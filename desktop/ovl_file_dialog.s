;;; ============================================================
;;; Overlay for File Dialog (used by Copy/Add/Edit)
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        BEGINSEG OverlayFileDialog

.scope file_dialog

        MLIEntry := main::MLIRelayImpl
        MGTKEntry := MGTKRelayImpl
        LETKEntry := LETKRelayImpl
        BTKEntry := BTKRelayImpl

;;; ============================================================

;;; Required proc definitions
CheckMouseMoved         := main::CheckMouseMoved
SystemTask               := main::SystemTask
DetectDoubleClick       := main::StashCoordsAndDetectDoubleClick
AdjustVolumeNameCase    := main::AdjustVolumeNameCase
AdjustFileEntryCase     := main::AdjustFileEntryCase

        .include "../lib/file_dialog.s"

;;; ============================================================

.endscope ; file_dialog

        ENDSEG OverlayFileDialog
