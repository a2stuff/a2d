;;; ============================================================
;;; Overlay for File Dialog (used by Copy/Delete/Add/Edit)
;;;
;;; Compiled as part of desktop.s
;;; ============================================================


.scope file_dialog
        .org $5000

;;; ============================================================

Exec:
        jmp     Start

;;; ============================================================

;;; Required proc definitions
MLIRelayImpl            := main::MLIRelayImpl
CheckMouseMoved         := main::CheckMouseMoved
YieldLoop               := main::YieldLoop
DetectDoubleClick       := main::StashCoordsAndDetectDoubleClick
ButtonEventLoop         := ButtonEventLoopRelay
ModifierDown            := main::ModifierDown
AdjustVolumeNameCase    := main::AdjustVolumeNameCase
AdjustFileEntryCase     := main::AdjustFileEntryCase

;;; Required data definitions
buf_input1_left := path_buf0
buf_input2_left := path_buf1
buf_input_right := path_buf2

;;; Required macro definitions
.define LIB_MGTK_CALL MGTK_RELAY_CALL
.define LIB_MLI_CALL MLI_RELAY_CALL

        .define FD_EXTENDED 1
        .include "../lib/file_dialog.s"
        .include "../lib/muldiv.s"

;;; ============================================================

        PAD_TO $7000

.endscope ; file_dialog

file_dialog__Exec := file_dialog::Exec

.undefine LIB_MGTK_CALL
.undefine LIB_MLI_CALL
