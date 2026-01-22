;;; ============================================================
;;; Selector Application
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        BEGINSEG SegmentApp

;;; ============================================================
;;; MGTK library

        ASSERT_ADDRESS ::MGTKEntry
        .include "../mgtk/mgtk.s"

;;; ============================================================
;;; Font

        FONT := *
        .incbin .concat("../../out/System.", kBuildLang, ".font")

;;; ============================================================

.scope app

;;; ============================================================

;;; TODO: Move these somewhere more sensible
penXOR:         .byte   MGTK::penXOR
notpencopy:     .byte   MGTK::notpencopy

        .include "../lib/event_params.s"

;;; See docs/Selector_List_Format.md for file format
selector_list   := $B300

kShortcutRunDeskTop = res_char_button_desktop_shortcut
kShortcutRunProgram = res_char_menu_item_run_a_program_shortcut

;;; ============================================================
;;; Resources

;;; for MenuSelect, HiliteMenu, MenuKey
.params menu_params
menu_id:
        .byte   $00
menu_item:
        .byte   $00

;;; for MenuKey only
which_key:
        .byte   $00
key_mods:
        .byte   $00
.endparams

        ;; Menu bar
        DEFINE_MENU_BAR menu, 3
        DEFINE_MENU_BAR_ITEM 1, str_apple, apple_menu
        DEFINE_MENU_BAR_ITEM 2, str_file, file_menu
        DEFINE_MENU_BAR_ITEM 3, str_startup, startup_menu

        ;; Apple menu
        DEFINE_MENU apple_menu, 5
        DEFINE_MENU_ITEM str_a2desktop
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM str_copyright1
        DEFINE_MENU_ITEM str_copyright2
        DEFINE_MENU_ITEM str_copyright3

        ;; File menu
        DEFINE_MENU file_menu, 1
        DEFINE_MENU_ITEM str_run_a_program, res_char_menu_item_run_a_program_shortcut

        ;; Startup menu
        DEFINE_MENU startup_menu, 1

kMenuItemShortcutOffset = 2

mi_x1:  DEFINE_MENU_ITEM str_slot_x1, '0'
mi_x2:  DEFINE_MENU_ITEM str_slot_x2, '0'
mi_x3:  DEFINE_MENU_ITEM str_slot_x3, '0'
mi_x4:  DEFINE_MENU_ITEM str_slot_x4, '0'
mi_x5:  DEFINE_MENU_ITEM str_slot_x5, '0'
mi_x6:  DEFINE_MENU_ITEM str_slot_x6, '0'
mi_x7:  DEFINE_MENU_ITEM str_slot_x7, '0'

str_apple:
        PASCAL_STRING kGlyphSolidApple

str_file:
        PASCAL_STRING res_string_menu_bar_item_file
str_startup:
        PASCAL_STRING res_string_menu_bar_item_startup

str_a2desktop:
        PASCAL_STRING .sprintf(res_string_version_format_long, kDeskTopProductName, ::kDeskTopVersionMajor, ::kDeskTopVersionMinor, kDeskTopVersionSuffix)

str_copyright1:
        PASCAL_STRING res_string_copyright_line1 ; menu item
str_copyright2:
        PASCAL_STRING res_string_copyright_line2 ; menu item
str_copyright3:
        PASCAL_STRING res_string_copyright_line3 ; menu item

str_run_a_program:
        PASCAL_STRING res_string_menu_item_run_a_program


str_slot_x1:
        PASCAL_STRING res_string_menu_item_slot_pattern
str_slot_x2:
        PASCAL_STRING res_string_menu_item_slot_pattern
str_slot_x3:
        PASCAL_STRING res_string_menu_item_slot_pattern
str_slot_x4:
        PASCAL_STRING res_string_menu_item_slot_pattern
str_slot_x5:
        PASCAL_STRING res_string_menu_item_slot_pattern
str_slot_x6:
        PASCAL_STRING res_string_menu_item_slot_pattern
str_slot_x7:
        PASCAL_STRING res_string_menu_item_slot_pattern
        kStrSlotXOffset = res_const_menu_item_slot_pattern_offset1


;;; Slot numbers
slot_table:     .byte   0       ; number of entries

slot_x1:        .byte   0
slot_x2:        .byte   0
slot_x3:        .byte   0
slot_x4:        .byte   0
slot_x5:        .byte   0
slot_x6:        .byte   0
slot_x7:        .byte   0


;;; ============================================================
;;; More Resources

grafport2:
        .tag    MGTK::GrafPort

solid_pattern:
        .res    8, $FF

.params getwinport_params
window_id:      .byte   0
a_grafport:     .addr   grafport_win
.endparams

grafport_win:   .tag    MGTK::GrafPort

setzp_params:   .byte   MGTK::zp_overwrite ; performance over convenience

.params startdesktop_params
machine:        .byte   $06
subid:          .byte   $EA
op_sys:         .byte   0
slot_num:       .byte   0
use_interrupts: .byte   0
sysfontptr:     .addr   FONT
savearea:       .addr   $800
savesize:       .word   $800
.endparams

desktop_started_flag:
        .byte   0

.params scalemouse_params
x_exponent:     .byte   1       ; MGTK default is x 2:1 and y 1:1
y_exponent:     .byte   0       ; ... doubled on IIc / IIc+
.endparams

.params winfo
        kDialogId = 1
        kWidth = 460
        kHeight = 124
window_id:      .byte   kDialogId
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   0
vscroll:        .byte   0
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
        DEFINE_POINT viewloc, (::kScreenWidth - kWidth)/2, (::kScreenHeight - kHeight)/2
mapbits:        .word   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   $00
        DEFINE_RECT maprect, 0, 0, kWidth, kHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .word   FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        DEFINE_RECT_FRAME rect_frame, winfo::kWidth, winfo::kHeight

        DEFINE_BUTTON ok_button,      winfo::kDialogId, res_string_button_ok, kGlyphReturn, winfo::kWidth - kButtonWidth - 60, winfo::kHeight - 18
        DEFINE_BUTTON desktop_button, winfo::kDialogId, res_string_button_desktop, res_char_button_desktop_shortcut,       60, winfo::kHeight - 18

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY

        DEFINE_POINT pos_title_string, 0, 16

str_selector_title:
        PASCAL_STRING res_string_selector_name

        ;; Options control metrics
        kEntryPickerCols = 3
        kEntryPickerRows = 8
        kEntryPickerLeft = (winfo::kWidth - kEntryPickerItemWidth * kEntryPickerCols + 1) / 2
        kEntryPickerTop  = 21
        kEntryPickerItemWidth = 127
        kEntryPickerItemHeight = kListItemHeight
        kEntryPickerTextHOffset = 4
        kEntryPickerTextVOffset = kEntryPickerItemHeight-1

        ;; Line endpoints
        DEFINE_POINT line1_pt1, kBorderDX*2, 19
        DEFINE_POINT line1_pt2, winfo::kWidth - kBorderDX*2, 19
        DEFINE_POINT line2_pt1, kBorderDX*2, winfo::kHeight - 22
        DEFINE_POINT line2_pt2, winfo::kWidth - kBorderDX*2, winfo::kHeight - 22

        io_buf_sl = $BB00

        DEFINE_OPEN_PARAMS open_selector_list_params, str_selector_list, io_buf_sl
        DEFINE_READWRITE_PARAMS read_selector_list_params, selector_list, kSelectorListBufSize

        io_buf_desktop = $1C00
        desktop_load_addr = $2000
        kDeskTopLoadSize = $400

        DEFINE_OPEN_PARAMS open_desktop_params, str_desktop, io_buf_desktop
        DEFINE_READWRITE_PARAMS read_desktop_params, desktop_load_addr, kDeskTopLoadSize

str_selector_list:
        PASCAL_STRING kPathnameSelectorList

str_desktop:
        PASCAL_STRING kPathnameDeskTop

        DEFINE_CLOSE_PARAMS close_desktop_params

        DEFINE_OPEN_PARAMS open_selector_params, str_selector, $800

str_selector:
        PASCAL_STRING kPathnameSelector

        DEFINE_SET_MARK_PARAMS set_mark_overlay1_params, kOverlayFileDialogOffset
        DEFINE_SET_MARK_PARAMS set_mark_overlay2_params, kOverlayCopyDialogOffset
        DEFINE_READWRITE_PARAMS read_overlay1_params, OVERLAY_ADDR, kOverlayFileDialogLength
        DEFINE_READWRITE_PARAMS read_overlay2_params, OVERLAY_ADDR, kOverlayCopyDialogLength
        DEFINE_CLOSE_PARAMS close_overlay_params

str_desktop_2:
        PASCAL_STRING kPathnameDeskTop

desktop_available_flag:
        .byte   0

        DEFINE_GET_FILE_INFO_PARAMS file_info_params, SELF_MODIFIED

entry_string_buf:
        .res    20

num_primary_run_list_entries:
        .byte   0
num_secondary_run_list_entries:
        .byte   0

invoked_during_boot_flag: ; bit7 set during keyboard checks during boot
        .byte   0

;;; ============================================================
;;; Clock Resources

        DEFINE_RECT rect_clock, 460, 0, kScreenWidth - 11, 10

str_time:
        PASCAL_STRING "00:00 XM"

str_4_spaces:
        PASCAL_STRING "    "

str_space:
        PASCAL_STRING " "

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
        .tag    ParsedDateTime

;;; GrafPort used when drawing the clock
clock_grafport:
        .tag    MGTK::GrafPort

;;; Used to save the current GrafPort while drawing the clock.
.params getport_params
portptr:        .addr   0
.endparams

;;; ============================================================
;;; App Initialization

entry:
.scope AppInit
        copy8   #BTK::kButtonStateDisabled, ok_button::state
        jsr     LoadSelectorList
        SET_BIT7_FLAG invoked_during_boot_flag
        lda     num_secondary_run_list_entries
        ora     num_primary_run_list_entries
        bne     check_key_down

quick_run_desktop:
        CALL    GetFileInfo, AX=#str_desktop_2
        jcs     done_keys
        jmp     RunDesktop

        ;; --------------------------------------------------
        ;; Check for key down

check_key_down:
        copy8   #0, quick_boot_slot

        lda     KBD
        bpl     done_keys
        sta     KBDSTRB
        and     #CHAR_MASK
        jsr     ToUpperCase
        bit     BUTN0           ; Open Apple?
        bmi     :+
        bit     BUTN1           ; Solid Apple?
        bpl     check_key
:
    IF A BETWEEN #'1', #'7'     ; Apple + 1...7 = boot slot
        and     #%00001111      ; ASCII to number
        sta     quick_boot_slot
        jmp     done_keys
    END_IF

check_key:
        cmp     #kShortcutRunDeskTop ; If key is down, try launching DeskTop
        beq     quick_run_desktop

        sec
        sbc     #'1'            ; 1-8 run that selector entry
        bmi     done_keys
        cmp     num_primary_run_list_entries
        bcs     done_keys
        sta     invoke_index
        jsr     GetSelectorListEntryAddr

        entry_ptr := $06

        ;; TODO: See if we can skip this and just `InvokeEntry`
        stax    entry_ptr
        ldy     #kSelectorEntryFlagsOffset
        lda     (entry_ptr),y
    IF A <> #kSelectorEntryCopyNever
        jsr     GetCopiedToRAMCardFlag
        beq     done_keys       ; no RAMCard, skip
        CALL    GetEntryCopiedToRAMCardFlag, X=invoke_index
        bpl     done_keys       ; wasn't copied!
    END_IF

        invoke_index := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     InvokeEntry

        ;; --------------------------------------------------

done_keys:
        sta     KBDSTRB
        CLEAR_BIT7_FLAG invoked_during_boot_flag

        ;; --------------------------------------------------

        jsr     SaveAndAdjustDeviceList
        jsr     DisconnectRAM

        ;; --------------------------------------------------
        ;; Find slots with devices using ProDOS Device ID Bytes
.scope
        slot_ptr := $06         ; pointed at $Cn00

        copy8   #0, slot_ptr
        ldx     #7              ; slot

    DO
        txa
        ora     #$C0            ; hi byte of $Cn00
        sta     slot_ptr+1

        ldy     #$01            ; $Cn01 == $20 ?
        lda     (slot_ptr),y
        cmp     #$20
        bne     next

        ldy     #$03            ; $Cn03 == $00 ?
        lda     (slot_ptr),y
        cmp     #$00
        bne     next

        ldy     #$05            ; $Cn05 == $03 ?
        lda     (slot_ptr),y
        cmp     #$03
        bne     next

        ;; Match! Add to slot_table
        inc     slot_table
        ldy     slot_table
        txa
        sta     slot_table,y

next:   dex
    WHILE NOT_ZERO
.endscope

        ;; --------------------------------------------------
        ;; Set up Startup menu

        lda     quick_boot_slot
        beq     set_startup_menu_items
        ldy     slot_table
    DO
        cmp     slot_table,y
        jeq     StartupSlot
        dey
    WHILE NOT_ZERO
        FALL_THROUGH_TO set_startup_menu_items

set_startup_menu_items:
        copy8   slot_table, startup_menu

        lda     slot_x1
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x1 + kStrSlotXOffset
        sta     mi_x1 + kMenuItemShortcutOffset
        sta     mi_x1 + kMenuItemShortcutOffset + 1

        lda     slot_x2
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x2 + kStrSlotXOffset
        sta     mi_x2 + kMenuItemShortcutOffset
        sta     mi_x2 + kMenuItemShortcutOffset + 1

        lda     slot_x3
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x3 + kStrSlotXOffset
        sta     mi_x3 + kMenuItemShortcutOffset
        sta     mi_x3 + kMenuItemShortcutOffset + 1

        lda     slot_x4
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x4 + kStrSlotXOffset
        sta     mi_x4 + kMenuItemShortcutOffset
        sta     mi_x4 + kMenuItemShortcutOffset + 1

        lda     slot_x5
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x5 + kStrSlotXOffset
        sta     mi_x5 + kMenuItemShortcutOffset
        sta     mi_x5 + kMenuItemShortcutOffset + 1

        lda     slot_x6
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x6 + kStrSlotXOffset
        sta     mi_x6 + kMenuItemShortcutOffset
        sta     mi_x6 + kMenuItemShortcutOffset + 1

        lda     slot_x7
        ora     #$30            ; number to ASCII digit
        sta     mi_x7 + kMenuItemShortcutOffset
        sta     mi_x7 + kMenuItemShortcutOffset + 1
        sta     str_slot_x7 + kStrSlotXOffset

        ;; Copy pattern from settings
        tmp_pattern := $00
        ldx     #DeskTopSettings::pattern + .sizeof(MGTK::Pattern)-1
    DO
        jsr     ReadSetting
        sta     tmp_pattern - DeskTopSettings::pattern,x
        dex
    WHILE X <> #AS_BYTE(DeskTopSettings::pattern-1)

        MGTK_CALL MGTK::SetDeskPat, tmp_pattern

        copy8   VERSION, startdesktop_params::machine
        copy8   ZIDBYTE, startdesktop_params::subid

        jsr     ClearDHRToBlack

        MGTK_CALL MGTK::SetZP1, setzp_params
        MGTK_CALL MGTK::StartDeskTop, startdesktop_params
        SET_BIT7_FLAG desktop_started_flag
        jsr     SetRGBMode
        MGTK_CALL MGTK::SetMenu, menu
        jsr     ShowClock
        MGTK_CALL MGTK::ShowCursor
        MGTK_CALL MGTK::FlushEvents

        lda     startdesktop_params::slot_num
    IF ZERO
        CALL    ReadSetting, X=#DeskTopSettings::options
        ora     #DeskTopSettings::kOptionsShowShortcuts
        jsr     WriteSetting
    END_IF

        ;; --------------------------------------------------
        ;; Cursor tracking

        ;; Doubled if option selected
        CALL    ReadSetting, X=#DeskTopSettings::mouse_tracking
    IF NOT_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
    END_IF
        ;; Also doubled if a IIc
        lda     ZIDBYTE         ; ZIDBYTE=0 for IIc / IIc+
    IF ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
    END_IF
        MGTK_CALL MGTK::ScaleMouse, scalemouse_params
        ;; --------------------------------------------------

        ;; Is DeskTop available?
        CALL    GetFileInfo, AX=#str_desktop_2
        ror     desktop_available_flag ; bit7 = C (1=not available)

        ;; --------------------------------------------------
        ;; Open the window

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     GetPortAndDrawWindow
        copy8   #BTK::kButtonStateDisabled, ok_button::state
        jsr     LoadSelectorList
        jsr     PopulateEntriesFlagTable

        OPTK_CALL OPTK::Draw, op_params

        jmp     EventLoop

quick_boot_slot:
        .byte   0
.endscope ; AppInit

;;; ============================================================
;;; Event Loop

.proc EventLoop
        jsr     SystemTask
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
    IF A = #MGTK::EventKind::button_down
        jsr     HandleButtonDown
        jmp     EventLoop
    END_IF

    IF A = #MGTK::EventKind::key_down
        ;; --------------------------------------------------
        ;; Key Down
        bit     desktop_available_flag
      IF NC
        lda     event_params::key
        jsr     ToUpperCase
       IF A = #kShortcutRunDeskTop

        BTK_CALL BTK::Flash, desktop_button
retry:  CALL    GetFileInfo, AX=#str_desktop_2
        IF CS
        CALL    ShowAlert, A=#AlertID::insert_system_disk
        ASSERT_NOT_EQUALS ::kAlertResultCancel, 0
        bne     EventLoop       ; `kAlertResultCancel` = 1
        beq     retry           ; `kAlertResultTryAgain` = 0
        END_IF
        jmp     RunDesktop
       END_IF
      END_IF

        jsr     HandleKey
        jmp     EventLoop
    END_IF

        ;; --------------------------------------------------

    IF A = #MGTK::EventKind::update
        jsr     ClearUpdates
    END_IF

        jmp     EventLoop
.endproc ; EventLoop

;;; ============================================================
;;; Handle update events

CheckAndClearUpdates:
    DO
        MGTK_CALL MGTK::PeekEvent, event_params
        lda     event_params::kind
        BREAK_IF A <> #MGTK::EventKind::update

        MGTK_CALL MGTK::GetEvent, event_params
        FALL_THROUGH_TO ClearUpdates

ClearUpdates:
        lda     event_params::window_id
        CONTINUE_IF A <> #winfo::kDialogId

        MGTK_CALL MGTK::BeginUpdate, beginupdate_params
        CONTINUE_IF NOT_ZERO    ; obscured

        CALL    DrawWindow, C=1 ; is update
        OPTK_CALL OPTK::Update, op_params
        MGTK_CALL MGTK::EndUpdate
    WHILE ZERO                  ; always
        rts

;;; ============================================================
;;; Menu dispatch tables

menu_dispatch_table:
        ;; Apple menu
menu1:  .addr   noop
        .addr   noop
        .addr   noop
        .addr   noop
        .addr   noop
        .addr   noop
        .addr   noop

        ;; File menu
menu2:  .addr   CmdRunAProgram

        ;; Startup menu
menu3:  .addr   CmdStartup
        .addr   CmdStartup
        .addr   CmdStartup
        .addr   CmdStartup
        .addr   CmdStartup
        .addr   CmdStartup
        .addr   CmdStartup
menu_end:

menu_addr_table:
        .byte   menu1 - menu_dispatch_table
        .byte   menu2 - menu_dispatch_table
        .byte   menu3 - menu_dispatch_table
        .byte   menu_end - menu_dispatch_table

;;; ============================================================

        SelChangeCallback := UpdateOKButton
        DEFINE_OPTION_PICKER op_record, winfo::kDialogId, kEntryPickerLeft, kEntryPickerTop, kEntryPickerRows, kEntryPickerCols, kEntryPickerItemWidth, kEntryPickerItemHeight, kEntryPickerTextHOffset, kEntryPickerTextVOffset, IsEntryCallback, DrawEntryCallback, SelChangeCallback

        DEFINE_OPTION_PICKER_PARAMS op_params, op_record

;;; ============================================================

.proc HandleKey
        lda     event_params::modifiers
        bne     has_modifiers
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     menukey

other:  jmp     HandleNonmenuKey

has_modifiers:
        lda     event_params::key
        jsr     ToUpperCase
        cmp     #CHAR_ESCAPE
        beq     menukey
        cmp     #kShortcutRunProgram
        beq     menukey
        cmp     #'9'+1
        bcs     other
        cmp     #'1'
        bcc     other

menukey:
        sta     menu_params::which_key
        copy8   event_params::modifiers, menu_params::key_mods
        MGTK_CALL MGTK::MenuKey, menu_params::menu_id
        FALL_THROUGH_TO HandleMenu
.endproc ; HandleKey

;;; ==================================================

.proc HandleMenu
        ldx     menu_params::menu_item
        beq     fail
        ldx     menu_params::menu_id
        bne     :+
fail:   jmp     EventLoop

:       dex
        lda     menu_addr_table,x
        tax
        ldy     menu_params::menu_item
        dey
        tya
        asl     a
        sta     addr
        txa
        clc
        adc     addr
        tax
        copy16  menu_dispatch_table,x, addr
        jsr     dispatch
        MGTK_CALL MGTK::HiliteMenu, menu_params
        rts

dispatch:
        addr := *+1
        jmp     SELF_MODIFIED
.endproc ; HandleMenu

;;; ============================================================

.proc CmdRunAProgram
        jsr     ClearSelectedIndex

        jsr     SetCursorWatch  ; before loading overlay
retry:
        ;; Load file dialog overlay
        MLI_CALL OPEN, open_selector_params
    IF CS
        CALL    ShowAlert, A=#AlertID::insert_system_disk
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     retry           ; `kAlertResultTryAgain` = 0
        jmp     SetCursorPointer  ; after loading overlay (failure)
    END_IF

        lda     open_selector_params::ref_num
        sta     set_mark_overlay1_params::ref_num
        sta     read_overlay1_params::ref_num
        MLI_CALL SET_MARK, set_mark_overlay1_params
        MLI_CALL READ, read_overlay1_params
        MLI_CALL CLOSE, close_overlay_params

        jsr     SetCursorPointer  ; after loading overlay (success)

        ;; Invoke file dialog
        jsr     file_dialog_init
        ;; Returns Z=1 on success, Y,X = path to launch
        bne     cancel
ok:     tya                     ; now A,X = path
        jsr     SaveFileDialogState
        jsr     LaunchPath
        jsr     RestoreFileDialogState
        jsr     file_dialog_loop ; ditto
        beq     ok

cancel: jmp     LoadSelectorList

.endproc ; CmdRunAProgram

;;; ============================================================

.proc HandleButtonDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        ASSERT_EQUALS MGTK::Area::desktop, 0
        RTS_IF ZERO

    IF A = #MGTK::Area::menubar
        MGTK_CALL MGTK::MenuSelect, menu_params
        jmp     HandleMenu
    END_IF

        RTS_IF A <> #MGTK::Area::content

        lda     findwindow_params::window_id
        RTS_IF A <> #winfo::kDialogId

        CALL    GetWindowPort, A=#winfo::kDialogId
        copy8   #winfo::kDialogId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; OK button?

        MGTK_CALL MGTK::InRect, ok_button::rect
        beq     check_desktop_btn
        BTK_CALL BTK::Track, ok_button
        bmi     done
        jsr     TryInvokeSelectedIndex
done:   rts

        ;; DeskTop button?

check_desktop_btn:
        bit     desktop_available_flag
    IF NC
        MGTK_CALL MGTK::InRect, desktop_button::rect
      IF NOT_ZERO
        BTK_CALL BTK::Track, desktop_button
        bmi     done

retry:  CALL    GetFileInfo, AX=#str_desktop_2
       IF CS
        CALL    ShowAlert, A=#AlertID::insert_system_disk
        ASSERT_NOT_EQUALS kAlertResultCancel, 0
        bne     done            ; `kAlertResultCancel` = 1
        beq     retry           ; `kAlertResultTryAgain` = 0
       END_IF
        jmp     RunDesktop
      END_IF
    END_IF

        ;; Entry selection?
        COPY_STRUCT screentowindow_params::window, op_params::coords
        OPTK_CALL OPTK::Click, op_params
        bmi     ret
        jsr     DetectDoubleClick
    IF NC
        BTK_CALL BTK::Flash, ok_button
        jmp     TryInvokeSelectedIndex
    END_IF
ret:    rts
.endproc ; HandleButtonDown

;;; ============================================================

.proc UpdateOKButton
        lda     #BTK::kButtonStateNormal
        bit     op_record::selected_index
    IF NS
        lda     #BTK::kButtonStateDisabled
    END_IF

    IF A <> ok_button::state
        sta     ok_button::state
        BTK_CALL BTK::Hilite, ok_button
    END_IF

        rts
.endproc ; UpdateOKButton

;;; ============================================================

noop:   rts

;;; ============================================================

.proc RunDesktop
        jsr     RestoreSystem

        MLI_CALL OPEN, open_desktop_params
        lda     open_desktop_params::ref_num
        sta     read_desktop_params::ref_num
        MLI_CALL READ, read_desktop_params
        MLI_CALL CLOSE, close_desktop_params
        jmp     desktop_load_addr
.endproc ; RunDesktop

;;; ============================================================
;;; Assert: ROM banked in, ALTZP/LC is OFF

.proc RestoreSystem
        bit     desktop_started_flag
    IF NS
        MGTK_CALL MGTK::StopDeskTop
    END_IF
        jsr     RestoreTextMode
        jsr     ReconnectRAM
        jmp     RestoreDeviceList
.endproc ; RestoreSystem

;;; ============================================================
;;; Disable 80-col firmware, clear and show the text screen.
;;; Assert: ROM is banked in, ALTZP/LC is off

.proc RestoreTextMode
        sta     SET80STORE      ; 80-col firmware expects this
        lda     #0              ; INIT is not used as that briefly
        sta     WNDLFT          ; displays the dirty text page
        sta     WNDTOP
        copy8   #80, WNDWDTH
        copy8   #24, WNDBTM
        jsr     HOME            ; Clear 80-col screen
        sta     TXTSET          ; ... and show it

        CALL    COUT, A=#$95    ; Ctrl-U - disable 80-col firmware
        jsr     INIT            ; reset text window again
        jsr     SETVID          ; after INIT so WNDTOP is set properly
        jsr     SETKBD

        ;; Switch back to color DHR mode
        jsr     SetColorMode
        sta     CLR80VID        ; back off, after `SetColorMode` call
        sta     DHIRESOFF

        rts
.endproc ; RestoreTextMode

;;; ============================================================

.proc HandleNonmenuKey
        CALL    GetWindowPort, A=#winfo::kDialogId
        lda     event_params::key
    IF A < #$1C                 ; Control character?
        jmp     control_char
    END_IF

        ;; --------------------------------------------------

        ;; 1-8 to select entry

        RTS_IF A NOT_BETWEEN #'1', #'8'

        sec
        sbc     #'1'
        RTS_IF A >= num_primary_run_list_entries

        sta     op_params::new_selection
        OPTK_CALL OPTK::SetSelection, op_params
        jmp     UpdateOKButton

        ;; --------------------------------------------------
        ;; Control characters - return and arrows

        ;; Return ?

control_char:
    IF A = #CHAR_RETURN
        BTK_CALL BTK::Flash, ok_button
        jmp     TryInvokeSelectedIndex
    END_IF

        ;; --------------------------------------------------
        ;; Arrow keys?

        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
    IF NOT_ZERO
        lda     event_params::key
      IF A IN #CHAR_UP, #CHAR_DOWN, #CHAR_LEFT, #CHAR_RIGHT
        sta     op_params::key
        OPTK_CALL OPTK::Key, op_params
        rts
      END_IF
    END_IF

        rts

.endproc ; HandleNonmenuKey

;;; ============================================================

.proc PopulateEntriesFlagTable
        ldx     #kSelectorListNumEntries - 1
        lda     #$FF
    DO
        sta     entries_flag_table,x
        dex
    WHILE POS

        ldx     #0
    DO
        BREAK_IF X = num_primary_run_list_entries
        txa
        sta     entries_flag_table,x
        inx
    WHILE NOT_ZERO

        ldx     #0
    DO
        BREAK_IF X = num_secondary_run_list_entries
        txa
        clc
        adc     #8
        sta     entries_flag_table+8,x
        inx
    WHILE NOT_ZERO

        rts
.endproc ; PopulateEntriesFlagTable

;;; Table for 24 entries; index (0...23) if in use, $FF if empty
entries_flag_table:
        .res    ::kSelectorListNumEntries, 0

;;; ============================================================

.proc TryInvokeSelectedIndex
        lda     op_record::selected_index
        RTS_IF NS
        jmp     InvokeEntry
.endproc ; TryInvokeSelectedIndex

;;; ============================================================

.proc LoadSelectorList
        ;; Initialize the counts, in case load fails.
        lda     #0
        sta     selector_list + kSelectorListNumPrimaryRunListOffset
        sta     selector_list + kSelectorListNumSecondaryRunListOffset

        MLI_CALL OPEN, open_selector_list_params
        bcs     cache

        lda     open_selector_list_params::ref_num
        sta     read_selector_list_params::ref_num
        MLI_CALL READ, read_selector_list_params
        MLI_CALL CLOSE, close_desktop_params

cache:  copy8   selector_list + kSelectorListNumPrimaryRunListOffset, num_primary_run_list_entries
        copy8   selector_list + kSelectorListNumSecondaryRunListOffset, num_secondary_run_list_entries
        rts
.endproc ; LoadSelectorList

;;; ============================================================

.proc LoadOverlayCopyDialog
start:  MLI_CALL OPEN, open_selector_params
        bcs     error
        lda     open_selector_params::ref_num
        sta     set_mark_overlay2_params::ref_num
        sta     read_overlay2_params::ref_num
        MLI_CALL SET_MARK, set_mark_overlay2_params
        MLI_CALL READ, read_overlay2_params
        MLI_CALL CLOSE, close_overlay_params
        rts

error:
        CALL    ShowAlert, A=#AlertID::insert_system_disk ; `kAlertResultCancel` = 1
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     start           ; `kAlertResultTryAgain` = 0
        rts
.endproc ; LoadOverlayCopyDialog

;;; ============================================================

.proc SetCursorWatch
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        rts
.endproc ; SetCursorWatch

.proc SetCursorPointer
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts
.endproc ; SetCursorPointer

;;; ============================================================

.proc SaveAndAdjustDeviceList
        ;; Save original DEVCNT+DEVLST
        .assert DEVLST = DEVCNT+1, error, "DEVCNT must precede DEVLST"
        ldx     DEVCNT
        inx                     ; include DEVCNT itself
    DO
        copy8   DEVCNT,x, backup_devlst,x
        dex
    WHILE POS

        ;; Find the startup volume's unit number
        copy8   DEVNUM, target
        jsr     GetCopiedToRAMCardFlag
    IF NS
        CALL    CopyDeskTopOriginalPrefix, AX=#INVOKER_PREFIX
        CALL    GetFileInfo, AX=#INVOKER_PREFIX
      IF CC
        copy8   DEVNUM, target
      END_IF
    END_IF

        ;; Find the device's index in the list
        ldx     #0
    DO
        lda     DEVLST,x
        and     #UNIT_NUM_MASK  ; to compare against DEVNUM
        target := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     found
        inx
    WHILE X < DEVCNT
        bcs     done            ; last one or not found

        ;; Save it
found:  ldy     DEVLST,x

        ;; Move everything up
    DO
        copy8   DEVLST+1,x, DEVLST,x
        inx
    WHILE X <> DEVCNT

        ;; Place it at the end
        tya
        sta     DEVLST,x

done:   rts
.endproc ; SaveAndAdjustDeviceList

.proc RestoreDeviceList
        ;; Verify that a backup was done. Note that DEVCNT can be
        ;; zero (since it is num devices - 1) so the high bit is used.
        ldx     backup_devlst   ; the original DEVCNT
        bmi     ret             ; backup was never done

        inx                     ; include DEVCNT itself
    DO
        copy8   backup_devlst,x, DEVCNT,x
        dex
    WHILE POS

ret:    rts
.endproc ; RestoreDeviceList

backup_devlst:
        .byte   $FF             ; backup for DEVCNT (w/ high bit set)
        .res    14, 0           ; backup for DEVLST (7 slots * 2 drives)

;;; ============================================================

.proc GetPortAndDrawWindow
        CALL    GetWindowPort, A=#winfo::kDialogId
        clc                     ; not an update
        FALL_THROUGH_TO DrawWindow
.endproc ; GetPortAndDrawWindow

;;; Inputs: C set if processing update event, clear otherwise
.proc DrawWindow
        ;; C = is update
        php

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, rect_frame

        MGTK_CALL MGTK::SetPenSize, pensize_normal
        CALL    DrawTitleString, AX=#str_selector_title

        plp
    IF CS
        ;; Processing update event
        BTK_CALL BTK::Update, ok_button
        bit     desktop_available_flag
      IF NC
        BTK_CALL BTK::Update, desktop_button
      END_IF
    ELSE
        ;; Non-update
        BTK_CALL BTK::Draw, ok_button
        bit     desktop_available_flag
      IF NC
        BTK_CALL BTK::Draw, desktop_button
      END_IF
    END_IF

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::MoveTo, line1_pt1
        MGTK_CALL MGTK::LineTo, line1_pt2
        MGTK_CALL MGTK::MoveTo, line2_pt1
        MGTK_CALL MGTK::LineTo, line2_pt2
        rts
.endproc ; DrawWindow

;;; ============================================================
;;; Draw Title String (centered at top of port)
;;; Input: A,X = string address

.proc DrawTitleString
        params := $6
        str := params
        width := params+2

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params
        sub16   #winfo::kWidth, width, pos_title_string::xcoord
        lsr16   pos_title_string::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, pos_title_string
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawTitleString

;;; ============================================================
;;; Set the active GrafPort to the selected window's port
;;; Input: A = window id

.proc GetWindowPort
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport_win
        rts
.endproc ; GetWindowPort

;;; ============================================================
;;; Input: A = Entry number
;;; Output: A,X = Entry address

.proc GetSelectorListEntryAddr
        addr := selector_list + kSelectorListEntriesOffset

        ldx     #0
        stx     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        clc
        adc     #<addr
        tay
        lda     hi
        adc     #>addr
        tax
        tya
        rts

hi:     .byte   0
.endproc ; GetSelectorListEntryAddr

;;; ============================================================

.proc GetSelectorListPathAddr
        addr := selector_list + kSelectorListPathsOffset

        ldx     #0
        stx     hi
        lsr     a
        ror     hi
        lsr     a
        ror     hi
        pha
        lda     hi
        adc     #<addr
        tay
        pla
        adc     #>addr
        tax
        tya
        rts

hi:     .byte   0
.endproc ; GetSelectorListPathAddr

;;; ============================================================
;;; Input: A = entry number
;;; Output: N=0 if valid entry

.proc IsEntryCallback
        tay
        ldx     entries_flag_table,y ; set N
        rts
.endproc ; IsEntryCallback

;;; ============================================================
;;; Input: A = entry number

.proc DrawEntryCallback
        ptr := $06

        pha
        jsr     GetSelectorListEntryAddr
        stax    ptr
        ldy     #0
        lda     (ptr),y         ; length

        ;; Copy string into buffer
        tay
    DO
        copy8   (ptr),y, entry_string_buf+3,y
        dey
    WHILE NOT_ZERO

        ;; Increase length by 3
        ldy     #0
        lda     (ptr),y
        clc
        adc     #3
        sta     text_params::length

        pla
    IF A >= #8                  ; first 8?
        ;; Prefix with spaces
        lda     #' '
        sta     entry_string_buf+1
        sta     entry_string_buf+2
        sta     entry_string_buf+3
    ELSE
        ;; Prefix with number
        adc     #'1'
        sta     entry_string_buf+1
        lda     #' '
        sta     entry_string_buf+2
        sta     entry_string_buf+3
    END_IF

        ;; Draw the string
common: MGTK_CALL MGTK::DrawText, text_params
        rts

.params text_params
data:   .addr   entry_string_buf+1
length: .byte   SELF_MODIFIED_BYTE
.endparams
.endproc ; DrawEntryCallback

;;; ============================================================

.proc CmdStartup
        ldy     menu_params::menu_item
        lda     slot_table,y
set:    ora     #>$C000         ; compute $Cn00
        sta     @addr+1
        lda     #<$C000
        sta     @addr

        jsr     RestoreSystem

        @addr := * + 1
        jmp     SELF_MODIFIED
.endproc ; CmdStartup
StartupSlot := CmdStartup::set

;;; ============================================================

;;; Input: A = index
;;; Does not rely on the UI's selected index as this may predate
;;; the UI display.
.proc InvokeEntryImpl
        ptr := $06

invoke_index:
        .byte   SELF_MODIFIED_BYTE

start:
        sta     invoke_index

        ;; --------------------------------------------------
        ;; Set cursor for duration of operation

        bit     invoked_during_boot_flag
    IF NC                       ; skip if there's no UI yet
        jsr     SetCursorWatch  ; before invoking entry
        jsr     rest
        jmp     SetCursorPointer ; after invoking entry
    END_IF
        FALL_THROUGH_TO rest    ; "else"
rest:
        ;; --------------------------------------------------

        jsr     ClearSelectedIndex

        ;; --------------------------------------------------
        ;; Figure out entry path, given entry options and overrides
        bit     invoked_during_boot_flag
    IF NC
        bit     BUTN0           ; if Open-Apple is down, skip RAMCard copy
        jmi     use_entry_path

        ;; Is there a RAMCard at all?
        jsr     GetCopiedToRAMCardFlag
        beq     use_entry_path  ; no RAMCard, skip
    END_IF

        ;; Look at the entry's flags
        CALL    GetSelectorListEntryAddr, A=invoke_index
        stax    ptr
        ldy     #kSelectorEntryFlagsOffset
        lda     (ptr),y
        ASSERT_EQUALS ::kSelectorEntryCopyOnBoot, 0
        beq     on_boot
        cmp     #kSelectorEntryCopyNever
        beq     use_entry_path  ; not copied

        ;; --------------------------------------------------
        ;; `kSelectorEntryCopyOnUse`
        bit     invoked_during_boot_flag
        bmi     use_ramcard_path ; skip if no UI

        CALL    GetEntryCopiedToRAMCardFlag, X=invoke_index
        bmi     use_ramcard_path ; already copied

        ;; Need to copy to RAMCard
        path_addr := $06
        CALL    GetSelectorListPathAddr, A=invoke_index
        jsr     CopyPathToInvokerPrefix

        jsr     LoadOverlayCopyDialog ; Trashes in-memory selector list
        jsr     ::file_copier::Exec
        pha
        jsr     LoadSelectorList
        jsr     CheckAndClearUpdates
        pla
    IF NOT_ZERO
        jmp     ClearSelectedIndex ; canceled!
    END_IF

        CALL    SetEntryCopiedToRAMCardFlag, X=invoke_index, A=#$FF
        jmp     use_ramcard_path

        ;; --------------------------------------------------
        ;; `kSelectorEntryCopyOnBoot`
on_boot:
        bit     invoked_during_boot_flag
    IF NC                       ; skip if no UI
        CALL    GetEntryCopiedToRAMCardFlag, X=invoke_index
        bpl     use_entry_path  ; wasn't copied!
        FALL_THROUGH_TO use_ramcard_path
    END_IF

        ;; --------------------------------------------------
        ;; Copied to RAMCard - use copied path
use_ramcard_path:
        CALL    ComposeRAMCardEntryPath, A=invoke_index
        jmp     LaunchPath

        ;; --------------------------------------------------
        ;; Not copied to RAMCard - just use entry's path
use_entry_path:
        CALL    GetSelectorListPathAddr, A=invoke_index

        FALL_THROUGH_TO LaunchPath
.endproc ; InvokeEntryImpl
InvokeEntry := InvokeEntryImpl::start

;;; ============================================================
;;; Launch specified path (A,X = path)
.proc LaunchPath
        jsr     CopyPathToInvokerPrefix

        ;; --------------------------------------------------
        ;; Set cursor for duration of operation

        bit     invoked_during_boot_flag
    IF NC                       ; skip if there's no UI yet
        jsr     SetCursorWatch  ; before launching path
        jsr     rest
        jmp     SetCursorPointer ; after launching path
    END_IF
        FALL_THROUGH_TO rest    ; "else"
rest:
        ;; --------------------------------------------------

retry:
        CALL    GetFileInfo, AX=#INVOKER_PREFIX
        bcc     check_type

        ;; Not present; maybe show a retry prompt
        tax
        bit     invoked_during_boot_flag
    IF NC
        txa
        pha
        jsr     ShowAlert
        tax
        pla
        cmp     #ERR_VOL_NOT_FOUND
        bne     fail
        txa
        ASSERT_NOT_EQUALS ::kAlertResultCancel, 0
        bne     fail            ; `kAlertResultCancel` = 1
        jmp     retry           ; TODO: `BEQ`
    END_IF

fail:
        jmp     ClearSelectedIndex

        ;; --------------------------------------------------
        ;; Check file type

        ;; Ensure it's BIN, SYS, S16 or BAS (if BS is present)

check_type:
        lda     #0
        sta     INVOKER_INTERPRETER
        sta     INVOKER_BITSY_COMPAT

        lda     file_info_params::file_type
    IF A = #FT_LINK
        jsr     ReadLinkFile
        bcs     err
        bcc     retry
    END_IF

    IF A = #FT_BASIC
        CALL    CheckInterpreter, AX=#str_extras_basic
        bcc     check_path
        jsr     CheckBasicSystem ; try relative to launch path
        beq     check_path

        CALL    ShowAlert, A=#AlertID::basic_system_not_found
        jmp     ClearSelectedIndex
    END_IF

    IF A = #FT_INT
        CALL    CheckInterpreter, AX=#str_extras_intbasic
        bcc     check_path
        jsr     ShowAlert
        jmp     ClearSelectedIndex
    END_IF

    IF A IN #FT_AWP, #FT_ASP, #FT_ADB
        CALL    CheckInterpreter, AX=#str_extras_awlaunch
        bcc     check_path
        jsr     ShowAlert
        jmp     ClearSelectedIndex
    END_IF

        cmp     #FT_BINARY
        beq     check_path
        cmp     #FT_SYSTEM
        beq     check_path
        cmp     #FT_S16
        beq     check_path

        jsr     CheckBasisSystem ; Is fallback BASIS.SYSTEM present?
    IF EQ
        SET_BIT7_FLAG INVOKER_BITSY_COMPAT
        bmi     check_path      ; always
    END_IF

        ;; Don't know how to invoke
err:
        bit     invoked_during_boot_flag
    IF NC
        CALL    ShowAlert, A=#AlertID::selector_unable_to_run
    END_IF
        jmp     ClearSelectedIndex

        ;; --------------------------------------------------
        ;; Check Path

check_path:
        ldy     INVOKER_PREFIX
    DO
        lda     INVOKER_PREFIX,y
        cmp     #'/'
        beq     :+
        dey
    WHILE NOT_ZERO

        CALL    ShowAlert, A=#AlertID::insert_source_disk
        ASSERT_NOT_EQUALS ::kAlertResultCancel, 0
        bne     ClearSelectedIndex ; `kAlertResultCancel` = 1
        jmp     retry

:       dey
        tya
        pha
        iny
        ldx     #0
    DO
        iny
        inx
        copy8   INVOKER_PREFIX,y, INVOKER_FILENAME,x
    WHILE Y <> INVOKER_PREFIX

        stx     INVOKER_FILENAME
        pla
        sta     INVOKER_PREFIX
        CALL    UpcaseString, AX=#INVOKER_PREFIX
        CALL    UpcaseString, AX=#INVOKER_FILENAME
        CALL    UpcaseString, AX=#INVOKER_INTERPRETER

        ;; --------------------------------------------------
        ;; Invoke

        jsr     RestoreSystem

        ;; Reset stack
        ldx     #$FF
        txs

        jmp     INVOKER

.endproc ; LaunchPath

        DEFINE_QUIT_PARAMS quit_params

.proc ClearSelectedIndex
        bit     invoked_during_boot_flag
    IF NC
        copy8   #$FF, op_params::new_selection
        OPTK_CALL OPTK::SetSelection, op_params
        jsr     UpdateOKButton
    END_IF
        rts
.endproc ; ClearSelectedIndex

;;; ============================================================

;;; Copy path to INVOKER_PREFIX
;;; Input: A,X = path
;;; Trashes $06
.proc CopyPathToInvokerPrefix
        ptr := $06

        stax    ptr
        ldy     #$00
        lda     (ptr),y
        tay
    DO
        copy8   (ptr),y, INVOKER_PREFIX,y
        dey
    WHILE POS

        rts
.endproc ; CopyPathToInvokerPrefix

;;; ============================================================

;;; Inputs: `INVOKER_PREFIX` has path to LNK file
;;; Output: C=0, `INVOKER_PREFIX` has target on success
;;;         C=1 on error

.proc ReadLinkFile
        read_buf := $800
        io_buf := $1C00

        MLI_CALL OPEN, open_params
        bcs     err
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        php
        MLI_CALL CLOSE, close_params
        plp
        bcs     err

        lda     read_params::trans_count
        cmp     #kLinkFilePathLengthOffset
        bcc     err

        ldx     #kCheckHeaderLength-1
    DO
        lda     read_buf,x
        cmp     check_header,x
        bne     err
        dex
    WHILE POS

        COPY_STRING read_buf + kLinkFilePathLengthOffset, INVOKER_PREFIX
        RETURN  C=0

err:    RETURN  C=1

check_header:
        .byte   kLinkFileSig1Value, kLinkFileSig2Value, kLinkFileCurrentVersion
        kCheckHeaderLength = * - check_header

        DEFINE_OPEN_PARAMS open_params, INVOKER_PREFIX, io_buf
        DEFINE_READWRITE_PARAMS read_params, read_buf, kLinkFileMaxSize
        DEFINE_CLOSE_PARAMS close_params

.endproc ; ReadLinkFile

;;; ============================================================

kBSOffset       = 5             ; Offset of 'x' in BASIx.SYSTEM
str_basix_system:
        PASCAL_STRING "BASIx.SYSTEM"

;;; --------------------------------------------------
;;; Check `INVOKER_PREFIX`'s ancestors to see if the desired interpreter
;;; (BASIC.SYSTEM or BASIS.SYSTEM) is present.
;;; Input: `INVOKER_PREFIX` set to target path
;;; Output: zero if found, non-zero if not found

.proc CheckBasixSystemImpl
        launch_path := INVOKER_PREFIX
        interp_path := INVOKER_INTERPRETER

        ENTRY_POINTS_FOR_A basic, 'C', basis, 'S'
        ;; "BASI?" -> "BASIC", "BASI?" -> "BASIS"
        sta     str_basix_system + kBSOffset

        ;; Start off with `interp_path` = `launch_path`
        ldx     launch_path
        stx     path_length
    DO
        copy8   launch_path,x, interp_path,x
        dex
    WHILE POS

        ;; Pop off a path segment.
pop_segment:
        path_length := *+1
        ldx     #SELF_MODIFIED_BYTE
    DO
        lda     interp_path,x
        cmp     #'/'
        beq     found_slash
        dex
    WHILE NOT_ZERO

no_bs:  copy8   #0, interp_path ; null out the path
        RETURN  A=#$FF          ; non-zero is failure

found_slash:
        cpx     #1
        beq     no_bs
        stx     interp_path
        dex
        stx     path_length

        ;; Append BASI?.SYSTEM to path and check for file.
        ldx     interp_path
        ldy     #0
    DO
        inx
        iny
        copy8   str_basix_system,y, interp_path,x
    WHILE Y <> str_basix_system
        stx     interp_path
        CALL    GetFileInfo, AX=#interp_path
        bcs     pop_segment

        rts                     ; zero is success
.endproc ; CheckBasixSystemImpl
CheckBasisSystem        := CheckBasixSystemImpl::basis
CheckBasicSystem        := CheckBasixSystemImpl::basic

;;; ============================================================

;;; Input: A,X = relative path to interpreter
;;; Output: `INVOKER_INTERPRETER` is abs path, flags have `GET_FILE_INFO` result
.proc CheckInterpreter
        ptr := $06

        stax    $06
        MLI_CALL GET_PREFIX, get_prefix_params
        ldy     #0
        copy8   (ptr),y, len
        ldx     INVOKER_INTERPRETER
    DO
        iny
        inx
        copy8   (ptr),y, INVOKER_INTERPRETER,x
        len := *+1
        cpy     #SELF_MODIFIED_BYTE
    WHILE NE
        stx     INVOKER_INTERPRETER

        TAIL_CALL GetFileInfo, AX=#INVOKER_INTERPRETER

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, INVOKER_INTERPRETER
.endproc ; CheckInterpreter

;;; ============================================================

;;; Call GET_FILE_INFO on path at A,X; results are in `file_info_params`
;;; Output: MLI result (carry/zero flag, etc)
.proc GetFileInfo
        stax    file_info_params::pathname
        MLI_CALL GET_FILE_INFO, file_info_params
        rts
.endproc ; GetFileInfo

;;; ============================================================
;;; Uppercase a string
;;; Input: A,X = Address

.proc UpcaseString
        ptr := $06

        stax    ptr
        ldy     #$00
        lda     (ptr),y
    IF NOT_ZERO
        tay
      DO
        lda     (ptr),y
        jsr     ToUpperCase
        sta     (ptr),y
        dey
      WHILE NOT_ZERO
    END_IF
        rts
.endproc ; UpcaseString

;;; ============================================================

str_extras_basic:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/BASIC.system")
str_extras_intbasic:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/IntBASIC.system")
str_extras_awlaunch:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/AWLaunch.system")

;;; ============================================================

        .include "../lib/uppercase.s"
        .include "../lib/ramcard.s"

;;; ============================================================

.proc ComposeRAMCardEntryPath
        buf := $800

        sta     tmp
        CALL    CopyRAMCardPrefix, AX=#buf

        CALL    GetSelectorListPathAddr, A=tmp

        path_addr := $06

        stax    path_addr
        ldy     #0
        copy8   (path_addr),y, len
        tay
    DO
        lda     (path_addr),y
        BREAK_IF A = #'/'
        dey
    WHILE NOT_ZERO

        dey
    DO
        lda     (path_addr),y
        BREAK_IF A = #'/'
        dey
    WHILE NOT_ZERO

        dey
        ldx     buf
    DO
        inx
        iny
        copy8   (path_addr),y, buf,x
    WHILE Y <> len

        stx     buf
        RETURN  AX=#buf


tmp:    .byte   0
len:    .byte   0
.endproc ; ComposeRAMCardEntryPath

;;; ============================================================
;;; Show Alert Message
;;; Input: A = AlertID

.proc ShowAlert
        tax
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1
        txa
        jsr     AlertById
        tax
        sta     ALTZPOFF
        bit     ROMIN2
        txa
        rts
.endproc ; ShowAlert

;;; Alert code calls here to yield; swaps memory banks back in
;;; to do things like read the ProDOS clock.
.proc SystemTaskFromLC
        sta     ALTZPOFF
        bit     ROMIN2
        jsr     SystemTask
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1
        rts
.endproc ; SystemTaskFromLC

;;; ============================================================
;;; Called by main and nested event loops to do periodic tasks.
;;; Returns 0 if the periodic tasks were run.

.proc SystemTask
        kMaxCounter = $E0       ; arbitrary

        inc     loop_counter
        inc     loop_counter
        lda     loop_counter
    IF A >= #kMaxCounter
        copy8   #0, loop_counter

        jsr     ShowClock
        jsr     ResetIIgsRGB    ; in case it was reset by control panel
    END_IF

        RETURN  A=loop_counter

loop_counter:
        .byte   0
.endproc ; SystemTask

;;; ============================================================

        .include "../lib/menuclock.s"
        .include "../lib/datetime.s"
        .include "../lib/doubleclick.s"

        .include "../lib/speed.s"
        .include "../lib/bell.s"
        .include "../lib/clear_dhr.s"
        saved_ram_buffer := $1C00
        .include "../lib/disconnect_ram.s"
        .include "../lib/reconnect_ram.s"
        .include "../lib/readwrite_settings.s"
        .include "../lib/monocolor.s"

        ADJUSTCASE_BLOCK_BUFFER := $1C00
        .include "../lib/adjustfilecase.s"

        ;; TODO: Move these out of the `app` scope
        .include "../toolkits/btk.s"
        BTKEntry := btk::BTKEntry

        .include "../toolkits/lbtk.s"
        LBTKEntry := lbtk::LBTKEntry

        .include "../toolkits/optk.s"
        OPTKEntry := optk::OPTKEntry

;;; ============================================================

.endscope ; app

        ENDSEG SegmentApp
        ASSERT_ADDRESS OVERLAY_ADDR
