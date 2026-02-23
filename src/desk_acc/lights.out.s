;;; ============================================================
;;; LIGHTS.OUT - Desk Accessory
;;;
;;; Click to toggle lights. Try to turn them all off.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "lights.out.res"

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

        kDAWindowId = $80

;;; ============================================================
;;; Param Blocks

        .include "../lib/event_params.s"

.params trackgoaway_params
goaway: .byte   0
.endparams

.params getwinport_params
window_id:      .byte   kDAWindowId
a_grafport:     .addr   grafport
.endparams
grafport:       .tag    MGTK::GrafPort

        kHPadding = 18
        kVPadding = 9

        kRows = 5
        kCols = 5
        kLights = kRows * kCols
        kLightWidth = BTK::kRadioButtonWidth + 4
        kLightHeight = BTK::kRadioButtonHeight + 2

kDAWidth        = kLightWidth * kCols + 2*kHPadding - 4
kDAHeight       = kLightHeight * kRows + 2*kVPadding - 2
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

        .repeat kRows, yy
        .repeat kCols, xx

        DEFINE_BUTTON .ident(.sprintf("button_%d_%d", xx, yy)), kDAWindowId,,, kHPadding + kLightWidth * xx, kVPadding + kLightHeight * yy

        .endrepeat
        .endrepeat



.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::go_away_box
title:          .addr   name
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kDAWidth
mincontheight:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontheight:  .word   kDAHeight
port:
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $FF
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

name:   PASCAL_STRING res_string_window_title

scrambled_flag:
        .byte   0

notpencopy:     .byte   MGTK::notpencopy
notpenXOR:      .byte   MGTK::notpenXOR

.params pattern_black
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
.endparams

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY

        DEFINE_RECT invert_rect, 0, 0, kDAWidth, kDAHeight
        DEFINE_RECT_FRAME frame_rect, kDAWidth, kDAHeight

;;; ============================================================
;;; Create the window

.proc CreateWindow
        jsr     InitRand
        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     Scramble
        FALL_THROUGH_TO InputLoop
.endproc ; CreateWindow

;;; ============================================================
;;; Input loop and processing

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params

        lda     event_params::kind
    IF A = #MGTK::EventKind::button_down
        jsr     OnClick
        jmp     InputLoop
    END_IF

    IF A = #MGTK::EventKind::key_down
        jsr     OnKey
        jmp     InputLoop
    END_IF

        jmp     InputLoop
.endproc ; InputLoop

;;; ============================================================

.proc OnClick
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
    IF A = #kDAWindowId
        lda     findwindow_params::which_area

        cmp     #MGTK::Area::close_box
        beq     DoClose

        cmp     #MGTK::Area::dragbar
        beq     DoDrag

        cmp     #MGTK::Area::content
        beq     DoClick
    END_IF
        rts
.endproc ; OnClick

;;; ============================================================

.proc OnKey
        lda     event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        beq     DoQuit
        rts
    END_IF

        cmp     #CHAR_ESCAPE
        beq     DoQuit

    IF bit scrambled_flag : NC
        jmp     Scramble
    END_IF

        ;; TODO: Keyboard controls?

        rts
.endproc ; OnKey

;;; ============================================================

.proc DoClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        bne     DoQuit
        rts
.endproc ; DoClose

;;; ============================================================

.proc DoDrag
        copy8   #kDAWindowId, dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
    IF bit dragwindow_params::moved : NS
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        jsr     DrawWindow
    END_IF

ret:    rts
.endproc ; DoDrag

;;; ============================================================

.proc DoQuit
        pla                     ; bust out of `OnXXX` proc
        pla
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; DoQuit

;;; ============================================================

.proc DoClick
    IF bit scrambled_flag : NC
        jmp     Scramble
    END_IF

        copy8   winfo::window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        copy16  #button_0_0::rect, rect_ptr
        ldx     #0
    DO
        txa                     ; A = index
        pha

        MGTK_CALL MGTK::InRect, SELF_MODIFIED, rect_ptr
      IF NOT_ZERO
        pla                     ; A = index
        jmp     DoLightClick
      END_IF

        add16_8 rect_ptr, #.sizeof(BTK::ButtonRecord)
        pla                     ; A = index
        tax
    WHILE inx : X <> #kLights

        rts
.endproc ; DoClick

;;; ============================================================

;;; Input: A = light index
.proc DoLightClick
        jsr     ToggleLight

        ;; Toggle neighbors
        pha
        jsr     IndexToXY
        inx
        jsr     IsXYValid
    IF CC
        jsr     XYToIndex
        jsr     ToggleLight
    END_IF
        pla

        pha
        jsr     IndexToXY
        dex
        jsr     IsXYValid
    IF CC
        jsr     XYToIndex
        jsr     ToggleLight
    END_IF
        pla

        pha
        jsr     IndexToXY
        iny
        jsr     IsXYValid
    IF CC
        jsr     XYToIndex
        jsr     ToggleLight
    END_IF
        pla

        pha
        jsr     IndexToXY
        dey
        jsr     IsXYValid
    IF CC
        jsr     XYToIndex
        jsr     ToggleLight
    END_IF
        pla

        ;; All lights out?
        rec_ptr := $06
        copy16  #button_0_0, rec_ptr
        ldy     #BTK::ButtonRecord::state
        ldx     #kLights-1
    DO
        lda     (rec_ptr),y
        bmi     ret             ; light on, so no
        add16_8 rec_ptr, #.sizeof(BTK::ButtonRecord)
    WHILE dex : POS

        ;; Yes, victory!
        ldx     #4
    DO
        txa
        pha
        jsr     PlaySound
        jsr     InvertWindow
        pla
        tax
    WHILE dex : NOT_ZERO

        CLEAR_BIT7_FLAG scrambled_flag

ret:    rts

.endproc ; DoLightClick

;;; ============================================================

;;; Input: A = light index
;;; Output: A is unchanged
.proc ToggleLight
        ptr := $06

        pha                     ; A = index
        jsr     SetButtonPtr

        ;; Toggle `state`
        ldy     #BTK::ButtonRecord::state
        lda     (ptr),y
        eor     #$80
        sta     (ptr),y

        ;; Repaint
        copy16  ptr, rec_ptr
        BTK_CALL BTK::RadioUpdate, SELF_MODIFIED, rec_ptr

        pla                     ; A = index
        rts
.endproc ; ToggleLight

;;; Input: A = light index
;;; Output: A is unchanged
.proc ToggleLightNoRedraw
        ptr := $06

        pha                     ; A = index
        jsr     SetButtonPtr

        ;; Toggle `state`
        ldy     #BTK::ButtonRecord::state
        lda     (ptr),y
        eor     #$80
        sta     (ptr),y

        pla                     ; A = index
        rts
.endproc ; ToggleLightNoRedraw

;;; ============================================================

;;; Input: A = light index
;;; Output: $06 points at `ButtonRecord`, A is unchanged
.proc SetButtonPtr
        ptr := $06

        pha                     ; A = index

        ;; Set `ptr` to address of `ButtonRecord`

        tax
        copy16  #button_0_0 - .sizeof(button_0_0), ptr
    DO
        add16_8 ptr, #.sizeof(button_0_0)
    WHILE dex : POS

        pla                     ; A = index
        rts
.endproc ; SetButtonPtr

;;; ============================================================
;;; Draw the DA window

.proc DrawWindow
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF NOT_ZERO         ; obscured
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        ;; Draw all buttons
        copy16  #button_0_0, rec_ptr
        ldx     #kLights-1
    DO
        txa                     ; A = index
        pha

        BTK_CALL BTK::RadioDraw, SELF_MODIFIED, rec_ptr

        add16_8 rec_ptr, #.sizeof(button_0_0)
        pla                     ; A = index
        tax
    WHILE dex : POS

        MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; DrawWindow

;;; ============================================================

.proc Scramble
        ldx     #kLights-1
    DO
        txa
        pha                     ; A = index

        jsr     Random
      IF NS
        pla                     ; A = index
        pha                     ; A = index

        jsr     ToggleLightNoRedraw

        ;; Toggle neighbors
        pha
        jsr     IndexToXY
        inx
        jsr     IsXYValid
       IF CC
        jsr     XYToIndex
        jsr     ToggleLightNoRedraw
       END_IF
        pla

        pha
        jsr     IndexToXY
        dex
        jsr     IsXYValid
       IF CC
        jsr     XYToIndex
        jsr     ToggleLightNoRedraw
       END_IF
        pla

        pha
        jsr     IndexToXY
        iny
        jsr     IsXYValid
       IF CC
        jsr     XYToIndex
        jsr     ToggleLightNoRedraw
       END_IF
        pla

        pha
        jsr     IndexToXY
        dey
        jsr     IsXYValid
       IF CC
        jsr     XYToIndex
        jsr     ToggleLightNoRedraw
       END_IF
        pla
      END_IF

        pla
        tax
    WHILE dex : POS

        SET_BIT7_FLAG scrambled_flag

        jmp     DrawWindow
.endproc ; Scramble

;;; ============================================================

;;; Input: A = index
;;; Output: X,Y = coords
.proc IndexToXY
        ldy     #0
    DO
        BREAK_IF A < #kCols
        iny
        sbc     #kCols
    WHILE POS                   ; always
        tax
        rts

.endproc ; IndexToXY

;;; Input: X,Y = coords
;;; Output: A = index
.proc XYToIndex
        txa
    DO
        dey
        BREAK_IF NEG
        clc
        adc     #kCols
    WHILE NOT_ZERO              ; always
        rts
.endproc ; XYToIndex

;;; Input: X,Y = coords
;;; Output: C=0 if valid, C=1 if not valid
.proc IsXYValid
        cpx     #kCols
        bcs     ret
        cpy     #kRows
ret:    rts
.endproc ; IsXYValid

;;; ============================================================
;;; Play sound

.proc PlaySound
        ldx     #$80
loop1:  lda     #88
loop2:  ldy     #27
delay1: dey
        bne     delay1
        bit     SPKR
        tay
delay2: dey
        bne     delay2
        sbc     #1
        beq     loop1
        bit     SPKR
        dex
        bne     loop2
        rts
.endproc ; PlaySound

;;; ============================================================

.proc InvertWindow
        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF ZERO                     ; not obscured
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::SetPattern, pattern_black
        MGTK_CALL MGTK::SetPenMode, notpenXOR
        MGTK_CALL MGTK::PaintRect, invert_rect
    END_IF
        rts
.endproc ; InvertWindow

;;; ============================================================

        .include "../lib/prng.s"
        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX aux::CreateWindow
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
