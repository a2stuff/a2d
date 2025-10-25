;;; ============================================================
;;; Overlay for Selector Edit - drives File Picker dialog
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        BEGINSEG OverlayShortcutEdit


;;; Constants specific to this dialog and used by the caller. These
;;; correspond to properties of `docs/Selector_List_Format.md` but are
;;; specific to this dialog and the caller.

kRunListPrimary   = 1           ; entry is in first 8 (menu and dialog)
kRunListSecondary = 2           ; entry is in second 16 (dialog only)

kCopyOnBoot = 1                 ; corresponds to `kSelectorEntryCopyOnBoot`
kCopyOnUse  = 2                 ; corresponds to `kSelectorEntryCopyOnUse`
kCopyNever  = 3                 ; corresponds to `kSelectorEntryCopyNever`

.scope SelectorEditOverlay

        MLIEntry := main::MLIRelayImpl
        MGTKEntry := MGTKRelayImpl
        BTKEntry := BTKRelayImpl

.proc Run
        ;; A = (obsolete, was dialog type)
        ;; Y = is_add_flag | copy_when
        ;; X = which_run_list
        stx     which_run_list
        sty     is_add_flag
        tya
        and     #$7F
        sta     copy_when

        tsx
        stx     saved_stack

        jsr     file_dialog::Init
        SET_BIT7_FLAG file_dialog::extra_controls_flag
        copy8   #file_dialog::kSelectionRequiredDirsOK, file_dialog::selection_requirement_flags

        lda     #BTK::kButtonStateNormal
        sta     primary_run_list_button::state
        sta     secondary_run_list_button::state
        sta     at_first_boot_button::state
        sta     at_first_use_button::state
        sta     never_button::state

        ldax    #label_edit
        bit     is_add_flag
    IF NS
        ldax    #label_add
    END_IF
        jsr     file_dialog::OpenWindow
        jsr     DrawControls

        COPY_BYTES file_dialog::kJumpTableSize, jt_callbacks, file_dialog::jump_table

        lda     which_run_list
        CALL    UpdateRunListButton, C=1
        lda     copy_when
        CALL    DrawCopyWhenButton, C=1

        copy16  #HandleClick, file_dialog::click_handler_hook
        copy16  #HandleKey, file_dialog::key_handler_hook
        copy8   #kSelectorMaxNameLength, file_dialog_res::line_edit::max_length

        ;; If we were passed a path (`path_buf0`), prep the file dialog with it.
        lda     path_buf0
    IF ZERO
        jsr     file_dialog::InitPathWithDefaultDevice
    ELSE
        COPY_STRING path_buf0, file_dialog::path_buf

        ;; Strip to parent directory
        jsr     file_dialog::StripPathBufSegment

        ;; And populate `buffer` with filename
        ldx     file_dialog::path_buf
        inx
        ldy     #0
      DO
        inx
        iny
        copy8   path_buf0,x, buffer,y
      WHILE X <> path_buf0
        sty     buffer
    END_IF
        CALL    file_dialog::UpdateListFromPathAndSelectFile, AX=#buffer
        jmp     file_dialog::EventLoop

buffer: .res 16, 0

.endproc ; Run

;;; ============================================================

.proc DrawControls
        MGTK_CALL MGTK::SetPort, file_dialog_res::winfo::port
        CALL    file_dialog::DrawLineEditLabel, AX=#enter_the_name_to_appear_label

        MGTK_CALL MGTK::MoveTo, add_a_new_entry_to_label_pos
        CALL    main::DrawString, AX=#add_a_new_entry_to_label_str

        MGTK_CALL MGTK::MoveTo, down_load_label_pos
        CALL    main::DrawString, AX=#down_load_label_str

        BTK_CALL BTK::RadioDraw, primary_run_list_button
        BTK_CALL BTK::RadioDraw, secondary_run_list_button

        BTK_CALL BTK::RadioDraw, at_first_boot_button
        BTK_CALL BTK::RadioDraw, at_first_use_button
        BTK_CALL BTK::RadioDraw, never_button

        rts
.endproc ; DrawControls

;;; ============================================================

saved_stack:
        .byte   0

jt_callbacks:
        jmp     HandleOK
        jmp     HandleCancel
        .assert * - jt_callbacks = file_dialog::kJumpTableSize, error, "Table size error"

;;; ============================================================
;;; Close window and finish (via saved_stack) if OK
;;; Outputs: A = 0 if OK
;;;          X = which run list (1=primary, 2=secondary)
;;;          Y = copy when (1=boot, 2=use, 3=never)

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, main::tmp_path_buf

.proc HandleOK
        CALL    file_dialog::GetPath, AX=#path_buf0
        CALL    file_dialog::GetPath, AX=#main::tmp_path_buf

        ;; If name is empty, use last path segment
        lda     text_input_buf
    IF ZERO
        ldx     path_buf0
      DO
        lda     path_buf0,x
        BREAK_IF A = #'/'
        dex
      WHILE NOT_ZERO            ; always, since path is valid
        inx

        ldy     #1
      DO
        copy8   path_buf0,x, text_input_buf,y
        BREAK_IF X = path_buf0
        inx
        iny
      WHILE NOT_ZERO            ; always

        ;; Truncate if necessary
        cpy     #kSelectorMaxNameLength+1
      IF GE
        ldy     #kSelectorMaxNameLength
      END_IF
        sty     text_input_buf
    END_IF

        ;; Disallow copying some types to ramcard
        lda     copy_when
        cmp     #kCopyNever
        beq     ok

        MLI_CALL GET_FILE_INFO, get_file_info_params
        bcs     alert
        ;; Volume?
        lda     get_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     invalid
        ;; Link?
        lda     get_file_info_params::file_type
        cmp     #FT_LINK
        beq     invalid

ok:     jsr     file_dialog::CloseWindow
        ldx     saved_stack
        txs
        ldx     which_run_list
        ldy     copy_when
        RETURN  A=#0

invalid:
        lda     #ERR_INVALID_PATHNAME
alert:  jmp     ShowAlert

.endproc ; HandleOK

;;; ============================================================

.proc HandleCancel
        jsr     file_dialog::CloseWindow
        ldx     saved_stack
        txs
        RETURN  A=#$FF
.endproc ; HandleCancel

;;; ============================================================

which_run_list:
        .byte   0
copy_when:
        .byte   0
is_add_flag:                    ; high bit set = Add, clear = Edit
        .byte   0

;;; ============================================================

.proc HandleClick
        MGTK_CALL MGTK::InRect, primary_run_list_button::rect
        jne     ClickPrimaryRunListCtrl

        MGTK_CALL MGTK::InRect, secondary_run_list_button::rect
        jne     ClickSecondaryRunListCtrl

        MGTK_CALL MGTK::InRect, at_first_boot_button::rect
        jne     ClickAtFirstBootCtrl

        MGTK_CALL MGTK::InRect, at_first_use_button::rect
        jne     ClickAtFirstUseCtrl

        MGTK_CALL MGTK::InRect, never_button::rect
        jne     ClickNeverCtrl

        RETURN  A=#0
.endproc ; HandleClick

.proc ClickPrimaryRunListCtrl
        lda     which_run_list
    IF A <> #kRunListPrimary
        CALL    UpdateRunListButton, C=0
        copy8   #kRunListPrimary, which_run_list
        CALL    UpdateRunListButton, C=1
    END_IF
        RETURN  A=#$FF
.endproc ; ClickPrimaryRunListCtrl

.proc ClickSecondaryRunListCtrl
        lda     which_run_list
    IF A <> #kRunListSecondary
        CALL    UpdateRunListButton, C=0
        copy8   #kRunListSecondary, which_run_list
	CALL    UpdateRunListButton, C=1
    END_IF
        RETURN  A=#$FF
.endproc ; ClickSecondaryRunListCtrl

.proc ClickAtFirstBootCtrl
        lda     copy_when
    IF A <> #kCopyOnBoot
        CALL    DrawCopyWhenButton, C=0
        lda     #kCopyOnBoot
        sta     copy_when
        CALL    DrawCopyWhenButton, C=1
    END_IF
        RETURN  A=#$FF
.endproc ; ClickAtFirstBootCtrl

.proc ClickAtFirstUseCtrl
        lda     copy_when
    IF A <> #kCopyOnUse
        CALL    DrawCopyWhenButton, C=0
        lda     #kCopyOnUse
        sta     copy_when
        CALL    DrawCopyWhenButton, C=1
    END_IF
        RETURN  A=#$FF
.endproc ; ClickAtFirstUseCtrl

.proc ClickNeverCtrl
        lda     copy_when
    IF A <> #kCopyNever
        CALL    DrawCopyWhenButton, C=0
        lda     #kCopyNever
        sta     copy_when
        CALL    DrawCopyWhenButton, C=1
    END_IF
        RETURN  A=#$FF
.endproc ; ClickNeverCtrl

;;; ============================================================

.proc UpdateRunListButton
        ldx     #BTK::kButtonStateNormal
    IF CS
        ldx     #BTK::kButtonStateChecked
    END_IF

    IF A = #kRunListPrimary
        stx     primary_run_list_button::state
        BTK_CALL BTK::RadioUpdate, primary_run_list_button
    ELSE
        stx     secondary_run_list_button::state
        BTK_CALL BTK::RadioUpdate, secondary_run_list_button
    END_IF

        rts
.endproc ; UpdateRunListButton

.proc DrawCopyWhenButton
        ldx     #BTK::kButtonStateNormal
    IF CS
        ldx     #BTK::kButtonStateChecked
    END_IF

    IF A = #kCopyOnBoot
        stx     at_first_boot_button::state
        BTK_CALL BTK::RadioUpdate, at_first_boot_button
        rts
    END_IF

    IF A = #kCopyOnUse
        stx     at_first_use_button::state
        BTK_CALL BTK::RadioUpdate, at_first_use_button
        rts
    END_IF

        stx     never_button::state
        BTK_CALL BTK::RadioUpdate, never_button
        rts
.endproc ; DrawCopyWhenButton

;;; ============================================================

.proc HandleKey
        lda     event_params::modifiers
        RTS_IF ZERO

        lda     event_params::key
        cmp     #res_char_shortcut_apple_1
        jeq     ClickPrimaryRunListCtrl

        cmp     #res_char_shortcut_apple_2
        jeq     ClickSecondaryRunListCtrl

        cmp     #res_char_shortcut_apple_3
        jeq     ClickAtFirstBootCtrl

        cmp     #res_char_shortcut_apple_4
        jeq     ClickAtFirstUseCtrl

        cmp     #res_char_shortcut_apple_5
        jeq     ClickNeverCtrl

        rts
.endproc ; HandleKey

;;; ============================================================

.endscope ; SelectorEditOverlay

        ENDSEG OverlayShortcutEdit
