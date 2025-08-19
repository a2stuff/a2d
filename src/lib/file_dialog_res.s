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

        DEFINE_POINT item_pos, 0, 0

.ifdef FD_EXTENDED
        DEFINE_RECT_FRAME dialog_ex_frame_rect, kFilePickerDlgExWidth, kFilePickerDlgExHeight
.endif

kButtonsLeft = 195
kMaxNameWidth = 140

        kDirLabelCenterX = kControlsLeft + kListBoxWidth/2
        DEFINE_POINT dir_label_pos, kDirLabelCenterX, 16 + kSystemFontHeight
        DEFINE_RECT_SZ dir_name_rect, kDirLabelCenterX - kMaxNameWidth/2, 16, kMaxNameWidth, kSystemFontHeight
        kDiskLabelCenterX = kButtonsLeft + kButtonWidth/2
        DEFINE_POINT disk_label_pos, kDiskLabelCenterX, 16 + kSystemFontHeight
        DEFINE_RECT_SZ disk_name_rect, kDiskLabelCenterX - kMaxNameWidth/2, 16, kMaxNameWidth, kSystemFontHeight

        DEFINE_BUTTON drives_button, kFilePickerDlgWindowID, res_string_button_drives, res_string_shortcut_drives,        kButtonsLeft, kControlsTop + 0 * (kButtonHeight + kButtonGap)
        DEFINE_BUTTON open_button, kFilePickerDlgWindowID,   res_string_button_open,   res_string_shortcut_open,          kButtonsLeft, kControlsTop + 1 * (kButtonHeight + kButtonGap)
        DEFINE_BUTTON close_button, kFilePickerDlgWindowID,  res_string_button_close,  res_string_shortcut_close,         kButtonsLeft, kControlsTop + 2 * (kButtonHeight + kButtonGap)
        SUPPRESS_SHADOW_WARNING
        DEFINE_BUTTON cancel_button, kFilePickerDlgWindowID, res_string_button_cancel, res_string_button_cancel_shortcut, kButtonsLeft, kControlsTop + 3 * (kButtonHeight + kButtonGap) + kSep
        DEFINE_BUTTON ok_button, kFilePickerDlgWindowID,     res_string_button_ok,     kGlyphReturn,                      kButtonsLeft, kControlsTop + 4 * (kButtonHeight + kButtonGap) + kSep
        UNSUPPRESS_SHADOW_WARNING

.ifdef FD_EXTENDED
;;; Dividing line
        DEFINE_POINT dialog_sep_start, 315, kControlsTop
        DEFINE_POINT dialog_sep_end,   315, 99
.endif

        kButtonSepY = kControlsTop + 3*kButtonHeight + 3*kButtonGap + 1
        DEFINE_POINT button_sep_start, kButtonsLeft, kButtonSepY
        DEFINE_POINT button_sep_end,   kButtonsLeft + kButtonWidth, kButtonSepY

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy

checkerboard_pattern:
        .byte   $55, $AA, $55, $AA, $55, $AA, $55, $AA

kFilePickerDlgWindowID  = $3E

;;; Simple, no customizations supported
kFilePickerDlgWidth     = 323
kFilePickerDlgHeight    = 108
kFilePickerDlgLeft      = (kScreenWidth - kFilePickerDlgWidth) / 2
kFilePickerDlgTop       = (kScreenHeight - kFilePickerDlgHeight) / 2

;;; Advanced; can have name and custom controls
.ifdef FD_EXTENDED
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
mincontheight:  .word   50
maxcontwidth:   .word   500
maxcontheight:  .word   140
port:
        DEFINE_POINT viewloc, kFilePickerDlgLeft, kFilePickerDlgTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kFilePickerDlgWidth, kFilePickerDlgHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

;;; Listbox within File Picker Dialog

kEntryListCtlWindowID = $3F

        kListRows       = 7
        kListBoxLeft    = kFilePickerDlgLeft + kControlsLeft + 1 ; +1 for external border
        kListBoxTop     = kFilePickerDlgTop + kControlsTop + 1
        kListBoxWidth   = 125
        kListBoxHeight  = kListItemHeight * kListRows - 1
.ifdef FD_EXTENDED
        kExListBoxLeft  = kFilePickerDlgExLeft + kControlsLeft + 1 ; +1 for external border
        kExListBoxTop   = kFilePickerDlgExTop + 28
.endif

        DEFINE_LIST_BOX_WINFO winfo_listbox, \
                kEntryListCtlWindowID, \
                kListBoxLeft, \
                kListBoxTop, \
                kListBoxWidth, \
                kListBoxHeight, \
                FONT

.ifdef FD_EXTENDED
;;; Needed in DeskTop (LBTK in Aux, File Dialog in Main)
.proc DrawEntryProc
        jsr     BankInMain
        jsr     ::file_dialog_impl__DrawListEntryProc
        jmp     BankInAux
.endproc ; DrawEntryProc
.proc OnSelChange
        jsr     BankInMain
        jsr     ::file_dialog_impl__OnListSelectionChange
        jmp     BankInAux
.endproc ; OnSelChange
.else
DrawEntryProc := ::file_dialog_impl__DrawListEntryProc
OnSelChange   := ::file_dialog_impl__OnListSelectionChange
.endif

        DEFINE_LIST_BOX listbox_rec, file_dialog_res::winfo_listbox, \
                file_dialog_res::kListRows, SELF_MODIFIED_BYTE, \
                DrawEntryProc, OnSelChange, NoOp
        DEFINE_LIST_BOX_PARAMS lb_params, listbox_rec

NoOp:   rts

.ifdef FD_EXTENDED
        DEFINE_POINT extra_viewloc, kFilePickerDlgExLeft, kFilePickerDlgExTop
        DEFINE_POINT extra_size, kFilePickerDlgExWidth, kFilePickerDlgExHeight
        DEFINE_POINT extra_listloc, kExListBoxLeft, kExListBoxTop

        DEFINE_POINT normal_viewloc, kFilePickerDlgLeft, kFilePickerDlgTop
        DEFINE_POINT normal_size, kFilePickerDlgWidth, kFilePickerDlgHeight
        DEFINE_POINT normal_listloc, kListBoxLeft, kListBoxTop
.endif

;;; ============================================================

.ifdef FD_EXTENDED
;;; Line Edit - Filename (etc)
        kLineEditX = kControlsLeft
        kLineEditWidth = 435
        kLineEditY = 114
        kLineEditHeight = kTextBoxHeight

        DEFINE_POINT line_edit_label_pos, kLineEditX, kLineEditY-2
        DEFINE_RECT_SZ line_edit_rect, kLineEditX, kLineEditY, kLineEditWidth, kLineEditHeight

        DEFINE_LINE_EDIT line_edit, kFilePickerDlgWindowID, text_input_buf, kLineEditX, kLineEditY, kLineEditWidth, kMaxFilenameLength
        DEFINE_LINE_EDIT_PARAMS le_params, line_edit
.endif ; FD_EXTENDED

.endscope ; file_dialog_res
