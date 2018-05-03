        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ============================================================
;;; DeskTop - the actual application
;;; ============================================================

        dummy0000 := $0000         ; overwritten by self-modified code
        dummy1234 := $1234         ; overwritten by self-modified code

        ;; TODO: Replace this with linker magic

        .include "desktop_aux.s"
        .include "desktop_lc.s"
        .include "desktop_main.s"
