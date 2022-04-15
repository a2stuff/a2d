;;; ============================================================
;;; Overlay for File Copy
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc FileCopyOverlay
        .org ::kOverlayFileCopyAddress

        MGTKEntry := MGTKRelayImpl

.proc Init
        copy    #$80, file_dialog::dual_inputs_flag

        jsr     file_dialog::OpenWindow
        jsr     DrawControls
        jsr     file_dialog::DeviceOnLine
        jsr     file_dialog::ReadDir
        jsr     file_dialog::UpdateScrollbar
        jsr     file_dialog::UpdateDiskName
        jsr     file_dialog::DrawListEntries
        jsr     InstallSourceCallbackTable
        jsr     file_dialog::PrepPath
        jsr     file_dialog::RedrawInput

        copy    #$FF, line_edit_res::blink_ip_flag
        copy    #0, line_edit_res::allow_all_chars_flag
        jmp     file_dialog::EventLoop
.endproc

.proc InstallSourceCallbackTable
        ldx     jt_source_filename
:       lda     jt_source_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        lda     jt_source_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        dex
        bpl     :-

        lda     #0
        sta     path_buf0
        sta     file_dialog::focus_in_input2_flag
        rts
.endproc

.proc DrawControls
        lda     file_dialog_res::winfo::window_id
        jsr     file_dialog::SetPortForWindow
        param_call file_dialog::DrawTitleCentered, aux::label_copy_file
        param_call file_dialog::DrawInput1Label, source_filename_label
        param_call file_dialog::DrawInput2Label, destination_filename_label
        rts
.endproc

jt_source_filename:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry HandleOkSource
        jump_table_entry HandleCancel
        .assert * - jt_source_filename = file_dialog::kJumpTableSize+1, error, "Table size error"

jt_destination_filename:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry HandleOkDestination
        jump_table_entry HandleCancelDestination
        .assert * - jt_destination_filename = file_dialog::kJumpTableSize+1, error, "Table size error"

;;; ============================================================

.proc HandleOkSource
        jsr     file_dialog::f1::HideIP ; Switch

        ;; install destination field handlers
        ldx     jt_destination_filename
:       lda     jt_destination_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        lda     jt_destination_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        dex
        bpl     :-

        ;; set up flags for destination
        lda     #$80
        sta     file_dialog::only_show_dirs_flag
        sta     file_dialog::focus_in_input2_flag
        lda     file_dialog_res::selected_index
        sta     LD921
        lda     #$FF
        sta     file_dialog_res::selected_index
        jsr     file_dialog::DeviceOnLine
        jsr     file_dialog::ReadDir
        jsr     file_dialog::UpdateScrollbar
        jsr     file_dialog::UpdateDiskName

        jsr     file_dialog::DrawListEntries

        ;; Init destination path
        ldx     file_dialog::path_buf
:       lda     file_dialog::path_buf,x
        sta     path_buf1,x
        dex
        bpl     :-

        ;; Append filename from source to destination

        ldx     path_buf0
        beq     done

        ;; Find last slash
:       lda     path_buf0,x
        cmp     #'/'
        beq     :+
        dex
        bne     :-
:
        ;; Append to destination
        ldy     path_buf1
        iny
:       lda     path_buf0,x
        sta     path_buf1,y
        cpx     path_buf0
        beq     :+
        iny
        inx
        bne     :-
:       sty     path_buf1

done:   jsr     file_dialog::RedrawInput

        ;; Twiddle flags
        lda     line_edit_res::input_dirty_flag
        sta     input1_dirty_flag
        lda     input2_dirty_flag
        sta     line_edit_res::input_dirty_flag
        rts
.endproc

;;; ============================================================

.proc HandleOkDestination
        param_call file_dialog::VerifyValidNonVolumePath, path_buf0
        beq     :+
err:    lda     #ERR_INVALID_PATHNAME
        jmp     JUMP_TABLE_SHOW_ALERT
:
        jsr     ComparePathBufs
        bne     :+
        lda     #kErrBadReplacement
        jmp     JUMP_TABLE_SHOW_ALERT
:
        param_call file_dialog::VerifyValidNonVolumePath, path_buf1
        bne     err
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo_listbox
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo
        copy    #0, file_dialog::only_show_dirs_flag
        copy    #0, line_edit_res::blink_ip_flag
        jsr     file_dialog::UnsetCursorIBeam
        copy16  #path_buf0, $6
        copy16  #path_buf1, $8
        ldx     file_dialog::saved_stack
        txs
        return  #$00
.endproc

;;; ============================================================

.proc HandleCancel
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo_listbox
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo
        copy    #0, line_edit_res::blink_ip_flag
        jsr     file_dialog::UnsetCursorIBeam
        ldx     file_dialog::saved_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

.proc HandleCancelDestination
        jsr     file_dialog::f2::HideIP ; Switch

        ;; install source field handlers
        ldx     jt_source_filename
:       lda     jt_source_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        lda     jt_source_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        dex
        bpl     :-

        copy    #0, file_dialog::only_show_dirs_flag
        copy    #$FF, file_dialog_res::selected_index
        copy    #0, file_dialog::focus_in_input2_flag

        lda     line_edit_res::input_dirty_flag
        sta     input2_dirty_flag
        lda     input1_dirty_flag
        sta     line_edit_res::input_dirty_flag

        COPY_STRING path_buf0, file_dialog::path_buf

        jsr     file_dialog::StripPathBufSegment
        bit     line_edit_res::input_dirty_flag
        bpl     L726D

        ;; TODO: Understand how these paths differ.
        ;; If selection is "dirty", do this...
        jsr     file_dialog::DeviceOnLine
        lda     #0
        jsr     file_dialog::ScrollClipRect
        jsr     file_dialog::ReadDir
        jsr     file_dialog::UpdateScrollbar
        jsr     file_dialog::UpdateDiskName
        jsr     file_dialog::DrawListEntries
        jsr     file_dialog::RedrawInput
        rts

        ;; Otherwise do this...
L726D:  lda     file_dialog::path_buf
        bne     L7281

L7272:  jsr     file_dialog::DeviceOnLine
        lda     #0
        jsr     file_dialog::ScrollClipRect
        jsr     file_dialog::ReadDir
        lda     #$FF            ; clear selection
        bne     L7289           ; always

L7281:  jsr     file_dialog::ReadDir
        bcs     L7272
        lda     LD921

L7289:  sta     file_dialog_res::selected_index
        cmp     #$FF            ; if no selection...
        bne     :+              ; make scroll index 0
        lda     #$00
:       jsr     file_dialog::UpdateScrollbar2
        jsr     file_dialog::UpdateDiskName
        jsr     file_dialog::DrawListEntries
        jsr     file_dialog::f1::Update
        rts
.endproc

;;; ============================================================

.proc ComparePathBufs
        ;; Compare lengths
        lda     path_buf0
        cmp     path_buf1
        bne     done

        ;; Compare characters, case-insensitive
        tax
:       lda     path_buf0,x
        jsr     main::UpcaseChar
        sta     @char
        lda     path_buf1,x
        jsr     main::UpcaseChar
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     done
        dex
        bne     :-

done:   rts
.endproc

;;; ============================================================

        PAD_TO ::kOverlayFileCopyAddress + ::kOverlayFileCopyLength

.endproc ; FileCopyOverlay
