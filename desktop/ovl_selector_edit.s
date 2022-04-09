;;; ============================================================
;;; Overlay for Selector Edit - drives File Picker dialog
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc SelectorEditOverlay
        .org ::kOverlaySelector2Address

        MGTKEntry := MGTKRelayImpl

.proc Init
        stx     which_run_list
        sty     copy_when
        jsr     file_dialog::OpenWindow
        jsr     L7101
        jsr     L70AD
        jsr     file_dialog::DeviceOnLine
        lda     path_buf0
        beq     finish
        ldy     path_buf0
:       lda     path_buf0,y
        sta     file_dialog::path_buf,y
        dey
        bpl     :-

        jsr     file_dialog::StripPathBufSegment
        ;; Was it just a volume name, e.g. "/VOL"?
        lda     file_dialog::path_buf
        bne     :+
        copy    path_buf0, file_dialog::path_buf ; yes, restore it
:

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

finish: jsr     file_dialog::ReadDir
        lda     #$00
        bcs     :+
        param_call file_dialog::FindFilenameIndex, buffer
        sta     file_dialog_res::selected_index
        jsr     file_dialog::CalcTopIndex
:       jsr     file_dialog::UpdateScrollbar2
        jsr     file_dialog::UpdateDiskName
        jsr     file_dialog::DrawListEntries
        lda     path_buf0
        bne     :+
        jsr     file_dialog::PrepPath
:       copy    path_buf0, line_edit_res::ip_pos
        jsr     file_dialog::RedrawInput
        jsr     file_dialog::f2::Redraw
        copy    #$FF, line_edit_res::blink_ip_flag
        copy    #0, line_edit_res::allow_all_chars_flag
        jsr     file_dialog::InitDeviceNumber
        jmp     file_dialog::EventLoop

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
        copy    path_buf0, line_edit_res::ip_pos
        lda     file_dialog_res::winfo::window_id
        jsr     file_dialog::SetPortForWindow
        lda     which_run_list
        sec
        jsr     DrawRunListButton
        lda     copy_when
        sec
        jsr     DrawCopyWhenButton
        copy    #$80, file_dialog::extra_controls_flag
        copy16  #HandleClick, file_dialog::click_handler_hook+1
        copy16  #HandleKey, file_dialog::HandleKeyEvent::key_meta_digit+1
        rts
.endproc

;;; ============================================================

.proc L7101
        lda     file_dialog_res::winfo::window_id
        jsr     file_dialog::SetPortForWindow
        lda     path_buf0
        beq     add
        param_call file_dialog::DrawTitleCentered, label_edit
        jmp     common

add:    param_call file_dialog::DrawTitleCentered, label_add
common: MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, file_dialog_res::input1_rect
        MGTK_CALL MGTK::FrameRect, file_dialog_res::input2_rect
        param_call file_dialog::DrawInput1Label, enter_the_full_pathname_label
        param_call file_dialog::DrawInput2Label, enter_the_name_to_appear_label

        MGTK_CALL MGTK::MoveTo, add_a_new_entry_to_label_pos
        param_call file_dialog::DrawString, add_a_new_entry_to_label_str

        MGTK_CALL MGTK::MoveTo, primary_run_list_label_pos
        param_call file_dialog::DrawString, primary_run_list_label_str
        param_call file_dialog::MeasureString, primary_run_list_label_str
        addax   rect_primary_run_list_ctrl::x1, rect_primary_run_list_ctrl::x2
        add16_8 rect_primary_run_list_ctrl::x2, #kRadioButtonWidth + kRadioButtonHOffset

        MGTK_CALL MGTK::MoveTo, secondary_run_list_label_pos
        param_call file_dialog::DrawString, secondary_run_list_label_str
        param_call file_dialog::MeasureString, secondary_run_list_label_str
        addax   rect_secondary_run_list_ctrl::x1, rect_secondary_run_list_ctrl::x2
        add16_8 rect_secondary_run_list_ctrl::x2, #kRadioButtonWidth + kRadioButtonHOffset

        MGTK_CALL MGTK::MoveTo, down_load_label_pos
        param_call file_dialog::DrawString, down_load_label_str

        MGTK_CALL MGTK::MoveTo, at_first_boot_label_pos
        param_call file_dialog::DrawString, at_first_boot_label_str
        param_call file_dialog::MeasureString, at_first_boot_label_str
        addax   rect_at_first_boot_ctrl::x1, rect_at_first_boot_ctrl::x2
        add16_8 rect_at_first_boot_ctrl::x2, #kRadioButtonWidth + kRadioButtonHOffset

        MGTK_CALL MGTK::MoveTo, at_first_use_label_pos
        param_call file_dialog::DrawString, at_first_use_label_str
        param_call file_dialog::MeasureString, at_first_use_label_str
        addax   rect_at_first_use_ctrl::x1, rect_at_first_use_ctrl::x2
        add16_8 rect_at_first_use_ctrl::x2, #kRadioButtonWidth + kRadioButtonHOffset

        MGTK_CALL MGTK::MoveTo, never_label_pos
        param_call file_dialog::DrawString, never_label_str
        param_call file_dialog::MeasureString, never_label_str
        addax   rect_never_ctrl::x1, rect_never_ctrl::x2
        add16_8 rect_never_ctrl::x2, #kRadioButtonWidth + kRadioButtonHOffset

        lda     #1
        clc
        jsr     DrawRunListButton
        lda     #2
        clc
        jsr     DrawRunListButton
        lda     #1
        clc
        jsr     DrawCopyWhenButton
        lda     #2
        clc
        jsr     DrawCopyWhenButton
        lda     #3
        clc
        jsr     DrawCopyWhenButton

        MGTK_CALL MGTK::InitPort, main_grafport
        MGTK_CALL MGTK::SetPort, main_grafport
        rts
.endproc

;;; ============================================================

        ;; Unused
        .byte   0

jt_pathname:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry HandleOkFilename
        jump_table_entry HandleCancelFilename
        .assert * - jt_pathname = file_dialog::kJumpTableSize+1, error, "Table size error"

jt_entry_name:
        .byte file_dialog::kJumpTableSize-1
        jump_table_entry HandleOkName
        jump_table_entry HandleCancelName
        .assert * - jt_entry_name = file_dialog::kJumpTableSize+1, error, "Table size error"

;;; ============================================================

.proc HandleOkFilename
        jsr     file_dialog::f1::MoveIPEnd
        jsr     file_dialog::f1::HideIP ; Switch

        ;; install name field handlers
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
        sta     file_dialog::listbox_disabled_flag
        lda     line_edit_res::input_dirty_flag
        sta     input1_dirty_flag
        lda     #$00
        sta     line_edit_res::input_dirty_flag
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

finish: copy    #$80, line_edit_res::allow_all_chars_flag
        copy    path_buf1, line_edit_res::ip_pos
        jsr     file_dialog::RedrawInput
        rts
.endproc

;;; ============================================================
;;; Close window and finish (via saved_stack) if OK
;;; Outputs: A = 0 if OK
;;;          X = which run list (1=primary, 2=secondary)
;;;          Y = copy when (1=boot, 2=use, 3=never)

.proc HandleOkName
        param_call file_dialog::VerifyValidPath, path_buf0
        bne     invalid
        lda     path_buf1
        jeq     Bell            ; empty - give a subtle error
        cmp     #14+1           ; Max selector name length
        bcs     too_long
        jsr     IsVolPath
        bcs     ok              ; nope
        lda     copy_when       ; Disallow copying volume to ramcard
        cmp     #3
        beq     ok
        FALL_THROUGH_TO invalid

invalid:
        lda     #ERR_INVALID_PATHNAME
        jmp     JUMP_TABLE_SHOW_ALERT

too_long:
        lda     #kErrNameTooLong
        jmp     JUMP_TABLE_SHOW_ALERT

ok:     MGTK_CALL MGTK::InitPort, main_grafport
        MGTK_CALL MGTK::SetPort, main_grafport
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo_listbox
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo
        copy    #0, line_edit_res::blink_ip_flag
        jsr     file_dialog::UnsetCursorIBeam
        copy16  #file_dialog::NoOp, file_dialog::HandleKeyEvent::key_meta_digit+1

        ldx     file_dialog::saved_stack
        txs
        ldx     which_run_list
        ldy     copy_when
        return  #0
.endproc

;;; Returns C=0 if `path_buf0` is a volume path, C=1 otherwise
;;; Assert: Path is valid
.proc IsVolPath
        ldy     path_buf0
:       lda     path_buf0,y
        cmp     #'/'
        beq     found
        dey
        bne     :-

found:  cpy     #2
        rts
.endproc

;;; ============================================================

.proc HandleCancelFilename
        MGTK_CALL MGTK::InitPort, main_grafport
        MGTK_CALL MGTK::SetPort, main_grafport
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo_listbox
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo
        copy    #0, line_edit_res::blink_ip_flag
        jsr     file_dialog::UnsetCursorIBeam
        copy16  #file_dialog::NoOp, file_dialog::HandleKeyEvent::key_meta_digit+1
        ldx     file_dialog::saved_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

.proc HandleCancelName
        jsr     file_dialog::f2::MoveIPEnd
        jsr     file_dialog::f2::HideIP ; Switch

        ;; install pathname field handlers
        ldx     jt_pathname
:       lda     jt_pathname+1,x
        sta     file_dialog::jump_table,x
        dex
        lda     jt_pathname+1,x
        sta     file_dialog::jump_table,x
        dex
        dex
        bpl     :-

        copy    #0, line_edit_res::allow_all_chars_flag
        lda     #$00
        sta     file_dialog::listbox_disabled_flag
        sta     file_dialog::focus_in_input2_flag
        lda     input1_dirty_flag
        sta     line_edit_res::input_dirty_flag

        copy    path_buf0, line_edit_res::ip_pos
        jsr     file_dialog::f1::ShowIP
        rts
.endproc

;;; ============================================================

which_run_list:
        .byte   0
copy_when:
        .byte   0

;;; ============================================================

.proc HandleClick
        MGTK_CALL MGTK::InRect, rect_primary_run_list_ctrl
        cmp     #MGTK::inrect_inside
        jeq     ClickPrimaryRunListCtrl

        MGTK_CALL MGTK::InRect, rect_secondary_run_list_ctrl
        cmp     #MGTK::inrect_inside
        jeq     ClickSecondaryRunListCtrl

        MGTK_CALL MGTK::InRect, rect_at_first_boot_ctrl
        cmp     #MGTK::inrect_inside
        jeq     ClickAtFirstBootCtrl

        MGTK_CALL MGTK::InRect, rect_at_first_use_ctrl
        cmp     #MGTK::inrect_inside
        jeq     ClickAtFirstUseCtrl

        MGTK_CALL MGTK::InRect, rect_never_ctrl
        cmp     #MGTK::inrect_inside
        jeq     ClickNeverCtrl

        return  #0
.endproc

.proc ClickPrimaryRunListCtrl
        lda     which_run_list
        cmp     #1
        beq     :+
        clc
        jsr     DrawRunListButton
        lda     #1
        sta     which_run_list
        sec
        jsr     DrawRunListButton
:       return  #$FF
.endproc

.proc ClickSecondaryRunListCtrl
        lda     which_run_list
        cmp     #2
        beq     :+
        clc
        jsr     DrawRunListButton
        lda     #2
        sta     which_run_list
        sec
        jsr     DrawRunListButton
:       return  #$FF
.endproc

.proc ClickAtFirstBootCtrl
        lda     copy_when
        cmp     #1
        beq     :+
        clc
        jsr     DrawCopyWhenButton
        lda     #1
        sta     copy_when
        sec
        jsr     DrawCopyWhenButton
:       return  #$FF
.endproc

.proc ClickAtFirstUseCtrl
        lda     copy_when
        cmp     #2
        beq     :+
        clc
        jsr     DrawCopyWhenButton
        lda     #2
        sta     copy_when
        sec
        jsr     DrawCopyWhenButton
:       return  #$FF
.endproc

.proc ClickNeverCtrl
        lda     copy_when
        cmp     #3
        beq     :+
        clc
        jsr     DrawCopyWhenButton
        lda     #3
        sta     copy_when
        sec
        jsr     DrawCopyWhenButton
:       return  #$FF
.endproc

;;; ============================================================

.proc DrawRunListButton
        pha
    IF_CC
        copy16  #unchecked_rb_bitmap, rb_params::mapbits
    ELSE
        copy16  #checked_rb_bitmap, rb_params::mapbits
    END_IF

        pla
        cmp     #1
    IF_EQ
        ldax    #rect_primary_run_list_ctrl
    ELSE
        ldax    #rect_secondary_run_list_ctrl
    END_IF

        ptr := $06
draw:
        stax    ptr
        ldy     #.sizeof(MGTK::Point)-1
:       lda     (ptr),y
        sta     rb_params::viewloc,y
        dey
        bpl     :-

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::PaintBits, rb_params
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

.proc DrawCopyWhenButton
        pha
    IF_CC
        copy16  #unchecked_rb_bitmap, rb_params::mapbits
    ELSE
        copy16  #checked_rb_bitmap, rb_params::mapbits
    END_IF

        pla
        cmp     #1
        bne     :+
        ldax    #rect_at_first_boot_ctrl
        bne     DrawRunListButton::draw ; always

:       cmp     #2
        bne     :+
        ldax    #rect_at_first_use_ctrl
        bne     DrawRunListButton::draw ; always

:       ldax    #rect_never_ctrl
        bne     DrawRunListButton::draw ; always
.endproc

;;; ============================================================

.proc HandleKey
        lda     file_dialog_res::winfo::window_id
        jsr     file_dialog::SetPortForWindow
        lda     event_params::modifiers
        bne     :+
        rts

:       lda     event_params::key
        cmp     #'1'
        jeq     ClickPrimaryRunListCtrl

        cmp     #'2'
        jeq     ClickSecondaryRunListCtrl

        cmp     #'3'
        jeq     ClickAtFirstBootCtrl

        cmp     #'4'
        jeq     ClickAtFirstUseCtrl

        cmp     #'5'
        jeq     ClickNeverCtrl

        rts
.endproc

;;; ============================================================

        PAD_TO ::kOverlaySelector2Address + ::kOverlaySelector2Length
.endproc ; SelectorOverlay
