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
        LETKEntry := LETKRelayImpl

.proc Run
        ;; A = (obsolete, was dialog type)
        ;; Y = is_add_flag | copy_when
        ;; X = which_run_list
        stx     which_run_list
        sty     is_add_flag
        tya
        and     #$7F
        sta     copy_when

        ;; Save stack
        tsx
        stx     saved_stack

        ;; Init the dialog, set title
        CALL    file_dialog::Init, A=#file_dialog::kSelectionRequiredDirsOK, X=#file_dialog::kShowAllFiles
        ldax    #label_edit
        bit     is_add_flag
    IF NS
        ldax    #label_add
    END_IF
        stax    shortcut_dialog_res::winfo_extended::title

        ;; Dynamic callbacks
        COPY_BYTES file_dialog::kJumpTableSize, jt_callbacks, file_dialog::jump_table

        ;; Open the dialog
        CALL    file_dialog::OpenWindow, AX=#shortcut_dialog_res::winfo_extended

        ;; Draw custom controls
        lda     #BTK::kButtonStateNormal
        sta     primary_run_list_button::state
        sta     secondary_run_list_button::state
        sta     at_first_boot_button::state
        sta     at_first_use_button::state
        sta     never_button::state
        jsr     DrawControls

        lda     which_run_list
        CALL    UpdateRunListButton, C=1
        lda     copy_when
        CALL    DrawCopyWhenButton, C=1

        LETK_CALL LETK::Init, shortcut_dialog_res::le_params
        LETK_CALL LETK::Activate, shortcut_dialog_res::le_params
        copy8   #kSelectorMaxNameLength, shortcut_dialog_res::line_edit::max_length

        ;; Set the path

        ;; If we were passed a path (`path_buf0`), prep the file dialog with it.
        lda     path_buf0
    IF ZERO
        jsr     file_dialog::InitPathWithDefaultDevice
    ELSE
        sta     len
        ;; Strip to parent directory
        CALL    main::RemovePathSegment, AX=#path_buf0

        ;; And populate `buffer` with filename
        ldx     path_buf0
        inx
        ldy     #0
      DO
        inx
        iny
        copy8   path_buf0,x, buffer,y
      WHILE X <> len
        sty     buffer

        CALL    file_dialog::InitPath, AX=#path_buf0
    END_IF

        CALL    file_dialog::UpdateListFromPathAndSelectFile, AX=#buffer
        jmp     EventLoop

buffer: .res 16, 0
len:    .byte   0
.endproc ; Run

;;; ============================================================

.proc EventLoop
    DO
        LETK_CALL LETK::Idle, shortcut_dialog_res::le_params
        jsr     ::main::SystemTask
        jsr     GetNextEvent
    WHILE A = #MGTK::EventKind::no_event

    IF A = #MGTK::EventKind::key_down

        lda     event_params::key
        ldx     event_params::modifiers
        sta     shortcut_dialog_res::le_params::key
        stx     shortcut_dialog_res::le_params::modifiers

      IF ZERO
        ;; No modifier

        ;; Line edit key?
       IF A BETWEEN #' ', #CHAR_DELETE
        LETK_CALL LETK::Key, shortcut_dialog_res::le_params
        jmp     consume
       ELSE_IF A IN #CHAR_LEFT, #CHAR_RIGHT, #CHAR_CTRL_F, #CHAR_CLEAR
        LETK_CALL LETK::Key, shortcut_dialog_res::le_params
        jmp     consume
       END_IF

      ELSE
        ;; Modifier - ours or we let the dialog handle it

        jsr     file_dialog::CheckTypeDown
        beq     EventLoop
        lda     event_params::key

        ;; Line edit key?
       IF A IN #CHAR_LEFT, #CHAR_RIGHT
        LETK_CALL LETK::Key, shortcut_dialog_res::le_params
        jmp     consume
       END_IF

        ;; Radio button shortcut?
       IF A BETWEEN #res_char_shortcut_apple_1, #res_char_shortcut_apple_5
        jsr     HandleKey
        jmp     consume
       END_IF

      END_IF

        jsr     file_dialog::HandleKey
        jmp     EventLoop
    END_IF

    IF A = #MGTK::EventKind::button_down

        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params+MGTK::FindWindowParams::window_id
      IF A = #file_dialog_res::kFilePickerDlgWindowID
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        jsr     HandleClick
        bmi     consume
      END_IF

        jsr     file_dialog::HandleClick
        jmp     EventLoop
    END_IF

    IF A = #kEventKindMouseMoved
        ;; Update mouse cursor if over/off text box
        copy8   #file_dialog_res::kFilePickerDlgWindowID, screentowindow_params+MGTK::ScreenToWindowParams::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params+MGTK::ScreenToWindowParams::window
        MGTK_CALL MGTK::InRect, shortcut_dialog_res::line_edit_rect
        ASSERT_EQUALS MGTK::inrect_outside, 0
       IF NOT ZERO
        jsr     main::SetCursorIBeam
       ELSE
        jsr     main::SetCursorPointer
       END_IF

        FALL_THROUGH_TO consume
    END_IF

consume:
        jsr     file_dialog::ResetTypeDown
        jmp     EventLoop

.endproc ; EventLoop

;;; ============================================================

.proc DrawControls
        MGTK_CALL MGTK::SetPort, file_dialog_res::grafport

        ;; Name field
        MGTK_CALL MGTK::MoveTo, shortcut_dialog_res::line_edit_label_pos
        MGTK_CALL MGTK::DrawString, enter_the_name_to_appear_label
        MGTK_CALL MGTK::FrameRect, shortcut_dialog_res::line_edit_rect

        ;; Vertical separator
        MGTK_CALL MGTK::MoveTo, shortcut_dialog_res::dialog_sep_start
        MGTK_CALL MGTK::LineTo, shortcut_dialog_res::dialog_sep_end

        ;; Radio buttons
        MGTK_CALL MGTK::MoveTo, add_a_new_entry_to_label_pos
        MGTK_CALL MGTK::DrawString, add_a_new_entry_to_label_str

        BTK_CALL BTK::RadioDraw, primary_run_list_button
        BTK_CALL BTK::RadioDraw, secondary_run_list_button

        MGTK_CALL MGTK::MoveTo, down_load_label_pos
        MGTK_CALL MGTK::DrawString, down_load_label_str

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
        ;; This is really "invalid options for this selection" but the
        ;; error is too obscure to bother with a dedicated message.
        lda     #ERR_INVALID_PATHNAME

alert:  TAIL_CALL ShowAlertOption, X=#AlertButtonOptions::OK

.endproc ; HandleOK

;;; ============================================================

.proc HandleCancel
        jsr     file_dialog::CloseWindow
        jsr     main::SetCursorPointer
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

;;; Output: A=$FF/N=1/Z=0 if consumed, A=$00/N=0/Z=1 otherwise
.proc HandleClick
        ;; Radio buttons

        MGTK_CALL MGTK::InRect, primary_run_list_button::rect
        bne     ClickPrimaryRunListCtrl

        MGTK_CALL MGTK::InRect, secondary_run_list_button::rect
        bne     ClickSecondaryRunListCtrl

        MGTK_CALL MGTK::InRect, at_first_boot_button::rect
        bne     ClickAtFirstBootCtrl

        MGTK_CALL MGTK::InRect, at_first_use_button::rect
        bne     ClickAtFirstUseCtrl

        MGTK_CALL MGTK::InRect, never_button::rect
        bne     ClickNeverCtrl

        ;; Text Edit
        MGTK_CALL MGTK::InRect, shortcut_dialog_res::line_edit_rect
    IF NOT_ZERO
        COPY_STRUCT MGTK::Point, screentowindow_params+MGTK::ScreenToWindowParams::window, shortcut_dialog_res::le_params::coords
        LETK_CALL LETK::Click, shortcut_dialog_res::le_params
        RETURN  A=#$FF
    END_IF

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

;;; Input: A=`event_params::key`
.proc HandleKey
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
