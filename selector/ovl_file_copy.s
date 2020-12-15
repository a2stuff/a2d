;;; ============================================================
;;; Recursive File Copy - Overlay #2
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        .org $A000

.scope file_copier
exec:
        sta     LA027
        jsr     open_window
        lda     LA027
        jsr     app::get_selector_list_path_addr
        jsr     LA802
        jsr     LA6BD
        jsr     draw_window_content
        lda     LA027
        jsr     app::get_selector_list_path_addr
        jsr     LA802
        jsr     LA3F6
        pha
        jsr     close_window
        pla
        rts

LA027:
        .byte   $00

        DEFINE_OPEN_PARAMS open_params, pathname1, $800
        DEFINE_READ_PARAMS read_params, buf_read_ptr, 4 ; next/prev blocks
buf_read_ptr:
        .res 4, 0
        DEFINE_CLOSE_PARAMS close_params

        DEFINE_READ_PARAMS read_params2, buf_dir_header, .sizeof(SubdirectoryHeader)-4
        DEFINE_READ_PARAMS read_params3, buf_5_bytes, 5
buf_5_bytes:
        .res    5, 0

        .res    4, 0            ; Unused???


        DEFINE_CLOSE_PARAMS close_params_src
        DEFINE_CLOSE_PARAMS close_params_dst

        .byte   $01
        .addr   pathname1

        io_buf_src = $D00
        io_buf_dst = $1100
        data_buf = $1500

        DEFINE_OPEN_PARAMS open_params_src, pathname1, io_buf_src
        DEFINE_OPEN_PARAMS open_params_dst, pathname_dst, io_buf_dst

        kDirCopyBufSize = $B00

        DEFINE_READ_PARAMS read_params_src, data_buf, kDirCopyBufSize
        DEFINE_WRITE_PARAMS write_params_dst, data_buf, kDirCopyBufSize

        DEFINE_CREATE_PARAMS create_params2, pathname_dst, $C3

        DEFINE_CREATE_PARAMS create_params, pathname_dst,
        .byte   0, 0

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params2, pathname1
        .byte   0

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, pathname_dst
        .byte   0

        .byte   $02
        .byte   0
        .byte   0
        .byte   0

buf_dir_header:
        .res    48, 0

addr_table:

LA0EC:  .word   do_copy
LA0EE:  .word   LA4FC
LA0F0:  .word   LA0F2

LA0F2:  rts

        .byte   0

pathname_dst:
        .res    ::kPathBufferSize, 0
pathname1:
        .res    ::kPathBufferSize, 0

LA176:  .res    64, 0
LA1B6:  .res    64, 0
LA1F6:  .res    16, 0
LA206:  .byte   0
LA207:
LA208           := * + 1
LA209           := * + 2
        .byte   $0D, $00, $00
LA20A:  .byte   0
LA20B:  .res    170, 0
LA2B5:  .byte   0
LA2B6:  .byte   0

LA2B7:  ldx     LA2B5
        lda     LA20A
        sta     LA20B,x
        inx
        stx     LA2B5
        rts

LA2C5:  ldx     LA2B5
        dex
        lda     LA20B,x
        sta     LA20A
        stx     LA2B5
        rts

LA2D3:  lda     #$00
        sta     LA208
        sta     LA2B6
        MLI_CALL OPEN, open_params
        beq     LA2E9
        jmp     handle_error_code

LA2E9:  lda     open_params::ref_num
        sta     LA209
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        beq     LA300
        jmp     handle_error_code

LA300:  jsr     LA319
        rts

LA304:  lda     LA209
        sta     close_params::ref_num
        MLI_CALL CLOSE, close_params
        beq     LA318
        jmp     handle_error_code

LA318:  rts

LA319:  inc     LA208
        lda     LA209
        sta     read_params2::ref_num
        MLI_CALL READ, read_params2
        beq     LA330
        jmp     handle_error_code

LA330:  inc     LA2B6
        lda     LA2B6
        cmp     LA207
        bcc     LA35B
        lda     #$00
        sta     LA2B6
        lda     LA209
        sta     read_params3::ref_num
        MLI_CALL READ, read_params3
        beq     LA354
        jmp     handle_error_code

LA354:  lda     read_params3::trans_count
        cmp     read_params3::request_count
        rts

LA35B:  return  #$00

LA35E:  lda     LA208
        sta     LA20A
        jsr     LA304
        jsr     LA2B7
        jsr     LA75D
        jsr     LA2D3
        rts

LA371:  jsr     LA304
        jsr     LA3E9
        jsr     LA782
        jsr     LA2C5
        jsr     LA2D3
        jsr     LA387
        jsr     LA3E6
        rts

LA387:  lda     LA208
        cmp     LA20A
        beq     LA395
        jsr     LA319
        jmp     LA387

LA395:  rts

LA396:  lda     #$00
        sta     LA206
        jsr     LA2D3
LA39E:  jsr     LA319
        bne     LA3D0
        lda     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        beq     LA39E
        lda     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        sta     LA3EC
        and     #NAME_LENGTH_MASK
        sta     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        lda     #$00
        sta     LA3E2
        jsr     LA3E3
        lda     LA3E2
        bne     LA39E
        lda     buf_dir_header+SubdirectoryHeader::reserved-4
        cmp     #$0F
        bne     LA39E
        jsr     LA35E
        inc     LA206
        jmp     LA39E

LA3D0:  lda     LA206
        beq     LA3DE
        jsr     LA371
        dec     LA206
        jmp     LA39E

LA3DE:  jsr     LA304
        rts

LA3E2:  .byte   0

LA3E3:  jmp     (LA0EC)
LA3E6:  jmp     (LA0EE)
LA3E9:  jmp     (LA0F0)

LA3EC:  .byte   0
        .byte   0
        .byte   0
        .byte   0


LA3F0:  .addr   do_copy
        .addr   LA4FC
        .addr   LA0F2

LA3F6:  ldy     #5
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
        jmp     handle_error_code

LA41B:  sub16   get_file_info_params::aux_type, get_file_info_params::blocks_used, LA4F3
        cmp16   LA4F3, LA75B
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
LA488:  jsr     LAABD
        jmp     LA475

LA48E:  jmp     handle_error_code

LA491:  lda     get_file_info_params2::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     LA4A0
        cmp     #ST_LINKED_DIRECTORY
        beq     LA4A0
        lda     #$00
        beq     LA4A2
LA4A0:  lda     #$FF
LA4A2:  sta     LA4F8
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
        jmp     handle_error_code

LA4E9:  lda     LA4F8
        beq     LA4F5
        jmp     LA396

        .byte   0
        rts

LA4F3:  .byte   0
        .byte   0
LA4F5:  jmp     copy_dir

LA4F8:  .byte   0
LA4F9:  .byte   0
LA4FA:  .byte   0

saved_stack:
        .byte   0

LA4FC:  jmp     LA7C0

;;; ============================================================

.proc do_copy
        lda     buf_dir_header+SubdirectoryHeader::reserved-4
        cmp     #$0F
        bne     LA536
        jsr     LA75D
        jsr     draw_window_content_ep2
        MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     LA528
        jmp     handle_error_code

LA51A:  jsr     LA7C0
        jsr     LA782
        lda     #$FF
        sta     LA3E2
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
        jmp     handle_error_code

LA54D:  jsr     LA56D
        bcc     LA555
        jmp     LAACB

LA555:  jsr     LA782
        jsr     LA69A
        bcs     LA56A
        jsr     LA75D
        jsr     copy_dir
        jsr     LA782
        jsr     LA7C0
LA569:  rts

.endproc

;;; ============================================================


LA56A:  jsr     LA7C0
LA56D:  MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     LA57B
        jmp     handle_error_code

LA57B:  lda     #$00
        sta     LA60E
        sta     LA60F
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     LA595
        cmp     #ERR_FILE_NOT_FOUND
        beq     LA5A1
        jmp     handle_error_code

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
        jmp     handle_error_code

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

.proc copy_dir
        MLI_CALL OPEN, open_params_src
        beq     LA61E
        jsr     handle_error_code
LA61E:  MLI_CALL OPEN, open_params_dst
        beq     LA62C
        jmp     handle_error_code

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
        jmp     handle_error_code

LA65A:  copy16  read_params_src::trans_count, write_params_dst::request_count
        ora     read_params_src::trans_count
        beq     LA687
        MLI_CALL WRITE, write_params_dst
        beq     LA679
        jmp     handle_error_code

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
        jmp     handle_error_code

LA6B6:  rts

LA6B7:  .addr   LA729
        .addr   LA728
        .addr   LA0F2

LA6BD:  ldy     #5
:       lda     LA6B7,y
        sta     addr_table,y
        dey
        bpl     :-

        lda     #$00
        sta     LA759
        sta     LA75A
        sta     LA75B
        sta     LA75C
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
LA6F6:  jsr     LAABD
        jmp     LA6E3

LA6FC:  jmp     handle_error_code

LA6FF:  lda     get_file_info_params2::storage_type
        sta     LA724
        cmp     #ST_VOLUME_DIRECTORY
        beq     LA711
        cmp     #ST_LINKED_DIRECTORY
        beq     LA711
        lda     #$00
        beq     LA713
LA711:  lda     #$FF
LA713:  sta     LA723
        beq     LA725
        jsr     LA396
        lda     LA724
        cmp     #$0F
        bne     LA725
        rts

LA723:  .byte   0
LA724:  .byte   0
LA725:  jmp     LA729

LA728:  rts

LA729:  jsr     LA75D
        MLI_CALL GET_FILE_INFO, get_file_info_params2
        bne     LA74A
        add16   LA75B, get_file_info_params2::blocks_used, LA75B
LA74A:  inc16   LA759
        jsr     LA782
        jsr     update_file_count_display
        rts

LA759:  .byte   0
LA75A:  .byte   0
LA75B:  .byte   0
LA75C:  .byte   0
LA75D:  lda     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        bne     LA763
        rts

LA763:  ldx     #$00
        ldy     pathname1
        lda     #'/'
        sta     pathname1+1,y
        iny
LA76E:  cpx     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        bcs     LA77E
        lda     buf_dir_header+SubdirectoryHeader::file_name-4,x
        sta     pathname1+1,y
        inx
        iny
        jmp     LA76E

LA77E:  sty     pathname1
        rts

LA782:  ldx     pathname1
        bne     LA788
        rts

LA788:  lda     pathname1,x
        cmp     #'/'
        beq     LA796
        dex
        bne     LA788
        stx     pathname1
        rts

LA796:  dex
        stx     pathname1
        rts

LA79B:  lda     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        bne     LA7A1
        rts

LA7A1:  ldx     #$00
        ldy     pathname_dst
        lda     #'/'
        sta     pathname_dst+1,y
        iny
LA7AC:  cpx     buf_dir_header+SubdirectoryHeader::storage_type_name_length-4
        bcs     LA7BC
        lda     buf_dir_header+SubdirectoryHeader::file_name-4,x
        sta     pathname_dst+1,y
        inx
        iny
        jmp     LA7AC

LA7BC:  sty     pathname_dst
        rts

LA7C0:  ldx     pathname_dst
        bne     LA7C6
        rts

LA7C6:  lda     pathname_dst,x
        cmp     #'/'
        beq     LA7D4
        dex
        bne     LA7C6
        stx     pathname_dst
        rts

LA7D4:  dex
        stx     pathname_dst
        rts

LA7D9:  ldy     #$00
        sta     LA4FA
        dey
LA7DF:  iny
        lda     LA1B6,y
        cmp     #'/'
        bne     LA7EA
        sty     LA4FA
LA7EA:  sta     pathname1,y
        cpy     LA1B6
        bne     LA7DF
        ldy     LA176
LA7F5:  lda     LA176,y
        sta     pathname_dst,y
        dey
        bpl     LA7F5
        rts

        return  #$00

;;; ============================================================

.proc LA802
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
LA80B:  lda     ($06),y
        sta     LA1B6,y
        dey
        bpl     LA80B
        ldy     LA1B6
LA816:  lda     LA1B6,y
        and     #CHAR_MASK
        cmp     #'/'
        beq     LA822
        dey
        bne     LA816
LA822:  dey
        sty     LA1B6
LA826:  lda     LA1B6,y
        and     #CHAR_MASK
        cmp     #'/'
        beq     LA832
        dey
        bpl     LA826
LA832:  ldx     #$00
LA834:  iny
        inx
        lda     LA1B6,y
        sta     LA1F6,x
        cpy     LA1B6
        bne     LA834
        stx     LA1F6
        lda     LCBANK2
        lda     LCBANK2
        ldy     RAMCARD_PREFIX
LA84D:  lda     RAMCARD_PREFIX,y
        sta     LA176,y
        dey
        bpl     LA84D
        lda     ROMIN2
        rts
.endproc

;;; ============================================================

.proc winfo
        kWidth = 350
        kHeight = 70
window_id:
        .byte   $0B
        .byte   $01,$00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $96,$00
        .byte   $32
        .byte   $00
        .word   500
        .word   140
        .byte   $64
        .byte   $00
        .byte   $32
        .byte   $00
        .addr   MGTK::screen_mapbits
        .byte   MGTK::screen_mapwidth
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .word   350, 70
        .byte   $FF
        .res    8, $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

        .byte   $01,$01
        .byte   $00
        .byte   $7F
        .addr   FONT
        .addr   0
.endproc

rect1:  DEFINE_RECT_SZ 20, 49, kButtonWidth, kButtonHeight
pos1:   DEFINE_POINT 24, 59

rect_frame1:
        DEFINE_RECT_INSET 4, 2, winfo::kWidth, winfo::kHeight
rect_frame2:
        DEFINE_RECT_INSET 5, 3, winfo::kWidth, winfo::kHeight

        DEFINE_LABEL download, "Copying to RAMCard...", 116, 16

pos_copying:    DEFINE_POINT 20, 32
pt2:    DEFINE_POINT 20, 45

str_copying:
        PASCAL_STRING "Copying:"

rect_clear_count:  DEFINE_RECT 18, 24, 344, 32

rect_clear_details:  DEFINE_RECT 6, 24, 344, 66

.params setportbits_params
viewloc:        DEFINE_POINT 100, 50
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, 346, 66
pattern:        .res    8, $FF
masks:          .byte   $FF, $00
penloc:         .word   0, 0
pensize:        .byte   1, 1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   FONT
next:           .addr   0
.endparams

str_not_enough_room:
        PASCAL_STRING "Not enough room in the RAMCard to copy the application."
str_click_ok:
        PASCAL_STRING "Click OK to continue."
str_error_download:
        PASCAL_STRING "An error occured during the download."
str_copy_incomplete:
        PASCAL_STRING "The copy wasn't completed, click OK to continue."
str_files_to_copy:
        PASCAL_STRING "Files to copy in the RAMCard: "
str_files_remaining:
        PASCAL_STRING "Files remaining to copy: "
str_spaces:
        PASCAL_STRING "    "    ; do not localize

;;; ============================================================

.proc open_window
        MGTK_CALL MGTK::OpenWindow, winfo
        lda     winfo::window_id
        jsr     app::get_window_port
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::FrameRect, rect_frame1
        MGTK_CALL MGTK::FrameRect, rect_frame2
        MGTK_CALL MGTK::MoveTo, download_label_pos
        param_call app::DrawString, download_label_str
        rts
.endproc

;;; ============================================================

.proc draw_window_content
        lda     winfo::window_id
        jsr     app::get_window_port
        MGTK_CALL MGTK::SetPenMode, app::pencopy
        MGTK_CALL MGTK::PaintRect, rect_clear_details
ep2:    dec     LA759
        lda     LA759
        cmp     #$FF
        bne     LAA4C
        dec     LA75A
LAA4C:  jsr     populate_count
        MGTK_CALL MGTK::SetPortBits, setportbits_params
        MGTK_CALL MGTK::SetPenMode, app::pencopy
        MGTK_CALL MGTK::PaintRect, rect_clear_count
        param_call app::AdjustPathCase, pathname1
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call app::DrawString, str_copying
        param_call app::DrawString, pathname1
        MGTK_CALL MGTK::MoveTo, pt2
        param_call app::DrawString, str_files_remaining
        param_call app::DrawString, str_count
        param_call app::DrawString, str_spaces
        rts
.endproc
        draw_window_content_ep2 := draw_window_content::ep2
;;; ============================================================

.proc update_file_count_display
        jsr     populate_count
        MGTK_CALL MGTK::SetPortBits, setportbits_params
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call app::DrawString, str_files_to_copy
        param_call app::DrawString, str_count
        param_call app::DrawString, str_spaces
        rts
.endproc

;;; ============================================================

LAABD:  lda     #$FD            ; Unknown alert number ???
        jsr     app::ShowAlert
        bne     :+
        jsr     app::set_watch_cursor
        rts

:       jmp     restore_stack_and_return

;;; ============================================================

LAACB:  lda     winfo::window_id
        jsr     app::get_window_port
        MGTK_CALL MGTK::SetPenMode, app::pencopy
        MGTK_CALL MGTK::PaintRect, rect_clear_details
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call app::DrawString, str_not_enough_room
        MGTK_CALL MGTK::MoveTo, pt2
        param_call app::DrawString, str_click_ok
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::FrameRect, rect1
        MGTK_CALL MGTK::MoveTo, pos1
        param_call app::DrawString, app::ok_button_label
        jsr     set_pointer_cursor
        jmp     restore_stack_and_return

;;; ============================================================

.proc handle_error_code
        lda     winfo::window_id
        jsr     app::get_window_port
        MGTK_CALL MGTK::SetPenMode, app::pencopy
        MGTK_CALL MGTK::PaintRect, rect_clear_details
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call app::DrawString, str_error_download
        MGTK_CALL MGTK::MoveTo, pt2
        param_call app::DrawString, str_copy_incomplete
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::FrameRect, rect1
        MGTK_CALL MGTK::MoveTo, pos1
        param_call app::DrawString, app::ok_button_label
        jsr     set_pointer_cursor
        jmp     restore_stack_and_return
.endproc

;;; ============================================================

set_pointer_cursor:
        jsr     app::set_pointer_cursor

;;; ============================================================

event_loop:
        MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_kind
        cmp     #MGTK::EventKind::button_down
        beq     handle_button_down
        cmp     #MGTK::EventKind::key_down
        bne     event_loop
        lda     app::event_key
        cmp     #CHAR_RETURN
        bne     event_loop
        lda     winfo::window_id
        jsr     app::get_window_port
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        MGTK_CALL MGTK::PaintRect, rect1
        jsr     app::set_watch_cursor
        rts

handle_button_down:
        MGTK_CALL MGTK::FindWindow, app::findwindow_params
        lda     app::findwindow_which_area
        beq     event_loop
        cmp     #MGTK::Area::content
        bne     event_loop
        lda     app::findwindow_window_id
        cmp     winfo::window_id
        bne     event_loop
        lda     winfo::window_id
        jsr     app::get_window_port
        lda     winfo::window_id
        sta     app::screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, app::screentowindow_params
        MGTK_CALL MGTK::MoveTo, app::screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect1
        cmp     #MGTK::inrect_inside
        bne     event_loop
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        jsr     LABE6
        bmi     event_loop
        jsr     app::set_watch_cursor
        rts

LABE6:  lda     #$00
        sta     LAC53
LABEB:  MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_kind
        cmp     #MGTK::EventKind::button_up
        beq     LAC3C
        lda     winfo::window_id
        sta     app::screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, app::screentowindow_params
        MGTK_CALL MGTK::MoveTo, app::screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect1
        cmp     #MGTK::inrect_inside
        beq     LAC1C
        lda     LAC53
        beq     LAC24
        jmp     LABEB

LAC1C:  lda     LAC53
        bne     LAC24
        jmp     LABEB

LAC24:  MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        lda     LAC53
        clc
        adc     #$80
        sta     LAC53
        jmp     LABEB

LAC3C:  lda     LAC53
        beq     LAC44
        return  #$FF

LAC44:  MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        return  #$00

LAC53:  .byte   0

;;; ============================================================

.proc restore_stack_and_return
        ldx     saved_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

.proc close_window
        MGTK_CALL MGTK::CloseWindow, winfo
        rts
.endproc

;;; ============================================================

.proc populate_count
        copy16  LA759, value
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

file_copier_exec   := file_copier::exec

        PAD_TO $AD00