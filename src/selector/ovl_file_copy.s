;;; ============================================================
;;; Recursive File Copy - Overlay #2
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        BEGINSEG OverlayCopyDialog

.scope file_copier

        AdjustFileEntryCase := app::AdjustFileEntryCase

;;; Called with `INVOKER_PREFIX` set to path of entry to copy
.proc Exec
        jsr     OpenWindow

        jsr     PrepSrcAndDstPaths
        jsr     EnumerateFiles
        bne     skip

        jsr     DrawWindowContent

        jsr     PrepSrcAndDstPaths
        jsr     CopyFiles

skip:
        pha
        jsr     CloseWindow
        pla

        rts
.endproc ; Exec

;;; ============================================================
;;; Recursive Enumerate & Copy Logic
;;; ============================================================

;;;          |             |
;;;          | Code        |
;;;   $2000  +-------------+
;;;          |.............|
;;;          |.(unused)....|
;;;   $1F00  +-------------+
;;;          |             |
;;;          | R/W Buffer  |
;;;   $1500  +-------------+
;;;          |             |
;;;          | Dst IO Buf  |
;;;   $1100  +-------------+
;;;          |             |
;;;          | Src I/O Buf |
;;;    $D00  +-------------+
;;;          |.(unused)....|
;;;    $C00  +-------------+
;;;          |             |
;;;          | Dir I/O Buf |
;;;    $800  +-------------+
;;;          :             :

dir_io_buffer :=  $800  ; 1024 bytes for I/O
src_io_buffer :=  $D00  ; 1024 bytes for I/O
dst_io_buffer := $1100  ; 1024 bytes for I/O
copy_buffer   := $1500  ; Read/Write buffer

        kCopyBufferSize = $A00
        .assert (kCopyBufferSize .mod BLOCK_SIZE) = 0, error, "integral number of blocks needed for sparse copies and performance"

;;; ============================================================
;;; Parameterized logic to support different implementations

.macro HANDLE_ERROR_CODE
        jmp     HandleErrorCode
.endmacro

.macro HANDLE_NO_SPACE
        jmp     ShowDiskFullError
.endmacro

.macro UPDATE_PROGRESS_UI
        jsr     UpdateWindowContent
.endmacro


;;; Jump table - populated by operation
op_jt_addrs:
op_jt_addr1:  .addr   CopyProcessDirectoryEntry
op_jt_addr2:  .addr   RemoveDstPathSegment
op_jt_addr3:  .addr   NoOp
kOpJTSize = * - op_jt_addrs

OpProcessDirectoryEntry:
        jmp     (op_jt_addr1)
OpResumeDirectory:
        jmp     (op_jt_addr2)
OpFinishDirectory:
        jmp     (op_jt_addr3)

;;; ============================================================
;;; Generic Recursive Operation Logic
;;; ============================================================
;;; Entry point is `ProcessDirectory`

NoOp:   rts

;;; Specific file paths (`pathname_dst` only used during copy)
pathname_src:        .res    ::kPathBufferSize, 0
pathname_dst:        .res    ::kPathBufferSize, 0

;;; ============================================================
;;; Directory enumeration parameter blocks

        DEFINE_OPEN_PARAMS open_src_dir_params, pathname_src, dir_io_buffer

        ;; Used for reading directory structure
        ;; 4 bytes is .sizeof(SubdirectoryHeader) - .sizeof(FileEntry)
        kBlockPointersSize = 4
        ASSERT_EQUALS .sizeof(SubdirectoryHeader) - .sizeof(FileEntry), kBlockPointersSize
        DEFINE_READWRITE_PARAMS read_block_pointers_params, buf_block_pointers, kBlockPointersSize ; For skipping prev/next pointers in directory data
buf_block_pointers:
        .res    kBlockPointersSize

        DEFINE_READWRITE_PARAMS read_src_dir_entry_params, file_entry, .sizeof(FileEntry)
        DEFINE_CLOSE_PARAMS close_src_dir_params

        ;; Blocks are 512 bytes, 13 entries of 39 bytes each leaves 5 bytes between.
        ;; Except first block, directory header is 39+4 bytes, leaving 1 byte, but then
        ;; block pointers are the next 4.
        kMaxPaddingBytes = 5
        DEFINE_READWRITE_PARAMS read_padding_bytes_params, buf_padding_bytes, kMaxPaddingBytes
buf_padding_bytes:
        .res    kMaxPaddingBytes

file_entry:
        .res    .sizeof(FileEntry)

;;; ============================================================
;;; State for directory recursion

recursion_depth:        .byte   0 ; How far down the directory structure are we
entries_per_block:      .byte   0
entry_index_in_dir:     .word   0
target_index:           .word   0

;;; Stack used when descending directories; keeps track of entry index within
;;; directories.
index_stack:    .res    ::kDirStackBufferSize, 0
stack_index:    .byte   0

entry_index_in_block:   .byte   0

;;; ============================================================
;;; Iterate directory entries
;;; Inputs: `pathname_src` points at source directory

.proc ProcessDirectory
        copy8   #0, recursion_depth
        jsr     OpenSrcDir
loop:
        jsr     ReadFileEntry
    IF_ZERO
        param_call AdjustFileEntryCase, file_entry

        lda     file_entry + FileEntry::storage_type_name_length
        beq     loop            ; deleted

        ;; Simplify to length-prefixed string
        and     #NAME_LENGTH_MASK
        sta     file_entry + FileEntry::storage_type_name_length

        CLEAR_BIT7_FLAG entry_err_flag
        jsr     OpProcessDirectoryEntry
        bit     entry_err_flag  ; don't recurse if the copy failed
        bmi     loop

        lda     file_entry + FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     loop            ; and don't recurse unless it's a directory

        ;; Recurse into child directory
        jsr     DescendDirectory
        inc     recursion_depth
        bpl     loop            ; always
    END_IF

        lda     recursion_depth
    IF_NOT_ZERO
        jsr     AscendDirectory
        dec     recursion_depth
        bpl     loop            ; always
    END_IF

        jmp     CloseSrcDir
.endproc ; ProcessDirectory

;;; Set on error during copying of a single file
entry_err_flag:  .byte   0      ; bit7

;;; ============================================================

.proc PushIndexToStack
        ldx     stack_index
        copy16  target_index, index_stack,x
        inx
        inx
        stx     stack_index
        rts
.endproc ; PushIndexToStack

;;; ============================================================

.proc PopIndexFromStack
        ldx     stack_index
        dex
        dex
        copy16   index_stack,x, target_index
        stx     stack_index
        rts
.endproc ; PopIndexFromStack

;;; ============================================================
;;; Open the source directory for reading, skipping header.
;;; Inputs: `pathname_src` set to dir

.proc OpenSrcDir
        lda     #0
        sta     entry_index_in_dir
        sta     entry_index_in_dir+1
        sta     entry_index_in_block

        MLI_CALL OPEN, open_src_dir_params
    IF_CS
fail:   HANDLE_ERROR_CODE
    END_IF

        ;; Skip over prev/next block pointers in header
        lda     open_src_dir_params::ref_num
        sta     read_block_pointers_params::ref_num
        sta     read_src_dir_entry_params::ref_num
        sta     read_padding_bytes_params::ref_num
        sta     close_src_dir_params::ref_num
        MLI_CALL READ, read_block_pointers_params
        bcs     fail

        ;; Header size is next/prev blocks + a file entry
        ASSERT_EQUALS .sizeof(SubdirectoryHeader), .sizeof(FileEntry) + 4
        copy8   #13, entries_per_block ; so ReadFileEntry doesn't immediately advance
        jsr     ReadFileEntry          ; read the rest of the header

        copy8   file_entry-4 + SubdirectoryHeader::entries_per_block, entries_per_block

        rts
.endproc ; OpenSrcDir

;;; ============================================================

.proc CloseSrcDir
        MLI_CALL CLOSE, close_src_dir_params
    IF_CS
        HANDLE_ERROR_CODE
    END_IF
        rts
.endproc ; CloseSrcDir

;;; ============================================================
;;; Read the next file entry in the directory into `file_entry`
;;; NOTE: Also used to read the vol/dir header.

.proc ReadFileEntry
        inc16   entry_index_in_dir

        MLI_CALL READ, read_src_dir_entry_params
    IF_CS
        cmp     #ERR_END_OF_FILE
        beq     eof

fail:   HANDLE_ERROR_CODE
    END_IF

        inc     entry_index_in_block
        lda     entry_index_in_block
    IF_A_GE     entries_per_block
        ;; Advance to first entry in next "block"
        copy8   #0, entry_index_in_block
        MLI_CALL READ, read_padding_bytes_params
        bcs     fail
    END_IF

        return  #0

eof:    return  #$FF
.endproc ; ReadFileEntry

;;; ============================================================
;;; Record the current index in the current directory, and
;;; recurse to the child directory in `file_entry`.

.proc DescendDirectory
        copy16  entry_index_in_dir, target_index
        jsr     CloseSrcDir
        jsr     PushIndexToStack
        jsr     AppendFileEntryToSrcPath
        jmp     OpenSrcDir
.endproc ; DescendDirectory

;;; ============================================================
;;; Close the current directory and resume iterating in the
;;; parent directory where we left off.

.proc AscendDirectory
        jsr     CloseSrcDir
        jsr     OpFinishDirectory
        jsr     RemoveSrcPathSegment
        jsr     PopIndexFromStack
        jsr     OpenSrcDir

:       cmp16   entry_index_in_dir, target_index
    IF_LT
        jsr     ReadFileEntry
        jmp     :-
    END_IF

        jmp     OpResumeDirectory
.endproc ; AscendDirectory

;;; ============================================================

.proc AppendFileEntryToSrcPath
        lda     file_entry+FileEntry::storage_type_name_length
    IF_NOT_ZERO
        ldx     #0
        ldy     pathname_src
        copy8   #'/', pathname_src+1,y
      DO
        iny
        BREAK_IF_X_GE file_entry+FileEntry::storage_type_name_length
        copy8   file_entry+FileEntry::file_name,x, pathname_src+1,y
        inx
      WHILE_NOT_ZERO            ; always
        sty     pathname_src
    END_IF
        rts
.endproc ; AppendFileEntryToSrcPath

;;; ============================================================

.proc RemoveSrcPathSegment
        ldx     pathname_src
    IF_NOT_ZERO
        lda     #'/'
      DO
        cmp     pathname_src,x
        beq     :+
        dex
      WHILE_NOT_ZERO
        inx
:
        dex
        stx     pathname_src
    END_IF
        rts
.endproc ; RemoveSrcPathSegment

;;; ============================================================

.proc AppendFileEntryToDstPath
        lda     file_entry+FileEntry::storage_type_name_length
    IF_NOT_ZERO
        ldx     #0
        ldy     pathname_dst
        copy8   #'/', pathname_dst+1,y
      DO
        iny
        BREAK_IF_X_GE file_entry+FileEntry::storage_type_name_length
        copy8   file_entry+FileEntry::file_name,x, pathname_dst+1,y
        inx
      WHILE_NOT_ZERO            ; always
        sty     pathname_dst
    END_IF
        rts
.endproc ; AppendFileEntryToDstPath

;;; ============================================================

.proc RemoveDstPathSegment
        ldx     pathname_dst
    IF_NOT_ZERO
        lda     #'/'
      DO
        cmp     pathname_dst,x
        beq     :+
        dex
      WHILE_NOT_ZERO
        inx
:
        dex
        stx     pathname_dst
    END_IF
        rts
.endproc ; RemoveDstPathSegment

;;; ============================================================
;;; Standard Copy Implementation
;;; ============================================================

;;; ============================================================
;;; File copy parameter blocks

        DEFINE_CREATE_PARAMS create_dir_params, pathname_dst, ACCESS_DEFAULT

        DEFINE_CREATE_PARAMS create_params, pathname_dst, ACCESS_DEFAULT
        DEFINE_OPEN_PARAMS open_src_params, pathname_src, src_io_buffer
        DEFINE_OPEN_PARAMS open_dst_params, pathname_dst, dst_io_buffer
        DEFINE_READWRITE_PARAMS read_src_params, copy_buffer, kCopyBufferSize
        DEFINE_READWRITE_PARAMS write_dst_params, copy_buffer, kCopyBufferSize
        DEFINE_SET_MARK_PARAMS mark_dst_params, 0
        DEFINE_CLOSE_PARAMS close_src_params
        DEFINE_CLOSE_PARAMS close_dst_params

        DEFINE_GET_FILE_INFO_PARAMS get_src_file_info_params, pathname_src
        DEFINE_GET_FILE_INFO_PARAMS get_dst_file_info_params, pathname_dst

;;; ============================================================
;;; Perform the recursive file copy.
;;; Inputs: `pathname_src` is source path
;;;         `pathname_dst` is destination path

.proc DoCopy
        ;; Check destination dir
        MLI_CALL GET_FILE_INFO, get_dst_file_info_params
    IF_A_EQ_ONE_OF #ERR_FILE_NOT_FOUND, #ERR_VOL_NOT_FOUND, #ERR_PATH_NOT_FOUND
        ;; Get source dir info
check_src:
        MLI_CALL GET_FILE_INFO, get_src_file_info_params
        bcc     gfi_ok
      IF_A_EQ_ONE_OF #ERR_VOL_NOT_FOUND, #ERR_FILE_NOT_FOUND
        jsr     ShowInsertSourceDiskPrompt
        jmp     check_src       ; retry
      END_IF
    END_IF

        HANDLE_ERROR_CODE

        ;; Prepare for copy...
gfi_ok:
        ldy     #$FF            ; maybe is dir
        lda     get_src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        ldy     #0              ; not a dir
is_dir:
        sty     is_dir_flag

        ;; copy `file_type`, `aux_type`, `storage_type`
        ldy     #4
    DO
        copy8   get_src_file_info_params+3,y, create_params+3,y
        dey
    WHILE_NOT_ZERO

        jsr     CheckSpaceAvailable
    IF_CS
        HANDLE_NO_SPACE
    END_IF

        ;; Copy creation date/time
        COPY_STRUCT DateTime, get_src_file_info_params::create_date, create_params::create_date

        ;; Create the file
        lda     create_params::storage_type
    IF_A_EQ     #ST_VOLUME_DIRECTORY
        copy8   #ST_LINKED_DIRECTORY, create_params::storage_type
    END_IF

        MLI_CALL CREATE, create_params
    IF_CS
        ;; NOTE: Since this is only ever "copy to RAMCard" / "on use"
        ;; we assume it is okay if it already exists.
      IF_A_NE   #ERR_DUPLICATE_FILENAME
        HANDLE_ERROR_CODE
      END_IF
    END_IF

        is_dir_flag := *+1
        lda     #SELF_MODIFIED_BYTE
    IF_NOT_ZERO
        jmp     ProcessDirectory
    END_IF

        jmp     CopyNormalFile

.endproc ; DoCopy

;;; ============================================================
;;; Copy an entry in a directory - regular file or directory.
;;; Inputs: `file_entry` populated with FileEntry
;;;         `pathname_src` has source directory path
;;;         `pathname_dst` has destination directory path
;;; Errors: `HANDLE_ERROR_CODE` is invoked

.proc CopyProcessDirectoryEntry
        jsr     CheckCancel

        lda     file_entry + FileEntry::file_type
    IF_A_EQ     #FT_DIRECTORY
        ;; --------------------------------------------------
        ;; Directory
        jsr     AppendFileEntryToSrcPath ; TODO: Hoist out of IF block
        UPDATE_PROGRESS_UI
        MLI_CALL GET_FILE_INFO, get_src_file_info_params
      IF_CS
fail:   HANDLE_ERROR_CODE
      END_IF

        jsr     AppendFileEntryToDstPath ; TODO: Hoist out of IF block
        jsr     CopyCreateDir
      IF_CS
        SET_BIT7_FLAG entry_err_flag
        bmi     pop_src_and_dst ; always
      END_IF
        jmp     RemoveSrcPathSegment
    END_IF

        ;; --------------------------------------------------
        ;; Regular File

        jsr     AppendFileEntryToDstPath ; TODO: Hoist out of IF block
        jsr     AppendFileEntryToSrcPath ; TODO: Hoist out of IF block
        UPDATE_PROGRESS_UI
        MLI_CALL GET_FILE_INFO, get_src_file_info_params
        bcs     fail

        jsr     CheckSpaceAvailable
    IF_CS
        HANDLE_NO_SPACE
    END_IF

        ;; Create parent dir if necessary
        ;; TODO: Is this actually needed?
        jsr     RemoveSrcPathSegment
        jsr     CopyCreateDir
        bcs     CheckSpace      ; ??? fail here or `pop_dst` ?
        jsr     AppendFileEntryToSrcPath

        ;; Do the copy
        jsr     CopyNormalFile

pop_src_and_dst:
        jsr     RemoveSrcPathSegment

;;; `pop_dst` label???
        jmp     RemoveDstPathSegment
.endproc ; CopyProcessDirectoryEntry

;;; ============================================================

.proc CheckSpace
        jsr     RemoveDstPathSegment
        FALL_THROUGH_TO CheckSpaceAvailable
.endproc ; CheckSpace

;;; ============================================================
;;; Check that there is room to copy a file. Handles overwrites.
;;; Inputs: `pathname_src` is source; `pathname_dst` is target
;;; Outputs: C=0 if there is sufficient space, C=1 otherwise

.proc CheckSpaceAvailable
        ;; --------------------------------------------------
        ;; Get source size

        MLI_CALL GET_FILE_INFO, get_src_file_info_params
        bcs     fail

        ;; --------------------------------------------------
        ;; Get destination size (in case of overwrite)

        copy16  #0, existing_blocks ; default 0, if it doesn't exist
        MLI_CALL GET_FILE_INFO, get_dst_file_info_params
    IF_CS
        cmp     #ERR_FILE_NOT_FOUND
        beq     got_dst_size    ; this is fine
fail:   HANDLE_ERROR_CODE
    END_IF
        copy16  get_dst_file_info_params::blocks_used, existing_blocks
got_dst_size:

        ;; --------------------------------------------------
        ;; Get destination volume free space

        ;; Isolate destination volume name
        copy8   pathname_dst, saved_length ; save

        ;; Strip to vol name - either end of string or next slash
        ldy     #1
    DO
        iny
        cpy     pathname_dst
        bcs     have_space      ; ???
        lda     pathname_dst,y
    WHILE_A_NE  #'/'
        sty     pathname_dst

        ;; Total blocks/used blocks on destination volume
        MLI_CALL GET_FILE_INFO, get_dst_file_info_params
        bcs     fail

        ;; Free = Total (aux) - Used
        sub16   get_dst_file_info_params::aux_type, get_dst_file_info_params::blocks_used, blocks_free
        ;; If overwriting, some blocks will be reclaimed.
        add16   blocks_free, existing_blocks, blocks_free
        ;; Does it fit? (free >= needed)
        cmp16   blocks_free, get_src_file_info_params::blocks_used
    IF_LT
        ;; Not enough room
        sec                     ; no space
        bcs     :+              ; always
    END_IF

have_space:
        clc
:
        saved_length := *+1         ; save full length of path
        lda     #SELF_MODIFIED_BYTE ; restore
        sta     pathname_dst
        rts

blocks_free:              ; Blocks free on volume
        .word   0
existing_blocks:          ; Blocks taken by file that will be replaced
        .word   0
.endproc ; CheckSpaceAvailable

;;; ============================================================
;;; Copy a normal (non-directory) file. File info is copied too.
;;; Inputs: `open_src_params` populated
;;;         `open_dst_params` populated; file already created
;;; Errors: `HANDLE_ERROR_CODE` is invoked

.proc CopyNormalFile
        ;; Open source
        MLI_CALL OPEN, open_src_params
        bcs     fail

        ;; Open destination
        MLI_CALL OPEN, open_dst_params
        bcs     fail

        lda     open_src_params::ref_num
        sta     read_src_params::ref_num
        sta     close_src_params::ref_num
        lda     open_dst_params::ref_num
        sta     write_dst_params::ref_num
        sta     mark_dst_params::ref_num
        sta     close_dst_params::ref_num

        lda     #0
        sta     mark_dst_params::position
        sta     mark_dst_params::position+1
        sta     mark_dst_params::position+2

        ;; Read a chunk
    DO
        copy16  #kCopyBufferSize, read_src_params::request_count
        jsr     CheckCancel
        MLI_CALL READ, read_src_params
      IF_CS
        cmp     #ERR_END_OF_FILE
        beq     close
fail:   HANDLE_ERROR_CODE
      END_IF

        ;; EOF?
        lda     read_src_params::trans_count
        ora     read_src_params::trans_count+1
        beq     close

        ;; Write the chunk
        jsr     CheckCancel
        jsr     _WriteDst
        bcs     fail
    WHILE_CC                    ; always

        ;; Close source and destination
close:  MLI_CALL CLOSE, close_dst_params
        MLI_CALL CLOSE, close_src_params

        ;; Copy file info
        MLI_CALL GET_FILE_INFO, get_src_file_info_params
        bcs     fail
        COPY_BYTES $B, get_src_file_info_params::access, get_dst_file_info_params::access

        copy8   #7, get_dst_file_info_params ; `SET_FILE_INFO` param_count
        MLI_CALL SET_FILE_INFO, get_dst_file_info_params
        copy8   #10, get_dst_file_info_params ; `GET_FILE_INFO` param_count

        rts

;;; Write the buffer to the destination file, being mindful of sparse blocks.
.proc _WriteDst
        ;; Always start off at start of copy buffer
        copy16  read_src_params::data_buffer, write_dst_params::data_buffer
    DO
        ;; Assume we're going to write everything we read. We may
        ;; later determine we need to write it out block-by-block.
        copy16  read_src_params::trans_count, write_dst_params::request_count

        ;; Assert: We're only ever copying to a RAMDisk, not AppleShare.
        ;; https://prodos8.com/docs/technote/30

        ;; Is there less than a full block? If so, just write it.
        lda     read_src_params::trans_count+1
        cmp     #.hibyte(BLOCK_SIZE)
        bcc     do_write        ; ...and done!

        ;; Otherwise we'll go block-by-block, treating all zeros
        ;; specially.
        copy16  #BLOCK_SIZE, write_dst_params::request_count

        ;; First two blocks are never made sparse. The first block is
        ;; never sparsely allocated (P8 TRM B.3.6 - Sparse Files) and
        ;; the transition from seedling to sapling is not handled
        ;; correctly in all versions of ProDOS.
        ;; https://prodos8.com/docs/technote/30
        ;; Assert: mark low byte is $00
        lda     mark_dst_params::position+1
        and     #%11111100
        ora     mark_dst_params::position+2
      IF_NOT_ZERO
        ;; Is this block all zeros? Scan all $200 bytes
        ;; (Note: coded for size, not speed, since we're I/O bound)
        ptr := $06
        copy16  write_dst_params::data_buffer, ptr ; first half
        ldy     #0
        tya
       DO
        ora     (ptr),y
        iny
       WHILE_NOT_ZERO
        inc     ptr+1           ; second half
       DO
        ora     (ptr),y
        iny
       WHILE_NOT_ZERO
        tay
       IF_ZERO
        ;; Block is all zeros, skip over it
        add16_8 mark_dst_params::position+1, #.hibyte(BLOCK_SIZE)
        MLI_CALL SET_EOF, mark_dst_params
        MLI_CALL SET_MARK, mark_dst_params
        jmp     next_block
       END_IF
      END_IF

        ;; Block is not sparse, write it
        jsr     do_write
        bcs     ret
        FALL_THROUGH_TO next_block

        ;; Advance to next block
next_block:
        inc     write_dst_params::data_buffer+1
        inc     write_dst_params::data_buffer+1
        ;; Assert: `read_src_params::trans_count` >= `BLOCK_SIZE`
        dec     read_src_params::trans_count+1
        dec     read_src_params::trans_count+1

        ;; Anything left to write?
        lda     read_src_params::trans_count
        ora     read_src_params::trans_count+1
    WHILE_NOT_ZERO
        clc
        rts

do_write:
        MLI_CALL WRITE, write_dst_params
        bcs     ret
        MLI_CALL GET_MARK, mark_dst_params
ret:    rts
.endproc ; _WriteDst
.endproc ; CopyNormalFile

;;; ============================================================

.proc CopyCreateDir
        ;; Copy `file_type`, `aux_type`, and `storage_type`
        kOffset = get_src_file_info_params::file_type - get_src_file_info_params
        kLen = get_src_file_info_params::storage_type - get_src_file_info_params::file_type + 1
        COPY_BYTES kLen, get_src_file_info_params+kOffset, create_dir_params+kOffset

        ;; Copy dates
        COPY_STRUCT DateTime, get_src_file_info_params::create_date, create_dir_params::create_date

        ;; If source is volume, create directory
        lda     create_dir_params::storage_type
    IF_A_EQ     #ST_VOLUME_DIRECTORY
        copy8   #ST_LINKED_DIRECTORY, create_dir_params::storage_type
    END_IF

        ;; Create it
        MLI_CALL CREATE, create_dir_params
    IF_CS
      IF_A_NE   #ERR_DUPLICATE_FILENAME
        HANDLE_ERROR_CODE
      END_IF
    END_IF
        clc                     ; treated as success
        rts
.endproc ; CopyCreateDir

;;; ============================================================
;;; Copy Specialization
;;; ============================================================

;;; Jump table for `CopyFiles`
copy_jt:
        .addr   CopyProcessDirectoryEntry ; callback for `OpProcessDirectoryEntry`
        .addr   RemoveDstPathSegment      ; callback for `OpResumeDirectory`
        .addr   NoOp                      ; callback for `OpFinishDirectory`

;;; ============================================================

;;; Paths for overall copy operation
dst_path:       .res    64, 0
src_path:       .res    64, 0
filename:       .res    16, 0

src_path_slash_index:           ; TODO: Written but never read?
        .byte   0

saved_stack:
        .byte   0

        DEFINE_CLOSE_PARAMS close_everything_params ; used in case of error

;;; ============================================================

.proc CopyFiles
        ;; Prepare jump table
        ldy     #kOpJTSize-1
    DO
        copy8   copy_jt,y, op_jt_addrs,y
        dey
    WHILE_POS

        tsx
        stx     saved_stack

        jsr     CopyPathsFromBufsToSrcAndDst
        MLI_CALL GET_FILE_INFO, get_dst_file_info_params
    IF_CS
        HANDLE_ERROR_CODE
    END_IF

        blocks := $06

        ;; Is there enough space?
        sub16   get_dst_file_info_params::aux_type, get_dst_file_info_params::blocks_used, blocks
        cmp16   blocks, blocks_total
    IF_LT
        HANDLE_NO_SPACE
    END_IF

        ;; Append `filename` to `pathname_dst`
        ldx     pathname_dst
        copy8   #'/', pathname_dst+1,x
        inc     pathname_dst
        ldy     #0
        ldx     pathname_dst
    DO
        iny
        inx
        copy8   filename,y, pathname_dst,x
    WHILE_Y_NE filename
        stx     pathname_dst

        jmp     DoCopy
.endproc ; CopyFiles

;;; ============================================================
;;; Enumeration Specialization
;;; ============================================================

;;; Jump table for `EnumerateFiles`
enum_jt:
        .addr   EnumerateVisitFile ; callback for `OpProcessDirectoryEntry`
        .addr   NoOp               ; callback for `OpResumeDirectory`
        .addr   NoOp               ; callback for `OpFinishDirectory`

;;; ============================================================
;;; Initially populated during enumeration, used during copy for UI
;;; updates.

file_count:
        .word   0
total_count:
        .word   0
blocks_total:
        .word   0

;;; ============================================================

.proc EnumerateFiles
        ;; Prepare jump table
        ldy     #kOpJTSize-1
    DO
        copy8   enum_jt,y, op_jt_addrs,y
        dey
    WHILE_POS

        tsx
        stx     saved_stack

        lda     #$00
        sta     file_count
        sta     file_count+1
        sta     blocks_total
        sta     blocks_total+1

        jsr     CopyPathsFromBufsToSrcAndDst
retry:  MLI_CALL GET_FILE_INFO, get_src_file_info_params
    IF_CS
      IF_A_EQ_ONE_OF #ERR_VOL_NOT_FOUND, #ERR_FILE_NOT_FOUND
        jsr     ShowInsertSourceDiskPrompt
        jmp     retry
      END_IF
        jmp     HandleErrorCode
    END_IF

        copy8   get_src_file_info_params::storage_type, storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        lda     #$00
        beq     set
is_dir: lda     #$FF
set:    sta     is_dir_flag
        beq     visit
        jsr     ProcessDirectory

        lda     storage_type
    IF_A_EQ     #ST_VOLUME_DIRECTORY
        ;; If copying a volume dir to RAMCard, the volume dir
        ;; will not be counted as a file during enumeration but
        ;; will be counted during copy, so include it to avoid
        ;; off-by-one.
        ;; https://github.com/a2stuff/a2d/issues/564
        inc16   file_count
        jsr     UpdateFileCountDisplay
        return  #0

        ;; TODO: Move these somewhere more sensible.
is_dir_flag:
        .byte   0
storage_type:
        .byte   0
    END_IF

visit:  jsr     EnumerateVisitFile
        return  #0
.endproc ; EnumerateFiles

;;; ============================================================

.proc EnumerateVisitFile
        jsr     CheckCancel

        jsr     AppendFileEntryToSrcPath
        MLI_CALL GET_FILE_INFO, get_src_file_info_params
    IF_CC
        add16   blocks_total, get_src_file_info_params::blocks_used, blocks_total
    END_IF
        inc16   file_count
        jsr     RemoveSrcPathSegment
        jmp     UpdateFileCountDisplay
.endproc ; EnumerateVisitFile

;;; ============================================================
;;; Common Logic
;;; ============================================================
;;; Used by both `EnumerateFiles` and `CopyFiles` to prepare
;;; for the operations.

;;; ============================================================
;;; Copy `src_path` to `pathname_src` and `dst_path` to `pathname_dst`
;;; and note last '/' in src.

.proc CopyPathsFromBufsToSrcAndDst
        ldy     #0
        sta     src_path_slash_index
        dey

        ;; Copy `src_path` to `pathname_src`
        ;; ... but record index of last '/'
    DO
        iny
        lda     src_path,y
      IF_A_EQ   #'/'
        sty     src_path_slash_index
      END_IF
        sta     pathname_src,y
    WHILE_Y_NE  src_path

        ;; Copy `dst_path` to `pathname_dst`
        ldy     dst_path
    DO
        copy8   dst_path,y, pathname_dst,y
        dey
    WHILE_POS

        rts
.endproc ; CopyPathsFromBufsToSrcAndDst

;;; ============================================================
;;; Input: `INVOKER_PREFIX` has path to copy

.proc PrepSrcAndDstPaths
        COPY_STRING INVOKER_PREFIX, src_path

        ldy     src_path
    DO
        lda     src_path,y
        BREAK_IF_A_EQ #'/'
        dey
    WHILE_NOT_ZERO
        dey
        sty     src_path

    DO
        lda     src_path,y
        BREAK_IF_A_EQ #'/'
        dey
    WHILE_POS

        ldx     #0
    DO
        iny
        inx
        copy8   src_path,y, filename,x
    WHILE_Y_NE  src_path
        stx     filename

        param_call app::CopyRAMCardPrefix, dst_path

        rts
.endproc ; PrepSrcAndDstPaths

;;; ============================================================
;;; Copy Progress UI
;;; ============================================================

.params winfo
        kWindowId = $0B
        kWidth = 350
        kHeight = 70
window_id:      .byte   kWindowId
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   150
mincontheight:  .word   50
maxcontwidth:   .word   500
maxcontheight:  .word   140
port:
        DEFINE_POINT viewloc, 100, 50
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kWidth, kHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        DEFINE_RECT_FRAME rect_frame, winfo::kWidth, winfo::kHeight

        DEFINE_LABEL download, res_string_label_download, 116, 16

        kProgressDialogDefaultX = 20
        kProgressDialogPathLeft = 100
        kProgressDialogPathWidth = winfo::kWidth - kProgressDialogPathLeft - kProgressDialogDefaultX

        DEFINE_POINT pos_copying, kProgressDialogDefaultX, 32
        DEFINE_POINT pos_path, kProgressDialogPathLeft, 32
        DEFINE_POINT pos_remaining, kProgressDialogDefaultX, 45

str_copying:
        PASCAL_STRING res_string_label_copying

        DEFINE_RECT rect_clear_count, 18, 24, winfo::kWidth-kBorderDX*2, 32
        DEFINE_RECT rect_clear_details, kBorderDX*2, 24, winfo::kWidth-kBorderDX*2, winfo::kHeight-kBorderDY*2

str_files_to_copy:
        PASCAL_STRING res_string_label_files_to_copy
str_files_remaining:
        PASCAL_STRING res_string_label_files_remaining
str_spaces:
        PASCAL_STRING "    "
str_from_int:
        PASCAL_STRING "000,000"

        kProgressBarTop = 51
        kProgressBarInset = 20
        kProgressBarWidth = winfo::kWidth - kProgressBarInset*2
        kProgressBarHeight = 7
        DEFINE_RECT_SZ progress_frame, kProgressBarInset-1, kProgressBarTop-1, kProgressBarWidth+2, kProgressBarHeight+2
        DEFINE_RECT_SZ progress_meter, kProgressBarInset, kProgressBarTop,  kProgressBarWidth,kProgressBarHeight

progress_pattern:
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001


;;; ============================================================

.proc OpenWindow
        MGTK_CALL MGTK::OpenWindow, winfo
        lda     #winfo::kWindowId
        jsr     app::GetWindowPort

        MGTK_CALL MGTK::SetPenMode, app::notpencopy
        MGTK_CALL MGTK::SetPenSize, app::pensize_frame
        MGTK_CALL MGTK::FrameRect, rect_frame
        MGTK_CALL MGTK::SetPenSize, app::pensize_normal

        MGTK_CALL MGTK::MoveTo, download_label_pos
        param_call DrawString, download_label_str
        rts
.endproc ; OpenWindow

;;; ============================================================

.params progress_muldiv_params
number:         .word   kProgressBarWidth ; (in) constant
numerator:      .word   0                 ; (in) populated dynamically
denominator:    .word   0                 ; (in) populated dynamically
result:         .word   0                 ; (out)
remainder:      .word   0                 ; (out)
.endparams

.proc DrawWindowContent
        lda     #winfo::kWindowId
        jsr     app::GetWindowPort
        MGTK_CALL MGTK::PaintRect, rect_clear_details

        MGTK_CALL MGTK::SetPenMode, app::notpencopy
        MGTK_CALL MGTK::FrameRect, progress_frame

        copy16  file_count, total_count
        FALL_THROUGH_TO UpdateWindowContent
.endproc

.proc UpdateWindowContent
        dec     file_count
        lda     file_count
    IF_A_EQ     #$FF
        dec     file_count+1
    END_IF

        lda     #winfo::kWindowId
        jsr     app::GetWindowPort

        ldax    file_count
        jsr     IntToString
        MGTK_CALL MGTK::PaintRect, rect_clear_count
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call DrawString, str_copying
        MGTK_CALL MGTK::MoveTo, pos_path
        COPY_STRING pathname_src, display_path
        param_call DrawDialogPath, display_path
        MGTK_CALL MGTK::MoveTo, pos_remaining
        param_call DrawString, str_files_remaining
        param_call DrawString, str_from_int
        param_call DrawString, str_spaces

        sub16   total_count, file_count, progress_muldiv_params::numerator
        copy16  total_count, progress_muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, progress_muldiv_params
        add16   progress_muldiv_params::result, progress_meter::x1, progress_meter::x2
        MGTK_CALL MGTK::SetPattern, progress_pattern
        MGTK_CALL MGTK::PaintRect, progress_meter

        rts

;;; Copy of `pathname_src` modified for display
display_path:
        .res    ::kPathBufferSize, 0
.endproc ; UpdateWindowContent

;;; ============================================================

.proc UpdateFileCountDisplay
        lda     #winfo::kWindowId
        jsr     app::GetWindowPort

        ldax    file_count
        jsr     IntToString
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call DrawString, str_files_to_copy
        param_call DrawString, str_from_int
        param_jump DrawString, str_spaces
.endproc ; UpdateFileCountDisplay

;;; ============================================================

.proc ShowInsertSourceDiskPrompt
        lda     #AlertID::insert_source_disk
        jsr     app::ShowAlert
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
    IF_ZERO                         ; `kAlertResultCancel` = 1
        jmp     app::SetCursorWatch ; try again
    END_IF
        jmp     RestoreStackAndReturn
.endproc ; ShowInsertSourceDiskPrompt

;;; ============================================================

.proc ShowDiskFullError
        lda     #AlertID::not_enough_room
        jsr     app::ShowAlert
        jmp     RestoreStackAndReturn
.endproc ; ShowDiskFullError

;;; ============================================================

.proc HandleErrorCode
        lda     #AlertID::copy_incomplete
        jsr     app::ShowAlert
        FALL_THROUGH_TO RestoreStackAndReturn
.endproc ; HandleErrorCode

;;; ============================================================

.proc RestoreStackAndReturn
        MLI_CALL CLOSE, close_everything_params
        ldx     saved_stack
        txs
        return  #$FF
.endproc ; RestoreStackAndReturn

;;; ============================================================

.proc CloseWindow
        MGTK_CALL MGTK::CloseWindow, winfo
        rts
.endproc ; CloseWindow

;;; ============================================================

;;; Aborts if Escape key is down
.proc CheckCancel
        MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_params::kind
    IF_A_EQ     #MGTK::EventKind::key_down
        lda     app::event_params::key
        cmp     #CHAR_ESCAPE
        beq     RestoreStackAndReturn
    END_IF

        rts
.endproc ; CheckCancel

;;; ============================================================

        .include "../lib/drawdialogpath.s"

        ReadSetting := app::ReadSetting
        .include "../lib/inttostring.s"
        .include "../lib/drawstring.s"

;;; ============================================================

.endscope ; file_copier

file_copier__Exec   := file_copier::Exec

        ENDSEG OverlayCopyDialog
