;;; ============================================================
;;; Run a Program File Picker Dialog - Overlay #1
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        RESOURCE_FILE "ovl_file_dialog.res"

        .org $A000

.scope file_dialog

;;; Map from index in file_names to list entry; high bit is
;;; set for directories.
file_list_index := $1780

num_file_names  := $177F

;;; Sequence of 16-byte records, filenames in current directory.
file_names      := $1800

;;; ============================================================

ep_init:
        jmp     init

ep_loop:
        jmp     event_loop

;;; ============================================================

pencopy:        .byte   MGTK::pencopy
penOR:          .byte   MGTK::penOR
penXOR:         .byte   MGTK::penXOR
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy
notpenOR:       .byte   MGTK::notpenOR
notpenXOR:      .byte   MGTK::notpenXOR
notpenBIC:      .byte   MGTK::notpenBIC

event_params := *
event_kind := event_params + 0
        ;; if kind is key_down
event_key := event_params + 1
event_modifiers := event_params + 2
        ;; if kind is no_event, button_down/up, drag, or apple_key:
event_coords := event_params + 1
event_xcoord := event_params + 1
event_ycoord := event_params + 3
        ;; if kind is update:
event_window_id := event_params + 1

activatectl_params := *
activatectl_which_ctl := activatectl_params + 0
activatectl_activate  := activatectl_params + 1

trackthumb_params := *
trackthumb_which_ctl := trackthumb_params + 0
trackthumb_mousex := trackthumb_params + 1
trackthumb_mousey := trackthumb_params + 3
trackthumb_thumbpos := trackthumb_params + 5
trackthumb_thumbmoved := trackthumb_params + 6
        .assert trackthumb_mousex = event_xcoord, error, "param mismatch"
        .assert trackthumb_mousey = event_ycoord, error, "param mismatch"

updatethumb_params := *
updatethumb_which_ctl := updatethumb_params
updatethumb_thumbpos := updatethumb_params + 1
updatethumb_stash := updatethumb_params + 5 ; not part of struct

screentowindow_params := *
screentowindow_window_id := screentowindow_params + 0
screentowindow_screenx := screentowindow_params + 1
screentowindow_screeny := screentowindow_params + 3
screentowindow_windowx := screentowindow_params + 5
screentowindow_windowy := screentowindow_params + 7
        .assert screentowindow_screenx = event_xcoord, error, "param mismatch"
        .assert screentowindow_screeny = event_ycoord, error, "param mismatch"

findwindow_params := * + 1    ; offset to x/y overlap event_params x/y
findwindow_mousex := findwindow_params + 0
findwindow_mousey := findwindow_params + 2
findwindow_which_area := findwindow_params + 4
findwindow_window_id := findwindow_params + 5
        .assert findwindow_mousex = event_xcoord, error, "param mismatch"
        .assert findwindow_mousey = event_ycoord, error, "param mismatch"

findcontrol_params := * + 1   ; offset to x/y overlap event_params x/y
findcontrol_mousex := findcontrol_params + 0
findcontrol_mousey := findcontrol_params + 2
findcontrol_which_ctl := findcontrol_params + 4
findcontrol_which_part := findcontrol_params + 5
        .assert findcontrol_mousex = event_xcoord, error, "param mismatch"
        .assert findcontrol_mousey = event_ycoord, error, "param mismatch"

;;; Union of preceding param blocks
        .res    10, 0

.params getwinport_params
window_id:     .byte   0
a_grafport:    .addr   grafport
.endparams

grafport:
        .tag    MGTK::GrafPort
grafport2:
        .tag    MGTK::GrafPort

double_click_counter_init:
        .byte   $FF

pointer_cursor:
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%0100000),PX(%0000000)
        .byte   PX(%0110000),PX(%0000000)
        .byte   PX(%0111000),PX(%0000000)
        .byte   PX(%0111100),PX(%0000000)
        .byte   PX(%0111110),PX(%0000000)
        .byte   PX(%0111111),PX(%0000000)
        .byte   PX(%0101100),PX(%0000000)
        .byte   PX(%0000110),PX(%0000000)
        .byte   PX(%0000110),PX(%0000000)
        .byte   PX(%0000011),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%1100000),PX(%0000000)
        .byte   PX(%1110000),PX(%0000000)
        .byte   PX(%1111000),PX(%0000000)
        .byte   PX(%1111100),PX(%0000000)
        .byte   PX(%1111110),PX(%0000000)
        .byte   PX(%1111111),PX(%0000000)
        .byte   PX(%1111111),PX(%1000000)
        .byte   PX(%1111111),PX(%0000000)
        .byte   PX(%0001111),PX(%0000000)
        .byte   PX(%0001111),PX(%0000000)
        .byte   PX(%0000111),PX(%1000000)
        .byte   PX(%0000111),PX(%1000000)
        .byte   1,1

ibeam_cursor:
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%0110001),PX(%1000000)
        .byte   PX(%0001010),PX(%0000000)
        .byte   PX(%0000100),PX(%0000000)
        .byte   PX(%0000100),PX(%0000000)
        .byte   PX(%0000100),PX(%0000000)
        .byte   PX(%0000100),PX(%0000000)
        .byte   PX(%0000100),PX(%0000000)
        .byte   PX(%0001010),PX(%0000000)
        .byte   PX(%0110001),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%0110001),PX(%1000000)
        .byte   PX(%1111011),PX(%1100000)
        .byte   PX(%0111111),PX(%1000000)
        .byte   PX(%0001110),PX(%0000000)
        .byte   PX(%0001110),PX(%0000000)
        .byte   PX(%0001110),PX(%0000000)
        .byte   PX(%0001110),PX(%0000000)
        .byte   PX(%0001110),PX(%0000000)
        .byte   PX(%0111111),PX(%1000000)
        .byte   PX(%1111011),PX(%1100000)
        .byte   PX(%0110001),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000)
        .byte   4, 5

;;; Text Input Field
LA0C8:  .res    68, 0

;;; String being edited:
buf_input_left:         .res    68, 0 ; left of IP
buf_input_right:        .res    68, 0 ; IP and right

.params winfo_dialog
        kWidth = 500
        kHeight = 153
window_id:
        .byte   $3E
        .byte   $01, $00
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

        .word   150, 50
        .word   500, 140
        .byte   $19,$00,$14
        .byte   $00
        .addr   MGTK::screen_mapbits
        .byte   MGTK::screen_mapwidth
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .word   kWidth, kHeight
        .res    8, $FF
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

        .byte   $01,$01
        .byte   $00
        .byte   $7F
        .addr   FONT
        .addr   0
.endparams


.params winfo_list
window_id:
        .byte   $3F
        .byte   $01,$00
        .byte   $00
        .byte   $00
vscroll:
        .byte   $C1,$00
        .byte   $00
vthumbmax:
        .byte   $03
vthumbpos:
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $64
        .byte   $00
        .byte   $46,$00
        .byte   $64
        .byte   $00
        .byte   $46,$00
        .byte   $35,$00
        .byte   $32
        .byte   $00
        .addr   MGTK::screen_mapbits
        .byte   MGTK::screen_mapwidth
        .byte   $00
maprect:
x1:     .word   0
y1:     .word   0
x2:     .word   125
y2:     .word   70
pattern:.res    8, $FF
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

        .byte   $01,$01
        .byte   $00
        .byte   $7F
        .addr   FONT
        .byte   $00
        .byte   $00
.endparams


        .byte   $00
        .byte   $00
prompt_ip_counter:
        .byte   1             ; immediately decremented to 0 and reset

        .byte   $00

prompt_ip_flag:
        .byte   $00
LA20D:
        .byte   $00
        .byte   $00

str_ip:
        PASCAL_STRING {kGlyphInsertionPoint} ; do not localize

LA211:
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00

str_1_char:
        PASCAL_STRING 0         ; do not localize

str_two_spaces:
        PASCAL_STRING "  "      ; do not localize

        DEFINE_POINT pt3, 0, 13

        DEFINE_RECT rect, 0, 0, 125, 0

        DEFINE_POINT pos, 2, 0

        .byte   0
        .byte   0

str_folder:
        PASCAL_STRING {kGlyphFolderLeft, kGlyphFolderRight} ; do not localize

selected_index:                 ; $FF if none
        .byte   0

        .byte   $00

        DEFINE_RECT_INSET rect_frame, 4, 2, winfo_dialog::kWidth, winfo_dialog::kHeight

        DEFINE_RECT rect0, 27, 16, 174, 26

        DEFINE_BUTTON change_drive, res_string_button_change_drive,       193, 30
        DEFINE_BUTTON open,         res_string_button_open,               193, 44
        DEFINE_BUTTON close,        res_string_button_close,              193, 58
        DEFINE_BUTTON cancel,       res_string_fd_button_cancel,  193, 73
        DEFINE_BUTTON ok,           res_string_fd_button_ok, 193, 89

;;; Dividing line
        DEFINE_POINT pt1, 323-8, 30
        DEFINE_POINT pt2, 323-8, 100

        DEFINE_POINT pos_disk, 28, 25
        DEFINE_POINT pos_input_label, 28, 112

        DEFINE_POINT pos_input2_label, 28, 135 ; Unused

textbg1:
        .byte   0
textbg2:
        .byte   $7F
str_disk:
        PASCAL_STRING res_string_disk

        ;; Frame
        DEFINE_RECT rect_input, 28, 113, 428, 124

        ;; Text bounds
        DEFINE_RECT rect_input_text, 30, 123, 28, 136

        .word   428, 147
        .word   30, 146

str_file_to_run:
        PASCAL_STRING res_string_label_file_to_run

;;; ============================================================

start:  jsr     open_window
        jsr     draw_window
        jsr     device_on_line
        jsr     LB118
        jsr     update_scrollbar
        jsr     update_disk_name
        jsr     draw_list_entries
        jsr     init_input
        jsr     prep_path
        jsr     redraw_input
        lda     #$FF
        sta     LA20D
        jmp     event_loop

;;; ============================================================

.proc init_input
        lda     #$00
        sta     buf_input_left
        sta     LA50E
        copy    #1, buf_input_right
        copy    #kGlyphInsertionPoint, buf_input_right+1
        rts
.endproc

;;; ============================================================

.proc draw_window
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        param_call draw_title_centered, app::str_run_a_program
        param_call draw_input_label, str_file_to_run
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, rect_input
        MGTK_CALL MGTK::InitPort, grafport2
        MGTK_CALL MGTK::SetPort, grafport2
        rts
.endproc

;;; ============================================================

.proc handle_ok
        param_call LB5F1, buf_input_left
        beq     :+
        rts

:       ldx     saved_stack
        txs
        ldy     #<buf_input_left
        ldx     #>buf_input_left
        sta     $07
        return  #$00

        .byte   0               ; Unused ???
.endproc

;;; ============================================================

.proc LA387
        MGTK_CALL MGTK::CloseWindow, winfo_list
        MGTK_CALL MGTK::CloseWindow, winfo_dialog
        lda     #$00
        sta     LA20D
        jsr     unset_ip_cursor
        ldx     saved_stack
        txs
        return  #$FF

.endproc

;;; ============================================================


        DEFINE_ON_LINE_PARAMS on_line_params, 0, buf_on_line

        io_buf := $1000
        dir_read_buf := $1400
        kDirReadSize = $200

        DEFINE_OPEN_PARAMS open_params, path_buf, io_buf
        DEFINE_READ_PARAMS read_params, dir_read_buf, kDirReadSize
        DEFINE_CLOSE_PARAMS close_params

buf_on_line:  .res    16, 0
device_index:  .byte   0        ; current drive, index in DEVLST
path_buf:  .res    128, 0
LA447:  .byte   0
LA448:  .byte   0

saved_stack:
        .byte   0

;;; ============================================================

init:   tsx
        stx     saved_stack
        jsr     set_cursor_pointer
        lda     #$00
        sta     device_index
        sta     LA447
        sta     prompt_ip_flag
        sta     LA211
        sta     cursor_ibeam_flag
        sta     LA47D
        sta     LA47F
        copy    SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter
        lda     #$FF
        sta     selected_index
        jmp     start

        .byte   0
        .byte   0
LA47D:  .byte   0
        .byte   0
LA47F:  .byte   0

;;; ============================================================

.proc event_loop
        bit     LA20D
        bpl     :+

        dec     prompt_ip_counter
        bne     :+
        jsr     blink_ip
        copy    SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter

:       MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     handle_button_down
        jmp     event_loop

:       cmp     #MGTK::EventKind::key_down
        bne     :+
        jsr     handle_key
        jmp     event_loop

:       jsr     check_mouse_moved
        bcc     event_loop

        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     :+
        jmp     event_loop
:       lda     findwindow_window_id
        cmp     winfo_dialog::window_id
        beq     l1
        jmp     event_loop

l1:     lda     winfo_dialog::window_id
        jsr     set_port_for_window
        lda     winfo_dialog::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect_input
        cmp     #MGTK::inrect_inside
        bne     l2
        jsr     set_cursor_ibeam
        jmp     l3

l2:     jsr     unset_ip_cursor
l3:     MGTK_CALL MGTK::InitPort, grafport2
        MGTK_CALL MGTK::SetPort, grafport2
        jmp     event_loop

.endproc

LA50E:  .byte   0

;;; ============================================================

.proc handle_button_down
        MGTK_CALL MGTK::FindWindow, findwindow_params
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
        cmp     winfo_dialog::window_id
        beq     :+
        jmp     handle_list_button_down

:       lda     winfo_dialog::window_id
        jsr     set_port_for_window
        lda     winfo_dialog::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx

        ;; Open ?
        MGTK_CALL MGTK::InRect, open_button_rect
        cmp     #MGTK::inrect_inside
        beq     LA554
        jmp     not_open

LA554:  bit     LA47F
        bmi     LA55E
        lda     selected_index
        bpl     LA561
LA55E:  jmp     set_up_ports

LA561:  tax
        lda     file_list_index,x
        bmi     LA56A
LA567:  jmp     set_up_ports

LA56A:  lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, open_button_rect
        jsr     event_loop_open_btn
        bmi     LA567
        jsr     LA8ED
        jmp     set_up_ports

not_open:
        ;; Change Drive ?
        MGTK_CALL MGTK::InRect, change_drive_button_rect
        cmp     #MGTK::inrect_inside
        beq     LA594
        jmp     not_change_drive

LA594:  bit     LA47F
        bmi     LA5AD
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, change_drive_button_rect
        jsr     event_loop_change_drive_btn
        bmi     LA5AD
        jsr     change_drive
LA5AD:  jmp     set_up_ports

not_change_drive:
        ;; Close ?
        MGTK_CALL MGTK::InRect, close_button_rect
        cmp     #MGTK::inrect_inside
        beq     LA5BD
        jmp     not_close

LA5BD:  bit     LA47F
        bmi     LA5D6
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, close_button_rect
        jsr     event_loop_close_btn
        bmi     LA5D6
        jsr     LA965
LA5D6:  jmp     set_up_ports

not_close:
        ;; OK ?
        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
        beq     LA5E6
        jmp     not_ok

LA5E6:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        jsr     event_loop_ok_btn
        bmi     LA5FD
        jsr     input_ip_to_end
        jsr     handle_ok
LA5FD:  jmp     set_up_ports

not_ok:
        ;; Cancel ?
        MGTK_CALL MGTK::InRect, cancel_button_rect
        cmp     #MGTK::inrect_inside
        beq     LA60D
        jmp     not_cancel

LA60D:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        jsr     event_loop_cancel_btn
        bmi     LA621
        jsr     LA387
LA621:  jmp     set_up_ports

not_cancel:
        ;; Input ?
        bit     LA47D
        bpl     LA62E
        jsr     click_handler_hook
        bmi     set_up_ports
LA62E:  jsr     check_input_click_and_move_ip
        rts

.proc set_up_ports
        MGTK_CALL MGTK::InitPort, grafport2
        MGTK_CALL MGTK::SetPort, grafport
        rts
.endproc

click_handler_hook:
        jsr     noop
        rts
.endproc

;;; ============================================================

.proc handle_list_button_down
        bit     LA47F
        bmi     rts1
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_which_ctl
        beq     LA662
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     rts1
        lda     winfo_list::vscroll
        and     #MGTK::Ctl::vertical_scroll_bar
        beq     rts1
        jmp     handle_vscroll_click

rts1:   rts

LA662:  lda     winfo_list::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        add16   screentowindow_windowy, winfo_list::y1, screentowindow_windowy
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
        lda     selected_index
        cmp     screentowindow_windowy
        beq     same
        jmp     different

        ;; --------------------------------------------------
        ;; Click on the previous entry

same:   jsr     app::DetectDoubleClick
        beq     open
        rts

open:   ldx     selected_index
        lda     file_list_index,x
        bmi     folder

        ;; File - select it.
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        jsr     handle_ok
        jmp     rts1

        ;; Folder - open it.
folder: and     #$7F
        pha
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, open_button_rect
        MGTK_CALL MGTK::PaintRect, open_button_rect
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
        jsr     LB0D6
        jsr     LB118
        jsr     update_scrollbar
        lda     #0
        jsr     scroll_clip_rect
        jsr     update_disk_name
        jsr     draw_list_entries
        MGTK_CALL MGTK::InitPort, grafport2
        MGTK_CALL MGTK::SetPort, grafport
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
        jsr     strip_path_segment_left_and_redraw
        lda     selected_index
        jsr     LB404
:       lda     screentowindow_windowy
        sta     selected_index
        bit     LA211
        bpl     :+
        jsr     prep_path
        jsr     redraw_input
:       lda     selected_index
        jsr     LB404
        jsr     list_selection_change

        jsr     app::DetectDoubleClick
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
        sta     trackthumb_which_ctl
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_thumbmoved
        bne     :+
        rts

:       lda     trackthumb_thumbpos
        sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_stash
        jsr     scroll_clip_rect
        jsr     draw_list_entries
        rts
.endproc

;;; ============================================================

        kLineDelta = 1
        kPageDelta = 9

.proc handle_page_up
        lda     winfo_list::vthumbpos
        sec
        sbc     #kPageDelta
        bpl     :+
        lda     #0
:       sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     scroll_clip_rect
        jsr     draw_list_entries
        rts
.endproc

;;; ============================================================

.proc handle_page_down
        lda     winfo_list::vthumbpos
        clc
        adc     #$09
        cmp     num_file_names
        beq     :+
        bcc     :+
        lda     num_file_names
:       sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     scroll_clip_rect
        jsr     draw_list_entries
        rts
.endproc

;;; ============================================================

.proc handle_line_up
        lda     winfo_list::vthumbpos
        bne     :+
        rts

:       sec
        sbc     #kLineDelta
        sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     scroll_clip_rect
        jsr     draw_list_entries
        jsr     check_arrow_repeat
        jmp     handle_line_up
.endproc

;;; ============================================================

.proc handle_line_down
        lda     winfo_list::vthumbpos
        cmp     winfo_list::vthumbmax
        bne     :+
        rts

:       clc
        adc     #kLineDelta
        sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     scroll_clip_rect
        jsr     draw_list_entries
        jsr     check_arrow_repeat
        jmp     handle_line_down
.endproc

;;; ============================================================

.proc check_arrow_repeat
        MGTK_CALL MGTK::PeekEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        beq     :+
        cmp     #MGTK::EventKind::drag
        beq     :+
        pla
        pla
        rts

:       MGTK_CALL MGTK::GetEvent, event_params
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_window_id
        cmp     winfo_list::window_id
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

:       MGTK_CALL MGTK::FindControl, findcontrol_params
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

.proc unset_ip_cursor
        bit     cursor_ibeam_flag
        bpl     :+
        jsr     set_cursor_pointer
        copy    #0, cursor_ibeam_flag
:       rts
.endproc

;;; ============================================================

.proc set_cursor_pointer
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetCursor, pointer_cursor
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

.proc set_cursor_ibeam
        bit     cursor_ibeam_flag
        bmi     :+
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetCursor, ibeam_cursor
        MGTK_CALL MGTK::ShowCursor
        copy    #$80, cursor_ibeam_flag
:       rts
.endproc

cursor_ibeam_flag:              ; high bit set when cursor is I-beam
        .byte   0

;;; ============================================================

.proc LA8ED
        ldx     selected_index
        lda     file_list_index,x
        and     #$7F
        pha
        bit     LA211
        bpl     :+
        jsr     prep_path
:       lda     #$00
        sta     l1
        lda     #<file_names
        sta     $08
        lda     #>file_names
        sta     $08+1
        pla
        asl     a
        rol     l1
        asl     a
        rol     l1
        asl     a
        rol     l1
        asl     a
        rol     l1
        clc
        adc     $08
        sta     $08
        lda     l1
        adc     $09
        sta     $09
        ldx     $09
        lda     $08
        jsr     LB0D6
        jsr     LB118
        jsr     update_scrollbar
        lda     #$00
        jsr     scroll_clip_rect
        jsr     update_disk_name
        jsr     draw_list_entries
        rts

l1:     .byte   0
.endproc

;;; ============================================================

.proc change_drive
        lda     #$FF
        sta     selected_index
        jsr     inc_device_num
        jsr     device_on_line
        jsr     LB118
        jsr     update_scrollbar
        lda     #$00
        jsr     scroll_clip_rect
        jsr     update_disk_name
        jsr     draw_list_entries
        jsr     prep_path
        jsr     redraw_input
        rts
.endproc

;;; ============================================================

.proc LA965
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

l3:     jsr     LB106
        lda     selected_index
        pha
        lda     #$FF
        sta     selected_index
        jsr     LB118
        jsr     update_scrollbar
        lda     #$00
        jsr     scroll_clip_rect
        jsr     update_disk_name
        jsr     draw_list_entries
        pla
        sta     selected_index
        bit     l7
        bmi     l4
        jsr     strip_path_segment_left_and_redraw
        lda     selected_index
        bmi     l5
        jsr     strip_path_segment_left_and_redraw
        jmp     l5

l4:     jsr     prep_path
        jsr     redraw_input
l5:     lda     #$FF
        sta     selected_index
l6:     rts

l7:     .byte   0
.endproc

;;; ============================================================

.proc LA9C9
        MGTK_CALL MGTK::InitPort, grafport2
        ldx     #$03
        lda     #$00
:       sta     grafport2,x
        sta     grafport2++MGTK::GrafPort::maprect,x
        dex
        bpl     :-
        copy16  #550, grafport2+MGTK::GrafPort::maprect+MGTK::Rect::x2
        copy16  #185, grafport2+MGTK::GrafPort::maprect+MGTK::Rect::y2
        MGTK_CALL MGTK::SetPort, grafport2
        rts
.endproc

;;; ============================================================

.proc event_loop_ok_btn
        lda     #$00
        sta     l4
l1:     MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     l2
        lda     winfo_dialog::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        lda     l4
        beq     toggle
        jmp     l1

:       lda     l4
        bne     toggle
        jmp     l1

toggle: MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        lda     l4
        clc
        adc     #$80
        sta     l4
        jmp     l1

l2:     lda     l4
        beq     l3
        return  #$FF

l3:     MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        return  #$00

l4:     .byte   0
.endproc

;;; ============================================================

.proc event_loop_cancel_btn
        lda     #$00
        sta     l6
l1:     MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     l4
        lda     winfo_dialog::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, cancel_button_rect
        cmp     #MGTK::inrect_inside
        beq     l2
        lda     l6
        beq     l3
        jmp     l1

l2:     lda     l6
        bne     l3
        jmp     l1

l3:     MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        lda     l6
        clc
        adc     #$80
        sta     l6
        jmp     l1

l4:     lda     l6
        beq     l5
        return  #$FF

l5:     MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        return  #$01

l6:     .byte   0
.endproc

;;; ============================================================

.proc event_loop_open_btn
        lda     #$00
        sta     l6
l1:     MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     l4
        lda     winfo_dialog::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, open_button_rect
        cmp     #MGTK::inrect_inside
        beq     l2
        lda     l6
        beq     l3
        jmp     l1

l2:     lda     l6
        bne     l3
        jmp     l1

l3:     MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, open_button_rect
        lda     l6
        clc
        adc     #$80
        sta     l6
        jmp     l1

l4:     lda     l6
        beq     l5
        return  #$FF

l5:     MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, open_button_rect
        return  #$00

l6:     .byte   0
.endproc

;;; ============================================================

.proc event_loop_change_drive_btn
        lda     #$00
        sta     l6
l1:     MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     l4
        lda     winfo_dialog::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, change_drive_button_rect
        cmp     #MGTK::inrect_inside
        beq     l2
        lda     l6
        beq     l3
        jmp     l1

l2:     lda     l6
        bne     l3
        jmp     l1

l3:     MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, change_drive_button_rect
        lda     l6
        clc
        adc     #$80
        sta     l6
        jmp     l1

l4:     lda     l6
        beq     l5
        return  #$FF

l5:     MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, change_drive_button_rect
        return  #$01

l6:     .byte   0
.endproc

;;; ============================================================

.proc event_loop_close_btn
        lda     #$00
        sta     l6
l1:     MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     l4
        lda     winfo_dialog::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, close_button_rect
        cmp     #MGTK::inrect_inside
        beq     l2
        lda     l6
        beq     l3
        jmp     l1

l2:     lda     l6
        bne     l3
        jmp     l1

l3:     MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, close_button_rect
        lda     l6
        clc
        adc     #$80
        sta     l6
        jmp     l1

l4:     lda     l6
        beq     l5
        return  #$FF

l5:     MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, close_button_rect
        return  #$00

l6:     .byte   0
.endproc

;;; ============================================================
;;; Key handler

.proc handle_key
        lda     event_modifiers
        beq     no_modifiers

        ;; With modifiers
        lda     event_key
        and     #CHAR_MASK

        cmp     #CHAR_LEFT
        bne     :+
        jmp     input_ip_to_start ; start of line

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     input_ip_to_end ; end of line

:       bit     LA47F
        bmi     not_arrow
        cmp     #CHAR_DOWN
        bne     :+
        jmp     scroll_list_bottom ; end of list

:       cmp     #CHAR_UP
        bne     not_arrow
        jmp     scroll_list_top ; start of list

not_arrow:
        cmp     #'0'
        bcc     :+
        cmp     #'9'+1
        bcs     :+
        jmp     key_meta_digit

:       bit     LA47F
        bmi     LACAA
        jmp     check_alpha

        ;; --------------------------------------------------
        ;; No modifiers

no_modifiers:
        lda     event_key
        and     #CHAR_MASK

        cmp     #CHAR_LEFT
        bne     :+
        jmp     input_ip_left

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     input_ip_right

:       cmp     #CHAR_RETURN
        bne     :+
        jmp     key_return

:       cmp     #CHAR_ESCAPE
        bne     :+
        jmp     key_escape

:       cmp     #CHAR_DELETE
        bne     :+
        jmp     key_delete

:       bit     LA47F
        bpl     :+
        jmp     finish

:       cmp     #CHAR_TAB
        bne     not_tab
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, change_drive_button_rect
        MGTK_CALL MGTK::PaintRect, change_drive_button_rect
        jsr     change_drive
LACAA:  jmp     exit

not_tab:
        cmp     #CHAR_CTRL_O    ; Open
        bne     not_ctrl_o
        lda     selected_index
        bmi     exit
        tax
        lda     file_list_index,x
        bmi     :+
        jmp     exit

:       lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, open_button_rect
        MGTK_CALL MGTK::PaintRect, open_button_rect
        jsr     LA8ED
        jmp     exit

not_ctrl_o:
        cmp     #CHAR_CTRL_C    ; Close
        bne     :+
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, close_button_rect
        MGTK_CALL MGTK::PaintRect, close_button_rect
        jsr     LA965
        jmp     exit

:       cmp     #CHAR_DOWN
        bne     :+
        jmp     key_down

:       cmp     #CHAR_UP
        bne     finish
        jmp     key_up

finish: jsr     input_insert_char
        rts

exit:   jsr     LA9C9
        rts
.endproc

;;; ============================================================

.proc key_return
        lda     selected_index
        bpl     LAD20
        bit     LA211
        bmi     LAD20
        rts
.endproc

;;; ============================================================

.proc LAD20
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        jsr     input_ip_to_end
        jsr     handle_ok
        jsr     LA9C9
        rts
.endproc

;;; ============================================================

.proc key_escape
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        jsr     LA387
        jsr     LA9C9
        rts
.endproc

;;; ============================================================

.proc key_delete
        jsr     input_delete_char
        rts
.endproc

;;; ============================================================

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

l2:     jsr     LB404
        jsr     strip_path_segment_left_and_redraw
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

l2:     jsr     LB404
        jsr     strip_path_segment_left_and_redraw
        dec     selected_index
        lda     selected_index
        jmp     update_list_selection

l3:     ldx     num_file_names
        dex
        txa
        jmp     update_list_selection
.endproc

;;; ============================================================

.proc check_alpha
        cmp     #'A'
        bcs     :+
rts1:   rts

:       cmp     #'Z'+1
        bcc     alpha
        cmp     #'a'
        bcc     rts1
        cmp     #'z'+1
        bcs     rts1
        and     #(CASE_MASK & $7F)

alpha:  jsr     LADDF
        bmi     rts1
        cmp     selected_index
        beq     rts1
        pha
        lda     selected_index
        bmi     LADDB
        jsr     LB404
        jsr     strip_path_segment_left_and_redraw
LADDB:  pla
        jmp     update_list_selection


.proc LADDF
        sta     LAE37
        lda     #$00
        sta     LAE35
LADE7:  lda     LAE35
        cmp     num_file_names
        beq     LAE06
        jsr     LAE0D
        ldy     #$01
        lda     ($06),y
        cmp     LAE37
        bcc     LAE00
        beq     LAE09
        jmp     LAE06

LAE00:  inc     LAE35
        jmp     LADE7

LAE06:  return  #$FF

LAE09:  return  LAE35
.endproc

.proc LAE0D
        tax
        lda     file_list_index,x
        and     #$7F
        ldx     #$00
        stx     LAE36
        asl     a
        rol     LAE36
        asl     a
        rol     LAE36
        asl     a
        rol     LAE36
        asl     a
        rol     LAE36
        clc
        adc     #<file_names
        sta     $06
        lda     LAE36
        adc     #>file_names
        sta     $07
        rts
.endproc

LAE35:  .byte   0
LAE36:  .byte   0
LAE37:  .byte   0

.endproc

;;; ============================================================

.proc scroll_list_top
        lda     num_file_names
        beq     l1
        lda     selected_index
        bmi     l2
        bne     :+
l1:     rts

:       jsr     LB404
        jsr     strip_path_segment_left_and_redraw
l2:     lda     #$00
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
        jsr     LB404
        jsr     strip_path_segment_left_and_redraw
l1:     ldx     num_file_names
        dex
        txa
        jmp     update_list_selection
.endproc

;;; ============================================================

.proc update_list_selection
        sta     selected_index
        jsr     list_selection_change

        lda     selected_index
        jsr     selection_second_col
        jsr     update_scrollbar2
        jsr     draw_list_entries

        copy    #1, buf_input_right
        copy    #' ', buf_input_right+1

        jsr     redraw_input
        rts
.endproc

;;; ============================================================

noop:   rts

;;; ============================================================

.proc open_window
        MGTK_CALL MGTK::OpenWindow, winfo_dialog
        MGTK_CALL MGTK::OpenWindow, winfo_list
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, rect_frame
        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::FrameRect, open_button_rect
        MGTK_CALL MGTK::FrameRect, close_button_rect
        MGTK_CALL MGTK::FrameRect, cancel_button_rect
        MGTK_CALL MGTK::FrameRect, change_drive_button_rect
        jsr     draw_ok_button_label
        jsr     draw_open_button_label
        jsr     draw_close_button_label
        jsr     draw_cancel_button_label
        jsr     draw_change_drive_button_label
        MGTK_CALL MGTK::MoveTo, pt1
        MGTK_CALL MGTK::LineTo, pt2
        jsr     LA9C9
        rts
.endproc

draw_ok_button_label:
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call draw_string, ok_button_label
        rts

draw_open_button_label:
        MGTK_CALL MGTK::MoveTo, open_button_pos
        param_call draw_string, open_button_label
        rts

draw_close_button_label:
        MGTK_CALL MGTK::MoveTo, close_button_pos
        param_call draw_string, close_button_label
        rts

draw_cancel_button_label:
        MGTK_CALL MGTK::MoveTo, cancel_button_pos
        param_call draw_string, cancel_button_label
        rts

draw_change_drive_button_label:
        MGTK_CALL MGTK::MoveTo, change_drive_button_pos
        param_call draw_string, change_drive_button_label
        rts

;;; ============================================================

.proc draw_string
        ptr := $06
        params := $06

        stax    ptr
        ldy     #$00
        lda     (ptr),y
        sta     $08
        inc16   params
        MGTK_CALL MGTK::DrawText, params
        rts
.endproc

;;; ============================================================

.proc draw_title_centered
        ptr := $06
        params := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     $08
        inc16   params
        MGTK_CALL MGTK::TextWidth, params
        lsr16   $09
        lda     #>winfo_dialog::kWidth
        sta     l1
        lda     #<winfo_dialog::kWidth
        lsr     l1
        ror     a
        sec
        sbc     $09
        sta     pt3::xcoord
        lda     l1
        sbc     $0A
        sta     pt3::xcoord+1
        MGTK_CALL MGTK::MoveTo, pt3
        MGTK_CALL MGTK::DrawText, params
        rts

l1:     .byte   0
.endproc

;;; ============================================================

.proc draw_input_label
        stax    $06
        MGTK_CALL MGTK::MoveTo, pos_input_label
        lda     $06
        ldx     $07
        jsr     draw_string
        rts
.endproc

;;; ============================================================

.proc device_on_line
        ;; Reverse order, so boot volume is first
retry:  lda     DEVCNT
        sec
        sbc     device_index
        tax
        lda     DEVLST,x

        and     #$F0
        sta     on_line_params::unit_num
        MLI_CALL ON_LINE, on_line_params
        lda     buf_on_line
        and     #NAME_LENGTH_MASK
        sta     buf_on_line
        bne     found
        jsr     inc_device_num
        jmp     retry

found:  param_call AdjustVolumeNameCase, buf_on_line
        lda     #0
        sta     path_buf
        param_call LB0D6, buf_on_line
        rts
.endproc

;;; ============================================================

.proc inc_device_num
        inc     device_index
        lda     device_index
        cmp     DEVCNT
        beq     :+
        bcc     :+
        lda     #0
        sta     device_index
:       rts
.endproc

;;; ============================================================

.proc LB095
        lda     #$00
        sta     LB0D5
        MLI_CALL OPEN, open_params
        beq     l1
        jsr     device_on_line
        lda     #$FF
        sta     selected_index
        lda     #$FF
        sta     LB0D5
        jmp     LB095

l1:     lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        beq     l2
        jsr     device_on_line
        lda     #$FF
        sta     selected_index
        jmp     LB095

l2:     rts
.endproc

LB0D5:  .byte   0

;;; ============================================================

.proc LB0D6
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

        pha
        tax
l1:     lda     ($06),y
        sta     path_buf,x
        dey
        dex
        cpx     path_buf
        bne     l1
        pla
        sta     path_buf
        lda     #$FF
        sta     selected_index
        rts
.endproc

;;; ============================================================

.proc LB106
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

.proc LB118
        jsr     LB095
        lda     #0
        sta     l10
        sta     l11
        sta     LA448
        lda     #1
        sta     l12
        copy16  dir_read_buf+$23, l13
        lda     dir_read_buf+$25
        and     #$7F
        sta     num_file_names
        bne     :+
        jmp     l6

:       copy16  #dir_read_buf+$2B, $06

l1:     param_call_indirect AdjustFileEntryCase, $06

        ldy     #0
        lda     ($06),y
        and     #NAME_LENGTH_MASK
        bne     l2
        jmp     l5

l2:     ldx     l10
        txa
        sta     file_list_index,x
        ldy     #0
        lda     ($06),y
        and     #STORAGE_TYPE_MASK
        cmp     #ST_LINKED_DIRECTORY << 4
        beq     l3
        bit     LA447
        bpl     l4
        inc     l11
        jmp     l5

l3:     lda     file_list_index,x
        ora     #$80
        sta     file_list_index,x
        inc     LA448
l4:     ldy     #$00
        lda     ($06),y
        and     #$0F
        sta     ($06),y
        copy16  #file_names, $08
        lda     #$00
        sta     l15
        lda     l10
        asl     a
        rol     l15
        asl     a
        rol     l15
        asl     a
        rol     l15
        asl     a
        rol     l15
        clc
        adc     $08
        sta     $08
        lda     l15
        adc     $09
        sta     $09
        ldy     #$00
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     ($08),y
        dey
        bpl     :-
        inc     l10
        inc     l11
l5:     inc     l12
        lda     l11
        cmp     num_file_names
        bne     l8
l6:     MLI_CALL CLOSE, close_params
        bit     LA447
        bpl     :+
        lda     LA448
        sta     num_file_names
:       jsr     sort_file_names
        jsr     LB65E
        lda     LB0D5
        bpl     l7
        sec
        rts

l7:     clc
        rts

l8:     lda     l12
        cmp     l14
        beq     l9
        lda     $06
        clc
        adc     l13
        sta     $06
        lda     $07
        adc     #$00
        sta     $07
        jmp     l1

l9:     MLI_CALL READ, read_params
        copy16  #dir_read_buf+$04, $06
        lda     #$00
        sta     l12
        jmp     l1

l10:    .byte   0
l11:    .byte   0
l12:    .byte   0
l13:    .byte   0
l14:    .byte   0
l15:    .byte   0
.endproc

;;; ============================================================

.proc draw_list_entries
        jsr     LA9C9

        lda     winfo_list::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::PaintRect, winfo_list::maprect
        lda     #16
        sta     pos::xcoord
        lda     #8
        sta     pos::ycoord
        lda     #0
        sta     pos::ycoord+1
        sta     l4

loop:   lda     l4
        cmp     num_file_names
        bne     :+
        jsr     LA9C9
        rts

:       MGTK_CALL MGTK::MoveTo, pos
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
        bpl     l1
        lda     #$01
        sta     pos
        MGTK_CALL MGTK::MoveTo, pos
        param_call draw_string, str_folder
        lda     #$10
        sta     pos
l1:     lda     l4
        cmp     selected_index
        bne     l2
        jsr     LB404
        lda     winfo_list::window_id
        jsr     set_port_for_window
l2:     inc     l4
        add16   pos::ycoord, #8, pos::ycoord
        jmp     loop

l3:     .byte   0
l4:     .byte   0
.endproc

;;; ============================================================

update_scrollbar:
        lda     #$00

.proc update_scrollbar2
        sta     l1
        lda     num_file_names
        cmp     #$0A
        bcs     :+
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_which_ctl
        copy    #MGTK::activatectl_deactivate, activatectl_activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts

:       lda     num_file_names
        sta     winfo_list::vthumbmax
        .assert MGTK::Ctl::vertical_scroll_bar = MGTK::activatectl_activate, error, "need to match"
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_which_ctl
        sta     activatectl_activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        lda     l1
        sta     updatethumb_thumbpos
        jsr     scroll_clip_rect
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        rts

l1:     .byte   0
.endproc

;;; ============================================================

.proc update_disk_name
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::PaintRect, rect0
        MGTK_CALL MGTK::SetPenMode, penXOR
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
        MGTK_CALL MGTK::MoveTo, pos_disk
        param_call draw_string, str_disk
        param_call draw_string, INVOKER_PREFIX
        jsr     LA9C9
        rts

l5:     .byte   0
.endproc

;;; ============================================================

.proc scroll_clip_rect
        sta     tmp
        clc
        adc     #kPageDelta
        cmp     num_file_names
        beq     l1
        bcs     l2
l1:     lda     tmp
        jmp     l4

l2:     lda     num_file_names
        cmp     #$0A
        bcs     l3
        lda     tmp
        jmp     l4

l3:     sec
        sbc     #kPageDelta
l4:     ldx     #$00
        stx     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        sta     winfo_list::y1
        ldx     tmp
        stx     winfo_list::y1+1
        clc
        adc     #70
        sta     winfo_list::y2
        lda     tmp
        adc     #0
        sta     winfo_list::y2+1
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

.proc LB404
        ldx     #$00
        stx     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        sta     rect::y1
        ldx     tmp
        stx     rect::y1+1
        clc
        adc     #$07
        sta     rect::y2
        lda     tmp
        adc     #$00
        sta     rect::y2+1
        lda     winfo_list::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect
        jsr     LA9C9
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

.proc set_port_for_window
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport
        rts
.endproc

;;; ============================================================
;;; Sorting

.proc sort_file_names
        lda     #$7F            ; beyond last possible name char
        ldx     #15
:       sta     l19,x
        dex
        bpl     :-
        lda     #$00
        sta     l16
        sta     l15
l1:     lda     l16
        cmp     num_file_names
        bne     l2
        jmp     l9

l2:     lda     l15
        jsr     LB5C6
        ldy     #$00
        lda     ($06),y
        bmi     l7
        and     #$0F
        sta     l18
        ldy     #$01
l3:     lda     ($06),y
        cmp     l18,y
        beq     l4
        bcs     l7
        jmp     l5

l4:     iny
        cpy     #$10
        bne     l3
        jmp     l7

l5:     lda     l15
        sta     l17
        ldx     #$0F
        lda     #$20
:       sta     l19,x
        dex
        bpl     :-
        ldy     l18
l6:     lda     ($06),y
        sta     l18,y
        dey
        bne     l6
l7:     inc     l15
        lda     l15
        cmp     num_file_names
        beq     l8
        jmp     l2

l8:     lda     l17
        jsr     LB5C6
        ldy     #$00
        lda     ($06),y
        ora     #$80
        sta     ($06),y
        lda     #$7F            ; beyond last possible name char
        ldx     #$0F
:       sta     l19,x
        dex
        bpl     :-
        ldx     l16
        lda     l17
        sta     l20,x
        lda     #$00
        sta     l15
        inc     l16
        jmp     l1

l9:     ldx     num_file_names
        dex
        stx     l16
l10:    lda     l16
        bpl     l14
        ldx     num_file_names
        beq     l13
        dex
l11:    lda     l20,x
        tay
        lda     file_list_index,y
        bpl     l12
        lda     l20,x
        ora     #$80
        sta     l20,x
l12:    dex
        bpl     l11
        ldx     num_file_names
        beq     l13
        dex
:       lda     l20,x
        sta     file_list_index,x
        dex
        bpl     :-
l13:    rts

l14:    jsr     LB5C6
        ldy     #$00
        lda     ($06),y
        and     #$7F
        sta     ($06),y
        dec     l16
        jmp     l10

l15:    .byte   0
l16:    .byte   0
l17:    .byte   0
l18:    .byte   0
l19:    .res    16, 0
l20:    .res    127, 0

;;; --------------------------------------------------

.proc LB5C6
        ptr := $06

        ldx     #<file_names
        stx     ptr
        ldx     #>file_names
        stx     ptr+1
        ldx     #$00
        stx     l21
        asl     a
        rol     l21
        asl     a
        rol     l21
        asl     a
        rol     l21
        asl     a
        rol     l21
        clc
        adc     ptr
        sta     ptr
        lda     l21
        adc     ptr+1
        sta     ptr+1
        rts

l21:    .byte   0
.endproc
.endproc

;;; ============================================================

.proc LB5F1
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
l3:     lda     l7
        cmp     #$02
        bcc     l6
        ldy     #$00
        lda     (ptr),y
        tay
l4:     lda     (ptr),y
        and     #$7F
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

.proc LB65E
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

.proc LB629                     ; Unreferenced ???
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     l8,y
        dey
        bpl     :-
        lda     #$00
        sta     l7
        copy16  #file_names, $06
l1:     lda     l7
        cmp     num_file_names
        beq     l4
        ldy     #$00
        lda     ($06),y
        cmp     l8
        bne     l3
        tay
l2:     lda     ($06),y
        cmp     l8,y
        bne     l3
        dey
        bne     l2
        jmp     l5

l3:     inc     l7
        lda     $06
        clc
        adc     #$10
        sta     $06
        bcc     l1
        inc     $07
        jmp     l1

l4:     return  #$FF

l5:     ldx     num_file_names
        lda     l7
l6:     dex
        cmp     file_list_index,x
        bne     l6
        txa
        rts

l7:     .byte   0
l8:     .res    16, 0
.endproc

;;; ============================================================
;;; Input: A = Selection (0-15, or $FF)
;;; Output: 0 if no selection or in first col, else mod 8

.proc selection_second_col
        bpl     has_sel
:       return  #0

has_sel:
        cmp     #9
        bcc     :-
        sec
        sbc     #8
        rts
.endproc

;;; ============================================================

.proc blink_ip
        pt := $06

        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        jsr     calc_input_endpos
        stax    pt
        copy16  rect_input_text::y1, pt+2
        MGTK_CALL MGTK::MoveTo, pt
        bit     prompt_ip_flag
        bpl     bg2

        MGTK_CALL MGTK::SetTextBG, textbg1
        copy    #$00, prompt_ip_flag
        beq     :+

bg2:    MGTK_CALL MGTK::SetTextBG, textbg2
        copy    #$FF, prompt_ip_flag

        params := $06

:       copy16  #str_ip+1, params
        lda     str_ip
        sta     params+2
        MGTK_CALL MGTK::DrawText, params
        jsr     LA9C9
        rts
.endproc

;;; ============================================================

.proc redraw_input
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::PaintRect, rect_input
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, rect_input
        MGTK_CALL MGTK::MoveTo, rect_input_text
        lda     buf_input_left
        beq     :+
        param_call draw_string, buf_input_left
:       param_call draw_string, buf_input_right
        param_call draw_string, str_two_spaces
        rts
.endproc

;;; ============================================================

.proc check_input_click_and_move_ip

        lda     winfo_dialog::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect_input
        cmp     #MGTK::inrect_inside
        beq     :+
        rts

:       jsr     calc_input_endpos
        stax    $06
        cmp16   screentowindow_windowx, $06
        bcs     l1
        jmp     l8

l1:     jsr     calc_input_endpos
        stax    l16
        ldx     buf_input_right
        inx
        lda     #$20
        sta     buf_input_right,x
        inc     buf_input_right
        copy16  #buf_input_right, $06
        lda     buf_input_right
        sta     $08
@loop:  MGTK_CALL MGTK::TextWidth, $06
        add16   $09, l16, $09
        cmp16   $09, screentowindow_windowx
        bcc     l2
        dec     $08
        lda     $08
        cmp     #$01
        bne     @loop
        dec     buf_input_right
        jmp     l15

l2:     lda     $08
        cmp     buf_input_right
        bcc     l3
        dec     buf_input_right
        jmp     input_ip_to_end

l3:     ldx     #$02
        ldy     buf_input_left
        iny
l4:     lda     buf_input_right,x
        sta     buf_input_left,y
        cpx     $08
        beq     l5
        iny
        inx
        jmp     l4

l5:     sty     buf_input_left
        ldy     #$02
        ldx     $08
        inx
l6:     lda     buf_input_right,x
        sta     buf_input_right,y
        cpx     buf_input_right
        beq     l7
        iny
        inx
        jmp     l6

l7:     dey
        sty     buf_input_right
        jmp     l15

l8:     copy16  #buf_input_left, $06
        lda     buf_input_left
        sta     $08
l9:     MGTK_CALL MGTK::TextWidth, $06
        add16   $09, rect_input_text::x1, $09
        cmp16   $09, screentowindow_windowx
        bcc     l10
        dec     $08
        lda     $08
        cmp     #$01
        bcs     l9
        jmp     input_ip_to_start

l10:    inc     $08
        ldy     #$00
        ldx     $08
l11:    cpx     buf_input_left
        beq     l12
        inx
        iny
        lda     buf_input_left,x
        sta     LA0C8+1,y
        jmp     l11

l12:    iny
        sty     LA0C8
        ldx     #$01
        ldy     LA0C8
l13:    cpx     buf_input_right
        beq     l14
        inx
        iny
        lda     buf_input_right,x
        sta     LA0C8,y
        jmp     l13

l14:    sty     LA0C8
        lda     str_ip+1
        sta     LA0C8+1
:       lda     LA0C8,y
        sta     buf_input_right,y
        dey
        bpl     :-
        lda     $08
        sta     buf_input_left
l15:    jsr     redraw_input
        jsr     LBB5B
        rts

l16:    .word   0
.endproc

;;; ============================================================

.proc input_insert_char
        sta     tmp
        lda     buf_input_left
        clc
        adc     buf_input_right
        cmp     #$41            ; ???
        bcc     continue
        rts

tmp:    .byte   0

continue:
        lda     tmp
        ldx     buf_input_left
        inx
        sta     buf_input_left,x
        sta     str_1_char+1
        jsr     calc_input_endpos
        inc     buf_input_left
        stax    $06
        copy16  rect_input_text::y1, $08
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::MoveTo, $06
        param_call draw_string, str_1_char
        param_call draw_string, buf_input_right
        jsr     LBB5B
        rts
.endproc

;;; ============================================================

.proc input_delete_char
        lda     buf_input_left
        bne     :+
        rts

:       dec     buf_input_left
        jsr     calc_input_endpos
        stax    $06
        copy16  rect_input_text::y1, $08
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::MoveTo, $06
        param_call draw_string, buf_input_right
        param_call draw_string, str_two_spaces
        jsr     LBB5B
        rts
.endproc

;;; ============================================================

.proc input_ip_left
        lda     buf_input_left
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

skip:   ldx     buf_input_left
        lda     buf_input_left,x
        sta     buf_input_right+2
        dec     buf_input_left
        inc     buf_input_right
        jsr     calc_input_endpos
        stax    $06
        copy16  rect_input_text::y1, $08
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::MoveTo, $06
        param_call draw_string, buf_input_right
        param_call draw_string, str_two_spaces
        jsr     LBB5B
        rts
.endproc

;;; ============================================================

.proc input_ip_right
        lda     buf_input_right
        cmp     #2
        bcs     :+
        rts

:       ldx     buf_input_left
        inx
        lda     buf_input_right+2
        sta     buf_input_left,x
        inc     buf_input_left
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
        lda     winfo_dialog::window_id
        jsr     set_port_for_window
        MGTK_CALL MGTK::MoveTo, rect_input_text
        param_call draw_string, buf_input_left
        param_call draw_string, buf_input_right
        param_call draw_string, str_two_spaces
        jsr     LBB5B
        rts
.endproc

;;; ============================================================

.proc input_ip_to_start
        lda     buf_input_left
        bne     :+
        rts

:       ldy     buf_input_left
        lda     buf_input_right
        cmp     #2
        bcc     skip

        ldx     #1
:       iny
        inx
        lda     buf_input_right,x
        sta     buf_input_left,y
        cpx     buf_input_right
        bne     :-

skip:   sty     buf_input_left

:       lda     buf_input_left,y
        sta     buf_input_right+1,y
        dey
        bne     :-
        ldx     buf_input_left
        inx
        stx     buf_input_right
        copy    #kGlyphInsertionPoint, buf_input_right+1
        copy    #0, buf_input_left
        jsr     redraw_input
        jsr     LBB5B
        rts
.endproc

;;; ============================================================

.proc input_ip_to_end
        lda     buf_input_right
        cmp     #2
        bcs     :+
        rts

:       ldx     #1
        ldy     buf_input_left
@loop:  inx
        iny
        lda     buf_input_right,x
        sta     buf_input_left,y
        cpx     buf_input_right
        bne     @loop
        sty     buf_input_left
        copy    #1, buf_input_right
        copy    #kGlyphInsertionPoint, buf_input_right+1
        jsr     redraw_input
        jsr     LBB5B
        rts
.endproc

;;; ============================================================
;;; Input: A,X = string address

.proc append_segment_to_input
        ptr := $06

        stax    ptr

        ldx     buf_input_left
        lda     #'/'
        sta     buf_input_left+1,x
        inc     buf_input_left

        ldy     #0
        lda     (ptr),y
        tay
        clc
        adc     buf_input_left
        pha
        tax

:       lda     (ptr),y
        sta     buf_input_left,x
        dey
        dex
        cpx     buf_input_left
        bne     :-

        pla
        sta     buf_input_left
        rts
.endproc

;;; ============================================================
;;; Trim end of left segment to rightmost '/'

.proc strip_path_segment_left
:       ldx     buf_input_left
        cpx     #0
        beq     done
        dec     buf_input_left
        lda     buf_input_left,x
        cmp     #'/'
        bne     :-
done:   rts
.endproc

;;; ============================================================

.proc strip_path_segment_left_and_redraw
        jsr     strip_path_segment_left
        jsr     redraw_input
        rts
.endproc

;;; ============================================================

.proc list_selection_change
        ptr := $06

        copy16  #file_names, ptr
        ldx     selected_index
        lda     file_list_index,x
        and     #$7F

        ldx     #0
        stx     tmp

        asl     a               ; *= 16
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp

        clc
        adc     ptr
        tay
        lda     tmp
        adc     ptr+1
        tax
        tya
        jsr     append_segment_to_input
        jsr     redraw_input
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

.proc LBB09                     ; Unreferenced ???
        COPY_STRING path_buf, buf_input_left
        rts
.endproc

;;; ============================================================

.proc prep_path
        COPY_STRING path_buf, buf_input_left
        rts
.endproc

;;; ============================================================
;;; Output: A,X = coordinates of input string end

.proc calc_input_endpos
        PARAM_BLOCK params, $06
data:   .addr   0
length: .byte   0
width:  .word   0
        END_PARAM_BLOCK

        lda     #0
        sta     params::width
        sta     params::width+1
        lda     buf_input_left
        beq     :+
        sta     params::length
        copy16  #buf_input_left+1, params::data
        MGTK_CALL MGTK::TextWidth, params
:       lda     params::width
        clc
        adc     rect_input_text::x1
        tay
        lda     params::width+1
        adc     rect_input_text::x1+1
        tax
        tya
        rts
.endproc

;;; ============================================================

.proc LBB5B
        ldx     buf_input_left
:       lda     buf_input_left,x
        sta     LA0C8,x
        dex
        bpl     :-

        lda     selected_index
        sta     l7
        bmi     l1
        ldx     #<file_names
        stx     $06
        ldx     #>file_names
        stx     $07
        ldx     #0
        stx     l6
        tax
        lda     file_list_index,x
        and     #$7F
        asl     a
        rol     l6
        asl     a
        rol     l6
        asl     a
        rol     l6
        asl     a
        rol     l6
        clc
        adc     $06
        tay
        lda     l6
        adc     $07
        tax
        tya
        jsr     LB0D6

l1:     lda     LA0C8
        cmp     path_buf
        bne     l3
        tax
l2:     lda     LA0C8,x
        cmp     path_buf,x
        bne     l3
        dex
        bne     l2
        lda     #0
        sta     LA211
        jsr     l4
        rts

l3:     lda     #$FF
        sta     LA211
        jsr     l4
        rts

l4:     lda     l7
        sta     selected_index
        bpl     l5
        rts

l5:     jsr     LB106
        rts

l6:     .byte   0
l7:     .byte   0
.endproc

;;; ============================================================
;;; Determine if mouse moved
;;; Output: C=1 if mouse moved

.proc check_mouse_moved
        ldx     #.sizeof(MGTK::Point)-1
:       lda     event_coords,x
        cmp     coords,x
        bne     diff
        dex
        bpl     :-
        clc
        rts

diff:   COPY_STRUCT MGTK::Point, event_coords, coords
        sec
        rts

        DEFINE_POINT coords, 0, 0
.endproc

;;; ============================================================

        IO_BUFFER := $1C00
        .define LIB_MLI_CALL MLI_CALL
        .include "../lib/adjustfilecase.s"
        .undefine LIB_MLI_CALL

;;; ============================================================

.endscope

file_dialog_init   := file_dialog::ep_init
file_dialog_loop   := file_dialog::ep_loop

        PAD_TO $BF00
