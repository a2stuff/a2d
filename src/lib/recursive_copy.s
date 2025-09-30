;;; ============================================================
;;; Generic Recursive Operation Logic
;;; ============================================================

;;; Implements recursive directory iteration; callers must implement a
;;; set of callbacks and error handlers. For file copying (the most
;;; common case), default callback implementations are provided.

;;; Callers must define:
;;;
;;; ----------------------------------------
;;; Identifiers
;;; ----------------------------------------
;;; * `dir_io_buffer`   - 1024 bytes for I/O
;;; * `dir_data_buffer` - 256 bytes for miscellaneous data
;;; * `src_io_buffer`   - 1024 bytes for I/O
;;; * `dst_io_buffer`   - 1024 bytes for I/O
;;; * `copy_buffer` and `kCopyBufferSize` (integral number of blocks)
;;; * `::kCopyIgnoreDuplicateErrorOnCreate` (0 or 1)
;;; * `::kCopyCheckSpaceAvailable` (0 or 1)
;;;
;;; ----------------------------------------
;;; Callbacks
;;; ----------------------------------------
;;; * `OpCheckCancel` - called regularly, allows caller to abort (close all open files, restore stack, hide UI)
;;; * `OpInsertSource` - called by `DoCopy`
;;; * `OpHandleErrorCode` - shows error, restores stack
;;; * `OpHandleNoSpace` - shows error, restores stack
;;; * `OpUpdateProgress` - updates UI and returns
;;;
;;; * `OpProcessDirectoryEntry` - called for each directory entry
;;; * `OpResumeDirectory` - called when resuming directory enumeration
;;; * `OpFinishDirectory` - called when enumerating a directory is complete
;;;
;;; For file copies:
;;; * `OpProcessDirectoryEntry` can use `CopyProcessDirectoryEntry`
;;; * `OpResumeDirectory` should be `RemoveDstPathSegment` (to keep in sync w/ src path)
;;; * `OpFinishDirectory` can be `NoOp`
;;; For enumeration:
;;; * `OpProcessDirectoryEntry` can increment a count and inspect `file_entry`
;;; * `OpResumeDirectory` can be `NoOp`
;;; * `OpFinishDirectory` can be `NoOp`
;;; For deletion:
;;; * `OpProcessDirectoryEntry` should delete non-directory files
;;; * `OpResumeDirectory` can be `NoOp`
;;; * `OpFinishDirectory` should delete the directory

;;; ----------------------------------------
;;; Entry points
;;; ----------------------------------------
;;; Doing real work:
;;; * `ProcessDirectory` - iterate `pathname_src` dir recursively and invoke callbacks
;;; * `DoCopy` - copy `pathname_src` to `pathname_dst`; calls `ProcessDirectory` if needed
;;; Utilities:
;;; * `AppendFileEntryToSrcPath` - uses `file_entry` and `pathname_src`
;;; * `AppendFileEntryToDstPath` - uses `file_entry` and `pathname_dst`
;;; * `RemoveSrcPathSegment` - modifies `pathname_src`
;;; * `RemoveDstPathSegment` - modifies `pathname_dst`
;;; * `NoOp` - just a handy `RTS`
;;;
;;; ----------------------------------------
;;; Parameters
;;; ----------------------------------------
;;; `pathname_src` - source pathname
;;; `pathname_dst` - destination pathname (for copies)

        .assert .lobyte(dir_io_buffer) = 0, error, "I/O buffers must be page-aligned"
        .assert .lobyte(src_io_buffer) = 0, error, "I/O buffers must be page-aligned"
        .assert .lobyte(dst_io_buffer) = 0, error, "I/O buffers must be page-aligned"
        .assert .lobyte(copy_buffer) = 0, error, "page-align copy buffer for better performance"
        .assert (kCopyBufferSize .mod BLOCK_SIZE) = 0, error, "integral number of blocks needed for sparse copies and performance"

NoOp:   rts

;;; Specific file paths (`pathname_dst` only used during copy)
pathname_src:        .res    ::kPathBufferSize, 0
pathname_dst:        .res    ::kPathBufferSize, 0

        ;; Populated during iteration
        DEFINE_GET_FILE_INFO_PARAMS src_file_info_params, pathname_src
        DEFINE_GET_FILE_INFO_PARAMS dst_file_info_params, pathname_dst

;;; ============================================================
;;; Directory enumeration parameter blocks and state

        ;; 4 bytes is .sizeof(SubdirectoryHeader) - .sizeof(FileEntry)
        kBlockPointersSize = 4
        ;; Blocks are 512 bytes, 13 entries of 39 bytes each leaves 5 bytes between.
        ;; Except first block, directory header is 39+4 bytes, leaving 1 byte, but then
        ;; block pointers are the next 4.
        kMaxPaddingBytes = 5

        ASSERT_EQUALS .sizeof(SubdirectoryHeader) - .sizeof(FileEntry), kBlockPointersSize

        PARAM_BLOCK, dir_data_buffer
;;; Read buffers
buf_block_pointers      .res    kBlockPointersSize
buf_padding_bytes       .res    kMaxPaddingBytes
file_entry              .tag    FileEntry

;;; State for directory recursion
recursion_depth         .byte   ; How far down the directory structure are we
entries_per_block       .byte   ; Number of file entries per directory block
entry_index_in_dir      .word
target_index            .word

;;; During directory traversal, the number of file entries processed
;;; at the current level is pushed here, so that following a descent
;;; the previous entries can be skipped.
index_stack_lo          .res    ::kDirStackSize
index_stack_hi          .res    ::kDirStackSize
stack_index             .byte

entry_index_in_block    .byte
dir_data_buffer_end     .byte
        END_PARAM_BLOCK
        .assert dir_data_buffer_end - dir_data_buffer <= 256, error, "too big"

        DEFINE_OPEN_PARAMS open_src_dir_params, pathname_src, dir_io_buffer
        DEFINE_READWRITE_PARAMS read_block_pointers_params, buf_block_pointers, kBlockPointersSize ; For skipping prev/next pointers in directory data
        DEFINE_READWRITE_PARAMS read_src_dir_entry_params, file_entry, .sizeof(FileEntry)
        DEFINE_READWRITE_PARAMS read_padding_bytes_params, buf_padding_bytes, kMaxPaddingBytes
        DEFINE_CLOSE_PARAMS close_src_dir_params

;;; ============================================================
;;; Iterate directory entries
;;; Inputs: `pathname_src` points at source directory

.proc ProcessDirectory
        lda     #0
        sta     recursion_depth
        sta     stack_index

        jsr     _OpenSrcDir
loop:
        jsr     _ReadFileEntry
    IF_ZERO
        param_call AdjustFileEntryCase, file_entry

        lda     file_entry + FileEntry::storage_type_name_length
        beq     loop            ; deleted
        pha                     ; A = `storage_type_name_length`

        ;; Requires `storage_type_name_length` to be intact
        jsr     _ConvertFileEntryToFileInfo

        ;; Simplify to length-prefixed string
        pla                     ; A = `storage_type_name_length`
        and     #NAME_LENGTH_MASK
        sta     file_entry

        jsr     OpCheckCancel

        CLEAR_BIT7_FLAG entry_err_flag
        jsr     OpProcessDirectoryEntry
        bit     entry_err_flag  ; don't recurse if the copy failed
        bmi     loop

        lda     file_entry + FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     loop            ; and don't recurse unless it's a directory

        ;; Recurse into child directory
        jsr     _DescendDirectory
        inc     recursion_depth
        bpl     loop            ; always
    END_IF

        lda     recursion_depth
    IF_NOT_ZERO
        jsr     _AscendDirectory
        dec     recursion_depth
        bpl     loop            ; always
    END_IF

        jmp     _CloseSrcDir
.endproc ; ProcessDirectory

;;; Set on error during copying of a single file
entry_err_flag:  .byte   0      ; bit7

;;; ============================================================

;;; Populate `src_file_info_params` from `file_entry`

.proc _ConvertFileEntryToFileInfo
        ldx     #kMapSize-1
    DO
        ldy     map,x
        copy8   file_entry,y, src_file_info_params::access,x
        dex
    WHILE_POS

        ;; Fix `storage_type`
        ldx     #4
    DO
        lsr     src_file_info_params::storage_type
        dex
    WHILE_NOT_ZERO

        rts

;;; index is offset in `src_file_info_params`, value is offset in `file_entry`
map:    .byte   FileEntry::access
        .byte   FileEntry::file_type
        .byte   FileEntry::aux_type
        .byte   FileEntry::aux_type+1
        .byte   FileEntry::storage_type_name_length
        .byte   FileEntry::blocks_used
        .byte   FileEntry::blocks_used+1
        .byte   FileEntry::mod_date
        .byte   FileEntry::mod_date+1
        .byte   FileEntry::mod_time
        .byte   FileEntry::mod_time+1
        .byte   FileEntry::creation_date
        .byte   FileEntry::creation_date+1
        .byte   FileEntry::creation_time
        .byte   FileEntry::creation_time+1
        kMapSize = * - map
.endproc ; _ConvertFileEntryToFileInfo

;;; ============================================================

.proc _PushIndexToStack
        ldx     stack_index
        copy8   target_index, index_stack_lo,x
        copy8   target_index+1, index_stack_hi,x
        inc     stack_index
        rts
.endproc ; _PushIndexToStack

;;; ============================================================

.proc _PopIndexFromStack
        dec     stack_index
        ldx     stack_index
        copy8   index_stack_lo,x, target_index
        copy8   index_stack_hi,x, target_index+1
        rts
.endproc ; _PopIndexFromStack

;;; ============================================================
;;; Open the source directory for reading, skipping header.
;;; Inputs: `pathname_src` set to dir

.proc _OpenSrcDir
        lda     #0
        sta     entry_index_in_dir
        sta     entry_index_in_dir+1
        sta     entry_index_in_block

        MLI_CALL OPEN, open_src_dir_params
    IF_CS
fail:   jmp     OpHandleErrorCode
    END_IF

        lda     open_src_dir_params::ref_num
        sta     read_block_pointers_params::ref_num
        sta     read_src_dir_entry_params::ref_num
        sta     read_padding_bytes_params::ref_num
        sta     close_src_dir_params::ref_num

        ;; Skip over prev/next block pointers in header
        MLI_CALL READ, read_block_pointers_params
        bcs     fail

        ;; Header size is next/prev blocks + a file entry
        copy8   #13, entries_per_block ; so `_ReadFileEntry` doesn't immediately advance
        jsr     _ReadFileEntry         ; read the rest of the header

        ASSERT_EQUALS .sizeof(SubdirectoryHeader), .sizeof(FileEntry) + 4
        copy8   file_entry-4 + SubdirectoryHeader::entries_per_block, entries_per_block

        rts
.endproc ; _OpenSrcDir

;;; ============================================================

.proc _CloseSrcDir
        MLI_CALL CLOSE, close_src_dir_params
    IF_CS
        jmp     OpHandleErrorCode
    END_IF
        rts
.endproc ; _CloseSrcDir

;;; ============================================================
;;; Read the next file entry in the directory into `file_entry`
;;; NOTE: Also used to read the vol/dir header.

.proc _ReadFileEntry
        inc16   entry_index_in_dir

        MLI_CALL READ, read_src_dir_entry_params
    IF_CS
        cmp     #ERR_END_OF_FILE
        beq     eof

fail:   jmp     OpHandleErrorCode
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
.endproc ; _ReadFileEntry

;;; ============================================================
;;; Record the current index in the current directory, and
;;; recurse to the child directory in `file_entry`.

.proc _DescendDirectory
        copy16  entry_index_in_dir, target_index
        jsr     _CloseSrcDir
        jsr     _PushIndexToStack
        jsr     AppendFileEntryToSrcPath
        jmp     _OpenSrcDir
.endproc ; _DescendDirectory

;;; ============================================================
;;; Close the current directory and resume iterating in the
;;; parent directory where we left off.

.proc _AscendDirectory
        jsr     _CloseSrcDir
        jsr     OpFinishDirectory
        jsr     RemoveSrcPathSegment
        jsr     _PopIndexFromStack
        jsr     _OpenSrcDir

:       cmp16   entry_index_in_dir, target_index
    IF_LT
        jsr     _ReadFileEntry
        jmp     :-
    END_IF

        jmp     OpResumeDirectory
.endproc ; _AscendDirectory

;;; ============================================================
;;; Append name at `file_entry` to path at `pathname_src`

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
;;; Remove segment from path at `pathname_src`

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
;;; Append name at `file_entry` to path at `pathname_dst`

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
;;; Remove segment from path at `pathname_dst`

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

        DEFINE_CREATE_PARAMS create_params, pathname_dst, ACCESS_DEFAULT
        DEFINE_OPEN_PARAMS open_src_params, pathname_src, src_io_buffer
        DEFINE_OPEN_PARAMS open_dst_params, pathname_dst, dst_io_buffer
        DEFINE_READWRITE_PARAMS read_src_params, copy_buffer, kCopyBufferSize
        DEFINE_READWRITE_PARAMS write_dst_params, copy_buffer, kCopyBufferSize
        DEFINE_SET_MARK_PARAMS mark_dst_params, 0
        DEFINE_CLOSE_PARAMS close_src_params
        DEFINE_CLOSE_PARAMS close_dst_params


;;; ============================================================
;;; Perform the recursive file copy.
;;; Inputs: `pathname_src` is source path
;;;         `pathname_dst` is destination path

.proc DoCopy
        ;; Check destination
        MLI_CALL GET_FILE_INFO, dst_file_info_params
    IF_A_NE_ALL_OF #ERR_FILE_NOT_FOUND, #ERR_VOL_NOT_FOUND, #ERR_PATH_NOT_FOUND
        jmp     OpHandleErrorCode
    END_IF

        ;; Get source info
retry:  MLI_CALL GET_FILE_INFO, src_file_info_params
    IF_CS
      IF_A_EQ_ONE_OF #ERR_VOL_NOT_FOUND, #ERR_FILE_NOT_FOUND
        jsr     OpInsertSource
        jmp     retry
      END_IF
        jmp     OpHandleErrorCode
    END_IF

.if ::kCopyCheckSpaceAvailable
        jsr     _RecordDestVolBlocksFree
.endif

        ;; Regular file or directory?
        lda     src_file_info_params::storage_type
    IF_A_NE_ALL_OF #ST_VOLUME_DIRECTORY, #ST_LINKED_DIRECTORY

        ;; --------------------------------------------------
        ;; File

.if ::kCopyCheckSpaceAvailable
        jsr     _EnsureSpaceAvailable
.endif
        jsr     _CopyCreateFile
        jmp     _CopyNormalFile

    END_IF

        ;; --------------------------------------------------
        ;; Directory

.if ::kCopyCheckSpaceAvailable
        jsr     _EnsureSpaceAvailable
.endif
        jsr     _CopyCreateFile
        jmp     ProcessDirectory

.endproc ; DoCopy

;;; ============================================================
;;; Copy an entry in a directory - regular file or directory.
;;; Inputs: `file_entry` populated with `FileEntry`
;;;         `src_file_info_params` populated
;;;         `pathname_src` has source directory path
;;;         `pathname_dst` has destination directory path
;;; Errors: `OpHandleErrorCode` is invoked

.proc CopyProcessDirectoryEntry
        jsr     AppendFileEntryToDstPath
        jsr     AppendFileEntryToSrcPath
        jsr     OpUpdateProgress

        ;; Called with `src_file_info_params` pre-populated
        lda     src_file_info_params::storage_type
    IF_A_NE     #ST_LINKED_DIRECTORY
        ;; --------------------------------------------------
        ;; File
.if ::kCopyCheckSpaceAvailable
        jsr     _EnsureSpaceAvailable
.endif
        jsr     _CopyCreateFile
        bcs     done

        jsr     _CopyNormalFile
    ELSE
        ;; --------------------------------------------------
        ;; Directory
        jsr     _CopyCreateFile
        bcc     ok_dir ; leave dst path segment in place for recursion
        SET_BIT7_FLAG entry_err_flag
    END_IF

        ;; --------------------------------------------------

done:   jsr     RemoveDstPathSegment
ok_dir: jsr     RemoveSrcPathSegment
        rts
.endproc ; CopyProcessDirectoryEntry

;;; ============================================================
;;; Record the number of blocks free on the destination volume.
;;; Input: `pathname_dst` is path on destination volume
;;; Output: `blocks_free` has the free block count

.if ::kCopyCheckSpaceAvailable
.proc _RecordDestVolBlocksFree
        ;; Isolate destination volume name
        lda     pathname_dst
        pha                     ; A = `pathname_dst` saved length

        ;; Strip to vol name - either end of string or next slash
        ldy     #1
    DO
        iny
        cpy     pathname_dst
        bcs     :+
        lda     pathname_dst,y
    WHILE_A_NE  #'/'
        sty     pathname_dst
:
        ;; Get total blocks/used blocks on destination volume
        MLI_CALL GET_FILE_INFO, dst_file_info_params
        jcs     OpHandleErrorCode

        ;; Free = Total (aux) - Used
        sub16   dst_file_info_params::aux_type, dst_file_info_params::blocks_used, blocks_free

        pla                     ; A = `pathname_dst` saved length
        sta     pathname_dst
        rts

blocks_free:              ; Blocks free on volume
        .word   0
.endproc ; _RecordDestVolBlocksFree
.endif

;;; ============================================================
;;; Check that there is room to copy a file. Handles overwrites.
;;; If not enough space, control is passed to `OpHandleNoSpace`
;;; (which will not return). Only returns if there is enough space.
;;; Inputs: `src_file_info_params` is populated; `pathname_dst` is target
;;; and `_RecordDestVolBlocksFree` has been called.

.if ::kCopyCheckSpaceAvailable
.proc _EnsureSpaceAvailable
        blocks_free := _RecordDestVolBlocksFree::blocks_free

        ;; Get destination size (in case of overwrite)
        MLI_CALL GET_FILE_INFO, dst_file_info_params
    IF_CC
        ;; Assume those blocks will be freed
        add16   blocks_free, dst_file_info_params::blocks_used, blocks_free
    ELSE_IF_A_NE #ERR_FILE_NOT_FOUND
        jmp     OpHandleErrorCode
    END_IF

        ;; Does it fit? (free >= needed)
        cmp16   blocks_free, src_file_info_params::blocks_used
    IF_LT
        ;; Not enough room
        jmp     OpHandleNoSpace
    END_IF

        ;; Assume those blocks will be used
        add16   blocks_free, src_file_info_params::blocks_used, blocks_free

        rts
.endproc ; _EnsureSpaceAvailable
.endif

;;; ============================================================
;;; Copy a normal (non-directory) file. File info is copied too.
;;; Inputs: `open_src_params` populated
;;;         `open_dst_params` populated; file already created
;;;         `src_file_info_params` populated
;;; Errors: `OpHandleErrorCode` is invoked

.proc _CopyNormalFile
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
        jsr     OpCheckCancel
        MLI_CALL READ, read_src_params
      IF_CS
        cmp     #ERR_END_OF_FILE
        beq     close
fail:   jmp     OpHandleErrorCode
      END_IF

        ;; EOF?
        lda     read_src_params::trans_count
        ora     read_src_params::trans_count+1
        beq     close

        ;; Write the chunk
        jsr     OpCheckCancel
        jsr     _WriteDst
        bcs     fail
    WHILE_CC                    ; always

        ;; Close source and destination
close:  MLI_CALL CLOSE, close_dst_params
        MLI_CALL CLOSE, close_src_params

        ;; Copy file info
        COPY_BYTES $B, src_file_info_params::access, dst_file_info_params::access

        copy8   #7, dst_file_info_params ; `SET_FILE_INFO` param_count
        MLI_CALL SET_FILE_INFO, dst_file_info_params
        copy8   #10, dst_file_info_params ; `GET_FILE_INFO` param_count

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
.endproc ; _CopyNormalFile

;;; ============================================================

.proc _CopyCreateFile
        ;; Copy `file_type`, `aux_type`, and `storage_type`
        COPY_BYTES src_file_info_params::storage_type - src_file_info_params::file_type + 1, src_file_info_params::file_type, create_params::file_type

        ;; Copy `create_date`/`create_time`
        COPY_STRUCT DateTime, src_file_info_params::create_date, create_params::create_date

        ;; If source is volume, create directory
        lda     create_params::storage_type
    IF_A_EQ     #ST_VOLUME_DIRECTORY
        copy8   #ST_LINKED_DIRECTORY, create_params::storage_type
    END_IF

        ;; Create it
        MLI_CALL CREATE, create_params
    IF_CS
.if ::kCopyIgnoreDuplicateErrorOnCreate
      IF_A_NE   #ERR_DUPLICATE_FILENAME
        jmp     OpHandleErrorCode
      END_IF
.else
        jmp     OpHandleErrorCode
.endif
    END_IF
        clc                     ; treated as success
        rts
.endproc ; _CopyCreateFile
