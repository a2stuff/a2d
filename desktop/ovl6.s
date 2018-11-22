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
        jsr     common_overlay::jt_06
        jsr     common_overlay::jt_03
        lda     #$FF
        sta     $D8EC
        jmp     common_overlay::L5106

L7026:  ldx     jump_table_entries
L7029:  lda     jump_table_entries+1,x
        sta     common_overlay::jump_table,x
        dex
        lda     jump_table_entries+1,x
        sta     common_overlay::jump_table,x
        dex
        dex
        bpl     L7029
        lda     #$00
        sta     path_buf0
        sta     $51AE
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

jump_table_entries:
        .byte $29               ; length of the following data block
        jump_table_entry L70B1
        jump_table_entry L70EA
        jump_table_entry $6593
        jump_table_entry $664E
        jump_table_entry $6DC2
        jump_table_entry $6DD0
        jump_table_entry $6E1D
        jump_table_entry $69C6
        jump_table_entry $6A18
        jump_table_entry $6A53
        jump_table_entry $6AAC
        jump_table_entry $6B01
        jump_table_entry $6B44
        jump_table_entry $66D8


L70B1:  addr_call common_overlay::L647C, path_buf0
        beq     L70C0
        lda     #$40
        jsr     JUMP_TABLE_ALERT_0
        rts

L70C0:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg_file_picker
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg
        lda     #0
        sta     $D8EC
        jsr     common_overlay::set_cursor_pointer
        copy16  #path_buf0, $6
        ldx     $50AA
        txs
        lda     #0
        rts

        .byte   0

L70EA:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg_file_picker
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg
        lda     #0
        sta     $D8EC
        jsr     common_overlay::set_cursor_pointer
        ldx     $50AA
        txs
        return  #$FF

;;; ============================================================

        PAD_TO $7800
.endproc ; file_delete_overlay
