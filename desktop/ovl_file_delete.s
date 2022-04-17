;;; ============================================================
;;; Overlay for File Delete
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc FileDeleteOverlay
        .org ::kOverlayFileDeleteAddress

        MGTKEntry := MGTKRelayImpl

;;; Called back from file dialog's `Start`
.proc Init
        jsr     file_dialog::OpenWindow
        jsr     DrawControls
        jsr     file_dialog::DeviceOnLine
        jsr     file_dialog::UpdateListFromPath
        jsr     InstallCallbackTable
        jsr     file_dialog::PrepPath
        jsr     file_dialog::RedrawInput

        copy    #$FF, line_edit_res::blink_ip_flag
        jmp     file_dialog::EventLoop
.endproc

.proc InstallCallbackTable
        COPY_BYTES file_dialog::kJumpTableSize, jt_filename, file_dialog::jump_table

        lda     #0
        sta     path_buf0
        sta     file_dialog::focus_in_input2_flag

        rts
.endproc

.proc DrawControls
        lda     file_dialog_res::winfo::window_id
        jsr     file_dialog::SetPortForWindow
        param_call file_dialog::DrawTitleCentered, aux::label_delete_file
        param_call file_dialog::DrawInput1Label, file_to_delete_label
        rts
.endproc

jt_filename:
        jmp     HandleOk
        jmp     HandleCancel
        .assert * - jt_filename = file_dialog::kJumpTableSize, error, "Table size error"

.proc HandleOk
        param_call file_dialog::VerifyValidNonVolumePath, path_buf0
        beq     :+
        lda     #ERR_INVALID_PATHNAME
        jsr     JUMP_TABLE_SHOW_ALERT
        rts
:
        jsr     file_dialog::CloseWindow
        copy16  #path_buf0, $6
        ldx     file_dialog::saved_stack
        txs
        lda     #0
        rts
.endproc

.proc HandleCancel
        jsr     file_dialog::CloseWindow
        ldx     file_dialog::saved_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

        PAD_TO ::kOverlayFileDeleteAddress + ::kOverlayFileDeleteLength
.endproc ; FileDeleteOverlay
