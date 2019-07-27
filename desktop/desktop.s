        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
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

        .include "invoker.s"

        .include "ovl1.s"
        .include "ovl1a.s"
        .include "ovl1b.s"
        .include "ovl1c.s"
        .include "ovl2.s"

.macro jump_table_entry addr
        .byte 0
        .addr addr
.endmacro

;;; ============================================================
;;; Interdependent Overlays

        .include "ovl3.s"       ; Selector (1/2) @ $9000-$9FFF
        .include "ovl4.s"       ; Common         @ $5000-$6FFF
        .include "ovl5.s"       ; File Copy      @ $7000-$77FF
        .include "ovl6.s"       ; File Delete    @ $7000-$77FF
        .include "ovl7.s"       ; Selector (2/2) @ $7000-$77FF

        common_overlay_L5000 := common_overlay::L5000
