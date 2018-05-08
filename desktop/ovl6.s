        .setcpu "6502"

;;; NB: Compiled as part of ovl34567.s

;;; ============================================================
;;; Overlay for File Delete
;;; ============================================================

        .org $7000
.proc file_delete_overlay

L7000:  jsr     common_overlay::create_common_dialog
        jsr     L704D
        jsr     common_overlay::L5E87
        jsr     common_overlay::L5F5B
        jsr     common_overlay::L6161
        jsr     common_overlay::L61B1
        jsr     common_overlay::L606D
        jsr     L7026
        jsr     common_overlay::L6D30
        jsr     common_overlay::L6D27
        lda     #$FF
        sta     $D8EC
        jmp     common_overlay::L5106

L7026:  ldx     L7086
L7029:  lda     L7087,x
        sta     $6D1E,x
        dex
        lda     L7087,x
        sta     $6D1E,x
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
        jsr     common_overlay::L62C8
        addr_call common_overlay::L5E0A, delete_a_file_label
        addr_call common_overlay::L5E57, file_to_delete_label
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, common_input1_rect
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

L7086:  .byte $29               ; length of the following data block
L7087:  entry 0, L70B1
        entry 0, L70EA
        entry 0, $6593
        entry 0, $664E
        entry 0, $6DC2
        entry 0, $6DD0
        entry 0, $6E1D
        entry 0, $69C6
        entry 0, $6A18
        entry 0, $6A53
        entry 0, $6AAC
        entry 0, $6B01
        entry 0, $6B44
        entry 0, $66D8


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