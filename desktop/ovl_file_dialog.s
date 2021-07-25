;;; ============================================================
;;; Overlay for File Dialog (used by Copy/Delete/Add/Edit)
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc file_dialog
        .org $5000

;;; Map from index in files_names to list entry; high bit is
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

exec:
L5000:  jmp     start

        io_buf := $1000
        dir_read_buf := $1400
        kDirReadSize = $200

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer
        DEFINE_OPEN_PARAMS open_params, path_buf, io_buf
        DEFINE_READ_PARAMS read_params, dir_read_buf, kDirReadSize
        DEFINE_CLOSE_PARAMS close_params

on_line_buffer: .res    16, 0
device_num:  .byte   0          ; next device number to try
path_buf:       .res    128, 0
L50A8:  .byte   0
L50A9:  .byte   0

stash_stack:
        .byte   0

;;; ============================================================

routine_table:  .addr   $7000, $7000, $7000

;;; ============================================================

.proc start
        sty     stash_y
        stx     stash_x
        tsx
        stx     stash_stack
        pha

        copy    DEVCNT, device_num

        lda     #0
        sta     L50A8
        sta     prompt_ip_flag
        sta     LD8EC
        sta     LD8F0
        sta     LD8F1
        sta     LD8F2
        sta     cursor_ibeam_flag
        sta     dual_inputs_flag
        sta     extra_controls_flag
        sta     L5105

        copy    SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter
        copy    #$FF, selected_index

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
.endproc

;;; ============================================================
;;; Flags set by invoker to alter behavior

extra_controls_flag:    ; Set when `click_handler_hook` should be called
        .byte   0

dual_inputs_flag:       ; Set when there are two text input fields
        .byte   0

L5105:  .byte   0       ; ??? something about the picker

;;; ============================================================

.proc event_loop
        bit     LD8EC
        bpl     :+

        dec     prompt_ip_counter
        bne     :+
        jsr     jt_blink_ip
        copy    SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter

:       jsr     main::yield_loop
        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     handle_button_down
        jmp     event_loop

:       cmp     #MGTK::EventKind::key_down
        bne     :+
        jsr     handle_key
        jmp     event_loop

:       jsr     main::check_mouse_moved
        bcc     event_loop

        MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     :+
        jmp     event_loop
:       lda     findwindow_window_id
        cmp     winfo_file_dialog::window_id
        beq     l1
        jmp     event_loop

l1:     lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        lda     winfo_file_dialog::window_id
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        bit     focus_in_input2_flag
        bmi     l2
        MGTK_RELAY_CALL MGTK::InRect, file_dialog_res::input1_rect
        cmp     #MGTK::inrect_inside
        bne     l4
        beq     l3
l2:     MGTK_RELAY_CALL MGTK::InRect, file_dialog_res::input2_rect
        cmp     #MGTK::inrect_inside
        bne     l4
l3:     jsr     set_cursor_ibeam
        jmp     l5

l4:     jsr     set_cursor_pointer
l5:     MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        jmp     event_loop
.endproc

focus_in_input2_flag:
        .byte   0

;;; ============================================================

.proc handle_button_down
        MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     :+
        rts

:       cmp     #MGTK::Area::content
        bne     :+
        jmp     handle_content_click

        rts                     ; Unreached ???

:       rts
.endproc

.proc handle_content_click
        lda     findwindow_window_id
        cmp     winfo_file_dialog::window_id
        beq     :+
        jmp     handle_list_button_down

:       lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        lda     winfo_file_dialog::window_id
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx

        ;; --------------------------------------------------
.proc check_open_button
        MGTK_RELAY_CALL MGTK::InRect, file_dialog_res::open_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_change_drive_button

        bit     L5105
        bmi     L520A
        lda     selected_index
        bpl     L520D
L520A:  jmp     set_up_ports

L520D:  tax
        lda     file_list_index,x
        bmi     L5216
L5213:  jmp     set_up_ports

L5216:  lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        param_call ButtonEventLoopRelay, kFilePickerDlgWindowID, file_dialog_res::open_button_rect
        bmi     L5213
        jsr     L5607
        jmp     set_up_ports
.endproc

        ;; --------------------------------------------------
.proc check_change_drive_button
        MGTK_RELAY_CALL MGTK::InRect, file_dialog_res::change_drive_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_close_button
        bit     L5105
        bmi     :+

        param_call ButtonEventLoopRelay, kFilePickerDlgWindowID, file_dialog_res::change_drive_button_rect
        bmi     :+
        jsr     change_drive

:       jmp     set_up_ports
.endproc

        ;; --------------------------------------------------
.proc check_close_button
        MGTK_RELAY_CALL MGTK::InRect, file_dialog_res::close_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_ok_button
        bit     L5105
        bmi     :+

        param_call ButtonEventLoopRelay, kFilePickerDlgWindowID, file_dialog_res::close_button_rect
        bmi     :+
        jsr     L567F
:       jmp     set_up_ports
.endproc

        ;; --------------------------------------------------
.proc check_ok_button
        MGTK_RELAY_CALL MGTK::InRect, file_dialog_res::ok_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_cancel_button

        param_call ButtonEventLoopRelay, kFilePickerDlgWindowID, file_dialog_res::ok_button_rect
        bmi     :+
        jsr     jt_handle_meta_right_key
        jsr     jt_handle_ok
:       jmp     set_up_ports
.endproc

        ;; --------------------------------------------------
.proc check_cancel_button
        MGTK_RELAY_CALL MGTK::InRect, file_dialog_res::cancel_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_other_click

        param_call ButtonEventLoopRelay, kFilePickerDlgWindowID, file_dialog_res::cancel_button_rect
        bmi     :+
        jsr     jt_handle_cancel
:       jmp     set_up_ports
.endproc

        ;; --------------------------------------------------
.proc check_other_click
        bit     extra_controls_flag
        bpl     :+
        jsr     click_handler_hook
        bmi     set_up_ports
:       jsr     jt_handle_click
        rts
.endproc
.endproc

;;; ============================================================

.proc set_up_ports
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, window_grafport
        rts
.endproc

;;; ============================================================
;;; This vector gets patched by overlays that add controls.

click_handler_hook:
        jsr     noop
        rts

;;; ============================================================

.proc handle_list_button_down
        bit     L5105
        bmi     rts1
        MGTK_RELAY_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_which_ctl
        beq     L5341
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     rts1
        lda     winfo_file_dialog_listbox::vscroll
        and     #MGTK::Ctl::vertical_scroll_bar ; vertical scroll enabled?
        beq     rts1
        jmp     handle_vscroll_click

rts1:   rts

L5341:  lda     winfo_file_dialog_listbox::window_id
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        add16   screentowindow_windowy, winfo_file_dialog_listbox::cliprect+2, screentowindow_windowy
        ldax    screentowindow_windowy
        ldy     #kListEntryHeight
        jsr     Divide_16_8_16
        stax    screentowindow_windowy

        lda     selected_index
        cmp     screentowindow_windowy
        beq     same
        jmp     different

        ;; --------------------------------------------------
        ;; Click on the previous entry

same:   jsr     main::detect_double_click
        beq     open
        rts

open:   ldx     selected_index
        lda     file_list_index,x
        bmi     folder

        ;; File - select it.
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        jsr     jt_handle_ok
        jmp     rts1

        ;; Folder - open it.
folder: and     #$7F
        pha
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::open_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::open_button_rect
        lda     #0
        sta     hi

        ptr := $08
        copy16  #file_names, $08
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
        jsr     append_to_path_buf

        jsr     read_dir
        jsr     update_scrollbar
        lda     #0
        jsr     scroll_clip_rect
        jsr     update_disk_name
        jsr     draw_list_entries
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, window_grafport
        rts

hi:     .byte   0

        ;; --------------------------------------------------
        ;; Click on a different entry

different:
        lda     screentowindow_windowy
        cmp     num_file_names
        bcc     :+
        rts

:       lda     selected_index
        bmi     :+
        jsr     jt_strip_path_segment
        lda     selected_index
        jsr     invert_entry
:       lda     screentowindow_windowy
        sta     selected_index
        bit     LD8F0
        bpl     :+
        jsr     jt_prep_path
        jsr     jt_redraw_input
:       lda     selected_index
        jsr     invert_entry
        jsr     jt_list_selection_change

        jsr     main::detect_double_click
        bmi     :+
        jmp     open

:       rts
.endproc

;;; ============================================================

.proc handle_vscroll_click
        lda     findcontrol_which_part
        cmp     #MGTK::Part::up_arrow
        bne     :+
        jmp     handle_line_up

:       cmp     #MGTK::Part::down_arrow
        bne     :+
        jmp     handle_line_down

:       cmp     #MGTK::Part::page_up
        bne     :+
        jmp     handle_page_up

:       cmp     #MGTK::Part::page_down
        bne     :+
        jmp     handle_page_down

        ;; Track thumb
:       lda     #MGTK::Ctl::vertical_scroll_bar
        sta     trackthumb_params
        MGTK_RELAY_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_thumbmoved
        bne     :+
        rts
:       lda     trackthumb_thumbpos
        sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_stash
        jsr     scroll_clip_rect
        jsr     draw_list_entries
        rts
.endproc

;;; ============================================================

.proc handle_page_up
        lda     winfo_file_dialog_listbox::vthumbpos
        sec
        sbc     #kPageDelta
        bpl     :+
        lda     #0
:       sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     scroll_clip_rect
        jsr     draw_list_entries
        rts
.endproc

;;; ============================================================

.proc handle_page_down
        lda     winfo_file_dialog_listbox::vthumbpos
        clc
        adc     #kPageDelta
        cmp     num_file_names
        beq     :+
        bcc     :+
        lda     num_file_names
:       sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     scroll_clip_rect
        jsr     draw_list_entries
        rts
.endproc

;;; ============================================================

.proc handle_line_up
        lda     winfo_file_dialog_listbox::vthumbpos
        bne     :+
        rts

:       sec
        sbc     #kLineDelta
        sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     scroll_clip_rect
        jsr     draw_list_entries
        jsr     check_arrow_repeat
        jmp     handle_line_up
.endproc

;;; ============================================================

.proc handle_line_down
        lda     winfo_file_dialog_listbox::vthumbpos
        cmp     winfo_file_dialog_listbox::vthumbmax
        bne     :+
        rts

:       clc
        adc     #kLineDelta
        sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     scroll_clip_rect
        jsr     draw_list_entries
        jsr     check_arrow_repeat
        jmp     handle_line_down
.endproc

;;; ============================================================

.proc check_arrow_repeat
        MGTK_RELAY_CALL MGTK::PeekEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        beq     :+
        cmp     #MGTK::EventKind::drag
        beq     :+
        pla
        pla
        rts

:       MGTK_RELAY_CALL MGTK::GetEvent, event_params
        MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_window_id
        cmp     winfo_file_dialog_listbox::window_id
        beq     :+
        pla
        pla
        rts

:       lda     findwindow_which_area
        cmp     #MGTK::Area::content
        beq     :+
        pla
        pla
        rts

:       MGTK_RELAY_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        beq     :+
        pla
        pla
        rts

:       lda     findcontrol_which_part
        cmp     #MGTK::Part::page_up ; up_arrow or down_arrow ?
        bcc     :+                   ; Yes, continue
        pla
        pla
:       rts
.endproc

;;; ============================================================

.proc set_cursor_pointer
        bit     cursor_ibeam_flag
        bpl     :+
        MGTK_RELAY_CALL MGTK::SetCursor, pointer_cursor
        copy    #0, cursor_ibeam_flag
:       rts
.endproc

;;; ============================================================

.proc set_cursor_ibeam
        bit     cursor_ibeam_flag
        bmi     done
        MGTK_RELAY_CALL MGTK::SetCursor, ibeam_cursor
        lda     #$80
        sta     cursor_ibeam_flag
done:   rts
.endproc

cursor_ibeam_flag:              ; high bit set when cursor is I-beam
        .byte   0

;;; ============================================================

.proc L5607
        ldx     selected_index
        lda     file_list_index,x
        and     #$7F
        pha
        bit     LD8F0
        bpl     l1
        jsr     jt_prep_path
l1:     lda     #$00
        sta     l2
        copy16  #file_names, $08
        pla
        asl     a
        rol     l2
        asl     a
        rol     l2
        asl     a
        rol     l2
        asl     a
        rol     l2
        clc
        adc     $08
        sta     $08
        lda     l2
        adc     $09
        sta     $09

        ldx     $09
        lda     $08
        jsr     append_to_path_buf

        jsr     read_dir
        jsr     update_scrollbar
        lda     #$00
        jsr     scroll_clip_rect
        jsr     update_disk_name
        jsr     draw_list_entries
        rts

l2:     .byte   0
.endproc

;;; ============================================================

.proc change_drive
        lda     #$FF
        sta     selected_index
        jsr     dec_device_num
        jsr     device_on_line
        jsr     read_dir
        jsr     update_scrollbar
        lda     #$00
        jsr     scroll_clip_rect
        jsr     update_disk_name
        jsr     draw_list_entries
        jsr     jt_prep_path
        jsr     jt_redraw_input
        rts
.endproc

;;; ============================================================

.proc L567F
        lda     #$00
        sta     l7
        ldx     path_buf
        bne     l1
        jmp     l6

l1:     lda     path_buf,x
        and     #CHAR_MASK
        cmp     #'/'
        beq     l2
        dex
        bpl     l1
        jmp     l6

l2:     cpx     #$01
        bne     l3
        jmp     l6

l3:     jsr     strip_path_segment
        lda     selected_index
        pha
        lda     #$FF
        sta     selected_index
        jsr     read_dir
        jsr     update_scrollbar
        lda     #$00
        jsr     scroll_clip_rect
        jsr     update_disk_name
        jsr     draw_list_entries
        pla
        sta     selected_index
        bit     l7
        bmi     l4
        jsr     jt_strip_path_segment
        lda     selected_index
        bmi     l5
        jsr     jt_strip_path_segment
        jmp     l5

l4:     jsr     jt_prep_path
        jsr     jt_redraw_input
l5:     lda     #$FF
        sta     selected_index
l6:     rts

l7:     .byte   0

.endproc

;;; ============================================================

L56E3:  MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        rts

;;; ============================================================

.proc MLI_RELAY
        sty     call
        stax    params
        sta     ALTZPOFF
        lda     ROMIN2
        jsr     MLI
call:   .byte   0
params: .addr   0
        sta     ALTZPON
        tax
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts
.endproc

;;; ============================================================

.proc noop
        rts
.endproc

;;; ============================================================
;;; Key handler

.proc handle_key
        lda     event_modifiers
        beq     L59F7

        ;; With modifiers
        lda     event_key

        cmp     #CHAR_LEFT
        bne     :+
        jmp     jt_handle_meta_left_key ; start of line

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     jt_handle_meta_right_key ; end of line

:       bit     L5105
        bmi     L59E4
        cmp     #CHAR_DOWN
        bne     :+
        jmp     scroll_list_bottom ; end of list

:       cmp     #CHAR_UP
        bne     L59E4
        jmp     scroll_list_top ; start of list

L59E4:  cmp     #'0'
        bcc     :+
        cmp     #'9'+1
        bcs     :+
        jmp     key_meta_digit

:       bit     L5105
        bmi     L5A4F
        jmp     check_alpha

        ;; --------------------------------------------------
        ;; No modifiers

L59F7:  lda     event_key

        cmp     #CHAR_LEFT
        bne     :+
        jmp     jt_handle_left_key

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     jt_handle_right_key

:       cmp     #CHAR_RETURN
        bne     :+
        jmp     key_return

:       cmp     #CHAR_ESCAPE
        bne     :+
        jmp     key_escape

:       cmp     #CHAR_DELETE
        bne     :+
        jmp     key_delete

:       bit     L5105
        bpl     :+
        jmp     finish

:       cmp     #CHAR_TAB
        bne     not_tab
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::change_drive_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::change_drive_button_rect
        jsr     change_drive
L5A4F:  jmp     exit

not_tab:
        cmp     #CHAR_CTRL_O    ; Open
        bne     not_ctrl_o
        lda     selected_index
        bmi     exit
        tax
        lda     file_list_index,x
        bmi     :+
        jmp     exit

:       lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::open_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::open_button_rect
        jsr     L5607
        jmp     exit

not_ctrl_o:
        cmp     #CHAR_CTRL_C    ; Close
        bne     :+
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::close_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::close_button_rect
        jsr     L567F
        jmp     exit

:       cmp     #CHAR_DOWN
        bne     :+
        jmp     key_down

:       cmp     #CHAR_UP
        bne     finish
        jmp     key_up

finish: jsr     jt_handle_other_key
        rts

exit:   jsr     L56E3
        rts

;;; ============================================================

.proc key_return
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::ok_button_rect
        jsr     jt_handle_meta_right_key
        jsr     jt_handle_ok
        jsr     L56E3
        rts
.endproc

;;; ============================================================

.proc key_escape
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::cancel_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::cancel_button_rect
        jsr     jt_handle_cancel
        jsr     L56E3
        rts
.endproc

;;; ============================================================

.proc key_delete
        jsr     jt_handle_delete_key
        rts
.endproc

;;; ============================================================
;;; This vector gets patched by overlays that add controls.

key_meta_digit:
        jmp     noop

;;; ============================================================

.proc key_down
        lda     num_file_names
        beq     l1
        lda     selected_index
        bmi     l3
        tax
        inx
        cpx     num_file_names
        bcc     l2
l1:     rts

l2:     jsr     invert_entry
        jsr     jt_strip_path_segment
        inc     selected_index
        lda     selected_index
        jmp     update_list_selection

l3:     lda     #0
        jmp     update_list_selection
.endproc

;;; ============================================================

.proc key_up
        lda     num_file_names
        beq     l1
        lda     selected_index
        bmi     l3
        bne     l2
l1:     rts

l2:     jsr     invert_entry
        jsr     jt_strip_path_segment
        dec     selected_index
        lda     selected_index
        jmp     update_list_selection

l3:     ldx     num_file_names
        dex
        txa
        jmp     update_list_selection
.endproc

;;; ============================================================

check_alpha:
        jsr     upcase_char
        cmp     #'A'
        bcc     done
        cmp     #'Z'+1
        bcs     done

        jsr     L5B9D
        bmi     done
        cmp     selected_index
        beq     done
        pha
        lda     selected_index
        bmi     L5B99
        jsr     invert_entry
        jsr     jt_strip_path_segment
L5B99:  pla
        jmp     update_list_selection

done:   rts

.proc L5B9D
        sta     L5BF5
        lda     #0
        sta     L5BF3
L5BA5:  lda     L5BF3
        cmp     num_file_names
        beq     L5BC4
        jsr     L5BCB
        ldy     #1
        lda     ($06),y
        cmp     L5BF5
        bcc     L5BBE
        beq     L5BC7
        jmp     L5BC4

L5BBE:  inc     L5BF3
        jmp     L5BA5

L5BC4:  return  #$FF

L5BC7:  return  L5BF3
.endproc

.proc L5BCB
        tax
        lda     file_list_index,x
        and     #$7F
        ldx     #$00
        stx     L5BF4
        asl     a
        rol     L5BF4
        asl     a
        rol     L5BF4
        asl     a
        rol     L5BF4
        asl     a
        rol     L5BF4
        clc
        adc     #<file_names
        sta     $06
        lda     L5BF4
        adc     #>file_names
        sta     $07
        rts
.endproc

L5BF3:  .byte   0
L5BF4:  .byte   0
L5BF5:  .byte   0
.endproc

;;; ============================================================

.proc upcase_char
        cmp     #'a'
        bcc     done
        cmp     #'z'+1
        bcs     done
        and     #(CASE_MASK & $7F) ; convert lowercase to uppercase
done:   rts
.endproc

;;; ============================================================

.proc scroll_list_top
        lda     num_file_names
        beq     l1
        lda     selected_index
        bmi     l3
        bne     l2
l1:     rts

l2:     jsr     invert_entry
        jsr     jt_strip_path_segment
l3:     lda     #$00
        jmp     update_list_selection
.endproc

;;; ============================================================

.proc scroll_list_bottom
        lda     num_file_names
        beq     done
        ldx     selected_index
        bmi     l1
        inx
        cpx     num_file_names
        bne     :+
done:   rts

:       dex
        txa
        jsr     invert_entry
        jsr     jt_strip_path_segment
l1:     ldx     num_file_names
        dex
        txa
        jmp     update_list_selection
.endproc

;;; ============================================================

.proc update_list_selection
        sta     selected_index
        jsr     jt_list_selection_change

        lda     selected_index
        jsr     calc_top_index
        jsr     update_scrollbar2
        jsr     draw_list_entries

        copy    #1, path_buf2
        copy    #' ', path_buf2+1

        jsr     jt_redraw_input
        rts
.endproc

;;; ============================================================

        PAD_TO $5CF7            ; Maintain previous addresses

;;; ============================================================

.proc open_window
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_file_dialog
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_file_dialog_listbox
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::dialog_frame_rect
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::ok_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::open_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::close_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::cancel_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::change_drive_button_rect
        jsr     draw_ok_button_label
        jsr     draw_open_button_label
        jsr     draw_close_button_label
        jsr     draw_cancel_button_label
        jsr     draw_change_drive_button_label
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::dialog_sep_start
        MGTK_RELAY_CALL MGTK::LineTo, file_dialog_res::dialog_sep_end
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        rts
.endproc

draw_ok_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::ok_button_pos
        param_call draw_string, file_dialog_res::ok_button_label
        rts

draw_open_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::open_button_pos
        param_call draw_string, file_dialog_res::open_button_label
        rts

draw_close_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::close_button_pos
        param_call draw_string, file_dialog_res::close_button_label
        rts

draw_cancel_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::cancel_button_pos
        param_call draw_string, file_dialog_res::cancel_button_label
        rts

draw_change_drive_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::change_drive_button_pos
        param_call draw_string, file_dialog_res::change_drive_button_label
        rts

;;; ============================================================

.proc copy_string_to_lcbuf
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

;;; ============================================================

.proc draw_string
        ptr := $06
        params := $06

        jsr     copy_string_to_lcbuf
        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     params+2
        inc16   params
        MGTK_RELAY_CALL MGTK::DrawText, params
        rts
.endproc

;;; ============================================================

.proc draw_title_centered
        text_params     := $6
        text_addr       := text_params + 0
        text_length     := text_params + 2
        text_width      := text_params + 3

        stax    text_addr       ; input is length-prefixed string
        jsr     AuxLoad
        sta     text_length
        inc16   text_addr ; point past length byte
        MGTK_RELAY_CALL MGTK::TextWidth, text_params

        sub16   #kFilePickerDlgWidth, text_width, file_dialog_title_pos::xcoord
        lsr16   file_dialog_title_pos::xcoord ; /= 2
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_title_pos
        MGTK_RELAY_CALL MGTK::DrawText, text_params
        rts
.endproc

;;; ============================================================

.proc draw_input1_label
        jsr     copy_string_to_lcbuf
        stax    $06
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::input1_label_pos
        ldax    $06
        jsr     draw_string
        rts
.endproc

;;; ============================================================

.proc draw_input2_label
        jsr     copy_string_to_lcbuf
        stax    $06
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::input2_label_pos
        ldax    $06
        jsr     draw_string
        rts
.endproc

;;; ============================================================

.proc device_on_line
retry:  ldx     device_num
        lda     DEVLST,x

        and     #$F0
        sta     on_line_params::unit_num
        MLI_RELAY_CALL ON_LINE, on_line_params
        lda     on_line_buffer
        and     #NAME_LENGTH_MASK
        sta     on_line_buffer
        bne     found
        jsr     dec_device_num
        jmp     retry

found:  param_call main::AdjustVolumeNameCase, on_line_buffer
        lda     #0
        sta     path_buf
        param_call append_to_path_buf, on_line_buffer
        rts
.endproc

;;; ============================================================

.proc dec_device_num
        dec     device_num
        bpl     :+
        copy    DEVCNT, device_num
:       rts
.endproc

;;; ============================================================
;;; Init `device_number` (index) from the most recently accessed
;;; device via ProDOS Global Page `DEVNUM`. Used when the dialog
;;; is initialized with a specific path.

.proc init_device_number
        lda     DEVNUM
        and     #$F0
        sta     last

        ldx     DEVCNT
        inx
:       dex
        lda     DEVLST,x
        and     #$F0
        cmp     last
        bne     :-
        stx     device_num
        rts

last:   .byte   0
.endproc

;;; ============================================================

.proc open_dir
        lda     #$00
        sta     open_dir_flag
retry:  MLI_RELAY_CALL OPEN, open_params
        beq     :+
        jsr     device_on_line
        lda     #$FF
        sta     selected_index
        sta     open_dir_flag
        jmp     retry

:       lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_RELAY_CALL READ, read_params
        beq     :+
        jsr     device_on_line
        lda     #$FF
        sta     selected_index
        sta     open_dir_flag
        jmp     retry

:       rts
.endproc

open_dir_flag:
        .byte   0

;;; ============================================================

.proc append_to_path_buf
        jsr     copy_string_to_lcbuf
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

        ;; Enough room?
        cmp     #kPathBufferSize
        bcc     :+
        return  #$FF            ; failure
:       pha

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
        sta     selected_index

        return  #$00
.endproc

;;; ============================================================

.proc strip_path_segment
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

.proc read_dir
        jsr     open_dir
        lda     #0
        sta     l12
        sta     l13
        sta     L50A9
        lda     #1
        sta     l14
        copy16  dir_read_buf+SubdirectoryHeader::entry_length, entry_length
        lda     dir_read_buf+SubdirectoryHeader::file_count
        and     #$7F
        sta     num_file_names
        bne     :+
        jmp     close

        ptr := $06
:       copy16  #dir_read_buf+.sizeof(SubdirectoryHeader), ptr

l1:     param_call_indirect main::AdjustFileEntryCase, ptr

        ldy     #0
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        bne     l2
        jmp     l6

l2:     ldx     l12
        txa
        sta     file_list_index,x
        ldy     #0
        lda     (ptr),y
        and     #STORAGE_TYPE_MASK
        cmp     #ST_LINKED_DIRECTORY << 4
        beq     l3
        bit     L50A8
        bpl     l4
        inc     l13
        jmp     l6

l3:     lda     file_list_index,x
        ora     #$80
        sta     file_list_index,x
        inc     L50A9
l4:     ldy     #$00
        lda     (ptr),y
        and     #$0F
        sta     (ptr),y

        dst_ptr := $08
        copy16  #file_names, dst_ptr
        lda     #$00
        sta     l17
        lda     l12
        asl     a               ; *= 16
        rol     l17
        asl     a
        rol     l17
        asl     a
        rol     l17
        asl     a
        rol     l17
        clc
        adc     dst_ptr
        sta     dst_ptr
        lda     l17
        adc     dst_ptr+1
        sta     dst_ptr+1

        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     (dst_ptr),y
        dey
        bpl     :-

        inc     l12
        inc     l13
l6:     inc     l14
        lda     l13
        cmp     num_file_names
        bne     next

close:  MLI_RELAY_CALL CLOSE, close_params
        bit     L50A8
        bpl     :+
        lda     L50A9
        sta     num_file_names
:       jsr     sort_file_names
        jsr     L64E2
        lda     open_dir_flag
        bpl     l9
        sec
        rts

l9:     clc
        rts

next:   lda     l14
        cmp     l16
        beq     :+
        add16_8 ptr, entry_length, ptr
        jmp     l1

:       MLI_RELAY_CALL READ, read_params
        copy16  #dir_read_buf+$04, ptr
        lda     #$00
        sta     l14
        jmp     l1

l12:    .byte   0
l13:    .byte   0
l14:    .byte   0
entry_length:
        .byte   0
l16:    .byte   0
l17:    .byte   0
.endproc

;;; ============================================================

.proc draw_list_entries
        lda     winfo_file_dialog_listbox::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, winfo_file_dialog_listbox::cliprect
        copy    #kListEntryNameX, picker_entry_pos::xcoord ; high byte always 0
        copy16  #kListEntryHeight, picker_entry_pos::ycoord
        copy    #0, l4

loop:   lda     l4
        cmp     num_file_names
        bne     :+
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        rts

:       MGTK_RELAY_CALL MGTK::MoveTo, picker_entry_pos
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
        jsr     draw_string
        ldx     l4
        lda     file_list_index,x
        bpl     :+

        ;; Folder glyph
        copy    #kListEntryGlyphX, picker_entry_pos::xcoord
        MGTK_RELAY_CALL MGTK::MoveTo, picker_entry_pos
        param_call draw_string, str_folder
        copy    #kListEntryNameX, picker_entry_pos::xcoord

:       lda     l4
        cmp     selected_index
        bne     l2
        jsr     invert_entry
        lda     winfo_file_dialog_listbox::window_id
        jsr     set_port_for_window
l2:     inc     l4

        add16_8 picker_entry_pos::ycoord, #kListEntryHeight, picker_entry_pos::ycoord
        jmp     loop

l3:     .byte   0
l4:     .byte   0
.endproc

        PAD_TO $6161            ; Maintain previous addresses

;;; ============================================================

update_scrollbar:
        lda     #$00

.proc update_scrollbar2
        sta     index
        lda     num_file_names
        cmp     #kPageDelta + 1
        bcs     :+

        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_which_ctl
        lda     #MGTK::activatectl_deactivate
        sta     activatectl_activate
        MGTK_RELAY_CALL MGTK::ActivateCtl, activatectl_params
        lda     #0
        jmp     scroll_clip_rect

:       lda     num_file_names
        sta     winfo_file_dialog_listbox::vthumbmax
        .assert MGTK::Ctl::vertical_scroll_bar = MGTK::activatectl_activate, error, "need to match"
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_which_ctl
        sta     activatectl_activate
        MGTK_RELAY_CALL MGTK::ActivateCtl, activatectl_params
        lda     index
        sta     updatethumb_thumbpos
        jsr     scroll_clip_rect
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        rts

index:  .byte   0
.endproc

;;; ============================================================

.proc update_disk_name
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::rect_D9C8
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
        sta     $0220,x
        cpy     l5
        bne     l4
        stx     $0220
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::disk_label_pos
        param_call draw_string, file_dialog_res::disk_label_str
        param_call draw_string, $0220
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        rts

l5:     .byte   0
.endproc

;;; ============================================================

.proc scroll_clip_rect
        sta     l5
        clc
        adc     #kPageDelta
        cmp     num_file_names
        beq     l1
        bcs     l2
l1:     lda     l5
        jmp     l4

l2:     lda     num_file_names
        cmp     #kPageDelta+1
        bcs     l3
        lda     l5
        jmp     l4

l3:     sec
        sbc     #kPageDelta

l4:     ldx     #$00            ; A,X = line
        ldy     #kListEntryHeight
        jsr     Multiply_16_8_16
        stax    winfo_file_dialog_listbox::cliprect::y1
        add16_8 winfo_file_dialog_listbox::cliprect::y1, #winfo_file_dialog_listbox::kHeight, winfo_file_dialog_listbox::cliprect::y2
        rts

l5:     .byte   0
.endproc

;;; ============================================================
;;; Inputs: A = entry index

.proc invert_entry
        ldx     #0              ; A,X = entry
        ldy     #kListEntryHeight
        jsr     Multiply_16_8_16
        stax    rect_file_dialog_selection::y1

        add16_8 rect_file_dialog_selection::y1, #kListEntryHeight, rect_file_dialog_selection::y2

        lda     winfo_file_dialog_listbox::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_file_dialog_selection
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

.proc set_port_for_window
        sta     getwinport_params2::window_id
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params2
        MGTK_RELAY_CALL MGTK::SetPort, window_grafport
        rts
.endproc

;;; ============================================================
;;; Sorting

.proc sort_file_names
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
        jsr     calc_entry_ptr
        ldy     #0
        lda     ($06),y
        bmi     next_inner
        and     #$0F
        sta     name_buf        ; length

        ldy     #1
l3:     lda     ($06),y
        jsr     upcase_char
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
        sta     l19

        ldx     #15
        lda     #' '            ; before first possible name char
:       sta     name_buf+1,x
        dex
        bpl     :-

        ldy     name_buf
:       lda     ($06),y
        jsr     upcase_char
        sta     name_buf,y
        dey
        bne     :-

next_inner:
        inc     inner_index
        lda     inner_index
        cmp     num_file_names
        beq     :+
        jmp     loop2

:       lda     l19
        jsr     calc_entry_ptr
        ldy     #0              ; mark as done
        lda     ($06),y
        ora     #$80
        sta     ($06),y

        lda     #$7F            ; beyond last possible name char
        ldx     #15
:       sta     name_buf+1,x
        dex
        bpl     :-

        ldx     outer_index
        lda     l19
        sta     l22,x
        lda     #0
        sta     inner_index
        inc     outer_index
        jmp     loop

        ;; Finish up
finish: ldx     num_file_names
        dex
        stx     outer_index
l11:    lda     outer_index
        bpl     l16
        ldx     num_file_names
        beq     done
        dex
l12:    lda     l22,x
        tay
        lda     file_list_index,y
        bpl     l13
        lda     l22,x
        ora     #$80
        sta     l22,x
l13:    dex
        bpl     l12

        ldx     num_file_names
        beq     done
        dex
:       lda     l22,x
        sta     file_list_index,x
        dex
        bpl     :-

done:   rts

l16:    jsr     calc_entry_ptr
        ldy     #0
        lda     ($06),y
        and     #$7F
        sta     ($06),y
        dec     outer_index
        jmp     l11

inner_index:
        .byte   0
outer_index:
        .byte   0
l19:    .byte   0
name_buf:
        .res 17, 0

l22:    .res 127, 0

;;; --------------------------------------------------

.proc calc_entry_ptr
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

tmp:     .byte   0
.endproc
.endproc

;;; ============================================================

.proc L647C
        ptr := $06

        stax    ptr
        ldy     #$01
        lda     (ptr),y
        cmp     #'/'
        bne     l6
        dey
        lda     (ptr),y
        cmp     #$02
        bcc     l6
        tay
        lda     (ptr),y
        cmp     #'/'
        beq     l6
        ldx     #$00
        stx     l7
l1:     lda     (ptr),y
        cmp     #'/'
        beq     l2
        inx
        cpx     #$10
        beq     l6
        dey
        bne     l1
        beq     l3
l2:     inc     l7
        ldx     #$00
        dey
        bne     l1
l3:     ldy     #$00
        lda     (ptr),y
        tay
l4:     lda     (ptr),y
        and     #CHAR_MASK
        cmp     #'.'
        beq     l5
        cmp     #'/'
        bcc     l6
        cmp     #'9'+1
        bcc     l5
        cmp     #'A'
        bcc     l6
        cmp     #'Z'+1
        bcc     l5
        cmp     #'a'
        bcc     l6
        cmp     #'z'+1
        bcs     l6
l5:     dey
        bne     l4
        return  #$00

l6:     return  #$FF

l7:     .byte   0
.endproc

;;; ============================================================

.proc L64E2
        ptr := $06

        lda     num_file_names
        bne     l2
l1:     rts

l2:     lda     #$00
        sta     l4
        copy16  #file_names, ptr
l3:     lda     l4
        cmp     num_file_names
        beq     l1
        inc     l4
        lda     ptr
        clc
        adc     #$10
        sta     ptr
        bcc     l3
        inc     ptr+1
        jmp     l3

l4:     .byte   0
.endproc

;;; ============================================================
;;; Find index to filename in file_list_index.
;;; Input: $06 = ptr to filename
;;; Output: A = index, or $FF if not found

.proc L6516
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     l9,y
        dey
        bpl     :-
        lda     #$00
        sta     l8
        copy16  #file_names, $06
l2:     lda     l8
        cmp     num_file_names
        beq     l5
        ldy     #$00
        lda     ($06),y
        cmp     l9
        bne     l4
        tay
l3:     lda     ($06),y
        cmp     l9,y
        bne     l4
        dey
        bne     l3
        jmp     l6

l4:     inc     l8
        lda     $06
        clc
        adc     #$10
        sta     $06
        bcc     l2
        inc     $07
        jmp     l2

l5:     return  #$FF

l6:     ldx     num_file_names
l7:     dex
        lda     file_list_index,x
        and     #$7F
        cmp     l8
        bne     l7
        txa
        rts

l8:     .byte   0
l9:     .res 16, 0
.endproc

;;; ============================================================
;;; Input: A = Selection, or $FF if none
;;; Output: top index to show so selection is in view

.proc calc_top_index
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

.proc blink_f1_ip
        pt := $06

        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        jsr     calc_input1_ip_pos
        stax    $06
        copy16  file_dialog_res::input1_textpos+2, $08
        MGTK_RELAY_CALL MGTK::MoveTo, pt
        bit     prompt_ip_flag
        bpl     bg2

        MGTK_RELAY_CALL MGTK::SetTextBG, file_dialog_res::textbg1
        copy    #$00, prompt_ip_flag
        beq     :+

bg2:    MGTK_RELAY_CALL MGTK::SetTextBG, file_dialog_res::textbg2
        copy    #$FF, prompt_ip_flag

        PARAM_BLOCK dt_params, $06
data    .addr
length  .byte
        END_PARAM_BLOCK

:       copy16  #str_insertion_point+1, dt_params::data
        copy    str_insertion_point, dt_params::length
        MGTK_RELAY_CALL MGTK::DrawText, dt_params
        jsr     L56E3
        rts
.endproc

;;; ============================================================

.proc blink_f2_ip
        pt := $06

        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        jsr     calc_input2_ip_pos
        stax    $06
        copy16  file_dialog_res::input2_textpos+2, $08
        MGTK_RELAY_CALL MGTK::MoveTo, pt
        bit     prompt_ip_flag
        bpl     bg2

        MGTK_RELAY_CALL MGTK::SetTextBG, file_dialog_res::textbg1
        copy    #$00, prompt_ip_flag
        jmp     :+

bg2:    MGTK_RELAY_CALL MGTK::SetTextBG, file_dialog_res::textbg2
        copy    #$FF, prompt_ip_flag

        PARAM_BLOCK dt_params, $06
data    .addr
length  .byte
        END_PARAM_BLOCK

:       copy16  #str_insertion_point+1, dt_params::data
        copy    str_insertion_point, dt_params::length
        MGTK_RELAY_CALL MGTK::DrawText, pt
        jsr     L56E3
        rts
.endproc

;;; ============================================================

.proc redraw_f1
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::input1_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::input1_rect
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::input1_textpos
        lda     path_buf0
        beq     :+
        param_call draw_string, path_buf0
:       param_call draw_string, path_buf2
        param_call draw_string, str_2_spaces
        rts
.endproc

;;; ============================================================

.proc redraw_f2
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, file_dialog_res::input2_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, file_dialog_res::input2_rect
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::input2_textpos
        lda     path_buf1
        beq     :+
        param_call draw_string, path_buf1
:       param_call draw_string, path_buf2
        param_call draw_string, str_2_spaces
        rts
.endproc

;;; ============================================================
;;; A click when f1 has focus (click may be elsewhere)

.proc handle_f1_click
        lda     winfo_file_dialog::window_id
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx

        ;; Inside input1 ?
        MGTK_RELAY_CALL MGTK::InRect, file_dialog_res::input1_rect
        cmp     #MGTK::inrect_inside
        beq     ep2

        ;; Inside input2 ?
        bit     dual_inputs_flag
        bpl     done
        MGTK_RELAY_CALL MGTK::InRect, file_dialog_res::input2_rect
        cmp     #MGTK::inrect_inside
        bne     done
        jsr     jt_handle_ok    ; move focus to input2
        ;; NOTE: Assumes screentowindow_window* has not been changed.
        jmp     handle_f2_click__ep2

done:   rts

        ;; Is click to left or right of insertion point?
ep2:    jsr     calc_input1_ip_pos
        stax    $06
        cmp16   screentowindow_windowx, $06
        bcs     to_right
        jmp     to_left

        PARAM_BLOCK tw_params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        ;; --------------------------------------------------

.proc to_right
        jsr     calc_input1_ip_pos
        stax    ip_pos
        ldx     path_buf2
        inx
        lda     #' '            ; append space at end
        sta     path_buf2,x
        inc     path_buf2

        ;; Iterate to find the position
        copy16  #path_buf2, tw_params::data
        copy    path_buf2, tw_params::length
@loop:  MGTK_RELAY_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, ip_pos, tw_params::width
        cmp16   tw_params::width, screentowindow_windowx
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bne     @loop

        dec     path_buf2       ; remove appended space
        jmp     finish

        ;; Was it to the right of the string?
:       lda     tw_params::length
        cmp     path_buf2
        bcc     :+
        dec     path_buf2       ; remove appended space
        jmp     handle_f1_meta_right_key ; and use this shortcut

        ;; Append from `path_buf2` into `path_buf0`
:       ldx     #2
        ldy     path_buf0
        iny
:       lda     path_buf2,x
        sta     path_buf0,y
        cpx     tw_params::length
        beq     :+
        iny
        inx
        jmp     :-
:       sty     path_buf0

        ;; Shift contents of `path_buf2` down,
        ;; preserving IP at the start.
        ldy     #2
        ldx     tw_params::length
        inx
:       lda     path_buf2,x
        sta     path_buf2,y
        cpx     path_buf2
        beq     :+
        iny
        inx
        jmp     :-

:       dey
        sty     path_buf2
        jmp     finish
.endproc

        ;; --------------------------------------------------

.proc to_left
        ;; Iterate to find the position
        copy16  #path_buf0, tw_params::data
        copy    path_buf0, tw_params::length
@loop:  MGTK_RELAY_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, file_dialog_res::input1_textpos, tw_params::width
        cmp16   tw_params::width, screentowindow_windowx
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bcs     @loop
        jmp     handle_f1_meta_left_key

        ;; Found position; copy everything to the right of
        ;; the new position from `path_buf0` to `split_buf`
:       inc     tw_params::length
        ldy     #0
        ldx     tw_params::length
:       cpx     path_buf0
        beq     :+
        inx
        iny
        lda     path_buf0,x
        sta     split_buf+1,y
        jmp     :-
:       iny
        sty     split_buf

        ;; Append `path_buf2` to `split_buf`
        ldx     #1
        ldy     split_buf
:       cpx     path_buf2
        beq     :+
        inx
        iny
        lda     path_buf2,x
        sta     split_buf,y
        jmp     :-
:       sty     split_buf

        ;; Copy IP and `split_buf` into `path_buf2`
        copy    #kGlyphInsertionPoint, split_buf+1
:       lda     split_buf,y
        sta     path_buf2,y
        dey
        bpl     :-

        ;; Adjust length
        lda     tw_params::length
        sta     path_buf0
        ;; fall through
.endproc

finish: jsr     jt_redraw_input
        jsr     select_matching_file_in_list__f1
        rts

ip_pos: .word   0
.endproc

;;; ============================================================
;;; A click when f2 has focus (click may be elsewhere)

.proc handle_f2_click

        ;; Was click inside text box?
        lda     winfo_file_dialog::window_id
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx

        ;; Inside input2 ?
        MGTK_RELAY_CALL MGTK::InRect, file_dialog_res::input2_rect
        cmp     #MGTK::inrect_inside
        beq     ep2

        ;; Inside input1 ?
        bit     dual_inputs_flag
        bpl     done
        MGTK_RELAY_CALL MGTK::InRect, file_dialog_res::input1_rect
        cmp     #MGTK::inrect_inside
        bne     done
        jsr     jt_handle_cancel ; Move focus to input1
        ;; NOTE: Assumes screentowindow_window* has not been changed.
        jmp     handle_f1_click::ep2

done:   rts

        ;; Is click to left or right of insertion point?
ep2:    jsr     calc_input2_ip_pos
        stax    $06
        cmp16   screentowindow_windowx, $06
        bcs     to_right
        jmp     to_left

        PARAM_BLOCK tw_params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        ;; --------------------------------------------------
        ;; Click to right of insertion point
.proc to_right
        jsr     calc_input2_ip_pos
        stax    ip_pos
        ldx     path_buf2
        inx
        lda     #' '            ; append space at end
        sta     path_buf2,x
        inc     path_buf2

        ;; Iterate to find the position
        copy16  #path_buf2, tw_params::data
        copy    path_buf2, tw_params::length
@loop:  MGTK_RELAY_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, ip_pos, tw_params::width
        cmp16   tw_params::width, screentowindow_windowx
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bne     @loop

        dec     path_buf2       ; remove appended space
        jmp     finish

        ;; Was it to the right of the string?
:       lda     tw_params::length
        cmp     path_buf2
        bcc     :+
        dec     path_buf2       ; remove appended space
        jmp     handle_f2_meta_right_key ; and use this shortcut

        ;; Append from `path_buf2` into `path_buf1`
:       ldx     #2
        ldy     path_buf1
        iny
:       lda     path_buf2,x
        sta     path_buf1,y
        cpx     $08
        beq     :+
        iny
        inx
        jmp     :-
:       sty     path_buf1

        ;; Shift contents of `path_buf2` down,
        ;; preserving IP at the start.
        ldy     #2
        ldx     tw_params::length
        inx
:       lda     path_buf2,x
        sta     path_buf2,y
        cpx     path_buf2
        beq     :+
        iny
        inx
        jmp     :-

:       dey
        sty     path_buf2
        jmp     finish
.endproc

        ;; --------------------------------------------------
        ;; Click to left of insertion point

.proc to_left
        copy16  #path_buf1, tw_params::data
        copy    path_buf1, tw_params::length
@loop:  MGTK_RELAY_CALL MGTK::TextWidth, $06
        add16   tw_params::width, file_dialog_res::input2_textpos, tw_params::width
        cmp16   tw_params::width, screentowindow_windowx
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bcs     @loop
        jmp     handle_f2_meta_left_key

        ;; Found position; copy everything to the right of
        ;; the new position from `path_buf1` to `split_buf`
:       inc     tw_params::length
        ldy     #0
        ldx     tw_params::length
:       cpx     path_buf1
        beq     :+
        inx
        iny
        lda     path_buf1,x
        sta     split_buf+1,y
        jmp     :-
:       iny
        sty     split_buf

        ;; Append `path_buf2` to `split_buf`
        ldx     #1
        ldy     split_buf
:       cpx     path_buf2
        beq     :+
        inx
        iny
        lda     path_buf2,x
        sta     split_buf,y
        jmp     :-
:       sty     split_buf

        ;; Copy IP and `split_buf` into `path_buf2`
        copy    #kGlyphInsertionPoint, split_buf+1
:       lda     split_buf,y
        sta     path_buf2,y
        dey
        bpl     :-

        ;; Adjust length
        lda     tw_params::length
        sta     path_buf1
        ;; fall through
.endproc

finish: jsr     jt_redraw_input
        jsr     select_matching_file_in_list__f2
        rts

ip_pos: .word   0
.endproc
handle_f2_click__ep2 := handle_f2_click::ep2

;;; ============================================================

.proc handle_f1_other_key
        sta     tmp
        lda     path_buf0
        clc
        adc     path_buf2
        cmp     #kMaxInputLength
        bcc     continue
        rts

continue:
        lda     tmp
        ldx     path_buf0
        inx
        sta     path_buf0,x
        sta     str_1_char+1
        jsr     calc_input1_ip_pos
        inc     path_buf0
        stax    $06
        copy16  file_dialog_res::input1_textpos+2, $08
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        param_call draw_string, str_1_char
        param_call draw_string, path_buf2
        jsr     select_matching_file_in_list__f1
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

.proc handle_f1_delete_key
        lda     path_buf0
        bne     :+
        rts

:       dec     path_buf0
        jsr     calc_input1_ip_pos
        stax    $06
        copy16  file_dialog_res::input1_textpos+2, $08
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        param_call draw_string, path_buf2
        param_call draw_string, str_2_spaces
        jsr     select_matching_file_in_list__f1
        rts
.endproc

;;; ============================================================

.proc handle_f1_left_key
        lda     path_buf0
        bne     :+
        rts

:       ldx     path_buf2
        cpx     #1
        beq     skip
:       lda     path_buf2,x
        sta     path_buf2+1,x
        dex
        cpx     #1
        bne     :-

skip:   ldx     path_buf0
        lda     path_buf0,x
        sta     path_buf2+2
        dec     path_buf0
        inc     path_buf2
        jsr     calc_input1_ip_pos
        stax    $06
        copy16  file_dialog_res::input1_textpos+2, $08
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        param_call draw_string, path_buf2
        param_call draw_string, str_2_spaces
        jsr     select_matching_file_in_list__f1
        rts
.endproc

;;; ============================================================

.proc handle_f1_right_key
        lda     path_buf2
        cmp     #2
        bcs     :+
        rts

:       ldx     path_buf0
        inx
        lda     path_buf2+2
        sta     path_buf0,x
        inc     path_buf0
        ldx     path_buf2
        cpx     #3
        bcc     finish

        ldx     #2
:       lda     path_buf2+1,x
        sta     path_buf2,x
        inx
        cpx     path_buf2
        bne     :-

finish: dec     path_buf2
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::input1_textpos
        param_call draw_string, path_buf0
        param_call draw_string, path_buf2
        param_call draw_string, str_2_spaces
        jsr     select_matching_file_in_list__f1
        rts
.endproc

;;; ============================================================

.proc handle_f1_meta_left_key
        lda     path_buf0
        bne     :+
        rts

:       ldy     path_buf0
        lda     path_buf2
        cmp     #2
        bcc     skip

        ldx     #1
:       iny
        inx
        lda     path_buf2,x
        sta     path_buf0,y
        cpx     path_buf2
        bne     :-

skip:   sty     path_buf0

:       lda     path_buf0,y
        sta     path_buf2+1,y
        dey
        bne     :-
        ldx     path_buf0
        inx
        stx     path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        copy    #0, path_buf0
        jsr     jt_redraw_input
        jsr     select_matching_file_in_list__f1
        rts
.endproc

;;; ============================================================

.proc handle_f1_meta_right_key
        jsr     move_ip_to_end_f1
        jsr     jt_redraw_input
        jsr     select_matching_file_in_list__f1
        rts
.endproc

;;; ============================================================

.proc handle_f2_other_key
        sta     l1
        lda     path_buf1
        clc
        adc     path_buf2
        cmp     #kMaxInputLength
        bcc     :+
        rts

:       lda     l1
        ldx     path_buf1
        inx
        sta     path_buf1,x
        sta     str_1_char+1
        jsr     calc_input2_ip_pos
        inc     path_buf1
        stax    $06
        copy16  file_dialog_res::input2_textpos+2, $08
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        param_call draw_string, str_1_char
        param_call draw_string, path_buf2
        jsr     select_matching_file_in_list__f2
        rts

l1:     .byte   0
.endproc

;;; ============================================================

.proc handle_f2_delete_key
        lda     path_buf1
        bne     :+
        rts

:       dec     path_buf1
        jsr     calc_input2_ip_pos
        stax    $06
        copy16  file_dialog_res::input2_textpos+2, $08
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        param_call draw_string, path_buf2
        param_call draw_string, str_2_spaces
        jsr     select_matching_file_in_list__f2
        rts
.endproc

;;; ============================================================

.proc handle_f2_left_key
        lda     path_buf1
        bne     l1
        rts

l1:     ldx     path_buf2
        cpx     #$01
        beq     l3
l2:     lda     path_buf2,x
        sta     path_buf2+1,x
        dex
        cpx     #$01
        bne     l2
l3:     ldx     path_buf1
        lda     path_buf1,x
        sta     path_buf2+2
        dec     path_buf1
        inc     path_buf2
        jsr     calc_input2_ip_pos
        stax    $06
        copy16  file_dialog_res::input2_textpos+2, $08
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        param_call draw_string, path_buf2
        param_call draw_string, str_2_spaces
        jsr     select_matching_file_in_list__f2
        rts
.endproc

;;; ============================================================

.proc handle_f2_right_key
        lda     path_buf2
        cmp     #$02
        bcs     l1
        rts

l1:     ldx     path_buf1
        inx
        lda     path_buf2+2
        sta     path_buf1,x
        inc     path_buf1
        ldx     path_buf2
        cpx     #$03
        bcc     l3
        ldx     #$02
l2:     lda     path_buf2+1,x
        sta     path_buf2,x
        inx
        cpx     path_buf2
        bne     l2
l3:     dec     path_buf2
        lda     winfo_file_dialog::window_id
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, file_dialog_res::input2_textpos
        param_call draw_string, path_buf1
        param_call draw_string, path_buf2
        param_call draw_string, str_2_spaces
        jsr     select_matching_file_in_list__f2
        rts
.endproc

;;; ============================================================

.proc handle_f2_meta_left_key
        lda     path_buf1
        bne     l1
        rts

l1:     ldy     path_buf1
        lda     path_buf2
        cmp     #$02
        bcc     l3
        ldx     #$01
l2:     iny
        inx
        lda     path_buf2,x
        sta     path_buf1,y
        cpx     path_buf2
        bne     l2
l3:     sty     path_buf1
l4:     lda     path_buf1,y
        sta     path_buf2+1,y
        dey
        bne     l4
        ldx     path_buf1
        inx
        stx     path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        copy    #0, path_buf1
        jsr     jt_redraw_input
        jsr     select_matching_file_in_list__f2
        rts
.endproc

;;; ============================================================

.proc handle_f2_meta_right_key
        jsr     move_ip_to_end_f2
        jsr     jt_redraw_input
        jsr     select_matching_file_in_list__f2
        rts
.endproc

;;; ============================================================

;;; Dynamically altered table of handlers for focused
;;; input field (e.g. source/destination filename, etc)

kJumpTableSize = $2A
jump_table:
jt_handle_ok:                   jmp     0
jt_handle_cancel:               jmp     0
jt_blink_ip:                    jmp     0
jt_redraw_input:                jmp     0
jt_strip_path_segment:          jmp     0
jt_list_selection_change:       jmp     0
jt_prep_path:                   jmp     0
jt_handle_other_key:            jmp     0
jt_handle_delete_key:           jmp     0
jt_handle_left_key:             jmp     0
jt_handle_right_key:            jmp     0
jt_handle_meta_left_key:        jmp     0
jt_handle_meta_right_key:       jmp     0
jt_handle_click:                jmp     0
        .assert * - jump_table = kJumpTableSize, error, "Table size mismatch"

;;; ============================================================
;;; Input: A,X = string address

.proc append_to_path_buf0
        ptr := $06

        stax    ptr

        ldx     path_buf0
        lda     #'/'
        sta     path_buf0+1,x
        inc     path_buf0

        ldy     #0
        lda     (ptr),y
        tay
        clc
        adc     path_buf0
        pha
        tax

:       lda     (ptr),y
        sta     path_buf0,x
        dey
        dex
        cpx     path_buf0
        bne     :-

        pla
        sta     path_buf0
        rts
.endproc

;;; ============================================================
;;; Input: A,X = string address

.proc append_to_path_buf1
        ptr := $06

        stax    ptr

        ldx     path_buf1
        lda     #'/'
        sta     path_buf1+1,x
        inc     path_buf1

        ldy     #$00
        lda     (ptr),y
        tay
        clc
        adc     path_buf1
        pha
        tax

:       lda     (ptr),y
        sta     path_buf1,x
        dey
        dex
        cpx     path_buf1
        bne     :-

        pla
        sta     path_buf1
        rts
.endproc

;;; ============================================================
;;; Trim end of left segment to rightmost '/'

.proc strip_path_buf0_segment
:       ldx     path_buf0
        cpx     #0
        beq     :+
        dec     path_buf0
        lda     path_buf0,x
        cmp     #'/'
        bne     :-
:       rts
.endproc

;;; ============================================================

.proc strip_path_buf1_segment
:       ldx     path_buf1
        cpx     #0
        beq     :+
        dec     path_buf1
        lda     path_buf1,x
        cmp     #'/'
        bne     :-
:       rts
.endproc

;;; ============================================================

.proc strip_f1_path_segment
        jsr     strip_path_buf0_segment
        jsr     jt_redraw_input
        rts
.endproc

;;; ============================================================

.proc strip_f2_path_segment
        jsr     strip_path_buf1_segment
        jsr     jt_redraw_input
        rts
.endproc

;;; ============================================================

handle_f1_selection_change:
        lda     #$00
        beq     L6DD6

handle_f2_selection_change:
        lda     #$80

.proc L6DD6
        ptr := $06

        sta     flag
        copy16  #file_names, ptr
        ldx     selected_index
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

        bit     flag
        bpl     f1
        jsr     append_to_path_buf1
        jmp     :+

f1:     jsr     append_to_path_buf0

:       jsr     jt_redraw_input
        rts

hi:     .byte   0               ; high byte
flag:   .byte   0
.endproc

;;; ============================================================

.proc prep_path_buf0
        COPY_STRING path_buf, path_buf0
        rts
.endproc

;;; ============================================================

.proc prep_path_buf1
        COPY_STRING path_buf, path_buf1
        rts
.endproc

;;; ============================================================
;;; Output: A,X = coordinates of input string end

.proc calc_input1_ip_pos
        PARAM_BLOCK params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        lda     #0
        sta     params::width
        sta     params::width+1
        lda     path_buf0
        beq     :+

        sta     params::length
        copy16  #path_buf0+1, params::data
        MGTK_RELAY_CALL MGTK::TextWidth, params

:       lda     params::width
        clc
        adc     file_dialog_res::input1_textpos
        tay
        lda     params::width+1
        adc     file_dialog_res::input1_textpos+1
        tax
        tya
        rts
.endproc

;;; ============================================================

.proc calc_input2_ip_pos
        PARAM_BLOCK params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        lda     #0
        sta     params::width
        sta     params::width+1
        lda     path_buf1
        beq     :+

        sta     params::length
        copy16  #path_buf1+1, params::data
        MGTK_RELAY_CALL MGTK::TextWidth, params

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

;;; ============================================================

.proc select_matching_file_in_list

f2:     lda     #$FF
        bmi     l1

f1:     lda     #$00

l1:     bmi     l3
        COPY_STRING path_buf0, split_buf
        jmp     l4

l3:     COPY_STRING path_buf1, split_buf

l4:     lda     selected_index
        sta     d2
        bmi     l5
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
        jsr     append_to_path_buf

l5:     lda     split_buf
        cmp     path_buf
        bne     l7
        tax
l6:     lda     split_buf,x
        cmp     path_buf,x
        bne     l7
        dex
        bne     l6
        lda     #0
        sta     LD8F0
        jsr     l8
        rts

l7:     lda     #$FF
        sta     LD8F0
        jsr     l8
        rts

l8:     lda     d2
        sta     selected_index
        bpl     l9
        rts

l9:     jsr     strip_path_segment
        rts

d1:     .byte   0
d2:     .byte   0
.endproc
select_matching_file_in_list__f1 := select_matching_file_in_list::f1
select_matching_file_in_list__f2 := select_matching_file_in_list::f2

;;; ============================================================

.proc move_ip_to_end_f1
        lda     path_buf2
        cmp     #2
        bcc     done

        ldx     #1
        ldy     path_buf0
:       inx
        iny
        lda     path_buf2,x
        sta     path_buf0,y
        cpx     path_buf2
        bne     :-
        sty     path_buf0

        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1

done:   rts
.endproc

.proc move_ip_to_end_f2
        lda     path_buf2
        cmp     #2
        bcc     done

        ldx     #1
        ldy     path_buf1
:       inx
        iny
        lda     path_buf2,x
        sta     path_buf1,y
        cpx     path_buf2
        bne     :-
        sty     path_buf1

        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1

done:   rts
.endproc

;;; ============================================================

        .include "../lib/muldiv.s"

;;; ============================================================

        PAD_TO $7000

.endproc ; file_dialog

file_dialog_exec := file_dialog::exec
