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
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry
        BTKEntry := BTKAuxEntry

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
;;;          |             | |             |
;;;          | DA          | | DA (copy)   |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;
;;; ============================================================

        .org DA_LOAD_ADDRESS

;;; ============================================================

        jmp     Copy2Aux

stash_stack:  .byte   $00

;;; ============================================================

.proc Copy2Aux

        start := start_da
        end   := end_da

        tsx
        stx     stash_stack

        copy16  #start, STARTLO
        copy16  #end, ENDLO
        copy16  #start, DESTINATIONLO
        sec
        jsr     AUXMOVE

        copy16  #start, XFERSTARTLO
        php
        pla
        ora     #$40            ; set overflow: aux zp/stack
        pha
        plp
        sec                     ; control main>aux
        jmp     XFER
.endproc

;;; ============================================================
;;; Assert: Running from Main

.proc SaveAndExit
        bit     dialog_result
    IF_NS
        jsr     SaveSettings
    END_IF

        ldx     stash_stack     ; exit the DA
        txs
        rts
.endproc

;;; ============================================================
;;;
;;; Everything from here on is copied to Aux
;;;
;;; ============================================================

start_da:
        jmp     init_window

;;; ============================================================
;;; Param blocks

        kDialogWidth = 265
        kDialogHeight = 90

        kControlMarginX = 16

        kRow1 = 10
        kRow2 = 25
        kRow3 = 40
        kRow4 = 55

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

        kOKButtonLeft = kDialogWidth - kButtonWidth - kControlMarginX
        kOKButtonTop = kDialogHeight - kButtonHeight - 7
        DEFINE_BUTTON ok_button_rec, kDAWindowId, res_string_button_ok, kGlyphReturn, kOKButtonLeft, kOKButtonTop
        DEFINE_BUTTON_PARAMS ok_button_params, ok_button_rec

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

        kDAWindowId = 100

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
mincontlength:  .word   100
maxcontwidth:   .word   500
maxcontlength:  .word   500
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
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME frame_rect, kDialogWidth, kDialogHeight

;;; ============================================================
;;; Initialize window, unpack the date.

init_window:
        MGTK_CALL MGTK::OpenWindow, winfo
        lda     #Field::FIRST
        sta     selected_field
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop

;;; ============================================================
;;; Input loop

.proc InputLoop
        param_call JTRelay, JUMP_TABLE_YIELD_LOOP
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     OnClick
        jmp     InputLoop

:       cmp     #MGTK::EventKind::key_down
        bne     InputLoop
        FALL_THROUGH_TO OnKey
.endproc

.proc OnKey
        MGTK_CALL MGTK::SetPort, winfo::port

        lda     event_params::modifiers
        bne     InputLoop
        lda     event_params::key

        cmp     #CHAR_RETURN
        jeq     OnKeyOk
        cmp     #CHAR_ESCAPE
        jeq     OnKeyOk

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
        bcc     InputLoop
        cmp     #CHAR_DELETE
        bcs     InputLoop
        jmp     OnKeyChar

.proc OnKeyPrev
        sec
        lda     selected_field
        sbc     #1
        bne     UpdateSelection
        lda     #Field::LAST
        bne     UpdateSelection ; always
.endproc

.proc OnKeyNext
        clc
        lda     selected_field
        adc     #1
        cmp     #Field::LAST+1
        bcc     UpdateSelection
        lda     #Field::FIRST
        FALL_THROUGH_TO UpdateSelection
.endproc

.proc UpdateSelection
        jsr     SelectField
        jmp     InputLoop
.endproc

.proc OnKeyChar
        ldx     selected_field

        cpx     #Field::date
    IF_EQ
        sta     SETTINGS + DeskTopSettings::intl_date_sep
        beq     update          ; always
    END_IF

        cpx     #Field::time
    IF_EQ
        sta     SETTINGS + DeskTopSettings::intl_time_sep
        beq     update          ; always
    END_IF

        cpx     #Field::deci
    IF_EQ
        sta     SETTINGS + DeskTopSettings::intl_deci_sep
        beq     update          ; always
    END_IF

        cpx     #Field::thou
    IF_EQ
        sta     SETTINGS + DeskTopSettings::intl_thou_sep
        beq     update          ; always
    END_IF

        jmp     InputLoop

update:
        copy    #$80, dialog_result
        txa
        jsr     DrawField
        jmp     InputLoop
.endproc

.endproc

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

        copy    #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, ok_button_rec::rect
        cmp     #MGTK::inrect_inside
        jeq     OnClickOk

        MGTK_CALL MGTK::InRect, date_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        lda     #Field::date
        jmp     SelectField
    END_IF

        MGTK_CALL MGTK::InRect, time_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        lda     #Field::time
        jmp     SelectField
    END_IF

        MGTK_CALL MGTK::InRect, deci_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        lda     #Field::deci
        jmp     SelectField
    END_IF

        MGTK_CALL MGTK::InRect, thou_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        lda     #Field::thou
        jmp     SelectField
    END_IF

        rts
.endproc

;;; ============================================================

.proc OnClickOk
        BTK_CALL BTK::Track, ok_button_params
        beq     OnOk
        rts
.endproc

.proc OnKeyOk
        BTK_CALL BTK::Flash, ok_button_params
        FALL_THROUGH_TO OnOk
.endproc

.proc OnOk
        jmp     Destroy
.endproc

;;; ============================================================
;;; Tear down the window and exit

;;; Used in Aux to store result during tear-down
;;; bit7 = settings changed
dialog_result:  .byte   0

.proc Destroy
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        param_call JTRelay, JUMP_TABLE_CLEAR_UPDATES

        lda     dialog_result

        ;; Back to Main
        sta     RAMWRTOFF
        sta     RAMRDOFF

        sta     dialog_result

        jmp     SaveAndExit
.endproc

;;; ============================================================
;;; Render the window contents

.proc DrawWindow
        MGTK_CALL MGTK::SetPort, winfo::port

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::MoveTo, date_label_pos
        param_call DrawString, date_label_str
        MGTK_CALL MGTK::FrameRect, date_rect

        MGTK_CALL MGTK::MoveTo, time_label_pos
        param_call DrawString, time_label_str
        MGTK_CALL MGTK::FrameRect, time_rect

        MGTK_CALL MGTK::MoveTo, deci_label_pos
        param_call DrawString, deci_label_str
        MGTK_CALL MGTK::FrameRect, deci_rect

        MGTK_CALL MGTK::MoveTo, thou_label_pos
        param_call DrawString, thou_label_str
        MGTK_CALL MGTK::FrameRect, thou_rect

        BTK_CALL BTK::Draw, ok_button_params

        lda     #Field::date
        jsr     DrawField
        lda     #Field::time
        jsr     DrawField
        lda     #Field::deci
        jsr     DrawField
        lda     #Field::thou
        jsr     DrawField

        rts
.endproc

;;; ============================================================

.params drawchar_params
addr:   .addr   char
length: .byte   1
char:   .byte   SELF_MODIFIED_BYTE
.endparams

;;; A = field
.proc DrawField
        pha
        cmp     selected_field
    IF_EQ
        MGTK_CALL MGTK::SetTextBG, settextbg_black_params
        MGTK_CALL MGTK::SetPenMode, notpencopy
    ELSE
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        MGTK_CALL MGTK::SetPenMode, pencopy
    END_IF
        pla

        cmp     #Field::date
    IF_EQ
        lda     SETTINGS + DeskTopSettings::intl_date_sep
        sta     drawchar_params::char
        sta     date_sample_label_str+kDateSampleOffset1
        sta     date_sample_label_str+kDateSampleOffset2
        MGTK_CALL MGTK::PaintRect, date_hilite
        MGTK_CALL MGTK::MoveTo, date_char_pos
        MGTK_CALL MGTK::DrawText, drawchar_params
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        MGTK_CALL MGTK::MoveTo, date_sample_label_pos
        param_jump DrawString, date_sample_label_str
    END_IF

        cmp     #Field::time
    IF_EQ
        lda     SETTINGS + DeskTopSettings::intl_time_sep
        sta     drawchar_params::char
        sta     time_sample_label_str+kTimeSampleOffset
        MGTK_CALL MGTK::PaintRect, time_hilite
        MGTK_CALL MGTK::MoveTo, time_char_pos
        MGTK_CALL MGTK::DrawText, drawchar_params
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        MGTK_CALL MGTK::MoveTo, time_sample_label_pos
        param_jump DrawString, time_sample_label_str
    END_IF

        cmp     #Field::deci
    IF_EQ
        lda     SETTINGS + DeskTopSettings::intl_deci_sep
        sta     drawchar_params::char
        sta     deci_sample_label_str+kDeciSampleOffset
        MGTK_CALL MGTK::PaintRect, deci_hilite
        MGTK_CALL MGTK::MoveTo, deci_char_pos
        MGTK_CALL MGTK::DrawText, drawchar_params
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        MGTK_CALL MGTK::MoveTo, deci_sample_label_pos
        param_jump DrawString, deci_sample_label_str
    END_IF

        cmp     #Field::thou
    IF_EQ
        lda     SETTINGS + DeskTopSettings::intl_thou_sep
        sta     drawchar_params::char
        sta     thou_sample_label_str+kThouSampleOffset
        MGTK_CALL MGTK::PaintRect, thou_hilite
        MGTK_CALL MGTK::MoveTo, thou_char_pos
        MGTK_CALL MGTK::DrawText, drawchar_params
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        MGTK_CALL MGTK::MoveTo, thou_sample_label_pos
        param_jump DrawString, thou_sample_label_str
    END_IF

        rts
.endproc

;;; ============================================================
;;; Selected a field (dehighlight the old one, highlight the new one)
;;; Input: A = new field to select

.proc SelectField
        ldx     selected_field
        sta     selected_field

        txa
        jsr     DrawField

        lda     selected_field
        jmp     DrawField
.endproc

;;; ============================================================
;;; Make call into Main from Aux (for JUMP_TABLE calls)
;;; Inputs: A,X = address

.proc JTRelay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        stax    @addr
        @addr := *+1
        jsr     SELF_MODIFIED
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

;;; ============================================================

        .include "../lib/save_settings.s"
        .include "../lib/drawstring.s"

;;; ============================================================

end_da  := *
.assert * < write_buffer, error, .sprintf("DA too big (at $%X)", *)
.assert * < DA_IO_BUFFER, error, .sprintf("DA too big (at $%X)", *)

;;; ============================================================
