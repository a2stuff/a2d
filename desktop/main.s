;;; ============================================================
;;; Desktop - Main Memory Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        .include "../disk_copy/disk_copy.inc"

;;; ============================================================
;;; Segment loaded into MAIN $4000-$BEFF
;;; ============================================================

        BEGINSEG SegmentDeskTopMain

.scope main

        MLIEntry  := MLIRelayImpl
        MGTKEntry := ::MGTKRelayImpl
        LETKEntry := LETKRelayImpl
        BTKEntry := BTKRelayImpl
        ITKEntry  := ITKRelayImpl

kShortcutResize = res_char_resize_shortcut
kShortcutMove   = res_char_move_shortcut
kShortcutScroll = res_char_scroll_shortcut

src_path_buf    := INVOKER_PREFIX
dst_path_buf    := $1F80

        ;; Jump table
        ;; Entries marked with * are used by DAs
        ;; "Exported" by desktop.inc

JT_MGTK_CALL:           jmp     ::MGTKRelayImpl         ; *
JT_MLI_CALL:            jmp     MLIRelayImpl            ; *
JT_CLEAR_UPDATES:       jmp     ClearUpdates            ; *
JT_YIELD_LOOP:          jmp     YieldLoop               ; *
JT_SELECT_WINDOW:       jmp     SelectAndRefreshWindow  ; *
JT_SHOW_ALERT:          jmp     ShowAlert               ; *
JT_SHOW_ALERT_OPTIONS:  jmp     ShowAlertOption
JT_LAUNCH_FILE:         jmp     LaunchFileWithPath
JT_SHOW_FILE:           jmp     ShowFileWithPath        ; *
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
JT_ADJUST_VOLNAME:      jmp     AdjustVolumeNameCase    ; *
JT_GET_RAMCARD_FLAG:    jmp     GetCopiedToRAMCardFlag  ; *
JT_GET_ORIG_PREFIX:     jmp     CopyDeskTopOriginalPrefix ; *
JT_BELL:                jmp     Bell                    ; *
JT_SLOW_SPEED:          jmp     SlowSpeed               ; *
JT_RESUME_SPEED:        jmp     ResumeSpeed             ; *
JT_READ_SETTING:        jmp     ReadSetting             ; *

        .assert JUMP_TABLE_LAST = *, error, "Jump table mismatch"

        ;; Main Loop
.proc MainLoop
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
.endproc ; CheckDrive

.endproc ; MainLoop

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
        copy    active_window_id, saved_active_window_id
        jmp     handle_update   ; skip PeekEvent

;;; Clear any pending updates.
clear:
        copy    active_window_id, saved_active_window_id
        FALL_THROUGH_TO loop

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
        MGTK_CALL MGTK::BeginUpdate, event_params::window_id
        ITK_CALL IconTK::DrawAll, event_params::window_id
        MGTK_CALL MGTK::EndUpdate
        jmp     loop

        ;; Window
win:    MGTK_CALL MGTK::BeginUpdate, event_params::window_id
        bne     :+            ; obscured
        jsr     UpdateWindow
        MGTK_CALL MGTK::EndUpdate
:       jmp     loop

finish:
        saved_active_window_id := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     active_window_id
        rts
.endproc ; ClearUpdatesImpl
ClearUpdatesNoPeek := ClearUpdatesImpl::clear_no_peek
ClearUpdates := ClearUpdatesImpl::clear

;;; ============================================================
;;; Called by main and nested event loops to do periodic tasks.
;;; Returns 0 if the periodic tasks were run.

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
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
.endproc ; YieldLoop

;;; ============================================================

.proc UpdateWindow
        lda     event_params::window_id
        cmp     #kMaxDeskTopWindows+1 ; directory windows are 1-8
        bcc     :+
        rts

:       sta     active_window_id
        jsr     LoadActiveWindowEntryTable

        ;; This correctly uses the clipped port provided by BeginUpdate.

        ;; `DrawWindowHeader` relies on `window_grafport` for dimensions
        copy    cached_window_id, getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        jsr     DrawWindowHeader

        ;; Overwrite the Winfo's port with the maprect we got for the update
        ;; since downstream calls will use the Winfo's port.
        lda     active_window_id
        jsr     SwapWindowPortbits
        jsr     OverwriteWindowPort

        winfo_ptr := $06

        ;; Determine the update's maprect is already below the header; if
        ;; not, we need to offset the maprect below the header.
        lda     active_window_id
        jsr     WindowLookup
        stax    winfo_ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        sub16in (winfo_ptr),y, window_grafport::viewloc::ycoord, yoff
        scmp16  yoff, #kWindowHeaderHeight
        bpl     skip_adjust_port

        ;; Adjust grafport to account for header
        jsr     OffsetWindowGrafport

        ;; MGTK doesn't like offscreen grafports, so if we end up with
        ;; nothing to draw, skip drawing!
        ;; https://github.com/a2stuff/a2d/issues/369
        ldx     #MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        scmp16  window_grafport,x, #kScreenHeight
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
        lda     #kDrawWindowEntriesContentOnlyPortAdjusted
        jsr     DrawWindowEntries

done:
        ;; Restore window's port
        lda     active_window_id
        jmp     SwapWindowPortbits

yoff:   .word   0
.endproc ; UpdateWindow

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
        .addr   CmdCopySelection
        .addr   CmdDeleteSelection
        .addr   CmdNoOp         ; --------
        .addr   CmdQuit
        ASSERT_ADDRESS_TABLE_SIZE menu2_start, ::kMenuSizeFile

        ;; View menu (3)
        menu3_start := *
        .addr   CmdViewBy
        .addr   CmdViewBy
        .addr   CmdViewBy
        .addr   CmdViewBy
        .addr   CmdViewBy
        .addr   CmdViewBy
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
        cmp     #'`'
        jeq     CmdHighlightAlphaNext ; like Tab
        cmp     #'~'
        jeq     CmdHighlightAlphaPrev ; like Shift+Tab
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
        jsr     UpcaseChar
        cmp     #res_char_menu_item_open_shortcut
        jeq     CmdOpenThenCloseCurrent
        cmp     #CHAR_DOWN
        jeq     CmdOpenThenCloseCurrent
        cmp     #CHAR_UP
        jeq     CmdOpenParentThenCloseCurrent
        cmp     #res_char_menu_item_close_shortcut
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
        MGTK_CALL MGTK::MenuKey, menu_click_params

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
        MGTK_CALL MGTK::HiliteMenu, menu_click_params
        copy    #0, menu_click_params::menu_id ; for `ToggleMenuHilite`
        rts

call_proc:
        tsx
        stx     saved_stack
        proc_addr := *+1
        jmp     SELF_MODIFIED
.endproc ; HandleKeydownImpl

HandleKeydown   := HandleKeydownImpl::HandleKeydown
MenuDispatch2   := HandleKeydownImpl::MenuDispatch2
window_open_flag := HandleKeydownImpl::window_open_flag

;;; ============================================================
;;; Handle click

.proc HandleClick
        tsx
        stx     saved_stack
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        bne     not_desktop

        ;; Click on desktop
        copy    #0, findwindow_params::window_id
        ITK_CALL IconTK::FindIcon, event_params::coords
        lda     findicon_params::which_icon
        jne     HandleVolumeIconClick

        jsr     LoadDesktopEntryTable
        lda     #0
        jmp     DragSelect

not_desktop:
        cmp     #MGTK::Area::menubar  ; menu?
        bne     not_menu
        copy    #0, menu_kbd_flag ; note that source is not keyboard
        MGTK_CALL MGTK::MenuSelect, menu_click_params
        jmp     MenuDispatch2

not_menu:
        pha                     ; A = MGTK::Area::*

        ;; Activate if needed
        lda     active_window_id
        cmp     findwindow_params::window_id
    IF_NE
        jsr     ClearSelection
        jsr     ActivateWindow
    END_IF

        pla                     ; A = MGTK::Area::*
        jsr     dispatch_click

        lda     selected_icon_count
    IF_ZERO
        ;; Try to select the window's parent icon. (Only works
        ;; for volume icons, otherwise it would put selection
        ;; in an inactive window.)
        lda     active_window_id
        jne     SelectIconForWindow
    END_IF
        rts

dispatch_click:
        cmp     #MGTK::Area::content
        jeq     HandleClientClick
        cmp     #MGTK::Area::dragbar
        jeq     HandleTitleClick
        cmp     #MGTK::Area::grow_box
        jeq     HandleResizeClick
        cmp     #MGTK::Area::close_box
        jeq     HandleCloseClick
        rts
.endproc ; HandleClick

;;; ============================================================
;;; Activate the window, and sets selection to its parent icon
;;; Inputs: window id to activate in `findwindow_params::window_id`

.proc ActivateWindowAndSelectIcon
        jsr     ClearSelection
        jsr     ActivateWindow

        ;; Try to select the window's parent icon. (Only works
        ;; for volume icons, otherwise it would put selection
        ;; in an inactive window.)
        lda     active_window_id
        jmp     SelectIconForWindow
.endproc ; ActivateWindowAndSelectIcon

;;; ============================================================
;;; Activate the window, draw contents, and update menu items
;;; Inputs: window id to activate in `findwindow_params::window_id`

.proc ActivateWindow
        ;; Make the window active.
        MGTK_CALL MGTK::SelectWindow, findwindow_params::window_id
        copy    findwindow_params::window_id, active_window_id
        jsr     UpdateWindowUsedFreeDisplayValues
        jsr     LoadActiveWindowEntryTable
        lda     #kDrawWindowEntriesHeaderAndContent
        jsr     DrawWindowEntries

        ;; Update menu items
        jsr     UncheckViewMenuItem
        FALL_THROUGH_TO CheckViewMenuItemForActiveWindow
.endproc ; ActivateWindow

.proc CheckViewMenuItemForActiveWindow
        jsr     GetActiveWindowViewBy
        and     #kViewByMenuMask
        sta     checkitem_params::menu_item
        inc     checkitem_params::menu_item
        jmp     CheckViewMenuItem
.endproc ; CheckViewMenuItemForActiveWindow

;;; ============================================================
;;; Inputs: A = window_id
;;; Selection should be cleared before calling

.proc SelectIconForWindow
        icon_ptr := $06

        ;; Select window's corresponding volume icon.
        ;; (Doesn't work for folder icons as only the active
        ;; window and desktop can have selections.)
        tax
        lda     window_to_dir_icon_table-1,x
        bmi     done            ; $FF = dir icon freed

        sta     icon_param
        jsr     GetIconEntry
        stax    icon_ptr

        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        beq     :+               ; desktop - selection ok
        cmp     active_window_id ; This should never be true
        bne     done
:
        sta     selected_window_id
        copy    #1, selected_icon_count
        copy    icon_param, selected_icon_list
        ITK_CALL IconTK::HighlightIcon, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param

done:   rts
.endproc ; SelectIconForWindow

;;; ============================================================

;;; Used only for file windows; adjusts port to account for header.
;;; Returns 0 if ok, `MGTK::Error::window_obscured` if the window is obscured.
.proc UnsafeOffsetAndSetPortFromWindowId
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     :+              ; MGTK::Error::window_obscured
        jsr     OffsetWindowGrafportAndSet
        lda     #0
:       rts
.endproc ; UnsafeOffsetAndSetPortFromWindowId

;;; Used for all sorts of windows, not just file windows.
;;; For file windows, used for drawing headers (sometimes);
;;; Returns 0 if ok, `MGTK::Error::window_obscured` if the window is obscured.
.proc UnsafeSetPortFromWindowId
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     :+              ; MGTK::Error::window_obscured
        MGTK_CALL MGTK::SetPort, window_grafport
:       rts
.endproc ; UnsafeSetPortFromWindowId

;;; Used for windows that can never be obscured (e.g. dialogs)
        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc SafeSetPortFromWindowId
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Result is not MGTK::Error::window_obscured
        MGTK_CALL MGTK::SetPort, window_grafport
        rts
.endproc ; SafeSetPortFromWindowId

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
.endproc ; CheckDiskInsertedEjected

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

        unit_number := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     FindSmartportDispatchAddress
        bcs     notsp           ; not SmartPort
        stax    dispatch
        sty     status_unit_num

        ;; Execute SmartPort call
        dispatch := *+1
        jsr     SELF_MODIFIED
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

        ;; params for call
        DEFINE_SP_STATUS_PARAMS status_params, 1, status_buffer, 0
        status_unit_num := status_params::unit_num
.endproc ; CheckDisksInDevices

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

        ;; Single?
        cmp     #1
        bne     multi
        lda     selected_icon_list
        cmp     trash_icon_num
        beq     no_selection    ; trash only - treat as no selection
        jsr     EnableMenuItemsRequiringSingleSelection
        jmp     :+
multi:  jsr     DisableMenuItemsRequiringSingleSelection
:
        ;; Files or Volumes?
        lda     selected_window_id ; In a window?
        beq     :+

        ;; --------------------------------------------------
        ;; Files selected (not volumes)

        jsr     DisableMenuItemsRequiringVolumeSelection
        jsr     EnableMenuItemsRequiringFileSelection
        jmp     EnableMenuItemsRequiringSelection

        ;; --------------------------------------------------
        ;; Volumes selected (not files)

:       jsr     EnableMenuItemsRequiringVolumeSelection
        jsr     DisableMenuItemsRequiringFileSelection
        jmp     EnableMenuItemsRequiringSelection

        ;; --------------------------------------------------
        ;; No Selection
no_selection:
        jsr     DisableMenuItemsRequiringVolumeSelection
        jsr     DisableMenuItemsRequiringFileSelection
        jsr     DisableMenuItemsRequiringSelection
        jmp     DisableMenuItemsRequiringSingleSelection

.endproc ; UpdateMenuItemStates

;;; ============================================================
;;; Common re-used param blocks

        DEFINE_GET_FILE_INFO_PARAMS file_info_params, SELF_MODIFIED
        DEFINE_GET_FILE_INFO_PARAMS src_file_info_params, src_path_buf
        DEFINE_GET_FILE_INFO_PARAMS dst_file_info_params, dst_path_buf

        .assert src_path_buf = INVOKER_PREFIX, error, "Params re-use"

;;; Call GET_FILE_INFO on path at A,X; results are in `file_info_params`
;;; Output: MLI result (carry/zero flag, etc)
.proc GetFileInfo
        stax    file_info_params::pathname
        MLI_CALL GET_FILE_INFO, file_info_params
        rts
.endproc ; GetFileInfo

;;; Call GET_FILE_INFO on file at `src_path_buf` a.k.a. `INVOKER_PREFIX`
;;; Output: MLI result (carry/zero flag, etc), `src_file_info_params` populated
.proc GetSrcFileInfo
        MLI_CALL GET_FILE_INFO, src_file_info_params
        rts
.endproc ; GetSrcFileInfo

;;; Call SET_FILE_INFO on file at `src_path_buf` a.k.a. `INVOKER_PREFIX`
;;; Input: `src_file_info_params` used
;;; Output: MLI result (carry/zero flag, etc)
.proc SetSrcFileInfo
        copy    #7, src_file_info_params::param_count ; SET_FILE_INFO
        MLI_CALL SET_FILE_INFO, src_file_info_params
        pha
        copy    #$A, src_file_info_params::param_count ; GET_FILE_INFO
        pla
        rts
.endproc ; SetSrcFileInfo

;;; Call GET_FILE_INFO on file at `dst_path_buf`
;;; Output: MLI result (carry/zero flag, etc), `dst_file_info_params` populated
.proc GetDstFileInfo
        MLI_CALL GET_FILE_INFO, dst_file_info_params
        rts
.endproc ; GetDstFileInfo

;;; ============================================================

;;; Additional path buffer used by a handful of locations where
;;; MLI calls require it to be in main memory.
;;; * Prefer `src_path_buf` unless it's already in use
;;; * Prefer `dst_path_buf`, but it's inside `IO_BUFFER`
tmp_path_buf:
        .res    ::kPathBufferSize, 0

;;; ============================================================
;;; Launch file (File > Open, Selector menu, or double-click)
;;; Inputs: Path in `src_path_buf` (a.k.a. `INVOKER_PREFIX`)

.proc LaunchFileWithPath
        jsr     SetCursorWatch ; before invoking

        ;; Get the file info to determine type.
        jsr     GetSrcFileInfo
        beq     :+
        jmp     ShowAlert

        ;; Check file type.
:       copy    src_file_info_params::file_type, icontype_filetype
        copy16  src_file_info_params::aux_type, icontype_auxtype
        copy16  src_file_info_params::blocks_used, icontype_blocks
        copy16  #src_path_buf, icontype_filename
        jsr     GetIconType

        ;; Handler based on type
        asl                     ; *= 4
        asl
        tax

        lda     invoke_table+0,x
        sta     handler
        lda     invoke_table+1,x
        sta     handler+1
        lda     invoke_table+2,x
        pha
        lda     invoke_table+3,x
        tax
        pla
        handler := *+1
        jmp     SELF_MODIFIED

        ;; --------------------------------------------------
        ;; Fallback - try BASIS.SYSTEM
fallback:
        jsr     CheckBasisSystem ; Is fallback BASIS.SYSTEM present?
        beq     launch           ; yes, continue below
        lda     #kErrFileNotOpenable
        jmp     ShowAlert

        ;; --------------------------------------------------
        ;; Launch interpreter (system file that accepts path).
interpreter:
        ptr1 := $06
        stax    ptr1            ; save for later

        ;; Is the interpreter where we expect it?
        jsr     GetFileInfo
        jcs     SetCursorPointer ; nope, just ignore

        ;; Construct absolute path
        MLI_CALL GET_PREFIX, get_prefix_params ; into `INVOKER_INTERPRETER`
        ldax    ptr1
        jsr     AppendToInvokerInterpreter
        FALL_THROUGH_TO launch

        ;; --------------------------------------------------
        ;; Generic launch
launch:
        param_call UpcaseString, INVOKER_PREFIX
        param_call UpcaseString, INVOKER_INTERPRETER
        jsr     SplitInvokerPath

        copy16  #INVOKER, reset_and_invoke_target
        jmp     ResetAndInvoke

        ;; --------------------------------------------------
        ;; BASIC program
basic:  jsr     CheckBasicSystem ; Only launch if BASIC.SYSTEM is found
        jeq     launch
        lda     #kErrBasicSysNotFound
        jmp     ShowAlert

        ;; --------------------------------------------------
        ;; Binary file
binary:
        lda     menu_click_params::menu_id ; From a menu (File, Selector)
        jne     launch
        jsr     ModifierDown ; Otherwise, only launch if a button is down
        jmi     launch
        lda     #kErrConfirmRunning
        jsr     ShowAlert       ; show a prompt otherwise
        cmp     #kAlertResultOK
        jeq     launch
        jmp     SetCursorPointer ; after not launching BIN

;;; --------------------------------------------------

.macro INVOKE_TABLE_ENTRY handler, param
        .addr   handler
        .addr   param
.endmacro

invoke_table:
        INVOKE_TABLE_ENTRY      fallback, 0                    ; generic
        INVOKE_TABLE_ENTRY      InvokeDeskAcc, str_preview_txt ; text
        INVOKE_TABLE_ENTRY      binary, 0                      ; binary
        INVOKE_TABLE_ENTRY      InvokeDeskAcc, str_preview_fot ; graphics
        INVOKE_TABLE_ENTRY      fallback, 0                    ; animation
        INVOKE_TABLE_ENTRY      InvokeDeskAcc, str_preview_mus ; music
        INVOKE_TABLE_ENTRY      fallback, 0                    ; audio
        INVOKE_TABLE_ENTRY      InvokeDeskAcc, str_preview_fnt ; font
        INVOKE_TABLE_ENTRY      fallback, 0                    ; relocatable
        INVOKE_TABLE_ENTRY      fallback, 0                    ; command
        INVOKE_TABLE_ENTRY      OpenFolder, 0                  ; folder
        INVOKE_TABLE_ENTRY      fallback, 0                    ; iigs
        INVOKE_TABLE_ENTRY      interpreter, str_awlauncher    ; appleworks_wp
        INVOKE_TABLE_ENTRY      interpreter, str_awlauncher    ; appleworks_sp
        INVOKE_TABLE_ENTRY      interpreter, str_awlauncher    ; appleworks_db
        INVOKE_TABLE_ENTRY      interpreter, str_unshrink      ; archive
        INVOKE_TABLE_ENTRY      interpreter, str_binscii       ; encoded
        INVOKE_TABLE_ENTRY      InvokeDeskAccWithSelection, 0  ; desk_accessory
        INVOKE_TABLE_ENTRY      basic, 0                       ; basic
        INVOKE_TABLE_ENTRY      interpreter, str_intbasic      ; intbasic
        INVOKE_TABLE_ENTRY      launch, 0                      ; system
        INVOKE_TABLE_ENTRY      launch, 0                      ; application
        ASSERT_RECORD_TABLE_SIZE invoke_table, IconType::COUNT, 4

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
        param_call AppendToInvokerInterpreter, str_basix_system
        param_call GetFileInfo, interp_path
        bne     pop_segment

        rts                     ; zero is success
.endproc ; CheckBasixSystemImpl
CheckBasisSystem        := CheckBasixSystemImpl::basis

.proc CheckBasicSystem
        MLI_CALL GET_PREFIX, get_prefix_params

        ldax    #str_extras_basic
        jsr     AppendToInvokerInterpreter
        param_call GetFileInfo, INVOKER_INTERPRETER
        jne     CheckBasixSystemImpl::basic ; nope, look relative to launch path
        rts
.endproc ; CheckBasicSystem

;;; --------------------------------------------------

;;; Input: A,X = relative path to append
;;; Output: `INVOKER_INTERPRETER` updated
;;; Trashes: $06
.proc AppendToInvokerInterpreter
        ptr1 := $06
        stax    ptr1

        ldy     #0
        ldx     INVOKER_INTERPRETER
        lda     (ptr1),y
        sta     len
:       iny
        inx
        lda     (ptr1),y
        sta     INVOKER_INTERPRETER,x
        len := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     :-
        stx     INVOKER_INTERPRETER

        rts
.endproc ; AppendToInvokerInterpreter

;;; --------------------------------------------------

.proc OpenFolder
        tsx
        stx     saved_stack

        jsr     OpenWindowForPath

        jmp     SetCursorPointer ; after opening folder
.endproc ; OpenFolder

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, INVOKER_INTERPRETER

.endproc ; LaunchFileWithPath

;;; ============================================================

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc UpcaseChar
        cmp     #'a'
        bcc     done
        cmp     #'z'+1
        bcs     done
        and     #CASE_MASK
done:   rts
.endproc ; UpcaseChar

;;; ============================================================
;;; Uppercase a string
;;; Input: A,X = Address
;;; Trashes $06

.proc UpcaseString
        ptr := $06

        stax    ptr
        ldy     #$00
        lda     (ptr),y
        beq     ret
        tay
@loop:  lda     (ptr),y
        jsr     UpcaseChar
        sta     (ptr),y
        dey
        bne     @loop
ret:    rts
.endproc ; UpcaseString


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
.endproc ; IsAlpha

;;; ============================================================

kBSOffset       = 5             ; Offset of 'x' in BASIx.SYSTEM
str_basix_system:
        PASCAL_STRING "BASIx.SYSTEM"

str_extras_basic:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/BASIC.system")

str_intbasic:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/IntBASIC.system")

str_awlauncher:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/AWLaunch.system")

str_unshrink:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/UnShrink")

str_binscii:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/BinSCII")

str_preview_fot:
        PASCAL_STRING .concat(kFilenamePreviewDir, "/show.image.file")

str_preview_fnt:
        PASCAL_STRING .concat(kFilenamePreviewDir, "/show.font.file")

str_preview_txt:
        PASCAL_STRING .concat(kFilenamePreviewDir, "/show.text.file")

str_preview_mus:
        PASCAL_STRING .concat(kFilenamePreviewDir, "/show.duet.file")

;;; ============================================================

str_empty:
        PASCAL_STRING ""

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
.endproc ; RestoreDeviceList

;;; Backup copy of DEVLST made before reordering and detaching offline devices
devlst_backup:
        .res    ::kMaxDevListSize+1, 0 ; +1 for DEVCNT itself

;;; ============================================================

.proc CmdNoOp
        rts
.endproc ; CmdNoOp

;;; ============================================================

.proc CmdSelectorAction
        ;; If adding, try to default to the current selection.
        lda     menu_click_params::item_num
        cmp     #kMenuItemIdSelectorAdd
    IF_EQ
        lda     #0
        sta     path_buf0

        ;; If there's a selection, put it in `path_buf0`
        lda     selected_window_id
        beq     :+
        lda     selected_icon_count
        beq     :+

        jsr     CopyAndComposeWinIconPaths
        jne     ShowAlert

        COPY_STRING src_path_buf, path_buf0
:
    END_IF

        lda     #kDynamicRoutineSelector1 ; selector picker dialog
        jsr     LoadDynamicRoutine
        bmi     done

        lda     menu_click_params::item_num
        cmp     #SelectorAction::delete
        bcs     invoke     ; delete or run (no need for more overlays)

        lda     #kDynamicRoutineSelector2 ; file dialog driver
        jsr     LoadDynamicRoutine
        bmi     done
        lda     #kDynamicRoutineFileDialog ; file dialog
        jsr     LoadDynamicRoutine
        bmi     done

invoke:
        ;; Invoke routine
        lda     menu_click_params::item_num
        jsr     selector_picker__Exec
        sta     result

        ;; Restore from overlays
        ;; (restore from file dialog overlay handled in picker overlay)
        lda     #kDynamicRoutineRestore9000 ; restore from picker dialog
        jsr     RestoreDynamicRoutine

        bit     result
        bmi     done            ; N=1 for Cancel

        lda     menu_click_params::item_num
        cmp     #SelectorAction::run
        bne     done

        ;; "Run" command
        result := *+1
        lda     #SELF_MODIFIED_BYTE
        jmp     InvokeSelectorEntry

done:   rts
.endproc ; CmdSelectorAction

;;; ============================================================

.proc CmdSelectorItem
        lda     menu_click_params::item_num
        sec
        sbc     #6              ; 4 items + separator (and make 0 based)

        FALL_THROUGH_TO InvokeSelectorEntry
.endproc ; CmdSelectorItem

;;; ============================================================

;;; A = `entry_num`
.proc InvokeSelectorEntry
        ptr := $06
        entry_path := tmp_path_buf

        sta     entry_num

        ;; Stash path, which may be from the picker (if not in the
        ;; primary list) and may be trashed (if the entry is copied
        ;; to RAMCard later.
        jsr     SetEntryPathPtr
        param_call CopyPtr1ToBuf, entry_path

        ;; Is there a RAMCard at all?
        jsr     GetCopiedToRAMCardFlag
        beq     use_entry_path  ; no RAMCard, skip

        ;; Look at the entry's flags
        lda     entry_num
        jsr     SetEntryPtr

        ldy     #kSelectorEntryFlagsOffset ; flag byte following name
        lda     (ptr),y
        .assert kSelectorEntryCopyOnBoot = 0, error, "enum mismatch"
        beq     on_boot
        cmp     #kSelectorEntryCopyNever
        beq     use_entry_path  ; not copied

        ;; --------------------------------------------------
        ;; `kSelectorEntryCopyOnUse`
        ldx     entry_num
        jsr     GetEntryCopiedToRAMCardFlag
        bmi     use_ramcard_path ; already copied!

        ;; Need to copy to RAMCard
        jsr     PrepEntryCopyPaths
        jsr     DoCopyToRAM
        bne     ret             ; canceled!

        ldx     entry_num
        lda     #$FF
        jsr     SetEntryCopiedToRAMCardFlag
        jmp     use_ramcard_path

        ;; --------------------------------------------------
        ;; `kSelectorEntryCopyOnBoot`
on_boot:
        ldx     entry_num
        jsr     GetEntryCopiedToRAMCardFlag
        bpl     use_entry_path  ; wasn't copied!
        FALL_THROUGH_TO use_ramcard_path

        ;; --------------------------------------------------
        ;; Copied to RAMCard - use copied path
use_ramcard_path:
        jsr     ComposeRAMCardEntryPath
        stax    ptr
        jmp     launch

        ;; --------------------------------------------------
        ;; Not copied to RAMCard - just use entry's path
use_entry_path:
        copy16  #entry_path, ptr
        FALL_THROUGH_TO launch

launch: param_call CopyPtr1ToBuf, INVOKER_PREFIX
        jmp     LaunchFileWithPath

ret:    rts

entry_num:
        .byte   0

;;; --------------------------------------------------
;;; Input: `entry_path` is populated
;;; Output: paths prepared for `DoCopyToRAM`
.proc PrepEntryCopyPaths
        entry_original_path := $800
        entry_ramcard_path := $840

        COPY_STRING entry_path, entry_original_path

        ;; Copy "down loaded" path to `entry_ramcard_path`
        jsr     ComposeRAMCardEntryPath
        stax    ptr
        param_call CopyPtr1ToBuf, entry_ramcard_path

        ;; Strip segment off path at `entry_original_path`
        ;; e.g. "/VOL/MOUSEPAINT/MP.SYSTEM" -> "/VOL/MOUSEPAINT"

        ldy     entry_original_path
:       lda     entry_original_path,y
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       dey
        sty     entry_original_path

        ;; Strip segment off path at `entry_ramcard_path`
        ;; e.g. "/RAM/MOUSEPAINT/MP.SYSTEM" -> "/RAM/MOUSEPAINT"
        ldy     entry_ramcard_path
:       lda     entry_ramcard_path,y
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       dey
        sty     entry_ramcard_path

        ;; Further prepare paths for copy
        copy16  #entry_original_path, $06
        copy16  #entry_ramcard_path, $08
        jmp     CopyPathsFromPtrsToBufsAndSplitName
.endproc ; PrepEntryCopyPaths

;;; --------------------------------------------------
;;; Compose path using RAM card prefix plus last two segments of path
;;; (e.g. "/RAM" + "/MOUSEPAINT/MP.SYSTEM") into `src_path_buf`
;;; Input: `entry_path` is populated
;;; Output: A,X = `src_path_buf`
.proc ComposeRAMCardEntryPath
        ;; Initialize buffer
        param_call CopyRAMCardPrefix, src_path_buf
        ldy     entry_path

        ;; Walk back one segment
:       lda     entry_path,y
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       dey

        ;; Walk back a second segment
:       lda     entry_path,y
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       dey

        ;; Append last two segments to `src_path_buf`
        ldx     src_path_buf
:       inx
        iny
        lda     entry_path,y
        sta     src_path_buf,x
        cpy     entry_path
        bne     :-

        stx     src_path_buf
        ldax    #src_path_buf
        rts
.endproc ; ComposeRAMCardEntryPath

;;; --------------------------------------------------
;;; Input: A = entry num
;;; Output: $06 points at entry
;;; NOTE: If in the "primary" list, points at the permanently loaded
;;; copy. Otherwise, assumes the picker just ran and points at the
;;; temporarily loaded copy.
.proc SetEntryPtr
        ptr := $06

        cmp     #kSelectorListNumPrimaryRunListEntries
        bcs     secondary
        jsr     ATimes16
        addax   #run_list_entries, ptr
        rts

secondary:
        jsr     ATimes16
        addax   #SELECTOR_FILE_BUF + kSelectorListEntriesOffset, ptr
        rts
.endproc ; SetEntryPtr

;;; --------------------------------------------------
;;; Input: A = entry num
;;; Output: $06 points at entry path
;;; NOTE: If in the "primary" list, points at the permanently loaded
;;; copy. Otherwise, assumes the picker just ran and points at the
;;; temporarily loaded copy.
.proc SetEntryPathPtr
        ptr := $06

        cmp     #kSelectorListNumPrimaryRunListEntries
        bcs     secondary
        jsr     ATimes64
        addax   #run_list_paths, ptr
        rts

secondary:
        jsr     ATimes64
        addax   #SELECTOR_FILE_BUF + kSelectorListPathsOffset, ptr
        rts
.endproc ; SetEntryPathPtr

.endproc ; InvokeSelectorEntry

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
.endproc ; CopyPtr1ToBuf

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
.endproc ; CopyPtr2ToBuf

;;; ============================================================

.proc CmdAbout
        param_jump InvokeDialogProc, kIndexAboutDialog, $0000
.endproc ; CmdAbout

;;; ============================================================

.proc CmdDeskaccImpl
        ptr := $6
        path := INVOKER_PREFIX

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, path

str_desk_acc:
        PASCAL_STRING .concat(kFilenameDADir, "/")

start:  jsr     SetCursorWatch  ; before loading DA

        ;; Get current prefix
        MLI_CALL GET_PREFIX, get_prefix_params

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
.endproc ; CmdDeskaccImpl
CmdDeskAcc      := CmdDeskaccImpl::start

;;; ============================================================
;;; Invoke a DA, with path set to first file selection
;;; Input: `src_path_buf` has DA path

.proc InvokeDeskAccWithSelection
        ;; * Can't use `dst_path_buf` as it is within DA_IO_BUFFER
        ;; * Can't use `src_path_buf` as it holds file selection
        COPY_STRING src_path_buf, tmp_path_buf ; Use this to launch the DA

        copy    #0, src_path_buf ; Signal no file selection

        ;; As a convenience for DAs, set path to first selected file.
        lda     selected_window_id
        beq     :+              ; not a file
        lda     selected_icon_count
        beq     :+              ; no selection
        jsr     CopyAndComposeWinIconPaths
        jne     ShowAlert
:
        ldax    #tmp_path_buf
        FALL_THROUGH_TO InvokeDeskAcc
.endproc ; InvokeDeskAccWithSelection

;;; ============================================================
;;; Invoke Desk Accessory
;;; Input: A,X = address of pathname buffer

.proc InvokeDeskAcc
        stax    open_pathname

        ;; Load the DA
@retry: MLI_CALL OPEN, open_params
        beq     :+
        lda     #kErrInsertSystemDisk
        jsr     ShowAlert
        cmp     #kAlertResultOK
        beq     @retry          ; ok, so try again
        rts                     ; cancel, so fail
:
        lda     open_ref_num
        sta     read_header_ref_num
        sta     read_ref_num
        sta     close_ref_num
        MLI_CALL READ, read_header_params

        lda     DAHeader__aux_length
        ora     DAHeader__aux_length+1
        beq     main

        ;; Aux memory segment
        copy16  DAHeader__aux_length, read_request_count
        MLI_CALL READ, read_params
        copy16  #DA_LOAD_ADDRESS, STARTLO
        copy16  #DA_LOAD_ADDRESS, DESTINATIONLO
        add16   #DA_LOAD_ADDRESS-1, DAHeader__aux_length, ENDLO
        sec ; main>aux
        jsr     AUXMOVE

        ;; Main memory segment
main:   copy16  DAHeader__main_length, read_request_count
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_params

        ;; Invoke it
        jsr     SetCursorPointer ; before invoking DA
        jsr     DA_LOAD_ADDRESS

        ;; Restore state
        jsr     InitSetDesktopPort ; DA's port destroyed, set something real as current
        jsr     ShowClockForceUpdate
        jmp     SetCursorPointer ; after invoking DA

.params DAHeader
aux_length:     .word   0
main_length:    .word   0
.endparams
        DAHeader__aux_length := DAHeader::aux_length
        DAHeader__main_length := DAHeader::main_length

        DEFINE_OPEN_PARAMS open_params, 0, DA_IO_BUFFER
        open_ref_num := open_params::ref_num
        open_pathname := open_params::pathname

        DEFINE_READ_PARAMS read_header_params, DAHeader, .sizeof(DAHeader)
        read_header_ref_num := read_header_params::ref_num

        DEFINE_READ_PARAMS read_params, DA_LOAD_ADDRESS, kDAMaxSize
        read_ref_num := read_params::ref_num
        read_request_count := read_params::request_count

        DEFINE_CLOSE_PARAMS close_params
        close_ref_num := close_params::ref_num

.endproc ; InvokeDeskAcc

;;; ============================================================

.proc CmdCopySelection
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
        jsr     PushPointers    ; $06 = dst
        jsr     ClearUpdates    ; following picker dialog close
        jsr     PopPointers     ; $06 = dst
        pla                     ; A = dialog result
        bpl     :+
        rts
:
        ;; --------------------------------------------------
        ;; Try the copy

        param_call CopyPtr1ToBuf, path_buf3
        jsr     DoCopySelection

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

.endproc ; CmdCopySelection

;;; ============================================================
;;; Copy string at ($6) to `path_buf3`, string at ($8) to `path_buf4`,
;;; split filename off `path_buf4` and store in `filename_buf`

.proc CopyPathsFromPtrsToBufsAndSplitName

        ;; Copy string at $6 to `path_buf3`
        param_call CopyPtr1ToBuf, path_buf3

        ;; Copy string at $8 to `path_buf4`
        param_call CopyPtr2ToBuf, path_buf4
        FALL_THROUGH_TO SplitPathBuf4
.endproc ; CopyPathsFromPtrsToBufsAndSplitName

;;; Split filename off `path_buf4` and store in `filename_buf`
;;; If a volume name, splits off leading "/" (e.g. "/VOL" to "/" and "VOL")
.proc SplitPathBuf4
        param_call FindLastPathSegment, path_buf4
        cpy     path_buf4
        beq     volume

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

        ;; Y = path length
volume:
        dey
        sty     filename_buf
:       lda     path_buf4+1,y
        sta     filename_buf,y
        dey
        bne     :-
        copy    #1, path_buf4
        rts
.endproc ; SplitPathBuf4

;;; ============================================================
;;; Split filename off `INVOKER_PREFIX` into `INVOKER_FILENAME`

.proc SplitInvokerPath
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

        rts
.endproc ; SplitInvokerPath

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
        ;; Entry point from OA+SA+O / OA+SA+Down

open_then_close_current:
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
        FALL_THROUGH_TO common

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
        jsr     GetIconEntry
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

        jsr     CopyAndComposeWinIconPaths
        jne     ShowAlert

        jmp     LaunchFileWithPath
.endproc ; CmdOpen
CmdOpenThenCloseCurrent := CmdOpen::open_then_close_current
CmdOpenFromDoubleClick := CmdOpen::from_double_click
CmdOpenFromKeyboard := CmdOpen::from_keyboard

;;; ============================================================

;;; Close parent window after open, if needed. Done by activating then closing.
;;; Input: `window_id_to_close` set by caller.
;;; Modifies `findwindow_params::window_id`
.proc MaybeCloseWindowAfterOpen
        lda     window_id_to_close
        beq     done

        jsr     CloseSpecifiedWindow

done:   rts
.endproc ; MaybeCloseWindowAfterOpen

;;; Parent window to close
window_id_to_close:
        .byte   0

;;; ============================================================
;;; Copy selection window and first selected icon paths to
;;; `buf_win_path` and `buf_filename` respectively, and
;;; compose into `src_path_buf`.
;;; Output: Z=1/A=0 on success, Z=0/A=error if path too long

.proc CopyAndComposeWinIconPaths
        ;; Copy window path to buf_win_path
        win_path_ptr := $06

        lda     selected_window_id
        jsr     GetWindowPath
        stax    win_path_ptr
        param_call CopyPtr1ToBuf, buf_win_path

        ;; Copy file path to buf_filename
        icon_ptr := $06

        lda     selected_icon_list
        jsr     GetIconEntry
        stax    icon_ptr
        ldy     #IconEntry::name

        lda     (icon_ptr),y    ; check length
        clc
        adc     buf_win_path
        cmp     #kMaxPathLength ; not +1 because we'll add '/'
        bcc     :+
        lda     #ERR_INVALID_PATHNAME
        rts
:
        lda     (icon_ptr),y
        tax
        clc
        adc     #IconEntry::name
        tay
:       lda     (icon_ptr),y
        sta     buf_filename,x
        dey
        dex
        bpl     :-

        ;; Compose window path plus icon path
        ldx     #$FF
:       inx
        copy    buf_win_path,x, src_path_buf,x
        cpx     buf_win_path
        bne     :-

        inx
        copy    #'/', src_path_buf,x

        ldy     #0
:       iny
        inx
        copy    buf_filename,y, src_path_buf,x
        cpy     buf_filename
        bne     :-
        stx     src_path_buf

        lda     #0              ; success
        rts
.endproc ; CopyAndComposeWinIconPaths


;;; ============================================================

.proc CmdOpenParentImpl

close_current:
        lda     active_window_id
        .byte   OPC_BIT_abs     ; Skip next 2-byte instruction
normal: lda     #0
        sta     window_id_to_close

        lda     active_window_id
        beq     done

        jsr     GetWindowPath
        jsr     CopyToSrcPath
        copy    src_path_buf, prev ; previous length

        ;; Try removing last segment
        param_call FindLastPathSegment, src_path_buf ; point Y at last '/'
        cpy     src_path_buf

        beq     volume
        sty     src_path_buf

        ;; --------------------------------------------------
        ;; Windowed

        ;; Try to open by path.
        tsx
        stx     saved_stack
        jsr     OpenWindowForPath

        ;; Calc the name
        name_ptr := $08
        copy16  #src_path_buf, name_ptr
        inc     src_path_buf           ; past the '/'
        add16_8 name_ptr, src_path_buf ; point at suffix
        prev := *+1
        lda     #SELF_MODIFIED_BYTE
        sec
        sbc     src_path_buf ; A = name length
        ldy     #0
        sta     (name_ptr),y    ; assign string length

        jsr     PushPointers
        jsr     MaybeCloseWindowAfterOpen
        jsr     PopPointers

        ;; Select by name (if not already done via close)
        lda     selected_icon_count
    IF_ZERO
        param_call_indirect SelectFileIconByName, name_ptr
    END_IF

done:   rts

        ;; --------------------------------------------------
        ;; Find volume icon by name and select it.

volume: lda     window_id_to_close
        beq     :+
        jsr     CloseActiveWindow
:       jsr     ClearSelection
        ldx     src_path_buf ; Strip '/'
        dex
        stx     src_path_buf+1
        ldax    #src_path_buf+1
        ldy     #0              ; 0=desktop
        jsr     FindIconByName
        beq     :+
        jsr     SelectIcon
:       rts
.endproc ; CmdOpenParentImpl
CmdOpenParent := CmdOpenParentImpl::normal
CmdOpenParentThenCloseCurrent := CmdOpenParentImpl::close_current

;;; ============================================================

.proc CmdClose
        lda     active_window_id
        bne     :+
        rts

:       jmp     CloseActiveWindow
.endproc ; CmdClose

;;; ============================================================

.proc CmdCloseAll
        lda     active_window_id  ; current window
        beq     done              ; nope, done!
        jsr     CloseActiveWindow ; close it...
        jmp     CmdCloseAll       ; and try again
done:   rts
.endproc ; CmdCloseAll

;;; ============================================================

.proc CmdDiskCopy
        jmp     start

        DEFINE_OPEN_PARAMS open_params, str_disk_copy, IO_BUFFER
        DEFINE_READ_PARAMS read_params, DISK_COPY_BOOTSTRAP, kDiskCopyBootstrapLength
        DEFINE_CLOSE_PARAMS close_params

str_disk_copy:
        PASCAL_STRING kPathnameDiskCopy

start:
@retry:
        ;; Do this now since we'll use up the space later.
        jsr     SaveWindows

        MLI_CALL OPEN, open_params
        beq     :+
        lda     #kErrInsertSystemDisk
        jsr     ShowAlert
        cmp     #kAlertResultOK
        beq     @retry          ; ok, so try again
        rts                     ; cancel, so fail
:
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_params

        ;; Successful - start to clean up
        ITK_CALL IconTK::RemoveAll, 0 ; volume icons
        MGTK_CALL MGTK::CloseAll
        MGTK_CALL MGTK::SetZP1, setzp_params_preserve

        ;; Initialize system bitmap
        ldx     #BITMAP_SIZE-1
        lda     #0
:       sta     BITMAP,x
        dex
        bpl     :-
        lda     #%00000001      ; ProDOS global page
        sta     BITMAP+BITMAP_SIZE-1
        lda     #%11001111      ; ZP, Stack, Text Page 1
        sta     BITMAP

        ;; Restore modified ProDOS state
        jsr     RestoreDeviceList

        ;; Set up banks for ProDOS usage
        sta     ALTZPOFF
        bit     ROMIN2

        jmp     DISK_COPY_BOOTSTRAP
.endproc ; CmdDiskCopy

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

        ;; access = destroy/rename/write/read
        DEFINE_CREATE_PARAMS create_params, src_path_buf, ACCESS_DEFAULT, FT_DIRECTORY,, ST_LINKED_DIRECTORY

start:  copy    #NewFolderDialogState::open, new_folder_dialog_params::phase
        param_call InvokeDialogProc, kIndexNewFolderDialog, new_folder_dialog_params

L4FC6:  lda     active_window_id
        beq     done            ; command should not be active without a window
        jsr     GetWindowPath
        stax    new_folder_dialog_params::a_path

        copy    #NewFolderDialogState::run, new_folder_dialog_params::phase
        param_call InvokeDialogProc, kIndexNewFolderDialog, new_folder_dialog_params
        jne     done            ; Canceled

        ;; Copy path
        tya                     ; A,X = Y,X
        jsr     CopyToSrcPath

        ;; Create with current date
        COPY_STRUCT DateTime, DATELO, create_params::create_date

        ;; Create folder
        MLI_CALL CREATE, create_params
        beq     success

        ;; Failure
        jsr     ShowAlert
        jmp     L4FC6

success:
        copy    #NewFolderDialogState::close, new_folder_dialog_params::phase
        param_call InvokeDialogProc, kIndexNewFolderDialog, new_folder_dialog_params
        param_call FindLastPathSegment, src_path_buf
        sty     src_path_buf
        jsr     FindWindowForSrcPath
        beq     done

        jsr     SelectAndRefreshWindowOrClose
        bne     done

        param_call SelectFileIconByName, text_input_buf

done:   rts

.endproc ; CmdNewFolderImpl
CmdNewFolder    := CmdNewFolderImpl::start

;;; ============================================================
;;; Select and scroll into view an icon in the active window.
;;; Inputs: A,X = name
;;; Trashes $06

.proc SelectFileIconByName
        ldy     active_window_id
        jsr     FindIconByName
        beq     ret             ; not found

        pha
        jsr     HighlightAndSelectIcon
        copy    active_window_id, selected_window_id
        pla
        jsr     ScrollIconIntoView

ret:    rts
.endproc ; SelectFileIconByName

;;; ============================================================
;;; Find an icon by name in the given window.
;;; Inputs: Y = window id, A,X = name
;;; Outputs: Z=0, A = icon id (or Z=1, A=0 if not found)
;;; NOTE: Modifies `cached_window_id`

.proc FindIconByName
        ptr_icon := $06
        ptr_name := $08

        stax    tmp             ; name

        jsr     PushPointers

        copy16  tmp, ptr_name
        tya
        jsr     LoadWindowEntryTable

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
        jsr     GetIconEntry
        addax   #IconEntry::name, ptr_icon
        jsr     CompareStrings
        bne     next

        ;; Match!
        ldx     icon
        lda     cached_window_entry_list,x
        sta     icon

done:   jsr     PopPointers
        lda     icon
        rts

next:   inc     icon
        bne     loop

tmp:    .addr   0
.endproc ; FindIconByName

;;; ============================================================
;;; Save/Restore drop target icon ID in case the window was rebuilt.

;;; Inputs: `drag_drop_params::result`
;;; Assert: If target is a file icon, icon is in active window.
;;; Trashes $06
.proc MaybeStashDropTargetName
        icon_ptr := $06

        ;; Flag as not stashed
        ldy     #0
        sty     stashed_name

        ;; Is the target an icon?
        lda     drag_drop_params::result
        bmi     done            ; high bit set = window

        jsr     GetIconEntry
        stax    icon_ptr

        ldy     #IconEntry::win_flags ; file icon?
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        beq     done            ; nope, vol icon

        ;; Stash name
        add16_8 icon_ptr, #IconEntry::name
        param_call CopyPtr1ToBuf, stashed_name

done:   rts
.endproc ; MaybeStashDropTargetName

;;; Outputs: `drag_drop_params::result` updated if needed
;;; Assert: `MaybeStashDropTargetName` was previously called
;;; NOTE: Preserves `cached_window_id`
;;; Trashes $06

.proc MaybeUpdateDropTargetFromName
        ;; Did we previously stash an icon's name?
        lda     stashed_name
        beq     done            ; not stashed

        ;; Try to find the icon by name.
        lda     cached_window_id
        sta     prev_cached_window_id

        ldy     active_window_id
        ldax    #stashed_name
        jsr     FindIconByName  ; modifies `cached_window_id`
        pha

        prev_cached_window_id := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     LoadWindowEntryTable ; restore previous state

        pla                          ; A = `FindIconByName` result
        beq     done                 ; no match

        ;; Update drop target with new icon id.
        sta     drag_drop_params::result

done:   rts
.endproc ; MaybeUpdateDropTargetFromName

stashed_name:
        .res    16, 0

;;; ============================================================
;;; Input: Icon number in A.
;;; Assert: Icon in active window.

.proc ScrollIconIntoView
        pha
        jsr     LoadActiveWindowEntryTable
        pla
        sta     icon_param

        ;; Map coordinates to window
        jsr     IconScreenToWindow

        ;; Grab the icon bounds
        ITK_CALL IconTK::GetIconBounds, icon_param ; inits `tmp_rect`

        ;; Restore coordinates
        lda     icon_param
        jsr     IconWindowToScreen

        ;; Get the viewport, and adjust for header
        jsr     ApplyActiveWinfoToWindowGrafport
        add16_8 window_grafport::maprect::y1, #kWindowHeaderHeight - 1

        copy    #0, dirty

        ;; Padding
        sub16_8 tmp_rect::x1, #kIconBBoxPaddingLeft
        add16_8 tmp_rect::x2, #kIconBBoxPaddingRight
        sub16_8 tmp_rect::y1, #kIconBBoxPaddingTop
        add16_8 tmp_rect::y2, #kIconBBoxPaddingBottom

        ;; --------------------------------------------------
        ;; X adjustment

        ;; Is left of icon beyond window? If so, adjust by delta (negative)
        sub16   tmp_rect::x1, window_grafport::maprect::x1, delta
        bmi     adjustx

        ;; Is right of icon beyond window? If so, adjust by delta (positive)
        sub16   tmp_rect::x2, window_grafport::maprect::x2, delta
        bmi     donex

adjustx:
        lda     delta
        ora     delta+1
        beq     donex

        inc     dirty
        add16   window_grafport::maprect::x1, delta, window_grafport::maprect::x1
        add16   window_grafport::maprect::x2, delta, window_grafport::maprect::x2

donex:

        ;; --------------------------------------------------
        ;; Y adjustment

        ;; Is top of icon beyond window? If so, adjust by delta (negative)
        sub16   tmp_rect::y1, window_grafport::maprect::y1, delta
        bmi     adjusty

        ;; Is bottom of icon beyond window? If so, adjust by delta (positive)
        sub16   tmp_rect::y2, window_grafport::maprect::y2, delta
        bmi     doney

adjusty:
        lda     delta
        ora     delta+1
        beq     doney

        inc     dirty
        add16   window_grafport::maprect::y1, delta, window_grafport::maprect::y1
        add16   window_grafport::maprect::y2, delta, window_grafport::maprect::y2

doney:
        dirty := *+1
        lda     #SELF_MODIFIED_BYTE
        beq     done

        ;; Apply the viewport (accounting for header)
        sub16_8 window_grafport::maprect::y1, #kWindowHeaderHeight - 1
        jsr     AssignActiveWindowCliprectAndUpdateCachedIcons
        jsr     ScrollUpdate
        jsr     RedrawAfterScroll

done:   rts

delta:  .word   0
.endproc ; ScrollIconIntoView

;;; ============================================================

.proc CmdCheckOrEjectImpl
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
.endproc ; CmdCheckOrEjectImpl
        CmdEject        := CmdCheckOrEjectImpl::eject
        CmdCheckDrive   := CmdCheckOrEjectImpl::check

;;; ============================================================

.proc CmdQuitImpl
        ;; Override within this scope
        MLIEntry := MLI

        quit_code_io := $800
        quit_code_addr := $1000
        quit_code_size := $400

        DEFINE_OPEN_PARAMS open_params, str_quit_code, quit_code_io
        DEFINE_READ_PARAMS read_params, quit_code_addr, quit_code_size
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_QUIT_PARAMS quit_params

str_quit_code:
        PASCAL_STRING kPathnameQuitSave

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

.endproc ; CmdQuitImpl
CmdQuit := CmdQuitImpl::start
ResetHandler    := CmdQuitImpl::ResetHandler

;;; ============================================================
;;; Exit DHR, restore device list, reformat /RAM.
;;; Returns with ALTZPOFF and ROM banked in.

.proc RestoreSystem
        copy    #0, main::mli_relay_checkevents_flag

        jsr     SaveWindows

        ;; Switch back to main ZP/LC, preserving return address.
        pla
        tax
        pla
        sta     ALTZPOFF
        pha
        txa
        pha

        ;; Exit graphics mode entirely
        bit     ROMIN2

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

        ;; Switch back to color DHR mode now that screen is blank
        bit     LCBANK1
        bit     LCBANK1
        sta     ALTZPON
        jsr     SetColorMode    ; depends on state in Aux LC
        sta     ALTZPOFF
        bit     ROMIN2

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

        jsr     ReconnectRAM
        jmp     RestoreDeviceList
.endproc ; RestoreSystem

;;; ============================================================

menu_item_to_view_by:
        .byte   kViewByIcon, kViewBySmallIcon
        .byte   kViewByName, kViewByDate, kViewBySize, kViewByType

.proc CmdViewBy
        ldx     menu_click_params::item_num
        lda     menu_item_to_view_by-1,x
        FALL_THROUGH_TO ViewByCommon
.endproc ; CmdViewBy

;;; ============================================================

.proc ViewByCommon
        sta     view

        ;; Valid?
        lda     active_window_id
        bne     :+
        rts
:
        ;; Is this a change?
        jsr     GetActiveWindowViewBy
        cmp     view
        bne     :+              ; not by icon
        rts
:
        ;; Update view menu/table
        view := *+1
        lda     #SELF_MODIFIED_BYTE
        ldx     active_window_id
        sta     win_view_by_table-1,x
        jsr     UpdateViewMenuCheck

;;; Entry point when view needs refreshing, e.g. rename when sorted.
entry2:
        ;; Selection not preserved in other entry points
        ;; because file records are not retained.
        jsr     PreserveSelection

        ;; Destroy existing icons
        jsr     DestroyIconsInActiveWindow

;;; Entry point when refreshing window contents
entry3:
        ;; Clear selection if in the window
        lda     selected_window_id
        cmp     active_window_id
        bne     :+
        lda     #0
        sta     selected_icon_count
        sta     selected_window_id
:
        ;; Reset the viewport
        jsr     ResetActiveWindowViewport ; Must precede icon creation

        ;; Create the icons
        jsr     LoadActiveWindowEntryTable
        jsr     InitWindowEntriesAndIcons
        jsr     AdjustViewportForNewIcons

        jsr     RestoreSelection

        jmp     RedrawAfterContentChange

;;; --------------------------------------------------
;;; Preserves selection by replacing selected icon ids
;;; with their corresponding record indexes, which remain
;;; valid across view changes.

.proc PreserveSelection
        lda     selected_window_id
        beq     ret
        lda     selected_icon_count
        beq     ret
        sta     selection_preserved_count

        ;; For each selected icon, replace icon number
        ;; with its corresponding file record number.
:       ldx     selected_icon_count
        lda     selected_icon_list-1,x
        jsr     GetIconRecordNum
        ldx     selected_icon_count
        sta     selected_icon_list-1,x
        dec     selected_icon_count
        bne     :-

        copy    #0, selected_window_id

ret:    rts
.endproc ; PreserveSelection

;;; --------------------------------------------------
;;; Restores selection after a view change, reversing what
;;; `PreserveSelection` did.

.proc RestoreSelection
        lda     selection_preserved_count
        beq     ret

        ;; For each record num in the list, find and
        ;; highlight the corresponding icon.
:       ldx     selected_icon_count
        lda     selected_icon_list,x
        jsr     FindIconForRecordNum
        ldx     selected_icon_count
        sta     selected_icon_list,x
        sta     icon_param
        ITK_CALL IconTK::HighlightIcon, icon_param
        inc     selected_icon_count
        dec     selection_preserved_count
        bne     :-

        copy    cached_window_id, selected_window_id

ret:    rts
.endproc ; RestoreSelection

selection_preserved_count:
        .byte   0
.endproc ; ViewByCommon

;;; ============================================================
;;; Find the icon for the cached window's given record index.
;;; Input: A = record index in cached window
;;; Output: A = icon id
;;; Assert: there is a match, window has entries
;;; Trashes $06

.proc FindIconForRecordNum
        sta     record_num

        lda     cached_window_entry_count
        sta     index

        index := *+1
:       ldx     #SELF_MODIFIED_BYTE
        lda     cached_window_entry_list-1,x
        jsr     GetIconRecordNum
        record_num := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     :+
        dec     index
        bpl     :-

:       ldx     index
        lda     cached_window_entry_list-1,x
        rts
.endproc ; FindIconForRecordNum

;;; ============================================================
;;; Retrieve the `IconEntry::record_num` for a given icon.
;;; Input: A = icon id
;;; Output: A = icon's record index in its window
;;; Trashes $06

.proc GetIconRecordNum
        jsr     GetIconEntry
        ptr := $06
        stax    ptr
        ldy     #IconEntry::record_num
        lda     (ptr),y
        rts
.endproc ; GetIconRecordNum

;;; ============================================================

.proc AddIconsForCachedWindow
        copy    #0, index
        index := *+1
:       lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     :+
        tax
        lda     cached_window_entry_list,x
        sta     icon_param
        jsr     GetIconEntry
        stax    @addr
        ITK_CALL IconTK::AddIcon, 0, @addr
        inc     index
        jmp     :-
:
        rts
.endproc ; AddIconsForCachedWindow

;;; ============================================================

.proc RedrawAfterContentChange
        ;; Draw the contents
        lda     active_window_id
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        jsr     ClearWindowBackgroundIfNotObscured

        lda     #kDrawWindowEntriesContentOnly
        jsr     DrawWindowEntries

        ;; Update scrollbars based on contents/viewport
        jmp     ScrollUpdate
.endproc ; RedrawAfterContentChange

;;; ============================================================

.proc UpdateViewMenuCheck
        ;; Uncheck last checked
        jsr     UncheckViewMenuItem

        ;; Check the new one
        copy    menu_click_params::item_num, checkitem_params::menu_item
        jmp     CheckViewMenuItem
.endproc ; UpdateViewMenuCheck

;;; ============================================================
;;; Destroy all of the icons in the active window.

.proc DestroyIconsInActiveWindow
        ITK_CALL IconTK::RemoveAll, active_window_id
        jsr     LoadActiveWindowEntryTable ; restored below
        lda     icon_count
        sec
        sbc     cached_window_entry_count
        sta     icon_count

        jsr     FreeCachedWindowIcons

        jmp     StoreWindowEntryTable
.endproc ; DestroyIconsInActiveWindow

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
.endproc ; FreeCachedWindowIcons

;;; ============================================================
;;; Clear active window entry count

.proc ClearActiveWindowEntryCount
        jsr     LoadActiveWindowEntryTable

        copy    #0, cached_window_entry_count

        jmp     StoreWindowEntryTable
.endproc ; ClearActiveWindowEntryCount

;;; ============================================================

;;; Set after format, erase, failed open, etc.
;;; Used by 'cmd_check_single_drive_by_XXX'; may be unit number
;;; or device index depending on call site.
drive_to_refresh:
        .byte   0

;;; ============================================================

.proc CmdFormatEraseDiskImpl
format: lda     #FormatEraseAction::format
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
erase:  lda     #FormatEraseAction::erase
        sta     action

        lda     #kDynamicRoutineFormatErase
        jsr     LoadDynamicRoutine
        bpl     :+
        rts
:
        jsr     GetSelectedUnitNum
        tax
        action := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     format_erase_overlay__Exec
        stx     drive_to_refresh ; X = unit number
        pha                     ; A = result
        jsr     ClearUpdates ; following dialog close
        pla                     ; A = result
        beq     :+
        rts
:
        jmp     CmdCheckSingleDriveByUnitNumber
.endproc ; CmdFormatEraseDiskImpl
CmdFormatDisk := CmdFormatEraseDiskImpl::format
CmdEraseDisk := CmdFormatEraseDiskImpl::erase

;;; ============================================================

;;; Inputs: A=unit number if a single volume is selected, 0 otherwise

.proc GetSelectedUnitNum
        ;; Get single selected volume icon (or fail)
        lda     selected_window_id
        bne     fail            ; not the desktop
        lda     selected_icon_count
        cmp     #1
        bne     fail            ; more/less than one selected
        lda     selected_icon_list

        ;; Look up device index by icon number
        ldx     #kMaxVolumes-1
:       cmp     device_to_icon_map,x
        beq     found
        dex
        bpl     :-

fail:   lda     #0
        rts

found:  lda     DEVLST,x
        and     #UNIT_NUM_MASK
        rts
.endproc ; GetSelectedUnitNum

;;; ============================================================

;;; These commands don't need anything beyond the operation.

CmdGetInfo      := DoGetInfo
CmdGetSize      := DoGetSize
CmdUnlock       := DoUnlock
CmdLock         := DoLock

;;; ============================================================

.proc CmdDeleteSelection
        ;; Re-uses 'drop on trash' logic which handles updating
        ;; the source window.
        copy    trash_icon_num, drag_drop_params::icon
        jmp     process_drop
.endproc ; CmdDeleteSelection

;;; ============================================================

;;; Assert: Single icon selected, and it's not trash
.proc CmdRename
        jsr     DoRename
        pha                     ; A = result

        ;; If selection is in a window with View > by Name, refresh
        lda     selected_window_id
    IF_NE
        jsr     GetSelectionViewBy
        cmp     #kViewByName
      IF_EQ
        txa                     ; X = window id
        jsr     ViewByCommon::entry2
      ELSE
        ;; Scrollbars may need adjusting
        jsr     ScrollUpdate
      END_IF
    END_IF

        pla                     ; A = result
        bpl     :+              ; N = window renamed
        ;; TODO: Avoid repainting everything
        MGTK_CALL MGTK::RedrawDeskTop
:
        rts
.endproc ; CmdRename

;;; ============================================================

;;; Assert: One or more file icons selected
.proc CmdDuplicate
        jsr     DoDuplicate
        beq     ret             ; flag set if window needs refreshing

        ;; Update cached used/free for all same-volume windows
        param_call UpdateUsedFreeViaPath, path_buf3

        ;; Select/refresh window if there was one
        lda     active_window_id
        jne     SelectAndRefreshWindowOrClose

ret:    rts
.endproc ; CmdDuplicate

;;; ============================================================
;;; Handle keyboard-based icon selection ("highlighting")

.proc CmdHighlightImpl

        ;; Next/prev in sorted order
a_prev: lda     #$80
        bne     store           ; always
a_next: lda     #$00
        beq     store           ; always

        ;; Tab / Shift+Tab - next/prev in sorted order, based on shift
alpha:  jsr     ShiftDown

store:  sta     flag
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
        FALL_THROUGH_TO select_next

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
        FALL_THROUGH_TO HighlightIcon

;;; Highlight the icon in the list at `selected_index`
HighlightIcon:
        ldx     selected_index
        lda     buffer+1,x
        jmp     SelectIcon
.endproc ; CmdHighlightImpl
CmdHighlightPrev := CmdHighlightImpl::prev
CmdHighlightNext := CmdHighlightImpl::next
CmdHighlightAlpha := CmdHighlightImpl::alpha
CmdHighlightAlphaPrev := CmdHighlightImpl::a_prev
CmdHighlightAlphaNext := CmdHighlightImpl::a_next

;;; ============================================================
;;; Type Down Selection

.proc ClearTypeDown
        copy    #0, typedown_buf
        rts
.endproc ; ClearTypeDown

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
        cpx     #kMaxFilenameLength
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
        rts

        num_filenames := $1800
        table := $1801

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
.endproc ; FindMatch

.endproc ; CheckTypeDown

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

        ;; --------------------------------------------------
        ;; Icons in active window

        jsr     LoadActiveWindowEntryTable

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

        ;; --------------------------------------------------
        ;; Desktop (volume) icons

volumes:
        jsr     LoadDesktopEntryTable

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
.endproc ; GetSelectableIcons

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

        rts
.endproc ; GetSelectableIconsSorted

;;; Assuming selectable icon buffer at $1800 is populated by the
;;; above functions, return ptr to nth icon's name in A,X
;;; Input: A = index
;;; Output: A,X = icon name pointer
.proc GetNthSelectableIconName
        buffer := $1800

        tax
        lda     buffer+1,x         ; A = icon num
        jmp     GetIconName
.endproc ; GetNthSelectableIconName

;;; ============================================================
;;; Compare strings at $06 (1) and $08 (2). Case insensitive.
;;; Returns C=0 for 1<2 , C=1 for 1>=2, Z=1 for 1=2
.proc CompareStrings
        ptr1 := $06
        ptr2 := $08

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
:       cpy     #SELF_MODIFIED_BYTE
        beq     gt              ; 1>2
        iny
        bne     loop            ; always

gt:     lda     #$FF            ; Z=0
        sec
ret:    rts
.endproc ; CompareStrings

;;; ============================================================
;;; Select an arbitrary icon. If windowed, it is scrolled into view.
;;; Inputs: A = icon id
;;; Assert: Selection is empty. If windowed, it's in the active window.

.proc SelectIcon
        sta     icon_param
        ITK_CALL IconTK::HighlightIcon, icon_param

        ;; Find icon's window, and set selection
        icon_ptr := $06
        lda     icon_param
        jsr     GetIconEntry
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
        lda     selected_icon_list
        jsr     ScrollIconIntoView
:

        ITK_CALL IconTK::DrawIcon, selected_icon_list

        rts
.endproc ; SelectIcon

;;; ============================================================

.proc CmdSelectAll
        lda     selected_icon_count
        beq     :+
        jsr     ClearSelection
:
        jsr     LoadActiveWindowEntryTable
        lda     cached_window_entry_count
        beq     finish          ; nothing to select!

        ldx     cached_window_entry_count
        dex
:       copy    cached_window_entry_list,x, selected_icon_list,x
        dex
        bpl     :-

        copy    cached_window_entry_count, selected_icon_count
        copy    active_window_id, selected_window_id

        lda     selected_window_id
    IF_ZERO
        sta     err             ; zero if desktop; will overwrite if windowed
        jsr     InitSetDesktopPort
    ELSE
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        sta     err
    END_IF

        ;; --------------------------------------------------
        ;; Mark all icons as highlighted
        ldx     #0
:       txa
        pha
        copy    selected_icon_list,x, icon_param
        ITK_CALL IconTK::HighlightIcon, icon_param
        pla
        tax
        inx
        cpx     selected_icon_count
        bne     :-

        ;; --------------------------------------------------
        ;; Repaint the icons
        err := *+1
        lda     #SELF_MODIFIED_BYTE
    IF_ZERO                     ; Skip drawing if obscured
        lda     cached_window_id
        beq     :+
        jsr     CachedIconsScreenToWindow
:
        ITK_CALL IconTK::DrawAll, cached_window_id ; CHECKED
        lda     cached_window_id
        beq     :+
        jsr     CachedIconsWindowToScreen
:
    END_IF

finish: rts
.endproc ; CmdSelectAll


;;; ============================================================
;;; Initiate keyboard-based resizing

.proc CmdResize
        MGTK_CALL MGTK::KeyboardMouse
        jmp     HandleResizeClick
.endproc ; CmdResize

;;; ============================================================
;;; Initiate keyboard-based window moving

.proc CmdMove
        MGTK_CALL MGTK::KeyboardMouse
        jmp     HandleTitleClick
.endproc ; CmdMove

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
@loop:  cpx     #kMaxDeskTopWindows
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
        ldx     #kMaxDeskTopWindows-1
:       lda     window_to_dir_icon_table,x
        beq     @loop           ; 0 = window free
        FALL_THROUGH_TO found

found:  inx
        stx     findwindow_params::window_id
        jmp     ActivateWindowAndSelectIcon

done:   rts
.endproc ; CmdCycleWindows

;;; ============================================================
;;; Keyboard-based scrolling of window contents

.proc CmdScroll
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

done:   rts

:
        cmp     #CHAR_RIGHT
        bne     :+
        jsr     ScrollRight
        jmp     loop
:
        cmp     #CHAR_LEFT
        bne     :+
        jsr     ScrollLeft
        jmp     loop
:
        cmp     #CHAR_DOWN
        bne     :+
        jsr     ScrollDown
        jmp     loop
:
        cmp     #CHAR_UP
        bne     loop
        jsr     ScrollUp
        jmp     loop
.endproc ; CmdScroll

;;; ============================================================
;;; Centralized logic for scrolling directory windows

.scope ScrollManager

        .include "../lib/muldiv32.s"

;;; Terminology:
;;; * "offset" - When the icons would fit entirely within the viewport
;;;   (for a given dimension) but the viewport is offset so a scrollbar
;;;   must still be shown.


;;; Effective viewport  ("Effective" discounts the window header.)
viewport := window_grafport::maprect

;;; `ubox` is a union of the effective viewport and icon bounding box
        DEFINE_RECT ubox, 0, 0, 0, 0

;;; Effective dimensions of the viewport
width:          .word   0
height:         .word   0

;;; Initial effective viewport top/left
        DEFINE_POINT old, 0, 0

;;; Increment/decrement sizes (depends on view type)
tick_h: .byte   0
tick_v: .byte   0

;;; --------------------------------------------------
;;; Compute the necessary data for scroll operations:
;;; * `viewport` - effective viewport of active window
;;; * `ubox` - union of icon bounding box and viewport
;;; * `tick_h` and `tick_v` sizes (based on view type)
;;; * `width` and `height` of the effective viewport
;;; * `old` - initial top/left of viewport (to detect changes)

_Preamble:
        jsr     LoadActiveWindowEntryTable

        jsr     CachedIconsScreenToWindow
        jsr     ComputeIconsBBox
        jsr     CachedIconsWindowToScreen

        jsr     GetActiveWindowViewBy ; N=0 is icon view, N=1 is list view
    IF_POS
        ;; Icon view
        copy    #kIconViewScrollTickH, tick_h
        copy    #kIconViewScrollTickV, tick_v
    ELSE
        ;; List view
        copy    #kListViewScrollTickH, tick_h
        copy    #kListViewScrollTickV, tick_v
    END_IF

        ;; Compute effective viewport
        jsr     ApplyActiveWinfoToWindowGrafport
        add16_8 viewport+MGTK::Rect::y1, #kWindowHeaderHeight - 1
        COPY_STRUCT MGTK::Point, viewport+MGTK::Rect::topleft, old
        sub16   viewport+MGTK::Rect::x2, viewport+MGTK::Rect::x1, width
        sub16   viewport+MGTK::Rect::y2, viewport+MGTK::Rect::y1, height

        ;; Make `ubox` bound both viewport and icons; needed to ensure
        ;; offset cases are handled.
        COPY_STRUCT MGTK::Rect, iconbb_rect, ubox
        scmp16  viewport+MGTK::Rect::x1, ubox::x1
    IF_NEG
        copy16  viewport+MGTK::Rect::x1, ubox::x1
    END_IF
        scmp16  viewport+MGTK::Rect::x2, ubox::x2
    IF_POS
        copy16  viewport+MGTK::Rect::x2, ubox::x2
    END_IF
        scmp16  viewport+MGTK::Rect::y1, ubox::y1
    IF_NEG
        copy16  viewport+MGTK::Rect::y1, ubox::y1
    END_IF
        scmp16  viewport+MGTK::Rect::y2, ubox::y2
    IF_POS
        copy16  viewport+MGTK::Rect::y2, ubox::y2
    END_IF

        rts

;;; --------------------------------------------------
;;; When arrow increment is clicked:
;;;   1. vp.hi += tick
;;;   2. goto _Clamp_hi

.proc ArrowRight
        jsr     _Preamble
        add16_8 viewport+MGTK::Rect::x2, tick_h
        jmp     _Clamp_x2
.endproc ; ArrowRight

.proc ArrowDown
        jsr     _Preamble
        add16_8 viewport+MGTK::Rect::y2, tick_v
        jmp     _Clamp_y2
.endproc ; ArrowDown

;;; --------------------------------------------------
;;; When arrow decrement is clicked:
;;;   1. vp.lo -= tick
;;;   2. goto _Clamp_lo

.proc ArrowLeft
        jsr     _Preamble
        sub16_8 viewport+MGTK::Rect::x1, tick_h
        jmp     _Clamp_x1
.endproc ; ArrowLeft

.proc ArrowUp
        jsr     _Preamble
        sub16_8 viewport+MGTK::Rect::y1, tick_v
        jmp     _Clamp_y1
.endproc ; ArrowUp

;;; --------------------------------------------------
;;; When page increment area is clicked:
;;;   1. vp.hi += size
;;;   2. goto _Clamp_hi

.proc PageRight
        jsr     _Preamble
        add16   viewport+MGTK::Rect::x2, width, viewport+MGTK::Rect::x2
        jmp     _Clamp_x2
.endproc ; PageRight

.proc PageDown
        jsr     _Preamble
        add16_8 viewport+MGTK::Rect::y2, height
        jmp     _Clamp_y2
.endproc ; PageDown

;;; --------------------------------------------------
;;; When page decrement area is clicked:
;;;   1. vp.lo -= size
;;;   2. goto _Clamp_lo

.proc PageLeft
        jsr     _Preamble
        sub16   viewport+MGTK::Rect::x1, width, viewport+MGTK::Rect::x1
        jmp     _Clamp_x1
.endproc ; PageLeft

.proc PageUp
        jsr     _Preamble
        sub16_8 viewport+MGTK::Rect::y1, height
        jmp     _Clamp_y1
.endproc ; PageUp

;;; --------------------------------------------------
;;; When thumb is moved by user:
;;;   1. vp.lo = ubox.lo + (ubox.hi - ubox.lo - size) * (newpos / thumb.max)
;;;   2. vp.hi = vp.lo + size
;;;   3. goto update

.proc TrackHThumb
        jsr     _Preamble
        sub16   ubox::x2, ubox::x1, multiplier
        sub16   multiplier, width, multiplier
        jsr     _TrackMulDiv
        add16   quotient, ubox::x1, viewport+MGTK::Rect::x1
        add16   viewport+MGTK::Rect::x1, width, viewport+MGTK::Rect::x2
        jmp     _MaybeUpdateHThumb
.endproc ; TrackHThumb

.proc TrackVThumb
        jsr     _Preamble
        sub16   ubox::y2, ubox::y1, multiplier
        sub16   multiplier, height, multiplier
        jsr     _TrackMulDiv
        add16   quotient, ubox::y1, viewport+MGTK::Rect::y1
        add16   viewport+MGTK::Rect::y1, height, viewport+MGTK::Rect::y2
        jmp     _MaybeUpdateVThumb
.endproc ; TrackVThumb

.proc _TrackMulDiv
        copy    trackthumb_params::thumbpos, multiplicand
        copy    #0, multiplicand+1
        jsr     Mul_16_16
        copy32  product, numerator
        copy32  #kScrollThumbMax, denominator
        jmp     Div_32_32
.endproc ; _TrackMulDiv

;;; --------------------------------------------------
;;; _Clamp_hi:
;;;   1. if vp.hi > ubox.hi: vp.hi = ubox.hi
;;;   2. vp.lo = vp.hi - size
;;;   3. goto update

.proc _Clamp_x2
        scmp16  viewport+MGTK::Rect::x2, ubox::x2
    IF_POS
        copy16  ubox::x2, viewport+MGTK::Rect::x2
    END_IF
        sub16   viewport+MGTK::Rect::x2, width, viewport+MGTK::Rect::x1
        jmp     _MaybeUpdateHThumb
.endproc ; _Clamp_x2

.proc _Clamp_y2
        scmp16  viewport+MGTK::Rect::y2, ubox::y2
    IF_POS
        copy16  ubox::y2, viewport+MGTK::Rect::y2
    END_IF
        sub16   viewport+MGTK::Rect::y2, height, viewport+MGTK::Rect::y1
        jmp     _MaybeUpdateVThumb
.endproc ; _Clamp_y2

;;; --------------------------------------------------
;;; _Clamp_lo:
;;;   1. if vp.lo < ubox.lo: vp.lo = ubox.lo
;;;   2. vp.hi = vp.lo + size
;;;   3. goto update

.proc _Clamp_x1
        scmp16  viewport+MGTK::Rect::x1, ubox::x1
    IF_NEG
        copy16  ubox::x1, viewport+MGTK::Rect::x1
    END_IF
        add16   viewport+MGTK::Rect::x1, width, viewport+MGTK::Rect::x2
        jmp     _MaybeUpdateHThumb
.endproc ; _Clamp_x1

.proc _Clamp_y1
        scmp16  viewport+MGTK::Rect::y1, ubox::y1
    IF_NEG
        copy16  ubox::y1, viewport+MGTK::Rect::y1
    END_IF
        add16   viewport+MGTK::Rect::y1, height, viewport+MGTK::Rect::y2
        jmp     _MaybeUpdateVThumb
.endproc ; _Clamp_y1

;;; --------------------------------------------------
;;; Following above gestures, determine if the viewport
;;; has changed and if so update the thumb.
;;;
;;;   1. if vp.lo != old:
;;;     1. newpos = (vp.lo - ubox.lo) / (ubox.hi - ubox.lo - size) * thumb.max
;;;     2. if newpos != thumb.pos: update thumb
;;;     3. redraw

.proc _MaybeUpdateHThumb
        ecmp16  viewport+MGTK::Rect::x1, old::xcoord
    IF_NE
        jsr     _SetHThumbFromViewport
        jsr     _UpdateViewport
        jsr     RedrawAfterScroll

        ;; Handle offset case - may be able to deactivate scrollbar now
        jsr     _Preamble       ; Need updated `ubox` and `maprect`
        scmp16  ubox::x1, viewport+MGTK::Rect::x1
        bmi     :+
        scmp16  viewport+MGTK::Rect::x2, ubox::x2
        bmi     :+
        ldx     #MGTK::Ctl::horizontal_scroll_bar
        lda     #MGTK::activatectl_deactivate
        jsr     _ActivateCtl
:
    END_IF
        rts
.endproc ; _MaybeUpdateHThumb

.proc _MaybeUpdateVThumb
        ecmp16  viewport+MGTK::Rect::y1, old::ycoord
    IF_NE
        jsr     _SetVThumbFromViewport
        jsr     _UpdateViewport
        jsr     RedrawAfterScroll

        ;; Handle offset case - may be able to deactivate scrollbar now
        jsr     _Preamble       ; Need updated `ubox` and `maprect`
        scmp16  ubox::y1, viewport+MGTK::Rect::y1
        bmi     :+
        scmp16  viewport+MGTK::Rect::y2, ubox::y2
        bmi     :+
        ldx     #MGTK::Ctl::vertical_scroll_bar
        lda     #MGTK::activatectl_deactivate
        jsr     _ActivateCtl
:
    END_IF
        rts
.endproc ; _MaybeUpdateVThumb

;;; Set hthumb position relative to `maprect` and `ubox`.
.proc _SetHThumbFromViewport
        sub16   viewport+MGTK::Rect::x1, ubox::x1, multiplier
        copy16  #kScrollThumbMax, multiplicand
        jsr     Mul_16_16
        copy32  product, numerator
        sub16   ubox::x2, ubox::x1, denominator
        sub16   denominator, width, denominator
        copy16  #0, denominator+2 ; 16->32 bits
        jsr     Div_32_32
        lda     quotient
        ldx     #MGTK::Ctl::horizontal_scroll_bar
        jmp     _UpdateThumb
.endproc ; _SetHThumbFromViewport

;;; Set vthumb position relative to `maprect` and `ubox`.
.proc _SetVThumbFromViewport
        sub16   viewport+MGTK::Rect::y1, ubox::y1, multiplier
        copy16  #kScrollThumbMax, multiplicand
        jsr     Mul_16_16
        copy32  product, numerator
        sub16   ubox::y2, ubox::y1, denominator
        sub16   denominator, height, denominator
        copy16  #0, denominator+2 ; 16->32 bits
        jsr     Div_32_32
        lda     quotient
        ldx     #MGTK::Ctl::vertical_scroll_bar
        jmp     _UpdateThumb
.endproc ; _SetVThumbFromViewport

;;; --------------------------------------------------
;;; Apply `maprect` back to active window's GrafPort

.proc _UpdateViewport
        ;; Restore header to viewport
        sub16_8 viewport+MGTK::Rect::y1, #kWindowHeaderHeight - 1

        jmp     AssignActiveWindowCliprectAndUpdateCachedIcons
.endproc ; _UpdateViewport

;;; --------------------------------------------------
;;; Check contents against window size, and activate/deactivate
;;; horizontal and vertical scrollbars as needed.

.proc ActivateCtlsSetThumbs
        jsr     _Preamble

        scmp16  ubox::x1, viewport+MGTK::Rect::x1
        bmi     activate_hscroll
        scmp16  viewport+MGTK::Rect::x2, ubox::x2
        bmi     activate_hscroll

        ;; deactivate horizontal scrollbar
        ldx     #MGTK::Ctl::horizontal_scroll_bar
        lda     #MGTK::activatectl_deactivate
        jsr     _ActivateCtl

        jmp     check_vscroll

activate_hscroll:
        ;; activate horizontal scrollbar
        ldx     #MGTK::Ctl::horizontal_scroll_bar
        lda     #MGTK::activatectl_activate
        jsr     _ActivateCtl

        jsr     _SetHThumbFromViewport
        FALL_THROUGH_TO check_vscroll

        ;; --------------------------------------------------

check_vscroll:
        scmp16  ubox::y1, viewport+MGTK::Rect::y1
        bmi     activate_vscroll
        scmp16  viewport+MGTK::Rect::y2, ubox::y2
        bmi     activate_vscroll

        ;; deactivate vertical scrollbar
        ldx     #MGTK::Ctl::vertical_scroll_bar
        lda     #MGTK::activatectl_deactivate
        jmp     _ActivateCtl

activate_vscroll:
        ;; activate vertical scrollbar
        ldx     #MGTK::Ctl::vertical_scroll_bar
        lda     #MGTK::activatectl_activate
        jsr     _ActivateCtl

        jmp     _SetVThumbFromViewport
.endproc ; ActivateCtlsSetThumbs

;;; --------------------------------------------------
;;; Inputs: A=activate/deactivate, X=which_ctl

.proc _ActivateCtl
        stx     activatectl_params::which_ctl
        sta     activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts
.endproc ; _ActivateCtl

;;; --------------------------------------------------
;;; Inputs: A=thumbpos, X=which_ctl

.proc _UpdateThumb
        sta     updatethumb_params::thumbpos
        stx     updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        rts
.endproc ; _UpdateThumb

.endscope ; ScrollManager

;;; Handle scroll gestures
ScrollLeft      := ScrollManager::ArrowLeft
ScrollUp        := ScrollManager::ArrowUp
ScrollRight     := ScrollManager::ArrowRight
ScrollDown      := ScrollManager::ArrowDown
ScrollPageLeft  := ScrollManager::PageLeft
ScrollPageUp    := ScrollManager::PageUp
ScrollPageRight := ScrollManager::PageRight
ScrollPageDown  := ScrollManager::PageDown
ScrollTrackHThumb := ScrollManager::TrackHThumb
ScrollTrackVThumb := ScrollManager::TrackVThumb

;;; Update the scrollbar activation state and thumb positions for
;;; both horizontal and vertical scrollbars, based on the window's
;;; viewport and contents.
ScrollUpdate    := ScrollManager::ActivateCtlsSetThumbs


;;; ============================================================

.proc CmdCheckDrives
        copy    #0, pending_alert
        jsr     CmdCloseAll
        jsr     ClearSelection

        ;; --------------------------------------------------
        ;; Destroy existing volume icons
.scope
        jsr     LoadDesktopEntryTable
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
        ITK_CALL IconTK::EraseIcon, icon_param ; CHECKED (desktop)
        ITK_CALL IconTK::RemoveIcon, icon_param
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
        jsr     GetIconEntry
        stax    @addr
        ITK_CALL IconTK::AddIcon, 0, @addr
        ITK_CALL IconTK::DrawIcon, icon_param ; CHECKED (desktop)

next:   pla
        tax
        inx
        jmp     loop
.endscope

.endproc ; CmdCheckDrives

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
        bit     check_drive_flags
        bpl     explicit_command
        bvc     after_format_erase

;;; --------------------------------------------------
;;; After an Open/Eject/Rename action

        ;; Map icon number to index in DEVLST
        lda     drive_to_refresh
        ldy     #kMaxVolumes-1
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
        jsr     GetIconName
        stax    $06

        path_buf := $1F00

        ;; Copy volume path to $1F00
        param_call CopyPtr1ToBuf, path_buf+1

        ;; Find all windows with path as prefix, and close them.
        sta     path_buf
        inc     path_buf
        copy    #'/', path_buf+1

        param_call FindWindowsForPrefix, path_buf
        lda     found_windows_count
        beq     not_in_map

close_loop:
        ldx     found_windows_count
        beq     not_in_map
        dex
        lda     found_windows_list,x
        jsr     CloseSpecifiedWindow
        dec     found_windows_count
        jmp     close_loop

not_in_map:

        jsr     ClearSelection
        jsr     LoadDesktopEntryTable

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
        ITK_CALL IconTK::EraseIcon, icon_param ; CHECKED (desktop)
        ITK_CALL IconTK::RemoveIcon, icon_param

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
        jmp     ShowAlert

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
        jsr     GetIconEntry
        stax    @addr
        ITK_CALL IconTK::AddIcon, 0, @addr
        ITK_CALL IconTK::DrawIcon, icon_param ; CHECKED (desktop)

:       jmp     StoreWindowEntryTable

;;; 0 = command, $80 = format/erase, $C0 = open/eject/rename
check_drive_flags:
        .byte   0

.endproc ; CmdCheckSingleDriveImpl

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
        FALL_THROUGH_TO ResetAndInvoke
.endproc ; CmdStartupItem

        ;; also invoked by launcher code
.proc ResetAndInvoke
        ;; Restore system state: devices, /RAM, ROM/ZP banks.
        jsr     RestoreSystem

        ;; also used by launcher code
        target := *+1
        jmp     SELF_MODIFIED
.endproc ; ResetAndInvoke
        reset_and_invoke_target := ResetAndInvoke::target

;;; ============================================================

.proc HandleClientClick
        jsr     LoadActiveWindowEntryTable

        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        jeq     HandleContentClick ; 0 = ctl_not_a_control

        ;; --------------------------------------------------

        cmp     #MGTK::Ctl::dead_zone
    IF_EQ
        rts
    END_IF

        cmp     #MGTK::Ctl::vertical_scroll_bar
    IF_EQ
        ;; Vertical scrollbar
        lda     active_window_id
        jsr     WindowLookup
        stax    $06
        ldy     #MGTK::Winfo::vscroll
        lda     ($06),y
        and     #MGTK::Scroll::option_active
        bne     :+
        rts
:
        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::thumb
        jeq     DoTrackThumb

        cmp     #MGTK::Part::up_arrow
      IF_EQ
:       jsr     ScrollUp
        lda     #MGTK::Part::up_arrow
        jsr     CheckControlRepeat
        bpl     :-
        rts
      END_IF

        cmp     #MGTK::Part::down_arrow
      IF_EQ
:       jsr     ScrollDown
        lda     #MGTK::Part::down_arrow
        jsr     CheckControlRepeat
        bpl     :-
        rts
      END_IF

        cmp     #MGTK::Part::page_up
      IF_EQ
:       jsr     ScrollPageUp
        lda     #MGTK::Part::page_up
        jsr     CheckControlRepeat
        bpl     :-
        rts
      END_IF

:       jsr     ScrollPageDown
        lda     #MGTK::Part::page_down
        jsr     CheckControlRepeat
        bpl     :-
        rts
    END_IF

        ;; Horizontal scrollbar
        lda     active_window_id
        jsr     WindowLookup
        stax    $06
        ldy     #MGTK::Winfo::hscroll
        lda     ($06),y
        and     #MGTK::Scroll::option_active
        bne     :+
        rts
:
        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::thumb
        jeq     DoTrackThumb

        cmp     #MGTK::Part::left_arrow
      IF_EQ
:       jsr     ScrollLeft
        lda     #MGTK::Part::left_arrow
        jsr     CheckControlRepeat
        bpl     :-
        rts
      END_IF

        cmp     #MGTK::Part::right_arrow
      IF_EQ
:       jsr     ScrollRight
        lda     #MGTK::Part::right_arrow
        jsr     CheckControlRepeat
        bpl     :-
        rts
      END_IF

        cmp     #MGTK::Part::page_left
      IF_EQ
:       jsr     ScrollPageLeft
        lda     #MGTK::Part::page_left
        jsr     CheckControlRepeat
        bpl     :-
        rts
      END_IF

:       jsr     ScrollPageRight
        lda     #MGTK::Part::page_right
        jsr     CheckControlRepeat
        bpl     :-
        rts
.endproc ; HandleClientClick

;;; ============================================================

.proc DoTrackThumb
        lda     findcontrol_params::which_ctl
        sta     trackthumb_params::which_ctl
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        bne     :+
        rts
:
        lda     trackthumb_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     :+
        jmp     ScrollTrackVThumb
:       jmp     ScrollTrackHThumb
.endproc ; DoTrackThumb

;;; ============================================================
;;; Handle mouse held down on scroll arrow/pager

.proc CheckControlRepeat
        sta     ctl
        jsr     PeekEvent
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag
        beq     :+
bail:   return  #$FF            ; high bit set = not repeating

:       MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        beq     bail
        cmp     #MGTK::Ctl::dead_zone
        beq     bail
        lda     findcontrol_params::which_part
        ctl := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     bail
        return  #0              ; high bit set = repeating
.endproc ; CheckControlRepeat

;;; ============================================================

.proc HandleContentClick
        ;; Ignore clicks in the header area
        copy    active_window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     screentowindow_params::windowy
        cmp     #kWindowHeaderHeight
        bcs     :+
        rts
:
        copy    active_window_id, findicon_params::window_id
        ITK_CALL IconTK::FindIcon, findicon_params
        lda     findicon_params::which_icon
        bne     HandleFileIconClick

        ;; Not an icon - maybe a drag?
        lda     active_window_id
        jmp     DragSelect
.endproc ; HandleContentClick

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
        jmp     UnhighlightAndDeselectIcon ; deselect, nothing further

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
        copy    active_window_id, selected_window_id
:       lda     icon_num
        jmp     HighlightAndSelectIcon ; select, nothing further

replace_selection:
        jsr     ClearSelection
        copy    active_window_id, selected_window_id
        lda     icon_num
        jsr     HighlightAndSelectIcon
        FALL_THROUGH_TO check_double_click

        ;; --------------------------------------------------
check_double_click:
        jsr     StashCoordsAndDetectDoubleClick
        jpl     CmdOpenFromDoubleClick

        ;; --------------------------------------------------
        ;; Drag of file icon

        copy    icon_num, drag_drop_params::icon
        ITK_CALL IconTK::DragHighlighted, drag_drop_params
        tax
        lda     drag_drop_params::result
        beq     same_or_desktop

process_drop:
        jsr     DoDrop
        jmp     PerformPostDropUpdates

        ;; --------------------------------------------------

same_or_desktop:
        cpx     #2              ; not a drag
        beq     ignore

        cpx     #$FF
        beq     failure

        ;; Icons moved within window - update and redraw
        lda     active_window_id
        jsr     SafeSetPortFromWindowId ; ASSERT: not obscured

        jsr     CachedIconsScreenToWindow
        ;; Adjust grafport for header.
        jsr     OffsetWindowGrafportAndSet

        ldx     #0
:       txa
        pha
        copy    selected_icon_list,x, icon_param
        ITK_CALL IconTK::DrawIconRaw, icon_param ; CHECKED (drag)
        pla
        tax
        inx
        cpx     selected_icon_count
        bne     :-

        jsr     CachedIconsWindowToScreen
        jsr     ScrollUpdate

ignore: rts

failure:
        ldx     saved_stack
        txs
        rts

        ;; --------------------------------------------------

.endproc ; HandleFileIconClick
        ;; Used for delete shortcut; set `drag_drop_params::icon` first
        process_drop := HandleFileIconClick::process_drop

;;; ============================================================
;;; After an icon drop (file or volume), update any affected
;;; windows.
;;; Inputs: A = result from `DoDrop`, and `drag_drop_params::result`

.proc PerformPostDropUpdates
        ;; --------------------------------------------------
        ;; (1/4) Canceled?

        cmp     #kOperationCanceled
        ;; TODO: Refresh source/dest if partial success
    IF_EQ
        rts
    END_IF

        ;; Was a move?
        ;; NOTE: Only applies in file icon case.
        bit     move_flag
    IF_NS
        ;; Update source vol's contents
        jsr     MaybeStashDropTargetName ; in case target is in window...
        jsr     UpdateActiveWindow
        jsr     MaybeUpdateDropTargetFromName ; ...restore after update.
    END_IF

        ;; --------------------------------------------------
        ;; (2/4) Dropped on trash?

        ;; NOTE: Only applies in file icon case; this proc is not called
        ;; when dropping volume icons on trash.
        lda     drag_drop_params::result
        cmp     trash_icon_num
        ;; Update used/free for same-vol windows
    IF_EQ
        copy    #$80, validate_windows_flag
        bne     UpdateActiveWindow ; always
    END_IF

        ;; --------------------------------------------------
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

        ;; --------------------------------------------------
        ;; (4/4) Dropped on window!

        and     #$7F            ; mask off window number
        pha
        jsr     UpdateUsedFreeViaWindow
        pla
        jmp     SelectAndRefreshWindowOrClose

.proc UpdateActiveWindow
        lda     active_window_id
        jsr     UpdateUsedFreeViaWindow
        lda     active_window_id
        jmp     SelectAndRefreshWindowOrClose
.endproc ; UpdateActiveWindow

.endproc ; PerformPostDropUpdates

;;; ============================================================
;;; Add specified icon to selection list, and redraw.
;;; Input: A = icon number
;;; Assert: Icon is in active window/desktop, `selected_window_id` is set.

.proc HighlightAndSelectIcon
        sta     icon_param
        ITK_CALL IconTK::HighlightIcon, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param

        ldx     selected_icon_count
        copy    icon_param, selected_icon_list,x
        inc     selected_icon_count

        rts
.endproc ; HighlightAndSelectIcon

;;; ============================================================
;;; Remove specified icon from selection list, and redraw.
;;; Input: A = icon number
;;; Assert: Must be in selection list.

.proc UnhighlightAndDeselectIcon
        sta     icon_param
        ITK_CALL IconTK::UnhighlightIcon, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param

        lda     icon_param
        jmp     RemoveFromSelectionList
.endproc ; UnhighlightAndDeselectIcon

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
.endproc ; RemoveFromSelectionList

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
        jsr     CloseSpecifiedWindow
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
.endproc ; TrySelectAndRefreshWindow

exception_flag:
        .byte   0
.endproc ; SelectAndRefreshWindowOrClose

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
        jsr     ActivateWindowAndSelectIcon ; bring to front
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
        jsr     DestroyIconsInActiveWindow
        jsr     ClearActiveWindowEntryCount

        ;; Copy window path to `src_path_buf`
        lda     active_window_id
        jsr     GetWindowPath
        jsr     CopyToSrcPath

        ;; Load new FileRecords
        pla                     ; window id
        jsr     OpenDirectory

        ;; Draw header
        jsr     UpdateWindowUsedFreeDisplayValues
        lda     active_window_id
        jsr     UnsafeSetPortFromWindowId ; CHECKED
    IF_ZERO                     ; Skip drawing if obscured
        jsr     LoadActiveWindowEntryTable
        jsr     DrawWindowHeader
    END_IF

        ;; Create icons and draw contents
        jmp     ViewByCommon::entry3
.endproc ; SelectAndRefreshWindow

;;; ============================================================
;;; Clear the window background, following a call to either
;;; `UnsafeSetPortFromWindowId` or `UnsafeOffsetAndSetPortFromWindowId`

.proc ClearWindowBackgroundIfNotObscured
    IF_ZERO                     ; Skip drawing if obscured
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, window_grafport::maprect
    END_IF
        rts
.endproc ; ClearWindowBackgroundIfNotObscured

;;; ============================================================
;;; Drag Selection
;;; Inputs: A = window_id (0 for desktop)
;;; Assert: `cached_window_id` == A

.proc DragSelect
        sta     window_id

    IF_NOT_ZERO
        ;; Map initial event coordinates
        jsr     CoordsScreenToWindow
    END_IF

        ;; Stash initial coords
        ldx     #.sizeof(MGTK::Point)-1
:       lda     event_params::coords,x
        sta     tmp_rect::topleft,x
        sta     tmp_rect::bottomright,x
        sta     initial_pos,x
        dex
        bpl     :-

        ;; Is this actually a drag?
        jsr     PeekEvent
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag
        beq     :+              ; yes
        ;; No, just a click; optionally clear selection
        jsr     ExtendSelectionModifierDown
        jpl     ClearSelection  ; don't clear if mis-clicking
        rts
:

        ;; --------------------------------------------------
        ;; Prep selection
        lda     window_id
        cmp     selected_window_id
        bne     clear
        jsr     ExtendSelectionModifierDown
        bmi     :+
clear:  jsr     ClearSelection
:

        ;; --------------------------------------------------
        ;; Set up drawing port, draw initial rect
        lda     window_id
    IF_NOT_ZERO
        jsr     UnsafeOffsetAndSetPortFromWindowId ; ASSERT: not obscured
    ELSE
        jsr     InitSetDesktopPort
    END_IF

        jsr     FrameTmpRect

        ;; --------------------------------------------------
        ;; Event loop
event_loop:
        jsr     PeekEvent
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag
        jeq     update

        ;; Process all icons in window
        jsr     FrameTmpRect
        ldx     #0
iloop:  cpx     cached_window_entry_count
    IF_ZERO
        ;; Finished!
        lda     window_id
      IF_ZERO
        sta     selected_window_id
      END_IF
        rts
    END_IF

        ;; Check if icon should be selected
        txa
        pha
        copy    cached_window_entry_list,x, icon_param
        lda     window_id
    IF_NOT_ZERO
        lda     icon_param
        jsr     IconScreenToWindow
    END_IF
        ITK_CALL IconTK::IconInRect, icon_param
        beq     done_icon

        ;; Already selected?
        lda     icon_param
        jsr     IsIconSelected
    IF_NE
        ;; Highlight and add to selection
        ITK_CALL IconTK::HighlightIcon, icon_param
        ldx     selected_icon_count
        inc     selected_icon_count
        copy    icon_param, selected_icon_list,x
        copy    window_id, selected_window_id
    ELSE
        ;; Unhighlight and remove from selection
        ITK_CALL IconTK::UnhighlightIcon, icon_param
        lda     icon_param
        jsr     RemoveFromSelectionList
    END_IF

        lda     window_id
    IF_ZERO
        ITK_CALL IconTK::DrawIcon, icon_param ; CHECKED (drag select)
    ELSE
        ITK_CALL IconTK::DrawIconRaw, icon_param ; CHECKED (drag select)
    END_IF

done_icon:
        lda     window_id
    IF_NOT_ZERO
        lda     icon_param
        jsr     IconWindowToScreen
    END_IF
        pla
        tax
        inx
        jmp     iloop

        ;; --------------------------------------------------
        ;; Check movement threshold
update: lda     window_id
    IF_NOT_ZERO
        jsr     CoordsScreenToWindow
    END_IF
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

        scmp16  event_params::xcoord, initial_pos+MGTK::Point::xcoord
    IF_NEG
        copy16  event_params::xcoord, tmp_rect::x1
        copy16  initial_pos+MGTK::Point::xcoord, tmp_rect::x2
    ELSE
        copy16  initial_pos+MGTK::Point::xcoord, tmp_rect::x1
        copy16  event_params::xcoord, tmp_rect::x2
    END_IF

        scmp16  event_params::ycoord, initial_pos+MGTK::Point::ycoord
    IF_NEG
        copy16  event_params::ycoord, tmp_rect::y1
        copy16  initial_pos+MGTK::Point::ycoord, tmp_rect::y2
    ELSE
        copy16  initial_pos+MGTK::Point::ycoord, tmp_rect::y1
        copy16  event_params::ycoord, tmp_rect::y2
    END_IF

        jsr     FrameTmpRect
        jmp     event_loop

window_id:                      ; 0 = desktop, assumed to be active otherwise
        .byte   0

deltax: .word   0
deltay: .word   0
initial_pos:
        .tag    MGTK::Point
last_pos:
        .tag    MGTK::Point

.proc CoordsScreenToWindow
        jsr     PushPointers
        jsr     PrepActiveWindowScreenMapping

        ;; Point at an imaginary `IconEntry`, to map
        ;; `event_params::coords` from screen to window.
        ldax    #(event_params::coords - IconEntry::iconx)
        jsr     IconPtrScreenToWindow

        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; CoordsScreenToWindow
.endproc ; DragSelect

;;; ============================================================

.proc HandleTitleClick
        copy    active_window_id, dragwindow_params::window_id

        jsr     LoadActiveWindowEntryTable
        jsr     CachedIconsScreenToWindow

        MGTK_CALL MGTK::DragWindow, dragwindow_params
        ;; `dragwindow_params::moved` is not checked; harmless if it didn't.

        jsr     CachedIconsWindowToScreen
        jsr     StoreWindowEntryTable

        rts
.endproc ; HandleTitleClick

;;; ============================================================

.proc HandleResizeClick
        copy    active_window_id, event_params
        MGTK_CALL MGTK::GrowWindow, event_params
        jmp     ScrollUpdate
.endproc ; HandleResizeClick

;;; ============================================================

.proc HandleCloseClick
        lda     active_window_id
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        bne     :+
        rts

        ;; If modifier is down, close all windows
:       jsr     ModifierDown
        jmi     CmdCloseAll

        FALL_THROUGH_TO CloseActiveWindow
.endproc ; HandleCloseClick

;;; Close the active window
.proc CloseActiveWindow
        lda     active_window_id
        FALL_THROUGH_TO CloseSpecifiedWindow
.endproc ; CloseActiveWindow

;;; Inputs: A = window_id
.proc CloseSpecifiedWindow
        icon_ptr := $06

        jsr     LoadWindowEntryTable

        jsr     ClearSelection

        lda     icon_count
        sec
        sbc     cached_window_entry_count
        sta     icon_count

        ITK_CALL IconTK::RemoveAll, cached_window_id

        jsr     FreeCachedWindowIcons

        dec     num_open_windows
        copy    #0, cached_window_entry_count
        jsr     StoreWindowEntryTable

        MGTK_CALL MGTK::CloseWindow, cached_window_id

        ;; --------------------------------------------------
        ;; Do we have a parent icon for this window?

        copy    #0, icon
        ldx     cached_window_id
        lda     window_to_dir_icon_table-1,x
        bmi     :+              ; $FF = dir icon freed

        sta     icon

        ;; Animate closing into dir (vol/folder) icon
        ldx     cached_window_id
        lda     window_to_dir_icon_table-1,x
        jsr     AnimateWindowClose ; A = icon id, X = window id
:
        ;; --------------------------------------------------
        ;; Tidy up after closing window

        lda     cached_window_id
        jsr     RemoveWindowFilerecordEntries

        ldx     cached_window_id
        lda     #0
        sta     window_to_dir_icon_table-1,x ; 0 = window free
        sta     win_view_by_table-1,x

        ;; Was it the active window?
        lda     cached_window_id
        cmp     active_window_id
    IF_EQ
        ;; Yes, update all the things
        MGTK_CALL MGTK::FrontWindow, active_window_id
        jsr     UncheckViewMenuItem
        jsr     UpdateWindowMenuItems
    END_IF

        jsr     ClearUpdates ; following CloseWindow above

        ;; --------------------------------------------------
        ;; Clean up the parent icon (if any)

        icon := *+1
        lda     #SELF_MODIFIED_BYTE
        beq     finish          ; none

        sta     icon_param
        jsr     GetIconEntry
        stax    icon_ptr

        ldy     #IconEntry::state ; clear dimmed state
        lda     (icon_ptr),y
        and     #AS_BYTE(~kIconEntryStateDimmed)
        sta     (icon_ptr),y

        .assert IconEntry::win_flags = IconEntry::state + 1, error, "enum mismatch"
        iny
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask ; which window?
        beq     :+              ; desktop, can draw/select
        cmp     active_window_id
        bne     redraw          ; not top window, skip select
:
        ;; Set selection and redraw
        sta     selected_window_id
        copy    #1, selected_icon_count
        copy    icon, selected_icon_list
        ITK_CALL IconTK::HighlightIcon, icon_param

redraw: ITK_CALL IconTK::DrawIcon, icon_param
finish: rts
.endproc ; CloseSpecifiedWindow

;;; ============================================================
;;; Check windows and close any where the backing volume/file no
;;; longer exists.

;;; Set to $80 to run a validation pass and close as needed.
validate_windows_flag:
        .byte   0

.proc ValidateWindows
        bit     validate_windows_flag
        bpl     done
        copy    #0, validate_windows_flag

        copy    #kMaxDeskTopWindows, window_id

loop:
        ;; Check if the window is in use
        window_id := *+1
        ldx     #SELF_MODIFIED_BYTE
        lda     window_to_dir_icon_table-1,x
        beq     next

        ;; Get and copy its path somewhere useful
        txa
        jsr     GetWindowPath
        jsr     CopyToSrcPath

        ;; See if it exists
        jsr     GetSrcFileInfo
        beq     next

        ;; Nope - close the window
        lda     window_id
        jsr     CloseSpecifiedWindow

next:   dec     window_id
        bne     loop

done:   rts
.endproc ; ValidateWindows

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
.endproc ; ApplyActiveWinfoToWindowGrafport

;;; NOTE: Does not update icon positions, so only use in empty windows.
.proc ResetActiveWindowViewport
        jsr     ApplyActiveWinfoToWindowGrafport
        sub16   window_grafport::maprect::x2, window_grafport::maprect::x1, window_grafport::maprect::x2
        sub16   window_grafport::maprect::y2, window_grafport::maprect::y1, window_grafport::maprect::y2
        copy16  #0, window_grafport::maprect::x1
        copy16  #0, window_grafport::maprect::y1
        FALL_THROUGH_TO AssignActiveWindowCliprect
.endproc ; ResetActiveWindowViewport

.proc AssignActiveWindowCliprect
        ptr := $6

        lda     active_window_id
        jsr     WindowLookup
        stax    ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     window_grafport::maprect,x
        sta     (ptr),y
        dey
        dex
        bpl     :-
        rts
.endproc ; AssignActiveWindowCliprect

.proc AssignActiveWindowCliprectAndUpdateCachedIcons
        jsr     CachedIconsScreenToWindow
        jsr     AssignActiveWindowCliprect
        jmp     CachedIconsWindowToScreen
.endproc ; AssignActiveWindowCliprectAndUpdateCachedIcons


;;; ============================================================
;;; After scrolling which adjusts maprect, redraw the contents.
;;; The header is not redrawn.

.proc RedrawAfterScroll
        ;; Clear content background, not header
        lda     active_window_id
        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        jsr     ClearWindowBackgroundIfNotObscured

        ;; Only draw content, not header
        lda     #kDrawWindowEntriesContentOnly
        jmp     DrawWindowEntries
.endproc ; RedrawAfterScroll

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
        jmp     CheckViewMenuItem
.endproc ; UpdateWindowMenuItems

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

:       MGTK_CALL MGTK::DisableMenu, disablemenu_params ; View menu

        copy    #kMenuIdFile, disableitem_params::menu_id
        lda     #aux::kMenuItemIdNewFolder
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdClose
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdCloseAll
        jsr     DisableMenuItem

        rts
.endproc ; ToggleMenuItemsRequiringWindow
EnableMenuItemsRequiringWindow := ToggleMenuItemsRequiringWindow::enable
DisableMenuItemsRequiringWindow := ToggleMenuItemsRequiringWindow::disable


;;; ============================================================
;;; Disable menu items for operating on a selection

.proc ToggleMenuItemsRequiringSelection
enable: lda     #MGTK::disableitem_enable
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
        .assert MGTK::disableitem_disable <> $C0, error, "Bad BIT skip"
disable:lda     #MGTK::disableitem_disable
        sta     disableitem_params::disable

        ;; File
        copy    #kMenuIdFile, disableitem_params::menu_id
        lda     #aux::kMenuItemIdOpen
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdGetInfo
        jsr     DisableMenuItem

        ;; Special
        copy    #kMenuIdSpecial, disableitem_params::menu_id
        lda     #aux::kMenuItemIdLock
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdUnlock
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdGetSize
        jmp     DisableMenuItem
.endproc ; ToggleMenuItemsRequiringSelection
EnableMenuItemsRequiringSelection := ToggleMenuItemsRequiringSelection::enable
DisableMenuItemsRequiringSelection := ToggleMenuItemsRequiringSelection::disable

;;; ============================================================
;;; Disable menu items for operating on a single selection

.proc ToggleMenuItemsRequiringSingleSelection
enable: lda     #MGTK::disableitem_enable
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
        .assert MGTK::disableitem_disable <> $C0, error, "Bad BIT skip"
disable:lda     #MGTK::disableitem_disable
        sta     disableitem_params::disable

        ;; File
        copy    #kMenuIdFile, disableitem_params::menu_id
        lda     #aux::kMenuItemIdRenameIcon
        jmp     DisableMenuItem
.endproc ; ToggleMenuItemsRequiringSingleSelection
EnableMenuItemsRequiringSingleSelection := ToggleMenuItemsRequiringSingleSelection::enable
DisableMenuItemsRequiringSingleSelection := ToggleMenuItemsRequiringSingleSelection::disable

;;; ============================================================
;;; Calls DisableItem menu_item in A (to enable or disable).
;;; Set disableitem_params' disable flag and menu_id before calling.

.proc DisableMenuItem
        sta     disableitem_params::menu_item
        MGTK_CALL MGTK::DisableItem, disableitem_params
        rts
.endproc ; DisableMenuItem

;;; ============================================================

.proc ToggleMenuItemsRequiringFileSelection
enable: lda     #MGTK::disableitem_enable
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
        .assert MGTK::disableitem_disable <> $C0, error, "Bad BIT skip"
disable:lda     #MGTK::disableitem_disable
        sta     disableitem_params::disable

        copy    #kMenuIdFile, disableitem_params::menu_id
        lda     #aux::kMenuItemIdDuplicate
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdCopyFile
        jsr     DisableMenuItem
        lda     #aux::kMenuItemIdDeleteFile
        jsr     DisableMenuItem

        rts

.endproc ; ToggleMenuItemsRequiringFileSelection
EnableMenuItemsRequiringFileSelection := ToggleMenuItemsRequiringFileSelection::enable
DisableMenuItemsRequiringFileSelection := ToggleMenuItemsRequiringFileSelection::disable

;;; ============================================================

.proc ToggleMenuItemsRequiringVolumeSelection
enable: lda     #MGTK::disableitem_enable
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
        .assert MGTK::disableitem_disable <> $C0, error, "Bad BIT skip"
disable:lda     #MGTK::disableitem_disable
        sta     disableitem_params::disable

        copy    #kMenuIdSpecial, disableitem_params::menu_id
        lda     #aux::kMenuItemIdEject
        jsr     DisableMenuItem

        copy    #kMenuIdSpecial, disableitem_params::menu_id
        lda     #aux::kMenuItemIdCheckDrive
        jsr     DisableMenuItem

        rts

.endproc ; ToggleMenuItemsRequiringVolumeSelection
EnableMenuItemsRequiringVolumeSelection := ToggleMenuItemsRequiringVolumeSelection::enable
DisableMenuItemsRequiringVolumeSelection := ToggleMenuItemsRequiringVolumeSelection::disable

;;; ============================================================

.proc ToggleSelectorMenuItems
enable: lda     #MGTK::disableitem_enable
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
        .assert MGTK::disableitem_disable <> $C0, error, "Bad BIT skip"
disable:lda     #MGTK::disableitem_disable
        sta     disableitem_params::disable

        copy    #kMenuIdSelector, disableitem_params::menu_id
        lda     #kMenuItemIdSelectorEdit
        jsr     DisableMenuItem
        lda     #kMenuItemIdSelectorDelete
        jsr     DisableMenuItem
        lda     #kMenuItemIdSelectorRun
        jsr     DisableMenuItem
        copy    #$80, selector_menu_items_updated_flag
        rts
.endproc ; ToggleSelectorMenuItems
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
        lda     findicon_params::which_icon
        jmp     UnhighlightAndDeselectIcon ; deselect, nothing further

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
:       lda     findicon_params::which_icon
        jmp     HighlightAndSelectIcon ; select, nothing further

        ;; Replace selection with clicked icon
replace_selection:
        jsr     ClearSelection
        lda     findicon_params::which_icon
        jsr     HighlightAndSelectIcon
        FALL_THROUGH_TO check_double_click

        ;; --------------------------------------------------
check_double_click:
        jsr     StashCoordsAndDetectDoubleClick
        jpl     CmdOpenFromDoubleClick

        ;; --------------------------------------------------
        ;; Drag of volume icon

        copy    findicon_params::which_icon, drag_drop_params::icon
        ITK_CALL IconTK::DragHighlighted, drag_drop_params
        tax
        lda     drag_drop_params::result
        beq     same_or_desktop

        jsr     DoDrop
        ;; NOTE: If drop target is trash, `JTDrop` relays to
        ;; `CmdEject` and pops the return address.
        jmp     PerformPostDropUpdates

        ;; --------------------------------------------------

same_or_desktop:
        cpx     #2              ; file icon dragged to desktop?
        beq     ignore

        ;; Icons moved on desktop - update and redraw
        ldx     #0
:       txa
        pha
        copy    selected_icon_list,x, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param
        pla
        tax
        inx
        cpx     selected_icon_count
        bne     :-

ignore: rts

.endproc ; HandleVolumeIconClick

;;; ============================================================
;;; Open a folder/volume icon
;;; Input: A = icon
;;; Note: stack will be restored via `saved_stack` on failure

.proc OpenWindowForIcon
        ptr := $06

        sta     icon_param

        ;; Already an open window for the icon?
        ldx     #kMaxDeskTopWindows-1
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
        jsr     GetIconPath     ; `path_buf3` set to path, A=0 on success
    IF_NE
        jsr     ShowAlert       ; A has error if `GetIconPath` fails

        jsr     RemoveFileRecordsForIcon ; TODO: Is this needed?
        jsr     MarkIconNotDimmed

        dec     num_open_windows
        ldx     saved_stack
        txs
        rts
    END_IF
        param_call CopyToSrcPath, path_buf3

        ;; Alternate entry point, called by:
        ;; `OpenWindowForPath` with `icon_param` = $FF
        ;; and `src_path_buf` set.
check_path:
        jsr     FindWindowForSrcPath
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
        cmp     #kMaxDeskTopWindows
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

        txa
        jsr     LoadWindowEntryTable

        ;; Update View and other menus
        inc     num_open_windows
        ldx     cached_window_id
        ;; TODO: Will need update here
        copy    #kViewByIcon, win_view_by_table-1,x

        lda     num_open_windows ; Was there already a window open?
        cmp     #2
    IF_LT
        jsr     EnableMenuItemsRequiringWindow
    ELSE
        jsr     UncheckViewMenuItem
        ;; Correct item will be checked below after window opens
    END_IF

        ;; This ensures `ptr` points at IconEntry (real or virtual)
        jsr     UpdateIcon

        ;; Set path (using `ptr`), size, contents, and volume free/used.
        jsr     PrepareNewWindow

        ;; Create the window
        lda     cached_window_id
        jsr     WindowLookup   ; A,X points at Winfo
        stax    @addr
        MGTK_CALL MGTK::OpenWindow, 0, @addr

        jsr     CheckViewMenuItemForActiveWindow

        lda     active_window_id
        jsr     UnsafeSetPortFromWindowId ; CHECKED
        bne     :+              ; Skip drawing if obscured
        jsr     DrawWindowHeader
:
        jmp     RedrawAfterContentChange


;;; Common code to update the dir (vol/folder) icon.
;;; * If `icon_param` is valid:
;;;   Points `ptr` at IconEntry, marks it open and repaints it, and sets `ptr`.
;;; * Otherwise:
;;;   Points `ptr` at a virtual IconEntry, to allow referencing the icon name.
.proc UpdateIcon
        lda     icon_param      ; set to $FF if opening via path
        jpl     MarkIconOpen

        ;; Find last '/'
        ldy     src_path_buf
:       lda     src_path_buf,y
        cmp     #'/'
        beq     :+
        dey
        bpl     :-
:
        ;; Start building string
        ldx     #0

:       iny
        inx
        lda     src_path_buf,y
        sta     buf_filename,x
        cpy     src_path_buf
        bne     :-

        stx     buf_filename

        ;; Adjust ptr as if it's pointing at an IconEntry
        copy16  #buf_filename - IconEntry::name, ptr
        rts
.endproc ; UpdateIcon
.endproc ; OpenWindowForIcon

;;; ============================================================
;;; Marks icon as open and repaints it.
;;; Input: A = icon id
;;; Output: `ptr` ($06) points at IconEntry

.proc MarkIconOpen
        ptr := $06
        sta     icon_param
        jsr     GetIconEntry
        stax    ptr

        ;; Set dimmed flag
        ldy     #IconEntry::state
        lda     (ptr),y
        ora     #kIconEntryStateDimmed
        sta     (ptr),y

        ITK_CALL IconTK::DrawIcon, icon_param
        rts
.endproc ; MarkIconOpen

;;; ============================================================
;;; Give a file path, tries to open/show a window for the containing
;;; directory, and if successful select/show the file.
;;; Input: `INVOKER_PREFIX` has full path to file
;;; Assert: Path is not a volume path

.proc ShowFileWithPath
        jsr     SplitInvokerPath

        tsx
        stx     saved_stack
        jsr     OpenWindowForPath

        param_jump SelectFileIconByName, INVOKER_FILENAME
.endproc ; ShowFileWithPath

;;; ============================================================
;;; Open a folder/volume icon
;;; Input: `src_path_buf` should have full path.
;;;   If a case match for existing window path, it will be activated.
;;; Note: stack will be restored via `saved_stack` on failure
;;;
;;; Set `suppress_error_on_open_flag` to avoid alert.

.proc OpenWindowForPath
        jsr     ClearSelection
        copy    #$FF, icon_param
        jsr     OpenWindowForIcon::check_path

        ;; Is there already an icon associated with this window?
        ldx     active_window_id
        lda     window_to_dir_icon_table-1,x
        bpl     ret             ; yes, so skip

        ;; Try to find a matching volume or folder icon.
        COPY_STRING src_path_buf, path_buf4
        param_call FindLastPathSegment, path_buf4
        cpy     path_buf4       ; was there a filename?
    IF_EQ
        ;; Volume - make it a filename
        ldx     path_buf4       ; Strip '/'
        dex
        stx     path_buf4+1
        ldax    #path_buf4+1
        ldy     #0              ; 0=desktop
    ELSE
        ;; File - need to see if there's a window
        jsr     SplitPathBuf4
        param_call FindWindowForPath, path_buf4
        beq     ret             ; no matching window
        tay                     ; Y=window id
        ldax    #filename_buf   ; A,X=filename
    END_IF
        jsr     FindIconByName
        beq     ret             ; no matching icon

        ;; Associate window with icon, and mark it open.
        ldx     active_window_id
        sta     window_to_dir_icon_table-1,x
        jsr     MarkIconOpen

ret:    rts
.endproc ; OpenWindowForPath

;;; ============================================================

;;; Inputs: A = MGTK::checkitem_check or MGTK::checkitem_uncheck
;;; Assumes checkitem_params::menu_item has been updated or is last checked.
.proc CheckViewMenuItemImpl
check:  lda     #MGTK::checkitem_check
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
        .assert MGTK::checkitem_uncheck <> $C0, error, "Bad BIT skip"
uncheck:lda     #MGTK::checkitem_uncheck

        sta     checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        rts
.endproc ; CheckViewMenuItemImpl
CheckViewMenuItem := CheckViewMenuItemImpl::check
UncheckViewMenuItem := CheckViewMenuItemImpl::uncheck

;;; ============================================================
;;; Draw all entries (icons or list items) in (cached) window
;;; Input: A=flag
;;;
;;; Called from:
;;; * `UpdateWindow` flag=$80
;;; * `ActivateWindow`; flag=$00
;;; * `RedrawAfterContentChange`; flag=$40
;;; * `RedrawAfterScroll`; flag=$40
kDrawWindowEntriesHeaderAndContent        = $00
kDrawWindowEntriesContentOnly             = $40
kDrawWindowEntriesContentOnlyPortAdjusted = $80

.proc DrawWindowEntries
        sta     header_and_offset_flag

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

        ;; --------------------------------------------------
        ;; Icons

        ;; Map icons to window space
        jsr     CachedIconsScreenToWindow

        ITK_CALL IconTK::DrawAll, cached_window_id

.ifdef DEBUG
        jsr     ComputeIconsBBox
        COPY_STRUCT MGTK::Rect, iconbb_rect, tmp_rect
        jsr     FrameTmpRect
.endif

        ;; Map icons back to screen space
        jsr     CachedIconsWindowToScreen

        ;; --------------------------------------------------
        ;; List View Columns

        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
        bpl     done

        ;; Find FileRecord list
        lda     cached_window_id
        jsr     GetFileRecordListForWindow
        stax    file_record_ptr ; points at head of list (entry count)
        inc16   file_record_ptr ; now points at first entry in list

        ;; First row
        ldax    #kListViewFirstBaseline
        stax    pos_col_type::ycoord
        stax    pos_col_size::ycoord
        stax    pos_col_date::ycoord

        ;; Draw each list view row
        lda     #0
        sta     rows_done
        rows_done := *+1
rloop:  lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     done
        tax
        lda     cached_window_entry_list,x

        ;; Look up file record number
        jsr     GetIconRecordNum
        jsr     DrawListViewRow
        inc     rows_done
        jmp     rloop

        ;; --------------------------------------------------
done:
        jsr     PopPointers     ; do not tail-call optimise!
        rts

;;; * If $80 N=1 V=?: the caller has offset the winfo's port; the
;;;   header is not drawn and the port is not adjusted.
;;; * If $40 N=0 V=1: skips drawing the header and offsets the port
;;;   for the content.
;;; * If $00 N=0 V=0: draws the header, then adjusts the port and
;;;   draws the content.
header_and_offset_flag:
        .byte   0
.endproc ; DrawWindowEntries

;;; ============================================================

.proc ClearSelection
        lda     selected_icon_count
        bne     :+
        rts
:
        ;; --------------------------------------------------
        ;; Mark the icons as not highlighted
        ldx     #0
:       txa
        pha
        copy    selected_icon_list,x, icon_param
        ITK_CALL IconTK::UnhighlightIcon, icon_param
        pla
        tax
        inx
        cpx     selected_icon_count
        bne     :-

        ;; --------------------------------------------------
        ;; Repaint the icons
        lda     selected_window_id
    IF_ZERO
        ;; Desktop
        ldx     #0
:       txa
        pha
        copy    selected_icon_list,x, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param ; CHECKED (desktop)
        pla
        tax
        inx
        cpx     selected_icon_count
        bne     :-
    ELSE
        ;; Windowed - use a clipped port for the window
        cmp     active_window_id ; in the active window?
        bne     skip             ; TODO: This should not be possible

        jsr     UnsafeOffsetAndSetPortFromWindowId ; CHECKED
        bne     skip             ; obscured

        jsr     PushPointers
        jsr     PrepActiveWindowScreenMapping

        ldx     #0
:       txa
        pha                     ; A = index
        copy    selected_icon_list,x, icon_param
        pha                     ; A = icon id
        jsr     GetIconEntry
        jsr     IconPtrScreenToWindow
        ITK_CALL IconTK::DrawIconRaw, icon_param ; CHECKED
        pla                     ; A = icon id
        jsr     GetIconEntry
        jsr     IconPtrWindowToScreen
        pla                     ; A = index
        tax
        inx
        cpx     selected_icon_count
        bne     :-
        jsr     PopPointers     ; do not tail-call optimize!

skip:
    END_IF

        ;; --------------------------------------------------
        ;; Clear selection list
        lda     #0
        sta     selected_icon_count
        sta     selected_window_id
        rts
.endproc ; ClearSelection

;;; ============================================================

.proc CachedIconsScreenToWindow
        jsr     PushPointers
        jsr     PrepActiveWindowScreenMapping

        copy    #0, index
        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     done

        tax
        lda     cached_window_entry_list,x
        jsr     GetIconEntry
        jsr     IconPtrScreenToWindow

        inc     index
        jmp     loop

done:   jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc ; CachedIconsScreenToWindow

;;; ============================================================

.proc CachedIconsWindowToScreen
        jsr     PushPointers
        jsr     PrepActiveWindowScreenMapping

        copy    #0, index
        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     done

        tax
        lda     cached_window_entry_list,x
        jsr     GetIconEntry
        jsr     IconPtrWindowToScreen

        inc     index
        jmp     loop

done:   jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc ; CachedIconsWindowToScreen

;;; ============================================================
;;; Adjust grafport for header.
.proc OffsetWindowGrafportImpl

        kOffset = kWindowHeaderHeight

noset:  lda     #$80
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
set:    lda     #0
        sta     flag
        add16_8 window_grafport::viewloc::ycoord, #kOffset
        add16_8 window_grafport::maprect::y1, #kOffset
        bit     flag
        bmi     :+
        MGTK_CALL MGTK::SetPort, window_grafport
:       rts

flag:   .byte   0
.endproc ; OffsetWindowGrafportImpl
OffsetWindowGrafport    := OffsetWindowGrafportImpl::noset
OffsetWindowGrafportAndSet      := OffsetWindowGrafportImpl::set

;;; ============================================================

.proc UpdateWindowUsedFreeDisplayValues
        lda     active_window_id
        asl
        tax
        copy16  window_k_used_table-2,x, window_draw_k_used_table-2,x ; 1-based to 0-based
        copy16  window_k_free_table-2,x, window_draw_k_free_table-2,x
        rts
.endproc ; UpdateWindowUsedFreeDisplayValues

;;; ============================================================
;;; Update used/free values for windows related to volume icon
;;; Input: A = icon number

.proc UpdateUsedFreeViaIcon
        jsr     GetIconPath     ; `path_buf3` set to path, A=0 on success
    IF_NE
        rts                     ; too long
    END_IF
        param_jump UpdateUsedFreeViaPath, path_buf3
.endproc ; UpdateUsedFreeViaIcon

;;; ============================================================
;;; Refresh vol used/free for windows of same volume as win in A.
;;; Input: A = window id

.proc UpdateUsedFreeViaWindow
        jsr     GetWindowPath   ; into A,X
        jmp     UpdateUsedFreeViaPath
.endproc ; UpdateUsedFreeViaWindow

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

        ;; Temporarily change path length
        tya
        ldy     #0
        sta     (ptr),y

        ;; Update `found_windows_count` and `found_windows_list`
        param_call_indirect FindWindowsForPrefix, ptr

        ;; Restore path length
        ldy     #0
        lda     pathlen
        sta     (ptr),y

        ;; Determine if there are windows to update
        jsr     PopPointers     ; $06 = vol path

        ldax    ptr
        jsr     CopyToSrcPath
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
.endproc ; UpdateUsedFreeViaPath

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
.endproc ; FindLastPathSegment

;;; ============================================================

.proc FindWindowForSrcPath
        ldax    #src_path_buf
        FALL_THROUGH_TO FindWindowForPath
.endproc ; FindWindowForSrcPath

;;; ============================================================
;;; `FindWindowForPath`
;;; Inputs: A,X = string
;;; Output: A = window id (0 if no match)
;;;
;;; `FindWindowsForPrefix`
;;; Inputs: A,X = string
;;; Outputs: `found_windows_count` and `found_windows_list` are updated

.proc FindWindowsImpl
        ptr1 := $6
        ptr2 := $8

exact:  ldy     #$80
        bne     start           ; always

prefix: ldy     #0


start:  stax    ptr1
        sty     exact_match_flag

        lda     #0
        sta     found_windows_count
        sta     window_num

loop:   inc     window_num

        window_num := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #kMaxDeskTopWindows+1 ; directory windows are 1-8
        bcc     check_window
        bit     exact_match_flag
        bpl     :+
        lda     #0
:       rts

check_window:
        tax
        lda     window_to_dir_icon_table-1,x
        beq     loop

        lda     window_num
        jsr     GetWindowPath
        stax    ptr2

        bit     exact_match_flag
    IF_NS
        jsr     CompareStrings  ; Z=1 if equal
        bne     loop
        return  window_num
    END_IF

        jsr     IsPathPrefixOf  ; Z=0 if prefix
        beq     loop
        ldx     found_windows_count
        lda     window_num
        sta     found_windows_list,x
        inc     found_windows_count
        bne     loop            ; always

exact_match_flag:
        .byte   0
.endproc ; FindWindowsImpl
        FindWindowForPath := FindWindowsImpl::exact
        FindWindowsForPrefix := FindWindowsImpl::prefix

found_windows_count:
        .byte   0
found_windows_list:
        .res    8

;;; ============================================================

.proc OpenDirectory
        jmp     Start

        DEFINE_OPEN_PARAMS open_params, src_path_buf, $800

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
        jsr     GetVolUsedFreeViaPath ; uses `src_path_buf`

        ldx     #0
:       lda     dir_buffer+SubdirectoryHeader::entry_length,x
        sta     dir_header,x
        inx
        cpx     #.sizeof(dir_header)
        bne     :-

        ;; Is there room for the files?
        lda     dir_header::file_count+1 ; > 255?
        bne     too_many_files  ; yep, definitely not enough room

        ;; How many more icons can we allocate?
        lda     #kMaxIconCount - 2 ; -1 for `DEVCNT` off-by-one, -1 for Trash
        sec
        sbc     icon_count      ; actual number in use
        clc
        adc     window_entry_count_table ; but don't count desktop icons...
        sec
        sbc     DEVCNT   ; count _potential_ number of desktop icons

        ;; Can we fit them all?
        cmp     dir_header::file_count
        bcs     enough_room

too_many_files:
        jsr     DoClose

        lda     active_window_id ; is a window open?
        beq     no_win
        lda     #kErrWindowMustBeClosed ; suggest closing a window
        bne     show            ; always
no_win: lda     #kErrTooManyFiles ; too many files to show
show:   jsr     ShowAlert

        ;; Records not created, no need for `RemoveFileRecordsForIcon`
        jsr     MarkIconNotDimmed
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
        jeq     finish

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
        ldy     #.sizeof(FileRecord)-1
:       lda     record,y
        sta     (record_ptr),y
        dey
        bpl     :-
        bit     LCBANK1
        bit     LCBANK1
        add16_8 record_ptr, #.sizeof(FileRecord)
        jmp     do_entry

finish: copy16  record_ptr, filerecords_free_start
        jsr     DoClose
        jsr     SetCursorPointer ; after loading directory
        jsr     PopPointers      ; do not tail-call optimise!
        rts
.endproc ; Start

;;; --------------------------------------------------

.proc DoOpen
        MLI_CALL OPEN, open_params
        beq     done

        ;; On error, clean up state

        ;; Show error, unless this is during window restore.
        bit     suppress_error_on_open_flag
        bmi     :+
        jsr     ShowAlert

        ;; If opening an icon, need to reset icon state.
:       bit     icon_param      ; Were we opening a path?
        bmi     :+              ; Yes, no icons to twiddle.

        jsr     RemoveFileRecordsForIcon ; TODO: Is this needed?
        jsr     MarkIconNotDimmed

        lda     selected_window_id
        bne     :+

        ;; Volume icon - check that it's still valid.
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
.endproc ; DoOpen

suppress_error_on_open_flag:
        .byte   0

;;; --------------------------------------------------

DoRead:
        MLI_CALL READ, read_params
        rts

DoClose:
        MLI_CALL CLOSE, close_params
        rts

;;; --------------------------------------------------
.endproc ; OpenDirectory

;;; ============================================================
;;; Inputs: `src_path_buf` set to full path (not modified)
;;; Outputs: Z=1 on success, `vol_kb_used` and `vol_kb_free` updated.
;;; TODO: Skip if same-vol windows already have data.

.proc GetVolUsedFreeViaPath
        copy    src_path_buf, saved_length

        ;; Strip to vol name - either end of string or next slash
        ldx     #1
:       inx                     ; start at 2nd character
        cpx     src_path_buf
        beq     :+
        lda     src_path_buf,x
        cmp     #'/'
        bne     :-
        dex
:       stx     src_path_buf

        ;; Get volume information
        jsr     GetSrcFileInfo
        bne     finish          ; failure

        ;; aux = total blocks
        copy16  src_file_info_params::aux_type, vol_kb_used
        ;; total - used = free
        sub16   src_file_info_params::aux_type, src_file_info_params::blocks_used, vol_kb_free
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
        sta     src_path_buf

        plp
        rts
.endproc ; GetVolUsedFreeViaPath

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
        ecmp16  ptr_src, filerecords_free_start
        bne     loop

        jsr     PopPointers     ; do not tail-call optimise!

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
.endproc ; RemoveWindowFilerecordEntries

;;; ============================================================
;;; Set up path and coords for new window, contents and free/used.
;;; Inputs: IconEntry pointer in $06, new window id in `cached_window_id`,
;;;         `src_path_buf` has full path
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

        add16_8 icon_ptr, #IconEntry::name, name_ptr

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
        ldy     src_path_buf
:       lda     src_path_buf,y
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

        ;; Map rect (initially empty, size assigned in `ComputeInitialWindowSize`)
        lda     #0
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       sta     (winfo_ptr),y
        dey
        dex
        bpl     :-

        ;; --------------------------------------------------
        ;; Scrollbars - start off inactive but ready to go

        lda     #MGTK::Scroll::option_present | MGTK::Scroll::option_thumb
        ldy     #MGTK::Winfo::hscroll
        sta     (winfo_ptr),y
        .assert MGTK::Winfo::vscroll = MGTK::Winfo::hscroll + 1, error, "enum mismatch"
        iny
        sta     (winfo_ptr),y

        ;; --------------------------------------------------
        ;; Read FileRecords

        lda     cached_window_id
        jsr     OpenDirectory

        ;; --------------------------------------------------
        ;; Update used/free table

        lda     icon_param      ; set to $FF if opening via path
        pha
        bmi     volume

        jsr     GetIconEntry
        stax    icon_ptr
        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        beq     volume

        ;; Windowed (folder) icon
        asl     a
        tax
        copy16  window_k_used_table-2,x, vol_kb_used ; 1-based to 0-based
        copy16  window_k_free_table-2,x, vol_kb_free

        ;; TODO: Missing branch here?

        ;; Desktop (volume) icon
volume: lda     cached_window_id
        asl     a
        tax
        copy16  vol_kb_used, window_k_used_table-2,x ; 1-based to 0-based
        copy16  vol_kb_free, window_k_free_table-2,x

        copy16  window_k_used_table-2,x, window_draw_k_used_table-2,x ; 1-based to 0-based
        copy16  window_k_free_table-2,x, window_draw_k_free_table-2,x

        ;; --------------------------------------------------
        ;; Create window and icons

        bit     copy_new_window_bounds_flag
    IF_NS
        ;; kViewByXXX
        ldx     cached_window_id
        copy    new_window_view_by, win_view_by_table-1,x

        ;; viewloc
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + .sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     new_window_viewloc,x
        sta     (winfo_ptr),y
        dey
        dex
        bpl     :-

        ;; maprect
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     new_window_maprect,x
        sta     (winfo_ptr),y
        dey
        dex
        bpl     :-
    END_IF

        jsr     InitWindowEntriesAndIcons

        bit     copy_new_window_bounds_flag
    IF_NC
        jsr     ComputeInitialWindowSize
        jsr     AdjustViewportForNewIcons
    END_IF

        ;; --------------------------------------------------
        ;; Animate the window being opened (if needed)

        pla                    ; A = source icon ($FF if from path)
        bmi     :+             ; TODO: Find some plausible source icon
        ldx     cached_window_id
        jsr     AnimateWindowOpen
:
        rts
.endproc ; PrepareNewWindow

copy_new_window_bounds_flag:
        .byte   0

;;; ============================================================
;;; File Icon Entry Construction
;;; Inputs: `cached_window_id` must be set

.proc CreateIconsForWindowImpl

iconbits:       .addr   0
iconentry_flags: .byte   0
icon_height:    .word   0

        ;; Updated based on view type
initial_xcoord:     .word   0
icons_this_row:
        .byte   0
        DEFINE_POINT icon_coords, 0, 0

        ;; Initial values when populating a list view
init_view:
icons_per_row:      .byte   0
col_spacing:        .byte   0
row_spacing:        .byte   0
        DEFINE_POINT row_coords, 0, 0
        init_view_size := * - init_view

        ;; Templates for populating initial values, based on view type
init_list_view:
        .byte   1, 0, kListItemHeight
        .word   kListViewInitialLeft, kListViewInitialTop
        .assert * - init_list_view = init_view_size, error, "struct size"
init_icon_view:
        .byte   kIconViewIconsPerRow, kIconViewSpacingX, kIconViewSpacingY
        .word   kIconViewInitialLeft, kIconViewInitialTop
        .assert * - init_icon_view = init_view_size, error, "struct size"
init_smicon_view:
        .byte   kSmallIconViewIconsPerRow, kSmallIconViewSpacingX, kSmallIconViewSpacingY
        .word   kSmallIconViewInitialLeft, kSmallIconViewInitialTop
        .assert * - init_smicon_view = init_view_size, error, "struct size"

.proc Start
        jsr     PushPointers

        ;; Select the template
        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
    IF_NEG
        ldax    #init_list_view
    ELSE
        .assert kViewByIcon = 0, error, "enum mismatch"
      IF_ZERO
        ldax    #init_icon_view
      ELSE
        ldax    #init_smicon_view
      END_IF
    END_IF

        ;; Populate the initial values fron the template
        ptr := $06
        stax    ptr
        ldy     #init_view_size-1
:       lda     (ptr),y
        sta     init_view,y
        dey
        bpl     :-

        ;; Init/zero out the rest of the state
        copy16  row_coords::xcoord, initial_xcoord

        lda     #0
        sta     icons_this_row
        sta     index

        ;; Copy `cached_window_entry_list` to temp location
        record_order_list := $800
        ldx     cached_window_entry_count
        stx     num_files
        dex
:       lda     cached_window_entry_list,x
        sta     record_order_list,x
        dex
        bpl     :-

        copy    #0, cached_window_entry_count

        ;; Get base pointer to records
        lda     cached_window_id
        jsr     GetFileRecordListForWindow
        addax   #1, records_base_ptr ; first byte in list is the list size

        lda     cached_window_id
        sta     active_window_id

        ;; Loop over files, creating icon for each
        index := *+1
:       ldx     #SELF_MODIFIED_BYTE
        num_files := *+1
        cpx     #SELF_MODIFIED_BYTE
        beq     :+

        ;; Get record from ordered list
        lda     record_order_list,x
        tax                     ; 1-based to 0-based
        dex
        txa
        pha                     ; A = record_num-1
        .assert .sizeof(FileRecord) = 32, error, "FileRecord size must be 2^5"
        jsr     ATimes32        ; A,X = A * 32
        record_ptr := $06
        addax   records_base_ptr, record_ptr
        pla                     ; A = record_num-1
        jsr     AllocAndPopulateFileIcon

        inc     index
        bne     :-              ; always
:
        jsr     PopPointers     ; do not tail-call optimise!
        rts

records_base_ptr:
        .word   0

.endproc ; Start

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
        jsr     GetIconEntry
        stax    icon_entry

        ;; Assign record number
        pla                     ; A = record_num
        ldy     #IconEntry::record_num
        sta     (icon_entry),y

        ;; Bank in the FileRecord entries
        bit     LCBANK2
        bit     LCBANK2

        ;; Copy the name out of LCBANK2
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

        ;; Find the icon type
        ldy     #FileRecord::file_type
        lda     (file_record),y
        sta     icontype_filetype
        ldy     #FileRecord::aux_type
        copy16in (file_record),y, icontype_auxtype
        ldy     #FileRecord::blocks
        copy16in (file_record),y, icontype_blocks
        copy16  #name_tmp, icontype_filename

        ;; Bank in the resources we need
        bit     LCBANK1
        bit     LCBANK1

        jsr     GetCachedWindowViewBy
        sta     view_by
        jsr     GetIconType
        view_by := *+1
        ldy     #SELF_MODIFIED_BYTE
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

        jsr     GetCachedWindowViewBy
        .assert kViewByIcon = 0, error, "enum mismatch"
    IF_ZERO
        ;; Icon view: include y-offset
        ldy     #IconEntry::icony
        sub16in (icon_entry),y, icon_height, (icon_entry),y
    END_IF

        lda     cached_window_entry_count
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
        add16_8 row_coords::ycoord, row_spacing
        copy16  initial_xcoord, row_coords::xcoord
        lda     #0
        sta     icons_this_row
        jmp     L7870

        ;; Next column otherwise
L7862:  add16_8 row_coords::xcoord, col_spacing

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
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
        bne     :+              ; too long

        jsr     PushPointers
        param_call FindWindowForPath, path_buf3
        jsr     PopPointers
        cmp     #0              ; A = window id, 0 if none
        beq     :+
        tax
        lda     icon_num
        sta     window_to_dir_icon_table-1,x

        ldy     #IconEntry::state ; mark as dimmed
        lda     (icon_entry),y
        ora     #kIconEntryStateDimmed
        sta     (icon_entry),y
:
        rts
.endproc ; AllocAndPopulateFileIcon

;;; ============================================================
;;; Inputs: A = `IconType` member, Y = `kViewByXXX` value
;;; Outputs: Populates `iconentry_flags`, `iconbits`, `icon_height`

.proc FindIconDetailsForIconType
        ptr := $6

        sty     view_by
        jsr     PushPointers

        ;; For populating `IconEntry::win_flags`
        tay                     ; Y = `IconType`
        lda     icontype_iconentryflags_table,y
        sta     iconentry_flags

        ;; Load up A,X with pointer to `IconResource`
        view_by := *+1
        lda     #SELF_MODIFIED_BYTE
    IF_NE
        ;; List View / Small Icon View
        php
        lda     iconentry_flags
        ora     #kIconEntryFlagsSmall
        plp
     IF_NEG
        ora     #kIconEntryFlagsFixed
     END_IF
        sta     iconentry_flags

        ldax    #sm_gen
        cpy     #IconType::folder
      IF_EQ
        ldax    #sm_dir
      END_IF
   ELSE
        ;; Icon View
        tya                     ; Y = `IconType`
        asl     a
        tay
        lda     type_icons_table,y
        ldx     type_icons_table+1,y
   END_IF

        ;; For populating IconEntry::iconbits
        stax    iconbits

        ;; Icon height will be needed too
        stax    ptr
        ldy     #IconResource::maprect + MGTK::Rect::y2
        copy16in (ptr),y, icon_height

        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; FindIconDetailsForIconType

.endproc ; CreateIconsForWindowImpl
CreateIconsForWindow := CreateIconsForWindowImpl::Start

;;; ============================================================
;;; Compute the window initial size for `cached_window_id`,
;;; based on icons bounding box.
;;; Output: Updates the Winfo record's maprect right/bottom.

.proc ComputeInitialWindowSize

        jsr     PushPointers

        ;; NOTE: Coordinates (screen vs. window) doesn't matter
        jsr     ComputeIconsBBox

        winfo_ptr := $06

        lda     cached_window_id
        jsr     WindowLookup
        stax    winfo_ptr

        ;; convert right/bottom to width/height
        bbox_dx := iconbb_rect+MGTK::Rect::x2
        bbox_dy := iconbb_rect+MGTK::Rect::y2
        sub16   bbox_dx, iconbb_rect+MGTK::Rect::x1, bbox_dx
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        sub16in bbox_dy, (winfo_ptr),y, bbox_dy


        ;; --------------------------------------------------
        ;; Width

        lda     cached_window_entry_count
        beq     use_minw        ; `iconbb_rect` is bogus if there are no icons

        ;; Check if width is < min or > max
        cmp16   bbox_dx, #kMinWindowWidth
        bcc     use_minw
        cmp16   bbox_dx, #kMaxWindowWidth
        bcs     use_maxw
        ldax    bbox_dx
        jmp     assign_width

use_minw:
        ldax    #kMinWindowWidth
        jmp     assign_width

use_maxw:
        ldax    #kMaxWindowWidth

assign_width:
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Rect::x2
        sta     (winfo_ptr),y
        txa
        iny
        sta     (winfo_ptr),y

        ;; --------------------------------------------------
        ;; Height

        lda     cached_window_entry_count
        beq     use_minh        ; `iconbb_rect` is bogus if there are no icons

        ;; Check if height is < min or > max
        cmp16   bbox_dy, #kMinWindowHeight
        bcc     use_minh
        cmp16   bbox_dy, #kMaxWindowHeight
        bcs     use_maxh
        ldax    bbox_dy
        jmp     assign_height

use_minh:
        ldax    #kMinWindowHeight
        jmp     assign_height

use_maxh:
        ldax    #kMaxWindowHeight

assign_height:
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Rect::y2
        sta     (winfo_ptr),y
        txa
        iny
        sta     (winfo_ptr),y

        ;; Finished
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; ComputeInitialWindowSize

;;; ============================================================
;;; For a newly populated window (new or refreshed), adjust the
;;; viewport so that the icon bbox is in the top-left, rather
;;; than being offset arbitrarily.

;;; Inputs: `cached_window_id` is accurate
.proc AdjustViewportForNewIcons
        ;; Screen space
        jsr     ComputeIconsBBox

        winfo_ptr := $06

        ;; No-op if window is empty
        lda     cached_window_entry_count
        beq     ret

        lda     cached_window_id
        jsr     WindowLookup
        stax    winfo_ptr

        ;; Adjust view bounds of new window so it matches icon bounding box.
        ;; (Only done for width because height is treated as fixed.)
        jsr     CachedIconsScreenToWindow
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::xcoord
        sub16in iconbb_rect+MGTK::Rect::x1, (winfo_ptr),y, tmpw
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Rect::x1
        add16in (winfo_ptr),y, tmpw, (winfo_ptr),y
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Rect::x2
        add16in (winfo_ptr),y, tmpw, (winfo_ptr),y
        jsr     CachedIconsWindowToScreen

ret:    rts

tmpw:   .word   0
.endproc ; AdjustViewportForNewIcons


;;; ============================================================
;;; Map file type (etc) to icon type

;;; Input: `icontype_filetype`, `icontype_auxtype`, `icontype_blocks`, `icontype_filename` populated
;;; Output: A is IconType to use (for icons, open/preview, etc)

.proc GetIconType
        ptr := $06

        jsr     PushPointers
        copy16  #icontype_table, ptr

loop:   ldy     #ICTRecord::mask ; $00 if done
        lda     (ptr),y
        cmp     #kICTSentinel
        bne     :+
        jsr     PopPointers
        lda     #IconType::generic
        rts

        ;; Check type (with mask)
:       and     icontype_filetype    ; A = type & mask
        iny                     ; ASSERT: Y = ICTRecord::filetype
        .assert ICTRecord::filetype = ICTRecord::mask+1, error, "enum mismatch"
        cmp     (ptr),y         ; type check
        jne     next

        ;; Flags
        iny                     ; ASSERT: Y = ICTRecord::flags
        .assert ICTRecord::flags = ICTRecord::filetype+1, error, "enum mismatch"
        lda     (ptr),y
        sta     flags

        ;; Does Aux Type matter, and if so does it match?
        bit     flags
    IF_NS                       ; bit 7 = compare aux
        iny                     ; ASSERT: Y = FTORecord::aux_suf
        .assert ICTRecord::aux_suf = ICTRecord::flags+1, error, "enum mismatch"
        lda     icontype_auxtype
        cmp     (ptr),y
        bne     next
        iny
        lda     icontype_auxtype+1
        cmp     (ptr),y
        bne     next
    END_IF

        ;; Does Block Count matter, and if so does it match?
        bit     flags
    IF_VS                       ; bit 6 = compare blocks
        ldy     #ICTRecord::blocks
        lda     icontype_blocks
        cmp     (ptr),y
        bne     next
        iny
        lda     icontype_blocks+1
        cmp     (ptr),y
        bne     next
    END_IF

        ;; Filename suffix?
        lda     flags
        and     #ICT_FLAGS_SUFFIX
    IF_NOT_ZERO
        ;; Set up pointers to suffix and filename
        ptr_suffix      := $08
        ptr_filename    := $0A
        ldy     #ICTRecord::aux_suf
        copy16in (ptr),y, ptr_suffix
        copy16  icontype_filename, ptr_filename
        ;; Start at the end of the strings
        ldy     #0
        lda     (ptr_suffix),y
        sta     suffix_pos
        lda     (ptr_filename),y
        sta     filename_pos
        ;; Case-insensitive compare each character
        suffix_pos := *+1
:       ldy     #SELF_MODIFIED_BYTE
        lda     (ptr_suffix),y
        jsr     UpcaseChar
        sta     char
        filename_pos := *+1
        ldy     #SELF_MODIFIED_BYTE
        lda     (ptr_filename),y
        jsr     UpcaseChar
        char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     next            ; no match
        ;; Move to previous characters
        dec     suffix_pos
        beq     :+              ; if we ran out of suffix, it's a match
        dec     filename_pos
        beq     next            ; but if we ran out of filename, it's not
        bne     :-              ; otherwise, keep going
:
    END_IF

        ;; Have a match
        ldy     #ICTRecord::icontype
        lda     (ptr),y
        sta     tmp
        jsr     PopPointers
        tmp := *+1
        lda     #SELF_MODIFIED_BYTE
        rts

        ;; Next entry
next:   add16_8 ptr, #.sizeof(ICTRecord)
        jmp     loop

flags:  .byte   0
.endproc ; GetIconType


;;; ============================================================
;;; Draw header (items/K in disk/K available/lines) for active window

.proc DrawWindowHeader
        ;; --------------------------------------------------
        ;; Separator Lines

        ;; x coords
        copy16  window_grafport::maprect::x1, header_line_left::xcoord
        copy16  window_grafport::maprect::x2, header_line_right::xcoord

        ;; y coords
        lda     window_grafport::maprect::y1
        clc
        adc     #kWindowHeaderHeight - 3
        sta     header_line_left::ycoord
        sta     header_line_right::ycoord
        lda     window_grafport::maprect::y1+1
        adc     #0
        sta     header_line_left::ycoord+1
        sta     header_line_right::ycoord+1

        ;; Draw top line
        MGTK_CALL MGTK::MoveTo, header_line_left
        jsr     SetPenModeNotCopy
        MGTK_CALL MGTK::LineTo, header_line_right

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
        MGTK_CALL MGTK::MoveTo, header_line_left
        MGTK_CALL MGTK::LineTo, header_line_right

        ;; --------------------------------------------------
        ;; Labels (Items/K in disk/K available)

        ;; Cache values
        lda     active_window_id
        jsr     GetFileRecordCountForWindow
        ldx     #0
        stax    num_items

        ldax    #str_items_suffix
        ldy     cached_window_entry_count
        cpy     #1
    IF_EQ
        ldax    #str_item_suffix
    END_IF
        stax    ptr_str_items_suffix

        ldx     active_window_id
        dex                     ; index 0 is window 1
        txa
        asl     a
        tay
        lda     window_draw_k_used_table,y
        ldx     window_draw_k_used_table+1,y
        stax    k_in_disk
        lda     window_draw_k_free_table,y
        ldx     window_draw_k_free_table+1,y
        stax    k_available

        ;; Measure strings
        ldax    num_items
        jsr     MeasureIntString
        stax    width_num_items
        param_call_indirect MeasureString, ptr_str_items_suffix
        addax   width_num_items

        ldax    k_in_disk
        jsr     MeasureIntString
        stax    width_k_in_disk
        param_call MeasureString, str_k_in_disk
        addax   width_k_in_disk

        ldax    k_available
        jsr     MeasureIntString
        stax    width_k_available
        param_call MeasureString, str_k_available
        addax   width_k_available

        ;; Determine gap for centering
        gap := header_text_delta::xcoord
        sub16   window_grafport::maprect::x2, window_grafport::maprect::x1, gap ; window width
        sub16_8 gap, #kWindowHeaderInsetX * 2, gap ; minus left/right insets
        sub16   gap, width_num_items, gap          ; minus width of all text
        sub16   gap, width_k_in_disk, gap
        sub16   gap, width_k_available, gap
        asr16   gap                         ; divided evenly
        scmp16  #kWindowHeaderSpacingX, gap ; is it below the minimum?
    IF_POS
        copy16  #kWindowHeaderSpacingX, gap ; yes, use the minimum
    END_IF

        ;; Draw "XXX items"
        add16_8 window_grafport::maprect::x1, #kWindowHeaderInsetX, header_text_pos::xcoord
        add16_8 window_grafport::maprect::y1, #kWindowHeaderHeight-5, header_text_pos::ycoord
        MGTK_CALL MGTK::MoveTo, header_text_pos
        ldax    num_items
        jsr     DrawIntString
        param_call_indirect DrawString, ptr_str_items_suffix

        ;; Draw "XXXK in disk"
        MGTK_CALL MGTK::Move, header_text_delta
        ldax    k_in_disk
        jsr     DrawIntString
        param_call DrawString, str_k_in_disk

        ;; Draw "XXXK available"
        MGTK_CALL MGTK::Move, header_text_delta
        ldax    k_available
        jsr     DrawIntString
        param_jump DrawString, str_k_available

num_items:      .word   0
k_in_disk:      .word   0
k_available:    .word   0

width_num_items:        .word   0
width_k_in_disk:        .word   0
width_k_available:      .word   0

ptr_str_items_suffix:
        .addr   0

.proc DrawIntString
        jsr     IntToStringWithSeparators
        param_jump DrawString, str_from_int
.endproc ; DrawIntString

.proc MeasureIntString
        jsr     IntToStringWithSeparators
        ldax    #str_from_int
        FALL_THROUGH_TO MeasureString
.endproc ; MeasureIntString

;;; Measure text, pascal string address in A,X; result in A,X
;;; String must be in LC area (visible to both main and aux code)
.proc MeasureString
        ptr := $6
        len := $8
        result := $9

        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     len
        inc16   ptr
        MGTK_CALL MGTK::TextWidth, ptr
        ldax    result
        rts
.endproc ; MeasureString

.endproc ; DrawWindowHeader

;;; ============================================================
;;; Compute bounding box for icons within cached window
;;; Inputs: `cached_window_id` is set

        DEFINE_RECT iconbb_rect, 0, 0, 0, 0

.proc ComputeIconsBBox
        kIntMax = $7FFF

        ;; min.x = min.y = max.x = max.y = 0
        ldx     #.sizeof(MGTK::Rect)-1
        lda     #0
:       sta     iconbb_rect,x
        dex
        bpl     :-

        ;; icon_num = 0
        sta     icon_num

        ;; min.x = min.y = kIntMax
        ldax    #kIntMax
        stax    iconbb_rect::x1
        stax    iconbb_rect+MGTK::Rect::y1

check_icon:
        icon_num := *+1
        ldx     #SELF_MODIFIED_BYTE
        cpx     cached_window_entry_count
        bne     more

        ;; If there are any entries...
        lda     cached_window_entry_count
    IF_NOT_ZERO
        ;; Add padding around bbox
        sub16_8 iconbb_rect::x1, #kIconBBoxPaddingLeft
        add16_8 iconbb_rect::x2, #kIconBBoxPaddingRight
        sub16_8 iconbb_rect::y1, #kIconBBoxPaddingTop
        add16_8 iconbb_rect::y2, #kIconBBoxPaddingBottom

        ;; List view?
        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
      IF_NEG
        ;; max.x = kListViewWidth
        copy16  #kListViewWidth, iconbb_rect::x2
      END_IF
    END_IF

        rts

more:   lda     cached_window_entry_list,x
        sta     icon_param
        ITK_CALL IconTK::GetIconBounds, icon_param ; inits `tmp_rect`

        jsr     GetCachedWindowViewBy
        .assert kViewByIcon = 0, error, "enum mismatch"
    IF_ZERO
        ;; Pretend icon is max height
        sub16   tmp_rect::y2, #kMaxIconTotalHeight, tmp_rect::y1
    END_IF

        ;; First icon (index 0) - just use its coordinates as min/max
        lda     icon_num
        bne     compare

        COPY_STRUCT MGTK::Rect, tmp_rect, iconbb_rect
        jmp     next

        ;; --------------------------------------------------
        ;; Compare X coords

compare:
        scmp16  tmp_rect::x1, iconbb_rect::x1
        bpl     :+
        copy16  tmp_rect::x1, iconbb_rect::x1
:       scmp16  tmp_rect::x2, iconbb_rect::x2
        bmi     :+
        copy16  tmp_rect::x2, iconbb_rect::x2
:

        ;; --------------------------------------------------
        ;; Compare Y coords

        scmp16  tmp_rect::y1, iconbb_rect::y1
        bpl     :+
        copy16  tmp_rect::y1, iconbb_rect::y1
:       scmp16  tmp_rect::y2, iconbb_rect::y2
        bmi     :+
        copy16  tmp_rect::y2, iconbb_rect::y2
:
        ;; --------------------------------------------------

next:   inc     icon_num
        jmp     check_icon
.endproc ; ComputeIconsBBox

;;; ============================================================
;;; Prepares a window's set of entries - before icon creation
;;; (or in views without icons) these are `FileRecord` indexes.
;;; In list views these are subsequently sorted. When icons are
;;; created, this order is used but the list is re-populated
;;; with icon numbers.
;;;
;;; icons, these are replaced by icon numbers.
;;; Inputs: `cached_window_id` is set
;;; Outputs: Populates `cached_window_entry_count` with count and
;;;          `cached_window_entry_list` with indexes 1...N
;;; Assert: LCBANK1 is active

.proc InitCachedWindowEntries
        jsr     PushPointers

        ;; Get the entry count via FileRecord list
        lda     cached_window_id
        jsr     GetFileRecordCountForWindow

        ;; Store the count
        sta     cached_window_entry_count

        ;; Init the entries, monotonically increasing
        tax
    IF_NOT_ZERO
:       txa
        sta     cached_window_entry_list-1,x ; entries are 1-based
        dex
        bne     :-
    END_IF

        jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc ; InitCachedWindowEntries

;;; ============================================================

.proc InitWindowEntriesAndIcons
        jsr     InitCachedWindowEntries
        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
    IF_NEG
        jsr     SortRecords
    END_IF
        jsr     CreateIconsForWindow
        jsr     StoreWindowEntryTable
        jmp     AddIconsForCachedWindow
.endproc ; InitWindowEntriesAndIcons

;;; ============================================================
;;; Fetch the entry count for a window; valid after `OpenDirectory`,
;;; does not depend on icon creation state.
;;; Input: A = window_od
;;; Output: A = entry count
;;; Trashes $06
.proc GetFileRecordCountForWindow
        ptr := $06

        jsr     GetFileRecordListForWindow
        stax    ptr

        bit     LCBANK2
        bit     LCBANK2

        ldy     #0
        lda     (ptr),y         ; count (at head of list)

        bit     LCBANK1
        bit     LCBANK1

        rts
.endproc ; GetFileRecordCountForWindow

;;; ============================================================
;;; Populates and sorts `cached_window_entry_list`.
;;; Assumes `InitCachedWindowEntries` has been invoked
;;; (`cached_window_entry_count` is valid, etc)
;;; Inputs: A=kViewBy* for `cached_window_id`

.proc SortRecords
        ptr := $06

list_start_ptr  := $801
num_records     := $803
scratch_space   := $804         ; can be used by comparison funcs

        sta     CompareFileRecords_sort_by

        lda     cached_window_entry_count
        cmp     #2
        bcs     :+              ; can't sort < 2 records
        rts
:       sta     num_records

        lda     cached_window_id
        jsr     GetFileRecordListForWindow
        stax    ptr             ; point past the count
        stax    list_start_ptr
        inc16   ptr
        inc16   list_start_ptr

        ;; --------------------------------------------------
        ;; Selection sort

        ptr1 := $06
        ptr2 := $08

        ldx     num_records
        dex
        stx     outer

        outer := *+1
oloop:  lda     #SELF_MODIFIED_BYTE
        jsr     CalcPtr
        stax    ptr2

        lda     #0
        sta     inner

        inner := *+1
iloop:  lda     #SELF_MODIFIED_BYTE
        jsr     CalcPtr
        stax    ptr1

        bit     LCBANK2
        bit     LCBANK2
        jsr     CompareFileRecords
        php
        bit     LCBANK1
        bit     LCBANK1
        plp
        bcc     next

        ;; Swap
        ldx     inner
        ldy     outer
        lda     cached_window_entry_list,x
        pha
        lda     cached_window_entry_list,y
        sta     cached_window_entry_list,x
        pla
        sta     cached_window_entry_list,y

        lda     outer
        jsr     CalcPtr
        stax    ptr2

next:   inc     inner
        lda     inner
        cmp     outer
        bne     iloop

        dec     outer
        bne     oloop

        rts

;;; --------------------------------------------------
;;; Input: A = index in list being sorted
;;; Output: A,X = pointer to FileRecord

.proc CalcPtr
        ;; Map from sorting list index to FileRecord index
        tax
        ldy     cached_window_entry_list,x
        dey                     ; 1-based to 0-based
        tya

        ;; Calculate the pointer
        .assert .sizeof(FileRecord) = 32, error, "FileRecord size must be 2^5"
        jsr     ATimes32

        clc
        adc     list_start_ptr
        pha
        txa
        adc     list_start_ptr+1
        tax
        pla

        rts
.endproc ; CalcPtr

;;; --------------------------------------------------

;;; Inputs: $06 and $08 point at FileRecords
;;; Assert: LCBANK2 banked in so FileRecords are visible

.proc CompareFileRecords
        ptr1 := $06
        ptr2 := $08

        ;; Set by caller
        sort_by := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #kViewByName
    IF_EQ
        .assert FileRecord::name = 0, error, "Assumes name is at offset 0"
        jmp     CompareStrings
    END_IF

        cmp     #kViewByDate
    IF_EQ
PARAM_BLOCK scratch, $804       ; `scratch_space`
date_a  .tag    DateTime
date_b  .tag    DateTime
parsed_a .tag ParsedDateTime
parsed_b .tag ParsedDateTime
END_PARAM_BLOCK

        ;; Copy the dates somewhere easier to work with
        ldy     #FileRecord::modification_date + .sizeof(DateTime)-1
        ldx     #.sizeof(DateTime)-1
:       copy    (ptr2),y, scratch::date_a,x ; order descending
        copy    (ptr1),y, scratch::date_b,x
        dey
        dex
        bpl     :-

        ;; Crack the ProDOS values into more useful structs, and
        ;; handle various year encodings.
        ptr := $0A

        copy16  #scratch::parsed_a, ptr
        ldax    #scratch::date_a
        jsr     ParseDatetime

        copy16  #scratch::parsed_b, ptr
        ldax    #scratch::date_b
        jsr     ParseDatetime

        ;; Compare member-wise (just year/month/day)
        year_a  := scratch::parsed_a + ParsedDateTime::year
        year_b  := scratch::parsed_b + ParsedDateTime::year
        ecmp16  year_a, year_b
        bne     done

        month_a := scratch::parsed_a + ParsedDateTime::month
        month_b := scratch::parsed_b + ParsedDateTime::month
        lda     month_a
        cmp     month_b
        bne     done

        day_a   := scratch::parsed_a + ParsedDateTime::day
        day_b   := scratch::parsed_b + ParsedDateTime::day
        lda     day_a
        cmp     day_b
done:   rts
    END_IF

        cmp     #kViewBySize
    IF_EQ
        ;; Copy sizes somewhere convenient
        size1 := $804
        size2 := $806
        ldy     #FileRecord::blocks
        copy    (ptr1),y, size1
        copy    (ptr2),y, size2
        iny
        copy    (ptr1),y, size1+1
        copy    (ptr2),y, size2+1

        ;; Treat directories as 0
        ldy     #FileRecord::file_type
        lda     (ptr1),y
        cmp     #FT_DIRECTORY
      IF_EQ
        copy16  #0, size1
      END_IF
        lda     (ptr2),y
        cmp     #FT_DIRECTORY
      IF_EQ
        copy16  #0, size2
      END_IF

        ;; Compare!
        cmp16   size2, size1 ; order descending
        rts
    END_IF

        ;; Assert: kViewByType
        scratch := $804
        ldy     #FileRecord::file_type
        lda     (ptr1),y
        jsr     ComposeFileTypeStringForSorting
        COPY_STRING str_file_type, scratch
        ldy     #FileRecord::file_type
        lda     (ptr2),y
        jsr     ComposeFileTypeStringForSorting

        bit     LCBANK1
        bit     LCBANK1
        jsr     PushPointers
        copy16  #scratch, $06
        copy16  #str_file_type, $08
        jsr     CompareStrings
        jsr     PopPointers
        bit     LCBANK2
        bit     LCBANK2

        rts

.endproc ; CompareFileRecords
CompareFileRecords_sort_by := CompareFileRecords::sort_by

.proc ComposeFileTypeStringForSorting
        jsr     ComposeFileTypeString
        lda     str_file_type+1
        cmp     #'$'
        bne     :+
        lda     #$FF
        sta     str_file_type+1
:       rts
.endproc ; ComposeFileTypeStringForSorting

.endproc ; SortRecords


;;; ============================================================
;;; A = entry number

.proc DrawListViewRow

        ptr := $06

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
        scmp16  pos_col_type::ycoord, window_grafport::maprect::y2
        bpl     ret

        add16_8 pos_col_type::ycoord, #kListViewRowHeight
        add16_8 pos_col_size::ycoord, #kListViewRowHeight
        add16_8 pos_col_date::ycoord, #kListViewRowHeight

        ;; Above top?
        scmp16  pos_col_type::ycoord, window_grafport::maprect::y1
        bpl     in_range
ret:    rts

        ;; Draw it!
in_range:
        MGTK_CALL MGTK::MoveTo, pos_col_type
        jsr     PrepareColType
        param_call DrawString, text_buffer2

        MGTK_CALL MGTK::MoveTo, pos_col_size
        jsr     PrepareColSize
        param_call DrawStringRight, text_buffer2

        MGTK_CALL MGTK::MoveTo, pos_col_date
        jsr     ComposeDateString
        param_jump DrawString, text_buffer2
.endproc ; DrawListViewRow

;;; ============================================================

.proc PrepareColType
        file_type := list_view_filerecord + FileRecord::file_type

        lda     file_type
        jsr     ComposeFileTypeString

        COPY_BYTES 4, str_file_type, text_buffer2 ; 3 characters + length

        rts
.endproc ; PrepareColType

.proc PrepareColSize
        file_type := list_view_filerecord + FileRecord::file_type

        lda     file_type
        cmp     #FT_DIRECTORY
    IF_EQ
        copy    #1, text_buffer2
        copy    #'-', text_buffer2+1
        rts
    END_IF

        blocks := list_view_filerecord + FileRecord::blocks

        ldax    blocks
        FALL_THROUGH_TO ComposeSizeString
.endproc ; PrepareColSize

;;; ============================================================
;;; Populate `text_buffer2` with "12,345K"

.proc ComposeSizeString
        stax    value           ; size in 512-byte blocks

        lsr16   value       ; Convert blocks to K, rounding up
        bcc     :+          ; NOTE: divide then maybe inc, rather than
        inc16   value       ; always inc then divide, to handle $FFFF
:

        ldax    value
        jsr     IntToStringWithSeparators
        ldx     #0

        ;; Append number
        ldy     #0
:       lda     str_from_int+1,y
        sta     text_buffer2+1,x
        iny
        inx
        cpy     str_from_int
        bne     :-

        ;; Append suffix
        ldy     #0
:       lda     str_kb_suffix+1, y
        sta     text_buffer2+1,x
        iny
        inx
        cpy     str_kb_suffix
        bne     :-

        stx     text_buffer2
        rts

value:  .word   0

.endproc ; ComposeSizeString

;;; ============================================================

.proc ComposeDateString
        copy    #0, text_buffer2
        copy16  #text_buffer2, $8
        lda     datetime_for_conversion ; any bits set?
        ora     datetime_for_conversion+1
        bne     append_date_strings
        sta     month           ; 0 is "no date" string
        jmp     AppendMonthString

append_date_strings:
        copy16  #parsed_date, $0A
        ldax    #datetime_for_conversion
        jsr     ParseDatetime

        ldx     #DeskTopSettings::intl_date_order
        jsr     ReadSetting
        .assert DeskTopSettings::kDateOrderMDY = 0, error, "enum mismatch"
    IF_EQ
        ;; Month Day, Year
        jsr     AppendMonthString
        param_call ConcatenateDatePart, str_space
        jsr     AppendDayString
        param_call ConcatenateDatePart, str_comma
    ELSE
        ;; Day Month Year
        jsr     AppendDayString
        param_call ConcatenateDatePart, str_space
        jsr     AppendMonthString
        param_call ConcatenateDatePart, str_space
    END_IF
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
.endproc ; AppendDayString

.proc AppendMonthString
        lda     month
        asl     a
        tay
        lda     month_table+1,y
        tax
        lda     month_table,y

        jmp     ConcatenateDatePart
.endproc ; AppendMonthString

.proc AppendYearString
        ldax    year
        jsr     IntToString
        param_jump ConcatenateDatePart, str_from_int
.endproc ; AppendYearString

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
.endproc ; ConcatenateDatePart

.endproc ; ComposeDateString


;;; ============================================================

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"

;;; A,X = A * 16
.proc ATimes16
        ldx     #4
        bne     AShiftX       ; always
.endproc ; ATimes16

;;; A,X = A * 32
.proc ATimes32
        ldx     #5
        bne     AShiftX       ; always
.endproc ; ATimes32

;;; A,X = A * 64
.proc ATimes64
        ldx     #6
        bne     AShiftX       ; always
.endproc ; ATimes64

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
.endproc ; AShiftX

;;; ============================================================
;;; Look up an icon address.
;;; Inputs: A = icon number
;;; Output: A,X = IconEntry address

.proc GetIconEntry
        asl     a
        tay
        lda     icon_entry_address_table,y
        ldx     icon_entry_address_table+1,y
        rts
.endproc ; GetIconEntry

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
.endproc ; WindowLookup

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
.endproc ; GetWindowPath

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
.endproc ; GetWindowTitlePath

;;; ============================================================
;;; Inputs: A = icon id (volume or file)
;;; Outputs: Z=1/A=0/`path_buf3` populated with full path on success
;;;          Z=0/A=`ERR_INVALID_PATHNAME` if too long

.proc GetIconPath
        jsr     PushPointers

        icon_ptr := $06
        win_path_ptr := $08

        jsr     GetIconEntry
        stax    icon_ptr

        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        pha                     ; A = window id
        add16_8 icon_ptr, #IconEntry::name
        pla
        bne     file            ; A = window id

        ;; Volume - no base path
        copy16  #0, win_path_ptr ; base
        beq     concat           ; always

        ;; File - window path is base path
file:
        jsr     GetWindowPath
        stax    win_path_ptr

        ;; Is there room?
        ldy     #0
        lda     (icon_ptr),y
        clc
        adc     (win_path_ptr),y
        cmp     #kMaxPathLength ; not +1 because we'll add '/'
        bcs     too_long

concat:
        ;; Yes, concatenate
        jsr     JoinPaths       ; $08 = base, $06 = file
        lda     #0
        beq     finish          ; always

        ;; No, report error
too_long:
        lda     #ERR_INVALID_PATHNAME

finish:
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; GetIconPath

;;; ============================================================
;;; Input: A,X = path to copy
;;; Output: populates `src_path_buf` a.k.a. `INVOKER_PREFIX`

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
.endproc ; CopyToSrcPath

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
.endproc ; CopyToDstPath

;;; ============================================================
;;; Input: A,X = path to append
;;; Output: appends '/' and path to `src_path_buf` a.k.a. `INVOKER_PREFIX`

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
.endproc ; AppendFilenameToSrcPath

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
.endproc ; AppendFilenameToDstPath

;;; ============================================================

.proc ComposeFileTypeString
        sta     file_type

        ;; Search `type_table` for type
        ldy     #kNumFileTypes-1
:       lda     type_table,y
        file_type := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     found
        dey
        bpl     :-
        jmp     not_found

        ;; Found - copy string from `type_names_table`
found:  tya
        asl     a               ; *4
        asl     a
        tay

        ldx     #0
:       lda     type_names_table,y
        sta     str_file_type+1,x
        iny
        inx
        cpx     #3
        bne     :-

        rts

        ;; Type not found - use generic " $xx"
not_found:
        copy    #'$', str_file_type+1

        lda     file_type
        pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        copy    hex_digits,x, str_file_type+2

        pla                     ; A = file_type
        and     #$0F
        tax
        copy    hex_digits,x, str_file_type+3

        rts
.endproc ; ComposeFileTypeString

str_file_type:
        PASCAL_STRING "$00"

;;; ============================================================
;;; Append aux type (in A,X) to text_buffer2

.proc AppendAuxType
        stax    auxtype
        ldy     text_buffer2

        ;; Append prefix
        ldx     #0
:       lda     str_auxtype_prefix+1,x
        sta     text_buffer2+1,y
        inx
        iny
        cpx     str_auxtype_prefix
        bne     :-

        ;; Append type
        lda     auxtype+1
        jsr     DoByte
        lda     auxtype
        jsr     DoByte

        sty     text_buffer2
        rts

DoByte:
        pha
        lsr
        lsr
        lsr
        lsr
        tax
        lda     hex_digits,x
        sta     text_buffer2+1,y
        iny
        pla
        and     #%00001111
        tax
        lda     hex_digits,x
        sta     text_buffer2+1,y
        iny
        rts

auxtype:
        .word 0
.endproc ; AppendAuxType

;;; ============================================================
;;; Draw text right aligned, pascal string address in A,X
;;; String must be in aux or LC memory.

.proc DrawStringRight
        params  := $6
        textptr := $6
        textlen := $8
        width   := $9
        dy      := $B

        stax    textptr
        jsr     AuxLoad
        beq     ret
        sta     textlen
        inc16   textptr
        MGTK_CALL MGTK::TextWidth, params
        sub16   #0, width, width
        copy16  #0, dy
        MGTK_CALL MGTK::Move, width
        MGTK_CALL MGTK::DrawText, params

ret:    rts
.endproc ; DrawStringRight

;;; ============================================================

.proc SwapWindowPortbits
        ptr := $6

        jsr     PushPointers
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
        jsr     PopPointers     ; do not tail-call optimise!
        rts

saved_portbits:
        .res    .sizeof(MGTK::GrafPort)+1, 0
.endproc ; SwapWindowPortbits

;;; ============================================================
;;; Convert icon's coordinates from window to screen
;;; (icon index in A, active window)
;;; NOTE: Avoid calling in a loop; factor out `PrepActiveWindowScreenMapping`

.proc IconWindowToScreen
        jsr     PushPointers
        pha
        jsr     PrepActiveWindowScreenMapping
        pla
        jsr     GetIconEntry
        jsr     IconPtrWindowToScreen
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; IconWindowToScreen

;;; Convert icon's coordinates from window to screen
;;; Inputs: A,X = `IconEntry`, `PrepActiveWindowScreenMapping` called
;;; Trashes $06
.proc IconPtrWindowToScreen
        entry_ptr := $6
        stax    entry_ptr

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

        rts
.endproc ; IconPtrWindowToScreen

;;; ============================================================
;;; Convert icon's coordinates from screen to window
;;; (icon index in A, active window)
;;; NOTE: Avoid calling in a loop; factor out `PrepActiveWindowScreenMapping`

.proc IconScreenToWindow
        jsr     PushPointers
        pha
        jsr     PrepActiveWindowScreenMapping
        pla
        jsr     GetIconEntry
        jsr     IconPtrScreenToWindow
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; IconScreenToWindow

;;; Convert icon's coordinates from screen to window
;;; Inputs: A,X = `IconEntry`, `PrepActiveWindowScreenMapping` called
;;; Trashes $06
.proc IconPtrScreenToWindow
        entry_ptr := $6
        stax    entry_ptr

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

        rts
.endproc ; IconPtrScreenToWindow

;;; ============================================================

        DEFINE_POINT pos_screen, 0, 0
        DEFINE_POINT pos_win, 0, 0

;;; Inits `pos_screen` and `pos_window` for window/screen mapping
;;; for active window.
;;; Inputs: `active_window_id` set
;;; Trashes: $08

.proc PrepActiveWindowScreenMapping
        winfo_ptr := $8

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

        rts
.endproc ; PrepActiveWindowScreenMapping

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
        .addr cdrom_icon
        ASSERT_ADDRESS_TABLE_SIZE device_type_to_icon_address_table, ::kNumDeviceTypes

dib_buffer := $800
        DEFINE_SP_STATUS_PARAMS status_params, 1, dib_buffer, 3 ; Return Device Information Block (DIB)

;;; Roughly follows:
;;; Technical Note: ProDOS #21: Identifying ProDOS Devices
;;; http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.21.html

.proc GetDeviceType
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
        jsr     DeviceDriverAddress
        cmp     #<kVEDRIVEDriverAddress
        bne     :+
        cpx     #>kVEDRIVEDriverAddress
        bne     :+
vdrive: ldax    #str_device_type_vdrive
        ldy     #kDeviceTypeFileShare
        rts
:
        ;; Special case for VSDRIVE
        cmp     #<kVSDRIVEDriverAddress
        bne     :+
        cpx     #>kVSDRIVEDriverAddress
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
        jsr     DeviceDriverAddress ; Z=1 if $Cn
        bvs     is_sp
        jne     generic             ; not $CnXX, unknown type

        ;; Firmware driver; maybe SmartPort?
is_sp:  lda     unit_number
        jsr     FindSmartportDispatchAddress
        bcs     not_sp
        stax    dispatch
        sty     status_params::unit_num

        ;; Execute SmartPort call
        dispatch := *+1
        jsr     SELF_MODIFIED
        .byte   SPCall::Status
        .addr   status_params
        bcs     not_sp

        ;; Trim trailing whitespace (seen in CFFA)
.scope
        ldy     dib_buffer+SPDIB::ID_String_Length
        beq     done
:       lda     dib_buffer+SPDIB::Device_Name-1,y
        cmp     #' '
        bne     done
        dey
        bne     :-
done:   sty     dib_buffer+SPDIB::ID_String_Length
.endscope

        ;; Case-adjust
.scope
        ldy     dib_buffer+SPDIB::ID_String_Length
        beq     done
        dey
        beq     done

        ;; Look at prior and current character; if both are alpha,
        ;; lowercase current.
loop:   lda     dib_buffer+SPDIB::Device_Name-1,y ; Test previous character
        jsr     IsAlpha
        bne     next
        lda     dib_buffer+SPDIB::Device_Name,y ; Adjust this one if also alpha
        jsr     IsAlpha
        bne     next
        lda     dib_buffer+SPDIB::Device_Name,y
        ora     #AS_BYTE(~CASE_MASK)
        sta     dib_buffer+SPDIB::Device_Name,y

next:   dey
        bne     loop
done:
.endscope

        ;; Check device type
        ;; Technical Note: SmartPort #4: SmartPort Device Types
        ;; http://www.1000bit.it/support/manuali/apple/technotes/smpt/tn.smpt.4.html
        lda     dib_buffer+SPDIB::Device_Type_Code
        .assert SPDeviceType::MemoryExpansionCard = 0, error, "enum mismatch"
        bne     :+            ; $00 = Memory Expansion Card (RAM Disk)
        ldax    #dib_buffer+SPDIB::ID_String_Length
        ldy     #kDeviceTypeRAMDisk
        rts
:
        cmp     #SPDeviceType::SCSICDROM
        bne     test_size
        ldax    #dib_buffer+SPDIB::ID_String_Length
        ldy     #kDeviceTypeCDROM
        rts

        ;; NOTE: Codes for 3.5" disk ($01) and 5-1/4" disk ($0A) are not trusted
        ;; since emulators do weird things.
        ;; TODO: Is that comment about false positives or false negatives?
        ;; i.e. if $01 or $0A is seen, can that be trusted?

not_sp:
        ;; Not SmartPort - try AppleTalk
        MLI_CALL READ_BLOCK, block_params
        beq     :+
        cmp     #ERR_NETWORK_ERROR
        bne     :+
        ldax    #str_device_type_appletalk
        ldy     #kDeviceTypeFileShare
        rts
:

        ;; RAM-based driver or not SmartPort
generic:
        copy    #0, dib_buffer+SPDIB::ID_String_Length

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

:       ldax    #dib_buffer+SPDIB::ID_String_Length
        ldy     #kDeviceTypeFixed
        rts

f525:   ldax    #dib_buffer+SPDIB::ID_String_Length
        ldy     #kDeviceTypeDiskII
        rts

f35:    ldax    #dib_buffer+SPDIB::ID_String_Length
        ldy     #kDeviceTypeRemovable
        rts

        DEFINE_READ_BLOCK_PARAMS block_params, block_buffer, 2
        unit_number := block_params::unit_num

blocks: .word   0

.endproc ; GetDeviceType

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
        MLI_CALL ON_LINE, on_line_params
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
.endproc ; GetBlockCountImpl
GetBlockCount   := GetBlockCountImpl::start

;;; ============================================================
;;; Create Volume Icon
;;; Input: A = unit number, Y = index in DEVLST
;;; Output: 0 on success, ProDOS error code on failure
;;; Assert: `cached_window_id` == 0
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
        MLI_CALL ON_LINE, on_line_params
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
        jsr     GetIconEntry
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
        ldy     #IconResource::maprect + MGTK::Rect::x2
        sub16in #kMaxIconWidth, (icon_defn_ptr),y, offset
        lsr16   offset          ; offset = (max_width - icon_width) / 2
        ldy     #IconEntry::iconx
        add16in (icon_ptr),y, offset, (icon_ptr),y

        ;; Adjust vertically
        ldy     #IconResource::maprect + MGTK::Rect::y2
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

        icon_ptr := $06

        jsr     PushPointers
        copy16  #cvi_data_buffer, $08

        ldx     cached_window_entry_count
        dex
        stx     index

        index := *+1
loop:   ldx     #SELF_MODIFIED_BYTE
        lda     cached_window_entry_list,x
        cmp     trash_icon_num
        beq     next
        jsr     GetIconName
        stax    icon_ptr

        jsr     CompareStrings
        bne     next

        ;; It matches; report a duplicate.
        lda     #ERR_DUPLICATE_VOLUME
        bne     finish          ; always

        ;; Doesn't match, try again
next:   dec     index
        bpl     loop

        ;; All done, clean up and report no duplicates.
        lda     #0

finish: jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; CompareNames


.endproc ; CreateVolumeIcon

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
.endproc ; AllocDesktopIconPosition

;;; Input: A = icon num
.proc FreeDesktopIconPosition
        ldx     #kMaxVolumes-1
:       dex
        cmp     desktop_icon_usage_table,x
        bne     :-
        lda     #0
        sta     desktop_icon_usage_table,x
        rts
.endproc ; FreeDesktopIconPosition

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
.endproc ; RemoveIconFromWindow

;;; ============================================================
;;; Search the window->dir_icon mapping table.
;;; Inputs: A = icon number
;;; Outputs: Z=1 && N=0 if found, X = index (0-7), A unchanged

.proc FindWindowIndexForDirIcon
        ldx     #kMaxDeskTopWindows-1
:       cmp     window_to_dir_icon_table,x
        beq     done
        dex
        bpl     :-
done:   rts
.endproc ; FindWindowIndexForDirIcon

;;; ============================================================
;;; Used when recovering from a failed open (bad path, too many icons, etc)
;;; Inputs: `icon_param` points at icon

.proc RemoveFileRecordsForIcon
        lda     icon_param
        beq     ret

        jsr     FindWindowIndexForDirIcon ; X = window id-1 if found
    IF_EQ
        inx
        txa
        jsr     RemoveWindowFilerecordEntries
    END_IF

ret:    rts
.endproc ; RemoveFileRecordsForIcon

;;; ============================================================
;;; Used when recovering from a failed open (bad path, too many icons, etc)
;;; Inputs: `icon_param` points at icon

.proc MarkIconNotDimmed
        icon_ptr := $6

        ;; Find open window for the icon
        lda     icon_param
        beq     ret

        jsr     FindWindowIndexForDirIcon ; X = window id-1 if found
    IF_EQ
        ;; If found, remove from the table.
        ;; Note: 0 not $FF because we know the window doesn't exist
        ;; any more.
        copy    #0, window_to_dir_icon_table,x
    END_IF

        ;; Update the icon and redraw
        lda     icon_param
        jsr     GetIconEntry
        stax    icon_ptr
        ldy     #IconEntry::state
        lda     (icon_ptr),y
        and     #AS_BYTE(~kIconEntryStateDimmed)
        sta     (icon_ptr),y
        ITK_CALL IconTK::DrawIcon, icon_param

ret:    rts
.endproc ; MarkIconNotDimmed

;;; ============================================================

.proc AnimateWindowImpl
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
        jsr     GetIconEntry
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

        sub16   window_grafport::maprect::x2, window_grafport::maprect::x1, L8D54
        sub16   window_grafport::maprect::y2, window_grafport::maprect::y1, L8D56
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
        jmp     AnimateWindowOpenImpl

:       jmp     AnimateWindowCloseImpl

close_flag:
        .byte   0

flag:   .byte   0               ; ???
flag2:  .byte   0               ; ???
L8D50:  .word   0
L8D52:  .word   0
L8D54:  .word   0
L8D56:  .word   0
.endproc ; AnimateWindowImpl
AnimateWindowClose      := AnimateWindowImpl::close
AnimateWindowOpen       := AnimateWindowImpl::open

;;; ============================================================

kMaxAnimationStep = 11

.proc AnimateWindowOpenImpl
        ;; Loop N = 0 to 13
        ;; If N in 0..11, draw N
        ;; If N in 2..13, erase N-2 (i.e. 0..11, 2 behind)

        lda     #0
        sta     step
        jsr     InitSetDesktopPort

        ;; If N in 0..11, draw N
loop:   lda     step            ; draw the Nth
        cmp     #kMaxAnimationStep+1
        bcs     erase
        jsr     FrameTableRect

        ;; If N in 2..13, erase N-2 (i.e. 0..11, 2 behind)
erase:  lda     step
        sec
        sbc     #2              ; erase the (N-2)th
        bmi     next
        jsr     FrameTableRect

next:   inc     step
        step := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #kMaxAnimationStep+3
        bne     loop
        rts
.endproc ; AnimateWindowOpenImpl

;;; ============================================================

.proc AnimateWindowCloseImpl
        ;; Loop N = 11 to -2
        ;; If N in 0..11, draw N
        ;; If N in -2..9, erase N+2 (0..11, i.e. 2 behind)

        lda     #kMaxAnimationStep
        sta     step
        jsr     InitSetDesktopPort

        ;; If N in 0..11, draw N
loop:   lda     step
        bmi     erase
        jsr     FrameTableRect

        ;; If N in -2..9, erase N+2 (0..11, i.e. 2 behind)
erase:  lda     step
        clc
        adc     #2
        cmp     #kMaxAnimationStep+1
        bcs     next
        jsr     FrameTableRect

next:   dec     step
        step := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #AS_BYTE(-3)
        bne     loop
        rts
.endproc ; AnimateWindowCloseImpl

;;; ============================================================

;;; Inputs: A = rect in `rect_table` to frame
.proc FrameTableRect
        rect_table := $800

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

        FALL_THROUGH_TO FrameTmpRect
.endproc ; FrameTableRect

.proc FrameTmpRect
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        jsr     SetPenModeXOR
        MGTK_CALL MGTK::FrameRect, tmp_rect
        rts
.endproc ; FrameTmpRect

;;; ============================================================
;;; Dynamically load parts of Desktop

;;; Call `LoadDynamicRoutine` or `RestoreDynamicRoutine`
;;; with A set to routine number (0-8); routine is loaded
;;; from DeskTop file to target address. Returns with
;;; minus flag set on failure.

;;; Routines are:
;;;  0 = format/erase disk        - A$ 800,L$1400 call w/ A = 4 = format, A = 5 = erase
;;;  1 = selector actions (all)   - A$9000,L$1000
;;;  2 = common file dialog       - A$5000,L$2000
;;;  3 = part of copy file        - A$7000,L$ 800
;;;  4 = selector add/edit        - L$7000,L$ 800
;;;  5 = restore 1                - A$5000,L$2800 (restore $5000...$77FF)
;;;  6 = restore 2                - A$9000,L$1000 (restore $9000...$9FFF)
;;;
;;; Routines 1-5 need appropriate "restore routines" applied when complete.

.proc LoadDynamicRoutineImpl

kNumOverlays = 7

pos_table:
        .dword  kOverlayFormatEraseOffset
        .dword  kOverlayShortcutPickOffset, kOverlayFileDialogOffset
        .dword  kOverlayFileCopyOffset
        .dword  kOverlayShortcutEditOffset, kOverlayDeskTopRestore1Offset
        .dword  kOverlayDeskTopRestore2Offset
        ASSERT_RECORD_TABLE_SIZE pos_table, kNumOverlays, 4

len_table:
        .word   kOverlayFormatEraseLength
        .word   kOverlayShortcutPickLength, kOverlayFileDialogLength
        .word   kOverlayFileCopyLength
        .word   kOverlayShortcutEditLength, kOverlayDeskTopRestore1Length
        .word   kOverlayDeskTopRestore2Length
        ASSERT_RECORD_TABLE_SIZE len_table, kNumOverlays, 2

addr_table:
        .word   kOverlayFormatEraseAddress
        .word   kOverlayShortcutPickAddress, kOverlayFileDialogAddress
        .word   kOverlayFileCopyAddress
        .word   kOverlayShortcutEditAddress, kOverlayDeskTopRestore1Address
        .word   kOverlayDeskTopRestore2Address
        ASSERT_ADDRESS_TABLE_SIZE addr_table, kNumOverlays

        DEFINE_OPEN_PARAMS open_params, str_desktop, IO_BUFFER

str_desktop:
        PASCAL_STRING kPathnameDeskTop

        DEFINE_SET_MARK_PARAMS set_mark_params, 0

        DEFINE_READ_PARAMS read_params, 0, 0
        DEFINE_CLOSE_PARAMS close_params

        ;; Called with routine # in A

load:   pha
        copy    #AlertButtonOptions::OKCancel, button_options
        .assert AlertButtonOptions::OKCancel <> 0, error, "bne always assumption"
        bne     :+              ; always

restore:
        pha
        ;; Need to set low bit in this case to override the default.
        copy    #AlertButtonOptions::OK|%00000001, button_options

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

retry:  MLI_CALL OPEN, open_params
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
        MLI_CALL SET_MARK, set_mark_params
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_params
        jmp     SetCursorPointer ; after loading overlay

.endproc ; LoadDynamicRoutineImpl
LoadDynamicRoutine      := LoadDynamicRoutineImpl::load
RestoreDynamicRoutine   := LoadDynamicRoutineImpl::restore

;;; ============================================================

.proc SetRGBMode
        ldx     #DeskTopSettings::rgb_color
        jsr     ReadSetting
        bpl     SetMonoMode
        FALL_THROUGH_TO SetColorMode
.endproc ; SetRGBMode

.proc SetColorMode
        bit     machine_config::iigs_flag
        bmi     iigs

        bit     machine_config::lcm_eve_flag
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
        bit     machine_config::iigs_flag
        bmi     iigs

        bit     machine_config::lcm_eve_flag
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

;;; On IIgs, force preferred RGB mode. No-op otherwise.
.proc ResetIIgsRGB
        bit     machine_config::iigs_flag
        bpl     SetMonoMode::done ; nope

        ldx     #DeskTopSettings::rgb_color
        jsr     ReadSetting
        bmi     SetColorMode::iigs
        bpl     SetMonoMode::iigs ; always
.endproc ; ResetIIgsRGB

;;; ============================================================
;;; Operations performed on selection
;;;
;;; These operate on the entire selection recursively, e.g.
;;; computing size, deleting, copying, etc., and share common
;;; logic.

.enum PromptResult
        ok      = 0
        cancel  = 1
.endenum

;;; ============================================================

.scope operations

;;; Used by Duplicate command for a single file copy
.proc DoCopyFile
        copy    #0, operation_flags ; copy/delete
        copy    #0, move_flag
        tsx
        stx     stack_stash

        jsr     PrepCallbacksForEnumeration
        jsr     DoCopyDialogPhase
        jsr     EnumerationProcessSelectedFile
        jsr     PrepCallbacksForCopy
        FALL_THROUGH_TO DoCopyCommon
.endproc ; DoCopyFile

.proc DoCopyCommon
        copy    #$FF, copy_run_flag
        copy    #0, move_flag
        jsr     CopyProcessNotSelectedFile
        jsr     InvokeOperationCompleteCallback
        FALL_THROUGH_TO FinishOperation
.endproc ; DoCopyCommon

FinishOperation:
        return  #kOperationSucceeded

;;; Used when running a Shortcut, to copy to RAMCard
.proc DoCopyToRAM
        copy    #0, move_flag
        copy    #$80, run_flag
        copy    #%11000000, operation_flags ; get size
        tsx
        stx     stack_stash
        jsr     PrepCallbacksForEnumeration
        jsr     DoDownloadDialogPhase
        jsr     EnumerationProcessSelectedFile
        jsr     PrepCallbacksForDownload
        jmp     DoCopyCommon
.endproc ; DoCopyToRAM

;;; --------------------------------------------------

.proc DoGetSize
        copy    #0, run_flag
        copy    #%11000000, operation_flags ; get size
        jmp     DoOpOnSelectionCommon
.endproc ; DoGetSize

.proc DoCopySelection
        copy    #0, operation_flags ; copy/delete
        copy    #$40, copy_delete_flags ; target is `path_buf3`
        jmp     DoOpOnSelectionCommon
.endproc ; DoCopySelection

;;; Used for drag/drop copy as well as deleting selection
;;; (if `drag_drop_params::result` equals `trash_icon_num`)
.proc DoDrop
        lda     drag_drop_params::result
        cmp     trash_icon_num
        bne     :+
        lda     #$80
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
:       lda     #$00
        sta     copy_delete_flags
        copy    #0, operation_flags ; copy/delete
        jmp     DoOpOnSelectionCommon
.endproc ; DoDrop

.proc DoLockUnlockImpl
lock:   lda     #$00
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
unlock: lda     #$80
        sta     unlock_flag
        copy    #%10000000, operation_flags ; lock/unlock
        jsr     DoOpOnSelectionCommon
        jmp     FinishOperation
.endproc ; DoLockUnlockImpl
        DoLock   := DoLockUnlockImpl::lock
        DoUnlock := DoLockUnlockImpl::unlock

.proc DoOpOnSelectionCommon
        tsx
        stx     stack_stash
        lda     operation_flags
        jne     BeginOperation  ; copy/delete

        ;; Copy or delete
        bit     copy_delete_flags
        bvs     common                ; path target
        bpl     compute_target_prefix ; drop target

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
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
    IF_NE
        jsr     ShowAlert
        return  #kOperationCanceled
    END_IF

common:
        ldy     path_buf3
:       copy    path_buf3,y, path_buf4,y
        dey
        bpl     :-
        FALL_THROUGH_TO BeginOperation
.endproc ; DoOpOnSelectionCommon

;;; --------------------------------------------------
;;; Start the actual operation

.proc BeginOperation
        copy    #0, do_op_flag

        jsr     PrepCallbacksForEnumeration
        bit     operation_flags
        bvs     @size
        bmi     @lock
        bit     copy_delete_flags
        bmi     @trash

        ;; Copy or Move?
        bvc     @drop
        ;; Target is path - always a copy
        lda     #0
        beq     @store      ; always
        ;; Drag/drop - compare src/dst paths (etc)
@drop:  lda     selected_window_id
        jsr     GetWindowPath
        jsr     CheckMoveOrCopy
@store: sta     move_flag
        jsr     DoCopyDialogPhase
        jmp     iterate_selection

@trash: jsr     DoDeleteDialogPhase
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
        bit     copy_delete_flags
        bmi     @trash
        jsr     PrepCallbacksForCopy
        jmp     iterate_selection

@trash: jsr     PrepCallbacksForDelete
        jmp     iterate_selection

@lock:  jsr     PrepCallbacksForLock
        FALL_THROUGH_TO iterate_selection

@size:  FALL_THROUGH_TO iterate_selection

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
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
        jne     ShowErrorAlert  ; too long

        ;; During selection iteration, allow Escape to cancel the operation.
        jsr     CheckCancel

        jsr     OpProcessSelectedFile

next_icon:

        inc     icon_count
        ldx     icon_count
        cpx     selected_icon_count
        bne     loop

        ;; Done icons - did we complete the operation?
        lda     do_op_flag
        bne     finish

        ;; No, we finished enumerating. Now do the real work.
        inc     do_op_flag

        ;; Do we need to show a confirmation dialog?
        ;; (Delete, Get Size)
        bit     operation_flags
        bmi     @lock_or_size

        bit     copy_delete_flags
        bpl     no_confirm
        bmi     confirm

@lock_or_size:
        bvc     no_confirm      ; lock/unlock

confirm:
        jsr     InvokeOperationConfirmCallback
        bit     operation_flags
        bvs     finish          ; get size - we're done!

no_confirm:
        jmp     perform

finish: jsr     InvokeOperationCompleteCallback
        return  #0
.endproc ; BeginOperation

.endscope ; operations
        DoCopySelection := operations::DoCopySelection
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

        ;; bit 7 set = delete, clear = copy
        ;; bit 6 set = target is `drag_drop_params::result`
        ;;       clear = target is `path_buf3`
copy_delete_flags:
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
;;; Output: A,X = icon name ptr

.proc GetIconName
        jsr     GetIconEntry
        clc
        adc     #IconEntry::name
        bcc     :+
        inx
:       rts
.endproc ; GetIconName

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
.endproc ; JoinPaths

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
.endproc ; DoEject

;;; ============================================================
;;; Inputs: A = icon number

.proc SmartportEject
        dib_buffer := ::IO_BUFFER

        ;; Look up device index by icon number
        ldy     #kMaxVolumes-1
:       cmp     device_to_icon_map,y
        beq     :+
        dey
        bpl     :-
        rts
:       lda     DEVLST,y        ; A = unit_number

        ;; Compute SmartPort dispatch address
        jsr     FindSmartportDispatchAddress
        bcs     done            ; not SP
        stax    status_dispatch
        stax    control_dispatch
        sty     status_unit_number
        sty     control_unit_number

        ;; Execute SmartPort call
        status_dispatch := *+1
        jsr     SELF_MODIFIED
        .byte   SPCall::Status
        .addr   status_params
        bcs     done            ; failure
        lda     dib_buffer+SPDIB::Device_Type_Code
        cmp     #SPDeviceType::Disk35
        bne     done            ; not 3.5, don't issue command

        ;; Execute SmartPort call
        control_dispatch := *+1
        jsr     SELF_MODIFIED
        .byte   SPCall::Control
        .addr   control_params

done:   rts

        DEFINE_SP_STATUS_PARAMS status_params, SELF_MODIFIED_BYTE, dib_buffer, 3 ; Return Device Information Block (DIB)
        status_unit_number := status_params::unit_num

        DEFINE_SP_CONTROL_PARAMS control_params, SELF_MODIFIED_BYTE, list, $04 ; For Apple/UniDisk 3.3: Eject disk
        control_unit_number := control_params::unit_number
list:   .word   0               ; 0 items in list
.endproc ; SmartportEject

;;; ============================================================
;;; "Get Info" dialog state and logic
;;; ============================================================

        DEFINE_READ_BLOCK_PARAMS block_params, $800, $A

.params get_info_dialog_params
state:  .byte   0
a_str:  .addr   0               ; e.g. string address
index:  .byte   0               ; index in selected icon list
.endparams

.enum GetInfoDialogState
        name    = 1
        type    = 2             ; blank for vol
        size    = 3             ; blocks (file)/size (volume)
        created = 4
        modified = 5
        locked  = 6             ; locked (file)/protected (volume)

        prompt  = 7             ; signals the dialog to enter loop

        prepare_file = $80      ; +2 if multiple
        prepare_vol  = $81      ; +2 if multiple
.endenum


;;; ============================================================
;;; Get Info

;;; Assert: At least one icon is selected
.proc DoGetInfo
        lda     selected_icon_count
        bne     :+
        rts

:       copy    #0, get_info_dialog_params::index
loop:   ldx     get_info_dialog_params::index
        cpx     selected_icon_count
        jeq     done

        ldx     get_info_dialog_params::index
        lda     selected_icon_list,x
        cmp     trash_icon_num
        jeq     next

        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
    IF_NE
        jsr     ShowAlert
        jmp     next
    END_IF

        ldy     path_buf3       ; Copy to `src_path_buf`
:       copy    path_buf3,y, src_path_buf,y
        dey
        bpl     :-

        ;; Try to get file info
common: jsr     GetSrcFileInfo
    IF_NE
        jsr     ShowAlert
        cmp     #kAlertResultTryAgain
        beq     common
        jmp     next
    END_IF

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
        ldy     #kMaxVolumes-1

:       cmp     device_to_icon_map,y
        beq     :+
        dey
        bpl     :-
        jmp     common2
:       lda     DEVLST,y
        sta     block_params::unit_num
        MLI_CALL READ_BLOCK, block_params
        bne     common2
        MLI_CALL WRITE_BLOCK, block_params
        cmp     #ERR_WRITE_PROTECTED
        bne     common2
        copy    #$80, write_protected_flag

common2:
        ;; --------------------------------------------------
        ;; Name
        copy    #GetInfoDialogState::name, get_info_dialog_params::state
        ldx     get_info_dialog_params::index
        lda     selected_icon_list,x
        jsr     GetIconName
        stax    get_info_dialog_params::a_str
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------
        ;; Type
        copy    #GetInfoDialogState::type, get_info_dialog_params::state
        lda     selected_window_id
    IF_ZERO
        ;; Volume
        COPY_STRING str_volume, text_buffer2
    ELSE
        ;; File
        lda     src_file_info_params::file_type
        pha
        jsr     ComposeFileTypeString
        COPY_STRING str_file_type, text_buffer2
        pla                     ; A = file type
        cmp     #FT_DIRECTORY
      IF_NE
        ldax    src_file_info_params::aux_type
        jsr     AppendAuxType
      END_IF
    END_IF
        copy16  #text_buffer2, get_info_dialog_params::a_str
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------
        ;; Size/Blocks
        copy    #GetInfoDialogState::size, get_info_dialog_params::state

        ;; Compose "12345K" or "12345K / 67890K" string
        buf := INVOKER_PREFIX
        copy    #0, buf

        lda     selected_window_id ; volume?
        beq     volume                ; yes

        ;; A file, so just show the size
        ldax    src_file_info_params::blocks_used
        jmp     append_size

        ;; A volume.
volume:
        ;; ProDOS TRM 4.4.5:
        ;; "When file information about a volume directory is requested, the
        ;; total number of blocks on the volume is returned in the aux_type
        ;; field and the total blocks for all files is returned in blocks_used.

        ldax    src_file_info_params::blocks_used
        jsr     ComposeSizeString

        ;; `text_buffer2` now has "12345K"

        ;; Copy into `buf`
        ldx     buf
        ldy     #0
:       inx
        lda     text_buffer2+1,y
        sta     buf,x
        iny
        cpy     text_buffer2
        bne     :-

        ;; Append " / " to `buf`
        inx
        copy    #' ', buf,x
        inx
        copy    #'/', buf,x
        inx
        copy    #' ', buf,x
        stx     buf

        ;; Load up the total volume size...
        ldax    src_file_info_params::aux_type

        ;; Compute "12345K" (either volume size or file size)
append_size:
        jsr     ComposeSizeString

        ;; Append latest to buffer
        ldx     buf
        ldy     #1
:       inx
        lda     text_buffer2,y
        sta     buf,x
        cpy     text_buffer2
        beq     :+
        iny
        bne     :-
:       stx     buf

        COPY_STRING buf, text_buffer2
        copy16  #text_buffer2, get_info_dialog_params::a_str
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------
        ;; Created date
        copy    #GetInfoDialogState::created, get_info_dialog_params::state
        COPY_STRUCT DateTime, src_file_info_params::create_date, datetime_for_conversion
        jsr     ComposeDateString
        copy16  #text_buffer2, get_info_dialog_params::a_str
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------
        ;; Modified date
        copy    #GetInfoDialogState::modified, get_info_dialog_params::state
        COPY_STRUCT DateTime, src_file_info_params::mod_date, datetime_for_conversion
        jsr     ComposeDateString
        copy16  #text_buffer2, get_info_dialog_params::a_str
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
        lda     src_file_info_params::access ; File
        and     #ACCESS_DEFAULT
        cmp     #ACCESS_DEFAULT
        beq     not_protected

is_protected:
        ldax    #aux::str_info_yes
        bne     show_protected           ; always
not_protected:
        ldax    #aux::str_info_no
show_protected:
        stax    get_info_dialog_params::a_str
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------

        copy    #GetInfoDialogState::prompt, get_info_dialog_params::state
        jsr     RunGetInfoDialogProc
        bne     done

next:   inc     get_info_dialog_params::index
        jmp     loop

done:   copy    #0, path_buf4
        rts

write_protected_flag:
        .byte   0

.proc RunGetInfoDialogProc
        param_jump InvokeDialogProc, kIndexGetInfoDialog, get_info_dialog_params
.endproc ; RunGetInfoDialogProc
.endproc ; DoGetInfo

;;; ============================================================

.enum RenameDialogState
        open  = $00
        run   = $80
        close = $40
.endenum

        old_name_buf := $1F00
        new_name_buf := stashed_name

        DEFINE_RENAME_PARAMS rename_params, src_path_buf, dst_path_buf

.params rename_dialog_params
state:  .byte   0
a_path: .addr   old_name_buf
.endparams

;;; Assert: Single icon selected, and it's not Trash.
.proc DoRenameImpl

start:
        lda     #0
        sta     result_flags

        lda     selected_icon_list
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
    IF_NE
        jsr     ShowAlert
        return  result_flags
    END_IF

        param_call CopyToSrcPath, path_buf3

        lda     selected_icon_list
        jsr     GetIconName
        stax    $06

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
        param_call CopyPtr2ToBuf, new_name_buf

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

        ;; Did the name change (ignoring case)?
        copy16  #old_name_buf, $06
        copy16  #new_name_buf, $08
        jsr     CompareStrings
        beq     no_change

        ;; Already exists? (Mostly for volumes, but works for files as well)
        jsr     GetDstFileInfo
        bne     :+
        lda     #ERR_DUPLICATE_FILENAME
        jsr     ShowAlert
        jmp     retry

        ;; Try to rename
:
no_change:
        ;; Update case bits, in memory or on disk
        jsr     ApplyCaseBits

        MLI_CALL RENAME, rename_params
        beq     finish
        ;; Failed, maybe retry
        jsr     ShowAlert       ; Alert options depend on specific ProDOS error
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        jeq     retry           ; `kAlertResultTryAgain` = 0
        lda     #RenameDialogState::close
        jsr     RunDialogProc
        jmp     fail

        ;; --------------------------------------------------
        ;; Completed - tear down the dialog...
finish: lda     #RenameDialogState::close
        jsr     RunDialogProc

        lda     selected_icon_list
        sta     icon_param

        ;; Erase the icon, in case new name is shorter
        ITK_CALL IconTK::EraseIcon, icon_param ; CHECKED - takes care of ports

        ;; Copy new string in
        icon_name_ptr := $06
        lda     selected_icon_list
        jsr     GetIconName
        stax    icon_name_ptr

        ldy     new_name_buf
:       lda     new_name_buf,y
        sta     (icon_name_ptr),y
        dey
        bpl     :-

        ;; If not volume, find and update associated FileEntry
        lda     selected_window_id
        jeq     end_filerecord_and_icon_update

        ;; Dig up the index of the icon within the window.
        icon_ptr := $06
        lda     icon_param
        jsr     GetIconEntry
        stax    icon_ptr

        ;; Compute bounds of icon bitmap
        jsr     GetSelectionViewBy
        .assert kViewByIcon = 0, error, "enum mismatch"
    IF_ZERO
        ITK_CALL IconTK::GetIconBounds, icon_param ; inits `tmp_rect`
        sub16_8 tmp_rect::y2, #kIconLabelHeight + kIconLabelGap, tmp_rect::y2
    END_IF

        ldy     #IconEntry::record_num
        lda     (icon_ptr),y
        pha                     ; A = index of icon in window

        ;; Find the window's FileRecord list.
        file_record_ptr := $08
        lda     selected_window_id
        jsr     GetFileRecordListForWindow
        stax    file_record_ptr ; points at head of list (entry count)
        inc16   file_record_ptr ; now points at first FileRecord in list

        ;; Look up the FileRecord within the list.
        pla                     ; A = index
        .assert .sizeof(FileRecord) = 32, error, "FileRecord size must be 2^5"
        jsr     ATimes32        ; A,X = index * 32
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

        ;; Filename change may alter icon. Don't bank out FileRecords yet.
        ldy     #FileRecord::file_type
        lda     (file_record_ptr),y
        sta     icontype_filetype
        ldy     #FileRecord::aux_type
        copy16in (file_record_ptr),y, icontype_auxtype
        ldy     #FileRecord::blocks
        copy16in (file_record_ptr),y, icontype_blocks
        copy16  #new_name_buf, icontype_filename

        ;; Now we're done with FileRecords.
        bit     LCBANK1
        bit     LCBANK1

        jsr     GetSelectionViewBy
        .assert kViewByIcon = 0, error, "enum mismatch"
    IF_ZERO
        sta     view_by
        jsr     GetIconType
        view_by := *+1
        ldy     #SELF_MODIFIED_BYTE
        jsr     CreateIconsForWindowImpl::FindIconDetailsForIconType

        ;; Use new `icon_height` to offset vertically.
        ;; Add old icon height to make icony top of text
        ldy     #IconEntry::icony
        sub16in tmp_rect::y2, CreateIconsForWindowImpl::icon_height, (icon_ptr),y
        ;; Use `iconbits` to populate IconEntry::iconbits
        ldy     #IconEntry::iconbits
        copy16in CreateIconsForWindowImpl::iconbits, (icon_ptr),y
        ;; Assumes `iconentry_flags` will not change, regardless of icon.
    END_IF

end_filerecord_and_icon_update:

        ;; Draw the (maybe new) icon
        ITK_CALL IconTK::DrawIcon, icon_param

        ;; Is there a window for the folder/volume?
        jsr     FindWindowForSrcPath
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
        ;; Totally done

        return result_flags

.proc RunDialogProc
        sta     rename_dialog_params
        param_jump InvokeDialogProc, kIndexRenameDialog, rename_dialog_params
.endproc ; RunDialogProc

;;; N bit ($80) set if a window title was changed
result_flags:
        .byte   0
.endproc ; DoRenameImpl
DoRename        := DoRenameImpl::start

;;; ============================================================
;;; Following a rename or move of `src_path_buf` to `dst_path_buf`,
;;; update any affected window paths.
;;;
;;; Uses `FindWindowsForPrefix`
;;; Assert: The path actually changed.

.proc UpdateWindowPaths
        ;; Update paths for any matching/child windows.
        param_call FindWindowsForPrefix, src_path_buf
        lda     found_windows_count
    IF_NOT_ZERO

        dec     found_windows_count
wloop:  ldx     found_windows_count
        lda     found_windows_list,x
        jsr     GetWindowPath
        jsr     UpdateTargetPath

        dec     found_windows_count
        bpl     wloop
    END_IF

        rts
.endproc ; UpdateWindowPaths

;;; ============================================================
;;; Replace `src_path_buf` as the prefix of path at $06 with `dst_path_buf`.
;;; Assert: `src_path_buf` is a prefix of the path at $06!
;;; Inputs: A,X = path to update, `src_path_buf` and `dst_path_buf`,
;;; Outputs: Path updated.
;;; Modifies `tmp_path_buf` and $1F00
;;; NOTE: Sometimes called with LCBANK2; must not assume LCBANK1 present!
;;; Trashes $06

.proc UpdateTargetPath
        dst := $06

        old_path := $1F00
        new_path := tmp_path_buf   ; arbitrary usage of this buffer

        stax    dst

        ;; Set `old_path` to the old path (should be `src_path_buf` + suffix)
        param_call CopyPtr1ToBuf, old_path

        ;; Set `new_path` to the new prefix
        ldy     dst_path_buf
:       lda     dst_path_buf,y
        sta     new_path,y
        dey
        bpl     :-

        ;; Copy the suffix from `old_path` to `new_path`
        ldx     src_path_buf
        cpx     old_path
        beq     assign          ; paths are equal, no copying needed

        ldy     dst_path_buf
:       inx                     ; advance into suffix
        iny
        lda     old_path,x
        sta     new_path,y
        cpx     old_path
        bne     :-
        sty     new_path

        ;; Assign the new window path
assign: ldy     new_path
:       lda     new_path,y
        sta     (dst),y
        dey
        bpl     :-

        rts
.endproc ; UpdateTargetPath

;;; ============================================================
;;; Following a rename or move of `src_path_buf` to `dst_path_buf`,
;;; update the target path if needed.
;;;
;;; Inputs: A,X = pointer to path to update
;;; Outputs: Z=1 if updated, Z=0 if no change
;;; NOTE: Sometimes called with LCBANK2; must not assume LCBANK1 present!
;;; Trashes $06, $08

.proc MaybeUpdateTargetPath
        ptr := $08

        stax    ptr
        jsr     MaybeStripSlash

        ;; Is `src_path_buf` a prefix?
        copy16  #src_path_buf, $06
        jsr     IsPathPrefixOf  ; Z=0 if a prefix
        php
    IF_NE
        ;; It's a prefix! Do the replacement
        param_call_indirect UpdateTargetPath, ptr
    END_IF

        jsr     MaybeRestoreSlash
        plp                     ; Z=0 if updated
    IF_NE
        return  #0
    END_IF
        return  #$FF

.proc MaybeStripSlash
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
:       rts
.endproc ; MaybeStripSlash

.proc MaybeRestoreSlash
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
:       rts
.endproc ; MaybeRestoreSlash
        slash_flag := MaybeRestoreSlash::slash_flag

.endproc ; MaybeUpdateTargetPath

;;; ============================================================

.proc UpdatePrefix
        path := tmp_path_buf    ; depends on `src_path_buf`, `dst_path_buf`

        ;; ProDOS Prefix
        MLI_CALL GET_PREFIX, get_set_prefix_params
        param_call MaybeUpdateTargetPath, path
    IF_EQ
        MLI_CALL SET_PREFIX, get_set_prefix_params
    END_IF

        ;; Original Prefix
        jsr     GetCopiedToRAMCardFlag
    IF_MINUS
        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2
        param_call MaybeUpdateTargetPath, DESKTOP_ORIG_PREFIX
        param_call MaybeUpdateTargetPath, RAMCARD_PREFIX
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1
    END_IF

        ;; Restart Prefix
        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2
        param_call MaybeUpdateTargetPath, SELECTOR + QuitRoutine::prefix_buffer_offset
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        rts

        DEFINE_GET_PREFIX_PARAMS get_set_prefix_params, path
.endproc ; UpdatePrefix

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
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
    IF_NE
        jsr     ShowAlert
        return  result_flag
    END_IF

        param_call CopyToSrcPath, path_buf3

        ldx     index
        lda     selected_icon_list,x
        jsr     GetIconName
        stax    $06

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
        return  result_flag

        ;; --------------------------------------------------
        ;; Success, new name in Y,X

success:
        new_name_ptr := $08
        sty     new_name_ptr
        stx     new_name_ptr+1
        param_call CopyPtr2ToBuf, new_name_buf

        lda     selected_window_id
        jsr     GetWindowPath
        jsr     CopyToDstPath

        ;; Append new filename
        ldax    new_name_ptr
        jsr     AppendFilenameToDstPath

        ;; --------------------------------------------------
        ;; Check for unchanged/duplicate name

        jsr     GetDstFileInfo
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
        ;; Update name case bits on disk, if possible.
        COPY_STRING dst_path_buf, src_path_buf
        jsr     ApplyCaseBits
:

        ;; --------------------------------------------------
        ;; Totally done - advance to next selected icon
        inc     index
        jmp     loop

.proc RunDialogProc
        sta     duplicate_dialog_params
        param_jump InvokeDialogProc, kIndexDuplicateDialog, duplicate_dialog_params
.endproc ; RunDialogProc

;;; N bit ($80) set if anything succeeded (and window needs refreshing)
result_flag:
        .byte   0
.endproc ; DoDuplicateImpl
DoDuplicate     := DoDuplicateImpl::start

;;; ============================================================

;;; Memory Map
;;; ...
;;; $1F80 - $1FFF   - dst path buffer
;;; $1F00 - $1F7F   - unused
;;; $1500 - $1EFF   - file data buffer
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
        kBufSize = $A00
        .assert file_data_buffer + kBufSize <= dst_path_buf, error, "Buffer overlap"
        .assert (kBufSize .mod BLOCK_SIZE) = 0, error, "better performance for an integral number of blocks"

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
op_jt_addr0:  .addr   0
op_jt_addr1:  .addr   0
op_jt_addr3:  .addr   0
        ASSERT_TABLE_SIZE op_jt_addrs, kOpJTAddrsSize

op_jt0: jmp     (op_jt_addr0)   ; process selected file
op_jt1: jmp     (op_jt_addr1)   ; process directory entry
op_jt3: jmp     (op_jt_addr3)   ; when finished directory

OpProcessSelectedFile   := op_jt0
OpProcessDirectoryEntry := op_jt1
OpFinishDirectory       := op_jt3

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
.endproc ; PushEntryCount

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
.endproc ; PopEntryCount

.proc OpenSrcDir
        lda     #0
        sta     entries_read
        sta     entries_read+1
        sta     entries_read_this_block

@retry: MLI_CALL OPEN, open_src_dir_params
        beq     :+
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     @retry          ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialog

:       lda     open_src_dir_params::ref_num
        sta     op_ref_num
        sta     read_block_pointers_params::ref_num

@retry2:MLI_CALL READ, read_block_pointers_params
        beq     :+
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     @retry2         ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialog

:       jmp     ReadFileEntry
.endproc ; OpenSrcDir

.proc CloseSrcDir
        lda     op_ref_num
        sta     close_src_dir_params::ref_num
@retry: MLI_CALL CLOSE, close_src_dir_params
        beq     :+
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     @retry          ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialog

:       rts
.endproc ; CloseSrcDir

.proc ReadFileEntry
        inc16   entries_read
        lda     op_ref_num
        sta     read_src_dir_entry_params::ref_num
@retry: MLI_CALL READ, read_src_dir_entry_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     eof
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     @retry          ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialog

:       inc     entries_read_this_block
        lda     entries_read_this_block
        cmp     num_entries_per_block
        bcc     :+
        copy    #0, entries_read_this_block
        copy    op_ref_num, read_padding_bytes_params::ref_num
        MLI_CALL READ, read_padding_bytes_params
:       return  #0

eof:    return  #$FF
.endproc ; ReadFileEntry

;;; ============================================================

.proc PrepToOpenDir
        copy16  entries_read, entries_to_skip
        jsr     CloseSrcDir
        jsr     PushEntryCount
        jsr     AppendFileEntryToSrcPath
        jmp     OpenSrcDir
.endproc ; PrepToOpenDir

.proc FinishDir
        jsr     CloseSrcDir
        jsr     OpFinishDirectory
        jsr     RemoveSrcPathSegment
        jsr     PopEntryCount
        jsr     OpenSrcDir

:       cmp16   entries_read, entries_to_skip
        bcs     done
        jsr     ReadFileEntry
        jmp     :-
done:   rts
.endproc ; FinishDir

.proc ProcessDir
        copy    #0, process_depth
        jsr     OpenSrcDir
loop:   jsr     ReadFileEntry
        bne     end_dir

        param_call AdjustFileEntryCase, file_entry_buf

        lda     file_entry_buf + FileEntry::storage_type_name_length
        beq     loop

        jsr     ConvertFileEntryToFileInfo

        ;; Simplify to length-prefixed string
        lda     file_entry_buf + FileEntry::storage_type_name_length
        and     #NAME_LENGTH_MASK
        sta     file_entry_buf

        ;; During directory iteration, allow Escape to cancel the operation.
        jsr     CheckCancel

        copy    #0, cancel_descent_flag
        jsr     OpProcessDirectoryEntry
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
.endproc ; ProcessDir

cancel_descent_flag:  .byte   0

;;; ============================================================
;;; "Copy" (including Drag/Drop/Move) files state and logic
;;; ============================================================

;;; `CopyProcessSelectedFile`
;;;  - delegates to `CopyProcessDirectoryEntry`; if op=move, fixes up paths
;;; `CopyProcessDirectoryEntry`
;;;  - copies file/directory
;;; `CopyFinishDirectory`
;;;  - if dir and op=move, deletes dir

;;; Overlays for copy operation (`op_jt_addrs`)
callbacks_for_copy:
        .addr   CopyProcessSelectedFile
        .addr   CopyProcessDirectoryEntry
        .addr   CopyFinishDirectory
        ASSERT_TABLE_SIZE callbacks_for_copy, kOpJTAddrsSize

.enum CopyDialogLifecycle
        open            = 0
        count           = 1
        show            = 2
        close           = 3
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
.endproc ; DoCopyDialogPhase

.proc CopyDialogEnumerationCallback
        stax    copy_dialog_params::count
        copy    #CopyDialogLifecycle::count, copy_dialog_params::phase
        jmp     RunCopyDialogProc
.endproc ; CopyDialogEnumerationCallback

.proc PrepCallbacksForCopy
        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_copy,y,  op_jt_addrs,y
        dey
        bpl     :-

        copy    #0, all_flag
        rts
.endproc ; PrepCallbacksForCopy

.proc CopyDialogCompleteCallback
        copy    #CopyDialogLifecycle::close, copy_dialog_params::phase
        jmp     RunCopyDialogProc
.endproc ; CopyDialogCompleteCallback

;;; ============================================================
;;; "Download" - shares heavily with Copy

.proc DoDownloadDialogPhase
        copy    #CopyDialogLifecycle::open, copy_dialog_params::phase
        copy16  #DownloadDialogEnumerationCallback, operation_enumeration_callback
        copy16  #DownloadDialogCompleteCallback, operation_complete_callback
        param_jump InvokeDialogProc, kIndexDownloadDialog, copy_dialog_params
.endproc ; DoDownloadDialogPhase

.proc DownloadDialogEnumerationCallback
        stax    copy_dialog_params::count
        copy    #CopyDialogLifecycle::count, copy_dialog_params::phase
        param_jump InvokeDialogProc, kIndexDownloadDialog, copy_dialog_params
.endproc ; DownloadDialogEnumerationCallback

.proc PrepCallbacksForDownload
        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_copy,y, op_jt_addrs,y
        dey
        bpl     :-

        copy    #$80, all_flag
        copy16  #DownloadDialogTooLargeCallback, operation_toolarge_callback
        rts
.endproc ; PrepCallbacksForDownload

.proc DownloadDialogCompleteCallback
        copy    #CopyDialogLifecycle::close, copy_dialog_params::phase
        param_jump InvokeDialogProc, kIndexDownloadDialog, copy_dialog_params
.endproc ; DownloadDialogCompleteCallback

.proc DownloadDialogTooLargeCallback
        param_call ShowAlertParams, AlertButtonOptions::OK, aux::str_ramcard_full
        jmp     CloseFilesCancelDialog
.endproc ; DownloadDialogTooLargeCallback

;;; ============================================================
;;; Handle copying of a file.
;;; Calls into the recursion logic of `ProcessDir` as necessary.

.proc CopyProcessFileImpl
        ;; Normal handling, via `CopyProcessSelectedFile`
selected:
        copy    #$80, copy_run_flag
        lda     #0
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction

        ;; Via File > Duplicate or copying to RAMCard
not_selected:
        lda     #$FF

        sta     is_not_selected_flag
        copy    #CopyDialogLifecycle::show, copy_dialog_params::phase
        jsr     CopyPathsFromBufsToSrcAndDst
        bit     operation_flags
        bvc     @not_run
        jsr     CheckVolBlocksFree           ; dst is a volume path (RAM Card)
@not_run:
        bit     copy_run_flag
        bpl     get_src_info    ; never taken ???
        bvs     L9A50
        is_not_selected_flag := *+1
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
        ;; When recursing, called with `src_file_info_params` pre-populated
        ;; But for selected files, need to get file info.
        bit     is_not_selected_flag
    IF_NC
@retry: jsr     GetSrcFileInfo
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry
:
    END_IF

        lda     src_file_info_params::storage_type
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
        ldx     #src_file_info_params::storage_type - src_file_info_params::access
:       lda     src_file_info_params::access,x
        sta     create_params2::access,x
        dex
        bpl    :-

        ;; Explicitly set default access
        copy    #ACCESS_DEFAULT, create_params2::access

        lda     copy_run_flag
        beq     success         ; never taken ???
        jsr     CheckSpaceAndShowPrompt
        bcs     failure

        ;; Copy create_time/create_date
        ldx     #.sizeof(DateTime)-1
:       lda     src_file_info_params::create_date,x
        sta     create_params2::create_date,x
        dex
        bpl     :-

        ;; If a volume, need to create a subdir instead
        lda     create_params2::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     :+
        lda     #ST_LINKED_DIRECTORY
        sta     create_params2::storage_type
:
        ;; TODO: Dedupe with `TryCreateDst`
        jsr     DecrementOpFileCount
retry:  MLI_CALL CREATE, create_params2
        beq     success

        cmp     #ERR_DUPLICATE_FILENAME
        bne     err
        bit     all_flag
        bmi     yes

        param_call ShowAlertParams, AlertButtonOptions::YesNoAllCancel, aux::str_exists_prompt
        jsr     SetCursorWatch  ; preserves A

        cmp     #kAlertResultYes
        beq     yes
        cmp     #kAlertResultNo
        beq     failure
        cmp     #kAlertResultAll
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
.endproc ; CopyProcessFileImpl
        CopyProcessNotSelectedFile := CopyProcessFileImpl::not_selected

;;; ============================================================

.proc CopyProcessSelectedFile
        jsr     CopyProcessFileImpl::selected

        bit     move_flag
    IF_NS
        jsr     UpdateWindowPaths
        jsr     UpdatePrefix
    END_IF

        rts
.endproc ; CopyProcessSelectedFile

;;; ============================================================

src_path_slash_index:
        .byte   0

;;; ============================================================
;;; If moving, delete src file/directory.

.proc CopyFinishDirectory
        jsr     RemoveDstPathSegment
        FALL_THROUGH_TO MaybeFinishFileMove
.endproc ; CopyFinishDirectory

.proc MaybeFinishFileMove
        ;; Copy or move?
        bit     move_flag
        bpl     done

        ;; Was a move - delete file
@retry: MLI_CALL DESTROY, destroy_params
        beq     done
        cmp     #ERR_ACCESS_ERROR
        bne     :+
        jsr     UnlockSrcFile
        beq     @retry
        bne     done            ; silently leave file

:       jsr     ShowErrorAlert
        jmp     @retry
done:   rts
.endproc ; MaybeFinishFileMove

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

.proc CopyProcessDirectoryEntry
        jsr     AppendFileEntryToDstPath
        jsr     AppendFileEntryToSrcPath
        jsr     DecFileCountAndRunCopyDialogProc

        ;; Called with `src_file_info_params` pre-populated
        lda     file_entry_buf + FileEntry::file_type
        lda     src_file_info_params::storage_type
        cmp     #ST_LINKED_DIRECTORY
        bne     regular_file

        ;; --------------------------------------------------
        ;; Directory

        jsr     TryCreateDst
        bcs     :+
        ;; Success - leave dst path segment in place for recursion
        jsr     RemoveSrcPathSegment
        rts
:
        copy    #$FF, cancel_descent_flag
        bne     done            ; always

        ;; --------------------------------------------------
        ;; File

regular_file:
        cmp     #ST_TREE_FILE+1 ; only seedling/sapling/tree supported
    IF_GE
        lda     #kErrUnsupportedFileType
        jsr     ShowAlert
        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialog
        bne     done            ; always
    END_IF

        jsr     CheckSpaceAndShowPrompt
        jcs     CloseFilesCancelDialog

        jsr     TryCreateDst
        bcs     done

        jsr     DoFileCopy
        jsr     MaybeFinishFileMove

done:   jsr     RemoveSrcPathSegment
        jsr     RemoveDstPathSegment
        rts
.endproc ; CopyProcessDirectoryEntry

;;; ============================================================

.proc RunCopyDialogProc
        param_jump InvokeDialogProc, kIndexCopyDialog, copy_dialog_params
.endproc ; RunCopyDialogProc

;;; ============================================================

.proc CheckVolBlocksFree
@retry: jsr     GetDstFileInfo
        beq     :+
        jsr     ShowErrorAlertDst
        jmp     @retry

:       sub16   dst_file_info_params::aux_type, dst_file_info_params::blocks_used, blocks_free
        cmp16   blocks_free, op_block_count
        jcc     InvokeOperationTooLargeCallback

        rts

blocks_free:
        .word   0
.endproc ; CheckVolBlocksFree

;;; ============================================================

;;; Assert: `src_file_info_params` is populated
.proc CheckSpaceAndShowPrompt
        jsr     CheckSpace
        bcc     done

        bit     move_flag
    IF_NS
        ldax    #aux::str_large_move_prompt
    ELSE
        ldax    #aux::str_large_copy_prompt
    END_IF
        ldy     #AlertButtonOptions::OKCancel
        jsr     ShowAlertParams ; A,X = string, Y = AlertButtonOptions
        jsr     SetCursorWatch  ; preserves A

        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialog

        sec
done:   rts

.proc CheckSpace
        ;; If destination doesn't exist, 0 blocks will be reclaimed.
        copy16  #0, existing_size

        ;; Does destination exist?
@retry2:jsr     GetDstFileInfo
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
        jsr     GetDstFileInfo
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
.endproc ; CheckSpace
.endproc ; CheckSpaceAndShowPrompt

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
        jsr     CloseSrc        ; swap if necessary
:       jsr     OpenDst
        bne     :-
        jsr     CopyDstRefNum
        MLI_CALL SET_MARK, mark_dst_params

        ;; Write
write:  bit     src_eof_flag
        bmi     eof
        jsr     WriteDst
        bit     src_dst_exclusive_flag
        bpl     read
        jsr     CloseDst       ; swap if necessary
        jsr     OpenSrc
        jsr     CopySrcRefNum

        MLI_CALL SET_MARK, mark_src_params
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
@retry: MLI_CALL OPEN, open_src_params
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry
:       rts
.endproc ; OpenSrc

.proc CopySrcRefNum
        lda     open_src_params::ref_num
        sta     read_src_params::ref_num
        sta     close_src_params::ref_num
        sta     mark_src_params::ref_num
        rts
.endproc ; CopySrcRefNum

.proc OpenDst
@retry: MLI_CALL OPEN, open_dst_params
        beq     done
        cmp     #ERR_VOL_NOT_FOUND
        beq     not_found
        jsr     ShowErrorAlertDst
        jmp     @retry

not_found:
        jsr     ShowErrorAlertDst
        lda     #ERR_VOL_NOT_FOUND

done:   rts
.endproc ; OpenDst

.proc CopyDstRefNum
        lda     open_dst_params::ref_num
        sta     write_dst_params::ref_num
        sta     close_dst_params::ref_num
        sta     mark_dst_params::ref_num
        rts
.endproc ; CopyDstRefNum

.proc ReadSrc
        copy16  #kBufSize, read_src_params::request_count
@retry: MLI_CALL READ, read_src_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     eof
        jsr     ShowErrorAlert
        jmp     @retry

:       copy16  read_src_params::trans_count, write_dst_params::request_count
        ora     read_src_params::trans_count
        bne     :+
eof:    copy    #$FF, src_eof_flag
:       MLI_CALL GET_MARK, mark_src_params
        rts
.endproc ; ReadSrc

.proc WriteDst
@retry: MLI_CALL WRITE, write_dst_params
        beq     :+
        jsr     ShowErrorAlertDst
        jmp     @retry
:       MLI_CALL GET_MARK, mark_dst_params
        rts
.endproc ; WriteDst

.proc CloseDst
        MLI_CALL CLOSE, close_dst_params
        rts
.endproc ; CloseDst

.proc CloseSrc
        MLI_CALL CLOSE, close_src_params
        rts
.endproc ; CloseSrc

        ;; Set if src/dst can't be open simultaneously.
src_dst_exclusive_flag:
        .byte   0

src_eof_flag:
        .byte   0

.endproc ; DoFileCopy

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
retry:  MLI_CALL CREATE, create_params3
        beq     success

        cmp     #ERR_DUPLICATE_FILENAME
        bne     err
        bit     all_flag
        bmi     yes

        param_call ShowAlertParams, AlertButtonOptions::YesNoAllCancel, aux::str_exists_prompt
        jsr     SetCursorWatch  ; preserves A

        cmp     #kAlertResultYes
        beq     yes
        cmp     #kAlertResultNo
        beq     failure
        cmp     #kAlertResultAll
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
.endproc ; TryCreateDst

;;; ============================================================
;;; "Delete" (Delete/Trash) files dialog state and logic
;;; ============================================================

;;; `DeleteProcessSelectedFile`
;;;  - if dir, recurses; delegates to `DestroySrcFileWithRetry`; if dir, destroys dir
;;; `DeleteProcessDirectoryEntry`
;;;  - if not dir, delegates to `DestroySrcFileWithRetry`
;;; `DeleteFinishDirectory`
;;;  - destroys dir via `DestroySrcFileWithRetry`

;;; Overlays for delete operation (`op_jt_addrs`)
callbacks_for_delete:
        .addr   DeleteProcessSelectedFile
        .addr   DeleteProcessDirectoryEntry
        .addr   DeleteFinishDirectory
        ASSERT_TABLE_SIZE callbacks_for_delete, kOpJTAddrsSize

.enum DeleteDialogLifecycle
        open            = 0
        count           = 1
        show            = 2
        close           = 3
.endenum

.params delete_dialog_params
phase:  .byte   0
count:  .word   0
a_path: .addr   src_path_buf
.endparams

.proc DoDeleteDialogPhase
        copy    #DeleteDialogLifecycle::open, delete_dialog_params::phase
        copy16  #DeleteDialogConfirmCallback, operation_confirm_callback
        copy16  #DeleteDialogEnumerationCallback, operation_enumeration_callback
        jsr     RunDeleteDialogProc
        copy16  #DeleteDialogCompleteCallback, operation_complete_callback
        rts

.proc DeleteDialogEnumerationCallback
        stax    delete_dialog_params::count
        copy    #DeleteDialogLifecycle::count, delete_dialog_params::phase
        jmp     RunDeleteDialogProc
.endproc ; DeleteDialogEnumerationCallback

.proc DeleteDialogConfirmCallback
        ;; `text_input_buf` is used rather than `text_buffer2` due to size
        jsr ComposeFileCountString
        copy    #0, text_input_buf
        param_call AppendToTextInputBuf, aux::str_delete_confirm_prefix
        param_call AppendToTextInputBuf, str_file_count
        param_call_indirect AppendToTextInputBuf, ptr_str_files_suffix
        param_call AppendToTextInputBuf, aux::str_delete_confirm_suffix

        param_call ShowAlertParams, AlertButtonOptions::OKCancel, text_input_buf
        jsr     SetCursorWatch  ; preserves A

        cmp     #kAlertResultOK
        beq     :+
        lda     #kOperationCanceled
        jmp     CloseFilesCancelDialogWithResult
:       rts
.endproc ; DeleteDialogConfirmCallback

.endproc ; DoDeleteDialogPhase

;;; ============================================================

.proc PrepCallbacksForDelete
        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_delete,y, op_jt_addrs,y
        dey
        bpl     :-

        copy    #0, all_flag
        rts
.endproc ; PrepCallbacksForDelete

.proc DeleteDialogCompleteCallback
        copy    #DeleteDialogLifecycle::close, delete_dialog_params::phase
        jmp     RunDeleteDialogProc
.endproc ; DeleteDialogCompleteCallback

;;; ============================================================
;;; Handle deletion of a selected file.
;;; Calls into the recursion logic of `ProcessDir` as necessary.

.proc DeleteProcessSelectedFile
        copy    #DeleteDialogLifecycle::show, delete_dialog_params::phase
        jsr     CopyPathsFromBufsToSrcAndDst

@retry: jsr     GetSrcFileInfo
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry

        ;; Check if it's a regular file or directory
:       lda     src_file_info_params::storage_type
        ;; ST_VOLUME_DIRECTORY excluded because volumes are ejected.
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        cmp     #ST_TREE_FILE+1 ; only seedling/sapling/tree supported
    IF_GE
        lda     #kErrUnsupportedFileType
        jsr     ShowAlert
        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialog
        rts
    END_IF
        jmp     do_destroy

is_dir:
        ;; Recurse, and process directory
        jsr     ProcessDir
        ;; ST_VOLUME_DIRECTORY excluded because volumes are ejected.
        FALL_THROUGH_TO do_destroy

do_destroy:
        jsr     DecFileCountAndRunDeleteDialogProc
        jsr     DecrementOpFileCount

        FALL_THROUGH_TO DestroySrcFileWithRetry
.endproc ; DeleteProcessSelectedFile

.proc DestroySrcFileWithRetry
retry:  MLI_CALL DESTROY, destroy_params
        beq     done

        ;; Failed - determine why, maybe try to unlock.
        ;; TODO: If it's a directory, this could be because it's not empty,
        ;; e.g. if it contained files that could not be deleted.
        cmp     #ERR_ACCESS_ERROR
        bne     error
        bit     all_flag
        bmi     unlock

        param_call ShowAlertParams, AlertButtonOptions::YesNoAllCancel, aux::str_delete_locked_file
        jsr     SetCursorWatch  ; preserves A

        cmp     #kAlertResultNo
        beq     done
        cmp     #kAlertResultYes
        beq     unlock
        cmp     #kAlertResultAll
        bne     :+
        copy    #$80, all_flag
        bne     unlock          ; always
        ;; PromptResult::cancel
:       jmp     CloseFilesCancelDialog

unlock: jsr     UnlockSrcFile
        beq     retry

done:   rts

error:  jsr     ShowErrorAlert
        jmp     retry
.endproc ; DestroySrcFileWithRetry

.proc UnlockSrcFile
        jsr     GetSrcFileInfo
        lda     src_file_info_params::access
        and     #$80            ; destroy enabled bit set?
        bne     done            ; yes, no need to unlock

        lda     #ACCESS_DEFAULT
        sta     src_file_info_params::access
        jsr     SetSrcFileInfo

done:   rts
.endproc ; UnlockSrcFile

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

.proc DeleteProcessDirectoryEntry
        jsr     AppendFileEntryToSrcPath
        jsr     DecFileCountAndRunDeleteDialogProc
        jsr     DecrementOpFileCount

        ;; Called with `src_file_info_params` pre-populated
        ;; Directories will be processed separately
        lda     src_file_info_params::storage_type
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

        jsr     DestroySrcFileWithRetry
next_file:
        jmp     RemoveSrcPathSegment
.endproc ; DeleteProcessDirectoryEntry

;;; ============================================================
;;; Delete directory when exiting via traversal

.proc DeleteFinishDirectory
        param_call InvokeDialogProc, kIndexDeleteDialog, delete_dialog_params
        jmp     DestroySrcFileWithRetry
.endproc ; DeleteFinishDirectory

.proc RunDeleteDialogProc
        param_jump InvokeDialogProc, kIndexDeleteDialog, delete_dialog_params
.endproc ; RunDeleteDialogProc

;;; ============================================================
;;; "Lock"/"Unlock" dialog state and logic
;;; ============================================================

;;; `LockProcessSelectedFile`
;;;  - if dir, recurses; locks file via `LockFileCommon`
;;; `LockProcessDirectoryEntry`
;;;  - locks file via `LockFileCommon`
;;; (finishing a directory is a no-op)

;;; Overlays for lock/unlock operation (`op_jt_addrs`)
callbacks_for_lock:
        .addr   LockProcessSelectedFile
        .addr   LockProcessDirectoryEntry
        .addr   DoNothing
        ASSERT_TABLE_SIZE callbacks_for_lock, kOpJTAddrsSize

.enum LockDialogLifecycle
        open            = 0 ; opening window, initial label
        count           = 1 ; show operation details (e.g. file count)
        show            = 2 ; performing operation
        close           = 3 ; destroy window
.endenum

.params lock_unlock_dialog_params
phase:  .byte   0
count:  .word   0
a_path: .addr   src_path_buf
.endparams

.proc DoLockDialogPhase
        copy    #LockDialogLifecycle::open, lock_unlock_dialog_params::phase
        copy16  #LockDialogEnumerationCallback, operation_enumeration_callback
        jsr     RunLockDialogProc
        copy16  #LockDialogCompleteCallback, operation_complete_callback
        rts
.endproc ; DoLockDialogPhase

.proc LockDialogEnumerationCallback
        stax    lock_unlock_dialog_params::count
        copy    #LockDialogLifecycle::count, lock_unlock_dialog_params::phase
        jmp     RunLockDialogProc
.endproc ; LockDialogEnumerationCallback

.proc PrepCallbacksForLock
        ldy     #kOpJTAddrsSize-1
:       copy    callbacks_for_lock,y, op_jt_addrs,y
        dey
        bpl     :-

        rts
.endproc ; PrepCallbacksForLock

.proc LockDialogCompleteCallback
        copy    #LockDialogLifecycle::close, lock_unlock_dialog_params::phase
        jmp     RunLockDialogProc
.endproc ; LockDialogCompleteCallback

.proc RunLockDialogProc
        param_jump InvokeDialogProc, kIndexLockDialog, lock_unlock_dialog_params
.endproc ; RunLockDialogProc

;;; ============================================================
;;; Handle locking of a selected file.
;;; Calls into the recursion logic of `ProcessDir` as necessary.

.proc LockProcessSelectedFile
        copy    #LockDialogLifecycle::show, lock_unlock_dialog_params::phase
        jsr     CopyPathsFromBufsToSrcAndDst

@retry: jsr     GetSrcFileInfo
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry

:       lda     src_file_info_params::storage_type
        sta     storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        bne     do_lock

is_dir:
        jsr     ProcessDir
        storage_type := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #ST_VOLUME_DIRECTORY
        bne     :+
        rts
:       jsr     GetSrcFileInfo
        FALL_THROUGH_TO do_lock

do_lock:
        jsr     LockFileCommon
        jmp     AppendFileEntryToSrcPath ; ???
.endproc ; LockProcessSelectedFile

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

.proc LockProcessDirectoryEntry
        jsr     AppendFileEntryToSrcPath
        FALL_THROUGH_TO LockFileCommon
.endproc ; LockProcessDirectoryEntry

.proc LockFileCommon
        jsr     update_dialog

        jsr     DecrementOpFileCount

        ;; Called with `src_file_info_params` pre-populated
        lda     src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     ok

        lda     src_file_info_params::access
        bit     unlock_flag
    IF_NS
        ora     #LOCKED_MASK    ; grant access
    ELSE
        and     #AS_BYTE(~LOCKED_MASK) ; revoke access
    END_IF
        sta     src_file_info_params::access

retry:  jsr     SetSrcFileInfo
        beq     ok
        jsr     ShowErrorAlert
        jmp     retry

ok:     jmp     RemoveSrcPathSegment

update_dialog:
        sub16   op_file_count, #1, lock_unlock_dialog_params::count
        jmp     RunLockDialogProc
.endproc ; LockFileCommon

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
        param_call InvokeDialogProc, kIndexGetSizeDialog, get_size_dialog_params
        copy16  #GetSizeDialogCompleteCallback, operation_complete_callback
        rts
.endproc ; DoGetSizeDialogPhase

.proc GetSizeDialogEnumerationCallback
        copy    #GetSizeDialogLifecycle::count, get_size_dialog_params::phase
        param_jump InvokeDialogProc, kIndexGetSizeDialog, get_size_dialog_params
.endproc ; GetSizeDialogEnumerationCallback

.proc GetSizeDialogConfirmCallback
        copy    #GetSizeDialogLifecycle::prompt, get_size_dialog_params::phase
        param_jump InvokeDialogProc, kIndexGetSizeDialog, get_size_dialog_params
.endproc ; GetSizeDialogConfirmCallback

.proc GetSizeDialogCompleteCallback
        copy    #GetSizeDialogLifecycle::close, get_size_dialog_params::phase
        param_jump InvokeDialogProc, kIndexGetSizeDialog, get_size_dialog_params

.endproc ; GetSizeDialogCompleteCallback

;;; ============================================================
;;; Most operations start by doing a traversal to just count
;;; the files.

;;; `EnumerationProcessSelectedFile`
;;;  - if op=copy, validates; if dir, recurses; delegates to:
;;; `EnumerationProcessDirectoryEntry`
;;;  - increments file count; if op=size, sums size
;;; (finishing a directory is a no-op)

;;; Overlays for size operation (`op_jt_addrs`)
callbacks_for_size_or_count:
        .addr   EnumerationProcessSelectedFile
        .addr   EnumerationProcessDirectoryEntry
        .addr   DoNothing
        ASSERT_TABLE_SIZE callbacks_for_size_or_count, kOpJTAddrsSize

.proc PrepCallbacksForEnumeration
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
.endproc ; PrepCallbacksForEnumeration

;;; ============================================================
;;; Handle sizing (or just counting) of a selected file.
;;; Calls into the recursion logic of `ProcessDir` as necessary.

.proc EnumerationProcessSelectedFile
        ;; If copy, validate the source vs. target
        bit     operation_flags
        bmi     :+
        bit     copy_delete_flags
        bmi     :+
        jsr     CopyPathsFromBufsToSrcAndDst
        jsr     CheckRecursion
        jne     ShowErrorAlert
        jsr     AppendSrcPathLastSegmentToDstPath
        jsr     CheckBadReplacement
        jne     ShowErrorAlert
:
        jsr     CopyPathsFromBufsToSrcAndDst
@retry: jsr     GetSrcFileInfo
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry

:       copy    src_file_info_params::storage_type, storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        bne     do_sum_file_size

is_dir:
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
        ;; Make subsequent call to `AppendFileEntryToSrcPath` a no-op
        copy    #0, file_entry_buf + FileEntry::storage_type_name_length
        FALL_THROUGH_TO EnumerationProcessDirectoryEntry
.endproc ; EnumerationProcessSelectedFile

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

.proc EnumerationProcessDirectoryEntry
        ;; If operation is "get size" or "download", add the block count to the sum
        bit     operation_flags
    IF_VS
        lda     file_entry_buf + FileEntry::storage_type_name_length
      IF_NOT_ZERO
        ;; If we have a valid file entry, use its block count
        add16   op_block_count, file_entry_buf+FileEntry::blocks_used, op_block_count
      ELSE
        ;; Otherwise, query the existing path
        jsr     GetSrcFileInfo
       IF_ZERO
        add16   op_block_count, src_file_info_params::blocks_used, op_block_count
       END_IF
      END_IF
    END_IF

        inc16   op_file_count
        ldax    op_file_count
        jmp     InvokeOperationEnumerationCallback
.endproc ; EnumerationProcessDirectoryEntry

op_file_count:
        .word   0

op_block_count:
        .word   0

;;; ============================================================

.proc DecrementOpFileCount
        dec16   op_file_count
        rts
.endproc ; DecrementOpFileCount

;;; ============================================================

;;; Populate `src_file_info_params` from `file_entry_buf`

.proc ConvertFileEntryToFileInfo
        ldx     #kMapSize-1
:       ldy     map,x
        lda     file_entry_buf,y
        sta     src_file_info_params::access,x
        dex
        bpl     :-

        ;; Fix `storage_type`
        ldx     #4
:       lsr     src_file_info_params::storage_type
        dex
        bne     :-

        rts

;;; index is offset in `src_file_info_params`, value is offset in `file_entry_buf`
map:    .byte   FileEntry::access
        .byte   FileEntry::file_type
        .byte   FileEntry::aux_type
        .byte   FileEntry::aux_type+1
        .byte   FileEntry::storage_type_name_length
        .byte   FileEntry::blocks_used
        .byte   FileEntry::blocks_used+1
        .byte   FileEntry::mod_date
        .byte   FileEntry::mod_date+1
        .byte   FileEntry::mod_time
        .byte   FileEntry::mod_time+1
        .byte   FileEntry::creation_date
        .byte   FileEntry::creation_date+1
        .byte   FileEntry::creation_time
        .byte   FileEntry::creation_time+1
        kMapSize = * - map
.endproc ; ConvertFileEntryToFileInfo

;;; ============================================================
;;; Append name at `file_entry_buf` to path at `src_path_buf`

.proc AppendFileEntryToSrcPath
        ldax    #file_entry_buf
        jmp     AppendFilenameToSrcPath
.endproc ; AppendFileEntryToSrcPath

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
.endproc ; RemoveSrcPathSegment

;;; ============================================================
;;; Append name at `file_entry_buf` to path at `dst_path_buf`

.proc AppendFileEntryToDstPath
        ldax    #file_entry_buf
        jmp     AppendFilenameToDstPath
.endproc ; AppendFileEntryToDstPath

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
.endproc ; RemoveDstPathSegment

;;; ============================================================
;;; Check if `src_path_buf` is inside `dst_path_buf`.
;;; Output: A=0 if ok, A=err code otherwise.

.proc CheckRecursion
        copy16  #src_path_buf, $06
        copy16  #dst_path_buf, $08
        jsr     IsPathPrefixOf
        beq     ret
        lda     #kErrMoveCopyIntoSelf
ret:    rts
.endproc ; CheckRecursion

;;; ============================================================
;;; Check for replacing an item with itself or a descendant.
;;; Input: `src_path_buf` and `dst_path_buf` are full paths
;;; Output: A=0 if ok, A=err code otherwise.

.proc CheckBadReplacement

        ;; Examples:
        ;; src: '/a/p'   dst: '/a/p' (replace with self)
        ;; src: '/a/c/c' dst: '/a/c' (replace with item inside self)

        ;; Check for dst being subset of src

        copy16  #dst_path_buf, $06
        copy16  #src_path_buf, $08
        jsr     IsPathPrefixOf
        beq     ret
        lda     #kErrBadReplacement
ret:    rts

.endproc ; CheckBadReplacement

;;; ============================================================
;;; Check if $06 is same path or parent of $08.
;;; Returns Z=1 if not, Z=0 if it is.

.proc IsPathPrefixOf
        ptr1 := $06
        ptr2 := $08

        ldy     #0
        lda     (ptr1),y        ; Compare string lengths. If the same, need
        cmp     (ptr2),y        ; to compare strings. If `ptr1` > `ptr2`
        beq     compare         ; ('/a/b' vs. '/a'), then it's not a problem.
        bcs     ok

        ;; Assert: `ptr1` is shorter then `ptr2`
        tay                     ; See if `ptr2` is possibly a subfolder
        iny
        lda     (ptr2),y        ; ('/a/b/c' vs. '/a/b') or a sibling
        cmp     #'/'            ; ('/a/bc' vs. /a/b').
        bne     ok              ; At worst, a sibling - that's okay.

        ;; Potentially self or a subfolder; compare strings.
compare:
        ldy     #0
        lda     (ptr1),y
        tay
:       lda     (ptr1),y
        jsr     UpcaseChar
        sta     @char
        lda     (ptr2),y
        jsr     UpcaseChar
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     ok
        dey
        bne     :-

        ;; Self or subfolder
        return  #$FF

ok:     return  #0
.endproc ; IsPathPrefixOf

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
.endproc ; CopyPathsFromBufsToSrcAndDst

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
.endproc ; AppendSrcPathLastSegmentToDstPath

;;; ============================================================
;;; If Escape is pressed, abort the operation.

.proc CheckCancel
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::key_down
        bne     ret
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     CloseFilesCancelDialog
ret:    rts
.endproc ; CheckCancel

;;; ============================================================
;;; Closes dialog, closes all open files, and restores stack.

.proc CloseFilesCancelDialog
        lda     #kOperationFailed
ep2:    sta     @result

        jsr     InvokeOperationCompleteCallback

        MLI_CALL CLOSE, close_params

        ldx     stack_stash     ; restore stack, in case recursion was aborted
        txs

        @result := *+1
        lda     #SELF_MODIFIED_BYTE
        rts

        DEFINE_CLOSE_PARAMS close_params
.endproc ; CloseFilesCancelDialog
CloseFilesCancelDialogWithResult := CloseFilesCancelDialog::ep2

;;; ============================================================
;;; Move or Copy? Compare src/dst paths, same vol = move.
;;; Button down inverts the default action.
;;; Input: A,X = source path
;;; Output: A=high bit set if move, clear if copy

.proc CheckMoveOrCopy
        src_ptr := $08
        dst_buf := path_buf4

        stax    src_ptr

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
        FALL_THROUGH_TO no_match

no_match:
        flag := *+1
        lda     #SELF_MODIFIED_BYTE
        rts

match:  lda     flag
        eor     #$80
        rts
.endproc ; CheckMoveOrCopy

;;; ============================================================

.proc DecFileCountAndRunDeleteDialogProc
        sub16   op_file_count, #1, delete_dialog_params::count
        param_jump InvokeDialogProc, kIndexDeleteDialog, delete_dialog_params
.endproc ; DecFileCountAndRunDeleteDialogProc

.proc DecFileCountAndRunCopyDialogProc
        sub16   op_file_count, #1, copy_dialog_params::count
        param_jump InvokeDialogProc, kIndexCopyDialog, copy_dialog_params
.endproc ; DecFileCountAndRunCopyDialogProc

;;; ============================================================

.proc ApplyFileInfoAndSize
:       jsr     CopyFileInfo
        copy    #ACCESS_DEFAULT, dst_file_info_params::access
        jsr     SetDstFileInfo
        lda     src_file_info_params::file_type
        cmp     #FT_DIRECTORY
        beq     done

        ;; If a regular file, open/set eof/close
        MLI_CALL OPEN, open_dst_params
        beq     :+
        jsr     ShowErrorAlertDst
        jmp     :-              ; retry

:       lda     open_dst_params::ref_num
        sta     set_eof_params::ref_num
        sta     close_dst_params::ref_num
@retry: MLI_CALL SET_EOF, set_eof_params
        beq     close
        jsr     ShowErrorAlertDst
        jmp     @retry

close:  MLI_CALL CLOSE, close_dst_params
done:   rts
.endproc ; ApplyFileInfoAndSize

.proc CopyFileInfo
        COPY_BYTES 11, src_file_info_params::access, dst_file_info_params::access
        rts
.endproc ; CopyFileInfo

.proc SetDstFileInfo
:       copy    #7, dst_file_info_params::param_count ; SET_FILE_INFO
        MLI_CALL SET_FILE_INFO, dst_file_info_params
        pha
        copy    #$A, dst_file_info_params::param_count ; GET_FILE_INFO
        pla
        beq     done
        jsr     ShowErrorAlertDst
        jmp     :-

done:   rts
.endproc ; SetDstFileInfo

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
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        bne     close           ; not kAlertResultTryAgain = 0
        jsr     SetCursorWatch  ; undone by `ClosePromptDialog` or `CloseProgressDialog`
        rts

not_found:
        bit     flag
        bpl     :+
        lda     #kErrInsertDstDisk
        jmp     show

:       lda     #kErrInsertSrcDisk
show:   jsr     ShowAlert
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        bne     close           ; not kAlertResultTryAgain = 0
        jmp     do_on_line

close:  jmp     CloseFilesCancelDialog

flag:   .byte   0

do_on_line:
        jsr     SetCursorWatch  ; undone by `ClosePromptDialog` or `CloseProgressDialog`
        MLI_CALL ON_LINE, on_line_params2
        rts

.endproc ; ShowErrorAlertImpl
ShowErrorAlert  := ShowErrorAlertImpl::flag_clear
ShowErrorAlertDst       := ShowErrorAlertImpl::flag_set

;;; ============================================================

;;; Inputs: `src_path_buf` is file, `stashed_name` is new name
;;; Outputs: `new_name_buf` had "resulting" file case

.proc ApplyCaseBits
        jsr     GetSrcFileInfo
        bcs     fallback

        lda     src_file_info_params::file_type
        cmp     #FT_ADB
        beq     appleworks
        cmp     #FT_AWP
        beq     appleworks
        cmp     #FT_ASP
        beq     appleworks

        ;; TODO: Handle GS/OS case bits

        ;; --------------------------------------------------
fallback:
        ;; Since we can't preserve casing, just upcase it for now.
        ;; See: https://github.com/a2stuff/a2d/issues/352
        ldy     stashed_name
:       lda     stashed_name,y
        jsr     UpcaseChar
        sta     stashed_name,y
        dey
        bne     :-

        ;; ... then recase it, so we're consistent for icons/paths.
        ldax    #stashed_name
        jmp     AdjustFileNameCase

        ;; --------------------------------------------------
appleworks:
        ;; We can preserve case, so apply it
        ldx     #15
        clc

:       ror     src_file_info_params::aux_type
        ror     src_file_info_params::aux_type+1
        lda     stashed_name,x
        cmp     #'a'
        dex
        bpl     :-

        jmp     SetSrcFileInfo
.endproc ; ApplyCaseBits

;;; ============================================================
;;; Dialog Proc Invocation

kNumDialogTypes = 10

kIndexAboutDialog       = 0
kIndexCopyDialog        = 1
kIndexDeleteDialog      = 2
kIndexNewFolderDialog   = 3
kIndexGetInfoDialog     = 4
kIndexLockDialog        = 5
kIndexRenameDialog      = 6
kIndexDownloadDialog    = 7
kIndexGetSizeDialog     = 8
kIndexDuplicateDialog   = 9

dialog_proc_table:
        .addr   AboutDialogProc
        .addr   CopyDialogProc
        .addr   DeleteDialogProc
        .addr   NewFolderDialogProc
        .addr   GetInfoDialogProc
        .addr   LockDialogProc
        .addr   RenameDialogProc
        .addr   DownloadDialogProc
        .addr   GetSizeDialogProc
        .addr   DuplicateDialogProc
        ASSERT_ADDRESS_TABLE_SIZE dialog_proc_table, kNumDialogTypes

dialog_param_addr:
        .addr   0

.proc InvokeDialogProc
        stax    dialog_param_addr
        tya
        asl     a
        tax
        copy16  dialog_proc_table,x, @jump_addr

        @jump_addr := *+1
        jmp     SELF_MODIFIED
.endproc ; InvokeDialogProc


;;; ============================================================
;;; Message handler for OK/Cancel dialog

;;; Outputs: N=0/Z=1 if ok, N=0/Z=0 if canceled; N=1 means call again

.proc PromptInputLoop
        lda     has_input_field_flag
        beq     :+
        LETK_CALL LETK::Idle, le_params
:
        ;; Dispatch event types - mouse down, key press
        jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
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

        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        beq     PromptInputLoop

        lda     findwindow_params::window_id
        cmp     #winfo_prompt_dialog::kWindowId
        bne     PromptInputLoop

        ;; Is over this window... but where?
        copy    winfo_prompt_dialog, event_params
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, name_input_rect
        cmp     #MGTK::inrect_inside
        bne     out
        jsr     SetCursorIBeamWithFlag ; toggling in prompt dialog
        jmp     done
out:    jsr     SetCursorPointerWithFlag ; toggling in prompt dialog
done:   jmp     PromptInputLoop
.endproc ; PromptInputLoop

;;; Click handler for prompt dialog

.proc PromptClickHandler
        MGTK_CALL MGTK::FindWindow, findwindow_params
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
:       copy    winfo_prompt_dialog, event_params
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, ok_button_rec::rect
        cmp     #MGTK::inrect_inside
        beq     check_button_ok
        jmp     maybe_check_button_cancel

check_button_ok:
        bit     ok_button_rec::state
        bmi     :+
        BTK_CALL BTK::Track, ok_button_params
        bmi     :+
        lda     #PromptResult::ok
:       rts

maybe_check_button_cancel:
        bit     prompt_button_flags
        bpl     check_button_cancel
        return  #$FF

check_button_cancel:
        MGTK_CALL MGTK::InRect, cancel_button_rec::rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        BTK_CALL BTK::Track, cancel_button_params
        bmi     :+
        lda     #PromptResult::cancel
:       rts
    END_IF

        bit     has_input_field_flag
    IF_PLUS
        lda     #$FF
        jmp     jump_relay
    END_IF

        ;; Was click inside text box?
        MGTK_CALL MGTK::InRect, name_input_rect
        cmp     #MGTK::inrect_inside
        bne     :+
        COPY_STRUCT MGTK::Point, screentowindow_params::window, le_params::coords
        LETK_CALL LETK::Click, le_params
:       return  #$FF
.endproc ; PromptClickHandler

;;; Key handler for prompt dialog

.proc PromptKeyHandler
        lda     event_params::key
        sta     le_params::key

        ldx     event_params::modifiers
        stx     le_params::modifiers
    IF_NOT_ZERO
        ;; Modifiers

        bit     has_input_field_flag
      IF_NS
        LETK_CALL LETK::Key, le_params
        jsr     UpdateOKButton
      END_IF

    ELSE
        ;; No modifiers

        bit     format_erase_overlay_flag
      IF_NS
        jsr     format_erase_overlay__IsOptionPickerKey
       IF_EQ
        jsr     format_erase_overlay__HandleOptionPickerKey
        return  #$FF
       END_IF
      END_IF

        cmp     #CHAR_RETURN
        jeq     HandleKeyOK

        cmp     #CHAR_ESCAPE
      IF_EQ
        bit     prompt_button_flags
        jpl     HandleKeyCancel
        jmp     HandleKeyOK
      END_IF

        bit     has_input_field_flag
      IF_NS
        jsr     IsControlChar ; pass through control characters
        bcc     allow
        jsr     IsFilenameChar
        bcs     ignore
allow:  LETK_CALL LETK::Key, le_params
        jsr     UpdateOKButton
ignore:
      END_IF

    END_IF
        return  #$FF

        ;; --------------------------------------------------

.proc HandleKeyOK
        bit     ok_button_rec::state
        bmi     ret
        BTK_CALL BTK::Flash, ok_button_params
        lda     #PromptResult::ok
ret:    rts
.endproc ; HandleKeyOK

.proc HandleKeyCancel
        BTK_CALL BTK::Flash, cancel_button_params
        return  #PromptResult::cancel
.endproc ; HandleKeyCancel

.endproc ; PromptKeyHandler

rts1:
        rts

;;; ============================================================

;;; Input: A=character
;;; Output: C=0 if control, C=1 if not
.proc IsControlChar
        cmp     #CHAR_DELETE
        bcs     yes

        cmp     #' '
        bcc     yes
        rts                     ; C=1

yes:    clc                     ; C=0
        rts
.endproc ; IsControlChar

;;; ============================================================

;;; Input: A=character
;;; Output: C=0 if valid filename character, C=1 otherwise
.proc IsFilenameChar
        cmp     #'.'
        beq     allow_if_not_first

        cmp     #'0'
        bcc     ignore
        cmp     #'9'+1
        bcc     allow_if_not_first

        cmp     #'A'
        bcc     ignore
        cmp     #'Z'+1
        bcc     allow

        cmp     #'a'
        bcc     ignore
        cmp     #'z'+1
        bcc     allow
        bcs     ignore          ; always

allow_if_not_first:
        ldx     text_input_buf
        beq     ignore

allow:  clc
        rts

ignore: sec
        rts
.endproc ; IsFilenameChar

;;; ============================================================

jump_relay:
        jmp     SELF_MODIFIED


;;; ============================================================
;;; "About" dialog

.proc AboutDialogProc

        MGTK_CALL MGTK::OpenWindow, winfo_about_dialog
        lda     #winfo_about_dialog::kWindowId
        jsr     SafeSetPortFromWindowId
        jsr     SetPenModeNotCopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, aux::about_dialog_frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal
        jsr     SetPenModeXOR
        param_call DrawDialogTitle, aux::str_about1
        param_call DrawDialogLabel, 1 | DDL_CENTER, aux::str_about2
        param_call DrawDialogLabel, 2 | DDL_CENTER, aux::str_about3
        param_call DrawDialogLabel, 3 | DDL_CENTER, aux::str_about4
        param_call DrawDialogLabel, 5 | DDL_CENTER, aux::str_about5
        param_call DrawDialogLabel, 6 | DDL_CENTER, aux::str_about6
        param_call DrawDialogLabel, 7 | DDL_CENTER, aux::str_about7
        param_call DrawDialogLabel, 9, aux::str_about8
        param_call DrawDialogLabel, 9 | DDL_RIGHT, aux::str_about9

:       jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     close
        cmp     #MGTK::EventKind::key_down
        bne     :-

close:  MGTK_CALL MGTK::CloseWindow, winfo_about_dialog
        jmp     ClearUpdates ; following CloseWindow
.endproc ; AboutDialogProc

;;; ============================================================

.proc CopyDialogProc
        ptr := $6

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::phase - copy_dialog_params
        lda     (ptr),y         ; `CopyDialogLifecycle`

        ;; --------------------------------------------------
        cmp     #CopyDialogLifecycle::open
    IF_EQ
        copy    #0, has_input_field_flag
        jmp     OpenProgressDialog
    END_IF

        ;; --------------------------------------------------
        cmp     #CopyDialogLifecycle::count
    IF_EQ
        ldy     #copy_dialog_params::count - copy_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForProgressDialog
        bit     move_flag
      IF_NC
        param_call DrawProgressDialogLabel, 0, aux::str_copy_copying
      ELSE
        param_call DrawProgressDialogLabel, 0, aux::str_move_moving
      END_IF
        jmp     DrawFileCountWithSuffix
    END_IF

        ;; --------------------------------------------------
        cmp     #CopyDialogLifecycle::show
    IF_EQ
        ldy     #copy_dialog_params::count - copy_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForProgressDialog

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::a_src - copy_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyPtr1ToBuf0
        param_call DrawProgressDialogLabel, 1, aux::str_copy_from
        jsr     ClearTargetFileRectAndSetPos
        jsr     DrawDialogPathBuf0

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::a_dst - copy_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyPtr1ToBuf0
        param_call DrawProgressDialogLabel, 2, aux::str_copy_to
        jsr     ClearDestFileRectAndSetPos
        jsr     DrawDialogPathBuf0

        jmp     DrawProgressDialogFilesRemaining
    END_IF

        ;; --------------------------------------------------
        ;; CopyDialogLifecycle::close
        jmp     CloseProgressDialog
.endproc ; CopyDialogProc

;;; ============================================================
;;; "DownLoad" dialog

DownloadDialogProc := CopyDialogProc

;;; ============================================================
;;; "Get Size" dialog

.proc GetSizeDialogProc
        ptr := $6

        jsr     CopyDialogParamAddrToPtr
        ldy     #get_size_dialog_params::phase - get_size_dialog_params
        lda     (ptr),y

        ;; --------------------------------------------------
        cmp     #GetSizeDialogLifecycle::open
    IF_EQ
        jsr     OpenDialogWindow
        jsr     SetCursorWatch  ; until `...::prompt` or on close
        param_call DrawDialogTitle, aux::label_get_size
        param_call DrawDialogLabel, 1 | DDL_LRIGHT, aux::str_size_number
        param_jump DrawDialogLabel, 2 | DDL_LRIGHT, aux::str_size_blocks
    END_IF

        ;; --------------------------------------------------
        cmp     #GetSizeDialogLifecycle::count
    IF_EQ
GetSizeDialogProc::do_count := *
        ;; File Count
        ldy     #get_size_dialog_params::a_files - get_size_dialog_params
        jsr     DereferencePtrToAddr
        copy16in (ptr),y, file_count
        jsr     ComposeFileCountString
        jsr     SetPortForDialogWindow
        param_call DrawDialogLabel, 1 | DDL_VALUE, str_file_count

        ;; Size
        jsr     CopyDialogParamAddrToPtr
        ldy     #get_size_dialog_params::a_blocks - get_size_dialog_params
        jsr     DereferencePtrToAddr
        copy16in (ptr),y, file_count

        ldax    file_count
        jsr     ComposeSizeString
        param_jump DrawDialogLabel, 2 | DDL_VALUE, text_buffer2
    END_IF

        ;; --------------------------------------------------
        cmp     #GetSizeDialogLifecycle::prompt
    IF_EQ
        ;; If no files were seen, `do_count` was never executed and so the
        ;; counts will not be shown. Update one last time, just in case.
        jsr     do_count

        jsr     SetPortForDialogWindow
        jsr     AddOKButton
        jsr     SetCursorPointer ; set in `...::open`
:       jsr     PromptInputLoop
        bmi     :-
        return  #0
    END_IF

        ;; --------------------------------------------------
        ;; GetSizeDialogLifecycle::close
        jmp     ClosePromptDialog
.endproc ; GetSizeDialogProc

;;; ============================================================
;;; "Delete File" dialog

.proc DeleteDialogProc
        ptr := $06

        jsr     CopyDialogParamAddrToPtr
        ldy     #delete_dialog_params::phase - delete_dialog_params
        lda     (ptr),y         ; `DeleteDialogLifecycle`

        ;; --------------------------------------------------
        cmp     #DeleteDialogLifecycle::open
    IF_EQ
        copy    #0, has_input_field_flag
        jmp     OpenProgressDialog
    END_IF

        ;; --------------------------------------------------
        cmp     #DeleteDialogLifecycle::count
    IF_EQ
        ldy     #delete_dialog_params::count - delete_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForProgressDialog
        param_call DrawProgressDialogLabel, 0, aux::str_delete_count
        jmp     DrawFileCountWithSuffix
    END_IF

        ;; --------------------------------------------------
        cmp     #DeleteDialogLifecycle::show
    IF_EQ
        ldy     #delete_dialog_params::count - delete_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForProgressDialog

        jsr     CopyDialogParamAddrToPtr
        ldy     #delete_dialog_params::a_path - delete_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyPtr1ToBuf0
        param_call DrawProgressDialogLabel, 1, aux::str_file_colon
        jsr     ClearTargetFileRectAndSetPos
        jsr     DrawDialogPathBuf0

        jmp     DrawProgressDialogFilesRemaining
    END_IF

        ;; --------------------------------------------------
        ;; DeleteDialogLifecycle::close
        jmp     CloseProgressDialog
.endproc ; DeleteDialogProc

;;; ============================================================
;;; "New Folder" dialog

.proc NewFolderDialogProc

        jsr     CopyDialogParamAddrToPtr
        ldy     #new_folder_dialog_params::phase - new_folder_dialog_params
        lda     ($06),y

        ;; --------------------------------------------------
        cmp     #NewFolderDialogState::open
    IF_EQ
        copy    #$80, has_input_field_flag
        lda     #$00
        jsr     OpenPromptWindow
        jsr     SetPortForDialogWindow
        param_jump DrawDialogTitle, aux::label_new_folder
    END_IF

        ;; --------------------------------------------------
        cmp     #NewFolderDialogState::run
        jne     not_run

        copy    #$80, has_input_field_flag
        copy    #0, prompt_button_flags
        jsr     CopyDialogParamAddrToPtr
        ldy     #new_folder_dialog_params::a_path - new_folder_dialog_params
        copy16in ($06),y, $08
        param_call CopyPtr2ToBuf, path_buf0
        param_call CopyPtr2ToBuf, path_buf4
        jsr     SplitPathBuf4
        COPY_STRING filename_buf, buf_filename ; for display

        jsr     SetPortForDialogWindow
        param_call DrawDialogLabel, 2, aux::str_in
        param_call DrawString, buf_filename
        param_call DrawDialogLabel, 4, aux::str_enter_folder_name
        jsr     InitNameInput

loop:   jsr     PromptInputLoop
        bmi     loop
        bne     do_close

        lda     path_buf0       ; full path okay?
        clc
        adc     text_input_buf
        cmp     #::kMaxPathLength ; not +1 because we'll add '/'
        bcs     too_long

        inc     path_buf0
        ldx     path_buf0
        copy    #'/', path_buf0,x
        ldx     path_buf0
        ldy     #0
:       inx
        iny
        copy    text_input_buf,y, path_buf0,x
        cpy     text_input_buf
        bne     :-
        stx     path_buf0
        ldy     #<path_buf0
        ldx     #>path_buf0
        return  #0

too_long:
        lda     #kErrNameTooLong
        jsr     ShowAlert
        jmp     loop

not_run:

        ;; --------------------------------------------------
        ;; NewFolderDialogState::close
do_close:
        jsr     ClosePromptDialog
        return  #1
.endproc ; NewFolderDialogProc

;;; ============================================================
;;; "Get Info" dialog

.proc GetInfoDialogProc
        ptr := $6

        jsr     CopyDialogParamAddrToPtr
        ldy     #get_info_dialog_params::state - get_info_dialog_params
        lda     (ptr),y

        ;; --------------------------------------------------
        ;; GetInfoDialogState::prepare_*
    IF_NS
        ;; Draw the field labels (e.g. "Size:")
        copy    #0, has_input_field_flag
        ;; ldy     #get_info_dialog_params::state - get_info_dialog_params
        lda     (ptr),y
        pha
        lsr     a               ; bit 1 set if multiple
        lsr     a               ; so configure buttons appropriately
        ror     a
        eor     #$80
        jsr     OpenPromptWindow
        jsr     SetPortForDialogWindow

        param_call DrawDialogTitle, aux::label_get_info
        pla                     ; A = get_info_dialog_params::state
        pha                     ; bit 0 set if volume

        ;; Draw labels
        param_call DrawDialogLabel, 1 | DDL_LRIGHT, aux::str_info_name
        param_call DrawDialogLabel, 2 | DDL_LRIGHT, aux::str_info_type
        param_call DrawDialogLabel, 4 | DDL_LRIGHT, aux::str_info_create
        param_call DrawDialogLabel, 5 | DDL_LRIGHT, aux::str_info_mod

        pla                     ; bit 0 set if volume
        and     #$01
      IF_NOT_ZERO
        param_call DrawDialogLabel, 3 | DDL_LRIGHT, aux::str_info_vol_size
        param_jump DrawDialogLabel, 6 | DDL_LRIGHT, aux::str_info_protected
      ELSE
        param_call DrawDialogLabel, 3 | DDL_LRIGHT, aux::str_info_file_size
        param_jump DrawDialogLabel, 6 | DDL_LRIGHT, aux::str_info_locked
      END_IF
    END_IF

        ;; --------------------------------------------------
        ;; GetInfoDialogState::* (name, type, etc)
        ;; Draw a specific value

        cmp     #GetInfoDialogState::prompt
    IF_NE
        jsr     SetPortForDialogWindow
        jsr     CopyDialogParamAddrToPtr
        ldy     #get_info_dialog_params::state - get_info_dialog_params
        lda     (ptr),y
        ora     #DDL_VALUE
        sta     row

        ;; Draw the string at `get_info_dialog_params::a_str`
        jsr     CopyDialogParamAddrToPtr
        ldy     #get_info_dialog_params::a_str - get_info_dialog_params + 1
        lda     (ptr),y
        tax
        dey
        lda     (ptr),y
        row := *+1
        ldy     #SELF_MODIFIED_BYTE
        jmp     DrawDialogLabel
    END_IF

        ;; --------------------------------------------------
        ;; GetInfoDialogState::prompt
:       jsr     PromptInputLoop
        bmi     :-

        pha
        jsr     ClosePromptDialog
        pla
        rts
.endproc ; GetInfoDialogProc

;;; ============================================================
;;; "Lock"/"Unlock" dialog

.proc LockDialogProc
        ptr := $06

        jsr     CopyDialogParamAddrToPtr
        ldy     #lock_unlock_dialog_params::phase - lock_unlock_dialog_params
        lda     (ptr),y         ; `LockDialogLifecycle`

        ;; --------------------------------------------------
        cmp     #LockDialogLifecycle::open
    IF_EQ
        copy    #0, has_input_field_flag
        jmp     OpenProgressDialog
    END_IF

        ;; --------------------------------------------------
        cmp     #LockDialogLifecycle::count
    IF_EQ
        ldy     #lock_unlock_dialog_params::count - lock_unlock_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForProgressDialog
        bit     unlock_flag
      IF_NS
        param_call DrawProgressDialogLabel, 0, aux::str_unlock_count
      ELSE
        param_call DrawProgressDialogLabel, 0, aux::str_lock_count
      END_IF
        jmp     DrawFileCountWithSuffix
    END_IF

        ;; --------------------------------------------------
        cmp     #LockDialogLifecycle::show
    IF_EQ
        ldy     #lock_unlock_dialog_params::count - lock_unlock_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForProgressDialog
        jsr     CopyDialogParamAddrToPtr
        ldy     #lock_unlock_dialog_params::a_path - lock_unlock_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyPtr1ToBuf0
        param_call DrawProgressDialogLabel, 1, aux::str_file_colon
        jsr     ClearTargetFileRectAndSetPos
        jsr     DrawDialogPathBuf0

        jmp     DrawProgressDialogFilesRemaining
    END_IF

        ;; --------------------------------------------------
        ;; LockDialogLifecycle::close
        jmp     CloseProgressDialog
.endproc ; LockDialogProc

;;; ============================================================
;;; "Rename" dialog

.proc RenameDialogProc
        params_ptr := $06

        jsr     CopyDialogParamAddrToPtr
        ldy     #rename_dialog_params::state - rename_dialog_params
        lda     (params_ptr),y

        ;; ----------------------------------------
        cmp     #RenameDialogState::open
    IF_EQ
        copy    #$80, has_input_field_flag
        lda     #$00
        jsr     OpenPromptWindow
        jsr     SetPortForDialogWindow
        param_call DrawDialogTitle, aux::label_rename_icon
        jsr     CopyDialogParamAddrToPtr
        ldy     #rename_dialog_params::a_path - rename_dialog_params
        copy16in (params_ptr),y, $08
        param_call CopyPtr2ToBuf, text_input_buf
        param_call DrawDialogLabel, 2, aux::str_rename_old
        param_call DrawString, text_input_buf
        param_call DrawDialogLabel, 4, aux::str_rename_new
        jmp     InitNameInput
    END_IF

        ;; --------------------------------------------------
        cmp     #RenameDialogState::run
    IF_EQ
        copy    #$00, prompt_button_flags
        copy    #$80, has_input_field_flag
:       jsr     PromptInputLoop
        bmi     :-              ; continue?

        bne     do_close        ; canceled!

        ldy     #<text_input_buf
        ldx     #>text_input_buf
        return  #0
    END_IF

        ;; --------------------------------------------------
        ;; RenameDialogState::close
do_close:
        jsr     ClosePromptDialog
        return  #1
.endproc ; RenameDialogProc

;;; ============================================================
;;; "Duplicate" dialog

.proc DuplicateDialogProc
        params_ptr := $06

        jsr     CopyDialogParamAddrToPtr
        ldy     #duplicate_dialog_params::state - duplicate_dialog_params
        lda     (params_ptr),y

        ;; --------------------------------------------------
        cmp     #DuplicateDialogState::open
    IF_EQ
        copy    #$80, has_input_field_flag
        lda     #$00
        jsr     OpenPromptWindow
        jsr     SetPortForDialogWindow
        param_call DrawDialogTitle, aux::label_duplicate_icon
        jsr     CopyDialogParamAddrToPtr
        ldy     #duplicate_dialog_params::a_path - duplicate_dialog_params
        copy16in (params_ptr),y, $08
        param_call CopyPtr2ToBuf, text_input_buf
        param_call DrawDialogLabel, 2, aux::str_duplicate_original
        param_call DrawString, text_input_buf
        param_call DrawDialogLabel, 4, aux::str_rename_new
        jmp     InitNameInput
    END_IF

        ;; --------------------------------------------------
        cmp     #DuplicateDialogState::run
    IF_EQ
        copy    #$00, prompt_button_flags
        copy    #$80, has_input_field_flag
:       jsr     PromptInputLoop
        bmi     :-              ; continue?

        bne     do_close        ; canceled!

        ldy     #<text_input_buf
        ldx     #>text_input_buf
        return  #0
    END_IF

        ;; --------------------------------------------------
        ;; DuplicateDialogState::close
do_close:
        jsr     ClosePromptDialog
        return  #1
.endproc ; DuplicateDialogProc

;;; ============================================================

.proc CopyDialogParamAddrToPtr
        copy16  dialog_param_addr, $06
        rts
.endproc ; CopyDialogParamAddrToPtr

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
.endproc ; DereferencePtrToAddr

;;; ============================================================

;;; `file_count` must be populated
.proc DrawFileCountWithSuffix
        jsr     ComposeFileCountString
        param_call DrawString, str_file_count
        param_jump_indirect DrawString, ptr_str_files_suffix
.endproc ; DrawFileCountWithSuffix

;;; `file_count` must be populated
.proc DrawProgressDialogFilesRemaining
        MGTK_CALL MGTK::MoveTo, progress_dialog_remaining_pos
        param_call DrawString, aux::str_files_remaining

        jsr     ComposeFileCountString
        param_call DrawString, str_file_count
        param_jump DrawString, str_2_spaces
.endproc ; DrawProgressDialogFilesRemaining

;;; ============================================================

.proc SetCursorPointerWithFlag
        bit     cursor_ibeam_flag
        bpl     :+
        jsr     SetCursorPointer ; toggle routine
        copy    #0, cursor_ibeam_flag
:       rts
.endproc ; SetCursorPointerWithFlag

.proc SetCursorIBeamWithFlag
        bit     cursor_ibeam_flag
        bmi     :+
        jsr     SetCursorIBeam ; toggle routine
        copy    #$80, cursor_ibeam_flag
:       rts
.endproc ; SetCursorIBeamWithFlag

cursor_ibeam_flag:          ; high bit set if I-beam, clear if pointer
        .byte   0

;;; ============================================================
;;;
;;; Routines beyond this point are used by overlays
;;;
;;; ============================================================

        .assert * >= $A000, error, "Routine used by overlays in overlay zone"

;;; ============================================================

mli_relay_checkevents_flag:
        .byte   0

.proc MLIRelayImpl
        params_src := $7E

        ;; Since this is likely to be I/O bound, process events
        ;; so the mouse stays responsive.
        bit     mli_relay_checkevents_flag
        bpl     :+
        MGTK_CALL MGTK::CheckEvents
:
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
.endproc ; MLIRelayImpl

;;; ============================================================

;;; Preserves A
        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc SetCursorWatch
        pha
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        pla
        rts
.endproc ; SetCursorWatch

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc SetCursorPointer
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts
.endproc ; SetCursorPointer

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc SetCursorIBeam
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::ibeam
        rts
.endproc ; SetCursorIBeam

;;; ============================================================
;;; Double Click Detection
;;; Returns with A=0 if double click, A=$FF otherwise.

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc StashCoordsAndDetectDoubleClick
        ;; Stash coords for double-click in windows
        COPY_STRUCT MGTK::Point, event_params::coords, drag_drop_params::coords

        jmp     DetectDoubleClick
.endproc ; StashCoordsAndDetectDoubleClick

;;; ============================================================

;;; Inputs: A = new `prompt_button_flags` value

.proc OpenPromptWindow
        sta     prompt_button_flags

        copy    #0, text_input_buf

        jsr     OpenDialogWindow
        jsr     DrawOKButton
        bit     prompt_button_flags
        bmi     done
        jsr     DrawCancelButton
done:   rts
.endproc ; OpenPromptWindow

;;; ============================================================

.proc OpenDialogWindow
        copy    #0, ok_button_rec::state

        lda     #0
        sta     has_input_field_flag
        sta     format_erase_overlay_flag
        sta     cursor_ibeam_flag
        jsr     SetCursorPointer

        copy16  #rts1, jump_relay+1

        MGTK_CALL MGTK::OpenWindow, winfo_prompt_dialog
        jsr     SetPortForDialogWindow
        jsr     SetPenModeNotCopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, aux::prompt_dialog_frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal
        MGTK_CALL MGTK::SetPenMode, penXOR
        rts
.endproc ; OpenDialogWindow

;;; ============================================================

.proc SetPortForDialogWindow
        lda     #winfo_prompt_dialog::kWindowId
        jmp     SafeSetPortFromWindowId
.endproc ; SetPortForDialogWindow

;;; ============================================================

.proc OpenProgressDialog
        MGTK_CALL MGTK::OpenWindow, winfo_progress_dialog
        jsr     SetPortForProgressDialog
        jsr     SetPenModeNotCopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, aux::progress_dialog_frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal
        MGTK_CALL MGTK::SetPenMode, penXOR
        jmp     SetCursorWatch  ; undone by `CloseProgressDialog`
.endproc ; OpenProgressDialog

;;; ============================================================

.proc SetPortForProgressDialog
        lda     #winfo_progress_dialog::kWindowId
        jmp     SafeSetPortFromWindowId
.endproc ; SetPortForProgressDialog

;;; ============================================================

.proc CloseProgressDialog
        MGTK_CALL MGTK::CloseWindow, winfo_progress_dialog::window_id
        jsr     ClearUpdates     ; following CloseWindow
        jmp     SetCursorPointer ; when closing dialog
.endproc ; CloseProgressDialog

;;; ============================================================

;;; Draw dialog label.
;;; A,X has pointer to DrawText params block
;;; Y has row number (1, 2, ... ) in low nibble, alignment in top nibble

        DDL_LEFT   = $00      ; Left aligned relative to `kDialogLabelDefaultX`
        DDL_VALUE  = $10      ; Left aligned relative to `kDialogValueLeft`
        DDL_CENTER = $20      ; centered within dialog
        DDL_RIGHT  = $30      ; Right aligned
        DDL_LRIGHT = $40      ; Right aligned relative to `kDialogLabelRightX`

.proc DrawDialogLabel
        textwidth_params := $8
        textptr := $8
        textlen := $A
        result  := $B

        ptr := $6

        stx     ptr+1
        sta     ptr
        tya
        and     #%00001111
        sta     row
        tya
        and     #%11110000      ; A = flags
        beq     calc_y          ; DDL_LEFT

        cmp     #DDL_VALUE
    IF_EQ
        copy16  #kDialogValueLeft, dialog_label_pos::xcoord
        jmp     calc_y
    END_IF

        ;; Compute text width
        pha                     ; A = flags
        add16_8 ptr, #1, textptr
        ldax    ptr
        jsr     AuxLoad
        sta     textlen
        MGTK_CALL MGTK::TextWidth, textwidth_params
        pla                     ; A = flags

        cmp     #DDL_CENTER
     IF_EQ
        sub16   #kPromptDialogWidth, result, dialog_label_pos::xcoord
        lsr16   dialog_label_pos::xcoord
        jmp     calc_y
     END_IF

        cmp     #DDL_RIGHT
     IF_EQ
        sub16   #kPromptDialogWidth - kDialogLabelDefaultX, result, dialog_label_pos::xcoord
     ELSE
        ;; DDL_LRIGHT
        sub16   #kDialogLabelRightX, result, dialog_label_pos::xcoord
     END_IF

calc_y:
        ;; y = base + aux::kDialogLabelHeight * line
        row := *+1
        lda     #SELF_MODIFIED_BYTE ; low byte
        ldx     #0                  ; high byte
        ldy     #aux::kDialogLabelHeight
        jsr     Multiply_16_8_16
        addax   dialog_label_base_pos::ycoord, dialog_label_pos::ycoord
        MGTK_CALL MGTK::MoveTo, dialog_label_pos
        param_call_indirect DrawString, ptr

        ;; Restore default X position
        copy16  #kDialogLabelDefaultX, dialog_label_pos::xcoord
        rts
.endproc ; DrawDialogLabel

;;; ============================================================
;;; Draw Progress Dialog Label
;;; A,X = string
;;; Y = row number (0, 1, 2, ... )

.proc DrawProgressDialogLabel
        pha
        txa
        pha

        ;; y = base + aux::kDialogLabelHeight * line
        tya                     ; low byte
        ldx     #0              ; high byte
        ldy     #aux::kDialogLabelHeight
        jsr     Multiply_16_8_16
        addax   #kProgressDialogLabelBaseY, progress_dialog_label_pos::ycoord
        MGTK_CALL MGTK::MoveTo, progress_dialog_label_pos

        pla
        tax
        pla
        jmp     DrawString
.endproc ; DrawProgressDialogLabel

;;; ============================================================

.proc DrawDialogPathBuf0
        ldax    #path_buf0
        FALL_THROUGH_TO DrawDialogPath
.endproc ; DrawDialogPathBuf0

;;; Draw a path (long string) in the progress dialog by without intruding
;;; into the border. If the string is too long, it is shrunk from the
;;; center with "..." inserted.
;;; Inputs: A,X = string address
;;; Trashes $06...$0C
.proc DrawDialogPath
        ptr := $6
        stax    ptr

loop:   jsr     measure
        bcc     draw            ; already short enough

        jsr     ellipsify
        jmp     loop

        ;; Draw
draw:   MGTK_CALL MGTK::DrawText, txt
        rts

        ;; Measure
measure:
        txt := $8
        len := $A
        result := $B

        ldy     #0
        lda     (ptr),y
        sta     len
        add16   ptr, #1, txt
        MGTK_CALL MGTK::TextWidth, txt
        cmp16   result, #kProgressDialogPathWidth
        rts

ellipsify:
        ldy     #0
        lda     (ptr),y         ; length
        sta     length
        pha
        sec                     ; shrink length by one
        sbc     #1
        sta     (ptr),y
        pla
        lsr                     ; /= 2

        pha                     ; A = length/2

        tay
:       iny                     ; shift chars from midpoint to
        lda     (ptr),y         ; end of string down by one
        dey
        sta     (ptr),y
        iny
        length := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     :-

        pla                     ; A = length/2

        tay                     ; overwrite midpoint with
        lda     #'.'            ; "..."
        sta     (ptr),y
        iny
        sta     (ptr),y
        iny
        sta     (ptr),y
        rts
.endproc ; DrawDialogPath

;;; ============================================================

.proc DrawOKButton
        BTK_CALL BTK::Draw, ok_button_params
        rts
.endproc ; DrawOKButton

.proc UpdateOKButton
        bit     format_erase_overlay_flag
    IF_NS
        lda     #0
        jsr     format_erase_overlay__ValidSelection ; preserves A
        bpl     set_state
        lda     #$80
        bne     set_state       ; always
    END_IF

        bit     has_input_field_flag
        bpl     ret

        lda     #0
        ldx     text_input_buf
        bne     :+
        lda     #$80
:

set_state:
        cmp     ok_button_rec::state
        beq     ret
        sta     ok_button_rec::state
        BTK_CALL BTK::Hilite, ok_button_params

ret:    rts
.endproc ; UpdateOKButton

.proc DrawCancelButton
        BTK_CALL BTK::Draw, cancel_button_params
        rts
.endproc ; DrawCancelButton

.proc AddOKButton
        jsr     DrawOKButton
        copy    #$80, prompt_button_flags
        rts
.endproc ; AddOKButton

.proc EraseOKCancelButtons
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, ok_button_rec::rect
        MGTK_CALL MGTK::PaintRect, cancel_button_rec::rect
        rts
.endproc ; EraseOKCancelButtons

;;; ============================================================
;;; Draw text, pascal string address in A,X
;;; String must be in aux or LC memory.

.proc DrawString
        params := $6
        textptr := $6
        textlen := $8

        stax    textptr
        jsr     AuxLoad
        beq     done
        sta     textlen
        inc16   textptr
        MGTK_CALL MGTK::DrawText, params
done:   rts
.endproc ; DrawString

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
        MGTK_CALL MGTK::TextWidth, text_params

        sub16   #kPromptDialogWidth, text_width, pos_dialog_title::xcoord
        lsr16   pos_dialog_title::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, pos_dialog_title
        MGTK_CALL MGTK::DrawText, text_params
        rts
.endproc ; DrawDialogTitle


;;; ============================================================

.proc NoOp
        rts
.endproc ; NoOp

;;; ============================================================
;;; Frames and initializes the line edit control in the prompt
;;; dialog. Call after `text_input_buf` is populated so IP is set
;;; correctly.

.proc InitNameInput
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, name_input_rect
        LETK_CALL LETK::Init, le_params
        LETK_CALL LETK::Activate, le_params
        jmp     UpdateOKButton
.endproc ; InitNameInput

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

        ldy     #0
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
.endproc ; ComposeFileCountString

;;; ============================================================

.proc CopyPtr1ToBuf0
        param_jump CopyPtr1ToBuf, path_buf0
.endproc ; CopyPtr1ToBuf0

;;; ============================================================

.proc ClearTargetFileRectAndSetPos
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, aux::current_target_file_rect
        MGTK_CALL MGTK::MoveTo,  aux::current_target_file_pos
        rts
.endproc ; ClearTargetFileRectAndSetPos

.proc ClearDestFileRectAndSetPos
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, aux::current_dest_file_rect
        MGTK_CALL MGTK::MoveTo,  aux::current_dest_file_pos
        rts
.endproc ; ClearDestFileRectAndSetPos

;;; ============================================================

.proc GetEvent
        MGTK_CALL MGTK::GetEvent, event_params
        rts
.endproc ; GetEvent

.proc PeekEvent
        MGTK_CALL MGTK::PeekEvent, event_params
        rts
.endproc ; PeekEvent

.proc SetPenModeXOR
        MGTK_CALL MGTK::SetPenMode, penXOR
        rts
.endproc ; SetPenModeXOR

.proc SetPenModeCopy
        MGTK_CALL MGTK::SetPenMode, pencopy
        rts
.endproc ; SetPenModeCopy

.proc SetPenModeNotCopy
        MGTK_CALL MGTK::SetPenMode, notpencopy
        rts
.endproc ; SetPenModeNotCopy

;;; ============================================================

.proc InitSetDesktopPort
        MGTK_CALL MGTK::InitPort, desktop_grafport
        MGTK_CALL MGTK::SetPort, desktop_grafport
        rts
.endproc ; InitSetDesktopPort

;;; ============================================================

.proc ClosePromptDialog
        MGTK_CALL MGTK::CloseWindow, winfo_prompt_dialog
        jsr     ClearUpdates     ; following CloseWindow
        jmp     SetCursorPointer ; when closing dialog
.endproc ; ClosePromptDialog

;;; ============================================================
;;; Output: A = number of selected icons

.proc GetSelectionCount
        lda     selected_icon_count
        rts
.endproc ; GetSelectionCount

;;; ============================================================
;;; Input: A = index in selection
;;; Output: A,X = IconEntry address

.proc GetSelectedIcon
        tax
        lda     selected_icon_list,x
        jmp     GetIconEntry
.endproc ; GetSelectedIcon

;;; ============================================================
;;; Output: A = window with selection, 0 if desktop

.proc GetSelectionWindow
        lda     selected_window_id
        rts
.endproc ; GetSelectionWindow

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
.endproc ; IsIconSelected

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
.endproc ; FindIndexInFilerecordListEntries

;;; Input: A = window_id
;;; Output: A,X = address of FileRecord list (first entry is length)
;;; Assert: Window is found in list.
.proc GetFileRecordListForWindow
        jsr     FindIndexInFilerecordListEntries
        txa
        asl
        tax
        lda     window_filerecord_table,x
        pha
        lda     window_filerecord_table+1,x
        tax
        pla
        rts
.endproc ; GetFileRecordListForWindow

;;; ============================================================
;;; Outputs: A = kViewBy* value for active window, X = window id
;;; If kViewByIcon, Z=1 and N=0; otherwise Z=0 and N=1

;;; Assert: There is an active window
.proc GetActiveWindowViewBy
        ldx     active_window_id
        lda     win_view_by_table-1,x
        rts
.endproc ; GetActiveWindowViewBy

;;; Assert: There is a cached window
.proc GetCachedWindowViewBy
        ldx     cached_window_id
        lda     win_view_by_table-1,x
        rts
.endproc ; GetCachedWindowViewBy

;;; Assert: There is a selection.
;;; NOTE: This variant works even if selection is on desktop
.proc GetSelectionViewBy
        ldx     selected_window_id
        lda     win_view_by_table-1,x
        rts
.endproc ; GetSelectionViewBy

;;; ============================================================

.proc ToggleMenuHilite
        lda     menu_click_params::menu_id
        beq     :+
        MGTK_CALL MGTK::HiliteMenu, menu_click_params
:       rts
.endproc ; ToggleMenuHilite

;;; ============================================================
;;; Determine if mouse moved (returns w/ carry set if moved)
;;; Used in dialogs to possibly change cursor

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
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

.endproc ; CheckMouseMoved

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
        PASCAL_STRING kPathnameDeskTopState

.proc Save
        data_ptr := $06
        winfo_ptr := $08

        ;; Write file format version byte
        copy    #kDeskTopFileVersion, desktop_file_data_buf

        copy16  #desktop_file_data_buf+1, data_ptr

        ;; Get first window pointer
        MGTK_CALL MGTK::FrontWindow, window_id
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

        ;; * Can't use `src_path_buf`, that's holding external path to invoke
        ;; * Can't use `dst_path_buf`, that's inside `IO_BUFFER`
        param_call CopyDeskTopOriginalPrefix, tmp_path_buf

        ;; Append '/'
        ldy     tmp_path_buf
        iny
        lda     #'/'
        sta     tmp_path_buf,y

        ;; Append filename
        ldx     #0
:       inx
        iny
        copy    str_desktop_file,x, tmp_path_buf,y
        cpx     str_desktop_file
        bne     :-
        sty     tmp_path_buf

        ;; Write the file
        lda     #<tmp_path_buf
        sta     create_params::pathname
        sta     open_params::pathname
        lda     #>tmp_path_buf
        sta     create_params::pathname+1
        sta     open_params::pathname+1
        jsr     WriteOutFile

exit:   rts

.proc WriteWindowInfo
        path_ptr := $0A

        ;; Find name
        ldy     #MGTK::Winfo::window_id
        lda     (winfo_ptr),y
        pha                     ; A = window_id
        jsr     GetWindowPath
        stax    path_ptr

        ;; Copy path in
        .assert DeskTopFileItem::window_path = 0, error, "struct layout"
        ldy     #::kPathBufferSize-1
:       lda     (path_ptr),y
        sta     (data_ptr),y
        dey
        bpl     :-

        ;; Copy view_by in
        pla                     ; A = window_id
        tax
        lda     win_view_by_table-1,x
        ldy     #DeskTopFileItem::view_by
        sta     (data_ptr),y

        ;; Location - copy to `new_window_viewloc` as a temp location, then into data
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + .sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     (winfo_ptr),y
        sta     new_window_viewloc,x
        dey
        dex
        bpl     :-
        ldy     #DeskTopFileItem::viewloc+.sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     new_window_viewloc,x
        sta     (data_ptr),y
        dey
        dex
        bpl     :-

        ;; Bounds - copy to `new_window_maprect` as a temp location, then into data
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     (winfo_ptr),y
        sta     new_window_maprect,x
        dey
        dex
        bpl     :-
        ldy     #DeskTopFileItem::maprect+.sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     new_window_maprect,x
        sta     (data_ptr),y
        dey
        dex
        bpl     :-

        ;; Offset to next entry
        add16_8 data_ptr, #.sizeof(DeskTopFileItem)
        rts

.endproc ; WriteWindowInfo

window_id := findwindow_params::window_id

.endproc ; Save

.proc Open
        MLI_CALL OPEN, open_params
        rts
.endproc ; Open

.proc Close
        MLI_CALL CLOSE, close_params
        rts
.endproc ; Close

.proc WriteOutFile
        MLI_CALL CREATE, create_params
        jsr     Open
        bcs     :+
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_CALL WRITE, write_params
        jsr     Close
:       rts
.endproc ; WriteOutFile

.endscope ; save_restore_windows
SaveWindows := save_restore_windows::Save

;;; ============================================================

;;; Test if either modifier (Open-Apple or Solid-Apple) is down.
;;; Output: A=high bit/N flag set if either is down.

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc ModifierDown
        lda     BUTN0
        ora     BUTN1
        rts
.endproc ; ModifierDown

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
.endproc ; ExtendSelectionModifierDown

;;; Test if shift is down (if it can be detected).
;;; Output: A=high bit/N flag set if down.

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc ShiftDown
        bit     machine_config::iigs_flag
        bpl     TestShiftMod    ; no, rely on shift key mod

        lda     KEYMODREG       ; On IIgs, use register instead
        and     #%00000001      ; bit 7 = Command (OA), bit 0 = Shift
        beq     ret
        lda     #$80
ret:    rts
.endproc ; ShiftDown

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
.endproc ; TestShiftMod

;;; ============================================================
;;; Window Entry Tables
;;; ============================================================


;;; Input: A = window_id (0=desktop)
.proc LoadWindowEntryTable
        sta     cached_window_id

        ;; Load count & entries
        tax
        lda     window_entry_count_table,x
        sta     cached_window_entry_count
        beq     done_load       ; no entries, done
        sta     count

        lda     window_entry_offset_table,x
        tax                     ; X = offset in table
        ldy     #0              ; Y = index in win
:       lda     window_entry_table,x
        sta     cached_window_entry_list,y
        inx
        iny
        count := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     :-
done_load:

        rts
.endproc ; LoadWindowEntryTable

;;; Assert: `cached_window_id` and `icon_count` is up-to-date
.proc StoreWindowEntryTable
        lda     cached_window_id
        cmp     #kMaxDeskTopWindows ; last window?
        beq     done_shift       ; yes, no need to shift

        ;; Compute delta to shift up (or down)
        tax                     ; X = window_id
        lda     cached_window_entry_count
        sec
        sbc     window_entry_count_table,x ; A = amount to shift up (may be <0)
        beq     done_shift
        sta     delta

        ;; Offset entries by delta
        bmi     shift_down

        ;; Shift up
        inx                     ; X = next window_id
        lda     window_entry_offset_table,x
        sta     last
        ldy     icon_count      ; Y = new offset
        tya
        sec
        sbc     delta
        tax                     ; X = old offset

:       lda     window_entry_table,x
        sta     window_entry_table,y
        last := *+1
        cpx     #SELF_MODIFIED_BYTE
        beq     shift_offsets
        dex
        dey
        jmp     :-

shift_down:
        ;; Shift down
        inx                     ; X = next window_id
        lda     window_entry_offset_table,x
        tax                     ; X = old offset
        clc
        adc     delta
        tay                     ; Y = new offset

:       lda     window_entry_table,x
        sta     window_entry_table,y
        cpy     icon_count
        beq     shift_offsets
        inx
        iny
        jmp     :-

shift_offsets:
        ;; Update offsets table by delta
        ldx     cached_window_id
        inx
:       lda     window_entry_offset_table,x
        clc
        delta := *+1
        adc     #SELF_MODIFIED_BYTE
        sta     window_entry_offset_table,x
        inx
        cpx     #kMaxDeskTopWindows+1
        bne     :-
done_shift:

        ;; Store count & entries
        ldx     cached_window_id
        lda     cached_window_entry_count
        sta     window_entry_count_table,x
        beq     done_store      ; no entries, done
        sta     count

        lda     window_entry_offset_table,x
        tax                     ; X = offset in table
        ldy     #0              ; Y = index in win
:       lda     cached_window_entry_list,y
        sta     window_entry_table,x
        inx
        iny
        count := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     :-
done_store:

        rts
.endproc ; StoreWindowEntryTable

window_entry_count_table:       .res    ::kMaxDeskTopWindows+1, 0
window_entry_offset_table:      .res    ::kMaxDeskTopWindows+1, 0
window_entry_table:             .res    ::kMaxIconCount, 0

.proc LoadActiveWindowEntryTable
        lda     active_window_id
        jmp     LoadWindowEntryTable
.endproc ; LoadActiveWindowEntryTable

.proc LoadDesktopEntryTable
        lda     #0
        jmp     LoadWindowEntryTable
.endproc ; LoadDesktopEntryTable

;;; ============================================================
;;; Used/Free icon map
;;; ============================================================

;;; Find first available free icon in the map; if
;;; available, mark it and return index+1.

.proc AllocateIcon
        ldx     #0
loop:   lda     free_icon_map,x
        beq     :+
        inx
        cpx     #kMaxIconCount  ; allow up to the maximum
        bne     loop
        rts

:       inx                     ; 0-based to 1-based
        txa
        dex
        tay
        lda     #1
        sta     free_icon_map,x
        tya

        rts
.endproc ; AllocateIcon

;;; Mark the specified icon as free

.proc FreeIcon
        tay
        dey                     ; 1-based to 0-based
        lda     #0
        sta     free_icon_map,y

        rts
.endproc ; FreeIcon

;;; 0-based (0th entry represents icon_id=1)
free_icon_map:  .res    ::kMaxIconCount, 0

;;; ============================================================
;;; Library Routines
;;; ============================================================

        .assert * >= $A000, error, "Routines used by overlays in overlay zone"

        RC_AUXMEM = 1
        RC_LCBANK = 1
        .include "../lib/ramcard.s"

        ;; Place buffers here so they're safe to call from DAs/Overlays
ADJUSTCASE_VOLPATH:     .res    17 ; Room for len+'/'+name
ADJUSTCASE_VOLBUF:      .tag    VolumeDirectoryHeader
        ADJUSTCASE_IO_BUFFER := IO_BUFFER
        .include "../lib/adjustfilecase.s"

        SP_ALTZP = 1
        SP_LCBANK1 = 1
        .include "../lib/smartport.s"

        .include "../lib/menuclock.s"
        .include "../lib/inttostring.s"
        .include "../lib/datetime.s"
        .include "../lib/is_diskii.s"
        .include "../lib/doubleclick.s"
        .include "../lib/reconnect_ram.s"
        .include "../lib/muldiv.s"
        .include "../lib/readwrite_settings.s"

        is_iigs_flag := machine_config::iigs_flag
        is_iiecard_flag := machine_config::iiecard_flag
        is_laser128_flag := machine_config::laser128_flag
        .include "../lib/speed.s"
        .include "../lib/bell.s"

;;; ============================================================
;;; Resources (that are only used from Main, i.e. not MGTK)
;;; ============================================================

;;; Window paths
;;; 8 entries; each entry is kPathBufferSize bytes long
;;; * length-prefixed path string (no trailing /)
;;; Windows 1...8 (since 0 is desktop)
window_path_table:
        .res    (::kMaxDeskTopWindows * ::kPathBufferSize), 0

;;; Table of desktop window path addresses
window_path_addr_table:
        .addr   $0000
        .repeat ::kMaxDeskTopWindows,i
        .addr   window_path_table+i*kPathBufferSize
        .endrepeat
        ASSERT_ADDRESS_TABLE_SIZE window_path_addr_table, ::kMaxDeskTopWindows + 1

;;; ============================================================

;;; Window used/free (in kilobytes)
;;; Two tables, 8 entries each
;;; Windows 1...8 (since 0 is desktop)
window_k_used_table:  .res    ::kMaxDeskTopWindows*2, 0
window_k_free_table:  .res    ::kMaxDeskTopWindows*2, 0

;;; To avoid artifacts, the values drawn are only updated when
;;; a window becomes active.
window_draw_k_used_table:  .res    ::kMaxDeskTopWindows*2, 0
window_draw_k_free_table:  .res    ::kMaxDeskTopWindows*2, 0

;;; ============================================================

;;; Params for icontype_lookup
icontype_filetype:   .byte   0
icontype_auxtype:    .word   0
icontype_blocks:     .word   0
icontype_filename:   .addr   0

icontype_table:
        ;; Types entirely defined by file suffix
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_shk_suffix, 0, IconType::archive ; NuFX
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_bny_suffix, 0, IconType::archive ; Binary II
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_bxy_suffix, 0, IconType::archive ; NuFX in Binary II
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_a2fc_suffix, 0, IconType::graphics ; Apple II Full Color
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_a2fm_suffix, 0, IconType::graphics ; Apple II Full Monochrome
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_a2lc_suffix, 0, IconType::graphics ; Apple II Low Color
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_a2hr_suffix, 0, IconType::graphics ; Apple II High Resolution
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_bsc_suffix, 0, IconType::encoded ; BinSCII
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_bsq_suffix, 0, IconType::encoded ; BinSCII - ShrinkIt
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_btc_suffix, 0, IconType::audio ; Zero-Crossing Audio
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_zc_suffix, 0, IconType::audio ; Binary Time Constant Audio

        ;; Binary files ($06) identified as graphics (hi-res, double hi-res, minipix)
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $2000, 17, IconType::graphics ; HR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $4000, 17, IconType::graphics ; HR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $2000, 33, IconType::graphics ; DHR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $4000, 33, IconType::graphics ; DHR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $5800, 3,  IconType::graphics ; Minipix as FOT

        ;; Simple Mappings
        DEFINE_ICTRECORD $FF, FT_TEXT,      ICT_FLAGS_NONE, 0, 0, IconType::text          ; $04
        DEFINE_ICTRECORD $FF, FT_BINARY,    ICT_FLAGS_NONE, 0, 0, IconType::binary        ; $06
        DEFINE_ICTRECORD $FF, FT_FONT,      ICT_FLAGS_NONE, 0, 0, IconType::font          ; $07
        DEFINE_ICTRECORD $FF, FT_GRAPHICS,  ICT_FLAGS_NONE, 0, 0, IconType::graphics      ; $08

        DEFINE_ICTRECORD $FF, FT_DIRECTORY, ICT_FLAGS_NONE, 0, 0, IconType::folder        ; $0F
        DEFINE_ICTRECORD $FF, FT_ADB,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_db ; $19
        DEFINE_ICTRECORD $FF, FT_AWP,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_wp ; $1A
        DEFINE_ICTRECORD $FF, FT_ASP,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_sp ; $1B

        DEFINE_ICTRECORD $FF, FT_CMD,       ICT_FLAGS_NONE, 0, 0, IconType::command       ; $F0
        DEFINE_ICTRECORD $FF, FT_BASIC,     ICT_FLAGS_NONE, 0, 0, IconType::basic         ; $FC
        DEFINE_ICTRECORD $FF, FT_INT,       ICT_FLAGS_NONE, 0, 0, IconType::intbasic      ; $FA
        DEFINE_ICTRECORD $FF, FT_REL,       ICT_FLAGS_NONE, 0, 0, IconType::relocatable   ; $FE
        DEFINE_ICTRECORD $FF, FT_SYSTEM,    ICT_FLAGS_SUFFIX, str_sys_suffix, 0, IconType::application ; $FF
        DEFINE_ICTRECORD $FF, FT_SYSTEM,    ICT_FLAGS_NONE, 0, 0, IconType::system        ; $FF

        DEFINE_ICTRECORD $FF, FT_ANIMATION, ICT_FLAGS_NONE, 0, 0, IconType::animation     ; $5B ANM
        DEFINE_ICTRECORD $FF, FT_SOUND,     ICT_FLAGS_NONE, 0, 0, IconType::audio         ; $D8 SND
        DEFINE_ICTRECORD $FF, FT_MUSIC,     ICT_FLAGS_NONE, 0, 0, IconType::music         ; $D5 MUS
        DEFINE_ICTRECORD $FF, $E0,          ICT_FLAGS_AUX, $8002, 0, IconType::archive ; NuFX

        ;; IIgs-Specific Files (ranges)
        DEFINE_ICTRECORD $F0, $50,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs General  $5x
        DEFINE_ICTRECORD $F0, $A0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs BASIC    $Ax
        DEFINE_ICTRECORD $FF, FT_S16, ICT_FLAGS_NONE, 0, 0, IconType::application ; IIgs System   $B3
        DEFINE_ICTRECORD $F0, $B0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs System   $Bx
        DEFINE_ICTRECORD $F0, $C0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs Graphics $Cx

        ;; Desk Accessories/Applets $F1/$0642 and $F1/$8642
        DEFINE_ICTRECORD $FF, kDAFileType,  ICT_FLAGS_AUX, kDAFileAuxType, 0, IconType::desk_accessory
        DEFINE_ICTRECORD $FF, kDAFileType,  ICT_FLAGS_AUX, kDAFileAuxType|$8000, 0, IconType::desk_accessory
        .byte   kICTSentinel

;;; Suffixes
str_sys_suffix:                 ; SYS files with .SYSTEM suffix are given "application" icon
        PASCAL_STRING ".SYSTEM"

str_shk_suffix:                 ; ShrinkIt NuFX files, that have lost their type info.
        PASCAL_STRING ".SHK"

str_bny_suffix:                 ; Binary II files, which contain metadata as a header
        PASCAL_STRING ".BNY"    ; (pronounced "bunny", per A2-Central, Vol 5. No. 7, Aug 1989 )

str_bxy_suffix:                 ; ShrinkIt NuFX files, in a Binary II package
        PASCAL_STRING ".BXY"    ; (pronounced "boxy", per A2-Central, Vol 5. No. 7, Aug 1989 )

str_a2fc_suffix:                ; Double-hires ("Apple II Full Color")
        PASCAL_STRING ".A2FC"

str_a2fm_suffix:                ; Double-hires ("Apple II Full Mono") - Bmp2DHR uses this
        PASCAL_STRING ".A2FM"

str_a2lc_suffix:                ; Single-hires ("Apple II Low Color")
        PASCAL_STRING ".A2LC"

str_a2hr_suffix:                ; Single-hires B&W ("Apple II High Resolution")
        PASCAL_STRING ".A2HR"

str_zc_suffix:                  ; "Zero-Crossing" Audio
        PASCAL_STRING ".ZC"

str_btc_suffix:                 ; "Binary Time Constant" Audio
        PASCAL_STRING ".BTC"

str_bsc_suffix:                 ; BinSCII
        PASCAL_STRING ".BSC"

str_bsq_suffix:                 ; BinSCII - ShrinkIt
        PASCAL_STRING ".BSQ"

;;; ============================================================
;;; DeskTop icon placement

;;;  +-------------------------+
;;;  |                     1   |
;;;  |                     2   |
;;;  |                     3   |
;;;  |                     4   |
;;;  |        13  12  11   5   |
;;;  | 10  9   8   7   6 Trash |
;;;  +-------------------------+

        kTrashIconX = 506
        kTrashIconY = 160

        kVolIconDeltaY = 29

        kVolIconCol1 = 490
        kVolIconCol2 = 400
        kVolIconCol3 = 310
        kVolIconCol4 = 220
        kVolIconCol5 = 130
        kVolIconCol6 = 40

desktop_icon_coords_table:
        .word    kVolIconCol1,15 + kVolIconDeltaY*0 ; 1
        .word    kVolIconCol1,15 + kVolIconDeltaY*1 ; 2
        .word    kVolIconCol1,15 + kVolIconDeltaY*2 ; 3
        .word    kVolIconCol1,15 + kVolIconDeltaY*3 ; 4
        .word    kVolIconCol1,15 + kVolIconDeltaY*4 ; 5
        .word    kVolIconCol2,kTrashIconY+2         ; 6
        .word    kVolIconCol3,kTrashIconY+2         ; 7
        .word    kVolIconCol4,kTrashIconY+2         ; 8
        .word    kVolIconCol5,kTrashIconY+2         ; 9
        .word    kVolIconCol6,kTrashIconY+2         ; 10
        .word    kVolIconCol2,15 + kVolIconDeltaY*4 ; 11
        .word    kVolIconCol3,15 + kVolIconDeltaY*4 ; 12
        .word    kVolIconCol4,15 + kVolIconDeltaY*4 ; 13
        .word    kVolIconCol5,15 + kVolIconDeltaY*4 ; 14
        ASSERT_RECORD_TABLE_SIZE desktop_icon_coords_table, ::kMaxVolumes, .sizeof(MGTK::Point)


;;; Which icon positions are in use. 0=free, icon number otherwise
desktop_icon_usage_table:
        .res    ::kMaxVolumes, 0

;;; ============================================================

;;; FileRecord for list view
list_view_filerecord:
        .tag FileRecord

;;; Used elsewhere for converting date to string
datetime_for_conversion := list_view_filerecord + FileRecord::modification_date

;;; ============================================================


path_buf4:
        .res    ::kPathBufferSize, 0
path_buf3:
        .res    ::kPathBufferSize, 0
filename_buf:
        .res    16, 0

        ;; Set to $80 for Copy, $FF for Run
copy_run_flag:
        .byte   0

op_ref_num:
        .byte   0

process_depth:
        .byte   0               ; tracks recursion depth

;;; Number of file entries per directory block
num_entries_per_block:
        .byte   13

entries_read:
        .word   0
entries_to_skip:
        .word   0

;;; During directory traversal, the number of file entries processed
;;; at the current level is pushed here, so that following a descent
;;; the previous entries can be skipped.
entry_count_stack:
        .res    ::kDirStackBufferSize, 0

entry_count_stack_index:
        .byte   0

entries_read_this_block:
        .byte   0

;;; ============================================================

        ;; index is device number (in DEVLST), value is icon number
device_to_icon_map:
        .res    ::kMaxVolumes, 0

;;; Window to file record mapping list. Each entry is a window
;;; id. Position in the list is the same as position in the
;;; subsequent file record list.
window_id_to_filerecord_list_count:
        .byte   0
window_id_to_filerecord_list_entries:
        .res    ::kMaxDeskTopWindows, 0 ; 8 entries + length

;;; Mapping from position in above table to FileRecord entry
window_filerecord_table:
        .res    ::kMaxDeskTopWindows*2

;;; ============================================================

startup_slot_table:
        .res    7, 0            ; maps menu item index (0-based) to slot number

;;; ============================================================

;;; Assigned during startup
trash_icon_num:  .byte   0

;;; ============================================================

hex_digits:
        .byte   "0123456789ABCDEF"

;;; ============================================================

;;; High bit set if menu dispatch via keyboard accelerator, clear otherwise.
menu_kbd_flag:
        .byte   0

;;; ============================================================

;;; Map ProDOS file type to string (for listings/Get Info).
;;; If not found, $XX is used (like CATALOG).

        kNumFileTypes = 19
type_table:
        .byte   FT_TYPELESS   ; unknown
        .byte   FT_BAD        ; bad block
        .byte   FT_TEXT       ; text
        .byte   FT_BINARY     ; binary
        .byte   FT_FONT       ; font
        .byte   FT_GRAPHICS   ; graphics
        .byte   FT_DIRECTORY  ; directory
        .byte   FT_ADB        ; appleworks db
        .byte   FT_AWP        ; appleworks wp
        .byte   FT_ASP        ; appleworks sp
        .byte   FT_ANIMATION  ; animation
        .byte   FT_S16        ; IIgs application
        .byte   FT_MUSIC      ; music
        .byte   FT_SOUND      ; sampled sound
        .byte   FT_CMD        ; command
        .byte   FT_INT        ; intbasic
        .byte   FT_BASIC      ; basic
        .byte   FT_REL        ; rel
        .byte   FT_SYSTEM     ; system
        ASSERT_TABLE_SIZE type_table, kNumFileTypes

type_names_table:
        ;; Types marked with * are known to BASIC.SYSTEM.
        .byte   "NON " ; unknown
        .byte   "BAD " ; bad block
        .byte   "TXT " ; text *
        .byte   "BIN " ; binary *
        .byte   "FNT " ; font
        .byte   "FOT " ; graphics
        .byte   "DIR " ; directory *
        .byte   "ADB " ; appleworks db *
        .byte   "AWP " ; appleworks wp *
        .byte   "ASP " ; appleworks sp *
        .byte   "ANM " ; animation
        .byte   "S16 " ; IIgs application
        .byte   "MUS " ; music
        .byte   "SND " ; sampled sound
        .byte   "CMD " ; command *
        .byte   "INT " ; basic *
        .byte   "BAS " ; basic *
        .byte   "REL " ; rel *
        .byte   "SYS " ; system *
        ASSERT_RECORD_TABLE_SIZE type_names_table, kNumFileTypes, 4

;;; ============================================================
;;; Map IconType to other icon/details

;;; Table mapping IconType to kIconEntryFlags*
icontype_iconentryflags_table:
        .byte   0                    ; generic
        .byte   0                    ; text
        .byte   0                    ; binary
        .byte   0                    ; graphics
        .byte   0                    ; animation/video
        .byte   0                    ; music
        .byte   0                    ; audio
        .byte   0                    ; font
        .byte   0                    ; relocatable
        .byte   0                    ; command
        .byte   kIconEntryFlagsDropTarget ; folder
        .byte   0                    ; iigs
        .byte   0                    ; appleworks db
        .byte   0                    ; appleworks wp
        .byte   0                    ; appleworks sp
        .byte   0                    ; archive
        .byte   0                    ; encoded
        .byte   0                    ; desk accessory
        .byte   0                    ; basic
        .byte   0                    ; intbasic
        .byte   0                    ; system
        .byte   0                    ; application
        ASSERT_TABLE_SIZE icontype_iconentryflags_table, IconType::COUNT

;;; Table mapping IconType to IconResource
type_icons_table:
        .addr   gen ; generic
        .addr   txt ; text
        .addr   bin ; binary
        .addr   fot ; graphics
        .addr   anm ; animation/video
        .addr   mus ; music
        .addr   snd ; audio
        .addr   fnt ; font
        .addr   rel ; relocatable
        .addr   cmd ; command
        .addr   dir ; folder
        .addr   src ; iigs
        .addr   adb ; appleworks db
        .addr   awp ; appleworks wp
        .addr   asp ; appleworks sp
        .addr   arc ; archive
        .addr   arc ; encoded
        .addr   a2d ; desk accessory
        .addr   bas ; basic
        .addr   int ; intbasic
        .addr   sys ; system
        .addr   app ; application
        ASSERT_ADDRESS_TABLE_SIZE type_icons_table, IconType::COUNT

;;; ============================================================

;;; Shortcut ("run list") paths
run_list_paths:
        .res    ::kMaxRunListEntries * ::kSelectorListPathLength, 0

;;; ============================================================
;;; Localized strings (may change length)
;;; ============================================================

str_auxtype_prefix:
        PASCAL_STRING res_string_auxtype_prefix

str_device_type_diskii:
        PASCAL_STRING res_string_volume_type_disk_ii
str_device_type_ramdisk:
        PASCAL_STRING res_string_volume_type_ramcard
str_device_type_appletalk:
        PASCAL_STRING res_string_volume_type_fileshare
str_device_type_vdrive:
        PASCAL_STRING res_string_volume_type_vdrive

str_volume:
        PASCAL_STRING res_string_volume

;;; ============================================================

.endscope ; main
        main__YieldLoop := main::YieldLoop
        main__ReadSetting := main::ReadSetting
        main__WriteSetting := main::WriteSetting

;;; ============================================================
;;; "Exports"

        Bell := main::Bell
        Multiply_16_8_16 := main::Multiply_16_8_16
        Divide_16_8_16 := main::Divide_16_8_16

;;; ============================================================

        ENDSEG SegmentDeskTopMain
