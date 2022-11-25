;;; ============================================================
;;; Resources for lib/file_dialog.s
;;;
;;; Separated to support running from a separate bank than
;;; the resources.
;;; ============================================================

.scope file_dialog_res

;;; Must be visible to MGTK
filename_buf:
        .res    18, 0           ; filename + length + slash (or + folder glyphs for others)


        DEFINE_POINT pos_title, 0, 14

        kListBoxWidth = 125
        kListRows = 7

        DEFINE_RECT rect_selection, 0, 0, kListBoxWidth, 0

        DEFINE_POINT picker_entry_pos, 2, 0

str_folder:
        PASCAL_STRING {kGlyphFolderLeft, kGlyphFolderRight}
str_file:
        PASCAL_STRING {kGlyphFileLeft, kGlyphFileRight}
str_vol:
        PASCAL_STRING {kGlyphDiskLeft, kGlyphDiskRight}

        kControlsLeft = 28
        kControlsTop  = 27
        kButtonGap = 3
        kSep = kButtonGap-1 + 1 + kButtonGap-1


pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME dialog_frame_rect, kFilePickerDlgWidth, kFilePickerDlgHeight

.if FD_EXTENDED
        DEFINE_RECT_FRAME dialog_ex_frame_rect, kFilePickerDlgExWidth, kFilePickerDlgExHeight
.endif

kButtonsLeft = 195
kMaxNameWidth = 140

        kDirLabelCenterX = kControlsLeft + kListBoxWidth/2
        DEFINE_POINT dir_label_pos, 0, 16 + kSystemFontHeight
        DEFINE_RECT_SZ dir_name_rect, kDirLabelCenterX - kMaxNameWidth/2, 16, kMaxNameWidth, kSystemFontHeight
        kDiskLabelCenterX = kButtonsLeft + kButtonWidth/2
        DEFINE_POINT disk_label_pos, 0, 16 + kSystemFontHeight
        DEFINE_RECT_SZ disk_name_rect, kDiskLabelCenterX - kMaxNameWidth/2, 16, kMaxNameWidth, kSystemFontHeight

        DEFINE_BUTTON drives_button_rec, kFilePickerDlgWindowID, res_string_button_drives,, kButtonsLeft, kControlsTop + 0 * (kButtonHeight + kButtonGap)
        DEFINE_BUTTON_PARAMS drives_button_params, drives_button_rec
        DEFINE_BUTTON open_button_rec, kFilePickerDlgWindowID,         res_string_button_open,,         kButtonsLeft, kControlsTop + 1 * (kButtonHeight + kButtonGap)
        DEFINE_BUTTON_PARAMS open_button_params, open_button_rec
        DEFINE_BUTTON close_button_rec, kFilePickerDlgWindowID,        res_string_button_close,,        kButtonsLeft, kControlsTop + 2 * (kButtonHeight + kButtonGap)
        DEFINE_BUTTON_PARAMS close_button_params, close_button_rec
        DEFINE_BUTTON cancel_button_rec, kFilePickerDlgWindowID,       res_string_button_cancel, res_string_button_cancel_shortcut, kButtonsLeft, kControlsTop + 3 * (kButtonHeight + kButtonGap) + kSep
        DEFINE_BUTTON_PARAMS cancel_button_params, cancel_button_rec
        DEFINE_BUTTON ok_button_rec, kFilePickerDlgWindowID,           res_string_button_ok, kGlyphReturn,                          kButtonsLeft, kControlsTop + 4 * (kButtonHeight + kButtonGap) + kSep
        DEFINE_BUTTON_PARAMS ok_button_params, ok_button_rec

;;; Dividing line
        DEFINE_POINT dialog_sep_start, 315, kControlsTop
        DEFINE_POINT dialog_sep_end,   315, 99

        kButtonSepY = kControlsTop + 3*kButtonHeight + 3*kButtonGap + 1
        DEFINE_POINT button_sep_start, kButtonsLeft, kButtonSepY
        DEFINE_POINT button_sep_end,   kButtonsLeft + kButtonWidth, kButtonSepY

penXOR:         .byte   MGTK::penXOR
notpencopy:     .byte   MGTK::notpencopy

checkerboard_pattern:
        .byte   $55, $AA, $55, $AA, $55, $AA, $55, $AA

.if FD_EXTENDED
        kInputWidth = 435
        kInputHeight = kTextBoxHeight

        kInput1Y = 114
        DEFINE_POINT input1_label_pos, kControlsLeft, kInput1Y-1
        DEFINE_RECT_SZ input1_rect, kControlsLeft, kInput1Y, kInputWidth, kInputHeight
.endif

kFilePickerDlgWindowID  = $3E

;;; Simple, no customizations supported
kFilePickerDlgWidth     = 323
kFilePickerDlgHeight    = 108
kFilePickerDlgLeft      = (kScreenWidth - kFilePickerDlgWidth) / 2
kFilePickerDlgTop       = (kScreenHeight - kFilePickerDlgHeight) / 2

;;; Advanced; can have name and custom controls
.if FD_EXTENDED
kFilePickerDlgExWidth   = 500
kFilePickerDlgExHeight  = 132
kFilePickerDlgExLeft    = (kScreenWidth - kFilePickerDlgExWidth) / 2
kFilePickerDlgExTop     = (kScreenHeight - kFilePickerDlgExHeight) / 2
.endif

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

        REF_WINFO_MEMBERS
.endparams

;;; Listbox within File Picker Dialog

kEntryListCtlWindowID = $3F

.params winfo_listbox
        kWidth = kListBoxWidth
        kHeight = kListItemHeight * kListRows - 1
        kLeft =   kFilePickerDlgLeft + kControlsLeft + 1 ; +1 for external border

        kTop =    kFilePickerDlgTop + kControlsTop + 1
.if FD_EXTENDED
        kExLeft =   kFilePickerDlgExLeft + kControlsLeft + 1 ; +1 for external border
        kExTop =    kFilePickerDlgExTop + 28
.endif

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

        REF_WINFO_MEMBERS
.endparams

;;; ============================================================

.if FD_EXTENDED
;;; Auxiliary field
        DEFINE_LINE_EDIT line_edit_f1, kFilePickerDlgWindowID, buf_input2, kControlsLeft, kInput1Y, kInputWidth, kMaxPathLength
        DEFINE_LINE_EDIT_PARAMS le_params_f1, line_edit_f1
.endif ; FD_EXTENDED

.endscope ; file_dialog_res
