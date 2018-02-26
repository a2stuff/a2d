
        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

.macro entry arg1, arg2
        .byte arg1
        .addr arg2
.endmacro

;;; ==================================================
;;; Resources from language card area

        winfo12 := $D5B7
        winfo15 := $D5F1

        path_buf0 := $D402
        path_buf1 := $D443
        path_buf2 := $D484

        grafport3 := $D239

        dialog_rect1 := $DA9E
        dialog_rect2 := $DAAA

;;; ==================================================
;;; Interdependent Overlays

        .include "ovl3.s"       ; Selector (1/2) @ $9000-$9FFF
        .include "ovl4.s"       ; Common         @ $5000-$6FFF
        .include "ovl5.s"       ; File Copy      @ $7000-$77FF
        .include "ovl6.s"       ; File Delete    @ $7000-$77FF
        .include "ovl7.s"       ; Selector (2/2) @ $7000-$77FF
