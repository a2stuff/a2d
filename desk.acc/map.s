;;; ============================================================
;;; MAP - Desk Accessory
;;;
;;; A simple world map
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "map.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../letk/letk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry
        LETKEntry := LETKAuxEntry

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
;;; Resources

kMapLeft = 10
kMapTop = 5
kMapWidth = 175
kMapHeight = 46

pensize_normal: .byte   1, 1
pensize_frame:  .byte   2, 1

        DEFINE_RECT_SZ frame_rect, kMapLeft - 4, kMapTop - 2, kMapWidth + 6, kMapHeight + 3
        DEFINE_RECT_SZ map_rect, kMapLeft, kMapTop, kMapWidth, kMapHeight

kControlsLeft = 6

kRow1 = kMapTop + kMapHeight + 6
kRow2 = kRow1 + kTextBoxHeight + 4
kRow3 = kRow2 + kSystemFontHeight + 4

kTextBoxLeft = kControlsLeft
kTextBoxTop = kRow1
kTextBoxWidth = 7 * 15 + 2 * kTextBoxTextHOffset
        DEFINE_RECT_SZ input_rect, kTextBoxLeft, kTextBoxTop, kTextBoxWidth, kTextBoxHeight
        DEFINE_BUTTON find, res_string_button_find, kTextBoxLeft + kTextBoxWidth + 5, kTextBoxTop, 62

kLabelLeft = kControlsLeft + kTextBoxTextHOffset
kValueLeft = 80
        DEFINE_LABEL lat, res_string_latitude, kLabelLeft, kRow2 + kSystemFontHeight
        DEFINE_POINT pos_lat, kValueLeft, kRow2 + kSystemFontHeight
        DEFINE_LABEL long, res_string_longitude, kLabelLeft, kRow3 + kSystemFontHeight
        DEFINE_POINT pos_long, kValueLeft, kRow3 + kSystemFontHeight


str_spaces:
        PASCAL_STRING "      "
str_degree_suffix:
        PASCAL_STRING {kGlyphDegreeSign, " "}
str_n:  PASCAL_STRING res_string_dir_n
str_s:  PASCAL_STRING res_string_dir_s
str_e:  PASCAL_STRING res_string_dir_e
str_w:  PASCAL_STRING res_string_dir_w

.params map_params
        DEFINE_POINT viewloc, kMapLeft, kMapTop
mapbits:        .addr   map_bitmap
mapwidth:       .byte   25
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kMapWidth-1, kMapHeight-1
.endparams

map_bitmap:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1111111),PX(%1111110),PX(%0111111),PX(%1111111),PX(%1111111),PX(%1110000),PX(%0000000),PX(%0001111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1111000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011110),PX(%0001111),PX(%1111111),PX(%1000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1111111),PX(%1001111),PX(%1011111),PX(%1100000),PX(%0000011),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000),PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000),PX(%0111111),PX(%1000000),PX(%0000000)
        .byte   PX(%1100000),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0011111),PX(%1110011),PX(%1101110),PX(%0011100),PX(%0000000),PX(%1111111),PX(%1111000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%1111110),PX(%0000011),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000),PX(%0011111),PX(%1000001),PX(%1111110),PX(%0000001),PX(%1110000),PX(%0000000),PX(%0011110),PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%0000001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0111000),PX(%0000000),PX(%0111000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1111100),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1100011),PX(%1111000)
        .byte   PX(%0000000),PX(%0011100),PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0111111),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0110000),PX(%0101100),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0001110),PX(%0000000)
        .byte   PX(%0000100),PX(%1100000),PX(%0000000),PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100),PX(%1111111),PX(%1111000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0111001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000),PX(%0001100),PX(%0100100)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0001100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1101000),PX(%0000000),PX(%0000001)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1111111),PX(%1111111),PX(%1000011),PX(%1111111),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1111111),PX(%1111111),PX(%1110111),PX(%1111000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1111100),PX(%0011001),PX(%1111000),PX(%0001110),PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000),PX(%0011100),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1110000),PX(%0000100),PX(%1001111),PX(%1111110),PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0110000),PX(%0110000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1100000),PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0011011),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1111111),PX(%1111110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000101),PX(%1111100),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%1111111),PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000010),PX(%1010000),PX(%0000000),PX(%0000000),PX(%0000010),PX(%0111100),PX(%0000011),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0111111),PX(%1111000),PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011110),PX(%0110000),PX(%0111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1011111),PX(%1110000),PX(%0001111),PX(%1110000),PX(%1111111),PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1100111),PX(%0000000),PX(%0000111),PX(%1000000),PX(%0111111),PX(%1000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0011110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111001),PX(%1000000),PX(%0000011),PX(%0000000),PX(%0010111),PX(%0000000),PX(%1010000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%1111111),PX(%1110000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000),PX(%0100000),PX(%0001000),PX(%0000000),PX(%0110000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0010100),PX(%0001100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1000001),PX(%1111111),PX(%1111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001110),PX(%0111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011111),PX(%1111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0001101),PX(%1000011),PX(%1111000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1100000),PX(%0000000),PX(%0111110),PX(%0010000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0010000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000001),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011111),PX(%1111111),PX(%1111110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011111),PX(%1111111),PX(%1100011),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011111),PX(%0011000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%1111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1111111),PX(%0000110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1111111),PX(%1111100),PX(%0000001),PX(%0000001)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%1111111),PX(%1111000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%1111110),PX(%0000110),PX(%0001000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000010),PX(%0000000),PX(%0000000),PX(%0000111),PX(%1111111),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%1111110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%1111111),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%1111000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%0000000),PX(%1111111),PX(%0000000),PX(%0000100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%1110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001110),PX(%0000000),PX(%0000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001111),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0000000),PX(%0001100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011100),PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0010000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001110),PX(%0000000),PX(%0000001),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011111),PX(%1111111),PX(%1111100),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011111),PX(%1110000),PX(%1111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1100000)
        .byte   PX(%0000000),PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0000000),PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)

;;; ============================================================

str_from_int:   PASCAL_STRING "000,000" ; filled in by IntToString

;;; ============================================================

kDAWindowId     = 61
kDAWidth        = kMapWidth + 19
kDAHeight       = 97
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

        .include "../lib/event_params.s"

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport_win
.endparams

grafport_win:   .tag    MGTK::GrafPort

.params trackgoaway_params
clicked:        .byte   0
.endparams

;;; ============================================================

lat:    .word   0
long:   .word   0

kPositionMarkerWidth = 11
kPositionMarkerHeight = 7
.params position_marker_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   position_marker_bitmap
mapwidth:       .byte   2
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kPositionMarkerWidth-1, kPositionMarkerHeight-1
.endparams

xcoord := position_marker_params::viewloc::xcoord
ycoord := position_marker_params::viewloc::ycoord

position_marker_bitmap:
        .byte   PX(%0000010),PX(%0000000)
        .byte   PX(%0010010),PX(%0100000)
        .byte   PX(%0001000),PX(%1000000)
        .byte   PX(%1110000),PX(%0111000)
        .byte   PX(%0001000),PX(%1000000)
        .byte   PX(%0010010),PX(%0100000)
        .byte   PX(%0000010),PX(%0000000)

;;; ============================================================
;;; Line Edit

cursor_ibeam_flag: .byte   0

kBufSize = 16                       ; max length = 15, length
buf_search:     .res    kBufSize, 0 ; search term

        DEFINE_LINE_EDIT line_edit_rec, kDAWindowId, buf_search, kTextBoxLeft, kTextBoxTop, kTextBoxWidth, kBufSize - 1
        DEFINE_LINE_EDIT_PARAMS le_params, line_edit_rec

;;; ============================================================

.proc Init
        copy    #0, buf_search

        MGTK_CALL MGTK::OpenWindow, winfo
        LETK_CALL LETK::Init, le_params
        jsr     UpdateCoordsFromLatLong
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        LETK_CALL LETK::Activate, le_params
        FALL_THROUGH_TO InputLoop
.endproc

.proc InputLoop
        LETK_CALL LETK::Idle, le_params
        param_call JTRelay, JUMP_TABLE_YIELD_LOOP
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey
        cmp     #MGTK::EventKind::no_event
        bne     InputLoop
        jsr     CheckMouseMoved
        bcc     InputLoop
        jmp     HandleMouseMove
.endproc

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo
        param_jump JTRelay, JUMP_TABLE_CLEAR_UPDATES
.endproc

;;; ============================================================

.proc HandleKey
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     Exit

        cmp     #CHAR_RETURN
    IF_EQ
        param_call ButtonFlash, kDAWindowId, find_button_rect
        jsr     DoFind
        jmp     InputLoop
    END_IF

        copy    event_params::key, le_params::key
        copy    event_params::modifiers, le_params::modifiers
        LETK_CALL LETK::Key, le_params
        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     winfo::window_id
        bne     InputLoop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        beq     HandleDrag
        cmp     #MGTK::Area::content
        jeq     HandleClick
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
        copy    #kDAWindowId, dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        bit     dragwindow_params::moved
        bpl     :+

        ;; Force DA onscreen (to keep line edit control visible)
        bit     winfo::viewloc::xcoord+1
    IF_NS
        copy16  #0, winfo::viewloc::xcoord
    END_IF

        cmp16   winfo::viewloc::xcoord, #kScreenWidth - kDAWidth
    IF_CS
        copy16  #kScreenWidth - kDAWidth, winfo::viewloc::xcoord
    END_IF

        cmp16   winfo::viewloc::ycoord, #kScreenHeight - kDAHeight
    IF_CS
        copy16  #kScreenHeight - kDAHeight, winfo::viewloc::ycoord
    END_IF

        ;; Draw DeskTop's windows and icons.
        param_call JTRelay, JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow

        LETK_CALL LETK::Update, le_params ; window moved

:       jmp     InputLoop

.endproc

;;; ============================================================

.proc DoFind
        ptr := $06

        ;; Erase old position
        jsr     SetPort
    IF_EQ
        jsr     DrawPositionIndicator
    END_IF

        copy16  #location_table, ptr
        copy    #0, index

loop:
        ;; Compare lengths
        ldy     #0
        lda     (ptr),y
        cmp     buf_search
        bne     next

        tay
cloop:  lda     (ptr),y
        jsr     ToUpperCase
        sta     @char
        lda     buf_search,y
        jsr     ToUpperCase
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     next
        dey
        bne     cloop

        ;; Match!
        ldy     #0
        lda     (ptr),y
        tay
        iny                  ; past end of string
        ldx     #0           ; copy next 4 bytes into `lat` and `long`
:       lda     (ptr),y
        sta     lat,x
        iny
        inx
        cpx     #4
        bne     :-

        jmp     done

        ;; Advance pointer to next record
next:   inc     index
        lda     index
        cmp     #kNumLocations
        beq     fail

        ldy     #0              ; string length
        lda     (ptr),y
        clc
        adc     #1+4            ; size of length byte + coords
        clc
        adc     ptr
        sta     ptr
        bcc     :+
        inc     ptr+1
:
        jmp     loop



fail:   param_call JTRelay, JUMP_TABLE_BELL

done:   ;; Update display
        jsr     SetPort
    IF_EQ
        jsr     DrawLatLong
    END_IF
        rts


index:  .byte   0
.endproc

;;; ============================================================

.proc ToUpperCase
        cmp     #'a'
        bcc     ret
        cmp     #'z'+1
        bcs     ret
        and     #CASE_MASK
ret:    rts
.endproc



;;; ============================================================

.proc HandleClick
        copy    #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; Click in button?
        MGTK_CALL MGTK::InRect, find_button_rect
    IF_NE
        param_call ButtonClick, kDAWindowId, find_button_rect
        bmi     :+
        jsr     DoFind
:       jmp     done
    END_IF

        ;; Click in line edit?
        MGTK_CALL MGTK::InRect, input_rect
    IF_NE
        COPY_STRUCT MGTK::Point, screentowindow_params::window, le_params::coords
        LETK_CALL LETK::Click, le_params
        jmp     done
    END_IF

        ;; Click in map?
        MGTK_CALL MGTK::InRect, map_rect
        jeq     done            ; nope

        ;; Erase old position
        jsr     SetPort
    IF_EQ
        jsr     DrawPositionIndicator
    END_IF

        ;; Compute new position
        sub16   screentowindow_params::windowx, #kMapLeft+1, long
        sub16   screentowindow_params::windowy, #kMapTop, lat

        ;; Map latitude to +90...-90
        ldax    lat
        ldy     #180
        jsr     Multiply_16_8_16
        ldy     #kMapHeight
        jsr     Divide_16_8_16
        stax    lat
        sub16   #90, lat, lat

        ;; Map longitude to -180...+180
        ldax    long
        ldy     #360/2
        jsr     Multiply_16_8_16
        ldy     #kMapWidth/2
        jsr     Divide_16_8_16
        stax    long
        sub16   long, #180, long

        ;; Update display
        jsr     SetPort
    IF_EQ
        jsr     DrawLatLong
    END_IF

done:   jmp     InputLoop
.endproc

;;; ============================================================

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy

;;; ============================================================
;;; Output: Z=1 if ok, Z=0 / A = MGTK::Error on errr

.proc SetPort
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     ret
        MGTK_CALL MGTK::SetPort, grafport_win
ret:    rts
.endproc

;;; ============================================================
;;; Determine if mouse moved (returns w/ carry set if moved)
;;; Used in dialogs to possibly change cursor

.proc CheckMouseMoved
        ldx     #.sizeof(MGTK::Point)-1
:       lda     event_params::coords,x
        cmp     coords,x
        bne     diff
        dex
        bpl     :-
        clc
        rts

diff:   COPY_STRUCT MGTK::Point, event_params::coords, coords
        sec
        rts

        DEFINE_POINT coords, 0, 0
.endproc

;;; ============================================================

.proc HandleMouseMove
        copy    #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, input_rect
        cmp     #MGTK::inrect_inside
        beq     inside

outside:
        bit     cursor_ibeam_flag
        bpl     done
        copy    #0, cursor_ibeam_flag
        param_call JTRelay, JUMP_TABLE_CUR_POINTER
        jmp     done

inside:
        bit     cursor_ibeam_flag
        bmi     done
        copy    #$80, cursor_ibeam_flag
        param_call JTRelay, JUMP_TABLE_CUR_IBEAM

done:   jmp     InputLoop
.endproc

;;; ============================================================

.proc DrawWindow
        ;; Defer if content area is not visible
        jsr     SetPort
        bne     ret

        MGTK_CALL MGTK::HideCursor

        ;; ==============================

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal
        MGTK_CALL MGTK::PaintBits, map_params

        MGTK_CALL MGTK::MoveTo, lat_label_pos
        param_call DrawString, lat_label_str
        MGTK_CALL MGTK::MoveTo, long_label_pos
        param_call DrawString, long_label_str

        jsr     DrawLatLong

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, find_button_rect
        MGTK_CALL MGTK::MoveTo, find_button_pos
        param_call DrawString, find_button_label


        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, input_rect

        ;; ==============================

        MGTK_CALL MGTK::ShowCursor

ret:    rts

.endproc

;;; ============================================================
;;; Assert: Correct GrafPort selected

.proc DrawLatLong
        ;; Latitude
        copy16  lat, tmp
        copy    #0, sflag
        bit     tmp+1
    IF_NS
        copy    #$80, sflag
        sub16   #0, tmp, tmp
    END_IF

        ldax    tmp
        jsr     IntToString
        MGTK_CALL MGTK::MoveTo, pos_lat
        param_call DrawString, str_from_int
        param_call DrawString, str_degree_suffix
        bit     sflag
    IF_NC
        param_call DrawString, str_n
    ELSE
        param_call DrawString, str_s
    END_IF
        param_call DrawString, str_spaces

        ;; Longitude
        copy16  long, tmp
        copy    #0, sflag
        bit     tmp+1
    IF_NS
        copy    #$80, sflag
        sub16   #0, tmp, tmp
    END_IF

        ldax    tmp
        jsr     IntToString
        MGTK_CALL MGTK::MoveTo, pos_long
        param_call DrawString, str_from_int
        param_call DrawString, str_degree_suffix
        bit     sflag
    IF_NC
        param_call DrawString, str_e
    ELSE
        param_call DrawString, str_w
    END_IF
        param_call DrawString, str_spaces

        jsr     UpdateCoordsFromLatLong
        jmp     DrawPositionIndicator

tmp:    .word   0
sflag:  .byte   0
.endproc

;;; ============================================================
;;; Assert: Correct GrafPort selected
;;; Assert: `UpdateCoordsFromLatLong` has been called

.proc DrawPositionIndicator
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::PaintBits, position_marker_params
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

.proc UpdateCoordsFromLatLong
        ;; Map latitude from +90...-90
        sub16   #90, lat, ycoord ; 90...-90 to 0...180
        ldax    ycoord
        ldy     #kMapHeight
        jsr     Multiply_16_8_16
        ldy     #180
        jsr     Divide_16_8_16
        stax    ycoord

        ;; Map longitude from -180...+180
        add16   long, #180, xcoord ; -180...180 to 0...360
        ldax    xcoord
        ldy     #kMapWidth/2
        jsr     Multiply_16_8_16
        ldy     #360/2
        jsr     Divide_16_8_16
        stax    xcoord

        add16   xcoord, #kMapLeft+1 - (kPositionMarkerWidth/2), xcoord
        add16   ycoord, #kMapTop    - (kPositionMarkerHeight/2), ycoord
        rts
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

        .include "../lib/drawstring.s"
        .include "../lib/inttostring.s"
        .include "../lib/muldiv.s"
        .include "../lib/button.s"

;;; ============================================================

        loc_count .set 0
.macro DEFINE_LOCATION name, lat, long
        PASCAL_STRING name
        .word   AS_WORD(lat)
        .word   AS_WORD(long)
        loc_count .set loc_count+1
.endmacro

location_table:
        DEFINE_LOCATION "Abidjan", 5, -4
        DEFINE_LOCATION "Alexandria", 31, 29
        DEFINE_LOCATION "Auckland", -36, 174
        DEFINE_LOCATION "Bangalore", 12, 77
        DEFINE_LOCATION "Bangkok", 13, 100
        DEFINE_LOCATION "Beijing", 39, 116
        DEFINE_LOCATION "Berlin", 52, 13
        DEFINE_LOCATION "Bogota", 4, -74
        DEFINE_LOCATION "Bucharest", 44, 26
        DEFINE_LOCATION "Buenos Aires", -34, -58
        DEFINE_LOCATION "Cairo", 30, 31
        DEFINE_LOCATION "Cape Town", -33, 18
        DEFINE_LOCATION "Caracas", 10, -66
        DEFINE_LOCATION "Chengdu", 30, 104
        DEFINE_LOCATION "Chennai", 13, 80
        DEFINE_LOCATION "Chicago", 41, -87
        DEFINE_LOCATION "Chongqing", 29, 106
        DEFINE_LOCATION "Cupertino", 37, -122
        DEFINE_LOCATION "Dar es Salaam", -6, 39
        DEFINE_LOCATION "Delhi", 28, 77
        DEFINE_LOCATION "Dhaka", 23, 90
        DEFINE_LOCATION "Guangzhou", 23, 113
        DEFINE_LOCATION "Havana", 23, -82
        DEFINE_LOCATION "Ho Chi Minh", 10, 106
        DEFINE_LOCATION "Hong Kong", 22, 114
        DEFINE_LOCATION "Honolulu", 21, -157
        DEFINE_LOCATION "Houston", 29, -95
        DEFINE_LOCATION "Hyderabad", 17, 78
        DEFINE_LOCATION "Istanbul", 41, 28
        DEFINE_LOCATION "Jakarta", -6, 106
        DEFINE_LOCATION "Johannesburg", -26, 28
        DEFINE_LOCATION "Kansas City", 39, -94
        DEFINE_LOCATION "Karachi", 24, 67
        DEFINE_LOCATION "Khartoum", 15, 32
        DEFINE_LOCATION "Kinshasa", -4, 15
        DEFINE_LOCATION "Kolkata", 22, 88
        DEFINE_LOCATION "Kyiv", 50, 30
        DEFINE_LOCATION "Lagos", 6, 3
        DEFINE_LOCATION "Lahore", 31, 74
        DEFINE_LOCATION "Lima", -12, -77
        DEFINE_LOCATION "Lisbon", 38, -9
        DEFINE_LOCATION "London", 51, 0
        DEFINE_LOCATION "Los Angeles", 34, -118
        DEFINE_LOCATION "Madrid", 40, -3
        DEFINE_LOCATION "Manila", 14, 120
        DEFINE_LOCATION "Mexico City", 19, -99
        DEFINE_LOCATION "Moscow", 55, 37
        DEFINE_LOCATION "Montreal", 45, -73
        DEFINE_LOCATION "Mumbai", 19, 72
        DEFINE_LOCATION "Nagoya", 35, 136
        DEFINE_LOCATION "Nairobi", -1, 36
        DEFINE_LOCATION "New York", 40, -74
        DEFINE_LOCATION "Osaka", 34, 135
        DEFINE_LOCATION "Ottawa", 45, -75
        DEFINE_LOCATION "Papeete", -17, -149
        DEFINE_LOCATION "Paris", 48, 2
        DEFINE_LOCATION "Rio de Janeiro", -22, -43
        DEFINE_LOCATION "Rome", 41, 12
        DEFINE_LOCATION "St Petersburg", 59, 30
        DEFINE_LOCATION "San Francisco", 37, -122
        DEFINE_LOCATION "Santiago", -33, -70
        DEFINE_LOCATION "Sao Paulo", -23, -46
        DEFINE_LOCATION "Seattle", 47, -122
        DEFINE_LOCATION "Seoul", 37, 126
        DEFINE_LOCATION "Shanghai", 31, 121
        DEFINE_LOCATION "Shenzhen", 22, 114
        DEFINE_LOCATION "Singapore", 1, 103
        DEFINE_LOCATION "Suzhou", 31, 120
        DEFINE_LOCATION "Sydney", -33, 151
        DEFINE_LOCATION "Tianjin", 39, 117
        DEFINE_LOCATION "Tehran", 35, 51
        DEFINE_LOCATION "Tokyo", 35, 139
        DEFINE_LOCATION "Toronto", 43, -79
        DEFINE_LOCATION "Vancouver", 49, -123
        DEFINE_LOCATION "Washington", 38, -77
        DEFINE_LOCATION "Xiamen", 24, 118

kNumLocations = loc_count

;;; ============================================================

da_end  := *
.assert * < WINDOW_ENTRY_TABLES, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00

;;; ============================================================
