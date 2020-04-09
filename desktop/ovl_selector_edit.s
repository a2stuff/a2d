;;; ============================================================
;;; Overlay for Selector (part of it, anyway)
;;; ============================================================

.proc selector_overlay
        .org $7000

.proc L7000
        stx     L73A9
        sty     L73AA
        jsr     common_overlay::create_common_dialog
        jsr     L7101
        jsr     L70AD
        jsr     common_overlay::device_on_line
        lda     path_buf0
        beq     L7056
        ldy     path_buf0
L7021:  lda     path_buf0,y
        sta     common_overlay::path_buf,y
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
        addr_call common_overlay::L6516, L709D
        sta     LD920
        jsr     common_overlay::L6586
L706A:  jsr     common_overlay::L6163
        jsr     common_overlay::L61B1
        jsr     common_overlay::draw_list_entries
        lda     path_buf0
        bne     L707B
        jsr     common_overlay::jt_prep_path
L707B:  copy    #1, path_buf2
        copy    #' ', path_buf2+1
        jsr     common_overlay::jt_redraw_input
        jsr     common_overlay::redraw_f2
        copy    #1, path_buf2
        copy    #' ', path_buf2+1
        lda     #$FF
        sta     LD8EC
        jmp     common_overlay::event_loop

L709D:  .res 16, 0

.endproc

;;; ============================================================


.proc L70AD
        ldx     jt_pathname
L70B0:  lda     jt_pathname+1,x
        sta     common_overlay::jump_table,x
        dex
        lda     jt_pathname+1,x
        sta     common_overlay::jump_table,x
        dex
        dex
        bpl     L70B0
        lda     #$00
        sta     common_overlay::L51AE
        lda     #$80
        sta     common_overlay::L5104
        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        lda     winfo_entrydlg
        jsr     common_overlay::set_port_for_window
        lda     L73A9
        jsr     L7467
        lda     L73AA
        jsr     L747B
        lda     #$80
        sta     common_overlay::L5103
        copy16  #L73AB, common_overlay::L531B+1
        copy16  #L74F4, common_overlay::L59B9::key_meta_digit+1
        rts
.endproc

;;; ============================================================

.proc L7101
        lda     winfo_entrydlg
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
        MGTK_RELAY_CALL MGTK::MoveTo, pos_add_a_new_entry_to_label
        addr_call common_overlay::draw_string, add_a_new_entry_to_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_run_list_label
        addr_call common_overlay::draw_string, run_list_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_other_run_list_label
        addr_call common_overlay::draw_string, other_run_list_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_down_load_label
        addr_call common_overlay::draw_string, down_load_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_at_first_boot_label
        addr_call common_overlay::draw_string, at_first_boot_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_at_first_use_label
        addr_call common_overlay::draw_string, at_first_use_label
        MGTK_RELAY_CALL MGTK::MoveTo, pos_never_label
        addr_call common_overlay::draw_string, never_label
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, rect_run_list_radiobtn
        MGTK_RELAY_CALL MGTK::FrameRect, rect_other_run_list_radiobtn
        MGTK_RELAY_CALL MGTK::FrameRect, rect_at_first_boot_radiobtn
        MGTK_RELAY_CALL MGTK::FrameRect, rect_at_first_use_radiobtn
        MGTK_RELAY_CALL MGTK::FrameRect, rect_never_radiobtn
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts
.endproc

;;; ============================================================

        .byte   $00

jt_pathname:  .byte   $29
        jump_table_entry L725D
        jump_table_entry L732F
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

jt_entry_name:  .byte   $29
        jump_table_entry L72CD
        jump_table_entry L736C
        jump_table_entry common_overlay::blink_f2_ip
        jump_table_entry common_overlay::redraw_f2
        jump_table_entry common_overlay::strip_f2_path_segment
        jump_table_entry common_overlay::jt_handle_f2_tbd05
        jump_table_entry common_overlay::prep_path_buf1
        jump_table_entry common_overlay::handle_f2_other_key
        jump_table_entry common_overlay::handle_f2_delete_key
        jump_table_entry common_overlay::handle_f2_left_key
        jump_table_entry common_overlay::handle_f2_right_key
        jump_table_entry common_overlay::handle_f2_meta_left_key
        jump_table_entry common_overlay::handle_f2_meta_right_key
        jump_table_entry common_overlay::handle_f2_click

;;; ============================================================

.proc L725D
        copy    #1, path_buf2
        copy    #' ', path_buf2+1
        jsr     common_overlay::jt_redraw_input
        ldx     jt_entry_name
L726D:  lda     jt_entry_name+1,x
        sta     common_overlay::jump_table,x
        dex
        lda     jt_entry_name+1,x
        sta     common_overlay::jump_table,x
        dex
        dex
        bpl     L726D
        lda     #$80
        sta     common_overlay::L51AE
        sta     common_overlay::L5105
        lda     LD8F0
        sta     LD8F1
        lda     #$00
        sta     LD8F0
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
L72BF:  copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        jsr     common_overlay::jt_redraw_input
        rts
.endproc

;;; ============================================================

.proc L72CD
        addr_call common_overlay::L647C, path_buf0
        bne     L72E2
        lda     path_buf1
        beq     L72E7
        cmp     #$0F
        bcs     L72E8
        jmp     L72EE

L72E2:  lda     #ERR_INVALID_PATHNAME
        jsr     JUMP_TABLE_ALERT_0
L72E7:  rts

L72E8:  lda     #kErrNameTooLong
        jsr     JUMP_TABLE_ALERT_0
        rts

L72EE:  MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg_file_picker
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg
        sta     LD8EC
        jsr     common_overlay::set_cursor_pointer
        copy16  #common_overlay::noop, common_overlay::L59B9::key_meta_digit+1
        ldx     common_overlay::stash_stack
        txs
        ldx     L73A9
        ldy     L73AA
        return  #$00
.endproc

;;; ============================================================

.proc L732F
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg_file_picker
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entrydlg
        lda     #$00
        sta     LD8EC
        jsr     common_overlay::set_cursor_pointer
        copy16  #common_overlay::noop, common_overlay::L59B9::key_meta_digit+1
        ldx     common_overlay::stash_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

.proc L736C
        copy    #1, path_buf2
        copy    #' ', path_buf2+1
        jsr     common_overlay::jt_redraw_input
        ldx     jt_pathname
L737C:  lda     jt_pathname+1,x
        sta     common_overlay::jump_table,x
        dex
        lda     jt_pathname+1,x
        sta     common_overlay::jump_table,x
        dex
        dex
        bpl     L737C
        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        jsr     common_overlay::jt_redraw_input
        lda     #$00
        sta     common_overlay::L5105
        sta     common_overlay::L51AE
        lda     LD8F1
        sta     LD8F0
        rts
.endproc

;;; ============================================================

L73A9:  .byte   0
L73AA:  .byte   0

;;; ============================================================

.proc L73AB
        MGTK_RELAY_CALL MGTK::InRect, rect_run_list_ctrl
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     click_run_list_ctrl
:       MGTK_RELAY_CALL MGTK::InRect, rect_other_run_list_ctrl
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     click_other_run_list_ctrl
:       MGTK_RELAY_CALL MGTK::InRect, rect_at_first_boot_ctrl
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     click_at_first_boot_ctrl
:       MGTK_RELAY_CALL MGTK::InRect, rect_at_first_use_ctrl
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     click_at_first_use_ctrl
:       MGTK_RELAY_CALL MGTK::InRect, rect_never_ctrl
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     click_never_ctrl
:       return  #0
.endproc

.proc click_run_list_ctrl
        lda     L73A9
        cmp     #1
        beq     :+
        jsr     L7467
        lda     #1
        sta     L73A9
        jsr     L7467
:       return  #$FF
.endproc

.proc click_other_run_list_ctrl
        lda     L73A9
        cmp     #2
        beq     :+
        jsr     L7467
        lda     #2
        sta     L73A9
        jsr     L7467
:       return  #$FF
.endproc

.proc click_at_first_boot_ctrl
        lda     L73AA
        cmp     #1
        beq     :+
        jsr     L747B
        lda     #1
        sta     L73AA
        jsr     L747B
:       return  #$FF
.endproc

.proc click_at_first_use_ctrl
        lda     L73AA
        cmp     #2
        beq     :+
        jsr     L747B
        lda     #2
        sta     L73AA
        jsr     L747B
:       return  #$FF
.endproc

.proc click_never_ctrl
        lda     L73AA
        cmp     #3
        beq     :+
        jsr     L747B
        lda     #3
        sta     L73AA
        jsr     L747B
:       return  #$FF
.endproc

;;; ============================================================

L7467:  cmp     #1
        bne     L7473
        addr_call draw_inset_rect, rect_run_list_radiobtn
        rts

L7473:  addr_call draw_inset_rect, rect_other_run_list_radiobtn
        rts

L747B:  cmp     #1
        bne     L7487
        addr_call draw_inset_rect, rect_at_first_boot_radiobtn
        rts

L7487:  cmp     #2
        bne     L7493
        addr_call draw_inset_rect, rect_at_first_use_radiobtn
        rts

L7493:  addr_call draw_inset_rect, rect_never_radiobtn
        rts

;;; ============================================================
;;; Draw rect inset by 2px. Pointer to Rect in A,X.

.proc draw_inset_rect
        ptr := $06

        ;; Copy to scratch rect
        stax    ptr
        ldy     #.sizeof(MGTK::Rect)-1
:       lda     (ptr),y
        sta     rect_scratch,y
        dey
        bpl     :-

        lda     rect_scratch::x1
        clc
        adc     #2
        sta     rect_scratch::x1
        bcc     :+
        inc     rect_scratch::x1+1

:       lda     rect_scratch::y1
        clc
        adc     #2
        sta     rect_scratch::y1
        bcc     :+
        inc     rect_scratch::y1+1

:       lda     rect_scratch::x2
        sec
        sbc     #2
        sta     rect_scratch::x2
        bcs     :+
        dec     rect_scratch::x2+1

:       lda     rect_scratch::y2
        sec
        sbc     #2
        sta     rect_scratch::y2
        bcs     :+
        dec     rect_scratch::y2+1

:       MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_scratch
        rts
.endproc

;;; ============================================================

L74F4:  lda     winfo_entrydlg
        jsr     common_overlay::set_port_for_window
        lda     event_modifiers
        bne     L7500
        rts

L7500:  lda     event_key
        and     #CHAR_MASK
        cmp     #'1'
        bne     L750C
        jmp     click_run_list_ctrl

L750C:  cmp     #'2'
        bne     L7513
        jmp     click_other_run_list_ctrl

L7513:  cmp     #'3'
        bne     L751A
        jmp     click_at_first_boot_ctrl

L751A:  cmp     #'4'
        bne     L7521
        jmp     click_at_first_use_ctrl

L7521:  cmp     #'5'
        bne     L7528
        jmp     click_never_ctrl

L7528:  rts

;;; ============================================================

        PAD_TO $7800
.endproc ; selector_overlay
