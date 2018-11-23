;;; ============================================================
;;; Overlay for File Copy
;;; ============================================================

.proc file_copy_overlay
        .org $7000

L7000:  jsr     common_overlay::create_common_dialog
        jsr     L7052
        jsr     common_overlay::device_on_line
        jsr     common_overlay::L5F5B
        jsr     common_overlay::L6161
        jsr     common_overlay::L61B1
        jsr     common_overlay::L606D
        jsr     L7026
        jsr     common_overlay::jt_06
        jsr     common_overlay::jt_03
        lda     #$FF
        sta     LD8EC
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
        lda     #$80
        sta     common_overlay::L5104
        lda     #$00
        sta     path_buf0
        sta     common_overlay::L51AE
        lda     #$01
        sta     path_buf2
        lda     #$06
        sta     path_buf2+1
        rts

L7052:  lda     winfo_entrydlg
        jsr     common_overlay::set_port_for_window
        addr_call common_overlay::L5E0A, copy_a_file_label
        addr_call common_overlay::L5E57, source_filename_label
        addr_call common_overlay::L5E6F, destination_filename_label
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, common_input1_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_input2_rect
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

jump_table_entries:
        .byte   $29             ; length of following data block
        jump_table_entry L70F1
        jump_table_entry L71D8
        jump_table_entry common_overlay::L6593
        jump_table_entry common_overlay::L664E
        jump_table_entry common_overlay::L6DC2
        jump_table_entry common_overlay::L6DD0
        jump_table_entry common_overlay::L6E1D
        jump_table_entry common_overlay::L69C6
        jump_table_entry common_overlay::L6A18
        jump_table_entry common_overlay::L6A53
        jump_table_entry common_overlay::L6AAC
        jump_table_entry common_overlay::L6B01
        jump_table_entry common_overlay::L6B44
        jump_table_entry common_overlay::L66D8

jump_table2_entries:
        .byte   $29        ; length of following data block
        jump_table_entry L7189
        jump_table_entry L71F9
        jump_table_entry common_overlay::L65F0
        jump_table_entry common_overlay::L6693
        jump_table_entry common_overlay::L6DC9
        jump_table_entry common_overlay::L6DD4
        jump_table_entry common_overlay::L6E31
        jump_table_entry common_overlay::L6B72
        jump_table_entry common_overlay::L6BC4
        jump_table_entry common_overlay::L6BFF
        jump_table_entry common_overlay::L6C58
        jump_table_entry common_overlay::L6CAD
        jump_table_entry common_overlay::L6CF0
        jump_table_entry common_overlay::L684F

;;; ============================================================

L70F1:  lda     #1
        sta     path_buf2
        lda     #$20
        sta     path_buf2+1
        jsr     common_overlay::jt_03

        ldx     jump_table2_entries
:       lda     jump_table2_entries+1,x
        sta     common_overlay::jump_table,x
        dex
        lda     jump_table2_entries+1,x
        sta     common_overlay::jump_table,x
        dex
        dex
        bpl     :-

        lda     #$80
        sta     common_overlay::L50A8
        sta     common_overlay::L51AE
        lda     LD920
        sta     LD921
        lda     #$FF
        sta     LD920
        jsr     common_overlay::device_on_line
        jsr     common_overlay::L5F5B
        jsr     common_overlay::L6161
        jsr     common_overlay::L61B1

        jsr     common_overlay::L606D
        ldx     common_overlay::path_buf
L7137:  lda     common_overlay::path_buf,x
        sta     path_buf1,x
        dex
        bpl     L7137
        addr_call common_overlay::adjust_filename_case, path_buf1  ; path_buf1
        lda     #$01
        sta     path_buf2           ; path_buf2
        lda     #$06
        sta     path_buf2+1
        ldx     path_buf0
        beq     L7178
L7156:  lda     path_buf0,x
        and     #CHAR_MASK
        cmp     #'/'
        beq     L7162
        dex
        bne     L7156
L7162:  ldy     #2
        dex
L7165:  cpx     path_buf0
        beq     L7178
        inx
        lda     path_buf0,x
        sta     path_buf2,y
        inc     path_buf2
        iny
        jmp     L7165

L7178:  jsr     common_overlay::jt_03
        lda     LD8F0
        sta     LD8F1
        lda     LD8F2
        sta     LD8F0
        rts

        .byte   0

;;; ============================================================

L7189:  addr_call common_overlay::L647C, path_buf0
        beq     L7198
L7192:  lda     #$40
        jsr     JUMP_TABLE_ALERT_0
        rts

L7198:  addr_call common_overlay::L647C, path_buf1
        bne     L7192
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg_file_picker
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg
        lda     #0
        sta     common_overlay::L50A8
        lda     #0
        sta     LD8EC
        jsr     common_overlay::set_cursor_pointer
        copy16  #path_buf0, $6
        copy16  #path_buf1, $8
        ldx     common_overlay::stash_stack
        txs
        return  #$00

        .byte   0

;;; ============================================================

L71D8:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg_file_picker
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg
        lda     #0
        sta     LD8EC
        jsr     common_overlay::set_cursor_pointer
        ldx     common_overlay::stash_stack
        txs
        return  #$FF

;;; ============================================================

L71F9:  lda     #1
        sta     path_buf2
        lda     #' '
        sta     path_buf2+1
        jsr     common_overlay::jt_03
        ldx     jump_table_entries
L7209:  lda     jump_table_entries+1,x
        sta     common_overlay::jump_table,x
        dex
        lda     jump_table_entries+1,x
        sta     common_overlay::jump_table,x
        dex
        dex
        bpl     L7209
        lda     #$01
        sta     path_buf2
        lda     #$06
        sta     path_buf2+1
        lda     #$00
        sta     common_overlay::L50A8
        lda     #$FF
        sta     LD920
        lda     #$00
        sta     common_overlay::L51AE
        lda     LD8F0
        sta     LD8F2
        lda     LD8F1
        sta     LD8F0

        ldx     path_buf0
:       lda     path_buf0,x
        sta     common_overlay::path_buf,x
        dex
        bpl     :-

        jsr     common_overlay::L5F49
        bit     LD8F0
        bpl     L726D
        jsr     common_overlay::device_on_line
        lda     #0
        jsr     common_overlay::L6227
        jsr     common_overlay::L5F5B
        jsr     common_overlay::L6161
        jsr     common_overlay::L61B1
        jsr     common_overlay::L606D
        jsr     common_overlay::jt_03
        jmp     L7295

L726D:  lda     common_overlay::path_buf
        bne     L7281
L7272:  jsr     common_overlay::device_on_line
        lda     #$00
        jsr     common_overlay::L6227
        jsr     common_overlay::L5F5B
        lda     #$FF
        bne     L7289
L7281:  jsr     common_overlay::L5F5B
        bcs     L7272
        lda     LD921
L7289:  sta     LD920
        jsr     common_overlay::L6163
        jsr     common_overlay::L61B1
        jsr     common_overlay::L606D
L7295:  rts

;;; ============================================================

        PAD_TO $7800

.endproc ; file_copy_overlay
