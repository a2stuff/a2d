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

        PAD_TO ::FONT
        .incbin .concat("../mgtk/fonts/System.", kBuildLang)

;;; ============================================================
;;; Generic Resources (outside scope for convenience)

pencopy:        .byte   MGTK::pencopy
penOR:          .byte   MGTK::penOR
penXOR:         .byte   MGTK::penXOR
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy
notpenOR:       .byte   MGTK::notpenOR
notpenXOR:      .byte   MGTK::notpenXOR
notpenBIC:      .byte   MGTK::notpenBIC

;;; ============================================================
;;; Event Params (and overlapping param structs)

        .include "../lib/event_params.s"

;;; ============================================================

.scope app

;;; See docs/Selector_List_Format.md for file format
selector_list   := $B300

kShortcutRunDeskTop = res_char_button_desktop_shortcut
kShortcutRunProgram = res_char_menu_item_run_a_program_shortcut

;;; ============================================================
;;; Resources

saved_stack:
        .byte   $00

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

menu:   DEFINE_MENU_BAR 3
        DEFINE_MENU_BAR_ITEM 1, str_apple, apple_menu
        DEFINE_MENU_BAR_ITEM 2, str_file, file_menu
        DEFINE_MENU_BAR_ITEM 3, str_startup, startup_menu

apple_menu:
        DEFINE_MENU 5
        DEFINE_MENU_ITEM str_a2desktop
        DEFINE_MENU_ITEM str_blank
        DEFINE_MENU_ITEM str_copyright1
        DEFINE_MENU_ITEM str_copyright2
        DEFINE_MENU_ITEM str_copyright3

file_menu:
        DEFINE_MENU 1
        DEFINE_MENU_ITEM str_run_a_program, res_char_menu_item_run_a_program_shortcut

startup_menu:
        DEFINE_MENU 1

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
        PASCAL_STRING res_string_menu_bar_item_file    ; menu bar item
str_startup:
        PASCAL_STRING res_string_menu_bar_item_startup ; menu bar item

str_a2desktop:
        PASCAL_STRING .sprintf(res_string_version_format_long, kDeskTopProductName, ::kDeskTopVersionMajor, ::kDeskTopVersionMinor, kDeskTopVersionSuffix)

str_blank:
        PASCAL_STRING " "
str_copyright1:
        PASCAL_STRING res_string_copyright_line1 ; menu item
str_copyright2:
        PASCAL_STRING res_string_copyright_line2 ; menu item
str_copyright3:
        PASCAL_STRING res_string_copyright_line3 ; menu item

str_run_a_program:
        PASCAL_STRING res_string_menu_item_run_a_program ; menu item


str_slot_x1:
        PASCAL_STRING res_string_menu_item_slot_pattern  ; menu item
str_slot_x2:
        PASCAL_STRING res_string_menu_item_slot_pattern  ; menu item
str_slot_x3:
        PASCAL_STRING res_string_menu_item_slot_pattern  ; menu item
str_slot_x4:
        PASCAL_STRING res_string_menu_item_slot_pattern  ; menu item
str_slot_x5:
        PASCAL_STRING res_string_menu_item_slot_pattern  ; menu item
str_slot_x6:
        PASCAL_STRING res_string_menu_item_slot_pattern  ; menu item
str_slot_x7:
        PASCAL_STRING res_string_menu_item_slot_pattern  ; menu item
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

;;; ============================================================
;;; Application entry point

        PAD_TO ::START
        jmp     entry

;;; ============================================================

.params getwinport_params
window_id:     .byte   0
a_grafport:    .addr   grafport_win
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
colormasks:     .byte   $FF, 0
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   $7F
textfont:       .word   FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        DEFINE_RECT_FRAME rect_frame, winfo::kWidth, winfo::kHeight

        DEFINE_BUTTON ok_button_rec,      winfo::kDialogId, res_string_button_ok, kGlyphReturn, winfo::kWidth - kButtonWidth - 60, winfo::kHeight - 18
        DEFINE_BUTTON_PARAMS ok_button_params, ok_button_rec
        DEFINE_BUTTON desktop_button_rec, winfo::kDialogId, res_string_button_desktop, res_char_button_desktop_shortcut,       60, winfo::kHeight - 18
        DEFINE_BUTTON_PARAMS desktop_button_params, desktop_button_rec

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY

        DEFINE_POINT pos_title_string, 0, 16

str_selector_title:
        PASCAL_STRING res_string_selector_name

        ;; Options control metrics
        kEntryPickerCols = 3
        kEntryPickerRows = 8
        kEntryPickerRowShift = 3 ; log2(kEntryPickerRows)
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

        ;; Used when rendering entries
        DEFINE_RECT entry_picker_item_rect, 0, 0, 0, 0

        io_buf_sl = $BB00

        DEFINE_OPEN_PARAMS open_selector_list_params, str_selector_list, io_buf_sl
        DEFINE_READ_PARAMS read_selector_list_params, selector_list, kSelectorListBufSize

        io_buf_desktop = $1C00
        desktop_load_addr = $2000
        kDeskTopLoadSize = $400

        DEFINE_OPEN_PARAMS open_desktop_params, str_desktop, io_buf_desktop
        DEFINE_READ_PARAMS read_desktop_params, desktop_load_addr, kDeskTopLoadSize

str_selector_list:
        PASCAL_STRING kPathnameSelectorList

str_desktop:
        PASCAL_STRING kPathnameDeskTop

        DEFINE_CLOSE_PARAMS close_params

        DEFINE_OPEN_PARAMS open_selector_params, str_selector, $800

str_selector:
        PASCAL_STRING kPathnameSelector

        DEFINE_SET_MARK_PARAMS set_mark_overlay1_params, kOverlayFileDialogOffset
        DEFINE_SET_MARK_PARAMS set_mark_overlay2_params, kOverlayCopyDialogOffset
        DEFINE_READ_PARAMS read_overlay1_params, OVERLAY_ADDR, kOverlayFileDialogLength
        DEFINE_READ_PARAMS read_overlay2_params, OVERLAY_ADDR, kOverlayCopyDialogLength
        DEFINE_CLOSE_PARAMS close_params2

str_desktop_2:
        PASCAL_STRING kPathnameDeskTop

desktop_available_flag:
        .byte   0

        DEFINE_GET_FILE_INFO_PARAMS file_info_params, SELF_MODIFIED

;;; Index of selected entry, or $FF if none
selected_index:
        .byte   0

entry_string_buf:
        .res    20

num_primary_run_list_entries:
        .byte   0
num_secondary_run_list_entries:
        .byte   0

invoked_during_boot_flag:       ; set to 1 during key checks during boot, 0 otherwise
        .byte   0

is_iigs_flag:                   ; high bit set if IIgs
        .byte   0

is_iiecard_flag:                ; high bit set if Mac IIe Option Card
        .byte   0

is_laser128_flag:               ; high bit set if Laser 128
        .byte   0

lcm_eve_flag:                   ; high bit set if Le Chat Mauve Eve present
        .byte   0

;;; ============================================================
;;; Clock Resources

        DEFINE_POINT pos_clock, kScreenWidth - 11, 10

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
        .tag ParsedDateTime

;;; GrafPort used when drawing the clock
clock_grafport:
        .tag MGTK::GrafPort

;;; Used to save the current GrafPort while drawing the clock.
.params getport_params
portptr:        .addr   0
.endparams

;;; ============================================================
;;; App Initialization

entry:
.proc AppInit
        ;; Detect IIgs
        sec
        jsr     IDROUTINE       ; clear C if IIgs
    IF_CC
        copy    #$80, is_iigs_flag
    END_IF

        ;; Detect Mac IIe Option Card
        lda     ZIDBYTE
        cmp     #$E0            ; Is Enhanced IIe?
        bne     :+
        lda     IDBYTEMACIIE
        cmp     #$02            ; Mac IIe Option Card signature
        bne     :+
        copy    #$80, is_iiecard_flag
:
        ;; Detect Laser 128
        lda     IDBYTELASER128
        cmp     #$AC
    IF_EQ
        copy    #$80, is_laser128_flag
    END_IF

        jsr     DetectLeChatMauveEve
        beq     :+              ; Z=1 means no LCMEve
        copy    #$80, lcm_eve_flag
:

        copy    #$FF, selected_index
        copy    #$80, ok_button_rec::state
        jsr     LoadSelectorList
        copy    #1, invoked_during_boot_flag
        lda     num_secondary_run_list_entries
        ora     num_primary_run_list_entries
        bne     check_key_down

quick_run_desktop:
        param_call GetFileInfo, str_desktop_2
        beq     :+
        jmp     done_keys
:       jmp     RunDesktop

        ;; --------------------------------------------------
        ;; Check for key down

check_key_down:
        lda     #0
        sta     quick_boot_slot

        lda     KBD
        bpl     done_keys
        sta     KBDSTRB
        and     #CHAR_MASK
        bit     BUTN0           ; Open Apple?
        bmi     :+
        bit     BUTN1           ; Solid Apple?
        bpl     check_key
:       cmp     #'1'            ; Solid Apple + 1...7 = boot slot
        bcc     check_key
        cmp     #'8'
        bcs     check_key
        sec
        sbc     #$30            ; ASCII to number
        sta     quick_boot_slot
        jmp     done_keys

check_key:
        cmp     #kShortcutRunDeskTop ; If Q is down, try launching DeskTop
        beq     quick_run_desktop
        cmp     #TO_LOWER(kShortcutRunDeskTop)
        beq     quick_run_desktop

        sec
        sbc     #'1'            ; 1-8 run that selector entry
        bmi     done_keys
        cmp     num_primary_run_list_entries
        bcs     done_keys
        sta     selected_index
        jsr     GetSelectorListEntryAddr

        entry_ptr := $06

        ;; TODO: See if we can skip this and just `InvokeEntry`
        stax    entry_ptr
        ldy     #kSelectorEntryFlagsOffset
        lda     (entry_ptr),y
        cmp     #kSelectorEntryCopyNever
    IF_NE
        jsr     GetCopiedToRAMCardFlag
        beq     done_keys       ; no RAMCard, skip
        ldx     selected_index
        jsr     GetEntryCopiedToRAMCardFlag
        bpl     done_keys       ; wasn't copied!
    END_IF
        lda     selected_index
        jsr     InvokeEntry

        ;; --------------------------------------------------

done_keys:
        sta     KBDSTRB
        copy    #0, invoked_during_boot_flag

        ;; --------------------------------------------------

        jsr     SaveAndAdjustDeviceList
        jsr     DisconnectRAM

        ;; --------------------------------------------------
        ;; Find slots with devices using ProDOS Device ID Bytes
.scope
        slot_ptr := $06         ; pointed at $Cn00

        lda     #0
        sta     slot_ptr
        ldx     #7              ; slot

loop:   txa
        ora     #$C0            ; hi byte of $Cn00
        sta     slot_ptr+1

        ldy     #$01        ; $Cn01 == $20 ?
        lda     (slot_ptr),y
        cmp     #$20
        bne     next

        ldy     #$03        ; $Cn03 == $00 ?
        lda     (slot_ptr),y
        cmp     #$00
        bne     next

        ldy     #$05        ; $Cn05 == $03 ?
        lda     (slot_ptr),y
        cmp     #$03
        bne     next

        ;; Match! Add to slot_table
        inc     slot_table
        ldy     slot_table
        txa
        sta     slot_table,y

next:   dex
        bne     loop
.endscope

        ;; --------------------------------------------------
        ;; Set up Startup menu

        lda     quick_boot_slot
        beq     set_startup_menu_items
        ldy     slot_table
L91FA:  cmp     slot_table,y
        beq     L9205
        dey
        bne     L91FA
        jmp     set_startup_menu_items

L9205:  ora     #$C0
        sta     @addr+1
        @addr := *+1
        jmp     $C000           ; High byte is self-modified

set_startup_menu_items:
        lda     slot_table
        sta     startup_menu

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
:       jsr     ReadSetting
        sta     tmp_pattern - DeskTopSettings::pattern,x
        dex
        cpx     #AS_BYTE(DeskTopSettings::pattern-1)
        bne     :-

        MGTK_CALL MGTK::SetDeskPat, tmp_pattern

        copy    VERSION, startdesktop_params::machine
        copy    ZIDBYTE, startdesktop_params::subid

        jsr     ClearDHRToBlack

        MGTK_CALL MGTK::SetZP1, setzp_params
        MGTK_CALL MGTK::StartDeskTop, startdesktop_params
        copy    #$80, desktop_started_flag
        jsr     SetRGBMode
        MGTK_CALL MGTK::SetMenu, menu
        jsr     ShowClock
        MGTK_CALL MGTK::ShowCursor
        MGTK_CALL MGTK::FlushEvents

        lda     startdesktop_params::slot_num
    IF_ZERO
        ldx     #DeskTopSettings::options
        jsr     ReadSetting
        ora     #DeskTopSettings::kOptionsShowShortcuts
        jsr     WriteSetting
    END_IF

        ;; --------------------------------------------------
        ;; Cursor tracking

        ;; Doubled if option selected
        ldx     #DeskTopSettings::mouse_tracking
        jsr     ReadSetting
    IF_NOT_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
    END_IF
        ;; Also doubled if a IIc
        lda     ZIDBYTE         ; ZIDBYTE=0 for IIc / IIc+
    IF_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
    END_IF
        MGTK_CALL MGTK::ScaleMouse, scalemouse_params
        ;; --------------------------------------------------

        ;; Is DeskTop available?
        param_call GetFileInfo, str_desktop_2
        beq     :+
        lda     #$80
:       sta     desktop_available_flag

        ;; --------------------------------------------------
        ;; Open the window

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     GetPortAndDrawWindow
        copy    #$FF, selected_index
        copy    #$80, ok_button_rec::state
        jsr     LoadSelectorList
        jsr     PopulateEntriesFlagTable
        jsr     DrawEntries
        jmp     EventLoop

quick_boot_slot:
        .byte   0
.endproc ; AppInit

;;; ============================================================
;;; Event Loop

.proc EventLoop
        jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     HandleButtonDown
        jmp     EventLoop

:       cmp     #MGTK::EventKind::key_down
        bne     not_key

        ;; --------------------------------------------------
        ;; Key Down

        bit     desktop_available_flag
        bmi     not_desktop
        lda     event_params::key
        cmp     #kShortcutRunDeskTop
        beq     :+
        cmp     #TO_LOWER(kShortcutRunDeskTop)
        bne     not_desktop

:       BTK_CALL BTK::Flash, desktop_button_params
@retry: param_call GetFileInfo, str_desktop_2
        beq     :+
        lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     EventLoop       ; `kAlertResultCancel` = 1
        beq     @retry          ; `kAlertResultTryAgain` = 0
:       jmp     RunDesktop

not_desktop:
        jsr     HandleKey
        jmp     EventLoop

        ;; --------------------------------------------------

not_key:
        cmp     #MGTK::EventKind::update
        bne     not_update
        jsr     ClearUpdates

not_update:
        jmp     EventLoop
.endproc ; EventLoop

;;; ============================================================
;;; Handle update events

CheckAndClearUpdates:
        MGTK_CALL MGTK::PeekEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::update
        bne     done
        MGTK_CALL MGTK::GetEvent, event_params
        FALL_THROUGH_TO ClearUpdates

ClearUpdates:
        jsr     @do_update
        jmp     CheckAndClearUpdates

@do_update:
        lda     event_params::window_id
        cmp     #winfo::kDialogId
        bne     done

        MGTK_CALL MGTK::BeginUpdate, beginupdate_params
        bne     done            ; obscured
        lda     #$80
        sta     ok_button_params::update
        sta     desktop_button_params::update
        jsr     DrawWindowAndEntries
        lda     #$00
        sta     ok_button_params::update
        sta     desktop_button_params::update
        MGTK_CALL MGTK::EndUpdate
done:   rts

;;; ============================================================

.proc DrawWindowAndEntries
        jsr     DrawWindow
        jmp     DrawEntries
.endproc ; DrawWindowAndEntries

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

.scope option_picker
kOptionPickerRows = kEntryPickerRows
kOptionPickerCols = kEntryPickerCols
kOptionPickerItemWidth = kEntryPickerItemWidth
kOptionPickerItemHeight = kEntryPickerItemHeight
kOptionPickerLeft = kEntryPickerLeft
kOptionPickerTop = kEntryPickerTop
kOptionPickerRowShift = app::kEntryPickerRowShift
option_picker_item_rect := entry_picker_item_rect

        .include "../lib/option_picker.s"
.endscope ; option_picker

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
        cmp     #CHAR_ESCAPE
        beq     menukey
        cmp     #kShortcutRunProgram
        beq     menukey
        cmp     #TO_LOWER(kShortcutRunProgram)
        beq     menukey
        cmp     #'9'+1
        bcs     other
        cmp     #'1'
        bcc     other

menukey:
        sta     menu_params::which_key
        lda     event_params::modifiers
        sta     menu_params::key_mods
        MGTK_CALL MGTK::MenuKey, menu_params::menu_id
        FALL_THROUGH_TO HandleMenu
.endproc ; HandleKey

;;; ==================================================

.proc HandleMenu
        ldx     menu_params::menu_item
        beq     L93BE
        ldx     menu_params::menu_id
        bne     L93C1
L93BE:  jmp     EventLoop

L93C1:  dex
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
        jsr     L93EB
        MGTK_CALL MGTK::HiliteMenu, menu_params
        rts

L93EB:  tsx
        stx     saved_stack

        addr := *+1
        jmp     SELF_MODIFIED
.endproc ; HandleMenu

;;; ============================================================

.proc CmdRunAProgram
        lda     #$FF
        jsr     option_picker::SetOptionPickerSelection
        jsr     UpdateOKButton
retry:
        jsr     SetCursorWatch
        MLI_CALL OPEN, open_selector_params
        bne     L9443
        lda     open_selector_params::ref_num
        sta     set_mark_overlay1_params::ref_num
        sta     read_overlay1_params::ref_num
        MLI_CALL SET_MARK, set_mark_overlay1_params
        MLI_CALL READ, read_overlay1_params
        MLI_CALL CLOSE, close_params2
        jsr     file_dialog_init
        bne     L943F
L9436:  tya
        jsr     invoke_entry_ep2
        jsr     file_dialog_loop
        beq     L9436
L943F:  jmp     LoadSelectorList

L9443:  lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     retry           ; `kAlertResultTryAgain` = 0
        rts
.endproc ; CmdRunAProgram

;;; ============================================================

.proc HandleButtonDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        bne     :+
        rts

:       cmp     #MGTK::Area::menubar
        bne     :+
        MGTK_CALL MGTK::MenuSelect, menu_params
        jmp     HandleMenu

:       cmp     #MGTK::Area::content
        beq     :+
        rts

:       lda     findwindow_params::window_id
        cmp     #winfo::kDialogId
        beq     :+
        rts

:       lda     #winfo::kDialogId
        jsr     GetWindowPort
        lda     #winfo::kDialogId
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; OK button?

        MGTK_CALL MGTK::InRect, ok_button_rec::rect
        cmp     #MGTK::inrect_inside
        bne     check_desktop_btn
        bit     ok_button_rec::state
        bmi     done
        BTK_CALL BTK::Track, ok_button_params
        bmi     done
        jsr     TryInvokeSelectedIndex
done:   rts

        ;; DeskTop button?

check_desktop_btn:
        bit     desktop_available_flag
        bmi     check_entries
        MGTK_CALL MGTK::InRect, desktop_button_rec::rect
        cmp     #MGTK::inrect_inside
        bne     check_entries

        BTK_CALL BTK::Track, desktop_button_params
        bmi     done

@retry: param_call GetFileInfo, str_desktop_2
        beq     :+
        lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     done            ; `kAlertResultCancel` = 1
        beq     @retry          ; `kAlertResultTryAgain` = 0
:       jmp     RunDesktop

        ;; Entry selection?

check_entries:
        jsr     option_picker::HandleOptionPickerClick
        php
        jsr     UpdateOKButton
        plp
        bmi     ret
        jsr     DetectDoubleClick
    IF_NC
        BTK_CALL BTK::Flash, ok_button_params
        jmp     InvokeEntry
    END_IF
ret:    rts
.endproc ; HandleButtonDown

;;; ============================================================

.proc UpdateOKButton
        lda     #0
        bit     selected_index
        bpl     :+
        lda     #$80
:       cmp     ok_button_rec::state
        beq     :+
        sta     ok_button_rec::state
        BTK_CALL BTK::Hilite, ok_button_params
:       rts

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
        MLI_CALL CLOSE, close_params
        jmp     desktop_load_addr
.endproc ; RunDesktop

;;; ============================================================
;;; Assert: ROM banked in, ALTZP/LC is OFF

.proc RestoreSystem
        bit     desktop_started_flag
    IF_NS
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
        lda     #0              ; INIT is not used as that briefly
        sta     WNDLFT          ; displays the dirty text page
        sta     WNDTOP
        lda     #80
        sta     WNDWDTH
        lda     #24
        sta     WNDBTM
        jsr     HOME            ; Clear 80-col screen

        lda     #$11            ; Ctrl-Q - disable 80-col firmware
        jsr     COUT

        ;; Switch back to color DHR mode
        jsr     SetColorMode

        sta     DHIRESOFF
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR

        jsr     SETVID          ; after TXTSET so WNDTOP is set properly
        jsr     SETKBD

        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80STORE

        rts
.endproc ; RestoreTextMode

;;; ============================================================

;;; Input: A = index
;;; Output: A unchanged, Z=1 if valid, Z=0 if not valid
.proc IsIndexValid
        tay
        ldx     entries_flag_table,y
        rts
.endproc ; IsIndexValid

;;; ============================================================

.proc HandleNonmenuKey

        lda     #winfo::kDialogId
        jsr     GetWindowPort
        lda     event_params::key
        cmp     #$1C            ; Control character?
        bcs     :+
        jmp     control_char

        ;; --------------------------------------------------

        ;; 1-8 to select entry

:       cmp     #'1'
        bcs     :+
        rts

:       cmp     #'9'
        bcc     :+
        rts

:       sec
        sbc     #'1'
        cmp     num_primary_run_list_entries
        bcc     :+
        rts

:       jsr     option_picker::SetOptionPickerSelection
        jmp     UpdateOKButton

        ;; --------------------------------------------------
        ;; Control characters - return and arrows

        ;; Return ?

control_char:
        cmp     #CHAR_RETURN
        bne     not_return
        BTK_CALL BTK::Flash, ok_button_params
        jmp     TryInvokeSelectedIndex
not_return:

        ;; --------------------------------------------------
        ;; Arrow keys?

        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
    IF_NE
        lda     event_params::key
        jsr     option_picker::IsOptionPickerKey
      IF_EQ
        jsr     option_picker::HandleOptionPickerKey
        jmp     UpdateOKButton
      END_IF
    END_IF

        rts

.endproc ; HandleNonmenuKey

;;; ============================================================

.proc PopulateEntriesFlagTable
        ldx     #kSelectorListNumEntries - 1
        lda     #$FF
:       sta     entries_flag_table,x
        dex
        bpl     :-

        ldx     #0
:       cpx     num_primary_run_list_entries
        beq     :+
        txa
        sta     entries_flag_table,x
        inx
        bne     :-

:       ldx     #0
:       cpx     num_secondary_run_list_entries
        beq     :+
        txa
        clc
        adc     #8
        sta     entries_flag_table+8,x
        inx
        bne     :-
:       rts
.endproc ; PopulateEntriesFlagTable

;;; Table for 24 entries; index (0...23) if in use, $FF if empty
entries_flag_table:
        .res    ::kSelectorListNumEntries, 0

;;; ============================================================

.proc TryInvokeSelectedIndex
        lda     selected_index
        bmi     :+
        jsr     InvokeEntry
:       rts
.endproc ; TryInvokeSelectedIndex

;;; ============================================================

.proc DrawEntries

        ;; Primary Run List
        lda     #0
        sta     count
:       lda     count
        cmp     num_primary_run_list_entries
        beq     :+
        jsr     DrawListEntry
        inc     count
        jmp     :-

        ;; Secondary Run List
:       lda     #0
        sta     count
:       lda     count
        cmp     num_secondary_run_list_entries
        beq     done
        clc
        adc     #8
        jsr     DrawListEntry
        inc     count
        jmp     :-

done:   rts

count:  .byte   0
.endproc ; DrawEntries

;;; ============================================================

.proc LoadSelectorList
        ;; Initialize the counts, in case load fails.
        lda     #0
        sta     selector_list + kSelectorListNumPrimaryRunListOffset
        sta     selector_list + kSelectorListNumSecondaryRunListOffset

        MLI_CALL OPEN, open_selector_list_params
        bne     cache

        lda     open_selector_list_params::ref_num
        sta     read_selector_list_params::ref_num
        MLI_CALL READ, read_selector_list_params
        MLI_CALL CLOSE, close_params

cache:  copy    selector_list + kSelectorListNumPrimaryRunListOffset, num_primary_run_list_entries
        copy    selector_list + kSelectorListNumSecondaryRunListOffset, num_secondary_run_list_entries
        rts
.endproc ; LoadSelectorList

;;; ============================================================

.proc LoadOverlayCopyDialog
start:  MLI_CALL OPEN, open_selector_params
        bne     error
        lda     open_selector_params::ref_num
        sta     set_mark_overlay2_params::ref_num
        sta     read_overlay2_params::ref_num
        MLI_CALL SET_MARK, set_mark_overlay2_params
        MLI_CALL READ, read_overlay2_params
        MLI_CALL CLOSE, close_params2
        rts

error:  lda     #AlertID::insert_system_disk
        jsr     ShowAlert       ; `kAlertResultCancel` = 1
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
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
:       copy    DEVCNT,x, backup_devlst,x
        dex
        bpl     :-

        ;; Find the startup volume's unit number
        copy    DEVNUM, target
        jsr     GetCopiedToRAMCardFlag
    IF_MINUS
        param_call CopyDeskTopOriginalPrefix, INVOKER_PREFIX
        param_call GetFileInfo, INVOKER_PREFIX
        bcs     :+
        copy    DEVNUM, target
:
    END_IF

        ;; Find the device's index in the list
        ldx     #0
:       lda     DEVLST,x
        and     #UNIT_NUM_MASK  ; to compare against DEVNUM
        target := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     found
        inx
        cpx     DEVCNT
        bcc     :-
        bcs     done            ; last one or not found

        ;; Save it
found:  ldy     DEVLST,x

        ;; Move everything up
:       lda     DEVLST+1,x
        sta     DEVLST,x
        inx
        cpx     DEVCNT
        bne     :-

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
:       copy    backup_devlst,x, DEVCNT,x
        dex
        bpl     :-

ret:    rts
.endproc ; RestoreDeviceList

backup_devlst:
        .byte   $FF             ; backup for DEVCNT (w/ high bit set)
        .res    14, 0           ; backup for DEVLST (7 slots * 2 drives)

;;; ============================================================

.proc GetPortAndDrawWindow
        lda     #winfo::kDialogId
        jsr     GetWindowPort
        FALL_THROUGH_TO DrawWindow
.endproc ; GetPortAndDrawWindow

.proc DrawWindow
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, rect_frame

        MGTK_CALL MGTK::SetPenSize, pensize_normal
        param_call DrawTitleString, str_selector_title

        BTK_CALL BTK::Draw, ok_button_params
        bit     desktop_available_flag
    IF_NC
        BTK_CALL BTK::Draw, desktop_button_params
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

        sub16   #winfo::kWidth, text_width, pos_title_string::xcoord
        lsr16   pos_title_string::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, pos_title_string
        MGTK_CALL MGTK::DrawText, text_params
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

hi:    .byte   0
.endproc ; GetSelectorListPathAddr

;;; ============================================================
;;; Input: A = entry number

.proc DrawListEntry
        ptr := $06

        pha
        jsr     GetSelectorListEntryAddr
        stax    ptr
        ldy     #0
        lda     (ptr),y         ; length

        ;; Copy string into buffer
        tay
:       lda     (ptr),y
        sta     entry_string_buf+3,y
        dey
        bne     :-

        ;; Increase length by 3
        ldy     #0
        lda     (ptr),y
        clc
        adc     #3
        sta     entry_string_buf

        pla
        pha
        cmp     #8              ; first 8?
        bcc     prefix

        ;; Prefix with spaces
        lda     #' '
        sta     entry_string_buf+1
        sta     entry_string_buf+2
        sta     entry_string_buf+3
        jmp     common

        ;; Prefix with number
prefix: pla
        pha
        clc
        adc     #'1'
        sta     entry_string_buf+1
        lda     #' '
        sta     entry_string_buf+2
        sta     entry_string_buf+3

        ;; Draw the string
common: lda     #winfo::kDialogId
        jsr     GetWindowPort
        pla
        jsr     option_picker::GetOptionPos
        addax   #kEntryPickerTextHOffset, entry_picker_item_rect::x1
        tya
        ldx     #0
        addax   #kEntryPickerTextVOffset, entry_picker_item_rect::y1
        MGTK_CALL MGTK::MoveTo, entry_picker_item_rect::topleft
        param_call DrawString, entry_string_buf
        rts
.endproc ; DrawListEntry

;;; ============================================================

.proc CmdStartup
        ldy     menu_params::menu_item
        lda     slot_table,y
        ora     #>$C000         ; compute $Cn00
        sta     @addr+1
        lda     #<$C000
        sta     @addr

        jsr     RestoreSystem

        @addr := * + 1
        jmp     SELF_MODIFIED
.endproc ; CmdStartup

;;; ============================================================

.proc InvokeEntry
        ptr := $06

        lda     invoked_during_boot_flag
        bne     :+              ; skip if there's no UI yet
        jsr     SetCursorWatch
        lda     selected_index
        pha
        lda     #$FF            ; clear hilite
        jsr     option_picker::SetOptionPickerSelection
        jsr     UpdateOKButton
        pla
        sta     selected_index  ; needed below; will be cleared on failure
:       jmp     try

        ;; TODO: Untangle this entry point
ep2:    jmp     launch

try:    lda     invoked_during_boot_flag
        bne     check_entry_flags
        bit     BUTN0           ; if Open-Apple is down, skip RAMCard copy
        bpl     :+
        jmp     use_entry_path
:
        ;; Is there a RAMCard at all?
        jsr     GetCopiedToRAMCardFlag
        beq     use_entry_path  ; no RAMCard, skip

        ;; Look at the entry's flags
check_entry_flags:
        lda     selected_index
        jsr     GetSelectorListEntryAddr
        stax    ptr
        ldy     #kSelectorEntryFlagsOffset
        lda     (ptr),y
        .assert kSelectorEntryCopyOnBoot = 0, error, "enum mismatch"
        beq     on_boot
        cmp     #kSelectorEntryCopyNever
        beq     use_entry_path  ; not copied

        ;; --------------------------------------------------
        ;; `kSelectorEntryCopyOnUse`
        lda     invoked_during_boot_flag
        bne     use_ramcard_path ; skip if no UI

        ldx     selected_index
        jsr     GetEntryCopiedToRAMCardFlag
        bmi     use_ramcard_path ; already copied

        ;; Need to copy to RAMCard
        jsr     LoadOverlayCopyDialog
        lda     selected_index
        jsr     file_copier__Exec
        pha
        jsr     CheckAndClearUpdates
        pla
    IF_NOT_ZERO
        jsr     SetCursorPointer
        jmp     ClearSelectedIndex ; canceled!
    END_IF

        ldx     selected_index
        lda     #$FF
        jsr     SetEntryCopiedToRAMCardFlag
        jmp     use_ramcard_path

        ;; --------------------------------------------------
        ;; `kSelectorEntryCopyOnBoot`
on_boot:
        lda     invoked_during_boot_flag
        bne     use_ramcard_path         ; skip if no UI

        ldx     selected_index
        jsr     GetEntryCopiedToRAMCardFlag
        bpl     use_entry_path  ; wasn't copied!
        FALL_THROUGH_TO use_ramcard_path

        ;; --------------------------------------------------
        ;; Copied to RAMCard - use copied path
use_ramcard_path:
        lda     selected_index
        jsr     ComposeRAMCardEntryPath
        jmp     launch

        ;; --------------------------------------------------
        ;; Not copied to RAMCard - just use entry's path
use_entry_path:
        lda     selected_index
        jsr     GetSelectorListPathAddr


        ;; --------------------------------------------------
        ;; Launch specified path (A,X = path)
launch:

        ;; Copy path to INVOKER_PREFIX
        stax    ptr
        ldy     #$00
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     INVOKER_PREFIX,y
        dey
        bpl     :-
        param_call GetFileInfo, INVOKER_PREFIX
        beq     check_type

        ;; Not present; maybe show a retry prompt
        tax
        lda     invoked_during_boot_flag
        bne     fail
        txa
        pha
        jsr     ShowAlert
        tax
        pla
        cmp     #ERR_VOL_NOT_FOUND
        bne     fail
        txa
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     fail            ; `kAlertResultCancel` = 1
        jsr     SetCursorWatch
        jmp     use_entry_path

fail:   jmp     ClearSelectedIndex

        ;; --------------------------------------------------
        ;; Check file type

        ;; Ensure it's BIN, SYS, S16 or BAS (if BS is present)

check_type:
        lda     file_info_params::file_type
        cmp     #FT_BASIC
        bne     not_basic
        jsr     CheckBasicSystem
        jeq     check_path

        lda     #AlertID::basic_system_not_found
        jsr     ShowAlert
        jmp     ClearSelectedIndex

not_basic:
        cmp     #FT_BINARY
        beq     check_path
        cmp     #FT_SYSTEM
        beq     check_path
        cmp     #FT_S16
        beq     check_path

        jsr     CheckBasisSystem ; Is fallback BASIS.SYSTEM present?
        beq     check_path

        ;; Don't know how to invoke
        lda     #AlertID::selector_unable_to_run
        jsr     ShowAlert
        jmp     ClearSelectedIndex

        ;; --------------------------------------------------
        ;; Check Path

check_path:
        ldy     INVOKER_PREFIX
:       lda     INVOKER_PREFIX,y
        cmp     #'/'
        beq     :+
        dey
        bne     :-
        lda     #AlertID::insert_source_disk
        jsr     ShowAlert
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     ClearSelectedIndex ; `kAlertResultCancel` = 1
        jmp     try

:       dey
        tya
        pha
        iny
        ldx     #$00
:       iny
        inx
        lda     INVOKER_PREFIX,y
        sta     INVOKER_FILENAME,x
        cpy     INVOKER_PREFIX
        bne     :-
        stx     INVOKER_FILENAME
        pla
        sta     INVOKER_PREFIX
        param_call UpcaseString, INVOKER_PREFIX
        param_call UpcaseString, INVOKER_FILENAME
        param_call UpcaseString, INVOKER_INTERPRETER

        ;; --------------------------------------------------
        ;; Invoke

        jsr     RestoreSystem

        jsr     INVOKER

        ;; If we got here, invoker failed somehow. Relaunch.
        jsr     Bell
        jsr     Bell
        jsr     Bell
        MLI_CALL QUIT, quit_params
        brk

.endproc ; InvokeEntry
        invoke_entry_ep2 := InvokeEntry::ep2

        DEFINE_QUIT_PARAMS quit_params

.proc ClearSelectedIndex
        lda     invoked_during_boot_flag
        bne     :+
        lda     #$FF
        sta     selected_index
:       rts
.endproc ; ClearSelectedIndex

;;; ============================================================

kBSOffset       = 5             ; Offset of 'x' in BASIx.SYSTEM
str_basix_system:
        PASCAL_STRING "BASIx.SYSTEM"

;;; --------------------------------------------------
;;; Check `src_path_buf`'s ancestors to see if the desired interpreter
;;; (BASIC.SYSTEM or BASIS.SYSTEM) is present.
;;; Input: `src_path_buf` set to target path
;;; Output: zero if found, non-zero if not found

.proc CheckBasixSystemImpl
        launch_path := INVOKER_PREFIX
        interp_path := INVOKER_INTERPRETER

basic:  lda     #'C'            ; "BASI?" -> "BASIC"
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
basis:  lda     #'S'            ; "BASI?" -> "BASIS"
        sta     str_basix_system + kBSOffset

        ;; Start off with `interp_path` = `launch_path`
        ldx     launch_path
        stx     path_length
:       copy    launch_path,x, interp_path,x
        dex
        bpl     :-

        ;; Pop off a path segment.
pop_segment:
        path_length := *+1
        ldx     #SELF_MODIFIED_BYTE
:       lda     interp_path,x
        cmp     #'/'
        beq     found_slash
        dex
        bne     :-

no_bs:  copy    #0, interp_path ; null out the path
        return  #$FF            ; non-zero is failure

found_slash:
        cpx     #1
        beq     no_bs
        stx     interp_path
        dex
        stx     path_length

        ;; Append BASI?.SYSTEM to path and check for file.
        ldx     interp_path
        ldy     #0
:       inx
        iny
        copy    str_basix_system,y, interp_path,x
        cpy     str_basix_system
        bne     :-
        stx     interp_path
        param_call GetFileInfo, interp_path
        bne     pop_segment

        rts                     ; zero is success
.endproc ; CheckBasixSystemImpl
CheckBasisSystem        := CheckBasixSystemImpl::basis

str_extras_basic:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/BASIC.system")

.proc CheckBasicSystem
        MLI_CALL GET_PREFIX, get_prefix_params

        ldy     #0
        ldx     INVOKER_INTERPRETER
:       iny
        inx
        lda     str_extras_basic,y
        sta     INVOKER_INTERPRETER,x
        cpy     str_extras_basic
        bne     :-
        stx     INVOKER_INTERPRETER
        param_call GetFileInfo, INVOKER_INTERPRETER
        jne     CheckBasixSystemImpl::basic ; nope, look relative to launch path
        rts

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, INVOKER_INTERPRETER
.endproc ; CheckBasicSystem

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
        beq     ret
        tay
@loop:  lda     (ptr),y
        cmp     #'a'
        bcc     :+
        cmp     #'z'+1
        bcs     :+
        and     #CASE_MASK
        sta     (ptr),y
:       dey
        bne     @loop
ret:    rts
.endproc ; UpcaseString

;;; ============================================================

        .include "../lib/ramcard.s"

;;; ============================================================

.proc ComposeRAMCardEntryPath
        buf := $800

        sta     tmp
        param_call CopyRAMCardPrefix, buf
        lda     tmp
        jsr     GetSelectorListPathAddr

        path_addr := $06

        stax    path_addr
        ldy     #0
        lda     (path_addr),y
        sta     len
        tay
:       lda     (path_addr),y
        cmp     #'/'
        beq     :+
        dey
        bne     :-

:       dey
:       lda     (path_addr),y
        cmp     #'/'
        beq     :+
        dey
        bne     :-

:       dey
        ldx     buf
:       inx
        iny
        lda     (path_addr),y
        sta     buf,x
        cpy     len
        bne     :-
        stx     buf
        ldax    #buf
        rts

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
.proc AlertYieldLoopRelay
        sta     ALTZPOFF
        bit     ROMIN2
        jsr     YieldLoop
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1
        rts
.endproc ; AlertYieldLoopRelay

;;; ============================================================
;;; Assert: ROM is banked in

.proc SetRGBMode
        ldx     #DeskTopSettings::rgb_color
        jsr     ReadSetting
        bpl     SetMonoMode
        FALL_THROUGH_TO SetColorMode
.endproc ; SetRGBMode

.proc SetColorMode
        ;; IIgs?
        sec
        jsr     IDROUTINE
        bcc     iigs

        bit     lcm_eve_flag
        bmi     lcmeve

        ;; AppleColor Card - Mode 2 (Color 140x192)
        ;; Also: Video-7 and Le Chat Mauve Feline
        sta     SET80VID        ; set register to 1
        sta     AN3_OFF
        sta     AN3_ON          ; shift in 1 as first bit
        sta     AN3_OFF
        sta     AN3_ON          ; shift in 1 as second bit
        sta     DHIRESON        ; re-enable DHR
        rts

        ;; Le Chat Mauve Eve - COL140 mode
        ;; (AN3 off, HR1 off, HR2 off, HR3 off)
lcmeve: sta     AN3_OFF
        sta     HR1_OFF
        sta     HR2_OFF
        sta     HR3_OFF
        rts

        ;; Apple IIgs - DHR Color
iigs:   lda     NEWVIDEO
        and     #<~(1<<5)       ; Color
        sta     NEWVIDEO
        lda     #$00            ; Color
        sta     MONOCOLOR
        rts
.endproc ; SetColorMode

.proc SetMonoMode
        sec
        jsr     IDROUTINE
        bcc     iigs

        bit     lcm_eve_flag
        bmi     lcmeve

        ;; AppleColor Card - Mode 1 (Monochrome 560x192)
        ;; Also: Video-7 and Le Chat Mauve Feline
        sta     CLR80VID        ; set register to 0
        sta     AN3_OFF
        sta     AN3_ON          ; shift in 0 as first bit
        sta     AN3_OFF
        sta     AN3_ON          ; shift in 0 as second bit
        sta     SET80VID        ; re-enable DHR
        sta     DHIRESON
        rts

        ;; Le Chat Mauve Eve - BW560 mode
        ;; (AN3 off, HR1 off, HR2 on, HR3 on)
lcmeve: sta     AN3_OFF
        sta     HR1_OFF
        sta     HR2_ON
        sta     HR3_ON
        rts

        ;; Apple IIgs - DHR B&W
iigs:   lda     NEWVIDEO
        ora     #(1<<5)         ; B&W
        sta     NEWVIDEO
        lda     #$80            ; Mono
        sta     MONOCOLOR

done:   rts
.endproc ; SetMonoMode


;;; ============================================================
;;; On IIgs, force preferred RGB mode. No-op otherwise.

.proc ResetIIgsRGB
        bit     is_iigs_flag
        bpl     SetMonoMode::done

        ldx     #DeskTopSettings::rgb_color
        jsr     ReadSetting
        bmi     SetColorMode::iigs
        bpl     SetMonoMode::iigs ; always
.endproc ; ResetIIgsRGB

;;; ============================================================
;;; Called by main and nested event loops to do periodic tasks.
;;; Returns 0 if the periodic tasks were run.

.proc YieldLoop
        kMaxCounter = $E0       ; arbitrary

        inc     loop_counter
        inc     loop_counter
        lda     loop_counter
        cmp     #kMaxCounter
        bcc     :+
        copy    #0, loop_counter

        jsr     ShowClock
        jsr     ResetIIgsRGB   ; in case it was reset by control panel

:       lda     loop_counter
        rts

loop_counter:
        .byte   0
.endproc ; YieldLoop

;;; ============================================================

        .include "../lib/menuclock.s"
        .include "../lib/datetime.s"
        .include "../lib/doubleclick.s"
        .include "../lib/drawstring.s"
        .include "../lib/muldiv.s"
        .include "../lib/speed.s"
        .include "../lib/bell.s"
        .include "../lib/detect_lcmeve.s"
        .include "../lib/clear_dhr.s"
        .include "../lib/disconnect_ram.s"
        .include "../lib/reconnect_ram.s"
        .include "../lib/readwrite_settings.s"

         ADJUSTCASE_VOLPATH := $810
         ADJUSTCASE_VOLBUF  := $820
         ADJUSTCASE_IO_BUFFER := $1C00
        .include "../lib/adjustfilecase.s"

        .include "../toolkits/btk.s"
        BTKEntry := btk::BTKEntry

;;; ============================================================

.endscope ; app

        ENDSEG SegmentApp
        ASSERT_ADDRESS OVERLAY_ADDR
