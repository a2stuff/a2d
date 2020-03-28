        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk_100B4.inc"


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


        .org $A000
        .scope
        .include "selector7.s"
        .endscope

        .org $A000
        .scope
        .include "selector8.s"
        .endscope
