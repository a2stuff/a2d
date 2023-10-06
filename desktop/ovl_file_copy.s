;;; ============================================================
;;; Overlay for File Copy
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        BEGINSEG OverlayFileCopy

.scope FileCopyOverlay

;;; Called back from file dialog's `Start`
.proc Init
        copy    #0, file_dialog::extra_controls_flag
        copy    #$80, file_dialog::only_show_dirs_flag

        param_call file_dialog::OpenWindow, label_copy_selection
        jsr     file_dialog::InitPathWithDefaultDevice
        jsr     file_dialog::UpdateListFromPath
        COPY_BYTES file_dialog::kJumpTableSize, jt_callbacks, file_dialog::jump_table

        jmp     file_dialog::EventLoop
.endproc ; Init

jt_callbacks:
        jmp     HandleOK
        jmp     HandleCancel
        .assert * - jt_callbacks = file_dialog::kJumpTableSize, error, "Table size error"

;;; ============================================================

.proc HandleOK
        param_call file_dialog::GetPath, path_buf0

        jsr     file_dialog::CloseWindow
        copy16  #path_buf0, $6
        ldx     file_dialog::saved_stack
        txs
        return  #$00
.endproc ; HandleOK

;;; ============================================================

.proc HandleCancel
        jsr     file_dialog::CloseWindow
        ldx     file_dialog::saved_stack
        txs
        return  #$FF
.endproc ; HandleCancel

;;; ============================================================

.endscope ; FileCopyOverlay

        ENDSEG OverlayFileCopy
