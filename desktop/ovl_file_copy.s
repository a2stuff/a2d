;;; ============================================================
;;; Overlay for File Copy
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc FileCopyOverlay
        .org $7000

.proc Init
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

        copy    #$FF, blink_ip_flag
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

        copy    #$80, file_dialog::dual_inputs_flag

        lda     #0
        sta     path_buf0
        sta     file_dialog::focus_in_input2_flag
        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        rts
.endproc

.proc DrawControls
        lda     winfo_file_dialog::window_id
        jsr     file_dialog::SetPortForWindow
        param_call file_dialog::DrawTitleCentered, aux::label_copy_file
        param_call file_dialog::DrawInput1Label, file_dialog_res::source_filename_label
        param_call file_dialog::DrawInput2Label, file_dialog_res::destination_filename_label
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::input1_rect
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::input2_rect
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        rts
.endproc

jt_source_filename:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry HandleOkSource
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
        .assert * - jt_source_filename = file_dialog::kJumpTableSize+1, error, "Table size error"

jt_destination_filename:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry HandleOkDestination
        jump_table_entry HandleCancelDestination
        jump_table_entry file_dialog::BlinkF2IP
        jump_table_entry file_dialog::RedrawF2
        jump_table_entry file_dialog::StripF2PathSegment
        jump_table_entry file_dialog::HandleF2SelectionChange
        jump_table_entry file_dialog::PrepPathInput2
        jump_table_entry file_dialog::HandleF2OtherKey
        jump_table_entry file_dialog::HandleF2DeleteKey
        jump_table_entry file_dialog::HandleF2LeftKey
        jump_table_entry file_dialog::HandleF2RightKey
        jump_table_entry file_dialog::HandleF2MetaLeftKey
        jump_table_entry file_dialog::HandleF2MetaRightKey
        jump_table_entry file_dialog::HandleF2Click
        .assert * - jt_destination_filename = file_dialog::kJumpTableSize+1, error, "Table size error"

;;; ============================================================

.proc HandleOkSource
        jsr     file_dialog::MoveIPToEndF1

        copy    #1, path_buf2
        copy    #' ', path_buf2+1
        jsr     file_dialog::RedrawInput

        ;; install destination handlers
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
        lda     file_dialog_res2::selected_index
        sta     LD921
        lda     #$FF
        sta     file_dialog_res2::selected_index
        jsr     file_dialog::DeviceOnLine
        jsr     file_dialog::ReadDir
        jsr     file_dialog::UpdateScrollbar
        jsr     file_dialog::UpdateDiskName

        jsr     file_dialog::DrawListEntries

        ldx     file_dialog::path_buf
:       lda     file_dialog::path_buf,x
        sta     path_buf1,x
        dex
        bpl     :-

        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1

        ldx     path_buf0
        beq     done

        ;; Find last slash
:       lda     path_buf0,x
        cmp     #'/'
        beq     :+
        dex
        bne     :-
:       ldy     #2
        dex

        ;; Copy filename into path_buf2
:       cpx     path_buf0
        beq     done
        inx
        lda     path_buf0,x
        sta     path_buf2,y
        inc     path_buf2
        iny
        jmp     :-

done:   jsr     file_dialog::RedrawInput

        ;; Twiddle flags
        lda     input_dirty_flag
        sta     input1_dirty_flag
        lda     input2_dirty_flag
        sta     input_dirty_flag
        rts
.endproc

        ;; Unused
        .byte   0

;;; ============================================================

.proc HandleOkDestination
        param_call file_dialog::VerifyValidPath, path_buf0
        beq     :+
err:    lda     #ERR_INVALID_PATHNAME
        jsr     JUMP_TABLE_SHOW_ALERT
        rts

:       param_call file_dialog::VerifyValidPath, path_buf1
        bne     err
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog_listbox
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog
        copy    #0, file_dialog::only_show_dirs_flag
        copy    #0, blink_ip_flag
        jsr     file_dialog::UnsetCursorIBeam
        copy16  #path_buf0, $6
        copy16  #path_buf1, $8
        ldx     file_dialog::saved_stack
        txs
        return  #$00
.endproc

        ;; Unused
        .byte   0

;;; ============================================================

.proc HandleCancel
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog_listbox
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog
        copy    #0, blink_ip_flag
        jsr     file_dialog::UnsetCursorIBeam
        ldx     file_dialog::saved_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

.proc HandleCancelDestination
        jsr     file_dialog::MoveIPToEndF2

        copy    #1, path_buf2
        copy    #' ', path_buf2+1
        jsr     file_dialog::RedrawInput

        ldx     jt_source_filename
:       lda     jt_source_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        lda     jt_source_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        dex
        bpl     :-

        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        copy    #0, file_dialog::only_show_dirs_flag
        copy    #$FF, file_dialog_res2::selected_index
        copy    #0, file_dialog::focus_in_input2_flag

        lda     input_dirty_flag
        sta     input2_dirty_flag
        lda     input1_dirty_flag
        sta     input_dirty_flag

        COPY_STRING path_buf0, file_dialog::path_buf

        jsr     file_dialog::StripPathSegment
        bit     input_dirty_flag
        bpl     L726D
        jsr     file_dialog::DeviceOnLine
        lda     #0
        jsr     file_dialog::ScrollClipRect
        jsr     file_dialog::ReadDir
        jsr     file_dialog::UpdateScrollbar
        jsr     file_dialog::UpdateDiskName
        jsr     file_dialog::DrawListEntries
        jsr     file_dialog::RedrawInput
        jmp     L7295

L726D:  lda     file_dialog::path_buf
        bne     L7281
L7272:  jsr     file_dialog::DeviceOnLine
        lda     #$00
        jsr     file_dialog::ScrollClipRect
        jsr     file_dialog::ReadDir
        lda     #$FF
        bne     L7289
L7281:  jsr     file_dialog::ReadDir
        bcs     L7272
        lda     LD921
L7289:  sta     file_dialog_res2::selected_index
        cmp     #$FF            ; if no selection...
        bne     :+              ; make scroll index 0
        lda     #$00
:       jsr     file_dialog::UpdateScrollbar2
        jsr     file_dialog::UpdateDiskName
        jsr     file_dialog::DrawListEntries
L7295:  rts
.endproc

;;; ============================================================

        PAD_TO $7800

.endproc ; FileCopyOverlay
