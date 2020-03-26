        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"


;;; ============================================================
;;; Selector application
;;; ============================================================

        .org $2000
        .scope
        .include "selector1.s"
        .endscope

        .org $1000
        .scope
        .include "selector2.s"
        .endscope

        .org $1E27
        .scope
        .include "selector3.s"
        .endscope

        .org $290
        .scope
        .include "selector4.s"
        .endscope

        .org $4000
        .scope
        .include "selector5.s"
        .endscope

        .org $D000
        .scope
        .include "selector6.s"
        .endscope

        .incbin "orig/selector7"
