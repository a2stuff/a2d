;;; ============================================================
;;; Overlay for File Copy
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc file_copy_overlay
        .org $7000

.proc init
        jsr     file_dialog::create_common_dialog
        jsr     draw_controls
        jsr     file_dialog::device_on_line
        jsr     file_dialog::L5F5B
        jsr     file_dialog::update_scrollbar
        jsr     file_dialog::update_disk_name
        jsr     file_dialog::draw_list_entries
        jsr     install_source_callback_table
        jsr     file_dialog::jt_prep_path
        jsr     file_dialog::jt_redraw_input

        copy    #$FF, LD8EC
        jmp     file_dialog::event_loop
.endproc

.proc install_source_callback_table
        ldx     jt_source_filename
:       lda     jt_source_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        lda     jt_source_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        dex
        bpl     :-

        lda     #$80
        sta     file_dialog::L5104

        lda     #0
        sta     path_buf0
        sta     file_dialog::L51AE
        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        rts
.endproc

.proc draw_controls
        lda     winfo_file_dialog
        jsr     file_dialog::set_port_for_window
        addr_call file_dialog::L5E0A, file_dialog_res::copy_a_file_label
        addr_call file_dialog::L5E57, file_dialog_res::source_filename_label
        addr_call file_dialog::L5E6F, file_dialog_res::destination_filename_label
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::input1_rect
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::input2_rect
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        rts
.endproc

jt_source_filename:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry handle_ok_source
        jump_table_entry handle_cancel
        jump_table_entry file_dialog::blink_f1_ip
        jump_table_entry file_dialog::redraw_f1
        jump_table_entry file_dialog::strip_f1_path_segment
        jump_table_entry file_dialog::handle_f1_selection_change
        jump_table_entry file_dialog::prep_path_buf0
        jump_table_entry file_dialog::handle_f1_other_key
        jump_table_entry file_dialog::handle_f1_delete_key
        jump_table_entry file_dialog::handle_f1_left_key
        jump_table_entry file_dialog::handle_f1_right_key
        jump_table_entry file_dialog::handle_f1_meta_left_key
        jump_table_entry file_dialog::handle_f1_meta_right_key
        jump_table_entry file_dialog::handle_f1_click
        .assert * - jt_source_filename = file_dialog::kJumpTableSize+1, error, "Table size error"

jt_destination_filename:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry handle_ok_destination
        jump_table_entry handle_cancel_destination
        jump_table_entry file_dialog::blink_f2_ip
        jump_table_entry file_dialog::redraw_f2
        jump_table_entry file_dialog::strip_f2_path_segment
        jump_table_entry file_dialog::handle_f2_selection_change
        jump_table_entry file_dialog::prep_path_buf1
        jump_table_entry file_dialog::handle_f2_other_key
        jump_table_entry file_dialog::handle_f2_delete_key
        jump_table_entry file_dialog::handle_f2_left_key
        jump_table_entry file_dialog::handle_f2_right_key
        jump_table_entry file_dialog::handle_f2_meta_left_key
        jump_table_entry file_dialog::handle_f2_meta_right_key
        jump_table_entry file_dialog::handle_f2_click
        .assert * - jt_destination_filename = file_dialog::kJumpTableSize+1, error, "Table size error"

;;; ============================================================

.proc handle_ok_source
        lda     #1
        sta     path_buf2
        lda     #' '
        sta     path_buf2+1
        jsr     file_dialog::jt_redraw_input

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
        sta     file_dialog::L50A8
        sta     file_dialog::L51AE
        lda     selected_index
        sta     LD921
        lda     #$FF
        sta     selected_index
        jsr     file_dialog::device_on_line
        jsr     file_dialog::L5F5B
        jsr     file_dialog::update_scrollbar
        jsr     file_dialog::update_disk_name

        jsr     file_dialog::draw_list_entries

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
        and     #CHAR_MASK
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

done:   jsr     file_dialog::jt_redraw_input

        ;; Twiddle flags
        lda     LD8F0
        sta     LD8F1
        lda     LD8F2
        sta     LD8F0
        rts
.endproc

        ;; Unused
        .byte   0

;;; ============================================================

.proc handle_ok_destination
        addr_call file_dialog::L647C, path_buf0
        beq     :+
err:    lda     #ERR_INVALID_PATHNAME
        jsr     JUMP_TABLE_ALERT_0
        rts

:       addr_call file_dialog::L647C, path_buf1
        bne     err
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog_listbox
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog
        copy    #0, file_dialog::L50A8
        copy    #0, LD8EC
        jsr     file_dialog::set_cursor_pointer
        copy16  #path_buf0, $6
        copy16  #path_buf1, $8
        ldx     file_dialog::stash_stack
        txs
        return  #$00
.endproc

        ;; Unused
        .byte   0

;;; ============================================================

.proc handle_cancel
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog_listbox
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog
        lda     #0
        sta     LD8EC
        jsr     file_dialog::set_cursor_pointer
        ldx     file_dialog::stash_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

.proc handle_cancel_destination
        lda     #1
        sta     path_buf2
        lda     #' '
        sta     path_buf2+1
        jsr     file_dialog::jt_redraw_input

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
        copy    #0, file_dialog::L50A8
        copy    #$FF, selected_index
        copy    #0, file_dialog::L51AE

        lda     LD8F0
        sta     LD8F2
        lda     LD8F1
        sta     LD8F0

        ldx     path_buf0
:       lda     path_buf0,x
        sta     file_dialog::path_buf,x
        dex
        bpl     :-

        jsr     file_dialog::L5F49
        bit     LD8F0
        bpl     L726D
        jsr     file_dialog::device_on_line
        lda     #0
        jsr     file_dialog::scroll_clip_rect
        jsr     file_dialog::L5F5B
        jsr     file_dialog::update_scrollbar
        jsr     file_dialog::update_disk_name
        jsr     file_dialog::draw_list_entries
        jsr     file_dialog::jt_redraw_input
        jmp     L7295

L726D:  lda     file_dialog::path_buf
        bne     L7281
L7272:  jsr     file_dialog::device_on_line
        lda     #$00
        jsr     file_dialog::scroll_clip_rect
        jsr     file_dialog::L5F5B
        lda     #$FF
        bne     L7289
L7281:  jsr     file_dialog::L5F5B
        bcs     L7272
        lda     LD921
L7289:  sta     selected_index
        jsr     file_dialog::update_scrollbar2
        jsr     file_dialog::update_disk_name
        jsr     file_dialog::draw_list_entries
L7295:  rts
.endproc

;;; ============================================================

        PAD_TO $7800

.endproc ; file_copy_overlay
