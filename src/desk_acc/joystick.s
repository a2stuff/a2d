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
        .include "../toolkits/btk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

kDAWindowId     = $80
kDAWidth        = 270
kDAHeight       = 85
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

str_title:
        PASCAL_STRING res_string_window_title

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


;;; ============================================================


.params event_params
kind:  .byte   0
;;; EventKind::key_down
key             := *
modifiers       := * + 1
;;; EventKind::update
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

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort

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

        DEFINE_BUTTON joy_btn0_button, kDAWindowId, res_string_label_joy_btn0,, kJoystickDisplayX + kJoystickDisplayW + 20, kJoystickDisplayY + 10
        DEFINE_BUTTON joy_btn1_button, kDAWindowId, res_string_label_joy_btn1,, kJoystickDisplayX + kJoystickDisplayW + 20, kJoystickDisplayY + 30
        DEFINE_BUTTON joy_btn2_button, kDAWindowId, res_string_label_joy_btn2,, kJoystickDisplayX + kJoystickDisplayW + 20, kJoystickDisplayY + 50

.params joy_marker
        DEFINE_POINT viewloc, kJoystickDisplayX+1, kJoystickDisplayY+1
mapbits:        .addr   joy_marker_bitmap
mapwidth:       .byte   2
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 7, 4
        REF_MAPINFO_MEMBERS
.endparams

.params joy_marker2
        DEFINE_POINT viewloc, kJoystickDisplayX+1, kJoystickDisplayY+1
mapbits:        .addr   joy_marker_bitmap2
mapwidth:       .byte   2
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 7, 4
        REF_MAPINFO_MEMBERS
.endparams

joy_marker_bitmap:
        PIXELS  "..####.."
        PIXELS  ".######."
        PIXELS  "########"
        PIXELS  ".######."
        PIXELS  "..####.."

joy_marker_bitmap2:
        PIXELS  "..####.."
        PIXELS  ".##..##."
        PIXELS  "##....##"
        PIXELS  ".##..##."
        PIXELS  "..####.."

.params joystick_params
        DEFINE_POINT viewloc, kJoystickCalibrationX+1, kJoystickCalibrationY + 6
mapbits:        .addr   joystick_bitmap
mapwidth:       .byte   6
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 35, 18
        REF_MAPINFO_MEMBERS
.endparams

joystick_bitmap:
        PIXELS  "...........................###......"
        PIXELS  "...##..##############....######....."
        PIXELS  "........................######......"
        PIXELS  ".....##..##########....######......."
        PIXELS  "......................######........"
        PIXELS  "......##..#######....######........."
        PIXELS  "....................######.........."
        PIXELS  ".......##..####.....####............"
        PIXELS  "....................##.............."
        PIXELS  "...................##..............."
        PIXELS  "..................##................"
        PIXELS  "...##############################..."
        PIXELS  "..##............................##.."
        PIXELS  "..##............................##.."
        PIXELS  ".##################################."
        PIXELS  "##................................##"
        PIXELS  "##................................##"
        PIXELS  "##................................##"
        PIXELS  ".##################################."

;;; ============================================================

.proc Init
        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        jsr     DoJoystick

        jmp     InputLoop
.endproc ; InputLoop

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Exit

;;; ============================================================

.proc HandleKey
        lda     event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        beq     Exit
        bne     InputLoop       ; always
    END_IF

        cmp     #CHAR_ESCAPE
        beq     Exit
        bne     InputLoop       ; always
.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        bne     InputLoop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        beq     HandleDrag
        cmp     #MGTK::Area::content
        beq     HandleClick
        jmp     InputLoop
.endproc ; HandleDown

;;; ============================================================

.proc HandleClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        bne     Exit
        jmp     InputLoop
.endproc ; HandleClose

;;; ============================================================

.proc HandleDrag
        copy8   #kDAWindowId, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params

    IF bit dragwindow_params::moved : NS
        ;; Draw DeskTop's windows and icons.
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow
    END_IF

        jmp     InputLoop
.endproc ; HandleDrag


;;; ============================================================

.proc HandleClick
        ;; no-op
        jmp     InputLoop
.endproc ; HandleClick

;;; ============================================================

notpencopy:     .byte   MGTK::notpencopy


;;; ============================================================

.proc DrawWindow
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF ZERO                     ; not obscured
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintBits, joystick_params

        MGTK_CALL MGTK::FrameRect, joy_disp_frame_rect

        BTK_CALL BTK::RadioDraw, joy_btn0_button
        BTK_CALL BTK::RadioDraw, joy_btn1_button
        BTK_CALL BTK::RadioDraw, joy_btn2_button

        SET_BIT7_FLAG force_draw_flag
        MGTK_CALL MGTK::ShowCursor
    END_IF

        rts
.endproc ; DrawWindow

;;; ============================================================

        kNumPaddles = 4

.struct InputState
        valid   .byte

        pdl0    .byte
        pdl1    .byte
        pdl2    .byte
        pdl3    .byte

        butn0   .byte
        butn1   .byte
        butn2   .byte
.endstruct

.proc DoJoystick
        ;; Read paddles, copy into our current state
        jsr     ReadPaddles
        ldx     #kNumPaddles-1
    DO
        lda     pdl0,x
        lsr                     ; clamp range to 0...127
        sta     curr+InputState::pdl0,x
    WHILE dex : POS

        lsr     curr+InputState::pdl1 ; clamp Y to 0...63 (due to pixel aspect ratio)
        lsr     curr+InputState::pdl3 ; clamp Y to 0...63 (due to pixel aspect ratio)

        ;; Read buttons, copy into our current state
        lda     BUTN0
        and     #$80            ; only care about msb
        sta     curr+InputState::butn0

        lda     BUTN1
        and     #$80            ; only care about msb
        sta     curr+InputState::butn1

        lda     BUTN2
        and     #$80            ; only care about msb
        sta     curr+InputState::butn2

        ;; Mark current state as valid
        copy8   #$80, curr+InputState::valid

        ;; --------------------------------------------------

        ;; If last state was valid, see if joystick 2 registered
        ;; a change; if so, set a flag.
    IF bit last+InputState::valid : NS
        lda     curr+InputState::pdl2
        cmp     last+InputState::pdl2
        bne     set
        lda     curr+InputState::pdl3
        cmp     last+InputState::pdl3
        beq     :+
set:    SET_BIT7_FLAG joy2_valid_flag
:
    END_IF

        ;; Changed? (or first time through)
    IF bit force_draw_flag : NC
        ldx     #.sizeof(InputState)-1
      DO
        lda     curr,x
        cmp     last,x
        bne     :+              ; changed - draw
      WHILE dex : POS
        rts                     ; no change - skip
:
    END_IF

        ;; --------------------------------------------------

        COPY_STRUCT InputState, curr, last
        CLEAR_BIT7_FLAG force_draw_flag

        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF A = #MGTK::Error::window_obscured

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        ;; --------------------------------------------------
        ;; Joystick Position

        ;; Erase old
        MGTK_CALL MGTK::SetPenMode, penOR
    IF bit joy2_valid_flag : NS
        MGTK_CALL MGTK::PaintBits, joy_marker2
    END_IF
        MGTK_CALL MGTK::PaintBits, joy_marker

.scope joy1
        joy_x := joy_marker::viewloc::xcoord
        copy8   curr+InputState::pdl0, joy_x
        copy8   #0, joy_x+1
        add16   joy_x, #kJoystickDisplayX + 1, joy_x

        joy_y := joy_marker::viewloc::ycoord
        copy8   curr+InputState::pdl1, joy_y
        copy8   #0, joy_y+1
        add16   joy_y, #kJoystickDisplayY + 1, joy_y
.endscope ; joy1
.scope joy2
        joy_x := joy_marker2::viewloc::xcoord
        copy8   curr+InputState::pdl2, joy_x
        copy8   #0, joy_x+1
        add16   joy_x, #kJoystickDisplayX + 1, joy_x

        joy_y := joy_marker2::viewloc::ycoord
        copy8   curr+InputState::pdl3, joy_y
        copy8   #0, joy_y+1
        add16   joy_y, #kJoystickDisplayY + 1, joy_y
.endscope ; joy2

        ;; Draw new
        MGTK_CALL MGTK::SetPenMode, notpencopy
    IF bit joy2_valid_flag : NS
        MGTK_CALL MGTK::PaintBits, joy_marker2
    END_IF
        MGTK_CALL MGTK::PaintBits, joy_marker

        ;; --------------------------------------------------
        ;; Button States

        lda     curr+InputState::butn0
        and     #$80
        ASSERT_EQUALS BTK::kButtonStateChecked, $80
        sta     joy_btn0_button::state
        BTK_CALL BTK::RadioDraw, joy_btn0_button

        lda     curr+InputState::butn1
        and     #$80
        ASSERT_EQUALS BTK::kButtonStateChecked, $80
        sta     joy_btn1_button::state
        BTK_CALL BTK::RadioDraw, joy_btn1_button

        lda     curr+InputState::butn2
        and     #$80
        ASSERT_EQUALS BTK::kButtonStateChecked, $80
        sta     joy_btn2_button::state
        BTK_CALL BTK::RadioDraw, joy_btn2_button

        ;; --------------------------------------------------

        MGTK_CALL MGTK::ShowCursor
        rts

curr:   .tag InputState
last:   .tag InputState

penOR:          .byte   MGTK::penOR
notpencopy:     .byte   MGTK::notpencopy

joy2_valid_flag:                ; bit7
        .byte   0
.endproc ; DoJoystick

force_draw_flag:                ; bit7
        .byte   0

;;; ============================================================

pdl0:   .byte   0
pdl1:   .byte   0
pdl2:   .byte   0
pdl3:   .byte   0

.proc ReadPaddles
        php
        sei

        JSR_TO_MAIN JUMP_TABLE_SLOW_SPEED

        ;; Read all paddles
        ldx     #kNumPaddles - 1
    DO
        jsr     PRead
        tya
        sta     pdl0,x
    WHILE dex : POS

        JSR_TO_MAIN JUMP_TABLE_RESUME_SPEED

        plp
        rts

.proc PRead
        ;; Let any previous timer reset (but don't wait forever)
        ldy     #0
    DO
        dey
        nop                     ; Empirically, 4 NOPs are needed here.
        nop                     ; https://github.com/a2stuff/a2d/issues/173
        nop
        nop
        BREAK_IF ZERO
        lda     PADDL0,x
    WHILE NS

        ;; Read paddle
        ;; Per Technical Note: Apple IIe #6: The Apple II Paddle Circuits
        ;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/aiie/tn.aiie.06.html
        lda     PTRIG           ; Trigger paddles
        ldy     #0              ; Init counter
        nop                     ; ... and wait for first count
        nop
    DO
        lda     PADDL0,X        ; 11 microsecond loop
        bpl     done
        iny
    WHILE NOT_ZERO
        dey                     ; handle overflow

done:   rts
.endproc ; PRead

.endproc ; ReadPaddles

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX aux::Init
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
