;;; ============================================================
;;; Overlay for File Copy
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.scope FileCopyOverlay
        .org ::kOverlayFileCopyAddress

;;; Called back from file dialog's `Start`
.proc Init
        copy    #0, file_dialog::extra_controls_flag
        copy    #$80, file_dialog::only_show_dirs_flag

        copy    #0, path_buf1

        jsr     file_dialog::OpenWindow
        param_call file_dialog::DrawTitleCentered, aux::label_copy_selection
        jsr     file_dialog::DeviceOnLine
        jsr     file_dialog::UpdateListFromPath
        COPY_BYTES file_dialog::kJumpTableSize, jt_callbacks, file_dialog::jump_table

        jmp     file_dialog::EventLoop
.endproc

jt_callbacks:
        jmp     HandleOk
        jmp     HandleCancel
        .assert * - jt_callbacks = file_dialog::kJumpTableSize, error, "Table size error"

;;; ============================================================

.proc HandleOk
        param_call file_dialog::GetPath, path_buf1

        jsr     file_dialog::CloseWindow
        copy16  #path_buf1, $6
        ldx     file_dialog::saved_stack
        txs
        return  #$00
.endproc

;;; ============================================================

.proc HandleCancel
        jsr     file_dialog::CloseWindow
        ldx     file_dialog::saved_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

        PAD_TO ::kOverlayFileCopyAddress + ::kOverlayFileCopyLength

.endscope ; FileCopyOverlay
