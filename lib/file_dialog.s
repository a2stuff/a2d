;;; ============================================================
;;; Common File Picker Dialog
;;;
;;; Required includes:
;;; * lib/file_dialog_res.s
;;; * lib/event_params.s
;;; * lib/muldiv.s
;;; Requires the following proc definitions:
;;; * `AdjustFileEntryCase`
;;; * `AdjustVolumeNameCase`
;;; * `CheckMouseMoved`
;;; * `DetectDoubleClick`
;;; * `MLIRelayImpl`
;;; * `ModifierDown`
;;; * `ShiftDown`
;;; * `YieldLoop`
;;; Requires the following data definitions:
;;; * `buf_text`
;;; * `buf_input1`
;;; * `window_grafport`
;;; * `penXOR`
;;; Requires the following macro definitions:
;;; * `MGTK_CALL`
;;; * `LETK_CALL`
;;; * `BTK_CALL`
;;;
;;; If `FD_EXTENDED` is defined as 1:
;;; * two input fields are supported
;;; * title passed to `DrawTitleCentered` in aux, `AuxLoad` is used
;;; * `buf_input2` must be defined

;;; ============================================================

;;; Map from index in file_names to list entry; high bit is
;;; set for directories.
file_list_index := $1780

num_file_names  := $177F

;;; Sequence of 16-byte records, filenames in current directory.
file_names      := $1800

kMaxInputLength = $3F

;;; ============================================================

        DEFINE_ON_LINE_PARAMS on_line_params, 0, on_line_buffer

        io_buf := $1000
        dir_read_buf := $1400
        kDirReadSize = $200

        DEFINE_OPEN_PARAMS open_params, path_buf, io_buf
        DEFINE_READ_PARAMS read_params, dir_read_buf, kDirReadSize
        DEFINE_CLOSE_PARAMS close_params

on_line_buffer: .res    16, 0
device_num:     .byte   0       ; current drive, index in DEVLST
path_buf:       .res    128, 0

only_show_dirs_flag:            ; set when selecting copy destination
        .byte   0
dir_count:
        .byte   0

saved_stack:
        .byte   0

;;; Buffer used when selecting filename by holding Apple key and typing name.
;;; Length-prefixed string, initialized to 0 when the dialog is shown.
type_down_buf:
        .res    16, 0

selected_index:                 ; $FF if none
        .byte   0

;;; ============================================================

.if FD_EXTENDED
routine_table:
        .addr   kOverlayFileCopyAddress
        .addr   kOverlayFileDeleteAddress
        .addr   kOverlayShortcutEditAddress
.endif

;;; ============================================================

;;; For FD_EXTENDED, A=routine to jump to from `routine_table`
;;; Otherwise, jumps to label `start`.

.proc Start
.if FD_EXTENDED
        sty     stash_y
        stx     stash_x
.endif
        tsx
        stx     saved_stack
.if FD_EXTENDED
        pha
.endif
        jsr     SetCursorPointer
        copy    DEVCNT, device_num

        lda     #0
        sta     type_down_buf
        sta     file_dialog_res::allow_all_chars_flag
        sta     only_show_dirs_flag
        sta     cursor_ibeam_flag
        sta     extra_controls_flag
        sta     listbox_disabled_flag
.if FD_EXTENDED
        sta     input1_dirty_flag
        sta     input2_dirty_flag
        sta     dual_inputs_flag
.endif

        copy    #$FF, selected_index

        lda     #0
        sta     file_dialog_res::open_button_rec::state
        sta     file_dialog_res::close_button_rec::state
        sta     file_dialog_res::change_drive_button_rec::state

.if FD_EXTENDED
        pla
        asl     a
        tax
        copy16  routine_table,x, @jump
        ldy     stash_y
        ldx     stash_x

        @jump := *+1
        jmp     SELF_MODIFIED

stash_x:        .byte   0
stash_y:        .byte   0
.else
        jmp     start
.endif

.endproc

;;; ============================================================
;;; Flags set by invoker to alter behavior

extra_controls_flag:    ; Set when `click_handler_hook` should be called
        .byte   0

dual_inputs_flag:       ; Set when there are two text input fields
        .byte   0

listbox_disabled_flag:  ; Set when the listbox is not active
        .byte   0

;;; ============================================================

.proc EventLoop
        jsr     Idle
        jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params

        lda     event_params::kind
        cmp     #MGTK::EventKind::apple_key
        beq     is_btn
        cmp     #MGTK::EventKind::button_down
        bne     :+
        copy    #0, type_down_buf
is_btn: jsr     HandleButtonDown
        jmp     EventLoop

:       cmp     #MGTK::EventKind::key_down
        bne     :+
        jsr     HandleKeyEvent
        jmp     EventLoop

:       jsr     CheckMouseMoved
        bcc     EventLoop

        copy    #0, type_down_buf

        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        jeq     EventLoop

        lda     findwindow_params::window_id
        cmp     #file_dialog_res::kFilePickerDlgWindowID
        beq     l1
        jsr     UnsetCursorIBeam
        jmp     EventLoop

l1:
        lda     #file_dialog_res::kFilePickerDlgWindowID
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

.if FD_EXTENDED
        bit     focus_in_input2_flag
        bmi     l2
.endif

        MGTK_CALL MGTK::InRect, file_dialog_res::input1_rect
        cmp     #MGTK::inrect_inside
        bne     l4

.if FD_EXTENDED
        beq     l3
l2:     MGTK_CALL MGTK::InRect, file_dialog_res::input2_rect
        cmp     #MGTK::inrect_inside
        bne     l4
l3:
.endif

        jsr     SetCursorIBeam
        jmp     l5
l4:
        jsr     UnsetCursorIBeam
l5:     jmp     EventLoop
.endproc

.if FD_EXTENDED
focus_in_input2_flag:
        .byte   0
.endif

;;; ============================================================

.proc HandleButtonDown
        ;; We allow Apple+Click just for Change Drive button
        ldx     #0
        lda     event_params::kind
        cmp     #MGTK::EventKind::apple_key
        bne     :+
        ldx     #$80
:       stx     is_apple_click_flag

        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        beq     :+
ret:    rts
:
        lda     findwindow_params::window_id
        cmp     #file_dialog_res::kFilePickerDlgWindowID
        beq     not_list
        bit     listbox_disabled_flag
        bmi     not_list
        bit     is_apple_click_flag
        bmi     ret             ; ignore except for Change Drive
        jsr     HandleListClick
        bmi     ret
        jsr     DetectDoubleClick
        bmi     ret
        ldx     selected_index
        lda     file_list_index,x
    IF_NC
        ;; File - accept it.
        BTK_CALL BTK::Flash, file_dialog_res::ok_button_params
        jmp     HandleOk
    END_IF
        ;; Folder - open it.
        BTK_CALL BTK::Flash, file_dialog_res::open_button_params
        jmp     DoOpen

not_list:
        lda     #file_dialog_res::kFilePickerDlgWindowID
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; --------------------------------------------------
        ;; Change Drive button

        MGTK_CALL MGTK::InRect, file_dialog_res::change_drive_button_rec::rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        jsr     IsChangeDriveAllowed
        bcs     :+
        BTK_CALL BTK::Track, file_dialog_res::change_drive_button_params
        bmi     :+
        jsr     DoChangeDrive
:       rts
    END_IF

        bit     is_apple_click_flag
        bmi     ret             ; ignore except for Change Drive

        ;; --------------------------------------------------
        ;; Open button

        MGTK_CALL MGTK::InRect, file_dialog_res::open_button_rec::rect
        cmp     #MGTK::inrect_inside
     IF_EQ
        jsr     IsOpenAllowed
        bcs     :+
        BTK_CALL BTK::Track, file_dialog_res::open_button_params
        bmi     :+
        jsr     DoOpen
:       rts
    END_IF

        ;; --------------------------------------------------
        ;; Close button

        MGTK_CALL MGTK::InRect, file_dialog_res::close_button_rec::rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        jsr     IsCloseAllowed
        bcs     :+
        BTK_CALL BTK::Track, file_dialog_res::close_button_params
        bmi     :+
        jsr     DoClose
:       rts
    END_IF

        ;; --------------------------------------------------
        ;; OK button

        MGTK_CALL MGTK::InRect, file_dialog_res::ok_button_rec::rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        BTK_CALL BTK::Track, file_dialog_res::ok_button_params
        bmi     :+
        jsr     HandleOk
:       rts
    END_IF

        ;; --------------------------------------------------
        ;; Cancel button

        MGTK_CALL MGTK::InRect, file_dialog_res::cancel_button_rec::rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        BTK_CALL BTK::Track, file_dialog_res::cancel_button_params
        bmi     :+
        jsr     HandleCancel
:       rts
    END_IF

        ;; --------------------------------------------------
        ;; Extra controls

        bit     extra_controls_flag
    IF_NS
        jsr     click_handler_hook
        bpl     :+
        rts
:
    END_IF

        ;; --------------------------------------------------
        ;; Text entry controls

.if !FD_EXTENDED
        ;; Single field only
        MGTK_CALL MGTK::InRect, file_dialog_res::input1_rect
        cmp     #MGTK::inrect_inside
        bne     done_click
        jsr     f1__Click
.else
        ;; Maybe dual fields
        MGTK_CALL MGTK::InRect, file_dialog_res::input1_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        bit     focus_in_input2_flag
      IF_NS
        jsr     HandleCancel ; Move focus to input1
        ;; NOTE: Assumes screentowindow_params::window* has not been changed.
      END_IF
        jsr     f1__Click
        jmp     done_click
    END_IF

        ;; Does the second field exist?
        bit     dual_inputs_flag
        bpl     done_click
        MGTK_CALL MGTK::InRect, file_dialog_res::input2_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        bit     focus_in_input2_flag
      IF_NC
        jsr     HandleOk    ; move focus to input2
        ;; NOTE: Assumes screentowindow_params::window* has not been changed.
      END_IF
        jsr     f2__Click
    END_IF
.endif
done_click:

        rts

is_apple_click_flag:
        .byte   0
.endproc

;;; ============================================================
;;; This vector gets patched by overlays that add controls.

click_handler_hook:
        jmp     NoOp

;;; ============================================================
;;; Refresh the list view from the current path
;;; Clears selection.

.proc UpdateListFromPath
        lda     #$FF
        jsr     SetSelectedIndex
        jsr     ReadDir
        jsr     EnableScrollbar
        jsr     UpdateViewport
        jsr     UpdateDiskName
        jmp     DrawListEntries
.endproc

;;; ============================================================

.proc UnsetCursorIBeam
        bit     cursor_ibeam_flag
        bpl     :+
        jsr     SetCursorPointer
        copy    #0, cursor_ibeam_flag
:       rts
.endproc

;;; ============================================================

.proc SetCursorPointer
        MGTK_CALL MGTK::SetCursor, pointer_cursor
        rts
.endproc

;;; ============================================================

.proc SetCursorIBeam
        bit     cursor_ibeam_flag
        bmi     :+
        MGTK_CALL MGTK::SetCursor, ibeam_cursor
        copy    #$80, cursor_ibeam_flag
:       rts
.endproc

cursor_ibeam_flag:              ; high bit set when cursor is I-beam
        .byte   0

;;; ============================================================

.proc DoOpen
        ldx     selected_index
        lda     file_list_index,x
        and     #$7F

        jsr     GetNthFilename
        jsr     AppendToPathBuf


        jsr     PrepPath
        jsr     Update          ; string changed
        jsr     Activate        ; move IP to end

        jmp     UpdateListFromPath
.endproc

;;; ============================================================

.proc DoChangeDrive
        jsr     ModifierDown
        sta     drive_dir_flag
        jsr     ShiftDown
        ora     drive_dir_flag
        sta     drive_dir_flag

        jsr     NextDeviceNum
        jsr     DeviceOnLine

        jsr     PrepPath
        jsr     Update          ; string changed
        jsr     Activate        ; move IP to end

        jmp     UpdateListFromPath
.endproc

;;; ============================================================

;;; Output: C=0 if allowed, C=1 if not.
.proc IsChangeDriveAllowed
        bit     listbox_disabled_flag
        bmi     no
        lda     DEVCNT
        beq     no

        clc
        rts

no:     sec
        rts
.endproc

;;; ============================================================

;;; Output: C=0 if allowed, C=1 if not.
.proc IsOpenAllowed
        bit     listbox_disabled_flag
        bmi     no
        lda     selected_index
        bmi     no              ; no selection
        tax
        lda     file_list_index,x
        bpl     no              ; not a folder

        clc
        rts

no:     sec
        rts
.endproc

;;; ============================================================

;;; Output: C=0 if allowed, C=1 if not.
.proc IsCloseAllowed
        bit     listbox_disabled_flag
        bmi     no

        ;; Walk back looking for last '/'
        ldx     path_buf
        beq     no
:       lda     path_buf,x
        cmp     #'/'
        beq     :+
        dex
        bpl     :-
        bmi     no

        ;; Volume?
:       cpx     #1
        beq     no

        clc
        rts

no:     sec
        rts
.endproc

;;; ============================================================

.proc DoClose
        jsr     IsCloseAllowed
        bcs     ret

        ;; Remove last segment
        jsr     StripPathBufSegment

        jsr     PrepPath
        jsr     Update          ; string changed
        jsr     Activate        ; move IP to end

        jsr     UpdateListFromPath

ret:    rts
.endproc

;;; ============================================================
;;; Key handler

.proc HandleKeyEvent
        lda     event_params::key

        bit     listbox_disabled_flag
    IF_NC
        jsr     IsListKey
      IF_EQ
        copy    #0, type_down_buf
        jmp     HandleListKey
      END_IF
    END_IF

        ldx     event_params::modifiers
    IF_NE
        ;; With modifiers
        lda     event_params::key

        bit     listbox_disabled_flag
        bmi     :+
        jsr     CheckTypeDown
        jeq     exit
:
        copy    #0, type_down_buf
        lda     event_params::key
        cmp     #CHAR_TAB
        jeq     KeyTab

        ;; Hook for clients
        cmp     #'0'
        bcc     :+
        cmp     #'9'+1
        jcc     key_meta_digit
:
        ;; Delegate to active line edit
        jsr     Key

    ELSE
        ;; --------------------------------------------------
        ;; No modifiers

        pha
        copy    #0, type_down_buf
        pla

        cmp     #CHAR_RETURN
        jeq     KeyReturn

        cmp     #CHAR_ESCAPE
        jeq     KeyEscape

        bit     listbox_disabled_flag
      IF_NC
        cmp     #CHAR_TAB
        jeq     KeyTab

        cmp     #CHAR_CTRL_O    ; Open
        jeq     KeyOpen

        cmp     #CHAR_CTRL_C    ; Close
        jeq     KeyClose
      END_IF

        jsr     IsControlChar ; pass through control characters
        bcc     allow
        bit     file_dialog_res::allow_all_chars_flag
      IF_NC
        jsr     IsPathChar
        bcs     ignore
      END_IF
allow:  jsr     Key
ignore:
    END_IF

exit:   rts

;;; ============================================================

.proc KeyOpen
        jsr     IsOpenAllowed
        bcs     ret

        BTK_CALL BTK::Flash, file_dialog_res::open_button_params
        jsr     DoOpen

ret:    rts
.endproc

;;; ============================================================

.proc KeyClose
        jsr     IsCloseAllowed
        bcs     ret

        BTK_CALL BTK::Flash, file_dialog_res::close_button_params
        jsr     DoClose

ret:    rts
.endproc

;;; ============================================================

.proc KeyReturn
.if !FD_EXTENDED
        lda     selected_index
        bpl     :+              ; has a selection
        bit     file_dialog_res::input_dirty_flag
        bmi     :+              ; input is dirty
        rts
:
.endif
        BTK_CALL BTK::Flash, file_dialog_res::ok_button_params
        jmp     HandleOk
.endproc

;;; ============================================================

.proc KeyEscape
        BTK_CALL BTK::Flash, file_dialog_res::cancel_button_params
        jmp     HandleCancel
.endproc

;;; ============================================================

.proc KeyTab
        jsr     IsChangeDriveAllowed
        bcs     ret

        BTK_CALL BTK::Flash, file_dialog_res::change_drive_button_params
        jsr     DoChangeDrive
ret:    rts
.endproc

;;; ============================================================
;;; This vector gets patched by overlays that add controls.

key_meta_digit:
        jmp     NoOp

;;; ============================================================

.proc CheckTypeDown
        jsr     UpcaseChar
        cmp     #'A'
        bcc     :+
        cmp     #'Z'+1
        bcc     file_char

:       ldx     type_down_buf
        beq     not_file_char

        cmp     #'.'
        beq     file_char
        cmp     #'0'
        bcc     not_file_char
        cmp     #'9'+1
        bcc     file_char

not_file_char:
        return  #$FF

file_char:
        ldx     type_down_buf
        cpx     #15
        bne     :+
        rts                     ; Z=1 to consume
:
        inx
        stx     type_down_buf
        sta     type_down_buf,x

        jsr     FindMatch
        bmi     done
        cmp     selected_index
        beq     done
        pha
        lda     selected_index
        jsr     HighlightIndex
        pla
        jmp     UpdateListSelection

done:   return  #0

.proc FindMatch
        lda     num_file_names
        bne     :+
        return  #$FF
:
        copy    #0, index

loop:   ldx     index
        lda     file_list_index,x
        and     #$7F
        jsr     SetPtrToNthFilename

        ldy     #0
        lda     ($06),y
        sta     len

        ldy     #1              ; compare strings (length >= 1)
cloop:  lda     ($06),y
        jsr     UpcaseChar
        cmp     type_down_buf,y
        bcc     next
        beq     :+
        bcs     found
:
        cpy     type_down_buf
        beq     found

        iny
        cpy     len
        bcc     cloop
        beq     cloop

next:   inc     index
        lda     index
        cmp     num_file_names
        bne     loop
        dec     index
found:  return  index

len:    .byte   0
.endproc

index:  .byte   0
char:   .byte   0

.endproc ; CheckAlpha

.endproc ; HandleKeyEvent

;;; ============================================================

;;; ============================================================

;;; Input: A = index
;;; Output: A,X = filename
.proc GetNthFilename
        ldx     #$00
        stx     hi

        asl     a               ; * 16
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi

        clc
        adc     #<file_names
        tay
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        adc     #>file_names

        tax
        tya
        rts
.endproc

;;; Input: A = index
;;; Output: $06 and A,X = filename
.proc SetPtrToNthFilename
        jsr     GetNthFilename
        stax    $06
        rts
.endproc

;;; ============================================================

.proc UpcaseChar
        cmp     #'a'
        bcc     done
        cmp     #'z'+1
        bcs     done
        and     #(CASE_MASK & $7F) ; convert lowercase to uppercase
done:   rts
.endproc

;;; ============================================================

;;; Input: A=character
;;; Output: C=0 if control, C=1 if not
.proc IsControlChar
        cmp     #CHAR_DELETE
        bcs     yes

        cmp     #' '
        bcc     yes
        rts                     ; C=1

yes:    clc                     ; C=0
        rts
.endproc

;;; ============================================================

;;; Input: A=character
;;; Output: C=0 if valid path character, C=1 otherwise
.proc IsPathChar
        jsr     UpcaseChar
        cmp     #'A'
        bcc     :+
        cmp     #'Z'+1
        bcc     yes
:       cmp     #'0'
        bcc     :+
        cmp     #'9'+1
        bcc     yes
:       cmp     #'.'
        beq     yes
        cmp     #'/'
        beq     yes

        sec
        rts

yes:    clc
        rts
.endproc

;;; ============================================================

;;; Inputs: A=index
;;; Outputs: A=index
.proc SetSelectedIndex
        pha
        sta     selected_index
        jsr     UpdateDynamicButtons
        pla
        rts
.endproc

;;; Inputs: A=flag (high bit = listbox disabled)
.proc SetListBoxDisabled
        sta     listbox_disabled_flag
        FALL_THROUGH_TO UpdateDynamicButtons
.endproc

.proc UpdateDynamicButtons
        jsr     DrawChangeDriveLabel
        jsr     DrawOpenLabel
        jmp     DrawCloseLabel
.endproc

;;; ============================================================

;;; Inputs: A=index
.proc UpdateListSelection
        jsr     SetSelectedIndex
        jsr     ScrollIntoView
        jsr     HandleSelectionChange
.endproc

;;; ============================================================

.proc NoOp
        rts
.endproc

;;; ============================================================

.proc OpenWindow
        MGTK_CALL MGTK::OpenWindow, file_dialog_res::winfo
        MGTK_CALL MGTK::OpenWindow, file_dialog_res::winfo_listbox
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, file_dialog_res::input1_rect
.if FD_EXTENDED
        bit     dual_inputs_flag
    IF_NS
        MGTK_CALL MGTK::FrameRect, file_dialog_res::input2_rect
    END_IF
.endif
        MGTK_CALL MGTK::SetPenSize, file_dialog_res::pensize_frame
        MGTK_CALL MGTK::FrameRect, file_dialog_res::dialog_frame_rect
        MGTK_CALL MGTK::SetPenSize, file_dialog_res::pensize_normal
        MGTK_CALL MGTK::SetPenMode, penXOR

        BTK_CALL BTK::Draw, file_dialog_res::ok_button_params
        BTK_CALL BTK::Draw, file_dialog_res::cancel_button_params

        jsr     IsChangeDriveAllowed
        ror
        sta     file_dialog_res::change_drive_button_rec::state
        BTK_CALL BTK::Draw, file_dialog_res::change_drive_button_params

        jsr     IsOpenAllowed
        ror
        sta     file_dialog_res::open_button_rec::state
        BTK_CALL BTK::Draw, file_dialog_res::open_button_params

        jsr     IsCloseAllowed
        ror
        sta     file_dialog_res::close_button_rec::state
        BTK_CALL BTK::Draw, file_dialog_res::close_button_params

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::SetPattern, file_dialog_res::winfo::penpattern
        MGTK_CALL MGTK::MoveTo, file_dialog_res::dialog_sep_start
        MGTK_CALL MGTK::LineTo, file_dialog_res::dialog_sep_end
        MGTK_CALL MGTK::SetPattern, file_dialog_res::checkerboard_pattern
        MGTK_CALL MGTK::MoveTo, file_dialog_res::button_sep_start
        MGTK_CALL MGTK::LineTo, file_dialog_res::button_sep_end
        rts
.endproc

;;; ============================================================

.proc DrawOpenLabel
        jsr     IsOpenAllowed
        lda     #0
        ror                     ; C into high bit
        cmp     file_dialog_res::open_button_rec::state
        beq     ret             ; no change

        sta     file_dialog_res::open_button_rec::state
        BTK_CALL BTK::Hilite, file_dialog_res::open_button_params

ret:    rts
.endproc

;;; ============================================================

.proc DrawCloseLabel
        jsr     IsCloseAllowed
        lda     #0
        ror                     ; C into high bit
        cmp     file_dialog_res::close_button_rec::state
        beq     ret             ; no change

        sta     file_dialog_res::close_button_rec::state
        BTK_CALL BTK::Hilite, file_dialog_res::close_button_params

ret:    rts
.endproc

;;; ============================================================

.proc DrawChangeDriveLabel
        jsr     IsChangeDriveAllowed
        lda     #0
        ror                     ; C into high bit
        cmp     file_dialog_res::change_drive_button_rec::state
        beq     ret             ; no change

        sta     file_dialog_res::change_drive_button_rec::state
        BTK_CALL BTK::Hilite, file_dialog_res::change_drive_button_params

ret:    rts
.endproc

;;; ============================================================

.proc CloseWindow
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo_listbox
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo
        copy    #0, file_dialog::only_show_dirs_flag
        jmp     UnsetCursorIBeam
.endproc

;;; ============================================================
;;; Inputs: A,X = string
;;; Output: Copied to `file_dialog_res::filename_buf`
;;; Assert: 15 characters or less

.proc CopyFilenameToBuf
        stax    ptr
        ldx     #kMaxFilenameLength
        ptr := *+1
:       lda     SELF_MODIFIED,x
        sta     file_dialog_res::filename_buf,x
        dex
        bpl     :-
        rts
.endproc

;;; ============================================================

.proc DrawString
        ptr := $06
        params := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        beq     ret
        sta     params+2
        inc16   params
        MGTK_CALL MGTK::DrawText, params
ret:    rts
.endproc

;;; ============================================================

.proc MeasureString
        ptr := $06
        params := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     params+2
        inc16   params
        MGTK_CALL MGTK::TextWidth, params
        ldax    params+3
        rts
.endproc

;;; ============================================================

.proc DrawTitleCentered
        text_params     := $6
        text_addr       := text_params + 0
        text_length     := text_params + 2
        text_width      := text_params + 3

        stax    text_addr       ; input is length-prefixed string
.if FD_EXTENDED
        jsr     AuxLoad
.else
        ldy     #0
        lda     (text_addr),y
.endif
        sta     text_length
        inc16   text_addr ; point past length byte
        MGTK_CALL MGTK::TextWidth, text_params

        sub16   #file_dialog_res::kFilePickerDlgWidth, text_width, file_dialog_res::pos_title::xcoord
        lsr16   file_dialog_res::pos_title::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, file_dialog_res::pos_title
        MGTK_CALL MGTK::DrawText, text_params
        rts
.endproc

;;; ============================================================

.proc DrawInput1Label
        stax    $06
        MGTK_CALL MGTK::MoveTo, file_dialog_res::input1_label_pos
        ldax    $06
        jmp     DrawString
.endproc

;;; ============================================================

.if FD_EXTENDED
.proc DrawInput2Label
        stax    $06
        MGTK_CALL MGTK::MoveTo, file_dialog_res::input2_label_pos
        ldax    $06
        jmp     DrawString
.endproc
.endif

;;; ============================================================

.proc DeviceOnLine
retry:  ldx     device_num
        lda     DEVLST,x

        and     #UNIT_NUM_MASK
        sta     on_line_params::unit_num
        MLI_CALL ON_LINE, on_line_params
        lda     on_line_buffer
        and     #NAME_LENGTH_MASK
        sta     on_line_buffer
        bne     found
        jsr     NextDeviceNum
        jmp     retry

found:  param_call AdjustVolumeNameCase, on_line_buffer
        lda     #0
        sta     path_buf
        param_call AppendToPathBuf, on_line_buffer
        lda     #$FF
        jmp     SetSelectedIndex
.endproc

;;; ============================================================

drive_dir_flag:
        .byte   0

.proc NextDeviceNum
        bit     drive_dir_flag
        bmi     incr

        ;; Decrement
        dec     device_num
        bpl     :+
        copy    DEVCNT, device_num
:       rts

        ;; Increment
incr:   ldx     device_num
        cpx     DEVCNT
        bne     :+
        ldx     #AS_BYTE(-1)
:       inx
        stx     device_num
        rts
.endproc

;;; ============================================================
;;; Init `device_number` (index) from the most recently accessed
;;; device via ProDOS Global Page `DEVNUM`. Used when the dialog
;;; is initialized with a specific path.

.if FD_EXTENDED
.proc InitDeviceNumber
        lda     DEVNUM
        sta     last

        ldx     DEVCNT
        inx
:       dex
        lda     DEVLST,x
        and     #UNIT_NUM_MASK
        cmp     last
        bne     :-
        stx     device_num
        rts

last:   .byte   0
.endproc
.endif

;;; ============================================================

.proc OpenDir
.if !FD_EXTENDED
retry:
.endif
        lda     #$00
        sta     open_dir_flag
.if FD_EXTENDED
retry:
.endif
        MLI_CALL OPEN, open_params
        beq     :+
        jsr     DeviceOnLine
        lda     #$FF
        jsr     SetSelectedIndex
.if !FD_EXTENDED
        lda     #$FF
.endif
        sta     open_dir_flag
        jmp     retry

:       lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        beq     :+
        jsr     DeviceOnLine
        lda     #$FF
        jsr     SetSelectedIndex
.if FD_EXTENDED
        sta     open_dir_flag
.endif
        jmp     retry

:       rts
.endproc

open_dir_flag:
        .byte   0

;;; ============================================================

.proc AppendToPathBuf
        ptr := $06
        stax    ptr
        ldx     path_buf
        lda     #'/'
        sta     path_buf+1,x
        inc     path_buf
        ldy     #0
        lda     (ptr),y
        tay
        clc
        adc     path_buf
.if FD_EXTENDED
        ;; Enough room?
        cmp     #kPathBufferSize
        bcc     :+
        return  #$FF            ; failure
:
.endif
        pha
        tax
:       lda     (ptr),y
        sta     path_buf,x
        dey
        dex
        cpx     path_buf
        bne     :-

        pla
        sta     path_buf

.if FD_EXTENDED
        lda     #0
.endif
        rts
.endproc

;;; ============================================================

.proc StripPathBufSegment
:       ldx     path_buf
        cpx     #0
        beq     :+
        dec     path_buf
        lda     path_buf,x
        cmp     #'/'
        bne     :-
:       rts
.endproc

;;; ============================================================

.proc ReadDir
        jsr     OpenDir
        lda     #0
        sta     d1
        sta     d2
        sta     dir_count
        lda     #1
        sta     d3
        copy16  dir_read_buf+SubdirectoryHeader::entry_length, entry_length
        lda     dir_read_buf+SubdirectoryHeader::file_count
        and     #$7F
        sta     num_file_names
        bne     :+
        jmp     close

        ptr := $06
:       copy16  #dir_read_buf+.sizeof(SubdirectoryHeader), ptr

l1:     param_call_indirect AdjustFileEntryCase, ptr

        ldy     #0
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        bne     l2
        jmp     l6

l2:     ldx     d1
        txa
        sta     file_list_index,x
        ldy     #0
        lda     (ptr),y
        and     #STORAGE_TYPE_MASK
        cmp     #ST_LINKED_DIRECTORY << 4
        beq     l3
        bit     only_show_dirs_flag
        bpl     l4
        inc     d2
        jmp     l6

l3:     lda     file_list_index,x
        ora     #$80
        sta     file_list_index,x
        inc     dir_count
l4:     ldy     #$00
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        sta     (ptr),y

        dst_ptr := $08
        lda     d1
        jsr     GetNthFilename
        stax    dst_ptr

        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     (dst_ptr),y
        dey
        bpl     :-

        inc     d1
        inc     d2
l6:     inc     d3
        lda     d2
        cmp     num_file_names
        bne     next

close:  MLI_CALL CLOSE, close_params
        bit     only_show_dirs_flag
        bpl     :+
        lda     dir_count
        sta     num_file_names
:       jsr     SortFileNames
        jsr     SetPtrAfterFilenames
        lda     open_dir_flag
        bpl     l9
        sec
        rts

l9:     clc
        rts

next:   lda     d3
        cmp     d4
        beq     :+
        add16_8 ptr, entry_length
        jmp     l1

:       MLI_CALL READ, read_params
        copy16  #dir_read_buf+$04, ptr
        lda     #$00
        sta     d3
        jmp     l1

d1:     .byte   0
d2:     .byte   0
d3:     .byte   0
entry_length:
        .byte   0
d4:     .byte   0
.endproc


;;; ============================================================

.proc UpdateDiskName
        jsr     SetPortForDialog
        MGTK_CALL MGTK::PaintRect, file_dialog_res::disk_name_rect
        copy16  #path_buf, $06

        ;; Copy first segment
        ldy     #0
        ldx     #2              ; skip leading slash
:       lda     path_buf,x
        cmp     #'/'
        beq     finish
        iny
        sta     file_dialog_res::filename_buf,y
        cpx     path_buf
        beq     finish
        inx
        bne     :-

finish: sty     file_dialog_res::filename_buf

        MGTK_CALL MGTK::MoveTo, file_dialog_res::disk_label_pos
        param_call DrawString, file_dialog_res::disk_label_str
        param_call DrawString, file_dialog_res::filename_buf

        rts
.endproc

;;; ============================================================

.proc SetPortForList
        lda     #file_dialog_res::kEntryListCtlWindowID
        bne     SetPortForWindow ; always
.endproc

.proc SetPortForDialog
        lda     #file_dialog_res::kFilePickerDlgWindowID
        FALL_THROUGH_TO SetPortForWindow
.endproc

.proc SetPortForWindow
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured.
        MGTK_CALL MGTK::SetPort, window_grafport
        rts
.endproc

;;; ============================================================
;;; Sorting

.proc SortFileNames
        lda     #$7F            ; beyond last possible name char
        ldx     #15
:       sta     name_buf+1,x
        dex
        bpl     :-

        lda     #0
        sta     outer_index
        sta     inner_index

loop:   lda     outer_index     ; outer loop
        cmp     num_file_names
        bne     loop2
        jmp     finish

loop2:  lda     inner_index     ; inner loop
        jsr     SetPtrToNthFilename
        ldy     #0
        lda     ($06),y
        bmi     next_inner
        and     #NAME_LENGTH_MASK
        sta     name_buf        ; length

        ldy     #1
l3:     lda     ($06),y
        jsr     UpcaseChar
        cmp     name_buf,y
        beq     :+
        bcs     next_inner
        jmp     l5

:       cpy     name_buf
        beq     l5
        iny
        cpy     #16
        bne     l3
        jmp     next_inner

l5:     lda     inner_index
        sta     d1

        ldx     #15
        lda     #' '            ; before first possible name char
:       sta     name_buf+1,x
        dex
        bpl     :-

        ldy     name_buf
:       lda     ($06),y
        jsr     UpcaseChar
        sta     name_buf,y
        dey
        bne     :-

next_inner:
        inc     inner_index
        lda     inner_index
        cmp     num_file_names
        beq     :+
        jmp     loop2

:       lda     d1
        jsr     SetPtrToNthFilename
        ldy     #0              ; mark as done
        lda     ($06),y
        ora     #$80
        sta     ($06),y

        lda     #$7F            ; beyond last possible name char
        ldx     #15             ; max length
:       sta     name_buf+1,x
        dex
        bpl     :-

        ldx     outer_index
        lda     d1
        sta     d2,x
        lda     #0
        sta     inner_index
        inc     outer_index
        jmp     loop

        ;; Finish up
finish: ldx     num_file_names
        dex
        stx     outer_index
l10:    lda     outer_index
        bpl     l14
        ldx     num_file_names
        beq     done
        dex
l11:    lda     d2,x
        tay
        lda     file_list_index,y
        bpl     l12
        lda     d2,x
        ora     #$80
        sta     d2,x
l12:    dex
        bpl     l11

        ldx     num_file_names
        beq     done
        dex
:       lda     d2,x
        sta     file_list_index,x
        dex
        bpl     :-

done:   rts

l14:    jsr     SetPtrToNthFilename
        ldy     #0
        lda     ($06),y
        and     #$7F
        sta     ($06),y
        dec     outer_index
        jmp     l10

inner_index:
        .byte   0
outer_index:
        .byte   0
d1:     .byte   0
name_buf:
        .res    17, 0

d2:     .res    127, 0

.endproc ; SortFileNames

;;; ============================================================


.proc VerifyValidPath
        ptr := $06

        stax    ptr
        ldy     #$01
        lda     (ptr),y
        cmp     #'/'            ; must be a full path
        bne     fail
        dey
        lda     (ptr),y
        cmp     #2              ; must include vol name
        bcc     fail
        tay
        lda     (ptr),y
        cmp     #'/'
        beq     fail            ; can't end in '/'

        ldx     #0
        stx     index
l1:     lda     (ptr),y
        cmp     #'/'
        beq     l2
        inx
        cpx     #16
        beq     fail
        dey
        bne     l1
        beq     l3
l2:     inc     index
        ldx     #0
        dey
        bne     l1

l3:
.if !FD_EXTENDED
        lda     index
        cmp     #2
        bcc     fail
.endif

        ldy     #0
        lda     (ptr),y
        tay
l4:     lda     (ptr),y
        cmp     #'.'
        beq     l5
        cmp     #'/'
        bcc     fail
        cmp     #'9'+1
        bcc     l5
        cmp     #'A'
        bcc     fail
        cmp     #'Z'+1
        bcc     l5
        cmp     #'a'
        bcc     fail
        cmp     #'z'+1
        bcs     fail
l5:     dey
        bne     l4
        return  #$00

fail:   return  #$FF

index:  .byte   0
.endproc

.proc VerifyValidNonVolumePath
        ptr := $06
        jsr     VerifyValidPath ; stores A,X to $06
        bne     ret

        ;; Valid, so make sure it's not a volume - find last '/'
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        cmp     #'/'
        beq     :+
        dey
        bpl     :-

:       cpy     #1
        beq     fail
        lda     #0
        rts
fail:   lda     #$FF
ret:    rts
.endproc

;;; ============================================================

.proc SetPtrAfterFilenames
        ptr := $06

        lda     num_file_names
        bne     iter
done:   rts

iter:   lda     #0
        sta     index
        copy16  #file_names, ptr
loop:   lda     index
        cmp     num_file_names
        beq     done
        inc     index

        ;; TODO: Replace this with <<4
        lda     ptr
        clc
        adc     #16
        sta     ptr
        bcc     loop
        inc     ptr+1

        jmp     loop

index:  .byte   0
.endproc

;;; ============================================================
;;; Find index to filename in file_list_index.
;;; Input: $06 = ptr to filename
;;; Output: A = index, or $FF if not found

.if FD_EXTENDED
.proc FindFilenameIndex
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     d2,y
        dey
        bpl     :-
        lda     #$00
        sta     d1
        copy16  #file_names, $06
l1:     lda     d1
        cmp     num_file_names
        beq     l4
        ldy     #$00
        lda     ($06),y
        cmp     d2
        bne     l3
        tay
l2:     lda     ($06),y
        cmp     d2,y
        bne     l3
        dey
        bne     l2
        jmp     l5

l3:     inc     d1
        lda     $06
        clc
        adc     #$10
        sta     $06
        bcc     l1
        inc     $07
        jmp     l1

l4:     return  #$FF

l5:     ldx     num_file_names
l6:     dex
        lda     file_list_index,x
        and     #$7F
        cmp     d1
        bne     l6
        txa
        rts

d1:     .byte   0
d2:     .res    16, 0
.endproc
.endif

;;; ============================================================
;;; Input: A = Selection, or $FF if none
;;; Output: top index to show so selection is in view

.proc CalcTopIndex
        bpl     has_sel
        return  #0

has_sel:
        cmp     file_dialog_res::winfo_listbox::vthumbpos
    IF_LT
        rts
    END_IF

        sec
        sbc     #file_dialog_res::kListRows-1
        bmi     no_change
        cmp     file_dialog_res::winfo_listbox::vthumbpos
        beq     no_change
    IF_GE
        rts
    END_IF

no_change:
        lda     file_dialog_res::winfo_listbox::vthumbpos
        rts
.endproc

;;; ============================================================
;;; Text Input Field 1
;;; ============================================================

.scope f1
.proc Idle
        LETK_CALL LETK::Idle, file_dialog_res::le_params_f1
        rts
.endproc
.proc Activate
        LETK_CALL LETK::Activate, file_dialog_res::le_params_f1
        rts
.endproc
.proc Deactivate
        LETK_CALL LETK::Deactivate, file_dialog_res::le_params_f1
        rts
.endproc
.proc Key
        copy    event_params::key, file_dialog_res::le_params_f1::key
        copy    event_params::modifiers, file_dialog_res::le_params_f1::modifiers
        LETK_CALL LETK::Key, file_dialog_res::le_params_f1
        bit     file_dialog_res::line_edit_f1::dirty_flag
    IF_NS
        copy    #0, file_dialog_res::line_edit_f1::dirty_flag
        jsr     NotifyTextChangedF1
    END_IF
        rts
.endproc
.proc Click
        COPY_STRUCT MGTK::Point, screentowindow_params::window, file_dialog_res::le_params_f1::coords
        LETK_CALL LETK::Click, file_dialog_res::le_params_f1
        rts
.endproc
.proc Update
        LETK_CALL LETK::Update, file_dialog_res::le_params_f1
        rts
.endproc

.endscope ; f1

f1__Click := f1::Click

;;; ============================================================

.proc PrepPathF1
        COPY_STRING path_buf, buf_input1
        rts
.endproc

;;; ============================================================
;;; Text Input Field 2
;;; ============================================================

.if FD_EXTENDED
.scope f2
.proc Idle
        LETK_CALL LETK::Idle, file_dialog_res::le_params_f2
        rts
.endproc
.proc Activate
        LETK_CALL LETK::Activate, file_dialog_res::le_params_f2
        rts
.endproc
.proc Deactivate
        LETK_CALL LETK::Deactivate, file_dialog_res::le_params_f2
        rts
.endproc
.proc Key
        copy    event_params::key, file_dialog_res::le_params_f2::key
        copy    event_params::modifiers, file_dialog_res::le_params_f2::modifiers
        LETK_CALL LETK::Key, file_dialog_res::le_params_f2
        bit     file_dialog_res::line_edit_f2::dirty_flag
    IF_NS
        copy    #0, file_dialog_res::line_edit_f2::dirty_flag
        jsr     NotifyTextChangedF2
    END_IF
        rts
.endproc
.proc Click
        COPY_STRUCT MGTK::Point, screentowindow_params::window, file_dialog_res::le_params_f2::coords
        LETK_CALL LETK::Click, file_dialog_res::le_params_f2
        rts
.endproc
.proc Update
        LETK_CALL LETK::Update, file_dialog_res::le_params_f2
        rts
.endproc

.endscope ; f2

f2__Click := f2::Click

.endif ; FD_EXTENDED

;;; ============================================================

.proc LineEditInit
        LETK_CALL LETK::Init, file_dialog_res::le_params_f1
.if FD_EXTENDED
        LETK_CALL LETK::Init, file_dialog_res::le_params_f2
.endif
        rts
.endproc

;;; ============================================================


.if !FD_EXTENDED

;;; Alias table - replaces jump table in hookable version

PrepPath        := PrepPathF1
Idle            := f1::Idle
Activate        := f1::Activate
Deactivate      := f1::Deactivate
Key             := f1::Key
Click           := f1::Click
Update          := f1::Update

.else

;;; Dynamically altered table of handlers for focused
;;; input field (e.g. source/destination filename, etc)

kJumpTableSize = 6
jump_table:
HandleOk:             jmp     0
HandleCancel:         jmp     0
        .assert * - jump_table = kJumpTableSize, error, "Table size mismatch"

Idle:
        bit     focus_in_input2_flag
        jpl     f1::Idle
        jmp     f2::Idle

Activate:
        bit     focus_in_input2_flag
        jpl     f1::Activate
        jmp     f2::Activate

Deactivate:
        bit     focus_in_input2_flag
        jpl     f1::Deactivate
        jmp     f2::Deactivate

PrepPath:
        bit     focus_in_input2_flag
        jpl     PrepPathF1
        jmp     PrepPathF2

Key:
        bit     focus_in_input2_flag
        jpl     f1::Key
        jmp     f2::Key

Click:
        bit     focus_in_input2_flag
        jpl     f1::Click
        jmp     f2::Click

Update:
        bit     focus_in_input2_flag
        jpl     f1::Update
        jmp     f2::Update

.endif

;;; ============================================================

.proc HandleSelectionChange
        ptr := $06

        ;; Find name of selected item
        copy16  #file_names, ptr
        ldx     selected_index
        lda     file_list_index,x
        and     #$7F
        jsr     GetNthFilename

        ;; Append selected name to path temporarily
        jsr     AppendToPathBuf

        ;; Copy it into appropriate text buf
        jsr     PrepPath

        ;; And restore path
        jsr     StripPathBufSegment

        jsr     Update          ; string changed
        jsr     Activate        ; move IP to end

        rts
.endproc

;;; ============================================================

.if FD_EXTENDED
.proc PrepPathF2
        buf_text := buf_input2

        ;; Whenever the path is updated, preserve last segment of
        ;; the path (the filename) as a suffix. This is fairly
        ;; specific to "Copy a File".

        copy    #0, buf_filename

        ;; Search for last '/'
        ldx     buf_text
        beq     do_copy
:       lda     buf_text,x
        cmp     #'/'
        beq     :+
        dex
        beq     do_copy
        bne     :-              ; always
:
        ;; Copy slash and last segment to filename
        ldy     #1
:       lda     buf_text,x
        sta     buf_filename,y
        cpx     buf_text
        beq     :+
        iny
        inx
        bne     :-              ; always

:       sty     buf_filename

do_copy:
        ;; Update the text with the new path
        COPY_STRING path_buf, buf_text

        ;; Append filename if not blank
        lda     buf_filename
        beq     finish
        ldx     buf_text
        inx
        ldy     #1
:       lda     buf_filename,y
        sta     buf_text,x
        cpy     buf_filename
        beq     :+
        iny
        inx
        bne     :-              ; always
:       stx     buf_text

finish:
        rts
.endproc
.endif

;;; ============================================================
;;; Set the `file_dialog_res::input_dirty_flag`
;;; Flag is set if:
;;; * Current text in active input field is case-sensitive match
;;;   for the current path (if no selection), or current
;;;   path+selected filename (if there is a selection).
;;; The flag is used to control:
;;; * Destination Cancel in file copy (alters how state is reset)
;;; * How Return is handled in Selector (if set and no sel, ignore)

.if !FD_EXTENDED

.proc NotifyTextChangedF1
        ldax    #buf_input1

.else

.proc NotifyTextChanged
f2:     ldax    #buf_input2
        jmp     common

f1:     ldax    #buf_input1

common:

.endif
        ptr := $08
        stax    ptr

        ;; Build full path (with seleciton or not) into `path_buf`
        lda     selected_index
        pha
        bmi     compare_paths   ; no selection

        tax
        lda     file_list_index,x
        and     #$7F            ; mask off "is folder?" bit
        jsr     GetNthFilename
        jsr     AppendToPathBuf
        copy    #$FF, selected_index ; TODO: Remove?

        ;; Compare with path buf
        ;; NOTE: Case sensitive, since we're always comparing adjusted paths.
compare_paths:
        ldy     #0
        lda     (ptr),y
        cmp     path_buf
        bne     no_match
        tay
:       lda     (ptr),y
        cmp     path_buf,y
        bne     no_match
        dey
        bne     :-

        ;; Matched
        lda     #0
        beq     update_flag     ; always

        ;; Did not match
no_match:
        lda     #$FF
        FALL_THROUGH_TO update_flag

update_flag:
        sta     file_dialog_res::input_dirty_flag

        ;; Restore selection following `AppendToPathBuf` call above.
        pla
        sta     selected_index
        bmi     :+
        jsr     StripPathBufSegment
:       rts
.endproc
.if FD_EXTENDED
NotifyTextChangedF1 := NotifyTextChanged::f1
NotifyTextChangedF2 := NotifyTextChanged::f2
.endif

;;; ============================================================

.proc OnListSelectionChange
        jsr     UpdateDynamicButtons
        jmp     HandleSelectionChange
.endproc

;;; ============================================================
;;; List Box
;;; ============================================================

.scope listbox
        kWindowId = file_dialog_res::kEntryListCtlWindowID
        winfo = file_dialog_res::winfo_listbox
        kHeight = file_dialog_res::winfo_listbox::kHeight
        kRows = file_dialog_res::kListRows
        num_items = num_file_names
        highlight_rect = file_dialog_res::rect_selection
        item_pos = file_dialog_res::picker_entry_pos
.endscope
listbox::selected_index = selected_index

;;; ============================================================
;;; Output: Z=1/A=$00 on click on an item
;;;         N=1/A=$FF otherwise

.proc HandleListClick
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
    IF_EQ
        jsr     HandleListScroll
        return  #$FF            ; not an item
    END_IF

        cmp     #MGTK::Ctl::not_a_control
    IF_NE
        return  #$FF            ; not an item
    END_IF

        copy    #listbox::kWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        add16   screentowindow_params::windowy, listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::y1, screentowindow_params::windowy
        ldax    screentowindow_params::windowy
        ldy     #kListItemHeight
        jsr     Divide_16_8_16

        ;; Validate
        cmp     listbox::num_items
    IF_GE
        return  #$FF            ; not an item
    END_IF

        ;; Update selection (if different)
        cmp     listbox::selected_index
    IF_NE
        pha
        lda     listbox::selected_index
        jsr     HighlightIndex
        pla
        sta     listbox::selected_index
        jsr     HighlightIndex

        jsr     OnListSelectionChange
    END_IF

        return  #0              ; an item
.endproc

;;; ============================================================

.proc HandleListScrollWithPart
        sta     findcontrol_params::which_part
        FALL_THROUGH_TO HandleListScroll
.endproc

.proc HandleListScroll
        ;; Ignore unless vscroll is enabled
        lda     listbox::winfo+MGTK::Winfo::vscroll
        and     #MGTK::Scroll::option_active
        bne     :+
ret:    rts
:
        lda     findcontrol_params::which_part

        ;; --------------------------------------------------

        cmp     #MGTK::Part::up_arrow
    IF_EQ
repeat: lda     listbox::winfo+MGTK::Winfo::vthumbpos
        beq     ret

        sec
        sbc     #1
        jsr     update
        jsr     CheckArrowRepeat
        jmp     repeat
    END_IF

        ;; --------------------------------------------------

        cmp     #MGTK::Part::down_arrow
    IF_EQ
repeat: lda     listbox::winfo+MGTK::Winfo::vthumbpos
        cmp     listbox::winfo+MGTK::Winfo::vthumbmax
        beq     ret

        clc
        adc     #1
        jsr     update
        jsr     CheckArrowRepeat
        jmp     repeat
    END_IF

        ;; --------------------------------------------------

        cmp     #MGTK::Part::page_up
    IF_EQ
        lda     listbox::winfo+MGTK::Winfo::vthumbpos
        cmp     #listbox::kRows
        bcs     :+
        lda     #0
        beq     update          ; always
:       sbc     #listbox::kRows
        jmp     update
    END_IF

        ;; --------------------------------------------------

        cmp     #MGTK::Part::page_down
    IF_EQ
        lda     listbox::winfo+MGTK::Winfo::vthumbpos
        clc
        adc     #listbox::kRows
        cmp     listbox::winfo+MGTK::Winfo::vthumbmax
        bcc     update
        lda     listbox::winfo+MGTK::Winfo::vthumbmax
        jmp     update
    END_IF

        ;; --------------------------------------------------

        copy    #MGTK::Ctl::vertical_scroll_bar, trackthumb_params::which_ctl
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        beq     ret
        lda     trackthumb_params::thumbpos
        FALL_THROUGH_TO update

        ;; --------------------------------------------------

update: sta     updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params

        jsr     UpdateViewport
        jmp     DrawListEntries
.endproc

;;; ============================================================

.proc CheckArrowRepeat
        MGTK_CALL MGTK::PeekEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     :+
        cmp     #MGTK::EventKind::drag
        bne     cancel
:
        MGTK_CALL MGTK::GetEvent, event_params
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #listbox::kWindowId
        bne     cancel

        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        bne     cancel

        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     cancel

        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::page_up ; up_arrow or down_arrow ?
        bcc     ret                  ; Yes, continue

cancel: pla
        pla
ret:    rts
.endproc

;;; ============================================================
;;; Input: A=character
;;; Output: Z=1 if up/down, Z=0 if not

.proc IsListKey
        cmp     #CHAR_UP
        beq     ret
        cmp     #CHAR_DOWN
ret:    rts
.endproc

;;; ============================================================

.proc HandleListKey
        lda     listbox::num_items
        bne     :+
ret:    rts
:
        lda     event_params::key
        ldx     event_params::modifiers

        ;; No modifiers
    IF_ZERO
        cmp     #CHAR_UP
      IF_EQ
        ldx     listbox::selected_index
        beq     ret
       IF_NS
        ldx     listbox::num_items
       END_IF
        dex
        txa
        bpl     SetSelection    ; always
      END_IF
        ;; CHAR_DOWN
        ldx     listbox::selected_index
      IF_NS
        ldx     #0
      ELSE
        inx
        cpx     listbox::num_items
        beq     ret
      END_IF
        txa
        bpl     SetSelection    ; always
    END_IF

        ;; Double modifiers
        cpx     #3
    IF_EQ
        cmp     #CHAR_UP
      IF_EQ
        lda     listbox::selected_index
        beq     ret
        lda     #0
        bpl     SetSelection    ; always
      END_IF
        ;; CHAR_DOWN
        ldx     listbox::selected_index
      IF_NC
        inx
        cpx     listbox::num_items
        beq     ret
      END_IF
        ldx     listbox::num_items
        dex
        txa
        bpl     SetSelection    ; always
    END_IF

        ;; Single modifier
        cmp     #CHAR_UP
    IF_EQ
        lda     #MGTK::Part::page_up
        jmp     HandleListScrollWithPart
    END_IF
        ;; CHAR_DOWN
        lda     #MGTK::Part::page_down
        jmp     HandleListScrollWithPart

SetSelection:
        pha                     ; A = new selection
        lda     listbox::selected_index
        jsr     HighlightIndex
        pla                     ; A = new selection
        sta     listbox::selected_index
        jsr     ScrollIntoView

        jmp     OnListSelectionChange
.endproc

;;; ============================================================
;;; Inputs: A = entry index

.proc HighlightIndex
        cmp     #0              ; don't assume caller has flags set
        bmi     ret

        ldx     #0              ; A,X = entry
        ldy     #kListItemHeight
        jsr     Multiply_16_8_16
        stax    listbox::highlight_rect+MGTK::Rect::y1
        addax   #kListItemHeight-1, listbox::highlight_rect+MGTK::Rect::y2

        jsr     SetPortForList
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, listbox::highlight_rect
ret:    rts
.endproc

;;; ============================================================
;;; Enable/disable scrollbar as appropriate; resets thumb pos.
;;; Assert: `listbox::num_items` is set.

.proc EnableScrollbar
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl

        lda     listbox::num_items
        cmp     #listbox::kRows + 1
    IF_LT
        copy    #0, updatethumb_params::thumbpos
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params

        copy    #MGTK::activatectl_deactivate, activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params

        rts
    END_IF

        copy    #0, updatethumb_params::thumbpos
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params

        lda     listbox::num_items
        sec
        sbc     #listbox::kRows
        sta     setctlmax_params::ctlmax
        MGTK_CALL MGTK::SetCtlMax, setctlmax_params

        copy    #MGTK::activatectl_activate, activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params

        rts
.endproc

;;; ============================================================
;;; Input: A = row to ensure visible
;;; Assert: `listbox::winfo+MGTK::Winfo::vthumbpos` is set.

.proc ScrollIntoView
        cmp     listbox::winfo+MGTK::Winfo::vthumbpos
    IF_LT
        sta     updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     UpdateViewport
        jmp     DrawListEntries
    END_IF

        sec
        sbc     #listbox::kRows-1
        bmi     skip
        cmp     listbox::winfo+MGTK::Winfo::vthumbpos
        beq     skip
    IF_GE
        sta     updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     UpdateViewport
        jmp     DrawListEntries
    END_IF

skip:   lda     listbox::selected_index
        jmp     HighlightIndex
.endproc

;;; ============================================================

.proc UpdateViewport
        ldax    #kListItemHeight
        ldy     listbox::winfo+MGTK::Winfo::vthumbpos
        jsr     Multiply_16_8_16
        stax    listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::y1
        addax   #listbox::kHeight, listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::y2

        rts
.endproc

;;; ============================================================

;;; Calls `DrawListEntryProc` for each entry.
.proc DrawListEntries
        jsr     SetPortForList

        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::PaintRect, listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect

        lda     listbox::num_items
        beq     ret

        lda     #0
        sta     index
        copy16  #kListItemTextOffsetY, listbox::item_pos+MGTK::Point::ycoord

loop:   copy16  #kListItemTextOffsetX, listbox::item_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, listbox::item_pos

        index := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     DrawListEntryProc

        add16_8  listbox::item_pos+MGTK::Point::ycoord, #kListItemHeight

.if 1
        lda     index
        cmp     listbox::selected_index
    IF_EQ
        jsr     HighlightIndex
    END_IF
.endif

        inc     index
        lda     index
        cmp     listbox::num_items
        bne     loop

        MGTK_CALL MGTK::ShowCursor
ret:    rts
.endproc

;;; ============================================================

;;; Called with A = index
.proc DrawListEntryProc
        tax
        lda     file_list_index,x
        pha
        and     #$7F

        jsr     GetNthFilename
        jsr     CopyFilenameToBuf
        copy16  #file_dialog_res::kListEntryNameX, listbox::item_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, listbox::item_pos
        param_call DrawString, file_dialog_res::filename_buf

        ;; Folder glyph?
        pla
    IF_NS
        copy16  #file_dialog_res::kListEntryGlyphX, listbox::item_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, listbox::item_pos
        param_call DrawString, file_dialog_res::str_folder
    END_IF

        rts
.endproc

;;; ============================================================
