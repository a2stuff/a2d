        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../desktop.inc"


;;; ============================================================
;;; DeskTop - the actual application
;;; ============================================================

        .include "internal.inc"

        ;; TODO: Replace this with linker magic

        .include "desktop_aux.s"
        .include "desktop_lc.s"
        .include "desktop_res.s"
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
