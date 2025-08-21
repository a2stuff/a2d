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
        LBTKEntry := LBTKRelayImpl
        ITKEntry  := ITKRelayImpl

src_path_buf    := INVOKER_PREFIX
dst_path_buf    := $1F80

        ;; Jump table
        ;; Entries marked with * are used by DAs
        ;; "Exported" by desktop.inc

JT_MGTK_CALL:           jmp     ::MGTKRelayImpl         ; *
JT_MLI_CALL:            jmp     MLIRelayImpl            ; *
JT_CLEAR_UPDATES:       jmp     ClearUpdates            ; *
JT_SYSTEM_TASK:         jmp     SystemTask              ; *
JT_ACTIVATE_WINDOW:     jmp     ActivateAndRefreshWindow ; *
JT_SHOW_ALERT:          jmp     ShowAlert               ; *
JT_SHOW_ALERT_PARAMS:   jmp     ShowAlertStruct         ; *
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
JT_ADJUST_ONLINEENTRY:  jmp     AdjustOnLineEntryCase   ; *
JT_GET_RAMCARD_FLAG:    jmp     GetCopiedToRAMCardFlag  ; *
JT_GET_ORIG_PREFIX:     jmp     CopyDeskTopOriginalPrefix ; *
JT_BELL:                jmp     Bell                    ; *
JT_SLOW_SPEED:          jmp     SlowSpeed               ; *
JT_RESUME_SPEED:        jmp     ResumeSpeed             ; *
JT_READ_SETTING:        jmp     ReadSetting             ; *
JT_GET_TICKS:           jmp     GetTickCount            ; *

        ASSERT_EQUALS ::JUMP_TABLE_LAST, *

.macro PROC_USED_IN_OVERLAY
        .assert * < OVERLAY_BUFFER || * >= OVERLAY_BUFFER + kOverlayBufferSize, error, "Routine used by overlays in overlay zone"
.endmacro

;;; ============================================================
;;; Main event loop for the application

.proc MainLoop

        ;; Poll drives every Nth time `SystemTask` does its thing.
        ;; At 1MHz on a //e this is about once every 3 seconds.
        kDrivePollFrequency = 35

        ;; Close any windows that are not longer valid, if necessary
        jsr     ValidateWindows

        ;; Enable/disable menu items, based on windows/selection
        jsr     UpdateMenuItemStates

        ;; Can loop to here if no state changed
loop:
        jsr     SystemTask
    IF_ZERO
        ;; Maybe poll drives for updates
        dec     counter
      IF_NEG
        copy8   #kDrivePollFrequency, counter
        jsr     CheckDiskInsertedEjected
        jmp     MainLoop
      END_IF
    END_IF

        ;; Get an event
        jsr     GetNextEvent

        ;; Did the mouse move?
        cmp     #kEventKindMouseMoved
    IF_EQ
        jsr     ClearTypeDown
        jmp     loop            ; no state change
    END_IF

        ;; Is it a key down event?
        cmp     #MGTK::EventKind::key_down
    IF_EQ
        jsr     HandleKeydown
        jmp     MainLoop
    END_IF

        ;; Is it a button-down event? (including w/ modifiers)
        cmp     #MGTK::EventKind::button_down
        beq     click
        cmp     #MGTK::EventKind::apple_key
        bne     :+
click:
        jsr     ClearTypeDown
        jsr     HandleClick
        jmp     MainLoop
:

        ;; Is it an update event?
        cmp     #MGTK::EventKind::update
    IF_EQ
        jsr     ClearUpdatesNoPeek
    END_IF

        jmp     loop

counter:
        .byte   0

.endproc ; MainLoop

;;; ============================================================
;;; Clear Updates
;;; MGTK sends a update event when a window needs to be redrawn
;;; because it was revealed by another operation (e.g. close).
;;; This is called implicitly during the main loop if an update
;;; event is seen, and also explicitly following operations
;;; (e.g. a window close followed by a nested loop or slow
;;; file operation).

.proc ClearUpdatesImpl

;;; Caller already called GetEvent, no need to PeekEvent;
;;; just jump directly into the clearing loop.
clear_no_peek := handle_update

;;; Clear any pending updates.
clear:
        FALL_THROUGH_TO loop

        ;; --------------------------------------------------
loop:
        jsr     PeekEvent
        lda     event_params::kind
        cmp     #MGTK::EventKind::update
        bne     finish
        jsr     GetEvent        ; no need to synthesize events

handle_update:
        MGTK_CALL MGTK::BeginUpdate, event_params::window_id
        bne     loop            ; obscured
        lda     event_params::window_id
    IF_ZERO
        ;; Desktop
        ITK_CALL IconTK::DrawAll, event_params::window_id
    ELSE
        ;; Window
        jsr     UpdateWindow
    END_IF
        MGTK_CALL MGTK::EndUpdate
        jmp     loop

finish:
        rts
.endproc ; ClearUpdatesImpl
ClearUpdatesNoPeek := ClearUpdatesImpl::clear_no_peek
ClearUpdates := ClearUpdatesImpl::clear

;;; ============================================================
;;; Called by main and nested event loops to do periodic tasks.
;;; Returns 0 if the periodic tasks were run.

        PROC_USED_IN_OVERLAY
.proc SystemTask
        inc     tick_counter
        bne     :+
        inc     tick_counter+1
        bne     :+
        inc     tick_counter+2
:
        inc     loop_counter
        inc     loop_counter
        loop_counter := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     periodic_task_delay    ; for per-machine timing
        bcc     :+
        copy8   #0, loop_counter

        jsr     ShowClock
        jsr     ResetIIgsRGB   ; in case it was reset by control panel

:       lda     loop_counter
        rts
.endproc ; SystemTask

;;; ============================================================

.proc GetTickCount
        lda     tick_counter
        ldx     tick_counter+1
        ldy     tick_counter+2
        rts
.endproc ; GetTickCount

tick_counter:
        .faraddr 0

;;; ============================================================

;;; Inputs: A = `window_id` from `update` event
.proc UpdateWindow
        cmp     #kMaxDeskTopWindows+1 ; directory windows are 1-8
        RTS_IF_GE

        jsr     LoadWindowEntryTable

        ;; This correctly uses the clipped port provided by BeginUpdate.

        ;; `DrawWindowHeader` relies on `window_grafport` for dimensions
        copy8   cached_window_id, getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        jsr     DrawWindowHeader

        ;; `AdjustUpdatePortForEntries` also relies on `window_grafport`
        jsr     AdjustUpdatePortForEntries
        jsr     DrawWindowEntries

        rts
.endproc ; UpdateWindow

;;; ============================================================
;;; Menu Dispatch

.proc HandleKeydown
        ;; Handle accelerator keys
        lda     event_params::modifiers
        bne     modifiers       ; either Open-Apple or Solid-Apple ?

        ;; --------------------------------------------------
        ;; No modifiers

        lda     event_params::key
        jsr     CheckTypeDown
        RTS_IF_ZERO

        jsr     ClearTypeDown

        lda     event_params::key
        cmp     #CHAR_LEFT
        jeq     KeyboardHighlightLeft
        cmp     #CHAR_UP
        jeq     KeyboardHighlightUp
        cmp     #CHAR_RIGHT
        jeq     KeyboardHighlightRight
        cmp     #CHAR_DOWN
        jeq     KeyboardHighlightDown
        cmp     #CHAR_TAB
        jeq     KeyboardHighlightAlpha
        cmp     #'`'
        jeq     KeyboardHighlightAlphaNext ; like Tab
        cmp     #'~'
        jeq     KeyboardHighlightAlphaPrev ; like Shift+Tab
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
        jsr     ToUpperCase
        cmp     #res_char_menu_item_open_shortcut
        jeq     CmdOpenThenCloseCurrent
        cmp     #CHAR_DOWN
        jeq     CmdOpenThenCloseCurrent
        cmp     #CHAR_UP
        jeq     CmdOpenParentThenCloseCurrent
        cmp     #kShortcutCloseWindow
        jeq     CmdCloseAll
        cmp     #CHAR_CTRL_F
        jeq     CmdFlipScreen
        rts
    END_IF

        ;; Non-menu keys
        lda     event_params::key
        jsr     ToUpperCase
        cmp     #CHAR_DOWN      ; Apple-Down (Open)
        jeq     CmdOpenFromKeyboard
        cmp     #CHAR_UP        ; Apple-Up (Open Parent)
        jeq     CmdOpenParent

        ldx     active_window_id
    IF_NOT_ZERO
        cmp     #kShortcutGrowWindow ; Apple-G (Resize)
        jeq     CmdResize
        cmp     #kShortcutMoveWindow  ; Apple-M (Move)
        jeq     CmdMove
        cmp     #kShortcutScrollWindow ; Apple-S (Scroll)
        jeq     CmdScroll
        cmp     #'`'            ; Apple-` (Cycle Windows)
        beq     cycle
        cmp     #'~'            ; Shift-Apple-` (Cycle Windows)
        beq     cycle
        cmp     #CHAR_TAB       ; Apple-Tab (Cycle Windows)
        bne     :+
cycle:  jmp     CmdCycleWindows
:
    END_IF

        ;; Not one of our shortcuts - check for menu keys
        ;; (shortcuts or entering keyboard menu mode)
menu_accelerators:
        copy8   event_params::key, menu_click_params::which_key
        copy8   event_params::modifiers, menu_click_params::key_mods
        copy8   #0, menu_modified_click_flag ; note that source is not Apple+click
        MGTK_CALL MGTK::MenuKey, menu_click_params

        FALL_THROUGH_TO MenuDispatch
.endproc ; HandleKeydown

.proc MenuDispatch
        ldx     menu_click_params::menu_id
        RTS_IF_ZERO

        dex                     ; x has top level menu id
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
        copy8   #0, menu_click_params::menu_id ; for `ToggleMenuHilite`
        rts

call_proc:
        tsx
        stx     saved_stack
        proc_addr := *+1
        jmp     SELF_MODIFIED


        ;; Keep in sync with aux::menu_item_id_*

        ;; jump table for menu item handlers
dispatch_table:
        ;; Apple menu (1)
        menu1_start := *
        .addr   CmdAbout
        .addr   CmdAboutThisApple
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

        ;; Edit menu (3)
        menu3_start := *
        .addr   CmdCut
        .addr   CmdCopy
        .addr   CmdPaste
        .addr   CmdClear
        .addr   CmdNoOp         ; --------
        .addr   CmdSelectAll
        ASSERT_ADDRESS_TABLE_SIZE menu3_start, ::kMenuSizeEdit

        ;; View menu (4)
        menu4_start := *
        .addr   CmdViewBy
        .addr   CmdViewBy
        .addr   CmdViewBy
        .addr   CmdViewBy
        .addr   CmdViewBy
        .addr   CmdViewBy
        ASSERT_ADDRESS_TABLE_SIZE menu4_start, ::kMenuSizeView

        ;; Special menu (5)
        menu5_start := *
        .addr   CmdCheckDrives
        .addr   CmdCheckDrive
        .addr   CmdEject
        .addr   CmdNoOp         ; --------
        .addr   CmdFormatDisk
        .addr   CmdEraseDisk
        .addr   CmdDiskCopy
        .addr   CmdNoOp         ; --------
        .addr   CmdMakeLink
        .addr   CmdShowLink
        ASSERT_ADDRESS_TABLE_SIZE menu5_start, ::kMenuSizeSpecial

        ;; Startup menu (6)
        menu6_start := *
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        .addr   CmdStartupItem
        ASSERT_ADDRESS_TABLE_SIZE menu6_start, ::kMenuSizeStartup

        ;; Selector menu (7)
        menu7_start := *
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
        ASSERT_ADDRESS_TABLE_SIZE menu7_start, ::kMenuSizeSelector

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
        .byte   menu_end - dispatch_table
        ASSERT_TABLE_SIZE offset_table, ::kMenuNumItems+1
.endproc ; MenuDispatch

;;; ============================================================
;;; Handle click

.proc HandleClick
        tsx
        stx     saved_stack
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        bne     not_desktop

        ;; Click on desktop
        lda     #0
        sta     clicked_window_id
        sta     findwindow_params::window_id
        ITK_CALL IconTK::FindIcon, event_params::coords
        lda     findicon_params::which_icon
        jne     _IconClick

        lda     #0
        jmp     DragSelect

not_desktop:
        cmp     #MGTK::Area::menubar  ; menu?
        bne     not_menu

        ;; Maybe clock?
        lda     MACHID
        and     #%00000001      ; bit 0 = clock card
    IF_NE
        cmp16   event_params::xcoord, #460 ; TODO: Hard coded?
      IF_CS
        param_jump InvokeDeskAccWithIcon, $FF, str_date_and_time
      END_IF
    END_IF

        ;; Note if menu showing via modified click
        jsr     ModifierDown
        sta     menu_modified_click_flag

        MGTK_CALL MGTK::MenuSelect, menu_click_params

        ;; But allow double-modifier click or shortcut too
        lda     BUTN0
        and     BUTN1
        ora     menu_modified_click_flag
        sta     menu_modified_click_flag

        jmp     MenuDispatch

not_menu:
        jsr     window_click

        lda     selected_icon_count
    IF_ZERO
        ;; Try to select the window's parent icon.
        lda     active_window_id
      IF_NOT_ZERO
        jsr     GetWindowPath
        jsr     IconToAnimate
        jmp     SelectIcon
      END_IF
    END_IF
        rts

window_click:
        cmp     #MGTK::Area::content
        beq     _ContentClick

        pha                     ; A = MGTK::Area::*
        ;; Activate if needed
        lda     findwindow_params::window_id
        jsr     ActivateWindow  ; no-op if already active
        pla                     ; A = MGTK::Area::*

        cmp     #MGTK::Area::dragbar
        jeq     DoWindowDrag
        cmp     #MGTK::Area::grow_box
        jeq     DoWindowResize
        cmp     #MGTK::Area::close_box
        jeq     HandleCloseClick
        rts

;;; --------------------------------------------------

.proc _ContentClick
        lda     findwindow_params::window_id
        sta     clicked_window_id
        sta     findcontrolex_params::window_id

        MGTK_CALL MGTK::FindControlEx, findcontrolex_params
        lda     findcontrol_params::which_ctl

        ASSERT_EQUALS MGTK::Ctl::not_a_control, 0
    IF_ZERO
        ;; Ignore clicks in the header area
        copy8   clicked_window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     screentowindow_params::windowy
        cmp     #kWindowHeaderHeight
      IF_LT
        jmp     _ActivateClickedWindow ; no-op if already active
      END_IF

        ;; On an icon?
        copy8   clicked_window_id, findicon_params::window_id
        ITK_CALL IconTK::FindIcon, findicon_params
        lda     findicon_params::which_icon
        jne     _IconClick

        ;; Not an icon - maybe a drag?
        jsr     _ActivateClickedWindow ; no-op if already active
        lda     active_window_id
        jmp     DragSelect
    END_IF

        ;; --------------------------------------------------

        cmp     #MGTK::Ctl::dead_zone
        jeq     _ActivateClickedWindow ; no-op if already active

        cmp     #MGTK::Ctl::vertical_scroll_bar
    IF_EQ
        ;; Vertical scrollbar
        lda     clicked_window_id
        cmp     active_window_id
        jne     ActivateWindow

        jsr     GetWindowPtr
        stax    $06
        ldy     #MGTK::Winfo::vscroll
        lda     ($06),y
        and     #MGTK::Scroll::option_active
        RTS_IF_EQ

        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::thumb
        jeq     _TrackThumb

        cmp     #MGTK::Part::up_arrow
      IF_EQ
:       jsr     ScrollUp
        lda     #MGTK::Part::up_arrow
        jsr     _CheckControlRepeat
        bpl     :-
        rts
      END_IF

        cmp     #MGTK::Part::down_arrow
      IF_EQ
:       jsr     ScrollDown
        lda     #MGTK::Part::down_arrow
        jsr     _CheckControlRepeat
        bpl     :-
        rts
      END_IF

        cmp     #MGTK::Part::page_up
      IF_EQ
:       jsr     ScrollPageUp
        lda     #MGTK::Part::page_up
        jsr     _CheckControlRepeat
        bpl     :-
        rts
      END_IF

:       jsr     ScrollPageDown
        lda     #MGTK::Part::page_down
        jsr     _CheckControlRepeat
        bpl     :-
        rts
    END_IF

        ;; Horizontal scrollbar
        lda     clicked_window_id
        cmp     active_window_id
        jne     ActivateWindow

        jsr     GetWindowPtr
        stax    $06
        ldy     #MGTK::Winfo::hscroll
        lda     ($06),y
        and     #MGTK::Scroll::option_active
        RTS_IF_EQ

        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::thumb
        jeq     _TrackThumb

        cmp     #MGTK::Part::left_arrow
      IF_EQ
:       jsr     ScrollLeft
        lda     #MGTK::Part::left_arrow
        jsr     _CheckControlRepeat
        bpl     :-
        rts
      END_IF

        cmp     #MGTK::Part::right_arrow
      IF_EQ
:       jsr     ScrollRight
        lda     #MGTK::Part::right_arrow
        jsr     _CheckControlRepeat
        bpl     :-
        rts
      END_IF

        cmp     #MGTK::Part::page_left
      IF_EQ
:       jsr     ScrollPageLeft
        lda     #MGTK::Part::page_left
        jsr     _CheckControlRepeat
        bpl     :-
        rts
      END_IF

:       jsr     ScrollPageRight
        lda     #MGTK::Part::page_right
        jsr     _CheckControlRepeat
        bpl     :-
        rts

;;; ------------------------------------------------------------

.proc _TrackThumb
        lda     findcontrol_params::which_ctl
        sta     trackthumb_params::which_ctl
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        RTS_IF_ZERO

        lda     trackthumb_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     :+
        jmp     ScrollTrackVThumb
:       jmp     ScrollTrackHThumb
.endproc ; _TrackThumb

;;; ------------------------------------------------------------
;;; Handle mouse held down on scroll arrow/pager

.proc _CheckControlRepeat
        ctl := $06

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
        cmp     ctl
        bne     bail
        return  #0              ; high bit set = repeating
.endproc ; _CheckControlRepeat

.endproc ; _ContentClick

;;; ------------------------------------------------------------
;;; Handle a click on an icon, either windowed or desktop. They
;;; are processed the same way, unless a drag occurs.
;;; Input: A = icon
;;;   `findicon_params::which_icon` and `findicon_params::window_id`
;;;   must still be populated

.proc _IconClick
        pha
        jsr     GetSingleSelectedIcon
        sta     prev_selected_icon
        pla

        jsr     IsIconSelected
        bne     not_selected

        ;; --------------------------------------------------
        ;; Icon was already selected
        jsr     ExtendSelectionModifierDown
        bpl     :+

        ;; Modifier down - remove from selection
        lda     findicon_params::which_icon
        jsr     UnhighlightAndDeselectIcon
        jmp     _ActivateClickedWindow ; no-op if already active

        ;; Double click or drag?
:       jmp     check_double_click

        ;; --------------------------------------------------
        ;; Icon was not already selected
not_selected:
        jsr     ExtendSelectionModifierDown
        bpl     replace_selection

        ;; Modifier down - add to selection
        lda     selected_icon_count
        beq     replace_selection
        lda     findicon_params::window_id
        cmp     selected_window_id
        bne     replace_selection
        lda     findicon_params::which_icon
        jsr     AddIconToSelection
        jmp     check_double_click

        ;; Replace selection with clicked icon
replace_selection:
        lda     findicon_params::which_icon
        jsr     SelectIcon
        FALL_THROUGH_TO check_double_click

        ;; --------------------------------------------------
check_double_click:
        ;; Stash initial coords so dragging is accurate.
        COPY_STRUCT MGTK::Point, event_params::coords, drag_drop_params::coords

        jsr     DetectDoubleClick
    IF_NC
        jsr     _ActivateClickedWindow ; no-op if already active
        jmp     CmdOpenFromDoubleClick
    END_IF

        ;; --------------------------------------------------
        ;; Drag of icon

        copy8   findicon_params::which_icon, drag_drop_params::icon
        ITK_CALL IconTK::DragHighlighted, drag_drop_params

        cmp     #IconTK::kDragResultCanceled
        RTS_IF_EQ

        cmp     #IconTK::kDragResultNotADrag
    IF_EQ
        jsr     _ActivateClickedWindow ; no-op if already active
        jmp     _CheckRenameClick
    END_IF

        ;; ----------------------------------------

        cmp     #IconTK::kDragResultMove
    IF_EQ
        jsr     RedrawSelectedIcons

        jsr     _ActivateClickedWindow ; no-op if already active

        lda     selected_window_id
        RTS_IF_ZERO

        jmp     ScrollUpdate
    END_IF

        ;; ----------------------------------------
        ;; File drop on same window:
        ;; * No modifiers - move (see `kDragResultMove` case above)
        ;; * Single modifier - duplicate
        ;; * Double modifiers - make link

        ;; Volume drop on desktop:
        ;; * No modifiers - move (see `kDragResultMove` case above)
        ;; * Single modifier - ignore
        ;; * Double modifiers - ignore

        cmp     #IconTK::kDragResultMoveModified
    IF_EQ
        lda     selected_window_id
        RTS_IF_ZERO

        jsr     _ActivateClickedWindow

        ;; File drop on same window, but with modifier(s) down so not a move

        jsr     GetSingleSelectedIcon
        RTS_IF_ZERO

        ;; Double modifier?
        lda     BUTN0
        and     BUTN1
      IF_NS
        jsr     SetPathBuf4FromDragDropResult
        RTS_IF_CS               ; failure, e.g. path too long
        jmp     MakeLinkInTarget
      END_IF

        ;; Single modifier
        jmp     CmdDuplicate
    END_IF

        ;; ----------------------------------------
        ;; A = `IconTK::kDragResultDrop`

        ;; File drop on target:
        ;; * No modifiers - copy/move (depending on other/same vol)
        ;; * Single modifier - copy/move (ditto, but opposite)
        ;; * Double modifiers - make link

        ;; Volume drop on target:
        ;; * No modifiers - copy
        ;; * Single modifier - copy
        ;; * Double modifiers - make link

        lda     drag_drop_params::target

        ;; Trash?
        cmp     trash_icon_num
    IF_EQ
        lda     selected_window_id
        jeq     CmdEject
        jmp     CmdDeleteSelection
    END_IF

        ;; Desktop?
        cmp     #$80
        RTS_IF_EQ               ; ignore

        ;; Path for target
        jsr     SetPathBuf4FromDragDropResult
        RTS_IF_CS               ; failure, e.g. path too long

        ;; Double modifier?
        lda     BUTN0
        and     BUTN1
    IF_NS
        jsr     GetSingleSelectedIcon
        RTS_IF_ZERO
        jmp     MakeLinkInTarget
    END_IF

        ;; Copy/Move
        jsr     DoCopyOrMoveSelection
        jmp     _PerformPostDropUpdates
.endproc ; _IconClick

;;; ------------------------------------------------------------

;;; Used during icon click to trigger rename
prev_selected_icon:
        .byte   0

;;; Prior to processing the click, `prev_selected_icon` should
;;; be set to the result of `GetSingleSelectedIcon`.
.proc _CheckRenameClick
        jsr     GetSingleSelectedIcon
        cmp     prev_selected_icon
        bne     ret
        cmp     trash_icon_num
        beq     ret
        sta     icon_param
        ITK_CALL IconTK::GetRenameRect, icon_param
        MGTK_CALL MGTK::MoveTo, event_params::coords
        MGTK_CALL MGTK::InRect, tmp_rect
        jne     CmdRename
ret:    rts
.endproc ; _CheckRenameClick

;;;------------------------------------------------------------
;;; After an icon drop (file or volume), update any affected
;;; windows.
;;; Inputs: A = `kOperationXYZ`, and `drag_drop_params::target`

.proc _PerformPostDropUpdates
        ;; --------------------------------------------------
        ;; (1/4) Canceled?

        cmp     #kOperationCanceled
        RTS_IF_EQ

        ;; --------------------------------------------------
        ;; (2/4) Was a move?
        ;; NOTE: Only applies in file icon case.

        bit     operations__move_flag
    IF_NS
        ;; Update source vol's contents
        jsr     MaybeStashDropTargetName ; in case target is in window...
        jsr     UpdateActivateAndRefreshSelectedWindow
        jsr     MaybeUpdateDropTargetFromName ; ...restore after update.
    END_IF

        ;; --------------------------------------------------
        ;; (3/4) Dropped on icon?

        lda     drag_drop_params::target
    IF_POS
        ;; Yes, on an icon; update used/free for same-vol windows
        pha
        jsr     GetIconPath     ; `path_buf3` set to path, A=0 on success
      IF_ZERO
        param_call UpdateUsedFreeViaPath, path_buf3
      END_IF
        pla
        jsr     FindWindowIndexForDirIcon ; X = window id-1 if found
      IF_EQ
        inx
        txa
        jmp     ActivateAndRefreshWindowOrClose
      END_IF
        rts
    END_IF

        ;; --------------------------------------------------
        ;; (4/4) Dropped on window!

        and     #$7F            ; mask off window number
        jmp     UpdateActivateAndRefreshWindow
.endproc ; _PerformPostDropUpdates


.proc _ActivateClickedWindow
        window_id := *+1
        lda     #SELF_MODIFIED_BYTE
        jmp     ActivateWindow
.endproc ; _ActivateClickedWindow
clicked_window_id := _ActivateClickedWindow::window_id

.endproc ; HandleClick

;;; ============================================================
;;; Activate the window, draw contents, and update menu items
;;; No-op if the window is already active, or if 0 passed.
;;; Inputs: A = window id to activate

.proc ActivateWindow
        cmp     active_window_id
        RTS_IF_EQ

        cmp     #0
        RTS_IF_EQ

        ;; Make the window active.
        sta     active_window_id
        MGTK_CALL MGTK::SelectWindow, active_window_id

        ;; Repaint the contents
        jsr     UpdateWindowUsedFreeDisplayValues
        jsr     LoadActiveWindowEntryTable
        FALL_THROUGH_TO DrawCachedWindowHeaderAndEntries
.endproc ; ActivateWindow

;;; ============================================================

.proc DrawCachedWindowHeaderAndEntries
        lda     cached_window_id
        jsr     UnsafeSetPortFromWindowId ; CHECKED
    IF_ZERO
        jsr     DrawWindowHeader
        jsr     AdjustWindowPortForEntries
        jsr     DrawWindowEntries
    END_IF
        rts
.endproc ; DrawCachedWindowHeaderAndEntries

;;; ============================================================
;;; Redraw the active window's entries. The header is not redrawn.

.proc ClearAndDrawActiveWindowEntries
        lda     active_window_id
        jsr     UnsafeSetPortFromWindowIdAndAdjustForEntries ; CHECKED
    IF_ZERO
        MGTK_CALL MGTK::PaintRect, window_grafport::maprect
        jsr     DrawWindowEntries
    END_IF
        rts
.endproc ; ClearAndDrawActiveWindowEntries

;;; ============================================================

;;; Used only for file windows; adjusts port to account for header.
;;; Returns 0 if ok, `MGTK::Error::window_obscured` if the window is obscured.
.proc UnsafeSetPortFromWindowIdAndAdjustForEntries
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     :+              ; MGTK::Error::window_obscured
        jsr     AdjustWindowPortForEntries
:       rts
.endproc ; UnsafeSetPortFromWindowIdAndAdjustForEntries

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
        PROC_USED_IN_OVERLAY
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
        copy8   disk_in_device_table,x, last_disk_in_devices_table,x

        lda     removable_device_table,x
        ldy     DEVCNT
:       cmp     DEVLST,y
        beq     :+
        dey
        bpl     :-
        rts
:
        sty     drive_to_refresh ; DEVLST index
        jsr     CheckDriveByIndex
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

;;; Preserves Y
.proc CheckDisksInDevices
        status_buffer := $800

        tya                     ; preserve Y
        pha

        ldx     removable_device_table
        beq     done
        stx     disk_in_device_table
:       lda     removable_device_table,x
        jsr     check_disk_in_drive
        sta     disk_in_device_table,x
        dex
        bne     :-
done:
        pla
        tay                     ; restore Y
        rts

;;; Input: A = unit_number
;;; Preserves X
check_disk_in_drive:
        tay                     ; Y = unit_number
        txa                     ; preserve X
        pha
        tya                     ; A = unit_number

        jsr     FindSmartportDispatchAddress
    IF_CC                       ; is SmartPort
        stax    dispatch
        sty     status_unit_num

        ;; Execute SmartPort call
        dispatch := *+1
        jsr     SELF_MODIFIED
        .byte   SPCall::Status
        .addr   status_params

        lda     status_buffer
        and     #$10            ; general status byte, $10 = disk in drive
      IF_NOT_ZERO
        ldy     #$FF            ; is SmartPort and disk in drive
        bne     finish          ; always
      END_IF
    END_IF

        ldy     #0              ; not SmartPort or no disk in drive

finish: pla
        tax                     ; restore X
        tya                     ; A = result
        rts

        ;; params for call
        DEFINE_SP_STATUS_PARAMS status_params, 1, status_buffer, 0
        status_unit_num := status_params::unit_num
.endproc ; CheckDisksInDevices

;;; ============================================================

.proc UpdateMenuItemStates
        ;; Flags, or'd together to represent current state

        kWindowOpen   = %00000001
        kHasShortcuts = %00000010
        kHasSelection = %00000100
        kSingleSel    = %00001000
        kFileSel      = %00010000
        kVolSel       = %00100000
        kLinkSel      = %01000000

        ;; --------------------------------------------------
        ;; Windows

        jsr     _UncheckViewMenuItem
        lda     active_window_id
    IF_NOT_ZERO
        jsr     GetActiveWindowViewBy
        and     #DeskTopSettings::kViewByIndexMask
        tax
        inx
        stx     checkitem_params::menu_item
        jsr     _CheckViewMenuItem

        lda     #kWindowOpen    ; A = flags (initial value)
        ldx     #MGTK::disablemenu_enable
    ELSE
        lda     #0              ; A = flags (initial value)
        ldx     #MGTK::disablemenu_disable
    END_IF
        pha                     ; A = flags
        stx     disablemenu_params::disable
        MGTK_CALL MGTK::DisableMenu, disablemenu_params
        pla                     ; A = flags

        ;; --------------------------------------------------
        ;; Selector List

        ldx     num_selector_list_items
    IF_NOT_ZERO
        ora     #kHasShortcuts  ; A = flags
    END_IF

        ;; --------------------------------------------------
        ;; Selected Icons

        ldx     selected_icon_count
    IF_NOT_ZERO
        ;; Single?
        cpx     #1
      IF_EQ
        ldx     selected_icon_list ; X = icon id
        cpx     trash_icon_num
        beq     set_flags       ; trash only - treat as no selection
        ora     #kSingleSel     ; A = flags

        ;; Link?
        pha                     ; A = flags
        txa                     ; A = icon id
        jsr     GetIconEntry
        ptr := $06
        stax    ptr
        ldy     #IconEntry::type
        lda     (ptr),y
        tax                     ; X = icon type
        pla                     ; A = flags
        cpx     #IconType::link
       IF_EQ
        ora     #kLinkSel       ; A = flags
       END_IF
      END_IF

        ;; Files or Volumes?
        ldx     selected_window_id ; In a window?
      IF_NOT_ZERO
        ora     #kHasSelection | kFileSel ; A = flags
      ELSE
        ora     #kHasSelection | kVolSel ; A = flags
      END_IF
    END_IF

set_flags:
        sta     flags

        ;; --------------------------------------------------
        ;; Update the menus

        ldy     #0
loop:   lda     table,y         ; menu_id
        RTS_IF_ZERO
        sta     disableitem_params::menu_id
        iny

        lda     table,y         ; menu_item
        sta     disableitem_params::menu_item
        iny

        ldx     #MGTK::disableitem_disable
        lda     table,y         ; flags
        flags := *+1
        and     #SELF_MODIFIED_BYTE
        cmp     table,y
    IF_EQ
        ldx     #MGTK::disableitem_enable
    END_IF
        stx     disableitem_params::disable
        iny

        tya
        pha
        MGTK_CALL MGTK::DisableItem, disableitem_params
        pla
        tay
        bne     loop            ; always

        ;; menu id, item id, required flags
table:
        .byte   kMenuIdFile, aux::kMenuItemIdNewFolder,       kWindowOpen
        .byte   kMenuIdFile, aux::kMenuItemIdOpen,            kHasSelection
        .byte   kMenuIdFile, aux::kMenuItemIdClose,           kWindowOpen
        .byte   kMenuIdFile, aux::kMenuItemIdCloseAll,        kWindowOpen
        .byte   kMenuIdFile, aux::kMenuItemIdGetInfo,         kHasSelection
        .byte   kMenuIdFile, aux::kMenuItemIdRenameIcon,      kSingleSel
        .byte   kMenuIdFile, aux::kMenuItemIdDuplicate,       kSingleSel | kFileSel
        .byte   kMenuIdFile, aux::kMenuItemIdCopySelection,   kHasSelection
        .byte   kMenuIdFile, aux::kMenuItemIdDeleteFile,      kFileSel

        .byte   kMenuIdEdit, aux::kMenuItemIdCut,             kSingleSel
        .byte   kMenuIdEdit, aux::kMenuItemIdCopy,            kSingleSel
        .byte   kMenuIdEdit, aux::kMenuItemIdPaste,           kSingleSel
        .byte   kMenuIdEdit, aux::kMenuItemIdClear,           kSingleSel

        .byte   kMenuIdSpecial, aux::kMenuItemIdCheckDrive,   kVolSel
        .byte   kMenuIdSpecial, aux::kMenuItemIdEject,        kVolSel
        .byte   kMenuIdSpecial, aux::kMenuItemIdMakeLink,     kSingleSel | kFileSel
        .byte   kMenuIdSpecial, aux::kMenuItemIdShowOriginal, kLinkSel

        .byte   kMenuIdSelector, kMenuItemIdSelectorEdit,     kHasShortcuts
        .byte   kMenuIdSelector, kMenuItemIdSelectorDelete,   kHasShortcuts
        .byte   kMenuIdSelector, kMenuItemIdSelectorRun,      kHasShortcuts

        .byte   0               ; sentinel

;;; ------------------------------------------------------------

;;; Inputs: A = MGTK::checkitem_check or MGTK::checkitem_uncheck
;;; Assumes checkitem_params::menu_item has been updated or is last checked.
.proc _CheckViewMenuItemImpl
check:  lda     #MGTK::checkitem_check
        SKIP_NEXT_2_BYTE_INSTRUCTION
        ASSERT_NOT_EQUALS MGTK::checkitem_uncheck, $C0, "Bad BIT skip"
uncheck:lda     #MGTK::checkitem_uncheck

        sta     checkitem_params::check
        MGTK_CALL MGTK::CheckItem, checkitem_params
        rts
.endproc ; _CheckViewMenuItemImpl
_CheckViewMenuItem := _CheckViewMenuItemImpl::check
_UncheckViewMenuItem := _CheckViewMenuItemImpl::uncheck

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
        copy8   #7, src_file_info_params::param_count ; SET_FILE_INFO
        MLI_CALL SET_FILE_INFO, src_file_info_params
        pha
        copy8   #$A, src_file_info_params::param_count ; GET_FILE_INFO
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
        clc
        bcc     :+              ; always
sys_disk:
        sec
:       ror     sys_prompt_flag

        jsr     SetCursorWatch ; before invoking

        ;; Easiest to assume absolute path later.
        jsr     _MakeSrcPathAbsolute ; Trashes `INVOKER_INTERPRETER`

        ;; Assume no interpreter to start
        lda     #0
        sta     INVOKER_INTERPRETER
        sta     INVOKER_BITSY_COMPAT

        ;; Get the file info to determine type.
retry:  jsr     GetSrcFileInfo
        bcc     :+

        sys_prompt_flag := *+1
        lda     #SELF_MODIFIED_BYTE
        jpl     ShowAlert

        lda     #kErrInsertSystemDisk
        jsr     ShowAlert
        cmp     #kAlertResultOK
        beq     retry           ; ok, so try again
        rts                     ; cancel, so fail

        ;; Check file type.
:       ldax    #src_path_buf
        jsr     DetermineIconType ; uses passed name and `src_file_info_params`

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
        jsr     _CheckBasisSystem ; Is fallback BASIS.SYSTEM present?
    IF_CC                        ; yes, continue below
        copy8   #$80, INVOKER_BITSY_COMPAT
        bmi     launch          ; always
    END_IF
        param_jump ShowAlertParams, AlertButtonOptions::OK, aux::str_alert_cannot_open

        ;; --------------------------------------------------
        ;; Launch interpreter (system file that accepts path).
interpreter:
        ptr1 := $06
        stax    ptr1            ; save for later

        ;; Is the interpreter where we expect it?
        jsr     GetFileInfo
        jcs     SetCursorPointer ; nope, just ignore

        ;; Construct absolute path
        ldax    ptr1
        jsr     _MakeRelPathAbsoluteIntoInvokerInterpreter
        FALL_THROUGH_TO launch

        ;; --------------------------------------------------
        ;; Generic launch
launch:
        param_call IconToAnimate, src_path_buf
        ldx     #$FF            ; desktop
        jsr     AnimateWindowOpen

        param_call UpcaseString, INVOKER_PREFIX
        param_call UpcaseString, INVOKER_INTERPRETER
        jsr     SplitInvokerPath

        copy16  #INVOKER, reset_and_invoke_target
        jmp     ResetAndInvoke

        ;; --------------------------------------------------
        ;; BASIC program
basic:  jsr     _CheckBasicSystem ; Only launch if BASIC.SYSTEM is found
        jcc     launch
        lda     #kErrBasicSysNotFound
        jmp     ShowAlert

        ;; --------------------------------------------------
        ;; Binary file
binary:
        lda     menu_click_params::menu_id ; From a menu (File, Selector)
        jne     launch
        jsr     ModifierDown ; Otherwise, only launch if a button is down
        jmi     launch
        param_call ShowAlertParams, AlertButtonOptions::OKCancel, aux::str_alert_confirm_running
        cmp     #kAlertResultOK
        jeq     launch
        jmp     SetCursorPointer ; after not launching BIN

;;; --------------------------------------------------

.macro INVOKE_TABLE_ENTRY handler, param
        .addr   handler
        .addr   param
.endmacro

invoke_table := * - (4 * IconType::VOL_COUNT)
        ;; Volume types skipped via above math; GET_FILE_INFO yields
        ;; `FT_DIRECTORY` which maps to a folder
        INVOKE_TABLE_ENTRY      fallback, 0                    ; generic
        INVOKE_TABLE_ENTRY      _InvokePreview, str_preview_txt ; text
        INVOKE_TABLE_ENTRY      binary, 0                      ; binary
        INVOKE_TABLE_ENTRY      _InvokePreview, str_preview_fot ; graphics
        INVOKE_TABLE_ENTRY      fallback, 0                    ; animation
        INVOKE_TABLE_ENTRY      _InvokePreview, str_preview_mus ; music
        INVOKE_TABLE_ENTRY      interpreter, str_preview_pt3   ; tracker
        INVOKE_TABLE_ENTRY      fallback, 0                    ; audio
        INVOKE_TABLE_ENTRY      interpreter, str_tts           ; speech
        INVOKE_TABLE_ENTRY      _InvokePreview, str_preview_fnt ; font
        INVOKE_TABLE_ENTRY      fallback, 0                    ; relocatable
        INVOKE_TABLE_ENTRY      fallback, 0                    ; command
        INVOKE_TABLE_ENTRY      _OpenFolder, 0                 ; folder
        INVOKE_TABLE_ENTRY      _OpenFolder, 0                 ; system_folder
        INVOKE_TABLE_ENTRY      fallback, 0                    ; iigs
        INVOKE_TABLE_ENTRY      interpreter, str_awlauncher    ; appleworks_wp
        INVOKE_TABLE_ENTRY      interpreter, str_awlauncher    ; appleworks_sp
        INVOKE_TABLE_ENTRY      interpreter, str_awlauncher    ; appleworks_db
        INVOKE_TABLE_ENTRY      interpreter, str_unshrink      ; archive
        INVOKE_TABLE_ENTRY      interpreter, str_binscii       ; encoded
        INVOKE_TABLE_ENTRY      _InvokeLink, 0                 ; link
        INVOKE_TABLE_ENTRY      InvokeDeskAccByPath, 0         ; desk_accessory
        INVOKE_TABLE_ENTRY      basic, 0                       ; basic
        INVOKE_TABLE_ENTRY      interpreter, str_intbasic      ; intbasic
        INVOKE_TABLE_ENTRY      fallback, 0                    ; variables
        INVOKE_TABLE_ENTRY      launch, 0                      ; system
        INVOKE_TABLE_ENTRY      launch, 0                      ; application
        ;; Small Icon types skipped via math below
        ASSERT_RECORD_TABLE_SIZE invoke_table, IconType::COUNT - IconType::SMALL_COUNT, 4

;;; --------------------------------------------------
;;; Check `src_path_buf`'s ancestors to see if the desired interpreter
;;; (BASIC.SYSTEM or BASIS.SYSTEM) is present.
;;; Input: `src_path_buf` set to target path
;;; Output: C=0 if found, C=1 if not found

.proc _CheckBasixSystemImpl
        launch_path := INVOKER_PREFIX
        interp_path := INVOKER_INTERPRETER

basic:  lda     #'C'            ; "BASI?" -> "BASIC"
        SKIP_NEXT_2_BYTE_INSTRUCTION
basis:  lda     #'S'            ; "BASI?" -> "BASIS"
        sta     str_basix_system + kBSOffset

        ;; Start off with `interp_path` = `launch_path`
        COPY_STRING launch_path, interp_path

        ;; Pop off a path segment.
pop_segment:
        param_call RemovePathSegment, interp_path
        cmp     #2
        bcc     no_bs
        inc     interp_path     ; restore trailing '/'

        ;; Append BASI?.SYSTEM to path and check for file.
        param_call _AppendToInvokerInterpreter, str_basix_system
        param_call GetFileInfo, interp_path
        bcc     ret

        param_call RemovePathSegment, interp_path
        bne     pop_segment     ; always

no_bs:  copy8   #0, interp_path ; null out the path
        sec

ret:    rts
.endproc ; _CheckBasixSystemImpl
_CheckBasisSystem        := _CheckBasixSystemImpl::basis

.proc _CheckBasicSystem
        ldax    #str_extras_basic
        jsr     _MakeRelPathAbsoluteIntoInvokerInterpreter
        param_call GetFileInfo, INVOKER_INTERPRETER
        jcs     _CheckBasixSystemImpl::basic ; nope, look relative to launch path
        rts
.endproc ; _CheckBasicSystem

;;; --------------------------------------------------

;;; Input: A,X = relative path to append
;;; Output: `INVOKER_INTERPRETER` has absolute path
.proc _MakeRelPathAbsoluteIntoInvokerInterpreter
        pha
        txa
        pha

        MLI_CALL GET_PREFIX, get_prefix_params

        pla
        tax
        pla
        FALL_THROUGH_TO _AppendToInvokerInterpreter
.endproc ; _MakeRelPathAbsoluteIntoInvokerInterpreter

;;; --------------------------------------------------

;;; Input: A,X = relative path to append
;;; Output: `INVOKER_INTERPRETER` updated
.proc _AppendToInvokerInterpreter
        jsr     PushPointers

        ptr1 := $06
        len  := $08

        stax    ptr1

        ldy     #0
        ldx     INVOKER_INTERPRETER
        lda     (ptr1),y
        sta     len
:       iny
        inx
        lda     (ptr1),y
        sta     INVOKER_INTERPRETER,x
        cpy     len
        bne     :-
        stx     INVOKER_INTERPRETER

        jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc ; _AppendToInvokerInterpreter

;;; --------------------------------------------------

.proc _OpenFolder
        tsx
        stx     saved_stack

        jsr     OpenWindowForPath

        jmp     SetCursorPointer ; after opening folder
.endproc ; _OpenFolder


;;; --------------------------------------------------
;;; Invoke a Preview DA
;;; Inputs: A,X = relative path to DA; `src_path_buf` is file to preview

.proc _InvokePreview
        pha
        txa
        pha
        param_call IconToAnimate, src_path_buf
        tay
        pla
        tax
        pla
        jmp     InvokeDeskAccWithIcon
.endproc ; _InvokePreview

;;; --------------------------------------------------

.proc _InvokeLink
        jsr     ReadLinkFile
        RTS_IF_CS
        jmp     LaunchFileWithPath
.endproc ; _InvokeLink

;;; --------------------------------------------------

;;; Trashes: `INVOKER_INTERPRETER`
.proc _MakeSrcPathAbsolute
        ;; Already absolute?
        lda     src_path_buf+1
        cmp     #'/'
    IF_NE
        ;; Get prefix and append path
        ldax    #src_path_buf
        jsr     _MakeRelPathAbsoluteIntoInvokerInterpreter

        ;; Copy back to original buffer
        param_call CopyToSrcPath, INVOKER_INTERPRETER
    END_IF

        rts
.endproc ; _MakeSrcPathAbsolute

;;; --------------------------------------------------

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, INVOKER_INTERPRETER

.endproc ; LaunchFileWithPath
LaunchFileWithPathOnSystemDisk := LaunchFileWithPath::sys_disk

;;; ============================================================

;;; Inputs: `src_path_buf` has path to LNK file
;;; Output: C=0, `src_path_buf` has target on success
;;;         C=1 and alert is shown on error

.proc ReadLinkFile
        read_buf := $800

        MLI_CALL OPEN, open_params
        bcs     err
        lda     open_params__ref_num
        sta     read_params__ref_num
        sta     close_params__ref_num
        MLI_CALL READ, read_params
        php
        MLI_CALL CLOSE, close_params
        plp
        bcs     err

        lda     read_params__trans_count
        cmp     #kLinkFilePathLengthOffset
        bcc     bad

        ldx     #kCheckHeaderLength-1
:       lda     read_buf,x
        cmp     check_header,x
        bne     bad
        dex
        bpl     :-

        param_call CopyToSrcPath, read_buf + kLinkFilePathLengthOffset
        clc
        rts

bad:    lda     #kErrUnknown
err:    jsr     ShowAlert
        sec
        rts

check_header:
        .byte   kLinkFileSig1Value, kLinkFileSig2Value, kLinkFileCurrentVersion
        kCheckHeaderLength = * - check_header

        DEFINE_OPEN_PARAMS open_params, src_path_buf, $1C00
        open_params__ref_num := open_params::ref_num
        DEFINE_READ_PARAMS read_params, read_buf, kLinkFileMaxSize
        read_params__ref_num := read_params::ref_num
        read_params__trans_count := read_params::trans_count
        DEFINE_CLOSE_PARAMS close_params
        close_params__ref_num := close_params::ref_num

.endproc ; ReadLinkFile

;;; ============================================================
;;; Uppercase a string
;;; Input: A,X = Address
;;; Trashes $06

        PROC_USED_IN_OVERLAY
.proc UpcaseString
        ptr := $06

        stax    ptr
        ldy     #$00
        lda     (ptr),y
        beq     ret
        tay
@loop:  lda     (ptr),y
        jsr     ToUpperCase
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
        jsr     ToUpperCase
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

str_about_this_apple:
        PASCAL_STRING .concat(kFilenameModulesDir, "/this.apple")

str_tts:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/TTS.system")

str_awlauncher:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/AWLaunch.system")

str_unshrink:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/UnShrink")

str_binscii:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/BinSCII")

str_preview_fot:
        PASCAL_STRING .concat(kFilenameModulesDir, "/show.image.file")

str_preview_fnt:
        PASCAL_STRING .concat(kFilenameModulesDir, "/show.font.file")

str_preview_txt:
        PASCAL_STRING .concat(kFilenameModulesDir, "/show.text.file")

str_preview_mus:
        PASCAL_STRING .concat(kFilenameModulesDir, "/show.duet.file")

str_preview_pt3:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/PT3PLR.system")

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
:       copy8   devlst_backup,x, DEVLST-1,x ; DEVCNT is at DEVLST-1
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
        lda     selected_icon_count
        beq     :+

        lda     selected_icon_list
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
        jne     ShowAlert       ; too long

        COPY_STRING path_buf3, path_buf0
:
    END_IF

        lda     #kDynamicRoutineShortcutPick
        jsr     LoadDynamicRoutine
        bmi     done

        lda     menu_click_params::item_num
        cmp     #SelectorAction::delete
        bcs     invoke     ; delete or run (no need for more overlays)

        lda     #kDynamicRoutineShortcutEdit
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
        lda     #kDynamicRoutineRestoreSP ; restore from picker dialog
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
        jsr     _SetEntryPathPtr
        param_call CopyPtr1ToBuf, entry_path

        ;; Is there a RAMCard at all?
        jsr     GetCopiedToRAMCardFlag
        beq     use_entry_path  ; no RAMCard, skip

        ;; Look at the entry's flags
        lda     entry_num
        jsr     _SetEntryPtr

        ldy     #kSelectorEntryFlagsOffset ; flag byte following name
        lda     (ptr),y
        ASSERT_EQUALS ::kSelectorEntryCopyOnBoot, 0
        beq     on_boot
        cmp     #kSelectorEntryCopyNever
        beq     use_entry_path  ; not copied

        ;; --------------------------------------------------
        ;; `kSelectorEntryCopyOnUse`
        ldx     entry_num
        jsr     GetEntryCopiedToRAMCardFlag
        bmi     use_ramcard_path ; already copied!

        ;; Need to copy to RAMCard
        jsr     _PrepEntryCopyPaths
        jsr     DoCopyToRAM

        cmp     #kOperationCanceled
        RTS_IF_EQ

        cmp     #kOperationFailed
    IF_EQ
        param_call CopyRAMCardPrefix, path_buf4
        jmp     RefreshWindowForPathBuf4
    END_IF

        ;; Success!
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
        jsr     _ComposeRAMCardEntryPath
        stax    ptr
        jmp     launch

        ;; --------------------------------------------------
        ;; Not copied to RAMCard - just use entry's path
use_entry_path:
        copy16  #entry_path, ptr
        FALL_THROUGH_TO launch

launch: param_call CopyPtr1ToBuf, INVOKER_PREFIX
        jmp     LaunchFileWithPath

entry_num:
        .byte   0

;;; --------------------------------------------------
;;; Input: `entry_path` is populated
;;; Output: paths prepared for `DoCopyToRAM`
.proc _PrepEntryCopyPaths
        entry_original_path := $800
        entry_ramcard_path := $840

        COPY_STRING entry_path, entry_original_path

        ;; Copy "down loaded" path to `entry_ramcard_path`
        jsr     _ComposeRAMCardEntryPath
        stax    ptr
        param_call CopyPtr1ToBuf, entry_ramcard_path

        ;; Strip segment off path at `entry_original_path`
        ;; e.g. "/VOL/MOUSEPAINT/MP.SYSTEM" -> "/VOL/MOUSEPAINT"
        param_call RemovePathSegment, entry_original_path

        ;; Strip segment off path at `entry_ramcard_path`
        ;; e.g. "/RAM/MOUSEPAINT/MP.SYSTEM" -> "/RAM/MOUSEPAINT"
        param_call RemovePathSegment, entry_ramcard_path

        ;; Further prepare paths for copy
        copy16  #entry_original_path, $06
        copy16  #entry_ramcard_path, $08
        jmp     CopyPathsFromPtrsToBufsAndSplitName
.endproc ; _PrepEntryCopyPaths

;;; --------------------------------------------------
;;; Compose path using RAM card prefix plus last two segments of path
;;; (e.g. "/RAM" + "/MOUSEPAINT/MP.SYSTEM") into `src_path_buf`
;;; Input: `entry_path` is populated
;;; Output: A,X = `src_path_buf`
.proc _ComposeRAMCardEntryPath
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
.endproc ; _ComposeRAMCardEntryPath

;;; --------------------------------------------------
;;; Input: A = entry num
;;; Output: $06 points at entry
;;; NOTE: If in the "primary" list, points at the permanently loaded
;;; copy. Otherwise, assumes the picker just ran and points at the
;;; temporarily loaded copy.
.proc _SetEntryPtr
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
.endproc ; _SetEntryPtr

;;; --------------------------------------------------
;;; Input: A = entry num
;;; Output: $06 points at entry path
;;; NOTE: If in the "primary" list, points at the permanently loaded
;;; copy. Otherwise, assumes the picker just ran and points at the
;;; temporarily loaded copy.
.proc _SetEntryPathPtr
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
.endproc ; _SetEntryPathPtr

.endproc ; InvokeSelectorEntry

;;; ============================================================
;;; Copy the string at $06 to target at A,X
;;; Inputs: Source string at $06, target buffer at A,X
;;; Output: String length in A

        PROC_USED_IN_OVERLAY
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
        jmp     AboutDialogProc
.endproc ; CmdAbout

;;; ============================================================

.proc CmdAboutThisApple
        param_jump InvokeDeskAccWithIcon, $FF, str_about_this_apple
.endproc ; CmdAboutThisApple

;;; ============================================================

.proc CmdDeskAccImpl
        ptr := $6
        len := $8
        path := INVOKER_PREFIX

str_desk_acc:
        PASCAL_STRING .concat(kFilenameDADir, "/")

start:  jsr     SetCursorWatch  ; before loading DA

        ;; Append DA directory name
        param_call CopyToSrcPath, str_desk_acc

        ;; Find DA name
        lda     menu_click_params::item_num           ; menu item index (1-based)
        sec
        sbc     #kAppleMenuFixedItems+1
        tay
        ldax    #kDAMenuItemSize
        jsr     Multiply_16_8_16
        addax   #desk_acc_names, ptr

        ;; Append name to path
        ldx     path
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
        cpy     len
        bne     loop
        stx     path

        ;; Allow arbitrary types in menu (e.g. folders)
        jmp     LaunchFileWithPathOnSystemDisk
.endproc ; CmdDeskAccImpl
CmdDeskAcc      := CmdDeskAccImpl::start

;;; ============================================================
;;; Invoke a DA, with path set to first file selection
;;; Input: `src_path_buf` has DA absolute path

.proc InvokeDeskAccByPath
        ;; * Can't use `dst_path_buf` as it is within DA_IO_BUFFER
        ;; * Can't use `src_path_buf` as it holds file selection
        COPY_STRING src_path_buf, tmp_path_buf ; Use this to launch the DA

        copy8   #0, src_path_buf ; Signal no file selection

        ;; As a convenience for DAs, pass path to first selected icon.
        lda     selected_icon_count
        beq     :+
        lda     selected_icon_list ; first selected icon
        cmp     trash_icon_num     ; ignore trash
        beq     :+
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
        jne     ShowAlert       ; too long
        param_call CopyToSrcPath, path_buf3
:
        param_call IconToAnimate, tmp_path_buf
        tay
        ldax    #tmp_path_buf
        FALL_THROUGH_TO InvokeDeskAccWithIcon
.endproc ; InvokeDeskAccByPath

;;; ============================================================
;;; Invoke Desk Accessory
;;; Input: A,X = DA pathname (relative is OK)
;;;        Y = icon id to animate ($FF for none)

.proc InvokeDeskAccWithIcon
        stax    open_pathname

        tya
        sta     icon            ; can't use stack, as DAs can modify
    IF_NC
        ldx     #$FF            ; desktop
        jsr     AnimateWindowOpen
    END_IF

        ;; Load the DA
retry:  MLI_CALL OPEN, open_params
        bcc     :+
        lda     #kErrInsertSystemDisk
        jsr     ShowAlert
        cmp     #kAlertResultOK
        beq     retry           ; ok, so try again
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
        jsr     ClearUpdates

        icon := *+1
        lda     #SELF_MODIFIED_BYTE
    IF_NC
        ldx     #$FF            ; desktop
        jsr     AnimateWindowClose
    END_IF

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

.endproc ; InvokeDeskAccWithIcon

;;; ============================================================

;;; Inputs: A,X = absolute path
;;; Outputs: A = icon to animate (path or volume)

.proc IconToAnimate
        jsr     PushPointers

        ptr := $06
        stax    ptr

        ;; Is the file represented by an icon?
        jsr     FindIconForPath
    IF_ZERO
        ;; No, just use volume path

        ;; Save length
        ldy     #0
        lda     (ptr),y
        pha

        param_call_indirect MakeVolumePath, ptr
        param_call_indirect FindIconForPath, ptr
        tax

        ;; Restore length
        pla
        ldy     #0
        sta     (ptr),y

        txa
    END_IF
        jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc ; IconToAnimate

;;; ============================================================

;;; Reduce an absolute path to just the volume path. If already a
;;; volume path, the length is not changed.
;;; e.g. "/VOL/DIR/FILE" to "/VOL"
;;; Inputs: A,X = vol
;;; Note: length is modified, but buffer otherwise unchanged

.proc MakeVolumePath
        jsr     PushPointers

        ptr := $06
        pathlen := $08

        stax    ptr

        ldy     #0
        lda     (ptr),y
        sta     pathlen
        iny                     ; start at 2nd character
:
        iny
        cpy     pathlen
        beq     :+
        lda     (ptr),y
        cmp     #'/'
        bne     :-
        dey
:
        tya
        ldy     #0
        sta     (ptr),y

        jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc ; MakeVolumePath

;;; ============================================================

.proc CmdCopySelection
        lda     #kDynamicRoutineFileDialog
        jsr     LoadDynamicRoutine
        RTS_IF_NS

        lda     #kDynamicRoutineFileCopy
        jsr     LoadDynamicRoutine
        RTS_IF_NS

        jsr     FileCopyOverlay__Run
        pha                     ; A = dialog result
        lda     #kDynamicRoutineRestoreFD
        jsr     RestoreDynamicRoutine
        jsr     PushPointers    ; $06 = dst
        jsr     ClearUpdates    ; following picker dialog close
        jsr     PopPointers     ; $06 = dst
        pla                     ; A = dialog result
        RTS_IF_NS

        ;; --------------------------------------------------
        ;; Try the copy

        param_call CopyPtr1ToBuf, path_buf4
        jsr     DoCopySelection

        cmp     #kOperationCanceled
        RTS_IF_EQ

        FALL_THROUGH_TO RefreshWindowForPathBuf4

.endproc ; CmdCopySelection

;;; ============================================================

.proc RefreshWindowForPathBuf4
        ;; See if there's a window we should activate later.
        param_call FindWindowForPath, path_buf4
        pha                     ; save for later

        ;; Update cached used/free for all same-volume windows
        param_call UpdateUsedFreeViaPath, path_buf4

        ;; Select/refresh window if there was one
        pla
        jne     ActivateAndRefreshWindowOrClose

        rts
.endproc ; RefreshWindowForPathBuf4

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
        copy8   #1, path_buf4
        rts
.endproc ; SplitPathBuf4

;;; ============================================================
;;; Split filename off `INVOKER_PREFIX` into `INVOKER_FILENAME`
;;; Assert: `INVOKER_PREFIX` is a file path not volume path

.proc SplitInvokerPath
        param_call FindLastPathSegment, INVOKER_PREFIX ; point Y at last '/'
        tya
        pha
        ldx     #1
        iny                     ; +1 for length byte
        iny                     ; +1 to skip past '/'
:       copy8   INVOKER_PREFIX,y, INVOKER_FILENAME,x
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
        lda     #0
        bit     menu_modified_click_flag
    IF_NS
        lda     selected_window_id
    END_IF
        sta     window_id_to_close
        jmp     common

        ;; --------------------------------------------------
        ;; Entry point from OA+SA+O / OA+SA+Down

open_then_close_current:
        lda     selected_icon_count
        RTS_IF_ZERO

        copy8   selected_window_id, window_id_to_close
        jmp     common

        ;; --------------------------------------------------
        ;; Entry point from Apple+Down

        ;; Never close after open only.
from_keyboard:
        lda     selected_icon_count
        RTS_IF_ZERO

        copy8   #0, window_id_to_close
        jmp     common

        ;; --------------------------------------------------
        ;; Entry point from double-click

        ;; Close after open if modifier is down.
from_double_click:
        copy8   #0, window_id_to_close
        jsr     ModifierDown
        bpl     :+
        copy8   selected_window_id, window_id_to_close
:
        FALL_THROUGH_TO common

        ;; --------------------------------------------------
common:
        copy8   #0, dir_flag

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
        dir_flag := *+1
        lda     #SELF_MODIFIED_BYTE
        bpl     done

        ;; Maybe close the previously active window, depending on source/modifiers
        jsr     MaybeCloseWindowAfterOpen

done:   rts

next:   txa
        pha                     ; A = index
        lda     selected_icon_list_copy,x

        ;; Trash?
        cmp     trash_icon_num
        beq     next_icon

        pha                     ; A = icon id

        ;; Look at flags...
        jsr     GetIconEntry
        stax    ptr

        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryFlagsDropTarget ; folder or volume?
        beq     maybe_open_file       ; nope

        ;; Directory
        copy8   #$80, dir_flag

        pla                     ; A = icon id
        jsr     OpenWindowForIcon

next_icon:
        pla                     ; A = index
        tax
        inx
        jmp     loop

        ;; File (executable or data)
maybe_open_file:
        pla                     ; A = icon id
        tax                     ; X = icon id

        lda     selected_icon_count_copy
        cmp     #2              ; multiple files open?
        bcs     next_icon       ; don't try to invoke

        pla                     ; A = index; no longer needed

        txa                     ; A = icon id
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
        jne     ShowAlert       ; too long
        param_call CopyToSrcPath, path_buf3

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

.proc CmdOpenParentImpl

close_current:
        lda     active_window_id
        SKIP_NEXT_2_BYTE_INSTRUCTION
normal: lda     #0
        sta     window_id_to_close

        lda     active_window_id
        beq     done

        jsr     GetWindowPath
        jsr     CopyToSrcPath

        ;; Try removing last segment
        param_call FindLastPathSegment, src_path_buf ; point Y at last '/'
        cpy     src_path_buf

        beq     volume

        ;; --------------------------------------------------
        ;; Windowed

        ;; Calc the name
        .assert src_path_buf = INVOKER_PREFIX, error, "mismatch"
        jsr     SplitInvokerPath

        ;; Try to open by path.
        tsx
        stx     saved_stack
        jsr     OpenWindowForPath

        jsr     MaybeCloseWindowAfterOpen

        ;; Select by name (if not already done via close)
        lda     selected_icon_count
    IF_ZERO
        param_call SelectFileIconByName, INVOKER_FILENAME
    END_IF

done:   rts

        ;; --------------------------------------------------
        ;; Find volume icon by name and select it.

volume:
        jsr     MaybeCloseWindowAfterOpen

        param_call FindIconForPath, src_path_buf
        beq     :+
        jsr     SelectIconAndEnsureVisible
:
        rts
.endproc ; CmdOpenParentImpl
CmdOpenParent := CmdOpenParentImpl::normal
CmdOpenParentThenCloseCurrent := CmdOpenParentImpl::close_current

;;; ============================================================

.proc CmdClose
        lda     active_window_id
        RTS_IF_ZERO

        bit     menu_modified_click_flag
        bmi     CmdCloseAll

        jmp     CloseActiveWindow
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

.proc CmdDiskCopyImpl
        DEFINE_OPEN_PARAMS open_params, str_disk_copy, IO_BUFFER
        DEFINE_READ_PARAMS read_params, DISK_COPY_BOOTSTRAP, kDiskCopyBootstrapLength
        DEFINE_CLOSE_PARAMS close_params

str_disk_copy:
        PASCAL_STRING kPathnameDiskCopy

start:
@retry:
        ;; Do this now since we'll use up the space later.
        jsr     SaveWindows

        ;; Smuggle through the selected unit, if any.
        jsr     GetSelectedUnitNum
        sta     DISK_COPY_INITIAL_UNIT_NUM

        MLI_CALL OPEN, open_params
        bcc     :+
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
        ITK_CALL IconTK::FreeAll, 0 ; volume icons
        MGTK_CALL MGTK::CloseAll
        MGTK_CALL MGTK::SetZP1, setzp_params_preserve

        ;; Did we detach S3D2 /RAM?
        ;; NOTE: ReconnectRAM is not used here because (1) it will be
        ;; disconnected immediately by Disk Copy anyway and (2) we
        ;; don't want to trash MGTK in aux memory. We restore just
        ;; enough for Disk Copy to disconnect/reconnect properly.
        lda     saved_ram_unitnum
    IF_NE
        inc     DEVCNT
        ldx     DEVCNT
        sta     DEVLST,x
        copy16  saved_ram_drvec, RAMSLOT
    END_IF

        ;; Restore modified ProDOS state
        jsr     RestoreDeviceList

        ;; Set up banks for ProDOS usage
        sta     ALTZPOFF
        bit     ROMIN2

        jmp     DISK_COPY_BOOTSTRAP
.endproc ; CmdDiskCopyImpl
CmdDiskCopy := CmdDiskCopyImpl::start

;;; ============================================================

;;; Assert: There is an active window
.proc CmdNewFolderImpl

        ;; access = destroy/rename/write/read
        DEFINE_CREATE_PARAMS create_params, src_path_buf, ACCESS_DEFAULT, FT_DIRECTORY,, ST_LINKED_DIRECTORY

start:
        ;; Create with current date
        MLI_CALL GET_TIME
        COPY_STRUCT DateTime, DATELO, create_params::create_date

        ;; --------------------------------------------------
        ;; Determine the name to use

        ;; Start with generic folder name
        COPY_STRING str_new_folder, stashed_name

        ;; Repeat to find a free name
retry:  lda     active_window_id
        jsr     GetWindowPath
        jsr     CopyToSrcPath
        param_call AppendFilenameToSrcPath, stashed_name
        jsr     GetSrcFileInfo
        bcc     spin
        cmp     #ERR_FILE_NOT_FOUND
        beq     create
        bne     error

spin:   jsr     SpinName
        jmp     retry

        ;; --------------------------------------------------
        ;; Try creating the folder
create:
        MLI_CALL CREATE, create_params
        bcs     error

        ;; Update cached used/free for all same-volume windows and refresh
        lda     active_window_id
        jsr     UpdateActivateAndRefreshWindow
        RTS_IF_NE

        ;; Select and rename the file
        jmp     TriggerRenameForFileIconWithStashedName

        ;; --------------------------------------------------
error:
        ldx     #AlertButtonOptions::OK
        jmp     ShowAlertOption

.endproc ; CmdNewFolderImpl
CmdNewFolder    := CmdNewFolderImpl::start

;;; ============================================================
;;; Select and scroll into view an icon in the active window.
;;; Inputs: A,X = name
;;; Output: C=0 on success
;;; Trashes $06

.proc SelectFileIconByName
        ldy     active_window_id
        jsr     FindIconByName
    IF_ZERO                     ; not found
        sec
        rts
    END_IF

        jsr     SelectIconAndEnsureVisible
        clc
        rts
.endproc ; SelectFileIconByName

;;; ============================================================
;;; Find an icon by name in the given window.
;;; Inputs: Y = window id, A,X = name
;;; Outputs: Z=0, A = icon id (or Z=1, A=0 if not found)

.proc FindIconByName
        ptr_icon_name := $06
        ptr_name := $08

        jsr     PushPointers
        stax    ptr_name

        lda     cached_window_id
        pha

        tya
        jsr     LoadWindowEntryTable

        ;; Iterate icons
        copy8   #0, icon

        icon := *+1
loop:   ldx     #SELF_MODIFIED_BYTE
        cpx     cached_window_entry_count
        bne     :+

        ;; Not found
        copy8   #0, icon
        beq     done            ; always

        ;; Compare with name from dialog
:       lda     cached_window_entry_list,x
        jsr     GetIconName
        stax    ptr_icon_name
        jsr     CompareStrings
        bne     next

        ;; Match!
        ldx     icon
        lda     cached_window_entry_list,x
        sta     icon

done:
        pla
        jsr     LoadWindowEntryTable
        jsr     PopPointers
        lda     icon
        rts

next:   inc     icon
        bne     loop
.endproc ; FindIconByName

;;; ============================================================
;;; Save/Restore drop target icon ID in case the window was rebuilt.

;;; Inputs: `drag_drop_params::target`
;;; Assert: If target is a file icon, icon is in active window.
;;; Trashes $06
.proc MaybeStashDropTargetName
        ;; Flag as not stashed
        ldy     #0
        sty     stashed_name

        ;; Is the target an icon?
        lda     drag_drop_params::target
        bmi     done            ; high bit set = window

        jsr     GetIconWindow   ; file icon?
        beq     done            ; nope, vol icon

        ;; Stash name
        ptr1 := $06
        lda     drag_drop_params::target
        jsr     GetIconName
        stax    ptr1
        param_call CopyPtr1ToBuf, stashed_name

done:   rts
.endproc ; MaybeStashDropTargetName

;;; Outputs: `drag_drop_params::target` updated if needed
;;; Assert: `MaybeStashDropTargetName` was previously called
;;; Trashes $06

.proc MaybeUpdateDropTargetFromName
        ;; Did we previously stash an icon's name?
        lda     stashed_name
        beq     done            ; not stashed

        ;; Try to find the icon by name.
        ldy     active_window_id
        param_call FindIconByName, stashed_name
        beq     done            ; no match

        ;; Update drop target with new icon id.
        sta     drag_drop_params::target

done:   rts
.endproc ; MaybeUpdateDropTargetFromName

stashed_name:
        .res    16, 0

;;; ============================================================
;;; Take the name in `stashed_name` and "increment it":
;;; * If ends in dot-digits, increment (adjusting length if needed)
;;; * Otherwise, append ".2" (shrinking if needed)
;;; Trashes $10...$1F

.proc SpinName
        digits := $10

        ;; Zero out counter (a digit string, in reverse)
        lda     #'0'
        ldy     #15
:       sta     digits,y
        dey
        bne     :-

        ;; While digits, pop from string (X=len) onto digits (Y=len)
        ldx     stashed_name
:       lda     stashed_name,x
        cmp     #'0'
        bcc     :+
        cmp     #'9'+1
        bcs     :+
        iny
        sta     digits,y        ; stash digits as we go
        dex
        bne     :-              ; always (name must start w/ letter)
:
        ;; Did the string end with '.' then digits?
        cmp     #'.'            ; dot before numbers?
        bne     just_append
        cpy     #0              ; any digits found?
        beq     just_append

        ;; Truncate the '.', and increment the digits
        dex
        stx     stashed_name
        sty     digits

        ldx     #0              ; increment
:       inc     digits+1,x
        lda     digits+1,x
        cmp     #'9'+1
        bne     concatenate     ; done
        lda     #'0'
        sta     digits+1,x
        inx
        cpx     digits
        bne     :-
        inc     digits
        cpx     #13             ; max of 13 digits
        bne     :-
        beq     SpinName        ; restart

        ;; --------------------------------------------------
just_append:
        lda     #1
        sta     digits
        lda     #'2'
        sta     digits+1
        FALL_THROUGH_TO concatenate

        ;; --------------------------------------------------
concatenate:
        lda     #14
        sec
        sbc     digits
        cmp     stashed_name
    IF_LT
        sta     stashed_name
    END_IF

        ldx     stashed_name
        inx
        lda     #'.'
        sta     stashed_name,x
        ldy     digits
:       lda     digits,y
        inx
        sta     stashed_name,x
        dey
        bne     :-
        stx     stashed_name
        rts
.endproc ; SpinName

;;; ============================================================
;;; Input: Icon number in A.
;;; Assert: Icon in active window.

.proc ScrollIconIntoView
        pha
        jsr     LoadActiveWindowEntryTable
        pla
        sta     icon_param

        ;; Map coordinates to window
        pha                     ; A = icon
        jsr     IconScreenToWindow

        ;; Grab the icon bounds
        ITK_CALL IconTK::GetIconBounds, icon_param ; inits `tmp_rect`

        ;; Restore coordinates
        pla                     ; A = icon
        jsr     IconWindowToScreen

        ;; Get the viewport, and adjust for header
        jsr     ApplyActiveWinfoToWindowGrafport
        add16_8 window_grafport::maprect::y1, #kWindowHeaderHeight - 1


        ;; Padding
        MGTK_CALL MGTK::InflateRect, bbox_pad_tmp_rect

        ;; --------------------------------------------------
        ;; Adjustments

        delta := $06
        dirty := $08

        copy8   #0, dirty
        ldx     #2              ; loop over dimensions
loop:
        ;; Is left of icon beyond window? If so, adjust by delta (negative)
        sub16   tmp_rect::topleft,x, window_grafport::maprect::topleft,x, delta
        bmi     adjust

        ;; Is right of icon beyond window? If so, adjust by delta (positive)
        sub16   tmp_rect::bottomright,x, window_grafport::maprect::bottomright,x, delta
        bmi     done

adjust:
        lda     delta
        ora     delta+1
        beq     done

        inc     dirty
        add16   window_grafport::maprect::topleft,x, delta, window_grafport::maprect::topleft,x
        add16   window_grafport::maprect::bottomright,x, delta, window_grafport::maprect::bottomright,x

done:
        dex                     ; next dimension
        dex
        bpl     loop

        lda     dirty
    IF_NOT_ZERO
        ;; Apply the viewport (accounting for header)
        sub16_8 window_grafport::maprect::y1, #kWindowHeaderHeight - 1
        jsr     AssignActiveWindowCliprectAndUpdateCachedIcons
        jsr     ClearAndDrawActiveWindowEntries
        jsr     ScrollUpdate
    END_IF

        rts

.endproc ; ScrollIconIntoView

;;; ============================================================

.proc CmdCheckOrEjectImpl
        buffer := $1800

eject:  lda     #$80
        SKIP_NEXT_2_BYTE_INSTRUCTION
check:  lda     #0
        sta     eject_flag

        ;; Ensure that volumes are selected
        lda     selected_window_id
        beq     :+
done:   rts

        ;; And if there's only one, it's not Trash
:       jsr     GetSingleSelectedIcon
        cmp     trash_icon_num  ; if it's Trash, skip it
        beq     done

        ;; Record non-Trash selected volume icons to a buffer
        lda     #0
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
        jsr     CheckDriveByIconNumber
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
        bcs     fail
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
        copy8   #0, main::mli_relay_checkevents_flag

        jsr     SaveWindows

        MGTK_CALL MGTK::StopDeskTop

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

        sta     SET80STORE      ; 80-col firmware expects this
        lda     #0              ; INIT is not used as that briefly
        sta     WNDLFT          ; displays the dirty text page
        sta     WNDTOP
        lda     #80
        sta     WNDWDTH
        lda     #24
        sta     WNDBTM
        jsr     HOME            ; Clear 80-col screen
        sta     TXTSET          ; ... and show it

        lda     #$95            ; Ctrl-U - disable 80-col firmware
        jsr     COUT
        jsr     INIT            ; reset text window again
        jsr     SETVID          ; after INIT so WNDTOP is set properly
        jsr     SETKBD

        ;; Switch back to color DHR mode now that screen is blank
        bit     LCBANK1
        bit     LCBANK1
        sta     ALTZPON
        jsr     SetColorMode    ; depends on state in Aux LC
        sta     CLR80VID        ; back off, after `SetColorMode` call
        sta     DHIRESOFF
        sta     ALTZPOFF
        bit     ROMIN2

        jsr     ReconnectRAM
        jmp     RestoreDeviceList
.endproc ; RestoreSystem

;;; ============================================================

menu_item_to_view_by:
        .byte   DeskTopSettings::kViewByIcon
        .byte   DeskTopSettings::kViewBySmallIcon
        .byte   DeskTopSettings::kViewByName
        .byte   DeskTopSettings::kViewByDate
        .byte   DeskTopSettings::kViewBySize
        .byte   DeskTopSettings::kViewByType

.proc CmdViewBy
        ldx     menu_click_params::item_num
        lda     menu_item_to_view_by-1,x
        sta     view

        ;; Valid?
        lda     active_window_id
        RTS_IF_ZERO

        ;; Is this a change?
        jsr     GetActiveWindowViewBy
        cmp     view
        RTS_IF_EQ

        ;; Update view menu/table
        view := *+1
        lda     #SELF_MODIFIED_BYTE
        ldx     active_window_id
        sta     win_view_by_table-1,x

        FALL_THROUGH_TO RefreshViewPreserveSelection
.endproc ; CmdViewBy

;;; ============================================================

.proc RefreshViewImpl

;;; Entry point when view needs refreshing, e.g. rename when sorted.
entry2:
        ;; Selection not preserved in other entry points
        ;; because file records are not retained.
        jsr     _PreserveSelection

        ;; Destroy existing icons
        jsr     LoadActiveWindowEntryTable
        jsr     RemoveAndFreeCachedWindowIcons

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

        jsr     _RestoreSelection

        jsr     ClearAndDrawActiveWindowEntries
        jmp     ScrollUpdate

;;; --------------------------------------------------
;;; Preserves selection by replacing selected icon ids
;;; with their corresponding record indexes, which remain
;;; valid across view changes.

.proc _PreserveSelection
        lda     selected_window_id
        cmp     active_window_id
        bne     ret
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

        copy8   #0, selected_window_id

ret:    rts
.endproc ; _PreserveSelection

;;; --------------------------------------------------
;;; Restores selection after a view change, reversing what
;;; `_PreserveSelection` did.

.proc _RestoreSelection
        lda     selection_preserved_count
        beq     ret

        ;; For each record num in the list, find and
        ;; highlight the corresponding icon.
:       ldx     selected_icon_count
        lda     selected_icon_list,x
        jsr     FindIconForRecordNum
        jsr     AddToSelectionList
        sta     icon_param
        ITK_CALL IconTK::HighlightIcon, icon_param
        dec     selection_preserved_count
        bne     :-

        copy8   cached_window_id, selected_window_id

ret:    rts
.endproc ; _RestoreSelection

selection_preserved_count:
        .byte   0
.endproc ; RefreshViewImpl
RefreshViewPreserveSelection := RefreshViewImpl::entry2
RefreshView := RefreshViewImpl::entry3

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
;;; Retrieve the window id for a given icon.
;;; Input: A = icon id
;;; Output: A = window id (0=desktop)

.proc GetIconWindow
        jsr     PushPointers
        jsr     GetIconEntry
        ptr := $06
        stax    ptr
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc ; GetIconWindow

;;; ============================================================

.proc RemoveAndFreeCachedWindowIcons
        lda     icon_count
        sec
        sbc     cached_window_entry_count
        sta     icon_count

        ITK_CALL IconTK::FreeAll, cached_window_id

        ;; Remove any associations with windows
        ldx     cached_window_entry_count
        beq     done

loop:   txa                     ; X = index+1
        pha                     ; A = index+1
        lda     cached_window_entry_list-1,x
        jsr     FindWindowIndexForDirIcon ; X = window id-1 if found
    IF_EQ
        copy8   #kWindowToDirIconNone, window_to_dir_icon_table,x
    END_IF
        pla                     ; A = index+1
        tax                     ; X = index+1
        dex
        bne     loop

done:   rts
.endproc ; RemoveAndFreeCachedWindowIcons

;;; ============================================================

;;; Set after format, erase, failed open, etc.
;;; Used by `CheckDriveByXXX`; may be unit number,
;;; icon number, or device index depending on call site.
drive_to_refresh:
        .byte   0

;;; ============================================================

.proc CmdFormatEraseDiskImpl
format: lda     #FormatEraseAction::format
        SKIP_NEXT_2_BYTE_INSTRUCTION
erase:  lda     #FormatEraseAction::erase
        sta     action

        jsr     GetSelectedUnitNum
        sta     unit_num

exec:   lda     #kDynamicRoutineFormatErase
        jsr     LoadDynamicRoutine
        RTS_IF_NS

        unit_num := *+1
        ldx     #SELF_MODIFIED_BYTE
        action := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     format_erase_overlay__Exec
        stx     drive_to_refresh ; X = unit number
        pha                      ; A = result
        jsr     ClearUpdates     ; following dialog close
        pla                      ; A = result
        RTS_IF_NOT_ZERO

        jmp     CheckDriveByUnitNumber

unit:   sta     unit_num
        copy8   #FormatEraseAction::format, action
        bne     exec            ; always

.endproc ; CmdFormatEraseDiskImpl
CmdFormatDisk := CmdFormatEraseDiskImpl::format
CmdEraseDisk := CmdFormatEraseDiskImpl::erase
FormatUnitNum := CmdFormatEraseDiskImpl::unit

;;; ============================================================

;;; Inputs: A=unit number if a single volume is selected, 0 otherwise

.proc GetSelectedUnitNum
        ;; Get single selected volume icon (or fail)
        lda     selected_window_id
        bne     fail            ; not the desktop
        jsr     GetSingleSelectedIcon
        beq     fail

        jsr     IconToDeviceIndex
        beq     found

fail:   lda     #0
        rts

found:  lda     DEVLST,x
        and     #UNIT_NUM_MASK
        rts
.endproc ; GetSelectedUnitNum

;;; ============================================================

;;; Input: A = icon id
;;; Output: if found, Z=1 and X = index in DEVLST; Z=0 otherwise

.proc IconToDeviceIndex
        ldx     #kMaxVolumes-1
:       cmp     device_to_icon_map,x
        beq     ret
        dex
        bpl     :-

ret:    rts
.endproc ; IconToDeviceIndex

;;; ============================================================

.proc CmdGetInfo
        jsr     DoGetInfo
    IF_NS
        ;; Selected items were modified (e.g. locked), so refresh
        lda     selected_window_id
      IF_NOT_ZERO               ; windowed (not desktop); no refresh needed
        cmp     active_window_id
        jeq     ClearAndDrawActiveWindowEntries ; active - just repaint
        jmp     ActivateWindow  ; inactive - activate, it will repaint
      END_IF
    END_IF

        rts
.endproc ; CmdGetInfo

;;; ============================================================

.proc CmdDeleteSelection
        lda     selected_window_id
        jeq     CmdEject

        jsr     DoDeleteSelection
        cmp     #kOperationCanceled
        RTS_IF_EQ

        copy8   #$80, validate_windows_flag
        jmp     UpdateActivateAndRefreshSelectedWindow
.endproc ; CmdDeleteSelection

;;; ============================================================

;;; Assert: Single icon selected, and it's not Trash

.proc CmdCopy
        lda     selected_icon_list
        jsr     GetIconName
        stax    $06
        param_jump CopyPtr1ToBuf, clipboard
.endproc ; CmdCopy

.proc CmdPaste
        ;; MacOS 6 behavior - no-op if clipboard is empty
        lda     clipboard
        RTS_IF_EQ

        ldax    #clipboard
        jmp     CmdRenameWithDefaultNameGiven
.endproc ; CmdPaste

.proc CmdCut
        jsr     CmdCopy
        FALL_THROUGH_TO CmdClear
.endproc ; CmdCut

.proc CmdClear
        ldax    #str_empty
        jmp     CmdRenameWithDefaultNameGiven
.endproc ; CmdClear

;;; ============================================================

.proc TriggerRenameForFileIconWithStashedName
        param_call SelectFileIconByName, stashed_name
        FALL_THROUGH_TO CmdRename
.endproc ; TriggerRenameForFileIconWithStashedName

;;; ============================================================

;;; Assert: Single icon selected, and it's not Trash
.proc CmdRename
        ;; Dialog will use this field (populated in `DoRename`) as default
        ldax    #old_name_buf

        ;; ... but callers can override and use this entry point instead.
ep2:
        jsr     DoRename
        pha                     ; A = result

        ;; If selection in non-active window, activate it
        lda     selected_window_id
        jsr     ActivateWindow  ; no-op if already active, or 0

        ;; If selection is in a window with View > by Name, refresh
        lda     selected_window_id
    IF_NE
        jsr     GetSelectionViewBy
        cmp     #DeskTopSettings::kViewByName
      IF_EQ
        txa                     ; X = window id
        jsr     RefreshViewPreserveSelection

        lda     selected_icon_list
        jsr     ScrollIconIntoView
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
CmdRenameWithDefaultNameGiven := CmdRename::ep2 ; A,X = name

;;; ============================================================

;;; Assert: Single file icon selected
.proc CmdDuplicate

        ;; --------------------------------------------------
        ;; Determine the name to use

        ;; Start with original name
        lda     selected_icon_list
        jsr     GetIconName
        stax    $06
        param_call CopyPtr1ToBuf, stashed_name

        ;; Construct src path
        jsr     GetSelectionWindow
        jsr     GetWindowPath
        jsr     CopyToSrcPath
        param_call AppendFilenameToSrcPath, stashed_name

        ;; Repeat to find a free name
spin:   jsr     GetSelectionWindow
        jsr     GetWindowPath
        jsr     CopyToDstPath
        jsr     SpinName
        param_call AppendFilenameToDstPath, stashed_name
        jsr     GetDstFileInfo
        bcc     spin
        cmp     #ERR_FILE_NOT_FOUND
        bne     error

        ;; --------------------------------------------------
        ;; Try copying the file

        copy16  #src_path_buf, $06
        copy16  #dst_path_buf, $08
        jsr     CopyPathsFromPtrsToBufsAndSplitName
        jsr     DoCopyFile
        sta     result
        cmp     #kOperationCanceled
        RTS_IF_EQ

        ;; Update name case bits on disk, if possible.
        param_call CopyToSrcPath, dst_path_buf
        jsr     ApplyCaseBits ; applies `stashed_name` to `src_path_buf`

        ;; Update cached used/free for all same-volume windows, and refresh
        lda     selected_window_id
        jsr     UpdateActivateAndRefreshWindow
        RTS_IF_NE

        ;; If operation failed, then just leave the default name.
        result := *+1
        lda     #SELF_MODIFIED_BYTE
        ASSERT_NOT_EQUALS kOperationFailed, 0
        RTS_IF_NOT_ZERO

        ;; Select and rename the file
        jmp     TriggerRenameForFileIconWithStashedName

        ;; --------------------------------------------------
error:
        ldx     #AlertButtonOptions::OK
        jmp     ShowAlertOption

.endproc ; CmdDuplicate

;;; ============================================================
;;; Handle keyboard-based icon selection ("highlighting")

.proc KeyboardHighlightImpl

;;; Local variables on ZP
PARAM_BLOCK, $50
delta      .byte
END_PARAM_BLOCK

        ;; ----------------------------------------
        ;; Next/prev in sorted order

        ;; Tab / Shift+Tab
alpha:  jsr     ShiftDown
        bpl     a_next
        FALL_THROUGH_TO a_prev

a_prev: lda     #AS_BYTE(-1)
        SKIP_NEXT_2_BYTE_INSTRUCTION
a_next: lda     #1

        sta     delta
        jsr     GetKeyboardSelectableIconsSorted
        jmp     common

        ;; ----------------------------------------
        ;; Arrows - next/prev in icon order
prev:   lda     #AS_BYTE(-1)
        SKIP_NEXT_2_BYTE_INSTRUCTION
next:   lda     #1

        sta     delta
        jsr     GetKeyboardSelectableIcons
        FALL_THROUGH_TO common

;;; --------------------------------------------------
;;; Figure out current selected index, based on selection.

common:
        ;; First byte is icon count. Rest is a list of selectable icons.
        buffer := $1800

        ;; Anything selectable?
        lda     buffer
        beq     ret

        lda     selected_icon_count
        beq     fallback

        ;; Try to find actual selection in our list
        lda     selected_icon_list ; Only consider first, otherwise N^2
        ldx     buffer             ; count
        dex                        ; index
:       cmp     buffer+1,x
        beq     pick_next_prev
        dex
        bpl     :-

        ;; If not in our list, use a fallback.
fallback:
        ldx     #0
        ldy     delta
    IF_NEG
        ldx     buffer
        dex
    END_IF
        bpl     select_index    ; always

        ;; There was a selection; pick prev/next based on keypress.
pick_next_prev:
        txa
        clc
        adc     delta           ; +1 or -1
        cmp     buffer
        bcs     ret             ; handles >= max or < 0
        tax
        FALL_THROUGH_TO select_index

select_index:
        lda     buffer+1,x
        jmp     SelectIconAndEnsureVisible

ret:    rts

.endproc ; KeyboardHighlightImpl
KeyboardHighlightPrev := KeyboardHighlightImpl::prev
KeyboardHighlightNext := KeyboardHighlightImpl::next
KeyboardHighlightAlpha := KeyboardHighlightImpl::alpha
KeyboardHighlightAlphaPrev := KeyboardHighlightImpl::a_prev
KeyboardHighlightAlphaNext := KeyboardHighlightImpl::a_next

;;; ============================================================

.proc KeyboardHighlightSpatialImpl

;;; Local variables on ZP
PARAM_BLOCK, $50
dir        .byte
index      .byte
cur_icon   .byte
icon_rect  .tag MGTK::Rect
best_icon  .byte
best_value .word
END_PARAM_BLOCK
        ASSERT_EQUALS icon_rect, cur_icon+1, "Must be adjacent"

        kDirLeft  = 0
        kDirRight = 1
        kDirUp    = 2
        kDirDown  = 3

left:   lda     #kDirLeft
        SKIP_NEXT_2_BYTE_INSTRUCTION

right:  lda     #kDirRight
        SKIP_NEXT_2_BYTE_INSTRUCTION

up:     lda     #kDirUp
        SKIP_NEXT_2_BYTE_INSTRUCTION

down:   lda     #kDirDown

        sta     dir

;;; --------------------------------------------------
;;; If a list view, use index-based logic

        jsr     GetActiveWindowViewBy ; N=0 is icon view, N=1 is list view
    IF_NEG
        lda     dir
        cmp     #kDirUp
        beq     KeyboardHighlightPrev
        bcs     KeyboardHighlightNext
        rts                     ; ignore if left/right
    END_IF

;;; --------------------------------------------------
;;; Identify a starting icon

        jsr     LoadActiveWindowEntryTable

        lda     selected_icon_count
        jeq     fallback

        lda     active_window_id
        cmp     selected_window_id
        jne     fallback

        lda     selected_icon_list ; use first
        sta     icon_param

;;; --------------------------------------------------
;;; Get bounds

        ITK_CALL IconTK::GetBitmapRect, icon_param ; inits `tmp_rect`

;;; --------------------------------------------------
;;; Extend rect, based on dir

        kDelta = 1024

        ;; For relevant dir, determine:
        ;;   A,X = delta (positive or negative)
        ;;   Y = offset into `tmp_rect`
        ldy     dir
        lda     rect_deltas_lo,y
        ldx     rect_deltas_hi,y
        pha
        lda     far_offsets,y
        tay
        pla

        ;; `tmp_rect`,y += A,X
        clc
        adc     tmp_rect,y
        sta     tmp_rect,y
        txa
        iny
        adc     tmp_rect,y
        sta     tmp_rect,y

;;; --------------------------------------------------
;;; Iterate over icons, consider any in rect

        lda     #0
        sta     best_icon
        sta     index

icon_loop:
        ldx     index
        cpx     cached_window_entry_count
        beq     finish_loop

        lda     cached_window_entry_list,x
        sta     cur_icon
        sta     icon_param
        jsr     IsIconSelected
        beq     next_icon

        ITK_CALL IconTK::IconInRect, icon_param ; tests against `tmp_rect`
        beq     next_icon

        ITK_CALL IconTK::GetIconBounds, cur_icon ; result in `icon_rect`

        ldx     dir
        ldy     near_offsets,x  ; y = MGTK::Rect member offset

        ;; If icon's near edge < selected icon's near edge, ignore
        scmp16  icon_rect,y, tmp_rect,y
        eor     compare_order,x ; flip result if needed
        bmi     next_icon

        ;; Any other candidates so far?
        lda     best_icon
        beq     best

        ;; If icon's near edge > `best_value`, ignore
        scmp16  icon_rect,y, best_value
        eor     compare_order,x ; flip result if needed
        bpl     next_icon

best:
        copy8   cur_icon, best_icon
        copy16  icon_rect,y, best_value

next_icon:
        inc     index
        bne     icon_loop       ; always

finish_loop:
        lda     best_icon
        bne     select

ret:    rts

;;; Tables indexed by `kDirXXX`
rect_deltas_lo: .byte   <AS_WORD(-kDelta), <kDelta, <AS_WORD(-kDelta), <kDelta
rect_deltas_hi: .byte   >AS_WORD(-kDelta), >kDelta, >AS_WORD(-kDelta), >kDelta
far_offsets:    .byte   MGTK::Rect::x1, MGTK::Rect::x2, MGTK::Rect::y1, MGTK::Rect::y2
near_offsets:   .byte   MGTK::Rect::x2, MGTK::Rect::x1, MGTK::Rect::y2, MGTK::Rect::y1
compare_order:  .byte   $80, $00, $80, $00
;;; --------------------------------------------------
;;; If there was no (usable) selection, pick icon from active window.

fallback:
        ldy     cached_window_entry_count
        beq     ret

        ;; Default to first (X) / last (Y) icon
        ldx     #0
        dey
        lda     active_window_id
    IF_ZERO
        ;; ...except on desktop, since first is Trash.
        tay                     ; make last (Y) be Trash (0)
        inx                     ; and first (X) be 1st volume icon
        cpx     cached_window_entry_count
        bne     :+              ; unless there isn't one
        dex
:
    END_IF
        ror     dir             ; C = 1 if right/down
        lda     cached_window_entry_list,x
        bcs     :+
        lda     cached_window_entry_list,y
:

select:
        jmp     SelectIconAndEnsureVisible

.endproc ; KeyboardHighlightSpatialImpl
KeyboardHighlightLeft  := KeyboardHighlightSpatialImpl::left
KeyboardHighlightRight := KeyboardHighlightSpatialImpl::right
KeyboardHighlightDown  := KeyboardHighlightSpatialImpl::down
KeyboardHighlightUp    := KeyboardHighlightSpatialImpl::up

;;; ============================================================
;;; Type Down Selection

.proc ClearTypeDown
        copy8   #0, typedown_buf
        rts
.endproc ; ClearTypeDown

;;; Returns Z=1 if consumed, Z=0 otherwise.
.proc CheckTypeDown
        jsr     ToUpperCase
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
        RTS_IF_ZS               ; Z=1 to consume

        inx
        stx     typedown_buf
        sta     typedown_buf,x

        ;; Collect and sort the potential type-down matches
        jsr     GetKeyboardSelectableIconsSorted
        lda     num_filenames
        beq     done

        ;; Find a match.
        jsr     _FindMatch

        ;; Icon to select
        tax
        lda     table,x         ; index to icon
        sta     icon

        ;; Already the selection?
        jsr     GetSingleSelectedIcon
        cmp     icon
        beq     done            ; yes, nothing to do

        ;; Update the selection.
        icon := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     SelectIconAndEnsureVisible

done:   lda     #0
        rts

        num_filenames := $1800
        table := $1801

;;; Find the substring match for `typedown_buf`, or the next
;;; match in lexicographic order, or the last item in the table.
.proc _FindMatch
        ptr     := $06
        len     := $08

        copy8   #0, index

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
        jsr     ToUpperCase
        cmp     typedown_buf,y
        bcc     next
        beq     :+
        bcs     found
:
        cpy     typedown_buf
        beq     found

        iny
        cpy     len
        bcc     cloop
        beq     cloop

next:   inc     index
        lda     index
        cmp     num_filenames
        bne     loop
        dec     index
found:  return  index
.endproc ; _FindMatch

.endproc ; CheckTypeDown

;;; Length plus filename
typedown_buf:
        .res    16, 0

;;; ============================================================
;;; Build list of keyboard-selectable icons.
;;; This is all icons in active window.
;;; Output: Buffer at $1800 (length prefixed)
;;;         X = number of icons

.proc GetKeyboardSelectableIcons
        buffer := $1800

        jsr     LoadActiveWindowEntryTable
        ldx     #0
:
        cpx     cached_window_entry_count
        beq     :+
        lda     cached_window_entry_list,x
        sta     buffer+1,x
        inx
        bne     :-              ; always
:
        stx     buffer
        rts
.endproc ; GetKeyboardSelectableIcons

;;; Gather the keyboard-selectable icons into buffer at $1800, and
;;; sort them by name.
;;; Output: Buffer at $1800 (length prefixed)

.proc GetKeyboardSelectableIconsSorted
        buffer := $1800
        ptr1 := $06
        ptr2 := $08

        jsr     GetKeyboardSelectableIcons

        cpx     #2
        RTS_IF_CC

        ;; Selection sort. In each outer iteration, the highest
        ;; remaining element is moved to the end of the unsorted
        ;; region, and the region is reduced by one. O(n^2)
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
.endproc ; GetKeyboardSelectableIconsSorted

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
        copy8   (ptr1),y, len1
        copy8   (ptr2),y, len2
        iny

loop:   lda     (ptr2),y
        jsr     ToUpperCase
        sta     char
        lda     (ptr1),y
        jsr     ToUpperCase
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
;;; Replace selection with the specified icon. The icon's
;;; window is activated if necessary. If windowed, it is scrolled
;;; into view.
;;; Inputs: A = icon id

.proc SelectIconAndEnsureVisible
        ;; No-op if already single selected icon
        ldy     selected_icon_count
        dey
        bne     continue
        cmp     selected_icon_list
        beq     ret

continue:
        pha
        jsr     ClearSelection
        pla

        pha
        jsr     GetIconWindow
        jsr     ActivateWindow  ; no-op if already active, or 0
        pla

        sta     icon_param
        ITK_CALL IconTK::HighlightIcon, icon_param

        ;; Find icon's window, and set selection
        lda     icon_param
        jsr     GetIconWindow
        sta     selected_window_id
        copy8   #1, selected_icon_count
        copy8   icon_param, selected_icon_list

        ;; If windowed, ensure it is visible
        lda     selected_window_id
        beq     :+
        lda     selected_icon_list
        jsr     ScrollIconIntoView
:

        ITK_CALL IconTK::DrawIcon, selected_icon_list

ret:    rts
.endproc ; SelectIconAndEnsureVisible

;;; ============================================================

.proc CmdSelectAll
        jsr     ClearSelection

        jsr     LoadActiveWindowEntryTable
        lda     cached_window_entry_count
        beq     finish          ; nothing to select!

        ldx     cached_window_entry_count
        dex
:       copy8   cached_window_entry_list,x, selected_icon_list,x
        dex
        bpl     :-

        copy8   cached_window_entry_count, selected_icon_count
        copy8   active_window_id, selected_window_id

        ;; --------------------------------------------------
        ;; Mark all icons as highlighted

        ldx     #0
:       txa
        pha
        copy8   selected_icon_list,x, icon_param
        ITK_CALL IconTK::HighlightIcon, icon_param
        pla
        tax
        inx
        cpx     selected_icon_count
        bne     :-

        ;; --------------------------------------------------
        ;; Repaint the icons

        ;; Assert: `selected_window_id` == `active_window_id`
        ;; Assert: `selected_window_id` == `cached_window_id`

        lda     selected_window_id
    IF_ZERO
        jsr     InitSetDesktopPort
    ELSE
        jsr     UnsafeSetPortFromWindowIdAndAdjustForEntries ; CHECKED
    END_IF
    IF_ZERO                     ; Skip drawing if obscured
        jsr     CachedIconsScreenToWindow
        ITK_CALL IconTK::DrawAll, cached_window_id ; CHECKED
        jsr     CachedIconsWindowToScreen
    END_IF

finish: rts
.endproc ; CmdSelectAll


;;; ============================================================
;;; Initiate keyboard-based resizing

.proc CmdResize
        MGTK_CALL MGTK::KeyboardMouse
        jmp     DoWindowResize
.endproc ; CmdResize

;;; ============================================================
;;; Initiate keyboard-based window moving

.proc CmdMove
        MGTK_CALL MGTK::KeyboardMouse
        jmp     DoWindowDrag
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
        bne     found           ; not `kWindowToDirIconFree`
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
        beq     @loop           ; is `kWindowToDirIconFree`
        FALL_THROUGH_TO found

found:  inx
        txa
        jmp     ActivateWindow

done:   rts
.endproc ; CmdCycleWindows

;;; ============================================================
;;; Flip Screen

.proc CmdFlipScreen
        JSR_TO_AUX aux::FlipMGTKHiresTable
        MGTK_CALL MGTK::RedrawDeskTop
        MGTK_CALL MGTK::DrawMenuBar
        rts
.endproc ; CmdFlipScreen

;;; ============================================================
;;; Keyboard-based scrolling of window contents

.proc CmdScroll
loop:   jsr     GetEvent        ; no need to synthesize events

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

;;; Terminology:
;;; * "offset" - When the icons would fit entirely within the viewport
;;;   (for a given dimension) but the viewport is offset so a scrollbar
;;;   must still be shown.


;;; Effective viewport  ("Effective" discounts the window header.)
viewport := window_grafport::maprect

;;; Local variables on ZP
;;; NOTE: $50...$6F is used because MulDiv uses $10...$19
PARAM_BLOCK, $50
;;; `ubox` is a union of the effective viewport and icon bounding box
ubox    .tag    MGTK::Rect

;;; Effective dimensions of the viewport
width   .word
height  .word

;;; Initial effective viewport top/left
old     .tag    MGTK::Point

;;; Increment/decrement sizes (depends on view type)
tick_h  .byte
tick_v  .byte

tmpw    .word
END_PARAM_BLOCK
dimensions := width

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
        ldx     #kIconViewScrollTickH
        ldy     #kIconViewScrollTickV
    ELSE
        ;; List view
        ldx     #kListViewScrollTickH
        ldy     #kListViewScrollTickV
    END_IF
        stx     tick_h
        sty     tick_v

        ;; Compute effective viewport
        jsr     ApplyActiveWinfoToWindowGrafport
        add16_8 viewport+MGTK::Rect::y1, #kWindowHeaderHeight - 1
        COPY_STRUCT MGTK::Point, viewport+MGTK::Rect::topleft, old
        sub16   viewport+MGTK::Rect::x2, viewport+MGTK::Rect::x1, width
        sub16   viewport+MGTK::Rect::y2, viewport+MGTK::Rect::y1, height

        ;; Make `ubox` bound both viewport and icons; needed to ensure
        ;; offset cases are handled.
        MGTK_CALL MGTK::UnionRects, unionrects_viewport_iconbb
        COPY_BLOCK iconbb_rect, ubox
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
        sub16   ubox+MGTK::Rect::x2, ubox+MGTK::Rect::x1, tmpw
        sub16   tmpw, width, track_muldiv_params::number
        jsr     _TrackMulDiv
        add16   track_muldiv_params::result, ubox+MGTK::Rect::x1, viewport+MGTK::Rect::x1
        add16   viewport+MGTK::Rect::x1, width, viewport+MGTK::Rect::x2
        jmp     _MaybeUpdateHThumb
.endproc ; TrackHThumb

.proc TrackVThumb
        jsr     _Preamble
        sub16   ubox+MGTK::Rect::y2, ubox+MGTK::Rect::y1, tmpw
        sub16   tmpw, height, track_muldiv_params::number
        jsr     _TrackMulDiv
        add16   track_muldiv_params::result, ubox+MGTK::Rect::y1, viewport+MGTK::Rect::y1
        add16   viewport+MGTK::Rect::y1, height, viewport+MGTK::Rect::y2
        jmp     _MaybeUpdateVThumb
.endproc ; TrackVThumb

.proc _TrackMulDiv
        copy8   trackthumb_params::thumbpos, track_muldiv_params::numerator
        MGTK_CALL MGTK::MulDiv, track_muldiv_params
        rts
.endproc ; _TrackMulDiv

;;; --------------------------------------------------
;;; _Clamp_hi:
;;;   1. if vp.hi > ubox.hi: vp.hi = ubox.hi
;;;   2. vp.lo = vp.hi - size
;;;   3. goto update

.proc _Clamp_hi
        scmp16  viewport+MGTK::Rect::bottomright,x, ubox+MGTK::Rect::bottomright,x
    IF_POS
        copy16  ubox+MGTK::Rect::bottomright,x, viewport+MGTK::Rect::bottomright,x
    END_IF
        sub16   viewport+MGTK::Rect::bottomright,x, dimensions,x, viewport+MGTK::Rect::topleft,x
        rts
.endproc ; _Clamp_hi

.proc _Clamp_x2
        ldx     #0
        jsr     _Clamp_hi
        jmp     _MaybeUpdateHThumb
.endproc ; _Clamp_x2

.proc _Clamp_y2
        ldx     #2
        jsr     _Clamp_hi
        jmp     _MaybeUpdateVThumb
.endproc ; _Clamp_y2

;;; --------------------------------------------------
;;; _Clamp_lo:
;;;   1. if vp.lo < ubox.lo: vp.lo = ubox.lo
;;;   2. vp.hi = vp.lo + size
;;;   3. goto update

.proc _Clamp_lo
        scmp16  viewport+MGTK::Rect::topleft,x, ubox+MGTK::Rect::topleft,x
    IF_NEG
        copy16  ubox+MGTK::Rect::topleft,x, viewport+MGTK::Rect::topleft,x
    END_IF
        add16   viewport+MGTK::Rect::topleft,x, dimensions,x, viewport+MGTK::Rect::bottomright,x
        rts
.endproc ; _Clamp_lo

.proc _Clamp_x1
        ldx     #0
        jsr     _Clamp_lo
        jmp     _MaybeUpdateHThumb
.endproc ; _Clamp_x1

.proc _Clamp_y1
        ldx     #2
        jsr     _Clamp_lo
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
        ecmp16  viewport+MGTK::Rect::x1, old+MGTK::Point::xcoord
    IF_NE
        jsr     _SetHThumbFromViewport
        jsr     _UpdateViewport
        jsr     ClearAndDrawActiveWindowEntries

        ;; Handle offset case - may be able to deactivate scrollbar now
        jsr     _Preamble       ; Need updated `ubox` and `maprect`
        scmp16  ubox+MGTK::Rect::x1, viewport+MGTK::Rect::x1
        bmi     :+
        scmp16  viewport+MGTK::Rect::x2, ubox+MGTK::Rect::x2
        bmi     :+
        ldx     #MGTK::Ctl::horizontal_scroll_bar
        lda     #MGTK::activatectl_deactivate
        jsr     _ActivateCtl
:
    END_IF
        rts
.endproc ; _MaybeUpdateHThumb

.proc _MaybeUpdateVThumb
        ecmp16  viewport+MGTK::Rect::y1, old+MGTK::Point::ycoord
    IF_NE
        jsr     _SetVThumbFromViewport
        jsr     _UpdateViewport
        jsr     ClearAndDrawActiveWindowEntries

        ;; Handle offset case - may be able to deactivate scrollbar now
        jsr     _Preamble       ; Need updated `ubox` and `maprect`
        scmp16  ubox+MGTK::Rect::y1, viewport+MGTK::Rect::y1
        bmi     :+
        scmp16  viewport+MGTK::Rect::y2, ubox+MGTK::Rect::y2
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
        sub16   viewport+MGTK::Rect::x1, ubox+MGTK::Rect::x1, setthumb_muldiv_params::number
        sub16   ubox+MGTK::Rect::x2, ubox+MGTK::Rect::x1, tmpw
        sub16   tmpw, width, setthumb_muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, setthumb_muldiv_params
        lda     setthumb_muldiv_params::result
        ldx     #MGTK::Ctl::horizontal_scroll_bar
        jmp     _UpdateThumb
.endproc ; _SetHThumbFromViewport

;;; Set vthumb position relative to `maprect` and `ubox`.
.proc _SetVThumbFromViewport
        sub16   viewport+MGTK::Rect::y1, ubox+MGTK::Rect::y1, setthumb_muldiv_params::number
        sub16   ubox+MGTK::Rect::y2, ubox+MGTK::Rect::y1, tmpw
        sub16   tmpw, height, setthumb_muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, setthumb_muldiv_params
        lda     setthumb_muldiv_params::result
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

        scmp16  ubox+MGTK::Rect::x1, viewport+MGTK::Rect::x1
        bmi     activate_hscroll
        scmp16  viewport+MGTK::Rect::x2, ubox+MGTK::Rect::x2
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
        scmp16  ubox+MGTK::Rect::y1, viewport+MGTK::Rect::y1
        bmi     activate_vscroll
        scmp16  viewport+MGTK::Rect::y2, ubox+MGTK::Rect::y2
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
        copy8   #0, pending_alert
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
        ITK_CALL IconTK::EraseIcon, icon_param
        ITK_CALL IconTK::FreeIcon, icon_param
        lda     icon_param
        jsr     FreeDesktopIconPosition
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
        ;; NOTE: Not masked with `UNIT_NUM_MASK`, for `CreateVolumeIcon`.
        jsr     CreateVolumeIcon ; A = unmasked unit num, Y = device index
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
        ITK_CALL IconTK::DrawIcon, icon_param

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

.proc CheckDriveImpl

        ;; After open/eject/rename
by_icon_number:
        lda     #$C0            ; NOTE: This not safe to skip!
        SKIP_NEXT_2_BYTE_INSTRUCTION

        ;; After polling drives
by_index:
        lda     #$00
        SKIP_NEXT_2_BYTE_INSTRUCTION

        ;; After format/erase
by_unit_number:
        lda     #$80

        sta     check_drive_flags
        bit     check_drive_flags
        bpl     have_index
        bvc     map_icon_number

;;; --------------------------------------------------
;;; After an Open/Eject/Rename action

        ;; Map icon number to index in DEVLST
        lda     drive_to_refresh
        jsr     IconToDeviceIndex
        RTS_IF_NOT_ZERO             ; Not found - not a volume icon

        stx     devlst_index
        jmp     have_index

;;; --------------------------------------------------
;;; After a Format/Erase action

map_icon_number:
        ;; Map unit number to index in DEVLST
        ldy     DEVCNT
:       lda     DEVLST,y
        and     #UNIT_NUM_MASK
        cmp     drive_to_refresh
        beq     :+
        dey
        bpl     :-
        iny
:       sty     devlst_index
        jmp     have_index

;;; --------------------------------------------------

        devlst_index := drive_to_refresh

have_index:
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
        copy8   #'/', path_buf+1

close_loop:
        ;; NOTE: This is called within loop because the list
        ;; (`found_windows_count` / `found_windows_list`) is trashed
        ;; during close when animating window.
        param_call FindWindowsForPrefix, path_buf
        ldx     found_windows_count
        beq     not_in_map
        lda     found_windows_list-1,x
        jsr     CloseSpecifiedWindow
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
        jsr     FreeDesktopIconPosition
        ITK_CALL IconTK::EraseIcon, icon_param
        ITK_CALL IconTK::FreeIcon, icon_param

:       lda     cached_window_entry_count
        sta     previous_icon_count
        inc     cached_window_entry_count
        inc     icon_count

        pla
        tay
        lda     DEVLST,y
        ;; NOTE: Not masked with `UNIT_NUM_MASK`, for `CreateVolumeIcon`.
        jsr     CreateVolumeIcon ; A = unmasked unit num, Y = device index

        cmp     #ERR_NOT_PRODOS_VOLUME
    IF_EQ
        param_call ShowAlertParams, AlertButtonOptions::OKCancel, aux::str_alert_unreadable_format
        cmp     #kAlertResultCancel
        RTS_IF_EQ

        ldy     devlst_index
        lda     DEVLST,y
        and     #UNIT_NUM_MASK
        jmp     FormatUnitNum
    END_IF

        cmp     #ERR_DUPLICATE_VOLUME
        beq     err

        bit     check_drive_flags
        bmi     add_icon

        ;; Explicit command
        and     #$FF            ; check `CreateVolumeIcon` results
        beq     add_icon

        ;; Expected errors per Technical Note: ProDOS #21
        ;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/pdos/tn.pdos.21.html
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
        ITK_CALL IconTK::DrawIcon, icon_param

:       jmp     StoreWindowEntryTable

;;; 0 = command, $80 = format/erase, $C0 = open/eject/rename
check_drive_flags:
        .byte   0

.endproc ; CheckDriveImpl

        CheckDriveByIndex := CheckDriveImpl::by_index
        CheckDriveByUnitNumber := CheckDriveImpl::by_unit_number
        CheckDriveByIconNumber := CheckDriveImpl::by_icon_number

;;; ============================================================

.proc CmdStartupItem
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

.proc CmdMakeLinkImpl

;;; Param block written out as new link file
PARAM_BLOCK link_struct, $800
sig1    .byte
sig2    .byte
ver     .byte
path    .byte
END_PARAM_BLOCK

header: .byte   kLinkFileSig1Value, kLinkFileSig2Value, kLinkFileCurrentVersion
        kHeaderSize = * - header

        .define kAliasSuffix ".alias"
suffix: .byte   kAliasSuffix

        DEFINE_CREATE_PARAMS create_params, dst_path_buf, ACCESS_DEFAULT, FT_LINK, kLinkFileAuxType
        DEFINE_OPEN_PARAMS open_params, dst_path_buf, IO_BUFFER
        DEFINE_WRITE_PARAMS write_params, link_struct, 0
        DEFINE_CLOSE_PARAMS close_params

        ;; --------------------------------------------------
        ;; Stash target directory name

;;; Entry point where selection's window is used as target path
target_selection:
        jsr     GetSelectionWindow
        jsr     GetWindowPath
        jsr     CopyToBuf4

;;; Entry point where caller sets `path_buf4`
arbitrary_target:

        ;; --------------------------------------------------
        ;; Prep struct for writing

        lda     selected_icon_list
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
        jne     ShowAlert       ; too long

        ldx     #kHeaderSize-1
:       copy8   header,x, link_struct,x
        dex
        bpl     :-

        COPY_STRING path_buf3, link_struct::path
        lda     link_struct::path
        clc
        adc     #link_struct::path-link_struct+1
        sta     write_params::request_count

        ;; --------------------------------------------------
        ;; Determine the name to use

        ;; Start with original name
        lda     selected_icon_list
        jsr     GetIconName
        stax    $06
        param_call CopyPtr1ToBuf, stashed_name

        ;; Append ".alias"
        lda     stashed_name
        clc
        adc     #.strlen(kAliasSuffix)
        cmp     #kMaxFilenameLength+1
        bcc     :+
        lda     #kMaxFilenameLength
:       tax
        sta     stashed_name
        ldy     #.strlen(kAliasSuffix)-1
:       lda     suffix,y
        sta     stashed_name,x
        dex
        dey
        bpl     :-

        ;; Repeat to find a free name
retry:  param_call CopyToDstPath, path_buf4
        param_call AppendFilenameToDstPath, stashed_name
        jsr     GetDstFileInfo
        bcc     spin
        cmp     #ERR_FILE_NOT_FOUND
        beq     create
        bne     err
spin:   jsr     SpinName
        jmp     retry

        ;; --------------------------------------------------
        ;; Create and write link file
create:
        MLI_CALL CREATE, create_params
        bcs     err

        MLI_CALL OPEN, open_params
        bcs     err
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_CALL WRITE, write_params
        php
        MLI_CALL CLOSE, close_params
        plp
        bcs     err

        ;; Update name case bits on disk, if possible.
        param_call CopyToSrcPath, dst_path_buf
        jsr     ApplyCaseBits ; applies `stashed_name` to `src_path_buf`

        ;; --------------------------------------------------
        ;; Update cached used/free for all same-volume windows, and refresh

        param_call UpdateUsedFreeViaPath, dst_path_buf

        jsr     ShowFileWithPath
        RTS_IF_CS

        ;; Select and rename the file
        jmp     TriggerRenameForFileIconWithStashedName

        ;; --------------------------------------------------
err:    jmp     ShowAlert

.endproc ; CmdMakeLinkImpl
        CmdMakeLink := CmdMakeLinkImpl::target_selection
        MakeLinkInTarget := CmdMakeLinkImpl::arbitrary_target

;;; ============================================================

.proc CmdShowLink
        ;; Assert: single LNK file icon selected
        jsr     GetSingleSelectedIcon
        jsr     GetIconPath     ; `path_buf3` set to path, A=0 on success
        bne     alert           ; too long
        param_call CopyToSrcPath, path_buf3
        jsr     ReadLinkFile
        RTS_IF_CS

        ;; File or volume?
        param_call FindLastPathSegment, src_path_buf ; point Y at last '/'
        cpy     src_path_buf
        jne     ShowFileWithPath

        ;; Volume
        param_call FindIconForPath, src_path_buf
        jne     SelectIconAndEnsureVisible

        lda     #ERR_VOL_NOT_FOUND
alert:  jmp     ShowAlert
.endproc ; CmdShowLink

;;; ============================================================
;;; Given a window, update used/free data for all same-volume windows,
;;; then activate the window (if needed) and refresh the contents
;;; (closing on error).
;;; Same inputs/outputs as `ActivateAndRefreshWindowOrClose`

.proc UpdateActivateAndRefreshSelectedWindow
        lda     selected_window_id
        FALL_THROUGH_TO UpdateActivateAndRefreshWindow
.endproc ; UpdateActivateAndRefreshSelectedWindow

.proc UpdateActivateAndRefreshWindow
        pha
        jsr     GetWindowPath   ; into A,X
        jsr     UpdateUsedFreeViaPath
        pla
        jmp     ActivateAndRefreshWindowOrClose
.endproc ; UpdateActivateAndRefreshWindow

;;; ============================================================
;;; Input: A = icon id
;;; NOTE: It does not activate the icon's window, or scroll the icon
;;; into view.

.proc SelectIcon
        pha
        jsr     ClearSelection
        pla
        pha
        jsr     GetIconWindow
        sta     selected_window_id
        pla
        FALL_THROUGH_TO AddIconToSelection
.endproc ; SelectIcon

;;; ============================================================
;;; Add specified icon to selection list, mark it highlighted, and redraw.
;;; NOTE: This increments `selected_icon_count` and does NOT change
;;; `selected_window_id`
;;; Input: A = icon number
;;; Assert: Icon is in active window/desktop, `selected_window_id` is set.

.proc AddIconToSelection
        sta     icon_param
        ITK_CALL IconTK::HighlightIcon, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param

        lda     icon_param
        FALL_THROUGH_TO AddToSelectionList
.endproc ; AddIconToSelection

;;; ============================================================
;;; Add specified icon to `selected_icon_list`
;;; Inputs: A = icon_num
;;; Outputs: A is not modified
;;; Assert: icon is not present in the list.
;;; NOTE: Does not modify `selected_window_id`.

.proc AddToSelectionList
        ldx     selected_icon_count
        sta     selected_icon_list,x
        inc     selected_icon_count
        rts
.endproc ; AddToSelectionList

;;; ============================================================
;;; Remove specified icon from selection list, and redraw.
;;; Input: A = icon number
;;; Assert: Must be in selection list.

.proc UnhighlightAndDeselectIcon
        sta     icon_param
        ITK_CALL IconTK::UnhighlightIcon, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param

        lda     icon_param
        FALL_THROUGH_TO RemoveFromSelectionList
.endproc ; UnhighlightAndDeselectIcon

;;; ============================================================
;;; Remove specified icon from `selected_icon_list`
;;; Inputs: A = icon_num
;;; Assert: icon is present in the list.
;;; NOTE: Clears `selected_window_id` if count drops to 0.

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
    IF_ZERO
        copy8   #0, selected_window_id
    END_IF
        rts
.endproc ; RemoveFromSelectionList

;;; ============================================================

;;; Calls `ActivateAndRefreshWindow` - on failure (e.g. too
;;; many files) the window is closed.
;;; Input: A = window id
;;; Output: A=0/Z=1/N=0 on success, A=$FF/Z=0/N=1 on failure

.proc ActivateAndRefreshWindowOrClose
        pha
        jsr     _TryActivateAndRefreshWindow
        pla

        bit     exception_flag
        bmi     :+
        return  #0

:       inc     num_open_windows ; was decremented on failure
        jsr     CloseSpecifiedWindow
        return  #$FF

.proc _TryActivateAndRefreshWindow
        ldx     #$80
        stx     exception_flag
        tsx
        stx     saved_stack
        jsr     ActivateAndRefreshWindow
        ldx     #0
        stx     exception_flag
        rts
.endproc ; _TryActivateAndRefreshWindow

exception_flag:
        .byte   0
.endproc ; ActivateAndRefreshWindowOrClose

;;; ============================================================

.proc ActivateAndRefreshWindow
        pha                     ; A = window_id

        ;; Clear selection
        jsr     ClearSelection

        ;; Bring window to front if needed
        pla                     ; A = window_id
        cmp     active_window_id
    IF_NE
        sta     active_window_id
        MGTK_CALL MGTK::SelectWindow, active_window_id
    END_IF

        ;; Clear background
        lda     active_window_id
        jsr     UnsafeSetPortFromWindowId ; CHECKED
        pha                               ; A = obscured?
    IF_ZERO                               ; skip if obscured
        MGTK_CALL MGTK::PaintRect, window_grafport::maprect
    END_IF

        ;; Remove old FileRecords
        lda     active_window_id
        pha                     ; A = `active_window_id`
        jsr     RemoveWindowFileRecords

        ;; Remove old icons
        jsr     LoadActiveWindowEntryTable
        jsr     RemoveAndFreeCachedWindowIcons
        jsr     ClearActiveWindowEntryCount

        ;; Copy window path to `src_path_buf`
        pla                     ; A = `active_window_id`
        pha                     ; A = `active_window_id`
        jsr     GetWindowPath
        jsr     CopyToSrcPath

        ;; Load new FileRecords
        pla                     ; A = `active_window_id`
        jsr     CreateFileRecordsForWindow

        ;; Draw header
        jsr     UpdateWindowUsedFreeDisplayValues
        pla                     ; A = obscured?
    IF_ZERO                     ; skip if obscured
        jsr     LoadActiveWindowEntryTable
        jsr     DrawWindowHeader
    END_IF

        ;; Create icons and draw contents
        jmp     RefreshView
.endproc ; ActivateAndRefreshWindow

;;; ============================================================
;;; Drag Selection
;;; Inputs: A = window_id (0 for desktop)
;;; Assert: `cached_window_id` == A

.proc DragSelect

PARAM_BLOCK, $10
window_id       .byte    ; 0 = desktop, assumed to be active otherwise
delta           .tag    MGTK::Point
initial_pos     .tag    MGTK::Point
last_pos        .tag    MGTK::Point
END_PARAM_BLOCK

        sta     window_id
        jsr     LoadWindowEntryTable

        lda     window_id
    IF_NOT_ZERO
        ;; Map initial event coordinates
        jsr     _CoordsScreenToWindow
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
        jsr     UnsafeSetPortFromWindowIdAndAdjustForEntries ; ASSERT: not obscured
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
        RTS_IF_EQ

        ;; Check if icon should be selected
        txa
        pha
        copy8   cached_window_entry_list,x, icon_param
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
        ;; NOTE: Does not use `AddIconToSelection` because we perform
        ;; a more optimized drawing below.
        ITK_CALL IconTK::HighlightIcon, icon_param
        lda     icon_param
        jsr     AddToSelectionList
        copy8   window_id, selected_window_id
    ELSE
        ;; Unhighlight and remove from selection
        ITK_CALL IconTK::UnhighlightIcon, icon_param
        lda     icon_param
        jsr     RemoveFromSelectionList
    END_IF

        lda     window_id
    IF_ZERO
        ITK_CALL IconTK::DrawIcon, icon_param
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
        jsr     _CoordsScreenToWindow
    END_IF

        ldx     #2              ; loop over dimensions
dloop:
        sub16   event_params::coords,x, last_pos,x, delta,x

        lda     delta+1,x
    IF_NEG
        lda     delta,x        ; negate
        eor     #$FF
        sta     delta,x
        inc     delta,x
    END_IF

        ;; TODO: Experiment with making this lower.
        kDragBoundThreshold = 5

        lda     delta,x
        cmp     #kDragBoundThreshold
        bcs     :+

        dex                     ; next dimension
        dex
        bpl     dloop
        jmp     event_loop

        ;; Beyond threshold; erase rect
:       jsr     FrameTmpRect

        COPY_STRUCT MGTK::Point, event_params::coords, last_pos

        ;; --------------------------------------------------
        ;; Figure out coords for rect's left/top/bottom/right

        ldx     #2              ; loop over dimensions
:       scmp16  event_params::coords,x, initial_pos,x
    IF_NEG
        copy16  event_params::coords,x, tmp_rect::topleft,x
        copy16  initial_pos,x, tmp_rect::bottomright,x
    ELSE
        copy16  initial_pos,x, tmp_rect::topleft,x
        copy16  event_params::coords,x, tmp_rect::bottomright,x
    END_IF
        dex                     ; next dimension
        dex
        bpl     :-

        jsr     FrameTmpRect
        jmp     event_loop

.proc _CoordsScreenToWindow
        jsr     PushPointers
        jsr     PrepActiveWindowScreenMapping

        ;; Point at an imaginary `IconEntry`, to map
        ;; `event_params::coords` from screen to window.
        ldax    #(event_params::coords - IconEntry::iconx)
        jsr     IconPtrScreenToWindow

        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; _CoordsScreenToWindow
.endproc ; DragSelect

;;; ============================================================

.proc DoWindowDrag
        copy8   active_window_id, dragwindow_params::window_id

        jsr     LoadActiveWindowEntryTable
        jsr     CachedIconsScreenToWindow

        MGTK_CALL MGTK::DragWindow, dragwindow_params
        ;; `dragwindow_params::moved` is not checked; harmless if it didn't.

        jsr     CachedIconsWindowToScreen

        rts
.endproc ; DoWindowDrag

;;; ============================================================

.proc DoWindowResize
        copy8   active_window_id, event_params
        MGTK_CALL MGTK::GrowWindow, event_params
        jmp     ScrollUpdate
.endproc ; DoWindowResize

;;; ============================================================

.proc HandleCloseClick
        lda     active_window_id
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        RTS_IF_ZERO

        ;; If modifier is down, close all windows
        jsr     ModifierDown
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

        jsr     RemoveAndFreeCachedWindowIcons

        dec     num_open_windows
        jsr     ClearAndStoreCachedWindowEntryTable

        MGTK_CALL MGTK::CloseWindow, cached_window_id

        ;; --------------------------------------------------
        ;; Do we have a parent icon for this window?

        copy8   #0, icon
        ldx     cached_window_id
        lda     window_to_dir_icon_table-1,x
        bmi     :+              ; is `kWindowToDirIconNone`
        sta     icon
:

        ;; --------------------------------------------------
        ;; Animate closing

        lda     cached_window_id
        jsr     GetWindowPath
        jsr     IconToAnimate
        sta     anim_icon       ; to select later
        ldx     cached_window_id
        jsr     AnimateWindowClose ; A = icon id, X = window id

        ;; --------------------------------------------------
        ;; Tidy up after closing window

        lda     cached_window_id
        jsr     RemoveWindowFileRecords

        ldx     cached_window_id
        ASSERT_EQUALS ::kWindowToDirIconFree, 0
        ASSERT_EQUALS DeskTopSettings::kViewByIcon, 0
        lda     #0
        sta     window_to_dir_icon_table-1,x ; `kWindowToDirIconFree`

        ;; Was it the active window?
        lda     cached_window_id
        cmp     active_window_id
    IF_EQ
        ;; Yes, record the new one
        MGTK_CALL MGTK::FrontWindow, active_window_id
    END_IF

        jsr     ClearUpdates ; following CloseWindow above

        ;; --------------------------------------------------
        ;; Clean up the parent icon (if any)

        icon := *+1
        lda     #SELF_MODIFIED_BYTE
    IF_NE
        jsr     MarkIconNotDimmedNoDraw
        ;; Assert: `icon` == `anim_icon`, and will get redrawn next.
    END_IF

        ;; --------------------------------------------------
        ;; Select the ancestor icon that was animated into

        anim_icon := *+1
        lda     #SELF_MODIFIED_BYTE
        jmp     SelectIcon

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
        copy8   #0, validate_windows_flag

        copy8   #kMaxDeskTopWindows, window_id

loop:
        ;; Check if the window is in use
        window_id := *+1
        ldx     #SELF_MODIFIED_BYTE
        lda     window_to_dir_icon_table-1,x
        beq     next            ; is `kWindowToDirIconFree`

        ;; Get and copy its path somewhere useful
        txa
        jsr     GetWindowPath
        jsr     CopyToSrcPath

        ;; See if it exists
        jsr     GetSrcFileInfo
        bcc     next

        ;; Nope - close the window
        lda     window_id
        jsr     CloseSpecifiedWindow

next:   dec     window_id
        bne     loop

done:   rts
.endproc ; ValidateWindows

;;; ============================================================

.proc ApplyActiveWinfoToWindowGrafport
        lda     active_window_id
        FALL_THROUGH_TO ApplyWinfoToWindowGrafport
.endproc ; ApplyActiveWinfoToWindowGrafport

.proc ApplyWinfoToWindowGrafport
        ptr := $06

        jsr     GetWindowPtr
        addax   #MGTK::Winfo::port, ptr
        ldy     #.sizeof(MGTK::GrafPort) - 1
:       lda     (ptr),y
        sta     window_grafport,y
        dey
        bpl     :-
        rts
.endproc ; ApplyWinfoToWindowGrafport

;;; NOTE: Does not update icon positions, so only use in empty windows.
.proc ResetActiveWindowViewport
        jsr     ApplyActiveWinfoToWindowGrafport
        ldx     #2              ; loop over dimensions
:       sub16   window_grafport::maprect::bottomright,x, window_grafport::maprect::topleft,x, window_grafport::maprect::bottomright,x
        copy16  #0, window_grafport::maprect::topleft,x
        dex                     ; next dimension
        dex
        bpl     :-
        FALL_THROUGH_TO AssignActiveWindowCliprect
.endproc ; ResetActiveWindowViewport

.proc AssignActiveWindowCliprect
        ptr := $6

        lda     active_window_id
        jsr     GetWindowPtr
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

;;; If there's a single icon selected, return it. Otherwise,
;;; return zero.
;;; Z=0 and A=icon num if only one, Z=0 and A=0 otherwise
.proc GetSingleSelectedIcon
        lda     selected_icon_count
        cmp     #1
    IF_NE
        lda     #0
        rts
    END_IF
        lda     selected_icon_list
        rts
.endproc ; GetSingleSelectedIcon

;;; ============================================================
;;; Open a folder/volume, either by icon or path
;;; `OpenWindowForIcon`
;;; Input: A = icon
;;; `OpenWindowForPath`
;;; Input: `src_path_buf` populated
;;; Note: stack will be restored via `saved_stack` on failure

.proc OpenWindowImpl

        ;; --------------------------------------------------
        ;; A = icon, `src_path_buf` not set
for_icon:
        sta     icon_param      ; stash for later

        ;; Already an open window for the icon?
        jsr     FindWindowIndexForDirIcon
    IF_EQ
        inx
        txa
        jmp     ActivateWindow  ; no-op if already active
    END_IF

        ;; Compute the path, if it fits
        lda     icon_param
        jsr     GetIconPath     ; `path_buf3` set to path, A=0 on success
    IF_NOT_ZERO
        jsr     ShowAlert       ; A has error if `GetIconPath` fails
        ldx     saved_stack
        txs
        rts
    END_IF
        param_call CopyToSrcPath, path_buf3 ; set `src_path_buf`
        jmp     no_win

        ;; --------------------------------------------------
        ;; `src_path_buf` set by caller
for_path:
        jsr     ClearSelection
        copy8   #kWindowToDirIconNone, icon_param

        ;; Already an open window for the path?
        jsr     FindWindowForSrcPath
        jne     ActivateWindow  ; no-op if already active

        ;; Find icon, if it exists
        param_call FindIconForPath, src_path_buf
    IF_NOT_ZERO
        sta     icon_param
    END_IF

        FALL_THROUGH_TO no_win

        ;; --------------------------------------------------
        ;; No window - need to open one.

        ;; `src_path_buf` has path
        ;; `icon_param` has icon (or `kWindowToDirIconNone`)

        ptr := $06
no_win:
        ;; Is there a free window?
        lda     num_open_windows
        cmp     #kMaxDeskTopWindows
        bcc     :+

        ;; Nope, show error.
        param_call ShowAlertParams, AlertButtonOptions::OK, aux::str_warning_too_many_windows
        ldx     saved_stack
        txs
        rts

        ;; Search window-icon map to find an unused window.
:       ldx     #0
:       lda     window_to_dir_icon_table,x
        beq     :+              ; is `kWindowToDirIconFree`
        inx
        jmp     :-

        ;; Map the window to its source icon
:       lda     icon_param      ; possibly `kWindowToDirIconNone` if opening via path
        sta     window_to_dir_icon_table,x
        inx                     ; 0-based to 1-based

        txa
        jsr     LoadWindowEntryTable

        ;; Update View and other menus
        inc     num_open_windows

        ldx     #DeskTopSettings::default_view
        jsr     ReadSetting
        sta     initial_view_by

        lda     icon_param
        bmi     :+              ; no source icon, use default
        jsr     GetIconWindow
        beq     :+              ; not windowed, use default
        tax
        copy8   win_view_by_table-1,x, initial_view_by
:
        ldx     cached_window_id
        initial_view_by := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     win_view_by_table-1,x

        ;; This ensures `ptr` points at IconEntry (real or virtual)
        ;; and marks/paints the icon (if there is one) as dimmed.
        jsr     _UpdateIcon

        ;; Set path (using `ptr`), size, contents, and volume free/used.
        jsr     _PrepareNewWindow

        ;; Create the window
        lda     cached_window_id
        jsr     GetWindowPtr   ; A,X points at Winfo
        stax    @addr
        MGTK_CALL MGTK::OpenWindow, 0, @addr

        jsr     DrawCachedWindowHeaderAndEntries
        jmp     ScrollUpdate

;;; Common code to update the dir (vol/folder) icon.
;;; * If `icon_param` is valid:
;;;   Points `ptr` at IconEntry, marks it open and repaints it, and sets `ptr`.
;;; * Otherwise:
;;;   Points `ptr` at a virtual IconEntry, to allow referencing the icon name.
.proc _UpdateIcon
        lda     icon_param      ; set to `kWindowToDirIconNone` if opening via path
        jpl     MarkIconDimmed

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
        sta     filename_buf,x
        cpy     src_path_buf
        bne     :-

        stx     filename_buf

        ;; Adjust ptr as if it's pointing at an IconEntry
        copy16  #filename_buf - IconEntry::name, ptr
        rts
.endproc ; _UpdateIcon

;;; ------------------------------------------------------------
;;; Set up path and coords for new window, contents and free/used.
;;; Inputs: IconEntry pointer in $06, new window id in `cached_window_id`,
;;;         `src_path_buf` has full path
;;; Outputs: Winfo configured, window path table entry set

.proc _PrepareNewWindow
        icon_ptr := $06

        ;; Copy icon name to window title
.scope
        name_ptr := icon_ptr
        title_ptr := $08

        jsr     PushPointers

        lda     cached_window_id
        jsr     GetWindowTitle
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
        jsr     GetWindowPtr
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
        ASSERT_EQUALS MGTK::Winfo::vscroll, MGTK::Winfo::hscroll + 1
        iny
        sta     (winfo_ptr),y

        ;; --------------------------------------------------
        ;; Read FileRecords

        lda     cached_window_id
        jsr     CreateFileRecordsForWindow

        ;; --------------------------------------------------
        ;; Update used/free table

        lda     icon_param      ; set to `kWindowToDirIconNone` if opening via path
    IF_NC
        ;; If a windowed icon, source from that
        jsr     GetIconWindow
      IF_NOT_ZERO
        ;; Windowed (folder) icon
        asl     a
        tax
        copy16  window_k_used_table-2,x, vol_kb_used ; 1-based to 0-based
        copy16  window_k_free_table-2,x, vol_kb_free
      END_IF
    END_IF

        ;; Used cached window's details, which are correct now.
        lda     cached_window_id
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
        ;; DeskTopSettings::kViewByXXX
        ldx     cached_window_id
        copy8   new_window_view_by, win_view_by_table-1,x

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
        ;; Animate the window being opened

        lda     cached_window_id
        jsr     GetWindowPath
        jsr     IconToAnimate
        ldx     cached_window_id
        jsr     AnimateWindowOpen

        rts
.endproc ; _PrepareNewWindow

.endproc ; OpenWindowImpl
OpenWindowForIcon := OpenWindowImpl::for_icon
OpenWindowForPath := OpenWindowImpl::for_path

;;; ============================================================
;;; Marks icon as open and repaints it.
;;; Input: A = icon id
;;; Output: `ptr` ($06) points at IconEntry

.proc MarkIconDimmed
        sta     icon_param      ; Needed for `IconTK::DrawIcon` call below

        ptr := $06
        jsr     GetIconEntry
        stax    ptr

        ;; Set dimmed flag
        ldy     #IconEntry::state
        lda     (ptr),y
        ora     #kIconEntryStateDimmed
        sta     (ptr),y

        ITK_CALL IconTK::DrawIcon, icon_param
        rts
.endproc ; MarkIconDimmed

;;; ============================================================
;;; Mark the icon as not open; does not redraw as not all clients need
;;; it, e.g. if they will subsequently select the icon.
;;; Input: A = `icon_id`
;;; Trashes $06

.proc MarkIconNotDimmedNoDraw
        ptr := $06
        jsr     GetIconEntry
        stax    ptr

        ;; Clear dimmed flag
        ldy     #IconEntry::state
        lda     (ptr),y
        and     #AS_BYTE(~kIconEntryStateDimmed)
        sta     (ptr),y

        ;; Redrawing is left to caller
        rts
.endproc ; MarkIconNotDimmedNoDraw

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
        copy8   #kWindowToDirIconFree, window_to_dir_icon_table,x
    END_IF

        ;; Update the icon and redraw
        lda     icon_param
        jsr     MarkIconNotDimmedNoDraw
        ITK_CALL IconTK::DrawIcon, icon_param

ret:    rts
.endproc ; MarkIconNotDimmed

;;; ============================================================
;;; Give a file path, tries to open/show a window for the containing
;;; directory, and if successful select/show the file.
;;; Input: `INVOKER_PREFIX` has full path to file
;;; Output: C=0 on success
;;; Assert: Path is not a volume path

.proc ShowFileWithPath
        jsr     SplitInvokerPath

        lda     num_open_windows
        sta     old

        tsx
        stx     saved_stack
        jsr     OpenWindowForPath

        ;; If an existing window was shown, refresh the contents.
        lda     num_open_windows
        old := *+1
        cmp     #SELF_MODIFIED_BYTE
    IF_EQ
        lda     active_window_id
        jsr     ActivateAndRefreshWindowOrClose
        bne     err
    END_IF

        param_call SelectFileIconByName, INVOKER_FILENAME
        clc
        rts

err:    sec
        rts
.endproc ; ShowFileWithPath

;;; ============================================================
;;; Find an icon for a given path. May be volume or in any window.
;;;
;;; Inputs: A,X has path
;;; Output: A=icon id and Z=0 if found, Z=1 if no match
;;; Trashes $06 and `path_buf4`

.proc FindIconForPath
        jsr     CopyToBuf4
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
        RTS_IF_ZERO             ; no matching window

        tay                     ; Y=window id
        ldax    #filename_buf   ; A,X=filename
    END_IF
        jmp     FindIconByName
.endproc ; FindIconForPath

;;; ============================================================
;;; Draw all entries (icons or list items) in (cached) window

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc DrawWindowEntries
        ;; --------------------------------------------------
        ;; Icons

        ;; Map icons to window space
        jsr     CachedIconsScreenToWindow

        ITK_CALL IconTK::DrawAll, cached_window_id

.ifdef DEBUG
        jsr     ComputeIconsBBox
        COPY_BLOCK iconbb_rect, tmp_rect
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
        stax    pos_col::ycoord

        ;; Draw each list view row
        ldx     #0              ; X = index
rloop:  cpx     cached_window_entry_count
        beq     done
        txa                     ; A = index
        pha
        lda     cached_window_entry_list,x

        ;; Look up file record number
        jsr     GetIconRecordNum
        jsr     DrawListViewRow

        MGTK_CALL MGTK::CheckEvents

        pla                     ; A = index
        tax                     ; X = index
        inx
        jmp     rloop

        ;; --------------------------------------------------
done:
        rts
.endproc ; DrawWindowEntries

;;; ============================================================
;;; Retrieve the `IconEntry::record_num` for a given icon.
;;; Input: A = icon id
;;; Output: A = icon's record index in its window
;;; Trashes $06

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc GetIconRecordNum
        jsr     GetIconEntry
        ptr := $06
        stax    ptr
        ldy     #IconEntry::record_num
        lda     (ptr),y
        rts
.endproc ; GetIconRecordNum

;;; ============================================================

.proc ClearSelection
        lda     selected_icon_count
        RTS_IF_ZERO

        ;; --------------------------------------------------
        ;; Mark the icons as not highlighted
        ldx     #0
:       txa
        pha
        copy8   selected_icon_list,x, icon_param
        ITK_CALL IconTK::UnhighlightIcon, icon_param
        pla
        tax
        inx
        cpx     selected_icon_count
        bne     :-

        ;; --------------------------------------------------
        ;; Repaint the icons

        jsr     RedrawSelectedIcons

        ;; --------------------------------------------------
        ;; Clear selection list
        lda     #0
        sta     selected_icon_count
        sta     selected_window_id
        rts
.endproc ; ClearSelection

;;; ============================================================

;;; Repaint all selected icons. This uses a fast path if selection
;;; is in the active window, since a clipped port is sufficient.
;;; Otherwise, IconTK's smart (but slow) clipping is used.

.proc RedrawSelectedIcons
        lda     selected_window_id
        beq     unoptimized     ; Desktop

        cmp     active_window_id
        bne     unoptimized

        ;; --------------------------------------------------
        ;; Fast path. Since selection is in the top-most window,
        ;; drawing can be done using `IconTK::DrawIconRaw` in a
        ;; clipped port.

        jsr     UnsafeSetPortFromWindowIdAndAdjustForEntries ; CHECKED
        RTS_IF_NOT_ZERO                            ; obscured

        jsr     PushPointers
        jsr     PrepActiveWindowScreenMapping

        ldx     #0
:       txa
        pha                     ; A = index
        copy8   selected_icon_list,x, icon_param
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
        rts

        ;; --------------------------------------------------
        ;; Slow path. This uses `IconTK::DrawIcon` which clips icons
        ;; against overlapping windows.

unoptimized:
        ldx     #0
:       txa
        pha
        copy8   selected_icon_list,x, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param
        pla
        tax
        inx
        cpx     selected_icon_count
        bne     :-

        rts
.endproc ; RedrawSelectedIcons

;;; ============================================================

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc CachedIconsScreenToWindow
        param_jump _CachedIconsXToY, IconPtrScreenToWindow
.endproc ; CachedIconsScreenToWindow

;;; ============================================================

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc CachedIconsWindowToScreen
        param_jump _CachedIconsXToY, IconPtrWindowToScreen
.endproc ; CachedIconsWindowToScreen

;;; ============================================================

;;; Inputs: A,X = proc to call for each icon
;;; Note: No-op if `cached_window_id` = 0 (desktop)
        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc _CachedIconsXToY
        stax    proc

        jsr     PushPointers
        lda     cached_window_id
        beq     done
        jsr     PrepWindowScreenMapping

        copy8   #0, index
        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     cached_window_entry_count
        beq     done

        tax
        lda     cached_window_entry_list,x
        jsr     GetIconEntry
        proc := *+1
        jsr     SELF_MODIFIED

        inc     index
        jmp     loop

done:   jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc ; _CachedIconsXToY

;;; ============================================================
;;; Adjust grafport for header.

.proc AdjustWindowPortForEntries
        add16_8 window_grafport::viewloc::ycoord, #kWindowHeaderHeight
        add16_8 window_grafport::maprect::y1, #kWindowHeaderHeight
        MGTK_CALL MGTK::SetPort, window_grafport
        rts
.endproc ; AdjustWindowPortForEntries

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
;;; Refresh vol used/free for windows of same volume as path in A,X.
;;; Input: A = window id

.proc UpdateUsedFreeViaPath
        ptr := $6

        stax    ptr
        jsr     PushPointers    ; save $06 = path

        ;; Save original length
        ldy     #0
        lda     (ptr),y
        pha

        param_call_indirect MakeVolumePath, ptr

        ;; Update `found_windows_count` and `found_windows_list`
        param_call_indirect FindWindowsForPrefix, ptr

        ;; Restore path length
        pla
        ldy     #0
        sta     (ptr),y

        ;; Determine if there are windows to update
        jsr     PopPointers     ; $06 = vol path

        ldax    ptr
        jsr     CopyToSrcPath
        jsr     GetVolUsedFreeViaPath
        bne     done

        ldy     found_windows_count
        beq     done
loop:   lda     found_windows_list-1,y
        asl     a
        tax
        copy16  vol_kb_used, window_k_used_table-2,x ; 1-based to 0-based
        copy16  vol_kb_free, window_k_free_table-2,x
        dey
        bne     loop

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
        beq     loop            ; is `kWindowToDirIconFree`

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

.proc CreateFileRecordsForWindowImpl
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

record_count:           .byte   0

.proc _Start
        sta     window_id
        jsr     PushPointers
        jsr     SetCursorWatch ; before loading directory

        jsr     _DoOpen
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        jsr     _DoRead
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
        jsr     _DoClose

        ldax    #aux::str_warning_window_must_be_closed ; too many files to show
        ldy     active_window_id ; is a window open?
        bne     :+
        ldax    #aux::str_warning_too_many_files ; suggest closing a window
:       ldy     #AlertButtonOptions::OK
        jsr     ShowAlertParams ; A,X = string, Y = AlertButtonOptions

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

        copy8   #AS_BYTE(-1), index_in_dir ; immediately incremented
        copy8   #0, index_in_block
        copy8   #0, record_count

        jsr     PushPointers    ; save initial `record_ptr`

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

next:   inc     index_in_block
        lda     index_in_block
        cmp     dir_header::entries_per_block
        beq     L71E7
        add16_8 entry_ptr, dir_header::entry_length
        jmp     L71F7

L71E7:  copy8   #$00, index_in_block
        copy16  #$0C04, entry_ptr
        jsr     _DoRead

L71F7:  ldx     #$00
        ldy     #$00
        lda     (entry_ptr),y
        and     #$0F
        beq     next            ; inactive entry
        sta     record,x

        ldx     #DeskTopSettings::options
        jsr     ReadSetting
        and     #DeskTopSettings::kOptionsShowInvisible
    IF_ZERO
        ldy     #FileEntry::access
        lda     (entry_ptr),y
        and     #ACCESS_I
        bne     do_entry
    END_IF

        inc     record_count

        ;; See FileRecord struct for record structure

        param_call_indirect AdjustFileEntryCase, entry_ptr

        ;; Point at first character
        ldx     #FileRecord::name+1
        ldy     #FileEntry::file_name

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

        ;; Store record count
        jsr     PopPointers     ; restore `record_ptr` to list start
        bit     LCBANK2
        bit     LCBANK2
        lda     record_count
        ldy     #0
        sta     (record_ptr),y
        bit     LCBANK1
        bit     LCBANK1

        jsr     _DoClose
        jsr     SetCursorPointer ; after loading directory
        jsr     PopPointers      ; do not tail-call optimise!
        rts
.endproc ; _Start

;;; --------------------------------------------------

.proc _DoOpen
        MLI_CALL OPEN, open_params
        bcc     done

        ;; On error, clean up state

        ;; Show error, unless this is during window restore.
        bit     suppress_error_on_open_flag
        bmi     :+
        jsr     ShowAlert

        ;; If opening an icon, need to reset icon state.
:       bit     icon_param      ; Were we opening a path?
        bmi     :+              ; Yes, no icons to twiddle.

        jsr     MarkIconNotDimmed

        lda     selected_window_id
        bne     :+

        ;; Volume icon - check that it's still valid.
        lda     icon_param
        sta     drive_to_refresh ; icon_number
        jsr     CheckDriveByIconNumber

        ;; A window was allocated but unused, so restore the count.
:       dec     num_open_windows

        ;; A table entry was possibly allocated - free it.
        ldy     cached_window_id
        dey
        bmi     :+
        lda     #kWindowToDirIconFree
        sta     window_to_dir_icon_table,y
        sta     cached_window_id

        ;; And return via saved stack.
:       jsr     SetCursorPointer
        ldx     saved_stack
        txs

done:   rts
.endproc ; _DoOpen

suppress_error_on_open_flag:
        .byte   0

;;; --------------------------------------------------

.proc _DoRead
        MLI_CALL READ, read_params
        rts
.endproc ; _DoRead

.proc _DoClose
        MLI_CALL CLOSE, close_params
        rts
.endproc ; _DoClose

;;; --------------------------------------------------
.endproc ; CreateFileRecordsForWindowImpl
CreateFileRecordsForWindow := CreateFileRecordsForWindowImpl::_Start

;;; ============================================================
;;; Inputs: `src_path_buf` set to full path (not modified)
;;; Outputs: Z=1 on success, `vol_kb_used` and `vol_kb_free` updated.
;;; TODO: Skip if same-vol windows already have data.

.proc GetVolUsedFreeViaPath
        copy8   src_path_buf, saved_length

        ;; Strip to vol name - either end of string or next slash
        param_call MakeVolumePath, src_path_buf

        ;; Get volume information
        jsr     GetSrcFileInfo
        bcs     finish          ; failure

        ;; aux = total blocks
        copy16  src_file_info_params::blocks_used, vol_kb_used
        ;; total - used = free
        sub16   src_file_info_params::aux_type, vol_kb_used, vol_kb_free

        ;; Blocks to K
        lsr16   vol_kb_free
        lsr16   vol_kb_used
        lda     #0              ; success

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

.proc RemoveWindowFileRecords
        ;; Find address of FileRecord list
        jsr     FindIndexInFileRecordListEntries
        RTS_IF_ZC

        ;; Move list entries down by one
        stx     index
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

        deltam  := $0A          ; memory delta
        size    := $0C          ; size of a window's list

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
.endproc ; RemoveWindowFileRecords


copy_new_window_bounds_flag:
        .byte   0

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
        jsr     GetWindowPtr
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
        tmpw := $08

        ;; No-op if window is empty
        lda     cached_window_entry_count
        beq     ret

        lda     cached_window_id
        jsr     GetWindowPtr
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
.endproc ; AdjustViewportForNewIcons


;;; ============================================================
;;; Map file type (etc) to icon type

;;; Input: `src_file_info_params` (`file_type`, `aux_type`, `blocks_used`) and A,X = filename
;;; Output: A is IconType to use (for icons, open/preview, etc)

.proc DetermineIconType
        ptr := $06
        flags := $08
        ptr_filename := $0A

        file_type   := src_file_info_params::file_type
        aux_type    := src_file_info_params::aux_type
        blocks_used := src_file_info_params::blocks_used

        stax    ptr_filename

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
:       and     file_type       ; A = type & mask
        iny                     ; ASSERT: Y = ICTRecord::filetype
        ASSERT_EQUALS ICTRecord::filetype, ICTRecord::mask+1
        cmp     (ptr),y         ; type check
        jne     next

        ;; Flags
        iny                     ; ASSERT: Y = ICTRecord::flags
        ASSERT_EQUALS ICTRecord::flags, ICTRecord::filetype+1
        lda     (ptr),y
        sta     flags

        ;; Does Aux Type matter, and if so does it match?
        bit     flags
    IF_NS                       ; bit 7 = compare aux
        iny                     ; ASSERT: Y = FTORecord::aux_suf
        ASSERT_EQUALS ICTRecord::aux_suf, ICTRecord::flags+1
        lda     aux_type
        cmp     (ptr),y
        bne     next
        iny
        lda     aux_type+1
        cmp     (ptr),y
        bne     next
    END_IF

        ;; Does Block Count matter, and if so does it match?
        bit     flags
    IF_VS                       ; bit 6 = compare blocks
        ldy     #ICTRecord::blocks
        lda     blocks_used
        cmp     (ptr),y
        bne     next
        iny
        lda     blocks_used+1
        cmp     (ptr),y
        bne     next
    END_IF

        ;; Filename suffix?
        lda     flags
        and     #ICT_FLAGS_SUFFIX
    IF_NOT_ZERO
        ;; Set up pointers to suffix and filename
        ptr_suffix      := $08
        ldy     #ICTRecord::aux_suf
        copy16in (ptr),y, ptr_suffix
        ;; Start at the end of the strings
        ldy     #0
        lda     (ptr_suffix),y
        sta     suffix_pos
        lda     (ptr_filename),y
        sta     filename_pos
:
        ;; Case-insensitive compare each character
        filename_pos := *+1
        ldy     #SELF_MODIFIED_BYTE
        lda     (ptr_filename),y
        jsr     ToUpperCase
        suffix_pos := *+1
        ldy     #SELF_MODIFIED_BYTE
        cmp     (ptr_suffix),y  ; already uppercase
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
        jsr     PopPointers
        rts

        ;; Next entry
next:   add16_8 ptr, #.sizeof(ICTRecord)
        jmp     loop
.endproc ; DetermineIconType

;;; ============================================================

;;; Input: $08 = `FileRecord` pointer
.proc FileRecordToSrcFileInfo
        file_record := $08
        ldy     #FileRecord::file_type
        copy8   (file_record),y, src_file_info_params::file_type
        ldy     #FileRecord::aux_type
        copy16in (file_record),y, src_file_info_params::aux_type
        ldy     #FileRecord::blocks
        copy16in (file_record),y, src_file_info_params::blocks_used
        rts
.endproc ; FileRecordToSrcFileInfo

;;; ============================================================
;;; Draw header (items/K in disk/K available/lines) for `cached_window_id`

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc DrawWindowHeader

;;; Local variables on ZP
PARAM_BLOCK, $50
num_items               .word
k_in_disk               .word
k_available             .word

width_num_items         .word
width_k_in_disk         .word
width_k_available       .word

ptr_str_items_suffix    .addr
END_PARAM_BLOCK

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
        lda     cached_window_id
        jsr     GetFileRecordCountForWindow
        ldx     #0
        stax    num_items

        tay
        ldax    #str_items_suffix
        cpy     #1
    IF_EQ
        ldax    #str_item_suffix
    END_IF
        stax    ptr_str_items_suffix

        ldx     cached_window_id
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
        jsr     _MeasureIntString
        stax    width_num_items
        param_call_indirect _MeasureString, ptr_str_items_suffix
        addax   width_num_items

        ldax    k_in_disk
        jsr     _MeasureIntString
        stax    width_k_in_disk
        param_call _MeasureString, str_k_in_disk
        addax   width_k_in_disk

        ldax    k_available
        jsr     _MeasureIntString
        stax    width_k_available
        param_call _MeasureString, str_k_available
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
        jsr     _DrawIntString
        param_call_indirect DrawString, ptr_str_items_suffix

        ;; Draw "XXXK in disk"
        MGTK_CALL MGTK::Move, header_text_delta
        ldax    k_in_disk
        jsr     _DrawIntString
        param_call DrawString, str_k_in_disk

        ;; Draw "XXXK available"
        MGTK_CALL MGTK::Move, header_text_delta
        ldax    k_available
        jsr     _DrawIntString
        param_jump DrawString, str_k_available

.proc _DrawIntString
        jsr     IntToStringWithSeparators
        param_jump DrawString, str_from_int
.endproc ; _DrawIntString

.proc _MeasureIntString
        jsr     IntToStringWithSeparators
        ldax    #str_from_int
        FALL_THROUGH_TO _MeasureString
.endproc ; _MeasureIntString

;;; Measure text, pascal string address in A,X; result in A,X
;;; String must be in LC area (visible to both main and aux code)
.proc _MeasureString
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
.endproc ; _MeasureString

.endproc ; DrawWindowHeader

;;; ============================================================
;;; Compute bounding box for icons within cached window
;;; Inputs: `cached_window_id` is set

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
        ;; List view?
        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
      IF_NEG
        ;; max.x = kListViewWidth
        add16   iconbb_rect::x1, #kListViewWidth, iconbb_rect::x2
      END_IF

        ;; Add padding around bbox
        MGTK_CALL MGTK::InflateRect, bbox_pad_iconbb_rect
    END_IF

        rts

more:   lda     cached_window_entry_list,x
        sta     icon_param
        ITK_CALL IconTK::GetIconBounds, icon_param ; inits `tmp_rect`

        jsr     GetCachedWindowViewBy
        ASSERT_EQUALS DeskTopSettings::kViewByIcon, 0
    IF_ZERO
        ;; Pretend icon is max height
        sub16   tmp_rect::y2, #kMaxIconTotalHeight, tmp_rect::y1
    END_IF

        lda     icon_num
    IF_ZERO
        ;; First icon (index 0) - just use its coordinates as min/max
        COPY_BLOCK tmp_rect, iconbb_rect
    ELSE
        ;; Expand bounding rect to encompass icon's rect
        MGTK_CALL MGTK::UnionRects, unionrects_tmp_iconbb
    END_IF

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
;;; Inputs: `cached_window_id` is set
;;; Outputs: Populates `cached_window_entry_count` with count and
;;;          `cached_window_entry_list` with indexes 1...N
;;; Assert: LCBANK1 is active

.proc InitWindowEntriesAndIcons
        ;; --------------------------------------------------
        ;; Create generic entries for window

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

        ;; --------------------------------------------------
        ;; Sort (if needed)

        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
    IF_NEG
        jsr     SortRecords
    END_IF

        ;; --------------------------------------------------
        ;; Create icons

        jsr     _CreateIconsForWindow
        jmp     StoreWindowEntryTable

;;; ------------------------------------------------------------
;;; File Icon Entry Construction
;;; Inputs: `cached_window_id` must be set

.proc _CreateIconsForWindow

;;; Local variables on ZP
PARAM_BLOCK, $50
icon_type       .addr
icon_flags      .byte
icon_height     .word

        ;; Updated based on view type
initial_xcoord  .word
icons_this_row  .byte

        ;; Initial values when populating a list view
icons_per_row   .byte
col_spacing     .byte
row_spacing     .byte
icon_coords     .tag    MGTK::Point
END_PARAM_BLOCK
        init_view := icons_per_row
        init_view_size = 3 + .sizeof(MGTK::Point)

        jsr     PushPointers

        ;; Select the template
        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
    IF_NEG
        ldy     #init_list_view - init_views + init_view_size-1
    ELSE
        ASSERT_EQUALS DeskTopSettings::kViewByIcon, 0
      IF_ZERO
        ldy     #init_icon_view - init_views + init_view_size-1
      ELSE
        ldy     #init_smicon_view - init_views + init_view_size-1
      END_IF
    END_IF

        ;; Populate the initial values from the template
        ldx     #init_view_size-1
:       lda     init_views,y
        sta     init_view,x
        dey
        dex
        bpl     :-

        ;; Init/zero out the rest of the state
        copy16  icon_coords+MGTK::Point::xcoord, initial_xcoord

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

        copy8   #0, cached_window_entry_count

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
        ASSERT_EQUALS .sizeof(FileRecord), 32
        jsr     ATimes32        ; A,X = A * 32
        record_ptr := $08
        addax   records_base_ptr, record_ptr
        pla                     ; A = record_num-1
        jsr     _AllocAndPopulateFileIcon

        inc     index
        bne     :-              ; always
:
        jsr     CachedIconsWindowToScreen
        jsr     PopPointers     ; do not tail-call optimise!
        rts

        ;; Templates for populating initial values, based on view type
init_views:
init_list_view:
        .byte   1, 0, kListItemHeight
        .word   kListViewInitialLeft, kListViewInitialTop
        ASSERT_EQUALS * - init_list_view, init_view_size
init_icon_view:
        .byte   kIconViewIconsPerRow, kIconViewSpacingX, kIconViewSpacingY
        .word   kIconViewInitialLeft, kIconViewInitialTop
        ASSERT_EQUALS * - init_icon_view, init_view_size
init_smicon_view:
        .byte   kSmallIconViewIconsPerRow, kSmallIconViewSpacingX, kSmallIconViewSpacingY
        .word   kSmallIconViewInitialLeft, kSmallIconViewInitialTop
        ASSERT_EQUALS * - init_smicon_view, init_view_size

records_base_ptr:
        .word   0

;;; ============================================================
;;; Create icon
;;; Inputs: A = record_num, $08 = `FileRecord`

.proc _AllocAndPopulateFileIcon
        icon_entry  := $06
        file_record := $08
        name_tmp := $1800

        pha                     ; A = record_num

        inc     icon_count
        ITK_CALL IconTK::AllocIcon, get_icon_entry_params
        copy16  get_icon_entry_params::addr, icon_entry
        lda     get_icon_entry_params::id
        sta     icon_num
        ldx     cached_window_entry_count
        inc     cached_window_entry_count
        sta     cached_window_entry_list,x

        ;; Assign record number
        pla                     ; A = record_num
        ldy     #IconEntry::record_num
        sta     (icon_entry),y

        ;; Bank in the `FileRecord` entries
        bit     LCBANK2
        bit     LCBANK2

        ;; Copy the name out
        ASSERT_EQUALS FileRecord::name, 0
        ldy     #kMaxFilenameLength
:       lda     (file_record),y
        sta     name_tmp,y
        dey
        bpl     :-

        ;; Copy out file metadata needed to determine icon type
        jsr     FileRecordToSrcFileInfo ; uses `FileRecord` ptr in $08

        ;; Done with `FileRecord` entries
        bit     LCBANK1
        bit     LCBANK1

        ;; Determine icon type
        jsr     GetCachedWindowViewBy
        sta     view_by
        ldax    #name_tmp
        jsr     DetermineIconType ; uses passed name and `src_file_info_params`
        view_by := *+1
        ldy     #SELF_MODIFIED_BYTE
        jsr     _FindIconDetailsForIconType

        ;; Copy name into `IconEntry`
        ldy     #IconEntry::name + kMaxFilenameLength
        ldx     #kMaxFilenameLength
:       lda     name_tmp,x
        sta     (icon_entry),y
        dey
        dex
        bpl     :-

        ;; Assign location
        ldy     #IconEntry::iconx + .sizeof(MGTK::Point) - 1
        ldx     #.sizeof(MGTK::Point) - 1
:       lda     icon_coords,x
        sta     (icon_entry),y
        dey
        dex
        bpl     :-

        jsr     GetCachedWindowViewBy
        ASSERT_EQUALS DeskTopSettings::kViewByIcon, 0
    IF_ZERO
        ;; Icon view: include y-offset
        ldy     #IconEntry::icony
        sub16in (icon_entry),y, icon_height, (icon_entry),y
    END_IF

        ;; Next col
        add16_8 icon_coords+MGTK::Point::xcoord, col_spacing
        inc     icons_this_row
        ;; Next row?
        lda     icons_this_row
        cmp     icons_per_row
    IF_EQ
        add16_8 icon_coords+MGTK::Point::ycoord, row_spacing
        copy16  initial_xcoord, icon_coords+MGTK::Point::xcoord
        copy8   #0, icons_this_row
    END_IF

        ;; Assign `IconEntry::win_flags`
        lda     cached_window_id
        ora     icon_flags
        ldy     #IconEntry::win_flags
        sta     (icon_entry),y

        ;; Assign `IconEntry::type`
        ldy     #IconEntry::type
        copy8   icon_type, (icon_entry),y

        ;; If folder, see if there's an associated window
        lda     src_file_info_params::file_type
        cmp     #FT_DIRECTORY
        bne     :+
        icon_num := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
        bne     :+              ; too long

        jsr     PushPointers
        param_call FindWindowForPath, path_buf3
        jsr     PopPointers
        tax                     ; A = window id, 0 if none
        beq     :+
        lda     icon_num
        sta     window_to_dir_icon_table-1,x

        ;; Update `IconEntry::state`
        ldy     #IconEntry::state ; mark as dimmed
        lda     (icon_entry),y
        ora     #kIconEntryStateDimmed
        sta     (icon_entry),y
:
        rts
.endproc ; _AllocAndPopulateFileIcon

;;; ============================================================
;;; Inputs: A = `IconType` member, Y = `DeskTopSettings::kViewByXXX` value
;;; Outputs: Populates `icon_flags`, `icon_type`, `icon_height`

.proc _FindIconDetailsForIconType
        ptr := $6

        sty     view_by
        jsr     PushPointers

        ;; For populating `IconEntry::win_flags`
        tay                     ; Y = `IconType`
        lda     icontype_iconentryflags_table,y
        sta     icon_flags

        ;; Adjust type and flags based on view
        view_by := *+1
        lda     #SELF_MODIFIED_BYTE
        ASSERT_EQUALS DeskTopSettings::kViewByIcon, 0
    IF_NOT_ZERO
        ;; List View / Small Icon View
        php
        lda     icon_flags
        ora     #kIconEntryFlagsSmall
        plp
      IF_NS
        ora     #kIconEntryFlagsFixed
      END_IF
        sta     icon_flags

        lda     icontype_to_smicon_table,y
        tay
   END_IF

        ;; For populating `IconEntry::type`
        sty     icon_type

        ;; Icon height will be needed too
        tya
        asl                     ; *= 2
        tay
        ldax    type_icons_table,y
        stax    ptr
        ldy     #IconResource::maprect + MGTK::Rect::y2
        copy16in (ptr),y, icon_height

        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; _FindIconDetailsForIconType

.endproc ; _CreateIconsForWindow

.endproc ; InitWindowEntriesAndIcons

;;; ============================================================
;;; Fetch the entry count for a window; valid after `CreateFileRecordsForWindow`,
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
;;; Inputs: A=DeskTopSettings::kViewBy* for `cached_window_id`

.proc SortRecords
        ptr := $06

list_start_ptr  := $801
num_records     := $803
scratch_space   := $804         ; can be used by comparison funcs

        sta     _CompareFileRecords_sort_by

        lda     cached_window_entry_count
        cmp     #2
        RTS_IF_LT               ; can't sort < 2 records

        sta     num_records

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
        jsr     _CalcPtr
        stax    ptr2

        lda     #0
        sta     inner

        inner := *+1
iloop:  lda     #SELF_MODIFIED_BYTE
        jsr     _CalcPtr
        stax    ptr1

        bit     LCBANK2
        bit     LCBANK2
        jsr     _CompareFileRecords
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
        jsr     _CalcPtr
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

.proc _CalcPtr
        ;; Map from sorting list index to FileRecord index
        tax
        ldy     cached_window_entry_list,x
        dey                     ; 1-based to 0-based
        tya

        ;; Calculate the pointer
        ASSERT_EQUALS .sizeof(FileRecord), 32
        jsr     ATimes32

        clc
        adc     list_start_ptr
        pha
        txa
        adc     list_start_ptr+1
        tax
        pla

        rts
.endproc ; _CalcPtr

;;; --------------------------------------------------

;;; Inputs: $06 and $08 point at FileRecords
;;; Assert: LCBANK2 banked in so FileRecords are visible

.proc _CompareFileRecords
        ptr1 := $06
        ptr2 := $08

        ;; Set by caller
        sort_by := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #DeskTopSettings::kViewByName
    IF_EQ
        ASSERT_EQUALS FileRecord::name, 0
        jmp     CompareStrings
    END_IF

        cmp     #DeskTopSettings::kViewByDate
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
:       copy8   (ptr2),y, scratch::date_a,x ; order descending
        copy8   (ptr1),y, scratch::date_b,x
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

        ;; Compare member-wise
        ecmp16  scratch::parsed_a + ParsedDateTime::year, scratch::parsed_b + ParsedDateTime::year
        bne     done

        lda     scratch::parsed_a + ParsedDateTime::month
        cmp     scratch::parsed_b + ParsedDateTime::month
        bne     done

        lda     scratch::parsed_a + ParsedDateTime::day
        cmp     scratch::parsed_b + ParsedDateTime::day
        bne     done

        lda     scratch::parsed_a + ParsedDateTime::hour
        cmp     scratch::parsed_b + ParsedDateTime::hour
        bne     done

        lda     scratch::parsed_a + ParsedDateTime::minute
        cmp     scratch::parsed_b + ParsedDateTime::minute

done:   rts
    END_IF

        cmp     #DeskTopSettings::kViewBySize
    IF_EQ
        ;; Copy sizes somewhere convenient
        size1 := $804
        size2 := $806
        ldy     #FileRecord::blocks
        copy8   (ptr1),y, size1
        copy8   (ptr2),y, size2
        iny
        copy8   (ptr1),y, size1+1
        copy8   (ptr2),y, size2+1

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

        ;; Assert: DeskTopSettings::kViewByType
        scratch := $804
        ldy     #FileRecord::file_type
        lda     (ptr1),y
        jsr     _ComposeFileTypeStringForSorting
        COPY_STRING str_file_type, scratch
        ldy     #FileRecord::file_type
        lda     (ptr2),y
        jsr     _ComposeFileTypeStringForSorting

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

.endproc ; _CompareFileRecords
_CompareFileRecords_sort_by := _CompareFileRecords::sort_by

.proc _ComposeFileTypeStringForSorting
        jsr     ComposeFileTypeString
        lda     str_file_type+1
        cmp     #'$'
        bne     :+
        lda     #$FF
        sta     str_file_type+1
:       rts
.endproc ; _ComposeFileTypeStringForSorting

.endproc ; SortRecords


;;; ============================================================
;;; A = entry number

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc DrawListViewRow

        ptr := $06

        ASSERT_EQUALS .sizeof(FileRecord), 32
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
        scmp16  pos_col::ycoord, window_grafport::maprect::y2
        bpl     ret

        add16   pos_col::ycoord, #kListViewRowHeight, pos_col::ycoord

        ;; Above top?
        scmp16  pos_col::ycoord, window_grafport::maprect::y1
        bpl     in_range
ret:    rts

        ;; Draw it!
in_range:
        ldax    #kColLock
        jsr     set_pos
        jsr     _PrepareColLock
        param_call DrawString, text_buffer2

        ldax    #kColType
        jsr     set_pos
        jsr     _PrepareColType
        param_call DrawString, text_buffer2

        ldax    #kColSize
        jsr     set_pos
        jsr     _PrepareColSize
        param_call DrawStringRight, text_buffer2

        ldax    #kColDate
        jsr     set_pos
        jsr     ComposeDateString
        param_jump DrawString, text_buffer2

set_pos:
        stax    pos_col::xcoord
        MGTK_CALL MGTK::MoveTo, pos_col
        rts

;;; ============================================================

.proc _PrepareColType
        file_type := list_view_filerecord + FileRecord::file_type

        lda     file_type
        jsr     ComposeFileTypeString

        COPY_BYTES 4, str_file_type, text_buffer2 ; 3 characters + length

        rts
.endproc ; _PrepareColType

.proc _PrepareColLock
        copy8   #0, text_buffer2

        access := list_view_filerecord + FileRecord::access
        lda     access
        and     #ACCESS_DEFAULT
        cmp     #ACCESS_DEFAULT
    IF_NE
        inc     text_buffer2
        copy8   #kGlyphLock, text_buffer2+1
    END_IF

        rts
.endproc ; _PrepareColLock

.proc _PrepareColSize
        file_type := list_view_filerecord + FileRecord::file_type

        lda     file_type
        cmp     #FT_DIRECTORY
    IF_EQ
        copy8   #1, text_buffer2
        copy8   #'-', text_buffer2+1
        rts
    END_IF

        blocks := list_view_filerecord + FileRecord::blocks

        ldax    blocks
        FALL_THROUGH_TO ComposeSizeString
.endproc ; _PrepareColSize

.endproc ; DrawListViewRow

;;; ============================================================
;;; Populate `text_buffer2` with "12,345K"
;;; Trashes: $06

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc ComposeSizeString
        value := $06

        stax    value           ; size in 512-byte blocks

        ldx     #DeskTopSettings::intl_deci_sep
        jsr     ReadSetting
        sta     deci_sep

        copy8   #0, frac_flag
        cmp16   value, #20
    IF_LT
        lsr16   value        ; Convert blocks to K, rounding up
        ror     frac_flag    ; If < 10k and odd, show ".5" suffix"
    ELSE
        lsr16   value       ; Convert blocks to K, rounding up
        bcc     :+          ; NOTE: divide then maybe inc, rather than
        inc16   value       ; always inc then divide, to handle $FFFF
:
    END_IF

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

        ;; Append ".5" if needed
        frac_flag := *+1
        lda     #SELF_MODIFIED_BYTE
        bpl     :+
        deci_sep := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     text_buffer2+1,x
        inx
        lda     #'5'
        sta     text_buffer2+1,x
        inx
:

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
.endproc ; ComposeSizeString

;;; ============================================================

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc ComposeDateString
        copy8   #0, text_buffer2
        copy16  #text_buffer2, $8
        lda     datetime_for_conversion ; any bits set?
        ora     datetime_for_conversion+1
        bne     append_date_strings
        sta     month           ; 0 is "no date" string
        jmp     _AppendMonthString

append_date_strings:
        copy16  #parsed_date, $0A
        ldax    #datetime_for_conversion
        jsr     ParseDatetime

        jsr     _AppendDateString
        param_call _ConcatenateDatePart, str_at
        param_call MakeTimeString, parsed_date
        param_jump _ConcatenateDatePart, str_time

        tmp_date := $0A

.proc _AppendDateString
        ecmp16  datetime_for_conversion, DATELO
    IF_EQ
        param_jump _ConcatenateDatePart, str_today
    END_IF

        copy16  datetime_for_conversion, tmp_date
        jsr     _DecP8Date
        ecmp16  DATELO, tmp_date
    IF_EQ
        param_jump _ConcatenateDatePart, str_tomorrow
    END_IF

        copy16  DATELO, tmp_date
        jsr     _DecP8Date
        ecmp16  datetime_for_conversion, tmp_date
    IF_EQ
        param_jump _ConcatenateDatePart, str_yesterday
    END_IF

        ldx     #DeskTopSettings::intl_date_order
        jsr     ReadSetting
        ASSERT_EQUALS DeskTopSettings::kDateOrderMDY, 0
      IF_EQ
        ;; Month Day, Year
        jsr     _AppendMonthString
        param_call _ConcatenateDatePart, str_space
        jsr     _AppendDayString
        param_call _ConcatenateDatePart, str_comma
      ELSE
        ;; Day Month Year
        jsr     _AppendDayString
        param_call _ConcatenateDatePart, str_space
        jsr     _AppendMonthString
        param_call _ConcatenateDatePart, str_space
      END_IF
        jmp     _AppendYearString
.endproc ; _AppendDateString

.proc _AppendDayString
        lda     day
        ldx     #0
        jsr     IntToString

        param_jump _ConcatenateDatePart, str_from_int
.endproc ; _AppendDayString

.proc _AppendMonthString
        lda     month
        asl     a
        tay
        ldax    month_table,y

        jmp     _ConcatenateDatePart
.endproc ; _AppendMonthString

.proc _AppendYearString
        ldax    year
        jsr     IntToString
        param_jump _ConcatenateDatePart, str_from_int
.endproc ; _AppendYearString

year    := parsed_date + ParsedDateTime::year
month   := parsed_date + ParsedDateTime::month
day     := parsed_date + ParsedDateTime::day
hour    := parsed_date + ParsedDateTime::hour
min     := parsed_date + ParsedDateTime::minute

.proc _ConcatenateDatePart
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
.endproc ; _ConcatenateDatePart


.proc _DecP8Date
        DATELO := tmp_date
        DATEHI := tmp_date+1

;;; ====================================================
;;;  DecP8Date - Takes a 16-bit P8 date and
;;;              calculates the previous day
;;; ----------------------------------------------------
;;;  Written 5/30/2025 by John Brooks as part of the
;;;  open-source AppleII Desktop code-golf challenge
;;;  64-bytes
;;; ====================================================

;;;        7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
;;;       +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
;;; DATE: |    year     |  month  |   day   |
;;;       +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+

        dec     DATELO          ; dec day
        lda     DATELO
        and     #%00011111      ; day
        bne     done

        lsr     DATEHI          ; C = month high bit, year in DATEHI
        lda     DATELO
        ror                     ; A = month * 16
        sbc     #1*16-1         ; dec month * 16 (-1 for c=0)
        bne     calc_days

        dec     DATEHI          ; year - 1
        bpl     year_okay
        lda     #99
        sta     DATEHI          ; wrap to year 99 (not 127)
year_okay:
        lda     #12*16          ; month = december

calc_days:
        tax                     ; X = month * 16
        sta     DATELO
        bpl     pre_august
        eor     #1*16           ; 31 days in odd months 1-7 and in even months 8-12
pre_august:
        and     #1*16
        adc     #$f0            ; C=1 if 31-day month (except Feb)
        lda     #30/2
        rol                     ; A = days in new month, 30 or 31

        cpx     #2*16           ; Is new month == feb?
        bne     not_feb

        lda     DATEHI          ; C=1 from cpx above
        and     #3              ; is year divisible by 4?
        beq     is_leap
        clc                     ; 28 days if not a leap year
is_leap:
        lda     #28/2           ; if C=1, 29 day leap year
        rol

not_feb:
        asl     DATELO          ; 3 month bits in LO, top bit in C
        ora     DATELO          ; merge day in A with 3 month bits
        sta     DATELO          ; save day & month
        rol     DATEHI          ; save year and month high bit
done:
        rts
.endproc ; _DecP8Date

.endproc ; ComposeDateString

;;; ============================================================
;;; Look up an icon address.
;;; Inputs: A = icon number
;;; Output: A,X = IconEntry address

.proc GetIconEntry
        sta     get_icon_entry_params::id
        ITK_CALL IconTK::GetIconEntry, get_icon_entry_params
        ldax    get_icon_entry_params::addr
        rts
.endproc ; GetIconEntry

;;; ============================================================
;;; Look up window.
;;; Inputs: A = window id
;;; Output: A,X = Winfo address

.proc GetWindowPtr
        asl     a
        tax
        lda     win_table,x
        pha
        lda     win_table+1,x
        tax
        pla
        rts
.endproc ; GetWindowPtr

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
;;; Returns window path or a "/" path if 0=desktop is passed

.proc GetWindowOrRootPath
        cmp     #0
        bne     GetWindowPath
        ldax    #str_root_path
        rts

str_root_path:  PASCAL_STRING "/"

.endproc ; GetWindowOrRootPath

;;; ============================================================
;;; Look up window title.
;;; Input: A = window_id
;;; Output: A,X = title address

.proc GetWindowTitle
        asl     a
        tax
        lda     window_title_addr_table,x
        pha
        lda     window_title_addr_table+1,x
        tax
        pla
        rts
.endproc ; GetWindowTitle

;;; ============================================================
;;; Inputs: A = icon id (volume or file)
;;; Outputs: Z=1/A=0/`path_buf3` populated with full path on success
;;;          Z=0/A=`ERR_INVALID_PATHNAME` if too long

.proc GetIconPath
        jsr     PushPointers

        name_ptr := $06
        win_path_ptr := $08

        pha
        jsr     GetIconName
        stax    name_ptr
        pla
        jsr     GetIconWindow
    IF_ZERO
        ;; Volume - no base path
        copy16  #0, win_path_ptr ; base
    ELSE
        ;; File - window path is base path
        jsr     GetWindowPath
        stax    win_path_ptr

        ;; Is there room?
        ldy     #0
        lda     (name_ptr),y
        clc
        adc     (win_path_ptr),y
        cmp     #kMaxPathLength ; not +1 because we'll add '/'
        bcs     too_long
    END_IF

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
        sub16in (entry_ptr),y, map_delta_x, (entry_ptr),y

        ;; icony
        iny
        sub16in (entry_ptr),y, map_delta_y, (entry_ptr),y

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
        add16in (entry_ptr),y, map_delta_x, (entry_ptr),y

        ;; icony
        iny
        add16in (entry_ptr),y, map_delta_y, (entry_ptr),y

        rts
.endproc ; IconPtrScreenToWindow

;;; ============================================================

map_delta_x:    .word   0
map_delta_y:    .word   0

;;; Inits `map_delta_x` and `map_delta_y` for window/screen mapping
;;; for active window.
;;; Inputs: `active_window_id` set
;;; Trashes: $08

.proc PrepActiveWindowScreenMapping
        lda     active_window_id
        FALL_THROUGH_TO PrepWindowScreenMapping
.endproc ; PrepActiveWindowScreenMapping

.proc PrepWindowScreenMapping
        winfo_ptr := $8

        jsr     GetWindowPtr
        stax    winfo_ptr

        ;; Compute delta x
        sec
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + 0
        lda     (winfo_ptr),y
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + 0
        sbc     (winfo_ptr),y
        sta     map_delta_x
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + 1
        lda     (winfo_ptr),y
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + 1
        sbc     (winfo_ptr),y
        sta     map_delta_x+1

        ;; Compute delta y
        sec
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + 2
        lda     (winfo_ptr),y
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + 2
        sbc     (winfo_ptr),y
        sta     map_delta_y
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + 3
        lda     (winfo_ptr),y
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + 3
        sbc     (winfo_ptr),y
        sta     map_delta_y+1

        rts

.endproc ; PrepWindowScreenMapping

;;; ============================================================
;;; Input: A = unmasked unit number
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

dib_buffer := $800
        DEFINE_SP_STATUS_PARAMS status_params, 1, dib_buffer, 3 ; Return Device Information Block (DIB)

;;; Roughly follows:
;;; Technical Note: ProDOS #21: Identifying ProDOS Devices
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/pdos/tn.pdos.21.html

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
        ldy     #IconType::ramdisk
        rts
:
        ;; Special case for VEDRIVE
        jsr     DeviceDriverAddress
        cmp     #<kVEDRIVEDriverAddress
        bne     :+
        cpx     #>kVEDRIVEDriverAddress
        bne     :+
vdrive: ldax    #str_device_type_vdrive
        ldy     #IconType::fileshare
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
        ldy     #IconType::floppy140
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

.if kBuildSupportsLowercase
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
        ora     #AS_BYTE(~CASE_MASK) ; guarded by `kBuildSupportsLowercase`
        sta     dib_buffer+SPDIB::Device_Name,y

next:   dey
        bne     loop
done:
.endscope
.endif

        ;; Check device type
        ;; Technical Note: SmartPort #4: SmartPort Device Types
        ;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/smpt/tn.smpt.4.html
        lda     dib_buffer+SPDIB::Device_Type_Code
        ASSERT_EQUALS SPDeviceType::MemoryExpansionCard, 0
        bne     :+            ; $00 = Memory Expansion Card (RAM Disk)
        ldax    #dib_buffer+SPDIB::ID_String_Length
        ldy     #IconType::ramdisk
        rts
:
        cmp     #SPDeviceType::SCSICDROM
        bne     test_size
        ldax    #dib_buffer+SPDIB::ID_String_Length
        ldy     #IconType::cdrom
        rts

        ;; NOTE: Codes for 3.5" disk ($01) and 5-1/4" disk ($0A) are not trusted
        ;; since emulators do weird things.
        ;; TODO: Is that comment about false positives or false negatives?
        ;; i.e. if $01 or $0A is seen, can that be trusted?

not_sp:
        ;; Not SmartPort - try AppleTalk
        MLI_CALL READ_BLOCK, block_params
        cmp     #ERR_NETWORK_ERROR
    IF_EQ
        ldax    #str_device_type_appletalk
        ldy     #IconType::fileshare
        rts
    END_IF

        ;; RAM-based driver or not SmartPort
generic:
        copy8   #0, dib_buffer+SPDIB::ID_String_Length

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
        ldy     #IconType::profile
        rts

f525:   ldax    #dib_buffer+SPDIB::ID_String_Length
        ldy     #IconType::floppy140
        rts

f35:    ldax    #dib_buffer+SPDIB::ID_String_Length
        ldy     #IconType::floppy800
        rts

        DEFINE_READ_BLOCK_PARAMS block_params, block_buffer, kVolumeDirKeyBlock
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
        copy8   #'/', buffer

        param_call GetFileInfo, path
        bcs     ret
        ldax    file_info_params::aux_type

ret:    rts
.endproc ; GetBlockCountImpl
GetBlockCount   := GetBlockCountImpl::start

;;; ============================================================
;;; Create Volume Icon
;;; Input: A = unmasked unit number, Y = index in DEVLST
;;; Output: 0 on success, ProDOS error code on failure
;;; Assert: `cached_window_id` == 0
;;;
;;; NOTE: Called from Initializer (init) which resides in $800-$1200

        cvi_data_buffer := $800

        DEFINE_ON_LINE_PARAMS on_line_params,, cvi_data_buffer

.proc CreateVolumeIcon
        kMaxIconWidth = 53
        kMaxIconHeight = 15

        sta     unit_number     ; unmasked, for `GetDeviceType`
        sty     devlst_index
        and     #UNIT_NUM_MASK
        sta     on_line_params::unit_num
        MLI_CALL ON_LINE, on_line_params
        bcc     success

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
        bne     :+
        lda     cvi_data_buffer+1 ; if name len is zero, second byte is error
        jmp     error
:
        param_call AdjustOnLineEntryCase, cvi_data_buffer
        jsr     _CompareNames
        bne     error

        icon_ptr := $6
        icon_defn_ptr := $8
        offset := $A

        jsr     PushPointers

        ITK_CALL IconTK::AllocIcon, get_icon_entry_params
        copy16  get_icon_entry_params::addr, icon_ptr
        lda     get_icon_entry_params::id

        ;; Assign icon number
        ldy     devlst_index
        sta     device_to_icon_map,y
        ldx     cached_window_entry_count
        dex
        sta     cached_window_entry_list,x

        ;; Copy name
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
        tya                     ; Y = `IconType`
        ldy     #IconEntry::type
        sta     (icon_ptr),y
        asl                     ; * 2
        tax
        copy16  type_icons_table,x, icon_defn_ptr

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
        cpy     #IconEntry::iconx + .sizeof(MGTK::Point)
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

        jsr     PopPointers
        return  #0

;;; Compare a volume name against existing volume icons for drives.
;;; Inputs: String to compare against is in `cvi_data_buffer`
;;; Output: A=0 if not a duplicate, ERR_DUPLICATE_VOLUME if there is a duplicate.
;;; Assert: `cached_window_entry_count` is one greater than actual count
.proc _CompareNames

        icon_ptr := $06

        jsr     PushPointers
        copy16  #cvi_data_buffer, $08

        ldx     cached_window_entry_count
        dex                     ; skip the newly created icon
        stx     index

        index := *+1
loop:   ldx     #SELF_MODIFIED_BYTE
        lda     cached_window_entry_list-1,x
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
        bne     loop

        ;; All done, clean up and report no duplicates.
        lda     #0

finish: jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; _CompareNames

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

kMaxAnimationStep = 7

.proc AnimateWindowImpl
        ptr := $06
        rect_table := $800

close:  ldy     #$80
        SKIP_NEXT_2_BYTE_INSTRUCTION
open:   ldy     #$00
        sty     close_flag

        sta     icon_param
        txa                     ; A = window_id

        win_rect := rect_table + kMaxAnimationStep * .sizeof(MGTK::Rect)
        icon_rect := rect_table

    IF_NEG
        ;; --------------------------------------------------
        ;; Use desktop rect
        copy16  #0, win_rect + MGTK::Rect::x1
        copy16  #kMenuBarHeight, win_rect + MGTK::Rect::y1
        copy16  #kScreenWidth-1, win_rect + MGTK::Rect::x2
        copy16  #kScreenHeight-1, win_rect + MGTK::Rect::y2
    ELSE
        ;; --------------------------------------------------
        ;; Get window rect - used as last rect

        jsr     ApplyWinfoToWindowGrafport

        ;; Convert viewloc and maprect to bounding rect
        COPY_STRUCT MGTK::Point, window_grafport + MGTK::GrafPort::viewloc, win_rect + MGTK::Rect::topleft
        ldx     #2              ; loop over dimensions
:       sub16   window_grafport::maprect::bottomright,x, window_grafport::maprect::topleft,x, win_rect + MGTK::Rect::bottomright,x
        add16   win_rect + MGTK::Rect::topleft,x, win_rect + MGTK::Rect::bottomright,x, win_rect + MGTK::Rect::bottomright,x
        dex                     ; next dimension
        dex
        bpl     :-
    END_IF

        ;; --------------------------------------------------
        ;; Get icon position - used as first rect

        ITK_CALL IconTK::GetIconBounds, icon_param ; inits `tmp_rect`
        COPY_BLOCK tmp_rect, icon_rect

        ;; --------------------------------------------------
        ;; Compute intermediate rects

        delta := $06

        ;; Iterate over all 4 rectangle edges
        ldy     #0              ; Y = offset into MGTK::Rect
edge_loop:
        sub16   win_rect,y, icon_rect,y, delta

        ;; Iterate over all N animation steps
        ldx     #0              ; X = step
step_loop:
        txa                     ; A = step
        pha

        asr16   delta           ; divide by two (signed)

        ;; Address of target rect
        tya                     ; offset *into* rect
        clc
        adc     table,x         ; plus offset *of* rect
        tax

        ;; Apply delta
        add16   rect_table,y, delta, rect_table,x

        pla                     ; A = step
        tax                     ; X = step
        inx
        cpx     #kMaxAnimationStep-1
        bne     step_loop

        iny
        iny
        cpy     #.sizeof(MGTK::Rect)
        bne     edge_loop

        ;; --------------------------------------------------
        ;; Animate it

        bit     close_flag
        bmi     :+
        jmp     AnimateWindowOpenImpl

:       jmp     AnimateWindowCloseImpl

close_flag:
        .byte   0

table:
        .repeat main::kMaxAnimationStep, i
        .byte   (main::kMaxAnimationStep - 1 - i) * .sizeof(MGTK::Rect)
        .endrepeat

.endproc ; AnimateWindowImpl
AnimateWindowClose      := AnimateWindowImpl::close
AnimateWindowOpen       := AnimateWindowImpl::open

;;; ============================================================

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
;;; Operations performed on selection
;;;
;;; These operate on the entire selection recursively, e.g.
;;; computing size, deleting, copying, etc., and share common
;;; logic.
;;;
;;; Importantly, the procs in this `operations` scope are modal
;;; operations. This allows this code to be paged out when other modal
;;; operations are performed, such as accessories that need a large
;;; buffer.

;;; ============================================================

.enum PromptResult
        ok      = 0
        cancel  = 1
.endenum

;;; ============================================================
;;; For drop onto window/icon, compute target prefix.
;;; Input: `drag_drop_params::target` set
;;; Output: C=0, `path_buf4` populated with target path
;;;         C=1 on error (e.g. path too long); alert is shown
.proc SetPathBuf4FromDragDropResult
        ;; Is drop on a window or an icon?
        ;; hi bit clear = target is an icon
        ;; hi bit set = target is a window; get window number
        lda     drag_drop_params::target
        bpl     target_is_icon

        ;; Drop is on a window
        and     #%01111111      ; get window id
        jsr     GetWindowPath
        jsr     CopyToBuf4
        clc
        rts                     ; success

        ;; Drop is on an icon.
target_is_icon:
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
    IF_NE
        jsr     ShowAlert
        sec                     ; failure
        rts
    END_IF

        COPY_STRING path_buf3, path_buf4
        clc                     ; success
        rts
.endproc ; SetPathBuf4FromDragDropResult

;;; ============================================================

.scope operations

;;; ============================================================
;;; Operations where source/target paths are passed by callers

;;; File > Duplicate - for a single file copy
;;; Caller sets `path_buf3` (source) and `path_buf4` (destination)
.proc DoCopyFile
        copy8   #0, operation_flags ; bit7=0 = copy/delete
        copy8   #0, move_flag
        tsx
        stx     stack_stash

        jsr     PrepTraversalCallbacksForEnumeration
        jsr     OpenCopyProgressDialog
        jsr     SetDstIsAppleShareFlag  ; uses `path_buf4`, may fail
        jsr     EnumerationProcessSelectedFile
        jsr     PrepTraversalCallbacksForCopy
        FALL_THROUGH_TO DoCopyCommon
.endproc ; DoCopyFile

.proc DoCopyCommon
        jsr     CopyProcessNotSelectedFile
        jsr     InvokeOperationCompleteCallback
        FALL_THROUGH_TO FinishOperation
.endproc ; DoCopyCommon

FinishOperation:
        return  #kOperationSucceeded

;;; Shortcuts > Run a Shortcut... w/ "Copy to RAMCard"/"at first use"
;;; Caller sets `path_buf3` (source) and `path_buf4` (destination)
.proc DoCopyToRAM
        copy8   #0, move_flag
        copy8   #%11000000, operation_flags ; bits7&6=1 = copy to RAMCard
        copy8   #0, dst_is_appleshare_flag  ; by definition, not AppleShare
        tsx
        stx     stack_stash

        jsr     PrepTraversalCallbacksForEnumeration
        jsr     OpenCopyProgressDialog
        jsr     EnumerationProcessSelectedFile
        jsr     PrepTraversalCallbacksForDownload
        jmp     DoCopyCommon
.endproc ; DoCopyToRAM

;;; ============================================================
;;; Operations on selection (source)

;;; File > Copy To...
;;; Drag / Drop (to anything but Trash)
;;; Caller sets `path_buf4` (destination)
.proc DoCopyOrMoveSelection
        lda     selected_window_id
        beq     :+              ; dragging volume always copies
        jsr     GetWindowPath
        jsr     CheckMoveOrCopy
:       SKIP_NEXT_2_BYTE_INSTRUCTION

ep_always_copy:
        lda     #0              ; do not convert to `copy8`!

        sta     move_flag

        copy8   #0, operation_flags ; bit7=0 = copy/delete
        copy8   #$00, copy_delete_flags ; bit7=0 = copy
        tsx
        stx     stack_stash

        jsr     PrepTraversalCallbacksForEnumeration
        jsr     OpenCopyProgressDialog
        jsr     SetDstIsAppleShareFlag  ; uses `path_buf4`, may fail
        jmp     OperationOnSelection
.endproc ; DoCopyOrMoveSelection
DoCopySelection := DoCopyOrMoveSelection::ep_always_copy

;;; File > Delete
;;; Drag / Drop to Trash (except volumes)
.proc DoDeleteSelection
        copy8   #0, move_flag
        copy8   #0, operation_flags ; bit7=0 = copy/delete
        copy8   #$80, copy_delete_flags ; bit7=1 = delete
        tsx
        stx     stack_stash

        jsr     PrepTraversalCallbacksForEnumeration
        jsr     OpenDeleteProgressDialog
        FALL_THROUGH_TO OperationOnSelection
.endproc ; DoDeleteSelection

;;; --------------------------------------------------
;;; Start the actual operation

.proc OperationOnSelection

        ;; Selection is iterated twice, once to get a file count, then
        ;; again to do the real work.

iterate_selection:
        ldx     #0
loop:   txa                     ; X = index
        pha                     ; A = index
        lda     selected_icon_list,x
        cmp     trash_icon_num
        beq     next_icon
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
        jne     ShowErrorAlert  ; too long

        ;; During selection iteration, allow Escape to cancel the operation.
        jsr     CheckCancel

        ;; If copy, validate the source vs. target during enumeration phase
        ;; NOTE: Here rather than in `CopyProcessSelectedFile` because we don't
        ;; run this for copy using paths (i.e. Duplicate, Copy to RAMCard)
        lda     do_op_flag
        bne     :+
        bit     copy_delete_flags ; bit7=0 = copy
        bmi     :+
        jsr     CopyPathsFromBufsToSrcAndDst

        ;; Check for copying/moving an item into itself.
        copy16  #src_path_buf, $06
        copy16  #dst_path_buf, $08
        jsr     IsPathPrefixOf
    IF_NE
        param_call ShowAlertParams, AlertButtonOptions::OK, aux::str_alert_move_copy_into_self
        jmp     CloseFilesCancelDialogWithCanceledResult
    END_IF
        jsr     AppendSrcPathLastSegmentToDstPath

        ;; Check for replacing an item with itself or a descendant.
        copy16  #dst_path_buf, $06
        copy16  #src_path_buf, $08
        jsr     IsPathPrefixOf
    IF_NE
        param_call ShowAlertParams, AlertButtonOptions::OK, aux::str_alert_bad_replacement
        jmp     CloseFilesCancelDialogWithCanceledResult
    END_IF
:
        jsr     OpProcessSelectedFile

next_icon:
        pla                     ; A = index
        tax                     ; X = index
        inx
        cpx     selected_icon_count
        bne     loop

        ;; --------------------------------------------------

        ;; Done icons - did we complete the operation?
        lda     do_op_flag
    IF_NE
        jsr     InvokeOperationCompleteCallback
        return  #0
    END_IF

        ;; No, we finished enumerating. Now do the real work.
        jsr     InvokeOperationConfirmCallback
        jsr     InvokeOperationPrepTraversalCallback

        ;; And iterate selection again.
        jmp     iterate_selection

.endproc ; OperationOnSelection

;;; ============================================================

stack_stash:
        .byte   0

        ;; $80 = lock/unlock (obsolete)
        ;; $C0 = "download" (a.k.a. copy to ramcard)
        ;; $00 = copy/delete
operation_flags:
        .byte   0

        ;; bit 7 set = delete, clear = copy
copy_delete_flags:
        .byte   0

        ;; bit 7 set = move, clear = copy
        ;; bit 6 set = same volume move and relink supported
move_flag:
        .byte   0

        ;; bit 7 set = "all" selected in Yes / No / All prompt
all_flag:
        .byte   0

        ;; bit 7 set = destination is an AppleShare (network) drive
dst_is_appleshare_flag:
        .byte   0

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
        ASSERT_EQUALS .sizeof(SubdirectoryHeader) - .sizeof(FileEntry), kBlockPointersSize

        ;; Blocks are 512 bytes, 13 entries of 39 bytes each leaves 5 bytes between.
        ;; Except first block, directory header is 39+4 bytes, leaving 1 byte, but then
        ;; block pointers are the next 4.
        .define kMaxPaddingBytes 5

        PARAM_BLOCK dir_data, $C00
buf_block_pointers      .res    kBlockPointersSize
buf_padding_bytes       .res    kMaxPaddingBytes
file_entry_buf          .tag    FileEntry
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
        .assert (kBufSize .mod BLOCK_SIZE) = 0, error, "integral number of blocks needed for sparse copies and performance"

        DEFINE_CLOSE_PARAMS close_src_params
        DEFINE_CLOSE_PARAMS close_dst_params
        DEFINE_DESTROY_PARAMS destroy_src_params, src_path_buf
        DEFINE_DESTROY_PARAMS destroy_dst_params, dst_path_buf
        DEFINE_OPEN_PARAMS open_src_params, src_path_buf, $0D00
        DEFINE_OPEN_PARAMS open_dst_params, dst_path_buf, $1100
        DEFINE_READ_PARAMS read_src_params, file_data_buffer, kBufSize
        DEFINE_WRITE_PARAMS write_dst_params, file_data_buffer, kBufSize
        DEFINE_CREATE_PARAMS create_params3, dst_path_buf, ACCESS_DEFAULT

        DEFINE_SET_MARK_PARAMS mark_src_params, 0
        DEFINE_SET_MARK_PARAMS mark_dst_params, 0
        DEFINE_ON_LINE_PARAMS on_line_params2,, $800

        block_buffer := file_data_buffer
        DEFINE_READ_BLOCK_PARAMS block_params, block_buffer, SELF_MODIFIED

;;; ============================================================
;;; Callbacks used during operations. There are two sets:
;;;
;;; * Callbacks for the overall operation lifecycle
;;; * Callbacks for selection and file system traversal
;;;
;;; These are separate because the latter are swapped out between the
;;; initial enumeration phase and the actual operation phase.

;;; NOTE: These are referenced by indirect JMP and *must not*
;;; cross page boundaries.
operation_lifecycle_callbacks:
operation_enumeration_callback: .addr   SELF_MODIFIED
operation_complete_callback:    .addr   SELF_MODIFIED
operation_confirm_callback:     .addr   SELF_MODIFIED
operation_prep_callback:        .addr   SELF_MODIFIED
        kOpLifecycleCallbacksSize = * - operation_lifecycle_callbacks

;;; NOTE: These are referenced by indirect JMP and *must not*
;;; cross page boundaries.
operation_traversal_callbacks:
op_process_selected_file_callback:      .addr   SELF_MODIFIED
op_process_dir_entry_callback:          .addr   SELF_MODIFIED
op_finish_directory_callback:           .addr   SELF_MODIFIED
        kOpTraversalCallbacksSize = * - operation_traversal_callbacks

;;; ------------------------------------------------------------
;;; Operation lifecycle callbacks

;;; Called for each file during enumeration; A,X = file count
InvokeOperationEnumerationCallback:
        jmp     (operation_enumeration_callback)

;;; Called on operation completion (success or failure)
InvokeOperationCompleteCallback:
        jmp     (operation_complete_callback)

;;; Called once enumeration is complete, to confirm the operation.
InvokeOperationConfirmCallback:
        jmp     (operation_confirm_callback)

;;; Called once selection enumeration is complete, to prepare for the actual op.
InvokeOperationPrepTraversalCallback:
        jmp     (operation_prep_callback)

;;; ------------------------------------------------------------
;;; Selection and file system traversal callbacks

;;; Called for each file in the selection
OpProcessSelectedFile:
        jmp     (op_process_selected_file_callback)

;;; Called for each file in a directory
OpProcessDirectoryEntry:
        jmp     (op_process_dir_entry_callback)

;;; Called when a directory is complete
OpFinishDirectory:
        jmp     (op_finish_directory_callback)

;;; ------------------------------------------------------------

DoNothing:   rts

;;; 0 for count/size pass, non-zero for actual operation
do_op_flag:
        .byte   0

;;; ============================================================

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
        bcc     :+
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     @retry          ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialogWithFailedResult

:       lda     open_src_dir_params::ref_num
        sta     op_ref_num
        sta     read_block_pointers_params::ref_num

@retry2:MLI_CALL READ, read_block_pointers_params
        bcc     :+
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     @retry2         ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialogWithFailedResult

:       jmp     ReadFileEntry
.endproc ; OpenSrcDir

.proc CloseSrcDir
        lda     op_ref_num
        sta     close_src_dir_params::ref_num
@retry: MLI_CALL CLOSE, close_src_dir_params
        bcc     :+
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     @retry          ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialogWithFailedResult

:       rts
.endproc ; CloseSrcDir

.proc ReadFileEntry
        inc16   entries_read
        lda     op_ref_num
        sta     read_src_dir_entry_params::ref_num
@retry: MLI_CALL READ, read_src_dir_entry_params
        bcc     :+
        cmp     #ERR_END_OF_FILE
        beq     eof
        ldx     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertOption
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     @retry          ; `kAlertResultTryAgain` = 0
        jmp     CloseFilesCancelDialogWithFailedResult

:       inc     entries_read_this_block
        lda     entries_read_this_block
        cmp     num_entries_per_block
        bcc     :+
        copy8   #0, entries_read_this_block
        copy8   op_ref_num, read_padding_bytes_params::ref_num
        MLI_CALL READ, read_padding_bytes_params
:       return  #0

eof:    return  #$FF
.endproc ; ReadFileEntry

;;; ============================================================

;;; Input: Destination path in `path_buf4`
;;; Output: `dst_is_appleshare_flag` is set
.proc SetDstIsAppleShareFlag
        copy8   #0, dst_is_appleshare_flag

        ;; Issue a `GET_FILE_INFO` on destination to set `DEVNUM`
@retry: param_call GetFileInfo, path_buf4
        bcc     :+
        jsr     ShowErrorAlertDst
        jmp     @retry
:
        ;; Try to read a block off device; if AppleShare will fail.
        copy8   DEVNUM, unit_number
        MLI_CALL READ_BLOCK, block_params
        cmp     #ERR_NETWORK_ERROR
    IF_EQ
        copy8   #$80, dst_is_appleshare_flag
    END_IF
ret:    rts

        DEFINE_READ_BLOCK_PARAMS block_params, block_buffer, kVolumeDirKeyBlock
        unit_number := block_params::unit_num
.endproc ; SetDstIsAppleShareFlag

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
        copy8   #0, process_depth
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

        copy8   #0, cancel_descent_flag
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

;;; Verify that file is not forked (etc); if it is an OK/Cancel alert is shown.
;;; If the user selects cancel, the operation is cancelled.
;;;
;;; Input: A=`storage_type`
;;; Output: C=0 if supported type, C=1 if unsupported but user picks OK.
;;; Exception: If user selects Cancel, `CloseFilesCancelDialogWithFailedResult` is invoked.
.proc ValidateStorageType
        cmp     #ST_VOLUME_DIRECTORY
        beq     ok
        cmp     #ST_LINKED_DIRECTORY
        beq     ok
        cmp     #ST_TREE_FILE+1 ; only seedling/sapling/tree supported
        bcc     ok

        ;; Unsupported type - show error, and either abort or return failure
        param_call ShowAlertParams, AlertButtonOptions::OKCancel, aux::str_alert_unsupported_type
        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialogWithFailedResult
        sec
        rts

        ;; Return success
ok:     clc
        rts
.endproc ; ValidateStorageType

;;; ============================================================
;;; "Copy" (including Drag/Drop/Move) files state and logic
;;; ============================================================

;;; `CopyProcessSelectedFile`
;;;  - delegates to `CopyProcessDirectoryEntry`; if op=move, fixes up paths
;;; `CopyProcessDirectoryEntry`
;;;  - copies file/directory
;;; `CopyFinishDirectory`
;;;  - if dir and op=move, deletes dir

;;; Traversal callbacks for copy operation (`operation_traversal_callbacks`)
operation_traversal_callbacks_for_copy:
        .addr   CopyProcessSelectedFile
        .addr   CopyProcessDirectoryEntry
        .addr   CopyFinishDirectory
        ASSERT_TABLE_SIZE operation_traversal_callbacks_for_copy, kOpTraversalCallbacksSize

.proc OpenCopyProgressDialog
        COPY_BYTES kOpLifecycleCallbacksSize, operation_lifecycle_callbacks_for_copy, operation_lifecycle_callbacks
        jmp     OpenProgressDialog

.proc _CopyDialogEnumerationCallback
        stax    file_count
        stax    total_count
        jsr     SetPortForProgressDialog
        bit     move_flag
      IF_NC
        param_call DrawProgressDialogLabel, 0, aux::str_copy_copying
      ELSE
        param_call DrawProgressDialogLabel, 0, aux::str_move_moving
      END_IF
        jmp     DrawFileCountWithSuffix
.endproc ; _CopyDialogEnumerationCallback

;;; Lifecycle callbacks for copy operation (`operation_lifecycle_callbacks`)
operation_lifecycle_callbacks_for_copy:
        .addr   _CopyDialogEnumerationCallback
        .addr   CloseProgressDialog
        .addr   operations::DoNothing
        .addr   PrepTraversalCallbacksForCopy
        ASSERT_TABLE_SIZE operation_lifecycle_callbacks_for_copy, operations::kOpLifecycleCallbacksSize

.endproc ; OpenCopyProgressDialog

;;; ============================================================

.proc PrepTraversalCallbacksForCopy
        COPY_BYTES kOpTraversalCallbacksSize, operation_traversal_callbacks_for_copy, operation_traversal_callbacks

        copy8   #0, operations::all_flag
        copy8   #1, do_op_flag
        rts
.endproc ; PrepTraversalCallbacksForCopy

;;; ============================================================
;;; "Download" - shares heavily with Copy

.proc PrepTraversalCallbacksForDownload
        COPY_BYTES kOpTraversalCallbacksSize, operation_traversal_callbacks_for_copy, operation_traversal_callbacks

        copy8   #$80, operations::all_flag
        copy8   #1, do_op_flag
        rts
.endproc ; PrepTraversalCallbacksForDownload

;;; ============================================================
;;; Handle copying of a file.
;;; Calls into the recursion logic of `ProcessDir` as necessary.

;;; Used for these operations:
;;; * File > Duplicate (via `not_selected` entry point) - operates on passed path, `operation_flags` = $00
;;; * Run a Shortcut (via `not_selected` entry point) - operates on passed path, `operation_flags` = $C0
;;; * File > Copy To - operates on selection, `operation_flags` = $00
;;; * Drag/Drop (to non-Trash) - operates on selection, `operation_flags` = $00

.proc CopyProcessFileImpl
        ;; Normal handling, via `CopyProcessSelectedFile`
selected:
        ;; Caller sets `move_flag` appropriately
        lda     #$80
        SKIP_NEXT_2_BYTE_INSTRUCTION

        ;; Via File > Duplicate or copying to RAMCard
not_selected:
        ;; Caller sets `move_flag` to $00
        lda     #0

        pha                     ; A = use selection?
        jsr     CopyPathsFromBufsToSrcAndDst

        ;; If "Copy to RAMCard", make sure there's enough room.
        bit     operations::operation_flags ; CopyToRAM has N=1/V=1, otherwise N=0/V=0
    IF_VS
        jsr     CheckVolBlocksFree
    END_IF

        pla                     ; A = use selection?
    IF_NS
        ;; File > Copy To...
        ;; Drag/Drop

        ;; Use last segment of source for destination (e.g. for Copy/Move)
        jsr     AppendSrcPathLastSegmentToDstPath
    ELSE
        ;; File > Duplicate
        ;; Shortcuts > Run a Shortcut...

        ;; Used passed filename for destination (e.g. for Duplicate)
        param_call AppendFilenameToDstPath, filename_buf
    END_IF

        ;; Paths are set up - update dialog and populate `src_file_info_params`
        jsr     DecFileCountAndUpdateCopyDialogProgress

@retry: jsr     GetSrcFileInfo
        bcc     :+
        jsr     ShowErrorAlert
        jmp     @retry
:
        lda     src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     dir
        cmp     #ST_LINKED_DIRECTORY
        beq     dir

        ;; --------------------------------------------------
        ;; File

        jsr     ValidateStorageType
        bcs     done

        jsr     TryCreateDst
        bcs     done

        bit     move_flag       ; same volume relink move?
    IF_VS
        jmp     RelinkFile
    END_IF

        jsr     DoFileCopy
        jmp     MaybeFinishFileMove

        ;; --------------------------------------------------
        ;; Directory
dir:
        jsr     TryCreateDst
        bcs     done

        bit     move_flag       ; same volume relink move?
    IF_VS
        jsr     RelinkFile
        jmp     NotifyPathChanged
    END_IF

        ;; Copy directory contents
        jsr     ProcessDir
        jsr     GetAndApplySrcInfoToDst ; copy modified date/time
        jsr     MaybeFinishFileMove

        bit     move_flag
    IF_NS
        jsr     NotifyPathChanged
    END_IF

done:
        rts
.endproc ; CopyProcessFileImpl
        CopyProcessSelectedFile := CopyProcessFileImpl::selected
        CopyProcessNotSelectedFile := CopyProcessFileImpl::not_selected

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

.proc CopyProcessDirectoryEntry
        jsr     AppendFileEntryToDstPath
        jsr     AppendFileEntryToSrcPath
        jsr     DecFileCountAndUpdateCopyDialogProgress

        ;; Called with `src_file_info_params` pre-populated
        lda     src_file_info_params::storage_type
        cmp     #ST_LINKED_DIRECTORY
        beq     dir

        ;; --------------------------------------------------
        ;; File

        jsr     ValidateStorageType
        bcs     done

        jsr     TryCreateDst
        bcs     done

        jsr     DoFileCopy
        jsr     MaybeFinishFileMove
        jmp     done

        ;; --------------------------------------------------
        ;; Directory
dir:
        jsr     TryCreateDst
        bcc     ok_dir          ; leave dst path segment in place for recursion
        copy8   #$FF, cancel_descent_flag

        ;; --------------------------------------------------

done:   jsr     RemoveDstPathSegment
ok_dir: jsr     RemoveSrcPathSegment
        rts
.endproc ; CopyProcessDirectoryEntry

;;; ============================================================
;;; If moving, delete src file/directory.

.proc CopyFinishDirectory
        jsr     GetAndApplySrcInfoToDst ; apply modification date/time
        jsr     RemoveDstPathSegment
        FALL_THROUGH_TO MaybeFinishFileMove
.endproc ; CopyFinishDirectory

.proc MaybeFinishFileMove
        ;; Copy or move?
        bit     move_flag
        bpl     done

        ;; Was a move - delete file
@retry: MLI_CALL DESTROY, destroy_src_params
        bcc     done
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

.proc DecFileCountAndUpdateCopyDialogProgress
        jsr     DecrementOpFileCount
        stax    file_count
        jsr     SetPortForProgressDialog

        param_call CopyToBuf0, src_path_buf
        param_call DrawProgressDialogLabel, 1, aux::str_copy_from
        jsr     DrawTargetFilePath

        param_call CopyToBuf0, dst_path_buf
        param_call DrawProgressDialogLabel, 2, aux::str_copy_to
        jsr     DrawDestFilePath

        jmp     DrawProgressDialogFilesRemaining
.endproc ; DecFileCountAndUpdateCopyDialogProgress

;;; ============================================================
;;; Used before "Copy to RAMCard", to ensure everything will fit.

.proc CheckVolBlocksFree
@retry: jsr     GetDstFileInfo
        bcc     :+
        jsr     ShowErrorAlertDst
        jmp     @retry

:       sub16   dst_file_info_params::aux_type, dst_file_info_params::blocks_used, blocks_free
        cmp16   blocks_free, op_block_count
    IF_LT
        param_call ShowAlertParams, AlertButtonOptions::OK, aux::str_ramcard_full
        jmp     CloseFilesCancelDialogWithFailedResult
    END_IF

        rts

blocks_free:
        .word   0
.endproc ; CheckVolBlocksFree

;;; ============================================================
;;; Used when copying a single file.

;;; Assert: `src_file_info_params` is populated
.proc CheckSpaceAndShowPrompt

        ;; --------------------------------------------------
        ;; Check how much space is available on the target volume
        ;; (including space reclaimed if a file will be overwritten)

        ;; If destination doesn't exist, 0 blocks will be reclaimed.
        copy16  #0, existing_size

        ;; Does destination exist?
@retry2:jsr     GetDstFileInfo
        bcc     got_exist_size
        cmp     #ERR_FILE_NOT_FOUND
        beq     :+
        jsr     ShowErrorAlertDst ; retry if destination not present
        jmp     @retry2

got_exist_size:
        copy16  dst_file_info_params::blocks_used, existing_size
:
        ;; Compute destination volume path
retry:  copy8   dst_path_buf, saved_length

        ;; Strip to vol name - either end of string or next slash
        param_call MakeVolumePath, dst_path_buf

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

        ;; --------------------------------------------------
        ;; Check if there is enough room

        cmp16   blocks_free, src_file_info_params::blocks_used
    IF_GE
        clc
        rts
    END_IF

        ;; Show appropriate message
        ldax    #aux::str_large_copy_prompt
        bit     move_flag
    IF_NS
        ldax    #aux::str_large_move_prompt
    END_IF
        ldy     #AlertButtonOptions::OKCancel
        jsr     ShowAlertParams ; A,X = string, Y = AlertButtonOptions
        jsr     SetCursorWatch  ; preserves A

        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialogWithFailedResult

        sec
        rts

blocks_free:
        .word   0
existing_size:
        .word   0
.endproc ; CheckSpaceAndShowPrompt

;;; ============================================================
;;; Common implementation used by both `CopyProcessSelectedFile`
;;; and `CopyProcessDirectoryEntry`
;;; Output: C=0 on success, C=1 on failure

.proc TryCreateDst
        bit     move_flag       ; same volume relink move?
    IF_VC
        ;; No, verify that there is room.
        jsr     CheckSpaceAndShowPrompt
        RTS_IF_CS
    END_IF

        ;; Copy file_type, aux_type, storage_type
        ldx     #src_file_info_params::storage_type - src_file_info_params::file_type
:       lda     src_file_info_params::file_type,x
        sta     create_params3::file_type,x
        dex
        bpl     :-

        ;; Copy create_time/create_date
        ldx     #.sizeof(DateTime)-1
:       lda     src_file_info_params::create_date,x
        sta     create_params3::create_date,x
        dex
        bpl     :-

        jsr     ReadSrcCaseBits

        ;; If a volume, need to create a subdir instead
        lda     create_params3::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     :+
        lda     #ST_LINKED_DIRECTORY
        sta     create_params3::storage_type
:

        ;; --------------------------------------------------
retry:  jsr     GetDstFileInfo
        bcs     create
        cmp     #ERR_FILE_NOT_FOUND
        beq     create

        ;; File exists
        lda     dst_file_info_params::storage_type
        cmp     #ST_LINKED_DIRECTORY
    IF_EQ
        ;; TODO: In the future, prompt and recursively delete
        param_call ShowAlertParams, AlertButtonOptions::OK, aux::str_no_overwrite_dir
        jsr     SetCursorWatch
        jmp     CloseFilesCancelDialogWithFailedResult
    END_IF
        ;; Prompt to replace
        bit     operations::all_flag
        bmi     yes

        param_call ShowAlertParams, AlertButtonOptions::YesNoAllCancel, aux::str_exists_prompt
        jsr     SetCursorWatch  ; preserves A

        cmp     #kAlertResultYes
        beq     yes
        cmp     #kAlertResultNo
        beq     failure
        cmp     #kAlertResultAll
        bne     cancel
        copy8   #$80, operations::all_flag
yes:
        MLI_CALL DESTROY, destroy_dst_params
        bcs     retry

        ;; --------------------------------------------------
        ;; Create the file
create:
        MLI_CALL CREATE, create_params3
        bcc     success
        jsr     ShowErrorAlertDst
        jmp     retry

success:
        lda     case_bits
        ora     case_bits+1
    IF_NOT_ZERO
        jsr     WriteDstCaseBits
    END_IF

        clc
        rts

failure:
        sec
        rts

cancel: jmp     CloseFilesCancelDialogWithFailedResult
.endproc ; TryCreateDst

;;; ============================================================
;;; Case Bits

.proc ReadSrcCaseBits
        copy16  #0, case_bits   ; best effort

        jsr     GetSrcFileInfo
        bcs     ret

        lda     src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
    IF_EQ
        ;; Volume
        copy8   DEVNUM, unit_number
        MLI_CALL READ_BLOCK, vol_block_params
        bcs     ret
        copy16  block_buffer + VolumeDirectoryHeader::case_bits, case_bits
    ELSE
        ;; File
        ldax    #src_path_buf
        jsr     GetFileEntryBlock ; leaves $06 pointing at `FileEntry`
        bcs     ret
        entry_ptr := $06
        ldy     #FileEntry::case_bits
        copy16in (entry_ptr),y, case_bits
    END_IF

        clc                     ; success
ret:    rts

        DEFINE_READ_BLOCK_PARAMS vol_block_params, block_buffer, kVolumeDirKeyBlock
        unit_number := vol_block_params::unit_num
.endproc ; ReadSrcCaseBits

.proc WriteDstCaseBits
        ldax    #dst_path_buf
        jsr     GetFileEntryBlock
        bcs     ret
        stax    block_params::block_num

        block_ptr := $06
        ldax    #block_buffer
        jsr     GetFileEntryBlockOffset ; Y is already the entry number
        stax    block_ptr

        copy8   DEVNUM, block_params::unit_num
        MLI_CALL READ_BLOCK, block_params
        bcs     ret
        ldy     #FileEntry::case_bits
        copy16in case_bits, (block_ptr),y
        MLI_CALL WRITE_BLOCK, block_params

ret:    rts
.endproc ; WriteDstCaseBits

;;; ============================================================
;;; Relink - swaps source and target, then deletes source.
;;;
;;; Assert: `TryCreateDst` has succeeded

.proc RelinkFileImpl
        src_block := $800
        dst_block := $A00

        DEFINE_READ_BLOCK_PARAMS src_block_params, src_block, 0
        DEFINE_READ_BLOCK_PARAMS dst_block_params, dst_block, 0
src_entry_num:  .byte   0
dst_entry_num:  .byte   0

Start:  lda     DEVNUM
        sta     src_block_params::unit_num
        sta     dst_block_params::unit_num

        ;; --------------------------------------------------
        ;; Locate the source/destination directory blocks

:       ldax    #src_path_buf
        jsr     GetFileEntryBlock
        bcc     :+
        lda     #ERR_PATH_NOT_FOUND
        jsr     ShowErrorAlert
        jmp     :-
:       stax    src_block_params::block_num
        sty     src_entry_num

:       ldax    #dst_path_buf
        jsr     GetFileEntryBlock
        bcc     :+
        lda     #ERR_PATH_NOT_FOUND
        jsr     ShowErrorAlert
        jmp     :-
:       stax    dst_block_params::block_num
        sty     dst_entry_num

        ;; --------------------------------------------------
        ;; Load the directory blocks containing FileEntry records

        jsr     _ReadBlocks

        ;; --------------------------------------------------
        ;; Swap the File Entry fields between the blocks, but
        ;; leave `header_pointer` unchanged

        src_ptr := $06
        dst_ptr := $08

        ;; Point `src_ptr` / `dst_ptr` at `FileEntry` structures
        ldax    #src_block
        ldy     src_entry_num
        jsr     GetFileEntryBlockOffset
        stax    src_ptr

        ldax    #dst_block
        ldy     dst_entry_num
        jsr     GetFileEntryBlockOffset
        stax    dst_ptr

        ;; Swap everything but `header_pointer`
        ldy     #FileEntry::header_pointer-1
:       lda     (src_ptr),y
        pha
        lda     (dst_ptr),y
        sta     (src_ptr),y
        pla
        sta     (dst_ptr),y
        dey
        bpl     :-

        ;; --------------------------------------------------
        ;; Write out the updated blocks

        jsr     _WriteBlocks

        ;; --------------------------------------------------
        ;; If a subdirectory, need to modify parent links

        ldy     #FileEntry::storage_type_name_length
        lda     (src_ptr),y
        and     #STORAGE_TYPE_MASK
        cmp     #ST_LINKED_DIRECTORY<<4
    IF_EQ
        ;; Identify the key blocks of the src/dst file
        ldy     #FileEntry::key_pointer
        copy8   (src_ptr),y, src_block_params::block_num
        copy8   (dst_ptr),y, dst_block_params::block_num
        iny
        copy8   (src_ptr),y, src_block_params::block_num+1
        copy8   (dst_ptr),y, dst_block_params::block_num+1

        ;; Load the key blocks of the source/dest files
        jsr     _ReadBlocks

        ;; Swap the `parent_pointer`/`parent_entry_number` fields between subdir headers
        ldx     #2
:       ldy     src_block + SubdirectoryHeader::parent_pointer,x
        lda     dst_block + SubdirectoryHeader::parent_pointer,x
        sta     src_block + SubdirectoryHeader::parent_pointer,x
        tya
        sta     dst_block + SubdirectoryHeader::parent_pointer,x
        dex
        bpl     :-

        ;; Write out the updated key blocks
        jsr     _WriteBlocks
    END_IF

        ;; --------------------------------------------------
        ;; Delete the file at the source location.

:       MLI_CALL DESTROY, destroy_src_params
        bcc     :+
        jsr     ShowErrorAlert
        jmp     :-
:
        rts

;;; --------------------------------------------------

.proc _ReadBlocks
:
        MLI_CALL READ_BLOCK, src_block_params
        bcc     :+
        jsr     ShowErrorAlert
        jmp     :-
:
        MLI_CALL READ_BLOCK, dst_block_params
        bcc     :+
        jsr     ShowErrorAlert
        jmp     :-
:
        rts
.endproc ; _ReadBlocks

;;; --------------------------------------------------

.proc _WriteBlocks
:
        MLI_CALL WRITE_BLOCK, src_block_params
        bcc     :+
        jsr     ShowErrorAlert
        jmp     :-
:
        MLI_CALL WRITE_BLOCK, dst_block_params
        bcc     :+
        jsr     ShowErrorAlert
        jmp     :-
:
        rts
.endproc ; _WriteBlocks

.endproc ; RelinkFileImpl
        RelinkFile := RelinkFileImpl::Start

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

        jsr     _OpenSrc
        jsr     _OpenDst
    IF_NOT_ZERO
        ;; Destination not available; note it, can prompt later
        copy8   #$FF, src_dst_exclusive_flag
    END_IF

        ;; Read
read:   jsr     _ReadSrc
        bit     src_dst_exclusive_flag
        bpl     write
        jsr     _CloseSrc       ; swap if necessary
:       jsr     _OpenDst
        bne     :-
        MLI_CALL SET_MARK, mark_dst_params

        ;; Write
write:  bit     src_eof_flag
        bmi     eof
        jsr     _WriteDst
        bit     src_dst_exclusive_flag
        bpl     read
        jsr     _CloseDst       ; swap if necessary
        jsr     _OpenSrc

        MLI_CALL SET_MARK, mark_src_params
        bcc     read
        copy8   #$FF, src_eof_flag
        jmp     read

        ;; EOF
eof:    jsr     _CloseDst
        bit     src_dst_exclusive_flag
        bmi     :+
        jsr     _CloseSrc
:       jmp     ApplySrcInfoToDst

.proc _OpenSrc
@retry: MLI_CALL OPEN, open_src_params
        bcc     :+
        jsr     ShowErrorAlert
        jmp     @retry
:
        lda     open_src_params::ref_num
        sta     read_src_params::ref_num
        sta     close_src_params::ref_num
        sta     mark_src_params::ref_num
        return  #0
.endproc ; _OpenSrc

.proc _OpenDst
@retry: MLI_CALL OPEN, open_dst_params
        bcc     done
        cmp     #ERR_VOL_NOT_FOUND
        beq     not_found
        jsr     ShowErrorAlertDst
        jmp     @retry

not_found:
        jsr     ShowErrorAlertDst
        return  #ERR_VOL_NOT_FOUND

done:   lda     open_dst_params::ref_num
        sta     write_dst_params::ref_num
        sta     close_dst_params::ref_num
        sta     mark_dst_params::ref_num
        return  #0
.endproc ; _OpenDst

.proc _ReadSrc
        copy16  #kBufSize, read_src_params::request_count
@retry: MLI_CALL READ, read_src_params
        bcc     :+
        cmp     #ERR_END_OF_FILE
        beq     eof
        jsr     ShowErrorAlert
        jmp     @retry

:       lda     read_src_params::trans_count
        ora     read_src_params::trans_count+1
        bne     :+
eof:    copy8   #$FF, src_eof_flag
:       MLI_CALL GET_MARK, mark_src_params
        rts
.endproc ; _ReadSrc

.proc _WriteDst
        ;; Always start off at start of copy buffer
        copy16  read_src_params::data_buffer, write_dst_params::data_buffer
loop:
        ;; Assume we're going to write everything we read. We may
        ;; later determine we need to write it out block-by-block.
        copy16  read_src_params::trans_count, write_dst_params::request_count

        ;; ProDOS Tech Note #30: AppleShare servers do not support
        ;; sparse files. https://prodos8.com/docs/technote/30
        bit     dst_is_appleshare_flag
        bmi     do_write        ; ...and done!

        ;; Is there less than a full block? If so, just write it.
        lda     read_src_params::trans_count+1
        cmp     #.hibyte(BLOCK_SIZE)
        bcc     do_write        ; ...and done!

        ;; Otherwise we'll go block-by-block, treating all zeros
        ;; specially.
        copy16  #BLOCK_SIZE, write_dst_params::request_count

        ;; First two blocks are never made sparse. The first block is
        ;; never sparsely allocated (P8 TRM B.3.6 - Sparse Files) and
        ;; the transition from seedling to sapling is not handled
        ;; correctly in all versions of ProDOS.
        ;; https://prodos8.com/docs/technote/30
        ;; Assert: mark low byte is $00
        lda     mark_dst_params::position+1
        and     #%11111100
        ora     mark_dst_params::position+2
        beq     not_sparse

        ;; Is this block all zeros? Scan all $200 bytes
        ;; (Note: coded for size, not speed, since we're I/O bound)
        ptr := $06
        copy16  write_dst_params::data_buffer, ptr ; first half
        ldy     #0
        tya
:       ora     (ptr),y
        iny
        bne     :-
        inc     ptr+1           ; second half
:       ora     (ptr),y
        iny
        bne     :-
        tay
        bne     not_sparse

        ;; Block is all zeros, skip over it
        add16_8  mark_dst_params::position+1, #.hibyte(BLOCK_SIZE)
        MLI_CALL SET_EOF, mark_dst_params
        MLI_CALL SET_MARK, mark_dst_params
        jmp     next_block

        ;; Block is not sparse, write it
not_sparse:
        jsr     do_write
        FALL_THROUGH_TO next_block

        ;; Advance to next block
next_block:
        inc     write_dst_params::data_buffer+1
        inc     write_dst_params::data_buffer+1
        ;; Assert: `read_src_params::trans_count` >= `BLOCK_SIZE`
        dec     read_src_params::trans_count+1
        dec     read_src_params::trans_count+1

        ;; Anything left to write?
        lda     read_src_params::trans_count
        ora     read_src_params::trans_count+1
        bne     loop
        rts

do_write:
@retry: MLI_CALL WRITE, write_dst_params
        bcc     :+
        jsr     ShowErrorAlertDst
        jmp     @retry
:       MLI_CALL GET_MARK, mark_dst_params
        rts
.endproc ; _WriteDst

.proc _CloseDst
        MLI_CALL CLOSE, close_dst_params
        rts
.endproc ; _CloseDst

.proc _CloseSrc
        MLI_CALL CLOSE, close_src_params
        rts
.endproc ; _CloseSrc

        ;; Set if src/dst can't be open simultaneously.
src_dst_exclusive_flag:
        .byte   0

src_eof_flag:
        .byte   0

.endproc ; DoFileCopy

;;; ============================================================
;;; "Delete" (Delete/Trash) files dialog state and logic
;;; ============================================================

;;; `DeleteProcessSelectedFile`
;;;  - if dir, recurses; delegates to `DeleteFileCommon`; if dir, destroys dir
;;; `DeleteProcessDirectoryEntry`
;;;  - if not dir, delegates to `DeleteFileCommon`
;;; `DeleteFinishDirectory`
;;;  - destroys dir via `DeleteFileCommon`

;;; Traversal callbacks for delete operation (`operation_traversal_callbacks`)
operation_traversal_callbacks_for_delete:
        .addr   DeleteProcessSelectedFile
        .addr   DeleteProcessDirectoryEntry
        .addr   DeleteFinishDirectory
        ASSERT_TABLE_SIZE operation_traversal_callbacks_for_delete, kOpTraversalCallbacksSize

.proc OpenDeleteProgressDialog
        COPY_BYTES kOpLifecycleCallbacksSize, operation_lifecycle_callbacks_for_delete, operation_lifecycle_callbacks
        jmp     OpenProgressDialog

.proc _DeleteDialogEnumerationCallback
        stax    file_count
        stax    total_count
        jsr     SetPortForProgressDialog
        param_call DrawProgressDialogLabel, 0, aux::str_delete_count
        jmp     DrawFileCountWithSuffix
.endproc ; _DeleteDialogEnumerationCallback

.proc _DeleteDialogConfirmCallback
        ;; `text_input_buf` is used rather than `text_buffer2` due to size
        jsr ComposeFileCountString
        copy8   #0, text_input_buf
        param_call AppendToTextInputBuf, aux::str_delete_confirm_prefix
        param_call AppendToTextInputBuf, str_file_count
        param_call_indirect AppendToTextInputBuf, ptr_str_files_suffix
        param_call AppendToTextInputBuf, aux::str_delete_confirm_suffix

        param_call ShowAlertParams, AlertButtonOptions::OKCancel, text_input_buf
        jsr     SetCursorWatch  ; preserves A

        cmp     #kAlertResultOK
        beq     :+
        jmp     CloseFilesCancelDialogWithCanceledResult
:       rts
.endproc ; _DeleteDialogConfirmCallback

;;; Lifecycle callbacks for delete operation (`operation_lifecycle_callbacks`)
operation_lifecycle_callbacks_for_delete:
        .addr   _DeleteDialogEnumerationCallback
        .addr   CloseProgressDialog
        .addr   _DeleteDialogConfirmCallback
        .addr   PrepTraversalCallbacksForDelete
        ASSERT_TABLE_SIZE operation_lifecycle_callbacks_for_delete, operations::kOpLifecycleCallbacksSize

.endproc ; OpenDeleteProgressDialog

;;; ============================================================

.proc PrepTraversalCallbacksForDelete
        COPY_BYTES kOpTraversalCallbacksSize, operation_traversal_callbacks_for_delete, operation_traversal_callbacks

        copy8   #0, operations::all_flag
        copy8   #1, do_op_flag
        rts
.endproc ; PrepTraversalCallbacksForDelete

;;; ============================================================
;;; Handle deletion of a selected file.
;;; Calls into the recursion logic of `ProcessDir` as necessary.

.proc DeleteProcessSelectedFile
        jsr     CopyPathsFromBufsToSrcAndDst

        ;; Path is set up - update dialog and populate `src_file_info_params`
        jsr     DecFileCountAndUpdateDeleteDialogProgress

@retry: jsr     GetSrcFileInfo
        bcc     :+
        jsr     ShowErrorAlert
        jmp     @retry

        ;; Check if it's a regular file or directory
:       lda     src_file_info_params::storage_type
        ;; ST_VOLUME_DIRECTORY excluded because volumes are ejected.
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        jsr     ValidateStorageType
        bcc     do_destroy
        rts

is_dir:
        ;; Recurse, and process directory
        jsr     ProcessDir
        jsr     UpdateDeleteDialogProgress ; update path display
        ;; ST_VOLUME_DIRECTORY excluded because volumes are ejected.
        FALL_THROUGH_TO do_destroy

do_destroy:
        FALL_THROUGH_TO DeleteFileCommon
.endproc ; DeleteProcessSelectedFile

;;; ============================================================
;;; Common implementation used by both `DeleteProcessSelectedFile`
;;; and `DeleteProcessDirectoryEntry`

.proc DeleteFileCommon
retry:  MLI_CALL DESTROY, destroy_src_params
        bcc     done

        ;; Failed - determine why, maybe try to unlock.
        ;; TODO: If it's a directory, this could be because it's not empty,
        ;; e.g. if it contained files that could not be deleted.
        cmp     #ERR_ACCESS_ERROR
        bne     error
        bit     operations::all_flag
        bmi     unlock

        param_call ShowAlertParams, AlertButtonOptions::YesNoAllCancel, aux::str_delete_locked_file
        jsr     SetCursorWatch  ; preserves A

        cmp     #kAlertResultNo
        beq     done
        cmp     #kAlertResultYes
        beq     unlock
        cmp     #kAlertResultAll
        bne     :+
        copy8   #$80, operations::all_flag
        bne     unlock          ; always
:       jmp     CloseFilesCancelDialogWithFailedResult

unlock: jsr     UnlockSrcFile
        beq     retry

done:   rts

error:  jsr     ShowErrorAlert
        jmp     retry
.endproc ; DeleteFileCommon

.proc UnlockSrcFile
        jsr     GetSrcFileInfo
        lda     src_file_info_params::access
        and     #ACCESS_D       ; destroy enabled bit set?
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
        jsr     DecFileCountAndUpdateDeleteDialogProgress

        ;; Called with `src_file_info_params` pre-populated
        ;; Directories will be processed separately
        lda     src_file_info_params::storage_type
        cmp     #ST_LINKED_DIRECTORY
        beq     next_file
        jsr     ValidateStorageType
        bcs     next_file

        jsr     DeleteFileCommon
next_file:
        jmp     RemoveSrcPathSegment
.endproc ; DeleteProcessDirectoryEntry

;;; ============================================================
;;; Delete directory when exiting via traversal

.proc DeleteFinishDirectory
        jsr     UpdateDeleteDialogProgress
        jmp     DeleteFileCommon
.endproc ; DeleteFinishDirectory

;;; ============================================================

.proc DecFileCountAndUpdateDeleteDialogProgress
        jsr     DecrementOpFileCount
        stax    file_count
        FALL_THROUGH_TO UpdateDeleteDialogProgress
.endproc ; DecFileCountAndUpdateDeleteDialogProgress

.proc UpdateDeleteDialogProgress
        jsr     SetPortForProgressDialog

        param_call CopyToBuf0, src_path_buf
        param_call DrawProgressDialogLabel, 1, aux::str_file_colon
        jsr     DrawTargetFilePath

        jmp     DrawProgressDialogFilesRemaining
.endproc ; UpdateDeleteDialogProgress

;;; ============================================================
;;; Most operations start by doing a traversal to just count
;;; the files.

;;; `EnumerationProcessSelectedFile`
;;;  - if op=copy, validates; if dir, recurses; delegates to:
;;; `EnumerationProcessDirectoryEntry`
;;;  - increments file count; if op=size, sums size
;;; (finishing a directory is a no-op)

;;; Traversal callbacks for size operation (`operation_traversal_callbacks`)
operation_traversal_callbacks_for_enumeration:
        .addr   EnumerationProcessSelectedFile
        .addr   EnumerationProcessDirectoryEntry
        .addr   DoNothing
        ASSERT_TABLE_SIZE operation_traversal_callbacks_for_enumeration, kOpTraversalCallbacksSize

.proc PrepTraversalCallbacksForEnumeration
        COPY_BYTES kOpTraversalCallbacksSize, operation_traversal_callbacks_for_enumeration, operation_traversal_callbacks

        lda     #0
        sta     op_file_count
        sta     op_file_count+1
        sta     op_block_count
        sta     op_block_count+1
        sta     do_op_flag

        rts
.endproc ; PrepTraversalCallbacksForEnumeration

;;; ============================================================
;;; Handle sizing (or just counting) of a selected file.
;;; Calls into the recursion logic of `ProcessDir` as necessary.

.proc EnumerationProcessSelectedFile
        jsr     CopyPathsFromBufsToSrcAndDst
@retry: jsr     GetSrcFileInfo
        bcc     :+
        jsr     ShowErrorAlert
        jmp     @retry

:       copy8   src_file_info_params::storage_type, storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        bne     do_sum_file_size

        ;; For linked directory - tally it now while we have
        ;; `src_file_info_params` populated.
        jsr     EnumerationProcessDirectoryEntry

        bit     move_flag       ; same volume relink move?
        RTS_IF_VS

is_dir:
        jsr     ProcessDir
        storage_type := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #ST_VOLUME_DIRECTORY
        bne     :+              ; if a subdirectory

        ;; If copying a volume dir, it will not be counted as a file
        ;; during enumeration but will be counted during copy, so
        ;; include it to avoid off-by-one.
        inc16   op_file_count
:       rts

do_sum_file_size:
        FALL_THROUGH_TO EnumerationProcessDirectoryEntry
.endproc ; EnumerationProcessSelectedFile

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

.proc EnumerationProcessDirectoryEntry
        ;; If operation is "get size" or "download", add the block count to the sum
        bit     operations::operation_flags
    IF_VS
        ;; Called with `src_file_info_params` pre-populated
        add16   op_block_count, src_file_info_params::blocks_used, op_block_count
    END_IF

        inc16   op_file_count
        ldax    op_file_count
        jmp     operations::InvokeOperationEnumerationCallback
.endproc ; EnumerationProcessDirectoryEntry

;;; Count of files - increases during enumeration, decreases as
;;; files are processed.
op_file_count:
        .word   0

op_block_count:
        .word   0

;;; ============================================================

.proc DecrementOpFileCount
        dec16   op_file_count
        ldax    op_file_count
        rts
.endproc ; DecrementOpFileCount

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
        param_jump CopyToDstPath, path_buf4
.endproc ; CopyPathsFromBufsToSrcAndDst

src_path_slash_index:
        .byte   0

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

.proc DrawTargetFilePath
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, aux::current_target_file_rect
        MGTK_CALL MGTK::MoveTo,  aux::current_target_file_pos
        jmp     DrawDialogPathBuf0
.endproc ; DrawTargetFilePath

.proc DrawDestFilePath
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::PaintRect, aux::current_dest_file_rect
        MGTK_CALL MGTK::MoveTo,  aux::current_dest_file_pos
        jmp     DrawDialogPathBuf0
.endproc ; DrawDestFilePath

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
        param_call DrawString, str_2_spaces

        ;; Update progress bar
        sub16   total_count, file_count, progress_muldiv_params::numerator
        copy16  total_count, progress_muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, progress_muldiv_params
        add16   progress_muldiv_params::result, progress_dialog_bar_meter::x1, progress_dialog_bar_meter::x2
        jsr     SetPenModeCopy
        MGTK_CALL MGTK::SetPattern, progress_pattern
        MGTK_CALL MGTK::PaintRect, progress_dialog_bar_meter

        rts
.endproc ; DrawProgressDialogFilesRemaining

;;; ============================================================
;;; Append name at `file_entry_buf` to path at `src_path_buf`

.proc AppendFileEntryToSrcPath
        param_jump AppendFilenameToSrcPath, file_entry_buf
.endproc ; AppendFileEntryToSrcPath

;;; ============================================================
;;; Append name at `file_entry_buf` to path at `dst_path_buf`

.proc AppendFileEntryToDstPath
        param_jump AppendFilenameToDstPath, file_entry_buf
.endproc ; AppendFileEntryToDstPath

;;; ============================================================

;;; ============================================================
;;; If Escape is pressed, abort the operation.

.proc CheckCancel
        jsr     GetEvent        ; no need to synthesize events

        cmp     #MGTK::EventKind::key_down
        bne     ret

        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     cancel

ret:    rts

cancel: lda     do_op_flag
        beq     CloseFilesCancelDialogWithCanceledResult
        FALL_THROUGH_TO CloseFilesCancelDialogWithFailedResult
.endproc ; CheckCancel

;;; ============================================================
;;; Closes dialog, closes all open files, and restores stack.

.proc CloseFilesCancelDialogImpl
failed:
        lda     #kOperationFailed
        SKIP_NEXT_2_BYTE_INSTRUCTION

canceled:
        lda     #kOperationCanceled

        sta     @result
        jsr     operations::InvokeOperationCompleteCallback

        MLI_CALL CLOSE, close_params

        ldx     operations::stack_stash     ; restore stack, in case recursion was aborted
        txs

        @result := *+1
        lda     #SELF_MODIFIED_BYTE
        rts

        DEFINE_CLOSE_PARAMS close_params
.endproc ; CloseFilesCancelDialogImpl
CloseFilesCancelDialogWithFailedResult := CloseFilesCancelDialogImpl::failed
CloseFilesCancelDialogWithCanceledResult := CloseFilesCancelDialogImpl::canceled

;;; ============================================================
;;; Move or Copy? Compare src/dst paths, same vol = move.
;;; Button down inverts the default action.
;;; Input: A,X = source path
;;; Output: A=bit 7 set if move, clear if copy
;;;           bit 6 set if same vol move and block ops supported

.proc CheckMoveOrCopy
        src_ptr := $08
        dst_buf := path_buf4
        block_buffer := $800

        stax    src_ptr

        jsr     ModifierDown    ; Apple inverts the default
        and     #%10000000
        sta     flag

        ;; Check if same volume
        ldy     #0
        lda     (src_ptr),y
        sta     src_len
        iny                     ; skip leading '/'
        bne     check           ; always

        ;; Chars the same?
loop:   lda     (src_ptr),y
        jsr     ToUpperCase
        sta     @char
        lda     dst_buf,y
        jsr     ToUpperCase
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
ret:    rts

match:  lda     flag
        eor     #$80
        beq     ret             ; copy

        ;; Same vol - but are block operations supported?
@retry: param_call_indirect GetFileInfo, src_ptr
        bcc     :+
        jsr     ShowErrorAlert
        jmp     @retry
:
        lda     DEVNUM
        sta     block_params__unit_num
        MLI_CALL READ_BLOCK, block_params
        lda     #$80            ; bit 7 = move
        bcs     :+
        eor     #$40            ; bit 6 = relink supported
:       rts

        DEFINE_READ_BLOCK_PARAMS block_params, block_buffer, kVolumeDirKeyBlock
        block_params__unit_num := block_params::unit_num
.endproc ; CheckMoveOrCopy

;;; ============================================================

.proc GetAndApplySrcInfoToDst
        jsr     GetSrcFileInfo

        ;; Skip if source is volume; the contents are copied not the
        ;; item itself, so it doesn't make sense.
        lda     src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        RTS_IF_EQ

        FALL_THROUGH_TO ApplySrcInfoToDst
.endproc ; GetAndApplySrcInfoToDst

.proc ApplySrcInfoToDst
        COPY_BYTES 11, src_file_info_params::access, dst_file_info_params::access
        FALL_THROUGH_TO SetDstFileInfo
.endproc ; ApplySrcInfoToDst

;;; ============================================================

.proc SetDstFileInfo
:       copy8   #7, dst_file_info_params::param_count ; SET_FILE_INFO
        MLI_CALL SET_FILE_INFO, dst_file_info_params
        pha
        copy8   #$A, dst_file_info_params::param_count ; GET_FILE_INFO
        pla
        bcc     done
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
        SKIP_NEXT_2_BYTE_INSTRUCTION
flag_clear:
        ldx     #0
        stx     flag

        cmp     #ERR_VOL_NOT_FOUND ; if err is "not found"
        beq     not_found       ; prompt specifically for src/dst disk
        cmp     #ERR_PATH_NOT_FOUND
        beq     not_found

        jsr     ShowAlert
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        bne     close           ; not kAlertResultTryAgain = 0
        jmp     SetCursorWatch  ; undone by `ClosePromptDialog` or `CloseProgressDialog`

not_found:
        ldax    #aux::str_alert_insert_source_disk
        bit     flag
        bpl     :+
        ldax    #aux::str_alert_insert_destination
:       ldy     #AlertButtonOptions::TryAgainCancel
        jsr     ShowAlertParams ; A,X = string, Y = AlertButtonOptions
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        bne     close           ; not kAlertResultTryAgain = 0
        jsr     SetCursorWatch  ; undone by `ClosePromptDialog` or `CloseProgressDialog`

        ;; Poll drives before trying again
        MLI_CALL ON_LINE, on_line_params2
        rts

close:  jmp     CloseFilesCancelDialogWithFailedResult

flag:   .byte   0

.endproc ; ShowErrorAlertImpl
ShowErrorAlert  := ShowErrorAlertImpl::flag_clear
ShowErrorAlertDst       := ShowErrorAlertImpl::flag_set

;;; ============================================================
;;; "Get Info" dialog state and logic
;;; ============================================================

;;; NOTE: Inside `operations` scope due to reuse of recursive
;;; directory enumeration logic (`ProcessDir` etc)

.scope get_info

        DEFINE_READ_BLOCK_PARAMS getinfo_block_params, $800, $A

;;; ============================================================
;;; Get Info
;;; Returns: A has bit7 = 1 if selected items were modified
;;; Assert: At least one icon is selected

.proc DoGetInfo
        lda     selected_icon_count
        RTS_IF_ZERO

        ;; --------------------------------------------------
        ;; Loop over selected icons

        lda     #0
        sta     icon_index
        sta     result_flag

loop:   ldx     icon_index
        cpx     selected_icon_count
        jeq     done

        ldx     icon_index
        lda     selected_icon_list,x
        cmp     trash_icon_num
        jeq     next

        ;; --------------------------------------------------
        ;; Get the file / volume info from ProDOS

        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
    IF_NE
        jsr     ShowAlert
        jmp     next
    END_IF
        param_call CopyToSrcPath, path_buf3

        ;; Try to get file/volume info
common: jsr     GetSrcFileInfo
    IF_CS
        jsr     ShowAlert
        cmp     #kAlertResultTryAgain
        beq     common
        jmp     next
    END_IF

        ;; Special cases for volumes
        lda     selected_window_id
    IF_ZERO
        ;; Volume - determine write-protect state
        copy8   #0, write_protected_flag
        ldx     icon_index
        lda     selected_icon_list,x
        jsr     IconToDeviceIndex
        bne     skip
        lda     DEVLST,x
        and     #UNIT_NUM_MASK
        sta     getinfo_block_params::unit_num
        MLI_CALL READ_BLOCK, getinfo_block_params
        bcs     skip
        MLI_CALL WRITE_BLOCK, getinfo_block_params
        cmp     #ERR_WRITE_PROTECTED
        bne     skip
        copy8   #$80, write_protected_flag
skip:
    END_IF

        ;; --------------------------------------------------
        ;; Open and populate dialog

        jsr     _DialogOpen

        ;; --------------------------------------------------
        ;; Descendant size/file count

        lda     src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     do_dir
        cmp     #ST_LINKED_DIRECTORY
        bne     :+
do_dir:
        jsr     SetCursorWatch
        jsr     _GetDirSize
        jsr     SetCursorPointer
:
        ;; --------------------------------------------------
        ;; Run the dialog, until OK or Cancel

        jsr     _DialogRun
        bne     done

next:   inc     icon_index
        jmp     loop

done:   copy8   #0, path_buf4
        lda     result_flag
        rts

icon_index:
        .byte   0
result_flag:
        .byte   0
vol_used_blocks:
        .word   0
vol_total_blocks:
        .word   0
write_protected_flag:
        .byte   0

;;; ------------------------------------------------------------
;;; Open and populate the dialog

.proc _DialogOpen
        copy8   #0, has_input_field_flag

        lda     #$00            ; OK only
        ldx     icon_index
        inx
        cpx     selected_icon_count
    IF_EQ
        lda     #$80            ; OK/Cancel
    END_IF
        jsr     OpenPromptWindow
        jsr     SetPortForDialogWindow

        param_call DrawDialogTitle, aux::label_get_info

        ;; Draw labels
        param_call DrawDialogLabel, 1 | DDL_LRIGHT, aux::str_info_name
        param_call DrawDialogLabel, 2 | DDL_LRIGHT, aux::str_info_type
        param_call DrawDialogLabel, 4 | DDL_LRIGHT, aux::str_info_create
        param_call DrawDialogLabel, 5 | DDL_LRIGHT, aux::str_info_mod

        lda     selected_window_id
      IF_ZERO
        param_call DrawDialogLabel, 3 | DDL_LRIGHT, aux::str_info_vol_size
        param_call DrawDialogLabel, 6 | DDL_LRIGHT, aux::str_info_protected
      ELSE
        param_call DrawDialogLabel, 3 | DDL_LRIGHT, aux::str_info_file_size
      END_IF

        ;; --------------------------------------------------
        ;; Name

        ldx     icon_index
        lda     selected_icon_list,x
        jsr     GetIconName
        ldy     #1 | DDL_VALUE
        jsr     DrawDialogLabel

        ;; --------------------------------------------------
        ;; Type

        lda     selected_window_id
    IF_ZERO
        ;; Volume
        param_call DrawDialogLabel, 2 | DDL_VALUE, aux::str_volume
    ELSE
        ;; File
        lda     src_file_info_params::file_type
        pha
        jsr     ComposeFileTypeString
        COPY_STRING str_file_type, text_input_buf
        pla                     ; A = file type
        cmp     #FT_DIRECTORY
      IF_NE
        ldax    src_file_info_params::aux_type
        jsr     _AppendAuxType
      END_IF
        param_call DrawDialogLabel, 2 | DDL_VALUE, text_input_buf
    END_IF

        ;; --------------------------------------------------
        ;; Size/Blocks

        ;; Compose "12345K" or "12345K / 67890K" string
        copy8   #0, text_input_buf

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
        stax    vol_used_blocks
        jsr     ComposeSizeString
        param_call AppendToTextInputBuf, text_buffer2
        param_call AppendToTextInputBuf, aux::str_info_size_slash

        ;; Load up the total volume size...
        ldax    src_file_info_params::aux_type
        stax    vol_total_blocks

        ;; Compute "12345K" (either volume size or file size)
append_size:
        jsr     ComposeSizeString
        param_call AppendToTextInputBuf, text_buffer2
        param_call DrawDialogLabel, 3 | DDL_VALUE, text_input_buf

        ;; --------------------------------------------------
        ;; Created date

        COPY_STRUCT DateTime, src_file_info_params::create_date, datetime_for_conversion
        jsr     ComposeDateString
        param_call DrawDialogLabel, 4 | DDL_VALUE, text_buffer2

        ;; --------------------------------------------------
        ;; Modified date

        COPY_STRUCT DateTime, src_file_info_params::mod_date, datetime_for_conversion
        jsr     ComposeDateString
        param_call DrawDialogLabel, 5 | DDL_VALUE, text_buffer2

        ;; --------------------------------------------------
        ;; Locked/Protected

        lda     selected_window_id
    IF_ZERO
        ;; Volume - regular label
        ldax    #aux::str_info_no
        bit     write_protected_flag
      IF_NS
        ldax    #aux::str_info_yes
      END_IF
        ldy     #6 | DDL_VALUE
        jsr     DrawDialogLabel
    ELSE
        ;; File - checkbox control
        ldx     #BTK::kButtonStateNormal
        lda     src_file_info_params::access
        and     #ACCESS_DEFAULT
        cmp     #ACCESS_DEFAULT
      IF_NE
        ldx     #BTK::kButtonStateChecked ; locked
      END_IF
        stx     locked_button::state
        BTK_CALL BTK::CheckboxDraw, locked_button

        ;; Assign hooks; reset in `OpenPromptWindow`
        copy16  #_HandleClick, main::PromptDialogClickHandlerHook
        copy16  #_HandleKey, main::PromptDialogKeyHandlerHook
    END_IF

        rts
.endproc ; _DialogOpen

;;; ------------------------------------------------------------
;;; Recursively count child files / sizes

.proc _GetDirSize
        lda     selected_window_id
    IF_NOT_ZERO
        copy16  #1, file_count
        copy16  src_file_info_params::blocks_used, num_blocks
    ELSE
        copy16  #0, file_count
        copy16  #0, num_blocks
    END_IF

        COPY_BYTES kOpTraversalCallbacksSize, operation_traversal_callbacks_for_getinfo, operation_traversal_callbacks

        copy16  #DoNothing, operations::operation_complete_callback ; handle error
        tsx
        stx     operations::stack_stash
        jsr     ProcessDir
        jmp     _UpdateDirSizeDisplay ; in case 0 files were seen

;;; Traversal callbacks for get info operation (`operation_traversal_callbacks`)
operation_traversal_callbacks_for_getinfo:
        .addr   DoNothing
        .addr   _GetInfoProcessDirEntry
        .addr   DoNothing
        ASSERT_TABLE_SIZE operation_traversal_callbacks_for_getinfo, operations::kOpTraversalCallbacksSize

.proc _GetInfoProcessDirEntry
        add16   num_blocks, src_file_info_params::blocks_used, num_blocks
        inc16   file_count
        FALL_THROUGH_TO _UpdateDirSizeDisplay
.endproc ; _GetInfoProcessDirEntry

.proc _UpdateDirSizeDisplay
        ;; Dir: "<size>K for <count> file(s)"
        ;; Vol: "<size>K for <count> file(s) / <total>K>"
        copy8   #0, text_input_buf

        ;; "<size>K"
        ldax    num_blocks
        ldy     selected_window_id
    IF_ZERO
        ldax    vol_used_blocks
    END_IF
        jsr     ComposeSizeString
        param_call AppendToTextInputBuf, text_buffer2

        ;; " for "
        param_call AppendToTextInputBuf, aux::str_info_size_infix

        ;; "<count> "
        jsr     ComposeFileCountString
        param_call AppendToTextInputBuf, str_file_count

        ;; "file(s)"
        ldax    #aux::str_info_size_suffix
        ldy     file_count+1
        bne     :+
        ldy     file_count
        cpy     #1
        bne     :+
        ldax    #aux::str_info_size_suffix_singular
:       jsr     AppendToTextInputBuf

        lda     selected_window_id
    IF_ZERO
        ;; " / "
        param_call AppendToTextInputBuf, aux::str_info_size_slash
        ;; "<total>K"
        ldax    vol_total_blocks
        jsr     ComposeSizeString
        param_call AppendToTextInputBuf, text_buffer2
    END_IF
        ;; In case it shrank
        param_call AppendToTextInputBuf, str_2_spaces

        jsr     SetPortForDialogWindow
        param_jump DrawDialogLabel, 3 | DDL_VALUE, text_input_buf
.endproc ; _UpdateDirSizeDisplay

num_blocks:
        .word   0
.endproc ; _GetDirSize

;;; ------------------------------------------------------------
;;; Append aux type (in A,X) to `text_input_buf`

.proc _AppendAuxType
        pha
        txa
        pha
        param_call AppendToTextInputBuf, aux::str_auxtype_prefix

        ;; Append type
        pla
        jsr     do_byte
        pla
        FALL_THROUGH_TO do_byte

do_byte:
        pha
        lsr
        lsr
        lsr
        lsr
        jsr     do_nibble
        pla
        FALL_THROUGH_TO do_nibble

do_nibble:
        and     #%00001111
        tax
        lda     hex_digits,x
        inc     text_input_buf
        ldx     text_input_buf
        sta     text_input_buf,x
        rts
.endproc ; _AppendAuxType

;;; ------------------------------------------------------------
;;; Input loop and (hooked) event handlers

.proc _DialogRun
:       jsr     PromptInputLoop
        bmi     :-

        pha
        jsr     ClosePromptDialog
        pla
        rts

.endproc ; _DialogRun

.proc _HandleClick
        MGTK_CALL MGTK::InRect, locked_button::rect
    IF_NOT_ZERO
        jsr     _ToggleFileLock
    END_IF
        return #$FF
.endproc ; _HandleClick

.proc _HandleKey
        cmp     #CHAR_CTRL_L
        beq     _ToggleFileLock
        rts
.endproc ; _HandleKey

.proc _ToggleFileLock
        ;; Modify file
        lda     src_file_info_params::access
        bit     locked_button::state
    IF_NS
        ;; Unlock
        ora     #LOCKED_MASK
    ELSE
        ;; Lock
        and     #AS_BYTE(~LOCKED_MASK)
    END_IF
        sta     src_file_info_params::access
        jsr     SetSrcFileInfo
        bcs     ret
        ;; TODO: Show alert, offer retry on failure?

        ;; Toggle UI
        lda     locked_button::state
        eor     #$80
        sta     locked_button::state
        BTK_CALL BTK::CheckboxUpdate, locked_button

        ;; Update FileRecord
        icon_ptr := $06
        file_record_ptr := $08

        ldx     icon_index
        lda     selected_icon_list,x
        jsr     GetIconEntry
        stax    icon_ptr
        jsr     SetFileRecordPtrFromIconPtr

        bit     LCBANK2
        bit     LCBANK2
        lda     src_file_info_params::access
        ldy     #FileRecord::access
        sta     (file_record_ptr),y
        bit     LCBANK1
        bit     LCBANK1

        copy8   #$80, result_flag

ret:    return  #$FF
.endproc ; _ToggleFileLock

.endproc ; DoGetInfo

.endscope ; get_info

;;; ============================================================

.endscope ; operations

        DoCopyOrMoveSelection := operations::DoCopyOrMoveSelection
        DoCopySelection := operations::DoCopySelection
        DoDeleteSelection := operations::DoDeleteSelection
        DoCopyToRAM := operations::DoCopyToRAM
        DoCopyFile := operations::DoCopyFile
        operations__move_flag := operations::move_flag

        DoGetInfo := operations::get_info::DoGetInfo

;;; ============================================================

.scope rename
        old_name_buf := $1F00
        new_name_buf := stashed_name

        DEFINE_RENAME_PARAMS rename_params, src_path_buf, dst_path_buf

.params rename_dialog_params
a_prev: .addr   old_name_buf
a_path: .addr   SELF_MODIFIED_BYTE
.endparams

;;; Inputs: A,X = address of buffer holding previous name
;;; Assert: Single icon selected, and it's not Trash.
.proc DoRenameImpl

start:
        stax    rename_dialog_params::a_prev

        lda     #0
        sta     result_flags

        ;; Dialog needs base path to ensure new name is valid path
        jsr     GetSelectionWindow
        jsr     GetWindowOrRootPath
        stax    rename_dialog_params::a_path

        ;; Original path
        lda     selected_icon_list
        jsr     GetIconPath     ; `path_buf3` set to path; A=0 on success
    IF_NE
        jsr     ShowAlert
        return  result_flags
    END_IF
        param_call CopyToSrcPath, path_buf3

        ;; Copy original name for display/default
        lda     selected_icon_list
        jsr     GetIconName
        stax    $06
        param_call CopyPtr1ToBuf, old_name_buf

        lda     selected_icon_list
        sta     icon_param
        ITK_CALL IconTK::GetRenameRect, icon_param ; populates `tmp_rect`

        ;; Open the dialog
        jsr     _DialogOpen

        ;; Run the dialog
retry:  jsr     _DialogRun
        beq     success

        ;; Failure
fail:   return  result_flags

        ;; --------------------------------------------------
        ;; Success, new name in X,Y

success:
        new_name_ptr := $08
        stxy    new_name_ptr

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
        param_call AppendFilenameToDstPath, new_name_buf

        ;; Did the name change (ignoring case)?
        copy16  #old_name_buf, $06
        copy16  #new_name_buf, $08
        jsr     CompareStrings
        beq     no_change

        ;; Already exists? (Mostly for volumes, but works for files as well)
        jsr     GetDstFileInfo
        bcs     :+
        lda     #ERR_DUPLICATE_FILENAME
        jsr     ShowAlert
        jmp     retry

        ;; Try to rename
:
no_change:
        ;; Update case bits, in memory or on disk
        jsr     ApplyCaseBits ; applies `stashed_name` to `src_path_buf`

        MLI_CALL RENAME, rename_params
        bcc     finish
        ;; Failed, maybe retry
        jsr     ShowAlert       ; Alert options depend on specific ProDOS error
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        jeq     retry           ; `kAlertResultTryAgain` = 0
        jsr     _DialogClose
        jmp     fail

        ;; --------------------------------------------------
        ;; Completed - tear down the dialog...
finish: jsr     _DialogClose

        lda     selected_icon_list
        sta     icon_param

        ;; Erase the icon, in case new name is shorter
        ITK_CALL IconTK::EraseIcon, icon_param

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

        file_record_ptr := $08
        jsr     SetFileRecordPtrFromIconPtr

        ;; Bank in the `FileRecord` entries
        bit     LCBANK2
        bit     LCBANK2

        ;; Copy the new name in
        ASSERT_EQUALS FileRecord::name, 0, "Name must be at start of FileRecord"
        ldy     new_name_buf
:       lda     new_name_buf,y
        sta     (file_record_ptr),y
        dey
        bpl     :-

        ;; Copy out file metadata needed to determine icon type
        jsr     FileRecordToSrcFileInfo ; uses `FileRecord` ptr in $08

        ;; Done with `FileRecord` entries
        bit     LCBANK1
        bit     LCBANK1

        ;; Determine new icon type
        jsr     GetSelectionViewBy
        ASSERT_EQUALS DeskTopSettings::kViewByIcon, 0
    IF_ZERO
        tmpy := $50

        ;; Compute bounds of icon bitmap
        ITK_CALL IconTK::GetIconBounds, icon_param ; inits `tmp_rect`
        copy16  tmp_rect::y2, tmpy

        ldax    #new_name_buf
        jsr     DetermineIconType ; uses passed name and `src_file_info_params`
        ldy     #IconEntry::type
        sta     (icon_ptr),y
        ;; Assumes flags will not change, regardless of icon.

        ;; Update location so bottom (name) is in the same place
        ITK_CALL IconTK::GetIconBounds, icon_param ; inits `tmp_rect`
        ;; A,X = `tmpy` - `tmp_rect::y2` (delta between old and new bottom)
        lda     tmpy
        sec
        sbc     tmp_rect::y2
        pha
        lda     tmpy+1
        sbc     tmp_rect::y2+1
        tax
        pla

        ;; `icony` += A,X
        ldy     #IconEntry::icony
        clc
        adc     (icon_ptr),y
        sta     (icon_ptr),y
        txa
        iny
        adc     (icon_ptr),y
        sta     (icon_ptr),y
    END_IF

end_filerecord_and_icon_update:

        ;; Draw the (maybe new) icon
        ITK_CALL IconTK::DrawIcon, icon_param

        ;; Is there a window for the folder/volume?
        jsr     FindWindowForSrcPath
    IF_NOT_ZERO
        dst := $06
        ;; Update the window title
        jsr     GetWindowTitle
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
        jsr     NotifyPathChanged

        ;; --------------------------------------------------
        ;; Totally done

        return result_flags

;;; N bit ($80) set if a window title was changed
result_flags:
        .byte   0
.endproc ; DoRenameImpl
DoRename        := DoRenameImpl::start

;;; ============================================================
;;; "Rename" dialog

;;; This uses a minimal dialog window to simulate modeless rename.

.proc _DialogOpen
        ldy     #LETK::kLineEditOptionsNormal
        jsr     GetSelectionViewBy
        cmp     #DeskTopSettings::kViewByIcon
      IF_EQ
        ldy     #LETK::kLineEditOptionsCentered
      END_IF
        sty     rename_line_edit_rec::options

        COPY_STRUCT MGTK::Point, tmp_rect::topleft, winfo_rename_dialog::viewloc

        copy8   #0, cursor_ibeam_flag
        jsr     SetCursorPointer

        MGTK_CALL MGTK::OpenWindow, winfo_rename_dialog

        copy16  rename_dialog_params::a_prev, $08
        param_call CopyPtr2ToBuf, text_input_buf
        LETK_CALL LETK::Init, rename_le_params
        LETK_CALL LETK::Activate, rename_le_params
        rts
.endproc ; _DialogOpen

;;; ============================================================

.proc _DialogRun
loop:   jsr     _InputLoop
        bmi     loop            ; continue?
        bne     _DialogClose    ; canceled!

        lda     text_input_buf  ; treat empty as cancel
        beq     _DialogClose

        ;; Validate path length before committing
        copy16  rename_dialog_params::a_path, $08
        param_call CopyPtr2ToBuf, path_buf0
        lda     path_buf0       ; full path okay?
        clc
        adc     text_input_buf
        cmp     #::kMaxPathLength ; not +1 because we'll add '/'
      IF_GE
        param_call ShowAlertParams, AlertButtonOptions::OK, aux::str_alert_name_too_long
        jmp     loop
      END_IF

        ldxy    #text_input_buf
        return  #0
.endproc ; _DialogRun

;;; ============================================================

.proc _DialogClose
        MGTK_CALL MGTK::CloseWindow, winfo_rename_dialog
        jsr     ClearUpdates     ; following CloseWindow
        jsr     SetCursorPointer ; when closing dialog
        return  #1
.endproc ; _DialogClose

;;; ============================================================

;;; Outputs: N=0/Z=1 if ok, N=0/Z=0 if canceled; N=1 means call again

.proc _InputLoop
        LETK_CALL LETK::Idle, rename_le_params

        jsr     SystemTask
        jsr     GetNextEvent

        cmp     #MGTK::EventKind::button_down
        jeq     _ClickHandler

        cmp     #MGTK::EventKind::key_down
        jeq     _KeyHandler

        cmp     #kEventKindMouseMoved
        bne     _InputLoop

        ;; Check if mouse is over window, change cursor appropriately.
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        bne     out
        lda     findwindow_params::window_id
        cmp     #winfo_rename_dialog::kWindowId
        bne     out

        jsr     SetCursorIBeamWithFlag
        jmp     _InputLoop

out:    jsr     SetCursorPointerWithFlag
        jmp     _InputLoop
.endproc ; _InputLoop

;;; Click handler for rename dialog

.proc _ClickHandler
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
    IF_NE
        return  #PromptResult::ok
    END_IF

        lda     findwindow_params::window_id
        cmp     #winfo_rename_dialog::kWindowId
    IF_NE
        return  #PromptResult::ok
    END_IF

        copy8   winfo_rename_dialog, event_params
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        COPY_STRUCT MGTK::Point, screentowindow_params::window, rename_le_params::coords
        LETK_CALL LETK::Click, rename_le_params

        return  #$FF
.endproc ; _ClickHandler

;;; Key handler for rename dialog

.proc _KeyHandler
        lda     event_params::key
        sta     rename_le_params::key

        ;; Modifiers?
        ldx     event_params::modifiers
        stx     rename_le_params::modifiers
        bne     allow           ; pass through modified keys

        ;; No modifiers
        cmp     #CHAR_RETURN
      IF_EQ
        return  #PromptResult::ok
      END_IF

        cmp     #CHAR_ESCAPE
      IF_EQ
        return  #PromptResult::cancel
      END_IF

        jsr     IsControlChar   ; pass through control characters
        bcc     allow
        ldy     rename_line_edit_rec+LETK::LineEditRecord::caret_pos
        jsr     IsFilenameChar
        bcs     ignore
allow:  LETK_CALL LETK::Key, rename_le_params
ignore:
        return  #$FF
.endproc ; _KeyHandler

.endscope ; rename
        DoRename := rename::DoRename
        old_name_buf := rename::old_name_buf

;;; ============================================================
;;; Input: $06 has `IconEntry` ptr
;;; Output: $08 has `FileRecord` ptr

.proc SetFileRecordPtrFromIconPtr
        icon_ptr := $06
        file_record_ptr := $08

        ldy     #IconEntry::record_num
        lda     (icon_ptr),y
        pha                     ; A = index of icon in window

        ;; Find the window's FileRecord list.
        lda     selected_window_id
        jsr     GetFileRecordListForWindow
        stax    file_record_ptr ; points at head of list (entry count)
        inc16   file_record_ptr ; now points at first FileRecord in list

        ;; Look up the FileRecord within the list.
        pla                     ; A = index
        ASSERT_EQUALS .sizeof(FileRecord), 32
        jsr     ATimes32        ; A,X = index * 32
        addax   file_record_ptr, file_record_ptr
        rts
.endproc ; SetFileRecordPtrFromIconPtr

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
        jsr     IconToDeviceIndex
        RTS_IF_ZC

        lda     DEVLST,x        ; A = unit_number
        ;; NOTE: Not masked with `UNIT_NUM_MASK`, `FindSmartportDispatchAddress` handles it.

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
;;; Following a rename or move of `src_path_buf` to `dst_path_buf`,
;;; update any affected paths.
;;;
;;; * Window paths (so operations within windows still work)
;;; * ProDOS PREFIX (which points at DeskTop's folder)
;;; * Original PREFIX (if copied to RAMCard)
;;; * Restart PREFIX (in the ProDOS Selector code)
;;;
;;; Assert: The path actually changed.

.proc NotifyPathChanged

        ;; --------------------------------------------------
        ;; Update any affected window paths

        ldx     #kMaxDeskTopWindows
wloop:  txa
        pha
        ldy     window_to_dir_icon_table-1,x ; X = 1-based id, so -1 to index
        beq     wnext           ; is `kWindowToDirIconFree`
        jsr     GetWindowPath
        jsr     _MaybeUpdateTargetPath
wnext:  pla
        tax
        dex
        bne     wloop

        ;; --------------------------------------------------
        ;; Update prefixes

        path := tmp_path_buf    ; depends on `src_path_buf`, `dst_path_buf`

        ;; ProDOS Prefix
        MLI_CALL GET_PREFIX, get_set_prefix_params
        param_call _MaybeUpdateTargetPath, path
    IF_NE
        MLI_CALL SET_PREFIX, get_set_prefix_params
    END_IF

        ;; Original Prefix
        jsr     GetCopiedToRAMCardFlag
    IF_MINUS
        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2
        param_call _MaybeUpdateTargetPath, DESKTOP_ORIG_PREFIX
        param_call _MaybeUpdateTargetPath, RAMCARD_PREFIX
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1
    END_IF

        ;; Restart Prefix
        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2
        param_call _MaybeUpdateTargetPath, SELECTOR + QuitRoutine::prefix_buffer_offset
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        rts

        DEFINE_GET_PREFIX_PARAMS get_set_prefix_params, path

;;; ============================================================
;;; Replace `src_path_buf` as the prefix of path at $06 with `dst_path_buf`.
;;; Assert: `src_path_buf` is a prefix of the path at $06!
;;; Inputs: A,X = path to update, `src_path_buf` and `dst_path_buf`,
;;; Outputs: Path updated.
;;; Modifies `tmp_path_buf` and $1F00
;;; NOTE: Sometimes called with LCBANK2; must not assume LCBANK1 present!
;;; Trashes $06

.proc _UpdateTargetPath
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
.endproc ; _UpdateTargetPath

;;; ============================================================
;;; Following a rename or move of `src_path_buf` to `dst_path_buf`,
;;; update the target path if needed.
;;;
;;; Inputs: A,X = pointer to path to update
;;; Outputs: Z=0 if updated, Z=1 if no change
;;; NOTE: Sometimes called with LCBANK2; must not assume LCBANK1 present!
;;; Trashes $06, $08

.proc _MaybeUpdateTargetPath
        ptr := $08

        stax    ptr
        jsr     _MaybeStripSlash

        ;; Is `src_path_buf` a prefix?
        copy16  #src_path_buf, $06
        jsr     IsPathPrefixOf  ; Z=0 if a prefix
        php
    IF_NE
        ;; It's a prefix! Do the replacement
        param_call_indirect _UpdateTargetPath, ptr
    END_IF

        jsr     _MaybeRestoreSlash
        plp                     ; Z=0 if updated
        rts

.proc _MaybeStripSlash
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
.endproc ; _MaybeStripSlash

.proc _MaybeRestoreSlash
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
.endproc ; _MaybeRestoreSlash
        slash_flag := _MaybeRestoreSlash::slash_flag

.endproc ; _MaybeUpdateTargetPath

.endproc ; NotifyPathChanged

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
        jsr     ToUpperCase
        sta     @char
        lda     (ptr2),y
        jsr     ToUpperCase
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
;;; Dynamically load parts of Desktop

;;; Call `LoadDynamicRoutine` or `RestoreDynamicRoutine`
;;; with A set to routine number (0-8); routine is loaded
;;; from DeskTop file to target address. Returns with
;;; minus flag set on failure.

;;; Routines are:
;;;  0 = format/erase disk        - A$ 800,L$1400 call w/ A = 4 = format, A = 5 = erase
;;;  1 = shortcut picker          - A$9000,L$1000
;;;  2 = common file dialog       - A$6000,L$1000
;;;  3 = part of copy file        - A$7000,L$ 800
;;;  4 = shortcut editor          - L$7000,L$ 800
;;;  5 = restore shortcut picker  - A$5000,L$1000 (restore $5000...$5FFF)
;;;  6 = restore file dialog      - A$6000,L$1400 (restore $6000...$73FF)
;;;  7 = restore buffer           - A$5000,L$2800 (restore $5000...$77FF)
;;;
;;; Routines 1-5 need appropriate "restore routines" applied when complete.

        PROC_USED_IN_OVERLAY

.proc LoadDynamicRoutineImpl

kNumOverlays = 8

pos_table:
        .dword  kOverlayFormatEraseOffset
        .dword  kOverlayShortcutPickOffset, kOverlayFileDialogOffset
        .dword  kOverlayFileCopyOffset
        .dword  kOverlayShortcutEditOffset, kOverlayDeskTopRestoreSPOffset
        .dword  kOverlayDeskTopRestoreFDOffset, kOverlayDeskTopRestoreBufferOffset
        ASSERT_RECORD_TABLE_SIZE pos_table, kNumOverlays, 4

len_table:
        .word   kOverlayFormatEraseLength
        .word   kOverlayShortcutPickLength, kOverlayFileDialogLength
        .word   kOverlayFileCopyLength
        .word   kOverlayShortcutEditLength, kOverlayDeskTopRestoreSPLength
        .word   kOverlayDeskTopRestoreFDLength, kOverlayDeskTopRestoreBufferLength
        ASSERT_RECORD_TABLE_SIZE len_table, kNumOverlays, 2

addr_table:
        .word   kOverlayFormatEraseAddress
        .word   kOverlayShortcutPickAddress, kOverlayFileDialogAddress
        .word   kOverlayFileCopyAddress
        .word   kOverlayShortcutEditAddress, kOverlayDeskTopRestoreSPAddress
        .word   kOverlayDeskTopRestoreFDAddress, kOverlayDeskTopRestoreBufferAddress
        ASSERT_ADDRESS_TABLE_SIZE addr_table, kNumOverlays

        DEFINE_OPEN_PARAMS open_params, str_desktop, IO_BUFFER

str_desktop:
        PASCAL_STRING kPathnameDeskTop

        DEFINE_SET_MARK_PARAMS set_mark_params, 0

        DEFINE_READ_PARAMS read_params, 0, 0
        DEFINE_CLOSE_PARAMS close_params

        ;; Called with routine # in A

load:   pha
        copy8   #AlertButtonOptions::OKCancel, button_options
        ASSERT_NOT_EQUALS AlertButtonOptions::OKCancel, 0
        bne     :+              ; always

restore:
        pha
        ;; Need to set low bit in this case to override the default.
        copy8   #AlertButtonOptions::OK|%00000001, button_options

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
        bcc     :+

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

        PROC_USED_IN_OVERLAY

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
;;; Remove segment from path at `src_path_buf`

.proc RemoveSrcPathSegment
        ldax    #src_path_buf
        FALL_THROUGH_TO RemovePathSegment
.endproc ; RemoveSrcPathSegment

;;; ============================================================
;;; Remove segment from path at A,X
;;; Inputs: A,X = path
;;; Output: A = length

        PROC_USED_IN_OVERLAY

.proc RemovePathSegment
        jsr     PushPointers

        ptr := $06
        stax    ptr

        ldy     #0
        lda     (ptr),y         ; length
        beq     finish

        tay
:       lda     (ptr),y
        cmp     #'/'
        beq     found
        dey
        bne     :-
        iny

found:  dey
        tya
        ldy     #0
        sta     (ptr),y

finish: jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc ; RemovePathSegment

;;; ============================================================
;;; Remove segment from path at `dst_path_buf`

.proc RemoveDstPathSegment
        param_jump RemovePathSegment, dst_path_buf
.endproc ; RemoveDstPathSegment

;;; ============================================================
;;; Given a path and a prospective name, update the filesystem with
;;; the desired case bits, considering type and the option
;;; `DeskTopSettings::kOptionsSetCaseBits`.
;;;
;;; Volume - If option set, write case bits to volume header;
;;; otherwise clear case bits in volume header and recase the string
;;; in memory.
;;;
;;; Regular File - If option set, write case bits to directory entry;
;;; otherwise clear case bits in directory entry and recase the string
;;; in memory.
;;;
;;; AppleWorks File - Write case bits to auxtype. If option set, also
;;; write case bits to directory entry. Otherwise, clear case bits in
;;; directory entry. (The string in memory is never recased, which
;;; makes this not a superset of the regular file case.)
;;;
;;; Inputs: `src_path_buf` is file, `stashed_name` is new name
;;; Outputs: `stashed_name` had "resulting" file case

.proc ApplyCaseBits
        param_call CalculateCaseBits, stashed_name
        stax    case_bits

        jsr     GetSrcFileInfo
        bcs     ret
        copy8   DEVNUM, unit_number

        lda     src_file_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     volume

        ;; --------------------------------------------------
        ;; File

        param_call GetFileEntryBlock, src_path_buf
        bcs     ret
        stax    block_number

        block_ptr := $08
        param_call GetFileEntryBlockOffset, block_buffer ; Y is already the entry number
        stax    block_ptr

        MLI_CALL READ_BLOCK, block_params
        bcs     ret

        ;; Is AppleWorks?
        ldy     #FileEntry::file_type
        lda     (block_ptr),y
        cmp     #FT_ADB
        beq     appleworks
        cmp     #FT_AWP
        beq     appleworks
        cmp     #FT_ASP
        beq     appleworks

        ;; --------------------------------------------------
        ;; Non-AppleWorks file

        jsr     get_case_bits_per_option_and_adjust_string
        jmp     write_file_case_bits_and_block

        ;; --------------------------------------------------
        ;; AppleWorks file

appleworks:
        ;; Per Per File Type Notes: File Type $19 (25) All Auxiliary Types (etc)
        ;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/ftyp/ftn.19.xxxx.html
        ;;
        ;; Like as GS/OS case bits, except:
        ;; * Shifted left by one bit; low bit is clear
        ;; * Word is stored byte-swapped
        lda     case_bits
        asl     a
        tax
        lda     case_bits+1
        rol     a

        ldy     #FileEntry::aux_type
        sta     (block_ptr),y
        txa
        iny
        sta     (block_ptr),y

        jsr     get_option
    IF_ZERO
        ;; Option not set, so zero case bits; memory string preserved
        ldax    #0
    ELSE
        ;; Option set, so write case bits as is.
        ldax    case_bits
    END_IF
        FALL_THROUGH_TO write_file_case_bits_and_block

write_file_case_bits_and_block:
        ldy     #FileEntry::case_bits
        sta     (block_ptr),y
        iny
        txa
        sta     (block_ptr),y
        FALL_THROUGH_TO write_block

write_block:
        MLI_CALL WRITE_BLOCK, block_params
ret:    rts

        ;; --------------------------------------------------
        ;; Volume
volume:
        copy16  #kVolumeDirKeyBlock, block_number
        MLI_CALL READ_BLOCK, block_params
        bcs     ret

        jsr     get_case_bits_per_option_and_adjust_string
        stax    block_buffer + VolumeDirectoryHeader::case_bits
        jmp     write_block

        ;; --------------------------------------------------
        ;; Helpers

        ;; Returns Z=0 if option set, Z=1 otherwise
get_option:
        ldx     #DeskTopSettings::options
        jsr     ReadSetting
        and     #DeskTopSettings::kOptionsSetCaseBits
        rts

        ;; Returns A,X=case bits if option set, A,X=0 otherwise
get_case_bits_per_option_and_adjust_string:
        jsr     get_option
    IF_ZERO
        ;; Option not set, so zero case bits, adjust memory string
        param_call UpcaseString, stashed_name
        param_call AdjustFileNameCase, stashed_name
        ldax    #0
    ELSE
        ;; Option set, so write case bits as is, leave string alone
        ldax    case_bits
    END_IF
        rts

        ;; --------------------------------------------------
        block_buffer := $800
        DEFINE_READ_BLOCK_PARAMS block_params, block_buffer, SELF_MODIFIED
        unit_number := block_params::unit_num
        block_number := block_params::block_num
.endproc ; ApplyCaseBits

;;; ============================================================

;;; Per Technical Note: GS/OS #8: Filenames With More Than CAPS and Numerals
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/gsos/tn.gsos.08.html
;;; Input: A,X = name
;;; Output: A,X = case bits
;;; Trashes: $06/$08

        PROC_USED_IN_OVERLAY

.proc CalculateCaseBits
        ptr  := $06
        bits := $08

        stax    ptr

        ldy     #15
:       lda     (ptr),y
        cmp     #'a'            ; set C if lowercase
        ror     bits+1
        ror     bits
        dey
        bne     :-
        sec
        ror     bits+1
        ror     bits

        ldax    bits
        rts
.endproc ; CalculateCaseBits

;;; ============================================================
;;; Message handler for OK/Cancel dialog

;;; Outputs: N=0/Z=1 if ok, N=0/Z=0 if canceled; N=1 means call again

        PROC_USED_IN_OVERLAY

.proc PromptInputLoop
        bit     has_input_field_flag
        bpl     :+
        LETK_CALL LETK::Idle, prompt_le_params
:
        jsr     SystemTask
        jsr     GetNextEvent

        cmp     #MGTK::EventKind::button_down
        jeq     _ClickHandler

        cmp     #MGTK::EventKind::key_down
        jeq     _KeyHandler

        ;; Does the dialog have an input field?
        bit     has_input_field_flag
        bpl     PromptInputLoop

        cmp     #kEventKindMouseMoved
        bne     PromptInputLoop

        ;; Check if mouse is over input field, change cursor appropriately.
        copy8   winfo_prompt_dialog, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, name_input_rect
        ASSERT_EQUALS MGTK::inrect_outside, 0
        beq     out
        jsr     SetCursorIBeamWithFlag ; toggling in prompt dialog
        jmp     PromptInputLoop

out:    jsr     SetCursorPointerWithFlag ; toggling in prompt dialog
        jmp     PromptInputLoop

;;; Click handler for prompt dialog

.proc _ClickHandler
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        beq     :+
        return  #$FF
:
        lda     findwindow_params::window_id
        cmp     #winfo_prompt_dialog::kWindowId
        beq     :+
        return  #$FF
:
        copy8   winfo_prompt_dialog, event_params
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, ok_button::rect
    IF_NOT_ZERO
        BTK_CALL BTK::Track, ok_button
        bmi     :+
        lda     #PromptResult::ok
:       rts
    END_IF

        bit     prompt_button_flags
    IF_NC
        MGTK_CALL MGTK::InRect, cancel_button::rect
      IF_NOT_ZERO
        BTK_CALL BTK::Track, cancel_button
        bmi     :+
        lda     #PromptResult::cancel
:       rts
      END_IF
    END_IF

        bit     has_input_field_flag
    IF_NC
        lda     #$FF            ; in case handler is just RTS
        jmp     (PromptDialogClickHandlerHook)
    END_IF

        ;; Was click inside text box?
        MGTK_CALL MGTK::InRect, name_input_rect
    IF_NOT_ZERO
        COPY_STRUCT MGTK::Point, screentowindow_params::window, prompt_le_params::coords
        LETK_CALL LETK::Click, prompt_le_params
    END_IF

        return  #$FF
.endproc ; _ClickHandler

;;; Key handler for prompt dialog

.proc _KeyHandler
        lda     event_params::key
        sta     prompt_le_params::key

        ldx     event_params::modifiers
        stx     prompt_le_params::modifiers
    IF_NOT_ZERO
        ;; Modifiers

        bit     has_input_field_flag
      IF_NS
        LETK_CALL LETK::Key, prompt_le_params
        jsr     UpdateOKButton
      ELSE
        jsr     KeyHookRelay
        return  #$FF
      END_IF

    ELSE
        ;; No modifiers

        cmp     #CHAR_RETURN
        beq     _HandleKeyOK

        cmp     #CHAR_ESCAPE
      IF_EQ
        bit     prompt_button_flags
        bpl     _HandleKeyCancel
        bmi     _HandleKeyOK    ; always
      END_IF

        bit     has_input_field_flag
      IF_NS
        jsr     IsControlChar   ; pass through control characters
        bcc     allow
        ldy     prompt_line_edit_rec+LETK::LineEditRecord::caret_pos
        jsr     IsFilenameChar
        bcs     ignore
allow:  LETK_CALL LETK::Key, prompt_le_params
        jsr     UpdateOKButton
ignore:
      ELSE
        jsr     KeyHookRelay
        return  #$FF
      END_IF

    END_IF
        return  #$FF

        ;; --------------------------------------------------

KeyHookRelay:
        jmp     (PromptDialogKeyHandlerHook)

.proc _HandleKeyOK
        bit     ok_button::state
        ASSERT_EQUALS BTK::kButtonStateDisabled, $80
        bmi     ret
        BTK_CALL BTK::Flash, ok_button
        lda     #PromptResult::ok
ret:    rts
.endproc ; _HandleKeyOK

.proc _HandleKeyCancel
        BTK_CALL BTK::Flash, cancel_button
        return  #PromptResult::cancel
.endproc ; _HandleKeyCancel

.endproc ; _KeyHandler

.endproc ; PromptInputLoop

;;; NOTE: These are referenced by indirect JMP and *must not*
;;; cross page boundaries.
PAD_IF_NEEDED_TO_AVOID_PAGE_BOUNDARY
PromptDialogClickHandlerHook:
        .addr   SELF_MODIFIED

PAD_IF_NEEDED_TO_AVOID_PAGE_BOUNDARY
PromptDialogKeyHandlerHook:
        .addr   SELF_MODIFIED

;;; ============================================================

;;; Input: A=character
;;; Output: C=0 if control, C=1 if not
.proc IsControlChar
        cmp     #CHAR_DELETE
        bcs     yes

        cmp     #' '
        rts                     ; C=0 (if less) or 1

yes:    clc                     ; C=0
        rts
.endproc ; IsControlChar

;;; ============================================================

;;; Input: A=character, Y=caret_pos
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

.if kBuildSupportsLowercase
        cmp     #'a'
        bcc     ignore
        cmp     #'z'+1
        bcc     allow
.endif
        bcs     ignore          ; always

allow_if_not_first:
        cpy     #0
        beq     ignore

allow:  clc
        rts

ignore: sec
        rts
.endproc ; IsFilenameChar

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

:       jsr     SystemTask
        jsr     GetNextEvent

        cmp     #MGTK::EventKind::button_down
        beq     close

        cmp     #MGTK::EventKind::key_down
        bne     :-

close:  MGTK_CALL MGTK::CloseWindow, winfo_about_dialog
        jmp     ClearUpdates ; following CloseWindow
.endproc ; AboutDialogProc

;;; ============================================================

        PROC_USED_IN_OVERLAY
.proc SetCursorPointerWithFlag
        bit     cursor_ibeam_flag
        bpl     :+
        jsr     SetCursorPointer ; toggle routine
        copy8   #0, cursor_ibeam_flag
:       rts
.endproc ; SetCursorPointerWithFlag

.proc SetCursorIBeamWithFlag
        bit     cursor_ibeam_flag
        bmi     :+
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::ibeam
        copy8   #$80, cursor_ibeam_flag
:       rts
.endproc ; SetCursorIBeamWithFlag

cursor_ibeam_flag:          ; high bit set if I-beam, clear if pointer
        .byte   0

;;; ============================================================

.proc OpenProgressDialog
        MGTK_CALL MGTK::OpenWindow, winfo_progress_dialog
        jsr     SetPortForProgressDialog
        jsr     SetPenModeNotCopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, aux::progress_dialog_frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal
        MGTK_CALL MGTK::FrameRect, progress_dialog_bar_frame
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

        .include "../lib/drawdialogpath.s"

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
        copy8   #kDeskTopFileVersion, desktop_file_data_buf

        copy16  #desktop_file_data_buf+1, data_ptr

        ;; Get first window pointer
        MGTK_CALL MGTK::FrontWindow, window_id
        lda     window_id
        beq     finish
        jsr     GetWindowPtr
        stax    winfo_ptr
        copy8   #0, depth

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
        jsr     _WriteWindowInfo
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
        copy8   str_desktop_file,x, tmp_path_buf,y
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

.proc _WriteWindowInfo
        path_ptr := $0A

        ;; Find name
        ldy     #MGTK::Winfo::window_id
        lda     (winfo_ptr),y
        pha                     ; A = window_id
        jsr     GetWindowPath
        stax    path_ptr

        ;; Copy path in
        ASSERT_EQUALS DeskTopFileItem::window_path, 0
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

.endproc ; _WriteWindowInfo

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
;;; Find the FileEntry for a file within the containing
;;; directory, providing the block number and offset.
;;;
;;; The intended use is to modify properties of files that
;;; GET/SET_FILE_INFO MLI calls can't, such as:
;;; * Modifying the `version`/`min_version` bytes, which are
;;;   used by GS/OS to store filename case bits.
;;; * Modifying the `key_pointer` and other sensitive fields,
;;;   e.g. to allow relinking files.
;;; * Updating a subdirectory's key block's `parent_pointer`
;;;   and `parent_entry_number` fields.
;;;
;;; Input: A,X = path
;;; Output: C=0, A,X=block, Y=entry on success; C=1 on error
;;;         If successful, $06 points at `FileEntry` in block buffer
.proc GetFileEntryBlock

;;; Memory Map
io_buf    := $1000              ; $1000-$13FF
block_buf := $1400              ; $1400-$15FF
path_buf  := $1600
filename  := $1670

entry_num       := $1680        ; (byte) entry number in current block
current_block   := $1681        ; (word) current block number
saw_header_flag := $1683        ; (byte) indicates header entry seen
kEntriesPerBlock = $0D

        ptr := $06

        stax    ptr
        param_call CopyPtr1ToBuf, path_buf

        ;; Clear out pointer to next block; used to identify
        ;; the current block.
        lda     #0
        sta     block_buf+2
        sta     block_buf+3
        sta     saw_header_flag

        ;; --------------------------------------------------
        ;; Split path into dir path and filename

        ldy     path_buf
sloop:  lda     path_buf,y      ; find last '/'
        cmp     #'/'
        beq     :+
        inx                     ; length of filename
        dey
        bne     sloop
:
        dey                     ; length not including '/'
        bne     :+
        sec                     ; was a volume path - failure
        rts

:       tya
        pha                     ; A = new path length
        stx     filename

        iny
        ldx     #0              ; copy out filename
:       inx
        iny
        lda     path_buf,y
        jsr     ToUpperCase
        sta     filename,x
        cpy     path_buf
        bne     :-
        stx     filename

        pla
        sta     path_buf

        ;; --------------------------------------------------
        ;; Open directory, search blocks for filename

        JUMP_TABLE_MLI_CALL OPEN, open_params
        jcs     exit

        lda     open_params_ref_num
        sta     read_params_ref_num
        sta     close_params_ref_num

next_block:
        ;; This is the block we're about to read; save for later.
        copy16  block_buf+2, current_block

        JUMP_TABLE_MLI_CALL READ, read_params
        bcs     close
        copy8   #AS_BYTE(-1), entry_num
        entry_ptr := $06
        copy16  #(block_buf+4 - .sizeof(FileEntry)), entry_ptr

next_entry:
        ;; Advance to next entry
        lda     entry_num
        cmp     #kEntriesPerBlock
        beq     next_block

        inc     entry_num
        add16_8 entry_ptr, #.sizeof(FileEntry)

        ;; Header?
        lda     saw_header_flag
    IF_ZERO
        inc     saw_header_flag
        bne     next_entry      ; always
    END_IF

        ;; Active entry?
        ldy     #FileEntry::storage_type_name_length
        lda     (entry_ptr),y
        beq     next_entry
        tax                     ; X = `storage_type_name_length`

        ;; Is this the first block? Get block num from entry's pointer.
        lda     current_block
        ora     current_block+1
        bne     :+
        ldy     #FileEntry::header_pointer
        copy16in (entry_ptr),y, current_block
:
        ;; See if this is the file we're looking for
        txa                     ; A = `storage_type_name_length`
        and     #NAME_LENGTH_MASK
        cmp     filename
        bne     next_entry
        tay
        ASSERT_EQUALS FileEntry::file_name, 1
nloop:  lda     (entry_ptr),y
        cmp     filename,y
        bne     next_entry
        dey
        bne     nloop

        ;; Match!
        clc

close:  php
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        plp
exit:
        ;; Only valid if C=0
        ldax    current_block
        ldy     entry_num
        rts

        DEFINE_OPEN_PARAMS open_params, path_buf, io_buf
        DEFINE_READ_PARAMS read_params, block_buf, BLOCK_SIZE
        DEFINE_CLOSE_PARAMS close_params
        open_params_ref_num := open_params::ref_num
        read_params_ref_num := read_params::ref_num
        close_params_ref_num := close_params::ref_num

.endproc ; GetFileEntryBlock

;;; ============================================================
;;; After calling `GetFileEntryBlock`, this can be used to translate
;;; the entry number in Y into the address of the corresponding
;;; `FileEntry` with a memory buffer for the block.

;;; Inputs: A,X = directory block, Y = entry number in block
;;; Outputs: A,X = pointer to `FileEntry`

.proc GetFileEntryBlockOffset
        ;; Skip prev/next block pointers
        clc
        adc     #4
        bcc     :+
        inx
:
        ;; Iterate through entries
        cpy     #0
        beq     ret

loop:   clc
        adc     #.sizeof(FileEntry)
        bcc     :+
        inx
:       dey
        bne     loop

ret:    rts

.endproc ; GetFileEntryBlockOffset

;;; ============================================================
;;;
;;; Routines beyond this point are used by overlays
;;;
;;; ============================================================

        PROC_USED_IN_OVERLAY

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
        PROC_USED_IN_OVERLAY
.proc SetCursorWatch
        pha
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        pla
        rts
.endproc ; SetCursorWatch

        PROC_USED_IN_OVERLAY
.proc SetCursorPointer
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts
.endproc ; SetCursorPointer

;;; ============================================================

;;; Inputs: A = new `prompt_button_flags` value

        PROC_USED_IN_OVERLAY

.proc OpenPromptWindow
        sta     prompt_button_flags

        copy8   #0, text_input_buf

        copy8   #BTK::kButtonStateNormal, ok_button::state

        lda     #0
        sta     has_input_field_flag
        sta     has_device_picker_flag
        sta     cursor_ibeam_flag
        jsr     SetCursorPointer

        copy16  #NoOp, PromptDialogClickHandlerHook
        copy16  #NoOp, PromptDialogKeyHandlerHook

        MGTK_CALL MGTK::OpenWindow, winfo_prompt_dialog
        jsr     SetPortForDialogWindow
        jsr     SetPenModeNotCopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, aux::prompt_dialog_frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        BTK_CALL BTK::Draw, ok_button
        bit     prompt_button_flags
    IF_NC
        BTK_CALL BTK::Draw, cancel_button
    END_IF

        rts
.endproc ; OpenPromptWindow

;;; ============================================================

        PROC_USED_IN_OVERLAY
.proc SetPortForDialogWindow
        lda     #winfo_prompt_dialog::kWindowId
        jmp     SafeSetPortFromWindowId
.endproc ; SetPortForDialogWindow

;;; ============================================================

;;; Draw dialog label.
;;; A,X has pointer to DrawText params block
;;; Y has row number (1, 2, ... ) in low nibble, alignment in top nibble

        DDL_LEFT   = $00      ; Left aligned relative to `kDialogLabelDefaultX`
        DDL_VALUE  = $10      ; Left aligned relative to `kDialogValueLeft`
        DDL_CENTER = $20      ; centered within dialog
        DDL_RIGHT  = $30      ; Right aligned
        DDL_LRIGHT = $40      ; Right aligned relative to `kDialogLabelRightX`

        PROC_USED_IN_OVERLAY
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
        ldxy    ptr
        inxy
        stxy    textptr
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
        addax   #aux::kDialogLabelBaseY, dialog_label_pos::ycoord
        MGTK_CALL MGTK::MoveTo, dialog_label_pos
        param_call_indirect DrawString, ptr

        ;; Restore default X position
        copy16  #kDialogLabelDefaultX, dialog_label_pos::xcoord
        rts
.endproc ; DrawDialogLabel

;;; ============================================================

        PROC_USED_IN_OVERLAY
.proc UpdateOKButton
        bit     has_device_picker_flag
    IF_NS
        lda     #0
        jsr     format_erase_overlay__ValidSelection ; preserves A
        bpl     set_state
        lda     #$80
        bne     set_state       ; always
    END_IF

        bit     has_input_field_flag
        bpl     ret

        lda     #BTK::kButtonStateNormal
        ldx     text_input_buf
        bne     :+
        lda     #BTK::kButtonStateChecked
:

set_state:
        cmp     ok_button::state
        beq     ret
        sta     ok_button::state
        BTK_CALL BTK::Hilite, ok_button

ret:    rts
.endproc ; UpdateOKButton

;;; ============================================================
;;; Draw text, pascal string address in A,X
;;; String must be in aux or LC memory.

        PROC_USED_IN_OVERLAY
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

        PROC_USED_IN_OVERLAY
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

        PROC_USED_IN_OVERLAY

.proc NoOp
        rts
.endproc ; NoOp

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
        copy8   str_from_int,x, str_file_count,y
        bne     :-

:       iny
        copy8   #' ', str_file_count,y
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

;;; Input: A,X = string to copy
;;; Trashes: $06
        PROC_USED_IN_OVERLAY
.proc CopyToBuf0
        ptr1 := $06
        stax    ptr1
        param_jump CopyPtr1ToBuf, path_buf0
.endproc ; CopyToBuf0

;;; ============================================================

;;; Input: A,X = string to copy
;;; Trashes: $06
.proc CopyToBuf4
        ptr1 := $06
        stax    ptr1
        param_jump CopyPtr1ToBuf, path_buf4
.endproc ; CopyToBuf4

;;; ============================================================

        PROC_USED_IN_OVERLAY

;;; Wrapper for `MGTK::GetEvent`, returns the `EventKind` in A
.proc GetEvent
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
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
        ;; Exclude menu bar
        ldax    #kMenuBarHeight
        stax    desktop_grafport + MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        stax    desktop_grafport + MGTK::GrafPort::maprect + MGTK::Rect::y1
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

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc FindIndexInFileRecordListEntries
        ldx     window_id_to_filerecord_list_count
        dex
:       cmp     window_id_to_filerecord_list_entries,x
        beq     :+
        dex
        bpl     :-
:       rts
.endproc ; FindIndexInFileRecordListEntries

;;; Input: A = window_id
;;; Output: A,X = address of FileRecord list (first entry is length)
;;; Assert: Window is found in list.
        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc GetFileRecordListForWindow
        jsr     FindIndexInFileRecordListEntries
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
;;; Outputs: A = DeskTopSettings::kViewBy* value for active window, X = window id
;;; If DeskTopSettings::kViewByIcon, Z=1 and N=0; otherwise Z=0 and N=1

;;; Assert: There is an active window
.proc GetActiveWindowViewBy
        ldx     active_window_id
        lda     win_view_by_table-1,x
        rts
.endproc ; GetActiveWindowViewBy

;;; Assert: There is a cached window
        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc GetCachedWindowViewBy
        ldx     cached_window_id
        lda     win_view_by_table-1,x
        rts
.endproc ; GetCachedWindowViewBy

;;; Assert: There is a selection.
;;; NOTE: This variant works even if selection is on desktop
;;; Preserves Y
.proc GetSelectionViewBy
        ldx     selected_window_id
        lda     win_view_by_table-1,x
        rts
.endproc ; GetSelectionViewBy

;;; ============================================================

        PROC_USED_IN_OVERLAY
.proc ToggleMenuHilite
        lda     menu_click_params::menu_id
        beq     :+
        MGTK_CALL MGTK::HiliteMenu, menu_click_params
:       rts
.endproc ; ToggleMenuHilite

;;; ============================================================

;;; Test if either modifier (Open-Apple or Solid-Apple) is down.
;;; Output: A=high bit/N flag set if either is down.

        PROC_USED_IN_OVERLAY
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
        ldx     #DeskTopSettings::system_capabilities
        jsr     ReadSetting
        and     #DeskTopSettings::kSysCapIsIIgs
        bne     iigs

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

        PROC_USED_IN_OVERLAY
.proc ShiftDown
        ldx     #DeskTopSettings::system_capabilities
        jsr     ReadSetting
        and     #DeskTopSettings::kSysCapIsIIgs
        beq     TestShiftMod    ; no, rely on shift key mod

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
        ldx     #DeskTopSettings::system_capabilities
        jsr     ReadSetting

        ;; If a IIe, maybe use shift key mod
        ;; Not IIc/Laser 128 as BUTN2 set when mouse button clicked
        and     #DeskTopSettings::kSysCapIsIIc | DeskTopSettings::kSysCapIsLaser128
        bne     :+

        ;; It's a IIe, compare shift key state
        lda     pb2_initial_state ; if shift key mod installed, %1xxxxxxx
        eor     BUTN2             ; ... and if shift is down, %0xxxxxxx

:       rts
.endproc ; TestShiftMod

;;; ============================================================
;;; Window Entry Tables
;;; ============================================================


        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
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

.proc ClearActiveWindowEntryCount
        jsr     LoadActiveWindowEntryTable
        FALL_THROUGH_TO ClearAndStoreCachedWindowEntryTable
.endproc ; ClearActiveWindowEntryCount

.proc ClearAndStoreCachedWindowEntryTable
        copy8   #0, cached_window_entry_count
        FALL_THROUGH_TO StoreWindowEntryTable
.endproc ; ClearAndStoreCachedWindowEntryTable

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
window_entry_table:             .res    ::kMaxIconCount+1, 0
;;; NOTE: +1 in above is to address an off-by-one case in the shift-up
;;; logic with 127 icons. A simpler fix may be possible, see commit
;;; 41ebde49 for another attempt, but that introduces other issues.

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc LoadActiveWindowEntryTable
        lda     active_window_id
        jmp     LoadWindowEntryTable
.endproc ; LoadActiveWindowEntryTable

.proc LoadDesktopEntryTable
        lda     #0
        jmp     LoadWindowEntryTable
.endproc ; LoadDesktopEntryTable

;;; ============================================================

;;; A,X = A,X * Y
.proc Multiply_16_8_16
PARAM_BLOCK muldiv_params, $10
number          .word           ; (in)
numerator       .word           ; (in)
denominator     .word           ; (in)
result          .word           ; (out)
remainder       .word           ; (out)
END_PARAM_BLOCK

        stax    muldiv_params::number
        sty     muldiv_params::numerator
        copy8   #0, muldiv_params::numerator+1
        copy16  #1, muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, muldiv_params
        ldax    muldiv_params::result
        rts
.endproc ; Multiply_16_8_16

;;; ============================================================
;;; Library Routines
;;; ============================================================

        .assert * >= OVERLAY_BUFFER + kOverlayBufferSize, error, "Routines used by overlays in overlay zone"

        RC_AUXMEM = 1
        RC_LCBANK = 1
        .include "../lib/ramcard.s"

        ADJUSTCASE_BLOCK_BUFFER := IO_BUFFER
        .include "../lib/adjustfilecase.s"

        .include "../lib/smartport.s"

        .include "../lib/menuclock.s"
        .include "../lib/inttostring.s"
        .include "../lib/filetypestring.s"
        .include "../lib/datetime.s"
        .include "../lib/is_diskii.s"
        .include "../lib/doubleclick.s"
        .include "../lib/reconnect_ram.s"
        .include "../lib/readwrite_settings.s"
        .include "../lib/get_next_event.s"
        .include "../lib/monocolor.s"
        .include "../lib/speed.s"
        .include "../lib/bell.s"
        .include "../lib/uppercase.s"

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

icontype_table:
        ;; Types where suffix shouldn't override other metadata
        DEFINE_ICTRECORD $FF, FT_DIRECTORY, ICT_FLAGS_AUX, $8000, 0, IconType::system_folder ; $0F
        DEFINE_ICTRECORD $FF, FT_DIRECTORY, ICT_FLAGS_NONE, 0, 0, IconType::folder        ; $0F

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
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_btc_suffix, 0, IconType::audio ; Binary Time Constant Audio
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_zc_suffix, 0, IconType::audio ; Zero-Crossing Audio
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_pt3_suffix, 0, IconType::tracker ; Vortex Tracker PT3

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

        DEFINE_ICTRECORD $FF, FT_ADB,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_db ; $19
        DEFINE_ICTRECORD $FF, FT_AWP,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_wp ; $1A
        DEFINE_ICTRECORD $FF, FT_ASP,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_sp ; $1B

        DEFINE_ICTRECORD $FF, FT_CMD,       ICT_FLAGS_NONE, 0, 0, IconType::command       ; $F0
        DEFINE_ICTRECORD $FF, FT_INT,       ICT_FLAGS_NONE, 0, 0, IconType::intbasic      ; $FA
        DEFINE_ICTRECORD $FF, FT_IVR,       ICT_FLAGS_NONE, 0, 0, IconType::variables     ; $FB
        DEFINE_ICTRECORD $FF, FT_BASIC,     ICT_FLAGS_NONE, 0, 0, IconType::basic         ; $FC
        DEFINE_ICTRECORD $FF, FT_VAR,       ICT_FLAGS_NONE, 0, 0, IconType::variables     ; $FD
        DEFINE_ICTRECORD $FF, FT_REL,       ICT_FLAGS_NONE, 0, 0, IconType::relocatable   ; $FE
        DEFINE_ICTRECORD $FF, FT_SYSTEM,    ICT_FLAGS_SUFFIX, str_sys_suffix, 0, IconType::application ; $FF
        DEFINE_ICTRECORD $FF, FT_SYSTEM,    ICT_FLAGS_NONE, 0, 0, IconType::system        ; $FF

        DEFINE_ICTRECORD $FF, FT_ANIMATION, ICT_FLAGS_NONE, 0, 0, IconType::animation     ; $5B ANM
        DEFINE_ICTRECORD $FF, FT_SOUND,     ICT_FLAGS_NONE, 0, 0, IconType::audio         ; $D8 SND
        DEFINE_ICTRECORD $FF, FT_MUSIC,     ICT_FLAGS_NONE, 0, 0, IconType::music         ; $D5 MUS
        DEFINE_ICTRECORD $FF, FT_ARCHIVE,   ICT_FLAGS_AUX, $8002, 0, IconType::archive    ; NuFX
        DEFINE_ICTRECORD $FF, FT_LINK,      ICT_FLAGS_AUX, kLinkFileAuxType, 0, IconType::link ; $E1 LNK
        DEFINE_ICTRECORD $FF, FT_SPEECH,    ICT_FLAGS_AUX, $0001, 0, IconType::speech     ; $D9 Speech

        ;; IIgs-Specific Files (ranges)
        DEFINE_ICTRECORD $F0, $50,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs General  $5x
        DEFINE_ICTRECORD $F0, $A0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs BASIC    $Ax
        DEFINE_ICTRECORD $FF, FT_S16, ICT_FLAGS_NONE, 0, 0, IconType::application ; IIgs System   $B3
        DEFINE_ICTRECORD $F0, $B0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs System   $Bx
        DEFINE_ICTRECORD $FF, FT_PNT, ICT_FLAGS_AUX, $0001, 0, IconType::graphics ; IIgs Pkd SHR  $C0
        DEFINE_ICTRECORD $FF, FT_PIC, ICT_FLAGS_AUX, $0000, 0, IconType::graphics ; IIgs SHR      $C1
        DEFINE_ICTRECORD $F0, $C0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs Graphics $Cx

        ;; Desk Accessories/Applets $F1/$0642 and $F1/$8642
        DEFINE_ICTRECORD $FF, kDAFileType,  ICT_FLAGS_AUX, kDAFileAuxType, 0, IconType::desk_accessory
        DEFINE_ICTRECORD $FF, kDAFileType,  ICT_FLAGS_AUX, kDAFileAuxType|$8000, 0, IconType::desk_accessory
        .byte   kICTSentinel

;;; Suffixes (must be uppercase)
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

str_pt3_suffix:                 ; Vortex Tracker PT3
        PASCAL_STRING ".PT3"

;;; ============================================================
;;; DeskTop icon placement

;;;  +-------------------------+
;;;  |                     1   |
;;;  |                     2   |
;;;  |                     3   |
;;;  |                     4   |
;;;  |     14  13  12  11  5   |
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

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
;;; FileRecord for list view
list_view_filerecord:
        .tag FileRecord

;;; Used elsewhere for converting date to string
datetime_for_conversion := list_view_filerecord + FileRecord::modification_date

;;; ============================================================

case_bits:      .word   0

;;; Holds a single filename
clipboard:
        .res    16, 0

path_buf4:
        .res    ::kPathBufferSize, 0
path_buf3:
        .res    ::kPathBufferSize, 0
filename_buf:
        .res    16, 0

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

;;; High bit set if menu dispatch via mouse with option, clear otherwise.
menu_modified_click_flag:
        .byte   0

;;; ============================================================
;;; Map IconType to other icon/details

;;; Table mapping IconType to kIconEntryFlags*
icontype_iconentryflags_table := * - IconType::VOL_COUNT
        ;; Volume types skipped via above math.
        .byte   0                    ; generic
        .byte   0                    ; text
        .byte   0                    ; binary
        .byte   0                    ; graphics
        .byte   0                    ; animation
        .byte   0                    ; music
        .byte   0                    ; tracker
        .byte   0                    ; audio
        .byte   0                    ; speech
        .byte   0                    ; font
        .byte   0                    ; relocatable
        .byte   0                    ; command
        .byte   kIconEntryFlagsDropTarget ; folder
        .byte   kIconEntryFlagsDropTarget ; system_folder
        .byte   0                    ; iigs
        .byte   0                    ; appleworks_db
        .byte   0                    ; appleworks_wp
        .byte   0                    ; appleworks_sp
        .byte   0                    ; archive
        .byte   0                    ; encoded
        .byte   0                    ; link
        .byte   0                    ; desk_accessory
        .byte   0                    ; basic
        .byte   0                    ; intbasic
        .byte   0                    ; variables
        .byte   0                    ; system
        .byte   0                    ; application
        ;; Small Icon types skipped via math below
        ASSERT_TABLE_SIZE icontype_iconentryflags_table, IconType::COUNT - IconType::SMALL_COUNT

icontype_to_smicon_table := * - IconType::VOL_COUNT
        ;; Volume types skipped via above math
        .byte      IconType::small_generic ; generic
        .byte      IconType::small_generic ; text
        .byte      IconType::small_generic ; binary
        .byte      IconType::small_generic ; graphics
        .byte      IconType::small_generic ; animation/video
        .byte      IconType::small_generic ; music
        .byte      IconType::small_generic ; tracker
        .byte      IconType::small_generic ; audio
        .byte      IconType::small_generic ; speech
        .byte      IconType::small_generic ; font
        .byte      IconType::small_generic ; relocatable
        .byte      IconType::small_generic ; command
        .byte      IconType::small_folder  ; folder
        .byte      IconType::small_folder  ; system_folder
        .byte      IconType::small_generic ; iigs
        .byte      IconType::small_generic ; appleworks_db
        .byte      IconType::small_generic ; appleworks_wp
        .byte      IconType::small_generic ; appleworks_sp
        .byte      IconType::small_generic ; archive
        .byte      IconType::small_generic ; encoded
        .byte      IconType::small_generic ; link
        .byte      IconType::small_generic ; desk_accessory
        .byte      IconType::small_generic ; basic
        .byte      IconType::small_generic ; intbasic
        .byte      IconType::small_generic ; variables
        .byte      IconType::small_generic ; system
        .byte      IconType::small_generic ; application
        ;; Small Icon types skipped via math below
        ASSERT_TABLE_SIZE icontype_to_smicon_table, IconType::COUNT - IconType::SMALL_COUNT

;;; ============================================================

;;; Shortcut ("run list") paths
run_list_paths:
        .res    ::kMaxRunListEntries * ::kSelectorListPathLength, 0

;;; ============================================================
;;; Localized strings (may change length)
;;; ============================================================

str_device_type_diskii:
        PASCAL_STRING res_string_volume_type_disk_ii
str_device_type_ramdisk:
        PASCAL_STRING res_string_volume_type_ramcard
str_device_type_appletalk:
        PASCAL_STRING res_string_volume_type_fileshare
str_device_type_vdrive:
        PASCAL_STRING res_string_volume_type_vdrive
str_new_folder:
        PASCAL_STRING res_string_new_folder_default
str_date_and_time:
        PASCAL_STRING .concat(kFilenameDADir, "/", res_filename_control_panels, "/", res_filename_date_and_time)

;;; ============================================================

.endscope ; main

;;; ============================================================
;;; "Exports" from lib/ routines (mostly)

        ReadSetting := main::ReadSetting
        WriteSetting := main::WriteSetting
        GetNextEvent := main::GetNextEvent
        SystemTask := main::SystemTask
        Bell := main::Bell
        Multiply_16_8_16 := main::Multiply_16_8_16
        DetectDoubleClick := main::DetectDoubleClick
        AdjustOnLineEntryCase := main::AdjustOnLineEntryCase
        AdjustFileEntryCase := main::AdjustFileEntryCase

;;; ============================================================

        ENDSEG SegmentDeskTopMain
