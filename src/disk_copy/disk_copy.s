        .include "../config.inc"

        BTK_SHORT = 1

        .include "apple2.inc"
        .include "opcodes.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../inc/smartport.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../toolkits/btk.inc"
        .include "../toolkits/lbtk.inc"
        .include "../lib/alert_dialog.inc"
        .include "disk_copy.inc"

;;; ============================================================
;;; Memory Constants

;;; MGTK - left over in Aux by DeskTop
MGTKAuxEntry    := $4000

;;; Font - left over in  Aux by DeskTop
DEFAULT_FONT    := $8800

;;; ============================================================
;;; File Structure
;;; ============================================================

        INITSEG 0
        DEFSEG Loader,          DISK_COPY_BOOTSTRAP, kDiskCopyBootstrapLength
        DEFSEG SegmentAuxLC,    $D000, $2000
        DEFSEG SegmentMain,     $0800, $0C00
        ;; Update `memory_bitmap` in main.s if these change!

;;; ============================================================
;;; Disk Copy module
;;; ============================================================

        RESOURCE_FILE "disk_copy.res"

        PREDEFINE_SCOPE ::auxlc
        PREDEFINE_SCOPE ::main

        .include "loader.s"
        .include "auxlc.s"
        .include "main.s"
