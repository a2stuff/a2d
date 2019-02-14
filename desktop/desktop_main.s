;;; ============================================================
;;; DeskTop - Main Memory Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into MAIN $4000-$BEFF
;;; ============================================================

.proc desktop_main

.scope format_erase_overlay
L0CB8           := $0CB8
L0CD7           := $0CD7
L0CF9           := $0CF9
L0D14           := $0D14
.endscope

dst_path_buf   := $1FC0

        dynamic_routine_800  := $0800
        dynamic_routine_5000 := $5000
        dynamic_routine_7000 := $7000
        dynamic_routine_9000 := $9000

        dynamic_routine_disk_copy    = 0
        dynamic_routine_format_erase = 1
        dynamic_routine_selector1    = 2
        dynamic_routine_common       = 3
        dynamic_routine_file_copy    = 4
        dynamic_routine_file_delete  = 5
        dynamic_routine_selector2    = 6
        dynamic_routine_restore5000  = 7
        dynamic_routine_restore9000  = 8


        .org $4000

        ;; Jump table
        ;; Entries marked with * are used by DAs
        ;; "Exported" by desktop.inc

JT_MAIN_LOOP:           jmp     enter_main_loop
JT_MGTK_RELAY:          jmp     MGTK_RELAY
JT_SIZE_STRING:         jmp     compose_blocks_string
JT_DATE_STRING:         jmp     compose_date_string
JT_SELECT_WINDOW:       jmp     select_and_refresh_window
JT_AUXLOAD:             jmp     AuxLoad
JT_EJECT:               jmp     cmd_eject
JT_REDRAW_ALL:          jmp     redraw_windows          ; *
JT_DESKTOP_RELAY:       jmp     DESKTOP_RELAY
JT_LOAD_OVL:            jmp     load_dynamic_routine
JT_CLEAR_SELECTION:     jmp     clear_selection         ; *
JT_MLI_RELAY:           jmp     MLI_RELAY               ; *
JT_COPY_TO_BUF:         jmp     LoadWindowIconTable
JT_COPY_FROM_BUF:       jmp     StoreWindowIconTable
JT_NOOP:                jmp     cmd_noop
JT_FILE_TYPE_STRING:    jmp     compose_file_type_string
JT_SHOW_ALERT0:         jmp     ShowAlert
JT_SHOW_ALERT:          jmp     ShowAlertOption
JT_LAUNCH_FILE:         jmp     launch_file
JT_CUR_POINTER:         jmp     set_pointer_cursor      ; *
JT_CUR_WATCH:           jmp     set_watch_cursor
JT_RESTORE_OVL:         jmp     restore_dynamic_routine
JT_COLOR_MODE:          jmp     set_color_mode          ; *
JT_MONO_MODE:           jmp     set_mono_mode           ; *
JT_RESTORE_SYS:         jmp     restore_system          ; *

        .assert JUMP_TABLE_MAIN_LOOP = JT_MAIN_LOOP, error, "Jump table mismatch"
        .assert JUMP_TABLE_RESTORE_SYS = JT_RESTORE_SYS, error, "Jump table mismatch"

        ;; Main Loop
.proc enter_main_loop
        cli

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        jsr     initialize_disks_in_devices_tables

        ;; Add icons (presumably desktop ones?)
        ldx     #0
iloop:  cpx     cached_window_icon_count
        beq     skip
        txa
        pha
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup
        ldy     #DT_ADD_ICON
        jsr     DESKTOP_RELAY   ; icon entry addr in A,X
        pla
        tax
        inx
        jmp     iloop

skip:   copy    #0, cached_window_id
        jsr     StoreWindowIconTable

        ;; Clear various flags
        lda     #0
        sta     LD2A9
        sta     double_click_flag
        sta     loop_counter
        sta     LE26F

        ;; Pending error message?
        lda     pending_alert
        beq     main_loop
        tay
        jsr     ShowAlert

        ;; Main loop
main_loop:
        jsr     reset_grafport3

        inc     loop_counter
        inc     loop_counter
        lda     loop_counter
        cmp     machine_type    ; for per-machine timing
        bcc     :+
        copy    #0, loop_counter

        jsr     show_clock

        ;; Poll drives for updates
        jsr     check_disk_inserted_ejected
        beq     :+
        jsr     L40E0           ; conditionally ???

:       jsr     L464E

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
        jsr     reset_grafport3
        copy    active_window_id, L40F0
        copy    #$80, L40F1
        jsr     L410D

:       jmp     main_loop

loop_counter:
        .byte   0

;;; --------------------------------------------------

L40E0:  tsx
        stx     saved_stack
        sta     menu_click_params::item_num
        jsr     cmd_check_single_drive_by_menu
        copy    #0, menu_click_params::item_num
        rts

L40F0:  .byte   $00
L40F1:  .byte   $00
redraw_windows:
        jsr     reset_grafport3
        copy    active_window_id, L40F0
        copy    #$00, L40F1
L4100:  jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::update
        bne     L412B
        jsr     get_event
L410D:  jsr     L4113
        jmp     L4100

L4113:  MGTK_RELAY_CALL MGTK::BeginUpdate, event_window_id
        bne     L4151           ; did not really need updating
        jsr     update_window
        MGTK_RELAY_CALL MGTK::EndUpdate
        rts

L412B:  jsr     LoadDesktopIconTable
        lda     L40F0
        sta     active_window_id
        beq     L4143
        bit     running_da_flag
        bmi     L4143
        jsr     redraw_selected_icons
L4143:  bit     L40F1
        bpl     L4151
        DESKTOP_RELAY_CALL DT_REDRAW_ICONS
L4151:  rts

.endproc
        main_loop := enter_main_loop::main_loop
        redraw_windows := enter_main_loop::redraw_windows

;;; ============================================================


draw_window_header_flag:  .byte   0


.proc update_window
        lda     event_window_id
        cmp     #9              ; only handle windows 1...8
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
        sub16in ($06),y, grafport2::viewloc::ycoord, L4242
        cmp16   L4242, #15
        bpl     L41CB
        jsr     offset_grafport2

        ldx     #11
        ldy     #31
        copy    grafport2,x, ($06),y
        dey
        dex
        copy    grafport2,x, ($06),y

        ldx     #3
        ldy     #23
        copy    grafport2,x, ($06),y
        dey
        dex
        copy    grafport2,x, ($06),y

L41CB:  ldx     cached_window_id
        dex
        lda     win_view_by_table,x
        bpl     L41E2
        jsr     L6C19
        copy    #0, draw_window_header_flag
        lda     active_window_id
        jmp     assign_window_portbits

L41E2:  copy    cached_window_id, getwinport_params2::window_id
        jsr     get_set_port2
        jsr     cached_icons_window_to_screen

        COPY_BLOCK grafport2::cliprect, tmp_rect

        copy    #0, L4241
L41FE:  lda     L4241
        cmp     cached_window_icon_count
        beq     L4227
        tax
        copy    cached_window_icon_list,x, icon_param
        DESKTOP_RELAY_CALL DT_ICON_IN_RECT, icon_param
        beq     :+
        DESKTOP_RELAY_CALL DT_REDRAW_ICON, icon_param
:       inc     L4241
        jmp     L41FE

L4227:  copy    #$00, draw_window_header_flag
        copy    cached_window_id, getwinport_params2::window_id
        jsr     get_set_port2
        jsr     cached_icons_screen_to_window
        lda     active_window_id
        jsr     assign_window_portbits
        jmp     reset_grafport3

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
        jsr     offset_grafport2_and_set

        COPY_BLOCK grafport2::cliprect, tmp_rect

        ;; Redraw selected icons in window
window: lda     num
        cmp     selected_icon_count
        beq     done
        tax
        copy    selected_icon_list,x, icon_param
        jsr     icon_window_to_screen
        DESKTOP_RELAY_CALL DT_ICON_IN_RECT, icon_param
        beq     :+
        DESKTOP_RELAY_CALL DT_REDRAW_ICON, icon_param
:       lda     icon_param
        jsr     icon_screen_to_window
        inc     num
        jmp     window

done:   jmp     reset_grafport3

        ;; Redraw selected icons on desktop
desktop:
        lda     num
        cmp     selected_icon_count
        beq     done
        tax
        copy    selected_icon_list,x, icon_param
        DESKTOP_RELAY_CALL DT_REDRAW_ICON, icon_param
        inc     num
        jmp     desktop

num:    .byte   0
.endproc

;;; ============================================================
;;; Menu Dispatch

.proc handle_keydown_impl

        ;; Keep in sync with desktop_aux::menu_item_id_*

        ;; jump table for menu item handlers
dispatch_table:
        ;; Apple menu (1)
        menu1_start := *
        .addr   cmd_about
        .addr   cmd_noop        ; --------
        .repeat ::max_desk_acc_count
        .addr   cmd_deskacc
        .endrepeat

        ;; File menu (2)
        menu2_start := *
        .addr   cmd_new_folder
        .addr   cmd_noop        ; --------
        .addr   cmd_open
        .addr   cmd_close
        .addr   cmd_close_all
        .addr   cmd_select_all
        .addr   cmd_noop        ; --------
        .addr   cmd_copy_file
        .addr   cmd_delete_file
        .addr   cmd_noop        ; --------
        .addr   cmd_get_info
        .addr   cmd_rename_icon
        .addr   cmd_noop        ; --------
        .addr   cmd_quit

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

        ;; View menu (4)
        menu4_start := *
        .addr   cmd_view_by_icon
        .addr   cmd_view_by_name
        .addr   cmd_view_by_date
        .addr   cmd_view_by_size
        .addr   cmd_view_by_type

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

flag:   .byte   $00

        ;; Handle accelerator keys
handle_keydown:
        lda     event_modifiers
        bne     :+              ; either OA or SA ?
        jmp     menu_accelerators           ; nope
:       cmp     #3              ; both OA + SA ?
        bne     :+              ; nope
        rts

        ;; Non-menu keys
:       lda     event_key
        ora     #$20            ; force to lower-case
        cmp     #'h'            ; OA-H (Highlight Icon)
        bne     :+
        jmp     cmd_higlight
:       bit     flag
        bpl     menu_accelerators
        cmp     #'w'            ; OA-W (Activate Window)
        bne     :+
        jmp     cmd_activate
:       cmp     #'g'            ; OA-G (Resize)
        bne     :+
        jmp     cmd_resize
:       cmp     #'m'            ; OA-M (Move)
        bne     :+
        jmp     cmd_move
:       cmp     #'x'            ; OA-X (Scroll)
        bne     menu_accelerators
        jmp     cmd_scroll

menu_accelerators:
        copy    event_key, LE25C
        lda     event_modifiers
        beq     :+
        lda     #1
:       sta     LE25D
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
        DESKTOP_RELAY_CALL DT_FIND_ICON, event_coords
        lda     findicon_which_icon
        beq     :+
        jmp     handle_volume_icon_click

:       jmp     L68AA

not_desktop:
        cmp     #MGTK::Area::menubar  ; menu?
        bne     not_menu
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

.proc handle_active_window_click
        pla
        cmp     #MGTK::Area::content
        bne     :+
        jsr     detect_double_click
        sta     double_click_flag
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

.proc handle_inactive_window_click
        ptr := $6

        jmp     start

L445C:  .byte   0

start:  jsr     clear_selection
        ldx     findwindow_window_id
        dex
        copy    window_to_dir_icon_table,x, icon_param
        lda     icon_param
        jsr     icon_entry_lookup
        stax    ptr
        ldy     #1
        lda     (ptr),y
        beq     L44A6
        ora     #$80
        sta     (ptr),y
        iny
        lda     (ptr),y
        and     #$0F
        sta     L445C
        jsr     zero_grafport5_coords
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
        jsr     reset_grafport3
        copy    L445C, selected_window_index
        copy    #1, selected_icon_count
        copy    icon_param, selected_icon_list
L44A6:  MGTK_RELAY_CALL MGTK::SelectWindow, findwindow_window_id
        copy    findwindow_window_id, active_window_id
        jsr     LoadActiveWindowIconTable
        jsr     L6C19
        jsr     LoadDesktopIconTable
        copy    #MGTK::checkitem_uncheck, checkitem_params::check
        MGTK_RELAY_CALL MGTK::CheckItem, checkitem_params
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        and     #$0F
        sta     checkitem_params::menu_item
        inc     checkitem_params::menu_item
        copy    #MGTK::checkitem_check, checkitem_params::check
        MGTK_RELAY_CALL MGTK::CheckItem, checkitem_params
        rts
.endproc

;;; ============================================================

.proc get_set_port2
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params2
        MGTK_RELAY_CALL MGTK::SetPort, grafport2
        rts
.endproc

.proc get_port2
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params2
        rts
.endproc

.proc reset_grafport3
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts
.endproc

;;; ============================================================

.proc redraw_windows_and_desktop
        jsr     redraw_windows
        DESKTOP_RELAY_CALL DT_REDRAW_ICONS
        rts
.endproc

;;; ============================================================

.proc initialize_disks_in_devices_tables
        ldx     #0
        ldy     DEVCNT
loop:   lda     DEVLST,y
        and     #$0F
        cmp     #DT_REMOVABLE
        beq     append          ; yes
next:   dey
        bpl     loop

        stx     removable_device_table
        stx     disk_in_device_table
        jsr     check_disks_in_devices

        ;; Make copy of table
        ldx     disk_in_device_table
        beq     done
:       copy    disk_in_device_table,x, last_disk_in_devices_table,x
        dex
        bpl     :-

done:   rts

append: lda     DEVLST,y        ; add it to the list
        ;; Don't issue STATUS calls to IIc Plus Slot 5 firmware, as it causes
        ;; the motor to spin. https://github.com/inexorabletash/a2d/issues/25
        bit     is_iic_plus_flag
        bpl     :+
        and     #%01110000      ; mask off slot
        cmp     #$50            ; is it slot 5?
        beq     next            ; if so, ignore
:       lda     DEVLST,y

        inx
        sta     removable_device_table,x
        bne     next            ; always
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

max_removable_devices = 8

removable_device_table:
        .byte   0               ; num entries
        .res    max_removable_devices, 0

;;; Updated by check_disks_in_devices
disk_in_device_table:
        .byte   0               ; num entries
        .res    max_removable_devices, 0

;;; Snapshot of previous results; used to detect changes.
last_disk_in_devices_table:
        .byte   0               ; num entries
        .res    max_removable_devices, 0

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
.proc status_params
param_count:    .byte   3
unit_num:       .byte   1
list_ptr:       .addr   status_buffer
status_code:    .byte   0
.endproc
status_unit_num := status_params::unit_num
.endproc

;;; ============================================================

.proc L464E
        lda     num_selector_list_items
        beq     :+
        bit     LD344
        bmi     L4666
        jsr     enable_selector_menu_items
        jmp     L4666

:       bit     LD344
        bmi     L4666
        jsr     disable_selector_menu_items
L4666:  lda     selected_icon_count
        beq     L46A8
        lda     selected_window_index
        bne     L4691
        lda     selected_icon_count
        cmp     #2
        bcs     L4697
        lda     selected_icon_list
        cmp     trash_icon_num
        bne     L468B
        jsr     disable_eject_menu_item
        jsr     disable_file_menu_items
        copy    #0, LE26F
        rts

L468B:  jsr     enable_eject_menu_item
        jmp     L469A

L4691:  jsr     disable_eject_menu_item
        jmp     L469A

L4697:  jsr     enable_eject_menu_item
L469A:  bit     LE26F
        bmi     L46A7
        jsr     enable_file_menu_items
        copy    #$80, LE26F
L46A7:  rts

L46A8:  bit     LE26F
        bmi     L46AE
        rts

L46AE:  jsr     disable_eject_menu_item
        jsr     disable_file_menu_items
        copy    #$00, LE26F
        rts
.endproc

.proc MLI_RELAY
        sty     call
        stax    params
        php
        sei
        sta     ALTZPOFF
        sta     ROMIN2
        jsr     MLI
call:   .byte   $00
params: .addr   dummy0000
        sta     ALTZPON
        tax
        lda     LCBANK1
        lda     LCBANK1
        plp
        txa
        rts
.endproc

.macro MLI_RELAY_CALL call, addr
        yax_call desktop_main::MLI_RELAY, call, addr
.endmacro

;;; ============================================================
;;; Launch file (double-click) ???

.proc launch_file
        path := $220

        jmp     begin

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, path

begin:
        jsr     set_watch_cursor

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

        ;; Get the file info to determine type.
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        jsr     ShowAlert
        rts

        ;; Check file type.
:       lda     get_file_info_params::file_type
        cmp     #FT_BASIC
        bne     :+
        jsr     check_basic_system ; Only launch if BASIC.SYSTEM is found
        jmp     launch

:       cmp     #FT_BINARY
        bne     :+
        lda     BUTN0           ; Only launch if a button is down
        ora     BUTN1           ; BUG: Never gets this far ???
        bmi     launch
        jsr     set_pointer_cursor
        rts

:       cmp     #FT_SYSTEM
        beq     launch

        cmp     #FT_S16
        beq     launch

        cmp     #FT_GRAPHICS
        bne     :+
        addr_jump invoke_desk_acc, str_preview_fot

:       cmp     #FT_TEXT
        bne     :+
        addr_jump invoke_desk_acc, str_preview_txt

:       lda     #ERR_FILE_NOT_OPENABLE
        jsr     show_alert_and_fail

launch: DESKTOP_RELAY_CALL DT_UNHIGHLIGHT_ALL
        MGTK_RELAY_CALL MGTK::CloseAll
        MGTK_RELAY_CALL MGTK::SetMenu, blank_menu
        ldx     buf_win_path
:       copy    buf_win_path,x, path,x
        dex
        bpl     :-
        ldx     buf_filename2
:       copy    buf_filename2,x, INVOKER_FILENAME,x
        dex
        bpl     :-
        copy16  #INVOKER, reset_and_invoke_target
        jmp     reset_and_invoke

;;; --------------------------------------------------

.proc check_basic_system_impl
        path := $1800

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params2, path

start:  ldx     buf_win_path
        stx     path_length
:       copy    buf_win_path,x, path,x
        dex
        bpl     :-

        inc     path
        ldx     path
        copy    #'/', path,x
loop:
        ;; Append BASIC.SYSTEM to path and check for file.
        ldx     path
        ldy     #0
:       inx
        iny
        copy    str_basic_system,y, path,x
        cpy     str_basic_system
        bne     :-
        stx     path
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params2
        bne     not_found
        rts

        ;; Pop off a path segment and try again.
not_found:
        ldx     path_length
:       lda     path,x
        cmp     #'/'
        beq     found_slash
        dex
        bne     :-

no_bs:  lda     #ERR_BASIC_SYS_NOT_FOUND

show_alert_and_fail:
        jsr     ShowAlert
        pla                     ; pop caller address, return to its caller
        pla
        rts

found_slash:
        cpx     #$01
        beq     no_bs
        stx     path
        dex
        stx     path_length
        jmp     loop

path_length:
        .byte   0

str_basic_system:
        PASCAL_STRING "Basic.system"
.endproc
        check_basic_system := check_basic_system_impl::start
        show_alert_and_fail := check_basic_system_impl::show_alert_and_fail

;;; --------------------------------------------------

.endproc

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

L485D:  .word   $E000
L485F:  .word   $D000

sys_start_flag:  .byte   0
sys_start_path:  .res    40, 0

;;; ============================================================

set_watch_cursor:
        jsr     hide_cursor
        MGTK_RELAY_CALL MGTK::SetCursor, watch_cursor
        jsr     show_cursor
        rts

set_pointer_cursor:
        jsr     hide_cursor
        MGTK_RELAY_CALL MGTK::SetCursor, pointer_cursor
        jsr     show_cursor
        rts

hide_cursor:
        MGTK_RELAY_CALL MGTK::HideCursor
        rts

show_cursor:
        MGTK_RELAY_CALL MGTK::ShowCursor
        rts

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
        yax_call invoke_dialog_proc, index_warning_dialog, warning_dialog_num
        rts
.endproc

        copy16  #main_loop, L48E4

        L48E4 := *+1
        jmp     dummy1234           ; self-modified

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

.proc cmd_noop
        rts
.endproc

;;; ============================================================

.proc cmd_selector_action
        jsr     set_watch_cursor
        lda     #dynamic_routine_selector1
        jsr     load_dynamic_routine
        bmi     done
        lda     menu_click_params::item_num
        cmp     #3              ; 1 = Add, 2 = Edit (need more overlays)
        bcs     :+              ; 3 = Delete, 4 = Run (can skip)
        lda     #dynamic_routine_selector2
        jsr     load_dynamic_routine
        bmi     done
        lda     #dynamic_routine_common
        jsr     load_dynamic_routine
        bmi     done

:       jsr     set_pointer_cursor
        ;; Invoke routine
        lda     menu_click_params::item_num
        jsr     dynamic_routine_9000
        sta     result
        jsr     set_watch_cursor
        ;; Restore from overlays
        lda     #dynamic_routine_restore9000
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
        bpl     L497A

        jsr     jt_run
        bmi     done
        jsr     L4968

done:   jsr     set_pointer_cursor
        jsr     redraw_windows_and_desktop
        rts

.proc L4968
        jsr     make_ramcard_prefixed_path
        COPY_STRING $840, buf_win_path
        jmp     launch_buf_win_path
.endproc

L497A:  jsr     make_ramcard_prefixed_path
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

        ldy     #$0F            ; flag byte following name
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
;;; Get "copied to RAM card" flag from Main LC Bank 2.

.proc get_copied_to_ramcard_flag
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2
        lda     copied_to_ramcard_flag
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

        ldx     ramcard_prefix
:       lda     ramcard_prefix,x
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

        ldx     desktop_orig_prefix
:       lda     desktop_orig_prefix,x
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
        yax_call invoke_dialog_proc, index_about_dialog, $0000
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================

.proc cmd_deskacc_impl
        ptr := $6

        .define prefix "Desk.acc/"
        prefix_length = .strlen(prefix)

str_desk_acc:
        PASCAL_STRING prefix, prefix_length + 15

start:  jsr     reset_grafport3
        jsr     set_watch_cursor

        ;; Find DA name
        lda     menu_click_params::item_num           ; menu item index (1-based)
        sec
        sbc     #3              ; About and separator before first item
        jsr     a_times_16
        addax   #desk_acc_names, ptr

        ;; Compute total length
        ldy     #0
        lda     (ptr),y
        tay
        clc
        adc     #prefix_length
        pha
        tax

        ;; Append name to path
:       lda     ($06),y
        sta     str_desk_acc,x
        dex
        dey
        bne     :-
        pla
        sta     str_desk_acc    ; update length

        ;; Convert spaces to periods
        ldx     str_desk_acc
:       lda     str_desk_acc,x
        cmp     #' '
        bne     nope
        lda     #'.'
        sta     str_desk_acc,x
nope:   dex
        bne     :-

        ldax    #str_desk_acc
        ;; fall through
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
        jsr     read
        jsr     close
        copy    #$80, running_da_flag

        ;; Invoke it
        jsr     set_pointer_cursor
        jsr     reset_grafport3
        ;;         MGTK_RELAY_CALL MGTK::SetZP1, zp_use_flag0
        ;;         MGTK_RELAY_CALL MGTK::SetZP1, zp_use_flag1
        jsr     DA_LOAD_ADDRESS
        ;;         MGTK_RELAY_CALL MGTK::SetZP1, zp_use_flag0
        lda     #0
        sta     running_da_flag

        ;; Restore state
        jsr     reset_grafport3
        jsr     redraw_windows_and_desktop
done:   jsr     set_pointer_cursor
        rts

open:   yxa_call MLI_RELAY, OPEN, open_params
        bne     :+
        rts
:       lda     #warning_msg_insert_system_disk
        jsr     warning_dialog_proc_num
        beq     open            ; ok, so try again
        return  #$FF            ; cancel, so fail

read:   yxa_jump MLI_RELAY, READ, read_params

close:  yxa_jump MLI_RELAY, CLOSE, close_params

zp_use_flag1:
        .byte   $80

        DEFINE_OPEN_PARAMS open_params, 0, DA_IO_BUFFER
        open_ref_num := open_params::ref_num
        open_pathname := open_params::pathname

        DEFINE_READ_PARAMS read_params, DA_LOAD_ADDRESS, DA_MAX_SIZE
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
        jsr     set_watch_cursor
        lda     #dynamic_routine_common
        jsr     load_dynamic_routine
        bmi     L4CD6
        lda     #dynamic_routine_file_copy
        jsr     load_dynamic_routine
        bmi     L4CD6
        jsr     set_pointer_cursor
        lda     #$00
        jsr     dynamic_routine_5000
        pha
        jsr     set_watch_cursor
        lda     #dynamic_routine_restore5000
        jsr     restore_dynamic_routine
        jsr     set_pointer_cursor
        pla
        bpl     :+
        jmp     L4CD6

        ;; --------------------------------------------------

:       jsr     copy_paths_and_split_name
        jsr     redraw_windows_and_desktop

        jsr     jt_copy_file

L4CD6:  pha
        jsr     set_pointer_cursor
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
        jsr     set_watch_cursor
        lda     #dynamic_routine_common
        jsr     load_dynamic_routine
        bmi     L4D9D

        lda     #dynamic_routine_file_delete
        jsr     load_dynamic_routine
        bmi     L4D9D

        jsr     set_pointer_cursor
        lda     #$01
        jsr     dynamic_routine_5000
        pha
        jsr     set_watch_cursor
        lda     #dynamic_routine_restore5000
        jsr     restore_dynamic_routine
        jsr     set_pointer_cursor
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
        jsr     set_pointer_cursor
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

.proc cmd_open
        ptr := $06

        ldx     #0
        stx     dir_count

L4DEC:  cpx     selected_icon_count
        bne     :+

        ;; Were any directories opened?
        lda     dir_count
        beq     done
        jsr     clear_selection
done:   rts

:       txa
        pha
        lda     selected_icon_list,x
        jsr     icon_entry_lookup
        stax    ptr

        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #icon_entry_type_mask

        cmp     #icon_entry_type_trash
        beq     next_file
        cmp     #icon_entry_type_dir
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
        sta     L4E71
        lda     selected_icon_count
        cmp     #2              ; multiple files open?
        bcs     next_file       ; don't try to invoke

        pla
        lda     active_window_id
        jsr     window_path_lookup
        stax    $06

        ldy     #0
        lda     ($06),y
        tay
L4E34:  lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     L4E34
        lda     selected_icon_list
        jsr     icon_entry_lookup
        stax    $06
        ldy     #$09
        lda     ($06),y
        tax
        clc
        adc     #$09
        tay
        dex
        dey
L4E51:  lda     ($06),y
        sta     buf_filename2-1,x
        dey
        dex
        bne     L4E51
        ldy     #$09
        lda     ($06),y
        tax
        dex
        dex
        stx     buf_filename2
        lda     L4E71
        cmp     #$20
        bcc     L4E6E
        lda     L4E71
L4E6E:  jmp     launch_file

L4E71:  .byte   0

        ;; Count of opened volumes/folders; if non-zero,
        ;; selection must be cleared before finishing.
dir_count:
        .byte   0
.endproc

;;; ============================================================

.proc cmd_close
        lda     active_window_id
        bne     L4E78
        rts

L4E78:  jsr     clear_selection
        dec     LEC2E
        jsr     LoadActiveWindowIconTable
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        bmi     L4EB4
        DESKTOP_RELAY_CALL DT_CLOSE_WINDOW, active_window_id
        lda     icon_count
        sec
        sbc     cached_window_icon_count
        sta     icon_count
        ldx     #$00
L4EA5:  cpx     cached_window_icon_count
        beq     L4EB4
        lda     cached_window_icon_list,x
        jsr     FreeIcon
        inx
        jmp     L4EA5

L4EB4:  ldx     #$00
        txa
L4EB7:  sta     cached_window_icon_list,x
        cpx     cached_window_icon_count
        beq     L4EC3
        inx
        jmp     L4EB7

L4EC3:  sta     cached_window_icon_count
        jsr     StoreWindowIconTable
        jsr     LoadDesktopIconTable
        MGTK_RELAY_CALL MGTK::CloseWindow, active_window_id
        ldx     active_window_id
        dex
        lda     window_to_dir_icon_table,x
        sta     icon_param
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #AS_BYTE(~icon_entry_open_mask) ; clear open_flag
        sta     ($06),y
        and     #icon_entry_winid_mask
        sta     selected_window_index
        jsr     zero_grafport5_coords
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
        jsr     reset_grafport3
        copy    #1, selected_icon_count
        copy    icon_param, selected_icon_list
        ldx     active_window_id
        dex
        lda     window_to_dir_icon_table,x
        jsr     L7345
        ldx     active_window_id
        dex
        copy    #0, window_to_dir_icon_table,x
        MGTK_RELAY_CALL MGTK::FrontWindow, active_window_id
        lda     active_window_id
        bne     L4F3C
        DESKTOP_RELAY_CALL DT_REDRAW_ICONS
L4F3C:  lda     #MGTK::checkitem_uncheck
        sta     checkitem_params::check
        MGTK_RELAY_CALL MGTK::CheckItem, checkitem_params
        jsr     update_window_menu_items
        jmp     reset_grafport3
.endproc

;;; ============================================================

.proc cmd_close_all
        lda     active_window_id   ; current window
        beq     done            ; nope, done!
        jsr     cmd_close       ; close it...
        jmp     cmd_close_all   ; and try again
done:   rts
.endproc

;;; ============================================================

.proc cmd_disk_copy
        lda     #dynamic_routine_disk_copy
        jsr     load_dynamic_routine
        bmi     fail
        jmp     dynamic_routine_800

fail:   rts
.endproc

;;; ============================================================

.proc cmd_new_folder_impl

        ptr := $06

.proc new_folder_dialog_params
phase:  .byte   0               ; window_id?
win_path_ptr:  .word   0
.endproc

        ;; access = destroy/rename/write/read
        DEFINE_CREATE_PARAMS create_params, path_buffer, ACCESS_DEFAULT, FT_DIRECTORY,, ST_LINKED_DIRECTORY

path_buffer:
        .res    65, 0              ; buffer is used elsewhere too

start:  copy    active_window_id, new_folder_dialog_params::phase
        yax_call invoke_dialog_proc, index_new_folder_dialog, new_folder_dialog_params

L4FC6:  lda     active_window_id
        beq     L4FD4
        jsr     window_path_lookup
        stax    new_folder_dialog_params::win_path_ptr
L4FD4:  copy    #$80, new_folder_dialog_params::phase
        yax_call invoke_dialog_proc, index_new_folder_dialog, new_folder_dialog_params
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
        yax_call invoke_dialog_proc, index_new_folder_dialog, new_folder_dialog_params
        addr_call find_last_path_segment, path_buffer
        sty     path_buffer
        addr_call find_window_for_path, path_buffer
        beq     done
        jsr     select_and_refresh_window

        ;; TODO: Select new folder
        ;; * LoadActiveWindowIconTable
        ;; * Iterate icons
        ;; * Compare name w/ name from dialog
        ;; * If match, make it selected


        ;; TODO: Scroll into view

done:   jmp     redraw_windows_and_desktop

name_ptr:
        .addr   0
.endproc
        cmd_new_folder := cmd_new_folder_impl::start
        path_buffer := cmd_new_folder_impl::path_buffer ; ???

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

str_quit_code:  PASCAL_STRING "Quit.tmp"

start:
        MLI_RELAY_CALL OPEN, open_params
        bne     fail
        lda open_params::ref_num
        sta read_params::ref_num
        sta close_params::ref_num
        MLI_RELAY_CALL READ, read_params
        MLI_RELAY_CALL CLOSE, close_params

        ;; Restore system state: devices, /RAM, ROM/ZP banks.
        jsr     restore_system

quit:   jmp     quit_code_addr

fail:   jsr     ShowAlert
        rts

.endproc
        cmd_quit := cmd_quit_impl::start

;;; ============================================================
;;; Exit DHR, restore device list, reformat /RAM.
;;; Returns with ALTZPOFF and ROM banked in.

.proc restore_system
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
        bne     :+
        rts

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
        copy    active_window_id, getwinport_params2::window_id
        jsr     get_port2
        jsr     offset_grafport2_and_set
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, grafport2::cliprect
        lda     active_window_id
        jsr     L7D5D
        stax    L51EB
        sty     L51ED
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$1F
        lda     #$00
L5162:  sta     ($06),y
        dey
        cpy     #$1B
        bne     L5162

        ldy     #$23
        ldx     #$03
L516D:  lda     L51EB,x
        sta     ($06),y
        dey
        dex
        bpl     L516D

        lda     active_window_id
        jsr     create_file_icon_ep2
        copy    active_window_id, getwinport_params2::window_id
        jsr     get_set_port2
        jsr     cached_icons_window_to_screen
        copy    #0, L51EF
L518D:  lda     L51EF
        cmp     cached_window_icon_count
        beq     L51A7
        tax
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup
        ldy     #DT_ADD_ICON
        jsr     DESKTOP_RELAY   ; icon entry addr in A,X
        inc     L51EF
        jmp     L518D

L51A7:  jsr     reset_grafport3
        jsr     cached_icons_screen_to_window
        jsr     StoreWindowIconTable
        jsr     update_scrollbars
        lda     selected_window_index
        beq     L51E3
        lda     selected_icon_count
        beq     L51E3
        sta     L51EF
L51C0:  ldx     L51EF
        lda     selected_icon_count,x
        sta     icon_param
        jsr     icon_window_to_screen
        jsr     offset_grafport2_and_set
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
        lda     icon_param
        jsr     icon_screen_to_window
        dec     L51EF
        bne     L51C0
L51E3:  jmp     LoadDesktopIconTable

L51EB:  .word   0
L51ED:  .byte   0
        .byte   0
L51EF:  .byte   0
.endproc

;;; ============================================================

.proc view_by_nonicon_common
        ldx     active_window_id
        dex
        sta     win_view_by_table,x
        jsr     LoadActiveWindowIconTable
        jsr     sort_records
        jsr     StoreWindowIconTable
        copy    active_window_id, getwinport_params2::window_id
        jsr     get_port2
        jsr     offset_grafport2_and_set
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, grafport2::cliprect
        lda     active_window_id
        jsr     L7D5D
        stax    L5263
        sty     L5265
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$1F
        lda     #$00
L523B:  sta     ($06),y
        dey
        cpy     #$1B
        bne     L523B

        ldy     #$23
        ldx     #$03
L5246:  lda     L5263,x
        sta     ($06),y
        dey
        dex
        bpl     L5246

        copy    #$80, draw_window_header_flag
        jsr     reset_grafport3
        jsr     L6C19
        jsr     update_scrollbars
        copy    #0, draw_window_header_flag
        rts

L5263:  .word   0

L5265:  .byte   0
        .byte   0
.endproc

;;; ============================================================

.proc cmd_view_by_name
        ldx     active_window_id
        bne     :+
        rts

:       dex
        lda     win_view_by_table,x
        cmp     #view_by_name
        bne     :+
        rts

:       cmp     #$00
        bne     :+
        jsr     close_active_window
:       jsr     update_view_menu_check
        lda     #view_by_name
        jmp     view_by_nonicon_common
.endproc

;;; ============================================================

.proc cmd_view_by_date
        ldx     active_window_id
        bne     :+
        rts

:       dex
        lda     win_view_by_table,x
        cmp     #view_by_date
        bne     :+
        rts

:       cmp     #$00
        bne     :+
        jsr     close_active_window
:       jsr     update_view_menu_check
        lda     #view_by_date
        jmp     view_by_nonicon_common
.endproc

;;; ============================================================

.proc cmd_view_by_size
        ldx     active_window_id
        bne     :+
        rts

:       dex
        lda     win_view_by_table,x
        cmp     #view_by_size
        bne     :+
        rts

:       cmp     #$00
        bne     :+
        jsr     close_active_window
:       jsr     update_view_menu_check
        lda     #view_by_size
        jmp     view_by_nonicon_common
.endproc

;;; ============================================================

.proc cmd_view_by_type
        ldx     active_window_id
        bne     :+
        rts

:       dex
        lda     win_view_by_table,x
        cmp     #view_by_type
        bne     :+
        rts

:       cmp     #$00
        bne     :+
        jsr     close_active_window
:       jsr     update_view_menu_check
        lda     #view_by_type
        jmp     view_by_nonicon_common
.endproc

;;; ============================================================

.proc update_view_menu_check
        ;; Uncheck last checked
        lda     #MGTK::checkitem_uncheck
        sta     checkitem_params::check
        MGTK_RELAY_CALL MGTK::CheckItem, checkitem_params

        ;; Check the new one
        lda     menu_click_params::item_num           ; index of View menu item to check
        sta     checkitem_params::menu_item
        lda     #MGTK::checkitem_check
        sta     checkitem_params::check
        MGTK_RELAY_CALL MGTK::CheckItem, checkitem_params
        rts
.endproc

;;; ============================================================

.proc close_active_window
        DESKTOP_RELAY_CALL DT_CLOSE_WINDOW, active_window_id
        jsr     LoadActiveWindowIconTable
        lda     icon_count
        sec
        sbc     cached_window_icon_count
        sta     icon_count
        ldx     #0
loop:   cpx     cached_window_icon_count
        beq     done
        lda     cached_window_icon_list,x
        jsr     FreeIcon
        copy    #0, cached_window_icon_list,x
        inx
        jmp     loop

done:   jsr     StoreWindowIconTable
        jmp     LoadDesktopIconTable
.endproc

;;; ============================================================

;;; Set after format, erase, failed open, etc.
;;; Used by 'cmd_check_single_drive_by_XXX'; may be unit number
;;; or device index depending on call site.
drive_to_refresh:
        .byte   0

;;; ============================================================

.proc cmd_format_disk
        lda     #dynamic_routine_format_erase
        jsr     load_dynamic_routine
        bmi     fail

        lda     #$04
        jsr     dynamic_routine_800
        bne     :+
        stx     drive_to_refresh ; unit number
        jsr     redraw_windows_and_desktop
        jsr     cmd_check_single_drive_by_unit_number
:       jmp     redraw_windows_and_desktop

fail:   rts
.endproc

;;; ============================================================

.proc cmd_erase_disk
        lda     #dynamic_routine_format_erase
        jsr     load_dynamic_routine
        bmi     done

        lda     #$05
        jsr     dynamic_routine_800
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
        cmp     #1              ; Trash
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
        jsr     L5431
        bmi     next_icon
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

L5431:  ldx     #7
L5433:  cmp     window_to_dir_icon_table,x
        beq     L543E
        dex
        bpl     L5433
        return  #$FF

L543E:  inx
        txa
        rts
.endproc

;;; ============================================================
;;; Handle keyboard-based icon selection ("highlighting")

.proc cmd_higlight
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
        bpl     L5464
        jmp     L54C5

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
        jsr     icon_window_to_screen
        DESKTOP_RELAY_CALL DT_ICON_IN_RECT, icon_param
        pha
        lda     icon_param
        jsr     icon_screen_to_window
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
        and     #icon_entry_winid_mask
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
        and     #icon_entry_winid_mask
        sta     getwinport_params2::window_id
        beq     L5614
        jsr     L56F9
        lda     icon_param
        jsr     icon_window_to_screen
L5614:  DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
        lda     getwinport_params2::window_id
        beq     L562B
        lda     icon_param
        jsr     icon_screen_to_window
        jsr     reset_grafport3
L562B:  rts

L562C:  lda     icon_param
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        sta     getwinport_params2::window_id
        beq     L564A
        jsr     L56F9
        lda     icon_param
        jsr     icon_window_to_screen
L564A:  DESKTOP_RELAY_CALL DT_UNHIGHLIGHT_ICON, icon_param
        lda     getwinport_params2::window_id
        beq     L5661
        lda     icon_param
        jsr     icon_screen_to_window
        jsr     reset_grafport3
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
        bpl     L5676
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
        jsr     L56F9
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
        jsr     icon_window_to_screen
L56CF:  DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param2
        lda     LE22C
        beq     L56E3
        lda     icon_param2
        jsr     icon_screen_to_window
L56E3:  dec     L56F8
        bpl     L56B4
        lda     selected_window_index
        beq     L56F0
        jsr     reset_grafport3
L56F0:  jmp     LoadDesktopIconTable

L56F8:  .byte   0
.endproc

;;; ============================================================

.proc L56F9
        sta     getwinport_params2::window_id
        jsr     get_port2
        jmp     offset_grafport2_and_set
.endproc

;;; ============================================================
;;; Handle keyboard-based window activation

.proc cmd_activate
        lda     active_window_id
        bne     L5708
        rts

L5708:  sta     $800
        ldy     #$01
        ldx     #$00
L570F:  lda     window_to_dir_icon_table,x
        beq     L5720
        inx
        cpx     active_window_id
        beq     L5721
        txa
        dex
        sta     $800,y
        iny
L5720:  inx
L5721:  cpx     #$08
        bne     L570F
        sty     L578D
        cpy     #$01
        bne     L572D
        rts

L572D:  copy    #0, L578C
L5732:  jsr     get_event
        lda     event_kind
        cmp     #MGTK::EventKind::key_down
        beq     L5743
        cmp     #MGTK::EventKind::button_down
        bne     L5732
        jmp     L578B

L5743:  lda     event_key
        and     #CHAR_MASK
        cmp     #CHAR_RETURN
        beq     L578B
        cmp     #CHAR_ESCAPE
        beq     L578B
        cmp     #CHAR_LEFT
        beq     L5772
        cmp     #CHAR_RIGHT
        bne     L5732
        ldx     L578C
        inx
        cpx     L578D
        bne     L5763
        ldx     #$00
L5763:  stx     L578C
        lda     $800,x
        sta     findwindow_window_id
        jsr     handle_inactive_window_click
        jmp     L5732

L5772:  ldx     L578C
        dex
        bpl     L577C
        ldx     L578D
        dex
L577C:  stx     L578C
        lda     $800,x
        sta     findwindow_window_id
        jsr     handle_inactive_window_click
        jmp     L5732

L578B:  rts

L578C:  .byte   0
L578D:  .byte   0

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
;;; Keyboard-based scrolling of window contents

.proc cmd_scroll
        jsr     L5803
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

.proc L5803
        jsr     LoadActiveWindowIconTable
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        sta     active_window_view_by
        jsr     L58C3
        stax    L585F
        sty     horiz_scroll_flag
        jsr     L58E2
        stax    L5861
        sty     vert_scroll_flag
        rts
.endproc

;;; ============================================================

scroll_right:                   ; elevator right / contents left
        ldax    L585F
        jsr     L5863
        sta     L585F
        rts

scroll_left:                    ; elevator left / contents right
        lda     L585F
        jsr     L587E
        sta     L585F
        rts

scroll_down:                    ; elevator down / contents up
        ldax    L5861
        jsr     L5893
        sta     L5861
        rts

scroll_up:                      ; elevator up / contents down
        lda     L5861
        jsr     L58AE
        sta     L5861
        rts

horiz_scroll_flag:      .byte   0 ; can scroll horiz?
vert_scroll_flag:       .byte   0 ; can scroll vert?
L585F:  .word   0
L5861:  .word   0

.proc L5863
        stx     L587D
        cmp     L587D
        beq     :+
        sta     updatethumb_stash
        inc     updatethumb_stash
        lda     #MGTK::Ctl::horizontal_scroll_bar
        sta     updatethumb_which_ctl
        jsr     L5C54
        lda     updatethumb_stash
:       rts

L587D:  .byte   0
.endproc

.proc L587E
        beq     :+
        sta     updatethumb_stash
        dec     updatethumb_stash
        lda     #MGTK::Ctl::horizontal_scroll_bar
        sta     updatethumb_which_ctl
        jsr     L5C54
        lda     updatethumb_stash
:       rts
        .byte   0
.endproc

.proc L5893
        stx     L58AD
        cmp     L58AD
        beq     :+
        sta     updatethumb_stash
        inc     updatethumb_stash
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        jsr     L5C54
        lda     updatethumb_stash
:       rts

L58AD:  .byte   0
.endproc

.proc L58AE
        beq     :+
        sta     updatethumb_stash
        dec     updatethumb_stash
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        jsr     L5C54
        lda     updatethumb_stash
:       rts

        .byte   0
.endproc

.proc L58C3
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$06
        lda     ($06),y
        tax
        iny
        lda     ($06),y
        pha
        ldy     #$04
        lda     ($06),y
        and     #$01
        clc
        ror     a
        ror     a
        tay
        pla
        rts
.endproc

.proc L58E2
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$08
        lda     ($06),y
        tax
        iny
        lda     ($06),y
        pha
        ldy     #$05
        lda     ($06),y
        and     #$01
        clc
        ror     a
        ror     a
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
        DESKTOP_RELAY_CALL DT_REMOVE_ICON, icon_param
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
        lda     #ERR_DUPLICATE_VOL_NAME
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
        ldy     #DT_ADD_ICON
        jsr     DESKTOP_RELAY   ; icon entry addr in A,X
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
:       jsr     icon_entry_lookup
        addax   #IconEntry::len, $06

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
        jsr     reset_grafport3
        DESKTOP_RELAY_CALL DT_REMOVE_ICON, icon_param

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
        cmp     #$2F            ; there was an error ($2F = ???)
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
        ldy     #DT_ADD_ICON
        jsr     DESKTOP_RELAY   ; icon entry addr in A,X

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

        ;; Restore event coords (following detect_double_click)
        COPY_STRUCT MGTK::Point, saved_event_coords, event_coords

        MGTK_RELAY_CALL MGTK::FindControl, event_coords
        lda     findcontrol_which_ctl
        bne     :+
        jmp     handle_content_click ; 0 = ctl_not_a_control
:       bit     double_click_flag
        bmi     :+
        jmp     done_client_click ; ignore double click
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
:       jsr     L5803
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
pgup:   jsr     L638C
        lda     #MGTK::Part::page_up
        jsr     check_control_repeat
        bpl     pgup
        jmp     done_client_click

pgdn:   jsr     L63EC
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
:       jsr     L5803
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
pglt:   jsr     L6451
        lda     #MGTK::Part::page_left
        jsr     check_control_repeat
        bpl     pglt
        jmp     done_client_click

pgrt:   jsr     L64B0
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
:       jsr     L5C54
        jsr     StoreWindowIconTable
        jmp     LoadDesktopIconTable
.endproc

;;; ============================================================

.proc L5C54
        lda     updatethumb_stash
        sta     updatethumb_thumbpos
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     L6523
        jsr     L84D1
        bit     active_window_view_by
        bmi     :+
        jsr     cached_icons_screen_to_window
:       copy    active_window_id, getwinport_params2::window_id
        jsr     get_set_port2
        MGTK_RELAY_CALL MGTK::PaintRect, grafport2::cliprect
        jsr     reset_grafport3
        jmp     L6C19
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
        bit     active_window_view_by
        bpl     :+
        jmp     clear_selection

:       copy    active_window_id, findicon_window_id
        DESKTOP_RELAY_CALL DT_FIND_ICON, findicon_params
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
:       ldx     selected_icon_count
        lda     icon_num
        sta     selected_icon_list,x
        inc     selected_icon_count

        copy    active_window_id, selected_window_index
        copy    active_window_id, getwinport_params2::window_id

        jsr     get_set_port2
        copy    icon_num, icon_param
        jsr     icon_window_to_screen
        jsr     offset_grafport2_and_set
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
        copy    active_window_id, getwinport_params2::window_id
        jsr     get_set_port2
        lda     icon_num
        jsr     icon_screen_to_window
        jsr     reset_grafport3
        bit     double_click_flag
        bmi     start_icon_drag
        jmp     handle_double_click

        ;; --------------------------------------------------

start_icon_drag:
        copy    icon_num, drag_drop_param
        DESKTOP_RELAY_CALL DT_DRAG_HIGHLIGHTED, drag_drop_param
        tax
        lda     drag_drop_param
        beq     desktop

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
:       lda     drag_drop_param
        cmp     trash_icon_num
        bne     :+
        ;; Update used/free for same-vol windows
        jsr     update_active_window
        jmp     redraw_windows_and_desktop

        ;; Dropped on icon?
:       lda     drag_drop_param
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
        copy    active_window_id, getwinport_params2::window_id
        jsr     get_set_port2
        jsr     cached_icons_window_to_screen
        jsr     offset_grafport2_and_set

        ldx     selected_icon_count
        dex
:       txa
        pha
        lda     selected_icon_list,x
        sta     redraw_icon_param
        DESKTOP_RELAY_CALL DT_REDRAW_ICON, redraw_icon_param
        pla
        tax
        dex
        bpl     :-

        copy    active_window_id, getwinport_params2::window_id
        jsr     get_set_port2
        jsr     update_scrollbars
        jsr     cached_icons_screen_to_window
        jsr     reset_grafport3

;;; Used as additional entry point
swap_in_desktop_icon_table:
        jsr     StoreWindowIconTable
        jmp     LoadDesktopIconTable

L5DF7:  ldx     saved_stack
        txs
        rts

handle_double_click:
        lda     icon_num           ; after a double-click (on file or folder)
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_type_mask

        cmp     #icon_entry_type_trash
        beq     done
        cmp     #icon_entry_type_dir
        bne     file

        ;; Directory
        lda     icon_num
        jsr     open_folder_or_volume_icon
        bmi     done
        jmp     swap_in_desktop_icon_table
done:   rts

        ;; File (executable or data)
file:   sta     L5E77
        lda     active_window_id
        jsr     window_path_lookup
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L5E3A:  lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     L5E3A
        lda     icon_num
        jsr     icon_entry_lookup
        stax    $06
        ldy     #$09
        lda     ($06),y
        tax
        clc
        adc     #$09
        tay
        dex
        dey
L5E57:  lda     ($06),y
        sta     buf_filename2-1,x
        dey
        dex
        bne     L5E57
        ldy     #$09
        lda     ($06),y
        tax
        dex
        dex
        stx     buf_filename2
        lda     L5E77
        cmp     #$20
        bcc     L5E74
        lda     L5E77
L5E74:  jmp     launch_file     ; when double-clicked

.proc update_active_window
        lda     active_window_id
        jsr     update_used_free_for_vol_windows
        lda     active_window_id
        jmp     select_and_refresh_window
.endproc

L5E77:  .byte   0

.endproc
        handle_file_icon_click := handle_file_icon_click_impl::start
        swap_in_desktop_icon_table := handle_file_icon_click_impl::swap_in_desktop_icon_table

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

:       copy    active_window_id, getwinport_params2::window_id
        jsr     get_set_port2
        jsr     set_penmode_copy
        MGTK_RELAY_CALL MGTK::PaintRect, grafport2::cliprect
        ldx     active_window_id
        dex
        lda     window_to_dir_icon_table,x
        pha
        jsr     L7345
        lda     window_id
        tax
        dex
        lda     win_view_by_table,x
        bmi     :+
        jsr     close_active_window
:       lda     active_window_id
        jsr     window_path_lookup

        ptr := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     LE1B0,y
        dey
        bpl     :-

        pla
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
        copy    active_window_id, getwinport_params2::window_id
        jsr     get_port2
        jsr     offset_grafport2_and_set
        ldx     #$03
L5F50:  lda     pt1,x
        sta     tmp_rect::x1,x
        lda     pt2,x
        sta     tmp_rect::x2,x
        dex
        bpl     L5F50
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, tmp_rect
L5F6B:  jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::drag
        beq     L5FC5
        MGTK_RELAY_CALL MGTK::FrameRect, tmp_rect
        ldx     #$00
L5F80:  cpx     cached_window_icon_count
        bne     L5F88
        jmp     reset_grafport3

L5F88:  txa
        pha
        lda     cached_window_icon_list,x
        sta     icon_param
        jsr     icon_window_to_screen
        DESKTOP_RELAY_CALL DT_ICON_IN_RECT, icon_param
        beq     L5FB9
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
        ldx     selected_icon_count
        inc     selected_icon_count
        copy    icon_param, selected_icon_list,x
        copy    active_window_id, selected_window_index
L5FB9:  lda     icon_param
        jsr     icon_screen_to_window
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

L601F:  MGTK_RELAY_CALL MGTK::FrameRect, tmp_rect

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
L60BF:  MGTK_RELAY_CALL MGTK::FrameRect, tmp_rect
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
        jmp     icon_ptr_window_to_screen
.endproc
        L5F13 := L5F13_impl::start

;;; ============================================================

.proc handle_title_click
        jmp     L60DE

L60DE:  copy    active_window_id, event_params
        MGTK_RELAY_CALL MGTK::FrontWindow, active_window_id
        lda     active_window_id
        jsr     copy_window_portbits
        MGTK_RELAY_CALL MGTK::DragWindow, event_params
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$16
        lda     ($06),y
        cmp     #$19
        bcs     L6112
        lda     #$19
        sta     ($06),y
L6112:  ldy     #$14

        sub16in ($06),y, port_copy+MGTK::GrafPort::viewloc+MGTK::Point::xcoord, L6197
        iny
        sub16in ($06),y, port_copy+MGTK::GrafPort::viewloc+MGTK::Point::ycoord, L6199

        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        beq     L6143
        rts

L6143:  jsr     LoadActiveWindowIconTable
        ldx     #$00
L614E:  cpx     cached_window_icon_count
        bne     L6161
        jsr     StoreWindowIconTable
        jsr     LoadDesktopIconTable
        jmp     L6196

L6161:  txa
        pha
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup
        stax    $06
        ldy     #$03
        add16in ($06),y, L6197, ($06),y
        iny
        add16in ($06),y, L6199, ($06),y
        pla
        tax
        inx
        jmp     L614E

L6196:  rts

L6197:  .word   0
L6199:  .word   0

.endproc

;;; ============================================================

.proc handle_resize_click
        copy    active_window_id, event_params
        MGTK_RELAY_CALL MGTK::GrowWindow, event_params
        jsr     redraw_windows_and_desktop
        jsr     LoadActiveWindowIconTable
        jsr     cached_icons_window_to_screen
        jsr     update_scrollbars
        jsr     cached_icons_screen_to_window
        jsr     LoadDesktopIconTable
        jmp     reset_grafport3
.endproc

;;; ============================================================

handle_close_click:
        lda     active_window_id
        MGTK_RELAY_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        bne     close_window
        rts

.proc close_window
        jsr     LoadActiveWindowIconTable
        jsr     clear_selection
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        bmi     L6215
        lda     icon_count
        sec
        sbc     cached_window_icon_count
        sta     icon_count
        DESKTOP_RELAY_CALL DT_CLOSE_WINDOW, active_window_id
        ldx     #$00
L6206:  cpx     cached_window_icon_count
        beq     L6215
        lda     cached_window_icon_list,x
        jsr     FreeIcon
        inx
        jmp     L6206

L6215:  dec     LEC2E
        ldx     #$00
        txa
L621B:  sta     cached_window_icon_list,x
        cpx     cached_window_icon_count
        beq     L6227
        inx
        jmp     L621B

L6227:  sta     cached_window_icon_count
        jsr     StoreWindowIconTable
        MGTK_RELAY_CALL MGTK::CloseWindow, active_window_id
        ldx     active_window_id
        dex
        lda     window_to_dir_icon_table,x
        sta     icon_param
        jsr     icon_entry_lookup
        stax    $06
        ldy     #1
        lda     ($06),y
        and     #$0F
        beq     L6276
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #AS_BYTE(~icon_entry_open_mask) ; clear open_flag
        sta     ($06),y
        and     #icon_entry_winid_mask
        sta     selected_window_index
        jsr     zero_grafport5_coords
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
        jsr     reset_grafport3
        copy    #1, selected_icon_count
        copy    icon_param, selected_icon_list
L6276:  ldx     active_window_id
        dex
        lda     window_to_dir_icon_table,x
        jsr     L7345
        ldx     active_window_id
        dex
        lda     window_to_dir_icon_table,x
        inx
        jsr     animate_window_close
        ldx     active_window_id
        dex
        lda     #$00
        sta     window_to_dir_icon_table,x
        sta     win_view_by_table,x
        MGTK_RELAY_CALL MGTK::FrontWindow, active_window_id
        jsr     LoadDesktopIconTable
        lda     #MGTK::checkitem_uncheck
        sta     checkitem_params::check
        MGTK_RELAY_CALL MGTK::CheckItem, checkitem_params
        jsr     update_window_menu_items
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================

.proc L62BC
        cmp     #$01
        bcc     L62C2
        bne     L62C5
L62C2:  return  #0

L62C5:  sta     L638B
        stx     L6386
        sty     L638A
        cmp     L6386
        bcc     L62D5
        tya
        rts

L62D5:  lda     #$00
        sta     L6385
        sta     L6389
        clc
        ror     L6386
        ror     L6385
        clc
        ror     L638A
        ror     L6389
        lda     #$00
        sta     L6383
        sta     L6387
        sta     L6384
        sta     L6388
L62F9:  lda     L6384
        cmp     L638B
        beq     L630F
        bcc     L6309
        jsr     L6319
        jmp     L62F9

L6309:  jsr     L634E
        jmp     L62F9

L630F:  lda     L6388
        cmp     #$01
        bcs     L6318
        lda     #$01
L6318:  rts

L6319:  sub16   L6383, L6385, L6383
        sub16   L6387, L6389, L6387
        clc
        ror     L6386
        ror     L6385
        clc
        ror     L638A
        ror     L6389
        rts

L634E:  add16   L6383, L6385, L6383
        add16   L6387, L6389, L6387
        clc
        ror     L6386
        ror     L6385
        clc
        ror     L638A
        ror     L6389
        rts

L6383:  .byte   0
L6384:  .byte   0
L6385:  .byte   0
L6386:  .byte   0
L6387:  .byte   0
L6388:  .byte   0
L6389:  .byte   0
L638A:  .byte   0
L638B:  .byte   0

.endproc

;;; ============================================================

.proc L638C
        jsr     L650F
        sty     L63E9
        jsr     L644C
        sta     L63E8
        sub16_8 grafport2::cliprect::y1, L63E8, L63EA
        cmp16   L63EA, iconbb_rect+MGTK::Rect::y1
        bmi     L63C1
        ldax    L63EA
        jmp     L63C7

L63C1:  ldax    iconbb_rect+MGTK::Rect::y1
L63C7:  stax    grafport2::cliprect::y1
        add16_8 grafport2::cliprect::y1, L63E9, grafport2::cliprect::y2
        jsr     assign_active_window_cliprect
        jsr     update_scrollbars
        jmp     L6556

L63E8:  .byte   0
L63E9:  .byte   0
L63EA:  .word   0

.endproc

;;; ============================================================

.proc L63EC
        jsr     L650F
        sty     L6449
        jsr     L644C
        sta     L6448
        add16_8 grafport2::cliprect::y2, L6448, L644A
        cmp16   L644A, iconbb_rect+MGTK::Rect::y2
        bpl     L6421
        ldax    L644A
        jmp     L6427

L6421:  ldax    iconbb_rect+MGTK::Rect::y2
L6427:  stax    grafport2::cliprect::y2
        sub16_8 grafport2::cliprect::y2, L6449, grafport2::cliprect::y1
        jsr     assign_active_window_cliprect
        jsr     update_scrollbars
        jmp     L6556

L6448:  .byte   0
L6449:  .byte   0
L644A:  .word   0
.endproc

;;; ============================================================

.proc L644C
        tya
        sec
        sbc     #$0E
        rts
.endproc

;;; ============================================================

.proc L6451
        jsr     L650F
        stax    L64AC
        sub16   grafport2::cliprect::x1, L64AC, L64AE
        cmp16   L64AE, iconbb_rect+MGTK::Rect::x1
        bmi     L6484
        ldax    L64AE
        jmp     L648A

L6484:  ldax    iconbb_rect+MGTK::Rect::x1
L648A:  stax    grafport2::cliprect::x1
        add16   grafport2::cliprect::x1, L64AC, grafport2::cliprect::x2
        jsr     assign_active_window_cliprect
        jsr     update_scrollbars
        jmp     L6556

L64AC:  .word   0
L64AE:  .word   0
.endproc

;;; ============================================================

.proc L64B0
        jsr     L650F
        stax    L650B
        add16   grafport2::cliprect::x2, L650B, L650D
        cmp16   L650D, iconbb_rect+MGTK::Rect::x2
        bpl     L64E3
        ldax    L650D
        jmp     L64E9

L64E3:  ldax    iconbb_rect+MGTK::Rect::x2
L64E9:  stax    grafport2::cliprect::x2
        sub16   grafport2::cliprect::x2, L650B, grafport2::cliprect::x1
        jsr     assign_active_window_cliprect
        jsr     update_scrollbars
        jmp     L6556

L650B:  .word   0
L650D:  .word   0
.endproc

.proc L650F
        bit     active_window_view_by
        bmi     :+
        jsr     cached_icons_window_to_screen
:       jsr     L6523
        jsr     compute_icons_bbox
        lda     active_window_id
        jmp     L7D5D
.endproc

.proc L6523
        lda     active_window_id
        jsr     window_lookup
        addax   #$14, $06
        ldy     #$25
:       lda     ($06),y
        sta     grafport2,y
        dey
        bpl     :-
        rts
.endproc

.proc assign_active_window_cliprect
        ptr := $6

        lda     active_window_id
        jsr     window_lookup
        stax    ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + 7
        ldx     #7
:       lda     grafport2::cliprect,x
        sta     (ptr),y
        dey
        dex
        bpl     :-
        rts
.endproc

.proc L6556
        bit     active_window_view_by
        bmi     :+
        jsr     cached_icons_screen_to_window
:       MGTK_RELAY_CALL MGTK::PaintRect, grafport2::cliprect
        jsr     reset_grafport3
        jmp     L6C19
.endproc

;;; ============================================================

.proc update_hthumb
        lda     active_window_id
        jsr     L7D5D
        stax    L6600
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$06
        lda     ($06),y
        tay
        sub16   iconbb_rect+MGTK::Rect::x2, iconbb_rect+MGTK::Rect::x1, L6602
        sub16   L6602, L6600, L6602
        lsr16    L6602
        ldx     L6602
        sub16   grafport2::cliprect::x1, iconbb_rect+MGTK::Rect::x1, L6602
        bpl     L65D0
        lda     #$00
        beq     L65EB
L65D0:  cmp16   grafport2::cliprect::x2, iconbb_rect+MGTK::Rect::x2
        bmi     L65E2
        tya
        jmp     L65EE

L65E2:  lsr16    L6602
        lda     L6602
L65EB:  jsr     L62BC
L65EE:  sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::horizontal_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        rts

L6600:  .word   0
L6602:  .word   0
.endproc

;;; ============================================================

.proc update_vthumb
        lda     active_window_id
        jsr     L7D5D
        sty     L669F
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$08
        lda     ($06),y
        tay
        sub16   iconbb_rect+MGTK::Rect::y2, iconbb_rect+MGTK::Rect::y1, L66A0
        sub16_8 L66A0, L669F, L66A0
        lsr16    L66A0
        lsr16    L66A0
        ldx     L66A0
        sub16   grafport2::cliprect::y1, iconbb_rect+MGTK::Rect::y1, L66A0
        bpl     L6669
        lda     #$00
        beq     L668A
L6669:  cmp16   grafport2::cliprect::y2, iconbb_rect+MGTK::Rect::y2
        bmi     L667B
        tya
        jmp     L668D

L667B:  lsr16   L66A0
        lsr16   L66A0
        lda     L66A0
L668A:  jsr     L62BC
L668D:  sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        rts

L669F:  .byte   0
L66A0:  .word   0
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
        copy    #menu_id_file, disableitem_params::menu_id
        copy    #desktop_aux::menu_item_id_new_folder, disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        copy    #desktop_aux::menu_item_id_close, disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        copy    #desktop_aux::menu_item_id_close_all, disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params

        copy    #0, menu_dispatch_flag
        rts

check_view_menu_items:
        dex
        lda     win_view_by_table,x
        and     #$0F
        tax
        inx
        stx     checkitem_params::menu_item
        lda     #MGTK::checkitem_check
        sta     checkitem_params::check
        MGTK_RELAY_CALL MGTK::CheckItem, checkitem_params
        rts
.endproc

;;; ============================================================
;;; Disable menu items for operating on a selected file

.proc disable_file_menu_items
        copy    #MGTK::disableitem_disable, disableitem_params::disable

        ;; File
        copy    #menu_id_file, disableitem_params::menu_id
        lda     #desktop_aux::menu_item_id_open
        jsr     disable_menu_item
        lda     #desktop_aux::menu_item_id_get_info
        jsr     disable_menu_item
        lda     #desktop_aux::menu_item_id_rename_icon
        jsr     disable_menu_item

        ;; Special
        copy    #menu_id_special, disableitem_params::menu_id
        lda     #desktop_aux::menu_item_id_lock
        jsr     disable_menu_item
        lda     #desktop_aux::menu_item_id_unlock
        jsr     disable_menu_item
        lda     #desktop_aux::menu_item_id_get_size
        jsr     disable_menu_item
        rts

disable_menu_item:
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        rts
.endproc

;;; ============================================================

.proc enable_file_menu_items
        copy    #MGTK::disableitem_enable, disableitem_params::disable

        ;; File
        copy    #menu_id_file, disableitem_params::menu_id
        lda     #desktop_aux::menu_item_id_open
        jsr     enable_menu_item
        lda     #desktop_aux::menu_item_id_get_info
        jsr     enable_menu_item
        lda     #desktop_aux::menu_item_id_rename_icon
        jsr     enable_menu_item

        ;; Special
        copy    #menu_id_special, disableitem_params::menu_id
        lda     #desktop_aux::menu_item_id_lock
        jsr     enable_menu_item
        lda     #desktop_aux::menu_item_id_unlock
        jsr     enable_menu_item
        lda     #desktop_aux::menu_item_id_get_size
        jsr     enable_menu_item
        rts

enable_menu_item:
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        rts
.endproc

;;; ============================================================

.proc toggle_eject_menu_item
enable:
        copy    #MGTK::disableitem_enable, disableitem_params::disable
        jmp     :+

disable:
        copy    #MGTK::disableitem_disable, disableitem_params::disable

:       copy    #menu_id_special, disableitem_params::menu_id
        copy    #desktop_aux::menu_item_id_eject, disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params

        copy    #menu_id_special, disableitem_params::menu_id
        copy    #desktop_aux::menu_item_id_check_drive, disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params

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

:       copy    #menu_id_selector, disableitem_params::menu_id
        lda     #menu_item_id_selector_edit
        jsr     configure_menu_item
        lda     #menu_item_id_selector_delete
        jsr     configure_menu_item
        lda     #menu_item_id_selector_run
        jsr     configure_menu_item
        copy    #$80, LD344
        rts

configure_menu_item:
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
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
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, findicon_which_icon
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
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, findicon_which_icon
        copy    #1, selected_icon_count
        copy    findicon_which_icon, selected_icon_list
        copy    #0, selected_window_index


L6834:  bit     double_click_flag
        bpl     L6880

        ;; Drag of volume icon
        copy    findicon_which_icon, drag_drop_param
        DESKTOP_RELAY_CALL DT_DRAG_HIGHLIGHTED, drag_drop_param
        tax
        lda     drag_drop_param
        beq     L6878
        jsr     jt_drop
        cmp     #$FF
        bne     L6858
        jmp     redraw_windows_and_desktop

L6858:  lda     drag_drop_param
        cmp     trash_icon_num
        bne     L6863
        jmp     redraw_windows_and_desktop

L6863:  lda     drag_drop_param
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
        DESKTOP_RELAY_CALL DT_REDRAW_ICON, icon_param3
        pla
        tax
        dex
        bpl     L6893
        rts
.endproc

;;; ============================================================

.proc L68AA
        jsr     reset_grafport3
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

L68CF:  MGTK_RELAY_CALL MGTK::SetPattern, desktop_aux::checkerboard_pattern
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, tmp_rect
L68E4:  jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::drag
        beq     L6932
        MGTK_RELAY_CALL MGTK::FrameRect, tmp_rect
        ldx     #0
L68F9:  cpx     cached_window_icon_count
        bne     :+
        lda     #0
        sta     selected_window_index
        rts

:       txa
        pha
        copy    cached_window_icon_list,x, icon_param
        DESKTOP_RELAY_CALL DT_ICON_IN_RECT, icon_param
        beq     L692C
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
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

L6989:  MGTK_RELAY_CALL MGTK::FrameRect, tmp_rect

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
L6A29:  MGTK_RELAY_CALL MGTK::FrameRect, tmp_rect
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

        ldx     #7
:       cmp     window_to_dir_icon_table,x
        beq     L6A80
        dex
        bpl     :-
        jsr     icon_entry_lookup
        addax   #IconEntry::len, ptr
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

L6A80:  inx
        txa
        pha
        jsr     update_used_free_for_vol_windows
        pla
        jmp     select_and_refresh_window
.endproc

;;; ============================================================

.proc open_folder_or_volume_icon
        sta     icon_params2
        jsr     StoreWindowIconTable
        lda     icon_params2
        ldx     #$07
L6A95:  cmp     window_to_dir_icon_table,x
        beq     L6AA0
        dex
        bpl     L6A95
        jmp     L6B1E

L6AA0:  inx
        cpx     active_window_id
        bne     L6AA7
        rts

L6AA7:  stx     cached_window_id
        jsr     LoadWindowIconTable
        lda     icon_params2
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        ora     #icon_entry_open_mask ; set open_flag
        sta     ($06),y
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        sta     getwinport_params2::window_id
        beq     L6AD8
        cmp     active_window_id
        bne     L6AEF
        jsr     get_set_port2
        lda     icon_params2
        jsr     icon_window_to_screen
L6AD8:  DESKTOP_RELAY_CALL DT_REDRAW_ICON, icon_params2
        lda     getwinport_params2::window_id
        beq     L6AEF
        lda     icon_params2
        jsr     icon_screen_to_window
        jsr     reset_grafport3
L6AEF:  lda     icon_params2
        ldx     LE1F1
        dex
L6AF6:  cmp     LE1F1+1,x
        beq     L6B01
        dex
        bpl     L6AF6
        jsr     open_directory
L6B01:  MGTK_RELAY_CALL MGTK::SelectWindow, cached_window_id
        lda     cached_window_id
        sta     active_window_id
        jsr     L6C19
        jsr     redraw_windows
        jmp     LoadDesktopIconTable

L6B1E:  lda     LEC2E
        cmp     #$08
        bcc     L6B2F
        lda     #warning_msg_too_many_windows
        jsr     warning_dialog_proc_num
        ldx     saved_stack
        txs
        rts

L6B2F:  ldx     #$00
L6B31:  lda     window_to_dir_icon_table,x
        beq     L6B3A
        inx
        jmp     L6B31

L6B3A:  lda     icon_params2
        sta     window_to_dir_icon_table,x
        inx
        stx     cached_window_id
        jsr     LoadWindowIconTable
        inc     LEC2E
        ldx     cached_window_id
        dex
        copy    #0, win_view_by_table,x
        lda     LEC2E
        cmp     #$02
        bcs     L6B60
        jsr     enable_various_file_menu_items
        jmp     L6B68

L6B60:  copy    #0, checkitem_params::check
        jsr     check_item
L6B68:  lda     #desktop_aux::menu_item_id_view_by_icon
        sta     checkitem_params::menu_item
        sta     checkitem_params::check
        jsr     check_item
        lda     icon_params2
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        ora     #icon_entry_open_mask ; set open_flag
        sta     ($06),y
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        sta     getwinport_params2::window_id
        beq     L6BA1
        cmp     active_window_id
        bne     L6BB8
        jsr     get_set_port2
        jsr     offset_grafport2_and_set
        lda     icon_params2
        jsr     icon_window_to_screen
L6BA1:  DESKTOP_RELAY_CALL DT_REDRAW_ICON, icon_params2
        lda     getwinport_params2::window_id
        beq     L6BB8
        lda     icon_params2
        jsr     icon_screen_to_window
        jsr     reset_grafport3
L6BB8:  jsr     L744B

        lda     cached_window_id
        jsr     window_lookup
        ldy     #MGTK::OpenWindow
        jsr     MGTK_RELAY

        copy    active_window_id, getwinport_params2::window_id
        jsr     get_set_port2
        jsr     draw_window_header
        jsr     cached_icons_window_to_screen
        copy    #0, L6C0E
L6BDA:  lda     L6C0E
        cmp     cached_window_icon_count
        beq     L6BF4
        tax
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup
        ldy     #DT_ADD_ICON
        jsr     DESKTOP_RELAY   ; icon entry addr in A,X
        inc     L6C0E
        jmp     L6BDA

L6BF4:  lda     cached_window_id
        sta     active_window_id
        jsr     update_scrollbars
        jsr     cached_icons_screen_to_window
        jsr     StoreWindowIconTable
        jsr     LoadDesktopIconTable
        jmp     reset_grafport3

L6C0E:  .byte   0
.endproc

;;; ============================================================

.proc check_item
        MGTK_RELAY_CALL MGTK::CheckItem, checkitem_params
        rts
.endproc

;;; ============================================================

.proc L6C19
        ldx     cached_window_id
        dex
        lda     win_view_by_table,x
        bmi     L6C25
        jmp     L6CCD

L6C25:  jsr     push_pointers
        lda     cached_window_id
        sta     getwinport_params2::window_id
        jsr     get_set_port2
        bit     draw_window_header_flag
        bmi     :+
        jsr     draw_window_header
:       lda     cached_window_id
        sta     getwinport_params2::window_id
        jsr     get_port2
        bit     draw_window_header_flag
        bmi     :+
        jsr     offset_grafport2_and_set
:       ldx     cached_window_id
        dex
        lda     window_to_dir_icon_table,x
        ldx     #$00
L6C53:  cmp     LE1F1+1,x
        beq     L6C5F
        inx
        cpx     LE1F1
        bne     L6C53
        rts

L6C5F:  txa
        asl     a
        tax
        lda     LE202,x
        sta     LE71D
        sta     $06
        lda     LE202+1,x
        sta     LE71D+1
        sta     $06+1
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
        lda     ($06),y
        tay
        lda     LCBANK1
        lda     LCBANK1
        tya
        sta     LE71F
        inc     LE71D
        bne     L6C8F
        inc     LE71D+1

        ;; First row
.proc L6C8F
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
        lda     #0
        sta     rows_done
rloop:  lda     rows_done
        cmp     cached_window_icon_count
        beq     done
        tax
        lda     cached_window_icon_list,x
        jsr     L813F
        inc     rows_done
        jmp     rloop

done:   jsr     reset_grafport3
        jsr     pop_pointers
        rts

rows_done:
        .byte   0
.endproc

L6CCD:  lda     cached_window_id
        sta     getwinport_params2::window_id
        jsr     get_set_port2
        bit     draw_window_header_flag
        bmi     :+
        jsr     draw_window_header
:       jsr     cached_icons_window_to_screen
        jsr     offset_grafport2_and_set

        COPY_BLOCK grafport2::cliprect, tmp_rect

        ldx     #$00
        txa
        pha
L6CF3:  cpx     cached_window_icon_count
        bne     L6D09
        pla
        jsr     reset_grafport3
        lda     cached_window_id
        sta     getwinport_params2::window_id
        jsr     get_set_port2
        jsr     cached_icons_screen_to_window
        rts

L6D09:  txa
        pha
        lda     cached_window_icon_list,x
        sta     icon_param
        DESKTOP_RELAY_CALL DT_ICON_IN_RECT, icon_param
        beq     L6D25
        DESKTOP_RELAY_CALL DT_REDRAW_ICON, icon_param
L6D25:  pla
        tax
        inx
        jmp     L6CF3
.endproc

;;; ============================================================

.proc clear_selection
        lda     selected_icon_count
        bne     L6D31
        rts

L6D31:  copy    #0, L6DB0
        copy    selected_window_index, tmp_rect ; ???
        beq     L6D7D
        cmp     active_window_id
        beq     L6D4D
        jsr     zero_grafport5_coords
        copy    #0, tmp_rect
        beq     L6D56
L6D4D:  sta     getwinport_params2::window_id
        jsr     get_set_port2
        jsr     offset_grafport2_and_set
L6D56:  lda     L6DB0
        cmp     selected_icon_count
        beq     L6D9B
        tax
        lda     selected_icon_list,x
        sta     icon_param
        jsr     icon_window_to_screen
        DESKTOP_RELAY_CALL DT_UNHIGHLIGHT_ICON, icon_param
        lda     icon_param
        jsr     icon_screen_to_window
        inc     L6DB0
        jmp     L6D56

L6D7D:  lda     L6DB0
        cmp     selected_icon_count
        beq     L6D9B
        tax
        lda     selected_icon_list,x
        sta     icon_param
        DESKTOP_RELAY_CALL DT_UNHIGHLIGHT_ICON, icon_param
        inc     L6DB0
        jmp     L6D7D

L6D9B:  lda     #$00
        ldx     selected_icon_count
        dex
L6DA1:  sta     selected_icon_list,x
        dex
        bpl     L6DA1
        sta     selected_icon_count
        sta     selected_window_index
        jmp     reset_grafport3

L6DB0:  .byte   0
.endproc

;;; ============================================================

.proc update_scrollbars
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        bmi     :+
        jsr     compute_icons_bbox
        jmp     config_port

:       jsr     cached_icons_window_to_screen
        jsr     compute_icons_bbox
        jsr     cached_icons_screen_to_window

config_port:
        copy    active_window_id, getwinport_params2::window_id
        jsr     get_set_port2

        ;; check horizontal bounds
        cmp16   iconbb_rect+MGTK::Rect::x1, grafport2::cliprect::x1
        bmi     activate_hscroll
        cmp16   grafport2::cliprect::x2, iconbb_rect+MGTK::Rect::x2
        bmi     activate_hscroll

        ;; deactivate horizontal scrollbar
        lda     #MGTK::Ctl::horizontal_scroll_bar
        sta     activatectl_which_ctl
        lda     #MGTK::activatectl_deactivate
        sta     activatectl_activate
        jsr     activate_ctl

        jmp     check_vscroll

activate_hscroll:
        ;; activate horizontal scrollbar
        lda     #MGTK::Ctl::horizontal_scroll_bar
        sta     activatectl_which_ctl
        lda     #MGTK::activatectl_activate
        sta     activatectl_activate
        jsr     activate_ctl
        jsr     update_hthumb

check_vscroll:
        ;; check vertical bounds
        cmp16   iconbb_rect+MGTK::Rect::y1, grafport2::cliprect::y1
        bmi     activate_vscroll
        cmp16   grafport2::cliprect::y2, iconbb_rect+MGTK::Rect::y2
        bmi     activate_vscroll

        ;; deactivate vertical scrollbar
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_which_ctl
        lda     #MGTK::activatectl_deactivate
        sta     activatectl_activate
        jsr     activate_ctl

        rts

activate_vscroll:
        ;; activate vertical scrollbar
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_which_ctl
        lda     #MGTK::activatectl_activate
        sta     activatectl_activate
        jsr     activate_ctl
        jmp     update_vthumb

activate_ctl:
        MGTK_RELAY_CALL MGTK::ActivateCtl, activatectl_params
        rts
.endproc

;;; ============================================================

.proc cached_icons_window_to_screen
        lda     #0
        sta     count
loop:   lda     count
        cmp     cached_window_icon_count
        beq     done
        tax
        lda     cached_window_icon_list,x
        jsr     icon_window_to_screen
        inc     count
        jmp     loop

done:   rts

count:  .byte   0
.endproc

;;; ============================================================

.proc cached_icons_screen_to_window
        lda     #0
        sta     index
loop:   lda     index
        cmp     cached_window_icon_count
        beq     done
        tax
        lda     cached_window_icon_list,x
        jsr     icon_screen_to_window
        inc     index
        jmp     loop

done:   rts

index:  .byte   0
.endproc

;;; ============================================================

.proc offset_grafport2_impl

flag_clear:
        lda     #$80
        beq     :+
flag_set:
        lda     #0
:       sta     flag
        add16   grafport2::viewloc::ycoord, #15, grafport2::viewloc::ycoord
        add16   grafport2::cliprect::y1, #15, grafport2::cliprect::y1
        bit     flag
        bmi     done
        MGTK_RELAY_CALL MGTK::SetPort, grafport2
done:   rts

flag:   .byte   0
.endproc
        offset_grafport2 := offset_grafport2_impl::flag_clear
        offset_grafport2_and_set := offset_grafport2_impl::flag_set

;;; ============================================================

.proc enable_various_file_menu_items
        copy    #MGTK::disablemenu_enable, disablemenu_params::disable
        MGTK_RELAY_CALL MGTK::DisableMenu, disablemenu_params

        copy    #MGTK::disableitem_enable, disableitem_params::disable
        copy    #menu_id_file, disableitem_params::menu_id
        copy    #desktop_aux::menu_item_id_new_folder, disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        copy    #desktop_aux::menu_item_id_close, disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        copy    #desktop_aux::menu_item_id_close_all, disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params

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

        ;; If 'set' version called, length in Y; otherwise use str len
.proc find_windows
        ptr := $6

set:    stax    ptr
        lda     #$80
        bne     start

unset:  stax    ptr
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
        cmp     #9              ; windows are 1-8
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

:       lda     (ptr),y
        cmp     path_buffer,y
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
.endproc
        find_window_for_path := find_windows::set
        find_windows_for_prefix := find_windows::unset

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
        sta     L72A7
        jsr     push_pointers

        COPY_BYTES $41, LE1B0, path_buffer

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

        sub16   L485D, L485F, L72A8
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
L7147:  lda     LEC2E
        jsr     mark_icons_not_opened_1
        dec     LEC2E
        jsr     redraw_windows_and_desktop
        jsr     do_close
        lda     active_window_id
        beq     L715F
        lda     #$03
        bne     L7161
L715F:  lda     #warning_msg_window_must_be_closed2
L7161:  jsr     warning_dialog_proc_num
        ldx     saved_stack
        txs
        rts

        record_ptr := $06

L7169:  copy16  L485F, record_ptr
        lda     LE1F1
        asl     a
        tax
        copy16  record_ptr, LE202,x
        ldx     LE1F1
        lda     L72A7
        sta     LE1F1+1,x
        inc     LE1F1
        lda     L70C1

        ;; Store entry count
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
        inc     record_ptr
        lda     record_ptr
        bne     do_entry
        inc     record_ptr+1

        ;; Record is temporarily constructed at $1F00 then copied into place.
        record := $1F00
        record_size := $20

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

        ;; Copy entry composed at $1F00 to buffer in Aux LC Bank 2
        lda     LCBANK2
        lda     LCBANK2
        ldx     #record_size-1
        ldy     #record_size-1
:       lda     record,x
        sta     (record_ptr),y
        dex
        dey
        bpl     :-
        lda     LCBANK1
        lda     LCBANK1
        lda     #record_size
        clc
        adc     record_ptr
        sta     record_ptr
        bcc     L7293
        inc     record_ptr+1
L7293:  jmp     do_entry

L7296:  copy16  record_ptr, L485F
        jsr     do_close
        jsr     pop_pointers
        rts
L72A7:  .byte   0
L72A8:  .word   0
.endproc

;;; --------------------------------------------------

.proc do_open
        MLI_RELAY_CALL OPEN, open_params
        beq     done
        jsr     ShowAlert
        jsr     mark_icons_not_opened_2
        lda     selected_window_index
        bne     :+
        lda     icon_params2
        sta     drive_to_refresh ; icon number
        jsr     cmd_check_single_drive_by_icon_number
:       ldx     saved_stack
        txs
done:   rts
.endproc

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

.proc L7345
        sta     L7445
        ldx     #$00
L734A:  lda     LE1F1+1,x
        cmp     L7445
        beq     :+
        inx
        cpx     #$08
        bne     L734A
        rts

:       stx     L7446
        dex
:       inx
        lda     LE1F1+2,x
        sta     LE1F1+1,x
        cpx     LE1F1
        bne     :-

        dec     LE1F1
        lda     L7446
        cmp     LE1F1
        bne     :+
        ldx     L7446
        asl     a
        tax
        copy16  LE202,x, L485F
        rts

:       lda     L7446
        asl     a
        tax
        copy16  LE202,x, $06
        inx
        inx
        copy16  LE202,x, $08
        ldy     #$00
        jsr     push_pointers
L73A5:  lda     LCBANK2
        lda     LCBANK2
        lda     ($08),y
        sta     ($06),y
        lda     LCBANK1
        lda     LCBANK1
        inc16   $06
        inc16   $08
        lda     $08+1
        cmp     L485F+1
        bne     L73A5
        lda     $08
        cmp     L485F
        bne     L73A5
        jsr     pop_pointers
        lda     LE1F1
        asl     a
        tax
        sub16   L485F, LE202,x, L7447
        inc     L7446
L73ED:  lda     L7446
        cmp     LE1F1
        bne     :+
        jmp     L7429

:       lda     L7446
        asl     a
        tax
        sub16   LE202+2,x, LE202,x, L7449
        add16   LE200,x, L7449, LE202,x
        inc     L7446
        jmp     L73ED

L7429:  lda     LE1F1
        sec
        sbc     #$01
        asl     a
        tax
        add16   LE202,x, L7447, L485F
        rts

L7445:  .byte   0
L7446:  .byte   0
L7447:  .word   0
L7449:  .word   0
.endproc

;;; ============================================================

.proc L744B
        lda     cached_window_id
        asl     a
        tax
        copy16  LE6BF,x, $08
        ldy     #$09
        lda     ($06),y
        tay
        jsr     push_pointers
        lda     $06
        clc
        adc     #$09
        sta     $06
        bcc     L746D
        inc     $06+1
L746D:  tya
        tax
        ldy     #$00
L7471:  lda     ($06),y
        sta     ($08),y
        iny
        dex
        bne     L7471
        lda     #$20
        sta     ($08),y
        ldy     #IconEntry::win_type
        lda     ($08),y
        and     #%11011111       ; ???
        sta     ($08),y
        jsr     pop_pointers
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        bne     L74D3
        jsr     push_pointers
        lda     cached_window_id
        jsr     window_path_lookup
        stax    $08
        lda     $06
        clc
        adc     #$09
        sta     $06
        bcc     L74A8
        inc     $06+1
L74A8:  ldy     #$00
        lda     ($06),y
        tay
L74AD:  lda     ($06),y
        sta     ($08),y
        dey
        bpl     L74AD
        ldy     #$00
        lda     ($08),y
        sec
        sbc     #$01
        sta     ($08),y
        ldy     #1
        lda     #'/'
        sta     ($08),y
        ldy     #$00
        lda     ($08),y
        tay
L74C8:  lda     ($08),y
        sta     LE1B0,y
        dey
        bpl     L74C8
        jmp     L7569

L74D3:  tay
        copy    #$00, L7620
        jsr     push_pointers
        tya
        pha
        jsr     window_path_lookup
        stax    $06
        pla
        asl     a
        tax
        copy16  LE6BF,x, $08
        ldy     #$00
        lda     ($06),y
        clc
        adc     ($08),y
        cmp     #$43
        bcc     L750D
        lda     #ERR_INVALID_PATHNAME
        jsr     ShowAlert
        jsr     mark_icons_not_opened_2
        dec     LEC2E
        ldx     saved_stack
        txs
        rts

L750D:  ldy     #0
        lda     ($06),y
        tay
L7512:  lda     ($06),y
        sta     LE1B0,y
        dey
        bpl     L7512
        lda     #'/'
        sta     LE1B0+1
        inc     LE1B0
        ldx     LE1B0
        sta     LE1B0,x
        lda     icon_params2
        jsr     icon_entry_lookup
        stax    $08
        ldx     LE1B0
        ldy     #$09
        lda     ($08),y
        clc
        adc     LE1B0
        sta     LE1B0
        dec     LE1B0
        dec     LE1B0
        ldy     #$0A
L7548:  iny
        inx
        lda     ($08),y
        sta     LE1B0,x
        cpx     LE1B0
        bne     L7548
        lda     cached_window_id
        jsr     window_path_lookup
        stax    $08
        ldy     LE1B0
L7561:  lda     LE1B0,y
        sta     ($08),y
        dey
        bpl     L7561
L7569:  lda     cached_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$14
        lda     cached_window_id
        sec
        sbc     #$01
        asl     a
        asl     a
        asl     a
        asl     a
        pha
        adc     #$05
        sta     ($06),y
        iny
        lda     #$00
        sta     ($06),y
        iny
        pla
        lsr     a
        clc
        adc     #.sizeof(IconEntry)
        sta     ($06),y
        iny
        lda     #$00
        sta     ($06),y
        lda     #$00
        ldy     #$1F
        ldx     #$03
L75A3:  sta     ($06),y
        dey
        dex
        bpl     L75A3
        ldy     #$04
        lda     ($06),y
        and     #$FE
        sta     ($06),y
        iny
        lda     ($06),y
        and     #$FE
        sta     ($06),y
        lda     #$00
        ldy     #$07
        sta     ($06),y
        ldy     #$09
        sta     ($06),y
        jsr     pop_pointers
        lda     icon_params2

        jsr     open_directory

        lda     icon_params2
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        beq     L75FA
        tax
        dex
        txa
        asl     a
        tax
        copy16  window_k_used_table,x, vol_kb_used
        copy16  window_k_free_table,x, vol_kb_free
L75FA:  ldx     cached_window_id
        dex
        txa
        asl     a
        tax
        copy16  vol_kb_used, window_k_used_table,x
        copy16  vol_kb_free, window_k_free_table,x
        lda     cached_window_id
        jsr     create_file_icon_ep1
        rts

L7620:  .byte   $00
.endproc

;;; ============================================================
;;; File Icon Entry Construction

.proc create_file_icon

        icon_x_spacing  = 80
        icon_y_spacing  = 32

window_id:      .byte   0
iconbits:       .addr   0
icon_type:      .byte   0
icon_height:    .word   0
L7625:  .byte   0               ; ???

        max_icon_height = 17

initial_coords:                 ; first icon in window
        DEFINE_POINT  52,16 + max_icon_height, initial_coords

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

        lda     icon_params2
        ldx     LE1F1
        dex
:       cmp     LE1F1+1,x
        beq     :+
        dex
        bpl     :-
        rts

:       txa
        asl     a
        tax
        copy16  LE202,x, $06
        lda     LCBANK2
        lda     LCBANK2
        ldy     #0
        lda     ($06),y
        sta     L7764
        lda     LCBANK1
        lda     LCBANK1
        inc     $06
        lda     $06
        bne     L76A4
        inc     $06+1
L76A4:  lda     cached_window_id
        sta     active_window_id
L76AA:  lda     L7625
        cmp     L7764
        beq     L76BB
        jsr     L7768
        inc     L7625
        jmp     L76AA

L76BB:  bit     flag
        bpl     :+
        jsr     pop_pointers
        rts

:       jsr     compute_icons_bbox
        lda     window_id
        jsr     window_lookup
        stax    $06
        ldy     #$16
        lda     iconbb_rect+MGTK::Rect::y2
        sec
        sbc     ($06),y
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

L7705:  addr_jump L7710, $00AA

L770C:  ldax    #450
L7710:  ldy     #$20
        sta     ($06),y
        txa
        iny
        sta     ($06),y

        cmp16   iconbb_rect+MGTK::Rect::y2, #50
        bmi     L7739
        cmp16   iconbb_rect+MGTK::Rect::y2, #108
        bpl     L7740
        ldax    iconbb_rect+MGTK::Rect::y2
        jmp     L7744

L7739:  addr_jump L7744, $0032

L7740:  ldax    #$6C
L7744:  ldy     #$22
        sta     ($06),y
        txa
        iny
        sta     ($06),y
        lda     L7767
        ldy     #$06
        sta     ($06),y
        ldy     #$08
        sta     ($06),y
        lda     icon_params2
        ldx     window_id
        jsr     animate_window_open
        jsr     pop_pointers
        rts

L7764:  .byte   $00,$00,$00
L7767:  .byte   $14

.endproc

;;; ============================================================
;;; Create icon

.proc L7768
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

        ;; Copy the name (offset by 2 for count and leading space)
        ldy     #FileEntry::storage_type_name_length
        lda     (file_entry),y  ; assumes storage type is 0 ???
        sta     name_tmp
        iny
        ldx     #0
:       lda     (file_entry),y
        sta     name_tmp+2,x
        inx
        iny
        cpx     name_tmp
        bne     :-

        inc     name_tmp        ; length += 2 for leading/trailing spaces
        inc     name_tmp
        lda     #' '            ; leading space
        sta     name_tmp+1
        ldx     name_tmp
        sta     name_tmp,x      ; trailing space

        ;; Check file type
        ldy     #FileEntry::file_type
        lda     (file_entry),y

        cmp     #FT_S16         ; IIgs System?
        beq     is_app

        ;; Map other IIgs-specific types to one icon
        tax
        and     #$F0            ; high nibble
        cmp     #$50            ; $5x Types: Apple IIgs General
        beq     is_iigs
        cmp     #$A0            ; $Ax Types: Apple IIgs BASIC
        beq     is_iigs
        cmp     #$B0            ; $Bx Types: Apple IIgs System
        beq     is_iigs
        cmp     #$C0            ; $Cx Types: Graphics
        beq     is_iigs
        txa

        cmp     #FT_BAD         ; T$01 is overloaded below for "apps", so
        bne     :+              ; treat as generic
        lda     #FT_TYPELESS

:       cmp     #FT_SYSTEM      ; Other system?
        bne     got_type        ; nope

        ;; Distinguish *.SYSTEM files as apps (use $01) from other
        ;; type=SYS files (use $FF).
        ldy     #FileEntry::storage_type_name_length
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
        lda     #FT_BAD         ; overloaded meaning in icon tables
        bne     got_type        ; always

is_iigs:
        lda     #FT_SRC
        bne     got_type

str_sys_suffix:
        PASCAL_STRING ".SYSTEM"

not_app:
        lda     #$FF

got_type:
        tay

        ;; Figure out icon type
        lda     LCBANK1
        lda     LCBANK1
        tya

        jsr     find_icon_details_for_file_type
        ldy     #IconEntry::len
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
        adc     #icon_x_spacing
        sta     row_coords::xcoord
        bcc     L7870
        inc     row_coords::xcoord+1

L7870:  lda     cached_window_id
        ora     icon_type
        ldy     #IconEntry::win_type
        sta     (icon_entry),y
        ldy     #IconEntry::iconbits
        copy16in iconbits, (icon_entry),y
        ldx     cached_window_icon_count
        dex
        lda     cached_window_icon_list,x
        jsr     icon_screen_to_window
        add16   file_entry, #icon_y_spacing, file_entry
        rts

        .byte   0
        .byte   0
.endproc

;;; ============================================================
;;; Special case: $01 is used for App-like SYS files.

.proc find_icon_details_for_file_type
        ptr := $6

        sta     file_type
        jsr     push_pointers

        ;; Find index of file type
        copy16  #type_table, ptr
        ldy     #num_file_types-1
:       lda     (ptr),y
        cmp     file_type
        beq     found
        dey
        bpl     :-
        ldy     #0              ; default is first entry (FT_TYPELESS)

found:
        ;; Look up icon type
        copy16  #icon_type_table, ptr
        lda     (ptr),y
        sta     icon_type

        tya
        asl     a
        tay

        ;; Look up icon definition
        copy16  #type_icons_table, ptr
        copy16in (ptr),y, iconbits

        ;; Icon height will be needed too
        copy16  iconbits, ptr
        ldy     #IconDefinition::maprect + MGTK::Rect::y2
        copy16in (ptr),y, icon_height

        jsr     pop_pointers
        rts

file_type:
        .byte   0
.endproc

.endproc
        create_file_icon_ep2 := create_file_icon::ep1::ep2
        create_file_icon_ep1 := create_file_icon::ep1

;;; ============================================================
;;; Draw header (items/k in disk/k available/lines)

.proc draw_window_header

        ;; Compute header coords

        ;; x coords
        lda     grafport2::cliprect::x1
        sta     header_line_left::xcoord
        clc
        adc     #5
        sta     items_label_pos::xcoord
        lda     grafport2::cliprect::x1+1
        sta     header_line_left::xcoord+1
        adc     #0
        sta     items_label_pos::xcoord+1

        ;; y coords
        lda     grafport2::cliprect::y1
        clc
        adc     #12
        sta     header_line_left::ycoord
        sta     header_line_right::ycoord
        lda     grafport2::cliprect::y1+1
        adc     #0
        sta     header_line_left::ycoord+1
        sta     header_line_right::ycoord+1

        ;; Draw top line
        MGTK_RELAY_CALL MGTK::MoveTo, header_line_left
        copy16  grafport2::cliprect::x2, header_line_right::xcoord
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
        add16 grafport2::cliprect::y1, #10, items_label_pos::ycoord

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
        sub16   grafport2::cliprect::x2, grafport2::cliprect::x1, xcoord

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
        add16   pos_k_in_disk::xcoord, grafport2::cliprect::x1, pos_k_in_disk::xcoord
        add16   pos_k_available::xcoord, grafport2::cliprect::x1, pos_k_available::xcoord

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

cur_icon_pos:
        DEFINE_POINT 0,0,cur_icon_pos

        entry_ptr := $06

        kIntMax = $7FFF

        kPadTop    = 15
        kPadLeft   = 50
        kPadBottom = 32
        kPadRight  = 50


start:  ldx     #3
        lda     #0
:       sta     iconbb_rect::x2,x
        dex
        bpl     :-

        sta     icon_num
        lda     #<kIntMax
        sta     iconbb_rect::x1
        sta     iconbb_rect+MGTK::Rect::y1
        lda     #>kIntMax
        sta     iconbb_rect::x1+1
        sta     iconbb_rect+MGTK::Rect::y1+1

        ldx     cached_window_id
        dex
        lda     win_view_by_table,x
        bpl     L7BCB
        lda     cached_window_icon_count
        bne     L7BA1
L7B96:  ldax    #$0300
L7B9A:  sta     iconbb_rect::x1,x
        dex
        bpl     L7B9A
        rts

        ;; iconbb_rect::x2 = 360
        ;; iconbb_rect::y2 = (A + 2) * 8
L7BA1:  clc
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
        jmp     L7B96

L7BCB:  lda     cached_window_icon_count
        cmp     #1
        bne     check_icon

        ;; First icon - copy coords
        lda     cached_window_icon_list
        jsr     icon_entry_lookup
        stax    entry_ptr

        ldy     #IconEntry::iconx+.sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     (entry_ptr),y
        sta     iconbb_rect::x1,x
        sta     iconbb_rect::x2,x
        dey
        dex
        bpl     :-

        jmp     finish

check_icon:
        lda     icon_num
        cmp     cached_window_icon_count
        bne     more

finish: lda     iconbb_rect::x2
        clc
        adc     #kPadRight
        sta     iconbb_rect::x2
        bcc     :+
        inc     iconbb_rect::x2+1
:       lda     iconbb_rect::y2
        clc
        adc     #kPadBottom
        sta     iconbb_rect::y2
        bcc     :+
        inc     iconbb_rect::y2+1
:       sub16   iconbb_rect::x1, #kPadLeft, iconbb_rect::x1
        sub16   iconbb_rect::y1, #kPadTop, iconbb_rect::y1
        rts

more:   tax
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup
        stax    entry_ptr
        ldy     #IconEntry::win_type
        lda     (entry_ptr),y
        and     #icon_entry_winid_mask
        cmp     hi           ; BUG: from old code that iterated all icons???
        bne     :+
        inc     icon_num
        jmp     check_icon

:       ldy     #IconEntry::iconx+.sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     (entry_ptr),y
        sta     cur_icon_pos::xcoord,x
        dey
        dex
        bpl     :-

        ;; --------------------------------------------------
        ;; Compare X coords

        bit     iconbb_rect::x1+1         ; negative?
        bmi     pt0x_neg

        bit     cur_icon_pos::xcoord+1
        bmi     adjust_pt0_x

        ;; X: cur and pt0 are positive
        cmp16   cur_icon_pos::xcoord, iconbb_rect::x1
        bmi     adjust_pt0_x
        cmp16   cur_icon_pos::xcoord, iconbb_rect::x2
        bpl     adjust_pt1_x
        jmp     compare_y

pt0x_neg:
        bit     cur_icon_pos::xcoord+1
        bmi     bothx_neg

        ;; X: cur positive, pt0 negative
        bit     iconbb_rect::x2+1
        bmi     compare_y
        cmp16   cur_icon_pos::xcoord, iconbb_rect::x2
        bmi     compare_y
        jmp     adjust_pt1_x

        ;; X: cur and pt0 are negative
bothx_neg:
        cmp16   cur_icon_pos::xcoord, iconbb_rect::x1
        bmi     adjust_pt0_x
        cmp16   cur_icon_pos::xcoord, iconbb_rect::x2
        bmi     compare_y

adjust_pt1_x:
        copy16  cur_icon_pos::xcoord, iconbb_rect::x2
        jmp     compare_y

adjust_pt0_x:
        copy16  cur_icon_pos::xcoord, iconbb_rect::x1

        ;; --------------------------------------------------
        ;; Compare Y coords

compare_y:
        bit     iconbb_rect::y1+1
        bmi     pt0y_neg
        bit     cur_icon_pos::ycoord+1
        bmi     adjust_pt0_y

        ;; Y: cur and pt0 are positive
        cmp16   cur_icon_pos::ycoord, iconbb_rect::y1
        bmi     adjust_pt0_y
        cmp16   cur_icon_pos::ycoord, iconbb_rect::y2
        bpl     adjust_pt1_y
        jmp     next

pt0y_neg:
        bit     cur_icon_pos::ycoord+1
        bmi     bothy_neg

        ;; Y: cur positive, pt0 negative
        bit     iconbb_rect::y2+1
        bmi     next
        cmp16   cur_icon_pos::ycoord, iconbb_rect::y2
        bmi     next
        jmp     adjust_pt1_y

        ;; Y: cur and pt0 are negative
bothy_neg:
        cmp16   cur_icon_pos::ycoord, iconbb_rect::y1
        bmi     adjust_pt0_y
        cmp16   cur_icon_pos::ycoord, iconbb_rect::y2
        bmi     next

adjust_pt1_y:
        copy16  cur_icon_pos::ycoord, iconbb_rect::y2
        jmp     next

adjust_pt0_y:
        copy16  cur_icon_pos::ycoord, iconbb_rect::y1

next:   inc     icon_num
        jmp     check_icon

icon_num:
        .byte   0

hi:     .byte   0
.endproc
        compute_icons_bbox := compute_icons_bbox_impl::start

;;; ============================================================

.proc L7D5D
        jsr     window_lookup
        stax    $06

        ldy     #35
        ldx     #7
:       lda     ($06),y
        sta     L7D94,x
        dey
        dex
        bpl     :-

        lda     L7D98
        sec
        sbc     L7D94
        pha
        lda     L7D98+1
        sbc     L7D94+1
        pha

        lda     L7D9A
        sec
        sbc     L7D96
        pha
        lda     L7D9A+1
        sbc     L7D96+1         ; weird - this is discarded???
        pla
        tay
        pla
        tax
        pla
        rts

L7D94:  .word   0
L7D96:  .word   0
L7D98:  .word   0
L7D9A:  .word   0

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

start:  ldx     cached_window_id
        dex
        lda     window_to_dir_icon_table,x

        ldx     #0
:       cmp     LE1F1+1,x
        beq     found
        inx
        cpx     LE1F1
        bne     :-
        rts

found:  txa
        asl     a
        tax

        lda     LE202,x         ; Ptr points at start of record
        sta     ptr
        sta     list_start_ptr
        lda     LE202+1,x
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
        cmp     #view_by_name
        beq     :+
        jmp     check_date

:
        ;; By Name

        ;; Sorted in increasing lexicographical order
.scope
        name := $807
        name_size = $F
        name_len  := $804

        lda     LCBANK2
        lda     LCBANK2

        ;; Set up highest value ("ZZZZZZZZZZZZZZZ")
        lda     #'Z'
        ldx     #name_size
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

        ldx     #name_size
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
        cmp     #view_by_date
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
        sta     date
        sta     date+1
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
        ldy     #FileRecord::modification_date
        copy16in (ptr),y, date_a
        copy16  date, date_b
        jsr     compare_dates
        beq     inext
        bcc     inext

        ;; if greater than
place:  ldy     #FileRecord::modification_date+1
        lda     (ptr),y
        sta     date+1
        dey
        lda     (ptr),y
        sta     date

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
        sta     date
        sta     date+1

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
        cmp     #view_by_size
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
        cmp     #view_by_type
        beq     :+
        rts

:
        ;; By Type

        ;; Types are ordered by type_table
.scope
        type_table_copy := $807

        ;; Copy type_table prefixed by length to $807
        copy16  #type_table, $08
        copy    #num_file_types, type_table_copy
        ldy     #num_file_types-1
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

date_a: .word   0
date_b: .word   0

.proc compare_dates
        ptr := $0A

        copy16  #parsed_a, ptr
        ldax    date_a
        jsr     parse_date

        copy16  #parsed_b, ptr
        ldax    date_b
        jsr     parse_date

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
year_a: .word   0
month_a:.byte   0
day_a:  .byte   0

parsed_b:
year_b: .word   0
month_b:.byte   0
day_b:  .byte   0

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

.proc L813F_impl

L813C:  .byte   0
        .byte   0
L813E:  .byte   8

start:  ldy     #$00
        tax
        dex
        txa
        sty     L813C
        asl     a
        rol     L813C
        asl     a
        rol     L813C
        asl     a
        rol     L813C
        asl     a
        rol     L813C
        asl     a
        rol     L813C
        clc
        adc     LE71D
        sta     $06
        lda     LE71D+1
        adc     L813C
        sta     $06+1
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$1F
L8171:  lda     ($06),y
        sta     LEC43,y
        dey
        bpl     L8171
        lda     LCBANK1
        lda     LCBANK1
        ldx     #$31
        lda     #' '
L8183:  sta     text_buffer2::data-1,x
        dex
        bpl     L8183
        copy    #0, text_buffer2::length
        lda     pos_col_type::ycoord
        clc
        adc     L813E
        sta     pos_col_type::ycoord
        bcc     L819D
        inc     pos_col_type::ycoord+1
L819D:  lda     pos_col_size::ycoord
        clc
        adc     L813E
        sta     pos_col_size::ycoord
        bcc     L81AC
        inc     pos_col_size::ycoord+1
L81AC:  lda     pos_col_date::ycoord
        clc
        adc     L813E
        sta     pos_col_date::ycoord
        bcc     L81BB
        inc     pos_col_date::ycoord+1
L81BB:  cmp16   pos_col_name::ycoord, grafport2::cliprect::y2
        bmi     L81D9
        lda     pos_col_name::ycoord
        clc
        adc     L813E
        sta     pos_col_name::ycoord
        bcc     L81D8
        inc     pos_col_name::ycoord+1
L81D8:  rts

L81D9:  lda     pos_col_name::ycoord
        clc
        adc     L813E
        sta     pos_col_name::ycoord
        bcc     L81E8
        inc     pos_col_name::ycoord+1
L81E8:  cmp16   pos_col_name::ycoord, grafport2::cliprect::y1
        bpl     L81F7
        rts

L81F7:  jsr     prepare_col_name
        addr_call SetPosDrawText, pos_col_name
        jsr     prepare_col_type
        addr_call SetPosDrawText, pos_col_type
        jsr     prepare_col_size
        addr_call SetPosDrawText, pos_col_size
        jsr     compose_date_string
        addr_jump SetPosDrawText, pos_col_date
.endproc
        L813F := L813F_impl::start

;;; ============================================================

.proc prepare_col_name
        lda     LEC43
        and     #$0F
        sta     text_buffer2::length
        tax
loop:   lda     LEC43,x
        sta     text_buffer2::data,x
        dex
        bne     loop
        lda     #' '
        sta     text_buffer2::data
        inc     text_buffer2::length
        rts
.endproc

.proc prepare_col_type
        lda     LEC53
        jsr     compose_file_type_string

        ;; BUG: should be 4 not 5???
        COPY_BYTES 5, str_file_type, text_buffer2::data-1

        rts
.endproc

.proc prepare_col_size
        ldax    LEC54
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
        ldx     #21
        lda     #' '
:       sta     text_buffer2::data-1,x
        dex
        bpl     :-
        lda     #1
        sta     text_buffer2::length
        copy16  #text_buffer2::length, $8
        lda     date            ; any bits set?
        ora     date+1
        bne     append_date_strings
        sta     month           ; 0 is "no date" string
        jmp     append_month_string

append_date_strings:
        copy16  #parsed_date, $0A
        ldax    date
        jsr     parse_date

        jsr     append_month_string
        addr_call concatenate_date_part, str_space
        jsr     append_day_string
        addr_call concatenate_date_part, str_space
        jmp     append_year_string

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

parsed_date:
year:   .word   0
month:  .byte   0
day:    .byte   0

month_table:
        .addr   str_no_date
        .addr   str_jan,str_feb,str_mar,str_apr,str_may,str_jun
        .addr   str_jul,str_aug,str_sep,str_oct,str_nov,str_dec

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
;;; Parse date
;;; Input: A,X = Date lo/hi
;;; $0A points at {year:.word, month:.byte, day:.byte} to be filled

.proc parse_date
        ptr := $0A

        ;; TODO: Handle ProDOS 2.5 extended dates
        ;; (additional year bits packed into time bytes)

        stax    date

        ;; Null date? Leave as all zeros.
        ora     date+1          ; null date?
        bne     year
        ldy     #3
:       sta     (ptr),y
        dey
        bpl     :-
        rts

        ;; Year
year:   ldy     #1
        copy    #0, (ptr),y

        lda     date+1
        and     #%11111110
        lsr     a
        ldy     #0
        sta     (ptr),y
        ;; Per ProDOS Tech Note #28, 40-99 is 1940-1999, 0-39 is 2000-2039
        ;; http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.28.html
        cmp     #40             ; 40-99 (and also 100-127, though non-conforming)
        bcs     y1900

y2000:  add16in   (ptr),y, #2000, (ptr),y
        jmp     month

y1900:  add16in   (ptr),y, #1900, (ptr),y

        ;; Month
month:  lda     date+1
        ror     a
        lda     date
        ror     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ldy     #2
        sta     (ptr),y

        ;; Day
day:    lda     date
        and     #%00011111
        ldy     #3
        sta     (ptr),y
        rts

date:   .word   0

.endproc

;;; ============================================================

.proc L84D1
        jsr     push_pointers
        bit     active_window_view_by
        bmi     L84DC
        jsr     cached_icons_window_to_screen
L84DC:  sub16   grafport2::cliprect::x2, grafport2::cliprect::x1, L85F8
        sub16   grafport2::cliprect::y2, grafport2::cliprect::y1, L85FA
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     L850C
        asl     a
        bne     L850E
L850C:  lda     #$00
L850E:  sta     L85F1
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        lda     #$06
        clc
        adc     L85F1
        tay
        lda     ($06),y
        pha
        jsr     compute_icons_bbox
        ldx     L85F1

        sub16   iconbb_rect::x2,x, iconbb_rect::x1,x, L85F2

        ldx     L85F1

        sub16   L85F2, L85F8,x, L85F2

        bpl     L8562
        lda     L85F8,x
        sta     L85F2
        lda     L85F9,x
        sta     L85F3
L8562:  lsr16   L85F2
        lsr16   L85F2
        lda     L85F2
        tay
        pla
        tax
        lda     event_params+1
        jsr     L62BC
        ldx     #$00
        stx     L85F2
        asl     a
        rol     L85F2
        asl     a
        rol     L85F2

        ldx     L85F1
        clc
        adc     iconbb_rect::x1,x
        sta     grafport2::cliprect::x1,x
        lda     L85F2
        adc     iconbb_rect::x1+1,x
        sta     grafport2::cliprect::x1+1,x

        lda     active_window_id
        jsr     L7D5D
        stax    L85F4
        sty     L85F6
        lda     L85F1
        beq     L85C3
        add16_8 grafport2::cliprect::y1, L85F6, grafport2::cliprect::y2
        jmp     L85D6

L85C3:  add16 grafport2::cliprect::x1, L85F4, grafport2::cliprect::x2
L85D6:  lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$23
        ldx     #$07
L85E4:  lda     grafport2::cliprect::x1,x
        sta     ($06),y
        dey
        dex
        bpl     L85E4
        jsr     pop_pointers
        rts

L85F1:  .byte   0
L85F2:  .byte   0
L85F3:  .byte   0
L85F4:  .word   0
L85F6:  .byte   0
        .byte   0
L85F8:  .byte   0
L85F9:  .byte   0
L85FA:  .word   0
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
        ldy     #num_file_types-1
:       lda     ($06),y
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
:       lda     ($06),y
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
        cmp     #$0A
        bcs     L8764
        clc
        adc     #'0'            ; 0-9
        bne     L8767
L8764:  clc
        adc     #'A' - $A       ; A-F
L8767:  sta     str_file_type+3
        lda     file_type
        and     #$0F
        cmp     #$0A
        bcs     L8778
        clc
        adc     #'0'            ; 0-9
        bne     L877B
L8778:  clc
        adc     #'A' - $A       ; A-F
L877B:  sta     path_buf4
        rts

file_type:
        .byte   0

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
;;; Pops two words from stack to $6/$8

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
;;; Convert icon's coordinates from screen to window (direction???)
;;; (icon index in A, active window)

.proc icon_screen_to_window
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
;;; Convert icon's coordinates from window to screen (direction???)
;;; (icon index in A, active window)

.proc icon_window_to_screen
        tay
        jsr     push_pointers
        tya
        jsr     icon_entry_lookup
        stax    $06
        ;; fall through
.endproc

;;; Convert icon's coordinates from window to screen (direction???)
;;; (icon entry pointer in $6, active window)

.proc icon_ptr_window_to_screen
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

.proc zero_grafport5_coords
        lda     #0
        tax
:       sta     grafport5::cliprect::x1,x
        sta     grafport5::viewloc::xcoord,x
        sta     grafport5::cliprect::x2,x
        inx
        cpx     #4
        bne     :-
        MGTK_RELAY_CALL MGTK::SetPort, grafport5
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

        cmp     #$3E            ; RAM.SYSTEM
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
ram:    return  #device_type_ramdisk

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
        return  #device_type_removable

        ;; Try AppleTalk
unk:    MLI_RELAY_CALL READ_BLOCK, block_params
        beq     hd
        cmp     #ERR_NETWORK_ERROR
        bne     hd
        return  #device_type_fileshare

hd:     return  #device_type_profile

        DEFINE_READ_BLOCK_PARAMS block_params, $800, 0
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
        and     #%00001111      ; mask off name length
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

        max_icon_width = 53

.proc create_volume_icon
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

        ;; Copy name, with leading/trailing space
        lda     cvi_data_buffer
        and     #NAME_LENGTH_MASK
        sta     cvi_data_buffer

        addr_call adjust_volname_case, cvi_data_buffer

        ldy     #IconEntry::name
        copy    #' ', (icon_ptr),y ; leading space
        iny

        ldx     #0
:       lda     cvi_data_buffer+1,x
        sta     (icon_ptr),y
        iny
        inx
        cpx     cvi_data_buffer
        bne     :-

        copy    #' ', (icon_ptr),y ; trailing space

        inx                     ; for leading/trailing space
        inx
        txa
        ldy     #IconEntry::len
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
        sub16in #max_icon_width, (icon_defn_ptr),y, offset
        lsr16   offset          ; offset = (max_width - icon_width) / 2
        ldy     #IconEntry::iconx
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


;;; Icons are placed places in order as specified by caller
;;; in X. (Reverse DEVLST order, so most important is first.)
;;;
;;;  +-------------------------+
;;;  |                     1   |
;;;  |                     2   |
;;;  |                     3   |
;;;  |                     4   |
;;;  |        13  12  11   5   |
;;;  | 10  9   8   7   6 Trash |
;;;  +-------------------------+

        trash_iconx = 506
        trash_icony = 160

desktop_icon_coords_table:
        DEFINE_POINT 490,16     ; 1
        DEFINE_POINT 490,45     ; 2
        DEFINE_POINT 490,75     ; 3
        DEFINE_POINT 490,103    ; 4
        DEFINE_POINT 490,131    ; 5
        DEFINE_POINT 400,160    ; 6
        DEFINE_POINT 310,160    ; 7
        DEFINE_POINT 220,160    ; 8
        DEFINE_POINT 130,160    ; 9
        DEFINE_POINT 40,160     ; 10
        DEFINE_POINT 400,131    ; 11
        DEFINE_POINT 310,131    ; 12
        DEFINE_POINT 220,131    ; 13
        ;; Maximum of 13 devices:
        ;; 7 slots * 2 drives = 14 (size of DEVLST)
        ;; ... but RAM in Slot 3 Drive 2 is disconnected.
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

.proc mark_icons_not_opened
        ptr := $6

L8B19:  jsr     push_pointers
        jmp     start

L8B1F:  lda     icon_params2
        bne     :+
        rts
:       jsr     push_pointers
        lda     icon_params2
        jsr     L7345           ; ???
        ;; fall through

        ;; Find open window for the icon
start:  lda     icon_params2
        ldx     #8 - 1
:       cmp     window_to_dir_icon_table,x
        beq     :+
        dex
        bpl     :-
        jmp     skip

        ;; If found, remove from the table
:       lda     #0
        sta     window_to_dir_icon_table,x

        ;; Update the icon and redraw
skip:   lda     icon_params2
        jsr     icon_entry_lookup
        stax    ptr
        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #AS_BYTE(~icon_entry_open_mask) ; clear open_flag
        sta     ($06),y
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
        lda     #$14
        clc
        adc     #$23
        tay

        ldx     #.sizeof(MGTK::GrafPort)-1
:       lda     (ptr),y
        sta     grafport2,x
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
:       lda     grafport2,x
        sta     rect_table,y
        dey
        dex
        bpl     :-

        sub16   grafport2::cliprect::x2, grafport2::cliprect::x1, L8D54
        sub16   grafport2::cliprect::y2, grafport2::cliprect::y1, L8D56
        add16   $0858, L8D54, $085C
        add16   $085A, L8D56, $085E
        lda     #$00
        sta     L8D4E
        sta     L8D4F
        sta     L8D4D
        sub16   $0858, rect_table, L8D50
        sub16   $085A, $0802, L8D52
        bit     L8D51
        bpl     L8C6A
        copy    #$80, L8D4E
        lda     L8D50
        eor     #$FF
        sta     L8D50
        lda     L8D51
        eor     #$FF
        sta     L8D51
        inc16   L8D50
L8C6A:  bit     L8D53
        bpl     L8C8C
        copy    #$80, L8D4F
        lda     L8D52
        eor     #$FF
        sta     L8D52
        lda     L8D53
        eor     #$FF
        sta     L8D53
        inc16   L8D52

L8C8C:  lsr16   L8D50
        lsr16   L8D52
        lsr16   L8D54
        lsr16   L8D56
        lda     #$0A
        sec
        sbc     L8D4D
        asl     a
        asl     a
        asl     a
        tax
        bit     L8D4E
        bpl     :+
        sub16   rect_table, L8D50, rect_table,x
        jmp     L8CDC

:       add16   rect_table, L8D50, rect_table,x

L8CDC:  bit     L8D4F
        bpl     L8CF7
        sub16   $0802, L8D52, $0802,x
        jmp     L8D0A

L8CF7:  add16   rect_table+2, L8D52, rect_table+2,x

L8D0A:  add16   rect_table,x, L8D54, rect_table+4,x ; right
        add16   rect_table+2,x, L8D56, rect_table+6,x ; bottom

        inc     L8D4D
        lda     L8D4D
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

L8D4D:  .byte   0
L8D4E:  .byte   0
L8D4F:  .byte   0
L8D50:  .byte   0
L8D51:  .byte   0
L8D52:  .byte   0
L8D53:  .byte   0
L8D54:  .word   0
L8D56:  .word   0
.endproc
        animate_window_close := animate_window::close
        animate_window_open := animate_window::open

;;; ============================================================

.proc animate_window_open_impl

        rect_table := $800

        lda     #0
        sta     step
        jsr     reset_grafport3
        MGTK_RELAY_CALL MGTK::SetPattern, desktop_aux::checkerboard_pattern
        jsr     set_penmode_xor

loop:   lda     step
        cmp     #12
        bcs     erase

        ;; Compute offset into rect table
        asl     a
        asl     a
        asl     a
        clc
        adc     #7
        tax

        ;; Copy rect to draw
        ldy     #7
:       lda     rect_table,x
        sta     tmp_rect,y
        dex
        dey
        bpl     :-

        jsr     draw_anim_window_rect

        ;; Compute offset into rect table
erase:  lda     step
        sec
        sbc     #2
        bmi     next
        asl     a               ; * 8 (size of Rect)
        asl     a
        asl     a
        clc
        adc     #$07
        tax

        ;; Copy rect to erase
        ldy     #.sizeof(MGTK::Rect)-1
:       lda     rect_table,x
        sta     tmp_rect,y
        dex
        dey
        bpl     :-

        jsr     draw_anim_window_rect

next:   inc     step
        lda     step
        cmp     #$0E
        bne     loop
        rts

step:   .byte   0
.endproc

;;; ============================================================

.proc animate_window_close_impl

        rect_table := $800

        lda     #11
        sta     step
        jsr     reset_grafport3
        MGTK_RELAY_CALL MGTK::SetPattern, desktop_aux::checkerboard_pattern
        jsr     set_penmode_xor

loop:   lda     step
        bmi     erase
        beq     erase

        ;; Compute offset into rect table
        asl     a               ; * 8 (size of Rect)
        asl     a
        asl     a
        clc
        adc     #$07
        tax

        ;; Copy rect to draw
        ldy     #.sizeof(MGTK::Rect)-1
:       lda     rect_table,x
        sta     tmp_rect,y
        dex
        dey
        bpl     :-

        jsr     draw_anim_window_rect

        ;; Compute offset into rect table
erase:  lda     step
        clc
        adc     #2
        cmp     #13
        bcs     next
        asl     a
        asl     a
        asl     a
        clc
        adc     #$07
        tax

        ;; Copy rect to erase
        ldy     #.sizeof(MGTK::Rect)-1
:       lda     rect_table,x
        sta     tmp_rect,y
        dex
        dey
        bpl     :-

        jsr     draw_anim_window_rect

next:   dec     step
        lda     step
        cmp     #AS_BYTE(-3)
        bne     loop
        rts

step:   .byte   0
.endproc

;;; ============================================================

.proc draw_anim_window_rect
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

pos_table:
        .dword  $00012FE0,$000160E0,$000174E0,$000184E0,$0001A4E0
        .dword  $0001ACE0,$0001B4E0,$0000B780,$0000F780
len_table:
        .word   $0200,$1400,$1000,$2000,$0800,$0800,$0800,$2800,$1000
addr_table:
        .addr   $0800,$0800,$9000,$5000,$7000,$7000,$7000,$5000,$9000

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

        lda     #warning_msg_insert_system_disk
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
        beq     done

        MLI_RELAY_CALL GET_TIME, 0
        lda     TIMEHI          ; hours
        and     #%00011111

        ;; AM/PM
        ldx     #'A'
        cmp     #12
        bcc     :+
        ldx     #'P'
        sec
        sbc     #12
:       stx     str_clock + 7

        ;; Hours
        cmp     #0              ; 0 -> 12
        bne     :+
        lda     #12
:       ldx     #' '            ; Leading space or 1?
        cmp     #10
        bcc     :+
        ldx     #'1'
        sec
        sbc     #10
:       stx     str_clock + 1   ; Tens place
        ora     #'0'
        sta     str_clock + 2   ; Ones place

        ;; Minutes
        lda     TIMELO
        and     #%00111111
        ldx     #0              ; Subtract off tens (in X)
:       cmp     #10
        bcc     :+
        inx
        sec
        sbc     #10
        bpl     :-
:       ora     #'0'
        sta     str_clock + 5   ; Ones place
        txa
        ora     #'0'
        sta     str_clock + 4   ; Tens place

        ;; Assumes call from main loop, where grafport3 is initialized.
        MGTK_RELAY_CALL MGTK::MoveTo, pos_clock
        addr_call draw_text1, str_clock
done:   rts
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
        jsr     ID_BYTE_FE1F
        lda     LCBANK1
        lda     LCBANK1
        rts
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
        jsr     redraw_desktop_and_windows
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
        jsr     L99BC
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
        lda     drag_drop_param
        cmp     #1              ; Trash (BUG: Should use trash_icon_num)
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
        jsr     prep_grafport3
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
        lda     drag_drop_param
        bpl     check_icon_drop_type

        ;; Drop is on a window
        and     #%01111111      ; get window id
        asl     a
        tax
        copy16  window_path_addr_table,x, $08
        copy16  #empty_string, $06
        jsr     join_paths
        jmp     L9076

        ;; Drop is on an icon.
        ;; Is drop on a volume or a file?
        ;; (lower 4 bits are containing window id)
check_icon_drop_type:
        jsr     get_icon_entry_win_type
        and     #icon_entry_winid_mask
        beq     drop_on_volume_icon ; 0 = desktop (so, volume icon)

        ;; Drop is on a file icon.
        asl     a
        tax
        copy16  window_path_addr_table,x, $08
        lda     drag_drop_param
        jsr     icon_entry_name_lookup
        jsr     join_paths
        jmp     L9076

        ;; Drop is on a volume icon.
        ;;
drop_on_volume_icon:
        lda     drag_drop_param

        ;; Prefix name with '/'
        jsr     icon_entry_name_lookup
        ldy     #1
        lda     #'/'
        sta     ($06),y

        ;; Copy to path_buf3
        dey
        lda     ($06),y
        sta     @compare
        sta     path_buf3,y
:       iny
        lda     ($06),y
        sta     path_buf3,y
        @compare := *+1
        cpy     #0              ; self-modified
        bne     :-

        ;; Restore ' ' to name prefix
        ldy     #1
        lda     #' '
        sta     ($06),y

L9076:  ldy     #$FF
:       iny
        copy    path_buf3,y, path_buf4,y
        cpy     path_buf3
        bne     :-
        lda     path_buf4
        beq     begin_operation
        dec     path_buf4
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
        cmp     #1              ; icon #1 is always Trash (BUG: should use trash_icon_num)
        beq     next_icon
        jsr     icon_entry_name_lookup
        jsr     join_paths
        ;; Shrink name to remove trailing ' '
        lda     path_buf3
        beq     :+
        dec     path_buf3
:
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
        add16   icon_entry_address_table,y, #IconEntry::len, $06
        rts
.endproc

;;; ============================================================

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
        iny
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

.proc prep_grafport3
        yax_call JT_MGTK_RELAY, MGTK::InitPort, grafport3
        yax_call JT_MGTK_RELAY, MGTK::SetPort, grafport3
        rts
.endproc

.proc redraw_desktop_and_windows
        jsr     JT_REDRAW_ALL
        yax_call JT_DESKTOP_RELAY, DT_REDRAW_ICONS, 0
        rts
.endproc

.proc get_window_path_ptr
        ptr := $08

        copy16  #nullptr, ptr   ; ptr to empty string???
        lda     selected_window_index
        beq     done

        asl     a
        tax
        copy16  window_path_addr_table,x, ptr
        lda     #0
done:   rts

nullptr:
        .addr   0
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

.proc control_params
param_count:    .byte   3
unit_number:    .byte   0
control_list:   .addr   list
control_code:   .byte   4       ; Eject disk
.endproc
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

.proc get_info_dialog_params
L92E3:  .byte   0
L92E4:  .word   0
L92E6:  .byte   0
.endproc

;;; ============================================================
;;; Look up device driver address.
;;; Input: A = unit number
;;; Output: $0A/$0B ptr to driver; Z set if $CnXX

.proc device_driver_address
        slot_addr := $0A

        and     #%11110000      ; mask off drive/slot
        clc
        ror                     ; 0DSSS000
        ror                     ; 00DSSS00
        ror                     ; 000DSSS0
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

:       copy    #0, get_info_dialog_params::L92E6
        jsr     prep_grafport3
loop:   ldx     get_info_dialog_params::L92E6
        cpx     selected_icon_count
        bne     :+
        jmp     done

:       lda     selected_window_index
        beq     vol_icon

        ;; File icon
        asl     a
        tax
        copy16  window_path_addr_table,x, $08
        ldx     get_info_dialog_params::L92E6
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        jsr     join_paths

        ldy     #0              ; Copy name to path_buf
:       lda     path_buf3,y
        sta     path_buf,y
        iny
        cpy     path_buf
        bne     :-
        dec     path_buf
        jmp     common

        ;; Volume icon
vol_icon:
        ldx     get_info_dialog_params::L92E6
        lda     selected_icon_list,x
        cmp     #1              ; trash icon?
        bne     :+
        jmp     next
:       jsr     icon_entry_name_lookup
        ldy     #0
:       lda     (ptr),y
        sta     path_buf,y
        iny
        cpy     path_buf
        bne     :-
        dec     path_buf
        lda     #'/'
        sta     path_buf+1

        ;; Try to get file info
common: MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params5
        beq     :+
        jsr     show_error_alert
        beq     common
:
        lda     selected_window_index
        beq     vol_icon2

        ;; File icon
        copy    #$80, get_info_dialog_params::L92E3
        lda     get_info_dialog_params::L92E6
        clc
        adc     #1
        cmp     selected_icon_count
        beq     :+
        inc     get_info_dialog_params::L92E3
        inc     get_info_dialog_params::L92E3
:       jsr     run_get_info_dialog_proc
        jmp     common2

vol_icon2:
        copy    #$81, get_info_dialog_params::L92E3
        lda     get_info_dialog_params::L92E6
        clc
        adc     #1
        cmp     selected_icon_count
        beq     :+
        inc     get_info_dialog_params::L92E3
        inc     get_info_dialog_params::L92E3
:       jsr     run_get_info_dialog_proc
        copy    #0, write_protected_flag
        ldx     get_info_dialog_params::L92E6
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
        ldx     get_info_dialog_params::L92E6
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        copy    #1, get_info_dialog_params::L92E3
        copy16  ptr, get_info_dialog_params::L92E4
        jsr     run_get_info_dialog_proc
        copy    #2, get_info_dialog_params::L92E3
        lda     selected_window_index
        bne     is_file
        bit     write_protected_flag
        bmi     is_protected
        copy    #0, get_info_dialog_params::L92E4
        beq     L9428           ; always

is_protected:
        copy    #1, get_info_dialog_params::L92E4
        bne     L9428           ; always

is_file:
        lda     get_file_info_params5::access
        and     #ACCESS_DEFAULT
        cmp     #ACCESS_DEFAULT
        beq     L9423
        copy    #1, get_info_dialog_params::L92E4
        bne     L9428           ; always

L9423:  copy    #0, get_info_dialog_params::L92E4
L9428:  jsr     run_get_info_dialog_proc
        jmp     L942F

write_protected_flag:
        .byte   0

L942F:  copy    #3, get_info_dialog_params::L92E3

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

        copy16  #path_buf4, get_info_dialog_params::L92E4
        jsr     run_get_info_dialog_proc

        copy    #4, get_info_dialog_params::L92E3
        copy16  get_file_info_params5::create_date, date
        jsr     JT_DATE_STRING
        copy16  #text_buffer2::length, get_info_dialog_params::L92E4
        jsr     run_get_info_dialog_proc
        copy    #5, get_info_dialog_params::L92E3
        copy16  get_file_info_params5::mod_date, date
        jsr     JT_DATE_STRING
        copy16  #text_buffer2::length, get_info_dialog_params::L92E4
        jsr     run_get_info_dialog_proc
        copy    #6, get_info_dialog_params::L92E3
        lda     selected_window_index
        bne     L9519

        COPY_STRING str_vol, str_file_type
        bmi     L951F           ; always

L9519:  lda     get_file_info_params5::file_type
        jsr     JT_FILE_TYPE_STRING
L951F:  copy16  #str_file_type, get_info_dialog_params::L92E4
        jsr     run_get_info_dialog_proc
        bne     done

next:   inc     get_info_dialog_params::L92E6
        jmp     loop

done:   copy    #0, path_buf4
        rts

str_vol:
        PASCAL_STRING " VOL"

.proc run_get_info_dialog_proc
        yax_call invoke_dialog_proc, index_get_info_dialog, get_info_dialog_params
        rts
.endproc
.endproc

;;; ============================================================

.proc do_rename_icon_impl

        src_path_buf := $220

        DEFINE_RENAME_PARAMS rename_params, src_path_buf, dst_path_buf

rename_dialog_params:
        .byte   0
        .addr   $1F00

start:
        copy    #0, L9706
L9576:  lda     L9706
        cmp     selected_icon_count
        bne     L9581
        return  #0

L9581:  ldx     L9706
        lda     selected_icon_list,x
        cmp     #$01
        bne     L9591
        inc     L9706
        jmp     L9576

L9591:  lda     selected_window_index
        beq     L95C2
        asl     a
        tax
        copy16  window_path_addr_table,x, $08
        ldx     L9706
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        jsr     join_paths
        ldy     #$00
L95B0:  lda     path_buf3,y
        sta     src_path_buf,y
        iny
        cpy     src_path_buf
        bne     L95B0
        dec     src_path_buf
        jmp     L95E0

L95C2:  ldx     L9706
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        ldy     #$00
L95CD:  lda     ($06),y
        sta     src_path_buf,y
        iny
        cpy     src_path_buf
        bne     L95CD
        dec     src_path_buf
        lda     #'/'
        sta     src_path_buf+1
L95E0:  ldx     L9706
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        ldy     #$00
        lda     ($06),y
        tay
L95EE:  lda     ($06),y
        sta     $1F12,y
        dey
        bpl     L95EE
        ldy     #$00
        lda     ($06),y
        tay
        dey
        sec
        sbc     #$02
        sta     $1F00
L9602:  lda     ($06),y
        sta     $1F00-1,y
        dey
        cpy     #$01
        bne     L9602
        lda     #$00
        jsr     L96F8
L9611:  lda     #$80
        jsr     L96F8
        beq     L962F
L9618:  ldx     L9706
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        ldy     $1F12
L9624:  lda     $1F12,y
        sta     ($06),y
        dey
        bpl     L9624
        return  #$FF

L962F:  sty     $08
        sty     L9707
        stx     $08+1
        stx     L9708
        lda     selected_window_index
        beq     L964D
        asl     a
        tax
        copy16  window_path_addr_table,x, $06
        jmp     L9655

L964D:  copy16  #L9705, $06
L9655:  ldy     #$00
        lda     ($06),y
        tay
L965A:  lda     ($06),y
        sta     dst_path_buf,y
        dey
        bpl     L965A
        inc     dst_path_buf
        ldx     dst_path_buf
        lda     #'/'
        sta     dst_path_buf,x
        ldy     #$00
        lda     ($08),y
        sta     L9709
L9674:  inx
        iny
        lda     ($08),y
        sta     dst_path_buf,x
        cpy     L9709
        bne     L9674
        stx     dst_path_buf
        MLI_RELAY_CALL RENAME, rename_params
        beq     L969E
        jsr     JT_SHOW_ALERT0
        bne     L9696
        jmp     L9611

L9696:  lda     #$40
        jsr     L96F8
        jmp     L9618

L969E:  lda     #$40
        jsr     L96F8
        ldx     L9706
        lda     selected_icon_list,x
        sta     icon_param2
        yax_call JT_DESKTOP_RELAY, DT_REDRAW_ICON_IDX, icon_param2
        copy16  L9707, $08
        ldx     L9706
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        ldy     #$00
        lda     ($08),y
        clc
        adc     #$02
        sta     ($06),y
        lda     ($08),y
        tay
        inc16   $06
L96DA:  lda     ($08),y
        sta     ($06),y
        dey
        bne     L96DA
        dec     $06
        lda     $06
        cmp     #$FF
        bne     L96EB
        dec     $06+1
L96EB:  lda     ($06),y
        tay
        lda     #' '
        sta     ($06),y
        inc     L9706
        jmp     L9576

L96F8:  sta     rename_dialog_params
        yax_call invoke_dialog_proc, index_rename_dialog, rename_dialog_params
        rts

L9705:  .byte   $00
L9706:  .byte   $00
L9707:  .byte   $00
L9708:  .byte   $00
L9709:  .byte   $00
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

        buf_size = $AC0

        DEFINE_CLOSE_PARAMS close_src_params
        DEFINE_CLOSE_PARAMS close_dst_params
        DEFINE_DESTROY_PARAMS destroy_params, src_path_buf
        DEFINE_OPEN_PARAMS open_src_params, src_path_buf, $0D00
        DEFINE_OPEN_PARAMS open_dst_params, dst_path_buf, $1100
        DEFINE_READ_PARAMS read_src_params, $1500, buf_size
        DEFINE_WRITE_PARAMS write_dst_params, $1500, buf_size
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
        op_jt_addrs_size := 6
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
        ldx     #$80
        jsr     JT_SHOW_ALERT
        beq     @retry
        jmp     close_files_cancel_dialog

:       lda     open_src_dir_params::ref_num
        sta     op_ref_num
        sta     read_src_dir_header_params::ref_num

@retry2:MLI_RELAY_CALL READ, read_src_dir_header_params
        beq     :+
        ldx     #$80
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
        ldx     #$80
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
        ldx     #$80
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

.proc copy_dialog_params
phase:  .byte   0
count:  .addr   0
        .addr   src_path_buf
        .addr   dst_path_buf
.endproc

.proc do_copy_dialog_phase
        copy    #CopyDialogLifecycle::open, copy_dialog_params::phase
        copy16  #copy_dialog_phase0_callback1, dialog_phase0_callback
        copy16  #copy_dialog_phase1_callback1, dialog_phase1_callback
        jmp     run_copy_dialog_proc
.endproc

.proc copy_dialog_phase0_callback1
        stax    copy_dialog_params::count
        copy    #CopyDialogLifecycle::populate, copy_dialog_params::phase
        jmp     run_copy_dialog_proc
.endproc

.proc prep_callbacks_for_copy
        ldy     #op_jt_addrs_size-1
:       copy    callbacks_for_copy,y,  op_jt_addrs,y
        dey
        bpl     :-

        lda     #0
        sta     LA425
        sta     all_flag
        rts
.endproc

.proc copy_dialog_phase1_callback1
        copy    #CopyDialogLifecycle::close, copy_dialog_params::phase
        jmp     run_copy_dialog_proc
.endproc

.proc do_download_dialog_phase
        copy    #CopyDialogLifecycle::open, copy_dialog_params::phase
        copy16  #copy_dialog_phase0_callback2, dialog_phase0_callback
        copy16  #copy_dialog_phase1_callback2, dialog_phase1_callback
        yax_call invoke_dialog_proc, index_download_dialog, copy_dialog_params
        rts
.endproc

.proc copy_dialog_phase0_callback2
        stax    copy_dialog_params::count
        copy    #CopyDialogLifecycle::populate, copy_dialog_params::phase
        yax_call invoke_dialog_proc, index_download_dialog, copy_dialog_params
        rts
.endproc

.proc L99BC
        copy    #$80, all_flag

        ldy     #op_jt_addrs_size-1
:       copy    callbacks_for_copy,y, op_jt_addrs,y
        dey
        bpl     :-

        copy    #0, LA425
        copy16  #copy_dialog_phase3_callback, dialog_phase3_callback
        rts
.endproc

.proc copy_dialog_phase1_callback2
        copy    #CopyDialogLifecycle::exists, copy_dialog_params::phase
        yax_call invoke_dialog_proc, index_download_dialog, copy_dialog_params
        rts
.endproc

.proc copy_dialog_phase3_callback
        copy    #CopyDialogLifecycle::too_large, copy_dialog_params::phase
        yax_call invoke_dialog_proc, index_download_dialog, copy_dialog_params
        cmp     #PromptResult::yes
        bne     cancel
        rts
.endproc

cancel: jmp     close_files_cancel_dialog

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
        lda     op_file_count+1
        bne     :+
        lda     op_file_count
        bne     :+
        jmp     close_files_cancel_dialog

        ;; Copy access, file_type, aux_type, storage_type
:       ldy     #7
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
        lda     op_file_count+1
        bne     :+
        lda     op_file_count
        bne     :+
        jmp     close_files_cancel_dialog

:       jsr     try_create_dst
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
        yax_call invoke_dialog_proc, index_copy_dialog, copy_dialog_params
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
        copy16  #buf_size, read_src_params::request_count
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
        yax_call invoke_dialog_proc, index_copy_dialog, copy_dialog_params
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

.proc delete_dialog_params
phase:  .byte   0
count:  .word   0
        .addr   src_path_buf
.endproc

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
        ldy     #op_jt_addrs_size-1
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
        yax_call invoke_dialog_proc, index_delete_dialog, delete_dialog_params
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
        yax_call invoke_dialog_proc, index_delete_dialog, delete_dialog_params
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

.proc lock_unlock_dialog_params
phase:  .byte   0
files_remaining_count:
        .word   0
        .addr   src_path_buf
.endproc

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

        ldy     #op_jt_addrs_size-1
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
        yax_call invoke_dialog_proc, index_lock_dialog, lock_unlock_dialog_params
        rts

unlock_dialog_lifecycle:
        yax_call invoke_dialog_proc, index_unlock_dialog, lock_unlock_dialog_params
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

.proc get_size_dialog_params
phase:  .byte   0
        .addr   op_file_count, op_block_count
.endproc

do_get_size_dialog_phase:
        copy    #0, get_size_dialog_params::phase
        copy16  #get_size_dialog_phase2_callback, dialog_phase2_callback
        copy16  #get_size_dialog_phase0_callback, dialog_phase0_callback
        yax_call invoke_dialog_proc, index_get_size_dialog, get_size_dialog_params
        copy16  #get_size_dialog_phase1_callback, dialog_phase1_callback
        rts

.proc get_size_dialog_phase0_callback
        copy    #1, get_size_dialog_params::phase
        yax_call invoke_dialog_proc, index_get_size_dialog, get_size_dialog_params
        ;; fall through
.endproc
get_size_rts1:
        rts

.proc get_size_dialog_phase2_callback
        copy    #2, get_size_dialog_params::phase
        yax_call invoke_dialog_proc, index_get_size_dialog, get_size_dialog_params
        beq     get_size_rts1
        jmp     close_files_cancel_dialog
.endproc

.proc get_size_dialog_phase1_callback
        copy    #3, get_size_dialog_params::phase
        yax_call invoke_dialog_proc, index_get_size_dialog, get_size_dialog_params
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

        ldy     #op_jt_addrs_size-1
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
        sta     getwinport_params2::window_id
        yax_call JT_MGTK_RELAY, MGTK::GetWinPort, getwinport_params2
        yax_call JT_MGTK_RELAY, MGTK::SetPort, grafport2
:       ldx     stack_stash     ; restore stack, in case recusion was aborted
        txs
        return  #$FF
.endproc

;;; ============================================================
;;; Move or Copy? Compare src/dst paths, same vol = move.
;;; Output: A=high bit set if move, clear if copy

.proc check_move_or_copy
        src_ptr := $08
        dst_buf := path_buf4

        bit     BUTN0           ; Open-Apple overrides, forces copy
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
        yax_call JT_MGTK_RELAY, MGTK::GetEvent, event_params
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
        yax_call invoke_dialog_proc, index_delete_dialog, delete_dialog_params
        rts
.endproc

.proc dec_file_count_and_run_copy_dialog_proc
        sub16   op_file_count, #1, copy_dialog_params::count
        yax_call invoke_dialog_proc, index_copy_dialog, copy_dialog_params
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
        lda     #ERR_INSERT_DST_DISK
        jmp     show

:       lda     #ERR_INSERT_SRC_DISK
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
        ram_unit_number = (1<<7 | 3<<4 | DT_RAM)

        ;; Search DEVLST to see if S3D2 RAM was restored
        ldx     DEVCNT
:       lda     DEVLST,x
        cmp     #ram_unit_number
        beq     format
        dex
        bpl     :-
        rts

        ;; NOTE: Assumes driver (in DEVADR) was not modified
        ;; when detached.

        ;; /RAM FORMAT call; see ProDOS 8 TRM 5.2.2.4 for details
format: copy    #DRIVER_COMMAND_FORMAT, DRIVER_COMMAND
        copy    #ram_unit_number, DRIVER_UNIT_NUMBER
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

        PAD_TO $A500

;;; ============================================================
;;; Dialog Launcher (or just proc handler???)

        index_about_dialog              = 0
        index_copy_dialog               = 1
        index_delete_dialog             = 2
        index_new_folder_dialog         = 3
        index_get_info_dialog           = 6
        index_lock_dialog               = 7
        index_unlock_dialog             = 8
        index_rename_dialog             = 9
        index_download_dialog           = 10
        index_get_size_dialog           = 11
        index_warning_dialog            = 12

invoke_dialog_proc:
        .assert * = $A500, error, "Entry point used by overlay"
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
        sta     cursor_ip_flag

        copy    #prompt_insertion_point_blink_count, prompt_ip_counter

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
        copy    #prompt_insertion_point_blink_count, prompt_ip_counter

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
        MGTK_RELAY_CALL MGTK::FindWindow, event_coords
        lda     findwindow_which_area
        bne     :+
        jmp     prompt_input_loop

:       lda     findwindow_window_id
        cmp     winfo_alert_dialog
        beq     :+
        jmp     prompt_input_loop

:       lda     winfo_alert_dialog ; Is over this window... but where?
        jsr     set_port_from_window_id
        copy    winfo_alert_dialog, event_params
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, name_input_rect
        cmp     #MGTK::inrect_inside
        bne     out
        jsr     set_cursor_insertion_point_with_flag
        jmp     done
out:    jsr     set_cursor_pointer_with_flag
done:   jsr     reset_grafport3a
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
        cmp     winfo_alert_dialog
        beq     :+
        return  #$FF
:       lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        copy    winfo_alert_dialog, event_params
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        bit     LD8E7
        bvc     :+
        jmp     check_button_yes

:       MGTK_RELAY_CALL MGTK::InRect, desktop_aux::ok_button_rect
        cmp     #MGTK::inrect_inside
        beq     check_button_ok
        jmp     maybe_check_button_cancel

check_button_ok:
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::ok_button_rect
        jsr     button_loop_ok
        bmi     :+
        lda     #PromptResult::ok
:       rts

check_button_yes:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::yes_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_button_no
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::yes_button_rect
        jsr     button_loop_yes
        bmi     :+
        lda     #PromptResult::yes
:       rts

check_button_no:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::no_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_button_all
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::no_button_rect
        jsr     button_loop_no
        bmi     :+
        lda     #PromptResult::no
:       rts

check_button_all:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::all_button_rect
        cmp     #MGTK::inrect_inside
        bne     maybe_check_button_cancel
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::all_button_rect
        jsr     button_loop_all
        bmi     :+
        lda     #PromptResult::all
:       rts

maybe_check_button_cancel:
        bit     LD8E7
        bpl     check_button_cancel
        return  #$FF

check_button_cancel:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::cancel_button_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        jmp     LA6ED
:       jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::cancel_button_rect
        jsr     button_loop_cancel
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
        bne     LA71A
        lda     event_key
        and     #CHAR_MASK
        cmp     #CHAR_LEFT
        bne     LA710
        jmp     LA815

LA710:  cmp     #CHAR_RIGHT
        bne     LA717
        jmp     LA820

LA717:  return  #$FF

LA71A:  lda     event_key
        and     #CHAR_MASK
        cmp     #CHAR_LEFT
        bne     LA72E
        bit     format_erase_overlay_flag
        bpl     :+
        jmp     format_erase_overlay::L0CB8

:       jmp     LA82B

LA72E:  cmp     #CHAR_RIGHT
        bne     LA73D
        bit     format_erase_overlay_flag
        bpl     :+
        jmp     format_erase_overlay::L0CD7

:       jmp     LA83E

LA73D:  cmp     #CHAR_RETURN
        bne     LA749
        bit     LD8E7
        bvs     LA717
        jmp     LA851

LA749:  cmp     #CHAR_ESCAPE
        bne     LA755
        bit     LD8E7
        bmi     LA717
        jmp     LA86F

LA755:  cmp     #CHAR_DELETE
        bne     LA75C
        jmp     LA88D

LA75C:  cmp     #CHAR_UP
        bne     LA76B
        bit     format_erase_overlay_flag
        bmi     LA768
        jmp     LA717

LA768:  jmp     format_erase_overlay::L0D14

LA76B:  cmp     #CHAR_DOWN
        bne     LA77A
        bit     format_erase_overlay_flag
        bmi     LA777
        jmp     LA717

LA777:  jmp     format_erase_overlay::L0CF9

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
        jmp     LA717

LA7AB:  cmp     #'z'+1
        bcc     LA7B2
        jmp     LA717

LA7B2:  cmp     #'9'+1
        bcc     LA7D8
        cmp     #'A'
        bcs     LA7BD
        jmp     LA717

LA7BD:  cmp     #'Z'+1
        bcc     LA7DD
        cmp     #'a'
        bcs     LA7DD
        jmp     LA717

LA7C8:  cmp     #' '
        bcs     LA7CF
        jmp     LA717

LA7CF:  cmp     #'~'
        beq     LA7DD
        bcc     LA7DD
        jmp     LA717

LA7D8:  ldx     path_buf1
        beq     LA7E5
LA7DD:  ldx     has_input_field_flag
        beq     LA7E5
        jsr     LBB0B
LA7E5:  return  #$FF

do_yes: jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::yes_button_rect
        return  #PromptResult::yes

do_no:  jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::no_button_rect
        return  #PromptResult::no

do_all: jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::all_button_rect
        return  #PromptResult::all

LA815:  lda     has_input_field_flag
        beq     LA81D
        jsr     LBC5E
LA81D:  return  #$FF

LA820:  lda     has_input_field_flag
        beq     LA828
        jsr     LBCC9
LA828:  return  #$FF

LA82B:  lda     has_input_field_flag
        beq     LA83B
        bit     format_erase_overlay_flag
        bpl     LA838
        jmp     format_erase_overlay::L0CD7

LA838:  jsr     LBBA4
LA83B:  return  #$FF

LA83E:  lda     has_input_field_flag
        beq     LA84E
        bit     format_erase_overlay_flag
        bpl     LA84B
        jmp     format_erase_overlay::L0CB8

LA84B:  jsr     LBC03
LA84E:  return  #$FF

LA851:  lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::ok_button_rect
        return  #0

LA86F:  lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::cancel_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::cancel_button_rect
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
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::about_dialog_outer_rect
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::about_dialog_inner_rect
        addr_call draw_dialog_title, desktop_aux::str_about1
        axy_call draw_dialog_label, 1 | DDL_CENTER, desktop_aux::str_about2
        axy_call draw_dialog_label, 2 | DDL_CENTER, desktop_aux::str_about3
        axy_call draw_dialog_label, 3 | DDL_CENTER, desktop_aux::str_about4
        axy_call draw_dialog_label, 5, desktop_aux::str_about5
        axy_call draw_dialog_label, 6 | DDL_CENTER, desktop_aux::str_about6
        axy_call draw_dialog_label, 7, desktop_aux::str_about7
        axy_call draw_dialog_label, 9, desktop_aux::str_about8
        copy16  #310 - (7 * .strlen(VERSION_SUFFIX)), dialog_label_pos
        axy_call draw_dialog_label, 9, desktop_aux::str_about9
        copy16  #dialog_label_default_x, dialog_label_pos

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
        jsr     reset_grafport3a
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

        axy_call draw_dialog_label, 2, desktop_aux::str_copy_from
        axy_call draw_dialog_label, 3, desktop_aux::str_copy_to
        bit     move_flag
        bmi     :+
        addr_call draw_dialog_title, desktop_aux::str_copy_title
        axy_call draw_dialog_label, 1, desktop_aux::str_copy_copying
        axy_call draw_dialog_label, 4, desktop_aux::str_copy_remaining
        rts
:       addr_call draw_dialog_title, desktop_aux::str_move_title
        axy_call draw_dialog_label, 1, desktop_aux::str_move_moving
        axy_call draw_dialog_label, 4, desktop_aux::str_move_remaining
        rts

        ;; CopyDialogLifecycle::populate
do1:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::copy_file_count_pos
        addr_call draw_text1, str_file_count
        addr_call draw_text1, str_files
        rts

        ;; CopyDialogLifecycle::exists
do2:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
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
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::current_target_file_pos
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
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::current_dest_file_pos
        addr_call draw_text1, path_buf1
        yax_call MGTK_RELAY, MGTK::MoveTo, desktop_aux::copy_file_count_pos2
        addr_call draw_text1, str_file_count
        rts

        ;; CopyDialogLifecycle::close
do5:    jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer
        rts

        ;; CopyDialogLifecycle::exists
do3:    jsr     bell
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        axy_call draw_dialog_label, 6, desktop_aux::str_exists_prompt
        jsr     draw_yes_no_all_cancel_buttons
LAA7F:  jsr     prompt_input_loop
        bmi     LAA7F
        pha
        jsr     erase_yes_no_all_cancel_buttons
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::prompt_rect
        pla
        rts

        ;; CopyDialogLifecycle::too_large
do4:    jsr     bell
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        axy_call draw_dialog_label, 6, desktop_aux::str_large_prompt
        jsr     draw_ok_cancel_buttons
:       jsr     prompt_input_loop
        bmi     :-
        pha
        jsr     erase_ok_cancel_buttons
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::prompt_rect
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
        addr_call draw_dialog_title, desktop_aux::str_download
        axy_call draw_dialog_label, 1, desktop_aux::str_copy_copying
        axy_call draw_dialog_label, 2, desktop_aux::str_copy_from
        axy_call draw_dialog_label, 3, desktop_aux::str_copy_to
        axy_call draw_dialog_label, 4, desktop_aux::str_copy_remaining
        rts

do1:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::copy_file_count_pos
        addr_call draw_text1, str_file_count
        addr_call draw_text1, str_files
        rts

do2:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
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
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::copy_file_count_pos2
        addr_call draw_text1, str_file_count
        rts

do3:    jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer
        rts

do4:    jsr     bell
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        axy_call draw_dialog_label, 6, desktop_aux::str_ramcard_full
        jsr     draw_ok_button
:       jsr     prompt_input_loop
        bmi     :-
        pha
        jsr     erase_ok_button
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::prompt_rect
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
        addr_call draw_dialog_title, desktop_aux::str_size_title
        axy_call draw_dialog_label, 1, desktop_aux::str_size_number
        ldy     #1
        jsr     draw_colon
        axy_call draw_dialog_label, 2, desktop_aux::str_size_blocks
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
        lda     winfo_alert_dialog
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

do3:    jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer
        rts

do2:    lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     draw_ok_button
:       jsr     prompt_input_loop
        bmi     :-
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::clear_dialog_labels_rect
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
        addr_call draw_dialog_title, desktop_aux::str_delete_title
        lda     LAD1F
        beq     LAD20
        axy_call draw_dialog_label, 4, desktop_aux::str_ok_empty
        rts

LAD1F:  .byte   0
LAD20:  axy_call draw_dialog_label, 4, desktop_aux::str_delete_ok
        rts

        ;; DeleteDialogLifecycle::populate
do1:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        lda     LAD1F
        bne     LAD54
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::delete_file_count_pos
        jmp     LAD5D

LAD54:  MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::delete_file_count_pos2
LAD5D:  addr_call draw_text1, str_file_count
        addr_call draw_text1, str_files
        rts

        ;; DeleteDialogLifecycle::show
do3:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
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
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::delete_remaining_count_pos
        addr_call draw_text1, str_file_count
        rts

        ;; DeleteDialogLifecycle::confirm
do2:    lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     draw_ok_cancel_buttons
LADC4:  jsr     prompt_input_loop
        bmi     LADC4
        bne     LADF4
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::clear_dialog_labels_rect
        jsr     erase_ok_cancel_buttons
        yax_call draw_dialog_label, 2, desktop_aux::str_file_colon
        yax_call draw_dialog_label, 4, desktop_aux::str_delete_remaining
        lda     #$00
LADF4:  rts

        ;; DeleteDialogLifecycle::close
do5:    jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer
        rts

        ;; DeleteDialogLifecycle::locked
do4:    lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        axy_call draw_dialog_label, 6, desktop_aux::str_delete_locked_file
        jsr     draw_yes_no_all_cancel_buttons
LAE17:  jsr     prompt_input_loop
        bmi     LAE17
        pha
        jsr     erase_yes_no_all_cancel_buttons
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy ; white
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::prompt_rect ; erase prompt
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
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        addr_call draw_dialog_title, desktop_aux::str_new_folder_title
        jsr     set_penmode_xor2
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
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        yax_call draw_dialog_label, 2, desktop_aux::str_in_colon
        copy    #55, dialog_label_pos
        yax_call draw_dialog_label, 2, path_buf0
        copy    #dialog_label_default_x, dialog_label_pos
        yax_call draw_dialog_label, 4, desktop_aux::str_enter_folder_name
        jsr     draw_filename_prompt
LAEC6:  jsr     prompt_input_loop
        bmi     LAEC6
        bne     LAF16
        jsr     merge_path_buf1_path_buf2
        lda     path_buf1
        beq     LAEC6
        cmp     #16             ; max filename length
        bcc     LAEE1
LAED6:  lda     #ERR_NAME_TOO_LONG
        jsr     JT_SHOW_ALERT0
        jsr     draw_filename_prompt
        jmp     LAEC6

LAEE1:  lda     path_buf0
        clc
        adc     path_buf1
        clc
        adc     #$01
        cmp     #$41
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

LAF16:  jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
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
        bmi     LAF34
        jmp     LAFB9

LAF34:  copy    #0, has_input_field_flag
        lda     (ptr),y
        lsr     a
        lsr     a
        ror     a
        eor     #$80
        jsr     open_prompt_window
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        addr_call draw_dialog_title, desktop_aux::str_info_title
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     (ptr),y
        and     #$7F
        lsr     a
        ror     a
        sta     LB01D
        yax_call draw_dialog_label, 1, desktop_aux::str_info_name
        bit     LB01D
        bmi     LAF78
        yax_call draw_dialog_label, 2, desktop_aux::str_info_locked
        jmp     LAF81

LAF78:  yax_call draw_dialog_label, 2, desktop_aux::str_info_protected
LAF81:  bit     LB01D
        bpl     LAF92
        yax_call draw_dialog_label, 3, desktop_aux::str_info_blocks
        jmp     LAF9B

LAF92:  yax_call draw_dialog_label, 3, desktop_aux::str_info_size
LAF9B:  yax_call draw_dialog_label, 4, desktop_aux::str_info_create
        yax_call draw_dialog_label, 5, desktop_aux::str_info_mod
        yax_call draw_dialog_label, 6, desktop_aux::str_info_type
        jmp     reset_grafport3a

LAFB9:  lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        copy    (ptr),y, row
        tay
        jsr     draw_colon
        copy    #165, dialog_label_pos
        jsr     copy_dialog_param_addr_to_ptr
        lda     row
        cmp     #2
        bne     LAFF0
        ldy     #1
        lda     (ptr),y
        beq     :+
        addr_jump LAFF8, desktop_aux::str_yes_label
:       addr_jump LAFF8, desktop_aux::str_no_label

LAFF0:  ldy     #2
        lda     (ptr),y
        tax
        dey
        lda     (ptr),y
LAFF8:  ldy     row
        jsr     draw_dialog_label
        lda     row
        cmp     #6
        beq     :+
        rts

:       jsr     prompt_input_loop
        bmi     :-

        pha
        jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer_with_flag
        pla
        rts

LB01D:  .byte   0
row:    .byte   0
.endproc

;;; ============================================================
;;; Draw ":" after dialog label

.proc draw_colon
        copy    #160, dialog_label_pos
        addr_call draw_dialog_label, desktop_aux::str_colon
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
        addr_call draw_dialog_title, desktop_aux::str_lock_title
        yax_call draw_dialog_label, 4, desktop_aux::str_lock_ok
        rts

        ;; LockDialogLifecycle::populate
do1:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::lock_remaining_count_pos2
        addr_call draw_text1, str_file_count
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::files_pos2
        addr_call draw_text1, str_files
        rts

        ;; LockDialogLifecycle::operation
do3:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
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
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::lock_remaining_count_pos
        addr_call draw_text1, str_file_count
        rts

        ;; LockDialogLifecycle::loop
do2:    lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     draw_ok_cancel_buttons
LB0FA:  jsr     prompt_input_loop
        bmi     LB0FA
        bne     LB139
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::clear_dialog_labels_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::cancel_button_rect
        yax_call draw_dialog_label, 2, desktop_aux::str_file_colon
        yax_call draw_dialog_label, 4, desktop_aux::str_lock_remaining
        lda     #$00
LB139:  rts

        ;; LockDialogLifecycle::close
do4:    jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
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
        addr_call draw_dialog_title, desktop_aux::str_unlock_title
        yax_call draw_dialog_label, 4, desktop_aux::str_unlock_ok
        rts

        ;; LockDialogLifecycle::populate
do1:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::unlock_remaining_count_pos2
        addr_call draw_text1, str_file_count
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::files_pos
        addr_call draw_text1, str_files
        rts

        ;; LockDialogLifecycle::operation
do3:    ldy     #1
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
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
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::unlock_remaining_count_pos
        addr_call draw_text1, str_file_count
        rts

        ;; LockDialogLifecycle::loop
do2:    lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     draw_ok_cancel_buttons
LB218:  jsr     prompt_input_loop
        bmi     LB218
        bne     LB257
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::clear_dialog_labels_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::cancel_button_rect
        yax_call draw_dialog_label, 2, desktop_aux::str_file_colon
        yax_call draw_dialog_label, 4, desktop_aux::str_unlock_remaining
        lda     #$00
LB257:  rts

        ;; LockDialogLifecycle::close
do4:    jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer
        rts
.endproc

;;; ============================================================
;;; "Rename" dialog

.proc rename_dialog_proc
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #0
        lda     ($06),y
        cmp     #$80
        bne     LB276
        jmp     LB2ED

LB276:  cmp     #$40
        bne     LB27D
        jmp     LB313

LB27D:  jsr     clear_path_buf1
        jsr     copy_dialog_param_addr_to_ptr
        copy    #$80, has_input_field_flag
        jsr     clear_path_buf2
        lda     #$00
        jsr     open_prompt_window
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        addr_call draw_dialog_title, desktop_aux::str_rename_title
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::FrameRect, name_input_rect
        yax_call draw_dialog_label, 2, desktop_aux::str_rename_old
        copy    #85, dialog_label_pos
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #1
        copy16in ($06),y, $08
        ldy     #0
        lda     ($08),y
        tay
LB2CA:  copy    ($08),y, buf_filename,y
        dey
        bpl     LB2CA
        yax_call draw_dialog_label, 2, buf_filename
        yax_call draw_dialog_label, 4, desktop_aux::str_rename_new
        copy    #0, path_buf1
        jsr     draw_filename_prompt
        rts

LB2ED:  copy16  #$8000, LD8E7
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
LB2FD:  jsr     prompt_input_loop
        bmi     LB2FD
        bne     LB313
        lda     path_buf1
        beq     LB2FD
        jsr     LBCC9
        ldy     #<path_buf1
        ldx     #>path_buf1
        return  #0

LB313:  jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer
        return  #1
.endproc

;;; ============================================================
;;; "Warning!" dialog
;;; $6 ptr to message num

.proc warning_dialog_proc
        ptr := $6

        ;; Create window
        MGTK_RELAY_CALL MGTK::HideCursor
        jsr     open_alert_window
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        addr_call draw_dialog_title, desktop_aux::str_warning
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
        jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer
        pla
        rts

        ;; high bit set if "cancel" should be an option
warning_cancel_table:
        .byte   $80,$00,$00,$80,$00,$00,$80

warning_message_table:
        .addr   desktop_aux::str_insert_system_disk,desktop_aux::str_1_space
        .addr   desktop_aux::str_selector_list_full,desktop_aux::str_before_new_entries
        .addr   desktop_aux::str_selector_list_full,desktop_aux::str_before_new_entries
        .addr   desktop_aux::str_window_must_be_closed,desktop_aux::str_1_space
        .addr   desktop_aux::str_window_must_be_closed,desktop_aux::str_1_space
        .addr   desktop_aux::str_too_many_windows,desktop_aux::str_1_space
        .addr   desktop_aux::str_save_selector_list,desktop_aux::str_on_system_disk
.endproc
        warning_msg_insert_system_disk          = 0
        warning_msg_selector_list_full          = 1
        warning_msg_selector_list_full2         = 2
        warning_msg_window_must_be_closed       = 3
        warning_msg_window_must_be_closed2      = 4
        warning_msg_too_many_windows            = 5
        warning_msg_save_selector_list          = 6

;;; ============================================================

.proc copy_dialog_param_addr_to_ptr
        copy16  dialog_param_addr, $06
        rts
.endproc

;;; ============================================================

.proc set_cursor_pointer_with_flag
        bit     cursor_ip_flag
        bpl     :+
        jsr     set_cursor_pointer
        copy    #0, cursor_ip_flag
:       rts
.endproc

.proc set_cursor_insertion_point_with_flag
        bit     cursor_ip_flag
        bmi     :+
        jsr     set_cursor_insertion_point
        copy    #$80, cursor_ip_flag
:       rts
.endproc

cursor_ip_flag:                 ; high bit set if IP, clear if pointer
        .byte   0

;;; ============================================================
;;;
;;; Routines beyond this point are used by overlays
;;;
;;; ============================================================

        .assert * >= $A000, error, "Routine used by overlays in overlay zone"

.proc bell
        sta     ALTZPOFF
        sta     ROMIN2
        jsr     BELL1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

.proc set_cursor_watch
        MGTK_RELAY_CALL MGTK::HideCursor
        MGTK_RELAY_CALL MGTK::SetCursor, watch_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor
        rts
.endproc

.proc set_cursor_pointer
        MGTK_RELAY_CALL MGTK::HideCursor
        MGTK_RELAY_CALL MGTK::SetCursor, pointer_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor
        rts
.endproc

.proc set_cursor_insertion_point
        MGTK_RELAY_CALL MGTK::HideCursor
        MGTK_RELAY_CALL MGTK::SetCursor, insertion_point_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor
        rts
.endproc

set_penmode_xor2:
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        rts

;;; ============================================================
;;; Double Click Detection
;;; Returns with A=0 if double click, A=$FF otherwise.

.proc detect_double_click
        double_click_deltax = 5
        double_click_deltay = 4

        ;; Stash initial coords
        ldx     #3
:       copy    event_coords,x, coords,x
        sta     saved_event_coords,x ; for double-click in windows
        dex
        bpl     :-

        lda     #0
        sta     counter+1
        lda     machine_type ; Speed of mouse driver? ($96=IIe,$FA=IIc,$FD=IIgs)
        asl     a            ; * 2
        rol     counter+1    ; So IIe = $12C, IIc = $1F4, IIgs = $1FA
        sta     counter

        ;; Decrement counter, bail if time delta exceeded
loop:   dec     counter
        bne     :+
        dec     counter+1
        bne     exit

:       MGTK_RELAY_CALL MGTK::PeekEvent, event_params

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
        bne     exit

        MGTK_RELAY_CALL MGTK::GetEvent, event_params
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
        cmp     #AS_BYTE(-double_click_deltax)
        bcs     check_y
fail:   return  #$FF

        ;; is 0 < x < delta ?
:       lda     delta
        cmp     #double_click_deltax
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
        cmp     #AS_BYTE(-double_click_deltay)
        bcs     ok

        ;; is 0 < y < delta ?
:       lda     delta
        cmp     #double_click_deltay
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

:       MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::ok_button_rect
        jsr     draw_ok_label
no_ok:  bit     LD8E7
        bmi     done
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::cancel_button_rect
        jsr     draw_cancel_label
done:   jmp     reset_grafport3a
.endproc

;;; ============================================================

.proc open_dialog_window
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_alert_dialog
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::confirm_dialog_outer_rect
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::confirm_dialog_inner_rect
        rts
.endproc

;;; ============================================================

.proc open_alert_window
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_alert_dialog
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     set_fill_white
        MGTK_RELAY_CALL MGTK::PaintBits, alert_bitmap2_params
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::confirm_dialog_outer_rect
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::confirm_dialog_inner_rect
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
        jsr     load_aux_from_ptr
        sta     textlen
        MGTK_RELAY_CALL MGTK::TextWidth, textwidth_params
        lsr16   result
        sub16   #200, result, dialog_label_pos
        pla

        ;; y = base + desktop_aux::dialog_label_height * line
skip:   ldx     #0
        ldy     #desktop_aux::dialog_label_height
        jsr     Multiply_16_8_16
        stax    dialog_label_pos::ycoord
        add16   dialog_label_pos::ycoord, dialog_label_base_pos::ycoord, dialog_label_pos::ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, dialog_label_pos
        addr_call_indirect draw_text1, ptr
        ldx     dialog_label_pos
        copy    #dialog_label_default_x,dialog_label_pos::xcoord ; restore original x coord
        rts
.endproc

;;; ============================================================

draw_ok_label:
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::ok_label_pos
        addr_call draw_text1, desktop_aux::str_ok_label
        rts

draw_cancel_label:
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::cancel_label_pos
        addr_call draw_text1, desktop_aux::str_cancel_label
        rts

draw_yes_label:
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::yes_label_pos
        addr_call draw_text1, desktop_aux::str_yes_label
        rts

draw_no_label:
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::no_label_pos
        addr_call draw_text1, desktop_aux::str_no_label
        rts

draw_all_label:
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::all_label_pos
        addr_call draw_text1, desktop_aux::str_all_label
        rts

draw_yes_no_all_cancel_buttons:
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::yes_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::no_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::all_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::cancel_button_rect
        jsr     draw_yes_label
        jsr     draw_no_label
        jsr     draw_all_label
        jsr     draw_cancel_label
        copy    #$40, LD8E7
        rts

erase_yes_no_all_cancel_buttons:
        jsr     set_fill_white
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::yes_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::no_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::all_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::cancel_button_rect
        rts

draw_ok_cancel_buttons:
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::cancel_button_rect
        jsr     draw_ok_label
        jsr     draw_cancel_label
        copy    #$00, LD8E7
        rts

erase_ok_cancel_buttons:
        jsr     set_fill_white
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::cancel_button_rect
        rts

draw_ok_button:
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::FrameRect, desktop_aux::ok_button_rect
        jsr     draw_ok_label
        copy    #$80, LD8E7
        rts

erase_ok_button:
        jsr     set_fill_white
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::ok_button_rect
        rts

;;; ============================================================

.proc draw_text1
        params := $6
        textptr := $6
        textlen := $8

        stax    textptr
        jsr     load_aux_from_ptr
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

        jsr     load_aux_from_ptr
        sta     str_len
        inc     str_data        ; point past length byte
        bne     :+
        inc     str_data+1
:       MGTK_RELAY_CALL MGTK::TextWidth, str
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

apply_bits:
        ldy     #1
bloop:  asl16   version_bytes
        bcc     :+
        lda     (ptr),y
        ora     #AS_BYTE(~CASE_MASK)
        sta     (ptr),y
:       iny
        cpy     #16
        bcc     bloop
        rts


version_bytes:
        .word   0
.endproc
        adjust_fileentry_case := adjust_case_impl::file_entry
        adjust_volname_case := adjust_case_impl::vol_name


;;; ============================================================

.proc set_port_from_window_id
        sta     getwinport_params2::window_id
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params2
        MGTK_RELAY_CALL MGTK::SetPort, grafport2
        rts
.endproc

;;; ============================================================
;;; Event loop during button press - handle inverting
;;; the text as mouse is dragged in/out, report final
;;; click (A as passed) / cancel (A is negative)

button_loop_ok:
        lda     #PromptResult::ok
        jmp     button_event_loop

button_loop_cancel:
        lda     #PromptResult::cancel
        jmp     button_event_loop

button_loop_yes:
        lda     #PromptResult::yes
        jmp     button_event_loop

button_loop_no:
        lda     #PromptResult::no
        jmp     button_event_loop

button_loop_all:
        lda     #PromptResult::all
        jmp     button_event_loop

.proc button_event_loop
        ;; Configure test and fill procs
        pha
        asl     a
        asl     a
        tax
        copy16  test_fill_button_proc_table,x, test_button_proc_addr
        copy16  test_fill_button_proc_table+2,x, fill_button_proc_addr
        pla
        jmp     event_loop

test_fill_button_proc_table:
        .addr   test_ok_button,fill_ok_button
        .addr   test_cancel_button,fill_cancel_button
        .addr   test_yes_button,fill_yes_button
        .addr   test_no_button,fill_no_button
        .addr   test_all_button,fill_all_button

test_ok_button:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::ok_button_rect
        rts

test_cancel_button:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::cancel_button_rect
        rts

test_yes_button:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::yes_button_rect
        rts

test_no_button:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::no_button_rect
        rts

test_all_button:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::all_button_rect
        rts

fill_ok_button:
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::ok_button_rect
        rts

fill_cancel_button:
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::cancel_button_rect
        rts

fill_yes_button:
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::yes_button_rect
        rts

fill_no_button:
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::no_button_rect
        rts

fill_all_button:
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::all_button_rect
        rts

test_proc:  jmp     (test_button_proc_addr)
fill_proc:  jmp     (fill_button_proc_addr)

test_button_proc_addr:  .addr   0
fill_button_proc_addr:  .addr   0

event_loop:
        sta     click_result
        copy    #0, down_flag
loop:   MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     exit
        lda     winfo_alert_dialog
        sta     event_params
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        jsr     test_proc
        cmp     #MGTK::inrect_inside
        beq     inside
        lda     down_flag       ; outside but was inside?
        beq     invert
        jmp     loop

inside: lda     down_flag       ; already depressed?
        bne     invert
        jmp     loop

invert: jsr     set_penmode_xor2
        jsr     fill_proc
        lda     down_flag
        clc
        adc     #$80
        sta     down_flag
        jmp     loop

exit:   lda     down_flag       ; was depressed?
        beq     clicked
        return  #$FF            ; hi bit = cancelled

clicked:
        jsr     fill_proc       ; invert one last time
        return  click_result    ; grab expected result

down_flag:
        .byte   0

click_result:
        .byte   0

.endproc

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
        MGTK_RELAY_CALL MGTK::SetTextBG, desktop_aux::textbg_black
        copy    #0, prompt_ip_flag
        beq     draw            ; always

set_flag:
        MGTK_RELAY_CALL MGTK::SetTextBG, desktop_aux::textbg_white
        copy    #$FF, prompt_ip_flag

        drawtext_params := $6
        textptr := $6
        textlen := $8

draw:   copy16  #str_insertion_point+1, textptr
        lda     str_insertion_point
        sta     textlen
        MGTK_RELAY_CALL MGTK::DrawText, drawtext_params
        MGTK_RELAY_CALL MGTK::SetTextBG, desktop_aux::textbg_white
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        rts
.endproc

;;; ============================================================

.proc draw_filename_prompt
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     set_fill_white
        MGTK_RELAY_CALL MGTK::PaintRect, name_input_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, name_input_rect
        MGTK_RELAY_CALL MGTK::MoveTo, name_input_textpos
        MGTK_RELAY_CALL MGTK::SetPortBits, name_input_mapinfo
        addr_call draw_text1, path_buf1
        addr_call draw_text1, path_buf2
        addr_call draw_text1, str_2_spaces
        lda     winfo_alert_dialog
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
        jmp     LBCC9

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
        jmp     LBC5E

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
        lda     winfo_alert_dialog
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
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        rts
.endproc

;;; ============================================================

.proc LBBA4
        lda     path_buf1
        bne     :+
        rts

        point := $6
        xcoord := $6
        ycoord := $8

:       ldx     path_buf2
        cpx     #1
        beq     LBBBC
LBBB1:  lda     path_buf2,x
        sta     path_buf2+1,x
        dex
        cpx     #1
        bne     LBBB1
LBBBC:  ldx     path_buf1
        lda     path_buf1,x
        sta     path_buf2+2
        dec     path_buf1
        inc     path_buf2
        jsr     measure_path_buf1
        stax    xcoord
        copy16  name_input_textpos::ycoord, ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, point
        MGTK_RELAY_CALL MGTK::SetPortBits, name_input_mapinfo
        addr_call draw_text1, path_buf2
        addr_call draw_text1, str_2_spaces
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        rts
.endproc

;;; ============================================================

.proc LBC03
        lda     path_buf2
        cmp     #$02
        bcs     LBC0B
        rts

LBC0B:  ldx     path_buf1
        inx
        lda     path_buf2+2
        sta     path_buf1,x
        inc     path_buf1
        ldx     path_buf2
        cpx     #$03
        bcc     LBC2D
        ldx     #$02
LBC21:  lda     path_buf2+1,x
        sta     path_buf2,x
        inx
        cpx     path_buf2
        bne     LBC21
LBC2D:  dec     path_buf2
        MGTK_RELAY_CALL MGTK::MoveTo, name_input_textpos
        MGTK_RELAY_CALL MGTK::SetPortBits, name_input_mapinfo
        addr_call draw_text1, path_buf1
        addr_call draw_text1, path_buf2
        addr_call draw_text1, str_2_spaces
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        rts
.endproc

;;; ============================================================

.proc LBC5E
        lda     path_buf1
        bne     LBC64
        rts

LBC64:  ldx     path_buf2
        cpx     #$01
        beq     LBC79
LBC6B:  lda     path_buf2,x
        sta     split_buf-1,x
        dex
        cpx     #$01
        bne     LBC6B
        ldx     path_buf2
LBC79:  dex
        stx     split_buf
        ldx     path_buf1
LBC80:  lda     path_buf1,x
        sta     path_buf2+1,x
        dex
        bne     LBC80
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
        ldx     split_buf
        beq     LBCB3
LBCA6:  lda     split_buf,x
        sta     path_buf2,y
        dex
        dey
        cpy     path_buf2
        bne     LBCA6
LBCB3:  pla
        sta     path_buf2
        copy    #0, path_buf1
        MGTK_RELAY_CALL MGTK::MoveTo, name_input_textpos
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

.proc LBCC9
        jsr     merge_path_buf1_path_buf2
        MGTK_RELAY_CALL MGTK::MoveTo, name_input_textpos
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

.proc load_aux_from_ptr
        target          := $20

        ;; Backup copy of $20
        COPY_BYTES proc_len+1, target, saved_proc_buf

        ;; Overwrite with proc
        ldx     #proc_len
:       lda     proc,x
        sta     target,x
        dex
        bpl     :-

        ;; Call proc
        jsr     target
        pha

        ;; Restore copy
        COPY_BYTES proc_len+1, saved_proc_buf, target

        pla
        rts

.proc proc
        sta     RAMRDON
        sta     RAMWRTON
        ldy     #0
        lda     ($06),y
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc
        proc_len = .sizeof(proc)

saved_proc_buf:
        .res    20, 0
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
        jsr     set_fill_white
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::current_target_file_rect
        rts

clear_dest_file_rect:
        jsr     set_fill_white
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::current_dest_file_rect
        rts

set_fill_white:
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        rts

reset_grafport3a:

        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

;;; ============================================================

str_preview_fot:
        PASCAL_STRING "Preview/show.image.file"

str_preview_txt:
        PASCAL_STRING "Preview/show.text.file"

;;; ============================================================

        PAD_TO $BF00

.endproc ; desktop_main
        desktop_main_pop_pointers := desktop_main::pop_pointers
        desktop_main_push_pointers := desktop_main::push_pointers

;;; ============================================================
;;; Segment loaded into MAIN $800-$FFF
;;; ============================================================

;;; Appears to be init sequence - machine identification, etc

.proc desktop_800

        .org $800

start:

;;; ============================================================
;;; Detect Machine Type

;;; NOTE: Starts with ROM paged in, exits with LCBANK1 paged in.

.scope machine_type
        ;; See Apple II Miscellaneous #7: Apple II Family Identification

        ;; First, detect IIgs
        copy    #0, iigs_flag
        sec                     ; Follow detection protocol
        jsr     ID_BYTE_FE1F    ; RTS on pre-IIgs
        bcs     :+              ; carry clear = IIgs
        copy    #$80, iigs_flag
:
        ;; Now stash the bytes we need
        copy    ID_BYTE_FBB3, id_FBB3 ; $06 = IIe or later
        copy    ID_BYTE_FBC0, id_FBC0 ; $00 = IIc or later
        copy    ID_BYTE_FBBF, id_FBBF ; IIc ROM version (IIc+ = $05)

        ;; ... and page in LCBANK1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        sta     SET80COL

        ;; Ensure we're on a IIe or later
        lda     id_FBB3
        cmp     #$06            ; Ensure a IIe or later
        beq     :+
        brk                     ; Otherwise (][, ][+, ///), just crash

        ;; State needed by MGTK
:       copy    id_FBB3, startdesktop_params::machine
        copy    id_FBC0, startdesktop_params::subid

        ;; Identify machine type (double-click timer, other flags)
        copy    #0, is_iic_plus_flag

        lda     id_FBC0
        beq     is_iic          ; $FBC0 = $00 -> is IIc or IIc+
        bit     iigs_flag
        bmi     is_iigs

        copy    #$96, machine_type ; IIe
        jmp     end

is_iigs:
        copy    #$FD, machine_type ; IIgs
        jmp     end


is_iic: copy    #$FA, machine_type ; IIc
        lda     id_FBBF            ; ROM version
        cmp     #$05               ; IIc Plus = $05
        bne     :+
        copy    #$80, is_iic_plus_flag
:       jmp     end

iigs_flag:                      ; High bit set if IIgs detected.
        .byte   0

id_FBB3: .byte   0
id_FBC0: .byte   0
id_FBBF: .byte   0

end:
.endscope

;;; ============================================================
;;; Back up DEVLST

.scope
        ;; Make a copy of the original device list
        ldx     DEVCNT
        inx
:       lda     DEVLST-1,x
        sta     devlst_backup,x
        dex
        bpl     :-
        ;; fall through
.endscope

;;; ============================================================
;;; Detach aux-memory RAM Disk

.scope
        ;; Look for /RAM
        ldx     DEVCNT
:       lda     DEVLST,x
        ;; BUG: ProDOS Tech Note #21 says $B3,$B7,$BB or $BF could be /RAM
        cmp     #(1<<7 | 3<<4 | DT_RAM) ; unit_num for /RAM is Slot 3, Drive 2
        beq     found_ram
        dex
        bpl     :-
        bmi     end
found_ram:
        jsr     remove_device
        ;; fall through

end:
.endscope

;;; ============================================================
;;; Initialize MGTK

.scope
        MGTK_RELAY_CALL MGTK::StartDeskTop, startdesktop_params
        jsr     desktop_main::set_mono_mode
        MGTK_RELAY_CALL MGTK::SetMenu, splash_menu
        MGTK_RELAY_CALL MGTK::SetZP1, zp_use_flag0
        MGTK_RELAY_CALL MGTK::SetCursor, watch_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor
        ;; fall through
.endscope

;;; ============================================================
;;; Populate icon_entries table

.scope
        ptr := $6

        jsr     desktop_main::push_pointers
        copy16  #icon_entries, ptr
        ldx     #1
loop:   cpx     #max_icon_count
        bne     :+
        jsr     desktop_main::pop_pointers
        jmp     end
:       txa
        pha
        asl     a
        tax
        copy16  ptr, icon_entry_address_table,x
        pla
        pha
        ldy     #0
        sta     (ptr),y
        iny
        copy    #0, (ptr),y
        lda     ptr
        clc
        adc     #.sizeof(IconEntry)
        sta     ptr
        bcc     :+
        inc     ptr+1
:       pla
        tax
        inx
        jmp     loop
end:
.endscope

;;; ============================================================
;;; Zero the window icon tables

.scope
        sta     RAMWRTON
        lda     #$00
        tax
loop:   sta     WINDOW_ICON_TABLES + $400,x         ; window 8, icon use map
        sta     WINDOW_ICON_TABLES + $300,x         ; window 6, 7
        sta     WINDOW_ICON_TABLES + $200,x         ; window 4, 5
        sta     WINDOW_ICON_TABLES + $100,x         ; window 2, 3
        sta     WINDOW_ICON_TABLES + $000,x         ; window 0, 1 (0=desktop)
        inx
        bne     loop
        sta     RAMWRTOFF
        jmp     create_trash_icon
.endscope

;;; ============================================================

trash_name:  PASCAL_STRING " Trash "

.proc create_trash_icon
        ptr := $6

        copy    #0, cached_window_id
        lda     #1
        sta     cached_window_icon_count
        sta     icon_count
        jsr     AllocateIcon
        sta     trash_icon_num
        sta     cached_window_icon_list
        jsr     desktop_main::icon_entry_lookup
        stax    ptr
        ldy     #IconEntry::win_type
        copy    #icon_entry_type_trash, (ptr),y

        ldy     #IconEntry::iconx
        copy16in #desktop_main::create_volume_icon::trash_iconx, (ptr),y
        ldy     #IconEntry::icony
        copy16in #desktop_main::create_volume_icon::trash_icony, (ptr),y
        ldy     #IconEntry::iconbits
        copy16in #trash_icon, (ptr),y

        iny
        ldx     #0
:       lda     trash_name,x
        sta     (ptr),y
        iny
        inx
        cpx     trash_name
        bne     :-
        lda     trash_name,x
        sta     (ptr),y
        ;; fall through
.endproc

;;; ============================================================

;;; This removes particular devices from the device list.
;;; * SmartPort devices
;;; * Mapped to Drive 2
;;; * Removable
;;; * With only one actual device present (per STATUS call)
;;; ... but why???

.proc filter_devices
        ptr := $06

        lda     DEVCNT
        sta     devcnt
        inc     devcnt
        ldx     #0
:       lda     DEVLST,x
        and     #%10001111      ; drive, not slot, $CnFE status
        cmp     #%10001011      ; drive 2 ... ??? $CnFE = $Bx ?
        beq     :+
        inx
        cpx     devcnt
        bne     :-
        jmp     done

:       lda     DEVLST,x        ; unit_num
        stx     index

        sp_addr := $0A
        jsr     desktop_main::find_smartport_dispatch_address
        bne     done            ; not SmartPort

        ;; Execute SmartPort call
        jsr     smartport_call
        .byte   0               ; $00 = STATUS
        .addr   smartport_params

        bcs     done
        lda     $1F00           ; number of devices
        cmp     #2
        bcs     done

        ;; Single device - remove from DEVLST - Why ???
        ldx     index
:       copy    DEVLST+1,x, DEVLST,x
        inx
        cpx     devcnt
        bne     :-
        dec     DEVCNT
done:   jmp     end

index:  .byte   0

smartport_call:
        jmp     (sp_addr)

smartport_params:
        .byte   $03             ; parameter count
        .byte   0               ; unit number (0 = overall status)
        .addr   $1F00           ; status list pointer
        .byte   0               ; status code (0 = device status)

devcnt: .byte   0

end:
.endproc

;;; ============================================================

.proc load_selector_list
        ptr1 := $6
        ptr2 := $8

        selector_list_io_buf := $1000
        selector_list_data_buf := $1400
        selector_list_data_len := $400

        MGTK_RELAY_CALL MGTK::CheckEvents

        copy    #0, L0A92
        jsr     read_selector_list
        bne     done

        lda     selector_list_data_buf
        clc
        adc     selector_list_data_buf+1
        sta     num_selector_list_items
        lda     #0
        sta     LD344

        lda     selector_list_data_buf
        sta     L0A93
L0A3B:  lda     L0A92
        cmp     L0A93
        beq     done
        jsr     calc_data_addr
        stax    ptr1
        lda     L0A92
        jsr     calc_entry_addr
        stax    ptr2
        ldy     #0
        lda     (ptr1),y
        tay
L0A59:  lda     (ptr1),y
        sta     (ptr2),y
        dey
        bpl     L0A59
        ldy     #15
        lda     (ptr1),y
        sta     (ptr2),y
        lda     L0A92
        jsr     calc_data_str
        stax    ptr1
        lda     L0A92
        jsr     calc_entry_str
        stax    ptr2
        ldy     #0
        lda     (ptr1),y
        tay
L0A7F:  lda     (ptr1),y
        sta     (ptr2),y
        dey
        bpl     L0A7F
        inc     L0A92
        inc     selector_menu
        jmp     L0A3B

done:   jmp     calc_header_item_widths

L0A92:  .byte   0
L0A93:  .byte   0
        .byte   0

;;; --------------------------------------------------

calc_data_addr:
        jsr     desktop_main::a_times_16
        clc
        adc     #<(selector_list_data_buf+2)
        tay
        txa
        adc     #>(selector_list_data_buf+2)
        tax
        tya
        rts

calc_entry_addr:
        jsr     desktop_main::a_times_16
        clc
        adc     #<run_list_entries
        tay
        txa
        adc     #>run_list_entries
        tax
        tya
        rts

calc_entry_str:
        jsr     desktop_main::a_times_64
        clc
        adc     #<run_list_paths
        tay
        txa
        adc     #>run_list_paths
        tax
        tya
        rts

calc_data_str:
        jsr     desktop_main::a_times_64
        clc
        adc     #<(selector_list_data_buf+2 + $180)
        tay
        txa
        adc     #>(selector_list_data_buf+2 + $180)
        tax
        tya
        rts

;;; --------------------------------------------------

        DEFINE_OPEN_PARAMS open_params, str_selector_list, selector_list_io_buf

str_selector_list:
        PASCAL_STRING "Selector.List"

        DEFINE_READ_PARAMS read_params, selector_list_data_buf, selector_list_data_len
        DEFINE_CLOSE_PARAMS close_params

.proc read_selector_list
        MLI_RELAY_CALL OPEN, open_params
        ;;         bne     done
        bne     write_selector_list

        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_RELAY_CALL READ, read_params
        MLI_RELAY_CALL CLOSE, close_params
done:   rts
.endproc

        DEFINE_CREATE_PARAMS create_params, str_selector_list, ACCESS_DEFAULT, $F1
        DEFINE_WRITE_PARAMS write_params, selector_list_data_buf, selector_list_data_len

.proc write_selector_list
        ptr := $06

        ;; Clear buffer
        copy16  #selector_list_data_buf, ptr
        ldx     #>selector_list_data_len ; number of pages
        lda     #0
ploop:  ldy     #0
:       sta     (ptr),y
        dey
        bne     :-
        dex
        bne     ploop

        ;; Write out file
        MLI_RELAY_CALL CREATE, create_params
        bne     done
        MLI_RELAY_CALL OPEN, open_params
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_RELAY_CALL WRITE, write_params ; two blocks of $400
        MLI_RELAY_CALL WRITE, write_params
        MLI_RELAY_CALL CLOSE, close_params

done:   rts
.endproc

.endproc

;;; ============================================================

.proc calc_header_item_widths
        ;; Enough space for "123456"
        addr_call desktop_main::measure_text1, str_from_int
        stax    dx

        ;; Width of "123456 Items"
        addr_call desktop_main::measure_text1, str_items
        addax   dx, width_items_label

        ;; Width of "123456K in disk"
        addr_call desktop_main::measure_text1, str_k_in_disk
        addax   dx, width_k_in_disk_label

        ;; Width of "123456K available"
        addr_call desktop_main::measure_text1, str_k_available
        addax   dx, width_k_available_label

        add16   width_k_in_disk_label, width_k_available_label, width_right_labels
        add16   width_items_label, #5, width_items_label_padded
        add16   width_items_label_padded, width_k_in_disk_label, width_left_labels
        add16   width_left_labels, #3, width_left_labels
        jmp     end

dx:     .word   0

end:
.endproc

;;; ============================================================
;;; Enumerate Desk Accessories

.scope
        MGTK_RELAY_CALL MGTK::CheckEvents

        read_dir_buffer := $1400

        ;; Does the directory exist?
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        jmp     end

:       lda     get_file_info_type
        cmp     #FT_DIRECTORY
        beq     open_dir
        jmp     end

open_dir:
        MLI_RELAY_CALL OPEN, open_params
        lda     open_ref_num
        sta     read_ref_num
        sta     close_ref_num
        MLI_RELAY_CALL READ, read_params

        lda     #0
        sta     entry_num
        sta     desk_acc_num

        lda     #1              ; First block has header instead of entry
        sta     entry_in_block

        lda     read_dir_buffer + SubdirectoryHeader::file_count
        and     #$7F
        sta     file_count

        lda     #2
        sta     apple_menu      ; "About..." and separator

        lda     read_dir_buffer + SubdirectoryHeader::entries_per_block
        sta     entries_per_block
        lda     read_dir_buffer + SubdirectoryHeader::entry_length
        sta     entry_length

        dir_ptr := $06
        da_ptr := $08

        copy16  #read_dir_buffer + .sizeof(SubdirectoryHeader), dir_ptr

process_block:
        ;; TODO: Adjust case
        addr_call_indirect desktop_main::adjust_fileentry_case, dir_ptr

        ldy     #FileEntry::storage_type_name_length
        lda     (dir_ptr),y
        and     #NAME_LENGTH_MASK
        bne     :+
        jmp     next_entry

:       inc     entry_num
        ldy     #FileEntry::file_type
        lda     (dir_ptr),y
        cmp     #DA_FILE_TYPE
        bne     next_entry
        ldy     #FileEntry::aux_type+1 ; high bit set = skip
        lda     (dir_ptr),y
        bmi     next_entry

        ;; Compute slot in DA name table
is_da:  inc     desk_acc_num
        copy16  #desk_acc_names, da_ptr
        lda     #0
        sta     ptr_calc_hi
        lda     apple_menu      ; num menu items
        sec
        sbc     #2              ; ignore "About..." and separator
        asl     a
        rol     ptr_calc_hi
        asl     a
        rol     ptr_calc_hi
        asl     a
        rol     ptr_calc_hi
        asl     a
        rol     ptr_calc_hi
        clc
        adc     da_ptr
        sta     da_ptr
        lda     ptr_calc_hi
        adc     da_ptr+1
        sta     da_ptr+1

        ;; Copy name
        ldy     #FileEntry::storage_type_name_length
        lda     (dir_ptr),y
        and     #NAME_LENGTH_MASK
        sta     (da_ptr),y
        tay
:       lda     (dir_ptr),y
        sta     (da_ptr),y
        dey
        bne     :-

        ;; Convert periods to spaces
        lda     (da_ptr),y
        tay
loop:   lda     (da_ptr),y
        cmp     #'.'
        bne     :+
        lda     #' '
        sta     (da_ptr),y
:       dey

        bne     loop
        inc     apple_menu      ; number of menu items

next_entry:
        ;; Room for more DAs?
        lda     desk_acc_num
        cmp     #max_desk_acc_count
        bcc     :+
        jmp     close_dir

        ;; Any more entries in dir?
:       lda     entry_num
        cmp     file_count
        bne     :+
        jmp     close_dir

        ;; Any more entries in block?
:       inc     entry_in_block
        lda     entry_in_block
        cmp     entries_per_block
        bne     :+
        MLI_RELAY_CALL READ, read_params
        copy16  #read_dir_buffer + 4, dir_ptr

        lda     #0
        sta     entry_in_block
        jmp     process_block

:       add16_8 dir_ptr, entry_length, dir_ptr
        jmp     process_block

close_dir:
        MLI_RELAY_CALL CLOSE, close_params
        jmp     end

        DEFINE_OPEN_PARAMS open_params, str_desk_acc, $1000
        open_ref_num := open_params::ref_num

        DEFINE_READ_PARAMS read_params, read_dir_buffer, BLOCK_SIZE
        read_ref_num := read_params::ref_num

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, str_desk_acc
        get_file_info_type := get_file_info_params::file_type

        .byte   0

        DEFINE_CLOSE_PARAMS close_params
        close_ref_num := close_params::ref_num

str_desk_acc:
        PASCAL_STRING "Desk.acc"

file_count:     .byte   0
entry_num:      .byte   0
desk_acc_num:   .byte   0
entry_length:   .byte   0
entries_per_block:      .byte   0
entry_in_block: .byte   0
ptr_calc_hi:    .byte   0

end:
.endscope

;;; ============================================================
;;; Populate volume icons and device names

;;; TODO: Dedupe with cmd_check_drives

.scope
        devname_ptr := $08

        ldy     #0
        sty     desktop_main::pending_alert

        ;; Enumerate DEVLST in reverse order (most important volumes first)
        lda     DEVCNT
        sta     device_index

process_volume:
        lda     device_index
        asl     a
        tay
        copy16  device_name_table,y, devname_ptr
        ldy     device_index
        lda     DEVLST,y

        pha                     ; save all registers
        txa
        pha
        tya
        pha

        inc     cached_window_icon_count
        inc     icon_count
        lda     DEVLST,y
        ldx     cached_window_icon_count
        jsr     desktop_main::create_volume_icon ; A = unit number, X = icon index, Y = device number
        sta     cvi_result
        MGTK_RELAY_CALL MGTK::CheckEvents

        pla                     ; restore all registers
        tay
        pla
        tax
        pla

        pha
        lda     cvi_result
        cmp     #ERR_DEVICE_NOT_CONNECTED
        bne     :+

        ldy     device_index    ; BUG? Is there a missing pla instruction in this path?
        lda     DEVLST,y
        and     #$0F
        beq     select_template
        ldx     device_index
        jsr     remove_device
        jmp     next

:       cmp     #ERR_DUPLICATE_VOLUME
        bne     select_template
        lda     #ERR_DUPLICATE_VOL_NAME
        sta     desktop_main::pending_alert

        ;; This section populates device_name_table -
        ;; it determines which device type string to use, and
        ;; fills in slot and drive as appropriate.
        ;;
        ;; This is for a "Check" menu present in MouseDesk 1.1
        ;; but which was removed in MouseDesk 2.0, which allowed
        ;; refreshing individual windows. It is also used in the
        ;; Format/Erase disk dialog.

.proc select_template
        pla                     ; unit number into A
        pha

        jsr     desktop_main::get_device_type
        sta     device_type

        ;; Copy template to device name
        asl                     ; * 2
        tax
        src := $06
        copy16  device_template_table,x, src

        ldy     #0
        lda     (src),y
        tay
:       lda     (src),y
        sta     (devname_ptr),y
        dey
        bpl     :-

        ;; Insert Slot #
        pla                     ; unit number into A
        pha

        and     #%01110000      ; slot (from DSSSxxxx)
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #'0'

        ldx     device_type
        ldy     device_template_slot_offset_table,x
        sta     (devname_ptr),y

        ;; Insert Drive #
        pla                     ; unit number into A
        pha

        rol     a               ; set carry to drive - 1
        lda     #0              ; 0 + 1 + carry...
        adc     #1              ; now 1 or 2
        ora     #'0'            ; convert to '1' or '2'

        ldx     device_type
        ldy     device_template_drive_offset_table,x
        beq     :+              ; 0 = no drive # for this type
        sta     (devname_ptr),y
:
.endproc

done_drive_num:
        pla
next:   dec     device_index
        lda     device_index

        bpl     :+
        bmi     populate_startup_menu
:       jmp     process_volume  ; next!

device_type:
        .byte   0
device_index:
        .byte   0
cvi_result:
        .byte   0
.endscope

;;; ============================================================

        ;; Remove device num in X from devices list
.proc remove_device
        dex
:       inx
        copy    DEVLST+1,x, DEVLST,x
        lda     device_to_icon_map+1,x
        sta     device_to_icon_map,x
        cpx     DEVCNT
        bne     :-
        dec     DEVCNT
        rts
.endproc

;;; ============================================================

.proc populate_startup_menu
        slot_ptr := $06         ; pointed at $Cn00
        table_ptr := $08        ; points into slot_string_table

        lda     #7
        sta     slot
        lda     #0
        sta     slot_ptr
        tax                     ; X = menu entry

        ;; Identify ProDOS device in slot by ID bytes
loop:   lda     slot
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

        ;; It is a ProDOS device - prepare menu item.
        txa                     ; pointer to nth sNN string
        pha
        asl     a
        tax
        copy16  slot_string_table,x, table_ptr

        ldy     startup_menu_item_1 ; replace second-from-last char
        dey
        lda     slot
        ora     #'0'
        sta     (table_ptr),y

        pla
        tax
        inx

next:   dec     slot
        bne     loop

        ;; Set number of menu items.
        stx     startup_menu
        jmp     final_setup

slot:   .byte   0

slot_string_table:
        .addr   startup_menu_item_1
        .addr   startup_menu_item_2
        .addr   startup_menu_item_3
        .addr   startup_menu_item_4
        .addr   startup_menu_item_5
        .addr   startup_menu_item_6
        .addr   startup_menu_item_7

.endproc

;;; ============================================================

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params2, desktop_main::sys_start_path
        .byte   0

str_system_start:  PASCAL_STRING "System/Start"

.proc final_setup
        lda     #0
        sta     desktop_main::sys_start_flag
        jsr     desktop_main::get_copied_to_ramcard_flag
        cmp     #$80
        beq     L0EFE
        bne     config_toolkit
        dec     desktop_main::sys_start_path
        jmp     L0F05

L0EFE:  addr_call desktop_main::copy_desktop_orig_prefix, desktop_main::sys_start_path
L0F05:  ldx     desktop_main::sys_start_path

        ;; Find last /
floop:  lda     desktop_main::sys_start_path,x
        cmp     #'/'
        beq     :+
        dex
        bne     floop

        ;; Replace last path segment with "System/Start"
:       ldy     #0
cloop:  inx
        iny
        lda     str_system_start,y
        sta     desktop_main::sys_start_path,x
        cpy     str_system_start
        bne     cloop
        stx     desktop_main::sys_start_path

        ;; Does it point at anything? If so, set flag.
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params2
        bne     config_toolkit
        copy    #$80, desktop_main::sys_start_flag

        ;; Final MGTK configuration
config_toolkit:
        MGTK_RELAY_CALL MGTK::CheckEvents
        MGTK_RELAY_CALL MGTK::SetMenu, desktop_aux::desktop_menu
        MGTK_RELAY_CALL MGTK::SetCursor, pointer_cursor
        lda     #0
        sta     active_window_id
        jsr     desktop_main::update_window_menu_items
        jsr     desktop_main::disable_eject_menu_item
        jsr     desktop_main::disable_file_menu_items
        jmp     MGTK::MLI
.endproc

        PAD_TO $1000

.endproc ; desktop_800
