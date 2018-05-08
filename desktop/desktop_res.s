        .assert * = $D200, error, "Addr mismatch"

pencopy:        .byte   0
penOR:          .byte   1
penXOR:         .byte   2
penBIC:         .byte   3
notpencopy:     .byte   4
notpenOR:       .byte   5
notpenXOR:      .byte   6
notpenBIC:      .byte   7

;;; ============================================================
;;; Re-used param space for events/queries (10 bytes)

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
activatectl_which_ctl := activatectl_params
activatectl_activate  := activatectl_params + 1

trackthumb_params := *
trackthumb_which_ctl := trackthumb_params
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

findicon_params := * + 1      ; offset to x/y overlap event_params x/y
findicon_mousex := findicon_params + 0
findicon_mousey := findicon_params + 2
findicon_which_icon := findicon_params + 4
findicon_window_id := findicon_params + 5
        .assert findicon_mousex = event_xcoord, error, "param mismatch"
        .assert findicon_mousey = event_ycoord, error, "param mismatch"

        ;; Enough space for all the param types, and then some
        .res    10, 0

;;; ============================================================

.proc getwinport_params2
window_id:     .byte   0
a_grafport:     .addr   grafport2
.endproc

.proc grafport2
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   0
mapwidth:       .word   0
cliprect:       DEFINE_RECT 0, 0, 0, 0, cliprect
penpattern:     .res    8, 0
colormasks:     .byte   0, 0
penloc: DEFINE_POINT 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textbg: .byte   MGTK::textbg_black
fontptr:        .addr   0
.endproc

.proc grafport3
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   0
mapwidth:       .word   0
cliprect:       DEFINE_RECT 0, 0, 0, 0, cliprect
penpattern:     .res    8, 0
colormasks:     .byte   0, 0
penloc: DEFINE_POINT 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textbg: .byte   MGTK::textbg_black
fontptr:        .addr   0
.endproc
        grafport3_viewloc_xcoord := grafport3::viewloc::xcoord
        grafport3_cliprect_x1 := grafport3::cliprect::x1
        grafport3_cliprect_x2 := grafport3::cliprect::x2
        grafport3_cliprect_y2 := grafport3::cliprect::y2

.proc grafport5
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, 10, 10, cliprect
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc: DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg: .byte   MGTK::textbg_black
fontptr:        .addr   DEFAULT_FONT
.endproc

;;; ============================================================

white_pattern3:                 ; unused?
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   $FF

black_pattern3:                 ; unused?
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   $FF

checkerboard_pattern3:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   $FF

        ;; Copies of ROM bytes used for machine identification
.proc startdesktop_params
machine:        .byte   $06     ; ROM FBB3 ($06 = IIe or later)
subid:          .byte   $EA     ; ROM FBC0 ($EA = IIe, $E0 = IIe enh/IIgs, $00 = IIc/IIc+)
op_sys:         .byte   0       ; 0=ProDOS
slot_num:       .byte   0       ; Mouse slot, 0 = search
use_interrupts: .byte   0       ; 0=passive
sysfontptr:     .addr   DEFAULT_FONT
savearea:       .addr   $0800   ; $0800 - $1AFF
savesize:       .word   $1300
.endproc

zp_use_flag0:
        .byte   0

.proc trackgoaway_params        ; next 3 bytes???
goaway:.byte   0
.endproc
LD2A9:  .byte   0
double_click_flag:
        .byte   0               ; high bit clear if double-clicked, set otherwise

        ;; Set to specific machine type; used for double-click timing.
machine_type:
        .byte   $00             ; Set to: $96 = IIe, $FA = IIc, $FD = IIgs

warning_dialog_num:
        .byte   $00

;;; Cursors (bitmap - 2x12 bytes, mask - 2x12 bytes, hotspot - 2 bytes)

;;; Pointer

pointer_cursor:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0100000),px(%0000000)
        .byte   px(%0110000),px(%0000000)
        .byte   px(%0111000),px(%0000000)
        .byte   px(%0111100),px(%0000000)
        .byte   px(%0111110),px(%0000000)
        .byte   px(%0111111),px(%0000000)
        .byte   px(%0101100),px(%0000000)
        .byte   px(%0000110),px(%0000000)
        .byte   px(%0000110),px(%0000000)
        .byte   px(%0000011),px(%0000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000)
        .byte   px(%1110000),px(%0000000)
        .byte   px(%1111000),px(%0000000)
        .byte   px(%1111100),px(%0000000)
        .byte   px(%1111110),px(%0000000)
        .byte   px(%1111111),px(%0000000)
        .byte   px(%1111111),px(%1000000)
        .byte   px(%1111111),px(%0000000)
        .byte   px(%0001111),px(%0000000)
        .byte   px(%0001111),px(%0000000)
        .byte   px(%0000111),px(%1000000)
        .byte   px(%0000111),px(%1000000)
        .byte   1,1

;;; Insertion Point
insertion_point_cursor:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%0001010),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0001010),px(%0000000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%1111011),px(%1100000)
        .byte   px(%0111111),px(%1000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0111111),px(%1000000)
        .byte   px(%1111011),px(%1100000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%0000000),px(%0000000)
        .byte   4, 5

;;; Watch
watch_cursor:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0100001),px(%0010000)
        .byte   px(%0100110),px(%0011000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111100)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0000000),px(%0000000)
        .byte   5, 5

LD343:  .word   0
buf_filename2:  .res    16, 0
LD355:  .res    43, 0

temp_string_buf:
        .res    45, 0

LD3AD:  .res    19, 0
LD3C0:  .res    46, 0

LD3EE:  .res    17, 0
LD3FF:  .byte   0
LD400:  .byte   0
LD401:  .byte   0

;;; In common dialog (copy/edit file, add/edit selector entry):
;;; * path_buf0 has the contents of the top input field
;;; * path_buf1 has the contents of the bottom input field
;;; * path_buf2 has the contents of the focused field after insertion point
;;;   (May have leading caret glyph $06)

path_buf0:  .res    65, 0
path_buf1:  .res    65, 0
path_buf2:  .res    65, 0

alert_bitmap2:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),PX(%1111111),PX(%1111111),px(%0000000),px(%0000000)
        .byte   px(%0111100),px(%1111100),px(%0000001),px(%1110000),PX(%0000111),px(%0000000),px(%0000000)
        .byte   px(%0111100),px(%1111100),px(%0000011),px(%1100000),px(%0000011),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0000111),PX(%1100111),px(%1111001),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0001111),PX(%1100111),px(%1111001),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),px(%1111001),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),px(%1110011),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),PX(%1100111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),PX(%1001111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),PX(%0011111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),px(%1111110),PX(%0111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),px(%1111100),PX(%1111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),px(%1111100),PX(%1111111),px(%0000000),px(%0000000)
        .byte   px(%0111110),px(%0000000),PX(%0111111),PX(%1111111),PX(%1111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100000),PX(%1111111),px(%1111100),PX(%1111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100001),PX(%1111111),PX(%1111111),PX(%1111111),px(%0000000),px(%0000000)
        .byte   px(%0111000),px(%0000011),PX(%1111111),PX(%1111111),px(%1111110),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)

alert_bitmap2_params:
        DEFINE_POINT 40, 8      ; viewloc
        .addr   alert_bitmap2   ; mapbits
        .byte   7               ; mapwidth
        .byte   0               ; reserved
        DEFINE_RECT 0, 0, 36, 23 ; maprect

        ;; Looks like window param blocks starting here

.proc winfo_alert_dialog
window_id:      .byte   $0F
options:        .byte   MGTK::option_dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   150
maxcontwidth:   .word   50
mincontlength:  .word   500
maxcontlength:  .word   140
port:
viewloc:        DEFINE_POINT 75, 35
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, 400, 100
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc

;;; Dialog used for Selector > Add/Edit an Entry...

.proc winfo_entrydlg
window_id:      .byte   $12
options:        .byte   MGTK::option_dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   150
maxcontwidth:   .word   50
mincontlength:  .word   500
maxcontlength:  .word   140
port:
viewloc:        DEFINE_POINT 25, 20
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, 500, 153
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc

;;; File picker within Add/Edit an Entry dialog

.proc winfo_entrydlg_file_picker
window_id:      .byte   $15
options:        .byte   MGTK::option_dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_normal
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   3
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   100
maxcontwidth:   .word   70
mincontlength:  .word   100
maxcontlength:  .word   70
port:
viewloc:        DEFINE_POINT 53, 50
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, 125, 70
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc

;;; "About Apple II Desktop" Dialog

.proc winfo_about_dialog
        width := 400

window_id:      .byte   $18
options:        .byte   MGTK::option_dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   150
maxcontwidth:   .word   50
mincontlength:  .word   500
maxcontlength:  .word   140
port:
viewloc:        DEFINE_POINT (screen_width - width) / 2, 40
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, width, 110
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc
winfo_about_dialog_port    := winfo_about_dialog::port

;;; Dialog used for Edit/Delete/Run an Entry ...

.proc winfo_entry_picker
        width := 350

window_id:      .byte   $1B
options:        .byte   MGTK::option_dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   150
maxcontwidth:   .word   50
mincontlength:  .word   500
maxcontlength:  .word   140
port:
viewloc:        DEFINE_POINT (screen_width - width) / 2, 25
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, width, 110
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc

        ;; Coordinates for labels?
        .byte   $28,$00,$25,$00,$68,$01,$2F,$00,$2D,$00,$2E,$00

name_input_rect:  DEFINE_RECT 40,61,360,71, name_input_rect
name_input_textpos: DEFINE_POINT 45,70, name_input_textpos
pos_dialog_title: DEFINE_POINT 0, 18, pos_dialog_title

point7: DEFINE_POINT 40,18, point7
pointD: DEFINE_POINT 40,35, pointD

        dialog_label_default_x := 40
dialog_label_pos:
        DEFINE_POINT dialog_label_default_x,0, dialog_label_pos

.proc setportbits_params3
        DEFINE_POINT 75, 35
        .addr   MGTK::screen_mapbits
        .byte   MGTK::screen_mapwidth
        .byte   0
        DEFINE_RECT 0, 0, 358, 100
.endproc

        ;; ???
        .byte   $00

rect_D6D8:
        DEFINE_RECT 4,2,346,108
rect_D6E0:
        DEFINE_RECT 5,3,345,107

        ;; Line endpoints
pos_D6E8:
        DEFINE_POINT 6,22
pos_D6EC:
        DEFINE_POINT 344,22

        ;; Line endpoints
pos_D6F0:
        DEFINE_POINT 6,89
pos_D6F4:
        DEFINE_POINT 344,89

rect_D6F8:
        DEFINE_RECT 210,92,310,103

rect_D700:
        DEFINE_RECT 40,92,140,103

pos_D708:
        DEFINE_POINT 215,102
pos_D70C:
        DEFINE_POINT 45,102
        .word   130,7,220,19

add_an_entry_label:
        PASCAL_STRING "Add an Entry ..."
edit_an_entry_label:
        PASCAL_STRING "Edit an Entry ..."
delete_an_entry_label:
        PASCAL_STRING "Delete an Entry ..."
run_an_entry_label:
        PASCAL_STRING "Run an Entry ..."

LD760:  PASCAL_STRING "Run list"

enter_the_full_pathname_label1:
        PASCAL_STRING "Enter the full pathname of the run list file:"
enter_the_name_to_appear_label:
        PASCAL_STRING "Enter the name (14 characters max)  you wish to appear in the run list"

add_a_new_entry_to_label:
        PASCAL_STRING "Add a new entry to the:"
run_list_label:
        PASCAL_STRING {GLYPH_OAPPLE,"1 Run list"}
other_run_list_label:
        PASCAL_STRING {GLYPH_OAPPLE,"2 Other Run list"}
down_load_label:
        PASCAL_STRING "Down load:"
at_first_boot_label:
        PASCAL_STRING {GLYPH_OAPPLE,"3 at first boot"}
at_first_use_label:
        PASCAL_STRING {GLYPH_OAPPLE,"4 at first use"}
never_label:
        PASCAL_STRING {GLYPH_OAPPLE,"5 never"}

enter_the_full_pathname_label2:
        PASCAL_STRING "Enter the full pathname of the run list file:"

rect_D877:
        DEFINE_RECT 0,0,0,0

rect_D87F:
        DEFINE_RECT 6,23,344,87
        .byte   0

rect_D888:
        DEFINE_RECT 0,0,0,0
        .byte   0

the_dos_33_disk_label:
        PASCAL_STRING "the DOS 3.3 disk in slot   drive   ?"
the_dos_33_disk_slot_char_offset:
        .byte   26
the_dos_33_disk_drive_char_offset:
        .byte   34

the_disk_in_slot_label:
        PASCAL_STRING "the disk in slot   drive   ?"
the_disk_in_slot_slot_char_offset:
        .byte   18
the_disk_in_slot_drive_char_offset:
        .byte   26

buf_filename:
        .res    16, 0

LD8E7:  .byte   0
LD8E8:  .byte   0
LD8E9:  .byte   $14
        .byte   $00
LD8EB:  .byte   0
LD8EC:  .byte   0
LD8ED:  .byte   0
LD8EE:  .byte   1
LD8EF:  .byte   6

LD8F0:  .byte   0
LD8F1:  .byte   0
LD8F2:  .byte   0
LD8F3:  .byte   0
LD8F4:  .byte   0
LD8F5:  .byte   0

str_1_char:
        PASCAL_STRING {0}

str_2_spaces:
        PASCAL_STRING "  "

str_files:
        PASCAL_STRING "Files"
str_file_count:                 ; populated with number of files
        PASCAL_STRING "       "

file_count:
        .word   0

pos_D90B:
        DEFINE_POINT 0,13

rect_D90F:
        DEFINE_RECT 0,0,125,0

pos_D917:
        DEFINE_POINT 2,0

        .byte   $00,$00

str_folder:
        PASCAL_STRING {GLYPH_FOLDERL,GLYPH_FOLDERR}

        .byte   $00,$00

pos_D922:
        DEFINE_POINT 343,40
pos_D926:
        DEFINE_POINT 363,48
pos_D92A:
        DEFINE_POINT 363,56
pos_D92E:
        DEFINE_POINT 343,75
pos_D932:
        DEFINE_POINT 363,83
pos_D936:
        DEFINE_POINT 363,91
pos_D93A:
        DEFINE_POINT 363,99

rect_D93E:
        DEFINE_RECT 346,41,356,47

rect_D946:
        DEFINE_RECT 346,49,356,55

rect_D94E:
        DEFINE_RECT 346,76,356,82

rect_D956:
        DEFINE_RECT 346,84,356,90

rect_D95E:
        DEFINE_RECT 346,92,356,98

rect_D966:
        DEFINE_RECT 346,41,480,48

rect_D96E:
        DEFINE_RECT 346,49,480,55

rect_D976:
        DEFINE_RECT 346,76,480,83

rect_D97E:
        DEFINE_RECT 346,84,480,91

rect_D986:
        DEFINE_RECT 346,92,480,99

rect_D98E:
        DEFINE_RECT 0,0,0,0

        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00

common_dialog_frame_rect:
        DEFINE_RECT 4,2,496,151

rect_D9C8:
        DEFINE_RECT 27,16,174,26

common_close_button_rect:
        DEFINE_RECT 193,58,293,69


common_ok_button_rect:
        DEFINE_RECT 193,89,293,100

common_open_button_rect:
        DEFINE_RECT 193,44,293,55

common_cancel_button_rect:
        DEFINE_RECT 193,73,293,84

common_change_drive_button_rect:
        DEFINE_RECT 193,30,293,41

common_dialog_sep_start:
        DEFINE_POINT 323,30
common_dialog_sep_end:
        DEFINE_POINT 323,100

        .byte   $81,$D3,$00

ok_button_pos:
        .word   198,99
ok_button_label:
        PASCAL_STRING {"OK            ",GLYPH_RETURN}

close_button_pos:
        .word   198,68
close_button_label:
        PASCAL_STRING "Close"

open_button_pos:
        .word   198,54
open_button_label:
        PASCAL_STRING "Open"

cancel_button_pos:
        .word   198,83
cancel_button_label:
        PASCAL_STRING "Cancel        Esc"

change_drive_button_pos:
        .word   198,40
change_drive_button_label:
        PASCAL_STRING "Change Drive"

disk_label_pos:
        DEFINE_POINT   28,25

common_input1_label_pos:
        DEFINE_POINT   28,112
common_input2_label_pos:
        DEFINE_POINT   28,135

textbg1:
        .byte   $00
textbg2:
        .byte   $7F

disk_label:
        PASCAL_STRING " Disk: "

copy_a_file_label:
        PASCAL_STRING "Copy a File ..."

source_filename_label:
        PASCAL_STRING "Source filename:"

destination_filename_label:
        PASCAL_STRING "Destination filename:"

common_input1_rect:   DEFINE_RECT 28, 113, 463, 124
common_input1_textpos:      DEFINE_POINT 30,123

common_input2_rect:   DEFINE_RECT 28, 136, 463, 147
common_input2_textpos:      DEFINE_POINT 30,146

delete_a_file_label:
        PASCAL_STRING "Delete a File ..."

file_to_delete_label:
        PASCAL_STRING "File to delete:"

        .assert * = $DAD8, error, "Segment length mismatch"
        PAD_TO $DB00

;;; ============================================================

slot_drive_string_table:
        .addr   sd0s, sd1s, sd2s, sd3s, sd4s, sd5s, sd6s
        .addr   sd7s, sd8s, sd9s, sd10s, sd11s, sd12s, sd13s

        .addr   selector_menu

        ;; Buffer for Run List entries
run_list_entries:
        .res    640, 0

;;; ============================================================
;;; Window & Icon State
;;; ============================================================

LDD9E:  .byte   0

        ;; Pointers into icon_entries buffer
icon_entry_address_table:
        .assert * = file_table, error, "Entry point mismatch"
        .res    256, 0

;;; Copy from aux memory of icon list for active window (0=desktop)

        ;; which window buffer (see window_icon_count_table, window_icon_list_table) is copied
cached_window_id: .byte   0
        ;; number of icons in copied window
cached_window_icon_count:.byte   0
        ;; list of icons in copied window
cached_window_icon_list:   .res    127, 0


selected_window_index: ; index of selected window (used to get prefix)
        .assert * = path_index, error, "Entry point mismatch"
        .byte   0

selected_icon_count:            ; number of selected icons
        .assert * = selected_file_count, error, "Entry point mismatch"
        .byte   0

selected_icon_list:            ; index of selected icon (global, not w/in window)
        .assert * = selected_file_list, error, "Entry point mismatch"
        .res    127, 0

        ;; Buffer for desktop windows
win_table:
        .addr   0,winfo1,winfo2,winfo3,winfo4,winfo5,winfo6,winfo7,winfo8

        ;; Window to Path mapping table
window_address_table:
        .assert * = path_table, error, "Entry point mismatch"
        .addr   $0000
        .repeat 8,i
        .addr   window_path_table+i*65
        .endrepeat

;;; ============================================================

LDFC5:  .byte   0
LDFC6:  .byte   0
LDFC7:  .byte   0
LDFC8:  .byte   0

path_buf4:
        .res    65, 0
path_buf3:
        .res    65, 0
LE04B:  .res    16, 0
LE05B:  .byte   $00
LE05C:  .byte   $00
LE05D:  .byte   $00
LE05E:  .byte   $0D
LE05F:  .byte   $00
LE060:  .byte   $00
LE061:  .byte   $00


LE062:  .res    170, 0
LE10C:  .byte   0
LE10D:  .res    137, 0

DESKTOP_DEVICELIST:
        .res    10, 0
devlst_copy:
        .res    16, 0

LE1B0:  .res    65, 0           ; path buffer?
LE1F1:  .res    15, 0           ; length-prefixed string
LE200:  .word   0
LE202:  .res    24, 0           ; addr table

        .byte   $00,$00,$00,$00,$7F,$64,$00,$1C
        .byte   $00,$1E,$00,$32,$00,$1E,$00,$40
        .byte   $00

        ;; DT_HIGHLIGHT_ICON params
LE22B:  .byte   0

LE22C:  .byte   0

        ;; DT_HIGHLIGHT_ICON params
LE22D:  .byte   0

        ;; DT_UNHIGHLIGHT_ICON params
LE22E:
        .byte   $00

        ;; DT_HIGHLIGHT_ICON params
        ;; DT_UNHIGHLIGHT_ICON params
icon_param:  .byte   0

rect_E230:  DEFINE_RECT 0,0,0,0, rect_E230

        .byte   $00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00

LE256:
        .byte   $00,$00,$00,$00

.proc menu_click_params
menu_id:.byte   0
item_num:.byte  0
.endproc

LE25C:  .byte   0
LE25D:  .byte   0
        .byte   $00,$00,$00,$00
        .byte   $00,$04,$00,$00,$00

.proc checkitem_params
menu_id:        .byte   4
menu_item:      .byte   0
check:          .byte   0
.endproc

.proc disablemenu_params
menu_id:        .byte   4
disable:        .byte   0
.endproc

.proc disableitem_params
menu_id:        .byte   0
menu_item:      .byte   0
disable:        .byte   0
.endproc

LE26F:  .byte   $00

LE270:  .byte   $04             ; number of items in startup menu?

        .byte   $00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

        .addr   str_all

LE27C:  DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM sd0s
        DEFINE_MENU_ITEM sd1s
        DEFINE_MENU_ITEM sd2s
        DEFINE_MENU_ITEM sd3s
        DEFINE_MENU_ITEM sd4s
        DEFINE_MENU_ITEM sd5s
        DEFINE_MENU_ITEM sd6s
        DEFINE_MENU_ITEM sd7s
        DEFINE_MENU_ITEM sd8s
        DEFINE_MENU_ITEM sd9s
        DEFINE_MENU_ITEM sd10s
        DEFINE_MENU_ITEM sd11s
        DEFINE_MENU_ITEM sd12s
        DEFINE_MENU_ITEM sd13s

startup_menu:
        DEFINE_MENU 7
        DEFINE_MENU_ITEM startup_menu_item_1
        DEFINE_MENU_ITEM startup_menu_item_2
        DEFINE_MENU_ITEM startup_menu_item_3
        DEFINE_MENU_ITEM startup_menu_item_4
        DEFINE_MENU_ITEM startup_menu_item_5
        DEFINE_MENU_ITEM startup_menu_item_6
        DEFINE_MENU_ITEM startup_menu_item_7

str_all:PASCAL_STRING "All"

sd0:    DEFINE_STRING "Slot    drive       ", sd0s
sd1:    DEFINE_STRING "Slot    drive       ", sd1s
sd2:    DEFINE_STRING "Slot    drive       ", sd2s
sd3:    DEFINE_STRING "Slot    drive       ", sd3s
sd4:    DEFINE_STRING "Slot    drive       ", sd4s
sd5:    DEFINE_STRING "Slot    drive       ", sd5s
sd6:    DEFINE_STRING "Slot    drive       ", sd6s
sd7:    DEFINE_STRING "Slot    drive       ", sd7s
sd8:    DEFINE_STRING "Slot    drive       ", sd8s
sd9:    DEFINE_STRING "Slot    drive       ", sd9s
sd10:   DEFINE_STRING "Slot    drive       ", sd10s
sd11:   DEFINE_STRING "Slot    drive       ", sd11s
sd12:   DEFINE_STRING "Slot    drive       ", sd12s
sd13:   DEFINE_STRING "Slot    drive       ", sd13s

startup_menu_item_1:    PASCAL_STRING "Slot 0 "
startup_menu_item_2:    PASCAL_STRING "Slot 0 "
startup_menu_item_3:    PASCAL_STRING "Slot 0 "
startup_menu_item_4:    PASCAL_STRING "Slot 0 "
startup_menu_item_5:    PASCAL_STRING "Slot 0 "
startup_menu_item_6:    PASCAL_STRING "Slot 0 "
startup_menu_item_7:    PASCAL_STRING "Slot 0 "

        .addr   sd0, sd1, sd2, sd3, sd4, sd5, sd6, sd7
        .addr   sd8, sd9, sd10, sd11, sd12, sd13

str_profile_slot_x:
        PASCAL_STRING "ProFile Slot x     "
str_unidisk_xy:
        PASCAL_STRING "UniDisk 3.5  Sx,y  "
str_ramcard_slot_x:
        PASCAL_STRING "RAMCard Slot x      "
str_slot_drive:
        PASCAL_STRING "Slot    drive       "

selector_menu:
        DEFINE_MENU 5
        DEFINE_MENU_ITEM label_add
        DEFINE_MENU_ITEM label_edit
        DEFINE_MENU_ITEM label_del
        DEFINE_MENU_ITEM label_run, '0', '0'
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM run_list_entries + 0 * $10, '1', '1'
        DEFINE_MENU_ITEM run_list_entries + 1 * $10, '2', '2'
        DEFINE_MENU_ITEM run_list_entries + 2 * $10, '3', '3'
        DEFINE_MENU_ITEM run_list_entries + 3 * $10, '4', '4'
        DEFINE_MENU_ITEM run_list_entries + 4 * $10, '5', '5'
        DEFINE_MENU_ITEM run_list_entries + 5 * $10, '6', '6'
        DEFINE_MENU_ITEM run_list_entries + 6 * $10, '7', '7'
        DEFINE_MENU_ITEM run_list_entries + 7 * $10, '8', '8'

label_add:
        PASCAL_STRING "Add an Entry ..."
label_edit:
        PASCAL_STRING "Edit an Entry ..."
label_del:
        PASCAL_STRING "Delete an Entry ...      "
label_run:
        PASCAL_STRING "Run an Entry ..."

        ;; Apple Menu
apple_menu:
        DEFINE_MENU 1
        DEFINE_MENU_ITEM label_about
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM buf + 0 * $10
        DEFINE_MENU_ITEM buf + 1 * $10
        DEFINE_MENU_ITEM buf + 2 * $10
        DEFINE_MENU_ITEM buf + 3 * $10
        DEFINE_MENU_ITEM buf + 4 * $10
        DEFINE_MENU_ITEM buf + 5 * $10
        DEFINE_MENU_ITEM buf + 6 * $10
        DEFINE_MENU_ITEM buf + 7 * $10

label_about:
        PASCAL_STRING "About Apple II DeskTop ... "

buf:    .res    $80, 0

splash_menu:
        DEFINE_MENU_BAR 1
        DEFINE_MENU_BAR_ITEM 1, splash_menu_label, dummy_dd_menu

blank_menu:
        DEFINE_MENU_BAR 1
        DEFINE_MENU_BAR_ITEM 1, blank_dd_label, dummy_dd_menu

dummy_dd_menu:
        DEFINE_MENU 1
        DEFINE_MENU_ITEM dummy_dd_item

splash_menu_label:
        PASCAL_STRING "Apple II DeskTop Version 1.1"

blank_dd_label:
        PASCAL_STRING " "
dummy_dd_item:
        PASCAL_STRING "Rien"    ; ???

        ;; DT_UNHIGHLIGHT_ICON params
icon_params2:
        .byte   0

LE6BF:  .word   0

LE6C1:
        .addr   winfo1title_ptr
        .addr   winfo2title_ptr
        .addr   winfo3title_ptr
        .addr   winfo4title_ptr
        .addr   winfo5title_ptr
        .addr   winfo6title_ptr
        .addr   winfo7title_ptr
        .addr   winfo8title_ptr

win_buf_table:                  ; ???
        .res    8, 0

pos_col_name: DEFINE_POINT 0, 0, pos_col_name
pos_col_type: DEFINE_POINT 112, 0, pos_col_type
pos_col_size: DEFINE_POINT 140, 0, pos_col_size
pos_col_date: DEFINE_POINT 231, 0, pos_col_date

.proc text_buffer2
        .addr   data
length: .byte   0
data:   .res    49, 0
.endproc

LE71D:  .word   0
LE71F:  .byte   0
        .byte   0,0,0

;;; ============================================================

.macro WINFO_DEFN id, label, buflabel
.proc label
window_id:      .byte   id
options:        .byte   MGTK::option_go_away_box | MGTK::option_grow_box
title:          .addr   buflabel
hscroll:        .byte   MGTK::scroll_option_normal
vscroll:        .byte   MGTK::scroll_option_normal
hthumbmax:      .byte   3
hthumbpos:      .byte   0
vthumbmax:      .byte   3
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   170
maxcontwidth:   .word   50
mincontlength:  .word   545
maxcontlength:  .word   175
port:
viewloc:        DEFINE_POINT 20, 27
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, 440, 120
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc

buflabel:       .res    18, 0
.endmacro

        WINFO_DEFN 1, winfo1, winfo1title_ptr
        WINFO_DEFN 2, winfo2, winfo2title_ptr
        WINFO_DEFN 3, winfo3, winfo3title_ptr
        WINFO_DEFN 4, winfo4, winfo4title_ptr
        WINFO_DEFN 5, winfo5, winfo5title_ptr
        WINFO_DEFN 6, winfo6, winfo6title_ptr
        WINFO_DEFN 7, winfo7, winfo7title_ptr
        WINFO_DEFN 8, winfo8, winfo8title_ptr


;;; ============================================================

;;; Window paths
;;; 8 entries; each entry is 65 bytes long
;;; * length-prefixed path string (no trailing /)
;;; Windows 1...8 (since 0 is desktop)
window_path_table:
        .res    (8*65), 0

;;; Window used/free (in kilobytes)
;;; Two tables, 8 entries each
;;; Windows 1...8 (since 0 is desktop)
window_k_used_table:  .res    16, 0
window_k_free_table:  .res    16, 0

        .res    8, 0            ; ???

;;; ============================================================
;;; Resources for window header (Items/k in disk/available)

str_items:
        PASCAL_STRING " Items"

items_label_pos:
        DEFINE_POINT 8, 10, items_label_pos

header_line_left: DEFINE_POINT 0, 0, header_line_left
header_line_right:    DEFINE_POINT 0, 0, header_line_right

str_k_in_disk:
        PASCAL_STRING "K in disk"

str_k_available:
        PASCAL_STRING "K available"

str_from_int:                   ; populated by int_to_string
        PASCAL_STRING "      "

;;; Computed during startup
width_items_label_padded:       .word   0
        .word   0               ; ???
width_left_labels:      .word   0
        .word   0               ; ???

;;; Computed when painted
pos_k_in_disk:  DEFINE_POINT 0, 0, pos_k_in_disk
pos_k_available:        DEFINE_POINT 0, 0, pos_k_available

;;; Computed during startup
width_items_label:      .word   0
width_k_in_disk_label:  .word   0
width_k_available_label:        .word   0
width_right_labels:     .word   0

;;; Assigned during startup
trash_icon_num:  .byte   0

LEBFC:  .byte   0               ; flag of some sort ???

saved_event_coords: DEFINE_POINT 0, 0

;;; ============================================================

;;; Each buffer is a list of icons in each window (0=desktop)
;;; window_icon_count_table = start of buffer = icon count
;;; window_icon_list_table = first entry in buffer (length = 127)

window_icon_count_table:
        .repeat 9,i
        .addr   $1B00 + $80 * i
        .endrepeat

window_icon_list_table:
        .repeat 9,i
        .addr   $1B00 + $80 * i + 1
        .endrepeat

active_window_id:
        .byte   $00

LEC26:  .res    8, 0           ; ???
LEC2E:  .res    21, 0          ; ???
LEC43:  .res    16, 0          ; ???
LEC53:  .byte   0
LEC54:  .word   0
        .res    4, 0

date:  .word   0

        .res    7, 0            ; ???

        .assert * = $EC63, error, "Segment length mismatch"

;;; --------------------------------------------------

icon_entries:
        .byte   0, 0, 0, $F4, 1, $A0 ; overwritten ???
        PAD_TO $ED00

;;; (there's enough room here for 127 files at 27 bytes each)

;;; ============================================================

        .org $FB00

type_table_addr:  .addr type_table
type_icons_addr:  .addr type_icons
icon_type_table_addr:  .addr icon_type_table
type_names_addr:  .addr type_names

type_table:
        .byte   8               ; size of table; first entry is default
        .byte   FT_TYPELESS, FT_SRC, FT_TEXT, FT_BINARY
        .byte   FT_DIRECTORY, FT_SYSTEM, FT_BASIC, FT_BAD

icon_type_table:
        .byte   $60             ; unused?
        .byte   $50,$50,$50,$20,$00,$10,$30,$10

type_names:
        .byte   " ???"

        ;; Same order as icon list below
        .byte   " ???", " SRC", " TXT", " BIN"
        .byte   " DIR", " SYS", " BAS", " SYS"

        .byte   " BAD"

type_icons:
        .addr  gen, src, txt, bin, dir, sys, bas, app

.macro  DEFICON mapbits, mapwidth, x1, y1, x2, y2
        .addr   mapbits
        .byte   mapwidth
        .byte   0               ; reserved
        .word   x1, y1, x2, y2
.endmacro

gen:    DEFICON generic_icon, 4, 0, 0, 27, 17
src:
txt:    DEFICON text_icon, 4, 0, 0, 27, 17
bin:    DEFICON binary_icon, 4, 0, 0, 27, 17
dir:    DEFICON folder_icon, 4, 0, 0, 27, 17
sys:    DEFICON sys_icon, 4, 0, 0, 27, 17
bas:    DEFICON basic_icon, 4, 0, 0, 27, 17
app:    DEFICON app_icon, 5, 0, 0, 34, 17

;;; Generic

generic_icon:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1000000)
        .byte   px(%1000000),px(%0000000),PX(%0000001),px(%1100000)
        .byte   px(%1000000),px(%0000000),PX(%0000001),px(%0110000)
        .byte   px(%1000000),px(%0000000),PX(%0000001),px(%0011000)
        .byte   px(%1000000),px(%0000000),PX(%0000001),PX(%0001100)
        .byte   px(%1000000),px(%0000000),PX(%0000001),PX(%0000110)
        .byte   px(%1000000),px(%0000000),PX(%0000001),PX(%0000011)
        .byte   px(%1000000),px(%0000000),PX(%0000001),PX(%1111111)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)

generic_mask:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1100000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1110000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)

;;; Text File

text_icon:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1000000)
        .byte   px(%1000000),px(%0000000),PX(%0000001),px(%1100000)
        .byte   px(%1001100),px(%0111110),PX(%0111111),px(%0110000)
        .byte   px(%1000000),px(%0000000),PX(%0000001),px(%0011000)
        .byte   px(%1001111),px(%1100111),px(%1000001),PX(%0001100)
        .byte   px(%1000000),px(%0000000),px(%0000001),px(%0000110)
        .byte   px(%1001111),px(%0011110),px(%0110001),PX(%0000011)
        .byte   px(%1000000),px(%0000000),PX(%0000001),PX(%1111111)
        .byte   px(%1000000),px(%0000000),px(%0000000),px(%0000001)
        .byte   px(%1001111),px(%1100110),px(%0111100),px(%1111001)
        .byte   px(%1000000),px(%0000000),px(%0000000),px(%0000001)
        .byte   px(%1001111),px(%0011110),px(%1111111),px(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1001111),px(%0011111),px(%1001111),px(%1100001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)

text_mask:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1100000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1110000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),px(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)

;;; Binary

binary_icon:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),PX(%0000001),px(%1000000),px(%0000000)
        .byte   px(%0000000),px(%0000110),px(%0110000),px(%0000000)
        .byte   px(%0000000),px(%0011000),px(%0001100),px(%0000000)
        .byte   px(%0000000),px(%1100000),px(%0000011),px(%0000000)
        .byte   px(%0000011),px(%0000000),px(%0000000),px(%1100000)
        .byte   px(%0001100),px(%0011000),px(%0011000),px(%0011000)
        .byte   px(%0110000),px(%0100100),px(%0101000),px(%0000110)
        .byte   px(%1000000),px(%0100100),px(%0001000),px(%0000001)
        .byte   px(%0110000),px(%0100100),px(%0001000),px(%0000110)
        .byte   px(%0001100),px(%0011000),px(%0001000),px(%0011000)
        .byte   px(%0000011),px(%0000000),px(%0000000),px(%1100000)
        .byte   px(%0000000),px(%1100000),px(%0000011),px(%0000000)
        .byte   px(%0000000),px(%0011000),px(%0001100),px(%0000000)
        .byte   px(%0000000),px(%0000110),px(%0110000),px(%0000000)
        .byte   px(%0000000),PX(%0000001),px(%1000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)

binary_mask:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),PX(%0000001),px(%1000000),px(%0000000)
        .byte   px(%0000000),px(%0000111),px(%1110000),px(%0000000)
        .byte   px(%0000000),PX(%0011111),px(%1111100),px(%0000000)
        .byte   px(%0000000),PX(%1111111),PX(%1111111),px(%0000000)
        .byte   px(%0000011),PX(%1111111),PX(%1111111),px(%1100000)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),px(%1111000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),px(%1111110)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),px(%1111000)
        .byte   px(%0000011),PX(%1111111),PX(%1111111),px(%1100000)
        .byte   px(%0000000),PX(%1111111),PX(%1111111),px(%0000000)
        .byte   px(%0000000),PX(%0011111),px(%1111100),px(%0000000)
        .byte   px(%0000000),px(%0000111),px(%1110000),px(%0000000)
        .byte   px(%0000000),PX(%0000001),px(%1000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)

;;; Folder
folder_icon:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0011111),px(%1111110),px(%0000000),px(%0000000)
        .byte   px(%0100000),px(%0000001),px(%0000000),px(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),px(%1111110)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   px(%1000000),px(%0000000),px(%0000000),PX(%0000001)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),px(%1111110)

folder_mask:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0011111),px(%1111110),px(%0000000),px(%0000000)
        .byte   PX(%0111111),PX(%1111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),px(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),px(%1111110)

;;; System (no .SYSTEM suffix)

sys_icon:
        .byte   px(%0001111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0110000),px(%0000000),px(%0000000),px(%0000110)
        .byte   px(%0110011),px(%1111111),px(%1111111),px(%1100110)
        .byte   px(%0110011),px(%0000000),px(%0010000),px(%1100110)
        .byte   px(%0110011),px(%0000000),px(%0100000),px(%1100110)
        .byte   px(%0110011),px(%0010000),px(%1000100),px(%1100110)
        .byte   px(%0110011),px(%0100000),px(%0001000),px(%1100110)
        .byte   px(%0110011),px(%1111111),px(%1111111),px(%1100110)
        .byte   px(%0110000),px(%0000000),px(%0000000),px(%0000110)
        .byte   px(%0001111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%1111111),px(%1111111),px(%1111111),px(%1111111)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000011)
        .byte   px(%1100110),px(%0000000),px(%0000000),px(%0000011)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000011)
        .byte   px(%1111111),px(%1111111),px(%1111111),px(%1111111)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000011)
        .byte   px(%1111111),px(%1111111),px(%1111111),px(%1111111)

sys_mask:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0001111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0001111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0001111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0001111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0001111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0001111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0001111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0001111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)

;;; Basic

basic_icon:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),PX(%0000001),px(%1000000),px(%0000000)
        .byte   px(%0000000),px(%0000110),px(%0110000),px(%0000000)
        .byte   px(%0000000),px(%0011000),px(%0001100),px(%0000000)
        .byte   px(%0000000),px(%1100000),px(%0000011),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0111110),px(%0111000),px(%1111010),px(%0111100)
        .byte   px(%0100010),px(%1000100),px(%1000010),px(%1000110)
        .byte   px(%0111100),px(%1111100),px(%1111010),px(%1000000)
        .byte   px(%0100010),px(%1000100),px(%0001010),px(%1000110)
        .byte   px(%0111110),px(%1000100),px(%1111010),px(%0111100)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%1100000),px(%0000011),px(%0000000)
        .byte   px(%0000000),px(%0011000),px(%0001100),px(%0000000)
        .byte   px(%0000000),px(%0000110),px(%0110000),px(%0000000)
        .byte   px(%0000000),PX(%0000001),px(%1000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)

basic_mask:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),PX(%0000001),px(%1000000),px(%0000000)
        .byte   px(%0000000),px(%0000111),px(%1110000),px(%0000000)
        .byte   px(%0000000),PX(%0011111),px(%1111100),px(%0000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   px(%0000000),PX(%0011111),px(%1111100),px(%0000000)
        .byte   px(%0000000),px(%0000111),px(%1110000),px(%0000000)
        .byte   px(%0000000),PX(%0000001),px(%1000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000)

;;; System (with .SYSTEM suffix)

app_icon:
        .byte   px(%0000000),px(%0000000),px(%0011000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%1100110),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000011),px(%0000001),px(%1000000),px(%0000000)
        .byte   px(%0000000),px(%0001100),px(%0000000),px(%0110000),px(%0000000)
        .byte   px(%0000000),px(%0110000),px(%0000000),px(%0001100),px(%0000000)
        .byte   px(%0000001),px(%1000000),px(%0000000),px(%0000011),px(%0000000)
        .byte   px(%0000110),px(%0000000),px(%0000000),px(%0000000),px(%1100000)
        .byte   px(%0011000),px(%0000000),px(%0000001),px(%1111100),px(%0011000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000011),px(%0000110)
        .byte   px(%0011000),px(%0000000),px(%0011000),px(%1110000),px(%1111000)
        .byte   px(%0000110),px(%0000111),px(%1111111),px(%1111100),px(%0011110)
        .byte   px(%0000001),px(%1000000),px(%0110000),px(%1100000),px(%0011110)
        .byte   px(%0000000),px(%0110000),px(%0001110),px(%0000000),px(%0011110)
        .byte   px(%0000000),px(%0001100),px(%0000001),PX(%1111111),px(%1111110)
        .byte   px(%0000000),px(%0000011),px(%0000001),px(%1000000),px(%0011110)
        .byte   px(%0000000),px(%0000000),px(%1100110),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0011000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)

app_mask:
        .byte   px(%0000000),px(%0000000),px(%0011000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%1111110),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000011),px(%1111111),px(%1000000),px(%0000000)
        .byte   px(%0000000),px(%0001111),px(%1111111),px(%1110000),px(%0000000)
        .byte   px(%0000000),px(%0111111),px(%1111111),px(%1111100),px(%0000000)
        .byte   px(%0000001),px(%1111111),px(%1111111),px(%1111111),px(%0000000)
        .byte   px(%0000111),px(%1111111),px(%1111111),px(%1111111),px(%1100000)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110)
        .byte   px(%0011111),px(%1111111),px(%1111111),px(%1111111),px(%1111100)
        .byte   px(%0000111),px(%1111111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0000001),px(%1111111),px(%1111111),px(%1111111),px(%1111000)
        .byte   px(%0000000),px(%0111111),px(%1111111),px(%1111100),px(%1111000)
        .byte   px(%0000000),px(%0001111),px(%1111111),px(%1111000),px(%0000000)
        .byte   px(%0000000),px(%0000011),px(%1111111),px(%1000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%1111110),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0011000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
