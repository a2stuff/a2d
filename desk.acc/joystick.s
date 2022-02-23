;;; ============================================================
;;; JOYSTICK - Desk Accessory
;;;
;;; A simple joystick calibration tool
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "joystick.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        .org DA_LOAD_ADDRESS

da_start:

;;; Copy the DA to AUX for easy bank switching
.scope
        copy16  #da_start, STARTLO
        copy16  #da_end, ENDLO
        copy16  #da_start, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
.endscope

.scope
        ;; run the DA
        sta     RAMRDON         ; Run from Aux
        sta     RAMWRTON
        jsr     Init

        ;; tear down/exit
        sta     RAMRDOFF        ; Back to Main
        sta     RAMWRTOFF

        rts
.endscope

;;; ============================================================

kDAWindowId     = 61
kDAWidth        = 270
kDAHeight       = 85
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

str_title:
        PASCAL_STRING res_string_window_title ; window title

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::go_away_box
title:          .addr   str_title
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   32
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kDAWidth
mincontlength:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontlength:  .word   kDAHeight
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
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams


;;; ============================================================


.params event_params
kind:  .byte   0
;;; event_kind_key_down
key             := *
modifiers       := * + 1
;;; event_kind_update
window_id       := *
;;; otherwise
xcoord          := *
ycoord          := * + 2
        .res    4
.endparams

.params findwindow_params
mousex:         .word   0
mousey:         .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams

.params trackgoaway_params
clicked:        .byte   0
.endparams

.params dragwindow_params
window_id:      .byte   0
dragx:          .word   0
dragy:          .word   0
moved:          .byte   0
.endparams

.params winport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams


.params screentowindow_params
window_id:      .byte   kDAWindowId
        DEFINE_POINT screen, 0, 0
        DEFINE_POINT window, 0, 0
.endparams
        mx := screentowindow_params::window::xcoord
        my := screentowindow_params::window::ycoord

.params grafport
        DEFINE_POINT viewloc, 0, 0
mapbits:        .word   0
mapwidth:       .byte   0
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 0, 0
pattern:        .res    8, 0
colormasks:     .byte   0, 0
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   MGTK::pencopy
textback:       .byte   0
textfont:       .addr   0
.endparams


;;; ============================================================
;;; Common Resources

kRadioButtonWidth       = 15
kRadioButtonHeight      = 7

.params checked_rb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   checked_rb_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, kRadioButtonWidth, kRadioButtonHeight
.endparams

checked_rb_bitmap:
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%1110001),PX(%1110001),PX(%1100000)
        .byte   PX(%1100111),PX(%1111100),PX(%1100000)
        .byte   PX(%1100111),PX(%1111100),PX(%1100000)
        .byte   PX(%1110001),PX(%1110001),PX(%1100000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)

.params unchecked_rb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   unchecked_rb_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, kRadioButtonWidth, kRadioButtonHeight
.endparams

unchecked_rb_bitmap:
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%1110000),PX(%0000001),PX(%1100000)
        .byte   PX(%1100000),PX(%0000000),PX(%1100000)
        .byte   PX(%1100000),PX(%0000000),PX(%1100000)
        .byte   PX(%1110000),PX(%0000001),PX(%1100000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)

;;; ============================================================
;;; Joystick Calibration Resources

kJoystickCalibrationX = 15
kJoystickCalibrationY = 10

kJoystickDisplayX = kJoystickCalibrationX + 53
kJoystickDisplayY = kJoystickCalibrationY - 2
kJoystickDisplayW = 128
kJoystickDisplayH = 64

        DEFINE_RECT_SZ joy_disp_frame_rect, kJoystickDisplayX    , kJoystickDisplayY    , kJoystickDisplayW + 8, kJoystickDisplayH + 5
        DEFINE_RECT_SZ joy_disp_rect,       kJoystickDisplayX + 1, kJoystickDisplayY + 1, kJoystickDisplayW + 6, kJoystickDisplayH + 3

        DEFINE_POINT joy_btn0, kJoystickDisplayX + kJoystickDisplayW + 20, kJoystickDisplayY + 10
        DEFINE_POINT joy_btn1, kJoystickDisplayX + kJoystickDisplayW + 20, kJoystickDisplayY + 30
        DEFINE_POINT joy_btn2, kJoystickDisplayX + kJoystickDisplayW + 20, kJoystickDisplayY + 50

        DEFINE_POINT joy_btn0_lpos, kJoystickDisplayX + kJoystickDisplayW + kRadioButtonWidth + 30, kJoystickDisplayY + 10 + 8
        DEFINE_POINT joy_btn1_lpos, kJoystickDisplayX + kJoystickDisplayW + kRadioButtonWidth + 30, kJoystickDisplayY + 30 + 8
        DEFINE_POINT joy_btn2_lpos, kJoystickDisplayX + kJoystickDisplayW + kRadioButtonWidth + 30, kJoystickDisplayY + 50 + 8

joy_btn0_label:   PASCAL_STRING res_string_label_joy_btn0 ; dialog label
joy_btn1_label:   PASCAL_STRING res_string_label_joy_btn1 ; dialog label
joy_btn2_label:   PASCAL_STRING res_string_label_joy_btn2 ; dialog label

.params joy_marker
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   joy_marker_bitmap
mapwidth:       .byte   2
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 7, 4
.endparams

joy_marker_bitmap:
        .byte   PX(%0011110),PX(%0000000)
        .byte   PX(%0111111),PX(%0000000)
        .byte   PX(%1111111),PX(%1000000)
        .byte   PX(%0111111),PX(%0000000)
        .byte   PX(%0011110),PX(%0000000)


.params joystick_params
        DEFINE_POINT viewloc, kJoystickCalibrationX+1, kJoystickCalibrationY + 6
mapbits:        .addr   joystick_bitmap
mapwidth:       .byte   6
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 35, 18
.endparams

joystick_bitmap:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1100000),PX(%0000000)
        .byte   PX(%0001100),PX(%1111111),PX(%1111111),PX(%0000111),PX(%1110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1100000),PX(%0000000)
        .byte   PX(%0000011),PX(%0011111),PX(%1111100),PX(%0011111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001111),PX(%1110000),PX(%1111110),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1111100),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%1100111),PX(%1000001),PX(%1110000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000110),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100),PX(%0000000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000)

        ;; Initialized to $80 if a IIgs, $00 otherwise
is_iigs_flag:
        .byte   0

        ;; Initialized to $80 if a Mac IIe Card, $00 otherwise
is_iiecard_flag:
        .byte   0

;;; ============================================================

.proc Init
        ;; --------------------------------------------------
        ;; Probe some ROM locations.
        bit     ROMIN2

        ;; Detect IIgs, save for later
        sec
        jsr     IDROUTINE
        bcs     :+
        copy    #$80, is_iigs_flag
:
        ;; Detect IIe Card, save for later
        lda     ZIDBYTE
        cmp     #$E0            ; Is Enhanced IIe?
        bne     :+
        lda     IDBYTEMACIIE
        cmp     #$02            ; IIe Card signature
        bne     :+
        copy    #$80, is_iiecard_flag
:
        bit     LCBANK1
        bit     LCBANK1

        ;; --------------------------------------------------

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc

.proc InputLoop
        jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        jsr     DoJoystick

        jmp     InputLoop
.endproc

.proc YieldLoop
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_YIELD_LOOP
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

.proc ClearUpdates
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_CLEAR_UPDATES
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo
        jsr     ClearUpdates
        rts
.endproc

;;; ============================================================

.proc HandleKey
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     Exit
        bne     InputLoop
.endproc

;;; ============================================================

.proc HandleDown
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        bne     Exit
        lda     findwindow_params::window_id
        cmp     winfo::window_id
        bne     InputLoop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        beq     HandleDrag
        cmp     #MGTK::Area::content
        beq     HandleClick
        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        bne     Exit
        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleDrag
        copy    winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
common: bit     dragwindow_params::moved
        bpl     :+

        ;; Draw DeskTop's windows and icons.
        jsr     ClearUpdates

        ;; Draw DA's window
        jsr     DrawWindow

:       jmp     InputLoop

.endproc


;;; ============================================================

.proc HandleClick
        ;; no-op
        jmp     InputLoop
.endproc

;;; ============================================================

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy


;;; ============================================================

.proc DrawWindow
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        IF_EQ
        rts
        END_IF

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        ;; ==============================
        ;; Joystick Calibration

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintBits, joystick_params

        MGTK_CALL MGTK::FrameRect, joy_disp_frame_rect

        MGTK_CALL MGTK::MoveTo, joy_btn0_lpos
        param_call DrawString, joy_btn0_label
        MGTK_CALL MGTK::MoveTo, joy_btn1_lpos
        param_call DrawString, joy_btn1_label
        MGTK_CALL MGTK::MoveTo, joy_btn2_lpos
        param_call DrawString, joy_btn2_label

        copy    #0, last_joy_valid_flag

        ;; ==============================

done:   MGTK_CALL MGTK::ShowCursor
        rts

.endproc


;;; A,X = pos ptr, Z = checked
.proc DrawRadioButton
        ptr := $06

        stax    ptr
        beq     checked

unchecked:
        ldy     #3
:       lda     (ptr),y
        sta     unchecked_rb_params::viewloc,y
        dey
        bpl     :-
        MGTK_CALL MGTK::PaintBits, unchecked_rb_params
        rts

checked:
        ldy     #3
:       lda     (ptr),y
        sta     checked_rb_params::viewloc,y
        dey
        bpl     :-
        MGTK_CALL MGTK::PaintBits, checked_rb_params
        rts
.endproc

;;; ============================================================

        ;; TODO: Read and visualize all 4 paddles.
        kNumPaddles = 2

.struct InputState
        pdl0    .byte
        pdl1    .byte
        pdl2    .byte
        pdl3    .byte

        butn0   .byte
        butn1   .byte
        butn2   .byte
.endstruct

.proc DoJoystick

        jsr     ReadPaddles

        ;; TODO: Visualize all 4 paddles.

        ldx     #kNumPaddles-1
:       lda     pdl0,x
        lsr                     ; clamp range to 0...127
        sta     curr+InputState::pdl0,x
        dex
        bpl     :-

        lsr     curr+InputState::pdl1 ; clamp Y to 0...63 (due to pixel aspect ratio)

        lda     BUTN0
        and     #$80            ; only care about msb
        sta     curr+InputState::butn0

        lda     BUTN1
        and     #$80            ; only care about msb
        sta     curr+InputState::butn1

        lda     BUTN2
        and     #$80            ; only care about msb
        sta     curr+InputState::butn2

        ;; Changed? (or first time through)
        lda     last_joy_valid_flag
        beq     changed

        ldx     #.sizeof(InputState)-1
:       lda     curr,x
        cmp     last,x
        bne     changed
        dex
        bpl     :-

        rts

changed:
        COPY_STRUCT InputState, curr, last
        copy    #$80, last_joy_valid_flag

        joy_x := joy_marker::viewloc::xcoord
        copy    curr+InputState::pdl0, joy_x
        copy    #0, joy_x+1
        add16   joy_x, #kJoystickDisplayX + 1, joy_x

        joy_y := joy_marker::viewloc::ycoord
        copy    curr+InputState::pdl1, joy_y
        copy    #0, joy_y+1
        add16   joy_y, #kJoystickDisplayY + 1, joy_y

        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        IF_EQ
        rts
        END_IF

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, joy_disp_rect

        MGTK_CALL MGTK::SetPenMode, notpencopy

        MGTK_CALL MGTK::PaintBits, joy_marker

        ldax    #joy_btn0
        ldy     curr+InputState::butn0
        cpy     #$80
        jsr     DrawRadioButton

        ldax    #joy_btn1
        ldy     curr+InputState::butn1
        cpy     #$80
        jsr     DrawRadioButton

        ldax    #joy_btn2
        ldy     curr+InputState::butn2
        cpy     #$80
        jsr     DrawRadioButton

        MGTK_CALL MGTK::ShowCursor
done:   rts

curr:   .tag InputState
last:   .tag InputState

pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy

.endproc

last_joy_valid_flag:
        .byte   0

;;; ============================================================

pdl0:   .byte   0
pdl1:   .byte   0
pdl2:   .byte   0
pdl3:   .byte   0

.proc ReadPaddles
        ;; Slow down on IIgs
        bit     is_iigs_flag
        bpl     :+
        lda     CYAREG
        pha
        and     #%01111111      ; clear bit 7
        sta     CYAREG
:
        ;; Slow down on IIe Card.
        ;; Per Technical Note: Apple IIe #10: The Apple IIe Card for the Macintosh LC
        ;; http://www.1000bit.it/support/manuali/apple/technotes/aiie/tn.aiie.10.html

        bit     is_iiecard_flag
        bpl     :+
        lda     MACIIE
        pha
        and     #%11111011      ; clear bit 2
        sta     MACIIE
:

        ;; Read all paddles
        ldx     #kNumPaddles - 1
:       jsr     PRead
        tya
        sta     pdl0,x
        dex
        bpl     :-

        ;; Restore speed on IIgs
        bit     is_iigs_flag
        bpl     :+
        pla
        sta     CYAREG
:
        ;; Restore speed on IIe Card
        bit     is_iiecard_flag
        bpl     :+
        pla
        sta     MACIIE
:
        rts

.proc PRead
        ;; Let any previous timer reset (but don't wait forever)
        ldy     #0
:       dey
        nop                     ; Empirically, 4 NOPs are needed here.
        nop                     ; https://github.com/a2stuff/a2d/issues/173
        nop
        nop
        beq     :+
        lda     PADDL0,x
        bmi     :-

        ;; Read paddle
        ;; Per Technical Note: Apple IIe #6: The Apple II Paddle Circuits
        ;; http://www.1000bit.it/support/manuali/apple/technotes/aiie/tn.aiie.06.html
:       lda     PTRIG           ; Trigger paddles
        ldy     #0              ; Init counter
        nop                     ; ... and wait for first count
        nop
:       lda     PADDL0,X        ; 11 microsecond loop
        bpl     done
        iny
        bne     :-
        dey                     ; handle overflow
done:   rts
.endproc

.endproc

;;; ============================================================

        .include "../lib/drawstring.s"

;;; ============================================================

da_end  := *
.assert * < WINDOW_ENTRY_TABLES, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00

;;; ============================================================
