;;; ============================================================
;;; DeskTop - Main Memory Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into MAIN $4000-$BEFF
;;; ============================================================

.proc desktop_main

L0020           := $0020
L0800           := $0800

.scope format_erase_overlay
L0CB8           := $0CB8
L0CD7           := $0CD7
L0CF9           := $0CF9
L0D14           := $0D14
.endscope

path_buf_main   := $1FC0

        dynamic_routine_800  := $0800
        dynamic_routine_5000 := $5000
        dynamic_routine_7000 := $7000
        dynamic_routine_9000 := $9000

        dynamic_routine_disk_copy    := 0
        dynamic_routine_format_erase := 1
        dynamic_routine_selector1    := 2
        dynamic_routine_common       := 3
        dynamic_routine_file_copy    := 4
        dynamic_routine_file_delete  := 5
        dynamic_routine_selector2    := 6
        dynamic_routine_restore5000  := 7
        dynamic_routine_restore9000  := 8


        .org $4000

        ;; Jump table
        ;; Entries marked with * are used by DAs
        ;; "Exported" by desktop.inc

JT_MAIN_LOOP:           jmp     enter_main_loop
JT_MGTK_RELAY:          jmp     MGTK_RELAY
JT_SIZE_STRING:         jmp     compose_blocks_string
JT_DATE_STRING:         jmp     compose_date_string
JT_SELECT_WINDOW:       jmp     select_and_refresh_window
JT_AUXLOAD:             jmp     DESKTOP_AUXLOAD
JT_EJECT:               jmp     cmd_eject
JT_REDRAW_ALL:          jmp     redraw_windows          ; *
JT_DESKTOP_RELAY:       jmp     DESKTOP_RELAY
JT_LOAD_OVL:            jmp     load_dynamic_routine
JT_CLEAR_SELECTION:     jmp     clear_selection         ; *
JT_MLI_RELAY:           jmp     MLI_RELAY               ; *
JT_COPY_TO_BUF:         jmp     DESKTOP_COPY_TO_BUF
JT_COPY_FROM_BUF:       jmp     DESKTOP_COPY_FROM_BUF
JT_NOOP:                jmp     cmd_noop
JT_FILE_TYPE_STRING:    jmp     compose_file_type_string
JT_SHOW_ALERT0:         jmp     DESKTOP_SHOW_ALERT0
JT_SHOW_ALERT:          jmp     DESKTOP_SHOW_ALERT
JT_LAUNCH_FILE:         jmp     launch_file
JT_CUR_POINTER:         jmp     set_pointer_cursor      ; *
JT_CUR_WATCH:           jmp     set_watch_cursor
JT_RESTORE_SEF:         jmp     restore_dynamic_routine

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
        jsr     DESKTOP_COPY_FROM_BUF

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
        jsr     DESKTOP_SHOW_ALERT0

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
        stx     LE256
        sta     menu_click_params::item_num
        jsr     L59A0
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

L412B:  copy    #0, cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        lda     L40F0
        sta     active_window_id
        beq     L4143
        bit     running_da_flag
        bmi     L4143
        jsr     L4244
L4143:  bit     L40F1
        bpl     L4151
        DESKTOP_RELAY_CALL DT_REDRAW_ICONS
L4151:  rts

.endproc
        main_loop := enter_main_loop::main_loop
        redraw_windows := enter_main_loop::redraw_windows

;;; ============================================================


L4152:  .byte   0


.proc update_window
        lda     event_window_id
        cmp     #9              ; only handle windows 1...8
        bcc     L415B
        rts

L415B:  sta     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        copy    #$80, L4152
        copy    cached_window_id, getwinport_params2::window_id
        jsr     get_port2
        jsr     draw_window_header
        lda     active_window_id
        jsr     copy_window_portbits
        jsr     DESKTOP_ASSIGN_STATE
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #$16
        sub16in ($06),y, grafport2::viewloc::ycoord, L4242
        cmp16   L4242, #15
        bpl     L41CB
        jsr     offset_grafport2

        ldx     #$0B
        ldy     #$1F
        copy    grafport2,x, ($06),y
        dey
        dex
        copy    grafport2,x, ($06),y

        ldx     #$03
        ldy     #$17
        copy    grafport2,x, ($06),y
        dey
        dex
        copy    grafport2,x, ($06),y

L41CB:  ldx     cached_window_id
        dex
        lda     win_view_by_table,x
        bpl     L41E2
        jsr     L6C19
        copy    #$00, L4152
        lda     active_window_id
        jmp     assign_window_portbits

L41E2:  copy    cached_window_id, getwinport_params2::window_id
        jsr     get_set_port2
        jsr     cached_icons_window_to_screen

        COPY_BLOCK grafport2::cliprect, rect_E230

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

L4227:  copy    #$00, L4152
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

.proc L4244
        lda     selected_icon_count
        bne     :+
bail:   rts

:       copy    #0, L42C3

        lda     selected_window_index
        beq     L42A5
        cmp     active_window_id
        bne     bail

        copy    active_window_id, getwinport_params2::window_id
        jsr     get_port2
        jsr     offset_grafport2_and_set

        COPY_BLOCK grafport2::cliprect, rect_E230

L4270:  lda     L42C3
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
        inc     L42C3
        jmp     L4270

done:   jmp     reset_grafport3

L42A5:  lda     L42C3
        cmp     selected_icon_count
        beq     done
        tax
        copy    selected_icon_list,x, icon_param
        DESKTOP_RELAY_CALL DT_REDRAW_ICON, icon_param
        inc     L42C3
        jmp     L42A5

L42C3:  .byte   0
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
        .addr   cmd_eject
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
        .addr   cmd_noop        ; --------
        .addr   cmd_format_disk
        .addr   cmd_erase_disk
        .addr   cmd_disk_copy
        .addr   cmd_noop        ; --------
        .addr   cmd_lock
        .addr   cmd_unlock
        .addr   cmd_noop        ; --------
        .addr   cmd_get_info
        .addr   cmd_get_size
        .addr   cmd_noop        ; --------
        .addr   cmd_rename_icon

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

        PAD_TO $4359

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
        stx     LE256
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
        stx     LE256
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
        jmp     handle_icon_click

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
        copy    LEC26,x, icon_param
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
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        jsr     L6C19
        copy    #0, cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
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

        rts                     ; ???

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
        inx
        sta     removable_device_table,x
        bne     next            ; always

        rts                     ; remove ???
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

        .byte   $00

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

        ;; Compute smart port control unit number
        lda     unit_number
        pha
        rol     a
        pla
        php
        and     #$20
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        plp
        adc     #1
        sta     status_unit_num

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

status_buffer:  .res    16, 0
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
        jsr     DESKTOP_SHOW_ALERT0
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

        lda     #$FA
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
        addr_call upcase_string, $280
        addr_call upcase_string, path
        jsr     restore_device_list
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

no_bs:  lda     #$FE            ; "BASIC.SYSTEM not found"

show_alert_and_fail:
        jsr     DESKTOP_SHOW_ALERT0
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

prefix_buffer:  .res    30, 0

.proc upcase_string
        ptr := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
loop:   lda     (ptr),y
        cmp     #'a'
        bcc     :+
        cmp     #'z'+1
        bcs     :+
        and     #CASE_MASK
        sta     (ptr),y
:       dey
        bne     loop
        rts
.endproc

.endproc
        prefix_buffer := launch_file::prefix_buffer

;;; ============================================================

L485D:  .word   $E000
L485F:  .word   $D000

sys_start_flag:  .byte   $00
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
:       lda     devlst_backup,x
        sta     DEVLST-1,x
        dex
        bpl     :-
        rts
.endproc

.proc show_warning_dialog_num
        sta     warning_dialog_num
        yax_call launch_dialog, index_warning_dialog, warning_dialog_num
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

        lda     result
        bpl     done
        jsr     L4AAD
        jsr     L4A77
        jsr     get_copied_to_ramcard_flag
        bpl     L497A
        jsr     L8F24           ; Condition for this ???
        bmi     done
        jsr     L4968

done:   jsr     set_pointer_cursor
        jsr     redraw_windows_and_desktop
        rts

L4968:  jsr     L4AAD
        ldx     $840
L496E:  lda     $840,x
        sta     buf_win_path,x
        dex
        bpl     L496E
        jmp     L4A17

L497A:  jsr     L4AAD
        ldx     L0800
L4980:  lda     L0800,x
        sta     buf_win_path,x
        dex
        bpl     L4980
        jsr     L4A17
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
        jsr     L8F24
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
L4A17:  ldy     buf_win_path
L4A1A:  lda     buf_win_path,y
        cmp     #'/'
        beq     L4A24
        dey
        bpl     L4A1A
L4A24:  dey
        sty     L4A46
        ldx     #$00
        iny
L4A2B:  iny
        inx
        lda     buf_win_path,y
        sta     buf_filename2,x
        cpy     buf_win_path
        bne     L4A2B
        stx     buf_filename2
        lda     L4A46
        sta     buf_win_path
        lda     #$00
        jmp     launch_file

L4A46:  .byte   0

;;; --------------------------------------------------

        ;; Copy entry path to $800
L4A47:  pha
        jsr     a_times_64
        addax   #run_list_paths, $06
        ldy     #0
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     L0800,y
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

        ;; Strip segment off path at $800
L4A77:  ldy     $800
:       lda     $800,y
        cmp     #'/'
        beq     :+
        dey
        bne     :-

:       dey
        sty     L0800

        ;; Strip segment off path at $840
        ldy     $840
L4A8B:  lda     $840,y
        cmp     #'/'
        beq     L4A95
        dey
        bne     L4A8B
L4A95:  dey
        sty     $840

        ;; Return addresses in $6 and $8
        copy16  #$800, $06
        copy16  #$840, $08

        jsr     copy_paths_and_split_name
        rts

;;; --------------------------------------------------

L4AAD:  ldy     buf_win_path
L4AB0:  lda     buf_win_path,y
        sta     L0800,y
        dey
        bpl     L4AB0
        addr_call copy_ramcard_prefix, $840
        ldy     L0800
L4AC3:  lda     L0800,y
        cmp     #'/'
        beq     L4ACD
        dey
        bne     L4AC3
L4ACD:  dey
L4ACE:  lda     L0800,y
        cmp     #'/'
        beq     L4AD8
        dey
        bne     L4ACE
L4AD8:  dey
        ldx     $840
L4ADC:  iny
        inx
        lda     L0800,y
        sta     $840,x
        cpy     L0800
        bne     L4ADC
        rts

.proc check_downloaded_path
        jsr     compose_downloaded_entry_path
        stax    get_file_info_params3::pathname
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params3
        rts
.endproc

.endproc
        cmd_selector_item := cmd_selector_item_impl::start

        L4A17 := cmd_selector_item_impl::L4A17
        L4A77 := cmd_selector_item_impl::L4A77
        L4AAD := cmd_selector_item_impl::L4AAD

;;; ============================================================
;;; Get "coped to RAM card" flag from Main LC Bank 2.

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
        yax_call launch_dialog, index_about_dialog, $0000
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================

.proc cmd_deskacc_impl
        ptr := $6

zp_use_flag1:
        .byte   $80

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
        adc     prefix_length
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

        ;; Load the DA
        jsr     open
        bmi     done
        lda     open_ref_num
        sta     read_ref_num
        sta     close_ref_num
        jsr     read
        jsr     close
        lda     #$80
        sta     running_da_flag

        ;; Invoke it
        jsr     set_pointer_cursor
        jsr     reset_grafport3
        MGTK_RELAY_CALL MGTK::SetZP1, zp_use_flag0
        MGTK_RELAY_CALL MGTK::SetZP1, zp_use_flag1
        jsr     DA_LOAD_ADDRESS
        MGTK_RELAY_CALL MGTK::SetZP1, zp_use_flag0
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
        jsr     show_warning_dialog_num
        beq     open            ; ok, so try again
        return  #$FF            ; cancel, so fail

read:   yxa_jump MLI_RELAY, READ, read_params

close:  yxa_jump MLI_RELAY, CLOSE, close_params

unused: .byte   0               ; ???

        DEFINE_OPEN_PARAMS open_params, str_desk_acc, DA_IO_BUFFER
        open_ref_num := open_params::ref_num

        DEFINE_READ_PARAMS read_params, DA_LOAD_ADDRESS, DA_MAX_SIZE
        read_ref_num := read_params::ref_num

        DEFINE_CLOSE_PARAMS close_params
        close_ref_num := close_params::ref_num

        .define prefix "Desk.acc/"

prefix_length:
        .byte   .strlen(prefix)

str_desk_acc:
        PASCAL_STRING prefix, .strlen(prefix) + 15

.endproc
        cmd_deskacc := cmd_deskacc_impl::start

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
        bpl     L4CCD
        jmp     L4CD6

;;; --------------------------------------------------

L4CCD:  jsr     copy_paths_and_split_name
        jsr     redraw_windows_and_desktop
        jsr     jt_copy_file
L4CD6:  pha
        jsr     set_pointer_cursor
        pla
        bpl     :+
        jmp     redraw_windows_and_desktop

:       addr_call L6FAF, path_buf4
        beq     :+
        pha
        jsr     L6F0D
        pla
        jmp     select_and_refresh_window

:       ldy     #1
L4CF3:  iny
        lda     path_buf4,y
        cmp     #'/'
        beq     :+
        cpy     path_buf4
        bne     L4CF3
        iny
:       dey
        sty     path_buf4
        addr_call L6FB7, path_buf4
        ldax    #path_buf4
        ldy     path_buf4
        jsr     L6F4B
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
        addr_call L6FAF, path_buf3
        beq     L4DC2
        pha
        jsr     L6F0D
        pla
        jmp     select_and_refresh_window

L4DC2:  ldy     #1
:       iny
        lda     path_buf3,y
        cmp     #'/'
        beq     :+
        cpy     path_buf3
        bne     :-
        iny
:       dey
        sty     path_buf3
        addr_call L6FB7, path_buf3
        ldax    #path_buf3
        ldy     path_buf3
        jsr     L6F4B
        jmp     redraw_windows_and_desktop
.endproc

;;; ============================================================

.proc cmd_open
        ldx     #$00
L4DEC:  cpx     selected_icon_count
        bne     L4DF2
        rts

L4DF2:  txa
        pha
        lda     selected_icon_list,x
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_type_mask
        bne     L4E10
        ldy     #$00
        lda     ($06),y
        jsr     open_folder_or_volume_icon
        jmp     L4E14

L4E10:  cmp     #$40
        bcc     L4E1A
L4E14:  pla
        tax
        inx
        jmp     L4DEC

L4E1A:  sta     L4E71
        lda     selected_icon_count
        cmp     #$02
        bcs     L4E14
        pla
        lda     active_window_id
        jsr     window_address_lookup
        stax    $06
        ldy     #$00
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
.endproc

;;; ============================================================

.proc cmd_close
        lda     active_window_id
        bne     L4E78
        rts

L4E78:  jsr     clear_selection
        dec     LEC2E
        lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
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
        jsr     DESKTOP_FREE_ICON
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
        jsr     DESKTOP_COPY_FROM_BUF
        lda     #$00
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        MGTK_RELAY_CALL MGTK::CloseWindow, active_window_id
        ldx     active_window_id
        dex
        lda     LEC26,x
        sta     icon_param
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #(~icon_entry_open_mask)&$FF ; clear open_flag
        sta     ($06),y
        and     #icon_entry_winid_mask
        sta     selected_window_index
        jsr     zero_grafport5_coords
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
        jsr     reset_grafport3
        lda     #$01
        sta     selected_icon_count
        lda     icon_param
        sta     selected_icon_list
        ldx     active_window_id
        dex
        lda     LEC26,x
        jsr     L7345
        ldx     active_window_id
        dex
        lda     #$00
        sta     LEC26,x
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
L4F68:  .word   0
.endproc

        ;; access = destroy/rename/write/read
        DEFINE_CREATE_PARAMS create_params, path_buffer, ACCESS_DEFAULT, FT_DIRECTORY,, ST_LINKED_DIRECTORY

path_buffer:
        .res    65, 0              ; buffer is used elsewhere too

start:  copy    active_window_id, new_folder_dialog_params::phase
        yax_call launch_dialog, index_new_folder_dialog, new_folder_dialog_params

L4FC6:  lda     active_window_id
        beq     L4FD4
        jsr     window_address_lookup
        stax    new_folder_dialog_params::L4F68
L4FD4:  copy    #$80, new_folder_dialog_params::phase
        yax_call launch_dialog, index_new_folder_dialog, new_folder_dialog_params
        beq     :+
        jmp     done            ; Cancelled
:       stx     ptr+1
        stx     L504F
        sty     ptr
        sty     L504E

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
        jsr     DESKTOP_SHOW_ALERT0
        copy16  L504E, new_folder_dialog_params::L4F68
        jmp     L4FC6

        rts                     ; ???

success:
        copy    #$40, new_folder_dialog_params::phase
        yax_call launch_dialog, index_new_folder_dialog, new_folder_dialog_params
        addr_call find_last_path_segment, path_buffer
        sty     path_buffer
        addr_call L6FAF, path_buffer
        beq     done
        jsr     select_and_refresh_window

done:   jmp     redraw_windows_and_desktop

L504E:  .byte   0
L504F:  .byte   0
.endproc
        cmd_new_folder := cmd_new_folder_impl::start
        path_buffer := cmd_new_folder_impl::path_buffer ; ???

;;; ============================================================

.proc cmd_eject
        lda     selected_window_index
        beq     L5056
L5055:  rts

L5056:  lda     selected_icon_count
        beq     L5055
        cmp     #$01
        bne     L5067
        lda     selected_icon_list
        cmp     trash_icon_num
        beq     L5055
L5067:  lda     #$00
        tax
        tay
L506B:  lda     selected_icon_list,y
        cmp     trash_icon_num
        beq     L5077
        sta     $1800,x
        inx
L5077:  iny
        cpy     selected_icon_count
        bne     L506B
        dex
        stx     L5098
        jsr     jt_eject
L5084:  ldx     L5098
        lda     $1800,x
        sta     L533F
        jsr     L59A8
        dec     L5098
        bpl     L5084
        jmp     redraw_windows_and_desktop
L5098:  .byte   $00

.endproc

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

        ;; Restore machine to text state
        sta     ALTZPOFF
        jsr     exit_dhr_mode

        ;; S3D2 /RAM driver still in place?
        RAMSLOT := DEVADR + $10 + 3*2 ; Slot 3, Drive 2
        cmp16   RAMSLOT, NODEV
        beq     quit            ; No, so give up
        jsr     reinstall_ram

quit:   jmp     quit_code_addr

fail:   jsr     DESKTOP_SHOW_ALERT
        rts

.endproc
        cmd_quit := cmd_quit_impl::start

        PAD_TO $50F9            ; Maintain previous addresses

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
:       lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        ldx     #$00
        txa
:       cpx     cached_window_icon_count
        beq     :+
        sta     cached_window_icon_list,x
        inx
        jmp     :-

:       sta     cached_window_icon_count
        lda     #$00
        ldx     active_window_id
        dex
        sta     win_view_by_table,x
        jsr     update_view_menu_check
        lda     active_window_id
        sta     getwinport_params2::window_id
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
        lda     active_window_id
        sta     getwinport_params2::window_id
        jsr     get_set_port2
        jsr     cached_icons_window_to_screen
        lda     #$00
        sta     L51EF
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
        jsr     DESKTOP_COPY_FROM_BUF
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
L51E3:  lda     #$00
        sta     cached_window_id
        jmp     DESKTOP_COPY_TO_BUF

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
        lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        jsr     sort_records
        jsr     DESKTOP_COPY_FROM_BUF
        lda     active_window_id
        sta     getwinport_params2::window_id
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

        lda     #$80
        sta     L4152
        jsr     reset_grafport3
        jsr     L6C19
        jsr     update_scrollbars
        lda     #$00
        sta     L4152
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
        lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        lda     icon_count
        sec
        sbc     cached_window_icon_count
        sta     icon_count
        ldx     #0
loop:   cpx     cached_window_icon_count
        beq     done
        lda     cached_window_icon_list,x
        jsr     DESKTOP_FREE_ICON
        lda     #$00
        sta     cached_window_icon_list,x
        inx
        jmp     loop

done:   jsr     DESKTOP_COPY_FROM_BUF
        lda     #$00
        sta     cached_window_id
        jmp     DESKTOP_COPY_TO_BUF
.endproc

;;; ============================================================

L533F:  .byte   0

;;; ============================================================

.proc cmd_format_disk
        lda     #dynamic_routine_format_erase
        jsr     load_dynamic_routine
        bmi     fail

        lda     #$04
        jsr     dynamic_routine_800
        bne     :+
        stx     L533F
        jsr     redraw_windows_and_desktop
        jsr     L59A4
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

        stx     L533F
        jsr     redraw_windows_and_desktop
        jsr     L59A4
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
        beq     L5398
        rts

L5398:  lda     selected_window_index
        bne     L53B5
        ldx     #$00
        ldy     #$00
L53A1:  lda     selected_icon_list,x
        cmp     #$01
        beq     L53AC
        sta     L5428,y
        iny
L53AC:  inx
        cpx     selected_icon_list
        bne     L53A1
        sty     L5427
L53B5:  lda     #$FF
        sta     L5426
L53BA:  inc     L5426
        lda     L5426
        cmp     selected_icon_count
        bne     L53D0
        lda     selected_window_index
        bne     L53CD
        jmp     L540E
L53CD:  jmp     select_and_refresh_window

L53D0:  tax
        lda     selected_icon_list,x
        jsr     L5431
        bmi     L53BA
        jsr     window_address_lookup
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
        lda     $06
        jsr     L6FB7
        lda     L704B
        beq     L53BA
L53EF:  dec     L704B
        ldx     L704B
        lda     L704C,x
        cmp     active_window_id
        beq     L5403
        sta     findwindow_window_id
        jsr     handle_inactive_window_click
L5403:  jsr     close_window
        lda     L704B
        bne     L53EF
        jmp     L53BA

L540E:  ldx     L5427
L5411:  lda     L5428,x
        sta     L533F
        jsr     L59A8
        ldx     L5427
        dec     L5427
        dex
        bpl     L5411
        jmp     redraw_windows_and_desktop

L5426:  .byte   0
L5427:  .byte   0
L5428:  .res    9, 0

L5431:  ldx     #7
L5433:  cmp     LEC26,x
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
        lda     #$00
        sta     $1800
        lda     active_window_id
        bne     L545A
        jmp     L54C5

L545A:  tax
        dex
        lda     win_view_by_table,x
        bpl     L5464
        jmp     L54C5

L5464:  lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        lda     active_window_id
        jsr     window_lookup
        stax    $06
        ldy     #MGTK::Winfo::port+MGTK::GrafPort::maprect
L5479:  lda     ($06),y
        sta     rect_E230-(MGTK::Winfo::port+MGTK::GrafPort::maprect),y
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

L54BD:  lda     #$00
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
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
        lda     #$00
        sta     L544A
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

L5579:  lda     #$00
        sta     L544A
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

L5676:  lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        lda     cached_window_icon_count
        bne     L5687
        jmp     L56F0

L5687:  ldx     cached_window_icon_count
        dex
L568B:  lda     cached_window_icon_list,x
        sta     selected_icon_list,x
        dex
        bpl     L568B
        lda     cached_window_icon_count
        sta     selected_icon_count
        lda     active_window_id
        sta     selected_window_index
        lda     selected_window_index
        sta     LE22C
        beq     L56AB
        jsr     L56F9
L56AB:  lda     selected_icon_count
        sta     L56F8
        dec     L56F8
L56B4:  ldx     L56F8
        lda     selected_icon_list,x
        sta     LE22B
        jsr     icon_entry_lookup
        stax    $06
        lda     LE22C
        beq     L56CF
        lda     LE22B
        jsr     icon_window_to_screen
L56CF:  DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, LE22B
        lda     LE22C
        beq     L56E3
        lda     LE22B
        jsr     icon_screen_to_window
L56E3:  dec     L56F8
        bpl     L56B4
        lda     selected_window_index
        beq     L56F0
        jsr     reset_grafport3
L56F0:  lda     #$00
        sta     cached_window_id
        jmp     DESKTOP_COPY_TO_BUF

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

L5708:  sta     L0800
        ldy     #$01
        ldx     #$00
L570F:  lda     LEC26,x
        beq     L5720
        inx
        cpx     active_window_id
        beq     L5721
        txa
        dex
        sta     L0800,y
        iny
L5720:  inx
L5721:  cpx     #$08
        bne     L570F
        sty     L578D
        cpy     #$01
        bne     L572D
        rts

L572D:  lda     #$00
        sta     L578C
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
        lda     L0800,x
        sta     findwindow_window_id
        jsr     handle_inactive_window_click
        jmp     L5732

L5772:  ldx     L578C
        dex
        bpl     L577C
        ldx     L578D
        dex
L577C:  stx     L578C
        lda     L0800,x
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

done:   lda     #$00
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        rts

        ;; Horizontal ok?
:       bit     L585D
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
        bit     L585E
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
        lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        sta     L5B1B
        jsr     L58C3
        stax    L585F
        sty     L585D
        jsr     L58E2
        stax    L5861
        sty     L585E
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

L585D:  .byte   0               ; can scroll horiz?
L585E:  .byte   0               ; can scroll vert?
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
        lda     #0
        sta     pending_alert

        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
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
        lda     #$00
        sta     cached_window_icon_list,x
        DESKTOP_RELAY_CALL DT_REMOVE_ICON, icon_param
        lda     icon_param
        jsr     DESKTOP_FREE_ICON
        dec     cached_window_icon_count
        dec     icon_count
        pla
        tax
L5942:  dex
        bpl     L5916
        ldy     #$00
        sty     L599E
L594A:  ldy     L599E
        inc     cached_window_icon_count
        inc     icon_count
        lda     #$00
        sta     device_to_icon_map,y
        lda     DEVLST,y
        jsr     create_volume_icon
        cmp     #ERR_DUPLICATE_VOLUME
        bne     :+
        lda     #$F9            ; "... 2 volumes with the same name..."
        sta     pending_alert
:       inc     L599E
        lda     L599E
        cmp     DEVCNT
        beq     L594A
        bcc     L594A
        ldx     #$00
L5976:  cpx     cached_window_icon_count
        bne     L5986
        lda     pending_alert
        beq     L5983
        jsr     DESKTOP_SHOW_ALERT0
L5983:  jmp     DESKTOP_COPY_FROM_BUF

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

L599E:  .byte   0

pending_alert:
        .byte   0

L59A0:  lda     #$00
        beq     L59AA

L59A4:  lda     #$80
        bne     L59AA

L59A8:  lda     #$C0

.proc L59AA
        sta     L5AD0
        lda     #$00
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        bit     L5AD0
        bpl     L59EA
        bvc     L59D2
        lda     L533F
        ldy     #$0F
L59C1:  cmp     device_to_icon_map,y
        beq     L59C9
        dey
        bpl     L59C1
L59C9:  sty     L5AC6
        sty     menu_click_params::item_num
        jmp     L59F3

L59D2:  ldy     DEVCNT
        lda     L533F
L59D8:  cmp     DEVLST,y
        beq     L59E1
        dey
        bpl     L59D8
        iny
L59E1:  sty     L5AC6
        sty     menu_click_params::item_num
        jmp     L59F3

L59EA:  lda     menu_click_params::item_num
        sec
        sbc     #$03
        sta     menu_click_params::item_num
L59F3:  ldy     menu_click_params::item_num
        lda     device_to_icon_map,y
        bne     L59FE
        jmp     L5A4C

L59FE:  jsr     icon_entry_lookup
        addax   #9, $06
        ldy     #$00
        lda     ($06),y
        tay
L5A10:  lda     ($06),y
        sta     $1F00,y
        dey
        bpl     L5A10
        dec     $1F00
        lda     #'/'
        sta     $1F00+1
        ldax    #$1F00
        ldy     $1F00
        jsr     L6FB7
        lda     L704B
        beq     L5A4C
L5A2F:  ldx     L704B
        beq     L5A4C
        dex
        lda     L704C,x
        cmp     active_window_id
        beq     L5A43
        sta     findwindow_window_id
        jsr     handle_inactive_window_click
L5A43:  jsr     close_window
        dec     L704B
        jmp     L5A2F

L5A4C:  jsr     redraw_windows_and_desktop
        jsr     clear_selection
        lda     #$00
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        lda     menu_click_params::item_num
        tay
        pha
        lda     device_to_icon_map,y
        sta     icon_param
        beq     L5A7F
        jsr     remove_icon_from_window
        dec     icon_count
        lda     icon_param
        jsr     DESKTOP_FREE_ICON
        jsr     reset_grafport3
        DESKTOP_RELAY_CALL DT_REMOVE_ICON, icon_param
L5A7F:  lda     cached_window_icon_count
        sta     L5AC6
        inc     cached_window_icon_count
        inc     icon_count
        pla
        tay
        lda     DEVLST,y
        jsr     create_volume_icon
        bit     L5AD0
        bmi     L5AA9
        and     #$FF
        beq     L5AA9
        cmp     #'/'
        beq     L5AA9
        pha
        jsr     DESKTOP_COPY_FROM_BUF
        pla
        jsr     DESKTOP_SHOW_ALERT0
        rts

L5AA9:  lda     cached_window_icon_count
        cmp     L5AC6
        beq     L5AC0
        ldx     cached_window_icon_count
        dex
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup
        ldy     #DT_ADD_ICON
        jsr     DESKTOP_RELAY   ; icon entry addr in A,X
L5AC0:  jsr     DESKTOP_COPY_FROM_BUF
        jmp     redraw_windows_and_desktop

L5AC6:  .res    10, 0
L5AD0:  .byte   0
.endproc

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
        sbc     #$30
        clc
        adc     #>$C000         ; compute $Cn00
        sta     reset_and_invoke_target+1
        lda     #<$0000
        sta     reset_and_invoke_target
        ;; fall through
.endproc

        ;; also invoked by launcher code
.proc reset_and_invoke
        sta     ALTZPOFF
        jsr     exit_dhr_mode

        ;; also used by launcher code
        target := *+1
        jmp     dummy0000       ; self-modified
.endproc
        reset_and_invoke_target := reset_and_invoke::target

;;; ============================================================

.proc append_space_after_int
        inc     str_from_int
        ldx     str_from_int
        lda     #' '
        sta     str_from_int,x
        rts
.endproc

;;; ============================================================

        PAD_TO $5B1B            ; Maintain previous addresses

;;; ============================================================

L5B1B:  .byte   0

.proc handle_client_click
        lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        sta     L5B1B

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
        jsr     DESKTOP_COPY_FROM_BUF
        lda     #$00
        sta     cached_window_id
        jmp     DESKTOP_COPY_TO_BUF
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
        jsr     DESKTOP_COPY_FROM_BUF
        lda     #$00
        sta     cached_window_id
        jmp     DESKTOP_COPY_TO_BUF
.endproc

;;; ============================================================

.proc L5C54
        lda     updatethumb_stash
        sta     updatethumb_thumbpos
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     L6523
        jsr     L84D1
        bit     L5B1B
        bmi     :+
        jsr     cached_icons_screen_to_window
:       lda     active_window_id
        sta     getwinport_params2::window_id
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
        bit     L5B1B
        bpl     :+
        jmp     clear_selection

:       lda     active_window_id
        sta     findicon_window_id
        DESKTOP_RELAY_CALL DT_FIND_ICON, findicon_params
        lda     findicon_which_icon
        bne     L5CDA
        jsr     L5F13
        jmp     L5DEC
.endproc

;;; ============================================================


L5CD9:  .byte   0

.proc L5CDA
        sta     L5CD9
        ldx     selected_icon_count
        beq     L5CFB
        dex
        lda     L5CD9
L5CE6:  cmp     selected_icon_list,x
        beq     L5CF0
        dex
        bpl     L5CE6
        bmi     L5CFB
L5CF0:  bit     double_click_flag
        bmi     L5CF8
        jmp     L5DFC

L5CF8:  jmp     L5D55

L5CFB:  bit     BUTN0
        bpl     L5D08
        lda     selected_window_index
        cmp     active_window_id
        beq     L5D0B
L5D08:  jsr     clear_selection
L5D0B:  ldx     selected_icon_count
        lda     L5CD9
        sta     selected_icon_list,x
        inc     selected_icon_count
        lda     active_window_id
        sta     selected_window_index
        lda     active_window_id
        sta     getwinport_params2::window_id
        jsr     get_set_port2
        lda     L5CD9
        sta     icon_param
        jsr     icon_window_to_screen
        jsr     offset_grafport2_and_set
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
        lda     active_window_id
        sta     getwinport_params2::window_id
        jsr     get_set_port2
        lda     L5CD9
        jsr     icon_screen_to_window
        jsr     reset_grafport3
        bit     double_click_flag
        bmi     L5D55
        jmp     L5DFC

L5D55:  lda     L5CD9
        sta     LEBFC
        DESKTOP_RELAY_CALL $0A, LEBFC
        tax
        lda     LEBFC
        beq     L5DA6
        jsr     L8F00
        cmp     #$FF
        bne     L5D77
        jsr     L5DEC
        jmp     redraw_windows_and_desktop

L5D77:  lda     LEBFC
        cmp     trash_icon_num
        bne     L5D8E
        lda     active_window_id
        jsr     L6F0D
        lda     active_window_id
        jsr     select_and_refresh_window
        jmp     redraw_windows_and_desktop

L5D8E:  lda     LEBFC
        bmi     L5D99
        jsr     L6A3F
        jmp     redraw_windows_and_desktop

L5D99:  and     #$7F
        pha
        jsr     L6F0D
        pla
        jsr     select_and_refresh_window
        jmp     redraw_windows_and_desktop

L5DA6:  cpx     #$02
        bne     L5DAD
        jmp     L5DEC

L5DAD:  cpx     #$FF
        beq     L5DF7
        lda     active_window_id
        sta     getwinport_params2::window_id
        jsr     get_set_port2
        jsr     cached_icons_window_to_screen
        jsr     offset_grafport2_and_set
        ldx     selected_icon_count
        dex
L5DC4:  txa
        pha
        lda     selected_icon_list,x
        sta     LE22E
        DESKTOP_RELAY_CALL DT_REDRAW_ICON, LE22E
        pla
        tax
        dex
        bpl     L5DC4
        lda     active_window_id
        sta     getwinport_params2::window_id
        jsr     get_set_port2
        jsr     update_scrollbars
        jsr     cached_icons_screen_to_window
        jsr     reset_grafport3
L5DEC:  jsr     DESKTOP_COPY_FROM_BUF
        lda     #$00
        sta     cached_window_id
        jmp     DESKTOP_COPY_TO_BUF

L5DF7:  ldx     LE256
        txs
        rts

L5DFC:  lda     L5CD9           ; after a double-click (on file or folder)
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_type_mask
        cmp     #icon_entry_type_sys
        beq     L5E28
        cmp     #icon_entry_type_bin
        beq     L5E28
        cmp     #icon_entry_type_bas
        beq     L5E28
        cmp     #icon_entry_type_dir
        bne     L5E27

        lda     L5CD9           ; handle directory
        jsr     open_folder_or_volume_icon
        bmi     L5E27
        jmp     L5DEC

L5E27:  rts

L5E28:  sta     L5E77
        lda     active_window_id
        jsr     window_address_lookup
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L5E3A:  lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     L5E3A
        lda     L5CD9
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

L5E77:  .byte   0

.endproc
        L5DEC := L5CDA::L5DEC

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
        lda     LEC26,x
        pha
        jsr     L7345
        lda     window_id
        tax
        dex
        lda     win_view_by_table,x
        bmi     :+
        jsr     close_active_window
:       lda     active_window_id
        jsr     window_address_lookup

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
        jsr     DESKTOP_COPY_FROM_BUF
        lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        copy    active_window_id, getwinport_params2::window_id
        jsr     get_port2
        jsr     draw_window_header
        lda     #0
        ldx     active_window_id
        sta     win_view_by_table-1,x

        copy    #1, menu_click_params::item_num
        jsr     update_view_menu_check
        copy    #0, cached_window_id
        jmp     DESKTOP_COPY_TO_BUF

window_id:
        .byte   0
.endproc

;;; ============================================================


.proc L5F13_impl

L5F0B:  .byte   0
        .byte   0
        .byte   0
        .byte   0
L5F0F:  .byte   0
        .byte   0
        .byte   0
        .byte   0

start:  copy16  #notpenXOR, $06
        jsr     L60D5

        ldx     #$03
L5F20:  lda     event_coords,x
        sta     L5F0B,x
        sta     L5F0F,x
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
        sta     getwinport_params2::window_id
        jsr     get_port2
        jsr     offset_grafport2_and_set
        ldx     #$03
L5F50:  lda     L5F0B,x
        sta     rect_E230::x1,x
        lda     L5F0F,x
        sta     rect_E230::x2,x
        dex
        bpl     L5F50
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, rect_E230
L5F6B:  jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::drag
        beq     L5FC5
        MGTK_RELAY_CALL MGTK::FrameRect, rect_E230
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
        lda     icon_param
        sta     selected_icon_list,x
        lda     active_window_id
        sta     selected_window_index
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

L601F:  MGTK_RELAY_CALL MGTK::FrameRect, rect_E230

        COPY_STRUCT MGTK::Point, event_coords, L60CF

        cmp16   event_xcoord, rect_E230::x2
        bpl     L6068
        cmp16   event_xcoord, rect_E230::x1
        bmi     L6054
        bit     L60D3
        bpl     L6068
L6054:  copy16  event_xcoord, rect_E230::x1
        lda     #$80
        sta     L60D3
        jmp     L6079

L6068:  copy16  event_xcoord, rect_E230::x2
        lda     #$00
        sta     L60D3
L6079:  cmp16   event_ycoord, rect_E230::y2
        bpl     L60AE
        cmp16   event_ycoord, rect_E230::y1
        bmi     L609A
        bit     L60D4
        bpl     L60AE
L609A:  copy16  event_ycoord, rect_E230::y1
        lda     #$80
        sta     L60D4
        jmp     L60BF

L60AE:  copy16  event_ycoord, rect_E230::y2
        lda     #$00
        sta     L60D4
L60BF:  MGTK_RELAY_CALL MGTK::FrameRect, rect_E230
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

L60DE:  lda     active_window_id
        sta     event_params
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

L6143:  lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        ldx     #$00
L614E:  cpx     cached_window_icon_count
        bne     L6161
        jsr     DESKTOP_COPY_FROM_BUF
        lda     #$00
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
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
        lda     active_window_id
        sta     event_params
        MGTK_RELAY_CALL MGTK::GrowWindow, event_params
        jsr     redraw_windows_and_desktop
        lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        jsr     cached_icons_window_to_screen
        jsr     update_scrollbars
        jsr     cached_icons_screen_to_window
        lda     #$00
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
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
        lda     active_window_id
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
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
        jsr     DESKTOP_FREE_ICON
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
        jsr     DESKTOP_COPY_FROM_BUF
        MGTK_RELAY_CALL MGTK::CloseWindow, active_window_id
        ldx     active_window_id
        dex
        lda     LEC26,x
        sta     icon_param
        jsr     icon_entry_lookup
        stax    $06
        ldy     #$01
        lda     ($06),y
        and     #$0F
        beq     L6276
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #(~icon_entry_open_mask)&$FF ; clear open_flag
        sta     ($06),y
        and     #$0F
        sta     selected_window_index
        jsr     zero_grafport5_coords
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
        jsr     reset_grafport3
        lda     #$01
        sta     selected_icon_count
        lda     icon_param
        sta     selected_icon_list
L6276:  ldx     active_window_id
        dex
        lda     LEC26,x
        jsr     L7345
        ldx     active_window_id
        dex
        lda     LEC26,x
        inx
        jsr     animate_window_close
        ldx     active_window_id
        dex
        lda     #$00
        sta     LEC26,x
        sta     win_view_by_table,x
        MGTK_RELAY_CALL MGTK::FrontWindow, active_window_id
        lda     #$00
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
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
        cmp16   L63EA, L7B61
        bmi     L63C1
        ldax    L63EA
        jmp     L63C7

L63C1:  ldax    L7B61
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
        cmp16   L644A, L7B65
        bpl     L6421
        ldax    L644A
        jmp     L6427

L6421:  ldax    L7B65
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
        cmp16   L64AE, L7B5F
        bmi     L6484
        ldax    L64AE
        jmp     L648A

L6484:  ldax    L7B5F
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
        cmp16   L650D, L7B63
        bpl     L64E3
        ldax    L650D
        jmp     L64E9

L64E3:  ldax    L7B63
L64E9:  stax    grafport2::cliprect::x2
        sub16   grafport2::cliprect::x2, L650B, grafport2::cliprect::x1
        jsr     assign_active_window_cliprect
        jsr     update_scrollbars
        jmp     L6556

L650B:  .word   0
L650D:  .word   0
.endproc

.proc L650F
        bit     L5B1B
        bmi     :+
        jsr     cached_icons_window_to_screen
:       jsr     L6523
        jsr     L7B6B
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
        bit     L5B1B
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
        sub16   L7B63, L7B5F, L6602
        sub16   L6602, L6600, L6602
        lsr16    L6602
        ldx     L6602
        sub16   grafport2::cliprect::x1, L7B5F, L6602
        bpl     L65D0
        lda     #$00
        beq     L65EB
L65D0:  cmp16   grafport2::cliprect::x2, L7B63
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
        sub16   L7B65, L7B61, L66A0
        sub16_8 L66A0, L669F, L66A0
        lsr16    L66A0
        lsr16    L66A0
        ldx     L66A0
        sub16   grafport2::cliprect::y1, L7B61, L66A0
        bpl     L6669
        lda     #$00
        beq     L668A
L6669:  cmp16   grafport2::cliprect::y2, L7B65
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
        jmp     check_menu_items

disable_menu_items:
        lda     #MGTK::disablemenu_disable
        sta     disablemenu_params::disable
        MGTK_RELAY_CALL MGTK::DisableMenu, disablemenu_params

        lda     #MGTK::disableitem_disable
        sta     disableitem_params::disable
        lda     #menu_id_file
        sta     disableitem_params::menu_id
        lda     #desktop_aux::menu_item_id_new_folder
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        lda     #desktop_aux::menu_item_id_close
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        lda     #desktop_aux::menu_item_id_close_all
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params

        lda     #0
        sta     menu_dispatch_flag
        rts

        ;; Is this residue of a Windows menu???
check_menu_items:
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
        lda     #MGTK::disableitem_disable
        sta     disableitem_params::disable
        lda     #menu_id_file
        sta     disableitem_params::menu_id
        lda     #desktop_aux::menu_item_id_open
        jsr     disable_menu_item
        lda     #menu_id_special
        sta     disableitem_params::menu_id
        lda     #desktop_aux::menu_item_id_lock
        jsr     disable_menu_item
        lda     #desktop_aux::menu_item_id_unlock
        jsr     disable_menu_item
        lda     #desktop_aux::menu_item_id_get_info
        jsr     disable_menu_item
        lda     #desktop_aux::menu_item_id_get_size
        jsr     disable_menu_item
        lda     #desktop_aux::menu_item_id_rename_icon
        jsr     disable_menu_item
        rts

disable_menu_item:
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        rts
.endproc

;;; ============================================================

.proc enable_file_menu_items
        lda     #MGTK::disableitem_enable
        sta     disableitem_params::disable
        lda     #menu_id_file
        sta     disableitem_params::menu_id
        lda     #desktop_aux::menu_item_id_open
        jsr     enable_menu_item
        lda     #menu_id_special
        sta     disableitem_params::menu_id
        lda     #desktop_aux::menu_item_id_lock
        jsr     enable_menu_item
        lda     #desktop_aux::menu_item_id_unlock
        jsr     enable_menu_item
        lda     #desktop_aux::menu_item_id_get_info
        jsr     enable_menu_item
        lda     #desktop_aux::menu_item_id_get_size
        jsr     enable_menu_item
        lda     #desktop_aux::menu_item_id_rename_icon
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
        lda     #MGTK::disableitem_enable
        sta     disableitem_params::disable
        jmp     :+

disable:
        lda     #MGTK::disableitem_disable
        sta     disableitem_params::disable

:       lda     #menu_id_file
        sta     disableitem_params::menu_id

        lda     #11             ; > Eject
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        rts

.endproc
enable_eject_menu_item := toggle_eject_menu_item::enable
disable_eject_menu_item := toggle_eject_menu_item::disable

;;; ============================================================

.proc toggle_selector_menu_items
disable:
        lda     #MGTK::disableitem_disable
        sta     disableitem_params::disable
        jmp     :+

enable:
        lda     #MGTK::disableitem_enable
        sta     disableitem_params::disable

:       lda     #menu_id_selector
        sta     disableitem_params::menu_id
        lda     #2              ; > Edit
        jsr     configure_menu_item
        lda     #3              ; > Delete
        jsr     configure_menu_item
        lda     #4              ; > Run
        jsr     configure_menu_item
        lda     #$80
        sta     LD344
        rts

configure_menu_item:
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        rts
.endproc
enable_selector_menu_items := toggle_selector_menu_items::enable
disable_selector_menu_items := toggle_selector_menu_items::disable

;;; ============================================================

.proc handle_icon_click
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
        lda     #1
        sta     selected_icon_count
        lda     findicon_which_icon
        sta     selected_icon_list
        lda     #0
        sta     selected_window_index


L6834:  bit     double_click_flag
        bpl     L6880
        lda     findicon_which_icon
        sta     LEBFC
        DESKTOP_RELAY_CALL $0A, LEBFC
        tax
        lda     LEBFC
        beq     L6878
        jsr     L8F00
        cmp     #$FF
        bne     L6858
        jmp     redraw_windows_and_desktop

L6858:  lda     LEBFC
        cmp     trash_icon_num
        bne     L6863
        jmp     redraw_windows_and_desktop

L6863:  lda     LEBFC
        bpl     L6872
        and     #$7F
        pha
        jsr     L6F0D
        pla
        jmp     select_and_refresh_window

L6872:  jsr     L6A3F
        jmp     redraw_windows_and_desktop

L6878:  txa
        cmp     #2
        bne     L688F
        jmp     redraw_windows_and_desktop

L6880:  lda     findicon_which_icon
        cmp     trash_icon_num
        beq     L688E
        jsr     open_folder_or_volume_icon
        jsr     DESKTOP_COPY_FROM_BUF
L688E:  rts

L688F:  ldx     selected_icon_count
        dex
L6893:  txa
        pha
        lda     selected_icon_list,x
        sta     LE22D
        DESKTOP_RELAY_CALL DT_REDRAW_ICON, LE22D
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
        sta     rect_E230::x1,x
        sta     rect_E230::x2,x
        dex
        bpl     L68B8
        jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::drag
        beq     L68CF
        rts

L68CF:  MGTK_RELAY_CALL MGTK::SetPattern, checkerboard_pattern3
        jsr     set_penmode_xor
        MGTK_RELAY_CALL MGTK::FrameRect, rect_E230
L68E4:  jsr     peek_event
        lda     event_kind
        cmp     #MGTK::EventKind::drag
        beq     L6932
        MGTK_RELAY_CALL MGTK::FrameRect, rect_E230
        ldx     #0
L68F9:  cpx     cached_window_icon_count
        bne     :+
        lda     #0
        sta     selected_window_index
        rts

:       txa
        pha
        lda     cached_window_icon_list,x
        sta     icon_param
        DESKTOP_RELAY_CALL DT_ICON_IN_RECT, icon_param
        beq     L692C
        DESKTOP_RELAY_CALL DT_HIGHLIGHT_ICON, icon_param
        ldx     selected_icon_count
        inc     selected_icon_count
        lda     icon_param
        sta     selected_icon_list,x
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

L6989:  MGTK_RELAY_CALL MGTK::FrameRect, rect_E230

        COPY_STRUCT MGTK::Point, event_coords, L6A39

        cmp16   event_xcoord, rect_E230::x2
        bpl     L69D2
        cmp16   event_xcoord, rect_E230::x1
        bmi     L69BE
        bit     L6A3D
        bpl     L69D2
L69BE:  copy16  event_xcoord, rect_E230::x1
        lda     #$80
        sta     L6A3D
        jmp     L69E3

L69D2:  copy16  event_xcoord, rect_E230::x2
        lda     #$00
        sta     L6A3D
L69E3:  cmp16   event_ycoord, rect_E230::y2
        bpl     L6A18
        cmp16   event_ycoord, rect_E230::y1
        bmi     L6A04
        bit     L6A3E
        bpl     L6A18
L6A04:  copy16  event_ycoord, rect_E230::y1
        lda     #$80
        sta     L6A3E
        jmp     L6A29

L6A18:  copy16  event_ycoord, rect_E230::y2
        lda     #$00
        sta     L6A3E
L6A29:  MGTK_RELAY_CALL MGTK::FrameRect, rect_E230
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

.proc L6A3F
        ptr := $6

        ldx     #7
:       cmp     LEC26,x
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
        sta     $220,y
        dey
        bpl     L6A5C
        dec     $220
        lda     #'/'
        sta     $0220+1

        ldax    #$220
        ldy     $220
        jsr     L6FB7
        ldax    #$220
        ldy     $220
        jmp     L6F4B

L6A80:  inx
        txa
        pha
        jsr     L6F0D
        pla
        jmp     select_and_refresh_window
.endproc

;;; ============================================================

.proc open_folder_or_volume_icon
        sta     icon_params2
        jsr     DESKTOP_COPY_FROM_BUF
        lda     icon_params2
        ldx     #$07
L6A95:  cmp     LEC26,x
        beq     L6AA0
        dex
        bpl     L6A95
        jmp     L6B1E

L6AA0:  inx
        cpx     active_window_id
        bne     L6AA7
        rts

L6AA7:  stx     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
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
        lda     #$00
        sta     cached_window_id
        jmp     DESKTOP_COPY_TO_BUF

L6B1E:  lda     LEC2E
        cmp     #$08
        bcc     L6B2F
        lda     #warning_msg_too_many_windows
        jsr     show_warning_dialog_num
        ldx     LE256
        txs
        rts

L6B2F:  ldx     #$00
L6B31:  lda     LEC26,x
        beq     L6B3A
        inx
        jmp     L6B31

L6B3A:  lda     icon_params2
        sta     LEC26,x
        inx
        stx     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
        inc     LEC2E
        ldx     cached_window_id
        dex
        lda     #$00
        sta     win_view_by_table,x
        lda     LEC2E
        cmp     #$02
        bcs     L6B60
        jsr     enable_various_file_menu_items
        jmp     L6B68

L6B60:  lda     #$00
        sta     checkitem_params::check
        jsr     check_item
L6B68:  lda     #$01
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
        ldy     #$38
        jsr     MGTK_RELAY
        lda     active_window_id
        sta     getwinport_params2::window_id
        jsr     get_set_port2
        jsr     draw_window_header
        jsr     cached_icons_window_to_screen
        lda     #$00
        sta     L6C0E
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
        jsr     DESKTOP_COPY_FROM_BUF
        lda     #$00
        sta     cached_window_id
        jsr     DESKTOP_COPY_TO_BUF
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
        bit     L4152
        bmi     L6C39
        jsr     draw_window_header
L6C39:  lda     cached_window_id
        sta     getwinport_params2::window_id
        jsr     get_port2
        bit     L4152
        bmi     L6C4A
        jsr     offset_grafport2_and_set
L6C4A:  ldx     cached_window_id
        dex
        lda     LEC26,x
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
        bit     L4152
        bmi     L6CDE
        jsr     draw_window_header
L6CDE:  jsr     cached_icons_window_to_screen
        jsr     offset_grafport2_and_set

        COPY_BLOCK grafport2::cliprect, rect_E230

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

L6D31:  lda     #$00
        sta     L6DB0
        lda     selected_window_index
        sta     rect_E230
        beq     L6D7D
        cmp     active_window_id
        beq     L6D4D
        jsr     zero_grafport5_coords
        lda     #$00
        sta     rect_E230
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
        jsr     L7B6B
        jmp     config_port

:       jsr     cached_icons_window_to_screen
        jsr     L7B6B
        jsr     cached_icons_screen_to_window

config_port:
        lda     active_window_id
        sta     getwinport_params2::window_id
        jsr     get_set_port2

        ;; check horizontal bounds
        cmp16   L7B5F, grafport2::cliprect::x1
        bmi     activate_hscroll
        cmp16   grafport2::cliprect::x2, L7B63
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
        cmp16   L7B61, grafport2::cliprect::y1
        bmi     activate_vscroll
        cmp16   grafport2::cliprect::y2, L7B65
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
        lda     #MGTK::disablemenu_enable
        sta     disablemenu_params::disable
        MGTK_RELAY_CALL MGTK::DisableMenu, disablemenu_params

        lda     #MGTK::disableitem_enable
        sta     disableitem_params::disable
        lda     #menu_id_file
        sta     disableitem_params::menu_id
        lda     #1              ; > New Folder
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        lda     #4              ; > Close
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        lda     #5              ; > Close All
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params

        lda     #$80
        sta     menu_dispatch_flag
        rts
.endproc

;;; ============================================================

.proc L6F0D
        ptr := $6

        jsr     window_address_lookup
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
        addr_call_indirect L6FB7, ptr ; ???
        ldax    pathptr
        ldy     pathlen
        jmp     L6F4B

pathptr:        .addr   0
pathlen:        .byte   0
.endproc

;;; ============================================================

.proc L6F4B
        ptr := $6

        stax    ptr
        sty     vol_info_path_buf
L6F52:  lda     (ptr),y
        sta     vol_info_path_buf,y
        dey
        bne     L6F52
        jsr     get_vol_free_used
        bne     L6F8F
        lda     L704B
        beq     L6F8F
L6F64:  dec     L704B
        bmi     L6F8F
        ldx     L704B
        lda     L704C,x
        sec
        sbc     #1
        asl     a
        tax
        copy16  vol_kb_used, window_k_used_table,x
        copy16  vol_kb_free, window_k_free_table,x
        jmp     L6F64

L6F8F:  rts
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
.proc L6FBD
        ptr := $6

set:    stax    ptr
        lda     #$80
        bne     start

unset:  stax    ptr
        lda     #0

start:  sta     flag
        bit     flag
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

        ;; And capitalize
        addr_call adjust_case, path_buffer

        lda     #0
        sta     L704B
        sta     L7049

loop:   inc     L7049
        lda     L7049
        cmp     #$09
        bcc     L6FF6
        bit     flag
        bpl     L6FF5
        lda     #0
L6FF5:  rts

L6FF6:  jsr     window_lookup
        stax    ptr
        ldy     #10
        lda     (ptr),y
        beq     loop
        lda     L7049
        jsr     window_address_lookup
        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
        cmp     path_buffer
        beq     L7027
        bit     flag
        bmi     loop
        ldy     path_buffer
        iny
        lda     (ptr),y
        cmp     #'/'
        bne     loop
        dey
L7027:  lda     (ptr),y
        cmp     path_buffer,y
        bne     loop
        dey
        bne     L7027
        bit     flag
        bmi     done
        ldx     L704B
        lda     L7049
        sta     L704C,x
        inc     L704B
        jmp     loop

done:   return  L7049

L7049:  .byte   0
flag:   .byte   0
.endproc
        L6FAF := L6FBD::set
        L6FB7 := L6FBD::unset


L704B:  .byte   0
L704C:  .res    8

;;; ============================================================

.struct FileRecord
        name                    .res 16
        file_type               .byte ; 16 $10
        blocks                  .word ; 17 $11
        creation_date           .word ; 19 $13
        creation_time           .word ; 21 $15
        modification_date       .word ; 23 $17
        modification_time       .word ; 25 $19
        access                  .byte ; 27 $1B
        header_pointer          .word ; 28 $1C
        reserved                .word ; ???
.endstruct

;;; ============================================================

.proc open_directory
        jmp     start

        DEFINE_OPEN_PARAMS open_params, vol_info_path_buf, $800

vol_info_path_buf:
        .res    65, 0

        DEFINE_READ_PARAMS read_params, $0C00, $200
        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params4, vol_info_path_buf

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

        COPY_BYTES $41, LE1B0, vol_info_path_buf

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
        jsr     L8B19
        dec     LEC2E
        jsr     redraw_windows_and_desktop
        jsr     do_close
        lda     active_window_id
        beq     L715F
        lda     #$03
        bne     L7161
L715F:  lda     #warning_msg_window_must_be_closed2
L7161:  jsr     show_warning_dialog_num
        ldx     LE256
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

        lda     #$FF
        sta     L70C4
        lda     #$00
        sta     L70C3

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

L71E7:  lda     #$00
        sta     L70C3
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
        jsr     DESKTOP_SHOW_ALERT0
        jsr     L8B1F
        lda     selected_window_index
        bne     :+
        lda     icon_params2
        sta     L533F
        jsr     L59A8
:       ldx     LE256
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


get_vol_free_used:  MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params4
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
        vol_info_path_buf := open_directory::vol_info_path_buf
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
        jsr     window_address_lookup
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
        ldy     #$01
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
        lda     #$00
        sta     L7620
        jsr     push_pointers
        tya
        pha
        jsr     window_address_lookup
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
        lda     #$40
        jsr     DESKTOP_SHOW_ALERT0
        jsr     L8B1F
        dec     LEC2E
        ldx     LE256
        txs
        rts

L750D:  ldy     #$00
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
        jsr     window_address_lookup
        stax    $08
        ldy     LE1B0
L7561:  lda     LE1B0,y
        sta     ($08),y
        dey
        bpl     L7561
L7569:  addr_call_indirect adjust_case, $08
        lda     cached_window_id
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
L7625:  .byte   0               ; ???

initial_coords:                 ; first icon in window
        DEFINE_POINT  52,16, initial_coords

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
        lda     LEC26,x
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

:       jsr     L7B6B
        lda     window_id
        jsr     window_lookup
        stax    $06
        ldy     #$16
        lda     L7B65
        sec
        sbc     ($06),y
        sta     L7B65
        lda     L7B66
        sbc     #$00
        sta     L7B66
        cmp16   L7B63, #170
        bmi     L7705
        cmp16   L7B63, #450
        bpl     L770C
        ldax    L7B63
        jmp     L7710

L7705:  addr_jump L7710, $00AA

L770C:  ldax    #450
L7710:  ldy     #$20
        sta     ($06),y
        txa
        iny
        sta     ($06),y

        cmp16   L7B65, #50
        bmi     L7739
        cmp16   L7B65, #108
        bpl     L7740
        ldax    L7B65
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
        jsr     DESKTOP_ALLOC_ICON
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
        cmp     #FT_SYSTEM      ; Other system?
        bne     got_type        ; nope

        ;; Distinguish *.SYSTEM files as apps (use $01) from other
        ;; type=SYS files (use $FF).
        ldy     #FileEntry::storage_type_name_length
        lda     (file_entry),y
        tay
        ldx     str_sys_suffix
:       lda     (file_entry),y
        cmp     str_sys_suffix,x
        bne     not_app
        dey
        beq     not_app
        dex
        bne     :-

is_app:
        lda     #$01            ; TODO: Define a symbol for this.
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
        addr_call adjust_case, name_tmp
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
        add16   row_coords::ycoord, #32, row_coords::ycoord
        copy16  initial_coords::xcoord, row_coords::xcoord
        lda     #0
        sta     icons_this_row
        jmp     L7870

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

.proc find_icon_details_for_file_type
        ptr := $6

        sta     file_type
        jsr     push_pointers

        ;; Find index of file type
        copy16  type_table_addr, ptr
        ldy     #0
        lda     (ptr),y         ; first entry is size of table
        tay
:       lda     (ptr),y
        cmp     file_type
        beq     found
        dey
        bpl     :-
        ldy     #1              ; default is first entry (FT_TYPELESS)

found:
        ;; Look up icon type
        copy16  icon_type_table_addr, ptr
        lda     (ptr),y
        sta     icon_type
        dey
        tya
        asl     a
        tay

        ;; Look up icon definition
        copy16  type_icons_addr, ptr
        copy16in (ptr),y, iconbits
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
        lda     #$80
        sta     nonzero_flag
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

        PAD_TO $7B5F

;;; ============================================================

L7B5F:  .byte   0
L7B60:  .byte   0
L7B61:  .byte   0
L7B62:  .byte   0

L7B63:  .byte   0
L7B64:  .byte   0
L7B65:  .byte   0
L7B66:  .byte   0

L7B67:  .byte   0
L7B68:  .byte   0
L7B69:  .byte   0
L7B6A:  .byte   0

.proc L7B6B
        ldx     #3
        lda     #0
L7B6F:  sta     L7B63,x
        dex
        bpl     L7B6F

        sta     L7D5B
        lda     #$FF
        sta     L7B5F
        sta     L7B61
        lda     #$7F
        sta     L7B60
        sta     L7B62
        ldx     cached_window_id
        dex
        lda     win_view_by_table,x
        bpl     L7BCB
        lda     cached_window_icon_count
        bne     L7BA1
L7B96:  ldax    #$0300
L7B9A:  sta     L7B5F,x
        dex
        bpl     L7B9A
        rts

L7BA1:  clc
        adc     #$02
        ldx     #$00
        stx     L7D5C
        asl     a
        rol     L7D5C
        asl     a
        rol     L7D5C
        asl     a
        rol     L7D5C
        sta     L7B65
        lda     L7D5C
        sta     L7B66
        copy16  #$168, L7B63
        jmp     L7B96

L7BCB:  lda     cached_window_icon_count
        cmp     #$01
        bne     L7BEF
        lda     cached_window_icon_list
        jsr     icon_entry_lookup
        stax    $06
        ldy     #$06
        ldx     #$03
L7BE0:  lda     ($06),y
        sta     L7B5F,x
        sta     L7B63,x
        dey
        dex
        bpl     L7BE0
        jmp     L7BF7

L7BEF:  lda     L7D5B
        cmp     cached_window_icon_count
        bne     L7C36
L7BF7:  lda     L7B63
        clc
        adc     #$32
        sta     L7B63
        bcc     L7C05
        inc     L7B64
L7C05:  lda     L7B65
        clc
        adc     #$20
        sta     L7B65
        bcc     L7C13
        inc     L7B66
L7C13:  sub16   L7B5F, #50, L7B5F
        sub16   L7B61, #15, L7B61
        rts

L7C36:  tax
        lda     cached_window_icon_list,x
        jsr     icon_entry_lookup
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        cmp     L7D5C
        bne     L7C52
        inc     L7D5B
        jmp     L7BEF

L7C52:  ldy     #$06
        ldx     #$03
L7C56:  lda     ($06),y
        sta     L7B67,x
        dey
        dex
        bpl     L7C56
        bit     L7B60
        bmi     L7C88
        bit     L7B68
        bmi     L7CCE
        cmp16   L7B67, L7B5F
        bmi     L7CCE
        cmp16   L7B67, L7B63
        bpl     L7CBF
        jmp     L7CDA

L7C88:  bit     L7B68
        bmi     L7CA3
        bit     L7B64
        bmi     L7CDA
        cmp16   L7B67, L7B63
        bmi     L7CDA
        jmp     L7CBF

L7CA3:  cmp16   L7B67, L7B5F
        bmi     L7CCE
        cmp16   L7B67, L7B63
        bmi     L7CDA
L7CBF:  copy16  L7B67, L7B63
        jmp     L7CDA

L7CCE:  copy16  L7B67, L7B5F
L7CDA:  bit     L7B62
        bmi     L7D03
        bit     L7B6A
        bmi     L7D49
        cmp16   L7B69, L7B61
        bmi     L7D49
        cmp16   L7B69, L7B65
        bpl     L7D3A
        jmp     L7D55

L7D03:  bit     L7B6A
        bmi     L7D1E
        bit     L7B66
        bmi     L7D55
        cmp16   L7B69, L7B65
        bmi     L7D55
        jmp     L7D3A

L7D1E:  cmp16   L7B69, L7B61
        bmi     L7D49
        cmp16   L7B69, L7B65
        bmi     L7D55
L7D3A:  copy16  L7B69, L7B65
        jmp     L7D55

L7D49:  copy16  L7B69, L7B61
L7D55:  inc     L7D5B
        jmp     L7BEF

L7D5B:  .byte   0
L7D5C:  .byte   0
.endproc

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
        lda     LEC26,x

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
        and     #$0F            ; mask off name length
        sta     name_len
        ldy     #1
cloop:  lda     (ptr),y
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

        lda     #$00
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

        lda     #$00
        sta     date
        sta     date+1

        ldx     index
        dex
        ldy     $0806
        iny
        jsr     L812B

        lda     #$00
        sta     record_num
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
        lda     #$00
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

        ;; Copy type_table (including size) to $807
        copy16  type_table_addr, $08
        ldy     #0
        lda     ($08),y
        sta     type_table_copy
        tay                     ; num entries
:       lda     ($08),y
        sta     type_table_copy,y
        dey
        bne     :-

        lda     LCBANK2
        lda     LCBANK2

        lda     #0
        sta     index
        sta     record_num
        lda     #$FF
        sta     $0806

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

        lda     #$00
        sta     record_num
        lda     #$FF
        sta     $0806
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

        lda     #$00
        sta     record_num

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
        lda     #$00
        sta     text_buffer2::length
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
        addr_call SETPOS_DRAWTEXT_RELAY, pos_col_name
        jsr     prepare_col_type
        addr_call SETPOS_DRAWTEXT_RELAY, pos_col_type
        jsr     prepare_col_size
        addr_call SETPOS_DRAWTEXT_RELAY, pos_col_size
        jsr     compose_date_string
        addr_jump SETPOS_DRAWTEXT_RELAY, pos_col_date
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
        addr_call adjust_case, text_buffer2::length
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
        lda     #' '
        sta     text_buffer2::data

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
        bit     L5B1B
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
        jsr     L7B6B
        ldx     L85F1

        sub16   L7B63,x, L7B5F,x, L85F2

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
        adc     L7B5F,x
        sta     grafport2::cliprect::x1,x
        lda     L85F2
        adc     L7B60,x
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

.proc window_address_lookup
        asl     a
        tax
        lda     window_address_table,x
        pha
        lda     window_address_table+1,x
        tax
        pla
        rts
.endproc

;;; ============================================================

.proc compose_file_type_string
        sta     L877F
        copy16  type_table_addr, $06
        ldy     #$00
        lda     ($06),y
        tay
L8719:  lda     ($06),y
        cmp     L877F
        beq     L8726
        dey
        bne     L8719
        jmp     L8745

L8726:  tya
        asl     a
        asl     a
        tay
        copy16  type_names_addr, $06
        ldx     #$00
L8736:  lda     ($06),y
        sta     str_file_type+1,x
        iny
        inx
        cpx     #$04
        bne     L8736
        stx     str_file_type
        rts

L8745:  copy    #4, str_file_type
        copy    #' ', str_file_type+1
        copy    #'$', str_file_type+2
        lda     L877F
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
        adc     #'7'            ; A-F
L8767:  sta     str_file_type+3
        lda     L877F
        and     #$0F
        cmp     #$0A
        bcs     L8778
        clc
        adc     #'0'            ; 0-9
        bne     L877B
L8778:  clc
        adc     #'7'            ; A-F
L877B:  sta     path_buf4
        rts

L877F:  .byte   0

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
;;; Create Volume Icon. unit_number passed in A

        cvi_data_buffer := $800

        DEFINE_ON_LINE_PARAMS on_line_params,, cvi_data_buffer

.proc create_volume_icon
        sta     unit_number
        sty     device_num
        and     #$F0
        sta     on_line_params::unit_num
        MLI_RELAY_CALL ON_LINE, on_line_params
        beq     success

error:  pha                     ; save error
        ldy     device_num      ; remove unit from list
        lda     #0
        sta     device_to_icon_map,y
        dec     cached_window_icon_count
        dec     icon_count
        pla
        rts

success:
        lda     cvi_data_buffer ; dr/slot/name_len
        and     #$0F            ; mask off name len
        bne     create_icon
        lda     cvi_data_buffer+1 ; if name len is zero, second byte is error
        jmp     error

create_icon:
        icon_ptr := $6

        jsr     push_pointers
        jsr     DESKTOP_ALLOC_ICON
        ldy     device_num
        sta     device_to_icon_map,y
        jsr     icon_entry_lookup
        stax    icon_ptr

        ;; Copy name, with leading/trailing space
        lda     cvi_data_buffer
        and     #$0F
        sta     cvi_data_buffer
        addr_call adjust_case, cvi_data_buffer

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
        slot_addr := $0A

        ;; Look at "ID Nibble" (mostly bogus)
        lda     unit_number
        and     #%00001111      ; look at low nibble
        beq     is_disk_ii      ; only trustworthy use of "ID Nibble"

        ;; Look up driver address
        lda     unit_number
        jsr     device_driver_address
        bne     default         ; RAM-based driver: just use default
        lda     #$00
        sta     slot_addr       ; point at $Cn00 for firmware lookups

        ;; Probe firmware ID bytes
        ldy     #$FF            ; $CnFF: $00=Disk II, $FF=13-sector, else=block
        lda     (slot_addr),y
        beq     is_disk_ii

        ldy     #$07            ; SmartPort signature byte ($Cn07)
        lda     (slot_addr),y   ; $00 = SmartPort
        bne     default         ; unknown - use default

        ldy     #$FB            ; SmartPort ID Type Byte ($CnFB)
        lda     (slot_addr),y   ; bit 0 = is RAM Card?
        ora     #%00000001
        bne     is_ram_card

        ;; TODO: Distinguish ProFile vs. 3.5" disk using blocks.
        lda     unit_number     ; low nibble is high nibble of $CnFE
        ora     #%00001000      ; bit 3 = is removable?
        bne     is_35_floppy
        ;; fall through

default:
is_profile:
        ldax    #desktop_aux::profile_icon
        bne     assign

is_disk_ii:
        ldax    #desktop_aux::floppy140_icon
        bne     assign

is_35_floppy:
        ldax    #desktop_aux::floppy800_icon
        bne     assign

is_ram_card:
        ldax    #desktop_aux::ramdisk_icon
        ;; fall through

        ;; Assign icon bitmap
assign: ldy     #IconEntry::iconbits
        sta     (icon_ptr),y
        txa
        iny
        sta     (icon_ptr),y

        ;; ----------------------------------------

        ;; Assign icon type
        ldy     #IconEntry::win_type
        lda     #0
        sta     (icon_ptr),y
        inc     device_num

        ;; TODO: Center icon horizontally
        ;; (Currently, left edges are aligned)

        ;; Assign icon coordinates
        lda     device_num
        asl     a               ; device num * 4 is coordinates index
        asl     a
        tax
        ldy     #IconEntry::iconx
:       lda     desktop_icon_coords_table,x
        sta     (icon_ptr),y
        inx
        iny
        cpy     #IconEntry::iconbits
        bne     :-

        ;; Assign icon number
        ldx     cached_window_icon_count
        dex
        ldy     #IconEntry::id
        lda     (icon_ptr),y
        sta     cached_window_icon_list,x
        jsr     pop_pointers
        return  #0
.endproc

;;; ============================================================

unit_number:    .byte   0
device_num:     .byte   0

desktop_icon_coords_table:
        DEFINE_POINT 0,0
        DEFINE_POINT 490,16
        DEFINE_POINT 490,45
        DEFINE_POINT 490,75
        DEFINE_POINT 490,103
        DEFINE_POINT 490,131
        DEFINE_POINT 400,160
        DEFINE_POINT 310,160
        DEFINE_POINT 220,160
        DEFINE_POINT 130,160
        DEFINE_POINT 40,160
        DEFINE_POINT 400,131
        DEFINE_POINT 310,131
        DEFINE_POINT 220,131
        ;; Maximum of 13 devices:
        ;; 7 slots * 2 drives = 14 (size of DEVLST)
        ;; ... but RAM in Slot 3 Drive 2 is disconnected.

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, prefix_buffer

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

L8B19:  jsr     push_pointers
        jmp     L8B2E

L8B1F:  lda     icon_params2
        bne     L8B25
        rts

L8B25:  jsr     push_pointers
        lda     icon_params2
        jsr     L7345
        ;; fall through

.proc L8B2E
        ptr := $6

        lda     icon_params2
        ldx     #7              ; ???
:       cmp     LEC26,x
        beq     :+
        dex
        bpl     :-
        jmp     skip

:       lda     #0
        sta     LEC26,x
skip:   lda     icon_params2
        jsr     icon_entry_lookup
        stax    ptr
        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #(~icon_entry_open_mask)&$FF ; clear open_flag
        sta     ($06),y
        jsr     L4244
        jsr     pop_pointers
        rts
.endproc

;;; ============================================================

.proc animate_window
        ptr := $06
        rect_table := $0800

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

        ldx     #$23
:       lda     (ptr),y
        sta     grafport2,x
        dey
        dex
        bpl     :-

        ;; Get icon position
        lda     icon_id
        jsr     icon_entry_lookup
        stax    ptr
        ldy     #$03
        lda     ($06),y
        clc
        adc     #$07

        sta     rect_table
        sta     $0804
        iny
        lda     ($06),y
        adc     #$00
        sta     $0801
        sta     $0805
        iny
        lda     ($06),y
        clc
        adc     #$07
        sta     $0801+1
        sta     $0806
        iny
        lda     ($06),y
        adc     #$00
        sta     $0803
        sta     $0807
        ldy     #$5B
        ldx     #$03
L8BC1:  lda     grafport2,x
        sta     rect_table,y
        dey
        dex
        bpl     L8BC1
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
        lda     #$80
        sta     L8D4E
        lda     L8D50
        eor     #$FF
        sta     L8D50
        lda     L8D51
        eor     #$FF
        sta     L8D51
        inc16   L8D50
L8C6A:  bit     L8D53
        bpl     L8C8C
        lda     #$80
        sta     L8D4F
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
        MGTK_RELAY_CALL MGTK::SetPattern, checkerboard_pattern3
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
        sta     rect_E230,y
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
        sta     rect_E230,y
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
        MGTK_RELAY_CALL MGTK::SetPattern, checkerboard_pattern3
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
        sta     rect_E230,y
        dex
        dey
        bpl     :-

        jsr     draw_anim_window_rect

        ;; Compute offset into rect table
erase:  lda     step
        clc
        adc     #2
        cmp     #14
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
        sta     rect_E230,y
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
        MGTK_RELAY_CALL MGTK::FrameRect, rect_E230
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
        lda     #$00
        sta     restore_flag
        beq     :+

restore:
        pha
        lda     #$80            ; entry point with bit set
        sta     restore_flag

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
        jsr     show_warning_dialog_num
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

        PAD_TO $8F00

;;; ============================================================

L8F00:  jmp     L8FC5
        jmp     rts2            ; rts
        jmp     rts2            ; rts
jt_get_info:    jmp     do_get_info ; cmd_get_info
jt_lock:        jmp     do_lock ; cmd_lock
jt_unlock:      jmp     do_unlock ; cmd_unlock
jt_rename_icon: jmp     do_rename_icon ; cmd_rename_icon
jt_eject:       jmp     do_eject ; cmd_eject ???
jt_copy_file:   jmp     do_copy_file ; cmd_copy_file
jt_delete_file: jmp     do_delete_file ; cmd_delete_file
        jmp     rts2            ; rts
        jmp     rts2            ; rts
L8F24:  jmp     L8F7E           ; cmd_selector_action ???
jt_get_size:    jmp     do_get_size ; cmd_get_size

;;; ============================================================

        ;;  TODO: Break this down more?
.proc cmds

do_copy_file:
        lda     #0
        sta     L9189
        tsx
        stx     stack_stash
        jsr     LA248
        jsr     L993E
        jsr     LA271
        jsr     L9968
L8F3F:  copy16  #$00FF, LE05B
        jsr     L9A0D
        jsr     done_dialog_phase1
L8F4F:  jsr     L91E8
        return  #0

        jsr     L91D5
        jmp     L8F4F

do_delete_file:
        lda     #0
        sta     L9189
        tsx
        stx     stack_stash
        jsr     LA248
        lda     #$00
        jsr     L9E7E
        jsr     LA271
        jsr     done_dialog_phase2
        jsr     L9EBF
        jsr     L9EDB
        jsr     done_dialog_phase1
        jmp     L8F4F

L8F7E:  lda     #$80
        sta     L918C
        lda     #$C0
        sta     L9189
        tsx
        stx     stack_stash
        jsr     LA248
        jsr     L9984
        jsr     LA271
        jsr     L99BC
        jmp     L8F3F

;;; ============================================================
;;; Lock

do_lock:  jsr     L8FDD
        jmp     L8F4F

do_unlock:  jsr     L8FE1
        jmp     L8F4F

L8FA7:  asl     a
        tay
        copy16  icon_entry_address_table,y, $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        rts

do_get_size:  lda     #$00
        sta     L918C
        lda     #$C0
        sta     L9189
        jmp     L8FEB

L8FC5:  lda     LEBFC
        cmp     #$01
        bne     L8FD0
        lda     #$80
        bne     L8FD2
L8FD0:  lda     #$00
L8FD2:  sta     L918A
        lda     #0
        sta     L9189
        jmp     L8FEB

L8FDD:  lda     #$00
        beq     L8FE3
L8FE1:  lda     #$80
L8FE3:  sta     unlock_flag
        lda     #$80
        sta     L9189
L8FEB:  tsx
        stx     stack_stash
        lda     #$00
        sta     LE05C
        jsr     L91D5
        lda     L9189
        beq     :+
        jmp     L908C

:       bit     L918A
        bpl     L9011
        lda     selected_window_index
        beq     :+
        jmp     L908C

:       pla
        pla
        jmp     JT_EJECT

L9011:  lda     LEBFC
        bpl     L9032
        and     #$7F
        asl     a
        tax
        copy16  window_address_table,x, $08
        copy16  #L917B, $06
        jsr     join_paths
        jmp     L9076

L9032:  jsr     L8FA7
        and     #$0F
        beq     L9051
        asl     a
        tax
        copy16  window_address_table,x, $08
        lda     LEBFC
        jsr     icon_entry_name_lookup
        jsr     join_paths
        jmp     L9076

L9051:  lda     LEBFC
        jsr     icon_entry_name_lookup
        ldy     #$01
        lda     #'/'
        sta     ($06),y
        dey
        lda     ($06),y
        sta     @compare
        sta     path_buf3,y
:       iny
        lda     ($06),y
        sta     path_buf3,y
        @compare := *+1
        cpy     #$00            ; self-modified
        bne     :-
        ldy     #$01
        lda     #' '
        sta     ($06),y
L9076:  ldy     #$FF
L9078:  iny
        lda     path_buf3,y
        sta     path_buf4,y
        cpy     path_buf3
        bne     L9078
        lda     path_buf4
        beq     L908C
        dec     path_buf4
L908C:  lda     #$00
        sta     L97E4
        jsr     LA248
        bit     L9189
        bvs     L90B4
        bmi     L90AE
        bit     L918A
        bmi     L90A6
        jsr     L993E
        jmp     L90DE

L90A6:  lda     #$06
        jsr     L9E7E
        jmp     L90DE

L90AE:  jsr     LA059
        jmp     L90DE

L90B4:  jsr     LA1E4
        jmp     L90DE

L90BA:  bit     L9189
        bvs     L90D8
        bmi     L90D2
        bit     L918A
        bmi     L90CC
        jsr     L9968
        jmp     L90DE

L90CC:  jsr     L9EBF
        jmp     L90DE

L90D2:  jsr     LA0DF
        jmp     L90DE

L90D8:  jsr     LA241
        jmp     L90DE

L90DE:  jsr     L91F5
        lda     selected_icon_count
        bne     L90E9
        jmp     L9168

L90E9:  ldx     #$00
        stx     L917A
L90EE:  jsr     L91F5
        ldx     L917A
        lda     selected_icon_list,x
        cmp     #$01
        beq     L9140
        jsr     icon_entry_name_lookup
        jsr     join_paths
        copy16  #path_buf3, $06
        ldy     #$00
        lda     ($06),y
        beq     L9114
        sec
        sbc     #$01
        sta     ($06),y
L9114:  lda     L97E4
        beq     L913D
        bit     L9189
        bmi     L912F
        bit     L918A
        bmi     L9129
        jsr     L9A01
        jmp     L9140

L9129:  jsr     L9EDB
        jmp     L9140

L912F:  bvs     L9137
        jsr     LA114
        jmp     L9140

L9137:  jsr     LA271
        jmp     L9140

L913D:  jsr     LA271
L9140:  inc     L917A
        ldx     L917A
        cpx     selected_icon_count
        bne     L90EE
        lda     L97E4
        bne     L9168
        inc     L97E4
        bit     L9189
        bmi     L915D
        bit     L918A
        bpl     L9165
L915D:  jsr     done_dialog_phase2
        bit     L9189
        bvs     L9168
L9165:  jmp     L90BA

L9168:  jsr     done_dialog_phase1
        lda     LEBFC
        jsr     icon_entry_name_lookup
        ldy     #$01
        lda     #' '
        sta     ($06),y
        return  #0

L917A:  .byte   0
L917B:  .byte   0
.endproc
        do_delete_file := cmds::do_delete_file
        L8F7E := cmds::L8F7E
        do_copy_file := cmds::do_copy_file
        do_lock := cmds::do_lock
        do_unlock := cmds::do_unlock
        do_get_size := cmds::do_get_size
        L8FC5 := cmds::L8FC5

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

L9189:  .byte   0
L918A:  .byte   0

        ;; high bit set = unlock, clear = lock
unlock_flag:
        .byte   0

L918C:  .byte   0
L918D:  .byte   0

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

L91D5:  yax_call JT_MGTK_RELAY, MGTK::InitPort, grafport3
        yax_call JT_MGTK_RELAY, MGTK::SetPort, grafport3
        rts

L91E8:  jsr     JT_REDRAW_ALL
        yax_call JT_DESKTOP_RELAY, $C, 0
        rts

.proc L91F5
        copy16  #L9211, $08
        lda     selected_window_index
        beq     L9210
        asl     a
        tax
        copy16  window_address_table,x, $08
        lda     #$00
L9210:  rts

L9211:  .addr   0
.endproc

;;; ============================================================

.proc do_eject
        lda     selected_icon_count
        bne     :+
        rts
:       ldx     selected_icon_count
        stx     L0800
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
        cpx     L0800
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

        ;; Compute control_unit_number from unit_number
        lda     unit_number
        pha
        rol     a
        pla
        php
        and     #$20
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        plp
        adc     #1
        sta     control_unit_number

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

        .byte   0               ; unused???
.endproc

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params5, $220

        DEFINE_READ_BLOCK_PARAMS block_params, $0800, $A

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

        ora     #$F0            ; is it $Cn ?
        cmp     #$C0            ; leave Z flag set if so
        rts
.endproc

;;; ============================================================
;;; Look up SmartPort dispatch address.
;;; Input: A = unit number
;;; Output: Z set if SP, $0A/$0B dispatch address; Z clear if not SP

.proc find_smartport_dispatch_address
        sp_addr := $0A

        jsr     device_driver_address
        bne     exit            ; RAM-based driver

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

        lda     #0              ; exit with Z set on success

exit:   rts
.endproc

        PAD_TO $92E7            ; Maintain offsets

;;; ============================================================
;;; Get Info

.proc do_get_info
        lda     selected_icon_count
        bne     :+
        rts

:       lda     #$00
        sta     get_info_dialog_params::L92E6
        jsr     L91D5
L92F5:  ldx     get_info_dialog_params::L92E6
        cpx     selected_icon_count
        bne     L9300
        jmp     L9534

L9300:  lda     selected_window_index
        beq     L9331
        asl     a
        tax
        copy16  window_address_table,x, $08
        ldx     get_info_dialog_params::L92E6
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        jsr     join_paths
        ldy     #$00
L931F:  lda     path_buf3,y
        sta     $220,y
        iny
        cpy     $220
        bne     L931F
        dec     $220
        jmp     L9356

L9331:  ldx     get_info_dialog_params::L92E6
        lda     selected_icon_list,x
        cmp     #$01
        bne     L933E
        jmp     L952E

L933E:  jsr     icon_entry_name_lookup
        ldy     #$00
L9343:  lda     ($06),y
        sta     $220,y
        iny
        cpy     $220
        bne     L9343
        dec     $220
        lda     #'/'
        sta     $0220+1
L9356:  yax_call JT_MLI_RELAY, GET_FILE_INFO, get_file_info_params5
        beq     L9366
        jsr     show_error_alert
        beq     L9356
L9366:  lda     selected_window_index
        beq     L9387
        lda     #$80
        sta     get_info_dialog_params::L92E3
        lda     get_info_dialog_params::L92E6
        clc
        adc     #$01
        cmp     selected_icon_count
        beq     L9381
        inc     get_info_dialog_params::L92E3
        inc     get_info_dialog_params::L92E3
L9381:  jsr     launch_get_info_dialog
        jmp     L93DB

L9387:  lda     #$81
        sta     get_info_dialog_params::L92E3
        lda     get_info_dialog_params::L92E6
        clc
        adc     #$01
        cmp     selected_icon_count
        beq     L939D
        inc     get_info_dialog_params::L92E3
        inc     get_info_dialog_params::L92E3
L939D:  jsr     launch_get_info_dialog
        lda     #$00
        sta     L942E
        ldx     get_info_dialog_params::L92E6
        lda     selected_icon_list,x
        ldy     #$0F
L93AD:  cmp     device_to_icon_map,y
        beq     L93B8
        dey
        bpl     L93AD
        jmp     L93DB

L93B8:  lda     DEVLST,y
        sta     block_params::unit_num
        yax_call JT_MLI_RELAY, READ_BLOCK, block_params
        bne     L93DB
        yax_call JT_MLI_RELAY, WRITE_BLOCK, block_params
        cmp     #ERR_WRITE_PROTECTED
        bne     L93DB
        lda     #$80
        sta     L942E
L93DB:  ldx     get_info_dialog_params::L92E6
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        lda     #$01
        sta     get_info_dialog_params::L92E3
        copy16  $06, get_info_dialog_params::L92E4
        jsr     launch_get_info_dialog
        lda     #$02
        sta     get_info_dialog_params::L92E3
        lda     selected_window_index
        bne     L9413
        bit     L942E
        bmi     L940C
        lda     #$00
        sta     get_info_dialog_params::L92E4
        beq     L9428
L940C:  lda     #$01
        sta     get_info_dialog_params::L92E4
        bne     L9428
L9413:  lda     get_file_info_params5::access
        and     #$C3
        cmp     #$C3
        beq     L9423
        lda     #$01
        sta     get_info_dialog_params::L92E4
        bne     L9428
L9423:  lda     #$00
        sta     get_info_dialog_params::L92E4
L9428:  jsr     launch_get_info_dialog
        jmp     L942F

L942E:  .byte   0

L942F:  lda     #$03
        sta     get_info_dialog_params::L92E3

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
        jsr     launch_get_info_dialog

        lda     #$04
        sta     get_info_dialog_params::L92E3
        copy16  get_file_info_params5::create_date, date
        jsr     JT_DATE_STRING
        copy16  #text_buffer2::length, get_info_dialog_params::L92E4
        jsr     launch_get_info_dialog
        lda     #$05
        sta     get_info_dialog_params::L92E3
        copy16  get_file_info_params5::mod_date, date
        jsr     JT_DATE_STRING
        copy16  #text_buffer2::length, get_info_dialog_params::L92E4
        jsr     launch_get_info_dialog

        lda     #$06
        sta     get_info_dialog_params::L92E3
        lda     selected_window_index
        bne     L9519
        ldx     str_vol
L950E:  lda     str_vol,x
        sta     str_file_type,x
        dex
        bpl     L950E
        bmi     L951F
L9519:  lda     get_file_info_params5::file_type
        jsr     JT_FILE_TYPE_STRING
L951F:  copy16  #str_file_type, get_info_dialog_params::L92E4
        jsr     launch_get_info_dialog
        bne     L9534
L952E:  inc     get_info_dialog_params::L92E6
        jmp     L92F5

L9534:  lda     #$00
        sta     path_buf4
        rts

str_vol:
        PASCAL_STRING " VOL"

.proc launch_get_info_dialog
        yax_call launch_dialog, index_get_info_dialog, get_info_dialog_params
        rts
.endproc
.endproc
        L92F5 := do_get_info::L92F5

;;; ============================================================

        PAD_TO $9569            ; Maintain previous addresses

;;; ============================================================

.proc do_rename_icon_impl

        DEFINE_RENAME_PARAMS rename_params, $220, path_buf_main

rename_dialog_params:
        .byte   0
        .addr   $1F00

start:
        lda     #$00
        sta     L9706
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
        copy16  window_address_table,x, $08
        ldx     L9706
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        jsr     join_paths
        ldy     #$00
L95B0:  lda     path_buf3,y
        sta     $220,y
        iny
        cpy     $220
        bne     L95B0
        dec     $220
        jmp     L95E0

L95C2:  ldx     L9706
        lda     selected_icon_list,x
        jsr     icon_entry_name_lookup
        ldy     #$00
L95CD:  lda     ($06),y
        sta     $220,y
        iny
        cpy     $220
        bne     L95CD
        dec     $220
        lda     #'/'
        sta     $0220+1
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
        copy16  window_address_table,x, $06
        jmp     L9655

L964D:  copy16  #L9705, $06
L9655:  ldy     #$00
        lda     ($06),y
        tay
L965A:  lda     ($06),y
        sta     path_buf_main,y
        dey
        bpl     L965A
        inc     path_buf_main
        ldx     path_buf_main
        lda     #'/'
        sta     path_buf_main,x
        ldy     #$00
        lda     ($08),y
        sta     L9709
L9674:  inx
        iny
        lda     ($08),y
        sta     path_buf_main,x
        cpy     L9709
        bne     L9674
        stx     path_buf_main
        yax_call JT_MLI_RELAY, RENAME, rename_params
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
        sta     LE22B
        yax_call JT_DESKTOP_RELAY, $E, LE22B
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
        yax_call launch_dialog, index_rename_dialog, rename_dialog_params
        rts

L9705:  .byte   $00
L9706:  .byte   $00
L9707:  .byte   $00
L9708:  .byte   $00
L9709:  .byte   $00
.endproc
        do_rename_icon := do_rename_icon_impl::start

;;; ============================================================

        DEFINE_OPEN_PARAMS open_params3, $220, $800
        DEFINE_READ_PARAMS read_params3, L9718, 4

L9718:  .res    4, 0

        DEFINE_CLOSE_PARAMS close_params6
        DEFINE_READ_PARAMS read_params4, L97AD, $27
        DEFINE_READ_PARAMS read_params5, L972E, 5

L972E:  .res    5, 0

        .res    4, 0

        DEFINE_CLOSE_PARAMS close_params5
        DEFINE_CLOSE_PARAMS close_params3
        DEFINE_DESTROY_PARAMS destroy_params, $220
        DEFINE_OPEN_PARAMS open_params4, $220, $0D00
        DEFINE_OPEN_PARAMS open_params5, path_buf_main, $1100
        DEFINE_READ_PARAMS read_params6, $1500, $AC0
        DEFINE_WRITE_PARAMS write_params, $1500, $AC0
        DEFINE_CREATE_PARAMS create_params3, path_buf_main, ACCESS_DEFAULT
        DEFINE_CREATE_PARAMS create_params2, path_buf_main

        .byte   $00,$00

        DEFINE_GET_FILE_INFO_PARAMS file_info_params2, $220

        .byte   0

        DEFINE_GET_FILE_INFO_PARAMS file_info_params3, path_buf_main

        .byte   0

        DEFINE_SET_EOF_PARAMS set_eof_params, 0
        DEFINE_SET_MARK_PARAMS mark_params, 0
        DEFINE_SET_MARK_PARAMS mark_params2, 0
        DEFINE_ON_LINE_PARAMS on_line_params2,, $800


;;; ============================================================


L97AD:  .res    16, 0
L97BD:  .res    32, 0

L97DD:  .addr   L9B36
L97DF:  .addr   L9B33
L97E1:  .addr   rts2

rts2:   rts

L97E4:  .byte   $00


L97E5:  ldx     LE10C
        lda     LE061
        sta     LE062,x
        inx
        stx     LE10C
        rts

L97F3:  ldx     LE10C
        dex
        lda     LE062,x
        sta     LE061
        stx     LE10C
        rts

.proc L9801
        lda     #$00
        sta     LE05F
        sta     LE10D
L9809:  yax_call JT_MLI_RELAY, OPEN, open_params3
        beq     L981E
        ldx     #$80
        jsr     JT_SHOW_ALERT
        beq     L9809
        jmp     close_files_cancel_dialog

L981E:  lda     open_params3::ref_num
        sta     LE060
        sta     read_params3::ref_num
L9827:  yax_call JT_MLI_RELAY, READ, read_params3
        beq     L983C
        ldx     #$80
        jsr     JT_SHOW_ALERT
        beq     L9827
        jmp     close_files_cancel_dialog

L983C:  jmp     L985B
.endproc

.proc L983F
        lda     LE060
        sta     close_params6::ref_num
L9845:  yax_call JT_MLI_RELAY, CLOSE, close_params6
        beq     L985A
        ldx     #$80
        jsr     JT_SHOW_ALERT
        beq     L9845
        jmp     close_files_cancel_dialog

L985A:  rts
.endproc

.proc L985B
        inc     LE05F
        lda     LE060
        sta     read_params4::ref_num
L9864:  yax_call JT_MLI_RELAY, READ, read_params4
        beq     L987D
        cmp     #$4C
        beq     L989F
        ldx     #$80
        jsr     JT_SHOW_ALERT
        beq     L9864
        jmp     close_files_cancel_dialog

L987D:  inc     LE10D
        lda     LE10D
        cmp     LE05E
        bcc     L989C
        lda     #$00
        sta     LE10D
        lda     LE060
        sta     read_params5::ref_num
        yax_call JT_MLI_RELAY, READ, read_params5
L989C:  return  #0

L989F:  return  #$FF
.endproc

;;; ============================================================

L98A2:  lda     LE05F
        sta     LE061
        jsr     L983F
        jsr     L97E5
        jsr     append_to_path_220
        jmp     L9801

.proc L98B4
        jsr     L983F
        jsr     L992A
        jsr     remove_path_segment_220
        jsr     L97F3
        jsr     L9801
        jsr     sub
        jmp     L9927

sub:    lda     LE05F
        cmp     LE061
        beq     done
        jsr     L985B
        jmp     sub
done:   rts
.endproc

.proc L98D8
        lda     #$00
        sta     LE05D
        jsr     L9801
L98E0:  jsr     L985B
        bne     L9912
        lda     L97AD
        beq     L98E0
        lda     L97AD
        sta     L992D
        and     #$0F
        sta     L97AD
        lda     #$00
        sta     L9923
        jsr     L9924
        lda     L9923
        bne     L98E0
        lda     L97BD
        cmp     #$0F
        bne     L98E0
        jsr     L98A2
        inc     LE05D
        jmp     L98E0

L9912:  lda     LE05D
        beq     L9920
        jsr     L98B4
        dec     LE05D
        jmp     L98E0

L9920:  jmp     L983F
.endproc

L9923:  .byte   0
L9924:  jmp     (L97DD)
L9927:  jmp     (L97DF)
L992A:  jmp     (L97E1)

L992D:  .byte   $00,$00,$00,$00
L9931:  .addr   L9B36           ; Overlay for L97DD
        .addr   L9B33
        .addr   rts2

.proc copy_dialog_params
        .byte   0
count:  .addr   0
        .addr   $220
        .addr   path_buf_main
.endproc

.proc L993E
        lda     #0
        sta     copy_dialog_params
        copy16  #L995A, dialog_phase0_callback
        copy16  #L997C, dialog_phase1_callback
        jmp     L9BBF

L995A:  stax    copy_dialog_params::count
        lda     #1
        sta     copy_dialog_params
        jmp     L9BBF
.endproc

L9968:  ldy     #5
L996A:  lda     L9931,y
        sta     L97DD,y
        dey
        bpl     L996A
        lda     #$00
        sta     LA425
        sta     L918D
        rts

L997C:  lda     #5
        sta     copy_dialog_params
        jmp     L9BBF

L9984:  lda     #0
        sta     copy_dialog_params
        copy16  #L99A7, dialog_phase0_callback
        copy16  #L99DC, dialog_phase1_callback
        yax_call launch_dialog, index_download_dialog, copy_dialog_params
        rts

L99A7:  stax    copy_dialog_params::count
        lda     #1
        sta     copy_dialog_params
        yax_call launch_dialog, index_download_dialog, copy_dialog_params
        rts

L99BC:  lda     #$80
        sta     L918D
        ldy     #5
L99C3:  lda     L9931,y
        sta     L97DD,y
        dey
        bpl     L99C3
        lda     #0
        sta     LA425
        copy16  #L99EB, dialog_phase3_callback
        rts

L99DC:  lda     #3
        sta     copy_dialog_params
        yax_call launch_dialog, index_download_dialog, copy_dialog_params
        rts

L99EB:  lda     #4
        sta     copy_dialog_params
        yax_call launch_dialog, index_download_dialog, copy_dialog_params
        cmp     #2
        bne     L99FE
        rts

L99FE:  jmp     close_files_cancel_dialog

;;; ============================================================

.proc L9A01
        copy16  #$0080, LE05B
        beq     L9A0F
L9A0D:  lda     #$FF
L9A0F:  sta     L9B31
        lda     #2
        sta     copy_dialog_params
        jsr     LA379
        bit     L9189
        bvc     L9A22
        jsr     L9BC9
L9A22:  bit     LE05B
        bpl     L9A70
        bvs     L9A50
        lda     L9B31
        bne     L9A36
        lda     selected_window_index
        bne     L9A36
        jmp     L9B28

L9A36:  ldx     path_buf_main
        ldy     L9B32
        dey
L9A3D:  iny
        inx
        lda     $220,y
        sta     path_buf_main,x
        cpy     $220
        bne     L9A3D
        stx     path_buf_main
        jmp     L9A70

L9A50:  ldx     path_buf_main
        lda     #'/'
        sta     path_buf_main+1,x
        inc     path_buf_main
        ldy     #$00
        ldx     path_buf_main
L9A60:  iny
        inx
        lda     filename_buf,y
        sta     path_buf_main,x
        cpy     filename_buf
        bne     L9A60
        stx     path_buf_main
L9A70:  yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params2
        beq     L9A81
        jsr     show_error_alert
        jmp     L9A70

L9A81:  lda     file_info_params2::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     L9A90
        cmp     #ST_LINKED_DIRECTORY
        beq     L9A90
        lda     #$00
        beq     L9A95
L9A90:  jsr     decrement_LA2ED
        lda     #$FF
L9A95:  sta     L9B30
        jsr     LA40A
        lda     LA2ED+1
        bne     L9AA8
        lda     LA2ED
        bne     L9AA8
        jmp     close_files_cancel_dialog

L9AA8:  ldy     #$07
L9AAA:  lda     file_info_params2,y
        sta     create_params2,y
        dey
        cpy     #$02
        bne     L9AAA
        lda     #ACCESS_DEFAULT
        sta     create_params2::access
        lda     LE05B
        beq     L9B23
        jsr     L9C01
        bcs     L9B2C
        ldy     #$11
        ldx     #$0B
L9AC8:  lda     file_info_params2,y
        sta     create_params2,x
        dex
        dey
        cpy     #$0D
        bne     L9AC8
        lda     create_params2::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     L9AE0
        lda     #ST_LINKED_DIRECTORY
        sta     create_params2::storage_type
L9AE0:  yax_call JT_MLI_RELAY, CREATE, create_params2
        beq     L9B23
        cmp     #$47
        bne     L9B1D
        bit     L918D
        bmi     L9B14
        lda     #3
        sta     copy_dialog_params
        jsr     L9BBF
        pha
        lda     #2
        sta     copy_dialog_params
        pla
        cmp     #$02
        beq     L9B14
        cmp     #$03
        beq     L9B2C
        cmp     #$04
        bne     L9B1A
        lda     #$80
        sta     L918D
L9B14:  jsr     LA426
        jmp     L9B23

L9B1A:  jmp     close_files_cancel_dialog

L9B1D:  jsr     show_error_alert
        jmp     L9AE0

L9B23:  lda     L9B30
        beq     L9B2D
L9B28:  jmp     L98D8

        .byte   0
L9B2C:  rts

L9B2D:  jmp     L9CDA

L9B30:  .byte   0
L9B31:  .byte   0
.endproc
        L9A0D := L9A01::L9A0D

L9B32:  .byte   0


;;; ============================================================

L9B33:  jmp     LA360

;;; ============================================================

.proc L9B36
        jsr     check_escape_key_down
        beq     :+
        jmp     close_files_cancel_dialog
:       lda     L97BD
        cmp     #$0F
        bne     L9B88
        jsr     append_to_path_220
:       yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params2
        beq     L9B59
        jsr     show_error_alert
        jmp     :-

L9B59:  jsr     LA33B
        jsr     LA40A
        jsr     decrement_LA2ED
        lda     LA2ED+1
        bne     L9B6F
        lda     LA2ED
        bne     L9B6F
        jmp     close_files_cancel_dialog

L9B6F:  jsr     L9E19
        bcs     L9B7A
        jsr     remove_path_segment_220
        jmp     L9BBE

L9B7A:  jsr     LA360
        jsr     remove_path_segment_220
        lda     #$FF
        sta     L9923
        jmp     L9BBE

L9B88:  jsr     LA33B
        jsr     append_to_path_220
        jsr     LA40A
L9B91:  yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params2
        beq     L9BA2
        jsr     show_error_alert
        jmp     L9B91

L9BA2:  jsr     L9C01
        bcc     L9BAA
        jmp     close_files_cancel_dialog

L9BAA:  jsr     remove_path_segment_220
        jsr     L9E19
        bcs     L9BBB
        jsr     append_to_path_220
        jsr     L9CDA
        jsr     remove_path_segment_220
L9BBB:  jsr     LA360
L9BBE:  rts
.endproc

;;; ============================================================

L9BBF:  yax_call launch_dialog, index_copy_file_dialog, copy_dialog_params
        rts

;;; ============================================================

.proc L9BC9
        yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params3
        beq     L9BDA
        jsr     show_error_alert_dst
        jmp     L9BC9

L9BDA:  sub16   file_info_params3::aux_type, file_info_params3::blocks_used, L9BFF
        cmp16   L9BFF, LA2EF
        bcs     L9BFE
        jmp     done_dialog_phase3

L9BFE:  rts

L9BFF:  .word   0
.endproc

;;; ============================================================

.proc L9C01
        jsr     L9C1A
        bcc     done
        lda     #4
        sta     copy_dialog_params
        jsr     L9BBF
        beq     :+
        jmp     close_files_cancel_dialog
:       lda     #3
        sta     copy_dialog_params
        sec
done:   rts

.proc L9C1A
        yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params2
        beq     L9C2B
        jsr     show_error_alert
        jmp     L9C1A

L9C2B:  lda     #$00
        sta     L9CD8
        sta     L9CD9
L9C33:  yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params3
        beq     L9C48
        cmp     #$46
        beq     L9C54
        jsr     show_error_alert_dst
        jmp     L9C33

L9C48:  copy16  file_info_params3::blocks_used, L9CD8
L9C54:  lda     path_buf_main
        sta     L9CD6
        ldy     #$01
L9C5C:  iny
        cpy     path_buf_main
        bcs     L9CCC
        lda     path_buf_main,y
        cmp     #'/'
        bne     L9C5C
        tya
        sta     path_buf_main
        sta     L9CD7
L9C70:  yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params3
        beq     L9C95
        pha
        lda     L9CD6
        sta     path_buf_main
        pla
        jsr     show_error_alert_dst
        jmp     L9C70

        lda     L9CD7
        sta     path_buf_main
        jmp     L9C70

        jmp     close_files_cancel_dialog

L9C95:  sub16   file_info_params3::aux_type, file_info_params3::blocks_used, L9CD4
        add16   L9CD4, L9CD8, L9CD4
        cmp16   L9CD4, file_info_params2::blocks_used
        bcs     L9CCC
        sec
        bcs     L9CCD
L9CCC:  clc
L9CCD:  lda     L9CD6
        sta     path_buf_main
        rts

L9CD4:  .word   0
L9CD6:  .byte   0
L9CD7:  .byte   0
L9CD8:  .byte   0
L9CD9:  .byte   0
.endproc
.endproc

;;; ============================================================

.proc L9CDA
        jsr     decrement_LA2ED
        lda     #$00
        sta     L9E17
        sta     L9E18
        sta     mark_params::position
        sta     mark_params::position+1
        sta     mark_params::position+2
        sta     mark_params2::position
        sta     mark_params2::position+1
        sta     mark_params2::position+2
        jsr     L9D62
        jsr     L9D74
        jsr     L9D81
        beq     L9D09
        lda     #$FF
        sta     L9E17
        bne     L9D0C
L9D09:  jsr     L9D9C
L9D0C:  jsr     L9DA9
        bit     L9E17
        bpl     L9D28
        jsr     L9E0D
L9D17:  jsr     L9D81
        bne     L9D17
        jsr     L9D9C
        yax_call JT_MLI_RELAY, SET_MARK, mark_params2
L9D28:  bit     L9E18
        bmi     L9D51
        jsr     L9DE8
        bit     L9E17
        bpl     L9D0C
        jsr     L9E03
        jsr     L9D62
        jsr     L9D74
        yax_call JT_MLI_RELAY, SET_MARK, mark_params
        beq     L9D0C
        lda     #$FF
        sta     L9E18
        jmp     L9D0C

L9D51:  jsr     L9E03
        bit     L9E17
        bmi     L9D5C
        jsr     L9E0D
L9D5C:  jsr     LA46D
        jmp     LA479

L9D62:  yax_call JT_MLI_RELAY, OPEN, open_params4
        beq     L9D73
        jsr     show_error_alert
        jmp     L9D62

L9D73:  rts

L9D74:  lda     open_params4::ref_num
        sta     read_params6::ref_num
        sta     close_params5::ref_num
        sta     mark_params::ref_num
        rts

L9D81:  yax_call JT_MLI_RELAY, OPEN, open_params5
        beq     L9D9B
        cmp     #ERR_VOL_NOT_FOUND
        beq     L9D96
        jsr     show_error_alert_dst
        jmp     L9D81

L9D96:  jsr     show_error_alert_dst
        lda     #ERR_VOL_NOT_FOUND
L9D9B:  rts

L9D9C:  lda     open_params5::ref_num
        sta     write_params::ref_num
        sta     close_params3::ref_num
        sta     mark_params2::ref_num
        rts

L9DA9:  copy16  #$0AC0, read_params6::request_count
L9DB3:  yax_call JT_MLI_RELAY, READ, read_params6
        beq     L9DC8
        cmp     #ERR_END_OF_FILE
        beq     L9DD9
        jsr     show_error_alert
        jmp     L9DB3

L9DC8:  copy16  read_params6::trans_count, write_params::request_count
        ora     read_params6::trans_count
        bne     L9DDE
L9DD9:  lda     #$FF
        sta     L9E18
L9DDE:  yax_call JT_MLI_RELAY, GET_MARK, mark_params
        rts

L9DE8:  yax_call JT_MLI_RELAY, WRITE, write_params
        beq     L9DF9
        jsr     show_error_alert_dst
        jmp     L9DE8

L9DF9:  yax_call JT_MLI_RELAY, GET_MARK, mark_params2
        rts

L9E03:  yax_call JT_MLI_RELAY, CLOSE, close_params3
        rts

L9E0D:  yax_call JT_MLI_RELAY, CLOSE, close_params5
        rts

L9E17:  .byte   0
L9E18:  .byte   0

.endproc


.proc L9E19
        ldx     #$07
L9E1B:  lda     file_info_params2,x
        sta     create_params3,x
        dex
        cpx     #$03
        bne     L9E1B
L9E26:  yax_call JT_MLI_RELAY, CREATE, create_params3
        beq     L9E6F
        cmp     #ERR_DUPLICATE_FILENAME
        bne     L9E69
        bit     L918D
        bmi     L9E60
        lda     #3
        sta     copy_dialog_params
        yax_call launch_dialog, index_copy_file_dialog, copy_dialog_params
        pha
        lda     #2
        sta     copy_dialog_params
        pla
        cmp     #$02
        beq     L9E60
        cmp     #$03
        beq     L9E71
        cmp     #$04
        bne     L9E66
        lda     #$80
        sta     L918D
L9E60:  jsr     LA426
        jmp     L9E6F

L9E66:  jmp     close_files_cancel_dialog

L9E69:  jsr     show_error_alert_dst
        jmp     L9E26

L9E6F:  clc
        rts

L9E71:  sec
        rts
.endproc

L9E73:  .addr   L9F94           ; Overlay for L97DD
        .addr   rts2
        .addr   destroy_with_retry

.proc delete_file_dialog_params
phase:  .byte   0
count:  .word   0
        .addr   $220
.endproc

.proc L9E7E
        sta     delete_file_dialog_params::phase
        copy16  #L9EB1, dialog_phase2_callback
        copy16  #L9EA3, dialog_phase0_callback
        jsr     LA044
        copy16  #L9ED3, dialog_phase1_callback
        rts

L9EA3:  stax    delete_file_dialog_params::count
        copy    #1, delete_file_dialog_params::phase
        jmp     LA044

L9EB1:  copy    #2, delete_file_dialog_params::phase
        jsr     LA044
        beq     L9EBE
        jmp     close_files_cancel_dialog

L9EBE:  rts
.endproc

;;; ============================================================

.proc L9EBF
        ldy     #5
:       lda     L9E73,y
        sta     L97DD,y
        dey
        bpl     :-
        lda     #$00
        sta     LA425
        sta     L918D
        rts
.endproc

.proc L9ED3
        copy    #5, delete_file_dialog_params::phase
        jmp     LA044
.endproc

;;; ============================================================

.proc L9EDB
        copy    #3, delete_file_dialog_params::phase
        jsr     LA379
L9EE3:  yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params2
        beq     L9EF4
        jsr     show_error_alert
        jmp     L9EE3

L9EF4:  lda     file_info_params2::storage_type
        sta     L9F1D
        cmp     #ST_LINKED_DIRECTORY
        beq     L9F02
        lda     #$00
        beq     L9F04
L9F02:  lda     #$FF
L9F04:  sta     L9F1C
        beq     L9F1E
        jsr     L98D8
        lda     L9F1D
        cmp     #$0D
        bne     L9F18
        lda     #$FF
        sta     L9F1D
L9F18:  jmp     L9F1E

        rts

L9F1C:  .byte   0
L9F1D:  .byte   0

L9F1E:  bit     LE05C
        bmi     L9F26
        jsr     LA3EF
L9F26:  jsr     decrement_LA2ED
L9F29:  yax_call JT_MLI_RELAY, DESTROY, destroy_params
        beq     L9F8D
        cmp     #ERR_ACCESS_ERROR
        bne     L9F8E
        bit     L918D
        bmi     L9F62
        copy    #4, delete_file_dialog_params::phase
        jsr     LA044
        pha
        copy    #3, delete_file_dialog_params::phase
        pla
        cmp     #3
        beq     L9F8D
        cmp     #2
        beq     L9F62
        cmp     #4
        bne     L9F5F
        lda     #$80
        sta     L918D
        bne     L9F62
L9F5F:  jmp     close_files_cancel_dialog

L9F62:  yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params2
        lda     file_info_params2::access
        and     #$80
        bne     L9F8D
        lda     #ACCESS_DEFAULT
        sta     file_info_params2::access
        lda     #7              ; param count for SET_FILE_INFO
        sta     file_info_params2
        yax_call JT_MLI_RELAY, SET_FILE_INFO, file_info_params2
        lda     #$A             ; param count for GET_FILE_INFO
        sta     file_info_params2
        jmp     L9F29

L9F8D:  rts

L9F8E:  jsr     show_error_alert
        jmp     L9F29
.endproc

;;; ============================================================

.proc L9F94
        jsr     check_escape_key_down
        beq     :+
        jmp     close_files_cancel_dialog
:       jsr     append_to_path_220
        bit     LE05C
        bmi     L9FA7
        jsr     LA3EF
L9FA7:  jsr     decrement_LA2ED
L9FAA:  yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params2
        beq     L9FBB
        jsr     show_error_alert
        jmp     L9FAA

L9FBB:  lda     file_info_params2::storage_type
        cmp     #ST_LINKED_DIRECTORY
        beq     LA022
L9FC2:  yax_call JT_MLI_RELAY, DESTROY, destroy_params
        beq     LA022
        cmp     #ERR_ACCESS_ERROR
        bne     LA01C
        bit     L918D
        bmi     LA001
        copy    #4, delete_file_dialog_params::phase
        yax_call launch_dialog, index_delete_file_dialog, delete_file_dialog_params
        pha
        copy    #3, delete_file_dialog_params::phase
        pla
        cmp     #$03
        beq     LA022
        cmp     #$02
        beq     LA001
        cmp     #$04
        bne     L9FFE
        lda     #$80
        sta     L918D
        bne     LA001
L9FFE:  jmp     close_files_cancel_dialog

LA001:  lda     #ACCESS_DEFAULT
        sta     file_info_params2::access
        copy    #7, file_info_params2 ; param count for SET_FILE_INFO
        yax_call JT_MLI_RELAY, SET_FILE_INFO, file_info_params2
        copy    #$A,file_info_params2 ; param count for GET_FILE_INFO
        jmp     L9FC2

LA01C:  jsr     show_error_alert
        jmp     L9FC2

LA022:  jmp     remove_path_segment_220

        jsr     remove_path_segment_220
        lda     #$FF
        sta     L9923
        rts
.endproc

;;; ============================================================

.proc destroy_with_retry
retry:  yax_call JT_MLI_RELAY, DESTROY, destroy_params
        beq     done
        cmp     #ERR_ACCESS_ERROR
        beq     done
        jsr     show_error_alert
        jmp     retry
done:   rts
.endproc

LA044:  yax_call launch_dialog, index_delete_file_dialog, delete_file_dialog_params
        rts

LA04E:  .addr   LA170
        .addr   rts2
        .addr   rts2

;;; 0 = opening window, initial label
;;; 1 = show operation details (e.g. file count)
;;; 2 = draw buttons, input loop
;;; 3 = performing operation
;;; 4 = destroy window

.enum LockDialogLifecycle
        open      = 0
        populate  = 1
        loop      = 2
        operation = 3
        destroy   = 4
.endenum

.proc lock_unlock_dialog_params
phase:  .byte   0
files_remaining_count:
        .word   0
        .addr   $220
.endproc

.proc LA059
        copy    #LockDialogLifecycle::open, lock_unlock_dialog_params::phase
        bit     unlock_flag
        bpl     lock

        copy16  #LA0D1, dialog_phase2_callback
        copy16  #LA0B5, dialog_phase0_callback
        jsr     unlock_dialog_lifecycle
        copy16  #LA0F8, dialog_phase1_callback
        rts

lock:   copy16  #LA0C3, dialog_phase2_callback
        copy16  #LA0A7, dialog_phase0_callback
        jsr     lock_dialog_lifecycle
        copy16  #LA0F0, dialog_phase1_callback
        rts
.endproc

LA0A7:  stax    lock_unlock_dialog_params::files_remaining_count
        copy    #LockDialogLifecycle::populate, lock_unlock_dialog_params::phase
        jmp     lock_dialog_lifecycle

LA0B5:  stax    lock_unlock_dialog_params::files_remaining_count
        copy    #LockDialogLifecycle::populate, lock_unlock_dialog_params::phase
        jmp     unlock_dialog_lifecycle

LA0C3:  copy    #LockDialogLifecycle::loop, lock_unlock_dialog_params::phase
        jsr     lock_dialog_lifecycle
        beq     LA0D0
        jmp     close_files_cancel_dialog

LA0D0:  rts

LA0D1:  copy    #LockDialogLifecycle::loop, lock_unlock_dialog_params::phase
        jsr     unlock_dialog_lifecycle
        beq     LA0DE
        jmp     close_files_cancel_dialog

LA0DE:  rts

.proc LA0DF
        lda     #$00
        sta     LA425
        ldy     #$05
:       lda     LA04E,y
        sta     L97DD,y
        dey
        bpl     :-
        rts
.endproc

LA0F0:  copy    #LockDialogLifecycle::destroy, lock_unlock_dialog_params::phase
        jmp     lock_dialog_lifecycle

LA0F8:  copy    #LockDialogLifecycle::destroy, lock_unlock_dialog_params::phase
        jmp     unlock_dialog_lifecycle

lock_dialog_lifecycle:
        yax_call launch_dialog, index_lock_dialog, lock_unlock_dialog_params
        rts

unlock_dialog_lifecycle:
        yax_call launch_dialog, index_unlock_dialog, lock_unlock_dialog_params
        rts

;;; ============================================================

.proc LA114
        copy    #LockDialogLifecycle::operation, lock_unlock_dialog_params::phase
        jsr     LA379
        ldx     path_buf_main
        ldy     L9B32
        dey
LA123:  iny
        inx
        lda     $220,y
        sta     path_buf_main,x
        cpy     $220
        bne     LA123
        stx     path_buf_main
LA133:  yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params2
        beq     LA144
        jsr     show_error_alert
        jmp     LA133

LA144:  lda     file_info_params2::storage_type
        sta     LA169
        cmp     #ST_VOLUME_DIRECTORY
        beq     LA156
        cmp     #ST_LINKED_DIRECTORY
        beq     LA156
        lda     #$00
        beq     LA158
LA156:  lda     #$FF
LA158:  sta     LA168
        beq     LA16A
        jsr     L98D8
        lda     LA169
        cmp     #$0F
        bne     LA16A
        rts

LA168:  .byte   0
LA169:  .byte   0
LA16A:  jsr     LA173
        jmp     append_to_path_220
.endproc

;;; ============================================================

LA170:  jsr     append_to_path_220
        ;; fall through

.proc LA173
        jsr     LA1C3
        jsr     decrement_LA2ED
:       yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params2
        beq     :+
        jsr     show_error_alert
        jmp     :-
:       lda     file_info_params2::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     LA1C0
        cmp     #ST_LINKED_DIRECTORY
        beq     LA1C0
        bit     unlock_flag
        bpl     :+
        lda     #ACCESS_DEFAULT
        bne     LA1A0
:       lda     #$21
LA1A0:  sta     file_info_params2::access
LA1A3:  copy    #7, file_info_params2 ; param count for SET_FILE_INFO
        yax_call JT_MLI_RELAY, SET_FILE_INFO, file_info_params2
        pha
        copy    #$A, file_info_params2 ; param count for GET_FILE_INFO
        pla
        beq     LA1C0
        jsr     show_error_alert
        jmp     LA1A3

LA1C0:  jmp     remove_path_segment_220

LA1C3:  sub16   LA2ED, #1, lock_unlock_dialog_params::files_remaining_count
        bit     unlock_flag
        bpl     LA1DC
        jmp     unlock_dialog_lifecycle

LA1DC:  jmp     lock_dialog_lifecycle
.endproc

.proc get_size_dialog_params
phase:  .byte   0
        .addr   LA2ED, LA2EF
.endproc

LA1E4:  copy    #0, get_size_dialog_params::phase
        copy16  #LA220, dialog_phase2_callback
        copy16  #LA211, dialog_phase0_callback
        yax_call launch_dialog, index_get_size_dialog, get_size_dialog_params
        copy16  #LA233, dialog_phase1_callback
        rts

LA211:  copy    #1, get_size_dialog_params::phase
        yax_call launch_dialog, index_get_size_dialog, get_size_dialog_params
LA21F:  rts

LA220:  copy    #2, get_size_dialog_params::phase
        yax_call launch_dialog, index_get_size_dialog, get_size_dialog_params
        beq     LA21F
        jmp     close_files_cancel_dialog

LA233:  copy    #3, get_size_dialog_params::phase
        yax_call launch_dialog, index_get_size_dialog, get_size_dialog_params
LA241:  rts

LA242:  .addr   LA2AE,rts2,rts2

;;; ============================================================

.proc LA248
        copy    #0, LA425
        ldy     #5
LA24F:  lda     LA242,y
        sta     L97DD,y
        dey
        bpl     LA24F
        lda     #0
        sta     LA2ED
        sta     LA2ED+1
        sta     LA2EF
        sta     LA2EF+1
        ldy     #$17
        lda     #$00
LA26A:  sta     BITMAP,y
        dey
        bpl     LA26A
        rts
.endproc

;;; ============================================================

.proc LA271
        jsr     LA379
LA274:  yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params2
        beq     LA285
        jsr     show_error_alert
        jmp     LA274

LA285:  copy    file_info_params2::storage_type, LA2AA
        cmp     #ST_VOLUME_DIRECTORY
        beq     LA297
        cmp     #ST_LINKED_DIRECTORY
        beq     LA297
        lda     #$00
        beq     LA299
LA297:  lda     #$FF
LA299:  sta     LA2A9
        beq     LA2AB
        jsr     L98D8
        lda     LA2AA
        cmp     #$0F
        bne     LA2AB
        rts

LA2A9:  .byte   0
LA2AA:  .byte   0
.endproc

;;; ============================================================

LA2AB:  jmp     LA2AE

LA2AE:  bit     L9189
        bvc     :+
        jsr     append_to_path_220
        yax_call JT_MLI_RELAY, GET_FILE_INFO, file_info_params2
        bne     :+
        add16   LA2EF, file_info_params2::blocks_used, LA2EF
:       inc16     LA2ED
        bit     L9189
        bvc     :+
        jsr     remove_path_segment_220
:       ldax    LA2ED
        jmp     done_dialog_phase0

LA2ED:  .word   0
LA2EF:  .word   0

;;; ============================================================

.proc decrement_LA2ED
        lda     LA2ED
        bne     :+
        dec     LA2ED+1
:       dec     LA2ED
        rts
.endproc

;;; ============================================================
;;; Append name at L97AD to path at $220

.proc append_to_path_220
        path := $220

        lda     L97AD
        bne     :+
        rts

:       ldx     #0
        ldy     path
        copy    #'/', path+1,y

        iny
loop:   cpx     L97AD
        bcs     done
        lda     L97AD+1,x
        sta     path+1,y
        inx
        iny
        jmp     loop

done:   sty     $220
        rts
.endproc

;;; ============================================================
;;; Remove segment from path at $220

.proc remove_path_segment_220
        path := $220

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

.proc LA33B
        lda     L97AD
        bne     LA341
        rts

LA341:  ldx     #$00
        ldy     path_buf_main
        copy    #'/', path_buf_main+1,y
        iny
LA34C:  cpx     L97AD
        bcs     LA35C
        lda     L97AD+1,x
        sta     path_buf_main+1,y
        inx
        iny
        jmp     LA34C

LA35C:  sty     path_buf_main
        rts
.endproc

;;; ============================================================

.proc LA360
        ldx     path_buf_main
        bne     LA366
        rts

LA366:  lda     path_buf_main,x
        cmp     #'/'
        beq     LA374
        dex
        bne     LA366
        stx     path_buf_main
        rts

LA374:  dex
        stx     path_buf_main
        rts
.endproc

;;; ============================================================

.proc LA379
        ldy     #$00
        sty     L9B32
        dey
LA37F:  iny
        lda     path_buf3,y
        cmp     #'/'
        bne     LA38A
        sty     L9B32
LA38A:  sta     $220,y
        cpy     path_buf3
        bne     LA37F
        ldy     path_buf4
LA395:  lda     path_buf4,y
        sta     path_buf_main,y
        dey
        bpl     LA395
        rts
.endproc

;;; ============================================================

.proc close_files_cancel_dialog
        jsr     done_dialog_phase1
        jmp     :+

        DEFINE_CLOSE_PARAMS close_params

:       yax_call JT_MLI_RELAY, CLOSE, close_params
        lda     selected_window_index
        beq     :+
        sta     getwinport_params2::window_id
        yax_call JT_MGTK_RELAY, MGTK::GetWinPort, getwinport_params2
        yax_call JT_MGTK_RELAY, MGTK::SetPort, grafport2
:       ldx     stack_stash
        txs
        return  #$FF
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

LA3EF:  sub16   LA2ED, #1, delete_file_dialog_params::count
        yax_call launch_dialog, index_delete_file_dialog, delete_file_dialog_params
        rts

LA40A:  sub16   LA2ED, #1, copy_dialog_params::count
        yax_call launch_dialog, index_copy_file_dialog, copy_dialog_params
        rts

LA425:  .byte   0

;;; ============================================================

.proc LA426
        jsr     LA46D
        copy    #ACCESS_DEFAULT, file_info_params3::access
        jsr     LA479
        lda     file_info_params2::file_type
        cmp     #$0F
        beq     LA46C
        yax_call JT_MLI_RELAY, OPEN, open_params5
        beq     LA449
        jsr     show_error_alert_dst
        jmp     LA426

LA449:  lda     open_params5::ref_num
        sta     set_eof_params::ref_num
        sta     close_params3::ref_num
LA452:  yax_call JT_MLI_RELAY, SET_EOF, set_eof_params
        beq     LA463
        jsr     show_error_alert_dst
        jmp     LA452

LA463:  yax_call JT_MLI_RELAY, CLOSE, close_params3
LA46C:  rts
.endproc

.proc LA46D
        COPY_BYTES 11, file_info_params2::access, file_info_params3::access
        rts
.endproc

.proc LA479
        copy    #7, file_info_params3 ; SET_FILE_INFO param_count
        yax_call JT_MLI_RELAY, SET_FILE_INFO, file_info_params3
        pha
        copy    #$A, file_info_params3 ; GET_FILE_INFO param_count
        pla
        beq     done
        jsr     show_error_alert_dst
        jmp     LA479

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
        lda     #$FD            ; "Please insert destination disk"
        jmp     show

:       lda     #$FC            ; "Please insert source disk"
show:   jsr     JT_SHOW_ALERT0
        bne     LA4C2
        jmp     do_on_line

LA4C2:  jmp     close_files_cancel_dialog

flag:   .byte   0

do_on_line:
        yax_call JT_MLI_RELAY, ON_LINE, on_line_params2
        rts

.endproc
        show_error_alert := show_error_alert_impl::flag_clear
        show_error_alert_dst := show_error_alert_impl::flag_set

        .assert * = $A4D0, error, "Segment length mismatch"


;;;  ============================================================
;;;  Reinstall /RAM (Slot 3, Drive 2)

;;;  TODO: Do everything correcly per ProDOS TRM
;;;  http://www.easy68k.com/paulrsm/6502/PDOS8TRM.HTM#5.2.2.4

.proc reinstall_ram
        php
        sei                     ; Disable interrupts

        ram_unit_number = (1<<7 | 3<<4 | DT_RAM)

        ;;  Append unit number
        inc     DEVCNT
        ldx     DEVCNT
        lda     #ram_unit_number ; Slot 3, Drive 2
        sta     DEVLST,x

        ;;  NOTE: Assumes driver (in DEVADR) was not modified
        ;;  when detached.

        ;;  /RAM FORMAT call
        copy    #DRIVER_COMMAND_FORMAT, DRIVER_COMMAND
        copy    #ram_unit_number, DRIVER_UNIT_NUMBER
        copy16  #$2000, DRIVER_BUFFER
        lda     LCBANK1
        lda     LCBANK1
        jsr     driver

        plp                     ; Restore interrupts
        rts

RAMSLOT := DEVADR + $16         ; Slot 3, Drive 2

driver: jmp     (RAMSLOT)
.endproc


        PAD_TO $A500

;;; ============================================================
;;; Dialog Launcher (or just proc handler???)

        index_about_dialog              := 0
        index_copy_file_dialog          := 1
        index_delete_file_dialog        := 2
        index_new_folder_dialog         := 3
        index_get_info_dialog           := 6
        index_lock_dialog               := 7
        index_unlock_dialog             := 8
        index_rename_dialog             := 9
        index_download_dialog           := $A
        index_get_size_dialog           := $B
        index_warning_dialog            := $C

launch_dialog:
        .assert * = $A500, error, "Entry point used by overlay"
        jmp     launch_dialog_impl

dialog_proc_table:
        .addr   show_about_dialog
        .addr   show_copy_file_dialog
        .addr   show_delete_file_dialog
        .addr   show_new_folder_dialog
        .addr   rts1
        .addr   rts1
        .addr   show_get_info_dialog
        .addr   show_lock_dialog
        .addr   show_unlock_dialog
        .addr   show_rename_dialog
        .addr   show_download_dialog
        .addr   show_get_size_dialog
        .addr   show_warning_dialog

dialog_param_addr:
        .addr   0
        .byte   0

.proc launch_dialog_impl
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
        .assert * = $A567, error, "Entry point used by overlay"
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

        prompt_button_ok := 0
        prompt_button_cancel := 1
        prompt_button_yes := 2
        prompt_button_no := 3
        prompt_button_all := 4

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
        lda     #prompt_button_ok
:       rts

check_button_yes:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::yes_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_button_no
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::yes_button_rect
        jsr     button_loop_yes
        bmi     :+
        lda     #prompt_button_yes
:       rts

check_button_no:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::no_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_button_all
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::no_button_rect
        jsr     button_loop_no
        bmi     :+
        lda     #prompt_button_no
:       rts

check_button_all:
        MGTK_RELAY_CALL MGTK::InRect, desktop_aux::all_button_rect
        cmp     #MGTK::inrect_inside
        bne     maybe_check_button_cancel
        jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::all_button_rect
        jsr     button_loop_all
        bmi     :+
        lda     #prompt_button_all
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
        lda     #prompt_button_cancel
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
        return  #prompt_button_yes

do_no:  jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::no_button_rect
        return  #prompt_button_no

do_all: jsr     set_penmode_xor2
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::all_button_rect
        return  #prompt_button_all

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
        .assert * = $A899, error, "Entry point used by overlay"
        jmp     dummy0000


;;; ============================================================
;;; "About" dialog

.proc show_about_dialog
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

.proc show_copy_file_dialog
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
        bne     :+
        jmp     do4
:       cmp     #5
        bne     :+
        jmp     do5

:       copy    #0, has_input_field_flag
        jsr     open_dialog_window
        addr_call draw_dialog_title, desktop_aux::str_copy_title
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
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::LB0B6
        addr_call draw_text1, str_file_count
        addr_call draw_text1, str_files
        rts

do2:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     paint_rectAE86_white
        jsr     paint_rectAE8E_white
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$03
        lda     (ptr),y
        tax
        iny
        lda     (ptr),y
        sta     ptr+1
        stx     ptr
        jsr     copy_name_to_buf0_adjust_case
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
        jsr     copy_name_to_buf1_adjust_case
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::LAE82
        addr_call draw_text1, path_buf1
        yax_call MGTK_RELAY, MGTK::MoveTo, desktop_aux::LB0BA
        addr_call draw_text1, str_file_count
        rts

do5:    jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer
        rts

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

do4:    jsr     bell
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        axy_call draw_dialog_label, 6, desktop_aux::str_large_prompt
        jsr     draw_ok_cancel_buttons
LAAB1:  jsr     prompt_input_loop
        bmi     LAAB1
        pha
        jsr     erase_ok_cancel_buttons
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::prompt_rect
        pla
        rts
.endproc

;;; ============================================================

.proc bell
        .assert * = $AACE, error, "Entry point used by overlay"
        sta     ALTZPOFF
        sta     ROMIN2
        jsr     BELL1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

;;; ============================================================
;;; "DownLoad" dialog

.proc show_download_dialog
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
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::LB0B6
        addr_call draw_text1, str_file_count
        addr_call draw_text1, str_files
        rts

do2:    ldy     #$01
        copy16in (ptr),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     paint_rectAE86_white
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$03
        lda     (ptr),y
        tax
        iny
        lda     (ptr),y
        sta     ptr+1
        stx     ptr
        jsr     copy_name_to_buf0_adjust_case
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::LB0BA
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

.proc show_get_size_dialog
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

do1:    ldy     #$01
        lda     (ptr),y
        sta     file_count
        tax
        iny
        lda     (ptr),y
        sta     ptr+1
        stx     ptr
        ldy     #$00
        copy16in (ptr),y, file_count
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        copy    #165, dialog_label_pos
        yax_call draw_dialog_label, 1, str_file_count
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$03
        lda     (ptr),y
        tax
        iny
        lda     (ptr),y
        sta     ptr+1
        stx     ptr
        ldy     #$00
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
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::press_ok_to_rect
        jsr     erase_ok_button
        return  #0
.endproc

;;; ============================================================
;;; "Delete File" dialog

.proc show_delete_file_dialog
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$00
        lda     ($06),y

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
        bne     :+
        jmp     do4
:       cmp     #5
        bne     :+
        jmp     do5

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

do1:    ldy     #$01
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        lda     LAD1F
        bne     LAD54
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::LB16A
        jmp     LAD5D

LAD54:  MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::LB172
LAD5D:  addr_call draw_text1, str_file_count
        addr_call draw_text1, str_files
        rts

do3:    ldy     #$01
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     paint_rectAE86_white
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$03
        lda     ($06),y
        tax
        iny
        lda     ($06),y
        sta     $06+1
        stx     $06
        jsr     copy_name_to_buf0_adjust_case
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::delete_remaining_count_pos
        addr_call draw_text1, str_file_count
        rts

do2:    lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     draw_ok_cancel_buttons
LADC4:  jsr     prompt_input_loop
        bmi     LADC4
        bne     LADF4
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::press_ok_to_rect
        jsr     erase_ok_cancel_buttons
        yax_call draw_dialog_label, 2, desktop_aux::str_file_colon
        yax_call draw_dialog_label, 4, desktop_aux::str_delete_remaining
        lda     #$00
LADF4:  rts

do5:    jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer
        rts

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

.proc show_new_folder_dialog
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$00
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
        ldy     #$01
        copy16in ($06),y, $08
        ldy     #$00
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
        lda     path_buf1
        beq     LAEC6
        cmp     #$10
        bcc     LAEE1
LAED6:  lda     #$FB
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
        ldy     #$00
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

.proc show_get_info_dialog
        ptr := $6

        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$00
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
        ldy     #$00
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

.proc show_lock_dialog
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$00
        lda     ($06),y

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
        bne     :+
        jmp     do4

:       copy    #0, has_input_field_flag
        jsr     open_dialog_window
        addr_call draw_dialog_title, desktop_aux::str_lock_title
        yax_call draw_dialog_label, 4, desktop_aux::str_lock_ok
        rts

do1:    ldy     #$01
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

do3:    ldy     #$01
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     paint_rectAE86_white
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$03
        lda     ($06),y
        tax
        iny
        lda     ($06),y
        sta     $06+1
        stx     $06
        jsr     copy_name_to_buf0_adjust_case
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::lock_remaining_count_pos
        addr_call draw_text1, str_file_count
        rts

do2:    lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     draw_ok_cancel_buttons
LB0FA:  jsr     prompt_input_loop
        bmi     LB0FA
        bne     LB139
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::press_ok_to_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::cancel_button_rect
        yax_call draw_dialog_label, 2, desktop_aux::str_file_colon
        yax_call draw_dialog_label, 4, desktop_aux::str_lock_remaining
        lda     #$00
LB139:  rts

do4:    jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer
        rts
.endproc

;;; ============================================================
;;; "Unlock" dialog

.proc show_unlock_dialog
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$00
        lda     ($06),y

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
        bne     :+
        jmp     do4

:       copy    #0, has_input_field_flag
        jsr     open_dialog_window
        addr_call draw_dialog_title, desktop_aux::str_unlock_title
        yax_call draw_dialog_label, 4, desktop_aux::str_unlock_ok
        rts

do1:    ldy     #$01
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

do3:    ldy     #$01
        copy16in ($06),y, file_count
        jsr     adjust_str_files_suffix
        jsr     compose_file_count_string
        lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     paint_rectAE86_white
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$03
        lda     ($06),y
        tax
        iny
        lda     ($06),y
        sta     $06+1
        stx     $06
        jsr     copy_name_to_buf0_adjust_case
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::current_target_file_pos
        addr_call draw_text1, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, desktop_aux::unlock_remaining_count_pos
        addr_call draw_text1, str_file_count
        rts

do2:    lda     winfo_alert_dialog
        jsr     set_port_from_window_id
        jsr     draw_ok_cancel_buttons
LB218:  jsr     prompt_input_loop
        bmi     LB218
        bne     LB257
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::press_ok_to_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::cancel_button_rect
        yax_call draw_dialog_label, 2, desktop_aux::str_file_colon
        yax_call draw_dialog_label, 4, desktop_aux::str_unlock_remaining
        lda     #$00
LB257:  rts

do4:    jsr     reset_grafport3a
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_alert_dialog
        jsr     set_cursor_pointer
        rts
.endproc

;;; ============================================================
;;; "Rename" dialog

.proc show_rename_dialog
        jsr     copy_dialog_param_addr_to_ptr
        ldy     #$00
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
        ldy     #$01
        copy16in ($06),y, $08
        ldy     #$00
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

.proc show_warning_dialog
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
        ldy     #$00
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
        warning_msg_insert_system_disk          := 0
        warning_msg_selector_list_full          := 1
        warning_msg_selector_list_full2         := 2
        warning_msg_window_must_be_closed       := 3
        warning_msg_window_must_be_closed2      := 4
        warning_msg_too_many_windows            := 5
        warning_msg_save_selector_list          := 6

;;; ============================================================

.proc copy_dialog_param_addr_to_ptr
        copy16  dialog_param_addr, $06
        rts
.endproc

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

.proc set_cursor_watch
        .assert * = $B3E7, error, "Entry point used by overlay"
        MGTK_RELAY_CALL MGTK::HideCursor
        MGTK_RELAY_CALL MGTK::SetCursor, watch_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor
        rts
.endproc

.proc set_cursor_pointer
        .assert * = $B403, error, "Entry point used by overlay"
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
        .assert * = $B445, error, "Entry point used by overlay"

        double_click_deltax := 5
        double_click_deltay := 4

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
        cmp     #($100 - double_click_deltax)
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
        cmp     #($100 - double_click_deltay)
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

        PAD_TO $B509

;;; ============================================================

.proc open_prompt_window
        .assert * = $B509, error, "Entry point used by overlay"
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

        DDL_CENTER := $80

.proc draw_dialog_label
        .assert * = $B590, error, "Entry point used by overlay"

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
:       tya
        pha
        add16   ptr, #1, textptr
        jsr     load_aux_from_ptr
        sta     textlen
        MGTK_RELAY_CALL MGTK::TextWidth, textwidth_params
        lsr16   result
        sub16   #200, result, dialog_label_pos
        pla
        tay

skip:   dey                     ; ypos = (Y-1) * 8 + pointD::ycoord
        tya
        asl     a
        asl     a
        asl     a
        clc
        adc     pointD::ycoord
        sta     dialog_label_pos+2
        lda     pointD::ycoord+1
        adc     #0
        sta     dialog_label_pos+3
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
        .assert * = $B708, error, "Entry point used by overlay"
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
        .assert * = $B723, error, "Entry point used by overlay"

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

        ;; Unreferenced ???
LB76C:  stax    $06
        MGTK_RELAY_CALL MGTK::MoveTo, point7
        addr_call_indirect draw_text1, $06
        rts

;;; ============================================================
;;; Adjust case in a pathname (input buf A,X, output buf $A)

.proc adjust_case
        .assert * = $B781, error, "Entry point used by overlay"

        ptr := $A

        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
        beq     done

        ;; Walk backwards through string. At char N, check char N-1
        ;; to see if it is a symbol. If it is, and char N is a letter,
        ;; lower-case it.

loop:   dey
        beq     done
        bpl     :+
done:   rts

:       lda     (ptr),y
        and     #CHAR_MASK      ; convert to ASCII
        cmp     #'0'            ; <'0' includes '.', '/' and ' '
        bcs     check_alpha
        dey
        jmp     loop

check_alpha:
        iny
        lda     (ptr),y
        and     #CHAR_MASK
        cmp     #'A'
        bcc     :+
        cmp     #'Z'+1
        bcs     :+
        ora     #(~CASE_MASK & $FF)
        sta     (ptr),y
:       dey
        jmp     loop
.endproc

        PAD_TO $B7B9            ; Maintain previous addresses

;;; ============================================================

.proc set_port_from_window_id
        .assert * = $B7B9, error, "Entry point used by overlay"
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
        lda     #prompt_button_ok
        jmp     button_event_loop

button_loop_cancel:
        lda     #prompt_button_cancel
        jmp     button_event_loop

button_loop_yes:
        lda     #prompt_button_yes
        jmp     button_event_loop

button_loop_no:
        lda     #prompt_button_no
        jmp     button_event_loop

button_loop_all:
        lda     #prompt_button_all
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
        lda     path_buf1
        beq     done
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
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, name_input_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        rts

:       jsr     measure_path_buf1
        stax    $06
        cmp16   screentowindow_windowx, $06
        bcs     LB9EE
        jmp     LBA83
.endproc

.proc LB9EE
        ptr := $6
        jsr     measure_path_buf1
        stax    LBB09
        ldx     path_buf2
        inx
        copy    #' ', path_buf2,x
        inc     path_buf2
        copy16  #path_buf2, ptr
        lda     path_buf2
        sta     ptr+2
LBA10:  MGTK_RELAY_CALL MGTK::TextWidth, ptr
        add16   $09, LBB09, $09
        cmp16   $09, screentowindow_windowx
        bcc     LBA42
        dec     $08
        lda     $08
        cmp     #$01
        bne     LBA10
        dec     path_buf2
        jmp     LBB05
.endproc

.proc LBA42
        lda     $08
        cmp     path_buf2
        bcc     LBA4F
        dec     path_buf2
        jmp     LBCC9

LBA4F:  ldx     #$02
        ldy     path_buf1
        iny
LBA55:  lda     path_buf2,x
        sta     path_buf1,y
        cpx     $08
        beq     LBA64
        iny
        inx
        jmp     LBA55

LBA64:  sty     path_buf1
        ldy     #$02
        ldx     $08
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
        jmp     LBB05
.endproc

.proc LBA83
        params := $6
        textptr := $6
        textlen := $8
        result  := $9

        copy16  #path_buf1, textptr
        lda     path_buf1
        sta     textlen
:       MGTK_RELAY_CALL MGTK::TextWidth, params
        add16 result, name_input_textpos::xcoord, result
        cmp16   result, screentowindow_windowx
        bcc     LBABF
        dec     textlen
        lda     textlen
        cmp     #1
        bcs     :-
        jmp     LBC5E
.endproc

.proc LBABF
        inc     $08
        ldy     #0
        ldx     $08
LBAC5:  cpx     path_buf1
        beq     LBAD5
        inx
        iny
        lda     path_buf1,x
        sta     LD3C1+1,y
        jmp     LBAC5

LBAD5:  iny
        sty     LD3C1
        ldx     #1
        ldy     LD3C1
LBADE:  cpx     path_buf2
        beq     LBAEE
        inx
        iny
        lda     path_buf2,x
        sta     LD3C1,y
        jmp     LBADE

LBAEE:  sty     LD3C1
        lda     str_insertion_point+1
        sta     LD3C1+1
LBAF7:  lda     LD3C1,y
        sta     path_buf2,y
        dey
        bpl     LBAF7
        lda     $08
        sta     path_buf1
        ;; fall through
.endproc

LBB05:  jsr     draw_filename_prompt
        rts

LBB09:  .word   0

LBB0B:  sta     LBB62
        lda     path_buf1
        clc
        adc     path_buf2
        cmp     #$10
        bcc     LBB1A
        rts

.proc LBB1A
        point := $6
        xcoord := $6
        ycoord := $8

        lda     LBB62
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
.endproc

LBB62:  .byte   0
LBB63:  lda     path_buf1
        bne     LBB69
        rts

.proc LBB69
        point := $6
        xcoord := $6
        ycoord := $8

        dec     path_buf1
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

LBBA4:  lda     path_buf1
        bne     LBBAA
        rts

.proc LBBAA
        point := $6
        xcoord := $6
        ycoord := $8

        ldx     path_buf2
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

.proc LBC5E
        lda     path_buf1
        bne     LBC64
        rts

LBC64:  ldx     path_buf2
        cpx     #$01
        beq     LBC79
LBC6B:  lda     path_buf2,x
        sta     LD3C1-1,x
        dex
        cpx     #$01
        bne     LBC6B
        ldx     path_buf2
LBC79:  dex
        stx     LD3C1
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
        adc     LD3C1
        tay
        pha
        ldx     LD3C1
        beq     LBCB3
LBCA6:  lda     LD3C1,x
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

.proc LBCC9
        lda     path_buf2
        cmp     #$02
        bcs     LBCD1
        rts

LBCD1:  ldx     path_buf2
        dex
        txa
        clc
        adc     path_buf1
        pha
        tay
        ldx     path_buf2
LBCDF:  lda     path_buf2,x
        sta     path_buf1,y
        dex
        dey
        cpy     path_buf1
        bne     LBCDF
        pla
        sta     path_buf1
        copy    #1, path_buf2
        MGTK_RELAY_CALL MGTK::MoveTo, name_input_textpos
        jsr     draw_filename_prompt
        rts
.endproc

;;; Entry point???

        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
        clc
        adc     path_buf1
        pha
        tax
LBD11:  lda     ($06),y
        sta     path_buf1,x
        dey
        dex
        cpx     path_buf1
        bne     LBD11
        pla
        sta     path_buf1
        rts

LBD22:  ldx     path_buf1
        cpx     #$00
        beq     LBD33
        dec     path_buf1
        lda     path_buf1,x
        cmp     #'/'
        bne     LBD22
LBD33:  rts

        jsr     LBD22
        jsr     draw_filename_prompt
        rts

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
        .assert * = $BD69, error, "Entry point used by overlay"

        copy    #1, path_buf2   ; length
        copy    str_insertion_point+1, path_buf2+1 ; IP character
        rts
.endproc

.proc clear_path_buf1
        .assert * = $BD75, error, "Entry point used by overlay"

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

        PAD_TO $BE63

;;; ============================================================

.proc copy_name_to_buf0_adjust_case
        ptr := $6

        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     path_buf0,y
        dey
        bpl     :-
        addr_call adjust_case, path_buf0
        rts
.endproc

.proc copy_name_to_buf1_adjust_case
        ptr := $6

        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     path_buf1,y
        dey
        bpl     :-
        addr_call adjust_case, path_buf1
        rts
.endproc

;;; ============================================================

paint_rectAE86_white:
        jsr     set_fill_white
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::LAE86
        rts

paint_rectAE8E_white:
        jsr     set_fill_white
        MGTK_RELAY_CALL MGTK::PaintRect, desktop_aux::LAE8E
        rts

set_fill_white:
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        rts

reset_grafport3a:
        .assert * = $BEB1, error, "Entry point used by overlay"

        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

        .assert * = $BEC4, error, "Segment length mismatch"

;;; ============================================================
;;; Invoked when exiting or launching another program.

.proc exit_dhr_mode
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

        ;; On IIgs (only), restore DHR Color mode
        sec
        jsr     ID_BYTE_FE1F
        bcs     done
        lda     NEWVIDEO
        ora     #<~(1<<5)       ; Color
        sta     NEWVIDEO

done:   rts
.endproc

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

;;; ============================================================

start:

.proc detect_machine
        ;; Detect machine type
        ;; See Apple II Miscellaneous #7: Apple II Family Identification
        copy    #0, iigs_flag
        lda     ID_BYTE_FBC0    ; 0 = IIc or IIc+
        beq     :+
        sec                     ; Follow detection protocol
        jsr     ID_BYTE_FE1F    ; RTS on pre-IIgs
        bcs     :+              ; carry clear = IIgs
        copy    #$80, iigs_flag

:       ldx     ID_BYTE_FBB3
        ldy     ID_BYTE_FBC0
        cpx     #$06            ; Ensure a IIe or later
        beq     :+
        brk                     ; Otherwise (][, ][+, ///), just crash

:       sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        sta     SET80COL

        stx     startdesktop_params::machine
        sty     startdesktop_params::subid

        cpy     #0
        beq     is_iic          ; Now identify/store specific machine type.
        bit     iigs_flag       ; (number is used in double-click timer)
        bpl     is_iie
        copy    #$FD, machine_type ; IIgs
        jmp     init_video

is_iie: copy    #$96, machine_type ; IIe
        jmp     init_video

is_iic: copy    #$FA, machine_type ; IIc
        jmp     init_video
.endproc

iigs_flag:                      ; High bit set if IIgs detected.
        .byte   0

;;; ============================================================

.proc init_video
        ;;  AppleColor Card - Mode 1 (Monochrome 560x192)
        sta     CLR80VID
        sta     AN3_OFF
        sta     AN3_ON
        sta     AN3_OFF
        sta     AN3_ON
        sta     SET80VID
        sta     AN3_OFF

        ;; IIgs ?
        bit     iigs_flag
        bmi     iigs

        ;; Le Chat Mauve - BW560 mode
        ;; (AN3 off, HR1 off, HR2 on, HR3 on)
        ;; Skip on IIgs since emulators (KEGS/GSport/GSplus) crash.
        sta     HR2_ON
        sta     HR3_ON
        bpl     end

        ;; Force B&W mode on the IIgs
iigs:   lda     NEWVIDEO
        ora     #(1<<5)         ; B&W
        sta     NEWVIDEO
        ;; fall through
end:
.endproc

;;; ============================================================

.proc backup_device_list
        ;; Make a copy of the original device list
        ldx     DEVCNT
        inx
:       lda     DEVLST-1,x
        sta     devlst_backup,x
        dex
        bpl     :-
        ;; fall through
.endproc

.proc detach_ramdisk
        ;; Look for /RAM
        ldx     DEVCNT
:       lda     DEVLST,x
        ;; BUG: ProDOS Tech Note #21 says $B3,$B7,$BB or $BF could be /RAM
        cmp     #(1<<7 | 3<<4 | DT_RAM) ; unit_num for /RAM is Slot 3, Drive 2
        beq     found_ram
        dex
        bpl     :-
        bmi     init_mgtk
found_ram:
        jsr     remove_device
        ;; fall through
.endproc

;;; ============================================================

        ;; Initialize MGTK
.proc init_mgtk
        MGTK_RELAY_CALL MGTK::StartDeskTop, startdesktop_params
        MGTK_RELAY_CALL MGTK::SetMenu, splash_menu
        MGTK_RELAY_CALL MGTK::SetZP1, zp_use_flag0
        MGTK_RELAY_CALL MGTK::SetCursor, watch_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor
        ;; fall through
.endproc

;;; ============================================================

        ;; Populate icon_entries table
.proc populate_icon_entries_table
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
.endproc

;;; ============================================================

        ;; Zero the window icon tables
.proc clear_window_icon_tables
        sta     RAMWRTON
        lda     #$00
        tax
loop:   sta     $1F00,x         ; window 8, icon use map
        sta     $1E00,x         ; window 6, 7
        sta     $1D00,x         ; window 4, 5
        sta     $1C00,x         ; window 2, 3
        sta     $1B00,x         ; window 0, 1 (0=desktop)
        inx
        bne     loop
        sta     RAMWRTOFF
        jmp     create_trash_icon
.endproc

;;; ============================================================

trash_name:  PASCAL_STRING " Trash "

.proc create_trash_icon
        ptr := $6

        copy    #0, cached_window_id
        lda     #1
        sta     cached_window_icon_count
        sta     icon_count
        jsr     DESKTOP_ALLOC_ICON
        sta     trash_icon_num
        sta     cached_window_icon_list
        jsr     desktop_main::icon_entry_lookup
        stax    ptr
        ldy     #IconEntry::win_type
        copy    #icon_entry_type_trash, (ptr),y
        ldy     #IconEntry::iconbits
        copy16in #desktop_aux::trash_icon, (ptr),y
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
;;; TODO: Figure out what/why ???

.proc filter_volumes
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
:       lda     DEVLST+1,x
        sta     DEVLST,x
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

unit_number:
        .byte   0               ; now unused

end:
.endproc

;;; ============================================================

.proc load_selector_list
        ptr1 := $6
        ptr2 := $8

        selector_list_io_buf := $1000
        selector_list_data_buf := $1400
        selector_list_data_len := $400

        ;; Save the current PREFIX
        MGTK_RELAY_CALL MGTK::CheckEvents
        MLI_RELAY_CALL GET_PREFIX, desktop_main::get_prefix_params
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

.proc enumerate_desk_accessories
        MGTK_RELAY_CALL MGTK::CheckEvents ; ???

        read_dir_buffer := $1400

        ;; Does the directory exist?
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        jmp     populate_volume_icons

:       lda     get_file_info_type
        cmp     #FT_DIRECTORY
        beq     open_dir
        jmp     populate_volume_icons

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
        ldy     #FileEntry::storage_type_name_length
        lda     (dir_ptr),y
        and     #NAME_LENGTH_MASK
        bne     :+
        jmp     next_entry

:       inc     entry_num
        ldy     #FileEntry::file_type
        lda     (dir_ptr),y
        cmp     #DA_FILE_TYPE
        beq     is_da
        jmp     next_entry

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

        addr_call_indirect desktop_main::adjust_case, da_ptr

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
.endproc

;;; ============================================================

;;; TODO: Dedupe with cmd_check_drives

.proc populate_volume_icons
        ldy     #0
        sty     desktop_main::pending_alert
        sty     volume_num

process_volume:
        lda     volume_num
        asl     a
        tay
        copy16  slot_drive_string_table,y, $08
        ldy     volume_num
        lda     DEVLST,y

        pha                     ; save all registers
        txa
        pha
        tya
        pha

        inc     cached_window_icon_count
        inc     icon_count
        lda     DEVLST,y
        jsr     desktop_main::create_volume_icon
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
        bne     L0D64
        ldy     volume_num
        lda     DEVLST,y
        and     #$0F
        beq     select_template
        ldx     volume_num
        jsr     remove_device
        jmp     next
L0D64:  cmp     #ERR_DUPLICATE_VOLUME
        bne     select_template
        lda     #$F9            ; "... 2 volumes with the same name..."
        sta     desktop_main::pending_alert

        ;; This section populates slot_drive_string_table -
        ;; it determines which device type string to use, and
        ;; fills in slot and drive as appropriate.
        ;;
        ;; This is for a "Check" menu present in MouseDesk 1.1
        ;; but which was removed in MouseDesk 2.0, which allowed
        ;; refreshing individual windows.

.proc select_template
        pla
        pha
        and     #$0F            ; low nibble of unit number
        sta     unit_number_lo_nibble
        cmp     #DT_DISKII
        bne     :+
        addr_jump copy_template, str_slot_drive

:       cmp     #DT_REMOVABLE
        beq     is_removable
        cmp     #DT_PROFILE
        bne     L0DC2
        pla
        pha
        and     #$70            ; Compute $CnFB
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$C0
        sta     @slot_msb
        @slot_msb := *+2
        lda     $C7FB           ; self-modified
        and     #$01            ; is RAM card?
        bne     :+
        addr_jump copy_template, str_profile_slot_x

:       addr_jump copy_template, str_ramcard_slot_x

is_removable:
        ldax    #str_unidisk_xy
.endproc

copy_template:  stax    $06
        ldy     #$00
        lda     ($06),y
        sta     @compare
:       iny
        lda     ($06),y
        sta     ($08),y
        @compare := *+1
        cpy     #0
        bne     :-
        tay
L0DC2:  pla
        pha

        ;; A has unit number
        and     #$70            ; slot (from DSSSxxxx)
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$30
        tax

        lda     unit_number_lo_nibble
        cmp     #DT_PROFILE
        bne     check_removable

        ;; A has unit number (again)
        pla
        pha
        and     #$70            ; compute $CnFB
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$C0
        sta     @msb
        @msb := *+2
        lda     $C7FB           ; self-modified
        and     #$01            ; bit 0 = is RAM disk?
        bne     is_ram_disk

        ldy     #$0E
        bne     L0DFA           ; always

is_ram_disk:
        ldy     #$0E
        bne     L0DFA           ; always

check_removable:
        cmp     #DT_REMOVABLE
        bne     :+
        ldy     #$0F
        bne     L0DFA           ; always

:       ldy     #$06

L0DFA:  txa
        sta     ($08),y

        lda     unit_number_lo_nibble
        and     #$0F
        cmp     #DT_PROFILE
        beq     L0E21
        pla
        pha
        rol     a               ; set carry to drive - 1
        lda     #0
        adc     #1              ; drive = 1 or 2
        ora     #'0'
        pha

        lda     unit_number_lo_nibble
        and     #DT_RAM
        bne     L0E1C
        ldy     #$10
        pla
        bne     L0E1F           ; always
L0E1C:  ldy     #$11
        pla
L0E1F:  sta     ($08),y
L0E21:  pla
        inc     volume_num
next:   lda     volume_num

        cmp     DEVCNT          ; done?
        beq     :+
        bcs     populate_startup_menu
:       jmp     process_volume  ; next!

unit_number_lo_nibble:
        .byte   0
volume_num:
        .byte   0
cvi_result:
        .byte   0
.endproc

;;; ============================================================

        ;; Remove device num in X from devices list
.proc remove_device
        dex
L0E36:  inx
        lda     DEVLST+1,x
        sta     DEVLST,x
        lda     device_to_icon_map+1,x
        sta     device_to_icon_map,x
        cpx     DEVCNT
        bne     L0E36
        dec     DEVCNT
        rts
.endproc

;;; ============================================================

.proc populate_startup_menu
        lda     DEVCNT
        clc
        adc     #3
        sta     check_menu      ; obsolete

        lda     #0
        sta     slot
        tay
        tax

loop:   lda     DEVLST,y
        and     #$70            ; mask off slot
        beq     done
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        cmp     slot            ; same as last?
        beq     :+
        cmp     #2              ; ???
        bne     prepare
:       cpy     DEVCNT
        beq     done
        iny
        jmp     loop

prepare:
        sta     slot
        clc
        adc     #'0'
        sta     char

        txa                     ; pointer to nth sNN string
        pha
        asl     a
        tax
        copy16  slot_string_table,x, @item_ptr

        ldx     startup_menu_item_1             ; replace second-from-last char
        dex
        lda     char
        @item_ptr := *+1
        sta     dummy1234,x

        pla
        tax
        inx
        cpy     DEVCNT
        beq     done
        iny
        jmp     loop

done:   stx     startup_menu
        jmp     final_setup

char:   .byte   0
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

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, desktop_main::sys_start_path

str_system_start:  PASCAL_STRING "System/Start"

.proc final_setup
        lda     #0
        sta     desktop_main::sys_start_flag
        jsr     desktop_main::get_copied_to_ramcard_flag
        cmp     #$80
        beq     L0EFE
        MLI_RELAY_CALL GET_PREFIX, get_prefix_params
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
        lda     #$80
        sta     desktop_main::sys_start_flag

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
