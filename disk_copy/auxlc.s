;;; ============================================================
;;; Disk Copy - Auxiliary LC Segment $D000 - $F1FF
;;;
;;; Compiled as part of disk_copy.s
;;; ============================================================

        BEGINSEG SegmentAuxLC
.scope auxlc

        MGTKEntry := MGTKRelayImpl

kShortcutReadDisk = res_char_button_read_drive_shortcut

;;; ============================================================

;;; number of alert messages
kNumAlertMessages = 11

kAlertMsgInsertSource           = 0 ; No bell, *
kAlertMsgInsertDestination      = 1 ; No bell, *
kAlertMsgConfirmErase           = 2 ; No bell, X,Y = pointer to volume name
kAlertMsgDestinationFormatFail  = 3 ; Bell
kAlertMsgFormatError            = 4 ; Bell
kAlertMsgDestinationProtected   = 5 ; Bell
kAlertMsgConfirmEraseSlotDrive  = 6 ; No bell, X = unit number
kAlertMsgCopySuccessful         = 7 ; No bell
kAlertMsgCopyFailure            = 8 ; No bell
kAlertMsgInsertSourceOrCancel   = 9 ; No bell, *
kAlertMsgInsertDestinationOrCancel = 10 ; No bell, *
;;; "Bell" or "No bell" determined by the `MaybeBell` proc.
;;; * = the 'InsertXOrCancel' variants are selected automatically when
;;; InsertX is specified if X flag is non-zero, and the unit number in
;;; Y identifies a removable volume. In that case, the alert will
;;; automatically be dismissed when a disk is inserted.

;;; ============================================================

        ASSERT_ADDRESS ::kSegmentAuxLCAddress, "Entry point"

start:
        jmp     init

;;; ============================================================
;;; Resources

pencopy:        .byte   MGTK::pencopy
penOR:          .byte   MGTK::penOR
penXOR:         .byte   MGTK::penXOR
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy
notpenOR:       .byte   MGTK::notpenOR
notpenXOR:      .byte   MGTK::notpenXOR
notpenBIC:      .byte   MGTK::notpenBIC

stack_stash:  .byte   0

.params hilitemenu_params
menu_id   := * + 0
.endparams
.params menuselect_params
menu_id   := * + 0
menu_item := * + 1
.endparams
.params menukey_params
menu_id   := * + 0
menu_item := * + 1
which_key := * + 2
key_mods  := * + 3
.endparams
        .res    4, 0



        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

;;; ============================================================
;;; Menu definition

        kMenuIdApple = 1
        kMenuIdFile = 2
        kMenuIdFacilities = 3

menu_definition:
        DEFINE_MENU_BAR 3
@items: DEFINE_MENU_BAR_ITEM kMenuIdApple, label_apple, menu_apple
        DEFINE_MENU_BAR_ITEM kMenuIdFile, label_file, menu_file
        DEFINE_MENU_BAR_ITEM kMenuIdFacilities, label_facilities, menu_facilities
        ASSERT_RECORD_TABLE_SIZE @items, 3, .sizeof(MGTK::MenuBarItem)

menu_apple:
        DEFINE_MENU 5
@items: DEFINE_MENU_ITEM label_desktop
        DEFINE_MENU_ITEM label_blank
        DEFINE_MENU_ITEM label_copyright1
        DEFINE_MENU_ITEM label_copyright2
        DEFINE_MENU_ITEM label_copyright3
        ASSERT_RECORD_TABLE_SIZE @items, 5, .sizeof(MGTK::MenuItem)

menu_file:
        DEFINE_MENU 1
@items: DEFINE_MENU_ITEM label_quit, res_char_dc_menu_item_quit_shortcut
        ASSERT_RECORD_TABLE_SIZE @items, 1, .sizeof(MGTK::MenuItem)

label_apple:
        PASCAL_STRING kGlyphSolidApple

menu_facilities:
        DEFINE_MENU 2
@items: DEFINE_MENU_ITEM label_quick_copy
        DEFINE_MENU_ITEM label_disk_copy
        ASSERT_RECORD_TABLE_SIZE @items, 2, .sizeof(MGTK::MenuItem)

label_file:
        PASCAL_STRING res_string_dc_menu_bar_item_file    ; menu bar item
label_facilities:
        PASCAL_STRING res_string_menu_bar_item_facilities ; menu bar item

label_desktop:
        PASCAL_STRING .sprintf(res_string_version_format_long, kDeskTopProductName, ::kDeskTopVersionMajor, ::kDeskTopVersionMinor, kDeskTopVersionSuffix)

label_blank:
        PASCAL_STRING " "
label_copyright1:
        PASCAL_STRING res_string_copyright_line1 ; menu item
label_copyright2:
        PASCAL_STRING res_string_copyright_line2 ; menu item
label_copyright3:
        PASCAL_STRING res_string_copyright_line3 ; menu item

label_quit:
        PASCAL_STRING res_string_dc_menu_item_quit    ; menu item

label_quick_copy:
        PASCAL_STRING res_string_menu_item_quick_copy ; menu item

label_disk_copy:
        PASCAL_STRING res_string_dc_menu_item_disk_copy ; menu item

;;; ============================================================

.params disablemenu_params
menu_id:        .byte   3
disable:        .byte   0
.endparams

.params checkitem_params
menu_id:        .byte   3
menu_item:      .byte   0
check:          .byte   0
.endparams

        .include "../lib/event_params.s"

grafport:  .res .sizeof(MGTK::GrafPort), 0

.params getwinport_params
window_id:      .byte   0
port:           .addr   grafport_win
.endparams

grafport_win:  .res    .sizeof(MGTK::GrafPort), 0

kDialogWidth    = 500
kDialogHeight   = 150
kDialogLeft     = (::kScreenWidth - kDialogWidth)/2
kDialogTop      = (::kScreenHeight - kDialogHeight)/2

.params winfo_dialog
        kWindowId = 1
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
        DEFINE_POINT viewloc, kDialogLeft, kDialogTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDialogWidth, kDialogHeight
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

kListBoxOffsetLeft = 20
kListBoxOffsetTop = 30
kListBoxLeft = kDialogLeft + kListBoxOffsetLeft
kListBoxTop = kDialogTop + kListBoxOffsetTop
kListBoxWidth = 150
kListBoxHeight = kListItemHeight*kListRows-1

.params winfo_drive_select
        kWindowId = 2
window_id:      .byte   kWindowId
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
mincontheight:  .word   50
maxcontwidth:   .word   150
maxcontheight:  .word   150
port:
        DEFINE_POINT viewloc, kListBoxLeft, kListBoxTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kListBoxWidth, kListBoxHeight
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

pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME rect_frame, kDialogWidth, kDialogHeight

        ;; For erasing parts of the window
        DEFINE_RECT rect_erase_dialog_upper, 8, 20, kDialogWidth-8, 103 ; under title to bottom of buttons
        DEFINE_RECT rect_erase_dialog_lower, 8, 103, kDialogWidth-8, kDialogHeight-4 ; top of buttons to bottom of dialog

        DEFINE_BUTTON ok_button_rec, winfo_dialog::kWindowId, res_string_button_ok, kGlyphReturn, 350, 90
        DEFINE_BUTTON_PARAMS ok_button_params, ok_button_rec

        ;; For drawing/updating the dialog title
        DEFINE_POINT point_title, 0, 15
        DEFINE_RECT rect_title, 8, 4, kDialogWidth-8, 15

        DEFINE_RECT rect_erase_select_src, 270, 38, 420, 46

        DEFINE_BUTTON read_drive_button_rec, winfo_dialog::kWindowId, res_string_button_read_drive, res_char_button_read_drive_shortcut, 210, 90
        DEFINE_BUTTON_PARAMS read_drive_button_params, read_drive_button_rec

        DEFINE_POINT point_slot_drive_name, 20, 28
str_slot_drive_name:
        PASCAL_STRING res_string_label_slot_drive_name ; dialog label

        DEFINE_POINT point_select_source, 270, 46
str_select_source:
        PASCAL_STRING res_string_prompt_select_source ; dialog label
str_select_destination:
        PASCAL_STRING res_string_prompt_select_destination ; dialog label

        DEFINE_POINT point_formatting, 210, 68
str_formatting:
        PASCAL_STRING res_string_label_status_formatting

        DEFINE_POINT point_writing, 210, 68
str_writing:
        PASCAL_STRING res_string_label_status_writing

        DEFINE_POINT point_reading, 210, 68
str_reading:
        PASCAL_STRING res_string_label_status_reading

str_unknown:
        PASCAL_STRING res_string_unknown
str_select_quit:
        PASCAL_STRING .sprintf(res_string_label_select_quit, res_string_dc_menu_item_quit, res_string_dc_menu_bar_item_file, ::kGlyphOpenApple, res_char_dc_menu_item_quit_shortcut) ; dialog label

bg_black:
        .byte   0
bg_white:
        .byte   $7F

        DEFINE_RECT rect_highlight_row, 0, 0, kListBoxWidth, 0


current_drive_selection:        ; $FF if no selection
        .byte   0

kListRows = 8                   ; number of visible rows

selection_mode:
        .byte   0               ; high bit clear = source; set = desination


kListEntrySlotOffset    = 8
kListEntryDriveOffset   = 40
kListEntryNameOffset    = 65
        DEFINE_POINT list_entry_pos, 0, 0

num_drives:
        .byte   0

num_src_drives:
        .byte   0

;;; 14 devices = 7 slots * 2 devices/slot (unit $Bx might not be /RAM)
kMaxNumDrives = 14

drive_name_table:
        .res    kMaxNumDrives * 16, 0
drive_unitnum_table:
        .res    kMaxNumDrives, 0
;;; Mapping from filtered destination list index to drive_*_table index
destination_index_table:
        .res    kMaxNumDrives, 0
block_count_table:
        .res    kMaxNumDrives * 2, 0

source_drive_index:  .byte   0
dest_drive_index:  .byte   0

str_d:  PASCAL_STRING 0
str_s:  PASCAL_STRING 0
unit_num:       .byte   0
ejectable_flag: .byte   0

;;; Memory index of block, for memory bitmap lookups
block_index_div8:               ; block index, divided by 8
        .byte   0
block_index_shift:              ; 7-(block index mod 8), for bitmap lookups
        .byte   0

;;; Actual block number, for volume bitmap lookups
block_num_div8:                 ; block number, divided by 8
        .word   0
block_num_shift:                ; 7-(block number mod 8), for bitmap lookups
        .byte   0

;;; Remember the block_num_div8/shift for the start of a CopyBlocks read,
;;; for the writing pass.
start_block_div8:
        .word   0
start_block_shift:
        .byte   0

block_count_div8:              ; calculated when reading volume bitmap
        .word   0

LD429:  .byte   0

        DEFINE_RECT rect_D42A, 18, 20, kDialogWidth-10, 88

.params win_frame_rect_params
id:     .byte   winfo_drive_select::kWindowId
rect:   .tag    MGTK::Rect
.endparams

device_name_buf:
        .res 18, 0

listbox_enabled_flag:  .byte   0
LD44D:  .byte   0
LD44E:  .byte   0

disk_copy_flag:                 ; mode: 0 = Disk Copy, 1 = Quick Copy
        .byte   0

str_2_spaces:   PASCAL_STRING "  "
str_from_int:   PASCAL_STRING "000,000" ; filled in by IntToString

;;; Label positions
        DEFINE_POINT point_blocks_read, 300, 125
        DEFINE_POINT point_blocks_written, 300, 135
        DEFINE_POINT point_source, 300, 115
        DEFINE_POINT point_source2, 40, 125
        DEFINE_POINT point_slot_drive, 110, 125
        DEFINE_POINT point_destination, 40, 135
        DEFINE_POINT point_slot_drive2, 110, 135
        DEFINE_POINT point_disk_copy, 40, 115
        DEFINE_POINT point_select_quit, 20, 145
        DEFINE_RECT rect_select_quit, 20, 136, 400, 145
        DEFINE_POINT point_escape_stop_copy, 300, 145
        DEFINE_POINT point_error_writing, 40, 100
        DEFINE_POINT point_error_reading, 40, 90

str_blocks_read:
        PASCAL_STRING res_string_label_blocks_read
str_blocks_written:
        PASCAL_STRING res_string_label_blocks_written
str_blocks_to_transfer:
        PASCAL_STRING res_string_label_blocks_to_transfer
str_source:
        PASCAL_STRING res_string_source
str_destination:
        PASCAL_STRING res_string_destination
str_slot:
        PASCAL_STRING res_string_slot_prefix
str_drive:
        PASCAL_STRING res_string_drive_infix

str_dos33_s_d:
        PASCAL_STRING res_string_dos33_s_d_pattern
        kStrDOS33SlotOffset = res_const_dos33_s_d_pattern_offset1
        kStrDOS33DriveOffset = res_const_dos33_s_d_pattern_offset2

str_dos33_disk_copy:
        PASCAL_STRING res_string_dos33_disk_copy

str_pascal_disk_copy:
        PASCAL_STRING res_string_pascal_disk_copy

str_prodos_disk_copy:
        PASCAL_STRING res_string_prodos_disk_copy

str_escape_stop_copy:
        PASCAL_STRING res_string_escape_stop_copy

str_error_writing:
        PASCAL_STRING res_string_error_writing

str_error_reading:
        PASCAL_STRING res_string_error_reading

;;; ============================================================

LD5E0:  .byte   0

init:   jsr     DisconnectRAM

        ;; DeskTop will have left a no-longer valid port selected,
        ;; so init a new port before we do anything else.
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::SetMenu, menu_definition
        jsr     SetCursorPointer
        copy    #1, checkitem_params::menu_item
        copy    #1, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        copy    #1, disablemenu_params::disable
        MGTK_CALL MGTK::DisableMenu, disablemenu_params
        lda     #$00
        sta     disk_copy_flag
        sta     LD5E0
        jsr     OpenDialog

InitDialog:
        lda     #$00
        sta     listbox_enabled_flag
        lda     #$FF
        sta     current_drive_selection
        copy    #$80, ok_button_rec::state
        lda     #$81
        sta     LD44D
        copy    #0, disablemenu_params::disable
        MGTK_CALL MGTK::DisableMenu, disablemenu_params
        lda     #1
        sta     checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        jsr     DrawDialog
        MGTK_CALL MGTK::OpenWindow, winfo_drive_select
        lda     #$00
        sta     LD429
        lda     #$FF
        sta     listbox_enabled_flag

        jsr     SetCursorWatch
        jsr     EnumerateDevices
        jsr     SetCursorPointer
        copy    #$00, selection_mode

        lda     LD5E0
        bne     :+
        jsr     GetAllBlockCounts
:       jsr     ListInit
        inc     LD5E0

        ;; Loop until there's a selection (or drive check)
LD674:  jsr     LD986
        bmi     LD674
        beq     LD687
        MGTK_CALL MGTK::CloseWindow, winfo_drive_select
        jmp     InitDialog
LD687:  lda     current_drive_selection
        bmi     LD674

        ;; Have a source selection
        copy    #1, disablemenu_params::disable
        MGTK_CALL MGTK::DisableMenu, disablemenu_params
        lda     current_drive_selection
        sta     source_drive_index

        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_erase_select_src
        MGTK_CALL MGTK::MoveTo, point_select_source
        param_call DrawString, str_select_destination
        jsr     DrawSourceDriveInfo

        ;; Prepare for destination selection
        jsr     EnumerateDestinationDevices
        copy    #$80, selection_mode
        jsr     ListInit
        jsr     UpdateOKButton

        ;; Loop until there's a selection (or drive check)
LD6E6:  jsr     LD986
        bmi     LD6E6
        beq     LD6F9
        MGTK_CALL MGTK::CloseWindow, winfo_drive_select
        jmp     InitDialog
LD6F9:  lda     current_drive_selection
        bmi     LD6E6

        ;; Have a destination selection
        tax
        lda     destination_index_table,x
        sta     dest_drive_index
        lda     #$00
        sta     listbox_enabled_flag
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_upper

        ;; Erase the drive selection listbox
        MGTK_CALL MGTK::GetWinFrameRect, win_frame_rect_params
        MGTK_CALL MGTK::CloseWindow, winfo_drive_select
        sub16   win_frame_rect_params::rect+MGTK::Rect::x1, winfo_dialog::viewloc::xcoord, win_frame_rect_params::rect+MGTK::Rect::x1
        sub16   win_frame_rect_params::rect+MGTK::Rect::y1, winfo_dialog::viewloc::ycoord, win_frame_rect_params::rect+MGTK::Rect::y1
        sub16   win_frame_rect_params::rect+MGTK::Rect::x2, winfo_dialog::viewloc::xcoord, win_frame_rect_params::rect+MGTK::Rect::x2
        sub16   win_frame_rect_params::rect+MGTK::Rect::y2, winfo_dialog::viewloc::ycoord, win_frame_rect_params::rect+MGTK::Rect::y2
        MGTK_CALL MGTK::PaintRect, win_frame_rect_params::rect

        ;; --------------------------------------------------
        ;; Prompt to insert source disk

prompt_insert_source:
        ldx     #0
        lda     #kAlertMsgInsertSource ; X=0 means just show alert
        jsr     ShowAlertDialog
        cmp     #kAlertResultOK
        beq     :+              ; OK
        jmp     InitDialog      ; Cancel

:       lda     #$00
        sta     LD44D

        ;; --------------------------------------------------
        ;; Check source disk

        ldx     source_drive_index
        lda     drive_unitnum_table,x
        sta     main__on_line_params2_unit_num
        jsr     main__CallOnLine2
        beq     source_is_pro
        cmp     #ERR_NOT_PRODOS_VOLUME
        bne     check_source_error
        jsr     main__IdentifySourceNonProDOSDiskType
        jsr     MaybeEraseSelectQuitTip
        jsr     DrawSourceDriveInfo
        jmp     check_source_finish

check_source_error:
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_D42A ; TODO: What is this?
        jmp     prompt_insert_source

source_is_pro:
        lda     main__on_line_buffer2
        and     #$0F            ; mask off name length
        bne     source_get_name ; 0 signals error
        lda     main__on_line_buffer2+1
        ;; TODO: Dedupe with identical block above
        cmp     #ERR_NOT_PRODOS_VOLUME
        bne     check_source_error
        jsr     main__IdentifySourceNonProDOSDiskType
        jsr     MaybeEraseSelectQuitTip
        jsr     DrawSourceDriveInfo
        jmp     check_source_finish

source_get_name:
        lda     main__on_line_buffer2
        and     #$0F            ; mask off name length
        sta     main__on_line_buffer2
        param_call AdjustCase, main__on_line_buffer2
        jsr     MaybeEraseSelectQuitTip
        jsr     DrawSourceDriveInfo

check_source_finish:
        lda     source_drive_index
        jsr     GetBlockCount
        jsr     DrawDestinationDriveInfo
        jsr     DrawCopyFormatType
        ldx     dest_drive_index
        ldy     drive_unitnum_table,x

        ;; --------------------------------------------------
        ;; Prompt to insert destination disk

        ldx     #0
        lda     #kAlertMsgInsertDestination ; X=0 means just show alert
        jsr     ShowAlertDialog
        cmp     #kAlertResultOK
        beq     :+              ; OK
        jmp     InitDialog      ; Cancel
:

        jsr     SetCursorWatch

        ;; --------------------------------------------------
        ;; Check destination disk

        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        sta     main__on_line_params2_unit_num
        jsr     main__CallOnLine2
        beq     dest_is_pro
        cmp     #ERR_NOT_PRODOS_VOLUME
        beq     dest_ok
        jmp     try_format      ; Can't even read drive - try formatting

dest_is_pro:
        lda     main__on_line_buffer2
        and     #NAME_LENGTH_MASK
        bne     dest_ok         ; 0 signals error
        lda     main__on_line_buffer2+1
        cmp     #ERR_NOT_PRODOS_VOLUME
        beq     dest_ok
        jmp     try_format      ; Some other error - proceed with format

dest_ok:

        ;; --------------------------------------------------
        ;; Confirm erasure of the destination disk

        lda     main__on_line_buffer2
        and     #NAME_LENGTH_MASK
    IF_ZERO
        ;; Not ProDOS - try to read Pascal name
        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        sta     main__block_params_unit_num
        copy16  #0, main__block_params_block_num
        copy16  #default_block_buffer, main__block_params_data_buffer
        jsr     main__ReadBlock
        bne     use_sd
        jsr     IsPascalBootBlock
        bcs     use_sd

        param_call GetPascalVolName, main__on_line_buffer2
        ldxy    #main__on_line_buffer2
        lda     #kAlertMsgConfirmErase ; X,Y = ptr to volume name
        jmp     show

use_sd:
        ;; No name, use slot/drive
        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        and     #UNIT_NUM_MASK
        tax                     ; slot/drive
        lda     #kAlertMsgConfirmEraseSlotDrive ; X = unit number
    ELSE
        sta     main__on_line_buffer2
        param_call AdjustCase, main__on_line_buffer2
        ldxy    #main__on_line_buffer2
        lda     #kAlertMsgConfirmErase ; X,Y = ptr to volume name
    END_IF
show:   jsr     ShowAlertDialog
        cmp     #kAlertResultOK
        beq     maybe_format    ; OK
        jmp     InitDialog      ; Cancel

        ;; --------------------------------------------------
        ;; Format if necessary (and supported)

maybe_format:
        lda     disk_copy_flag
        bne     try_format
        jmp     do_copy

try_format:
        jsr     SetCursorWatch

        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        jsr     IsDiskII
        beq     format

        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        jsr     main__DeviceDriverAddress ; Z=1 if firmware
        stax    $06
        bne     do_copy         ; if not firmware, skip these checks

        lda     #$00            ; point at $Cn00
        sta     $06
        ldy     #$FE            ; $CnFE
        lda     ($06),y
        and     #$08            ; bit 3 = The device supports formatting.
        beq     do_copy

format: MGTK_CALL MGTK::MoveTo, point_formatting
        param_call DrawString, str_formatting
        jsr     main__FormatDevice
        bcc     do_copy
        cmp     #ERR_WRITE_PROTECTED
        beq     :+

        lda     #kAlertMsgFormatError ; no args
        jsr     ShowAlertDialog
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     try_format      ; Try Again
        jmp     InitDialog      ; Cancel

:       lda     #kAlertMsgDestinationProtected ; no args
        jsr     ShowAlertDialog
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     try_format      ; Try Again
        jmp     InitDialog      ; Cancel

        ;; --------------------------------------------------
        ;; Perform the copy

do_copy:
        jsr     SetCursorWatch

        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_upper
        lda     source_drive_index
        cmp     dest_drive_index
        bne     copy_read_bitmap

        ;; Disk swap
        tax
        lda     drive_unitnum_table,x
        pha
        jsr     main__EjectDisk
        pla
        tay
        ldx     #$80
        lda     #kAlertMsgInsertSource ; X != 0 means Y=unit number, auto-dismiss
        jsr     ShowAlertDialog
        cmp     #kAlertResultOK
        beq     copy_read_bitmap ; OK
        jmp     InitDialog       ; Cancel

copy_read_bitmap:
        jsr     SetCursorWatch

        jsr     main__ReadVolumeBitmap
        lda     #$00
        sta     block_num_div8
        sta     block_num_div8+1
        lda     #$07
        sta     block_num_shift
        jsr     DrawTotalBlocks
        jsr     DrawBlocksRead
        jsr     DrawBlocksWritten
        jsr     DrawEscToStopCopyHint

copy_loop:
        jsr     SetCursorWatch

        jsr     DrawStatusReading
        lda     #$00
        jsr     main__CopyBlocks
        cmp     #$01
        beq     copy_failure
        lda     source_drive_index
        cmp     dest_drive_index
        bne     copy_write
        tax
        lda     drive_unitnum_table,x
        pha
        jsr     main__EjectDisk
        pla
        tay
        ldx     #$80
        lda     #kAlertMsgInsertDestination ; X != 0 means Y=unit number, auto-dismiss
        jsr     ShowAlertDialog
        cmp     #kAlertResultOK
        beq     copy_write      ; OK
        jmp     InitDialog      ; Cancel

copy_write:
        jsr     SetCursorWatch

        jsr     DrawStatusWriting
        lda     #$80
        jsr     main__CopyBlocks
        bmi     copy_next
        bne     copy_failure
        lda     source_drive_index
        cmp     dest_drive_index
        bne     copy_loop

        ;; Disk swap
        tax
        lda     drive_unitnum_table,x
        pha
        jsr     main__EjectDisk
        pla
        tay
        ldx     #$80
        lda     #kAlertMsgInsertSource ; X !=0 means Y=unit number, auto-dismiss
        jsr     ShowAlertDialog
        cmp     #kAlertResultOK
        beq     copy_loop       ; OK
        jmp     InitDialog      ; Cancel

copy_next:
        jsr     SetCursorWatch

        jsr     main__FreeVolBitmapPages
        ldx     source_drive_index
        lda     drive_unitnum_table,x
        jsr     main__EjectDisk
        ldx     dest_drive_index
        cpx     source_drive_index
        beq     :+
        lda     drive_unitnum_table,x
        jsr     main__EjectDisk
:       lda     #kAlertMsgCopySuccessful ; no args
        jsr     ShowAlertDialog
        jmp     InitDialog

copy_failure:
        jsr     main__FreeVolBitmapPages
        lda     #kAlertMsgCopyFailure ; no args
        jsr     ShowAlertDialog
        jmp     InitDialog

;;; ============================================================
;;; Wait for and process event
;;; Output: N=1 if should be called again
;;;         Z=1 if OK selected, should proceed
;;;         Otherwise: Cancel selected (close/re-init dialog)

LD986:  MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
LD998:  jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        bne     LD9BA
        jmp     HandleClick

LD9BA:  cmp     #MGTK::EventKind::key_down
        bne     LD998
        jmp     HandleKey

;;; ============================================================

menu_command_table:
        ;; Apple menu
        .addr   main__NoOp
        .addr   main__NoOp
        .addr   main__NoOp
        .addr   main__NoOp
        .addr   main__NoOp
        ;; File menu
        .addr   main__Quit
        ;; Facilities menu
        .addr   cmd_quick_copy
        .addr   CmdDiskCopy

menu_offset_table:
        .byte   0, 5*2, 6*2, 8*2

;;; ============================================================

.proc HandleKey
        bit     listbox_enabled_flag
    IF_NS
        lda     event_params::key
        jsr     IsListKey
      IF_EQ
        jsr     ListKey
        jsr     UpdateOKButton
        return  #$FF
      END_IF
    END_IF

        lda     event_params::modifiers
        bne     :+
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     :+
        jmp     dialog_shortcuts

        ;; Modifiers
:
        ;; Keyboard-based menu selection
        lda     event_params::key
        sta     menukey_params::which_key
        lda     event_params::modifiers
        sta     menukey_params::key_mods
        MGTK_CALL MGTK::MenuKey, menukey_params
        FALL_THROUGH_TO HandleMenuSelection
.endproc ; HandleKey

.proc HandleMenuSelection
        ldx     menuselect_params::menu_id
        bne     :+
        return  #$FF
        ;; Compute offset into command table - menu offset + item offset
:       dex
        lda     menu_offset_table,x
        tax
        ldy     menuselect_params::menu_item
        dey
        tya
        asl     a
        sta     jump_addr
        txa
        clc
        adc     jump_addr
        tax
        copy16  menu_command_table,x, jump_addr
        jsr     do_jump
        MGTK_CALL MGTK::HiliteMenu, hilitemenu_params
        jmp     LD986

do_jump:
        tsx
        stx     stack_stash
        jump_addr := *+1
        jmp     SELF_MODIFIED
.endproc ; HandleMenuSelection

;;; ============================================================

cmd_quick_copy:
        lda     disk_copy_flag
        RTS_IF_ZERO

        copy    #0, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        copy    disk_copy_flag, checkitem_params::menu_item
        copy    #1, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        copy    #0, disk_copy_flag
        jsr     SetPortForDialog
        MGTK_CALL MGTK::PaintRect, rect_title
        param_call DrawTitleText, label_quick_copy
        rts

CmdDiskCopy:
        lda     disk_copy_flag
        RTS_IF_NOT_ZERO

        copy    #0, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        copy    #2, checkitem_params::menu_item
        copy    #1, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        copy    #1, disk_copy_flag
        jsr     SetPortForDialog
        MGTK_CALL MGTK::PaintRect, rect_title
        param_call DrawTitleText, label_disk_copy
        rts

;;; ============================================================

.proc HandleClick
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        .assert MGTK::Area::desktop = 0, error, "enum mismatch"
        RTS_IF_ZERO

        cmp     #MGTK::Area::menubar
        bne     :+
        MGTK_CALL MGTK::MenuSelect, menuselect_params
        jmp     HandleMenuSelection
:       cmp     #MGTK::Area::content
        beq     :+
        return  #$FF
:
        lda     findwindow_params::window_id
        cmp     #winfo_dialog::kWindowId
        beq     HandleDialogClick
        cmp     winfo_drive_select
        jsr     ListClick
        php
        jsr     UpdateOKButton
        plp
        bmi     :+
        jsr     DetectDoubleClick
:       rts
.endproc ; HandleClick

;;; ============================================================

.proc UpdateOKButton
        lda     current_drive_selection
        and     #$80

        cmp     ok_button_rec::state
        beq     ret
        sta     ok_button_rec::state
        BTK_CALL BTK::Hilite, ok_button_params

ret:    rts
.endproc ; UpdateOKButton

;;; ============================================================

.proc HandleDialogClick
        jsr     SetPortForDialog
        copy    #winfo_dialog::kWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, ok_button_rec::rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        bit     ok_button_rec::state
        bmi     :+
        BTK_CALL BTK::Track, ok_button_params
        bmi     :+
        lda     #$00
:       rts
    END_IF

        MGTK_CALL MGTK::InRect, read_drive_button_rec::rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        BTK_CALL BTK::Track, read_drive_button_params
        bmi     :+
        lda     #$01
:
    END_IF
        rts
.endproc ; HandleDialogClick

;;; ============================================================

.proc MGTKRelayImpl
        params_src := $7E

        ;; Adjust return address on stack, compute
        ;; original params address.
        pla
        sta     params_src
        clc
        adc     #<3
        tax
        pla
        sta     params_src+1
        adc     #>3
        pha
        txa
        pha

        ;; Copy the params here
        ldy     #3              ; ptr is off by 1
:       lda     (params_src),y
        sta     params-1,y
        dey
        bne     :-

        ;; Bank and call
        sta     RAMRDON
        sta     RAMWRTON
        jsr     MGTKAuxEntry
params: .res    3
        sta     RAMRDOFF
        sta     RAMWRTOFF

        rts
.endproc ; MGTKRelayImpl

;;; ============================================================

.proc dialog_shortcuts
        lda     event_params::key
        cmp     #kShortcutReadDisk
        beq     LDC09
        cmp     #TO_LOWER(kShortcutReadDisk)
        bne     LDC2D
LDC09:  BTK_CALL BTK::Flash, read_drive_button_params
        return  #$01

LDC2D:  cmp     #CHAR_RETURN
    IF_EQ
        bit     ok_button_rec::state
        bmi     :+
        BTK_CALL BTK::Flash, ok_button_params
        lda     #$00
:       rts
    END_IF

        return  #$FF
.endproc ; dialog_shortcuts

;;; ============================================================

.proc SetCursorWatch
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        rts
.endproc ; SetCursorWatch

;;; ============================================================

.proc SetCursorPointer
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts
.endproc ; SetCursorPointer

;;; ============================================================
;;; Populate `drive_name_table` for a non-ProDOS volume
;;; Input: A=unit number
;;; Output: Z=1 if successful

default_block_buffer := main__default_block_buffer

.proc NameNonProDOSVolume
        sta     main__block_params_unit_num
        copy16  #0, main__block_params_block_num
        copy16  #default_block_buffer, main__block_params_data_buffer
        jsr     main__ReadBlock
        bne     fail

        jsr     IsPascalBootBlock
        bne     try_dos33

        ;; Find slot for string in table
        lda     num_drives
        asl     a
        asl     a
        asl     a
        asl     a
        clc
        adc     #<drive_name_table
        tay
        lda     #>drive_name_table
        adc     #0
        tax
        tya
        jsr     GetPascalVolName
        lda     #$80
        sta     LD44E
        return  #$00

fail:   return  #$FF

try_dos33:
        lda     default_block_buffer+1
        cmp     #$A5
        bne     fail
        lda     default_block_buffer+2
        cmp     #$27
        bne     fail
        FALL_THROUGH_TO GetDos33VolName
.endproc ; NameNonProDOSVolume

;;; ============================================================
;;; Construct DOS 3.3 volume name (referencing slot/drive)
;;; Uses `str_dos33_s_d` template to construct volume name
;;; Inputs: `num_drives` and `main__block_params_unit_num` are set
;;; Outputs: Nth `drive_name_table` entry is populated

.proc GetDos33VolName
        ;; Mask off slot and drive, inject into template
        lda     main__block_params_unit_num
        pha
        jsr     UnitNumToSlotDigit
        sta     str_dos33_s_d + kStrDOS33SlotOffset
        pla
        jsr     UnitNumToDriveDigit
        sta     str_dos33_s_d + kStrDOS33DriveOffset

        ;; Find slot for string in table
        lda     num_drives
        asl     a
        asl     a
        asl     a
        asl     a
        tay

        ;; Copy the string in
        ldx     #0
:       lda     str_dos33_s_d,x
        sta     drive_name_table,y
        iny
        inx
        cpx     str_dos33_s_d
        bne     :-

        lda     str_dos33_s_d,x
        sta     drive_name_table,y

        lda     #$43            ; ???
        sta     $0300           ; ???
        return  #0
.endproc ; GetDos33VolName

;;; ============================================================
;;; Check block at `default_block_buffer` for Pascal signature
;;; Output: C=0 if Pascal volume, C=0 otherwise

.proc IsPascalBootBlock
        lda     default_block_buffer+1
        cmp     #$E0
        bne     fail

        lda     default_block_buffer+2
        cmp     #$70
        beq     match
        cmp     #$60
        beq     match

fail:   sec
        rts

match:  clc
        rts
.endproc ; IsPascalBootBlock


;;; ============================================================
;;; Get Pascal volume name
;;; Inputs: A,X=destination buffer (16 bytes)
;;; Output: Pascal name, with ':' suffix.
;;;         If reading second block fails, just uses " ".

.proc GetPascalVolName
        ptr := $06

        stax    ptr
        copy16  #2, main__block_params_block_num
        jsr     main__ReadBlock
    IF_NOT_ZERO
        ;; Just use a single space as the name
        ldy     #0
        lda     #1
        sta     (ptr),y
        iny
        lda     #' '
        sta     (ptr),y
        rts
    END_IF

        ;; Copy the name out of the block
        str_name := default_block_buffer+6

        ldy     #0
:       lda     str_name,y
        sta     (ptr),y
        iny
        cpy     str_name
        bne     :-
        lda     str_name,y
        sta     (ptr),y

        ;; If less than 15 characters, increase len by one
        cpy     #15
    IF_LT
        iny
        tya
        ldy     #0
        sta     (ptr),y
        tay
    END_IF

        ;; Replace last char with ':'
        lda     #':'
        sta     (ptr),y
        rts
.endproc ; GetPascalVolName

;;; ============================================================

        .include "../lib/inttostring.s"
        saved_ram_unitnum := main__saved_ram_unitnum
        saved_ram_drvec   := main__saved_ram_drvec
        .include "../lib/disconnect_ram.s"

        .include "../toolkits/btk.s"
        BTKEntry := btk::BTKEntry

;;; ============================================================

.proc OpenDialog
        MGTK_CALL MGTK::OpenWindow, winfo_dialog
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, rect_frame

        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        rts
.endproc ; OpenDialog

.proc DrawDialog
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_upper
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_lower
        lda     disk_copy_flag
        bne     :+
        param_call DrawTitleText, label_quick_copy
        jmp     draw_buttons
:       param_call DrawTitleText, label_disk_copy

draw_buttons:
        BTK_CALL BTK::Draw, ok_button_params
        jsr     UpdateOKButton
        BTK_CALL BTK::Draw, read_drive_button_params
        MGTK_CALL MGTK::MoveTo, point_slot_drive_name
        param_call DrawString, str_slot_drive_name
        MGTK_CALL MGTK::MoveTo, point_select_source
        param_call DrawString, str_select_source
        MGTK_CALL MGTK::MoveTo, point_select_quit
        param_call DrawString, str_select_quit

        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        rts

.endproc ; DrawDialog

;;; ============================================================

.proc DrawString
        ptr := $0A

        stax    ptr
        ldy     #$00
        lda     (ptr),y
        sta     ptr+2
        inc16   ptr
        MGTK_CALL MGTK::DrawText, ptr
        rts
.endproc ; DrawString

;;; ============================================================

.proc DrawTitleText
        text_params     := $6
        text_addr       := text_params + 0
        text_length     := text_params + 2
        text_width      := text_params + 3

        stax    text_addr       ; input is length-prefixed string
        ldy     #0
        lda     (text_addr),y
        sta     text_length
        inc16   text_addr       ; point past length
        MGTK_CALL MGTK::TextWidth, text_params

        sub16   #kDialogWidth, text_width, point_title::xcoord
        lsr16   point_title::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, point_title
        MGTK_CALL MGTK::DrawText, text_params
        rts
.endproc ; DrawTitleText

;;; ============================================================

.proc AdjustCase
        ptr := $A

        stx     ptr+1
        sta     ptr
        ldy     #0
        lda     (ptr),y
        and     #NAME_LENGTH_MASK ; handle ON_LINE results, etc
        tay
        RTS_IF_ZERO

next:   dey
        beq     done
        bpl     :+
done:   rts

:       lda     (ptr),y
        cmp     #'/'
        beq     skip
        cmp     #'.'
        bne     CheckAlpha
skip:   dey
        jmp     next

CheckAlpha:
        iny
        lda     (ptr),y
        cmp     #'A'
        bcc     :+
        cmp     #'Z'+1
        bcs     :+
        clc
        adc     #('a' - 'A')    ; convert to lower case
        sta     (ptr),y
:       dey
        jmp     next
.endproc ; AdjustCase

;;; ============================================================

.proc SetPortForList
        lda     #winfo_drive_select::kWindowId
        bne     SetPortForWindow ; always
.endproc ; SetPortForList

.proc SetPortForDialog
        lda     #winfo_dialog::kWindowId
        FALL_THROUGH_TO SetPortForWindow
.endproc ; SetPortForDialog

.proc SetPortForWindow
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured.
        MGTK_CALL MGTK::SetPort, grafport_win
        rts
.endproc ; SetPortForWindow

;;; ============================================================
;;; List Box
;;; ============================================================

.scope listbox
        winfo = winfo_drive_select
        kHeight = kListBoxHeight
        kRows = kListRows
        num_items = num_drives
        item_pos = list_entry_pos

        selected_index = current_drive_selection
        highlight_rect = rect_highlight_row
.endscope ; listbox

        .include "../lib/listbox.s"

;;; ============================================================

;;; Called with A = index
.proc DrawListEntryProc
        bit     selection_mode  ; source or destination?
        bpl     draw

        tax                     ; indirection for destination
        lda     destination_index_table,x

draw:   jmp     DrawDeviceListEntry
.endproc ; DrawListEntryProc

;;; ============================================================

;;; Populates `num_drives`, `drive_unitnum_table` and `drive_name_table`
.proc EnumerateDevices
        lda     #$00
        sta     LD44E
        sta     main__on_line_params2_unit_num
        jsr     main__CallOnLine2
        beq     LE17A

        brk                     ; rude!

LE17A:  lda     #$00
        sta     device_index
        sta     num_drives
LE182:  lda     #>main__on_line_buffer2
        sta     $07
        lda     #<main__on_line_buffer2
        sta     $06
        sta     LE264
        lda     device_index
        asl     a
        rol     LE264
        asl     a
        rol     LE264
        asl     a
        rol     LE264
        asl     a
        rol     LE264
        clc
        adc     $06
        sta     $06
        lda     LE264
        adc     $07
        sta     $07

        ;; Check first byte of record
        ldy     #0
        lda     ($06),y
        and     #NAME_LENGTH_MASK
        bne     LE20D

        lda     ($06),y         ; 0?
        beq     LE1CC           ; done!

        iny                     ; name_len=0 signifies an error
        lda     ($06),y         ; error code in second byte
        cmp     #ERR_DEVICE_NOT_CONNECTED
        bne     LE1CD
        dey
        lda     ($06),y
        jsr     IsDiskII
        jne     next_device
        lda     #ERR_DEVICE_NOT_CONNECTED
        bne     LE1CD           ; always

LE1CC:  rts

LE1CD:  pha
        ldy     #$00
        lda     ($06),y
        jsr     FindUnitNum
        ldx     num_drives
        sta     drive_unitnum_table,x
        pla
        cmp     #ERR_NOT_PRODOS_VOLUME
        bne     LE1EA
        lda     drive_unitnum_table,x
        and     #UNIT_NUM_MASK
        jsr     NameNonProDOSVolume
        beq     LE207

        ;; Unknown
LE1EA:  lda     num_drives
        asl     a
        asl     a
        asl     a
        asl     a
        tay
        ldx     #$00
:       lda     str_unknown,x
        sta     drive_name_table,y
        iny
        inx
        cpx     str_unknown
        bne     :-
        lda     str_unknown,x
        sta     drive_name_table,y

LE207:  inc     num_drives
        jmp     next_device

        ;; Valid ProDOS volume
LE20D:  ldx     num_drives
        ldy     #$00
        lda     ($06),y
        jsr     FindUnitNum
        ldx     num_drives
        sta     drive_unitnum_table,x
        ldax    $06
        jsr     AdjustCase
        lda     num_drives
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        ldy     #$00
        lda     ($06),y
        and     #NAME_LENGTH_MASK
        sta     drive_name_table,x
        sta     LE264
:       inx
        iny
        cpy     LE264
        beq     LE24D
        lda     ($06),y
        sta     drive_name_table,x
        jmp     :-

LE24D:  lda     ($06),y
        sta     drive_name_table,x
        inc     num_drives


next_device:
        inc     device_index
        lda     device_index
        cmp     #kMaxNumDrives+1
        beq     LE262
        jmp     LE182

LE262:  rts

device_index:
        .byte   0
LE264:  .byte   0

;;; --------------------------------------------------
;;; Inputs: A=driver/slot (DSSSxxxx)
;;; Outputs: full unit_num
;;; Assert: Is present in DEVLST
.proc FindUnitNum
        and     #UNIT_NUM_MASK
        sta     masked

        ldx     DEVCNT
loop:   lda     DEVLST,x
        and     #UNIT_NUM_MASK

        masked := *+1
        cmp     #SELF_MODIFIED_BYTE

        beq     match
        dex
        bpl     loop
        ;; NOTE: Assertion violated if not found

match:  lda     DEVLST,x
        rts
.endproc ; FindUnitNum

.endproc ; EnumerateDevices

;;; ============================================================

;;; Sets `num_drives` to the number of plausible destination devices,
;;; and populates `destination_index_table`. Also clears selection.
.proc EnumerateDestinationDevices
        ;; Stash source drive details
        lda     current_drive_selection
        asl     a
        tax
        lda     block_count_table,x
        sta     src_block_count
        lda     block_count_table+1,x
        sta     src_block_count+1

        lda     num_drives
        sta     num_src_drives

        lda     #0
        sta     num_drives
        sta     index
loop:   lda     index

        ;; Compare block counts
        asl     a
        tax
        ecmp16  block_count_table,x, src_block_count
        bne     next

        ;; Same - add it
        lda     index
        ldx     num_drives
        sta     destination_index_table,x

        ;; Keep going
        inc     num_drives
next:   inc     index
        lda     index
        cmp     num_src_drives
        beq     finish
        jmp     loop

        ;; Clear selection
finish: lda     #$FF
        sta     current_drive_selection
        rts

index:  .byte   0

src_block_count:
        .word   0
.endproc ; EnumerateDestinationDevices

;;; ============================================================

.proc DrawDeviceListEntry
        sta     device_index

        ldx     device_index
        lda     drive_unitnum_table,x
        jsr     PrepSDStrings

        ;; Slot
        lda     #kListEntrySlotOffset
        sta     list_entry_pos::xcoord
        MGTK_CALL MGTK::MoveTo, list_entry_pos
        param_call DrawString, str_s

        ;; Drive
        lda     #kListEntryDriveOffset
        sta     list_entry_pos::xcoord
        MGTK_CALL MGTK::MoveTo, list_entry_pos
        param_call DrawString, str_d

        ;; Name
        lda     #kListEntryNameOffset
        sta     list_entry_pos::xcoord
        MGTK_CALL MGTK::MoveTo, list_entry_pos
        lda     device_index
        asl     a
        asl     a
        asl     a
        asl     a
        clc
        adc     #<drive_name_table
        sta     $06
        lda     #>drive_name_table
        adc     #$00
        sta     $07

        lda     $06
        ldx     $07
        jmp     DrawString

device_index:
        .byte   0
.endproc ; DrawDeviceListEntry

;;; ============================================================
;;; Populate block_count_table across all devices

.proc GetAllBlockCounts
        lda     #0
        sta     index

:       jsr     GetBlockCount
        inc     index
        lda     index
        cmp     num_drives
        bne     :-
        rts

index:  .byte   0
.endproc ; GetAllBlockCounts

;;; ============================================================
;;; Inputs: A = device index
;;; Outputs: block_count_table (word) set to block count

.proc GetBlockCount

        ;; Special case Disk II devices, since we may be formatting non-ProDOS
        ;; disks the driver can't interrogate.

        pha
        tax                     ; X is device index
        lda     drive_unitnum_table,x
        jsr     IsDiskII
        beq     disk_ii

        pla
        pha
        tax
        lda     drive_unitnum_table,x
        jsr     main__DeviceDriverAddress ; Z=1 if firmware
        stax    $06
        jmp     use_driver

        ;; Disk II - always 280 blocks
disk_ii:
        pla
        asl     a
        tax
        lda     #<280
        sta     block_count_table,x
        lda     #>280
        sta     block_count_table+1,x
        rts

        ;; Use device driver
use_driver:
        pla
        pha
        tax
        lda     drive_unitnum_table,x
        ldxy    $06

        jsr     main__GetDeviceBlocksUsingDriver

        stx     tmp             ; blocks available low
        pla
        asl     a
        tax
        lda     tmp
        sta     block_count_table,x
        tya                     ; blocks available high
        sta     block_count_table+1,x
        rts

tmp:    .byte   0

.endproc ; GetBlockCount

;;; ============================================================

.proc DrawStatusWriting
        jsr     SetPortForDialog
        MGTK_CALL MGTK::MoveTo, point_writing
        param_call DrawString, str_writing
        rts
.endproc ; DrawStatusWriting

.proc DrawStatusReading
        jsr     SetPortForDialog
        MGTK_CALL MGTK::MoveTo, point_reading
        param_call DrawString, str_reading
        rts
.endproc ; DrawStatusReading

.proc DrawTotalBlocks
        jsr     SetPortForDialog
        lda     source_drive_index
        asl     a
        tay
        ldax    block_count_table,y
        jsr     IntToStringWithSeparators
        MGTK_CALL MGTK::MoveTo, point_source
        param_call DrawString, str_blocks_to_transfer
        param_call DrawString, str_from_int
        rts
.endproc ; DrawTotalBlocks

.proc DrawBlocksRead
        jsr     PrepDrawBlocks
        MGTK_CALL MGTK::MoveTo, point_blocks_read
        param_call DrawString, str_blocks_read
        param_call DrawString, str_from_int
        param_call DrawString, str_2_spaces
        rts
.endproc ; DrawBlocksRead

.proc DrawBlocksWritten
        jsr     PrepDrawBlocks
        MGTK_CALL MGTK::MoveTo, point_blocks_written
        param_call DrawString, str_blocks_written
        param_call DrawString, str_from_int
        param_call DrawString, str_2_spaces
        rts
.endproc ; DrawBlocksWritten

.proc PrepDrawBlocks
        jsr     SetPortForDialog
        lda     block_num_div8+1
        sta     hi
        lda     block_num_div8
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        ldx     block_num_shift
        clc
        adc     LE550,x
        tay
        lda     hi
        adc     #$00
        tax
        tya
        jmp     IntToStringWithSeparators

LE550:  .byte   7,6,5,4,3,2,1,0

hi:     .byte   0
.endproc ; PrepDrawBlocks

;;; ============================================================

.proc DrawSourceDriveInfo
        jsr     SetPortForDialog
        MGTK_CALL MGTK::MoveTo, point_source2
        param_call DrawString, str_source
        ldx     source_drive_index
        lda     drive_unitnum_table,x
        jsr     PrepSDStrings
        MGTK_CALL MGTK::MoveTo, point_slot_drive
        param_call DrawString, str_slot
        param_call DrawString, str_s
        param_call DrawString, str_drive
        param_call DrawString, str_d
        bit     LD44D
        bpl     LE5C6
        bvc     LE5C5
        lda     LD44D
        and     #$0F
        beq     LE5C6
LE5C5:  rts

LE5C6:  param_call DrawString, str_2_spaces
        COPY_STRING main__on_line_buffer2, device_name_buf
        param_call DrawString, device_name_buf
        rts
.endproc ; DrawSourceDriveInfo

;;; ============================================================

.proc DrawDestinationDriveInfo
        jsr     SetPortForDialog
        MGTK_CALL MGTK::MoveTo, point_destination
        param_call DrawString, str_destination
        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        jsr     PrepSDStrings
        MGTK_CALL MGTK::MoveTo, point_slot_drive2
        param_call DrawString, str_slot
        param_call DrawString, str_s
        param_call DrawString, str_drive
        param_call DrawString, str_d
        rts
.endproc ; DrawDestinationDriveInfo

;;; ============================================================

.proc DrawCopyFormatType
        jsr     SetPortForDialog
        MGTK_CALL MGTK::MoveTo, point_disk_copy
        bit     LD44D
        bmi     :+
        param_call DrawString, str_prodos_disk_copy
        rts

:       bvs     :+
        param_call DrawString, str_dos33_disk_copy
        rts

:       lda     LD44D
        and     #$0F
        bne     :+
        param_call DrawString, str_pascal_disk_copy
:       rts
.endproc ; DrawCopyFormatType

.proc MaybeEraseSelectQuitTip
        lda     LD44D
        cmp     #$C0
        beq     :+
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_select_quit
:       rts
.endproc ; MaybeEraseSelectQuitTip

.proc DrawEscToStopCopyHint
        jsr     SetPortForDialog
        MGTK_CALL MGTK::MoveTo, point_escape_stop_copy
        param_call DrawString, str_escape_stop_copy
        rts
.endproc ; DrawEscToStopCopyHint

;;; ============================================================
;;; Flash the message when escape is pressed

.proc FlashEscapeMessage
        jsr     SetPortForDialog
        copy    #10, count
        copy    #$80, flag

loop:   dec     count
        beq     finish

        lda     flag
        eor     #$80
        sta     flag
        beq     :+
        MGTK_CALL MGTK::SetTextBG, bg_white
        beq     move
:       MGTK_CALL MGTK::SetTextBG, bg_black
move:   MGTK_CALL MGTK::MoveTo, point_escape_stop_copy
        param_call DrawString, str_escape_stop_copy
        jmp     loop

finish: MGTK_CALL MGTK::SetTextBG, bg_white
        rts

count:  .byte   0
flag:   .byte   0
.endproc ; FlashEscapeMessage

;;; ============================================================
;;; Inputs: A = error code, X = writing flag
;;; Outputs: A=0 for ok, 1 for retry, $80 for cancel
.proc ShowBlockError
        stx     err_writing_flag

        cmp     #ERR_WRITE_PROTECTED
        bne     l2
        jsr     main__Bell
        lda     #kAlertMsgDestinationProtected ; no args
        jsr     ShowAlertDialog
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     :+                ; Cancel
        jsr     DrawStatusWriting ; Try Again
        return  #1

:       jsr     main__FreeVolBitmapPages
        return  #$80

l2:     jsr     main__Bell
        jsr     SetPortForDialog
        lda     main__block_params_block_num
        ldx     main__block_params_block_num+1
        jsr     IntToStringWithSeparators
        lda     err_writing_flag
        bne     :+

        MGTK_CALL MGTK::MoveTo, point_error_reading
        param_call DrawString, str_error_reading
        param_call DrawString, str_from_int
        return  #0

:       MGTK_CALL MGTK::MoveTo, point_error_writing
        param_call DrawString, str_error_writing
        param_call DrawString, str_from_int
        return  #0

err_writing_flag:
        .byte   0
.endproc ; ShowBlockError

;;; ============================================================
;;; Read block (w/ retries) to aux memory
;;; Inputs: A,X=mem address to store it
;;; Outputs: A=0 on success, nonzero otherwise

.proc ReadBlockToAuxmem
        ptr1 := $06
        ptr2 := $08             ; one page up

        sta     ptr1
        sta     ptr2
        stx     ptr1+1
        stx     ptr2+1
        inc     ptr2+1

        ;; Read block
        copy16  #default_block_buffer, main__block_params_data_buffer
retry:  jsr     main__ReadBlock
        beq     move
        ldx     #0              ; reading
        jsr     ShowBlockError
        beq     move
        bpl     retry
        rts

        ;; Copy block from main to aux
move:   sta     RAMRDOFF
        sta     RAMWRTON
        ldy     #$FF
        iny
:       lda     default_block_buffer,y
        sta     (ptr1),y
        lda     default_block_buffer+$100,y
        sta     (ptr2),y
        iny
        bne     :-
        sta     RAMRDOFF
        sta     RAMWRTOFF

        lda     #0
        rts
.endproc ; ReadBlockToAuxmem

;;; ============================================================
;;; Write block (w/ retries) from aux memory
;;; Inputs: A,X=address to read from
;;; Outputs: A=0 on success, nonzero otherwise

.proc WriteBlockFromAuxmem
        ptr1 := $06
        ptr2 := $08             ; one page up

        sta     ptr1
        sta     ptr2
        stx     ptr1+1
        stx     ptr2+1
        inc     ptr2+1

        ;; Copy block aux to main
        copy16  #default_block_buffer, main__block_params_data_buffer
        sta     RAMRDON
        sta     RAMWRTOFF
        ldy     #$FF
        iny
:       lda     (ptr1),y
        sta     default_block_buffer,y
        lda     (ptr2),y
        sta     default_block_buffer+$100,y
        iny
        bne     :-
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ;; Write block
retry:  jsr     main__WriteBlock
        beq     done
        ldx     #$80            ; writing
        jsr     ShowBlockError
        beq     done
        bpl     retry
done:   rts
.endproc ; WriteBlockFromAuxmem

;;; ============================================================

;;; Input: A = unit number (i.e. %DSSSxxxx)
;;; Output: `str_s` and `str_d` populated with digits
.proc PrepSDStrings
        pha
        jsr     UnitNumToSlotDigit
        sta     str_s + 1
        pla
        jsr     UnitNumToDriveDigit
        sta     str_d + 1
        rts
.endproc ; PrepSDStrings


;;; Input: A = unit number (i.e. %DSSSxxxx)
;;; Output: A = ASCII digit '0' ... '7'
.proc UnitNumToSlotDigit
        and     #$70            ; A = %0SSS0000
        lsr     a               ; A = %00SSS000
        lsr     a               ; A = %000SSS00
        lsr     a               ; A = %0000SSS0
        lsr     a               ; A = %00000SSS
        ora     #'0'
        rts
.endproc ; UnitNumToSlotDigit

;;; Input: A = unit number (i.e. %DSSSxxxx)
;;; Output: A = ASCII digit '1' or '2'
.proc UnitNumToDriveDigit
        and     #$80            ; A = %D0000000
        asl     a               ; A = %00000000, C = D
        rol     a               ; A = %0000000D, C = 0
        adc     #'1'            ; no need to CLC
        rts
.endproc ; UnitNumToDriveDigit

;;; ============================================================


.proc ShowAlertDialog
        jmp     start

;;; --------------------------------------------------
;;; Messages

str_insert_source:
        PASCAL_STRING res_string_prompt_insert_source
str_insert_dest:
        PASCAL_STRING res_string_prompt_insert_destination

str_confirm_erase:
        PASCAL_STRING res_string_prompt_erase_prefix
str_confirm_erase_buf:  .res    18, 0
kLenConfirmErase = .strlen(res_string_prompt_erase_prefix)
str_confirm_erase_suffix:
        PASCAL_STRING res_string_prompt_erase_suffix

str_dest_format_fail:
        PASCAL_STRING res_string_errmsg_dest_format_fail
str_format_error:
        PASCAL_STRING res_string_errmsg_format_error
str_dest_protected:
        PASCAL_STRING res_string_errmsg_dest_protected

;;; This string is seen when copying over a non-ProDOS/non-Pascal disk.
str_confirm_erase_sd:
        PASCAL_STRING res_string_prompt_erase_slot_drive_pattern
        kStrConfirmEraseSDSlotOffset = res_const_prompt_erase_slot_drive_pattern_offset1
        kStrConfirmEraseSDDriveOffset = res_const_prompt_erase_slot_drive_pattern_offset2

str_copy_success:
        PASCAL_STRING res_string_label_status_copy_success
str_copy_fail:
        PASCAL_STRING res_string_label_status_copy_fail
str_insert_source_or_cancel:
        PASCAL_STRING res_string_prompt_insert_source_or_cancel
str_insert_dest_or_cancel:
        PASCAL_STRING res_string_prompt_insert_dest_or_cancel

alert_table:
        .byte   kAlertMsgInsertSource
        .byte   kAlertMsgInsertDestination
        .byte   kAlertMsgConfirmErase
        .byte   kAlertMsgDestinationFormatFail
        .byte   kAlertMsgFormatError
        .byte   kAlertMsgDestinationProtected
        .byte   kAlertMsgConfirmEraseSlotDrive
        .byte   kAlertMsgCopySuccessful
        .byte   kAlertMsgCopyFailure
        .byte   kAlertMsgInsertSourceOrCancel
        .byte   kAlertMsgInsertDestinationOrCancel
        ASSERT_TABLE_SIZE alert_table, auxlc::kNumAlertMessages

message_table:
        .addr   str_insert_source
        .addr   str_insert_dest
        .addr   str_confirm_erase
        .addr   str_dest_format_fail
        .addr   str_format_error
        .addr   str_dest_protected
        .addr   str_confirm_erase_sd
        .addr   str_copy_success
        .addr   str_copy_fail
        .addr   str_insert_source_or_cancel
        .addr   str_insert_dest_or_cancel
        ASSERT_ADDRESS_TABLE_SIZE message_table, auxlc::kNumAlertMessages

alert_button_options_table:
        .byte   AlertButtonOptions::OKCancel    ; kAlertMsgInsertSource
        .byte   AlertButtonOptions::OKCancel    ; kAlertMsgInsertDestination
        .byte   AlertButtonOptions::OKCancel    ; kAlertMsgConfirmErase
        .byte   AlertButtonOptions::OK          ; kAlertMsgDestinationFormatFail
        .byte   AlertButtonOptions::TryAgainCancel ; kAlertMsgFormatError
        .byte   AlertButtonOptions::TryAgainCancel ; kAlertMsgDestinationProtected
        .byte   AlertButtonOptions::OKCancel    ; kAlertMsgConfirmEraseSlotDrive
        .byte   AlertButtonOptions::OK          ; kAlertMsgCopySuccessful
        .byte   AlertButtonOptions::OK          ; kAlertMsgCopyFailure
        .byte   AlertButtonOptions::OK          ; kAlertMsgInsertSourceOrCancel
        .byte   AlertButtonOptions::OK          ; kAlertMsgInsertDestinationOrCancel
        ASSERT_TABLE_SIZE alert_button_options_table, auxlc::kNumAlertMessages

alert_options_table:
        .byte   0                       ; kAlertMsgInsertSource
        .byte   0                       ; kAlertMsgInsertDestination
        .byte   0                       ; kAlertMsgConfirmErase
        .byte   AlertOptions::Beep      ; kAlertMsgDestinationFormatFail
        .byte   AlertOptions::Beep      ; kAlertMsgFormatError
        .byte   AlertOptions::Beep      ; kAlertMsgDestinationProtected
        .byte   0                       ; kAlertMsgConfirmEraseSlotDrive
        .byte   0                       ; kAlertMsgCopySuccessful
        .byte   0                       ; kAlertMsgCopyFailure
        .byte   0                       ; kAlertMsgInsertSourceOrCancel
        .byte   0                       ; kAlertMsgInsertDestinationOrCancel
        ASSERT_TABLE_SIZE alert_options_table, auxlc::kNumAlertMessages

.params alert_params
text:           .addr   0
buttons:        .byte   0       ; AlertButtonOptions
options:        .byte   0       ; AlertOptions
.endparams

start:
        pha                     ; A = alert id
        copy    #0, ejectable_flag

        ;; --------------------------------------------------
        ;; Determine alert options

        pla                     ; A = alert id
        .assert kAlertMsgInsertSource = 0, error, "enum mismatch"
    IF_EQ                       ; kAlertMsgInsertSource
        cpx     #0
        beq     find_in_alert_table
        jsr     IsDriveEjectable
        beq     find_in_alert_table ; nope, stick with kAlertMsgInsertSource
        lda     #kAlertMsgInsertSourceOrCancel
        bne     find_in_alert_table ; always
    END_IF

        cmp     #kAlertMsgInsertDestination
    IF_EQ
        cpx     #0
        beq     find_in_alert_table
        jsr     IsDriveEjectable
        beq     :+              ; nope
        lda     #kAlertMsgInsertDestinationOrCancel
        bne     find_in_alert_table ; always
:       lda     #kAlertMsgInsertDestination
        bne     find_in_alert_table ; always
    END_IF

        cmp     #kAlertMsgConfirmErase
    IF_EQ
        jsr     AppendToConfirmErase
        lda     #kAlertMsgConfirmErase
        bne     find_in_alert_table ; always
    END_IF

        cmp     #kAlertMsgConfirmEraseSlotDrive
    IF_EQ
        jsr     SetConfirmEraseSdSlotDrive
        lda     #kAlertMsgConfirmEraseSlotDrive
        FALL_THROUGH_TO find_in_alert_table
    END_IF

find_in_alert_table:
        ;; A = alert id; search table to determine index
        ldy     #0
:       cmp     alert_table,y
        beq     :+
        iny
        cpy     #kNumAlertMessages
        bne     :-
        ldy     #0              ; default

        ;; Y = index
:       tya
        asl     a
        tay
        copy16  message_table,y, alert_params::text
        tya
        lsr     a
        tay
        copy    alert_button_options_table,y, alert_params::buttons
        copy    alert_options_table,y, alert_params::options

        ldax    #alert_params
        jmp     Alert

;;; --------------------------------------------------
;;; Inputs: X,Y = volume name

.proc AppendToConfirmErase
        ptr := $06
        stxy    ptr
        ldy     #$00
        lda     (ptr),y
        pha
        tay
:       lda     (ptr),y
        sta     str_confirm_erase_buf-1,y
        dey
        bne     :-
        pla
        clc
        adc     #kLenConfirmErase

        tay
        ldx     #0
:       iny
        inx
        lda     str_confirm_erase_suffix,x
        sta     str_confirm_erase,y
        cpx     str_confirm_erase_suffix
        bne     :-

        sty     str_confirm_erase
        rts
.endproc ; AppendToConfirmErase

;;; --------------------------------------------------
;;; Inputs: X = %DSSSxxxx

.proc SetConfirmEraseSdSlotDrive
        txa
        jsr     UnitNumToSlotDigit
        sta     str_confirm_erase_sd  + kStrConfirmEraseSDSlotOffset
        txa
        jsr     UnitNumToDriveDigit
        sta     str_confirm_erase_sd + kStrConfirmEraseSDDriveOffset
        rts
.endproc ; SetConfirmEraseSdSlotDrive

;;; --------------------------------------------------

;;; Y = unit number
;;; If ejectable, sets `ejectable_flag`
.proc IsDriveEjectable
        sty     unit_num
        tya
        jsr     main__IsDriveEjectable
        beq     :+
        sta     ejectable_flag
:       rts
.endproc ; IsDriveEjectable

.endproc ; ShowAlertDialog

;;; ============================================================

.scope alert_dialog

        alert_grafport := grafport
        AlertYieldLoop := YieldLoop
        Bell := main__Bell

        AD_EJECTABLE = 1
        .include "../lib/alert_dialog.s"

;;; ============================================================
;;; Poll the drive in `unit_num` until a disk is inserted, or
;;; the Escape key is pressed.
;;; Output: A = 0 if disk inserted, $80 if Escape pressed
.proc WaitForDiskOrEsc
@retry:
        ;; Poll drive until something is present
        ;; (either a ProDOS disk or a non-ProDOS disk)
        lda     unit_num
        sta     main__on_line_params_unit_num
        jsr     main__CallOnLine
        beq     done

        cmp     #ERR_NOT_PRODOS_VOLUME
        beq     done
        lda     main__on_line_buffer
        and     #NAME_LENGTH_MASK
        bne     done
        lda     main__on_line_buffer+1
        cmp     #ERR_NOT_PRODOS_VOLUME
        beq     done

        jsr     AlertYieldLoop
        MGTK_CALL MGTK::GetEvent, Alert::event_params
        lda     Alert::event_kind
        cmp     #MGTK::EventKind::key_down
        bne     @retry

        lda     Alert::event_key
        cmp     #CHAR_ESCAPE
        bne     @retry
        return  #$80

done:   return  #$00
.endproc ; WaitForDiskOrEsc

.endscope ; alert_dialog
Alert := alert_dialog::Alert

;;; ============================================================
;;; Called by main and nested event loops to do periodic tasks.
;;; Returns 0 if the periodic tasks were run.

.proc YieldLoop
        kMaxCounter = $E0       ; arbitrary

        inc     loop_counter
        inc     loop_counter

        loop_counter := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #kMaxCounter
        bcc     :+
        copy    #0, loop_counter

        jsr     main__ResetIIgsRGB ; in case it was reset by control panel

:       lda     loop_counter
        rts
.endproc ; YieldLoop

        .include "../lib/is_diskii.s"
        .include "../lib/muldiv.s"
        .include "../lib/doubleclick.s"

;;; ============================================================

.proc CheckEvents
        MGTK_CALL MGTK::CheckEvents
        rts
.endproc ; CheckEvents

;;; ============================================================

.proc StopDeskTop
        MGTK_CALL MGTK::StopDeskTop
        rts
.endproc ; StopDeskTop

;;; ============================================================

        .assert * <= $F400, error, "Update memory_bitmap if code extends past $F400"
.endscope ; auxlc
        auxlc__start := auxlc::start

        ENDSEG SegmentAuxLC
