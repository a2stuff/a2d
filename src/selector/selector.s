        .include "../config.inc"

        BTK_SHORT = 1

        .include "apple2.inc"
        .include "apple2.mac"
        .include "opcodes.inc"
        .include "../inc/macros.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
        .include "../toolkits/lbtk.inc"
        .include "../toolkits/optk.inc"
        .include "../lib/alert_dialog.inc"
        .include "../common.inc"

SAVE_AREA_BUFFER:= $0800
MGTKEntry       := $4000

OVERLAY_ADDR    := MGTKEntry + kSegmentAppLength

MLIEntry        := MLI

.enum AlertID
selector_unable_to_run  = $00
io_error                = $27
no_device               = $28
pathname_does_not_exist = $44
insert_source_disk      = $45
file_not_found          = $46
copy_incomplete         = $FC
not_enough_room         = $FD
insert_system_disk      = $FE
basic_system_not_found  = $FF
.endenum

;;; ============================================================
;;; File Structure
;;; ============================================================
;;; Selector is broken into various segments plus dynamically
;;; loaded overlays, all stored in one file. This section
;;; defines the file offsets, load addresses and lengths of each
;;; segment and offset

        ;; Bootstrap is at $0-$200 in file
        kLoaderOffset = $200

        ;; Segments
        INITSEG kLoaderOffset
        DEFSEG SegmentLoader,     $2000,        $0200
        DEFSEG SegmentInvoker,    INVOKER,      $0160
        DEFSEG SegmentApp,        $4000,        $6B00
        DEFSEG SegmentAlert,      $D000,        $0600

        ;; Dynamically loaded overlays
        DEFSEG OverlayFileDialog, OVERLAY_ADDR, $0B00
        DEFSEG OverlayCopyDialog, OVERLAY_ADDR, $0A00

;;; ============================================================
;;; Selector module
;;; ============================================================

        RESOURCE_FILE "selector.res"

        .define QR_LOADSTRING res_string_status_loading_selector
        .define QR_FILENAME kPathnameSelector
        .include "../lib/bootstrap.s"

        ;; Ensure loader.starts at correct offset from start of file.
        .res    kSegmentLoaderOffset - (.sizeof(InstallAsQuit) + .sizeof(QuitRoutine))

        ;; Segments
        .include "loader.s"
        .include "../lib/invoker.s"
        .include "app.s"
        .include "alert_dialog.s"

        ;; Overlays
        .include "ovl_file_dialog.s"
        .include "ovl_file_copy.s"
