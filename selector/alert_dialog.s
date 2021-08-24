;;; ============================================================
;;; Resources
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        RESOURCE_FILE "alert_dialog.res"

        .org $D000

kShortcutTryAgain = res_char_button_try_again_shortcut

.proc AlertById
        jmp     start

;;; --------------------------------------------------
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

kNumAlerts = 8

alert_table:
        .byte   AlertID::selector_unable_to_run
        .byte   AlertID::io_error
        .byte   AlertID::no_device
        .byte   AlertID::pathname_does_not_exist
        .byte   AlertID::insert_source_disk
        .byte   AlertID::file_not_found
        .byte   AlertID::insert_system_disk
        .byte   AlertID::basic_system_not_found
        ASSERT_TABLE_SIZE alert_table, kNumAlerts

message_table:
        .addr   str_selector_unable_to_run
        .addr   str_io_error
        .addr   str_no_device
        .addr   str_pathname_does_not_exist
        .addr   str_insert_source_disk
        .addr   str_file_not_found
        .addr   str_insert_system_disk
        .addr   str_basic_system_not_found
        ASSERT_ADDRESS_TABLE_SIZE message_table, kNumAlerts

alert_options_table:
        .byte   AlertButtonOptions::Ok
        .byte   AlertButtonOptions::Ok
        .byte   AlertButtonOptions::Ok
        .byte   AlertButtonOptions::Ok
        .byte   AlertButtonOptions::TryAgainCancel
        .byte   AlertButtonOptions::Ok
        .byte   AlertButtonOptions::TryAgainCancel
        .byte   AlertButtonOptions::Ok
        ASSERT_TABLE_SIZE alert_options_table, kNumAlerts

.params alert_params
line1:          .addr   0       ; first line of text
line2:          .addr   0       ; unused
buttons:        .byte   0       ; AlertButtonOptions
options:        .byte   AlertOptions::Beep | AlertOptions::SaveBack
.endparams

start:  pha                     ; alert number
        lda     app::L9129      ; if non-zero, just return cancel
        beq     :+
        pla
        return  #kAlertResultCancel
:       pla                     ; alert number

        ;; --------------------------------------------------
        ;; Process Options, populate `alert_params`

        ;; A = alert

        ;; Search for alert in table, set Y to index
        ldy     #kNumAlerts-1
:       cmp     alert_table,y
        beq     :+
        dey
        bpl     :-
        ldy     #0              ; default
:

        ;; Look up message
        tya                     ; Y = index
        asl     a
        tay                     ; Y = index * 2
        copy16  message_table,y, alert_params::line1

        ;; Look up button options
        tya                     ; Y = index * 2
        lsr     a
        tay                     ; Y = index
        copy    alert_options_table,y, alert_params::buttons

        ldax    #alert_params
        jmp     Alert
.endproc

;;; ============================================================
;;; Display alert
;;; Inputs: A,X=alert_params structure
;;;    { .addr line1, .addr line2, .byte AlertButtonOptions, .byte AlertOptions }

        pointer_cursor = app::pointer_cursor
        Bell = app::Bell
        DrawString = app::DrawString
        alert_yield_loop = app::yield_loop
        alert_grafport = app::grafport2

.proc Alert
        jmp     start

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

pencopy:        .byte   0
penXOR:         .byte   2

event_params:   .tag    MGTK::Event
event_kind      := event_params + MGTK::Event::kind
event_coords    := event_params + MGTK::Event::xcoord
event_xcoord    := event_params + MGTK::Event::xcoord
event_ycoord    := event_params + MGTK::Event::ycoord
event_key       := event_params + MGTK::Event::key

kAlertRectWidth         = 420
kAlertRectHeight        = 55
kAlertRectLeft          = (::kScreenWidth - kAlertRectWidth)/2
kAlertRectTop           = (::kScreenHeight - kAlertRectHeight)/2

        DEFINE_RECT_SZ alert_rect, kAlertRectLeft, kAlertRectTop, kAlertRectWidth, kAlertRectHeight
        DEFINE_RECT_INSET alert_inner_frame_rect1, 4, 2, kAlertRectWidth, kAlertRectHeight
        DEFINE_RECT_INSET alert_inner_frame_rect2, 5, 3, kAlertRectWidth, kAlertRectHeight

.params screen_portbits
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kScreenWidth-1, kScreenHeight-1
.endparams

.params portmap
        DEFINE_POINT viewloc, kAlertRectLeft, kAlertRectTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kAlertRectWidth, kAlertRectHeight
.endparams

        DEFINE_BUTTON ok,        res_string_button_ok,          300, 37
        DEFINE_BUTTON try_again, res_string_button_try_again,   300, 37
        DEFINE_BUTTON cancel,    res_string_button_cancel,       20, 37

        DEFINE_POINT pos_prompt1, 75, 29-11
        DEFINE_POINT pos_prompt2, 75, 29

.params alert_params
line1:          .addr   0       ; first line of text
line2:          .addr   0       ; optional - second line of text (TODO: wrap instead)
buttons:        .byte   0       ; AlertButtonOptions
options:        .byte   0       ; AlertOptions flags
.endparams

        ;; Actual entry point
start:
        ;; Copy passed params
        stax    @addr
        ldx     #.sizeof(alert_params)-1
        @addr := *+1
:       lda     SELF_MODIFIED,x
        sta     alert_params,x
        dex
        bpl     :-

        MGTK_CALL MGTK::SetCursor, pointer_cursor

        ;; --------------------------------------------------
        ;; Play bell

        bit     alert_params::options
    IF_NS                       ; N = play sound
        jsr     Bell
    END_IF

        ;; --------------------------------------------------
        ;; Draw alert

        MGTK_CALL MGTK::HideCursor

        bit     alert_params::options
    IF_VS                       ; V = use save area
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

        jsr     dialog_background_save
    END_IF

        ;; Set up GrafPort
        MGTK_CALL MGTK::InitPort, alert_grafport
        MGTK_CALL MGTK::SetPort, alert_grafport

        MGTK_CALL MGTK::SetPortBits, screen_portbits ; viewport for screen

        ;; Draw alert box and bitmap - coordinates are in screen space
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, alert_rect ; alert background
        MGTK_CALL MGTK::SetPenMode, penXOR ; ensures corners are inverted
        MGTK_CALL MGTK::FrameRect, alert_rect ; alert outline

        MGTK_CALL MGTK::SetPortBits, portmap ; viewport for remaining operations

        ;; Draw rest of alert - coordinates are relative to portmap
        MGTK_CALL MGTK::FrameRect, alert_inner_frame_rect1 ; inner 2x border
        MGTK_CALL MGTK::FrameRect, alert_inner_frame_rect2
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintBits, alert_bitmap_params

        ;; Draw appropriate buttons
        MGTK_CALL MGTK::SetPenMode, penXOR

        bit     alert_params::buttons ; high bit clear = Cancel
        bpl     ok_button

        ;; Cancel button
        MGTK_CALL MGTK::FrameRect, cancel_button_rect
        MGTK_CALL MGTK::MoveTo, cancel_button_pos
        param_call DrawString, cancel_button_label

        bit     alert_params::buttons
        bvs     ok_button

        ;; Try Again button
        MGTK_CALL MGTK::FrameRect, try_again_button_rect
        MGTK_CALL MGTK::MoveTo, try_again_button_pos
        param_call DrawString, try_again_button_label

        jmp     draw_prompt

        ;; OK button
ok_button:
        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call DrawString, ok_button_label

        ;; Prompt string
draw_prompt:
        lda     alert_params::line2
        ora     alert_params::line2+1
      IF_ZERO
        MGTK_CALL MGTK::MoveTo, pos_prompt2
        param_call_indirect DrawString, alert_params::line1
      ELSE
        MGTK_CALL MGTK::MoveTo, pos_prompt1
        param_call_indirect DrawString, alert_params::line1
        MGTK_CALL MGTK::MoveTo, pos_prompt2
        param_call_indirect DrawString, alert_params::line2
      END_IF

        MGTK_CALL MGTK::ShowCursor

        ;; --------------------------------------------------
        ;; Event Loop

event_loop:
        jsr     alert_yield_loop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jmp     handle_button_down

:       cmp     #MGTK::EventKind::key_down
        bne     event_loop

        ;; --------------------------------------------------
        ;; Key Down
        lda     event_key
        bit     alert_params::buttons ; has Cancel?
        bpl     check_only_ok   ; nope

        cmp     #CHAR_ESCAPE
        bne     :+

do_cancel:
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        lda     #kAlertResultCancel
        jmp     finish

:       bit     alert_params::buttons ; has Try Again?
        bvs     check_ok        ; nope
        cmp     #TO_LOWER(kShortcutTryAgain)
        bne     :+

do_try_again:
        MGTK_CALL MGTK::SetPenMode, penXOR
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

do_ok:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        lda     #kAlertResultOK
        jmp     finish

:       jmp     event_loop

        ;; --------------------------------------------------
        ;; Buttons

handle_button_down:
        jsr     map_event_coords
        MGTK_CALL MGTK::MoveTo, event_coords

        bit     alert_params::buttons ; Cancel showing?
        bpl     check_ok_rect   ; nope

        MGTK_CALL MGTK::InRect, cancel_button_rect ; Cancel?
        cmp     #MGTK::inrect_inside
        bne     :+
        param_call AlertButtonEventLoop, cancel_button_rect
        bne     no_button
        lda     #kAlertResultCancel
        jmp     finish

:       bit     alert_params::buttons ; Try Again showing?
        bvs     check_ok_rect   ; nope

        MGTK_CALL MGTK::InRect, try_again_button_rect ; Try Again?
        cmp     #MGTK::inrect_inside
        bne     no_button
        param_call AlertButtonEventLoop, try_again_button_rect
        bne     no_button
        lda     #kAlertResultTryAgain
        jmp     finish

check_ok_rect:
        MGTK_CALL MGTK::InRect, ok_button_rect ; OK?
        cmp     #MGTK::inrect_inside
        bne     no_button
        param_call AlertButtonEventLoop, ok_button_rect
        bne     no_button
        lda     #kAlertResultOK
        jmp     finish

no_button:
        jmp     event_loop

;;; ============================================================

finish:

        bit     alert_params::options
    IF_VS                       ; V = use save area
        pha
        MGTK_CALL MGTK::HideCursor
        jsr     dialog_background_restore
        MGTK_CALL MGTK::ShowCursor
        pla
    END_IF

        rts

;;; ============================================================

.proc map_event_coords
        sub16   event_xcoord, portmap::viewloc::xcoord, event_xcoord
        sub16   event_ycoord, portmap::viewloc::ycoord, event_ycoord
        rts
.endproc

        .define LIB_MGTK_CALL MGTK_CALL
        .include "../lib/alertbuttonloop.s"
        .undefine LIB_MGTK_CALL

        .include "../lib/savedialogbackground.s"
        dialog_background_save := dialog_background::Save
        dialog_background_restore := dialog_background::Restore

.endproc

;;; ============================================================

        PAD_TO $D800
