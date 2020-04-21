;;; ============================================================
;;; CONTROL.PANEL - Desk Accessory
;;;
;;; A control panel offering system settings:
;;;   * DeskTop pattern
;;;   * Joystick calibration
;;;   * Double-click speed
;;;   * Insertion point blink rate
;;; ============================================================

        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        .org $800

entry:

;;; Copy the DA to AUX for easy bank switching
.scope
        lda     ROMIN2
        copy16  #$0800, STARTLO
        copy16  #da_end, ENDLO
        copy16  #$0800, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
        lda     LCBANK1
        lda     LCBANK1
.endscope

.scope
        ;; run the DA
        sta     RAMRDON         ; Run from Aux
        sta     RAMWRTON
        jsr     init

        ;; tear down/exit
        sta     RAMRDOFF        ; Back to Main
        sta     RAMWRTOFF

        jsr     save_settings

        rts
.endscope

;;; ============================================================

kDAWindowId     = 61
kDAWidth        = 416
kDAHeight       = 122
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - 10 - kDAHeight)/2 + 10

str_title:
        PASCAL_STRING "Control Panel"

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
viewloc:        DEFINE_POINT kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
maprect:        DEFINE_RECT 0, 0, kDAWidth, kDAHeight, maprect
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:          DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

.params frame_pensize
penwidth:       .byte   4
penheight:      .byte   2
.endparams

frame_p1:       DEFINE_POINT 0, 58
frame_p2:       DEFINE_POINT kDAWidth, 58
frame_p3:       DEFINE_POINT 190, 0
frame_p4:       DEFINE_POINT 190, kDAHeight

frame_rect:     DEFINE_RECT AS_WORD(-1), AS_WORD(-1), kDAWidth - 4 + 2, kDAHeight - 2 + 2


.params winfo_fullscreen
window_id:      .byte   kDAWindowId+1
options:        .byte   MGTK::Option::dialog_box
title:          .addr   str_title
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   32
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kScreenWidth
mincontlength:  .word   kScreenHeight
maxcontwidth:   .word   kScreenWidth
maxcontlength:  .word   kScreenHeight
port:
viewloc:        DEFINE_POINT 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
maprect:        DEFINE_RECT 0, 0, kScreenWidth, kScreenHeight
pattern:        .res    8, 0
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
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
screen: DEFINE_POINT 0, 0, screen
window: DEFINE_POINT 0, 0, window
.endparams
        mx := screentowindow_params::window::xcoord
        my := screentowindow_params::window::ycoord

.params grafport
viewloc:        DEFINE_POINT 0, 0
mapbits:        .word   0
mapwidth:       .byte   0
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 0, 0
pattern:        .res    8, 0
colormasks:     .byte   0, 0
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textback:       .byte   0
textfont:       .addr   0
.endparams


;;; ============================================================
;;; Common Resources

kRadioButtonWidth       = 15
kRadioButtonHeight      = 7

.params checked_params
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   checked_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, kRadioButtonWidth, kRadioButtonHeight
.endparams

checked_bitmap:
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%1110001),PX(%1110001),PX(%1100000)
        .byte   PX(%1100111),PX(%1111100),PX(%1100000)
        .byte   PX(%1100111),PX(%1111100),PX(%1100000)
        .byte   PX(%1110001),PX(%1110001),PX(%1100000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)

.params unchecked_params
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   unchecked_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, kRadioButtonWidth, kRadioButtonHeight
.endparams

unchecked_bitmap:
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%1110000),PX(%0000001),PX(%1100000)
        .byte   PX(%1100000),PX(%0000000),PX(%1100000)
        .byte   PX(%1100000),PX(%0000000),PX(%1100000)
        .byte   PX(%1110000),PX(%0000001),PX(%1100000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)

;;; ============================================================
;;; Desktop Pattern Editor Resources

kPatternEditX   = 12
kPatternEditY   = 6

kFatBitWidth            = 8
kFatBitWidthShift       = 3
kFatBitHeight           = 4
kFatBitHeightShift      = 2
fatbits_frame:
        DEFINE_RECT_SZ kPatternEditX, kPatternEditY,  8 * kFatBitWidth + 1, 8 * kFatBitHeight + 1, fatbits_frame
fatbits_rect:                   ; For hit testing
        DEFINE_RECT_SZ kPatternEditX+1, kPatternEditY+1,  8 * kFatBitWidth - 1, 8 * kFatBitHeight - 1, fatbits_rect

str_desktop_pattern:
        DEFINE_STRING "Desktop Pattern"
pattern_label_pos:
        DEFINE_POINT kPatternEditX + 35, kPatternEditY + 47

kPreviewLeft    = kPatternEditX + 79
kPreviewTop     = kPatternEditY
kPreviewRight   = kPreviewLeft + 81
kPreviewBottom  = kPreviewTop + 33
kPreviewSpacing = kPreviewTop + 6

preview_rect:
        DEFINE_RECT kPreviewLeft+1, kPreviewSpacing + 1, kPreviewRight - 1, kPreviewBottom - 1

preview_line:
        DEFINE_RECT kPreviewLeft, kPreviewSpacing, kPreviewRight, kPreviewSpacing

preview_frame:
        DEFINE_RECT kPreviewLeft, kPreviewTop, kPreviewRight, kPreviewBottom

kArrowWidth     = 6
kArrowHeight    = 5
kArrowInset     = 5

kRightArrowLeft         = kPreviewRight - kArrowInset - kArrowWidth
kRightArrowTop          = kPreviewTop+1
kRightArrowRight        = kRightArrowLeft + kArrowWidth - 1
kRightArrowBottom       = kRightArrowTop + kArrowHeight - 1

kLeftArrowLeft          = kPreviewLeft + kArrowInset + 1
kLeftArrowTop           = kPreviewTop + 1
kLeftArrowRight         = kLeftArrowLeft + kArrowWidth - 1
kLeftArrowBottom        = kLeftArrowTop + kArrowHeight - 1

.params larr_params
viewloc:        DEFINE_POINT kLeftArrowLeft, kLeftArrowTop
mapbits:        .addr   larr_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, kArrowWidth-1, kArrowHeight-1
.endparams

.params rarr_params
viewloc:        DEFINE_POINT kRightArrowLeft, kRightArrowTop
mapbits:        .addr   rarr_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, kArrowWidth-1, kArrowHeight-1
.endparams

larr_rect:      DEFINE_RECT kLeftArrowLeft-2, kLeftArrowTop, kLeftArrowRight+2, kLeftArrowBottom
rarr_rect:      DEFINE_RECT kRightArrowLeft-2, kRightArrowTop, kRightArrowRight+2, kRightArrowBottom

larr_bitmap:
        .byte   PX(%0000110)
        .byte   PX(%0011110)
        .byte   PX(%1111110)
        .byte   PX(%0011110)
        .byte   PX(%0000110)
rarr_bitmap:
        .byte   PX(%1100000)
        .byte   PX(%1111000)
        .byte   PX(%1111110)
        .byte   PX(%1111000)
        .byte   PX(%1100000)

;;; ============================================================
;;; Double-Click Speed Resources

kDblClickX      = 208
kDblClickY      = 6

        ;; Selected index (1-3, or 0 for 'no match')
dblclick_selection:
        .byte   1

        ;; Computed counter values
kDblClickSpeedTableSize = 3
dblclick_speed_table:
        .word   kDefaultDblClickSpeed * 1
        .word   kDefaultDblClickSpeed * 4
        .word   kDefaultDblClickSpeed * 16

str_dblclick_speed:
        DEFINE_STRING "Double-Click Speed"

dblclick_label_pos:
        DEFINE_POINT kDblClickX + 45, kDblClickY + 47

.params dblclick_params
viewloc:        DEFINE_POINT kDblClickX, kDblClickY
mapbits:        .addr   dblclick_bitmap
mapwidth:       .byte   8
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 53, 33
.endparams

dblclick_arrow_pos1:
        DEFINE_POINT kDblClickX + 65, kDblClickY + 7
dblclick_arrow_pos2:
        DEFINE_POINT kDblClickX + 65, kDblClickY + 22
dblclick_arrow_pos3:
        DEFINE_POINT kDblClickX + 110, kDblClickY + 10
dblclick_arrow_pos4:
        DEFINE_POINT kDblClickX + 110, kDblClickY + 22
dblclick_arrow_pos5:
        DEFINE_POINT kDblClickX + 155, kDblClickY + 13
dblclick_arrow_pos6:
        DEFINE_POINT kDblClickX + 155, kDblClickY + 23

dblclick_button_rect1:
        DEFINE_RECT_SZ kDblClickX + 175, kDblClickY + 25, kRadioButtonWidth, kRadioButtonHeight
dblclick_button_rect2:
        DEFINE_RECT_SZ kDblClickX + 130, kDblClickY + 25, kRadioButtonWidth, kRadioButtonHeight
dblclick_button_rect3:
        DEFINE_RECT_SZ kDblClickX +  85, kDblClickY + 25, kRadioButtonWidth, kRadioButtonHeight

dblclick_bitmap:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000111),PX(%1111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0011100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1110000)
        .byte   PX(%1110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011100)
        .byte   PX(%1100000),PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000),PX(%0001100)
        .byte   PX(%1100000),PX(%0110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000),PX(%0001100)
        .byte   PX(%1100000),PX(%0110000),PX(%0000000),PX(%0011111),PX(%1110000),PX(%0000000),PX(%0011000),PX(%0001100)
        .byte   PX(%1100000),PX(%0110000),PX(%0000001),PX(%1110000),PX(%0011110),PX(%0000000),PX(%0011000),PX(%0001100)
        .byte   PX(%1100000),PX(%0110000),PX(%0000111),PX(%0110000),PX(%0011011),PX(%1000000),PX(%0011000),PX(%0001100)
        .byte   PX(%1100000),PX(%0110101),PX(%0101110),PX(%0110000),PX(%0011001),PX(%1101010),PX(%1011000),PX(%0001100)
        .byte   PX(%1100000),PX(%0110000),PX(%0000110),PX(%0110000),PX(%0011001),PX(%1000000),PX(%0011000),PX(%0001100)
        .byte   PX(%1100000),PX(%0110000),PX(%0000110),PX(%0110000),PX(%0011001),PX(%1000000),PX(%0011000),PX(%0001100)
        .byte   PX(%1100000),PX(%0110000),PX(%0000110),PX(%0011111),PX(%1110001),PX(%1000000),PX(%0011000),PX(%0001100)
        .byte   PX(%1100000),PX(%0110000),PX(%0000110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0011000),PX(%0001100)
        .byte   PX(%1100000),PX(%0111111),PX(%1111110),PX(%0000000),PX(%0000001),PX(%1111111),PX(%1111000),PX(%0001100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0001100)


.params darrow_params
viewloc:        DEFINE_POINT 0, 0
mapbits:        .addr   darr_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 16, 7
.endparams

darr_bitmap:
        .byte   PX(%0000011),PX(%1111100),PX(%0000000)
        .byte   PX(%0000011),PX(%1111100),PX(%0000000)
        .byte   PX(%0000011),PX(%1111100),PX(%0000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1110000)
        .byte   PX(%0011111),PX(%1111111),PX(%1000000)
        .byte   PX(%0000111),PX(%1111110),PX(%0000000)
        .byte   PX(%0000001),PX(%1111000),PX(%0000000)
        .byte   PX(%0000000),PX(%0100000),PX(%0000000)

;;; ============================================================
;;; Joystick Calibration Resources

kJoystickCalibrationX = 12
kJoystickCalibrationY = 68

str_calibrate_joystick:
        DEFINE_STRING "Calibrate Joystick"
joystick_label_pos:
        DEFINE_POINT kJoystickCalibrationX + 30, kJoystickCalibrationY + 48

kJoystickDisplayX = kJoystickCalibrationX + 80
kJoystickDisplayY = kJoystickCalibrationY + 20 - 6
kJoystickDisplayW = 64
kJoystickDisplayH = 32

joy_disp_frame_rect:
        DEFINE_RECT_SZ kJoystickDisplayX - 32    , kJoystickDisplayY - 16    , kJoystickDisplayW + 7 + 1, kJoystickDisplayH + 4 + 1
joy_disp_rect:
        DEFINE_RECT_SZ kJoystickDisplayX - 32 + 1, kJoystickDisplayY - 16 + 1, kJoystickDisplayW + 7 - 1, kJoystickDisplayH + 4 - 1

joy_btn0:       DEFINE_POINT kJoystickDisplayX + 58 + 4, kJoystickDisplayY - 8, joy_btn0
joy_btn1:       DEFINE_POINT kJoystickDisplayX + 58 + 4, kJoystickDisplayY + 5, joy_btn1

joy_btn0_lpos: DEFINE_POINT kJoystickDisplayX + 48 + 4, kJoystickDisplayY - 8 + 8
joy_btn1_lpos: DEFINE_POINT kJoystickDisplayX + 48 + 4, kJoystickDisplayY + 5 + 8

joy_btn0_label:   DEFINE_STRING "0"
joy_btn1_label:   DEFINE_STRING "1"

.params joy_marker
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   joy_marker_bitmap
mapwidth:       .byte   2
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 7, 4
.endparams

joy_marker_bitmap:
        .byte   PX(%0011110),PX(%0000000)
        .byte   PX(%0111111),PX(%0000000)
        .byte   PX(%1111111),PX(%1000000)
        .byte   PX(%0111111),PX(%0000000)
        .byte   PX(%0011110),PX(%0000000)


.params joystick_params
viewloc:        DEFINE_POINT kJoystickCalibrationX+1, kJoystickCalibrationY + 6
mapbits:        .addr   joystick_bitmap
mapwidth:       .byte   6
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 35, 18
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

;;; ============================================================
;;; IP Blink Speed Resources

kIPBlinkDisplayX = 214
kIPBlinkDisplayY = 75

        ;; Selected index (1-3, or 0 for 'no match')
ipblink_selection:
        .byte   0

str_ipblink_label1:
        DEFINE_STRING "Rate of Insertion"
str_ipblink_label2:
        DEFINE_STRING "Point Blinking"
str_ipblink_slow:
        DEFINE_STRING "Slow"
str_ipblink_fast:
        DEFINE_STRING "Fast"

ipblink_label1_pos:
        DEFINE_POINT kIPBlinkDisplayX, kIPBlinkDisplayY + 11
ipblink_label2_pos:
        DEFINE_POINT kIPBlinkDisplayX, kIPBlinkDisplayY + 10 + 11
ipblink_slow_pos:
        DEFINE_POINT kIPBlinkDisplayX + 110 - 4 + 2, kIPBlinkDisplayY + 16 + 5 + 12 + 1
ipblink_fast_pos:
        DEFINE_POINT kIPBlinkDisplayX + 140 + 4 + 4, kIPBlinkDisplayY + 16 + 5 + 12 + 1

ipblink_btn1_rect:
        DEFINE_RECT_SZ kIPBlinkDisplayX + 110 + 2, kIPBlinkDisplayY + 16, kRadioButtonWidth, kRadioButtonHeight
ipblink_btn2_rect:
        DEFINE_RECT_SZ kIPBlinkDisplayX + 130 + 2, kIPBlinkDisplayY + 16, kRadioButtonWidth, kRadioButtonHeight
ipblink_btn3_rect:
        DEFINE_RECT_SZ kIPBlinkDisplayX + 150 + 2, kIPBlinkDisplayY + 16, kRadioButtonWidth, kRadioButtonHeight




.params ipblink_bitmap_params
viewloc:        DEFINE_POINT kIPBlinkDisplayX + 120 - 1, kIPBlinkDisplayY
mapbits:        .addr   ipblink_bitmap
mapwidth:       .byte   6
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 37, 12
.endparams

ipblink_bitmap:
        .byte   PX(%0000110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0110000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0110000),PX(%0000001),PX(%1000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000011),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%1100110),PX(%0110011),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000011),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0110000),PX(%0000001),PX(%1000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0110000)

.params ipblink_bitmap_ip_params
viewloc:        DEFINE_POINT kIPBlinkDisplayX + 120 - 1 + 20, kIPBlinkDisplayY
mapbits:        .addr   ipblink_ip_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 1, 12
.endparams

ipblink_ip_bitmap:
        .byte   PX(%1100000)
        .byte   PX(%1100000)
        .byte   PX(%1100000)
        .byte   PX(%1100000)
        .byte   PX(%1100000)
        .byte   PX(%1100000)
        .byte   PX(%1100000)
        .byte   PX(%1100000)
        .byte   PX(%1100000)
        .byte   PX(%1100000)
        .byte   PX(%1100000)
        .byte   PX(%1100000)
        .byte   PX(%1100000)

;;; ============================================================

.proc init
        jsr     init_pattern
        jsr     init_ipblink
        jsr     init_dblclick

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     draw_window
        MGTK_CALL MGTK::FlushEvents
        ;; fall through
.endproc

.proc input_loop
        MGTK_CALL MGTK::GetEvent, event_params
        bne     exit
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     handle_down
        cmp     #MGTK::EventKind::key_down
        beq     handle_key

        jsr     do_joystick

        jsr     do_ipblink

        jmp     input_loop
.endproc

.proc exit
        MGTK_CALL MGTK::CloseWindow, winfo
        rts
.endproc

;;; ============================================================

.proc handle_key
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     exit
        bne     input_loop
.endproc

;;; ============================================================

.proc handle_down
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        bne     exit
        lda     findwindow_params::window_id
        cmp     winfo::window_id
        bne     input_loop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     handle_close
        cmp     #MGTK::Area::dragbar
        beq     handle_drag
        cmp     #MGTK::Area::content
        beq     handle_click
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_close
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        bne     exit
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_drag
        copy    winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
common: bit     dragwindow_params::moved
        bpl     :+

        ;; Draw DeskTop's windows
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_REDRAW_ALL
        sta     RAMRDON
        sta     RAMWRTON

        ;; Draw DA's window
        jsr     draw_window

        ;; Draw DeskTop icons
        ITK_CALL IconTK::RedrawIcons

:       jmp     input_loop

.endproc


;;; ============================================================

.proc handle_click
        copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, fatbits_rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        jmp     handle_bits_click
        END_IF

        MGTK_CALL MGTK::InRect, larr_rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        jmp     handle_larr_click
        END_IF

        MGTK_CALL MGTK::InRect, rarr_rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        jmp     handle_rarr_click
        END_IF

        MGTK_CALL MGTK::InRect, preview_rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        jmp     handle_pattern_click
        END_IF

        MGTK_CALL MGTK::InRect, dblclick_button_rect1
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #1
        jmp     handle_dblclick_click
        END_IF

        MGTK_CALL MGTK::InRect, dblclick_button_rect2
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #2
        jmp     handle_dblclick_click
        END_IF

        MGTK_CALL MGTK::InRect, dblclick_button_rect3
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #3
        jmp     handle_dblclick_click
        END_IF

        MGTK_CALL MGTK::InRect, ipblink_btn1_rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #1
        jmp     handle_ipblink_click
        END_IF

        MGTK_CALL MGTK::InRect, ipblink_btn2_rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #2
        jmp     handle_ipblink_click
        END_IF

        MGTK_CALL MGTK::InRect, ipblink_btn3_rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #3
        jmp     handle_ipblink_click
        END_IF

        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_rarr_click
        inc     pattern_index

        lda     pattern_index
        cmp     #kPatternCount
        IF_GE
        copy    #0, pattern_index
        END_IF

        jmp     update_pattern
.endproc

.proc handle_larr_click
        dec     pattern_index

        lda     pattern_index
        IF_NEG
        copy    #kPatternCount-1, pattern_index
        END_IF

        jmp     update_pattern
.endproc

.proc update_pattern
        ptr := $06
        lda     pattern_index
        asl
        tay
        copy16  patterns,y, ptr
        ldy     #7
:       lda     (ptr),y
        sta     pattern,y
        dey
        bpl     :-

        jsr     update_bits
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_bits_click

        ;; Determine sense flag (0=clear, $FF=set)
        jsr     map_coords
        ldx     mx
        ldy     my

        stx     lastx
        sty     lasty

        lda     pattern,y
        and     mask1,x
        beq     :+
        lda     #0
        jmp     @store
:       lda     #$FF
@store: sta     flag

        ;; Toggle pattern bit
loop:   ldx     mx
        ldy     my
        lda     pattern,y
        bit     flag
        bpl     :+
        ora     mask1,x         ; set bit
        jmp     @store
:       and     mask2,x         ; clear bit
@store: sta     pattern,y
        jsr     update_bits

        ;; Repeat until mouse-up
event:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_up
        bne     :+
        jmp     input_loop

:       copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, fatbits_rect
        cmp     #MGTK::inrect_inside
        bne     event

        jsr     map_coords
        lda     mx
        cmp     lastx
        bne     moved
        lda     my
        cmp     lasty
        bne     moved
        jmp     event

moved:  copy    mx, lastx
        copy    my, lasty
        jmp     loop

mask1:  .byte   1<<0, 1<<1, 1<<2, 1<<3, 1<<4, 1<<5, 1<<6, 1<<7
mask2:  .byte   AS_BYTE(~(1<<0)), AS_BYTE(~(1<<1)), AS_BYTE(~(1<<2)), AS_BYTE(~(1<<3)), AS_BYTE(~(1<<4)), AS_BYTE(~(1<<5)), AS_BYTE(~(1<<6)), AS_BYTE(~(1<<7))

flag:   .byte   0

lastx:  .byte   0
lasty:  .byte   0
.endproc

;;; Assumes click is within fatbits_rect
.proc map_coords
        sub16   mx, fatbits_rect::x1, mx
        sub16   my, fatbits_rect::y1, my

        ldy     #kFatBitWidthShift
:       lsr16   mx
        dey
        bne     :-

        ldy     #kFatBitHeightShift
:       lsr16   my
        dey
        bne     :-

        rts
.endproc

.proc update_bits
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor
        jsr     draw_bits
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

.proc init_dblclick
        ;; Find matching index in word table, or 0
        ldx     #kDblClickSpeedTableSize * 2
loop:   lda     SETTINGS + DeskTopSettings::dblclick_speed
        cmp     dblclick_speed_table-2,x
        bne     next
        lda     SETTINGS + DeskTopSettings::dblclick_speed+1
        cmp     dblclick_speed_table-2+1,x
        bne     next
        ;; Found a match
        txa
        lsr                     ; /= 2
        sta     dblclick_selection
        rts

next:   dex
        dex
        bpl     loop
        copy    #0, dblclick_selection ; not found
        rts
.endproc

.proc handle_dblclick_click
        sta     dblclick_selection  ; 1, 2 or 3
        asl                     ; *= 2
        tax
        dex
        dex                     ; 0, 2 or 4

        copy16  dblclick_speed_table,x, SETTINGS + DeskTopSettings::dblclick_speed

        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor
        jsr     draw_dblclick_buttons
        MGTK_CALL MGTK::ShowCursor
        jmp     input_loop
.endproc

;;; ============================================================


.proc init_pattern
        ptr := $06

        MGTK_CALL MGTK::GetDeskPat, ptr
        ldy     #.sizeof(MGTK::Pattern)-1
:       lda     (ptr),y
        sta     pattern,y
        dey
        bpl     :-
        rts
.endproc

.proc handle_pattern_click
        MGTK_CALL MGTK::SetDeskPat, pattern
        COPY_STRUCT MGTK::Pattern, pattern, SETTINGS + DeskTopSettings::pattern

        MGTK_CALL MGTK::OpenWindow, winfo_fullscreen
        MGTK_CALL MGTK::CloseWindow, winfo_fullscreen

        ;; Draw DeskTop's windows
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_REDRAW_ALL
        sta     RAMRDON
        sta     RAMWRTON

        ;; Draw DA's window
        jsr     draw_window

        ;; Draw DeskTop icons
        ITK_CALL IconTK::RedrawIcons

        jmp input_loop
.endproc

;;; ============================================================

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy


;;; ============================================================

.proc draw_window
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        IF_EQ
        rts
        END_IF

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        ;; ==============================
        ;; Desktop Pattern

        MGTK_CALL MGTK::MoveTo, pattern_label_pos
        MGTK_CALL MGTK::DrawText, str_desktop_pattern

        MGTK_CALL MGTK::SetPenMode, penBIC
        MGTK_CALL MGTK::FrameRect, fatbits_frame
        MGTK_CALL MGTK::PaintBits, larr_params
        MGTK_CALL MGTK::PaintBits, rarr_params

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, preview_frame

        MGTK_CALL MGTK::SetPenMode, penBIC
        MGTK_CALL MGTK::FrameRect, preview_line

        jsr     draw_bits

        MGTK_CALL MGTK::SetPenMode, notpencopy

        ;; ==============================
        ;; Double-Click Speed

        MGTK_CALL MGTK::MoveTo, dblclick_label_pos
        MGTK_CALL MGTK::DrawText, str_dblclick_speed


.macro copy32 arg1, arg2
        .scope
        ldy     #3
loop:   copy    arg1,y, arg2,y
        dey
        bpl     loop
        .endscope
.endmacro

        ;; TODO: Loop here
        copy32 dblclick_arrow_pos1, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params
        copy32 dblclick_arrow_pos2, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params
        copy32 dblclick_arrow_pos3, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params
        copy32 dblclick_arrow_pos4, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params
        copy32 dblclick_arrow_pos5, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params
        copy32 dblclick_arrow_pos6, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params

        jsr     draw_dblclick_buttons

        MGTK_CALL MGTK::PaintBits, dblclick_params

        MGTK_CALL MGTK::SetPenSize, winfo::penwidth

        ;; ==============================
        ;; Joystick Calibration

        MGTK_CALL MGTK::MoveTo, joystick_label_pos
        MGTK_CALL MGTK::DrawText, str_calibrate_joystick

        MGTK_CALL MGTK::PaintBits, joystick_params

        MGTK_CALL MGTK::FrameRect, joy_disp_frame_rect

        MGTK_CALL MGTK::MoveTo, joy_btn0_lpos
        MGTK_CALL MGTK::DrawText, joy_btn0_label
        MGTK_CALL MGTK::MoveTo, joy_btn1_lpos
        MGTK_CALL MGTK::DrawText, joy_btn1_label

        copy    #0, last_joy_valid_flag

        ;; ==============================
        ;; IP Blinking

        MGTK_CALL MGTK::MoveTo, ipblink_label1_pos
        MGTK_CALL MGTK::DrawText, str_ipblink_label1

        MGTK_CALL MGTK::MoveTo, ipblink_label2_pos
        MGTK_CALL MGTK::DrawText, str_ipblink_label2

        MGTK_CALL MGTK::PaintBits, ipblink_bitmap_params

        MGTK_CALL MGTK::MoveTo, ipblink_slow_pos
        MGTK_CALL MGTK::DrawText, str_ipblink_slow

        MGTK_CALL MGTK::MoveTo, ipblink_fast_pos
        MGTK_CALL MGTK::DrawText, str_ipblink_fast

        jsr     draw_ipblink_buttons

        ;; ==============================
        ;; Frame

        MGTK_CALL MGTK::SetPenSize, frame_pensize
        MGTK_CALL MGTK::MoveTo, frame_p1
        MGTK_CALL MGTK::LineTo, frame_p2
        MGTK_CALL MGTK::MoveTo, frame_p3
        MGTK_CALL MGTK::LineTo, frame_p4
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, winfo::penwidth

done:   MGTK_CALL MGTK::ShowCursor
        rts

.endproc

.proc draw_dblclick_buttons
        MGTK_CALL MGTK::SetPenMode, notpencopy

        ldax    #dblclick_button_rect1
        ldy     dblclick_selection
        cpy     #1
        jsr     draw_radio_button

        ldax    #dblclick_button_rect2
        ldy     dblclick_selection
        cpy     #2
        jsr     draw_radio_button

        ldax    #dblclick_button_rect3
        ldy     dblclick_selection
        cpy     #3
        jsr     draw_radio_button
.endproc


.proc draw_ipblink_buttons
        MGTK_CALL MGTK::SetPenMode, notpencopy

        ldax    #ipblink_btn1_rect
        ldy     ipblink_selection
        cpy     #1
        jsr     draw_radio_button

        ldax    #ipblink_btn2_rect
        ldy     ipblink_selection
        cpy     #2
        jsr     draw_radio_button

        ldax    #ipblink_btn3_rect
        ldy     ipblink_selection
        cpy     #3
        jsr     draw_radio_button

        rts
.endproc

;;; A,X = pos ptr, Z = checked
.proc draw_radio_button
        ptr := $06

        stax    ptr
        beq     checked

unchecked:
        ldy     #3
:       lda     (ptr),y
        sta     unchecked_params::viewloc,y
        dey
        bpl     :-
        MGTK_CALL MGTK::PaintBits, unchecked_params
        rts

checked:
        ldy     #3
:       lda     (ptr),y
        sta     checked_params::viewloc,y
        dey
        bpl     :-
        MGTK_CALL MGTK::PaintBits, checked_params
        rts
.endproc


bitpos:    DEFINE_POINT    0, 0, bitpos

.proc draw_bits
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, pattern
        MGTK_CALL MGTK::PaintRect, preview_rect

        MGTK_CALL MGTK::SetPattern, winfo::pattern
        MGTK_CALL MGTK::SetPenSize, size

        copy    #0, ypos
        copy16  fatbits_rect::y1, bitpos::ycoord

yloop:  copy    #0, xpos
        copy16  fatbits_rect::x1, bitpos::xcoord
        ldy     ypos
        copy    pattern,y, row

xloop:  ror     row
        bcc     zero
        lda     #MGTK::pencopy
        bpl     store
zero:   lda     #MGTK::notpencopy
store:  sta     mode

        MGTK_CALL MGTK::SetPenMode, mode
        MGTK_CALL MGTK::MoveTo, bitpos
        MGTK_CALL MGTK::LineTo, bitpos

        ;; next x
        inc     xpos
        lda     xpos
        cmp     #8
        IF_NE
        add16   bitpos::xcoord, #kFatBitWidth, bitpos::xcoord
        jmp     xloop
        END_IF

        ;; next y
        inc     ypos
        lda     ypos
        cmp     #8
        IF_NE
        add16   bitpos::ycoord, #kFatBitHeight, bitpos::ycoord
        jmp     yloop
        END_IF

        rts

xpos:   .byte   0
ypos:   .byte   0
row:    .byte   0

mode:   .byte   0
size:   .byte kFatBitWidth, kFatBitHeight

.endproc

;;; ============================================================

pattern:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

pattern_index:  .byte   0
kPatternCount = 15 + 14         ; 15 B&W patterns, 14 solid color patterns
patterns:
        .addr pattern_checkerboard, pattern_dark, pattern_vdark, pattern_black
        .addr pattern_olives, pattern_scales, pattern_stripes
        .addr pattern_light, pattern_vlight, pattern_xlight, pattern_white
        .addr pattern_cane, pattern_brick, pattern_curvy, pattern_abrick
        .addr pattern_c1, pattern_c2, pattern_c3, pattern_c4
        .addr pattern_c5, pattern_c6, pattern_c7, pattern_c8
        .addr pattern_c9, pattern_cA, pattern_cB, pattern_cC
        .addr pattern_cD, pattern_cE

pattern_checkerboard:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

pattern_dark:
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001

pattern_vdark:
        .byte   %10001000
        .byte   %00000000
        .byte   %00100010
        .byte   %00000000
        .byte   %10001000
        .byte   %00000000
        .byte   %00100010
        .byte   %00000000

pattern_black:
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000

pattern_olives:
        .byte   %00010001
        .byte   %01101110
        .byte   %00001110
        .byte   %00001110
        .byte   %00010001
        .byte   %11100110
        .byte   %11100000
        .byte   %11100000

pattern_scales:
        .byte   %11111110
        .byte   %11111110
        .byte   %01111101
        .byte   %10000011
        .byte   %11101111
        .byte   %11101111
        .byte   %11010111
        .byte   %00111000

pattern_stripes:
        .byte   %01110111
        .byte   %10111011
        .byte   %11011101
        .byte   %11101110
        .byte   %01110111
        .byte   %10111011
        .byte   %11011101
        .byte   %11101110

pattern_light:
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011

pattern_vlight:
        .byte   %11101110
        .byte   %11111111
        .byte   %10111011
        .byte   %11111111
        .byte   %11101110
        .byte   %11111111
        .byte   %10111011
        .byte   %11111111

pattern_xlight:
        .byte   %11111110
        .byte   %11111111
        .byte   %11101111
        .byte   %11111111
        .byte   %11111110
        .byte   %11111111
        .byte   %11101111
        .byte   %11111111

pattern_white:
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111

pattern_cane:
        .byte   %11100000
        .byte   %11010001
        .byte   %10111011
        .byte   %00011101
        .byte   %00001110
        .byte   %00010111
        .byte   %10111011
        .byte   %01110001

pattern_brick:
        .byte   %00000000
        .byte   %11111110
        .byte   %11111110
        .byte   %11111110
        .byte   %00000000
        .byte   %11101111
        .byte   %11101111
        .byte   %11101111

pattern_curvy:
        .byte   %00111111
        .byte   %11011110
        .byte   %11101101
        .byte   %11110011
        .byte   %11001111
        .byte   %10111111
        .byte   %01111111
        .byte   %01111111

pattern_abrick:
        .byte   %11101111
        .byte   %11000111
        .byte   %10111011
        .byte   %01111100
        .byte   %11111110
        .byte   %01111111
        .byte   %10111111
        .byte   %11011111

        ;; Solid colors (note that nibbles are flipped)
pattern_c1:      .res 8, $88     ; 1 = red
pattern_c2:      .res 8, $44     ; 2 = brown
pattern_c3:      .res 8, $CC     ; 3 = orange
pattern_c4:      .res 8, $22     ; 4 = green
pattern_c5:      .res 8, $AA     ; 5 = gray1
pattern_c6:      .res 8, $66     ; 6 = light green
pattern_c7:      .res 8, $EE     ; 7 = yellow
pattern_c8:      .res 8, $11     ; 8 = blue
pattern_c9:      .res 8, $99     ; 9 = magenta
pattern_cA:      .res 8, $55     ; A = gray2
pattern_cB:      .res 8, $DD     ; B = pink
pattern_cC:      .res 8, $33     ; C = light blue
pattern_cD:      .res 8, $BB     ; D = lavender
pattern_cE:      .res 8, $77     ; E = aqua

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

.proc do_joystick

        jsr     read_paddles

        ;; TODO: Visualize all 4 paddles.

        ldx     #kNumPaddles-1
:       lda     pdl0,x
        lsr                     ; clamp range to 0...63
        lsr
        sta     curr+InputState::pdl0,x
        dex
        bpl     :-

        lsr     curr+InputState::pdl1 ; clamp Y to 0...31 (due to pixel aspect ratio)

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
        sub16   joy_x, #31, joy_x
        add16   joy_x, #kJoystickDisplayX, joy_x

        joy_y := joy_marker::viewloc::ycoord
        copy    curr+InputState::pdl1, joy_y
        copy    #0, joy_y+1
        sub16   joy_y, #15, joy_y
        add16   joy_y, #kJoystickDisplayY, joy_y

        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        IF_EQ
        rts
        END_IF

        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, joy_disp_rect

        MGTK_CALL MGTK::SetPenMode, notpencopy

        MGTK_CALL MGTK::PaintBits, joy_marker

        ldax    #joy_btn0
        ldy     curr+InputState::butn0
        cpy     #$80
        jsr     draw_radio_button

        ldax    #joy_btn1
        ldy     curr+InputState::butn1
        cpy     #$80
        jsr     draw_radio_button

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

.proc read_paddles
        ldx     #kNumPaddles - 1
:       jsr     pread
        tya
        sta     pdl0,x
        dex
        bpl     :-

        rts

.proc pread
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
;;; IP Blink

kIPBlinkSpeedTableSize = 3

ipblink_speed_table:
        .byte   kDefaultIPBlinkSpeed * 2
        .byte   kDefaultIPBlinkSpeed * 1
        .byte   kDefaultIPBlinkSpeed * 1/2

ipblink_counter:
        .byte   120

.proc init_ipblink
        lda     SETTINGS + DeskTopSettings::ip_blink_speed
        ldx     #kIPBlinkSpeedTableSize
:       cmp     ipblink_speed_table-1,x
        beq     done
        dex
        bne     :-

done:   stx     ipblink_selection
        rts
.endproc

.proc handle_ipblink_click
        sta     ipblink_selection

        tax
        lda     ipblink_speed_table-1,x
        sta     SETTINGS + DeskTopSettings::ip_blink_speed
        sta     ipblink_counter

        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor
        jsr     draw_ipblink_buttons
        MGTK_CALL MGTK::ShowCursor
        jmp     input_loop
.endproc

.proc do_ipblink
        dec     ipblink_counter
        lda     ipblink_counter
        bne     done

        copy    SETTINGS + DeskTopSettings::ip_blink_speed, ipblink_counter
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        beq     done

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintBits, ipblink_bitmap_ip_params

done:   rts

.endproc

;;; ============================================================
;;; Save Settings

filename:
        PASCAL_STRING "DeskTop.config"

filename_buffer:
        .res 65

write_buffer:
        .res .sizeof(DeskTopSettings)

        DEFINE_CREATE_PARAMS create_params, filename, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
        DEFINE_WRITE_PARAMS write_params, write_buffer, .sizeof(DeskTopSettings)
        DEFINE_CLOSE_PARAMS close_params

.proc save_settings
        ;; Run from Main, but with LCBANK1 in

        ;; Copy from LCBANK to somewhere ProDOS can read.
        COPY_STRUCT DeskTopSettings, SETTINGS, write_buffer

        sta     ALTZPOFF        ; Main ZP, ROM in, like ProDOS MLI wants.
        lda     ROMIN2

        ;; Write to desktop current prefix
        copy16  #filename, open_params::pathname
        jsr     do_write

        ;; Write to the original file location, if necessary
        jsr     get_copied_to_ramcard_flag
        beq     done
        ldax    #filename_buffer
        stax    open_params::pathname
        jsr     copy_desktop_orig_prefix
        jsr     append_filename
        jsr     do_write

done:   sta     ALTZPON         ; Aux ZP, LCBANK1 in, like DeskTop wants.
        lda     LCBANK1
        lda     LCBANK1
        rts

.proc append_filename
        ;; Append filename to buffer
        inc     filename_buffer ; Add '/' separator
        ldx     filename_buffer
        lda     #'/'
        sta     filename_buffer,x

        ldx     #0              ; Append filename
        ldy     filename_buffer
:       inx
        iny
        lda     filename,x
        sta     filename_buffer,y
        cpx     filename
        bne     :-
        sty     filename_buffer
        rts
.endproc

.proc do_write
        ;; Create if necessary
        copy16  DATELO, create_params::create_date
        copy16  TIMELO, create_params::create_time
        MLI_CALL CREATE, create_params

        MLI_CALL OPEN, open_params
        bcs     done
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_CALL WRITE, write_params
close:  MLI_CALL CLOSE, close_params
done:   rts
.endproc

.endproc


;;; ============================================================

        dummy_address := $1234



;;; Assert: ALTZPOFF
.proc get_copied_to_ramcard_flag
        lda     LCBANK2
        lda     LCBANK2
        lda     COPIED_TO_RAMCARD_FLAG
        tax
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts
.endproc

;;; Assert: ALTZPOFF
.proc copy_ramcard_prefix
        stax    @addr
        lda     LCBANK2
        lda     LCBANK2

        ldx     RAMCARD_PREFIX
:       lda     RAMCARD_PREFIX,x
        @addr := *+1
        sta     dummy_address,x
        dex
        bpl     :-

        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

;;; Assert: ALTZPOFF
.proc copy_desktop_orig_prefix
        stax    @addr
        lda     LCBANK2
        lda     LCBANK2

        ldx     DESKTOP_ORIG_PREFIX
:       lda     DESKTOP_ORIG_PREFIX,x
        @addr := *+1
        sta     dummy_address,x
        dex
        bpl     :-

        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

;;; ============================================================

da_end  := *
.assert * < WINDOW_ICON_TABLES, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but icon tables start at AUX $1B00

;;; ============================================================
