;;; ============================================================
;;; BENCHMARK - Desk Accessory
;;;
;;; Uses VBL to probe system speed.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "benchmark.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================
;;; Param blocks

kDAWindowId     = $80
kDAWidth        = 400
kDAHeight       = 70
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

kButtonInsetX   = 25

        DEFINE_BUTTON ok_button, kDAWindowId, res_string_button_ok, kGlyphReturn, kDAWidth - kButtonWidth - kButtonInsetX, 52

        DEFINE_LABEL title, res_string_window_title, 0, 18

;;; ============================================================

        .include "../lib/event_params.s"

;;; ============================================================

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY

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
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8,$FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        DEFINE_RECT_FRAME frame_rect, kDAWidth, kDAHeight

.params getwinport_params
window_id:      .byte   0
a_grafport:     .addr   grafport_win
.endparams

grafport_win:       .tag MGTK::GrafPort

;;; ============================================================

        DEFINE_BUTTON radio_60hz_button, kDAWindowId, res_string_60hz, res_string_shortcut_apple_6,  60, 54
        DEFINE_BUTTON radio_50hz_button, kDAWindowId, res_string_50hz, res_string_shortcut_apple_5, 140, 54

;;; ============================================================


str_from_int:   PASCAL_STRING "000,000"    ; Filled in by IntToString
str_spaces:     PASCAL_STRING "    "

counter:        .word   0       ; set by `ProbeSpeed`

        kSpeedDefault60Hz = 97  ; Measured
        kSpeedDefault50Hz = kSpeedDefault60Hz * 60 / 50 ; TODO: Validate on real hardware
        kSpeedMax = 16          ; MHz

        kMeterTop = 24
        kMeterHeight = 9
        kMeterLeft = 20
        kMeterWidth = kDAWidth-kMeterLeft*2
        DEFINE_RECT_SZ meter_frame, kMeterLeft-1, kMeterTop-1, kMeterWidth+2, kMeterHeight+2
        DEFINE_RECT_SZ meter_left, kMeterLeft, kMeterTop, kMeterWidth, kMeterHeight
        DEFINE_RECT_SZ meter_right, kMeterLeft, kMeterTop, kMeterWidth, kMeterHeight

.params ticks_muldiv_params
number:         .word   kMeterWidth ; (in) constant
numerator:      .word   0           ; (in) populated dynamically
denominator:    .word   kSpeedMax   ; (in) constant
result:         .word   0           ; (out)
remainder:      .word   0           ; (out)
.endparams

.params progress_muldiv_params
number:         .word   kMeterWidth ; (in) constant
numerator:      .word   0           ; (in) populated dynamically
denominator:    .word   0           ; (in) populated dynamically
result:         .word   0           ; (out)
remainder:      .word   0           ; (out)
.endparams

pattern_left:
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
pattern_right:
        .byte   %11101110
        .byte   %11111111
        .byte   %10111011
        .byte   %11111111
        .byte   %11101110
        .byte   %11111111
        .byte   %10111011
        .byte   %11111111
pattern_plaid:
        .byte   %01011010
        .byte   %11111111
        .byte   %01011010
        .byte   %01011010
        .byte   %01011010
        .byte   %11111111
        .byte   %01011010
        .byte   %01011010

        DEFINE_POINT pt_tick, 0, kMeterTop + kMeterHeight + 2
        DEFINE_POINT pt_tickdelta, 0, 2
        DEFINE_POINT pt_labeldelta, 0, kSystemFontHeight + 2

;;; ============================================================
;;; Initialize window, unpack the date.

.proc RunDA
        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPort, winfo::port

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        CALL    DrawTitleString, AX=#title_label_str

        MGTK_CALL MGTK::FrameRect, meter_frame

        lda     #0
    DO
        pha
        sta     ticks_muldiv_params::numerator
        MGTK_CALL MGTK::MulDiv, ticks_muldiv_params
        add16   meter_left::x1, ticks_muldiv_params::result, pt_tick::xcoord
        MGTK_CALL MGTK::MoveTo, pt_tick
        MGTK_CALL MGTK::Line, pt_tickdelta
        pla
        pha
        ldx     #0
        jsr     IntToString
        MGTK_CALL MGTK::Move, pt_labeldelta
        CALL    DrawStringCentered, AX=#str_from_int

        pla
        clc
        adc     #1
    WHILE A < #kSpeedMax+1

        lda     #BTK::kButtonStateChecked
        sta     radio_60hz_button::state

        BTK_CALL BTK::RadioDraw, radio_60hz_button
        BTK_CALL BTK::RadioDraw, radio_50hz_button

        BTK_CALL BTK::Draw, ok_button

        MGTK_CALL MGTK::ShowCursor

        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; RunDA

;;; ============================================================
;;; Input loop

.proc InputLoop
        dec     probe_count
    IF ZERO
        jsr     UpdateMeter
    END_IF

        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind

        cmp     #MGTK::EventKind::button_down
        jeq     OnClick

        cmp     #MGTK::EventKind::key_down
        beq     OnKey

        jmp     InputLoop

probe_count:
        .byte   0

.endproc ; InputLoop

.proc OnKey
        lda     event_params::key
        jsr     ToUpperCase

        ldx     event_params::modifiers
    IF NOT_ZERO
        cmp     #res_char_shortcut_apple_5
        jeq     OnClick50Hz

        cmp     #res_char_shortcut_apple_6
        jeq     OnClick60Hz

        cmp     #kShortcutCloseWindow
        beq     OnKeyOK
        jmp     InputLoop
    END_IF

        cmp     #CHAR_RETURN
        beq     OnKeyOK

        cmp     #CHAR_ESCAPE
        beq     OnKeyOK

        jmp     InputLoop
.endproc ; OnKey

.proc OnKeyOK
        BTK_CALL BTK::Flash, ok_button
        jmp     CloseWindow
.endproc ; OnKeyOK

;;; ============================================================

.proc OnClick
        MGTK_CALL MGTK::FindWindow, findwindow_params

        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        bne     miss

        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        beq     hit

miss:   jmp     InputLoop

hit:    lda     winfo::window_id
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, radio_60hz_button::rect
        bne     OnClick60Hz

        MGTK_CALL MGTK::InRect, radio_50hz_button::rect
        bne     OnClick50Hz

        MGTK_CALL MGTK::InRect, ok_button::rect
        bne     OnClickOK

        jmp     InputLoop
.endproc ; OnClick

;;; ============================================================

.proc OnClick60Hz
        bit     radio_60hz_button::state
        bmi     done

        lda     #BTK::kButtonStateChecked
        sta     radio_60hz_button::state
        lda     #BTK::kButtonStateNormal
        sta     radio_50hz_button::state
        BTK_CALL BTK::RadioUpdate, radio_60hz_button
        BTK_CALL BTK::RadioUpdate, radio_50hz_button

done:   jmp     InputLoop
.endproc ; OnClick60Hz

;;; ============================================================

.proc OnClick50Hz
        bit     radio_50hz_button::state
        bmi     done

        lda     #BTK::kButtonStateNormal
        sta     radio_60hz_button::state
        lda     #BTK::kButtonStateChecked
        sta     radio_50hz_button::state
        BTK_CALL BTK::RadioUpdate, radio_60hz_button
        BTK_CALL BTK::RadioUpdate, radio_50hz_button

done:   jmp     InputLoop
.endproc ; OnClick50Hz

;;; ============================================================

.proc OnClickOK
        BTK_CALL BTK::Track, ok_button
        jeq     CloseWindow
        jmp     InputLoop
.endproc ; OnClickOK

;;; ============================================================

.proc CloseWindow
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; CloseWindow

;;; ============================================================

.proc UpdateMeter
        MGTK_CALL MGTK::SetPattern, pattern_left

        jsr     ProbeSpeed

        copy16  counter, progress_muldiv_params::numerator
    IF bit radio_60hz_button::state : NS
        copy16  #kSpeedMax * kSpeedDefault60Hz, progress_muldiv_params::denominator
    ELSE
        copy16  #kSpeedMax * kSpeedDefault50Hz, progress_muldiv_params::denominator
    END_IF

        MGTK_CALL MGTK::MulDiv, progress_muldiv_params

        ;; Max out the meter
        cmp16   progress_muldiv_params::result, #kMeterWidth
    IF GE
        copy16  #kMeterWidth, progress_muldiv_params::result
        MGTK_CALL MGTK::SetPattern, pattern_plaid
    END_IF

        add16   meter_left::x1, progress_muldiv_params::result, meter_left::x2
        add16   meter_left::x2, #1, meter_right::x1

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::ShieldCursor, meter_frame
        MGTK_CALL MGTK::PaintRect, meter_left
        MGTK_CALL MGTK::SetPattern, pattern_right
        MGTK_CALL MGTK::PaintRect, meter_right
        MGTK_CALL MGTK::UnshieldCursor

        rts
.endproc ; UpdateMeter

;;; ============================================================
;;; Draw Title String (centered at top of port)
;;; Input: A,X = string address

.proc DrawTitleString
        params := $6
        str := $6
        width := $8

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params
        sub16   #kDAWidth, width, title_label_pos::xcoord
        lsr16   title_label_pos::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, title_label_pos
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawTitleString

;;; ============================================================

.proc ProbeSpeed
        copy16  #0, counter

        php
        sei

        ;; Probe system type; we need a different strategy for
        ;; IIe/IIgs (softswitch) vs IIc (interrupts)
        bit     ROMIN2
        lda     ZIDBYTE         ; IIc = 0
        bit     LCBANK1
        bit     LCBANK1

.macro SPIN_CPU
        ldx     #$20            ; IIgs slows to read VBL; spin
:       dex                     ; here so bulk of loop is fast.
        bne     :-              ; c/o Kent Dickey
.endmacro


    IF A <> #0
        ;; IIe / IIgs

        ;; Wait one cycle
:       bit     RDVBLBAR
        bpl     :-
:       bit     RDVBLBAR
        bmi     :-              ; start off with high bit clear

        ;; Loop until full cycle seen
      DO
        inc16   counter
        SPIN_CPU
        bit     RDVBLBAR
      WHILE NC

      DO
        inc16   counter
        SPIN_CPU
        bit     RDVBLBAR
      WHILE NS
    ELSE
        ;; IIc

        ;; See Apple IIc Tech Note #9: Detecting VBL
        ;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/aiic/tn.aiic.9.html

        lda     IOUDISON        ; = RDIOUDIS
        pha                     ; save IOUDIS state
        sta     IOUDISOFF

        lda     RDVBLMSK
        pha                     ; save VBL interrupt state
        sta     ENVBL

        ;; Wait for VBL
:       bit     RDVBLBAR
        bpl     :-
        bit     IOUDISON        ; = RDIOUDIS (since PTRIG would slow)

        ;; Wait for VBL
      DO
        inc16   counter
        SPIN_CPU
        bit     RDVBLBAR
      WHILE NC
        bit     IOUDISON        ; = RDIOUDIS (since PTRIG would slow)

        pla                     ; restore VBL interrupt state
      IF NC
        sta     DISVBL
      END_IF

        pla                     ; restore IOUDIS state
      IF NC
        sta     IOUDISON
      END_IF
    END_IF

        plp
        rts

.endproc ; ProbeSpeed

;;; ============================================================

.proc DrawStringCentered
        params := $06
        str := params
        width := params+2

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params
        lsr16   width
        sub16   #0, width, params+MGTK::Point::xcoord
        copy16  #0, params+MGTK::Point::ycoord
        MGTK_CALL MGTK::Move, params
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawStringCentered

;;; ============================================================

        .include "../lib/inttostring.s"
        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        JSR_TO_AUX aux::RunDA
        rts

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
