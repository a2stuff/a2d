;;; ============================================================
;;; Recursive File Copy - Overlay #2
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        RESOURCE_FILE "ovl_file_copy.res"

        .org OVERLAY_ADDR

.scope file_copier
Exec:
        sta     LA027
        jsr     OpenWindow
        lda     LA027
        jsr     app::GetSelectorListPathAddr
        jsr     LA802
        jsr     LA6BD
        jsr     DrawWindowContent
        lda     LA027
        jsr     app::GetSelectorListPathAddr
        jsr     LA802
        jsr     LA3F6
        pha
        jsr     CloseWindow
        pla
        rts

LA027:
        .byte   $00

;;; ============================================================

        DEFINE_OPEN_PARAMS open_params, pathname1, $800

        ;; 4 bytes is .sizeof(SubdirectoryHeader) - .sizeof(FileEntry)
        kBlockPointersSize = 4
        .assert .sizeof(SubdirectoryHeader) - .sizeof(FileEntry) = kBlockPointersSize, error, "bad structs"
        DEFINE_READ_PARAMS read_block_pointers_params, buf_block_pointers, kBlockPointersSize ; For skipping prev/next pointers in directory data
buf_block_pointers:
        .res    kBlockPointersSize, 0

        DEFINE_CLOSE_PARAMS close_params

        DEFINE_READ_PARAMS read_fileentry_params, buf_dir_header, .sizeof(FileEntry)

        ;; Blocks are 512 bytes, 13 entries of 39 bytes each leaves 5 bytes between.
        ;; Except first block, directory header is 39+4 bytes, leaving 1 byte, but then
        ;; block pointers are the next 4.
        kMaxPaddingBytes = 5
        DEFINE_READ_PARAMS read_padding_bytes_params, buf_padding_bytes, kMaxPaddingBytes
buf_padding_bytes:
        .res    kMaxPaddingBytes, 0

        DEFINE_CLOSE_PARAMS close_params_src
        DEFINE_CLOSE_PARAMS close_params_dst

        io_buf_src = $D00
        io_buf_dst = $1100
        data_buf = $1500

        DEFINE_OPEN_PARAMS open_params_src, pathname1, io_buf_src
        DEFINE_OPEN_PARAMS open_params_dst, pathname_dst, io_buf_dst

        kDirCopyBufSize = $B00

        DEFINE_READ_PARAMS read_params_src, data_buf, kDirCopyBufSize
        DEFINE_WRITE_PARAMS write_params_dst, data_buf, kDirCopyBufSize

        DEFINE_CREATE_PARAMS create_params2, pathname_dst, $C3

        DEFINE_CREATE_PARAMS create_params, pathname_dst

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params2, pathname1

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, pathname_dst

buf_dir_header:
        .res    48, 0

addr_table:

LA0EC:  .word   DoCopy
LA0EE:  .word   LA4FC
LA0F0:  .word   LA0F2

LA0F2:  rts

pathname_dst:
        .res    ::kPathBufferSize, 0
pathname1:
        .res    ::kPathBufferSize, 0

LA176:  .res    64, 0
LA1B6:  .res    64, 0
LA1F6:  .res    16, 0

;;; ============================================================

recursion_depth:        .byte   0 ; How far down the directory structure are we
entries_per_block:      .byte   13 ; TODO: Read this from directory header
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
        lda     target_index
        sta     index_stack,x
        inx
        lda     target_index+1
        sta     index_stack,x
        inx
        stx     stack_index
        rts
.endproc

;;; ============================================================

.proc PopIndexFromStack
        ldx     stack_index
        dex
        lda     index_stack,x
        sta     target_index+1
        dex
        lda     index_stack,x
        sta     target_index
        stx     stack_index
        rts
.endproc

;;; ============================================================

.proc OpenSrcDir
        lda     #$00
        sta     entry_index_in_dir
        sta     entry_index_in_dir+1
        sta     entry_index_in_block
        MLI_CALL OPEN, open_params
        beq     l1
        jmp     HandleErrorCode

l1:     lda     open_params::ref_num
        sta     ref_num
        sta     read_block_pointers_params::ref_num
        MLI_CALL READ, read_block_pointers_params
        beq     l2
        jmp     HandleErrorCode

l2:     jsr     ReadFileEntry
        rts
.endproc

;;; ============================================================

.proc DoCloseFile
        lda     ref_num
        sta     close_params::ref_num
        MLI_CALL CLOSE, close_params
        beq     l1
        jmp     HandleErrorCode

l1:     rts
.endproc

;;; ============================================================

.proc ReadFileEntry
        inc16   entry_index_in_dir

        ;; Skip entry
        lda     ref_num
        sta     read_fileentry_params::ref_num
        MLI_CALL READ, read_fileentry_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     eof
        jmp     HandleErrorCode
:
        ;; TODO: Could AdjustFileEntryCase here

        inc     entry_index_in_block
        lda     entry_index_in_block
        cmp     entries_per_block
        bcc     done

        ;; Advance to first entry in next "block"
        lda     #0
        sta     entry_index_in_block
        lda     ref_num
        sta     read_padding_bytes_params::ref_num
        MLI_CALL READ, read_padding_bytes_params
        beq     :+
        jmp     HandleErrorCode
:

done:   return  #0

eof:    return  #$FF
.endproc

;;; ============================================================

.proc DescendDirectory
        copy16  entry_index_in_dir, target_index
        jsr     DoCloseFile
        jsr     PushIndexToStack
        jsr     LA75D
        jsr     OpenSrcDir
        rts
.endproc

.proc AscendDirectory
        jsr     DoCloseFile
        jsr     LA3E9
        jsr     LA782
        jsr     PopIndexFromStack
        jsr     OpenSrcDir
        jsr     AdvanceToTargetEntry
        jsr     LA3E6
        rts
.endproc

.proc AdvanceToTargetEntry
:       cmp16   entry_index_in_dir, target_index
        beq     :+
        jsr     ReadFileEntry
        jmp     :-

:       rts
.endproc

;;; ============================================================

.proc CopyDirectory
        lda     #$00
        sta     recursion_depth
        jsr     OpenSrcDir
l1:     jsr     ReadFileEntry
        bne     l2
        lda     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        beq     l1
        lda     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        sta     LA3EC
        and     #NAME_LENGTH_MASK
        sta     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        lda     #$00
        sta     copy_err_flag
        jsr     LA3E3
        lda     copy_err_flag
        bne     l1
        lda     buf_dir_header+SubdirectoryHeader::reserved-4
        cmp     #$0F
        bne     l1
        jsr     DescendDirectory
        inc     recursion_depth
        jmp     l1

l2:     lda     recursion_depth
        beq     l3
        jsr     AscendDirectory
        dec     recursion_depth
        jmp     l1

l3:     jsr     DoCloseFile
        rts
.endproc

;;; ============================================================

copy_err_flag:  .byte   0

;;; ============================================================

LA3E3:  jmp     (LA0EC)
LA3E6:  jmp     (LA0EE)
LA3E9:  jmp     (LA0F0)

LA3EC:  .byte   0
        .byte   0
        .byte   0
        .byte   0


LA3F0:  .addr   DoCopy
        .addr   LA4FC
        .addr   LA0F2

;;; ============================================================

.proc LA3F6
        ldy     #5
LA3F8:  lda     LA3F0,y
        sta     LA0EC,y
        dey
        bpl     LA3F8
        tsx
        stx     saved_stack
        lda     #$FF
        sta     LA4F9
        jsr     LA7D9
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     LA41B
        jmp     HandleErrorCode

LA41B:  sub16   get_file_info_params::aux_type, get_file_info_params::blocks_used, LA4F3
        cmp16   LA4F3, blocks_total
        bcs     LA43F
        jmp     LAACB

LA43F:  ldx     pathname_dst
        lda     #'/'
        sta     pathname_dst+1,x
        inc     pathname_dst
        ldy     #$00
        ldx     pathname_dst
LA44F:  iny
        inx
        lda     LA1F6,y
        sta     pathname_dst,x
        cpy     LA1F6
        bne     LA44F
        stx     pathname_dst
        MLI_CALL GET_FILE_INFO, get_file_info_params
        cmp     #ERR_FILE_NOT_FOUND
        beq     LA475
        cmp     #ERR_VOL_NOT_FOUND
        beq     LA475
        cmp     #ERR_PATH_NOT_FOUND
        beq     LA475
        rts

LA475:  MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     LA491
        cmp     #ERR_VOL_NOT_FOUND
        beq     LA488
        cmp     #ERR_FILE_NOT_FOUND
        bne     LA48E
LA488:  jsr     ShowInsertSourceDiskAlert
        jmp     LA475           ; retry

LA48E:  jmp     HandleErrorCode

LA491:  lda     get_file_info_params2::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     LA4A0
        cmp     #ST_LINKED_DIRECTORY
        beq     LA4A0
        lda     #$00
        beq     LA4A2
LA4A0:  lda     #$FF
LA4A2:  sta     is_dir_flag
        ldy     #$07
LA4A7:  lda     get_file_info_params2,y
        sta     create_params,y
        dey
        cpy     #$02
        bne     LA4A7
        lda     #ACCESS_DEFAULT
        sta     create_params::access
        jsr     LA56D
        bcc     LA4BF
        jmp     LAACB

        ;; Copy creation date/time
LA4BF:  ldy     #(get_file_info_params2::create_time+1 - get_file_info_params2)
        ldx     #(create_params::create_time+1 - create_params)
:       lda     get_file_info_params2,y
        sta     create_params,x
        dex
        dey
        cpy     #(get_file_info_params2::create_date-1 - get_file_info_params2)
        bne     :-

        lda     create_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     LA4DB
        lda     #ST_LINKED_DIRECTORY
        sta     create_params::storage_type
LA4DB:  MLI_CALL CREATE, create_params
        beq     LA4E9
        jmp     HandleErrorCode

LA4E9:  lda     is_dir_flag
        beq     LA4F5
        jmp     CopyDirectory

        .byte   0
        rts

LA4F3:  .byte   0
        .byte   0
LA4F5:  jmp     CopyDir

is_dir_flag:
        .byte   0
LA4F9:  .byte   0
.endproc

;;; ============================================================

LA4FA:  .byte   0

saved_stack:
        .byte   0

LA4FC:  jmp     LA7C0

;;; ============================================================

.proc DoCopy
        lda     buf_dir_header+SubdirectoryHeader::reserved-4
        cmp     #$0F
        bne     LA536
        jsr     LA75D
        jsr     draw_window_content_ep2
        MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     LA528
        jmp     HandleErrorCode

LA51A:  jsr     LA7C0
        jsr     LA782
        lda     #$FF
        sta     copy_err_flag
        jmp     LA569

LA528:  jsr     LA79B
        jsr     LA69A
        bcs     LA51A
        jsr     LA782
        jmp     LA569

LA536:  jsr     LA79B
        jsr     LA75D
        jsr     draw_window_content_ep2
        MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     LA54D
        jmp     HandleErrorCode

LA54D:  jsr     LA56D
        bcc     LA555
        jmp     LAACB

LA555:  jsr     LA782
        jsr     LA69A
        bcs     LA56A
        jsr     LA75D
        jsr     CopyDir
        jsr     LA782
        jsr     LA7C0
LA569:  rts

.endproc

;;; ============================================================


LA56A:  jsr     LA7C0
LA56D:  MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     LA57B
        jmp     HandleErrorCode

LA57B:  lda     #$00
        sta     LA60E
        sta     LA60F
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     LA595
        cmp     #ERR_FILE_NOT_FOUND
        beq     LA5A1
        jmp     HandleErrorCode

LA595:  copy16  get_file_info_params::blocks_used, LA60E
LA5A1:  lda     pathname_dst
        sta     LA60C
        ldy     #$01
LA5A9:  iny
        cpy     pathname_dst
        bcs     LA602
        lda     pathname_dst,y
        cmp     #'/'
        bne     LA5A9
        tya
        sta     pathname_dst
        sta     LA60D
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     LA5CB
        jmp     HandleErrorCode

LA5CB:  sub16   get_file_info_params::aux_type, get_file_info_params::blocks_used, LA60A
        sub16   LA60A, LA60E, LA60A
        cmp16   LA60A, get_file_info_params2::blocks_used
        bcs     LA602
        sec
        bcs     LA603
LA602:  clc
LA603:  lda     LA60C
        sta     pathname_dst
        rts

LA60A:  .word   0
LA60C:  .byte   0
LA60D:  .byte   0
LA60E:  .byte   0
LA60F:  .byte   0

;;; ============================================================

.proc CopyDir
        MLI_CALL OPEN, open_params_src
        beq     LA61E
        jsr     HandleErrorCode
LA61E:  MLI_CALL OPEN, open_params_dst
        beq     LA62C
        jmp     HandleErrorCode

LA62C:  lda     open_params_src::ref_num
        sta     read_params_src::ref_num
        sta     close_params_src::ref_num
        lda     open_params_dst::ref_num
        sta     write_params_dst::ref_num
        sta     close_params_dst::ref_num
LA63E:  copy16  #kDirCopyBufSize, read_params_src::request_count
        MLI_CALL READ, read_params_src
        beq     LA65A
        cmp     #ERR_END_OF_FILE
        beq     LA687
        jmp     HandleErrorCode

LA65A:  copy16  read_params_src::trans_count, write_params_dst::request_count
        ora     read_params_src::trans_count
        beq     LA687
        MLI_CALL WRITE, write_params_dst
        beq     LA679
        jmp     HandleErrorCode

LA679:  lda     write_params_dst::trans_count
        cmp     #<kDirCopyBufSize
        bne     LA687
        lda     write_params_dst::trans_count+1
        cmp     #>kDirCopyBufSize
        beq     LA63E
LA687:  MLI_CALL CLOSE, close_params_dst
        MLI_CALL CLOSE, close_params_src
        rts
.endproc

;;; ============================================================


LA69A:  ldx     #(get_file_info_params2::storage_type - get_file_info_params2)
LA69C:  lda     get_file_info_params2,x
        sta     create_params2,x
        dex
        cpx     #$03
        bne     LA69C
        MLI_CALL CREATE, create_params2
        clc
        beq     LA6B6
        jmp     HandleErrorCode

LA6B6:  rts

LA6B7:  .addr   LA729
        .addr   LA728
        .addr   LA0F2

;;; ============================================================

.proc LA6BD
        ldy     #5
:       lda     LA6B7,y
        sta     addr_table,y
        dey
        bpl     :-

        lda     #$00
        sta     file_count
        sta     file_count+1
        sta     blocks_total
        sta     blocks_total+1
        ldy     #BITMAP_SIZE-1
        lda     #$00
LA6DA:  sta     BITMAP,y
        dey
        bpl     LA6DA
        jsr     LA7D9
LA6E3:  MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     LA6FF
        cmp     #ERR_VOL_NOT_FOUND
        beq     LA6F6
        cmp     #ERR_FILE_NOT_FOUND
        bne     LA6FC
LA6F6:  jsr     ShowInsertSourceDiskAlert
        jmp     LA6E3           ; retry

LA6FC:  jmp     HandleErrorCode

LA6FF:  lda     get_file_info_params2::storage_type
        sta     storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     LA711
        cmp     #ST_LINKED_DIRECTORY
        beq     LA711
        lda     #$00
        beq     LA713
LA711:  lda     #$FF
LA713:  sta     is_dir_flag
        beq     LA725
        jsr     CopyDirectory
        lda     storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     LA725

        ;; If copying a volume dir to RAMCard, the volume dir
        ;; will not be counted as a file during enumeration but
        ;; will be counted during copy, so include it to avoid
        ;; off-by-one.
        ;; https://github.com/a2stuff/a2d/issues/564
        inc16   file_count
        jsr     UpdateFileCountDisplay

        rts

is_dir_flag:
        .byte   0
storage_type:
        .byte   0

LA725:  jmp     LA729
.endproc

;;; ============================================================

LA728:  rts

;;; ============================================================

.proc LA729
        jsr     LA75D
        MLI_CALL GET_FILE_INFO, get_file_info_params2
        bne     :+
        add16   blocks_total, get_file_info_params2::blocks_used, blocks_total
:       inc16   file_count
        jsr     LA782
        jsr     UpdateFileCountDisplay
        rts
.endproc

file_count:
        .word   0
blocks_total:
        .word   0

;;; ============================================================

.proc LA75D
        lda     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        bne     l1
        rts

l1:     ldx     #$00
        ldy     pathname1
        lda     #'/'
        sta     pathname1+1,y
        iny
l2:     cpx     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        bcs     l3
        lda     buf_dir_header+SubdirectoryHeader::file_name-4,x
        sta     pathname1+1,y
        inx
        iny
        jmp     l2

l3:     sty     pathname1
        rts
.endproc

;;; ============================================================

.proc LA782
        ldx     pathname1
        bne     :+
        rts

:       lda     pathname1,x
        cmp     #'/'
        beq     :+
        dex
        bne     :-
        stx     pathname1
        rts

:       dex
        stx     pathname1
        rts
.endproc

;;; ============================================================

.proc LA79B
        lda     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        bne     l1
        rts

l1:     ldx     #$00
        ldy     pathname_dst
        lda     #'/'
        sta     pathname_dst+1,y
        iny
l2:     cpx     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        bcs     l3
        lda     buf_dir_header+SubdirectoryHeader::file_name-4,x
        sta     pathname_dst+1,y
        inx
        iny
        jmp     l2

l3:     sty     pathname_dst
        rts
.endproc

;;; ============================================================

.proc LA7C0
        ldx     pathname_dst
        bne     l1
        rts

l1:     lda     pathname_dst,x
        cmp     #'/'
        beq     l2
        dex
        bne     l1
        stx     pathname_dst
        rts

l2:     dex
        stx     pathname_dst
        rts
.endproc

;;; ============================================================

.proc LA7D9
        ldy     #$00
        sta     LA4FA
        dey
l1:     iny
        lda     LA1B6,y
        cmp     #'/'
        bne     l2
        sty     LA4FA
l2:     sta     pathname1,y
        cpy     LA1B6
        bne     l1
        ldy     LA176
l3:     lda     LA176,y
        sta     pathname_dst,y
        dey
        bpl     l3
        rts
.endproc

        ;; TODO: Unreachable???
        return  #$00

;;; ============================================================

.proc LA802
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
l1:     lda     ($06),y
        sta     LA1B6,y
        dey
        bpl     l1
        ldy     LA1B6
l2:     lda     LA1B6,y
        cmp     #'/'
        beq     l3
        dey
        bne     l2
l3:     dey
        sty     LA1B6
l4:     lda     LA1B6,y
        cmp     #'/'
        beq     l5
        dey
        bpl     l4
l5:     ldx     #$00
l6:     iny
        inx
        lda     LA1B6,y
        sta     LA1F6,x
        cpy     LA1B6
        bne     l6
        stx     LA1F6
        bit     LCBANK2
        bit     LCBANK2
        ldy     RAMCARD_PREFIX
l7:     lda     RAMCARD_PREFIX,y
        sta     LA176,y
        dey
        bpl     l7
        bit     ROMIN2
        rts
.endproc

;;; ============================================================

.params winfo
        kWidth = 350
        kHeight = 70
window_id:      .byte   $0B
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
textback:       .byte   $7F
textfont:       .addr   FONT
nextwinfo:      .addr   0
.endparams

        DEFINE_RECT_SZ ok_button_rect, winfo::kWidth-20-kButtonWidth, 49, kButtonWidth, kButtonHeight
        DEFINE_POINT ok_button_pos, winfo::kWidth-20-kButtonWidth+4, 59

        DEFINE_RECT_FRAME rect_frame, winfo::kWidth, winfo::kHeight

        DEFINE_LABEL download, res_string_label_download, 116, 16

        DEFINE_POINT pos_copying, 20, 32
        DEFINE_POINT pt2, 20, 45

str_copying:
        PASCAL_STRING res_string_label_copying

        DEFINE_RECT rect_clear_count, 18, 24, winfo::kWidth-kBorderDX*2, 32
        DEFINE_RECT rect_clear_details, kBorderDX*2, 24, winfo::kWidth-kBorderDX*2, winfo::kHeight-kBorderDY*2

.params setportbits_params
        DEFINE_POINT viewloc, 100, 50
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 340, 66
pattern:        .res    8, $FF
masks:          .byte   $FF, $00
penloc:         .word   0, 0
pensize:        .byte   1, 1
penmode:        .byte   MGTK::pencopy
textback:       .byte   $7F
textfont:       .addr   FONT
next:           .addr   0
.endparams

str_not_enough_room:
        PASCAL_STRING res_string_errmsg_not_enough_room
str_click_ok:
        PASCAL_STRING res_string_prompt_click_ok
str_error_download:
        PASCAL_STRING res_string_errmsg_error_download
str_copy_incomplete:
        PASCAL_STRING res_string_errmsg_copy_incomplete
str_files_to_copy:
        PASCAL_STRING res_string_label_files_to_copy
str_files_remaining:
        PASCAL_STRING res_string_label_files_remaining
str_spaces:
        PASCAL_STRING "    "    ; do not localize
str_space:
        PASCAL_STRING " "    ; do not localize

;;; ============================================================

.proc OpenWindow
        MGTK_CALL MGTK::OpenWindow, winfo
        lda     winfo::window_id
        jsr     app::GetWindowPort

        MGTK_CALL MGTK::SetPenMode, app::notpencopy
        MGTK_CALL MGTK::SetPenSize, app::pensize_frame
        MGTK_CALL MGTK::FrameRect, rect_frame
        MGTK_CALL MGTK::SetPenSize, app::pensize_normal

        MGTK_CALL MGTK::MoveTo, download_label_pos
        param_call app::DrawString, download_label_str
        rts
.endproc

;;; ============================================================

.proc DrawWindowContent
        lda     winfo::window_id
        jsr     app::GetWindowPort
        MGTK_CALL MGTK::SetPenMode, app::pencopy
        MGTK_CALL MGTK::PaintRect, rect_clear_details

ep2:    dec     file_count
        lda     file_count
        cmp     #$FF
        bne     :+
        dec     file_count+1
:

        jsr     PopulateCount
        MGTK_CALL MGTK::SetPortBits, setportbits_params
        MGTK_CALL MGTK::SetPenMode, app::pencopy
        MGTK_CALL MGTK::PaintRect, rect_clear_count
        param_call app::AdjustPathCase, pathname1
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call app::DrawString, str_copying
        param_call app::DrawString, str_space
        param_call app::DrawString, pathname1
        MGTK_CALL MGTK::MoveTo, pt2
        param_call app::DrawString, str_files_remaining
        param_call app::DrawString, str_count
        param_call app::DrawString, str_spaces
        rts
.endproc
        draw_window_content_ep2 := DrawWindowContent::ep2
;;; ============================================================

.proc UpdateFileCountDisplay
        jsr     PopulateCount
        MGTK_CALL MGTK::SetPortBits, setportbits_params
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call app::DrawString, str_files_to_copy
        param_call app::DrawString, str_count
        param_call app::DrawString, str_spaces
        rts
.endproc

;;; ============================================================

.proc ShowInsertSourceDiskAlert
        lda     #AlertID::insert_source_disk
        jsr     app::ShowAlert
        bne     :+              ; `kAlertResultCancel` = 1
        jsr     app::SetWatchCursor ; try again
        rts

:       jmp     RestoreStackAndReturn
.endproc

;;; ============================================================

LAACB:  lda     winfo::window_id
        jsr     app::GetWindowPort
        MGTK_CALL MGTK::SetPenMode, app::pencopy
        MGTK_CALL MGTK::PaintRect, rect_clear_details
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call app::DrawString, str_not_enough_room
        MGTK_CALL MGTK::MoveTo, pt2
        param_call app::DrawString, str_click_ok
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call app::DrawString, app::ok_button_label
        jsr     SetPointerCursor
        jmp     RestoreStackAndReturn

;;; ============================================================

.proc HandleErrorCode
        lda     winfo::window_id
        jsr     app::GetWindowPort
        MGTK_CALL MGTK::SetPenMode, app::pencopy
        MGTK_CALL MGTK::PaintRect, rect_clear_details
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call app::DrawString, str_error_download
        MGTK_CALL MGTK::MoveTo, pt2
        param_call app::DrawString, str_copy_incomplete
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call app::DrawString, app::ok_button_label
        jsr     SetPointerCursor
        jmp     RestoreStackAndReturn
.endproc

;;; ============================================================

SetPointerCursor:
        jsr     app::SetPointerCursor

;;; ============================================================

event_loop:
        MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     HandleButtonDown
        cmp     #MGTK::EventKind::key_down
        bne     event_loop
        lda     app::event_params::key
        cmp     #CHAR_RETURN
        bne     event_loop
        lda     winfo::window_id
        jsr     app::GetWindowPort
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        jsr     app::SetWatchCursor
        rts

HandleButtonDown:
        MGTK_CALL MGTK::FindWindow, app::findwindow_params
        lda     app::findwindow_params::which_area
        beq     event_loop
        cmp     #MGTK::Area::content
        bne     event_loop
        lda     app::findwindow_params::window_id
        cmp     winfo::window_id
        bne     event_loop
        lda     winfo::window_id
        jsr     app::GetWindowPort
        lda     winfo::window_id
        sta     app::screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, app::screentowindow_params
        MGTK_CALL MGTK::MoveTo, app::screentowindow_windowx
        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
        bne     event_loop
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        jsr     LABE6
        bmi     event_loop
        jsr     app::SetWatchCursor
        rts

LABE6:  lda     #$00
        sta     LAC53
LABEB:  MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_params::kind
        cmp     #MGTK::EventKind::button_up
        beq     LAC3C
        lda     winfo::window_id
        sta     app::screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, app::screentowindow_params
        MGTK_CALL MGTK::MoveTo, app::screentowindow_windowx
        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
        beq     LAC1C
        lda     LAC53
        beq     LAC24
        jmp     LABEB

LAC1C:  lda     LAC53
        bne     LAC24
        jmp     LABEB

LAC24:  MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        lda     LAC53
        clc
        adc     #$80
        sta     LAC53
        jmp     LABEB

LAC3C:  lda     LAC53
        beq     LAC44
        return  #$FF

LAC44:  MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        return  #$00

LAC53:  .byte   0

;;; ============================================================

.proc RestoreStackAndReturn
        ldx     saved_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

.proc CloseWindow
        MGTK_CALL MGTK::CloseWindow, winfo
        rts
.endproc

;;; ============================================================

.proc PopulateCount
        copy16  file_count, value
        ldx     #7
        lda     #' '
:       sta     str_count,x
        dex
        bne     :-
        lda     #0
        sta     nonzero_flag
        ldy     #0
        ldx     #0

loop:   lda     #0
        sta     digit
sloop:  cmp16   value, powers,x
        bpl     subtract
        lda     digit
        bne     not_pad
        bit     nonzero_flag
        bmi     not_pad
        lda     #' '
        bne     store
not_pad:
        ora     #$30            ; to ASCII digit
        pha
        lda     #$80
        sta     nonzero_flag
        pla
store:  sta     str_count+2,y
        iny
        inx
        inx
        cpx     #8
        beq     done
        jmp     loop

subtract:
        inc     digit
        lda     value
        sec
        sbc     powers,x
        sta     value
        lda     value+1
        sbc     powers+1,x
        sta     value+1
        jmp     sloop

done:   lda     value
        ora     #$30            ; number to ASCII digit
        sta     str_count+2,y
        rts

powers: .word   10000, 1000, 100, 10
value:  .word   0
digit:  .byte   0
nonzero_flag:
        .byte   0
.endproc

str_count:
        PASCAL_STRING "       " ; do not localize

;;; ============================================================

.endscope

file_copier__Exec   := file_copier::Exec

        PAD_TO OVERLAY_ADDR + kOverlay2Size
