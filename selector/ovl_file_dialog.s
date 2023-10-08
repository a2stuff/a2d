;;; ============================================================
;;; Run a Program File Picker Dialog - Overlay #1
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        BEGINSEG OverlayFileDialog

.scope file_dialog
        .org ::OVERLAY_ADDR

        BTKEntry := app::BTKEntry

;;; ============================================================

ep_init:
        tsx
        stx     saved_stack

        jsr     Init
        param_call OpenWindow, app::str_run_a_program
        jsr     InitPathWithDefaultDevice
        jsr     UpdateListFromPath
        jmp     EventLoop

;;; ============================================================


ep_loop:
        jmp     EventLoop

;;; ============================================================

.params getwinport_params
window_id:     .byte   0
a_grafport:    .addr   window_grafport
.endparams

window_grafport:
        .tag    MGTK::GrafPort

buf_path:
        .res    ::kPathBufferSize, 0

saved_stack:
        .byte   0

;;; ============================================================
;;; File Picker Dialog

        .include "../lib/file_dialog_res.s"

;;; ============================================================

.proc HandleOK
        param_call GetPath, buf_path

        ldx     saved_stack
        txs
        ldy     #<buf_path
        ldx     #>buf_path
        return  #$00
.endproc ; HandleOK

;;; ============================================================

.proc HandleCancel
        jsr     CloseWindow
        ldx     saved_stack
        txs
        return  #$FF
.endproc ; HandleCancel

;;; ============================================================

;;; Required proc definitions:
YieldLoop               := app::YieldLoop
DetectDoubleClick       := app::DetectDoubleClick
AdjustVolumeNameCase    := app::AdjustVolumeNameCase
AdjustFileEntryCase     := app::AdjustFileEntryCase
ReadSetting             := app::ReadSetting
Multiply_16_8_16        := app::Multiply_16_8_16
Divide_16_8_16          := app::Divide_16_8_16

        .include "../lib/file_dialog.s"
        .include "../lib/mouse_moved.s"

;;; ============================================================

.endscope ; file_dialog

file_dialog_init   := file_dialog::ep_init
file_dialog_loop   := file_dialog::ep_loop

        ENDSEG OverlayFileDialog
        .assert * <= $BF00, error, "Overwrites ProDOS Global Page"
