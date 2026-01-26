;;; ============================================================
;;; Resources for lib/file_dialog.s
;;;
;;; Separated to support running from a separate bank than
;;; the resources.
;;; ============================================================

;;; Define `FD_LBTK_RELAYS` if LBTK is running from Aux and
;;; so callbacks will require aux>main relays.

.scope file_dialog_res

;;; Must be visible to MGTK
filename_buf:
        .res    18, 0           ; filename + length + slash (or + folder glyphs for others)

;;; Dialog title
        DEFINE_POINT pos_title, 0, 14

;;; Dialog frame
pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME dialog_frame_rect, kFilePickerDlgWidth, kFilePickerDlgHeight

;;; Multi-glyph symbols used to prefix volumes, folders and files
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

        kButtonsLeft = 195
        kMaxNameWidth = 140

;;; Labels for current directory and current volume
        kDirLabelCenterX = kControlsLeft + kListBoxWidth/2
        DEFINE_POINT dir_label_pos, kDirLabelCenterX, 16 + kSystemFontHeight
        DEFINE_RECT_SZ dir_name_rect, kDirLabelCenterX - kMaxNameWidth/2, 16, kMaxNameWidth, kSystemFontHeight
        kDiskLabelCenterX = kButtonsLeft + kButtonWidth/2
        DEFINE_POINT disk_label_pos, kDiskLabelCenterX, 16 + kSystemFontHeight
        DEFINE_RECT_SZ disk_name_rect, kDiskLabelCenterX - kMaxNameWidth/2, 16, kMaxNameWidth, kSystemFontHeight

;;; Buttons
        DEFINE_BUTTON drives_button, kFilePickerDlgWindowID, res_string_button_drives, res_string_shortcut_drives,        kButtonsLeft, kControlsTop + 0 * (kButtonHeight + kButtonGap)
        DEFINE_BUTTON open_button, kFilePickerDlgWindowID,   res_string_button_open,   res_string_shortcut_open,          kButtonsLeft, kControlsTop + 1 * (kButtonHeight + kButtonGap)
        DEFINE_BUTTON close_button, kFilePickerDlgWindowID,  res_string_button_close,  res_string_shortcut_close,         kButtonsLeft, kControlsTop + 2 * (kButtonHeight + kButtonGap)
        SUPPRESS_SHADOW_WARNING
        DEFINE_BUTTON cancel_button, kFilePickerDlgWindowID, res_string_button_cancel, res_string_button_cancel_shortcut, kButtonsLeft, kControlsTop + 3 * (kButtonHeight + kButtonGap) + kSep
        DEFINE_BUTTON ok_button, kFilePickerDlgWindowID,     res_string_button_ok,     kGlyphReturn,                      kButtonsLeft, kControlsTop + 4 * (kButtonHeight + kButtonGap) + kSep
        UNSUPPRESS_SHADOW_WARNING

;;; Separator between Drives / Open / Close and OK / Cancel
        kButtonSepY = kControlsTop + 3*kButtonHeight + 3*kButtonGap + 1
        DEFINE_POINT button_sep_start, kButtonsLeft, kButtonSepY
        DEFINE_POINT button_sep_end,   kButtonsLeft + kButtonWidth, kButtonSepY

pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy

checkerboard_pattern:
        .byte   $55, $AA, $55, $AA, $55, $AA, $55, $AA

;;; ============================================================

;;; Dialog Window

;;; A different Winfo can be passed to `OpenWindow` but it must
;;; use `kFilePickerDlgWindowID`.
        kFilePickerDlgWindowID  = $3E

        kFilePickerDlgWidth     = 323
        kFilePickerDlgHeight    = 108
        kFilePickerDlgLeft      = (kScreenWidth - kFilePickerDlgWidth) / 2
        kFilePickerDlgTop       = (kScreenHeight - kFilePickerDlgHeight) / 2

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

grafport:       .tag    MGTK::GrafPort

.params fd_getwinport_params
window_id:      .byte   kFilePickerDlgWindowID
port:           .addr   grafport
.endparams

;;; ============================================================

;;; List Box definition

        kEntryListCtlWindowID = $3F

        kListRows       = 7
        kListBoxLeft    = kControlsLeft + 1 ; +1 for external border
        kListBoxTop     = kControlsTop + 1
        kListBoxWidth   = 125
        kListBoxHeight  = kListItemHeight * kListRows - 1

        DEFINE_LIST_BOX_WINFO winfo_listbox, \
                kEntryListCtlWindowID, \
                SELF_MODIFIED, \
                SELF_MODIFIED, \
                kListBoxWidth, \
                kListBoxHeight, \
                FONT

;;; If LBTK resides in Aux then relays are needed. This is
;;; specific to DeskTop/Disk Copy.

.ifdef FD_LBTK_RELAYS

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

        ;; Used by `DrawEntryProc`
        DEFINE_POINT item_pos, 0, 0

NoOp:   rts

;;; ============================================================

.endscope ; file_dialog_res
