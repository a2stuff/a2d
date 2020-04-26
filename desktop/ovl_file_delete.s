;;; ============================================================
;;; Overlay for File Delete
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc file_delete_overlay
        .org $7000

L7000:  jsr     file_dialog::create_common_dialog
        jsr     L704D
        jsr     file_dialog::device_on_line
        jsr     file_dialog::L5F5B
        jsr     file_dialog::L6161
        jsr     file_dialog::L61B1
        jsr     file_dialog::draw_list_entries
        jsr     L7026
        jsr     file_dialog::jt_prep_path
        jsr     file_dialog::jt_redraw_input
        lda     #$FF
        sta     LD8EC
        jmp     file_dialog::event_loop

L7026:  ldx     jt_filename
L7029:  lda     jt_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        lda     jt_filename+1,x
        sta     file_dialog::jump_table,x
        dex
        dex
        bpl     L7029
        lda     #$00
        sta     path_buf0
        sta     file_dialog::L51AE
        lda     #$01
        sta     path_buf2
        lda     #$06
        sta     path_buf2+1     ; ???
        rts

L704D:  lda     winfo_file_dialog
        jsr     file_dialog::set_port_for_window
        addr_call file_dialog::L5E0A, delete_a_file_label
        addr_call file_dialog::L5E57, file_to_delete_label
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, common_input1_rect
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

jt_filename:
        .byte $29               ; length of the following data block
        jump_table_entry L70B1
        jump_table_entry L70EA
        jump_table_entry file_dialog::blink_f1_ip
        jump_table_entry file_dialog::redraw_f1
        jump_table_entry file_dialog::strip_f1_path_segment
        jump_table_entry file_dialog::jt_handle_f1_tbd05
        jump_table_entry file_dialog::prep_path_buf0
        jump_table_entry file_dialog::handle_f1_other_key
        jump_table_entry file_dialog::handle_f1_delete_key
        jump_table_entry file_dialog::handle_f1_left_key
        jump_table_entry file_dialog::handle_f1_right_key
        jump_table_entry file_dialog::handle_f1_meta_left_key
        jump_table_entry file_dialog::handle_f1_meta_right_key
        jump_table_entry file_dialog::handle_f1_click


L70B1:  addr_call file_dialog::L647C, path_buf0
        beq     L70C0
        lda     #ERR_INVALID_PATHNAME
        jsr     JUMP_TABLE_ALERT_0
        rts

L70C0:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog_listbox
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog
        lda     #0
        sta     LD8EC
        jsr     file_dialog::set_cursor_pointer
        copy16  #path_buf0, $6
        ldx     file_dialog::stash_stack
        txs
        lda     #0
        rts

        .byte   0

L70EA:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog_listbox
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog
        lda     #0
        sta     LD8EC
        jsr     file_dialog::set_cursor_pointer
        ldx     file_dialog::stash_stack
        txs
        return  #$FF

;;; ============================================================

        PAD_TO $7800
.endproc ; file_delete_overlay
