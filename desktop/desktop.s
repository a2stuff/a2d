        .include "../config.inc"

        .include "apple2.inc"
        .include "opcodes.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../inc/smartport.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/icontk.inc"
        .include "../toolkits/letk.inc"
        .include "../toolkits/btk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"


;;; ============================================================
;;; DeskTop - the actual application
;;; ============================================================

        RESOURCE_FILE "desktop.res"

        .include "internal.inc"

        .include "../lib/bootstrap.s"
        .include "quit_handler.s"

        ;; Ensure loader.starts at correct offset from start of file.
        .res    kSegmentLoaderOffset - (.sizeof(InstallAsQuit) + .sizeof(QuitRoutine))

        .include "loader.s"

        .assert .sizeof(InstallSegments) = kSegmentLoaderLength, error, "Size mismatch"

        .include "auxmem.s"
        .include "lc.s"
        .include "res.s"
        .include "main.s"

        .include "init.s"

        .include "../lib/invoker.s"

;;; ============================================================
;;; Other Overlays

        .include "ovl_format_erase.s"
        .include "ovl_selector_pick.s" ; Selector (1/2) @ $9000-$9FFF
        .include "ovl_file_dialog.s"   ; File Dialog    @ $5000-$6FFF
        .include "ovl_file_copy.s"     ; File Copy      @ $7000-$77FF
        .include "ovl_selector_edit.s" ; Selector (2/2) @ $7000-$77FF
