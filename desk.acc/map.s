;;; ============================================================
;;; MAP - Desk Accessory
;;;
;;; A simple world map
;;; ============================================================

;;; TODO:
;;; * Current location indicator on map
;;; * Searchable city database

        .include "../config.inc"
        RESOURCE_FILE "map.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry

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

kMapLeft = 6
kMapTop = 4
kMapWidth = 175
kMapHeight = 46

        DEFINE_RECT_SZ frame_rect, kMapLeft - 2, kMapTop - 2, kMapWidth + 3, kMapHeight + 3
        DEFINE_RECT_SZ map_rect, kMapLeft, kMapTop, kMapWidth, kMapHeight

kLabelLeft = 20
kValueLeft = 110
kRow1Baseline = kMapHeight + kSystemFontHeight + 10
kRow2Baseline = kRow1Baseline + kSystemFontHeight + 4

        DEFINE_LABEL lat, res_string_latitude, kLabelLeft, kRow1Baseline
        DEFINE_POINT pos_lat, kValueLeft, kRow1Baseline
        DEFINE_LABEL long, res_string_longitude, kLabelLeft, kRow2Baseline
        DEFINE_POINT pos_long, kValueLeft, kRow2Baseline

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
kDAWidth        = kMapWidth + 11
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
port:           .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort

.params trackgoaway_params
clicked:        .byte   0
.endparams

;;; ============================================================

lat:    .word   0
long:   .word   0
s_flag: .byte   0
w_flag: .byte   0

;;; ============================================================

.proc Init
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
        jmp     ClearUpdates
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
        copy    #kDAWindowId, dragwindow_params::window_id
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
        copy    #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        ;; Click in map?
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, map_rect
        jeq     done

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
        ldy     #180
        jsr     Multiply_16_8_16
        ldy     #kMapWidth/2
        jsr     Divide_16_8_16
        stax    long
        sub16   long, #180, long

        ;; Make positive, set flags
        lda     #0
        sta     s_flag
        sta     w_flag

        bit     lat+1
    IF_NS
        copy    #$80, s_flag
        sub16   #0, lat, lat
    END_IF

        bit     long+1
    IF_NS
        copy    #$80, w_flag
        sub16   #0, long, long
    END_IF

        jsr     DrawLatLong

done:   jmp     InputLoop

.endproc

;;; ============================================================

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy

;;; ============================================================

.proc DrawWindow
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        IF_EQ
        rts
        END_IF

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        ;; ==============================

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::PaintBits, map_params

        MGTK_CALL MGTK::MoveTo, lat_label_pos
        param_call DrawString, lat_label_str
        MGTK_CALL MGTK::MoveTo, long_label_pos
        param_call DrawString, long_label_str

        jsr     DrawLatLong

        ;; ==============================

        MGTK_CALL MGTK::ShowCursor
        rts

.endproc

;;; ============================================================

.proc DrawLatLong

        ldax    lat
        jsr     IntToString
        MGTK_CALL MGTK::MoveTo, pos_lat
        param_call DrawString, str_from_int
        param_call DrawString, str_degree_suffix
        bit     s_flag
    IF_NC
        param_call DrawString, str_n
    ELSE
        param_call DrawString, str_s
    END_IF
        param_call DrawString, str_spaces

        ldax    long
        jsr     IntToString
        MGTK_CALL MGTK::MoveTo, pos_long
        param_call DrawString, str_from_int
        param_call DrawString, str_degree_suffix
        bit     w_flag
    IF_NC
        param_call DrawString, str_e
    ELSE
        param_call DrawString, str_w
    END_IF
        param_call DrawString, str_spaces

        rts
.endproc

;;; ============================================================

        .include "../lib/drawstring.s"
        .include "../lib/inttostring.s"
        .include "../lib/muldiv.s"

;;; ============================================================

da_end  := *
.assert * < WINDOW_ENTRY_TABLES, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00

;;; ============================================================
