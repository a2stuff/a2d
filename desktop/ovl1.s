
        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ==================================================
;;; Overlay for Disk Copy
;;; ==================================================

        .org $800

.proc disk_copy_overlay
        jmp     start

        load_target := $1800

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

.proc open_params
param_count:    .byte   3
pathname:       .addr   str_desktop2
io_buffer:      .addr   $1C00
ref_num:        .byte   0
.endproc

.proc set_mark_params
param_count:    .byte   2
ref_num:        .byte   0
position:       .faraddr $131E0
.endproc

.proc read_params
param_count:    .byte   4
ref_num:        .byte   0
data_buffer:    .addr   load_target
request_count:  .word   $0200
trans_count:    .word   0
.endproc

.proc close_params
param_count:    .byte   1
ref_num:        .byte   0
.endproc

str_desktop2:
        PASCAL_STRING "DeskTop2"

;;; ==================================================

        ptr := $6

start:  lda     #$80
        sta     ptr
        DESKTOP_RELAY_CALL $6, $0
        MGTK_RELAY_CALL MGTK::CloseAll, $0
        MGTK_RELAY_CALL MGTK::SetZP1, ptr

        ;; Copy menu bar up to language card, and use it.
        ldx     #.sizeof(menu_bar)
:       lda     menu_bar,x
        sta     $D400,x
        dex
        bpl     :-
        MGTK_RELAY_CALL MGTK::SetMenu, menu_target

        ;; Clear most of the system bitmap
        ldx     #BITMAP_SIZE - 3
        lda     #0
:       sta     BITMAP+1,x
        dex
        bpl     :-

        ;; Open self (DESKTOP2)
        yax_call MLI_RELAY, OPEN, open_params

        ;; Slurp in yet another overlay...
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num

        yax_call MLI_RELAY, SET_MARK, set_mark_params
        yax_call MLI_RELAY, READ, read_params
        yax_call MLI_RELAY, CLOSE, close_params

        ;; And invoke it.
        sta     ALTZPOFF
        lda     ROMIN2
        jmp     load_target

;;; ==================================================

.proc MLI_RELAY
        sty     call
        sta     params
        stx     params+1
        php
        sei
        sta     ALTZPOFF
        lda     $C082
        jsr     MLI
call:   .byte   0
params: .addr   0
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        plp
        txa
self:   bne     self            ; hang on error?
        rts
.endproc

        PAD_TO $A00
.endproc