;;; ============================================================
;;; Recursive File Copy - Overlay #2
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        BEGINSEG OverlayCopyDialog

.scope file_copier

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

        DEFINE_OPEN_PARAMS open_params, pathname_src, $800

        ;; 4 bytes is .sizeof(SubdirectoryHeader) - .sizeof(FileEntry)
        kBlockPointersSize = 4
        ASSERT_EQUALS .sizeof(SubdirectoryHeader) - .sizeof(FileEntry), kBlockPointersSize
        DEFINE_READWRITE_PARAMS read_block_pointers_params, buf_block_pointers, kBlockPointersSize ; For skipping prev/next pointers in directory data
buf_block_pointers:
        .res    kBlockPointersSize, 0

        DEFINE_CLOSE_PARAMS close_params
        DEFINE_CLOSE_PARAMS close_everything_params ; used in case of error

        DEFINE_READWRITE_PARAMS read_fileentry_params, file_entry, .sizeof(FileEntry)

        ;; Blocks are 512 bytes, 13 entries of 39 bytes each leaves 5 bytes between.
        ;; Except first block, directory header is 39+4 bytes, leaving 1 byte, but then
        ;; block pointers are the next 4.
        kMaxPaddingBytes = 5
        DEFINE_READWRITE_PARAMS read_padding_bytes_params, buf_padding_bytes, kMaxPaddingBytes
buf_padding_bytes:
        .res    kMaxPaddingBytes, 0

        DEFINE_CLOSE_PARAMS close_src_params
        DEFINE_CLOSE_PARAMS close_dst_params

        io_buf_src = $D00
        io_buf_dst = $1100
        data_buf = $1500

        DEFINE_OPEN_PARAMS open_src_params, pathname_src, io_buf_src
        DEFINE_OPEN_PARAMS open_dst_params, pathname_dst, io_buf_dst

        kDirCopyBufSize = $A00
        .assert (kDirCopyBufSize .mod BLOCK_SIZE) = 0, error, "integral number of blocks needed for sparse copies and performance"

        DEFINE_READWRITE_PARAMS read_src_params, data_buf, kDirCopyBufSize
        DEFINE_READWRITE_PARAMS write_dst_params, data_buf, kDirCopyBufSize
        DEFINE_SET_MARK_PARAMS mark_dst_params, 0

        DEFINE_CREATE_PARAMS create_params2, pathname_dst, ACCESS_DEFAULT

        DEFINE_CREATE_PARAMS create_params, pathname_dst

        DEFINE_GET_FILE_INFO_PARAMS get_src_file_info_params, pathname_src

        DEFINE_GET_FILE_INFO_PARAMS get_dst_file_info_params, pathname_dst

file_entry:
        .res    .sizeof(FileEntry)

addr_table:

;;; Jump table - populated by operation
op_jt_addrs:
op_jt_addr1:  .addr   CopyVisitFile
op_jt_addr2:  .addr   PopDstSegment
op_jt_addr3:  .addr   NoOp2

NoOp2:  rts

;;; Specific file paths during copy
pathname_dst:
        .res    ::kPathBufferSize, 0
pathname_src:
        .res    ::kPathBufferSize, 0

;;; Copy of `pathname_src` modified for display
display_path:
        .res    ::kPathBufferSize, 0

;;; Paths for overall operation
dst_path:       .res    64, 0
src_path:       .res    64, 0
filename:       .res    16, 0

;;; ============================================================

recursion_depth:        .byte   0 ; How far down the directory structure are we
entries_per_block:      .byte   0
ref_num:                .byte   0
entry_index_in_dir:     .word   0
target_index:           .word   0

;;; Stack used when descending directories; keeps track of entry index within
;;; directories.
index_stack:    .res    ::kDirStackBufferSize, 0
stack_index:    .byte   0

entry_index_in_block:   .byte   0

;;; ============================================================

.proc PushIndexToStack
        ldx     stack_index
        copy8   target_index, index_stack,x
        inx
        copy8   target_index+1, index_stack,x
        inx
        stx     stack_index
        rts
.endproc ; PushIndexToStack

;;; ============================================================

.proc PopIndexFromStack
        ldx     stack_index
        dex
        copy8   index_stack,x, target_index+1
        dex
        copy8   index_stack,x, target_index
        stx     stack_index
        rts
.endproc ; PopIndexFromStack

;;; ============================================================

.proc OpenSrcDir
        lda     #$00
        sta     entry_index_in_dir
        sta     entry_index_in_dir+1
        sta     entry_index_in_block
        MLI_CALL OPEN, open_params
        jcs     HandleErrorCode

        lda     open_params::ref_num
        sta     ref_num
        sta     read_block_pointers_params::ref_num
        MLI_CALL READ, read_block_pointers_params
        jcs     HandleErrorCode

        copy8   #13, entries_per_block ; so ReadFileEntry doesn't immediately advance
        jsr     ReadFileEntry          ; read the rest of the header

        copy8   file_entry-4 + SubdirectoryHeader::entries_per_block, entries_per_block

        rts
.endproc ; OpenSrcDir

;;; ============================================================

.proc DoCloseFile
        lda     ref_num
        sta     close_params::ref_num
        MLI_CALL CLOSE, close_params
        jcs     HandleErrorCode

        rts
.endproc ; DoCloseFile

;;; ============================================================

.proc ReadFileEntry
        inc16   entry_index_in_dir

        ;; Skip entry
        lda     ref_num
        sta     read_fileentry_params::ref_num
        MLI_CALL READ, read_fileentry_params
    IF_CS
        cmp     #ERR_END_OF_FILE
        beq     eof
        jmp     HandleErrorCode
    END_IF

        inc     entry_index_in_block
        lda     entry_index_in_block
        cmp     entries_per_block
        bcc     done

        ;; Advance to first entry in next "block"
        copy8   #0, entry_index_in_block
        lda     ref_num
        sta     read_padding_bytes_params::ref_num
        MLI_CALL READ, read_padding_bytes_params
        jcs     HandleErrorCode

done:   return  #0

eof:    return  #$FF
.endproc ; ReadFileEntry

;;; ============================================================

.proc DescendDirectory
        copy16  entry_index_in_dir, target_index
        jsr     DoCloseFile
        jsr     PushIndexToStack
        jsr     AppendFilenameToSrcPathname
        jmp     OpenSrcDir
.endproc ; DescendDirectory

.proc AscendDirectory
        jsr     DoCloseFile
        jsr     op_jt3
        jsr     RemoveSegmentFromSrcPathname
        jsr     PopIndexFromStack
        jsr     OpenSrcDir
        jsr     AdvanceToTargetEntry
        jmp     op_jt2
.endproc ; AscendDirectory

.proc AdvanceToTargetEntry
:       cmp16   entry_index_in_dir, target_index
    IF_LT
        jsr     ReadFileEntry
        jmp     :-
    END_IF

        rts
.endproc ; AdvanceToTargetEntry

;;; ============================================================

.proc HandleDirectory
        copy8   #0, recursion_depth
        jsr     OpenSrcDir
loop:
        jsr     ReadFileEntry
    IF_ZERO
        param_call app::AdjustFileEntryCase, file_entry

        lda     file_entry+FileEntry::storage_type_name_length
        beq     loop
        and     #NAME_LENGTH_MASK
        sta     file_entry+FileEntry::storage_type_name_length
        copy8   #0, copy_err_flag
        jsr     op_jt1
        lda     copy_err_flag
        bne     loop
        lda     file_entry+FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     loop
        jsr     DescendDirectory
        inc     recursion_depth
        jmp     loop
    END_IF

        lda     recursion_depth
    IF_NOT_ZERO
        jsr     AscendDirectory
        dec     recursion_depth
        jmp     loop
    END_IF

        jmp     DoCloseFile
.endproc ; HandleDirectory

;;; ============================================================

copy_err_flag:  .byte   0

;;; ============================================================

op_jt1: jmp     (op_jt_addr1)
op_jt2: jmp     (op_jt_addr2)
op_jt3: jmp     (op_jt_addr3)

;;; ============================================================

;;; Jump table for `CopyFiles`
copy_jt:
        .addr   CopyVisitFile
        .addr   PopDstSegment
        .addr   NoOp2

;;; ============================================================

.proc CopyFiles
        ;; Prepare jump table
        ldy     #5
    DO
        copy8   copy_jt,y, op_jt_addrs,y
        dey
    WHILE_POS

        tsx
        stx     saved_stack

        copy8   #$FF, LA4F9
        jsr     CopyPathsFromBufsToSrcAndDst
        MLI_CALL GET_FILE_INFO, get_dst_file_info_params
        jcs     HandleErrorCode

        ;; Is there enough space?
        sub16   get_dst_file_info_params::aux_type, get_dst_file_info_params::blocks_used, blocks
        cmp16   blocks, blocks_total
    IF_LT
        jmp     ShowDiskFullError
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

        MLI_CALL GET_FILE_INFO, get_dst_file_info_params
        bcc     check_src
        cmp     #ERR_FILE_NOT_FOUND
        beq     check_src
        cmp     #ERR_VOL_NOT_FOUND
        beq     check_src
        cmp     #ERR_PATH_NOT_FOUND
        bne     error

check_src:
        MLI_CALL GET_FILE_INFO, get_src_file_info_params
        bcc     LA491
        cmp     #ERR_VOL_NOT_FOUND
        beq     LA488
        cmp     #ERR_FILE_NOT_FOUND
        bne     error
LA488:  jsr     ShowInsertSourceDiskAlert
        jmp     check_src       ; retry

error:  jmp     HandleErrorCode

LA491:  lda     get_src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        lda     #0
        beq     LA4A2
is_dir: lda     #$FF
LA4A2:  sta     is_dir_flag

        ldy     #$07
    DO
        copy8   get_src_file_info_params,y, create_params,y
        dey
    WHILE_Y_NE  #$02

        copy8   #ACCESS_DEFAULT, create_params::access
        jsr     CheckSpace2
        bcc     LA4BF
        jmp     ShowDiskFullError

        ;; Copy creation date/time
LA4BF:  ldy     #(get_src_file_info_params::create_time+1 - get_src_file_info_params)
        ldx     #(create_params::create_time+1 - create_params)
    DO
        copy8   get_src_file_info_params,y, create_params,x
        dex
        dey
    WHILE_Y_NE  #(get_src_file_info_params::create_date-1 - get_src_file_info_params)

        lda     create_params::storage_type
    IF_A_EQ     #ST_VOLUME_DIRECTORY
        copy8   #ST_LINKED_DIRECTORY, create_params::storage_type
    END_IF

        MLI_CALL CREATE, create_params
    IF_CS
      IF_A_NE   #ERR_DUPLICATE_FILENAME
        jmp     HandleErrorCode
      END_IF
    END_IF

        lda     is_dir_flag
        beq     do_file
        jmp     HandleDirectory

blocks: .word   0

do_file:
        jmp     CopyFile

is_dir_flag:
        .byte   0

LA4F9:  .byte   0
.endproc ; CopyFiles

;;; ============================================================

src_path_slash_index:           ; TODO: Written but never read?
        .byte   0

saved_stack:
        .byte   0

PopDstSegment:
        jmp     RemoveSegmentFromDstPathname

;;; ============================================================

.proc CopyVisitFile
        jsr     CheckEscapeKeyDown
        jeq     RestoreStackAndReturn

        lda     file_entry+FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     is_file

        ;; --------------------------------------------------
        ;; Directory
        jsr     AppendFilenameToSrcPathname
        jsr     draw_window_content_ep2
        MLI_CALL GET_FILE_INFO, get_src_file_info_params
        bcc     LA528
        jmp     HandleErrorCode

err:    jsr     RemoveSegmentFromDstPathname
        jsr     RemoveSegmentFromSrcPathname
        copy8   #$FF, copy_err_flag
        rts

LA528:  jsr     AppendFilenameToDstPathname
        jsr     CreateDstFile
        bcs     err
        jmp     RemoveSegmentFromSrcPathname

        ;; --------------------------------------------------
        ;; Regular File
is_file:
        jsr     AppendFilenameToDstPathname
        jsr     AppendFilenameToSrcPathname
        jsr     draw_window_content_ep2
        MLI_CALL GET_FILE_INFO, get_src_file_info_params
        jcs     HandleErrorCode

        jsr     CheckSpace2
        jcs     ShowDiskFullError

        jsr     RemoveSegmentFromSrcPathname
        jsr     CreateDstFile
        bcs     CheckSpace
        jsr     AppendFilenameToSrcPathname
        jsr     CopyFile
        jsr     RemoveSegmentFromSrcPathname
        jsr     RemoveSegmentFromDstPathname
        rts

.endproc ; CopyVisitFile

;;; ============================================================

.proc CheckSpace
        jsr     RemoveSegmentFromDstPathname

ep2:    MLI_CALL GET_FILE_INFO, get_src_file_info_params
        jcs     HandleErrorCode

        copy16  #0, existing_blocks
        MLI_CALL GET_FILE_INFO, get_dst_file_info_params
        bcc     exists
        cmp     #ERR_FILE_NOT_FOUND
        beq     LA5A1
        jmp     HandleErrorCode

exists: copy16  get_dst_file_info_params::blocks_used, existing_blocks

LA5A1:  copy8   pathname_dst, saved_length
        ;; Strip to vol name - either end of string or next slash
        ldy     #1
    DO
        iny
        cpy     pathname_dst
        bcs     has_room
        lda     pathname_dst,y
    WHILE_A_NE  #'/'
        tya
        sta     pathname_dst

        ;; Total blocks/used blocks on destination volume
        MLI_CALL GET_FILE_INFO, get_dst_file_info_params
        jcs     HandleErrorCode

        ;; aux = total blocks
        sub16   get_dst_file_info_params::aux_type, get_dst_file_info_params::blocks_used, blocks_free
        add16   blocks_free, existing_blocks, blocks_free
        cmp16   blocks_free, get_src_file_info_params::blocks_used
        bcs     has_room

        ;; Not enough room
        sec
        bcs     LA603
has_room:
        clc

LA603:  copy8   saved_length, pathname_dst
        rts

blocks_free:              ; Blocks free on volume
        .word   0
saved_length:
        .byte   0
existing_blocks:          ; Blocks taken by file that will be replaced
        .word   0
.endproc ; CheckSpace
CheckSpace2 := CheckSpace::ep2

;;; ============================================================

.proc CopyFile
        MLI_CALL OPEN, open_src_params
        jcs     HandleErrorCode

        MLI_CALL OPEN, open_dst_params
        jcs     HandleErrorCode

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

loop:
        ;; Read a chunk
        copy16  #kDirCopyBufSize, read_src_params::request_count
        MLI_CALL READ, read_src_params
    IF_CS
        cmp     #ERR_END_OF_FILE
        beq     done
        jmp     HandleErrorCode
    END_IF

        ;; EOF?
        lda     read_src_params::trans_count
        ora     read_src_params::trans_count+1
        beq     done

        ;; Write the chunk
        jsr     _WriteDst
        jcs     HandleErrorCode
        jmp     loop

done:
        MLI_CALL CLOSE, close_dst_params
        MLI_CALL CLOSE, close_src_params
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
        beq     not_sparse

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
        bne     not_sparse

        ;; Block is all zeros, skip over it
        add16_8 mark_dst_params::position+1, #.hibyte(BLOCK_SIZE)
        MLI_CALL SET_EOF, mark_dst_params
        MLI_CALL SET_MARK, mark_dst_params
        jmp     next_block

        ;; Block is not sparse, write it
not_sparse:
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
.endproc ; CopyFile

;;; ============================================================

.proc CreateDstFile
        ;; Copy `file_type`, `aux_type`, and `storage_type`
        ldx     #(get_src_file_info_params::storage_type - get_src_file_info_params)
    DO
        copy8   get_src_file_info_params,x, create_params2,x
        dex
    WHILE_X_NE  #(get_src_file_info_params::file_type - get_src_file_info_params) - 1

        MLI_CALL CREATE, create_params2
    IF_CS
      IF_A_NE   #ERR_DUPLICATE_FILENAME
        jmp     HandleErrorCode
      END_IF
    END_IF
        clc                     ; treated as success
        rts
.endproc ; CreateDstFile

;;; ============================================================

;;; Jump table for `EnumerateFiles`
enum_jt:
        .addr   EnumerateVisitFile
        .addr   NoOp
        .addr   NoOp2

;;; ============================================================

.proc EnumerateFiles
        ;; Prepare jump table
        ldy     #5
    DO
        copy8   enum_jt,y, addr_table,y
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
        jsr     ShowInsertSourceDiskAlert
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
        jsr     HandleDirectory
        lda     storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     visit

        ;; If copying a volume dir to RAMCard, the volume dir
        ;; will not be counted as a file during enumeration but
        ;; will be counted during copy, so include it to avoid
        ;; off-by-one.
        ;; https://github.com/a2stuff/a2d/issues/564
        inc16   file_count
        jsr     UpdateFileCountDisplay
        return  #0

is_dir_flag:
        .byte   0
storage_type:
        .byte   0

visit:  jsr     EnumerateVisitFile
        return  #0
.endproc ; EnumerateFiles

;;; ============================================================

.proc NoOp
        rts
.endproc ; NoOp

;;; ============================================================

.proc EnumerateVisitFile
        jsr     CheckEscapeKeyDown
        jeq     RestoreStackAndReturn

        jsr     AppendFilenameToSrcPathname
        MLI_CALL GET_FILE_INFO, get_src_file_info_params
    IF_CC
        add16   blocks_total, get_src_file_info_params::blocks_used, blocks_total
    END_IF
        inc16   file_count
        jsr     RemoveSegmentFromSrcPathname
        jmp     UpdateFileCountDisplay
.endproc ; EnumerateVisitFile

;;; ============================================================

file_count:
        .word   0
total_count:
        .word   0
blocks_total:
        .word   0

;;; ============================================================

.proc AppendFilenameToSrcPathname
        lda     file_entry+FileEntry::storage_type_name_length
        RTS_IF_ZERO

        ldx     #$00
        ldy     pathname_src
        copy8   #'/', pathname_src+1,y
        iny
:       cpx     file_entry+FileEntry::storage_type_name_length
        bcs     :+
        copy8   file_entry+FileEntry::file_name,x, pathname_src+1,y
        inx
        iny
        jmp     :-              ; TODO: `BNE`
:
        sty     pathname_src
        rts
.endproc ; AppendFilenameToSrcPathname

;;; ============================================================

.proc RemoveSegmentFromSrcPathname
        ldx     pathname_src
        RTS_IF_ZERO

    DO
        lda     pathname_src,x
        cmp     #'/'
        beq     :+
        dex
    WHILE_NOT_ZERO
        stx     pathname_src
        rts
:
        dex
        stx     pathname_src
        rts
.endproc ; RemoveSegmentFromSrcPathname

;;; ============================================================

.proc AppendFilenameToDstPathname
        lda     file_entry+FileEntry::storage_type_name_length
        RTS_IF_ZERO

        ldx     #$00
        ldy     pathname_dst
        copy8   #'/', pathname_dst+1,y
        iny
:       cpx     file_entry+FileEntry::storage_type_name_length
        bcs     :+
        copy8   file_entry+FileEntry::file_name,x, pathname_dst+1,y
        inx
        iny
        jmp     :-              ; TODO: `BNE`
:
        sty     pathname_dst
        rts
.endproc ; AppendFilenameToDstPathname

;;; ============================================================

.proc RemoveSegmentFromDstPathname
        ldx     pathname_dst
        RTS_IF_ZERO

    DO
        lda     pathname_dst,x
        cmp     #'/'
        beq     :+
        dex
    WHILE_NOT_ZERO
        stx     pathname_dst
        rts
:
        dex
        stx     pathname_dst
        rts
.endproc ; RemoveSegmentFromDstPathname

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

ep2:    dec     file_count
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
.endproc ; DrawWindowContent
        draw_window_content_ep2 := DrawWindowContent::ep2
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

.proc ShowInsertSourceDiskAlert
        lda     #AlertID::insert_source_disk
        jsr     app::ShowAlert
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
    IF_ZERO                         ; `kAlertResultCancel` = 1
        jmp     app::SetCursorWatch ; try again
    END_IF
        jmp     RestoreStackAndReturn
.endproc ; ShowInsertSourceDiskAlert

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
        jmp     RestoreStackAndReturn
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

;;; Output: Z=1 if Escape is down
.proc CheckEscapeKeyDown
        MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_params::kind
        cmp     #MGTK::EventKind::key_down
        bne     ret
        lda     app::event_params::key
        cmp     #CHAR_ESCAPE
ret:    rts
.endproc ; CheckEscapeKeyDown

;;; ============================================================

        .include "../lib/drawdialogpath.s"

        ReadSetting := app::ReadSetting
        .include "../lib/inttostring.s"
        .include "../lib/drawstring.s"

;;; ============================================================

.endscope ; file_copier

file_copier__Exec   := file_copier::Exec

        ENDSEG OverlayCopyDialog
