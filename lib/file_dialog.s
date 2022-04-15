;;; ============================================================
;;; Common File Picker Dialog
;;;
;;; Required includes:
;;; * lib/file_dialog_res.s
;;; * lib/line_edit_res.s
;;; * lib/event_params.s
;;; * lib/muldiv.s
;;; Requires the following proc definitions:
;;; * `AdjustFileEntryCase`
;;; * `AdjustVolumeNameCase`
;;; * `ButtonEventLoop`
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

kListEntryHeight = kSystemFontHeight
kListEntryGlyphX = 1
kListEntryNameX  = 16

kLineDelta = 1
kPageDelta = 8

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

;;; ============================================================

.if FD_EXTENDED
routine_table:
        .addr   kOverlayFileCopyAddress
        .addr   kOverlayFileDeleteAddress
        .addr   kOverlaySelector2Address
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

        jsr     LineEditInit

        lda     #0
        sta     file_dialog_res::type_down_buf
        sta     only_show_dirs_flag
        sta     cursor_ibeam_flag
        sta     extra_controls_flag
        sta     listbox_disabled_flag
.if FD_EXTENDED
        sta     input1_dirty_flag
        sta     input2_dirty_flag
        sta     dual_inputs_flag
.endif

        copy    #$FF, file_dialog_res::selected_index

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
        copy    #0, file_dialog_res::type_down_buf
is_btn: jsr     HandleButtonDown
        jmp     EventLoop

:       cmp     #MGTK::EventKind::key_down
        bne     :+
        jsr     HandleKeyEvent
        jmp     EventLoop

:       jsr     CheckMouseMoved
        bcc     EventLoop

        copy    #0, file_dialog_res::type_down_buf

        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        jeq     EventLoop

        lda     findwindow_params::window_id
        cmp     file_dialog_res::winfo::window_id
        beq     l1
        jsr     UnsetCursorIBeam
        jmp     EventLoop

l1:     jsr     SetPortForDialog
        lda     file_dialog_res::winfo::window_id
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::windowx

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

l4:     jsr     UnsetCursorIBeam
l5:     jmp     EventLoop
.endproc

.if FD_EXTENDED
focus_in_input2_flag:
        .byte   0
.endif

;;; ============================================================

.proc HandleButtonDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        bne     :+
        rts

:       cmp     #MGTK::Area::content
        jeq     HandleContentClick

        rts
.endproc

.proc HandleContentClick
        lda     findwindow_params::window_id
        cmp     file_dialog_res::winfo::window_id
        beq     :+
        jmp     HandleListButtonDown

:       jsr     SetPortForDialog
        lda     file_dialog_res::winfo::window_id
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::windowx

        ;; --------------------------------------------------
        ;; Open button

        MGTK_CALL MGTK::InRect, file_dialog_res::open_button_rect
        cmp     #MGTK::inrect_inside
     IF_EQ
        bit     listbox_disabled_flag
        bmi     l1
        lda     file_dialog_res::selected_index
        bpl     l2
l1:     jmp     SetUpPorts

l2:     tax
        lda     file_list_index,x
        bmi     l4
l3:     jmp     SetUpPorts

l4:     jsr     SetPortForDialog
        param_call ButtonEventLoop, file_dialog_res::kFilePickerDlgWindowID, file_dialog_res::open_button_rect
        bmi     l3
        jsr     OpenSelectedItem
        jmp     SetUpPorts
    END_IF

        ;; --------------------------------------------------
        ;; Change Drive button

        MGTK_CALL MGTK::InRect, file_dialog_res::change_drive_button_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        bit     listbox_disabled_flag
        bmi     :+

        param_call ButtonEventLoop, file_dialog_res::kFilePickerDlgWindowID, file_dialog_res::change_drive_button_rect
        bmi     :+
        jsr     ChangeDrive
:
        jmp     SetUpPorts
    END_IF

        ;; --------------------------------------------------
        ;; Close button

        MGTK_CALL MGTK::InRect, file_dialog_res::close_button_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        bit     listbox_disabled_flag
        bmi     :+

        param_call ButtonEventLoop, file_dialog_res::kFilePickerDlgWindowID, file_dialog_res::close_button_rect
        bmi     :+
        jsr     DoClose
:       jmp     SetUpPorts
    END_IF

        ;; --------------------------------------------------
        ;; OK button

        MGTK_CALL MGTK::InRect, file_dialog_res::ok_button_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        param_call ButtonEventLoop, file_dialog_res::kFilePickerDlgWindowID, file_dialog_res::ok_button_rect
        bmi     :+
        jsr     HandleOk
:       jmp     SetUpPorts
    END_IF

        ;; --------------------------------------------------
        ;; Cancel button

        MGTK_CALL MGTK::InRect, file_dialog_res::cancel_button_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        param_call ButtonEventLoop, file_dialog_res::kFilePickerDlgWindowID, file_dialog_res::cancel_button_rect
        bmi     :+
        jsr     HandleCancel
:       jmp     SetUpPorts
    END_IF

        ;; --------------------------------------------------
        ;; Extra controls

        bit     extra_controls_flag
    IF_NS
        jsr     click_handler_hook
        bmi     SetUpPorts      ; if consumed
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
        FALL_THROUGH_TO SetUpPorts

SetUpPorts:
        rts

.endproc ; HandleContentClick

;;; ============================================================
;;; This vector gets patched by overlays that add controls.

click_handler_hook:
        jsr     NoOp
        rts

;;; ============================================================

.proc HandleListButtonDown
        bit     listbox_disabled_flag
        bmi     rts1
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        beq     in_list

        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     rts1
        lda     file_dialog_res::winfo_listbox::vscroll
        and     #MGTK::Ctl::vertical_scroll_bar ; vertical scroll enabled?
        beq     rts1
        jmp     HandleVScrollClick

rts1:   rts

in_list:
        lda     file_dialog_res::winfo_listbox::window_id
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        add16   screentowindow_params::windowy, file_dialog_res::winfo_listbox::cliprect::y1, screentowindow_params::windowy
        ldax    screentowindow_params::windowy
        ldy     #kListEntryHeight
        jsr     Divide_16_8_16
        new_index := screentowindow_params::windowy
        stax    screentowindow_params::windowy

        lda     file_dialog_res::selected_index
        cmp     new_index
        beq     same
        jmp     different

        ;; --------------------------------------------------
        ;; Click on the previous entry

same:   jsr     DetectDoubleClick
        beq     open
        rts

open:   ldx     file_dialog_res::selected_index
        lda     file_list_index,x
        bmi     folder

        ;; File - select it.
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        MGTK_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        jsr     HandleOk
        jmp     rts1

        ;; Folder - open it.
folder: and     #$7F
        pha                     ; A = index

        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_CALL MGTK::PaintRect, file_dialog_res::open_button_rect
        MGTK_CALL MGTK::PaintRect, file_dialog_res::open_button_rect

        pla                     ; A = index
        jsr     GetNthFilename
        jsr     AppendToPathBuf
        copy    #$FF, file_dialog_res::selected_index

        jsr     UpdateListFromPath

        rts

        ;; --------------------------------------------------
        ;; Click on a different entry

different:
        lda     new_index
        cmp     num_file_names
        bcc     :+
        rts

:       lda     file_dialog_res::selected_index
        bmi     :+
        lda     file_dialog_res::selected_index
        jsr     InvertEntry
:       lda     new_index
        sta     file_dialog_res::selected_index
        jsr     InvertEntry
        jsr     HandleSelectionChange

        jsr     DetectDoubleClick
        bmi     :+
        jmp     open

:       rts
.endproc

;;; ============================================================
;;; Refresh the list view from the current path

.proc UpdateListFromPath
        jsr     ReadDir
        jsr     UpdateScrollbar
        lda     #0
        jsr     ScrollClipRect
        jsr     UpdateDiskName
        jmp     DrawListEntries
.endproc

;;; ============================================================

.proc HandleVScrollClick
        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::up_arrow
        jeq     HandleLineUp

        cmp     #MGTK::Part::down_arrow
        jeq     HandleLineDown

        cmp     #MGTK::Part::page_up
        jeq     HandlePageUp

        cmp     #MGTK::Part::page_down
        jeq     HandlePageDown

        ;; Track thumb
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     trackthumb_params::which_ctl
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        bne     :+
        rts

:       lda     trackthumb_params::thumbpos
        jmp     UpdateThumbCommon
.endproc

;;; ============================================================

.proc HandlePageUp
        lda     file_dialog_res::winfo_listbox::vthumbpos
        sec
        sbc     #kPageDelta
        bpl     :+
        lda     #0
:
        jmp     UpdateThumbCommon
.endproc

;;; ============================================================

.proc HandlePageDown
        lda     file_dialog_res::winfo_listbox::vthumbpos
        clc
        adc     #kPageDelta
        cmp     file_dialog_res::winfo_listbox::vthumbmax
        beq     :+
        bcc     :+
        lda     file_dialog_res::winfo_listbox::vthumbmax
:
        jmp     UpdateThumbCommon
.endproc

;;; ============================================================

.proc HandleLineUp
        lda     file_dialog_res::winfo_listbox::vthumbpos
        bne     :+
        rts

:       sec
        sbc     #kLineDelta
        jsr     UpdateThumbCommon
        jsr     CheckArrowRepeat
        jmp     HandleLineUp
.endproc

;;; ============================================================

.proc HandleLineDown
        lda     file_dialog_res::winfo_listbox::vthumbpos
        cmp     file_dialog_res::winfo_listbox::vthumbmax
        bne     :+
        rts

:       clc
        adc     #kLineDelta
        jsr     UpdateThumbCommon
        jsr     CheckArrowRepeat
        jmp     HandleLineDown
.endproc

;;; ============================================================

.proc UpdateThumbCommon
        sta     updatethumb_params::thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_params::thumbpos
        jsr     ScrollClipRect
        jmp     DrawListEntries
.endproc

;;; ============================================================

.proc CheckArrowRepeat
        MGTK_CALL MGTK::PeekEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     :+
        cmp     #MGTK::EventKind::drag
        beq     :+
        pla
        pla
        rts

:       MGTK_CALL MGTK::GetEvent, event_params
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     file_dialog_res::winfo_listbox::window_id
        beq     :+
        pla
        pla
        rts

:       lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        beq     :+
        pla
        pla
        rts

:       MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        beq     :+
        pla
        pla
        rts

:       lda     findcontrol_params::which_part
        cmp     #MGTK::Part::page_up ; up_arrow or down_arrow ?
        bcc     :+                   ; Yes, continue
        pla
        pla
:       rts
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

.proc OpenSelectedItem
        ldx     file_dialog_res::selected_index
        lda     file_list_index,x
        and     #$7F

        jsr     GetNthFilename
        jsr     AppendToPathBuf
        copy    #$FF, file_dialog_res::selected_index
        jsr     PrepPath
        jsr     RedrawInput

        jmp     UpdateListFromPath
.endproc

;;; ============================================================

.proc ChangeDrive
        lda     #$FF
        sta     file_dialog_res::selected_index

        jsr     ModifierDown
        sta     drive_dir_flag
        jsr     ShiftDown
        ora     drive_dir_flag
        sta     drive_dir_flag

        jsr     NextDeviceNum
        jsr     DeviceOnLine

        jsr     UpdateListFromPath

        jsr     PrepPath
        jsr     RedrawInput
        rts
.endproc

;;; ============================================================

.proc DoClose
        ;; Walk back looking for last '/'
        ldx     path_buf
        beq     ret             ; no-op if empty
:       lda     path_buf,x
        cmp     #'/'
        beq     :+
        dex
        bpl     :-
        bmi     ret             ; always

        ;; Volume?
:       cpx     #1
        beq     ret             ; no-op

        ;; Remove last segment
        jsr     StripPathBufSegment

        lda     #$FF
        sta     file_dialog_res::selected_index

        jsr     UpdateListFromPath

        jsr     PrepPath
        jsr     RedrawInput

ret:    rts
.endproc

;;; ============================================================
;;; Key handler

.proc HandleKeyEvent
        lda     event_params::key

        ldx     event_params::modifiers
    IF_NE
        ;; With modifiers
        lda     event_params::key

        bit     listbox_disabled_flag
        bmi     :+
        jsr     CheckTypeDown
        jeq     exit
:
        lda     event_params::key
        cmp     #CHAR_TAB
        jeq     KeyTab

        bit     listbox_disabled_flag
      IF_NC
        cmp     #CHAR_DOWN
        jeq     ScrollListBottom ; end of list

        cmp     #CHAR_UP
        jeq     ScrollListTop   ; start of list
      END_IF

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
        copy    #0, file_dialog_res::type_down_buf
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
        IF_EQ
        lda     file_dialog_res::selected_index
        bmi     exit
        tax
        lda     file_list_index,x
        jpl     exit

        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_CALL MGTK::PaintRect, file_dialog_res::open_button_rect
        MGTK_CALL MGTK::PaintRect, file_dialog_res::open_button_rect
        jsr     OpenSelectedItem
        jmp     exit
        END_IF

        cmp     #CHAR_CTRL_C    ; Close
        IF_EQ
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_CALL MGTK::PaintRect, file_dialog_res::close_button_rect
        MGTK_CALL MGTK::PaintRect, file_dialog_res::close_button_rect
        jsr     DoClose
        jmp     exit
        END_IF

        cmp     #CHAR_DOWN
        jeq     KeyDown

        cmp     #CHAR_UP
        jeq     KeyUp
      END_IF

        jsr     Key
    END_IF

exit:   rts

;;; ============================================================

.proc KeyReturn
.if !FD_EXTENDED
        lda     file_dialog_res::selected_index
        bpl     :+
        bit     line_edit_res::input_dirty_flag
        bmi     :+
        rts
:
.endif
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        MGTK_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        jsr     HandleOk
        rts
.endproc

;;; ============================================================

.proc KeyEscape
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_CALL MGTK::PaintRect, file_dialog_res::cancel_button_rect
        MGTK_CALL MGTK::PaintRect, file_dialog_res::cancel_button_rect
        jsr     HandleCancel
        rts
.endproc

;;; ============================================================

.proc KeyTab
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_CALL MGTK::PaintRect, file_dialog_res::change_drive_button_rect
        MGTK_CALL MGTK::PaintRect, file_dialog_res::change_drive_button_rect
        jsr     ChangeDrive
        rts
.endproc

;;; ============================================================
;;; This vector gets patched by overlays that add controls.

key_meta_digit:
        jmp     NoOp

;;; ============================================================

.proc KeyDown
        lda     num_file_names
        beq     l1
        lda     file_dialog_res::selected_index
        bmi     l3
        tax
        inx
        cpx     num_file_names
        bcc     l2
l1:     rts

l2:     jsr     InvertEntry
        inc     file_dialog_res::selected_index
        lda     file_dialog_res::selected_index
        jmp     UpdateListSelection

l3:     lda     #0
        jmp     UpdateListSelection
.endproc

;;; ============================================================

.proc KeyUp
        lda     num_file_names
        beq     l1
        lda     file_dialog_res::selected_index
        bmi     l3
        bne     l2
l1:     rts

l2:     jsr     InvertEntry
        dec     file_dialog_res::selected_index
        lda     file_dialog_res::selected_index
        jmp     UpdateListSelection

l3:     ldx     num_file_names
        dex
        txa
        jmp     UpdateListSelection
.endproc

;;; ============================================================

.proc CheckTypeDown
        jsr     UpcaseChar
        cmp     #'A'
        bcc     :+
        cmp     #'Z'+1
        bcc     file_char

:       ldx     file_dialog_res::type_down_buf
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
        ldx     file_dialog_res::type_down_buf
        cpx     #15
        bne     :+
        rts                     ; Z=1 to consume
:
        inx
        stx     file_dialog_res::type_down_buf
        sta     file_dialog_res::type_down_buf,x

        jsr     FindMatch
        bmi     done
        cmp     file_dialog_res::selected_index
        beq     done
        pha
        lda     file_dialog_res::selected_index
        bmi     :+
        jsr     InvertEntry
:       pla
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
        cmp     file_dialog_res::type_down_buf,y
        bcc     next
        beq     :+
        bcs     found
:
        cpy     file_dialog_res::type_down_buf
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

.proc ScrollListTop
        lda     num_file_names
        beq     done
        lda     file_dialog_res::selected_index
        bmi     select
        bne     deselect
done:   rts

deselect:
        jsr     InvertEntry

select:
        lda     #$00
        jmp     UpdateListSelection
.endproc

;;; ============================================================

.proc ScrollListBottom
        lda     num_file_names
        beq     done
        ldx     file_dialog_res::selected_index
        bmi     l1
        inx
        cpx     num_file_names
        bne     :+
done:   rts

:       dex
        txa
        jsr     InvertEntry
l1:     ldx     num_file_names
        dex
        txa
        jmp     UpdateListSelection
.endproc

;;; ============================================================

.proc UpdateListSelection
        sta     file_dialog_res::selected_index
        jsr     HandleSelectionChange

        lda     file_dialog_res::selected_index
        jsr     CalcTopIndex
        cmp     file_dialog_res::winfo_listbox::vthumbpos
        beq     :+

        ;; View changed - redraw everything
        jsr     UpdateScrollbar2
        jmp     DrawListEntries
:
        ;; No change - just adjust highlights
        lda     file_dialog_res::selected_index
        jmp     InvertEntry
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
        MGTK_CALL MGTK::FrameRect, file_dialog_res::ok_button_rect
        MGTK_CALL MGTK::FrameRect, file_dialog_res::open_button_rect
        MGTK_CALL MGTK::FrameRect, file_dialog_res::close_button_rect
        MGTK_CALL MGTK::FrameRect, file_dialog_res::cancel_button_rect
        MGTK_CALL MGTK::FrameRect, file_dialog_res::change_drive_button_rect
        jsr     DrawOkButtonLabel
        jsr     DrawOpenButtonLabel
        jsr     DrawCloseButtonLabel
        jsr     DrawCancelButtonLabel
        jsr     DrawChangeDriveButtonLabel
        MGTK_CALL MGTK::MoveTo, file_dialog_res::dialog_sep_start
        MGTK_CALL MGTK::LineTo, file_dialog_res::dialog_sep_end
        MGTK_CALL MGTK::SetPattern, file_dialog_res::checkerboard_pattern
        MGTK_CALL MGTK::MoveTo, file_dialog_res::button_sep_start
        MGTK_CALL MGTK::LineTo, file_dialog_res::button_sep_end
        rts
.endproc

.proc DrawOkButtonLabel
        MGTK_CALL MGTK::MoveTo, file_dialog_res::ok_button_pos
        param_call DrawString, file_dialog_res::ok_button_label
        rts
.endproc

.proc DrawOpenButtonLabel
        MGTK_CALL MGTK::MoveTo, file_dialog_res::open_button_pos
        param_call DrawString, file_dialog_res::open_button_label
        rts
.endproc

.proc DrawCloseButtonLabel
        MGTK_CALL MGTK::MoveTo, file_dialog_res::close_button_pos
        param_call DrawString, file_dialog_res::close_button_label
        rts
.endproc

.proc DrawCancelButtonLabel
        MGTK_CALL MGTK::MoveTo, file_dialog_res::cancel_button_pos
        param_call DrawString, file_dialog_res::cancel_button_label
        rts
.endproc

.proc DrawChangeDriveButtonLabel
        MGTK_CALL MGTK::MoveTo, file_dialog_res::change_drive_button_pos
        param_call DrawString, file_dialog_res::change_drive_button_label
        rts
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
        jsr     DrawString
        rts
.endproc

;;; ============================================================

.if FD_EXTENDED
.proc DrawInput2Label
        stax    $06
        MGTK_CALL MGTK::MoveTo, file_dialog_res::input2_label_pos
        ldax    $06
        jsr     DrawString
        rts
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
        copy    #$FF, file_dialog_res::selected_index
        rts
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
        and     #UNIT_NUM_MASK
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
        sta     file_dialog_res::selected_index
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
        sta     file_dialog_res::selected_index
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
        add16_8 ptr, entry_length, ptr
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

.proc DrawListEntries
        jsr     SetPortForList
        MGTK_CALL MGTK::PaintRect, file_dialog_res::winfo_listbox::cliprect
        copy    #kListEntryNameX, file_dialog_res::picker_entry_pos::xcoord ; high byte always 0
        copy16  #kListEntryHeight, file_dialog_res::picker_entry_pos::ycoord
        copy    #0, index

loop:   lda     index
        cmp     num_file_names
        bne     :+
        rts

:       MGTK_CALL MGTK::MoveTo, file_dialog_res::picker_entry_pos
        ldx     index
        lda     file_list_index,x
        and     #$7F

        jsr     GetNthFilename
        jsr     CopyFilenameToBuf
        param_call DrawString, file_dialog_res::filename_buf
        ldx     index
        lda     file_list_index,x
        bpl     :+

        ;; Folder glyph
        copy    #kListEntryGlyphX, file_dialog_res::picker_entry_pos::xcoord
        MGTK_CALL MGTK::MoveTo, file_dialog_res::picker_entry_pos
        param_call DrawString, file_dialog_res::str_folder
        copy    #kListEntryNameX, file_dialog_res::picker_entry_pos::xcoord

:       lda     index
        cmp     file_dialog_res::selected_index
        bne     l2
        jsr     InvertEntry
        jsr     SetPortForList
l2:     inc     index

        add16_8 file_dialog_res::picker_entry_pos::ycoord, #kListEntryHeight, file_dialog_res::picker_entry_pos::ycoord
        jmp     loop

index:  .byte   0
.endproc

;;; ============================================================

UpdateScrollbar:
        lda     #$00

.proc UpdateScrollbar2
        sta     index
        lda     num_file_names
        cmp     #kPageDelta + 1
        bcs     :+
        ;; Deactivate scrollbar
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        copy    #MGTK::activatectl_deactivate, activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        copy    #0, file_dialog_res::winfo_listbox::vthumbmax
        lda     #0
        jmp     ScrollClipRect
:
        ;; Activate scrollbar
        lda     num_file_names
        sec
        sbc     #kPageDelta
        cmp     file_dialog_res::winfo_listbox::vthumbmax
        beq     :+
        sta     file_dialog_res::winfo_listbox::vthumbmax
        .assert MGTK::Ctl::vertical_scroll_bar = MGTK::activatectl_activate, error, "need to match"
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_params::which_ctl
        sta     activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
:
        ;; Update position
        lda     index
        cmp     file_dialog_res::winfo_listbox::vthumbpos
    IF_NE
        sta     updatethumb_params::thumbpos
        jsr     ScrollClipRect
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
    END_IF

        rts

index:  .byte   0
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

.proc ScrollClipRect
        sta     tmp
        clc
        adc     #kPageDelta
        cmp     num_file_names
        beq     l1
        bcs     l2
l1:     lda     tmp
        jmp     l4

l2:     lda     num_file_names
        cmp     #kPageDelta+1
        bcs     l3
        lda     tmp
        jmp     l4

l3:     sec
        sbc     #kPageDelta

l4:     ldx     #$00            ; A,X = line
        ldy     #kListEntryHeight
        jsr     Multiply_16_8_16
        stax    file_dialog_res::winfo_listbox::cliprect::y1
        add16_8 file_dialog_res::winfo_listbox::cliprect::y1, #file_dialog_res::winfo_listbox::kHeight, file_dialog_res::winfo_listbox::cliprect::y2
        rts

tmp:    .byte   0
.endproc

;;; ============================================================
;;; Inputs: A = entry index

.proc InvertEntry
        ldx     #0              ; A,X = entry
        ldy     #kListEntryHeight
        jsr     Multiply_16_8_16
        stax    file_dialog_res::rect_selection::y1

        add16_8 file_dialog_res::rect_selection::y1, #kListEntryHeight, file_dialog_res::rect_selection::y2

        jsr     SetPortForList
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, file_dialog_res::rect_selection
        rts
.endproc

;;; ============================================================

.proc SetPortForDialog
        lda     #file_dialog_res::kFilePickerDlgWindowID
        bne     SetPortForWindow ; always
.endproc
.proc SetPortForList
        lda     #file_dialog_res::kEntryListCtlWindowID
        FALL_THROUGH_TO SetPortForWindow
.endproc
.proc SetPortForWindow
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
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
        sbc     #kPageDelta-1
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
        buf_text := buf_input1
        textpos := file_dialog_res::input1_textpos
        clear_rect := file_dialog_res::input1_clear_rect
        kLineEditMaxLength := kMaxInputLength
        click_coords := screentowindow_params::windowx
        IsAllowedChar := IsPathChar
        NotifyTextChanged := NotifyTextChangedF1
        SetPort := SetPortForDialog

        .include "../lib/line_edit.s"

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

        buf_text := buf_input2
        textpos := file_dialog_res::input2_textpos
        clear_rect := file_dialog_res::input2_clear_rect
        kLineEditMaxLength := kMaxInputLength
        click_coords := screentowindow_params::windowx
        IsAllowedChar := IsPathChar
        NotifyTextChanged := NotifyTextChangedF2
        SetPort := SetPortForDialog

        .include "../lib/line_edit.s"

.endscope ; f2

f2__Click := f2::Click

.endif ; FD_EXTENDED

;;; ============================================================

.proc LineEditInit
        ;; These init `line_edit_res` properties; the two
        ;; calls here are redundant, but future-proof.
        jsr     f1::Init
.if FD_EXTENDED
        jsr     f2::Init
.endif
        rts
.endproc

;;; ============================================================


.if !FD_EXTENDED

;;; Alias table - replaces jump table in hookable version

PrepPath        := PrepPathF1
Idle            := f1::Idle
RedrawInput     := f1::Update
Key             := f1::Key
Click           := f1::Click

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

RedrawInput:
        bit     focus_in_input2_flag
        jpl     f1::Update
        jmp     f2::Update

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

.endif

;;; ============================================================

.proc HandleSelectionChange
        ptr := $06

        ;; Find name of selected item
        copy16  #file_names, ptr
        ldx     file_dialog_res::selected_index
        lda     file_list_index,x
        and     #$7F
        jsr     GetNthFilename

        ;; Append selected name to path temporarily
        jsr     AppendToPathBuf

        ;; Copy it into appropriate text buf
        jsr     PrepPath

        ;; And restore path
        jsr     StripPathBufSegment

        jsr     RedrawInput

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


;;; ============================================================
;;; Set the `line_edit_res::input_dirty_flag`
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
        lda     file_dialog_res::selected_index
        sta     current_selection
        bmi     compare_paths   ; no selection

        tax
        lda     file_list_index,x
        and     #$7F            ; mask off "is folder?" bit
        jsr     GetNthFilename
        jsr     AppendToPathBuf
        copy    #$FF, file_dialog_res::selected_index ; TODO: Remove?

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
        sta     line_edit_res::input_dirty_flag

        ;; Restore selection following `AppendToPathBuf` call above.
        lda     current_selection
        sta     file_dialog_res::selected_index
        bmi     :+
        jsr     StripPathBufSegment
:       rts

current_selection:
        .byte   0
.endproc
.if FD_EXTENDED
NotifyTextChangedF1 := NotifyTextChanged::f1
NotifyTextChangedF2 := NotifyTextChanged::f2
.endif

;;; ============================================================
