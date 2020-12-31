;;; ============================================================
;;; Resources
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        .org $D000

.scope alert

alert_bitmap:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0000001),PX(%1110000),PX(%0000111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0000011),PX(%1100000),PX(%0000011),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000111),PX(%1100111),PX(%1111001),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0001111),PX(%1100111),PX(%1111001),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1111001),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1110011),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1100111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1001111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%0011111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111110),PX(%0111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111100),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111100),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111110),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%1111111),PX(%1111100),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111000),PX(%0000011),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)

.params alert_bitmap_params
viewloc:        DEFINE_POINT 20, 8
mapbits:        .addr   alert_bitmap
mapwidth:       .byte   7
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, 36, 23
.endparams

kAlertRectWidth         = 420
kAlertRectHeight        = 55
kAlertRectLeft          = (kScreenWidth - kAlertRectWidth)/2
kAlertRectTop           = (kScreenHeight - kAlertRectHeight)/2

alert_rect:
        DEFINE_RECT_SZ kAlertRectLeft, kAlertRectTop, kAlertRectWidth, kAlertRectHeight
alert_inner_frame_rect1:
        DEFINE_RECT_INSET 4, 2, kAlertRectWidth, kAlertRectHeight
alert_inner_frame_rect2:
        DEFINE_RECT_INSET 5, 3, kAlertRectWidth, kAlertRectHeight

.params portmap
viewloc:        DEFINE_POINT kAlertRectLeft, kAlertRectTop, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kAlertRectWidth, kAlertRectHeight, maprect
.endparams

        DEFINE_BUTTON ok,        "OK            \x0D", 300, 37
        DEFINE_BUTTON try_again, "Try Again  A",       300, 37
        DEFINE_BUTTON cancel,    "Cancel    Esc",       20, 37

pos_prompt:     DEFINE_POINT 75,29

alert_options:  .byte   0
prompt_addr:    .addr   0

;;; ============================================================
;;; Messages

str_selector_unable_to_run:
        PASCAL_STRING "The Selector is unable to run the program."
str_io_error:
        PASCAL_STRING "I/O Error"
str_no_device:
        PASCAL_STRING "No device connected."
str_pathname_does_not_exist:
        PASCAL_STRING "Part of the pathname doesn't exist."
str_insert_source_disk:
        PASCAL_STRING "Please insert source disk."
str_file_not_found:
        PASCAL_STRING "The file cannot be found."
str_insert_system_disk:
        PASCAL_STRING "Please insert the system disk"
str_basic_system_not_found:
        PASCAL_STRING "BASIC.SYSTEM not found"

kNumErrorMessages = 8

num_error_messages:
        .byte   kNumErrorMessages

error_message_index_table:
        .byte   AlertID::selector_unable_to_run
        .byte   AlertID::io_error
        .byte   AlertID::no_device
        .byte   AlertID::pathname_does_not_exist
        .byte   AlertID::insert_source_disk
        .byte   AlertID::file_not_found
        .byte   AlertID::insert_system_disk
        .byte   AlertID::basic_system_not_found
        ASSERT_TABLE_SIZE error_message_index_table, kNumErrorMessages

error_message_table:
        .addr   str_selector_unable_to_run
        .addr   str_io_error
        .addr   str_no_device
        .addr   str_pathname_does_not_exist
        .addr   str_insert_source_disk
        .addr   str_file_not_found
        .addr   str_insert_system_disk
        .addr   str_basic_system_not_found
        ASSERT_ADDRESS_TABLE_SIZE error_message_table, kNumErrorMessages

alert_options_table:
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $80
        .byte   $00
        .byte   $80
        .byte   $00
        ASSERT_TABLE_SIZE alert_options_table, kNumErrorMessages

.proc ShowAlertImpl
        pha
        lda     app::L9129
        beq     :+
        pla
        return  #$01
:       jsr     app::set_pointer_cursor
        MGTK_CALL MGTK::InitPort, app::grafport2
        MGTK_CALL MGTK::SetPort, app::grafport2

        ;; Compute save bounds
        ldax    portmap::viewloc::xcoord ; left
        jsr     calc_x_save_bounds
        sty     save_x1_byte
        sta     save_x1_bit

        lda     portmap::viewloc::xcoord ; right
        clc
        adc     portmap::maprect::x2
        pha
        lda     portmap::viewloc::xcoord+1
        adc     portmap::maprect::x2+1
        tax
        pla
        jsr     calc_x_save_bounds
        sty     save_x2_byte
        sta     save_x2_bit

        lda     portmap::viewloc::ycoord ; top
        sta     save_y1
        clc
        adc     portmap::maprect::y2 ; bottom
        sta     save_y2

        MGTK_CALL MGTK::HideCursor
        jsr     dialog_background_save
        MGTK_CALL MGTK::ShowCursor

        ;; Set up GrafPort
        ldx     #.sizeof(MGTK::Point)-1
        lda     #0
:       sta     app::grafport2+MGTK::GrafPort::viewloc,x
        sta     app::grafport2+MGTK::GrafPort::maprect,x
        dex
        bpl     :-
        copy16  #550, app::grafport2 + MGTK::GrafPort::maprect + MGTK::Rect::x2
        copy16  #185, app::grafport2 + MGTK::GrafPort::maprect + MGTK::Rect::y2
        MGTK_CALL MGTK::SetPort, app::grafport2

        ;; Draw alert box and bitmap
        MGTK_CALL MGTK::SetPenMode, app::pencopy
        MGTK_CALL MGTK::PaintRect, alert_rect
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::FrameRect, alert_rect
        MGTK_CALL MGTK::SetPortBits, portmap
        MGTK_CALL MGTK::FrameRect, alert_inner_frame_rect1
        MGTK_CALL MGTK::FrameRect, alert_inner_frame_rect2
        MGTK_CALL MGTK::SetPenMode, app::pencopy
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::PaintBits, alert_bitmap_params
        MGTK_CALL MGTK::ShowCursor

        ;; --------------------------------------------------
        ;; Process Options

        pla                     ; alert number
        ldy     #$00
LD307:  cmp     error_message_index_table,y
        beq     LD314
        iny
        cpy     num_error_messages
        bne     LD307
        ldy     #$00
LD314:  tya
        asl     a
        tay
        lda     error_message_table,y
        sta     prompt_addr
        lda     error_message_table+1,y
        sta     prompt_addr+1
        tya
        lsr     a
        tay
        lda     alert_options_table,y
        sta     alert_options

        ;; Draw appropriate buttons
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        bit     alert_options
        bpl     ok_button

        ;; Cancel button
        MGTK_CALL MGTK::FrameRect, cancel_button_rect
        MGTK_CALL MGTK::MoveTo, cancel_button_pos
        param_call app::DrawString, cancel_button_label

        bit     alert_options
        bvs     ok_button

        ;; Try Again button
        MGTK_CALL MGTK::FrameRect, try_again_button_rect
        MGTK_CALL MGTK::MoveTo, try_again_button_pos
        param_call app::DrawString, try_again_button_label
        jmp     draw_prompt

        ;; OK button
ok_button:
        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call app::DrawString, ok_button_label

        ;; Prompt string
draw_prompt:
        MGTK_CALL MGTK::MoveTo, pos_prompt
        param_call_indirect app::DrawString, prompt_addr

        ;; --------------------------------------------------
        ;; Event Loop

event_loop:
        MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jmp     handle_button

:       cmp     #MGTK::EventKind::key_down
        bne     event_loop

        ;; --------------------------------------------------
        ;; Key Down
        lda     app::event_key
        and     #CHAR_MASK
        bit     alert_options   ; Escape = Cancel?
        bpl     check_ok
        cmp     #CHAR_ESCAPE
        bne     :+

        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        lda     #kAlertResultCancel
        jmp     finish

:       bit     alert_options   ; A = Try Again?
        bvs     check_ok
        cmp     #'a'
        bne     :+
was_a:  MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, try_again_button_rect
        lda     #kAlertResultTryAgain
        jmp     finish

:       cmp     #'A'
        beq     was_a
        cmp     #CHAR_RETURN    ; also allow Return as default
        beq     was_a
        jmp     event_loop

check_ok:
        cmp     #CHAR_RETURN    ; Return = OK?
        bne     :+
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        lda     #kAlertResultOK
        jmp     finish

:       jmp     event_loop

        ;; --------------------------------------------------
        ;; Buttons

handle_button:
        jsr     map_alert_coords
        MGTK_CALL MGTK::MoveTo, app::event_coords

        bit     alert_options   ; Cancel?
        bpl     check_ok_button_rect

        MGTK_CALL MGTK::InRect, cancel_button_rect
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     cancel_btn_event_loop

:       bit     alert_options   ; Try Again?
        bvs     check_ok_button_rect
        MGTK_CALL MGTK::InRect, try_again_button_rect
        cmp     #MGTK::inrect_inside
        bne     no_button
        jmp     try_again_btn_event_loop

check_ok_button_rect:
        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside ; OK?
        bne     no_button
        jmp     ok_button_event_loop

no_button:
        jmp     event_loop

finish: pha
        MGTK_CALL MGTK::HideCursor
        jsr     dialog_background_restore
        MGTK_CALL MGTK::ShowCursor
        pla
        rts

        ;; --------------------------------------------------
        ;; Try Again Button Event Loop

.proc try_again_btn_event_loop
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, try_again_button_rect
        lda     #$00
        sta     LD4AC
LD457:  MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_kind
        cmp     #MGTK::EventKind::button_up
        beq     LD49F
        jsr     map_alert_coords
        MGTK_CALL MGTK::MoveTo, app::event_coords
        MGTK_CALL MGTK::InRect, try_again_button_rect
        cmp     #MGTK::inrect_inside
        beq     LD47F
        lda     LD4AC
        beq     LD487
        jmp     LD457

LD47F:  lda     LD4AC
        bne     LD487
        jmp     LD457

LD487:  MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, try_again_button_rect
        lda     LD4AC
        clc
        adc     #$80
        sta     LD4AC
        jmp     LD457

LD49F:  lda     LD4AC
        beq     LD4A7
        jmp     event_loop

LD4A7:  lda     #$00
        jmp     finish

LD4AC:  .byte   0
.endproc

        ;; --------------------------------------------------
        ;; Cancel Button Event Loop

.proc cancel_btn_event_loop
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        lda     #$00
        sta     LD513
LD4BE:  MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_kind
        cmp     #MGTK::EventKind::button_up
        beq     LD506
        jsr     map_alert_coords
        MGTK_CALL MGTK::MoveTo, app::event_coords
        MGTK_CALL MGTK::InRect, cancel_button_rect
        cmp     #MGTK::inrect_inside
        beq     LD4E6
        lda     LD513
        beq     LD4EE
        jmp     LD4BE

LD4E6:  lda     LD513
        bne     LD4EE
        jmp     LD4BE

LD4EE:  MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        lda     LD513
        clc
        adc     #$80
        sta     LD513
        jmp     LD4BE

LD506:  lda     LD513
        beq     LD50E
        jmp     event_loop

LD50E:  lda     #$01
        jmp     finish

LD513:  .byte   0
.endproc

        ;; --------------------------------------------------
        ;; OK Button Event Loop

.proc ok_button_event_loop
        lda     #$00
        sta     LD57A
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
LD525:  MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_kind
        cmp     #MGTK::EventKind::button_up
        beq     LD56D
        jsr     map_alert_coords
        MGTK_CALL MGTK::MoveTo, app::event_coords
        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
        beq     LD54D
        lda     LD57A
        beq     LD555
        jmp     LD525

LD54D:  lda     LD57A
        bne     LD555
        jmp     LD525

LD555:  MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        lda     LD57A
        clc
        adc     #$80
        sta     LD57A
        jmp     LD525

LD56D:  lda     LD57A
        beq     LD575
        jmp     event_loop

LD575:  lda     #$00
        jmp     finish

LD57A:  .byte   0
.endproc

;;; ============================================================

.proc map_alert_coords
        sub16   app::event_xcoord, portmap::viewloc::xcoord, app::event_xcoord
        sub16   app::event_ycoord, portmap::viewloc::ycoord, app::event_ycoord
        rts
.endproc

;;; ============================================================
;;; Save/Restore Dialog Background
;;;
;;; This reuses the "save area" ($800-$1AFF) used by MGTK for
;;; quickly restoring menu backgrounds.

;;; TODO: Simplify these routines like DeskTop - no need
;;; for precise bit masking on the edges.

.scope dialog_background

        ptr := $06

.proc save
        copy16  #SAVE_AREA_BUFFER, addr
        lda     save_y1
        jsr     LD6AA
        lda     save_y2
        sec
        sbc     save_y1
        tax
        inx
LD5BB:  lda     save_x1_byte
        sta     LD5F6
LD5C1:  lda     LD5F6
        lsr     a
        tay
        sta     PAGE2OFF        ; main $2000-$3FFF
        bcs     LD5CE
        sta     PAGE2ON         ; aux $2000-$3FFF
LD5CE:  lda     (ptr),y
        addr := *+1
        sta     dummy1234
        inc16   addr
        lda     LD5F6
        cmp     save_x2_byte
        bcs     LD5E8
        inc     LD5F6
        bne     LD5C1
LD5E8:  jsr     LD6EC
        dex
        bne     LD5BB
        ldax    addr
        rts

        .byte   0
LD5F6:  .byte   0
.endproc

;;; ============================================================

.proc restore
        copy16  #SAVE_AREA_BUFFER, addr
        ldx     save_x1_bit
        ldy     save_x2_bit
        lda     #$FF
        cpx     #$00
        beq     LD612
LD60D:  clc
        rol     a
        dex
        bne     LD60D
LD612:  sta     LD6A6
        eor     #$FF
        sta     LD6A7
        lda     #$01
        cpy     #$00
        beq     LD625
LD620:  sec
        rol     a
        dey
        bne     LD620
LD625:  sta     LD6A8
        eor     #$FF
        sta     LD6A9
        lda     save_y1
        jsr     LD6AA
        lda     save_y2
        sec
        sbc     save_y1
        tax
        inx
        lda     save_x1_byte
        sta     LD6A5
LD642:  lda     save_x1_byte
        sta     LD6A5
LD648:  lda     LD6A5
        lsr     a
        tay
        sta     PAGE2OFF        ; main $2000-$3FFF
        bcs     LD655
        sta     PAGE2ON         ; aux $2000-$3FFF
LD655:
        addr := *+1
        lda     SAVE_AREA_BUFFER
        pha
        lda     LD6A5
        cmp     save_x1_byte
        beq     LD677
        cmp     save_x2_byte
        bne     LD685
        lda     (ptr),y
        and     LD6A9
        sta     (ptr),y
        pla
        and     LD6A8
        ora     (ptr),y
        pha
        jmp     LD685

LD677:  lda     (ptr),y
        and     LD6A7
        sta     (ptr),y
        pla
        and     LD6A6
        ora     (ptr),y
        pha
LD685:  pla
        sta     (ptr),y
        inc16   addr
        lda     LD6A5
        cmp     save_x2_byte
        bcs     LD69D
        inc     LD6A5
        bne     LD648
LD69D:  jsr     LD6EC
        dex
        bne     LD642
        rts

        .byte   0
LD6A5:  .byte   0
LD6A6:  .byte   0
LD6A7:  .byte   0
LD6A8:  .byte   0
LD6A9:  .byte   0
.endproc

;;; ============================================================

LD6AA:  sta     LD769
        and     #$07
        sta     LD74A
        lda     LD769
        and     #$38
        sta     LD749
        lda     LD769
        and     #$C0
        sta     LD748
        jsr     LD6C6
        rts

LD6C6:  lda     LD748
        lsr     a
        lsr     a
        ora     LD748
        pha
        lda     LD749
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     LD6EB
        pla
        ror     a
        sta     ptr
        lda     LD74A
        asl     a
        asl     a
        ora     LD6EB
        ora     #$20
        sta     $07
        clc
        rts

LD6EB:  .byte   0

;;; ============================================================

LD6EC:  lda     LD74A
        cmp     #$07
        beq     LD6F9
        inc     LD74A
        jmp     LD6C6

LD6F9:  lda     #$00
        sta     LD74A
        lda     LD749
        cmp     #$38
        beq     LD70E
        clc
        adc     #$08
        sta     LD749
        jmp     LD6C6

LD70E:  lda     #$00
        sta     LD749
        lda     LD748
        clc
        adc     #$40
        sta     LD748
        cmp     #$C0
        beq     LD723
        jmp     LD6C6

LD723:  sec
        rts

.endscope
        dialog_background_save := dialog_background::save
        dialog_background_restore := dialog_background::restore



calc_x_save_bounds:
        ldy     #$00
        cpx     #$02
        bne     LD730
        ldy     #$49
        clc
        adc     #$01
LD730:  cpx     #$01
        bne     LD73E
        ldy     #$24
        clc
        adc     #$04
        bcc     LD73E
        iny
        sbc     #$07
LD73E:  cmp     #$07
        bcc     LD747
        sbc     #$07
        iny
        bne     LD73E
LD747:  rts

LD748:  .byte   0
LD749:  .byte   0
LD74A:  .byte   0

        ;; Unused???
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0


;;; Dialog bound coordinates

save_y1:        .byte   0
save_x1_byte:   .byte   0
save_y2:        .byte   0
save_x2_byte:   .byte   0
save_x1_bit:    .byte   0
save_x2_bit:    .byte   0

LD769:          .byte   0

.endproc

;;; ============================================================

.endscope
        ShowAlertImpl := alert::ShowAlertImpl

        PAD_TO $D800
