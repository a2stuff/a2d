;;; ============================================================
;;; Overlay for File Delete
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc file_delete_overlay
        .org $7000

.proc init
        jsr     file_dialog::open_window
        jsr     draw_controls
        jsr     file_dialog::device_on_line
        jsr     file_dialog::read_dir
        jsr     file_dialog::update_scrollbar
        jsr     file_dialog::update_disk_name
        jsr     file_dialog::draw_list_entries
        jsr     install_callback_table
        jsr     file_dialog::jt_prep_path
        jsr     file_dialog::jt_redraw_input

        copy    #$FF, LD8EC
        jmp     file_dialog::event_loop
.endproc

.proc install_callback_table
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

.proc draw_controls
        lda     winfo_file_dialog
        jsr     file_dialog::set_port_for_window
        param_call file_dialog::draw_title_centered, aux::label_delete_file
        param_call file_dialog::draw_input1_label, file_dialog_res::file_to_delete_label
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::input1_rect
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        rts
.endproc

jt_filename:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry handle_ok
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
        .assert * - jt_filename = file_dialog::kJumpTableSize+1, error, "Table size error"


.proc handle_ok
        param_call file_dialog::L647C, path_buf0
        beq     :+
        lda     #ERR_INVALID_PATHNAME
        jsr     JUMP_TABLE_SHOW_ALERT
        rts

:       MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog_listbox
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog
        lda     #0
        sta     LD8EC
        jsr     file_dialog::set_cursor_pointer
        copy16  #path_buf0, $6
        ldx     file_dialog::stash_stack
        txs
        lda     #0
        rts
.endproc

        ;; Unused
        .byte   0

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

        PAD_TO $7800
.endproc ; file_delete_overlay
