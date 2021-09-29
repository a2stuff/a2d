;;; ============================================================
;;; Selector Application
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        RESOURCE_FILE "app.res"

        .org $4000

.scope app

;;; See docs/Selector_List_Format.md for file format
selector_list   := $B300

kEntryPickerItemWidth = 127
kEntryPickerItemHeight = 9

kShortcutRunDeskTop = res_char_button_desktop_shortcut
kShortcutRunProgram = res_char_menu_item_run_a_program_shortcut

;;; ============================================================
;;; MGTK library

        ASSERT_ADDRESS ::MGTK
        .include "../mgtk/mgtk.s"

;;; ============================================================
;;; Resources

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

pencopy:        .byte   MGTK::pencopy
penOR:          .byte   MGTK::penOR
penXOR:         .byte   MGTK::penXOR
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy
notpenOR:       .byte   MGTK::notpenOR
notpenXOR:      .byte   MGTK::notpenXOR
notpenBIC:      .byte   MGTK::notpenBIC

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
        PASCAL_STRING kGlyphSolidApple ; do not localize

str_file:
        PASCAL_STRING res_string_menu_bar_item_file    ; menu bar item
str_startup:
        PASCAL_STRING res_string_menu_bar_item_startup ; menu bar item

str_a2desktop:
        PASCAL_STRING .sprintf("%s Version %d.%d", kDeskTopProductName, ::kDeskTopVersionMajor, ::kDeskTopVersionMinor) ; do not localize

str_blank:
        PASCAL_STRING " "       ; do not localize
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
;;; Font

        PAD_TO ::FONT
        .incbin .concat("../mgtk/fonts/A2D.FONT.", kBuildLang)

;;; ============================================================
;;; Settings

        PAD_TO ::SETTINGS
        .include "../lib/default_settings.s"

;;; ============================================================
;;; Application entry point

        PAD_TO ::START
        jmp     entry

;;; ============================================================
;;; Event Params (and overlapping param structs)

event_params := *
event_kind := event_params + 0
        ;; if kind is key_down
event_key := event_params + 1
event_modifiers := event_params + 2
        ;; if kind is no_event, button_down/up, drag, or apple_key:
event_coords := event_params + 1
event_xcoord := event_params + 1
event_ycoord := event_params + 3
        ;; if kind is update:
event_window_id := event_params + 1

screentowindow_params := *
screentowindow_window_id := screentowindow_params + 0
screentowindow_screenx := screentowindow_params + 1
screentowindow_screeny := screentowindow_params + 3
screentowindow_windowx := screentowindow_params + 5
screentowindow_windowy := screentowindow_params + 7
        .assert screentowindow_screenx = event_xcoord, error, "param mismatch"
        .assert screentowindow_screeny = event_ycoord, error, "param mismatch"

findwindow_params := * + 1    ; offset to x/y overlap event_params x/y
findwindow_mousex := findwindow_params + 0
findwindow_mousey := findwindow_params + 2
findwindow_which_area := findwindow_params + 4
findwindow_window_id := findwindow_params + 5
        .assert findwindow_mousex = event_xcoord, error, "param mismatch"
        .assert findwindow_mousey = event_ycoord, error, "param mismatch"

beginupdate_params := * + 1
beginupdate_window_id := beginupdate_params + 0

;;; Coords used when entry is clicked
entry_click_x := * + 5
entry_click_y := * + 7

;;; Union of above params
        .res    10, 0

;;; ============================================================

grafport2:
        .tag    MGTK::GrafPort

.params getwinport_params
window_id:     .byte   0
a_grafport:    .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort

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
        kWidth = 500
        kHeight = 118
window_id:      .byte   kDialogId = 1
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
viewloc:        .word   (::kScreenWidth - kWidth)/2, (::kScreenHeight - kHeight)/2
mapbits:        .word   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   $00
cliprect:       .word   0, 0, kWidth, kHeight
pattern:        .res    8, $FF
colormasks:     .byte   $FF, 0
penloc:         .word   0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .word   FONT
nextwinfo:      .addr   0
.endparams

        DEFINE_RECT_INSET rect_frame, 4, 2, winfo::kWidth, winfo::kHeight

        DEFINE_BUTTON ok,      res_string_button_ok, 340, 102
        DEFINE_BUTTON desktop, res_string_button_desktop,    60, 102

setpensize_params:
        .byte   2, 1

        DEFINE_POINT pos_title_string, 0, 15

str_selector_title:
        PASCAL_STRING res_string_selector_dialog_title ; dialog title

        DEFINE_POINT pt0, 5, 22

        DEFINE_POINT line1_pt1, 5, 20
        DEFINE_POINT line1_pt2, winfo::kWidth - 5, 20
        DEFINE_POINT line2_pt1, 5, winfo::kHeight - 20
        DEFINE_POINT line2_pt2, winfo::kWidth - 5, winfo::kHeight - 20

;;; Position of entries box
        DEFINE_POINT pos_entry_base, 16, 30

;;; Point used when rendering entries
        DEFINE_POINT pos_entry_str, 0, 0

        DEFINE_RECT_SZ rect_entry_base, 16, 22, kEntryPickerItemWidth, kEntryPickerItemHeight - 1

        DEFINE_RECT rect_entry, 0, 0, 0, 0

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

        DEFINE_SET_MARK_PARAMS set_mark_overlay1_params, kOverlay1Offset
        DEFINE_SET_MARK_PARAMS set_mark_overlay2_params, kOverlay2Offset
        DEFINE_READ_PARAMS read_overlay1_params, OVERLAY_ADDR, kOverlay1Size
        DEFINE_READ_PARAMS read_overlay2_params, OVERLAY_ADDR, kOverlay2Size
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

num_run_list_entries:
        .byte   0
num_other_run_list_entries:
        .byte   0

L9129:  .byte   0

not_iigs_flag:                  ; high bit set unless IIgs
        .byte   0

lcm_eve_flag:                   ; high bit set if Le Chat Mauve Eve present
        .byte   0

;;; ============================================================
;;; Clock Resources

        DEFINE_POINT pos_clock, 475, 10

str_time:
        PASCAL_STRING "00:00 XM" ; do not localize

str_4_spaces:
        PASCAL_STRING "    "    ; do not localize

dow_strings:
        .byte   .sprintf("%4s", res_string_weekday_abbrev_1)
        .byte   .sprintf("%4s", res_string_weekday_abbrev_2)
        .byte   .sprintf("%4s", res_string_weekday_abbrev_3)
        .byte   .sprintf("%4s", res_string_weekday_abbrev_4)
        .byte   .sprintf("%4s", res_string_weekday_abbrev_5)
        .byte   .sprintf("%4s", res_string_weekday_abbrev_6)
        .byte   .sprintf("%4s", res_string_weekday_abbrev_7)
        ASSERT_RECORD_TABLE_SIZE dow_strings, 7, 4

.params dow_str_params
addr:   .addr   0
length: .byte   4               ; includes trailing space
.endparams

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
.proc app_init
        cli

        sec
        jsr     IDROUTINE       ; clear C if IIgs
        ror     not_iigs_flag   ; rotate C into high bit

        jsr     DetectLeChatMauveEve
        bne     :+
        copy    #$80, lcm_eve_flag
:

        copy    #$FF, selected_index
        jsr     load_selector_list
        copy    #1, L9129
        lda     num_other_run_list_entries
        ora     num_run_list_entries
        bne     check_key_down

quick_run_desktop:
        MLI_CALL GET_FILE_INFO, get_file_info_desktop2_params
        beq     :+
        jmp     done_keys
:       jmp     run_desktop

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
        cmp     num_run_list_entries
        bcs     done_keys
        sta     selected_index
        jsr     get_selector_list_entry_addr

        entry_ptr := $06

        stax    entry_ptr
        ldy     #kSelectorEntryFlagsOffset
        lda     (entry_ptr),y
        cmp     #kSelectorEntryCopyNever
        beq     :+
        jsr     GetCopiedToRAMCardFlag
        beq     done_keys
        jsr     get_selected_index_file_info
        beq     :+
        jmp     done_keys

:       lda     selected_index
        jsr     invoke_entry

        ;; --------------------------------------------------

done_keys:
        sta     KBDSTRB
        copy    #0, L9129

        ;; --------------------------------------------------

        jsr     disconnect_ramdisk

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

        MGTK_CALL MGTK::StartDeskTop, startdesktop_params
        jsr     SetRGBMode
        MGTK_CALL MGTK::SetMenu, menu
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
        jsr     get_port_and_draw_window
        copy    #$FF, selected_index
        jsr     load_selector_list
        jsr     populate_entries_flag_table
        jsr     draw_entries
        jmp     event_loop

quick_boot_slot:
        .byte   0
.endproc

;;; ============================================================
;;; Event Loop

.proc event_loop
        jsr     yield_loop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     handle_button_down
        jmp     event_loop

:       cmp     #MGTK::EventKind::key_down
        bne     not_key

        ;; --------------------------------------------------
        ;; Key Down

        bit     desktop_available_flag
        bmi     not_desktop
        lda     event_key
        cmp     #kShortcutRunDeskTop
        beq     :+
        cmp     #TO_LOWER(kShortcutRunDeskTop)
        bne     not_desktop

:       lda     winfo::window_id
        jsr     get_window_port
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, desktop_button_rect
        MGTK_CALL MGTK::PaintRect, desktop_button_rect
@retry: MLI_CALL GET_FILE_INFO, get_file_info_desktop2_params
        beq     :+
        lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        bne     event_loop      ; `kAlertResultCancel` = 1
        beq     @retry          ; `kAlertResultTryAgain` = 0
:       jmp     run_desktop

not_desktop:
        jsr     handle_key
        jmp     event_loop

        ;; --------------------------------------------------

not_key:
        cmp     #MGTK::EventKind::update
        bne     not_update
        jsr     handle_updates

not_update:
        jmp     event_loop
.endproc

;;; ============================================================
;;; Handle update events

check_and_handle_updates:
        MGTK_CALL MGTK::PeekEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::update
        bne     done
        MGTK_CALL MGTK::GetEvent, event_params
        ;; Fall through.

handle_updates:
        jsr     @do_update
        jmp     check_and_handle_updates

@do_update:
        MGTK_CALL MGTK::BeginUpdate, beginupdate_params
        bne     done
        jsr     draw_window_and_entries
        MGTK_CALL MGTK::EndUpdate
        rts

done:   rts

;;; ============================================================

.proc draw_window_and_entries
        jsr     draw_window
        jsr     draw_entries
        rts
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
menu2:  .addr   cmd_run_a_program

        ;; Startup menu
menu3:  .addr   cmd_startup
        .addr   cmd_startup
        .addr   cmd_startup
        .addr   cmd_startup
        .addr   cmd_startup
        .addr   cmd_startup
        .addr   cmd_startup
menu_end:

menu_addr_table:
        .byte   menu1 - menu_dispatch_table
        .byte   menu2 - menu_dispatch_table
        .byte   menu3 - menu_dispatch_table
        .byte   menu_end - menu_dispatch_table

;;; ============================================================

.proc handle_key
        lda     event_modifiers
        bne     has_modifiers
        lda     event_key
        cmp     #CHAR_ESCAPE
        beq     menukey

other:  jmp     handle_nonmenu_key

has_modifiers:
        lda     event_key
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
        lda     event_modifiers
        beq     :+
        lda     #1
:       sta     menu_params::key_mods
        MGTK_CALL MGTK::MenuKey, menu_params::menu_id
        ;; Fall through
.endproc

;;; ==================================================

.proc handle_menu
        ldx     menu_params::menu_item
        beq     L93BE
        ldx     menu_params::menu_id
        bne     L93C1
L93BE:  jmp     event_loop

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

.proc cmd_run_a_program
        lda     selected_index
        bmi     L93FF
        jsr     maybe_toggle_entry_hilite
        lda     #$FF
        sta     selected_index
L93FF:  jsr     set_watch_cursor
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
L943F:  jsr     load_selector_list
        rts

L9443:  lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        bne     :+           ; `kAlertResultCancel` = 1
        jsr     set_watch_cursor
        jmp     L93FF

:       rts
.endproc

;;; ============================================================

.proc handle_button_down
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     :+
        rts

:       cmp     #MGTK::Area::menubar
        bne     :+
        MGTK_CALL MGTK::MenuSelect, menu_params
        jmp     handle_menu

:       cmp     #MGTK::Area::content
        beq     :+
        rts

:       lda     findwindow_window_id
        cmp     winfo::window_id
        beq     :+
        rts

:       lda     winfo::window_id
        jsr     get_window_port
        lda     winfo::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx

        ;; OK button?

        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_desktop_btn

        ldy     winfo::window_id
        ldax    #ok_button_rect
        jsr     ButtonEventLoop
        bmi     done
        jsr     try_invoke_selected_index
done:   rts

        ;; DeskTop button?

check_desktop_btn:
        bit     desktop_available_flag
        bmi     check_entries
        MGTK_CALL MGTK::InRect, desktop_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_entries

        ldy     winfo::window_id
        ldax    #desktop_button_rect
        jsr     ButtonEventLoop
        bmi     done

@retry: MLI_CALL GET_FILE_INFO, get_file_info_desktop2_params
        beq     :+
        lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        bne     done            ; `kAlertResultCancel` = 1
        beq     @retry          ; `kAlertResultTryAgain` = 0
:       jmp     run_desktop

        ;; Entry selection?

check_entries:
        sub16   entry_click_x, pos_entry_base::xcoord, entry_click_x
        sub16   entry_click_y, pt0::ycoord, entry_click_y
        lda     entry_click_y+1
        bpl     :+
        lda     selected_index
        jsr     maybe_toggle_entry_hilite
        copy    #$FF, selected_index
        rts

:       ldax    entry_click_y
        ldy     #kEntryPickerItemHeight
        jsr     Divide_16_8_16
        cmp     #8              ; only care about low byte in A
        bcc     L954C
        lda     selected_index
        jsr     maybe_toggle_entry_hilite
        copy    #$FF, selected_index
        rts

L954C:  sta     L959D
        lda     #$00
        sta     L959F
        asl16   entry_click_x
        rol     L959F
        lda     entry_click_x+1
        asl     a               ; *= 8
        asl     a
        asl     a
        clc
        adc     L959D
        sta     L959E
        cmp     #$08
        bcc     L9571
        jmp     L9582

L9571:  cmp     num_run_list_entries
        bcc     finish
        lda     selected_index
        jsr     maybe_toggle_entry_hilite
        copy    #$FF, selected_index
        rts

L9582:  sec
        sbc     #8
        cmp     num_other_run_list_entries
        bcc     finish
        lda     selected_index
        jsr     maybe_toggle_entry_hilite
        copy    #$FF, selected_index
        rts

finish: lda     L959E
        jsr     handle_entry_click
        rts

L959D:  .byte   0
L959E:  .byte   0
L959F:  .byte   0

.endproc

;;; ============================================================

noop:   rts

;;; ============================================================

.proc run_desktop
        ;; DeskTop will immediately disconnect RAMDisk, but it is
        ;; restored differently.
        jsr     reconnect_ramdisk
        MLI_CALL OPEN, open_desktop2_params
        lda     open_desktop2_params::ref_num
        sta     read_desktop2_params::ref_num
        sta     DHIRESOFF
        sta     TXTCLR
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        MLI_CALL READ, read_desktop2_params
        MLI_CALL CLOSE, close_params
        jmp     desktop_load_addr
.endproc

;;; ============================================================

.proc handle_nonmenu_key

        lda     winfo::window_id
        jsr     get_window_port
        lda     event_key
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
        cmp     num_run_list_entries
        bcc     :+
        rts

:       lda     selected_index
        bmi     no_cur_sel
        cmp     tentative_selection
        bne     :+
        rts

:       lda     selected_index
        jsr     maybe_toggle_entry_hilite
no_cur_sel:
        lda     tentative_selection
        sta     selected_index
        jsr     maybe_toggle_entry_hilite
        rts

        ;; --------------------------------------------------
        ;; Control characters - return and arrows

        ;; Return ?

control_char:
        cmp     #CHAR_RETURN
        bne     not_return
        lda     winfo::window_id
        jsr     get_window_port
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        jsr     try_invoke_selected_index
        rts
not_return:

        ;; --------------------------------------------------
        ;; Arrow keys?

        cmp     #CHAR_LEFT
        bne     :+
        jmp     handle_key_left

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     handle_key_right

:       cmp     #CHAR_DOWN
        bne     :+
        jmp     handle_key_down

:       cmp     #CHAR_UP
        bne     :+
        jmp     handle_key_up

:       rts

;;; ============================================================


tentative_selection:
        .byte   0


;;; ============================================================

.proc handle_key_right
        lda     num_run_list_entries
        ora     num_other_run_list_entries
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
        jsr     maybe_toggle_entry_hilite

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
        jsr     maybe_toggle_entry_hilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc handle_key_left
        lda     num_run_list_entries
        ora     num_other_run_list_entries
        beq     done

        lda     selected_index
        bpl     move            ; have a selection

        ;; No selection - re-use logic to find last item
        jmp     handle_key_up

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     maybe_toggle_entry_hilite

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
        jsr     maybe_toggle_entry_hilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc handle_key_up
        lda     num_run_list_entries
        ora     num_other_run_list_entries
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
        jsr     maybe_toggle_entry_hilite

        ldx     selected_index
loop:   dex                     ; to previous
        bmi     wrap
        lda     entries_flag_table,x
        bpl     set
        jmp     loop

wrap:   ldx     #kSelectorListNumEntries
        jmp     loop

set:    sta     selected_index
        jsr     maybe_toggle_entry_hilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc handle_key_down
        lda     num_run_list_entries
        ora     num_other_run_list_entries
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
        jsr     maybe_toggle_entry_hilite

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
        jsr     maybe_toggle_entry_hilite

done:   return  #$FF
.endproc

;;; ============================================================

.endproc

;;; ============================================================

.proc populate_entries_flag_table
        ldx     #kSelectorListNumEntries - 1
        lda     #$FF
:       sta     entries_flag_table,x
        dex
        bpl     :-

        ldx     #0
:       cpx     num_run_list_entries
        beq     :+
        txa
        sta     entries_flag_table,x
        inx
        bne     :-

:       ldx     #0
:       cpx     num_other_run_list_entries
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

.proc try_invoke_selected_index
        lda     selected_index
        bmi     :+
        jsr     invoke_entry
:       rts
.endproc

;;; ============================================================

.proc draw_entries

        ;; Run List
        lda     #0
        sta     count
:       lda     count
        cmp     num_run_list_entries
        beq     :+
        jsr     draw_list_entry
        inc     count
        jmp     :-

        ;; Other Run List
:       lda     #0
        sta     count
:       lda     count
        cmp     num_other_run_list_entries
        beq     done
        clc
        adc     #8
        jsr     draw_list_entry
        inc     count
        jmp     :-

done:   rts

count:  .byte   0
.endproc

;;; ============================================================

.proc load_selector_list
        ;; Initialize the counts, in case load fails.
        lda     #0
        sta     selector_list + kSelectorListNumRunListOffset
        sta     selector_list + kSelectorListNumOtherListOffset

        MLI_CALL OPEN, open_selector_list_params
        bne     cache

        lda     open_selector_list_params::ref_num
        sta     read_selector_list_params::ref_num
        MLI_CALL READ, read_selector_list_params
        MLI_CALL CLOSE, close_params

cache:  copy    selector_list + kSelectorListNumRunListOffset, num_run_list_entries
        copy    selector_list + kSelectorListNumOtherListOffset, num_other_run_list_entries
        rts
.endproc

;;; ============================================================

.proc load_overlay2
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
        beq     start           ; `kAlertResultTryAgain` = 0
        rts
.endproc

;;; ============================================================

.proc set_watch_cursor
        MGTK_CALL MGTK::SetCursor, watch_cursor
        rts
.endproc

.proc set_pointer_cursor
        MGTK_CALL MGTK::SetCursor, pointer_cursor
        rts
.endproc

;;; ============================================================

;;; Disconnect /RAM
.proc disconnect_ramdisk
        ldx     DEVCNT
:       lda     DEVLST,x
        and     #%11110000      ; DSSSnnnn
        cmp     #$B0            ; Slot 3, Drive 2 = /RAM
        beq     remove
        dex
        bpl     :-
        rts

remove: lda     DEVLST,x
        sta     saved_ram_unitnum

        ;; Shift other devices down
shift:  lda     DEVLST+1,x
        sta     DEVLST,x
        cpx     DEVCNT
        beq     done
        inx
        jmp     shift

done:   dec     DEVCNT
        rts
.endproc

;;; Restore /RAM
.proc reconnect_ramdisk
        lda     saved_ram_unitnum
        beq     done

        inc     DEVCNT
        ldx     DEVCNT
        sta     DEVLST,x

done:   rts
.endproc

saved_ram_unitnum:
        .byte   0

;;; ============================================================

get_port_and_draw_window:
        lda     winfo::window_id
        jsr     get_window_port
        ;; Fall through

.proc draw_window
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::SetPenSize, setpensize_params

        MGTK_CALL MGTK::FrameRect, rect_frame
        MGTK_CALL MGTK::FrameRect, ok_button_rect

        bit     desktop_available_flag
        bmi     :+
        MGTK_CALL MGTK::FrameRect, desktop_button_rect
:
        param_call draw_title_string, str_selector_title
        jsr     draw_ok_label
        bit     desktop_available_flag
        bmi     :+
        jsr     draw_desktop_label
:
        MGTK_CALL MGTK::MoveTo, line1_pt1
        MGTK_CALL MGTK::LineTo, line1_pt2
        MGTK_CALL MGTK::MoveTo, line2_pt1
        MGTK_CALL MGTK::LineTo, line2_pt2
        rts
.endproc

;;; ============================================================

.proc draw_ok_label
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call DrawString, ok_button_label
        rts
.endproc

.proc draw_desktop_label
        MGTK_CALL MGTK::MoveTo, desktop_button_pos
        param_call DrawString, desktop_button_label
        rts
.endproc

;;; ============================================================
;;; Draw Title String (centered at top of port)
;;; Input: A,X = string address

.proc draw_title_string
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
        and     #CHAR_MASK
        cmp     #'/'
        beq     L99FA
        cmp     #'.'
        bne     L99FE
L99FA:  dey
        jmp     loop

        ;; Adjust case
L99FE:  iny
        lda     (ptr),y
        and     #CHAR_MASK
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

.proc get_window_port
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport
        rts
.endproc

;;; ============================================================
;;; Input: A = Entry number
;;; Output: A,X = Entry address

.proc get_selector_list_entry_addr
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

.proc get_selector_list_path_addr
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

.proc set_entry_text_pos

        pha                     ; stack has index
        lsr     a
        lsr     a
        lsr     a
        pha                     ; ... and index / 8 (= column)

        ;; X coordinate
        ldx     #0
        stx     tmp
        lsr     a
        ror     tmp
        tay
        lda     tmp
        clc
        adc     pos_entry_base::xcoord
        sta     pos_entry_str::xcoord
        tya
        adc     pos_entry_base::xcoord+1
        sta     pos_entry_str::xcoord+1

        ;; Y coordinate
        pla                     ; A = column

        asl     a
        asl     a
        asl     a
        sta     tmp
        pla                     ; A = index
        sec
        sbc     tmp             ; A = row

        ldx     #0
        ldy     #kEntryPickerItemHeight
        jsr     Multiply_16_8_16
        addax   pos_entry_base::ycoord, pos_entry_str::ycoord
        rts

tmp:    .byte   0
.endproc

;;; ============================================================
;;; Input: A = entry number

.proc draw_list_entry
        ptr := $06

        pha
        jsr     get_selector_list_entry_addr
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
common: lda     winfo::window_id
        jsr     get_window_port
        pla
        jsr     set_entry_text_pos
        MGTK_CALL MGTK::MoveTo, pos_entry_str
        param_call DrawString, entry_string_buf
        rts
.endproc

;;; ============================================================
;;; Input: A = clicked entry

.proc handle_entry_click
        cmp     selected_index  ; same as previous selection?
        beq     :+
        pha
        lda     selected_index
        jsr     maybe_toggle_entry_hilite ; un-highlight old entry
        pla
        sta     selected_index
        jsr     maybe_toggle_entry_hilite ; highlight new entry
:

        jsr     DetectDoubleClick
        bne     :+

        jmp     invoke_entry

:       rts

.endproc

;;; ============================================================
;;; Toggle the highlight on an entry in the list
;;; Input: A = entry number

.proc maybe_toggle_entry_hilite
        bpl     :+
        rts

:       pha

        lsr     a
        lsr     a
        lsr     a
        sta     col      ; col

        asl     a
        asl     a
        asl     a
        sta     tmp

        pla
        sec
        sbc     tmp
        sta     row

        lda     #0
        sta     tmp
        lda     col
        lsr     a
        ror     tmp
        pha

        ;; X coords
        lda     tmp
        clc
        adc     rect_entry_base::x1
        sta     rect_entry::x1
        pla
        pha
        adc     rect_entry_base::x1+1
        sta     rect_entry::x1+1
        lda     tmp
        clc
        adc     rect_entry_base::x2
        sta     rect_entry::x2
        pla
        adc     rect_entry_base::x2+1
        sta     rect_entry::x2+1

        ;; Y coords
        lda     row
        ldx     #0
        ldy     #kEntryPickerItemHeight
        jsr     Multiply_16_8_16
        stax    tmp
        addax   rect_entry_base::y1, rect_entry::y1
        add16   tmp, rect_entry_base::y2, rect_entry::y2

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect_entry

        rts

tmp:    .word   0
row:    .byte   0
col:    .byte   0
.endproc

;;; ============================================================

.proc cmd_startup
        ldy     menu_params::menu_item
        lda     slot_table,y
        ora     #>$C000         ; compute $Cn00
        sta     @addr+1
        lda     #<$C000
        sta     @addr

        sta     ALTZPOFF
        lda     ROMIN2
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR
        sta     DHIRESOFF
        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80COL
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME

        @addr := * + 1
        jmp     SELF_MODIFIED
.endproc

;;; ============================================================

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_invoke_params, INVOKER_PREFIX

.proc invoke_entry
        lda     L9129
        bne     :+
        jsr     set_watch_cursor
        lda     selected_index
        bmi     :+
        jsr     maybe_toggle_entry_hilite
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
        jsr     get_selector_list_entry_addr
        stax    $06
        ldy     #kSelectorEntryFlagsOffset
        lda     ($06),y
        asl     a
        bmi     L9C78           ; bit 6 (now 7) = never copy
        bcc     L9C65           ; bit 8 (now C) = copy on boot

        ;; Copy on boot
        lda     L9129
        bne     L9C6F
        jsr     get_selected_index_file_info
        beq     L9C6F
        jsr     load_overlay2
        lda     selected_index
        jsr     file_copier_exec
        pha
        jsr     check_and_handle_updates
        pla
        beq     L9C6F
        jsr     set_pointer_cursor
        jmp     clear_selected_index

L9C65:  lda     L9129
        bne     L9C6F
        jsr     get_selected_index_file_info
        bne     L9C78
L9C6F:  lda     selected_index
        jsr     compose_dst_path
        jmp     L9C7E

        ;; --------------------------------------------------

L9C78:  lda     selected_index
        jsr     get_selector_list_path_addr
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
        bne     fail            ; `kAlertResultCancel` = 1
        jsr     set_watch_cursor
        jmp     L9C78

fail:   jmp     clear_selected_index

        ;; --------------------------------------------------
        ;; Check file type

        ;; Ensure it's BIN, SYS, S16 or BAS (if BS is present)

check_type:
        lda     get_file_info_invoke_params::file_type
        cmp     #FT_BASIC
        bne     not_basic
        jsr     check_basic_system
        jeq     check_path

        lda     #AlertID::basic_system_not_found
        jsr     ShowAlert
        jmp     clear_selected_index

not_basic:
        cmp     #FT_BINARY
        beq     check_path
        cmp     #FT_SYSTEM
        beq     check_path
        cmp     #FT_S16
        beq     check_path

        jsr     check_basis_system ; Is fallback BASIS.SYSTEM present?
        beq     check_path

        ;; Don't know how to invoke
        lda     #AlertID::selector_unable_to_run
        jsr     ShowAlert
        jmp     clear_selected_index

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
        bne     clear_selected_index ; `kAlertResultCancel` = 1
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
        param_call upcase_string, INVOKER_PREFIX
        param_call upcase_string, INVOKER_FILENAME

        ;; --------------------------------------------------
        ;; Invoke

        jsr     reconnect_ramdisk
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        sta     DHIRESOFF
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR
        sta     CLRALTCHAR
        jsr     SetColorMode
        sta     CLR80VID
        sta     CLR80COL

        jsr     INVOKER

        ;; If we got here, invoker failed somehow. Relaunch.
        jsr     Bell
        jsr     Bell
        jsr     Bell
        MLI_CALL QUIT, quit_params
        brk

.endproc
        invoke_entry_ep2 := invoke_entry::ep2

        DEFINE_QUIT_PARAMS quit_params

.proc clear_selected_index
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
        PASCAL_STRING "BASIx.SYSTEM" ; do not localize

.proc check_basix_system_impl
        launch_path := INVOKER_PREFIX
        path_buf := $1C00

basic:  lda     #'C'            ; "BASI?" -> "BASIC"
        bne     start           ; always

basis:  lda     #'S'            ; "BASI?" -> "BASIS"
        ;; fall through

start:  sta     str_basix_system + kBSOffset

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
        check_basic_system := check_basix_system_impl::basic
        check_basis_system := check_basix_system_impl::basis

;;; ============================================================
;;; Uppercase a string
;;; Input: A,X = Address

.proc upcase_string
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

.proc get_selected_index_file_info
        ptr := $06

        lda     selected_index
        jsr     compose_dst_path
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

        .include "../lib/buttonloop.s"

;;; ============================================================

;;; NOTE: Can't use "../lib/ramcard.s" since the calling code is
;;; not running w/ AUXZP and LCBANK1.

.proc GetCopiedToRAMCardFlag
        lda     LCBANK2
        lda     LCBANK2
        lda     COPIED_TO_RAMCARD_FLAG
        tax
        lda     ROMIN2
        txa
        rts
.endproc

.proc CopyRAMCardPrefix
        stax    @addr
        lda     LCBANK2
        lda     LCBANK2
        ldx     RAMCARD_PREFIX
:       lda     RAMCARD_PREFIX,x
        @addr := * + 1
        sta     SELF_MODIFIED,x
        dex
        bpl     :-
        lda     ROMIN2
        rts
.endproc

;;; ============================================================

.proc compose_dst_path
        buf := $800

        sta     tmp
        param_call CopyRAMCardPrefix, buf
        lda     tmp
        jsr     get_selector_list_path_addr

        path_addr := $06

        stax    path_addr
        ldy     #0
        lda     (path_addr),y
        sta     len
        tay
:       lda     (path_addr),y
        and     #CHAR_MASK
        cmp     #'/'
        beq     :+
        dey
        bne     :-

:       dey
:       lda     (path_addr),y
        and     #CHAR_MASK
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
        lda     LCBANK1
        lda     LCBANK1
        txa
        jsr     AlertById
        tax
        sta     ALTZPOFF
        lda     ROMIN2
        txa
        rts
.endproc

;;; ============================================================
;;; Assert: ROM is banked in

.proc SetRGBMode
        bit     SETTINGS + DeskTopSettings::rgb_color
        bmi     SetColorMode
        bpl     SetMonoMode
.endproc

.proc SetColorMode
        ;; IIgs?
        sec
        jsr     IDROUTINE
        bcc     iigs

        ;; AppleColor Card - Mode 2 (Color 140x192)
        ;; Also: Video-7 and Le Chat Mauve Feline
        sta     SET80VID
        lda     AN3_OFF
        lda     AN3_ON
        lda     AN3_OFF
        lda     AN3_ON
        lda     AN3_OFF

        ;; Le Chat Mauve Eve - COL140 mode
        ;; (AN3 off, HR1 off, HR2 off, HR3 off)
        ;; Skip on IIgs since emulators (KEGS/GSport/GSplus) crash.
        ;; lda AN3_OFF ; already done above
        bit     lcm_eve_flag
        bpl     done
        sta     HR2_OFF
        sta     HR3_OFF
        bmi     done            ; always

        ;; Apple IIgs - DHR Color
iigs:   lda     NEWVIDEO
        and     #<~(1<<5)       ; Color
        sta     NEWVIDEO

done:   rts
.endproc

.proc SetMonoMode
        ;; IIgs?
        sec
        jsr     IDROUTINE
        bcc     iigs

        ;; AppleColor Card - Mode 1 (Monochrome 560x192)
        ;; Also: Video-7 and Le Chat Mauve Feline
        sta     CLR80VID
        lda     AN3_OFF
        lda     AN3_ON
        lda     AN3_OFF
        lda     AN3_ON
        sta     SET80VID
        lda     AN3_OFF

        ;; Le Chat Mauve Eve - BW560 mode
        ;; (AN3 off, HR1 off, HR2 on, HR3 on)
        ;; Skip on IIgs since emulators (KEGS/GSport/GSplus) crash.
        ;; lda AN3_OFF ; already done above
        bit     lcm_eve_flag
        bpl     done
        sta     HR2_ON
        sta     HR3_ON
        bmi     done            ; always

        ;; Apple IIgs - DHR B&W
iigs:   lda     NEWVIDEO
        ora     #(1<<5)         ; B&W
        sta     NEWVIDEO

done:   rts
.endproc


;;; ============================================================
;;; On IIgs, force preferred RGB mode. No-op otherwise.

.proc reset_iigs_rgb
        bit     not_iigs_flag
        bmi     done

        bit     SETTINGS + DeskTopSettings::rgb_color
        bmi     color

mono:   lda     NEWVIDEO
        ora     #(1<<5)         ; B&W
        sta     NEWVIDEO
        rts

color:  lda     NEWVIDEO
        and     #<~(1<<5)        ; Color
        sta     NEWVIDEO

done:   rts
.endproc

;;; ============================================================
;;; Called by main and nested event loops to do periodic tasks.
;;; Returns 0 if the periodic tasks were run.

.proc yield_loop
        kMaxCounter = $E0       ; arbitrary

        inc     loop_counter
        inc     loop_counter
        lda     loop_counter
        cmp     #kMaxCounter
        bcc     :+
        copy    #0, loop_counter

        jsr     show_clock
        jsr     reset_iigs_rgb ; in case it was reset by control panel

:       lda     loop_counter
        rts

loop_counter:
        .byte   0
.endproc

;;; ============================================================

;;; ============================================================

.proc show_clock
        lda     MACHID
        and     #1              ; bit 0 = clock card
        bne     :+
        rts

:       MLI_CALL GET_TIME, 0

        ;; Changed?
        ldx     #.sizeof(DateTime)-1
:       lda     DATELO,x
        cmp     last_dt,x
        bne     :+
        dex
        bpl     :-
        lda     SETTINGS + DeskTopSettings::clock_24hours
        cmp     last_s
        bne     :+
        rts

:       COPY_STRUCT DateTime, DATELO, last_dt
        copy    SETTINGS + DeskTopSettings::clock_24hours, last_s

        ;; --------------------------------------------------
        ;; Save the current GrafPort and use a custom one for drawing

        MGTK_CALL MGTK::GetPort, getport_params
        MGTK_CALL MGTK::InitPort, clock_grafport
        MGTK_CALL MGTK::SetPort, clock_grafport

        MGTK_CALL MGTK::MoveTo, pos_clock

        ;; --------------------------------------------------
        ;; Day of Week

        copy16  #parsed_date, $0A
        ldax    #DATELO
        jsr     parse_datetime

        ;; TODO: Make DOW calc work on ParsedDateTime
        sub16   parsed_date + ParsedDateTime::year, #1900, parsed_date + ParsedDateTime::year
        ldy     parsed_date + ParsedDateTime::year
        ldx     parsed_date + ParsedDateTime::month
        lda     parsed_date + ParsedDateTime::day
        jsr     day_of_week
        asl                     ; * 4
        asl
        clc
        adc     #<dow_strings
        sta     dow_str_params::addr
        lda     #0
        adc     #>dow_strings
        sta     dow_str_params::addr+1
        MGTK_CALL MGTK::DrawText, dow_str_params

        ;; --------------------------------------------------
        ;; Time

        ldax    #parsed_date
        jsr     make_time_string

        param_call DrawString, str_time
        param_call DrawString, str_4_spaces ; in case it got shorter

        ;; --------------------------------------------------
        ;; Restore the previous GrafPort

        copy16  getport_params::portptr, @addr
        MGTK_CALL MGTK::SetPort, 0, @addr

last_dt:
        .tag    DateTime        ; previous date/time
last_s: .byte   0               ; previous settings
.endproc

;;; ============================================================

        .include "../lib/datetime.s"
        .include "../lib/doubleclick.s"
        .include "../lib/drawstring.s"
        .include "../lib/muldiv.s"
        .include "../lib/bell.s"
        .include "../lib/detect_lcmeve.s"

.endscope

        PAD_TO OVERLAY_ADDR
