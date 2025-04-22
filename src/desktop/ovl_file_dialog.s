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
        LBTKEntry := LBTKRelayImpl

;;; ============================================================

        .include "../lib/file_dialog.s"

;;; ============================================================

.endscope ; file_dialog

        ENDSEG OverlayFileDialog
