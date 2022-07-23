;;; ============================================================
;;; DeskTop - Resources
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into AUX $D200-$ECFF
;;; ============================================================

        ASSERT_ADDRESS $D200

pencopy:        .byte   MGTK::pencopy
penOR:          .byte   MGTK::penOR
penXOR:         .byte   MGTK::penXOR
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy
notpenOR:       .byte   MGTK::notpenOR
notpenXOR:      .byte   MGTK::notpenXOR
notpenBIC:      .byte   MGTK::notpenBIC

;;; ============================================================
;;; Re-used param space for events/queries (10 bytes)

        .include "../lib/event_params.s"
;;; ============================================================

.params getwinport_params
window_id:     .byte   0
a_grafport:     .addr   window_grafport
.endparams

;;; GrafPort used specifically for operations that draw into windows.

.params window_grafport
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 0, 0
penpattern:     .res    8, 0
colormasks:     .byte   0, 0
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   MGTK::pencopy
textbg:         .byte   MGTK::textbg_black
fontptr:        .addr   0
.endparams
        .assert .sizeof(window_grafport) = .sizeof(MGTK::GrafPort), error, "size mismatch"

;;; GrafPort used for nearly all operations. Usually re-initialized
;;; before use.

desktop_grafport:        .tag   MGTK::GrafPort

;;; GrafPort used for icon operations in inactive windows, to
;;; prevent any drawing.
null_grafport:          .tag    MGTK::GrafPort

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

.params machine_config
;;; ID bytes, copied from ROM
id_version:     .byte   0       ; ROM FBB3; $06 = IIe or later
id_idbyte:      .byte   0       ; ROM FBC0; $00 = IIc or later
id_idbyte2:     .byte   0       ; ROM FBBF; IIc ROM version (IIc+ = $05)
id_idlaser:     .byte   0       ; ROM FB1E; $AC = Laser 128
iigs_flag:      .byte   0       ; High bit set if IIgs

;;; High bit set if Le Chat Mauve Eve present
lcm_eve_flag:
        .byte   0

;;; Shift key mod sets PB2 if shift is *not* down. Since we can't detect
;;; the mod, snapshot on init (and assume shift is not down) and XOR.
pb2_initial_state:
        .byte   0
.endparams

.params initmenu_params
open_char:      .byte   kGlyphOpenApple
solid_char:     .byte   kGlyphSolidApple
        .assert (solid_char - open_char) = 1, error, "solid_char must follow open_char immediately"
check_char:     .byte   kGlyphCheckmark
control_char:   .byte   '^'
.endparams

setzp_params_nopreserve:           ; performance over convenience
        .byte   MGTK::zp_overwrite ; set at startup

setzp_params_preserve:            ; convenience over performance
        .byte   MGTK::zp_preserve ; used while DAs are running

.params trackgoaway_params
goaway:.byte   0
.endparams

;;; Every event loop tick, a counter is incremented (by 3); when it passes
;;; this value, periodic tasks are run (e.g. drawing the clock, checking
;;; for new devices, etc).
periodic_task_delay:
        .byte   0

;;; This delay is initialized to a machine-specific value. TODO: Why???
kPeriodicTaskDelayIIe  = $96
kPeriodicTaskDelayIIc  = $FA
kPeriodicTaskDelayIIgs = $FD

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

        ;; Cleared when Selector entries changed, set once
        ;; the menu state has been updated.
selector_menu_items_updated_flag:
        .byte   0

buf_filename2:  .res    16, 0

        ;; Used during launching
buf_win_path:
        .res    kPathBufferSize, 0

;;; In common dialog (copy/edit file, add/edit shortcut):
;;; * path_buf0 has the contents of the top input field
;;; * path_buf1 has the contents of the bottom input field

path_buf0:  .res    kPathBufferSize, 0
path_buf1:  .res    kPathBufferSize, 0

;;; ============================================================
;;; Dialog used for prompts (yes/no/all) and operation progress

.params winfo_prompt_dialog
        kWindowId = aux::kPromptWindowId
        kWidth = aux::kPromptDialogWidth
        kHeight = aux::kPromptDialogHeight

window_id:      .byte   kWindowId
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
        DEFINE_POINT viewloc, aux::kPromptDialogLeft, aux::kPromptDialogTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kWidth, kHeight
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

        kDialogLabelDefaultX    =  40
        kDialogLabelRightX      = 160
        kDialogValueLeft        = 170

        kNameInputLeft = kDialogLabelDefaultX
        kNameInputTop = 67
        kNameInputWidth = 320

        DEFINE_RECT_SZ name_input_rect, kNameInputLeft, kNameInputTop, kNameInputWidth, kTextBoxHeight
        DEFINE_POINT pos_dialog_title, 0, 18

        DEFINE_POINT dialog_label_base_pos, kDialogLabelDefaultX, 30

        DEFINE_POINT dialog_label_pos, kDialogLabelDefaultX, 0

;;; $00 = ok/cancel
;;; $80 = ok (only)
;;; $40 = yes/no/all/cancel
prompt_button_flags:
        .byte   0
has_input_field_flag:
        .byte   0

format_erase_overlay_flag:      ; set when prompt is showing device picker
        .byte   0


;;; ============================================================
;;; "About Apple II DeskTop" Dialog

.params winfo_about_dialog
        kWindowId = $18
        kWidth = aux::kAboutDialogWidth
        kHeight = aux::kAboutDialogHeight

window_id:      .byte   kWindowId
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
        DEFINE_RECT maprect, 0, 0, kWidth, kHeight
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

;;; ============================================================
;;; Dialog for Edit/Delete/Run a Shortcut...

.params winfo_entry_picker
        kWindowId = $1B
        kWidth = 350
        kHeight = 126

window_id:      .byte   kWindowId
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
        DEFINE_RECT maprect, 0, 0, kWidth, kHeight
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME entry_picker_frame_rect, winfo_entry_picker::kWidth, winfo_entry_picker::kHeight

        ;; Options control metrics
        kShortcutPickerCols = 3
        kShortcutPickerRows = 8
        kShortcutPickerRowShift = 3 ; log2(kShortcutPickerRows)
        kShortcutPickerLeft = (winfo_entry_picker::kWidth - kShortcutPickerItemWidth * kShortcutPickerCols + 1) / 2
        kShortcutPickerTop  = 24
        kShortcutPickerItemWidth  = 104
        kShortcutPickerItemHeight = kListItemHeight
        kShortcutPickerTextHOffset = 10
        kShortcutPickerTextYOffset = kShortcutPickerItemHeight - 1

        ;; Line endpoints
        DEFINE_POINT entry_picker_line1_start, kBorderDX*2, 22
        DEFINE_POINT entry_picker_line1_end, winfo_entry_picker::kWidth - kBorderDX*2, 22
        DEFINE_POINT entry_picker_line2_start, kBorderDX*2, winfo_entry_picker::kHeight-21
        DEFINE_POINT entry_picker_line2_end, winfo_entry_picker::kWidth - kBorderDX*2, winfo_entry_picker::kHeight-21

        ;; Used when rendering entries
        DEFINE_RECT entry_picker_item_rect, 0, 0, 0, 0

        DEFINE_BUTTON entry_picker_ok_button_rec, winfo_entry_picker::kWindowId, res_string_button_ok, 210, winfo_entry_picker::kHeight-18
        DEFINE_BUTTON_PARAMS entry_picker_ok_button_params, entry_picker_ok_button_rec
        DEFINE_BUTTON entry_picker_cancel_button_rec, winfo_entry_picker::kWindowId, res_string_button_cancel, 40, winfo_entry_picker::kHeight-18
        DEFINE_BUTTON_PARAMS entry_picker_cancel_button_params, entry_picker_cancel_button_rec

;;; ============================================================
;;; Format/Erase dialogs

        ;; Options control metrics
        kVolPickerCols = 3
        kVolPickerRows = 4
        kVolPickerRowShift = 2  ; log2(kVolPickerRows)
        kVolPickerLeft = (winfo_prompt_dialog::kWidth - kVolPickerItemWidth * kVolPickerCols + 1) / 2
        kVolPickerTop = 44
        kVolPickerItemWidth = 127
        kVolPickerItemHeight = kListItemHeight
        kVolPickerTextHOffset = 1
        kVolPickerTextVOffset = kVolPickerItemHeight-1

        ;; Line endpoints
        DEFINE_POINT vol_picker_line1_start, 7, kVolPickerTop - 2
        DEFINE_POINT vol_picker_line1_end, winfo_prompt_dialog::kWidth - 8, kVolPickerTop - 2
        DEFINE_POINT vol_picker_line2_start, 7, winfo_prompt_dialog::kHeight-22
        DEFINE_POINT vol_picker_line2_end, winfo_prompt_dialog::kWidth - 8, winfo_prompt_dialog::kHeight-22

        ;; Used when rendering entries
        DEFINE_RECT vol_picker_item_rect, 0, 0, 0, 0

the_dos_33_disk_label:
        PASCAL_STRING res_string_the_dos_33_disk_suffix_pattern
        kTheDos33DiskSlotCharOffset = res_const_the_dos_33_disk_suffix_pattern_offset1
        kTheDos33DiskDriveCharOffset = res_const_the_dos_33_disk_suffix_pattern_offset2

the_disk_in_slot_label:
        PASCAL_STRING res_string_the_disk_in_slot_suffix_pattern
        kTheDiskInSlotSlotCharOffset = res_const_the_disk_in_slot_suffix_pattern_offset1
        kTheDiskInSlotDriveCharOffset = res_const_the_disk_in_slot_suffix_pattern_offset2

buf_filename:
        .res    16, 0

;;; ============================================================
;;; Name prompt dialog (used for Rename, Duplicate, Format, Erase)

        DEFINE_LINE_EDIT line_edit_rec, winfo_prompt_dialog::kWindowId, path_buf1, kNameInputLeft, kNameInputTop, kNameInputWidth, kMaxFilenameLength
        DEFINE_LINE_EDIT_PARAMS le_params, line_edit_rec

;;; ============================================================

str_file_suffix:
        PASCAL_STRING res_string_file_suffix
str_files_suffix:
        PASCAL_STRING res_string_files_suffix

str_file_count:                 ; populated with number of files
        PASCAL_STRING " ##,### "

;;; Used as suffix to handle `str_file_count` shrinking
str_2_spaces:
        PASCAL_STRING "  "

str_kb_suffix:
        PASCAL_STRING res_string_kb_suffix       ; suffix for kilobytes

file_count:
        .word   0

;;; ============================================================
;;; Resources for Add/Edit a Shortcut dialog

enter_the_full_pathname_label:
        PASCAL_STRING res_string_selector_label_enter_pathname
enter_the_name_to_appear_label:
        PASCAL_STRING res_string_selector_label_enter_name


;;; Padding between radio/checkbox and label
kLabelPadding = 5

kRadioButtonWidth       = 15
kRadioButtonHeight      = 7

.params rb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   SELF_MODIFIED
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kRadioButtonWidth, kRadioButtonHeight
.endparams

checked_rb_bitmap:
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%1110001),PX(%1110001),PX(%1100000)
        .byte   PX(%1100111),PX(%1111100),PX(%1100000)
        .byte   PX(%1100111),PX(%1111100),PX(%1100000)
        .byte   PX(%1110001),PX(%1110001),PX(%1100000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)

unchecked_rb_bitmap:
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%1110000),PX(%0000001),PX(%1100000)
        .byte   PX(%1100000),PX(%0000000),PX(%1100000)
        .byte   PX(%1100000),PX(%0000000),PX(%1100000)
        .byte   PX(%1110000),PX(%0000001),PX(%1100000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)

kRadioButtonLeft  = 332
kRadioButtonHOffset = kLabelPadding
kRadioControlHeight = 8         ; system font height - 1

        ;; Rect widths are dynamically computed based on label

        DEFINE_LABEL add_a_new_entry_to, res_string_selector_label_add_a_new_entry_to,                   329, 37

        DEFINE_RECT_SZ rect_primary_run_list_ctrl,   kRadioButtonLeft, 39, kRadioButtonWidth + kRadioButtonHOffset, kRadioControlHeight
        DEFINE_LABEL primary_run_list,   {kGlyphOpenApple,res_string_selector_label_primary_run_list},   kRadioButtonLeft + kRadioButtonWidth + kRadioButtonHOffset, 47

        DEFINE_RECT_SZ rect_secondary_run_list_ctrl, kRadioButtonLeft, 48, kRadioButtonWidth + kRadioButtonHOffset, kRadioControlHeight
        DEFINE_LABEL secondary_run_list, {kGlyphOpenApple,res_string_selector_label_secondary_run_list}, kRadioButtonLeft + kRadioButtonWidth + kRadioButtonHOffset, 56

        DEFINE_LABEL down_load,          res_string_selector_label_download,                             329, 71

        DEFINE_RECT_SZ rect_at_first_boot_ctrl,      kRadioButtonLeft, 73, kRadioButtonWidth + kRadioButtonHOffset, kRadioControlHeight
        DEFINE_LABEL at_first_boot,      {kGlyphOpenApple,res_string_selector_label_at_first_boot},      kRadioButtonLeft + kRadioButtonWidth + kRadioButtonHOffset, 81

        DEFINE_RECT_SZ rect_at_first_use_ctrl,       kRadioButtonLeft, 82, kRadioButtonWidth + kRadioButtonHOffset, kRadioControlHeight
        DEFINE_LABEL at_first_use,       {kGlyphOpenApple,res_string_selector_label_at_first_use},       kRadioButtonLeft + kRadioButtonWidth + kRadioButtonHOffset, 90

        DEFINE_RECT_SZ rect_never_ctrl,              kRadioButtonLeft, 91, kRadioButtonWidth + kRadioButtonHOffset, kRadioControlHeight
        DEFINE_LABEL never,              {kGlyphOpenApple,res_string_selector_label_never},              kRadioButtonLeft + kRadioButtonWidth + kRadioButtonHOffset, 99

;;; ============================================================

input1_dirty_flag:              ; stash dirty flag when input2 is active
        .byte   0
input2_dirty_flag:              ; stash dirty flag when input1 is active
        .byte   0

saved_src_index:
        .byte   0

        FONT := DEFAULT_FONT
        .define FD_EXTENDED 1
        buf_input1 := path_buf0
        buf_input2 := path_buf1
        .include "../lib/file_dialog_res.s"

file_to_delete_label:
        PASCAL_STRING res_string_delete_file_label_file_to_delete

source_filename_label:
        PASCAL_STRING res_string_copy_file_label_source_filename

destination_filename_label:
        PASCAL_STRING res_string_copy_file_label_destination_filename

;;; ============================================================

;;; 5.25" Floppy Disk
        DEFINE_ICON_RESOURCE floppy140_icon, floppy140_pixels, 4, 26, 14, floppy140_mask

;;; RAM Disk
        DEFINE_ICON_RESOURCE ramdisk_icon, ramdisk_pixels, 6, 39, 11, ramdisk_mask

;;; 3.5" Floppy Disk
        DEFINE_ICON_RESOURCE floppy800_icon, floppy800_pixels, 3, 20, 11, floppy800_mask

;;; Hard Disk
        DEFINE_ICON_RESOURCE profile_icon, profile_pixels, 8, 52, 9, profile_mask

;;; File Share
        DEFINE_ICON_RESOURCE fileshare_icon, fileshare_pixels, 5, 34, 14, fileshare_mask

;;; Trash Can
        DEFINE_ICON_RESOURCE trash_icon, trash_pixels, 3, 20, 17, trash_mask

;;; ============================================================

floppy140_pixels:
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000111),PX(%1100000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)

floppy140_mask:
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)

ramdisk_pixels:
        .byte   PX(%0000000),PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0111000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%0000011),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%0011100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1100000),PX(%0000111),PX(%1100011),PX(%1100110),PX(%0000110),PX(%0001100)
        .byte   PX(%1100000),PX(%0000110),PX(%0110110),PX(%0110111),PX(%1011110),PX(%0001100)
        .byte   PX(%1100000),PX(%0000111),PX(%1100111),PX(%1110110),PX(%1110110),PX(%0001100)
        .byte   PX(%1100000),PX(%0000110),PX(%0110110),PX(%0110110),PX(%0000110),PX(%0001100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110011),PX(%0011001),PX(%1001100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0110011),PX(%0011001),PX(%1001100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111100)

ramdisk_mask:
        .byte   PX(%0000000),PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000011),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111100)

floppy800_pixels:
        .byte   PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1100011),PX(%0000000),PX(%1100111)
        .byte   PX(%1100011),PX(%0000000),PX(%1100111)
        .byte   PX(%1100011),PX(%1111111),PX(%1100011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100111),PX(%1111111),PX(%1110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0110011)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)

floppy800_mask:
        .byte   PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)

profile_pixels:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100011),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000)
        .byte   PX(%0000111),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%0000000)

profile_mask:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000)
        .byte   PX(%0000111),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%0000000)

fileshare_pixels:
        .byte   PX(%0000000),PX(%0000000),PX(%0011001),PX(%1111111),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000),PX(%1100110),PX(%0000000),PX(%1110000)
        .byte   PX(%0011111),PX(%1110011),PX(%0000001),PX(%1000000),PX(%1111100)
        .byte   PX(%0011000),PX(%0011111),PX(%1100000),PX(%0110000),PX(%0001100)
        .byte   PX(%0011000),PX(%0000000),PX(%0011000),PX(%0001100),PX(%0001100)
        .byte   PX(%0011000),PX(%0000000),PX(%0011000),PX(%0110000),PX(%0001100)
        .byte   PX(%0011000),PX(%0000000),PX(%0011001),PX(%1000000),PX(%0001100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000110),PX(%0110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0001110),PX(%0111000),PX(%0000000)
        .byte   PX(%1100111),PX(%1111111),PX(%1111000),PX(%0001111),PX(%1110011)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)
        .byte   PX(%1100111),PX(%1111111),PX(%1111110),PX(%0111111),PX(%1110011)

fileshare_mask:
        .byte   PX(%0000000),PX(%0000000),PX(%0011001),PX(%1111111),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000),PX(%1111111),PX(%1111111),PX(%1110000)
        .byte   PX(%0011111),PX(%1110011),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000111),PX(%1110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0001111),PX(%1111000),PX(%0000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111),PX(%1111111)

trash_pixels:
        .byte   PX(%0000001),PX(%1111111),PX(%1000000)
        .byte   PX(%0000011),PX(%1000001),PX(%1100000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1100000),PX(%0000000),PX(%0000011)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1100000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100100),PX(%0010000),PX(%1000011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100100),PX(%0010000),PX(%1000011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000011)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)

trash_mask:
        .byte   PX(%0000001),PX(%1111111),PX(%1000000)
        .byte   PX(%0000011),PX(%1111111),PX(%1100000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)

;;; ============================================================

str_jan:PASCAL_STRING res_string_month_name_1
str_feb:PASCAL_STRING res_string_month_name_2
str_mar:PASCAL_STRING res_string_month_name_3
str_apr:PASCAL_STRING res_string_month_name_4
str_may:PASCAL_STRING res_string_month_name_5
str_jun:PASCAL_STRING res_string_month_name_6
str_jul:PASCAL_STRING res_string_month_name_7
str_aug:PASCAL_STRING res_string_month_name_8
str_sep:PASCAL_STRING res_string_month_name_9
str_oct:PASCAL_STRING res_string_month_name_10
str_nov:PASCAL_STRING res_string_month_name_11
str_dec:PASCAL_STRING res_string_month_name_12

month_table:
        .addr   str_no_date
        .addr   str_jan,str_feb,str_mar,str_apr,str_may,str_jun
        .addr   str_jul,str_aug,str_sep,str_oct,str_nov,str_dec
        ASSERT_ADDRESS_TABLE_SIZE month_table, 13

str_no_date:
        PASCAL_STRING res_string_no_date

str_space:
        PASCAL_STRING " "
str_comma:
        PASCAL_STRING res_string_comma_infix
str_at:
        PASCAL_STRING res_string_at_infix

;;; ============================================================

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

        ;; Pointers into icon_entries buffer (index 0 not used)
icon_entry_address_table:
        .res    (kMaxIconCount+1)*2, 0

;;; Copy from aux memory of icon list for active window (0=desktop)

        ;; which window buffer is copied
        ;; (see `window_entry_count_table`, `window_entry_list_table`)
cached_window_id: .byte   0
        ;; number of entries in copied window
cached_window_entry_count:.byte   0
        ;; list of entries (icons or file entry numbers) in copied window
cached_window_entry_list:   .res    kMaxIconCount, 0

;;; Index of window with selection (0=desktop)
selected_window_id:
        .byte   0

;;; Number of selected icons
selected_icon_count:
        .byte   0

;;; Indexes of selected icons (global, not w/in window)
selected_icon_list:
        .res    kMaxIconCount, 0

kMaxNumWindows = kMaxDeskTopWindows

;;; Table of desktop window winfo addresses
win_table:
        .addr   0,winfo1,winfo2,winfo3,winfo4,winfo5,winfo6,winfo7,winfo8
        ASSERT_ADDRESS_TABLE_SIZE win_table, kMaxNumWindows + 1

;;; ============================================================

str_file_type:
        PASCAL_STRING " $00"

;;; ============================================================

path_buf4:
        .res    kPathBufferSize, 0
path_buf3:
        .res    kPathBufferSize, 0
filename_buf:
        .res    16, 0

        ;; Set to $80 for Copy, $FF for Run
copy_run_flag:
        .byte   0

delete_skip_decrement_flag:     ; always set to 0 ???
        .byte   0

op_ref_num:
        .byte   0

process_depth:
        .byte   0               ; tracks recursion depth

;;; Number of file entries per directory block
num_entries_per_block:
        .byte   13

entries_read:
        .word   0
entries_to_skip:
        .word   0

;;; During directory traversal, the number of file entries processed
;;; at the current level is pushed here, so that following a descent
;;; the previous entries can be skipped.
entry_count_stack:
        .res    kDirStackBufferSize, 0

entry_count_stack_index:
        .byte   0

entries_read_this_block:
        .byte   0

;;; ============================================================

        ;; index is device number (in DEVLST), value is icon number
device_to_icon_map:
        .res    kMaxVolumes, 0

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

;;; ============================================================

;;; IconTK initialization parameters
.params itkinit_params
headersize:     .byte   kWindowHeaderHeight
a_polybuf:      .addr   SAVE_AREA_BUFFER
bufsize:        .word   kSaveAreaSize
.endproc

;;; Used for multiple IconTK calls:
;;; * IconTK::EraseIcon
;;; * IconTK::HighlightIcon
;;; * IconTK::IconInRect (with following `tmp_rect`)
;;; * IconTK::DrawIcon
;;; * IconTK::RemoveIcon
;;; * IconTK::UnhighlightIcon
icon_param:  .byte   0

        ;; Used for all sorts of temporary work
        ;; * follows icon_param for IconTK::IconInRect call
        ;; * used for saving/restoring window bounds to/from file
        ;; * used for icon clipping
        ;; * used for window frame zoom animation
        ASSERT_ADDRESS icon_param+1
        DEFINE_RECT tmp_rect, 0, 0, 0, 0

;;; ============================================================

tmp_mapinfo:
        .tag    MGTK::MapInfo

saved_stack:
        .byte   0

.params menu_click_params       ; used for MGTK::MenuKey as well
menu_id:        .byte   0
item_num:       .byte   0
which_key:      .byte   0
key_mods:       .byte   0
.endparams

.params checkitem_params
menu_id:        .byte   kMenuIdView
menu_item:      .byte   0
check:          .byte   0
.endparams

.params disablemenu_params
menu_id:        .byte   kMenuIdView
disable:        .byte   0
.endparams

.params disableitem_params
menu_id:        .byte   0
menu_item:      .byte   0
disable:        .byte   0
.endparams

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
        .res    28, 0           ; TODO: Only need 24 = 1 (len) + 16 (name) + 7 (prefix)
        .endrepeat

;;; Startup menu items (populated by slot scan at startup)

startup_menu_item_1:    PASCAL_STRING res_string_menu_item_slot_pattern ; menu item
startup_menu_item_2:    PASCAL_STRING res_string_menu_item_slot_pattern ; menu item
startup_menu_item_3:    PASCAL_STRING res_string_menu_item_slot_pattern ; menu item
startup_menu_item_4:    PASCAL_STRING res_string_menu_item_slot_pattern ; menu item
startup_menu_item_5:    PASCAL_STRING res_string_menu_item_slot_pattern ; menu item
startup_menu_item_6:    PASCAL_STRING res_string_menu_item_slot_pattern ; menu item
startup_menu_item_7:    PASCAL_STRING res_string_menu_item_slot_pattern ; menu item
        kStartupMenuItemSlotOffset = res_const_menu_item_slot_pattern_offset1

startup_slot_table:
        .res    7, 0            ; maps menu item index (0-based) to slot number

;;; ============================================================

kSelectorMenuMinItems = 5

selector_menu:
        DEFINE_MENU kSelectorMenuMinItems
@items: DEFINE_MENU_ITEM label_add
        DEFINE_MENU_ITEM label_edit
        DEFINE_MENU_ITEM label_del
        DEFINE_MENU_ITEM label_run, '0'
        DEFINE_MENU_SEPARATOR
        .repeat kMaxRunListEntries, i
        DEFINE_MENU_ITEM run_list_entries + i * $10, ('0'+i+1)
        .endrepeat
        .assert 5 + kMaxRunListEntries = kMenuSizeSelector, error, "Menu size mismatch"
        ASSERT_RECORD_TABLE_SIZE @items, kMenuSizeSelector, .sizeof(MGTK::MenuItem)

        kMenuItemIdSelectorAdd       = 1
        kMenuItemIdSelectorEdit      = 2
        kMenuItemIdSelectorDelete    = 3
        kMenuItemIdSelectorRun       = 4

label_add:
        PASCAL_STRING res_string_menu_item_add_entry ; menu item
label_edit:
        PASCAL_STRING res_string_menu_item_edit_entry ; menu item
label_del:
        PASCAL_STRING res_string_menu_item_delete_entry ; menu item
label_run:
        PASCAL_STRING res_string_menu_item_run_entry ; menu item

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
        PASCAL_STRING .sprintf(res_string_menu_item_about, kDeskTopProductName) ; menu item

desk_acc_names:
        .res    kMaxDeskAccCount * kDAMenuItemSize, 0

window_title_addr_table:
        .addr   0
        .addr   winfo1title
        .addr   winfo2title
        .addr   winfo3title
        .addr   winfo4title
        .addr   winfo5title
        .addr   winfo6title
        .addr   winfo7title
        .addr   winfo8title
        ASSERT_ADDRESS_TABLE_SIZE window_title_addr_table, kMaxNumWindows + 1

win_view_by_table:
        .res    kMaxNumWindows, 0

        DEFINE_POINT pos_col_icon,   4, 0
        DEFINE_POINT pos_col_name,  22, 0
        DEFINE_POINT pos_col_type, 128, 0
        DEFINE_POINT pos_col_size, 166, 0
        DEFINE_POINT pos_col_date, 231, 0

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
        DEFINE_POINT viewloc, 20, 27
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, 440, 120
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

buflabel:       .res    18, 0
.endmacro

        WINFO_DEFN 1, winfo1, winfo1title
        WINFO_DEFN 2, winfo2, winfo2title
        WINFO_DEFN 3, winfo3, winfo3title
        WINFO_DEFN 4, winfo4, winfo4title
        WINFO_DEFN 5, winfo5, winfo5title
        WINFO_DEFN 6, winfo6, winfo6title
        WINFO_DEFN 7, winfo7, winfo7title
        WINFO_DEFN 8, winfo8, winfo8title


;;; ============================================================
;;; Resources for window header (Items/K in disk/K available)

str_item_suffix:
        PASCAL_STRING res_string_window_header_item_suffix
str_items_suffix:
        PASCAL_STRING res_string_window_header_items_suffix

        DEFINE_POINT items_label_pos, 8, 10

        DEFINE_POINT header_line_left, 0, 0
        DEFINE_POINT header_line_right, 0, 0

str_k_in_disk:
        PASCAL_STRING res_string_window_header_k_used_suffix ; suffix for disk space used

str_k_available:
        PASCAL_STRING res_string_window_header_k_available_suffix ; suffix for disk space available

str_from_int:                   ; populated by IntToString
        PASCAL_STRING "000,000" ; 6 digits plus thousands separator

;;; Computed during startup
width_items_label_padded:
        .word   0
width_left_labels:
        .word   0

;;; Computed when painted
        DEFINE_POINT pos_k_in_disk, 0, 0
        DEFINE_POINT pos_k_available, 0, 0

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
        DEFINE_POINT coords, 0, 0
.endparams

;;; ============================================================

;;; Each buffer is a list of icons in each window (0=desktop)
;;; window_entry_count_table = start of buffer = icon count
;;; window_entry_list_table = first entry in buffer (length = `kMaxIconCount`)
;;; (0 is not a valid icon number)

kWindowEntryTableSize = kMaxIconCount + 1

window_entry_count_table:
        .repeat kMaxNumWindows+1,i
        .addr   WINDOW_ENTRY_TABLES + kWindowEntryTableSize * i
        .endrepeat

window_entry_list_table:
        .repeat kMaxNumWindows+1,i
        .addr   WINDOW_ENTRY_TABLES + kWindowEntryTableSize * i + 1
        .endrepeat

active_window_id:
        .byte   0

;;; $00 = window not in use
;;; $FF = window in use, but dir (vol/folder) icon deleted
;;; Otherwise, dir (vol/folder) icon associated with window.
window_to_dir_icon_table:
        .res    kMaxNumWindows, 0

num_open_windows:
        .byte   0

;;; --------------------------------------------------

hex_digits:
        .byte   "0123456789ABCDEF"

;;; High bit set if menu dispatch via keyboard accelerator, clear otherwise.
menu_kbd_flag:
        .byte   0

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

;;; ============================================================
;;; Resources for clock on menu bar

        DEFINE_POINT pos_clock, kScreenWidth - 11, 10

str_time:
        PASCAL_STRING "00:00 XM"

str_4_spaces:
        PASCAL_STRING "    "

dow_strings:
        PASCAL_STRING res_string_weekday_abbrev_1, 3
        PASCAL_STRING res_string_weekday_abbrev_2, 3
        PASCAL_STRING res_string_weekday_abbrev_3, 3
        PASCAL_STRING res_string_weekday_abbrev_4, 3
        PASCAL_STRING res_string_weekday_abbrev_5, 3
        PASCAL_STRING res_string_weekday_abbrev_6, 3
        PASCAL_STRING res_string_weekday_abbrev_7, 3
        ASSERT_RECORD_TABLE_SIZE dow_strings, 7, 4

parsed_date:
        .tag ParsedDateTime

;;; GrafPort used when drawing the clock
clock_grafport:
        .tag MGTK::GrafPort

;;; Used to save the current GrafPort while drawing the clock.
.params getport_params
portptr:        .addr   0
.endparams

;;; ============================================================

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

;;; ============================================================

        PAD_TO ::kSegmentDeskTopLC1AAddress + ::kSegmentDeskTopLC1ALength

;;; (there's enough room here for 128 files at up to 28 bytes each; index 0 not used)
icon_entries:
        .assert ($FB00 - *) >= (kMaxIconCount+1) * .sizeof(IconEntry), error, "Not enough room for icons"

;;; There's plenty of room after that (~409 bytes) if additional
;;; buffer space is needed.

;;; ============================================================
;;; Segment loaded into AUX $FB00-$FFFF
;;; ============================================================

        .org ::kSegmentDeskTopLC1BAddress


;;; Map IconType to other icon/details

icontype_iconentryflags_table:
        .byte   0                    ; generic
        .byte   0                    ; text
        .byte   0                    ; binary
        .byte   0                    ; graphics
        .byte   0                    ; music
        .byte   0                    ; font
        .byte   0                    ; relocatable
        .byte   0                    ; command
        .byte   kIconEntryFlagsDropTarget ; folder
        .byte   0                    ; iigs
        .byte   0                    ; appleworks db
        .byte   0                    ; appleworks wp
        .byte   0                    ; appleworks sp
        .byte   0                    ; archive
        .byte   0                    ; desk accessory
        .byte   0                    ; basic
        .byte   0                    ; system
        .byte   0                    ; application
        ASSERT_TABLE_SIZE icontype_iconentryflags_table, IconType::COUNT

type_icons_table:               ; map into definitions below
        .addr   gen ; generic
        .addr   txt ; text
        .addr   bin ; binary
        .addr   fot ; graphics
        .addr   mus ; music
        .addr   fnt ; font
        .addr   rel ; relocatable
        .addr   cmd ; command
        .addr   dir ; folder
        .addr   src ; iigs
        .addr   adb ; appleworks db
        .addr   awp ; appleworks wp
        .addr   asp ; appleworks sp
        .addr   arc ; archive
        .addr   a2d ; desk accessory
        .addr   bas ; basic
        .addr   sys ; system
        .addr   app ; application
        ASSERT_ADDRESS_TABLE_SIZE type_icons_table, IconType::COUNT

        DEFINE_ICON_RESOURCE gen, generic_icon, 4, 27, 15, generic_mask
        DEFINE_ICON_RESOURCE src, aux::iigs_file_icon, 4, 27, 15, generic_mask
        DEFINE_ICON_RESOURCE rel, aux::rel_file_icon, 4, 27, 14, binary_mask
        DEFINE_ICON_RESOURCE cmd, aux::cmd_file_icon, 4, 27, 8, aux::graphics_mask
        DEFINE_ICON_RESOURCE txt, text_icon, 4, 27, 15, generic_mask
        DEFINE_ICON_RESOURCE bin, binary_icon, 4, 27, 14, binary_mask
        DEFINE_ICON_RESOURCE dir, folder_icon, 4, 27, 11, folder_mask
        DEFINE_ICON_RESOURCE sys, sys_icon, 4, 27, 17, sys_mask
        DEFINE_ICON_RESOURCE bas, aux::basic_icon, 4, 27, 14, aux::basic_mask
        DEFINE_ICON_RESOURCE fot, aux::graphics_icon, 4, 27, 12, aux::graphics_mask
        DEFINE_ICON_RESOURCE mus, aux::music_icon, 4, 27, 15, generic_mask
        DEFINE_ICON_RESOURCE adb, aux::adb_icon, 4, 27, 15, generic_mask
        DEFINE_ICON_RESOURCE awp, aux::awp_icon, 4, 27, 15, generic_mask
        DEFINE_ICON_RESOURCE asp, aux::asp_icon, 4, 27, 15, generic_mask
        DEFINE_ICON_RESOURCE arc, aux::archive_icon, 4, 25, 14, aux::archive_mask
        DEFINE_ICON_RESOURCE a2d, aux::a2d_file_icon, 4, 27, 15, generic_mask
        DEFINE_ICON_RESOURCE fnt, aux::font_icon, 4, 27, 15, generic_mask
        DEFINE_ICON_RESOURCE app, app_icon, 5, 34, 16, app_mask

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



;;; ============================================================
;;; Settings - modified by Control Panels
;;; ============================================================

        PAD_TO ::BELLDATA
        .include "../lib/default_sound.s"

        PAD_TO ::SETTINGS
        .include "../lib/default_settings.s"

;;; ============================================================

;;; Reserved space for 6502 vectors
;;; * NMI is rarely used
;;; * On RESET, the main page/ROM is banked in (Enh. IIe, IIc, IIgs)
;;; * IRQ must be preserved; points into firmware
;;; ... but might as well preserved

        ASSERT_ADDRESS VECTORS
        .res    kIntVectorsSize, 0

        ASSERT_ADDRESS ::kSegmentDeskTopLC1BAddress + ::kSegmentDeskTopLC1BLength
        ASSERT_ADDRESS $10000
