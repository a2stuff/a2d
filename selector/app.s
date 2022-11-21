;;; ============================================================
;;; Selector Application
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        .org kSegmentAppAddress

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
        PASCAL_STRING .sprintf(res_string_version_format_short, kDeskTopProductName, ::kDeskTopVersionMajor, ::kDeskTopVersionMinor)

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
mincontlength:  .word   50
maxcontwidth:   .word   500
maxcontlength:  .word   140
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
        PASCAL_STRING res_string_selector_dialog_title ; dialog title

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

        DEFINE_OPEN_PARAMS open_desktop2_params, str_desktop2, io_buf_desktop
        DEFINE_READ_PARAMS read_desktop2_params, desktop_load_addr, kDeskTopLoadSize

str_selector_list:
        PASCAL_STRING kFilenameSelectorList

str_desktop2:
        PASCAL_STRING kFilenameDeskTop

        DEFINE_CLOSE_PARAMS close_params

        DEFINE_OPEN_PARAMS open_selector_params, str_selector, $800

str_selector:
        PASCAL_STRING kFilenameSelector

        DEFINE_SET_MARK_PARAMS set_mark_overlay1_params, kOverlayFileDialogOffset
        DEFINE_SET_MARK_PARAMS set_mark_overlay2_params, kOverlayCopyDialogOffset
        DEFINE_READ_PARAMS read_overlay1_params, OVERLAY_ADDR, kOverlayFileDialogLength
        DEFINE_READ_PARAMS read_overlay2_params, OVERLAY_ADDR, kOverlayCopyDialogLength
        DEFINE_CLOSE_PARAMS close_params2

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_desktop2_params, str_desktop2_2
str_desktop2_2:
        PASCAL_STRING kFilenameDeskTop

desktop_available_flag:
        .byte   0


;;; Index of selected entry, or $FF if none
selected_index:
        .byte   0

entry_string_buf:
        .res    20

num_primary_run_list_entries:
        .byte   0
num_secondary_run_list_entries:
        .byte   0

L9129:  .byte   0

is_iigs_flag:                   ; high bit set if IIgs
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
        cli

        copy    BUTN2, pb2_initial_state

        sec
        jsr     IDROUTINE       ; clear C if IIgs
    IF_CC
        copy    #$80, is_iigs_flag
    END_IF

        jsr     DetectLeChatMauveEve
        beq     :+              ; Z=1 means no LCMEve
        copy    #$80, lcm_eve_flag
:

        copy    #$FF, selected_index
        jsr     LoadSelectorList
        copy    #1, L9129
        lda     num_secondary_run_list_entries
        ora     num_primary_run_list_entries
        bne     check_key_down

quick_run_desktop:
        MLI_CALL GET_FILE_INFO, get_file_info_desktop2_params
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

        stax    entry_ptr
        ldy     #kSelectorEntryFlagsOffset
        lda     (entry_ptr),y
        cmp     #kSelectorEntryCopyNever
        beq     :+
        jsr     GetCopiedToRAMCardFlag
        beq     done_keys
        jsr     GetSelectedIndexFileInfo
        beq     :+
        jmp     done_keys

:       lda     selected_index
        jsr     InvokeEntry

        ;; --------------------------------------------------

done_keys:
        sta     KBDSTRB
        copy    #0, L9129

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

        MGTK_CALL MGTK::SetDeskPat, SETTINGS + DeskTopSettings::pattern

        copy    VERSION, startdesktop_params::machine
        copy    ZIDBYTE, startdesktop_params::subid

        jsr     ClearDHRToBlack

        MGTK_CALL MGTK::SetZP1, setzp_params
        MGTK_CALL MGTK::StartDeskTop, startdesktop_params
        jsr     SetRGBMode
        MGTK_CALL MGTK::SetMenu, menu
        jsr     ShowClock
        MGTK_CALL MGTK::ShowCursor
        MGTK_CALL MGTK::FlushEvents

        ;; --------------------------------------------------
        ;; Cursor tracking

        ;; Doubled if option selected
        lda     SETTINGS + DeskTopSettings::mouse_tracking
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
        MLI_CALL GET_FILE_INFO, get_file_info_desktop2_params
        beq     :+
        lda     #$80
:       sta     desktop_available_flag

        ;; --------------------------------------------------
        ;; Open the window

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     GetPortAndDrawWindow
        copy    #$FF, selected_index
        jsr     LoadSelectorList
        jsr     PopulateEntriesFlagTable
        jsr     DrawEntries
        jmp     EventLoop

quick_boot_slot:
        .byte   0
.endproc

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
@retry: MLI_CALL GET_FILE_INFO, get_file_info_desktop2_params
        beq     :+
        lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     EventLoop      ; `kAlertResultCancel` = 1
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
.endproc

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
.endproc

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
        beq     :+
        lda     #1
:       sta     menu_params::key_mods
        MGTK_CALL MGTK::MenuKey, menu_params::menu_id
        FALL_THROUGH_TO HandleMenu
.endproc

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
.endproc

;;; ============================================================

.proc CmdRunAProgram
        lda     selected_index
        bmi     L93FF
        jsr     MaybeToggleEntryHilite
        lda     #$FF
        sta     selected_index
L93FF:  jsr     SetCursorWatch
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
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     :+           ; `kAlertResultCancel` = 1
        jsr     SetCursorWatch
        jmp     L93FF

:       rts
.endproc

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

@retry: MLI_CALL GET_FILE_INFO, get_file_info_desktop2_params
        beq     :+
        lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     done            ; `kAlertResultCancel` = 1
        beq     @retry          ; `kAlertResultTryAgain` = 0
:       jmp     RunDesktop

        ;; Entry selection?

check_entries:
        jsr     GetOptionIndexFromCoords
        bmi     done

        ;; Is it valid?
        sta     index
        cmp     #8
        bcc     primary
        bcs     secondary

primary:
        cmp     num_primary_run_list_entries
        bcc     finish
        lda     selected_index
        jsr     MaybeToggleEntryHilite
        copy    #$FF, selected_index
        rts

secondary:
        sec
        sbc     #8
        cmp     num_secondary_run_list_entries
        bcc     finish
        lda     selected_index
        jsr     MaybeToggleEntryHilite
        copy    #$FF, selected_index
        rts

finish: lda     index
        jmp     HandleEntryClick

L959D:  .byte   0
index:  .byte   0
L959F:  .byte   0

.endproc

;;; ============================================================

noop:   rts

;;; ============================================================

.proc RunDesktop
        sta     ALTZPOFF
        bit     ROMIN2
        jsr     RestoreSystem

        MLI_CALL OPEN, open_desktop2_params
        lda     open_desktop2_params::ref_num
        sta     read_desktop2_params::ref_num
        MLI_CALL READ, read_desktop2_params
        MLI_CALL CLOSE, close_params
        jmp     desktop_load_addr
.endproc

;;; ============================================================
;;; Assert: ROM banked in, ALTZP/LC is OFF

.proc RestoreSystem
        jsr     SetColorMode
        jsr     RestoreTextMode
        jsr     ReconnectRAM
        jmp     RestoreDeviceList
.endproc

;;; ============================================================
;;; Disable 80-col firmware, clear and show the text screen.
;;; Assert: ROM is banked in, ALTZP/LC is off

.proc RestoreTextMode
        jsr     HOME            ; Clear 80-col screen
        lda     #$11            ; Ctrl-Q - disable 80-col firmware
        jsr     COUT

        jsr     SETVID
        jsr     SETKBD
        jsr     INIT

        sta     DHIRESOFF
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR

        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80STORE

        rts
.endproc

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
        sta     tentative_selection
        cmp     num_primary_run_list_entries
        bcc     :+
        rts

:       lda     selected_index
        bmi     no_cur_sel
        cmp     tentative_selection
        bne     :+
        rts

:       lda     selected_index
        jsr     MaybeToggleEntryHilite
no_cur_sel:
        lda     tentative_selection
        sta     selected_index
        jmp     MaybeToggleEntryHilite

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

        cmp     #CHAR_LEFT
        jeq     HandleKeyLeft

        cmp     #CHAR_RIGHT
        jeq     HandleKeyRight

        cmp     #CHAR_DOWN
        jeq     HandleKeyDown

        cmp     #CHAR_UP
        jeq     HandleKeyUp

        rts

;;; ============================================================


tentative_selection:
        .byte   0


;;; ============================================================

.proc HandleKeyRight
        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
        beq     done

        lda     selected_index
        bpl     move           ; have a selection

        ;; No selection; find a valid one in top row
        ldx     #0
        lda     entries_flag_table
        bpl     set

        ldx     #8
        lda     entries_flag_table+8
        bpl     set

        ldx     #16
        lda     entries_flag_table+16
        bpl     set

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     MaybeToggleEntryHilite

        lda     selected_index
loop:   clc
        adc     #8
        cmp     #kSelectorListNumEntries
        bcc     :+
        clc
        adc     #1
        and     #7

:       tax
        lda     entries_flag_table,x
        bpl     set
        txa
        jmp     loop

set:    txa
        sta     selected_index
        jsr     MaybeToggleEntryHilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc HandleKeyLeft
        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
        beq     done

        lda     selected_index
        bpl     move            ; have a selection

        ;; No selection - re-use logic to find last item
        jmp     HandleKeyUp

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     MaybeToggleEntryHilite

        lda     selected_index
loop:   sec
        sbc     #8
        bpl     :+
        sec
        sbc     #1
        and     #7
        ora     #16

:       tax
        lda     entries_flag_table,x
        bpl     set
        txa
        jmp     loop

set:    txa
        sta     selected_index
        jsr     MaybeToggleEntryHilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc HandleKeyUp
        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
        beq     done

        lda     selected_index
        bpl     move            ; have a selection

        ;; No selection; find last valid one
        ldx     #kSelectorListNumEntries - 1
:       lda     entries_flag_table,x
        bpl     set
        dex
        bpl     :-

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     MaybeToggleEntryHilite

        ldx     selected_index
loop:   dex                     ; to previous
        bmi     wrap
        lda     entries_flag_table,x
        bpl     set
        jmp     loop

wrap:   ldx     #kSelectorListNumEntries
        jmp     loop

set:    sta     selected_index
        jsr     MaybeToggleEntryHilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc HandleKeyDown
        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
        beq     done

        lda     selected_index
        bpl     move           ; have a selection

        ;; No selection; find first valid one
        ldx     #0
:       lda     entries_flag_table,x
        bpl     set
        inx
        bne     :-

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     MaybeToggleEntryHilite

        ldx     selected_index
loop:   inx                     ; to next
        cpx     #kSelectorListNumEntries
        bcs     wrap
        lda     entries_flag_table,x
        bpl     set             ; valid!
        jmp     loop

wrap:   ldx     #AS_BYTE(-1)
        jmp     loop

        ;; Set the selection
set:    sta     selected_index
        jsr     MaybeToggleEntryHilite

done:   return  #$FF
.endproc

;;; ============================================================

.endproc

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
.endproc

;;; Table for 24 entries; index (0...23) if in use, $FF if empty
entries_flag_table:
        .res    ::kSelectorListNumEntries, 0

;;; ============================================================

.proc TryInvokeSelectedIndex
        lda     selected_index
        bmi     :+
        jsr     InvokeEntry
:       rts
.endproc

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
.endproc

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
.endproc

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
.endproc

;;; ============================================================

.proc SetCursorWatch
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        rts
.endproc

.proc SetCursorPointer
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts
.endproc

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
        MLI_CALL GET_FILE_INFO, get_file_info_invoke_params
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
.endproc

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
.endproc

backup_devlst:
        .byte   $FF             ; backup for DEVCNT (w/ high bit set)
        .res    14, 0           ; backup for DEVLST (7 slots * 2 drives)

;;; ============================================================

.proc GetPortAndDrawWindow
        lda     #winfo::kDialogId
        jsr     GetWindowPort
        FALL_THROUGH_TO DrawWindow
.endproc

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
.endproc

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
.endproc

;;; ============================================================
;;; Inputs: A,X = Address

.proc AdjustPathCase
        ptr := $0A

        stx     ptr+1
        sta     ptr
        ldy     #$00
        lda     (ptr),y
        tay
        bne     loop
        rts

loop:   dey
        beq     done
        bpl     :+
done:   rts

        ;; Seek to next boundary
:       lda     (ptr),y
        cmp     #'/'
        beq     L99FA
        cmp     #'.'
        bne     L99FE
L99FA:  dey
        jmp     loop

        ;; Adjust case
L99FE:  iny
        lda     (ptr),y
        cmp     #'A'
        bcc     L9A10
        cmp     #'Z'+1
        bcs     L9A10
        clc
        adc     #$20            ; to lower case
        sta     (ptr),y
L9A10:  dey
        jmp     loop

        .byte   0
.endproc

;;; ============================================================
;;; Set the active GrafPort to the selected window's port
;;; Input: A = window id

.proc GetWindowPort
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport_win
        rts
.endproc

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
.endproc

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
.endproc

;;; ============================================================
;;; Get the coordinates of an option by index.
;;; Input: A = volume index
;;; Output: A,X = x coordinate, Y = y coordinate
.proc GetOptionPos
        sta     index
        .repeat app::kEntryPickerRowShift
        lsr
        .endrepeat
        ldx     #0              ; hi
        ldy     #kEntryPickerItemWidth
        jsr     Multiply_16_8_16
        clc
        adc     #<kEntryPickerLeft
        pha                     ; lo
        txa
        adc     #>kEntryPickerLeft
        pha                     ; hi

        ;; Y coordinate
        index := *+1
        lda     #SELF_MODIFIED_BYTE
        and     #kEntryPickerRows-1
        ldx     #0              ; hi
        ldy     #kEntryPickerItemHeight
        jsr     Multiply_16_8_16
        clc
        adc     #kEntryPickerTop

        tay                     ; Y coord
        pla
        tax                     ; X coord hi
        pla                     ; X coord lo

        rts
.endproc

;;; ============================================================

;;; Inputs: `screentowindow_params` has `windowx` and `windowy` mapped
;;; Outputs: A=index, N=1 if no match
.proc GetOptionIndexFromCoords
        ;; Row
        sub16   screentowindow_params::windowy, #kEntryPickerTop, screentowindow_params::windowy
        bmi     done

        ldax    screentowindow_params::windowy
        ldy     #kEntryPickerItemHeight
        jsr     Divide_16_8_16  ; A = row

        cmp     #kEntryPickerRows
        bcs     done
        sta     row

        ;; Column
        sub16   screentowindow_params::windowx, #kEntryPickerLeft, screentowindow_params::windowx
        bmi     done

        ldax    screentowindow_params::windowx
        ldy     #kEntryPickerItemWidth
        jsr     Divide_16_8_16  ; A = col

        cmp     #kEntryPickerCols
        bcs     done

        ;; Index
        .repeat app::kEntryPickerRowShift
        asl
        .endrepeat
        row := *+1
        ora     #SELF_MODIFIED_BYTE
        rts

done:   return  #$FF
.endproc

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
        jsr     GetOptionPos
        addax   #kEntryPickerTextHOffset, entry_picker_item_rect::x1
        tya
        ldx     #0
        addax   #kEntryPickerTextVOffset, entry_picker_item_rect::y1
        MGTK_CALL MGTK::MoveTo, entry_picker_item_rect::topleft
        param_call DrawString, entry_string_buf
        rts
.endproc

;;; ============================================================
;;; Input: A = clicked entry

.proc HandleEntryClick
        cmp     selected_index  ; same as previous selection?
        beq     :+
        pha
        lda     selected_index
        jsr     MaybeToggleEntryHilite ; un-highlight old entry
        pla
        sta     selected_index
        jsr     MaybeToggleEntryHilite ; highlight new entry
:

        jsr     DetectDoubleClick
        jeq     InvokeEntry

        rts

.endproc

;;; ============================================================
;;; Toggle the highlight on an entry in the list
;;; Input: A = entry number (negative if no selection)

.proc MaybeToggleEntryHilite
        bmi     ret

        jsr     GetOptionPos
        stax    entry_picker_item_rect::x1
        addax   #kEntryPickerItemWidth-1, entry_picker_item_rect::x2
        tya                     ; y lo
        ldx     #0              ; y hi
        stax    entry_picker_item_rect::y1
        addax   #kEntryPickerItemHeight-1, entry_picker_item_rect::y2

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, entry_picker_item_rect

ret:    rts
.endproc

;;; ============================================================

.proc CmdStartup
        ldy     menu_params::menu_item
        lda     slot_table,y
        ora     #>$C000         ; compute $Cn00
        sta     @addr+1
        lda     #<$C000
        sta     @addr

        sta     ALTZPOFF
        bit     ROMIN2
        jsr     RestoreSystem

        @addr := * + 1
        jmp     SELF_MODIFIED
.endproc

;;; ============================================================

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_invoke_params, INVOKER_PREFIX

.proc InvokeEntry
        lda     L9129
        bne     :+
        jsr     SetCursorWatch
        lda     selected_index
        bmi     :+
        jsr     MaybeToggleEntryHilite
:       jmp     try

ep2:    jmp     L9C7E

try:    lda     L9129
        bne     L9C32
        bit     BUTN0
        bpl     L9C2A
        jmp     L9C78

L9C2A:  jsr     GetCopiedToRAMCardFlag
        bne     L9C32
        jmp     L9C78

L9C32:  lda     selected_index
        jsr     GetSelectorListEntryAddr
        stax    $06
        ldy     #kSelectorEntryFlagsOffset
        lda     ($06),y
        asl     a
        bmi     L9C78           ; bit 6 (now 7) = never copy
        bcc     L9C65           ; bit 8 (now C) = copy on boot

        ;; Copy on boot
        lda     L9129
        bne     L9C6F
        jsr     GetSelectedIndexFileInfo
        beq     L9C6F
        jsr     LoadOverlayCopyDialog
        lda     selected_index
        jsr     file_copier__Exec
        pha
        jsr     CheckAndClearUpdates
        pla
        beq     L9C6F
        jsr     SetCursorPointer
        jmp     ClearSelectedIndex

L9C65:  lda     L9129
        bne     L9C6F
        jsr     GetSelectedIndexFileInfo
        bne     L9C78
L9C6F:  lda     selected_index
        jsr     ComposeDstPath
        jmp     L9C7E

        ;; --------------------------------------------------

L9C78:  lda     selected_index
        jsr     GetSelectorListPathAddr
L9C7E:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9C87:  lda     ($06),y
        sta     INVOKER_PREFIX,y
        dey
        bpl     L9C87
        MLI_CALL GET_FILE_INFO, get_file_info_invoke_params
        beq     check_type

        tax
        lda     L9129
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
        jmp     L9C78

fail:   jmp     ClearSelectedIndex

        ;; --------------------------------------------------
        ;; Check file type

        ;; Ensure it's BIN, SYS, S16 or BAS (if BS is present)

check_type:
        lda     get_file_info_invoke_params::file_type
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

        ;; --------------------------------------------------
        ;; Invoke

        sta     ALTZPOFF
        bit     ROMIN2
        jsr     RestoreSystem

        jsr     INVOKER

        ;; If we got here, invoker failed somehow. Relaunch.
        jsr     Bell
        jsr     Bell
        jsr     Bell
        MLI_CALL QUIT, quit_params
        brk

.endproc
        invoke_entry_ep2 := InvokeEntry::ep2

        DEFINE_QUIT_PARAMS quit_params

.proc ClearSelectedIndex
        lda     L9129
        bne     :+
        lda     #$FF
        sta     selected_index
:       rts
.endproc

;;; ============================================================

        scratch_buf := $1C00
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_bs_params, scratch_buf

kBSOffset       = 5             ; Offset of 'x' in BASIx.SYSTEM
str_basix_system:
        PASCAL_STRING "BASIx.SYSTEM"

.proc CheckBasixSystemImpl
        launch_path := INVOKER_PREFIX
        path_buf := $1C00

basic:  lda     #'C'            ; "BASI?" -> "BASIC"
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
basis:  lda     #'S'            ; "BASI?" -> "BASIS"
        sta     str_basix_system + kBSOffset

        ldx     launch_path
:       lda     launch_path,x
        cmp     #'/'
        beq     :+
        dex
        bne     :-
        jmp     L9DBA

:       dex
        stx     len
        stx     path_buf
L9D78:  lda     launch_path,x
        sta     path_buf,x
        dex
        bne     L9D78
        inc     path_buf
        ldx     path_buf
        lda     #'/'
        sta     path_buf,x
L9D8C:  ldx     path_buf
        ldy     #$00
L9D91:  inx
        iny
        lda     str_basix_system,y
        sta     path_buf,x
        cpy     str_basix_system
        bne     L9D91
        stx     path_buf
        MLI_CALL GET_FILE_INFO, get_file_info_bs_params
        bne     L9DAD
        rts

L9DAD:  ldx     len
L9DB0:  lda     path_buf,x
        cmp     #'/'
        beq     L9DC8
        dex
        bne     L9DB0

L9DBA:  return  #$FF            ; non-zero is failure

L9DC8:  cpx     #$01
        beq     L9DBA
        stx     path_buf
        dex
        stx     len
        jmp     L9D8C

len:    .byte   0

.endproc
CheckBasicSystem        := CheckBasixSystemImpl::basic
CheckBasisSystem        := CheckBasixSystemImpl::basis

;;; ============================================================
;;; Uppercase a string
;;; Input: A,X = Address

.proc UpcaseString
        ptr := $06

        stax    ptr
        ldy     #$00
        lda     (ptr),y
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
        rts
.endproc

;;; ============================================================

.proc GetSelectedIndexFileInfo
        ptr := $06

        lda     selected_index
        jsr     ComposeDstPath
        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     INVOKER_PREFIX,y
        dey
        bpl     :-
        MLI_CALL GET_FILE_INFO, get_file_info_invoke_params
        rts
.endproc

;;; ============================================================

;;; NOTE: Can't use "../lib/ramcard.s" since the calling code is
;;; not running w/ AUXZP and LCBANK1.

.proc GetCopiedToRAMCardFlag
        bit     LCBANK2
        bit     LCBANK2
        lda     COPIED_TO_RAMCARD_FLAG
        tax
        bit     ROMIN2
        txa
        rts
.endproc

.proc CopyRAMCardPrefix
        stax    @addr
        bit     LCBANK2
        bit     LCBANK2
        ldx     RAMCARD_PREFIX
:       lda     RAMCARD_PREFIX,x
        @addr := * + 1
        sta     SELF_MODIFIED,x
        dex
        bpl     :-
        bit     ROMIN2
        rts
.endproc

;;; Copy the original DeskTop prefix (e.g. "/HD/A2D") to the passed buffer.
;;; Input: A,X=destination buffer
.proc CopyDeskTopOriginalPrefix
        stax    @addr
        bit     LCBANK2
        bit     LCBANK2

        ldx     DESKTOP_ORIG_PREFIX
:       lda     DESKTOP_ORIG_PREFIX,x
        @addr := *+1
        sta     SELF_MODIFIED,x
        dex
        bpl     :-

        bit     ROMIN2
        rts
.endproc

;;; ============================================================

.proc ComposeDstPath
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
.endproc

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
.endproc

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
.endproc

;;; ============================================================
;;; Assert: ROM is banked in

.proc SetRGBMode
        bit     SETTINGS + DeskTopSettings::rgb_color
        bpl     SetMonoMode
        FALL_THROUGH_TO SetColorMode
.endproc

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
.endproc

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
.endproc


;;; ============================================================
;;; On IIgs, force preferred RGB mode. No-op otherwise.

.proc ResetIIgsRGB
        bit     is_iigs_flag
        bpl     SetMonoMode::done

        bit     SETTINGS + DeskTopSettings::rgb_color
        bmi     SetColorMode::iigs
        bpl     SetMonoMode::iigs ; always
.endproc

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
.endproc

;;; ============================================================
;;; Test if either modifier (Open-Apple or Solid-Apple) is down.
;;; Output: A=high bit/N flag set if either is down.

.proc ModifierDown
        lda     BUTN0
        ora     BUTN1
        rts
.endproc

;;; Test if shift is down (if it can be detected).
;;; Output: A=high bit/N flag set if down.

.proc ShiftDown
        bit     is_iigs_flag
        bpl     TestShiftMod    ; no, rely on shift key mod

        lda     KEYMODREG       ; On IIgs, use register instead
        and     #%00000001      ; bit 7 = Command (OA), bit 0 = Shift
        bne     :+
        rts

:       lda     #$80
        rts
.endproc

;;; Compare the shift key mod state. Returns high bit set if
;;; not the initial state (i.e. Shift key is likely down), if
;;; detectable.

.proc TestShiftMod
        ;; If a IIe, maybe use shift key mod
        ldx     ZIDBYTE         ; $00 = IIc/IIc+
        ldy     IDBYTELASER128  ; $AC = Laser 128
        lda     #0
        cpx     #0              ; ZIDBYTE = $00 == IIc/IIc+
        beq     :+
        cpy     #$AC            ; IDBYTELASER128 = $AC = Laser 128
        beq     :+              ; On Laser, BUTN2 set when mouse button clicked

        ;; It's a IIe, compare shift key state
        lda     pb2_initial_state ; if shift key mod installed, %1xxxxxxx
        eor     BUTN2             ; ... and if shift is down, %0xxxxxxx

:       rts
.endproc

;;; Shift key mod sets PB2 if shift is *not* down. Since we can't detect
;;; the mod, snapshot on init (and assume shift is not down) and XOR.
pb2_initial_state:
        .byte   0

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

        BTK_SHORT = 1
        .include "../toolkits/btk.s"
        BTKEntry := btk::BTKEntry

;;; ============================================================
;;; Settings - modified by Control Panels
;;; ============================================================

        PAD_TO ::BELLDATA
        .include "../lib/default_sound.s"

        PAD_TO ::SETTINGS
        .include "../lib/default_settings.s"

;;; ============================================================

.endscope

        PAD_TO kSegmentAppAddress + kSegmentAppLength
        ASSERT_ADDRESS OVERLAY_ADDR
