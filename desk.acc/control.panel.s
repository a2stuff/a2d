;;; ============================================================
;;; CONTROL.PANEL - Desk Accessory
;;;
;;; A control panel offering system settings:
;;;   * DeskTop pattern
;;;   * Mouse tracking speed
;;;   * Double-click speed
;;;   * Insertion point blink rate
;;;   * Time 12- or 24-hour display
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "control.panel.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
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
kDAHeight       = 132
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
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

.params frame_pensize
penwidth:       .byte   4
penheight:      .byte   2
.endparams

        DEFINE_POINT frame_l1a, 0, 68
        DEFINE_POINT frame_l1b, 190, 68
        DEFINE_POINT frame_l2a, 190, 58
        DEFINE_POINT frame_l2b, kDAWidth, 58
        DEFINE_POINT frame_l3a, 190, 0
        DEFINE_POINT frame_l3b, 190, kDAHeight
        DEFINE_POINT frame_l4a, 190, 102
        DEFINE_POINT frame_l4b, kDAWidth, 102

        DEFINE_RECT frame_rect, AS_WORD(-1), AS_WORD(-1), kDAWidth - 4 + 2, kDAHeight - 2 + 2


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
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kScreenWidth, kScreenHeight
pattern:        .res    8, 0
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
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
penmode:        .byte   0
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

kCheckboxWidth       = 17
kCheckboxHeight      = 8

.params checked_cb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   checked_cb_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, kCheckboxWidth, kCheckboxHeight
.endparams

checked_cb_bitmap:
        .byte   PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111000),PX(%0000000),PX(%1111000)
        .byte   PX(%1100110),PX(%0000011),PX(%0011000)
        .byte   PX(%1100001),PX(%1001100),PX(%0011000)
        .byte   PX(%1100000),PX(%0110000),PX(%0011000)
        .byte   PX(%1100001),PX(%1001100),PX(%0011000)
        .byte   PX(%1100110),PX(%0000011),PX(%0011000)
        .byte   PX(%1111000),PX(%0000000),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111000)

.params unchecked_cb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   unchecked_cb_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, kCheckboxWidth, kCheckboxHeight
.endparams

unchecked_cb_bitmap:
        .byte   PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111000)

;;; ============================================================
;;; Desktop Pattern Editor Resources

kPatternEditX   = 12
kPatternEditY   = 6

kFatBitWidth            = 8
kFatBitWidthShift       = 3
kFatBitHeight           = 4
kFatBitHeightShift      = 2
        DEFINE_RECT_SZ fatbits_frame, kPatternEditX, kPatternEditY,  8 * kFatBitWidth + 1, 8 * kFatBitHeight + 1
        ;; For hit testing
        DEFINE_RECT_SZ fatbits_rect, kPatternEditX+1, kPatternEditY+1,  8 * kFatBitWidth - 1, 8 * kFatBitHeight - 1

        DEFINE_LABEL pattern, res_string_label_pattern, kPatternEditX + 35, kPatternEditY + 47

kPreviewLeft    = kPatternEditX + 79
kPreviewTop     = kPatternEditY
kPreviewRight   = kPreviewLeft + 81
kPreviewBottom  = kPreviewTop + 33
kPreviewSpacing = kPreviewTop + 6

        DEFINE_RECT preview_rect, kPreviewLeft+1, kPreviewSpacing + 1, kPreviewRight - 1, kPreviewBottom - 1
        DEFINE_RECT preview_line, kPreviewLeft, kPreviewSpacing, kPreviewRight, kPreviewSpacing
        DEFINE_RECT preview_frame, kPreviewLeft, kPreviewTop, kPreviewRight, kPreviewBottom

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
        DEFINE_POINT viewloc, kLeftArrowLeft, kLeftArrowTop
mapbits:        .addr   larr_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, kArrowWidth-1, kArrowHeight-1
.endparams

.params rarr_params
        DEFINE_POINT viewloc, kRightArrowLeft, kRightArrowTop
mapbits:        .addr   rarr_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, kArrowWidth-1, kArrowHeight-1
.endparams

        DEFINE_RECT larr_rect, kLeftArrowLeft-2, kLeftArrowTop, kLeftArrowRight+2, kLeftArrowBottom
        DEFINE_RECT rarr_rect, kRightArrowLeft-2, kRightArrowTop, kRightArrowRight+2, kRightArrowBottom

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

        DEFINE_LABEL rgb_color, res_string_label_rgb_color, kPatternEditX + 68, kPatternEditY + 59

        DEFINE_RECT_SZ rect_rgb, kPatternEditX + 46, kPatternEditY + 50, kCheckboxWidth, kCheckboxHeight

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

        DEFINE_LABEL dblclick_speed, res_string_label_dblclick_speed, kDblClickX + 45, kDblClickY + 47

.params dblclick_params
        DEFINE_POINT viewloc, kDblClickX, kDblClickY
mapbits:        .addr   dblclick_bitmap
mapwidth:       .byte   8
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 53, 33
.endparams

        DEFINE_POINT dblclick_arrow_pos1, kDblClickX + 65, kDblClickY + 7
        DEFINE_POINT dblclick_arrow_pos2, kDblClickX + 65, kDblClickY + 22
        DEFINE_POINT dblclick_arrow_pos3, kDblClickX + 110, kDblClickY + 10
        DEFINE_POINT dblclick_arrow_pos4, kDblClickX + 110, kDblClickY + 22
        DEFINE_POINT dblclick_arrow_pos5, kDblClickX + 155, kDblClickY + 13
        DEFINE_POINT dblclick_arrow_pos6, kDblClickX + 155, kDblClickY + 23

        DEFINE_RECT_SZ dblclick_button_rect1, kDblClickX + 175, kDblClickY + 25, kRadioButtonWidth, kRadioButtonHeight
        DEFINE_RECT_SZ dblclick_button_rect2, kDblClickX + 130, kDblClickY + 25, kRadioButtonWidth, kRadioButtonHeight
        DEFINE_RECT_SZ dblclick_button_rect3, kDblClickX +  85, kDblClickY + 25, kRadioButtonWidth, kRadioButtonHeight

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
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   darr_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 16, 7
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
;;; Mouse Tracking Resources

kMouseTrackingX = 25
kMouseTrackingY = 78

        DEFINE_LABEL mouse_tracking, res_string_label_mouse_tracking, kMouseTrackingX + 30, kMouseTrackingY + 45

        DEFINE_RECT_SZ tracking_button_rect1, kMouseTrackingX + 84, kMouseTrackingY + 8, kRadioButtonWidth, kRadioButtonHeight
        DEFINE_RECT_SZ tracking_button_rect2, kMouseTrackingX + 84, kMouseTrackingY + 21, kRadioButtonWidth, kRadioButtonHeight

        DEFINE_LABEL tracking_slow, res_string_label_tracking_slow, kMouseTrackingX + 105, kMouseTrackingY +  8 + 8
        DEFINE_LABEL tracking_fast, res_string_label_tracking_fast, kMouseTrackingX + 105, kMouseTrackingY + 21 + 8

.params mouse_tracking_params
        DEFINE_POINT viewloc, kMouseTrackingX + 5, kMouseTrackingY
mapbits:        .addr   mouse_tracking_bitmap
mapwidth:       .byte   9
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 62, 31
.endparams

mouse_tracking_bitmap:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0110011),PX(%0011001),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1110000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011111),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1111111),PX(%1100000),PX(%0000000),PX(%1111111),PX(%1100000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%0000000),PX(%0000011),PX(%0011001),PX(%1001100),PX(%0010011),PX(%1111111),PX(%1111111),PX(%1111001),PX(%0000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0100011),PX(%0000000),PX(%0000000),PX(%0011000),PX(%1000110)
        .byte   PX(%0000000),PX(%0000110),PX(%0110011),PX(%1001100),PX(%0100011),PX(%0101010),PX(%1010101),PX(%0111000),PX(%1000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0100011),PX(%0000000),PX(%0000000),PX(%0011000),PX(%1000110)
        .byte   PX(%0000000),PX(%0001100),PX(%1100111),PX(%1001100),PX(%0100011),PX(%0000000),PX(%0000000),PX(%0011000),PX(%1000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0100011),PX(%1111111),PX(%1111111),PX(%1111000),PX(%1000110)
        .byte   PX(%0000000),PX(%0011001),PX(%1001111),PX(%1001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0000000),PX(%0110011),PX(%0011111),PX(%1001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0000000),PX(%1100110),PX(%0111111),PX(%1001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0000001),PX(%1001100),PX(%1111111),PX(%1001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0000110),PX(%0110011),PX(%1111111),PX(%1001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0011001),PX(%1001111),PX(%1111111),PX(%1001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%1100110),PX(%0111111),PX(%1111111),PX(%1001100),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1100000)

.params scalemouse_params
x_exponent:     .byte   0
y_exponent:     .byte   0
.endparams

;;; ============================================================
;;; IP Blink Speed Resources

kIPBlinkDisplayX = 214
kIPBlinkDisplayY = 65

        ;; Selected index (1-3, or 0 for 'no match')
ipblink_selection:
        .byte   0

        DEFINE_LABEL ipblink1, res_string_label_ipblink1, kIPBlinkDisplayX-4, kIPBlinkDisplayY + 11
        DEFINE_LABEL ipblink2, res_string_label_ipblink2, kIPBlinkDisplayX-4, kIPBlinkDisplayY + 10 + 11
        DEFINE_LABEL ipblink_slow, res_string_label_ipblink_slow, kIPBlinkDisplayX + 110 - 4 + 4, kIPBlinkDisplayY + 16 + 5 + 12 + 1
        DEFINE_LABEL ipblink_fast, res_string_label_ipblink_fast, kIPBlinkDisplayX + 140 + 4 + 6, kIPBlinkDisplayY + 16 + 5 + 12 + 1

        DEFINE_RECT_SZ ipblink_btn1_rect, kIPBlinkDisplayX + 110 + 6, kIPBlinkDisplayY + 16, kRadioButtonWidth, kRadioButtonHeight
        DEFINE_RECT_SZ ipblink_btn2_rect, kIPBlinkDisplayX + 130 + 6, kIPBlinkDisplayY + 16, kRadioButtonWidth, kRadioButtonHeight
        DEFINE_RECT_SZ ipblink_btn3_rect, kIPBlinkDisplayX + 150 + 6, kIPBlinkDisplayY + 16, kRadioButtonWidth, kRadioButtonHeight

.params ipblink_bitmap_params
        DEFINE_POINT viewloc, kIPBlinkDisplayX + 120 + 3, kIPBlinkDisplayY
mapbits:        .addr   ipblink_bitmap
mapwidth:       .byte   6
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 37, 12
.endparams

ipblink_bitmap:
        .byte   PX(%0000110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0110000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0110000),PX(%0000001),PX(%1000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000011),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%1100110),PX(%0110011),PX(%0000001),PX(%1000000),PX(%1100110),PX(%0110011)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000011),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0110000),PX(%0000001),PX(%1000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000),PX(%0110000)

.params ipblink_bitmap_ip_params
        DEFINE_POINT viewloc, kIPBlinkDisplayX + 120 + 3 + 20, kIPBlinkDisplayY
mapbits:        .addr   ipblink_ip_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 1, 12
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
;;; 12/24 Hour Resources

kHourDisplayX = 210
kHourDisplayY = 114

        DEFINE_LABEL clock, res_string_label_clock, kHourDisplayX+kRadioButtonWidth, kHourDisplayY+8

        DEFINE_RECT_SZ rect_12hour, kHourDisplayX+60, kHourDisplayY, kRadioButtonWidth, kRadioButtonHeight
        DEFINE_LABEL clock_12hour, res_string_label_clock_12hour, kHourDisplayX+60+kRadioButtonWidth+6, kHourDisplayY+8

        DEFINE_RECT_SZ rect_24hour, kHourDisplayX+120, kHourDisplayY, kRadioButtonWidth, kRadioButtonHeight
        DEFINE_LABEL clock_24hour, res_string_label_clock_24hour, kHourDisplayX+120+kRadioButtonWidth+6, kHourDisplayY+8

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

        ;; Draw DeskTop's windows and icons.
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_CLEAR_UPDATES_REDRAW_ICONS
        sta     RAMRDON
        sta     RAMWRTON

        ;; Draw DA's window
        jsr     draw_window

:       jmp     input_loop

.endproc


;;; ============================================================

.proc handle_click
        copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        ;; ----------------------------------------

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

        MGTK_CALL MGTK::InRect, rect_rgb
        cmp     #MGTK::inrect_inside
        IF_EQ
        jmp     handle_rgb_click
        END_IF

        ;; ----------------------------------------

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

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, tracking_button_rect1
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #0
        jmp     handle_tracking_click
        END_IF

        MGTK_CALL MGTK::InRect, tracking_button_rect2
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #1
        jmp     handle_tracking_click
        END_IF

        ;; ----------------------------------------

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

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, rect_12hour
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #$00
        jmp     handle_hour_click
        END_IF

        MGTK_CALL MGTK::InRect, rect_24hour
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #$80
        jmp     handle_hour_click
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

        jsr     draw_preview
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
@store: cmp     pattern,y       ; did it change?
        beq     event
        sta     pattern,y

        ldx     mx
        ldy     my
        lda     flag
        jsr     draw_bit

        jsr     draw_preview

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

.proc handle_tracking_click
        ;; --------------------------------------------------
        ;; Update Settings

        sta     SETTINGS + DeskTopSettings::mouse_tracking
        ;; --------------------------------------------------
        ;; Update MGTK

        copy    #1, scalemouse_params::x_exponent
        copy    #0, scalemouse_params::y_exponent

        ;; Doubled if option selected
        lda     SETTINGS + DeskTopSettings::mouse_tracking
        IF_NOT_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
        END_IF

        ;; Also doubled if a IIc
        ldx     ROMIN
        lda     ZIDBYTE
        ldx     LCBANK1
        ldx     LCBANK1
        cmp     #0              ; ZIDBYTE=0 for IIc / IIc+
        IF_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
        END_IF

        ;; TODO: This warps the cursor position; can this be fixed?
        MGTK_CALL MGTK::ScaleMouse, scalemouse_params

        ;; --------------------------------------------------
        ;; Update the UI

        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor
        jsr     draw_tracking_buttons
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

        ;; Draw DeskTop's windows and icons.
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_CLEAR_UPDATES_REDRAW_ICONS
        sta     RAMRDON
        sta     RAMWRTON

        ;; Draw DA's window
        jsr     draw_window

        jmp     input_loop
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
        param_call DrawString, pattern_label_str

        MGTK_CALL MGTK::SetPenMode, penBIC
        MGTK_CALL MGTK::FrameRect, fatbits_frame
        MGTK_CALL MGTK::PaintBits, larr_params
        MGTK_CALL MGTK::PaintBits, rarr_params

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, preview_frame

        MGTK_CALL MGTK::SetPenMode, penBIC
        MGTK_CALL MGTK::FrameRect, preview_line

        jsr     draw_preview
        jsr     draw_bits

        MGTK_CALL MGTK::SetPenMode, notpencopy

        MGTK_CALL MGTK::MoveTo, rgb_color_label_pos
        param_call DrawString, rgb_color_label_str

        jsr     draw_rgb_checkbox

        ;; ==============================
        ;; Double-Click Speed

        MGTK_CALL MGTK::MoveTo, dblclick_speed_label_pos
        param_call DrawString, dblclick_speed_label_str


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

        ;; ==============================
        ;; Mouse Tracking Speed

        MGTK_CALL MGTK::MoveTo, mouse_tracking_label_pos
        param_call DrawString, mouse_tracking_label_str

        MGTK_CALL MGTK::MoveTo, tracking_slow_label_pos
        param_call DrawString, tracking_slow_label_str

        MGTK_CALL MGTK::MoveTo, tracking_fast_label_pos
        param_call DrawString, tracking_fast_label_str

        jsr     draw_tracking_buttons

        MGTK_CALL MGTK::PaintBits, mouse_tracking_params

        ;; ==============================
        ;; IP Blinking

        MGTK_CALL MGTK::MoveTo, ipblink1_label_pos
        param_call DrawString, ipblink1_label_str

        MGTK_CALL MGTK::MoveTo, ipblink2_label_pos
        param_call DrawString, ipblink2_label_str

        MGTK_CALL MGTK::PaintBits, ipblink_bitmap_params

        MGTK_CALL MGTK::MoveTo, ipblink_slow_label_pos
        param_call DrawString, ipblink_slow_label_str

        MGTK_CALL MGTK::MoveTo, ipblink_fast_label_pos
        param_call DrawString, ipblink_fast_label_str

        jsr     draw_ipblink_buttons

        ;; ==============================
        ;; 12/24 Hour Clock

        MGTK_CALL MGTK::MoveTo, clock_label_pos
        param_call DrawString, clock_label_str

        MGTK_CALL MGTK::MoveTo, clock_12hour_label_pos
        param_call DrawString, clock_12hour_label_str

        MGTK_CALL MGTK::MoveTo, clock_24hour_label_pos
        param_call DrawString, clock_24hour_label_str

        jsr     draw_hour_buttons

        ;; ==============================
        ;; Frame

        MGTK_CALL MGTK::SetPenSize, frame_pensize
        MGTK_CALL MGTK::MoveTo, frame_l1a
        MGTK_CALL MGTK::LineTo, frame_l1b
        MGTK_CALL MGTK::MoveTo, frame_l2a
        MGTK_CALL MGTK::LineTo, frame_l2b
        MGTK_CALL MGTK::MoveTo, frame_l3a
        MGTK_CALL MGTK::LineTo, frame_l3b
        MGTK_CALL MGTK::MoveTo, frame_l4a
        MGTK_CALL MGTK::LineTo, frame_l4b
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

        rts
.endproc


.proc draw_tracking_buttons
        MGTK_CALL MGTK::SetPenMode, notpencopy

        ldax    #tracking_button_rect1
        ldy     SETTINGS + DeskTopSettings::mouse_tracking
        cpy     #0
        jsr     draw_radio_button

        ldax    #tracking_button_rect2
        ldy     SETTINGS + DeskTopSettings::mouse_tracking
        cpy     #1
        jsr     draw_radio_button

        rts
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

.proc draw_hour_buttons
        MGTK_CALL MGTK::SetPenMode, notpencopy

        ldax    #rect_12hour
        ldy     SETTINGS + DeskTopSettings::clock_24hours
        cpy     #0
        jsr     draw_radio_button

        ldax    #rect_24hour
        ldy     SETTINGS + DeskTopSettings::clock_24hours
        cpy     #$80
        jsr     draw_radio_button

        rts
.endproc

.proc draw_rgb_checkbox
        MGTK_CALL MGTK::SetPenMode, notpencopy

        ldax    #rect_rgb
        ldy     SETTINGS + DeskTopSettings::rgb_color
        cpy     #$80
        jsr     draw_checkbox

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

;;; A,X = pos ptr, Z = checked
.proc draw_checkbox
        ptr := $06

        stax    ptr
        beq     checked

unchecked:
        ldy     #3
:       lda     (ptr),y
        sta     unchecked_cb_params::viewloc,y
        dey
        bpl     :-
        MGTK_CALL MGTK::PaintBits, unchecked_cb_params
        rts

checked:
        ldy     #3
:       lda     (ptr),y
        sta     checked_cb_params::viewloc,y
        dey
        bpl     :-
        MGTK_CALL MGTK::PaintBits, checked_cb_params
        rts
.endproc

;;; ============================================================

;;; Assert: called from a routine that ensures window is onscreen
.proc draw_preview

        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport

        ;; Shift the pattern so that when interpreted as NTSC color it
        ;; displays the same as it would when applied to the desktop.
        kWindowBorderOffset = 3

        ldx     #7
:       copy    pattern,x, rotated_pattern,x
        dex
        bpl     :-

        add16   winfo::viewloc, preview_rect, offset
        lda     offset
        clc
        adc     #kWindowBorderOffset
        and     #$07            ; pattern is 8 bits wide
        tay

loop:
        ldx     #7              ; 8 rows

:       lda     rotated_pattern,x
        cmp     #$80
        rol     rotated_pattern,x
        dex
        bpl     :-

        dey
        bpl     loop

        ;; Draw it

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, rotated_pattern
        MGTK_CALL MGTK::PaintRect, preview_rect

        rts

offset: .word   0

rotated_pattern:
        .res    8
.endproc

;;; ============================================================

        DEFINE_RECT bitrect, 0, 0, 0, 0

;;; Assert: called from a routine that ensures window is onscreen
.proc draw_bits

        ;; Perf: Filling rects is slightly faster than using large pens,
        ;; but 64 draw calls is still slow, ~1s to update fully at 1MHz

        MGTK_CALL MGTK::SetPattern, winfo::pattern

        copy    #0, ypos
        copy16  fatbits_rect::y1, bitrect::y1
        add16   bitrect::y1, #kFatBitHeight-1, bitrect::y2

yloop:  copy    #0, xpos
        copy16  fatbits_rect::x1, bitrect::x1
        add16   bitrect::x1, #kFatBitWidth-1, bitrect::x2
        ldy     ypos
        copy    pattern,y, row

xloop:  ror     row
        bcc     zero
        lda     #MGTK::pencopy
        bpl     store
zero:   lda     #MGTK::notpencopy
store:  sta     mode

        MGTK_CALL MGTK::SetPenMode, mode
        MGTK_CALL MGTK::PaintRect, bitrect

        ;; next x
        inc     xpos
        lda     xpos
        cmp     #8
        IF_NE
        add16   bitrect::x1, #kFatBitWidth, bitrect::x1
        add16   bitrect::x2, #kFatBitWidth, bitrect::x2
        jmp     xloop
        END_IF

        ;; next y
        inc     ypos
        lda     ypos
        cmp     #8
        IF_NE
        add16   bitrect::y1, #kFatBitHeight, bitrect::y1
        add16   bitrect::y2, #kFatBitHeight, bitrect::y2
        jmp     yloop
        END_IF

        rts

xpos:   .byte   0
ypos:   .byte   0
row:    .byte   0

mode:   .byte   0

.endproc


;;; Input: A = set/clear X = x coord, Y = y coord
;;; Assert: called from a routine that ensures window is onscreen
.proc draw_bit
        sta     mode

        stx     bitrect::x1
        sty     bitrect::y1
        lda     #0
        sta     bitrect::x1+1
        sta     bitrect::y1+1

        ldx     #kFatBitWidthShift
:       asl16   bitrect::x1
        dex
        bne     :-

        ldx     #kFatBitHeightShift
:       asl16   bitrect::y1
        dex
        bne     :-

        add16   bitrect::x1, fatbits_rect::x1, bitrect::x1
        add16   bitrect::x1, #kFatBitWidth-1, bitrect::x2
        add16   bitrect::y1, fatbits_rect::y1, bitrect::y1
        add16   bitrect::y1, #kFatBitHeight-1, bitrect::y2

        lda     #MGTK::pencopy
        bit     mode
        bmi     :+
        lda     #MGTK::notpencopy
:       sta     mode

        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::SetPattern, winfo::pattern
        MGTK_CALL MGTK::SetPenMode, mode
        MGTK_CALL MGTK::PaintRect, bitrect

        rts

mode:   .byte   0
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
kPatternCount = 15 + 14 + 1 ; 15 B&W patterns, 14 solid color patterns + 1
patterns:
        .addr pattern_checkerboard, pattern_dark, pattern_vdark, pattern_black
        .addr pattern_olives, pattern_scales, pattern_stripes
        .addr pattern_light, pattern_vlight, pattern_xlight, pattern_white
        .addr pattern_cane, pattern_brick, pattern_curvy, pattern_abrick
        .addr pattern_rainbow
        .addr pattern_c1, pattern_c2, pattern_c3, pattern_c4
        .addr pattern_c5, pattern_c6, pattern_c7, pattern_c8
        .addr pattern_c9, pattern_cA, pattern_cB, pattern_cC
        .addr pattern_cD, pattern_cE
        ASSERT_ADDRESS_TABLE_SIZE patterns, kPatternCount

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

pattern_rainbow:
        .byte   $88     ; red
        .byte   $99     ; magenta
        .byte   $33     ; light blue
        .byte   $00     ; black
        .byte   $00     ; black
        .byte   $22     ; green
        .byte   $EE     ; yellow
        .byte   $CC     ; orange


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

.proc handle_rgb_click
        lda     SETTINGS + DeskTopSettings::rgb_color
        eor     #$80
        sta     SETTINGS + DeskTopSettings::rgb_color

        MGTK_CALL MGTK::HideCursor
        jsr     draw_rgb_checkbox
        MGTK_CALL MGTK::ShowCursor

        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_RGB_MODE
        sta     RAMRDON
        sta     RAMWRTON

        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_hour_click
        sta     SETTINGS + DeskTopSettings::clock_24hours
        MGTK_CALL MGTK::HideCursor
        jsr     draw_hour_buttons
        MGTK_CALL MGTK::ShowCursor
        jmp     input_loop
.endproc

;;; ============================================================
;;; Save Settings

filename:
        PASCAL_STRING kFilenameDeskTopConfig

filename_buffer:
        .res kPathBufferSize

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

done:   rts

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
        param_call JUMP_TABLE_MLI, CREATE, create_params

        param_call JUMP_TABLE_MLI, OPEN, open_params
        bcs     done
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        param_call JUMP_TABLE_MLI, WRITE, write_params
close:  param_call JUMP_TABLE_MLI, CLOSE, close_params
done:   rts
.endproc

.endproc


;;; ============================================================

.proc get_copied_to_ramcard_flag
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2
        lda     COPIED_TO_RAMCARD_FLAG
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts
.endproc

.proc copy_ramcard_prefix
        stax    @addr
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2

        ldx     RAMCARD_PREFIX
:       lda     RAMCARD_PREFIX,x
        @addr := *+1
        sta     SELF_MODIFIED,x
        dex
        bpl     :-

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

.proc copy_desktop_orig_prefix
        stax    @addr
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2

        ldx     DESKTOP_ORIG_PREFIX
:       lda     DESKTOP_ORIG_PREFIX,x
        @addr := *+1
        sta     SELF_MODIFIED,x
        dex
        bpl     :-

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

;;; ============================================================

        .include "../lib/drawstring.s"

;;; ============================================================

da_end  := *
.assert * < WINDOW_ICON_TABLES, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but icon tables start at AUX $1B00

;;; ============================================================
