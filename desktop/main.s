;;; ============================================================
;;; Desktop - Main Memory Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        RESOURCE_FILE "main.res"

;;; ============================================================
;;; Segment loaded into MAIN $4000-$BEFF
;;; ============================================================

.scope main

kShortcutResize = res_char_resize_shortcut
kShortcutMove   = res_char_move_shortcut
kShortcutScroll = res_char_scroll_shortcut

src_path_buf    := INVOKER_PREFIX
dst_path_buf    := $1F80

open_dir_path_buf := INVOKER_PREFIX

        .org $4000

        ;; Jump table
        ;; Entries marked with * are used by DAs
        ;; "Exported" by desktop.inc

JT_MGTK_CALL:           jmp     MGTKRelayImpl           ; *
JT_MLI_CALL:            jmp     MLIRelayImpl            ; *
JT_CLEAR_UPDATES:       jmp     ClearUpdates            ; *
JT_YIELD_LOOP:          jmp     YieldLoop               ; *
JT_SELECT_WINDOW:       jmp     SelectAndRefreshWindow  ; *
JT_SHOW_ALERT:          jmp     ShowAlert               ; *
JT_SHOW_ALERT_OPTIONS:  jmp     ShowAlertOption
JT_LAUNCH_FILE:         jmp     LaunchFile
JT_CUR_POINTER:         jmp     SetCursorPointer        ; *
JT_CUR_WATCH:           jmp     SetCursorWatch          ; *
JT_CUR_IBEAM:           jmp     SetCursorIBeam          ; *
JT_RESTORE_OVL:         jmp     RestoreDynamicRoutine   ; *
JT_COLOR_MODE:          jmp     SetColorMode            ; *
JT_MONO_MODE:           jmp     SetMonoMode             ; *
JT_RGB_MODE:            jmp     SetRGBMode              ; *
JT_RESTORE_SYS:         jmp     RestoreSystem           ; *
JT_GET_SEL_COUNT:       jmp     GetSelectionCount       ; *
JT_GET_SEL_ICON:        jmp     GetSelectedIcon         ; *
JT_GET_SEL_WIN:         jmp     GetSelectionWindow      ; *
JT_GET_WIN_PATH:        jmp     GetWindowPath           ; *
JT_HILITE_MENU:         jmp     ToggleMenuHilite        ; *
JT_ADJUST_FILEENTRY:    jmp     AdjustFileEntryCase     ; *
JT_GET_RAMCARD_FLAG:    jmp     GetCopiedToRAMCardFlag  ; *
JT_GET_ORIG_PREFIX:     jmp     CopyDeskTopOriginalPrefix ; *

        .assert JUMP_TABLE_GET_ORIG_PREFIX = JT_GET_ORIG_PREFIX, error, "Jump table mismatch"

        ;; Main Loop
.proc MainLoop
        jsr     ResetMainGrafport

        ;; Close any windows that are not longer valid, if necessary
        jsr     ValidateWindows

        jsr     YieldLoop
        bne     :+

        ;; Poll drives for updates
        jsr     CheckDiskInsertedEjected
        beq     :+
        jsr     CheckDrive      ; DEVLST index+3 of changed drive

:       jsr     UpdateMenuItemStates

        ;; Get an event
        jsr     GetEvent
        lda     event_params::kind

        ;; Is it a key down event?
        cmp     #MGTK::EventKind::key_down
    IF_EQ
        jsr     HandleKeydown
        jmp     MainLoop
    END_IF

        ;; Was it maybe a mouse move?
        cmp     #MGTK::EventKind::no_event
    IF_EQ
        jsr     CheckMouseMoved
        bcc     MainLoop        ; nope, ignore
        ;; fall through...
    END_IF

        ;; Cancel any type down selection.
        jsr     ClearTypeDown
        lda     event_params::kind

        ;; Is it a button-down event? (including w/ modifiers)
        cmp     #MGTK::EventKind::button_down
        beq     click
        cmp     #MGTK::EventKind::apple_key
        bne     :+
click:  jsr     HandleClick
        jmp     MainLoop
:

        ;; Is it an update event?
        cmp     #MGTK::EventKind::update
    IF_EQ
        jsr     ClearUpdatesNoPeek
    END_IF

        jmp     MainLoop

;;; --------------------------------------------------

.proc CheckDrive
        tsx
        stx     saved_stack
        sta     menu_click_params::item_num
        jsr     CmdCheckSingleDriveByMenu
        copy    #0, menu_click_params::item_num
        rts
.endproc

.endproc

;;; ============================================================
;;; Clear Updates
;;; MGTK sends a update event when a window needs to be redrawn
;;; because it was revealed by another operation (e.g. close).
;;; This is called implicitly during the main loop if an update
;;; event is seen, and also explicitly following operations
;;; (e.g. a window close followed by a nested loop or slow
;;; file operation).
;;;
;;; This is made more complicated by the presence of desktop
;;; (volume) icons, which MGTK is unaware of. Implicit updates
;;; trigger a desktop icon repaint, but these are insufficient
;;; for cases where MGTK doesn't think there's anything to
;;; update. Therefore, most DeskTop sites will call explicitly
;;; to both clear updates and redraw icons using the
;;; `ClearUpdates` entry point.

.proc ClearUpdatesImpl

;;; Caller already called GetEvent, no need to PeekEvent;
;;; just jump directly into the clearing loop.
clear_no_peek:
        jsr     ResetMainGrafport
        copy    active_window_id, saved_active_window_id
        jmp     handle_update   ; skip PeekEvent

;;; Clear any pending updates.
clear:
        jsr     ResetMainGrafport
        copy    active_window_id, saved_active_window_id
        ;; fall through

        ;; --------------------------------------------------
loop:
        jsr     PeekEvent
        lda     event_params::kind
        cmp     #MGTK::EventKind::update
        bne     finish
        jsr     GetEvent

handle_update:
        lda     event_params::window_id
        bne     win

        ;; Desktop
        MGTK_RELAY_CALL MGTK::BeginUpdate, event_params::window_id
        ITK_RELAY_CALL IconTK::RedrawDesktopIcons
        MGTK_RELAY_CALL MGTK::EndUpdate
        jmp     loop

        ;; Window
win:    MGTK_RELAY_CALL MGTK::BeginUpdate, event_params::window_id
        bne     :+            ; obscured
        jsr     UpdateWindow
        MGTK_RELAY_CALL MGTK::EndUpdate
:       jmp     loop

finish: jsr     LoadDesktopEntryTable ; restore after `UpdateWindow`
        saved_active_window_id := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     active_window_id
        rts
.endproc
ClearUpdatesNoPeek := ClearUpdatesImpl::clear_no_peek
ClearUpdates := ClearUpdatesImpl::clear

;;; ============================================================
;;; Called by main and nested event loops to do periodic tasks.
;;; Returns 0 if the periodic tasks were run.

.proc YieldLoop
        inc     loop_counter
        inc     loop_counter
        loop_counter := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     periodic_task_delay    ; for per-machine timing
        bcc     :+
        copy    #0, loop_counter

        jsr     ShowClock
        jsr     ResetIIgsRGB   ; in case it was reset by control panel

:       lda     loop_counter
        rts
.endproc

;;; ============================================================

.proc UpdateWindow
        lda     event_params::window_id
        cmp     #kMaxNumWindows+1 ; directory windows are 1-8
        bcc     :+
        rts

:       sta     active_window_id
        jsr     LoadActiveWindowEntryTable ; restored in `ClearUpdates`

        ;; This correctly uses the clipped port provided by BeginUpdate.

        ;; `DrawWindowHeader` relies on `window_grafport` for dimensions
        copy    cached_window_id, getwinport_params::window_id
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params
        jsr     DrawWindowHeader

        ;; Overwrite the Winfo's port with the cliprect we got for the update
        ;; since downstream calls will use the Winfo's port.
        lda     active_window_id
        jsr     SwapWindowPortbits
        jsr     OverwriteWindowPort

        winfo_ptr := $06

        ;; Determine the update's cliprect is already below the header; if
        ;; not, we need to offset the cliprect below the header.
        lda     active_window_id
        jsr     WindowLookup
        stax    winfo_ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        sub16in (winfo_ptr),y, window_grafport::viewloc::ycoord, yoff
        cmp16   yoff, #kWindowHeaderHeight+1
        bpl     skip_adjust_port

        ;; Adjust grafport to account for header
        jsr     OffsetWindowGrafport

        ;; MGTK doesn't like offscreen grafports, so if we end up with
        ;; nothing to draw, skip drawing!
        ;; https://github.com/a2stuff/a2d/issues/369
        ldx     #MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        cmp16   window_grafport,x, #kScreenHeight
        bpl     done

        ;; Apply the computed grafport to the Winfo
        ldx     #MGTK::GrafPort::maprect + MGTK::Point::ycoord + 1
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Point::ycoord + 1
        copy    window_grafport,x, (winfo_ptr),y
        dey
        dex
        copy    window_grafport,x, (winfo_ptr),y

        ldx     #MGTK::GrafPort::viewloc + MGTK::Point::ycoord + 1
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::ycoord + 1
        copy    window_grafport,x, (winfo_ptr),y
        dey
        dex
        copy    window_grafport,x, (winfo_ptr),y

skip_adjust_port:

        ;; Actually draw the window icons/list
        copy    #$80, header_and_offset_flag ; port already adjusted
        jsr     DrawWindowEntries
        copy    #0, header_and_offset_flag

done:
        ;; Restore window's port
        lda     active_window_id
        jsr     SwapWindowPortbits

        ;; Back to normal TODO: Is this needed??? Move to end of update loop?
        jmp     ResetMainGrafport

yoff:   .word   0
.endproc

;;; ============================================================
;;; Menu Dispatch

.proc HandleKeydownImpl

        ;; Keep in sync with aux::menu_item_id_*

        ;; jump table for menu item handlers
dispatch_table:
        ;; Apple menu (1)
        menu1_start := *
        .addr   CmdAbout
        .addr   CmdNoOp         ; --------
        .repeat ::kMaxDeskAccCount
        .addr   CmdDeskAcc
        .endrepeat
        ASSERT_ADDRESS_TABLE_SIZE menu1_start, ::kMenuSizeApple

        ;; File menu (2)
        menu2_start := *
        .addr   CmdNewFolder
        .addr   CmdOpen
        .addr   CmdClose
        .addr   CmdCloseAll
        .addr   CmdSelectAll
        .addr   CmdNoOp         ; --------
        .addr   CmdGetInfo
        .addr   CmdRename
        .addr   CmdDuplicate
        .addr   CmdNoOp         ; --------
        .addr   CmdCopyFile
        .addr   CmdDeleteFile
        .addr   CmdNoOp         ; --------
        .addr   CmdQuit
        ASSERT_ADDRESS_TABLE_SIZE menu2_start, ::kMenuSizeFile

        ;; View menu (3)
        menu3_start := *
        .addr   CmdViewByIcon
        .addr   CmdViewByName
        .addr   CmdViewByDate
        .addr   CmdViewBySize
        .addr   CmdViewByType
        ASSERT_ADDRESS_TABLE_SIZE menu3_start, ::kMenuSizeView

        ;; Special menu (4)
        menu4_start := *
        .addr   CmdCheckDrives
        .addr   CmdCheckDrive
        .addr   CmdEject
        .addr   CmdNoOp         ; --------
        .addr   CmdFormatDisk
        .addr   CmdEraseDisk
        .addr   CmdDiskCopy
        .addr   CmdNoOp         ; --------
        .addr   CmdLock
        .addr   CmdUnlock
        .addr   CmdGetSize
        ASSERT_ADDRESS_TABLE_SIZE menu4_start, ::kMenuSizeSpecial

        ;; Startup menu (5)
        menu5_start := *
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        ASSERT_ADDRESS_TABLE_SIZE menu5_start, ::kMenuSizeStartup

        ;; Selector menu (6)
        menu6_start := *
        .addr   CmdSelectorAction
        .addr   CmdSelectorAction
        .addr   CmdSelectorAction
        .addr   CmdSelectorAction
        .addr   CmdNoOp         ; --------
        .addr   CmdSelectorItem
        .addr   CmdSelectorItem
        .addr   CmdSelectorItem
        .addr   CmdSelectorItem
        .addr   CmdSelectorItem
        .addr   CmdSelectorItem
        .addr   CmdSelectorItem
        .addr   CmdSelectorItem
        ASSERT_ADDRESS_TABLE_SIZE menu6_start, ::kMenuSizeSelector

        menu_end := *

        ;; indexed by menu id-1
offset_table:
        .byte   menu1_start - dispatch_table
        .byte   menu2_start - dispatch_table
        .byte   menu3_start - dispatch_table
        .byte   menu4_start - dispatch_table
        .byte   menu5_start - dispatch_table
        .byte   menu6_start - dispatch_table
        .byte   menu_end - dispatch_table

        ;; Set if there are open windows
window_open_flag:   .byte   $00

        ;; Handle accelerator keys
HandleKeydown:
        lda     event_params::modifiers
        bne     modifiers       ; either Open-Apple or Solid-Apple ?

        ;; --------------------------------------------------
        ;; No modifiers

        lda     event_params::key
        jsr     CheckTypeDown
        bne     :+
        rts
:       jsr     ClearTypeDown

        lda     event_params::key
        cmp     #CHAR_LEFT
        jeq     CmdHighlightPrev
        cmp     #CHAR_UP
        jeq     CmdHighlightPrev
        cmp     #CHAR_RIGHT
        jeq     CmdHighlightNext
        cmp     #CHAR_DOWN
        jeq     CmdHighlightNext
        cmp     #CHAR_TAB
        jeq     CmdHighlightAlpha

        jmp     menu_accelerators

        ;; --------------------------------------------------
        ;; Modifiers

modifiers:
        jsr     ClearTypeDown

        lda     event_params::modifiers
        cmp     #3              ; both Open-Apple + Solid-Apple ?
    IF_EQ
        ;; Double-modifier shortcuts
        lda     event_params::key
        cmp     #'O'
        jeq     CmdOpenThenCloseParent
        cmp     #'W'
        jeq     CmdCloseAll
        rts
    END_IF

        ;; Non-menu keys
        lda     event_params::key
        jsr     UpcaseChar
        cmp     #CHAR_DOWN      ; Apple-Down (Open)
        jeq     CmdOpenFromKeyboard
        cmp     #CHAR_UP        ; Apple-Up (Open Parent)
        jeq     CmdOpenParent
        bit     window_open_flag
        bpl     menu_accelerators
        cmp     #kShortcutResize ; Apple-G (Resize)
        jeq     CmdResize
        cmp     #kShortcutMove  ; Apple-M (Move)
        jeq     CmdMove
        cmp     #kShortcutScroll ; Apple-X (Scroll)
        jeq     CmdScroll
        cmp     #CHAR_DELETE    ; Apple-Delete (Delete)
        jeq     CmdDeleteSelection
        cmp     #'`'            ; Apple-` (Cycle Windows)
        beq     cycle
        cmp     #'~'            ; Shift-Apple-` (Cycle Windows)
        beq     cycle
        cmp     #CHAR_TAB       ; Apple-Tab (Cycle Windows)
        bne     menu_accelerators
cycle:  jmp     CmdCycleWindows

        ;; Not one of our shortcuts - check for menu keys
        ;; (shortcuts or entering keyboard menu mode)
menu_accelerators:
        copy    event_params::key, menu_click_params::which_key
        lda     event_params::modifiers
        beq     :+
        lda     #1              ; treat Solid-Apple same as Open-Apple
:       sta     menu_click_params::key_mods
        copy    #$80, menu_kbd_flag ; note that source is keyboard
        MGTK_RELAY_CALL MGTK::MenuKey, menu_click_params

MenuDispatch2:
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
        copy    #0, menu_click_params::menu_id ; for `ToggleMenuHilite`
        rts

call_proc:
        tsx
        stx     saved_stack
        proc_addr := *+1
        jmp     SELF_MODIFIED
.endproc

HandleKeydown   := HandleKeydownImpl::HandleKeydown
MenuDispatch2   := HandleKeydownImpl::MenuDispatch2
window_open_flag := HandleKeydownImpl::window_open_flag

;;; ============================================================
;;; Handle click

.proc HandleClick
        tsx
        stx     saved_stack
        MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        bne     not_desktop

        ;; Click on desktop
        copy    #0, findwindow_params::window_id
        ITK_RELAY_CALL IconTK::FindIcon, event_params::coords
        lda     findicon_params::which_icon
        jne     HandleVolumeIconClick

        jmp     DesktopDragSelect

not_desktop:
        cmp     #MGTK::Area::menubar  ; menu?
        bne     not_menu
        copy    #0, menu_kbd_flag ; note that source is not keyboard
        MGTK_RELAY_CALL MGTK::MenuSelect, menu_click_params
        jmp     MenuDispatch2

not_menu:
        pha                     ; which window - active or not?
        lda     active_window_id
        cmp     findwindow_params::window_id
        beq     HandleActiveWindowClick
        pla
        jmp     HandleInactiveWindowClick
.endproc

;;; ============================================================
;;; Inputs: MGTK::Area pushed to stack

.proc HandleActiveWindowClick
        pla
        cmp     #MGTK::Area::content
        jeq     HandleClientClick
        cmp     #MGTK::Area::dragbar
        jeq     HandleTitleClick
        cmp     #MGTK::Area::grow_box
        jeq     HandleResizeClick
        cmp     #MGTK::Area::close_box
        jeq     HandleCloseClick
        rts
.endproc

;;; ============================================================
;;; Inputs: window id to activate in `findwindow_params::window_id`

;;; Activate the window, and sets selection to its parent icon
.proc HandleInactiveWindowClick
        jsr     ClearSelection

        jsr     ActivateWindow

        ;; Try to select the window's parent icon. (Only works
        ;; for volume icons, otherwise it would put selection
        ;; in an inactive window.)
        lda     active_window_id
        jmp     SelectIconForWindow
.endproc

;;; Inputs: window id to activate in `findwindow_params::window_id`
.proc ActivateWindow
        ;; Make the window active.
        MGTK_RELAY_CALL MGTK::SelectWindow, findwindow_params::window_id
        copy    findwindow_params::window_id, active_window_id
        jsr     LoadActiveWindowEntryTable ; restored below
        jsr     DrawWindowEntries
        jsr     LoadDesktopEntryTable ; restore from above

        ;; Update menu items
        copy    #MGTK::checkitem_uncheck, checkitem_params::check
        jsr     CheckItem
        jsr     GetActiveWindowViewBy
        and     #kViewByMenuMask
        sta     checkitem_params::menu_item
        inc     checkitem_params::menu_item
        copy    #MGTK::checkitem_check, checkitem_params::check
        jmp     CheckItem
.endproc

;;; ============================================================
;;; Inputs: A = window_id
;;; Selection should be cleared before calling

.proc SelectIconForWindow
        ptr := $06

        ;; Select window's corresponding volume icon.
        ;; (Doesn't work for folder icons as only the active
        ;; window and desktop can have selections.)
        tax
        dex
        lda     window_to_dir_icon_table,x
        bmi     done            ; $FF = dir icon freed

        sta     icon_param
        lda     icon_param
        jsr     IconEntryLookup
        stax    ptr

        ldy     #IconEntry::state ; set state to open
        lda     (ptr),y
        beq     done
        ora     #kIconEntryFlagsOpen
        sta     (ptr),y

        iny                     ; IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        beq     :+
        cmp     active_window_id ; This should never be true
        bne     done

:       sta     selected_window_id
        copy    #1, selected_icon_count
        copy    icon_param, selected_icon_list
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param

        lda     icon_param
        jsr     DrawIcon

done:   rts
.endproc

;;; ============================================================
;;; Draw an icon in its window/on the desktop.
;;; This handles skipping if the window is obscured.
;;;
;;; Inputs: A = icon id
;;; Outputs: sets `icon_param` to the icon id
;;; Assert: `ResetMainGrafport` state is in effect (and restored)
;;; Assert: If windowed, the icon is in the active window.

.proc DrawIcon
        sta     icon_param
        jsr     PushPointers

        ;; Look up the icon
        icon_ptr := $06
        lda     icon_param
        jsr     IconEntryLookup
        stax    icon_ptr

        ;; Get the window id
        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        sta     win

        ;; Set up the port and draw the icon
        beq     :+
        lda     icon_param
        jsr     IconScreenToWindow
        win := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        bne     skip            ; MGTK::Error::window_obscured
:       ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED
skip:   lda     win
        beq     :+
        lda     icon_param
        jsr     IconWindowToScreen
        jsr     ResetMainGrafport
:
        jsr     PopPointers
        rts
.endproc

;;; ============================================================

;;; Used only for file windows; adjusts port to account for header.
;;; Returns 0 if ok, `MGTK::Error::window_obscured` if the window is obscured.
.proc UnsafeOffsetAndSetPortFromWindowId
        sta     getwinport_params::window_id
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params
        bne     :+              ; MGTK::Error::window_obscured
        jsr     OffsetWindowGrafportAndSet
        lda     #0
:       rts
.endproc

;;; Used for all sorts of windows, not just file windows.
;;; For file windows, used for drawing headers (sometimes);
;;; Returns 0 if ok, `MGTK::Error::window_obscured` if the window is obscured.
.proc UnsafeSetPortFromWindowId
        sta     getwinport_params::window_id
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params
        bne     :+              ; MGTK::Error::window_obscured
        MGTK_RELAY_CALL MGTK::SetPort, window_grafport
:       rts
.endproc

;;; Used for windows that can never be obscured (e.g. dialogs)
.proc SafeSetPortFromWindowId
        sta     getwinport_params::window_id
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Result is not MGTK::Error::window_obscured
        MGTK_RELAY_CALL MGTK::SetPort, window_grafport
        rts
.endproc

;;; ============================================================
;;; Update table tracking disk-in-device status, determine if
;;; there was a change (insertion or ejection).
;;; Output: 0 if no change,

.proc CheckDiskInsertedEjected
        lda     disk_in_device_table
        beq     done
        jsr     CheckDisksInDevices
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

;;; Updated by `CheckDisksInDevices`
disk_in_device_table:
        .byte   0               ; num entries
        .res    kMaxRemovableDevices, 0

;;; Snapshot of previous results; used to detect changes.
last_disk_in_devices_table:
        .byte   0               ; num entries
        .res    kMaxRemovableDevices, 0

;;; ============================================================

.proc CheckDisksInDevices
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
        unit_number := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     FindSmartportDispatchAddress
        bne     notsp           ; not SmartPort
        stx     status_unit_num

        ;; Execute SmartPort call
        jsr     SmartportCall
        .byte   SPCall::Status
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
        result := *+1
        lda     #SELF_MODIFIED_BYTE
        rts

SmartportCall:
        jmp     (sp_addr)

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

.proc UpdateMenuItemStates
        ;; Selector List
        lda     num_selector_list_items
        beq     :+

        bit     selector_menu_items_updated_flag
        bmi     check_selection
        jsr     EnableSelectorMenuItems
        jmp     check_selection

:       bit     selector_menu_items_updated_flag
        bmi     check_selection
        jsr     DisableSelectorMenuItems

check_selection:
        lda     selected_icon_count
        beq     no_selection

        ;; --------------------------------------------------
        ;; Selected Icons

        lda     selected_window_id ; In a window?
        beq     :+

        ;; --------------------------------------------------
        ;; Files selected (not volumes)

        jsr     DisableMenuItemsRequiringVolumeSelection
        jsr     EnableMenuItemsRequiringFileSelection
        jsr     EnableMenuItemsRequiringSelection
        rts

        ;; --------------------------------------------------
        ;; Volumes selected (not files)

:       lda     selected_icon_count
        cmp     #1
        bne     :+
        lda     selected_icon_list
        cmp     trash_icon_num
        beq     no_selection    ; trash only - treat as no selection

        ;; At least one real volume
:       jsr     EnableMenuItemsRequiringVolumeSelection
        jsr     DisableMenuItemsRequiringFileSelection
        jsr     EnableMenuItemsRequiringSelection
        rts

        ;; --------------------------------------------------
        ;; No Selection
no_selection:
        jsr     DisableMenuItemsRequiringVolumeSelection
        jsr     DisableMenuItemsRequiringFileSelection
        jsr     DisableMenuItemsRequiringSelection
        rts

.endproc

;;; ============================================================
;;; Common re-used param blocks

        DEFINE_GET_FILE_INFO_PARAMS file_info_params, SELF_MODIFIED
        DEFINE_GET_FILE_INFO_PARAMS src_file_info_params, src_path_buf
        DEFINE_GET_FILE_INFO_PARAMS dst_file_info_params, dst_path_buf

        .assert src_path_buf = INVOKER_PREFIX, error, "Params re-use"
        .define get_file_info_params src_file_info_params

;;; Call GET_FILE_INFO on path at A,X; results are in `file_info_params`
;;; Output: MLI result (carry/zero flag, etc)
.proc GetFileInfo
        stax    file_info_params::pathname
        MLI_RELAY_CALL GET_FILE_INFO, file_info_params
        rts
.endproc

;;; ============================================================
;;; Launch file (File > Open, Selector menu, or double-click)

.proc LaunchFileImpl
        path := INVOKER_PREFIX

compose_path:
        jsr     ComposeWinFilePaths

with_path:
        jsr     SetCursorWatch ; before invoking

        ;; Get the file info to determine type.
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        jsr     ShowAlert
        rts

        ;; Check file type.
:       copy    get_file_info_params::file_type, icontype_filetype
        copy16  get_file_info_params::aux_type, icontype_auxtype
        copy16  get_file_info_params::blocks_used, icontype_blocks
        jsr     GetIconType

        cmp     #IconType::basic
        bne     :+
        jsr     CheckBasicSystem ; Only launch if BASIC.SYSTEM is found
        jeq     launch
        lda     #kErrBasicSysNotFound
        jmp     ShowAlert

:       cmp     #IconType::binary
        bne     :+
        lda     menu_click_params::menu_id ; From a menu (File, Selector)
        bne     launch
        jsr     ModifierDown ; Otherwise, only launch if a button is down
        bmi     launch
        jsr     SetCursorPointer ; after not launching BIN
        rts

:       cmp     #IconType::folder
        jeq     OpenFolder

        cmp     #IconType::system
        beq     launch

        cmp     #IconType::application
        beq     launch

        cmp     #IconType::graphics
        bne     :+
        param_jump InvokeDeskAcc, str_preview_fot

:       cmp     #IconType::text
        bne     :+
        param_jump InvokeDeskAcc, str_preview_txt

:       cmp     #IconType::font
        bne     :+
        param_jump InvokeDeskAcc, str_preview_fnt

:       cmp     #IconType::music
        bne     :+
        param_jump InvokeDeskAcc, str_preview_mus

:       cmp     #IconType::desk_accessory
    IF_EQ
        COPY_STRING path, path_buffer ; Use this to launch the DA

        ;; As a convenience for DAs, set path to first selected file.
        lda     selected_window_id
        beq     no_file_sel
        lda     selected_icon_count
        beq     no_file_sel

        jsr     CopyWinIconPaths
        jsr     ComposeWinFilePaths
        jmp     :+

no_file_sel:
        copy    #0, path        ; Signal no file selection

:       param_jump InvokeDeskAcc, path_buffer
    END_IF


        jsr     CheckBasisSystem ; Is fallback BASIS.SYSTEM present?
        beq     launch
        lda     #kErrFileNotOpenable
        jmp     ShowAlert

launch:
        ;; Copy/split path into prefix and filename
        param_call FindLastPathSegment, INVOKER_PREFIX ; point Y at last '/'
        tya
        pha
        ldx     #1
        iny                     ; +1 for length byte
        iny                     ; +1 to skip past '/'
:       copy    INVOKER_PREFIX,y, INVOKER_FILENAME,x
        cpy     INVOKER_PREFIX
        beq     :+
        iny
        inx
        bne     :-              ; always
:       stx     INVOKER_FILENAME
        pla
        sta     INVOKER_PREFIX

        copy16  #INVOKER, reset_and_invoke_target
        jmp     ResetAndInvoke

;;; --------------------------------------------------
;;; Check `buf_win_path` and ancestors to see if the desired interpreter
;;; (BASIC.SYSTEM or BASIS.SYSTEM) is present.
;;; Input: `buf_win_path` set to initial search path
;;; Output: zero if found, non-zero if not found

.proc CheckBasixSystemImpl
        launch_path := INVOKER_PREFIX
        tmp_path := $1800

basic:  lda     #'C'            ; "BASI?" -> "BASIC"
        bne     start           ; always

basis:  lda     #'S'            ; "BASI?" -> "BASIS"
        ;; fall through

start:  sta     str_basix_system + kBSOffset

        ldx     launch_path
        stx     path_length
:       copy    launch_path,x, tmp_path,x
        dex
        bpl     :-

        inc     tmp_path
        ldx     tmp_path
        copy    #'/', tmp_path,x
loop:
        ;; Append BASI?.SYSTEM to path and check for file.
        ldx     tmp_path
        ldy     #0
:       inx
        iny
        copy    str_basix_system,y, tmp_path,x
        cpy     str_basix_system
        bne     :-
        stx     tmp_path
        param_call GetFileInfo, tmp_path
        bne     not_found
        rts                     ; zero is success

        ;; Pop off a path segment and try again.
not_found:
        path_length := *+1
        ldx     #SELF_MODIFIED_BYTE
:       lda     tmp_path,x
        cmp     #'/'
        beq     found_slash
        dex
        bne     :-

no_bs:  return  #$FF            ; non-zero is failure

found_slash:
        cpx     #1
        beq     no_bs
        stx     tmp_path
        dex
        stx     path_length
        jmp     loop
.endproc
CheckBasicSystem        := CheckBasixSystemImpl::basic
CheckBasisSystem        := CheckBasixSystemImpl::basis

;;; --------------------------------------------------

.proc OpenFolder
        tsx
        stx     saved_stack

        .assert path = open_dir_path_buf, error, "Buffer alias"
        jsr     OpenWindowForPath

        jmp     SetCursorPointer ; after opening folder
.endproc

;;; --------------------------------------------------

.proc ComposeWinFilePaths
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

        rts
.endproc

.endproc
LaunchFile         := LaunchFileImpl::compose_path ; use `buf_win_path` + `buf_filename2`
LaunchFileWithPath := LaunchFileImpl::with_path ; use `INVOKER_PREFIX`

;;; ============================================================

.proc UpcaseChar
        cmp     #'a'
        bcc     done
        cmp     #'z'+1
        bcs     done
        and     #CASE_MASK
done:   rts
.endproc

;;; ============================================================
;;; Inputs: Character in A
;;; Outputs: Z=1 if alpha, 0 otherwise
;;; A is trashed

.proc IsAlpha
        cmp     #'@'            ; in upper/lower "plane" ?
        bcc     nope
        and     #CASE_MASK      ; force upper-case
        cmp     #'A'
        bcc     nope
        cmp     #'Z'+1
        bcs     nope

        lda     #0
        rts

nope:   lda     #$FF
        rts
.endproc

;;; ============================================================

kBSOffset       = 5             ; Offset of 'x' in BASIx.SYSTEM
str_basix_system:
        PASCAL_STRING "BASIx.SYSTEM" ; do not localize

str_preview_fot:
        PASCAL_STRING .concat(kFilenamePreviewDir, "/show.image.file") ; do not localize

str_preview_fnt:
        PASCAL_STRING .concat(kFilenamePreviewDir, "/show.font.file") ; do not localize

str_preview_txt:
        PASCAL_STRING .concat(kFilenamePreviewDir, "/show.text.file") ; do not localize

str_preview_mus:
        PASCAL_STRING .concat(kFilenamePreviewDir, "/show.duet.file") ; do not localize

;;; ============================================================

str_empty:
        PASCAL_STRING ""        ; do not localize

;;; ============================================================
;;; Aux $D000-$DFFF b2 holds FileRecord entries. These are stored
;;; with a one byte length prefix, then sequential FileRecords.
;;; Not counting the prefix, this gives room for 128 entries.
;;; Only 127 icons are supported and volumes don't get entries,
;;; so this is enough.

;;; `window_id_to_filerecord_list_*` maps win id to list num
;;; `window_filerecord_table` maps from list num to address

file_records_buffer := $D000
kFileRecordsBufferLen = $1000
        .assert kFileRecordsBufferLen > .sizeof(FileRecord) * kMaxIconCount, error, "Size mismatch"

;;; This remains constant:
filerecords_free_end:
        .word   file_records_buffer + kFileRecordsBufferLen

;;; This tracks the start of free space.
filerecords_free_start:
        .word   file_records_buffer

;;; ============================================================

.proc RestoreDeviceList
        ldx     devlst_backup
        inx                     ; include the count itself
:       copy    devlst_backup,x, DEVLST-1,x ; DEVCNT is at DEVLST-1
        dex
        bpl     :-
        rts
.endproc

;;; ============================================================

.proc CmdNoOp
        rts
.endproc

;;; ============================================================

.proc CmdSelectorAction
        lda     #kDynamicRoutineSelector1 ; selector picker dialog
        jsr     LoadDynamicRoutine
        bmi     done

        lda     menu_click_params::item_num
        cmp     #SelectorAction::delete
        bcs     :+              ; delete or run (no need for more overlays)

        lda     #kDynamicRoutineSelector2 ; file dialog driver
        jsr     LoadDynamicRoutine
        bmi     done
        lda     #kDynamicRoutineFileDialog ; file dialog
        jsr     LoadDynamicRoutine
        bmi     done

:
        ;; Invoke routine
        lda     menu_click_params::item_num
        jsr     selector_picker__Exec
        sta     result

        ;; Restore from overlays
        ;; (restore from file dialog overlay handled in picker overlay)
        lda     #kDynamicRoutineRestore9000 ; restore from picker dialog
        jsr     RestoreDynamicRoutine

        lda     menu_click_params::item_num
        cmp     #SelectorAction::run
        bne     done

        ;; "Run" command
        result := *+1
        lda     #SELF_MODIFIED_BYTE
        bpl     done
        jsr     MakeRamcardPrefixedPath
        jsr     StripPathSegments
        jsr     GetCopiedToRAMCardFlag
        bpl     run_from_ramcard

        ;; Need to copy to RAMCard
        jsr     DoCopyToRAM
        bmi     done
        jsr     L4968

done:   rts

.proc L4968
        jsr     MakeRamcardPrefixedPath
        COPY_STRING $840, buf_win_path
        jmp     LaunchBufWinPath
.endproc

        ;; Was already copied to RAMCard, so update path then run.
run_from_ramcard:
        jsr     MakeRamcardPrefixedPath
        COPY_STRING $800, buf_win_path
        jsr     LaunchBufWinPath
        jmp     done
.endproc


;;; ============================================================

.proc CmdSelectorItem
        lda     menu_click_params::item_num
        sec
        sbc     #6              ; 4 items + separator (and make 0 based)
        sta     entry_num

        jsr     ATimes16
        addax   #run_list_entries, $06

        ldy     #kSelectorEntryFlagsOffset ; flag byte following name
        lda     ($06),y
        asl     a
        bmi     not_downloaded  ; bit 6
        bcc     L49E0           ; bit 7

        jsr     GetCopiedToRAMCardFlag
        beq     not_downloaded
        lda     entry_num
        jsr     CheckDownloadedPath
        beq     L49ED

        lda     entry_num
        jsr     L4A47
        jsr     DoCopyToRAM
        bpl     L49ED
        rts

L49E0:  jsr     GetCopiedToRAMCardFlag
        beq     not_downloaded

        lda     entry_num
        jsr     CheckDownloadedPath           ; was-downloaded flag check?
        bne     not_downloaded

L49ED:  lda     entry_num
        jsr     ComposeDownloadedEntryPath
        stax    $06
        jmp     L4A0A

not_downloaded:
        lda     entry_num
        jsr     ATimes64
        addax   #run_list_paths, $06

L4A0A:  param_call CopyPtr1ToBuf, buf_win_path
        ;; fall through

.proc LaunchBufWinPath
        ;; Find last '/'
        ldy     buf_win_path
:       lda     buf_win_path,y
        cmp     #'/'
        beq     :+
        dey
        bpl     :-

:       dey
        tya
        pha                     ; A = slash index

        ;; Copy filename to buf_filename2
        ldx     #0
        iny
:       iny
        inx
        lda     buf_win_path,y
        sta     buf_filename2,x
        cpy     buf_win_path
        bne     :-
        stx     buf_filename2

        ;; Truncate path
        pla                     ; A = slash index
        sta     buf_win_path
        lda     #0

        jmp     LaunchFile
.endproc

entry_num:
        .byte   0

;;; --------------------------------------------------

        ;; Copy entry path to $800
.proc L4A47
        pha
        jsr     ATimes64
        addax   #run_list_paths, $06
        param_call CopyPtr1ToBuf, $800

        ;; Copy "down loaded" path to $840
        pla
        jsr     ComposeDownloadedEntryPath
        param_call CopyPtr2ToBuf, $840
        ;; fall through
.endproc

        ;; Strip segment off path at $800
.proc StripPathSegments
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

        jsr     CopyPathsFromPtrsToBufsAndSplitName
        rts
.endproc

;;; --------------------------------------------------
;;; Append last two path segments of `buf_win_path` to
;;; `ramcard_prefix`, result left at $840

.proc MakeRamcardPrefixedPath
        ;; Copy window path to $800
        ldy     buf_win_path
:       lda     buf_win_path,y
        sta     $800,y
        dey
        bpl     :-

        param_call CopyRAMCardPrefix, $840

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

.proc CheckDownloadedPath
        jsr     ComposeDownloadedEntryPath
        jmp     GetFileInfo
.endproc

.endproc

LaunchBufWinPath        := CmdSelectorItem::LaunchBufWinPath
StripPathSegments       := CmdSelectorItem::StripPathSegments
MakeRamcardPrefixedPath := CmdSelectorItem::MakeRamcardPrefixedPath

;;; ============================================================
;;; Copy the string at $06 to target at A,X
;;; Inputs: Source string at $06, target buffer at A,X
;;; Output: String length in A

.proc CopyPtr1ToBuf
        ptr1 := $06

        stax    addr
        ldy     #0
        lda     (ptr1),y
        tay
:       lda     (ptr1),y
        addr := *+1
        sta     SELF_MODIFIED,y
        dey
        bpl     :-
        rts
.endproc

;;; Copy the string at $08 to target at A,X
;;; Inputs: Source string at $08, target buffer at A,X
;;; Output: String length in A
.proc CopyPtr2ToBuf
        ptr2 := $08

        stax    addr
        ldy     #0
        lda     (ptr2),y
        tay
:       lda     (ptr2),y
        addr := *+1
        sta     SELF_MODIFIED,y
        dey
        bpl     :-
        rts
.endproc

;;; ============================================================
;;; Append filename to directory path in `path_buffer`
;;; Inputs: A,X = ptr to path suffix to append
;;; Outputs: `path_buffer` has '/' and suffix appended

.proc AppendFilenameToPathBuffer

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
        lda     SELF_MODIFIED,x
        sta     path_buffer,y
        @filename2 := *+1
        cpx     SELF_MODIFIED
        bne     :-
        sty     path_buffer

        rts

.endproc

;;; ============================================================

        .include "../lib/ramcard.s"
        .assert * <= $5000, error, "Routine used by overlays in overlay zone"

;;; ============================================================
;;; For entry copied ("down loaded") to RAM card, compose path
;;; using RAM card prefix plus last two segments of path
;;; (e.g. "/RAM" + "/" + "MOUSEPAINT/MP.SYSTEM") into `path_buffer`

.proc ComposeDownloadedEntryPath
        sta     entry_num

        ;; Initialize buffer
        param_call CopyRAMCardPrefix, path_buffer

        ;; Find entry path
        entry_num := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     ATimes64
        addax   #run_list_paths, $06
        ldy     #0
        lda     ($06),y
        sta     @prefix_length

        ;; Walk back one segment
        tay
:       lda     ($06),y
        cmp     #'/'
        beq     :+
        dey
        bne     :-

:       dey

        ;; Walk back a second segment
:       lda     ($06),y
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
        @prefix_length := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     :-

        stx     path_buffer
        ldax    #path_buffer
        rts
.endproc

;;; ============================================================

.proc CmdAbout
        param_call invoke_dialog_proc, kIndexAboutDialog, $0000
        rts
.endproc

;;; ============================================================

.proc CmdDeskaccImpl
        ptr := $6
        path := INVOKER_PREFIX

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, path

str_desk_acc:
        PASCAL_STRING .concat(kFilenameDADir, "/") ; do not localize

start:  jsr     ResetMainGrafport
        jsr     SetCursorWatch  ; before loading DA

        ;; Get current prefix
        MLI_RELAY_CALL GET_PREFIX, get_prefix_params

        ;; Find DA name
        lda     menu_click_params::item_num           ; menu item index (1-based)
        sec
        sbc     #3              ; About and separator before first item
        tay
        ldax    #kDAMenuItemSize
        jsr     Multiply_16_8_16
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
skip:   iny
        lda     ($06),y
        cmp     #' '            ; Convert spaces back to periods
        bcc     skip            ; Ignore control characters
        bne     :+
        lda     #'.'
:       sta     path,x
        len := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     loop
        stx     path

        ;; Allow arbitrary types in menu (e.g. folders)
        jmp     LaunchFileWithPath
.endproc
CmdDeskAcc      := CmdDeskaccImpl::start

;;; ============================================================
;;; Invoke Desk Accessory
;;; Input: A,X = address of pathname buffer

.proc InvokeDeskAcc
        stax    open_pathname

        ;; Load the DA
@retry: MLI_RELAY_CALL OPEN, open_params
        beq     :+
        lda     #kErrInsertSystemDisk
        jsr     ShowAlert
        cmp     #kAlertResultOK
        beq     @retry          ; ok, so try again
        rts                     ; cancel, so fail
:
        lda     open_ref_num
        sta     read_ref_num
        sta     close_ref_num
        MLI_RELAY_CALL READ, read_params
        MLI_RELAY_CALL CLOSE, close_params

        ;; Invoke it
        jsr     SetCursorPointer ; before invoking DA
        jsr     ResetMainGrafport
        MGTK_RELAY_CALL MGTK::SetZP1, setzp_params_preserve
        jsr     DA_LOAD_ADDRESS
        MGTK_RELAY_CALL MGTK::SetZP1, setzp_params_nopreserve

        ;; Restore state
        jsr     ShowClockForceUpdate
        jsr     ResetMainGrafport
done:   jsr     SetCursorPointer ; after invoking DA
        rts

        DEFINE_OPEN_PARAMS open_params, 0, DA_IO_BUFFER
        open_ref_num := open_params::ref_num
        open_pathname := open_params::pathname

        DEFINE_READ_PARAMS read_params, DA_LOAD_ADDRESS, kDAMaxSize
        read_ref_num := read_params::ref_num

        DEFINE_CLOSE_PARAMS close_params
        close_ref_num := close_params::ref_num

.endproc

;;; ============================================================

.proc CmdCopyFile
        lda     #kDynamicRoutineFileDialog
        jsr     LoadDynamicRoutine
        bpl     :+
        rts
:
        lda     #kDynamicRoutineFileCopy
        jsr     LoadDynamicRoutine
        bpl     :+
        rts
:
        lda     #$00
        jsr     file_dialog__Exec
        pha                     ; A = dialog result
        lda     #kDynamicRoutineRestore5000
        jsr     RestoreDynamicRoutine
        jsr     PushPointers   ; $06 = src / $08 = dst
        jsr     ClearUpdates ; following picker dialog close
        jsr     PopPointers    ; $06 = src / $08 = dst
        pla                     ; A = dialog result
        bpl     :+
        rts
:
        ;; --------------------------------------------------
        ;; Try the copy

        ;; Validate
        src := $06
        ldax    src
        jsr     CopyToSrcPath

        dst := $08
        ldax    dst
        jsr     CopyToDstPath

        jsr     CheckRecursion
        jne     ShowAlert
        jsr     CheckBadReplacement
        jne     ShowAlert

        ;; Copy
        jsr     CopyPathsFromPtrsToBufsAndSplitName
        jsr     DoCopyFile
        ;; result is ignored; update regardless

        ;; --------------------------------------------------
        ;; Update windows with results

        ;; See if there's a window we should activate later.
        param_call FindWindowForPath, path_buf4
        pha                     ; save for later

        ;; Update cached used/free for all same-volume windows
        param_call UpdateUsedFreeViaPath, path_buf4

        ;; Select/refresh window if there was one
        pla
        jne     SelectAndRefreshWindowOrClose

        rts

.endproc

;;; ============================================================
;;; Copy string at ($6) to `path_buf3`, string at ($8) to `path_buf4`,
;;; split filename off `path_buf4` and store in `filename_buf`

.proc CopyPathsFromPtrsToBufsAndSplitName

        ;; Copy string at $6 to `path_buf3`
        param_call CopyPtr1ToBuf, path_buf3

        ;; Copy string at $8 to `path_buf4`
        param_call CopyPtr2ToBuf, path_buf4

        param_call FindLastPathSegment, path_buf4

        ;; Copy filename part to buf
        ldx     #1
        iny                     ; +1 for length byte
        iny                     ; +1 to skip past '/'
:       lda     path_buf4,y
        sta     filename_buf,x
        cpy     path_buf4
        beq     :+
        iny
        inx
        jmp     :-

:       stx     filename_buf

        ;; And remove from `path_buf4`
        lda     path_buf4
        sec
        sbc     filename_buf
        sta     path_buf4
        dec     path_buf4
        rts
.endproc

;;; ============================================================

.proc CmdDeleteFile
        lda     #kDynamicRoutineFileDialog
        jsr     LoadDynamicRoutine
        bpl     :+
        rts
:
        lda     #kDynamicRoutineFileDelete
        jsr     LoadDynamicRoutine
        bpl     :+
        rts
:
        lda     #$01
        jsr     file_dialog__Exec
        pha                     ; A = dialog result
        lda     #kDynamicRoutineRestore5000
        jsr     RestoreDynamicRoutine
        jsr     PushPointers   ; $06 is path
        jsr     ClearUpdates ; following picker dialog close
        jsr     PopPointers    ; $06 is path
        pla                     ; A = dialog result
        bpl     :+
        rts
:
        ;; --------------------------------------------------
        ;; Try the delete

        param_call CopyPtr1ToBuf, path_buf3

        jsr     DoDeleteFile
        cmp     #kOperationCanceled
        bne     :+
        rts
:

        ;; --------------------------------------------------
        ;; Update windows with results

        copy    #$80, validate_windows_flag

        ;; Strip filename, so it's just the containing path.
        param_call FindLastPathSegment, path_buf3
        sty     path_buf3

        ;; See if there's a window we should activate later.
        param_call FindWindowForPath, path_buf3
        pha                     ; save for later

        ;; Update cached used/free for all same-volume windows
        param_call UpdateUsedFreeViaPath, path_buf3

        ;; Select/refresh window if there was one
        pla
        jne     SelectAndRefreshWindowOrClose

        rts
.endproc

;;; ============================================================

.proc CmdOpen
        ptr := $06

        selected_icon_count_copy := $1F80
        selected_icon_list_copy := $1F81
        .assert selected_icon_list_copy + kMaxIconCount <= $2000, error, "overlap"

        ;; --------------------------------------------------
        ;; Entry point from menu

        ;; Close after open only if from real menu, and modifier is down.
        copy    #0, window_id_to_close
        bit     menu_kbd_flag   ; If keyboard (Apple-O) ignore. (see issue #9)
        bmi     :+
        jsr     ModifierDown
        bpl     :+
        copy    selected_window_id, window_id_to_close
:
        jmp     common


        ;; --------------------------------------------------
        ;; Entry point from OA+SA+O

open_then_close_parent:
        lda     selected_icon_count
        bne     :+
        rts
:       copy    selected_window_id, window_id_to_close
        jmp     common

        ;; --------------------------------------------------
        ;; Entry point from Apple+Down

        ;; Never close after open only.
from_keyboard:
        lda     selected_icon_count
        bne     :+
        rts
:       copy    #0, window_id_to_close
        jmp     common

        ;; --------------------------------------------------
        ;; Entry point from double-click

        ;; Close after open if modifier is down.
from_double_click:
        copy    #0, window_id_to_close
        jsr     ModifierDown
        bpl     :+
        copy    selected_window_id, window_id_to_close
:
        ;; fall through

        ;; --------------------------------------------------
common:
        copy    #0, dir_flag

        ;; Make a copy of selection
        ldx     selected_icon_count
        stx     selected_icon_count_copy
:       lda     selected_icon_list-1,x
        sta     selected_icon_list_copy-1,x
        dex
        bne     :-

        ldx     #0
loop:   cpx     selected_icon_count_copy
        bne     next

        ;; Finish up...

        ;; Were any directories opened?
        lda     dir_flag
        beq     done

        ;; Maybe close the previously active window, depending on source/modifiers
        jsr     MaybeCloseWindowAfterOpen

done:   rts

next:   txa
        pha
        lda     selected_icon_list_copy,x

        ;; Trash?
        cmp     trash_icon_num
        beq     next_icon

        ;; Look at flags...
        jsr     IconEntryLookup
        stax    ptr

        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryFlagsDropTarget ; folder or volume?
        beq     maybe_open_file       ; nope

        ;; Directory

        ;; Set when we see the first vol/folder icon, so we can
        ;; clear selection (if it's a folder).
        dir_flag := *+1         ; first one seen?
        lda     #SELF_MODIFIED_BYTE

        bne     :+              ; not the first
        inc     dir_flag        ; only do this once
        lda     selected_window_id ; selection in a window?
        beq     :+                 ; no
        jsr     ClearSelection
:

        ldy     #0
        lda     (ptr),y
        jsr     OpenWindowForIcon

next_icon:
        pla
        tax
        inx
        jmp     loop

        ;; File (executable or data)
maybe_open_file:
        lda     selected_icon_count_copy
        cmp     #2              ; multiple files open?
        bcs     next_icon       ; don't try to invoke

        pla

        jsr     CopyWinIconPaths
        jmp     LaunchFile


;;; Close parent window after open, if needed. Done by activating then closing.
;;; Modifies `findwindow_params::window_id`
.proc MaybeCloseWindowAfterOpen
        lda     window_id_to_close
        beq     done

        pha
        sta     findwindow_params::window_id
        jsr     HandleInactiveWindowClick
        pla
        jsr     CloseWindow

done:   rts
.endproc

;;; Parent window to close
window_id_to_close:
        .byte   0
.endproc
CmdOpenThenCloseParent := CmdOpen::open_then_close_parent
CmdOpenFromDoubleClick := CmdOpen::from_double_click
CmdOpenFromKeyboard := CmdOpen::from_keyboard

;;; ============================================================
;;; Copy selection window and first selected icon paths to
;;; `buf_win_path` and `buf_filename2` respectively.

.proc CopyWinIconPaths
        ;; Copy window path to buf_win_path
        win_path_ptr := $06

        lda     selected_window_id
        jsr     GetWindowPath
        stax    win_path_ptr
        param_call CopyPtr1ToBuf, buf_win_path

        ;; Copy file path to buf_filename2
        icon_ptr := $06

        lda     selected_icon_list
        jsr     IconEntryLookup
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

        rts
.endproc


;;; ============================================================

.proc CmdOpenParent
        lda     active_window_id
        beq     done

        jsr     GetWindowPath
        .assert src_path_buf = open_dir_path_buf, error, "Buffer alias"
        jsr     CopyToSrcPath
        copy    open_dir_path_buf, prev ; previous length

        ;; Try removing last segment
        param_call FindLastPathSegment, open_dir_path_buf ; point Y at last '/'
        cpy     open_dir_path_buf

        beq     volume
        sty     open_dir_path_buf

        ;; --------------------------------------------------
        ;; Windowed

        ;; Try to open by path.
        tsx
        stx     saved_stack
        jsr     OpenWindowForPath

        ;; Calc the name
        name_ptr := $08
        copy16  #open_dir_path_buf, name_ptr
        inc     open_dir_path_buf           ; past the '/'
        add16_8 name_ptr, open_dir_path_buf ; point at suffix
        prev := *+1
        lda     #SELF_MODIFIED_BYTE
        sec
        sbc     open_dir_path_buf ; A = name length
        ldy     #0
        sta     (name_ptr),y    ; assign string length

        ;; Select by name
        jsr     SelectFileIconByName ; $08 = name

done:   rts

        ;; --------------------------------------------------
        ;; Find volume icon by name and select it.

volume: jsr     ClearSelection
        ldx     open_dir_path_buf ; Strip '/'
        dex
        stx     open_dir_path_buf+1
        ldax    #open_dir_path_buf+1
        ldy     #0              ; 0=desktop
        jsr     FindIconByName
        beq     :+
        jsr     SelectIcon
:       rts
.endproc

;;; ============================================================

.proc CmdClose
        icon_ptr := $06

        lda     active_window_id
        bne     :+
        rts

:       jmp     CloseWindow
.endproc

;;; ============================================================

.proc CmdCloseAll
        lda     active_window_id   ; current window
        beq     done            ; nope, done!
        jsr     CloseWindow    ; close it...
        jmp     CmdCloseAll   ; and try again
done:   rts
.endproc

;;; ============================================================

.proc CmdDiskCopy
        jsr     SaveWindows

        lda     #kDynamicRoutineDiskCopy
        jsr     LoadDynamicRoutine
        jpl     format_erase_overlay__Exec

        rts
.endproc

;;; ============================================================

.enum NewFolderDialogState
        open  = $00
        run   = $80
        close = $40
.endenum

.params new_folder_dialog_params
phase:  .byte   0
a_path: .addr   0
.endparams

.proc CmdNewFolderImpl

        ptr := $06

        ;; access = destroy/rename/write/read
        DEFINE_CREATE_PARAMS create_params, path_buffer, ACCESS_DEFAULT, FT_DIRECTORY,, ST_LINKED_DIRECTORY

path_buffer:
        .res    ::kPathBufferSize, 0              ; buffer is used elsewhere too

start:  copy    #NewFolderDialogState::open, new_folder_dialog_params::phase
        param_call invoke_dialog_proc, kIndexNewFolderDialog, new_folder_dialog_params

L4FC6:  lda     active_window_id
        beq     :+
        jsr     GetWindowPath
        stax    new_folder_dialog_params::a_path

:       copy    #NewFolderDialogState::run, new_folder_dialog_params::phase
        param_call invoke_dialog_proc, kIndexNewFolderDialog, new_folder_dialog_params
        jne     done            ; Canceled

        stx     ptr+1
        stx     name_ptr+1
        sty     ptr
        sty     name_ptr

        ;; Copy path
        param_call CopyPtr1ToBuf, path_buffer

        ;; Create with current date
        COPY_STRUCT DateTime, DATELO, create_params::create_date

        ;; Create folder
        MLI_RELAY_CALL CREATE, create_params
        beq     success

        ;; Failure
        jsr     ShowAlert
        jmp     L4FC6

success:
        copy    #NewFolderDialogState::close, new_folder_dialog_params::phase
        param_call invoke_dialog_proc, kIndexNewFolderDialog, new_folder_dialog_params
        param_call FindLastPathSegment, path_buffer
        sty     path_buffer
        param_call FindWindowForPath, path_buffer
        beq     done

        jsr     SelectAndRefreshWindowOrClose
        bne     done

        copy16  #path_buf1, $08
        jsr     SelectFileIconByName ; $08 = folder name

done:   rts


name_ptr:
        .addr   0
.endproc
CmdNewFolder    := CmdNewFolderImpl::start
path_buffer     := CmdNewFolderImpl::path_buffer

;;; ============================================================
;;; Select and scroll into view an icon in the active window.
;;; No-op if the active window is a list view.
;;; Inputs: $08 = name
;;; Trashes $06

.proc SelectFileIconByName
        ptr_icon := $6
        ptr_name := $8          ; Input

        ldax    ptr_name
        ldy     active_window_id
        jsr     FindIconByName
        beq     ret             ; not found

        pha
        jsr     SelectFileIcon
        jsr     LoadActiveWindowEntryTable ; restored below
        pla
        jsr     ScrollIconIntoView
        jsr     LoadDesktopEntryTable ; restore from above

ret:    rts
.endproc

;;; ============================================================
;;; Find an icon by name in the given window.
;;; Inputs: Y = window id, A,X = name
;;; Outputs: Z=0, A = icon id (or Z=1, A=0 if not found)
;;; Assert: Desktop icon table cached in (and restored)

.proc FindIconByName
        ptr_icon := $06
        ptr_name := $08

        stax    tmp             ; name

        ;; Icon view?
        tya                     ; window id
        tax
        dex
        lda     win_view_by_table,x
        bpl     :+
        lda     #0              ; list view = not found
        rts

:       jsr     PushPointers

        copy16  tmp, ptr_name
        sty     cached_window_id
        jsr     LoadWindowEntryTable ; restored below

        ;; Iterate icons
        copy    #0, icon

        icon := *+1
loop:   ldx     #SELF_MODIFIED_BYTE
        cpx     cached_window_entry_count
        bne     :+

        ;; Not found
        copy    #0, icon
        beq     done            ; always

        ;; Compare with name from dialog
:       lda     cached_window_entry_list,x
        jsr     IconEntryLookup
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
        jsr     UpcaseChar
        sta     @char
        lda     (ptr_name),y
        jsr     UpcaseChar
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     next
        dey
        bne     cloop

        ;; Match!
        ldx     icon
        lda     cached_window_entry_list,x
        sta     icon

done:   jsr     LoadDesktopEntryTable ; restore from above
        jsr     PopPointers
        lda     icon
        rts

next:   inc     icon
        bne     loop

tmp:    .addr   0
.endproc

;;; ============================================================
;;; Save/Restore drop target icon ID in case the window was rebuilt.

;;; Inputs: `drag_drop_params::result`
;;; Assert: If taget is a file icon, icon is in active window.
;;; Trashes $06
.proc MaybeStashDropTargetName
        icon_ptr := $06

        ;; Flag as not stashed
        ldy     #0
        sty     stashed_name

        ;; Is the target an icon?
        lda     drag_drop_params::result
        bmi     done            ; high bit set = window

        jsr     IconEntryLookup
        stax    icon_ptr

        ldy     #IconEntry::win_flags ; file icon?
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        beq     done            ; nope, vol icon

        ;; Stash name
        add16_8 icon_ptr, #IconEntry::name
        param_call CopyPtr1ToBuf, stashed_name

done:   rts
.endproc

;;; Outputs: `drag_drop_params::result` updated if needed
;;; Assert: `MaybeStashDropTargetName` was previously called
;;; Trashes $06
.proc MaybeUpdateDropTargetFromName
        ;; Did we previously stash an icon's name?
        lda     stashed_name
        beq     done            ; not stashed

        ;; Try to find the icon by name.
        lda     cached_window_id
        sta     prev_cached_window_id
        jsr     LoadDesktopEntryTable ; expected by `FindIconByName`
        ldy     active_window_id
        ldax    #stashed_name
        jsr     FindIconByName
        pha
        prev_cached_window_id := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     LoadWindowEntryTable ; restore previous state
        pla                          ; A = `FindIconByName` result
        beq     done                 ; no match

        ;; Update drop target with new icon id.
        sta     drag_drop_params::result

done:   rts
.endproc

stashed_name:
        .res    16, 0

;;; ============================================================
;;; Grab the bounds (MGTK::Rect) of an icon. Just the graphic,
;;; not the label.
;;; Inputs: A = icon number
;;; Outputs: `cur_icon_bounds` is filled, $06 points at icon entry

        DEFINE_RECT cur_icon_bounds, 0, 0, 0, 0

.proc CacheIconBounds
        entry_ptr := $06
        icondef_ptr := $08

        jsr     IconEntryLookup
        stax    entry_ptr

        ;; Position
        ldy     #IconEntry::iconx+.sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     (entry_ptr),y
        sta     cur_icon_bounds::topleft,x
        dey
        dex
        bpl     :-

        ;; Size
        ldy     #IconEntry::iconbits
        lda     (entry_ptr),y
        sta     icondef_ptr
        iny
        lda     (entry_ptr),y
        sta     icondef_ptr+1

        ldy     #IconDefinition::maprect+MGTK::Rect::bottomright+.sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     (icondef_ptr),y
        sta     cur_icon_bounds::bottomright,x
        dey
        dex
        bpl     :-

        ;; Turn size into bounds
        add16   cur_icon_bounds::x1, cur_icon_bounds::x2, cur_icon_bounds::x2
        add16   cur_icon_bounds::y1, cur_icon_bounds::y2, cur_icon_bounds::y2

        rts
.endproc

;;; ============================================================
;;; Input: Icon number in A. Must be in active window.

.proc ScrollIconIntoView
        icon_ptr := $06

        sta     icon_num

        ;; Map coordinates to window
        jsr     IconScreenToWindow

        ;; Grab the icon coords
        icon_num := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     CacheIconBounds

        ;; Restore coordinates
        lda     icon_num
        jsr     IconWindowToScreen

        jsr     PrepareHighlightGrafport
        jsr     ApplyActiveWinfoToWindowGrafport

        copy    #0, dirty

        ;; --------------------------------------------------
        ;; X adjustment

        ;; Is left of icon beyond window? If so, adjust by delta (negative)
        sub16_8 cur_icon_bounds::x1, #kIconBBoxOffsetLeft, delta
        sub16   delta, window_grafport::cliprect::x1, delta
        bmi     adjustx

        ;; Is right of icon beyond window? If so, adjust by delta (positive)
        add16_8 cur_icon_bounds::x1, #kIconBBoxOffsetRight
        sub16   cur_icon_bounds::x1, window_grafport::cliprect::x2, delta
        bmi     donex

adjustx:
        lda     delta
        ora     delta+1
        beq     donex

        inc     dirty
        add16   window_grafport::cliprect::x1, delta, window_grafport::cliprect::x1
        add16   window_grafport::cliprect::x2, delta, window_grafport::cliprect::x2

donex:

        ;; --------------------------------------------------
        ;; Y adjustment

        ;; Is top of icon beyond window? If so, adjust by delta (negative)
        sub16_8 cur_icon_bounds::y1, #kIconBBoxOffsetTop, delta
        sub16   delta, window_grafport::cliprect::y1, delta
        bmi     adjusty

        ;; Is bottom of icon beyond window? If so, adjust by delta (positive)
        add16_8 cur_icon_bounds::y2, #kIconBBoxOffsetBottom
        sub16   cur_icon_bounds::y2, window_grafport::cliprect::y2, delta
        bmi     doney

adjusty:
        lda     delta
        ora     delta+1
        beq     doney

        inc     dirty
        add16   window_grafport::cliprect::y1, delta, window_grafport::cliprect::y1
        add16   window_grafport::cliprect::y2, delta, window_grafport::cliprect::y2

doney:
        dirty := *+1
        lda     #SELF_MODIFIED_BYTE
        beq     done

        jsr     CachedIconsScreenToWindow ; assumed by...
        jsr     FinishScrollAdjustAndRedraw

done:   rts

delta:  .word   0
.endproc

;;; ============================================================

.proc CmdCheckOrEject
        buffer := $1800

eject:  lda     #$80
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
check:  lda     #0
        sta     eject_flag

        ;; Ensure that volumes are selected
        lda     selected_window_id
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
        jsr     DoEject
:

        ;; Check each of the recorded volumes
        count := *+1
loop2:  ldx     #SELF_MODIFIED_BYTE
        lda     buffer,x
        sta     drive_to_refresh ; icon number
        jsr     CmdCheckSingleDriveByIconNumber
        dec     count
        bpl     loop2

        rts

eject_flag:
        .byte   0
.endproc
        CmdEject        := CmdCheckOrEject::eject
        CmdCheckDrive   := CmdCheckOrEject::check

;;; ============================================================

.proc CmdQuitImpl
        ;; TODO: Assumes prefix is retained. Compose correct path.

        quit_code_io := $800
        quit_code_addr := $1000
        quit_code_size := $400

        DEFINE_OPEN_PARAMS open_params, str_quit_code, quit_code_io
        DEFINE_READ_PARAMS read_params, quit_code_addr, quit_code_size
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_QUIT_PARAMS quit_params

str_quit_code:
        PASCAL_STRING kFilenameQuitSave

ResetHandler:
        ;; Restore DeskTop Main expected state...
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

start:
        ;; Restore system state: devices, /RAM, ROM/ZP banks.
        jsr     RestoreSystem

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
CmdQuit := CmdQuitImpl::start
ResetHandler    := CmdQuitImpl::ResetHandler

;;; ============================================================
;;; Exit DHR, restore device list, reformat /RAM.
;;; Returns with ALTZPOFF and ROM banked in.

.proc RestoreSystem
        jsr     SaveWindows
        jsr     RestoreDeviceList

        ;; Switch back to main ZP, preserving return address.
        pla
        tax
        pla
        sta     ALTZPOFF
        pha
        txa
        pha

        ;; Switch back to color DHR mode
        jsr     SetColorMode

        ;; Exit graphics mode entirely
        bit     ROMIN2

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
        sta     CLR80COL

        ;; Restore /RAM if possible.
        jmp     MaybeReformatRam
.endproc

;;; ============================================================

.proc CmdViewByIcon
        lda     active_window_id
        bne     :+
        rts

:       jsr     GetActiveWindowViewBy
        bne     :+              ; not by icon
        rts

        ;; View by icon
entry:
:       jsr     LoadActiveWindowEntryTable ; restored below

        ldx     #$00
        txa
:       cpx     cached_window_entry_count
        beq     :+
        sta     cached_window_entry_list,x
        inx
        jmp     :-
:       sta     cached_window_entry_count

        lda     #0
        ldx     active_window_id
        dex
        sta     win_view_by_table,x
        jsr     UpdateViewMenuCheck

        lda     active_window_id
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        jsr     ClearWindowBackgroundIfNotObscured

        lda     active_window_id
        jsr     ComputeWindowDimensions
        stax    win_width
        sty     win_height

        ptr = $06

        lda     active_window_id
        jsr     WindowLookup
        stax    ptr

        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Point) - 1
        lda     #0
:       sta     (ptr),y
        dey
        cpy     #MGTK::Winfo::port + MGTK::GrafPort::maprect - 1
        bne     :-

        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     win_width,x
        sta     (ptr),y
        dey
        dex
        bpl     :-

        lda     active_window_id
        jsr     CreateIconsAndPreserveWindowSize

        lda     active_window_id
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        sta     err

        jsr     CachedIconsScreenToWindow
        copy    #0, index
        index := *+1
:       lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     :+
        tax
        lda     cached_window_entry_list,x
        sta     icon_param
        jsr     IconEntryLookup
        stax    @addr
        ITK_RELAY_CALL IconTK::AddIcon, 0, @addr
        err := *+1
        lda     #SELF_MODIFIED_BYTE
    IF_ZERO                     ; Skip drawing if obscured
        ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED
    END_IF
        inc     index
        jmp     :-

:       jsr     ResetMainGrafport
        jsr     CachedIconsWindowToScreen
        jsr     StoreWindowEntryTable

        jsr     CachedIconsScreenToWindow
        jsr     UpdateScrollbars
        jsr     CachedIconsWindowToScreen

finish: jmp     LoadDesktopEntryTable ; restore from above

win_width:
        .word   0
win_height:
        .word   0
.endproc

;;; ============================================================

.proc ViewByNoniconCommon
        sta     view

        ;; Valid?
        lda     active_window_id
        beq     ret

        ;; Is this a change?
        jsr     GetActiveWindowViewBy
        view := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     ret

        ;; Destroy existing icons
        cmp     #kViewByIcon
        bne     :+
        jsr     DestroyIconsInActiveWindow
:
        ;; Update view menu/table
        jsr     UpdateViewMenuCheck
        lda     view
        ldx     active_window_id
        dex
        sta     win_view_by_table,x

        ;; Clear selection if in the window
        lda     selected_window_id
        cmp     active_window_id
        bne     sort
        lda     #0
        sta     selected_icon_count
        sta     selected_window_id

        ;; Sort the records
sort:   jsr     LoadActiveWindowEntryTable ; restored below
        jsr     SortRecords
        jsr     StoreWindowEntryTable

        ;; Draw the records
        lda     active_window_id
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        jsr     ClearWindowBackgroundIfNotObscured
        jsr     ResetMainGrafport

        copy    #$40, header_and_offset_flag
        jsr     DrawWindowEntries
        copy    #0, header_and_offset_flag

        jsr     UpdateScrollbars

done:   jsr     LoadDesktopEntryTable ; restored from above
ret:    rts
.endproc

;;; ============================================================

.proc CmdViewByName
        lda     #kViewByName
        jmp     ViewByNoniconCommon
.endproc

;;; ============================================================

.proc CmdViewByDate
        lda     #kViewByDate
        jmp     ViewByNoniconCommon
.endproc

;;; ============================================================

.proc CmdViewBySize
        lda     #kViewBySize
        jmp     ViewByNoniconCommon
.endproc

;;; ============================================================

.proc CmdViewByType
        lda     #kViewByType
        jmp     ViewByNoniconCommon
.endproc

;;; ============================================================

.proc UpdateViewMenuCheck
        ;; Uncheck last checked
        copy    #MGTK::checkitem_uncheck, checkitem_params::check
        jsr     CheckItem

        ;; Check the new one
        copy    menu_click_params::item_num, checkitem_params::menu_item
        copy    #MGTK::checkitem_check, checkitem_params::check
        jsr     CheckItem
        rts
.endproc

;;; ============================================================
;;; Destroy all of the icons in the active window.
;;; Assert: DesktopEntryTable is cached (and this is restored)

.proc DestroyIconsInActiveWindow
        ITK_RELAY_CALL IconTK::CloseWindow, active_window_id
        jsr     LoadActiveWindowEntryTable ; restored below
        lda     icon_count
        sec
        sbc     cached_window_entry_count
        sta     icon_count

        jsr     FreeCachedWindowIcons

done:   jsr     StoreWindowEntryTable
        jmp     LoadDesktopEntryTable ; restore from above
.endproc

;;; ============================================================

.proc FreeCachedWindowIcons
        copy    #0, index

        index := *+1
loop:   ldx     #SELF_MODIFIED_BYTE
        cpx     cached_window_entry_count
        beq     done

        lda     cached_window_entry_list,x
        pha
        jsr     FreeIcon
        pla

        jsr     FindWindowIndexForDirIcon ; X = window id-1 if found
    IF_EQ
        copy    #$FF, window_to_dir_icon_table,x ; $FF = dir icon freed
    END_IF

        ldx     index
        copy    #0, cached_window_entry_list,x

        inc     index
        bne     loop

done:   rts
.endproc

;;; ============================================================
;;; Clear active window entry count
;;; Assert: DesktopEntryTable is cached (and this is restored)

.proc ClearActiveWindowEntryCount
        jsr     LoadActiveWindowEntryTable ; restored below

        copy    #0, cached_window_entry_count

        jsr     StoreWindowEntryTable
        jmp     LoadDesktopEntryTable ; restore from above
.endproc

;;; ============================================================

;;; Set after format, erase, failed open, etc.
;;; Used by 'cmd_check_single_drive_by_XXX'; may be unit number
;;; or device index depending on call site.
drive_to_refresh:
        .byte   0

;;; ============================================================

.proc CmdFormatDisk
        lda     #kDynamicRoutineFormatErase
        jsr     LoadDynamicRoutine
        bpl     :+
        rts
:
        lda     #4
        jsr     format_erase_overlay__Exec
        stx     drive_to_refresh ; X = unit number
        pha                     ; A = result
        jsr     ClearUpdates ; following dialog close
        pla                     ; A = result
        beq     :+
        rts
:
        jmp     CmdCheckSingleDriveByUnitNumber
.endproc

;;; ============================================================

.proc CmdEraseDisk
        lda     #kDynamicRoutineFormatErase
        jsr     LoadDynamicRoutine
        bpl     :+
        rts
:
        lda     #5
        jsr     format_erase_overlay__Exec
        stx     drive_to_refresh ; X = unit number
        pha                     ; A = result
        jsr     ClearUpdates ; following dialog close
        pla                     ; A = result
        beq     :+
        rts
:
        jmp     CmdCheckSingleDriveByUnitNumber
.endproc

;;; ============================================================

;;; These commands don't need anything beyond the operation.

CmdGetInfo      := DoGetInfo
CmdGetSize      := DoGetSize
CmdUnlock       := DoUnlock
CmdLock         := DoLock

;;; ============================================================

.proc CmdDeleteSelection
        copy    trash_icon_num, drag_drop_params::icon
        jmp     process_drop
.endproc

;;; ============================================================

.proc CmdRename
        lda     selected_icon_count
        beq     ret

        jsr     DoRename
        sta     result

        bit     result
        bpl     :+              ; N = window renamed
        ;; TODO: Avoid repainting everything
        MGTK_RELAY_CALL MGTK::RedrawDeskTop
:
        bit     result
        bvc     ret             ; V = SYS file renamed
        lda     active_window_id
        ;; TODO: Optimize, e.g. rebuild from existing FileRecords ?
        jsr     SelectAndRefreshWindow

ret:    rts

result: .byte   0
.endproc

;;; ============================================================

.proc CmdDuplicate
        lda     selected_icon_count
        beq     ret

        jsr     DoDuplicate
        beq     ret             ; flag set if window needs refreshing

        ;; Update cached used/free for all same-volume windows
        param_call UpdateUsedFreeViaPath, path_buf3

        ;; Select/refresh window if there was one
        lda     active_window_id
        jne     SelectAndRefreshWindowOrClose

ret:    rts
.endproc

;;; ============================================================
;;; Handle keyboard-based icon selection ("highlighting")

.proc CmdHighlight

        ;; Tab / Shift+Tab - next/prev in sorted order

alpha:  jsr     ShiftDown
        sta     flag
        jsr     GetSelectableIconsSorted
        jmp     common

        ;; Arrows - next/prev in icon order

prev:   lda     #$80
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
next:   lda     #$00
        sta     flag

;;; First byte is icon count. Rest is a list of selectable icons.
        buffer := $1800
        jsr     GetSelectableIcons

;;; Figure out current selected index, based on selection.

common: lda     selected_icon_count
        beq     pick_first

        ;; Try to find actual selection in our list
        lda     selected_icon_list ; Only consider first, otherwise N^2
        ldx     buffer             ; count
        dex                        ; index
:       cmp     buffer+1,x
        beq     pick_next_prev
        dex
        bpl     :-


        ;; No selection; pick the first icon identified.
pick_first:
        copy    #0, selected_index
        jsr     ClearSelection
        jmp     HighlightIcon

        ;; There was a selection; clear it, and pick prev/next
        ;; based on keypress.
pick_next_prev:
        stx     selected_index
        jsr     ClearSelection

        flag := *+1
        lda     #SELF_MODIFIED_BYTE
        bmi     select_prev
        ;; fall through

select_next:
        selected_index := *+1
        ldx     #SELF_MODIFIED_BYTE
        inx
        cpx     buffer
        bne     :+
        ldx     #0
:       stx     selected_index
        jmp     HighlightIcon

select_prev:
        ldx     selected_index
        dex
        bpl     :+
        ldx     buffer
        dex
:       stx     selected_index
        ;; fall through

;;; Highlight the icon in the list at `selected_index`
HighlightIcon:
        ldx     selected_index
        lda     buffer+1,x
        jmp     SelectIcon
.endproc
CmdHighlightPrev := CmdHighlight::prev
CmdHighlightNext := CmdHighlight::next
CmdHighlightAlpha := CmdHighlight::alpha

;;; ============================================================
;;; Type Down Selection

.proc ClearTypeDown
        copy    #0, typedown_buf
        rts
.endproc

;;; Returns Z=1 if consumed, Z=0 otherwise.
.proc CheckTypeDown
        jsr     UpcaseChar
        cmp     #'A'
        bcc     :+
        cmp     #'Z'+1
        bcc     file_char

:       ldx     typedown_buf
        beq     not_file_char

        cmp     #'.'
        beq     file_char
        cmp     #'0'
        bcc     not_file_char
        cmp     #'9'+1
        bcc     file_char

not_file_char:
        return  #$FF            ; Z=0 to ignore

file_char:
        ldx     typedown_buf
        cpx     #15
        bne     :+
        rts                     ; Z=1 to consume
:
        inx
        stx     typedown_buf
        sta     typedown_buf,x

        ;; Collect and sort the potential type-down matches
        jsr     GetSelectableIconsSorted

        ;; Find a match. There will always be one, since
        ;; desktop icons (including Trash) are considered.
        jsr     FindMatch

        ;; Icon to select
        tax
        lda     table,x         ; index to icon
        sta     icon

        ;; Already the selection?
        lda     selected_icon_count
        cmp     #1
        bne     update
        lda     selected_icon_list
        cmp     icon
        beq     done            ; yes, nothing to do

        ;; Update the selection.
update: jsr     ClearSelection
        icon := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     SelectIcon

done:   lda     #0
ret:    rts

        num_filenames := $1800
        table := $1801
        ptr1 := $06
        ptr2 := $08

;;; Find the substring match for `typedown_buf`, or the next
;;; match in lexicographic order, or the last item in the table.
.proc FindMatch
        ptr     := $06

        copy    #0, index

        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        jsr     GetNthSelectableIconName
        stax    ptr

        ;; NOTE: Can't use `CompareStrings` as we want to match
        ;; on subset-or-equals.
        ldy     #0
        lda     (ptr),y
        sta     len

        ldy     #1
cloop:  lda     (ptr),y
        jsr     UpcaseChar
        cmp     typedown_buf,y
        bcc     next
        beq     :+
        bcs     found
:
        cpy     typedown_buf
        beq     found

        iny
        len := *+1
        cpy     #SELF_MODIFIED_BYTE
        bcc     cloop
        beq     cloop

next:   inc     index
        lda     index
        cmp     num_filenames
        bne     loop
        dec     index
found:  return  index
.endproc

.endproc

;;; Length plus filename
typedown_buf:
        .res    16, 0

;;; ============================================================
;;; Build list of selectable icons.
;;; Includes icons in the active window (if any, and if icon view)
;;; followed by the volume icons on the desktop, including Trash.
;;; Output: Buffer at $1800 (length prefixed)

.proc GetSelectableIcons
        buffer := $1800

        copy    #0, buffer
        lda     active_window_id
        beq     volumes         ; no active window

        jsr     GetActiveWindowViewBy
        bmi     volumes         ; not icon view

        ;; --------------------------------------------------
        ;; Icons in active window

        jsr     LoadActiveWindowEntryTable ; restored below

        ldx     #0              ; index in buffer and icon list
win_loop:
        cpx     cached_window_entry_count
        beq     :+

        lda     cached_window_entry_list,x
        sta     buffer+1,x
        inc     buffer
        inx
        jmp     win_loop
:
        jsr     LoadDesktopEntryTable ; restore from above

        ;; --------------------------------------------------
        ;; Desktop (volume) icons

volumes:
        ldx     buffer
        ldy     #0
vol_loop:
        lda     cached_window_entry_list,y
        sta     buffer+1,x
        iny
        inx
        cpy     cached_window_entry_count
        bne     vol_loop
        lda     buffer
        clc
        adc     cached_window_entry_count
        sta     buffer

        rts
.endproc

;;; Gather the selectable icons (in active window plus desktop) into
;;; buffer at $1800, as above, but also sort them by name.
;;; Output: Buffer at $1800 (length prefixed)

.proc GetSelectableIconsSorted
        buffer := $1800
        ptr1 := $06
        ptr2 := $08

        ;; Init table with unsorted list of icons (never empty)
        jsr     GetSelectableIcons

        ;; Selection sort. In each outer iteration, the highest
        ;; remaining element is moved to the end of the unsorted
        ;; region, and the region is reduced by one. O(n^2)
        ldx     buffer          ; count
        dex
        stx     outer

        outer := *+1
oloop:  lda     #SELF_MODIFIED_BYTE
        jsr     GetNthSelectableIconName
        stax    ptr2

        lda     #0
        sta     inner

        inner := *+1
iloop:  lda     #SELF_MODIFIED_BYTE
        jsr     GetNthSelectableIconName
        stax    ptr1

        jsr     CompareStrings
        bcc     next

        ;; Swap
        ldx     inner
        ldy     outer
        lda     buffer+1,x
        pha
        lda     buffer+1,y
        sta     buffer+1,x
        pla
        sta     buffer+1,y
        tya
        jsr     GetNthSelectableIconName
        stax    ptr2

next:   inc     inner
        lda     inner
        cmp     outer
        bne     iloop

        dec     outer
        bne     oloop

ret:    rts

;;; Compare strings at $06 (1) and $08 (2).
;;; Returns C=0 for 1<2 , C=1 for 1>=2, Z=1 for 1=2
.proc CompareStrings
        ldy     #0
        copy    (ptr1),y, len1
        copy    (ptr2),y, len2
        iny

loop:   lda     (ptr2),y
        jsr     UpcaseChar
        sta     char
        lda     (ptr1),y
        jsr     UpcaseChar
        char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     ret             ; differ at Yth character

        ;; End of string 1?
        len1 := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     :+
        cpy     len2            ; 1<2 or 1=2 ?
        rts

        ;; End of string 2?
        len2 := *+1
:       cpy     SELF_MODIFIED_BYTE
        beq     gt              ; 1>2
        iny
        bne     loop            ; always

gt:     lda     #$FF            ; Z=0
        sec
ret:    rts
.endproc

.endproc

;;; Assuming selectable icon buffer at $1800 is populated by the
;;; above functions, return ptr to nth icon's name in A,X
;;; Input: A = index
;;; Output: A,X = icon name pointer
.proc GetNthSelectableIconName
        buffer := $1800

        tax
        lda     buffer+1,x         ; A = icon num
        asl     a
        tay
        lda     icon_entry_address_table,y
        clc
        adc     #IconEntry::name
        pha
        lda     icon_entry_address_table+1,y
        adc     #0
        tax
        pla
        rts
.endproc


;;; ============================================================
;;; Select an arbitrary icon. If windowed, it is scrolled into view.
;;; Inputs: A = icon id
;;; Assert: Selection is empty. If windowed, it's in the active window.

.proc SelectIcon
        sta     icon_param
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param

        ;; Find icon's window, and set selection
        icon_ptr := $06
        lda     icon_param
        jsr     IconEntryLookup
        stax    icon_ptr
        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask

        sta     selected_window_id
        copy    #1, selected_icon_count
        copy    icon_param, selected_icon_list

        ;; If windowed, ensure it is visible
        lda     selected_window_id
        beq     :+
        jsr     LoadActiveWindowEntryTable ; restored below
        lda     selected_icon_list
        jsr     ScrollIconIntoView
        jsr     LoadDesktopEntryTable ; restore from above
:

        lda     selected_icon_list
        jsr     DrawIcon

        rts
.endproc

;;; ============================================================

.proc CmdSelectAll
        lda     selected_icon_count
        beq     :+
        jsr     ClearSelection

:       lda     active_window_id
        beq     :+              ; desktop is okay
        jsr     GetActiveWindowViewBy
        bpl     :+              ; view by icons
        rts

:       jsr     LoadActiveWindowEntryTable ; restored below
        lda     cached_window_entry_count
        jeq     finish          ; nothing to select!

        ldx     cached_window_entry_count
        dex
:       copy    cached_window_entry_list,x, selected_icon_list,x
        dex
        bpl     :-

        copy    cached_window_entry_count, selected_icon_count
        copy    active_window_id, selected_window_id
        lda     selected_window_id
        beq     :+
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        sta     err

:       lda     selected_icon_count
        sta     index
        dec     index
        index := *+1
loop:   ldx     #SELF_MODIFIED_BYTE
        copy    selected_icon_list,x, icon_param
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param

        err := *+1
        lda     #SELF_MODIFIED_BYTE
    IF_ZERO                     ; Skip drawing if obscured
        ;; TODO: Find common pattern for redrawing multiple icons
        lda     selected_window_id
        beq     :+
        lda     icon_param
        jsr     IconScreenToWindow
:       ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED
        lda     selected_window_id
        beq     :+
        lda     icon_param
        jsr     IconWindowToScreen
:
    END_IF

        dec     index
        bpl     loop

        lda     selected_window_id
        beq     finish
        jsr     ResetMainGrafport
finish: jmp     LoadDesktopEntryTable ; restore from above
.endproc


;;; ============================================================
;;; Initiate keyboard-based resizing

.proc CmdResize
        MGTK_RELAY_CALL MGTK::KeyboardMouse
        jmp     HandleResizeClick
.endproc

;;; ============================================================
;;; Initiate keyboard-based window moving

.proc CmdMove
        MGTK_RELAY_CALL MGTK::KeyboardMouse
        jmp     HandleTitleClick
.endproc

;;; ============================================================
;;; Cycle Through Windows
;;; Input: A = Key used; '~' is reversed


.proc CmdCycleWindows
        tay

        ;; Need at least two windows to cycle.
        lda     num_open_windows
        cmp     #2
        bcc     done

        cpy     #'~'
        beq     reverse

        jsr     ShiftDown
        bmi     reverse

        ;; TODO: Using this table as the source is a little odd.
        ;; Ideally would be doing send-front-to-back/bring-back-to-front
        ;; but maintaining order would be tricky.

        ;; --------------------------------------------------
        ;; Search upwards through window-icon map to find next.
        ;; ID is 1-based, table is 0-based, so don't need to start
        ;; with an increment
        ldx     active_window_id
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
        ldx     active_window_id
        dex
@loop:  dex
        bpl     :+
        ldx     #kMaxNumWindows-1
:       lda     window_to_dir_icon_table,x
        beq     @loop           ; 0 = window free
        ;;  fall through...

found:  inx
        stx     findwindow_params::window_id
        jmp     HandleInactiveWindowClick

done:   rts
.endproc

;;; ============================================================
;;; Keyboard-based scrolling of window contents

.proc CmdScroll
        jsr     GetActiveWindowScrollInfo
loop:   jsr     GetEvent
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     done
        cmp     #MGTK::EventKind::key_down
        bne     loop
        lda     event_params::key
        cmp     #CHAR_RETURN
        beq     done
        cmp     #CHAR_ESCAPE
        bne     :+

done:   jmp     LoadDesktopEntryTable ; restore from `GetActiveWindowScrollInfo`

        ;; Horizontal ok?
:       bit     horiz_scroll_flag
        jpl     vertical

        cmp     #CHAR_RIGHT
        bne     :+
        jsr     ScrollRight
        jmp     loop

:       cmp     #CHAR_LEFT
        bne     vertical
        jsr     ScrollLeft
        jmp     loop

        ;; Vertical ok?
vertical:
        bit     vert_scroll_flag
        jpl     loop

        cmp     #CHAR_DOWN
        bne     :+
        jsr     ScrollDown
        jmp     loop

:       cmp     #CHAR_UP
        bne     loop
        jsr     ScrollUp
        jmp     loop
.endproc

;;; ============================================================

.proc GetActiveWindowScrollInfo
        jsr     LoadActiveWindowEntryTable ; restored in `CmdScroll` and `HandleClientClick`
        jsr     GetActiveWindowViewBy
        sta     active_window_view_by
        jsr     GetActiveWindowHScrollInfo
        sta     horiz_scroll_pos
        stx     horiz_scroll_max
        sty     horiz_scroll_flag
        jsr     GetActiveWindowVScrollInfo
        sta     vert_scroll_pos
        stx     vert_scroll_max
        sty     vert_scroll_flag
        rts
.endproc

;;; ============================================================

ScrollRight:                   ; elevator right / contents left
        lda     horiz_scroll_pos
        ldx     horiz_scroll_max
        jsr     DoScrollRight
        sta     horiz_scroll_pos
        rts

ScrollLeft:                    ; elevator left / contents right
        lda     horiz_scroll_pos
        jsr     DoScrollLeft
        sta     horiz_scroll_pos
        rts

ScrollDown:                    ; elevator down / contents up
        lda     vert_scroll_pos
        ldx     vert_scroll_max
        jsr     DoScrollDown
        sta     vert_scroll_pos
        rts

ScrollUp:                      ; elevator up / contents down
        lda     vert_scroll_pos
        jsr     DoScrollUp
        sta     vert_scroll_pos
        rts

horiz_scroll_flag:      .byte   0 ; can scroll horiz?
vert_scroll_flag:       .byte   0 ; can scroll vert?
horiz_scroll_pos:       .byte   0
horiz_scroll_max:       .byte   0
vert_scroll_pos:        .byte   0
vert_scroll_max:        .byte   0

.proc DoScrollRight
        stx     max
        max := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     :+
        sta     updatethumb_params::stash
        inc     updatethumb_params::stash
        copy    #MGTK::Ctl::horizontal_scroll_bar, updatethumb_params::which_ctl
        jsr     UpdateScrollThumb
        lda     updatethumb_params::stash
:       rts
.endproc

.proc DoScrollLeft
        beq     :+
        sta     updatethumb_params::stash
        dec     updatethumb_params::stash
        copy    #MGTK::Ctl::horizontal_scroll_bar, updatethumb_params::which_ctl
        jsr     UpdateScrollThumb
        lda     updatethumb_params::stash
:       rts
.endproc

.proc DoScrollDown
        stx     max
        max := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     :+
        sta     updatethumb_params::stash
        inc     updatethumb_params::stash
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        jsr     UpdateScrollThumb
        lda     updatethumb_params::stash
:       rts
.endproc

.proc DoScrollUp
        beq     :+
        sta     updatethumb_params::stash
        dec     updatethumb_params::stash
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        jsr     UpdateScrollThumb
        lda     updatethumb_params::stash
:       rts
.endproc

;;; Output: A = hscroll pos, X = hscroll max, Y = hscroll active flag (high bit)
.proc GetActiveWindowHScrollInfo
        ptr := $06

        lda     active_window_id
        jsr     WindowLookup
        stax    ptr
        ldy     #MGTK::Winfo::hthumbmax
        lda     (ptr),y
        tax
        iny                     ; hthumbpos
        lda     (ptr),y
        pha
        ldy     #MGTK::Winfo::hscroll
        lda     (ptr),y
        and     #MGTK::Scroll::option_active ; low bit
        clc
        ror     a
        ror     a               ; shift to high bit
        tay
        pla
        rts
.endproc

;;; Output: A = vscroll pos, X = vscroll max, Y = vscroll active flag (high bit)
.proc GetActiveWindowVScrollInfo
        ptr := $06

        lda     active_window_id
        jsr     WindowLookup
        stax    ptr
        ldy     #MGTK::Winfo::vthumbmax
        lda     (ptr),y
        tax
        iny
        lda     (ptr),y
        pha
        ldy     #MGTK::Winfo::vscroll
        lda     (ptr),y
        and     #MGTK::Scroll::option_active ; low bit
        clc
        ror     a
        ror     a               ; shift to high bit
        tay
        pla
        rts
.endproc

;;; ============================================================

.proc CmdCheckDrives
        copy    #0, pending_alert
        jsr     LoadDesktopEntryTable ; TODO: Needed???
        jsr     CmdCloseAll
        jsr     ClearSelection
        jsr     ResetMainGrafport

        ;; --------------------------------------------------
        ;; Destroy existing volume icons
.scope
        ldx     cached_window_entry_count
        dex
loop:   lda     cached_window_entry_list,x
        cmp     trash_icon_num
        beq     next

        txa
        pha
        lda     cached_window_entry_list,x
        sta     icon_param
        copy    #0, cached_window_entry_list,x
        ITK_RELAY_CALL IconTK::EraseIcon, icon_param ; CHECKED (desktop)
        ITK_RELAY_CALL IconTK::RemoveIcon, icon_param
        lda     icon_param
        jsr     FreeDesktopIconPosition
        lda     icon_param
        jsr     FreeIcon
        dec     cached_window_entry_count
        dec     icon_count

        pla
        tax

next:   dex
        bpl     loop
.endscope

        ;; --------------------------------------------------
        ;; Create new volume icons
.scope
        ;; Enumerate DEVLST in reverse order (most important volumes first)
        ldy     DEVCNT
        sty     devlst_index
        devlst_index := *+1
@loop:  ldy     #SELF_MODIFIED_BYTE
        inc     cached_window_entry_count
        inc     icon_count
        lda     #0
        sta     device_to_icon_map,y
        lda     DEVLST,y
        jsr     CreateVolumeIcon ; A = unit num, Y = device index
        cmp     #ERR_DUPLICATE_VOLUME
        bne     :+
        lda     #kErrDuplicateVolName
        sta     pending_alert
:       dec     devlst_index
        bpl     @loop
.endscope

        ;; --------------------------------------------------
        ;; Add them to IconTK
.scope
        ldx     #0
loop:   cpx     cached_window_entry_count
        bne     cont

        ;; finish up
        lda     pending_alert
        beq     :+
        jsr     ShowAlert
:       jmp     StoreWindowEntryTable


cont:   txa
        pha
        lda     cached_window_entry_list,x
        cmp     trash_icon_num
        beq     next

        sta     icon_param
        jsr     IconEntryLookup
        stax    @addr
        ITK_RELAY_CALL IconTK::AddIcon, 0, @addr
        ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED (desktop)

next:   pla
        tax
        inx
        jmp     loop
.endscope

.endproc

;;; ============================================================

pending_alert:
        .byte   0

;;; ============================================================
;;; Check > [drive] command - obsolete, but core still used
;;; following Format (etc)
;;;

.proc CmdCheckSingleDriveImpl

        ;; index in DEVLST
        devlst_index  := menu_click_params::item_num

        ;; After open/eject/rename
by_icon_number:
        lda     #$C0            ; NOTE: This not safe to skip!
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction

        ;; Check Drive command
by_menu:
        lda     #$00
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction

        ;; After format/erase
by_unit_number:
        lda     #$80

        sta     check_drive_flags
        jsr     LoadDesktopEntryTable ; TODO: Needed???
        bit     check_drive_flags
        bpl     explicit_command
        bvc     after_format_erase

;;; --------------------------------------------------
;;; After an Open/Eject/Rename action

        ;; Map icon number to index in DEVLST
        lda     drive_to_refresh
        ldy     #kMaxVolumes
:       cmp     device_to_icon_map,y
        beq     :+
        dey
        bpl     :-
        rts                         ; Not found - not a volume icon

:       sty     devlst_index
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
:       sty     devlst_index
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
        jeq     not_in_map

        ;; Close any associated windows.

        ;; A = icon number
        jsr     IconEntryNameLookup

        ptr := $06
        path_buf := $1F00

        ;; Copy volume path to $1F00
        param_call CopyPtr1ToBuf, path_buf+1

        ;; Find all windows with path as prefix, and close them.
        sta     path_buf
        inc     path_buf
        copy    #'/', path_buf+1

        ldax    #path_buf
        ldy     path_buf
        jsr     FindWindowsForPrefix
        lda     found_windows_count
        beq     not_in_map

close_loop:
        ldx     found_windows_count
        beq     not_in_map
        dex
        lda     found_windows_list,x
        cmp     active_window_id
        beq     :+
        sta     findwindow_params::window_id
        jsr     HandleInactiveWindowClick

:       jsr     CloseWindow
        dec     found_windows_count
        jmp     close_loop

not_in_map:

        jsr     ClearSelection
        jsr     LoadDesktopEntryTable ; TODO: Needed???

        lda     devlst_index
        tay
        pha

        lda     device_to_icon_map,y
        sta     icon_param
        beq     :+

        jsr     RemoveIconFromWindow
        dec     icon_count
        lda     icon_param
        jsr     FreeIcon
        lda     icon_param
        jsr     FreeDesktopIconPosition
        jsr     ResetMainGrafport
        ITK_RELAY_CALL IconTK::EraseIcon, icon_param ; CHECKED (desktop)
        ITK_RELAY_CALL IconTK::RemoveIcon, icon_param

:       lda     cached_window_entry_count
        sta     previous_icon_count
        inc     cached_window_entry_count
        inc     icon_count

        pla
        tay
        lda     DEVLST,y
        ldx     icon_param      ; preserve icon index if known
        bne     :+
:       jsr     CreateVolumeIcon ; A = unit num, Y = device index

        cmp     #ERR_DUPLICATE_VOLUME
        beq     err

        bit     check_drive_flags
        bmi     add_icon

        ;; Explicit command
        and     #$FF            ; check `CreateVolumeIcon` results
        beq     add_icon

        ;; Expected errors per Technical Note: ProDOS #21
        ;; http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.21.html
        cmp     #ERR_IO_ERROR   ; disk damaged or blank
        beq     add_icon
        cmp     #ERR_DEVICE_OFFLINE ; no disk in the drive
        beq     add_icon

err:    pha
        jsr     StoreWindowEntryTable
        pla
        jsr     ShowAlert
        rts

add_icon:
        lda     cached_window_entry_count
        previous_icon_count := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     :+

        ;; If a new icon was added, more work is needed.
        ldx     cached_window_entry_count
        dex
        lda     cached_window_entry_list,x
        sta     icon_param
        jsr     IconEntryLookup
        stax    @addr
        ITK_RELAY_CALL IconTK::AddIcon, 0, @addr
        ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED (desktop)

:       jsr     StoreWindowEntryTable
        rts

;;; 0 = command, $80 = format/erase, $C0 = open/eject/rename
check_drive_flags:
        .byte   0

.endproc

        CmdCheckSingleDriveByMenu := CmdCheckSingleDriveImpl::by_menu
        CmdCheckSingleDriveByUnitNumber := CmdCheckSingleDriveImpl::by_unit_number
        CmdCheckSingleDriveByIconNumber := CmdCheckSingleDriveImpl::by_icon_number


;;; ============================================================

.proc CmdStartupItem
        ;; Determine the slot by looking at the menu item string.
        ldx     menu_click_params::item_num
        dex
        lda     startup_slot_table,x
        ora     #>$C000         ; compute $Cn00
        sta     reset_and_invoke_target+1
        lda     #<$C000
        sta     reset_and_invoke_target
        ;; fall through
.endproc

        ;; also invoked by launcher code
.proc ResetAndInvoke
        ;; Restore system state: devices, /RAM, ROM/ZP banks.
        jsr     RestoreSystem

        ;; also used by launcher code
        target := *+1
        jmp     SELF_MODIFIED
.endproc
        reset_and_invoke_target := ResetAndInvoke::target

;;; ============================================================

active_window_view_by:
        .byte   0

.proc HandleClientClick
        jsr     LoadActiveWindowEntryTable ; restored below or in `HandleContentClick`
        jsr     GetActiveWindowViewBy
        sta     active_window_view_by

        MGTK_RELAY_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        ;; TODO: jmp here means `done_client_click` not called, callee responsible
        jeq     HandleContentClick ; 0 = ctl_not_a_control

        cmp     #MGTK::Ctl::dead_zone
        bne     :+
        rts
:       cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     horiz

        ;; Vertical scrollbar
        lda     active_window_id
        jsr     WindowLookup
        stax    $06
        ldy     #MGTK::Winfo::vscroll
        lda     ($06),y
        and     #MGTK::Scroll::option_active
        jeq     done_client_click

        jsr     GetActiveWindowScrollInfo
        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::thumb
        bne     :+
        jsr     DoTrackThumb
        jmp     done_client_click

:       cmp     #MGTK::Part::up_arrow
        bne     :+
up:     jsr     ScrollUp
        lda     #MGTK::Part::up_arrow
        jsr     CheckControlRepeat
        bpl     up
        jmp     done_client_click

:       cmp     #MGTK::Part::down_arrow
        bne     :+
down:   jsr     ScrollDown
        lda     #MGTK::Part::down_arrow
        jsr     CheckControlRepeat
        bpl     down
        jmp     done_client_click

:       cmp     #MGTK::Part::page_down
        beq     pgdn
pgup:   jsr     ScrollPageUp
        lda     #MGTK::Part::page_up
        jsr     CheckControlRepeat
        bpl     pgup
        jmp     done_client_click

pgdn:   jsr     ScrollPageDown
        lda     #MGTK::Part::page_down
        jsr     CheckControlRepeat
        bpl     pgdn
        jmp     done_client_click

        ;; Horizontal scrollbar
horiz:  lda     active_window_id
        jsr     WindowLookup
        stax    $06
        ldy     #MGTK::Winfo::hscroll
        lda     ($06),y
        and     #MGTK::Scroll::option_active
        jeq     done_client_click

        jsr     GetActiveWindowScrollInfo
        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::thumb
        bne     :+
        jsr     DoTrackThumb
        jmp     done_client_click

:       cmp     #MGTK::Part::left_arrow
        bne     :+
left:   jsr     ScrollLeft
        lda     #MGTK::Part::left_arrow
        jsr     CheckControlRepeat
        bpl     left
        jmp     done_client_click

:       cmp     #MGTK::Part::right_arrow
        bne     :+
rght:   jsr     ScrollRight
        lda     #MGTK::Part::right_arrow
        jsr     CheckControlRepeat
        bpl     rght
        jmp     done_client_click

:       cmp     #MGTK::Part::page_right
        beq     pgrt
pglt:   jsr     ScrollPageLeft
        lda     #MGTK::Part::page_left
        jsr     CheckControlRepeat
        bpl     pglt
        jmp     done_client_click

pgrt:   jsr     ScrollPageRight
        lda     #MGTK::Part::page_right
        jsr     CheckControlRepeat
        bpl     pgrt
        jmp     done_client_click

done_client_click:
        jsr     StoreWindowEntryTable
        jmp     LoadDesktopEntryTable ; restore from above
.endproc

;;; ============================================================

.proc DoTrackThumb
        lda     findcontrol_params::which_ctl
        sta     trackthumb_params::which_ctl
        MGTK_RELAY_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        bne     :+
        rts
:       jmp     UpdateScrollThumb
.endproc

;;; ============================================================
;;; Called when the scroll thumb has been moved by the user.

.proc UpdateScrollThumb
        copy    updatethumb_params::stash, updatethumb_params::thumbpos
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     ApplyActiveWinfoToWindowGrafport

        bit     active_window_view_by
        bmi     :+              ; list view, no icons
        jsr     CachedIconsScreenToWindow
:

        jsr     UpdateCliprectAfterScroll
        jsr     UpdateScrollbarsLeaveThumbs

        bit     active_window_view_by
        bmi     :+              ; list view, no icons
        jsr     CachedIconsWindowToScreen
:

        ;; Clear content background, not header
        lda     active_window_id
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        jsr     ClearWindowBackgroundIfNotObscured
        jsr     ResetMainGrafport

        ;; Only draw content, not header
        copy    #$40, header_and_offset_flag
        jsr     DrawWindowEntries
        copy    #0, header_and_offset_flag
        rts
.endproc

;;; ============================================================
;;; Handle mouse held down on scroll arrow/pager

.proc CheckControlRepeat
        sta     ctl
        jsr     PeekEvent
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag
        beq     :+
bail:   return  #$FF            ; high bit set = not repeating

:       MGTK_RELAY_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        beq     bail
        cmp     #MGTK::Ctl::dead_zone
        beq     bail
        lda     findcontrol_params::which_part
        ctl := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     bail
        return  #0              ; high bit set = repeating
.endproc

;;; ============================================================

.proc HandleContentClick
        ;; Ignore clicks in the header area
        copy    active_window_id, screentowindow_params::window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     screentowindow_params::windowy
        cmp     #kWindowHeaderHeight + 1
        bcs     :+
        rts
:

        bit     active_window_view_by
        jmi     ClearSelection

        copy    active_window_id, findicon_params::window_id
        ITK_RELAY_CALL IconTK::FindIcon, findicon_params
        lda     findicon_params::which_icon
        bne     HandleFileIconClick

        ;; Not an icon - maybe a drag?
        jsr     DragSelect
        jmp     done_content_click ; restore from `HandleClientClick`
.endproc

;;; ============================================================

.proc HandleFileIconClick
        sta     icon_num
        jsr     IsIconSelected
        bne     not_selected

        ;; --------------------------------------------------
        ;; Icon was already selected
        jsr     ExtendSelectionModifierDown
        bpl     :+

        ;; Modifier down - remove from selection
        icon_num := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     DeselectFileIcon ; deselect, nothing further
        jmp     done_content_click ; restore from `HandleClientClick`

        ;; Double click or drag?
:       jmp     check_double_click

        ;; --------------------------------------------------
        ;; Icon not already selected
not_selected:
        jsr     ExtendSelectionModifierDown
        bpl     replace_selection

        ;; Modifier down - add to selection
        lda     selected_window_id
        cmp     active_window_id ; same window?
        beq     :+               ; if so, retain selection
        jsr     ClearSelection
:       lda     icon_num
        jsr     SelectFileIcon ; select, nothing further
        jmp     done_content_click ; restore from `HandleClientClick`

replace_selection:
        jsr     ClearSelection
        lda     icon_num
        jsr     SelectFileIcon
        ;; fall through...

        ;; --------------------------------------------------
check_double_click:
        jsr     StashCoordsAndDetectDoubleClick
        bmi     :+
        jsr     done_content_click ; restore from `HandleClientClick`
        jmp     CmdOpenFromDoubleClick
:
        ;; --------------------------------------------------
        ;; Drag of file icon
        copy    icon_num, drag_drop_params::icon
        ITK_RELAY_CALL IconTK::DragHighlighted, drag_drop_params
        tax
        lda     drag_drop_params::result
        beq     same_or_desktop

process_drop:
        jsr     DoDrop

        ;; (1/4) Canceled?
        cmp     #kOperationCanceled
        ;; TODO: Refresh source/dest if partial success
        jeq     done_content_click ; restore from `HandleClientClick`

        ;; Was a move?
        bit     move_flag
    IF_NS
        ;; Update source vol's contents
        jsr     MaybeStashDropTargetName ; in case target is in window...
        jsr     UpdateActiveWindow
        jsr     MaybeUpdateDropTargetFromName ; ...restore after update.
    END_IF

        ;; (2/4) Dropped on trash?
        lda     drag_drop_params::result
        cmp     trash_icon_num
        ;; Update used/free for same-vol windows
    IF_EQ
        copy    #$80, validate_windows_flag
        bne     UpdateActiveWindow ; always
    END_IF

        ;; (3/4) Dropped on icon?
        lda     drag_drop_params::result
    IF_POS
        ;; Yes, on an icon; update used/free for same-vol windows
        pha
        jsr     UpdateUsedFreeViaIcon
        pla
        jsr     FindWindowIndexForDirIcon ; X = window id-1 if found
      IF_EQ
        inx
        txa
        jmp     SelectAndRefreshWindowOrClose
      END_IF
        rts
    END_IF

        ;; (4/4) Dropped on window!
        and     #$7F            ; mask off window number
        pha
        jsr     UpdateUsedFreeViaWindow
        pla
        jmp     SelectAndRefreshWindowOrClose

        ;; --------------------------------------------------

same_or_desktop:
        cpx     #2              ; file icon dragged to desktop?
        jeq     done_content_click ; restore from `HandleClientClick`

        cpx     #$FF
        beq     failure

        ;; Icons moved within window - update and redraw
        lda     active_window_id
        jsr     SafeSetPortFromWindowId ; ASSERT: not obscured

        jsr     CachedIconsScreenToWindow
        ;; Adjust grafport for header.
        jsr     OffsetWindowGrafportAndSet

        ldx     selected_icon_count
        dex
:       txa
        pha
        lda     selected_icon_list,x
        sta     icon_param
        ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED (drag)
        pla
        tax
        dex
        bpl     :-

        jsr     UpdateScrollbars
        jsr     CachedIconsWindowToScreen
        jsr     ResetMainGrafport
        ;; fall through

;;; Used as additional entry point
done_content_click:     ; TODO: Obscures correct usage; remove?
        jsr     StoreWindowEntryTable
        jmp     LoadDesktopEntryTable

failure:
        ldx     saved_stack
        txs
        rts

        ;; --------------------------------------------------

.proc UpdateActiveWindow
        lda     active_window_id
        jsr     UpdateUsedFreeViaWindow
        lda     active_window_id
        jmp     SelectAndRefreshWindowOrClose
.endproc

.endproc
        done_content_click := HandleFileIconClick::done_content_click
        ;; Used for delete shortcut; set `drag_drop_params::icon` first
        process_drop := HandleFileIconClick::process_drop

;;; ============================================================
;;; Add specified icon to selection list, and redraw.
;;; Input: A = icon number
;;; Assert: Icon is in active window.

.proc SelectFileIcon
        sta     icon_param
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param

        ldx     selected_icon_count
        copy    icon_param, selected_icon_list,x
        inc     selected_icon_count
        copy    active_window_id, selected_window_id

        lda     icon_param
        jsr     DrawIcon
        rts
.endproc

;;; ============================================================
;;; Remove specified icon from selection list, and redraw.
;;; Input: A = icon number
;;; Assert: Must be in selection list and active window.

.proc DeselectFileIcon
        sta     icon_param
        ITK_RELAY_CALL IconTK::UnhighlightIcon, icon_param

        lda     icon_param
        jsr     RemoveFromSelectionList

        lda     icon_param
        jsr     DrawIcon
        rts
.endproc

;;; ============================================================
;;; Remove specified icon from `selected_icon_list`
;;; Inputs: A = icon_num
;;; Assert: icon is present in the list.

.proc RemoveFromSelectionList
        ;; Find index in list
        ldx     selected_icon_count
:       dex
        cmp     selected_icon_list,x
        bne     :-

        ;; Move everything down
:       lda     selected_icon_list+1,x
        sta     selected_icon_list,x
        inx
        cpx     selected_icon_count
        bne     :-

        dec     selected_icon_count
        rts
.endproc

;;; ============================================================

;;; Calls `SelectAndRefreshWindow` - on failure (e.g. too
;;; many files) the window is closed.
;;; Input: A = window id
;;; Output: A=0/Z=1/N=0 on success, A=$FF/Z=0/N=1 on failure

.proc SelectAndRefreshWindowOrClose
        pha
        jsr     TrySelectAndRefreshWindow
        pla

        bit     exception_flag
        bmi     :+
        return  #0

:       inc     num_open_windows ; was decremented on failure
        sta     active_window_id ; expected by CloseWindow
        jsr     CloseWindow
        return  #$FF

.proc TrySelectAndRefreshWindow
        ldx     #$80
        stx     exception_flag
        tsx
        stx     saved_stack
        jsr     SelectAndRefreshWindow
        ldx     #0
        stx     exception_flag
        rts
.endproc

exception_flag:
        .byte   0
.endproc

;;; ============================================================

.proc SelectAndRefreshWindow
        pha                     ; A = window_id

        ;; Clear selection
        jsr     ClearSelection

        ;; Bring window to front if needed
        pla                     ; A = window_id
        cmp     active_window_id
        beq     :+
        sta     findwindow_params::window_id
        jsr     HandleInactiveWindowClick ; bring to front
:
        ;; Clear background
        lda     active_window_id
        jsr     UnsafeSetPortFromWindowId ; CHECKED
        jsr     ClearWindowBackgroundIfNotObscured

        ;; Remove old FileRecords
        lda     active_window_id
        pha
        jsr     RemoveWindowFilerecordEntries

        ;; Remove old icons
        jsr     GetActiveWindowViewBy
        bmi     :+              ; list view, not icons
        jsr     DestroyIconsInActiveWindow
        jsr     ClearActiveWindowEntryCount

        ;; Copy window path to `open_dir_path_buf`
:       lda     active_window_id
        jsr     GetWindowPath
        .assert src_path_buf = open_dir_path_buf, error, "Buffer alias"
        jsr     CopyToSrcPath

        ;; Load new FileRecords
        pla                     ; window id
        jsr     OpenDirectory

        ;; Create icons and draw contents
        jsr     CmdViewByIcon::entry
        jsr     StoreWindowEntryTable ; TODO: above leaves Desktop; remove?

        ;; Draw header
        lda     active_window_id
        jsr     UnsafeSetPortFromWindowId ; CHECKED
    IF_ZERO                     ; Skip drawing if obscured
        jsr     LoadActiveWindowEntryTable ; restored below
        jsr     DrawWindowHeader
        jsr     LoadDesktopEntryTable ; restore from above
    END_IF

        ;; Set view state and update menu
        lda     #0
        ldx     active_window_id
        sta     win_view_by_table-1,x

        copy    #1, menu_click_params::item_num
        jsr     UpdateViewMenuCheck

        rts
.endproc

;;; ============================================================
;;; Clear the window background, following a call to either
;;; `UnsafeSetPortFromWindowId` or `UnsafeOffsetAndSetPortFromWindowId`

.proc ClearWindowBackgroundIfNotObscured
    IF_ZERO                     ; Skip drawing if obscured
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, window_grafport::cliprect
    END_IF
        rts
.endproc

;;; ============================================================
;;; Drag Selection - initiated in a window

.proc DragSelect
        ;; Set up $06 to point at an imaginary `IconEntry`, to map
        ;; `event_params::coords` from screen to window.
        copy16  #(event_params::coords - IconEntry::iconx), $06
        ;; Map initial event coordinates
        jsr     CoordsScreenToWindow

        ;; Stash initial coords
        ldx     #.sizeof(MGTK::Point)-1
:       lda     event_params::coords,x
        sta     tmp_rect::topleft,x
        sta     tmp_rect::bottomright,x
        dex
        bpl     :-

        ;; Is this actually a drag?
        jsr     PeekEvent
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag
        beq     l3                          ; yes

        ;; No, just a click; optionally clear selection
        jsr     ExtendSelectionModifierDown
        bmi     :+              ; don't clear if mis-clicking
        jsr     ClearSelection
:       rts

        ;; --------------------------------------------------
        ;; Prep selection
l3:     lda     selected_window_id ; different window, or desktop?
        cmp     active_window_id   ; if so, definitely clear selection
        bne     clear
        jsr     ExtendSelectionModifierDown
        bmi     :+
clear:  jsr     ClearSelection

        ;; --------------------------------------------------
        ;; Set up drawing port, draw initial rect
:       lda     active_window_id
        jsr     UnsafeOffsetAndSetPortFromWindowId ; ASSERT: not obscured

        jsr     FrameTmpRect

        ;; --------------------------------------------------
        ;; Event loop
event_loop:
        jsr     PeekEvent
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag
        beq     update

        ;; Process all icons in window
        jsr     FrameTmpRect
        ldx     #0
iloop:  cpx     cached_window_entry_count
        ;; Finished!
        jeq     ResetMainGrafport

        ;; Check if icon should be selected
        txa
        pha
        copy    cached_window_entry_list,x, icon_param
        jsr     IconScreenToWindow
        ITK_RELAY_CALL IconTK::IconInRect, icon_param
        beq     done_icon

        ;; Already selected?
        lda     icon_param
        jsr     IsIconSelected
    IF_NE
        ;; Highlight and add to selection
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param
        ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED (drag select)
        ldx     selected_icon_count
        inc     selected_icon_count
        copy    icon_param, selected_icon_list,x
        copy    active_window_id, selected_window_id
    ELSE
        ;; Unhighlight and remove from selection
        ITK_RELAY_CALL IconTK::UnhighlightIcon, icon_param
        ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED (drag select)
        lda     icon_param
        jsr     RemoveFromSelectionList
    END_IF

done_icon:
        lda     icon_param
        jsr     IconWindowToScreen
        pla
        tax
        inx
        jmp     iloop

        ;; --------------------------------------------------
        ;; Check movement threshold
update: jsr     CoordsScreenToWindow
        sub16   event_params::xcoord, last_pos+MGTK::Point::xcoord, deltax
        sub16   event_params::ycoord, last_pos+MGTK::Point::ycoord, deltay

        lda     deltax+1
        bpl     :+
        lda     deltax          ; negate
        eor     #$FF
        sta     deltax
        inc     deltax

:       lda     deltay+1
        bpl     :+
        lda     deltay          ; negate
        eor     #$FF
        sta     deltay
        inc     deltay

        ;; TODO: Experiment with making this lower.
        kDragBoundThreshold = 5

:       lda     deltax
        cmp     #kDragBoundThreshold
        bcs     :+
        lda     deltay
        cmp     #kDragBoundThreshold
        jcc     event_loop

        ;; Beyond threshold; erase rect
:       jsr     FrameTmpRect

        COPY_STRUCT MGTK::Point, event_params::coords, last_pos

        ;; --------------------------------------------------
        ;; Figure out coords for rect's left/top/bottom/right
        cmp16   event_params::xcoord, tmp_rect::x2
        bpl     l12
        cmp16   event_params::xcoord, tmp_rect::x1
        bmi     l11
        bit     x_flag
        bpl     l12
l11:    copy16  event_params::xcoord, tmp_rect::x1
        copy    #$80, x_flag
        jmp     do_y
l12:    copy16  event_params::xcoord, tmp_rect::x2
        copy    #0, x_flag

do_y:   cmp16   event_params::ycoord, tmp_rect::y2
        bpl     l15
        cmp16   event_params::ycoord, tmp_rect::y1
        bmi     l14
        bit     y_flag
        bpl     l15
l14:    copy16  event_params::ycoord, tmp_rect::y1
        copy    #$80, y_flag
        jmp     draw
l15:    copy16  event_params::ycoord, tmp_rect::y2
        copy    #0, y_flag

draw:   jsr     FrameTmpRect
        jmp     event_loop

deltax: .word   0
deltay: .word   0
last_pos:
        .tag    MGTK::Point
x_flag: .byte   0
y_flag: .byte   0

.proc CoordsScreenToWindow
        jsr     PushPointers
        jmp     IconPtrScreenToWindow
.endproc
.endproc

;;; ============================================================

.proc HandleTitleClick
        ptr := $06

        copy    active_window_id, event_params
        jsr     GetActiveWindowViewBy
        bmi     :+
        jsr     LoadActiveWindowEntryTable ; restored below
        jsr     CachedIconsScreenToWindow
:       MGTK_RELAY_CALL MGTK::DragWindow, event_params
        jsr     GetActiveWindowViewBy
        bmi     :+
        jsr     CachedIconsWindowToScreen
        jsr     StoreWindowEntryTable
        jsr     LoadDesktopEntryTable ; restore from above
:       rts

.endproc

;;; ============================================================

.proc HandleResizeClick
        copy    active_window_id, event_params
        MGTK_RELAY_CALL MGTK::GrowWindow, event_params
        jsr     LoadActiveWindowEntryTable ; restored below
        jsr     CachedIconsScreenToWindow
        jsr     UpdateScrollbars
        jsr     CachedIconsWindowToScreen
        jsr     LoadDesktopEntryTable ; restore from above
        jmp     ResetMainGrafport
.endproc

;;; ============================================================

.proc HandleCloseClick
        lda     active_window_id
        MGTK_RELAY_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        bne     :+
        rts

        ;; If modifier is down, close all windows
:       jsr     ModifierDown
        jmi     CmdCloseAll

        ;; fall through...
.endproc

.proc CloseWindow
        icon_ptr := $06

        jsr     LoadActiveWindowEntryTable ; restored below

        jsr     ClearSelection

        jsr     GetActiveWindowViewBy
        bmi     iter            ; list view, not icons

        lda     icon_count
        sec
        sbc     cached_window_entry_count
        sta     icon_count

        ITK_RELAY_CALL IconTK::CloseWindow, active_window_id

        jsr     FreeCachedWindowIcons

iter:   dec     num_open_windows
        ldx     #0
        txa
:       sta     cached_window_entry_list,x
        cpx     cached_window_entry_count
        beq     cont
        inx
        jmp     :-

cont:   sta     cached_window_entry_count
        jsr     StoreWindowEntryTable

        MGTK_RELAY_CALL MGTK::CloseWindow, active_window_id

        ;; --------------------------------------------------
        ;; Do we have a parent icon for this window?

        copy    #0, icon
        ldx     active_window_id
        dex
        lda     window_to_dir_icon_table,x
        bmi     :+              ; $FF = dir icon freed

        sta     icon

        ;; Animate closing into dir (vol/folder) icon
        ldx     active_window_id
        dex
        lda     window_to_dir_icon_table,x
        inx
        jsr     AnimateWindowClose ; A = icon id, X = window id
:
        ;; --------------------------------------------------
        ;; Tidy up after closing window

        lda     active_window_id
        jsr     RemoveWindowFilerecordEntries

        ldx     active_window_id
        dex
        lda     #0
        sta     window_to_dir_icon_table,x ; 0 = window free
        sta     win_view_by_table,x

        MGTK_RELAY_CALL MGTK::FrontWindow, active_window_id
        jsr     LoadDesktopEntryTable ; restore from above
        copy    #MGTK::checkitem_uncheck, checkitem_params::check
        jsr     CheckItem
        jsr     UpdateWindowMenuItems

        jsr     ClearUpdates ; following CloseWindow above

        ;; --------------------------------------------------
        ;; Clean up the parent icon (if any)

        icon := *+1
        lda     #SELF_MODIFIED_BYTE
        beq     finish          ; none

        sta     icon_param
        jsr     IconEntryLookup
        stax    icon_ptr

        ldy     #IconEntry::win_flags ; clear open state
        lda     (icon_ptr),y
        and     #AS_BYTE(~kIconEntryFlagsOpen)
        sta     (icon_ptr),y
        and     #kIconEntryWinIdMask ; which window?
        beq     :+              ; desktop, can draw/select
        cmp     active_window_id
        bne     finish          ; not top window, skip draw/select

        ;; Set selection and redraw

:       sta     selected_window_id
        copy    #1, selected_icon_count
        copy    icon, selected_icon_list
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param

        lda     icon_param
        jsr     DrawIcon

finish: rts
.endproc

;;; ============================================================
;;; Check windows and close any where the backing volume/file no
;;; longer exists.

;;; Set to $80 to run a validation pass and close as needed.
validate_windows_flag:
        .byte   0

.proc ValidateWindows
        pathbuf := INVOKER_PREFIX

        bit     validate_windows_flag
        bpl     done
        copy    #0, validate_windows_flag

        copy    #kMaxNumWindows, window_id

loop:
        ;; Check if the window is in use
        window_id := *+1
        ldx     #SELF_MODIFIED_BYTE
        lda     window_to_dir_icon_table-1,x
        beq     next

        ;; Get and copy its path somewhere useful
        txa
        jsr     GetWindowPath
        .assert src_path_buf = pathbuf, error, "Buffer alias"
        jsr     CopyToSrcPath

        ;; See if it exists
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params
        beq     next

        ;; Nope - close the window
        lda     window_id
        pha
        sta     findwindow_params::window_id
        jsr     HandleInactiveWindowClick
        pla
        jsr     CloseWindow

next:   dec     window_id
        bne     loop

done:   rts
.endproc

;;; ============================================================
;;; Scaling function for scroll calculations
;;;
;;; Used for both computing new thumb position given range/offset/max,
;;; and new offset given range/position/max.
;;;
;;; Inputs:
;;;   A = numerator 1 ---- e.g. scroll position (window edge - content edge)
;;;   X = denominator 1 -- e.g. scroll range (content size - window size)
;;;   Y = denominator 2 -- e.g. thumbmax
;;; Outputs:
;;;   A = numerator 2 ---- e.g. new thumbpos
;;;    where:
;;;      A(in):X = A(out):Y
;;;    or:
;;;      R = A * Y / X

.proc CalculateThumbPos
        cmp     #1
        bcc     :+
        bne     start
:       return  #0

start:  sta     aa
        stx     xx+1
        sty     yy+1
        cmp     xx+1            ; A >= X ?
        bcc     :+
        tya                     ; return Y
        rts

:       lda     #0
        sta     xx
        sta     yy
        lsr16   xx              ; xx /= 2
        lsr16   yy              ; yy /= 2

        lda     #0
        sta     mm
        sta     nn
        sta     mm+1
        sta     nn+1

        ;; while mm != aa
        ;;   if (mm > aa)
        ;;     sub
        ;;   else
        ;;     add
loop:   lda     mm+1
        cmp     aa
        beq     finish          ; if mm == aa, done
        bcc     :+              ; less?
        jsr     do_sub
        jmp     loop
:       jsr     do_add
        jmp     loop

        ;; return nn (minimum 1)
finish: lda     nn+1
        cmp     #1              ; why not bne ???
        bcs     :+
        lda     #1
:       rts

        ;; mm -= xx; nn -= yy; xx /= 2; yy /= 2
do_sub: sub16   mm, xx, mm
        sub16   nn, yy, nn
        lsr16   xx
        lsr16   yy
        rts

        ;; mm += xx; nn += yy; xx /= 2; yy /= 2
do_add: add16   mm, xx, mm
        add16   nn, yy, nn
        lsr16   xx
        lsr16   yy
        rts

        ;; 8.8 fixed point numbers
mm:     .word   0
xx:     .word   0               ; X.0
nn:     .word   0
yy:     .word   0               ; Y.0

        ;; except aa, which is just positive
aa:     .byte   0               ; A

.endproc

;;; ============================================================

.proc ScrollPageUp
        jsr     ComputeActiveWindowDimensions
        sty     height
        jsr     CalcHeightMinusHeader
        sta     useful_height

        sub16_8 window_grafport::cliprect::y1, useful_height, delta
        cmp16   delta, iconbb_rect+MGTK::Rect::y1
        bmi     clamp
        ldax    delta
        jmp     adjust

clamp:  ldax    iconbb_rect+MGTK::Rect::y1

adjust: stax    window_grafport::cliprect::y1
        add16_8 window_grafport::cliprect::y1, height, window_grafport::cliprect::y2
        jmp     FinishScrollAdjustAndRedraw

useful_height:
        .byte   0               ; without header
height: .byte   0               ; of window's port
delta:  .word   0
.endproc

;;; ============================================================

.proc ScrollPageDown
        jsr     ComputeActiveWindowDimensions
        sty     height
        jsr     CalcHeightMinusHeader
        sta     useful_height

        add16_8 window_grafport::cliprect::y2, useful_height, delta
        cmp16   delta, iconbb_rect+MGTK::Rect::y2
        bpl     clamp
        ldax    delta
        jmp     adjust

clamp:  ldax    iconbb_rect+MGTK::Rect::y2

adjust: stax    window_grafport::cliprect::y2
        sub16_8 window_grafport::cliprect::y2, height, window_grafport::cliprect::y1
        jmp     FinishScrollAdjustAndRedraw

useful_height:
        .byte   0               ; without header
height: .byte   0               ; of window's port
delta:  .word   0
.endproc

;;; ============================================================
;;; Input: Y = window height
;;; Output: A = Window height without items/used/free header

.proc CalcHeightMinusHeader
        tya
        sec
        sbc     #kWindowHeaderHeight
        rts
.endproc

;;; ============================================================

.proc ScrollPageLeft
        jsr     ComputeActiveWindowDimensions
        stax    width

        sub16   window_grafport::cliprect::x1, width, delta
        cmp16   delta, iconbb_rect+MGTK::Rect::x1
        bmi     clamp

        ldax    delta
        jmp     adjust

clamp:  ldax    iconbb_rect+MGTK::Rect::x1

adjust: stax    window_grafport::cliprect::x1
        add16   window_grafport::cliprect::x1, width, window_grafport::cliprect::x2
        jmp     FinishScrollAdjustAndRedraw

width:  .word   0               ; of window's port
delta:  .word   0
.endproc

;;; ============================================================

.proc ScrollPageRight
        jsr     ComputeActiveWindowDimensions
        stax    width

        add16   window_grafport::cliprect::x2, width, delta
        cmp16   delta, iconbb_rect+MGTK::Rect::x2
        bpl     clamp
        ldax    delta
        jmp     adjust

clamp:  ldax    iconbb_rect+MGTK::Rect::x2

adjust: stax    window_grafport::cliprect::x2
        sub16   window_grafport::cliprect::x2, width, window_grafport::cliprect::x1
        jmp     FinishScrollAdjustAndRedraw

width:  .word   0               ; of window's port
delta:  .word   0
.endproc

;;; ============================================================
;;; Computes dimensions of active window.
;;; If icon view, leaves icons mapped to window coords.
;;; Returns: Width in A,X, height in Y

.proc ComputeActiveWindowDimensions
        bit     active_window_view_by
        bmi     :+              ; list view, not icons
        jsr     CachedIconsScreenToWindow
:       jsr     ApplyActiveWinfoToWindowGrafport
        jsr     ComputeIconsBBox
        lda     active_window_id
        jmp     ComputeWindowDimensions
.endproc

;;; ============================================================

.proc ApplyActiveWinfoToWindowGrafport
        ptr := $06

        lda     active_window_id
        jsr     WindowLookup
        addax   #MGTK::Winfo::port, ptr
        ldy     #.sizeof(MGTK::GrafPort) - 1
:       lda     (ptr),y
        sta     window_grafport,y
        dey
        bpl     :-
        rts
.endproc

.proc AssignActiveWindowCliprect
        ptr := $6

        lda     active_window_id
        jsr     WindowLookup
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

.proc FinishScrollAdjustAndRedraw
        jsr     AssignActiveWindowCliprect
        jsr     UpdateScrollbars

        bit     active_window_view_by
        bmi     :+
        jsr     CachedIconsWindowToScreen
:

        ;; Clear content background, not header
        lda     active_window_id
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        jsr     ClearWindowBackgroundIfNotObscured
        jsr     ResetMainGrafport

        ;; Only draw content, not header
        copy    #$40, header_and_offset_flag
        jsr     DrawWindowEntries
        copy    #0, header_and_offset_flag
        rts
.endproc

;;; ============================================================
;;; Assert: scroll bar is active; content is wider than window.

.proc UpdateHThumb
        winfo_ptr := $06

        ;; Compute window size
        lda     active_window_id
        jsr     ComputeWindowDimensions
        stax    win_width

        ;; Look up thumbmax
        lda     active_window_id
        jsr     WindowLookup
        stax    winfo_ptr
        ldy     #MGTK::Winfo::hthumbmax
        lda     (winfo_ptr),y
        tay                     ; Y = thumbmax

        ;; Compute size delta (content vs. window)
        sub16   iconbb_rect+MGTK::Rect::x2, iconbb_rect+MGTK::Rect::x1, size
        sub16   size, win_width, size
        lsr16   size            ; / 2
        ldx     size            ; X = (content size - window size)/2

        ;; Compute offset
        sub16   window_grafport::cliprect::x1, iconbb_rect+MGTK::Rect::x1, size
        bpl     :+
        lda     #0              ; content near edge within window; clamp
        beq     calc            ; always

:       cmp16   window_grafport::cliprect::x2, iconbb_rect+MGTK::Rect::x2
        bmi     :+              ; content far edge within window? no
        tya                     ; yes; skip calculation
        jmp     skip

:       lsr16   size            ; / 2
        lda     size            ; A = (window left - content left) / 2

        ;; A:X = R:Y
        ;; A = scroll position / 2
        ;; X = scroll range / 2
        ;; Y = thumbmax
        ;; R = thumbpos
calc:   jsr     CalculateThumbPos

skip:   sta     updatethumb_params::thumbpos
        lda     #MGTK::Ctl::horizontal_scroll_bar
        sta     updatethumb_params::which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        rts

win_width:
        .word   0
size:   .word   0
.endproc

;;; ============================================================
;;; Assert: scroll bar is active; content is taller than window.

.proc UpdateVThumb
        winfo_ptr := $06

        ;; Compute window size
        lda     active_window_id
        jsr     ComputeWindowDimensions
        sty     win_height

        ;; Look up thumbmax
        lda     active_window_id
        jsr     WindowLookup
        stax    winfo_ptr
        ldy     #MGTK::Winfo::vthumbmax
        lda     (winfo_ptr),y
        tay                     ; Y = thumbmax

        ;; Compute size delta (content vs. window)
        sub16   iconbb_rect+MGTK::Rect::y2, iconbb_rect+MGTK::Rect::y1, size
        sub16_8 size, win_height, size
        lsr16   size            ; / 4
        lsr16   size
        ldx     size            ; X = (content size - window size)/4

        ;; Compute offset
        sub16   window_grafport::cliprect::y1, iconbb_rect+MGTK::Rect::y1, size
        bpl     :+
        lda     #0              ; content near edge within window; clamp
        beq     calc            ; always

:       cmp16   window_grafport::cliprect::y2, iconbb_rect+MGTK::Rect::y2
        bmi     neg             ; content far edge within window? no
        tya                     ; yes; skip calculation
        jmp     skip

neg:    lsr16   size            ; / 4
        lsr16   size
        lda     size            ; A = (window top - content top) / 4

        ;; A:X = R:Y
        ;; A = scroll position / 4
        ;; X = scroll range / 4
        ;; Y = thumbmax
        ;; R = thumbpos
calc:   jsr     CalculateThumbPos

skip:   sta     updatethumb_params::thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_params::which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        rts

win_height:
        .byte   0
size:   .word   0
.endproc

;;; ============================================================
;;; If a window is open, ensure the right view item is checked,.
;;; Otherwise, ensure the necessary menu items are disabled.
;;; (Called on window close)

.proc UpdateWindowMenuItems
        lda     active_window_id
        beq     DisableMenuItemsRequiringWindow

        ;; Check appropriate view menu item
        jsr     GetActiveWindowViewBy
        and     #kViewByMenuMask
        tax
        inx
        stx     checkitem_params::menu_item
        copy    #MGTK::checkitem_check, checkitem_params::check
        jsr     CheckItem
        rts
.endproc

;;; ============================================================

.proc ToggleMenuItemsRequiringWindow
enable:
        copy    #MGTK::disablemenu_enable, disablemenu_params::disable
        copy    #MGTK::disableitem_enable, disableitem_params::disable
        copy    #$80, window_open_flag
        jmp     :+

disable:
        copy    #MGTK::disablemenu_disable, disablemenu_params::disable
        copy    #MGTK::disableitem_disable, disableitem_params::disable
        copy    #0, window_open_flag

:       MGTK_RELAY_CALL MGTK::DisableMenu, disablemenu_params ; View menu

        copy    #kMenuIdFile, disableitem_params::menu_id
        lda     #aux::kMenuItemIdNewFolder
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdClose
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdCloseAll
        jsr     DisableMenuItem

        rts
.endproc
EnableMenuItemsRequiringWindow := ToggleMenuItemsRequiringWindow::enable
DisableMenuItemsRequiringWindow := ToggleMenuItemsRequiringWindow::disable


;;; ============================================================
;;; Disable menu items for operating on a selection

.proc ToggleMenuItemsRequiringSelection
enable:
        copy    #MGTK::disableitem_enable, disableitem_params::disable
        jmp     :+
disable:
        copy    #MGTK::disableitem_disable, disableitem_params::disable

        ;; File
:       copy    #kMenuIdFile, disableitem_params::menu_id
        lda     #aux::kMenuItemIdOpen
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdGetInfo
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdRenameIcon
        jsr     DisableMenuItem

        ;; Special
        copy    #kMenuIdSpecial, disableitem_params::menu_id
        lda     #aux::kMenuItemIdLock
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdUnlock
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdGetSize
        jsr     DisableMenuItem
        rts
.endproc
EnableMenuItemsRequiringSelection := ToggleMenuItemsRequiringSelection::enable
DisableMenuItemsRequiringSelection := ToggleMenuItemsRequiringSelection::disable

;;; ============================================================
;;; Calls DisableItem menu_item in A (to enable or disable).
;;; Set disableitem_params' disable flag and menu_id before calling.

.proc DisableMenuItem
        sta     disableitem_params::menu_item
        MGTK_RELAY_CALL MGTK::DisableItem, disableitem_params
        rts
.endproc

;;; ============================================================

.proc ToggleMenuItemsRequiringFileSelection
enable:
        copy    #MGTK::disableitem_enable, disableitem_params::disable
        jmp     :+

disable:
        copy    #MGTK::disableitem_disable, disableitem_params::disable

:       copy    #kMenuIdFile, disableitem_params::menu_id
        lda     #aux::kMenuItemIdDuplicate
        jsr     DisableMenuItem

        rts

.endproc
EnableMenuItemsRequiringFileSelection := ToggleMenuItemsRequiringFileSelection::enable
DisableMenuItemsRequiringFileSelection := ToggleMenuItemsRequiringFileSelection::disable

;;; ============================================================

.proc ToggleMenuItemsRequiringVolumeSelection
enable:
        copy    #MGTK::disableitem_enable, disableitem_params::disable
        jmp     :+

disable:
        copy    #MGTK::disableitem_disable, disableitem_params::disable

:       copy    #kMenuIdSpecial, disableitem_params::menu_id
        lda     #aux::kMenuItemIdEject
        jsr     DisableMenuItem

        copy    #kMenuIdSpecial, disableitem_params::menu_id
        lda     #aux::kMenuItemIdCheckDrive
        jsr     DisableMenuItem

        rts

.endproc
EnableMenuItemsRequiringVolumeSelection := ToggleMenuItemsRequiringVolumeSelection::enable
DisableMenuItemsRequiringVolumeSelection := ToggleMenuItemsRequiringVolumeSelection::disable

;;; ============================================================

.proc ToggleSelectorMenuItems
disable:
        copy    #MGTK::disableitem_disable, disableitem_params::disable
        jmp     :+

enable:
        copy    #MGTK::disableitem_enable, disableitem_params::disable

:       copy    #kMenuIdSelector, disableitem_params::menu_id
        lda     #kMenuItemIdSelectorEdit
        jsr     DisableMenuItem
        lda     #kMenuItemIdSelectorDelete
        jsr     DisableMenuItem
        lda     #kMenuItemIdSelectorRun
        jsr     DisableMenuItem
        copy    #$80, selector_menu_items_updated_flag
        rts
.endproc
EnableSelectorMenuItems := ToggleSelectorMenuItems::enable
DisableSelectorMenuItems := ToggleSelectorMenuItems::disable

;;; ============================================================

.proc HandleVolumeIconClick
        lda     findicon_params::which_icon
        jsr     IsIconSelected
        bne     not_selected

        ;; --------------------------------------------------
        ;; Icon was already selected
        jsr     ExtendSelectionModifierDown
        bpl     :+

        ;; Modifier down - remove from selection
        jmp     DeselectVolIcon ; deselect, nothing further

        ;; Double click or drag?
:       jmp     check_double_click

        ;; --------------------------------------------------
        ;; Icon was not already selected
not_selected:
        jsr     ExtendSelectionModifierDown
        bpl     replace_selection

        ;; Modifier down - add to selection
        lda     selected_window_id ; on desktop?
        beq     :+                 ; if so, retain selection
        jsr     ClearSelection
:       jsr     SelectVolIcon
        rts                     ; select, nothing further

        ;; Replace selection with clicked icon
replace_selection:
        jsr     ClearSelection
        jsr     SelectVolIcon
        ;; fall through...

        ;; --------------------------------------------------
check_double_click:
        jsr     StashCoordsAndDetectDoubleClick
        jpl     CmdOpenFromDoubleClick

        ;; --------------------------------------------------
        ;; Drag of volume icon
        copy    findicon_params::which_icon, drag_drop_params::icon
        ITK_RELAY_CALL IconTK::DragHighlighted, drag_drop_params
        tax
        lda     drag_drop_params::result
        beq     same_or_desktop

        jsr     DoDrop

        ;; NOTE: If drop target is trash, `JTDrop` relays to
        ;; `CmdEject` and pops the return address.

        ;; (1/4) Canceled?
        cmp     #kOperationCanceled
    IF_EQ
        rts
    END_IF

        ;; (2/4) Dropped on trash? (eject)
        ;; Not reached - see above.
        ;; Assert: `drag_drop_params::result` != `trash_icon_num`

        ;; (3/4) Dropped on icon?
        lda     drag_drop_params::result
    IF_POS
        ;; Yes, on an icon; update used/free for same-vol windows
        pha
        jsr     UpdateUsedFreeViaIcon
        pla
        jsr     FindWindowIndexForDirIcon ; X = window id-1 if found
      IF_EQ
        inx
        txa
        jmp     SelectAndRefreshWindowOrClose
      END_IF
        rts
    END_IF

        ;; (4/4) Dropped on window!
        and     #$7F            ; mask off window number
        pha
        jsr     UpdateUsedFreeViaWindow
        pla
        jmp     SelectAndRefreshWindowOrClose

        ;; --------------------------------------------------

same_or_desktop:
        txa
        cmp     #2              ; TODO: What is this case???
        bne     :+
        rts

        ;; Icons moved on desktop - update and redraw
:       ldx     selected_icon_count
        dex
:       txa
        pha
        copy    selected_icon_list,x, icon_param
        ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED (desktop)
        pla
        tax
        dex
        bpl     :-

ret:    rts

.proc SelectVolIcon
        ITK_RELAY_CALL IconTK::HighlightIcon, findicon_params::which_icon
        ITK_RELAY_CALL IconTK::DrawIcon, findicon_params::which_icon ; CHECKED (desktop)
        ldx     selected_icon_count
        copy    findicon_params::which_icon, selected_icon_list,x
        inc     selected_icon_count
        rts
.endproc

.proc DeselectVolIcon
        ITK_RELAY_CALL IconTK::UnhighlightIcon, findicon_params::which_icon
        ITK_RELAY_CALL IconTK::DrawIcon, findicon_params::which_icon ; CHECKED (desktop)
        lda     findicon_params::which_icon
        jmp     RemoveFromSelectionList
.endproc

.endproc


;;; ============================================================
;;; Drag Selection - initiated on the desktop itself

.proc DesktopDragSelect
        ;; Stash initial coords
        ldx     #.sizeof(MGTK::Point)-1
:       lda     event_params::coords,x
        sta     tmp_rect::topleft,x
        sta     tmp_rect::bottomright,x
        dex
        bpl     :-

        ;; Is this actually a drag?
        jsr     PeekEvent
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag
        beq     l2              ; yes!

        ;; No, just a click; optionally clear selection
        jsr     ExtendSelectionModifierDown
        bmi     :+               ; don't clear if mis-clicking
        jsr     ClearSelection
:       rts

        ;; --------------------------------------------------
        ;; Prep selection
l2:     lda     selected_window_id ; window?
        bne     clear              ; if so, definitely clear selection
        jsr     ExtendSelectionModifierDown
        bmi     :+
clear:  jsr     ClearSelection

        ;; --------------------------------------------------
        ;; Set up drawing port, draw initial rect
:       jsr     ResetMainGrafport

        jsr     FrameTmpRect

        ;; --------------------------------------------------
        ;; Event loop
event_loop:
        jsr     PeekEvent
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag
        beq     update

        ;; Process all icons on desktop
        jsr     FrameTmpRect
        ldx     #0
iloop:  cpx     cached_window_entry_count
        bne     :+
        ;; Finished!
        copy    #0, selected_window_id
        rts

        ;; Check if icon should be selected
:       txa
        pha
        copy    cached_window_entry_list,x, icon_param
        ITK_RELAY_CALL IconTK::IconInRect, icon_param
        beq     done_icon

        ;; Already selected?
        lda     icon_param
        jsr     IsIconSelected
    IF_NE
        ;; Highlight and add to selection
        ITK_RELAY_CALL IconTK::HighlightIcon, icon_param
        ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED (drag select)
        ldx     selected_icon_count
        copy    icon_param, selected_icon_list,x
        inc     selected_icon_count
    ELSE
        ;; Unhighlight and remove from selection
        ITK_RELAY_CALL IconTK::UnhighlightIcon, icon_param
        ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED (drag select)
        lda     icon_param
        jsr     RemoveFromSelectionList
    END_IF

done_icon:
        pla
        tax
        inx
        jmp     iloop

        ;; --------------------------------------------------
        ;; Check movement threshold
update: sub16   event_params::xcoord, last_pos + MGTK::Point::xcoord, deltax
        sub16   event_params::ycoord, last_pos + MGTK::Point::ycoord, deltay

        lda     deltax+1
        bpl     :+
        lda     deltax          ; negate
        eor     #$FF
        sta     deltax
        inc     deltax

:       lda     deltay+1
        bpl     :+
        lda     deltay          ; negate
        eor     #$FF
        sta     deltay
        inc     deltay

        ;; TODO: Experiment with making this lower.
        kDragBoundThreshold = 5

:       lda     deltax
        cmp     #kDragBoundThreshold
        bcs     :+
        lda     deltay
        cmp     #kDragBoundThreshold
        jcc     event_loop

        ;; Beyond threshold; erase rect
:       jsr     FrameTmpRect

        COPY_STRUCT MGTK::Point, event_params::coords, last_pos

        ;; --------------------------------------------------
        ;; Figure out coords for rect's left/top/bottom/right
        cmp16   event_params::xcoord, tmp_rect::x2
        bpl     l11
        cmp16   event_params::xcoord, tmp_rect::x1
        bmi     l10
        bit     x_flag
        bpl     l11
l10:    copy16  event_params::xcoord, tmp_rect::x1
        copy    #$80, x_flag
        jmp     do_y
l11:    copy16  event_params::xcoord, tmp_rect::x2
        copy    #0, x_flag

do_y:   cmp16   event_params::ycoord, tmp_rect::y2
        bpl     l14
        cmp16   event_params::ycoord, tmp_rect::y1
        bmi     l13
        bit     y_flag
        bpl     l14
l13:    copy16  event_params::ycoord, tmp_rect::y1
        copy    #$80, y_flag
        jmp     draw
l14:    copy16  event_params::ycoord, tmp_rect::y2
        copy    #0, y_flag

draw:   jsr     FrameTmpRect
        jmp     event_loop

deltax: .word   0
deltay: .word   0
last_pos:
        .tag MGTK::Point
x_flag: .byte   0
y_flag: .byte   0
.endproc

;;; ============================================================
;;; Open a folder/volume icon
;;; Input: A = icon
;;; Note: stack will be restored via `saved_stack` on failure

.proc OpenWindowForIcon
        ptr := $06

        sta     icon_param
        jsr     StoreWindowEntryTable
        lda     icon_param

        ;; Already an open window for the icon?
        ldx     #kMaxNumWindows-1
:       cmp     window_to_dir_icon_table,x
        beq     found_win
        dex
        bpl     :-
        jmp     no_linked_win

        ;; --------------------------------------------------
        ;; There is an existing window associated with icon.

found_win:                    ; X = window id - 1
        ;; Is it the active window? If so, done!
        inx
        cpx     active_window_id
        bne     :+
        rts

        ;; Otherwise, bring the window to the front.
:       stx     findwindow_params::window_id
        jmp     ActivateWindow

        ;; --------------------------------------------------
        ;; No associated window - check for matching path.

no_linked_win:
        ;; Compute the path (will be needed anyway).
        lda     icon_param
        jsr     IconEntryLookup
        stax    ptr
        jsr     ComposeIconFullPath ; may fail

        ;; Alternate entry point, called by:
        ;; `OpenWindowForPath` with `icon_param` = $FF
        ;; and `open_dir_path_buf` set.
check_path:
        param_call FindWindowForPath, open_dir_path_buf
        beq     no_win

        ;; Found a match - associate the window.
        tax                     ; A = window id
        dex                     ; 1-based to 0-based
        lda     icon_param      ; set to $FF if opening via path
        bmi     :+
        sta     window_to_dir_icon_table,x
        txa                     ; stash window id - 1
        pha
        lda     icon_param
        jsr     MarkIconOpen
        pla                     ; restore window id - 1
        tax
:       jmp     found_win       ; wants X = window id - 1

        ;; --------------------------------------------------
        ;; No window - need to open one.

no_win:
        ;; Is there a free window?
        lda     num_open_windows
        cmp     #kMaxNumWindows
        bcc     :+

        ;; Nope, show error.
        lda     #kErrTooManyWindows
        jsr     ShowAlert
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
:       lda     icon_param      ; set to $FF if opening via path
        sta     window_to_dir_icon_table,x
        inx                     ; 0-based to 1-based

        stx     cached_window_id
        jsr     LoadWindowEntryTable ; restored below

        ;; Update View and other menus
        inc     num_open_windows
        ldx     cached_window_id
        dex
        copy    #0, win_view_by_table,x

        lda     num_open_windows ; Was there already a window open?
        cmp     #2
        bcs     :+              ; yes, no need to enable file menu
        jsr     EnableMenuItemsRequiringWindow
        jmp     update_view

:       copy    #MGTK::checkitem_uncheck, checkitem_params::check
        jsr     CheckItem

update_view:
        .assert MGTK::checkitem_check = aux::kMenuItemIdViewByIcon, error, "const mismatch"
        lda     #aux::kMenuItemIdViewByIcon
        sta     checkitem_params::menu_item
        sta     checkitem_params::check
        jsr     CheckItem

        ;; This ensures `ptr` points at IconEntry (real or virtual)
        jsr     UpdateIcon

        ;; Set path (using `ptr`), size, contents, and volume free/used.
        jsr     PrepareNewWindow

        ;; Create the window
        lda     cached_window_id
        jsr     WindowLookup   ; A,X points at Winfo
        stax    @addr
        MGTK_RELAY_CALL MGTK::OpenWindow, 0, @addr

        lda     active_window_id
        jsr     UnsafeSetPortFromWindowId ; CHECKED
        sta     err

        bne     :+              ; Skip drawing if obscured
        jsr     DrawWindowHeader
:

        ;; Restore and add the icons
        jsr     CachedIconsScreenToWindow
        copy    #0, num
:       lda     num
        cmp     cached_window_entry_count
        beq     done
        tax
        lda     cached_window_entry_list,x
        sta     icon_param
        jsr     IconEntryLookup ; A,X points at IconEntry
        stax    @addr2
        ITK_RELAY_CALL IconTK::AddIcon, 0, @addr2
        err := *+1
        lda     #SELF_MODIFIED_BYTE
    IF_ZERO                     ; Skip drawing if obscured
        ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED
    END_IF
        inc     num
        jmp     :-

        ;; Finish up
done:   copy    cached_window_id, active_window_id
        jsr     UpdateScrollbars
        jsr     CachedIconsWindowToScreen
        jsr     StoreWindowEntryTable
        jsr     LoadDesktopEntryTable ; restore from above
        jmp     ResetMainGrafport

;;; Common code to update the dir (vol/folder) icon.
;;; * If `icon_param` is valid:
;;;   Points `ptr` at IconEntry, marks it open and repaints it, and sets `ptr`.
;;; * Otherwise:
;;;   Points `ptr` at a virtual IconEntry, to allow referencing the icon name.
.proc UpdateIcon
        lda     icon_param      ; set to $FF if opening via path
        jpl     MarkIconOpen

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
;;; Marks icon as open and repaints it.
;;; Input: A = icon id
;;; Output: `ptr` ($06) points at IconEntry

.proc MarkIconOpen
        ptr := $06
        lda     icon_param
        jsr     IconEntryLookup
        stax    ptr

        ;; Set open flag
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        ora     #kIconEntryFlagsOpen
        sta     (ptr),y

        ;; Only draw to desktop or active window
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        beq     :+
        cmp     active_window_id
        bne     done

:       lda     icon_param
        jsr     DrawIcon

done:   rts
.endproc

;;; ============================================================
;;; Open a folder/volume icon
;;; Input: `open_dir_path_buf` should have full path.
;;;   If a case match for existing window path, it will be activated.
;;; Note: stack will be restored via `saved_stack` on failure
;;;
;;; Set `suppress_error_on_open_flag` to avoid alert.

;;; TODO: See if an existing icon exists, mark it as open.

.proc OpenWindowForPath
        jsr     ClearSelection
        copy    #$FF, icon_param
        jsr     OpenWindowForIcon::check_path
        rts
.endproc

;;; ============================================================

.proc CheckItem
        MGTK_RELAY_CALL MGTK::CheckItem, checkitem_params
        rts
.endproc

;;; ============================================================
;;; Draw all entries (icons or list items) in (cached) window

;;; * If $80 N=1 V=?: the caller has offset the winfo's port; the
;;;   header is not drawn and the port is not adjusted.
;;; * If $40 N=0 V=1: skips drawing the header and offsets the port
;;;   for the content.
;;; * If $00 N=0 V=0: draws the header, then adjusts the port and
;;;   draws the content.
header_and_offset_flag:
        .byte   0

;;; Called from:
;;; * `UpdateWindow` flag=$80
;;; * `HandleInactiveWindowClick`; flag=$00
;;; * `ViewByNoniconCommon`; flag=$40
;;; * `UpdateScrollThumb`; flag=$40
;;; * `FinishScrollAdjustAndRedraw`; flag=$40
;;; * `OpenWindowForIcon`; flag=$00

.proc DrawWindowEntries
        ptr := $06

        jsr     PushPointers

        bit     header_and_offset_flag
    IF_NS
        lda     cached_window_id
        jsr     UnsafeSetPortFromWindowId ; CHECKED
        jne     done
    ELSE
    IF_VS
        lda     cached_window_id
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        jne     done
    ELSE
        lda     cached_window_id
        jsr     UnsafeSetPortFromWindowId ; CHECKED
        jne     done
        jsr     DrawWindowHeader
        jsr     OffsetWindowGrafportAndSet
    END_IF
    END_IF

        ;; List or Icon view?

        jsr     GetCachedWindowViewBy
        jpl     icon_view

        ;; --------------------------------------------------
        ;; List view
list_view:

        ;; Find FileRecord list
        lda     cached_window_id
        jsr     FindIndexInFilerecordListEntries
        beq     :+
        rts

:       txa
        asl     a
        tax
        copy16  window_filerecord_table,x, file_record_ptr ; points at head of list (entry count)
        inc16   file_record_ptr ; now points at first entry in list

        ;; First row

        lda     #kFirstRowBaseline
        sta     pos_col_icon::ycoord
        sta     pos_col_name::ycoord
        sta     pos_col_type::ycoord
        sta     pos_col_size::ycoord
        sta     pos_col_date::ycoord
        lda     #0
        sta     pos_col_icon::ycoord+1
        sta     pos_col_name::ycoord+1
        sta     pos_col_type::ycoord+1
        sta     pos_col_size::ycoord+1
        sta     pos_col_date::ycoord+1

        ;; Draw each list view row
        lda     #0
        sta     rows_done
        rows_done := *+1
rloop:  lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     done
        tax
        lda     cached_window_entry_list,x
        jsr     DrawListViewRow
        inc     rows_done
        jmp     rloop

        ;; --------------------------------------------------
        ;; Icon view
icon_view:

        ;; Map icons to window space
        jsr     CachedIconsScreenToWindow

        ;; Set up test rect for quick exclusion
        COPY_BLOCK window_grafport::cliprect, tmp_rect

        ;; Loop over all icons
        copy    #0, index
        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     done_icons
        tax
        lda     cached_window_entry_list,x
        sta     icon_param
        ITK_RELAY_CALL IconTK::IconInRect, icon_param
        beq     :+
        ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED
:       inc     index
        jmp     loop

done_icons:
        ;; Map icons back to screen space
        jsr     CachedIconsWindowToScreen
        jmp     done

        ;; --------------------------------------------------
done:
        jsr     ResetMainGrafport
        jsr     PopPointers
        rts
.endproc

;;; ============================================================

.proc ClearSelection
        lda     selected_icon_count
        bne     :+
        rts

:       lda     #0
        sta     index
        sta     err
        lda     selected_window_id
        beq     loop

        cmp     active_window_id ; in the active window?
        beq     use_win_port

        ;; Selection is in a non-active window
        jsr     PrepareHighlightGrafport ; TODO: ends up being a null port???
        jmp     loop

        ;; Selection is in the active window
use_win_port:
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        sta     err

        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     selected_icon_count
        beq     finish
        tax
        copy    selected_icon_list,x, icon_param
        ITK_RELAY_CALL IconTK::UnhighlightIcon, icon_param

        err := *+1
        lda     #SELF_MODIFIED_BYTE
    IF_ZERO                     ; Skip drawing if obscured
        ;; TODO: Find common pattern for redrawing multiple icons
        lda     selected_window_id
        beq     :+
        lda     icon_param
        jsr     IconScreenToWindow
:       ITK_RELAY_CALL IconTK::DrawIcon, icon_param ; CHECKED
        lda     selected_window_id
        beq     :+
        lda     icon_param
        jsr     IconWindowToScreen
:
    END_IF

        inc     index
        jmp     loop

        ;; --------------------------------------------------
        ;; Clear selection list
finish: lda     #0
        sta     selected_icon_count
        sta     selected_window_id
        jmp     ResetMainGrafport
.endproc

;;; ============================================================
;;; Check contents against window size, and activate/deactivate
;;; horizontal and vertical scrollbars as needed. The
;;; `UpdateScrollbars` entry point will update the thumbs; the
;;; `UpdateScrollbarsLeaveThumbs` entry point will not.
;;;
;;; Assert: cached icons mapped to window space (if in icon view)

.proc UpdateScrollbarsImpl
update_thumbs:
        lda     #$80
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
leave_thumbs:
        lda     #$00
        sta     update_thumbs_flag

        jsr     GetActiveWindowViewBy
    IF_POS
        ;; List view
        jsr     ComputeIconsBBox
    ELSE
        ;; Icon view
        jsr     CachedIconsScreenToWindow
        jsr     ComputeIconsBBox
        jsr     CachedIconsWindowToScreen
    END_IF

config_port:
        jsr     ApplyActiveWinfoToWindowGrafport

        ;; check horizontal bounds
        cmp16   iconbb_rect+MGTK::Rect::x1, window_grafport::cliprect::x1
        bmi     activate_hscroll
        cmp16   window_grafport::cliprect::x2, iconbb_rect+MGTK::Rect::x2
        bmi     activate_hscroll

        ;; deactivate horizontal scrollbar
        copy    #MGTK::Ctl::horizontal_scroll_bar, activatectl_params::which_ctl
        copy    #MGTK::activatectl_deactivate, activatectl_params::activate
        jsr     ActivateCtl

        jmp     check_vscroll

activate_hscroll:
        ;; activate horizontal scrollbar
        copy    #MGTK::Ctl::horizontal_scroll_bar, activatectl_params::which_ctl
        copy    #MGTK::activatectl_activate, activatectl_params::activate
        jsr     ActivateCtl

        bit     update_thumbs_flag
        bpl     :+
        jsr     UpdateHThumb
:

check_vscroll:
        ;; check vertical bounds
        cmp16   iconbb_rect+MGTK::Rect::y1, window_grafport::cliprect::y1
        bmi     activate_vscroll
        cmp16   window_grafport::cliprect::y2, iconbb_rect+MGTK::Rect::y2
        bmi     activate_vscroll

        ;; deactivate vertical scrollbar
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        copy    #MGTK::activatectl_deactivate, activatectl_params::activate
        jsr     ActivateCtl

        rts

activate_vscroll:
        ;; activate vertical scrollbar
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        copy    #MGTK::activatectl_activate, activatectl_params::activate
        jsr     ActivateCtl

        bit     update_thumbs_flag
        jmi     UpdateVThumb

.proc ActivateCtl
        MGTK_RELAY_CALL MGTK::ActivateCtl, activatectl_params
        rts
.endproc

update_thumbs_flag:
        .byte   0
.endproc
UpdateScrollbars        := UpdateScrollbarsImpl::update_thumbs
UpdateScrollbarsLeaveThumbs     := UpdateScrollbarsImpl::leave_thumbs

;;; ============================================================

.proc CachedIconsScreenToWindow
        copy    #0, count
        count := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     done
        tax
        lda     cached_window_entry_list,x
        jsr     IconScreenToWindow
        inc     count
        jmp     loop

done:   rts
.endproc

;;; ============================================================

.proc CachedIconsWindowToScreen
        lda     #0
        sta     index
        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     done
        tax
        lda     cached_window_entry_list,x
        jsr     IconWindowToScreen
        inc     index
        jmp     loop

done:   rts
.endproc

;;; ============================================================
;;; Adjust grafport for header.
.proc OffsetWindowGrafportImpl

        kOffset = kWindowHeaderHeight + 1

noset:  lda     #$80
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
set:    lda     #0
        sta     flag
        add16   window_grafport::viewloc::ycoord, #kOffset, window_grafport::viewloc::ycoord
        add16   window_grafport::cliprect::y1, #kOffset, window_grafport::cliprect::y1
        bit     flag
        bmi     :+
        MGTK_RELAY_CALL MGTK::SetPort, window_grafport
:       rts

flag:   .byte   0
.endproc
OffsetWindowGrafport    := OffsetWindowGrafportImpl::noset
OffsetWindowGrafportAndSet      := OffsetWindowGrafportImpl::set

;;; ============================================================
;;; Update used/free values for windows related to volume icon
;;; Input: A = icon number

.proc UpdateUsedFreeViaIcon
        jsr     GetIconPath   ; `path_buf3` set to path
        param_jump UpdateUsedFreeViaPath, path_buf3
.endproc

;;; ============================================================
;;; Refresh vol used/free for windows of same volume as win in A.
;;; Input: A = window id

.proc UpdateUsedFreeViaWindow
        jsr     GetWindowPath   ; into A,X
        jmp     UpdateUsedFreeViaPath
.endproc

;;; ============================================================
;;; Refresh vol used/free for windows of same volume as path in A,X.
;;; Input: A = window id

.proc UpdateUsedFreeViaPath
        ptr := $6

        stax    ptr
        jsr     PushPointers    ; save $06 = path

        ;; Strip to vol name - either end of string or next slash
        ldy     #0              ; length offset
        lda     (ptr),y
        sta     pathlen
        iny
:       iny                     ; start at 2nd character
        pathlen := *+1
        cpy     #SELF_MODIFIED_BYTE
        beq     :+
        lda     (ptr),y
        cmp     #'/'
        bne     :-
        dey
:
        ;; NOTE: Path is unchanged, but Y has effective length for
        ;; the following call.

        ;; Update `found_windows_count` and `found_windows_list`
        param_call_indirect FindWindowsForPrefix, ptr

        ;; Determine if there are windows to update
        jsr     PopPointers     ; $06 = vol path

        param_call CopyPtr1ToBuf, path_buffer

        jsr     GetVolUsedFreeViaPath
        bne     done

        ldy     found_windows_count
        beq     done
loop:   lda     found_windows_list,y
        asl     a
        tax
        copy16  vol_kb_used, window_k_used_table-2,x ; 1-based to 0-based
        copy16  vol_kb_free, window_k_free_table-2,x
        dey
        bpl     loop

done:   rts

pathptr:        .addr   0
.endproc

;;; ============================================================
;;; Find position of last segment of path at (A,X), return in Y.
;;; For "/a/b", Y points at "/b"; if volume path, unchanged.

.proc FindLastPathSegment
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
;;; `FindWindowForPath`
;;; Inputs: A,X = string (uses full string)
;;; Output: A = window id (0 if no match)
;;;
;;; `FindWindowsForPrefix`
;;; Inputs: A,X = string, Y = prefix length
;;; Outputs: `found_windows_count` and `found_windows_list` are updated

        ;; If 'prefix' version called, length in Y; otherwise use str len
.proc FindWindows
        ptr := $6

exact:  ldy     #$80
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
prefix: ldy     #0
        stax    ptr
        sty     exact_match_flag
        bit     exact_match_flag
        bpl     :+
        ldy     #0              ; Use full length
        lda     (ptr),y
        tay

:       sty     path_buffer

        ;; Copy ptr to `path_buffer`
:       lda     (ptr),y
        sta     path_buffer,y
        dey
        bne     :-

        lda     #0
        sta     found_windows_count
        sta     window_num

loop:   inc     window_num

        window_num := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #kMaxNumWindows+1 ; directory windows are 1-8
        bcc     check_window
        bit     exact_match_flag
        bpl     :+
        lda     #0
:       rts

check_window:
        jsr     WindowLookup
        stax    ptr
        ldy     #MGTK::Winfo::status
        lda     (ptr),y
        beq     loop

        lda     window_num
        jsr     GetWindowPath
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
        jsr     UpcaseChar
        sta     @char
        lda     path_buffer,y
        jsr     UpcaseChar
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
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

exact_match_flag:
        .byte   0
.endproc
        FindWindowForPath := FindWindows::exact
        FindWindowsForPrefix := FindWindows::prefix

found_windows_count:
        .byte   0
found_windows_list:
        .res    8

;;; ============================================================

.proc OpenDirectory
        jmp     Start

        DEFINE_OPEN_PARAMS open_params, open_dir_path_buf, $800

        dir_buffer := $C00

        DEFINE_READ_PARAMS read_params, dir_buffer, $200
        DEFINE_CLOSE_PARAMS close_params

;;; Copy of data from directory header
.params dir_header
entry_length:           .byte   0
entries_per_block:      .byte   0
file_count:             .word   0
.endparams

index_in_block:         .byte   0
index_in_dir:           .byte   0

.proc Start
        sta     window_id
        jsr     PushPointers
        jsr     SetCursorWatch ; before loading directory

        jsr     DoOpen
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        jsr     DoRead
        jsr     GetVolUsedFreeViaPath

        ldx     #0
:       lda     dir_buffer+SubdirectoryHeader::entry_length,x
        sta     dir_header,x
        inx
        cpx     #.sizeof(dir_header)
        bne     :-

        ;; Compute the number of free file records. This is used as a proxy
        ;; for "number of non-volume icons" below. Each record is 32 bytes;
        ;; each directory takes one length byte, so the maximum number of
        ;; records (128) can never be used, which (uncoincidentally) equals
        ;; kMaxIconCount.
        sub16   filerecords_free_end, filerecords_free_start, free_record_count
        dec16   free_record_count ; ensure this is never 128 even when totally empty
        ldx     #5              ; /= 32 .sizeof(FileRecord)
:       lsr16   free_record_count
        dex
        bne     :-

        ;; Is there room for the files?
        lda     dir_header::file_count+1 ; > 255?
        bne     too_many_files  ; yep, definitely not enough room

        lda     icon_count      ; are there enough icons free
        clc                     ; to fit all of the files?
        adc     dir_header::file_count
        bcs     too_many_files  ; overflow, definitely not enough room

        cmp     #kMaxIconCount+1 ; allow up to the maximum
        bcs     too_many_files   ; more than we can handle

        ;; This computes "how many icons would be free if all volumes had an icon",
        ;; and then checks to see if we have room.
        ;; `free_record_count` - `reserved_desktop_icons`
        ;; This should be equivalent to:
        ;; `kMaxIconCount` - (`icon_count` - # actual vol icons) - (# possible vol icons)
        ldx     DEVCNT
        inx                     ; DEVCNT is one less than number of devices
        inx                     ; And one more for Trash
        stx     reserved_desktop_icons
        sub16_8 free_record_count, reserved_desktop_icons, free_record_count ; -= # possible volume icons
        cmp16   free_record_count, dir_header::file_count ; would the files fit?
        bcs     enough_room

too_many_files:
        jsr     DoClose

        lda     active_window_id ; is a window open?
        beq     no_win
        lda     #kErrWindowMustBeClosed ; suggest closing a window
        bne     show            ; always
no_win: lda     #kErrTooManyFiles ; too many files to show
show:   jsr     ShowAlert

        jsr     MarkIconNotOpened
        dec     num_open_windows

        jsr     SetCursorPointer ; after loading directory (failed)
        ldx     saved_stack
        txs
        rts

enough_room:
        record_ptr := $06

        copy16  filerecords_free_start, record_ptr

        ;; Append entry to list
        lda     window_id_to_filerecord_list_count ; get pointer offset
        asl     a
        tax
        copy16  record_ptr, window_filerecord_table,x ; update pointer table
        ldx     window_id_to_filerecord_list_count    ; get window id offset
        window_id := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     window_id_to_filerecord_list_entries,x ; update window id list
        inc     window_id_to_filerecord_list_count

        ;; Store entry count
        lda     dir_header::file_count
        bit     LCBANK2
        bit     LCBANK2
        ldy     #0
        sta     (record_ptr),y
        bit     LCBANK1
        bit     LCBANK1

        copy    #AS_BYTE(-1), index_in_dir ; immediately incremented
        copy    #0, index_in_block

        entry_ptr := $08

        copy16  #dir_buffer + SubdirectoryHeader::storage_type_name_length, entry_ptr

        ;; Advance past entry count
        inc16   record_ptr

        ;; Record is temporarily constructed at $1F00 then copied into place.
        record := $1F00

do_entry:
        inc     index_in_dir
        lda     index_in_dir
        cmp     dir_header::file_count
        jeq     L7296

        inc     index_in_block
        lda     index_in_block
        cmp     dir_header::entries_per_block
        beq     L71E7
        add16_8 entry_ptr, dir_header::entry_length
        jmp     L71F7

L71E7:  copy    #$00, index_in_block
        copy16  #$0C04, entry_ptr
        jsr     DoRead

L71F7:  ldx     #$00
        ldy     #$00
        lda     (entry_ptr),y
        and     #$0F
        sta     record,x
        bne     L7223
        inc     index_in_block
        lda     index_in_block
        cmp     dir_header::entries_per_block
        jeq     L71E7

        add16_8 entry_ptr, dir_header::entry_length
        jmp     L71F7

L7223:  iny
        inx

        ;; See FileRecord struct for record structure

        txa
        pha
        tya
        pha
        param_call_indirect AdjustFileEntryCase, entry_ptr
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
        bit     LCBANK2
        bit     LCBANK2
        ldx     #.sizeof(FileRecord)-1
        ldy     #.sizeof(FileRecord)-1
:       lda     record,x
        sta     (record_ptr),y
        dex
        dey
        bpl     :-
        bit     LCBANK1
        bit     LCBANK1
        lda     #.sizeof(FileRecord)
        clc
        adc     record_ptr
        sta     record_ptr
        bcc     L7293
        inc     record_ptr+1
L7293:  jmp     do_entry

L7296:  copy16  record_ptr, filerecords_free_start
        jsr     DoClose
        jsr     SetCursorPointer ; after loading directory
        jsr     PopPointers
        rts

free_record_count:
        .word   0

reserved_desktop_icons:
        .byte   0
.endproc

;;; --------------------------------------------------

.proc DoOpen
        MLI_RELAY_CALL OPEN, open_params
        beq     done

        ;; On error, clean up state

        ;; Show error, unless this is during window restore.
        bit     suppress_error_on_open_flag
        bmi     :+
        jsr     ShowAlert

        ;; If opening an icon, need to reset icon state.
:       bit     icon_param      ; Were we opening a path?
        bmi     :+              ; Yes, no icons to twiddle.

        jsr     remove_filerecords_and_mark_icon_not_opened
        lda     selected_window_id
        bne     :+

        ;; BUG: This is passing a file icon to something assuming a
        ;; volume icon!
        lda     icon_param
        sta     drive_to_refresh ; icon_number
        jsr     CmdCheckSingleDriveByIconNumber

        ;; A window was allocated but unused, so restore the count
        ;; and menu item state.
:       dec     num_open_windows
        lda     num_open_windows
        bne     :+
        jsr     DisableMenuItemsRequiringWindow

        ;; A table entry was possibly allocated - free it.
:       ldy     cached_window_id
        dey
        bmi     :+
        lda     #0
        sta     window_to_dir_icon_table,y
        sta     cached_window_id

        ;; And return via saved stack.
:       jsr     SetCursorPointer
        ldx     saved_stack
        txs

done:   rts
.endproc

suppress_error_on_open_flag:
        .byte   0

;;; --------------------------------------------------

DoRead:
        MLI_RELAY_CALL READ, read_params
        rts

DoClose:
        MLI_RELAY_CALL CLOSE, close_params
        rts

;;; --------------------------------------------------
.endproc

;;; ============================================================
;;; Inputs: `path_buffer` set to full path (not modified)
;;; Outputs: Z=1 on success, `vol_kb_used` and `vol_kb_free` updated.
;;; TODO: Skip if same-vol windows already have data.

.proc GetVolUsedFreeViaPath
        lda     path_buffer
        sta     saved_length

        ;; Strip to vol name - either end of string or next slash
        ldx     #1
:       inx                     ; start at 2nd character
        cpx     path_buffer
        beq     :+
        lda     path_buffer,x
        cmp     #'/'
        bne     :-
        dex
:       stx     path_buffer

        ;; Get volume information
        param_call GetFileInfo, path_buffer
        bne     finish          ; failure

        ;; aux = total blocks
        copy16  file_info_params::aux_type, vol_kb_used
        ;; total - used = free
        sub16   file_info_params::aux_type, file_info_params::blocks_used, vol_kb_free
        sub16   vol_kb_used, vol_kb_free, vol_kb_used ; total - free = used

        ;; Blocks to K
        lsr16   vol_kb_free
        php
        lsr16   vol_kb_used
        plp
        bcc     :+
        inc16   vol_kb_used
:       lda     #0              ; success

finish: php

        saved_length := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     path_buffer

        plp
        rts
.endproc

vol_kb_free:  .word   0
vol_kb_used:  .word   0

;;; ============================================================
;;; Remove the FileRecord entries for a window, and free/compact
;;; the space.
;;; A = window id

.proc RemoveWindowFilerecordEntries
        ;; Find address of FileRecord list
        jsr     FindIndexInFilerecordListEntries
        beq     :+
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
        index := *+1
        lda     #SELF_MODIFIED_BYTE
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
        jsr     PushPointers

loop:   bit     LCBANK2
        bit     LCBANK2
        lda     (ptr_src),y
        sta     (ptr_dst),y
        bit     LCBANK1
        bit     LCBANK1
        inc16   ptr_dst
        inc16   ptr_src

        ;; All the way to top of used space
        lda     ptr_src+1
        cmp     filerecords_free_start+1
        bne     loop
        lda     ptr_src
        cmp     filerecords_free_start
        bne     loop

        jsr     PopPointers

        ;; Offset affected list pointers down
        lda     window_id_to_filerecord_list_count
        asl     a
        tax
        sub16   filerecords_free_start, window_filerecord_table,x, deltam
        inc     index

loop2:  lda     index
        cmp     window_id_to_filerecord_list_count
        jeq     finish

        lda     index
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

deltam: .word   0               ; memory delta
size:   .word   0               ; size of a window's list
.endproc

;;; ============================================================
;;; Compute full path for icon
;;; Inputs: IconEntry pointer in $06
;;; Outputs: `open_dir_path_buf` has full path
;;; Exceptions: if path too long, shows error and restores `saved_stack`
;;; See `GetIconPath` for a variant that doesn't length check.

.proc ComposeIconFullPath
        icon_ptr := $06
        name_ptr := $06

        jsr     PushPointers

        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        pha
        add16   icon_ptr, #IconEntry::name, name_ptr
        pla
        and     #kIconEntryWinIdMask
        bne     has_parent      ; A = window_id

        ;; --------------------------------------------------
        ;; Desktop (volume) icon - no parent path

        ;; Copy name
        param_call CopyPtr1ToBuf, open_dir_path_buf+1 ; Leave room for leading '/'
        ;; Add leading '/' and adjust length
        sta     open_dir_path_buf
        inc     open_dir_path_buf
        copy    #'/', open_dir_path_buf+1

        jsr     PopPointers
        rts

        ;; --------------------------------------------------
        ;; Windowed (folder) icon - has parent path
has_parent:

        parent_path_ptr := $08

        jsr     GetWindowPath
        stax    parent_path_ptr

        ldy     #0
        lda     (parent_path_ptr),y
        clc
        adc     (name_ptr),y
        cmp     #kPathBufferSize

    IF_GE
        lda     #ERR_INVALID_PATHNAME
        jsr     ShowAlert
        jsr     remove_filerecords_and_mark_icon_not_opened
        dec     num_open_windows
        ldx     saved_stack
        txs
        rts
    END_IF

        ;; Copy parent path to open_dir_path_buf
        .assert src_path_buf = open_dir_path_buf, error, "Buffer alias"
        ldax    parent_path_ptr
        jsr     CopyToSrcPath
        ldax    name_ptr
        jsr     AppendFilenameToSrcPath

        jsr     PopPointers
        rts
.endproc

;;; ============================================================
;;; Set up path and coords for new window, contents and free/used.
;;; Inputs: IconEntry pointer in $06, new window id in `cached_window_id`,
;;;         `open_dir_path_buf` has full path
;;; Outputs: Winfo configured, window path table entry set

.proc PrepareNewWindow
        icon_ptr := $06

        ;; Copy icon name to window title
.scope
        name_ptr := icon_ptr
        title_ptr := $08

        jsr     PushPointers

        lda     cached_window_id
        jsr     GetWindowTitlePath
        stax    title_ptr

        add16   icon_ptr, #IconEntry::name, name_ptr

        ldy     #0
        lda     (name_ptr),y
        tay
:       lda     (name_ptr),y
        sta     (title_ptr),y
        dey
        bpl     :-

        jsr     PopPointers
.endscope

        ;; --------------------------------------------------
        path_ptr := $08

        ;; Copy previously composed path into window path
        lda     cached_window_id
        jsr     GetWindowPath
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
        jsr     WindowLookup
        stax    winfo_ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc

        ;; xcoord = (window_id-1) * 16 + kWindowXOffset
        ;; ycoord = (window_id-1) * 8 + kWindowYOffset

        lda     cached_window_id
        sec
        sbc     #1              ; * 16
        asl     a
        asl     a
        asl     a
        asl     a

        pha
        adc     #kWindowXOffset
        sta     (winfo_ptr),y   ; viewloc::xcoord
        iny
        lda     #0
        sta     (winfo_ptr),y
        iny
        pla

        lsr     a               ; / 2
        clc
        adc     #kWindowYOffset
        sta     (winfo_ptr),y   ; viewloc::ycoord
        iny
        lda     #0
        sta     (winfo_ptr),y

        ;; Map rect (initially empty, size assigned in `CreateIconsForWindow`)
        lda     #0
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       sta     (winfo_ptr),y
        dey
        dex
        bpl     :-

        ;; Assign saved left/top?
        bit     copy_new_window_bounds_flag
    IF_MINUS
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + .sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     tmp_rect,x
        sta     (winfo_ptr),y
        dey
        dex
        bpl     :-
    END_IF

        ;; --------------------------------------------------
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
        jsr     OpenDirectory

        lda     icon_param      ; set to $FF if opening via path
        bmi     volume

        jsr     IconEntryLookup
        stax    icon_ptr
        ldy     #IconEntry::win_flags
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
        jsr     CreateIconsAndSetWindowSize
        rts
.endproc

copy_new_window_bounds_flag:
        .byte   0

;;; ============================================================
;;; File Icon Entry Construction
;;; Inputs: A = window_id

.proc CreateIconsForWindow

window_id:      .byte   0
iconbits:       .addr   0
iconentry_flags: .byte   0
icon_height:    .word   0

        ;; first icon in window
        DEFINE_POINT initial_coords, kIconBBoxOffsetLeft, kMaxIconHeight + kIconBBoxOffsetTop

        ;; first icon in current row
        DEFINE_POINT row_coords, 0, 0

icons_this_row:
        .byte   0

        DEFINE_POINT icon_coords, 0, 0

preserve_window_size_flag:
        .byte   0

.proc Impl
ep_set_window_size:
        pha
        lda     #0
        beq     common

ep_preserve_window_size:
        pha
        ldx     cached_window_id
        dex
        lda     window_to_dir_icon_table,x
        sta     icon_param      ; Guaranteed to exist, since window just created
        lda     #$80
        ;; Fall through

common: sta     preserve_window_size_flag
        pla
        sta     window_id
        jsr     PushPointers

        COPY_STRUCT MGTK::Point, initial_coords, row_coords

        lda     #0
        sta     icons_this_row
        sta     index

        ldx     #3
:       sta     icon_coords,x
        dex
        bpl     :-

        lda     cached_window_id
        jsr     FindIndexInFilerecordListEntries
        beq     :+
        rts                     ; BUG: Needs PopPointers?

        ;; Pointer to file records
        records_ptr := $06

:       txa
        asl     a
        tax
        copy16  window_filerecord_table,x, records_ptr
        bit     LCBANK2         ; get file count (resides in LC2)
        bit     LCBANK2
        ldy     #0              ; first byte in list is the list size
        lda     (records_ptr),y
        sta     num_files
        bit     LCBANK1
        bit     LCBANK1
        inc16   records_ptr
        lda     cached_window_id
        sta     active_window_id

        ;; Loop over files, creating icon for each
        index := *+1
:       lda     #SELF_MODIFIED_BYTE
        num_files := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     :+
        jsr     AllocAndPopulateFileIcon
        inc     index
        jmp     :-

:       bit     preserve_window_size_flag
        bpl     :+
        jsr     PopPointers
        rts

        ;; --------------------------------------------------
        ;; Compute the window initial size, based on icons bounding box

:       jsr     ComputeIconsBBox

        winfo_ptr := $06

        lda     window_id
        jsr     WindowLookup
        stax    winfo_ptr

        ;; convert right/bottom to width/height
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::xcoord
        sub16in iconbb_rect+MGTK::Rect::x2, (winfo_ptr),y, iconbb_rect+MGTK::Rect::x2
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        sub16in iconbb_rect+MGTK::Rect::y2, (winfo_ptr),y, iconbb_rect+MGTK::Rect::y2

        ;; Check if width is < min or > max
        cmp16   iconbb_rect+MGTK::Rect::x2, #kMinWindowWidth
        bmi     use_minw
        cmp16   iconbb_rect+MGTK::Rect::x2, #kMaxWindowWidth
        bpl     use_maxw
        ldax    iconbb_rect+MGTK::Rect::x2
        jmp     assign_width

use_minw:
        ldax    #kMinWindowWidth
        jmp     assign_width

use_maxw:
        ldax    #kMaxWindowWidth

assign_width:
        bit     copy_new_window_bounds_flag
    IF_MINUS
        ldax    tmp_rect::x2
    END_IF

        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Rect::x2
        sta     (winfo_ptr),y
        txa
        iny
        sta     (winfo_ptr),y

        ;; Check if height is < min or > max

        cmp16   iconbb_rect+MGTK::Rect::y2, #kMinWindowHeight
        bmi     use_minh
        cmp16   iconbb_rect+MGTK::Rect::y2, #kMaxWindowHeight
        bpl     use_maxh
        ldax    iconbb_rect+MGTK::Rect::y2
        jmp     assign_height

use_minh:
        ldax    #kMinWindowHeight
        jmp     assign_height

use_maxh:
        ldax    #kMaxWindowHeight

assign_height:
        bit     copy_new_window_bounds_flag
    IF_MINUS
        ldax    tmp_rect::y2
    END_IF

        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Rect::y2
        sta     (winfo_ptr),y
        txa
        iny
        sta     (winfo_ptr),y

        ;; Update scrollbars
        lda     thumbmax
        ldy     #MGTK::Winfo::hthumbmax
        sta     (winfo_ptr),y
        ldy     #MGTK::Winfo::vthumbmax
        sta     (winfo_ptr),y

        ;; Animate the window being opened
        lda     icon_param
        ldx     window_id
        jsr     AnimateWindowOpen

        ;; Finished
        jsr     PopPointers
        rts

        ;; TODO: Make this a constant?
thumbmax:
        .byte   20

.endproc

;;; ============================================================
;;; Create icon
;;; Inputs: A = record_num

.proc AllocAndPopulateFileIcon
        file_record := $6
        icon_entry := $8
        name_tmp := $1800

        pha                     ; A = record_num

        inc     icon_count
        jsr     AllocateIcon
        sta     icon_num
        ldx     cached_window_entry_count
        inc     cached_window_entry_count
        sta     cached_window_entry_list,x
        jsr     IconEntryLookup
        stax    icon_entry

        ;; Assign record number
        pla                     ; A = record_num
        ldy     #IconEntry::record_num
        sta     (icon_entry),y

        ;; Bank in the FileRecord entries
        bit     LCBANK2
        bit     LCBANK2

        ;; Copy the name
        ldy     #FileRecord::name
        lda     (file_record),y
        sta     name_tmp
        iny
        ldx     #0
:       lda     (file_record),y
        sta     name_tmp+1,x
        inx
        iny
        cpx     name_tmp
        bne     :-

        ;; Check file type
        ldy     #FileRecord::file_type
        lda     (file_record),y

        ;; Handle several classes of overrides
        sta     icontype_filetype
        ldy     #FileRecord::aux_type
        copy16in (file_record),y, icontype_auxtype
        ldy     #FileRecord::blocks
        copy16in (file_record),y, icontype_blocks
        jsr     GetIconType

        ;; Distinguish *.SYSTEM files as apps (use $01) from other
        ;; type=SYS files (use $FF).
        cmp     #IconType::system
        bne     got_type

        ldy     #FileRecord::name
        lda     (file_record),y
        tay
        ldx     str_sys_suffix
cloop:  lda     (file_record),y
        jsr     UpcaseChar
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
        PASCAL_STRING ".SYSTEM" ; do not localize

not_app:
        lda     #IconType::system
        ;; fall through

got_type:
        tay

        ;; Figure out icon type
        bit     LCBANK1
        bit     LCBANK1
        tya

        jsr     FindIconDetailsForIconType
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

        lda     cached_window_entry_count
        cmp     #kIconsPerRow
        beq     L781A
        bcs     L7826
L781A:  copy16  row_coords::xcoord, icon_coords::xcoord
L7826:  copy16  row_coords::ycoord, icon_coords::ycoord
        inc     icons_this_row
        lda     icons_this_row
        cmp     #kIconsPerRow
        bne     L7862

        ;; Next row (and initial column) if necessary
        add16   row_coords::ycoord, #kIconSpacingY, row_coords::ycoord
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
        ora     iconentry_flags
        ldy     #IconEntry::win_flags
        sta     (icon_entry),y
        ldy     #IconEntry::iconbits
        copy16in iconbits, (icon_entry),y
        ldx     cached_window_entry_count
        dex
        lda     cached_window_entry_list,x
        jsr     IconWindowToScreen

        ;; If folder, see if there's an associated window
        lda     icontype_filetype
        cmp     #FT_DIRECTORY
        bne     :+
        icon_num := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     GetIconPath     ; `path_buf3` set to path
        jsr     PushPointers
        ldax    #path_buf3
        jsr     FindWindowForPath
        tay
        jsr     PopPointers
        tya                     ; A = window id, 0 if none
        beq     :+
        tax
        dex                     ; 1-based to 0-based
        lda     icon_num
        sta     window_to_dir_icon_table,x

        ldy     #IconEntry::win_flags ; mark as open
        lda     (icon_entry),y
        ora     #kIconEntryFlagsOpen
        sta     (icon_entry),y
:
        add16   file_record, #.sizeof(FileRecord), file_record
        rts
.endproc

;;; ============================================================
;;; Inputs: A = `IconType` member
;;; Outputs: Populates `iconentry_flags`, `iconbits`, `icon_height`

.proc FindIconDetailsForIconType
        ptr := $6

        tay
        jsr     PushPointers
        tya

        ;; For populating IconEntry::win_flags
        lda     icontype_iconentryflags_table, y
        sta     iconentry_flags

        ;; For populating IconEntry::iconbits
        tya
        asl     a
        tay
        copy16  type_icons_table,y, iconbits

        ;; Icon height will be needed too
        copy16  iconbits, ptr
        ldy     #IconDefinition::maprect + MGTK::Rect::y2
        copy16in (ptr),y, icon_height

        jsr     PopPointers
        rts
.endproc

.endproc
CreateIconsAndPreserveWindowSize        := CreateIconsForWindow::Impl::ep_preserve_window_size
CreateIconsAndSetWindowSize             := CreateIconsForWindow::Impl::ep_set_window_size


;;; ============================================================
;;; Map file type (etc) to icon type

;;; Input: `icontype_type`, `icontype_auxtype`, `icontype_blocks` populated
;;; Output: A is IconType to use (for icons, open/preview, etc)

.proc GetIconType
        ptr := $06

        jsr     PushPointers
        copy16  #icontype_table, ptr

loop:   ldy     #0              ; type_mask, or $00 if done
        lda     (ptr),y
        bne     :+
        jsr     PopPointers
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
        jsr     PopPointers
        tmp := *+1
        lda     #SELF_MODIFIED_BYTE
        rts

        ;; Next entry
next:   add16   ptr, #.sizeof(ICTRecord), ptr
        jmp     loop

flags:  .byte   0
.endproc


;;; ============================================================
;;; Draw header (items/K in disk/K available/lines) for active window
;;; Assert: `cached_window_entry_count` is set (i.e. active window cached)

.proc DrawWindowHeader

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
        adc     #kWindowHeaderHeight - 2
        sta     header_line_left::ycoord
        sta     header_line_right::ycoord
        lda     window_grafport::cliprect::y1+1
        adc     #0
        sta     header_line_left::ycoord+1
        sta     header_line_right::ycoord+1

        ;; Draw top line
        MGTK_RELAY_CALL MGTK::MoveTo, header_line_left
        copy16  window_grafport::cliprect::x2, header_line_right::xcoord
        jsr     SetPenModeNotCopy
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
        add16 window_grafport::cliprect::y1, #kWindowHeaderHeight-4, items_label_pos::ycoord

        ;; Draw "XXX Items"
        lda     cached_window_entry_count
        ldx     #0
        jsr     IntToStringWithSeparators
        lda     cached_window_entry_count
        jsr     adjust_item_suffix

        MGTK_RELAY_CALL MGTK::MoveTo, items_label_pos
        jsr     DrawIntString
        param_call_indirect DrawPascalString, ptr_str_items_suffix

        ;; Draw "XXXK in disk"
        jsr     CalcHeaderCoords
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
        jsr     IntToStringWithSeparators
        MGTK_RELAY_CALL MGTK::MoveTo, pos_k_in_disk
        jsr     DrawIntString
        param_call DrawPascalString, str_k_in_disk

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
        jsr     IntToStringWithSeparators
        MGTK_RELAY_CALL MGTK::MoveTo, pos_k_available
        jsr     DrawIntString
        param_call DrawPascalString, str_k_available
        rts

.proc  adjust_item_suffix
        cmp     #1
        bne     :+
        copy16  #str_item_suffix, ptr_str_items_suffix
        rts

:       copy16  #str_items_suffix, ptr_str_items_suffix
        rts
.endproc


ptr_str_items_suffix:
        .addr   0

;;; --------------------------------------------------

.proc CalcHeaderCoords
        ;; Width of window
        sub16   window_grafport::cliprect::x2, window_grafport::cliprect::x1, xcoord

        ;; Is there room to spread things out?
        sub16   xcoord, width_items_label, xcoord
        jmi     skipcenter
        sub16   xcoord, width_right_labels, xcoord
        jmi     skipcenter

        ;; Yes - center "K in disk"
        add16   width_left_labels, xcoord, pos_k_available::xcoord
        lda     xcoord+1
        beq     :+
        lda     xcoord
        cmp     #24             ; threshold
        bcc     nosub
:       sub16   pos_k_available::xcoord, #kWindowHeaderHeight-8, pos_k_available::xcoord
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
.endproc ; CalcHeaderCoords

.proc DrawIntString
        param_jump DrawPascalString, str_from_int
.endproc

xcoord:
        .word   0
.endproc ; DrawWindowHeader

;;; ============================================================

        .include "../lib/inttostring.s"

;;; ============================================================
;;; Compute bounding box for icons within cached window

        DEFINE_RECT iconbb_rect, 0, 0, 0, 0

.proc ComputeIconsBBoxImpl

        entry_ptr := $06

        kIntMax = $7FFF

start:
        ;; max.x = max.y = 0
        ldx     #.sizeof(MGTK::Point)-1
        lda     #0
:       sta     iconbb_rect::bottomright,x
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
        jsr     GetCachedWindowViewBy
        bpl     icon_view           ; icon view

        ;; --------------------------------------------------
        ;; List view

        ;; If no items, simply zero out min and done. Otherwise,
        ;; do an actual calculation.

        lda     cached_window_entry_count
        bne     list_view_non_empty
        ;; Just fall through if no items (min = max = 0)

        ;; min.x = min.y = 0
zero_min:
        lda     #0
        ldx     #.sizeof(MGTK::Point)-1
:       sta     iconbb_rect::topleft,x
        dex
        bpl     :-
        rts

        ;; min.x = kListViewWidth
        ;; min.y = A * kRowHeight + kWindowHeaderHeight+1
list_view_non_empty:
        kRowHeight = 9          ; Default font size
        ldx     #0              ; A,X = count + 2
        ldy     #kRowHeight
        jsr     Multiply_16_8_16
        addax   #kWindowHeaderHeight+1, iconbb_rect::y2

        copy16  #kListViewWidth, iconbb_rect::x2

        ;; Now zero out min (and done
        jmp     zero_min

        ;; --------------------------------------------------
        ;; Icon view
icon_view:

check_icon:
        icon_num := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
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
        lda     cached_window_entry_list,x
        jsr     CacheIconBounds

        ;; First icon (index 0) - just use its coordinates as min/max
        lda     icon_num
        bne     compare_x

        COPY_STRUCT MGTK::Rect, cur_icon_bounds, iconbb_rect
        jmp     next

        ;; --------------------------------------------------
        ;; Compare X coords

compare_x:
        scmp16  cur_icon_bounds::x1, iconbb_rect::x1
        bmi     adjust_min_x
        scmp16  cur_icon_bounds::x1, iconbb_rect::x2
        jmi     compare_y

adjust_max_x:
        copy16  cur_icon_bounds::x1, iconbb_rect::x2
        jmp     compare_y

adjust_min_x:
        copy16  cur_icon_bounds::x1, iconbb_rect::x1

        ;; --------------------------------------------------
        ;; Compare Y coords

compare_y:
        scmp16  cur_icon_bounds::y1, iconbb_rect::y1
        bmi     adjust_min_y
        scmp16  cur_icon_bounds::y2, iconbb_rect::y2
        jmi     next

adjust_max_y:
        copy16  cur_icon_bounds::y2, iconbb_rect::y2
        jmp     next

adjust_min_y:
        copy16  cur_icon_bounds::y1, iconbb_rect::y1

next:   inc     icon_num
        jmp     check_icon
.endproc
ComputeIconsBBox        := ComputeIconsBBoxImpl::start

;;; ============================================================
;;; Compute dimensions of window
;;; Input: A = window
;;; Output: A,X = width, Y = height

.proc ComputeWindowDimensions
        ptr := $06

        jsr     WindowLookup
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

        DEFINE_RECT rect, 0, 0, 0, 0

.endproc

;;; ============================================================

.proc SortRecords
        ptr := $06

record_num      := $800
list_start_ptr  := $801
num_records     := $803
        ;; $804 = scratch byte
index           := $805

        jmp     start

start:  lda     cached_window_id
        jsr     FindIndexInFilerecordListEntries
        beq     found
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

        bit     LCBANK2         ; Start copying records
        bit     LCBANK2

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
        jsr     PtrCalc

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
        lda     #$01            ; if mod date is $0000, set it to $0100 ???
        sta     (ptr),y

next:   inc     record_num
        jmp     loop

break:  bit     LCBANK1         ; Done copying records
        bit     LCBANK1

        ;; --------------------------------------------------

        ;; What sort order?
        jsr     GetCachedWindowViewBy
        cmp     #kViewByName
        jne     check_date

        ;; By Name

        ;; Sorted in increasing lexicographical order
.scope
        name := $807
        kNameSize = $F
        name_len  := $804

        bit     LCBANK2
        bit     LCBANK2

        ;; Set up highest value
        lda     #$7F            ; beyond last possible name char
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
        jmp     FinishViewChange

iloop:  jsr     PtrCalc

        ;; Check record for mark
        ldy     #0
        lda     (ptr),y
        bmi     inext

        ;; Compare names
        and     #NAME_LENGTH_MASK
        sta     name_len
        ldy     #1
cloop:  lda     (ptr),y
        jsr     UpcaseChar
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
        jsr     UpcaseChar
        sta     name,y
        dey
        bne     :-

inext:  inc     record_num
        lda     record_num
        cmp     num_records
        jne     iloop

        inc     index
        lda     $0806
        sta     record_num
        jsr     PtrCalc

        ;; Mark record
        ldy     #0
        lda     (ptr),y
        ora     #$80
        sta     (ptr),y

        kMaxFilenameLength = 15
        lda     #$7F            ; beyond last possible name char
        ldx     #kMaxFilenameLength
:       sta     $0808,x
        dex
        bpl     :-

        ldx     index
        dex
        ldy     $0806
        iny
        jsr     UpdateCachedWindowEntry

        lda     #0
        sta     record_num
        jmp     loop
.endscope

        ;; --------------------------------------------------

check_date:
        cmp     #kViewByDate
        jne     check_size

        ;; By Date

        ;; Sorted by decreasing date
.scope
        date    := $0808

        bit     LCBANK2
        bit     LCBANK2

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
        jmp     FinishViewChange

iloop:  jsr     PtrCalc

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
        jsr     CompareDates
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
        jsr     PtrCalc

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
        jsr     UpdateCachedWindowEntry

        copy    #0, record_num
        jmp     loop
.endscope

        ;; --------------------------------------------------

check_size:
        cmp     #kViewBySize
        jne     check_type

        ;; By Size

        ;; Sorted by decreasing size
.scope
        size := $0808

        bit     LCBANK2
        bit     LCBANK2

        lda     #0
        sta     size
        sta     size+1
        sta     index
        sta     record_num

loop:   lda     index
        cmp     num_records
        bne     iloop
        jmp     FinishViewChange

iloop:  jsr     PtrCalc

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
        jsr     PtrCalc

        ;; Mark record
        ldy     #0
        lda     (ptr),y
        ora     #$80
        sta     (ptr),y

        copy16  #0, size

        ldx     index
        dex
        ldy     $0806
        iny
        jsr     UpdateCachedWindowEntry

        lda     #0
        sta     record_num
        jmp     loop
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

        bit     LCBANK2
        bit     LCBANK2

        lda     #0
        sta     index
        sta     record_num
        copy    #$FF, $0806

loop:   lda     index
        cmp     num_records
        bne     iloop
        jmp     FinishViewChange

iloop:  jsr     PtrCalc

        ;; Check record for mark
        ldy     #0
        lda     (ptr),y
        bmi     inext

        ;; Compare types
        ldy     #FileRecord::file_type
        lda     (ptr),y
        ldx     type_table_copy
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
        jsr     PtrCalc

        ;; Mark record
        ldy     #0
        lda     (ptr),y
        ora     #$80
        sta     (ptr),y

        ldx     index
        dex
        ldy     $0806
        iny
        jsr     UpdateCachedWindowEntry

        copy    #0, record_num
        copy    #$FF, $0806
        jmp     loop
.endscope

;;; --------------------------------------------------
;;; ptr = `list_start_ptr` + (`record_num` * .sizeof(FileRecord))

.proc PtrCalc
        ptr := $6

        lda     record_num
        .assert .sizeof(FileRecord) = 32, error, "FileRecord size must be 2^5"
        jsr     ATimes32
        addax   list_start_ptr, ptr

        rts
.endproc

;;; --------------------------------------------------

date_a: .tag    DateTime
date_b: .tag    DateTime

.proc CompareDates
        ptr := $0A

        copy16  #parsed_a, ptr
        ldax    #date_a
        jsr     ParseDatetime

        copy16  #parsed_b, ptr
        ldax    #date_b
        jsr     ParseDatetime

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

.proc FinishViewChange
        ptr := $06

        copy    #0, record_num

loop:   lda     record_num
        cmp     num_records
        beq     done
        jsr     PtrCalc

        ldy     #$00            ; Remove mark
        lda     (ptr),y
        and     #$7F
        sta     (ptr),y

        ldy     #FileRecord::modification_date ; ???
        lda     (ptr),y
        bne     :+
        iny
        lda     (ptr),y         ; modification_date hi
        cmp     #$01
        bne     :+
        lda     #$00            ; if mod date was $0000 and set to $0100, reset it
        sta     (ptr),y
:       inc     record_num
        jmp     loop

done:   bit     LCBANK1
        bit     LCBANK1
        rts
.endproc

;;; --------------------------------------------------
;;; Inputs: X = index in window, Y = new value

.proc UpdateCachedWindowEntry
        bit     LCBANK1
        bit     LCBANK1
        tya
        sta     cached_window_entry_list,x
        bit     LCBANK2
        bit     LCBANK2
        rts
.endproc

.endproc


;;; ============================================================
;;; A = entry number

.proc DrawListViewRow

        kRowHeight = 9          ; Default font height

        ptr := $06

        ;; Compute address of (A-1)th file record
        tax                     ; 1-based to 0-based
        dex
        txa
        .assert .sizeof(FileRecord) = 32, error, "FileRecord size must be 2^5"
        jsr     ATimes32      ; A,X = A * 32
        addax   file_record_ptr, ptr

        ;; Copy into more convenient location (LCBANK1)
        bit     LCBANK2
        bit     LCBANK2
        ldy     #.sizeof(FileRecord)-1
:       lda     (ptr),y
        sta     list_view_filerecord,y
        dey
        bpl     :-
        bit     LCBANK1
        bit     LCBANK1

        ;; Below bottom?
        cmp16   pos_col_name::ycoord, window_grafport::cliprect::y2
        bpl     ret

        add16_8 pos_col_icon::ycoord, #kRowHeight
        add16_8 pos_col_name::ycoord, #kRowHeight
        add16_8 pos_col_type::ycoord, #kRowHeight
        add16_8 pos_col_size::ycoord, #kRowHeight
        add16_8 pos_col_date::ycoord, #kRowHeight

        ;; Above top?
        cmp16   pos_col_name::ycoord, window_grafport::cliprect::y1
        bpl     in_range
ret:    rts

        ;; Draw it!
in_range:
        jsr     PrepareColGlyph
        param_call SetPosDrawText, pos_col_icon
        jsr     PrepareColName
        param_call SetPosDrawText, pos_col_name
        jsr     PrepareColType
        param_call SetPosDrawText, pos_col_type
        jsr     PrepareColSize
        param_call SetPosDrawText, pos_col_size
        jsr     ComposeDateString
        param_jump SetPosDrawText, pos_col_date
.endproc

;;; ============================================================

.proc PrepareColGlyph
        file_type := list_view_filerecord + FileRecord::file_type

        lda     file_type
        cmp     #FT_DIRECTORY
    IF_EQ
        copy    #kGlyphFolderLeft, text_buffer2::data
        copy    #kGlyphFolderRight, text_buffer2::data+1
        lda     #2
    ELSE
        copy    #' ', text_buffer2::data
        lda     #1
    END_IF
        sta     text_buffer2::length

        rts
.endproc

.proc PrepareColName
        name := list_view_filerecord + FileRecord::name

        lda     name
        and     #NAME_LENGTH_MASK
        sta     text_buffer2::length
        tax
:       lda     name,x
        sta     text_buffer2::data-1,x
        dex
        bne     :-

        rts
.endproc

.proc PrepareColType
        file_type := list_view_filerecord + FileRecord::file_type

        lda     file_type
        jsr     ComposeFileTypeString

        COPY_BYTES 5, str_file_type, text_buffer2::length ; 4 characters + length

        rts
.endproc

.proc PrepareColSize
        blocks := list_view_filerecord + FileRecord::blocks

        ldax    blocks
        ;; fall through
.endproc

;;; ============================================================
;;; Populate `text_buffer2` with " 12,345K"

.proc ComposeSizeString
        stax    value           ; size in 512-byte blocks

        lsr16   value       ; Convert blocks to K, rounding up
        bcc     :+          ; NOTE: divide then maybe inc, rather than
        inc16   value       ; always inc then divide, to handle $FFFF
:

        ldax    value
        jsr     IntToStringWithSeparators

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
:       lda     str_kb_suffix+1, y
        sta     text_buffer2::data,x
        iny
        inx
        cpy     str_kb_suffix
        bne     :-

        stx     text_buffer2::length
        rts

value:  .word   0

.endproc

;;; ============================================================

.proc ComposeDateString
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
        jmp     AppendMonthString

append_date_strings:
        copy16  #parsed_date, $0A
        ldax    #datetime_for_conversion
        jsr     ParseDatetime

        jsr     AppendMonthString
        param_call ConcatenateDatePart, str_space
        jsr     AppendDayString
        param_call ConcatenateDatePart, str_comma
        jsr     AppendYearString

        param_call ConcatenateDatePart, str_at
        ldax    #parsed_date
        jsr     MakeTimeString
        param_jump ConcatenateDatePart, str_time

.proc AppendDayString
        lda     day
        ldx     #0
        jsr     IntToString

        param_jump ConcatenateDatePart, str_from_int
.endproc

.proc AppendMonthString
        lda     month
        asl     a
        tay
        lda     month_table+1,y
        tax
        lda     month_table,y

        jmp     ConcatenateDatePart
.endproc

.proc AppendYearString
        ldax    year
        jsr     IntToString
        param_jump ConcatenateDatePart, str_from_int
.endproc

year    := parsed_date + ParsedDateTime::year
month   := parsed_date + ParsedDateTime::month
day     := parsed_date + ParsedDateTime::day
hour    := parsed_date + ParsedDateTime::hour
min     := parsed_date + ParsedDateTime::minute

.proc ConcatenateDatePart
        stax    $06
        ldy     #$00
        lda     ($08),y
        sta     concat_len
        clc
        adc     ($06),y
        sta     ($08),y
        lda     ($06),y
        sta     compare_y
:       inc     concat_len
        iny
        lda     ($06),y
        sty     tmp
        concat_len := *+1
        ldy     #SELF_MODIFIED_BYTE
        sta     ($08),y
        tmp := *+1
        ldy     #SELF_MODIFIED_BYTE
        compare_y := *+1
        cpy     #SELF_MODIFIED_BYTE
        bcc     :-
        rts
.endproc

.endproc

;;; ============================================================
;;; After a scroll, update window clipping region
;;;
;;; Inputs are thumbpos, thumbmax, icon bbox, window cliprect.
;;; Output is an updated cliprect.
;;;
;;; Assert: cached icons mapped to window space
;;; Assert: window_grafport reflects active window

.proc UpdateCliprectAfterScroll
        copy    #0, sense_flag

        ;; Compute window size
        sub16   window_grafport::cliprect::x2, window_grafport::cliprect::x1, win_width
        sub16   window_grafport::cliprect::y2, window_grafport::cliprect::y1, win_height

        ;; Set `dir` to be an offset to either 0 (if horiz) or 2 (if vert)
        ;; Used for both an offset to Point::xcoord or Point::ycoord
        ;; and an offset to Winfo::hthumbmax or Winfo::vthumbmax
        .assert MGTK::Point::xcoord - MGTK::Point::ycoord = MGTK::Winfo::hthumbmax - MGTK::Winfo::vthumbmax, error, "Offsets should match"

        lda     updatethumb_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar ; vertical?
        bne     horiz
        asl     a               ; == Point::ycoord
        bne     :+              ; always
horiz:  lda     #0              ; == Point::xcoord
:       sta     dir

        ptr := $06

        ;; Look up thumbmax
        lda     active_window_id
        jsr     WindowLookup
        stax    ptr
        lda     #MGTK::Winfo::hthumbmax
        clc
        adc     dir
        tay
        lda     (ptr),y
        pha                     ; thumbmax

        ;; Compute size delta (content vs. window)
        jsr     ComputeIconsBBox

        ldx     dir
        sub16   iconbb_rect::bottomright,x, iconbb_rect::topleft,x, delta ; delta = bb size
        sub16   delta, win_size,x, delta ; delta -= window size

        ;; If content is smaller than window, edge cases.
        ;; NOTE: Icons are in window space!
    IF_NEG
        ;; If content to left of window, delta is distance to left edge
        sub16   window_grafport::cliprect::topleft,x, iconbb_rect::topleft,x, delta
      IF_NEG
        ;; Else, to the right, delta is distance to right edge
        copy    #$80, sense_flag
        sub16   iconbb_rect::bottomright,x, window_grafport::cliprect::bottomright,x, delta
      END_IF
    END_IF

        ;; Scale delta down to fit in single byte
        lsr16   delta     ; / 4
        lsr16   delta     ; which should bring it into single byte range

        ldy     delta           ; scroll range / 4
        pla                     ; thumbmax
        tax
        lda     updatethumb_params::thumbpos ; thumbpos

        ;; A:X = R:Y
        ;; A = thumbpos
        ;; X = thumbmax
        ;; Y = scroll range / 4
        ;; R = scroll position / 4
        jsr     CalculateThumbPos

        ;; Scale new delta up again
        sta     delta
        copy    #0, delta+1
        asl16   delta           ; * 4
        asl16   delta

        ;; Apply to the window port
        ldx     dir
        bit     sense_flag
    IF_POS
        ;; win min = content min + delta
        add16   delta, iconbb_rect::topleft,x, window_grafport::cliprect::topleft,x
    ELSE
        ;; win near += delta, which derives from:
        ;; new win min = content min + content size - orig delta + new delta - window size
        add16   window_grafport::cliprect::topleft,x, delta, window_grafport::cliprect::topleft,x
    END_IF
        add16   window_grafport::cliprect::topleft,x, win_size,x, window_grafport::cliprect::bottomright,x

        ;; Update window's port
update_port:
        lda     active_window_id
        jsr     WindowLookup
        stax    ptr

        ldy     #.sizeof(MGTK::GrafPort)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     window_grafport::cliprect,x
        sta     (ptr),y
        dey
        dex
        bpl     :-

        rts

dir:    .byte   0               ; 0 if horizontal, 2 if vertical (word offset)
delta:  .word   0               ; offset between content and cliprect

win_size:
win_width:      .word   0
win_height:     .word   0

sense_flag:     .byte   0
.endproc


;;; ============================================================

;;; A,X = A * 16
.proc ATimes16
        ldx     #4
        bne     AShiftX       ; always
.endproc

;;; A,X = A * 32
.proc ATimes32
        ldx     #5
        bne     AShiftX       ; always
.endproc

;;; A,X = A * 64
.proc ATimes64
        ldx     #6
        bne     AShiftX       ; always
.endproc

;;; A,X = A << X
.proc AShiftX
        ldy     #0
        sty     hi

:       asl     a
        rol     hi
        dex
        bne     :-

        hi := *+1
        ldx     #SELF_MODIFIED_BYTE
        rts
.endproc

;;; ============================================================
;;; Look up an icon address.
;;; Inputs: A = icon number
;;; Output: A,X = IconEntry address

.proc IconEntryLookup
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
;;; Look up window.
;;; Inputs: A = window id
;;; Output: A,X = Winfo address

.proc WindowLookup
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
;;; Look up window path.
;;; Input: A = window_id
;;; Output: A,X = path address

.proc GetWindowPath
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
;;; Look up window title path.
;;; Input: A = window_id
;;; Output: A,X = title path address

.proc GetWindowTitlePath
        asl     a
        tax
        lda     window_title_addr_table,x
        pha
        lda     window_title_addr_table+1,x
        tax
        pla
        rts
.endproc

;;; ============================================================
;;; Inputs: A = icon id (volume or file)
;;; Outputs: `path_buf3` populated with full path
;;; NOTE: Does not do length checks.
;;; See `ComposeIconFullPath` for a variant that length checks.

.proc GetIconPath
        tay                     ; A = icon
        jsr     PushPointers
        tya                     ; A = icon

        icon_ptr := $06
        jsr     IconEntryLookup
        stax    icon_ptr

        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        pha                     ; A = window id
        add16   icon_ptr, #IconEntry::name, icon_ptr
        pla
        bne     file            ; A = window id

        ;; Volume - no base path
        copy16  #0, $08         ; base
        beq     common          ; always

        ;; File - window path is base path
file:
        jsr     GetWindowPath
        stax    $08

common: jsr     JoinPaths      ; $08 = base, $06 = file
        jsr     PopPointers
        rts
.endproc

;;; ============================================================
;;; Input: A,X = path to copy
;;; Output: populates `src_path_buf` a.k.a. `open_dir_path_buf` a.k.a. `INVOKER_PREFIX`

.proc CopyToSrcPath
        stax    @ptr1
        stax    @ptr2
        ldy     #0
        @ptr1 := *+1
        lda     SELF_MODIFIED,y
        tay
        @ptr2 := *+1
:       lda     SELF_MODIFIED,y
        sta     src_path_buf,y
        dey
        bpl     :-
        rts
.endproc

;;; ============================================================
;;; Input: A,X = path to copy
;;; Output: populates `dst_path_buf`

.proc CopyToDstPath
        stax    @ptr1
        stax    @ptr2
        ldy     #0
        @ptr1 := *+1
        lda     SELF_MODIFIED,y
        tay
        @ptr2 := *+1
:       lda     SELF_MODIFIED,y
        sta     dst_path_buf,y
        dey
        bpl     :-
        rts
.endproc

;;; ============================================================
;;; Input: A,X = path to append
;;; Output: appends '/' and path to `src_path_buf` a.k.a. `open_dir_path_buf` a.k.a. `INVOKER_PREFIX`

.proc AppendFilenameToSrcPath
        stax    @ptr1
        stax    @ptr2

        ;; Append '/'
        ldx     src_path_buf
        inx
        lda     #'/'
        sta     src_path_buf,x

        ;; Append new filename
        ldy     #0
:       inx
        iny
        @ptr1 := *+1
        lda     SELF_MODIFIED,y
        sta     src_path_buf,x
        @ptr2 := *+1
        cpy     SELF_MODIFIED
        bne     :-
        stx     src_path_buf

        rts
.endproc

;;; ============================================================
;;; Input: A,X = path to append
;;; Output: appends '/' and path to `dst_path_buf`

.proc AppendFilenameToDstPath
        stax    @ptr1
        stax    @ptr2

        ;; Append '/'
        ldx     dst_path_buf
        inx
        lda     #'/'
        sta     dst_path_buf,x

        ;; Append new filename
        ldy     #0
:       inx
        iny
        @ptr1 := *+1
        lda     SELF_MODIFIED,y
        sta     dst_path_buf,x
        @ptr2 := *+1
        cpy     SELF_MODIFIED
        bne     :-
        stx     dst_path_buf

        rts
.endproc

;;; ============================================================

.proc ComposeFileTypeString
        ptr := $06

        sta     file_type
        copy16  #type_table, ptr
        ldy     #kNumFileTypes-1
:       lda     (ptr),y
        file_type := *+1
        cmp     #SELF_MODIFIED_BYTE
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
.endproc

;;; ============================================================
;;; Append aux type (in A,X) to text_buffer2

.proc AppendAuxType
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
        jsr     DoByte
        lda     auxtype
        jsr     DoByte

        sty     text_buffer2::length
        rts

DoByte:
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

prefix: PASCAL_STRING res_string_auxtype_prefix

auxtype:
        .word 0
.endproc

;;; ============================================================
;;; Draw text, pascal string address in A,X

.proc DrawPascalString
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

.proc MeasureText1
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
;;; Pushes two words from $6/$8 to stack; trashes A,X

.proc PushPointers
        ptr := $6

        ;; Stash return address
        pla
        sta     lo
        pla
        sta     hi

        ;; Copy 4 bytes from $8 to stack
        ldx     #AS_BYTE(-4)
:       lda     $06 + 4,x
        pha
        inx
        bne     :-

        ;; Restore return address
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        rts
.endproc

;;; ============================================================
;;; Pops two words from stack to $6/$8; trashes A,X

.proc PopPointers
        ptr := $6

        ;; Stash return address
        pla
        sta     lo
        pla
        sta     hi

        ;; Copy 4 bytes from stack to $6
        ldx     #3
:       pla
        sta     $06,x
        dex
        bpl     :-

        ;; Restore return address to stack
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        rts
.endproc

;;; ============================================================

.proc SwapWindowPortbits
        ptr := $6

        tay
        jsr     PushPointers
        tya
        jsr     WindowLookup
        stax    ptr

        ldy     #MGTK::Winfo::port
:       lda     (ptr),y
        tax
        lda     saved_portbits-MGTK::Winfo::port,y
        sta     (ptr),y
        txa
        sta     saved_portbits-MGTK::Winfo::port,y
        iny
        cpy     #MGTK::Winfo::port+.sizeof(MGTK::GrafPort)
        bne     :-
        jsr     PopPointers
        rts

saved_portbits:
        .res    .sizeof(MGTK::GrafPort)+1, 0
.endproc

;;; ============================================================
;;; Convert icon's coordinates from window to screen
;;; (icon index in A, active window)

.proc IconWindowToScreen
        entry_ptr := $6
        winfo_ptr := $8

        tay
        jsr     PushPointers
        tya
        jsr     IconEntryLookup
        stax    entry_ptr

        lda     active_window_id
        jsr     WindowLookup
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

        jsr     PopPointers
        rts

pos_screen:     .word   0, 0
pos_win:        .word   0, 0

.endproc

;;; ============================================================
;;; Convert icon's coordinates from screen to window
;;; (icon index in A, active window)

.proc IconScreenToWindow
        tay
        jsr     PushPointers
        tya
        jsr     IconEntryLookup
        stax    $06
        ;; fall through
.endproc

;;; Convert icon's coordinates from screen to window
;;; (icon entry pointer in $6, active window)
;;; NOTE: does `PopPointers` before exiting
.proc IconPtrScreenToWindow
        entry_ptr := $6
        winfo_ptr := $8

        lda     active_window_id
        jsr     WindowLookup
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
        jsr     PopPointers
        rts

pos_screen:     .word   0, 0
pos_win:        .word   0, 0
.endproc

;;; ============================================================
;;; Zero out and then select highlight_grafport. Used for setting
;;; and clearing selections (since icons are in screen space).

.proc PrepareHighlightGrafport
        lda     #0
        tax
:       sta     highlight_grafport::cliprect::topleft,x
        sta     highlight_grafport::viewloc::xcoord,x
        sta     highlight_grafport::cliprect::bottomright,x
        inx
        cpx     #.sizeof(MGTK::Point)
        bne     :-
        MGTK_RELAY_CALL MGTK::SetPort, highlight_grafport
        rts
.endproc

;;; ============================================================
;;; Input: A = unit_number
;;; Output: A,X=name (length may be 0), Y =
;;;  0 = Disk II
;;;  1 = RAM Disk (including SmartPort RAM Disk)
;;;  2 = Fixed (e.g. ProFile)
;;;  3 = Removable (e.g. UniDisk 3.5)
;;;  4 = AppleTalk file share
;;;
;;; NOTE: Called from Initializer (init) which resides in $800-$1200+
;;;
;;; Name is hardcoded if Disk II, RAM Disk, or AppleTalk; via SmartPort
;;; (re-cased) if the call succeeds, otherwise pointer to empty string.
;;;
;;; Uses start of $800 as a param buffer

device_type_to_icon_address_table:
        .addr floppy140_icon
        .addr ramdisk_icon
        .addr profile_icon
        .addr floppy800_icon
        .addr fileshare_icon
        ASSERT_ADDRESS_TABLE_SIZE device_type_to_icon_address_table, ::kNumDeviceTypes

.params status_params
param_count:    .byte   3
unit_num:       .byte   1
list_ptr:       .addr   dib_buffer
status_code:    .byte   3       ; Return Device Information Block (DIB)
.endparams

PARAM_BLOCK dib_buffer, $800
Device_Statbyte1        .byte
Device_Size_Lo          .byte
Device_Size_Med         .byte
Device_Size_Hi          .byte
ID_String_Length        .byte
Device_Name             .res    16
Device_Type_Code        .byte
Device_Subtype_Code     .byte
Version                 .word
END_PARAM_BLOCK

;;; Roughly follows:
;;; Technical Note: ProDOS #21: Identifying ProDOS Devices
;;; http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.21.html

.proc GetDeviceType
        slot_addr := $0A

        ;; Avoid Initializer memory ($800-$1200)
        block_buffer := $1E00

        sta     unit_number

        ;; Special case for RAM.DRV.SYSTEM/RAMAUX.SYSTEM
        cmp     #kRamDrvSystemUnitNum
        beq     ram
        cmp     #kRamAuxSystemUnitNum
        bne     :+
ram:    ldax    #str_device_type_ramdisk
        ldy     #kDeviceTypeRAMDisk
        rts
:
        ;; Special case for VEDRIVE
        jsr     DeviceDriverAddress ; populates `slot_addr`, Z=1 if $Cn
        cmp16   slot_addr, #kVEDRIVEDriverAddress
        bne     :+
vdrive: ldax    #str_device_type_vdrive
        ldy     #kDeviceTypeFileShare
        rts
:
        ;; Special case for VSDRIVE
        cmp16   slot_addr, #kVSDRIVEDriverAddress
        bne     :+
        sta     ALTZPOFF        ; peek at Main/LCBANK1
        lda     VSDRIVE_SIGNATURE_BYTE
        sta     ALTZPON         ; back to Aux/LCBANK1
        cmp     #kVSDRIVESignatureValue
        beq     vdrive
:
        ;; Is Disk II? A dedicated test that takes advantage of the
        ;; fact that Disk II devices are never remapped.
        lda     unit_number
        jsr     IsDiskII
        bne     :+
        ldax    #str_device_type_diskii
        ldy     #kDeviceTypeDiskII
        rts
:
        ;; Look up driver address
        lda     unit_number
        jsr     DeviceDriverAddress ; populates `slot_addr`, Z=1 if $Cn
        jne     generic             ; not $CnXX, unknown type

        ;; Firmware driver; maybe SmartPort?
        sp_addr := $0A
        lda     unit_number
        jsr     FindSmartportDispatchAddress
        bne     not_sp
        stx     status_params::unit_num

        ;; Execute SmartPort call
        jsr     SmartportCall
        .byte   SPCall::Status
        .addr   status_params
        bcs     not_sp

        ;; Trim trailing whitespace (seen in CFFA)
.scope
        ldy     dib_buffer::ID_String_Length
        beq     done
:       lda     dib_buffer::Device_Name-1,y
        cmp     #' '
        bne     done
        dey
        bne     :-
done:   sty     dib_buffer::ID_String_Length
.endscope

        ;; Case-adjust
.scope
        ldy     dib_buffer::ID_String_Length
        beq     done
        dey
        beq     done

        ;; Look at prior and current character; if both are alpha,
        ;; lowercase current.
loop:   lda     dib_buffer::Device_Name-1,y ; Test previous character
        jsr     IsAlpha
        bne     next
        lda     dib_buffer::Device_Name,y ; Adjust this one if also alpha
        jsr     IsAlpha
        bne     next
        lda     dib_buffer::Device_Name,y
        ora     #AS_BYTE(~CASE_MASK)
        sta     dib_buffer::Device_Name,y

next:   dey
        bne     loop
done:
.endscope

        ;; Check device type
        ;; Technical Note: SmartPort #4: SmartPort Device Types
        ;; http://www.1000bit.it/support/manuali/apple/technotes/smpt/tn.smpt.4.html
        lda     dib_buffer::Device_Type_Code
        .assert SPDeviceType::MemoryExpansionCard = 0, error, "enum mismatch"
        bne     test_size     ; $00 = Memory Expansion Card (RAM Disk)
        ;; NOTE: Codes for 3.5" disk ($01) and 5-1/4" disk ($0A) are not trusted
        ;; since emulators do weird things.
        ;; TODO: Is that comment about false positives or false negatives?
        ;; i.e. if $01 or $0A is seen, can that be trusted?

        ldax    #dib_buffer::ID_String_Length
        ldy     #kDeviceTypeRAMDisk
        rts

not_sp:
        ;; Not SmartPort - try AppleTalk
        MLI_RELAY_CALL READ_BLOCK, block_params
        beq     :+
        cmp     #ERR_NETWORK_ERROR
        bne     :+
        ldax    #str_device_type_appletalk
        ldy     #kDeviceTypeFileShare
        rts
:

        ;; RAM-based driver or not SmartPort
generic:
        copy    #0, dib_buffer::ID_String_Length

test_size:

        ;; SmartPort or Generic Block Device
        ;; Select either 3.5" Floppy or ProFile icon

        ;; Old heuristic. Invalid on UDC, etc.
        ;;         and     #%00001111
        ;;         cmp     #DT_REMOVABLE

        ;; Better heuristic, but still invalid on UDC, Virtual II, etc.
        ;;         and     #%00001000      ; bit 3 = is removable?

        ;; So instead, just display:
        ;;   <=  280 blocks (140k) as a 5.25" floppy
        ;;   <= 1600 blocks (800k) as a 3.5" floppy

        kMax525FloppyBlocks = 280
        kMax35FloppyBlocks = 1600

        lda     unit_number
        jsr     GetBlockCount
        bcs     :+
        stax    blocks
        cmp16   blocks, #kMax525FloppyBlocks+1
        bcc     f525
        cmp16   blocks, #kMax35FloppyBlocks+1
        bcc     f35

:       ldax    #dib_buffer::ID_String_Length
        ldy     #kDeviceTypeFixed
        rts

f525:   ldax    #dib_buffer::ID_String_Length
        ldy     #kDeviceTypeDiskII
        rts

f35:    ldax    #dib_buffer::ID_String_Length
        ldy     #kDeviceTypeRemovable
        rts

        DEFINE_READ_BLOCK_PARAMS block_params, block_buffer, 2
        unit_number := block_params::unit_num

SmartportCall:
        jmp     (sp_addr)

blocks: .word   0

str_device_type_diskii:
        PASCAL_STRING res_string_volume_type_disk_ii
str_device_type_ramdisk:
        PASCAL_STRING res_string_volume_type_ramcard
str_device_type_appletalk:
        PASCAL_STRING res_string_volume_type_fileshare
str_device_type_vdrive:
        PASCAL_STRING res_string_volume_type_vdrive
.endproc

;;; ============================================================
;;; Get the block count for a given unit number.
;;; Input: A=unit_number
;;; Output: C=0, blocks in A,X on success, C=1 on error
.proc GetBlockCountImpl
        ;; Use $800 scratch space right after `dib_buffer`
        path := $880            ; becomes length-prefixed path
        buffer := path+1        ; length overwritten with '/'

        DEFINE_ON_LINE_PARAMS on_line_params,, buffer

start:  sta     on_line_params::unit_num
        MLI_RELAY_CALL ON_LINE, on_line_params
        bcs     ret

        ;; Prefix the path with '/'
        lda     buffer
        and     #NAME_LENGTH_MASK
        clc
        adc     #1              ; account for '/'
        sta     path
        copy    #'/', buffer

        param_call GetFileInfo, path
        bcs     ret
        ldax    file_info_params::aux_type

ret:    rts
.endproc
GetBlockCount   := GetBlockCountImpl::start

;;; ============================================================
;;; Create Volume Icon
;;; Input: A = unit number, Y = index in DEVLST
;;; Output: 0 on success, ProDOS error code on failure
;;;
;;; NOTE: Called from Initializer (init) which resides in $800-$1200

        cvi_data_buffer := $800

        DEFINE_ON_LINE_PARAMS on_line_params,, cvi_data_buffer

.proc CreateVolumeIcon
        kMaxIconWidth = 53
        kMaxIconHeight = 15

        sta     unit_number
        sty     devlst_index
        and     #UNIT_NUM_MASK
        sta     on_line_params::unit_num
        MLI_RELAY_CALL ON_LINE, on_line_params
        beq     success

error:  pha                     ; save error
        ldy     devlst_index      ; remove unit from list
        lda     #0
        sta     device_to_icon_map,y
        dec     cached_window_entry_count
        dec     icon_count
        pla
        rts

success:
        lda     cvi_data_buffer ; dr/slot/name_len
        and     #NAME_LENGTH_MASK
        sta     cvi_data_buffer
        bne     :+
        lda     cvi_data_buffer+1 ; if name len is zero, second byte is error
        jmp     error
:

        jsr     CompareNames
        bne     error

        icon_ptr := $6
        icon_defn_ptr := $8

        jsr     PushPointers
        jsr     AllocateIcon
        ldy     devlst_index
        sta     device_to_icon_map,y
        jsr     IconEntryLookup
        stax    icon_ptr

        ;; Copy name
        param_call AdjustVolumeNameCase, cvi_data_buffer

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

        ;; NOTE: Done with `cvi_data_buffer` at this point,
        ;; so $800 is free.

        ;; ----------------------------------------

        ;; Figure out icon
        unit_number := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     GetDeviceType   ; uses $800 as DIB buffer
        tya                     ; Y = kDeviceType constant
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

        ;; Assign icon flags
        ldy     #IconEntry::win_flags
        lda     #kIconEntryFlagsDropTarget
        sta     (icon_ptr),y

        ;; Invalid record
        ldy     #IconEntry::record_num
        lda     #$FF
        sta     (icon_ptr),y

        ;; Assign icon coordinates
        devlst_index := *+1
        ldy     #SELF_MODIFIED_BYTE
        lda     device_to_icon_map,y
        jsr     AllocDesktopIconPosition
        txa
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
        ldx     cached_window_entry_count
        dex
        ldy     #IconEntry::id
        lda     (icon_ptr),y
        sta     cached_window_entry_list,x
        jsr     PopPointers
        return  #0

offset:         .word   0

;;; Compare a volume name against existing volume icons for drives.
;;; Inputs: String to compare against is in `cvi_data_buffer`
;;; Output: A=0 if not a duplicate, ERR_DUPLICATE_VOLUME if there is a duplicate.
;;; Assert: `cached_window_entry_count` is one greater than actual count
.proc CompareNames

        string := cvi_data_buffer
        icon_ptr := $06

        jsr     PushPointers
        ldx     cached_window_entry_count
        dex
        stx     index

        index := *+1
loop:   ldx     #SELF_MODIFIED_BYTE
        lda     cached_window_entry_list,x
        cmp     trash_icon_num
        beq     next
        jsr     IconEntryLookup
        stax    icon_ptr
        add16_8 icon_ptr, #IconEntry::name

        ;; Lengths match?
        ldy     #0
        lda     (icon_ptr),y
        cmp     string
        bne     next

        tay
cloop:  lda     (icon_ptr),y
        jsr     UpcaseChar
        sta     @char
        lda     string,y
        jsr     UpcaseChar
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     next
        dey
        bne     cloop

        ;; It matches; report a duplicate.
        jsr     PopPointers
        lda     #ERR_DUPLICATE_VOLUME
        rts

        ;; Doesn't match, try again
next:   dec     index
        bpl     loop

        ;; All done, clean up and report no duplicates.
        jsr     PopPointers
        lda     #0
        rts
.endproc


.endproc

;;; ============================================================
;;; Allocate/Free an icon position on the DeskTop. The position
;;; is used as an index into `desktop_icon_coords_table` to place
;;; icons; `desktop_icon_usage_table` tracks used/free slots.

;;; Input: A = icon num
;;; Output: X = index into `desktop_icon_coords_table` to use
.proc AllocDesktopIconPosition
        pha

        ldx     #0
:       lda     desktop_icon_usage_table,x
        beq     :+
        inx
        bne     :-              ; always

:       pla
        sta     desktop_icon_usage_table,x
        rts
.endproc

;;; Input: A = icon num
.proc FreeDesktopIconPosition
        ldx     #kMaxVolumes-1
:       dex
        cmp     desktop_icon_usage_table,x
        bne     :-
        lda     #0
        sta     desktop_icon_usage_table,x
        rts
.endproc

;;; ============================================================

.proc RemoveIconFromWindow
        ldx     cached_window_entry_count
        dex
:       cmp     cached_window_entry_list,x
        beq     remove
        dex
        bpl     :-
        rts

remove: lda     cached_window_entry_list+1,x
        sta     cached_window_entry_list,x
        inx
        cpx     cached_window_entry_count
        bne     remove
        dec     cached_window_entry_count
        ldx     cached_window_entry_count
        lda     #0
        sta     cached_window_entry_list,x
        rts
.endproc

;;; ============================================================
;;; Search the window->dir_icon mapping table.
;;; Inputs: A = icon number
;;; Outputs: Z=1 && N=0 if found, X = index (0-7), A unchanged

.proc FindWindowIndexForDirIcon
        ldx     #kMaxNumWindows-1
:       cmp     window_to_dir_icon_table,x
        beq     done
        dex
        bpl     :-
done:   rts
.endproc

;;; ============================================================
;;; Used when recovering from a failed open (bad path, too many icons, etc)
;;; Inputs: `icon_param` points at icon
;;; Assert: If windowed, icon is in the active window.

.proc MarkIconNotOpened
        ptr := $6

        ;; Primary entry point.
        jsr     PushPointers
        jmp     start

        ;; This entry point removes filerecords associated with window
remove_filerecords:
        lda     icon_param
        beq     ret

        jsr     PushPointers
        lda     icon_param
        jsr     FindWindowIndexForDirIcon ; X = window id-1 if found
    IF_EQ
        inx
        txa
        jsr     RemoveWindowFilerecordEntries
    END_IF
        ;; fall through

        ;; Find open window for the icon
start:  lda     icon_param
        jsr     FindWindowIndexForDirIcon ; X = window id-1 if found
    IF_EQ
        ;; If found, remove from the table.
        ;; Note: 0 not $FF because we know the window doesn't exist
        ;; any more.
        copy    #0, window_to_dir_icon_table,x
    END_IF
        ;; Update the icon and redraw
        lda     icon_param
        jsr     IconEntryLookup
        stax    ptr
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #AS_BYTE(~kIconEntryFlagsOpen) ; clear open_flag
        sta     (ptr),y

        lda     icon_param
        jsr     DrawIcon

        jsr     PopPointers

ret:    rts
.endproc
        remove_filerecords_and_mark_icon_not_opened := MarkIconNotOpened::remove_filerecords

;;; ============================================================

.proc AnimateWindow
        ptr := $06
        rect_table := $800

close:  ldy     #$80
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
open:   ldy     #$00
        sty     close_flag

        sta     icon_id
        txa                     ; A = window_id

        ;; Get window rect
        jsr     WindowLookup
        stax    ptr
        ldy     #MGTK::Winfo::port + .sizeof(MGTK::GrafPort)-1
        ldx     #.sizeof(MGTK::GrafPort)-1
:       lda     (ptr),y
        sta     window_grafport,x
        dey
        dex
        bpl     :-

        ;; Get icon position
        icon_id := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     IconEntryLookup
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

        ldy     #kMaxAnimationStep * .sizeof(MGTK::Rect) + 3
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
        step := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #10
        jne     L8C8C

        bit     close_flag
        bmi     :+
        jsr     AnimateWindowOpenImpl
        rts

:       jsr     AnimateWindowCloseImpl
        rts

close_flag:
        .byte   0

flag:   .byte   0               ; ???
flag2:  .byte   0               ; ???
L8D50:  .word   0
L8D52:  .word   0
L8D54:  .word   0
L8D56:  .word   0
.endproc
AnimateWindowClose      := AnimateWindow::close
AnimateWindowOpen       := AnimateWindow::open

;;; ============================================================

kMaxAnimationStep = 11

.proc AnimateWindowOpenImpl

        rect_table := $800

        ;; Loop N = 0 to 13
        ;; If N in 0..11, draw N
        ;; If N in 2..13, erase N-2 (i.e. 0..11, 2 behind)

        lda     #0
        sta     step
        jsr     ResetMainGrafport

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

        jsr     FrameTmpRect

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

        jsr     FrameTmpRect

next:   inc     step
        step := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #kMaxAnimationStep+3
        bne     loop
        rts
.endproc

;;; ============================================================

.proc AnimateWindowCloseImpl

        rect_table := $800

        ;; Loop N = 11 to -2
        ;; If N in 0..11, draw N
        ;; If N in -2..9, erase N+2 (0..11, i.e. 2 behind)

        lda     #kMaxAnimationStep
        sta     step
        jsr     ResetMainGrafport

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

        jsr     FrameTmpRect

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

        jsr     FrameTmpRect

next:   dec     step
        step := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #AS_BYTE(-3)
        bne     loop
        rts
.endproc

;;; ============================================================

.proc FrameTmpRect
        MGTK_RELAY_CALL MGTK::SetPattern, checkerboard_pattern
        jsr     SetPenModeXOR
        MGTK_RELAY_CALL MGTK::FrameRect, tmp_rect
        rts
.endproc

;;; ============================================================
;;; Dynamically load parts of Desktop2

;;; Call `LoadDynamicRoutine` or `RestoreDynamicRoutine`
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

.proc LoadDynamicRoutineImpl

kNumOverlays = 9

pos_table:
        .dword  kOverlayDiskCopy1Offset, kOverlayFormatEraseOffset
        .dword  kOverlaySelector1Offset, kOverlayFileDialogOffset
        .dword  kOverlayFileCopyOffset, kOverlayFileDeleteOffset
        .dword  kOverlaySelector2Offset, kOverlayDeskTopRestore1Offset
        .dword  kOverlayDeskTopRestore2Offset
        ASSERT_RECORD_TABLE_SIZE pos_table, kNumOverlays, 4

len_table:
        .word   kOverlayDiskCopy1Length, kOverlayFormatEraseLength
        .word   kOverlaySelector1Length, kOverlayFileDialogLength
        .word   kOverlayFileCopyLength, kOverlayFileDeleteLength
        .word   kOverlaySelector2Length, kOverlayDeskTopRestore1Length
        .word   kOverlayDeskTopRestore2Length
        ASSERT_RECORD_TABLE_SIZE len_table, kNumOverlays, 2

addr_table:
        .word   kOverlayDiskCopy1Address, kOverlayFormatEraseAddress
        .word   kOverlaySelector1Address, kOverlayFileDialogAddress
        .word   kOverlayFileCopyAddress, kOverlayFileDeleteAddress
        .word   kOverlaySelector2Address, kOverlayDeskTopRestore1Address
        .word   kOverlayDeskTopRestore2Address
        ASSERT_ADDRESS_TABLE_SIZE addr_table, kNumOverlays

        DEFINE_OPEN_PARAMS open_params, str_desktop2, IO_BUFFER

str_desktop2:
        PASCAL_STRING kFilenameDeskTop

        DEFINE_SET_MARK_PARAMS set_mark_params, 0

        DEFINE_READ_PARAMS read_params, 0, 0
        DEFINE_CLOSE_PARAMS close_params

        ;; Called with routine # in A

load:   pha
        copy    #AlertButtonOptions::OkCancel, button_options
        .assert AlertButtonOptions::OkCancel <> 0, error, "bne always assumption"
        bne     :+              ; always

restore:
        pha
        ;; Need to set low bit in this case to override the default.
        copy    #AlertButtonOptions::Ok|%00000001, button_options

:       jsr     SetCursorWatch ; before loading overlay
        pla
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

retry:  MLI_RELAY_CALL OPEN, open_params
        beq     :+

        lda     #kErrInsertSystemDisk
        button_options := *+1
        ldx     #SELF_MODIFIED_BYTE
        jsr     ShowAlertOption
        cmp     #kAlertResultOK
        beq     retry
        return  #$FF            ; failed

:       lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num
        MLI_RELAY_CALL SET_MARK, set_mark_params
        MLI_RELAY_CALL READ, read_params
        MLI_RELAY_CALL CLOSE, close_params
        jsr     SetCursorPointer ; after loading overlay
        rts

.endproc
LoadDynamicRoutine      := LoadDynamicRoutineImpl::load
RestoreDynamicRoutine   := LoadDynamicRoutineImpl::restore

;;; ============================================================

        .define LIB_MGTK_CALL MGTK_RELAY_CALL
        .define LIB_MLI_CALL MLI_RELAY_CALL
        .include "../lib/menuclock.s"
        .undefine LIB_MLI_CALL
        .undefine LIB_MGTK_CALL

;;; ============================================================

.proc SetRGBMode
        bit     SETTINGS + DeskTopSettings::rgb_color
        bmi     SetColorMode
        bpl     SetMonoMode
.endproc

.proc SetColorMode
        ;; IIgs?
        bit     machine_config::iigs_flag
        bmi     iigs

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
        bit     machine_config::lcm_eve_flag
        bpl     done
        sta     HR2_OFF
        sta     HR3_OFF
        bmi     done            ; always

        ;; Apple IIgs - DHR Color
iigs:   lda     NEWVIDEO
        and     #<~(1<<5)        ; Color
        sta     NEWVIDEO

done:   rts
.endproc

.proc SetMonoMode
        ;; IIgs?
        bit     machine_config::iigs_flag
        bmi     iigs

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
        bit     machine_config::lcm_eve_flag
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

;;; On IIgs, force preferred RGB mode. No-op otherwise.
.proc ResetIIgsRGB
        bit     machine_config::iigs_flag
        bpl     done            ; nope

        bit     SETTINGS + DeskTopSettings::rgb_color
        bmi     color

mono:   lda     NEWVIDEO
        ora     #(1<<5)         ; B&W
        sta     NEWVIDEO
        rts

color:  lda     NEWVIDEO
        and     #<~(1<<5)       ; Color
        sta     NEWVIDEO

done:   rts
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

.enum DeleteDialogLifecycle
        open            = 0
        count           = 1
        confirm         = 2     ; confirmation before deleting
        show            = 3
        locked          = 4     ; confirm deletion of locked file
        close           = 5
        trash           = 6     ; open, but from trash path ???
.endenum

;;; --------------------------------------------------

.scope operations

DoCopyFile:
        copy    #0, operation_flags ; copy/delete
        copy    #0, move_flag
        tsx
        stx     stack_stash

        jsr     PrepCallbacksForSizeOrCount
        jsr     DoCopyDialogPhase
        jsr     SizeOrCountProcessSelectedFile
        jsr     PrepCallbacksForCopy
        ;; fall through

DoCopyToRAM2:
        copy    #$FF, copy_run_flag
        copy    #0, move_flag
        copy    #0, delete_skip_decrement_flag
        jsr     copy_file_for_run
        jsr     InvokeOperationCompleteCallback
        ;; fall through

.proc FinishOperation
        return  #kOperationSucceeded
.endproc

DoDeleteFile:
        copy    #0, operation_flags ; copy/delete
        tsx
        stx     stack_stash
        jsr     PrepCallbacksForSizeOrCount
        lda     #DeleteDialogLifecycle::open
        jsr     DoDeleteDialogPhase
        jsr     SizeOrCountProcessSelectedFile
        jsr     InvokeOperationConfirmCallback
        jsr     PrepCallbacksForDelete
        jsr     DeleteProcessSelectedFile
        jsr     InvokeOperationCompleteCallback
        jmp     FinishOperation

DoCopyToRAM:
        copy    #$80, run_flag
        copy    #%11000000, operation_flags ; get size
        tsx
        stx     stack_stash
        jsr     PrepCallbacksForSizeOrCount
        jsr     DoDownloadDialogPhase
        jsr     SizeOrCountProcessSelectedFile
        jsr     PrepCallbacksForDownload
        jmp     DoCopyToRAM2

;;; --------------------------------------------------
;;; Lock

DoLock:
        jsr     L8FDD
        jmp     FinishOperation

DoUnlock:
        jsr     L8FE1
        jmp     FinishOperation

.proc GetIconEntryWinFlags
        asl     a
        tay
        copy16  icon_entry_address_table,y, $06
        ldy     #IconEntry::win_flags
        lda     ($06),y
        rts
.endproc

;;; --------------------------------------------------

.proc DoGetSize
        copy    #0, run_flag
        copy    #%11000000, operation_flags ; get size
        jmp     L8FEB
.endproc

.proc DoDrop
        lda     drag_drop_params::result
        cmp     trash_icon_num
        bne     :+
        lda     #$80
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
:       lda     #$00
        sta     delete_flag
        copy    #0, operation_flags ; copy/delete
        jmp     L8FEB
.endproc

        ;; common for lock/unlock
L8FDD:  lda     #$00            ; unlock
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
L8FE1:  lda     #$80            ; lock
        sta     unlock_flag
        copy    #%10000000, operation_flags ; lock/unlock
        ;; fall through

L8FEB:  tsx
        stx     stack_stash
        copy    #0, delete_skip_decrement_flag
        jsr     ResetMainGrafport
        lda     operation_flags
        jne     BeginOperation  ; copy/delete

        ;; Copy or delete
        bit     delete_flag
        bpl     compute_target_prefix ; copy

        ;; --------------------------------------------------
        ;; Delete - are selected icons volumes?
        lda     selected_window_id
        jne     BeginOperation ; no, just files

        ;; Yes - eject it!
        pla
        pla
        jmp     CmdEject

;;; --------------------------------------------------
;;; For drop onto window/icon, compute target prefix.

        ;; Is drop on a window or an icon?
        ;; hi bit clear = target is an icon
        ;; hi bit set = target is a window; get window number
compute_target_prefix:
        lda     drag_drop_params::result
        bpl     target_is_icon

        ;; Drop is on a window
        and     #%01111111      ; get window id
        jsr     GetWindowPath
        stax    $08
        copy16  #str_empty, $06
        jsr     JoinPaths
        dec     path_buf3       ; remove trailing '/'
        jmp     common

        ;; Drop is on an icon.
target_is_icon:
        jsr     GetIconPath   ; `path_buf3` set to path

common:
        ldy     path_buf3
:       copy    path_buf3,y, path_buf4,y
        dey
        bpl     :-
        ;; fall through

;;; --------------------------------------------------
;;; Start the actual operation

.proc BeginOperation
        copy    #0, do_op_flag

        jsr     PrepCallbacksForSizeOrCount
        bit     operation_flags
        bvs     @size
        bmi     @lock
        bit     delete_flag
        bmi     @trash

        ;; Copy or Move - compare src/dst paths (etc)
        lda     selected_window_id
        jsr     GetWindowPath
        stax    $08
        jsr     CheckMoveOrCopy
        sta     move_flag
        jsr     DoCopyDialogPhase
        jmp     iterate_selection

@trash: lda     #DeleteDialogLifecycle::trash
        jsr     DoDeleteDialogPhase
        jmp     iterate_selection

@lock:  jsr     DoLockDialogPhase
        jmp     iterate_selection

@size:  jsr     DoGetSizeDialogPhase
        jmp     iterate_selection

;;; Perform operation

perform:
        bit     operation_flags
        bvs     @size
        bmi     @lock
        bit     delete_flag
        bmi     @trash
        jsr     PrepCallbacksForCopy
        jmp     iterate_selection

@trash: jsr     PrepCallbacksForDelete
        jmp     iterate_selection

@lock:  jsr     PrepCallbacksForLock
        jmp     iterate_selection

@size:  jsr     get_size_rts2           ; no-op ???
        jmp     iterate_selection

iterate_selection:
        lda     selected_icon_count
        jeq     finish

        ldx     #0
        stx     icon_count

        icon_count := *+1
loop:   ldx     #SELF_MODIFIED_BYTE
        lda     selected_icon_list,x
        cmp     trash_icon_num
        beq     next_icon
        jsr     GetIconPath

        lda     do_op_flag
        beq     just_size_and_count

        bit     operation_flags
        bmi     @lock_or_size
        bit     delete_flag
        bmi     :+

        jsr     CopyProcessSelectedFile
        bit     move_flag
        bpl     next_icon
        jsr     UpdateWindowPaths
        jsr     UpdatePrefix
        jmp     next_icon

:       jsr     DeleteProcessSelectedFile
        jmp     next_icon

@lock_or_size:
        bvs     @size           ; size?
        jsr     LockProcessSelectedFile
        jmp     next_icon

@size:  jsr     SizeOrCountProcessSelectedFile
        jmp     next_icon

just_size_and_count:
        ;; Just enumerate files...
        bit     operation_flags
        bmi     :+
        bit     delete_flag
        bmi     :+

        ;; But if copying, validate the target.
        jsr     CopyPathsFromBufsToSrcAndDst
        jsr     CheckRecursion
        jne     ShowErrorAlert
        jsr     AppendSrcPathLastSegmentToDstPath
        jsr     CheckBadReplacement
        jne     ShowErrorAlert

:       jsr     SizeOrCountProcessSelectedFile

next_icon:
        inc     icon_count
        ldx     icon_count
        cpx     selected_icon_count
        bne     loop

        lda     do_op_flag
        bne     finish
        inc     do_op_flag
        bit     operation_flags
        bmi     @lock_or_size
        bit     delete_flag
        bpl     not_trash

@lock_or_size:
        jsr     InvokeOperationConfirmCallback
        bit     operation_flags
        bvs     finish
not_trash:
        jmp     perform

finish: jsr     InvokeOperationCompleteCallback
        return  #0
.endproc

.endscope ; operations
        DoDeleteFile := operations::DoDeleteFile
        DoCopyToRAM := operations::DoCopyToRAM
        DoCopyFile := operations::DoCopyFile
        DoLock := operations::DoLock
        DoUnlock := operations::DoUnlock
        DoGetSize := operations::DoGetSize
        DoDrop := operations::DoDrop

;;; ============================================================

;;; Called for each file during enumeration; A,X = file count
InvokeOperationEnumerationCallback:
        operation_enumeration_callback := *+1
        jmp     SELF_MODIFIED

;;; Called on operation completion (success or failure)
InvokeOperationCompleteCallback:
        operation_complete_callback := *+1
        jmp     SELF_MODIFIED

;;; Called once enumeration is complete, to confirm the operation.
InvokeOperationConfirmCallback:
        operation_confirm_callback := *+1
        jmp     SELF_MODIFIED

;;; Called when there are not enough free blocks on destination.
InvokeOperationTooLargeCallback:
        operation_toolarge_callback := *+1
        jmp     SELF_MODIFIED

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

        ;; high bit set = from Selector > Run command
        ;; high bit clear = Get Size
run_flag:
        .byte   0

all_flag:
        .byte   0

;;; ============================================================
;;; Input: A = icon
;;; Output: $06 = icon name ptr

.proc IconEntryNameLookup
        asl     a
        tay
        add16   icon_entry_address_table,y, #IconEntry::name, $06
        rts
.endproc

;;; ============================================================
;;; Concatenate paths.
;;; Inputs: Base path in $08, second path in $06
;;; Output: `path_buf3`

.proc JoinPaths
        str1 := $8
        str2 := $6
        buf  := path_buf3

        ldx     #0

        lda     str1            ; check for nullptr (volume)
        ora     str1+1
        beq     do_str2

        ldy     #0              ; check for empty string
        lda     (str1),y
        beq     do_str2

        ;; Copy $8 (str1)
        sta     @len
:       iny
        inx
        lda     (str1),y
        sta     buf,x
        @len := *+1
        cpy     #SELF_MODIFIED_BYTE
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
        cpy     #SELF_MODIFIED_BYTE
        bne     :-

done:   stx     buf
        rts
.endproc

;;; ============================================================

.proc DoEject
        lda     selected_icon_count
        beq     ret

        ldx     selected_icon_count
        stx     $800
        dex
:       lda     selected_icon_list,x
        sta     $0801,x
        dex
        bpl     :-

        jsr     ClearSelection
        ldx     #0
        stx     index
        index := *+1
loop:   ldx     #SELF_MODIFIED_BYTE
        lda     $0801,x
        cmp     #$01
        beq     :+
        jsr     SmartportEject
:       inc     index
        ldx     index
        cpx     $800
        bne     loop

ret:    rts
.endproc

;;; ============================================================

.proc SmartportEject
        ptr := $6

        ;; Look up device index by icon number
        sta     @compare
        ldy     #0

:       lda     device_to_icon_map,y

        @compare := *+1
        cmp     #SELF_MODIFIED_BYTE

        beq     found
        cpy     DEVCNT
        beq     exit
        iny
        bne     :-
exit:   rts

found:  lda     DEVLST,y        ; unit_number

        ;; Compute SmartPort dispatch address
        smartport_addr := $0A
        jsr     FindSmartportDispatchAddress
        bne     done            ; not SP
        stx     control_unit_number

        ;; Execute SmartPort call
        jsr     SmartportCall
        .byte   SPCall::Control
        .addr   control_params
done:   rts

SmartportCall:
        jmp     (smartport_addr)

.params control_params
param_count:    .byte   3
unit_number:    .byte   0
control_list:   .addr   list
control_code:   .byte   $04     ; For Apple/UniDisk 3.3: Eject disk
.endparams
        control_unit_number := control_params::unit_number
list:   .word   0               ; 0 items in list
.endproc

;;; ============================================================
;;; "Get Info" dialog state and logic
;;; ============================================================

        DEFINE_READ_BLOCK_PARAMS block_params, $800, $A

.params get_info_dialog_params
state:  .byte   0
a_path: .addr   0               ; e.g. string address
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

        .include "../lib/smartport.s"

;;; ============================================================
;;; Get Info

.proc DoGetInfo
        path_buf := INVOKER_PREFIX
        ptr := $6

        lda     selected_icon_count
        bne     :+
        rts

:       copy    #0, get_info_dialog_params::index
        jsr     ResetMainGrafport
loop:   ldx     get_info_dialog_params::index
        cpx     selected_icon_count
        jeq     done

        ldx     get_info_dialog_params::index
        lda     selected_icon_list,x
        cmp     trash_icon_num
        jeq     next

        jsr     GetIconPath   ; `path_buf3` is full path

        ldy     path_buf3       ; Copy to `path_buf`
:       copy    path_buf3,y, path_buf,y
        dey
        bpl     :-

        ;; Try to get file info
common: MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        jsr     ShowErrorAlert
        beq     common
:
        lda     selected_window_id
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
:       jsr     RunGetInfoDialogProc
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
:       jsr     RunGetInfoDialogProc
        copy    #0, write_protected_flag
        ldx     get_info_dialog_params::index
        lda     selected_icon_list,x

        ;; Map icon to unit number
        ldy     #kMaxVolumes

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
        jsr     IconEntryNameLookup

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
        copy16  #text_buffer2::length, get_info_dialog_params::a_path
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------
        ;; Locked/Protected
        copy    #GetInfoDialogState::locked, get_info_dialog_params::state
        lda     selected_window_id
        bne     is_file

        bit     write_protected_flag ; Volume
        bmi     is_protected
        bpl     not_protected

is_file:
        lda     get_file_info_params::access ; File
        and     #ACCESS_DEFAULT
        cmp     #ACCESS_DEFAULT
        beq     not_protected

is_protected:
        copy16  #aux::yes_button_label, get_info_dialog_params::a_path
        bne     show_protected           ; always
not_protected:
        copy16  #aux::no_button_label, get_info_dialog_params::a_path
show_protected:
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------
        ;; Size/Blocks
        copy    #GetInfoDialogState::size, get_info_dialog_params::state

        ;; Compose " 12345K" or " 12345K / 67890K" string
        buf := INVOKER_PREFIX
        copy    #0, buf

        lda     selected_window_id ; volume?
        beq     volume                ; yes

        ;; A file, so just show the size
        ldax    get_file_info_params::blocks_used
        jmp     append_size

        ;; A volume.
volume:
        ;; ProDOS TRM 4.4.5:
        ;; "When file information about a volume directory is requested, the
        ;; total number of blocks on the volume is returned in the aux_type
        ;; field and the total blocks for all files is returned in blocks_used.

        ldax    get_file_info_params::blocks_used
        jsr     ComposeSizeString

        ;; text_buffer2 now has " 12345K" (used space)

        ;; Copy into buf
        ldx     buf
        ldy     #0
:       inx
        lda     text_buffer2::data,y
        sta     buf,x
        iny
        cpy     text_buffer2::length
        bne     :-

        ;; Append ' /' to buf
        inx
        lda     #' '
        sta     buf,x
        inx
        lda     #'/'
        sta     buf,x
        stx     buf

        ;; Load up the total volume size...
        ldax    get_file_info_params::aux_type

        ;; Compute " 12345K" (either volume size or file size)
append_size:
        jsr     ComposeSizeString

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

        ;; TODO: Compose directly into `path_buf4`.
        COPY_STRING buf, path_buf4

        copy16  #path_buf4, get_info_dialog_params::a_path
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------
        ;; Created date
        copy    #GetInfoDialogState::created, get_info_dialog_params::state
        COPY_STRUCT DateTime, get_file_info_params::create_date, datetime_for_conversion
        jsr     ComposeDateString
        copy16  #text_buffer2::length, get_info_dialog_params::a_path
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------
        ;; Modified date
        copy    #GetInfoDialogState::modified, get_info_dialog_params::state
        COPY_STRUCT DateTime, get_file_info_params::mod_date, datetime_for_conversion
        jsr     ComposeDateString
        copy16  #text_buffer2::length, get_info_dialog_params::a_path
        jsr     RunGetInfoDialogProc


        ;; --------------------------------------------------
        ;; Type
        copy    #GetInfoDialogState::type, get_info_dialog_params::state
        lda     selected_window_id
        bne     :+

        ;; Volume
        COPY_STRING str_vol, text_buffer2::length
        jmp     show_type

        ;; File
:       lda     get_file_info_params::file_type
        jsr     ComposeFileTypeString
        COPY_STRING str_file_type, text_buffer2::length
        ldax    get_file_info_params::aux_type
        jsr     AppendAuxType

show_type:
        copy16  #text_buffer2::length, get_info_dialog_params::a_path
        jsr     RunGetInfoDialogProc
        bne     done

next:   inc     get_info_dialog_params::index
        jmp     loop

done:   copy    #0, path_buf4
        rts

write_protected_flag:
        .byte   0

str_vol:
        PASCAL_STRING res_string_volume

.proc RunGetInfoDialogProc
        param_call invoke_dialog_proc, kIndexGetInfoDialog, get_info_dialog_params
        rts
.endproc
.endproc

;;; ============================================================

.enum RenameDialogState
        open  = $00
        run   = $80
        close = $40
.endenum

        old_name_buf := $1F00
        new_name_buf := $1F10

        DEFINE_RENAME_PARAMS rename_params, src_path_buf, dst_path_buf

.params rename_dialog_params
state:  .byte   0
a_path: .addr   old_name_buf
.endparams

.proc DoRenameImpl

start:
        lda     #0
        sta     index
        sta     result_flags

        ;; Loop over all selected icons
        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     selected_icon_count
        bne     :+
        return  result_flags

:       ldx     index
        lda     selected_icon_list,x
        cmp     trash_icon_num  ; Skip trash
        bne     :+
        inc     index
        jmp     loop
:
        jsr     GetIconPath

        ldax    #path_buf3
        jsr     CopyToSrcPath

        ldx     index
        lda     selected_icon_list,x
        jsr     IconEntryNameLookup

        param_call CopyPtr1ToBuf, old_name_buf

        ;; Open the dialog
        lda     #RenameDialogState::open
        jsr     RunDialogProc

        ;; Run the dialog
retry:  lda     #RenameDialogState::run
        jsr     RunDialogProc
        beq     ok

        ;; Failure
fail:   return  result_flags

        ;; --------------------------------------------------
        ;; Success, new name in Y,X

ok:
        new_name_ptr := $08
        sty     new_name_ptr
        stx     new_name_ptr+1

        ;; Copy the name somewhere LCBANK-safe
        ;; Since we can't preserve casing, just upcase it for now.
        ;; See: https://github.com/a2stuff/a2d/issues/352
        ldy     #0
        lda     (new_name_ptr),y
        tay
:       lda     (new_name_ptr),y
        jsr     UpcaseChar
        sta     new_name_buf,y
        dey
        bpl     :-

        ;; Did the name change?
        ldx     old_name_buf
        cpx     new_name_buf
        bne     changed
:       lda     old_name_buf,x
        jsr     UpcaseChar
        sta     @char
        lda     new_name_buf,x
        jsr     UpcaseChar
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     changed
        dex
        bne     :-
        ;; Didn't change, no-op
        lda     #RenameDialogState::close
        jsr     RunDialogProc
        inc     index
        jmp     loop

changed:

        ;; ... then recase it, so we're consistent for icons/paths.
        ldax    #new_name_buf
        jsr     AdjustFileNameCase

        ;; File or Volume?
        lda     selected_window_id
    IF_NOT_ZERO
        jsr     GetWindowPath
    ELSE
        ldax    #str_empty
    END_IF

        ;; Copy window path as prefix
        jsr     CopyToDstPath

        ;; Append new filename
        ldax    #new_name_buf
        jsr     AppendFilenameToDstPath

        ;; Already exists? (Mostly for volumes, but works for files as well)
        MLI_RELAY_CALL GET_FILE_INFO, dst_file_info_params
        bne     :+
        lda     #ERR_DUPLICATE_FILENAME
        jsr     ShowAlert
        jmp     retry

        ;; Try to rename
:       MLI_RELAY_CALL RENAME, rename_params
        beq     finish

        ;; Failed, maybe retry
        jsr     ShowAlert       ; Alert options depend on specific ProDOS error
        jeq     retry           ; `kAlertResultTryAgain` = 0
        lda     #RenameDialogState::close
        jsr     RunDialogProc
        jmp     fail

        ;; --------------------------------------------------
        ;; Completed - tear down the dialog...
finish: lda     #RenameDialogState::close
        jsr     RunDialogProc

        ldx     index
        lda     selected_icon_list,x
        sta     icon_param

        jsr     ResetMainGrafport ; assumed for volume icons

        ;; Erase the icon, in case new name is shorter
.scope
        lda     selected_window_id
        beq     :+
        ;; NOTE: EraseIcon operates with icons in screen space (?!?)
        ;; so no need to call `IconScreenToWindow` here
        lda     selected_window_id
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        bne     skip            ; MGTK::Error::window_obscured
:       ITK_RELAY_CALL IconTK::EraseIcon, icon_param ; CHECKED
skip:   lda     selected_window_id
        beq     :+
        ;; NOTE: EraseIcon operates with icons in screen space (?!?)
        ;; so no need to call `IconWindowToScreen` here
        jsr     ResetMainGrafport
:
.endscope

        ;; Copy new string in
        icon_name_ptr := $06
        ldx     index
        lda     selected_icon_list,x
        jsr     IconEntryNameLookup ; $06 = icon name ptr
        ldy     new_name_buf
:       lda     new_name_buf,y
        sta     (icon_name_ptr),y
        dey
        bpl     :-

        lda     icon_param
        jsr     DrawIcon

        ;; If not volume, find and update associated FileEntry
        lda     selected_window_id
    IF_NOT_ZERO
        ;; Dig up the index of the icon within the window.
        icon_ptr := $06
        lda     icon_param
        jsr     IconEntryLookup
        stax    icon_ptr
        ldy     #IconEntry::record_num
        lda     (icon_ptr),y
        pha                     ; A = index of icon in window

        ;; Find the window's FileRecord list.
        file_record_ptr := $06
        lda     selected_window_id
        jsr     FindIndexInFilerecordListEntries ; Assert: must be found
        txa
        asl
        tax
        copy16  window_filerecord_table,x, file_record_ptr ; points at head of list (entry count)
        inc16   file_record_ptr ; now points at first FileRecord in list

        ;; Look up the FileRecord within the list.
        pla                     ; A = index
        .assert .sizeof(FileRecord) = 32, error, "FileRecord size must be 2^5"
        jsr     ATimes32      ; A,X = index * 32
        addax   file_record_ptr, file_record_ptr

        ;; Bank in FileRecords, and copy the new name in.
        bit     LCBANK2
        bit     LCBANK2
        .assert FileRecord::name = 0, error, "Name must be at start of FileRecord"
        ldy     new_name_buf
:       lda     new_name_buf,y
        sta     (file_record_ptr),y
        dey
        bpl     :-

        ;; Note if it's a SYS file
        ldy     #FileRecord::file_type
        lda     (file_record_ptr),y
        cmp     #FT_SYSTEM
        bne     :+
        lda     result_flags
        ora     #$40
        sta     result_flags
:

        bit     LCBANK1
        bit     LCBANK1
    END_IF

        ;; Is there a window for the folder/volume?
        param_call FindWindowForPath, src_path_buf
    IF_NOT_ZERO
        dst := $06
        ;; Update the window title
        jsr     GetWindowTitlePath
        stax    dst
        ldy     new_name_buf
:       lda     new_name_buf,y
        sta     (dst),y
        dey
        bpl     :-

        lda     result_flags
        ora     #$80
        sta     result_flags
    END_IF

        ;; Update affected window paths, ProDOS prefix
        jsr     UpdateWindowPaths
        jsr     UpdatePrefix

        ;; --------------------------------------------------
        ;; Totally done - advance to next selected icon
        inc     index
        jmp     loop

.proc RunDialogProc
        sta     rename_dialog_params
        param_call invoke_dialog_proc, kIndexRenameDialog, rename_dialog_params
        rts
.endproc

;;; N bit ($80) set if a window title was changed
;;; V bit ($40) set if a SYS file was renamed
result_flags:
        .byte   0
.endproc
DoRename        := DoRenameImpl::start

;;; ============================================================
;;; Following a rename or move of `src_path_buf` to `dst_path_buf`,
;;; update any affected window paths.
;;;
;;; Uses `FindWindowsForPrefix`
;;; Modifies $06
;;; Assert: The path actually changed.

.proc UpdateWindowPaths
        ;; Is there a window for the folder/volume?
        param_call FindWindowForPath, src_path_buf
    IF_NOT_ZERO
        dst := $06
        ;; Update the path
        jsr     GetWindowPath
        stax    dst
        lda     dst_path_buf
        tay
:       lda     dst_path_buf,y
        sta     (dst),y
        dey
        bpl     :-
    END_IF

        ;; Update paths for any child windows.
        ldy     src_path_buf    ; Y = length
        param_call FindWindowsForPrefix, src_path_buf
        lda     found_windows_count
    IF_NOT_ZERO
        dst := $06

        dec     found_windows_count
wloop:  ldx     found_windows_count
        lda     found_windows_list,x
        jsr     GetWindowPath
        stax    dst

        jsr     UpdateTargetPath

        dec     found_windows_count
        bpl     wloop
    END_IF

        rts
.endproc

;;; ============================================================
;;; Replace `src_path_buf` as the prefix of path at $06 with `dst_path_buf`.
;;; Assert: `src_path_buf` is a prefix of the path at $06!
;;; Inputs: $06 = path to update, `src_path_buf` and `dst_path_buf`,
;;; Outputs: Path at $06 updated.
;;; Modifies `path_buf1` and `path_buf2`

.proc UpdateTargetPath
        dst := $06

        ;; Set `path_buf1` to the old path (should be `src_path_buf` + suffix)
        param_call CopyPtr1ToBuf, path_buf1

        ;; Set `path_buf2` to the new prefix
        ldy     dst_path_buf
:       lda     dst_path_buf,y
        sta     path_buf2,y
        dey
        bpl     :-

        ;; Copy the suffix from `path_buf1` to `path_buf2`
        ldx     src_path_buf
        cpx     path_buf1
        beq     assign          ; paths are equal, no copying needed

        ldy     dst_path_buf
:       inx                     ; advance into suffix
        iny
        lda     path_buf1,x
        sta     path_buf2,y
        cpx     path_buf1
        bne     :-
        sty     path_buf2

        ;; Assign the new window path
assign: ldy     path_buf2
:       lda     path_buf2,y
        sta     (dst),y
        dey
        bpl     :-

        rts
.endproc

;;; ============================================================
;;; Following a rename or move of `src_path_buf` to `dst_path_buf`,
;;; update the target path if needed.
;;;
;;; Inputs: $06 = pointer to path to update
;;; Outputs: Path at $06 updated, Z=1 if updated, Z=0 if no change

.proc MaybeUpdateTargetPath
        ptr := $06

        ;; Did path end with a '/'? If so, set flag and remove.
        ldy     #0
        sty     slash_flag
        lda     (ptr),y
        tay                     ; Y=target path length
        lda     (ptr),y
        cmp     #'/'
        bne     :+
        sta     slash_flag      ; need to restore it later, but
        ldy     #0              ; remove the '/' for now
        lda     (ptr),y
        sec
        sbc     #1
        sta     (ptr),y
        tay                     ; Y=updated target path length
:
        ;; Is `src_path_buf` a prefix?
        cpy     src_path_buf
        bcc     no_change       ; string is shorter, can't be a prefix
        beq     :+              ; same length, maybe a prefix
        iny                     ; string is longer, but still need to ensure
        lda     (ptr),y         ; that the next path char is a '/'
        cmp     #'/'
        bne     no_change       ; nope, so can't be a prefix
:
        ;; Compare strings
        ldy     src_path_buf
:       lda     (ptr),y
        jsr     UpcaseChar
        sta     @char
        lda     src_path_buf,y
        jsr     UpcaseChar
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     no_change
        dey
        bne     :-

        ;; It's a prefix! Do the replacement
        jsr     UpdateTargetPath

        ;; Restore trailing '/' if needed
        slash_flag := *+1       ; non-zero if trailing slash needed
        lda     #SELF_MODIFIED_BYTE
        beq     :+
        ldy     #0
        lda     (ptr),y
        clc
        adc     #1
        sta     (ptr),y
        tay
        lda     #'/'
        sta     (ptr),y
:
        return  #0

no_change:
        return  #$FF
.endproc

;;; ============================================================

.proc UpdatePrefix
        ptr := $06
        path := path_buffer

        ;; ProDOS Prefix
        MLI_RELAY_CALL GET_PREFIX, get_set_prefix_params
        copy16  #path, ptr
        jsr     MaybeUpdateTargetPath
    IF_EQ
        MLI_RELAY_CALL SET_PREFIX, get_set_prefix_params
    END_IF

        ;; Original Prefix
        jsr     GetCopiedToRAMCardFlag
    IF_MINUS
        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2
        copy16  #DESKTOP_ORIG_PREFIX, ptr
        jsr     MaybeUpdateTargetPath
        copy16  #RAMCARD_PREFIX, ptr
        jsr     MaybeUpdateTargetPath
        copy16  #SELECTOR + QuitRoutine::prefix_buffer_offset, ptr
        jsr     MaybeUpdateTargetPath
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1
    END_IF

        ;; Restart Prefix
        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2
        copy16  #SELECTOR + QuitRoutine::prefix_buffer_offset, ptr
        jsr     MaybeUpdateTargetPath
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        rts

        DEFINE_GET_PREFIX_PARAMS get_set_prefix_params, path
.endproc

;;; ============================================================

.enum DuplicateDialogState
        open  = $00
        run   = $80
        close = $40
.endenum

.params duplicate_dialog_params
state:  .byte   0
a_path: .addr   old_name_buf
.endparams

.proc DoDuplicateImpl

start:
        lda     #0
        sta     index
        sta     result_flag

        ;; Verify selection is files (menu item shouldn't be enabled, though)
        lda     selected_window_id
        bne     :+
        return  result_flag
:
        ;; Loop over all selected icons
        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     selected_icon_count
        bne     :+
        return  result_flag
:
        ;; Compose full path
        ldx     index
        lda     selected_icon_list,x
        jsr     GetIconPath   ; populates `path_buf3`

        ldax    #path_buf3
        jsr     CopyToSrcPath

        ldx     index
        lda     selected_icon_list,x
        jsr     IconEntryNameLookup

        ;; Copy name for display/default
        param_call CopyPtr1ToBuf, old_name_buf

        ;; Open the dialog
        lda     #DuplicateDialogState::open
        jsr     RunDialogProc

        ;; Run the dialog
retry:  lda     #DuplicateDialogState::run
        jsr     RunDialogProc
        beq     success

        ;; Failure
fail:   return  result_flag

        ;; --------------------------------------------------
        ;; Success, new name in Y,X

success:
        new_name_ptr := $08
        sty     new_name_ptr
        stx     new_name_ptr+1

        lda     selected_window_id
        jsr     GetWindowPath
        jsr     CopyToDstPath

        ;; Append new filename
        ldax    new_name_ptr
        jsr     AppendFilenameToDstPath

        ;; --------------------------------------------------
        ;; Check for unchanged/duplicate name

        MLI_RELAY_CALL GET_FILE_INFO, dst_file_info_params
    IF_ZERO
        lda     #ERR_DUPLICATE_FILENAME
        jsr     ShowAlert
        jmp     retry
    END_IF

        ;; Close the dialog
        lda     #DuplicateDialogState::close
        jsr     RunDialogProc

        ;; --------------------------------------------------
        ;; Try copying the file

        copy16  #src_path_buf, $06
        copy16  #dst_path_buf, $08
        jsr     CopyPathsFromPtrsToBufsAndSplitName
        jsr     DoCopyFile
        bmi     :+
        lda     #$80
        sta     result_flag
:

        ;; --------------------------------------------------
        ;; Totally done - advance to next selected icon
        inc     index
        jmp     loop

.proc RunDialogProc
        sta     duplicate_dialog_params
        param_call invoke_dialog_proc, kIndexDuplicateDialog, duplicate_dialog_params
        rts
.endproc

;;; N bit ($80) set if anything succeeded (and window needs refreshing)
result_flag:
        .byte   0
.endproc
DoDuplicate     := DoDuplicateImpl::start

;;; ============================================================

;;; Memory Map
;;; ...
;;; $1F80 - $1FFF   - dst path buffer
;;; $1500 - $1F7F   - file data buffer
;;; $1100 - $14FF   - dst file I/O buffer
;;; $0D00 - $10FF   - src file I/O buffer
;;; $0C00 - $0CFF   - dir data buffer
;;; $0800 - $0BFF   - src dir I/O buffer
;;; ...

        ;; 4 bytes is .sizeof(SubdirectoryHeader) - .sizeof(FileEntry)
        .define kBlockPointersSize 4
        .assert .sizeof(SubdirectoryHeader) - .sizeof(FileEntry) = kBlockPointersSize, error, "bad structs"

        ;; Blocks are 512 bytes, 13 entries of 39 bytes each leaves 5 bytes between.
        ;; Except first block, directory header is 39+4 bytes, leaving 1 byte, but then
        ;; block pointers are the next 4.
        .define kMaxPaddingBytes 5

        PARAM_BLOCK dir_data, $C00
buf_block_pointers      .res    kBlockPointersSize
buf_padding_bytes       .res    kMaxPaddingBytes
file_entry_buf          .res    .sizeof(FileEntry)
        END_PARAM_BLOCK
        file_entry_buf := dir_data::file_entry_buf

        DEFINE_OPEN_PARAMS open_src_dir_params, src_path_buf, $800
        DEFINE_READ_PARAMS read_block_pointers_params, dir_data::buf_block_pointers, kBlockPointersSize ; For skipping prev/next pointers in directory data

        DEFINE_CLOSE_PARAMS close_src_dir_params

        DEFINE_READ_PARAMS read_src_dir_entry_params, file_entry_buf, .sizeof(FileEntry)

        DEFINE_READ_PARAMS read_padding_bytes_params, dir_data::buf_padding_bytes, kMaxPaddingBytes

        file_data_buffer := $1500
        kBufSize = $A80
        .assert file_data_buffer + kBufSize <= dst_path_buf, error, "Buffer overlap"

        DEFINE_CLOSE_PARAMS close_src_params
        DEFINE_CLOSE_PARAMS close_dst_params
        DEFINE_DESTROY_PARAMS destroy_params, src_path_buf
        DEFINE_OPEN_PARAMS open_src_params, src_path_buf, $0D00
        DEFINE_OPEN_PARAMS open_dst_params, dst_path_buf, $1100
        DEFINE_READ_PARAMS read_src_params, file_data_buffer, kBufSize
        DEFINE_WRITE_PARAMS write_dst_params, file_data_buffer, kBufSize
        DEFINE_CREATE_PARAMS create_params3, dst_path_buf, ACCESS_DEFAULT
        DEFINE_CREATE_PARAMS create_params2, dst_path_buf

        DEFINE_SET_EOF_PARAMS set_eof_params, 0
        DEFINE_SET_MARK_PARAMS mark_src_params, 0
        DEFINE_SET_MARK_PARAMS mark_dst_params, 0
        DEFINE_ON_LINE_PARAMS on_line_params2,, $800


;;; ============================================================

        ;; overlayed indirect jump table
        kOpJTAddrsSize = 6

;;; NOTE: These are referenced by indirect JMP and *must not*
;;; cross page boundaries.
op_jt_addrs:
op_jt_addr1:  .addr   CopyProcessDirectoryEntry     ; defaults are for copy
op_jt_addr2:  .addr   copy_pop_directory
op_jt_addr3:  .addr   DoNothing

DoNothing:   rts

;;; 0 for count/size pass, non-zero for actual operation
do_op_flag:
        .byte   0

.proc PushEntryCount
        ldx     entry_count_stack_index
        lda     entries_to_skip
        sta     entry_count_stack,x
        inx
        lda     entries_to_skip+1
        sta     entry_count_stack,x
        inx
        stx     entry_count_stack_index
        rts
.endproc

.proc PopEntryCount
        ldx     entry_count_stack_index
        dex
        lda     entry_count_stack,x
        sta     entries_to_skip+1
        dex
        lda     entry_count_stack,x
        sta     entries_to_skip
        stx     entry_count_stack_index
        rts
.endproc

.proc OpenSrcDir
        lda     #0
        sta     entries_read
        sta     entries_read+1
        sta     entries_read_this_block

@retry: MLI_RELAY_CALL OPEN, open_src_dir_params
        beq     :+
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        beq     @retry          ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialog

:       lda     open_src_dir_params::ref_num
        sta     op_ref_num
        sta     read_block_pointers_params::ref_num

@retry2:MLI_RELAY_CALL READ, read_block_pointers_params
        beq     :+
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        beq     @retry2         ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialog

:       jmp     ReadFileEntry
.endproc

.proc CloseSrcDir
        lda     op_ref_num
        sta     close_src_dir_params::ref_num
@retry: MLI_RELAY_CALL CLOSE, close_src_dir_params
        beq     :+
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        beq     @retry          ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialog

:       rts
.endproc

.proc ReadFileEntry
        inc16   entries_read
        lda     op_ref_num
        sta     read_src_dir_entry_params::ref_num
@retry: MLI_RELAY_CALL READ, read_src_dir_entry_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     eof
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        beq     @retry          ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialog

:       inc     entries_read_this_block
        lda     entries_read_this_block
        cmp     num_entries_per_block
        bcc     :+
        copy    #0, entries_read_this_block
        copy    op_ref_num, read_padding_bytes_params::ref_num
        MLI_RELAY_CALL READ, read_padding_bytes_params
:       return  #0

eof:    return  #$FF
.endproc

;;; ============================================================

.proc PrepToOpenDir
        copy16  entries_read, entries_to_skip
        jsr     CloseSrcDir
        jsr     PushEntryCount
        jsr     AppendFileEntryToSrcPath
        jmp     OpenSrcDir
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

.proc FinishDir
        jsr     CloseSrcDir
        jsr     op_jt3          ; third - called when exiting dir
        jsr     RemoveSrcPathSegment
        jsr     PopEntryCount
        jsr     OpenSrcDir
        jsr     sub
        jmp     op_jt2          ; second - called when exited dir

sub:    cmp16   entries_read, entries_to_skip
        beq     done
        jsr     ReadFileEntry
        jmp     sub
done:   rts
.endproc

.proc ProcessDir
        copy    #0, process_depth
        jsr     OpenSrcDir
loop:   jsr     ReadFileEntry
        bne     end_dir

        param_call AdjustFileEntryCase, file_entry_buf

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
        jsr     PrepToOpenDir
        inc     process_depth
        jmp     loop

end_dir:
        lda     process_depth
        beq     :+
        jsr     FinishDir
        dec     process_depth
        jmp     loop

:       jmp     CloseSrcDir
.endproc

cancel_descent_flag:  .byte   0

op_jt1: jmp     (op_jt_addr1)
op_jt2: jmp     (op_jt_addr2)
op_jt3: jmp     (op_jt_addr3)

;;; ============================================================
;;; "Copy" (including Drag/Drop/Move) files state and logic
;;; ============================================================

;;; CopyProcessSelectedFile
;;;  - called for each file in selection; calls ProcessDir to recurse
;;; CopyProcessDirectoryEntry
;;;  - c/o ProcessDir for each file in dir; skips if dir, copies otherwise
;;; copy_pop_directory
;;;  - c/o ProcessDir when exiting dir; pops path segment
;;; MaybeFinishFileMove
;;;  - c/o ProcessDir after exiting; deletes dir if moving

;;; Overlays for copy operation (op_jt_addrs)
callbacks_for_copy:
        .addr   CopyProcessDirectoryEntry
        .addr   copy_pop_directory
        .addr   MaybeFinishFileMove

.enum CopyDialogLifecycle
        open            = 0
        count           = 1
        show            = 2
        exists          = 3     ; show "file exists" prompt
        too_large       = 4     ; show "too large" prompt
        close           = 5
.endenum

;;; Also used for Download
.params copy_dialog_params
phase:  .byte   0
count:  .addr   0
a_src:  .addr   src_path_buf
a_dst:  .addr   dst_path_buf
.endparams

.proc DoCopyDialogPhase
        copy    #CopyDialogLifecycle::open, copy_dialog_params::phase
        copy16  #CopyDialogEnumerationCallback, operation_enumeration_callback
        copy16  #CopyDialogCompleteCallback, operation_complete_callback
        jmp     RunCopyDialogProc
.endproc

.proc CopyDialogEnumerationCallback
        stax    copy_dialog_params::count
        copy    #CopyDialogLifecycle::count, copy_dialog_params::phase
        jmp     RunCopyDialogProc
.endproc

.proc PrepCallbacksForCopy
        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_copy,y,  op_jt_addrs,y
        dey
        bpl     :-

        copy    #0, all_flag
        rts
.endproc

.proc CopyDialogCompleteCallback
        copy    #CopyDialogLifecycle::close, copy_dialog_params::phase
        jmp     RunCopyDialogProc
.endproc

;;; ============================================================
;;; "Download" - shares heavily with Copy

.enum DownloadDialogLifecycle
        open            = 0
        count           = 1
        show            = 2
        close           = 3
        too_large       = 4
.endenum

.proc DoDownloadDialogPhase
        copy    #DownloadDialogLifecycle::open, copy_dialog_params::phase
        copy16  #DownloadDialogEnumerationCallback, operation_enumeration_callback
        copy16  #DownloadDialogCompleteCallback, operation_complete_callback
        param_call invoke_dialog_proc, kIndexDownloadDialog, copy_dialog_params
        rts
.endproc

.proc DownloadDialogEnumerationCallback
        stax    copy_dialog_params::count
        copy    #CopyDialogLifecycle::count, copy_dialog_params::phase
        param_call invoke_dialog_proc, kIndexDownloadDialog, copy_dialog_params
        rts
.endproc

.proc PrepCallbacksForDownload
        copy    #$80, all_flag

        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_copy,y, op_jt_addrs,y
        dey
        bpl     :-

        copy16  #DownloadDialogTooLargeCallback, operation_toolarge_callback
        rts
.endproc

.proc DownloadDialogCompleteCallback
        copy    #DownloadDialogLifecycle::close, copy_dialog_params::phase
        param_call invoke_dialog_proc, kIndexDownloadDialog, copy_dialog_params
        rts
.endproc

.proc DownloadDialogTooLargeCallback
        copy    #DownloadDialogLifecycle::too_large, copy_dialog_params::phase
        param_call invoke_dialog_proc, kIndexDownloadDialog, copy_dialog_params
        ;; TODO: The dialog (in `DownloadDialogProc`) only has an OK button,
        ;; so the result is never yes.
        cmp     #PromptResult::yes
        bne     :+
        rts
:       jmp     CloseFilesCancelDialog
.endproc

;;; ============================================================
;;; Handle copying of a selected file.
;;; Calls into the recursion logic of `ProcessDir` as necessary.

.proc CopyProcessSelectedFile
        copy    #$80, copy_run_flag
        copy    #0, delete_skip_decrement_flag
        beq     :+              ; always

for_run:
        lda     #$FF

:       sta     is_run_flag
        copy    #CopyDialogLifecycle::show, copy_dialog_params::phase
        jsr     CopyPathsFromBufsToSrcAndDst
        bit     operation_flags
        bvc     @not_run
        jsr     CheckVolBlocksFree           ; dst is a volume path (RAM Card)
@not_run:
        bit     copy_run_flag
        bpl     get_src_info    ; never taken ???
        bvs     L9A50
        is_run_flag := *+1
        lda     #SELF_MODIFIED_BYTE
        bne     :+
        lda     selected_window_id ; dragging from window?
        jeq     CopyDir

:       jsr     AppendSrcPathLastSegmentToDstPath
        jmp     get_src_info

        ;; Append filename to `dst_path_buf`
L9A50:  ldax    #filename_buf
        jsr     AppendFilenameToDstPath

get_src_info:
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry

:       lda     src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        cmp     #ST_TREE_FILE+1 ; only seedling/sapling/tree supported
    IF_GE
        lda     #kErrUnsupportedFileType
        jsr     ShowAlert
        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialog
        jmp     failure
    END_IF

        lda     #$00
        beq     store
is_dir: lda     #$FF
store:  sta     is_dir_flag
        jsr     DecFileCountAndRunCopyDialogProc

        ;; Copy access, file_type, aux_type, storage_type
        ldy     #src_file_info_params::storage_type - src_file_info_params
:       lda     src_file_info_params,y
        sta     create_params2,y
        dey
        cpy     #src_file_info_params::access - src_file_info_params - 1
        bne     :-

        copy    #ACCESS_DEFAULT, create_params2::access
        lda     copy_run_flag
        beq     success         ; never taken ???
        jsr     CheckSpaceAndShowPrompt
        bcs     failure

        ;; Copy create_time/create_date
        ldy     #src_file_info_params::create_time - src_file_info_params + 1
        ldx     #create_params2::create_time - create_params2 + 1
:       lda     src_file_info_params,y
        sta     create_params2,x
        dex
        dey
        cpy     #src_file_info_params::create_date - src_file_info_params - 1
        bne     :-

        ;; If a volume, need to create a subdir instead
        lda     create_params2::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     :+
        lda     #ST_LINKED_DIRECTORY
        sta     create_params2::storage_type
:

        ;; TODO: Dedupe with `TryCreateDst`
        jsr     DecrementOpFileCount
retry:  MLI_RELAY_CALL CREATE, create_params2
        beq     success

        cmp     #ERR_DUPLICATE_FILENAME
        bne     err
        bit     all_flag
        bmi     yes
        copy    #CopyDialogLifecycle::exists, copy_dialog_params::phase
        jsr     RunCopyDialogProc
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
yes:    jsr     ApplyFileInfoAndSize
        jmp     success

        ;; PromptResult::cancel
cancel: jmp     CloseFilesCancelDialog

err:    jsr     ShowErrorAlert
        jmp     retry

success:
        is_dir_flag := *+1
        lda     #SELF_MODIFIED_BYTE
        beq     CopyFile
CopyDir:                       ; also used when dragging a volume icon
        jsr     ProcessDir
        jmp     MaybeFinishFileMove
CopyFile:
        jsr     DoFileCopy
        jmp     MaybeFinishFileMove

failure:
        rts
.endproc
        copy_file_for_run := CopyProcessSelectedFile::for_run

;;; ============================================================

src_path_slash_index:
        .byte   0

;;; ============================================================

copy_pop_directory:
        jmp     RemoveDstPathSegment

;;; ============================================================
;;; If moving, delete src file/directory.

.proc MaybeFinishFileMove
        ;; Copy or move?
        bit     move_flag
        bpl     done

        ;; Was a move - delete file
@retry: MLI_RELAY_CALL DESTROY, destroy_params
        beq     done
        cmp     #ERR_ACCESS_ERROR
        bne     :+
        jsr     UnlockSrcFile
        beq     @retry
        bne     done            ; silently leave file

:       jsr     ShowErrorAlert
        jmp     @retry
done:   rts
.endproc

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

.proc CopyProcessDirectoryEntry
        jsr     CheckEscapeKeyDown
        jne     CloseFilesCancelDialog

        lda     file_entry_buf + FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     regular_file

        ;; Directory
        jsr     AppendFileEntryToSrcPath
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry

:       jsr     AppendFileEntryToDstPath
        jsr     DecFileCountAndRunCopyDialogProc

        jsr     TryCreateDst
        bcs     :+
        jsr     RemoveSrcPathSegment
        jmp     done

:       jsr     RemoveDstPathSegment
        jsr     RemoveSrcPathSegment
        copy    #$FF, cancel_descent_flag
        jmp     done

        ;; File
regular_file:
        jsr     AppendFileEntryToDstPath
        jsr     AppendFileEntryToSrcPath
        jsr     DecFileCountAndRunCopyDialogProc
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry
:
        lda     src_file_info_params::storage_type
        cmp     #ST_TREE_FILE+1 ; only seedling/sapling/tree supported
    IF_GE
        lda     #kErrUnsupportedFileType
        jsr     ShowAlert
        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialog
        jmp     skip
    END_IF

        jsr     CheckSpaceAndShowPrompt
        jcs     CloseFilesCancelDialog

        jsr     RemoveSrcPathSegment
        jsr     TryCreateDst
        bcs     :+
        jsr     AppendFileEntryToSrcPath
        jsr     DoFileCopy
        jsr     MaybeFinishFileMove
skip:   jsr     RemoveSrcPathSegment
:       jsr     RemoveDstPathSegment
done:   rts
.endproc

;;; ============================================================

.proc RunCopyDialogProc
        param_call invoke_dialog_proc, kIndexCopyDialog, copy_dialog_params
        rts
.endproc

;;; ============================================================

.proc CheckVolBlocksFree
@retry: MLI_RELAY_CALL GET_FILE_INFO, dst_file_info_params
        beq     :+
        jsr     ShowErrorAlertDst
        jmp     @retry

:       sub16   dst_file_info_params::aux_type, dst_file_info_params::blocks_used, blocks_free
        cmp16   blocks_free, op_block_count
        jcc     InvokeOperationTooLargeCallback

        rts

blocks_free:
        .word   0
.endproc

;;; ============================================================

.proc CheckSpaceAndShowPrompt
        jsr     CheckSpace
        bcc     done
        ;; TODO: Convert this to an alert
        copy    #CopyDialogLifecycle::too_large, copy_dialog_params::phase
        jsr     RunCopyDialogProc
        jne     CloseFilesCancelDialog

        copy    #CopyDialogLifecycle::exists, copy_dialog_params::phase
        sec
done:   rts

.proc CheckSpace
        ;; Size of source
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry

        ;; If destination doesn't exist, 0 blocks will be reclaimed.
:       copy16  #0, existing_size

        ;; Does destination exist?
@retry2:MLI_RELAY_CALL GET_FILE_INFO, dst_file_info_params
        beq     got_exist_size
        cmp     #ERR_FILE_NOT_FOUND
        beq     :+
        jsr     ShowErrorAlertDst ; retry if destination not present
        jmp     @retry2

got_exist_size:
        copy16  dst_file_info_params::blocks_used, existing_size
:
        ;; Compute destination volume path
retry:  copy    dst_path_buf, saved_length

        ;; Strip to vol name - either end of string or next slash
        ldy     #1
:       iny                     ; start at 2nd character
        cpy     dst_path_buf
        beq     :+
        lda     dst_path_buf,y
        cmp     #'/'
        bne     :-
        dey
:       sty     dst_path_buf

        ;; Total blocks/used blocks on destination volume
        MLI_RELAY_CALL GET_FILE_INFO, dst_file_info_params
        pha
        saved_length := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     dst_path_buf
        pla
        beq     :+
        jsr     ShowErrorAlertDst
        jmp     retry
:
        ;; aux = total blocks
        sub16   dst_file_info_params::aux_type, dst_file_info_params::blocks_used, blocks_free
        add16   blocks_free, existing_size, blocks_free
        cmp16   blocks_free, src_file_info_params::blocks_used
        bcs     has_room

        ;; not enough room
        sec
        rts

has_room:
        clc
        rts

blocks_free:
        .word   0
existing_size:
        .word   0
.endproc
.endproc

;;; ============================================================
;;; Actual byte-for-byte file copy routine

.proc DoFileCopy
        lda     #0
        sta     src_dst_exclusive_flag
        sta     src_eof_flag
        sta     mark_src_params::position
        sta     mark_src_params::position+1
        sta     mark_src_params::position+2
        sta     mark_dst_params::position
        sta     mark_dst_params::position+1
        sta     mark_dst_params::position+2

        jsr     OpenSrc
        jsr     CopySrcRefNum
        jsr     OpenDst
        beq     :+

        ;; Destination not available; note it, can prompt later
        copy    #$FF, src_dst_exclusive_flag
        bne     read            ; always
:       jsr     CopyDstRefNum

        ;; Read
read:   jsr     ReadSrc
        bit     src_dst_exclusive_flag
        bpl     write
        jsr     CloseSrc       ; swap if necessary
:       jsr     OpenDst
        bne     :-
        jsr     CopyDstRefNum
        MLI_RELAY_CALL SET_MARK, mark_dst_params

        ;; Write
write:  bit     src_eof_flag
        bmi     eof
        jsr     WriteDst
        bit     src_dst_exclusive_flag
        bpl     read
        jsr     CloseDst       ; swap if necessary
        jsr     OpenSrc
        jsr     CopySrcRefNum

        MLI_RELAY_CALL SET_MARK, mark_src_params
        beq     read
        copy    #$FF, src_eof_flag
        jmp     read

        ;; EOF
eof:    jsr     CloseDst
        bit     src_dst_exclusive_flag
        bmi     :+
        jsr     CloseSrc
:       jsr     CopyFileInfo
        jmp     SetDstFileInfo

.proc OpenSrc
@retry: MLI_RELAY_CALL OPEN, open_src_params
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry
:       rts
.endproc

.proc CopySrcRefNum
        lda     open_src_params::ref_num
        sta     read_src_params::ref_num
        sta     close_src_params::ref_num
        sta     mark_src_params::ref_num
        rts
.endproc

.proc OpenDst
@retry: MLI_RELAY_CALL OPEN, open_dst_params
        beq     done
        cmp     #ERR_VOL_NOT_FOUND
        beq     not_found
        jsr     ShowErrorAlertDst
        jmp     @retry

not_found:
        jsr     ShowErrorAlertDst
        lda     #ERR_VOL_NOT_FOUND

done:   rts
.endproc

.proc CopyDstRefNum
        lda     open_dst_params::ref_num
        sta     write_dst_params::ref_num
        sta     close_dst_params::ref_num
        sta     mark_dst_params::ref_num
        rts
.endproc

.proc ReadSrc
        copy16  #kBufSize, read_src_params::request_count
@retry: MLI_RELAY_CALL READ, read_src_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     eof
        jsr     ShowErrorAlert
        jmp     @retry

:       copy16  read_src_params::trans_count, write_dst_params::request_count
        ora     read_src_params::trans_count
        bne     :+
eof:    copy    #$FF, src_eof_flag
:       MLI_RELAY_CALL GET_MARK, mark_src_params
        rts
.endproc

.proc WriteDst
@retry: MLI_RELAY_CALL WRITE, write_dst_params
        beq     :+
        jsr     ShowErrorAlertDst
        jmp     @retry
:       MLI_RELAY_CALL GET_MARK, mark_dst_params
        rts
.endproc

.proc CloseDst
        MLI_RELAY_CALL CLOSE, close_dst_params
        rts
.endproc

.proc CloseSrc
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

.proc TryCreateDst
        ;; Copy file_type, aux_type, storage_type
        ldx     #7
:       lda     src_file_info_params,x
        sta     create_params3,x
        dex
        cpx     #3
        bne     :-

        jsr     DecrementOpFileCount
retry:  MLI_RELAY_CALL CREATE, create_params3
        beq     success

        cmp     #ERR_DUPLICATE_FILENAME
        bne     err
        bit     all_flag
        bmi     yes
        copy    #CopyDialogLifecycle::exists, copy_dialog_params::phase
        param_call invoke_dialog_proc, kIndexCopyDialog, copy_dialog_params
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
yes:    jsr     ApplyFileInfoAndSize
        jmp     success

cancel: jmp     CloseFilesCancelDialog

err:    jsr     ShowErrorAlertDst
        jmp     retry

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

;;; DeleteProcessSelectedFile
;;;  - called for each file in selection; calls ProcessDir to recurse
;;; DeleteProcessDirectoryEntry
;;;  - c/o ProcessDir for each file in dir; skips if dir, deletes otherwise
;;; DeleteFinishDirectory
;;;  - c/o ProcessDir when exiting dir; deletes it

;;; Overlays for delete operation (op_jt_addrs)
callbacks_for_delete:
        .addr   DeleteProcessDirectoryEntry
        .addr   DoNothing
        .addr   DeleteFinishDirectory

.params delete_dialog_params
phase:  .byte   0
count:  .word   0
a_path: .addr   src_path_buf
.endparams

.proc DoDeleteDialogPhase
        sta     delete_dialog_params::phase
        copy16  #DeleteDialogConfirmCallback, operation_confirm_callback
        copy16  #DeleteDialogEnumerationCallback, operation_enumeration_callback
        jsr     RunDeleteDialogProc
        copy16  #DeleteDialogCompleteCallback, operation_complete_callback
        rts

.proc DeleteDialogEnumerationCallback
        stax    delete_dialog_params::count
        copy    #DeleteDialogLifecycle::count, delete_dialog_params::phase
        jmp     RunDeleteDialogProc
.endproc

.proc DeleteDialogConfirmCallback
        copy    #DeleteDialogLifecycle::confirm, delete_dialog_params::phase
        jsr     RunDeleteDialogProc
        beq     :+
        lda     #kOperationCanceled
        jmp     CloseFilesCancelDialogWithResult
:       rts
.endproc

.endproc

;;; ============================================================

.proc PrepCallbacksForDelete
        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_delete,y, op_jt_addrs,y
        dey
        bpl     :-

        copy    #0, all_flag
        rts
.endproc

.proc DeleteDialogCompleteCallback
        copy    #DeleteDialogLifecycle::close, delete_dialog_params::phase
        jmp     RunDeleteDialogProc
.endproc

;;; ============================================================
;;; Handle deletion of a selected file.
;;; Calls into the recursion logic of `ProcessDir` as necessary.

.proc DeleteProcessSelectedFile
        copy    #DeleteDialogLifecycle::show, delete_dialog_params::phase
        jsr     CopyPathsFromBufsToSrcAndDst

@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry

        ;; Check if it's a regular file or directory
:       lda     src_file_info_params::storage_type
        sta     storage_type
        cmp     #ST_LINKED_DIRECTORY
        beq     :+
        cmp     #ST_TREE_FILE+1 ; only seedling/sapling/tree supported
    IF_GE
        lda     #kErrUnsupportedFileType
        jsr     ShowAlert
        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialog
        jmp     done
    END_IF

        lda     #0
        beq     store
:       lda     #$FF

store:  ;; sta     is_dir_flag - unused
        beq     do_destroy

        ;; Recurse, and process directory
        jsr     ProcessDir

        ;; Was it a directory?
        storage_type := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #ST_LINKED_DIRECTORY
        bne     :+
        copy    #$FF, storage_type ; is this re-checked?
:       jmp     do_destroy

do_destroy:
        bit     delete_skip_decrement_flag
        bmi     :+
        jsr     DecFileCountAndRunDeleteDialogProc
:       jsr     DecrementOpFileCount

retry:  MLI_RELAY_CALL DESTROY, destroy_params
        beq     done

        ;; Failed, try to unlock.
        ;; TODO: If it's a directory, this could be because it's not empty,
        ;; e.g. if it contained files that could not be deleted.
        cmp     #ERR_ACCESS_ERROR
        bne     error
        bit     all_flag
        bmi     do_it
        copy    #DeleteDialogLifecycle::locked, delete_dialog_params::phase
        jsr     RunDeleteDialogProc
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
:       jmp     CloseFilesCancelDialog

do_it:  jsr     UnlockSrcFile
        beq     retry

done:   rts

error:  jsr     ShowErrorAlert
        jmp     retry
.endproc

.proc UnlockSrcFile
        MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        lda     src_file_info_params::access
        and     #$80            ; destroy enabled bit set?
        bne     done            ; yes, no need to unlock

        lda     #ACCESS_DEFAULT
        sta     src_file_info_params::access
        copy    #7, src_file_info_params::param_count ; SET_FILE_INFO
        MLI_RELAY_CALL SET_FILE_INFO, src_file_info_params
        pha
        copy    #$A, src_file_info_params::param_count ; GET_FILE_INFO
        pla

done:   rts
.endproc

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

.proc DeleteProcessDirectoryEntry
        ;; Cancel if escape pressed
        jsr     CheckEscapeKeyDown
        jne     CloseFilesCancelDialog

        jsr     AppendFileEntryToSrcPath
        bit     delete_skip_decrement_flag
        bmi     :+
        jsr     DecFileCountAndRunDeleteDialogProc
:       jsr     DecrementOpFileCount

        ;; Check file type
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry

        ;; Directories will be processed separately
:       lda     src_file_info_params::storage_type
        cmp     #ST_LINKED_DIRECTORY
        beq     next_file
        cmp     #ST_TREE_FILE+1 ; only seedling/sapling/tree supported
    IF_GE
        lda     #kErrUnsupportedFileType
        jsr     ShowAlert
        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialog
        jmp     next_file
    END_IF

loop:   MLI_RELAY_CALL DESTROY, destroy_params
        beq     next_file
        cmp     #ERR_ACCESS_ERROR
        bne     err
        bit     all_flag
        bmi     unlock
        copy    #DeleteDialogLifecycle::locked, delete_dialog_params::phase
        param_call invoke_dialog_proc, kIndexDeleteDialog, delete_dialog_params
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
:       jmp     CloseFilesCancelDialog

unlock: copy    #ACCESS_DEFAULT, src_file_info_params::access
        copy    #7, src_file_info_params::param_count ; SET_FILE_INFO
        MLI_RELAY_CALL SET_FILE_INFO, src_file_info_params
        copy    #$A,src_file_info_params::param_count ; GET_FILE_INFO
        jmp     loop

err:    jsr     ShowErrorAlert
        jmp     loop

next_file:
        jmp     RemoveSrcPathSegment
.endproc

;;; ============================================================
;;; Delete directory when exiting via traversal

.proc DeleteFinishDirectory
@retry: MLI_RELAY_CALL DESTROY, destroy_params
        beq     done
        cmp     #ERR_ACCESS_ERROR
        beq     done
        jsr     ShowErrorAlert
        jmp     @retry
done:   rts
.endproc

.proc RunDeleteDialogProc
        param_call invoke_dialog_proc, kIndexDeleteDialog, delete_dialog_params
        rts
.endproc

;;; ============================================================
;;; "Lock"/"Unlock" dialog state and logic
;;; ============================================================

;;; LockProcessSelectedFile
;;;  - called for each file in selection; calls ProcessDir to recurse
;;; LockProcessDirectoryEntry
;;;  - c/o ProcessDir for each file in dir; skips if dir, locks otherwise

;;; Overlays for lock/unlock operation (op_jt_addrs)
callbacks_for_lock:
        .addr   LockProcessDirectoryEntry
        .addr   DoNothing
        .addr   DoNothing

.enum LockDialogLifecycle
        open            = 0 ; opening window, initial label
        count           = 1 ; show operation details (e.g. file count)
        prompt          = 2 ; draw buttons, input loop
        operation       = 3 ; performing operation
        close           = 4 ; destroy window
.endenum

.params lock_unlock_dialog_params
phase:  .byte   0
count:  .word   0
a_path: .addr   src_path_buf
.endparams

.proc DoLockDialogPhase
        copy    #LockDialogLifecycle::open, lock_unlock_dialog_params::phase
        bit     unlock_flag
        bpl     :+

        ;; Unlock
        copy16  #UnlockDialogConfirmCallback, operation_confirm_callback
        copy16  #UnlockDialogEnumerationCallback, operation_enumeration_callback
        jsr     RunUnlockDialogProc
        copy16  #UnlockDialogCompleteCallback, operation_complete_callback
        rts

        ;; Lock
:       copy16  #LockDialogConfirmCallback, operation_confirm_callback
        copy16  #LockDialogEnumerationCallback, operation_enumeration_callback
        jsr     RunLockDialogProc
        copy16  #LockDialogCompleteCallback, operation_complete_callback
        rts
.endproc

.proc LockDialogEnumerationCallback
        stax    lock_unlock_dialog_params::count
        copy    #LockDialogLifecycle::count, lock_unlock_dialog_params::phase
        jmp     RunLockDialogProc
.endproc

.proc UnlockDialogEnumerationCallback
        stax    lock_unlock_dialog_params::count
        copy    #LockDialogLifecycle::count, lock_unlock_dialog_params::phase
        jmp     RunUnlockDialogProc
.endproc

.proc LockDialogConfirmCallback
        copy    #LockDialogLifecycle::prompt, lock_unlock_dialog_params::phase
        jsr     RunLockDialogProc
        jne     CloseFilesCancelDialog

        rts
.endproc

.proc UnlockDialogConfirmCallback
        copy    #LockDialogLifecycle::prompt, lock_unlock_dialog_params::phase
        jsr     RunUnlockDialogProc
        jne     CloseFilesCancelDialog

        rts
.endproc

.proc PrepCallbacksForLock
        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_lock,y, op_jt_addrs,y
        dey
        bpl     :-

        rts
.endproc

.proc LockDialogCompleteCallback
        copy    #LockDialogLifecycle::close, lock_unlock_dialog_params::phase
        jmp     RunLockDialogProc
.endproc

.proc UnlockDialogCompleteCallback
        copy    #LockDialogLifecycle::close, lock_unlock_dialog_params::phase
        jmp     RunUnlockDialogProc
.endproc

RunLockDialogProc:
        param_call invoke_dialog_proc, kIndexLockDialog, lock_unlock_dialog_params
        rts

RunUnlockDialogProc:
        param_call invoke_dialog_proc, kIndexUnlockDialog, lock_unlock_dialog_params
        rts

;;; ============================================================
;;; Handle locking of a selected file.
;;; Calls into the recursion logic of `ProcessDir` as necessary.

.proc LockProcessSelectedFile
        copy    #LockDialogLifecycle::operation, lock_unlock_dialog_params::phase
        jsr     CopyPathsFromBufsToSrcAndDst
        jsr     AppendSrcPathLastSegmentToDstPath

@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     ShowErrorAlert
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
store:  ;; sta     is_dir_flag - unused
        beq     do_lock

        ;; Process files in directory
        jsr     ProcessDir

        ;; If this wasn't a volume directory, lock it too
        storage_type := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #ST_VOLUME_DIRECTORY
        bne     do_lock
        rts

do_lock:
        jsr     LockFileCommon
        jmp     AppendFileEntryToSrcPath
.endproc

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

LockProcessDirectoryEntry:
        jsr     AppendFileEntryToSrcPath
        ;; fall through

.proc LockFileCommon
        jsr     update_dialog

        jsr     DecrementOpFileCount

@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry

:       lda     src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     ok
        cmp     #ST_LINKED_DIRECTORY
        beq     ok
        bit     unlock_flag
        bpl     :+
        lda     #ACCESS_DEFAULT
        bne     set             ; always
:       lda     #ACCESS_LOCKED
set:    sta     src_file_info_params::access

:       copy    #7, src_file_info_params::param_count ; SET_FILE_INFO
        MLI_RELAY_CALL SET_FILE_INFO, src_file_info_params
        pha
        copy    #$A, src_file_info_params::param_count ; GET_FILE_INFO
        pla
        beq     ok
        jsr     ShowErrorAlert
        jmp     :-

ok:     jmp     RemoveSrcPathSegment

update_dialog:
        sub16   op_file_count, #1, lock_unlock_dialog_params::count
        bit     unlock_flag
        bpl     :+
        jmp     RunUnlockDialogProc

:       jmp     RunLockDialogProc
.endproc

;;; ============================================================
;;; "Get Size" dialog state and logic
;;; ============================================================

;;; Logic also used for "count" operation which precedes most
;;; other operations (copy, delete, lock, unlock) to populate
;;; confirmation dialog.

.enum GetSizeDialogLifecycle
        open    = 0
        count   = 1
        prompt  = 2
        close   = 3
.endenum

.params get_size_dialog_params
phase:          .byte   0
a_files:        .addr  op_file_count
a_blocks:       .addr  op_block_count
.endparams

.proc DoGetSizeDialogPhase
        copy    #0, get_size_dialog_params::phase
        copy16  #GetSizeDialogConfirmCallback, operation_confirm_callback
        copy16  #GetSizeDialogEnumerationCallback, operation_enumeration_callback
        param_call invoke_dialog_proc, kIndexGetSizeDialog, get_size_dialog_params
        copy16  #GetSizeDialogCompleteCallback, operation_complete_callback
        rts
.endproc

.proc GetSizeDialogEnumerationCallback
        copy    #GetSizeDialogLifecycle::count, get_size_dialog_params::phase
        param_call invoke_dialog_proc, kIndexGetSizeDialog, get_size_dialog_params
        ;; fall through
.endproc
get_size_rts1:
        rts

.proc GetSizeDialogConfirmCallback
        copy    #GetSizeDialogLifecycle::prompt, get_size_dialog_params::phase
        param_call invoke_dialog_proc, kIndexGetSizeDialog, get_size_dialog_params
        beq     get_size_rts1
        jmp     CloseFilesCancelDialog
.endproc

.proc GetSizeDialogCompleteCallback
        copy    #GetSizeDialogLifecycle::close, get_size_dialog_params::phase
        param_call invoke_dialog_proc, kIndexGetSizeDialog, get_size_dialog_params
.endproc
get_size_rts2:
        rts

;;; ============================================================
;;; Most operations start by doing a traversal to just count
;;; the files.

;;; Overlays for size operation (op_jt_addrs)
callbacks_for_size_or_count:
        .addr   SizeOrCountProcessDirectoryEntry
        .addr   DoNothing
        .addr   DoNothing

.proc PrepCallbacksForSizeOrCount
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
;;; Calls into the recursion logic of `ProcessDir` as necessary.

.proc SizeOrCountProcessSelectedFile
        jsr     CopyPathsFromBufsToSrcAndDst
@retry: MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry

:       copy    src_file_info_params::storage_type, storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        lda     #0
        beq     store           ; always

is_dir: lda     #$FF

store:  ;; sta     is_dir_flag - unused
        beq     do_sum_file_size           ; if not a dir

        jsr     ProcessDir
        storage_type := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #ST_VOLUME_DIRECTORY
        bne     do_sum_file_size           ; if a subdirectory

        ;; If copying a volume dir to RAMCard, the volume dir
        ;; will not be counted as a file during enumeration but
        ;; will be counted during copy, so include it to avoid
        ;; off-by-one.
        ;; https://github.com/a2stuff/a2d/issues/462
        bit     run_flag
        bpl     :+
        inc16   op_file_count
:       rts

do_sum_file_size:
        jmp     SizeOrCountProcessDirectoryEntry
.endproc

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

.proc SizeOrCountProcessDirectoryEntry
        bit     operation_flags
        bvc     :+              ; not size

        ;; If operation is "get size", add the block count to the sum
        jsr     AppendFileEntryToSrcPath
        MLI_RELAY_CALL GET_FILE_INFO, src_file_info_params
        bne     :+
        add16   op_block_count, src_file_info_params::blocks_used, op_block_count

:       inc16   op_file_count

        bit     operation_flags
        bvc     :+              ; not size
        jsr     RemoveSrcPathSegment

:       ldax    op_file_count
        jmp     InvokeOperationEnumerationCallback
.endproc

op_file_count:
        .word   0

op_block_count:
        .word   0

;;; ============================================================

.proc DecrementOpFileCount
        dec16   op_file_count
        rts
.endproc

;;; ============================================================
;;; Append name at `file_entry_buf` to path at `src_path_buf`

.proc AppendFileEntryToSrcPath
        ldax    #file_entry_buf
        jmp     AppendFilenameToSrcPath
.endproc

;;; ============================================================
;;; Remove segment from path at `src_path_buf`

.proc RemoveSrcPathSegment
        path := src_path_buf

        ldx     path            ; length
        beq     ret

:       lda     path,x
        cmp     #'/'
        beq     found
        dex
        bne     :-
        stx     path
        rts

found:  dex
        stx     path

ret:    rts
.endproc

;;; ============================================================
;;; Append name at `file_entry_buf` to path at `dst_path_buf`

.proc AppendFileEntryToDstPath
        ldax    #file_entry_buf
        jmp     AppendFilenameToDstPath
.endproc

;;; ============================================================
;;; Remove segment from path at `dst_path_buf`

.proc RemoveDstPathSegment
        path := dst_path_buf

        ldx     path            ; length
        beq     ret

:       lda     path,x
        cmp     #'/'
        beq     found
        dex
        bne     :-
        stx     path
        rts

found:  dex
        stx     path

ret:    rts
.endproc

;;; ============================================================
;;; Check if `src_path_buf` is inside `dst_path_buf`.
;;; Output: A=0 if ok, A=err code otherwise.

.proc CheckRecursion
        src := src_path_buf
        dst := dst_path_buf

        ldx     src             ; Compare string lengths. If the same, need
        cpx     dst             ; to compare strings. If `src` > `dst`
        beq     compare         ; ('/a/b' vs. '/a'), then it's not a problem.
        bcs     ok

        ;; Assert: `src` is shorter then `dst`
        inx                     ; See if `dst` is possibly a subfolder
        lda     dst,x           ; ('/a/b/c' vs. '/a/b') or a sibling
        cmp     #'/'            ; ('/a/bc' vs. /a/b').
        bne     ok              ; At worst, a sibling - that's okay.

        ;; Potentially self or a subfolder; compare strings.
compare:
        ldx     src
:       lda     src,x
        jsr     UpcaseChar
        sta     @char
        lda     dst,x
        jsr     UpcaseChar
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     ok
        dex
        bne     :-

        ;; Self or subfolder; show a fatal error.
        return  #kErrMoveCopyIntoSelf

ok:     return  #0

.endproc

;;; ============================================================
;;; Check for replacing an item with itself or a descendant.
;;; Input: `src_path_buf` and `dst_path_buf` are full paths
;;; Output: A=0 if ok, A=err code otherwise.

.proc CheckBadReplacement

        ;; Examples:
        ;; src: '/a/p'   dst: '/a/p' (replace with self)
        ;; src: '/a/c/c' dst: '/a/c' (replace with item inside self)

        ;; Check for dst being subset of src

        src := src_path_buf
        dst := dst_path_buf

        ldx     dst             ; Compare string lengths. If the same, need
        cpx     src             ; to compare strings. If `dst` > `src`
        beq     compare         ; ('/a/b' vs. '/a'), then it's not a problem.
        bcs     ok

        ;; Assert: `dst` is shorter then `src`
        inx                     ; See if `src` is possibly a subfolder
        lda     src,x           ; ('/a/b/c' vs. '/a/b') or a sibling
        cmp     #'/'            ; ('/a/bc' vs. /a/b').
        bne     ok              ; At worst, a sibling - that's okay.

        ;; Potentially self or a subfolder; compare strings.
compare:
        ldx     dst
:       lda     dst,x
        jsr     UpcaseChar
        sta     @char
        lda     src,x
        jsr     UpcaseChar
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     ok
        dex
        bne     :-

        ;; Self or subfolder; show a fatal error.
        return  #kErrBadReplacement

ok:     return  #0

.endproc

;;; ============================================================
;;; Copy `path_buf3` to `src_path_buf`, `path_buf4` to `dst_path_buf`
;;; and note last '/' in src.

.proc CopyPathsFromBufsToSrcAndDst
        ldy     #0
        sty     src_path_slash_index
        dey

        ;; Copy `path_buf3` to `src_path_buf`
        ;; ... but record index of last '/'
loop:   iny
        lda     path_buf3,y
        cmp     #'/'
        bne     :+
        sty     src_path_slash_index
:       sta     src_path_buf,y
        cpy     path_buf3
        bne     loop

        ;; Copy `path_buf4` to `dst_path_buf`
        ldax    #path_buf4
        jmp     CopyToDstPath
.endproc

;;; ============================================================
;;; Assuming CopyPathsFromBufsToSrcAndDst has been called, append
;;; the last path segment of `src_path_buf` to `dst_path_buf`.
;;; Assert: `src_path_slash_index` is set properly.

.proc AppendSrcPathLastSegmentToDstPath
        ldx     dst_path_buf
        ldy     src_path_slash_index
        dey
:       iny
        inx
        lda     src_path_buf,y
        sta     dst_path_buf,x
        cpy     src_path_buf
        bne     :-

        stx     dst_path_buf
        rts
.endproc

;;; ============================================================
;;; Closes dialog, closes all open files, and restores stack.

.proc CloseFilesCancelDialog
        lda     #kOperationFailed
ep2:    sta     @result

        jsr     InvokeOperationCompleteCallback

        MLI_RELAY_CALL CLOSE, close_params

        ldx     stack_stash     ; restore stack, in case recursion was aborted
        txs

        @result := *+1
        lda     #SELF_MODIFIED_BYTE
        rts

        DEFINE_CLOSE_PARAMS close_params
.endproc
CloseFilesCancelDialogWithResult := CloseFilesCancelDialog::ep2

;;; ============================================================
;;; Move or Copy? Compare src/dst paths, same vol = move.
;;; Button down inverts the default action.
;;; Output: A=high bit set if move, clear if copy

.proc CheckMoveOrCopy
        src_ptr := $08
        dst_buf := path_buf4

        jsr     ModifierDown    ; Apple inverts the default
        sta     flag

        ldy     #0
        lda     (src_ptr),y
        sta     src_len
        iny                     ; skip leading '/'
        bne     check           ; always

        ;; Chars the same?
loop:   lda     (src_ptr),y
        jsr     UpcaseChar
        sta     @char
        lda     dst_buf,y
        jsr     UpcaseChar
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     no_match

        ;; Same and a slash?
        cmp     #'/'
        beq     match

        ;; End of src?
        src_len := *+1
check:  cpy     #SELF_MODIFIED_BYTE
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
        flag := *+1
        lda     #SELF_MODIFIED_BYTE
        rts

match:  lda     flag
        eor     #$80
        rts
.endproc

;;; ============================================================

.proc CheckEscapeKeyDown
        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::key_down
        bne     nope
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        bne     nope
        lda     #$FF
        bne     done
nope:   lda     #$00
done:   rts
.endproc

;;; ============================================================

.proc DecFileCountAndRunDeleteDialogProc
        sub16   op_file_count, #1, delete_dialog_params::count
        param_call invoke_dialog_proc, kIndexDeleteDialog, delete_dialog_params
        rts
.endproc

.proc DecFileCountAndRunCopyDialogProc
        sub16   op_file_count, #1, copy_dialog_params::count
        param_call invoke_dialog_proc, kIndexCopyDialog, copy_dialog_params
        rts
.endproc

;;; ============================================================

.proc ApplyFileInfoAndSize
:       jsr     CopyFileInfo
        copy    #ACCESS_DEFAULT, dst_file_info_params::access
        jsr     SetDstFileInfo
        lda     src_file_info_params::file_type
        cmp     #FT_DIRECTORY
        beq     done

        ;; If a regular file, open/set eof/close
        MLI_RELAY_CALL OPEN, open_dst_params
        beq     :+
        jsr     ShowErrorAlertDst
        jmp     :-              ; retry

:       lda     open_dst_params::ref_num
        sta     set_eof_params::ref_num
        sta     close_dst_params::ref_num
@retry: MLI_RELAY_CALL SET_EOF, set_eof_params
        beq     close
        jsr     ShowErrorAlertDst
        jmp     @retry

close:  MLI_RELAY_CALL CLOSE, close_dst_params
done:   rts
.endproc

.proc CopyFileInfo
        COPY_BYTES 11, src_file_info_params::access, dst_file_info_params::access
        rts
.endproc

.proc SetDstFileInfo
:       copy    #7, dst_file_info_params::param_count ; SET_FILE_INFO
        MLI_RELAY_CALL SET_FILE_INFO, dst_file_info_params
        pha
        copy    #$A, dst_file_info_params::param_count ; GET_FILE_INFO
        pla
        beq     done
        jsr     ShowErrorAlertDst
        jmp     :-

done:   rts
.endproc

;;; ============================================================
;;; Show Alert Dialog
;;; A=error. If ERR_VOL_NOT_FOUND or ERR_FILE_NOT_FOUND, will
;;; show "please insert source disk" (or destination, if flag set)

.proc ShowErrorAlertImpl

flag_set:
        ldx     #$80
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
flag_clear:
        ldx     #0
        stx     flag

        cmp     #ERR_VOL_NOT_FOUND ; if err is "not found"
        beq     not_found       ; prompt specifically for src/dst disk
        cmp     #ERR_PATH_NOT_FOUND
        beq     not_found

        jsr     ShowAlert
        bne     close           ; not kAlertResultTryAgain = 0
        rts

not_found:
        bit     flag
        bpl     :+
        lda     #kErrInsertDstDisk
        jmp     show

:       lda     #kErrInsertSrcDisk
show:   jsr     ShowAlert
        bne     close           ; not kAlertResultTryAgain = 0
        jmp     do_on_line

close:  jmp     CloseFilesCancelDialog

flag:   .byte   0

do_on_line:
        MLI_RELAY_CALL ON_LINE, on_line_params2
        rts

.endproc
ShowErrorAlert  := ShowErrorAlertImpl::flag_clear
ShowErrorAlertDst       := ShowErrorAlertImpl::flag_set

;;; ============================================================

        PAD_TO $A500

;;; ============================================================
;;; Dialog Proc Invocation

kNumDialogTypes = 11

kIndexAboutDialog       = 0
kIndexCopyDialog        = 1
kIndexDeleteDialog      = 2
kIndexNewFolderDialog   = 3
kIndexGetInfoDialog     = 4
kIndexLockDialog        = 5
kIndexUnlockDialog      = 6
kIndexRenameDialog      = 7
kIndexDownloadDialog    = 8
kIndexGetSizeDialog     = 9
kIndexDuplicateDialog   = 10

invoke_dialog_proc:
        ASSERT_ADDRESS $A500, "Overlay entry point"
        jmp     InvokeDialogProcImpl

dialog_proc_table:
        .addr   AboutDialogProc
        .addr   CopyDialogProc
        .addr   DeleteDialogProc
        .addr   NewFolderDialogProc
        .addr   GetInfoDialogProc
        .addr   LockDialogProc
        .addr   UnlockDialogProc
        .addr   RenameDialogProc
        .addr   DownloadDialogProc
        .addr   GetSizeDialogProc
        .addr   DuplicateDialogProc
        ASSERT_ADDRESS_TABLE_SIZE dialog_proc_table, kNumDialogTypes

dialog_param_addr:
        .addr   0

.proc InvokeDialogProcImpl
        stax    dialog_param_addr
        tya
        asl     a
        tax
        copy16  dialog_proc_table,x, @jump_addr

        lda     #0
        sta     prompt_ip_flag
        sta     blink_ip_flag
        sta     input_dirty_flag
        sta     input1_dirty_flag
        sta     input2_dirty_flag
        sta     has_input_field_flag
        sta     input_allow_all_chars_flag
        sta     format_erase_overlay_flag
        sta     cursor_ibeam_flag

        copy16  SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter

        copy16  #rts1, jump_relay+1
        jsr     SetCursorPointer ; when opening dialog

        @jump_addr := *+1
        jmp     SELF_MODIFIED
.endproc


;;; ============================================================
;;; Message handler for OK/Cancel dialog

.proc PromptInputLoop
        lda     has_input_field_flag
        beq     :+

        ;; Blink the insertion point
        dec16   prompt_ip_counter
        lda     prompt_ip_counter
        ora     prompt_ip_counter+1
        bne     :+
        jsr     RedrawPromptInsertionPoint
        copy16  SETTINGS + DeskTopSettings::ip_blink_speed, prompt_ip_counter

        ;; Dispatch event types - mouse down, key press
:       jsr     YieldLoop
        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        jeq     PromptClickHandler

        cmp     #MGTK::EventKind::key_down
        jeq     PromptKeyHandler

        ;; Does the dialog have an input field?
        lda     has_input_field_flag
        beq     PromptInputLoop

        ;; Check if mouse is over input field, change cursor appropriately.
        jsr     CheckMouseMoved
        bcc     PromptInputLoop

        MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        jeq     PromptInputLoop

        lda     findwindow_params::window_id
        cmp     #winfo_prompt_dialog::kWindowId
        jne     PromptInputLoop

        lda     winfo_prompt_dialog ; Is over this window... but where?
        jsr     SafeSetPortFromWindowId
        copy    winfo_prompt_dialog, event_params
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_params::windowx
        MGTK_RELAY_CALL MGTK::InRect, name_input_rect
        cmp     #MGTK::inrect_inside
        bne     out
        jsr     SetCursorIBeamWithFlag ; toggling in prompt dialog
        jmp     done
out:    jsr     SetCursorPointerWithFlag ; toggling in prompt dialog
done:   jsr     ResetMainGrafport
        jmp     PromptInputLoop
.endproc

;;; Click handler for prompt dialog

.proc PromptClickHandler
        MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        bne     :+
        return  #$FF
:       cmp     #MGTK::Area::content
        jeq     content
        return  #$FF

content:
        lda     findwindow_params::window_id
        cmp     #winfo_prompt_dialog::kWindowId
        beq     :+
        return  #$FF
:       lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        copy    winfo_prompt_dialog, event_params
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_params::windowx
        bit     prompt_button_flags
        jvs     check_button_yes

        MGTK_RELAY_CALL MGTK::InRect, aux::ok_button_rect
        cmp     #MGTK::inrect_inside
        beq     check_button_ok
        jmp     maybe_check_button_cancel

check_button_ok:
        param_call ButtonEventLoopRelay, winfo_prompt_dialog::kWindowId, aux::ok_button_rect
        bmi     :+
        lda     #PromptResult::ok
:       rts

check_button_yes:
        MGTK_RELAY_CALL MGTK::InRect, aux::yes_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_button_no
        param_call ButtonEventLoopRelay, winfo_prompt_dialog::kWindowId, aux::yes_button_rect
        bmi     :+
        lda     #PromptResult::yes
:       rts

check_button_no:
        MGTK_RELAY_CALL MGTK::InRect, aux::no_button_rect
        cmp     #MGTK::inrect_inside
        bne     check_button_all
        param_call ButtonEventLoopRelay, winfo_prompt_dialog::kWindowId, aux::no_button_rect
        bmi     :+
        lda     #PromptResult::no
:       rts

check_button_all:
        MGTK_RELAY_CALL MGTK::InRect, aux::all_button_rect
        cmp     #MGTK::inrect_inside
        bne     maybe_check_button_cancel
        param_call ButtonEventLoopRelay, winfo_prompt_dialog::kWindowId, aux::all_button_rect
        bmi     :+
        lda     #PromptResult::all
:       rts

maybe_check_button_cancel:
        bit     prompt_button_flags
        bpl     check_button_cancel
        return  #$FF

check_button_cancel:
        MGTK_RELAY_CALL MGTK::InRect, aux::cancel_button_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        param_call ButtonEventLoopRelay, winfo_prompt_dialog::kWindowId, aux::cancel_button_rect
        bmi     :+
        lda     #PromptResult::cancel
:       rts
    END_IF

        bit     has_input_field_flag
    IF_PLUS
        lda     #$FF
        jmp     jump_relay
    END_IF

        jsr     HandleClickInTextbox
        return  #$FF
.endproc

;;; Key handler for prompt dialog

.proc PromptKeyHandler
        lda     event_params::modifiers
        beq     no_mods

        ;; Modifier key down.
        lda     event_params::key
        cmp     #CHAR_LEFT
        jeq     LeftWithMod

        cmp     #CHAR_RIGHT
        jeq     RightWithMod

done:   return  #$FF

        ;; No modifier key down.
no_mods:
        lda     event_params::key

        cmp     #CHAR_LEFT
        bne     :+
        bit     format_erase_overlay_flag
        jmi     format_erase_overlay__PromptHandleKeyLeft
        jmp     HandleKeyLeft

:       cmp     #CHAR_RIGHT
        bne     :+
        bit     format_erase_overlay_flag
        jmi     format_erase_overlay__PromptHandleKeyRight
        jmp     HandleKeyRight

:       cmp     #CHAR_RETURN
        bne     :+
        bit     prompt_button_flags
        bvs     done
        jmp     HandleKeyOk

:       cmp     #CHAR_ESCAPE
        bne     :+
        bit     prompt_button_flags
        jpl     HandleKeyCancel
        jmp     HandleKeyOk

:       cmp     #CHAR_DELETE
        jeq     HandleKeyDelete

        cmp     #CHAR_UP
        bne     :+
        bit     format_erase_overlay_flag
        jpl     done
        jmp     format_erase_overlay__PromptHandleKeyUp

:       cmp     #CHAR_DOWN
        bne     :+
        bit     format_erase_overlay_flag
        jpl     done
        jmp     format_erase_overlay__PromptHandleKeyDown

:       bit     prompt_button_flags
        bvc     :+
        cmp     #kShortcutYes
        beq     do_yes
        cmp     #TO_LOWER(kShortcutYes)
        beq     do_yes
        cmp     #kShortcutNo
        beq     do_no
        cmp     #TO_LOWER(kShortcutNo)
        beq     do_no
        cmp     #kShortcutAll
        beq     do_all
        cmp     #TO_LOWER(kShortcutAll)
        beq     do_all
        cmp     #CHAR_RETURN
        beq     do_yes

:       bit     input_allow_all_chars_flag
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
        beq     fail
LA7DD:  ldx     has_input_field_flag
        beq     fail
        jsr     InputFieldInsertChar
fail:   return  #$FF

do_yes: jsr     SetPenModeXOR
        MGTK_RELAY_CALL MGTK::PaintRect, aux::yes_button_rect
        return  #PromptResult::yes

do_no:  jsr     SetPenModeXOR
        MGTK_RELAY_CALL MGTK::PaintRect, aux::no_button_rect
        return  #PromptResult::no

do_all: jsr     SetPenModeXOR
        MGTK_RELAY_CALL MGTK::PaintRect, aux::all_button_rect
        return  #PromptResult::all

.proc LeftWithMod
        lda     has_input_field_flag
        beq     :+
        jsr     InputFieldIPStart
:       return  #$FF
.endproc

.proc RightWithMod
        lda     has_input_field_flag
        beq     :+
        jsr     InputFieldIPEnd
:       return  #$FF
.endproc

.proc HandleKeyLeft
        lda     has_input_field_flag
        beq     done
        bit     format_erase_overlay_flag ; BUG? Should never be set here based on caller test.
        jmi     format_erase_overlay__PromptHandleKeyRight

        jsr     InputFieldIPLeft
done:   return  #$FF
.endproc

.proc HandleKeyRight
        lda     has_input_field_flag
        beq     done
        bit     format_erase_overlay_flag ; BUG? Should never be set here based on caller test.
        jmi     format_erase_overlay__PromptHandleKeyLeft

        jsr     InputFieldIPRight
done:   return  #$FF
.endproc

.proc HandleKeyOk
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     SetPenModeXOR
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        return  #0
.endproc

.proc HandleKeyCancel
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     SetPenModeXOR
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        return  #1
.endproc

.proc HandleKeyDelete
        lda     has_input_field_flag
        beq     :+
        jsr     InputFieldDeleteChar
:       return  #$FF
.endproc

.endproc

rts1:
        rts

;;; ============================================================

jump_relay:
        jmp     SELF_MODIFIED


;;; ============================================================
;;; "About" dialog

.proc AboutDialogProc

        kVersionLeft = winfo_about_dialog::kWidth - 90 - (7 * .strlen(kDeskTopVersionSuffix))

        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_about_dialog
        lda     #winfo_about_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     SetPenModeNotCopy
        MGTK_RELAY_CALL MGTK::SetPenSize, pensize_frame
        MGTK_RELAY_CALL MGTK::FrameRect, aux::about_dialog_frame_rect
        MGTK_RELAY_CALL MGTK::SetPenSize, pensize_normal
        jsr     SetPenModeXOR
        param_call DrawDialogTitle, aux::str_about1
        param_call DrawDialogLabel, 1 | DDL_CENTER, aux::str_about2
        param_call DrawDialogLabel, 2 | DDL_CENTER, aux::str_about3
        param_call DrawDialogLabel, 3 | DDL_CENTER, aux::str_about4
        param_call DrawDialogLabel, 5 | DDL_CENTER, aux::str_about5
        param_call DrawDialogLabel, 6 | DDL_CENTER, aux::str_about6
        param_call DrawDialogLabel, 7 | DDL_CENTER, aux::str_about7
        param_call DrawDialogLabel, 9, aux::str_about8
        copy16  #kVersionLeft, dialog_label_pos
        param_call DrawDialogLabel, 9, aux::str_about9
        copy16  #kDialogLabelDefaultX, dialog_label_pos

:       jsr     YieldLoop
        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     close
        cmp     #MGTK::EventKind::key_down
        bne     :-

close:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo_about_dialog
        jmp     ClearUpdates ; following CloseWindow
.endproc

;;; ============================================================

.proc CopyDialogProc
        ptr := $6

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::phase - copy_dialog_params
        lda     (ptr),y

        cmp     #CopyDialogLifecycle::count
        jeq     do1
        cmp     #CopyDialogLifecycle::show
        jeq     do2
        cmp     #CopyDialogLifecycle::exists
        jeq     do3
        cmp     #CopyDialogLifecycle::too_large
        jeq     do4
        cmp     #CopyDialogLifecycle::close
        jeq     do5

        ;; --------------------------------------------------
        ;; CopyDialogLifecycle::open
        copy    #0, has_input_field_flag
        jsr     OpenDialogWindow

        param_call DrawDialogLabel, 2, aux::str_copy_from
        param_call DrawDialogLabel, 3, aux::str_copy_to
        bit     move_flag
        bmi     :+
        param_call DrawDialogTitle, aux::str_copy_title
        param_call DrawDialogLabel, 1, aux::str_copy_copying
        param_call DrawDialogLabel, 4, aux::str_copy_remaining
        rts
:       param_call DrawDialogTitle, aux::str_move_title
        param_call DrawDialogLabel, 1, aux::str_move_moving
        param_call DrawDialogLabel, 4, aux::str_move_remaining
        rts

        ;; --------------------------------------------------
        ;; CopyDialogLifecycle::count
do1:    ldy     #copy_dialog_params::count - copy_dialog_params
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        MGTK_RELAY_CALL MGTK::MoveTo, aux::copy_file_count_pos
        param_call DrawString, str_file_count
        param_call_indirect DrawString, ptr_str_files_suffix
        rts

        ;; --------------------------------------------------
        ;; CopyDialogLifecycle::exists
do2:    ldy     #copy_dialog_params::count - copy_dialog_params
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     ClearTargetFileRect
        jsr     ClearDestFileRect

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::a_src - copy_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyNameToBuf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_target_file_pos
        param_call DrawDialogPath, path_buf0

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::a_dst - copy_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyNameToBuf1
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_dest_file_pos
        param_call DrawDialogPath, path_buf1

        MGTK_RELAY_CALL MGTK::MoveTo, aux::copy_file_count_pos2
        param_call DrawString, str_file_count
        param_call DrawString, str_2_spaces
        rts

        ;; --------------------------------------------------
        ;; CopyDialogLifecycle::close
do5:    jsr     ClosePromptDialog
        jsr     SetCursorPointer ; when closing dialog
        rts

        ;; --------------------------------------------------
        ;; CopyDialogLifecycle::exists
do3:    jsr     Bell
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        param_call DrawDialogLabel, 6, aux::str_exists_prompt
        jsr     DrawYesNoAllCancelButtons
:       jsr     PromptInputLoop
        bmi     :-
        pha
        jsr     EraseYesNoAllCancelButtons
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::prompt_rect
        pla
        rts

        ;; --------------------------------------------------
        ;; CopyDialogLifecycle::too_large
do4:    jsr     Bell
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        bit     move_flag
    IF_MINUS
        param_call      DrawDialogLabel, 6, aux::str_large_move_prompt
    ELSE
        param_call      DrawDialogLabel, 6, aux::str_large_copy_prompt
    END_IF
        jsr     DrawOkCancelButtons
:       jsr     PromptInputLoop
        bmi     :-
        pha
        jsr     EraseOkCancelButtons
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::prompt_rect
        pla
        rts
.endproc

;;; ============================================================
;;; "DownLoad" dialog

.proc DownloadDialogProc
        ptr := $6

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::phase - copy_dialog_params
        lda     (ptr),y
        cmp     #DownloadDialogLifecycle::count
        jeq     do1
        cmp     #DownloadDialogLifecycle::show
        jeq     do2
        cmp     #DownloadDialogLifecycle::close
        jeq     do3
        cmp     #DownloadDialogLifecycle::too_large
        jeq     do4

        ;; --------------------------------------------------
        ;; DownloadDialogLifecycle::open
        copy    #0, has_input_field_flag
        jsr     OpenDialogWindow
        param_call DrawDialogTitle, aux::str_download
        param_call DrawDialogLabel, 1, aux::str_copy_copying
        param_call DrawDialogLabel, 2, aux::str_copy_from
        param_call DrawDialogLabel, 3, aux::str_copy_to
        param_call DrawDialogLabel, 4, aux::str_copy_remaining
        rts

        ;; --------------------------------------------------
        ;; DownloadDialogLifecycle::count
do1:    ldy     #copy_dialog_params::count - copy_dialog_params
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        MGTK_RELAY_CALL MGTK::MoveTo, aux::copy_file_count_pos
        param_call DrawString, str_file_count
        param_call_indirect DrawString, ptr_str_files_suffix
        rts

        ;; --------------------------------------------------
        ;; DownloadDialogLifecycle::show
do2:    ldy     #copy_dialog_params::count - copy_dialog_params
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     ClearTargetFileRect
        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::a_src - copy_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyNameToBuf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_target_file_pos
        param_call DrawDialogPath, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::copy_file_count_pos2
        param_call DrawString, str_file_count
        param_call DrawString, str_2_spaces
        rts

        ;; --------------------------------------------------
        ;; DownloadDialogLifecycle::close
do3:    jsr     ClosePromptDialog
        jsr     SetCursorPointer ; when closing dialog
        rts

        ;; --------------------------------------------------
        ;; DownloadDialogLifecycle::too_large
do4:    jsr     Bell
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        param_call DrawDialogLabel, 6, aux::str_ramcard_full
        jsr     DrawOkButton
:       jsr     PromptInputLoop
        bmi     :-
        pha
        jsr     EraseOkButton
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::prompt_rect
        pla
        rts
.endproc

;;; ============================================================
;;; "Get Size" dialog

.proc GetSizeDialogProc
        ptr := $6

        kValueLeft = 165

        jsr     CopyDialogParamAddrToPtr
        ldy     #get_size_dialog_params::phase - get_size_dialog_params
        lda     (ptr),y
        cmp     #GetSizeDialogLifecycle::count
        jeq     do1
        cmp     #GetSizeDialogLifecycle::prompt
        jeq     do2
        cmp     #GetSizeDialogLifecycle::close
        jeq     do3

        ;; --------------------------------------------------
        ;; GetSizeDialogLifecycle::open
        jsr     OpenDialogWindow
        param_call DrawDialogTitle, aux::label_get_size
        param_call DrawDialogLabel, 1, aux::str_size_number
        ldy     #1
        jsr     DrawColon
        param_call DrawDialogLabel, 2, aux::str_size_blocks
        ldy     #2
        jsr     DrawColon
        rts

        ;; --------------------------------------------------
        ;; GetSizeDialogLifecycle::count
do1:
        ;; File Count
        ldy     #get_size_dialog_params::a_files - get_size_dialog_params
        jsr     DereferencePtrToAddr
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        copy    #kValueLeft, dialog_label_pos
        param_call DrawDialogLabel, 1, str_file_count

        ;; Size
        jsr     CopyDialogParamAddrToPtr
        ldy     #get_size_dialog_params::a_blocks - get_size_dialog_params
        jsr     DereferencePtrToAddr
        copy16in (ptr),y, file_count

        lsr16   file_count      ; Convert blocks to K, rounding up
        bcc     :+              ; NOTE: divide then maybe inc, rather than
        inc16   file_count      ; always inc then divide, to handle $FFFF
:

        jsr     ComposeFileCountString
        copy    #kValueLeft, dialog_label_pos
        dec     str_file_count  ; remove trailing space
        param_call DrawDialogLabel, 2, str_file_count
        param_call DrawString, str_kb_suffix
        rts

        ;; --------------------------------------------------
        ;; GetSizeDialogLifecycle::close
do3:    jsr     ClosePromptDialog
        jsr     SetCursorPointer ; when closing dialog
        rts

        ;; --------------------------------------------------
        ;; GetSizeDialogLifecycle::confirm
do2:
        ;; If no files were seen, `do1` was never executed and so the
        ;; counts will not be shown. Update one last time, just in case.
        jsr     do1

        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     DrawOkButton
:       jsr     PromptInputLoop
        bmi     :-
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        jsr     EraseOkButton
        return  #0
.endproc

;;; ============================================================
;;; "Delete File" dialog

.proc DeleteDialogProc
        ptr := $06

        jsr     CopyDialogParamAddrToPtr
        ldy     #delete_dialog_params::phase - delete_dialog_params
        lda     (ptr),y         ; phase

        cmp     #DeleteDialogLifecycle::count
        jeq     do1
        cmp     #DeleteDialogLifecycle::confirm
        jeq     do2
        cmp     #DeleteDialogLifecycle::show
        jeq     do3
        cmp     #DeleteDialogLifecycle::locked
        jeq     do4
        cmp     #DeleteDialogLifecycle::close
        jeq     do5

        ;; --------------------------------------------------
        ;; DeleteDialogLifecycle::open or trash
        sta     delete_flag
        copy    #0, has_input_field_flag
        jsr     OpenDialogWindow
        param_call DrawDialogTitle, aux::str_delete_title
        rts

delete_flag:                    ; clear if trash, set if delete
        .byte   0

        ;; --------------------------------------------------
        ;; DeleteDialogLifecycle::count
do1:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        lda     delete_flag
        beq     :+
        param_call DrawDialogLabel, 4, aux::str_ok_empty
        jmp     show_count
:       param_call DrawDialogLabel, 4, aux::str_delete_ok
show_count:
        param_call DrawString, str_file_count
        param_call_indirect DrawString, ptr_str_files_suffix
        rts

        ;; --------------------------------------------------
        ;; DeleteDialogLifecycle::show
do3:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     ClearTargetFileRect
        jsr     CopyDialogParamAddrToPtr
        ldy     #delete_dialog_params::a_path - delete_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyNameToBuf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_target_file_pos
        param_call DrawDialogPath, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::delete_remaining_count_pos
        param_call DrawString, str_file_count
        param_call DrawString, str_2_spaces
        rts

        ;; --------------------------------------------------
        ;; DeleteDialogLifecycle::confirm
do2:    lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     DrawOkCancelButtons
LADC4:  jsr     PromptInputLoop
        bmi     LADC4
        bne     LADF4
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        jsr     EraseOkCancelButtons
        param_call DrawDialogLabel, 2, aux::str_file_colon
        param_call DrawDialogLabel, 4, aux::str_delete_remaining
        lda     #$00
LADF4:  rts

        ;; --------------------------------------------------
        ;; DeleteDialogLifecycle::close
do5:    jsr     ClosePromptDialog
        jsr     SetCursorPointer ; when closing dialog
        rts

        ;; --------------------------------------------------
        ;; DeleteDialogLifecycle::locked
do4:    lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        param_call DrawDialogLabel, 6, aux::str_delete_locked_file
        jsr     DrawYesNoAllCancelButtons
LAE17:  jsr     PromptInputLoop
        bmi     LAE17
        pha
        jsr     EraseYesNoAllCancelButtons
        jsr     SetPenModeCopy ; white
        MGTK_RELAY_CALL MGTK::PaintRect, aux::prompt_rect ; erase prompt
        pla
        rts
.endproc

;;; ============================================================
;;; "New Folder" dialog

.proc NewFolderDialogProc

        kParentPathLeft = 55

        jsr     CopyDialogParamAddrToPtr
        ldy     #new_folder_dialog_params::phase - new_folder_dialog_params
        lda     ($06),y
        cmp     #NewFolderDialogState::run
        jeq     do_run

        cmp     #NewFolderDialogState::close
        jeq     do_close

        ;; --------------------------------------------------
        ;; NewFolderDialogState::open
        copy    #$80, has_input_field_flag
        jsr     ClearPathBuf1
        jsr     ClearPathBuf2
        lda     #$00
        jsr     OpenPromptWindow
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        param_call DrawDialogTitle, aux::label_new_folder
        jsr     FrameNameInputRect
        rts

        ;; --------------------------------------------------
        ;; NewFolderDialogState::run
do_run: copy    #$80, has_input_field_flag
        copy    #0, prompt_button_flags
        jsr     CopyDialogParamAddrToPtr
        ldy     #new_folder_dialog_params::a_path - new_folder_dialog_params
        copy16in ($06),y, $08
        param_call CopyPtr2ToBuf, path_buf0

        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        param_call DrawDialogLabel, 2, aux::str_in
        param_call DrawDialogPath, path_buf0
        param_call DrawDialogLabel, 4, aux::str_enter_folder_name
        jsr     DrawFilenamePrompt
LAEC6:  jsr     PromptInputLoop
        bmi     LAEC6
        bne     do_close
        jsr     MergePathBuf1PathBuf2
        lda     path_buf1
        beq     LAEC6
        cmp     #16             ; max filename length + 1
        bcc     LAEE1
LAED6:  lda     #kErrNameTooLong
        jsr     ShowAlert
        jsr     DrawFilenamePrompt
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

        ;; --------------------------------------------------
        ;; NewFolderDialogState::close
do_close:
        jsr     ClosePromptDialog
        jsr     SetCursorPointer ; when closing dialog
        return  #1
.endproc

;;; ============================================================
;;; "Get Info" dialog

.proc GetInfoDialogProc
        ptr := $6

        kValueLeft = 165

        jsr     CopyDialogParamAddrToPtr
        ldy     #get_info_dialog_params::state - get_info_dialog_params
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
        jsr     OpenPromptWindow
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId

        param_call DrawDialogTitle, aux::label_get_info
        jsr     CopyDialogParamAddrToPtr
        ldy     #get_info_dialog_params::state - get_info_dialog_params
        lda     (ptr),y
        and     #$7F
        lsr     a
        ror     a
        sta     is_volume_flag

        ;; Draw labels
        param_call DrawDialogLabel, 1, aux::str_info_name

        ;; Locked (file) or Protected (volume)
        bit     is_volume_flag
        bmi     :+
        param_call DrawDialogLabel, 2, aux::str_info_locked
        jmp     draw_size_label
:       param_call DrawDialogLabel, 2, aux::str_info_protected

        ;; Blocks (file) or Size (volume)
draw_size_label:
        bit     is_volume_flag
        bpl     :+
        param_call DrawDialogLabel, 3, aux::str_info_vol_size
        jmp     draw_final_labels
:       param_call DrawDialogLabel, 3, aux::str_info_file_size

draw_final_labels:
        param_call DrawDialogLabel, 4, aux::str_info_create
        param_call DrawDialogLabel, 5, aux::str_info_mod
        param_call DrawDialogLabel, 6, aux::str_info_type
        jmp     ResetMainGrafport

        ;; Draw a specific value
populate_value:
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     CopyDialogParamAddrToPtr
        ldy     #get_info_dialog_params::state - get_info_dialog_params
        copy    (ptr),y, row
        tay
        jsr     DrawColon
        copy    #kValueLeft, dialog_label_pos

        ;; Draw the string at addr
        jsr     CopyDialogParamAddrToPtr
        ldy     #get_info_dialog_params::a_path - get_info_dialog_params + 1
        lda     (ptr),y
        tax
        dey
        lda     (ptr),y
        row := *+1
        ldy     #SELF_MODIFIED_BYTE
        jsr     DrawDialogLabel

        ;; If not 6 (the last one), run modal loop
        lda     row
        cmp     #GetInfoDialogState::type
        bne     done

:       jsr     PromptInputLoop
        bmi     :-

        pha
        jsr     ClosePromptDialog
        jsr     SetCursorPointerWithFlag ; when closing dialog with prompt
        pla
done:   rts

is_volume_flag:
        .byte   0               ; high bit set if volume, clear if file
.endproc

;;; ============================================================
;;; Draw ":" after dialog label

.proc DrawColon
        kColonLeft = 160

        copy    #kColonLeft, dialog_label_pos
        param_call DrawDialogLabel, aux::str_colon
        rts
.endproc

;;; ============================================================
;;; "Lock" dialog

.proc LockDialogProc
        ptr := $06

        jsr     CopyDialogParamAddrToPtr
        ldy     #lock_unlock_dialog_params::phase - lock_unlock_dialog_params
        lda     (ptr),y

        cmp     #LockDialogLifecycle::count
        jeq     do1
        cmp     #LockDialogLifecycle::prompt
        jeq     do2
        cmp     #LockDialogLifecycle::operation
        jeq     do3
        cmp     #LockDialogLifecycle::close
        jeq     do4

        ;; --------------------------------------------------
        ;; LockDialogLifecycle::open
        copy    #0, has_input_field_flag
        jsr     OpenDialogWindow
        param_call DrawDialogTitle, aux::label_lock
        rts

        ;; --------------------------------------------------
        ;; LockDialogLifecycle::count
do1:    ldy     #lock_unlock_dialog_params::count - lock_unlock_dialog_params
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        param_call DrawDialogLabel, 4, aux::str_lock_ok
        param_call DrawString, str_file_count
        param_call_indirect DrawString, ptr_str_files_suffix
        rts

        ;; --------------------------------------------------
        ;; LockDialogLifecycle::operation
do3:    ldy     #lock_unlock_dialog_params::count - lock_unlock_dialog_params
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     ClearTargetFileRect
        jsr     CopyDialogParamAddrToPtr
        ldy     #lock_unlock_dialog_params::a_path - lock_unlock_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyNameToBuf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_target_file_pos
        param_call DrawDialogPath, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::lock_remaining_count_pos
        param_call DrawString, str_file_count
        param_call DrawString, str_2_spaces
        rts

        ;; --------------------------------------------------
        ;; LockDialogLifecycle::prompt
do2:    lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     DrawOkCancelButtons
LB0FA:  jsr     PromptInputLoop
        bmi     LB0FA
        bne     LB139
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        param_call DrawDialogLabel, 2, aux::str_file_colon
        param_call DrawDialogLabel, 4, aux::str_lock_remaining
        lda     #$00
LB139:  rts

        ;; LockDialogLifecycle::close
do4:    jsr     ClosePromptDialog
        jsr     SetCursorPointer ; when closing dialog
        rts
.endproc

;;; ============================================================
;;; "Unlock" dialog

.proc UnlockDialogProc
        ptr := $06

        jsr     CopyDialogParamAddrToPtr
        ldy     #0
        lda     (ptr),y

        cmp     #LockDialogLifecycle::count
        jeq     do1
        cmp     #LockDialogLifecycle::prompt
        jeq     do2
        cmp     #LockDialogLifecycle::operation
        jeq     do3
        cmp     #LockDialogLifecycle::close
        jeq     do4

        ;; --------------------------------------------------
        ;; LockDialogLifecycle::open
        copy    #0, has_input_field_flag
        jsr     OpenDialogWindow
        param_call DrawDialogTitle, aux::label_unlock
        rts

        ;; --------------------------------------------------
        ;; LockDialogLifecycle::count
do1:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        param_call DrawDialogLabel, 4, aux::str_unlock_ok
        param_call DrawString, str_file_count
        param_call_indirect DrawString, ptr_str_files_suffix
        rts

        ;; --------------------------------------------------
        ;; LockDialogLifecycle::operation
do3:    ldy     #1
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     ClearTargetFileRect
        jsr     CopyDialogParamAddrToPtr
        ldy     #lock_unlock_dialog_params::a_path - lock_unlock_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyNameToBuf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::current_target_file_pos
        param_call DrawDialogPath, path_buf0
        MGTK_RELAY_CALL MGTK::MoveTo, aux::unlock_remaining_count_pos
        param_call DrawString, str_file_count
        param_call DrawString, str_2_spaces
        rts

        ;; --------------------------------------------------
        ;; LockDialogLifecycle::prompt
do2:    lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     DrawOkCancelButtons
LB218:  jsr     PromptInputLoop
        bmi     LB218
        bne     LB257
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        param_call DrawDialogLabel, 2, aux::str_file_colon
        param_call DrawDialogLabel, 4, aux::str_unlock_remaining
        lda     #$00
LB257:  rts

        ;; --------------------------------------------------
        ;; LockDialogLifecycle::close
do4:    jsr     ClosePromptDialog
        jsr     SetCursorPointer ; when closing dialog
        rts
.endproc

;;; ============================================================
;;; "Rename" dialog

.proc RenameDialogProc
        params_ptr := $06

        jsr     CopyDialogParamAddrToPtr
        ldy     #rename_dialog_params::state - rename_dialog_params
        lda     (params_ptr),y
        cmp     #RenameDialogState::run
        jeq     do_run

        cmp     #RenameDialogState::close
        jeq     do_close

        ;; ----------------------------------------
        ;; RenameDialogState::open
        jsr     CopyDialogParamAddrToPtr
        copy    #$80, has_input_field_flag
        lda     #$00
        jsr     OpenPromptWindow
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        param_call DrawDialogTitle, aux::label_rename_icon
        jsr     FrameNameInputRect
        jsr     CopyDialogParamAddrToPtr
        ldy     #rename_dialog_params::a_path - rename_dialog_params
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
        jsr     ClearPathBuf2

        param_call DrawDialogLabel, 2, aux::str_rename_old
        param_call DrawString, buf_filename
        param_call DrawDialogLabel, 4, aux::str_rename_new
        jsr     DrawFilenamePrompt
        rts

        ;; --------------------------------------------------
        ;; RenameDialogState::run
do_run:
        copy    #$00, prompt_button_flags
        copy    #$80, has_input_field_flag
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
:       jsr     PromptInputLoop
        bmi     :-              ; continue?

        bne     do_close        ; canceled!

        jsr     InputFieldIPEnd ; collapse name

        lda     path_buf1
        beq     :-              ; name is empty, retry

        ldy     #<path_buf1
        ldx     #>path_buf1
        return  #0

        ;; --------------------------------------------------
        ;; RenameDialogState::close
do_close:
        jsr     ClosePromptDialog
        jsr     SetCursorPointer ; when closing dialog
        return  #1
.endproc

;;; ============================================================
;;; "Duplicate" dialog

.proc DuplicateDialogProc
        params_ptr := $06

        jsr     CopyDialogParamAddrToPtr
        ldy     #0
        lda     (params_ptr),y
        cmp     #DuplicateDialogState::run
        jeq     do_run

        cmp     #DuplicateDialogState::close
        jeq     do_close

        ;; --------------------------------------------------
        ;; DuplicateDialogState::open

        jsr     CopyDialogParamAddrToPtr
        copy    #$80, has_input_field_flag
        lda     #$00
        jsr     OpenPromptWindow
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        param_call DrawDialogTitle, aux::label_duplicate_icon
        jsr     FrameNameInputRect
        jsr     CopyDialogParamAddrToPtr
        ldy     #duplicate_dialog_params::a_path - duplicate_dialog_params
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
        jsr     ClearPathBuf2

        param_call DrawDialogLabel, 2, aux::str_duplicate_original
        param_call DrawString, buf_filename
        param_call DrawDialogLabel, 4, aux::str_rename_new
        jsr     DrawFilenamePrompt
        rts

        ;; --------------------------------------------------
        ;; DuplicateDialogState::run
do_run:
        copy    #$00, prompt_button_flags
        copy    #$80, has_input_field_flag
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
:       jsr     PromptInputLoop
        bmi     :-              ; continue?

        bne     do_close        ; canceled!

        jsr     InputFieldIPEnd ; collapse name

        lda     path_buf1
        beq     :-              ; name is empty, retry

        ldy     #<path_buf1
        ldx     #>path_buf1
        return  #0

        ;; --------------------------------------------------
        ;; DuplicateDialogState::run
do_close:
        jsr     ClosePromptDialog
        jsr     SetCursorPointer ; when closing dialog
        return  #1
.endproc

;;; ============================================================

.proc CopyDialogParamAddrToPtr
        copy16  dialog_param_addr, $06
        rts
.endproc

;;; ============================================================
;;; Convert a pointer-to-pointer to just a pointer.
;;; Inputs: $06,Y references an address
;;; Outputs: $06 set to that address, and Y=0 for quick use

.proc DereferencePtrToAddr
        ptr := $06
        lda     (ptr),y
        tax
        iny
        lda     (ptr),y
        sta     ptr+1
        stx     ptr
        ldy     #0
        rts
.endproc

;;; ============================================================

.proc SetCursorPointerWithFlag
        bit     cursor_ibeam_flag
        bpl     :+
        jsr     SetCursorPointer ; toggle routine
        copy    #0, cursor_ibeam_flag
:       rts
.endproc

.proc SetCursorIBeamWithFlag
        bit     cursor_ibeam_flag
        bmi     :+
        jsr     SetCursorIBeam ; toggle routine
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

.proc MLIRelayImpl
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
        ldy     #3      ; ptr is off by 1
:       lda     (params_src),y
        sta     params-1,y
        dey
        bne     :-

        ;; Bank and call
        sta     ALTZPOFF
        bit     ROMIN2

        jsr     MLI
params:  .res    3

        sta     ALTZPON
        php
        bit     LCBANK1
        bit     LCBANK1
        plp
        rts
.endproc

;;; ============================================================

.proc SetCursorWatch
        MGTK_RELAY_CALL MGTK::SetCursor, watch_cursor
        rts
.endproc

.proc SetCursorPointer
        MGTK_RELAY_CALL MGTK::SetCursor, pointer_cursor
        rts
.endproc

.proc SetCursorIBeam
        MGTK_RELAY_CALL MGTK::SetCursor, ibeam_cursor
        rts
.endproc

;;; ============================================================
;;; Double Click Detection
;;; Returns with A=0 if double click, A=$FF otherwise.

.proc StashCoordsAndDetectDoubleClick
        ;; Stash coords for double-click in windows
        COPY_STRUCT MGTK::Point, event_params::coords, drag_drop_params::coords

        jmp     DetectDoubleClick
.endproc

;;; ============================================================

.proc OpenPromptWindow
        sta     prompt_button_flags
        jsr     OpenDialogWindow
        bit     prompt_button_flags
        bvc     :+
        jsr     DrawYesNoAllCancelButtons
        jmp     no_ok

:       jsr     DrawOkFrameAndLabel
no_ok:  bit     prompt_button_flags
        bmi     done
        jsr     DrawCancelFrameAndLabel
done:   jmp     ResetMainGrafport
.endproc

;;; ============================================================

.proc OpenDialogWindow
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_prompt_dialog
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     SetPenModeNotCopy
        MGTK_RELAY_CALL MGTK::SetPenSize, pensize_frame
        MGTK_RELAY_CALL MGTK::FrameRect, aux::confirm_dialog_frame_rect
        MGTK_RELAY_CALL MGTK::SetPenSize, pensize_normal
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        rts
.endproc

;;; ============================================================

;;; Draw dialog label.
;;; A,X has pointer to DrawText params block
;;; Y has row number (1, 2, ... ) with high bit to center it

        DDL_CENTER = $80

.proc DrawDialogLabel
        textwidth_params := $8
        textptr := $8
        textlen := $A
        result  := $B

        ptr := $6

        stx     ptr+1
        sta     ptr
        tya
        jpl     skip

        ;; Compute text width and center it
        and     #$7F            ; strip "center?" flag
        pha
        add16   ptr, #1, textptr
        ldax    ptr
        jsr     AuxLoad
        sta     textlen
        MGTK_RELAY_CALL MGTK::TextWidth, textwidth_params
        lsr16   result
        sub16   #aux::kPromptDialogWidth/2, result, dialog_label_pos
        pla

        ;; y = base + aux::kDialogLabelHeight * line
skip:   ldx     #0
        ldy     #aux::kDialogLabelHeight
        jsr     Multiply_16_8_16
        stax    dialog_label_pos::ycoord
        add16   dialog_label_pos::ycoord, dialog_label_base_pos::ycoord, dialog_label_pos::ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, dialog_label_pos
        param_call_indirect DrawString, ptr
        ldx     dialog_label_pos
        copy    #kDialogLabelDefaultX,dialog_label_pos::xcoord ; restore original x coord
        rts
.endproc

;;; ============================================================

;;; Set up clipping to draw a path (long string) in a dialog
;;; without intruding into the border.
;;; Inputs: A,X = string address
.proc DrawDialogPath
        stax    string
        param_call GetPortBits, tmp_mapinfo
        MGTK_RELAY_CALL MGTK::SetPortBits, aux::prompt_dialog_labels_mapinfo
        ldax    string
        jsr     DrawString
        MGTK_RELAY_CALL MGTK::SetPortBits, tmp_mapinfo
        rts

string: .addr   0
.endproc

;;; ============================================================

;;; Caller must set XOR penmode
.proc DrawOkFrameAndLabel
        MGTK_RELAY_CALL MGTK::FrameRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::MoveTo, aux::ok_button_pos
        param_call DrawString, aux::ok_button_label
        rts
.endproc

;;; Caller must set XOR penmode
.proc DrawCancelFrameAndLabel
        MGTK_RELAY_CALL MGTK::FrameRect, aux::cancel_button_rect
        MGTK_RELAY_CALL MGTK::MoveTo, aux::cancel_button_pos
        param_call DrawString, aux::cancel_button_label
        rts
.endproc

.proc DrawYesNoAllCancelButtons
        jsr     SetPenModeXOR

        MGTK_RELAY_CALL MGTK::FrameRect, aux::yes_button_rect
        MGTK_RELAY_CALL MGTK::MoveTo, aux::yes_button_pos
        param_call DrawString, aux::yes_button_label

        MGTK_RELAY_CALL MGTK::FrameRect, aux::no_button_rect
        MGTK_RELAY_CALL MGTK::MoveTo, aux::no_button_pos
        param_call DrawString, aux::no_button_label

        MGTK_RELAY_CALL MGTK::FrameRect, aux::all_button_rect
        MGTK_RELAY_CALL MGTK::MoveTo, aux::all_button_pos
        param_call DrawString, aux::all_button_label

        jsr     DrawCancelFrameAndLabel
        copy    #$40, prompt_button_flags
        rts
.endproc

.proc EraseYesNoAllCancelButtons
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::yes_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::no_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::all_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        rts
.endproc

.proc DrawOkCancelButtons
        jsr     SetPenModeXOR
        jsr     DrawOkFrameAndLabel
        jsr     DrawCancelFrameAndLabel
        copy    #$00, prompt_button_flags
        rts
.endproc

.proc EraseOkCancelButtons
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::cancel_button_rect
        rts
.endproc

.proc DrawOkButton
        jsr     SetPenModeXOR
        jsr     DrawOkFrameAndLabel
        copy    #$80, prompt_button_flags
        rts
.endproc

.proc EraseOkButton
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        rts
.endproc

;;; ============================================================

.proc DrawString
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

.proc DrawDialogTitle
        text_params     := $6
        text_addr       := text_params + 0
        text_length     := text_params + 2
        text_width      := text_params + 3

        stax    text_addr       ; input is length-prefixed string
        jsr     AuxLoad
        sta     text_length
        inc16   text_addr        ; point past length byte
        MGTK_RELAY_CALL MGTK::TextWidth, text_params

        sub16   #aux::kPromptDialogWidth, text_width, pos_dialog_title::xcoord
        lsr16   pos_dialog_title::xcoord ; /= 2
        MGTK_RELAY_CALL MGTK::MoveTo, pos_dialog_title
        MGTK_RELAY_CALL MGTK::DrawText, text_params
        rts
.endproc

;;; ============================================================

        .define LIB_MLI_CALL MLI_RELAY_CALL
        ADJUSTCASE_VOLPATH := $810
        ADJUSTCASE_VOLBUF  := $820
        ADJUSTCASE_IO_BUFFER := IO_BUFFER
        .include "../lib/adjustfilecase.s"
        .undefine LIB_MLI_CALL

;;; ============================================================

.proc NoOp
        rts
.endproc

;;; ============================================================

.proc RedrawPromptInsertionPoint
        point := $6
        xcoord := $6
        ycoord := $8

        jsr     MeasurePathBuf1
        stax    xcoord
        copy16  name_input_textpos::ycoord, ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, point
        jsr     SetNameInputClipRect
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
        textptr := drawtext_params + 0
        textlen := drawtext_params + 2

draw:   copy16  #str_insertion_point+1, textptr
        copy    str_insertion_point, textlen
        MGTK_RELAY_CALL MGTK::DrawText, drawtext_params
        MGTK_RELAY_CALL MGTK::SetTextBG, aux::textbg_white
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        rts
.endproc

;;; ============================================================

.proc DrawFilenamePrompt
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, name_input_rect
        jsr     FrameNameInputRect
        MGTK_RELAY_CALL MGTK::MoveTo, name_input_textpos
        jsr     SetNameInputClipRect
        param_call DrawString, path_buf1
        param_call DrawString, path_buf2
        param_call DrawString, str_2_spaces
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
done:   rts
.endproc

.proc FrameNameInputRect
        jsr     SetPenModeNotCopy
        MGTK_RELAY_CALL MGTK::FrameRect, name_input_rect
        rts
.endproc

.proc SetNameInputClipRect
        MGTK_RELAY_CALL MGTK::SetPortBits, name_input_mapinfo
        rts
.endproc

;;; ============================================================

.proc HandleClickInTextbox
        ptr := $6

        PARAM_BLOCK tw_params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        click_coords := screentowindow_params::windowx

        ;; Mouse coords to window coords; is click inside name field?
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, click_coords
        MGTK_RELAY_CALL MGTK::InRect, name_input_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        rts

        ;; Is it to the right of the text?
:       jsr     MeasurePathBuf1

        width := $6

        stax    width
        cmp16   click_coords, width
        bcs     ToRight
        jmp     ToLeft

;;; --------------------------------------------------

        ;; Click is to the right of IP

.proc ToRight
        jsr     MeasurePathBuf1
        stax    ip_pos

        ldx     path_buf2
        inx
        copy    #' ', path_buf2,x ; append space at end
        inc     path_buf2

        ;; Iterate to find the position
        copy16  #path_buf2, tw_params::data
        copy    path_buf2, tw_params::length
@loop:  MGTK_RELAY_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, ip_pos, tw_params::width
        cmp16   tw_params::width, click_coords
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bne     @loop

        dec     path_buf2
        jmp     finish

        ;; Was it to the right of the string?
:       lda     tw_params::length
        cmp     path_buf2
        bcc     :+
        dec     path_buf2          ; remove appended space
        jmp     InputFieldIPEnd ; use this shortcut

        ;; Append from `path_buf2` into `path_buf0`
:       ldx     #2
        ldy     path_buf1
        iny
:       lda     path_buf2,x
        sta     path_buf1,y
        cpx     tw_params::length
        beq     :+
        iny
        inx
        jmp     :-
:       sty     path_buf1

        ;; Shift contents of `path_buf2` down,
        ;; preserving IP at the start.
        ldy     #2
        ldx     tw_params::length
        inx
:       lda     path_buf2,x
        sta     path_buf2,y
        cpx     path_buf2
        beq     :+
        iny
        inx
        jmp     :-

:       dey
        sty     path_buf2
        jmp     finish
.endproc

;;; --------------------------------------------------

        ;; Click to left of IP

.proc ToLeft
        ;; Iterate to find the position
        copy16  #path_buf1, tw_params::data
        copy    path_buf1, tw_params::length
:       MGTK_RELAY_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, name_input_textpos::xcoord, tw_params::width
        cmp16   tw_params::width, click_coords
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bcs     :-
        jmp     InputFieldIPStart

        ;; Found position; copy everything to the right of
        ;; the new position from `path_buf1` to `buf_text`
:       inc     tw_params::length
        ldy     #0
        ldx     tw_params::length
:       cpx     path_buf1
        beq     :+
        inx
        iny
        lda     path_buf1,x
        sta     buf_text+1,y
        jmp     :-
:       iny
        sty     buf_text

        ;; Append `path_buf2` to `buf_text`
        ldx     #1
        ldy     buf_text
:       cpx     path_buf2
        beq     :+
        inx
        iny
        lda     path_buf2,x
        sta     buf_text,y
        jmp     :-
:       sty     buf_text

        ;; Copy IP and `buf_text` into `path_buf2`
        copy    #kGlyphInsertionPoint, buf_text+1
:       lda     buf_text,y
        sta     path_buf2,y
        dey
        bpl     :-

        ;; Adjust length
        lda     tw_params::length
        sta     path_buf1
        ;; fall through
.endproc

finish: jsr     DrawFilenamePrompt
        rts

ip_pos: .word   0
.endproc

;;; ============================================================
;;; When a non-control key is hit - insert the passed character

.proc InputFieldInsertChar
        sta     char

        ;; Is there room?
        lda     path_buf1
        clc
        adc     path_buf2
        cmp     #$10            ; max name length
        bcc     :+
        rts
:
        point := $6
        xcoord := $6
        ycoord := $8

        ;; Insert, and redraw single char and right string
        char := *+1
        lda     #SELF_MODIFIED_BYTE
        ldx     path_buf1
        inx
        sta     path_buf1,x
        sta     str_1_char+1
        jsr     MeasurePathBuf1 ; measure before extending
        inc     path_buf1
        stax    xcoord
        copy16  name_input_textpos::ycoord, ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, point
        jsr     SetNameInputClipRect
        param_call DrawString, str_1_char
        param_call DrawString, path_buf2
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        rts
.endproc

;;; ============================================================
;;; When delete (backspace) is hit - shrink left buffer by one

.proc InputFieldDeleteChar
        ;; Anything to delete?
        lda     path_buf1
        beq     ret

        point := $6
        xcoord := $6
        ycoord := $8

        ;; Decrease length of left string, measure and redraw right string
        dec     path_buf1
        jsr     MeasurePathBuf1
        stax    xcoord
        copy16  name_input_textpos::ycoord, ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, point
        jsr     SetNameInputClipRect
        param_call DrawString, path_buf2
        param_call DrawString, str_2_spaces
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId

ret:    rts
.endproc

;;; ============================================================
;;; Move IP one character left.

.proc InputFieldIPLeft
        ;; Any characters to left of IP?
        lda     path_buf1
        beq     ret

        point := $6
        xcoord := $6
        ycoord := $8

        ldx     path_buf2
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
        jsr     MeasurePathBuf1
        stax    xcoord
        copy16  name_input_textpos::ycoord, ycoord
        MGTK_RELAY_CALL MGTK::MoveTo, point
        jsr     SetNameInputClipRect
        param_call DrawString, path_buf2
        param_call DrawString, str_2_spaces
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId

ret:    rts
.endproc

;;; ============================================================
;;; Move IP one character right.

.proc InputFieldIPRight
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
        jsr     SetNameInputClipRect
        param_call DrawString, path_buf1
        param_call DrawString, path_buf2
        param_call DrawString, str_2_spaces
        lda     #winfo_prompt_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        rts
.endproc

;;; ============================================================
;;; Move IP to start of input field.

.proc InputFieldIPStart
        ;; Any characters to left of IP?
        lda     path_buf1
        beq     ret

        ;; Any characters to right of IP?
        ldx     path_buf2
        cpx     #1
        beq     move

        ;; Preserve right characters up to make room.
        ;; TODO: Why not just shift them up???
loop1:  lda     path_buf2,x
        sta     buf_text-1,x
        dex
        cpx     #1
        bne     loop1
        ldx     path_buf2

        ;; Move characters left to right
move:   dex
        stx     buf_text
        ldx     path_buf1
loop2:  lda     path_buf1,x
        sta     path_buf2+1,x
        dex
        bne     loop2

        ;; Adjust lengths.
        copy    #kGlyphInsertionPoint, path_buf2+1
        inc     path_buf1
        lda     path_buf1
        sta     path_buf2
        lda     path_buf1
        clc
        adc     buf_text
        tay
        pha

        ;; Append right right characters again if needed.
        ldx     buf_text
        beq     finish
loop3:  lda     buf_text,x
        sta     path_buf2,y
        dex
        dey
        cpy     path_buf2
        bne     loop3

finish: pla
        sta     path_buf2
        copy    #0, path_buf1
        jsr     DrawFilenamePrompt

ret:    rts
.endproc

;;; ============================================================

.proc MergePathBuf1PathBuf2
        lda     path_buf2
        cmp     #2
        bcc     done

        ;; Compute new `path_buf1` length
        ldx     path_buf2
        dex
        txa
        clc
        adc     path_buf1
        pha

        ;; Copy chars from `path_buf2` to `path_buf1`
        tay
        ldx     path_buf2
loop:   lda     path_buf2,x
        sta     path_buf1,y
        dex
        dey
        cpy     path_buf1
        bne     loop

        ;; Finish up, shrinking `path_buf2` to just an insertion point
        pla
        sta     path_buf1
        copy    #1, path_buf2

done:   rts
.endproc

;;; ============================================================
;;; Move IP to end of input field.

.proc InputFieldIPEnd
        jsr     MergePathBuf1PathBuf2
        jsr     DrawFilenamePrompt
        rts
.endproc

;;; ============================================================
;;; Compute width of `path_buf1`, offset `name_input_textpos`, return x coord in (A,X)

.proc MeasurePathBuf1
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

.proc ClearPathBuf2
        copy    #1, path_buf2   ; length
        copy    #kGlyphInsertionPoint, path_buf2+1
        rts
.endproc

.proc ClearPathBuf1
        copy    #0, path_buf1   ; length
        rts
.endproc

;;; ============================================================

;;; Adjusted to point at file/files (singular/plural)
ptr_str_files_suffix:
        .addr   str_files_suffix

;;; ============================================================
;;; Populate `str_file_count` based on `file_count`. As a side
;;; effect, adjusts `ptr_str_files_suffix` as well, on the
;;; assumption it may be output as well.

.proc ComposeFileCountString
        ;; Populate `str_file_count`
        ldax    file_count
        jsr     IntToStringWithSeparators

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

        ;; Adjust `ptr_str_files_suffix`
        lda     file_count+1    ; > 255?
        bne     :+
        lda     file_count
        cmp     #1
        bne     :+

        copy16  #str_file_suffix, ptr_str_files_suffix ; singular
        rts

:       copy16  #str_files_suffix, ptr_str_files_suffix ; plural
        rts
.endproc

;;; ============================================================

.proc CopyNameToBuf0
        param_jump CopyPtr1ToBuf, path_buf0
.endproc

.proc CopyNameToBuf1
        param_jump CopyPtr1ToBuf, path_buf1
.endproc

;;; ============================================================

.proc ClearTargetFileRect
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::current_target_file_rect
        rts
.endproc

.proc ClearDestFileRect
        jsr     SetPenModeCopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::current_dest_file_rect
        rts
.endproc

;;; ============================================================

.proc GetEvent
        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        rts
.endproc

.proc PeekEvent
        MGTK_RELAY_CALL MGTK::PeekEvent, event_params
        rts
.endproc

.proc SetPenModeXOR
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        rts
.endproc

.proc SetPenModeCopy
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        rts
.endproc

.proc SetPenModeNotCopy
        MGTK_RELAY_CALL MGTK::SetPenMode, notpencopy
        rts
.endproc

;;; ============================================================

.proc ResetMainGrafport
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        rts
.endproc

;;; ============================================================

.proc ClosePromptDialog
        jsr     ResetMainGrafport
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_prompt_dialog
        jmp     ClearUpdates ; following CloseWindow
.endproc

;;; ============================================================
;;; Output: A = number of selected icons

.proc GetSelectionCount
        lda     selected_icon_count
        rts
.endproc

;;; ============================================================
;;; Input: A = index in selection
;;; Output: A,X = IconEntry address

.proc GetSelectedIcon
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

.proc GetSelectionWindow
        lda     selected_window_id
        rts
.endproc

;;; ============================================================
;;; Determine if an icon is in the current selection.
;;; Inputs: A=icon number
;;; Outputs: Z=1 if found, X=index in `selected_icon_list`
;;; X modified, A,Y preserved

.proc IsIconSelected

        ;; TODO: Update to use highlight bit in IconEntry::state

        ldx     selected_icon_count
        beq     nope
        dex
:       cmp     selected_icon_list,x
        beq     done            ; found it!
        dex
        bpl     :-

nope:   ldx     #$FF            ; clear Z = failure

done:   rts
.endproc

;;; ============================================================
;;; Inputs: A = window id
;;; Outputs: Z = 1 if found, and X = index in `window_id_to_filerecord_list_entries`

.proc FindIndexInFilerecordListEntries
        ldx     window_id_to_filerecord_list_count
        dex
:       cmp     window_id_to_filerecord_list_entries,x
        beq     :+
        dex
        bpl     :-
:       rts
.endproc

;;; ============================================================
;;; Outputs: A = kViewBy* value for active window
;;; If kViewByIcon, Z=1 and N=0; otherwise Z=0 and N=1
;;; Assert: There is an active/cached window

.proc GetActiveWindowViewBy
        ldx     active_window_id
        dex
        lda     win_view_by_table,x
        rts
.endproc

.proc GetCachedWindowViewBy
        ldx     cached_window_id
        dex
        lda     win_view_by_table,x
        rts
.endproc

;;; ============================================================

.proc ToggleMenuHilite
        lda     menu_click_params::menu_id
        beq     :+
        MGTK_RELAY_CALL MGTK::HiliteMenu, menu_click_params
:       rts
.endproc

;;; ============================================================
;;; Determine if mouse moved (returns w/ carry set if moved)
;;; Used in dialogs to possibly change cursor

.proc CheckMouseMoved
        ldx     #.sizeof(MGTK::Point)-1
:       lda     event_params::coords,x
        cmp     coords,x
        bne     diff
        dex
        bpl     :-
        clc
        rts

diff:   COPY_STRUCT MGTK::Point, event_params::coords, coords
        sec
        rts

        DEFINE_POINT coords, 0, 0

.endproc

;;; ============================================================

;;; ============================================================
;;; Save/Restore window state at shutdown/launch

.scope save_restore_windows
        desktop_file_io_buf := IO_BUFFER
        desktop_file_data_buf := $1800
        kFileSize = 1 + 8 * .sizeof(DeskTopFileItem) + 1

        DEFINE_CREATE_PARAMS create_params, str_desktop_file, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_params, str_desktop_file, desktop_file_io_buf
        DEFINE_READ_PARAMS read_params, desktop_file_data_buf, kFileSize
        DEFINE_READ_PARAMS write_params, desktop_file_data_buf, kFileSize
        DEFINE_CLOSE_PARAMS close_params
str_desktop_file:
        PASCAL_STRING kFilenameDeskTopState

.proc Save
        data_ptr := $06
        winfo_ptr := $08

        ;; Write file format version byte
        copy    #kDeskTopFileVersion, desktop_file_data_buf

        copy16  #desktop_file_data_buf+1, data_ptr

        ;; Get first window pointer
        MGTK_RELAY_CALL MGTK::FrontWindow, window_id
        lda     window_id
        beq     finish
        jsr     WindowLookup
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
        jsr     WriteWindowInfo
        depth := *+1            ; Last window?
        lda     #SELF_MODIFIED_BYTE
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
        jsr     WriteOutFile

        ;; If DeskTop was copied to RAMCard, also write to original prefix.
        jsr     GetCopiedToRAMCardFlag
        bpl     exit
        param_call CopyDeskTopOriginalPrefix, path_buffer
        param_call AppendFilenameToPathBuffer, str_desktop_file
        lda     #<path_buffer
        sta     create_params::pathname
        sta     open_params::pathname
        lda     #>path_buffer
        sta     create_params::pathname+1
        sta     open_params::pathname+1
        jsr     WriteOutFile

exit:   rts

.proc WriteWindowInfo
        path_ptr := $0A
        bounds := tmp_rect

        ;; Find name
        ldy     #MGTK::Winfo::window_id
        lda     (winfo_ptr),y
        jsr     GetWindowPath
        stax    path_ptr

        ;; Copy name in
        ldy     #::kPathBufferSize-1
:       lda     (path_ptr),y
        sta     (data_ptr),y
        dey
        bpl     :-

        ;; Assemble rect
        ;; Compute width/height from port's maprect
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     (winfo_ptr),y
        sta     bounds,x
        dey
        dex
        bpl     :-
        sub16   bounds + MGTK::Rect::x2, bounds + MGTK::Rect::x1, bounds + MGTK::Rect::x2
        sub16   bounds + MGTK::Rect::y2, bounds + MGTK::Rect::y1, bounds + MGTK::Rect::y2

        ;; Now top/left from port's viewloc
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + .sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     (winfo_ptr),y
        sta     bounds,x
        dey
        dex
        bpl     :-

        ;; Copy bounds in
        ldy     #DeskTopFileItem::rect+.sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     bounds,x
        sta     (data_ptr),y
        dey
        dex
        bpl     :-

        ;; Offset to next entry
        add16_8 data_ptr, #.sizeof(DeskTopFileItem)
        rts

.endproc                        ; WriteWindowInfo

window_id := findwindow_params::window_id

.endproc                        ; save

.proc Open
        MLI_RELAY_CALL OPEN, open_params
        rts
.endproc

.proc Close
        MLI_RELAY_CALL CLOSE, close_params
        rts
.endproc

.proc WriteOutFile
        MLI_RELAY_CALL CREATE, create_params
        jsr     Open
        bcs     :+
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_RELAY_CALL WRITE, write_params
        jsr     Close
:       rts
.endproc

.endscope ; save_restore_windows
SaveWindows := save_restore_windows::Save

;;; ============================================================

;;; Test if either modifier (Open-Apple or Solid-Apple) is down.
;;; Output: A=high bit/N flag set if either is down.

.proc ModifierDown
        lda     BUTN0
        ora     BUTN1
        rts
.endproc

;;; Test if either primary modifier (Open-Apple) or shift is down,
;;; (if shift key can be detected).
;;; Output: A=high bit/N flag set if either is down.

.proc ExtendSelectionModifierDown
        ;; IIgs? Use KEYMODREG instead
        bit     machine_config::iigs_flag
        bmi     iigs

        jsr     TestShiftMod  ; Shift key state, if detectable
        ora     BUTN0           ; Either way, check button state
        rts

        ;; IIgs - do everything using one I/O location
iigs:   lda     KEYMODREG
        and     #%10000001      ; bit 7 = Command (OA), bit 0 = Shift
        beq     ret
        lda     #$80
ret:    rts
.endproc

;;; Test if shift is down (if it can be detected).
;;; Output: A=high bit/N flag set if down.

.proc ShiftDown
        bit     machine_config::iigs_flag
        bpl     TestShiftMod    ; no, rely on shift key mod

        lda     KEYMODREG       ; On IIgs, use register instead
        and     #%00000001      ; bit 7 = Command (OA), bit 0 = Shift
        beq     ret
        lda     #$80
ret:    rts
.endproc

;;; Compare the shift key mod state. Returns high bit set if
;;; not the initial state (i.e. Shift key is likely down), if
;;; detectable.

.proc TestShiftMod
        ;; If a IIe, maybe use shift key mod
        ldx     machine_config::id_idbyte ; $00 = IIc/IIc+
        ldy     machine_config::id_idlaser ; $AC = Laser 128
        lda     #0
        cpx     #0              ; ZIDBYTE = $00 == IIc/IIc+
        beq     :+
        cpy     #$AC            ; IDBYTELASER128 = $AC = Laser 128
        beq     :+              ; On Laser, BUTN2 set when mouse button clicked

        ;; It's a IIe, compare shift key state
        lda     machine_config::pb2_initial_state ; if shift key mod installed, %1xxxxxxx
        eor     BUTN2             ; ... and if shift is down, %0xxxxxxx

:       rts
.endproc

;;; ============================================================
;;; Reformat /RAM (Slot 3, Drive 2) if present
;;; Assumes ROM is banked in, restores it when complete. Also
;;; assumes hires screen (main and aux) are safe to destroy.

.proc MaybeReformatRam
        ;; Search DEVLST to see if S3D2 RAM was restored
        ldx     DEVCNT
:       lda     DEVLST,x
        and     #%11110000      ; DSSSnnnn
        cmp     #$B0            ; Slot 2, Drive 2 = /RAM
        beq     format
        dex
        bpl     :-
        rts

        ;; NOTE: Assumes driver (in DEVADR) was not modified
        ;; when detached.

        ;; /RAM FORMAT call; see ProDOS 8 TRM 5.2.2.4 for details
format: lda     DEVLST,x
        and     #UNIT_NUM_MASK
        sta     DRIVER_UNIT_NUMBER
        copy    #DRIVER_COMMAND_FORMAT, DRIVER_COMMAND
        copy16  #$2000, DRIVER_BUFFER
        bit     LCBANK1
        bit     LCBANK1
        jsr     driver
        bit     ROMIN2
        rts

RAMSLOT := DEVADR + $16         ; Slot 3, Drive 2

driver: jmp     (RAMSLOT)
.endproc

;;; ============================================================

        .include "../lib/datetime.s"
        .include "../lib/is_diskii.s"

;;; ============================================================

        PAD_TO $BF00

.endscope ; main
        main__PopPointers := main::PopPointers
        main__PushPointers := main::PushPointers
        main__YieldLoop := main::YieldLoop
