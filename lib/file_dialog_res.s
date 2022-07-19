;;; ============================================================
;;; Resources for lib/file_dialog.s
;;;
;;; Separated to support running from a separate bank than
;;; the resources.
;;; ============================================================

.scope file_dialog_res

;;; If set, control allows entering all printable characters.
;;; The default is to only allow pathname characters.
allow_all_chars_flag:
        .byte   0

;;; Buffer used when selecting filename by holding Apple key and typing name.
;;; Length-prefixed string, initialized to 0 when the dialog is shown.
type_down_buf:
        .res    16, 0

filename_buf:
        .res    17, 0           ; filename + length + slash (for some uses)

;;; Used by some clients.
input_dirty_flag:
        .byte   0

        DEFINE_POINT pos_title, 0, 14

        kListBoxWidth = 125
        kListRows = 7

        DEFINE_RECT rect_selection, 0, 0, kListBoxWidth, 0

        DEFINE_POINT picker_entry_pos, 2, 0

str_folder:
        PASCAL_STRING {kGlyphFolderLeft, kGlyphFolderRight}

selected_index:                 ; $FF if none
        .byte   0

        kControlsLeft = 28
        kControlsTop  = 26
        kButtonGap = 3
        kSep = kButtonGap + 1 + kButtonGap


pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME dialog_frame_rect, kFilePickerDlgWidth, kFilePickerDlgHeight

        DEFINE_RECT disk_name_rect, kControlsLeft, 16, 174, 26

        DEFINE_BUTTON change_drive, res_string_button_change_drive, 195, kControlsTop + 0 * (kButtonHeight + kButtonGap)
        DEFINE_BUTTON open,         res_string_button_open,         195, kControlsTop + 1 * (kButtonHeight + kButtonGap)
        DEFINE_BUTTON close,        res_string_button_close,        195, kControlsTop + 2 * (kButtonHeight + kButtonGap)
        DEFINE_BUTTON cancel,       res_string_button_cancel,       195, kControlsTop + 3 * (kButtonHeight + kButtonGap) + kSep
        DEFINE_BUTTON ok,           res_string_button_ok,           195, kControlsTop + 4 * (kButtonHeight + kButtonGap) + kSep

;;; Dividing line
        DEFINE_POINT dialog_sep_start, 315, kControlsTop
        DEFINE_POINT dialog_sep_end,   315, 100

        kButtonSepY = kControlsTop + 3*kButtonHeight + 3*kButtonGap + 2
        DEFINE_POINT button_sep_start, 195, kButtonSepY
        DEFINE_POINT button_sep_end,   195 + kButtonWidth, kButtonSepY

        DEFINE_LABEL disk, res_string_label_disk, kControlsLeft, 25


textbg1:
        .byte   0
textbg2:
        .byte   $7F

        DEFINE_RECT tmp_rect, 0, 0, 0, 0

checkerboard_pattern:
        .byte   $55, $AA, $55, $AA, $55, $AA, $55, $AA

kCommonInputWidth = 435
kCommonInputHeight = kTextBoxHeight

        kInput1Y = 111
        DEFINE_POINT input1_label_pos, kControlsLeft, kInput1Y-1
        DEFINE_RECT_SZ input1_rect, kControlsLeft, kInput1Y, kCommonInputWidth, kCommonInputHeight

.if FD_EXTENDED
        kInput2Y = 135
        DEFINE_POINT input2_label_pos, kControlsLeft, kInput2Y-1
        DEFINE_RECT_SZ input2_rect, kControlsLeft, kInput2Y, kCommonInputWidth, kCommonInputHeight
.endif

kFilePickerDlgWindowID  = $3E
kFilePickerDlgWidth     = 500

.if FD_EXTENDED
kFilePickerDlgHeight    = 153
.else
kFilePickerDlgHeight    = 129
.endif

kFilePickerDlgLeft      = (kScreenWidth - kFilePickerDlgWidth) / 2
kFilePickerDlgTop       = (kScreenHeight - kFilePickerDlgHeight) / 2

;;; File Picker Dialog

.params winfo
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
        DEFINE_POINT viewloc, kFilePickerDlgLeft, kFilePickerDlgTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kFilePickerDlgWidth, kFilePickerDlgHeight
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

;;; Listbox within File Picker Dialog

kEntryListCtlWindowID = $3F

kListEntryGlyphX = 1
kListEntryNameX  = 16

kLineDelta = 1

.params winfo_listbox
        kWidth = kListBoxWidth
        kHeight = kListItemHeight * kListRows - 1
        kLeft =   kFilePickerDlgLeft + kControlsLeft + 1 ; +1 for external border
        kTop =    kFilePickerDlgTop + 28

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
mincontlength:  .word   kHeight
maxcontwidth:   .word   100
maxcontlength:  .word   kHeight
port:
        DEFINE_POINT viewloc, kLeft, kTop
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
fontptr:        .addr   FONT
nextwinfo:      .addr   0
.endparams

;;; ============================================================

;;; Pathname field
.params line_edit_f1
START:
window_id:      .byte   kFilePickerDlgWindowID
a_buf:          .addr   buf_input1
        DEFINE_RECT_SZ rect, kControlsLeft+1, kInput1Y+1, kCommonInputWidth-2, kCommonInputHeight-2
max_length:     .byte   kMaxPathLength
dirty_flag:     .byte   0
        .res    .sizeof(LETK::LineEditRecord) - (*-START)
.endparams
.assert .sizeof(line_edit_f1) = .sizeof(LETK::LineEditRecord), error, "struct size"

.params le_params_f1
record: .addr   line_edit_f1
;;; For `LETK::Key` calls:
key       := * + 0
modifiers := * + 1
;;; For `LETK::Click` calls:
coords  := * + 0
xcoord  := * + 0
ycoord  := * + 2
        .res 4
.endparams

.if FD_EXTENDED
;;; Auxiliary field
.params line_edit_f2
START:
window_id:      .byte   kFilePickerDlgWindowID
a_buf:          .addr   buf_input2
        DEFINE_RECT_SZ rect, kControlsLeft+1, kInput2Y+1, kCommonInputWidth-2, kCommonInputHeight-2
max_length:     .byte   kMaxPathLength
dirty_flag:     .byte   0
        .res    .sizeof(LETK::LineEditRecord) - (*-START)
.endparams
.assert .sizeof(line_edit_f2) = .sizeof(LETK::LineEditRecord), error, "struct size"

.params le_params_f2
record: .addr   line_edit_f2
;;; For `LETK::Key` calls:
key       := * + 0
modifiers := * + 1
;;; For `LETK::Click` calls:
coords  := * + 0
xcoord  := * + 0
ycoord  := * + 2
        .res 4
.endparams
.endif ; FD_EXTENDED

.endscope ; file_dialog_res
