;;; ============================================================
;;; DeskTop - Resources
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into AUX $D200-$ECFF
;;; ============================================================

        ASSERT_ADDRESS $D200

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

.params getwinport_params2
window_id:     .byte   0
a_grafport:     .addr   window_grafport
.endparams

;;; GrafPort used specifically for operations that draw into windows.

.params window_grafport
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 0, 0, cliprect
penpattern:     .res    8, 0
colormasks:     .byte   0, 0
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_black
fontptr:        .addr   0
.endparams

;;; GrafPort used for nearly all operations. Usually re-initialized
;;; before use.

.params main_grafport
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 0, 0, cliprect
penpattern:     .res    8, 0
colormasks:     .byte   0, 0
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_black
fontptr:        .addr   0
.endparams
        main_grafport_viewloc_xcoord := main_grafport::viewloc::xcoord
        main_grafport_cliprect_x1 := main_grafport::cliprect::x1
        main_grafport_cliprect_x2 := main_grafport::cliprect::x2
        main_grafport_cliprect_y2 := main_grafport::cliprect::y2


;;; GrafPort used specifically when setting/clearing icon highlights,
;;; since icons are in screen space coordinates.

.params highlight_grafport
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 10, 10, cliprect
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_black
fontptr:        .addr   DEFAULT_FONT
.endparams

;;; ============================================================

        ;; Copies of ROM bytes used for machine identification
.params startdesktop_params
machine:        .byte   $06     ; ROM FBB3 ($06 = IIe or later)
subid:          .byte   $EA     ; ROM FBC0 ($EA = IIe, $E0 = IIe enh/IIgs, $00 = IIc/IIc+)
op_sys:         .byte   0       ; 0=ProDOS
slot_num:       .byte   0       ; Mouse slot, 0 = search
use_interrupts: .byte   0       ; 0=passive
sysfontptr:     .addr   DEFAULT_FONT
savearea:       .addr   SAVE_AREA_BUFFER
savesize:       .word   kSaveAreaSize
.endparams

.params initmenu_params
solid_char:     .byte   kGlyphSolidApple
open_char:      .byte   kGlyphOpenApple
check_char:     .byte   kGlyphCheckmark
control_char:   .byte   '^'
.endparams

zp_use_flag0:
        .byte   0

.params trackgoaway_params
goaway:.byte   0
.endparams

double_click_flag:
        .byte   0               ; high bit clear if double-clicked, set otherwise

        ;; Set to specific machine type
machine_type:
        .byte   $00             ; Set to: $96 = IIe, $FA = IIc, $FD = IIgs

warning_dialog_num:
        .byte   $00

;;; Cursors (bitmap - 2x12 bytes, mask - 2x12 bytes, hotspot - 2 bytes)

;;; Pointer

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

;;; Insertion Point
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

;;; Watch
watch_cursor:
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%0011111),PX(%1100000)
        .byte   PX(%0011111),PX(%1100000)
        .byte   PX(%0100000),PX(%0010000)
        .byte   PX(%0100001),PX(%0010000)
        .byte   PX(%0100110),PX(%0011000)
        .byte   PX(%0100000),PX(%0010000)
        .byte   PX(%0100000),PX(%0010000)
        .byte   PX(%0011111),PX(%1100000)
        .byte   PX(%0011111),PX(%1100000)
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%0011111),PX(%1100000)
        .byte   PX(%0111111),PX(%1110000)
        .byte   PX(%0111111),PX(%1110000)
        .byte   PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111000)
        .byte   PX(%0111111),PX(%1110000)
        .byte   PX(%0111111),PX(%1110000)
        .byte   PX(%0011111),PX(%1100000)
        .byte   PX(%0000000),PX(%0000000)
        .byte   5, 5

.params scalemouse_params
x_exponent:     .byte   1       ; MGTK default is x 2:1 and y 1:1
y_exponent:     .byte   0       ; ... doubled on IIc / IIc+
.endparams

num_selector_list_items:
        .byte   0

LD344:  .byte   0
buf_filename2:  .res    16, 0
buf_win_path:   .res    43, 0

temp_string_buf:
        .res    kPathBufferSize, 0

        ;; used when splitting string for text field
split_buf:
        .res    kPathBufferSize, 0

;;; In common dialog (copy/edit file, add/edit selector entry):
;;; * path_buf0 has the contents of the top input field
;;; * path_buf1 has the contents of the bottom input field
;;; * path_buf2 has the contents of the focused field after insertion point
;;;   (May have leading caret glyph $06)

path_buf0:  .res    kPathBufferSize, 0
path_buf1:  .res    kPathBufferSize, 0
path_buf2:  .res    kPathBufferSize, 0

;;; ============================================================
;;; Dialog used for prompts (yes/no/all) and operation progress

kPromptDialogWindowID = $0F

.params winfo_prompt_dialog
        kWidth = aux::kPromptDialogWidth
        kHeight = aux::kPromptDialogHeight

window_id:      .byte   kPromptDialogWindowID
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
viewloc:        DEFINE_POINT (kScreenWidth - kWidth) / 2, (kScreenHeight - kHeight) / 2
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
cliprect:       DEFINE_RECT 0, 0, kWidth, kHeight
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

;;; ============================================================
;;; Dialog used for Selector > Add/Edit an Entry...

kFilePickerDlgWindowID  = $12
kFilePickerDlgWidth     = 500
kFilePickerDlgHeight    = 153

.params winfo_file_dialog
        kWidth = kFilePickerDlgWidth
        kHeight = kFilePickerDlgHeight

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
viewloc:        DEFINE_POINT (kScreenWidth - kWidth) / 2, (kScreenHeight - kHeight) / 2
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
cliprect:       DEFINE_RECT 0, 0, kFilePickerDlgWidth, kFilePickerDlgHeight
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

;;; File picker within Add/Edit an Entry dialog

kEntryListCtlWindowID = $15

.params winfo_file_dialog_listbox
window_id:      .byte   kEntryListCtlWindowID
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
mincontlength:  .word   70
maxcontwidth:   .word   100
maxcontlength:  .word   70
port:
viewloc:        DEFINE_POINT 53, 50
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
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
.endparams

;;; "About Apple II DeskTop" Dialog

.params winfo_about_dialog
        kWidth = aux::kAboutDialogWidth
        kHeight = aux::kAboutDialogHeight

window_id:      .byte   $18
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
viewloc:        DEFINE_POINT (kScreenWidth - kWidth) / 2, (kScreenHeight - kHeight) / 2

mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
cliprect:       DEFINE_RECT 0, 0, kWidth, kHeight
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams
winfo_about_dialog_port    := winfo_about_dialog::port

;;; Dialog used for Edit/Delete/Run an Entry ...

kEntryDialogWindowID = $1B

.params winfo_entry_picker
        kWidth = 350
        kHeight = 118

window_id:      .byte   kEntryDialogWindowID
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
viewloc:        DEFINE_POINT (kScreenWidth - kWidth) / 2, (kScreenHeight - kHeight) / 2
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
cliprect:       DEFINE_RECT 0, 0, kWidth, kHeight
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

name_input_rect:  DEFINE_RECT 40,61+6,360,71+6, name_input_rect
name_input_textpos: DEFINE_POINT 45,70+6, name_input_textpos
pos_dialog_title: DEFINE_POINT 0, 18, pos_dialog_title

dialog_label_base_pos:
        DEFINE_POINT 40,35-5, dialog_label_base_pos

        kDialogLabelDefaultX = 40
dialog_label_pos:
        DEFINE_POINT kDialogLabelDefaultX,0, dialog_label_pos

.params name_input_mapinfo
        DEFINE_POINT 80, 35+7
        .addr   MGTK::screen_mapbits
        .byte   MGTK::screen_mapwidth
        .byte   0
        DEFINE_RECT 0, 0, 358, 100
.endparams

        kEntryPickerItemHeight = 9 ; default font height

entry_picker_outer_rect:
        DEFINE_RECT_INSET 4,2,winfo_entry_picker::kWidth,winfo_entry_picker::kHeight
entry_picker_inner_rect:
        DEFINE_RECT_INSET 5,3,winfo_entry_picker::kWidth,winfo_entry_picker::kHeight

        ;; Line endpoints
entry_picker_line1_start:
        DEFINE_POINT 6,22
entry_picker_line1_end:
        DEFINE_POINT 344,22

        ;; Line endpoints
entry_picker_line2_start:
        DEFINE_POINT 6,winfo_entry_picker::kHeight-21
entry_picker_line2_end:
        DEFINE_POINT 344,winfo_entry_picker::kHeight-21

entry_picker_ok_rect:
        DEFINE_RECT_SZ 210,winfo_entry_picker::kHeight-18,kButtonWidth,kButtonHeight

entry_picker_cancel_rect:
        DEFINE_RECT_SZ 40,winfo_entry_picker::kHeight-18,kButtonWidth,kButtonHeight

entry_picker_ok_pos:
        DEFINE_POINT 215,winfo_entry_picker::kHeight-8
entry_picker_cancel_pos:
        DEFINE_POINT 45,winfo_entry_picker::kHeight-8

add_an_entry_label:
        PASCAL_STRING "Add an Entry..." ; dialog title
edit_an_entry_label:
        PASCAL_STRING "Edit an Entry..." ; dialog title
delete_an_entry_label:
        PASCAL_STRING "Delete an Entry..." ; dialog title
run_an_entry_label:
        PASCAL_STRING "Run an Entry..." ; dialog title

enter_the_full_pathname_label1:
        PASCAL_STRING "Enter the full pathname of the run list file:"
enter_the_name_to_appear_label:
        PASCAL_STRING "Enter the name (14 characters max)  you wish to appear in the run list"

        DEFINE_LABEL add_a_new_entry_to, "Add a new entry to the:",            343, 39
        DEFINE_LABEL run_list,           {kGlyphOpenApple,"1 Run list"},       363, 48
        DEFINE_LABEL other_run_list,     {kGlyphOpenApple,"2 Other Run list"}, 363, 57
        DEFINE_LABEL down_load,          "Copy to RAMCard:",                   343, 73
        DEFINE_LABEL at_first_boot,      {kGlyphOpenApple,"3 at first boot"},  363, 82
        DEFINE_LABEL at_first_use,       {kGlyphOpenApple,"4 at first use"},   363, 91
        DEFINE_LABEL never,              {kGlyphOpenApple,"5 never"},          363,100

enter_the_full_pathname_label2:
        PASCAL_STRING "Enter the full pathname of the run list file:"

entry_picker_item_rect:
        DEFINE_RECT 0,0,0,0,entry_picker_item_rect

entry_picker_all_items_rect:
        DEFINE_RECT 6,23,344,winfo_entry_picker::kHeight-23

;;; In Format/Erase Disk picker dialog, this is the selected index (0-based),
;;; or $FF if no drive is selected
selected_device_index:
        .byte   0

select_volume_rect:
        DEFINE_RECT 0,0,0,0,select_volume_rect

;;; Used in Format/Erase dialogs
num_volumes:
        .byte   0

the_dos_33_disk_label:
        PASCAL_STRING "the DOS 3.3 disk in slot # drive # ?"
        kTheDos33DiskSlotCharOffset = 26
        kTheDos33DiskDriveCharOffset = 34

the_disk_in_slot_label:
        PASCAL_STRING "the disk in slot # drive # ?"
        kTheDiskInSlotSlotCharOffset = 18
        kTheDiskInSlotDriveCharOffset = 26

buf_filename:
        .res    16, 0

LD8E7:  .byte   0
has_input_field_flag:
        .byte   0

prompt_ip_counter:
        .byte   1               ; immediately decremented to 0 and reset

prompt_ip_flag:
        .byte   0

;;; Flag that controls the behavior of the file dialog picker.
LD8EC:  .byte   0

format_erase_overlay_flag:
        .byte   0

str_insertion_point:
        PASCAL_STRING {kGlyphInsertionPoint} ; do not localize

;;; Flags that control the behavior of the file picker dialog.

LD8F0:  .byte   0
LD8F1:  .byte   0
LD8F2:  .byte   0
LD8F3:  .byte   0
LD8F4:  .byte   0
LD8F5:  .byte   0

        ;; Used to draw/clear insertion point; overwritten with char
        ;; to right of insertion point as needed.
str_1_char:
        PASCAL_STRING {0}       ; do not localize

        ;; Used as suffix for text being edited to account for insertion
        ;; point adding extra width.
str_2_spaces:
        PASCAL_STRING "  "      ; do not localize

str_files:
        PASCAL_STRING "Files"
str_file_count:                 ; populated with number of files
        PASCAL_STRING " ##,### " ; do not localize

str_kb_suffix:
        PASCAL_STRING "K"       ; suffix for kilobytes

        ;; This location also used as path buffer by ovl_format_erase
ovl_path_buf:

file_count:
        .word   0

pos_D90B:
        DEFINE_POINT 0,13

rect_D90F:
        DEFINE_RECT 0,0,125,0

picker_entry_pos:
        DEFINE_POINT 2,0

        .byte   $00,$00

str_folder:
        PASCAL_STRING {kGlyphFolderLeft, kGlyphFolderRight} ; do not localize

selected_index:                 ; $FF if none
        .byte   0


LD921:  .byte   0


kRadioButtonWidth = 10
kRadioButtonHeight = 6

rect_run_list_radiobtn:
        DEFINE_RECT_SZ 346,41,kRadioButtonWidth,kRadioButtonHeight
rect_other_run_list_radiobtn:
        DEFINE_RECT_SZ 346,50,kRadioButtonWidth,kRadioButtonHeight
rect_at_first_boot_radiobtn:
        DEFINE_RECT_SZ 346,75,kRadioButtonWidth,kRadioButtonHeight
rect_at_first_use_radiobtn:
        DEFINE_RECT_SZ 346,84,kRadioButtonWidth,kRadioButtonHeight
rect_never_radiobtn:
        DEFINE_RECT_SZ 346,93,kRadioButtonWidth,kRadioButtonHeight

kRadioControlWidth = 134
kRadioControlHeight = 8

rect_run_list_ctrl:
        DEFINE_RECT_SZ 346,40,kRadioControlWidth,kRadioControlHeight
rect_other_run_list_ctrl:
        DEFINE_RECT_SZ 346,49,kRadioControlWidth,kRadioControlHeight
rect_at_first_boot_ctrl:
        DEFINE_RECT_SZ 346,74,kRadioControlWidth,kRadioControlHeight
rect_at_first_use_ctrl:
        DEFINE_RECT_SZ 346,83,kRadioControlWidth,kRadioControlHeight
rect_never_ctrl:
        DEFINE_RECT_SZ 346,92,kRadioControlWidth,kRadioControlHeight

rect_scratch:
        DEFINE_RECT 0,0,0,0, rect_scratch

;;; ============================================================

.scope file_dialog_res

dialog_frame_rect:
        DEFINE_RECT_INSET 4,2,kFilePickerDlgWidth,kFilePickerDlgHeight

rect_D9C8:
        DEFINE_RECT 27,16,174,26

        DEFINE_BUTTON close, "Close", 193,58
        DEFINE_BUTTON ok, {"OK            ",kGlyphReturn}, 193,89
        DEFINE_BUTTON open, "Open", 193,44
        DEFINE_BUTTON cancel, "Cancel        Esc", 193,73
        DEFINE_BUTTON change_drive, "Change Drive", 193,30

dialog_sep_start:
        DEFINE_POINT 323,30
dialog_sep_end:
        DEFINE_POINT 323,100

        .byte   $81,$D3,$00

        DEFINE_LABEL disk, " Disk: ", 28,25

input1_label_pos:
        DEFINE_POINT   28,112
input2_label_pos:
        DEFINE_POINT   28,135

textbg1:
        .byte   $00
textbg2:
        .byte   $7F

copy_a_file_label:
        PASCAL_STRING "Copy a File..." ; dialog title

source_filename_label:
        PASCAL_STRING "Source filename:"

destination_filename_label:
        PASCAL_STRING "Destination filename:"

kCommonInputWidth = 435
kCommonInputHeight = 11

input1_rect:   DEFINE_RECT_SZ 28, 113, kCommonInputWidth, kCommonInputHeight
input1_textpos:      DEFINE_POINT 30,123

input2_rect:   DEFINE_RECT_SZ 28, 136, kCommonInputWidth, kCommonInputHeight
input2_textpos:      DEFINE_POINT 30,146

delete_a_file_label:
        PASCAL_STRING "Delete a File..." ; dialog title

file_to_delete_label:
        PASCAL_STRING "File to delete:"

.endscope

;;; ============================================================
;;; Resources for clock on menu bar

pos_clock:
        DEFINE_POINT 475, 10

str_time:
        PASCAL_STRING "00:00 XM" ; do not localize

str_4_spaces:
        PASCAL_STRING "    "    ; do not localize

dow_strings:
        STRING  "Sun "
        STRING  "Mon "
        STRING  "Tue "
        STRING  "Wed "
        STRING  "Thu "
        STRING  "Fri "
        STRING  "Sat "
        ASSERT_RECORD_TABLE_SIZE dow_strings, 7, 4

.params dow_str_params
addr:   .addr   0
length: .byte   4               ; includes trailing space
.endparams

month_offset_table:             ; for Day-of-Week calculations
        .byte   1,5,6,3,1,5,3,0,4,2,6,4
        ASSERT_TABLE_SIZE month_offset_table, 12

parsed_date:
        .tag ParsedDateTime

;;; ============================================================

;;; 5.25" Floppy Disk
floppy140_icon:
        DEFICON aux::floppy140_pixels, 4, 26, 14, aux::floppy140_mask

;;; RAM Disk
ramdisk_icon:
        DEFICON aux::ramdisk_pixels, 6, 39, 11, aux::ramdisk_mask

;;; 3.5" Floppy Disk
floppy800_icon:
        DEFICON aux::floppy800_pixels, 3, 20, 11, aux::floppy800_mask

;;; Hard Disk
profile_icon:
        DEFICON aux::profile_pixels, 8, 52, 9, aux::profile_mask

;;; File Share
fileshare_icon:
        DEFICON aux::fileshare_pixels, 5, 34, 14, aux::fileshare_mask

;;; Trash Can
trash_icon:
        DEFICON aux::trash_pixels, 3, 20, 17, aux::trash_mask


;;; ============================================================
;;; DeskTop icon placement

;;;  +-------------------------+
;;;  |                     1   |
;;;  |                     2   |
;;;  |                     3   |
;;;  |                     4   |
;;;  |        13  12  11   5   |
;;;  | 10  9   8   7   6 Trash |
;;;  +-------------------------+

        kTrashIconX = 506
        kTrashIconY = 160

        kVolIconDeltaY = 29

        kVolIconCol1 = 490
        kVolIconCol2 = 400
        kVolIconCol3 = 310
        kVolIconCol4 = 220
        kVolIconCol5 = 130
        kVolIconCol6 = 40

desktop_icon_coords_table:
        DEFINE_POINT kVolIconCol1,15 + kVolIconDeltaY*0 ; 1
        DEFINE_POINT kVolIconCol1,15 + kVolIconDeltaY*1 ; 2
        DEFINE_POINT kVolIconCol1,15 + kVolIconDeltaY*2 ; 3
        DEFINE_POINT kVolIconCol1,15 + kVolIconDeltaY*3 ; 4
        DEFINE_POINT kVolIconCol1,15 + kVolIconDeltaY*4 ; 5
        DEFINE_POINT kVolIconCol2,kTrashIconY+2         ; 6
        DEFINE_POINT kVolIconCol3,kTrashIconY+2         ; 7
        DEFINE_POINT kVolIconCol4,kTrashIconY+2         ; 8
        DEFINE_POINT kVolIconCol5,kTrashIconY+2         ; 9
        DEFINE_POINT kVolIconCol6,kTrashIconY+2         ; 10
        DEFINE_POINT kVolIconCol2,15 + kVolIconDeltaY*4 ; 11
        DEFINE_POINT kVolIconCol3,15 + kVolIconDeltaY*4 ; 12
        DEFINE_POINT kVolIconCol4,15 + kVolIconDeltaY*4 ; 13
        ;; Maximum of 13 devices:
        ;; 7 slots * 2 drives = 14 (size of DEVLST)
        ;; ... but RAM in Slot 3 Drive 2 is disconnected.
        ASSERT_RECORD_TABLE_SIZE desktop_icon_coords_table, kMaxVolumes, .sizeof(MGTK::Point)
;;; ============================================================

        PAD_TO $DB00

;;; ============================================================

selector_menu_addr:
        .addr   selector_menu

        ;; Buffer for Run List entries
        kMaxRunListEntries = 8

        ;; Names
run_list_entries:
        .res    kMaxRunListEntries * 16, 0

        ;; Paths
run_list_paths:
        .res    kMaxRunListEntries * kSelectorListPathLength, 0

;;; ============================================================
;;; Window & Icon State
;;; ============================================================

        ;; Total number of icons
icon_count:
        .byte   0

        ;; Pointers into icon_entries buffer
icon_entry_address_table:
        .res    256, 0

;;; Copy from aux memory of icon list for active window (0=desktop)

        ;; which window buffer (see window_icon_count_table, window_icon_list_table) is copied
cached_window_id: .byte   0
        ;; number of icons in copied window
cached_window_icon_count:.byte   0
        ;; list of icons in copied window
cached_window_icon_list:   .res    127, 0


;;; Index of window with selection (0=desktop)
selected_window_index:
        .byte   0

;;; Number of selected icons
selected_icon_count:
        .byte   0

;;; Indexes of selected icons (global, not w/in window, up to 127)
selected_icon_list:
        .res    127, 0

kMaxNumWindows = kMaxDeskTopWindows

;;; Table of desktop window winfo addresses
win_table:
        .addr   0,winfo1,winfo2,winfo3,winfo4,winfo5,winfo6,winfo7,winfo8
        ASSERT_ADDRESS_TABLE_SIZE win_table, kMaxNumWindows + 1

;;; Table of desktop window path addresses
window_path_addr_table:
        .addr   $0000
        .repeat 8,i
        .addr   window_path_table+i*kPathBufferSize
        .endrepeat
        ASSERT_ADDRESS_TABLE_SIZE window_path_addr_table, kMaxNumWindows + 1

;;; ============================================================

str_file_type:
        PASCAL_STRING " $00"    ; do not localize

;;; ============================================================

path_buf4:
        .res    kPathBufferSize, 0
path_buf3:
        .res    kPathBufferSize, 0
filename_buf:
        .res    16, 0

        ;; Set to $80 for Copy, $FF for Run
LE05B:  .byte   0

delete_skip_decrement_flag:     ; always set to 0 ???
        .byte   0

process_depth:
        .byte   0               ; tracks recursion depth

;;; Number of file entries per directory block
num_entries_per_block:
        .byte   13

entries_read:
        .byte   0
op_ref_num:
        .byte   0
entries_to_skip:
        .byte   0

;;; During directory traversal, the number of file entries processed
;;; at the current level is pushed here, so that following a descent
;;; the previous entries can be skipped.
entry_count_stack:
        .res    170, 0

entry_count_stack_index:
        .byte   0

entries_read_this_block:
        .byte   0

;;; ============================================================

;;; Backup copy of DEVLST made before detaching ramdisk
devlst_backup:
        .res    kMaxVolumes+1, 0 ; TODO: Why +1?

        ;; index is device number (in DEVLST), value is icon number
device_to_icon_map:
        .res    kMaxVolumes+1, 0 ; TODO: Why +1?

;;; Path buffer for open_directory logic
open_dir_path_buf:
        .res    kPathBufferSize, 0

;;; Window to file record mapping list. Each entry is a window
;;; id. Position in the list is the same as position in the
;;; subsequent file record list.
window_id_to_filerecord_list_count:
        .byte   0
window_id_to_filerecord_list_entries:
        .res    kMaxNumWindows, 0 ; 8 entries + length

;;; Mapping from position in above table to FileRecord entry
window_filerecord_table:
        .res    kMaxNumWindows*2

        ;; IconTK::HighlightIcon params
icon_param2:
        .byte   0

LE22C:  .byte   0

        ;; IconTK::HighlightIcon params
icon_param3:
        .byte   0

redraw_icon_param:
        .byte   0

        ;; IconTK::HighlightIcon params
        ;; IconTK::Icon params
icon_param:  .byte   0

        ;; Used for all sorts of temporary work
        ;; (follows icon_param for IconTK::IconInRect call)
tmp_rect:
        DEFINE_RECT 0,0,0,0, tmp_rect

saved_stack:
        .byte   0

.params menu_click_params       ; used for MGTK::MenuKey as well
menu_id:.byte   0
item_num:.byte  0
which_key:      .byte   0
key_mods:       .byte   0
.endparams

        .byte   $00,$00,$00,$00
        .byte   $00,$04,$00,$00,$00

.params checkitem_params
menu_id:        .byte   4
menu_item:      .byte   0
check:          .byte   0
.endparams

.params disablemenu_params
menu_id:        .byte   4
disable:        .byte   0
.endparams

.params disableitem_params
menu_id:        .byte   0
menu_item:      .byte   0
disable:        .byte   0
.endparams

file_menu_items_enabled_flag:
        .byte   0

startup_menu:
        DEFINE_MENU kMenuSizeStartup
@items: DEFINE_MENU_ITEM startup_menu_item_1
        DEFINE_MENU_ITEM startup_menu_item_2
        DEFINE_MENU_ITEM startup_menu_item_3
        DEFINE_MENU_ITEM startup_menu_item_4
        DEFINE_MENU_ITEM startup_menu_item_5
        DEFINE_MENU_ITEM startup_menu_item_6
        DEFINE_MENU_ITEM startup_menu_item_7
        ASSERT_RECORD_TABLE_SIZE @items, kMenuSizeStartup, .sizeof(MGTK::MenuItem)

;;; ============================================================

;;; Device Names (populated at startup using templates in init.s)
device_name_table:
        .repeat kMaxVolumes+1, i
        .addr   .ident(.sprintf("dev%ds", i))
        .endrepeat
        ASSERT_ADDRESS_TABLE_SIZE device_name_table, kMaxVolumes + 1

        .repeat kMaxVolumes+1, i
        .ident(.sprintf("dev%ds", i)) := *
        .res    20, 0
        .endrepeat

        ;; These strings are padded to be 8 bytes long to ease indexing
startup_menu_item_1:    PASCAL_STRING "Slot #", 7 ; menu item
startup_menu_item_2:    PASCAL_STRING "Slot #", 7 ; menu item
startup_menu_item_3:    PASCAL_STRING "Slot #", 7 ; menu item
startup_menu_item_4:    PASCAL_STRING "Slot #", 7 ; menu item
startup_menu_item_5:    PASCAL_STRING "Slot #", 7 ; menu item
startup_menu_item_6:    PASCAL_STRING "Slot #", 7 ; menu item
startup_menu_item_7:    PASCAL_STRING "Slot #", 7 ; menu item
        ASSERT_RECORD_TABLE_SIZE startup_menu_item_1, 7, 8
        kStartupMenuItemSlotOffset = 6

;;; ============================================================

selector_menu:
        DEFINE_MENU 5
@items: DEFINE_MENU_ITEM label_add
        DEFINE_MENU_ITEM label_edit
        DEFINE_MENU_ITEM label_del
        DEFINE_MENU_ITEM label_run, '0', '0'
        DEFINE_MENU_SEPARATOR
        .repeat kMaxRunListEntries, i
        DEFINE_MENU_ITEM run_list_entries + i * $10, .string(i+1), .string(i+1)
        .endrepeat
        .assert 5 + kMaxRunListEntries = kMenuSizeSelector, error, "Menu size mismatch"
        ASSERT_RECORD_TABLE_SIZE @items, kMenuSizeSelector, .sizeof(MGTK::MenuItem)

        kMenuItemIdSelectorAdd       = 1
        kMenuItemIdSelectorEdit      = 2
        kMenuItemIdSelectorDelete    = 3
        kMenuItemIdSelectorRun       = 4

label_add:
        PASCAL_STRING "Add an Entry..." ; menu item
label_edit:
        PASCAL_STRING "Edit an Entry..." ; menu item
label_del:
        PASCAL_STRING "Delete an Entry..." ; menu item
label_run:
        PASCAL_STRING "Run an Entry..." ; menu item

kDAMenuItemSize = 19            ; length (1) + filename (15) + folder glyphs prefix (3)

        ;; Apple Menu
apple_menu:
        DEFINE_MENU 1
@items: DEFINE_MENU_ITEM label_about
        DEFINE_MENU_SEPARATOR
        .repeat kMaxDeskAccCount, i
        DEFINE_MENU_ITEM desk_acc_names + i * kDAMenuItemSize
        .endrepeat
        .assert 2 + kMaxDeskAccCount = kMenuSizeApple, error, "Menu size mismatch"
        ASSERT_RECORD_TABLE_SIZE @items, kMenuSizeApple, .sizeof(MGTK::MenuItem)

label_about:
        PASCAL_STRING .sprintf("About %s", kDeskTopProductName) ; menu item

desk_acc_names:
        .res    kMaxDeskAccCount * kDAMenuItemSize, 0

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
        PASCAL_STRING .sprintf("%s Version %d.%d%s", kDeskTopProductName, kDeskTopVersionMajor, kDeskTopVersionMinor, kDeskTopVersionSuffix)

blank_dd_label:
        PASCAL_STRING " "       ; do not localize
dummy_dd_item:
        PASCAL_STRING "Rien"    ; French for "nothing" - do not localize

        ;; IconTK::UNHIGHLIGHT_ICON params
icon_params2:
        .byte   0

window_title_addr_table:
        .addr   0
        .addr   winfo1title_ptr
        .addr   winfo2title_ptr
        .addr   winfo3title_ptr
        .addr   winfo4title_ptr
        .addr   winfo5title_ptr
        .addr   winfo6title_ptr
        .addr   winfo7title_ptr
        .addr   winfo8title_ptr
        ASSERT_ADDRESS_TABLE_SIZE window_title_addr_table, kMaxNumWindows + 1

        ;; (low nibble must match menu order)
        kViewByIcon = $00
        kViewByName = $81
        kViewByDate = $82
        kViewBySize = $83
        kViewByType = $84

win_view_by_table:
        .res    kMaxNumWindows, 0

pos_col_name: DEFINE_POINT 0, 0, pos_col_name
pos_col_type: DEFINE_POINT 112, 0, pos_col_type
pos_col_size: DEFINE_POINT 150, 0, pos_col_size
pos_col_date: DEFINE_POINT 231, 0, pos_col_date

kTextBuffer2Len = 49
.params text_buffer2
        .addr   data
length: .byte   0
data:   .res    ::kTextBuffer2Len, 0
.endparams

file_record_ptr:
        .addr   0

;;; ============================================================

.macro WINFO_DEFN id, label, buflabel
.params label
window_id:      .byte   id
options:        .byte   MGTK::Option::go_away_box | MGTK::Option::grow_box
title:          .addr   buflabel
hscroll:        .byte   MGTK::Scroll::option_normal
vscroll:        .byte   MGTK::Scroll::option_normal
hthumbmax:      .byte   3
hthumbpos:      .byte   0
vthumbmax:      .byte   3
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   170
mincontlength:  .word   50
maxcontwidth:   .word   545
maxcontlength:  .word   175
port:
viewloc:        DEFINE_POINT 20, 27
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
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
.endparams

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
;;; 8 entries; each entry is kPathBufferSize bytes long
;;; * length-prefixed path string (no trailing /)
;;; Windows 1...8 (since 0 is desktop)
window_path_table:
        .res    (kMaxNumWindows*kPathBufferSize), 0

;;; Window used/free (in kilobytes)
;;; Two tables, 8 entries each
;;; Windows 1...8 (since 0 is desktop)
window_k_used_table:  .res    kMaxNumWindows*2, 0
window_k_free_table:  .res    kMaxNumWindows*2, 0

;;; ============================================================
;;; Resources for window header (Items/K in disk/K available)

str_items:
        PASCAL_STRING " Items"

items_label_pos:
        DEFINE_POINT 8, 10, items_label_pos

header_line_left: DEFINE_POINT 0, 0, header_line_left
header_line_right:    DEFINE_POINT 0, 0, header_line_right

str_k_in_disk:
        PASCAL_STRING "K in disk" ; suffix for disk space used

str_k_available:
        PASCAL_STRING "K available" ; suffix for disk space available

str_from_int:                   ; populated by int_to_string
        PASCAL_STRING "000,000" ; 6 digits plus thousands separator - do not localize

;;; Computed during startup
width_items_label_padded:
        .word   0
width_left_labels:
        .word   0

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

;;; Selection drag/drop icon/result, and coords
.params drag_drop_params
icon:
result:  .byte   0
coords: DEFINE_POINT 0, 0
.endparams

;;; ============================================================

;;; Each buffer is a list of icons in each window (0=desktop)
;;; window_icon_count_table = start of buffer = icon count
;;; window_icon_list_table = first entry in buffer (length = 127)

window_icon_count_table:
        .repeat kMaxNumWindows+1,i
        .addr   WINDOW_ICON_TABLES + $80 * i
        .endrepeat

window_icon_list_table:
        .repeat kMaxNumWindows+1,i
        .addr   WINDOW_ICON_TABLES + $80 * i + 1
        .endrepeat

active_window_id:
        .byte   $00

;;; $00 = window not in use
;;; $FF = window in use, but dir (vol/folder) icon deleted
;;; Otherwise, dir (vol/folder) icon associated with window.
window_to_dir_icon_table:
        .res    kMaxNumWindows, 0

num_open_windows:
        .byte   0

;;; --------------------------------------------------
;;; FileRecord for list view

list_view_filerecord:
        .tag FileRecord

;;; Used elsewhere for converting date to string
datetime_for_conversion := list_view_filerecord + FileRecord::modification_date

;;; --------------------------------------------------

hex_digits:
        .byte   "0123456789ABCDEF"

;;; Parent window to close after an Open action
window_id_to_close:
        .byte   0

;;; High bit set if menu dispatch via keyboard accelerator, clear otherwise.
menu_kbd_flag:
        .byte   0

;;; --------------------------------------------------

;;; Params for icontype_lookup
icontype_filetype:   .byte   0
icontype_auxtype:    .word   0
icontype_blocks:     .word   0

;;; Mapping from file info to icon type
;;;
;;; The incoming type is compared (using a mask) against a type, and
;;; optionally auxtype and block count. First match wins.

.struct ICTRecord      ; Offset
        mask     .byte ; 0     incoming type masked before comparison
        filetype .byte ; 1     file type for the record (must match)
        flags    .byte ; 2     bit 7 = compare aux; 6 = compare blocks
        aux      .word ; 3     optional aux type
        blocks   .word ; 5     optional block count
        icontype .byte ; 7     IconType
.endstruct
.macro DEFINE_ICTRECORD mask, filetype, flags, aux, blocks, icontype
        .byte   mask
        .byte   filetype
        .byte   flags
        .word   aux
        .word   blocks
        .byte   icontype
.endmacro
        ICT_FLAGS_NONE   = %00000000
        ICT_FLAGS_AUX    = %10000000
        ICT_FLAGS_BLOCKS = %01000000

icontype_table:
        ;; Binary files ($06) identified as graphics (hi-res, double hi-res, minpix)
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $2000, 17, IconType::graphics ; HR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $4000, 17, IconType::graphics ; HR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $2000, 33, IconType::graphics ; DHR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $4000, 33, IconType::graphics ; DHR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $5800, 3,  IconType::graphics ; Minipix as FOT

        ;; Simple Mappings
        DEFINE_ICTRECORD $FF, FT_TEXT,      ICT_FLAGS_NONE, 0, 0, IconType::text          ; $04
        DEFINE_ICTRECORD $FF, FT_BINARY,    ICT_FLAGS_NONE, 0, 0, IconType::binary        ; $06
        DEFINE_ICTRECORD $FF, FT_FONT,      ICT_FLAGS_NONE, 0, 0, IconType::font          ; $07
        DEFINE_ICTRECORD $FF, FT_GRAPHICS,  ICT_FLAGS_NONE, 0, 0, IconType::graphics      ; $08

        DEFINE_ICTRECORD $FF, FT_DIRECTORY, ICT_FLAGS_NONE, 0, 0, IconType::folder        ; $0F
        DEFINE_ICTRECORD $FF, FT_ADB,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_db ; $19
        DEFINE_ICTRECORD $FF, FT_AWP,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_wp ; $1A
        DEFINE_ICTRECORD $FF, FT_ASP,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_sp ; $1B

        DEFINE_ICTRECORD $FF, FT_CMD,       ICT_FLAGS_NONE, 0, 0, IconType::command       ; $F0
        DEFINE_ICTRECORD $FF, FT_BASIC,     ICT_FLAGS_NONE, 0, 0, IconType::basic         ; $FC
        DEFINE_ICTRECORD $FF, FT_REL,       ICT_FLAGS_NONE, 0, 0, IconType::relocatable   ; $FE
        DEFINE_ICTRECORD $FF, FT_SYSTEM,    ICT_FLAGS_NONE, 0, 0, IconType::system        ; $FF

        ;; IIgs-Specific Files (ranges)
        DEFINE_ICTRECORD $F0, $50,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs General  $5x
        DEFINE_ICTRECORD $F0, $A0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs BASIC    $Ax
        DEFINE_ICTRECORD $FF, FT_S16, ICT_FLAGS_NONE, 0, 0, IconType::application ; IIgs System   $B3
        DEFINE_ICTRECORD $F0, $B0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs System   $Bx
        DEFINE_ICTRECORD $F0, $C0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs Graphics $Cx

        ;; Desk Accessories/Applets $F1/$0640 and $F1/$8640
        DEFINE_ICTRECORD $FF, kDAFileType,  ICT_FLAGS_AUX, kDAFileAuxType, 0, IconType::desk_accessory
        DEFINE_ICTRECORD $FF, kDAFileType,  ICT_FLAGS_AUX, kDAFileAuxType|$8000, 0, IconType::desk_accessory


;;; --------------------------------------------------

checkerboard_pattern:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

;;; --------------------------------------------------

        PAD_TO $ED00

;;; (there's enough room here for 127 files at 25 bytes each)
icon_entries:
        .assert ($FB00 - *) >= 127 * .sizeof(IconEntry), error, "Not enough room for icons"

;;; There's plenty of room after that (~409 bytes) if additional
;;; buffer space is needed.

;;; ============================================================
;;; Segment loaded into AUX $FB00-$FFFF
;;; ============================================================

        .org $FB00

;;; Map ProDOS file type to string (for listings/Get Info).
;;; If not found, $XX is used (like CATALOG).

        kNumFileTypes = 12
type_table:
        .byte   FT_REL        ; rel
        .byte   FT_CMD        ; command
        .byte   FT_TEXT       ; text
        .byte   FT_BINARY     ; binary
        .byte   FT_DIRECTORY  ; directory
        .byte   FT_SYSTEM     ; system
        .byte   FT_BASIC      ; basic
        .byte   FT_GRAPHICS   ; graphics
        .byte   FT_ADB        ; appleworks db
        .byte   FT_AWP        ; appleworks wp
        .byte   FT_ASP        ; appleworks sp
        .byte   FT_BAD        ; bad block
        ASSERT_TABLE_SIZE type_table, kNumFileTypes

type_names_table:
        .byte   " REL" ; rel
        .byte   " CMD" ; rel
        .byte   " TXT" ; text
        .byte   " BIN" ; binary
        .byte   " DIR" ; directory
        .byte   " SYS" ; system
        .byte   " BAS" ; basic
        .byte   " FOT" ; graphics
        .byte   " ADB" ; appleworks db
        .byte   " AWP" ; appleworks wp
        .byte   " ASP" ; appleworks sp
        .byte   " BAD" ; bad block
        ASSERT_RECORD_TABLE_SIZE type_names_table, kNumFileTypes, 4

;;; Map IconType to other icon/details

icontype_iconentrytype_table:
        .byte   kIconEntryTypeGeneric ; generic
        .byte   kIconEntryTypeGeneric ; text
        .byte   kIconEntryTypeBinary  ; binary
        .byte   kIconEntryTypeGeneric ; graphics
        .byte   kIconEntryTypeGeneric ; font
        .byte   kIconEntryTypeGeneric ; relocatable
        .byte   kIconEntryTypeGeneric ; command
        .byte   kIconEntryTypeDir     ; folder
        .byte   kIconEntryTypeGeneric ; iigs
        .byte   kIconEntryTypeGeneric ; appleworks db
        .byte   kIconEntryTypeGeneric ; appleworks wp
        .byte   kIconEntryTypeGeneric ; appleworks sp
        .byte   kIconEntryTypeGeneric ; desk accessory
        .byte   kIconEntryTypeBasic   ; basic
        .byte   kIconEntryTypeSystem  ; system
        .byte   kIconEntryTypeSystem  ; application
        ASSERT_TABLE_SIZE icontype_iconentrytype_table, IconType::COUNT

type_icons_table:               ; map into definitions below
        .addr   gen ; generic
        .addr   txt ; text
        .addr   bin ; binary
        .addr   fot ; graphics
        .addr   fnt ; font
        .addr   rel ; relocatable
        .addr   cmd ; command
        .addr   dir ; folder
        .addr   src ; iigs
        .addr   adb ; appleworks db
        .addr   awp ; appleworks wp
        .addr   asp ; appleworks sp
        .addr   a2d ; desk accessory
        .addr   bas ; basic
        .addr   sys ; system
        .addr   app ; application
        ASSERT_ADDRESS_TABLE_SIZE type_icons_table, IconType::COUNT

gen:    DEFICON generic_icon, 4, 27, 15, generic_mask
src:    DEFICON aux::iigs_file_icon, 4, 27, 15, generic_mask
rel:    DEFICON aux::rel_file_icon, 4, 27, 14, binary_mask
cmd:    DEFICON aux::cmd_file_icon, 4, 27, 8, aux::graphics_mask
txt:    DEFICON text_icon, 4, 27, 15, generic_mask
bin:    DEFICON binary_icon, 4, 27, 14, binary_mask
dir:    DEFICON folder_icon, 4, 27, 11, folder_mask
sys:    DEFICON sys_icon, 4, 27, 17, sys_mask
bas:    DEFICON aux::basic_icon, 4, 27, 14, aux::basic_mask
fot:    DEFICON aux::graphics_icon, 4, 27, 12, aux::graphics_mask
adb:    DEFICON aux::adb_icon, 4, 27, 15, generic_mask
awp:    DEFICON aux::awp_icon, 4, 27, 15, generic_mask
asp:    DEFICON aux::asp_icon, 4, 27, 15, generic_mask
a2d:    DEFICON aux::a2d_file_icon, 4, 27, 15, generic_mask
fnt:    DEFICON aux::font_icon, 4, 27, 15, generic_mask
app:    DEFICON app_icon, 5, 34, 16, app_mask

;;; Generic

generic_icon:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%1100000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0011000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0000110)
        .byte   PX(%0100000),PX(%0000000),PX(%0000111),PX(%1111110)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)

        ;; Generic mask is re-used for multiple "document" types
generic_mask:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1100000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)

;;; Text File

text_icon:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%1100000)
        .byte   PX(%0100000),PX(%1110111),PX(%1011100),PX(%0011000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0000110)
        .byte   PX(%0100111),PX(%0110111),PX(%0110111),PX(%1111110)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100111),PX(%1101110),PX(%1111110),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%1111101),PX(%1101101),PX(%1110010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100110),PX(%1111011),PX(%1011011),PX(%1110010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100111),PX(%1101101),PX(%1011101),PX(%1110010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        ;; shares generic_mask

;;; Binary

binary_icon:
        .byte   PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000110),PX(%0110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0011000),PX(%0001100),PX(%0000000)
        .byte   PX(%0000000),PX(%1100000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000011),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0001100),PX(%0011000),PX(%0011000),PX(%0011000)
        .byte   PX(%0110000),PX(%0100100),PX(%0101000),PX(%0000110)
        .byte   PX(%1000000),PX(%0100100),PX(%0001000),PX(%0000001)
        .byte   PX(%0110000),PX(%0100100),PX(%0001000),PX(%0000110)
        .byte   PX(%0001100),PX(%0011000),PX(%0001000),PX(%0011000)
        .byte   PX(%0000011),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0000000),PX(%1100000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000000),PX(%0011000),PX(%0001100),PX(%0000000)
        .byte   PX(%0000000),PX(%0000110),PX(%0110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)

binary_mask:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000111),PX(%1110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0011111),PX(%1111100),PX(%0000000)
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0000011),PX(%1111111),PX(%1111111),PX(%1100000)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0001111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0000011),PX(%1111111),PX(%1111111),PX(%1100000)
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0000000),PX(%0011111),PX(%1111100),PX(%0000000)
        .byte   PX(%0000000),PX(%0000111),PX(%1110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)

;;; Folder
folder_icon:
        .byte   PX(%0011111),PX(%1111110),PX(%0000000),PX(%0000000)
        .byte   PX(%0100000),PX(%0000001),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)

folder_mask:
        .byte   PX(%0011111),PX(%1111110),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)

;;; System (no .SYSTEM suffix)

sys_icon:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100111),PX(%1111111),PX(%1111111),PX(%1110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0110011)
        .byte   PX(%1100110),PX(%1100110),PX(%0110000),PX(%0110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0110011)
        .byte   PX(%1100110),PX(%1100110),PX(%0000000),PX(%0110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0110011)
        .byte   PX(%1100111),PX(%1111111),PX(%1111111),PX(%1110011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000011)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)

sys_mask:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)


;;; System (with .SYSTEM suffix)

app_icon:
        .byte   PX(%0000000),PX(%0000000),PX(%0011000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%1100110),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000011),PX(%0000001),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0001100),PX(%0000000),PX(%0110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0110000),PX(%0000000),PX(%0001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000001),PX(%1111100),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000110),PX(%0000011),PX(%0000110)
        .byte   PX(%0011000),PX(%0000000),PX(%0011000),PX(%1110000),PX(%1111000)
        .byte   PX(%0000110),PX(%0000111),PX(%1111111),PX(%1111100),PX(%0011110)
        .byte   PX(%0000001),PX(%1000000),PX(%0110000),PX(%1100000),PX(%0011110)
        .byte   PX(%0000000),PX(%0110000),PX(%0001110),PX(%0000000),PX(%0011110)
        .byte   PX(%0000000),PX(%0001100),PX(%0000001),PX(%1111111),PX(%1111110)
        .byte   PX(%0000000),PX(%0000011),PX(%0000001),PX(%1000000),PX(%0011110)
        .byte   PX(%0000000),PX(%0000000),PX(%1100110),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0011000),PX(%0000000),PX(%0000000)

app_mask:
        .byte   PX(%0000000),PX(%0000000),PX(%0011000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%1111110),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000011),PX(%1111111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0001111),PX(%1111111),PX(%1110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111100),PX(%0000000)
        .byte   PX(%0000001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1100000)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0000001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111100),PX(%1111000)
        .byte   PX(%0000000),PX(%0001111),PX(%1111111),PX(%1111000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000011),PX(%1111111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%1111110),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0011000),PX(%0000000),PX(%0000000)

        ;; Reserve $80 bytes for settings
        PAD_TO $FF80

;;; ============================================================
;;; Settings - modified by Control Panel
;;; ============================================================

.scope settings
        ASSERT_ADDRESS ::SETTINGS

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::version_major
        .byte   kDeskTopVersionMajor
        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::version_minor
        .byte   kDeskTopVersionMinor

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::pattern
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::dblclick_speed
        .word   0               ; $12C * 1, * 4, or * 32, 0 if not set

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::ip_blink_speed
        .byte   kDefaultIPBlinkSpeed ; 120, 60 or 30; lower is faster

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::clock_24hours
        .byte   0

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::rgb_color
        .byte   0

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::mouse_tracking
        .byte   0

        ;; Reserved for future use...

        PAD_TO ::SETTINGS + .sizeof(DeskTopSettings)
.endscope

        ASSERT_ADDRESS $10000
