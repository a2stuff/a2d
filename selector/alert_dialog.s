;;; ============================================================
;;; Resources
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        RESOURCE_FILE "alert_dialog.res"

        .org $D000

.scope alert

kShortcutTryAgain = res_char_button_try_again_shortcut

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
        DEFINE_POINT viewloc, 20, 8
mapbits:        .addr   alert_bitmap
mapwidth:       .byte   7
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 36, 23
.endparams

kAlertRectWidth         = 420
kAlertRectHeight        = 55
kAlertRectLeft          = (kScreenWidth - kAlertRectWidth)/2
kAlertRectTop           = (kScreenHeight - kAlertRectHeight)/2

        DEFINE_RECT_SZ alert_rect, kAlertRectLeft, kAlertRectTop, kAlertRectWidth, kAlertRectHeight
        DEFINE_RECT_INSET alert_inner_frame_rect1, 4, 2, kAlertRectWidth, kAlertRectHeight
        DEFINE_RECT_INSET alert_inner_frame_rect2, 5, 3, kAlertRectWidth, kAlertRectHeight

.params portmap
        DEFINE_POINT viewloc, kAlertRectLeft, kAlertRectTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kAlertRectWidth, kAlertRectHeight
.endparams

        DEFINE_BUTTON ok,        res_string_alert_button_ok, 300, 37
        DEFINE_BUTTON try_again, res_string_button_try_again,       300, 37
        DEFINE_BUTTON cancel,    res_string_button_cancel,       20, 37

        DEFINE_POINT pos_prompt, 75, 29

alert_options:  .byte   0
prompt_addr:    .addr   0

;;; ============================================================
;;; Messages

str_selector_unable_to_run:
        PASCAL_STRING res_string_alert_selector_unable_to_run
str_io_error:
        PASCAL_STRING res_string_alert_io_error
str_no_device:
        PASCAL_STRING res_string_alert_no_device
str_pathname_does_not_exist:
        PASCAL_STRING res_string_alert_pathname_does_not_exist
str_insert_source_disk:
        PASCAL_STRING res_string_alert_insert_source_disk
str_file_not_found:
        PASCAL_STRING res_string_alert_file_not_found
str_insert_system_disk:
        PASCAL_STRING res_string_alert_insert_system_disk
str_basic_system_not_found:
        PASCAL_STRING res_string_alert_basic_system_not_found

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
        jsr     CalcXSaveBounds
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
        jsr     CalcXSaveBounds
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
        cmp     #TO_LOWER(kShortcutTryAgain)
        bne     :+
was_a:  MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, try_again_button_rect
        lda     #kAlertResultTryAgain
        jmp     finish

:       cmp     #kShortcutTryAgain
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

        .include "../lib/savedialogbackground.s"
        dialog_background_save := dialog_background::Save
        dialog_background_restore := dialog_background::Restore

.endproc

;;; ============================================================

.endscope
        ShowAlertImpl := alert::ShowAlertImpl

        PAD_TO $D800
