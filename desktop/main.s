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
.endproc
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
.endproc

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
        scmp16  yoff, #kWindowHeaderHeight+1
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
        .addr   CmdCopySelection
        .addr   CmdDeleteSelection
        .addr   CmdNoOp         ; --------
        .addr   CmdQuit
        ASSERT_ADDRESS_TABLE_SIZE menu2_start, ::kMenuSizeFile

        ;; View menu (3)
        menu3_start := *
        .addr   CmdViewByIcon
        .addr   CmdViewBySmallIcon
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
        cmp     #'O'
        jeq     CmdOpenThenCloseCurrent
        cmp     #CHAR_DOWN
        jeq     CmdOpenThenCloseCurrent
        cmp     #CHAR_UP
        jeq     CmdOpenParentThenCloseCurrent
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
.endproc

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
.endproc

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
.endproc

;;; ============================================================
;;; Activate the window, draw contents, and update menu items
;;; Inputs: window id to activate in `findwindow_params::window_id`

.proc ActivateWindow
        ;; Make the window active.
        MGTK_CALL MGTK::SelectWindow, findwindow_params::window_id
        copy    findwindow_params::window_id, active_window_id
        jsr     LoadActiveWindowEntryTable
        lda     #kDrawWindowEntriesHeaderAndContent
        jsr     DrawWindowEntries

        ;; Update menu items
        jsr     UncheckViewMenuItem
        FALL_THROUGH_TO CheckViewMenuItemForActiveWindow
.endproc

.proc CheckViewMenuItemForActiveWindow
        jsr     GetActiveWindowViewBy
        and     #kViewByMenuMask
        sta     checkitem_params::menu_item
        inc     checkitem_params::menu_item
        jmp     CheckViewMenuItem
.endproc

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
        jsr     IconEntryLookup
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
.endproc

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
.endproc

;;; Used for all sorts of windows, not just file windows.
;;; For file windows, used for drawing headers (sometimes);
;;; Returns 0 if ok, `MGTK::Error::window_obscured` if the window is obscured.
.proc UnsafeSetPortFromWindowId
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     :+              ; MGTK::Error::window_obscured
        MGTK_CALL MGTK::SetPort, window_grafport
:       rts
.endproc

;;; Used for windows that can never be obscured (e.g. dialogs)
        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc SafeSetPortFromWindowId
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Result is not MGTK::Error::window_obscured
        MGTK_CALL MGTK::SetPort, window_grafport
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

.endproc

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
.endproc

;;; Call GET_FILE_INFO on file at `src_path_buf` a.k.a. `INVOKER_PREFIX`
;;; Output: MLI result (carry/zero flag, etc), `src_file_info_params` populated
.proc GetSrcFileInfo
        MLI_CALL GET_FILE_INFO, src_file_info_params
        rts
.endproc

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
.endproc

;;; Call GET_FILE_INFO on file at `dst_path_buf`
;;; Output: MLI result (carry/zero flag, etc), `dst_file_info_params` populated
.proc GetDstFileInfo
        MLI_CALL GET_FILE_INFO, dst_file_info_params
        rts
.endproc

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

        cmp     #IconType::basic
        bne     :+
        jsr     CheckBasicSystem ; Only launch if BASIC.SYSTEM is found
        jeq     launch
        lda     #kErrBasicSysNotFound
        jmp     ShowAlert

:       cmp     #IconType::binary
        bne     :+
        lda     menu_click_params::menu_id ; From a menu (File, Selector)
        jne     launch
        jsr     ModifierDown ; Otherwise, only launch if a button is down
        jmi     launch
        lda     #kErrConfirmRunning
        jsr     ShowAlert       ; show a prompt otherwise
        cmp     #kAlertResultOK
        jeq     launch
        jmp     SetCursorPointer ; after not launching BIN

:       cmp     #IconType::folder
        jeq     OpenFolder

        cmp     #IconType::system
        beq     launch

        cmp     #IconType::application
        beq     launch

        cmp     #IconType::archive
        bne     :+
        param_jump InvokeInterpreter, str_unshrink

:       cmp     #IconType::graphics
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
        ;; * Can't use `dst_path_buf` as it is within DA_IO_BUFFER
        ;; * Can't use `src_path_buf` as it holds file selection
        COPY_STRING src_path_buf, tmp_path_buf ; Use this to launch the DA

        ;; As a convenience for DAs, set path to first selected file.
        lda     selected_window_id
        beq     no_file_sel
        lda     selected_icon_count
        beq     no_file_sel

        jsr     CopyAndComposeWinIconPaths
        jmp     :+

no_file_sel:
        copy    #0, src_path_buf ; Signal no file selection

:       param_jump InvokeDeskAcc, tmp_path_buf
    END_IF

        ;; --------------------------------------------------

        jsr     CheckBasisSystem ; Is fallback BASIS.SYSTEM present?
        beq     launch
        lda     #kErrFileNotOpenable
        jmp     ShowAlert

launch:
        param_call UpcaseString, INVOKER_PREFIX
        param_call UpcaseString, INVOKER_INTERPRETER
        jsr     SplitInvokerPath

        copy16  #INVOKER, reset_and_invoke_target
        jmp     ResetAndInvoke

;;; --------------------------------------------------
;;; Check `buf_win_path` and ancestors to see if the desired interpreter
;;; (BASIC.SYSTEM or BASIS.SYSTEM) is present.
;;; Input: `buf_win_path` set to initial search path
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

        inc     interp_path
        ldx     interp_path
        copy    #'/', interp_path,x
loop:
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
        bne     not_found
        rts                     ; zero is success

        ;; Pop off a path segment and try again.
not_found:
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
        jmp     loop
.endproc
CheckBasisSystem        := CheckBasixSystemImpl::basis

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
.endproc


;;; --------------------------------------------------

.proc OpenFolder
        tsx
        stx     saved_stack

        jsr     OpenWindowForPath

        jmp     SetCursorPointer ; after opening folder
.endproc

.endproc

;;; ============================================================

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc UpcaseChar
        cmp     #'a'
        bcc     done
        cmp     #'z'+1
        bcs     done
        and     #CASE_MASK
done:   rts
.endproc

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
        PASCAL_STRING "BASIx.SYSTEM"

str_extras_basic:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/BASIC.system")

str_unshrink:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/UnShrink")

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

;;; Backup copy of DEVLST made before reordering and detaching offline devices
devlst_backup:
        .res    ::kMaxDevListSize+1, 0 ; +1 for DEVCNT itself

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
        bcs     invoke     ; delete or run (no need for more overlays)

        lda     #kDynamicRoutineSelector2 ; file dialog driver
        jsr     LoadDynamicRoutine
        bmi     done
        lda     #kDynamicRoutineFileDialog ; file dialog
        jsr     LoadDynamicRoutine
        bmi     done

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
        COPY_STRING src_path_buf, path_buf0
:
    END_IF

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
.endproc

;;; ============================================================

.proc CmdSelectorItem
        lda     menu_click_params::item_num
        sec
        sbc     #6              ; 4 items + separator (and make 0 based)

        FALL_THROUGH_TO InvokeSelectorEntry
.endproc

;;; ============================================================

;;; A = `entry_num`
.proc InvokeSelectorEntry
        ptr := $06

        sta     entry_num

        ;; Is there a RAMCard at all?
        jsr     GetCopiedToRAMCardFlag
        beq     use_entry_path  ; no RAMCard, skip

        ;; Look at the entry's flags
        lda     entry_num
        jsr     ATimes16
        addax   #run_list_entries, ptr

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
        lda     entry_num
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
        lda     entry_num
        jsr     ComposeRAMCardEntryPath
        stax    ptr
        jmp     launch

        ;; --------------------------------------------------
        ;; Not copied to RAMCard - just use entry's path
use_entry_path:
        lda     entry_num
        jsr     ATimes64
        addax   #run_list_paths, ptr
        FALL_THROUGH_TO launch

launch: param_call CopyPtr1ToBuf, INVOKER_PREFIX
        jmp     LaunchFileWithPath

ret:    rts

entry_num:
        .byte   0

;;; --------------------------------------------------
;;; Input: A = `entry_num`
;;; Output: paths prepared for `DoCopyToRAM`
.proc PrepEntryCopyPaths
        entry_original_path := $800
        entry_ramcard_path := $840

        pha
        jsr     ATimes64
        addax   #run_list_paths, $06
        param_call CopyPtr1ToBuf, entry_original_path

        ;; Copy "down loaded" path to `entry_ramcard_path`
        pla
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
.endproc

;;; --------------------------------------------------
;;; Compose path using RAM card prefix plus last two segments of path
;;; (e.g. "/RAM" + "/MOUSEPAINT/MP.SYSTEM") into `src_path_buf`
;;; Output: A,X = `src_path_buf`
.proc ComposeRAMCardEntryPath
        ptr := $06

        sta     entry_num

        ;; Initialize buffer
        param_call CopyRAMCardPrefix, src_path_buf

        ;; Find entry path
        entry_num := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     ATimes64
        addax   #run_list_paths, ptr
        ldy     #0
        lda     (ptr),y
        sta     @prefix_length
        tay

        ;; Walk back one segment
:       lda     (ptr),y
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       dey

        ;; Walk back a second segment
:       lda     (ptr),y
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       dey

        ;; Append last two segments to `src_path_buf`
        ldx     src_path_buf
:       inx
        iny
        lda     (ptr),y
        sta     src_path_buf,x
        @prefix_length := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     :-

        stx     src_path_buf
        ldax    #src_path_buf
        rts
.endproc

.endproc

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

.proc CmdAbout
        param_jump InvokeDialogProc, kIndexAboutDialog, $0000
.endproc

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
.endproc
CmdDeskAcc      := CmdDeskaccImpl::start

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

.endproc

;;; ============================================================
;;; Launch interpreter (system file that accepts path).

.proc InvokeInterpreter
        ptr1 := $06
        stax    ptr1            ; save for later

        ;; Is the interpreter where we expect it?
        jsr     GetFileInfo
        jcs     SetCursorPointer ; nope, just ignore

        ROUTINE_TARGET := $800
        INTERPRETER_PATH := $A00
        PREFIX_PATH := $A20
        TARGET_PATH := INVOKER_PREFIX ; already populated and safe

        ;; Stash path to interpreter for routine.
        param_call CopyPtr1ToBuf, INTERPRETER_PATH

        ;; Stash current window path, to use as PREFIX.
        lda     active_window_id
        jeq     SetCursorPointer ; no window, just fail
        jsr     GetWindowPath
        stax    ptr1
        param_call CopyPtr1ToBuf, PREFIX_PATH

        ;; Copy routine to $800 and invoke it
        ldx     #0
:       copy    routine,x, ROUTINE_TARGET,x ; single page
        inx
        bne     :-
        jsr     RestoreSystem
        jmp     ROUTINE_TARGET

PROC_AT routine, InvokeInterpreter::ROUTINE_TARGET
        ;; Override within the proc
        MLIEntry := MLI

        jmp     start

        io_buf := $1C00
        DEFINE_OPEN_PARAMS open_params, INTERPRETER_PATH, io_buf
        DEFINE_READ_PARAMS read_params, PRODOS_SYS_START, MLI - PRODOS_SYS_START
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_QUIT_PARAMS quit_params
        DEFINE_SET_PREFIX_PARAMS set_prefix_params, PREFIX_PATH

start:
        ;; Try to load the interpreter
        MLI_CALL OPEN, open_params
        bcs     fail
        lda open_params::ref_num
        sta read_params::ref_num
        sta close_params::ref_num
        MLI_CALL READ, read_params
        bcs     fail
        MLI_CALL CLOSE, close_params

        ;; Set PREFIX to current window
        MLI_CALL SET_PREFIX, set_prefix_params

        ;; Copy target pathname to interpreter's path buffer
        ldx     TARGET_PATH
:       copy    TARGET_PATH,x, PRODOS_INTERPRETER_BUF,x
        dex
        bpl     :-

        jmp     PRODOS_SYS_START

fail:   MLI_CALL CLOSE, close_params
        MLI_CALL QUIT, quit_params

END_PROC_AT
        .assert .sizeof(routine) < $100, error, "Routine too large"
.endproc

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

.endproc

;;; ============================================================
;;; Copy string at ($6) to `path_buf3`, string at ($8) to `path_buf4`,
;;; split filename off `path_buf4` and store in `filename_buf`

.proc CopyPathsFromPtrsToBufsAndSplitName

        ;; Copy string at $6 to `path_buf3`
        param_call CopyPtr1ToBuf, path_buf3

        ;; Copy string at $8 to `path_buf4`
        param_call CopyPtr2ToBuf, path_buf4
        FALL_THROUGH_TO SplitPathBuf4
.endproc

;;; Split filename off `path_buf4` and store in `filename_buf`
.proc SplitPathBuf4
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

        jsr     CopyAndComposeWinIconPaths
        jmp     LaunchFileWithPath
.endproc
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
.endproc

;;; Parent window to close
window_id_to_close:
        .byte   0

;;; ============================================================
;;; Copy selection window and first selected icon paths to
;;; `buf_win_path` and `buf_filename` respectively, and
;;; compose into `src_path_buf`.

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
        jsr     IconEntryLookup
        stax    icon_ptr
        ldy     #IconEntry::name
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

        rts
.endproc


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
        jsr     SelectFileIconByName ; $08 = name
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
.endproc
CmdOpenParent := CmdOpenParentImpl::normal
CmdOpenParentThenCloseCurrent := CmdOpenParentImpl::close_current

;;; ============================================================

.proc CmdClose
        lda     active_window_id
        bne     :+
        rts

:       jmp     CloseActiveWindow
.endproc

;;; ============================================================

.proc CmdCloseAll
        lda     active_window_id  ; current window
        beq     done              ; nope, done!
        jsr     CloseActiveWindow ; close it...
        jmp     CmdCloseAll       ; and try again
done:   rts
.endproc

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
        ;; TODO: See if we can rearrange the memory map to preserve this.
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

        copy16  #path_buf1, $08
        jsr     SelectFileIconByName ; $08 = folder name

done:   rts

.endproc
CmdNewFolder    := CmdNewFolderImpl::start

;;; ============================================================
;;; Select and scroll into view an icon in the active window.
;;; Inputs: $08 = name
;;; Trashes $06

.proc SelectFileIconByName
        ptr_name := $8          ; Input

        ldax    ptr_name
        ldy     active_window_id
        jsr     FindIconByName
        beq     ret             ; not found

        pha
        jsr     HighlightAndSelectIcon
        copy    active_window_id, selected_window_id
        pla
        jsr     ScrollIconIntoView

ret:    rts
.endproc

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
        add16_8 ptr_icon, #IconEntry::name
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

done:   jsr     PopPointers
        lda     icon
        rts

next:   inc     icon
        bne     loop

tmp:    .addr   0
.endproc

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
.endproc

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
        add16_8 window_grafport::maprect::y1, #kWindowHeaderHeight

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
        sub16_8 window_grafport::maprect::y1, #kWindowHeaderHeight
        jsr     AssignActiveWindowCliprectAndUpdateCachedIcons
        jsr     ScrollUpdate
        jsr     RedrawAfterScroll

done:   rts

delta:  .word   0
.endproc

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
.endproc
        CmdEject        := CmdCheckOrEjectImpl::eject
        CmdCheckDrive   := CmdCheckOrEjectImpl::check

;;; ============================================================

.proc CmdQuitImpl
        ;; Override within this scope
        MLIEntry := MLI

        ;; TODO: Assumes prefix is retained. Compose correct path.

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

.endproc
CmdQuit := CmdQuitImpl::start
ResetHandler    := CmdQuitImpl::ResetHandler

;;; ============================================================
;;; Exit DHR, restore device list, reformat /RAM.
;;; Returns with ALTZPOFF and ROM banked in.

.proc RestoreSystem
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

        jsr     SETVID
        jsr     SETKBD

        sta     DHIRESOFF
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR

        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80STORE

        jsr     ReconnectRAM
        jmp     RestoreDeviceList
.endproc

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

        ;; Destroy existing icons
entry2:
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
        jsr     InitCachedWindowEntries
        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
    IF_NEG
        jsr     SortRecords
    END_IF
        jsr     CreateIconsForWindow
        jsr     StoreWindowEntryTable
        jsr     AddIconsForCachedWindow
        jsr     AdjustViewportForNewIcons

        jmp     RedrawAfterContentChange
.endproc

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
        jsr     IconEntryLookup
        stax    @addr
        ITK_CALL IconTK::AddIcon, 0, @addr
        inc     index
        jmp     :-
:
        rts
.endproc

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
.endproc


;;; ============================================================

.proc CmdViewByIcon
        lda     #kViewByIcon
        jmp     ViewByCommon
.endproc

;;; ============================================================

.proc CmdViewBySmallIcon
        lda     #kViewBySmallIcon
        jmp     ViewByCommon
.endproc

;;; ============================================================

.proc CmdViewByName
        lda     #kViewByName
        jmp     ViewByCommon
.endproc

;;; ============================================================

.proc CmdViewByDate
        lda     #kViewByDate
        jmp     ViewByCommon
.endproc

;;; ============================================================

.proc CmdViewBySize
        lda     #kViewBySize
        jmp     ViewByCommon
.endproc

;;; ============================================================

.proc CmdViewByType
        lda     #kViewByType
        jmp     ViewByCommon
.endproc

;;; ============================================================

.proc UpdateViewMenuCheck
        ;; Uncheck last checked
        jsr     UncheckViewMenuItem

        ;; Check the new one
        copy    menu_click_params::item_num, checkitem_params::menu_item
        jmp     CheckViewMenuItem
.endproc

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

.proc ClearActiveWindowEntryCount
        jsr     LoadActiveWindowEntryTable

        copy    #0, cached_window_entry_count

        jmp     StoreWindowEntryTable
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
        jsr     GetSelectedUnitNum
        tax
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
        jsr     GetSelectedUnitNum
        tax
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
.endproc

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
.endproc

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
.endproc

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
.endproc

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
.endproc
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

        rts

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
:       cpy     #SELF_MODIFIED_BYTE
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
        ITK_CALL IconTK::HighlightIcon, icon_param

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
        lda     selected_icon_list
        jsr     ScrollIconIntoView
:

        ITK_CALL IconTK::DrawIcon, selected_icon_list

        rts
.endproc

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
.endproc


;;; ============================================================
;;; Initiate keyboard-based resizing

.proc CmdResize
        MGTK_CALL MGTK::KeyboardMouse
        jmp     HandleResizeClick
.endproc

;;; ============================================================
;;; Initiate keyboard-based window moving

.proc CmdMove
        MGTK_CALL MGTK::KeyboardMouse
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
.endproc

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
.endproc

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
        add16_8 viewport+MGTK::Rect::y1, #kWindowHeaderHeight
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
.endproc

.proc ArrowDown
        jsr     _Preamble
        add16_8 viewport+MGTK::Rect::y2, tick_v
        jmp     _Clamp_y2
.endproc

;;; --------------------------------------------------
;;; When arrow decrement is clicked:
;;;   1. vp.lo -= tick
;;;   2. goto _Clamp_lo

.proc ArrowLeft
        jsr     _Preamble
        sub16_8 viewport+MGTK::Rect::x1, tick_h
        jmp     _Clamp_x1
.endproc

.proc ArrowUp
        jsr     _Preamble
        sub16_8 viewport+MGTK::Rect::y1, tick_v
        jmp     _Clamp_y1
.endproc

;;; --------------------------------------------------
;;; When page increment area is clicked:
;;;   1. vp.hi += size
;;;   2. goto _Clamp_hi

.proc PageRight
        jsr     _Preamble
        add16   viewport+MGTK::Rect::x2, width, viewport+MGTK::Rect::x2
        jmp     _Clamp_x2
.endproc

.proc PageDown
        jsr     _Preamble
        add16_8 viewport+MGTK::Rect::y2, height
        jmp     _Clamp_y2
.endproc

;;; --------------------------------------------------
;;; When page decrement area is clicked:
;;;   1. vp.lo -= size
;;;   2. goto _Clamp_lo

.proc PageLeft
        jsr     _Preamble
        sub16   viewport+MGTK::Rect::x1, width, viewport+MGTK::Rect::x1
        jmp     _Clamp_x1
.endproc

.proc PageUp
        jsr     _Preamble
        sub16_8 viewport+MGTK::Rect::y1, height
        jmp     _Clamp_y1
.endproc

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
.endproc

.proc TrackVThumb
        jsr     _Preamble
        sub16   ubox::y2, ubox::y1, multiplier
        sub16   multiplier, height, multiplier
        jsr     _TrackMulDiv
        add16   quotient, ubox::y1, viewport+MGTK::Rect::y1
        add16   viewport+MGTK::Rect::y1, height, viewport+MGTK::Rect::y2
        jmp     _MaybeUpdateVThumb
.endproc

.proc _TrackMulDiv
        copy    trackthumb_params::thumbpos, multiplicand
        copy    #0, multiplicand+1
        jsr     Mul_16_16
        copy32  product, numerator
        copy32  #kScrollThumbMax, denominator
        jmp     Div_32_32
.endproc

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
.endproc

.proc _Clamp_y2
        scmp16  viewport+MGTK::Rect::y2, ubox::y2
    IF_POS
        copy16  ubox::y2, viewport+MGTK::Rect::y2
    END_IF
        sub16   viewport+MGTK::Rect::y2, height, viewport+MGTK::Rect::y1
        jmp     _MaybeUpdateVThumb
.endproc

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
.endproc

.proc _Clamp_y1
        scmp16  viewport+MGTK::Rect::y1, ubox::y1
    IF_NEG
        copy16  ubox::y1, viewport+MGTK::Rect::y1
    END_IF
        add16   viewport+MGTK::Rect::y1, height, viewport+MGTK::Rect::y2
        jmp     _MaybeUpdateVThumb
.endproc

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
.endproc

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
.endproc

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
.endproc

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
.endproc

;;; --------------------------------------------------
;;; Apply `maprect` back to active window's GrafPort

.proc _UpdateViewport
        ptr := $06

        ;; Restore header to viewport
        sub16_8 viewport+MGTK::Rect::y1, #kWindowHeaderHeight

        jmp     AssignActiveWindowCliprectAndUpdateCachedIcons
.endproc

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
.endproc

;;; --------------------------------------------------
;;; Inputs: A=activate/deactivate, X=which_ctl

.proc _ActivateCtl
        stx     activatectl_params::which_ctl
        sta     activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts
.endproc

;;; --------------------------------------------------
;;; Inputs: A=thumbpos, X=which_ctl

.proc _UpdateThumb
        sta     updatethumb_params::thumbpos
        stx     updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        rts
.endproc

.endscope

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
        jsr     IconEntryLookup
        stax    @addr
        ITK_CALL IconTK::AddIcon, 0, @addr
        ITK_CALL IconTK::DrawIcon, icon_param ; CHECKED (desktop)

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
        jsr     IconEntryNameLookup

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
        jsr     IconEntryLookup
        stax    @addr
        ITK_CALL IconTK::AddIcon, 0, @addr
        ITK_CALL IconTK::DrawIcon, icon_param ; CHECKED (desktop)

:       jmp     StoreWindowEntryTable

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
        FALL_THROUGH_TO ResetAndInvoke
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
.endproc

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
.endproc

;;; ============================================================

.proc HandleContentClick
        ;; Ignore clicks in the header area
        copy    active_window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     screentowindow_params::windowy
        cmp     #kWindowHeaderHeight + 1
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

        ;; (1/4) Canceled?
        cmp     #kOperationCanceled
        ;; TODO: Refresh source/dest if partial success
        jeq     ignore

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
        jeq     ignore

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
        lda     selected_icon_list,x
        sta     icon_param
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

.proc UpdateActiveWindow
        lda     active_window_id
        jsr     UpdateUsedFreeViaWindow
        lda     active_window_id
        jmp     SelectAndRefreshWindowOrClose
.endproc

.endproc
        ;; Used for delete shortcut; set `drag_drop_params::icon` first
        process_drop := HandleFileIconClick::process_drop

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
.endproc

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
        lda     active_window_id
        jsr     UnsafeSetPortFromWindowId ; CHECKED
    IF_ZERO                     ; Skip drawing if obscured
        jsr     LoadActiveWindowEntryTable
        jsr     DrawWindowHeader
    END_IF

        ;; Create icons and draw contents
        jmp     ViewByCommon::entry3
.endproc

;;; ============================================================
;;; Clear the window background, following a call to either
;;; `UnsafeSetPortFromWindowId` or `UnsafeOffsetAndSetPortFromWindowId`

.proc ClearWindowBackgroundIfNotObscured
    IF_ZERO                     ; Skip drawing if obscured
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, window_grafport::maprect
    END_IF
        rts
.endproc

;;; ============================================================
;;; Drag Selection
;;; Inputs: A = window_id (0 for desktop)
;;; Assert: `cached_window_id` == A

.proc DragSelect
        sta     window_id

    IF_NOT_ZERO
        ;; Set up $06 to point at an imaginary `IconEntry`, to map
        ;; `event_params::coords` from screen to window.
        copy16  #(event_params::coords - IconEntry::iconx), $06
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
        jsr     IconPtrScreenToWindow
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc
.endproc

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
.endproc

;;; ============================================================

.proc HandleResizeClick
        copy    active_window_id, event_params
        MGTK_CALL MGTK::GrowWindow, event_params
        jsr     ScrollUpdate
        rts
.endproc

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
.endproc

;;; Close the active window
.proc CloseActiveWindow
        lda     active_window_id
        FALL_THROUGH_TO CloseSpecifiedWindow
.endproc

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
        jsr     IconEntryLookup
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
.endproc

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

;;; NOTE: Does not update icon positions, so only use in empty windows.
.proc ResetActiveWindowViewport
        jsr     ApplyActiveWinfoToWindowGrafport
        sub16   window_grafport::maprect::x2, window_grafport::maprect::x1, window_grafport::maprect::x2
        sub16   window_grafport::maprect::y2, window_grafport::maprect::y1, window_grafport::maprect::y2
        copy16  #0, window_grafport::maprect::x1
        copy16  #0, window_grafport::maprect::y1
        FALL_THROUGH_TO AssignActiveWindowCliprect
.endproc

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
.endproc

.proc AssignActiveWindowCliprectAndUpdateCachedIcons
        jsr     CachedIconsScreenToWindow
        jsr     AssignActiveWindowCliprect
        jmp     CachedIconsWindowToScreen
.endproc


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
        jmp     CheckViewMenuItem
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

:       MGTK_CALL MGTK::DisableMenu, disablemenu_params ; View menu

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
.endproc
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
.endproc
EnableMenuItemsRequiringSingleSelection := ToggleMenuItemsRequiringSingleSelection::enable
DisableMenuItemsRequiringSingleSelection := ToggleMenuItemsRequiringSingleSelection::disable

;;; ============================================================
;;; Calls DisableItem menu_item in A (to enable or disable).
;;; Set disableitem_params' disable flag and menu_id before calling.

.proc DisableMenuItem
        sta     disableitem_params::menu_item
        MGTK_CALL MGTK::DisableItem, disableitem_params
        rts
.endproc

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

.endproc
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

.endproc
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
:
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

        rts
.endproc

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
        jsr     IconEntryLookup
        stax    ptr
        jsr     ComposeIconFullPath ; may fail

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
.endproc
.endproc

;;; ============================================================
;;; Marks icon as open and repaints it.
;;; Input: A = icon id
;;; Output: `ptr` ($06) points at IconEntry

.proc MarkIconOpen
        ptr := $06
        sta     icon_param
        jsr     IconEntryLookup
        stax    ptr

        ;; Set dimmed flag
        ldy     #IconEntry::state
        lda     (ptr),y
        ora     #kIconEntryStateDimmed
        sta     (ptr),y

        ITK_CALL IconTK::DrawIcon, icon_param
        rts
.endproc

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

        copy16  #INVOKER_FILENAME, $08
        jmp     SelectFileIconByName
.endproc

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
.endproc

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
.endproc
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
        ptr := $06
        jsr     IconEntryLookup
        stax    ptr
        ldy     #IconEntry::record_num
        lda     (ptr),y

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
.endproc

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
        jsr     IconEntryLookup
        stax    $06
        jsr     IconPtrScreenToWindow
        ITK_CALL IconTK::DrawIconRaw, icon_param ; CHECKED
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
.endproc

;;; ============================================================

.proc CachedIconsScreenToWindow
        entry_ptr := $6

        jsr     PushPointers
        jsr     PrepActiveWindowScreenMapping

        copy    #0, index
        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     done

        tax
        lda     cached_window_entry_list,x
        jsr     IconEntryLookup
        stax    entry_ptr
        jsr     IconPtrScreenToWindow

        inc     index
        jmp     loop

done:   jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc

;;; ============================================================

.proc CachedIconsWindowToScreen
        entry_ptr := $6

        jsr     PushPointers
        jsr     PrepActiveWindowScreenMapping

        copy    #0, index
        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     done

        tax
        lda     cached_window_entry_list,x
        jsr     IconEntryLookup
        stax    entry_ptr
        jsr     IconPtrWindowToScreen

        inc     index
        jmp     loop

done:   jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc

;;; ============================================================
;;; Adjust grafport for header.
.proc OffsetWindowGrafportImpl

        kOffset = kWindowHeaderHeight + 1

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

.proc FindWindowForSrcPath
        ldax    #src_path_buf
        FALL_THROUGH_TO FindWindowForPath
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
.proc FindWindowsImpl
        ptr := $6

        ;; NOTE: Not used for MLI calls, so another buffer could be used.
        path := tmp_path_buf

exact:  stax    ptr
        lda     #$80
        bne     start           ; always

prefix: stax    ptr
        lda     #0

start:  sta     exact_match_flag
        bit     exact_match_flag
        bpl     :+
        ldy     #0              ; Use full length
        lda     (ptr),y
        tay

:       sty     tmp_path_buf

        ;; Copy ptr to `path`
:       lda     (ptr),y
        sta     path,y
        dey
        bne     :-

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
        cmp     path
        beq     :+

        bit     exact_match_flag
        bmi     loop
        ldy     path
        iny
        lda     (ptr),y
        cmp     #'/'
        bne     loop
        dey

        ;; Case-insensitive comparison
:       lda     (ptr),y
        jsr     UpcaseChar
        sta     @char
        lda     path,y
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
        ;; TODO: Simplify now that all files get icons regardless of view.
        ldx     DEVCNT
        inx                     ; DEVCNT is one less than number of devices
        inx                     ; And one more for Trash
        stx     reserved_desktop_icons
        sub16_8 free_record_count, reserved_desktop_icons ; -= # possible volume icons
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

free_record_count:
        .word   0

reserved_desktop_icons:
        .byte   0
.endproc

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

        jsr     remove_filerecords_and_mark_icon_not_dimmed
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
.endproc

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
.endproc

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
        ecmp16  ptr_src, filerecords_free_start
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
;;; Outputs: `src_path_buf` has full path
;;; Exceptions: if path too long, shows error and restores `saved_stack`
;;; See `GetIconPath` for a variant that doesn't length check.

.proc ComposeIconFullPath
        icon_ptr := $06
        name_ptr := $06

        jsr     PushPointers

        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        pha
        add16_8 icon_ptr, #IconEntry::name, name_ptr
        pla
        and     #kIconEntryWinIdMask
        bne     has_parent      ; A = window_id

        ;; --------------------------------------------------
        ;; Desktop (volume) icon - no parent path

        ;; Copy name
        param_call CopyPtr1ToBuf, src_path_buf+1 ; Leave room for leading '/'
        ;; Add leading '/' and adjust length
        sta     src_path_buf
        inc     src_path_buf
        copy    #'/', src_path_buf+1

        jsr     PopPointers     ; do not tail-call optimise!
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
        jsr     remove_filerecords_and_mark_icon_not_dimmed
        dec     num_open_windows
        ldx     saved_stack
        txs
        rts
    END_IF

        ;; Copy parent path to src_path_buf
        ldax    parent_path_ptr
        jsr     CopyToSrcPath
        ldax    name_ptr
        jsr     AppendFilenameToSrcPath

        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc

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

        jsr     InitCachedWindowEntries
        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
    IF_NEG
        jsr     SortRecords
    END_IF
        jsr     CreateIconsForWindow
        jsr     StoreWindowEntryTable
        jsr     AddIconsForCachedWindow

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
.endproc

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
icons_per_row:      .byte   0
col_spacing:        .byte   0
row_spacing:        .byte   0
        DEFINE_POINT row_coords, 0, 0

icons_this_row:
        .byte   0

        DEFINE_POINT icon_coords, 0, 0

.proc Start
        jsr     PushPointers

        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
    IF_NEG
        ;; List View
        copy16  #kListViewInitialLeft, row_coords::xcoord
        copy16  #kListViewInitialTop, row_coords::ycoord
        copy    #1, icons_per_row ; by definition
        copy    #0, col_spacing   ; N/A
        copy    #kListItemHeight, row_spacing
    ELSE
        .assert kViewByIcon = 0, error, "enum mismatch"
      IF_ZERO
        ;; Icon View
        copy16  #kIconViewInitialLeft, row_coords::xcoord
        copy16  #kIconViewInitialTop, row_coords::ycoord
        copy    #kIconViewIconsPerRow, icons_per_row
        copy    #kIconViewSpacingX, col_spacing
        copy    #kIconViewSpacingY, row_spacing
      ELSE
        ;; Small Icon View
        copy16  #kSmallIconViewInitialLeft, row_coords::xcoord
        copy16  #kSmallIconViewInitialTop, row_coords::ycoord
        copy    #kSmallIconViewIconsPerRow, icons_per_row
        copy    #kSmallIconViewSpacingX, col_spacing
        copy    #kSmallIconViewSpacingY, row_spacing
      END_IF
    END_IF

        copy16  row_coords::xcoord, initial_xcoord

        lda     #0
        sta     icons_this_row
        sta     index

        ldx     #3
:       sta     icon_coords,x
        dex
        bpl     :-

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
        jsr     GetIconPath     ; `path_buf3` set to path
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
.endproc

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
.endproc

.endproc
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
.endproc

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
.endproc


;;; ============================================================
;;; Map file type (etc) to icon type

;;; Input: `icontype_filetype`, `icontype_auxtype`, `icontype_blocks`, `icontype_filename` populated
;;; Output: A is IconType to use (for icons, open/preview, etc)

.proc GetIconType
        ptr := $06

        jsr     PushPointers
        copy16  #icontype_table, ptr

loop:   ldy     #0              ; type_mask, or $00 if done
        lda     (ptr),y
        cmp     #kICTSentinel
        bne     :+
        jsr     PopPointers
        lda     #IconType::generic
        rts

        ;; Check type (with mask)
:       and     icontype_filetype    ; A = type & type_mask
        iny                     ; ASSERT: Y = ICTRecord::type
        cmp     (ptr),y         ; type check
        jne     next

        ;; Flags
        iny                     ; ASSERT: Y = ICTRecord::flags
        lda     (ptr),y
        sta     flags

        ;; Does Aux Type matter, and if so does it match?
        bit     flags
    IF_NS                       ; bit 7 = compare aux
        iny                     ; ASSERT: Y = FTORecord::aux_suf
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
.endproc


;;; ============================================================
;;; Draw header (items/K in disk/K available/lines) for active window

.proc DrawWindowHeader

        ;; Compute header coords

        ;; x coords
        lda     window_grafport::maprect::x1
        sta     header_line_left::xcoord
        clc
        adc     #5
        sta     items_label_pos::xcoord
        lda     window_grafport::maprect::x1+1
        sta     header_line_left::xcoord+1
        adc     #0
        sta     items_label_pos::xcoord+1

        ;; y coords
        lda     window_grafport::maprect::y1
        clc
        adc     #kWindowHeaderHeight - 2
        sta     header_line_left::ycoord
        sta     header_line_right::ycoord
        lda     window_grafport::maprect::y1+1
        adc     #0
        sta     header_line_left::ycoord+1
        sta     header_line_right::ycoord+1

        ;; Draw top line
        MGTK_CALL MGTK::MoveTo, header_line_left
        copy16  window_grafport::maprect::x2, header_line_right::xcoord
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

        ;; Baseline for header text
        add16_8 window_grafport::maprect::y1, #kWindowHeaderHeight-4, items_label_pos::ycoord

        ;; Draw "XXX Items"
        lda     active_window_id
        jsr     GetFileRecordCountForWindow
        ldx     #0
        jsr     IntToStringWithSeparators
        lda     cached_window_entry_count
        jsr     adjust_item_suffix

        MGTK_CALL MGTK::MoveTo, items_label_pos
        jsr     DrawIntString
        param_call_indirect DrawLCString, ptr_str_items_suffix

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
        MGTK_CALL MGTK::MoveTo, pos_k_in_disk
        jsr     DrawIntString
        param_call DrawLCString, str_k_in_disk

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
        MGTK_CALL MGTK::MoveTo, pos_k_available
        jsr     DrawIntString
        param_jump DrawLCString, str_k_available

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
        sub16   window_grafport::maprect::x2, window_grafport::maprect::x1, xcoord

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
        add16   pos_k_in_disk::xcoord, window_grafport::maprect::x1, pos_k_in_disk::xcoord
        add16   pos_k_available::xcoord, window_grafport::maprect::x1, pos_k_available::xcoord

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
        param_jump DrawLCString, str_from_int
.endproc

xcoord:
        .word   0
.endproc ; DrawWindowHeader

;;; ============================================================
;;; Compute bounding box for icons within cached window
;;; Inputs: `cached_window_id` is set

        DEFINE_RECT iconbb_rect, 0, 0, 0, 0

.proc ComputeIconsBBox

        entry_ptr := $06

        kIntMax = $7FFF

start:
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

finish:
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
.endproc

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
.endproc

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
.endproc

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

ret:    rts

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
.endproc

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
        jmp     GetSelectableIconsSorted::CompareStrings
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
        ldy     #FileRecord::blocks
        lda     (ptr2),y        ; order descending
        cmp     (ptr1),y
        iny
        lda     (ptr2),y
        sbc     (ptr1),y
        rts
    END_IF

        ;; Assert: kViewByType
        ldy     #FileRecord::file_type
        lda     (ptr1),y
        jsr     GetTypeIndex
        sta     index1
        lda     (ptr2),y
        jsr     GetTypeIndex
        index1 := *+1
        cmp     #SELF_MODIFIED_BYTE
        rts

.endproc
CompareFileRecords_sort_by := CompareFileRecords::sort_by

;;; --------------------------------------------------
;;; Input: A = file type
;;; Output: A = sorting weight
;;; Assert: LCBANK2 is active
.proc GetTypeIndex
        bit     LCBANK1
        bit     LCBANK1

        ldx     #kNumFileTypes-1
:       cmp     type_table,x
        beq     found
        dex
        bpl     :-

        ;; Not found
        ldx     #0

found:  txa

        bit     LCBANK2
        bit     LCBANK2
        rts
.endproc

.endproc


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
        jsr     draw_text

        MGTK_CALL MGTK::MoveTo, pos_col_size
        jsr     PrepareColSize
        jsr     draw_text

        MGTK_CALL MGTK::MoveTo, pos_col_date
        jsr     ComposeDateString
        FALL_THROUGH_TO draw_text

draw_text:
        MGTK_CALL MGTK::DrawText, text_buffer2
        rts
.endproc

;;; ============================================================

.proc PrepareColType
        file_type := list_view_filerecord + FileRecord::file_type

        lda     file_type
        jsr     ComposeFileTypeString

        COPY_BYTES 4, str_file_type, text_buffer2::length ; 3 characters + length

        rts
.endproc

.proc PrepareColSize
        file_type := list_view_filerecord + FileRecord::file_type

        lda     file_type
        cmp     #FT_DIRECTORY
    IF_EQ
        copy    #1, text_buffer2::length
        copy    #'-', text_buffer2::data
        rts
    END_IF

        blocks := list_view_filerecord + FileRecord::blocks

        ldax    blocks
        FALL_THROUGH_TO ComposeSizeString
.endproc

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
        copy    #0, text_buffer2::length
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

        lda     SETTINGS+DeskTopSettings::intl_date_order
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

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"

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
        jsr     PushPointers

        icon_ptr := $06
        jsr     IconEntryLookup
        stax    icon_ptr

        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        pha                     ; A = window id
        add16_8 icon_ptr, #IconEntry::name
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
        jsr     PopPointers    ; do not tail-call optimise!
        rts
.endproc

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

        stx     str_file_type
        rts

        ;; Type not found - use generic " $xx"
not_found:
        copy    #3, str_file_type
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
.endproc

;;; ============================================================
;;; Append aux type (in A,X) to text_buffer2

.proc AppendAuxType
        stax    auxtype
        ldy     text_buffer2::length

        ;; Append prefix
        ldx     #0
:       lda     str_auxtype_prefix+1,x
        sta     text_buffer2::data,y
        inx
        iny
        cpx     str_auxtype_prefix
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

auxtype:
        .word 0
.endproc

;;; ============================================================
;;; Draw text, pascal string address in A,X
;;; String must be in LC area (visible to both main and aux code)

.proc DrawLCString
        params := $6
        textptr := $6
        textlen := $8

        stax    textptr
        ldy     #0
        lda     (textptr),y
        beq     exit
        sta     textlen
        inc16   textptr
        MGTK_CALL MGTK::DrawText, params
exit:   rts
.endproc

;;; ============================================================
;;; Measure text, pascal string address in A,X; result in A,X
;;; String must be in LC area (visible to both main and aux code)

.proc MeasureLCString
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
.endproc

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
.endproc

;;; ============================================================
;;; Convert icon's coordinates from window to screen
;;; (icon index in A, active window)
;;; NOTE: Avoid calling in a loop; factor out `PrepActiveWindowScreenMapping`

.proc IconWindowToScreen
        entry_ptr := $6

        jsr     PushPointers
        jsr     IconEntryLookup
        stax    entry_ptr
        jsr     PrepActiveWindowScreenMapping
        jsr     IconPtrWindowToScreen
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc

;;; Convert icon's coordinates from window to screen
;;; Inputs: icon entry pointer in $6, `PrepActiveWindowScreenMapping` called
.proc IconPtrWindowToScreen
        entry_ptr := $6

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
.endproc

;;; ============================================================
;;; Convert icon's coordinates from screen to window
;;; (icon index in A, active window)
;;; NOTE: Avoid calling in a loop; factor out `PrepActiveWindowScreenMapping`

.proc IconScreenToWindow
        entry_ptr := $6

        jsr     PushPointers
        jsr     IconEntryLookup
        stax    entry_ptr
        jsr     PrepActiveWindowScreenMapping
        jsr     IconPtrScreenToWindow
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc

;;; Convert icon's coordinates from screen to window
;;; Inputs: icon entry pointer in $6, `PrepActiveWindowScreenMapping` called
.proc IconPtrScreenToWindow
        entry_ptr := $6

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
.endproc

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
        .addr cdrom_icon
        ASSERT_ADDRESS_TABLE_SIZE device_type_to_icon_address_table, ::kNumDeviceTypes

dib_buffer := $800
.params status_params
param_count:    .byte   3
unit_num:       .byte   1
list_ptr:       .addr   dib_buffer
status_code:    .byte   3       ; Return Device Information Block (DIB)
.endparams

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
.endproc
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
        lda     #ERR_DUPLICATE_VOLUME
        bne     finish          ; always

        ;; Doesn't match, try again
next:   dec     index
        bpl     loop

        ;; All done, clean up and report no duplicates.
        lda     #0

finish: jsr     PopPointers     ; do not tail-call optimise!
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
        ldx     #kMaxDeskTopWindows-1
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

.proc MarkIconNotDimmed
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
        FALL_THROUGH_TO start

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

        ldy     #IconEntry::state
        lda     (ptr),y
        and     #AS_BYTE(~kIconEntryStateDimmed)
        sta     (ptr),y
        ITK_CALL IconTK::DrawIcon, icon_param

        jsr     PopPointers

ret:    rts
.endproc
        remove_filerecords_and_mark_icon_not_dimmed := MarkIconNotDimmed::remove_filerecords

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
.endproc
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
.endproc

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
.endproc

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
.endproc

.proc FrameTmpRect
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        jsr     SetPenModeXOR
        MGTK_CALL MGTK::FrameRect, tmp_rect
        rts
.endproc

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

.endproc
LoadDynamicRoutine      := LoadDynamicRoutineImpl::load
RestoreDynamicRoutine   := LoadDynamicRoutineImpl::restore

;;; ============================================================

.proc SetRGBMode
        bit     SETTINGS + DeskTopSettings::rgb_color
        bpl     SetMonoMode
        FALL_THROUGH_TO SetColorMode
.endproc

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
.endproc

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
.endproc

;;; On IIgs, force preferred RGB mode. No-op otherwise.
.proc ResetIIgsRGB
        bit     machine_config::iigs_flag
        bpl     SetMonoMode::done ; nope

        bit     SETTINGS + DeskTopSettings::rgb_color
        bmi     SetColorMode::iigs
        bpl     SetMonoMode::iigs ; always
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
        FALL_THROUGH_TO DoCopyToRAM2

DoCopyToRAM2:
        copy    #$FF, copy_run_flag
        copy    #0, move_flag
        copy    #0, delete_skip_decrement_flag
        jsr     copy_file_for_run
        jsr     InvokeOperationCompleteCallback
        FALL_THROUGH_TO FinishOperation

.proc FinishOperation
        return  #kOperationSucceeded
.endproc

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

;;; --------------------------------------------------

.proc DoGetSize
        copy    #0, run_flag
        copy    #%11000000, operation_flags ; get size
        jmp     L8FEB
.endproc

.proc DoCopySelection
        copy    #0, operation_flags ; copy/delete
        copy    #$40, copy_delete_flags ; target is `path_buf3`
        jmp     L8FEB
.endproc

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
        jmp     L8FEB
.endproc

        ;; common for lock/unlock
L8FDD:  lda     #$00            ; unlock
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
L8FE1:  lda     #$80            ; lock
        sta     unlock_flag
        copy    #%10000000, operation_flags ; lock/unlock
        FALL_THROUGH_TO L8FEB

L8FEB:  tsx
        stx     stack_stash
        copy    #0, delete_skip_decrement_flag
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
        jsr     GetIconPath   ; `path_buf3` set to path

common:
        ldy     path_buf3
:       copy    path_buf3,y, path_buf4,y
        dey
        bpl     :-
        FALL_THROUGH_TO BeginOperation

;;; --------------------------------------------------
;;; Start the actual operation

.proc BeginOperation
        copy    #0, do_op_flag

        jsr     PrepCallbacksForSizeOrCount
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
        stax    $08
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
        jsr     GetIconPath

        lda     do_op_flag
        beq     just_size_and_count

        bit     operation_flags
        bmi     @lock_or_size
        bit     copy_delete_flags
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
        bit     copy_delete_flags
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

        bit     copy_delete_flags
        bpl     no_confirm
        bmi     confirm

@lock_or_size:
        bvc     no_confirm      ; lock/unlock

confirm:
        jsr     InvokeOperationConfirmCallback
        bit     operation_flags
        bvs     finish

no_confirm:
        jmp     perform

finish: jsr     InvokeOperationCompleteCallback
        return  #0
.endproc

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
;;; Inputs: A = icon number

.proc SmartportEject
        ptr := $6

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

.params status_params
param_count:    .byte   3
unit_num:       .byte   SELF_MODIFIED_BYTE
list_ptr:       .addr   dib_buffer
status_code:    .byte   3       ; Return Device Information Block (DIB)
.endparams
        status_unit_number := status_params::unit_num

.params control_params
param_count:    .byte   3
unit_number:    .byte   SELF_MODIFIED_BYTE
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

        jsr     GetIconPath   ; `path_buf3` is full path

        ldy     path_buf3       ; Copy to `src_path_buf`
:       copy    path_buf3,y, src_path_buf,y
        dey
        bpl     :-

        ;; Try to get file info
common: jsr     GetSrcFileInfo
        beq     :+
        jsr     ShowErrorAlert
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
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
        jsr     IconEntryNameLookup
        copy16  $06, get_info_dialog_params::a_str
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------
        ;; Type
        copy    #GetInfoDialogState::type, get_info_dialog_params::state
        lda     selected_window_id
    IF_ZERO
        ;; Volume
        COPY_STRING str_volume, text_buffer2::length
    ELSE
        ;; File
        lda     src_file_info_params::file_type
        pha
        jsr     ComposeFileTypeString
        COPY_STRING str_file_type, text_buffer2::length
        pla                     ; A = file type
        cmp     #FT_DIRECTORY
      IF_NE
        ldax    src_file_info_params::aux_type
        jsr     AppendAuxType
      END_IF
    END_IF
        copy16  #text_buffer2::length, get_info_dialog_params::a_str
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

        ;; text_buffer2 now has "12345K"

        ;; Copy into buf
        ldx     buf
        ldy     #0
:       inx
        lda     text_buffer2::data,y
        sta     buf,x
        iny
        cpy     text_buffer2::length
        bne     :-

        ;; Append " / " to buf
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
        lda     text_buffer2::data-1,y
        sta     buf,x
        cpy     text_buffer2::length
        beq     :+
        iny
        bne     :-
:       stx     buf

        ;; TODO: Compose directly into `path_buf1`.
        COPY_STRING buf, path_buf1

        copy16  #path_buf1, get_info_dialog_params::a_str
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------
        ;; Created date
        copy    #GetInfoDialogState::created, get_info_dialog_params::state
        COPY_STRUCT DateTime, src_file_info_params::create_date, datetime_for_conversion
        jsr     ComposeDateString
        copy16  #text_buffer2::length, get_info_dialog_params::a_str
        jsr     RunGetInfoDialogProc

        ;; --------------------------------------------------
        ;; Modified date
        copy    #GetInfoDialogState::modified, get_info_dialog_params::state
        COPY_STRUCT DateTime, src_file_info_params::mod_date, datetime_for_conversion
        jsr     ComposeDateString
        copy16  #text_buffer2::length, get_info_dialog_params::a_str
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
.endproc
.endproc

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
        jsr     GetIconPath

        param_call CopyToSrcPath, path_buf3

        lda     selected_icon_list
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
        beq     no_change       ; always
changed:

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
        jsr     IconEntryNameLookup ; $06 = icon name ptr
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
        jsr     IconEntryLookup
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
.endproc

;;; N bit ($80) set if a window title was changed
result_flags:
        .byte   0

icony:  .word   0
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
        jsr     FindWindowForSrcPath
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
;;; Modifies `path_buf1` and `tmp_path_buf`

.proc UpdateTargetPath
        dst := $06

        ;; Set `path_buf1` to the old path (should be `src_path_buf` + suffix)
        param_call CopyPtr1ToBuf, path_buf1

        ;; Set `tmp_path_buf` to the new prefix
        ldy     dst_path_buf
:       lda     dst_path_buf,y
        sta     tmp_path_buf,y
        dey
        bpl     :-

        ;; Copy the suffix from `path_buf1` to `tmp_path_buf`
        ldx     src_path_buf
        cpx     path_buf1
        beq     assign          ; paths are equal, no copying needed

        ldy     dst_path_buf
:       inx                     ; advance into suffix
        iny
        lda     path_buf1,x
        sta     tmp_path_buf,y
        cpx     path_buf1
        bne     :-
        sty     tmp_path_buf

        ;; Assign the new window path
assign: ldy     tmp_path_buf
:       lda     tmp_path_buf,y
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
        ldy     src_path_buf
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
        path := tmp_path_buf    ; depends on `src_path_buf`, `dst_path_buf`

        ;; ProDOS Prefix
        MLI_CALL GET_PREFIX, get_set_prefix_params
        copy16  #path, ptr
        jsr     MaybeUpdateTargetPath
    IF_EQ
        MLI_CALL SET_PREFIX, get_set_prefix_params
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

        param_call CopyToSrcPath, path_buf3

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

;;; NOTE: These are referenced by indirect JMP and *must not*
;;; cross page boundaries.
op_jt_addrs:
op_jt_addr1:  .addr   CopyProcessDirectoryEntry     ; defaults are for copy
op_jt_addr2:  .addr   copy_pop_directory
op_jt_addr3:  .addr   DoNothing

op_jt1: jmp     (op_jt_addr1)
op_jt2: jmp     (op_jt_addr2)
op_jt3: jmp     (op_jt_addr3)

        ;; overlayed indirect jump table
        kOpJTAddrsSize = 6

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
.endproc

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
.endproc

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
        bcs     done
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
        param_jump InvokeDialogProc, kIndexDownloadDialog, copy_dialog_params
.endproc

.proc DownloadDialogEnumerationCallback
        stax    copy_dialog_params::count
        copy    #CopyDialogLifecycle::count, copy_dialog_params::phase
        param_jump InvokeDialogProc, kIndexDownloadDialog, copy_dialog_params
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
        param_jump InvokeDialogProc, kIndexDownloadDialog, copy_dialog_params
.endproc

.proc DownloadDialogTooLargeCallback
        copy    #DownloadDialogLifecycle::too_large, copy_dialog_params::phase
        param_call InvokeDialogProc, kIndexDownloadDialog, copy_dialog_params
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
@retry: jsr     GetSrcFileInfo
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
retry:  MLI_CALL CREATE, create_params2
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
@retry: jsr     GetSrcFileInfo
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
@retry: jsr     GetSrcFileInfo
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
        param_jump InvokeDialogProc, kIndexCopyDialog, copy_dialog_params
.endproc

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
@retry: jsr     GetSrcFileInfo
        beq     :+
        jsr     ShowErrorAlert
        jmp     @retry

        ;; If destination doesn't exist, 0 blocks will be reclaimed.
:       copy16  #0, existing_size

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
.endproc

.proc CopySrcRefNum
        lda     open_src_params::ref_num
        sta     read_src_params::ref_num
        sta     close_src_params::ref_num
        sta     mark_src_params::ref_num
        rts
.endproc

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
.endproc

.proc WriteDst
@retry: MLI_CALL WRITE, write_dst_params
        beq     :+
        jsr     ShowErrorAlertDst
        jmp     @retry
:       MLI_CALL GET_MARK, mark_dst_params
        rts
.endproc

.proc CloseDst
        MLI_CALL CLOSE, close_dst_params
        rts
.endproc

.proc CloseSrc
        MLI_CALL CLOSE, close_src_params
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
retry:  MLI_CALL CREATE, create_params3
        beq     success

        cmp     #ERR_DUPLICATE_FILENAME
        bne     err
        bit     all_flag
        bmi     yes
        copy    #CopyDialogLifecycle::exists, copy_dialog_params::phase
        param_call InvokeDialogProc, kIndexCopyDialog, copy_dialog_params
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

@retry: jsr     GetSrcFileInfo
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

retry:  MLI_CALL DESTROY, destroy_params
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
        jsr     GetSrcFileInfo
        lda     src_file_info_params::access
        and     #$80            ; destroy enabled bit set?
        bne     done            ; yes, no need to unlock

        lda     #ACCESS_DEFAULT
        sta     src_file_info_params::access
        jsr     SetSrcFileInfo

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
@retry: jsr     GetSrcFileInfo
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

loop:   MLI_CALL DESTROY, destroy_params
        beq     next_file
        cmp     #ERR_ACCESS_ERROR
        bne     err
        bit     all_flag
        bmi     unlock
        copy    #DeleteDialogLifecycle::locked, delete_dialog_params::phase
        param_call InvokeDialogProc, kIndexDeleteDialog, delete_dialog_params
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
        jsr     SetSrcFileInfo
        jmp     loop

err:    jsr     ShowErrorAlert
        jmp     loop

next_file:
        jmp     RemoveSrcPathSegment
.endproc

;;; ============================================================
;;; Delete directory when exiting via traversal

.proc DeleteFinishDirectory
@retry: MLI_CALL DESTROY, destroy_params
        beq     done
        cmp     #ERR_ACCESS_ERROR
        beq     done
        jsr     ShowErrorAlert
        jmp     @retry
done:   rts
.endproc

.proc RunDeleteDialogProc
        param_jump InvokeDialogProc, kIndexDeleteDialog, delete_dialog_params
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
        operation       = 2 ; performing operation
        close           = 3 ; destroy window
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
        copy16  #UnlockDialogEnumerationCallback, operation_enumeration_callback
        jsr     RunUnlockDialogProc
        copy16  #UnlockDialogCompleteCallback, operation_complete_callback
        rts

        ;; Lock
:       copy16  #LockDialogEnumerationCallback, operation_enumeration_callback
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

.proc RunLockDialogProc
        param_jump InvokeDialogProc, kIndexLockDialog, lock_unlock_dialog_params
.endproc

.proc RunUnlockDialogProc
        param_jump InvokeDialogProc, kIndexUnlockDialog, lock_unlock_dialog_params
.endproc

;;; ============================================================
;;; Handle locking of a selected file.
;;; Calls into the recursion logic of `ProcessDir` as necessary.

.proc LockProcessSelectedFile
        copy    #LockDialogLifecycle::operation, lock_unlock_dialog_params::phase
        jsr     CopyPathsFromBufsToSrcAndDst
        jsr     AppendSrcPathLastSegmentToDstPath

@retry: jsr     GetSrcFileInfo
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
        FALL_THROUGH_TO LockFileCommon

.proc LockFileCommon
        jsr     update_dialog

        jsr     DecrementOpFileCount

@retry: jsr     GetSrcFileInfo
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

:       jsr     SetSrcFileInfo
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
        param_call InvokeDialogProc, kIndexGetSizeDialog, get_size_dialog_params
        copy16  #GetSizeDialogCompleteCallback, operation_complete_callback
        rts
.endproc

.proc GetSizeDialogEnumerationCallback
        copy    #GetSizeDialogLifecycle::count, get_size_dialog_params::phase
        param_jump InvokeDialogProc, kIndexGetSizeDialog, get_size_dialog_params
.endproc

.proc GetSizeDialogConfirmCallback
        copy    #GetSizeDialogLifecycle::prompt, get_size_dialog_params::phase
        param_jump InvokeDialogProc, kIndexGetSizeDialog, get_size_dialog_params
.endproc

.proc GetSizeDialogCompleteCallback
        copy    #GetSizeDialogLifecycle::close, get_size_dialog_params::phase
        param_jump InvokeDialogProc, kIndexGetSizeDialog, get_size_dialog_params

.endproc

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
@retry: jsr     GetSrcFileInfo
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
        ;; Make subsequent call to `AppendFileEntryToSrcPath` a no-op
        copy    #0, file_entry_buf + FileEntry::storage_type_name_length
        FALL_THROUGH_TO SizeOrCountProcessDirectoryEntry
.endproc

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

.proc SizeOrCountProcessDirectoryEntry
        bit     operation_flags
        bvc     :+              ; not size

        ;; If operation is "get size", add the block count to the sum
        lda     file_entry_buf + FileEntry::storage_type_name_length
    IF_NOT_ZERO
        jsr     AppendFileEntryToSrcPath
    END_IF
        jsr     GetSrcFileInfo
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

        MLI_CALL CLOSE, close_params

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
        FALL_THROUGH_TO no_match

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
        MGTK_CALL MGTK::GetEvent, event_params
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
        param_jump InvokeDialogProc, kIndexDeleteDialog, delete_dialog_params
.endproc

.proc DecFileCountAndRunCopyDialogProc
        sub16   op_file_count, #1, copy_dialog_params::count
        param_jump InvokeDialogProc, kIndexCopyDialog, copy_dialog_params
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
.endproc

.proc CopyFileInfo
        COPY_BYTES 11, src_file_info_params::access, dst_file_info_params::access
        rts
.endproc

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
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        bne     close           ; not kAlertResultTryAgain = 0
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
        MLI_CALL ON_LINE, on_line_params2
        rts

.endproc
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
.endproc

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

.proc InvokeDialogProc
        stax    dialog_param_addr
        tya
        asl     a
        tax
        copy16  dialog_proc_table,x, @jump_addr

        lda     #0
        sta     has_input_field_flag
        sta     format_erase_overlay_flag
        sta     cursor_ibeam_flag

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
.endproc

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
        bit     prompt_button_flags
        jvs     check_button_yes

        MGTK_CALL MGTK::InRect, aux::ok_button_rec::rect
        cmp     #MGTK::inrect_inside
        beq     check_button_ok
        jmp     maybe_check_button_cancel

check_button_ok:
        BTK_CALL BTK::Track, aux::ok_button_params
        bmi     :+
        lda     #PromptResult::ok
:       rts

check_button_yes:
        MGTK_CALL MGTK::InRect, aux::yes_button_rec::rect
        cmp     #MGTK::inrect_inside
        bne     check_button_no
        BTK_CALL BTK::Track, aux::yes_button_params
        bmi     :+
        lda     #PromptResult::yes
:       rts

check_button_no:
        MGTK_CALL MGTK::InRect, aux::no_button_rec::rect
        cmp     #MGTK::inrect_inside
        bne     check_button_all
        BTK_CALL BTK::Track, aux::no_button_params
        bmi     :+
        lda     #PromptResult::no
:       rts

check_button_all:
        MGTK_CALL MGTK::InRect, aux::all_button_rec::rect
        cmp     #MGTK::inrect_inside
        bne     maybe_check_button_cancel
        BTK_CALL BTK::Track, aux::all_button_params
        bmi     :+
        lda     #PromptResult::all
:       rts

maybe_check_button_cancel:
        bit     prompt_button_flags
        bpl     check_button_cancel
        return  #$FF

check_button_cancel:
        MGTK_CALL MGTK::InRect, aux::cancel_button_rec::rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        BTK_CALL BTK::Track, aux::cancel_button_params
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
.endproc

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
      END_IF

    ELSE
        ;; No modifiers

        bit     format_erase_overlay_flag
      IF_NS
        cmp     #CHAR_LEFT
        jeq     format_erase_overlay__PromptHandleKeyLeft
        cmp     #CHAR_RIGHT
        jeq     format_erase_overlay__PromptHandleKeyRight
        cmp     #CHAR_UP
        jeq     format_erase_overlay__PromptHandleKeyUp
        cmp     #CHAR_DOWN
        jeq     format_erase_overlay__PromptHandleKeyDown
      END_IF

        cmp     #CHAR_RETURN
      IF_EQ
        bit     prompt_button_flags
        jvc     HandleKeyOk
      END_IF

        cmp     #CHAR_ESCAPE
      IF_EQ
        bit     prompt_button_flags
        jpl     HandleKeyCancel
        jmp     HandleKeyOk
      END_IF

        bit     prompt_button_flags
      IF_VS
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
      END_IF

        bit     has_input_field_flag
      IF_NS
        jsr     IsControlChar ; pass through control characters
        bcc     allow
        jsr     IsFilenameChar
        bcs     ignore
allow:  LETK_CALL LETK::Key, le_params
ignore:
      END_IF

    END_IF
        return  #$FF

        ;; --------------------------------------------------

do_yes: BTK_CALL BTK::Flash, aux::yes_button_params
        return  #PromptResult::yes

do_no:  BTK_CALL BTK::Flash, aux::no_button_params
        return  #PromptResult::no

do_all: BTK_CALL BTK::Flash, aux::all_button_params
        return  #PromptResult::all

.proc HandleKeyOk
        BTK_CALL BTK::Flash, aux::ok_button_params
        return  #0
.endproc

.proc HandleKeyCancel
        BTK_CALL BTK::Flash, aux::cancel_button_params
        return  #1
.endproc

.endproc

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
.endproc

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
        ldx     path_buf1
        beq     ignore

allow:  clc
        rts

ignore: sec
        rts
.endproc

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
.endproc

;;; ============================================================

.proc CopyDialogProc
        ptr := $6

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::phase - copy_dialog_params
        lda     (ptr),y

        ;; --------------------------------------------------
        cmp     #CopyDialogLifecycle::open
    IF_EQ
        copy    #0, has_input_field_flag
        jsr     OpenDialogWindow

        bit     move_flag
      IF_NC
        param_call DrawDialogTitle, aux::str_copy_title
      ELSE
        param_call DrawDialogTitle, aux::str_move_title
      END_IF
        param_call DrawDialogLabel, 2, aux::str_copy_from
        param_jump DrawDialogLabel, 3, aux::str_copy_to
    END_IF

        ;; --------------------------------------------------
        cmp     #CopyDialogLifecycle::count
    IF_EQ
        ldy     #copy_dialog_params::count - copy_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForDialogWindow
        bit     move_flag
      IF_NC
        param_call DrawDialogLabel, 1, aux::str_copy_copying
      ELSE
        param_call DrawDialogLabel, 1, aux::str_move_moving
      END_IF
        jmp     DrawFileCountWithSuffix
    END_IF

        ;; --------------------------------------------------
        cmp     #CopyDialogLifecycle::show
    IF_EQ
        ldy     #copy_dialog_params::count - copy_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForDialogWindow
        jsr     ClearTargetFileRect
        jsr     ClearDestFileRect

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::a_src - copy_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyNameToBuf0
        MGTK_CALL MGTK::MoveTo, aux::current_target_file_pos
        jsr     DrawDialogPathBuf0

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::a_dst - copy_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyNameToBuf1
        MGTK_CALL MGTK::MoveTo, aux::current_dest_file_pos
        param_call DrawDialogPath, path_buf1

        param_call DrawDialogLabel, 4, aux::str_files_remaining
        jmp     DrawFileCountWithTrailingSpaces
    END_IF

        ;; --------------------------------------------------
        cmp     #CopyDialogLifecycle::exists
    IF_EQ
        jsr     SetPortForDialogWindow
        param_call DrawDialogLabel, 6, aux::str_exists_prompt
        jsr     AddYesNoAllCancelButtons
        jsr     Bell
:       jsr     PromptInputLoop
        bmi     :-
        pha
        jsr     EraseYesNoAllCancelButtons
        jsr     ErasePrompt
        pla
        rts
    END_IF

        ;; --------------------------------------------------
        cmp     #CopyDialogLifecycle::too_large
    IF_EQ
        jsr     SetPortForDialogWindow
        bit     move_flag
      IF_NS
        param_call DrawDialogLabel, 6, aux::str_large_move_prompt
      ELSE
        param_call DrawDialogLabel, 6, aux::str_large_copy_prompt
      END_IF
        jsr     AddOkCancelButtons
        jsr     Bell
:       jsr     PromptInputLoop
        bmi     :-
        pha
        jsr     EraseOkCancelButtons
        jsr     ErasePrompt
        pla
        rts
    END_IF

        ;; --------------------------------------------------
        ;; CopyDialogLifecycle::close
        jsr     ClosePromptDialog
        jmp     SetCursorPointer ; when closing dialog
.endproc

;;; ============================================================
;;; "DownLoad" dialog

.proc DownloadDialogProc
        ptr := $6

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::phase - copy_dialog_params
        lda     (ptr),y

        ;; --------------------------------------------------
        cmp     #DownloadDialogLifecycle::open
    IF_EQ
        copy    #0, has_input_field_flag
        jsr     OpenDialogWindow
        param_call DrawDialogTitle, aux::str_download
        param_call DrawDialogLabel, 2, aux::str_copy_from
        param_call DrawDialogLabel, 3, aux::str_copy_to
        rts
    END_IF

        ;; --------------------------------------------------
        cmp     #DownloadDialogLifecycle::count
    IF_EQ
        ldy     #copy_dialog_params::count - copy_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForDialogWindow

        param_call DrawDialogLabel, 1, aux::str_copy_copying
        jmp     DrawFileCountWithSuffix
    END_IF

        ;; --------------------------------------------------
        cmp     #DownloadDialogLifecycle::show
    IF_EQ
        ldy     #copy_dialog_params::count - copy_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForDialogWindow
        jsr     ClearTargetFileRect

        jsr     CopyDialogParamAddrToPtr
        ldy     #copy_dialog_params::a_src - copy_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyNameToBuf0
        MGTK_CALL MGTK::MoveTo, aux::current_target_file_pos
        jsr     DrawDialogPathBuf0

        param_call DrawDialogLabel, 4, aux::str_files_remaining
        jmp     DrawFileCountWithTrailingSpaces
    END_IF

        ;; --------------------------------------------------
        cmp     #DownloadDialogLifecycle::too_large
    IF_EQ
        jsr     SetPortForDialogWindow
        param_call DrawDialogLabel, 6, aux::str_ramcard_full
        jsr     AddOkButton
        jsr     Bell
:       jsr     PromptInputLoop
        bmi     :-
        pha
        jsr     EraseOkButton
        jsr     ErasePrompt
        pla
        rts
    END_IF

        ;; --------------------------------------------------
        ;; DownloadDialogLifecycle::close
        jsr     ClosePromptDialog
        jmp     SetCursorPointer ; when closing dialog
.endproc

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
        param_jump DrawDialogLabel, 2 | DDL_VALUE, text_buffer2::length
    END_IF

        ;; --------------------------------------------------
        cmp     #GetSizeDialogLifecycle::prompt
    IF_EQ
        ;; If no files were seen, `do_count` was never executed and so the
        ;; counts will not be shown. Update one last time, just in case.
        jsr     do_count

        jsr     SetPortForDialogWindow
        jsr     AddOkButton
:       jsr     PromptInputLoop
        bmi     :-
        jsr     EraseDialogLabels
        jsr     EraseOkButton
        return  #0
    END_IF

        ;; --------------------------------------------------
        ;; GetSizeDialogLifecycle::close
        jsr     ClosePromptDialog
        jmp     SetCursorPointer ; when closing dialog
.endproc

;;; ============================================================
;;; "Delete File" dialog

.proc DeleteDialogProc
        ptr := $06

        jsr     CopyDialogParamAddrToPtr
        ldy     #delete_dialog_params::phase - delete_dialog_params
        lda     (ptr),y         ; phase

        ;; --------------------------------------------------
        cmp     #DeleteDialogLifecycle::open
    IF_EQ
        copy    #0, has_input_field_flag
        jsr     OpenDialogWindow
        param_jump DrawDialogTitle, aux::str_delete_title
    END_IF

        ;; --------------------------------------------------
        cmp     #DeleteDialogLifecycle::count
    IF_EQ
        ldy     #delete_dialog_params::count - delete_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForDialogWindow

        param_call DrawDialogLabel, 4, aux::str_delete_ok
        jmp     DrawFileCountWithSuffix
    END_IF

        ;; --------------------------------------------------
        cmp     #DeleteDialogLifecycle::show
    IF_EQ
        ldy     #delete_dialog_params::count - delete_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForDialogWindow
        jsr     ClearTargetFileRect
        jsr     CopyDialogParamAddrToPtr
        ldy     #delete_dialog_params::a_path - delete_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyNameToBuf0
        MGTK_CALL MGTK::MoveTo, aux::current_target_file_pos
        jsr     DrawDialogPathBuf0

        param_call DrawDialogLabel, 4, aux::str_files_remaining
        jmp     DrawFileCountWithTrailingSpaces
    END_IF

        ;; --------------------------------------------------
        cmp     #DeleteDialogLifecycle::confirm
    IF_EQ
        jsr     SetPortForDialogWindow
        jsr     AddOkCancelButtons
        jsr     Bell
:       jsr     PromptInputLoop
        bmi     :-
        bne     :+
        jsr     EraseDialogLabels
        jsr     EraseOkCancelButtons

        param_call DrawDialogLabel, 1, aux::str_delete_count
        jsr     DrawFileCountWithSuffix
        param_call DrawDialogLabel, 2, aux::str_file_colon

        lda     #$00
:       rts
    END_IF

        ;; --------------------------------------------------
        cmp     #DeleteDialogLifecycle::locked
    IF_EQ
        jsr     SetPortForDialogWindow
        param_call DrawDialogLabel, 6, aux::str_delete_locked_file
        jsr     AddYesNoAllCancelButtons
:       jsr     PromptInputLoop
        bmi     :-
        pha
        jsr     EraseYesNoAllCancelButtons
        jsr     ErasePrompt
        pla
        rts
    END_IF

        ;; --------------------------------------------------
        ;; DeleteDialogLifecycle::close
        jsr     ClosePromptDialog
        jmp     SetCursorPointer ; when closing dialog
.endproc

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
        jsr     ClearPathBuf1
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

        jsr     SetPortForDialogWindow
        param_call DrawDialogLabel, 2, aux::str_in
        jsr     DrawDialogPathBuf0
        param_call DrawDialogLabel, 4, aux::str_enter_folder_name
        jsr     InitNameInput

loop:   jsr     PromptInputLoop
        bmi     loop
        bne     do_close

        lda     path_buf1
        beq     loop            ; empty

        lda     path_buf0       ; full path okay?
        clc
        adc     path_buf1
        clc
        adc     #1
        cmp     #::kPathBufferSize
        bcs     too_long

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

too_long:
        lda     #kErrNameTooLong
        jsr     ShowAlert
        jmp     loop

not_run:

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
        jsr     SetCursorPointer ; when closing dialog
        pla
        rts
.endproc

;;; ============================================================
;;; "Lock"/"Unlock" dialog

.proc LockDialogProc
        ptr := $06

        jsr     CopyDialogParamAddrToPtr
        ldy     #lock_unlock_dialog_params::phase - lock_unlock_dialog_params
        lda     (ptr),y

        ;; --------------------------------------------------
        cmp     #LockDialogLifecycle::open
    IF_EQ
        copy    #0, has_input_field_flag
        jsr     OpenDialogWindow
        bit     unlock_flag
      IF_NS
        param_call DrawDialogTitle, aux::label_unlock
      ELSE
        param_call DrawDialogTitle, aux::label_lock
      END_IF
        param_jump DrawDialogLabel, 2, aux::str_file_colon
    END_IF

        ;; --------------------------------------------------
        cmp     #LockDialogLifecycle::count
    IF_EQ
        ldy     #lock_unlock_dialog_params::count - lock_unlock_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForDialogWindow
        bit     unlock_flag
      IF_NS
        param_call DrawDialogLabel, 1, aux::str_unlock_count
      ELSE
        param_call DrawDialogLabel, 1, aux::str_lock_count
      END_IF
        jmp     DrawFileCountWithSuffix
    END_IF

        ;; --------------------------------------------------
        cmp     #LockDialogLifecycle::operation
    IF_EQ
        ldy     #lock_unlock_dialog_params::count - lock_unlock_dialog_params
        copy16in (ptr),y, file_count
        jsr     SetPortForDialogWindow
        jsr     ClearTargetFileRect
        jsr     CopyDialogParamAddrToPtr
        ldy     #lock_unlock_dialog_params::a_path - lock_unlock_dialog_params
        jsr     DereferencePtrToAddr
        jsr     CopyNameToBuf0
        MGTK_CALL MGTK::MoveTo, aux::current_target_file_pos
        jsr     DrawDialogPathBuf0

        param_call DrawDialogLabel, 4, aux::str_files_remaining
        jmp     DrawFileCountWithTrailingSpaces
    END_IF

        ;; --------------------------------------------------
        ;; LockDialogLifecycle::close
do_close:
        jsr     ClosePromptDialog
        jmp     SetCursorPointer ; when closing dialog
.endproc
UnlockDialogProc := LockDialogProc

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

        ;; Populate filename field and input
        ldy     #0
        lda     ($08),y
        tay
:       lda     ($08),y
        sta     buf_filename,y
        sta     path_buf1,y
        dey
        bpl     :-

        param_call DrawDialogLabel, 2, aux::str_rename_old
        param_call DrawString, buf_filename
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

        lda     path_buf1
        beq     :-              ; name is empty, retry

        ldy     #<path_buf1
        ldx     #>path_buf1
        return  #0
    END_IF

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

        ;; Populate filename field and input
        ldy     #0
        lda     ($08),y
        tay
:       lda     ($08),y
        sta     buf_filename,y
        sta     path_buf1,y
        dey
        bpl     :-

        param_call DrawDialogLabel, 2, aux::str_duplicate_original
        param_call DrawString, buf_filename
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

        lda     path_buf1
        beq     :-              ; name is empty, retry

        ldy     #<path_buf1
        ldx     #>path_buf1
        return  #0
    END_IF

        ;; --------------------------------------------------
        ;; DuplicateDialogState::close
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

;;; `file_count` must be populated
.proc DrawFileCountWithSuffix
        jsr     ComposeFileCountString
        param_call DrawString, str_file_count
        param_jump_indirect DrawString, ptr_str_files_suffix
.endproc

;;; `file_count` must be populated
.proc DrawFileCountWithTrailingSpaces
        jsr     ComposeFileCountString
        param_call DrawString, str_file_count
        param_jump DrawString, str_2_spaces
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

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc SetCursorWatch
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        rts
.endproc

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc SetCursorPointer
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts
.endproc

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
.proc SetCursorIBeam
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::ibeam
        rts
.endproc

;;; ============================================================
;;; Double Click Detection
;;; Returns with A=0 if double click, A=$FF otherwise.

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
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
        jsr     AddYesNoAllCancelButtons
        jmp     no_ok

:       jsr     DrawOkButton
no_ok:  bit     prompt_button_flags
        bmi     done
        jsr     DrawCancelButton
done:   rts
.endproc

;;; ============================================================

.proc OpenDialogWindow
        MGTK_CALL MGTK::OpenWindow, winfo_prompt_dialog
        jsr     SetPortForDialogWindow
        jsr     SetPenModeNotCopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, aux::confirm_dialog_frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal
        MGTK_CALL MGTK::SetPenMode, penXOR
        rts
.endproc

;;; ============================================================

.proc SetPortForDialogWindow
        lda     #winfo_prompt_dialog::kWindowId
        jmp     SafeSetPortFromWindowId
.endproc

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
        sub16   #aux::kPromptDialogWidth, result, dialog_label_pos::xcoord
        lsr16   dialog_label_pos::xcoord
        jmp     calc_y
     END_IF

        cmp     #DDL_RIGHT
     IF_EQ
        sub16   #aux::kPromptDialogWidth - kDialogLabelDefaultX, result, dialog_label_pos::xcoord
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
.endproc

;;; ============================================================

.proc DrawDialogPathBuf0
        ldax    #path_buf0
        FALL_THROUGH_TO DrawDialogPath
.endproc

;;; Draw a path (long string) in the prompt dialog by without intruding
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
        cmp16   result, #aux::kPromptDialogPathWidth
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
.endproc

;;; ============================================================

.proc DrawOkButton
        BTK_CALL BTK::Draw, aux::ok_button_params
        rts
.endproc

.proc DrawCancelButton
        BTK_CALL BTK::Draw, aux::cancel_button_params
        rts
.endproc

.proc AddYesNoAllCancelButtons
        BTK_CALL BTK::Draw, aux::yes_button_params
        BTK_CALL BTK::Draw, aux::no_button_params
        BTK_CALL BTK::Draw, aux::all_button_params

        jsr     DrawCancelButton
        copy    #$40, prompt_button_flags
        rts
.endproc

.proc EraseYesNoAllCancelButtons
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, aux::yes_button_rec::rect
        MGTK_CALL MGTK::PaintRect, aux::no_button_rec::rect
        MGTK_CALL MGTK::PaintRect, aux::all_button_rec::rect
        MGTK_CALL MGTK::PaintRect, aux::cancel_button_rec::rect
        rts
.endproc

.proc AddOkCancelButtons
        jsr     DrawOkButton
        jsr     DrawCancelButton
        copy    #$00, prompt_button_flags
        rts
.endproc

.proc EraseOkCancelButtons
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, aux::ok_button_rec::rect
        MGTK_CALL MGTK::PaintRect, aux::cancel_button_rec::rect
        rts
.endproc

.proc AddOkButton
        jsr     DrawOkButton
        copy    #$80, prompt_button_flags
        rts
.endproc

.proc EraseOkButton
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, aux::ok_button_rec::rect
        rts
.endproc

.proc EraseDialogLabels
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        rts
.endproc

.proc ErasePrompt
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, aux::prompt_rect
        rts
.endproc

;;; ============================================================
;;; Draw text, pascal string address in A,X
;;; String must be in aux memory.

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
        MGTK_CALL MGTK::TextWidth, text_params

        sub16   #aux::kPromptDialogWidth, text_width, pos_dialog_title::xcoord
        lsr16   pos_dialog_title::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, pos_dialog_title
        MGTK_CALL MGTK::DrawText, text_params
        rts
.endproc


;;; ============================================================

.proc NoOp
        rts
.endproc

;;; ============================================================

.proc ClearPathBuf1
        copy    #0, path_buf1   ; length
        rts
.endproc

;;; ============================================================
;;; Frames and initializes the line edit control in the prompt
;;; dialog. Call after `path_buf1` is populated so IP is set
;;; correctly.

.proc InitNameInput
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, name_input_rect
        LETK_CALL LETK::Init, le_params
        LETK_CALL LETK::Activate, le_params
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
        MGTK_CALL MGTK::PaintRect, aux::current_target_file_rect
        rts
.endproc

.proc ClearDestFileRect
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, aux::current_dest_file_rect
        rts
.endproc

;;; ============================================================

.proc GetEvent
        MGTK_CALL MGTK::GetEvent, event_params
        rts
.endproc

.proc PeekEvent
        MGTK_CALL MGTK::PeekEvent, event_params
        rts
.endproc

.proc SetPenModeXOR
        MGTK_CALL MGTK::SetPenMode, penXOR
        rts
.endproc

.proc SetPenModeCopy
        MGTK_CALL MGTK::SetPenMode, pencopy
        rts
.endproc

.proc SetPenModeNotCopy
        MGTK_CALL MGTK::SetPenMode, notpencopy
        rts
.endproc

;;; ============================================================

.proc InitSetDesktopPort
        MGTK_CALL MGTK::InitPort, desktop_grafport
        MGTK_CALL MGTK::SetPort, desktop_grafport
        rts
.endproc

;;; ============================================================

.proc ClosePromptDialog
        MGTK_CALL MGTK::CloseWindow, winfo_prompt_dialog
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
.endproc

;;; ============================================================
;;; Outputs: A = kViewBy* value for active window, X = window id
;;; If kViewByIcon, Z=1 and N=0; otherwise Z=0 and N=1

;;; Assert: There is an active window
.proc GetActiveWindowViewBy
        ldx     active_window_id
        lda     win_view_by_table-1,x
        rts
.endproc

;;; Assert: There is a cached window
.proc GetCachedWindowViewBy
        ldx     cached_window_id
        lda     win_view_by_table-1,x
        rts
.endproc

;;; Assert: There is a selection.
;;; NOTE: This variant works even if selection is on desktop
.proc GetSelectionViewBy
        ldx     selected_window_id
        lda     win_view_by_table-1,x
        rts
.endproc

;;; ============================================================

.proc ToggleMenuHilite
        lda     menu_click_params::menu_id
        beq     :+
        MGTK_CALL MGTK::HiliteMenu, menu_click_params
:       rts
.endproc

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

.endproc                        ; WriteWindowInfo

window_id := findwindow_params::window_id

.endproc                        ; save

.proc Open
        MLI_CALL OPEN, open_params
        rts
.endproc

.proc Close
        MLI_CALL CLOSE, close_params
        rts
.endproc

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
.endproc

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

        .assert * < $5000 || (* >= $7800 && * < $9000) || * >= $A000, error, "Routine used by overlays in overlay zone"
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
;;; Window Entry Tables
;;; ============================================================


;;; Input: A = window_id (0=desktop)
.proc LoadWindowEntryTable
        sta     cached_window_id ; TODO: Want this?

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
.endproc

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
.endproc

window_entry_count_table:       .res    ::kMaxDeskTopWindows+1, 0
window_entry_offset_table:      .res    ::kMaxDeskTopWindows+1, 0
window_entry_table:             .res    ::kMaxIconCount, 0

.proc LoadActiveWindowEntryTable
        lda     active_window_id
        jmp     LoadWindowEntryTable
.endproc

.proc LoadDesktopEntryTable
        lda     #0
        jmp     LoadWindowEntryTable
.endproc

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
.endproc

;;; Mark the specified icon as free

.proc FreeIcon
        tay
        dey                     ; 1-based to 0-based
        lda     #0
        sta     free_icon_map,y

        rts
.endproc

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

delete_skip_decrement_flag:     ; always set to 0 ???
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

;;; Computed during startup
width_items_label_padded:
        .word   0
width_left_labels:
        .word   0

;;; Computed during startup
width_items_label:      .word   0
width_k_in_disk_label:  .word   0
width_k_available_label:        .word   0
width_right_labels:     .word   0

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

        kNumFileTypes = 14
type_table:
        .byte   FT_BAD        ; bad block
        .byte   FT_TEXT       ; text
        .byte   FT_BINARY     ; binary
        .byte   FT_FONT       ; font
        .byte   FT_GRAPHICS   ; graphics
        .byte   FT_DIRECTORY  ; directory
        .byte   FT_ADB        ; appleworks db
        .byte   FT_AWP        ; appleworks wp
        .byte   FT_ASP        ; appleworks sp
        .byte   FT_MUSIC      ; music
        .byte   FT_CMD        ; command
        .byte   FT_BASIC      ; basic
        .byte   FT_REL        ; rel
        .byte   FT_SYSTEM     ; system
        ASSERT_TABLE_SIZE type_table, kNumFileTypes

type_names_table:
        ;; Types marked with * are known to BASIC.SYSTEM.
        .byte   "BAD " ; bad block
        .byte   "TXT " ; text *
        .byte   "BIN " ; binary *
        .byte   "FNT " ; font
        .byte   "FOT " ; graphics
        .byte   "DIR " ; directory *
        .byte   "ADB " ; appleworks db *
        .byte   "AWP " ; appleworks wp *
        .byte   "ASP " ; appleworks sp *
        .byte   "MUS " ; music
        .byte   "CMD " ; command *
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
        .byte   0                    ; desk accessory
        .byte   0                    ; basic
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
        .addr   a2d ; desk accessory
        .addr   bas ; basic
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

;;; ============================================================
;;; "Exports"

        Bell := main::Bell
        Multiply_16_8_16 := main::Multiply_16_8_16
        Divide_16_8_16 := main::Divide_16_8_16

;;; ============================================================

        ENDSEG SegmentDeskTopMain
