;;; ============================================================
;;; Run a Program File Picker Dialog - Overlay #1
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        RESOURCE_FILE "ovl_file_dialog.res"

        .org OVERLAY_ADDR

.scope file_dialog

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

ep_init:
        jmp     init

ep_loop:
        jmp     EventLoop

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
        ;; if `kind` is key_down
event_key := event_params + 1
event_modifiers := event_params + 2
        ;; if `kind` is no_event, button_down/up, drag, or apple_key:
event_coords := event_params + 1
event_xcoord := event_params + 1
event_ycoord := event_params + 3
        ;; if `kind` is update:
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
buf_text:       .res    68, 0

;;; String being edited:
buf_input_left:         .res    68, 0 ; left of IP
buf_input_right:        .res    68, 0 ; IP and right

kFilePickerDlgWindowID = $3E

.params winfo_file_dialog
        kWidth = 500
        kHeight = 153

window_id:      .byte   kFilePickerDlgWindowID
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   150
mincontlength:  .word   50
maxcontwidth:   .word   500
maxcontlength:  .word   140
port:
        DEFINE_POINT viewloc, (kScreenWidth - kWidth) / 2, (kScreenHeight - kHeight) / 2
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT cliprect, 0, 0, kWidth, kHeight
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   FONT
nextwinfo:      .addr   0
.endparams


.params winfo_file_dialog_listbox
        kWidth = 125
        kHeight = 72

window_id:      .byte   $3F
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_normal
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   3
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   100
mincontlength:  .word   kHeight
maxcontwidth:   .word   100
maxcontlength:  .word   kHeight
port:
        DEFINE_POINT viewloc, 53, 48
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
maprect:
        DEFINE_RECT cliprect, 0, 0, kWidth, kHeight
pattern:        .res    8, $FF
colormasks:     .byte   $FF, 0
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textbg:         .byte   $7F
fontptr:        .addr   FONT
nextwinfo:      .addr   0
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

str_insertion_point:
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

        DEFINE_POINT file_dialog_title_pos, 0, 13

        DEFINE_RECT rect, 0, 0, 125, 0

        DEFINE_POINT pos, 2, 0

        .byte   0
        .byte   0

str_folder:
        PASCAL_STRING {kGlyphFolderLeft, kGlyphFolderRight} ; do not localize

selected_index:                 ; $FF if none
        .byte   0

        .byte   $00

        DEFINE_RECT_INSET rect_frame, 4, 2, winfo_file_dialog::kWidth, winfo_file_dialog::kHeight

        DEFINE_RECT rect0, 27, 16, 174, 26

        DEFINE_BUTTON change_drive, res_string_button_change_drive, 193, 28
        DEFINE_BUTTON open,         res_string_button_open,         193, 42
        DEFINE_BUTTON close,        res_string_button_close,        193, 56
        DEFINE_BUTTON cancel,       res_string_button_cancel,       193, 71
        DEFINE_BUTTON ok,           res_string_button_ok,           193, 87

;;; Dividing line
        DEFINE_POINT pt1, 315, 28
        DEFINE_POINT pt2, 315, 100

        DEFINE_POINT pos_disk, 28, 25
        DEFINE_POINT pos_input_label, 28, 112

        DEFINE_POINT pos_input2_label, 28, 135 ; Unused

textbg1:
        .byte   0
textbg2:
        .byte   $7F
str_disk:
        PASCAL_STRING res_string_disk

kCommonInputWidth = 435
kCommonInputHeight = 11

        DEFINE_RECT_SZ rect_input, 28, 113, kCommonInputWidth, kCommonInputHeight
        DEFINE_POINT input_textpos, 30, 123

        DEFINE_RECT_SZ unused_input2_rect, 28, 136, kCommonInputWidth, kCommonInputHeight
        DEFINE_POINT unused_input2_textpos, 30, 146

str_file_to_run:
        PASCAL_STRING res_string_label_file_to_run

;;; ============================================================

start:  jsr     OpenWindow
        jsr     DrawWindow
        jsr     DeviceOnLine
        jsr     ReadDir
        jsr     UpdateScrollbar
        jsr     UpdateDiskName
        jsr     DrawListEntries
        jsr     InitInput
        jsr     PrepPath
        jsr     RedrawInput
        lda     #$FF
        sta     LA20D
        jmp     EventLoop

;;; ============================================================

.proc InitInput
        lda     #$00
        sta     buf_input_left
        sta     LA50E
        copy    #1, buf_input_right
        copy    #kGlyphInsertionPoint, buf_input_right+1
        rts
.endproc

;;; ============================================================

.proc DrawWindow
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        param_call DrawTitleCentered, app::str_run_a_program
        param_call DrawInputLabel, str_file_to_run
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, rect_input
        MGTK_CALL MGTK::InitPort, grafport2
        MGTK_CALL MGTK::SetPort, grafport2
        rts
.endproc

;;; ============================================================

.proc HandleOk
        param_call LB5F1, buf_input_left
        beq     :+
        rts

:       ldx     saved_stack
        txs
        ldy     #<buf_input_left
        ldx     #>buf_input_left
        sta     $07
        return  #$00
.endproc

;;; ============================================================

.proc LA387
        MGTK_CALL MGTK::CloseWindow, winfo_file_dialog_listbox
        MGTK_CALL MGTK::CloseWindow, winfo_file_dialog
        lda     #$00
        sta     LA20D
        jsr     UnsetIPCursor
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
device_num:     .byte   0       ; current drive, index in DEVLST
path_buf:  .res    128, 0
LA447:  .byte   0
LA448:  .byte   0

saved_stack:
        .byte   0

;;; ============================================================

init:   tsx
        stx     saved_stack
        jsr     SetCursorPointer

        copy    DEVCNT, device_num

        lda     #0
        sta     LA447
        sta     prompt_ip_flag
        sta     LA211
        sta     cursor_ibeam_flag
        sta     LA47D
        sta     LA47F

        copy    SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter
        copy    #$FF, selected_index

        jmp     start

        .byte   0
        .byte   0
LA47D:  .byte   0
        .byte   0
LA47F:  .byte   0

;;; ============================================================

.proc EventLoop
        bit     LA20D
        bpl     :+

        dec     prompt_ip_counter
        bne     :+
        jsr     BlinkIP
        copy    SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter

:       jsr     app::YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     HandleButtonDown
        jmp     EventLoop

:       cmp     #MGTK::EventKind::key_down
        bne     :+
        jsr     HandleKey
        jmp     EventLoop

:       jsr     CheckMouseMoved
        bcc     EventLoop

        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     :+
        jmp     EventLoop
:       lda     findwindow_window_id
        cmp     winfo_file_dialog::window_id
        beq     l1
        jsr     UnsetIPCursor
        jmp     EventLoop

l1:     lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        lda     winfo_file_dialog::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect_input
        cmp     #MGTK::inrect_inside
        bne     l2
        jsr     SetCursorIBeam
        jmp     l3

l2:     jsr     UnsetIPCursor
l3:     MGTK_CALL MGTK::InitPort, grafport2
        MGTK_CALL MGTK::SetPort, grafport2
        jmp     EventLoop

.endproc

LA50E:  .byte   0

;;; ============================================================

.proc HandleButtonDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     :+
        rts

:       cmp     #MGTK::Area::content
        bne     :+
        jmp     HandleContentClick

:       rts
.endproc

.proc HandleContentClick
        lda     findwindow_window_id
        cmp     winfo_file_dialog::window_id
        beq     :+
        jmp     HandleListButtonDown

:       lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        lda     winfo_file_dialog::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx

        ;; --------------------------------------------------
.proc CheckOpenButton
        MGTK_CALL MGTK::InRect, open_button_rect
        cmp     #MGTK::inrect_inside
        bne     CheckChangeDriveButton

        bit     LA47F
        bmi     LA55E
        lda     selected_index
        bpl     LA561
LA55E:  jmp     SetUpPorts

LA561:  tax
        lda     file_list_index,x
        bmi     LA56A
LA567:  jmp     SetUpPorts

LA56A:  lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        param_call app::ButtonEventLoop, kFilePickerDlgWindowID, open_button_rect
        bmi     LA567
        jsr     LA8ED
        jmp     SetUpPorts
.endproc

        ;; --------------------------------------------------
.proc CheckChangeDriveButton
        MGTK_CALL MGTK::InRect, change_drive_button_rect
        cmp     #MGTK::inrect_inside
        bne     CheckCloseButton
        bit     LA47F
        bmi     :+

        param_call app::ButtonEventLoop, kFilePickerDlgWindowID, change_drive_button_rect
        bmi     :+
        jsr     ChangeDrive
:       jmp     SetUpPorts
.endproc

        ;; --------------------------------------------------
.proc CheckCloseButton
        MGTK_CALL MGTK::InRect, close_button_rect
        cmp     #MGTK::inrect_inside
        bne     CheckOkButton
        bit     LA47F
        bmi     :+

        param_call app::ButtonEventLoop, kFilePickerDlgWindowID, close_button_rect
        bmi     :+
        jsr     LA965
:       jmp     SetUpPorts
.endproc

        ;; --------------------------------------------------
.proc CheckOkButton
        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
        bne     CheckCancelButton

        param_call app::ButtonEventLoop, kFilePickerDlgWindowID, ok_button_rect
        bmi     :+
        jsr     InputIPToEnd
        jsr     HandleOk
:       jmp     SetUpPorts
.endproc

        ;; --------------------------------------------------
.proc CheckCancelButton
        MGTK_CALL MGTK::InRect, cancel_button_rect
        cmp     #MGTK::inrect_inside
        bne     CheckOtherClick

        param_call app::ButtonEventLoop, kFilePickerDlgWindowID, cancel_button_rect
        bmi     :+
        jsr     LA387
:       jmp     SetUpPorts
.endproc

        ;; --------------------------------------------------
.proc CheckOtherClick
        bit     LA47D
        bpl     :+
        jsr     click_handler_hook
        bmi     SetUpPorts
:       jsr     CheckInputClickAndMoveIP
        rts
.endproc

;;; ============================================================

.proc SetUpPorts
        MGTK_CALL MGTK::InitPort, grafport2
        MGTK_CALL MGTK::SetPort, grafport
        rts
.endproc

click_handler_hook:
        jsr     noop
        rts
.endproc

;;; ============================================================

.proc HandleListButtonDown
        bit     LA47F
        bmi     rts1
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_which_ctl
        beq     LA662
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     rts1
        lda     winfo_file_dialog_listbox::vscroll
        and     #MGTK::Ctl::vertical_scroll_bar
        beq     rts1
        jmp     HandleVScrollClick

rts1:   rts

LA662:  lda     winfo_file_dialog_listbox::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        add16   screentowindow_windowy, winfo_file_dialog_listbox::cliprect::y1, screentowindow_windowy
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

same:   jsr     app::DetectDoubleClick
        beq     open
        rts

open:   ldx     selected_index
        lda     file_list_index,x
        bmi     folder

        ;; File - select it.
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        jsr     HandleOk
        jmp     rts1

        ;; Folder - open it.
folder: and     #$7F
        pha
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
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
        jsr     AppendToPathBuf

        jsr     ReadDir
        jsr     UpdateScrollbar
        lda     #0
        jsr     ScrollClipRect
        jsr     UpdateDiskName
        jsr     DrawListEntries
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
        jsr     StripPathSegmentLeftAndRedraw
        lda     selected_index
        jsr     InvertEntry
:       lda     screentowindow_windowy
        sta     selected_index
        bit     LA211
        bpl     :+
        jsr     PrepPath
        jsr     RedrawInput
:       lda     selected_index
        jsr     InvertEntry
        jsr     ListSelectionChange

        jsr     app::DetectDoubleClick
        bmi     :+
        jmp     open

:       rts
.endproc

;;; ============================================================

.proc HandleVScrollClick
        lda     findcontrol_which_part
        cmp     #MGTK::Part::up_arrow
        bne     :+
        jmp     HandleLineUp

:       cmp     #MGTK::Part::down_arrow
        bne     :+
        jmp     HandleLineDown

:       cmp     #MGTK::Part::page_up
        bne     :+
        jmp     HandlePageUp

:       cmp     #MGTK::Part::page_down
        bne     :+
        jmp     HandlePageDown

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
        jsr     ScrollClipRect
        jsr     DrawListEntries
        rts
.endproc

;;; ============================================================

.proc HandlePageUp
        lda     winfo_file_dialog_listbox::vthumbpos
        sec
        sbc     #kPageDelta
        bpl     :+
        lda     #0
:       sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     ScrollClipRect
        jsr     DrawListEntries
        rts
.endproc

;;; ============================================================

.proc HandlePageDown
        lda     winfo_file_dialog_listbox::vthumbpos
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
        jsr     ScrollClipRect
        jsr     DrawListEntries
        rts
.endproc

;;; ============================================================

.proc HandleLineUp
        lda     winfo_file_dialog_listbox::vthumbpos
        bne     :+
        rts

:       sec
        sbc     #kLineDelta
        sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     ScrollClipRect
        jsr     DrawListEntries
        jsr     CheckArrowRepeat
        jmp     HandleLineUp
.endproc

;;; ============================================================

.proc HandleLineDown
        lda     winfo_file_dialog_listbox::vthumbpos
        cmp     winfo_file_dialog_listbox::vthumbmax
        bne     :+
        rts

:       clc
        adc     #kLineDelta
        sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     ScrollClipRect
        jsr     DrawListEntries
        jsr     CheckArrowRepeat
        jmp     HandleLineDown
.endproc

;;; ============================================================

.proc CheckArrowRepeat
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

.proc UnsetIPCursor
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

.proc LA8ED
        ldx     selected_index
        lda     file_list_index,x
        and     #$7F
        pha
        bit     LA211
        bpl     :+
        jsr     PrepPath
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
        jsr     AppendToPathBuf

        jsr     ReadDir
        jsr     UpdateScrollbar
        lda     #$00
        jsr     ScrollClipRect
        jsr     UpdateDiskName
        jsr     DrawListEntries
        rts

l1:     .byte   0
.endproc

;;; ============================================================

.proc ChangeDrive
        lda     #$FF
        sta     selected_index
        jsr     DecDeviceNum
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

.proc LA965
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
        lda     selected_index
        pha
        lda     #$FF
        sta     selected_index
        jsr     ReadDir
        jsr     UpdateScrollbar
        lda     #$00
        jsr     ScrollClipRect
        jsr     UpdateDiskName
        jsr     DrawListEntries
        pla
        sta     selected_index
        bit     l7
        bmi     l4
        jsr     StripPathSegmentLeftAndRedraw
        lda     selected_index
        bmi     l5
        jsr     StripPathSegmentLeftAndRedraw
        jmp     l5

l4:     jsr     PrepPath
        jsr     RedrawInput
l5:     lda     #$FF
        sta     selected_index
l6:     rts

l7:     .byte   0
.endproc

;;; ============================================================

.proc InitSetGrafport2
        MGTK_CALL MGTK::InitPort, grafport2
        ldx     #3
        lda     #0
:       sta     grafport2,x
        sta     grafport2+MGTK::GrafPort::maprect,x
        dex
        bpl     :-
        copy16  #550, grafport2+MGTK::GrafPort::maprect+MGTK::Rect::x2
        copy16  #185, grafport2+MGTK::GrafPort::maprect+MGTK::Rect::y2
        MGTK_CALL MGTK::SetPort, grafport2
        rts
.endproc

;;; ============================================================
;;; Key handler

.proc HandleKey
        lda     event_modifiers
        beq     no_modifiers

        ;; With modifiers
        lda     event_key

        cmp     #CHAR_LEFT
        bne     :+
        jmp     InputIPToStart  ; start of line

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     InputIPToEnd    ; end of line

:       bit     LA47F
        bmi     not_arrow
        cmp     #CHAR_DOWN
        bne     :+
        jmp     ScrollListBottom ; end of list

:       cmp     #CHAR_UP
        bne     not_arrow
        jmp     ScrollListTop   ; start of list

not_arrow:
        cmp     #'0'
        bcc     :+
        cmp     #'9'+1
        bcs     :+
        jmp     key_meta_digit

:       bit     LA47F
        bmi     LACAA
        jmp     CheckAlpha

        ;; --------------------------------------------------
        ;; No modifiers

no_modifiers:
        lda     event_key

        cmp     #CHAR_LEFT
        bne     :+
        jmp     InputIPLeft

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     InputIPRight

:       cmp     #CHAR_RETURN
        bne     :+
        jmp     KeyReturn

:       cmp     #CHAR_ESCAPE
        bne     :+
        jmp     KeyEscape

:       cmp     #CHAR_DELETE
        bne     :+
        jmp     KeyDelete

:       bit     LA47F
        bpl     :+
        jmp     finish

:       cmp     #CHAR_TAB
        bne     not_tab
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, change_drive_button_rect
        MGTK_CALL MGTK::PaintRect, change_drive_button_rect
        jsr     ChangeDrive
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

:       lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, open_button_rect
        MGTK_CALL MGTK::PaintRect, open_button_rect
        jsr     LA8ED
        jmp     exit

not_ctrl_o:
        cmp     #CHAR_CTRL_C    ; Close
        bne     :+
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, close_button_rect
        MGTK_CALL MGTK::PaintRect, close_button_rect
        jsr     LA965
        jmp     exit

:       cmp     #CHAR_DOWN
        bne     :+
        jmp     KeyDown

:       cmp     #CHAR_UP
        bne     finish
        jmp     KeyUp

finish: jsr     InputInsertChar
        rts

exit:   jsr     InitSetGrafport2
        rts
.endproc

;;; ============================================================

.proc KeyReturn
        lda     selected_index
        bpl     LAD20
        bit     LA211
        bmi     LAD20
        rts
.endproc

;;; ============================================================

.proc LAD20
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        jsr     InputIPToEnd
        jsr     HandleOk
        jsr     InitSetGrafport2
        rts
.endproc

;;; ============================================================

.proc KeyEscape
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        jsr     LA387
        jsr     InitSetGrafport2
        rts
.endproc

;;; ============================================================

.proc KeyDelete
        jsr     InputDeleteChar
        rts
.endproc

;;; ============================================================

key_meta_digit:
        jmp     noop

;;; ============================================================

.proc KeyDown
        lda     num_file_names
        beq     l1
        lda     selected_index
        bmi     l3
        tax
        inx
        cpx     num_file_names
        bcc     l2
l1:     rts

l2:     jsr     InvertEntry
        jsr     StripPathSegmentLeftAndRedraw
        inc     selected_index
        lda     selected_index
        jmp     UpdateListSelection

l3:     lda     #0
        jmp     UpdateListSelection
.endproc

;;; ============================================================

.proc KeyUp
        lda     num_file_names
        beq     l1
        lda     selected_index
        bmi     l3
        bne     l2
l1:     rts

l2:     jsr     InvertEntry
        jsr     StripPathSegmentLeftAndRedraw
        dec     selected_index
        lda     selected_index
        jmp     UpdateListSelection

l3:     ldx     num_file_names
        dex
        txa
        jmp     UpdateListSelection
.endproc

;;; ============================================================

.proc CheckAlpha
        jsr     UpcaseChar
        cmp     #'A'
        bcc     done
        cmp     #'Z'+1
        bcs     done

        jsr     LADDF
        bmi     done
        cmp     selected_index
        beq     done
        pha
        lda     selected_index
        bmi     LADDB
        jsr     InvertEntry
        jsr     StripPathSegmentLeftAndRedraw
LADDB:  pla
        jmp     UpdateListSelection

done:   rts

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
        beq     l1
        lda     selected_index
        bmi     l2
        bne     :+
l1:     rts

:       jsr     InvertEntry
        jsr     StripPathSegmentLeftAndRedraw
l2:     lda     #$00
        jmp     UpdateListSelection
.endproc

;;; ============================================================

.proc ScrollListBottom
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
        jsr     InvertEntry
        jsr     StripPathSegmentLeftAndRedraw
l1:     ldx     num_file_names
        dex
        txa
        jmp     UpdateListSelection
.endproc

;;; ============================================================

.proc UpdateListSelection
        sta     selected_index
        jsr     ListSelectionChange

        lda     selected_index
        jsr     CalcTopIndex
        jsr     UpdateScrollbar2
        jsr     DrawListEntries

        copy    #1, buf_input_right
        copy    #' ', buf_input_right+1

        jsr     RedrawInput
        rts
.endproc

;;; ============================================================

noop:   rts

;;; ============================================================

.proc OpenWindow
        MGTK_CALL MGTK::OpenWindow, winfo_file_dialog
        MGTK_CALL MGTK::OpenWindow, winfo_file_dialog_listbox
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, rect_frame
        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::FrameRect, open_button_rect
        MGTK_CALL MGTK::FrameRect, close_button_rect
        MGTK_CALL MGTK::FrameRect, cancel_button_rect
        MGTK_CALL MGTK::FrameRect, change_drive_button_rect
        jsr     DrawOkButtonLabel
        jsr     DrawOpenButtonLabel
        jsr     DrawCloseButtonLabel
        jsr     DrawCancelButtonLabel
        jsr     DrawChangeDriveButtonLabel
        MGTK_CALL MGTK::MoveTo, pt1
        MGTK_CALL MGTK::LineTo, pt2
        jsr     InitSetGrafport2
        rts
.endproc

.proc DrawOkButtonLabel
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call DrawString, ok_button_label
        rts
.endproc

.proc DrawOpenButtonLabel
        MGTK_CALL MGTK::MoveTo, open_button_pos
        param_call DrawString, open_button_label
        rts
.endproc

.proc DrawCloseButtonLabel
        MGTK_CALL MGTK::MoveTo, close_button_pos
        param_call DrawString, close_button_label
        rts
.endproc

.proc DrawCancelButtonLabel
        MGTK_CALL MGTK::MoveTo, cancel_button_pos
        param_call DrawString, cancel_button_label
        rts
.endproc

.proc DrawChangeDriveButtonLabel
        MGTK_CALL MGTK::MoveTo, change_drive_button_pos
        param_call DrawString, change_drive_button_label
        rts
.endproc

;;; ============================================================

.proc DrawString
        ptr := $06
        params := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     params+2
        inc16   params
        MGTK_CALL MGTK::DrawText, params
        rts
.endproc

;;; ============================================================

.proc DrawTitleCentered
        text_params     := $6
        text_addr       := text_params + 0
        text_length     := text_params + 2
        text_width      := text_params + 3

        stax    text_addr       ; input is length-prefixed string
        ldy     #0
        lda     (text_addr),y
        sta     text_length
        inc16   text_addr ; point past length byte
        MGTK_CALL MGTK::TextWidth, text_params

        sub16   #winfo_file_dialog::kWidth, text_width, file_dialog_title_pos::xcoord
        lsr16   file_dialog_title_pos::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, file_dialog_title_pos::xcoord
        MGTK_CALL MGTK::DrawText, text_params
        rts
.endproc

;;; ============================================================

.proc DrawInputLabel
        stax    $06
        MGTK_CALL MGTK::MoveTo, pos_input_label
        ldax    $06
        jsr     DrawString
        rts
.endproc

;;; ============================================================

.proc DeviceOnLine
retry:  ldx     device_num
        lda     DEVLST,x

        and     #UNIT_NUM_MASK
        sta     on_line_params::unit_num
        MLI_CALL ON_LINE, on_line_params
        lda     buf_on_line
        and     #NAME_LENGTH_MASK
        sta     buf_on_line
        bne     found
        jsr     DecDeviceNum
        jmp     retry

found:  param_call AdjustVolumeNameCase, buf_on_line
        lda     #0
        sta     path_buf
        param_call AppendToPathBuf, buf_on_line
        rts
.endproc

;;; ============================================================

.proc DecDeviceNum
        dec     device_num
        bpl     :+
        copy    DEVCNT, device_num
:       rts
.endproc

;;; ============================================================

.proc OpenDir
retry:  lda     #$00
        sta     open_dir_flag
        MLI_CALL OPEN, open_params
        beq     :+
        jsr     DeviceOnLine
        lda     #$FF
        sta     selected_index
        lda     #$FF
        sta     open_dir_flag
        jmp     retry

:       lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        beq     :+
        jsr     DeviceOnLine
        lda     #$FF
        sta     selected_index
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
        ;; TODO: Check length?

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
        sta     selected_index

        rts
.endproc

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
        sta     l10
        sta     l11
        sta     LA448
        lda     #1
        sta     l12
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
        jmp     l5

l2:     ldx     l10
        txa
        sta     file_list_index,x
        ldy     #0
        lda     (ptr),y
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
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        sta     (ptr),y

        dst_ptr := $08
        copy16  #file_names, dst_ptr
        lda     #$00
        sta     l15
        lda     l10
        asl     a               ; *= 16
        rol     l15
        asl     a
        rol     l15
        asl     a
        rol     l15
        asl     a
        rol     l15
        clc
        adc     dst_ptr
        sta     dst_ptr
        lda     l15
        adc     dst_ptr+1
        sta     dst_ptr+1

        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     (dst_ptr),y
        dey
        bpl     :-

        inc     l10
        inc     l11
l5:     inc     l12
        lda     l11
        cmp     num_file_names
        bne     next

close:  MLI_CALL CLOSE, close_params
        bit     LA447
        bpl     :+
        lda     LA448
        sta     num_file_names
:       jsr     SortFileNames
        jsr     LB65E
        lda     open_dir_flag
        bpl     l7
        sec
        rts

l7:     clc
        rts

next:   lda     l12
        cmp     l14
        beq     :+
        add16_8 ptr, entry_length, ptr
        jmp     l1

:       MLI_CALL READ, read_params
        copy16  #dir_read_buf+$04, ptr
        lda     #$00
        sta     l12
        jmp     l1

l10:    .byte   0
l11:    .byte   0
l12:    .byte   0
entry_length:
        .byte   0
l14:    .byte   0
l15:    .byte   0
.endproc

;;; ============================================================

.proc DrawListEntries
        jsr     InitSetGrafport2

        lda     winfo_file_dialog_listbox::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::PaintRect, winfo_file_dialog_listbox::maprect
        copy    #kListEntryNameX, pos::xcoord ; high byte always 0
        copy16  #kListEntryHeight, pos::ycoord
        copy    #0, l4

loop:   lda     l4
        cmp     num_file_names
        bne     :+
        jsr     InitSetGrafport2
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
        jsr     DrawString
        ldx     l4
        lda     file_list_index,x
        bpl     :+

        ;; Folder glyph
        copy    #kListEntryGlyphX, pos::xcoord
        MGTK_CALL MGTK::MoveTo, pos
        param_call DrawString, str_folder
        copy    #kListEntryNameX, pos::xcoord

:       lda     l4
        cmp     selected_index
        bne     l2
        jsr     InvertEntry
        lda     winfo_file_dialog_listbox::window_id
        jsr     SetPortForWindow
l2:     inc     l4
        add16_8 pos::ycoord, #kListEntryHeight, pos::ycoord
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
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_which_ctl
        copy    #MGTK::activatectl_deactivate, activatectl_activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        lda     #0
        jmp     ScrollClipRect

:       lda     num_file_names
        sta     winfo_file_dialog_listbox::vthumbmax
        .assert MGTK::Ctl::vertical_scroll_bar = MGTK::activatectl_activate, error, "need to match"
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_which_ctl
        sta     activatectl_activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        lda     index
        sta     updatethumb_thumbpos
        jsr     ScrollClipRect
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        rts

index:  .byte   0
.endproc

;;; ============================================================

.proc UpdateDiskName
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
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
        param_call DrawString, str_disk
        param_call DrawString, INVOKER_PREFIX
        jsr     InitSetGrafport2
        rts

l5:     .byte   0
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
        stax    winfo_file_dialog_listbox::cliprect::y1
        add16_8 winfo_file_dialog_listbox::cliprect::y1, #winfo_file_dialog_listbox::kHeight, winfo_file_dialog_listbox::cliprect::y2
        rts

tmp:    .byte   0
.endproc

;;; ============================================================
;;; Inputs: A = entry index

.proc InvertEntry
        ldx     #0              ; A,X = entry
        ldy     #kListEntryHeight
        jsr     Multiply_16_8_16
        stax    rect::y1

        add16_8 rect::y1, #kListEntryHeight, rect::y2

        lda     winfo_file_dialog_listbox::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect
        jsr     InitSetGrafport2
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

.proc SetPortForWindow
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport
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
        sta     l17

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

:       lda     l17
        jsr     CalcEntryPtr
        ldy     #0              ; mark as done
        lda     ($06),y
        ora     #$80
        sta     ($06),y

        lda     #$7F            ; beyond last possible name char
        ldx     #$0F            ; max length
:       sta     name_buf+1,x
        dex
        bpl     :-

        ldx     outer_index
        lda     l17
        sta     l20,x
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
        beq     done
        dex
:       lda     l20,x
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
l17:    .byte   0
name_buf:
        .res    17, 0

l20:    .res    127, 0

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

.proc FindFilenameIndex       ; Unreferenced - TODO: Remove
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

.proc BlinkIP
        pt := $06

        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        jsr     CalcIPPos
        stax    pt
        copy16  input_textpos::ycoord, pt+2
        MGTK_CALL MGTK::MoveTo, pt
        bit     prompt_ip_flag
        bpl     bg2

        MGTK_CALL MGTK::SetTextBG, textbg1
        copy    #$00, prompt_ip_flag
        beq     :+

bg2:    MGTK_CALL MGTK::SetTextBG, textbg2
        copy    #$FF, prompt_ip_flag

        PARAM_BLOCK dt_params, $06
data    .addr
length  .byte
        END_PARAM_BLOCK

:       copy16  #str_insertion_point+1, dt_params::data
        copy    str_insertion_point, dt_params::length
        MGTK_CALL MGTK::DrawText, dt_params
        jsr     InitSetGrafport2
        rts
.endproc

;;; ============================================================

.proc RedrawInput
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::PaintRect, rect_input
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, rect_input
        MGTK_CALL MGTK::MoveTo, input_textpos
        lda     buf_input_left
        beq     :+
        param_call DrawString, buf_input_left
:       param_call DrawString, buf_input_right
        param_call DrawString, str_two_spaces
        rts
.endproc

;;; ============================================================

.proc CheckInputClickAndMoveIP

        ;; Was click inside text box?
        lda     winfo_file_dialog::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect_input
        cmp     #MGTK::inrect_inside
        beq     :+
        rts

        ;; Is click to left or right of insertion point?
:       jsr     CalcIPPos
        stax    $06
        cmp16   screentowindow_windowx, $06
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
        jsr     CalcIPPos
        stax    ip_pos
        ldx     buf_input_right
        inx
        lda     #' '            ; append space at end
        sta     buf_input_right,x
        inc     buf_input_right

        ;; Iterate to find the position
        copy16  #buf_input_right, tw_params::data
        copy    buf_input_right, tw_params::length
@loop:  MGTK_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, ip_pos, tw_params::width
        cmp16   tw_params::width, screentowindow_windowx
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
        dec     buf_input_right ; remove appended space...
        jmp     InputIPToEnd    ; and use this shortcut

        ;; Append from `buf_input_right` into `buf_input_left`
:       ldx     #2
        ldy     buf_input_left
        iny
:       lda     buf_input_right,x
        sta     buf_input_left,y
        cpx     tw_params::length
        beq     :+
        iny
        inx
        jmp     :-
:       sty     buf_input_left

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
        copy16  #buf_input_left, tw_params::data
        copy    buf_input_left, tw_params::length
@loop:  MGTK_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, input_textpos::xcoord, tw_params::width
        cmp16   tw_params::width, screentowindow_windowx
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bcs     @loop
        jmp     InputIPToStart

        ;; Found position; copy everything to the right of
        ;; the new position from `buf_input_left` to `buf_text`
:       inc     tw_params::length
        ldy     #0
        ldx     tw_params::length
:       cpx     buf_input_left
        beq     :+
        inx
        iny
        lda     buf_input_left,x
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
        sta     buf_input_left
        ;; fall through
.endproc

finish: jsr     RedrawInput
        jsr     LBB5B
        rts

ip_pos: .word   0
.endproc

;;; ============================================================

.proc InputInsertChar
        sta     tmp
        lda     buf_input_left
        clc
        adc     buf_input_right
        cmp     #kMaxInputLength
        bcc     continue
        rts

tmp:    .byte   0

continue:
        lda     tmp
        ldx     buf_input_left
        inx
        sta     buf_input_left,x
        sta     str_1_char+1
        jsr     CalcIPPos
        inc     buf_input_left
        stax    $06
        copy16  input_textpos::ycoord, $08
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::MoveTo, $06
        param_call DrawString, str_1_char
        param_call DrawString, buf_input_right
        jsr     LBB5B
        rts
.endproc

;;; ============================================================

.proc InputDeleteChar
        lda     buf_input_left
        bne     :+
        rts

:       dec     buf_input_left
        jsr     CalcIPPos
        stax    $06
        copy16  input_textpos::ycoord, $08
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::MoveTo, $06
        param_call DrawString, buf_input_right
        param_call DrawString, str_two_spaces
        jsr     LBB5B
        rts
.endproc

;;; ============================================================

.proc InputIPLeft
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
        jsr     CalcIPPos
        stax    $06
        copy16  input_textpos::ycoord, $08
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::MoveTo, $06
        param_call DrawString, buf_input_right
        param_call DrawString, str_two_spaces
        jsr     LBB5B
        rts
.endproc

;;; ============================================================

.proc InputIPRight
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
        lda     winfo_file_dialog::window_id
        jsr     SetPortForWindow
        MGTK_CALL MGTK::MoveTo, input_textpos
        param_call DrawString, buf_input_left
        param_call DrawString, buf_input_right
        param_call DrawString, str_two_spaces
        jsr     LBB5B
        rts
.endproc

;;; ============================================================

.proc InputIPToStart
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
        jsr     RedrawInput
        jsr     LBB5B
        rts
.endproc

;;; ============================================================

.proc InputIPToEnd
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
        jsr     RedrawInput
        jsr     LBB5B
        rts
.endproc

;;; ============================================================
;;; Input: A,X = string address

.proc AppendSegmentToInput
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

.proc StripPathSegmentLeft
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

.proc StripPathSegmentLeftAndRedraw
        jsr     StripPathSegmentLeft
        jsr     RedrawInput
        rts
.endproc

;;; ============================================================

.proc ListSelectionChange
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
        jsr     AppendSegmentToInput
        jsr     RedrawInput
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

.proc LBB09                     ; Unreferenced - TODO: Remove
        COPY_STRING path_buf, buf_input_left
        rts
.endproc

;;; ============================================================

.proc PrepPath
        COPY_STRING path_buf, buf_input_left
        rts
.endproc

;;; ============================================================
;;; Output: A,X = X coordinate of insertion point

.proc CalcIPPos
        PARAM_BLOCK params, $06
data    .addr
length  .byte
width   .word
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
        adc     input_textpos::xcoord
        tay
        lda     params::width+1
        adc     input_textpos::xcoord+1
        tax
        tya
        rts
.endproc

;;; ============================================================

.proc LBB5B
        COPY_STRING buf_input_left, buf_text

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
        jsr     AppendToPathBuf

l1:     lda     buf_text
        cmp     path_buf
        bne     l3
        tax
l2:     lda     buf_text,x
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

l5:     jsr     StripPathSegment
        rts

l6:     .byte   0
l7:     .byte   0
.endproc

;;; ============================================================
;;; Determine if mouse moved
;;; Output: C=1 if mouse moved

.proc CheckMouseMoved
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

        .define LIB_MLI_CALL MLI_CALL
         ADJUSTCASE_VOLPATH := $810
         ADJUSTCASE_VOLBUF  := $820
         ADJUSTCASE_IO_BUFFER := $1C00
        .include "../lib/adjustfilecase.s"
        .undefine LIB_MLI_CALL

        .include "../lib/muldiv.s"

;;; ============================================================

.endscope

file_dialog_init   := file_dialog::ep_init
file_dialog_loop   := file_dialog::ep_loop

        PAD_TO OVERLAY_ADDR + kOverlay1Size
        .assert * <= $BF00, error, "Overwrites ProDOS Global Page"
