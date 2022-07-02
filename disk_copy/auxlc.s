;;; ============================================================
;;; Disk Copy - Auxiliary LC Segment $D000 - $F1FF
;;;
;;; Compiled as part of disk_copy.s
;;; ============================================================

.scope auxlc
        .org ::kSegmentAuxLCAddress

        MGTKEntry := MGTKRelayImpl

kShortcutYes      = res_char_button_yes_shortcut
kShortcutNo       = res_char_button_no_shortcut
kShortcutTryAgain = res_char_button_try_again_shortcut
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
kAlertMsgInsertDestionationOrCancel = 10 ; No bell, *
;;; "Bell" or "No bell" determined by the `MaybeBell` proc.
;;; * = the 'InsertXOrCancel' variants are selected automatically when
;;; InsertX is specified if X flag is non-zero, and the unit number in
;;; Y identifies a removable volume. In that case, the alert will
;;; automatically be dismissed when a disk is inserted.

kAlertResultTryAgain    = 0
kAlertResultOK          = 0     ; NOTE: Different than DeskTop (=2)
kAlertResultCancel      = 1
kAlertResultYes         = 2
kAlertResultNo          = 3

;;; ============================================================

        ASSERT_ADDRESS ::kSegmentAuxLCAddress, "Entry point"

start:
        jmp     init

;;; ============================================================
;;; Resources

pencopy:        .byte   0
penOR:          .byte   1
penXOR:         .byte   2
penBIC:         .byte   3
notpencopy:     .byte   4
notpenOR:       .byte   5
notpenXOR:      .byte   6
notpenBIC:      .byte   7

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
        PASCAL_STRING .sprintf(res_string_version_format_short, kDeskTopProductName, ::kDeskTopVersionMajor, ::kDeskTopVersionMinor) ; menu item

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
mincontlength:  .word   50
maxcontwidth:   .word   500
maxcontlength:  .word   140
port:
        DEFINE_POINT viewloc, kDialogLeft, kDialogTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDialogWidth, kDialogHeight
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
mincontlength:  .word   50
maxcontwidth:   .word   150
maxcontlength:  .word   150
port:
        DEFINE_POINT viewloc, kListBoxLeft, kListBoxTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kListBoxWidth, kListBoxHeight
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
        DEFINE_RECT_FRAME rect_frame, kDialogWidth, kDialogHeight

        ;; For erasing parts of the window
        DEFINE_RECT_SZ rect_erase_dialog_upper, 8, 20, kDialogWidth-16, kListBoxHeight + 11 ; under title to bottom of list
        DEFINE_RECT_SZ rect_erase_dialog_lower, 8, 103, kDialogWidth-16, 42 ; bottom of list to bottom of dialog

        DEFINE_BUTTON ok, res_string_button_ok, 350, 90

        ;; For drawing/updating the dialog title
        DEFINE_POINT point_title, 0, 15
        DEFINE_RECT rect_title, 8, 4, kDialogWidth-8, 15

        DEFINE_RECT rect_erase_select_src, 270, 38, 420, 46

        DEFINE_BUTTON read_drive, res_string_button_read_drive, 210, 90

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
        PASCAL_STRING .sprintf(res_string_label_select_quit, ::kGlyphOpenApple) ; dialog label

bg_black:
        .byte   0
bg_white:
        .byte   $7F

        DEFINE_RECT rect_highlight_row, 0, 0, kListBoxWidth, 0


current_drive_selection:        ; $FF if no selection
        .byte   0

;;; TODO: This can just use vthumbpos
top_row:                        ; top row visible in list box
        .byte   0

kListRows = 8                   ; number of visible rows

selection_mode:
        .byte   0               ; high bit clear = source; set = desination


LD367:  .byte   0
LD368:  .byte   0

kListEntrySlotOffset    = 8
kListEntryDriveOffset   = 40
kListEntryNameOffset    = 65
        DEFINE_POINT list_entry_pos, 0, 0

num_drives:
        .byte   0

num_src_drives:
        .byte   0

;;; 13 devices = 7 slots * 2 devices/slot - 1 device for S3D2 /RAM
kMaxNumDrives = 13

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

LD44C:  .byte   0
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
        DEFINE_RECT rect_D483, 20, 136, 400, 145
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

        ;; cursor definition - pointer
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

        ;; Cursor definition - watch
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

;;; ============================================================

LD5E0:  .byte   0

init:   jsr     DisconnectRAM
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
        sta     LD367
        sta     LD368
        sta     LD44C
        lda     #$FF
        sta     current_drive_selection
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
        sta     LD44C

        jsr     EnumerateDevices
        copy    #$00, selection_mode
        copy    #0, top_row
        jsr     UpdateViewport
        jsr     EnableScrollbar

        lda     LD5E0
        bne     :+
        jsr     GetAllBlockCounts
:       jsr     DrawDeviceListEntries
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

        lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_erase_select_src
        MGTK_CALL MGTK::MoveTo, point_select_source
        param_call DrawString, str_select_destination
        jsr     DrawSourceDriveInfo

        ;; Prepare for destination selection
        jsr     EnumerateDestinationDevices
        copy    #$80, selection_mode
        copy    #0, top_row
        jsr     UpdateViewport
        jsr     EnableScrollbar

        jsr     DrawDestinationListEntries

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
        sta     LD44C
        lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_upper

        MGTK_CALL MGTK::GetWinFrameRect, win_frame_rect_params
        MGTK_CALL MGTK::CloseWindow, winfo_drive_select
        sub16   win_frame_rect_params::rect+MGTK::Rect::x1, winfo_dialog::viewloc::xcoord, win_frame_rect_params::rect+MGTK::Rect::x1
        sub16   win_frame_rect_params::rect+MGTK::Rect::y1, winfo_dialog::viewloc::ycoord, win_frame_rect_params::rect+MGTK::Rect::y1
        sub16   win_frame_rect_params::rect+MGTK::Rect::x2, winfo_dialog::viewloc::xcoord, win_frame_rect_params::rect+MGTK::Rect::x2
        sub16   win_frame_rect_params::rect+MGTK::Rect::y2, winfo_dialog::viewloc::ycoord, win_frame_rect_params::rect+MGTK::Rect::y2
        MGTK_CALL MGTK::PaintRect, win_frame_rect_params::rect

LD734:  ldx     #0
        lda     #kAlertMsgInsertSource ; X=0 means just show alert
        jsr     ShowAlertDialog
        .assert kAlertResultOK = 0, error, "Branch assumes enum value"
        beq     :+              ; OK
        jmp     InitDialog      ; Cancel

:       lda     #$00
        sta     LD44D
        ldx     source_drive_index
        lda     drive_unitnum_table,x
        sta     main__on_line_params2_unit_num
        jsr     main__CallOnLine2
        beq     LD77E
        cmp     #ERR_NOT_PRODOS_VOLUME
        bne     LD763
        jsr     main__IdentifyNonprodosDiskType
        jsr     LE674
        jsr     DrawSourceDriveInfo
        jmp     LD7AD

LD763:  lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_D42A
        jmp     LD734

LD77E:  lda     main__on_line_buffer2
        and     #$0F            ; mask off name length
        bne     LD798           ; 0 signals error
        lda     main__on_line_buffer2+1
        cmp     #ERR_NOT_PRODOS_VOLUME
        bne     LD763
        jsr     main__IdentifyNonprodosDiskType
        jsr     LE674
        jsr     DrawSourceDriveInfo
        jmp     LD7AD

LD798:  lda     main__on_line_buffer2
        and     #$0F            ; mask off name length
        sta     main__on_line_buffer2
        param_call AdjustCase, main__on_line_buffer2
        jsr     LE674
        jsr     DrawSourceDriveInfo
LD7AD:  lda     source_drive_index
        jsr     GetBlockCount
        jsr     DrawDestinationDriveInfo
        jsr     LE63F
        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        tay

        ldx     #0
        lda     #kAlertMsgInsertDestination ; X=0 means just show alert
        jsr     ShowAlertDialog
        .assert kAlertResultOK = 0, error, "Branch assumes enum value"
        beq     :+              ; OK
        jmp     InitDialog      ; Cancel

:       ldx     dest_drive_index
        lda     drive_unitnum_table,x
        sta     main__on_line_params2_unit_num
        jsr     main__CallOnLine2
        beq     LD7E1
        cmp     #ERR_NOT_PRODOS_VOLUME
        beq     LD7F2
        jmp     LD852

LD7E1:  lda     main__on_line_buffer2
        and     #$0F            ; mask off name length
        bne     LD7F2           ; 0 signals error
        lda     main__on_line_buffer2+1
        cmp     #ERR_NOT_PRODOS_VOLUME
        beq     LD7F2
        jmp     LD852

LD7F2:
        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        jsr     IsDiskII
        beq     LD817

        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        jsr     main__DeviceDriverAddress ; Z=1 if firmware
        stax    $06
        bne     :+              ; if not firmware, skip these checks

        lda     #$00            ; point at $Cn00
        sta     $06
        ldy     #$FE            ; $CnFE
        lda     ($06),y
        and     #$08            ; bit 3 = The device supports formatting.
        bne     LD817
:       jmp     LD8A9

LD817:  lda     main__on_line_buffer2
        and     #$0F            ; mask off name length
        bne     LD82C           ; have a name to show; otherwise, use S,D
        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        and     #UNIT_NUM_MASK
        tax                     ; slot/drive
        lda     #kAlertMsgConfirmEraseSlotDrive ; X = unit number
        jmp     show

LD82C:  sta     main__on_line_buffer2
        param_call AdjustCase, main__on_line_buffer2

        ldxy    #main__on_line_buffer2
        lda     #kAlertMsgConfirmErase ; X,Y = ptr to volume name
show:   jsr     ShowAlertDialog
        cmp     #kAlertResultCancel
        beq     :+              ; Cancel
        cmp     #kAlertResultYes
        beq     LD84A           ; Yes
:       jmp     InitDialog      ; No

LD84A:  lda     disk_copy_flag
        bne     LD852
        jmp     LD8A9

LD852:  ldx     dest_drive_index
        lda     drive_unitnum_table,x
        jsr     IsDiskII
        beq     format

        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        jsr     main__DeviceDriverAddress ; Z=1 if firmware
        stax    $06
        bne     :+              ; if not firmware, skip these checks

        lda     #$00            ; point at $Cn00
        sta     $06
        ldy     #$FE            ; $CnFE
        lda     ($06),y
        and     #$08            ; bit 3 = The device supports formatting.
        bne     format

:       lda     #kAlertMsgDestinationFormatFail ; no args
        jsr     ShowAlertDialog
        jmp     InitDialog

format: MGTK_CALL MGTK::MoveTo, point_formatting
        param_call DrawString, str_formatting
        jsr     main__FormatDevice
        bcc     LD8A9
        cmp     #ERR_WRITE_PROTECTED
        beq     LD89F

        lda     #kAlertMsgFormatError ; no args
        jsr     ShowAlertDialog
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     LD852           ; Try Again
        jmp     InitDialog      ; Cancel

LD89F:  lda     #kAlertMsgDestinationProtected ; no args
        jsr     ShowAlertDialog
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     LD852           ; Try Again
        jmp     InitDialog      ; Cancel

LD8A9:  lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_upper
        lda     source_drive_index
        cmp     dest_drive_index
        bne     LD8DF

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
        .assert kAlertResultOK = 0, error, "Branch assumes enum value"
        beq     LD8DF           ; OK
        jmp     InitDialog      ; Cancel

LD8DF:  jsr     main__ReadVolumeBitmap
        lda     #$00
        sta     block_num_div8
        sta     block_num_div8+1
        lda     #$07
        sta     block_num_shift
        jsr     LE4BF
        jsr     LE4EC
        jsr     LE507
        jsr     LE694
LD8FB:  jsr     LE4A8
        lda     #$00
        jsr     main__CopyBlocks
        cmp     #$01
        beq     LD97A
        jsr     LE4EC
        lda     source_drive_index
        cmp     dest_drive_index
        bne     LD928
        tax
        lda     drive_unitnum_table,x
        pha
        jsr     main__EjectDisk
        pla
        tay
        ldx     #$80
        lda     #kAlertMsgInsertDestination ; X != 0 means Y=unit number, auto-dismiss
        jsr     ShowAlertDialog
        .assert kAlertResultOK = 0, error, "Branch assumes enum value"
        beq     LD928           ; OK
        jmp     InitDialog      ; Cancel

LD928:  jsr     LE491
        lda     #$80
        jsr     main__CopyBlocks
        bmi     LD955
        bne     LD97A
        jsr     LE507
        lda     source_drive_index
        cmp     dest_drive_index
        bne     LD8FB

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
        .assert kAlertResultOK = 0, error, "Branch assumes enum value"
        beq     LD8FB           ; OK
        jmp     InitDialog      ; Cancel

LD955:  jsr     LE507
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

LD97A:  jsr     main__FreeVolBitmapPages
        lda     #kAlertMsgCopyFailure ; no args
        jsr     ShowAlertDialog
        jmp     InitDialog

;;; ============================================================

LD986:  MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
LD998:  bit     LD368
        bpl     :+
        dec     LD367
        bne     :+
        lda     #$00
        sta     LD368
:       jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        bne     LD9BA
        jmp     HandleButtonDown

LD9BA:  cmp     #MGTK::EventKind::key_down
        bne     LD998
        jmp     LD9D5

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

LD9D5:  lda     event_params::modifiers
        bne     :+
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     :+
        jmp     dialog_shortcuts

        ;; Modifiers
:       lda     event_params::key
        ldx     event_params::modifiers
        cpx     #3
    IF_EQ
        ;; Double modifiers
        cmp     #CHAR_UP
      IF_EQ
        jsr     DoHome
        return  #$FF
      END_IF
        cmp     #CHAR_DOWN
      IF_EQ
        jsr     DoEnd
        return  #$FF
      END_IF
    ELSE
        ;; Single modifier
        cmp     #CHAR_UP
      IF_EQ
        lda     #MGTK::Part::page_up
        jsr     HandleScrollWithPart
        return  #$FF
      END_IF
        cmp     #CHAR_DOWN
      IF_EQ
        lda     #MGTK::Part::page_down
        jsr     HandleScrollWithPart
        return  #$FF
      END_IF
    END_IF

        ;; Keyboard-based menu selection
        lda     event_params::key
        sta     menukey_params::which_key
        lda     event_params::modifiers
        beq     :+
        lda     #1              ; treat Solid-Apple same as Open-Apple
:       sta     menukey_params::key_mods
        MGTK_CALL MGTK::MenuKey, menukey_params
handle_menu_selection:
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

;;; ============================================================

cmd_quick_copy:
        lda     disk_copy_flag
        bne     LDA42
        rts

LDA42:  copy    #0, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        copy    disk_copy_flag, checkitem_params::menu_item
        copy    #1, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        copy    #0, disk_copy_flag
        lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::PaintRect, rect_title
        param_call DrawTitleText, label_quick_copy
        rts

CmdDiskCopy:
        lda     disk_copy_flag
        beq     LDA7D
        rts

LDA7D:  copy    #0, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        copy    #2, checkitem_params::menu_item
        copy    #1, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        copy    #1, disk_copy_flag
        lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::PaintRect, rect_title
        param_call DrawTitleText, label_disk_copy
        rts

;;; ============================================================

HandleButtonDown:
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        bne     :+
        rts                     ; desktop - ignore
:       cmp     #MGTK::Area::menubar
        bne     :+
        MGTK_CALL MGTK::MenuSelect, menuselect_params
        jmp     handle_menu_selection
:       cmp     #MGTK::Area::content
        beq     :+
        return  #$FF
:
        lda     findwindow_params::window_id
        cmp     #winfo_dialog::kWindowId
        beq     handle_dialog_button_down
        cmp     winfo_drive_select
        jeq     handle_drive_select_button_down
        rts

        ;; --------------------------------------------------
        ;; Dialog window
handle_dialog_button_down:
        lda     #winfo_dialog::kWindowId
        sta     screentowindow_params::window_id
        jsr     SetWinPort
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        param_call ButtonClick, winfo_dialog::kWindowId, ok_button_rect
        bmi     :+
        lda     #$00
:       rts
    END_IF

        MGTK_CALL MGTK::InRect, read_drive_button_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        param_call ButtonClick, winfo_dialog::kWindowId, read_drive_button_rect
        bmi     :+
        lda     #$01
:
    END_IF
        rts

        ;; --------------------------------------------------
        ;; Drive select window

handle_drive_select_button_down:
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        jeq     HandleScroll

        cmp     #MGTK::Ctl::not_a_control
        jne     LDBCA

        copy    #winfo_drive_select::kWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        ldax    screentowindow_params::windowy
        ldy     #kListItemHeight
        jsr     Divide_16_8_16
        clc
        adc     top_row
        cmp     num_drives
        bcc     LDB98
        lda     current_drive_selection
        jsr     HighlightRow
        lda     #$FF
        sta     current_drive_selection           ; $FF if no selection?
        jmp     LDBCA

LDB98:  cmp     current_drive_selection
        bne     LDBCD
        bit     LD368
        bpl     LDBC0
        param_call ButtonFlash, winfo_dialog::kWindowId, ok_button_rect
        return  #$00

LDBC0:  lda     #$FF
        sta     LD368
        lda     #$64
        sta     LD367
LDBCA:  return  #$FF

LDBCD:  pha
        lda     current_drive_selection
        bmi     LDBD6
        jsr     HighlightRow
LDBD6:  pla
        sta     current_drive_selection
        jsr     HighlightRow
        jmp     LDBC0

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
.endproc

dialog_shortcuts:
        lda     event_params::key
        cmp     #kShortcutReadDisk
        beq     LDC09
        cmp     #TO_LOWER(kShortcutReadDisk)
        bne     LDC2D
LDC09:  param_call ButtonFlash, winfo_dialog::kWindowId, read_drive_button_rect
        return  #$01

LDC2D:  cmp     #CHAR_RETURN
    IF_EQ
        param_call ButtonFlash, winfo_dialog::kWindowId, ok_button_rect
        return  #$00
    END_IF

        bit     LD44C
        jpl     LDCA9

        cmp     #CHAR_DOWN
    IF_EQ
        lda     current_drive_selection
      IF_MINUS
        copy    #0, current_drive_selection
      ELSE
        tax
        inx
        cpx     num_drives
        beq     LDCA9           ; no-op if last
        jsr     HighlightRow
        inc     current_drive_selection
     END_IF

        lda     current_drive_selection
        pha
        jsr     ScrollIntoView
        pla
        jsr     HighlightRow
        jmp     LDCA9
    END_IF

        cmp     #CHAR_UP
    IF_EQ
        lda     current_drive_selection
      IF_MINUS
        ldx     num_drives
        dex
        stx     current_drive_selection
      ELSE
        beq     LDCA9           ; no-op if first
        jsr     HighlightRow
        dec     current_drive_selection
      END_IF

        lda     current_drive_selection
        pha
        jsr     ScrollIntoView
        pla
        jsr     HighlightRow
    END_IF

        FALL_THROUGH_TO LDCA9

LDCA9:  return  #$FF

;;; ============================================================

.proc DoHome
        lda     current_drive_selection
        bmi     :+
        beq     ret
        jsr     HighlightRow
:
        lda     #0
        sta     current_drive_selection
        pha
        jsr     ScrollIntoView
        pla
        jsr     HighlightRow

ret:    rts
.endproc

.proc DoEnd
        lda     current_drive_selection
        bmi     :+
        tax
        dex
        cpx     num_drives
        beq     ret
        jsr     HighlightRow
:
        ldx     num_drives
        dex
        stx     current_drive_selection
        txa
        pha
        jsr     ScrollIntoView
        pla
        jsr     HighlightRow

ret:    rts
.endproc

;;; ============================================================

.proc SetCursorWatch
        MGTK_CALL MGTK::SetCursor, watch_cursor
        rts
.endproc

;;; ============================================================

.proc SetCursorPointer
        MGTK_CALL MGTK::SetCursor, pointer_cursor
        rts
.endproc

;;; ============================================================

LDDFC:  sta     main__block_params_unit_num
        lda     #$00
        sta     main__block_params_block_num
        sta     main__block_params_block_num+1
        copy16  #$1C00, main__block_params_data_buffer
        jsr     main__ReadBlock
        beq     LDE19
        return  #$FF

LDE19:  lda     $1C01
        cmp     #$E0
        beq     LDE23
        jmp     LDE4D

LDE23:  lda     $1C02
        cmp     #$70
        beq     LDE31
        cmp     #$60
        beq     LDE31
LDE2E:  return  #$FF

LDE31:  lda     num_drives
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
        jsr     LDE9F
        lda     #$80
        sta     LD44E
        return  #$00

LDE4D:  cmp     #$A5
        bne     LDE2E
        lda     $1C02
        cmp     #ERR_IO_ERROR
        bne     LDE2E
        lda     main__block_params_unit_num
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #'0'
        sta     str_dos33_s_d + kStrDOS33SlotOffset
        lda     main__block_params_unit_num
        and     #$80
        asl     a
        rol     a
        adc     #'1'
        sta     str_dos33_s_d + kStrDOS33DriveOffset
        lda     num_drives
        asl     a
        asl     a
        asl     a
        asl     a
        tay
        ldx     #$00
LDE83:  lda     str_dos33_s_d,x
        sta     drive_name_table,y
        iny
        inx
        cpx     str_dos33_s_d
        bne     LDE83
        lda     str_dos33_s_d,x
        sta     drive_name_table,y
        lda     #$43
        sta     $0300
        return  #$00

.proc LDE9F
        ptr := $06

        stax    ptr
        copy16  #$0002, main__block_params_block_num
        jsr     main__ReadBlock
        beq     l1
        ldy     #$00
        lda     #$01
        sta     (ptr),y
        iny
        lda     #$20
        sta     (ptr),y
        rts

l1:     ldy     #$00
        ldx     #$00
l2:     lda     $1C06,x
        sta     (ptr),y
        inx
        iny
        cpx     $1C06
        bne     l2
        lda     $1C06,x
        sta     (ptr),y
        lda     $1C06
        cmp     #$0F
        bcs     l3
        ldy     #$00
        lda     (ptr),y
        clc
        adc     #$01
        sta     (ptr),y
        lda     (ptr),y
        tay
l3:     lda     #$3A
        sta     (ptr),y
        rts
.endproc

;;; ============================================================

        .include "../lib/button.s"
        .include "../lib/inttostring.s"
        .include "../lib/bell.s"
        saved_ram_unitnum := main__saved_ram_unitnum
        saved_ram_drvec   := main__saved_ram_drvec
        .include "../lib/disconnect_ram.s"

;;; ============================================================

.proc OpenDialog
        MGTK_CALL MGTK::OpenWindow, winfo_dialog
        lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, rect_frame

        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        rts
.endproc

.proc DrawDialog
        lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_upper
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_lower
        lda     disk_copy_flag
        bne     :+
        param_call DrawTitleText, label_quick_copy
        jmp     draw_buttons
:       param_call DrawTitleText, label_disk_copy

draw_buttons:
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::FrameRect, read_drive_button_rect
        jsr     DrawOkLabel
        jsr     DrawReadDriveLabel
        MGTK_CALL MGTK::MoveTo, point_slot_drive_name
        param_call DrawString, str_slot_drive_name
        MGTK_CALL MGTK::MoveTo, point_select_source
        param_call DrawString, str_select_source
        MGTK_CALL MGTK::MoveTo, point_select_quit
        param_call DrawString, str_select_quit

        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        rts

.proc DrawOkLabel
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call DrawString, ok_button_label
        rts
.endproc

.proc DrawReadDriveLabel
        MGTK_CALL MGTK::MoveTo, read_drive_button_pos
        param_call DrawString, read_drive_button_label
        rts
.endproc

.endproc

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
.endproc

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
.endproc

;;; ============================================================

.proc AdjustCase
        ptr := $A

        stx     ptr+1
        sta     ptr
        ldy     #0
        lda     (ptr),y
        tay
        bne     next
        rts

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
.endproc

;;; ============================================================

.proc SetWinPort
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport_win
        rts
.endproc

;;; ============================================================

;;; A = row to highlight
.proc HighlightRow
        ldx     #0              ; hi (A=lo)
        ldy     #kListItemHeight
        jsr     Multiply_16_8_16
        stax    rect_highlight_row::y1
        addax   #kListItemHeight-1, rect_highlight_row::y2

        lda     #winfo_drive_select::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect_highlight_row
        rts
.endproc

;;; ============================================================

;;; Enable/disable scrollbar as appropriate; resets thumb pos.
;;; Assert: `num_drives` and `top_row` are set.
.proc EnableScrollbar
        lda     num_drives
        cmp     #kListRows+1
    IF_LT
        copy    #0, activatectl_params::activate
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts
    END_IF

        lda     num_drives
        sec
        sbc     #kListRows
        sta     setctlmax_params::ctlmax
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        MGTK_CALL MGTK::SetCtlMax, setctlmax_params

        copy    #1, activatectl_params::activate
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        MGTK_CALL MGTK::ActivateCtl, activatectl_params

        copy    top_row, updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params

        rts
.endproc

;;; ============================================================

.proc HandleScrollWithPart
        sta     findcontrol_params::which_part
        FALL_THROUGH_TO HandleScroll
.endproc

;;; Assert: `top_row` is set.
.proc HandleScroll
        lda     winfo_drive_select::vscroll
        and     #MGTK::Scroll::option_active
        bne     :+
        rts
:
        lda     num_drives
        sec
        sbc     #kListRows
        sta     max_top

        lda     findcontrol_params::which_part

        cmp     #MGTK::Part::up_arrow
    IF_EQ
        lda     top_row
        cmp     #0
        jeq     done

        dec     top_row
        bpl     update
    END_IF

        cmp     #MGTK::Part::down_arrow
    IF_EQ
        lda     top_row
        cmp     max_top
        jcs     done

        inc     top_row
        bpl     update
    END_IF

        cmp     #MGTK::Part::page_up
    IF_EQ
        lda     top_row
        cmp     #kListRows
        bcs     :+
        lda     #0
        beq     store
:       sec
        sbc     #kListRows
        jmp     store
    END_IF

        cmp     #MGTK::Part::page_down
    IF_EQ
        lda     top_row
        clc
        adc     #kListRows
        cmp     max_top
        bcc     store
        lda     max_top
        jmp     store
    END_IF

        cmp     #MGTK::Part::thumb
    IF_EQ
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        beq     done
        lda     trackthumb_params::thumbpos
        FALL_THROUGH_TO store
    END_IF

store:  sta     top_row

update: copy    top_row, updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params

        jsr     UpdateViewport
        jsr     DrawListEntries
        lda     current_drive_selection
        bmi     :+
        jsr     HighlightRow
:
done:   return  #$FF

max_top:
        .byte   0
.endproc

;;; ============================================================

.proc DrawListEntries
        bit     selection_mode  ; source or destination?
        jpl     DrawDeviceListEntries
        jmp     DrawDestinationListEntries
.endproc

;;; ============================================================

;;; Input: A = row to ensure visible
;;; Assert: `top_row` is set.
.proc ScrollIntoView
        cmp     top_row
    IF_LT
        sta     top_row
        sta     updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     UpdateViewport
        jmp     DrawListEntries
    END_IF

        sec
        sbc     #kListRows-1
        bmi     ret
        cmp     top_row
        beq     ret
    IF_GE
        sta     top_row
        sta     updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     UpdateViewport
        jmp     DrawListEntries
    END_IF

ret:    rts
.endproc

;;; ============================================================

;;; Assert: `top_row` is set.
.proc UpdateViewport
        copy16  #0, winfo_drive_select::maprect::y1
        lda     top_row         ; lo
        ldx     #0              ; hi
        ldy     #kListItemHeight
        jsr     Multiply_16_8_16
        stax    winfo_drive_select::maprect::y1
        addax   #kListBoxHeight, winfo_drive_select::maprect::y2

        rts
.endproc

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
        and     #$0F            ; name_len
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
        jsr     LDDFC
        beq     LE207
LE1EA:  lda     num_drives
        asl     a
        asl     a
        asl     a
        asl     a
        tay
        ldx     #$00
LE1F4:  lda     str_unknown,x
        sta     drive_name_table,y
        iny
        inx
        cpx     str_unknown
        bne     LE1F4
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
        lda     num_drives
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        ldy     #$00
        lda     ($06),y
        and     #$0F
        sta     drive_name_table,x
        sta     LE264
LE23E:  inx
        iny
        cpy     LE264
        beq     LE24D
        lda     ($06),y
        sta     drive_name_table,x
        jmp     LE23E

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
.endproc

.endproc

;;; ============================================================

.proc DrawDeviceListEntries
        lda     #winfo_drive_select::kWindowId
        jsr     SetWinPort

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, winfo_drive_select::maprect

        lda     #0
        sta     index

loop:   lda     index
        jsr     SetYCoord
        lda     index
        jsr     DrawDeviceListEntry

        inc     index
        lda     index
        cmp     num_drives
        bne     loop

        rts

index:  .byte   0
.endproc

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
        lda     block_count_table,x
        cmp     src_block_count
        bne     next
        lda     block_count_table+1,x
        cmp     src_block_count+1
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
.endproc

;;; ============================================================

.proc DrawDestinationListEntries
        lda     #winfo_drive_select::kWindowId
        jsr     SetWinPort

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, winfo_drive_select::maprect

        lda     #0
        sta     index

loop:   lda     index
        jsr     SetYCoord
        ldx     index
        lda     destination_index_table,x
        jsr     DrawDeviceListEntry

        inc     index
        lda     index
        cmp     num_drives
        bne     loop

        rts

index:  .byte   0
.endproc

;;; ============================================================

.proc DrawDeviceListEntry
        sta     device_index

        ;; Slot
        lda     #kListEntrySlotOffset
        sta     list_entry_pos::xcoord
        MGTK_CALL MGTK::MoveTo, list_entry_pos
        ldx     device_index
        lda     drive_unitnum_table,x
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #'0'
        sta     str_s + 1
        param_call DrawString, str_s

        ;; Drive
        lda     #kListEntryDriveOffset
        sta     list_entry_pos::xcoord
        MGTK_CALL MGTK::MoveTo, list_entry_pos
        ldx     device_index
        lda     drive_unitnum_table,x
        and     #$80
        asl     a
        rol     a
        clc
        adc     #'1'
        sta     str_d + 1
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
        jsr     AdjustCase
        lda     $06
        ldx     $07
        jsr     DrawString
        rts

device_index:
        .byte   0
.endproc

;;; ============================================================

.proc SetYCoord
        ldx     #0              ; hi (A=lo)
        ldy     #kListItemHeight
        jsr     Multiply_16_8_16
        addax   #kListItemHeight-1, list_entry_pos::ycoord
        rts
.endproc

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
.endproc

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

.endproc

;;; ============================================================

LE491:  lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::MoveTo, point_writing
        param_call DrawString, str_writing
        rts

LE4A8:  lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::MoveTo, point_reading
        param_call DrawString, str_reading
        rts

LE4BF:  lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        lda     source_drive_index
        asl     a
        tay
        lda     block_count_table+1,y
        tax
        lda     block_count_table,y
        jsr     IntToStringWithSeparators
        MGTK_CALL MGTK::MoveTo, point_source
        param_call DrawString, str_blocks_to_transfer
        param_call DrawString, str_from_int
        rts

LE4EC:  jsr     LE522
        MGTK_CALL MGTK::MoveTo, point_blocks_read
        param_call DrawString, str_blocks_read
        param_call DrawString, str_from_int
        param_call DrawString, str_2_spaces
        rts

LE507:  jsr     LE522
        MGTK_CALL MGTK::MoveTo, point_blocks_written
        param_call DrawString, str_blocks_written
        param_call DrawString, str_from_int
        param_call DrawString, str_2_spaces
        rts

LE522:  lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        lda     block_num_div8+1
        sta     LE558
        lda     block_num_div8
        asl     a
        rol     LE558
        asl     a
        rol     LE558
        asl     a
        rol     LE558
        ldx     block_num_shift
        clc
        adc     LE550,x
        tay
        lda     LE558
        adc     #$00
        tax
        tya
        jsr     IntToStringWithSeparators
        rts

LE550:  .byte   7,6,5,4,3,2,1,0

LE558:  .byte   0

;;; ============================================================

.proc DrawSourceDriveInfo
        lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::MoveTo, point_source2
        param_call DrawString, str_source
        ldx     source_drive_index
        lda     drive_unitnum_table,x
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #'0'
        sta     str_s + 1
        ldx     source_drive_index
        lda     drive_unitnum_table,x
        and     #$80
        clc
        rol     a
        rol     a
        clc
        adc     #'1'
        sta     str_d + 1
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
.endproc

;;; ============================================================

.proc DrawDestinationDriveInfo
        lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::MoveTo, point_destination
        param_call DrawString, str_destination
        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #'0'
        sta     str_s + 1
        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        and     #$80
        asl     a
        rol     a
        clc
        adc     #'1'
        sta     str_d + 1
        MGTK_CALL MGTK::MoveTo, point_slot_drive2
        param_call DrawString, str_slot
        param_call DrawString, str_s
        param_call DrawString, str_drive
        param_call DrawString, str_d
        rts
.endproc

;;; ============================================================

LE63F:  lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::MoveTo, point_disk_copy
        bit     LD44D
        bmi     LE65B
        param_call DrawString, str_prodos_disk_copy
        rts

LE65B:  bvs     LE665
        param_call DrawString, str_dos33_disk_copy
        rts

LE665:  lda     LD44D
        and     #$0F
        bne     LE673
        param_call DrawString, str_pascal_disk_copy
LE673:  rts

LE674:  lda     LD44D
        cmp     #$C0
        beq     LE693
        lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect_D483
LE693:  rts

LE694:  lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
        MGTK_CALL MGTK::MoveTo, point_escape_stop_copy
        param_call DrawString, str_escape_stop_copy
        rts

;;; ============================================================
;;; Flash the message when escape is pressed

.proc FlashEscapeMessage
        lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
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
.endproc

;;; ============================================================
;;; Inputs: A = error code, X = writing flag
;;; Outputs: A=0 for ok, 1 for retry, $80 for cancel
.proc ShowBlockError
        stx     err_writing_flag

        cmp     #ERR_WRITE_PROTECTED
        bne     l2
        jsr     Bell
        lda     #kAlertMsgDestinationProtected ; no args
        jsr     ShowAlertDialog
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     :+              ; Cancel
        jsr     LE491           ; Try Again
        return  #1

:       jsr     main__FreeVolBitmapPages
        return  #$80

l2:     jsr     Bell
        lda     #winfo_dialog::kWindowId
        jsr     SetWinPort
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
.endproc

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
        copy16  #$1C00, main__block_params_data_buffer
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
:       lda     $1C00,y
        sta     (ptr1),y
        lda     $1D00,y
        sta     (ptr2),y
        iny
        bne     :-
        sta     RAMRDOFF
        sta     RAMWRTOFF

        lda     #0
        rts
.endproc

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
        copy16  #$1C00, main__block_params_data_buffer
        sta     RAMRDON
        sta     RAMWRTOFF
        ldy     #$FF
        iny
:       lda     (ptr1),y
        sta     $1C00,y
        lda     (ptr2),y
        sta     $1D00,y
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
.endproc

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

;;; This string is seen when copying a ProDOS disk to DOS 3.3 or Pascal disk.
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
        .byte   kAlertMsgInsertDestionationOrCancel
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
        .byte   AlertButtonOptions::OkCancel    ; kAlertMsgInsertSource
        .byte   AlertButtonOptions::OkCancel    ; kAlertMsgInsertDestination
        .byte   AlertButtonOptions::YesNoCancel ; kAlertMsgConfirmErase
        .byte   AlertButtonOptions::Ok          ; kAlertMsgDestinationFormatFail
        .byte   AlertButtonOptions::TryAgainCancel ; kAlertMsgFormatError
        .byte   AlertButtonOptions::TryAgainCancel ; kAlertMsgDestinationProtected
        .byte   AlertButtonOptions::YesNoCancel ; kAlertMsgConfirmEraseSlotDrive
        .byte   AlertButtonOptions::Ok          ; kAlertMsgCopySuccessful
        .byte   AlertButtonOptions::Ok          ; kAlertMsgCopyFailure
        .byte   AlertButtonOptions::Ok          ; kAlertMsgInsertSourceOrCancel
        .byte   AlertButtonOptions::Ok          ; kAlertMsgInsertDestionationOrCancel
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
        .byte   0                       ; kAlertMsgInsertDestionationOrCancel
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
        lda     #kAlertMsgInsertDestionationOrCancel
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
.endproc

;;; --------------------------------------------------
;;; Inputs: X = %DSSSxxxx

.proc SetConfirmEraseSdSlotDrive
        txa
        and     #$70            ; Mask off slot
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #'0'
        sta     str_confirm_erase_sd  + kStrConfirmEraseSDSlotOffset
        txa
        and     #$80            ; Mask off drive
        asl     a               ; Shift to low bit
        rol     a
        adc     #'1'            ; Drive 1 or 2
        sta     str_confirm_erase_sd + kStrConfirmEraseSDDriveOffset
        rts
.endproc

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
.endproc

.endproc

;;; ============================================================

.scope alert_dialog

        alert_grafport := grafport
        AlertYieldLoop := YieldLoop

        .define AD_YESNO 1
        .define AD_SAVEBG 0
        .define AD_WRAP 0
        .define AD_EJECTABLE 1

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
        and     #$0F
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
.endproc

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
.endproc

        .include "../lib/is_diskii.s"
        .include "../lib/muldiv.s"

;;; ============================================================
;;; Settings - modified by Control Panels
;;; ============================================================

        PAD_TO ::BELLDATA
        .include "../lib/default_sound.s"

        PAD_TO ::SETTINGS
        .include "../lib/default_settings.s"

;;; ============================================================

        ASSERT_ADDRESS ::kSegmentAuxLCAddress + ::kSegmentAuxLCLength
        .assert * <= $F400, error, "Update memory_bitmap if code extends past $F400"
.endscope
       auxlc__start := auxlc::start
