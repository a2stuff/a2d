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
kAlertRectLeft          = (::kScreenWidth - kAlertRectWidth)/2
kAlertRectTop           = (::kScreenHeight - kAlertRectHeight)/2

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

        DEFINE_BUTTON ok,        res_string_alert_button_ok,            300, 37
        DEFINE_BUTTON try_again, res_string_button_try_again,           300, 37
        DEFINE_BUTTON cancel,    res_string_button_cancel,               20, 37

        DEFINE_POINT pos_prompt, 75, 29

;;; %0....... = OK
;;; %10...... = Cancel, Try Again
;;; %11...... = Cancel, OK
alert_options:  .byte   0

kAlertOptionsOK                 = %00000000 ; Used internally only, callers would pass $01
kAlertOptionsTryAgainCancel     = %10000000
kAlertOptionsOKCancel           = %11000000

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

alert_table:
        .byte   AlertID::selector_unable_to_run
        .byte   AlertID::io_error
        .byte   AlertID::no_device
        .byte   AlertID::pathname_does_not_exist
        .byte   AlertID::insert_source_disk
        .byte   AlertID::file_not_found
        .byte   AlertID::insert_system_disk
        .byte   AlertID::basic_system_not_found
        ASSERT_TABLE_SIZE alert_table, kNumErrorMessages

message_table:
        .addr   str_selector_unable_to_run
        .addr   str_io_error
        .addr   str_no_device
        .addr   str_pathname_does_not_exist
        .addr   str_insert_source_disk
        .addr   str_file_not_found
        .addr   str_insert_system_disk
        .addr   str_basic_system_not_found
        ASSERT_ADDRESS_TABLE_SIZE message_table, kNumErrorMessages

        ;; $C0 (%11xxxxxx) = Cancel + Ok
        ;; $81 (%10xxxxx1) = Cancel + Yes + No
        ;; $80 (%10xx0000) = Cancel + Try Again
        ;; $00 (%0xxxxxxx) = Ok

.enum MessageFlags
        OkCancel = $C0
        YesNoCancel = $81
        TryAgainCancel = $80
        Ok = $00
.endenum

alert_options_table:
        .byte   MessageFlags::Ok
        .byte   MessageFlags::Ok
        .byte   MessageFlags::Ok
        .byte   MessageFlags::Ok
        .byte   MessageFlags::TryAgainCancel
        .byte   MessageFlags::Ok
        .byte   MessageFlags::TryAgainCancel
        .byte   MessageFlags::Ok
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
:       cmp     alert_table,y
        beq     :+
        iny
        cpy     num_error_messages
        bne     :-

        ldy     #0              ; default
:       tya
        asl     a
        tay
        copy16  message_table,y, prompt_addr
        tya
        lsr     a
        tay
        copy    alert_options_table,y, alert_options

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
        jsr     app::yield_loop
        MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jmp     handle_button_down

:       cmp     #MGTK::EventKind::key_down
        bne     event_loop

        ;; --------------------------------------------------
        ;; Key Down
        lda     app::event_key
        bit     alert_options   ; has Cancel?
        bpl     check_only_ok   ; nope

        cmp     #CHAR_ESCAPE
        bne     :+

do_cancel:
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        lda     #kAlertResultCancel
        jmp     finish

:       bit     alert_options   ; has Try Again?
        bvs     check_ok        ; nope
        cmp     #TO_LOWER(kShortcutTryAgain)
        bne     :+

do_try_again:
        MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, try_again_button_rect
        lda     #kAlertResultTryAgain
        jmp     finish

:       cmp     #kShortcutTryAgain
        beq     do_try_again
        cmp     #CHAR_RETURN    ; also allow Return as default
        beq     do_try_again
        jmp     event_loop

check_only_ok:
        cmp     #CHAR_ESCAPE    ; also allow Escape as default
        beq     do_ok
check_ok:
        cmp     #CHAR_RETURN
        bne     :+

do_ok:  MGTK_CALL MGTK::SetPenMode, app::penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        lda     #kAlertResultOK
        jmp     finish

:       jmp     event_loop

        ;; --------------------------------------------------
        ;; Buttons

handle_button_down:
        jsr     map_event_coords
        MGTK_CALL MGTK::MoveTo, app::event_coords

        bit     alert_options   ; Cancel showing?
        bpl     check_ok_rect   ; nope

        MGTK_CALL MGTK::InRect, cancel_button_rect ; Cancel?
        cmp     #MGTK::inrect_inside
        bne     :+
        param_call AlertButtonEventLoop, cancel_button_rect
        bne     no_button
        lda     #kAlertResultCancel
        jmp     finish

:       bit     alert_options   ; Try Again showing?
        bvs     check_ok_rect   ; nope

        MGTK_CALL MGTK::InRect, try_again_button_rect ; Try Again?
        cmp     #MGTK::inrect_inside
        bne     no_button
        param_call AlertButtonEventLoop, try_again_button_rect
        bne     no_button
        lda     #kAlertResultTryAgain
        jmp     finish

check_ok_rect:
        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside ; OK?
        bne     no_button
        param_call AlertButtonEventLoop, ok_button_rect
        bne     no_button
        lda     #kAlertResultOK
        jmp     finish

no_button:
        jmp     event_loop

;;; ============================================================

finish: pha
        MGTK_CALL MGTK::HideCursor
        jsr     dialog_background_restore
        MGTK_CALL MGTK::ShowCursor
        pla
        rts

;;; ============================================================

.proc map_event_coords
        sub16   app::event_xcoord, portmap::viewloc::xcoord, app::event_xcoord
        sub16   app::event_ycoord, portmap::viewloc::ycoord, app::event_ycoord
        rts
.endproc

        event_params = app::event_params
        event_kind = app::event_kind
        event_coords = app::event_coords
        penXOR = app::penXOR
        .define LIB_MGTK_CALL MGTK_CALL
        .include "../lib/alertbuttonloop.s"
        .undefine LIB_MGTK_CALL
        .include "../lib/savedialogbackground.s"
        dialog_background_save := dialog_background::Save
        dialog_background_restore := dialog_background::Restore

.endproc

;;; ============================================================

.endscope
        ShowAlertImpl := alert::ShowAlertImpl

        PAD_TO $D800
