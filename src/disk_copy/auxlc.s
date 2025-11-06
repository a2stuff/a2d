;;; ============================================================
;;; Disk Copy - Auxiliary LC Segment $D000
;;;
;;; Compiled as part of disk_copy.s
;;; ============================================================

        BEGINSEG SegmentAuxLC
.scope auxlc

        MGTKEntry := MGTKRelayImpl

kShortcutReadDisk = res_char_button_read_drive_shortcut

default_block_buffer := main::default_block_buffer

;;; ============================================================

;;; number of alert messages
kNumAlertMessages = 12

kAlertMsgInsertSource           = 0 ; No bell, *
kAlertMsgInsertDestination      = 1 ; No bell, *
kAlertMsgConfirmErase           = 2 ; No bell, X,Y = pointer to volume name
kAlertMsgDestinationFormatFail  = 3 ; Bell
kAlertMsgFormatError            = 4 ; Bell
kAlertMsgDestinationProtected   = 5 ; Bell
kAlertMsgConfirmEraseSlotDrive  = 6 ; No bell, X = unit number
kAlertMsgConfirmEraseDOS33      = 7 ; No bell, X = unit number
kAlertMsgCopySuccessful         = 8 ; No bell
kAlertMsgCopyFailure            = 9 ; No bell
kAlertMsgInsertSourceOrCancel   = 10 ; No bell, *
kAlertMsgInsertDestinationOrCancel = 11 ; No bell, *
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
penXOR:         .byte   MGTK::penXOR
notpencopy:     .byte   MGTK::notpencopy

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

;;; ============================================================
;;; Menu definition

        kMenuIdApple = 1
        kMenuIdFile = 2
        kMenuIdOptions = 3

        ;; Menu bar
        DEFINE_MENU_BAR menu_definition, 3
@items: DEFINE_MENU_BAR_ITEM kMenuIdApple, label_apple, menu_apple
        DEFINE_MENU_BAR_ITEM kMenuIdFile, label_file, menu_file
        DEFINE_MENU_BAR_ITEM kMenuIdOptions, label_facilities, menu_options
        ASSERT_RECORD_TABLE_SIZE @items, 3, .sizeof(MGTK::MenuBarItem)

        ;; Apple menu
        DEFINE_MENU menu_apple, 5
@items: DEFINE_MENU_ITEM label_desktop
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_copyright1
        DEFINE_MENU_ITEM label_copyright2
        DEFINE_MENU_ITEM label_copyright3
        ASSERT_RECORD_TABLE_SIZE @items, 5, .sizeof(MGTK::MenuItem)

        ;; File menu
        DEFINE_MENU menu_file, 1
@items: DEFINE_MENU_ITEM label_quit, res_char_dc_menu_item_quit_shortcut
        ASSERT_RECORD_TABLE_SIZE @items, 1, .sizeof(MGTK::MenuItem)

label_apple:
        PASCAL_STRING kGlyphSolidApple

        ;; Options menu
        DEFINE_MENU menu_options, 2
@items: DEFINE_MENU_ITEM label_quick_copy
        DEFINE_MENU_ITEM label_disk_copy
        ASSERT_RECORD_TABLE_SIZE @items, 2, .sizeof(MGTK::MenuItem)

        kMenuItemIdQuickCopy = 1
        kMenuItemIdDiskCopy  = 2

label_file:
        PASCAL_STRING res_string_dc_menu_bar_item_file
label_facilities:
        PASCAL_STRING res_string_menu_bar_item_facilities

label_desktop:
        PASCAL_STRING .sprintf(res_string_version_format_long, kDeskTopProductName, ::kDeskTopVersionMajor, ::kDeskTopVersionMinor, kDeskTopVersionSuffix)

label_copyright1:
        PASCAL_STRING res_string_copyright_line1 ; menu item
label_copyright2:
        PASCAL_STRING res_string_copyright_line2 ; menu item
label_copyright3:
        PASCAL_STRING res_string_copyright_line3 ; menu item

label_quit:
        PASCAL_STRING res_string_dc_menu_item_quit

label_quick_copy:
        PASCAL_STRING res_string_menu_item_quick_copy

label_disk_copy:
        PASCAL_STRING res_string_dc_menu_item_disk_copy

;;; ============================================================

.params disablemenu_params
menu_id:        .byte   kMenuIdOptions
disable:        .byte   0
.endparams

.params checkitem_params
menu_id:        .byte   kMenuIdOptions
menu_item:      .byte   0
check:          .byte   0
.endparams

        .include "../lib/event_params.s"

grafport:       .tag MGTK::GrafPort

        kDialogWindowId = 1

.params getwinport_params
window_id:      .byte   kDialogWindowId
port:           .addr   grafport_win
.endparams

grafport_win:   .tag MGTK::GrafPort

kDialogWidth    = 500
kDialogHeight   = 150
kDialogLeft     = (::kScreenWidth - kDialogWidth)/2
kDialogTop      = (::kScreenHeight - kDialogHeight)/2

.params winfo_dialog
        kWindowId = kDialogWindowId
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
penmode:        .byte   MGTK::pencopy ; default; good for for erasing rects
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME rect_frame, kDialogWidth, kDialogHeight

        kEraseLeft = 8
        kEraseRight = kDialogWidth-8

        ;; For erasing parts of the window
        DEFINE_RECT rect_erase_dialog_upper, kEraseLeft, 20, kEraseRight, 103 ; under title to bottom of buttons
        DEFINE_RECT rect_erase_dialog_lower, kEraseLeft, 103, kEraseRight, kDialogHeight-4 ; top of buttons to bottom of dialog

        DEFINE_BUTTON dialog_ok_button, winfo_dialog::kWindowId, res_string_button_ok, kGlyphReturn, 350, 90

        ;; For drawing/updating the dialog title
        DEFINE_POINT point_title, kDialogWidth/2, 15
        DEFINE_RECT rect_erase_title, kEraseLeft, 4, kEraseRight, 15

        DEFINE_RECT rect_erase_select_src, 270, 38, 420, 46

        DEFINE_BUTTON read_drive_button, winfo_dialog::kWindowId, res_string_button_read_drive, res_char_button_read_drive_shortcut, 210, 90

        DEFINE_LABEL slot_drive_name, res_string_label_slot_drive_name, 20, 28

        DEFINE_LABEL select_source, res_string_prompt_select_source, 270, 46
str_select_destination:
        PASCAL_STRING res_string_prompt_select_destination

        DEFINE_POINT point_status, kDialogWidth/2, 68
        DEFINE_RECT rect_status, kEraseLeft, 57, kEraseRight, 68
str_formatting:
        PASCAL_STRING res_string_label_status_formatting
str_writing:
        PASCAL_STRING res_string_label_status_writing
str_reading:
        PASCAL_STRING res_string_label_status_reading

        ;; Progress bar
        kProgressTop = 72
        kProgressHeight = 9
        kProgressLeft = 16
        kProgressWidth = kDialogWidth-kProgressLeft*2
        DEFINE_RECT_SZ progress_frame, kProgressLeft-1, kProgressTop-1, kProgressWidth+2, kProgressHeight+2
        DEFINE_RECT_SZ progress_bar, kProgressLeft, kProgressTop, kProgressWidth, kProgressHeight
progress_pattern:
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001

str_unknown:
        PASCAL_STRING res_string_unknown

bg_black:
        .byte   0
bg_white:
        .byte   $7F

kListRows = 8                   ; number of visible rows

selection_mode_flag:
        .byte   0               ; bit7 clear = source; set = destination


kListEntrySlotOffset    = 8
kListEntryDriveOffset   = 40
kListEntryNameOffset    = 65

num_src_drives:
        .byte   0

;;; 14 devices = 7 slots * 2 devices/slot (unit $Bx might not be /RAM)
kMaxNumDrives = 14

drive_name_table:
        .res    kMaxNumDrives * 16, 0
;;; Entries are properly masked (i.e. with `UNIT_NUM_MASK`)
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
ejectable_flag: .byte   0       ; bit7

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

.params win_frame_rect_params
id:     .byte   kListBoxWindowId
rect:   .tag    MGTK::Rect
.endparams

device_name_buf:
        .res 16, 0

listbox_enabled_flag:  .byte   0 ; bit7

kSourceDiskFormatProDOS = %00000000 ; bit7 clear
kSourceDiskFormatDOS33  = %10000000 ; bit6 clear
kSourceDiskFormatPascal = %11000000 ; bits 0-3 clear
kSourceDiskFormatOther  = %11000001
source_disk_format:
        .byte   0

disk_copy_flag:                 ; bit7 0 = Quick Copy, 1 = Disk Copy
        .byte   0

str_2_spaces:   PASCAL_STRING "  "
str_from_int:   PASCAL_STRING "000,000" ; filled in by IntToString

        kInfoTextY   = 115
        kSourceTextY = 125
        kDestTextY   = 135
        kTipTextY    = 145

        kOverviewTextX  =  40
        kSlotDriveTextX = 110
        kBlocksTextX    = 300

        DEFINE_LABEL blocks_read, res_string_label_blocks_read, kBlocksTextX, kSourceTextY
        DEFINE_LABEL blocks_written, res_string_label_blocks_written, kBlocksTextX, kDestTextY
        DEFINE_LABEL blocks_to_transfer, res_string_label_blocks_to_transfer, kBlocksTextX, kInfoTextY

        DEFINE_LABEL source, res_string_source, kOverviewTextX, kSourceTextY
        DEFINE_LABEL destination, res_string_destination, kOverviewTextX, kDestTextY

        DEFINE_POINT point_source_slot_drive, kSlotDriveTextX, kSourceTextY
        DEFINE_POINT point_destination_slot_drive, kSlotDriveTextX, kDestTextY
        DEFINE_POINT point_disk_copy, kOverviewTextX, kInfoTextY


        DEFINE_LABEL select_quit, .sprintf(res_string_label_select_quit, res_string_dc_menu_item_quit, res_string_dc_menu_bar_item_file, ::kGlyphOpenApple, res_char_dc_menu_item_quit_shortcut), kDialogWidth/2, kTipTextY
        DEFINE_RECT rect_erase_tip, kEraseLeft, kTipTextY-(kSystemFontHeight+2), kEraseRight, kTipTextY

        DEFINE_LABEL escape_stop_copy, res_string_escape_stop_copy, kDialogWidth/2, kTipTextY
        DEFINE_LABEL error_writing, res_string_error_writing, kOverviewTextX, 102
        DEFINE_LABEL error_reading, res_string_error_reading, kOverviewTextX, 92

str_slot_drive_pattern:
        PASCAL_STRING res_string_slot_drive_pattern

str_dos33:
        PASCAL_STRING res_string_dos33

str_dos33_disk_copy:
        PASCAL_STRING res_string_dos33_disk_copy

str_pascal_disk_copy:
        PASCAL_STRING res_string_pascal_disk_copy

str_prodos_disk_copy:
        PASCAL_STRING res_string_prodos_disk_copy

;;; ============================================================
;;; List Box
;;; ============================================================

kListBoxOffsetLeft = 20
kListBoxOffsetTop = 30
kListBoxLeft = kDialogLeft + kListBoxOffsetLeft
kListBoxTop = kDialogTop + kListBoxOffsetTop
kListBoxWidth = 150
kListBoxHeight = kListItemHeight*kListRows-1

        kListBoxWindowId = 2
        DEFINE_LIST_BOX_WINFO winfo_drive_select, \
                kListBoxWindowId, \
                kListBoxLeft, \
                kListBoxTop, \
                kListBoxWidth, \
                kListBoxHeight, \
                DEFAULT_FONT
        DEFINE_LIST_BOX listbox_rec, winfo_drive_select, \
                kListRows, SELF_MODIFIED_BYTE, \
                DrawListEntryProc, NoOp, NoOp
        DEFINE_LIST_BOX_PARAMS lb_params, listbox_rec

num_drives := listbox_rec::num_items
current_drive_selection := listbox_rec::selected_index


        DEFINE_POINT list_entry_pos, 0, 0

NoOp:   rts

;;; ============================================================

init:
        ;; DeskTop will have left a no-longer valid port selected,
        ;; so init a new port before we do anything else.
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::SetMenu, menu_definition
        jsr     SetCursorPointer

        copy8   #kMenuItemIdQuickCopy, checkitem_params::menu_item
        copy8   #MGTK::checkitem_check, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params

        CLEAR_BIT7_FLAG disk_copy_flag

        ;; Open dialog window
        MGTK_CALL MGTK::OpenWindow, winfo_dialog
        jsr     SetPortForDialog
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, rect_frame

InitDialog:
        CLEAR_BIT7_FLAG listbox_enabled_flag
        copy8   #$FF, current_drive_selection
        copy8   #BTK::kButtonStateDisabled, dialog_ok_button::state

        copy8   #kSourceDiskFormatOther, source_disk_format

        copy8   #MGTK::disablemenu_enable, disablemenu_params::disable
        MGTK_CALL MGTK::DisableMenu, disablemenu_params

        ;; --------------------------------------------------
        ;; Draw dialog window

        jsr     SetPortForDialog
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_upper
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_lower

        MGTK_CALL MGTK::MoveTo, point_title
        ldax    #label_quick_copy
        bit     disk_copy_flag
    IF NS
        ldax    #label_disk_copy
    END_IF
        jsr     DrawStringCentered

        BTK_CALL BTK::Draw, dialog_ok_button
        jsr     UpdateOKButton
        BTK_CALL BTK::Draw, read_drive_button
        MGTK_CALL MGTK::MoveTo, slot_drive_name_label_pos
        MGTK_CALL MGTK::DrawString, slot_drive_name_label_str
        MGTK_CALL MGTK::MoveTo, select_source_label_pos
        MGTK_CALL MGTK::DrawString, select_source_label_str
        MGTK_CALL MGTK::MoveTo, select_quit_label_pos
        CALL    DrawStringCentered, AX=#select_quit_label_str

        ;; --------------------------------------------------
        ;; Drive select listbox

        MGTK_CALL MGTK::OpenWindow, winfo_drive_select
        SET_BIT7_FLAG listbox_enabled_flag

        jsr     SetCursorWatch
        jsr     EnumerateDevices
        copy8   #0, DISK_COPY_INITIAL_UNIT_NUM
        jsr     GetAllBlockCounts

        jsr     SetCursorPointer
        CLEAR_BIT7_FLAG selection_mode_flag

        LBTK_CALL LBTK::Init, lb_params
        jsr     UpdateOKButton

        ;; --------------------------------------------------
        ;; Loop until there's a selection (or drive check)
        jsr     WaitForSelection

        ;; Have a source selection
        copy8   #MGTK::disablemenu_disable, disablemenu_params::disable
        MGTK_CALL MGTK::DisableMenu, disablemenu_params

        copy8   current_drive_selection, source_drive_index

        jsr     SetPortForDialog
        MGTK_CALL MGTK::PaintRect, rect_erase_select_src
        MGTK_CALL MGTK::MoveTo, select_source_label_pos
        MGTK_CALL MGTK::DrawString, str_select_destination
        jsr     DrawSourceDriveInfo

        ;; Prepare for destination selection
        jsr     EnumerateDestinationDevices
        SET_BIT7_FLAG selection_mode_flag
        LBTK_CALL LBTK::Init, lb_params
        jsr     UpdateOKButton

        ;; --------------------------------------------------
        ;; Loop until there's a selection (or drive check)
        jsr     WaitForSelection

        ;; Have a destination selection
        tax
        copy8   destination_index_table,x, dest_drive_index
        CLEAR_BIT7_FLAG listbox_enabled_flag

        jsr     SetPortForDialog
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_upper
        MGTK_CALL MGTK::PaintRect, rect_erase_tip

        ;; Erase the drive selection listbox
        MGTK_CALL MGTK::GetWinFrameRect, win_frame_rect_params
        MGTK_CALL MGTK::CloseWindow, winfo_drive_select
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::PaintRect, win_frame_rect_params::rect

        ;; --------------------------------------------------
        ;; Prompt to insert source disk

prompt_insert_source:
        CALL    ShowAlertDialog, X=#0, A=#kAlertMsgInsertSource ; X=0 means just show alert
    IF A <> #kAlertResultOK
        jmp     InitDialog      ; Cancel
    END_IF

        ;; --------------------------------------------------
        ;; Check source disk

        ldx     source_drive_index
        CALL    main::CallOnLine2, A=drive_unitnum_table,x
        bcc     source_is_pro

check_source_error:
        cmp     #ERR_NOT_PRODOS_VOLUME
        bne     prompt_insert_source

        ;; Source is non-ProDOS
        jsr     main::IdentifySourceNonProDOSDiskType
        sta     source_disk_format
        jsr     DrawSourceDriveInfo
        jmp     check_source_finish

        ;; Source is ProDOS
source_is_pro:
        copy8   #kSourceDiskFormatProDOS, source_disk_format

        lda     main::on_line_buffer2
        and     #$0F            ; mask off name length
    IF ZERO                     ; 0 signals error
        lda     main::on_line_buffer2+1
        jmp     check_source_error
    END_IF

        CALL    AdjustOnLineEntryCase, AX=#main::on_line_buffer2
        jsr     DrawSourceDriveInfo

check_source_finish:
        CALL    GetBlockCount, A=source_drive_index
        jsr     DrawDestinationDriveInfo
        jsr     DrawCopyFormatType
        ldx     dest_drive_index
        ldy     drive_unitnum_table,x

        ;; --------------------------------------------------
        ;; Prompt to insert destination disk

        CALL    ShowAlertDialog, X=#0, A=#kAlertMsgInsertDestination ; X=0 means just show alert
    IF A <> #kAlertResultOK
        jmp     InitDialog      ; Cancel
    END_IF

        jsr     SetCursorWatch

        ;; --------------------------------------------------
        ;; Check destination disk

        ldx     dest_drive_index
        CALL    main::CallOnLine2, A=drive_unitnum_table,x
    IF CS
        cmp     #ERR_NOT_PRODOS_VOLUME
        beq     dest_ok
        jmp     try_format      ; Can't even read drive - try formatting
    END_IF

        lda     main::on_line_buffer2
        and     #NAME_LENGTH_MASK
    IF ZERO                     ; 0 signals error
        lda     main::on_line_buffer2+1
        cmp     #ERR_NOT_PRODOS_VOLUME
        jne     try_format      ; Some other error - proceed with format
    END_IF

dest_ok:

        ;; --------------------------------------------------
        ;; Confirm erasure of the destination disk

        lda     main::on_line_buffer2
        and     #NAME_LENGTH_MASK
    IF ZERO
        ;; Not ProDOS - try to identify disk type
        ldx     dest_drive_index
        CALL    main::ReadBootBlock, A=drive_unitnum_table,x
      IF CC

        ;; Pascal?
        jsr     IsPascalBootBlock
       IF CC
        CALL    GetPascalVolName, AX=#main::on_line_buffer2
        jmp     buf2
       END_IF

        ;; DOS 3.3?
        jsr     IsDOS33BootBlock
       IF EQ
        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        tax                     ; slot/drive
        lda     #kAlertMsgConfirmEraseDOS33 ; X = unit number
        bne     show            ; always
       END_IF
      END_IF

        ;; Unknown, just use slot/drive
        ldx     dest_drive_index
        lda     drive_unitnum_table,x
        tax                     ; slot/drive
        lda     #kAlertMsgConfirmEraseSlotDrive ; X = unit number
    ELSE
        CALL    AdjustOnLineEntryCase, AX=#main::on_line_buffer2
buf2:   ldxy    #main::on_line_buffer2
        lda     #kAlertMsgConfirmErase ; X,Y = ptr to volume name
    END_IF
show:   jsr     ShowAlertDialog
        cmp     #kAlertResultOK
        beq     maybe_format    ; OK
        jmp     InitDialog      ; Cancel

        ;; --------------------------------------------------
        ;; Format if necessary (and supported)

maybe_format:
        bit     disk_copy_flag
        bmi     try_format      ; full disk copy
        jmp     do_copy

try_format:
        jsr     SetCursorWatch

        ldx     dest_drive_index
        CALL    IsDiskII, A=drive_unitnum_table,x
        beq     format

        ldx     dest_drive_index
        CALL    main::DeviceDriverAddress, A=drive_unitnum_table,x ; Z=1 if firmware

        stax    $06
        bne     do_copy         ; if not firmware, skip these checks

        copy8   #$00, $06       ; point at $Cn00
        ldy     #$FE            ; $CnFE
        lda     ($06),y
        and     #$08            ; bit 3 = The device supports formatting.
        beq     do_copy

format: CALL    DrawStatus, AX=#str_formatting
        jsr     main::FormatDevice
        bcc     do_copy

    IF A <> #ERR_WRITE_PROTECTED
        CALL    ShowAlertDialog, A=#kAlertMsgFormatError ; no args
    ELSE
        CALL    ShowAlertDialog, A=#kAlertMsgDestinationProtected ; no args
    END_IF
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     try_format      ; Try Again
        jmp     InitDialog      ; Cancel

        ;; --------------------------------------------------
        ;; Perform the copy

do_copy:
        jsr     SetCursorWatch

        jsr     SetPortForDialog
        MGTK_CALL MGTK::PaintRect, rect_erase_dialog_upper

        CALL    MaybePromptDiskSwap, X=#kAlertMsgInsertSource

        jsr     SetCursorWatch

        jsr     main::ReadVolumeBitmap

        ;; Current block
        copy16  #0, block_num_div8
        copy8   #7, block_num_shift ; 7 - (n % 8)

        ;; Blocks to copy
        jsr     main::CountActiveBlocksInVolumeBitmap
        stax    transfer_blocks
        jsr     DrawTotalBlocks

        ;; Blocks read/written so far
        ldax    #AS_WORD(-1)
        stax    blocks_read
        stax    blocks_written

        jsr     IncAndDrawBlocksRead
        jsr     IncAndDrawBlocksWritten
        jsr     DrawEscToStopCopyHint

copy_loop:
        jsr     SetCursorWatch

        jsr     DrawStatusReading
        CALL    main::CopyBlocks, C=0 ; reading
        cmp     #$01
        beq     copy_failure

        CALL    MaybePromptDiskSwap, X=#kAlertMsgInsertDestination

        jsr     SetCursorWatch

        jsr     DrawStatusWriting
        CALL    main::CopyBlocks, C=1 ; writing
        bmi     copy_success
        bne     copy_failure

        CALL    MaybePromptDiskSwap, X=#kAlertMsgInsertSource
        jmp     copy_loop

copy_success:
        jsr     SetCursorWatch

        jsr     main::FreeVolBitmapPages

        ldx     source_drive_index
        CALL    main::EjectDisk, A=drive_unitnum_table,x
        ldx     dest_drive_index
    IF X <> source_drive_index
        CALL    main::EjectDisk, A=drive_unitnum_table,x
    END_IF

        CALL    ShowAlertDialog, A=#kAlertMsgCopySuccessful ; no args
        jmp     InitDialog

copy_failure:
        jsr     main::FreeVolBitmapPages

        CALL    ShowAlertDialog, A=#kAlertMsgCopyFailure ; no args
        jmp     InitDialog

;;; ============================================================
;;; Wait until there's a selection, or refresh drive list --
;;; in which case this doesn't return.
;;; Output: A = selection

.proc WaitForSelection
loop:   jsr     EventLoop
        bmi     loop
        beq     check

        MGTK_CALL MGTK::CloseWindow, winfo_drive_select
        pla
        pla
        jmp     InitDialog

check:  lda     current_drive_selection
        bmi     loop
        rts
.endproc ; WaitForSelection

;;; ============================================================

;;; Input: X = message (`kAlertMsgInsertSource` or `kAlertMsgInsertDestination`)
;;; Returns when complete; if canceled, pops return address and runs `InitDialog`

.proc MaybePromptDiskSwap
        stx     message

        lda     source_drive_index
    IF A = dest_drive_index

        tax                     ; A = index
        lda     drive_unitnum_table,x
        pha                     ; A = unit num
        jsr     main::EjectDisk
        pla                     ; A = unit num
        tay                     ; Y = unit num

        message := *+1
        lda     #SELF_MODIFIED_BYTE
        CALL    ShowAlertDialog, X=#$80 ; X != 0 means Y=unit number, auto-dismiss

        cmp     #kAlertResultOK
      IF NE
        pla                     ; Cancel
        pla
        jmp     InitDialog
      END_IF
    END_IF

        rts
.endproc ; MaybePromptDiskSwap

;;; ============================================================
;;; Wait for and process event
;;; Output: N=1 if should be called again
;;;         Z=1 if OK selected, should proceed
;;;         Otherwise: Cancel selected (close/re-init dialog)

EventLoop:
loop:   jsr     SystemTask
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind

        cmp     #MGTK::EventKind::button_down
        jeq     HandleClick

        cmp     #MGTK::EventKind::key_down
        bne     loop
        jmp     HandleKey

;;; ============================================================

menu_command_table:
        ;; Apple menu
        .addr   NoOp
        .addr   NoOp
        .addr   NoOp
        .addr   NoOp
        .addr   NoOp
        ;; File menu
        .addr   main::Quit
        ;; Facilities menu
        .addr   CmdQuickCopy
        .addr   CmdDiskCopy

menu_offset_table:
        .byte   0, 5*2, 6*2

;;; ============================================================

.proc HandleKey
        bit     listbox_enabled_flag
    IF NS
        lda     event_params::key
      IF A IN #CHAR_UP, #CHAR_DOWN
        sta     lb_params::key
        copy8   event_params::modifiers, lb_params::modifiers
        LBTK_CALL LBTK::Key, lb_params
        jsr     UpdateOKButton
        RETURN  A=#$FF
      END_IF
    END_IF

        lda     event_params::modifiers
    IF ZERO
        lda     event_params::key
      IF A <> #CHAR_ESCAPE
        CALL    ToUpperCase, A=event_params::key

       IF A = #kShortcutReadDisk
        BTK_CALL BTK::Flash, read_drive_button
        RETURN  A=#1
       END_IF

       IF A = #CHAR_RETURN
        BTK_CALL BTK::Flash, dialog_ok_button
        bmi     ignore          ; disabled
        RETURN  A=#0
       END_IF

ignore: RETURN  A=#$FF
      END_IF
    END_IF

        ;; Keyboard-based menu selection
        copy8   event_params::key, menukey_params::which_key
        copy8   event_params::modifiers, menukey_params::key_mods
        MGTK_CALL MGTK::MenuKey, menukey_params
        FALL_THROUGH_TO HandleMenuSelection
.endproc ; HandleKey

.proc HandleMenuSelection
        ldx     menuselect_params::menu_id
    IF ZERO
        RETURN  A=#$FF
    END_IF

        ;; Compute offset into command table - menu offset + item offset
        lda     menuselect_params::menu_item ; menu item index is 1-based
        asl     a
        clc
        adc     menu_offset_table-1,x ; menu id is also 1-based
        tax
        copy16  menu_command_table-2,x, jump_addr ; 1-based (*2) to 0-based
        jsr     do_jump
        MGTK_CALL MGTK::HiliteMenu, hilitemenu_params
        jmp     EventLoop

do_jump:
        jump_addr := *+1
        jmp     SELF_MODIFIED
.endproc ; HandleMenuSelection

;;; ============================================================

.proc SetCopyModeImpl
        ENTRY_POINTS_FOR_A quick_copy, $00, disk_copy, $80

        eor     disk_copy_flag
        RTS_IF NC               ; no-op

        lda     disk_copy_flag
        eor     #$80
        sta     disk_copy_flag

        ;; Uncheck the previous `checkitem_params::menu_item`
        copy8   #MGTK::checkitem_uncheck, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params

        ;; Check the other one
        ASSERT_EQUALS 3 - auxlc::kMenuItemIdQuickCopy, auxlc::kMenuItemIdDiskCopy
        lda     checkitem_params::menu_item
        eor     #3
        sta     checkitem_params::menu_item
        copy8   #MGTK::checkitem_check, checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params

        ;; Update dialog title
        jsr     SetPortForDialog
        MGTK_CALL MGTK::PaintRect, rect_erase_title
        MGTK_CALL MGTK::MoveTo, point_title
        ldax    #label_quick_copy
        bit     disk_copy_flag
    IF NS
        ldax    #label_disk_copy
    END_IF
        TAIL_CALL DrawStringCentered
.endproc ; SetCopyModeImpl
CmdQuickCopy := SetCopyModeImpl::quick_copy
CmdDiskCopy := SetCopyModeImpl::disk_copy

;;; ============================================================

.proc HandleClick
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        .assert MGTK::Area::desktop = 0, error, "enum mismatch"
        RTS_IF ZERO

    IF A = #MGTK::Area::menubar
        MGTK_CALL MGTK::MenuSelect, menuselect_params
        jmp     HandleMenuSelection
    END_IF

    IF A <> #MGTK::Area::content
        RETURN  A=#$FF
    END_IF

        lda     findwindow_params::window_id
        cmp     #winfo_dialog::kWindowId
        beq     HandleDialogClick

    IF A = #kListBoxWindowId
        COPY_STRUCT event_params::coords, lb_params::coords
        LBTK_CALL LBTK::Click, lb_params

        php
        jsr     UpdateOKButton
        plp
      IF NC
        jsr     DetectDoubleClick
      END_IF
    END_IF
        rts
.endproc ; HandleClick

;;; ============================================================

.proc UpdateOKButton
        lda     current_drive_selection
        and     #$80
        .assert BTK::kButtonStateDisabled = $80, error, "const mismatch"

        cmp     dialog_ok_button::state
        beq     ret
        sta     dialog_ok_button::state
        BTK_CALL BTK::Hilite, dialog_ok_button

ret:    rts
.endproc ; UpdateOKButton

;;; ============================================================

.proc HandleDialogClick
        jsr     SetPortForDialog
        copy8   #winfo_dialog::kWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, dialog_ok_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, dialog_ok_button
      IF NC
        lda     #$00
      END_IF
        rts
    END_IF

        MGTK_CALL MGTK::InRect, read_drive_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, read_drive_button
      IF NC
        lda     #$01
      END_IF
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
        phax

        ;; Copy the params here
        ldy     #3              ; ptr is off by 1
    DO
        copy8   (params_src),y, params-1,y
        dey
    WHILE NOT_ZERO

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
;;; Input: A = table index
;;; Output: A,X = address in `drive_name_table`

.proc GetDriveNameTableSlot
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

        rts
.endproc ; GetDriveNameTableSlot

;;; ============================================================
;;; Input: A,X = source string, `num_drives` must be valid

.proc AssignDriveName
        src_ptr := $06
        dst_ptr := $08

        stax    src_ptr

        CALL    GetDriveNameTableSlot, A=num_drives
        stax    dst_ptr

        ldy     #0
        lda     (src_ptr),y
        tay
      DO
        copy8   (src_ptr),y, (dst_ptr),y
        dey
      WHILE POS
        rts
.endproc ; AssignDriveName

;;; ============================================================
;;; Check block at `default_block_buffer` for Pascal signature
;;; Output: C=0 if Pascal volume, C=1 otherwise

.proc IsPascalBootBlock
        lda     default_block_buffer+1
        cmp     #$E0
        bne     fail

        lda     default_block_buffer+2
        cmp     #$70
        beq     match
        cmp     #$60
        beq     match

fail:   RETURN  C=1

match:  RETURN  C=0
.endproc ; IsPascalBootBlock

;;; ============================================================
;;; Check block at `default_block_buffer` for DOS 3.3 signature
;;; Output: C=0 if DOS 3.3 volume, C=1 otherwise

.proc IsDOS33BootBlock
        lda     default_block_buffer+1
        cmp     #$A5
        bne     fail
        lda     default_block_buffer+2
        cmp     #$27
        beq     match

fail:   RETURN  C=1

match:  RETURN  C=0
.endproc ; IsDOS33BootBlock

;;; ============================================================
;;; Get Pascal volume name
;;; Inputs: A,X=destination buffer (16 bytes)
;;; Output: Pascal name, with ':' suffix.
;;;         If reading second block fails, just uses " ".

.proc GetPascalVolName
        ptr := $06

        stax    ptr
        copy16  #kVolumeDirKeyBlock, main::block_params::block_num
        jsr     main::ReadBlock
    IF CS
        ;; Just use a single space as the name
        ldy     #0
        copy8   #1, (ptr),y
        iny
        copy8   #' ', (ptr),y
        rts
    END_IF

        ;; Copy the name out of the block
        str_name := default_block_buffer+6

        ldy     #kMaxFilenameLength
    DO
        copy8   str_name,y, (ptr),y
        dey
    WHILE POS

        ;; If less than 15 characters, increase len by one
        ldy     str_name
    IF Y < #kMaxFilenameLength
        iny
        tya
        ldy     #0
        sta     (ptr),y
        tay
    END_IF

        ;; Replace last char with ':'
        copy8   #':', (ptr),y
        rts
.endproc ; GetPascalVolName

;;; ============================================================

        .include "../lib/inttostring.s"

        ;; TODO: Move these out of the `auxlc` scope
        .include "../toolkits/btk.s"
        BTKEntry := btk::BTKEntry

        .include "../toolkits/lbtk.s"
        LBTKEntry := lbtk::LBTKEntry

;;; ============================================================

.proc DrawStringCentered
        params := $0A
        str := params
        width := params+2

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params
        lsr16   width
        sub16   #0, width, params+MGTK::Point::xcoord
        copy16  #0, params+MGTK::Point::ycoord
        MGTK_CALL MGTK::Move, params
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawStringCentered

;;; ============================================================

;;; Input: A,X is ON_LINE data buffer entry *including* the
;;;        slot/drive bits, not just the name.
;;; Output: entry is length-prefix, case-adjusted

.proc AdjustOnLineEntryCase
        ptr := $A

        stax    ptr

        ldy     #0
        lda     (ptr),y
        pha
        and     #UNIT_NUM_MASK  ; stash unit number
        sta     main::block_params::unit_num
        pla
        and     #NAME_LENGTH_MASK
        sta     (ptr),y         ; mask off length

.if kBuildSupportsLowercase

        ;; --------------------------------------------------
        ;; Check for GS/OS case bits, apply if found

        copy16  #kVolumeDirKeyBlock, main::block_params::block_num
        copy16  #default_block_buffer, main::block_params::data_buffer
        jsr     main::ReadBlock
        bcs     fallback

        case_bits := default_block_buffer + VolumeDirectoryHeader::case_bits
        asl16   case_bits
        bcc     fallback      ; High bit set = GS/OS case bits present

        ldy     #1
    DO
        asl16   case_bits       ; Shift out high byte first
      IF CS
        lda     (ptr),y
        ora     #AS_BYTE(~CASE_MASK) ; guarded by `kBuildSupportsLowercase`
        sta     (ptr),y
      END_IF
        iny
    WHILE Y < #16               ; bits
        rts

        ;; --------------------------------------------------
        ;; Use heuristic
fallback:
        .include "../lib/wordcase.s"
.else
        rts
.endif
.endproc ; AdjustOnLineEntryCase

;;; ============================================================

.proc SetPortForDialog
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured.
        MGTK_CALL MGTK::SetPort, grafport_win
        rts
.endproc ; SetPortForDialog

;;; ============================================================

;;; Called with A = index, X,Y = addr of drawing pos (MGTK::Point)
.proc DrawListEntryProc
        pha
        pt_ptr := $06
        stxy    pt_ptr
        ldy     #.sizeof(MGTK::Point)-1
    DO
        copy8   (pt_ptr),y, list_entry_pos,y
        dey
    WHILE POS
        pla

        bit     selection_mode_flag  ; source or destination?
    IF NS
        tax                     ; indirection for destination
        lda     destination_index_table,x
    END_IF

        jmp     DrawDeviceListEntry
.endproc ; DrawListEntryProc

;;; ============================================================

;;; Populates `num_drives`, `drive_unitnum_table` and `drive_name_table`
.proc EnumerateDevices
        CALL    main::CallOnLine2, A=#0
    IF CS
        brk                     ; rude!
    END_IF

        on_line_ptr := $06

        lda     #0
        sta     num_drives
        tax                     ; X = index
loop:
        txa
        pha

        asl     a               ; *=16 (each record is 16 bytes)
        asl     a
        asl     a
        asl     a
        clc
        adc     #<main::on_line_buffer2
        sta     on_line_ptr
        lda     #0
        adc     #>main::on_line_buffer2
        sta     on_line_ptr+1

        ;; Check first byte of record
        ldy     #0
        lda     (on_line_ptr),y
    IF ZERO                     ; 0 indicates end of valid records
        pla                     ; pop index off stack
        rts
    END_IF

        ;; Tentatively add to table; doesn't count until we inc `num_drives`
        pha                     ; A = unit number / name length
        and     #UNIT_NUM_MASK
        ldx     num_drives
        sta     drive_unitnum_table,x
        pla                     ; A = unit number / name length

        and     #NAME_LENGTH_MASK
    IF ZERO
        ;; Not ProDOS

        ;; name_len=0 signifies an error, with error code in second byte
        iny                     ; Y = 1
        lda     (on_line_ptr),y
      IF A = #ERR_DEVICE_NOT_CONNECTED
        ;; Device Not Connected - skip, unless it's a Disk II device
        dey                     ; Y = 0
        CALL    IsDiskII, A=(on_line_ptr),y ; A = unmasked unit number
        bne     next_device

        lda     #ERR_DEVICE_NOT_CONNECTED
      END_IF

      IF A = #ERR_NOT_PRODOS_VOLUME
        ldx     num_drives
        CALL    main::ReadBootBlock, A=drive_unitnum_table,x
        bcs     next_device     ; failure

        jsr     IsPascalBootBlock
       IF EQ
        ;; Pascal
        CALL    GetDriveNameTableSlot, A=num_drives ; result in A,X
        jsr     GetPascalVolName      ; A,X is buffer to populate
        jmp     keep_it
       END_IF

        jsr     IsDOS33BootBlock
       IF CC
        ;; DOS 3.3
        CALL    AssignDriveName, AX=#str_dos33
        jmp     keep_it
       END_IF
      END_IF

        ;; Unknown
        CALL    AssignDriveName, AX=#str_unknown
        ;; "fall through" to `keep_it`
    ELSE
        ;; Valid ProDOS volume

        ldx     num_drives
        lda     drive_unitnum_table,x
      IF A = DISK_COPY_INITIAL_UNIT_NUM
        copy8   num_drives, current_drive_selection
      END_IF

        CALL    AdjustOnLineEntryCase, AX=on_line_ptr
        CALL    AssignDriveName, AX=on_line_ptr

        FALL_THROUGH_TO keep_it
    END_IF

keep_it:
        inc     num_drives

next_device:
        pla
        tax
        inx                     ; X = index
        cpx     #kMaxNumDrives+1
        jne     loop

        rts

.endproc ; EnumerateDevices

;;; ============================================================

;;; Sets `num_drives` to the number of plausible destination devices,
;;; and populates `destination_index_table`. Also clears selection.
.proc EnumerateDestinationDevices
        ;; Stash source drive details
        lda     current_drive_selection
        asl     a
        tax
        src_block_count := $06
        copy16  block_count_table,x, src_block_count

        copy8   num_drives, num_src_drives

        lda     #0
        sta     num_drives
        tax                     ; X = index
    DO
        txa
        pha

        ;; Compare block counts
        asl     a
        tax
        ecmp16  block_count_table,x, src_block_count
      IF EQ
        ;; Same - add it
        pla                     ; A = index
        pha
        ldx     num_drives
        sta     destination_index_table,x

        ;; Keep going
        inc     num_drives
      END_IF

        pla
        tax
        inx
    WHILE X <> num_src_drives

        ;; Clear selection
        copy8   #$FF, current_drive_selection
        rts
.endproc ; EnumerateDestinationDevices

;;; ============================================================

;;; Input: A = device index
.proc DrawDeviceListEntry
        pha                     ; A = index
        tax
        CALL    PrepSDStrings, A=drive_unitnum_table,x

        ;; Slot
        copy8   #kListEntrySlotOffset, list_entry_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, list_entry_pos
        MGTK_CALL MGTK::DrawString, str_s

        ;; Drive
        copy8   #kListEntryDriveOffset, list_entry_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, list_entry_pos
        MGTK_CALL MGTK::DrawString, str_d

        ;; Name
        copy8   #kListEntryNameOffset, list_entry_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, list_entry_pos

        pla                     ; A = index
        CALL    GetDriveNameTableSlot ; into A,X
        stax    @addr
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawDeviceListEntry

;;; ============================================================
;;; Populate block_count_table across all devices

.proc GetAllBlockCounts
        ldx     #0              ; index
    DO
        txa
        pha

        jsr     GetBlockCount

        pla
        tax
        inx
    WHILE X <> num_drives
        rts
.endproc ; GetAllBlockCounts

;;; ============================================================
;;; Inputs: A = device index
;;; Outputs: block_count_table (word) set to block count

.proc GetBlockCount

        ;; Special case Disk II devices, since we may be formatting non-ProDOS
        ;; disks the driver can't interrogate.

        pha
        tax                     ; X is device index
        CALL    IsDiskII, A=drive_unitnum_table,x
    IF EQ
        ;; Disk II - always 280 blocks
        pla
        pha
        asl     a
        tax
        ldxy    #280
    ELSE
        ;; Otherwise - use device driver
        pla
        pha
        tax
        CALL    main::DeviceDriverAddress, A=drive_unitnum_table,x ; Z=1 if firmware
        addr := $06
        stax    addr

        pla
        pha
        tax
        CALL    main::GetDeviceBlocksUsingDriver, A=drive_unitnum_table,x, XY=addr ; result in X,Y
    END_IF

        ;; X,Y = block count
        tmp := $06
        stx     tmp
        pla
        asl     a
        tax
        copy8   tmp, block_count_table,x ; lo
        tya
        sta     block_count_table+1,x    ; hi
        rts

.endproc ; GetBlockCount

;;; ============================================================

.proc DrawStatus
        phax
        jsr     SetPortForDialog
        MGTK_CALL MGTK::PaintRect, rect_status
        MGTK_CALL MGTK::MoveTo, point_status
        plax
        jmp     DrawStringCentered
.endproc ; DrawStatus

.proc DrawStatusWriting
        CALL    DrawStatus, AX=#str_writing
        jmp     DrawProgressBar
.endproc ; DrawStatusWriting

.proc DrawStatusReading
        CALL    DrawStatus, AX=#str_reading
        jmp     DrawProgressBar
.endproc ; DrawStatusReading

.proc DrawTotalBlocks
        jsr     IntToStringWithSeparators
        jsr     SetPortForDialog
        MGTK_CALL MGTK::MoveTo, blocks_to_transfer_label_pos
        MGTK_CALL MGTK::DrawString, blocks_to_transfer_label_str
        jmp     DrawIntString
.endproc ; DrawTotalBlocks

.proc IncAndDrawBlocksRead
        jsr     SetPortForDialog
        inc16   blocks_read
        CALL    IntToStringWithSeparators, AX=blocks_read
        MGTK_CALL MGTK::MoveTo, blocks_read_label_pos
        MGTK_CALL MGTK::DrawString, blocks_read_label_str
        jmp     DrawIntString
.endproc ; IncAndDrawBlocksRead

.proc IncAndDrawBlocksWritten
        jsr     SetPortForDialog
        inc16   blocks_written
        CALL    IntToStringWithSeparators, AX=blocks_written
        MGTK_CALL MGTK::MoveTo, blocks_written_label_pos
        MGTK_CALL MGTK::DrawString, blocks_written_label_str
        FALL_THROUGH_TO DrawIntString
.endproc ; IncAndDrawBlocksWritten

.proc DrawIntString
        MGTK_CALL MGTK::DrawString, str_from_int
        MGTK_CALL MGTK::DrawString, str_2_spaces
        rts
.endproc ; DrawIntString

blocks_read:
        .word   0
blocks_written:
        .word   0
transfer_blocks:
        .word   0

.params progress_muldiv_params
number:         .word   kProgressWidth ; (in) constant
numerator:      .word   0              ; (in) populated dynamically
denominator:    .word   0              ; (in) populated dynamically
result:         .word   0              ; (out)
remainder:      .word   0              ; (out)
.endparams

.proc DrawProgressBar
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, progress_frame
        copy16  transfer_blocks, progress_muldiv_params::denominator

        ;; read+written will not fit in 16 bits if total is > $7FFF
        ;; so scale appropriately
        tmp_read := $06
        tmp_written := $08
        copy16  blocks_read, tmp_read
        copy16  blocks_written, tmp_written
        bit     progress_muldiv_params::denominator+1
    IF NC
        ;; Use (read + written) / total*2
        asl16   progress_muldiv_params::denominator
    ELSE
        ;; Use ((read + written) / 2) / total
        lsr16   tmp_read
        lsr16   tmp_written
    END_IF
        add16   tmp_read, tmp_written, progress_muldiv_params::numerator

        MGTK_CALL MGTK::MulDiv, progress_muldiv_params
        add16   progress_bar::x1, progress_muldiv_params::result, progress_bar::x2
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, progress_pattern
        MGTK_CALL MGTK::PaintRect, progress_bar
        rts
.endproc ; DrawProgressBar

;;; ============================================================

.proc DrawSourceDriveInfo
        jsr     SetPortForDialog
        MGTK_CALL MGTK::MoveTo, source_label_pos
        MGTK_CALL MGTK::DrawString, source_label_str

        ldx     source_drive_index
        CALL    PrepSDStrings, A=drive_unitnum_table,x
        MGTK_CALL MGTK::MoveTo, point_source_slot_drive
        MGTK_CALL MGTK::DrawString, str_slot_drive_pattern

        bit     source_disk_format
        ASSERT_EQUALS auxlc::kSourceDiskFormatProDOS & $80, $00
        bpl     show_name       ; ProDOS

        ASSERT_EQUALS auxlc::kSourceDiskFormatDOS33 & $40, $00
        bvs     ret             ; DOS 3.3

        lda     source_disk_format
        and     #$0F
        ASSERT_EQUALS auxlc::kSourceDiskFormatPascal & $0F, $00
        bne     ret             ; Other

show_name:
        MGTK_CALL MGTK::DrawString, str_2_spaces
        COPY_STRING main::on_line_buffer2, device_name_buf
        MGTK_CALL MGTK::DrawString, device_name_buf

ret:    rts
.endproc ; DrawSourceDriveInfo

;;; ============================================================

.proc DrawDestinationDriveInfo
        jsr     SetPortForDialog
        MGTK_CALL MGTK::MoveTo, destination_label_pos
        MGTK_CALL MGTK::DrawString, destination_label_str

        ldx     dest_drive_index
        CALL    PrepSDStrings, A=drive_unitnum_table,x
        MGTK_CALL MGTK::MoveTo, point_destination_slot_drive
        MGTK_CALL MGTK::DrawString, str_slot_drive_pattern

        rts
.endproc ; DrawDestinationDriveInfo

;;; ============================================================

.proc DrawCopyFormatType
        jsr     SetPortForDialog
        MGTK_CALL MGTK::MoveTo, point_disk_copy

        bit     source_disk_format
        ASSERT_EQUALS auxlc::kSourceDiskFormatProDOS & $80, $00
    IF NC                       ; ProDOS
        MGTK_CALL MGTK::DrawString, str_prodos_disk_copy
        rts
    END_IF

        ASSERT_EQUALS auxlc::kSourceDiskFormatDOS33 & $40, $00
    IF VC                       ; DOS 3.3
        MGTK_CALL MGTK::DrawString, str_dos33_disk_copy
        rts
    END_IF

        lda     source_disk_format
        and     #$0F
        ASSERT_EQUALS auxlc::kSourceDiskFormatPascal & $0F, $00
    IF ZERO                     ; Pascal
        MGTK_CALL MGTK::DrawString, str_pascal_disk_copy
        rts
    END_IF

        ;; Nothing if `kSourceDiskFormatOther`

        rts
.endproc ; DrawCopyFormatType

.proc DrawEscToStopCopyHint
        jsr     SetPortForDialog
        MGTK_CALL MGTK::MoveTo, escape_stop_copy_label_pos
        TAIL_CALL DrawStringCentered, AX=#escape_stop_copy_label_str
.endproc ; DrawEscToStopCopyHint

;;; ============================================================
;;; Inputs: A = error code, X = writing flag
;;; Outputs: A=0 for ok, 1 for retry, $80 for cancel
.proc ShowBlockError
        stx     err_writing_flag

    IF A = #ERR_WRITE_PROTECTED
        jsr     main::Bell
        CALL    ShowAlertDialog, A=#kAlertMsgDestinationProtected ; no args
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
      IF ZERO
        jsr     DrawStatusWriting ; Try Again
        RETURN  A=#1
      END_IF
        jsr     main::FreeVolBitmapPages
        RETURN  A=#$80
    END_IF

        jsr     main::Bell
        jsr     SetPortForDialog
        CALL    IntToStringWithSeparators, AX=main::block_params::block_num

        lda     err_writing_flag
    IF ZERO
        MGTK_CALL MGTK::MoveTo, error_reading_label_pos
        MGTK_CALL MGTK::DrawString, error_reading_label_str
        jsr     DrawIntString
        RETURN  A=#0
    END_IF

        MGTK_CALL MGTK::MoveTo, error_writing_label_pos
        MGTK_CALL MGTK::DrawString, error_writing_label_str
        jsr     DrawIntString
        RETURN  A=#0

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

        jsr     main::PrepBlockPtrs

        ;; Read block
        jsr     main::ReadBlockWithRetry
        bmi     ret

        ;; Copy block from main to aux
        sta     RAMRDOFF
        sta     RAMWRTON

        ldy     #$00
    DO
        copy8   default_block_buffer,y,      (ptr1),y
        copy8   default_block_buffer+$100,y, (ptr2),y
        iny
    WHILE NOT_ZERO

        sta     RAMRDOFF
        sta     RAMWRTOFF

        lda     #0
ret:    rts
.endproc ; ReadBlockToAuxmem

;;; ============================================================
;;; Write block (w/ retries) from aux memory
;;; Inputs: A,X=address to read from
;;; Outputs: A=0 on success, nonzero otherwise

.proc WriteBlockFromAuxmem
        ptr1 := $06
        ptr2 := $08             ; one page up

        jsr     main::PrepBlockPtrs

        ;; Copy block aux to main
        sta     RAMRDON
        sta     RAMWRTOFF

        ldy     #$00
    DO
        copy8   (ptr1),y, default_block_buffer,y
        copy8   (ptr2),y, default_block_buffer+$100,y
        iny
    WHILE NOT_ZERO

        sta     RAMRDOFF
        sta     RAMWRTOFF

        ;; Write block
        jmp     main::WriteBlockWithRetry
.endproc ; WriteBlockFromAuxmem

;;; ============================================================

;;; Input: A = unit number (i.e. %DSSSxxxx)
;;; Output: `str_slot_drive_pattern` populated
.proc PrepSDStrings
        pha
        jsr     UnitNumToSlotDigit
        sta     str_s + 1
        sta     str_slot_drive_pattern + res_const_slot_drive_pattern_offset1
        pla
        jsr     UnitNumToDriveDigit
        sta     str_d + 1
        sta     str_slot_drive_pattern + res_const_slot_drive_pattern_offset2
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


.proc ShowAlertDialogImpl

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

;;; This string is seen when copying over a DOS 3.3 disk.
str_confirm_erase_dos33:
        PASCAL_STRING res_string_prompt_erase_dos33_pattern
        kStrConfirmEraseDOS33SlotOffset = res_const_prompt_erase_dos33_pattern_offset1
        kStrConfirmEraseDOS33DriveOffset = res_const_prompt_erase_dos33_pattern_offset2
;;; This string is seen when copying over a non-ProDOS/non-Pascal/non-DOS 3.3 disk.
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
        .byte   kAlertMsgConfirmEraseDOS33
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
        .addr   str_confirm_erase_dos33
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
        .byte   AlertButtonOptions::OKCancel    ; kAlertMsgConfirmEraseDOS33
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
        .byte   0                       ; kAlertMsgConfirmEraseDOS33
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
        CLEAR_BIT7_FLAG ejectable_flag

        ;; --------------------------------------------------
        ;; Determine alert options

        pla                     ; A = alert id
        .assert kAlertMsgInsertSource = 0, error, "enum mismatch"
    IF ZERO                     ; kAlertMsgInsertSource
        cpx     #0
        beq     find_in_alert_table
        jsr     _IsDriveEjectable
        beq     find_in_alert_table ; nope, stick with kAlertMsgInsertSource
        lda     #kAlertMsgInsertSourceOrCancel
        bne     find_in_alert_table ; always
    END_IF

    IF A = #kAlertMsgInsertDestination
        cpx     #0
        beq     find_in_alert_table
        jsr     _IsDriveEjectable
      IF NOT_ZERO
        lda     #kAlertMsgInsertDestinationOrCancel
        bne     find_in_alert_table ; always
      END_IF
        lda     #kAlertMsgInsertDestination
        bne     find_in_alert_table ; always
    END_IF

    IF A = #kAlertMsgConfirmErase
        jsr     _AppendToConfirmErase
        lda     #kAlertMsgConfirmErase
        bne     find_in_alert_table ; always
    END_IF

    IF A IN #kAlertMsgConfirmEraseSlotDrive, #kAlertMsgConfirmEraseDOS33
        pha
        jsr     _SetConfirmEraseSlotDrive
        pla
        FALL_THROUGH_TO find_in_alert_table
    END_IF

find_in_alert_table:
        ;; A = alert id; search table to determine index
        ldy     #0
    DO
        cmp     alert_table,y
        beq     :+
        iny
    WHILE Y <> #kNumAlertMessages
        ldy     #0              ; default
:
        ;; Y = index
        tya
        asl     a
        tay
        copy16  message_table,y, alert_params::text
        tya
        lsr     a
        tay
        copy8   alert_button_options_table,y, alert_params::buttons
        copy8   alert_options_table,y, alert_params::options

        TAIL_CALL Alert, AX=#alert_params

;;; --------------------------------------------------
;;; Inputs: X,Y = volume name

.proc _AppendToConfirmErase
        ptr := $06
        stxy    ptr
        ldy     #$00
        lda     (ptr),y
        pha
        tay
    DO
        copy8   (ptr),y, str_confirm_erase_buf-1,y
        dey
    WHILE NOT_ZERO

        pla
        clc
        adc     #kLenConfirmErase

        tay
        ldx     #0
    DO
        iny
        inx
        copy8   str_confirm_erase_suffix,x, str_confirm_erase,y
    WHILE X <> str_confirm_erase_suffix

        sty     str_confirm_erase
        rts
.endproc ; _AppendToConfirmErase

;;; --------------------------------------------------
;;; Inputs: X = %DSSSxxxx

.proc _SetConfirmEraseSlotDrive
        txa
        jsr     UnitNumToSlotDigit
        sta     str_confirm_erase_sd  + kStrConfirmEraseSDSlotOffset
        sta     str_confirm_erase_dos33  + kStrConfirmEraseDOS33SlotOffset
        txa
        jsr     UnitNumToDriveDigit
        sta     str_confirm_erase_sd + kStrConfirmEraseSDDriveOffset
        sta     str_confirm_erase_dos33 + kStrConfirmEraseDOS33DriveOffset
        rts
.endproc ; _SetConfirmEraseSlotDrive

;;; --------------------------------------------------

;;; Y = unit number
;;; If ejectable, sets `ejectable_flag`
.proc _IsDriveEjectable
        sty     unit_num
        tya
        jsr     main::IsDriveEjectable
    IF NS
        sta     ejectable_flag
    END_IF
        rts
.endproc ; _IsDriveEjectable

.endproc ; ShowAlertDialogImpl
ShowAlertDialog := ShowAlertDialogImpl::start

;;; ============================================================

.scope alert_dialog

        alert_grafport := grafport
        Bell := main::Bell

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
        CALL    main::CallOnLine, A=unit_num
        bcc     done

        cmp     #ERR_NOT_PRODOS_VOLUME
        beq     done
        lda     main::on_line_buffer
        and     #NAME_LENGTH_MASK
        bne     done
        lda     main::on_line_buffer+1
        cmp     #ERR_NOT_PRODOS_VOLUME
        beq     done

        jsr     SystemTask
        MGTK_CALL MGTK::GetEvent, Alert::event_params
        lda     Alert::event_kind
        cmp     #MGTK::EventKind::key_down
        bne     @retry

        lda     Alert::event_key
        cmp     #CHAR_ESCAPE
        bne     @retry
        RETURN  A=#$80

done:   RETURN  A=#$00
.endproc ; WaitForDiskOrEsc

.endscope ; alert_dialog
Alert := alert_dialog::Alert

;;; ============================================================
;;; Called by main and nested event loops to do periodic tasks.
;;; Returns 0 if the periodic tasks were run.

.proc SystemTask
        kMaxCounter = $E0       ; arbitrary

        inc     loop_counter
        inc     loop_counter

        loop_counter := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #kMaxCounter
    IF GE
        copy8   #0, loop_counter
        jsr     main::ResetIIgsRGB ; in case it was reset by control panel
    END_IF

        RETURN  A=loop_counter
.endproc ; SystemTask

        .include "../lib/is_diskii.s"
        .include "../lib/doubleclick.s"
        .include "../lib/uppercase.s"

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

        .assert * <= $F000, error, "Update memory_bitmap if code extends past $F000"
.endscope ; auxlc

        ENDSEG SegmentAuxLC
