;;; ============================================================
;;; THIS.APPLE - Desk Accessory
;;;
;;; Displays information about the current computer. The data
;;; shown includes:
;;;    * Model
;;;    * CPU
;;;    * Expanded/RAMWorks Memory
;;;    * ProDOS version
;;;    * Contents of each expansion slot
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "this.apple.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../inc/smartport.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry

;;; ============================================================

;;; Currently there's not enough room for these.
INCLUDE_UNSUPPORTED_MACHINES = 0

kShortcutEasterEgg = res_char_easter_egg_shortcut

;;; ============================================================

        .org DA_LOAD_ADDRESS

da_start:
;;; Some static checks where we can cache the results.
.scope
        jsr     IdentifyModel
        jsr     IdentifyProDOSVersion
        jsr     IdentifyMemory
.endscope

;;; Copy the DA to AUX for easy bank switching
.scope
        copy16  #da_start, STARTLO
        copy16  #da_end, ENDLO
        copy16  #da_start, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
.endscope

.scope
        ;; run the DA (from Aux)
        sta     RAMRDON
        sta     RAMWRTON
        jsr     Init

        ;; tear down/exit (back to Main)
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endscope

;;; ============================================================

kDAWindowId    = 60
kDAWidth        = 400
kDAHeight       = 118
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

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

str_title:
        PASCAL_STRING res_string_window_title ; dialog title

;;; ============================================================

.if INCLUDE_UNSUPPORTED_MACHINES
.params ii_bitmap
        DEFINE_POINT viewloc, 59, 8
mapbits:        .addr   ii_bits
mapwidth:       .byte   8
reserved:       .res    1
        DEFINE_RECT maprect, 0, 0, 50, 18
.endparams

.params iii_bitmap
        DEFINE_POINT viewloc, 57, 5
mapbits:        .addr   iii_bits
mapwidth:       .byte   8
reserved:       .res    1
        DEFINE_RECT maprect, 0, 0, 54, 24
.endparams
.endif

.params iie_bitmap
        DEFINE_POINT viewloc, 59, 5
mapbits:        .addr   iie_bits
mapwidth:       .byte   8
reserved:       .res    1
        DEFINE_RECT maprect, 0, 0, 50, 25
.endparams

.params iic_bitmap
        DEFINE_POINT viewloc, 62, 4
mapbits:        .addr   iic_bits
mapwidth:       .byte   7
reserved:       .res    1
        DEFINE_RECT maprect, 0, 0, 45, 27
.endparams

.params iigs_bitmap
        DEFINE_POINT viewloc, 65, 5
mapbits:        .addr   iigs_bits
mapwidth:       .byte   6
reserved:       .res    1
        DEFINE_RECT maprect, 0, 0, 38, 25
.endparams

.params iie_card_bitmap
        DEFINE_POINT viewloc, 56, 9
mapbits:        .addr   iie_card_bits
mapwidth:       .byte   8
reserved:       .res    1
        DEFINE_RECT maprect, 0, 0, 55, 21
.endparams

.params laser128_bitmap
        DEFINE_POINT viewloc, 60, 4
mapbits:        .addr   laser128_bits
mapwidth:       .byte   7
reserved:       .res    1
        DEFINE_RECT maprect, 0, 0, 47, 29
.endparams

.params ace500_bitmap
        DEFINE_POINT viewloc, 60, 4
mapbits:        .addr   ace500_bits
mapwidth:       .byte   7
reserved:       .res    1
        DEFINE_RECT maprect, 0, 0, 48, 29
.endparams

.params ace2000_bitmap
        DEFINE_POINT viewloc, 60, 7
mapbits:        .addr   ace2000_bits
mapwidth:       .byte   7
reserved:       .res    1
        DEFINE_RECT maprect, 0, 0, 48, 23
.endparams

.if INCLUDE_UNSUPPORTED_MACHINES
ii_bits:
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001111),PX(%1111111),PX(%1111100),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0001100),PX(%1111111),PX(%1111111),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0001100),PX(%1100000),PX(%0000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0001100),PX(%1100111),PX(%1111100),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100000),PX(%0001100),PX(%1100000),PX(%0000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0001100),PX(%1111111),PX(%1111111),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0001100),PX(%1100000),PX(%0000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001111),PX(%1111111),PX(%1111100),PX(%1100111),PX(%1111100),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%1100000),PX(%0000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000011),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1110000),PX(%0000000)
        .byte   PX(%0001110),PX(%0001100),PX(%1100110),PX(%0110011),PX(%0011001),PX(%1001100),PX(%0011100),PX(%0000000)
        .byte   PX(%0111000),PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0000111),PX(%0000000)
        .byte   PX(%1100001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100001),PX(%1000000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%0111000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%0000000)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100),PX(%0000000)

iii_bits:
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0000001),PX(%1000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%1100110),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%1100110),PX(%0000000)
        .byte   PX(%0000001),PX(%1001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%1111111),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1000011),PX(%1111000),PX(%0000000),PX(%0000000),PX(%1111000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0000001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0000000)
        .byte   PX(%0000011),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%0000000)
        .byte   PX(%0001110),PX(%0001100),PX(%1100110),PX(%0110011),PX(%0011000),PX(%0001100),PX(%1100001),PX(%1100000)
        .byte   PX(%0111000),PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110),PX(%0000011),PX(%0011000),PX(%0111000)
        .byte   PX(%1100001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0011001),PX(%1000000),PX(%1100110),PX(%0001100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
.endif

iie_bits:
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1001100),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1000011),PX(%1111111),PX(%1000000),PX(%1111111),PX(%1110000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000011),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1110000),PX(%0000000)
        .byte   PX(%0001110),PX(%0001100),PX(%1100110),PX(%0110011),PX(%0011001),PX(%1001100),PX(%0011100),PX(%0000000)
        .byte   PX(%0111000),PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0000111),PX(%0000000)
        .byte   PX(%1100001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100001),PX(%1000000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%0111000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%0000000)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100),PX(%0000000)

iic_bits:
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0000001),PX(%1001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0000000),PX(%0000001),PX(%1001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0000000)
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0000000),PX(%0000000)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0011001),PX(%0010010),PX(%0100100),PX(%1001001),PX(%0010010),PX(%0100100),PX(%1100000)
        .byte   PX(%0011001),PX(%0010010),PX(%0100100),PX(%1001001),PX(%0010010),PX(%0100100),PX(%1100000)
        .byte   PX(%0110001),PX(%0010010),PX(%0100100),PX(%1001001),PX(%0010010),PX(%0100100),PX(%0110000)
        .byte   PX(%0110001),PX(%0010010),PX(%0100100),PX(%1001001),PX(%0010010),PX(%0100100),PX(%0110000)
        .byte   PX(%0110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0110000)
        .byte   PX(%1100001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0011001),PX(%1001100),PX(%0011000)
        .byte   PX(%1100110),PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0011000)
        .byte   PX(%1100001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0011001),PX(%1001100),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000)

iigs_bits:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1100000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0110000)
        .byte   PX(%1100111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0110000)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0110000)
        .byte   PX(%1100110),PX(%0110011),PX(%0011001),PX(%1000000),PX(%0000110),PX(%0110000)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0110000)
        .byte   PX(%1100110),PX(%0110011),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0110000)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0110000)
        .byte   PX(%1100110),PX(%0110000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0110000)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0110000)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0110000)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0110000)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110),PX(%0110000)
        .byte   PX(%1100111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0110000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0110000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1100000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%0011001),PX(%1001111),PX(%1100000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000)

iie_card_bits:
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000),PX(%0000000)
        .byte   PX(%0011110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000),PX(%0000000)
        .byte   PX(%0011110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000),PX(%0011000),PX(%0000000)
        .byte   PX(%0011110),PX(%0000000),PX(%0000000),PX(%0000111),PX(%1111100),PX(%0011000),PX(%0011000),PX(%0000000)
        .byte   PX(%0011110),PX(%0111000),PX(%0011001),PX(%1000111),PX(%1111100),PX(%0000000),PX(%0011000),PX(%0111100)
        .byte   PX(%0011110),PX(%0111000),PX(%0011001),PX(%1000111),PX(%1111100),PX(%0000000),PX(%0011000),PX(%0111100)
        .byte   PX(%0001100),PX(%0000000),PX(%0011001),PX(%1000111),PX(%1111100),PX(%0000000),PX(%0011000),PX(%0111100)
        .byte   PX(%0001100),PX(%1111000),PX(%0000000),PX(%0000111),PX(%1111100),PX(%0011111),PX(%0011001),PX(%1111111)
        .byte   PX(%0001100),PX(%1111000),PX(%0111100),PX(%0000000),PX(%0000000),PX(%0011111),PX(%0011000),PX(%1111110)
        .byte   PX(%0001100),PX(%1111000),PX(%0111100),PX(%0000000),PX(%0000000),PX(%0011111),PX(%0011000),PX(%0111100)
        .byte   PX(%0001100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000),PX(%0011000)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011),PX(%1111111),PX(%1111111),PX(%1100011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%0001100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)

laser128_bits:
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%1100000)
        .byte   PX(%0000001),PX(%1000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011001),PX(%1000110),PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0011000),PX(%1100011),PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0011000),PX(%0110001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0011000),PX(%0011000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0011000),PX(%0001100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0011000),PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0011000),PX(%0110011),PX(%0011001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0011001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110)
        .byte   PX(%0011000),PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0000110)
        .byte   PX(%0011001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)

ace500_bits:
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%1100000)
        .byte   PX(%0000001),PX(%1000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%0110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%0110010),PX(%1010101),PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010101),PX(%0100011)
        .byte   PX(%0110001),PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010011)
        .byte   PX(%0110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%0110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0011000),PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0000110)
        .byte   PX(%0011001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0011000),PX(%0001100),PX(%1100110)
        .byte   PX(%0011000),PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0000110)
        .byte   PX(%0011001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0011000),PX(%0001100),PX(%1100110)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)

ace2000_bits:
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0110011),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100110),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%1100000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%1100000)
        .byte   PX(%0000001),PX(%1001100),PX(%0000000),PX(%0000000),PX(%0000001),PX(%1001100),PX(%1100000)
        .byte   PX(%0000001),PX(%1000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%1100000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%0110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%0110011),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110011)
        .byte   PX(%0110011),PX(%1111111),PX(%1000000),PX(%0000000),PX(%1100000),PX(%0000000),PX(%0110011)
        .byte   PX(%0110011),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110011)
        .byte   PX(%0110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)


;;; ============================================================

.if INCLUDE_UNSUPPORTED_MACHINES
str_ii:
        PASCAL_STRING res_string_model_ii

str_iiplus:
        PASCAL_STRING res_string_model_iiplus

str_iii:
        PASCAL_STRING res_string_model_iii
.endif

str_iie_original:
        PASCAL_STRING res_string_model_iie_original

str_iie_enhanced:
        PASCAL_STRING res_string_model_iie_enhanced

str_iie_edm:
        PASCAL_STRING res_string_model_iie_edm

str_iie_card:
        PASCAL_STRING res_string_model_iie_card

str_iic_original:
        PASCAL_STRING res_string_model_iic_original

str_iic_rom0:
        PASCAL_STRING res_string_model_iic_rom0

str_iic_rom3:
        PASCAL_STRING res_string_model_iic_rom3

str_iic_rom4:
        PASCAL_STRING res_string_model_iic_rom4

str_iic_plus:
        PASCAL_STRING res_string_model_iic_plus

str_iigs:
        PASCAL_STRING res_string_model_iigs_pattern
        kStrIIgsROMOffset = res_const_model_iigs_pattern_offset1

str_laser128:
        PASCAL_STRING res_string_model_laser128

str_ace500:
        PASCAL_STRING res_string_model_ace500

str_ace2000:
        PASCAL_STRING res_string_model_ace2000

;;; ============================================================

str_prodos_version:
        PASCAL_STRING "ProDOS #.#.#" ; do not localize
        kVersionStrMajor = 8
        kVersionStrMinor = 10
        kVersionStrPatch = 12

str_slot_n:
        PASCAL_STRING res_string_slot_n_pattern ; dialog label
        kStrSlotNOffset = res_const_slot_n_pattern_offset1

str_memory_prefix:
        PASCAL_STRING res_string_memory_prefix ; dialog label

str_memory_suffix:
        PASCAL_STRING res_string_memory_suffix       ; memory size suffix for kilobytes

memory:.word    0

;;; ============================================================

str_cpu_prefix: PASCAL_STRING res_string_cpu_prefix
str_6502:       PASCAL_STRING res_string_cpu_type_6502
str_65C02:      PASCAL_STRING res_string_cpu_type_65C02
str_65802:      PASCAL_STRING res_string_cpu_type_65802
str_65816:      PASCAL_STRING res_string_cpu_type_65816

;;; ============================================================

model_str_ptr:        .addr   0
model_pix_ptr:        .addr   0

        DEFINE_POINT line1, 0, 37
        DEFINE_POINT line2, kDAWidth, 37

        DEFINE_POINT pos_slot1, 45, 50
        DEFINE_POINT pos_slot2, 45, 61
        DEFINE_POINT pos_slot3, 45, 72
        DEFINE_POINT pos_slot4, 45, 83
        DEFINE_POINT pos_slot5, 45, 94
        DEFINE_POINT pos_slot6, 45, 105
        DEFINE_POINT pos_slot7, 45, 116

slot_pos_table:
        .addr 0, pos_slot1, pos_slot2, pos_slot3, pos_slot4, pos_slot5, pos_slot6, pos_slot7

;;; ============================================================

        PAD_TO $0FFD
.proc Z80Routine
        .assert * = $0FFD, error, "Must be at $0FFD / FFFDH"
        ;; .org $FFFD
        patch := *+2
        .byte   $32, $00, $e0   ; ld ($Es00),a   ; s=slot being probed turn off Z80, next PC is $0000
        .byte   $3e, $01        ; ld a,$01
        .byte   $32, $08, $00   ; ld (flag),a
        .byte   $c3, $fd, $ff   ; jp $FFFD
        flag := *
        .byte   $00             ; flag: .db $00
.endproc

;;; ============================================================

kMaxSmartportDevices = 8

str_diskii:     PASCAL_STRING res_string_card_type_diskii
str_block:      PASCAL_STRING res_string_card_type_block
kStrSmartportLength = .strlen(res_string_card_type_smartport)
str_smartport:  PASCAL_STRING res_string_card_type_smartport
        .res    (kMaxSmartportDevices*16 + (kMaxSmartportDevices-1)*2), 0 ; names + ", " seps
str_ssc:        PASCAL_STRING res_string_card_type_ssc
str_80col:      PASCAL_STRING res_string_card_type_80col
str_mouse:      PASCAL_STRING res_string_card_type_mouse
str_silentype:  PASCAL_STRING res_string_card_type_silentype
str_clock:      PASCAL_STRING res_string_card_type_clock
str_comm:       PASCAL_STRING res_string_card_type_comm
str_serial:     PASCAL_STRING res_string_card_type_serial
str_parallel:   PASCAL_STRING res_string_card_type_parallel
str_printer:    PASCAL_STRING res_string_card_type_printer
str_joystick:   PASCAL_STRING res_string_card_type_joystick
str_io:         PASCAL_STRING res_string_card_type_io
str_modem:      PASCAL_STRING res_string_card_type_modem
str_audio:      PASCAL_STRING res_string_card_type_audio
str_storage:    PASCAL_STRING res_string_card_type_storage
str_network:    PASCAL_STRING res_string_card_type_network
str_mockingboard: PASCAL_STRING res_string_card_type_mockingboard
str_z80:        PASCAL_STRING res_string_card_type_z80
str_uthernet2:  PASCAL_STRING res_string_card_type_uthernet2
str_vidhd:      PASCAL_STRING res_string_card_type_vidhd
str_unknown:    PASCAL_STRING res_string_unknown
str_empty:      PASCAL_STRING res_string_empty
str_none:       PASCAL_STRING res_string_none

;;; ============================================================

        DEFINE_POINT model_pos, 150, 12
        DEFINE_POINT pdver_pos, 150, 23
        DEFINE_POINT mem_pos, 150, 34

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

.params dib_buffer
Number_Devices:                 ; if unit_num == 0 && status_code == 0
Device_Statbyte1:       .byte   0
Interrupt_Status:               ; if unit_num == 0 && status_code == 0
Device_Size_Lo:         .byte   0
Device_Size_Med:        .byte   0
Device_Size_Hi:         .byte   0
ID_String_Length:       .byte   0
Device_Name:            .res    16
Device_Type_Code:       .byte   0
Device_Subtype_Code:    .byte   0
Version:                .word   0
.endparams

;;; ============================================================
;;; Per Technical Note: Apple II Miscellaneous #7: Apple II Family Identification
;;; http://www.1000bit.it/support/manuali/apple/technotes/misc/tn.misc.07.html
;;; and c/o JohnMBrooks

;;; Machine                    $FBB3    $FB1E    $FBC0    $FBDD    $FBBF
;;; --------------------------------------------------------------------
;;; Apple ][                    $38     [$AD]    [$60]             [$2F]
;;; Apple ][+                   $EA      $AD     [$EA]             [$EA]
;;; Apple /// (emulation)       $EA      $8A
;;; Apple IIe                   $06     [$AD]     $EA     [$A9]    [$00]
;;; Apple IIe (enhanced)        $06     [$AD]     $E0     [$A9]    [$00]
;;; Apple IIe (Ext. Debug Mon.) $06     [$AD]     $E1
;;; Apple IIe Option Card *     $06     [$AD]     $E0      $02
;;; Apple IIc **                $06     [$4C]     $00     [$A9]     $FF
;;; Apple IIc (3.5 ROM)         $06     [$4C]     $00     [$A9]     $00
;;; Apple IIc (Org. Mem. Exp.)  $06     [$4C]     $00     [$A9]     $03
;;; Apple IIc (Rev. Mem. Exp.)  $06     [$4C]     $00     [$A9]     $04
;;; Apple IIc Plus              $06     [$4C]     $00     [$A9]     $05
;;; Apple IIgs ***              $06     [$4C]     $E0     [$00]    [$00]
;;; Laser 128                   $06      $AC     [$E0]    [$8D]    [$00]
;;; Franklin ACE 500            $06      $AD      $00      $4C     [$00]
;;; Franklin ACE 2000 ****      $06      $AD    $EA/$E0    $4C     [$00]
;;;
;;; (Values in [] are for reference, not needed for compatibility check)
;;;
;;; * = $FBBE is the version byte for the Apple IIe Card.
;;;   $00 = first release
;;;   $03 = latest Apple release of IIe Startup (c/o MG)
;;;
;;; ** = $FBBF is the version byte for the Apple IIc family:
;;;   $FF = Original
;;;   $00 = 3.5 ROM
;;;   $03 = Original Memory Expansion
;;;   $04 = Revised Memory Expansion
;;;   $05 = IIc Plus
;;;
;;; *** = Apple IIgs looks like an Enhanced IIe. SEC, JSR $FE1F, CC=IIgs
;;;
;;; **** = Franklin ACE 2000 appears to have different ROM versions:
;;;   v5.X - has $FBC0=$EA (like an original IIe), and does not have $60 (RTS)
;;;          at $FE1F, so the IIgs IDROUTINE must be used with caution: it
;;;          will modify A and output text!
;;;   v6.0 - has $FBC0=$E0 (like an enhanced IIe), and has $FE1F=$60

.enum model
.if ::INCLUDE_UNSUPPORTED_MACHINES
        ii                      ; Apple ][
        iiplus                  ; Apple ][+
        iii                     ; Apple /// (emulation)
.endif
        iie_original            ; Apple IIe (original)
        iie_enhanced            ; Apple IIe (enhanced)
        iie_edm                 ; Apple IIe (Extended Debugging Monitor)
        iic_original            ; Apple IIc
        iic_rom0                ; Apple IIc (3.5 ROM)
        iic_rom3                ; Apple IIc (Org. Mem. Exp.)
        iic_rom4                ; Apple IIc (Rev. Mem. Exp.)
        iic_plus                ; Apple IIc Plus
        iigs                    ; Apple IIgs
        iie_card                ; Apple IIe Option Card
        laser128                ; Laser 128
        ace500                  ; Franklin ACE 500
        ace2000                 ; Franklin ACE 2000
        LAST
.endenum
kNumModels = model::LAST

model_str_table:
.if INCLUDE_UNSUPPORTED_MACHINES
        .addr   str_ii           ; Apple ][
        .addr   str_iiplus       ; Apple ][+
        .addr   str_iii          ; Apple /// (emulation)
.endif
        .addr   str_iie_original ; Apple IIe (original)
        .addr   str_iie_enhanced ; Apple IIe (enhanced)
        .addr   str_iie_edm      ; Apple IIe (Extended Debugging Monitor)
        .addr   str_iic_original ; Apple IIc
        .addr   str_iic_rom0     ; Apple IIc (3.5 ROM)
        .addr   str_iic_rom3     ; Apple IIc (Org. Mem. Exp.)
        .addr   str_iic_rom4     ; Apple IIc (Rev. Mem. Exp.)
        .addr   str_iic_plus     ; Apple IIc Plus
        .addr   str_iigs         ; Apple IIgs
        .addr   str_iie_card     ; Apple IIe Option Card
        .addr   str_laser128     ; Laser 128
        .addr   str_ace500       ; Franklin ACE 500
        .addr   str_ace2000      ; Franklin ACE 2000
        ASSERT_ADDRESS_TABLE_SIZE model_str_table, kNumModels

model_pix_table:
.if INCLUDE_UNSUPPORTED_MACHINES
        .addr   ii_bitmap       ; Apple ][
        .addr   ii_bitmap       ; Apple ][+
        .addr   iii_bitmap      ; Apple /// (emulation)
.endif
        .addr   iie_bitmap      ; Apple IIe (original)
        .addr   iie_bitmap      ; Apple IIe (enhanced)
        .addr   iie_bitmap      ; Apple IIe (Extended Debugging Monitor)
        .addr   iic_bitmap      ; Apple IIc
        .addr   iic_bitmap      ; Apple IIc (3.5 ROM)
        .addr   iic_bitmap      ; Apple IIc (Org. Mem. Exp.)
        .addr   iic_bitmap      ; Apple IIc (Rev. Mem. Exp.)
        .addr   iic_bitmap      ; Apple IIc Plus
        .addr   iigs_bitmap     ; Apple IIgs
        .addr   iie_card_bitmap ; Apple IIe Option Card
        .addr   laser128_bitmap ; Laser 128
        .addr   ace500_bitmap   ; Franklin ACE 500
        .addr   ace2000_bitmap  ; Franklin ACE 2000
        ASSERT_ADDRESS_TABLE_SIZE model_pix_table, kNumModels

;;; Based on Technical Note: Miscellaneous #2: Apple II Family Identification Routines 2.1
;;; http://www.1000bit.it/support/manuali/apple/technotes/misc/tn.misc.07.html
;;; Note that IIgs resolves as IIe (enh.) and is identified by ROM call.
;;;
;;; Format is: model (enum), then byte pairs [$FBxx, expected], then $00

MODEL_ID_PAGE := $FB00

model_lookup_table:
.if INCLUDE_UNSUPPORTED_MACHINES
        .byte   model::ii
        .byte   $B3, $38, 0

        .byte   model::iiplus
        .byte   $B3, $EA, $1E, $AD, 0

        .byte   model::iii
        .byte   $B3, $EA, $1E, $8A, 0
.endif

        .byte   model::laser128
        .byte   $B3, $06, $1E, $AC, 0

        .byte   model::ace500
        .byte   $B3, $06, $1E, $AD, $C0, $00, 0

        .byte   model::ace2000  ; must check before IIe
        .byte   $B3, $06, $1E, $AD, $C0, $E0, $DD, $4C, 0

        .byte   model::iie_original
        .byte   $B3, $06, $C0, $EA, 0

        .byte   model::iie_card ; must check before IIe enhanced check
        .byte   $B3, $06, $C0, $E0, $DD, $02, 0

        .byte   model::iie_enhanced
        .byte   $B3, $06, $C0, $E0, 0

        .byte   model::iic_original
        .byte   $B3, $06, $C0, $00, $BF, $FF, 0

        .byte   model::iic_rom0
        .byte   $B3, $06, $C0, $00, $BF, $00, 0

        .byte   model::iic_rom3
        .byte   $B3, $06, $C0, $00, $BF, $03, 0

        .byte   model::iic_rom4
        .byte   $B3, $06, $C0, $00, $BF, $04, 0

        .byte   model::iic_plus
        .byte   $B3, $06, $C0, $00, $BF, $05, 0

        .byte   $FF             ; sentinel

.proc IdentifyModel
        ;; Read from ROM
        bit     ROMIN2

        ldx     #0              ; offset into table

        ;; For each model...
m_loop: ldy     model_lookup_table,x ; model number
        bmi     fail            ; hit end of table
        inx

        ;; For each byte/expected pair in table...
b_loop: lda     model_lookup_table,x ; offset from MODEL_ID_PAGE
        beq     match           ; success!
        sta     @lsb
        inx

        lda     model_lookup_table,x
        inx
        @lsb := *+1
        cmp     MODEL_ID_PAGE   ; self-modified

        beq     b_loop          ; match, keep looking

        ;; No match, so skip to end of this entry
:       inx
        lda     model_lookup_table-1,x
        beq     m_loop

        inx
        bne     :-

fail:   ldy     #0

match:  tya

        ;; A has model; but now test for IIgs
        cmp     #model::iie_enhanced   ; IIgs masquerades as Enhanced IIe
        bne     :+

        sec
        jsr     IDROUTINE
        bcs     :+              ; not IIgs

        ;; Is IIgs; Y holds ROM revision
        tya
        ora     #'0'            ; convert to ASCII digit
        sta     str_iigs + kStrIIgsROMOffset
        lda     #model::iigs

        ;; A has model
:       asl
        tax
        copy16  model_str_table,x, model_str_ptr
        copy16  model_pix_table,x, model_pix_ptr

        ;; Read from LC RAM
        bit     LCBANK1
        bit     LCBANK1
        rts
.endproc


;;; ============================================================

;;; KVERSION Table
;;; $00         1.0.1
;;; $01         1.0.2
;;; $01         1.1.1
;;; $04         1.4
;;; $05         1.5
;;; $07         1.7
;;; $08         1.8
;;; $08         1.9
;;; $21         2.0.1
;;; $23         2.0.3
;;; $24         2.4.x

;;; Assert: Main is banked in
.proc IdentifyProDOSVersion

        ;; Read ProDOS version field from global page in main
        lda     KVERSION

        cmp     #$24
        bcs     v_2x
        cmp     #$20
        bcs     v_20x

        ;; $00...$08 are 1.x (roughly)
v_1x:   and     #$0F
        ora     #'0'
        sta     str_prodos_version + kVersionStrMinor
        copy    #'1', str_prodos_version + kVersionStrMajor
        copy    #10, str_prodos_version ; length
        bne     done

        ;; $20...$23 are 2.0.x (roughly)
v_20x:  and     #$0F
        ora     #'0'
        sta     str_prodos_version + kVersionStrPatch
        copy    #'0', str_prodos_version + kVersionStrMinor
        copy    #'2', str_prodos_version + kVersionStrMajor
        copy    #12, str_prodos_version ; length
        bne     done

        ;; $24...??? are 2.x (so far?)
v_2x:   and     #$0F
        ora     #'0'
        sta     str_prodos_version + kVersionStrMinor
        copy    #'2', str_prodos_version + kVersionStrMajor
        copy    #10, str_prodos_version ; length
        bne     done

done:   rts
.endproc

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
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     HandleDown
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     HandleKey
        jmp     InputLoop
.endproc

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo
        jsr     ClearUpdates
        rts                     ; exits input loop
.endproc

;;; ============================================================

.proc HandleKey
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     Exit
        cmp     #kShortcutEasterEgg
        beq     :+
        cmp     #TO_LOWER(kShortcutEasterEgg)
        bne     InputLoop
:       jmp     HandleEgg
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
        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        beq     InputLoop
        bne     Exit
.endproc

;;; ============================================================

.proc HandleDrag
        copy    winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        lda     dragwindow_params::moved
        bpl     :+

        ;; Draw DeskTop's windows and icons.
        jsr     ClearUpdates

        ;; Draw DA's window
        jsr     DrawWindow

:       jmp     InputLoop

.endproc

;;; ============================================================

.proc HandleEgg
        lda     egg
        asl
        tax
        copy16  model_str_table,x, model_str_ptr
        copy16  model_pix_table,x, model_pix_ptr

        inc     egg
        lda     egg
        cmp     #kNumModels
        bne     :+
        lda     #0
        sta     egg

:       jsr     ClearWindow
        jsr     DrawWindow
done:   jmp     InputLoop

egg:    .byte   0
.endproc

;;; ============================================================

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

;;; ============================================================

.proc ClearWindow
        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        bne     :+
        rts

:       MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::PaintRect, grafport::cliprect
        rts
.endproc

;;; ============================================================

.proc DrawWindow
        ptr := $06

        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        bne     :+
        rts

:       MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        copy16  model_pix_ptr, bits_addr
        MGTK_CALL MGTK::SetPenMode, penmode
        MGTK_CALL MGTK::PaintBits, SELF_MODIFIED, bits_addr

        MGTK_CALL MGTK::MoveTo, model_pos
        ldax    model_str_ptr
        jsr     DrawString

        MGTK_CALL MGTK::MoveTo, pdver_pos
        param_call DrawString, str_prodos_version

        MGTK_CALL MGTK::MoveTo, line1
        MGTK_CALL MGTK::LineTo, line2

        MGTK_CALL MGTK::MoveTo, mem_pos
        param_call DrawString, str_memory_prefix
        param_call DrawString, str_from_int
        param_call DrawString, str_memory_suffix
        param_call DrawString, str_cpu_prefix
        jsr     CPUId
        jsr     DrawString

        lda     #7
        sta     slot
        lda     #1<<7
        sta     mask

loop:   lda     slot
        asl
        tax
        copy16  slot_pos_table,x, slot_pos
        MGTK_CALL MGTK::MoveTo, 0, slot_pos
        lda     slot
        ora     #'0'
        sta     str_slot_n + kStrSlotNOffset
        param_call DrawString, str_slot_n

        ;; Possibilities:
        ;; * ProDOS thinks there's a card - may be firmware or no firmware
        ;; * ProDOS thinks there's no card, because it doesn't have firmware
        ;; * ProDOS thinks there's no card, because it's empty

        ;; Check ProDOS slot bit mask
        sta     RAMRDOFF
        lda     SLTBYT
        sta     RAMRDON
        and     mask
        beq     pro_no

        ;; ProDOS thinks there's a card...
        lda     slot
        jsr     ProbeSlot       ; check for matching firmware
        bcs     draw
        lda     slot            ; check non-firmware cases in case of
        jsr     ProbeSlotNoFirmware ; false-positive (e.g. emulator)
        bcs     draw

        ldax    #str_unknown
        bne     draw            ; always

pro_no:
        lda     slot
        jsr     ProbeSlotNoFirmware
        bcs     draw

        ldax    #str_empty

draw:   jsr     DrawString

        lsr     mask
        dec     slot
        bne     loop

        MGTK_CALL MGTK::ShowCursor
        rts

slot:   .byte   0
mask:   .byte   0
penmode:.byte   MGTK::notpencopy
.endproc

;;; ============================================================
;;; Point $06/$07 at $Cn00
;;; Input: Slot in A
.proc SetSlotPtr
        ptr     := $6

        ora     #$C0
        sta     ptr+1
        lda     #0
        sta     ptr
        rts
.endproc

;;; ============================================================
;;; Firmware Detector:
;;; Input: Slot # in A
;;; Output: Carry set and string ptr in A,X if detected, carry clear otherwise
;;;
;;; Uses a variety of sources:
;;; * Technical Note: ProDOS #21: Identifying ProDOS Devices
;;;   http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.21.html
;;; * Technical Note: Miscellaneous #8: Pascal 1.1 Firmware Protocol ID Bytes
;;;   http://www.1000bit.it/support/manuali/apple/technotes/misc/tn.misc.08.html
;;; * "ProDOS BASIC Programming Examples" disk

.proc ProbeSlot
        ptr     := $6

        ;; Point ptr at $Cn00
        jsr     SetSlotPtr

        ;; Get Firmware Byte
.macro GET_FWB offset
        ldy     #offset
        lda     (ptr),y
.endmacro

        ;; Compare Firmware Byte
.macro COMPARE_FWB offset, value
        GET_FWB  offset
        cmp     #value
.endmacro

;;; ---------------------------------------------
;;; Per Technical Note: Miscellaneous #8: Pascal 1.1 Firmware Protocol ID Bytes
;;; http://www.1000bit.it/support/manuali/apple/technotes/misc/tn.misc.08.html

;;; ProDOS and SmartPort Devices

        ldax    #sigtable_prodos_device
        jsr     SigCheck
        bcc     notpro

;;; Per Technical Note: ProDOS #21: Identifying ProDOS Devices
;;; http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.21.html
        COMPARE_FWB $FF, $00    ; $CnFF == $00 ?
        bne     :+
        return16 #str_diskii
:
        COMPARE_FWB $07, $00    ; $Cn07 == $00 ?
        beq     :+
        sec
        return16 #str_block
:
        jsr     PopulateSmartportName
        sec
        return16 #str_smartport
notpro:

;;; ---------------------------------------------
;;; VidHD

        ldax    #sigtable_vidhd
        jsr     SigCheck
        bcc     :+
        return16 #str_vidhd
:

;;; ---------------------------------------------
;;; Apple IIe Technical Reference Manual
;;; Pascal 1.1 firmware protocol
;;;
;;; $Cs05       $38 (like the old Apple II Serial Interface card)
;;; $Cs07       $18 (like the old Apple II Serial Interface card)
;;; $Cs0B       $01 (the generic signature of new cards)
;;; $Cs0C       $ci (the device signature)
;;;              c = device class
;;;              i = unique identifier

        ldax    #sigtable_pascal
        jsr     SigCheck
        jcc     notpas

        GET_FWB $0C             ; $Cn0C == ....

.macro IF_SIGNATURE_THEN_RETURN     byte, arg
        cmp     #byte
        bne     :+
        return16 #arg           ; C=1 implicitly if Z=1
:
.endmacro

        ;; Specific Apple cards/built-ins
    IF_SIGNATURE_THEN_RETURN $31, str_ssc
    IF_SIGNATURE_THEN_RETURN $88, str_80col
    IF_SIGNATURE_THEN_RETURN $20, str_mouse

        ;; Generic cards
        and     #$F0            ; just device class nibble
    IF_SIGNATURE_THEN_RETURN $10, str_printer
    IF_SIGNATURE_THEN_RETURN $20, str_joystick
    IF_SIGNATURE_THEN_RETURN $30, str_io
    IF_SIGNATURE_THEN_RETURN $40, str_modem
    IF_SIGNATURE_THEN_RETURN $50, str_audio
    IF_SIGNATURE_THEN_RETURN $60, str_clock
    IF_SIGNATURE_THEN_RETURN $70, str_storage
    IF_SIGNATURE_THEN_RETURN $80, str_80col
    IF_SIGNATURE_THEN_RETURN $90, str_network

        ;; Pascal Firmware, but unknown type. Return
        ;; "unknown" otherwise it will be detected as serial below.
        sec
        return16 #str_unknown

notpas:

;;; ---------------------------------------------
;;; Based on ProDOS BASIC Programming Examples

;;; Silentype
        ldax    #sigtable_silentype
        jsr     SigCheck
        bcc     :+
        return16 #str_silentype
:

;;; Clock
        ldax    #sigtable_clock
        jsr     SigCheck
        bcc     :+
        return16 #str_clock
:

;;; Communications Card
        ldax    #sigtable_comm
        jsr     SigCheck
        bcc     :+
        return16 #str_comm
:

;;; Serial Card
        ldax    #sigtable_serial
        jsr     SigCheck
        bcc     :+
        return16 #str_serial
:

;;; Parallel Card
        ldax    #sigtable_parallel
        jsr     SigCheck
        bcc     :+
        return16 #str_parallel
:

        rts

;;; Input: A,X = pointer to table (num, offset, value, offset, value, ...)
;;; Output: C=1 on match, C=0 on no match
.proc SigCheck
        stax    table_ptr

        ldx     #0              ; first byte in table is number of pairs
        jsr     get_next
        asl     a               ; if 2 entries, then point at table[4] (etc)
        tax

:       jsr     get_next        ; second byte in pair is value
        sta     @compare_byte
        dex
        jsr     get_next        ; first byte in pair is offset
        tay
        lda     (ptr),y
        @compare_byte := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     no_match
        dex
        bne     :-

        ;; match
        sec
        rts

no_match:
        clc
        rts

get_next:
        table_ptr := *+1
        lda     SELF_MODIFIED,x
        rts
.endproc

;;; Format is: num, offset, value, offset, value, ...
sigtable_prodos_device: .byte   3, $01, $20, $03, $00, $05, $03
sigtable_vidhd:         .byte   3, $00, $24, $01, $EA, $02, $4C
sigtable_pascal:        .byte   3, $05, $38, $07, $18, $0B, $01
sigtable_silentype:     .byte   3, $17, $C9, $37, $CF, $4C, $EA
sigtable_clock:         .byte   3, $00, $08, $01, $78, $02, $28
sigtable_comm:          .byte   2, $05, $18, $07, $38
sigtable_serial:        .byte   2, $05, $38, $07, $18
sigtable_parallel:      .byte   2, $05, $48, $07, $48

.endproc

;;; ============================================================
;;; Check for cards without firmware.
;;; Input: Slot # in A
;;; Output: Carry set and string ptr in A,X if detected, carry clear otherwise

.proc ProbeSlotNoFirmware
        ptr     := $6

        ;; Point ptr at $Cn00
        jsr     SetSlotPtr

        jsr     DetectMockingboard
        bcc     :+
        return16 #str_mockingboard
:

        jsr     DetectZ80
        bcc     :+
        return16 #str_z80
:

        jsr     DetectUthernet2
        bcc     :+
        return16 #str_uthernet2
:
        clc
        rts
.endproc

;;; Detect Z80
;;; Assumes $06 points at $Cn00, returns carry set if found

.proc DetectZ80
        ;; Convert $Cn to $En, update Z80 code
        lda     $07             ; $Cn
        ora     #$E0
        sta     Z80Routine::patch

        ;; Clear detection flag
        copy    #0, Z80Routine::flag

        ;; Try to invoke Z80
        ldy     #0
        sta     ($06),y

        ;; Flag will be set to 1 by routine if Z80 was present.
        lda     Z80Routine::flag
        ror                     ; move flag into carry
        rts
.endproc

;;; Detect Uthernet II
;;; Assumes $06 points at $Cn00, returns carry set if found

.proc DetectUthernet2
        ;; Based on the a2RetroSystems Uthernet II manual

        MR := $C084

        lda     $07             ; $Cn
        and     #$0F            ; $0n
        asl
        asl
        asl
        asl                     ; $n0
        tax                     ; Slot in high nibble of X

        ;; Send the RESET command
        lda     #$80
        sta     MR,x
        nop
        nop
        lda     MR,x            ; Should get zero
        bne     fail

        ;; Configure operating mode with auto-increment
        lda     #3              ; Operating mode
        sta     MR,x
        lda     MR,x            ; Read back MR
        cmp     #3
        bne     fail

        ;; Probe successful
        sec
        rts

fail:   clc
        rts
.endproc

;;; Detect Mockingboard
;;; Assumes $06 points at $Cn00, returns carry set if found

.proc DetectMockingboard
        ptr := $06
        tmp := $08

        ;; Hit Slot 6, which causes accelerators e.g. Zip Chip
        ;; to slow down.
        bit     $C0E0

        ldy     #4              ; $Cn04
        ldx     #2              ; try 2 times

loop:   lda     (ptr),Y         ; 6522 Low-Order Counter
        sta     tmp             ; read 8 cycles apart
        lda     (ptr),Y

        sec                     ; compare counter offset
        sbc     tmp
        cmp     #($100 - 8)
        bne     fail
        dex
        bne     loop

found:  sec
        rts

fail:   clc
        rts
.endproc

;;; ============================================================
;;; Update str_memory with memory count in kilobytes

;;; Assert: Main is banked in (for `CheckSlinkyMemory` call)
.proc IdentifyMemory
        copy16  #0, memory
        jsr     CheckRamworksMemory
        sty     memory          ; Y is number of 64k banks
        cpy     #0              ; 0 means 256 banks
        bne     :+
        inc     memory+1
:       inc16   memory          ; Main 64k memory

        jsr     CheckIIgsMemory
        jsr     CheckSlinkyMemory

        asl16   memory          ; * 64
        asl16   memory
        asl16   memory
        asl16   memory
        asl16   memory
        asl16   memory
        ldax    memory
        jsr     IntToStringWithSeparators
        rts
.endproc

;;; ============================================================
;;; Calculate RamWorks memory; returns number of banks in Y
;;; (256 banks = 0, since there must be at least 1)
;;;
;;; Note the bus floats for RamWorks RAM when the bank has no RAM,
;;; or bank selection may wrap to an earlier bank. This requires
;;; three passes (mark, count, restore); if count and restore are
;;; combined, it will produce false-positives if wrapping occurs
;;; (see https://github.com/a2stuff/a2d/issues/131).
;;;
;;; RamWorks-style cards are not guaranteed to have contiguous banks.
;;; a user can install 64Kb or 256Kb chips in a physical bank, in the
;;; former case, a gap in banks will appear.  Additionally, the piggy
;;; back cards may not have contiguous banks depending on capacity
;;; and installed chips.
;;;
;;; AE RamWorks cards can only support 8M max (banks $00-$7F), but
;;; the various emulators support 16M max (banks $00-$FF).
;;;
;;; If RamWorks is not present, bank switching is a no-op and the
;;; same regular 64Kb AUX bank is present throughout the test; this
;;; will be handled by an invalid signature check for other banks.
;;;
;;; Assert: Main is banked in
.proc CheckRamworksMemory
        sigb0   := $00
        sigb1   := $01

        ;; DAs are loaded with $1C00 as the io_buffer, so
        ;; $1C00-$1FFF MAIN is free.
        buf0    := DA_IO_BUFFER
        buf1    := DA_IO_BUFFER + $100

        php
        sei     ; don't let interrupts happen while the memory map is munged

        ;; Assumes ALTZPON on entry/exit
        ldy     #0              ; populated bank count

        ;; Iterate downwards (in case unpopulated banks wrap to earlier ones),
        ;; saving bytes and marking each bank.
.scope
        ldx     #255            ; bank we are checking
:       stx     RAMWORKS_BANK
        copy    sigb0, buf0,x   ; preserve bytes
        copy    sigb1, buf1,x
        txa                     ; bank num as first signature
        sta     sigb0
        eor     #$FF            ; complement as second signature
        sta     sigb1
        dex
        cpx     #255
        bne     :-
.endscope

        ;; Iterate upwards, tallying valid banks.
.scope
        ldx     #0              ; bank we are checking
loop:   stx     RAMWORKS_BANK   ; select bank
        txa
        cmp     sigb0           ; verify first signature
        bne     next
        eor     #$FF
        cmp     sigb1           ; verify second signature
        bne     next
        iny                     ; match - count it
next:   inx                     ; next bank
        bne     loop            ; if we hit 256 banks, make sure we exit
.endscope

        ;; Iterate upwards, restoring valid banks.
.scope
        ldx     #0              ; bank we are checking
loop:   stx     RAMWORKS_BANK   ; select bank
        txa
        cmp     sigb0           ; verify first signature
        bne     next
        eor     #$FF
        cmp     sigb1           ; verify second signature
        bne     next
        copy    buf0,x, sigb0   ; match - restore it
        copy    buf1,x, sigb1
next:   inx                     ; next bank
        bne     loop            ; if we hit 256 banks, make sure we exit
.endscope

        ;; Switch back to RW bank 0 (normal aux memory)
        lda     #0
        sta     RAMWORKS_BANK

        plp                     ; restore interrupt state
        rts
.endproc

;;; ============================================================

.proc CheckIIgsMemory
        bit     ROMIN2          ; Check ROM - is this a IIgs?
        sec
        jsr     IDROUTINE
        bit     LCBANK1
        bit     LCBANK1
        bcs     done

        .pushcpu
        .setcpu "65816"

        ;; From the IIgs Memory Manager tool set source
        ;; c/o Antoine Vignau and Dagen Brock
        NumBanks := $E11624

        lda     NumBanks
        sta     memory
        lda     NumBanks+1
        sta     memory+1
        .popcpu

done:   rts
.endproc

;;; ============================================================

;;; Assert: Main is banked in (due to SmartPort calls)

.proc CheckSlinkyMemory
        slot_ptr := $06

        lda     #7
        sta     slot

        ;; Point at $Cn00, look for SmartPort signature bytes
loop:   lda     slot
        jsr     SetSlotPtr

        ldx     #3
:       ldy     sig_offsets,x
        lda     (slot_ptr),y
        cmp     sig_values,x
        bne     next
        dex
        bpl     :-

        ;; Now look for device type
        ldy     #$FB            ; $CnFB is SmartPort ID Type byte
        lda     (slot_ptr),y
        and     #%00000001      ; bit 0 = RAM card
        beq     next

        ;; Locate SmartPort entry point: $Cn00 + ($CnFF) + 3
        ldy     #$FF
        lda     (slot_ptr),y
        clc
        adc     #3
        sta     sp_addr
        lda     slot_ptr+1
        sta     sp_addr+1

        ;; Make a STATUS call
        ;; NOTE: Must be done from Main.
        ;; https://github.com/a2stuff/a2d/issues/483
        sp_addr := *+1
        jsr     SELF_MODIFIED
        .byte   $00             ; STATUS
        .addr   status_params
        bcs     next

        ;; Convert blocks (0.5k) to banks (64k)
        ldx     #7
:       lsr     dib_buffer::Device_Size_Hi
        ror     dib_buffer::Device_Size_Med
        ror     dib_buffer::Device_Size_Lo
        dex
        bne     :-

        add16   memory, dib_buffer::Device_Size_Lo, memory

next:   dec     slot
        bpl     loop
        rts

sig_offsets:
        .byte   $01, $03, $05, $07
sig_values:
        .byte   $20, $00, $03, $00
slot:
        .byte   0

.params status_params
param_count:    .byte   3
unit_num:       .byte   1
list_ptr:       .addr   dib_buffer
status_code:    .byte   3       ; Return Device Information Block (DIB)
.endparams

.endproc


;;; ============================================================
;;; Input: 16-bit unsigned integer in A,X
;;; Output: str_from_int populated, with separator if needed

str_from_int:
        PASCAL_STRING "000,000" ; do not localize

        .include "../lib/inttostring.s"

;;; ============================================================
;;; Identify CPU - string pointer returned in A,X

.proc CPUId
        sed
        lda     #$99
        clc
        adc     #$01
        cld
        bmi     p6502
        clc
        .pushcpu
        .setcpu "65816"
        sep     #%00000001    ; two-byte NOP on 65C02
        .popcpu
        bcs     p658xx
        ; 65C02
        return16 #str_65C02
p6502:  return16 #str_6502

        ;; Distinguish 65802 and 65816 by machine ID
p658xx: bit     ROMIN2
        sec
        jsr     IDROUTINE
        bit     LCBANK1
        bit     LCBANK1
        bcs     p65802
        return16 #str_65816     ; Only IIgs supports 65816
p65802: return16 #str_65802     ; Other boards support 65802
.endproc

;;; ============================================================
;;; Look up SmartPort device names.
;;; (unit number 1) as the name.
;;; Inputs: $06 points at $Cn00
;;; Output: str_smartport populated with device names, or "(none)"

;;; Follows Technical Note: SmartPort #4: SmartPort Device Types
;;; http://www.1000bit.it/support/manuali/apple/technotes/smpt/tn.smpt.4.html

;;; Assert: Main is banked in (due to SmartPort calls)
.proc PopulateSmartportNameMainImpl

.params status_params
param_count:    .byte   3
unit_num:       .byte   1
list_ptr:       .addr   dib_buffer
status_code:    .byte   3       ; Return Device Information Block (DIB)
.endparams

        slot_ptr := $06

start:
        copy    #$80, empty_flag
        copy    #kStrSmartportLength, str_smartport

        ;; Locate SmartPort entry point: $Cn00 + ($CnFF) + 3
        ldy     #$FF
        lda     (slot_ptr),y
        clc
        adc     #3
        sta     sp_addr
        lda     slot_ptr+1
        sta     sp_addr+1

        ;; Query number of devices
        copy    #0, status_params::unit_num ; SmartPort status itself
        copy    #0, status_params::status_code
        jsr     SmartPortCall
        lda     dib_buffer::Number_Devices
        cmp     #kMaxSmartportDevices
        bcc     :+
        lda     #kMaxSmartportDevices
:       sta     num_devices
        bne     :+
        jmp     finish          ; no devices!

        ;; Start with unit #1
:       copy    #1, status_params::unit_num
        copy    #3, status_params::status_code ; Return Device Information Block (DIB)

device_loop:
        ;; Make the call
        jsr     SmartPortCall
        bcs     next

        ;; Trim trailing whitespace (seen in CFFA)
.scope
        ldy     dib_buffer::ID_String_Length
        beq     done
:       lda     dib_buffer::Device_Name-1,y
        cmp     #' '
        bne     done
        dey
        bne     :-
done:   sty     dib_buffer::ID_String_Length
.endscope

        ;; Case-adjust
.scope
        ldy     dib_buffer::ID_String_Length
        beq     done
        dey
        beq     done

        ;; Look at prior and current character; if both are alpha,
        ;; lowercase current.
loop:   lda     dib_buffer::Device_Name-1,y ; Test previous character
        jsr     IsAlpha
        bne     next
        lda     dib_buffer::Device_Name,y ; Adjust this one if also alpha
        jsr     IsAlpha
        bne     next
        lda     dib_buffer::Device_Name,y
        ora     #AS_BYTE(~CASE_MASK)
        sta     dib_buffer::Device_Name,y

next:   dey
        cpy     #0
        bne     loop
done:
.endscope

        ldx     str_smartport

        ;; Append separator, unless it's the first
.scope
        bit     empty_flag
        bmi     :+
        lda     #','
        inx
        sta     str_smartport,x
        lda     #' '
        inx
        sta     str_smartport,x
:
.endscope

        ;; Append device name
.scope
        copy    #0, empty_flag  ; saw a unit!

        lda    dib_buffer::ID_String_Length
    IF_ZERO
        ;; Seen in wDrive
        ldy     #0
:       lda     str_unknown+1,y
        inx
        sta     str_smartport,x
        iny
        cpy     str_unknown
        bne     :-
    ELSE
        ldy     #0
:       lda     dib_buffer::Device_Name,y
        inx
        sta     str_smartport,x
        iny
        cpy     dib_buffer::ID_String_Length
        bne     :-
    END_IF
.endscope

        stx     str_smartport

next:   lda     status_params::unit_num
        cmp     num_devices
        beq     finish
        inc     status_params::unit_num
        jmp     device_loop

finish:
        ;; If no units, populate with "(none)"
        bit     empty_flag
        bpl     exit

        ldx     str_smartport
        ldy     #0
:       lda     str_none+1,y
        inx
        sta     str_smartport,x
        iny
        cpy     str_none
        bne     :-
        stx     str_smartport

exit:   rts

empty_flag:
        .byte   0
num_devices:
        .byte   0

.proc SmartPortCall
        ;; NOTE: Must be done from Main.
        ;; https://github.com/a2stuff/a2d/issues/483
        sp_addr := * + 1
        jsr     SELF_MODIFIED
        .byte   SPCall::Status
        .addr   status_params
        rts
.endproc
        sp_addr = SmartPortCall::sp_addr

.endproc

;;; Assert: Aux is banked in (relays to Main)
.proc PopulateSmartportName
        sta     RAMRDOFF
        sta     RAMWRTOFF

        jsr     PopulateSmartportNameMainImpl::start

        sta     RAMWRTON
        COPY_STRING str_smartport, str_smartport
        sta     RAMRDON
        rts
.endproc

;;; ============================================================
;;; Inputs: Character in A
;;; Outputs: Z=1 if alpha, 0 otherwise
;;; A is trashed

.proc IsAlpha
        cmp     #'@'            ; in upper/lower "plane" ?
        bcc     nope
        and     #CASE_MASK      ; force upper-case
        cmp     #'A'
        bcc     nope
        cmp     #'Z'+1
        bcs     nope

        lda     #0
        rts

nope:   lda     #$FF
        rts
.endproc

;;; ============================================================

        .include  "../lib/drawstring.s"

;;; ============================================================


da_end  := *
.assert * < $1B00, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00
