;;; ============================================================
;;; CONTROL.PANEL - Desk Accessory
;;;
;;; A control panel offering system settings:
;;;   * DeskTop pattern
;;;   * Mouse tracking speed
;;;   * Double-click speed
;;;   * Insertion point blink rate
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

        MGTKEntry := MGTKAuxEntry

;;; ============================================================
;;; Memory map
;;;
;;;               Main            Aux
;;;          :             : :             :
;;;          |             | |             |
;;;          | DHR         | | DHR         |
;;;  $2000   +-------------+ +-------------+
;;;          | IO Buffer   | |Win Tables   |
;;;  $1C00   +-------------+ |             |
;;;          | write_buffer| |             |
;;;  $1B00   +-------------| +-------------+
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
        lda     dialog_result
        sta     RAMRDOFF        ; Back to Main
        sta     RAMWRTOFF

        ;; Save settings if dirty
        jmi     SaveSettings
        rts

.endscope

;;; ============================================================

;;; High bit set when anything changes.
dialog_result:
        .byte   0

.proc MarkDirty
        lda     #$80
        ora     dialog_result
        sta     dialog_result
        rts
.endproc

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
penmode:        .byte   MGTK::pencopy
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
        DEFINE_POINT frame_l2a, 190, 68
        DEFINE_POINT frame_l2b, kDAWidth, 68
        DEFINE_POINT frame_l3a, 190, 0
        DEFINE_POINT frame_l3b, 190, kDAHeight

        DEFINE_RECT frame_rect, AS_WORD(-1), AS_WORD(-1), kDAWidth - 2, kDAHeight


;;; ============================================================

        .include "../lib/event_params.s"

.params trackgoaway_params
clicked:        .byte   0
.endparams

.params winport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams


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

;;; Padding between radio/checkbox and label
kLabelPadding = 5

kRadioButtonWidth       = 15
kRadioButtonHeight      = 7

.params rb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   SELF_MODIFIED
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

.params cb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   SELF_MODIFIED
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

        DEFINE_LABEL rgb_color, res_string_label_rgb_color, kPatternEditX + kCheckboxWidth + 46 + kLabelPadding, kPatternEditY + 59
        ;; for hit testing; label width is added dynamically
        DEFINE_RECT_SZ rect_rgb, kPatternEditX + 46, kPatternEditY + 50, kCheckboxWidth + kLabelPadding, kCheckboxHeight

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

        kNumArrows = 6
arrows_table:
        DEFINE_POINT dblclick_arrow_pos1, kDblClickX + 65, kDblClickY + 7
        DEFINE_POINT dblclick_arrow_pos2, kDblClickX + 65, kDblClickY + 22
        DEFINE_POINT dblclick_arrow_pos3, kDblClickX + 110, kDblClickY + 10
        DEFINE_POINT dblclick_arrow_pos4, kDblClickX + 110, kDblClickY + 22
        DEFINE_POINT dblclick_arrow_pos5, kDblClickX + 155, kDblClickY + 13
        DEFINE_POINT dblclick_arrow_pos6, kDblClickX + 155, kDblClickY + 23
        ASSERT_RECORD_TABLE_SIZE arrows_table, kNumArrows, .sizeof(MGTK::Point)

        ;; for hit testing
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

        DEFINE_LABEL tracking_slow, res_string_label_slow, kMouseTrackingX + 84 + kRadioButtonWidth + kLabelPadding, kMouseTrackingY + 16
        DEFINE_LABEL tracking_fast, res_string_label_fast, kMouseTrackingX + 84 + kRadioButtonWidth + kLabelPadding, kMouseTrackingY + 29
        ;; for hit testing; label width is added dynamically
        DEFINE_RECT_SZ tracking_button_rect1, kMouseTrackingX + 84, kMouseTrackingY + 8, kRadioButtonWidth + kLabelPadding, kRadioButtonHeight
        DEFINE_RECT_SZ tracking_button_rect2, kMouseTrackingX + 84, kMouseTrackingY + 21, kRadioButtonWidth + kLabelPadding, kRadioButtonHeight

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
kIPBlinkDisplayY = 85

        ;; Selected index (1-3, or 0 for 'no match')
ipblink_selection:
        .byte   0

        DEFINE_LABEL ipblink1, res_string_label_ipblink1, kIPBlinkDisplayX-4, kIPBlinkDisplayY + 11
        DEFINE_LABEL ipblink2, res_string_label_ipblink2, kIPBlinkDisplayX-4, kIPBlinkDisplayY + 21
        DEFINE_LABEL ipblink_slow, res_string_label_slow, kIPBlinkDisplayX + 100, kIPBlinkDisplayY + 34
        DEFINE_LABEL ipblink_fast, res_string_label_fast, kIPBlinkDisplayX + 150, kIPBlinkDisplayY + 34
        ;; for hit testing
        DEFINE_RECT_SZ ipblink_btn1_rect, kIPBlinkDisplayX + 116, kIPBlinkDisplayY + 16, kRadioButtonWidth, kRadioButtonHeight
        DEFINE_RECT_SZ ipblink_btn2_rect, kIPBlinkDisplayX + 136, kIPBlinkDisplayY + 16, kRadioButtonWidth, kRadioButtonHeight
        DEFINE_RECT_SZ ipblink_btn3_rect, kIPBlinkDisplayX + 156, kIPBlinkDisplayY + 16, kRadioButtonWidth, kRadioButtonHeight

.params ipblink_bitmap_params
        DEFINE_POINT viewloc, kIPBlinkDisplayX + 123, kIPBlinkDisplayY
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

kIPBmpPosX = kIPBlinkDisplayX + 143
kIPBmpPosY = kIPBlinkDisplayY
kIPBmpWidth  = 2
kIPBmpHeight = 13

.params ipblink_bitmap_ip_params
        DEFINE_POINT viewloc, kIPBmpPosX, kIPBmpPosY
mapbits:        .addr   ipblink_ip_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, kIPBmpWidth - 1, kIPBmpHeight - 1
.endparams

kCursorWidth    = 8
kCursorHeight   = 12
kSlop           = 14            ; Two DHR bytes worth of pixels
        ;; Bounding rect for where the blinking IP and cursor could overlap.
        ;; If the cursor is inside this rect, it is hidden before drawing
        ;; the bitmap.
        DEFINE_RECT_SZ anim_cursor_rect, kIPBmpPosX - kCursorWidth - kSlop,  kIPBmpPosY - kCursorHeight, kCursorWidth + kIPBmpWidth + 2*kSlop, kCursorHeight + kIPBmpHeight
cursor_flag:
        .byte   0


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

.proc Init
        jsr     InitPattern
        jsr     InitIpblink
        jsr     InitDblclick

        param_call MeasureString, rgb_color_label_str
        addax   rect_rgb::x2
        param_call MeasureString, tracking_slow_label_str
        addax   tracking_button_rect1::x2
        param_call MeasureString, tracking_fast_label_str
        addax   tracking_button_rect2::x2

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc

.proc InputLoop
        jsr     DoIPBlink
        jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        .assert MGTK::EventKind::no_event = 0, error, "no_event must be 0"
        beq     HandleMove
        cmp     #MGTK::EventKind::button_down
        beq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        bne     InputLoop       ; always
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

.proc HandleMove
        copy    winfo::window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, anim_cursor_rect
        sta     cursor_flag
        jmp     InputLoop
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
        MGTK_CALL MGTK::FindWindow, findwindow_params
        bne     Exit
        lda     findwindow_params::window_id
        cmp     winfo::window_id
        jne     InputLoop
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
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        bit     dragwindow_params::moved
        bpl     :+

        ;; Draw DeskTop's windows and icons.
        jsr     ClearUpdates

        ;; Draw DA's window
        jsr     DrawWindow

:       jmp     InputLoop

.endproc


;;; ============================================================

.proc HandleClick
        copy    winfo::window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        ;; ----------------------------------------

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, fatbits_rect
        cmp     #MGTK::inrect_inside
        jeq     HandleBitsClick

        MGTK_CALL MGTK::InRect, larr_rect
        cmp     #MGTK::inrect_inside
        jeq     HandleLArrClick

        MGTK_CALL MGTK::InRect, rarr_rect
        cmp     #MGTK::inrect_inside
        jeq     HandleRArrClick

        MGTK_CALL MGTK::InRect, preview_rect
        cmp     #MGTK::inrect_inside
        jeq     HandlePatternClick

        MGTK_CALL MGTK::InRect, rect_rgb
        cmp     #MGTK::inrect_inside
        jeq     HandleRGBClick

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, dblclick_button_rect1
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #1
        jmp     HandleDblclickClick
        END_IF

        MGTK_CALL MGTK::InRect, dblclick_button_rect2
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #2
        jmp     HandleDblclickClick
        END_IF

        MGTK_CALL MGTK::InRect, dblclick_button_rect3
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #3
        jmp     HandleDblclickClick
        END_IF

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, tracking_button_rect1
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #0
        jmp     HandleTrackingClick
        END_IF

        MGTK_CALL MGTK::InRect, tracking_button_rect2
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #1
        jmp     HandleTrackingClick
        END_IF

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, ipblink_btn1_rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #1
        jmp     HandleIpblinkClick
        END_IF

        MGTK_CALL MGTK::InRect, ipblink_btn2_rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #2
        jmp     HandleIpblinkClick
        END_IF

        MGTK_CALL MGTK::InRect, ipblink_btn3_rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #3
        jmp     HandleIpblinkClick
        END_IF

        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleRArrClick
        inc     pattern_index

        lda     pattern_index
        cmp     #kPatternCount
        IF_GE
        copy    #0, pattern_index
        END_IF

        jmp     UpdatePattern
.endproc

.proc HandleLArrClick
        dec     pattern_index

        IF_NEG
        copy    #kPatternCount-1, pattern_index
        END_IF

        jmp     UpdatePattern
.endproc

.proc UpdatePattern
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

        jsr     DrawPreview
        jsr     UpdateBits
        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleBitsClick

        ;; Determine sense flag (0=clear, $FF=set)
        jsr     MapCoords
        ldx     screentowindow_params::windowx
        ldy     screentowindow_params::windowy

        stx     lastx
        sty     lasty

        lda     pattern,y
        and     mask1,x
        beq     :+
        lda     #0
        beq     @store          ; always
:       lda     #$FF
@store: sta     flag

        ;; Toggle pattern bit
loop:   ldx     screentowindow_params::windowx
        ldy     screentowindow_params::windowy
        lda     pattern,y
        bit     flag
        bpl     :+
        ora     mask1,x         ; set bit
        jmp     @store
:       and     mask2,x         ; clear bit
@store: cmp     pattern,y       ; did it change?
        beq     event
        sta     pattern,y

        ldx     screentowindow_params::windowx
        ldy     screentowindow_params::windowy
        lda     flag
        jsr     DrawBit

        jsr     DrawPreview

        ;; Repeat until mouse-up
event:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        jeq     InputLoop

        copy    winfo::window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, fatbits_rect
        cmp     #MGTK::inrect_inside
        bne     event

        jsr     MapCoords
        ldx     screentowindow_params::windowx
        ldy     screentowindow_params::windowy
        cpx     lastx
        bne     moved
        cpy     lasty
        beq     event

moved:  stx     lastx
        sty     lasty
        jmp     loop

mask1:  .byte   1<<0, 1<<1, 1<<2, 1<<3, 1<<4, 1<<5, 1<<6, 1<<7
mask2:  .byte   AS_BYTE(~(1<<0)), AS_BYTE(~(1<<1)), AS_BYTE(~(1<<2)), AS_BYTE(~(1<<3)), AS_BYTE(~(1<<4)), AS_BYTE(~(1<<5)), AS_BYTE(~(1<<6)), AS_BYTE(~(1<<7))

flag:   .byte   0

lastx:  .byte   0
lasty:  .byte   0
.endproc

;;; Assumes click is within fatbits_rect
.proc MapCoords
        sub16   screentowindow_params::windowx, fatbits_rect::x1, screentowindow_params::windowx
        sub16   screentowindow_params::windowy, fatbits_rect::y1, screentowindow_params::windowy

        ldy     #kFatBitWidthShift
:       lsr16   screentowindow_params::windowx
        dey
        bne     :-

        ldy     #kFatBitHeightShift
:       lsr16   screentowindow_params::windowy
        dey
        bne     :-

        rts
.endproc

.proc UpdateBits
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor
        jsr     DrawBits
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

.proc InitDblclick
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

.proc HandleDblclickClick
        sta     dblclick_selection ; 1, 2 or 3
        asl                     ; *= 2
        tax
        dex
        dex                     ; 0, 2 or 4

        copy16  dblclick_speed_table,x, SETTINGS + DeskTopSettings::dblclick_speed
        jsr     MarkDirty

        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor
        jsr     DrawDblclickButtons
        MGTK_CALL MGTK::ShowCursor
        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleTrackingClick
        ;; --------------------------------------------------
        ;; Update Settings

        sta     SETTINGS + DeskTopSettings::mouse_tracking
        jsr     MarkDirty

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

        MGTK_CALL MGTK::ScaleMouse, scalemouse_params

        ;; Set the cursor to the same position (c/o click event),
        ;; to avoid it warping due to the scale change.
        copy    #MGTK::EventKind::no_event, event_kind
        MGTK_CALL MGTK::PostEvent, event_params

        ;; --------------------------------------------------
        ;; Update the UI

        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor
        jsr     DrawTrackingButtons
        MGTK_CALL MGTK::ShowCursor

        jmp     InputLoop
.endproc

;;; ============================================================


.proc InitPattern
        ptr := $06

        MGTK_CALL MGTK::GetDeskPat, ptr
        ldy     #.sizeof(MGTK::Pattern)-1
:       lda     (ptr),y
        sta     pattern,y
        dey
        bpl     :-
        rts
.endproc

.proc HandlePatternClick
        MGTK_CALL MGTK::SetDeskPat, pattern
        COPY_STRUCT MGTK::Pattern, pattern, SETTINGS + DeskTopSettings::pattern
        jsr     MarkDirty

        MGTK_CALL MGTK::RedrawDeskTop

        ;; Draw DeskTop's windows and icons.
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_CLEAR_UPDATES
        sta     RAMRDON
        sta     RAMWRTON

        ;; Draw DA's window
        jsr     DrawWindow

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

        jsr     DrawPreview
        jsr     DrawBits

        MGTK_CALL MGTK::SetPenMode, notpencopy

        MGTK_CALL MGTK::MoveTo, rgb_color_label_pos
        param_call DrawString, rgb_color_label_str

        jsr     DrawRGBCheckbox

        ;; ==============================
        ;; Double-Click Speed

        MGTK_CALL MGTK::MoveTo, dblclick_speed_label_pos
        param_call DrawString, dblclick_speed_label_str


        ;; Arrows
.scope
        copy    #0, arrow_num
        copy16  #arrows_table, addr

loop:   ldy     #3
        addr := *+1
:       lda     SELF_MODIFIED,y
        sta     darrow_params::viewloc,y
        dey
        bpl     :-

        MGTK_CALL MGTK::PaintBits, darrow_params
        add16_8 addr, #.sizeof(MGTK::Point)
        inc     arrow_num
        lda     arrow_num
        cmp     #kNumArrows
        bne     loop
.endscope


        jsr     DrawDblclickButtons

        MGTK_CALL MGTK::PaintBits, dblclick_params

        ;; ==============================
        ;; Mouse Tracking Speed

        MGTK_CALL MGTK::MoveTo, mouse_tracking_label_pos
        param_call DrawString, mouse_tracking_label_str

        MGTK_CALL MGTK::MoveTo, tracking_slow_label_pos
        param_call DrawString, tracking_slow_label_str

        MGTK_CALL MGTK::MoveTo, tracking_fast_label_pos
        param_call DrawString, tracking_fast_label_str

        jsr     DrawTrackingButtons

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

        jsr     DrawIpblinkButtons

        ;; ==============================
        ;; Frame

        MGTK_CALL MGTK::SetPenSize, frame_pensize
        MGTK_CALL MGTK::MoveTo, frame_l1a
        MGTK_CALL MGTK::LineTo, frame_l1b
        MGTK_CALL MGTK::MoveTo, frame_l2a
        MGTK_CALL MGTK::LineTo, frame_l2b
        MGTK_CALL MGTK::MoveTo, frame_l3a
        MGTK_CALL MGTK::LineTo, frame_l3b
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, winfo::penwidth

done:   MGTK_CALL MGTK::ShowCursor
        rts

arrow_num:
        .byte   0

.endproc

.proc DrawDblclickButtons
        MGTK_CALL MGTK::SetPenMode, notpencopy

        ldax    #dblclick_button_rect1
        ldy     dblclick_selection
        cpy     #1
        jsr     DrawRadioButton

        ldax    #dblclick_button_rect2
        ldy     dblclick_selection
        cpy     #2
        jsr     DrawRadioButton

        ldax    #dblclick_button_rect3
        ldy     dblclick_selection
        cpy     #3
        jsr     DrawRadioButton

        rts
.endproc


.proc DrawTrackingButtons
        MGTK_CALL MGTK::SetPenMode, notpencopy

        ldax    #tracking_button_rect1
        ldy     SETTINGS + DeskTopSettings::mouse_tracking
        cpy     #0
        jsr     DrawRadioButton

        ldax    #tracking_button_rect2
        ldy     SETTINGS + DeskTopSettings::mouse_tracking
        cpy     #1
        jsr     DrawRadioButton

        rts
.endproc


.proc DrawIpblinkButtons
        MGTK_CALL MGTK::SetPenMode, notpencopy

        ldax    #ipblink_btn1_rect
        ldy     ipblink_selection
        cpy     #1
        jsr     DrawRadioButton

        ldax    #ipblink_btn2_rect
        ldy     ipblink_selection
        cpy     #2
        jsr     DrawRadioButton

        ldax    #ipblink_btn3_rect
        ldy     ipblink_selection
        cpy     #3
        jsr     DrawRadioButton

        rts
.endproc

.proc DrawRGBCheckbox
        MGTK_CALL MGTK::SetPenMode, notpencopy

        ldax    #rect_rgb
        ldy     SETTINGS + DeskTopSettings::rgb_color
        cpy     #$80
        jsr     DrawCheckbox

        rts
.endproc


;;; A,X = pos ptr, Z = checked
.proc DrawRadioButton
        ptr := $06

        stax    ptr

    IF_EQ
        copy16  #checked_rb_bitmap, rb_params::mapbits
    ELSE
        copy16  #unchecked_rb_bitmap, rb_params::mapbits
    END_IF

        ldy     #3
:       lda     (ptr),y
        sta     rb_params::viewloc,y
        dey
        bpl     :-

        MGTK_CALL MGTK::PaintBits, rb_params
        rts
.endproc

;;; A,X = pos ptr, Z = checked
.proc DrawCheckbox
        ptr := $06

        stax    ptr

    IF_EQ
        copy16  #checked_cb_bitmap, cb_params::mapbits
    ELSE
        copy16  #unchecked_cb_bitmap, cb_params::mapbits
    END_IF

        ldy     #3
:       lda     (ptr),y
        sta     cb_params::viewloc,y
        dey
        bpl     :-

        MGTK_CALL MGTK::PaintBits, cb_params
        rts
.endproc

;;; ============================================================

;;; Assert: called from a routine that ensures window is onscreen
.proc DrawPreview

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
.proc DrawBits

        ;; Perf: Filling rects is slightly faster than using large pens,
        ;; but 64 draw calls is still slow, ~1s to update fully at 1MHz

        MGTK_CALL MGTK::SetPattern, winfo::pattern

        copy    #0, ypos
        copy16  fatbits_rect::y1, bitrect::y1
        add16_8 bitrect::y1, #kFatBitHeight-1, bitrect::y2

yloop:  copy    #0, xpos
        copy16  fatbits_rect::x1, bitrect::x1
        add16_8 bitrect::x1, #kFatBitWidth-1, bitrect::x2
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
        add16_8 bitrect::x1, #kFatBitWidth
        add16_8 bitrect::x2, #kFatBitWidth
        jmp     xloop
        END_IF

        ;; next y
        inc     ypos
        lda     ypos
        cmp     #8
        IF_NE
        add16_8 bitrect::y1, #kFatBitHeight
        add16_8 bitrect::y2, #kFatBitHeight
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
.proc DrawBit
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
        add16_8 bitrect::x1, #kFatBitWidth-1, bitrect::x2
        add16   bitrect::y1, fatbits_rect::y1, bitrect::y1
        add16_8 bitrect::y1, #kFatBitHeight-1, bitrect::y2

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

;;; The index of the pattern in the table below. We start with -1
;;; representing the current desktop pattern; either incrementing
;;; to 0 or decrementing (to a negative and wrapping) will start
;;; iterating through the table.
pattern_index:  .byte   AS_BYTE(-1)

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
        .word   kDefaultIPBlinkSpeed * 2
        .word   kDefaultIPBlinkSpeed * 1
        .word   kDefaultIPBlinkSpeed * 1/2

ipblink_counter:
        .word   kDefaultIPBlinkSpeed

.proc InitIpblink
        ;; Find matching index in word table, or 0
        ldx     #kIPBlinkSpeedTableSize * 2
loop:   lda     SETTINGS + DeskTopSettings::ip_blink_speed
        cmp     ipblink_speed_table-2,x
        bne     next
        lda     SETTINGS + DeskTopSettings::ip_blink_speed+1
        cmp     ipblink_speed_table-2+1,x
        bne     next
        ;; Found a match
        txa
        lsr                     ; /= 2
        sta     ipblink_selection
        rts

next:   dex
        dex
        bpl     loop
        copy    #0, ipblink_selection ; not found
        rts
.endproc

.proc HandleIpblinkClick
        sta     ipblink_selection ; 1, 2 or 3
        asl                     ; *= 2
        tax
        dex
        dex                     ; 0, 2 or 4

        copy16  ipblink_speed_table,x, SETTINGS + DeskTopSettings::ip_blink_speed
        jsr     MarkDirty
        jsr     ResetIPBlinkCounter

        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor
        jsr     DrawIpblinkButtons
        MGTK_CALL MGTK::ShowCursor
        jmp     InputLoop
.endproc

.proc ResetIPBlinkCounter
        copy16  SETTINGS + DeskTopSettings::ip_blink_speed, ipblink_counter
        ;; Scale it because it's much slower in the DA than in DeskTop
        ;; prompts, due to more hit testing, etc.  1/2 speed seems okay.
        lsr16   ipblink_counter
        rts
.endproc


.proc DoIPBlink
        dec16   ipblink_counter
        lda     ipblink_counter
        ora     ipblink_counter+1
        bne     done

        jsr     ResetIPBlinkCounter

        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        beq     done

        bit     cursor_flag
        bpl     :+
        MGTK_CALL MGTK::HideCursor
:
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintBits, ipblink_bitmap_ip_params

        bit     cursor_flag
        bpl     :+
        MGTK_CALL MGTK::ShowCursor
:

done:   rts

.endproc

;;; ============================================================

.proc HandleRGBClick
        lda     SETTINGS + DeskTopSettings::rgb_color
        eor     #$80
        sta     SETTINGS + DeskTopSettings::rgb_color
        jsr     MarkDirty

        MGTK_CALL MGTK::HideCursor
        jsr     DrawRGBCheckbox
        MGTK_CALL MGTK::ShowCursor

        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_RGB_MODE
        sta     RAMRDON
        sta     RAMWRTON

        jmp     InputLoop
.endproc

;;; ============================================================

        .include "../lib/save_settings.s"
        .include "../lib/drawstring.s"
        .include "../lib/measurestring.s"

;;; ============================================================

da_end  := *
.assert * < WINDOW_ENTRY_TABLES, error, .sprintf("DA too big (at $%X)", *)
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00

;;; ============================================================
