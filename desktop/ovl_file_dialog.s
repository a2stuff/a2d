;;; ============================================================
;;; Overlay for File Dialog (used by Copy/Add/Edit)
;;;
;;; Compiled as part of desktop.s
;;; ============================================================


.scope file_dialog
        .org ::kOverlayFileDialogAddress

        MLIEntry := main::MLIRelayImpl
        MGTKEntry := MGTKRelayImpl
        LETKEntry := LETKRelayImpl
        BTKEntry := BTKRelayImpl

;;; ============================================================

Exec:
        jmp     Start

;;; ============================================================

;;; Required proc definitions
MLIRelayImpl            := main::MLIRelayImpl
CheckMouseMoved         := main::CheckMouseMoved
YieldLoop               := main::YieldLoop
DetectDoubleClick       := main::StashCoordsAndDetectDoubleClick
ModifierDown            := main::ModifierDown
ShiftDown               := main::ShiftDown
AdjustVolumeNameCase    := main::AdjustVolumeNameCase
AdjustFileEntryCase     := main::AdjustFileEntryCase

;;; Required data definitions
buf_text := path_buf1

;;; Required macro definitions
        .include "../lib/file_dialog.s"
        .include "../lib/muldiv.s"

;;; ============================================================

        PAD_TO ::kOverlayFileDialogAddress + ::kOverlayFileDialogLength

.endscope ; file_dialog

file_dialog__Exec := file_dialog::Exec
