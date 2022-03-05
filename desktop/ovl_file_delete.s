;;; ============================================================
;;; Overlay for File Delete
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc FileDeleteOverlay
        .org $7000

        MGTKEntry := MGTKRelayImpl

.proc Init
        jsr     file_dialog::OpenWindow
        jsr     DrawControls
        jsr     file_dialog::DeviceOnLine
        jsr     file_dialog::ReadDir
        jsr     file_dialog::UpdateScrollbar
        jsr     file_dialog::UpdateDiskName
        jsr     file_dialog::DrawListEntries
        jsr     InstallCallbackTable
        jsr     file_dialog::PrepPath
        jsr     file_dialog::RedrawInput

        copy    #$FF, blink_ip_flag
        copy    #0, input_allow_all_chars_flag
        jmp     file_dialog::EventLoop
.endproc

.proc InstallCallbackTable
        ldx     jt_filename
:       lda     jt_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        lda     jt_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        dex
        bpl     :-

        lda     #0
        sta     path_buf0
        sta     file_dialog::focus_in_input2_flag

        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        rts
.endproc

.proc DrawControls
        lda     file_dialog_res::winfo::window_id
        jsr     file_dialog::SetPortForWindow
        param_call file_dialog::DrawTitleCentered, aux::label_delete_file
        param_call file_dialog::DrawInput1Label, file_to_delete_label
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, file_dialog_res::input1_rect
        MGTK_CALL MGTK::InitPort, main_grafport
        MGTK_CALL MGTK::SetPort, main_grafport
        rts
.endproc

jt_filename:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry HandleOk
        jump_table_entry HandleCancel
        jump_table_entry file_dialog::BlinkF1IP
        jump_table_entry file_dialog::RedrawF1
        jump_table_entry file_dialog::StripF1PathSegment
        jump_table_entry file_dialog::HandleF1SelectionChange
        jump_table_entry file_dialog::PrepPathInput1
        jump_table_entry file_dialog::HandleF1OtherKey
        jump_table_entry file_dialog::HandleF1DeleteKey
        jump_table_entry file_dialog::HandleF1LeftKey
        jump_table_entry file_dialog::HandleF1RightKey
        jump_table_entry file_dialog::HandleF1MetaLeftKey
        jump_table_entry file_dialog::HandleF1MetaRightKey
        jump_table_entry file_dialog::HandleF1Click
        .assert * - jt_filename = file_dialog::kJumpTableSize+1, error, "Table size error"


.proc HandleOk
        param_call file_dialog::VerifyValidNonVolumePath, path_buf0
        beq     :+
        lda     #ERR_INVALID_PATHNAME
        jsr     JUMP_TABLE_SHOW_ALERT
        rts

:       MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo_listbox
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo
        copy    #0, blink_ip_flag
        jsr     file_dialog::UnsetCursorIBeam
        copy16  #path_buf0, $6
        ldx     file_dialog::saved_stack
        txs
        lda     #0
        rts
.endproc

        ;; Unused
        .byte   0

.proc HandleCancel
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo_listbox
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo
        copy    #0, blink_ip_flag
        jsr     file_dialog::UnsetCursorIBeam
        ldx     file_dialog::saved_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

        PAD_TO $7800
.endproc ; FileDeleteOverlay
