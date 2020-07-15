;;; ============================================================
;;; DeskTop - Main Memory Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into MAIN $4000-$BEFF
;;; ============================================================

.proc main

dst_path_buf   := $1FC0

        .org $4000

        ;; Jump table
        ;; Entries marked with * are used by DAs
        ;; "Exported" by desktop.inc

JT_MAIN_LOOP:           jmp     main_loop
JT_MGTK_RELAY:          jmp     MGTK_RELAY              ; *
JT_SIZE_STRING:         jmp     compose_blocks_string
JT_DATE_STRING:         jmp     compose_date_string
JT_SELECT_WINDOW:       jmp     select_and_refresh_window
JT_AUXLOAD:             jmp     AuxLoad
JT_EJECT:               jmp     cmd_eject
JT_REDRAW_WINDOWS:      jmp     redraw_windows          ; *
JT_ITK_RELAY:           jmp     ITK_RELAY
JT_LOAD_OVL:            jmp     load_dynamic_routine
JT_CLEAR_SELECTION:     jmp     clear_selection
JT_MLI_RELAY:           jmp     MLI_RELAY               ; *
JT_COPY_TO_BUF:         jmp     LoadWindowIconTable
JT_COPY_FROM_BUF:       jmp     StoreWindowIconTable
JT_NOOP:                jmp     cmd_noop
JT_FILE_TYPE_STRING:    jmp     compose_file_type_string
JT_SHOW_ALERT0:         jmp     ShowAlert
JT_SHOW_ALERT:          jmp     ShowAlertOption         ; *
JT_LAUNCH_FILE:         jmp     launch_file
JT_CUR_POINTER:         jmp     set_cursor_pointer      ; *
JT_CUR_WATCH:           jmp     set_cursor_watch        ; *
JT_RESTORE_OVL:         jmp     restore_dynamic_routine
JT_COLOR_MODE:          jmp     set_color_mode          ; *
JT_MONO_MODE:           jmp     set_mono_mode           ; *
JT_RESTORE_SYS:         jmp     restore_system          ; *
JT_REDRAW_ALL:          jmp     redraw_windows_and_desktop ; *
JT_GET_SEL_COUNT:       jmp     get_selection_count     ; *
JT_GET_SEL_ICON:        jmp     get_selected_icon       ; *
JT_GET_SEL_WIN:         jmp     get_selection_window    ; *
JT_GET_WIN_PATH:        jmp     get_window_path         ; *
JT_HILITE_MENU:         jmp     toggle_menu_hilite      ; *
JT_ADJUST_FILEENTRY:    jmp     adjust_fileentry_case   ; *
JT_CUR_IBEAM:           jmp     set_cursor_ibeam        ; *
        .assert JUMP_TABLE_MAIN_LOOP = JT_MAIN_LOOP, error, "Jump table mismatch"
        .assert JUMP_TABLE_CUR_IBEAM = JT_CUR_IBEAM, error, "Jump table mismatch"

        ;; Main Loop
.proc main_loop
        jsr     reset_main_grafport

        inc     loop_counter
        inc     loop_counter
        lda     loop_counter
        cmp     machine_type    ; for per-machine timing
        bcc     :+
        copy    #0, loop_counter

        jsr     show_clock
        jsr     force_iigs_mono ; in case it was reset by control panel

        ;; Poll drives for updates
        jsr     check_disk_inserted_ejected
        beq     :+
        jsr     check_drive           ; conditionally ???

:       jsr     update_menu_item_states

        ;; Get an event
        jsr     get_event
        lda     event_kind

        ;; Is it a button-down event? (including w/ modifiers)
        cmp     #MGTK::EventKind::button_down
        beq     click
        cmp     #MGTK::EventKind::apple_key
        bne     :+
click:  jsr     handle_click
        jmp     main_loop

        ;; Is it a key down event?
:       cmp     #MGTK::EventKind::key_down
        bne     :+
        jsr     handle_keydown
        jmp     main_loop

        ;; Is it an update event?
:       cmp     #MGTK::EventKind::update
        bne     :+
        jsr     reset_main_grafport
        copy    active_window_id, saved_active_window_id
        copy    #$80, redraw_icons_flag
        jsr     handle_update

:       jmp     main_loop

loop_counter:
        .byte   0

;;; --------------------------------------------------

.proc check_drive
        tsx
        stx     saved_stack
        sta     menu_click_params::item_num
        jsr     cmd_check_single_drive_by_menu
        copy    #0, menu_click_params::item_num
        rts
.endproc

saved_active_window_id:
        .byte   0

redraw_icons_flag:
        .byte   0

;;; --------------------------------------------------

redraw_windows:
        jsr     reset_main_grafport
        copy    active_window_id, saved_active_window_id
        copy    #0, redraw_icons_flag

redraw_loop:
        jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::update
        bne     finish
        jsr     get_event

handle_update:
        jsr     update
        jmp     redraw_loop

update: MGTK_RELAY_CALL MGTK::BeginUpdate, event_window_id
        bne     done_redraw     ; did not really need updating
        jsr     update_window
        MGTK_RELAY_CALL MGTK::EndUpdate
        rts

finish: jsr     LoadDesktopIconTable
        lda     saved_active_window_id
        sta     active_window_id
        beq     :+
        bit     running_da_flag
        bmi     :+
        jsr     redraw_selected_icons
:       bit     redraw_icons_flag
        bpl     done_redraw
        ITK_RELAY_CALL IconTK::RedrawIcons

done_redraw:
        rts

.endproc
        redraw_windows := main_loop::redraw_windows

;;; ============================================================


draw_window_header_flag:  .byte   0


.proc update_window
        lda     event_window_id
        cmp     #kMaxNumWindows+1 ; directory windows are 1-8
        bcc     L415B
        rts

L415B:  sta     active_window_id
        jsr     LoadActiveWindowIconTable
        copy    #$80, draw_window_header_flag
        copy    cached_window_id, getwinport_params2::window_id
        jsr     get_port2
        jsr     draw_window_header
        lda     active_window_id
        jsr     copy_window_portbits
        jsr     OverwriteWindowPort
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #22
        sub16in ($06),y, window_grafport::viewloc::ycoord, L4242
        cmp16   L4242, #15
        bpl     L41CB
        jsr     offset_window_grafport

        ldx     #11
        ldy     #31
        copy    window_grafport,x, ($06),y
        dey
        dex
        copy    window_grafport,x, ($06),y

        ldx     #3
        ldy     #23
        copy    window_grafport,x, ($06),y
        dey
        dex
        copy    window_grafport,x, ($06),y

L41CB:  ldx     cached_window_id
        dex
        lda     win_view_by_table,x
        bpl     by_icon
        jsr     draw_window_entries
        copy    #0, draw_window_header_flag
        lda     active_window_id
        jmp     assign_window_portbits

by_icon:
        lda     cached_window_id
        jsr     set_port_from_window_id

        jsr     cached_icons_screen_to_window

        COPY_BLOCK window_grafport::cliprect, tmp_rect

        copy    #0, L4241
L41FE:  lda     L4241
        cmp     cached_window_icon_count
        beq     L4227
        tax
        copy    cached_window_icon_list,x, icon_param
        ITK_RELAY_CALL IconTK::IconInRect, icon_param
        beq     :+
        ITK_RELAY_CALL IconTK::RedrawIcon, icon_param
:       inc     L4241
        jmp     L41FE

L4227:  copy    #0, draw_window_header_flag

        lda     cached_window_id
        jsr     set_port_from_window_id

        jsr     cached_icons_window_to_screen
        lda     active_window_id
        jsr     assign_window_portbits
        jmp     reset_main_grafport

L4241:  .byte   0
L4242:  .word   0
.endproc

;;; ============================================================

.proc redraw_selected_icons
        lda     selected_icon_count
        bne     :+
bail:   rts

:       copy    #0, num

        lda     selected_window_index
        beq     desktop
        cmp     active_window_id
        bne     bail

        copy    active_window_id, getwinport_params2::window_id
        jsr     get_port2
        cmp     #MGTK::Error::window_obscured
        beq     done
        jsr     offset_window_grafport_and_set

        COPY_BLOCK window_grafport::cliprect, tmp_rect

        ;; Redraw selected icons in window
window: lda     num
        cmp     selected_icon_count
        beq     done
        tax
        copy    selected_icon_list,x, icon_param
        jsr     icon_screen_to_window
        ITK_RELAY_CALL IconTK::IconInRect, icon_param
        beq     :+
        ITK_RELAY_CALL IconTK::RedrawIcon, icon_param
:       lda     icon_param
        jsr     icon_window_to_screen
        inc     num
        jmp     window

done:   jmp     reset_main_grafport

        ;; Redraw selected icons on desktop
desktop:
        lda     num
        cmp     selected_icon_count
        beq     done
        tax
        copy    selected_icon_list,x, icon_param
        ITK_RELAY_CALL IconTK::RedrawIcon, icon_param
        inc     num
        jmp     desktop

num:    .byte   0
.endproc

;;; ============================================================
;;; Menu Dispatch

.proc handle_keydown_impl

        ;; Keep in sync with aux::menu_item_id_*

        ;; jump table for menu item handlers
dispatch_table:
        ;; Apple menu (1)
        menu1_start := *
        .addr   cmd_about
        .addr   cmd_noop        ; --------
        .repeat ::kMaxDeskAccCount
        .addr   cmd_deskacc
        .endrepeat
        ASSERT_ADDRESS_TABLE_SIZE menu1_start, ::kMenuSizeApple

        ;; File menu (2)
        menu2_start := *
        .addr   cmd_new_folder
        .addr   cmd_open
        .addr   cmd_close
        .addr   cmd_close_all
        .addr   cmd_select_all
        .addr   cmd_noop        ; --------
        .addr   cmd_get_info
        .addr   cmd_rename_icon
        .addr   cmd_noop        ; --------
        .addr   cmd_copy_file
        .addr   cmd_delete_file
        .addr   cmd_noop        ; --------
        .addr   cmd_quit
        ASSERT_ADDRESS_TABLE_SIZE menu2_start, ::kMenuSizeFile

        ;; Selector menu (3)
        menu3_start := *
        .addr   cmd_selector_action
        .addr   cmd_selector_action
        .addr   cmd_selector_action
        .addr   cmd_selector_action
        .addr   cmd_noop        ; --------
        .addr   cmd_selector_item
        .addr   cmd_selector_item
        .addr   cmd_selector_item
        .addr   cmd_selector_item
        .addr   cmd_selector_item
        .addr   cmd_selector_item
        .addr   cmd_selector_item
        .addr   cmd_selector_item
        ASSERT_ADDRESS_TABLE_SIZE menu3_start, ::kMenuSizeSelector

        ;; View menu (4)
        menu4_start := *
        .addr   cmd_view_by_icon
        .addr   cmd_view_by_name
        .addr   cmd_view_by_date
        .addr   cmd_view_by_size
        .addr   cmd_view_by_type
        ASSERT_ADDRESS_TABLE_SIZE menu4_start, ::kMenuSizeView

        ;; Special menu (5)
        menu5_start := *
        .addr   cmd_check_drives
        .addr   cmd_check_drive
        .addr   cmd_eject
        .addr   cmd_noop        ; --------
        .addr   cmd_format_disk
        .addr   cmd_erase_disk
        .addr   cmd_disk_copy
        .addr   cmd_noop        ; --------
        .addr   cmd_lock
        .addr   cmd_unlock
        .addr   cmd_get_size
        ASSERT_ADDRESS_TABLE_SIZE menu5_start, ::kMenuSizeSpecial

        ;; 6/7 unused
        menu6_start := *
        menu7_start := *

        ;; Startup menu (8)
        menu8_start := *
        .addr   cmd_startup_item
        .addr   cmd_startup_item
        .addr   cmd_startup_item
        .addr   cmd_startup_item
        .addr   cmd_startup_item
        .addr   cmd_startup_item
        .addr   cmd_startup_item
        ASSERT_ADDRESS_TABLE_SIZE menu8_start, ::kMenuSizeStartup

        menu_end := *

        ;; indexed by menu id-1
offset_table:
        .byte   menu1_start - dispatch_table
        .byte   menu2_start - dispatch_table
        .byte   menu3_start - dispatch_table
        .byte   menu4_start - dispatch_table
        .byte   menu5_start - dispatch_table
        .byte   menu6_start - dispatch_table
        .byte   menu7_start - dispatch_table
        .byte   menu8_start - dispatch_table
        .byte   menu_end - dispatch_table

        ;; Set if there are open windows
flag:   .byte   $00

        ;; Handle accelerator keys
handle_keydown:
        lda     event_modifiers
        bne     :+              ; either Open-Apple or Solid-Apple ?
        jmp     menu_accelerators           ; nope
:       cmp     #3              ; both Open-Apple + Solid-Apple ?
        bne     :+              ; nope
        rts

        ;; Non-menu keys
:       lda     event_key
        jsr     upcase_char
        cmp     #'H'            ; Apple-H (Highlight Icon)
        bne     :+
        jmp     cmd_highlight
:       bit     flag
        bpl     menu_accelerators
        cmp     #'G'            ; Apple-G (Resize)
        bne     :+
        jmp     cmd_resize
:       cmp     #'M'            ; Apple-M (Move)
        bne     :+
        jmp     cmd_move
:       cmp     #'X'            ; Apple-X (Scroll)
        bne     :+
        jmp     cmd_scroll
:       cmp     #CHAR_DELETE    ; Apple-Delete (Delete)
        bne     :+
        jmp     cmd_delete_selection
:       cmp     #'`'            ; Apple-` (Cycle Windows)
        beq     cycle
        cmp     #'~'            ; Shift-Apple-` (Cycle Windows)
        beq     cycle
        cmp     #CHAR_TAB       ; Apple-Tab (Cycle Windows)
        bne     menu_accelerators
cycle:  jmp     cmd_cycle_windows

menu_accelerators:
        copy    event_key, menu_click_params::which_key
        lda     event_modifiers
        beq     :+
        lda     #1
:       sta     menu_click_params::key_mods
        copy    #$80, menu_kbd_flag ; note that source is keyboard
        MGTK_RELAY_CALL MGTK::MenuKey, menu_click_params

menu_dispatch2:
        ldx     menu_click_params::menu_id
        bne     :+
        rts

:       dex                     ; x has top level menu id
        lda     offset_table,x
        tax
        ldy     menu_click_params::item_num
        dey
        tya
        asl     a
        sta     proc_addr
        txa
        clc
        adc     proc_addr
        tax
        copy16  dispatch_table,x, proc_addr
        jsr     call_proc
        MGTK_RELAY_CALL MGTK::HiliteMenu, menu_click_params
        rts

call_proc:
        tsx
        stx     saved_stack
        proc_addr := *+1
        jmp     dummy1234           ; self-modified
.endproc

        handle_keydown := handle_keydown_impl::handle_keydown
        menu_dispatch2 := handle_keydown_impl::menu_dispatch2
        menu_dispatch_flag := handle_keydown_impl::flag

;;; ============================================================
;;; Handle click

.proc handle_click
        tsx
        stx     saved_stack
        MGTK_RELAY_CALL MGTK::FindWindow, event_coords
        lda     findwindow_which_area
        bne     not_desktop

        ;; Click on desktop
        jsr     detect_double_click
        sta     double_click_flag
        copy    #0, findwindow_window_id
        ITK_RELAY_CALL IconTK::FindIcon, event_coords
        lda     findicon_which_icon
        beq     :+
        jmp     handle_volume_icon_click

:       jmp     L68AA

not_desktop:
        cmp     #MGTK::Area::menubar  ; menu?
        bne     not_menu
        copy    #0, menu_kbd_flag ; note that source is not keyboard
        MGTK_RELAY_CALL MGTK::MenuSelect, menu_click_params
        jmp     menu_dispatch2

not_menu:
        pha                     ; which window - active or not?
        lda     active_window_id
        cmp     findwindow_window_id
        beq     handle_active_window_click
        pla
        jmp     handle_inactive_window_click
.endproc

;;; ============================================================
;;; Inputs: MGTK::Area pushed to stack

.proc handle_active_window_click
        pla
        cmp     #MGTK::Area::content
        bne     :+
        jmp     handle_client_click
:       cmp     #MGTK::Area::dragbar
        bne     :+
        jmp     handle_title_click
:       cmp     #MGTK::Area::grow_box
        bne     :+
        jmp     handle_resize_click
:       cmp     #MGTK::Area::close_box
        bne     :+
        jmp     handle_close_click
:       rts
.endproc

;;; ============================================================
;;; Inputs: window_id to activate in findwindow_window_id

.proc handle_inactive_window_click
        ptr := $6

        jmp     start

winid:  .byte   0

start:  jsr     clear_selection

        ;; Select window's corresponding volume icon.
        ;; (Doesn't work for folder icons as only the active
        ;; window and desktop can have selections.)
        ldx     findwindow_window_id
        dex
        lda     window_to_dir_icon_table,x
        bmi     continue        ; $FF = dir icon freed

        sta     icon_param
        lda     icon_param
        jsr     icon_entry_lookup
        stax    ptr

        ldy     #IconEntry::state ; set state to open
        lda     (ptr),y
        beq     continue
        ora     #kIconEntryOpenMask
        sta     (ptr),y

        iny                     ; IconEntry::win_type
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        sta     winid
        jsr     prepare_highlight_grafport
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param
        jsr     reset_main_grafport
        copy    winid, selected_window_index
        copy    #1, selected_icon_count
        copy    icon_param, selected_icon_list

        ;; Actually make the window active.
continue:
        MGTK_RELAY_CALL MGTK::SelectWindow, findwindow_window_id
        copy    findwindow_window_id, active_window_id
        jsr     LoadActiveWindowIconTable
        jsr     draw_window_entries
        jsr     LoadDesktopIconTable
        copy    #MGTK::checkitem_uncheck, checkitem_params::check
        jsr     check_item
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        and     #$0F            ; mask off menu item number
        sta     checkitem_params::menu_item
        inc     checkitem_params::menu_item
        copy    #MGTK::checkitem_check, checkitem_params::check
        jsr     check_item
        rts
.endproc

;;; ============================================================

.proc offset_and_set_port_from_window_id
        sta     getwinport_params2::window_id
        jsr     get_port2
        jmp     offset_window_grafport_and_set
.endproc

.proc set_port_from_window_id
        sta     getwinport_params2::window_id
        ;; fall through
.endproc

.proc get_set_port2
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params2
        MGTK_RELAY_CALL MGTK::SetPort, window_grafport
        rts
.endproc

.proc get_port2
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params2
        rts
.endproc

;;; ============================================================

.proc redraw_windows_and_desktop
        jsr     redraw_windows
        ITK_RELAY_CALL IconTK::RedrawIcons
        rts
.endproc

;;; ============================================================
;;; Update table tracking disk-in-device status, determine if
;;; there was a change (insertion or ejection).
;;; Output: 0 if no change,

.proc check_disk_inserted_ejected
        lda     disk_in_device_table
        beq     done
        jsr     check_disks_in_devices
        ldx     disk_in_device_table
:       lda     disk_in_device_table,x
        cmp     last_disk_in_devices_table,x
        bne     changed
        dex
        bne     :-
done:   return  #0

changed:
        copy    disk_in_device_table,x, last_disk_in_devices_table,x

        lda     removable_device_table,x
        ldy     DEVCNT
:       cmp     DEVLST,y
        beq     :+
        dey
        bpl     :-
        rts

:       tya
        clc
        adc     #$03
        rts
.endproc

;;; ============================================================

kMaxRemovableDevices = ::kMaxVolumes

removable_device_table:
        .byte   0               ; num entries
        .res    kMaxRemovableDevices, 0

;;; Updated by check_disks_in_devices
disk_in_device_table:
        .byte   0               ; num entries
        .res    kMaxRemovableDevices, 0

;;; Snapshot of previous results; used to detect changes.
last_disk_in_devices_table:
        .byte   0               ; num entries
        .res    kMaxRemovableDevices, 0

;;; ============================================================

.proc check_disks_in_devices
        ptr := $6
        status_buffer := $800

        ldx     removable_device_table
        beq     done
        stx     disk_in_device_table
:       lda     removable_device_table,x
        jsr     check_disk_in_drive
        sta     disk_in_device_table,x
        dex
        bne     :-
done:   rts

check_disk_in_drive:
        sta     unit_number
        txa
        pha
        tya
        pha

        sp_addr := $0A
        lda     unit_number
        jsr     find_smartport_dispatch_address
        bne     notsp           ; not SmartPort
        stx     status_unit_num

        ;; Execute SmartPort call
        jsr     smartport_call
        .byte   $00             ; $00 = STATUS
        .addr   status_params

        lda     status_buffer
        and     #$10            ; general status byte, $10 = disk in drive
        beq     notsp
        lda     #$FF
        bne     finish

notsp:  lda     #0              ; not SmartPort (or no disk in drive)

finish: sta     result
        pla
        tay
        pla
        tax
        return  result

smartport_call:
        jmp     (sp_addr)

unit_number:
        .byte   0
result: .byte   0

        ;; params for call
.params status_params
param_count:    .byte   3
unit_num:       .byte   1
list_ptr:       .addr   status_buffer
status_code:    .byte   0
.endparams
status_unit_num := status_params::unit_num
.endproc

;;; ============================================================

.proc update_menu_item_states
        ;; Selector List
        lda     num_selector_list_items
        beq     :+

        bit     LD344
        bmi     check_selection
        jsr     enable_selector_menu_items
        jmp     check_selection

:       bit     LD344
        bmi     check_selection
        jsr     disable_selector_menu_items

check_selection:
        lda     selected_icon_count
        beq     no_selection

        ;; --------------------------------------------------
        ;; Selected Icons
        lda     selected_window_index ; In a window?
        bne     files_selected

        ;; Volumes selected (not files)
        lda     selected_icon_count
        cmp     #2
        bcs     multiple_volumes

        lda     selected_icon_list
        cmp     trash_icon_num
        bne     enable_eject
        jsr     disable_eject_menu_item
        jsr     disable_file_menu_items
        copy    #0, file_menu_items_enabled_flag
        rts

enable_eject:
        jsr     enable_eject_menu_item
        jmp     finish1

        ;; Files selected (not volumes)
files_selected:
        jsr     disable_eject_menu_item
        jmp     finish1

multiple_volumes:
        jsr     enable_eject_menu_item

finish1:
        bit     file_menu_items_enabled_flag
        bmi     :+
        jsr     enable_file_menu_items
        copy    #$80, file_menu_items_enabled_flag
:       rts

        ;; --------------------------------------------------
        ;; No Selection
no_selection:
        bit     file_menu_items_enabled_flag
        bmi     :+
        rts

:       jsr     disable_eject_menu_item
        jsr     disable_file_menu_items
        copy    #0, file_menu_items_enabled_flag
        rts
.endproc

;;; ============================================================

.proc MLI_RELAY
        sty     call
        stax    params
        sta     ALTZPOFF
        sta     ROMIN2
        jsr     MLI
call:   .byte   0
params: .addr   0
        sta     ALTZPON
        tax
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts
.endproc

;;; ============================================================
;;; Launch file (File > Open, Selector menu, or double-click)

.proc launch_file_impl
        path := $220

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, path

compose_path:
        ;; Compose window path plus icon path
        ldx     #$FF
:       inx
        copy    buf_win_path,x, path,x
        cpx     buf_win_path
        bne     :-

        inx
        copy    #'/', path,x

        ldy     #0
:       iny
        inx
        copy    buf_filename2,y, path,x
        cpy     buf_filename2
        bne     :-
        stx     path

with_path:
        jsr     set_cursor_watch

        ;; Get the file info to determine type.
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        jsr     ShowAlert
        rts

        ;; Check file type.
:       copy    get_file_info_params::file_type, icontype_filetype
        copy16  get_file_info_params::aux_type, icontype_auxtype
        copy16  get_file_info_params::blocks_used, icontype_blocks
        jsr     get_icon_type

        cmp     #IconType::basic
        bne     :+
        jsr     check_basic_system ; Only launch if BASIC.SYSTEM is found
        beq     launch
        lda     #kErrBasicSysNotFound
        jmp     ShowAlert

:       cmp     #IconType::binary
        bne     :+
        lda     BUTN0           ; Only launch if a button is down
        ora     BUTN1
        bmi     launch
        jsr     set_cursor_pointer
        rts

:       cmp     #IconType::folder
        bne     :+
        jmp     open_folder

:       cmp     #IconType::system
        beq     launch

        cmp     #IconType::application
        beq     launch

        cmp     #IconType::graphics
        bne     :+
        addr_jump invoke_desk_acc, str_preview_fot

:       cmp     #IconType::text
        bne     :+
        addr_jump invoke_desk_acc, str_preview_txt

:       cmp     #IconType::font
        bne     :+
        addr_jump invoke_desk_acc, str_preview_fnt

:       cmp     #IconType::desk_accessory
        bne     :+
        addr_jump invoke_desk_acc, path

:       jsr     check_basis_system ; Is fallback BASIS.SYSTEM present?
        beq     launch
        lda     #kErrFileNotOpenable
        jmp     ShowAlert

launch: ldx     buf_win_path
:       copy    buf_win_path,x, INVOKER_PREFIX,x
        dex
        bpl     :-
        ldx     buf_filename2
:       copy    buf_filename2,x, INVOKER_FILENAME,x
        dex
        bpl     :-
        copy16  #INVOKER, reset_and_invoke_target
        jmp     reset_and_invoke

;;; --------------------------------------------------
;;; Check buf_win_path and ancestors to see if the desired interpreter
;;; (BASIC.SYSTEM or BASIS.SYSTEM) is present.
;;; Input: buf_win_path set to initial search path
;;; Output: zero if found, non-zero if not found

.proc check_basix_system_impl
        path := $1800

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params2, path

basic:  lda     #'C'            ; "BASI?" -> "BASIC"
        bne     start           ; always

basis:  lda     #'S'            ; "BASI?" -> "BASIS"
        ;; fall through

start:  sta     str_basix_system + kBSOffset

        ldx     buf_win_path
        stx     path_length
:       copy    buf_win_path,x, path,x
        dex
        bpl     :-

        inc     path
        ldx     path
        copy    #'/', path,x
loop:
        ;; Append BASI?.SYSTEM to path and check for file.
        ldx     path
        ldy     #0
:       inx
        iny
        copy    str_basix_system,y, path,x
        cpy     str_basix_system
        bne     :-
        stx     path
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params2
        bne     not_found
        rts                     ; zero is success

        ;; Pop off a path segment and try again.
not_found:
        ldx     path_length
:       lda     path,x
        cmp     #'/'
        beq     found_slash
        dex
        bne     :-

no_bs:  return  #$FF            ; non-zero is failure

found_slash:
        cpx     #1
        beq     no_bs
        stx     path
        dex
        stx     path_length
        jmp     loop

path_length:
        .byte   0

.endproc
        check_basic_system := check_basix_system_impl::basic
        check_basis_system := check_basix_system_impl::basis

;;; --------------------------------------------------

.proc open_folder
        ;; Copy path
        ldx     path
:       copy    path,x, open_dir_path_buf,x
        dex
        bpl     :-

        tsx
        stx     saved_stack

        jsr     open_window_for_path

        jsr     set_cursor_pointer
        rts
.endproc

;;; --------------------------------------------------

.endproc
launch_file             := launch_file_impl::compose_path ; use |buf_win_path| + |buf_filename2|
launch_file_with_path   := launch_file_impl::with_path ; use |path|

;;; ============================================================

.proc upcase_char
        cmp     #'a'
        bcc     done
        cmp     #'z'+1
        bcs     done
        and     #CASE_MASK
done:   rts
.endproc


;;; ============================================================

kBSOffset       = 5             ; Offset of 'x' in BASIx.SYSTEM
str_basix_system:
        PASCAL_STRING "BASIx.SYSTEM"

str_preview_fot:
        PASCAL_STRING "Preview/show.image.file"

str_preview_fnt:
        PASCAL_STRING "Preview/show.font.file"

str_preview_txt:
        PASCAL_STRING "Preview/show.text.file"

;;; ============================================================


;;; ============================================================
;;; Aux $D000-$DFFF holds FileRecord entries. These are stored
;;; with a one byte length prefix, then sequential FileRecords.
;;; Not counting the prefix, this gives room for 128 entries.
;;; Only 127 icons are supported and volumes don't get entries,
;;; so this is enough, but free space is not properly compacted
;;; so it can run out. https://github.com/a2stuff/a2d/issues/19

;;; `window_id_to_filerecord_list_*` maps win id to list num
;;; `window_filerecord_table` maps from list num to address

;;; This remains constant:
filerecords_free_end:
        .word   $E000

;;; This tracks the start of free space.
filerecords_free_start:
        .word   $D000

;;; ============================================================

.proc restore_device_list
        ldx     devlst_backup
        inx
:       copy    devlst_backup,x, DEVLST-1,x
        dex
        bpl     :-
        rts
.endproc

.proc warning_dialog_proc_num
        sta     warning_dialog_num
        yax_call invoke_dialog_proc, kIndexWarningDialog, warning_dialog_num
        rts
.endproc

        copy16  #main_loop, L48E4

        L48E4 := *+1
        jmp     dummy1234           ; self-modified

;;; ============================================================

.proc cmd_noop
        rts
.endproc

;;; ============================================================

.proc cmd_selector_action
        jsr     set_cursor_watch
        lda     #kDynamicRoutineSelector1
        jsr     load_dynamic_routine
        bmi     done
        lda     menu_click_params::item_num
        cmp     #3              ; 1 = Add, 2 = Edit (need more overlays)
        bcs     :+              ; 3 = Delete, 4 = Run (can skip)
        lda     #kDynamicRoutineSelector2
        jsr     load_dynamic_routine
        bmi     done
        lda     #kDynamicRoutineFileDialog
        jsr     load_dynamic_routine
        bmi     done

:       jsr     set_cursor_pointer
        ;; Invoke routine
        lda     menu_click_params::item_num
        jsr     selector_picker_exec
        sta     result
        jsr     set_cursor_watch
        ;; Restore from overlays
        lda     #kDynamicRoutineRestore9000
        jsr     restore_dynamic_routine

        lda     menu_click_params::item_num
        cmp     #4              ; 4 = Run ?
        bne     done

        ;; "Run" command
        lda     result
        bpl     done
        jsr     make_ramcard_prefixed_path
        jsr     strip_path_segments
        jsr     get_copied_to_ramcard_flag
        bpl     run_from_ramcard

        ;; Need to copy to RAMCard
        jsr     redraw_windows_and_desktop ; copying window is smaller
        jsr     jt_run
        bmi     done
        jsr     L4968

done:   jsr     set_cursor_pointer
        jsr     redraw_windows_and_desktop
        rts

.proc L4968
        jsr     make_ramcard_prefixed_path
        COPY_STRING $840, buf_win_path
        jmp     launch_buf_win_path
.endproc

        ;; Was already copied to RAMCard, so update path then run.
run_from_ramcard:
        jsr     make_ramcard_prefixed_path
        COPY_STRING $800, buf_win_path
        jsr     launch_buf_win_path
        jmp     done

result: .byte   0
.endproc


;;; ============================================================

.proc cmd_selector_item_impl
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params3, $220

start:
        jmp     L49A6

entry_num:
        .byte   0

L49A6:  lda     menu_click_params::item_num
        sec
        sbc     #6              ; 4 items + separator (and make 0 based)
        sta     entry_num

        jsr     a_times_16
        addax   #run_list_entries, $06

        ldy     #kSelectorEntryFlagsOffset ; flag byte following name
        lda     ($06),y
        asl     a
        bmi     not_downloaded  ; bit 6
        bcc     L49E0           ; bit 7

        jsr     get_copied_to_ramcard_flag
        beq     not_downloaded
        lda     entry_num
        jsr     check_downloaded_path
        beq     L49ED

        lda     entry_num
        jsr     L4A47
        jsr     jt_run
        bpl     L49ED
        jmp     redraw_windows_and_desktop

L49E0:  jsr     get_copied_to_ramcard_flag
        beq     not_downloaded

        lda     entry_num
        jsr     check_downloaded_path           ; was-downloaded flag check?
        bne     not_downloaded

L49ED:  lda     entry_num
        jsr     compose_downloaded_entry_path
        stax    $06
        jmp     L4A0A

not_downloaded:
        lda     entry_num
        jsr     a_times_64
        addax   #run_list_paths, $06

L4A0A:  ldy     #$00
        lda     ($06),y
        tay
L4A0F:  lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     L4A0F
        ;; fall through

.proc launch_buf_win_path
        ;; Find last '/'
        ldy     buf_win_path
:       lda     buf_win_path,y
        cmp     #'/'
        beq     :+
        dey
        bpl     :-

:       dey
        sty     slash_index

        ;; Copy filename to buf_filename2
        ldx     #0
        iny
:       iny
        inx
        lda     buf_win_path,y
        sta     buf_filename2,x
        cpy     buf_win_path
        bne     :-

        ;; Truncate path
        stx     buf_filename2
        lda     slash_index
        sta     buf_win_path
        lda     #0

        jmp     launch_file

slash_index:
        .byte   0
.endproc

;;; --------------------------------------------------

        ;; Copy entry path to $800
.proc L4A47
        pha
        jsr     a_times_64
        addax   #run_list_paths, $06
        ldy     #0
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     $800,y
        dey
        bpl     :-
        pla

        ;; Copy "down loaded" path to $840
        jsr     compose_downloaded_entry_path
        stax    $08
        ldy     #0
        lda     ($08),y
        tay
:       lda     ($08),y
        sta     $840,y
        dey
        bpl     :-
        ;; fall through
.endproc

        ;; Strip segment off path at $800
.proc strip_path_segments
        ldy     $800
:       lda     $800,y
        cmp     #'/'
        beq     :+
        dey
        bne     :-

:       dey
        sty     $800

        ;; Strip segment off path at $840
        ldy     $840
:       lda     $840,y
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       dey
        sty     $840

        ;; Return addresses in $6 and $8
        copy16  #$800, $06
        copy16  #$840, $08

        jsr     copy_paths_and_split_name
        rts
.endproc

;;; --------------------------------------------------
;;; Append last two path segments of buf_win_path to
;;; ramcard_prefix, result left at $840

.proc make_ramcard_prefixed_path
        ;; Copy window path to $800
        ldy     buf_win_path
:       lda     buf_win_path,y
        sta     $800,y
        dey
        bpl     :-

        addr_call copy_ramcard_prefix, $840

        ;; Find last '/' in path...
        ldy     $800
:       lda     $800,y
        cmp     #'/'
        beq     :+
        dey
        bne     :-

        ;; And back up one more path segment...
:       dey
:       lda     $800,y
        cmp     #'/'
        beq     :+
        dey
        bne     :-

:       dey
        ldx     $840
:       iny
        inx
        lda     $800,y
        sta     $840,x
        cpy     $800
        bne     :-
        rts
.endproc

.proc check_downloaded_path
        jsr     compose_downloaded_entry_path
        stax    get_file_info_params3::pathname
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params3
        rts
.endproc

.endproc
        cmd_selector_item := cmd_selector_item_impl::start

        launch_buf_win_path := cmd_selector_item_impl::launch_buf_win_path
        strip_path_segments := cmd_selector_item_impl::strip_path_segments
        make_ramcard_prefixed_path := cmd_selector_item_impl::make_ramcard_prefixed_path

;;; ============================================================
;;; Append filename to directory path in path_buffer
;;; Inputs: A,X = ptr to path suffix to append
;;; Outputs: path_buffer has '/' and suffix appended

.proc append_to_path_buffer

        stax    @filename1
        stax    @filename2

        ;; Append '/' separator
        ldy     path_buffer
        iny
        lda     #'/'
        sta     path_buffer,y

        ;; Append filename
        ldx     #0
:       inx
        iny
        @filename1 := *+1
        lda     dummy1234,x
        sta     path_buffer,y
        @filename2 := *+1
        cpx     dummy1234
        bne     :-
        sty     path_buffer

        rts

.endproc

;;; ============================================================
;;; Get "copied to RAM card" flag from Main LC Bank 2.

.proc get_copied_to_ramcard_flag
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2
        lda     COPIED_TO_RAMCARD_FLAG
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts
.endproc

.proc copy_ramcard_prefix
        stax    @destptr
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2

        ldx     RAMCARD_PREFIX
:       lda     RAMCARD_PREFIX,x
        @destptr := *+1
        sta     dummy1234,x
        dex
        bpl     :-

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

.proc copy_desktop_orig_prefix
        stax    @destptr
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2

        ldx     DESKTOP_ORIG_PREFIX
:       lda     DESKTOP_ORIG_PREFIX,x
        @destptr := *+1
        sta     dummy1234,x
        dex
        bpl     :-

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

;;; ============================================================
;;; For entry copied ("down loaded") to RAM card, compose path
;;; using RAM card prefix plus last two segments of path
;;; (e.g. "/RAM" + "/" + "MOUSEPAINT/MP.SYSTEM") into path_buffer

.proc compose_downloaded_entry_path
        sta     entry_num

        ;; Initialize buffer
        addr_call copy_ramcard_prefix, path_buffer

        ;; Find entry path
        lda     entry_num
        jsr     a_times_64
        addax   #run_list_paths, $06
        ldy     #0
        lda     ($06),y
        sta     prefix_length

        ;; Walk back one segment
        tay
:       lda     ($06),y
        and     #CHAR_MASK
        cmp     #'/'
        beq     :+
        dey
        bne     :-

:       dey

        ;; Walk back a second segment
:       lda     ($06),y
        and     #CHAR_MASK
        cmp     #'/'
        beq     :+
        dey
        bne     :-

:       dey

        ;; Append last two segments to path
        ldx     path_buffer
:       inx
        iny
        lda     ($06),y
        sta     path_buffer,x
        cpy     prefix_length
        bne     :-

        stx     path_buffer
        ldax    #path_buffer
        rts

entry_num:
        .byte   0

prefix_length:
        .byte   0
.endproc

;;; ============================================================

.proc cmd_about
        yax_call invoke_dialog_proc, kIndexAboutDialog, $0000
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================

.proc cmd_deskacc_impl
        ptr := $6
        path := $220

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, path

str_desk_acc:
        PASCAL_STRING "Desk.Acc/"

start:  jsr     reset_main_grafport
        jsr     set_cursor_watch

        ;; Get current prefix
        ;; TODO: Case adjust this?
        MLI_RELAY_CALL GET_PREFIX, get_prefix_params

        ;; Find DA name
        lda     menu_click_params::item_num           ; menu item index (1-based)
        sec
        sbc     #3              ; About and separator before first item
        jsr     a_times_16
        addax   #desk_acc_names, ptr

        ;; Append DA directory name
        ldx     path
        ldy     #0
:       inx
        iny
        lda     str_desk_acc,y
        sta     path,x
        cpy     str_desk_acc
        bne     :-

        ;; Append name to path
        ldy     #0
        lda     ($06),y
        sta     len
loop:   inx
        iny
        lda     ($06),y
        cmp     #' '            ; Convert spaces back to periods
        bne     :+
        lda     #'.'
:       sta     path,x
        len := *+1
        cpy     #0              ; self-modified
        bne     loop
        stx     path

        ;; Allow arbitrary types in menu (e.g. folders)
        jmp     launch_file_with_path
.endproc
        cmd_deskacc := cmd_deskacc_impl::start

;;; ============================================================
;;; Invoke Desk Accessory
;;; Input: A,X = address of pathnane buffer

.proc invoke_desk_acc
        stax    open_pathname

        ;; Load the DA
        jsr     open
        bmi     done
        lda     open_ref_num
        sta     read_ref_num
        sta     close_ref_num
        MLI_RELAY_CALL READ, read_params
        MLI_RELAY_CALL CLOSE, close_params
        copy    #$80, running_da_flag

        ;; Invoke it
        jsr     set_cursor_pointer
        jsr     reset_main_grafport
        jsr     DA_LOAD_ADDRESS
        lda     #0
        sta     running_da_flag

        ;; Restore state
        jsr     reset_main_grafport
        jsr     redraw_windows_and_desktop
done:   jsr     set_cursor_pointer
        rts

open:   MLI_RELAY_CALL OPEN, open_params
        bne     :+
        rts
:       lda     #kWarningMsgInsertSystemDisk
        jsr     warning_dialog_proc_num
        beq     open            ; ok, so try again
        return  #$FF            ; cancel, so fail

        DEFINE_OPEN_PARAMS open_params, 0, DA_IO_BUFFER
        open_ref_num := open_params::ref_num
        open_pathname := open_params::pathname

        DEFINE_READ_PARAMS read_params, DA_LOAD_ADDRESS, kDAMaxSize
        read_ref_num := read_params::ref_num

        DEFINE_CLOSE_PARAMS close_params
        close_ref_num := close_params::ref_num

.endproc

;;; ============================================================

        ;; high bit set while a DA is running
running_da_flag:
        .byte   0

;;; ============================================================

.proc cmd_copy_file
        jsr     set_cursor_watch
        lda     #kDynamicRoutineFileDialog
        jsr     load_dynamic_routine
        bmi     L4CD6
        lda     #kDynamicRoutineFileCopy
        jsr     load_dynamic_routine
        bmi     L4CD6
        jsr     set_cursor_pointer
        lda     #$00
        jsr     file_dialog_exec
        pha
        jsr     set_cursor_watch
        lda     #kDynamicRoutineRestore5000
        jsr     restore_dynamic_routine
        jsr     set_cursor_pointer
        pla
        bpl     :+
        jmp     L4CD6

        ;; --------------------------------------------------

:       jsr     copy_paths_and_split_name
        jsr     redraw_windows_and_desktop

        jsr     jt_copy_file

L4CD6:  pha
        jsr     set_cursor_pointer
        pla
        bpl     :+
        jmp     redraw_windows_and_desktop

:       addr_call find_window_for_path, path_buf4
        beq     :+
        pha
        jsr     update_used_free_for_vol_windows
        pla
        jmp     select_and_refresh_window

        ;; --------------------------------------------------
        ;; Update used/free for windows for same vol as path_buf4

:       ldy     #1
@loop:  iny
        lda     path_buf4,y
        cmp     #'/'
        beq     :+
        cpy     path_buf4
        bne     @loop
        iny
:       dey
        sty     path_buf4
        addr_call find_windows_for_prefix, path_buf4

        ldax    #path_buf4
        ldy     path_buf4
        jsr     update_vol_used_free_for_found_windows
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================
;;; Copy string at ($6) to path_buf3, string at ($8) to path_buf4,
;;; split filename off path_buf4 and store in filename_buf

.proc copy_paths_and_split_name

        ;; Copy string at $6 to path_buf3
        ldy     #0
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     path_buf3,y
        dey
        bpl     :-

        ;; Copy string at $8 to path_buf4
        ldy     #0
        lda     ($08),y
        tay
:       lda     ($08),y
        sta     path_buf4,y
        dey
        bpl     :-

        addr_call find_last_path_segment, path_buf4

        ;; Copy filename part to buf
        ldx     #1
        iny
        iny
:       lda     path_buf4,y
        sta     filename_buf,x
        cpy     path_buf4
        beq     :+
        iny
        inx
        jmp     :-

:       stx     filename_buf

        ;; And remove from path_buf4
        lda     path_buf4
        sec
        sbc     filename_buf
        sta     path_buf4
        dec     path_buf4
        rts
.endproc

;;; ============================================================

.proc cmd_delete_file
        jsr     set_cursor_watch
        lda     #kDynamicRoutineFileDialog
        jsr     load_dynamic_routine
        bmi     L4D9D

        lda     #kDynamicRoutineFileDelete
        jsr     load_dynamic_routine
        bmi     L4D9D

        jsr     set_cursor_pointer
        lda     #$01
        jsr     file_dialog_exec
        pha
        jsr     set_cursor_watch
        lda     #kDynamicRoutineRestore5000
        jsr     restore_dynamic_routine
        jsr     set_cursor_pointer
        pla
        bpl     :+
        jmp     L4D9D

:       ldy     #0
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     path_buf3,y
        dey
        bpl     :-

        jsr     redraw_windows_and_desktop

        jsr     jt_delete_file

L4D9D:  pha
        jsr     set_cursor_pointer
        pla
        bpl     :+
        jmp     redraw_windows_and_desktop

:       addr_call find_last_path_segment, path_buf3
        sty     path_buf3

        addr_call find_window_for_path, path_buf3
        beq     :+
        pha
        jsr     update_used_free_for_vol_windows
        pla
        jmp     select_and_refresh_window

        ;; --------------------------------------------------
        ;; Update used/free for windows for same vol as path_buf3

:       ldy     #1
@loop:  iny
        lda     path_buf3,y
        cmp     #'/'
        beq     :+
        cpy     path_buf3
        bne     @loop
        iny
:       dey
        sty     path_buf3
        addr_call find_windows_for_prefix, path_buf3

        ldax    #path_buf3
        ldy     path_buf3
        jsr     update_vol_used_free_for_found_windows
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================
;;; Helper for "Open" actions - if Apple key is down, record
;;; the parent window to close.

.proc set_window_to_close_after_open
        lda     BUTN0           ; Modifier down?
        ora     BUTN1
        bmi     :+              ; Yep

        lda     #0
        beq     store           ; always
:       lda     selected_window_index
store:  sta     window_id_to_close
        rts
.endproc

;;; ============================================================

.proc cmd_open
        ptr := $06

        ;; Source window to close?
        jsr     set_window_to_close_after_open

        ldx     #0
        stx     dir_count

L4DEC:  cpx     selected_icon_count
        bne     :+

        ;; Were any directories opened?
        lda     dir_count
        beq     done
        jsr     clear_selection

        ;; Close previous active window, depending on source/modifiers
        bit     menu_kbd_flag   ; If keyboard (Apple-O) ignore. (see issue #9)
        bmi     done            ; Yep, ignore.
        jsr     close_window_after_open

done:   rts

:       txa
        pha
        lda     selected_icon_list,x
        jsr     icon_entry_lookup
        stax    ptr

        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #kIconEntryTypeMask

        cmp     #kIconEntryTypeTrash
        beq     next_file
        cmp     #kIconEntryTypeDir
        bne     maybe_open_file

        ;; Directory
        ldy     #0
        lda     (ptr),y
        jsr     open_folder_or_volume_icon
        inc     dir_count

next_file:
        pla
        tax
        inx
        jmp     L4DEC

        ;; File (executable or data)
maybe_open_file:
        lda     selected_icon_count
        cmp     #2              ; multiple files open?
        bcs     next_file       ; don't try to invoke

        pla

        ;; Copy window path to buf_win_path
        win_path_ptr := $06

        lda     active_window_id
        jsr     window_path_lookup
        stax    win_path_ptr

        ldy     #0
        lda     (win_path_ptr),y
        tay
:       lda     (win_path_ptr),y
        sta     buf_win_path,y
        dey
        bpl     :-

        ;; Copy file path to buf_filename2
        icon_ptr := $06

        lda     selected_icon_list
        jsr     icon_entry_lookup
        stax    icon_ptr
        ldy     #IconEntry::name
        lda     (icon_ptr),y
        tax
        clc
        adc     #IconEntry::name
        tay
:       lda     (icon_ptr),y
        sta     buf_filename2,x
        dey
        dex
        bpl     :-

        jmp     launch_file

        ;; Count of opened volumes/folders; if non-zero,
        ;; selection must be cleared before finishing.
dir_count:
        .byte   0

last_active_window_id:
        .byte   0
.endproc

;;; ============================================================
;;; Close parent window after open, if needed. Done by activating then closing.
;;; Modifies findwindow_window_id

.proc close_window_after_open
        lda     window_id_to_close
        beq     done

        pha
        sta     findwindow_window_id
        jsr     handle_inactive_window_click
        pla
        jsr     close_window

done:   rts
.endproc

;;; ============================================================

.proc cmd_close
        icon_ptr := $06

        lda     active_window_id
        bne     :+
        rts

:       jmp     close_window
.endproc

;;; ============================================================

.proc cmd_close_all
        lda     active_window_id   ; current window
        beq     done            ; nope, done!
        jsr     close_window    ; close it...
        jmp     cmd_close_all   ; and try again
done:   rts
.endproc

;;; ============================================================

.proc cmd_disk_copy
        lda     #kDynamicRoutineDiskCopy
        jsr     load_dynamic_routine
        bmi     fail
        jmp     format_erase_overlay_exec

fail:   rts
.endproc

;;; ============================================================

.proc cmd_new_folder_impl

        ptr := $06

.params new_folder_dialog_params
phase:  .byte   0               ; window_id?
win_path_ptr:  .word   0
.endparams

        ;; access = destroy/rename/write/read
        DEFINE_CREATE_PARAMS create_params, path_buffer, ACCESS_DEFAULT, FT_DIRECTORY,, ST_LINKED_DIRECTORY

path_buffer:
        .res    ::kPathBufferSize, 0              ; buffer is used elsewhere too

start:  copy    active_window_id, new_folder_dialog_params::phase
        yax_call invoke_dialog_proc, kIndexNewFolderDialog, new_folder_dialog_params

L4FC6:  lda     active_window_id
        beq     L4FD4
        jsr     window_path_lookup
        stax    new_folder_dialog_params::win_path_ptr
L4FD4:  copy    #$80, new_folder_dialog_params::phase
        yax_call invoke_dialog_proc, kIndexNewFolderDialog, new_folder_dialog_params
        beq     :+
        jmp     done            ; Cancelled
:       stx     ptr+1
        stx     name_ptr+1
        sty     ptr
        sty     name_ptr

        ;; Copy path
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     path_buffer,y
        dey
        bpl     :-

        ;; Create with current date
        COPY_STRUCT DateTime, DATELO, create_params::create_date

        ;; Create folder
        MLI_RELAY_CALL CREATE, create_params
        beq     success

        ;; Failure
        jsr     ShowAlert
        copy16  name_ptr, new_folder_dialog_params::win_path_ptr
        jmp     L4FC6

success:
        copy    #$40, new_folder_dialog_params::phase
        yax_call invoke_dialog_proc, kIndexNewFolderDialog, new_folder_dialog_params
        addr_call find_last_path_segment, path_buffer
        sty     path_buffer
        addr_call find_window_for_path, path_buffer
        beq     done
        jsr     select_and_refresh_window

        ;; View by Icon?
        ;; TODO: Scroll list views, as well.
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        bmi     done

        jsr     select_new_folder_icon

done:   jmp     redraw_windows_and_desktop

.proc select_new_folder_icon
        ptr_icon := $6
        ptr_name := $8
        copy16  #path_buf1, ptr_name

        jsr     LoadActiveWindowIconTable

        ;; Iterate icons
        copy    #0, icon
loop:   ldx     icon
        cpx     cached_window_icon_count
        beq     done

        ;; Compare with name from dialog
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup
        stax    ptr_icon

        ;; Lengths match?
        ldy     #IconEntry::name
        lda     (ptr_icon),y
        ldy     #0
        cmp     (ptr_name),y
        bne     next

        ;; Compare characters (case insensitive)
        tay
        add16   ptr_icon, #IconEntry::name, ptr_icon
cloop:  lda     (ptr_icon),y
        jsr     upcase_char
        sta     char
        lda     (ptr_name),y
        jsr     upcase_char
        cmp     char
        bne     next
        dey
        bne     cloop

        ;; Match, so make selected
        ldx     icon
        lda     cached_window_icon_list,x
        pha
        jsr     select_file_icon
        pla
        jsr     scroll_icon_into_view
        bne     done            ; always

next:   inc     icon
        bne     loop

done:   jsr     LoadDesktopIconTable
        rts

icon:   .byte   0
char:   .byte   0
.endproc

name_ptr:
        .addr   0
.endproc
        cmd_new_folder := cmd_new_folder_impl::start
        path_buffer := cmd_new_folder_impl::path_buffer

;;; ============================================================
;;; Grab the coordinates (MGTK::Point) of an icon.
;;; Inputs: A = icon number
;;; Outputs: cur_icon_pos is filled, $06 points at icon entry

cur_icon_pos:
        DEFINE_POINT 0,0,cur_icon_pos

.proc cache_icon_pos
        entry_ptr := $06

        jsr     icon_entry_lookup
        stax    entry_ptr

        ldy     #IconEntry::iconx+.sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     (entry_ptr),y
        sta     cur_icon_pos::xcoord,x
        dey
        dex
        bpl     :-

        rts
.endproc

;;; ============================================================
;;; Input: Icon number in A. Must be in active window.

kIconBBoxOffsetTop     = 15
kIconBBoxOffsetLeft    = 50
kIconBBoxOffsetBottom  = 32          ; includes height of icon + label
kIconBBoxOffsetRight   = 50          ; includes width of icon + label

.proc scroll_icon_into_view
        icon_ptr := $06

        sta     icon_num

        ;; Map coordinates to window
        jsr     icon_screen_to_window

        ;; Grab the icon coords
        lda     icon_num
        jsr     cache_icon_pos

        ;; Restore coordinates
        lda     icon_num
        jsr     icon_window_to_screen

        jsr     apply_active_winfo_to_window_grafport

        copy    #0, dirty

        ;; --------------------------------------------------
        ;; X adjustment

        ;; Is left of icon beyond window? If so, adjust by delta (negative)
        sub16   cur_icon_pos::xcoord, window_grafport::cliprect::x1, delta
        bmi     adjustx

        ;; Is right of icon beyond window? If so, adjust by delta (positive)
        add16_8 cur_icon_pos::xcoord, #kIconBBoxOffsetRight, cur_icon_pos::xcoord
        sub16   cur_icon_pos::xcoord, window_grafport::cliprect::x2, delta
        bmi     donex

adjustx:
        inc     dirty
        add16   window_grafport::cliprect::x1, delta, window_grafport::cliprect::x1
        add16   window_grafport::cliprect::x2, delta, window_grafport::cliprect::x2

donex:

        ;; --------------------------------------------------
        ;; Y adjustment

        kMaxIconHeight = 17
        kIconLabelHeight = 8

        ;; Is top of icon beyond window? If so, adjust by delta (negative)
        sub16   cur_icon_pos::ycoord, window_grafport::cliprect::y1, delta
        bmi     adjusty

        ;; Is bottom of icon beyond window? If so, adjust by delta (positive)
        add16_8 cur_icon_pos::ycoord, #kIconBBoxOffsetBottom, cur_icon_pos::ycoord
        sub16   cur_icon_pos::ycoord, window_grafport::cliprect::y2, delta
        bmi     doney

adjusty:
        inc dirty
        add16   window_grafport::cliprect::y1, delta, window_grafport::cliprect::y1
        add16   window_grafport::cliprect::y2, delta, window_grafport::cliprect::y2

doney:
        lda     dirty
        beq     done

        jsr     cached_icons_screen_to_window ; assumed by...
        jsr     finish_scroll_adjust_and_redraw

done:   rts

icon_num:
        .byte   0

dirty:  .byte   0

delta: .word   0
.endproc

;;; ============================================================

.proc cmd_check_or_eject
        buffer := $1800

eject:
        lda     #$80
        bne     common          ; always

check:  lda     #0

common: sta     eject_flag

        ;; Ensure that volumes are selected
        lda     selected_window_index
        beq     :+
done:   rts

        ;; And if there's only one, it's not Trash
:       lda     selected_icon_count
        beq     done
        cmp     #1              ; single selection
        bne     :+
        lda     selected_icon_list
        cmp     trash_icon_num  ; if it's Trash, skip it
        beq     done

        ;; Record non-Trash selected volume icons to a buffer
:       lda     #0
        tax
        tay
loop1:  lda     selected_icon_list,y
        cmp     trash_icon_num
        beq     :+
        sta     buffer,x
        inx
:       iny
        cpy     selected_icon_count
        bne     loop1
        dex
        stx     count

        ;; Do the ejection
        bit     eject_flag
        bpl     :+
        jsr     jt_eject
:

        ;; Check each of the recorded volumes
loop2:  ldx     count
        lda     buffer,x
        sta     drive_to_refresh ; icon number
        jsr     cmd_check_single_drive_by_icon_number
        dec     count
        bpl     loop2

        ;; And finish up nicely
        jmp     redraw_windows_and_desktop

count:  .byte   0

eject_flag:
        .byte   0
.endproc
        cmd_eject       := cmd_check_or_eject::eject
        cmd_check_drive := cmd_check_or_eject::check

;;; ============================================================

.proc cmd_quit_impl
        ;; TODO: Assumes prefix is retained. Compose correct path.

        quit_code_io := $800
        quit_code_addr := $1000
        quit_code_size := $400

        DEFINE_OPEN_PARAMS open_params, str_quit_code, quit_code_io
        DEFINE_READ_PARAMS read_params, quit_code_addr, quit_code_size
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_QUIT_PARAMS quit_params

str_quit_code:  PASCAL_STRING "Quit.tmp"

reset_handler:
        ;; Restore DeskTop Main expected state...
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

start:
        ;; Restore system state: devices, /RAM, ROM/ZP banks.
        jsr     restore_system

        ;; Load and run/reinstall previous QUIT handler.
        MLI_CALL OPEN, open_params
        bne     fail
        lda open_params::ref_num
        sta read_params::ref_num
        sta close_params::ref_num
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_params
        jmp     quit_code_addr

fail:   MLI_CALL QUIT, quit_params
        brk

.endproc
        cmd_quit := cmd_quit_impl::start
        reset_handler := cmd_quit_impl::reset_handler

;;; ============================================================
;;; Exit DHR, restore device list, reformat /RAM.
;;; Returns with ALTZPOFF and ROM banked in.

.proc restore_system
        jsr     save_windows
        jsr     restore_device_list

        ;; Switch back to main ZP, preserving return address.
        pla
        tax
        pla
        sta     ALTZPOFF
        pha
        txa
        pha

        ;; Switch back to color DHR mode
        jsr     set_color_mode

        ;; Exit graphics mode entirely
        lda     ROMIN2
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR

        sta     DHIRESOFF
        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80COL

        ;; Restore /RAM if possible.
        jmp     maybe_reformat_ram
.endproc

;;; ============================================================

.proc cmd_view_by_icon
        ldx     active_window_id
        bne     :+
        rts

:       dex
        lda     win_view_by_table,x
        bne     :+              ; not by icon
        rts

        ;; View by icon
entry:
:       jsr     LoadActiveWindowIconTable
        ldx     #$00
        txa
:       cpx     cached_window_icon_count
        beq     :+
        sta     cached_window_icon_list,x
        inx
        jmp     :-

:       sta     cached_window_icon_count
        lda     #0
        ldx     active_window_id
        dex
        sta     win_view_by_table,x
        jsr     update_view_menu_check
        lda     active_window_id
        jsr     offset_and_set_port_from_window_id
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, window_grafport::cliprect
        lda     active_window_id
        jsr     compute_window_dimensions
        stax    L51EB
        sty     L51ED

        ptr = $06

        lda     active_window_id
        jsr     window_lookup
        stax    ptr

        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Point) - 1
        lda     #0
:       sta     (ptr),y
        dey
        cpy     #MGTK::Winfo::port + MGTK::GrafPort::maprect - 1
        bne     :-

        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     L51EB,x
        sta     (ptr),y
        dey
        dex
        bpl     :-

        lda     active_window_id
        jsr     create_file_icon_ep2

        lda     active_window_id
        jsr     set_port_from_window_id

        jsr     cached_icons_screen_to_window
        copy    #0, L51EF
L518D:  lda     L51EF
        cmp     cached_window_icon_count
        beq     L51A7
        tax
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup
        ldy     #IconTK::AddIcon
        jsr     ITK_RELAY   ; icon entry addr in A,X
        inc     L51EF
        jmp     L518D

L51A7:  jsr     reset_main_grafport
        jsr     cached_icons_window_to_screen
        jsr     StoreWindowIconTable
        jsr     update_scrollbars
        lda     selected_window_index
        beq     finish
        lda     selected_icon_count
        beq     finish
        sta     L51EF
L51C0:  ldx     L51EF
        lda     selected_icon_count,x
        sta     icon_param
        jsr     icon_screen_to_window
        jsr     offset_window_grafport_and_set
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param
        lda     icon_param
        jsr     icon_window_to_screen
        dec     L51EF
        bne     L51C0
finish: jmp     LoadDesktopIconTable

L51EB:  .word   0
L51ED:  .byte   0
        .byte   0
L51EF:  .byte   0
.endproc

;;; ============================================================

.proc view_by_nonicon_common
        sta     view

        ldx     active_window_id
        bne     :+
        rts
:
        dex
        lda     win_view_by_table,x
        cmp     view
        bne     :+
        rts
:
        cmp     #$00
        bne     :+
        jsr     close_active_window
:       jsr     update_view_menu_check

        lda     view
        ldx     active_window_id
        dex
        sta     win_view_by_table,x

        jsr     LoadActiveWindowIconTable
        jsr     sort_records
        jsr     StoreWindowIconTable
        lda     active_window_id
        jsr     offset_and_set_port_from_window_id
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, window_grafport::cliprect
        lda     active_window_id
        jsr     compute_window_dimensions
        stax    L5263
        sty     L5265

        ptr := $06

        lda     active_window_id
        jsr     window_lookup
        stax    ptr

        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Point) - 1
        lda     #0
:       sta     (ptr),y
        dey
        cpy     #MGTK::Winfo::port + MGTK::GrafPort::maprect - 1
        bne     :-

        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Point)-1
L5246:  lda     L5263,x
        sta     (ptr),y
        dey
        dex
        bpl     L5246

        copy    #$80, draw_window_header_flag
        jsr     reset_main_grafport
        jsr     draw_window_entries
        jsr     update_scrollbars
        copy    #0, draw_window_header_flag

done:   rts

L5263:  .word   0

L5265:  .byte   0
        .byte   0

view:   .byte   0
.endproc

;;; ============================================================

.proc cmd_view_by_name
        lda     #kViewByName
        jmp     view_by_nonicon_common
.endproc

;;; ============================================================

.proc cmd_view_by_date
        lda     #kViewByDate
        jmp     view_by_nonicon_common
.endproc

;;; ============================================================

.proc cmd_view_by_size
        lda     #kViewBySize
        jmp     view_by_nonicon_common
.endproc

;;; ============================================================

.proc cmd_view_by_type
        lda     #kViewByType
        jmp     view_by_nonicon_common
.endproc

;;; ============================================================

.proc update_view_menu_check
        ;; Uncheck last checked
        copy    #MGTK::checkitem_uncheck, checkitem_params::check
        jsr     check_item

        ;; Check the new one
        copy    menu_click_params::item_num, checkitem_params::menu_item
        copy    #MGTK::checkitem_check, checkitem_params::check
        jsr     check_item
        rts
.endproc

;;; ============================================================

.proc close_active_window
        ITK_RELAY_CALL IconTK::CloseWindow, active_window_id
        jsr     LoadActiveWindowIconTable
        lda     icon_count
        sec
        sbc     cached_window_icon_count
        sta     icon_count

        jsr     free_cached_window_icons

done:   jsr     StoreWindowIconTable
        jmp     LoadDesktopIconTable
.endproc

;;; ============================================================

.proc free_cached_window_icons
        copy    #0, index

loop:   ldx     index
        cpx     cached_window_icon_count
        beq     done

        lda     cached_window_icon_list,x
        pha
        jsr     FreeIcon
        pla

        jsr     find_window_for_dir_icon
        bne     :+
        copy    #$FF, window_to_dir_icon_table,x ; $FF = dir icon freed

:       ldx     index
        copy    #0, cached_window_icon_list,x

        inc     index
        bne     loop

done:   rts

index:  .byte   0
.endproc

;;; ============================================================

;;; Set after format, erase, failed open, etc.
;;; Used by 'cmd_check_single_drive_by_XXX'; may be unit number
;;; or device index depending on call site.
drive_to_refresh:
        .byte   0

;;; ============================================================

.proc cmd_format_disk
        lda     #kDynamicRoutineFormatErase
        jsr     load_dynamic_routine
        bmi     fail

        lda     #$04
        jsr     format_erase_overlay_exec
        bne     :+
        stx     drive_to_refresh ; unit number
        jsr     redraw_windows_and_desktop
        jsr     cmd_check_single_drive_by_unit_number
:       jmp     redraw_windows_and_desktop

fail:   rts
.endproc

;;; ============================================================

.proc cmd_erase_disk
        lda     #kDynamicRoutineFormatErase
        jsr     load_dynamic_routine
        bmi     done

        lda     #$05
        jsr     format_erase_overlay_exec
        bne     done

        stx     drive_to_refresh ; unit number
        jsr     redraw_windows_and_desktop
        jsr     cmd_check_single_drive_by_unit_number
done:   jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================

.proc cmd_get_info
        jsr     jt_get_info
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================

.proc cmd_get_size
        jsr     jt_get_size
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================

.proc cmd_unlock
        jsr     jt_unlock
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================

.proc cmd_lock
        jsr     jt_lock
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================

.proc cmd_delete_selection
        copy    trash_icon_num, drag_drop_params::icon
        jmp     process_drop
.endproc

;;; ============================================================

.proc cmd_rename_icon
        jsr     jt_rename_icon
        pha
        jsr     redraw_windows_and_desktop
        pla
        beq     :+
        rts

:       lda     selected_window_index
        bne     common

        ;; Volume icon on desktop

        ;; Copy selected icons (except Trash)
        ldx     #0
        ldy     #0
loop:   lda     selected_icon_list,x
        cmp     #kTrashIconNum
        beq     :+
        sta     selected_vol_icon_list,y
        iny
:       inx
        cpx     selected_icon_count
        bne     loop
        sty     selected_vol_icon_count

common: copy    #$FF, counter   ; immediately incremented to 0

        ;; Loop over selection

next_icon:
        inc     counter
        lda     counter
        cmp     selected_icon_count
        bne     not_done

        lda     selected_window_index
        bne     :+
        jmp     finish_with_vols
:       jmp     select_and_refresh_window

not_done:
        tax
        lda     selected_icon_list,x
        jsr     find_window_for_dir_icon
        bne     next_icon       ; not found
        inx                     ; 0-based index to 1-based window_id
        txa
        jsr     window_path_lookup
        stax    $06
        ldy     #0
        lda     ($06),y
        tay
        lda     $06
        jsr     find_windows_for_prefix
        lda     found_windows_count
        beq     next_icon
L53EF:  dec     found_windows_count
        ldx     found_windows_count
        lda     found_windows_list,x
        cmp     active_window_id
        beq     L5403
        sta     findwindow_window_id
        jsr     handle_inactive_window_click
L5403:  jsr     close_window
        lda     found_windows_count
        bne     L53EF
        jmp     next_icon

finish_with_vols:
        ldx     selected_vol_icon_count
        jmp     next_vol
:       lda     selected_vol_icon_list,x
        sta     drive_to_refresh         ; icon number
        jsr     cmd_check_single_drive_by_icon_number
        ldx     selected_vol_icon_count
        dec     selected_vol_icon_count
next_vol:
        dex
        bpl     :-
        jmp     redraw_windows_and_desktop

counter:
        .byte   0

selected_vol_icon_count:
        .byte   0

selected_vol_icon_list:
        .res    9, 0

.endproc

;;; ============================================================
;;; Handle keyboard-based icon selection ("highlighting")

.proc cmd_highlight
        jmp     L544D

L5444:  .byte   0
L5445:  .byte   0
L5446:  .byte   0
L5447:  .byte   0
L5448:  .byte   0
L5449:  .byte   0
L544A:  .byte   0
        .byte   0
        .byte   0

L544D:
        copy    #0, $1800
        lda     active_window_id
        bne     L545A
        jmp     L54C5

L545A:  tax
        dex
        lda     win_view_by_table,x
        bpl     L5464           ; by icon
        jmp     L54C5

        ;; View by icon
L5464:  jsr     LoadActiveWindowIconTable
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #MGTK::Winfo::port+MGTK::GrafPort::maprect
L5479:  lda     ($06),y
        sta     tmp_rect-(MGTK::Winfo::port+MGTK::GrafPort::maprect),y
        iny
        cpy     #MGTK::Winfo::port+MGTK::GrafPort::maprect+8
        bne     L5479
        ldx     #$00
L5485:  cpx     cached_window_icon_count
        beq     L54BD
        txa
        pha
        lda     cached_window_icon_list,x
        sta     icon_param
        jsr     icon_screen_to_window
        ITK_RELAY_CALL IconTK::IconInRect, icon_param
        pha
        lda     icon_param
        jsr     icon_window_to_screen
        pla
        beq     L54B7
        pla
        pha
        tax
        lda     cached_window_icon_list,x
        ldx     $1800
        sta     $1801,x
        inc     $1800
L54B7:  pla
        tax
        inx
        jmp     L5485

        ;; No window icons
L54BD:  jsr     LoadDesktopIconTable
L54C5:  ldx     $1800
        ldy     #$00
L54CA:  lda     cached_window_icon_list,y
        sta     $1801,x
        iny
        inx
        cpy     cached_window_icon_count
        bne     L54CA
        lda     $1800
        clc
        adc     cached_window_icon_count
        sta     $1800
        copy    #0, L544A
        ldax    #$03FF
L54EA:  sta     L5444,x
        dex
        bpl     L54EA
L54F0:  ldx     L544A
L54F3:  lda     $1801,x
        asl     a
        tay
        copy16  icon_entry_address_table,y, $06
        ldy     #$06
        lda     ($06),y
        cmp     L5447
        beq     L5510
        bcc     L5532
        jmp     L5547

L5510:  dey
        lda     ($06),y
        cmp     L5446
        beq     L551D
        bcc     L5532
        jmp     L5547

L551D:  dey
        lda     ($06),y
        cmp     L5445
        beq     L552A
        bcc     L5532
        jmp     L5547

L552A:  dey
        lda     ($06),y
        cmp     L5444
        bcs     L5547
L5532:  lda     $1801,x
        stx     L5449
        sta     L5448
        ldy     #$03
L553D:  lda     ($06),y
        sta     L5444-3,y
        iny
        cpy     #$07
        bne     L553D
L5547:  inx
        cpx     $1800
        bne     L54F3
        ldx     L544A
        lda     $1801,x
        tay
        lda     L5448
        sta     $1801,x
        ldx     L5449
        tya
        sta     $1801,x
        ldax    #$03FF
L5565:  sta     L5444,x
        dex
        bpl     L5565
        inc     L544A
        ldx     L544A
        cpx     $1800
        beq     L5579
        jmp     L54F0

L5579:  copy    #0, L544A
        jsr     clear_selection
L5581:  jsr     L55F0
L5584:  jsr     get_event
        lda     event_kind
        cmp     #MGTK::EventKind::key_down
        beq     L5595
        cmp     #MGTK::EventKind::button_down
        bne     L5584
        jmp     L55D1

L5595:  lda     event_params+MGTK::Event::key
        and     #CHAR_MASK
        cmp     #CHAR_RETURN
        beq     L55D1
        cmp     #CHAR_ESCAPE
        beq     L55D1
        cmp     #CHAR_LEFT
        beq     L55BE
        cmp     #CHAR_RIGHT
        bne     L5584
        ldx     L544A
        inx
        cpx     $1800
        bne     L55B5
        ldx     #$00
L55B5:  stx     L544A
        jsr     L562C
        jmp     L5581

L55BE:  ldx     L544A
        dex
        bpl     L55C8
        ldx     $1800
        dex
L55C8:  stx     L544A
        jsr     L562C
        jmp     L5581

L55D1:  ldx     L544A
        lda     $1801,x
        sta     selected_icon_list
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #kIconEntryWinIdMask
        sta     selected_window_index
        lda     #1
        sta     selected_icon_count
        rts

L55F0:  ldx     L544A
        lda     $1801,x
        sta     icon_param
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #kIconEntryWinIdMask
        sta     getwinport_params2::window_id
        beq     L5614
        jsr     offset_and_set_port_from_window_id
        lda     icon_param
        jsr     icon_screen_to_window
L5614:  ITK_RELAY_CALL IconTK::HighlightIcon, icon_param
        lda     getwinport_params2::window_id
        beq     L562B
        lda     icon_param
        jsr     icon_window_to_screen
        jsr     reset_main_grafport
L562B:  rts

L562C:  lda     icon_param
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #kIconEntryWinIdMask
        sta     getwinport_params2::window_id
        beq     L564A
        jsr     offset_and_set_port_from_window_id
        lda     icon_param
        jsr     icon_screen_to_window
L564A:  ITK_RELAY_CALL IconTK::UnhighlightIcon, icon_param
        lda     getwinport_params2::window_id
        beq     L5661
        lda     icon_param
        jsr     icon_window_to_screen
        jsr     reset_main_grafport
L5661:  rts
.endproc

;;; ============================================================

.proc cmd_select_all
        lda     selected_icon_count
        beq     L566A
        jsr     clear_selection
L566A:  ldx     active_window_id
        beq     L5676
        dex
        lda     win_view_by_table,x
        bpl     L5676           ; view by icons
        rts

L5676:  jsr     LoadActiveWindowIconTable
        lda     cached_window_icon_count
        bne     L5687
        jmp     L56F0

L5687:  ldx     cached_window_icon_count
        dex
L568B:  copy    cached_window_icon_list,x, selected_icon_list,x
        dex
        bpl     L568B
        copy    cached_window_icon_count, selected_icon_count
        copy    active_window_id, selected_window_index
        copy    selected_window_index, LE22C
        beq     L56AB
        jsr     offset_and_set_port_from_window_id
L56AB:  lda     selected_icon_count
        sta     L56F8
        dec     L56F8
L56B4:  ldx     L56F8
        copy    selected_icon_list,x, icon_param2
        jsr     icon_entry_lookup
        stax    $06
        lda     LE22C
        beq     L56CF
        lda     icon_param2
        jsr     icon_screen_to_window
L56CF:  ITK_RELAY_CALL IconTK::HighlightIcon, icon_param2
        lda     LE22C
        beq     L56E3
        lda     icon_param2
        jsr     icon_window_to_screen
L56E3:  dec     L56F8
        bpl     L56B4
        lda     selected_window_index
        beq     L56F0
        jsr     reset_main_grafport
L56F0:  jmp     LoadDesktopIconTable

L56F8:  .byte   0
.endproc


;;; ============================================================
;;; Initiate keyboard-based resizing

.proc cmd_resize
        MGTK_RELAY_CALL MGTK::KeyboardMouse
        jmp     handle_resize_click
.endproc

;;; ============================================================
;;; Initiate keyboard-based window moving

.proc cmd_move
        MGTK_RELAY_CALL MGTK::KeyboardMouse
        jmp     handle_title_click
.endproc

;;; ============================================================
;;; Cycle Through Windows
;;; Input: A = Key used; '~' is reversed


.proc cmd_cycle_windows
        tay

        ;; Need at least two windows to cycle.
        lda     num_open_windows
        cmp     #2
        bcc     done
        ldx     active_window_id

        cpy     #'~'
        beq     reverse

        ;; --------------------------------------------------
        ;; Search upwards through window-icon map to find next.
        ;; ID is 1-based, table is 0-based, so don't need to start
        ;; with an increment
@loop:  cpx     #kMaxNumWindows
        bne     :+
        ldx     #0
:       lda     window_to_dir_icon_table,x
        bne     found           ; 0 = window free
        inx
        bne     @loop           ; always

        ;; --------------------------------------------------
        ;; Search downwards through window-icon map to find next.
        ;; ID is 1-based, table is 0-based, start with decrements.
reverse:
        dex
@loop:  dex
        bpl     :+
        ldx     #kMaxNumWindows-1
:       lda     window_to_dir_icon_table,x
        beq     @loop           ; 0 = window free
        ;;  fall through...

found:  inx
        stx     findwindow_window_id
        jmp     handle_inactive_window_click

done:   rts
.endproc

;;; ============================================================
;;; Keyboard-based scrolling of window contents

.proc cmd_scroll
        jsr     get_active_window_scroll_info
loop:   jsr     get_event
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        beq     done
        cmp     #MGTK::EventKind::key_down
        bne     loop
        lda     event_key
        cmp     #CHAR_RETURN
        beq     done
        cmp     #CHAR_ESCAPE
        bne     :+

done:   jmp     LoadDesktopIconTable

        ;; Horizontal ok?
:       bit     horiz_scroll_flag
        bmi     :+
        jmp     vertical

:       cmp     #CHAR_RIGHT
        bne     :+
        jsr     scroll_right
        jmp     loop

:       cmp     #CHAR_LEFT
        bne     vertical
        jsr     scroll_left
        jmp     loop

        ;; Vertical ok?
vertical:
        bit     vert_scroll_flag
        bmi     :+
        jmp     loop

:       cmp     #CHAR_DOWN
        bne     :+
        jsr     scroll_down
        jmp     loop

:       cmp     #CHAR_UP
        bne     loop
        jsr     scroll_up
        jmp     loop
.endproc

;;; ============================================================

.proc get_active_window_scroll_info
        jsr     LoadActiveWindowIconTable
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        sta     active_window_view_by
        jsr     get_active_window_hscroll_info
        sta     horiz_scroll_pos
        stx     horiz_scroll_max
        sty     horiz_scroll_flag
        jsr     get_active_window_vscroll_info
        sta     vert_scroll_pos
        stx     vert_scroll_max
        sty     vert_scroll_flag
        rts
.endproc

;;; ============================================================

scroll_right:                   ; elevator right / contents left
        lda     horiz_scroll_pos
        ldx     horiz_scroll_max
        jsr     do_scroll_right
        sta     horiz_scroll_pos
        rts

scroll_left:                    ; elevator left / contents right
        lda     horiz_scroll_pos
        jsr     do_scroll_left
        sta     horiz_scroll_pos
        rts

scroll_down:                    ; elevator down / contents up
        lda     vert_scroll_pos
        ldx     vert_scroll_max
        jsr     do_scroll_down
        sta     vert_scroll_pos
        rts

scroll_up:                      ; elevator up / contents down
        lda     vert_scroll_pos
        jsr     do_scroll_up
        sta     vert_scroll_pos
        rts

horiz_scroll_flag:      .byte   0 ; can scroll horiz?
vert_scroll_flag:       .byte   0 ; can scroll vert?
horiz_scroll_pos:       .byte   0
horiz_scroll_max:       .byte   0
vert_scroll_pos:        .byte   0
vert_scroll_max:        .byte   0

.proc do_scroll_right
        stx     max
        cmp     max
        beq     :+
        sta     updatethumb_stash
        inc     updatethumb_stash
        copy    #MGTK::Ctl::horizontal_scroll_bar, updatethumb_which_ctl
        jsr     update_scroll_thumb
        lda     updatethumb_stash
:       rts

max:   .byte   0
.endproc

.proc do_scroll_left
        beq     :+
        sta     updatethumb_stash
        dec     updatethumb_stash
        copy    #MGTK::Ctl::horizontal_scroll_bar, updatethumb_which_ctl
        jsr     update_scroll_thumb
        lda     updatethumb_stash
:       rts
        .byte   0
.endproc

.proc do_scroll_down
        stx     max
        cmp     max
        beq     :+
        sta     updatethumb_stash
        inc     updatethumb_stash
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_which_ctl
        jsr     update_scroll_thumb
        lda     updatethumb_stash
:       rts

max:   .byte   0
.endproc

.proc do_scroll_up
        beq     :+
        sta     updatethumb_stash
        dec     updatethumb_stash
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_which_ctl
        jsr     update_scroll_thumb
        lda     updatethumb_stash
:       rts

        .byte   0
.endproc

;;; Output: A = hscroll pos, X = hscroll max, Y = hscroll active flag (high bit)
.proc get_active_window_hscroll_info
        ptr := $06

        lda     active_window_id
        jsr     window_lookup
        stax    ptr
        ldy     #MGTK::Winfo::hthumbmax
        lda     (ptr),y
        tax
        iny                     ; hthumbpos
        lda     (ptr),y
        pha
        ldy     #MGTK::Winfo::hscroll
        lda     (ptr),y
        and     #$01            ; active flag
        clc
        ror     a
        ror     a               ; shift to high bit
        tay
        pla
        rts
.endproc

;;; Output: A = vscroll pos, X = vscroll max, Y = vscroll active flag (high bit)
.proc get_active_window_vscroll_info
        ptr := $06

        lda     active_window_id
        jsr     window_lookup
        stax    ptr
        ldy     #MGTK::Winfo::vthumbmax
        lda     (ptr),y
        tax
        iny
        lda     (ptr),y
        pha
        ldy     #MGTK::Winfo::vscroll
        lda     (ptr),y
        and     #$01            ; active flag
        clc
        ror     a
        ror     a               ; shift to high bit
        tay
        pla
        rts
.endproc

;;; ============================================================

.proc cmd_check_drives
        copy    #0, pending_alert
        jsr     LoadDesktopIconTable
        jsr     cmd_close_all
        jsr     clear_selection
        jsr     reset_main_grafport
        ldx     cached_window_icon_count
        dex
L5916:  lda     cached_window_icon_list,x
        cmp     trash_icon_num
        beq     L5942
        txa
        pha
        lda     cached_window_icon_list,x
        sta     icon_param
        copy    #0, cached_window_icon_list,x
        ITK_RELAY_CALL IconTK::RemoveIcon, icon_param
        lda     icon_param
        jsr     FreeIcon
        dec     cached_window_icon_count
        dec     icon_count

        pla
        tax
L5942:  dex
        bpl     L5916

        ;; Enumerate DEVLST in reverse order (most important volumes first)
        ldy     DEVCNT
        sty     devlst_index
@loop:  ldy     devlst_index
        inc     cached_window_icon_count
        inc     icon_count
        lda     #0
        sta     device_to_icon_map,y
        lda     DEVLST,y
        ldx     cached_window_icon_count
        jsr     create_volume_icon ; A = unit num, Y = device num, X = icon index
        cmp     #ERR_DUPLICATE_VOLUME
        bne     :+
        lda     #kErrDuplicateVolName
        sta     pending_alert
:       dec     devlst_index
        lda     devlst_index
        bpl     @loop

        ldx     #0
L5976:  cpx     cached_window_icon_count
        bne     L5986
        lda     pending_alert
        beq     L5983
        jsr     ShowAlert
L5983:  jmp     StoreWindowIconTable

L5986:  txa
        pha
        lda     cached_window_icon_list,x
        cmp     trash_icon_num
        beq     L5998
        jsr     icon_entry_lookup
        ldy     #IconTK::AddIcon
        jsr     ITK_RELAY   ; icon entry addr in A,X
L5998:  pla
        tax
        inx
        jmp     L5976
.endproc

;;; ============================================================

devlst_index:
        .byte   0

pending_alert:
        .byte   0

;;; ============================================================
;;; Check > [drive] command - obsolete, but core still used
;;; following Format (etc)
;;;

.proc cmd_check_single_drive

        ;; index in DEVLST
        devlst_index  := menu_click_params::item_num

        ;; Check Drive command
by_menu:
        lda     #$00
        beq     start

        ;; After format/erase
by_unit_number:
        lda     #$80
        bne     start

        ;; After open/eject/rename
by_icon_number:
        lda     #$C0

start:  sta     check_drive_flags
        jsr     LoadDesktopIconTable
        bit     check_drive_flags
        bpl     explicit_command
        bvc     after_format_erase

;;; --------------------------------------------------
;;; After an Open/Eject/Rename action

        ;; Map icon number to index in DEVLST
        lda     drive_to_refresh
        ldy     #15
:       cmp     device_to_icon_map,y
        beq     :+
        dey
        bpl     :-

:       sty     previous_icon_count ; BUG: overwritten?
        sty     devlst_index
        jmp     common

;;; --------------------------------------------------
;;; After a Format/Erase action

after_format_erase:

        ;; Map unit number to index in DEVLST
        ldy     DEVCNT
        lda     drive_to_refresh
:       cmp     DEVLST,y
        beq     :+
        dey
        bpl     :-
        iny
:       sty     previous_icon_count ; BUG: overwritten?
        sty     devlst_index
        jmp     common

;;; --------------------------------------------------
;;; Check Drive command

explicit_command:
        ;; Map menu number to index in DEVLST
        lda     menu_click_params::item_num
        sec
        sbc     #3
        sta     devlst_index

;;; --------------------------------------------------

common:
        ldy     devlst_index
        lda     device_to_icon_map,y
        bne     :+
        jmp     not_in_map

        ;; Close any associated windows.

        ;; A = icon number
:       jsr     icon_entry_name_lookup

        ptr := $06
        path_buf := $1F00

        ;; Copy volume path to $1F00
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     path_buf,y
        dey
        bpl     :-

        ;; Find all windows with path as prefix, and close them.
        dec     path_buf
        lda     #'/'
        sta     path_buf+1
        ldax    #path_buf
        ldy     path_buf
        jsr     find_windows_for_prefix
        lda     found_windows_count
        beq     not_in_map

close_loop:
        ldx     found_windows_count
        beq     not_in_map
        dex
        lda     found_windows_list,x
        cmp     active_window_id
        beq     :+
        sta     findwindow_window_id
        jsr     handle_inactive_window_click

:       jsr     close_window
        dec     found_windows_count
        jmp     close_loop

not_in_map:

        jsr     redraw_windows_and_desktop
        jsr     clear_selection
        jsr     LoadDesktopIconTable

        lda     devlst_index
        tay
        pha

        lda     device_to_icon_map,y
        sta     icon_param
        beq     :+

        jsr     remove_icon_from_window
        dec     icon_count
        lda     icon_param
        jsr     FreeIcon
        jsr     reset_main_grafport
        ITK_RELAY_CALL IconTK::RemoveIcon, icon_param

:       lda     cached_window_icon_count
        sta     previous_icon_count
        inc     cached_window_icon_count
        inc     icon_count

        pla
        tay
        lda     DEVLST,y
        ldx     icon_param      ; preserve icon index if known
        bne     :+
        ldx     cached_window_icon_count
:       jsr     create_volume_icon ; A = unit num, Y = device num, X = icon index
        bit     check_drive_flags
        bmi     add_icon

        ;; Explicit command
        and     #$FF            ; check create_volume_icon results
        beq     add_icon
        cmp     #ERR_IO_ERROR   ; there was an error
        beq     add_icon
        pha
        jsr     StoreWindowIconTable
        pla
        jsr     ShowAlert
        rts

add_icon:
        lda     cached_window_icon_count
        cmp     previous_icon_count
        beq     :+

        ;; If a new icon was added, more work is needed.
        ldx     cached_window_icon_count
        dex
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup
        ldy     #IconTK::AddIcon
        jsr     ITK_RELAY   ; icon entry addr in A,X

:       jsr     StoreWindowIconTable
        jmp     redraw_windows_and_desktop

previous_icon_count:
        .byte    0

;;; 0 = command, $80 = format/erase, $C0 = open/eject/rename
check_drive_flags:
        .byte   0

.endproc

        cmd_check_single_drive_by_menu := cmd_check_single_drive::by_menu
        cmd_check_single_drive_by_unit_number := cmd_check_single_drive::by_unit_number
        cmd_check_single_drive_by_icon_number := cmd_check_single_drive::by_icon_number


;;; ============================================================

.proc cmd_startup_item
        ldx     menu_click_params::item_num
        dex
        txa
        asl     a
        asl     a
        asl     a
        clc
        adc     #6
        tax
        lda     startup_menu_item_1,x
        sec
        sbc     #'0'
        clc
        adc     #>$C000         ; compute $Cn00
        sta     reset_and_invoke_target+1
        lda     #<$0000
        sta     reset_and_invoke_target
        ;; fall through
.endproc

        ;; also invoked by launcher code
.proc reset_and_invoke
        ;; Restore system state: devices, /RAM, ROM/ZP banks.
        jsr     restore_system

        ;; also used by launcher code
        target := *+1
        jmp     dummy0000       ; self-modified
.endproc
        reset_and_invoke_target := reset_and_invoke::target

;;; ============================================================

active_window_view_by:
        .byte   0

.proc handle_client_click
        jsr     LoadActiveWindowIconTable
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        sta     active_window_view_by

        MGTK_RELAY_CALL MGTK::FindControl, event_coords
        lda     findcontrol_which_ctl
        bne     :+
        jmp     handle_content_click ; 0 = ctl_not_a_control
:       cmp     #MGTK::Ctl::dead_zone
        bne     :+
        rts
:       cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     horiz

        ;; Vertical scrollbar
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$05
        lda     ($06),y
        and     #$01
        bne     :+
        jmp     done_client_click
:       jsr     get_active_window_scroll_info
        lda     findcontrol_which_part
        cmp     #MGTK::Part::thumb
        bne     :+
        jsr     do_track_thumb
        jmp     done_client_click

:       cmp     #MGTK::Part::up_arrow
        bne     :+
up:     jsr     scroll_up
        lda     #MGTK::Part::up_arrow
        jsr     check_control_repeat
        bpl     up
        jmp     done_client_click

:       cmp     #MGTK::Part::down_arrow
        bne     :+
down:   jsr     scroll_down
        lda     #MGTK::Part::down_arrow
        jsr     check_control_repeat
        bpl     down
        jmp     done_client_click

:       cmp     #MGTK::Part::page_down
        beq     pgdn
pgup:   jsr     scroll_page_up
        lda     #MGTK::Part::page_up
        jsr     check_control_repeat
        bpl     pgup
        jmp     done_client_click

pgdn:   jsr     scroll_page_down
        lda     #MGTK::Part::page_down
        jsr     check_control_repeat
        bpl     pgdn
        jmp     done_client_click

        ;; Horizontal scrollbar
horiz:  lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$04
        lda     ($06),y
        and     #$01
        bne     :+
        jmp     done_client_click
:       jsr     get_active_window_scroll_info
        lda     findcontrol_which_part
        cmp     #MGTK::Part::thumb
        bne     :+
        jsr     do_track_thumb
        jmp     done_client_click

:       cmp     #MGTK::Part::left_arrow
        bne     :+
left:   jsr     scroll_left
        lda     #MGTK::Part::left_arrow
        jsr     check_control_repeat
        bpl     left
        jmp     done_client_click

:       cmp     #MGTK::Part::right_arrow
        bne     :+
rght:   jsr     scroll_right
        lda     #MGTK::Part::right_arrow
        jsr     check_control_repeat
        bpl     rght
        jmp     done_client_click

:       cmp     #MGTK::Part::page_right
        beq     pgrt
pglt:   jsr     scroll_page_left
        lda     #MGTK::Part::page_left
        jsr     check_control_repeat
        bpl     pglt
        jmp     done_client_click

pgrt:   jsr     scroll_page_right
        lda     #MGTK::Part::page_right
        jsr     check_control_repeat
        bpl     pgrt
        jmp     done_client_click

done_client_click:
        jsr     StoreWindowIconTable
        jmp     LoadDesktopIconTable
.endproc

;;; ============================================================

.proc do_track_thumb
        lda     findcontrol_which_ctl
        sta     trackthumb_which_ctl
        MGTK_RELAY_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_thumbmoved
        bne     :+
        rts
:       jsr     update_scroll_thumb
        jsr     StoreWindowIconTable
        jmp     LoadDesktopIconTable
.endproc

;;; ============================================================

.proc update_scroll_thumb
        copy    updatethumb_stash, updatethumb_thumbpos
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     apply_active_winfo_to_window_grafport
        jsr     compute_new_scroll_max
        bit     active_window_view_by
        bmi     :+              ; list view, no icons
        jsr     cached_icons_window_to_screen

:       lda     active_window_id
        jsr     set_port_from_window_id

        MGTK_RELAY_CALL MGTK::PaintRect, window_grafport::cliprect
        jsr     reset_main_grafport
        jmp     draw_window_entries
.endproc

;;; ============================================================
;;; Handle mouse held down on scroll arrow/pager

.proc check_control_repeat
        sta     ctl
        jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::drag
        beq     :+
bail:   return  #$FF            ; high bit set = not repeating

:       MGTK_RELAY_CALL MGTK::FindControl, event_coords
        lda     findcontrol_which_ctl
        beq     bail
        cmp     #MGTK::Ctl::dead_zone
        beq     bail
        lda     findcontrol_which_part
        cmp     ctl
        bne     bail
        return  #0              ; high bit set = repeating

ctl:    .byte   0
.endproc

;;; ============================================================

.proc handle_content_click
        ;; Subsequent action was not triggered by a menu, so hilite is not
        ;; necessary. https://github.com/a2stuff/a2d/issues/139
        copy    #$FF, menu_click_params::menu_id

        jsr     detect_double_click
        sta     double_click_flag

        bit     active_window_view_by
        bpl     :+
        jmp     clear_selection

:       copy    active_window_id, findicon_window_id
        ITK_RELAY_CALL IconTK::FindIcon, findicon_params
        lda     findicon_which_icon
        bne     handle_file_icon_click
        jsr     L5F13
        jmp     swap_in_desktop_icon_table
.endproc

;;; ============================================================


.proc handle_file_icon_click_impl
icon_num:  .byte   0

start:  sta     icon_num
        ldx     selected_icon_count
        beq     L5CFB
        dex
        lda     icon_num
L5CE6:  cmp     selected_icon_list,x
        beq     L5CF0
        dex
        bpl     L5CE6
        bmi     L5CFB
L5CF0:  bit     double_click_flag
        bmi     L5CF8
        jmp     handle_double_click

L5CF8:  jmp     start_icon_drag

        ;; Open-Apple: Extend selection (if in same window)
L5CFB:  bit     BUTN0
        bpl     replace
        lda     selected_window_index
        cmp     active_window_id ; same window?
        beq     :+               ; if so, retain selection
replace:
        jsr     clear_selection
:
        lda     icon_num
        jsr     select_file_icon

        bit     double_click_flag
        bmi     start_icon_drag
        jmp     handle_double_click

        ;; --------------------------------------------------

start_icon_drag:
        copy    icon_num, drag_drop_params::icon
        ITK_RELAY_CALL IconTK::DragHighlighted, drag_drop_params
        tax
        lda     drag_drop_params::result
        beq     desktop

process_drop:
        jsr     jt_drop

        ;; Failed?
        cmp     #$FF
        bne     :+
        jsr     swap_in_desktop_icon_table
        jmp     redraw_windows_and_desktop

        ;; Was a move?
:       bit     move_flag
        bpl     :+
        ;; Update source vol's contents
        jsr     update_active_window
        ;; fall through

        ;; Dropped on trash?
:       lda     drag_drop_params::result
        cmp     trash_icon_num
        bne     :+
        ;; Update used/free for same-vol windows
        jsr     update_active_window
        jmp     redraw_windows_and_desktop

        ;; Dropped on icon?
:       lda     drag_drop_params::result
        bmi     :+
        ;; Update used/free for same-vol windows
        jsr     update_vol_free_used_for_icon
        jmp     redraw_windows_and_desktop

        ;; Dropped on window!
:       and     #$7F            ; mask off window number
        pha
        jsr     update_used_free_for_vol_windows
        pla
        jsr     select_and_refresh_window
        jmp     redraw_windows_and_desktop

        ;; --------------------------------------------------

desktop:
        cpx     #$02
        bne     :+
        jmp     swap_in_desktop_icon_table

:       cpx     #$FF
        beq     L5DF7

        lda     active_window_id
        jsr     set_port_from_window_id

        jsr     cached_icons_screen_to_window
        jsr     offset_window_grafport_and_set

        ldx     selected_icon_count
        dex
:       txa
        pha
        lda     selected_icon_list,x
        sta     redraw_icon_param
        ITK_RELAY_CALL IconTK::RedrawIcon, redraw_icon_param
        pla
        tax
        dex
        bpl     :-

        lda     active_window_id
        jsr     set_port_from_window_id

        jsr     update_scrollbars
        jsr     cached_icons_window_to_screen
        jsr     reset_main_grafport

;;; Used as additional entry point
swap_in_desktop_icon_table:
        jsr     StoreWindowIconTable
        jmp     LoadDesktopIconTable

L5DF7:  ldx     saved_stack
        txs
        rts

handle_double_click:
        ;; Source window to close?
        jsr     set_window_to_close_after_open

        lda     icon_num           ; after a double-click (on file or folder)
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #kIconEntryTypeMask

        cmp     #kIconEntryTypeTrash
        beq     done
        cmp     #kIconEntryTypeDir
        bne     file

        ;; Directory
        lda     icon_num
        jsr     open_folder_or_volume_icon
        bmi     done
        jsr     swap_in_desktop_icon_table

        ;; If Apple key is down, close previous window.
        jsr     close_window_after_open

done:   rts

        ;; File (executable or data)
file:   sta     icon_entry_type
        lda     active_window_id
        jsr     window_path_lookup
        stax    $06

        ldy     #0
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     :-

        lda     icon_num
        jsr     icon_entry_lookup
        stax    $06

        ldy     #IconEntry::name
        lda     ($06),y
        tax
        clc
        adc     #IconEntry::name
        tay
:       lda     ($06),y
        sta     buf_filename2,x
        dey
        dex
        bpl     :-

        lda     icon_entry_type ; WTF - dead code ???
        cmp     #kIconEntryTypeBinary
        bcc     :+
        lda     icon_entry_type

:       jmp     launch_file     ; when double-clicked

.proc update_active_window
        lda     active_window_id
        jsr     update_used_free_for_vol_windows
        lda     active_window_id
        jmp     select_and_refresh_window
.endproc

icon_entry_type:
        .byte   0

.endproc
        handle_file_icon_click := handle_file_icon_click_impl::start
        swap_in_desktop_icon_table := handle_file_icon_click_impl::swap_in_desktop_icon_table
        process_drop := handle_file_icon_click_impl::process_drop

;;; ============================================================
;;; Add specified icon (in active window!) to selection list,
;;; and redraw.
;;; Input: A = icon number

.proc select_file_icon
        sta     icon_num
        ldx     selected_icon_count
        sta     selected_icon_list,x
        inc     selected_icon_count
        copy    active_window_id, selected_window_index

        lda     active_window_id
        jsr     set_port_from_window_id

        copy    icon_num, icon_param
        jsr     icon_screen_to_window

        jsr     offset_window_grafport_and_set
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param

        lda     active_window_id
        jsr     set_port_from_window_id

        lda     icon_num
        jsr     icon_window_to_screen
        jmp     reset_main_grafport

icon_num:
        .byte   0
.endproc

;;; ============================================================

.proc select_and_refresh_window
        sta     window_id
        jsr     redraw_windows_and_desktop
        jsr     clear_selection
        lda     window_id
        cmp     active_window_id
        beq     :+
        sta     findwindow_window_id
        jsr     handle_inactive_window_click ; bring to front

:       lda     active_window_id
        jsr     set_port_from_window_id

        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, window_grafport::cliprect

        lda     active_window_id
        pha
        jsr     remove_window_filerecord_entries

        lda     window_id
        tax
        dex
        lda     win_view_by_table,x
        bmi     :+              ; list view, not icons
        jsr     close_active_window
:       lda     active_window_id
        jsr     window_path_lookup

        ptr := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     open_dir_path_buf,y
        dey
        bpl     :-

        pla                     ; window id
        jsr     open_directory
        jsr     cmd_view_by_icon::entry
        jsr     StoreWindowIconTable
        jsr     LoadActiveWindowIconTable
        copy    active_window_id, getwinport_params2::window_id
        jsr     get_port2
        jsr     draw_window_header
        lda     #0
        ldx     active_window_id
        sta     win_view_by_table-1,x

        copy    #1, menu_click_params::item_num
        jsr     update_view_menu_check
        jmp     LoadDesktopIconTable

window_id:
        .byte   0
.endproc

;;; ============================================================
;;; Drag Selection

.proc L5F13_impl

pt1:    DEFINE_POINT 0, 0
pt2:    DEFINE_POINT 0, 0

start:  copy16  #notpenXOR, $06
        jsr     L60D5

        ldx     #.sizeof(MGTK::Point)-1
L5F20:  lda     event_coords,x
        sta     pt1,x
        sta     pt2,x
        dex
        bpl     L5F20

        jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::drag
        beq     L5F3F
        bit     BUTN0
        bmi     L5F3E
        jsr     clear_selection
L5F3E:  rts

L5F3F:  jsr     clear_selection
        lda     active_window_id
        jsr     offset_and_set_port_from_window_id
        ldx     #$03
L5F50:  lda     pt1,x
        sta     tmp_rect::x1,x
        lda     pt2,x
        sta     tmp_rect::x2,x
        dex
        bpl     L5F50
        jsr     set_penmode_xor
        jsr     frame_tmp_rect
L5F6B:  jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::drag
        beq     L5FC5
        jsr     frame_tmp_rect
        ldx     #$00
L5F80:  cpx     cached_window_icon_count
        bne     L5F88
        jmp     reset_main_grafport

L5F88:  txa
        pha
        lda     cached_window_icon_list,x
        sta     icon_param
        jsr     icon_screen_to_window
        ITK_RELAY_CALL IconTK::IconInRect, icon_param
        beq     L5FB9
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param
        ldx     selected_icon_count
        inc     selected_icon_count
        copy    icon_param, selected_icon_list,x
        copy    active_window_id, selected_window_index
L5FB9:  lda     icon_param
        jsr     icon_window_to_screen
        pla
        tax
        inx
        jmp     L5F80

L5FC5:  jsr     L60D5
        sub16   event_xcoord, L60CF, L60CB
        sub16   event_ycoord, L60D1, L60CD
        lda     L60CC
        bpl     L5FFE
        lda     L60CB
        eor     #$FF
        sta     L60CB
        inc     L60CB
L5FFE:  lda     L60CE
        bpl     L600E
        lda     L60CD
        eor     #$FF
        sta     L60CD
        inc     L60CD
L600E:  lda     L60CB
        cmp     #$05
        bcs     L601F
        lda     L60CD
        cmp     #$05
        bcs     L601F
        jmp     L5F6B

L601F:  jsr     frame_tmp_rect

        COPY_STRUCT MGTK::Point, event_coords, L60CF

        cmp16   event_xcoord, tmp_rect::x2
        bpl     L6068
        cmp16   event_xcoord, tmp_rect::x1
        bmi     L6054
        bit     L60D3
        bpl     L6068
L6054:  copy16  event_xcoord, tmp_rect::x1
        copy    #$80, L60D3
        jmp     L6079

L6068:  copy16  event_xcoord, tmp_rect::x2
        copy    #0, L60D3
L6079:  cmp16   event_ycoord, tmp_rect::y2
        bpl     L60AE
        cmp16   event_ycoord, tmp_rect::y1
        bmi     L609A
        bit     L60D4
        bpl     L60AE
L609A:  copy16  event_ycoord, tmp_rect::y1
        copy    #$80, L60D4
        jmp     L60BF

L60AE:  copy16  event_ycoord, tmp_rect::y2
        copy    #0, L60D4
L60BF:  jsr     frame_tmp_rect
        jmp     L5F6B

L60CB:  .byte   0
L60CC:  .byte   0
L60CD:  .byte   0
L60CE:  .byte   0
L60CF:  .word   0
L60D1:  .word   0
L60D3:  .byte   0
L60D4:  .byte   0

L60D5:  jsr     push_pointers
        jmp     icon_ptr_screen_to_window
.endproc
        L5F13 := L5F13_impl::start

;;; ============================================================

.proc handle_title_click
        ptr := $06

        kMinYPosition = kMenuBarHeight + kTitleBarHeight

        jmp     :+

:       copy    active_window_id, event_params
        MGTK_RELAY_CALL MGTK::FrontWindow, active_window_id
        lda     active_window_id
        jsr     copy_window_portbits
        MGTK_RELAY_CALL MGTK::DragWindow, event_params
        lda     active_window_id
        jsr     window_lookup
        stax    ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        lda     (ptr),y
        cmp     #kMinYPosition
        bcs     :+
        lda     #kMinYPosition
        sta     (ptr),y

:       ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::xcoord
        sub16in (ptr),y, port_copy+MGTK::GrafPort::viewloc+MGTK::Point::xcoord, deltax
        iny
        sub16in (ptr),y, port_copy+MGTK::GrafPort::viewloc+MGTK::Point::ycoord, deltay

        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        beq     :+           ; view by icon
        rts

        ;; Update icon positions
:       jsr     LoadActiveWindowIconTable
        ldx     #0
next:   cpx     cached_window_icon_count
        bne     :+
        jsr     StoreWindowIconTable
        jsr     LoadDesktopIconTable
        jmp     done

:       txa
        pha
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup
        stax    ptr
        ldy     #IconEntry::iconx
        add16in (ptr),y, deltax, (ptr),y
        iny
        add16in (ptr),y, deltay, (ptr),y
        pla
        tax
        inx
        jmp     next

done:   rts

deltax: .word   0
deltay: .word   0

.endproc

;;; ============================================================

.proc handle_resize_click
        copy    active_window_id, event_params
        MGTK_RELAY_CALL MGTK::GrowWindow, event_params
        jsr     redraw_windows_and_desktop
        jsr     LoadActiveWindowIconTable
        jsr     cached_icons_screen_to_window
        jsr     update_scrollbars
        jsr     cached_icons_window_to_screen
        jsr     LoadDesktopIconTable
        jmp     reset_main_grafport
.endproc

;;; ============================================================

handle_close_click:
        lda     active_window_id
        MGTK_RELAY_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        bne     close_window
        rts

.proc close_window
        icon_ptr := $06

        jsr     LoadActiveWindowIconTable

        jsr     clear_selection

        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        bmi     iter            ; list view, not icons

        lda     icon_count
        sec
        sbc     cached_window_icon_count
        sta     icon_count

        ITK_RELAY_CALL IconTK::CloseWindow, active_window_id

        jsr     free_cached_window_icons

iter:   dec     num_open_windows
        ldx     #0
        txa
:       sta     cached_window_icon_list,x
        cpx     cached_window_icon_count
        beq     cont
        inx
        jmp     :-

cont:   sta     cached_window_icon_count
        jsr     StoreWindowIconTable
        MGTK_RELAY_CALL MGTK::CloseWindow, active_window_id

        ;; Unhighlight dir (vol/folder) icon, if present
        ldx     active_window_id
        dex
        lda     window_to_dir_icon_table,x
        bmi     no_icon         ; $FF = dir icon freed
        sta     icon_param
        jsr     icon_entry_lookup
        stax    icon_ptr

        ldy     #IconEntry::state
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        beq     no_icon         ; ???

        ldy     #IconEntry::win_type
        lda     (icon_ptr),y
        and     #AS_BYTE(~kIconEntryOpenMask) ; clear open_flag
        sta     (icon_ptr),y
        and     #kIconEntryWinIdMask
        sta     selected_window_index
        jsr     prepare_highlight_grafport
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param
        jsr     reset_main_grafport
        copy    #1, selected_icon_count
        copy    icon_param, selected_icon_list

        ;; Animate closing into dir (vol/folder) icon
        ldx     active_window_id
        dex
        lda     window_to_dir_icon_table,x
        inx
        jsr     animate_window_close

no_icon:
        lda     active_window_id
        jsr     remove_window_filerecord_entries

        ldx     active_window_id
        dex
        lda     #0
        sta     window_to_dir_icon_table,x ; 0 = window free
        sta     win_view_by_table,x

        MGTK_RELAY_CALL MGTK::FrontWindow, active_window_id
        jsr     LoadDesktopIconTable
        copy    #MGTK::checkitem_uncheck, checkitem_params::check
        jsr     check_item
        jsr     update_window_menu_items
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================
;;; Input:
;;;   Y = thumbmax
;;;   X = iconbb size - window size (scaled to fit in one byte)
;;;   A = cliprect edge - iconbb edge (i.e. old pos???)
;;; Output:
;;;   A = new thumbpos

;;; Seems to be a generic scaling function ???

.proc calculate_thumb_pos
        cmp     #1
        bcc     :+
        bne     start
:       return  #0

        ;; TODO: This looks like a division routine ???
        ;; n / d => A / 256 ???

start:  sta     L638B
        stx     L6385+1
        sty     L6389+1
        cmp     L6385+1
        bcc     :+
        tya
        rts

:       lda     #0
        sta     L6385
        sta     L6389
        lsr16   L6385
        lsr16   L6389

        lda     #0
        sta     L6383
        sta     L6387
        sta     L6383+1
        sta     L6387+1

loop:   lda     L6383+1
        cmp     L638B
        beq     finish
        bcc     :+              ; less?
        jsr     do_sub
        jmp     loop
:       jsr     do_add
        jmp     loop

finish: lda     L6387+1
        cmp     #1              ; why not bne ???
        bcs     :+
        lda     #1
:       rts

do_sub: sub16   L6383, L6385, L6383
        sub16   L6387, L6389, L6387
        lsr16   L6385
        lsr16   L6389
        rts

do_add: add16   L6383, L6385, L6383
        add16   L6387, L6389, L6387
        lsr16   L6385
        lsr16   L6389
        rts

L6383:  .word   0
L6385:  .word   0
L6387:  .word   0
L6389:  .word   0
L638B:  .byte   0

.endproc

;;; ============================================================

.proc scroll_page_up
        jsr     compute_active_window_dimensions
        sty     height
        jsr     calc_height_minus_header
        sta     useful_height

        sub16_8 window_grafport::cliprect::y1, useful_height, delta
        cmp16   delta, iconbb_rect+MGTK::Rect::y1
        bmi     clamp
        ldax    delta
        jmp     adjust

clamp:  ldax    iconbb_rect+MGTK::Rect::y1

adjust: stax    window_grafport::cliprect::y1
        add16_8 window_grafport::cliprect::y1, height, window_grafport::cliprect::y2
        jmp     finish_scroll_adjust_and_redraw

useful_height:
        .byte   0               ; without header
height: .byte   0               ; of window's port
delta:  .word   0

.endproc

;;; ============================================================

.proc scroll_page_down
        jsr     compute_active_window_dimensions
        sty     height
        jsr     calc_height_minus_header
        sta     useful_height

        add16_8 window_grafport::cliprect::y2, useful_height, delta
        cmp16   delta, iconbb_rect+MGTK::Rect::y2
        bpl     clamp
        ldax    delta
        jmp     adjust

clamp:  ldax    iconbb_rect+MGTK::Rect::y2

adjust: stax    window_grafport::cliprect::y2
        sub16_8 window_grafport::cliprect::y2, height, window_grafport::cliprect::y1
        jmp     finish_scroll_adjust_and_redraw

useful_height:
        .byte   0               ; without header
height: .byte   0               ; of window's port
delta:  .word   0
.endproc

;;; ============================================================
;;; Input: Y = window height
;;; Output: A = Window height without items/used/free header

.proc calc_height_minus_header

        kWindowHeaderHeight = 14 ; TODO: move somewhere common

        tya
        sec
        sbc     #14
        rts
.endproc

;;; ============================================================

.proc scroll_page_left
        jsr     compute_active_window_dimensions
        stax    width

        sub16   window_grafport::cliprect::x1, width, delta
        cmp16   delta, iconbb_rect+MGTK::Rect::x1
        bmi     clamp

        ldax    delta
        jmp     adjust

clamp:  ldax    iconbb_rect+MGTK::Rect::x1

adjust: stax    window_grafport::cliprect::x1
        add16   window_grafport::cliprect::x1, width, window_grafport::cliprect::x2
        jmp     finish_scroll_adjust_and_redraw

width:  .word   0               ; of window's port
delta:  .word   0
.endproc

;;; ============================================================

.proc scroll_page_right
        jsr     compute_active_window_dimensions
        stax    width

        add16   window_grafport::cliprect::x2, width, delta
        cmp16   delta, iconbb_rect+MGTK::Rect::x2
        bpl     clamp
        ldax    delta
        jmp     adjust

clamp:  ldax    iconbb_rect+MGTK::Rect::x2

adjust: stax    window_grafport::cliprect::x2
        sub16   window_grafport::cliprect::x2, width, window_grafport::cliprect::x1
        jmp     finish_scroll_adjust_and_redraw

width:  .word   0               ; of window's port
delta:  .word   0
.endproc

;;; ============================================================
;;; Computes dimensions of active window.
;;; If icon view, leaves icons mapped to window coords.
;;; Returns: Width in A,X, height in Y

.proc compute_active_window_dimensions
        bit     active_window_view_by
        bmi     :+              ; list view, not icons
        jsr     cached_icons_screen_to_window
:       jsr     apply_active_winfo_to_window_grafport
        jsr     compute_icons_bbox
        lda     active_window_id
        jmp     compute_window_dimensions
.endproc

;;; ============================================================

.proc apply_active_winfo_to_window_grafport
        ptr := $06

        lda     active_window_id
        jsr     window_lookup
        addax   #MGTK::Winfo::port, ptr
        ldy     #.sizeof(MGTK::GrafPort) + 1
:       lda     (ptr),y
        sta     window_grafport,y
        dey
        bpl     :-
        rts
.endproc

.proc assign_active_window_cliprect
        ptr := $6

        lda     active_window_id
        jsr     window_lookup
        stax    ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     window_grafport::cliprect,x
        sta     (ptr),y
        dey
        dex
        bpl     :-
        rts
.endproc

;;; ============================================================
;;; After scrolling which adjusts cliprect, update the window,
;;; scrollbars, and redraw the window contents.
;;; If icon view, restores icons mapped to screen coords.

.proc finish_scroll_adjust_and_redraw
        jsr     assign_active_window_cliprect
        jsr     update_scrollbars

        bit     active_window_view_by
        bmi     :+
        jsr     cached_icons_window_to_screen
:

        MGTK_RELAY_CALL MGTK::PaintRect, window_grafport::cliprect
        jsr     reset_main_grafport
        jmp     draw_window_entries
.endproc

;;; ============================================================

.proc update_hthumb
        winfo_ptr := $06

        lda     active_window_id
        jsr     compute_window_dimensions
        stax    win_width
        lda     active_window_id
        jsr     window_lookup
        stax    winfo_ptr
        ldy     #MGTK::Winfo::hthumbmax
        lda     (winfo_ptr),y
        tay

        sub16   iconbb_rect+MGTK::Rect::x2, iconbb_rect+MGTK::Rect::x1, size
        sub16   size, win_width, size
        lsr16   size            ; / 2
        ldx     size
        sub16   window_grafport::cliprect::x1, iconbb_rect+MGTK::Rect::x1, size
        bpl     pos
        lda     #0
        beq     calc            ; always

pos:    cmp16   window_grafport::cliprect::x2, iconbb_rect+MGTK::Rect::x2
        bmi     neg
        tya
        jmp     L65EE

neg:    lsr16   size            ; / 2
        lda     size
calc:   jsr     calculate_thumb_pos

L65EE:  sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::horizontal_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        rts

win_width:
        .word   0
size:   .word   0
.endproc

;;; ============================================================

.proc update_vthumb
        winfo_ptr := $06

        lda     active_window_id
        jsr     compute_window_dimensions
        sty     win_height
        lda     active_window_id
        jsr     window_lookup
        stax    winfo_ptr
        ldy     #MGTK::Winfo::vthumbmax
        lda     (winfo_ptr),y
        tay

        sub16   iconbb_rect+MGTK::Rect::y2, iconbb_rect+MGTK::Rect::y1, size
        sub16_8 size, win_height, size
        lsr16   size            ; / 4
        lsr16   size
        ldx     size
        sub16   window_grafport::cliprect::y1, iconbb_rect+MGTK::Rect::y1, size
        bpl     pos
        lda     #0
        beq     calc            ; always

pos:    cmp16   window_grafport::cliprect::y2, iconbb_rect+MGTK::Rect::y2
        bmi     neg
        tya
        jmp     L668D

neg:    lsr16   size            ; / 4
        lsr16   size
        lda     size
calc:   jsr     calculate_thumb_pos

L668D:  sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        rts

win_height:
        .byte   0
size:   .word   0
.endproc

;;; ============================================================

.proc update_window_menu_items
        ldx     active_window_id
        beq     disable_menu_items
        jmp     check_view_menu_items

disable_menu_items:
        copy    #MGTK::disablemenu_disable, disablemenu_params::disable
        MGTK_RELAY_CALL MGTK::DisableMenu, disablemenu_params

        copy    #MGTK::disableitem_disable, disableitem_params::disable
        copy    #kMenuIdFile, disableitem_params::menu_id
        lda     #aux::kMenuItemIdNewFolder
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdClose
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdCloseAll
        jsr     disable_menu_item

        copy    #0, menu_dispatch_flag
        rts

check_view_menu_items:
        dex
        lda     win_view_by_table,x
        and     #$0F            ; mask off menu item number
        tax
        inx
        stx     checkitem_params::menu_item
        copy    #MGTK::checkitem_check, checkitem_params::check
        jsr     check_item
        rts
.endproc

;;; ============================================================
;;; Disable menu items for operating on a selected file

.proc disable_file_menu_items
        copy    #MGTK::disableitem_disable, disableitem_params::disable

        ;; File
        copy    #kMenuIdFile, disableitem_params::menu_id
        lda     #aux::kMenuItemIdOpen
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdGetInfo
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdRenameIcon
        jsr     disable_menu_item

        ;; Special
        copy    #kMenuIdSpecial, disableitem_params::menu_id
        lda     #aux::kMenuItemIdLock
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdUnlock
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdGetSize
        jsr     disable_menu_item
        rts
.endproc

;;; ============================================================
;;; Calls DisableItem menu_item in A (to enable or disable).
;;; Set disableitem_params' disable flag and menu_id before calling.

.proc disable_menu_item
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        rts
.endproc

;;; ============================================================

.proc enable_file_menu_items
        copy    #MGTK::disableitem_enable, disableitem_params::disable

        ;; File
        copy    #kMenuIdFile, disableitem_params::menu_id
        lda     #aux::kMenuItemIdOpen
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdGetInfo
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdRenameIcon
        jsr     disable_menu_item

        ;; Special
        copy    #kMenuIdSpecial, disableitem_params::menu_id
        lda     #aux::kMenuItemIdLock
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdUnlock
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdGetSize
        jsr     disable_menu_item
        rts
.endproc

;;; ============================================================

.proc toggle_eject_menu_item
enable:
        copy    #MGTK::disableitem_enable, disableitem_params::disable
        jmp     :+

disable:
        copy    #MGTK::disableitem_disable, disableitem_params::disable

:       copy    #kMenuIdSpecial, disableitem_params::menu_id
        lda     #aux::kMenuItemIdEject
        jsr     disable_menu_item

        copy    #kMenuIdSpecial, disableitem_params::menu_id
        lda     #aux::kMenuItemIdCheckDrive
        jsr     disable_menu_item

        rts

.endproc
enable_eject_menu_item := toggle_eject_menu_item::enable
disable_eject_menu_item := toggle_eject_menu_item::disable

;;; ============================================================

.proc toggle_selector_menu_items
disable:
        copy    #MGTK::disableitem_disable, disableitem_params::disable
        jmp     :+

enable:
        copy    #MGTK::disableitem_enable, disableitem_params::disable

:       copy    #kMenuIdSelector, disableitem_params::menu_id
        lda     #kMenuItemIdSelectorEdit
        jsr     disable_menu_item
        lda     #kMenuItemIdSelectorDelete
        jsr     disable_menu_item
        lda     #kMenuItemIdSelectorRun
        jsr     disable_menu_item
        copy    #$80, LD344
        rts
.endproc
enable_selector_menu_items := toggle_selector_menu_items::enable
disable_selector_menu_items := toggle_selector_menu_items::disable

;;; ============================================================

.proc handle_volume_icon_click
        lda     selected_icon_count
        bne     L67DF
        jmp     set_selection

L67DF:  tax
        dex
        lda     findicon_which_icon
L67E4:  cmp     selected_icon_list,x
        beq     L67EE
        dex
        bpl     L67E4
        bmi     L67F6
L67EE:  bit     double_click_flag
        bmi     L6834
        jmp     L6880

L67F6:  bit     BUTN0
        bpl     replace_selection

        ;; Add clicked icon to selection
        lda     selected_window_index
        bne     replace_selection
        ITK_RELAY_CALL IconTK::HighlightIcon, findicon_which_icon
        ldx     selected_icon_count
        lda     findicon_which_icon
        sta     selected_icon_list,x
        inc     selected_icon_count
        jmp     L6834

        ;; Replace selection with clicked icon
replace_selection:
        jsr     clear_selection

        ;; Set selection to clicked icon
set_selection:
        ITK_RELAY_CALL IconTK::HighlightIcon, findicon_which_icon
        copy    #1, selected_icon_count
        copy    findicon_which_icon, selected_icon_list
        copy    #0, selected_window_index


L6834:  bit     double_click_flag
        bpl     L6880

        ;; Drag of volume icon
        copy    findicon_which_icon, drag_drop_params::icon
        ITK_RELAY_CALL IconTK::DragHighlighted, drag_drop_params
        tax
        lda     drag_drop_params::result
        beq     L6878
        jsr     jt_drop
        cmp     #$FF
        bne     L6858
        jmp     redraw_windows_and_desktop

L6858:  lda     drag_drop_params::result
        cmp     trash_icon_num
        bne     L6863
        jmp     redraw_windows_and_desktop

L6863:  lda     drag_drop_params::result
        bpl     L6872
        and     #$7F
        pha
        jsr     update_used_free_for_vol_windows
        pla
        jmp     select_and_refresh_window

L6872:  jsr     update_vol_free_used_for_icon
        jmp     redraw_windows_and_desktop

L6878:  txa
        cmp     #2
        bne     L688F
        jmp     redraw_windows_and_desktop

        ;; Double-click on volume icon
L6880:  lda     findicon_which_icon
        cmp     trash_icon_num
        beq     L688E
        jsr     open_folder_or_volume_icon
        jsr     StoreWindowIconTable
L688E:  rts

L688F:  ldx     selected_icon_count
        dex
L6893:  txa
        pha
        copy    selected_icon_list,x, icon_param3
        ITK_RELAY_CALL IconTK::RedrawIcon, icon_param3
        pla
        tax
        dex
        bpl     L6893
        rts
.endproc

;;; ============================================================

.proc L68AA
        jsr     reset_main_grafport
        bit     BUTN0
        bpl     L68B3
        rts

L68B3:  jsr     clear_selection
        ldx     #3
L68B8:  lda     event_coords,x
        sta     tmp_rect::x1,x
        sta     tmp_rect::x2,x
        dex
        bpl     L68B8
        jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::drag
        beq     L68CF
        rts

L68CF:  MGTK_RELAY_CALL MGTK::SetPattern, checkerboard_pattern
        jsr     set_penmode_xor
        jsr     frame_tmp_rect
L68E4:  jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::drag
        beq     L6932
        jsr     frame_tmp_rect
        ldx     #0
L68F9:  cpx     cached_window_icon_count
        bne     :+
        lda     #0
        sta     selected_window_index
        rts

:       txa
        pha
        copy    cached_window_icon_list,x, icon_param
        ITK_RELAY_CALL IconTK::IconInRect, icon_param
        beq     L692C
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param
        ldx     selected_icon_count
        inc     selected_icon_count
        copy    icon_param, selected_icon_list,x
L692C:  pla
        tax
        inx
        jmp     L68F9

L6932:  sub16   event_xcoord, L6A39, L6A35
        sub16   event_ycoord, L6A3B, L6A37
        lda     L6A36
        bpl     L6968
        lda     L6A35
        eor     #$FF
        sta     L6A35
        inc     L6A35
L6968:  lda     L6A38
        bpl     L6978
        lda     L6A37
        eor     #$FF
        sta     L6A37
        inc     L6A37
L6978:  lda     L6A35
        cmp     #$05
        bcs     L6989
        lda     L6A37
        cmp     #$05
        bcs     L6989
        jmp     L68E4

L6989:  jsr     frame_tmp_rect

        COPY_STRUCT MGTK::Point, event_coords, L6A39

        cmp16   event_xcoord, tmp_rect::x2
        bpl     L69D2
        cmp16   event_xcoord, tmp_rect::x1
        bmi     L69BE
        bit     L6A3D
        bpl     L69D2
L69BE:  copy16  event_xcoord, tmp_rect::x1
        copy    #$80, L6A3D
        jmp     L69E3

L69D2:  copy16  event_xcoord, tmp_rect::x2
        copy    #0, L6A3D
L69E3:  cmp16   event_ycoord, tmp_rect::y2
        bpl     L6A18
        cmp16   event_ycoord, tmp_rect::y1
        bmi     L6A04
        bit     L6A3E
        bpl     L6A18
L6A04:  copy16  event_ycoord, tmp_rect::y1
        copy    #$80, L6A3E
        jmp     L6A29

L6A18:  copy16  event_ycoord, tmp_rect::y2
        copy    #0, L6A3E
L6A29:  jsr     frame_tmp_rect
        jmp     L68E4

L6A35:  .byte   0
L6A36:  .byte   0
L6A37:  .byte   0
L6A38:  .byte   0
L6A39:  .word   0
L6A3B:  .word   0
L6A3D:  .byte   0
L6A3E:  .byte   0
.endproc

;;; ============================================================
;;; Update used/free values for windows related to volume icon
;;; Input: icon number in A

.proc update_vol_free_used_for_icon
        ptr := $6
        path_buf := $220

        jsr     find_window_for_dir_icon
        beq     L6A80           ; found

        ;; Not in the map. Look for related windows.
        jsr     icon_entry_name_lookup

        ldy     #0
        lda     (ptr),y
        tay
        dey
L6A5C:  lda     (ptr),y
        sta     path_buf,y
        dey
        bpl     L6A5C
        dec     path_buf
        lda     #'/'
        sta     path_buf+1

        ldax    #path_buf
        ldy     path_buf
        jsr     find_windows_for_prefix
        ldax    #path_buf
        ldy     path_buf
        jmp     update_vol_used_free_for_found_windows

        ;; Found it in the map.
L6A80:  inx
        txa
        pha
        jsr     update_used_free_for_vol_windows
        pla
        jmp     select_and_refresh_window
.endproc

;;; ============================================================
;;; Open a folder/volume icon
;;; Input: A = icon
;;; Note: stack will be restored via saved_stack on failure

.proc open_folder_or_volume_icon
        ptr := $06

        sta     icon_params2
        jsr     StoreWindowIconTable
        lda     icon_params2

        ;; Already an open window for the icon?
        ldx     #7
:       cmp     window_to_dir_icon_table,x
        beq     found_win
        dex
        bpl     :-
        jmp     no_linked_win

        ;; --------------------------------------------------
        ;; There is an existing window associated with icon.

found_win:
        ;; Is it the active window? If so, done!
        inx
        cpx     active_window_id
        bne     :+
        rts

        ;; Otherwise, bring the window to the front.
:       stx     cached_window_id
        jsr     LoadWindowIconTable

        jsr     update_icon

        ;; Find FileRecord list
        lda     cached_window_id
        ldx     window_id_to_filerecord_list_count
        dex
:       cmp     window_id_to_filerecord_list_entries,x
        beq     select          ; found - skip loading
        dex
        bpl     :-

        jsr     open_directory  ; not found - load it

select: MGTK_RELAY_CALL MGTK::SelectWindow, cached_window_id
        lda     cached_window_id
        sta     active_window_id
        jsr     draw_window_entries
        jsr     redraw_windows
        jmp     LoadDesktopIconTable

        ;; --------------------------------------------------
        ;; No associated window - check for matching path.

no_linked_win:
        ;; Compute the path (will be needed anyway).
        lda     icon_params2
        jsr     icon_entry_lookup
        stax    ptr
        jsr     compose_icon_full_path

        ;; Alternate entry point: opening via path.
check_path:
        addr_call find_window_for_path, open_dir_path_buf
        beq     no_win

        ;; Found a match - associate the window.
        tax
        dex                     ; 1-based to 0-based
        lda     icon_params2    ; set to $FF if opening via path
        bmi     :+
        sta     window_to_dir_icon_table,x
:       jmp     found_win

        ;; --------------------------------------------------
        ;; No window - need to open one.

no_win:
        ;; Is there a free window?
        lda     num_open_windows
        cmp     #kMaxNumWindows
        bcc     :+

        ;; Nope, show error.
        lda     #kWarningMsgTooManyWindows
        jsr     warning_dialog_proc_num
        ldx     saved_stack
        txs
        rts

        ;; Search window-icon map to find an unused window.
:       ldx     #0
:       lda     window_to_dir_icon_table,x
        beq     :+              ; 0 = window free
        inx
        jmp     :-

        ;; Map the window to its source icon
:       lda     icon_params2    ; set to $FF if opening via path
        sta     window_to_dir_icon_table,x
        inx                     ; 0-based to 1-based

        stx     cached_window_id
        jsr     LoadWindowIconTable

        ;; Update View and other menus
        inc     num_open_windows
        ldx     cached_window_id
        dex
        copy    #0, win_view_by_table,x

        lda     num_open_windows ; Was there already a window open?
        cmp     #2
        bcs     :+              ; yes, no need to enable file menu
        jsr     enable_various_file_menu_items
        jmp     update_view

:       copy    #MGTK::checkitem_uncheck, checkitem_params::check
        jsr     check_item

update_view:
        .assert MGTK::checkitem_check = aux::kMenuItemIdViewByIcon, error, "const mismatch"
        lda     #aux::kMenuItemIdViewByIcon
        sta     checkitem_params::menu_item
        sta     checkitem_params::check
        jsr     check_item

        jsr     update_icon

        ;; Set path, size, contents, and volume free/used.
        jsr     prepare_new_window

        ;; Create the window
        lda     cached_window_id
        jsr     window_lookup   ; A,X points at Winfo
        ldy     #MGTK::OpenWindow
        jsr     MGTK_RELAY

        lda     active_window_id
        jsr     set_port_from_window_id

        jsr     draw_window_header

        ;; Restore and add the icons
        jsr     cached_icons_screen_to_window
        copy    #0, num
:       lda     num
        cmp     cached_window_icon_count
        beq     done
        tax
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup ; A,X points at IconEntry
        ldy     #IconTK::AddIcon
        jsr     ITK_RELAY   ; icon entry addr in A,X
        inc     num
        jmp     :-

        ;; Finish up
done:   copy    cached_window_id, active_window_id
        jsr     update_scrollbars
        jsr     cached_icons_window_to_screen
        jsr     StoreWindowIconTable
        jsr     LoadDesktopIconTable
        jmp     reset_main_grafport

;;; Common code to update the dir (vol/folder) icon.
.proc update_icon
        lda     icon_params2    ; set to $FF if opening via path
        bmi     calc_name_ptr

        jsr     icon_entry_lookup
        stax    ptr

        ldy     #IconEntry::win_type
        lda     (ptr),y
        ora     #kIconEntryOpenMask ; set open_flag
        sta     (ptr),y

        ldy     #IconEntry::win_type ; get window id
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        sta     getwinport_params2::window_id

        beq     :+               ; window 0 = desktop
        cmp     active_window_id ; prep to redraw windowed (file) icon
        bne     done             ; but only if active window
        jsr     get_set_port2
        jsr     offset_window_grafport_and_set
        lda     icon_params2
        jsr     icon_screen_to_window
:       ITK_RELAY_CALL IconTK::RedrawIcon, icon_params2

        lda     getwinport_params2::window_id
        beq     done            ; skip if on desktop
        lda     icon_params2    ; restore from drawing
        jsr     icon_window_to_screen
        jsr     reset_main_grafport

done:   rts

calc_name_ptr:
        ;; Find last '/'
        ldy     open_dir_path_buf
:       lda     open_dir_path_buf,y
        cmp     #'/'
        beq     :+
        dey
        bpl     :-
:
        ;; Start building string
        ldx     #0

:       iny
        inx
        lda     open_dir_path_buf,y
        sta     buf_filename2,x
        cpy     open_dir_path_buf
        bne     :-

        stx     buf_filename2

        ;; Adjust ptr as if it's pointing at an IconEntry
        copy16  #buf_filename2 - IconEntry::name, ptr
        rts
.endproc

num:    .byte   0
.endproc

;;; ============================================================
;;; Open a folder/volume icon
;;; Input: |open_dir_path_buf| should have full path.
;;;   If a case match for existing window path, it will be activated.
;;; Note: stack will be restored via |saved_stack| on failure
;;;
;;; Set |suppress_error_on_open_flag| to avoid alert.

.proc open_window_for_path
        copy    #$FF, icon_params2
        jmp     open_folder_or_volume_icon::check_path
.endproc

;;; ============================================================

.proc check_item
        MGTK_RELAY_CALL MGTK::CheckItem, checkitem_params
        rts
.endproc

;;; ============================================================
;;; Draw all entries (icons or list items) in (cached) window

.proc draw_window_entries
        ptr := $06

        ldx     cached_window_id
        dex
        lda     win_view_by_table,x
        bmi     list_view           ; list view, not icons
        jmp     icon_view

        ;; --------------------------------------------------
        ;; List view
list_view:
        jsr     push_pointers

        lda     cached_window_id
        jsr     set_port_from_window_id

        bit     draw_window_header_flag
        bmi     :+
        jsr     draw_window_header
:       lda     cached_window_id
        sta     getwinport_params2::window_id
        jsr     get_port2
        bit     draw_window_header_flag
        bmi     :+
        jsr     offset_window_grafport_and_set
:

        ;; Find FileRecord list
        lda     cached_window_id
        ldx     #0
:       cmp     window_id_to_filerecord_list_entries,x
        beq     :+
        inx
        cpx     window_id_to_filerecord_list_count
        bne     :-
        rts

:       txa
        asl     a
        tax
        lda     window_filerecord_table,x
        sta     file_record_ptr ; points at head of list (entry count)
        sta     ptr
        lda     window_filerecord_table+1,x
        sta     file_record_ptr+1
        sta     ptr+1
        lda     LCBANK2
        lda     LCBANK2
        ldy     #0
        lda     (ptr),y         ; entry count
        tay
        lda     LCBANK1
        lda     LCBANK1
        tya
        sta     file_record_count
        inc16   file_record_ptr ; now points at first entry in list

        ;; First row
        lda     #16
        sta     pos_col_name::ycoord
        sta     pos_col_type::ycoord
        sta     pos_col_size::ycoord
        sta     pos_col_date::ycoord
        lda     #0
        sta     pos_col_name::ycoord+1
        sta     pos_col_type::ycoord+1
        sta     pos_col_size::ycoord+1
        sta     pos_col_date::ycoord+1

        ;; Draw each list view row
        lda     #0
        sta     rows_done
rloop:  lda     rows_done
        cmp     cached_window_icon_count
        beq     done
        tax
        lda     cached_window_icon_list,x
        jsr     draw_list_view_row
        inc     rows_done
        jmp     rloop

done:   jsr     reset_main_grafport
        jsr     pop_pointers
        rts

rows_done:
        .byte   0

        ;; --------------------------------------------------
        ;; Icon view
icon_view:
        lda     cached_window_id
        jsr     set_port_from_window_id

        bit     draw_window_header_flag
        bmi     :+
        jsr     draw_window_header
:       jsr     cached_icons_screen_to_window
        jsr     offset_window_grafport_and_set

        COPY_BLOCK window_grafport::cliprect, tmp_rect

        ldx     #0
        txa
        pha

loop:   cpx     cached_window_icon_count ; done?
        bne     draw                     ; nope...

        pla                     ; finish up...
        jsr     reset_main_grafport

        lda     cached_window_id
        jsr     set_port_from_window_id

        jsr     cached_icons_window_to_screen
        rts

draw:   txa
        pha
        lda     cached_window_icon_list,x
        sta     icon_param
        ITK_RELAY_CALL IconTK::IconInRect, icon_param
        beq     :+
        ITK_RELAY_CALL IconTK::RedrawIcon, icon_param
:       pla
        tax
        inx
        jmp     loop
.endproc

;;; ============================================================

.proc clear_selection
        lda     selected_icon_count
        bne     :+
        rts

:       copy    #0, index
        lda     selected_window_index
        beq     volumes
        cmp     active_window_id
        beq     use_win_port
        jsr     prepare_highlight_grafport
        jmp     files

        ;; Windowed (file icons)
use_win_port:
        jsr     set_port_from_window_id
        jsr     offset_window_grafport_and_set

files:  lda     index
        cmp     selected_icon_count
        beq     finish
        tax
        lda     selected_icon_list,x
        sta     icon_param
        jsr     icon_screen_to_window
        ITK_RELAY_CALL IconTK::UnhighlightIcon, icon_param
        lda     icon_param
        jsr     icon_window_to_screen
        inc     index
        jmp     files

        ;; Desktop (volume icons)
volumes:
        lda     index
        cmp     selected_icon_count
        beq     finish
        tax
        lda     selected_icon_list,x
        sta     icon_param
        ITK_RELAY_CALL IconTK::UnhighlightIcon, icon_param
        inc     index
        jmp     volumes

        ;; Clear selection list
finish: lda     #0
        ldx     selected_icon_count
        dex
:       sta     selected_icon_list,x
        dex
        bpl     :-
        sta     selected_icon_count
        sta     selected_window_index
        jmp     reset_main_grafport

index:  .byte   0
.endproc

;;; ============================================================

.proc update_scrollbars
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        bmi     :+              ; list view, not icons
        jsr     compute_icons_bbox
        jmp     config_port

        ;; List view
:       jsr     cached_icons_screen_to_window
        jsr     compute_icons_bbox
        jsr     cached_icons_window_to_screen

config_port:
        lda     active_window_id
        jsr     set_port_from_window_id

        ;; check horizontal bounds
        cmp16   iconbb_rect+MGTK::Rect::x1, window_grafport::cliprect::x1
        bmi     activate_hscroll
        cmp16   window_grafport::cliprect::x2, iconbb_rect+MGTK::Rect::x2
        bmi     activate_hscroll

        ;; deactivate horizontal scrollbar
        copy    #MGTK::Ctl::horizontal_scroll_bar, activatectl_which_ctl
        copy    #MGTK::activatectl_deactivate, activatectl_activate
        jsr     activate_ctl

        jmp     check_vscroll

activate_hscroll:
        ;; activate horizontal scrollbar
        copy    #MGTK::Ctl::horizontal_scroll_bar, activatectl_which_ctl
        copy    #MGTK::activatectl_activate, activatectl_activate
        jsr     activate_ctl
        jsr     update_hthumb

check_vscroll:
        ;; check vertical bounds
        cmp16   iconbb_rect+MGTK::Rect::y1, window_grafport::cliprect::y1
        bmi     activate_vscroll
        cmp16   window_grafport::cliprect::y2, iconbb_rect+MGTK::Rect::y2
        bmi     activate_vscroll

        ;; deactivate vertical scrollbar
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_which_ctl
        copy    #MGTK::activatectl_deactivate, activatectl_activate
        jsr     activate_ctl

        rts

activate_vscroll:
        ;; activate vertical scrollbar
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_which_ctl
        copy    #MGTK::activatectl_activate, activatectl_activate
        jsr     activate_ctl
        jmp     update_vthumb

activate_ctl:
        MGTK_RELAY_CALL MGTK::ActivateCtl, activatectl_params
        rts
.endproc

;;; ============================================================

.proc cached_icons_screen_to_window
        lda     #0
        sta     count
loop:   lda     count
        cmp     cached_window_icon_count
        beq     done
        tax
        lda     cached_window_icon_list,x
        jsr     icon_screen_to_window
        inc     count
        jmp     loop

done:   rts

count:  .byte   0
.endproc

;;; ============================================================

.proc cached_icons_window_to_screen
        lda     #0
        sta     index
loop:   lda     index
        cmp     cached_window_icon_count
        beq     done
        tax
        lda     cached_window_icon_list,x
        jsr     icon_window_to_screen
        inc     index
        jmp     loop

done:   rts

index:  .byte   0
.endproc

;;; ============================================================

.proc offset_window_grafport_impl

flag_clear:
        lda     #$80
        beq     :+
flag_set:
        lda     #0
:       sta     flag
        add16   window_grafport::viewloc::ycoord, #15, window_grafport::viewloc::ycoord
        add16   window_grafport::cliprect::y1, #15, window_grafport::cliprect::y1
        bit     flag
        bmi     done
        MGTK_RELAY_CALL MGTK::SetPort, window_grafport
done:   rts

flag:   .byte   0
.endproc
        offset_window_grafport := offset_window_grafport_impl::flag_clear
        offset_window_grafport_and_set := offset_window_grafport_impl::flag_set

;;; ============================================================

.proc enable_various_file_menu_items
        copy    #MGTK::disablemenu_enable, disablemenu_params::disable
        MGTK_RELAY_CALL MGTK::DisableMenu, disablemenu_params

        copy    #MGTK::disableitem_enable, disableitem_params::disable
        copy    #kMenuIdFile, disableitem_params::menu_id
        lda     #aux::kMenuItemIdNewFolder
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdClose
        jsr     disable_menu_item
        lda     #aux::kMenuItemIdCloseAll
        jsr     disable_menu_item

        copy    #$80, menu_dispatch_flag
        rts
.endproc

;;; ============================================================
;;; Refresh vol used/free for windows of same volume as win in A.
;;; Input: A = window id

.proc update_used_free_for_vol_windows
        ptr := $6

        jsr     window_path_lookup
        sta     ptr
        sta     pathptr
        stx     ptr+1
        stx     pathptr+1
        ldy     #0              ; length offset
        lda     (ptr),y
        sta     pathlen
        iny
loop:   iny                     ; start at 2nd character
        lda     (ptr),y
        cmp     #'/'
        beq     found
        cpy     pathlen
        beq     finish
        jmp     loop

found:  dey
finish: sty     pathlen
        addr_call_indirect find_windows_for_prefix, ptr ; ???
        ldax    pathptr
        ldy     pathlen
        jmp     update_vol_used_free_for_found_windows

pathptr:        .addr   0
pathlen:        .byte   0
.endproc

;;; ============================================================
;;; Update used/free for results of find_window[s]_for_prefix

.proc update_vol_used_free_for_found_windows
        ptr := $6

        stax    ptr
        sty     path_buffer

:       lda     (ptr),y
        sta     path_buffer,y
        dey
        bne     :-

        jsr     get_vol_free_used

        bne     done
        lda     found_windows_count
        beq     done
loop:   dec     found_windows_count
        bmi     done
        ldx     found_windows_count
        lda     found_windows_list,x
        sec
        sbc     #1
        asl     a
        tax
        copy16  vol_kb_used, window_k_used_table,x
        copy16  vol_kb_free, window_k_free_table,x
        jmp     loop

done:   rts
.endproc

;;; ============================================================
;;; Find position of last segment of path at (A,X), return in Y.
;;; For "/a/b", Y points at "/a"; if volume path, unchanged.

.proc find_last_path_segment
        ptr := $A

        stax    ptr

        ;; Find last slash in string
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        cmp     #'/'
        beq     slash
        dey
        bpl     :-

        ;; Oops - no slash
        ldy     #1

        ;; Restore original string
restore:
        dey
        lda     (ptr),y
        tay
        rts

        ;; Are we left with "/" ?
slash:  cpy     #1
        beq     restore
        dey
        rts
.endproc

;;; ============================================================

        ;; If 'prefix' version called, length in Y; otherwise use str len
.proc find_windows
        ptr := $6

exact:  stax    ptr
        lda     #$80
        bne     start

prefix: stax    ptr
        lda     #0

start:  sta     exact_match_flag
        bit     exact_match_flag
        bpl     :+
        ldy     #0              ; Use full length
        lda     (ptr),y
        tay

:       sty     path_buffer

        ;; Copy ptr to path_buffer
:       lda     (ptr),y
        sta     path_buffer,y
        dey
        bne     :-

        lda     #0
        sta     found_windows_count
        sta     window_num

loop:   inc     window_num
        lda     window_num
        cmp     #kMaxNumWindows+1 ; directory windows are 1-8
        bcc     check_window
        bit     exact_match_flag
        bpl     :+
        lda     #0
:       rts

check_window:
        jsr     window_lookup
        stax    ptr
        ldy     #MGTK::Winfo::status
        lda     (ptr),y
        beq     loop

        lda     window_num
        jsr     window_path_lookup
        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
        cmp     path_buffer
        beq     :+

        bit     exact_match_flag
        bmi     loop
        ldy     path_buffer
        iny
        lda     (ptr),y
        cmp     #'/'
        bne     loop
        dey

        ;; Case-insensitive comparison
:       lda     (ptr),y
        jsr     upcase_char
        sta     char
        lda     path_buffer,y
        jsr     upcase_char
        cmp     char
        bne     loop
        dey
        bne     :-

        bit     exact_match_flag
        bmi     done
        ldx     found_windows_count
        lda     window_num
        sta     found_windows_list,x
        inc     found_windows_count
        jmp     loop

done:   return  window_num

window_num:
        .byte   0
exact_match_flag:
        .byte   0
char:   .byte   0
.endproc
        find_window_for_path := find_windows::exact
        find_windows_for_prefix := find_windows::prefix

found_windows_count:
        .byte   0
found_windows_list:
        .res    8

;;; ============================================================

.proc open_directory
        jmp     start

        DEFINE_OPEN_PARAMS open_params, path_buffer, $800

        DEFINE_READ_PARAMS read_params, $0C00, $200
        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params4, path_buffer

        .byte   0
vol_kb_free:  .word   0
vol_kb_used:  .word   0

entry_length:
        .byte   0

L70C0:  .byte   $00
L70C1:  .byte   $00
L70C2:  .byte   $00
L70C3:  .byte   $00
L70C4:  .byte   $00

.proc start
        sta     window_id
        jsr     push_pointers

        COPY_BYTES kPathBufferSize, open_dir_path_buf, path_buffer

        jsr     do_open
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        jsr     do_read
        jsr     L72E2

        ldx     #0
:       lda     $0C00+SubdirectoryHeader::entry_length,x
        sta     entry_length,x
        inx
        cpx     #4
        bne     :-

        sub16   filerecords_free_end, filerecords_free_start, L72A8
        ldx     #$05
L710A:  lsr16   L72A8
        dex
        cpx     #$00
        bne     L710A
        lda     L70C2
        bne     L7147
        lda     icon_count
        clc
        adc     L70C1
        bcs     L7147
        cmp     #$7C
        bcs     L7147
        sub16_8 L72A8, DEVCNT, L72A8
        cmp16   L72A8, L70C1
        bcs     L7169
L7147:  lda     num_open_windows
        jsr     mark_icons_not_opened_1
        dec     num_open_windows
        jsr     redraw_windows_and_desktop
        jsr     do_close
        lda     active_window_id
        beq     L715F
        lda     #$03
        bne     L7161
L715F:  lda     #kWarningMsgWindowMustBeClosed2
L7161:  jsr     warning_dialog_proc_num
        ldx     saved_stack
        txs
        rts

        record_ptr := $06

L7169:  copy16  filerecords_free_start, record_ptr

        ;; Append entry to list
        lda     window_id_to_filerecord_list_count ; get pointer offset
        asl     a
        tax
        copy16  record_ptr, window_filerecord_table,x ; update pointer table
        ldx     window_id_to_filerecord_list_count    ; get window id offset
        lda     window_id
        sta     window_id_to_filerecord_list_entries,x ; update window id list
        inc     window_id_to_filerecord_list_count

        ;; Store entry count
        lda     L70C1
        pha
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
        pla
        sta     (record_ptr),y
        lda     LCBANK1
        lda     LCBANK1

        copy    #$FF, L70C4
        copy    #$00, L70C3

        entry_ptr := $08

        copy16  #$0C00 + SubdirectoryHeader::storage_type_name_length, entry_ptr

        ;; Advance past entry count
        inc16   record_ptr

        ;; Record is temporarily constructed at $1F00 then copied into place.
        record := $1F00

do_entry:
        inc     L70C4
        lda     L70C4
        cmp     L70C1
        bne     L71CB
        jmp     L7296

L71CB:  inc     L70C3
        lda     L70C3
        cmp     L70C0
        beq     L71E7
        add16_8 entry_ptr, entry_length, entry_ptr
        jmp     L71F7

L71E7:  copy    #$00, L70C3
        copy16  #$0C04, entry_ptr
        jsr     do_read

L71F7:  ldx     #$00
        ldy     #$00
        lda     (entry_ptr),y
        and     #$0F
        sta     record,x
        bne     L7223
        inc     L70C3
        lda     L70C3
        cmp     L70C0
        bne     L7212
        jmp     L71E7

L7212:  add16_8 entry_ptr, entry_length, entry_ptr
        jmp     L71F7

L7223:  iny
        inx

        ;; See FileRecord struct for record structure

        ;; TODO: Determine if this case adjustment is necessary
        txa
        pha
        tya
        pha
        addr_call_indirect adjust_fileentry_case, entry_ptr
        pla
        tay
        pla
        tax

        ;; name, file_type
:       lda     (entry_ptr),y
        sta     record,x
        iny
        inx
        cpx     #FileEntry::file_type+1 ; name and type
        bne     :-

        ;; blocks
        ldy     #FileEntry::blocks_used
        lda     (entry_ptr),y
        sta     record,x
        inx
        iny
        lda     (entry_ptr),y
        sta     record,x

        ;; creation date/time
        ldy     #FileEntry::creation_date
        inx
:       lda     (entry_ptr),y
        sta     record,x
        inx
        iny
        cpy     #FileEntry::creation_date+4
        bne     :-

        ;; modification date/time
        ldy     #FileEntry::mod_date
:       lda     (entry_ptr),y
        sta     record,x
        inx
        iny
        cpy     #FileEntry::mod_date+4
        bne     :-

        ;; access
        ldy     #FileEntry::access
        lda     (entry_ptr),y
        sta     record,x
        inx

        ;; header pointer
        ldy     #FileEntry::header_pointer
        lda     (entry_ptr),y
        sta     record,x
        inx
        iny
        lda     (entry_ptr),y
        sta     record,x
        inx

        ;; aux type
        ldy     #FileEntry::aux_type
        lda     (entry_ptr),y
        sta     record,x
        inx
        iny
        lda     (entry_ptr),y
        sta     record,x

        ;; Copy entry composed at $1F00 to buffer in Aux LC Bank 2
        lda     LCBANK2
        lda     LCBANK2
        ldx     #.sizeof(FileRecord)-1
        ldy     #.sizeof(FileRecord)-1
:       lda     record,x
        sta     (record_ptr),y
        dex
        dey
        bpl     :-
        lda     LCBANK1
        lda     LCBANK1
        lda     #.sizeof(FileRecord)
        clc
        adc     record_ptr
        sta     record_ptr
        bcc     L7293
        inc     record_ptr+1
L7293:  jmp     do_entry

L7296:  copy16  record_ptr, filerecords_free_start
        jsr     do_close
        jsr     pop_pointers
        rts

window_id:
        .byte   0

L72A8:  .word   0
.endproc

;;; --------------------------------------------------

.proc do_open
        MLI_RELAY_CALL OPEN, open_params
        beq     done

        bit     suppress_error_on_open_flag
        bmi     :+
        jsr     ShowAlert

:       bit     icon_params2    ; Were we opening a path?
        bmi     :+              ; Yes, no icons to twiddle.

        jsr     mark_icons_not_opened_2
        lda     selected_window_index
        bne     :+
        sta     drive_to_refresh
        jsr     cmd_check_single_drive_by_icon_number

:       ldx     saved_stack
        txs

done:   rts
.endproc

suppress_error_on_open_flag:
        .byte   0

;;; --------------------------------------------------

do_read:
        MLI_RELAY_CALL READ, read_params
        rts

do_close:
        MLI_RELAY_CALL CLOSE, close_params
        rts

;;; --------------------------------------------------

L72E2:  lda     $0C04
        and     #$F0
        cmp     #$F0
        beq     get_vol_free_used
        rts


get_vol_free_used:
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params4
        beq     :+
        rts

        ;; aux = total blocks
:       copy16  get_file_info_params4::aux_type, vol_kb_used
        ;; total - used = free
        sub16   get_file_info_params4::aux_type, get_file_info_params4::blocks_used, vol_kb_free
        sub16   vol_kb_used, vol_kb_free, vol_kb_used ; total - free = used
        lsr16   vol_kb_free
        php
        lsr16   vol_kb_used
        plp
        bcc     :+
        inc16   vol_kb_used
:       return  #0
.endproc
        vol_kb_free := open_directory::vol_kb_free
        vol_kb_used := open_directory::vol_kb_used
        get_vol_free_used := open_directory::get_vol_free_used

;;; ============================================================
;;; Remove the FileRecord entries for a window, and free/compact
;;; the space.
;;; A = window id

.proc remove_window_filerecord_entries
        sta     window_id

        ;; Find address of FileRecord list
        ldx     #0
:       lda     window_id_to_filerecord_list_entries,x
        cmp     window_id
        beq     :+
        inx
        cpx     #kMaxNumWindows
        bne     :-
        rts

        ;; Move list entries down by one
:       stx     index
        dex
:       inx
        lda     window_id_to_filerecord_list_entries+1,x
        sta     window_id_to_filerecord_list_entries,x
        cpx     window_id_to_filerecord_list_count
        bne     :-

        ;; List is now shorter by one...
        dec     window_id_to_filerecord_list_count

        ;; Was that the last one?
        lda     index
        cmp     window_id_to_filerecord_list_count
        bne     :+
        ldx     index           ; yes...
        asl     a               ; so update the start of free space
        tax
        copy16  window_filerecord_table,x, filerecords_free_start
        rts                     ; and done!

        ;; --------------------------------------------------
        ;; Compact FileRecords

        ptr_src := $08
        ptr_dst := $06

        ;; Need to compact FileRecords space - shift memory down.
        ;;  +----------+------+----------+---------+
        ;;  |##########|xxxxxx|mmmmmmmmmm|         |
        ;;  +----------+------+----------+---------+
        ;;             1      2          3
        ;; 1 = ptr_dst (start of newly freed space)
        ;; 2 = ptr_src (next list)
        ;; 3 = filerecords_free_start (top of used space)
        ;; x = freed, m = moved, # = unchanged

:       lda     index
        asl     a
        tax
        copy16  window_filerecord_table,x, ptr_dst
        inx
        inx
        copy16  window_filerecord_table,x, ptr_src

        ldy     #0
        jsr     push_pointers

loop:   lda     LCBANK2
        lda     LCBANK2
        lda     (ptr_src),y
        sta     (ptr_dst),y
        lda     LCBANK1
        lda     LCBANK1
        inc16   ptr_dst
        inc16   ptr_src

        ;; All the way to top of used space
        lda     ptr_src+1
        cmp     filerecords_free_start+1
        bne     loop
        lda     ptr_src
        cmp     filerecords_free_start
        bne     loop

        jsr     pop_pointers

        ;; Offset affected list pointers down
        lda     window_id_to_filerecord_list_count
        asl     a
        tax
        sub16   filerecords_free_start, window_filerecord_table,x, deltam
        inc     index

loop2:  lda     index
        cmp     window_id_to_filerecord_list_count
        bne     :+
        jmp     finish

:       lda     index
        asl     a
        tax
        sub16   window_filerecord_table+2,x, window_filerecord_table,x, size
        add16   window_filerecord_table-2,x, size, window_filerecord_table,x
        inc     index
        jmp     loop2

finish:
        ;; Update "start of free memory" pointer
        lda     window_id_to_filerecord_list_count
        sec
        sbc     #1
        asl     a
        tax
        add16   window_filerecord_table,x, deltam, filerecords_free_start
        rts

window_id:
        .byte   0
index:  .byte   0
deltam: .word   0               ; memory delta
size:   .word   0               ; size of a window's list
.endproc

;;; ============================================================
;;; Compute full path for icon
;;; Inputs: IconEntry pointer in $06
;;; Outputs: open_dir_path_buf has full path
;;; Exceptions: if path too long, shows error and restores saved_stack

.proc compose_icon_full_path
        icon_ptr := $06
        name_ptr := $06

        jsr     push_pointers

        ldy     #IconEntry::win_type
        lda     (icon_ptr),y
        pha
        add16   icon_ptr, #IconEntry::name, name_ptr
        pla
        and     #kIconEntryWinIdMask
        bne     has_parent      ; A = window_id

        ;; --------------------------------------------------
        ;; Desktop (volume) icon - no parent path

        ;; Copy name
        ldy     #0
        lda     (name_ptr),y
        tay                     ; Y = length
:       lda     (name_ptr),y
        sta     open_dir_path_buf+1,y ; Leave room for leading '/'
        dey
        bne     :-

        ;; Add leading '/' and adjust length
        copy    #'/', open_dir_path_buf+1
        lda     (name_ptr),y
        sta     open_dir_path_buf
        inc     open_dir_path_buf

        jsr     pop_pointers
        rts

        ;; --------------------------------------------------
        ;; Windowed (folder) icon - has parent path
has_parent:

        parent_path_ptr := $08

        jsr     window_path_lookup
        stax    parent_path_ptr

        ldy     #0
        lda     (parent_path_ptr),y
        clc
        adc     (name_ptr),y
        cmp     #kPathBufferSize
        bcc     :+

        lda     #ERR_INVALID_PATHNAME
        jsr     ShowAlert
        jsr     mark_icons_not_opened_2
        dec     num_open_windows
        ldx     saved_stack
        txs
        rts

        ;; Copy parent path to open_dir_path_buf
:       ldy     #0
        lda     (parent_path_ptr),y
        tay
:       lda     (parent_path_ptr),y
        sta     open_dir_path_buf,y
        dey
        bpl     :-

        ;; Suffix with '/'
        lda     #'/'
        inc     open_dir_path_buf
        ldx     open_dir_path_buf
        sta     open_dir_path_buf,x

        ;; Append icon name
        ldy     #0
        lda     (name_ptr),y
        clc
        adc     open_dir_path_buf
        sta     open_dir_path_buf

:       iny
        inx
        lda     (name_ptr),y
        sta     open_dir_path_buf,x
        cpx     open_dir_path_buf
        bne     :-

        jsr     pop_pointers
        rts
.endproc

;;; ============================================================
;;; Set up path and coords for new window, contents and free/used.
;;; Inputs: IconEntry pointer in $06, new window_id in cached_window_id,
;;;         open_dir_path_buf has full path
;;; Outputs: Winfo configured, window path table entry set

.proc prepare_new_window
        icon_ptr := $06

        ;; Copy icon name to window title
.scope
        name_ptr := icon_ptr
        title_ptr := $08

        jsr     push_pointers

        lda     cached_window_id
        asl     a
        tax
        copy16  window_title_addr_table,x, title_ptr
        add16   icon_ptr, #IconEntry::name, name_ptr

        ldy     #0
        lda     (name_ptr),y
        tay
:       lda     (name_ptr),y
        sta     (title_ptr),y
        dey
        bpl     :-

        jsr     pop_pointers
.endscope

        ;; --------------------------------------------------
        path_ptr := $08

        ;; Copy previously composed path into window path
        lda     cached_window_id
        jsr     window_path_lookup
        stax    path_ptr
        ldy     open_dir_path_buf
:       lda     open_dir_path_buf,y
        sta     (path_ptr),y
        dey
        bpl     :-

        ;; --------------------------------------------------

        winfo_ptr := $06

        ;; Set window coordinates
        lda     cached_window_id
        jsr     window_lookup
        stax    winfo_ptr
        ldy     #MGTK::Winfo::port

        ;; xcoord = (window_id-1) * 16 + 5
        ;; ycoord = (window_id-1) * 8 + 27

        lda     cached_window_id
        sec
        sbc     #1              ; * 16
        asl     a
        asl     a
        asl     a
        asl     a

        pha
        adc     #5
        sta     (winfo_ptr),y   ; viewloc::xcoord
        iny
        lda     #0
        sta     (winfo_ptr),y
        iny
        pla

        lsr     a               ; / 2
        clc
        adc     #27
        sta     (winfo_ptr),y   ; viewloc::ycoord
        iny
        lda     #0
        sta     (winfo_ptr),y

        ;; Map rect
        lda     #0
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + 3
        ldx     #3
:       sta     (winfo_ptr),y
        dey
        dex
        bpl     :-

        ;; Scrollbars
        ldy     #MGTK::Winfo::hscroll
        lda     (winfo_ptr),y
        and     #AS_BYTE(~MGTK::Scroll::option_active)
        sta     (winfo_ptr),y
        iny                     ; vscroll
        lda     (winfo_ptr),y
        and     #AS_BYTE(~MGTK::Scroll::option_active)
        sta     (winfo_ptr),y

        lda     #0
        ldy     #MGTK::Winfo::hthumbpos
        sta     (winfo_ptr),y
        ldy     #MGTK::Winfo::vthumbpos
        sta     (winfo_ptr),y

        ;; --------------------------------------------------

        lda     cached_window_id
        jsr     open_directory

        lda     icon_params2    ; set to $FF if opening via path
        bmi     volume

        jsr     icon_entry_lookup
        stax    icon_ptr
        ldy     #IconEntry::win_type
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        beq     volume

        ;; Windowed (folder) icon
        tax
        dex
        txa
        asl     a
        tax
        copy16  window_k_used_table,x, vol_kb_used
        copy16  window_k_free_table,x, vol_kb_free

        ;; Desktop (volume) icon
volume: ldx     cached_window_id
        dex
        txa
        asl     a
        tax
        copy16  vol_kb_used, window_k_used_table,x
        copy16  vol_kb_free, window_k_free_table,x
        lda     cached_window_id
        jsr     create_file_icon_ep1
        rts

.endproc

;;; ============================================================
;;; File Icon Entry Construction

.proc create_file_icon

        kIconSpacingX  = 80
        kIconSpacingY  = 32

window_id:      .byte   0
iconbits:       .addr   0
iconentry_type: .byte   0
icon_height:    .word   0
L7625:  .byte   0               ; ???

        kMaxIconHeight = 17

initial_coords:                 ; first icon in window
        DEFINE_POINT  52,16 + kMaxIconHeight, initial_coords

row_coords:                     ; first icon in current row
        DEFINE_POINT 0, 0, row_coords

icons_per_row:
        .byte   5

icons_this_row:
        .byte   0

icon_coords:
        DEFINE_POINT 0, 0, icon_coords

flag:   .byte   0               ; ???

.proc ep1                       ; entry point #1 ???
        pha
        lda     #0
        beq     L7647

ep2:    pha                     ; entry point #2 ???
        ldx     cached_window_id
        dex
        lda     window_to_dir_icon_table,x
        ;; TODO: Guaranteed to exist?
        sta     icon_params2
        lda     #$80

L7647:  sta     flag
        pla
        sta     window_id
        jsr     push_pointers

        COPY_STRUCT MGTK::Point, initial_coords, row_coords

        lda     #0
        sta     icons_this_row
        sta     L7625

        ldx     #3
:       sta     icon_coords,x
        dex
        bpl     :-

        lda     cached_window_id
        ldx     window_id_to_filerecord_list_count
        dex
:       cmp     window_id_to_filerecord_list_entries,x
        beq     :+
        dex
        bpl     :-
        rts

:       txa
        asl     a
        tax
        copy16  window_filerecord_table,x, $06
        lda     LCBANK2
        lda     LCBANK2
        ldy     #0
        lda     ($06),y
        sta     L7764
        lda     LCBANK1
        lda     LCBANK1
        inc16   $06
        lda     cached_window_id
        sta     active_window_id
L76AA:  lda     L7625
        cmp     L7764
        beq     L76BB
        jsr     alloc_and_populate_file_icon
        inc     L7625
        jmp     L76AA

L76BB:  bit     flag
        bpl     :+
        jsr     pop_pointers
        rts

:       jsr     compute_icons_bbox
        lda     window_id
        jsr     window_lookup

        winfo_ptr := $06

        stax    winfo_ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + 2 ; ycoord
        lda     iconbb_rect+MGTK::Rect::y2
        sec
        sbc     (winfo_ptr),y
        sta     iconbb_rect+MGTK::Rect::y2
        lda     iconbb_rect+MGTK::Rect::y2+1
        sbc     #0
        sta     iconbb_rect+MGTK::Rect::y2+1
        cmp16   iconbb_rect+MGTK::Rect::x2, #170
        bmi     L7705
        cmp16   iconbb_rect+MGTK::Rect::x2, #450
        bpl     L770C
        ldax    iconbb_rect+MGTK::Rect::x2
        jmp     L7710

L7705:  ldax    #170
        jmp     L7710

L770C:  ldax    #450
L7710:  ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Rect::x2
        sta     (winfo_ptr),y
        txa
        iny
        sta     (winfo_ptr),y

        cmp16   iconbb_rect+MGTK::Rect::y2, #50
        bmi     L7739
        cmp16   iconbb_rect+MGTK::Rect::y2, #108
        bpl     L7740
        ldax    iconbb_rect+MGTK::Rect::y2
        jmp     L7744

L7739:  ldax    #50
        jmp     L7744

L7740:  ldax    #108
L7744:  ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Rect::y2
        sta     (winfo_ptr),y
        txa
        iny
        sta     (winfo_ptr),y
        lda     thumbmax
        ldy     #MGTK::Winfo::hthumbmax
        sta     (winfo_ptr),y
        ldy     #MGTK::Winfo::vthumbmax
        sta     (winfo_ptr),y
        lda     icon_params2
        ldx     window_id
        jsr     animate_window_open
        jsr     pop_pointers
        rts

L7764:  .byte   $00,$00,$00

thumbmax:
        .byte   20

.endproc

;;; ============================================================
;;; Create icon

.proc alloc_and_populate_file_icon
        file_entry := $6
        icon_entry := $8
        name_tmp := $1800

        inc     icon_count
        jsr     AllocateIcon
        ldx     cached_window_icon_count
        inc     cached_window_icon_count
        sta     cached_window_icon_list,x
        jsr     icon_entry_lookup
        stax    icon_entry
        lda     LCBANK2
        lda     LCBANK2

        ;; Copy the name
        ldy     #FileRecord::name
        lda     (file_entry),y
        sta     name_tmp
        iny
        ldx     #0
:       lda     (file_entry),y
        sta     name_tmp+1,x
        inx
        iny
        cpx     name_tmp
        bne     :-

        ;; Check file type
        ldy     #FileRecord::file_type
        lda     (file_entry),y

        ;; Handle several classes of overrides
        sta     icontype_filetype
        ldy     #FileRecord::aux_type
        copy16in (file_entry),y, icontype_auxtype
        ldy     #FileRecord::blocks
        copy16in (file_entry),y, icontype_blocks
        jsr     get_icon_type

        ;; Distinguish *.SYSTEM files as apps (use $01) from other
        ;; type=SYS files (use $FF).
        cmp     #IconType::system
        bne     got_type

        ldy     #FileRecord::name
        lda     (file_entry),y
        tay
        ldx     str_sys_suffix
cloop:  lda     (file_entry),y
        jsr     upcase_char
        cmp     str_sys_suffix,x
        bne     not_app
        dey
        beq     not_app
        dex
        bne     cloop

is_app:
        lda     #IconType::application
        bne     got_type        ; always

str_sys_suffix:
        PASCAL_STRING ".SYSTEM"

not_app:
        lda     #IconType::system
        ;; fall through

got_type:
        tay

        ;; Figure out icon type
        lda     LCBANK1
        lda     LCBANK1
        tya

        jsr     find_icon_details_for_icon_type
        ldy     #IconEntry::name
        ldx     #0
L77F0:  lda     name_tmp,x
        sta     (icon_entry),y
        iny
        inx
        cpx     name_tmp
        bne     L77F0
        lda     name_tmp,x
        sta     (icon_entry),y

        ;; Assign location
        ldx     #0
        ldy     #IconEntry::iconx
:       lda     row_coords,x
        sta     (icon_entry),y
        inx
        iny
        cpx     #.sizeof(MGTK::Point)
        bne     :-

        ;; Include y-offset
        ldy     #IconEntry::icony
        sub16in (icon_entry),y, icon_height, (icon_entry),y

        lda     cached_window_icon_count
        cmp     icons_per_row
        beq     L781A
        bcs     L7826
L781A:  copy16  row_coords::xcoord, icon_coords::xcoord
L7826:  copy16  row_coords::ycoord, icon_coords::ycoord
        inc     icons_this_row
        lda     icons_this_row
        cmp     icons_per_row
        bne     L7862

        ;; Next row (and initial column) if necessary
        add16   row_coords::ycoord, #32, row_coords::ycoord
        copy16  initial_coords::xcoord, row_coords::xcoord
        lda     #0
        sta     icons_this_row
        jmp     L7870

        ;; Next column otherwise
L7862:  lda     row_coords::xcoord
        clc
        adc     #kIconSpacingX
        sta     row_coords::xcoord
        bcc     L7870
        inc     row_coords::xcoord+1

L7870:  lda     cached_window_id
        ora     iconentry_type
        ldy     #IconEntry::win_type
        sta     (icon_entry),y
        ldy     #IconEntry::iconbits
        copy16in iconbits, (icon_entry),y
        ldx     cached_window_icon_count
        dex
        lda     cached_window_icon_list,x
        jsr     icon_window_to_screen
        add16   file_entry, #kIconSpacingY, file_entry
        rts
.endproc

;;; ============================================================

.proc find_icon_details_for_icon_type
        ptr := $6

        sta     icon_type
        jsr     push_pointers

        ;; For populating IconEntry::win_type
        ldy     icon_type
        lda     icontype_iconentrytype_table, y
        sta     iconentry_type

        ;; For populating IconEntry::iconbits
        tya
        asl     a
        tay
        copy16  type_icons_table,y, iconbits

        ;; Icon height will be needed too
        copy16  iconbits, ptr
        ldy     #IconDefinition::maprect + MGTK::Rect::y2
        copy16in (ptr),y, icon_height

        jsr     pop_pointers
        rts

icon_type:
        .byte   0
.endproc

.endproc
        create_file_icon_ep2 := create_file_icon::ep1::ep2
        create_file_icon_ep1 := create_file_icon::ep1


;;; ============================================================
;;; Map file type (etc) to icon type

;;; Input: icontype_type, icontype_auxtype, icontype_blocks populated
;;; Output: A is IconType to use (for icons, open/preview, etc)

.proc get_icon_type
        ptr := $06

        jsr     push_pointers
        copy16  #icontype_table, ptr

loop:   ldy     #0              ; type_mask, or $00 if done
        lda     (ptr),y
        bne     :+
        jsr     pop_pointers
        lda     #IconType::generic
        rts

        ;; Check type (with mask)
:       and     icontype_filetype    ; A = type & type_mask
        iny                     ; ASSERT: Y = ICTRecord::type
        cmp     (ptr),y         ; type check
        bne     next

        ;; Flags
        iny                     ; ASSERT: Y = ICTRecord::flags
        lda     (ptr),y
        sta     flags

        ;; Does Aux Type matter, and if so does it match?
        bit     flags
        bpl     blocks          ; bit 7 = compare aux
        iny                     ; ASSERT: Y = FTORecord::aux
        lda     icontype_auxtype
        cmp     (ptr),y
        bne     next
        iny
        lda     icontype_auxtype+1
        cmp     (ptr),y
        bne     next

        ;; Does Block Count matter, and if so does it match?
blocks: bit     flags
        bvc     match           ; bit 6 = compare blocks
        ldy     #ICTRecord::blocks
        lda     icontype_blocks
        cmp     (ptr),y
        bne     next
        iny
        lda     icontype_blocks+1
        cmp     (ptr),y
        bne     next

        ;; Have a match
match:  ldy     #ICTRecord::icontype
        lda     (ptr),y
        sta     tmp
        jsr     pop_pointers
        lda     tmp
        rts

        ;; Next entry
next:   add16   ptr, #.sizeof(ICTRecord), ptr
        jmp     loop

flags:  .byte   0
tmp:    .byte   0
.endproc


;;; ============================================================
;;; Draw header (items/k in disk/k available/lines)

.proc draw_window_header

        ;; Compute header coords

        ;; x coords
        lda     window_grafport::cliprect::x1
        sta     header_line_left::xcoord
        clc
        adc     #5
        sta     items_label_pos::xcoord
        lda     window_grafport::cliprect::x1+1
        sta     header_line_left::xcoord+1
        adc     #0
        sta     items_label_pos::xcoord+1

        ;; y coords
        lda     window_grafport::cliprect::y1
        clc
        adc     #12
        sta     header_line_left::ycoord
        sta     header_line_right::ycoord
        lda     window_grafport::cliprect::y1+1
        adc     #0
        sta     header_line_left::ycoord+1
        sta     header_line_right::ycoord+1

        ;; Draw top line
        MGTK_RELAY_CALL MGTK::MoveTo, header_line_left
        copy16  window_grafport::cliprect::x2, header_line_right::xcoord
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::LineTo, header_line_right

        ;; Offset down by 2px
        lda     header_line_left::ycoord
        clc
        adc     #2
        sta     header_line_left::ycoord
        sta     header_line_right::ycoord
        lda     header_line_left::ycoord+1
        adc     #0
        sta     header_line_left::ycoord+1
        sta     header_line_right::ycoord+1

        ;; Draw bottom line
        MGTK_RELAY_CALL MGTK::MoveTo, header_line_left
        MGTK_RELAY_CALL MGTK::LineTo, header_line_right

        ;; Baseline for header text
        add16 window_grafport::cliprect::y1, #10, items_label_pos::ycoord

        ;; Draw "XXX Items"
        lda     cached_window_icon_count
        ldx     #0
        jsr     int_to_string
        lda     cached_window_icon_count
        cmp     #2              ; plural?
        bcs     :+
        dec     str_items       ; remove trailing s
:       MGTK_RELAY_CALL MGTK::MoveTo, items_label_pos
        jsr     draw_int_string
        addr_call draw_pascal_string, str_items
        lda     cached_window_icon_count
        cmp     #2
        bcs     :+
        inc     str_items       ; restore trailing s

        ;; Draw "XXXK in disk"
:       jsr     calc_header_coords
        ldx     active_window_id
        dex                     ; index 0 is window 1
        txa
        asl     a
        tax
        lda     window_k_used_table,x
        tay
        lda     window_k_used_table+1,x
        tax
        tya
        jsr     int_to_string
        MGTK_RELAY_CALL MGTK::MoveTo, pos_k_in_disk
        jsr     draw_int_string
        addr_call draw_pascal_string, str_k_in_disk

        ;; Draw "XXXK available"
        ldx     active_window_id
        dex                     ; index 0 is window 1
        txa
        asl     a
        tax
        lda     window_k_free_table,x
        tay
        lda     window_k_free_table+1,x
        tax
        tya
        jsr     int_to_string
        MGTK_RELAY_CALL MGTK::MoveTo, pos_k_available
        jsr     draw_int_string
        addr_call draw_pascal_string, str_k_available
        rts

;;; --------------------------------------------------

.proc calc_header_coords
        ;; Width of window
        sub16   window_grafport::cliprect::x2, window_grafport::cliprect::x1, xcoord

        ;; Is there room to spread things out?
        sub16   xcoord, width_items_label, xcoord
        bpl     :+
        jmp     skipcenter
:       sub16   xcoord, width_right_labels, xcoord
        bpl     :+
        jmp     skipcenter

        ;; Yes - center "k in disk"
:       add16   width_left_labels, xcoord, pos_k_available::xcoord
        lda     xcoord+1
        beq     :+
        lda     xcoord
        cmp     #24             ; threshold
        bcc     nosub
:       sub16   pos_k_available::xcoord, #12, pos_k_available::xcoord
nosub:  lsr16   xcoord          ; divide by 2 to center
        add16   width_items_label_padded, xcoord, pos_k_in_disk::xcoord
        jmp     finish

        ;; No - just squish things together
skipcenter:
        copy16  width_items_label_padded, pos_k_in_disk::xcoord
        copy16  width_left_labels, pos_k_available::xcoord

finish:
        add16   pos_k_in_disk::xcoord, window_grafport::cliprect::x1, pos_k_in_disk::xcoord
        add16   pos_k_available::xcoord, window_grafport::cliprect::x1, pos_k_available::xcoord

        ;; Update y coords
        lda     items_label_pos::ycoord
        sta     pos_k_in_disk::ycoord
        sta     pos_k_available::ycoord
        lda     items_label_pos::ycoord+1
        sta     pos_k_in_disk::ycoord+1
        sta     pos_k_available::ycoord+1

        rts
.endproc ; calc_header_coords

draw_int_string:
        addr_jump draw_pascal_string, str_from_int

xcoord:
        .word   0
.endproc ; draw_window_header

;;; ============================================================
;;; Input: 16-bit unsigned number in A,X
;;; Output: length-prefixed string in str_from_int

.proc int_to_string
        stax    value

        lda     #0
        sta     nonzero_flag
        ldy     #0              ; y = position in string
        ldx     #0              ; x = which power index is subtracted (*2)

        ;; For each power of ten
loop:   lda     #0
        sta     digit

        ;; Keep subtracting/incrementing until zero is hit
sloop:  cmp16   value, powers,x
        bcc     break
        inc     digit
        sub16   value, powers,x, value
        jmp     sloop

break:  lda     digit
        bne     not_pad
        bit     nonzero_flag
        bpl     next

        ;; Convert to ASCII
not_pad:
        ora     #'0'
        pha
        copy    #$80, nonzero_flag
        pla

        ;; Place the character, move to next
        iny
        sta     str_from_int,y

next:   inx
        inx
        cpx     #8              ; up to 4 digits (*2) via subtraction
        beq     done
        jmp     loop

done:   lda     value           ; handle last digit
        ora     #'0'
        iny
        sta     str_from_int,y
        sty     str_from_int
        rts

powers: .word   10000, 1000, 100, 10
value:  .word   0            ; remaining value as subtraction proceeds
digit:  .byte   0            ; current digit being accumulated
nonzero_flag:                ; high bit set once a non-zero digit seen
        .byte   0

.endproc ; int_to_string

;;; ============================================================
;;; Compute bounding box for icons within cached window

iconbb_rect:
        DEFINE_RECT 0,0,0,0,iconbb_rect

.proc compute_icons_bbox_impl

        entry_ptr := $06

        kIntMax = $7FFF

start:
        ;; max.x = max.y = 0
        ldx     #.sizeof(MGTK::Point)-1
        lda     #0
:       sta     iconbb_rect::x2,x
        dex
        bpl     :-

        ;; icon_num = 0
        sta     icon_num

        ;; min.x = min.y = kIntMax
        lda     #<kIntMax
        sta     iconbb_rect::x1
        sta     iconbb_rect+MGTK::Rect::y1
        lda     #>kIntMax
        sta     iconbb_rect::x1+1
        sta     iconbb_rect+MGTK::Rect::y1+1

        ;; Icon view?
        ldx     cached_window_id
        dex
        lda     win_view_by_table,x
        bpl     icon_view           ; icon view

        ;; --------------------------------------------------
        ;; List view

        ;; If no items, simply zero out min and done. Otherwise,
        ;; do an actual calculation.

        lda     cached_window_icon_count
        bne     list_view_non_empty
        ;; Just fall through if no items (min = max = 0)

        ;; min.x = min.y = 0
zero_min:
        lda     #0
        ldx     #.sizeof(MGTK::Point)-1
:       sta     iconbb_rect::x1,x
        dex
        bpl     :-
        rts

        ;; min.x = 360
        ;; min.y = (A + 2) * 8
list_view_non_empty:
        clc
        adc     #2
        ldx     #0
        stx     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        sta     iconbb_rect::y2
        lda     hi
        sta     iconbb_rect::y2+1
        copy16  #360, iconbb_rect::x2

        ;; Now zero out min (and done
        jmp     zero_min

        ;; --------------------------------------------------
        ;; Icon view
icon_view:

check_icon:
        lda     icon_num
        cmp     cached_window_icon_count
        bne     more

        ;; Add padding around bbox
finish: lda     iconbb_rect::x2
        clc
        adc     #kIconBBoxOffsetRight
        sta     iconbb_rect::x2
        bcc     :+
        inc     iconbb_rect::x2+1
:       lda     iconbb_rect::y2
        clc
        adc     #kIconBBoxOffsetBottom
        sta     iconbb_rect::y2
        bcc     :+
        inc     iconbb_rect::y2+1
:       sub16   iconbb_rect::x1, #kIconBBoxOffsetLeft, iconbb_rect::x1
        sub16   iconbb_rect::y1, #kIconBBoxOffsetTop, iconbb_rect::y1
        rts

more:   tax
        lda     cached_window_icon_list,x
        jsr     cache_icon_pos

        ;; First icon (index 0) - just use its coordinates as min/max
        lda     icon_num
        bne     compare_x

        ldx     #.sizeof(MGTK::Point)-1
:       lda     cur_icon_pos,x
        sta     iconbb_rect::x1,x
        sta     iconbb_rect::x2,x
        dex
        bpl     :-
        jmp     next

        ;; --------------------------------------------------
        ;; Compare X coords

compare_x:
        bit     iconbb_rect::x1+1         ; negative?
        bmi     minx_neg

        bit     cur_icon_pos::xcoord+1
        bmi     adjust_min_x

        ;; X: cur and min are positive
        cmp16   cur_icon_pos::xcoord, iconbb_rect::x1
        bmi     adjust_min_x
        cmp16   cur_icon_pos::xcoord, iconbb_rect::x2
        bpl     adjust_max_x
        jmp     compare_y

minx_neg:
        bit     cur_icon_pos::xcoord+1
        bmi     bothx_neg

        ;; X: cur positive, min negative
        bit     iconbb_rect::x2+1
        bmi     compare_y
        cmp16   cur_icon_pos::xcoord, iconbb_rect::x2
        bmi     compare_y
        jmp     adjust_max_x

        ;; X: cur and min are negative
bothx_neg:
        cmp16   cur_icon_pos::xcoord, iconbb_rect::x1
        bmi     adjust_min_x
        cmp16   cur_icon_pos::xcoord, iconbb_rect::x2
        bmi     compare_y

adjust_max_x:
        copy16  cur_icon_pos::xcoord, iconbb_rect::x2
        jmp     compare_y

adjust_min_x:
        copy16  cur_icon_pos::xcoord, iconbb_rect::x1

        ;; --------------------------------------------------
        ;; Compare Y coords

compare_y:
        bit     iconbb_rect::y1+1
        bmi     miny_neg
        bit     cur_icon_pos::ycoord+1
        bmi     adjust_min_y

        ;; Y: cur and min are positive
        cmp16   cur_icon_pos::ycoord, iconbb_rect::y1
        bmi     adjust_min_y
        cmp16   cur_icon_pos::ycoord, iconbb_rect::y2
        bpl     adjust_max_y
        jmp     next

miny_neg:
        bit     cur_icon_pos::ycoord+1
        bmi     bothy_neg

        ;; Y: cur positive, min negative
        bit     iconbb_rect::y2+1
        bmi     next
        cmp16   cur_icon_pos::ycoord, iconbb_rect::y2
        bmi     next
        jmp     adjust_max_y

        ;; Y: cur and min are negative
bothy_neg:
        cmp16   cur_icon_pos::ycoord, iconbb_rect::y1
        bmi     adjust_min_y
        cmp16   cur_icon_pos::ycoord, iconbb_rect::y2
        bmi     next

adjust_max_y:
        copy16  cur_icon_pos::ycoord, iconbb_rect::y2
        jmp     next

adjust_min_y:
        copy16  cur_icon_pos::ycoord, iconbb_rect::y1

next:   inc     icon_num
        jmp     check_icon

icon_num:
        .byte   0

hi:     .byte   0
.endproc
        compute_icons_bbox := compute_icons_bbox_impl::start

;;; ============================================================
;;; Compute dimensions of window
;;; Input: A = window
;;; Output: A,X = width, Y = height

.proc compute_window_dimensions
        ptr := $06

        jsr     window_lookup
        stax    ptr

        ;; Copy window's maprect
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     (ptr),y
        sta     rect,x
        dey
        dex
        bpl     :-

        ;; Push delta-X
        lda     rect+MGTK::Rect::x2
        sec
        sbc     rect+MGTK::Rect::x1
        pha
        lda     rect+MGTK::Rect::x2+1
        sbc     rect+MGTK::Rect::x1+1
        pha

        ;; Push delta-Y
        lda     rect+MGTK::Rect::y2
        sec
        sbc     rect+MGTK::Rect::y1
        pha
        lda     rect+MGTK::Rect::y2+1
        sbc     rect+MGTK::Rect::y1+1
        ;; high byte is discarded

        pla
        tay
        pla
        tax
        pla

        rts

rect:   DEFINE_RECT 0,0,0,0

.endproc

;;; ============================================================

.proc sort_records
        ptr := $06

record_num      := $800
list_start_ptr  := $801
num_records     := $803
        ;; $804 = scratch byte
index           := $805

        jmp     start

start:  lda     cached_window_id
        ldx     #0
:       cmp     window_id_to_filerecord_list_entries,x
        beq     found
        inx
        cpx     window_id_to_filerecord_list_count
        bne     :-
        rts

found:  txa
        asl     a
        tax

        lda     window_filerecord_table,x         ; Ptr points at start of record
        sta     ptr
        sta     list_start_ptr
        lda     window_filerecord_table+1,x
        sta     ptr+1
        sta     list_start_ptr+1

        lda     LCBANK2         ; Start copying records
        lda     LCBANK2

        lda     #0              ; Number copied
        sta     record_num
        tay
        lda     (ptr),y         ; Number to copy
        sta     num_records

        inc     ptr             ; Point past number
        inc     list_start_ptr
        bne     loop
        inc     ptr+1
        inc     list_start_ptr+1

loop:   lda     record_num
        cmp     num_records
        beq     break
        jsr     ptr_calc

        ldy     #0
        lda     (ptr),y
        and     #$7F            ; mask off high bit
        sta     (ptr),y         ; mark as ???

        ldy     #FileRecord::modification_date ; ???
        lda     (ptr),y
        bne     next
        iny
        lda     (ptr),y         ; modification_date hi
        bne     next
        lda     #$01            ; if no mod date, set hi to 1 ???
        sta     (ptr),y

next:   inc     record_num
        jmp     loop

break:  lda     LCBANK1         ; Done copying records
        lda     LCBANK1

        ;; --------------------------------------------------

        ;; What sort order?
        ldx     cached_window_id
        dex
        lda     win_view_by_table,x
        cmp     #kViewByName
        beq     :+
        jmp     check_date

:
        ;; By Name

        ;; Sorted in increasing lexicographical order
.scope
        name := $807
        kNameSize = $F
        name_len  := $804

        lda     LCBANK2
        lda     LCBANK2

        ;; Set up highest value ("ZZZZZZZZZZZZZZZ")
        lda     #'Z'
        ldx     #kNameSize
:       sta     name+1,x
        dex
        bpl     :-

        lda     #0
        sta     index
        sta     record_num

loop:   lda     index
        cmp     num_records
        bne     iloop
        jmp     finish_view_change

iloop:  jsr     ptr_calc

        ;; Check record for mark
        ldy     #0
        lda     (ptr),y
        bmi     inext

        ;; Compare names
        and     #NAME_LENGTH_MASK
        sta     name_len
        ldy     #1
cloop:  lda     (ptr),y
        jsr     upcase_char
        cmp     name,y
        beq     :+
        bcs     inext
        jmp     place
:       iny
        cpy     #$10
        bne     cloop
        jmp     inext

        ;; if less than
place:  lda     record_num
        sta     $0806

        ldx     #kNameSize
        lda     #' '
:       sta     name+1,x
        dex
        bpl     :-

        ldy     name_len
:       lda     (ptr),y
        jsr     upcase_char
        sta     name,y
        dey
        bne     :-

inext:  inc     record_num
        lda     record_num
        cmp     num_records
        beq     :+
        jmp     iloop

:       inc     index
        lda     $0806
        sta     record_num
        jsr     ptr_calc

        ;; Mark record
        ldy     #0
        lda     (ptr),y
        ora     #$80
        sta     (ptr),y

        lda     #'Z'
        ldx     #15
:       sta     $0808,x
        dex
        bpl     :-

        ldx     index
        dex
        ldy     $0806
        iny
        jsr     L812B

        lda     #0
        sta     record_num
        jmp     loop
.endscope

        ;; --------------------------------------------------

check_date:
        cmp     #kViewByDate
        beq     :+
        jmp     check_size

:
        ;; By Date

        ;; Sorted by decreasing date
.scope
        date    := $0808

        lda     LCBANK2
        lda     LCBANK2

        lda     #0
        ldx     #.sizeof(DateTime)-1
:       sta     date,x
        dex
        bpl     :-
        sta     index
        sta     record_num

loop:   lda     index
        cmp     num_records
        bne     iloop
        jmp     finish_view_change

iloop:  jsr     ptr_calc

        ;; Check record for mark
        ldy     #0
        lda     (ptr),y
        bmi     inext

        ;; Compare dates
        ldy     #FileRecord::modification_date + .sizeof(DateTime)-1
        ldx     #.sizeof(DateTime)-1
:       copy    (ptr),y, date_a,x ; current
        copy    date,x, date_b,x  ; maximum
        dey
        dex
        bpl     :-
        jsr     compare_dates
        beq     inext
        bcc     inext

        ;; if greater than
place:  ldy     #FileRecord::modification_date + .sizeof(DateTime)-1
        ldx     #.sizeof(DateTime)-1
:       copy    (ptr),y, date,x ; new maximum
        dey
        dex
        bpl     :-

        lda     record_num
        sta     $0806
inext:  inc     record_num
        lda     record_num
        cmp     num_records
        beq     next
        jmp     iloop

next:   inc     index
        lda     $0806
        sta     record_num
        jsr     ptr_calc

        ;; Mark record
        ldy     #0
        lda     (ptr),y
        ora     #$80
        sta     (ptr),y

        lda     #0              ; Zero out date
        ldx     #.sizeof(DateTime)-1
:       sta     date,x
        dex
        bpl     :-

        ldx     index
        dex
        ldy     $0806
        iny
        jsr     L812B

        copy    #0, record_num
        jmp     loop
.endscope

        ;; --------------------------------------------------

check_size:
        cmp     #kViewBySize
        beq     :+
        jmp     check_type

:
        ;; By Size

        ;; Sorted by decreasing size
.scope
        size := $0808

        lda     LCBANK2
        lda     LCBANK2

        lda     #0
        sta     size
        sta     size+1
        sta     index
        sta     record_num

loop:   lda     index
        cmp     num_records
        bne     iloop
        jmp     finish_view_change

iloop:  jsr     ptr_calc

        ;; Check record for mark
        ldy     #0
        lda     (ptr),y
        bmi     inext

        ldy     #FileRecord::blocks+1
        lda     (ptr),y
        cmp     size+1          ; hi byte
        beq     :+
        bcs     place
:       dey
        lda     (ptr),y
        cmp     size            ; lo byte
        beq     place
        bcc     inext

        ;; if greater than
place:  copy16in (ptr),y, size
        lda     record_num
        sta     $0806

inext:  inc     record_num
        lda     record_num
        cmp     num_records
        beq     next
        jmp     iloop

next:   inc     index
        lda     $0806
        sta     record_num
        jsr     ptr_calc

        ;; Mark record
        ldy     #0
        lda     (ptr),y
        ora     #$80
        sta     (ptr),y

        lda     #0
        sta     size
        sta     size+1

        ldx     index
        dex
        ldy     $0806
        iny
        jsr     L812B

        lda     #0
        sta     record_num
        jmp     loop

        lda     LCBANK1
        lda     LCBANK1

        copy16  #84, pos_col_name::xcoord
        copy16  #203, pos_col_type::xcoord
        lda     #0
        sta     pos_col_size::xcoord
        sta     pos_col_size::xcoord+1
        copy16  #231, pos_col_date::xcoord

        lda     LCBANK2
        lda     LCBANK2
        jmp     finish_view_change
.endscope

        ;; --------------------------------------------------

check_type:
        cmp     #kViewByType
        beq     :+
        rts

:
        ;; By Type

        ;; Types are ordered by type_table
.scope
        type_table_copy := $807

        ;; Copy type_table prefixed by length to $807
        copy16  #type_table, $08
        copy    #kNumFileTypes, type_table_copy
        ldy     #kNumFileTypes-1
:       lda     ($08),y
        sta     type_table_copy+1,y
        dey
        bne     :-

        lda     LCBANK2
        lda     LCBANK2

        lda     #0
        sta     index
        sta     record_num
        copy    #$FF, $0806

loop:   lda     index
        cmp     num_records
        bne     iloop
        jmp     finish_view_change

iloop:  jsr     ptr_calc

        ;; Check record for mark
        ldy     #0
        lda     (ptr),y
        bmi     inext

        ;; Compare types
        ldy     #FileRecord::file_type
        lda     (ptr),y
        ldx     type_table_copy
        cpx     #0
        beq     place
        cmp     type_table_copy+1,x
        bne     inext

place:  lda     record_num
        sta     $0806
        jmp     L809E

inext:  inc     record_num
        lda     record_num
        cmp     num_records
        beq     next
        jmp     iloop

next:   lda     $0806
        cmp     #$FF
        bne     L809E
        dec     type_table_copy ; size of table
        lda     #0
        sta     record_num
        jmp     iloop

L809E:  inc     index
        lda     $0806
        sta     record_num
        jsr     ptr_calc

        ;; Mark record
        ldy     #0
        lda     (ptr),y
        ora     #$80
        sta     (ptr),y

        ldx     index
        dex
        ldy     $0806
        iny
        jsr     L812B

        copy    #0, record_num
        copy    #$FF, $0806
        jmp     loop
.endscope

;;; --------------------------------------------------
;;; ptr = list_start_ptr + ($800 * .sizeof(FileRecord))

.proc ptr_calc
        ptr := $6
        hi := $0804

        lda     #0
        sta     hi
        lda     record_num
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi

        clc
        adc     list_start_ptr
        sta     ptr
        lda     list_start_ptr+1
        adc     hi
        sta     ptr+1

        rts
.endproc

;;; --------------------------------------------------

date_a: .tag    DateTime
date_b: .tag    DateTime

.proc compare_dates
        ptr := $0A

        copy16  #parsed_a, ptr
        ldax    #date_a
        jsr     parse_datetime

        copy16  #parsed_b, ptr
        ldax    #date_b
        jsr     parse_datetime

        lda     year_a+1
        cmp     year_b+1
        bne     done
        lda     year_a
        cmp     year_b
        bne     done
        lda     month_a
        cmp     month_b
        bne     done
        lda     day_a
        cmp     day_b
done:   rts

parsed_a:
        .tag ParsedDateTime
year_a  := parsed_a + ParsedDateTime::year
month_a := parsed_a + ParsedDateTime::month
day_a   := parsed_a + ParsedDateTime::day
hour_a  := parsed_a + ParsedDateTime::hour
min_a   := parsed_a + ParsedDateTime::minute

parsed_b:
        .tag ParsedDateTime
year_b  := parsed_b + ParsedDateTime::year
month_b := parsed_b + ParsedDateTime::month
day_b   := parsed_b + ParsedDateTime::day
hour_b  := parsed_b + ParsedDateTime::hour
min_b   := parsed_b + ParsedDateTime::minute

.endproc

;;; --------------------------------------------------
;;; ???

.proc finish_view_change
        ptr := $06

        copy    #0, record_num

loop:   lda     record_num
        cmp     num_records
        beq     done
        jsr     ptr_calc
        ldy     #$00
        lda     (ptr),y
        and     #$7F
        sta     (ptr),y
        ldy     #$17
        lda     (ptr),y
        bne     :+
        iny
        lda     (ptr),y
        cmp     #$01
        bne     :+
        lda     #$00
        sta     (ptr),y
:       inc     record_num
        jmp     loop

done:   lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

;;; --------------------------------------------------
;;; ???

.proc L812B
        lda     LCBANK1
        lda     LCBANK1
        tya
        sta     cached_window_icon_list,x
        lda     LCBANK2
        lda     LCBANK2
        rts
.endproc

.endproc


;;; ============================================================
;;; A = entry number

.proc draw_list_view_row_impl

addr_lo:
        .byte   0
        .byte   0               ; Unused

row_height:
        .byte   8

        ptr := $06

start:
        ;; Compute address of (A-1)th file record
        ldy     #0
        tax                     ; 1-based to 0-based
        dex
        txa
        sty     addr_lo
        .assert .sizeof(FileRecord) = 32, error, "FileRecord size must be 2^5"
        asl     a               ; * 32
        rol     addr_lo
        asl     a
        rol     addr_lo
        asl     a
        rol     addr_lo
        asl     a
        rol     addr_lo
        asl     a
        rol     addr_lo
        clc
        adc     file_record_ptr
        sta     ptr
        lda     file_record_ptr+1
        adc     addr_lo
        sta     ptr+1

        ;; Copy into more convenient location (LCBANK1)
        lda     LCBANK2
        lda     LCBANK2
        ldy     #.sizeof(FileRecord)-1
:       lda     (ptr),y
        sta     list_view_filerecord,y
        dey
        bpl     :-
        lda     LCBANK1
        lda     LCBANK1

        ;; Clear out string
        ldx     #kTextBuffer2Len
        lda     #' '
:       sta     text_buffer2::data-1,x
        dex
        bpl     :-
        copy    #0, text_buffer2::length

        lda     pos_col_type::ycoord
        clc
        adc     row_height
        sta     pos_col_type::ycoord
        bcc     :+
        inc     pos_col_type::ycoord+1
:
        lda     pos_col_size::ycoord
        clc
        adc     row_height
        sta     pos_col_size::ycoord
        bcc     :+
        inc     pos_col_size::ycoord+1
:
        lda     pos_col_date::ycoord
        clc
        adc     row_height
        sta     pos_col_date::ycoord
        bcc     :+
        inc     pos_col_date::ycoord+1
:
        ;; Below bottom?
        cmp16   pos_col_name::ycoord, window_grafport::cliprect::y2
        bmi     check_top
        lda     pos_col_name::ycoord
        clc
        adc     row_height
        sta     pos_col_name::ycoord
        bcc     :+
        inc     pos_col_name::ycoord+1
:       rts

        ;; Above top?
check_top:
        lda     pos_col_name::ycoord
        clc
        adc     row_height
        sta     pos_col_name::ycoord
        bcc     :+
        inc     pos_col_name::ycoord+1
:       cmp16   pos_col_name::ycoord, window_grafport::cliprect::y1
        bpl     in_range
        rts

        ;; Draw it!
in_range:
        jsr     prepare_col_name
        addr_call SetPosDrawText, pos_col_name
        jsr     prepare_col_type
        addr_call SetPosDrawText, pos_col_type
        jsr     prepare_col_size
        addr_call SetPosDrawText, pos_col_size
        jsr     compose_date_string
        addr_jump SetPosDrawText, pos_col_date
.endproc
        draw_list_view_row := draw_list_view_row_impl::start

;;; ============================================================

.proc prepare_col_name
        name := list_view_filerecord + FileRecord::name

        lda     name
        and     #$0F
        sta     text_buffer2::length
        tax
loop:   lda     name,x
        sta     text_buffer2::data,x
        dex
        bne     loop
        lda     #' '
        sta     text_buffer2::data
        inc     text_buffer2::length
        rts
.endproc

.proc prepare_col_type
        file_type := list_view_filerecord + FileRecord::file_type

        lda     file_type
        jsr     compose_file_type_string

        ;; BUG: should be 4 not 5???
        COPY_BYTES 5, str_file_type, text_buffer2::data-1

        rts
.endproc

.proc prepare_col_size
        blocks := list_view_filerecord + FileRecord::blocks

        ldax    blocks
        ;; fall through
.endproc

;;; ============================================================
;;; Populate text_buffer2 with " 12345 Blocks"

.proc compose_blocks_string
        stax    value
        jsr     int_to_string

        ;; Leading space
        ldx     #1
        stx     text_buffer2::length
        copy    #' ', text_buffer2::data

        ;; Append number
        ldy     #0
:       lda     str_from_int+1,y
        sta     text_buffer2::data,x ; data follows length
        iny
        inx
        cpy     str_from_int
        bne     :-

        ;; Append suffix
        ldy     #0
:       lda     suffix+1, y
        sta     text_buffer2::data,x
        iny
        inx
        cpy     suffix
        bne     :-

        ;; If singular, drop trailing 's'
        ;; Block or Blocks?
        lda     value+1
        cmp     #>1
        bne     :+
        lda     value
        cmp     #<1
        bne     :+
        dex
:       stx     text_buffer2::length

done:   rts

suffix: PASCAL_STRING " Blocks"

value:  .word   0

.endproc

;;; ============================================================

.proc compose_date_string
        ldx     #kTextBuffer2Len
        lda     #' '
:       sta     text_buffer2::data-1,x
        dex
        bpl     :-
        lda     #1
        sta     text_buffer2::length
        copy16  #text_buffer2::length, $8
        lda     datetime_for_conversion ; any bits set?
        ora     datetime_for_conversion+1
        bne     append_date_strings
        sta     month           ; 0 is "no date" string
        jmp     append_month_string

append_date_strings:
        copy16  #parsed_date, $0A
        ldax    #datetime_for_conversion
        jsr     parse_datetime

        jsr     append_month_string
        addr_call concatenate_date_part, str_space
        jsr     append_day_string
        addr_call concatenate_date_part, str_comma
        jsr     append_year_string

        addr_call concatenate_date_part, str_at
        ldax    #parsed_date
        jsr     make_time_string
        addr_jump concatenate_date_part, str_time

.proc append_day_string
        lda     day
        ldx     #0
        jsr     int_to_string

        addr_jump concatenate_date_part, str_from_int
.endproc

.proc append_month_string
        lda     month
        asl     a
        tay
        lda     month_table+1,y
        tax
        lda     month_table,y

        jmp     concatenate_date_part
.endproc

.proc append_year_string
        ldax    year
        jsr     int_to_string
        addr_jump concatenate_date_part, str_from_int
.endproc

year    := parsed_date + ParsedDateTime::year
month   := parsed_date + ParsedDateTime::month
day     := parsed_date + ParsedDateTime::day
hour    := parsed_date + ParsedDateTime::hour
min     := parsed_date + ParsedDateTime::minute

month_table:
        .addr   str_no_date
        .addr   str_jan,str_feb,str_mar,str_apr,str_may,str_jun
        .addr   str_jul,str_aug,str_sep,str_oct,str_nov,str_dec
        ASSERT_ADDRESS_TABLE_SIZE month_table, 13

str_no_date:
        PASCAL_STRING "no date"

str_jan:PASCAL_STRING "January"
str_feb:PASCAL_STRING "February"
str_mar:PASCAL_STRING "March"
str_apr:PASCAL_STRING "April"
str_may:PASCAL_STRING "May"
str_jun:PASCAL_STRING "June"
str_jul:PASCAL_STRING "July"
str_aug:PASCAL_STRING "August"
str_sep:PASCAL_STRING "September"
str_oct:PASCAL_STRING "October"
str_nov:PASCAL_STRING "November"
str_dec:PASCAL_STRING "December"

str_space:
        PASCAL_STRING " "
str_comma:
        PASCAL_STRING ", "
str_at:
        PASCAL_STRING " at "

.proc concatenate_date_part
        stax    $06
        ldy     #$00
        lda     ($08),y
        sta     concat_len
        clc
        adc     ($06),y
        sta     ($08),y
        lda     ($06),y
        sta     @compare_y
:       inc     concat_len
        iny
        lda     ($06),y
        sty     tmp
        ldy     concat_len
        sta     ($08),y
        ldy     tmp
        @compare_y := *+1
        cpy     #0              ; self-modified
        bcc     :-
        rts

tmp:    .byte   0
concat_len:
        .byte   0
.endproc

.endproc

;;; ============================================================
;;; After a scroll, compute the new scroll maximum and update
;;; window clipping region

.proc compute_new_scroll_max
        jsr     push_pointers

        bit     active_window_view_by
        bmi     :+
        jsr     cached_icons_screen_to_window
:
        ;; View bounds
        sub16   window_grafport::cliprect::x2, window_grafport::cliprect::x1, clip_w
        sub16   window_grafport::cliprect::y2, window_grafport::cliprect::y1, clip_h

        lda     updatethumb_which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     L850C
        asl     a
        bne     L850E           ; always
L850C:  lda     #$00
L850E:  sta     dir

        ptr := $06

        lda     active_window_id
        jsr     window_lookup
        stax    ptr
        lda     #MGTK::Winfo::hthumbmax
        clc
        adc     dir             ; MGTK::Winfo::vthumbmax if dir is set
        tay
        lda     (ptr),y
        pha
        jsr     compute_icons_bbox

        ldx     dir
        sub16   iconbb_rect::x2,x, iconbb_rect::x1,x, L85F2

        ldx     dir
        sub16   L85F2, clip,x, L85F2

        bpl     :+
        lda     clip,x          ; if negative, use original bounds
        sta     L85F2
        lda     clip+1,x
        sta     L85F2+1
:

        lsr16   L85F2           ; / 4
        lsr16   L85F2
        lda     L85F2           ; which should bring it into single byte range
        tay
        pla
        tax
        lda     updatethumb_thumbpos
        jsr     calculate_thumb_pos
        ldx     #$00
        stx     L85F2
        asl     a
        rol     L85F2
        asl     a
        rol     L85F2

        ldx     dir
        clc
        adc     iconbb_rect::x1,x
        sta     window_grafport::cliprect::x1,x
        lda     L85F2
        adc     iconbb_rect::x1+1,x
        sta     window_grafport::cliprect::x1+1,x

        lda     active_window_id
        jsr     compute_window_dimensions
        stax    new_w
        sty     new_h
        lda     dir
        beq     :+
        add16_8 window_grafport::cliprect::y1, new_h, window_grafport::cliprect::y2
        jmp     update_port
:       add16 window_grafport::cliprect::x1, new_w, window_grafport::cliprect::x2

        ;; Update window's port
update_port:
        lda     active_window_id
        jsr     window_lookup
        stax    ptr

        ldy     #.sizeof(MGTK::GrafPort)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     window_grafport::cliprect::x1,x
        sta     (ptr),y
        dey
        dex
        bpl     :-

        jsr     pop_pointers
        rts

dir:    .byte   0               ; 0 if horizontal, 2 if vertical (word offset)
L85F2:  .word   0
new_w:  .word   0
new_h:  .word   0

clip:
clip_w: .word   0
clip_h: .word   0
.endproc


;;; ============================================================
;;; A = A * 16, high bits into X

.proc a_times_16
        ldx     #0
        stx     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        ldx     tmp
        rts

tmp:    .byte   0
.endproc

;;; ============================================================
;;; A = A * 64, high bits into X

.proc a_times_64
        ldx     #$00
        stx     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        ldx     tmp
        rts

tmp:    .byte   0
.endproc

;;; ============================================================
;;; Look up file address. Index in A, address in A,X.

.proc icon_entry_lookup
        asl     a
        tax
        lda     icon_entry_address_table,x
        pha
        lda     icon_entry_address_table+1,x
        tax
        pla
        rts
.endproc

;;; ============================================================
;;; Look up window. Index in A, address in A,X.

.proc window_lookup
        asl     a
        tax
        lda     win_table,x
        pha
        lda     win_table+1,x
        tax
        pla
        rts
.endproc

;;; ============================================================
;;; Look up window address. Index in A, address in A,X.

.proc window_path_lookup
        asl     a
        tax
        lda     window_path_addr_table,x
        pha
        lda     window_path_addr_table+1,x
        tax
        pla
        rts
.endproc

;;; ============================================================

.proc compose_file_type_string
        ptr := $06

        sta     file_type
        copy16  #type_table, ptr
        ldy     #kNumFileTypes-1
:       lda     (ptr),y
        cmp     file_type
        beq     found
        dey
        bpl     :-
        jmp     not_found

        ;; Found - copy string from table
found:  tya
        asl     a
        asl     a
        tay
        copy16  #type_names_table, ptr

        ldx     #0
:       lda     (ptr),y
        sta     str_file_type+1,x
        iny
        inx
        cpx     #4
        bne     :-

        stx     str_file_type
        rts

        ;; Type not found - use generic " $xx"
not_found:
        copy    #4, str_file_type
        copy    #' ', str_file_type+1
        copy    #'$', str_file_type+2

        lda     file_type
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        copy    hex_digits,x, str_file_type+3

        lda     file_type
        and     #$0F
        tax
        copy    hex_digits,x, str_file_type+4

        rts

file_type:
        .byte   0

.endproc

;;; ============================================================
;;; Append aux type (in A,X) to text_buffer2

.proc append_aux_type
        stax    auxtype
        ldy     text_buffer2::length

        ;; Append prefix
        ldx     #0
:       lda     prefix+1,x
        sta     text_buffer2::data,y
        inx
        iny
        cpx     prefix
        bne     :-

        ;; Append type
        lda     auxtype+1
        jsr     do_byte
        lda     auxtype
        jsr     do_byte

        ;; Append suffix
        lda     #')'
        sta     text_buffer2::data,y
        iny
        sty     text_buffer2::length
        rts

do_byte:
        pha
        lsr
        lsr
        lsr
        lsr
        tax
        lda     hex_digits,x
        sta     text_buffer2::data,y
        iny
        pla
        and     #%00001111
        tax
        lda     hex_digits,x
        sta     text_buffer2::data,y
        iny
        rts

prefix: PASCAL_STRING "   (AuxType: $"

auxtype:
        .word 0
.endproc

;;; ============================================================
;;; Draw text, pascal string address in A,X

.proc draw_pascal_string
        params := $6
        textptr := $6
        textlen := $8

        stax    textptr
        ldy     #0
        lda     (textptr),y
        beq     exit
        sta     textlen
        inc16   textptr
        MGTK_RELAY_CALL MGTK::DrawText, params
exit:   rts
.endproc

;;; ============================================================
;;; Measure text, pascal string address in A,X; result in A,X

.proc measure_text1
        ptr := $6
        len := $8
        result := $9

        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     len
        inc16   ptr
        MGTK_RELAY_CALL MGTK::TextWidth, ptr
        ldax    result
        rts
.endproc

;;; ============================================================
;;; Pushes two words from $6/$8 to stack

.proc push_pointers
        ptr := $6

        pla                     ; stash return address
        sta     addr
        pla
        sta     addr+1

        ldx     #0              ; copy 4 bytes from $8 to stack
loop:   lda     ptr,x
        pha
        inx
        cpx     #4
        bne     loop

        lda     addr+1           ; restore return address
        pha
        lda     addr
        pha
        rts

addr:   .addr   0
.endproc

;;; ============================================================
;;; Pops two words from stack to $6/$8; trashes A,X

.proc pop_pointers
        ptr := $6

        pla                     ; stash return address
        sta     addr
        pla
        sta     addr+1

        ldx     #3              ; copy 4 bytes from stack to $6
loop:   pla
        sta     ptr,x
        dex
        cpx     #$FF            ; why not bpl ???
        bne     loop

        lda     addr+1          ; restore return address to stack
        pha
        lda     addr
        pha
        rts

addr:   .addr   0
.endproc

;;; ============================================================

port_copy:
        .res    .sizeof(MGTK::GrafPort)+1, 0

.proc copy_window_portbits
        ptr := $6

        tay
        jsr     push_pointers
        tya
        jsr     window_lookup
        stax    ptr
        ldx     #0
        ldy     #MGTK::Winfo::port
:       lda     (ptr),y
        sta     port_copy,x
        iny
        inx
        cpx     #.sizeof(MGTK::GrafPort)
        bne     :-
        jsr     pop_pointers
        rts
.endproc

.proc assign_window_portbits
        ptr := $6

        tay
        jsr     push_pointers
        tya
        jsr     window_lookup
        stax    ptr
        ldx     #0
        ldy     #MGTK::Winfo::port
:       lda     port_copy,x
        sta     (ptr),y
        iny
        inx
        cpx     #.sizeof(MGTK::GrafPort)
        bne     :-
        jsr     pop_pointers
        rts
.endproc

;;; ============================================================
;;; Convert icon's coordinates from window to screen
;;; (icon index in A, active window)

.proc icon_window_to_screen
        entry_ptr := $6
        winfo_ptr := $8

        tay
        jsr     push_pointers
        tya
        jsr     icon_entry_lookup
        stax    entry_ptr

        lda     active_window_id
        jsr     window_lookup
        stax    winfo_ptr

        ;; Screen space
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + 3
        ldx     #3
:       lda     (winfo_ptr),y
        sta     pos_screen,x
        dey
        dex
        bpl     :-

        ;; Window space
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + 3
        ldx     #3
:       lda     (winfo_ptr),y
        sta     pos_win,x
        dey
        dex
        bpl     :-

        ;; iconx
        ldy     #IconEntry::iconx
        add16in (entry_ptr),y, pos_screen, (entry_ptr),y
        iny

        ;; icony
        add16in (entry_ptr),y, pos_screen+2, (entry_ptr),y

        ;; iconx
        ldy     #IconEntry::iconx
        sub16in (entry_ptr),y, pos_win, (entry_ptr),y
        iny

        ;; icony
        sub16in (entry_ptr),y, pos_win+2, (entry_ptr),y

        jsr     pop_pointers
        rts

pos_screen:     .word   0, 0
pos_win:        .word   0, 0

.endproc

;;; ============================================================
;;; Convert icon's coordinates from screen to window
;;; (icon index in A, active window)

.proc icon_screen_to_window
        tay
        jsr     push_pointers
        tya
        jsr     icon_entry_lookup
        stax    $06
        ;; fall through
.endproc

;;; Convert icon's coordinates from screen to window
;;; (icon entry pointer in $6, active window)

.proc icon_ptr_screen_to_window
        entry_ptr := $6
        winfo_ptr := $8

        lda     active_window_id
        jsr     window_lookup
        stax    winfo_ptr

        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + 3
        ldx     #3
:       lda     (winfo_ptr),y
        sta     pos_screen,x
        dey
        dex
        bpl     :-

        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + 3
        ldx     #3
:       lda     (winfo_ptr),y
        sta     pos_win,x
        dey
        dex
        bpl     :-

        ;; iconx
        ldy     #IconEntry::iconx
        sub16in (entry_ptr),y, pos_screen, (entry_ptr),y
        iny

        ;; icony
        sub16in (entry_ptr),y, pos_screen+2, (entry_ptr),y

        ;; iconx
        ldy     #IconEntry::iconx
        add16in (entry_ptr),y, pos_win, (entry_ptr),y
        iny

        ;; icony
        add16in (entry_ptr),y, pos_win+2, (entry_ptr),y
        jsr     pop_pointers
        rts

pos_screen:     .word   0, 0
pos_win:        .word   0, 0
.endproc

;;; ============================================================
;;; Zero out and then select highlight_grafport. Used for setting
;;; and clearing selections (since icons are in screen space).

.proc prepare_highlight_grafport
        lda     #0
        tax
:       sta     highlight_grafport::cliprect::x1,x
        sta     highlight_grafport::viewloc::xcoord,x
        sta     highlight_grafport::cliprect::x2,x
        inx
        cpx     #4
        bne     :-
        MGTK_RELAY_CALL MGTK::SetPort, highlight_grafport
        rts
.endproc

;;; ============================================================
;;; Input: A = unit_number
;;; Output: A =
;;;  0 = Disk II
;;;  1 = SmartPort, RAM Disk
;;;  2 = SmartPort, Fixed (e.g. ProFile)
;;;  3 = SmartPort, Removable (e.g. UniDisk 3.5)
;;;  4 = AppleTalk file share
;;;  5 = unknown / RAM-based driver

device_type_to_icon_address_table:
        .addr floppy140_icon
        .addr ramdisk_icon
        .addr profile_icon
        .addr floppy800_icon
        .addr fileshare_icon
        .addr profile_icon ; unknown

.proc get_device_type
        slot_addr := $0A
        sta     unit_number

        cmp     #kRamDrvSystemUnitNum ; Glen E. Bredon's RAM.DRV.SYSTEM
        beq     ram

        ;; Look at "ID Nibble" (mostly bogus)
        and     #%00001111      ; look at low nibble
        bne     :+              ; 0 = Disk II
        rts

        ;; Look up driver address
:       lda     unit_number
        jsr     device_driver_address
        bne     unk             ; RAM-based driver: just use default
        lda     #$00
        sta     slot_addr       ; point at $Cn00 for firmware lookups

        ;; Probe firmware ID bytes
        ldy     #$FF            ; $CnFF: $00=Disk II, $FF=13-sector, else=block
        lda     (slot_addr),y
        bne     :+
        rts                     ; 0 = Disk II

:       ldy     #$07            ; SmartPort signature byte ($Cn07)
        lda     (slot_addr),y   ; $00 = SmartPort
        bne     unk

        ldy     #$FB            ; SmartPort ID Type Byte ($CnFB)
        lda     (slot_addr),y   ; bit 0 = is RAM Card?
        and     #%00000001
        beq     :+
ram:    return  #kDeviceTypeRAMDisk

:       lda     unit_number     ; low nibble is high nibble of $CnFE

        ;; Old heuristic. Invalid on UDC, etc.
        ;;         and     #%00001111
        ;;         cmp     #DT_REMOVABLE

        ;; Better heuristic, but still invalid on UDC, Virtual II, etc.
        ;;         and     #%00001000      ; bit 3 = is removable?

        ;; So instead, just assume <=1600 blocks is a 3.5" floppy
        jsr     get_block_count
        bcs     hd
        stax    blocks
        cmp16   blocks, #1601
        bcs     hd
        return  #kDeviceTypeRemovable

        ;; Try AppleTalk
unk:    MLI_RELAY_CALL READ_BLOCK, block_params
        beq     hd
        cmp     #ERR_NETWORK_ERROR
        bne     hd
        return  #kDeviceTypeFileShare

hd:     return  #kDeviceTypeProFile

        DEFINE_READ_BLOCK_PARAMS block_params, $800, 2
        unit_number := block_params::unit_num

blocks: .word   0
.endproc

;;; ============================================================
;;; Get the block count for a given unit number.
;;; Input: A=unit_number
;;; Output: C=0, blocks in A,X on success, C=1 on error
.proc get_block_count_impl
        DEFINE_ON_LINE_PARAMS on_line_params,, buffer
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, path

start:  sta     on_line_params::unit_num
        MLI_RELAY_CALL ON_LINE, on_line_params
        bne     error

        ;; Prefix the path with '/'
        lda     buffer
        and     #NAME_LENGTH_MASK
        clc
        adc     #1              ; account for '/'
        sta     path
        copy    #'/', buffer

        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params
        bne     error

        ldax    get_file_info_params::aux_type
        clc
        rts

error:  sec
        rts

path:   .byte   0               ; becomes length-prefixed path
buffer: .res    16, 0            ; length overwritten with '/'
.endproc
        get_block_count := get_block_count_impl::start

;;; ============================================================
;;; Create Volume Icon
;;; Input: A = unit number, X = icon num, Y = index in DEVLST
;;; Output: 0 on success, ProDOS error code on failure

        cvi_data_buffer := $800

        DEFINE_ON_LINE_PARAMS on_line_params,, cvi_data_buffer

.proc create_volume_icon
        kMaxIconWidth = 53
        kMaxIconHeight = 15

        sta     unit_number
        dex                     ; icon numbers are 1-based, and Trash is #1,
        dex                     ; so make this 0-based
        stx     icon_index
        sty     devlst_index
        and     #$F0
        sta     on_line_params::unit_num
        MLI_RELAY_CALL ON_LINE, on_line_params
        beq     success

error:  pha                     ; save error
        ldy     devlst_index      ; remove unit from list
        lda     #0
        sta     device_to_icon_map,y
        dec     cached_window_icon_count
        dec     icon_count
        pla
        rts

success:
        lda     cvi_data_buffer ; dr/slot/name_len
        and     #NAME_LENGTH_MASK
        bne     create_icon
        lda     cvi_data_buffer+1 ; if name len is zero, second byte is error
        jmp     error

create_icon:
        icon_ptr := $6
        icon_defn_ptr := $8

        jsr     push_pointers
        jsr     AllocateIcon
        ldy     devlst_index
        sta     device_to_icon_map,y
        jsr     icon_entry_lookup
        stax    icon_ptr

        ;; Copy name
        lda     cvi_data_buffer
        and     #NAME_LENGTH_MASK
        sta     cvi_data_buffer

        addr_call adjust_volname_case, cvi_data_buffer

        ldy     #IconEntry::name+1

        ldx     #0
:       lda     cvi_data_buffer+1,x
        sta     (icon_ptr),y
        iny
        inx
        cpx     cvi_data_buffer
        bne     :-

        txa
        ldy     #IconEntry::name
        sta     (icon_ptr),y

        ;; ----------------------------------------

        ;; Figure out icon
        lda     unit_number
        jsr     get_device_type
        asl                     ; * 2
        tax
        ldy     #IconEntry::iconbits
        lda     device_type_to_icon_address_table,x
        sta     icon_defn_ptr
        sta     (icon_ptr),y
        iny
        lda     device_type_to_icon_address_table+1,x
        sta     icon_defn_ptr+1
        sta     (icon_ptr),y

        ;; ----------------------------------------

        ;; Assign icon type
        ldy     #IconEntry::win_type
        lda     #0
        sta     (icon_ptr),y
        inc     devlst_index

        ;; Assign icon coordinates
        lda     icon_index
        asl                     ; * 4 = .sizeof(MGTK::Point)
        asl
        tax
        ldy     #IconEntry::iconx
:       lda     desktop_icon_coords_table,x
        sta     (icon_ptr),y
        inx
        iny
        cpy     #IconEntry::iconbits
        bne     :-

        ;; Center it horizontally
        ldy     #IconDefinition::maprect + MGTK::Rect::x2
        sub16in #kMaxIconWidth, (icon_defn_ptr),y, offset
        lsr16   offset          ; offset = (max_width - icon_width) / 2
        ldy     #IconEntry::iconx
        add16in (icon_ptr),y, offset, (icon_ptr),y

        ;; Adjust vertically
        ldy     #IconDefinition::maprect + MGTK::Rect::y2
        sub16in #kMaxIconHeight, (icon_defn_ptr),y, offset
        ldy     #IconEntry::icony
        add16in (icon_ptr),y, offset, (icon_ptr),y

        ;; Assign icon number
        ldx     cached_window_icon_count
        dex
        ldy     #IconEntry::id
        lda     (icon_ptr),y
        sta     cached_window_icon_list,x
        jsr     pop_pointers
        return  #0

unit_number:    .byte   0
devlst_index:   .byte   0
icon_index:     .byte   0
offset:         .word   0

.endproc

;;; ============================================================

.proc remove_icon_from_window
        ldx     cached_window_icon_count
        dex
:       cmp     cached_window_icon_list,x
        beq     remove
        dex
        bpl     :-
        rts

remove: lda     cached_window_icon_list+1,x
        sta     cached_window_icon_list,x
        inx
        cpx     cached_window_icon_count
        bne     remove
        dec     cached_window_icon_count
        ldx     cached_window_icon_count
        lda     #0
        sta     cached_window_icon_list,x
        rts
.endproc

;;; ============================================================
;;; Search the window->dir_icon mapping table.
;;; Inputs: A = icon number
;;; Outputs: Z=1 && N=0 if found, X = index (0-7), A unchanged

.proc find_window_for_dir_icon
        ldx     #7
:       cmp     window_to_dir_icon_table,x
        beq     done
        dex
        bpl     :-
done:   rts
.endproc

;;; ============================================================

.proc mark_icons_not_opened
        ptr := $6

L8B19:  jsr     push_pointers
        jmp     start

        ;; This entry point removes filerecords associated with window
L8B1F:  lda     icon_params2
        bne     :+
        rts
:       jsr     push_pointers
        lda     icon_params2
        jsr     find_window_for_dir_icon
        bne     :+
        inx
        txa
        jsr     remove_window_filerecord_entries
:
        ;; fall through

        ;; Find open window for the icon
start:  lda     icon_params2
        jsr     find_window_for_dir_icon
        bne     skip            ; not found

        ;; If found, remove from the table
        ;; TODO: should this be $FF instead?
        copy    #0, window_to_dir_icon_table,x

        ;; Update the icon and redraw
skip:   lda     icon_params2
        jsr     icon_entry_lookup
        stax    ptr
        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #AS_BYTE(~kIconEntryOpenMask) ; clear open_flag
        sta     (ptr),y
        jsr     redraw_selected_icons
        jsr     pop_pointers
        rts
.endproc
        mark_icons_not_opened_1 := mark_icons_not_opened::L8B19
        mark_icons_not_opened_2 := mark_icons_not_opened::L8B1F

;;; ============================================================

.proc animate_window
        ptr := $06
        rect_table := $800

close:  ldy     #$80
        bne     :+

open:   ldy     #$00

:       sty     close_flag

        sta     icon_id
        stx     window_id
        txa

        ;; Get window rect
        jsr     window_lookup
        stax    ptr
        lda     #MGTK::Winfo::port
        clc                     ; Why add instead of just loading Y with constant ???
        adc     #.sizeof(MGTK::GrafPort)-1
        tay

        ldx     #.sizeof(MGTK::GrafPort)-1
:       lda     (ptr),y
        sta     window_grafport,x
        dey
        dex
        bpl     :-

        ;; Get icon position
        lda     icon_id
        jsr     icon_entry_lookup
        stax    ptr
        ldy     #IconEntry::iconx
        lda     (ptr),y         ; x lo
        clc
        adc     #7

        sta     rect_table
        sta     rect_table+4

        iny
        lda     (ptr),y
        adc     #0
        sta     rect_table+1
        sta     rect_table+5

        iny
        lda     (ptr),y
        clc
        adc     #7
        sta     rect_table+2
        sta     rect_table+6

        iny
        lda     (ptr),y         ; y hi
        adc     #0
        sta     rect_table+3
        sta     rect_table+7

        ldy     #11 * .sizeof(MGTK::Rect) + 3
        ldx     #3
:       lda     window_grafport,x
        sta     rect_table,y
        dey
        dex
        bpl     :-

        sub16   window_grafport::cliprect::x2, window_grafport::cliprect::x1, L8D54
        sub16   window_grafport::cliprect::y2, window_grafport::cliprect::y1, L8D56
        add16   $0858, L8D54, $085C
        add16   $085A, L8D56, $085E
        lda     #$00
        sta     flag
        sta     flag2
        sta     step
        sub16   $0858, rect_table, L8D50
        sub16   $085A, $0802, L8D52

        bit     L8D50+1
        bpl     :+

        copy    #$80, flag
        lda     L8D50           ; negate
        eor     #$FF
        sta     L8D50
        lda     L8D50+1
        eor     #$FF
        sta     L8D50+1
        inc16   L8D50
:

        bit     L8D52+1
        bpl     :+

        copy    #$80, flag2
        lda     L8D52           ; negate
        eor     #$FF
        sta     L8D52
        lda     L8D52+1
        eor     #$FF
        sta     L8D52+1
        inc16   L8D52
:

L8C8C:  lsr16   L8D50           ; divide by two
        lsr16   L8D52
        lsr16   L8D54
        lsr16   L8D56
        lda     #10
        sec
        sbc     step
        asl     a
        asl     a
        asl     a
        tax
        bit     flag
        bpl     :+
        sub16   rect_table, L8D50, rect_table,x
        jmp     L8CDC

:       add16   rect_table, L8D50, rect_table,x

L8CDC:  bit     flag2
        bpl     L8CF7
        sub16   $0802, L8D52, $0802,x
        jmp     L8D0A

L8CF7:  add16   rect_table+2, L8D52, rect_table+2,x

L8D0A:  add16   rect_table,x, L8D54, rect_table+4,x ; right
        add16   rect_table+2,x, L8D56, rect_table+6,x ; bottom

        inc     step
        lda     step
        cmp     #10
        beq     :+
        jmp     L8C8C

:       bit     close_flag
        bmi     :+
        jsr     animate_window_open_impl
        rts

:       jsr     animate_window_close_impl
        rts

close_flag:
        .byte   0

icon_id:
        .byte   0
window_id:
        .byte   0

step:   .byte   0
flag:   .byte   0               ; ???
flag2:  .byte   0               ; ???
L8D50:  .word   0
L8D52:  .word   0
L8D54:  .word   0
L8D56:  .word   0
.endproc
        animate_window_close := animate_window::close
        animate_window_open := animate_window::open

;;; ============================================================

kMaxAnimationStep = 11

.proc animate_window_open_impl

        rect_table := $800

        ;; Loop N = 0 to 13
        ;; If N in 0..11, draw N
        ;; If N in 2..13, erase N-2 (i.e. 0..11, 2 behind)

        lda     #0
        sta     step
        jsr     reset_main_grafport
        MGTK_RELAY_CALL MGTK::SetPattern, checkerboard_pattern
        jsr     set_penmode_xor

        ;; If N in 0..11, draw N
loop:   lda     step            ; draw the Nth
        cmp     #kMaxAnimationStep+1
        bcs     erase

        ;; Compute offset into rect table
        asl     a
        asl     a
        asl     a
        clc
        adc     #.sizeof(MGTK::Rect)-1
        tax

        ;; Copy rect to draw
        ldy     #.sizeof(MGTK::Rect)-1
:       lda     rect_table,x
        sta     tmp_rect,y
        dex
        dey
        bpl     :-

        jsr     frame_tmp_rect

        ;; If N in 2..13, erase N-2 (i.e. 0..11, 2 behind)
erase:  lda     step
        sec
        sbc     #2              ; erase the (N-2)th
        bmi     next

        ;; Compute offset into rect table
        asl     a               ; * 8 (size of Rect)
        asl     a
        asl     a
        clc
        adc     #.sizeof(MGTK::Rect)-1
        tax

        ;; Copy rect to erase
        ldy     #.sizeof(MGTK::Rect)-1
:       lda     rect_table,x
        sta     tmp_rect,y
        dex
        dey
        bpl     :-

        jsr     frame_tmp_rect

next:   inc     step
        lda     step
        cmp     #kMaxAnimationStep+3
        bne     loop
        rts

step:   .byte   0
.endproc

;;; ============================================================

.proc animate_window_close_impl

        rect_table := $800

        ;; Loop N = 11 to -2
        ;; If N in 0..11, draw N
        ;; If N in -2..9, erase N+2 (0..11, i.e. 2 behind)

        lda     #kMaxAnimationStep
        sta     step
        jsr     reset_main_grafport
        MGTK_RELAY_CALL MGTK::SetPattern, checkerboard_pattern
        jsr     set_penmode_xor

        ;; If N in 0..11, draw N
loop:   lda     step
        bmi     erase

        ;; Compute offset into rect table
        asl     a               ; * 8 (size of Rect)
        asl     a
        asl     a
        clc
        adc     #.sizeof(MGTK::Rect)-1
        tax

        ;; Copy rect to draw
        ldy     #.sizeof(MGTK::Rect)-1
:       lda     rect_table,x
        sta     tmp_rect,y
        dex
        dey
        bpl     :-

        jsr     frame_tmp_rect

        ;; If N in -2..9, erase N+2 (0..11, i.e. 2 behind)
erase:  lda     step
        clc
        adc     #2
        cmp     #kMaxAnimationStep+1
        bcs     next

        ;; Compute offset into rect table
        asl     a
        asl     a
        asl     a
        clc
        adc     #.sizeof(MGTK::Rect)-1
        tax

        ;; Copy rect to erase
        ldy     #.sizeof(MGTK::Rect)-1
:       lda     rect_table,x
        sta     tmp_rect,y
        dex
        dey
        bpl     :-

        jsr     frame_tmp_rect

next:   dec     step
        lda     step
        cmp     #AS_BYTE(-3)
        bne     loop
        rts

step:   .byte   0
.endproc

;;; ============================================================

.proc frame_tmp_rect
        MGTK_RELAY_CALL MGTK::FrameRect, tmp_rect
        rts
.endproc

;;; ============================================================
;;; Dynamically load parts of Desktop2

;;; Call load_dynamic_routine or restore_dynamic_routine
;;; with A set to routine number (0-8); routine is loaded
;;; from DeskTop2 file to target address. Returns with
;;; minus flag set on failure.

;;; Routines are:
;;;  0 = disk copy                - A$ 800,L$ 200
;;;  1 = format/erase disk        - A$ 800,L$1400 call w/ A = 4 = format, A = 5 = erase
;;;  2 = selector actions (all)   - A$9000,L$1000
;;;  3 = common file dialog       - A$5000,L$2000
;;;  4 = part of copy file        - A$7000,L$ 800
;;;  5 = part of delete file      - A$7000,L$ 800
;;;  6 = selector add/edit        - L$7000,L$ 800
;;;  7 = restore 1                - A$5000,L$2800 (restore $5000...$77FF)
;;;  8 = restore 2                - A$9000,L$1000 (restore $9000...$9FFF)
;;;
;;; Routines 2-6 need appropriate "restore routines" applied when complete.

.proc load_dynamic_routine_impl

kNumOverlays = 9

pos_table:
        .dword  $00012FE0,$000160E0,$000174E0,$000184E0,$0001A4E0
        .dword  $0001ACE0,$0001B4E0,$0000B780,$0000F780
        ASSERT_RECORD_TABLE_SIZE pos_table, kNumOverlays, 4

len_table:
        .word   $0200,$1400,$1000,$2000,$0800,$0800,$0800,$2800,$1000
        ASSERT_RECORD_TABLE_SIZE len_table, kNumOverlays, 2

addr_table:
        .addr   $0800,$0800,$9000,$5000,$7000,$7000,$7000,$5000,$9000
        ASSERT_ADDRESS_TABLE_SIZE addr_table, kNumOverlays

        DEFINE_OPEN_PARAMS open_params, str_desktop2, $1C00

str_desktop2:
        PASCAL_STRING "DeskTop2"

        DEFINE_SET_MARK_PARAMS set_mark_params, 0

        DEFINE_READ_PARAMS read_params, 0, 0
        DEFINE_CLOSE_PARAMS close_params

restore_flag:
        .byte   0

        ;; Called with routine # in A

load:   pha                     ; entry point with bit clear
        copy    #0, restore_flag
        beq     :+              ; always

restore:
        pha
        copy    #$80, restore_flag ; entry point with bit set

:       pla
        asl     a               ; y = A * 2 (to index into word table)
        tay
        asl     a               ; x = A * 4 (to index into dword table)
        tax

        lda     pos_table,x
        sta     set_mark_params::position
        lda     pos_table+1,x
        sta     set_mark_params::position+1
        lda     pos_table+2,x
        sta     set_mark_params::position+2

        copy16  len_table,y, read_params::request_count
        copy16  addr_table,y, read_params::data_buffer

open:   MLI_RELAY_CALL OPEN, open_params
        beq     :+

        lda     #kWarningMsgInsertSystemDisk
        ora     restore_flag    ; high bit set = no cancel
        jsr     warning_dialog_proc_num
        beq     open
        return  #$FF            ; failed

:       lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num
        MLI_RELAY_CALL SET_MARK, set_mark_params
        MLI_RELAY_CALL READ, read_params
        MLI_RELAY_CALL CLOSE, close_params
        rts

.endproc
        load_dynamic_routine := load_dynamic_routine_impl::load
        restore_dynamic_routine := load_dynamic_routine_impl::restore

;;; ============================================================

.proc show_clock
        lda     MACHID
        and     #1              ; bit 0 = clock card
        bne     :+
        rts

:       MLI_RELAY_CALL GET_TIME

        ;; Assumes call from main loop, where main_grafport is initialized.
        MGTK_RELAY_CALL MGTK::SetTextBG, aux::textbg_white
        MGTK_RELAY_CALL MGTK::MoveTo, pos_clock

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
        MGTK_RELAY_CALL MGTK::DrawText, dow_str_params

        ;; --------------------------------------------------
        ;; Time

        ldax    #parsed_date
        jsr     make_time_string

        addr_call draw_text1, str_time
        addr_jump draw_text1, str_4_spaces ; in case it got shorter
.endproc

;;; ============================================================

;;; Populate str_time with time. Uses clock_24hours flag in settings.
;;; Inputs: A,X = ParsedDateTime
;;; Outputs: str_time is populated
.proc make_time_string
        parsed_ptr := $06

        stax    parsed_ptr
        ldy     #ParsedDateTime::hour
        lda     (parsed_ptr),y
        sta     hour
        ldy     #ParsedDateTime::minute
        lda     (parsed_ptr),y
        sta     min

        ldy     #0              ; Index into time string

        ;; Hours
        lda     hour

        ;; 24->12 hour clock?
        bit     SETTINGS + DeskTopSettings::clock_24hours
        bmi     skip

        cmp     #12
        bcc     :+
        sec
        sbc     #12             ; 12...23 -> 0...11
:       cmp     #0
        bne     :+
        lda     #12             ; 0 -> 12
:

skip:   jsr     split
        pha
        txa                     ; tens (if > 0)
        bit     SETTINGS + DeskTopSettings::clock_24hours
        bmi     :+
        cmp     #0              ; if 12-hour clock && 0, skip
        beq     ones
:       ora     #'0'
        iny
        sta     str_time,y
ones:   pla                     ; ones
        ora     #'0'
        iny
        sta     str_time,y

        ;; Separator
        lda     #':'
        iny
        sta     str_time,y

        ;; Minutes
        lda     min
        jsr     split
        pha
        txa                     ; tens
        ora     #'0'
        iny
        sta     str_time,y
        pla                     ; ones
        ora     #'0'
        iny
        sta     str_time,y

        ;; Space
        lda     #' '
        iny
        sta     str_time,y

        bit     SETTINGS + DeskTopSettings::clock_24hours
        bmi     done

        lda     hour
        cmp     #12
        bcs     :+
        lda     #'A'
        bne     store             ; always
:       lda     #'P'
store:  iny
        sta     str_time,y
        lda     #'M'
        iny
        sta     str_time,y

done:   sty     str_time
        rts

hour:   .byte   0
min:    .byte   0

;;; Input: A = number
;;; Output: X = tens, A = ones
.proc split
        ldx     #0

loop:   cmp     #10
        bcc     done
        sec
        sbc     #10
        inx
        bne     loop            ; always

done:   rts
.endproc

.endproc

;;; ============================================================

;;; Day of the Week calculation (valid 1900-03-01 to 2155-12-31)
;;; c/o http://6502.org/source/misc/dow.htm
;;; Inputs: Y = year (0=1900), X = month (1=Jan), A = day (1...31)
;;; Output: A = weekday (0=Sunday)
.proc day_of_week
        tmp := $06

        cpx     #3              ; Year starts in March to bypass
        bcs     :+              ; leap year problem
        dey                     ; If Jan or Feb, decrement year
:       eor     #$7F            ; Invert A so carry works right
        cpy     #200            ; Carry will be 1 if 22nd century
        adc     month_offset_table-1,X ; A is now day+month offset
        sta     tmp
        tya                     ; Get the year
        jsr     mod7            ; Do a modulo to prevent overflow
        sbc     tmp             ; Combine with day+month
        sta     tmp
        tya                     ; Get the year again
        lsr                     ; Divide it by 4
        lsr
        clc                     ; Add it to y+m+d and fall through
        adc     tmp

mod7:   adc     #7              ; Returns (A+3) modulo 7
        bcc     mod7            ; for A in 0..255
        rts
.endproc

;;; ============================================================

.proc set_color_mode
        ;; AppleColor Card - Mode 2 (Color 140x192)
        sta     SET80VID
        lda     AN3_OFF
        lda     AN3_ON
        lda     AN3_OFF
        lda     AN3_ON
        lda     AN3_OFF

        ;; IIgs?
        jsr     test_iigs
        bcc     iigs

        ;; Le Chat Mauve - COL140 mode
        ;; (AN3 off, HR1 off, HR2 off, HR3 off)
        ;; Skip on IIgs since emulators (KEGS/GSport/GSplus) crash.
        sta     HR2_OFF
        sta     HR3_OFF
        bcs     done

        ;; Apple IIgs - DHR Color
iigs:   lda     NEWVIDEO
        and     #<~(1<<5)        ; Color
        sta     NEWVIDEO

done:   rts
.endproc

.proc set_mono_mode
        ;; AppleColor Card - Mode 1 (Monochrome 560x192)
        sta     CLR80VID
        lda     AN3_OFF
        lda     AN3_ON
        lda     AN3_OFF
        lda     AN3_ON
        sta     SET80VID
        lda     AN3_OFF

        ;; IIgs?
        jsr     test_iigs
        bcc     iigs

        ;; Le Chat Mauve - BW560 mode
        ;; (AN3 off, HR1 off, HR2 on, HR3 on)
        ;; Skip on IIgs since emulators (KEGS/GSport/GSplus) crash.
        sta     HR2_ON
        sta     HR3_ON
        bcs     done

        ;; Apple IIgs - DHR B&W
iigs:   lda     NEWVIDEO
        ora     #(1<<5)         ; B&W
        sta     NEWVIDEO

done:   rts
.endproc

;;; Returns with carry clear if IIgs, set otherwise.
.proc test_iigs
        lda     ROMIN2
        sec
        jsr     IDROUTINE
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

;;; On IIgs, force monochrome mode. No-op otherwise.
.proc force_iigs_mono
        jsr     test_iigs
        bcs     :+

        lda     NEWVIDEO
        ora     #(1<<5)         ; B&W
        sta     NEWVIDEO

:       rts
.endproc

;;; ============================================================
;;; Operations performed on selection
;;;
;;; These operate on the entire selection recursively, e.g.
;;; computing size, deleting, copying, etc., and share common
;;; logic.

.enum PromptResult
        ok      = 0
        cancel  = 1
        yes     = 2
        no      = 3
        all     = 4
.endenum

;;; ============================================================

jt_drop:        jmp     do_drop
jt_get_info:    jmp     do_get_info ; cmd_get_info
jt_lock:        jmp     do_lock ; cmd_lock
jt_unlock:      jmp     do_unlock ; cmd_unlock
jt_rename_icon: jmp     do_rename_icon ; cmd_rename_icon
jt_eject:       jmp     do_eject ; cmd_eject ???
jt_copy_file:   jmp     do_copy_file ; cmd_copy_file
jt_delete_file: jmp     do_delete_file ; cmd_delete_file
jt_run:         jmp     do_run  ; cmd_selector_action / Run
jt_get_size:    jmp     do_get_size ; cmd_get_size


;;; --------------------------------------------------

.enum DeleteDialogLifecycle
        open            = 0
        populate        = 1
        confirm         = 2     ; confirmation before deleting
        show            = 3
        locked          = 4     ; confirm deletion of locked file
        close           = 5
        trash           = 6     ; open, but from trash path ???
.endenum

;;; --------------------------------------------------

.proc operations

do_copy_file:
        copy    #0, operation_flags ; copy/delete
        tsx
        stx     stack_stash
        jsr     prep_callbacks_for_size_or_count
        jsr     do_copy_dialog_phase
        jsr     size_or_count_process_selected_file
        jsr     prep_callbacks_for_copy

do_run2:
        copy    #$FF, LE05B
        copy    #0, delete_skip_decrement_flag
        jsr     copy_file_for_run
        jsr     done_dialog_phase1

.proc finish_operation
        jsr     redraw_windows_and_desktop
        return  #0
.endproc

do_delete_file:
        copy    #0, operation_flags ; copy/delete
        tsx
        stx     stack_stash
        jsr     prep_callbacks_for_size_or_count
        lda     #DeleteDialogLifecycle::open
        jsr     do_delete_dialog_phase
        jsr     size_or_count_process_selected_file
        jsr     done_dialog_phase2
        jsr     prep_callbacks_for_delete
        jsr     delete_process_selected_file
        jsr     done_dialog_phase1
       jmp     finish_operation

do_run:
        copy    #$80, run_flag
        copy    #%11000000, operation_flags ; get size
        tsx
        stx     stack_stash
        jsr     prep_callbacks_for_size_or_count
        jsr     do_download_dialog_phase
        jsr     size_or_count_process_selected_file
        jsr     prep_callbacks_for_download
        jmp     do_run2

;;; --------------------------------------------------
;;; Lock

do_lock:
        jsr     L8FDD
        jmp     finish_operation

do_unlock:
        jsr     L8FE1
        jmp     finish_operation

.proc get_icon_entry_win_type
        asl     a
        tay
        copy16  icon_entry_address_table,y, $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        rts
.endproc

;;; --------------------------------------------------

.proc do_get_size
        copy    #0, run_flag
        copy    #%11000000, operation_flags ; get size
        jmp     L8FEB
.endproc

.proc do_drop
        lda     drag_drop_params::result
        cmp     #kTrashIconNum
        bne     :+
        lda     #$80
        bne     set           ; always
:       lda     #$00
set:    sta     delete_flag
        copy    #0, operation_flags ; copy/delete
        jmp     L8FEB
.endproc

        ;; common for lock/unlock
L8FDD:  lda     #$00            ; unlock
        beq     :+
L8FE1:  lda     #$80            ; lock
:       sta     unlock_flag
        copy    #%10000000, operation_flags ; lock/unlock

L8FEB:  tsx
        stx     stack_stash
        copy    #0, delete_skip_decrement_flag
        jsr     reset_main_grafport
        lda     operation_flags
        beq     :+              ; copy/delete
        jmp     begin_operation

        ;; Copy or delete
:       bit     delete_flag
        bpl     compute_target_prefix ; copy

        ;; Delete - is it a volume?
        lda     selected_window_index
        beq     :+
        jmp     begin_operation

        ;; Yes - eject it!
:       pla
        pla
        jmp     JT_EJECT

;;; --------------------------------------------------
;;; For drop onto window/icon, compute target prefix.

        ;; Is drop on a window or an icon?
        ;; hi bit clear = target is an icon
        ;; hi bit set = target is a window; get window number
compute_target_prefix:
        lda     drag_drop_params::result
        bpl     check_icon_drop_type

        ;; Drop is on a window
        and     #%01111111      ; get window id
        asl     a
        tax
        copy16  window_path_addr_table,x, $08
        copy16  #empty_string, $06
        jsr     join_paths
        dec     path_buf3       ; remove trailing '/'
        jmp     L9076

        ;; Drop is on an icon.
        ;; Is drop on a volume or a file?
        ;; (lower 4 bits are containing window id)
check_icon_drop_type:
        jsr     get_icon_entry_win_type
        and     #kIconEntryWinIdMask
        beq     drop_on_volume_icon ; 0 = desktop (so, volume icon)

        ;; Drop is on a file icon.
        asl     a
        tax
        copy16  window_path_addr_table,x, $08
        lda     drag_drop_params::result
        jsr     icon_entry_name_lookup
        jsr     join_paths
        jmp     L9076

        ;; Drop is on a volume icon.
        ;;
drop_on_volume_icon:
        lda     drag_drop_params::result
        jsr     icon_entry_name_lookup

        ;; Prefix name with '/'
        copy    #'/', path_buf3+1

        ;; Copy to path_buf3
        ldy     #0
        lda     ($06),y
        sta     @compare
:       iny
        lda     ($06),y
        sta     path_buf3+1,y
        @compare := *+1
        cpy     #0              ; self-modified
        bne     :-
        iny
        sty     path_buf3

L9076:  ldy     path_buf3
:       copy    path_buf3,y, path_buf4,y
        dey
        bpl     :-
        ;; fall through

;;; --------------------------------------------------
;;; Start the actual operation

.proc begin_operation
        copy    #0, L97E4

        jsr     prep_callbacks_for_size_or_count
        bit     operation_flags
        bvs     @size
        bmi     @lock
        bit     delete_flag
        bmi     @trash

        ;; Copy or Move - compare src/dst paths (etc)
        jsr     get_window_path_ptr
        jsr     check_move_or_copy
        sta     move_flag
        jsr     do_copy_dialog_phase
        jmp     iterate_selection

@trash: lda     #DeleteDialogLifecycle::trash
        jsr     do_delete_dialog_phase
        jmp     iterate_selection

@lock:  jsr     do_lock_dialog_phase
        jmp     iterate_selection

@size:  jsr     do_get_size_dialog_phase
        jmp     iterate_selection

;;; Perform operation

L90BA:  bit     operation_flags
        bvs     @size
        bmi     @lock
        bit     delete_flag
        bmi     @trash
        jsr     prep_callbacks_for_copy
        jmp     iterate_selection

@trash: jsr     prep_callbacks_for_delete
        jmp     iterate_selection

@lock:  jsr     prep_callbacks_for_lock
        jmp     iterate_selection

@size:  jsr     get_size_rts2           ; no-op ???
        jmp     iterate_selection

iterate_selection:
        lda     selected_icon_count
        bne     :+
        jmp     finish

:       ldx     #0
        stx     icon_count

loop:   jsr     get_window_path_ptr
        ldx     icon_count
        lda     selected_icon_list,x
        cmp     #kTrashIconNum
        beq     next_icon
        jsr     icon_entry_name_lookup
        jsr     join_paths

        lda     L97E4
        beq     L913D
        bit     operation_flags
        bmi     @lock_or_size
        bit     delete_flag
        bmi     :+

        jsr     copy_process_selected_file
        jmp     next_icon

:       jsr     delete_process_selected_file
        jmp     next_icon

@lock_or_size:
        bvs     @size           ; size?
        jsr     lock_process_selected_file
        jmp     next_icon

@size:  jsr     size_or_count_process_selected_file
        jmp     next_icon

L913D:  jsr     size_or_count_process_selected_file

next_icon:
        inc     icon_count
        ldx     icon_count
        cpx     selected_icon_count
        bne     loop

        lda     L97E4
        bne     finish
        inc     L97E4
        bit     operation_flags
        bmi     @lock_or_size
        bit     delete_flag
        bpl     not_trash

@lock_or_size:
        jsr     done_dialog_phase2
        bit     operation_flags
        bvs     finish
not_trash:
        jmp     L90BA

finish: jsr     done_dialog_phase1
        return  #0

icon_count:
        .byte   0
.endproc

empty_string:
        .byte   0
.endproc ; operations
        do_delete_file := operations::do_delete_file
        do_run := operations::do_run
        do_copy_file := operations::do_copy_file
        do_lock := operations::do_lock
        do_unlock := operations::do_unlock
        do_get_size := operations::do_get_size
        do_drop := operations::do_drop

;;; ============================================================

done_dialog_phase0:
        dialog_phase0_callback := *+1
        jmp     dummy0000

done_dialog_phase1:
        dialog_phase1_callback := *+1
        jmp     dummy0000

done_dialog_phase2:
        dialog_phase2_callback := *+1
        jmp     dummy0000

done_dialog_phase3:
        dialog_phase3_callback := *+1
        jmp     dummy0000

stack_stash:
        .byte   0

        ;; $80 = lock/unlock
        ;; $C0 = get size/run (easily probed with oVerflow flag)
        ;; $00 = copy/delete
operation_flags:
        .byte   0

        ;; high bit set = delete, clear = copy
delete_flag:
        .byte   0

        ;; high bit set = move, clear = copy
move_flag:
        .byte   0

        ;; high bit set = unlock, clear = lock
unlock_flag:
        .byte   0

        ;; high bit set = from Selector > Run command (download???)
        ;; high bit clear = Get Size
run_flag:
        .byte   0

all_flag:
        .byte   0

;;; ============================================================
;;; For icon index in A, put pointer to name in $6

.proc icon_entry_name_lookup
        asl     a
        tay
        add16   icon_entry_address_table,y, #IconEntry::name, $06
        rts
.endproc

;;; ============================================================
;;; Concatenate paths.
;;; Inputs: Base path in $08, second path in $06
;;; Output: path_buf3

.proc join_paths
        str1 := $8
        str2 := $6
        buf  := path_buf3

        ldx     #0
        ldy     #0
        lda     (str1),y
        beq     do_str2

        ;; Copy $8 (str1)
        sta     @len
:       iny
        inx
        lda     (str1),y
        sta     buf,x
        @len := *+1
        cpy     #0              ; self-modified
        bne     :-

do_str2:
        ;; Add path separator
        inx
        lda     #'/'
        sta     buf,x

        ;; Append $6 (str2)
        ldy     #0
        lda     (str2),y
        beq     done
        sta     @len
:       iny
        inx
        lda     (str2),y
        sta     buf,x
        @len := *+1
        cpy     #0              ; self-modified
        bne     :-

done:   stx     buf
        rts
.endproc

;;; ============================================================
;;; Points $08 to path of window with selection ($0000 if desktop)

.proc get_window_path_ptr
        ptr := $08

        lda     selected_window_index
        jsr     get_window_path
        stax    ptr
        rts
.endproc

;;; ============================================================

.proc do_eject
        lda     selected_icon_count
        bne     :+
        rts
:       ldx     selected_icon_count
        stx     $800
        dex
:       lda     selected_icon_list,x
        sta     $0801,x
        dex
        bpl     :-

        jsr     JT_CLEAR_SELECTION
        ldx     #0
        stx     index
loop:   ldx     index
        lda     $0801,x
        cmp     #$01
        beq     :+
        jsr     smartport_eject
:       inc     index
        ldx     index
        cpx     $800
        bne     loop
        rts

index:  .byte   0
.endproc

;;; ============================================================

.proc smartport_eject
        ptr := $6

        sta     @compare
        ldy     #0

:       lda     device_to_icon_map,y

        @compare := *+1
        cmp     #0

        beq     found
        cpy     DEVCNT
        beq     exit
        iny
        bne     :-
exit:   rts

found:  lda     DEVLST,y        ;
        sta     unit_number

        ;; Compute SmartPort dispatch address
        smartport_addr := $0A
        jsr     find_smartport_dispatch_address
        bne     exit            ; not SP
        stx     control_unit_number

        ;; Execute SmartPort call
        jsr     smartport_call
        .byte   $04             ; $04 = CONTROL
        .addr   control_params
        rts

smartport_call:
        jmp     (smartport_addr)

.params control_params
param_count:    .byte   3
unit_number:    .byte   0
control_list:   .addr   list
control_code:   .byte   4       ; Eject disk
.endparams
        control_unit_number := control_params::unit_number
list:   .word   0               ; 0 items in list
unit_number:
        .byte   0
.endproc

;;; ============================================================
;;; "Get Info" dialog state and logic
;;; ============================================================

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params5, $220

        DEFINE_READ_BLOCK_PARAMS block_params, $800, $A

.params get_info_dialog_params
state:  .byte   0
addr:   .addr   0               ; e.g. string address
index:  .byte   0               ; index in selected icon list
.endparams

.enum GetInfoDialogState
        name    = 1
        locked  = 2             ; locked (file)/protected (volume)
        size    = 3             ; blocks (file)/size (volume)
        created = 4
        modified = 5
        type    = 6             ; blank for vol, but signifies end-of-data

        prepare_file = $80      ; +2 if multiple
        prepare_vol  = $81      ; +2 if multiple
.endenum

;;; ============================================================
;;; Look up device driver address.
;;; Input: A = unit number
;;; Output: $0A/$0B ptr to driver; Z set if $CnXX

.proc device_driver_address
        slot_addr := $0A

        and     #%11110000      ; mask off drive/slot
        lsr                     ; 0DSSS000
        lsr                     ; 00DSSS00
        lsr                     ; 000DSSS0
        tax                     ; = slot * 2 + (drive == 2 ? 0x10 + 0x00)

        lda     DEVADR,x
        sta     slot_addr
        lda     DEVADR+1,x
        sta     slot_addr+1

        and     #$F0            ; is it $Cn ?
        cmp     #$C0            ; leave Z flag set if so
        rts
.endproc

;;; ============================================================
;;; Look up SmartPort dispatch address.
;;; Input: A = unit number
;;; Output: Z=1 if SP, $0A/$0B dispatch address, X = SP unit num
;;;         Z=0 if not SP

.proc find_smartport_dispatch_address
        sp_addr := $0A

        sta     unit_number     ; DSSSnnnn

        ;; Get device driver address
        jsr     device_driver_address
        bne     exit            ; RAM-based driver

        ;; Find actual address
        copy    #0, sp_addr     ; point at $Cn00 for firmware lookups

        ldy     #$07            ; SmartPort signature byte ($Cn07)
        lda     (sp_addr),y     ; $00 = SmartPort
        bne     exit

        ldy     #$FB            ; SmartPort ID Type Byte ($CnFB)
        lda     (sp_addr),y
        and     #$7F            ; bit 7 = is Extended
        bne     exit

        ;; Locate SmartPort entry point: $Cn00 + ($CnFF) + 3
        ldy     #$FF
        lda     (sp_addr),y
        clc
        adc     #3
        sta     sp_addr

        ;; Figure out SmartPort control unit number in X
        ldx     #1              ; start with unit 1
        bit     unit_number     ; high bit is D
        bpl     :+
        inx                     ; X = 1 or 2 (for Drive 1 or 2)

:       lda     unit_number
        and     #%01110000      ; 0SSSnnnn
        lsr
        lsr
        lsr
        lsr
        sta     mapped_slot     ; 00000SSS

        lda     sp_addr+1       ; $Cn
        and     #%00001111      ; $0n
        cmp     mapped_slot     ; equal = not remapped
        beq     :+
        inx                     ; now X = 3 or 4
        inx

:       lda     #0              ; exit with Z set on success
exit:   rts

unit_number:
        .byte   0
mapped_slot:                    ; from unit_number, not driver
        .byte   0
.endproc

;;; ============================================================
;;; Get Info

.proc do_get_info
        path_buf := $220
        ptr := $6

        lda     selected_icon_count
        bne     :+
        rts

:       copy    #0, get_info_dialog_params::index
        jsr     reset_main_grafport
loop:   ldx     get_info_dialog_params::index
        cpx     selected_icon_count
        bne     :+
        jmp     done

:       lda     selected_window_index
        beq     vol_icon

        ;; File icon
        asl     a
        tax
        copy16  window_path_addr_table,x, $08
        ldx     get_info_dialog_params::index
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        jsr     join_paths

        ldy     path_buf3       ; Copy name to path_buf
:       copy    path_buf3,y, path_buf,y
        dey
        bpl     :-
        jmp     common

        ;; Volume icon
vol_icon:
        ldx     get_info_dialog_params::index
        lda     selected_icon_list,x
        cmp     #kTrashIconNum
        bne     :+
        jmp     next
:       jsr     icon_entry_name_lookup

        ldy     #0
        lda     (ptr),y
        tay
        sta     path_buf
        inc     path_buf        ; for leading '/'
:       lda     (ptr),y
        sta     path_buf+1,y    ; leave room for leading '/'
        dey
        bne     :-
        copy    #'/', path_buf+1

        ;; Try to get file info
common: MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params5
        beq     :+
        jsr     show_error_alert
        beq     common
:
        lda     selected_window_index
        beq     vol_icon2

        ;; File icon
        copy    #GetInfoDialogState::prepare_file, get_info_dialog_params::state
        lda     get_info_dialog_params::index
        clc
        adc     #1
        cmp     selected_icon_count
        beq     :+
        inc     get_info_dialog_params::state
        inc     get_info_dialog_params::state
:       jsr     run_get_info_dialog_proc
        jmp     common2

vol_icon2:
        copy    #GetInfoDialogState::prepare_vol, get_info_dialog_params::state
        lda     get_info_dialog_params::index
        clc
        adc     #1
        cmp     selected_icon_count
        beq     :+
        inc     get_info_dialog_params::state
        inc     get_info_dialog_params::state
:       jsr     run_get_info_dialog_proc
        copy    #0, write_protected_flag
        ldx     get_info_dialog_params::index
        lda     selected_icon_list,x

        ;; Map icon to unit number
        ldy     #15
:       cmp     device_to_icon_map,y
        beq     :+
        dey
        bpl     :-
        jmp     common2
:       lda     DEVLST,y
        sta     block_params::unit_num
        MLI_RELAY_CALL READ_BLOCK, block_params
        bne     common2
        MLI_RELAY_CALL WRITE_BLOCK, block_params
        cmp     #ERR_WRITE_PROTECTED
        bne     common2
        copy    #$80, write_protected_flag

common2:
        ;; --------------------------------------------------
        ;; Name
        ldx     get_info_dialog_params::index
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup

        ;; Prepend space, like the other fields
        ;; TODO: Update all the other strings?
        ldy     #0
        lda     (ptr),y
        sta     text_buffer2::length
        inc     text_buffer2::length ; for leading space
        tay
:       copy    (ptr),y, text_buffer2::data,y
        dey
        bne     :-
        copy    #' ', text_buffer2::data

        copy    #GetInfoDialogState::name, get_info_dialog_params::state
        copy16  #text_buffer2::length, get_info_dialog_params::addr
        jsr     run_get_info_dialog_proc

        ;; --------------------------------------------------
        ;; Locked/Protected
        copy    #GetInfoDialogState::locked, get_info_dialog_params::state
        lda     selected_window_index
        bne     is_file

        bit     write_protected_flag ; Volume
        bmi     is_protected
        bpl     not_protected

is_file:
        lda     get_file_info_params5::access ; File
        and     #ACCESS_DEFAULT
        cmp     #ACCESS_DEFAULT
        beq     not_protected

is_protected:
        copy16  #aux::str_yes_label, get_info_dialog_params::addr
        bne     show_protected           ; always
not_protected:
        copy16  #aux::str_no_label, get_info_dialog_params::addr
show_protected:
        jsr     run_get_info_dialog_proc

        ;; --------------------------------------------------
        ;; Size/Blocks
        copy    #GetInfoDialogState::size, get_info_dialog_params::state

        ;; Compose " 12345 Blocks" or " 12345 / 67890 Blocks" string
        buf := $220
        copy    #0, buf

        lda     selected_window_index ; volume?
        bne     do_suffix                 ; nope

        ;; ProDOS TRM 4.4.5:
        ;; "When file information about a volume directory is requested, the
        ;; total number of blocks on the volume is returned in the aux_type
        ;; field and the total blocks for all files is returned in blocks_used.

        lda     get_file_info_params5::aux_type
        sec
        sbc     get_file_info_params5::blocks_used
        pha
        lda     get_file_info_params5::aux_type+1
        sbc     get_file_info_params5::blocks_used+1
        tax
        pla
        jsr     JT_SIZE_STRING

        ;; text_buffer2 now has " 12345 Blocks" (free space)

        ;; Copy number and leading/trailing space into buf
        ldx     buf
        ldy     #0
:       inx
        lda     text_buffer2::data,y
        cmp     #'B'            ; stop at 'B' in "Blocks"
        beq     slash
        sta     buf,x
        iny
        cpy     text_buffer2::length
        bne     :-

        ;; Append '/' to buf
slash:  lda     #'/'
        sta     buf,x
        stx     buf

do_suffix:
        lda     selected_window_index ; volume?
        bne     :+                    ; nope

        ;; Load up the total volume size...
        ldax    get_file_info_params5::aux_type
        jmp     compute_suffix

        ;; Load up the file size
:       ldax    get_file_info_params5::blocks_used

        ;; Compute " 12345 Blocks" (either result or suffix)
compute_suffix:
        jsr     JT_SIZE_STRING

        ;; Append latest to buffer
        ldx     buf
        ldy     #1
:       inx
        lda     text_buffer2::data-1,y
        sta     buf,x
        cpy     text_buffer2::length
        beq     :+
        iny
        bne     :-
:       stx     buf

        ;; TODO: Compose directly into path_buf4.
        ldx     buf
:       lda     buf,x
        sta     path_buf4,x
        dex
        bpl     :-

        copy16  #path_buf4, get_info_dialog_params::addr
        jsr     run_get_info_dialog_proc

        ;; --------------------------------------------------
        ;; Created date
        copy    #GetInfoDialogState::created, get_info_dialog_params::state
        COPY_STRUCT DateTime, get_file_info_params5::create_date, datetime_for_conversion
        jsr     JT_DATE_STRING
        copy16  #text_buffer2::length, get_info_dialog_params::addr
        jsr     run_get_info_dialog_proc

        ;; --------------------------------------------------
        ;; Modified date
        copy    #GetInfoDialogState::modified, get_info_dialog_params::state
        COPY_STRUCT DateTime, get_file_info_params5::mod_date, datetime_for_conversion
        jsr     JT_DATE_STRING
        copy16  #text_buffer2::length, get_info_dialog_params::addr
        jsr     run_get_info_dialog_proc


        ;; --------------------------------------------------
        ;; Type
        copy    #GetInfoDialogState::type, get_info_dialog_params::state
        lda     selected_window_index
        bne     :+

        ;; Volume
        COPY_STRING str_vol, text_buffer2::length
        bmi     show_type           ; always

        ;; File
:       lda     get_file_info_params5::file_type
        jsr     JT_FILE_TYPE_STRING
        COPY_STRING str_file_type, text_buffer2::length
        ldax    get_file_info_params5::aux_type
        jsr     append_aux_type

show_type:
        copy16  #text_buffer2::length, get_info_dialog_params::addr
        jsr     run_get_info_dialog_proc
        bne     done

next:   inc     get_info_dialog_params::index
        jmp     loop

done:   copy    #0, path_buf4
        rts

write_protected_flag:
        .byte   0

str_vol:
        PASCAL_STRING " Volume"

.proc run_get_info_dialog_proc
        yax_call invoke_dialog_proc, kIndexGetInfoDialog, get_info_dialog_params
        rts
.endproc
.endproc

;;; ============================================================

.enum RenameDialogState
        open  = $00
        run   = $80
        close = $40
.endenum

.proc do_rename_icon_impl

        src_path_buf := $220
        old_name_buf := $1F00

        DEFINE_RENAME_PARAMS rename_params, src_path_buf, dst_path_buf

.params rename_dialog_params
state:  .byte   0
addr:   .addr   old_name_buf
.endparams

start:
        copy    #0, index

        ;; Loop over all selected icons
loop:   lda     index
        cmp     selected_icon_count
        bne     :+
        return  #0

:       ldx     index
        lda     selected_icon_list,x
        cmp     #kTrashIconNum  ; Skip trash
        bne     :+
        inc     index
        jmp     loop
:
        ;; File or Volume?
        lda     selected_window_index
        beq     is_vol          ; no window, selection is volumes

        ;; File - compose full path
        asl     a
        tax
        copy16  window_path_addr_table,x, $08
        ldx     index
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        jsr     join_paths

        ldy     path_buf3       ; copy into src_path_buf
:       copy    path_buf3,y, src_path_buf,y
        dey
        bpl     :-

        jmp     common          ; proceed with rename

        icon_name_ptr := $06

        ;; Volume - compose full path (add '/' prefix)
is_vol: ldx     index
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup

        ldy     #0              ; copy into src_path_buf
        lda     (icon_name_ptr),y
        tay
        sta     src_path_buf
        inc     src_path_buf    ; for leading '/'
:       lda     (icon_name_ptr),y
        sta     src_path_buf+1,y ; leave room for leading '/'
        dey
        bne     :-
        copy    #'/', src_path_buf+1

common:
        ldx     index
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup

        ptr := $06

        ldy     #0              ; copy name again
        lda     (ptr),y         ; to old_name_buf
        tay
:       lda     (ptr),y
        sta     old_name_buf,y
        dey
        bpl     :-

        ;; Open the dialog
        lda     #RenameDialogState::open
        jsr     run_dialog_proc

        ;; Run the dialog
retry:  lda     #RenameDialogState::run
        jsr     run_dialog_proc
        beq     L962F

        ;; Failure
fail:   return  #$FF

        ;; Success, new name in Y,X
        win_path_ptr := $06
        new_name_ptr := $08

L962F:  sty     new_name_ptr
        sty     new_name_addr
        stx     new_name_ptr+1
        stx     new_name_addr+1

        ;; File or Volume?
        lda     selected_window_index
        beq     is_vol2
        asl     a
        tax
        copy16  window_path_addr_table,x, win_path_ptr
        jmp     common2

is_vol2:
        copy16  #str_empty, win_path_ptr

common2:
        ;; Copy window path as prefix
        ldy     #0
        lda     (win_path_ptr),y
        tay
:       lda     (win_path_ptr),y
        sta     dst_path_buf,y
        dey
        bpl     :-

        ;; Append '/'
        inc     dst_path_buf
        ldx     dst_path_buf
        lda     #'/'
        sta     dst_path_buf,x

        ;; Append new filename
        ldy     #0
        lda     (new_name_ptr),y
        sta     len
:       inx
        iny
        lda     (new_name_ptr),y
        sta     dst_path_buf,x
        cpy     len
        bne     :-
        stx     dst_path_buf

        ;; Try to rename
        MLI_RELAY_CALL RENAME, rename_params
        beq     finish

        ;; Failed, maybe retry
        jsr     JT_SHOW_ALERT0
        bne     :+
        jmp     retry           ; TODO: Retry isn't offered???
:       lda     #RenameDialogState::close
        jsr     run_dialog_proc
        jmp     fail

        ;; Completed - tear down the dialog...
finish: lda     #RenameDialogState::close
        jsr     run_dialog_proc

        ;; Replace the icon name
        ldx     index
        lda     selected_icon_list,x
        sta     icon_param2
        ITK_RELAY_CALL IconTK::EraseIcon, icon_param2 ; in case name is shorter
        copy16  new_name_addr, new_name_ptr
        ldx     index
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup

        ;; Copy new string in
        ldy     #0
        lda     (new_name_ptr),y
        tay
:       lda     (new_name_ptr),y
        sta     (icon_name_ptr),y
        dey
        bpl     :-

        ;; Totally done - advance to next selected icon
        inc     index
        jmp     loop

run_dialog_proc:
        sta     rename_dialog_params
        yax_call invoke_dialog_proc, kIndexRenameDialog, rename_dialog_params
        rts

str_empty:
        PASCAL_STRING ""

index:  .byte   0               ; selected icon index

new_name_addr:
        .addr   0

len:    .byte   0
.endproc
        do_rename_icon := do_rename_icon_impl::start

;;; ============================================================

        src_path_buf := $220

        DEFINE_OPEN_PARAMS open_src_dir_params, src_path_buf, $800
        DEFINE_READ_PARAMS read_src_dir_header_params, pointers_buf, 4 ; dir header: skip block pointers
pointers_buf:  .res    4, 0

        DEFINE_CLOSE_PARAMS close_src_dir_params
        DEFINE_READ_PARAMS read_src_dir_entry_params, file_entry_buf, .sizeof(FileEntry)
        DEFINE_READ_PARAMS read_src_dir_skip5_params, skip5_buf, 5 ; ???
skip5_buf:  .res    5, 0

        kBufSize = $AC0

        DEFINE_CLOSE_PARAMS close_src_params
        DEFINE_CLOSE_PARAMS close_dst_params
        DEFINE_DESTROY_PARAMS destroy_params, src_path_buf
        DEFINE_OPEN_PARAMS open_src_params, src_path_buf, $0D00
        DEFINE_OPEN_PARAMS open_dst_params, dst_path_buf, $1100
        DEFINE_READ_PARAMS read_src_params, $1500, kBufSize
        DEFINE_WRITE_PARAMS write_dst_params, $1500, kBufSize
        DEFINE_CREATE_PARAMS create_params3, dst_path_buf, ACCESS_DEFAULT
        DEFINE_CREATE_PARAMS create_params2, dst_path_buf

        .byte   0,0

        DEFINE_GET_FILE_INFO_PARAMS src_file_info_params, src_path_buf
        DEFINE_GET_FILE_INFO_PARAMS dst_file_info_params, dst_path_buf

        DEFINE_SET_EOF_PARAMS set_eof_params, 0
        DEFINE_SET_MARK_PARAMS mark_src_params, 0
        DEFINE_SET_MARK_PARAMS mark_dst_params, 0
        DEFINE_ON_LINE_PARAMS on_line_params2,, $800


;;; ============================================================

file_entry_buf:  .res    .sizeof(FileEntry), 0

        ;; overlayed indirect jump table
        kOpJTAddrsSize = 6

op_jt_addrs:
op_jt_addr1:  .addr   copy_process_directory_entry     ; defaults are for copy
op_jt_addr2:  .addr   copy_pop_directory
op_jt_addr3:  .addr   do_nothing

do_nothing:   rts

L97E4:  .byte   $00


.proc push_entry_count
        ldx     entry_count_stack_index
        lda     entries_to_skip
        sta     entry_count_stack,x
        inx
        stx     entry_count_stack_index
        rts
.endproc

.proc pop_entry_count
        ldx     entry_count_stack_index
        dex
        lda     entry_count_stack,x
        sta     entries_to_skip
        stx     entry_count_stack_index
        rts
.endproc

.proc open_src_dir
        lda     #0
        sta     entries_read
        sta     entries_read_this_block

@retry: MLI_RELAY_CALL OPEN, open_src_dir_params
        beq     :+
        ldx     #kAlertOptionsTryAgainCancel
        jsr     JT_SHOW_ALERT
        beq     @retry
        jmp     close_files_cancel_dialog

:       lda     open_src_dir_params::ref_num
        sta     op_ref_num
        sta     read_src_dir_header_params::ref_num

@retry2:MLI_RELAY_CALL READ, read_src_dir_header_params
        beq     :+
        ldx     #kAlertOptionsTryAgainCancel
        jsr     JT_SHOW_ALERT
        beq     @retry2
        jmp     close_files_cancel_dialog

:       jmp     read_file_entry
.endproc

.proc close_src_dir
        lda     op_ref_num
        sta     close_src_dir_params::ref_num
@retry: MLI_RELAY_CALL CLOSE, close_src_dir_params
        beq     :+
        ldx     #kAlertOptionsTryAgainCancel
        jsr     JT_SHOW_ALERT
        beq     @retry
        jmp     close_files_cancel_dialog

:       rts
.endproc

.proc read_file_entry
        inc     entries_read
        lda     op_ref_num
        sta     read_src_dir_entry_params::ref_num
@retry: MLI_RELAY_CALL READ, read_src_dir_entry_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     eof
        ldx     #kAlertOptionsTryAgainCancel
        jsr     JT_SHOW_ALERT
        beq     @retry
        jmp     close_files_cancel_dialog

:       inc     entries_read_this_block
        lda     entries_read_this_block
        cmp     num_entries_per_block
        bcc     :+
        copy    #0, entries_read_this_block
        copy    op_ref_num, read_src_dir_skip5_params::ref_num
        MLI_RELAY_CALL READ, read_src_dir_skip5_params
:       return  #0

eof:    return  #$FF
.endproc

;;; ============================================================

.proc prep_to_open_dir
        lda     entries_read
        sta     entries_to_skip
        jsr     close_src_dir
        jsr     push_entry_count
        jsr     append_to_src_path
        jmp     open_src_dir
.endproc

;;; Given this tree with b,c,e selected:
;;;        b
;;;        c/
;;;           d/
;;;               e
;;;        f
;;; Visit call sequence:
;;;  * op_jt1 c
;;;  * op_jt1 c/d
;;;  * op_jt3 c/d
;;;  * op_jt2 c
;;;
;;; Visiting individual files is done via direct calls, not the
;;; overlayed jump table. Order is:
;;;
;;;  * call: b
;;;  * op_jt1 on c
;;;  * call: c/d
;;;  * op_jt1 on c/d
;;;  * call: c/d/e
;;;  * op_jt3 on c/d
;;;  * op_jt2 on c
;;;  * call: c
;;;  * call: f
;;;  (3x final calls ???)

.proc finish_dir
        jsr     close_src_dir
        jsr     op_jt3          ; third - called when exiting dir
        jsr     remove_src_path_segment
        jsr     pop_entry_count
        jsr     open_src_dir
        jsr     sub
        jmp     op_jt2          ; second - called when exited dir

sub:    lda     entries_read
        cmp     entries_to_skip
        beq     done
        jsr     read_file_entry
        jmp     sub
done:   rts
.endproc

.proc process_dir
        copy    #0, process_depth
        jsr     open_src_dir
loop:   jsr     read_file_entry
        bne     end_dir

        addr_call adjust_fileentry_case, file_entry_buf

        lda     file_entry_buf + FileEntry::storage_type_name_length
        beq     loop

        and     #NAME_LENGTH_MASK
        sta     file_entry_buf

        copy    #0, cancel_descent_flag
        jsr     op_jt1          ; first - called when visiting dir
        lda     cancel_descent_flag
        bne     loop

        lda     file_entry_buf + FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     loop
        jsr     prep_to_open_dir
        inc     process_depth
        jmp     loop

end_dir:
        lda     process_depth
        beq     L9920
        jsr     finish_dir
        dec     process_depth
        jmp     loop

L9920:  jmp     close_src_dir
.endproc

cancel_descent_flag:  .byte   0

op_jt1: jmp     (op_jt_addr1)
op_jt2: jmp     (op_jt_addr2)
op_jt3: jmp     (op_jt_addr3)

;;; ============================================================
;;; "Copy" (including Drag/Drop/Move) files state and logic
;;; ============================================================

;;; copy_process_selected_file
;;;  - called for each file in selection; calls process_dir to recurse
;;; copy_process_directory_entry
;;;  - c/o process_dir for each file in dir; skips if dir, copies otherwise
;;; copy_pop_directory
;;;  - c/o process_dir when exiting dir; pops path segment
;;; maybe_finish_file_move
;;;  - c/o process_dir after exiting; deletes dir if moving

;;; Overlays for copy operation (op_jt_addrs)
callbacks_for_copy:
        .addr   copy_process_directory_entry
        .addr   copy_pop_directory
        .addr   maybe_finish_file_move

.enum CopyDialogLifecycle
        open            = 0
        populate        = 1
        show            = 2
        exists          = 3     ; show "file exists" prompt
        too_large       = 4     ; show "too large" prompt
        close           = 5
.endenum

.params copy_dialog_params
phase:  .byte   0
count:  .addr   0
        .addr   src_path_buf
        .addr   dst_path_buf
.endparams

.proc do_copy_dialog_phase
        copy    #CopyDialogLifecycle::open, copy_dialog_params::phase
        copy16  #copy_dialog_phase0_callback, dialog_phase0_callback
        copy16  #copy_dialog_phase1_callback, dialog_phase1_callback
        jmp     run_copy_dialog_proc
.endproc

.proc copy_dialog_phase0_callback
        stax    copy_dialog_params::count
        copy    #CopyDialogLifecycle::populate, copy_dialog_params::phase
        jmp     run_copy_dialog_proc
.endproc

.proc prep_callbacks_for_copy
        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_copy,y,  op_jt_addrs,y
        dey
        bpl     :-

        lda     #0
        sta     LA425
        sta     all_flag
        rts
.endproc

.proc copy_dialog_phase1_callback
        copy    #CopyDialogLifecycle::close, copy_dialog_params::phase
        jmp     run_copy_dialog_proc
.endproc

;;; ============================================================
;;; "Download" - shares heavily with Copy

.proc do_download_dialog_phase
        copy    #CopyDialogLifecycle::open, copy_dialog_params::phase
        copy16  #download_dialog_phase0_callback, dialog_phase0_callback
        copy16  #download_dialog_phase1_callback, dialog_phase1_callback
        yax_call invoke_dialog_proc, kIndexDownloadDialog, copy_dialog_params
        rts
.endproc

.proc download_dialog_phase0_callback
        stax    copy_dialog_params::count
        copy    #CopyDialogLifecycle::populate, copy_dialog_params::phase
        yax_call invoke_dialog_proc, kIndexDownloadDialog, copy_dialog_params
        rts
.endproc

.proc prep_callbacks_for_download
        copy    #$80, all_flag

        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_copy,y, op_jt_addrs,y
        dey
        bpl     :-

        copy    #0, LA425
        copy16  #download_dialog_phase3_callback, dialog_phase3_callback
        rts
.endproc

.proc download_dialog_phase1_callback
        copy    #CopyDialogLifecycle::exists, copy_dialog_params::phase
        yax_call invoke_dialog_proc, kIndexDownloadDialog, copy_dialog_params
        rts
.endproc

.proc download_dialog_phase3_callback
        copy    #CopyDialogLifecycle::too_large, copy_dialog_params::phase
        yax_call invoke_dialog_proc, kIndexDownloadDialog, copy_dialog_params
        cmp     #PromptResult::yes
        bne     :+
        rts
:       jmp     close_files_cancel_dialog
.endproc

;;; ============================================================
;;; Handle copying of a selected file.
;;; Calls into the recursion logic of |process_dir| as necessary.

.proc copy_process_selected_file
        copy    #$80, LE05B
        copy    #0, delete_skip_decrement_flag
        beq     :+              ; always

for_run:
        lda     #$FF

:       sta     is_run_flag
        copy    #CopyDialogLifecycle::show, copy_dialog_params::phase
        jsr     copy_paths_to_src_and_dst_paths
        bit     operation_flags
        bvc     @not_run
        jsr     check_vol_blocks_free           ; dst is a volume path (RAM Card)
@not_run:
        bit     LE05B
        bpl     get_src_info    ; never taken ???
        bvs     L9A50
        lda     is_run_flag
        bne     :+
        lda     selected_window_index ; dragging from window?
        bne     :+
        jmp     copy_dir

:       ldx     dst_path_buf
        ldy     src_path_slash_index
        dey
:       iny
        inx
        lda     src_path_buf,y
        sta     dst_path_buf,x
        cpy     src_path_buf
        bne     :-

        stx     dst_path_buf
        jmp     get_src_info

        ;; Append filename to dst_path_buf
L9A50:  ldx     dst_path_buf
        lda     #'/'
        sta     dst_path_buf+1,x
        inc     dst_path_buf
        ldy     #0
        ldx     dst_path_buf
:       iny
        inx
        lda     filename_buf,y
        sta     dst_path_buf,x
        cpy     filename_buf
        bne     :-
        stx     dst_path_buf

get_src_info:
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     show_error_alert
        jmp     @retry

:       lda     src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        lda     #$00
        beq     store
is_dir: jsr     decrement_op_file_count
        lda     #$FF
store:  sta     is_dir_flag
        jsr     dec_file_count_and_run_copy_dialog_proc

        ;; Copy access, file_type, aux_type, storage_type
        ldy     #7
:       lda     src_file_info_params,y
        sta     create_params2,y
        dey
        cpy     #2
        bne     :-

        copy    #ACCESS_DEFAULT, create_params2::access
        lda     LE05B
        beq     create_ok       ; never taken ???
        jsr     check_space_and_show_prompt
        bcs     done

        ;; Copy create_time/create_date
        ldy     #17
        ldx     #11
:       lda     src_file_info_params,y
        sta     create_params2,x
        dex
        dey
        cpy     #13
        bne     :-

        ;; If a volume, need to create a subdir instead
        lda     create_params2::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     do_create
        lda     #ST_LINKED_DIRECTORY
        sta     create_params2::storage_type

do_create:
        MLI_RELAY_CALL CREATE, create_params2
        beq     create_ok

        cmp     #ERR_DUPLICATE_FILENAME
        bne     err
        bit     all_flag
        bmi     do_it
        copy    #CopyDialogLifecycle::exists, copy_dialog_params::phase
        jsr     run_copy_dialog_proc
        pha
        copy    #CopyDialogLifecycle::show, copy_dialog_params::phase
        pla
        cmp     #PromptResult::yes
        beq     do_it
        cmp     #PromptResult::no
        beq     done
        cmp     #PromptResult::all
        bne     cancel
        copy    #$80, all_flag
do_it:  jsr     apply_file_info_and_size
        jmp     create_ok

        ;; PromptResult::cancel
cancel: jmp     close_files_cancel_dialog

err:    jsr     show_error_alert
        jmp     do_create       ; retry

create_ok:
        lda     is_dir_flag
        beq     copy_file
copy_dir:                       ; also used when dragging a volume icon
        jsr     process_dir
        jmp     maybe_finish_file_move

done:   rts

copy_file:
        jsr     do_file_copy
        jmp     maybe_finish_file_move

is_dir_flag:
        .byte   0

is_run_flag:
        .byte   0
.endproc
        copy_file_for_run := copy_process_selected_file::for_run

;;; ============================================================

src_path_slash_index:
        .byte   0

;;; ============================================================

copy_pop_directory:
        jmp     remove_dst_path_segment

;;; ============================================================
;;; If moving, delete src file/directory.

.proc maybe_finish_file_move
        ;; Copy or move?
        bit     move_flag
        bpl     done

        ;; Was a move - delete file
@retry: MLI_RELAY_CALL DESTROY, destroy_params
        beq     done
        cmp     #ERR_ACCESS_ERROR
        bne     :+
        jsr     unlock_src_file
        beq     @retry
        bne     done            ; silently leave file

:       jsr     show_error_alert
        jmp     @retry
done:   rts
.endproc

;;; ============================================================
;;; Called by |process_dir| to process a single file

.proc copy_process_directory_entry
        jsr     check_escape_key_down
        beq     :+
        jmp     close_files_cancel_dialog

:       lda     file_entry_buf + FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     regular_file

        ;; Directory
        jsr     append_to_src_path
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     show_error_alert
        jmp     @retry

:       jsr     append_to_dst_path
        jsr     dec_file_count_and_run_copy_dialog_proc
        jsr     decrement_op_file_count

        jsr     try_create_dst
        bcs     :+
        jsr     remove_src_path_segment
        jmp     done

:       jsr     remove_dst_path_segment
        jsr     remove_src_path_segment
        copy    #$FF, cancel_descent_flag
        jmp     done

        ;; File
regular_file:
        jsr     append_to_dst_path
        jsr     append_to_src_path
        jsr     dec_file_count_and_run_copy_dialog_proc
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     show_error_alert
        jmp     @retry

:       jsr     check_space_and_show_prompt
        bcc     :+
        jmp     close_files_cancel_dialog

:       jsr     remove_src_path_segment
        jsr     try_create_dst
        bcs     :+
        jsr     append_to_src_path
        jsr     do_file_copy
        jsr     maybe_finish_file_move
        jsr     remove_src_path_segment
:       jsr     remove_dst_path_segment
done:   rts
.endproc

;;; ============================================================

.proc run_copy_dialog_proc
        yax_call invoke_dialog_proc, kIndexCopyDialog, copy_dialog_params
        rts
.endproc

;;; ============================================================

.proc check_vol_blocks_free
@retry: MLI_RELAY_CALL GET_FILE_INFO, dst_file_info_params
        beq     :+
        jsr     show_error_alert_dst
        jmp     @retry

:       sub16   dst_file_info_params::aux_type, dst_file_info_params::blocks_used, blocks_free
        cmp16   blocks_free, op_block_count
        bcs     :+
        jmp     done_dialog_phase3

:       rts

blocks_free:
        .word   0
.endproc

;;; ============================================================

.proc check_space_and_show_prompt
        jsr     check_space
        bcc     done
        copy    #CopyDialogLifecycle::too_large, copy_dialog_params::phase
        jsr     run_copy_dialog_proc
        beq     :+
        jmp     close_files_cancel_dialog
:       copy    #CopyDialogLifecycle::exists, copy_dialog_params::phase
        sec
done:   rts

.proc check_space
        ;; Size of source
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     show_error_alert
        jmp     @retry

        ;; If destination doesn't exist, 0 blocks will be reclaimed.
:       lda     #0
        sta     existing_size
        sta     existing_size+1

        ;; Does destination exist?
@retry2:MLI_RELAY_CALL GET_FILE_INFO, dst_file_info_params
        beq     got_exist_size
        cmp     #ERR_FILE_NOT_FOUND
        beq     :+
        jsr     show_error_alert_dst ; retry if destination not present
        jmp     @retry2

got_exist_size:
        copy16  dst_file_info_params::blocks_used, existing_size

        ;; Compute destination volume path
:       lda     dst_path_buf
        sta     saved_length
        ldy     #1              ; search for second '/'
:       iny
        cpy     dst_path_buf
        bcs     has_room
        lda     dst_path_buf,y
        cmp     #'/'
        bne     :-
        tya
        sta     dst_path_buf
        sta     vol_path_length

        ;; Total blocks/used blocks on destination volume
@retry: MLI_RELAY_CALL GET_FILE_INFO, dst_file_info_params
        beq     got_info
        pha                     ; on failure, restore path
        lda     saved_length    ; in case copy is aborted
        sta     dst_path_buf
        pla
        jsr     show_error_alert_dst
        jmp     @retry          ; BUG: Does this need to assign length again???

got_info:
        ;; aux = total blocks
        sub16   dst_file_info_params::aux_type, dst_file_info_params::blocks_used, blocks_free
        add16   blocks_free, existing_size, blocks_free
        cmp16   blocks_free, src_file_info_params::blocks_used
        bcs     has_room

        ;; not enough room
        sec
        bcs     :+
has_room:
        clc

:       lda     saved_length
        sta     dst_path_buf
        rts

blocks_free:
        .word   0
saved_length:
        .byte   0
vol_path_length:
        .byte   0
existing_size:
        .word   0
.endproc
.endproc

;;; ============================================================
;;; Actual byte-for-byte file copy routine

.proc do_file_copy
        jsr     decrement_op_file_count
        lda     #0
        sta     src_dst_exclusive_flag
        sta     src_eof_flag
        sta     mark_src_params::position
        sta     mark_src_params::position+1
        sta     mark_src_params::position+2
        sta     mark_dst_params::position
        sta     mark_dst_params::position+1
        sta     mark_dst_params::position+2

        jsr     open_src
        jsr     copy_src_ref_num
        jsr     open_dst
        beq     :+

        ;; Destination not available; note it, can prompt later
        copy    #$FF, src_dst_exclusive_flag
        bne     read            ; always
:       jsr     copy_dst_ref_num

        ;; Read
read:   jsr     read_src
        bit     src_dst_exclusive_flag
        bpl     write
        jsr     close_src       ; swap if necessary
:       jsr     open_dst
        bne     :-
        jsr     copy_dst_ref_num
        MLI_RELAY_CALL SET_MARK, mark_dst_params

        ;; Write
write:  bit     src_eof_flag
        bmi     eof
        jsr     write_dst
        bit     src_dst_exclusive_flag
        bpl     read
        jsr     close_dst       ; swap if necessary
        jsr     open_src
        jsr     copy_src_ref_num

        MLI_RELAY_CALL SET_MARK, mark_src_params
        beq     read
        copy    #$FF, src_eof_flag
        jmp     read

        ;; EOF
eof:    jsr     close_dst
        bit     src_dst_exclusive_flag
        bmi     :+
        jsr     close_src
:       jsr     copy_file_info
        jmp     set_dst_file_info

.proc open_src
@retry: MLI_RELAY_CALL OPEN, open_src_params
        beq     :+
        jsr     show_error_alert
        jmp     @retry
:       rts
.endproc

.proc copy_src_ref_num
        lda     open_src_params::ref_num
        sta     read_src_params::ref_num
        sta     close_src_params::ref_num
        sta     mark_src_params::ref_num
        rts
.endproc

.proc open_dst
@retry: MLI_RELAY_CALL OPEN, open_dst_params
        beq     done
        cmp     #ERR_VOL_NOT_FOUND
        beq     not_found
        jsr     show_error_alert_dst
        jmp     @retry

not_found:
        jsr     show_error_alert_dst
        lda     #ERR_VOL_NOT_FOUND

done:   rts
.endproc

.proc copy_dst_ref_num
        lda     open_dst_params::ref_num
        sta     write_dst_params::ref_num
        sta     close_dst_params::ref_num
        sta     mark_dst_params::ref_num
        rts
.endproc

.proc read_src
        copy16  #kBufSize, read_src_params::request_count
@retry: MLI_RELAY_CALL READ, read_src_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     eof
        jsr     show_error_alert
        jmp     @retry

:       copy16  read_src_params::trans_count, write_dst_params::request_count
        ora     read_src_params::trans_count
        bne     :+
eof:    copy    #$FF, src_eof_flag
:       MLI_RELAY_CALL GET_MARK, mark_src_params
        rts
.endproc

.proc write_dst
@retry: MLI_RELAY_CALL WRITE, write_dst_params
        beq     :+
        jsr     show_error_alert_dst
        jmp     @retry
:       MLI_RELAY_CALL GET_MARK, mark_dst_params
        rts
.endproc

.proc close_dst
        MLI_RELAY_CALL CLOSE, close_dst_params
        rts
.endproc

.proc close_src
        MLI_RELAY_CALL CLOSE, close_src_params
        rts
.endproc

        ;; Set if src/dst can't be open simultaneously.
src_dst_exclusive_flag:
        .byte   0

src_eof_flag:
        .byte   0

.endproc

;;; ============================================================

.proc try_create_dst
        ;; Copy file_type, aux_type, storage_type
        ldx     #7
:       lda     src_file_info_params,x
        sta     create_params3,x
        dex
        cpx     #3
        bne     :-

create: MLI_RELAY_CALL CREATE, create_params3
        beq     success
        cmp     #ERR_DUPLICATE_FILENAME
        bne     err
        bit     all_flag
        bmi     yes
        copy    #CopyDialogLifecycle::exists, copy_dialog_params::phase
        yax_call invoke_dialog_proc, kIndexCopyDialog, copy_dialog_params
        pha
        copy    #CopyDialogLifecycle::show, copy_dialog_params::phase
        pla
        cmp     #PromptResult::yes
        beq     yes
        cmp     #PromptResult::no
        beq     failure
        cmp     #PromptResult::all
        bne     cancel
        copy    #$80, all_flag
yes:    jsr     apply_file_info_and_size
        jmp     success

cancel: jmp     close_files_cancel_dialog

err:    jsr     show_error_alert_dst
        jmp     create

success:
        clc
        rts

failure:
        sec
        rts
.endproc

;;; ============================================================
;;; Delete/Trash files dialog state and logic
;;; ============================================================

;;; delete_process_selected_file
;;;  - called for each file in selection; calls process_dir to recurse
;;; delete_process_directory_entry
;;;  - c/o process_dir for each file in dir; skips if dir, deletes otherwise
;;; delete_finish_directory
;;;  - c/o process_dir when exiting dir; deletes it

;;; Overlays for delete operation (op_jt_addrs)
callbacks_for_delete:
        .addr   delete_process_directory_entry
        .addr   do_nothing
        .addr   delete_finish_directory

.params delete_dialog_params
phase:  .byte   0
count:  .word   0
        .addr   src_path_buf
.endparams

.proc do_delete_dialog_phase
        sta     delete_dialog_params::phase
        copy16  #confirm_delete_dialog, dialog_phase2_callback
        copy16  #populate_delete_dialog, dialog_phase0_callback
        jsr     run_delete_dialog_proc
        copy16  #L9ED3, dialog_phase1_callback
        rts

.proc populate_delete_dialog
        stax    delete_dialog_params::count
        copy    #DeleteDialogLifecycle::populate, delete_dialog_params::phase
        jmp     run_delete_dialog_proc
.endproc

.proc confirm_delete_dialog
        copy    #DeleteDialogLifecycle::confirm, delete_dialog_params::phase
        jsr     run_delete_dialog_proc
        beq     :+
        jmp     close_files_cancel_dialog
:       rts
.endproc

.endproc

;;; ============================================================

.proc prep_callbacks_for_delete
        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_delete,y, op_jt_addrs,y
        dey
        bpl     :-

        lda     #0
        sta     LA425
        sta     all_flag
        rts
.endproc

.proc L9ED3
        copy    #DeleteDialogLifecycle::close, delete_dialog_params::phase
        jmp     run_delete_dialog_proc
.endproc

;;; ============================================================
;;; Handle deletion of a selected file.
;;; Calls into the recursion logic of |process_dir| as necessary.

.proc delete_process_selected_file
        copy    #DeleteDialogLifecycle::show, delete_dialog_params::phase
        jsr     copy_paths_to_src_and_dst_paths

@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     show_error_alert
        jmp     @retry

        ;; Check if it's a regular file or directory
:       lda     src_file_info_params::storage_type
        sta     storage_type
        cmp     #ST_LINKED_DIRECTORY
        beq     :+
        lda     #0
        beq     store
:       lda     #$FF
store:  sta     is_dir_flag
        beq     do_destroy

        ;; Recurse, and process directory
        jsr     process_dir

        ;; Was it a directory?
        lda     storage_type
        cmp     #ST_LINKED_DIRECTORY
        bne     :+
        copy    #$FF, storage_type ; is this re-checked?
:       jmp     do_destroy

        ;; Written, not read???
is_dir_flag:
        .byte   0

storage_type:
        .byte   0

do_destroy:
        bit     delete_skip_decrement_flag
        bmi     :+
        jsr     dec_file_count_and_run_delete_dialog_proc
:       jsr     decrement_op_file_count

retry:  MLI_RELAY_CALL DESTROY, destroy_params
        beq     done
        cmp     #ERR_ACCESS_ERROR
        bne     error
        bit     all_flag
        bmi     do_it
        copy    #DeleteDialogLifecycle::locked, delete_dialog_params::phase
        jsr     run_delete_dialog_proc
        pha
        copy    #DeleteDialogLifecycle::show, delete_dialog_params::phase
        pla
        cmp     #PromptResult::no
        beq     done
        cmp     #PromptResult::yes
        beq     do_it
        cmp     #PromptResult::all
        bne     :+
        copy    #$80, all_flag
        bne     do_it           ; always
:       jmp     close_files_cancel_dialog

do_it:  jsr     unlock_src_file
        bne     done
        jmp     retry

done:   rts

error:  jsr     show_error_alert
        jmp     retry
.endproc

.proc unlock_src_file
        MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        lda     src_file_info_params::access
        and     #$80
        bne     done
        lda     #ACCESS_DEFAULT
        sta     src_file_info_params::access
        copy    #7, src_file_info_params ; param count for SET_FILE_INFO
        MLI_RELAY_CALL SET_FILE_INFO, src_file_info_params
        copy    #$A, src_file_info_params ; param count for GET_FILE_INFO
        lda     #0                        ; success
done:   rts
.endproc

;;; ============================================================
;;; Called by |process_dir| to process a single file

.proc delete_process_directory_entry
        ;; Cancel if escape pressed
        jsr     check_escape_key_down
        beq     :+
        jmp     close_files_cancel_dialog

:       jsr     append_to_src_path
        bit     delete_skip_decrement_flag
        bmi     :+
        jsr     dec_file_count_and_run_delete_dialog_proc
:       jsr     decrement_op_file_count

        ;; Check file type
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     show_error_alert
        jmp     @retry

        ;; Directories will be processed separately
:       lda     src_file_info_params::storage_type
        cmp     #ST_LINKED_DIRECTORY
        beq     next_file

loop:   MLI_RELAY_CALL DESTROY, destroy_params
        beq     next_file
        cmp     #ERR_ACCESS_ERROR
        bne     err
        bit     all_flag
        bmi     unlock
        copy    #DeleteDialogLifecycle::locked, delete_dialog_params::phase
        yax_call invoke_dialog_proc, kIndexDeleteDialog, delete_dialog_params
        pha
        copy    #DeleteDialogLifecycle::show, delete_dialog_params::phase
        pla
        cmp     #PromptResult::no
        beq     next_file
        cmp     #PromptResult::yes
        beq     unlock
        cmp     #PromptResult::all
        bne     :+
        copy    #$80, all_flag
        bne     unlock           ; always
        ;; PromptResult::cancel
:       jmp     close_files_cancel_dialog

unlock: copy    #ACCESS_DEFAULT, src_file_info_params::access
        copy    #7, src_file_info_params ; param count for SET_FILE_INFO
        MLI_RELAY_CALL SET_FILE_INFO, src_file_info_params
        copy    #$A,src_file_info_params ; param count for GET_FILE_INFO
        jmp     loop

err:    jsr     show_error_alert
        jmp     loop

next_file:
        jmp     remove_src_path_segment
.endproc

;;; ============================================================
;;; Delete directory when exiting via traversal

.proc delete_finish_directory
@retry: MLI_RELAY_CALL DESTROY, destroy_params
        beq     done
        cmp     #ERR_ACCESS_ERROR
        beq     done
        jsr     show_error_alert
        jmp     @retry
done:   rts
.endproc

.proc run_delete_dialog_proc
        yax_call invoke_dialog_proc, kIndexDeleteDialog, delete_dialog_params
        rts
.endproc

;;; ============================================================
;;; "Lock"/"Unlock" dialog state and logic
;;; ============================================================

;;; lock_process_selected_file
;;;  - called for each file in selection; calls process_dir to recurse
;;; lock_process_directory_entry
;;;  - c/o process_dir for each file in dir; skips if dir, locks otherwise

;;; Overlays for lock/unlock operation (op_jt_addrs)
callbacks_for_lock:
        .addr   lock_process_directory_entry
        .addr   do_nothing
        .addr   do_nothing

.enum LockDialogLifecycle
        open            = 0 ; opening window, initial label
        populate        = 1 ; show operation details (e.g. file count)
        loop            = 2 ; draw buttons, input loop
        operation       = 3 ; performing operation
        close           = 4 ; destroy window
.endenum

.params lock_unlock_dialog_params
phase:  .byte   0
files_remaining_count:
        .word   0
        .addr   src_path_buf
.endparams

.proc do_lock_dialog_phase
        copy    #LockDialogLifecycle::open, lock_unlock_dialog_params::phase
        bit     unlock_flag
        bpl     :+

        ;; Unlock
        copy16  #unlock_dialog_phase2_callback, dialog_phase2_callback
        copy16  #unlock_dialog_phase0_callback, dialog_phase0_callback
        jsr     unlock_dialog_lifecycle
        copy16  #close_unlock_dialog, dialog_phase1_callback
        rts

        ;; Lock
:       copy16  #lock_dialog_phase2_callback, dialog_phase2_callback
        copy16  #lock_dialog_phase0_callback, dialog_phase0_callback
        jsr     lock_dialog_lifecycle
        copy16  #close_lock_dialog, dialog_phase1_callback
        rts
.endproc

.proc lock_dialog_phase0_callback
        stax    lock_unlock_dialog_params::files_remaining_count
        copy    #LockDialogLifecycle::populate, lock_unlock_dialog_params::phase
        jmp     lock_dialog_lifecycle
.endproc

.proc unlock_dialog_phase0_callback
        stax    lock_unlock_dialog_params::files_remaining_count
        copy    #LockDialogLifecycle::populate, lock_unlock_dialog_params::phase
        jmp     unlock_dialog_lifecycle
.endproc

.proc lock_dialog_phase2_callback
        copy    #LockDialogLifecycle::loop, lock_unlock_dialog_params::phase
        jsr     lock_dialog_lifecycle
        beq     :+
        jmp     close_files_cancel_dialog

:       rts
.endproc

.proc unlock_dialog_phase2_callback
        copy    #LockDialogLifecycle::loop, lock_unlock_dialog_params::phase
        jsr     unlock_dialog_lifecycle
        beq     :+
        jmp     close_files_cancel_dialog
:       rts
.endproc

.proc prep_callbacks_for_lock
        copy    #0, LA425

        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_lock,y, op_jt_addrs,y
        dey
        bpl     :-

        rts
.endproc

.proc close_lock_dialog
        copy    #LockDialogLifecycle::close, lock_unlock_dialog_params::phase
        jmp     lock_dialog_lifecycle
.endproc

.proc close_unlock_dialog
        copy    #LockDialogLifecycle::close, lock_unlock_dialog_params::phase
        jmp     unlock_dialog_lifecycle
.endproc

lock_dialog_lifecycle:
        yax_call invoke_dialog_proc, kIndexLockDialog, lock_unlock_dialog_params
        rts

unlock_dialog_lifecycle:
        yax_call invoke_dialog_proc, kIndexUnlockDialog, lock_unlock_dialog_params
        rts

;;; ============================================================
;;; Handle locking of a selected file.
;;; Calls into the recursion logic of |process_dir| as necessary.

.proc lock_process_selected_file
        copy    #LockDialogLifecycle::operation, lock_unlock_dialog_params::phase
        jsr     copy_paths_to_src_and_dst_paths
        ldx     dst_path_buf
        ldy     src_path_slash_index
        dey
LA123:  iny
        inx
        lda     src_path_buf,y
        sta     dst_path_buf,x
        cpy     src_path_buf
        bne     LA123
        stx     dst_path_buf

@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     show_error_alert
        jmp     @retry

:       lda     src_file_info_params::storage_type
        sta     storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        lda     #$00
        beq     store
is_dir: lda     #$FF
store:  sta     is_dir_flag
        beq     do_lock

        ;; Process files in directory
        jsr     process_dir

        ;; If this wasn't a volume directory, lock it too
        lda     storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     do_lock
        rts

        ;; Written, not read???
is_dir_flag:
        .byte   0

storage_type:
        .byte   0

do_lock:
        jsr     lock_file_common
        jmp     append_to_src_path
.endproc

;;; ============================================================
;;; Called by |process_dir| to process a single file

lock_process_directory_entry:
        jsr     append_to_src_path
        ;; fall through

.proc lock_file_common
        jsr     update_dialog

        jsr     decrement_op_file_count

@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     show_error_alert
        jmp     @retry

:       lda     src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     ok
        cmp     #ST_LINKED_DIRECTORY
        beq     ok
        bit     unlock_flag
        bpl     :+
        lda     #ACCESS_DEFAULT
        bne     set
:       lda     #ACCESS_LOCKED
set:    sta     src_file_info_params::access

:       copy    #7, src_file_info_params ; param count for SET_FILE_INFO
        MLI_RELAY_CALL SET_FILE_INFO, src_file_info_params
        pha
        copy    #$A, src_file_info_params ; param count for GET_FILE_INFO
        pla
        beq     ok
        jsr     show_error_alert
        jmp     :-

ok:     jmp     remove_src_path_segment

update_dialog:
        sub16   op_file_count, #1, lock_unlock_dialog_params::files_remaining_count
        bit     unlock_flag
        bpl     LA1DC
        jmp     unlock_dialog_lifecycle

LA1DC:  jmp     lock_dialog_lifecycle
.endproc

;;; ============================================================
;;; "Get Size" dialog state and logic
;;; ============================================================

;;; Logic also used for "count" operation which precedes most
;;; other operations (copy, delete, lock, unlock) to populate
;;; confirmation dialog.

.params get_size_dialog_params
phase:  .byte   0
        .addr   op_file_count, op_block_count
.endparams

do_get_size_dialog_phase:
        copy    #0, get_size_dialog_params::phase
        copy16  #get_size_dialog_phase2_callback, dialog_phase2_callback
        copy16  #get_size_dialog_phase0_callback, dialog_phase0_callback
        yax_call invoke_dialog_proc, kIndexGetSizeDialog, get_size_dialog_params
        copy16  #get_size_dialog_phase1_callback, dialog_phase1_callback
        rts

.proc get_size_dialog_phase0_callback
        copy    #1, get_size_dialog_params::phase
        yax_call invoke_dialog_proc, kIndexGetSizeDialog, get_size_dialog_params
        ;; fall through
.endproc
get_size_rts1:
        rts

.proc get_size_dialog_phase2_callback
        copy    #2, get_size_dialog_params::phase
        yax_call invoke_dialog_proc, kIndexGetSizeDialog, get_size_dialog_params
        beq     get_size_rts1
        jmp     close_files_cancel_dialog
.endproc

.proc get_size_dialog_phase1_callback
        copy    #3, get_size_dialog_params::phase
        yax_call invoke_dialog_proc, kIndexGetSizeDialog, get_size_dialog_params
.endproc
get_size_rts2:
        rts

;;; ============================================================
;;; Most operations start by doing a traversal to just count
;;; the files.

;;; Overlays for size operation (op_jt_addrs)
callbacks_for_size_or_count:
        .addr   size_or_count_process_directory_entry
        .addr   do_nothing
        .addr   do_nothing

.proc prep_callbacks_for_size_or_count
        copy    #0, LA425

        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_size_or_count,y, op_jt_addrs,y
        dey
        bpl     :-

        lda     #0
        sta     op_file_count
        sta     op_file_count+1
        sta     op_block_count
        sta     op_block_count+1

        rts
.endproc

;;; ============================================================
;;; Handle sizing (or just counting) of a selected file.
;;; Calls into the recursion logic of |process_dir| as necessary.

.proc size_or_count_process_selected_file
        jsr     copy_paths_to_src_and_dst_paths
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     show_error_alert
        jmp     @retry

:       copy    src_file_info_params::storage_type, storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        lda     #0
        beq     store           ; always

is_dir: lda     #$FF

store:  sta     is_dir_flag
        beq     do_sum_file_size           ; if not a dir

        jsr     process_dir
        lda     storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     do_sum_file_size           ; if a subdirectory
        rts

        ;; Written, not read???
is_dir_flag:
        .byte   0

storage_type:
        .byte   0

do_sum_file_size:
        jmp     size_or_count_process_directory_entry
.endproc

;;; ============================================================
;;; Called by |process_dir| to process a single file

size_or_count_process_directory_entry:
        bit     operation_flags
        bvc     :+              ; not size

        ;; If operation is "get size", add the block count to the sum
        jsr     append_to_src_path
        MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        bne     :+
        add16   op_block_count, src_file_info_params::blocks_used, op_block_count

:       inc16   op_file_count

        bit     operation_flags
        bvc     :+              ; not size
        jsr     remove_src_path_segment

:       ldax    op_file_count
        jmp     done_dialog_phase0

op_file_count:
        .word   0

op_block_count:
        .word   0

;;; ============================================================

.proc decrement_op_file_count
        dec16   op_file_count
        rts
.endproc

;;; ============================================================
;;; Append name at file_entry_buf to path at src_path_buf

.proc append_to_src_path
        path := src_path_buf

        lda     file_entry_buf
        bne     :+
        rts

:       ldx     #0
        ldy     path
        copy    #'/', path+1,y

        iny
loop:   cpx     file_entry_buf
        bcs     done
        lda     file_entry_buf+1,x
        sta     path+1,y
        inx
        iny
        jmp     loop

done:   sty     path
        rts
.endproc

;;; ============================================================
;;; Remove segment from path at src_path_buf

.proc remove_src_path_segment
        path := src_path_buf

        ldx     path            ; length
        bne     :+
        rts

:       lda     path,x
        cmp     #'/'
        beq     found
        dex
        bne     :-
        stx     path
        rts

found:  dex
        stx     path
        rts
.endproc

;;; ============================================================
;;; Append name at file_entry_buf to path at dst_path_buf

.proc append_to_dst_path
        path := dst_path_buf

        lda     file_entry_buf
        bne     :+
        rts

:       ldx     #0
        ldy     path
        copy    #'/', path+1,y

        iny
loop:   cpx     file_entry_buf
        bcs     done
        lda     file_entry_buf+1,x
        sta     path+1,y
        inx
        iny
        jmp     loop

done:   sty     path
        rts
.endproc

;;; ============================================================
;;; Remove segment from path at dst_path_buf

.proc remove_dst_path_segment
        path := dst_path_buf

        ldx     path            ; length
        bne     :+
        rts

:       lda     path,x
        cmp     #'/'
        beq     found
        dex
        bne     :-
        stx     path
        rts

found:  dex
        stx     path
        rts
.endproc

;;; ============================================================
;;; Copy path_buf3 to src_path_buf, path_buf4 to dst_path_buf
;;; and note last '/' in src.

.proc copy_paths_to_src_and_dst_paths
        ldy     #0
        sty     src_path_slash_index
        dey

        ;; Copy path_buf3 to src_path_buf
        ;; ... but record index of last '/'
loop:   iny
        lda     path_buf3,y
        cmp     #'/'
        bne     :+
        sty     src_path_slash_index
:       sta     src_path_buf,y
        cpy     path_buf3
        bne     loop

        ;; Copy path_buf4 to dst_path_buf
        ldy     path_buf4
:       lda     path_buf4,y
        sta     dst_path_buf,y
        dey
        bpl     :-
        rts
.endproc

;;; ============================================================
;;; Closes dialog, closes all open files, and restores stack.

.proc close_files_cancel_dialog
        jsr     done_dialog_phase1
        jmp     :+

        DEFINE_CLOSE_PARAMS close_params

:       MLI_RELAY_CALL CLOSE, close_params
        lda     selected_window_index
        beq     :+
        jsr     set_port_from_window_id
:       ldx     stack_stash     ; restore stack, in case recursion was aborted
        txs
        return  #$FF
.endproc

;;; ============================================================
;;; Move or Copy? Compare src/dst paths, same vol = move.
;;; Output: A=high bit set if move, clear if copy

.proc check_move_or_copy
        src_ptr := $08
        dst_buf := path_buf4

        lda     BUTN0           ; Apple overrides, forces copy
        ora     BUTN1
        bmi     no_match

        ldy     #0
        lda     (src_ptr),y
        sta     src_len
        iny                     ; skip leading '/'
        bne     check           ; always

        ;; Chars the same?
loop:   lda     (src_ptr),y
        cmp     dst_buf,y
        bne     no_match

        ;; Same and a slash?
        cmp     #'/'
        beq     match

        ;; End of src?
check:  cpy     src_len
        bcc     :+
        cpy     dst_buf         ; dst also done?
        bcs     match
        lda     path_buf4+1,y   ; is next char in dst a slash?
        bne     check_slash     ; always

:       cpy     dst_buf         ; src is not done, is dst?
        bcc     :+
        iny
        lda     (src_ptr),y     ; is next char in src a slash?
        bne     check_slash     ; always

:       iny                     ; next char
        bne     loop            ; always

check_slash:
        cmp     #'/'
        beq     match           ; if so, same vol
        ;; fall through

no_match:
        return  #0

match:  return  #$80

src_len:
        .byte   0
.endproc

;;; ============================================================

.proc check_escape_key_down
        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::key_down
        bne     nope
        lda     event_key
        cmp     #CHAR_ESCAPE
        bne     nope
        lda     #$FF
        bne     done
nope:   lda     #$00
done:   rts
.endproc

;;; ============================================================

.proc dec_file_count_and_run_delete_dialog_proc
        sub16   op_file_count, #1, delete_dialog_params::count
        yax_call invoke_dialog_proc, kIndexDeleteDialog, delete_dialog_params
        rts
.endproc

.proc dec_file_count_and_run_copy_dialog_proc
        sub16   op_file_count, #1, copy_dialog_params::count
        yax_call invoke_dialog_proc, kIndexCopyDialog, copy_dialog_params
        rts
.endproc

LA425:  .byte   0               ; ??? only written to (with 0)

;;; ============================================================

.proc apply_file_info_and_size
:       jsr     copy_file_info
        copy    #ACCESS_DEFAULT, dst_file_info_params::access
        jsr     set_dst_file_info
        lda     src_file_info_params::file_type
        cmp     #FT_DIRECTORY
        beq     done

        ;; If a regular file, open/set eof/close
        MLI_RELAY_CALL OPEN, open_dst_params
        beq     :+
        jsr     show_error_alert_dst
        jmp     :-              ; retry

:       lda     open_dst_params::ref_num
        sta     set_eof_params::ref_num
        sta     close_dst_params::ref_num
@retry: MLI_RELAY_CALL SET_EOF, set_eof_params
        beq     close
        jsr     show_error_alert_dst
        jmp     @retry

close:  MLI_RELAY_CALL CLOSE, close_dst_params
done:   rts
.endproc

.proc copy_file_info
        COPY_BYTES 11, src_file_info_params::access, dst_file_info_params::access
        rts
.endproc

.proc set_dst_file_info
:       copy    #7, dst_file_info_params ; SET_FILE_INFO param_count
        MLI_RELAY_CALL SET_FILE_INFO, dst_file_info_params
        pha
        copy    #$A, dst_file_info_params ; GET_FILE_INFO param_count
        pla
        beq     done
        jsr     show_error_alert_dst
        jmp     :-

done:   rts
.endproc

;;; ============================================================
;;; Show Alert Dialog
;;; A=error. If ERR_VOL_NOT_FOUND or ERR_FILE_NOT_FOUND, will
;;; show "please insert source disk" (or destination, if flag set)

.proc show_error_alert_impl

flag_set:
        ldx     #$80
        bne     :+

flag_clear:
        ldx     #0

:       stx     flag
        cmp     #ERR_VOL_NOT_FOUND ; if err is "not found"
        beq     not_found       ; prompt specifically for src/dst disk
        cmp     #ERR_PATH_NOT_FOUND
        beq     not_found

        jsr     JT_SHOW_ALERT0
        bne     LA4C2           ; cancel???
        rts

not_found:
        bit     flag
        bpl     :+
        lda     #kErrInsertDstDisk
        jmp     show

:       lda     #kErrInsertSrcDisk
show:   jsr     JT_SHOW_ALERT0
        bne     LA4C2
        jmp     do_on_line

LA4C2:  jmp     close_files_cancel_dialog

flag:   .byte   0

do_on_line:
        MLI_RELAY_CALL ON_LINE, on_line_params2
        rts

.endproc
        show_error_alert := show_error_alert_impl::flag_clear
        show_error_alert_dst := show_error_alert_impl::flag_set

;;; ============================================================
;;; Reformat /RAM (Slot 3, Drive 2) if present
;;; Assumes ROM is banked in, restores it when complete. Also
;;; assumes hires screen (main and aux) are safe to destroy.

.proc maybe_reformat_ram
        kRAMUnitNumber = (1<<7 | 3<<4 | DT_RAM)

        ;; Search DEVLST to see if S3D2 RAM was restored
        ldx     DEVCNT
:       lda     DEVLST,x
        cmp     #kRAMUnitNumber
        beq     format
        dex
        bpl     :-
        rts

        ;; NOTE: Assumes driver (in DEVADR) was not modified
        ;; when detached.

        ;; /RAM FORMAT call; see ProDOS 8 TRM 5.2.2.4 for details
format: copy    #DRIVER_COMMAND_FORMAT, DRIVER_COMMAND
        copy    #kRAMUnitNumber, DRIVER_UNIT_NUMBER
        copy16  #$2000, DRIVER_BUFFER
        lda     LCBANK1
        lda     LCBANK1
        jsr     driver
        sta     ROMIN2
        rts

RAMSLOT := DEVADR + $16         ; Slot 3, Drive 2

driver: jmp     (RAMSLOT)
.endproc

;;; ============================================================
;;; Determine if mouse moved (returns w/ carry set if moved)
;;; Used in dialogs to possibly change cursor

.proc check_mouse_moved
        ldx     #.sizeof(MGTK::Point)-1
:       lda     event_coords,x
        cmp     coords,x
        bne     diff
        dex
        bpl     :-
        clc
        rts

diff:   COPY_STRUCT MGTK::Point, event_coords, coords
        sec
        rts

coords: DEFINE_POINT 0,0

.endproc

;;; ============================================================
;;; Save/Restore window state at shutdown/launch

.proc save_restore_windows
        desktop_file_io_buf := $1000
        desktop_file_data_buf := $1400
        kFileSize = 2 + 8 * .sizeof(DeskTopFileItem) + 1

        DEFINE_CREATE_PARAMS create_params, str_desktop_file, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_params, str_desktop_file, desktop_file_io_buf
        DEFINE_READ_PARAMS read_params, desktop_file_data_buf, kFileSize
        DEFINE_READ_PARAMS write_params, desktop_file_data_buf, kFileSize
        DEFINE_CLOSE_PARAMS close_params
str_desktop_file:
        PASCAL_STRING "DeskTop.file"

.proc save
        data_ptr := $06
        winfo_ptr := $08

        ;; Write version bytes
        copy    #kDeskTopVersionMajor, desktop_file_data_buf
        copy    #kDeskTopVersionMinor, desktop_file_data_buf+1
        copy16  #desktop_file_data_buf+2, data_ptr

        ;; Get first window pointer
        MGTK_RELAY_CALL MGTK::FrontWindow, window_id
        lda     window_id
        beq     finish
        jsr     window_lookup
        stax    winfo_ptr
        copy    #0, depth

        ;; Is there a lower window?
recurse_down:
        next_ptr := $0A

        ldy     #MGTK::Winfo::nextwinfo
        copy16in (winfo_ptr),y, next_ptr
        ora     next_ptr
        beq     recurse_up      ; Nope - just finish.

        ;; Yes, recurse
        inc     depth
        lda     winfo_ptr
        pha
        lda     winfo_ptr+1
        pha

        copy16  next_ptr, winfo_ptr
        jmp     recurse_down

recurse_up:
        jsr     write_window_info
        lda     depth           ; Last window?
        beq     finish          ; Yes - we're done!

        dec     depth           ; No, pop the stack and write the next
        pla
        sta     winfo_ptr+1
        pla
        sta     winfo_ptr
        jmp     recurse_up

finish: ldy     #0              ; Write sentinel
        tay
        sta     (data_ptr),y

        ;; Write out file, to current prefix.
        jsr     write_out_file

        ;; If DeskTop was copied to RAMCard, also write to original prefix.
        jsr     get_copied_to_ramcard_flag
        bpl     exit
        addr_call copy_desktop_orig_prefix, path_buffer
        addr_call append_to_path_buffer, str_desktop_file
        lda     #<path_buffer
        sta     create_params::pathname
        sta     open_params::pathname
        lda     #>path_buffer
        sta     create_params::pathname+1
        sta     open_params::pathname+1
        jsr     write_out_file

exit:   rts

.proc write_window_info
        path_ptr := $0A

        ;; Find name
        ldy     #MGTK::Winfo::window_id
        lda     (winfo_ptr),y
        jsr     get_window_path
        stax    path_ptr

        ;; Copy name in
        ldy     #::kPathBufferSize-1
:       lda     (path_ptr),y
        sta     (data_ptr),y
        dey
        bpl     :-

        ;; Assemble rect - left/top first
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + .sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     (winfo_ptr),y
        sta     bounds,x
        dey
        dex
        bpl     :-
        ;; width/height next
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect  + MGTK::Rect::x2 + .sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     (winfo_ptr),y
        sta     bounds + MGTK::Rect::x2,x
        dey
        dex
        bpl     :-

        add16_8 data_ptr, #.sizeof(DeskTopFileItem), data_ptr
        rts

bounds: .tag    MGTK::Rect

.endproc                        ; write_window_info

window_id := findwindow_window_id

depth:  .byte   0

.endproc                        ; save

.proc open
        MLI_RELAY_CALL OPEN, open_params
        rts
.endproc

.proc close
        MLI_RELAY_CALL CLOSE, close_params
        rts
.endproc

.proc write_out_file
        MLI_RELAY_CALL CREATE, create_params
        jsr     open
        bcs     :+
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_RELAY_CALL WRITE, write_params
        jsr     close
:       rts
.endproc

.endproc
save_windows := save_restore_windows::save

;;; ============================================================

        PAD_TO $A500

;;; ============================================================
;;; Dialog Launcher (or just proc handler???)

kNumDialogTypes = 13

kIndexAboutDialog       = 0
kIndexCopyDialog        = 1
kIndexDeleteDialog      = 2
kIndexNewFolderDialog   = 3
kIndexGetInfoDialog     = 6
kIndexLockDialog        = 7
kIndexUnlockDialog      = 8
kIndexRenameDialog      = 9
kIndexDownloadDialog    = 10
kIndexGetSizeDialog     = 11
kIndexWarningDialog     = 12

invoke_dialog_proc:
        ASSERT_ADDRESS $A500, "Overlay entry point"
        jmp     invoke_dialog_proc_impl

dialog_proc_table:
        .addr   about_dialog_proc
        .addr   copy_dialog_proc
        .addr   delete_dialog_proc
        .addr   new_folder_dialog_proc
        .addr   rts1
        .addr   rts1
        .addr   get_info_dialog_proc
        .addr   lock_dialog_proc
        .addr   unlock_dialog_proc
        .addr   rename_dialog_proc
        .addr   download_dialog_proc
        .addr   get_size_dialog_proc
        .addr   warning_dialog_proc
        ASSERT_ADDRESS_TABLE_SIZE dialog_proc_table, kNumDialogTypes

dialog_param_addr:
        .addr   0
        .byte   0

.proc invoke_dialog_proc_impl
        stax    dialog_param_addr
        tya
        asl     a
        tax
        copy16  dialog_proc_table,x, @jump_addr

        lda     #0
        sta     prompt_ip_flag
        sta     LD8EC
        sta     LD8F0
        sta     LD8F1
        sta     LD8F2
        sta     has_input_field_flag
        sta     LD8F5
        sta     format_erase_overlay_flag
        sta     cursor_ibeam_flag

        copy    SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter

        copy16  #rts1, jump_relay+1
        jsr     set_cursor_pointer

        @jump_addr := *+1
        jmp     dummy0000       ; self-modified
.endproc


;;; ============================================================
;;; Message handler for OK/Cancel dialog

.proc prompt_input_loop
        lda     has_input_field_flag
        beq     :+

        ;; Blink the insertion point
        dec     prompt_ip_counter
        bne     :+
        jsr     redraw_prompt_insertion_point
        copy    SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter

        ;; Dispatch event types - mouse down, key press
:       MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jmp     prompt_click_handler

:       cmp     #MGTK::EventKind::key_down
        bne     :+
        jmp     prompt_key_handler

        ;; Does the dialog have an input field?
:       lda     has_input_field_flag
        beq     prompt_input_loop

        ;; Check if mouse is over input field, change cursor appropriately.
        jsr     check_mouse_moved
        bcc     prompt_input_loop

        MGTK_RELAY_CALL MGTK::FindWindow, event_coords
        lda     findwindow_which_area
        bne     :+
        jmp     prompt_input_loop

:       lda     findwindow_window_id
        cmp     winfo_prompt_dialog
        beq     :+
        jmp     prompt_input_loop

:       lda     winfo_prompt_dialog ; Is over this window... but where?
        jsr     set_port_from_window_id
        copy    winfo_prompt_dialog, event_params
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, name_input_rect
        cmp     #MGTK::inrect_inside
        bne     out
        jsr     set_cursor_ibeam_with_flag
        jmp     done
out:    jsr     set_cursor_pointer_with_flag
done:   jsr     reset_main_grafport
        jmp     prompt_input_loop
.endproc

;;; Click handler for prompt dialog

.proc prompt_click_handler
        MGTK_RELAY_CALL MGTK::FindWindow, event_coords
        lda     findwindow_which_area
        bne     :+
        return  #$FF
:       cmp     #MGTK::Area::content
        bne     :+
        jmp     content
:       return  #$FF

content:
        lda     findwindow_window_id
        cmp     winfo_prompt_dialog
        beq     :+
        return  #$FF
:       lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        copy    winfo_prompt_dialog, event_params
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        bit     LD8E7
        bvc     :+
        jmp     check_button_yes

:       MGTK_RELAY_CALL MGTK::InRect, aux::ok_button_rect
        cmp     #MGTK::inrect_inside
        beq     check_button_ok
        jmp     maybe_check_button_cancel

check_button_ok:
        yax_call ButtonEventLoopRelay, kPromptDialogWindowID, aux::ok_button_rect
        bmi     :+
        lda     #PromptResult::ok
:       rts

check_button_yes:
        MGTK_RELAY_CALL MGTK::InRect, aux::yes_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_button_no
        yax_call ButtonEventLoopRelay, kPromptDialogWindowID, aux::yes_button_rect
        bmi     :+
        lda     #PromptResult::yes
:       rts

check_button_no:
        MGTK_RELAY_CALL MGTK::InRect, aux::no_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_button_all
        yax_call ButtonEventLoopRelay, kPromptDialogWindowID, aux::no_button_rect
        bmi     :+
        lda     #PromptResult::no
:       rts

check_button_all:
        MGTK_RELAY_CALL MGTK::InRect, aux::all_button_rect
        cmp     #MGTK::inrect_inside
        bne     maybe_check_button_cancel
        yax_call ButtonEventLoopRelay, kPromptDialogWindowID, aux::all_button_rect
        bmi     :+
        lda     #PromptResult::all
:       rts

maybe_check_button_cancel:
        bit     LD8E7
        bpl     check_button_cancel
        return  #$FF

check_button_cancel:
        MGTK_RELAY_CALL MGTK::InRect, aux::cancel_button_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        jmp     LA6ED
:       yax_call ButtonEventLoopRelay, kPromptDialogWindowID, aux::cancel_button_rect
        bmi     :+
        lda     #PromptResult::cancel
:       rts

LA6ED:  bit     has_input_field_flag
        bmi     LA6F7
        lda     #$FF
        jmp     jump_relay

LA6F7:  jsr     LB9B8
        return  #$FF
.endproc

;;; Key handler for prompt dialog

.proc prompt_key_handler
        lda     event_modifiers
        cmp     #MGTK::event_modifier_solid_apple
        bne     no_mods

        ;; Modifier key down.
        lda     event_key
        and     #CHAR_MASK
        cmp     #CHAR_LEFT
        bne     :+
        jmp     left_with_mod

:       cmp     #CHAR_RIGHT
        bne     done
        jmp     right_with_mod

done:   return  #$FF

        ;; No modifier key down.
no_mods:
        lda     event_key
        and     #CHAR_MASK

        cmp     #CHAR_LEFT
        bne     LA72E
        bit     format_erase_overlay_flag
        bpl     :+
        jmp     format_erase_overlay_prompt_handle_key_left
:       jmp     handle_key_left

LA72E:  cmp     #CHAR_RIGHT
        bne     LA73D
        bit     format_erase_overlay_flag
        bpl     :+
        jmp     format_erase_overlay_prompt_handle_key_right
:       jmp     handle_key_right

LA73D:  cmp     #CHAR_RETURN
        bne     LA749
        bit     LD8E7
        bvs     done
        jmp     LA851

LA749:  cmp     #CHAR_ESCAPE
        bne     LA755
        bit     LD8E7
        bmi     done
        jmp     LA86F

LA755:  cmp     #CHAR_DELETE
        bne     LA75C
        jmp     LA88D

LA75C:  cmp     #CHAR_UP
        bne     LA76B
        bit     format_erase_overlay_flag
        bmi     :+
        jmp     done
:       jmp     format_erase_overlay_prompt_handle_key_up

LA76B:  cmp     #CHAR_DOWN
        bne     LA77A
        bit     format_erase_overlay_flag
        bmi     :+
        jmp     done
:       jmp     format_erase_overlay_prompt_handle_key_down

LA77A:  bit     LD8E7
        bvc     LA79B
        cmp     #'Y'
        beq     do_yes
        cmp     #'y'
        beq     do_yes
        cmp     #'N'
        beq     do_no
        cmp     #'n'
        beq     do_no
        cmp     #'A'
        beq     do_all
        cmp     #'a'
        beq     do_all
        cmp     #CHAR_RETURN
        beq     do_yes

LA79B:  bit     LD8F5
        bmi     LA7C8
        cmp     #'.'
        beq     LA7D8
        cmp     #'0'
        bcs     LA7AB
        jmp     done

LA7AB:  cmp     #'z'+1
        bcc     LA7B2
        jmp     done

LA7B2:  cmp     #'9'+1
        bcc     LA7D8
        cmp     #'A'
        bcs     LA7BD
        jmp     done

LA7BD:  cmp     #'Z'+1
        bcc     LA7DD
        cmp     #'a'
        bcs     LA7DD
        jmp     done

LA7C8:  cmp     #' '
        bcs     LA7CF
        jmp     done

LA7CF:  cmp     #'~'
        beq     LA7DD
        bcc     LA7DD
        jmp     done

LA7D8:  ldx     path_buf1
        beq     LA7E5
LA7DD:  ldx     has_input_field_flag
        beq     LA7E5
        jsr     LBB0B
LA7E5:  return  #$FF

do_yes: jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::PaintRect, aux::yes_button_rect
        return  #PromptResult::yes

do_no:  jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::PaintRect, aux::no_button_rect
        return  #PromptResult::no

do_all: jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::PaintRect, aux::all_button_rect
        return  #PromptResult::all

.proc left_with_mod
        lda     has_input_field_flag
        beq     :+
        jsr     input_field_ip_start
:       return  #$FF
.endproc

.proc right_with_mod
        lda     has_input_field_flag
        beq     :+
        jsr     input_field_ip_end
:       return  #$FF
.endproc

.proc handle_key_left
        lda     has_input_field_flag
        beq     done
        bit     format_erase_overlay_flag ; BUG? Should never be set here based on caller test.
        bpl     :+
        jmp     format_erase_overlay_prompt_handle_key_right

:       jsr     input_field_ip_left
done:   return  #$FF
.endproc

.proc handle_key_right
        lda     has_input_field_flag
        beq     done
        bit     format_erase_overlay_flag ; BUG? Should never be set here based on caller test.
        bpl     :+
        jmp     format_erase_overlay_prompt_handle_key_left

:       jsr     input_field_ip_right
done:   return  #$FF
.endproc

LA851:  lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        return  #0

LA86F:  lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        return  #1

LA88D:  lda     has_input_field_flag
        beq     LA895
        jsr     LBB63
LA895:  return  #$FF
.endproc

rts1:
        rts

;;; ============================================================

jump_relay:
        jmp     dummy0000


;;; ============================================================
;;; "About" dialog

.proc about_dialog_proc
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_about_dialog
        lda     winfo_about_dialog::window_id
        jsr     set_port_from_window_id
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, aux::about_dialog_outer_rect
        MGTK_RELAY_CALL MGTK::FrameRect, aux::about_dialog_inner_rect
        addr_call draw_dialog_title, aux::str_about1
        yax_call draw_dialog_label, 1 | DDL_CENTER, aux::str_about2
        yax_call draw_dialog_label, 2 | DDL_CENTER, aux::str_about3
        yax_call draw_dialog_label, 3 | DDL_CENTER, aux::str_about4
        yax_call draw_dialog_label, 5, aux::str_about5
        yax_call draw_dialog_label, 6 | DDL_CENTER, aux::str_about6
        yax_call draw_dialog_label, 7, aux::str_about7
        yax_call draw_dialog_label, 9, aux::str_about8
        copy16  #310 - (7 * .strlen(kDeskTopVersionSuffix)), dialog_label_pos
        yax_call draw_dialog_label, 9, aux::str_about9
        copy16  #kDialogLabelDefaultX, dialog_label_pos

:       MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        beq     close
        cmp     #MGTK::EventKind::key_down
        bne     :-
        lda     event_key
        and     #CHAR_MASK
        cmp     #CHAR_ESCAPE
        beq     close
        cmp     #CHAR_RETURN
        bne     :-
        jmp     close

close:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo_about_dialog
        jsr     reset_main_grafport
        jsr     set_cursor_pointer_with_flag
        rts
.endproc

;;; ============================================================

.proc copy_dialog_proc
        ptr := $6

        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     (ptr),y

        cmp     #CopyDialogLifecycle::populate
        bne     :+
        jmp     do1
:       cmp     #CopyDialogLifecycle::show
        bne     :+
        jmp     do2
:       cmp     #CopyDialogLifecycle::exists
        bne     :+
        jmp     do3
:       cmp     #CopyDialogLifecycle::too_large
        bne     :+
        jmp     do4
:       cmp     #CopyDialogLifecycle::close
        bne     :+
        jmp     do5

        ;; CopyDialogLifecycle::open
:       copy    #0, has_input_field_flag
        jsr     open_dialog_window

        yax_call draw_dialog_label, 2, aux::str_copy_from
        yax_call draw_dialog_label, 3, aux::str_copy_to
        bit     move_flag
        bmi     :+
        addr_call draw_dialog_title, aux::str_copy_title
        yax_call draw_dialog_label, 1, aux::str_copy_copying
        yax_call draw_dialog_label, 4, aux::str_copy_remaining
        rts
:       addr_call draw_dialog_title, aux::str_move_title
        yax_call draw_dialog_label, 1, aux::str_move_moving
        yax_call draw_dialog_label, 4, aux::str_move_remaining
        rts

        ;; CopyDialogLifecycle::populate
do1:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        MGTK_RELAY_CALL MGTK::MoveTo, aux::copy_file_count_pos
        addr_call draw_text1, str_file_count
        addr_call draw_text1, str_files
        rts

        ;; CopyDialogLifecycle::exists
do2:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     clear_target_file_rect
        jsr     clear_dest_file_rect
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$03
        lda     (ptr),y
        tax
        iny
        lda     (ptr),y
        sta     ptr+1
        stx     ptr
        jsr     copy_name_to_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$05
        lda     (ptr),y
        tax
        iny
        lda     (ptr),y
        sta     ptr+1
        stx     ptr
        jsr     copy_name_to_buf1
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_dest_file_pos
        addr_call draw_text1, path_buf1
        yax_call MGTK_RELAY, MGTK::MoveTo, aux::copy_file_count_pos2
        addr_call draw_text1, str_file_count
        rts

        ;; CopyDialogLifecycle::close
do5:    jsr     close_prompt_dialog
        jsr     set_cursor_pointer
        rts

        ;; CopyDialogLifecycle::exists
do3:    jsr     Bell
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        yax_call draw_dialog_label, 6, aux::str_exists_prompt
        jsr     draw_yes_no_all_cancel_buttons
LAA7F:  jsr     prompt_input_loop
        bmi     LAA7F
        pha
        jsr     erase_yes_no_all_cancel_buttons
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::prompt_rect
        pla
        rts

        ;; CopyDialogLifecycle::too_large
do4:    jsr     Bell
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        yax_call draw_dialog_label, 6, aux::str_large_prompt
        jsr     draw_ok_cancel_buttons
:       jsr     prompt_input_loop
        bmi     :-
        pha
        jsr     erase_ok_cancel_buttons
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::prompt_rect
        pla
        rts
.endproc

;;; ============================================================
;;; "DownLoad" dialog

.proc download_dialog_proc
        ptr := $6

        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     (ptr),y
        cmp     #1
        bne     :+
        jmp     do1
:       cmp     #2
        bne     :+
        jmp     do2
:       cmp     #3
        bne     :+
        jmp     do3
:       cmp     #4
        bne     else
        jmp     do4

else:   copy    #0, has_input_field_flag
        jsr     open_dialog_window
        addr_call draw_dialog_title, aux::str_download
        yax_call draw_dialog_label, 1, aux::str_copy_copying
        yax_call draw_dialog_label, 2, aux::str_copy_from
        yax_call draw_dialog_label, 3, aux::str_copy_to
        yax_call draw_dialog_label, 4, aux::str_copy_remaining
        rts

do1:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        MGTK_RELAY_CALL MGTK::MoveTo, aux::copy_file_count_pos
        addr_call draw_text1, str_file_count
        addr_call draw_text1, str_files
        rts

do2:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     clear_target_file_rect
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #3
        lda     (ptr),y
        tax
        iny
        lda     (ptr),y
        sta     ptr+1
        stx     ptr
        jsr     copy_name_to_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::copy_file_count_pos2
        addr_call draw_text1, str_file_count
        rts

do3:    jsr     close_prompt_dialog
        jsr     set_cursor_pointer
        rts

do4:    jsr     Bell
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        yax_call draw_dialog_label, 6, aux::str_ramcard_full
        jsr     draw_ok_button
:       jsr     prompt_input_loop
        bmi     :-
        pha
        jsr     erase_ok_button
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::prompt_rect
        pla
        rts
.endproc

;;; ============================================================
;;; "Get Size" dialog

.proc get_size_dialog_proc
        ptr := $6

        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     (ptr),y
        cmp     #1
        bne     :+
        jmp     do1
:       cmp     #2
        bne     :+
        jmp     do2
:       cmp     #3
        bne     else
        jmp     do3

else:   jsr     open_dialog_window
        addr_call draw_dialog_title, aux::str_size_title
        yax_call draw_dialog_label, 1, aux::str_size_number
        ldy     #1
        jsr     draw_colon
        yax_call draw_dialog_label, 2, aux::str_size_blocks
        ldy     #2
        jsr     draw_colon
        rts

do1:    ldy     #1
        lda     (ptr),y
        sta     file_count
        tax
        iny
        lda     (ptr),y
        sta     ptr+1
        stx     ptr
        ldy     #0
        copy16in (ptr),y, file_count
        jsr     compose_file_count_string
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        copy    #165, dialog_label_pos
        yax_call draw_dialog_label, 1, str_file_count
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #3
        lda     (ptr),y
        tax
        iny
        lda     (ptr),y
        sta     ptr+1
        stx     ptr
        ldy     #0
        copy16in (ptr),y, file_count
        jsr     compose_file_count_string
        copy    #165, dialog_label_pos
        yax_call draw_dialog_label, 2, str_file_count
        rts

do3:    jsr     close_prompt_dialog
        jsr     set_cursor_pointer
        rts

do2:    lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     draw_ok_button
:       jsr     prompt_input_loop
        bmi     :-
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        jsr     erase_ok_button
        return  #0
.endproc

;;; ============================================================
;;; "Delete File" dialog

.proc delete_dialog_proc
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     ($06),y         ; phase

        cmp     #DeleteDialogLifecycle::populate
        bne     :+
        jmp     do1
:       cmp     #DeleteDialogLifecycle::confirm
        bne     :+
        jmp     do2
:       cmp     #DeleteDialogLifecycle::show
        bne     :+
        jmp     do3
:       cmp     #DeleteDialogLifecycle::locked
        bne     :+
        jmp     do4
:       cmp     #DeleteDialogLifecycle::close
        bne     :+
        jmp     do5

        ;; DeleteDialogLifecycle::open or trash
:       sta     LAD1F
        copy    #0, has_input_field_flag
        jsr     open_dialog_window
        addr_call draw_dialog_title, aux::str_delete_title
        lda     LAD1F
        beq     LAD20
        yax_call draw_dialog_label, 4, aux::str_ok_empty
        rts

LAD1F:  .byte   0
LAD20:  yax_call draw_dialog_label, 4, aux::str_delete_ok
        rts

        ;; DeleteDialogLifecycle::populate
do1:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        lda     LAD1F
        bne     LAD54
        MGTK_RELAY_CALL MGTK::MoveTo, aux::delete_file_count_pos
        jmp     LAD5D

LAD54:  MGTK_RELAY_CALL MGTK::MoveTo, aux::delete_file_count_pos2
LAD5D:  addr_call draw_text1, str_file_count
        addr_call draw_text1, str_files
        rts

        ;; DeleteDialogLifecycle::show
do3:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     clear_target_file_rect
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #3
        lda     ($06),y
        tax
        iny
        lda     ($06),y
        sta     $06+1
        stx     $06
        jsr     copy_name_to_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::delete_remaining_count_pos
        addr_call draw_text1, str_file_count
        rts

        ;; DeleteDialogLifecycle::confirm
do2:    lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     draw_ok_cancel_buttons
LADC4:  jsr     prompt_input_loop
        bmi     LADC4
        bne     LADF4
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        jsr     erase_ok_cancel_buttons
        yax_call draw_dialog_label, 2, aux::str_file_colon
        yax_call draw_dialog_label, 4, aux::str_delete_remaining
        lda     #$00
LADF4:  rts

        ;; DeleteDialogLifecycle::close
do5:    jsr     close_prompt_dialog
        jsr     set_cursor_pointer
        rts

        ;; DeleteDialogLifecycle::locked
do4:    lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        yax_call draw_dialog_label, 6, aux::str_delete_locked_file
        jsr     draw_yes_no_all_cancel_buttons
LAE17:  jsr     prompt_input_loop
        bmi     LAE17
        pha
        jsr     erase_yes_no_all_cancel_buttons
        jsr     set_penmode_copy ; white
        MGTK_RELAY_CALL MGTK::PaintRect, aux::prompt_rect ; erase prompt
        pla
        rts
.endproc

;;; ============================================================
;;; "New Folder" dialog

.proc new_folder_dialog_proc
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     ($06),y
        cmp     #$80
        bne     LAE42
        jmp     LAE70

LAE42:  cmp     #$40
        bne     LAE49
        jmp     LAF16

LAE49:  copy    #$80, has_input_field_flag
        jsr     clear_path_buf2
        lda     #$00
        jsr     open_prompt_window
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        addr_call draw_dialog_title, aux::str_new_folder_title
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, name_input_rect
        rts

LAE70:  copy    #$80, has_input_field_flag
        copy    #0, LD8E7
        jsr     clear_path_buf1
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #1
        copy16in ($06),y, $08
        ldy     #0
        lda     ($08),y
        tay
LAE90:  lda     ($08),y
        sta     path_buf0,y
        dey
        bpl     LAE90
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        yax_call draw_dialog_label, 2, aux::str_in_colon
        copy    #55, dialog_label_pos
        yax_call draw_dialog_label, 2, path_buf0
        copy    #kDialogLabelDefaultX, dialog_label_pos
        yax_call draw_dialog_label, 4, aux::str_enter_folder_name
        jsr     draw_filename_prompt
LAEC6:  jsr     prompt_input_loop
        bmi     LAEC6
        bne     LAF16
        jsr     merge_path_buf1_path_buf2
        lda     path_buf1
        beq     LAEC6
        cmp     #16             ; max filename length
        bcc     LAEE1
LAED6:  lda     #kErrNameTooLong
        jsr     JT_SHOW_ALERT0
        jsr     draw_filename_prompt
        jmp     LAEC6

LAEE1:  lda     path_buf0
        clc
        adc     path_buf1
        clc
        adc     #1
        cmp     #::kPathBufferSize
        bcs     LAED6
        inc     path_buf0
        ldx     path_buf0
        copy    #'/', path_buf0,x
        ldx     path_buf0
        ldy     #0
LAEFF:  inx
        iny
        copy    path_buf1,y, path_buf0,x
        cpy     path_buf1
        bne     LAEFF
        stx     path_buf0
        ldy     #<path_buf0
        ldx     #>path_buf0
        return  #0

LAF16:  jsr     close_prompt_dialog
        jsr     set_cursor_pointer
        return  #1
.endproc

;;; ============================================================
;;; "Get Info" dialog

.proc get_info_dialog_proc
        ptr := $6

        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     (ptr),y
        bmi     prepare_window
        jmp     populate_value

        ;; Draw the field labels (e.g. "Size:")
prepare_window:
        copy    #0, has_input_field_flag
        lda     (ptr),y
        lsr     a               ; bit 1 set if multiple
        lsr     a               ; so configure buttons appropriately
        ror     a
        eor     #$80
        jsr     open_prompt_window
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id

        addr_call draw_dialog_title, aux::str_info_title
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     (ptr),y
        and     #$7F
        lsr     a
        ror     a
        sta     is_volume_flag

        ;; Draw labels
        yax_call draw_dialog_label, 1, aux::str_info_name

        ;; Locked (file) or Protected (volume)
        bit     is_volume_flag
        bmi     :+
        yax_call draw_dialog_label, 2, aux::str_info_locked
        jmp     draw_size_label
:       yax_call draw_dialog_label, 2, aux::str_info_protected

        ;; Blocks (file) or Size (volume)
draw_size_label:
        bit     is_volume_flag
        bpl     :+
        yax_call draw_dialog_label, 3, aux::str_info_blocks
        jmp     draw_final_labels
:       yax_call draw_dialog_label, 3, aux::str_info_size

draw_final_labels:
        yax_call draw_dialog_label, 4, aux::str_info_create
        yax_call draw_dialog_label, 5, aux::str_info_mod
        yax_call draw_dialog_label, 6, aux::str_info_type
        jmp     reset_main_grafport

        ;; Draw a specific value
populate_value:
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        copy    (ptr),y, row
        tay
        jsr     draw_colon
        copy    #165, dialog_label_pos
        jsr     copy_dialog_param_addr_to_ptr

        ;; Draw the string at addr
        ldy     #2
        lda     (ptr),y
        tax
        dey
        lda     (ptr),y
LAFF8:  ldy     row
        jsr     draw_dialog_label

        ;; If not 6 (the last one), run modal loop
        lda     row
        cmp     #GetInfoDialogState::type
        beq     :+
        rts

:       jsr     prompt_input_loop
        bmi     :-

        pha
        jsr     close_prompt_dialog
        jsr     set_cursor_pointer_with_flag
        pla
        rts

is_volume_flag:
        .byte   0               ; high bit set if volume, clear if file

row:    .byte   0
.endproc

;;; ============================================================
;;; Draw ":" after dialog label

.proc draw_colon
        copy    #160, dialog_label_pos
        addr_call draw_dialog_label, aux::str_colon
        rts
.endproc

;;; ============================================================
;;; "Lock" dialog

.proc lock_dialog_proc
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     ($06),y

        cmp     #LockDialogLifecycle::populate
        bne     :+
        jmp     do1
:       cmp     #LockDialogLifecycle::loop
        bne     :+
        jmp     do2
:       cmp     #LockDialogLifecycle::operation
        bne     :+
        jmp     do3
:       cmp     #LockDialogLifecycle::close
        bne     :+
        jmp     do4

        ;; LockDialogLifecycle::open
:       copy    #0, has_input_field_flag
        jsr     open_dialog_window
        addr_call draw_dialog_title, aux::str_lock_title
        yax_call draw_dialog_label, 4, aux::str_lock_ok
        rts

        ;; LockDialogLifecycle::populate
do1:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        MGTK_RELAY_CALL MGTK::MoveTo, aux::lock_remaining_count_pos2
        addr_call draw_text1, str_file_count
        MGTK_RELAY_CALL MGTK::MoveTo, aux::files_pos2
        addr_call draw_text1, str_files
        rts

        ;; LockDialogLifecycle::operation
do3:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     clear_target_file_rect
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #3
        lda     ($06),y
        tax
        iny
        lda     ($06),y
        sta     $06+1
        stx     $06
        jsr     copy_name_to_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::lock_remaining_count_pos
        addr_call draw_text1, str_file_count
        rts

        ;; LockDialogLifecycle::loop
do2:    lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     draw_ok_cancel_buttons
LB0FA:  jsr     prompt_input_loop
        bmi     LB0FA
        bne     LB139
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        yax_call draw_dialog_label, 2, aux::str_file_colon
        yax_call draw_dialog_label, 4, aux::str_lock_remaining
        lda     #$00
LB139:  rts

        ;; LockDialogLifecycle::close
do4:    jsr     close_prompt_dialog
        jsr     set_cursor_pointer
        rts
.endproc

;;; ============================================================
;;; "Unlock" dialog

.proc unlock_dialog_proc
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     ($06),y

        cmp     #LockDialogLifecycle::populate
        bne     :+
        jmp     do1
:       cmp     #LockDialogLifecycle::loop
        bne     :+
        jmp     do2
:       cmp     #LockDialogLifecycle::operation
        bne     :+
        jmp     do3
:       cmp     #LockDialogLifecycle::close
        bne     :+
        jmp     do4

        ;; LockDialogLifecycle::open
:       copy    #0, has_input_field_flag
        jsr     open_dialog_window
        addr_call draw_dialog_title, aux::str_unlock_title
        yax_call draw_dialog_label, 4, aux::str_unlock_ok
        rts

        ;; LockDialogLifecycle::populate
do1:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        MGTK_RELAY_CALL MGTK::MoveTo, aux::unlock_remaining_count_pos2
        addr_call draw_text1, str_file_count
        MGTK_RELAY_CALL MGTK::MoveTo, aux::files_pos
        addr_call draw_text1, str_files
        rts

        ;; LockDialogLifecycle::operation
do3:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     clear_target_file_rect
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #3
        lda     ($06),y
        tax
        iny
        lda     ($06),y
        sta     $06+1
        stx     $06
        jsr     copy_name_to_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::unlock_remaining_count_pos
        addr_call draw_text1, str_file_count
        rts

        ;; LockDialogLifecycle::loop
do2:    lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     draw_ok_cancel_buttons
LB218:  jsr     prompt_input_loop
        bmi     LB218
        bne     LB257
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        yax_call draw_dialog_label, 2, aux::str_file_colon
        yax_call draw_dialog_label, 4, aux::str_unlock_remaining
        lda     #$00
LB257:  rts

        ;; LockDialogLifecycle::close
do4:    jsr     close_prompt_dialog
        jsr     set_cursor_pointer
        rts
.endproc

;;; ============================================================
;;; "Rename" dialog

.proc rename_dialog_proc
        params_ptr := $06

        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     (params_ptr),y
        cmp     #RenameDialogState::run
        bne     :+
        jmp     run_loop

:       cmp     #RenameDialogState::close
        bne     open_win
        jmp     close_win

open_win:
        jsr     copy_dialog_param_addr_to_ptr
        copy    #$80, has_input_field_flag
        lda     #$00
        jsr     open_prompt_window
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        addr_call draw_dialog_title, aux::str_rename_title
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, name_input_rect
        yax_call draw_dialog_label, 2, aux::str_rename_old
        copy    #85, dialog_label_pos
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #1              ; rename_dialog_params::addr offset
        copy16in ($06),y, $08

        ;; Populate filename field and input (before IP)
        ldy     #0
        lda     ($08),y
        tay
:       lda     ($08),y
        sta     buf_filename,y
        sta     path_buf1,y
        dey
        bpl     :-

        ;; Clear input (after IP)
        jsr     clear_path_buf2

        yax_call draw_dialog_label, 2, buf_filename
        yax_call draw_dialog_label, 4, aux::str_rename_new
        jsr     draw_filename_prompt
        rts

run_loop:
        copy16  #$8000, LD8E7
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
:       jsr     prompt_input_loop
        bmi     :-              ; continue?

        bne     close_win       ; canceled!

        jsr     input_field_ip_end ; collapse name

        lda     path_buf1
        beq     :-              ; name is empty, retry

        ldy     #<path_buf1
        ldx     #>path_buf1
        return  #0

close_win:
        jsr     close_prompt_dialog
        jsr     set_cursor_pointer
        return  #1
.endproc

;;; ============================================================
;;; "Warning!" dialog
;;; $6 ptr to message num

kNumWarningTypes = 7

kWarningMsgInsertSystemDisk     = 0
kWarningMsgSelectorListFull     = 1
kWarningMsgSelectorListFull2    = 2
kWarningMsgWindowMustBeClosed   = 3
kWarningMsgWindowMustBeClosed2  = 4
kWarningMsgTooManyWindows       = 5
kWarningMsgSaveSelectorList     = 6

.proc warning_dialog_proc
        ptr := $6

        ;; Create window
        MGTK_RELAY_CALL MGTK::HideCursor
        jsr     open_alert_window
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        addr_call draw_dialog_title, aux::str_warning
        MGTK_RELAY_CALL MGTK::ShowCursor
        jsr     copy_dialog_param_addr_to_ptr

        ;; Dig up message
        ldy     #0
        lda     (ptr),y
        pha
        bmi     only_ok         ; high bit set means no cancel
        tax
        lda     warning_cancel_table,x
        bne     ok_and_cancel

only_ok:                        ; no cancel button
        pla
        and     #$7F
        pha
        jsr     draw_ok_button
        jmp     draw_string

ok_and_cancel:                  ; has cancel button
        jsr     draw_ok_cancel_buttons

draw_string:
        ;; First string
        pla
        pha
        asl     a               ; * 2
        asl     a               ; * 4, since there are two strings each
        tay
        lda     warning_message_table+1,y
        tax
        lda     warning_message_table,y
        ldy     #3              ; row
        jsr     draw_dialog_label

        ;; Second string
        pla
        asl     a
        asl     a
        tay
        lda     warning_message_table+2+1,y
        tax
        lda     warning_message_table+2,y
        ldy     #4              ; row
        jsr     draw_dialog_label

        ;; Input loop
:       jsr     prompt_input_loop
        bmi     :-

        pha
        jsr     close_prompt_dialog
        jsr     set_cursor_pointer
        pla
        rts

        ;; high bit set if "cancel" should be an option
warning_cancel_table:
        .byte   $80,$00,$00,$80,$00,$00,$80
        ASSERT_TABLE_SIZE warning_cancel_table, main::kNumWarningTypes

        ;; First line / second line of message.
warning_message_table:
        .addr   aux::str_insert_system_disk, aux::str_blank
        .addr   aux::str_selector_list_full, aux::str_selector_list_full2
        .addr   aux::str_selector_list_full, aux::str_selector_list_full2
        .addr   aux::str_window_must_be_closed, aux::str_blank
        .addr   aux::str_window_must_be_closed, aux::str_blank
        .addr   aux::str_too_many_windows, aux::str_blank
        .addr   aux::str_save_selector_list, aux::str_save_selector_list2
        ASSERT_RECORD_TABLE_SIZE warning_message_table, main::kNumWarningTypes, 4
.endproc

;;; ============================================================

.proc copy_dialog_param_addr_to_ptr
        copy16  dialog_param_addr, $06
        rts
.endproc

;;; ============================================================

.proc set_cursor_pointer_with_flag
        bit     cursor_ibeam_flag
        bpl     :+
        jsr     set_cursor_pointer
        copy    #0, cursor_ibeam_flag
:       rts
.endproc

.proc set_cursor_ibeam_with_flag
        bit     cursor_ibeam_flag
        bmi     :+
        jsr     set_cursor_ibeam
        copy    #$80, cursor_ibeam_flag
:       rts
.endproc

cursor_ibeam_flag:          ; high bit set if I-beam, clear if pointer
        .byte   0

;;; ============================================================
;;;
;;; Routines beyond this point are used by overlays
;;;
;;; ============================================================

        .assert * >= $A000, error, "Routine used by overlays in overlay zone"


;;; ============================================================

.proc set_cursor_watch
        jsr     hide_cursor
        MGTK_RELAY_CALL MGTK::SetCursor, watch_cursor
        jmp     show_cursor
.endproc

.proc set_cursor_pointer
        jsr     hide_cursor
        MGTK_RELAY_CALL MGTK::SetCursor, pointer_cursor
        jmp     show_cursor
.endproc

.proc set_cursor_ibeam
        jsr     hide_cursor
        MGTK_RELAY_CALL MGTK::SetCursor, ibeam_cursor
        jmp     show_cursor
.endproc

.proc hide_cursor
        MGTK_RELAY_CALL MGTK::HideCursor
        rts
.endproc

.proc show_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================
;;; Double Click Detection
;;; Returns with A=0 if double click, A=$FF otherwise.

.proc detect_double_click
        ;; Stash initial coords
        ldx     #.sizeof(MGTK::Point)-1
:       copy    event_coords,x, coords,x
        sta     drag_drop_params::coords,x ; for double-click in windows

        dex
        bpl     :-

        copy16  SETTINGS + DeskTopSettings::dblclick_speed, counter

        ;; Decrement counter, bail if time delta exceeded
loop:   dec16   counter
        lda     counter
        ora     counter+1
        beq     exit

        MGTK_RELAY_CALL MGTK::PeekEvent, event_params

        ;; Check coords, bail if pixel delta exceeded
        jsr     check_delta
        bmi     exit            ; moved past delta; no double-click

        lda     event_kind
        cmp     #MGTK::EventKind::no_event
        beq     loop
        cmp     #MGTK::EventKind::drag
        beq     loop
        cmp     #MGTK::EventKind::button_up
        bne     :+

        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        jmp     loop

:       cmp     #MGTK::EventKind::button_down
        beq     :+
        cmp     #MGTK::EventKind::apple_key ; modified-click
        bne     exit

:       MGTK_RELAY_CALL MGTK::GetEvent, event_params
        return  #0              ; double-click

exit:   return  #$FF            ; not double-click

        ;; Is the new coord within range of the old coord?
.proc check_delta
        ;; compute x delta
        lda     event_xcoord
        sec
        sbc     xcoord
        sta     delta
        lda     event_xcoord+1
        sbc     xcoord+1
        bpl     :+

        ;; is -delta < x < 0 ?
        lda     delta
        cmp     #AS_BYTE(-kDoubleClickDeltaX)
        bcs     check_y
fail:   return  #$FF

        ;; is 0 < x < delta ?
:       lda     delta
        cmp     #kDoubleClickDeltaX
        bcs     fail

        ;; compute y delta
check_y:
        lda     event_ycoord
        sec
        sbc     ycoord
        sta     delta
        lda     event_ycoord+1
        sbc     ycoord+1
        bpl     :+

        ;; is -delta < y < 0 ?
        lda     delta
        cmp     #AS_BYTE(-kDoubleClickDeltaY)
        bcs     ok

        ;; is 0 < y < delta ?
:       lda     delta
        cmp     #kDoubleClickDeltaY
        bcs     fail
ok:     return  #0
.endproc

counter:
        .word   0
coords:
xcoord: .word   0
ycoord: .word   0
delta:  .byte   0
.endproc

;;; ============================================================

.proc open_prompt_window
        sta     LD8E7
        jsr     open_dialog_window
        bit     LD8E7
        bvc     :+
        jsr     draw_yes_no_all_cancel_buttons
        jmp     no_ok

:       MGTK_RELAY_CALL MGTK::FrameRect, aux::ok_button_rect
        jsr     draw_ok_label
no_ok:  bit     LD8E7
        bmi     done
        MGTK_RELAY_CALL MGTK::FrameRect, aux::cancel_button_rect
        jsr     draw_cancel_label
done:   jmp     reset_main_grafport
.endproc

;;; ============================================================

.proc open_dialog_window
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_prompt_dialog
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, aux::confirm_dialog_outer_rect
        MGTK_RELAY_CALL MGTK::FrameRect, aux::confirm_dialog_inner_rect
        rts
.endproc

;;; ============================================================

.proc open_alert_window
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_prompt_dialog
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintBits, aux::Alert::alert_bitmap_params
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, aux::confirm_dialog_outer_rect
        MGTK_RELAY_CALL MGTK::FrameRect, aux::confirm_dialog_inner_rect
        rts
.endproc

;;; ============================================================

;;; Draw dialog label.
;;; A,X has pointer to DrawText params block
;;; Y has row number (1, 2, ... ) with high bit to center it

        DDL_CENTER = $80

.proc draw_dialog_label
        textwidth_params := $8
        textptr := $8
        textlen := $A
        result  := $B

        ptr := $6

        stx     ptr+1
        sta     ptr
        tya
        bmi     :+
        jmp     skip

        ;; Compute text width and center it
:       and     #$7F            ; strip "center?" flag
        pha
        add16   ptr, #1, textptr
        ldax    ptr
        jsr     AuxLoad
        sta     textlen
        MGTK_RELAY_CALL MGTK::TextWidth, textwidth_params
        lsr16   result
        sub16   #200, result, dialog_label_pos
        pla

        ;; y = base + aux::kDialogLabelHeight * line
skip:   ldx     #0
        ldy     #aux::kDialogLabelHeight
        jsr     Multiply_16_8_16
        stax    dialog_label_pos::ycoord
        add16   dialog_label_pos::ycoord, dialog_label_base_pos::ycoord, dialog_label_pos::ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, dialog_label_pos
        addr_call_indirect draw_text1, ptr
        ldx     dialog_label_pos
        copy    #kDialogLabelDefaultX,dialog_label_pos::xcoord ; restore original x coord
        rts
.endproc

;;; ============================================================

draw_ok_label:
        MGTK_RELAY_CALL MGTK::MoveTo, aux::ok_label_pos
        addr_call draw_text1, aux::str_ok_label
        rts

draw_cancel_label:
        MGTK_RELAY_CALL MGTK::MoveTo, aux::cancel_label_pos
        addr_call draw_text1, aux::str_cancel_label
        rts

draw_yes_label:
        MGTK_RELAY_CALL MGTK::MoveTo, aux::yes_label_pos
        addr_call draw_text1, aux::str_yes_label
        rts

draw_no_label:
        MGTK_RELAY_CALL MGTK::MoveTo, aux::no_label_pos
        addr_call draw_text1, aux::str_no_label
        rts

draw_all_label:
        MGTK_RELAY_CALL MGTK::MoveTo, aux::all_label_pos
        addr_call draw_text1, aux::str_all_label
        rts

draw_yes_no_all_cancel_buttons:
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, aux::yes_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, aux::no_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, aux::all_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, aux::cancel_button_rect
        jsr     draw_yes_label
        jsr     draw_no_label
        jsr     draw_all_label
        jsr     draw_cancel_label
        copy    #$40, LD8E7
        rts

erase_yes_no_all_cancel_buttons:
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::yes_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::no_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::all_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        rts

draw_ok_cancel_buttons:
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, aux::cancel_button_rect
        jsr     draw_ok_label
        jsr     draw_cancel_label
        copy    #$00, LD8E7
        rts

erase_ok_cancel_buttons:
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        rts

draw_ok_button:
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, aux::ok_button_rect
        jsr     draw_ok_label
        copy    #$80, LD8E7
        rts

erase_ok_button:
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        rts

;;; ============================================================

.proc draw_text1
        params := $6
        textptr := $6
        textlen := $8

        stax    textptr
        jsr     AuxLoad
        beq     done
        sta     textlen
        inc16   textptr
        MGTK_RELAY_CALL MGTK::DrawText, params
done:   rts
.endproc

;;; ============================================================

.proc draw_dialog_title
        str       := $6
        str_data  := $6
        str_len   := $8
        str_width := $9

        stax    str             ; input is length-prefixed string
        jsr     AuxLoad
        sta     str_len
        inc16   str_data        ; point past length byte
        MGTK_RELAY_CALL MGTK::TextWidth, str
        lsr16   str_width       ; divide by two
        lda     #>400           ; center within 400px
        sta     hi
        lda     #<400
        lsr     hi              ; divide by two
        ror     a
        sec
        sbc     str_width
        sta     pos_dialog_title::xcoord
        lda     hi
        sbc     str_width+1
        sta     pos_dialog_title::xcoord+1
        MGTK_RELAY_CALL MGTK::MoveTo, pos_dialog_title
        MGTK_RELAY_CALL MGTK::DrawText, str
        rts

hi:  .byte   0
.endproc

;;; ============================================================
;;; Adjust filename case, using GS/OS bits or heuristics
;;; Per Technical Note: GS/OS #8: Filenames With More Than CAPS and Numerals
;;; http://www.1000bit.it/support/manuali/apple/technotes/gsos/tn.gsos.08.html

;;; adjust_fileeentry_case:
;;; Input: A,X points at FileEntry structure.
;;;
;;; adjust_volname_case:
;;; Input: A,X points at ON_LINE result (e.g. 'MY.DISK', length + 15 chars)

.proc adjust_case_impl

        volpath := $810
        volbuf  := $820
        DEFINE_OPEN_PARAMS volname_open_params, volpath, $1000
        DEFINE_READ_PARAMS volname_read_params, volbuf, .sizeof(VolumeDirectoryHeader)
        DEFINE_CLOSE_PARAMS volname_close_params

        ptr := $A

;;; --------------------------------------------------
;;; Called with volume name. Convert to path, load
;;; VolumeDirectoryHeader, use bytes $1A/$1B
vol_name:
        stax    ptr

        ;; Convert volume name to a path
        ldy     #0
        lda     (ptr),y
        sta     volpath
        tay
:       lda     (ptr),y
        sta     volpath+1,y
        dey
        bne     :-
        lda     #'/'
        sta     volpath+1
        inc     volpath

        MLI_RELAY_CALL OPEN, volname_open_params
        bne     fallback
        lda     volname_open_params::ref_num
        sta     volname_read_params::ref_num
        sta     volname_close_params::ref_num
        MLI_RELAY_CALL READ, volname_read_params
        bne     fallback
        MLI_RELAY_CALL CLOSE, volname_close_params

        copy16  volbuf + $1A, version_bytes
        jmp     common

;;; --------------------------------------------------
;;; Called with FileEntry. Copy version bytes directly.
file_entry:
        stax    ptr

        .assert FileEntry::file_name = 1, error, "bad assumptions in structure"

        ;; AppleWorks?
        ldy     #FileEntry::file_type
        lda     (ptr),y
        cmp     #FT_ADB
        beq     appleworks
        cmp     #FT_AWP
        beq     appleworks
        cmp     #FT_ASP
        beq     appleworks

        ldy     #FileEntry::version
        copy16in (ptr),y, version_bytes
        ;; fall through

common:
        asl16   version_bytes
        bcs     apply_bits      ; High bit set = GS/OS case bits present

;;; --------------------------------------------------
;;; GS/OS bits are not present; apply heuristics

fallback:
        ldy     #0
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        beq     done

        ;; Walk backwards through string. At char N, check char N-1
        ;; to see if it is a '.'. If it isn't, and char N is a letter,
        ;; lower-case it.
        tay

loop:   dey
        beq     done
        bpl     :+
done:   rts

:       lda     (ptr),y
        cmp     #'.'
        bne     check_alpha
        dey
        bpl     loop            ; always

check_alpha:
        iny
        lda     (ptr),y
        cmp     #'A'
        bcc     :+
        ora     #AS_BYTE(~CASE_MASK)
        sta     (ptr),y
:       dey
        bpl     loop            ; always

;;; --------------------------------------------------
;;; GS/OS bits are present - apply to recase string.
;;; Per Technical Note: GS/OS #8: Filenames With More Than CAPS and Numerals
;;; http://www.1000bit.it/support/manuali/apple/technotes/gsos/tn.gsos.08.html
;;;
;;; "If version is read as a word value, bit 7 of min_version would be the
;;; highest bit (bit 15) of the word. If that bit is set, the remaining 15
;;; bits of the word are interpreted as flags that indicate whether the
;;; corresponding character in the filename is uppercase or lowercase, with
;;; set indicating lowercase."

apply_bits:
        ldy     #1
@bloop: asl16   version_bytes   ; NOTE: Shift out high byte first
        bcc     :+
        lda     (ptr),y
        ora     #AS_BYTE(~CASE_MASK)
        sta     (ptr),y
:       iny
        cpy     #16
        bcc     @bloop
        rts

;;; --------------------------------------------------
;;; AppleWorks
;;; Per File Type Notes: File Type $19 (25) All Auxiliary Types
;;; http://www.1000bit.it/support/manuali/apple/technotes/ftyp/ftn.19.xxxx.html
;;; Per File Type Notes: File Type $1A (26) All Auxiliary Types
;;; http://www.1000bit.it/support/manuali/apple/technotes/ftyp/ftn.19.xxxx.html
;;; Per File Type Notes: File Type $1B (27) All Auxiliary Types
;;; http://www.1000bit.it/support/manuali/apple/technotes/ftyp/ftn.19.xxxx.html
;;;
;;; "The volume or subdirectory auxiliary type word for this file type is
;;; defined to control uppercase and lowercase display of filenames. The
;;; highest bit of the least significant byte corresponds to the first
;;; character of the filename, the next highest bit of the least significant
;;; byte corresponds to the second character, etc., through the second bit
;;; of the most significant byte, which corresponds to the fifteenth
;;; character of the filename."
;;;
;;; Same logic as GS/OS, just a different field and byte-swapped.
appleworks:
        ldy     #FileEntry::aux_type
        lda     (ptr),y
        sta     version_bytes+1
        iny
        lda     (ptr),y
        sta     version_bytes
        jmp     apply_bits

;;; --------------------------------------------------

version_bytes:
        .word   0
.endproc
        adjust_fileentry_case := adjust_case_impl::file_entry
        adjust_volname_case := adjust_case_impl::vol_name


;;; ============================================================

.proc noop
        rts
.endproc

;;; ============================================================

.proc redraw_prompt_insertion_point
        point := $6
        xcoord := $6
        ycoord := $8

        jsr     measure_path_buf1
        stax    xcoord
        copy16  name_input_textpos::ycoord, ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, point
        MGTK_RELAY_CALL MGTK::SetPortBits, name_input_mapinfo
        bit     prompt_ip_flag
        bpl     set_flag

clear_flag:
        MGTK_RELAY_CALL MGTK::SetTextBG, aux::textbg_black
        copy    #0, prompt_ip_flag
        beq     draw            ; always

set_flag:
        MGTK_RELAY_CALL MGTK::SetTextBG, aux::textbg_white
        copy    #$FF, prompt_ip_flag

        drawtext_params := $6
        textptr := $6
        textlen := $8

draw:   copy16  #str_insertion_point+1, textptr
        lda     str_insertion_point
        sta     textlen
        MGTK_RELAY_CALL MGTK::DrawText, drawtext_params
        MGTK_RELAY_CALL MGTK::SetTextBG, aux::textbg_white
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        rts
.endproc

;;; ============================================================

.proc draw_filename_prompt
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, name_input_rect
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, name_input_rect
        MGTK_RELAY_CALL MGTK::MoveTo, name_input_textpos
        MGTK_RELAY_CALL MGTK::SetPortBits, name_input_mapinfo
        addr_call draw_text1, path_buf1
        addr_call draw_text1, path_buf2
        addr_call draw_text1, str_2_spaces
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
done:   rts
.endproc

;;; ============================================================

.proc LB9B8
        ptr := $6

        textwidth_params  := $6
        textptr := $6
        textlen := $8
        result  := $9

        click_coords := screentowindow_windowx

        ;; Mouse coords to window coords; is click inside name field?
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, click_coords
        MGTK_RELAY_CALL MGTK::InRect, name_input_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        rts

        ;; Is it to the right of the text?
:       jsr     measure_path_buf1

        width := $6

        stax    width
        cmp16   click_coords, width
        bcs     to_right
        jmp     within_text

;;; --------------------------------------------------

        ;; Click is to the right of the text

.proc to_right
        jsr     measure_path_buf1
        stax    buf1_width
        ldx     path_buf2
        inx
        copy    #' ', path_buf2,x
        inc     path_buf2
        copy16  #path_buf2, textptr
        lda     path_buf2
        sta     ptr+2
LBA10:  MGTK_RELAY_CALL MGTK::TextWidth, textwidth_params
        add16   result, buf1_width, result
        cmp16   result, click_coords
        bcc     LBA42
        dec     textlen
        lda     textlen
        cmp     #1
        bne     LBA10
        dec     path_buf2
        jmp     draw_text

LBA42:
        lda     textlen
        cmp     path_buf2
        bcc     LBA4F
        dec     path_buf2
        jmp     input_field_ip_end

LBA4F:  ldx     #2
        ldy     path_buf1
        iny
LBA55:  lda     path_buf2,x
        sta     path_buf1,y
        cpx     textlen
        beq     LBA64
        iny
        inx
        jmp     LBA55

LBA64:  sty     path_buf1
        ldy     #2
        ldx     textlen
        inx
LBA6C:  lda     path_buf2,x
        sta     path_buf2,y
        cpx     path_buf2
        beq     LBA7C
        iny
        inx
        jmp     LBA6C

LBA7C:  dey
        sty     path_buf2
        jmp     draw_text
.endproc

;;; --------------------------------------------------

        ;; Click within text - loop to find where in the
        ;; name to split the string.

.proc within_text
        copy16  #path_buf1, textptr
        lda     path_buf1
        sta     textlen
:       MGTK_RELAY_CALL MGTK::TextWidth, textwidth_params
        add16 result, name_input_textpos::xcoord, result
        cmp16   result, click_coords
        bcc     :+
        dec     textlen
        lda     textlen
        cmp     #1
        bcs     :-
        jmp     input_field_ip_start

        ;; Copy the text to the right of the click to split_buf
:       inc     textlen
        ldy     #0
        ldx     textlen
:       cpx     path_buf1
        beq     :+
        inx
        iny
        lda     path_buf1,x
        sta     split_buf+1,y
        jmp     :-
:
        ;; Copy it (again) into path_buf2
        iny
        sty     split_buf
        ldx     #1
        ldy     split_buf
:       cpx     path_buf2
        beq     :+
        inx
        iny
        lda     path_buf2,x
        sta     split_buf,y
        jmp     :-
:

        sty     split_buf
        lda     str_insertion_point+1
        sta     split_buf+1
LBAF7:  lda     split_buf,y
        sta     path_buf2,y
        dey
        bpl     LBAF7
        lda     textlen
        sta     path_buf1
        ;; fall through
.endproc

draw_text:
        jsr     draw_filename_prompt
        rts

buf1_width:
        .word   0

.endproc

;;; ============================================================

.proc LBB0B
        sta     param
        lda     path_buf1
        clc
        adc     path_buf2
        cmp     #$10
        bcc     :+
        rts

        point := $6
        xcoord := $6
        ycoord := $8

:       lda     param
        ldx     path_buf1
        inx
        sta     path_buf1,x
        sta     str_1_char+1
        jsr     measure_path_buf1
        inc     path_buf1
        stax    xcoord
        copy16  name_input_textpos::ycoord, ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, point
        MGTK_RELAY_CALL MGTK::SetPortBits, name_input_mapinfo
        addr_call draw_text1, str_1_char
        addr_call draw_text1, path_buf2
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        rts

param:  .byte   0
.endproc

;;; ============================================================

.proc LBB63
        lda     path_buf1
        bne     :+
        rts

        point := $6
        xcoord := $6
        ycoord := $8

:       dec     path_buf1
        jsr     measure_path_buf1
        stax    xcoord
        copy16  name_input_textpos::ycoord, ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, point
        MGTK_RELAY_CALL MGTK::SetPortBits, name_input_mapinfo
        addr_call draw_text1, path_buf2
        addr_call draw_text1, str_2_spaces
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        rts
.endproc

;;; ============================================================
;;; Move IP one character left.

.proc input_field_ip_left
        ;; Any characters to left of IP?
        lda     path_buf1
        bne     :+
        rts

        point := $6
        xcoord := $6
        ycoord := $8

:       ldx     path_buf2
        cpx     #1
        beq     finish

        ;; Shift right up by a character.
loop:   lda     path_buf2,x
        sta     path_buf2+1,x
        dex
        cpx     #1
        bne     loop

        ;; Copy character left to right and adjust lengths.
finish: ldx     path_buf1
        lda     path_buf1,x
        sta     path_buf2+2
        dec     path_buf1
        inc     path_buf2

        ;; Redraw (just the right part)
        jsr     measure_path_buf1
        stax    xcoord
        copy16  name_input_textpos::ycoord, ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, point
        MGTK_RELAY_CALL MGTK::SetPortBits, name_input_mapinfo
        addr_call draw_text1, path_buf2
        addr_call draw_text1, str_2_spaces
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        rts
.endproc

;;; ============================================================
;;; Move IP one character right.

.proc input_field_ip_right
        ;; Any characters to right of IP?
        lda     path_buf2
        cmp     #2
        bcs     :+
        rts

        ;; Copy char from right to left and adjust lengths.
:       ldx     path_buf1
        inx
        lda     path_buf2+2
        sta     path_buf1,x
        inc     path_buf1
        ldx     path_buf2
        cpx     #3
        bcc     finish

        ;; Shift right string down.
        ldx     #2
loop:   lda     path_buf2+1,x
        sta     path_buf2,x
        inx
        cpx     path_buf2
        bne     loop

        ;; Redraw (the whole thing)
finish: dec     path_buf2

        MGTK_RELAY_CALL MGTK::MoveTo, name_input_textpos
        MGTK_RELAY_CALL MGTK::SetPortBits, name_input_mapinfo
        addr_call draw_text1, path_buf1
        addr_call draw_text1, path_buf2
        addr_call draw_text1, str_2_spaces
        lda     winfo_prompt_dialog
        jsr     set_port_from_window_id
        rts
.endproc

;;; ============================================================
;;; Move IP to start of input field.

.proc input_field_ip_start
        ;; Any characters to left of IP?
        lda     path_buf1
        bne     :+
        rts

        ;; Any characters to right of IP?
:       ldx     path_buf2
        cpx     #1
        beq     move

        ;; Preserve right characters up to make room.
        ;; TODO: Why not just shift them up???
loop1:  lda     path_buf2,x
        sta     split_buf-1,x
        dex
        cpx     #1
        bne     loop1
        ldx     path_buf2

        ;; Move characters left to right
move:   dex
        stx     split_buf
        ldx     path_buf1
loop2:  lda     path_buf1,x
        sta     path_buf2+1,x
        dex
        bne     loop2

        ;; Adjust lengths.
        lda     str_insertion_point+1
        sta     path_buf2+1
        inc     path_buf1
        lda     path_buf1
        sta     path_buf2
        lda     path_buf1
        clc
        adc     split_buf
        tay
        pha

        ;; Append right right characters again if needed.
        ldx     split_buf
        beq     finish
loop3:  lda     split_buf,x
        sta     path_buf2,y
        dex
        dey
        cpy     path_buf2
        bne     loop3

finish: pla
        sta     path_buf2
        copy    #0, path_buf1
        MGTK_RELAY_CALL MGTK::MoveTo, name_input_textpos ; Seems unnecessary???
        jsr     draw_filename_prompt
        rts
.endproc

;;; ============================================================

.proc merge_path_buf1_path_buf2
        lda     path_buf2
        cmp     #2
        bcc     done

        ;; Compute new path_buf1 length
        ldx     path_buf2
        dex
        txa
        clc
        adc     path_buf1
        pha

        ;; Copy chars from path_buf2 to path_buf1
        tay
        ldx     path_buf2
loop:   lda     path_buf2,x
        sta     path_buf1,y
        dex
        dey
        cpy     path_buf1
        bne     loop

        ;; Finish up, shrinking path_buf2 to just an insertion point
        pla
        sta     path_buf1
        copy    #1, path_buf2

done:   rts
.endproc

;;; ============================================================
;;; Move IP to end of input field.

.proc input_field_ip_end
        jsr     merge_path_buf1_path_buf2
        MGTK_RELAY_CALL MGTK::MoveTo, name_input_textpos ; Seems unnecessary???
        jsr     draw_filename_prompt
        rts
.endproc

;;; ============================================================
;;; Compute width of path_buf1, offset name_input_textpos, return x coord in (A,X)

.proc measure_path_buf1
        textwidth_params  := $6
        textptr := $6
        textlen := $8
        result  := $9

        copy16  #path_buf1+1, textptr
        lda     path_buf1
        sta     textlen
        bne     :+
        ldax    name_input_textpos::xcoord
        rts

:       MGTK_RELAY_CALL MGTK::TextWidth, textwidth_params
        lda     result
        clc
        adc     name_input_textpos::xcoord
        tay
        lda     result+1
        adc     name_input_textpos::xcoord+1
        tax
        tya
        rts
.endproc

;;; ============================================================

.proc clear_path_buf2
        copy    #1, path_buf2   ; length
        copy    str_insertion_point+1, path_buf2+1 ; IP character
        rts
.endproc

.proc clear_path_buf1
        copy    #0, path_buf1   ; length
        rts
.endproc

;;; ============================================================
;;; Make str_files singular or plural based on file_count

.proc adjust_str_files_suffix
        ldx     str_files
        lda     file_count+1         ; > 255?
        bne     :+
        lda     file_count
        cmp     #2              ; > 2?
        bcs     :+

        copy    #' ', str_files,x ; singular
        rts

:       copy    #'s', str_files,x ; plural
        rts
.endproc

;;; ============================================================

.proc compose_file_count_string
        ldax    file_count
        jsr     int_to_string

        ldy     #1
        copy    #' ', str_file_count,y

        ldx     #0
:       cpx     str_from_int
        beq     :+
        inx
        iny
        copy    str_from_int,x, str_file_count,y
        bne     :-

:       iny
        copy    #' ', str_file_count,y
        sty     str_file_count

        rts
.endproc

;;; ============================================================

.proc copy_name_to_buf0
        ptr := $6

        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     path_buf0,y
        dey
        bpl     :-
        rts
.endproc

.proc copy_name_to_buf1
        ptr := $6

        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     path_buf1,y
        dey
        bpl     :-
        rts
.endproc

;;; ============================================================

clear_target_file_rect:
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::current_target_file_rect
        rts

clear_dest_file_rect:
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::current_dest_file_rect
        rts

;;; ============================================================

get_event:
        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        rts

peek_event:
        MGTK_RELAY_CALL MGTK::PeekEvent, event_params
        rts

set_penmode_xor:
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        rts

set_penmode_copy:
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        rts

;;; ============================================================

.proc reset_main_grafport
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        rts
.endproc

;;; ============================================================

.proc close_prompt_dialog
        jsr     reset_main_grafport
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_prompt_dialog
        rts
.endproc

;;; ============================================================
;;; Output: A = number of selected icons

.proc get_selection_count
        lda     selected_icon_count
        rts
.endproc

;;; ============================================================
;;; Input: A = index in selection
;;; Output: A,X = IconEntry address

.proc get_selected_icon
        tax
        lda     selected_icon_list,x
        asl     a
        tay
        lda     icon_entry_address_table,y
        ldx     icon_entry_address_table+1,y
        rts
.endproc

;;; ============================================================
;;; Output: A = window with selection, 0 if desktop

.proc get_selection_window
        lda     selected_window_index
        rts
.endproc

;;; ============================================================
;;; Input: A = window_id
;;; Output: A,X = path address

.proc get_window_path
        asl     a
        tay
        lda     window_path_addr_table,y
        ldx     window_path_addr_table+1,y
        rts
.endproc

;;; ============================================================

.proc toggle_menu_hilite
        MGTK_RELAY_CALL MGTK::HiliteMenu, menu_click_params
        rts
.endproc

;;; ============================================================

;;; ============================================================
;;; Parse date/time
;;; Input: A,X = addr of datetime to parse
;;; $0A points at ParsedDateTime to be filled

.proc parse_datetime
        parsed_ptr := $0A
        datetime_ptr := $0C

        stax    datetime_ptr

        ;; Null date? Leave as all zeros.
        ldy     #0
        lda     (datetime_ptr),y
        iny
        ora     (datetime_ptr),y ; null date?
        bne     not_null

        ldy     #.sizeof(ParsedDateTime)-1
:       sta     (parsed_ptr),y
        dey
        bpl     :-
        rts

not_null:
        ;; Is it a ProDOS 2.5 extended date/time? (see below)
        ldy     #3
        lda     (datetime_ptr),y
        and     #%11100000      ; Top 3 bits would be 0...
        bne     prodos_2_5      ; unless ProDOS 2.5a4+

        ;; --------------------------------------------------
        ;; ProDOS 8 DateTime:
        ;;       byte 1            byte 0
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; |    Year     |  Month  |   Day   |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;;
        ;;       byte 3            byte 2
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; |0 0 0|  Hour   | |0 0|  Minute   |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;;

        ;; ----------------------------------------
        ;; Year
        ;; (top 7 bits of datehi, top 3 bits of timehi)
year:   lda     #0
        sta     ytmp+1

        ldy     #DateTime::datehi
        lda     (datetime_ptr),y ; First, calculate year-1900
        lsr     a
        php                     ; Save Carry bit
        sta     ytmp

        ;; 0-39 is 2000-2039
        ;; Per Technical Note: ProDOS #28: ProDOS Dates -- 2000 and Beyond
        ;; http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.28.html
tn28:   lda     ytmp            ; ytmp is still just one byte
        cmp     #40
        bcs     :+
        adc     #100
        sta     ytmp
:

do1900: ldy     #ParsedDateTime::year
        add16in ytmp, #1900, (parsed_ptr),y

        ;; ----------------------------------------
        ;; Month
        ;; (mix low bit from datehi with top 3 bits from datelo)
        plp                     ; Restore Carry bit
        ldy     #DateTime::datelo
        lda     (datetime_ptr),y
        ror     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ldy     #ParsedDateTime::month
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; Day
        ;; (low 5 bits of datelo)
        ldy     #DateTime::datelo
        lda     (datetime_ptr),y
        and     #%00011111
        ldy     #ParsedDateTime::day
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; Hour
        ldy     #DateTime::timehi
        lda     (datetime_ptr),y
        and     #%00011111
        ldy     #ParsedDateTime::hour
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; Minute
        ldy     #DateTime::timelo
        lda     (datetime_ptr),y
        and     #%00111111
        ldy     #ParsedDateTime::minute
        sta     (parsed_ptr),y

        rts

        ;; --------------------------------------------------
        ;; ProDOS 8 2.5.0a4+ Extended DateTime:
        ;; https://prodos8.com/releases/prodos-25/
        ;;
        ;;       byte 1            byte 0
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; | Day     | Hour      | Minute    |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;;
        ;;       byte 3            byte 2
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; | Month | Year                    |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
prodos_2_5:
        ;; ----------------------------------------
        ;; day: 1-31
        ldy     #1
        lda     (datetime_ptr),y
        lsr
        lsr
        lsr
        ldy     #ParsedDateTime::day
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; month: 2-13
        ldy     #3
        lda     (datetime_ptr),y
        lsr
        lsr
        lsr
        lsr
        sec
        sbc     #1              ; make it 1-12
        ldy     #ParsedDateTime::month
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; year: 0-4095
        ldy     #2
        lda     (datetime_ptr),y
        ldy     #ParsedDateTime::year
        sta     (parsed_ptr),y

        ldy     #3
        lda     (datetime_ptr),y
        and     #%00001111
        ldy     #ParsedDateTime::year+1
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; hour: 0-23
        ldy     #0
        copy16in (datetime_ptr),y, ytmp
        ldx     #6
:       lsr16   ytmp
        dex
        bne     :-
        lda     ytmp
        and     #%00011111      ; should be unnecessary
        ldy     #ParsedDateTime::hour
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; minute: 0-59
        ldy     #0
        lda     (datetime_ptr),y
        and     #%00111111
        ldy     #ParsedDateTime::minute
        sta     (parsed_ptr),y

        rts

ytmp:   .word   0

.endproc

;;; ============================================================


        PAD_TO $BF00

.endproc ; main
        desktop_main_pop_pointers := main::pop_pointers
        desktop_main_push_pointers := main::push_pointers
