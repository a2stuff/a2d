;;; ============================================================
;;; Overlay for Selector Edit - drives File Picker dialog
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc SelectorEditOverlay
        .org ::kOverlayShortcutEditAddress

        MGTKEntry := MGTKRelayImpl

;;; Called back from file dialog's `Start`
.proc Init
        stx     which_run_list
        sty     copy_when


        copy    #$80, file_dialog::extra_controls_flag

        jsr     file_dialog::OpenWindow
        jsr     DrawControls

        COPY_BYTES file_dialog::kJumpTableSize, jt_callbacks, file_dialog::jump_table

        jsr     file_dialog::SetPortForDialog
        lda     which_run_list
        sec
        jsr     DrawRunListButton
        lda     copy_when
        sec
        jsr     DrawCopyWhenButton

        copy16  #HandleClick, file_dialog::click_handler_hook+1
        copy16  #HandleKey, file_dialog::HandleKeyEvent::key_meta_digit+1
        copy    #kSelectorMaxNameLength, file_dialog_res::line_edit_f1::max_length

        jsr     file_dialog::DeviceOnLine

        ;; TODO: Move all of this into file dialog itself?
        ;; If we were passed a path (`path_buf0`), prep the file dialog with it.
        lda     path_buf0
    IF_NE

        COPY_STRING path_buf0, file_dialog::path_buf

        ;; Was it just a volume name, e.g. "/VOL"?
        jsr     IsVolPath
      IF_CS
        ;; No, strip to parent directory
        jsr     file_dialog::StripPathBufSegment

        ;; And populate `buffer` with filename
        ldx     file_dialog::path_buf
        inx
        ldy     #0
:       inx
        iny
        lda     path_buf0,x
        sta     buffer,y
        cpx     path_buf0
        bne     :-
        sty     buffer
      END_IF
    END_IF
        jsr     file_dialog::ReadDir
        jsr     file_dialog::UpdateDiskName
        jsr     file_dialog::UpdateDirName
        lda     #$00
        bcs     :+              ; no files
        param_call file_dialog::FindFilenameIndex, buffer
:       jsr     file_dialog::SetSelectionAndUpdateList
        jsr     file_dialog::LineEditInit
        jsr     file_dialog::LineEditActivate
        jsr     file_dialog::InitDeviceNumber
        jmp     file_dialog::EventLoop

buffer: .res 16, 0

.endproc

;;; ============================================================

.proc DrawControls
        lda     path_buf0
    IF_EQ
        ldax    #label_add
    ELSE
        ldax    #label_edit
    END_IF
        jsr     file_dialog::DrawTitleCentered

        jsr     file_dialog::SetPortForDialog
        param_call file_dialog::DrawInput1Label, enter_the_name_to_appear_label

        MGTK_CALL MGTK::MoveTo, add_a_new_entry_to_label_pos
        param_call file_dialog::DrawString, add_a_new_entry_to_label_str

        MGTK_CALL MGTK::MoveTo, primary_run_list_label_pos
        param_call file_dialog::DrawString, primary_run_list_label_str
        param_call file_dialog::MeasureString, primary_run_list_label_str
        addax   rect_primary_run_list_ctrl::x2

        MGTK_CALL MGTK::MoveTo, secondary_run_list_label_pos
        param_call file_dialog::DrawString, secondary_run_list_label_str
        param_call file_dialog::MeasureString, secondary_run_list_label_str
        addax   rect_secondary_run_list_ctrl::x2

        MGTK_CALL MGTK::MoveTo, down_load_label_pos
        param_call file_dialog::DrawString, down_load_label_str

        MGTK_CALL MGTK::MoveTo, at_first_boot_label_pos
        param_call file_dialog::DrawString, at_first_boot_label_str
        param_call file_dialog::MeasureString, at_first_boot_label_str
        addax   rect_at_first_boot_ctrl::x2

        MGTK_CALL MGTK::MoveTo, at_first_use_label_pos
        param_call file_dialog::DrawString, at_first_use_label_str
        param_call file_dialog::MeasureString, at_first_use_label_str
        addax   rect_at_first_use_ctrl::x2

        MGTK_CALL MGTK::MoveTo, never_label_pos
        param_call file_dialog::DrawString, never_label_str
        param_call file_dialog::MeasureString, never_label_str
        addax   rect_never_ctrl::x2

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

        rts
.endproc

;;; ============================================================

jt_callbacks:
        jmp     HandleOk
        jmp     HandleCancel
        .assert * - jt_callbacks = file_dialog::kJumpTableSize, error, "Table size error"

;;; ============================================================
;;; Close window and finish (via saved_stack) if OK
;;; Outputs: A = 0 if OK
;;;          X = which run list (1=primary, 2=secondary)
;;;          Y = copy when (1=boot, 2=use, 3=never)

.proc HandleOk
        param_call file_dialog::GetPath, path_buf0

        ;; If name is empty, use last path segment
        lda     path_buf1
    IF_ZERO
        ldx     path_buf0
:       lda     path_buf0,x
        cmp     #'/'
        beq     :+
        dex
        bne     :-              ; always, since path is valid
:       inx

        ldy     #1
:       lda     path_buf0,x
        sta     path_buf1,y
        cpx     path_buf0
        beq     :+
        inx
        iny
        bne     :-              ; always

:
        ;; Truncate if necessary
        cpy     #kSelectorMaxNameLength+1
        bcc     :+
        ldy     #kSelectorMaxNameLength
:       sty     path_buf1
    END_IF

        jsr     IsVolPath
        bcs     ok              ; nope
        lda     copy_when       ; Disallow copying volume to ramcard
        cmp     #3
        beq     ok
        FALL_THROUGH_TO invalid

invalid:
        lda     #ERR_INVALID_PATHNAME
        jmp     JUMP_TABLE_SHOW_ALERT

ok:     jsr     file_dialog::CloseWindow
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

.proc HandleCancel
        jsr     file_dialog::CloseWindow
        copy16  #file_dialog::NoOp, file_dialog::HandleKeyEvent::key_meta_digit+1
        ldx     file_dialog::saved_stack
        txs
        return  #$FF
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

        jsr     file_dialog::SetPortForDialog
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
        jsr     file_dialog::SetPortForDialog
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

        PAD_TO ::kOverlayShortcutEditAddress + ::kOverlayShortcutEditLength
.endproc ; SelectorOverlay
