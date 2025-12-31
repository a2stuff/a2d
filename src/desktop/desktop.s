        .include "../config.inc"

        .include "apple2.inc"
        .include "apple2.mac"
        .include "opcodes.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../inc/smartport.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/icontk.inc"
        .include "../toolkits/letk.inc"
        .include "../toolkits/btk.inc"
        .include "../toolkits/lbtk.inc"
        .include "../toolkits/optk.inc"
        .include "../lib/alert_dialog.inc"
        .include "../common.inc"
        .include .concat("../desk_acc/res/filenames.res.", kBuildLang)

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
        DEFSEG SegmentLoader,      $2000, $0200
        DEFSEG SegmentDeskTopAux,  $4000, $8000
        DEFSEG SegmentDeskTopLC,   $D000, $2200
        DEFSEG SegmentDeskTopMain, $4000, $6D00
        DEFSEG SegmentInitializer, $0800, $0800
        DEFSEG SegmentInvoker,     $0290, $0160

        ;; Dynamically loaded overlays
        DEFSEG OverlayFormatErase,  $0800, $0F00
        DEFSEG OverlayShortcutPick, $5000, $0800
        DEFSEG OverlayFileDialog,   $6000, $0A00
        DEFSEG OverlayFileCopy,     $7000, $0100
        DEFSEG OverlayShortcutEdit, $7000, $0300

;;; These pseudo-overlays restore DeskTop after overlays are used

;;; Restore after OverlayShortcutPick has been used
kOverlayDeskTopRestoreSPLength = kOverlayShortcutPickLength
kOverlayDeskTopRestoreSPAddress = kOverlayShortcutPickAddress
kOverlayDeskTopRestoreSPOffset = kSegmentDeskTopMainOffset + (kOverlayDeskTopRestoreSPAddress - kSegmentDeskTopMainAddress)

;;; Restore after OverlayFileDialog and either OverlayFileCopy or OverlayShortcutEdit has been used
kOverlayDeskTopRestoreFDLength = $1400
kOverlayDeskTopRestoreFDAddress = kOverlayFileDialogAddress
kOverlayDeskTopRestoreFDOffset = kSegmentDeskTopMainOffset + (kOverlayDeskTopRestoreFDAddress - kSegmentDeskTopMainAddress)
.assert (kOverlayFileCopyAddress + kOverlayFileCopyLength) <= (kOverlayDeskTopRestoreFDAddress + kOverlayDeskTopRestoreFDLength), error, "restore coverage"
.assert (kOverlayShortcutEditAddress + kOverlayShortcutEditLength) <= (kOverlayDeskTopRestoreFDAddress + kOverlayDeskTopRestoreFDLength), error, "restore coverage"

;;; Restore after buffer is used by Desk Accessories
kOverlayDeskTopRestoreBufferLength = kOverlayBufferSize
kOverlayDeskTopRestoreBufferAddress = OVERLAY_BUFFER
kOverlayDeskTopRestoreBufferOffset = kSegmentDeskTopMainOffset + (kOverlayDeskTopRestoreBufferAddress - kSegmentDeskTopMainAddress)

;;; ============================================================
;;; DeskTop module
;;; ============================================================

        RESOURCE_FILE "desktop.res"

        .include "../desktop/desktop.inc"
        .include "internal.inc"

        .define QR_LOADSTRING res_string_status_loading_desktop
        .define QR_FILENAME kPathnameDeskTop
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
