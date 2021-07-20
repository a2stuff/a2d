;;; ============================================================
;;; Overlay for Selector Edit - drives File Picker dialog
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc selector_overlay
        .org $7000

.proc init
        stx     which_run_list
        sty     copy_when
        jsr     file_dialog::open_window
        jsr     L7101
        jsr     L70AD
        jsr     file_dialog::device_on_line
        lda     path_buf0
        beq     finish
        ldy     path_buf0
:       lda     path_buf0,y
        sta     file_dialog::path_buf,y
        dey
        bpl     :-

        jsr     file_dialog::strip_path_segment
        ldy     path_buf0
:       lda     path_buf0,y
        cmp     #'/'
        beq     found_slash
        dey
        cpy     #$01
        bne     :-

        lda     #$00
        sta     path_buf0
        jmp     finish

found_slash:
        ldx     #$00
:       iny
        inx
        lda     path_buf0,y
        sta     buffer,x
        cpy     path_buf0
        bne     :-
        stx     buffer

finish: jsr     file_dialog::read_dir
        lda     #$00
        bcs     :+
        param_call file_dialog::L6516, buffer
        sta     selected_index
        jsr     file_dialog::calc_top_index
:       jsr     file_dialog::update_scrollbar2
        jsr     file_dialog::update_disk_name
        jsr     file_dialog::draw_list_entries
        lda     path_buf0
        bne     :+
        jsr     file_dialog::jt_prep_path
:       copy    #1, path_buf2
        copy    #' ', path_buf2+1
        jsr     file_dialog::jt_redraw_input
        jsr     file_dialog::redraw_f2
        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        lda     #$FF
        sta     LD8EC
        jsr     file_dialog::init_device_number
        jmp     file_dialog::event_loop

buffer: .res 16, 0

.endproc

;;; ============================================================

.proc L70AD
        ldx     jt_pathname
:       lda     jt_pathname+1,x
        sta     file_dialog::jump_table,x
        dex
        lda     jt_pathname+1,x
        sta     file_dialog::jump_table,x
        dex
        dex
        bpl     :-

        copy    #0, file_dialog::focus_in_input2_flag
        copy    #$80, file_dialog::dual_inputs_flag
        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        lda     winfo_file_dialog::window_id
        jsr     file_dialog::set_port_for_window
        lda     which_run_list
        jsr     toggle_run_list_button
        lda     copy_when
        jsr     toggle_copy_when_button
        copy    #$80, file_dialog::extra_controls_flag
        copy16  #handle_click, file_dialog::click_handler_hook+1
        copy16  #handle_key, file_dialog::handle_key::key_meta_digit+1
        rts
.endproc

;;; ============================================================

.proc L7101
        lda     winfo_file_dialog::window_id
        jsr     file_dialog::set_port_for_window
        lda     path_buf0
        beq     add
        param_call file_dialog::draw_title_centered, label_edit
        jmp     common

add:    param_call file_dialog::draw_title_centered, label_add
common: MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::input1_rect
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::input2_rect
        param_call file_dialog::draw_input1_label, enter_the_full_pathname_label
        param_call file_dialog::draw_input2_label, enter_the_name_to_appear_label

        MGTK_RELAY_CALL MGTK::MoveTo, add_a_new_entry_to_label_pos
        param_call file_dialog::draw_string, add_a_new_entry_to_label_str
        MGTK_RELAY_CALL MGTK::MoveTo, run_list_label_pos
        param_call file_dialog::draw_string, run_list_label_str
        MGTK_RELAY_CALL MGTK::MoveTo, other_run_list_label_pos
        param_call file_dialog::draw_string, other_run_list_label_str
        MGTK_RELAY_CALL MGTK::MoveTo, down_load_label_pos
        param_call file_dialog::draw_string, down_load_label_str
        MGTK_RELAY_CALL MGTK::MoveTo, at_first_boot_label_pos
        param_call file_dialog::draw_string, at_first_boot_label_str
        MGTK_RELAY_CALL MGTK::MoveTo, at_first_use_label_pos
        param_call file_dialog::draw_string, at_first_use_label_str
        MGTK_RELAY_CALL MGTK::MoveTo, never_label_pos
        param_call file_dialog::draw_string, never_label_str

        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, rect_run_list_radiobtn
        MGTK_RELAY_CALL MGTK::FrameRect, rect_other_run_list_radiobtn
        MGTK_RELAY_CALL MGTK::FrameRect, rect_at_first_boot_radiobtn
        MGTK_RELAY_CALL MGTK::FrameRect, rect_at_first_use_radiobtn
        MGTK_RELAY_CALL MGTK::FrameRect, rect_never_radiobtn
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        rts
.endproc

;;; ============================================================

        ;; Unused
        .byte   0

jt_pathname:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry handle_ok_filename
        jump_table_entry handle_cancel_filename
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
        .assert * - jt_pathname = file_dialog::kJumpTableSize+1, error, "Table size error"

jt_entry_name:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry handle_ok_name
        jump_table_entry handle_cancel_name
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
        .assert * - jt_entry_name = file_dialog::kJumpTableSize+1, error, "Table size error"

;;; ============================================================

.proc handle_ok_filename
        jsr     file_dialog::move_ip_to_end_f1

        copy    #1, path_buf2
        copy    #' ', path_buf2+1
        jsr     file_dialog::jt_redraw_input

        ldx     jt_entry_name
:       lda     jt_entry_name+1,x
        sta     file_dialog::jump_table,x
        dex
        lda     jt_entry_name+1,x
        sta     file_dialog::jump_table,x
        dex
        dex
        bpl     :-

        lda     #$80
        sta     file_dialog::focus_in_input2_flag
        sta     file_dialog::L5105
        lda     LD8F0
        sta     LD8F1
        lda     #$00
        sta     LD8F0
        lda     path_buf1
        bne     finish
        lda     #$00
        sta     path_buf1
        ldx     path_buf0
        beq     finish
:       lda     path_buf0,x
        cmp     #'/'
        beq     found_slash
        dex
        bne     :-
        jmp     finish

found_slash:
        ldy     #0
:       iny
        inx
        lda     path_buf0,x
        sta     path_buf1,y
        cpx     path_buf0
        bne     :-

        sty     path_buf1
finish: copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        jsr     file_dialog::jt_redraw_input
        rts
.endproc

;;; ============================================================
;;; Close window and finish (via saved_stack) if OK
;;; Outputs: A = 0 if OK
;;;          X = which run list (1=run list, 2=other run list)
;;;          Y = copy when (1=boot, 2=use, 3=never)

.proc handle_ok_name
        param_call file_dialog::L647C, path_buf0
        bne     invalid
        lda     path_buf1
        beq     fail
        cmp     #$0F            ; Max selector name length
        bcs     too_long
        jmp     ok

invalid:
        lda     #ERR_INVALID_PATHNAME
        jsr     JUMP_TABLE_SHOW_ALERT
fail:   rts

too_long:
        lda     #kErrNameTooLong
        jsr     JUMP_TABLE_SHOW_ALERT
        rts

ok:     MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog_listbox
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog
        sta     LD8EC
        jsr     file_dialog::set_cursor_pointer
        copy16  #file_dialog::noop, file_dialog::handle_key::key_meta_digit+1

        ldx     file_dialog::stash_stack
        txs
        ldx     which_run_list
        ldy     copy_when
        return  #0
.endproc

;;; ============================================================

.proc handle_cancel_filename
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog_listbox
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_file_dialog
        lda     #0
        sta     LD8EC
        jsr     file_dialog::set_cursor_pointer
        copy16  #file_dialog::noop, file_dialog::handle_key::key_meta_digit+1
        ldx     file_dialog::stash_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

.proc handle_cancel_name
        jsr     file_dialog::move_ip_to_end_f2

        copy    #1, path_buf2
        copy    #' ', path_buf2+1
        jsr     file_dialog::jt_redraw_input

        ldx     jt_pathname
:       lda     jt_pathname+1,x
        sta     file_dialog::jump_table,x
        dex
        lda     jt_pathname+1,x
        sta     file_dialog::jump_table,x
        dex
        dex
        bpl     :-

        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        jsr     file_dialog::jt_redraw_input
        lda     #$00
        sta     file_dialog::L5105
        sta     file_dialog::focus_in_input2_flag
        lda     LD8F1
        sta     LD8F0
        rts
.endproc

;;; ============================================================

which_run_list:
        .byte   0
copy_when:
        .byte   0

;;; ============================================================

.proc handle_click
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
        lda     which_run_list
        cmp     #1
        beq     :+
        jsr     toggle_run_list_button
        lda     #1
        sta     which_run_list
        jsr     toggle_run_list_button
:       return  #$FF
.endproc

.proc click_other_run_list_ctrl
        lda     which_run_list
        cmp     #2
        beq     :+
        jsr     toggle_run_list_button
        lda     #2
        sta     which_run_list
        jsr     toggle_run_list_button
:       return  #$FF
.endproc

.proc click_at_first_boot_ctrl
        lda     copy_when
        cmp     #1
        beq     :+
        jsr     toggle_copy_when_button
        lda     #1
        sta     copy_when
        jsr     toggle_copy_when_button
:       return  #$FF
.endproc

.proc click_at_first_use_ctrl
        lda     copy_when
        cmp     #2
        beq     :+
        jsr     toggle_copy_when_button
        lda     #2
        sta     copy_when
        jsr     toggle_copy_when_button
:       return  #$FF
.endproc

.proc click_never_ctrl
        lda     copy_when
        cmp     #3
        beq     :+
        jsr     toggle_copy_when_button
        lda     #3
        sta     copy_when
        jsr     toggle_copy_when_button
:       return  #$FF
.endproc

;;; ============================================================

.proc toggle_run_list_button
        cmp     #1
        bne     :+
        param_call draw_inset_rect, rect_run_list_radiobtn
        rts

:       param_call draw_inset_rect, rect_other_run_list_radiobtn
        rts
.endproc

.proc toggle_copy_when_button
        cmp     #1
        bne     :+
        param_call draw_inset_rect, rect_at_first_boot_radiobtn
        rts

:       cmp     #2
        bne     :+
        param_call draw_inset_rect, rect_at_first_use_radiobtn
        rts

:       param_call draw_inset_rect, rect_never_radiobtn
        rts
.endproc

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

.proc handle_key
        lda     winfo_file_dialog::window_id
        jsr     file_dialog::set_port_for_window
        lda     event_modifiers
        bne     :+
        rts

:       lda     event_key
        cmp     #'1'
        bne     :+
        jmp     click_run_list_ctrl

:       cmp     #'2'
        bne     :+
        jmp     click_other_run_list_ctrl

:       cmp     #'3'
        bne     :+
        jmp     click_at_first_boot_ctrl

:       cmp     #'4'
        bne     :+
        jmp     click_at_first_use_ctrl

:       cmp     #'5'
        bne     :+
        jmp     click_never_ctrl

:       rts
.endproc

;;; ============================================================

        PAD_TO $7800
.endproc ; selector_overlay
