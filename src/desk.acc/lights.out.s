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
        .include "../inc/prodos.inc"
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
        cmp     #MGTK::EventKind::button_down
    IF_EQ
        jsr     OnClick
        jmp     InputLoop
    END_IF

        cmp     #MGTK::EventKind::key_down
    IF_EQ
        jsr     OnKey
        jmp     InputLoop
    END_IF

        jmp     InputLoop
.endproc ; InputLoop

;;; ============================================================

.proc OnClick
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        bne     ret
        lda     findwindow_params::which_area

        cmp     #MGTK::Area::close_box
        beq     DoClose

        cmp     #MGTK::Area::dragbar
        beq     DoDrag

        cmp     #MGTK::Area::content
        beq     DoClick

ret:    rts
.endproc ; OnClick

;;; ============================================================

.proc OnKey
        lda     event_params::key

        ldx     event_params::modifiers
    IF_NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        beq     DoQuit
        rts
    END_IF

        cmp     #CHAR_ESCAPE
        beq     DoQuit

        bit     scrambled_flag
    IF_NC
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
        lda     #kDAWindowId
        sta     dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        bit     dragwindow_params::moved
    IF_NS
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
        bit     scrambled_flag
    IF_NC
        jmp     Scramble
    END_IF

        copy8   winfo::window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        copy16  #button_0_0::rect, rect_ptr
        ldx     #0
loop:   txa                     ; A = index
        pha

        MGTK_CALL MGTK::InRect, SELF_MODIFIED, rect_ptr
    IF_NOT_ZERO
        pla                     ; A = index
        jmp     DoLightClick
    END_IF

next:   add16_8 rect_ptr, #.sizeof(BTK::ButtonRecord)
        pla                     ; A = index
        tax
        inx
        cpx     #kLights
        bne     loop

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
    IF_CC
        jsr     XYToIndex
        jsr     ToggleLight
    END_IF
        pla

        pha
        jsr     IndexToXY
        dex
        jsr     IsXYValid
    IF_CC
        jsr     XYToIndex
        jsr     ToggleLight
    END_IF
        pla

        pha
        jsr     IndexToXY
        iny
        jsr     IsXYValid
    IF_CC
        jsr     XYToIndex
        jsr     ToggleLight
    END_IF
        pla

        pha
        jsr     IndexToXY
        dey
        jsr     IsXYValid
    IF_CC
        jsr     XYToIndex
        jsr     ToggleLight
    END_IF
        pla

        ;; All lights out?
        rec_ptr := $06
        copy16  #button_0_0, rec_ptr
        ldy     #BTK::ButtonRecord::state
        ldx     #kLights-1
:       lda     (rec_ptr),y
        bmi     ret             ; light on, so no
        add16_8 rec_ptr, #.sizeof(BTK::ButtonRecord)
        dex
        bpl     :-

        ;; Yes, victory!
        ldx     #4
:       txa
        pha
        jsr     PlaySound
        jsr     InvertWindow
        pla
        tax
        dex
        bne     :-

        clc
        ror     scrambled_flag

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
:       add16_8 ptr, #.sizeof(button_0_0)
        dex
        bpl     :-

        pla                     ; A = index
        rts
.endproc ; SetButtonPtr

;;; ============================================================
;;; Draw the DA window

.proc DrawWindow
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF_NE               ; obscured
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        ;; Draw all buttons
        copy16  #button_0_0, rec_ptr
        ldx     #kLights-1
loop:   txa                     ; A = index
        pha

        BTK_CALL BTK::RadioDraw, SELF_MODIFIED, rec_ptr

next:   add16_8 rec_ptr, #.sizeof(button_0_0)
        pla                     ; A = index
        tax
        dex
        bpl     loop

        rts
.endproc ; DrawWindow

;;; ============================================================

.proc Scramble
        ldx     #kLights-1
loop:   txa
        pha                     ; A = index

        jsr     Random
    IF_NS
        pla                     ; A = index
        pha                     ; A = index

        jsr     ToggleLightNoRedraw

        ;; Toggle neighbors
        pha
        jsr     IndexToXY
        inx
        jsr     IsXYValid
      IF_CC
        jsr     XYToIndex
        jsr     ToggleLightNoRedraw
      END_IF
        pla

        pha
        jsr     IndexToXY
        dex
        jsr     IsXYValid
      IF_CC
        jsr     XYToIndex
        jsr     ToggleLightNoRedraw
      END_IF
        pla

        pha
        jsr     IndexToXY
        iny
        jsr     IsXYValid
      IF_CC
        jsr     XYToIndex
        jsr     ToggleLightNoRedraw
      END_IF
        pla

        pha
        jsr     IndexToXY
        dey
        jsr     IsXYValid
      IF_CC
        jsr     XYToIndex
        jsr     ToggleLightNoRedraw
      END_IF
        pla
    END_IF

next:   pla
        tax
        dex
        bpl     loop

        sec
        ror     scrambled_flag

        jmp     DrawWindow
.endproc ; Scramble

;;; ============================================================

;;; Input: A = index
;;; Output: X,Y = coords
.proc IndexToXY
        ldy     #0
:       cmp     #kCols
        bcc     :+
        iny
        sbc     #kCols
        bpl     :-              ; always
:
        tax
        rts

.endproc ; IndexToXY

;;; Input: X,Y = coords
;;; Output: A = index
.proc XYToIndex
        txa
:       dey
        bmi     ret
        clc
        adc     #kCols
        bne     :-              ; always
ret:    rts
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
        bne     ret             ; obscured
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::SetPattern, pattern_black
        MGTK_CALL MGTK::SetPenMode, notpenXOR
        MGTK_CALL MGTK::PaintRect, invert_rect

ret:    rts
.endproc ; InvertWindow


;;; ============================================================
;;; Pseudorandom Number Generation

;;; From https://www.apple2.org.za/gswv/a2zine/GS.WorldView/v1999/Nov/Articles.and.Reviews/Apple2RandomNumberGenerator.htm
;;; By David Empson

;;; NOTE: low bit of N and high bit of N+2 are coupled

R1:     .byte  0
R2:     .byte  0
R3:     .byte  0
R4:     .byte  0

.proc Random
        ror R4                  ; Bit 25 to carry
        lda R3                  ; Shift left 8 bits
        sta R4
        lda R2
        sta R3
        lda R1
        sta R2
        lda R4                  ; Get original bits 17-24
        ror                     ; Now bits 18-25 in ACC
        rol R1                  ; R1 holds bits 1-7
        eor R1                  ; Seven bits at once
        ror R4                  ; Shift right by one bit
        ror R3
        ror R2
        ror
        sta R1
        rts
.endproc ; Random

.proc InitRand
        ;; Use current 24-bit tick count as seed
        JSR_TO_MAIN JUMP_TABLE_GET_TICKS
        sta R1
        sta R2
        stx R3
        sty R4
        ldx #$20                ; Generate a few random numbers
InitLoop:
        jsr Random              ; to kick things off
        dex
        bne InitLoop
        rts
.endproc ; InitRand

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX aux::CreateWindow
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
