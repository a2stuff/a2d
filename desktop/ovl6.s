;;; ============================================================
;;; Overlay for File Delete
;;; ============================================================

.proc file_delete_overlay
        .org $7000

L7000:  jsr     common_overlay::create_common_dialog
        jsr     L704D
        jsr     common_overlay::device_on_line
        jsr     common_overlay::L5F5B
        jsr     common_overlay::L6161
        jsr     common_overlay::L61B1
        jsr     common_overlay::L606D
        jsr     L7026
        jsr     common_overlay::jt_prep_path
        jsr     common_overlay::jt_redraw_input
        lda     #$FF
        sta     LD8EC
        jmp     common_overlay::L5106

L7026:  ldx     jt_filename
L7029:  lda     jt_filename+1,x
        sta     common_overlay::jump_table,x
        dex
        lda     jt_filename+1,x
        sta     common_overlay::jump_table,x
        dex
        dex
        bpl     L7029
        lda     #$00
        sta     path_buf0
        sta     common_overlay::L51AE
        lda     #$01
        sta     path_buf2
        lda     #$06
        sta     path_buf2+1     ; ???
        rts

L704D:  lda     winfo_entrydlg
        jsr     common_overlay::set_port_for_window
        addr_call common_overlay::L5E0A, delete_a_file_label
        addr_call common_overlay::L5E57, file_to_delete_label
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, common_input1_rect
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

jt_filename:
        .byte $29               ; length of the following data block
        jump_table_entry L70B1
        jump_table_entry L70EA
        jump_table_entry common_overlay::blink_f1_ip
        jump_table_entry common_overlay::redraw_f1
        jump_table_entry common_overlay::strip_f1_path_segment
        jump_table_entry common_overlay::jt_handle_f1_tbd05
        jump_table_entry common_overlay::prep_path_buf0
        jump_table_entry common_overlay::handle_f1_other_key
        jump_table_entry common_overlay::handle_f1_delete_key
        jump_table_entry common_overlay::handle_f1_left_key
        jump_table_entry common_overlay::handle_f1_right_key
        jump_table_entry common_overlay::handle_f1_meta_left_key
        jump_table_entry common_overlay::handle_f1_meta_right_key
        jump_table_entry common_overlay::handle_f1_click


L70B1:  addr_call common_overlay::L647C, path_buf0
        beq     L70C0
        lda     #ERR_INVALID_PATHNAME
        jsr     JUMP_TABLE_ALERT_0
        rts

L70C0:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg_file_picker
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg
        lda     #0
        sta     LD8EC
        jsr     common_overlay::set_cursor_pointer
        copy16  #path_buf0, $6
        ldx     common_overlay::stash_stack
        txs
        lda     #0
        rts

        .byte   0

L70EA:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg_file_picker
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg
        lda     #0
        sta     LD8EC
        jsr     common_overlay::set_cursor_pointer
        ldx     common_overlay::stash_stack
        txs
        return  #$FF

;;; ============================================================

        PAD_TO $7800
.endproc ; file_delete_overlay
