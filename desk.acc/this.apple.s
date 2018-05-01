        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

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
        sta     RAMRDON
        sta     RAMWRTON
        jsr     init

        ;; tear down/exit
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endscope

;;; ============================================================

screen_width    := 560
screen_height   := 192

da_window_id    := 60
da_width        := 400
da_height       := 118
da_left         := (screen_width - da_width)/2
da_top          := 50

.proc winfo
window_id:      .byte   da_window_id
options:        .byte   MGTK::option_go_away_box
title:          .addr   str_title
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_none
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   32
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   da_width
mincontlength:  .word   da_height
maxcontwidth:   .word   da_width
maxcontlength:  .word   da_height
port:
viewloc:        DEFINE_POINT da_left, da_top
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
maprect:        DEFINE_RECT 0, 0, da_width, da_height
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:          DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc

str_title:
        PASCAL_STRING "About this Apple II"

;;; ============================================================

.proc iie_bitmap
viewloc:        DEFINE_POINT 59, 5
mapbits:        .addr   iie_bits
mapwidth:       .byte   8
reserved:       .res    1
maprect:        DEFINE_RECT 0, 0, 50, 25
.endproc

.proc iic_bitmap
viewloc:        DEFINE_POINT 64, 4
mapbits:        .addr   iic_bits
mapwidth:       .byte   6
reserved:       .res    1
maprect:        DEFINE_RECT 0, 0, 41, 27
.endproc

.proc iigs_bitmap
viewloc:        DEFINE_POINT 65, 5
mapbits:        .addr   iigs_bits
mapwidth:       .byte   6
reserved:       .res    1
maprect:        DEFINE_RECT 0, 0, 38, 25
.endproc

.proc iii_bitmap
viewloc:        DEFINE_POINT 57, 5
mapbits:        .addr   iii_bits
mapwidth:       .byte   8
reserved:       .res    1
maprect:        DEFINE_RECT 0, 0, 54, 24
.endproc

.proc iie_card_bitmap
viewloc:        DEFINE_POINT 56, 9
mapbits:        .addr   iie_card_bits
mapwidth:       .byte   8
reserved:       .res    1
maprect:        DEFINE_RECT 0, 0, 55, 21
.endproc

.proc laser128_bitmap
viewloc:        DEFINE_POINT 60, 4
mapbits:        .addr   laser128_bits
mapwidth:       .byte   7
reserved:       .res    1
maprect:        DEFINE_RECT 0, 0, 47, 29
.endproc


iie_bits:
        .byte   px(%1111111),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0111111),px(%1111111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0110000),px(%0000000),px(%0000000),px(%0000000),px(%0111111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%0011001),px(%1001100),px(%1111110),px(%0111111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%0011001),px(%1111111),px(%1111110),px(%0111111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%0011111),px(%1111111),px(%1111110),px(%0111111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0110011),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0110000),px(%0000000),px(%0000000),px(%0000000),px(%0110011),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%0011111),px(%1111111)
        .byte   px(%1111111),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0111111),px(%1111111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0111100),px(%0000000),px(%0111111),px(%0000000),px(%0001111),px(%0011111),px(%1111111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%0011111),px(%1111111)
        .byte   px(%1111111),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0111111),px(%1111111)
        .byte   px(%1111100),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%0001111),px(%1111111)
        .byte   px(%1110001),px(%1110011),px(%0011001),px(%1001100),px(%1100110),px(%0110011),px(%1100011),px(%1111111)
        .byte   px(%1000111),px(%1001100),px(%1100110),px(%0110011),px(%0011001),px(%1001100),px(%1111000),px(%1111111)
        .byte   px(%0011110),px(%0110011),px(%0011001),px(%1001100),px(%1100110),px(%0110011),px(%0011110),px(%0111111)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%1000111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111000),px(%1111111)
        .byte   px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%1111111)


iic_bits:
        .byte   px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011111)
        .byte   px(%1111001),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1001111)
        .byte   px(%1111001),px(%1100000),px(%0000000),px(%0000000),px(%0000011),px(%1001111)
        .byte   px(%1111001),px(%1001111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%1111001),px(%1001100),px(%1100110),px(%0110011),px(%1111001),px(%1001111)
        .byte   px(%1111001),px(%1001111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%1111001),px(%1001100),px(%1100111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%1111001),px(%1001111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%1111001),px(%1001100),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%1111001),px(%1001111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%1111001),px(%1001111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%1111001),px(%1001111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%1111001),px(%1100000),px(%0000000),px(%0000000),px(%0000011),px(%1001111)
        .byte   px(%1111001),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1001111)
        .byte   px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011111)
        .byte   px(%1111111),px(%1110011),px(%1111111),px(%1111111),px(%1100111),px(%1111111)
        .byte   px(%1000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000001)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0011001),px(%1001100),px(%1100110),px(%0110011),px(%0011001),px(%1001100)
        .byte   px(%0011001),px(%1001100),px(%1100110),px(%0110011),px(%0011001),px(%1001100)
        .byte   px(%0011001),px(%1001100),px(%1100110),px(%0110011),px(%0011001),px(%1001100)
        .byte   px(%0011001),px(%1001100),px(%1100110),px(%0110011),px(%0011001),px(%1001100)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0011001),px(%1001100),px(%1100110),px(%0110011),px(%0011001),px(%1001100)
        .byte   px(%0011110),px(%0110011),px(%0011001),px(%1001100),px(%1100110),px(%0111100)
        .byte   px(%0011001),px(%1001100),px(%1100110),px(%0110011),px(%0011001),px(%1001100)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%1000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000001)

iigs_bits:
        .byte   px(%1000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011111)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1001111)
        .byte   px(%0011000),px(%0000000),px(%0000000),px(%0000000),px(%0000001),px(%1001111)
        .byte   px(%0011001),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%0011001),px(%1001100),px(%1100110),px(%0111111),px(%1111001),px(%1001111)
        .byte   px(%0011001),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%0011001),px(%1001100),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%0011001),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%0011001),px(%1001111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%0011001),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%0011001),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%0011001),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%0011001),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1001111)
        .byte   px(%0011000),px(%0000000),px(%0000000),px(%0000000),px(%0000001),px(%1001111)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1001111)
        .byte   px(%1000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011111)
        .byte   px(%1100111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%1100111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%1100111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%1100111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%1100110),px(%0110000),px(%0011111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%1100111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0111111)
        .byte   px(%1100111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%1100111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%1111111)

iii_bits:
        .byte   px(%1111111),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%1111111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0110000),px(%0000000),px(%0000000),px(%0000000),px(%0111111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%0011001),px(%1001100),px(%1111110),px(%0111111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%0011001),px(%1111111),px(%1111110),px(%0111111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%0011111),px(%1111111),px(%1111110),px(%0110011),px(%0011001),px(%1111111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0110011),px(%0011001),px(%1111111)
        .byte   px(%1111110),px(%0110000),px(%0000000),px(%0000000),px(%0000000),px(%0111111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1111111)
        .byte   px(%1111111),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%1111111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111000),px(%0000000),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0111100),px(%0000111),px(%1111111),px(%1111111),px(%0000111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111001),px(%1111111)
        .byte   px(%1111110),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000001),px(%1111111)
        .byte   px(%1111100),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111000),px(%1111111)
        .byte   px(%1110001),px(%1110011),px(%0011001),px(%1001100),px(%1100111),px(%1110011),px(%0011110),px(%0011111)
        .byte   px(%1000111),px(%1001100),px(%1100110),px(%0110011),px(%0011001),px(%1111100),px(%1100111),px(%1000111)
        .byte   px(%0011110),px(%0110011),px(%0011001),px(%1001100),px(%1100110),px(%0111111),px(%0011001),px(%1110011)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1110011)
        .byte   px(%1000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000111)

iie_card_bits:
        .byte   px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000111),px(%1111111)
        .byte   px(%1100001),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1100111),px(%1111111)
        .byte   px(%1100001),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1100111),px(%1100111),px(%1111111)
        .byte   px(%1100001),px(%1111111),px(%1111111),px(%1111000),px(%0000011),px(%1100111),px(%1100111),px(%1111111)
        .byte   px(%1100001),px(%1000111),px(%1100110),px(%0111000),px(%0000011),px(%1111111),px(%1100111),px(%1000011)
        .byte   px(%1100001),px(%1000111),px(%1100110),px(%0111000),px(%0000011),px(%1111111),px(%1100111),px(%1000011)
        .byte   px(%1110011),px(%1111111),px(%1100110),px(%0111000),px(%0000011),px(%1111111),px(%1100111),px(%1000011)
        .byte   px(%1110011),px(%0000111),px(%1111111),px(%1111000),px(%0000011),px(%1100000),px(%1100110),px(%0000000)
        .byte   px(%1110011),px(%0000111),px(%1000011),px(%1111111),px(%1111111),px(%1100000),px(%1100111),px(%0000001)
        .byte   px(%1110011),px(%0000111),px(%1000011),px(%1111111),px(%1111111),px(%1100000),px(%1100111),px(%1000011)
        .byte   px(%1110011),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1100111),px(%1100111)
        .byte   px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000111),px(%1111111)
        .byte   px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111100),px(%0000000),px(%0000000),px(%0011100)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%1110011),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1100111)
        .byte   px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000111)

laser128_bits:
        .byte   px(%1111111),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0111111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%0011111)
        .byte   px(%1111110),px(%0111000),px(%0000000),px(%0000000),px(%0000000),px(%1111111),px(%0011111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%0011111)
        .byte   px(%1111110),px(%0110011),px(%0011001),px(%1001100),px(%1111110),px(%0111111),px(%0011111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%0011111)
        .byte   px(%1111110),px(%0110011),px(%0011001),px(%1111111),px(%1111110),px(%0111111),px(%0011111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%0011111)
        .byte   px(%1111110),px(%0110011),px(%0011111),px(%1111111),px(%1111110),px(%0111111),px(%0011111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0111111),px(%0011111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0110011),px(%0011111)
        .byte   px(%1111110),px(%0110011),px(%1111111),px(%1111111),px(%1111110),px(%0110011),px(%0011111)
        .byte   px(%1111110),px(%0111000),px(%0000000),px(%0000000),px(%0000001),px(%1111111),px(%0011111)
        .byte   px(%1111110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%0011111)
        .byte   px(%1111111),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0111111)
        .byte   px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111)
        .byte   px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000011)
        .byte   px(%1100110),px(%0111001),px(%1100111),px(%1111111),px(%1111111),px(%1111111),px(%1111001)
        .byte   px(%1100111),px(%0011100),px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000001)
        .byte   px(%1100111),px(%1001110),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111001)
        .byte   px(%1100111),px(%1100111),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000001)
        .byte   px(%1100111),px(%1110011),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111001)
        .byte   px(%1100111),px(%1111000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000001)
        .byte   px(%1100111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111001)
        .byte   px(%1100111),px(%1001100),px(%1100110),px(%0110011),px(%1111111),px(%1111111),px(%1111001)
        .byte   px(%1100110),px(%0110011),px(%0011001),px(%1001100),px(%1100110),px(%0110011),px(%0011001)
        .byte   px(%1100111),px(%1001100),px(%1100110),px(%0110011),px(%0011001),px(%1001100),px(%1111001)
        .byte   px(%1100110),px(%0110011),px(%0011001),px(%1001100),px(%1100110),px(%0110011),px(%0011001)
        .byte   px(%1100111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111001)
        .byte   px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000011)


;;; ============================================================

str_ii:
        PASCAL_STRING "Apple ]["

str_iiplus:
        PASCAL_STRING "Apple ][+"

str_iii:
        PASCAL_STRING "Apple /// (emulation)"

str_iie:
        PASCAL_STRING "Apple //e"

str_iie_enhanced:
        PASCAL_STRING "Apple IIe (enhanced)"

str_iie_card:
        PASCAL_STRING "Apple IIe Card"

str_iic:
        PASCAL_STRING "Apple IIc"

str_iic_plus:
        PASCAL_STRING "Apple IIc Plus"

str_iigs:
        PASCAL_STRING "Apple IIgs"

str_laser128:
        PASCAL_STRING "Laser 128"

;;; ============================================================

str_prodos_version:
        PASCAL_STRING "ProDOS 0.0.0"

str_slot_n:
        PASCAL_STRING "Slot 0:   "

str_memory_prefix:
        PASCAL_STRING "Memory: "

str_memory_suffix:
        PASCAL_STRING "K"

memory:.word    0

;;; ============================================================

str_diskii:     PASCAL_STRING "Disk II"
str_block:      PASCAL_STRING "Generic Block Device"
str_smartport:  PASCAL_STRING "SmartPort Device"
str_ssc:        PASCAL_STRING "Super Serial Card"
str_80col:      PASCAL_STRING "80 Column Card"
str_mouse:      PASCAL_STRING "Mouse Card"
str_silentype:  PASCAL_STRING "Silentype"
str_clock:      PASCAL_STRING "Clock"
str_comm:       PASCAL_STRING "Communications Card"
str_serial:     PASCAL_STRING "Serial Card"
str_parallel:   PASCAL_STRING "Parallel Card"
str_used:       PASCAL_STRING "Used"
str_printer:    PASCAL_STRING "Printer"
str_joystick:   PASCAL_STRING "Joystick"
str_io:         PASCAL_STRING "I/O Card"
str_modem:      PASCAL_STRING "Modem"
str_audio:      PASCAL_STRING "Audio Card"
str_storage:    PASCAL_STRING "Mass Storage"
str_network:    PASCAL_STRING "Network Card"
str_unknown:    PASCAL_STRING "(unknown)"
str_empty:      PASCAL_STRING "(empty)"

;;; ============================================================

str_cpu_prefix: PASCAL_STRING "  CPU: "
str_6502:       PASCAL_STRING "6502"
str_65C02:      PASCAL_STRING "65C02"
str_658xx:      PASCAL_STRING "658xx"

;;; ============================================================

model_str_ptr:        .addr   0
model_pix_ptr:        .addr   0

line1:  DEFINE_POINT 0, 37
line2:  DEFINE_POINT da_width, 37

pos_slot1:      DEFINE_POINT    45, 50
pos_slot2:      DEFINE_POINT    45, 61
pos_slot3:      DEFINE_POINT    45, 72
pos_slot4:      DEFINE_POINT    45, 83
pos_slot5:      DEFINE_POINT    45, 94
pos_slot6:      DEFINE_POINT    45, 105
pos_slot7:      DEFINE_POINT    45, 116

slot_pos_table:
        .addr 0, pos_slot1, pos_slot2, pos_slot3, pos_slot4, pos_slot5, pos_slot6, pos_slot7

;;; ============================================================

model_pos:      DEFINE_POINT 150, 12
pdver_pos:      DEFINE_POINT 150, 23
mem_pos:        DEFINE_POINT 150, 34

.proc event_params
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
.endproc

.proc findwindow_params
mousex:         .word   0
mousey:         .word   0
which_area:     .byte   0
window_id:      .byte   0
.endproc

.proc trackgoaway_params
clicked:        .byte   0
.endproc

.proc dragwindow_params
window_id:      .byte   0
dragx:          .word   0
dragy:          .word   0
moved:          .byte   0
.endproc

.proc winport_params
window_id:      .byte   da_window_id
port:           .addr   grafport
.endproc

.proc grafport
viewloc:        DEFINE_POINT 0, 0
mapbits:        .word   0
mapwidth:       .word   0
cliprect:       DEFINE_RECT 0, 0, 0, 0
pattern:        .res    8, 0
colormasks:     .byte   0, 0
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textback:       .byte   0
textfont:       .addr   0
.endproc


;;; ============================================================
;;; Per Tech Note: Apple II Miscellaneous #7: Apple II Family Identification,
;;; and c/o JohnMBrooks

;;; Machine                    $FBB3    $FB1E    $FBC0    $FBDD    $FBBE    $FBBF
;;; -----------------------------------------------------------------------------
;;; Apple ][                    $38     [$AD]    [$60]                      [$2F]
;;; Apple ][+                   $EA      $AD     [$EA]                      [$EA]
;;; Apple /// (emulation)       $EA      $8A
;;; Apple IIe                   $06     [$AD]     $E0                       [$00]
;;; Apple IIe (enhanced)        $06     [$AD]     $E0                       [$00]
;;; Apple IIe Option Card       $06     [$AD]     $E0      $02      $00
;;; Apple IIc                   $06               $00                        $FF
;;; Apple IIc (3.5 ROM)         $06               $00                        $00
;;; Apple IIc (Org. Mem. Exp.)  $06               $00                        $03
;;; Apple IIc (Rev. Mem. Exp.)  $06               $00                        $04
;;; Apple IIc Plus              $06               $00                        $05
;;; Apple IIgs                  $06     [$4C]     $E0  (and SEC, JSR $FE1F, CC=IIgs)
;;; Laser 128                   $06      $AC     [$E0]
;;;
;;; (Values in [] are for reference, not needed for compatibility check)

.scope model
        ii           := 0
        iiplus       := 1
        iie          := 2
        iie_enhanced := 3
        iic          := 4
        iic_plus     := 5
        iigs         := 6
        iie_card     := 7
        iii          := 8
        laser128     := 9
        LAST         := 10
.endscope

model_str_table:
        .addr   str_ii, str_iiplus, str_iie, str_iie_enhanced
        .addr   str_iic, str_iic_plus, str_iigs, str_iie_card
        .addr   str_iii, str_laser128

model_pix_table:
        .addr   iie_bitmap, iie_bitmap, iie_bitmap, iie_bitmap
        .addr   iic_bitmap, iic_bitmap, iigs_bitmap, iie_card_bitmap
        .addr   iii_bitmap, laser128_bitmap

.proc identify_model
        ;; Read from ROM
        lda     ROMIN2

        ;; ][, ][+ or ///
        lda     $FBB3
        cmp     #$38
        bne     :+
        lda     #model::ii
        bpl     done
:       cmp     #$EA
        bne     iie_or_later
        lda     $FB1E
        cmp     #$AD
        bne     :+
        lda     #model::iiplus
        bpl     done
:       lda     #model::iii
        bpl     done

iie_or_later:
        lda     $FBC0
        beq     iic_or_plus

        ;; IIe, IIe card, IIgs or Laser 128
        lda     $FB1E
        cmp     #$AC
        bne     :+
        lda     #model::laser128
        bpl     done
:       sec
        jsr     $FE1F
        bcs     :+
        lda     #model::iigs
        bpl     done
:       lda     $FBDD
        cmp     #$02
        bne     :+
        lda     #model::iie_card
        bpl     done
:       lda     #model::iie
        bpl     done

iic_or_plus:
        lda     $FBBF
        cmp     #5
        bne     :+
        lda     #model::iic
        bpl     done
:       lda     #model::iic_plus
        ;; fall through...

done:   asl
        tax
        copy16  model_str_table,x, model_str_ptr
        copy16  model_pix_table,x, model_pix_ptr

        ;; Read from LC RAM
        lda     LCBANK1
        lda     LCBANK1
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

.proc identify_prodos_version
        ;; Read ProDOS version field from global page in main
        sta     RAMRDOFF
        sta     RAMWRTOFF
        lda     KVERSION
        sta     RAMRDON
        sta     RAMWRTON

        cmp     #$24
        bcs     v_2x
        cmp     #$20
        bcs     v_20x

        ;; $00...$08 are 1.x (roughly)
v_1x:   and     #$0F
        clc
        adc     #'0'
        sta     str_prodos_version + 10
        lda     #'1'
        sta     str_prodos_version + 8
        lda     #10
        sta     str_prodos_version ; length
        bne     done

        ;; $20...$23 are 2.0.x (roughly)
v_20x:  and     #$0F
        clc
        adc     #'0'
        sta     str_prodos_version + 12
        lda     #'0'
        sta     str_prodos_version + 10
        lda     #'2'
        sta     str_prodos_version + 8
        lda     #12
        sta     str_prodos_version ; length
        bne     done

        ;; $24...??? are 2.x (so far?)
v_2x:   and     #$0F
        clc
        adc     #'0'
        sta     str_prodos_version + 10
        lda     #'2'
        sta     str_prodos_version + 8
        lda     #10
        sta     str_prodos_version ; length
        bne     done

done:   rts
.endproc

;;; ============================================================

.proc init
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        jsr     identify_model
        jsr     identify_prodos_version
        jsr     identify_memory

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     draw_window
        MGTK_CALL MGTK::FlushEvents
        ;; fall through
.endproc

.proc input_loop
        MGTK_CALL MGTK::GetEvent, event_params
        bne     exit
        lda     event_params::kind
        cmp     #MGTK::event_kind_button_down ; was clicked?
        beq     handle_down
        cmp     #MGTK::event_kind_key_down  ; any key?
        beq     handle_key
        jmp     input_loop
.endproc

.proc exit
        MGTK_CALL MGTK::CloseWindow, winfo
        DESKTOP_CALL DT_REDRAW_ICONS
        rts                     ; exits input loop
.endproc

;;; ============================================================

.proc handle_key
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     exit
        cmp     #'E'
        bne     input_loop
        jmp     handle_egg
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
        cmp     #MGTK::area_close_box
        beq     handle_close
        cmp     #MGTK::area_dragbar
        beq     handle_drag
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_close
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        beq     input_loop
        bne     exit
.endproc

;;; ============================================================

.proc handle_drag
        copy    winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        lda     dragwindow_params::moved
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
        DESKTOP_CALL DT_REDRAW_ICONS

:       jmp     input_loop

.endproc

;;; ============================================================

.proc handle_egg
        lda     egg
        asl
        tax
        copy16  model_str_table,x, model_str_ptr
        copy16  model_pix_table,x, model_pix_ptr

        inc     egg
        lda     egg
        cmp     #model::LAST
        bne     :+
        lda     #0
        sta     egg

:       jsr     clear_window
        jsr     draw_window
done:   jmp     input_loop

egg:    .byte   0
.endproc

;;; ============================================================

.proc clear_window
        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::error_window_obscured
        bne     :+
        rts

:       MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::PaintRect, grafport::cliprect
        rts
.endproc

;;; ============================================================

.proc draw_window
        ptr := $06

        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::error_window_obscured
        bne     :+
        rts

:       MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        copy16  model_pix_ptr, bits_addr
        MGTK_CALL MGTK::PaintBits, $0000, bits_addr

        MGTK_CALL MGTK::MoveTo, model_pos
        ldax    model_str_ptr
        jsr     draw_pascal_string

        MGTK_CALL MGTK::MoveTo, pdver_pos
        addr_call draw_pascal_string, str_prodos_version

        MGTK_CALL MGTK::SetPenMode, penmode
        MGTK_CALL MGTK::MoveTo, line1
        MGTK_CALL MGTK::LineTo, line2

        MGTK_CALL MGTK::MoveTo, mem_pos
        addr_call draw_pascal_string, str_memory_prefix
        addr_call draw_pascal_string, str_from_int
        addr_call draw_pascal_string, str_memory_suffix
        addr_call draw_pascal_string, str_cpu_prefix
        jsr     cpuid
        jsr     draw_pascal_string

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
        clc
        adc     #'0'
        sta     str_slot_n + 6
        addr_call draw_pascal_string, str_slot_n

        ;; Check ProDOS slot bit mask
        sta     RAMRDOFF
        lda     SLTBYT
        sta     RAMRDON
        and     mask
        bne     check

        ldax    #str_empty
        jsr     draw_pascal_string
        jmp     next

check:  lda     slot
        jsr     probe_slot
        jsr     draw_pascal_string

next:   lsr     mask
        dec     slot
        bne     loop

        MGTK_CALL MGTK::ShowCursor
        rts

slot:   .byte   0
mask:   .byte   0
penmode:.byte   MGTK::notpencopy
.endproc


;;; ============================================================
;;; Firmware Detector: Slot # in A, returns string ptr in A,X
;;;
;;; Uses a variety of sources:
;;; * TechNote ProDOS #21: Identifying ProDOS Devices
;;; * TechNote Miscellaneous #8: Pascal 1.1 Firmware Protocol ID Bytes
;;; * "ProDOS BASIC Programming Examples" disk

.proc probe_slot
        ptr     := $6

        ;; Point ptr at $Cn00
        clc
        adc     #$C0
        sta     ptr+1
        lda     #0
        sta     ptr

        ;; Get Firmware Byte
.macro getfwb offset
        ldy     #offset
        lda     (ptr),y
.endmacro

        ;; Compare Firmware Byte
.macro cmpfwb offset, value
        getfwb  offset
        cmp     #value
.endmacro

.macro result arg
        ldax    #arg
        rts
.endmacro

;;; ---------------------------------------------
;;; Per Miscellaneous Technical Note #8
;;; ProDOS and SmartPort Devices

        cmpfwb  $01, $20        ; $Cn01 == $20 ?
        bne     notpro

        cmpfwb  $03, $00        ; $Cn03 == $00 ?
        bne     notpro

        cmpfwb  $05, $03        ; $Cn05 == $03 ?
        bne     notpro

;;; Per ProDOS Technical Note #21
        cmpfwb  $FF, $00        ; $CnFF == $00 ?
        bne     :+
        result  str_diskii
:

        cmpfwb  $07, $00        ; $Cn07 == $00 ?
        beq     :+
        result  str_block

;;; TODO: Follow SmartPort Technical Note #4
;;; and identify specific device type via STATUS call
:
        result  str_smartport
notpro:
;;; ---------------------------------------------
;;; Per Miscellaneous Technical Note #8
;;; Pascal 1.1 Devices

        cmpfwb  $05, $38        ; $Cn05 == $38 ?
        bne     notpas

        cmpfwb  $07, $18        ; $Cn07 == $18 ?
        bne     notpas

        cmpfwb  $0B, $01        ; $Cn0B == $01 ?
        bne     notpas

        getfwb  $0C             ; $Cn0C == ....

.macro sig     byte, arg
        cmp     #byte
        bne     :+
        result  arg
:
.endmacro

        sig     $31, str_ssc
        sig     $88, str_80col
        sig     $20, str_mouse

notpas:
;;; ---------------------------------------------
;;; Based on ProDOS BASIC Programming Examples

;;; Silentype
        cmpfwb  23, 201
        bne     :+
        cmpfwb  55, 207
        bne     :+
        cmpfwb  76, 234
        bne     :+
        result  str_silentype
:

;;; Clock
        cmpfwb  0, 8
        bne     :+
        cmpfwb  1, 120
        bne     :+
        cmpfwb  2, 40
        bne     :+
        result  str_clock
:

;;; Communications Card
        cmpfwb  5, 24
        bne     :+
        cmpfwb  7, 56
        bne     :+
        result  str_comm
:

;;; Serial Card
        cmpfwb  5, 56
        bne     :+
        cmpfwb  7, 24
        bne     :+
        result  str_serial
:

;;; Parallel Card
        cmpfwb  5, 72
        bne     :+
        cmpfwb  7, 72
        bne     :+
        result  str_parallel
:

;;; Generic Devices
        cmpfwb  11, 1
        bne     :+
        getfwb  12
        clc
        ror
        ror
        ror
        ror

        cmp     #0
        bne     :+
        result  str_used
:
        cmp     #1
        bne     :+
        result  str_printer
:
        cmp     #2
        bne     :+
        result  str_joystick
:
        cmp     #3
        bne     :+
        result  str_io
:
        cmp     #4
        bne     :+
        result  str_modem
:
        cmp     #5
        bne     :+
        result  str_audio
:
        cmp     #6
        bne     :+
        result  str_clock
:
        cmp     #7
        bne     :+
        result  str_storage
:
        cmp     #8
        bne     :+
        result  str_80col
:
        cmp     #9
        bne     :+
        result  str_network
:
        result  str_unknown
.endproc

;;; ============================================================
;;; Update str_memory with memory count in kilobytes

.proc identify_memory
        copy16  #0, memory
        jsr     check_ramworks_memory
        sty     memory          ; Y is number of 64k banks
        cpy     #0              ; 0 means 256 banks
        bne     :+
        inc     memory+1
:       inc16   memory          ; Main 64k memory
        asl16   memory          ; * 64
        asl16   memory
        asl16   memory
        asl16   memory
        asl16   memory
        asl16   memory
        ldax    memory
        jsr     int_to_string
.endproc

;;; ============================================================
;;; Calculate RamWorks memory; returns number of banks in Y
;;; (256 banks = 0)
;;; Note the bus floats for RamWorks RAM when the bank has no RAM.
;;; RamWorks-style cards are not guaranteed to have contiguous banks.
;;; a user can install 64Kb or 256Kb chips in a physical bank, in the
;;; former case, a gap in banks will appear.  Additionally, the piggy
;;; back cards may not have contiguous banks depending on capacity
;;; and installed chips.
;;; AE RamWorks cards can only support 8M max (banks $00-$7F), but
;;; the various emulators support 16M max (banks $00-$FF).
;;;
;;; If RamWorks is not present, bank switching is a no-op and the
;;; same regular 64Kb AUX bank is present throughout the test, so
;;; we also need to distinguish that case.
.proc check_ramworks_memory
        sigb0   := $00
        sigb1   := $01

        ;; Run from clone in main memory
        php
        sei     ; don't let interrupts happen while the memory map is munged

        sta     RAMRDOFF
        sta     RAMWRTOFF

        ;; Assumes ALTZPON on entry/exit
        RWBANK  := $C073

        ldx     #0              ; bank we are checking
        ldy     #0              ; populated bank count
loop:   stx     RWBANK          ; select bank
        copy    sigb0, stash0   ; save existing data
        copy    sigb1, stash1
        txa                     ; bank number as first check byte
        sta     sigb0
        cmp     sigb0
        bne     :+
        eor     #$FF            ; bank complement as secondary check byte
        sta     sigb1
        cmp     sigb1
        bne     :+
        iny                     ; found a bank, count it
        copy    stash1, sigb1
        copy    stash0, sigb0
        inx                     ; next bank
        bne     loop            ; if we hit 256 banks, make sure we exit

        ;; Switch back to RW bank 0 (normal aux memory)
        lda     #0
        sta     RWBANK

        ;; --------------------------------------------------

        ;; Y=0 means either 256 populated banks, or that there was
        ;; never a RawWorks card present and RWBANK is a no-op.
        cpy     #0
        bne     done

        ;; Disambiguate these cases by writing to banks 0 and 1
        ;; and testing that they work. We know that bank 1 is
        ;; not an unpopulated RW bank.

        copy    sigb0, stash0   ; Write signature to bank 0
        copy    #0, sigb0

        lda     #1              ; Write signature to bank 1
        sta     RWBANK
        copy    sigb0, stash1
        copy    #1, sigb0

        lda     #0              ; Check signature in bank 0
        sta     RWBANK
        cmp     sigb0           ; If we don't see bank 0 signature
        beq     :+              ; then this was all a sham; set Y
        iny                     ; to 1 bank, i.e. normal AUX memory.

:       lda     #1              ; Restore bank 1
        sta     RWBANK
        copy    stash1, sigb0

        lda     #0              ; Restore bank 0
        sta     RWBANK
        copy    stash0, sigb0

        ;; Back to executing from aux memory
done:   sta     RAMRDON
        sta     RAMWRTON
        plp                     ; restore interrupt state
        rts

stash0: .byte   0
stash1: .byte   0
.endproc

;;; ============================================================

.proc draw_pascal_string
        params := $6
        textptr := $6
        textlen := $8

        stax    textptr
        ldy     #0
        lda     (textptr),y
        beq     exit
        sta     textlen
        inc16   textptr
        MGTK_CALL MGTK::DrawText, params
exit:   rts
.endproc

;;; ============================================================

str_from_int:
        PASCAL_STRING "000000"

.proc int_to_string
        stax    value

        ;; Fill buffer with spaces
        ldx     #6
        lda     #' '
:       sta     str_from_int,x
        dex
        bne     :-

        lda     #0
        sta     nonzero_flag
        ldy     #0              ; y = position in string
        ldx     #0              ; x = which power index is subtracted (*2)

        ;; For each power of ten
loop:   lda     #0
        sta     digit

        ;; Keep subtracting/incrementing until zero is hit
sloop:  cmp16   value, powers,x
        bpl     subtract

        lda     digit
        bne     not_pad
        bit     nonzero_flag
        bmi     not_pad

        ;; Pad with space
        lda     #' '
        bne     :+
        ;; Convert to ASCII
not_pad:
        clc
        adc     #'0'            ; why not ORA $30 ???
        pha
        lda     #$80
        sta     nonzero_flag
        pla

        ;; Place the character, move to next
:       sta     str_from_int+2,y
        iny
        inx
        inx
        cpx     #8              ; up to 4 digits (*2) via subtraction
        beq     done
        jmp     loop

subtract:
        inc     digit
        sub16   value, powers,x, value
        jmp     sloop

done:   lda     value           ; handle last digit
        ora     #'0'
        sta     str_from_int+2,y
        rts

powers: .word   10000, 1000, 100, 10
value:  .word   0            ; remaining value as subtraction proceeds
digit:  .byte   0            ; current digit being accumulated
nonzero_flag:                ; high bit set once a non-zero digit seen
        .byte   0
.endproc

;;; ============================================================
;;; Identify CPU - string pointer returned in A,X

.proc cpuid
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
        result  str_65C02
p6502:  result  str_6502
p658xx: result  str_658xx
.endproc

;;; ============================================================

da_end  = *
.assert * < $1B00, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but icon tables start at AUX $1B00
