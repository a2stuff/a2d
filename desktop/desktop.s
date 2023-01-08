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

;;; ============================================================
;;; File Structure
;;; ============================================================
;;; DeskTop is broken into various segments plus dynamically
;;; loaded overlays, all stored in one file. This section
;;; defines the file offsets, load addresses and lengths of each
;;; segment and offset

        ;; Bootstrap is at $0-$200 in file
        kLoaderOffset = $200

        ;; Segments
        INITSEG kLoaderOffset
        DEFSEG SegmentLoader,      $2000, $0300
        DEFSEG SegmentDeskTopAux,  $4000, $8000
        DEFSEG SegmentDeskTopLC1A, $D000, $1D00
        DEFSEG SegmentDeskTopLC1B, $FB00, $0500
        DEFSEG SegmentDeskTopMain, $4000, $7F00
        DEFSEG SegmentInitializer, $0800, $0A00
        DEFSEG SegmentInvoker,     $0290, $0160

        ;; Dynamically loaded overlays
        DEFSEG OverlayFormatErase,  $0800, $1200
        DEFSEG OverlayShortcutPick, $9000, $0A00
        DEFSEG OverlayFileDialog,   $5000, $1100
        DEFSEG OverlayFileCopy,     $7000, $0100
        DEFSEG OverlayShortcutEdit, $7000, $0300

;;; These pseudo-overlays restore DeskTop after overlays are used

kOverlayDeskTopRestore1Length = $2800
kOverlayDeskTopRestore1Address = $5000
kOverlayDeskTopRestore1Offset = kSegmentDeskTopMainOffset + (kOverlayDeskTopRestore1Address - kSegmentDeskTopMainAddress)

kOverlayDeskTopRestore2Length = $1000
kOverlayDeskTopRestore2Address = $9000
kOverlayDeskTopRestore2Offset = kSegmentDeskTopMainOffset + (kOverlayDeskTopRestore2Address - kSegmentDeskTopMainAddress)

;;; ============================================================
;;; DeskTop module
;;; ============================================================

        RESOURCE_FILE "desktop.res"

        .include "../desktop/desktop.inc"
        .include "internal.inc"

        .define QR_LOADSTRING .sprintf(res_string_splash_string, kDeskTopProductName)
        .define QR_FILENAME kFilenameDeskTop
        .include "../lib/bootstrap.s"

        ;; Ensure loader.starts at correct offset from start of file.
        .res    kSegmentLoaderOffset - (.sizeof(InstallAsQuit) + .sizeof(QuitRoutine))

        ;; Segments
        .include "loader.s"
        .include "auxmem.s"
        .include "lc.s"
        .include "main.s"
        .include "init.s"
        .include "../lib/invoker.s"

        ;; Overlays
        .include "ovl_format_erase.s"
        .include "ovl_selector_pick.s"
        .include "ovl_file_dialog.s"
        .include "ovl_file_copy.s"
        .include "ovl_selector_edit.s"
