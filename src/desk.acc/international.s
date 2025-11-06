;;; ============================================================
;;; INTERNATIONAL - Desk Accessory
;;;
;;; Configure internationalization settings.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "international.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
        .include "../lib/alert_dialog.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================
;;; Memory map
;;;
;;;               Main            Aux
;;;          :             : :             :
;;;          |             | |             |
;;;          | DHR         | | DHR         |
;;;  $2000   +-------------+ +-------------+
;;;          | IO Buffer   | |             |
;;;  $1C00   +-------------+ |             |
;;;          | write_buffer| |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          | stub & save | | GUI code &  |
;;;          | settings    | | resource    |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;
;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

.proc RunDA
        jsr     init_window
        RETURN  A=dialog_result
.endproc ; RunDA

;;; ============================================================
;;; Param blocks

        kDialogWidth = 430
        kDialogHeight = 89

        kControlMarginX = 16

        kRow1 = 10
        kRow2 = 25
        kRow3 = 40
        kRow4 = 55
        kRow5 = 70

        kLabelLeft = kControlMarginX
        kFieldLeft = 160
        kFieldWidth = kTextBoxTextHOffset * 2 + 7
        kFieldHeight = kSystemFontHeight + 4
        kSampleLeft = kFieldLeft + kFieldWidth + kControlMarginX

.macro DEFINE_FIELD name, string, sample, row
        DEFINE_RECT_SZ .ident(.sprintf("%s_rect", .string(name))), kFieldLeft, row, kFieldWidth, kFieldHeight
        DEFINE_RECT_SZ .ident(.sprintf("%s_hilite", .string(name))), kFieldLeft+2, row+2, kFieldWidth-4, kSystemFontHeight
        DEFINE_POINT .ident(.sprintf("%s_char_pos", .string(name))), kFieldLeft+kTextBoxTextHOffset+1, row+2+kSystemFontHeight
        DEFINE_LABEL name, string,      kLabelLeft, row+2+kSystemFontHeight
        DEFINE_LABEL .ident(.sprintf("%s_sample", .string(name))), .sprintf("%s  ", sample), kSampleLeft, row+2+kSystemFontHeight
.endmacro
        DEFINE_FIELD date, res_string_label_date_separator, "10/11/12", kRow1
        kDateSampleOffset1 = 3
        kDateSampleOffset2 = 6
        DEFINE_FIELD time, res_string_label_time_separator, "12:34", kRow2
        kTimeSampleOffset = 3
        DEFINE_FIELD deci, res_string_label_decimal_separator, "0.1234", kRow3
        kDeciSampleOffset = 2
        DEFINE_FIELD thou, res_string_label_thousands_separator, "12,345", kRow4
        kThouSampleOffset = 3

        kOptionDisplayX = 260
        DEFINE_BUTTON date_mdy_button, kDAWindowId, res_string_label_mdy, res_string_shortcut_apple_1, kOptionDisplayX, 16
        DEFINE_BUTTON date_dmy_button, kDAWindowId, res_string_label_dmy, res_string_shortcut_apple_2, kOptionDisplayX, 27

        DEFINE_BUTTON clock_12hour_button, kDAWindowId, res_string_label_clock_12hour, res_string_shortcut_apple_3, kOptionDisplayX, 45
        DEFINE_BUTTON clock_24hour_button, kDAWindowId, res_string_label_clock_24hour, res_string_shortcut_apple_4, kOptionDisplayX, 56

        kOKButtonLeft = kDialogWidth - kButtonWidth - kControlMarginX
        kOKButtonTop = kDialogHeight - kButtonHeight - 7
        DEFINE_BUTTON ok_button, kDAWindowId, res_string_button_ok, kGlyphReturn, kOKButtonLeft, kOKButtonTop

        DEFINE_LABEL first_dow, res_string_label_first_dow, kLabelLeft, kRow5+2+kSystemFontHeight
        DEFINE_BUTTON sunday_button, kDAWindowId, res_string_weekday_abbrev_1, res_string_shortcut_apple_5, kFieldLeft, kRow5+3
        DEFINE_BUTTON monday_button, kDAWindowId, res_string_weekday_abbrev_2, res_string_shortcut_apple_6, kFieldLeft+70, kRow5+3


.params settextbg_black_params
backcolor:   .byte   0          ; black
.endparams

.params settextbg_white_params
backcolor:   .byte   $FF        ; white
.endparams

.enum Field
        FIRST   = 1
        date    = 1
        time    = 2
        deci    = 3
        thou    = 4
        LAST    = 4
.endenum

selected_field:
        .byte   Field::FIRST

;;; ============================================================

        .include "../lib/event_params.s"

        kDAWindowId = $80

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy

.params winfo
window_id:      .byte   kDAWindowId
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
mincontwidth:   .word   100
mincontheight:  .word   100
maxcontwidth:   .word   500
maxcontheight:  .word   500
port:
        DEFINE_POINT viewloc, (kScreenWidth-kDialogWidth)/2, (kScreenHeight-kDialogHeight)/2
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDialogWidth, kDialogHeight
pattern:        .res    8,$FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME frame_rect, kDialogWidth, kDialogHeight

;;; ============================================================
;;; Initialize window, unpack the date.

init_window:
        MGTK_CALL MGTK::OpenWindow, winfo
        copy8   #Field::FIRST, selected_field
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop

;;; ============================================================
;;; Input loop

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
    IF A = #MGTK::EventKind::button_down
        jsr     OnClick
        jmp     InputLoop
    END_IF

        cmp     #MGTK::EventKind::key_down
        bne     InputLoop
        jsr     OnKey
        jmp     InputLoop
.endproc ; InputLoop

;;; ============================================================

.proc OnKey
        MGTK_CALL MGTK::SetPort, winfo::port

        lda     event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        jeq     OnKeyOK

        cmp     #res_char_shortcut_apple_1
        jeq     OnClickMDY
        cmp     #res_char_shortcut_apple_2
        jeq     OnClickDMY
        cmp     #res_char_shortcut_apple_3
        jeq     OnClick12Hour
        cmp     #res_char_shortcut_apple_4
        jeq     OnClick24Hour
        cmp     #res_char_shortcut_apple_5
        jeq     OnClickSunday
        cmp     #res_char_shortcut_apple_6
        jeq     OnClickMonday
        rts
    END_IF

        cmp     #CHAR_RETURN
        jeq     OnKeyOK
        cmp     #CHAR_ESCAPE
        jeq     OnKeyOK

        cmp     #CHAR_LEFT
        beq     OnKeyPrev
        cmp     #CHAR_UP
        beq     OnKeyPrev
        cmp     #CHAR_RIGHT
        beq     OnKeyNext
        cmp     #CHAR_TAB
        beq     OnKeyNext
        cmp     #CHAR_DOWN
        beq     OnKeyNext
        cmp     #' '
        bcc     ret
        cmp     #CHAR_DELETE
        bcs     ret
        jmp     OnKeyChar

ret:    rts

.proc OnKeyPrev
        sec
        lda     selected_field
        sbc     #1
        bne     UpdateSelection
        lda     #Field::LAST
        bne     UpdateSelection ; always
.endproc ; OnKeyPrev

.proc OnKeyNext
        clc
        lda     selected_field
        adc     #1
        cmp     #Field::LAST+1
        bcc     UpdateSelection
        lda     #Field::FIRST
        FALL_THROUGH_TO UpdateSelection
.endproc ; OnKeyNext

.proc UpdateSelection
        jmp     SelectField
.endproc ; UpdateSelection

.proc OnKeyChar
        ldx     selected_field

    IF X = #Field::date
        ldx     #DeskTopSettings::intl_date_sep
        bne     update          ; always
    END_IF

    IF X = #Field::time
        ldx     #DeskTopSettings::intl_time_sep
        bne     update          ; always
    END_IF

    IF X = #Field::deci
        ldx     #DeskTopSettings::intl_deci_sep
        bne     update          ; always
    END_IF

    IF X = #Field::thou
        ldx     #DeskTopSettings::intl_thou_sep
        bne     update          ; always
    END_IF

        rts

update:
        jsr     WriteSetting
        copy8   #$80, dialog_result
        TAIL_CALL DrawField, A=selected_field
.endproc ; OnKeyChar

.endproc ; OnKey

;;; ============================================================

.proc OnClick
        MGTK_CALL MGTK::FindWindow, event_params::xcoord
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        bne     miss
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        beq     hit
miss:   rts
hit:
        ;; ----------------------------------------

        MGTK_CALL MGTK::SetPort, winfo::port

        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, ok_button::rect
        jne     OnClickOK

        ;; --------------------------------------------------

        MGTK_CALL MGTK::InRect, clock_12hour_button::rect
        jne     OnClick12Hour

        MGTK_CALL MGTK::InRect, clock_24hour_button::rect
        jne     OnClick24Hour

        MGTK_CALL MGTK::InRect, date_mdy_button::rect
        jne     OnClickMDY

        MGTK_CALL MGTK::InRect, date_dmy_button::rect
        jne     OnClickDMY

        MGTK_CALL MGTK::InRect, sunday_button::rect
        jne     OnClickSunday

        MGTK_CALL MGTK::InRect, monday_button::rect
        jne     OnClickMonday

        ;; --------------------------------------------------

        MGTK_CALL MGTK::InRect, date_rect
    IF NOT_ZERO
        TAIL_CALL SelectField, A=#Field::date
    END_IF

        MGTK_CALL MGTK::InRect, time_rect
    IF NOT_ZERO
        TAIL_CALL SelectField, A=#Field::time
    END_IF

        MGTK_CALL MGTK::InRect, deci_rect
    IF NOT_ZERO
        TAIL_CALL SelectField, A=#Field::deci
    END_IF

        MGTK_CALL MGTK::InRect, thou_rect
    IF NOT_ZERO
        TAIL_CALL SelectField, A=#Field::thou
    END_IF

        rts
.endproc ; OnClick

;;; ============================================================

.proc OnClickOK
        BTK_CALL BTK::Track, ok_button
        beq     OnOK
        rts
.endproc ; OnClickOK

.proc OnKeyOK
        BTK_CALL BTK::Flash, ok_button
        FALL_THROUGH_TO OnOK
.endproc ; OnKeyOK

.proc OnOK
        jmp     Destroy
.endproc ; OnOK

;;; ============================================================

.proc OnClick12Hour
        CALL    WriteSetting, A=#0, X=#DeskTopSettings::clock_24hours
        copy8   #$80, dialog_result
        jmp     UpdateClockOptionButtons
.endproc ; OnClick12Hour

.proc OnClick24Hour
        CALL    WriteSetting, A=#$80, X=#DeskTopSettings::clock_24hours
        copy8   #$80, dialog_result
        jmp     UpdateClockOptionButtons
.endproc ; OnClick24Hour

.proc OnClickMDY
        CALL    WriteSetting, A=#DeskTopSettings::kDateOrderMDY, X=#DeskTopSettings::intl_date_order
        copy8   #$80, dialog_result
        jmp     UpdateDateOptionButtons
.endproc ; OnClickMDY

.proc OnClickDMY
        CALL    WriteSetting, A=#DeskTopSettings::kDateOrderDMY, X=#DeskTopSettings::intl_date_order
        copy8   #$80, dialog_result
        jmp     UpdateDateOptionButtons
.endproc ; OnClickDMY

.proc OnClickSunday
        CALL    WriteSetting, A=#0, X=#DeskTopSettings::intl_first_dow
        copy8   #$80, dialog_result
        jmp     UpdateFirstDOWOptionButtons
.endproc ; OnClickSunday

.proc OnClickMonday
        CALL    WriteSetting, A=#1, X=#DeskTopSettings::intl_first_dow
        copy8   #$80, dialog_result
        jmp     UpdateFirstDOWOptionButtons
.endproc ; OnClickMonday

;;; ============================================================
;;; Tear down the window and exit

;;; Used in Aux to store result during tear-down
;;; bit7 = settings changed
dialog_result:  .byte   0

.proc Destroy
        pla                     ; Exit `InputLoop`
        pla

        MGTK_CALL MGTK::CloseWindow, closewindow_params

        ;; Dates in DeskTop list views may be invalidated, so if any
        ;; settings changed, force a full redraw to avoid artifacts.
        bit     dialog_result
    IF NS
        MGTK_CALL MGTK::RedrawDeskTop
    END_IF

        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Destroy

;;; ============================================================
;;; Render the window contents

.proc DrawWindow
        MGTK_CALL MGTK::SetPort, winfo::port

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::MoveTo, date_label_pos
        MGTK_CALL MGTK::DrawString, date_label_str
        MGTK_CALL MGTK::FrameRect, date_rect

        MGTK_CALL MGTK::MoveTo, time_label_pos
        MGTK_CALL MGTK::DrawString, time_label_str
        MGTK_CALL MGTK::FrameRect, time_rect

        MGTK_CALL MGTK::MoveTo, deci_label_pos
        MGTK_CALL MGTK::DrawString, deci_label_str
        MGTK_CALL MGTK::FrameRect, deci_rect

        MGTK_CALL MGTK::MoveTo, thou_label_pos
        MGTK_CALL MGTK::DrawString, thou_label_str
        MGTK_CALL MGTK::FrameRect, thou_rect

        CALL    DrawField, A=#Field::date
        CALL    DrawField, A=#Field::time
        CALL    DrawField, A=#Field::deci
        CALL    DrawField, A=#Field::thou

        BTK_CALL BTK::Draw, ok_button
        BTK_CALL BTK::RadioDraw, date_mdy_button
        BTK_CALL BTK::RadioDraw, date_dmy_button
        BTK_CALL BTK::RadioDraw, clock_12hour_button
        BTK_CALL BTK::RadioDraw, clock_24hour_button

        MGTK_CALL MGTK::MoveTo, first_dow_label_pos
        MGTK_CALL MGTK::DrawString, first_dow_label_str
        BTK_CALL BTK::RadioDraw, sunday_button
        BTK_CALL BTK::RadioDraw, monday_button

        FALL_THROUGH_TO UpdateOptionButtons
.endproc ; DrawWindow

.proc UpdateOptionButtons
        jsr     UpdateFirstDOWOptionButtons
        jsr     UpdateDateOptionButtons
        FALL_THROUGH_TO UpdateClockOptionButtons
.endproc ; UpdateOptionButtons

.proc UpdateClockOptionButtons
        CALL    ReadSetting, X=#DeskTopSettings::clock_24hours

        pha
        cmp     #0
        jsr     ZToButtonState
        sta     clock_12hour_button::state
        BTK_CALL BTK::RadioUpdate, clock_12hour_button

        pla
        cmp     #$80
        jsr     ZToButtonState
        sta     clock_24hour_button::state
        BTK_CALL BTK::RadioUpdate, clock_24hour_button

        rts
.endproc ; UpdateClockOptionButtons

.proc UpdateDateOptionButtons
        CALL    ReadSetting, X=#DeskTopSettings::intl_date_order

        pha
        cmp     #DeskTopSettings::kDateOrderMDY
        jsr     ZToButtonState
        sta     date_mdy_button::state
        BTK_CALL BTK::RadioUpdate, date_mdy_button

        pla
        cmp     #DeskTopSettings::kDateOrderDMY
        jsr     ZToButtonState
        sta     date_dmy_button::state
        BTK_CALL BTK::RadioUpdate, date_dmy_button

        rts
.endproc ; UpdateDateOptionButtons

.proc UpdateFirstDOWOptionButtons
        CALL    ReadSetting, X=#DeskTopSettings::intl_first_dow

        pha
        cmp     #0
        jsr     ZToButtonState
        sta     sunday_button::state
        BTK_CALL BTK::RadioUpdate, sunday_button

        pla
        cmp     #1
        jsr     ZToButtonState
        sta     monday_button::state
        BTK_CALL BTK::RadioUpdate, monday_button

        rts
.endproc ; UpdateFirstDOWOptionButtons

.proc ZToButtonState
    IF ZC
        RETURN  A=#BTK::kButtonStateNormal
    END_IF
        RETURN  A=#BTK::kButtonStateChecked
.endproc ; ZToButtonState

;;; ============================================================

.params drawchar_params
addr:   .addr   char
length: .byte   1
char:   .byte   SELF_MODIFIED_BYTE
.endparams

;;; A = field
.proc DrawField
        pha
    IF A = selected_field
        MGTK_CALL MGTK::SetTextBG, settextbg_black_params
        MGTK_CALL MGTK::SetPenMode, notpencopy
    ELSE
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        MGTK_CALL MGTK::SetPenMode, pencopy
    END_IF
        pla

    IF A = #Field::date
        CALL    ReadSetting, X=#DeskTopSettings::intl_date_sep
        sta     drawchar_params::char
        sta     date_sample_label_str+kDateSampleOffset1
        sta     date_sample_label_str+kDateSampleOffset2
        MGTK_CALL MGTK::PaintRect, date_hilite
        MGTK_CALL MGTK::MoveTo, date_char_pos
        MGTK_CALL MGTK::DrawText, drawchar_params
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        MGTK_CALL MGTK::MoveTo, date_sample_label_pos
        MGTK_CALL MGTK::DrawString, date_sample_label_str
        rts
    END_IF

    IF A = #Field::time
        CALL    ReadSetting, X=#DeskTopSettings::intl_time_sep
        sta     drawchar_params::char
        sta     time_sample_label_str+kTimeSampleOffset
        MGTK_CALL MGTK::PaintRect, time_hilite
        MGTK_CALL MGTK::MoveTo, time_char_pos
        MGTK_CALL MGTK::DrawText, drawchar_params
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        MGTK_CALL MGTK::MoveTo, time_sample_label_pos
        MGTK_CALL MGTK::DrawString, time_sample_label_str
        rts
    END_IF

    IF A = #Field::deci
        CALL    ReadSetting, X=#DeskTopSettings::intl_deci_sep
        sta     drawchar_params::char
        sta     deci_sample_label_str+kDeciSampleOffset
        MGTK_CALL MGTK::PaintRect, deci_hilite
        MGTK_CALL MGTK::MoveTo, deci_char_pos
        MGTK_CALL MGTK::DrawText, drawchar_params
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        MGTK_CALL MGTK::MoveTo, deci_sample_label_pos
        MGTK_CALL MGTK::DrawString, deci_sample_label_str
        rts
    END_IF

    IF A = #Field::thou
        CALL    ReadSetting, X=#DeskTopSettings::intl_thou_sep
        sta     drawchar_params::char
        sta     thou_sample_label_str+kThouSampleOffset
        MGTK_CALL MGTK::PaintRect, thou_hilite
        MGTK_CALL MGTK::MoveTo, thou_char_pos
        MGTK_CALL MGTK::DrawText, drawchar_params
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        MGTK_CALL MGTK::MoveTo, thou_sample_label_pos
        MGTK_CALL MGTK::DrawString, thou_sample_label_str
        rts
    END_IF

        rts
.endproc ; DrawField

;;; ============================================================
;;; Selected a field (dehighlight the old one, highlight the new one)
;;; Input: A = new field to select

.proc SelectField
        ldx     selected_field
        sta     selected_field

        txa
        jsr     DrawField

        TAIL_CALL DrawField, A=selected_field
.endproc ; SelectField

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        JSR_TO_AUX aux::RunDA
        bmi     SaveSettings
        rts

        .include "../lib/save_settings.s"
        .assert * < write_buffer, error, .sprintf("DA too big (at $%X)", *)

        DA_END_MAIN_SEGMENT

;;; ============================================================
