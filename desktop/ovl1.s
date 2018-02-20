
        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

L1800           := $1800
MGTK_RELAY       := $D000
DESKTOP_RELAY   := $D040

;;; ==================================================
;;; Overlay for Disk Copy
;;; ==================================================

        .org $800

.proc disk_copy_overlay
        jmp     start

;;; ==================================================
;;; Menu - relocated up ot $D400

        menu_target := $D400

.proc menu_bar
        DEFINE_MENU_BAR 1
        DEFINE_MENU_BAR_ITEM 1, menu_target + (menu_label - menu_bar), menu_target + (menu - menu_bar)

menu:   DEFINE_MENU 1
        DEFINE_MENU_ITEM menu_target + (item_label - menu_bar)

menu_label:
        PASCAL_STRING "       Disk copy version 1.1   "
item_label:
        PASCAL_STRING "Rien"
.endproc

;;; ==================================================

L0842:  .byte   3
        .addr   str_desktop2
        .addr   $1C00

L0847:  .byte   $00,$02
L0849:  .byte   $00,$E0,$31,$01,$04
L084E:  .byte   $00,$00,$18,$00,$02,$00,$00,$01
        .byte   $00

str_desktop2:
        PASCAL_STRING "DeskTop2"

        ptr := $6

start:  lda     #$80
        sta     ptr
        yax_call DESKTOP_RELAY, $6, $0
        yax_call MGTK_RELAY, MGTK::CloseAll, $0
        yax_call MGTK_RELAY, MGTK::SetZP1, ptr

        ;; Copy menu bar up to language card, and use it.
        ldx     #.sizeof(menu_bar)
L0881:  lda     menu_bar,x
        sta     $D400,x
        dex
        bpl     L0881
        yax_call MGTK_RELAY, MGTK::SetMenu, menu_target

        ;; Clear most of the system bitmap
        ldx     #BITMAP_SIZE - 3
        lda     #0
:       sta     BITMAP+1,x
        dex
        bpl     :-


        ldy     #$C8
        lda     #$42
        ldx     #$08
        jsr     L08D3
        lda     L0847
        sta     L084E
        sta     L0849
        ldy     #$CE
        lda     #$48
        ldx     #$08
        jsr     L08D3
        ldy     #$CA
        lda     #$4D
        ldx     #$08
        jsr     L08D3
        ldy     #$CC
        lda     #$55
        ldx     #$08
        jsr     L08D3
        sta     ALTZPOFF
        lda     $C082
        jmp     L1800

L08D3:  sty     L08E7
        sta     L08E8
        stx     L08E9
        php
        sei
        sta     ALTZPOFF
        lda     $C082
        jsr     MLI
L08E7:  brk
L08E8:  brk
L08E9:  brk
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        plp
        txa
L08F6:  bne     L08F6
        rts

        PAD_TO $A00
.endproc