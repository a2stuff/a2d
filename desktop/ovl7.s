        .setcpu "6502"

;;; NB: Compiled as part of ovl34567.s

;;; ============================================================
;;; Overlay for Selector (part of it, anyway)
;;; ============================================================

        .org $7000
.proc selector_overlay

L7000:  stx     L73A9
        sty     L73AA
        jsr     common_overlay::create_common_dialog
        jsr     L7101
        jsr     L70AD
        jsr     common_overlay::device_on_line
        lda     path_buf0
        beq     L7056
        addr_call common_overlay::adjust_filename_case, path_buf0
        ldy     path_buf0
L7021:  lda     path_buf0,y
        sta     $5028,y
        dey
        bpl     L7021
        jsr     common_overlay::L5F49
        ldy     path_buf0
L7030:  lda     path_buf0,y
        cmp     #'/'
        beq     L7044
        dey
        cpy     #$01
        bne     L7030
        lda     #$00
        sta     path_buf0
        jmp     L7056

L7044:  ldx     #$00
L7046:  iny
        inx
        lda     path_buf0,y
        sta     L709D,x
        cpy     path_buf0
        bne     L7046
        stx     L709D
L7056:  jsr     common_overlay::L5F5B
        lda     #$00
        bcs     L706A
        addr_call common_overlay::L6516, $709D
        sta     $D920
        jsr     common_overlay::L6586
L706A:  jsr     common_overlay::L6163
        jsr     common_overlay::L61B1
        jsr     common_overlay::L606D
        lda     path_buf0
        bne     L707B
        jsr     common_overlay::jt_06
L707B:  copy16  #$2001, path_buf2
        jsr     common_overlay::jt_03
        jsr     common_overlay::L6693
        copy16  #$2001, path_buf2
        lda     #$FF
        sta     $D8EC
        jmp     common_overlay::L5106

;;; ============================================================

L709D:  .res 16, 0

;;; ============================================================


L70AD:  ldx     jump_table_entries
L70B0:  lda     jump_table_entries+1,x
        sta     common_overlay::jump_table,x
        dex
        lda     jump_table_entries+1,x
        sta     common_overlay::jump_table,x
        dex
        dex
        bpl     L70B0
        lda     #$00
        sta     $51AE
        lda     #$80
        sta     $5104
        copy16  #$0601, path_buf2
        lda     winfo_entrydlg
        jsr     common_overlay::set_port_for_window
        lda     L73A9
        jsr     L7467
        lda     L73AA
        jsr     L747B
        lda     #$80
        sta     $5103
        lda     #$AB
        sta     $531C
        lda     #$73
        sta     $531D
        lda     #$F4
        sta     $5B24
        lda     #$74
        sta     $5B25
        rts

L7101:  lda     winfo_entrydlg
        jsr     common_overlay::set_port_for_window
        lda     path_buf0
        beq     L7116
        addr_call common_overlay::L5E0A, edit_an_entry_label
        jmp     L711D

L7116:  addr_call common_overlay::L5E0A, add_an_entry_label
L711D:  addr_call common_overlay::L5E6F, enter_the_full_pathname_label2
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, common_input1_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_input2_rect
        addr_call common_overlay::L5E57, enter_the_full_pathname_label1
        addr_call common_overlay::L5E6F, enter_the_name_to_appear_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_D922
        addr_call common_overlay::draw_string, add_a_new_entry_to_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_D926
        addr_call common_overlay::draw_string, run_list_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_D92A
        addr_call common_overlay::draw_string, other_run_list_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_D92E
        addr_call common_overlay::draw_string, down_load_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_D932
        addr_call common_overlay::draw_string, at_first_boot_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_D936
        addr_call common_overlay::draw_string, at_first_use_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_D93A
        addr_call common_overlay::draw_string, never_label
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, rect_D93E
        MGTK_RELAY_CALL MGTK::FrameRect, rect_D946
        MGTK_RELAY_CALL MGTK::FrameRect, rect_D94E
        MGTK_RELAY_CALL MGTK::FrameRect, rect_D956
        MGTK_RELAY_CALL MGTK::FrameRect, rect_D95E
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

;;; ============================================================

        .byte   $00

jump_table_entries:  .byte   $29
        jump_table_entry $725D
        jump_table_entry $732F
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

jump_table2_entries:  .byte   $29
        jump_table_entry $72CD
        jump_table_entry $736C
        jump_table_entry $65F0
        jump_table_entry $6693
        jump_table_entry $6DC9
        jump_table_entry $6DD4
        jump_table_entry $6E31
        jump_table_entry $6B72
        jump_table_entry $6BC4
        jump_table_entry $6BFF
        jump_table_entry $6C58
        jump_table_entry $6CAD
        jump_table_entry $6CF0
        jump_table_entry $684F

;;; ============================================================

        copy16  #$2001, path_buf2
        jsr     common_overlay::jt_03
        ldx     jump_table2_entries
L726D:  lda     jump_table2_entries+1,x
        sta     $6D1E,x
        dex
        lda     jump_table2_entries+1,x
        sta     $6D1E,x
        dex
        dex
        bpl     L726D
        lda     #$80
        sta     $51AE
        sta     $5105
        lda     $D8F0
        sta     $D8F1
        lda     #$00
        sta     $D8F0
        lda     path_buf1
        bne     L72BF
        lda     #$00
        sta     path_buf1
        ldx     path_buf0
        beq     L72BF
L72A0:  lda     path_buf0,x
        cmp     #$2F
        beq     L72AD
        dex
        bne     L72A0
        jmp     L72BF

L72AD:  ldy     #$00
L72AF:  iny
        inx
        lda     path_buf0,x
        sta     path_buf1,y
        cpx     path_buf0
        bne     L72AF
        sty     path_buf1
L72BF:  copy16  #$0601, path_buf2
        jsr     common_overlay::jt_03
        rts

        addr_call common_overlay::L647C, path_buf0
        bne     L72E2
        lda     path_buf1
        beq     L72E7
        cmp     #$0F
        bcs     L72E8
        jmp     L72EE

L72E2:  lda     #$40
        jsr     JUMP_TABLE_ALERT_0
L72E7:  rts

L72E8:  lda     #$FB
        jsr     JUMP_TABLE_ALERT_0
        rts

L72EE:  MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg_file_picker
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg
        sta     $D8EC
        jsr     common_overlay::set_cursor_pointer
        copy16  #$59B8, $5B24
        ldx     $50AA
        txs
        ldx     L73A9
        ldy     L73AA
        return  #$00

        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg_file_picker
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg
        lda     #$00
        sta     $D8EC
        jsr     common_overlay::set_cursor_pointer
        copy16  #$59B8, $5B24
        ldx     $50AA
        txs
        return  #$FF

        copy16  #$2001, path_buf2
        jsr     common_overlay::jt_03
        ldx     jump_table_entries
L737C:  lda     jump_table_entries+1,x
        sta     $6D1E,x
        dex
        lda     jump_table_entries+1,x
        sta     $6D1E,x
        dex
        dex
        bpl     L737C
        copy16  #$0601, path_buf2
        jsr     common_overlay::jt_03
        lda     #$00
        sta     $5105
        sta     $51AE
        lda     $D8F1
        sta     $D8F0
        rts

L73A9:  .byte   0
L73AA:  .byte   0

        MGTK_RELAY_CALL MGTK::InRect, rect_D966
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     L73FE
:       MGTK_RELAY_CALL MGTK::InRect, rect_D96E
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     L7413
:       MGTK_RELAY_CALL MGTK::InRect, rect_D976
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     L7428
:       MGTK_RELAY_CALL MGTK::InRect, rect_D97E
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     L743D
:       MGTK_RELAY_CALL MGTK::InRect, rect_D986
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     L7452
:       return  #0

L73FE:  lda     L73A9
        cmp     #1
        beq     L7410
        jsr     L7467
        lda     #1
        sta     L73A9
        jsr     L7467
L7410:  return  #$FF

L7413:  lda     L73A9
        cmp     #2
        beq     L7425
        jsr     L7467
        lda     #2
        sta     L73A9
        jsr     L7467
L7425:  return  #$FF

L7428:  lda     L73AA
        cmp     #1
        beq     L743A
        jsr     L747B
        lda     #1
        sta     L73AA
        jsr     L747B
L743A:  return  #$FF

L743D:  lda     L73AA
        cmp     #2
        beq     L744F
        jsr     L747B
        lda     #2
        sta     L73AA
        jsr     L747B
L744F:  return  #$FF

L7452:  lda     L73AA
        cmp     #3
        beq     L7464
        jsr     L747B
        lda     #3
        sta     L73AA
        jsr     L747B
L7464:  return  #$FF

L7467:  cmp     #1
        bne     L7473
        addr_call L749B, $D93E
        rts

L7473:  addr_call L749B, $D946
        rts

L747B:  cmp     #1
        bne     L7487
        addr_call L749B, $D94E
        rts

L7487:  cmp     #2
        bne     L7493
        addr_call L749B, $D956
        rts

L7493:  addr_call L749B, $D95E
        rts

L749B:  stax    $06
        ldy     #7
L74A1:  lda     ($06),y
        sta     rect_D98E,y
        dey
        bpl     L74A1
        lda     rect_D98E
        clc
        adc     #2
        sta     rect_D98E
        bcc     L74B7
        inc     $D98F
L74B7:  lda     $D990
        clc
        adc     #2
        sta     $D990
        bcc     L74C5
        inc     $D991
L74C5:  lda     $D992
        sec
        sbc     #2
        sta     $D992
        bcs     L74D3
        dec     $D993
L74D3:  lda     $D994
        sec
        sbc     #2
        sta     $D994
        bcs     L74E1
        dec     $D995
L74E1:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D98E
        rts

L74F4:  lda     winfo_entrydlg
        jsr     common_overlay::set_port_for_window
        lda     event_modifiers
        bne     L7500
        rts

L7500:  lda     event_key
        and     #CHAR_MASK
        cmp     #'1'
        bne     L750C
        jmp     L73FE

L750C:  cmp     #'2'
        bne     L7513
        jmp     L7413

L7513:  cmp     #'3'
        bne     L751A
        jmp     L7428

L751A:  cmp     #'4'
        bne     L7521
        jmp     L743D

L7521:  cmp     #'5'
        bne     L7528
        jmp     L7452

L7528:  rts

;;; ============================================================

        PAD_TO $7800
.endproc ; selector_overlay
