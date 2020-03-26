        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"


;;; ============================================================
;;; Selector application
;;; ============================================================

        .include "selector1.s"
        .include "selector2.s"

        .org $1E27
        .scope
        .include "selector3.s"
        .endscope

        .include "selector4.s"

        .org $4000
        .scope
        .include "selector5.s"
        .endscope

        .include "selector6.s"

        .incbin "orig/selector7"
