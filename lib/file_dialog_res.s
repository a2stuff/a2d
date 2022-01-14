;;; ============================================================
;;; Resources for lib/file_dialog.s
;;;
;;; Separated to support running from a separate bank than
;;; the resources.
;;; ============================================================

.scope file_dialog_res

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

.endscope ; file_dialog_res
