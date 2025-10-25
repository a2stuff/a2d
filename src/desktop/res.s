;;; ============================================================
;;; DeskTop - Resources
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

pencopy:        .byte   MGTK::pencopy
penXOR:         .byte   MGTK::penXOR
notpencopy:     .byte   MGTK::notpencopy

;;; ============================================================
;;; Re-used param space for events/queries (10 bytes)

        .include "../lib/event_params.s"
;;; ============================================================

.params getwinport_params
window_id:     .byte   0
a_grafport:     .addr   window_grafport
.endparams

;;; GrafPort used specifically for operations that draw into windows.

window_grafport:        .tag    MGTK::GrafPort

;;; GrafPort used for nearly all operations. Usually re-initialized
;;; before use.

desktop_grafport:        .tag   MGTK::GrafPort

;;; ============================================================

        ;; Copies of ROM bytes used for machine identification
.params startdesktop_params
machine:        .byte   $06     ; ROM FBB3 ($06 = IIe or later)
subid:          .byte   $EA     ; ROM FBC0 ($EA = IIe, $E0 = IIe enh/IIgs, $00 = IIc/IIc+)
op_sys:         .byte   0       ; 0=ProDOS
slot_num:       .byte   0       ; Mouse slot, 0 = search
use_interrupts: .byte   0       ; 0=passive
systextfont:    .addr   DEFAULT_FONT
savearea:       .addr   SAVE_AREA_BUFFER
savesize:       .word   kSaveAreaSize
.endparams

;;; Shift key mod sets PB2 if shift is *not* down. Since we can't detect
;;; the mod, snapshot on init (and assume shift is not down) and XOR.
pb2_initial_state:
        .byte   0

.params initmenu_params
open_char:      .byte   kGlyphOpenApple
solid_char:     .byte   kGlyphSolidApple
        ASSERT_EQUALS (solid_char - open_char), 1, "solid_char must follow open_char immediately"
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

.params scalemouse_params
x_exponent:     .byte   1       ; MGTK default is x 2:1 and y 1:1
y_exponent:     .byte   0       ; ... doubled on IIc / IIc+
.endparams

num_selector_list_items:
        .byte   0

;;; Generic path buffer. In file dialog, used as current path.
path_buf0:
        .res    kPathBufferSize, 0

;;; Generic path buffer. Used primarily as line edit text content,
;;; and for composing long alert messages.
text_input_buf:
        .res    128, 0

;;; ============================================================

.params winfo_rename_dialog
        kWindowId = $12
        kWidth = kIconRenameLineEditWidth
        kHeight = kTextBoxHeight - 2

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
mincontheight:  .word   50
maxcontwidth:   .word   500
maxcontheight:  .word   140
port:
        DEFINE_POINT viewloc, SELF_MODIFIED, SELF_MODIFIED
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kWidth, kHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        DEFINE_LINE_EDIT rename_line_edit_rec, winfo_rename_dialog::kWindowId, text_input_buf, 0, -1, kIconRenameLineEditWidth, kMaxFilenameLength
        DEFINE_LINE_EDIT_PARAMS rename_le_params, rename_line_edit_rec

;;; ============================================================
;;; Dialog used for:
;;; * File > Get Info
;;; * Special > Format Disk...
;;; * Special > Erase Disk...

        kPromptDialogWidth = 400
        kPromptDialogHeight = 107
        kPromptDialogLeft = (kScreenWidth - kPromptDialogWidth) / 2
        kPromptDialogTop  = (kScreenHeight - kPromptDialogHeight) / 2

.params winfo_prompt_dialog
        kWindowId = $13
        kWidth = kPromptDialogWidth
        kHeight = kPromptDialogHeight

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
mincontheight:  .word   50
maxcontwidth:   .word   500
maxcontheight:  .word   140
port:
        DEFINE_POINT viewloc, kPromptDialogLeft, kPromptDialogTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kWidth, kHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        kDialogLabelDefaultX    =  40
        kDialogLabelRightX      = 160
        kDialogValueLeft        = 170

        kNameInputLeft = kDialogLabelDefaultX
        kNameInputTop = 67
        kNameInputWidth = 320

        DEFINE_RECT_SZ name_input_rect, kNameInputLeft, kNameInputTop, kNameInputWidth, kTextBoxHeight
        DEFINE_POINT pos_dialog_title, 0, aux::kDialogTitleY

        DEFINE_POINT dialog_label_pos, kDialogLabelDefaultX, 0

        kPromptWindowId = winfo_prompt_dialog::kWindowId
        DEFINE_BUTTON ok_button, kPromptWindowId, res_string_button_ok, kGlyphReturn, 260, kPromptDialogHeight-19
        DEFINE_BUTTON cancel_button, kPromptWindowId, res_string_button_cancel, res_string_button_cancel_shortcut, 40, kPromptDialogHeight-19

        DEFINE_BUTTON locked_button, kPromptWindowId, res_string_get_info_checkbox_locked, res_string_get_info_shortcut_locked, kDialogValueLeft, aux::kDialogLabelRow5+2

;;; $00 = ok/cancel
;;; $80 = ok (only)
prompt_button_flags:
        .byte   0
has_input_field_flag:
        .byte   0
has_device_picker_flag:      ; bit7 set when prompt is showing device picker
        .byte   0

;;; ============================================================

.params winfo_progress_dialog
        kWindowId = $11

        kWidth = aux::kProgressDialogWidth
        kHeight = aux::kProgressDialogHeight
        kLeft = (kScreenWidth - kWidth) / 2
        kTop  = (kScreenHeight - kHeight) / 6

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
mincontheight:  .word   50
maxcontwidth:   .word   500
maxcontheight:  .word   140
port:
        DEFINE_POINT viewloc, kLeft, kTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kWidth, kHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        kProgressDialogPathLeft = 60
        kProgressDialogPathWidth = winfo_progress_dialog::kWidth - kProgressDialogPathLeft - kProgressDialogLabelDefaultX

        kProgressDialogLabelDefaultX    = 25
        kProgressDialogLabelBaseY       = 17
        DEFINE_POINT progress_dialog_label_pos, kProgressDialogLabelDefaultX, 0
        DEFINE_POINT progress_dialog_remaining_pos, aux::kProgressDialogWidth/2, aux::kProgressDialogLabelRow0

        kProgressBarTop = 41
        kProgressBarWidth = winfo_progress_dialog::kWidth - kProgressDialogLabelDefaultX*2
        kProgressBarHeight = 7
        DEFINE_RECT_SZ progress_dialog_bar_frame, kProgressDialogLabelDefaultX-1, kProgressBarTop-1, kProgressBarWidth+2, kProgressBarHeight+2
        DEFINE_RECT_SZ progress_dialog_bar_meter, kProgressDialogLabelDefaultX, kProgressBarTop,  kProgressBarWidth,kProgressBarHeight

progress_pattern:
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001

.params progress_muldiv_params
number:         .word   kProgressBarWidth ; (in) constant
numerator:      .word   0                 ; (in) populated dynamically
denominator:    .word   0                 ; (in) populated dynamically
result:         .word   0                 ; (out)
remainder:      .word   0                 ; (out)
        REF_MULDIV_MEMBERS
.endparams

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
mincontheight:  .word   50
maxcontwidth:   .word   500
maxcontheight:  .word   140
port:
        DEFINE_POINT viewloc, (kScreenWidth - kWidth) / 2, (kScreenHeight - kHeight) / 2
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kWidth, kHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
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
mincontheight:  .word   50
maxcontwidth:   .word   500
maxcontheight:  .word   140
port:
        DEFINE_POINT viewloc, (kScreenWidth - kWidth) / 2, (kScreenHeight - kHeight) / 2
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kWidth, kHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME entry_picker_frame_rect, winfo_entry_picker::kWidth, winfo_entry_picker::kHeight

        ;; Options control metrics
        kShortcutPickerCols = 3
        kShortcutPickerRows = 8
        kShortcutPickerLeft = (winfo_entry_picker::kWidth - kShortcutPickerItemWidth * kShortcutPickerCols + 1) / 2
        kShortcutPickerTop  = 24
        kShortcutPickerItemWidth  = 104
        kShortcutPickerItemHeight = kListItemHeight
        kShortcutPickerTextHOffset = 10
        kShortcutPickerTextVOffset = kShortcutPickerItemHeight - 1

        DEFINE_OPTION_PICKER shortcut_picker_record, winfo_entry_picker::kWindowId, kShortcutPickerLeft, kShortcutPickerTop, kShortcutPickerRows, kShortcutPickerCols, kShortcutPickerItemWidth, kShortcutPickerItemHeight, kShortcutPickerTextHOffset, kShortcutPickerTextVOffset, ShortcutPickerIsEntryCallback, ShortcutPickerDrawEntryCallback, ShortcutPickerSelChangeCallback
        DEFINE_OPTION_PICKER_PARAMS shortcut_picker_params, shortcut_picker_record

;;; OPTK callbacks need to be aux-callable, so use these relays
ShortcutPickerIsEntryCallback:
        jsr     BankInMain
        jsr     SelectorPickOverlay::IsEntryCallback
        jmp     BankInAux

ShortcutPickerDrawEntryCallback:
        jsr     BankInMain
        jsr     SelectorPickOverlay::DrawEntryCallback
        jmp     BankInAux

ShortcutPickerSelChangeCallback:
        jsr     BankInMain
        jsr     SelectorPickOverlay::SelChangeCallback
        jmp     BankInAux


        ;; Line endpoints
        DEFINE_POINT entry_picker_line1_start, kBorderDX*2, 22
        DEFINE_POINT entry_picker_line1_end, winfo_entry_picker::kWidth - kBorderDX*2, 22
        DEFINE_POINT entry_picker_line2_start, kBorderDX*2, winfo_entry_picker::kHeight-21
        DEFINE_POINT entry_picker_line2_end, winfo_entry_picker::kWidth - kBorderDX*2, winfo_entry_picker::kHeight-21

        DEFINE_BUTTON entry_picker_ok_button, winfo_entry_picker::kWindowId, res_string_button_ok, kGlyphReturn, 210, winfo_entry_picker::kHeight-18
        DEFINE_BUTTON entry_picker_cancel_button, winfo_entry_picker::kWindowId, res_string_button_cancel, res_string_button_cancel_shortcut, 40, winfo_entry_picker::kHeight-18

;;; ============================================================
;;; Format/Erase dialogs

        ;; Options control metrics
        kVolPickerCols = 3
        kVolPickerRows = 5
        .assert kMaxDevListSize <= kVolPickerRows * kVolPickerCols, error, "can't fit all vols"
        kVolPickerLeft = (winfo_prompt_dialog::kWidth - kVolPickerItemWidth * kVolPickerCols + 1) / 2
        kVolPickerTop = 34
        kVolPickerItemWidth = 127
        kVolPickerItemHeight = kListItemHeight
        kVolPickerTextHOffset = 1
        kVolPickerTextVOffset = kVolPickerItemHeight-1

        DEFINE_OPTION_PICKER vol_picker_record, winfo_prompt_dialog::kWindowId, kVolPickerLeft, kVolPickerTop, kVolPickerRows, kVolPickerCols, kVolPickerItemWidth, kVolPickerItemHeight, kVolPickerTextHOffset, kVolPickerTextVOffset, VolPickerIsEntryCallback, VolPickerDrawEntryCallback, VolPickerSelChangeCallback
        DEFINE_OPTION_PICKER_PARAMS vol_picker_params, vol_picker_record

;;; OPTK callbacks need to be aux-callable, so use these relays
VolPickerIsEntryCallback:
        jsr     BankInMain
        jsr     FormatEraseOverlay::IsEntryCallback
        jmp     BankInAux

VolPickerDrawEntryCallback:
        jsr     BankInMain
        jsr     FormatEraseOverlay::DrawEntryCallback
        jmp     BankInAux

VolPickerSelChangeCallback:
        jsr     BankInMain
        jsr     FormatEraseOverlay::SelChangeCallback
        jmp     BankInAux

        ;; Label pos
        DEFINE_POINT vol_picker_select_pos, kDialogLabelDefaultX, kVolPickerTop - 4

        ;; Line endpoints
        DEFINE_POINT vol_picker_line1_start, 7, kVolPickerTop - 2
        DEFINE_POINT vol_picker_line1_end, winfo_prompt_dialog::kWidth - 8, kVolPickerTop - 2
        DEFINE_POINT vol_picker_line2_start, 7, winfo_prompt_dialog::kHeight-22
        DEFINE_POINT vol_picker_line2_end, winfo_prompt_dialog::kWidth - 8, winfo_prompt_dialog::kHeight-22

the_dos_33_disk_format:
        PASCAL_STRING res_string_the_dos_33_disk_format

the_disk_in_slot_format:
        PASCAL_STRING res_string_the_disk_in_slot_format

;;; ============================================================
;;; Name prompt dialog (used for Format/Erase)

        DEFINE_LINE_EDIT prompt_line_edit_rec, winfo_prompt_dialog::kWindowId, text_input_buf, kNameInputLeft, kNameInputTop, kNameInputWidth, kMaxFilenameLength
        DEFINE_LINE_EDIT_PARAMS prompt_le_params, prompt_line_edit_rec

;;; ============================================================

str_kb_suffix:
        PASCAL_STRING res_string_kb_suffix       ; suffix for kilobytes

file_count:                     ; increments during enumeration, decrements during op
        .word   0
total_count:                    ; increments during enumeration
        .word   0
block_count:                    ; totaled during enumeration
        .word   0

;;; ============================================================

        FONT := DEFAULT_FONT
        FD_EXTENDED = 1
        .include "../lib/file_dialog_res.s"

;;; ============================================================
;;; Resources for Add/Edit a Shortcut dialog

enter_the_name_to_appear_label:
        PASCAL_STRING res_string_selector_label_enter_name

kRadioButtonLeft  = 332

        kFDWinId = file_dialog_res::kFilePickerDlgWindowID

        DEFINE_LABEL add_a_new_entry_to, res_string_selector_label_add_a_new_entry_to,                   329, 35

        DEFINE_BUTTON primary_run_list_button,   kFDWinId, res_string_selector_label_primary_run_list, res_string_shortcut_apple_1, kRadioButtonLeft, 37
        DEFINE_BUTTON secondary_run_list_button, kFDWinId, res_string_selector_label_secondary_run_list, res_string_shortcut_apple_2, kRadioButtonLeft, 47

        DEFINE_LABEL down_load,          res_string_selector_label_download,                             329, 69

        DEFINE_BUTTON at_first_boot_button,      kFDWinId, res_string_selector_label_at_first_boot, res_string_shortcut_apple_3, kRadioButtonLeft, 71
        DEFINE_BUTTON at_first_use_button,       kFDWinId, res_string_selector_label_at_first_use, res_string_shortcut_apple_4, kRadioButtonLeft, 81
        DEFINE_BUTTON never_button,              kFDWinId, res_string_selector_label_never, res_string_shortcut_apple_5, kRadioButtonLeft, 91

;;; ============================================================

label_copy_selection:
        PASCAL_STRING res_string_menu_item_copy_selection

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

month_table := *-2
        .addr   str_jan,str_feb,str_mar,str_apr,str_may,str_jun
        .addr   str_jul,str_aug,str_sep,str_oct,str_nov,str_dec
        ASSERT_ADDRESS_TABLE_SIZE month_table, 13

str_no_date:
        PASCAL_STRING res_string_no_date
str_space:
        PASCAL_STRING " "
str_today:
        PASCAL_STRING res_string_today
str_yesterday:
        PASCAL_STRING res_string_yesterday
str_tomorrow:
        PASCAL_STRING res_string_tomorrow

str_datetime_format:
        PASCAL_STRING res_string_datetime_format

str_mdy_format:
        PASCAL_STRING res_string_mdy_format

str_dmy_format:
        PASCAL_STRING res_string_dmy_format

;;; ============================================================
;;; Shortcuts ("run list")

        ;; Buffer for Run List entries
        kMaxRunListEntries = 8

;;; Names (used in menus, must be visible to MGTK in Aux)
run_list_entries:
        .res    kMaxRunListEntries * 16, 0

;;; ============================================================
;;; Window & Icon State
;;; ============================================================

        ;; Used when restoring windows
        DEFINE_POINT new_window_viewloc, 0,0
        DEFINE_RECT new_window_maprect, 0,0,0,0
new_window_view_by:     .byte   0

        ;; Total number of icons
icon_count:
        .byte   0

;;; Copy out of `window_entry_table` of icon list for active window (0=desktop)

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

;;; Table of desktop window `Winfo` addresses
win_table:
        .addr   0
        .repeat ::kMaxDeskTopWindows,i
        .addr   .ident(.sprintf("winfo%d",i+1))
        .endrepeat
        ASSERT_ADDRESS_TABLE_SIZE win_table, kMaxDeskTopWindows + 1

;;; ============================================================

;;; IconTK initialization parameters
.params itkinit_params
headersize:     .byte   kWindowHeaderHeight
a_polybuf:      .addr   SAVE_AREA_BUFFER
bufsize:        .word   kSaveAreaSize
a_typemap:      .addr   type_icons_table
a_heap:         .addr   icon_entries
.endproc

;;; Table mapping IconType to IconResource
type_icons_table:
        ;; Volumes
        .addr   trash_icon      ; trash
        .addr   floppy140_icon  ; floppy140
        .addr   ramdisk_icon    ; ramdisk
        .addr   profile_icon    ; profile
        .addr   floppy800_icon  ; floppy800
        .addr   fileshare_icon  ; fileshare
        .addr   cdrom_icon      ; cdrom

        ;; Files
        .addr   gen             ; generic
        .addr   txt             ; text
        .addr   bin             ; binary
        .addr   fot             ; graphics
        .addr   anm             ; animation
        .addr   mus             ; music
        .addr   mus             ; tracker
        .addr   snd             ; audio
        .addr   tts             ; speech
        .addr   fnt             ; font
        .addr   rel             ; relocatable
        .addr   cmd             ; command
        .addr   dir             ; folder
        .addr   sdr             ; system_folder
        .addr   src             ; iigs
        .addr   adb             ; appleworks_db
        .addr   awp             ; appleworks_wp
        .addr   asp             ; appleworks_sp
        .addr   arc             ; archive
        .addr   arc             ; encoded
        .addr   lnk             ; link
        .addr   a2d             ; desk_accessory
        .addr   bas             ; basic
        .addr   int             ; intbasic
        .addr   var             ; variables
        .addr   sys             ; system
        .addr   app             ; application

        ;; Small icons
        .addr   sm_gen
        .addr   sm_dir
        ASSERT_ADDRESS_TABLE_SIZE type_icons_table, IconType::COUNT

;;; Used for multiple IconTK calls:
;;; * IconTK::EraseIcon
;;; * IconTK::HighlightIcon
;;; * IconTK::IconInRect (with following `tmp_rect`)
;;; * IconTK::DrawIcon
;;; * IconTK::FreeIcon
;;; * IconTK::UnhighlightIcon
;;; * IconTK::GetIconBounds (with following `tmp_rect`)
;;; * IconTK::GetRenameRect (with following `tmp_rect`)
icon_param:  .byte   0

        ;; Used for all sorts of temporary work
        ;; * follows icon_param for IconTK::IconInRect call
        ;; * used for saving/restoring window bounds to/from file
        ;; * used for icon clipping
        ;; * used for window frame zoom animation
        ASSERT_ADDRESS icon_param+1
        DEFINE_RECT tmp_rect, 0, 0, 0, 0

;;; Used by IconTK::AllocIcon and IconTK::GetIconEntry
;;; TODO: See if we can use `icon_param` for this
.params get_icon_entry_params
id:     .byte   0
addr:   .addr   0
.endparams

;;; Used for IconTK::OffsetAll
.params offset_icons_params
window_id:      .byte   0
delta_x:        .word   0
delta_y:        .word   0
.endparams

;;; Used by DeskTop to pad `tmp_rect`
.params bbox_pad_tmp_rect
        .addr   tmp_rect
        .word   kIconBBoxPaddingX, kIconBBoxPaddingY
.endparams

;;; Used by DeskTop to compute bounding box for icons
.params get_iconbb
window_id:      .byte   0
rect:           .tag    MGTK::Rect
.endparams
iconbb_rect := get_iconbb::rect

;;; Used by DeskTop to pad `iconbb_rect`
.params bbox_pad_iconbb_rect
        .addr   iconbb_rect
        .word   kIconBBoxPaddingX, kIconBBoxPaddingY
.endparams

;;; Used by DeskTop to expand `iconbb_rect` in `ScrollManager`
.params unionrects_viewport_iconbb
        .addr   window_grafport+MGTK::GrafPort::maprect
        .addr   iconbb_rect
.endparams


;;; ============================================================
;;; Alerts

alert_params:   .tag    AlertParams

;;; ============================================================

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

        ;; Startup menu
        DEFINE_MENU startup_menu, kMenuSizeStartup
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

        kDeviceNameLength = 16 + .strlen(res_string_sd_name_format) - 6
        .repeat kMaxVolumes+1, i
        .ident(.sprintf("dev%ds", i)) := *
        .res    kDeviceNameLength, 0
        .endrepeat

;;; Startup menu items (populated by slot scan at startup)

startup_menu_item_1:    PASCAL_STRING res_string_menu_item_slot_pattern
startup_menu_item_2:    PASCAL_STRING res_string_menu_item_slot_pattern
startup_menu_item_3:    PASCAL_STRING res_string_menu_item_slot_pattern
startup_menu_item_4:    PASCAL_STRING res_string_menu_item_slot_pattern
startup_menu_item_5:    PASCAL_STRING res_string_menu_item_slot_pattern
startup_menu_item_6:    PASCAL_STRING res_string_menu_item_slot_pattern
startup_menu_item_7:    PASCAL_STRING res_string_menu_item_slot_pattern
        kStartupMenuItemSlotOffset = res_const_menu_item_slot_pattern_offset1

;;; ============================================================

        ;; Shortcuts menu
        DEFINE_MENU selector_menu, kSelectorMenuFixedItems
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

        ASSERT_EQUALS ::kMenuItemIdSelectorAdd, SelectorAction::add
        ASSERT_EQUALS ::kMenuItemIdSelectorEdit, SelectorAction::edit
        ASSERT_EQUALS ::kMenuItemIdSelectorDelete, SelectorAction::delete
        ASSERT_EQUALS ::kMenuItemIdSelectorRun, SelectorAction::run

label_add:
        PASCAL_STRING res_string_menu_item_add_entry ; also dialog title
label_edit:
        PASCAL_STRING res_string_menu_item_edit_entry ; also dialog title
label_del:
        PASCAL_STRING res_string_menu_item_delete_entry ; also dialog title
label_run:
        PASCAL_STRING res_string_menu_item_run_entry ; also dialog title

kDAMenuItemSize = 19            ; length (1) + filename (15) + folder glyphs prefix (3)

        ;; Apple menu
        DEFINE_MENU apple_menu, kAppleMenuFixedItems
@items: DEFINE_MENU_ITEM label_about
        DEFINE_MENU_ITEM label_about_this_apply
        DEFINE_MENU_SEPARATOR
        .repeat kMaxDeskAccCount, i
        DEFINE_MENU_ITEM desk_acc_names + i * kDAMenuItemSize
        .endrepeat
        .assert 3 + kMaxDeskAccCount = kMenuSizeApple, error, "Menu size mismatch"
        ASSERT_RECORD_TABLE_SIZE @items, kMenuSizeApple, .sizeof(MGTK::MenuItem)

label_about:
        PASCAL_STRING res_string_menu_item_about
label_about_this_apply:
        PASCAL_STRING res_string_menu_item_about_this_apple

desk_acc_names:
        .res    kMaxDeskAccCount * kDAMenuItemSize, 0

window_title_addr_table:
        .addr   0
        .repeat ::kMaxDeskTopWindows,i
        .addr   .ident(.sprintf("winfo%dtitle",i+1))
        .endrepeat
        ASSERT_ADDRESS_TABLE_SIZE window_title_addr_table, kMaxDeskTopWindows + 1

;;; `win_view_by_table` is indexed by window id - 1; allow referencing
;;; the desktop (window id 0), which is always icon view.
        .byte   DeskTopSettings::kViewByIcon
win_view_by_table:
        .res    kMaxDeskTopWindows, 0

        DEFINE_POINT pos_col, 0, 0
        kColSize = 180          ; right-aligned
        kColLock = 186
        kColType = 200
        kColDate = 231

;;; Scratch buffer visible to MGTK, primarily used for list view columns.
kTextBuffer2Len = 49
text_buffer2:    .res   kTextBuffer2Len, 0

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
hthumbmax:      .byte   kScrollThumbMax
hthumbpos:      .byte   0
vthumbmax:      .byte   kScrollThumbMax
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   170
mincontheight:  .word   50
maxcontwidth:   .word   545
maxcontheight:  .word   175
port:
        DEFINE_POINT viewloc, 20, 27
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, 440, 120
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

buflabel:       .res    16, 0
.endmacro

        .repeat ::kMaxDeskTopWindows,i
        WINFO_DEFN i+1, .ident(.sprintf("winfo%d",i+1)), .ident(.sprintf("winfo%dtitle",i+1))
        .endrepeat

;;; ============================================================
;;; Resources for window header (Items/K in disk/K available)

        DEFINE_POINT header_text_pos, 0, 0
        DEFINE_POINT header_text_delta, 0, 0

        DEFINE_POINT header_line_left, 0, 0
        DEFINE_POINT header_line_right, 0, 0

str_from_int:                   ; populated by IntToString
        PASCAL_STRING "000,000" ; 6 digits plus thousands separator

;;; Selection drag/drop icon/target, and coords
.params drag_drop_params
icon:
target: .byte   0
        DEFINE_POINT coords, 0, 0
.endparams

;;; ============================================================
;;; Resources for scrollbar calculations

.params track_muldiv_params
number:         .word   0               ; (in) populated dynamically
numerator:      .word   0               ; (in) populated dynamically
denominator:    .word   kScrollThumbMax ; (in) constant
result:         .word   0               ; (out)
remainder:      .word   0               ; (out)
        REF_MULDIV_MEMBERS
.endparams

.params setthumb_muldiv_params
number:         .word   0               ; (in) populated dynamically
numerator:      .word   kScrollThumbMax ; (in) constant
denominator:    .word   0               ; (in) populated dynamically
result:         .word   0               ; (out)
remainder:      .word   0               ; (out)
        REF_MULDIV_MEMBERS
.endparams

;;; ============================================================

;;; Always tracks the front window, or 0 if none. Updated when a
;;; window is opened (via `MGTK::OpenWindow`), closed (via
;;; `MGTK::FrontWindow`), or activated (via `MGTK::SelectWindow`).
active_window_id:
        .byte   0

;;; Always tracks `active_window_id` unless an icon on the desktop has
;;; been clicked.
focused_window_id:
        .byte   0

kWindowToDirIconFree = $00      ; window not in use
kWindowToDirIconNone = $FF      ; no icon
;;; Otherwise, dir (vol/folder) icon associated with window.
window_to_dir_icon_table:
        .res    kMaxDeskTopWindows, kWindowToDirIconFree

num_open_windows:
        .byte   0

;;; ============================================================

solid_pattern:
        .res    8, $FF

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
;;; Icon Resources - File Type Icons
;;; ============================================================

;;; These need to be visible to both Main and Aux. Main uses them for
;;; placing icons during creation, and Aux uses them when rendering
;;; the icons.

        DEFINE_ICON_RESOURCE gen, generic_icon, 4, 25, 15, generic_mask
        DEFINE_ICON_RESOURCE src, iigs_file_icon, 4, 25, 15, generic_mask
        DEFINE_ICON_RESOURCE rel, rel_file_icon, 4, 27, 14, binary_mask
        DEFINE_ICON_RESOURCE cmd, cmd_file_icon, 4, 27, 8, graphics_mask
        DEFINE_ICON_RESOURCE txt, text_icon, 4, 25, 15, generic_mask
        DEFINE_ICON_RESOURCE bin, binary_icon, 4, 27, 14, binary_mask
        DEFINE_ICON_RESOURCE dir, folder_icon, 4, 27, 11, folder_mask
        DEFINE_ICON_RESOURCE sdr, system_folder_icon, 4, 27, 11, folder_mask
        DEFINE_ICON_RESOURCE sys, sys_icon, 4, 27, 17, sys_mask
        DEFINE_ICON_RESOURCE bas, basic_icon, 4, 27, 14, basic_mask
        DEFINE_ICON_RESOURCE int, intbasic_icon, 4, 27, 14, basic_mask
        DEFINE_ICON_RESOURCE fot, graphics_icon, 4, 27, 12, graphics_mask
        DEFINE_ICON_RESOURCE anm, video_icon, 4, 26, 12, graphics_mask
        DEFINE_ICON_RESOURCE mus, music_icon, 4, 25, 15, generic_mask
        DEFINE_ICON_RESOURCE snd, audio_icon, 4, 25, 15, generic_mask
        DEFINE_ICON_RESOURCE tts, tts_icon, 4, 25, 15, generic_mask
        DEFINE_ICON_RESOURCE adb, adb_icon, 4, 25, 15, generic_mask
        DEFINE_ICON_RESOURCE awp, awp_icon, 4, 25, 15, generic_mask
        DEFINE_ICON_RESOURCE asp, asp_icon, 4, 25, 15, generic_mask
        DEFINE_ICON_RESOURCE arc, archive_icon, 4, 25, 14, archive_mask
        DEFINE_ICON_RESOURCE lnk, lnk_icon, 3, 19, 10, graphics_mask
        DEFINE_ICON_RESOURCE a2d, a2d_file_icon, 4, 25, 15, generic_mask
        DEFINE_ICON_RESOURCE fnt, font_icon, 4, 25, 15, generic_mask
        DEFINE_ICON_RESOURCE app, app_icon, 5, 34, 16, app_mask
        DEFINE_ICON_RESOURCE var, var_file_icon, 4, 25, 15, generic_mask

;;; ============================================================

generic_icon:                   ; Generic
        PIXELS  "####################......"
        PIXELS  "#................#..##...."
        PIXELS  "#................#....##.."
        PIXELS  "#................#......##"
        PIXELS  "#................#########"
        PIXELS  "#........................#"
        PIXELS  "#........................#"
        PIXELS  "#........................#"
        PIXELS  "#........................#"
        PIXELS  "#........................#"
        PIXELS  "#........................#"
        PIXELS  "#........................#"
        PIXELS  "#........................#"
        PIXELS  "#........................#"
        PIXELS  "#........................#"
        PIXELS  "##########################"

        ;; Generic mask is re-used for multiple "document" types
generic_mask:
        PIXELS  "####################......"
        PIXELS  "######################...."
        PIXELS  "########################.."
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"

iigs_file_icon:                 ; IIgs-specific files
        PIXELS  "####################......"
        PIXELS  "#................#..##...."
        PIXELS  "#................#....##.."
        PIXELS  "#................#......##"
        PIXELS  "#.#####.#####....#########"
        PIXELS  "#...#.....#..............#"
        PIXELS  "#...#.....#..............#"
        PIXELS  "#...#.....#..............#"
        PIXELS  "#...#.....#....###...##..#"
        PIXELS  "#...#.....#...#.....#....#"
        PIXELS  "#...#.....#...#..##..##..#"
        PIXELS  "#...#.....#...#...#....#.#"
        PIXELS  "#.#####.#####..###...##..#"
        PIXELS  "#........................#"
        PIXELS  "#........................#"
        PIXELS  "##########################"
        ;; shares `generic_mask`

rel_file_icon:                  ; Relocatable
        PIXELS  ".............##............."
        PIXELS  "...........##..##..........."
        PIXELS  ".........##......##........."
        PIXELS  ".......##..........##......."
        PIXELS  ".....##..............##....."
        PIXELS  "...##..####..####.#....##..."
        PIXELS  ".##....#...#.#....#......##."
        PIXELS  "#......#####.###..#........#"
        PIXELS  ".##....#..#..#....#......##."
        PIXELS  "...##..#...#.####.####.##..."
        PIXELS  ".....##..............##....."
        PIXELS  ".......##..........##......."
        PIXELS  ".........##......##........."
        PIXELS  "...........##..##..........."
        PIXELS  ".............##............."
        ;; shares binary_mask

cmd_file_icon:                  ; ProDOS Command
        PIXELS  "............................"
        PIXELS  "..##########................"
        PIXELS  "........####....##..##..##.."
        PIXELS  "........####......##..##...."
        PIXELS  "........####....##..##..##.."
        PIXELS  "........####......##..##...."
        PIXELS  "........####....##..##..##.."
        PIXELS  "..##########................"
        PIXELS  "............................"
        ;; shares top part of graphics_mask

text_icon:                      ; Text File
        PIXELS  "####################......"
        PIXELS  "#................#..##...."
        PIXELS  "#.....###.####.###....##.."
        PIXELS  "#................#......##"
        PIXELS  "#..###.##.###.##.#########"
        PIXELS  "#........................#"
        PIXELS  "#..#####.###.######......#"
        PIXELS  "#........................#"
        PIXELS  "#........................#"
        PIXELS  "#.....#####.###.##.####..#"
        PIXELS  "#........................#"
        PIXELS  "#..##.####.###.##.#####..#"
        PIXELS  "#........................#"
        PIXELS  "#..#####.##.##.###.####..#"
        PIXELS  "#........................#"
        PIXELS  "##########################"
        ;; shares generic_mask

binary_icon:                    ; Binary File
        PIXELS  ".............##............."
        PIXELS  "...........##..##..........."
        PIXELS  ".........##......##........."
        PIXELS  ".......##..........##......."
        PIXELS  ".....##..............##....."
        PIXELS  "...##....##.....##.....##..."
        PIXELS  ".##.....#..#...#.#.......##."
        PIXELS  "#.......#..#.....#.........#"
        PIXELS  ".##.....#..#.....#.......##."
        PIXELS  "...##....##......#.....##..."
        PIXELS  ".....##..............##....."
        PIXELS  ".......##..........##......."
        PIXELS  ".........##......##........."
        PIXELS  "...........##..##..........."
        PIXELS  ".............##............."

binary_mask:
        PIXELS  "............................"
        PIXELS  ".............##............."
        PIXELS  "...........######..........."
        PIXELS  ".........##########........."
        PIXELS  ".......##############......."
        PIXELS  ".....##################....."
        PIXELS  "...######################..."
        PIXELS  ".##########################."
        PIXELS  "...######################..."
        PIXELS  ".....##################....."
        PIXELS  ".......##############......."
        PIXELS  ".........##########........."
        PIXELS  "...........######..........."
        PIXELS  ".............##............."
        PIXELS  "............................"

folder_icon:                    ; Folder
        PIXELS  "..###########..............."
        PIXELS  ".#...........#.............."
        PIXELS  ".##########################."
        PIXELS  "#..........................#"
        PIXELS  "#..........................#"
        PIXELS  "#..........................#"
        PIXELS  "#..........................#"
        PIXELS  "#..........................#"
        PIXELS  "#..........................#"
        PIXELS  "#..........................#"
        PIXELS  "#..........................#"
        PIXELS  ".##########################."

system_folder_icon:             ; System Folder
        PIXELS  "..###########..............."
        PIXELS  ".#...........#.............."
        PIXELS  ".##########################."
        PIXELS  "#..............##..........#"
        PIXELS  "#.............##...........#"
        PIXELS  "#..........##...##.........#"
        PIXELS  "#........###########.......#"
        PIXELS  "#.......#########..........#"
        PIXELS  "#.......############.......#"
        PIXELS  "#........##########........#"
        PIXELS  "#.........###..###.........#"
        PIXELS  ".##########################."

folder_mask:
        PIXELS  "..###########..............."
        PIXELS  ".#############.............."
        PIXELS  ".##########################."
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  ".##########################."

sys_icon:                       ; System (no .SYSTEM suffix)
        PIXELS  ".##########################."
        PIXELS  "##........................##"
        PIXELS  "##..####################..##"
        PIXELS  "##..##................##..##"
        PIXELS  "##..##.##..##..##.....##..##"
        PIXELS  "##..##................##..##"
        PIXELS  "##..##.##..##.........##..##"
        PIXELS  "##..##................##..##"
        PIXELS  "##..##................##..##"
        PIXELS  "##..####################..##"
        PIXELS  "##........................##"
        PIXELS  ".##########################."
        PIXELS  "##........................##"
        PIXELS  "##..##....................##"
        PIXELS  "##........................##"
        PIXELS  "############################"
        PIXELS  "##........................##"
        PIXELS  ".##########################."

sys_mask:
        PIXELS  "............................"
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "............................"
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "..########################.."
        PIXELS  "............................"

basic_icon:                     ; BASIC Program
        PIXELS  ".............##............."
        PIXELS  "...........##..##..........."
        PIXELS  ".........##......##........."
        PIXELS  ".......##..........##......."
        PIXELS  "............................"
        PIXELS  ".#####...###...####.#..####."
        PIXELS  ".#....#.#...#.#.....#.#....."
        PIXELS  ".#####..#####..###..#.#....."
        PIXELS  ".#....#.#...#.....#.#.#....."
        PIXELS  ".#####..#...#.####..#..####."
        PIXELS  "............................"
        PIXELS  ".......##..........##......."
        PIXELS  ".........##......##........."
        PIXELS  "...........##..##..........."
        PIXELS  ".............##............."

basic_mask:
        PIXELS  "............................"
        PIXELS  ".............##............."
        PIXELS  "...........######..........."
        PIXELS  ".........##########........."
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  ".........##########........."
        PIXELS  "...........######..........."
        PIXELS  ".............##............."
        PIXELS  "............................"

intbasic_icon:
        PIXELS  ".............##............."
        PIXELS  "...........##..##..........."
        PIXELS  ".........##......##........."
        PIXELS  ".......##..........##......."
        PIXELS  "............................"
        PIXELS  ".##....####....##..########."
        PIXELS  ".##....##.##...##.....##...."
        PIXELS  ".###...##..##..###....###..."
        PIXELS  ".###...###..##.###....###..."
        PIXELS  ".###...###...#####....###..."
        PIXELS  "............................"
        PIXELS  ".......##..........##......."
        PIXELS  ".........##......##........."
        PIXELS  "...........##..##..........."
        PIXELS  ".............##............."
        ;; shares `basic_mask`

graphics_icon:                  ; Graphics
        PIXELS  "############################"
        PIXELS  "#..........................#"
        PIXELS  "#...##.....................#"
        PIXELS  "#..####............##......#"
        PIXELS  "#...##............####.....#"
        PIXELS  "#.........##.....######....#"
        PIXELS  "#.......######..########...#"
        PIXELS  "#....####################..#"
        PIXELS  "#..######################..#"
        PIXELS  "#..######################..#"
        PIXELS  "#..######################..#"
        PIXELS  "#..........................#"
        PIXELS  "############################"

graphics_mask:
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"
        PIXELS  "############################"

video_icon:
        PIXELS  "###########################"
        PIXELS  "##...##...##...##...##...##"
        PIXELS  "###########################"
        PIXELS  "#.........................#"
        PIXELS  "#.........##..............#"
        PIXELS  "#.........#####...........#"
        PIXELS  "#.........#######.........#"
        PIXELS  "#.........#####...........#"
        PIXELS  "#.........##..............#"
        PIXELS  "#.........................#"
        PIXELS  "###########################"
        PIXELS  "##...##...##...##...##...##"
        PIXELS  "###########################"
        ;; shares left part of graphics_mask

music_icon:                     ; Music
        PIXELS  "####################......"
        PIXELS  "#................#..##...."
        PIXELS  "#................#....##.."
        PIXELS  "#................#......##"
        PIXELS  "#................#########"
        PIXELS  "#............#####.......#"
        PIXELS  "#.......##########.......#"
        PIXELS  "#.......######...#.......#"
        PIXELS  "#.......#........#.......#"
        PIXELS  "#.......#........#.......#"
        PIXELS  "#.......#.....####.......#"
        PIXELS  "#....####....#####.......#"
        PIXELS  "#...#####.....###........#"
        PIXELS  "#....###.................#"
        PIXELS  "#........................#"
        PIXELS  "##########################"

audio_icon:
        PIXELS  "####################......"
        PIXELS  "#................#..##...."
        PIXELS  "#................#....##.."
        PIXELS  "#................#......##"
        PIXELS  "#................#########"
        PIXELS  "#........................#"
        PIXELS  "#........##........#.....#"
        PIXELS  "#......##.#.....#...#....#"
        PIXELS  "#..####...#..#...#...#...#"
        PIXELS  "#..#......#...#..#...#...#"
        PIXELS  "#..#......#...#..#...#...#"
        PIXELS  "#..####...#..#...#...#...#"
        PIXELS  "#......##.#.....#...#....#"
        PIXELS  "#........##........#.....#"
        PIXELS  "#........................#"
        PIXELS  "##########################"

tts_icon:                       ; Text-to-Speech
        PIXELS "####################......"
        PIXELS "#..........#.....#..##...."
        PIXELS "#..........#.....#....##.."
        PIXELS "#...##.....#.....#......##"
        PIXELS "#...##.....#.....#########"
        PIXELS "#..........#.............#"
        PIXELS "#..........#.............#"
        PIXELS "#......#####.......#.....#"
        PIXELS "#........#......#...#....#"
        PIXELS "#........#...#...#...#...#"
        PIXELS "#....#####....#..#...#...#"
        PIXELS "#........#....#..#...#...#"
        PIXELS "#........#...#...#...#...#"
        PIXELS "##########......#...#....#"
        PIXELS "#..................#.....#"
        PIXELS "##########################"

adb_icon:                       ; AppleWorks Database
        PIXELS  "####################......"
        PIXELS  "#................#..##...."
        PIXELS  "#...##...#...#...#....##.."
        PIXELS  "#..#..#..#.#.#...#......##"
        PIXELS  "#..####..#.#.#...#########"
        PIXELS  "#..#..#...#.#............#"
        PIXELS  "#........................#"
        PIXELS  "#..######..#####..#####..#"
        PIXELS  "#........................#"
        PIXELS  "#..####################..#"
        PIXELS  "#........................#"
        PIXELS  "#..######..#####..#####..#"
        PIXELS  "#........................#"
        PIXELS  "#..######..#####..#####..#"
        PIXELS  "#........................#"
        PIXELS  "##########################"
        ;; shares `generic_mask`

awp_icon:                       ; AppleWorks Word Processing
        PIXELS  "####################......"
        PIXELS  "#................#..##...."
        PIXELS  "#...##...#...#...#....##.."
        PIXELS  "#..#..#..#.#.#...#......##"
        PIXELS  "#..####..#.#.#...#########"
        PIXELS  "#..#..#...#.#............#"
        PIXELS  "#........................#"
        PIXELS  "#......####..###..#####..#"
        PIXELS  "#........................#"
        PIXELS  "#...####..#####..#####...#"
        PIXELS  "#........................#"
        PIXELS  "#...######..#####..###...#"
        PIXELS  "#........................#"
        PIXELS  "#...###..###..####..##...#"
        PIXELS  "#........................#"
        PIXELS  "##########################"

asp_icon:                       ; AppleWorks Spreadsheet
        PIXELS  "####################......"
        PIXELS  "#................#..##...."
        PIXELS  "#...##...#...#...#....##.."
        PIXELS  "#..#..#..#.#.#...#......##"
        PIXELS  "#..####..#.#.#...#########"
        PIXELS  "#..#..#...#.#............#"
        PIXELS  "#........................#"
        PIXELS  "#...##################...#"
        PIXELS  "#...##..#..#..#..#..##...#"
        PIXELS  "#...##################...#"
        PIXELS  "#...##..#..#..#..#..##...#"
        PIXELS  "#...##################...#"
        PIXELS  "#...##..#..#..#..#..##...#"
        PIXELS  "#...##################...#"
        PIXELS  "#........................#"
        PIXELS  "##########################"
        ;; shares `generic_mask`

archive_icon:                   ; Archive
        PIXELS  ".......##############....."
        PIXELS  ".......#...........#.##..."
        PIXELS  "....####...........#...##."
        PIXELS  "....#..#...........######."
        PIXELS  ".####..#................#."
        PIXELS  ".#..#..#................#."
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  ".#..#..#................#."
        PIXELS  ".#..#..##################."
        PIXELS  ".#..#................#...."
        PIXELS  ".#..##################...."
        PIXELS  ".#................#......."
        PIXELS  ".##################......."

archive_mask:
        PIXELS  ".......##############....."
        PIXELS  ".......################..."
        PIXELS  "....#####################."
        PIXELS  "....#####################."
        PIXELS  ".########################."
        PIXELS  ".########################."
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  "##########################"
        PIXELS  ".########################."
        PIXELS  ".########################."
        PIXELS  ".#####################...."
        PIXELS  ".#####################...."
        PIXELS  ".##################......."
        PIXELS  ".##################......."

a2d_file_icon:                  ; Desk Accessory
        PIXELS  "####################......"
        PIXELS  "#................#..##...."
        PIXELS  "#................#....##.."
        PIXELS  "#................#......##"
        PIXELS  "#................#########"
        PIXELS  "#............##..........#"
        PIXELS  "#...........##...........#"
        PIXELS  "#.......###...###........#"
        PIXELS  "#.....#############......#"
        PIXELS  "#....###########.........#"
        PIXELS  "#....###########.........#"
        PIXELS  "#....##############......#"
        PIXELS  "#.....############.......#"
        PIXELS  "#......####..####........#"
        PIXELS  "#........................#"
        PIXELS  "##########################"
        ;; shares `generic_mask`

font_icon:                      ; Font
        PIXELS  "####################......"
        PIXELS  "#................#..##...."
        PIXELS  "#................#....##.."
        PIXELS  "#................#......##"
        PIXELS  "#......##........#########"
        PIXELS  "#......##................#"
        PIXELS  "#.....####...............#"
        PIXELS  "#.....#.##........####...#"
        PIXELS  "#....##..##......##.###..#"
        PIXELS  "#....#...##..........##..#"
        PIXELS  "#...########.....######..#"
        PIXELS  "#...#.....##....##...##..#"
        PIXELS  "#..##......##...##...##..#"
        PIXELS  "#.####....####...#######.#"
        PIXELS  "#........................#"
        PIXELS  "##########################"
        ;; shares `generic_mask`


app_icon:                       ; System (with .SYSTEM suffix)
        PIXELS  "................##................"
        PIXELS  "..............##..##.............."
        PIXELS  "............##......##............"
        PIXELS  "..........##..........##.........."
        PIXELS  "........##..............##........"
        PIXELS  "......##..................##......"
        PIXELS  "....##......................##...."
        PIXELS  "..##................######....##.."
        PIXELS  "##................##......##....##"
        PIXELS  "..##............##...###....####.."
        PIXELS  "....##.....###############....####"
        PIXELS  "......##.......##....##.......####"
        PIXELS  "........##.......###..........####"
        PIXELS  "..........##........##############"
        PIXELS  "............##......##........####"
        PIXELS  "..............##..##.............."
        PIXELS  "................##................"

app_mask:
        PIXELS  "................##................"
        PIXELS  "..............######.............."
        PIXELS  "............##########............"
        PIXELS  "..........##############.........."
        PIXELS  "........##################........"
        PIXELS  "......######################......"
        PIXELS  "....##########################...."
        PIXELS  "..##############################.."
        PIXELS  "##################################"
        PIXELS  "..###############################."
        PIXELS  "....############################.."
        PIXELS  "......##########################.."
        PIXELS  "........##################..####.."
        PIXELS  "..........###############........."
        PIXELS  "............##########............"
        PIXELS  "..............######.............."
        PIXELS  "................##................"

var_file_icon:                  ; Applesoft/IntBASIC variables
        PIXELS  "####################......"
        PIXELS  "#................#..##...."
        PIXELS  "#...###..........#....##.."
        PIXELS  "#..#...#..#####..#......##"
        PIXELS  "#..#####.........#########"
        PIXELS  "#..#...#..#####..........#"
        PIXELS  "#..#...#.................#"
        PIXELS  "#...........#............#"
        PIXELS  "#..####....####..........#"
        PIXELS  "#..#...#..#.#....#####...#"
        PIXELS  "#..####....###...........#"
        PIXELS  "#..#...#....#.#..#####...#"
        PIXELS  "#..####...####...........#"
        PIXELS  "#...........#............#"
        PIXELS  "#........................#"
        PIXELS  "##########################"

lnk_icon:
        PIXELS  "####################"
        PIXELS  "#..................#"
        PIXELS  "#......########....#"
        PIXELS  "#........######....#"
        PIXELS  "#......########....#"
        PIXELS  "#....######..##....#"
        PIXELS  "#....####..........#"
        PIXELS  "#....##............#"
        PIXELS  "#......##..........#"
        PIXELS  "#..................#"
        PIXELS  "####################"


;;; Small Icons - use for "View > by XXXX"
;;; Same visibility rules as above.
;;; NOTE: Keep in sync with kGlyphFile* and kGlyphFolder* in the system fonts.

        DEFINE_ICON_RESOURCE sm_gen, generic_sm_icon, 2, 13, 7, generic_sm_mask
        DEFINE_ICON_RESOURCE sm_dir, folder_sm_icon, 2, 13, 6, folder_sm_mask
generic_sm_icon:
        PIXELS  "..######......"
        PIXELS  "..#....###...."
        PIXELS  "..#....#####.."
        PIXELS  "..#........#.."
        PIXELS  "..#........#.."
        PIXELS  "..#........#.."
        PIXELS  "..#........#.."
        PIXELS  "..##########.."
generic_sm_mask:
        PIXELS  "..######......"
        PIXELS  "..########...."
        PIXELS  "..##########.."
        PIXELS  "..##########.."
        PIXELS  "..##########.."
        PIXELS  "..##########.."
        PIXELS  "..##########.."
        PIXELS  "..##########.."
folder_sm_icon:
        PIXELS  ".#####........"
        PIXELS  "#.....#######."
        PIXELS  "#............#"
        PIXELS  "#............#"
        PIXELS  "#............#"
        PIXELS  "#............#"
        PIXELS  "##############"
folder_sm_mask:
        PIXELS  ".#####........"
        PIXELS  "#############."
        PIXELS  "##############"
        PIXELS  "##############"
        PIXELS  "##############"
        PIXELS  "##############"
        PIXELS  "##############"

;;; ============================================================
;;; Icon Resources - Volume Type Icons
;;; ============================================================

;;; These need to be visible to both Main and Aux. Main uses them for
;;; placing icons during creation, and Aux uses them when rendering
;;; the icons.

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

;;; CD-ROM
        DEFINE_ICON_RESOURCE cdrom_icon, cdrom_pixels, 4, 26, 14, cdrom_mask

;;; Trash Can
        kTrashIconWidth = 23
        kTrashIconHeight = 18

        DEFINE_ICON_RESOURCE trash_icon, trash_pixels, 4, kTrashIconWidth-1, kTrashIconHeight-1, trash_mask

;;; ============================================================

floppy140_pixels:               ; 5.25" Floppy Disk
        PIXELS  "###########################"
        PIXELS  "##..........###..........##"
        PIXELS  "##..........###..........##"
        PIXELS  "##..........###..........##"
        PIXELS  "##..........###..........##"
        PIXELS  "##.......................##"
        PIXELS  "##..........###..........##"
        PIXELS  "##.........#####.........##"
        PIXELS  "##..........###..........##"
        PIXELS  "##.......................##"
        PIXELS  "##.......................##"
        PIXELS  "..##.....................##"
        PIXELS  "##.......................##"
        PIXELS  "##.......................##"
        PIXELS  "###########################"

floppy140_mask:
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "..#########################"
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "###########################"

ramdisk_pixels:                 ; RAM Disk
        PIXELS  "...........#############################"
        PIXELS  "........###...........................##"
        PIXELS  ".....###..............................##"
        PIXELS  "..###.................................##"
        PIXELS  "##.........#####...####..##.....##....##"
        PIXELS  "##.........##..##.##..##.####.####....##"
        PIXELS  "##.........#####..######.##.###.##....##"
        PIXELS  "##.........##..##.##..##.##.....##....##"
        PIXELS  "##....................................##"
        PIXELS  "########################..##..##..##..##"
        PIXELS  "......................##..##..##..##..##"
        PIXELS  "......................##################"

ramdisk_mask:
        PIXELS  "...........#############################"
        PIXELS  "........################################"
        PIXELS  ".....###################################"
        PIXELS  "..######################################"
        PIXELS  "########################################"
        PIXELS  "########################################"
        PIXELS  "########################################"
        PIXELS  "########################################"
        PIXELS  "########################################"
        PIXELS  "########################################"
        PIXELS  "......................##################"
        PIXELS  "......................##################"

floppy800_pixels:               ; 3.5" Floppy Disk
        PIXELS  "####################."
        PIXELS  "##...##.......##..###"
        PIXELS  "##...##.......##...##"
        PIXELS  "##...###########...##"
        PIXELS  "##.................##"
        PIXELS  "##.................##"
        PIXELS  "##..#############..##"
        PIXELS  "##..##.........##..##"
        PIXELS  "##..##.........##..##"
        PIXELS  "##..##.........##..##"
        PIXELS  "##..##.........##..##"
        PIXELS  "#####################"

floppy800_mask:
        PIXELS  "####################."
        PIXELS  "#####################"
        PIXELS  "#####################"
        PIXELS  "#####################"
        PIXELS  "#####################"
        PIXELS  "#####################"
        PIXELS  "#####################"
        PIXELS  "#####################"
        PIXELS  "#####################"
        PIXELS  "#####################"
        PIXELS  "#####################"
        PIXELS  "#####################"

profile_pixels:                 ; Hard Disk
        PIXELS  ".###################################################."
        PIXELS  "##.................................................##"
        PIXELS  "##.................................................##"
        PIXELS  "##.................................................##"
        PIXELS  "##...###...........................................##"
        PIXELS  "##.................................................##"
        PIXELS  "##.................................................##"
        PIXELS  "##.................................................##"
        PIXELS  ".###################################################."
        PIXELS  "....###.......................................###...."

profile_mask:
        PIXELS  ".###################################################."
        PIXELS  "#####################################################"
        PIXELS  "#####################################################"
        PIXELS  "#####################################################"
        PIXELS  "#####################################################"
        PIXELS  "#####################################################"
        PIXELS  "#####################################################"
        PIXELS  "#####################################################"
        PIXELS  ".###################################################."
        PIXELS  "....###.......................................###...."

fileshare_pixels:               ; File Share / Network Drive
        PIXELS  "................##..#########......"
        PIXELS  "..............##..##........###...."
        PIXELS  "..########..##......##......#####.."
        PIXELS  "..##.....#######......##.......##.."
        PIXELS  "..##............##......##.....##.."
        PIXELS  "..##............##....##.......##.."
        PIXELS  "..##............##..##.........##.."
        PIXELS  ".#################################."
        PIXELS  ".##.............................##."
        PIXELS  "..###############################.."
        PIXELS  "..................##..##..........."
        PIXELS  ".................###..###.........."
        PIXELS  "##..##############......#######..##"
        PIXELS  "....................##............."
        PIXELS  "##..################..#########..##"

fileshare_mask:
        PIXELS  "................##..#########......"
        PIXELS  "..............#################...."
        PIXELS  "..########..#####################.."
        PIXELS  "..###############################.."
        PIXELS  "..###############################.."
        PIXELS  "..###############################.."
        PIXELS  "..###############################.."
        PIXELS  ".#################################."
        PIXELS  ".#################################."
        PIXELS  "..###############################.."
        PIXELS  "..................######..........."
        PIXELS  ".................########.........."
        PIXELS  "###################################"
        PIXELS  "###################################"
        PIXELS  "####################..#############"

cdrom_pixels:
        PIXELS  "..........#######.........."
        PIXELS  "......####.......####......"
        PIXELS  "....##.....#####.....##...."
        PIXELS  "..##....##.............##.."
        PIXELS  ".#....#.....###..........#."
        PIXELS  ".#.......#...............#."
        PIXELS  "#...#.......###.......#...#"
        PIXELS  "#......#...#...#...#......#"
        PIXELS  "#...#.......###.......#...#"
        PIXELS  ".#...............#.......#."
        PIXELS  ".#..........###.....#....#."
        PIXELS  "..##.............##....##.."
        PIXELS  "....##.....#####.....##...."
        PIXELS  "......####.......####......"
        PIXELS  "..........#######.........."

cdrom_mask:
        PIXELS  "..........#######.........."
        PIXELS  "......###############......"
        PIXELS  "....###################...."
        PIXELS  "..#######################.."
        PIXELS  ".#########################."
        PIXELS  ".#########################."
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  "###########################"
        PIXELS  ".#########################."
        PIXELS  ".#########################."
        PIXELS  "..#######################.."
        PIXELS  "....###################...."
        PIXELS  "......###############......"
        PIXELS  "..........#######.........."

trash_pixels:                   ; Trash Can
        PIXELS  ".......#########......."
        PIXELS  "......##.......##......"
        PIXELS  "#######################"
        PIXELS  "##...................##"
        PIXELS  "#######################"
        PIXELS  ".##.................##."
        PIXELS  ".##..#....#....#....##."
        PIXELS  ".##...#....#....#...##."
        PIXELS  ".##...#....#....#...##."
        PIXELS  ".##...#....#....#...##."
        PIXELS  ".##...#....#....#...##."
        PIXELS  ".##...#....#....#...##."
        PIXELS  ".##...#....#....#...##."
        PIXELS  ".##...#....#....#...##."
        PIXELS  ".##...#....#....#...##."
        PIXELS  ".##..#....#....#....##."
        PIXELS  ".##.................##."
        PIXELS  ".#####################."

trash_mask:
        PIXELS  ".......#########......."
        PIXELS  "......###########......"
        PIXELS  "#######################"
        PIXELS  "#######################"
        PIXELS  "#######################"
        PIXELS  ".#####################."
        PIXELS  ".#####################."
        PIXELS  ".#####################."
        PIXELS  ".#####################."
        PIXELS  ".#####################."
        PIXELS  ".#####################."
        PIXELS  ".#####################."
        PIXELS  ".#####################."
        PIXELS  ".#####################."
        PIXELS  ".#####################."
        PIXELS  ".#####################."
        PIXELS  ".#####################."
        PIXELS  ".#####################."

;;; ============================================================

;;; (there's enough room here for 128 files at up to 26 bytes each; index 0 not used)
icon_entries:
        .assert ($10000 - *) >= (kMaxIconCount+1) * .sizeof(IconEntry), error, "Not enough room for icons"
