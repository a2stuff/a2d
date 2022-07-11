;;; ============================================================
;;; Overlay for File Dialog (used by Copy/Delete/Add/Edit)
;;;
;;; Compiled as part of desktop.s
;;; ============================================================


.scope file_dialog
        .org ::kOverlayFileDialogAddress

        MLIEntry := main::MLIRelayImpl
        MGTKEntry := MGTKRelayImpl
        LETKEntry := LETKRelayImpl

;;; ============================================================

Exec:
        jmp     Start

;;; ============================================================

;;; Required proc definitions
MLIRelayImpl            := main::MLIRelayImpl
CheckMouseMoved         := main::CheckMouseMoved
YieldLoop               := main::YieldLoop
DetectDoubleClick       := main::StashCoordsAndDetectDoubleClick
ButtonClick             := main::ButtonClick
ButtonFlash             := main::ButtonFlash
ModifierDown            := main::ModifierDown
ShiftDown               := main::ShiftDown
AdjustVolumeNameCase    := main::AdjustVolumeNameCase
AdjustFileEntryCase     := main::AdjustFileEntryCase

;;; Required data definitions
buf_input1 := path_buf0
buf_input2 := path_buf1

;;; Required macro definitions
        .include "../lib/file_dialog.s"
        .include "../lib/muldiv.s"

;;; ============================================================

        PAD_TO ::kOverlayFileDialogAddress + ::kOverlayFileDialogLength

.endscope ; file_dialog

file_dialog__Exec := file_dialog::Exec
