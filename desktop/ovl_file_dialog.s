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

;;; ============================================================

exec:
L5000:  jmp     L50B1

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer
        DEFINE_OPEN_PARAMS open_params, path_buf, $1000
        DEFINE_READ_PARAMS read_params, $1400, $200
        DEFINE_CLOSE_PARAMS close_params

on_line_buffer: .res    16, 0
device_num:  .byte   $00        ; next device number to try
path_buf:       .res    128, 0
L50A8:  .byte   $00
L50A9:  .byte   $00

;;; ============================================================

stash_stack:    .byte   0
routine_table:  .addr   $7000, $7000, $7000

.proc L50B1
        sty     stash_y
        stx     stash_x
        tsx
        stx     stash_stack
        pha
        lda     #0
        sta     device_num
        sta     L50A8
        sta     prompt_ip_flag
        sta     LD8EC
        sta     LD8F0
        sta     LD8F1
        sta     LD8F2
        sta     cursor_ip_flag
        sta     L5104
        sta     L5103
        sta     L5105
        lda     SETTINGS + DeskTopSettings::ip_blink_speed
        sta     prompt_ip_counter
        lda     #$FF
        sta     selected_index
        pla
        asl     a
        tax
        copy16  routine_table,x, @jump
        ldy     stash_y
        ldx     stash_x

        @jump := *+1
        jmp     dummy1234

stash_x:        .byte   0
stash_y:        .byte   0
.endproc

;;; ============================================================
;;; Flags set by invoker to alter behavior

L5103:  .byte   0               ; ??? something before jt_handle_click invoked
L5104:  .byte   0               ; ??? something about inputs
L5105:  .byte   0               ; ??? something about the picker

;;; ============================================================

.proc event_loop
        bit     LD8EC
        bpl     :+

        dec     prompt_ip_counter
        bne     :+
        jsr     jt_blink_ip
        copy    SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter

:       MGTK_RELAY_CALL MGTK::GetEvent, event_params
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
        cmp     winfo_entrydlg
        beq     L5151
        jmp     event_loop

L5151:  lda     winfo_entrydlg
        jsr     set_port_for_window
        lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        bit     L51AE
        bmi     L5183
        MGTK_RELAY_CALL MGTK::InRect, common_input1_rect
        cmp     #MGTK::inrect_inside
        bne     L5196
        beq     L5190
L5183:  MGTK_RELAY_CALL MGTK::InRect, common_input2_rect
        cmp     #MGTK::inrect_inside
        bne     L5196
L5190:  jsr     set_cursor_insertion
        jmp     L5199

L5196:  jsr     set_cursor_pointer
L5199:  MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        jmp     event_loop
.endproc

L51AE:  .byte   0

;;; ============================================================

.proc handle_button_down
        MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     :+
        rts
:       cmp     #MGTK::Area::content
        bne     :+
        jmp     L51C7
        rts                     ; Unreached ???
:       rts

L51C7:  lda     findwindow_window_id
        cmp     winfo_entrydlg
        beq     :+
        jmp     handle_list_button_down

:       lda     winfo_entrydlg
        jsr     set_port_for_window
        lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx

        ;; --------------------------------------------------
        ;; In open button?
.proc check_open_button
        MGTK_RELAY_CALL MGTK::InRect, common_open_button_rect
        cmp     #MGTK::inrect_inside
        beq     clicked
        jmp     check_change_drive_button

clicked:
        bit     L5105
        bmi     L520A
        lda     selected_index
        bpl     L520D
L520A:  jmp     set_up_ports

L520D:  tax
        lda     file_list_index,x
        bmi     L5216
L5213:  jmp     set_up_ports

L5216:  lda     winfo_entrydlg
        jsr     set_port_for_window
        yax_call ButtonEventLoopRelay, kFilePickerDlgWindowID, common_open_button_rect
        bmi     L5213
        jsr     L5607
        jmp     set_up_ports
.endproc

        ;; --------------------------------------------------
.proc check_change_drive_button
        MGTK_RELAY_CALL MGTK::InRect, common_change_drive_button_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        jmp     check_close_button
:       bit     L5105
        bmi     :+
        yax_call ButtonEventLoopRelay, kFilePickerDlgWindowID, common_change_drive_button_rect
        bmi     :+
        jsr     L565C
:       jmp     set_up_ports
.endproc

.proc check_close_button
        MGTK_RELAY_CALL MGTK::InRect, common_close_button_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        jmp     check_ok_button
:       bit     L5105
        bmi     :+
        yax_call ButtonEventLoopRelay, kFilePickerDlgWindowID, common_close_button_rect
        bmi     :+
        jsr     L567F
:       jmp     set_up_ports
.endproc

        ;; --------------------------------------------------
.proc check_ok_button
        MGTK_RELAY_CALL MGTK::InRect, common_ok_button_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        jmp     check_cancel_button
:       yax_call ButtonEventLoopRelay, kFilePickerDlgWindowID, common_ok_button_rect
        bmi     :+
        jsr     jt_handle_meta_right_key
        jsr     jt_handle_ok
:       jmp     set_up_ports
.endproc

        ;; --------------------------------------------------
.proc check_cancel_button
        MGTK_RELAY_CALL MGTK::InRect, common_cancel_button_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        jmp     check_other_click
:       yax_call ButtonEventLoopRelay, kFilePickerDlgWindowID, common_cancel_button_rect
        bmi     :+
        jsr     jt_handle_cancel
:       jmp     set_up_ports
.endproc

        ;; --------------------------------------------------
.proc check_other_click
        bit     L5103
        bpl     :+
        jsr     L531B
        bmi     set_up_ports
:       jsr     jt_handle_click
        rts
.endproc
.endproc

;;; ============================================================

.proc set_up_ports
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport2
        rts
.endproc

;;; ============================================================

L531B:  jsr     noop
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
        lda     winfo_entrydlg_file_picker::vscroll
        and     #MGTK::Ctl::vertical_scroll_bar ; vertical scroll enabled?
        beq     rts1
        jmp     handle_vscroll_click

rts1:   rts

L5341:  lda     winfo_entrydlg_file_picker
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        add16   screentowindow_windowy, winfo_entrydlg_file_picker::cliprect+2, screentowindow_windowy
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
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
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_ok_button_rect
        jsr     jt_handle_ok
        jmp     rts1

        ;; Folder - open it.
folder: and     #$7F
        pha
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_open_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_open_button_rect
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
        jsr     L5F0D
        jsr     L5F5B
        jsr     L6161
        lda     #0
        jsr     scroll_clip_rect
        jsr     L61B1
        jsr     draw_list_entries
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport2
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
        jsr     L6274
:       lda     screentowindow_windowy
        sta     selected_index
        bit     LD8F0
        bpl     :+
        jsr     jt_prep_path
        jsr     jt_redraw_input
:       lda     selected_index
        jsr     L6274
        jsr     jt_05

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

        ;; Thumb
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

        kLineDelta = 1
        kPageDelta = 9

.proc handle_page_up
        lda     winfo_entrydlg_file_picker::vthumbpos
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

.proc handle_page_down
        lda     winfo_entrydlg_file_picker::vthumbpos
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

.proc handle_line_up
        lda     winfo_entrydlg_file_picker::vthumbpos
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

.proc handle_line_down
        lda     winfo_entrydlg_file_picker::vthumbpos
        cmp     winfo_entrydlg_file_picker::vthumbmax
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
        cmp     winfo_entrydlg_file_picker
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
        bit     cursor_ip_flag
        bpl     done
        MGTK_RELAY_CALL MGTK::HideCursor
        MGTK_RELAY_CALL MGTK::SetCursor, pointer_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor
        lda     #$00
        sta     cursor_ip_flag
done:   rts
.endproc

;;; ============================================================

.proc set_cursor_insertion
        bit     cursor_ip_flag
        bmi     done
        MGTK_RELAY_CALL MGTK::HideCursor
        MGTK_RELAY_CALL MGTK::SetCursor, insertion_point_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor
        lda     #$80
        sta     cursor_ip_flag
done:   rts
.endproc

cursor_ip_flag:                 ; high bit set when cursor is IP
        .byte   0

;;; ============================================================

.proc L5607
        ldx     selected_index
        lda     file_list_index,x
        and     #$7F
        pha
        bit     LD8F0
        bpl     L5618
        jsr     jt_prep_path
L5618:  lda     #$00
        sta     L565B
        copy16  #file_names, $08
        pla
        asl     a
        rol     L565B
        asl     a
        rol     L565B
        asl     a
        rol     L565B
        asl     a
        rol     L565B
        clc
        adc     $08
        sta     $08
        lda     L565B
        adc     $09
        sta     $09
        ldx     $09
        lda     $08
        jsr     L5F0D
        jsr     L5F5B
        jsr     L6161
        lda     #$00
        jsr     scroll_clip_rect
        jsr     L61B1
        jsr     draw_list_entries
        rts

L565B:  .byte   0
.endproc

;;; ============================================================

L565C:  lda     #$FF
        sta     selected_index
        jsr     inc_device_num
        jsr     device_on_line
        jsr     L5F5B
        jsr     L6161
        lda     #$00
        jsr     scroll_clip_rect
        jsr     L61B1
        jsr     draw_list_entries
        jsr     jt_prep_path
        jsr     jt_redraw_input
        rts

L567F:  lda     #$00
        sta     L56E2
        ldx     path_buf
        bne     L568C
        jmp     L56E1

L568C:  lda     path_buf,x
        and     #CHAR_MASK
        cmp     #'/'
        beq     L569B
        dex
        bpl     L568C
        jmp     L56E1

L569B:  cpx     #$01
        bne     L56A2
        jmp     L56E1

L56A2:  jsr     L5F49
        lda     selected_index
        pha
        lda     #$FF
        sta     selected_index
        jsr     L5F5B
        jsr     L6161
        lda     #$00
        jsr     scroll_clip_rect
        jsr     L61B1
        jsr     draw_list_entries
        pla
        sta     selected_index
        bit     L56E2
        bmi     L56D6
        jsr     jt_strip_path_segment
        lda     selected_index
        bmi     L56DC
        jsr     jt_strip_path_segment
        jmp     L56DC

L56D6:  jsr     jt_prep_path
        jsr     jt_redraw_input
L56DC:  lda     #$FF
        sta     selected_index
L56E1:  rts

L56E2:  .byte   0

L56E3:  MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
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
        and     #CHAR_MASK

        cmp     #CHAR_LEFT
        bne     :+
        jmp     jt_handle_meta_left_key           ; start of line

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     jt_handle_meta_right_key           ; end of line

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
        jmp     L5B70

;;; ============================================================
;;; Key - without modifiers

L59F7:  lda     event_key
        and     #CHAR_MASK

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
        bpl     L5A27
        jmp     L5AC4

L5A27:  cmp     #CHAR_TAB
        bne     L5A52
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_change_drive_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_change_drive_button_rect
        jsr     L565C
L5A4F:  jmp     L5AC8

L5A52:  cmp     #CHAR_CTRL_O    ; Open
        bne     L5A8B
        lda     selected_index
        bmi     L5AC8
        tax
        lda     file_list_index,x
        bmi     :+
        jmp     L5AC8
:       lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_open_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_open_button_rect
        jsr     L5607
        jmp     L5AC8

L5A8B:  cmp     #CHAR_CTRL_C    ; Close
        bne     :+
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_close_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_close_button_rect
        jsr     L567F
        jmp     L5AC8

:       cmp     #CHAR_DOWN
        bne     :+
        jmp     key_down

:       cmp     #CHAR_UP
        bne     L5AC4
        jmp     key_up

L5AC4:  jsr     jt_handle_other_key
        rts

L5AC8:  jsr     L56E3
        rts

key_return:
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_RELAY_CALL MGTK::PaintRect, common_ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_ok_button_rect
        jsr     jt_handle_meta_right_key
        jsr     jt_handle_ok
        jsr     L56E3
        rts

key_escape:
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_RELAY_CALL MGTK::PaintRect, common_cancel_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_cancel_button_rect
        jsr     jt_handle_cancel
        jsr     L56E3
        rts

key_delete:
        jsr     jt_handle_delete_key
        rts

key_meta_digit:
        jmp     noop

.proc key_down
        lda     num_file_names
        beq     L5B37
        lda     selected_index
        bmi     L5B47
        tax
        inx
        cpx     num_file_names
        bcc     L5B38
L5B37:  rts

L5B38:  jsr     L6274
        jsr     jt_strip_path_segment
        inc     selected_index
        lda     selected_index
        jmp     update_list_selection

L5B47:  lda     #0
        jmp     update_list_selection
.endproc

.proc key_up
        lda     num_file_names
        beq     L5B58
        lda     selected_index
        bmi     L5B68
        bne     L5B59
L5B58:  rts

L5B59:  jsr     L6274
        jsr     jt_strip_path_segment
        dec     selected_index
        lda     selected_index
        jmp     update_list_selection

L5B68:  ldx     num_file_names
        dex
        txa
        jmp     update_list_selection
.endproc

L5B70:  cmp     #'A'            ; upper alpha?
        bcs     :+
done:   rts
:       cmp     #'Z'+1
        bcc     L5B83
        cmp     #'a'            ; Lower alpha?
        bcc     done
        cmp     #'z'+1
        bcs     done
        and     #$5F            ; convert lowercase to uppercase

L5B83:  jsr     L5B9D
        bmi     done
        cmp     selected_index
        beq     done
        pha
        lda     selected_index
        bmi     L5B99
        jsr     L6274
        jsr     jt_strip_path_segment
L5B99:  pla
        jmp     update_list_selection

L5B9D:  sta     L5BF5
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

L5BCB:  tax
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
        adc     #$00
        sta     $06
        lda     L5BF4
        adc     #$18
        sta     $07
        rts

L5BF3:  .byte   0
L5BF4:  .byte   0
L5BF5:  .byte   0
.endproc

;;; ============================================================

.proc scroll_list_top
        lda     num_file_names
        beq     L5C02
        lda     selected_index
        bmi     L5C09
        bne     L5C03
L5C02:  rts

L5C03:  jsr     L6274
        jsr     jt_strip_path_segment
L5C09:  lda     #$00
        jmp     update_list_selection
.endproc

.proc scroll_list_bottom
        lda     num_file_names
        beq     L5C1E
        ldx     selected_index
        bmi     L5C27
        inx
        cpx     num_file_names
        bne     L5C1F
L5C1E:  rts

L5C1F:  dex
        txa
        jsr     L6274
        jsr     jt_strip_path_segment
L5C27:  ldx     num_file_names
        dex
        txa
        jmp     update_list_selection
.endproc

;;; ============================================================

.proc update_list_selection
        sta     selected_index
        jsr     jt_05
        lda     selected_index
        jsr     L6586
        jsr     L6163
        jsr     draw_list_entries

        copy    #1, path_buf2
        copy    #' ', path_buf2+1

        jsr     jt_redraw_input
        rts
.endproc

;;; ============================================================

        PAD_TO $5CF7            ; Maintain previous addresses

;;; ============================================================

.proc create_common_dialog
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_entrydlg
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_entrydlg_file_picker
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, common_dialog_frame_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_ok_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_open_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_close_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_cancel_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_change_drive_button_rect
        jsr     draw_ok_button_label
        jsr     draw_open_button_label
        jsr     draw_close_button_label
        jsr     draw_cancel_button_label
        jsr     draw_change_drive_button_label
        MGTK_RELAY_CALL MGTK::MoveTo, common_dialog_sep_start
        MGTK_RELAY_CALL MGTK::LineTo, common_dialog_sep_end
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts
.endproc

draw_ok_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, ok_button_pos
        addr_call draw_string, ok_button_label
        rts

draw_open_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, open_button_pos
        addr_call draw_string, open_button_label
        rts

draw_close_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, close_button_pos
        addr_call draw_string, close_button_label
        rts

draw_cancel_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, cancel_button_pos
        addr_call draw_string, cancel_button_label
        rts

draw_change_drive_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, change_drive_button_pos
        addr_call draw_string, change_drive_button_label
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
        jsr     copy_string_to_lcbuf
        stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
        MGTK_RELAY_CALL MGTK::DrawText, $06
        rts
.endproc

;;; ============================================================

.proc L5E0A
        jsr     copy_string_to_lcbuf
        stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
        MGTK_RELAY_CALL MGTK::TextWidth, $06
        lsr16    $09
        lda     #$01
        sta     L5E56
        lda     #$F4
        lsr     L5E56
        ror     a
        sec
        sbc     $09
        sta     pos_D90B
        lda     L5E56
        sbc     $0A
        sta     pos_D90B+1
        MGTK_RELAY_CALL MGTK::MoveTo, pos_D90B
        MGTK_RELAY_CALL MGTK::DrawText, $06
        rts

L5E56:  .byte   0
.endproc

;;; ============================================================

L5E57:  jsr     copy_string_to_lcbuf
        stax    $06
        MGTK_RELAY_CALL MGTK::MoveTo, common_input1_label_pos
        ldax    $06
        jsr     draw_string
        rts

;;; ============================================================

L5E6F:  jsr     copy_string_to_lcbuf
        stax    $06
        MGTK_RELAY_CALL MGTK::MoveTo, common_input2_label_pos
        ldax    $06
        jsr     draw_string
        rts

;;; ============================================================

.proc device_on_line
:       ldx     device_num
        lda     DEVLST,x
        and     #$F0
        sta     on_line_params::unit_num
        yax_call MLI_RELAY, ON_LINE, on_line_params
        lda     on_line_buffer
        and     #NAME_LENGTH_MASK
        sta     on_line_buffer
        bne     found
        jsr     inc_device_num
        jmp     :-

found:  addr_call main::adjust_volname_case, on_line_buffer
        lda     #0
        sta     path_buf
        addr_call L5F0D, on_line_buffer
        rts
.endproc

;;; ============================================================

.proc inc_device_num
        inc     device_num
        lda     device_num
        cmp     DEVCNT
        beq     :+
        bcc     :+
        lda     #0
        sta     device_num
:       rts
.endproc

;;; ============================================================


L5ECB:  lda     #$00
        sta     L5F0C
L5ED0:  yax_call MLI_RELAY, OPEN, open_params
        beq     L5EE9
        jsr     device_on_line
        lda     #$FF
        sta     selected_index
        sta     L5F0C
        jmp     L5ED0

L5EE9:  lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        yax_call MLI_RELAY, READ, read_params
        beq     L5F0B
        jsr     device_on_line
        lda     #$FF
        sta     selected_index
        sta     L5F0C
        jmp     L5ED0

L5F0B:  rts

L5F0C:  .byte   0
L5F0D:  jsr     copy_string_to_lcbuf
        stax    $06
        ldx     path_buf
        lda     #'/'
        sta     path_buf+1,x
        inc     path_buf
        ldy     #0
        lda     ($06),y
        tay
        clc
        adc     path_buf
        cmp     #'A'
        bcc     L5F2F
        return  #$FF

L5F2F:  pha
        tax
L5F31:  lda     ($06),y
        sta     path_buf,x
        dey
        dex
        cpx     path_buf
        bne     L5F31
        pla
        sta     path_buf
        lda     #$FF
        sta     selected_index
        return  #$00

;;; ============================================================

L5F49:  ldx     path_buf
        cpx     #$00
        beq     L5F5A
        dec     path_buf
        lda     path_buf,x
        cmp     #'/'
        bne     L5F49
L5F5A:  rts

;;; ============================================================

L5F5B:  jsr     L5ECB
        lda     #$00
        sta     L6067
        sta     L6068
        sta     L50A9
        lda     #$01
        sta     L6069
        copy16  $1423, L606A
        lda     $1425
        and     #$7F
        sta     num_file_names
        bne     L5F87
        jmp     L6012

L5F87:  copy16  #$142B, $06
L5F8F:  addr_call_indirect main::adjust_fileentry_case, $06

        ldy     #$00
        lda     ($06),y
        and     #NAME_LENGTH_MASK
        bne     L5F9A
        jmp     L6007

L5F9A:  ldx     L6067
        txa
        sta     file_list_index,x
        ldy     #$00
        lda     ($06),y
        and     #STORAGE_TYPE_MASK
        cmp     #ST_LINKED_DIRECTORY << 4
        beq     L5FB6
        bit     L50A8
        bpl     L5FC1
        inc     L6068
        jmp     L6007

L5FB6:  lda     file_list_index,x
        ora     #$80
        sta     file_list_index,x
        inc     L50A9
L5FC1:  ldy     #$00
        lda     ($06),y
        and     #$0F
        sta     ($06),y
        copy16  #file_names, $08
        lda     #$00
        sta     L606C
        lda     L6067
        asl     a
        rol     L606C
        asl     a
        rol     L606C
        asl     a
        rol     L606C
        asl     a
        rol     L606C
        clc
        adc     $08
        sta     $08
        lda     L606C
        adc     $09
        sta     $09
        ldy     #$00
        lda     ($06),y
        tay
L5FFA:  lda     ($06),y
        sta     ($08),y
        dey
        bpl     L5FFA
        inc     L6067
        inc     L6068
L6007:  inc     L6069
        lda     L6068
        cmp     num_file_names
        bne     L6035
L6012:  yax_call MLI_RELAY, CLOSE, close_params
        bit     L50A8
        bpl     L6026
        lda     L50A9
        sta     num_file_names
L6026:  jsr     L62DE
        jsr     L64E2
        lda     L5F0C
        bpl     L6033
        sec
        rts

L6033:  clc
        rts

L6035:  lda     L6069
        cmp     L606B
        beq     L604E
        add16_8 $06, L606A, $06
        jmp     L5F8F

L604E:  yax_call MLI_RELAY, READ, read_params
        copy16  #$1404, $06
        lda     #$00
        sta     L6069
        jmp     L5F8F

L6067:  .byte   0
L6068:  .byte   0
L6069:  .byte   0
L606A:  .byte   0
L606B:  .byte   0
L606C:  .byte   0

;;; ============================================================

.proc draw_list_entries
        lda     winfo_entrydlg_file_picker
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, winfo_entrydlg_file_picker::cliprect
        lda     #$10
        sta     picker_entry_pos
        lda     #$08
        sta     picker_entry_pos+2
        lda     #$00
        sta     picker_entry_pos+3
        sta     L6128
L608E:  lda     L6128
        cmp     num_file_names
        bne     L60A9
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

L60A9:  MGTK_RELAY_CALL MGTK::MoveTo, picker_entry_pos
        ldx     L6128
        lda     file_list_index,x
        and     #$7F
        ldx     #$00
        stx     L6127
        asl     a
        rol     L6127
        asl     a
        rol     L6127
        asl     a
        rol     L6127
        asl     a
        rol     L6127
        clc
        adc     #$00
        tay
        lda     L6127
        adc     #$18
        tax
        tya
        jsr     draw_string
        ldx     L6128
        lda     file_list_index,x
        bpl     L60FF
        lda     #$01
        sta     picker_entry_pos
        MGTK_RELAY_CALL MGTK::MoveTo, picker_entry_pos
        addr_call draw_string, str_folder
        lda     #$10
        sta     picker_entry_pos
L60FF:  lda     L6128
        cmp     selected_index
        bne     L6110
        jsr     L6274
        lda     winfo_entrydlg_file_picker
        jsr     set_port_for_window
L6110:  inc     L6128
        add16   picker_entry_pos+2, #8, picker_entry_pos+2
        jmp     L608E

L6127:  .byte   0
L6128:  .byte   0
.endproc

        PAD_TO $6161            ; Maintain previous addresses

;;; ============================================================

L6161:  lda     #$00

.proc L6163
        sta     L61B0
        lda     num_file_names
        cmp     #$0A
        bcs     L6181
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_which_ctl
        lda     #MGTK::activatectl_deactivate
        sta     activatectl_activate
        MGTK_RELAY_CALL MGTK::ActivateCtl, activatectl_params
        rts

L6181:  lda     num_file_names
        sta     winfo_entrydlg_file_picker::vthumbmax
        .assert MGTK::Ctl::vertical_scroll_bar = MGTK::activatectl_activate, error, "need to match"
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_which_ctl
        sta     activatectl_activate
        MGTK_RELAY_CALL MGTK::ActivateCtl, activatectl_params
        lda     L61B0
        sta     updatethumb_thumbpos
        jsr     scroll_clip_rect
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        rts

L61B0:  .byte   0
.endproc

;;; ============================================================

.proc L61B1
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D9C8
        copy16  #path_buf, $06
        ldy     #$00
        lda     ($06),y
        sta     L6226
        iny
L61D0:  iny
        lda     ($06),y
        cmp     #'/'
        beq     L61DE
        cpy     L6226
        bne     L61D0
        beq     L61E2
L61DE:  dey
        sty     L6226
L61E2:  ldy     #$00
        ldx     #$00
L61E6:  inx
        iny
        lda     ($06),y
        sta     $0220,x
        cpy     L6226
        bne     L61E6
        stx     $0220
        MGTK_RELAY_CALL MGTK::MoveTo, disk_label_pos
        addr_call draw_string, disk_label
        addr_call draw_string, $0220
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

L6226:  .byte   0
.endproc

;;; ============================================================

.proc scroll_clip_rect
        sta     L6273
        clc
        adc     #$09
        cmp     num_file_names
        beq     L6234
        bcs     L623A
L6234:  lda     L6273
        jmp     L624A

L623A:  lda     num_file_names
        cmp     #$0A
        bcs     L6247
        lda     L6273
        jmp     L624A

L6247:  sec
        sbc     #$09
L624A:  ldx     #$00
        stx     L6273
        asl     a
        rol     L6273
        asl     a
        rol     L6273
        asl     a
        rol     L6273
        sta     winfo_entrydlg_file_picker::cliprect+2
        ldx     L6273
        stx     winfo_entrydlg_file_picker::cliprect+3
        clc
        adc     #70
        sta     winfo_entrydlg_file_picker::cliprect+6
        lda     L6273
        adc     #0
        sta     winfo_entrydlg_file_picker::cliprect+7
        rts

L6273:  .byte   0
.endproc

;;; ============================================================

.proc L6274
        ldx     #0
        stx     L62C7
        asl     a
        rol     L62C7
        asl     a
        rol     L62C7
        asl     a
        rol     L62C7
        sta     rect_D90F+2
        ldx     L62C7
        stx     rect_D90F+3
        clc
        adc     #7
        sta     rect_D90F+6
        lda     L62C7
        adc     #0
        sta     rect_D90F+7
        lda     winfo_entrydlg_file_picker
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D90F
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

L62C7:  .byte   0
.endproc

;;; ============================================================

.proc set_port_for_window
        sta     getwinport_params2::window_id
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params2
        MGTK_RELAY_CALL MGTK::SetPort, grafport2
        rts
.endproc

;;; ============================================================

.proc L62DE
        lda     #'Z'
        ldx     #15
:       sta     L63C2,x
        dex
        bpl     :-

        lda     #$00
        sta     L63BF
        sta     L63BE
L62F0:  lda     L63BF
        cmp     num_file_names
        bne     L62FB
        jmp     L6377

L62FB:  lda     L63BE
        jsr     L6451
        ldy     #$00
        lda     ($06),y
        bmi     L633D
        and     #$0F
        sta     L63C1
        ldy     #$01
L630E:  lda     ($06),y
        cmp     L63C1,y
        beq     L631A
        bcs     L633D
        jmp     L6322

L631A:  iny
        cpy     #$10
        bne     L630E
        jmp     L633D

L6322:  lda     L63BE
        sta     L63C0
        ldx     #$0F
        lda     #' '
L632C:  sta     L63C2,x
        dex
        bpl     L632C
        ldy     L63C1
L6335:  lda     ($06),y
        sta     L63C1,y
        dey
        bne     L6335
L633D:  inc     L63BE
        lda     L63BE
        cmp     num_file_names
        beq     L634B
        jmp     L62FB

L634B:  lda     L63C0
        jsr     L6451
        ldy     #$00
        lda     ($06),y
        ora     #$80
        sta     ($06),y

        lda     #'Z'
        ldx     #15
:       sta     L63C2,x
        dex
        bpl     :-

        ldx     L63BF
        lda     L63C0
        sta     L63D2,x
        lda     #$00
        sta     L63BE
        inc     L63BF
        jmp     L62F0

L6377:  ldx     num_file_names
        dex
        stx     L63BF
L637E:  lda     L63BF
        bpl     L63AD
        ldx     num_file_names
        beq     L63AC
        dex
L6389:  lda     L63D2,x
        tay
        lda     file_list_index,y
        bpl     L639A
        lda     L63D2,x
        ora     #$80
        sta     L63D2,x
L639A:  dex
        bpl     L6389
        ldx     num_file_names
        beq     L63AC
        dex
L63A3:  lda     L63D2,x
        sta     file_list_index,x
        dex
        bpl     L63A3
L63AC:  rts

L63AD:  jsr     L6451
        ldy     #$00
        lda     ($06),y
        and     #$7F
        sta     ($06),y
        dec     L63BF
        jmp     L637E

L63BE:  .byte   0
L63BF:  .byte   0
L63C0:  .byte   0
L63C1:  .byte   0
L63C2:  .res 16, 0
L63D2:  .res 127, 0
L6451:  ldx     #$00
        stx     $06
        ldx     #$18
        stx     $07
        ldx     #$00
        stx     L647B
        asl     a
        rol     L647B
        asl     a
        rol     L647B
        asl     a
        rol     L647B
        asl     a
        rol     L647B
        clc
        adc     $06
        sta     $06
        lda     L647B
        adc     $07
        sta     $07
        rts

L647B:  .byte   0
.endproc

;;; ============================================================

.proc L647C
        stax    $06
        ldy     #$01
        lda     ($06),y
        cmp     #'/'
        bne     L64DE
        dey
        lda     ($06),y
        cmp     #$02
        bcc     L64DE
        tay
        lda     ($06),y
        cmp     #'/'
        beq     L64DE
        ldx     #$00
        stx     L64E1
L649B:  lda     ($06),y
        cmp     #'/'
        beq     L64AB
        inx
        cpx     #$10
        beq     L64DE
        dey
        bne     L649B
        beq     L64B3
L64AB:  inc     L64E1
        ldx     #$00
        dey
        bne     L649B
L64B3:  ldy     #$00
        lda     ($06),y
        tay
L64B8:  lda     ($06),y
        and     #CHAR_MASK
        cmp     #'.'
        beq     L64D8
        cmp     #'/'
        bcc     L64DE
        cmp     #'9'+1
        bcc     L64D8
        cmp     #'A'
        bcc     L64DE
        cmp     #'Z'+1
        bcc     L64D8
        cmp     #'a'
        bcc     L64DE
        cmp     #'z'+1
        bcs     L64DE
L64D8:  dey
        bne     L64B8
        return  #$00

L64DE:  return  #$FF

L64E1:  .byte   0
.endproc

;;; ============================================================

.proc L64E2
        lda     num_file_names
        bne     L64E8
L64E7:  rts

L64E8:  lda     #$00
        sta     L6515
        copy16  #file_names, $06
L64F5:  lda     L6515
        cmp     num_file_names
        beq     L64E7
        inc     L6515
        lda     $06
        clc
        adc     #$10
        sta     $06
        bcc     L64F5
        inc     $07
        jmp     L64F5

L6515:  .byte   0
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
L651F:  lda     ($06),y
        sta     L6576,y
        dey
        bpl     L651F
        lda     #$00
        sta     L6575
        copy16  #file_names, $06
L6534:  lda     L6575
        cmp     num_file_names
        beq     L6564
        ldy     #$00
        lda     ($06),y
        cmp     L6576
        bne     L6553
        tay
L6546:  lda     ($06),y
        cmp     L6576,y
        bne     L6553
        dey
        bne     L6546
        jmp     L6567

L6553:  inc     L6575
        lda     $06
        clc
        adc     #$10
        sta     $06
        bcc     L6534
        inc     $07
        jmp     L6534

L6564:  return  #$FF

L6567:  ldx     num_file_names
L656D:  dex
        lda     file_list_index,x
        and     #$7F
        cmp     L6575
        bne     L656D
        txa
        rts

L6575:  .byte   0
L6576:  .res 16, 0
.endproc

;;; ============================================================

.proc L6586
        bpl     L658B
L6588:  return  #$00

L658B:  cmp     #$09
        bcc     L6588
        sec
        sbc     #$08
        rts
.endproc

;;; ============================================================

.proc blink_f1_ip
        ptr := $06

        lda     winfo_entrydlg
        jsr     set_port_for_window
        jsr     calc_path_buf0_input1_endpos
        stax    $06
        copy16  common_input1_textpos+2, $08
        MGTK_RELAY_CALL MGTK::MoveTo, ptr
        bit     prompt_ip_flag
        bpl     bg2

        MGTK_RELAY_CALL MGTK::SetTextBG, textbg1
        copy    #$00, prompt_ip_flag
        beq     :+

bg2:    MGTK_RELAY_CALL MGTK::SetTextBG, textbg2
        copy    #$FF, prompt_ip_flag

:       copy16  #str_insertion_point+1, ptr
        lda     str_insertion_point
        sta     $08
        MGTK_RELAY_CALL MGTK::DrawText, ptr
        jsr     L56E3
        rts
.endproc

;;; ============================================================

.proc blink_f2_ip
        ptr := $06

        lda     winfo_entrydlg
        jsr     set_port_for_window
        jsr     calc_path_buf1_input2_endpos
        stax    $06
        copy16  common_input2_textpos+2, $08
        MGTK_RELAY_CALL MGTK::MoveTo, ptr
        bit     prompt_ip_flag
        bpl     bg2

        MGTK_RELAY_CALL MGTK::SetTextBG, textbg1
        copy    #$00, prompt_ip_flag
        jmp     :+

bg2:    MGTK_RELAY_CALL MGTK::SetTextBG, textbg2
        copy    #$FF, prompt_ip_flag

:       copy16  #str_insertion_point+1, ptr
        lda     str_insertion_point
        sta     $08
        MGTK_RELAY_CALL MGTK::DrawText, ptr
        jsr     L56E3
        rts
.endproc

;;; ============================================================

.proc redraw_f1
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, common_input1_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, common_input1_rect
        MGTK_RELAY_CALL MGTK::MoveTo, common_input1_textpos
        lda     path_buf0
        beq     :+
        addr_call draw_string, path_buf0
:       addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        rts
.endproc

;;; ============================================================

.proc redraw_f2
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, common_input2_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, common_input2_rect
        MGTK_RELAY_CALL MGTK::MoveTo, common_input2_textpos
        lda     path_buf1
        beq     :+
        addr_call draw_string, path_buf1
:       addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        rts
.endproc

;;; ============================================================

.proc handle_f1_click
        lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, common_input1_rect
        cmp     #MGTK::inrect_inside
        beq     L6719
        bit     L5104
        bpl     L6718
        MGTK_RELAY_CALL MGTK::InRect, common_input2_rect
        cmp     #MGTK::inrect_inside
        bne     L6718
        jmp     jt_handle_ok

L6718:  rts

L6719:  jsr     calc_path_buf0_input1_endpos
        stax    $06
        cmp16   screentowindow_windowx, $06
        bcs     L672F
        jmp     L67C4

L672F:  jsr     calc_path_buf0_input1_endpos
        stax    L684D
        ldx     path_buf2
        inx
        lda     #' '
        sta     path_buf2,x
        inc     path_buf2
        copy16  #path_buf2, $06
        lda     path_buf2
        sta     $08
L6751:  MGTK_RELAY_CALL MGTK::TextWidth, $06
        add16   $09, L684D, $09
        cmp16   $09, screentowindow_windowx
        bcc     L6783
        dec     $08
        lda     $08
        cmp     #$01
        bne     L6751
        dec     path_buf2
        jmp     L6846

L6783:  lda     $08
        cmp     path_buf2
        bcc     L6790
        dec     path_buf2
        jmp     handle_f1_meta_right_key

L6790:  ldx     #$02
        ldy     path_buf0
        iny
L6796:  lda     path_buf2,x
        sta     path_buf0,y
        cpx     $08
        beq     L67A5
        iny
        inx
        jmp     L6796

L67A5:  sty     path_buf0
        ldy     #$02
        ldx     $08
        inx
L67AD:  lda     path_buf2,x
        sta     path_buf2,y
        cpx     path_buf2
        beq     L67BD
        iny
        inx
        jmp     L67AD

L67BD:  dey
        sty     path_buf2
        jmp     L6846

L67C4:  copy16  #path_buf0, $06
        lda     path_buf0
        sta     $08
L67D1:  MGTK_RELAY_CALL MGTK::TextWidth, $06
        add16   $09, common_input1_textpos, $09
        cmp16   $09, screentowindow_windowx
        bcc     L6800
        dec     $08
        lda     $08
        cmp     #$01
        bcs     L67D1
        jmp     handle_f1_meta_left_key

L6800:  inc     $08
        ldy     #$00
        ldx     $08
L6806:  cpx     path_buf0
        beq     L6816
        inx
        iny
        lda     path_buf0,x
        sta     split_buf+1,y
        jmp     L6806

L6816:  iny
        sty     split_buf
        ldx     #$01
        ldy     split_buf
L681F:  cpx     path_buf2
        beq     L682F
        inx
        iny
        lda     path_buf2,x
        sta     split_buf,y
        jmp     L681F

L682F:  sty     split_buf
        lda     str_insertion_point+1
        sta     split_buf+1
L6838:  lda     split_buf,y
        sta     path_buf2,y
        dey
        bpl     L6838
        lda     $08
        sta     path_buf0
L6846:  jsr     jt_redraw_input
        jsr     L6EA3
        rts

L684D:  .word   0
.endproc

;;; ============================================================

.proc handle_f2_click
        lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, common_input2_rect
        cmp     #MGTK::inrect_inside
        beq     L6890
        bit     L5104
        bpl     L688F
        MGTK_RELAY_CALL MGTK::InRect, common_input1_rect
        cmp     #MGTK::inrect_inside
        bne     L688F
        jmp     jt_handle_cancel

L688F:  rts

L6890:  jsr     calc_path_buf1_input2_endpos
        stax    $06
        cmp16   screentowindow_windowx, $06
        bcs     L68A6
        jmp     L693B

L68A6:  jsr     calc_path_buf1_input2_endpos
        stax    L69C4
        ldx     path_buf2
        inx
        lda     #' '
        sta     path_buf2,x
        inc     path_buf2
        copy16  #path_buf2, $06
        lda     path_buf2
        sta     $08
L68C8:  MGTK_RELAY_CALL MGTK::TextWidth, $06
        add16   $09, L69C4, $09
        cmp16   $09, screentowindow_windowx
        bcc     L68FA
        dec     $08
        lda     $08
        cmp     #$01
        bne     L68C8
        dec     path_buf2
        jmp     L69BD

L68FA:  lda     $08
        cmp     path_buf2
        bcc     L6907
        dec     path_buf2
        jmp     handle_f2_meta_right_key

L6907:  ldx     #$02
        ldy     path_buf1
        iny
L690D:  lda     path_buf2,x
        sta     path_buf1,y
        cpx     $08
        beq     L691C
        iny
        inx
        jmp     L690D

L691C:  sty     path_buf1
        ldy     #$02
        ldx     $08
        inx
L6924:  lda     path_buf2,x
        sta     path_buf2,y
        cpx     path_buf2
        beq     L6934
        iny
        inx
        jmp     L6924

L6934:  dey
        sty     path_buf2
        jmp     L69BD

L693B:  copy16  #path_buf1, $06
        lda     path_buf1
        sta     $08
L6948:  MGTK_RELAY_CALL MGTK::TextWidth, $06
        add16   $09, common_input2_textpos, $09
        cmp16   $09, screentowindow_windowx
        bcc     L6977
        dec     $08
        lda     $08
        cmp     #$01
        bcs     L6948
        jmp     handle_f2_meta_left_key

L6977:  inc     $08
        ldy     #$00
        ldx     $08
L697D:  cpx     path_buf1
        beq     L698D
        inx
        iny
        lda     path_buf1,x
        sta     split_buf+1,y
        jmp     L697D

L698D:  iny
        sty     split_buf
        ldx     #$01
        ldy     split_buf
L6996:  cpx     path_buf2
        beq     L69A6
        inx
        iny
        lda     path_buf2,x
        sta     split_buf,y
        jmp     L6996

L69A6:  sty     split_buf
        lda     str_insertion_point+1
        sta     split_buf+1
L69AF:  lda     split_buf,y
        sta     path_buf2,y
        dey
        bpl     L69AF
        lda     $08
        sta     path_buf1
L69BD:  jsr     jt_redraw_input
        jsr     L6E9F
        rts

L69C4:  .word   0
.endproc

;;; ============================================================

.proc handle_f1_other_key
        sta     L6A17
        lda     path_buf0
        clc
        adc     path_buf2
        cmp     #$3F
        bcc     L69D5
        rts

L69D5:  lda     L6A17
        ldx     path_buf0
        inx
        sta     path_buf0,x
        sta     str_1_char+1
        jsr     calc_path_buf0_input1_endpos
        inc     path_buf0
        stax    $06
        copy16  common_input1_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, str_1_char
        addr_call draw_string, path_buf2
        jsr     L6EA3
        rts

L6A17:  .byte   0
.endproc

;;; ============================================================

.proc handle_f1_delete_key
        lda     path_buf0
        bne     L6A1E
        rts

L6A1E:  dec     path_buf0
        jsr     calc_path_buf0_input1_endpos
        stax    $06
        copy16  common_input1_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6EA3
        rts
.endproc

;;; ============================================================

.proc handle_f1_left_key
        lda     path_buf0
        bne     L6A59
        rts

L6A59:  ldx     path_buf2
        cpx     #$01
        beq     L6A6B
L6A60:  lda     path_buf2,x
        sta     path_buf2+1,x
        dex
        cpx     #$01
        bne     L6A60
L6A6B:  ldx     path_buf0
        lda     path_buf0,x
        sta     path_buf2+2
        dec     path_buf0
        inc     path_buf2
        jsr     calc_path_buf0_input1_endpos
        stax    $06
        copy16  common_input1_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6EA3
        rts
.endproc

;;; ============================================================

.proc handle_f1_right_key
        lda     path_buf2
        cmp     #$02
        bcs     L6AB4
        rts

L6AB4:  ldx     path_buf0
        inx
        lda     path_buf2+2
        sta     path_buf0,x
        inc     path_buf0
        ldx     path_buf2
        cpx     #$03
        bcc     L6AD6
        ldx     #$02
L6ACA:  lda     path_buf2+1,x
        sta     path_buf2,x
        inx
        cpx     path_buf2
        bne     L6ACA
L6AD6:  dec     path_buf2
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, common_input1_textpos
        addr_call draw_string, path_buf0
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6EA3
        rts
.endproc

;;; ============================================================

.proc handle_f1_meta_left_key
        lda     path_buf0
        bne     L6B07
        rts

L6B07:  ldy     path_buf0
        lda     path_buf2
        cmp     #$02
        bcc     L6B20
        ldx     #$01
L6B13:  iny
        inx
        lda     path_buf2,x
        sta     path_buf0,y
        cpx     path_buf2
        bne     L6B13
L6B20:  sty     path_buf0
L6B23:  lda     path_buf0,y
        sta     path_buf2+1,y
        dey
        bne     L6B23
        ldx     path_buf0
        inx
        stx     path_buf2
        lda     #kGlyphInsertionPoint
        sta     path_buf2+1
        lda     #$00
        sta     path_buf0
        jsr     jt_redraw_input
        jsr     L6EA3
        rts
.endproc

;;; ============================================================

.proc handle_f1_meta_right_key
        lda     path_buf2
        cmp     #$02
        bcs     L6B4C
        rts

L6B4C:  ldx     #$01
        ldy     path_buf0
L6B51:  inx
        iny
        lda     path_buf2,x
        sta     path_buf0,y
        cpx     path_buf2
        bne     L6B51
        sty     path_buf0
        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        jsr     jt_redraw_input
        jsr     L6EA3
        rts
.endproc

;;; ============================================================

.proc handle_f2_other_key
        sta     L6BC3
        lda     path_buf1
        clc
        adc     path_buf2
        cmp     #$3F
        bcc     L6B81
        rts

L6B81:  lda     L6BC3
        ldx     path_buf1
        inx
        sta     path_buf1,x
        sta     str_1_char+1
        jsr     calc_path_buf1_input2_endpos
        inc     path_buf1
        stax    $06
        copy16  common_input2_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, str_1_char
        addr_call draw_string, path_buf2
        jsr     L6E9F
        rts

L6BC3:  .byte   0
.endproc

;;; ============================================================

.proc handle_f2_delete_key
        lda     path_buf1
        bne     L6BCA
        rts

L6BCA:  dec     path_buf1
        jsr     calc_path_buf1_input2_endpos
        stax    $06
        copy16  common_input2_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6E9F
        rts
.endproc

;;; ============================================================

.proc handle_f2_left_key
        lda     path_buf1
        bne     L6C05
        rts

L6C05:  ldx     path_buf2
        cpx     #$01
        beq     L6C17
L6C0C:  lda     path_buf2,x
        sta     path_buf2+1,x
        dex
        cpx     #$01
        bne     L6C0C
L6C17:  ldx     path_buf1
        lda     path_buf1,x
        sta     path_buf2+2
        dec     path_buf1
        inc     path_buf2
        jsr     calc_path_buf1_input2_endpos
        stax    $06
        copy16  common_input2_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6E9F
        rts
.endproc

;;; ============================================================

.proc handle_f2_right_key
        lda     path_buf2
        cmp     #$02
        bcs     L6C60
        rts

L6C60:  ldx     path_buf1
        inx
        lda     path_buf2+2
        sta     path_buf1,x
        inc     path_buf1
        ldx     path_buf2
        cpx     #$03
        bcc     L6C82
        ldx     #$02
L6C76:  lda     path_buf2+1,x
        sta     path_buf2,x
        inx
        cpx     path_buf2
        bne     L6C76
L6C82:  dec     path_buf2
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, common_input2_textpos
        addr_call draw_string, path_buf1
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6E9F
        rts
.endproc

;;; ============================================================

.proc handle_f2_meta_left_key
        lda     path_buf1
        bne     L6CB3
        rts

L6CB3:  ldy     path_buf1
        lda     path_buf2
        cmp     #$02
        bcc     L6CCC
        ldx     #$01
L6CBF:  iny
        inx
        lda     path_buf2,x
        sta     path_buf1,y
        cpx     path_buf2
        bne     L6CBF
L6CCC:  sty     path_buf1
L6CCF:  lda     path_buf1,y
        sta     path_buf2+1,y
        dey
        bne     L6CCF
        ldx     path_buf1
        inx
        stx     path_buf2
        lda     #kGlyphInsertionPoint
        sta     path_buf2+1
        lda     #$00
        sta     path_buf1
        jsr     jt_redraw_input
        jsr     L6E9F
        rts
.endproc

;;; ============================================================

.proc handle_f2_meta_right_key
        lda     path_buf2
        cmp     #$02
        bcs     L6CF8
        rts

L6CF8:  ldx     #$01
        ldy     path_buf1
L6CFD:  inx
        iny
        lda     path_buf2,x
        sta     path_buf1,y
        cpx     path_buf2
        bne     L6CFD
        sty     path_buf1
        copy    #1, path_buf2
        copy    #kGlyphInsertionPoint, path_buf2+1
        jsr     jt_redraw_input
        jsr     L6E9F
        rts
.endproc

;;; ============================================================

;;; Dynamically altered table of handlers for focused
;;; input field (e.g. source/destination filename, etc)
jump_table:
jt_handle_ok:                   jmp     0
jt_handle_cancel:               jmp     0
jt_blink_ip:                    jmp     0
jt_redraw_input:                jmp     0
jt_strip_path_segment:          jmp     0
jt_05:  jmp     0
jt_prep_path:                   jmp     0
jt_handle_other_key:            jmp     0
jt_handle_delete_key:           jmp     0
jt_handle_left_key:             jmp     0
jt_handle_right_key:            jmp     0
jt_handle_meta_left_key:        jmp     0
jt_handle_meta_right_key:       jmp     0
jt_handle_click:                jmp     0

;;; ============================================================

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

jt_handle_f1_tbd05:
        lda     #$00
        beq     L6DD6

jt_handle_f2_tbd05:
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

.proc calc_path_buf0_input1_endpos
        str       := $6
        str_data  := $6
        str_len   := $8
        str_width := $9

        lda     #0
        sta     str_width
        sta     str_width+1
        lda     path_buf0
        beq     :+

        sta     str_len
        copy16  #path_buf0+1, str_data
        MGTK_RELAY_CALL MGTK::TextWidth, str

:       lda     str_width
        clc
        adc     common_input1_textpos
        tay
        lda     str_width+1
        adc     common_input1_textpos+1
        tax
        tya
        rts
.endproc

;;; ============================================================

.proc calc_path_buf1_input2_endpos
        str       := $6
        str_data  := $6
        str_len   := $8
        str_width := $9

        lda     #0
        sta     str_width
        sta     str_width+1
        lda     path_buf1
        beq     :+

        sta     str_len
        copy16  #path_buf1+1, str_data
        MGTK_RELAY_CALL MGTK::TextWidth, str

:       lda     str_width
        clc
        adc     common_input2_textpos
        tay
        lda     str_width+1
        adc     common_input2_textpos+1
        tax
        tya
        rts
.endproc

;;; ============================================================

L6E9F:  lda     #$FF
        bmi     L6EA5
L6EA3:  lda     #$00


.proc L6EA5
        bmi     L6EB6
        ldx     path_buf0
L6EAA:  lda     path_buf0,x
        sta     split_buf,x
        dex
        bpl     L6EAA
        jmp     L6EC2

L6EB6:  ldx     path_buf1
L6EB9:  lda     path_buf1,x
        sta     split_buf,x
        dex
        bpl     L6EB9
L6EC2:  lda     selected_index
        sta     L6F3D
        bmi     L6EFB
        ldx     #$00
        stx     $06
        ldx     #$18
        stx     $07
        ldx     #$00
        stx     L6F3C
        tax
        lda     file_list_index,x
        and     #$7F
        asl     a
        rol     L6F3C
        asl     a
        rol     L6F3C
        asl     a
        rol     L6F3C
        asl     a
        rol     L6F3C
        clc
        adc     $06
        tay
        lda     L6F3C
        adc     $07
        tax
        tya
        jsr     L5F0D
L6EFB:  lda     split_buf
        cmp     path_buf
        bne     L6F26
        tax
L6F12:  lda     split_buf,x
        cmp     path_buf,x
        bne     L6F26
        dex
        bne     L6F12
        lda     #$00
        sta     LD8F0
        jsr     L6F2F
        rts

L6F26:  lda     #$FF
        sta     LD8F0
        jsr     L6F2F
        rts

L6F2F:  lda     L6F3D
        sta     selected_index
        bpl     L6F38
        rts

L6F38:  jsr     L5F49
        rts

L6F3C:  .byte   0
L6F3D:  .byte   0
.endproc

;;; ============================================================

        PAD_TO $7000

.endproc ; file_dialog

file_dialog_exec := file_dialog::exec