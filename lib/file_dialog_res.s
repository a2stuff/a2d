;;; ============================================================
;;; Resources for lib/file_dialog.s
;;;
;;; Separated to support running from a separate bank than
;;; the resources.
;;; ============================================================

.scope file_dialog_res

;;; Buffer used when selecting filename by holding Apple key and typing name.
;;; Length-prefixed string, initialized to 0 when the dialog is shown.
type_down_buf:
        .res    16, 0

        DEFINE_POINT pos_title, 0, 13

        DEFINE_RECT rect_selection, 0, 0, 125, 0

        DEFINE_POINT picker_entry_pos, 2, 0

str_folder:
        PASCAL_STRING {kGlyphFolderLeft, kGlyphFolderRight} ; do not localize

selected_index:                 ; $FF if none
        .byte   0

        DEFINE_RECT_INSET dialog_frame_rect, 4, 2, kFilePickerDlgWidth, kFilePickerDlgHeight

        DEFINE_RECT disk_name_rect, 27, 16, 174, 26

        DEFINE_BUTTON change_drive, res_string_button_change_drive, 193, 28
        DEFINE_BUTTON open,         res_string_button_open,         193, 42
        DEFINE_BUTTON close,        res_string_button_close,        193, 56
        DEFINE_BUTTON cancel,       res_string_button_cancel,       193, 71
        DEFINE_BUTTON ok,           res_string_button_ok,           193, 87

;;; Dividing line
        DEFINE_POINT dialog_sep_start, 315, 28
        DEFINE_POINT dialog_sep_end,   315, 100

        DEFINE_LABEL disk, res_string_label_disk, 28, 25

        DEFINE_POINT input1_label_pos, 28, 112
        DEFINE_POINT input2_label_pos, 28, 135

textbg1:
        .byte   0
textbg2:
        .byte   $7F

kCommonInputWidth = 435
kCommonInputHeight = 11

        DEFINE_RECT_SZ input1_rect, 28, 113, kCommonInputWidth, kCommonInputHeight
        DEFINE_POINT input1_textpos, 30, 123

        DEFINE_RECT_SZ input2_rect, 28, 136, kCommonInputWidth, kCommonInputHeight
        DEFINE_POINT input2_textpos, 30, 146

kFilePickerDlgWindowID  = $3E
kFilePickerDlgWidth     = 500
kFilePickerDlgHeight    = 153

;;; File Picker Dialog

.params winfo
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

;;; Listbox within File Picker Dialog

kEntryListCtlWindowID = $3F

.params winfo_listbox
        kWidth = 125
        kHeight = 72

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
        DEFINE_POINT viewloc, 53, 48
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
maprect:
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

.endscope ; file_dialog_res
