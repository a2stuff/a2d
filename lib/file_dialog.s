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
;;; * `ButtonEventLoop`
;;; * `CheckMouseMoved`
;;; * `DetectDoubleClick`
;;; * `MLIRelayImpl`
;;; * `ModifierDown`
;;; * `ShiftDown`
;;; * `YieldLoop`
;;; Requires the following data definitions:
;;; * `buf_text`
;;; * `buf_input1_left`
;;; * `buf_input_right`
;;; * `window_grafport`
;;; * `main_grafport`
;;; * `penXOR`
;;; Requires the following macro definitions:
;;; * `LIB_MGTK_CALL`
;;; * `LIB_MLI_CALL`
;;;
;;; If `FD_EXTENDED` is defined as 1:
;;; * two input fields are supported
;;; * title passed to `DrawTitleCentered` in aux, `AuxLoad` is used
;;; * `buf_input2_left` must be defined

;;; ============================================================

;;; Map from index in file_names to list entry; high bit is
;;; set for directories.
file_list_index := $1780

num_file_names  := $177F

;;; Sequence of 16-byte records, filenames in current directory.
file_names      := $1800

kListEntryHeight = 9            ; Default font height
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
routine_table:  .addr   $7000, $7000, $7000
.endif

;;; ============================================================

.proc Start
.if FD_EXTENDED
        sty     stash_y
        stx     stash_x
.endif
        tsx
        stx     saved_stack
.if FD_EXTENDED
        pha
.else
        jsr     SetCursorPointer
.endif
        copy    DEVCNT, device_num

        lda     #0
        sta     file_dialog_res::type_down_buf
        sta     only_show_dirs_flag
        sta     prompt_ip_flag
.if FD_EXTENDED
        sta     blink_ip_flag
.endif
        sta     input_dirty_flag
.if FD_EXTENDED
        sta     input1_dirty_flag
        sta     input2_dirty_flag
.endif
        sta     cursor_ibeam_flag
.if FD_EXTENDED
        sta     dual_inputs_flag
.endif
        sta     extra_controls_flag
        sta     listbox_disabled_flag

        copy16  SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter
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
.else
        jmp     start
.endif

stash_x:        .byte   0
stash_y:        .byte   0
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
        bit     blink_ip_flag
        bpl     :+

        dec16   prompt_ip_counter
        lda     prompt_ip_counter
        ora     prompt_ip_counter+1
        bne     :+
        jsr     BlinkIP
        copy16  SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter

:       jsr     YieldLoop
        LIB_MGTK_CALL MGTK::GetEvent, event_params

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
        jsr     HandleKey
        jmp     EventLoop

:       jsr     CheckMouseMoved
        bcc     EventLoop

        copy    #0, file_dialog_res::type_down_buf

        LIB_MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        jeq     EventLoop

        lda     findwindow_params::window_id
        cmp     file_dialog_res::winfo::window_id
        beq     l1
        jsr     UnsetCursorIBeam
        jmp     EventLoop

l1:     lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        lda     file_dialog_res::winfo::window_id
        sta     screentowindow_params::window_id
        LIB_MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        LIB_MGTK_CALL MGTK::MoveTo, screentowindow_params::windowx

.if FD_EXTENDED
        bit     focus_in_input2_flag
        bmi     l2
.endif

        LIB_MGTK_CALL MGTK::InRect, file_dialog_res::input1_rect
        cmp     #MGTK::inrect_inside
        bne     l4

.if FD_EXTENDED
        beq     l3
l2:     LIB_MGTK_CALL MGTK::InRect, file_dialog_res::input2_rect
        cmp     #MGTK::inrect_inside
        bne     l4
l3:
.endif

        jsr     SetCursorIBeam
        jmp     l5

l4:     jsr     UnsetCursorIBeam
l5:     LIB_MGTK_CALL MGTK::InitPort, main_grafport
        LIB_MGTK_CALL MGTK::SetPort, main_grafport
        jmp     EventLoop
.endproc

focus_in_input2_flag:
        .byte   0

;;; ============================================================

.proc HandleButtonDown
        LIB_MGTK_CALL MGTK::FindWindow, findwindow_params
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

:       lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        lda     file_dialog_res::winfo::window_id
        sta     screentowindow_params::window_id
        LIB_MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        LIB_MGTK_CALL MGTK::MoveTo, screentowindow_params::windowx

        ;; --------------------------------------------------
.proc CheckOpenButton
        LIB_MGTK_CALL MGTK::InRect, file_dialog_res::open_button_rect
        cmp     #MGTK::inrect_inside
        bne     CheckChangeDriveButton

        bit     listbox_disabled_flag
        bmi     l1
        lda     file_dialog_res::selected_index
        bpl     l2
l1:     jmp     SetUpPorts

l2:     tax
        lda     file_list_index,x
        bmi     l4
l3:     jmp     SetUpPorts

l4:     lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        param_call ButtonEventLoop, file_dialog_res::kFilePickerDlgWindowID, file_dialog_res::open_button_rect
        bmi     l3
        jsr     OpenSelectedItem
        jmp     SetUpPorts
.endproc

        ;; --------------------------------------------------
.proc CheckChangeDriveButton
        LIB_MGTK_CALL MGTK::InRect, file_dialog_res::change_drive_button_rect
        cmp     #MGTK::inrect_inside
        bne     CheckCloseButton
        bit     listbox_disabled_flag
        bmi     :+

        param_call ButtonEventLoop, file_dialog_res::kFilePickerDlgWindowID, file_dialog_res::change_drive_button_rect
        bmi     :+
        jsr     ChangeDrive
:
        jmp     SetUpPorts
.endproc

        ;; --------------------------------------------------
.proc CheckCloseButton
        LIB_MGTK_CALL MGTK::InRect, file_dialog_res::close_button_rect
        cmp     #MGTK::inrect_inside
        bne     CheckOkButton
        bit     listbox_disabled_flag
        bmi     :+

        param_call ButtonEventLoop, file_dialog_res::kFilePickerDlgWindowID, file_dialog_res::close_button_rect
        bmi     :+
        jsr     DoClose
:       jmp     SetUpPorts
.endproc

        ;; --------------------------------------------------
.proc CheckOkButton
        LIB_MGTK_CALL MGTK::InRect, file_dialog_res::ok_button_rect
        cmp     #MGTK::inrect_inside
        bne     CheckCancelButton

        param_call ButtonEventLoop, file_dialog_res::kFilePickerDlgWindowID, file_dialog_res::ok_button_rect
        bmi     :+
        jsr     HandleMetaRightKey
        jsr     HandleOk
:       jmp     SetUpPorts
.endproc

        ;; --------------------------------------------------
.proc CheckCancelButton
        LIB_MGTK_CALL MGTK::InRect, file_dialog_res::cancel_button_rect
        cmp     #MGTK::inrect_inside
        bne     CheckOtherClick

        param_call ButtonEventLoop, file_dialog_res::kFilePickerDlgWindowID, file_dialog_res::cancel_button_rect
        bmi     :+
        jsr     HandleCancel
:       jmp     SetUpPorts
.endproc

        ;; --------------------------------------------------
.proc CheckOtherClick
        bit     extra_controls_flag
        bpl     :+
        jsr     click_handler_hook
        bmi     SetUpPorts
:       jsr     HandleClick
        rts
.endproc

.proc SetUpPorts
        LIB_MGTK_CALL MGTK::InitPort, main_grafport
        LIB_MGTK_CALL MGTK::SetPort, window_grafport
        rts
.endproc

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
        LIB_MGTK_CALL MGTK::FindControl, findcontrol_params
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
        LIB_MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        add16   screentowindow_params::windowy, file_dialog_res::winfo_listbox::cliprect::y1, screentowindow_params::windowy
        ldax    screentowindow_params::windowy
        ldy     #kListEntryHeight
        jsr     Divide_16_8_16
        stax    screentowindow_params::windowy

        lda     file_dialog_res::selected_index
        cmp     screentowindow_params::windowy
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
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        jsr     HandleOk
        jmp     rts1

        ;; Folder - open it.
folder: and     #$7F
        pha
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::open_button_rect
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::open_button_rect
        lda     #0
        sta     hi

        ptr := $08
        copy16  #file_names, ptr
        pla
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        clc
        adc     ptr
        sta     ptr
        lda     hi
        adc     ptr+1
        sta     ptr+1

        ldx     ptr+1
        lda     ptr
        jsr     AppendToPathBuf

        jsr     ReadDir
        jsr     UpdateScrollbar
        lda     #0
        jsr     ScrollClipRect
        jsr     UpdateDiskName
        jsr     DrawListEntries
        LIB_MGTK_CALL MGTK::InitPort, main_grafport
        LIB_MGTK_CALL MGTK::SetPort, window_grafport
        rts

hi:     .byte   0

        ;; --------------------------------------------------
        ;; Click on a different entry

different:
        lda     screentowindow_params::windowy
        cmp     num_file_names
        bcc     :+
        rts

:       lda     file_dialog_res::selected_index
        bmi     :+
        jsr     StripPathSegmentLeftAndRedraw
        lda     file_dialog_res::selected_index
        jsr     InvertEntry
:       lda     screentowindow_params::windowy
        sta     file_dialog_res::selected_index
        bit     input_dirty_flag
        bpl     :+
        jsr     PrepPath
        jsr     RedrawInput
:       lda     file_dialog_res::selected_index
        jsr     InvertEntry
        jsr     HandleSelectionChange

        jsr     DetectDoubleClick
        bmi     :+
        jmp     open

:       rts
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
        LIB_MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        bne     :+
        rts

:       lda     trackthumb_params::thumbpos
        sta     updatethumb_params::thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_params::which_ctl
        LIB_MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_params::stash
        jsr     ScrollClipRect
        jsr     DrawListEntries
        rts
.endproc

;;; ============================================================

.proc HandlePageUp
        lda     file_dialog_res::winfo_listbox::vthumbpos
        sec
        sbc     #kPageDelta
        bpl     :+
        lda     #0
:       sta     updatethumb_params::thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_params::which_ctl
        LIB_MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_params::thumbpos
        jsr     ScrollClipRect
        jsr     DrawListEntries
        rts
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
:       sta     updatethumb_params::thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_params::which_ctl
        LIB_MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_params::thumbpos
        jsr     ScrollClipRect
        jsr     DrawListEntries
        rts
.endproc

;;; ============================================================

.proc HandleLineUp
        lda     file_dialog_res::winfo_listbox::vthumbpos
        bne     :+
        rts

:       sec
        sbc     #kLineDelta
        sta     updatethumb_params::thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_params::which_ctl
        LIB_MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_params::thumbpos
        jsr     ScrollClipRect
        jsr     DrawListEntries
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
        sta     updatethumb_params::thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_params::which_ctl
        LIB_MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_params::thumbpos
        jsr     ScrollClipRect
        jsr     DrawListEntries
        jsr     CheckArrowRepeat
        jmp     HandleLineDown
.endproc

;;; ============================================================

.proc CheckArrowRepeat
        LIB_MGTK_CALL MGTK::PeekEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     :+
        cmp     #MGTK::EventKind::drag
        beq     :+
        pla
        pla
        rts

:       LIB_MGTK_CALL MGTK::GetEvent, event_params
        LIB_MGTK_CALL MGTK::FindWindow, findwindow_params
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

:       LIB_MGTK_CALL MGTK::FindControl, findcontrol_params
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
        LIB_MGTK_CALL MGTK::SetCursor, pointer_cursor
        rts
.endproc

;;; ============================================================

.proc SetCursorIBeam
        bit     cursor_ibeam_flag
        bmi     :+
        LIB_MGTK_CALL MGTK::SetCursor, ibeam_cursor
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
        pha
        bit     input_dirty_flag
        bpl     :+
        jsr     PrepPath
:       lda     #0
        sta     tmp
        copy16  #file_names, $08
        pla
        asl     a               ; * 16
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        clc
        adc     $08
        sta     $08
        lda     tmp
        adc     $08+1
        sta     $08+1

        ldx     $08+1
        lda     $08
        jsr     AppendToPathBuf

        jsr     ReadDir
        jsr     UpdateScrollbar
        lda     #$00
        jsr     ScrollClipRect
        jsr     UpdateDiskName
        jsr     DrawListEntries
        rts

tmp:     .byte   0
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
        jsr     ReadDir
        jsr     UpdateScrollbar
        lda     #$00
        jsr     ScrollClipRect
        jsr     UpdateDiskName
        jsr     DrawListEntries
        jsr     PrepPath
        jsr     RedrawInput
        rts
.endproc

;;; ============================================================

.proc DoClose
        lda     #$00
        sta     l7
        ldx     path_buf
        bne     l1
        jmp     l6

l1:     lda     path_buf,x
        cmp     #'/'
        beq     l2
        dex
        bpl     l1
        jmp     l6

l2:     cpx     #$01
        bne     l3
        jmp     l6

l3:     jsr     StripPathSegment
        lda     file_dialog_res::selected_index
        pha
        lda     #$FF
        sta     file_dialog_res::selected_index
        jsr     ReadDir
        jsr     UpdateScrollbar
        lda     #$00
        jsr     ScrollClipRect
        jsr     UpdateDiskName
        jsr     DrawListEntries
        pla
        sta     file_dialog_res::selected_index
        bit     l7
        bmi     l4
        jsr     StripPathSegmentLeftAndRedraw
        lda     file_dialog_res::selected_index
        bmi     l5
        jsr     StripPathSegmentLeftAndRedraw
        jmp     l5

l4:     jsr     PrepPath
        jsr     RedrawInput
l5:     lda     #$FF
        sta     file_dialog_res::selected_index
l6:     rts

l7:     .byte   0
.endproc

;;; ============================================================

.proc InitSetGrafport
        LIB_MGTK_CALL MGTK::InitPort, main_grafport
        LIB_MGTK_CALL MGTK::SetPort, main_grafport
        rts
.endproc

;;; ============================================================
;;; Key handler

.proc HandleKey
        lda     event_params::modifiers
        beq     no_modifiers

        ;; With modifiers
        lda     event_params::key

        bit     listbox_disabled_flag
        bmi     :+
        jsr     CheckTypeDown
        jeq     exit
:
        lda     event_params::key
        cmp     #CHAR_TAB
        jeq     is_tab

        cmp     #CHAR_LEFT
        jeq     HandleMetaLeftKey ; start of line

        cmp     #CHAR_RIGHT
        jeq     HandleMetaRightKey ; end of line

        bit     listbox_disabled_flag
        bmi     not_arrow
        cmp     #CHAR_DOWN
        jeq     ScrollListBottom ; end of list

        cmp     #CHAR_UP
        jeq     ScrollListTop   ; start of list

not_arrow:
        cmp     #'0'
        bcc     :+
        cmp     #'9'+1
        bcs     jmp_exit
        jmp     key_meta_digit

        ;; --------------------------------------------------
        ;; No modifiers

no_modifiers:
        copy    #0, file_dialog_res::type_down_buf

        lda     event_params::key

        cmp     #CHAR_LEFT
        jeq     HandleLeftKey

        cmp     #CHAR_RIGHT
        jeq     HandleRightKey

        cmp     #CHAR_RETURN
        jeq     KeyReturn

        cmp     #CHAR_ESCAPE
        jeq     KeyEscape

        cmp     #CHAR_DELETE
        jeq     KeyDelete

        bit     listbox_disabled_flag
        bpl     :+
        jmp     finish

:       cmp     #CHAR_TAB
        bne     not_tab
is_tab: lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::change_drive_button_rect
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::change_drive_button_rect
        jsr     ChangeDrive
jmp_exit:
        jmp     exit

not_tab:
        cmp     #CHAR_CTRL_O    ; Open
        bne     not_ctrl_o
        lda     file_dialog_res::selected_index
        bmi     exit
        tax
        lda     file_list_index,x
        bmi     :+
        jmp     exit

:       lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::open_button_rect
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::open_button_rect
        jsr     OpenSelectedItem
        jmp     exit

not_ctrl_o:
        cmp     #CHAR_CTRL_C    ; Close
        bne     :+
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::close_button_rect
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::close_button_rect
        jsr     DoClose
        jmp     exit

:       cmp     #CHAR_DOWN
        jeq     KeyDown

        cmp     #CHAR_UP
        jeq     KeyUp

finish: jsr     HandleOtherKey
        rts

exit:   jsr     InitSetGrafport
        rts

;;; ============================================================

.proc KeyReturn
.if !FD_EXTENDED
        lda     file_dialog_res::selected_index
        bpl     :+
        bit     input_dirty_flag
        bmi     :+
        rts
:
.endif
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        jsr     HandleMetaRightKey
        jsr     HandleOk
        jsr     InitSetGrafport
        rts
.endproc

;;; ============================================================


.proc KeyEscape
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::SetPenMode, penXOR ; flash the button
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::cancel_button_rect
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::cancel_button_rect
        jsr     HandleCancel
        jsr     InitSetGrafport
        rts
.endproc

;;; ============================================================

.proc KeyDelete
        jsr     HandleDeleteKey
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
        jsr     StripPathSegmentLeftAndRedraw
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
        jsr     StripPathSegmentLeftAndRedraw
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
        jsr     StripPathSegmentLeftAndRedraw
:       pla
        jmp     UpdateListSelection

done:   return  #0

.proc FindMatch
        lda     num_file_names
        bne     :+
        return  #$FF
:
        copy    #0, index

loop:   lda     index
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

;;; Inputs: A = index
;;; Outputs: $06 points at filename
.proc SetPtrToNthFilename
        tax
        lda     file_list_index,x
        and     #$7F
        ldx     #$00
        stx     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        clc
        adc     #<file_names
        sta     $06
        lda     tmp
        adc     #>file_names
        sta     $06+1
        rts
.endproc

index:  .byte   0
tmp:    .byte   0
char:   .byte   0

.endproc ; CheckAlpha

.endproc ; HandleKey

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

.proc ScrollListTop
        lda     num_file_names
        beq     done
        lda     file_dialog_res::selected_index
        bmi     select
        bne     deselect
done:   rts

deselect:
        jsr     InvertEntry
        jsr     StripPathSegmentLeftAndRedraw

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
        jsr     StripPathSegmentLeftAndRedraw
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
        jsr     UpdateScrollbar2
        jsr     DrawListEntries

        copy    #1, buf_input_right
        copy    #' ', buf_input_right+1

        jsr     RedrawInput
        rts
.endproc

;;; ============================================================

.proc NoOp
        rts
.endproc

;;; ============================================================

.proc OpenWindow
        LIB_MGTK_CALL MGTK::OpenWindow, file_dialog_res::winfo
        LIB_MGTK_CALL MGTK::OpenWindow, file_dialog_res::winfo_listbox
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::SetPenMode, penXOR
        LIB_MGTK_CALL MGTK::FrameRect, file_dialog_res::dialog_frame_rect
        LIB_MGTK_CALL MGTK::FrameRect, file_dialog_res::ok_button_rect
        LIB_MGTK_CALL MGTK::FrameRect, file_dialog_res::open_button_rect
        LIB_MGTK_CALL MGTK::FrameRect, file_dialog_res::close_button_rect
        LIB_MGTK_CALL MGTK::FrameRect, file_dialog_res::cancel_button_rect
        LIB_MGTK_CALL MGTK::FrameRect, file_dialog_res::change_drive_button_rect
        jsr     DrawOkButtonLabel
        jsr     DrawOpenButtonLabel
        jsr     DrawCloseButtonLabel
        jsr     DrawCancelButtonLabel
        jsr     DrawChangeDriveButtonLabel
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::dialog_sep_start
        LIB_MGTK_CALL MGTK::LineTo, file_dialog_res::dialog_sep_end
        LIB_MGTK_CALL MGTK::SetPattern, file_dialog_res::checkerboard_pattern
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::button_sep_start
        LIB_MGTK_CALL MGTK::LineTo, file_dialog_res::button_sep_end
        jsr     InitSetGrafport
        rts
.endproc

.proc DrawOkButtonLabel
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::ok_button_pos
        param_call DrawString, file_dialog_res::ok_button_label
        rts
.endproc

.proc DrawOpenButtonLabel
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::open_button_pos
        param_call DrawString, file_dialog_res::open_button_label
        rts
.endproc

.proc DrawCloseButtonLabel
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::close_button_pos
        param_call DrawString, file_dialog_res::close_button_label
        rts
.endproc

.proc DrawCancelButtonLabel
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::cancel_button_pos
        param_call DrawString, file_dialog_res::cancel_button_label
        rts
.endproc

.proc DrawChangeDriveButtonLabel
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::change_drive_button_pos
        param_call DrawString, file_dialog_res::change_drive_button_label
        rts
.endproc

;;; ============================================================

.if FD_EXTENDED
.proc CopyStringToLcbuf
        ptr := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     temp_string_buf,y
        dey
        bpl     :-
        ldax    #temp_string_buf
        rts
.endproc
.endif

;;; ============================================================

.proc DrawString
        ptr := $06
        params := $06

.if FD_EXTENDED
        jsr     CopyStringToLcbuf
.endif
        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     params+2
        inc16   params
        LIB_MGTK_CALL MGTK::DrawText, params
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
        LIB_MGTK_CALL MGTK::TextWidth, text_params

        sub16   #file_dialog_res::kFilePickerDlgWidth, text_width, file_dialog_res::pos_title::xcoord
        lsr16   file_dialog_res::pos_title::xcoord ; /= 2
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::pos_title
        LIB_MGTK_CALL MGTK::DrawText, text_params
        rts
.endproc

;;; ============================================================

.proc DrawInput1Label
.if FD_EXTENDED
        jsr     CopyStringToLcbuf
.endif
        stax    $06
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::input1_label_pos
        ldax    $06
        jsr     DrawString
        rts
.endproc

;;; ============================================================

.if FD_EXTENDED
.proc DrawInput2Label
        jsr     CopyStringToLcbuf
        stax    $06
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::input2_label_pos
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
        LIB_MLI_CALL ON_LINE, on_line_params
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
        LIB_MLI_CALL OPEN, open_params
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
        LIB_MLI_CALL READ, read_params
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

;;; ============================================================

.proc AppendToPathBuf
        ptr := $06
.if FD_EXTENDED
        jsr     CopyStringToLcbuf
.endif
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
        lda     #$FF
        sta     file_dialog_res::selected_index

.if FD_EXTENDED
        lda     #0
.endif
        rts
.endproc

;;; ============================================================


;;; ============================================================

.proc StripPathSegment
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
        copy16  #file_names, dst_ptr
        lda     #$00
        sta     hi
        lda     d1
        asl     a               ; *= 16
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        clc
        adc     dst_ptr
        sta     dst_ptr
        lda     hi
        adc     dst_ptr+1
        sta     dst_ptr+1

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

close:  LIB_MLI_CALL CLOSE, close_params
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

:       LIB_MLI_CALL READ, read_params
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
hi:     .byte   0
.endproc

;;; ============================================================

.proc DrawListEntries
        lda     file_dialog_res::winfo_listbox::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::winfo_listbox::cliprect
        copy    #kListEntryNameX, file_dialog_res::picker_entry_pos::xcoord ; high byte always 0
        copy16  #kListEntryHeight, file_dialog_res::picker_entry_pos::ycoord
        copy    #0, l4

loop:   lda     l4
        cmp     num_file_names
        bne     :+
        jsr     InitSetGrafport
        rts

:       LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::picker_entry_pos
        ldx     l4
        lda     file_list_index,x
        and     #$7F
        ldx     #$00
        stx     l3
        asl     a
        rol     l3
        asl     a
        rol     l3
        asl     a
        rol     l3
        asl     a
        rol     l3
        clc
        adc     #<file_names
        tay
        lda     l3
        adc     #>file_names
        tax
        tya
        jsr     DrawString
        ldx     l4
        lda     file_list_index,x
        bpl     :+

        ;; Folder glyph
        copy    #kListEntryGlyphX, file_dialog_res::picker_entry_pos::xcoord
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::picker_entry_pos
        param_call DrawString, file_dialog_res::str_folder
        copy    #kListEntryNameX, file_dialog_res::picker_entry_pos::xcoord

:       lda     l4
        cmp     file_dialog_res::selected_index
        bne     l2
        jsr     InvertEntry
        lda     file_dialog_res::winfo_listbox::window_id
        jsr     SetPortForWindow
l2:     inc     l4

        add16_8 file_dialog_res::picker_entry_pos::ycoord, #kListEntryHeight, file_dialog_res::picker_entry_pos::ycoord
        jmp     loop

l3:     .byte   0
l4:     .byte   0
.endproc

;;; ============================================================

UpdateScrollbar:
        lda     #$00

.proc UpdateScrollbar2
        sta     index
        lda     num_file_names
        cmp     #kPageDelta + 1
        bcs     :+

        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        copy    #MGTK::activatectl_deactivate, activatectl_params::activate
        LIB_MGTK_CALL MGTK::ActivateCtl, activatectl_params
        lda     #0
        jmp     ScrollClipRect

:       lda     num_file_names
        sec
        sbc     #kPageDelta
        sta     file_dialog_res::winfo_listbox::vthumbmax
        .assert MGTK::Ctl::vertical_scroll_bar = MGTK::activatectl_activate, error, "need to match"
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_params::which_ctl
        sta     activatectl_params::activate
        LIB_MGTK_CALL MGTK::ActivateCtl, activatectl_params
        lda     index
        sta     updatethumb_params::thumbpos
        jsr     ScrollClipRect
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_params::which_ctl
        LIB_MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        rts

index:  .byte   0
.endproc

;;; ============================================================

.proc UpdateDiskName
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::disk_name_rect
.if !FD_EXTENDED
        LIB_MGTK_CALL MGTK::SetPenMode, penXOR
.endif
        copy16  #path_buf, $06
        ldy     #$00
        lda     ($06),y
        sta     l5
        iny
l1:     iny
        lda     ($06),y
        cmp     #'/'
        beq     l2
        cpy     l5
        bne     l1
        beq     l3
l2:     dey
        sty     l5
l3:     ldy     #$00
        ldx     #$00
l4:     inx
        iny
        lda     ($06),y
        sta     INVOKER_PREFIX,x
        cpy     l5
        bne     l4
        stx     INVOKER_PREFIX
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::disk_label_pos
        param_call DrawString, file_dialog_res::disk_label_str
        param_call DrawString, INVOKER_PREFIX
        jsr     InitSetGrafport
        rts

l5:     .byte   0
.endproc

;;; ============================================================


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

        lda     file_dialog_res::winfo_listbox::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::SetPenMode, penXOR
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::rect_selection
        jsr     InitSetGrafport
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

.proc SetPortForWindow
        sta     getwinport_params::window_id
        LIB_MGTK_CALL MGTK::GetWinPort, getwinport_params
        LIB_MGTK_CALL MGTK::SetPort, window_grafport
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
        jsr     CalcEntryPtr
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
        jsr     CalcEntryPtr
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

l14:    jsr     CalcEntryPtr
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

;;; --------------------------------------------------

.proc CalcEntryPtr
        ptr := $06

        ldx     #<file_names
        stx     ptr
        ldx     #>file_names
        stx     ptr+1
        ldx     #$00
        stx     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        clc
        adc     ptr
        sta     ptr
        lda     tmp
        adc     ptr+1
        sta     ptr+1
        rts

tmp:    .byte   0
.endproc
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
:       return  #0

has_sel:
        cmp     #kPageDelta
        bcc     :-
        sec
        sbc     #kPageDelta-1
        rts
.endproc

;;; ============================================================

.proc BlinkF1IP
        pt := $06

        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        jsr     CalcInput1IPPos
        stax    pt
        copy16  file_dialog_res::input1_textpos::ycoord, pt+2
        LIB_MGTK_CALL MGTK::MoveTo, pt
        bit     prompt_ip_flag
        bpl     bg2

        LIB_MGTK_CALL MGTK::SetTextBG, file_dialog_res::textbg1
        copy    #$00, prompt_ip_flag
        beq     :+

bg2:    LIB_MGTK_CALL MGTK::SetTextBG, file_dialog_res::textbg2
        copy    #$FF, prompt_ip_flag

        PARAM_BLOCK dt_params, $06
data    .addr
length  .byte
        END_PARAM_BLOCK

:       copy16  #str_insertion_point+1, dt_params::data
        copy    str_insertion_point, dt_params::length
        LIB_MGTK_CALL MGTK::DrawText, dt_params
        jsr     InitSetGrafport
        rts
.endproc

;;; ============================================================

.if FD_EXTENDED
.proc BlinkF2IP
        pt := $06

        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        jsr     CalcInput2IPPos
        stax    $06
        copy16  file_dialog_res::input2_textpos::ycoord, $08
        LIB_MGTK_CALL MGTK::MoveTo, pt
        bit     prompt_ip_flag
        bpl     bg2

        LIB_MGTK_CALL MGTK::SetTextBG, file_dialog_res::textbg1
        copy    #$00, prompt_ip_flag
        jmp     :+

bg2:    LIB_MGTK_CALL MGTK::SetTextBG, file_dialog_res::textbg2
        copy    #$FF, prompt_ip_flag

        PARAM_BLOCK dt_params, $06
data    .addr
length  .byte
        END_PARAM_BLOCK

:       copy16  #str_insertion_point+1, dt_params::data
        copy    str_insertion_point, dt_params::length
        LIB_MGTK_CALL MGTK::DrawText, pt
        jsr     InitSetGrafport
        rts
.endproc
.endif

;;; ============================================================

.proc RedrawF1
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::input1_rect
        LIB_MGTK_CALL MGTK::SetPenMode, notpencopy
        LIB_MGTK_CALL MGTK::FrameRect, file_dialog_res::input1_rect
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::input1_textpos
        lda     buf_input1_left
        beq     :+
        param_call DrawString, buf_input1_left
:       param_call DrawString, buf_input_right
        param_call DrawString, str_2_spaces
        rts
.endproc

;;; ============================================================

.if FD_EXTENDED
.proc RedrawF2
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::PaintRect, file_dialog_res::input2_rect
        LIB_MGTK_CALL MGTK::SetPenMode, notpencopy
        LIB_MGTK_CALL MGTK::FrameRect, file_dialog_res::input2_rect
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::input2_textpos
        lda     buf_input2_left
        beq     :+
        param_call DrawString, buf_input2_left
:       param_call DrawString, buf_input_right
        param_call DrawString, str_2_spaces
        rts
.endproc
.endif

;;; ============================================================
;;; A click when f1 has focus (click may be elsewhere)

.proc HandleF1Click
        lda     file_dialog_res::winfo::window_id
        sta     screentowindow_params::window_id
        LIB_MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::MoveTo, screentowindow_params::windowx

        ;; Inside input1 ?
        LIB_MGTK_CALL MGTK::InRect, file_dialog_res::input1_rect
        cmp     #MGTK::inrect_inside
.if !FD_EXTENDED
        beq     :+
        rts
:
.else
        beq     ep2

        ;; Inside input2 ?
        bit     dual_inputs_flag
        bpl     done
        LIB_MGTK_CALL MGTK::InRect, file_dialog_res::input2_rect
        cmp     #MGTK::inrect_inside
        bne     done
        jsr     HandleOk    ; move focus to input2
        ;; NOTE: Assumes screentowindow_params::window* has not been changed.
        jmp     HandleF2Click__ep2

done:   rts

ep2:
.endif
        ;; Is click to left or right of insertion point?
        jsr     CalcInput1IPPos
        stax    $06
        cmp16   screentowindow_params::windowx, $06
        bcs     ToRight
        jmp     ToLeft

        PARAM_BLOCK tw_params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        ;; --------------------------------------------------
        ;; Click to right of insertion point

.proc ToRight
        jsr     CalcInput1IPPos
        stax    ip_pos
        ldx     buf_input_right
        inx
        lda     #' '            ; append space at end
        sta     buf_input_right,x
        inc     buf_input_right

        ;; Iterate to find the position
        copy16  #buf_input_right, tw_params::data
        copy    buf_input_right, tw_params::length
@loop:  LIB_MGTK_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, ip_pos, tw_params::width
        cmp16   tw_params::width, screentowindow_params::windowx
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bne     @loop

        dec     buf_input_right ; remove appended space
        jmp     finish

        ;; Was it to the right of the string?
:       lda     tw_params::length
        cmp     buf_input_right
        bcc     :+
        dec     buf_input_right      ; remove appended space...
        jmp     HandleF1MetaRightKey ; and use this shortcut

        ;; Append from `buf_input_right` into `buf_input1_left`
:       ldx     #2
        ldy     buf_input1_left
        iny
:       lda     buf_input_right,x
        sta     buf_input1_left,y
        cpx     tw_params::length
        beq     :+
        iny
        inx
        jmp     :-
:       sty     buf_input1_left

        ;; Shift contents of `buf_input_right` down,
        ;; preserving IP at the start.
        ldy     #2
        ldx     tw_params::length
        inx
:       lda     buf_input_right,x
        sta     buf_input_right,y
        cpx     buf_input_right
        beq     :+
        iny
        inx
        jmp     :-

:       dey
        sty     buf_input_right
        jmp     finish
.endproc

        ;; --------------------------------------------------
        ;; Click to left of insertion point

.proc ToLeft
        ;; Iterate to find the position
        copy16  #buf_input1_left, tw_params::data
        copy    buf_input1_left, tw_params::length
@loop:  LIB_MGTK_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, file_dialog_res::input1_textpos::xcoord, tw_params::width
        cmp16   tw_params::width, screentowindow_params::windowx
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bcs     @loop
        jmp     HandleF1MetaLeftKey

        ;; Found position; copy everything to the right of
        ;; the new position from `buf_input1_left` to `buf_text`
:       inc     tw_params::length
        ldy     #0
        ldx     tw_params::length
:       cpx     buf_input1_left
        beq     :+
        inx
        iny
        lda     buf_input1_left,x
        sta     buf_text+1,y
        jmp     :-
:       iny
        sty     buf_text

        ;; Append `buf_input_right` to `buf_text`
        ldx     #1
        ldy     buf_text
:       cpx     buf_input_right
        beq     :+
        inx
        iny
        lda     buf_input_right,x
        sta     buf_text,y
        jmp     :-
:       sty     buf_text

        ;; Copy IP and `buf_text` into `buf_input_right`
        copy    #kGlyphInsertionPoint, buf_text+1
:       lda     buf_text,y
        sta     buf_input_right,y
        dey
        bpl     :-

        ;; Adjust length
        lda     tw_params::length
        sta     buf_input1_left
        ;; fall through
.endproc

finish: jsr     RedrawInput
        jsr     SelectMatchingFileInListF1
        rts

ip_pos: .word   0
.endproc ; HandleF1Click

;;; ============================================================
;;; A click when f2 has focus (click may be elsewhere)

.if FD_EXTENDED
.proc HandleF2Click

        ;; Was click inside text box?
        lda     file_dialog_res::winfo::window_id
        sta     screentowindow_params::window_id
        LIB_MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::MoveTo, screentowindow_params::windowx

        ;; Inside input2 ?
        LIB_MGTK_CALL MGTK::InRect, file_dialog_res::input2_rect
        cmp     #MGTK::inrect_inside
        beq     ep2

        ;; Inside input1 ?
        bit     dual_inputs_flag
        bpl     done
        LIB_MGTK_CALL MGTK::InRect, file_dialog_res::input1_rect
        cmp     #MGTK::inrect_inside
        bne     done
        jsr     HandleCancel ; Move focus to input1
        ;; NOTE: Assumes screentowindow_params::window* has not been changed.
        jmp     HandleF1Click::ep2

done:   rts

        ;; Is click to left or right of insertion point?
ep2:    jsr     CalcInput2IPPos
        stax    $06
        cmp16   screentowindow_params::windowx, $06
        bcs     ToRight
        jmp     ToLeft

        PARAM_BLOCK tw_params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        ;; --------------------------------------------------
        ;; Click to right of insertion point
.proc ToRight
        jsr     CalcInput2IPPos
        stax    ip_pos
        ldx     buf_input_right
        inx
        lda     #' '            ; append space at end
        sta     buf_input_right,x
        inc     buf_input_right

        ;; Iterate to find the position
        copy16  #buf_input_right, tw_params::data
        copy    buf_input_right, tw_params::length
@loop:  LIB_MGTK_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, ip_pos, tw_params::width
        cmp16   tw_params::width, screentowindow_params::windowx
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bne     @loop

        dec     buf_input_right       ; remove appended space
        jmp     finish

        ;; Was it to the right of the string?
:       lda     tw_params::length
        cmp     buf_input_right
        bcc     :+
        dec     buf_input_right       ; remove appended space
        jmp     HandleF2MetaRightKey ; and use this shortcut

        ;; Append from `buf_input_right` into `buf_input2_left`
:       ldx     #2
        ldy     buf_input2_left
        iny
:       lda     buf_input_right,x
        sta     buf_input2_left,y
        cpx     $08
        beq     :+
        iny
        inx
        jmp     :-
:       sty     buf_input2_left

        ;; Shift contents of `buf_input_right` down,
        ;; preserving IP at the start.
        ldy     #2
        ldx     tw_params::length
        inx
:       lda     buf_input_right,x
        sta     buf_input_right,y
        cpx     buf_input_right
        beq     :+
        iny
        inx
        jmp     :-

:       dey
        sty     buf_input_right
        jmp     finish
.endproc

        ;; --------------------------------------------------
        ;; Click to left of insertion point

.proc ToLeft
        copy16  #buf_input2_left, tw_params::data
        copy    buf_input2_left, tw_params::length
@loop:  LIB_MGTK_CALL MGTK::TextWidth, $06
        add16   tw_params::width, file_dialog_res::input2_textpos, tw_params::width
        cmp16   tw_params::width, screentowindow_params::windowx
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bcs     @loop
        jmp     HandleF2MetaLeftKey

        ;; Found position; copy everything to the right of
        ;; the new position from `buf_input2_left` to `buf_text`
:       inc     tw_params::length
        ldy     #0
        ldx     tw_params::length
:       cpx     buf_input2_left
        beq     :+
        inx
        iny
        lda     buf_input2_left,x
        sta     buf_text+1,y
        jmp     :-
:       iny
        sty     buf_text

        ;; Append `buf_input_right` to `buf_text`
        ldx     #1
        ldy     buf_text
:       cpx     buf_input_right
        beq     :+
        inx
        iny
        lda     buf_input_right,x
        sta     buf_text,y
        jmp     :-
:       sty     buf_text

        ;; Copy IP and `buf_text` into `buf_input_right`
        copy    #kGlyphInsertionPoint, buf_text+1
:       lda     buf_text,y
        sta     buf_input_right,y
        dey
        bpl     :-

        ;; Adjust length
        lda     tw_params::length
        sta     buf_input2_left
        ;; fall through
.endproc

finish: jsr     RedrawInput
        jsr     SelectMatchingFileInListF2
        rts

ip_pos: .word   0
.endproc
HandleF2Click__ep2 := HandleF2Click::ep2
.endif

;;; ============================================================

;;; ============================================================

.proc HandleF1OtherKey
        sta     tmp
        lda     buf_input1_left
        clc
        adc     buf_input_right
        cmp     #kMaxInputLength
        bcc     continue
        rts

continue:
        lda     tmp
        ldx     buf_input1_left
        inx
        sta     buf_input1_left,x
        sta     str_1_char+1
        jsr     CalcInput1IPPos
        inc     buf_input1_left
        stax    $06
        copy16  file_dialog_res::input1_textpos::ycoord, $08
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::MoveTo, $06
        param_call DrawString, str_1_char
        param_call DrawString, buf_input_right
        jsr     SelectMatchingFileInListF1
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

.proc HandleF1DeleteKey
        lda     buf_input1_left
        bne     :+
        rts

:       dec     buf_input1_left
        jsr     CalcInput1IPPos
        stax    $06
        copy16  file_dialog_res::input1_textpos::ycoord, $08
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::MoveTo, $06
        param_call DrawString, buf_input_right
        param_call DrawString, str_2_spaces
        jsr     SelectMatchingFileInListF1
        rts
.endproc

;;; ============================================================

.proc HandleF1LeftKey
        lda     buf_input1_left
        bne     :+
        rts

:       ldx     buf_input_right
        cpx     #1
        beq     skip
:       lda     buf_input_right,x
        sta     buf_input_right+1,x
        dex
        cpx     #1
        bne     :-

skip:   ldx     buf_input1_left
        lda     buf_input1_left,x
        sta     buf_input_right+2
        dec     buf_input1_left
        inc     buf_input_right
        jsr     CalcInput1IPPos
        stax    $06
        copy16  file_dialog_res::input1_textpos::ycoord, $08
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::MoveTo, $06
        param_call DrawString, buf_input_right
        param_call DrawString, str_2_spaces
        jsr     SelectMatchingFileInListF1
        rts
.endproc

;;; ============================================================

.proc HandleF1RightKey
        lda     buf_input_right
        cmp     #2
        bcs     :+
        rts

:       ldx     buf_input1_left
        inx
        lda     buf_input_right+2
        sta     buf_input1_left,x
        inc     buf_input1_left
        ldx     buf_input_right
        cpx     #3
        bcc     finish

        ldx     #2
:       lda     buf_input_right+1,x
        sta     buf_input_right,x
        inx
        cpx     buf_input_right
        bne     :-

finish: dec     buf_input_right
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::input1_textpos
        param_call DrawString, buf_input1_left
        param_call DrawString, buf_input_right
        param_call DrawString, str_2_spaces
        jsr     SelectMatchingFileInListF1
        rts
.endproc

;;; ============================================================

.proc HandleF1MetaLeftKey
        lda     buf_input1_left
        bne     :+
        rts

:       ldy     buf_input1_left
        lda     buf_input_right
        cmp     #2
        bcc     skip

        ldx     #1
:       iny
        inx
        lda     buf_input_right,x
        sta     buf_input1_left,y
        cpx     buf_input_right
        bne     :-

skip:   sty     buf_input1_left

:       lda     buf_input1_left,y
        sta     buf_input_right+1,y
        dey
        bne     :-
        ldx     buf_input1_left
        inx
        stx     buf_input_right
        copy    #kGlyphInsertionPoint, buf_input_right+1
        copy    #0, buf_input1_left
        jsr     RedrawInput
        jsr     SelectMatchingFileInListF1
        rts
.endproc

;;; ============================================================

.proc HandleF1MetaRightKey
        jsr     MoveIPToEndF1
        jsr     RedrawInput
        jsr     SelectMatchingFileInListF1
        rts
.endproc

;;; ============================================================

.if FD_EXTENDED
.proc HandleF2OtherKey
        sta     l1
        lda     buf_input2_left
        clc
        adc     buf_input_right
        cmp     #kMaxInputLength
        bcc     :+
        rts

:       lda     l1
        ldx     buf_input2_left
        inx
        sta     buf_input2_left,x
        sta     str_1_char+1
        jsr     CalcInput2IPPos
        inc     buf_input2_left
        stax    $06
        copy16  file_dialog_res::input2_textpos::ycoord, $08
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::MoveTo, $06
        param_call DrawString, str_1_char
        param_call DrawString, buf_input_right
        jsr     SelectMatchingFileInListF2
        rts

l1:     .byte   0
.endproc
.endif

;;; ============================================================

.if FD_EXTENDED
.proc HandleF2DeleteKey
        lda     buf_input2_left
        bne     :+
        rts

:       dec     buf_input2_left
        jsr     CalcInput2IPPos
        stax    $06
        copy16  file_dialog_res::input2_textpos::ycoord, $08
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::MoveTo, $06
        param_call DrawString, buf_input_right
        param_call DrawString, str_2_spaces
        jsr     SelectMatchingFileInListF2
        rts
.endproc
.endif

;;; ============================================================

.if FD_EXTENDED
.proc HandleF2LeftKey
        lda     buf_input2_left
        bne     l1
        rts

l1:     ldx     buf_input_right
        cpx     #$01
        beq     l3
l2:     lda     buf_input_right,x
        sta     buf_input_right+1,x
        dex
        cpx     #$01
        bne     l2
l3:     ldx     buf_input2_left
        lda     buf_input2_left,x
        sta     buf_input_right+2
        dec     buf_input2_left
        inc     buf_input_right
        jsr     CalcInput2IPPos
        stax    $06
        copy16  file_dialog_res::input2_textpos::ycoord, $08
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::MoveTo, $06
        param_call DrawString, buf_input_right
        param_call DrawString, str_2_spaces
        jsr     SelectMatchingFileInListF2
        rts
.endproc
.endif

;;; ============================================================

.if FD_EXTENDED
.proc HandleF2RightKey
        lda     buf_input_right
        cmp     #$02
        bcs     l1
        rts

l1:     ldx     buf_input2_left
        inx
        lda     buf_input_right+2
        sta     buf_input2_left,x
        inc     buf_input2_left
        ldx     buf_input_right
        cpx     #$03
        bcc     l3
        ldx     #$02
l2:     lda     buf_input_right+1,x
        sta     buf_input_right,x
        inx
        cpx     buf_input_right
        bne     l2
l3:     dec     buf_input_right
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        LIB_MGTK_CALL MGTK::MoveTo, file_dialog_res::input2_textpos
        param_call DrawString, buf_input2_left
        param_call DrawString, buf_input_right
        param_call DrawString, str_2_spaces
        jsr     SelectMatchingFileInListF2
        rts
.endproc
.endif

;;; ============================================================

.if FD_EXTENDED
.proc HandleF2MetaLeftKey
        lda     buf_input2_left
        bne     l1
        rts

l1:     ldy     buf_input2_left
        lda     buf_input_right
        cmp     #$02
        bcc     l3
        ldx     #$01
l2:     iny
        inx
        lda     buf_input_right,x
        sta     buf_input2_left,y
        cpx     buf_input_right
        bne     l2
l3:     sty     buf_input2_left
l4:     lda     buf_input2_left,y
        sta     buf_input_right+1,y
        dey
        bne     l4
        ldx     buf_input2_left
        inx
        stx     buf_input_right
        copy    #kGlyphInsertionPoint, buf_input_right+1
        copy    #0, buf_input2_left
        jsr     RedrawInput
        jsr     SelectMatchingFileInListF2
        rts
.endproc
.endif

;;; ============================================================

.if FD_EXTENDED
.proc HandleF2MetaRightKey
        jsr     MoveIPToEndF2
        jsr     RedrawInput
        jsr     SelectMatchingFileInListF2
        rts
.endproc
.endif

;;; ============================================================

.if !FD_EXTENDED

;;; Alias table - replaces jump table in hookable version

BlinkIP                 := BlinkF1IP
RedrawInput             := RedrawF1
HandleSelectionChange   := ListSelectionChange
PrepPath                := PrepPathInput1
HandleOtherKey          := HandleF1OtherKey
HandleDeleteKey         := HandleF1DeleteKey
HandleLeftKey           := HandleF1LeftKey
HandleRightKey          := HandleF1RightKey
HandleMetaLeftKey       := HandleF1MetaLeftKey
HandleMetaRightKey      := HandleF1MetaRightKey
HandleClick             := HandleF1Click

.else

;;; Dynamically altered table of handlers for focused
;;; input field (e.g. source/destination filename, etc)

kJumpTableSize = $2A
jump_table:
HandleOk:             jmp     0
HandleCancel:         jmp     0
BlinkIP:              jmp     0
RedrawInput:          jmp     0
StripPathSegmentLeftAndRedraw:     jmp     0
HandleSelectionChange:  jmp     0
PrepPath:             jmp     0
HandleOtherKey:       jmp     0
HandleDeleteKey:      jmp     0
HandleLeftKey:        jmp     0
HandleRightKey:       jmp     0
HandleMetaLeftKey:    jmp     0
HandleMetaRightKey:   jmp     0
HandleClick:          jmp     0
        .assert * - jump_table = kJumpTableSize, error, "Table size mismatch"
.endif

;;; ============================================================
;;; Input: A,X = string address

.proc AppendSegmentToInput1
        ptr := $06

        stax    ptr

        ldx     buf_input1_left
        lda     #'/'
        sta     buf_input1_left+1,x
        inc     buf_input1_left

        ldy     #0
        lda     (ptr),y
        tay
        clc
        adc     buf_input1_left
        pha
        tax

:       lda     (ptr),y
        sta     buf_input1_left,x
        dey
        dex
        cpx     buf_input1_left
        bne     :-

        pla
        sta     buf_input1_left
        rts
.endproc

;;; ============================================================
;;; Input: A,X = string address

.if FD_EXTENDED
.proc AppendSegmentToInput2
        ptr := $06

        stax    ptr

        ldx     buf_input2_left
        lda     #'/'
        sta     buf_input2_left+1,x
        inc     buf_input2_left

        ldy     #$00
        lda     (ptr),y
        tay
        clc
        adc     buf_input2_left
        pha
        tax

:       lda     (ptr),y
        sta     buf_input2_left,x
        dey
        dex
        cpx     buf_input2_left
        bne     :-

        pla
        sta     buf_input2_left
        rts
.endproc
.endif

;;; ============================================================
;;; Trim end of left segment to rightmost '/'

.proc StripPathSegmentInput1
:       ldx     buf_input1_left
        cpx     #0
        beq     :+
        dec     buf_input1_left
        lda     buf_input1_left,x
        cmp     #'/'
        bne     :-
:       rts
.endproc

;;; ============================================================

.if FD_EXTENDED
.proc StripPathSegmentInput2
:       ldx     buf_input2_left
        cpx     #0
        beq     :+
        dec     buf_input2_left
        lda     buf_input2_left,x
        cmp     #'/'
        bne     :-
:       rts
.endproc
.endif

;;; ============================================================


.if !FD_EXTENDED

.proc StripPathSegmentLeftAndRedraw
        jsr     StripPathSegmentInput1
        jsr     RedrawInput
        rts
.endproc

.else
.proc StripF1PathSegment
        jsr     StripPathSegmentInput1
        jsr     RedrawInput
        rts
.endproc

.proc StripF2PathSegment
        jsr     StripPathSegmentInput2
        jsr     RedrawInput
        rts
.endproc

.endif

;;; ============================================================

;;; ============================================================

.if FD_EXTENDED
HandleF1SelectionChange:
        lda     #$00
        beq     ListSelectionChange

HandleF2SelectionChange:
        lda     #$80
        ;; fall through
.endif

.proc ListSelectionChange
        ptr := $06

.if FD_EXTENDED
        sta     flag
.endif

        copy16  #file_names, ptr
        ldx     file_dialog_res::selected_index
        lda     file_list_index,x
        and     #$7F

        ldx     #0
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
        adc     ptr
        tay
        lda     hi
        adc     ptr+1
        tax
        tya

.if !FD_EXTENDED
        jsr     AppendSegmentToInput1
.else
        bit     flag
        bpl     f1
        jsr     AppendSegmentToInput2
        jmp     :+

f1:     jsr     AppendSegmentToInput1

:
.endif
        jsr     RedrawInput
        rts

hi:     .byte   0
.if FD_EXTENDED
flag:   .byte   0
.endif
.endproc

;;; ============================================================

.proc PrepPathInput1
        COPY_STRING path_buf, buf_input1_left
        rts
.endproc

;;; ============================================================

.if FD_EXTENDED
.proc PrepPathInput2
        COPY_STRING path_buf, buf_input2_left
        rts
.endproc
.endif

;;; ============================================================
;;; Output: A,X = X coordinate of insertion point

.proc CalcInput1IPPos
        PARAM_BLOCK params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        lda     #0
        sta     params::width
        sta     params::width+1
        lda     buf_input1_left
        beq     :+

        sta     params::length
        copy16  #buf_input1_left+1, params::data
        LIB_MGTK_CALL MGTK::TextWidth, params

:       lda     params::width
        clc
        adc     file_dialog_res::input1_textpos::xcoord
        tay
        lda     params::width+1
        adc     file_dialog_res::input1_textpos::xcoord+1
        tax
        tya
        rts
.endproc

;;; ============================================================

.if FD_EXTENDED
.proc CalcInput2IPPos
        PARAM_BLOCK params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        lda     #0
        sta     params::width
        sta     params::width+1
        lda     buf_input2_left
        beq     :+

        sta     params::length
        copy16  #buf_input2_left+1, params::data
        LIB_MGTK_CALL MGTK::TextWidth, params

:       lda     params::width
        clc
        adc     file_dialog_res::input2_textpos
        tay
        lda     params::width+1
        adc     file_dialog_res::input2_textpos+1
        tax
        tya
        rts
.endproc
.endif

;;; ============================================================

.if !FD_EXTENDED

.proc SelectMatchingFileInListF1
        COPY_STRING buf_input1_left, buf_text

.else

.proc SelectMatchingFileInList

f2:     lda     #$FF
        bmi     :+

f1:     lda     #$00

:       bmi     :+
        COPY_STRING buf_input1_left, buf_text
        jmp     common

:       COPY_STRING buf_input2_left, buf_text

common:

.endif

        lda     file_dialog_res::selected_index
        sta     d2
        bmi     l1
        ldx     #<file_names
        stx     $06
        ldx     #>file_names
        stx     $07
        ldx     #0
        stx     d1
        tax
        lda     file_list_index,x
        and     #$7F
        asl     a
        rol     d1
        asl     a
        rol     d1
        asl     a
        rol     d1
        asl     a
        rol     d1
        clc
        adc     $06
        tay
        lda     d1
        adc     $07
        tax
        tya
        jsr     AppendToPathBuf

l1:     lda     buf_text
        cmp     path_buf
        bne     l3
        tax
:       lda     buf_text,x
        cmp     path_buf,x
        bne     l3
        dex
        bne     :-
        lda     #0
        sta     input_dirty_flag
        jsr     l4
        rts

l3:     lda     #$FF
        sta     input_dirty_flag
        jsr     l4
        rts

l4:     lda     d2
        sta     file_dialog_res::selected_index
        bpl     l5
        rts

l5:     jsr     StripPathSegment
        rts

d1:     .byte   0
d2:     .byte   0
.endproc
.if FD_EXTENDED
SelectMatchingFileInListF1 := SelectMatchingFileInList::f1
SelectMatchingFileInListF2 := SelectMatchingFileInList::f2
.endif


;;; ============================================================

.proc MoveIPToEndF1
        lda     buf_input_right
        cmp     #2
        bcc     done

        ldx     #1
        ldy     buf_input1_left
:       inx
        iny
        lda     buf_input_right,x
        sta     buf_input1_left,y
        cpx     buf_input_right
        bne     :-
        sty     buf_input1_left

        copy    #1, buf_input_right
        copy    #kGlyphInsertionPoint, buf_input_right+1

done:   rts
.endproc

.if FD_EXTENDED
.proc MoveIPToEndF2
        lda     buf_input_right
        cmp     #2
        bcc     done

        ldx     #1
        ldy     buf_input2_left
:       inx
        iny
        lda     buf_input_right,x
        sta     buf_input2_left,y
        cpx     buf_input_right
        bne     :-
        sty     buf_input2_left

        copy    #1, buf_input_right
        copy    #kGlyphInsertionPoint, buf_input_right+1

done:   rts
.endproc
.endif

;;; ============================================================
