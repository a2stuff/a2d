;;; ============================================================
;;; Overlay for File Copy
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc FileCopyOverlay
        .org ::kOverlayFileCopyAddress

        MGTKEntry := MGTKRelayImpl

;;; Called back from file dialog's `Start`
.proc Init
        copy    #$80, file_dialog::dual_inputs_flag

        jsr     file_dialog::OpenWindow
        jsr     DrawControls
        jsr     file_dialog::DeviceOnLine
        jsr     file_dialog::UpdateListFromPath
        jsr     InstallSourceCallbackTable
        jsr     file_dialog::PrepPath
        jsr     file_dialog::Activate

        copy    #$FF, line_edit_res::blink_ip_flag
        jmp     file_dialog::EventLoop
.endproc

.proc InstallSourceCallbackTable
        COPY_BYTES file_dialog::kJumpTableSize, jt_source_filename, file_dialog::jump_table

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
        jmp     HandleOkSource
        jmp     HandleCancel
        .assert * - jt_source_filename = file_dialog::kJumpTableSize, error, "Table size error"

jt_destination_filename:
        jmp     HandleOkDestination
        jmp     HandleCancelDestination
        .assert * - jt_destination_filename = file_dialog::kJumpTableSize, error, "Table size error"

;;; ============================================================

.proc HandleOkSource
        param_call file_dialog::VerifyValidNonVolumePath, path_buf0
    IF_NE
        lda     #ERR_INVALID_PATHNAME
        jmp     JUMP_TABLE_SHOW_ALERT
    END_IF

        jsr     file_dialog::Deactivate

        ;; install destination field handlers
        COPY_BYTES file_dialog::kJumpTableSize, jt_destination_filename, file_dialog::jump_table

        ;; set up flags for destination
        lda     #$80
        sta     file_dialog::only_show_dirs_flag
        sta     file_dialog::focus_in_input2_flag
        lda     file_dialog_res::selected_index
        sta     saved_src_index
        lda     #$FF
        jsr     file_dialog::SetSelectedIndex
        jsr     file_dialog::DeviceOnLine
        jsr     file_dialog::UpdateListFromPath

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
        beq     done            ; always
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

done:   jsr     file_dialog::Activate

        ;; Twiddle flags
        lda     line_edit_res::input_dirty_flag
        sta     input1_dirty_flag
        lda     input2_dirty_flag
        sta     line_edit_res::input_dirty_flag
        rts
.endproc

;;; ============================================================

.proc HandleOkDestination
        param_call file_dialog::VerifyValidNonVolumePath, path_buf1
    IF_NE
        lda     #ERR_INVALID_PATHNAME
        jmp     JUMP_TABLE_SHOW_ALERT
    END_IF

        jsr     ComparePathBufs
    IF_EQ
        lda     #kErrBadReplacement
        jmp     JUMP_TABLE_SHOW_ALERT
    END_IF

        jsr     file_dialog::CloseWindow
        copy16  #path_buf0, $6
        copy16  #path_buf1, $8
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

.proc HandleCancelDestination
        jsr     file_dialog::Deactivate

        ;; install source field handlers
        COPY_BYTES file_dialog::kJumpTableSize, jt_source_filename, file_dialog::jump_table

        copy    #0, file_dialog::only_show_dirs_flag
        lda     #$FF
        jsr     file_dialog::SetSelectedIndex
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
        jsr     file_dialog::UpdateListFromPath
        jsr     file_dialog::Activate
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
        lda     saved_src_index

L7289:
        jsr     file_dialog::SetSelectedIndex
        cmp     #$FF            ; if no selection...
        bne     :+              ; make scroll index 0
        lda     #$00
:       jsr     file_dialog::UpdateScrollbarWithIndex
        jsr     file_dialog::UpdateDiskName
        jsr     file_dialog::DrawListEntries
        jsr     file_dialog::Activate
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
