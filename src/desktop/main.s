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
        .assert * < OVERLAY_BUFFER || * >= OVERLAY_BUFFER + kOverlayBufferSize, error, .sprintf("Routine used by overlays in overlay zone (at $%04X)", *)
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
    IF ZS
        ;; Maybe poll drives for updates
        dec     counter
      IF NEG
        copy8   #kDrivePollFrequency, counter
        jsr     CheckDiskInsertedEjected
        jmp     MainLoop
      END_IF
    END_IF

        ;; Get an event
        jsr     GetNextEvent

        ;; Did the mouse move?
    IF A = #kEventKindMouseMoved
        jsr     ClearTypeDown   ; always returns Z=1
        beq     loop            ; just to `loop` because no state change
    END_IF

        ;; Is it a key down event?
    IF A = #MGTK::EventKind::key_down
        jsr     HandleKeydown
        jmp     MainLoop
    END_IF

        ;; Is it a button-down event? (including w/ modifiers)
    IF A IN #MGTK::EventKind::button_down, #MGTK::EventKind::apple_key
        jsr     HandleClick
        jsr     ClearTypeDown   ; always returns Z=1
        beq     MainLoop        ; always
    END_IF

        ;; Is it an update event?
    IF A = #MGTK::EventKind::update
        jsr     ClearUpdatesSkipGet
    END_IF

        bne     loop            ; always

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

        PROC_USED_IN_OVERLAY

.proc ClearUpdates
    DO
        jsr     PeekEvent
        lda     event_params::kind
        BREAK_IF A <> #MGTK::EventKind::update

        jsr     GetEvent        ; no need to synthesize events

;;; If caller already called GetEvent, start here.
skip_get:
        MGTK_CALL MGTK::BeginUpdate, event_params::window_id
        CONTINUE_IF NOT_ZERO    ; obscured

        lda     event_params::window_id
      IF ZERO
        ;; Desktop
        ITK_CALL IconTK::DrawAll, event_params::window_id
      ELSE_IF A < #kMaxDeskTopWindows+1 ; 1...max are ours
        ;; Directory Window
        jsr     UpdateWindow
      END_IF
        MGTK_CALL MGTK::EndUpdate
    WHILE ZERO                  ; always

        rts
.endproc ; ClearUpdates
ClearUpdatesSkipGet := ClearUpdates::skip_get

;;; ============================================================
;;; Called by main and nested event loops to do periodic tasks.
;;; Returns 0 if the periodic tasks were run.

        PROC_USED_IN_OVERLAY
.proc SystemTask
        inc24   tick_counter

        inc     loop_counter
        inc     loop_counter
        loop_counter := *+1
        lda     #SELF_MODIFIED_BYTE
    IF A >= periodic_task_delay ; for per-machine timing
        copy8   #0, loop_counter

        jsr     ShowClock
        jsr     ResetIIgsRGB    ; in case it was reset by control panel
    END_IF
        RETURN  A=loop_counter
.endproc ; SystemTask

;;; ============================================================

.proc GetTickCount
        RETURN  A=tick_counter, X=tick_counter+1, Y=tick_counter+2
.endproc ; GetTickCount

tick_counter:
        .faraddr 0

;;; ============================================================

;;; Inputs: A = `window_id` from `update` event
.proc UpdateWindow
        sta     getwinport_params::window_id
        jsr     CacheWindowIconList

        ;; `AdjustUpdatePortForEntries` relies on `window_grafport`
        ;; for dimensions
        MGTK_CALL MGTK::GetWinPort, getwinport_params

        ;; This correctly uses the clipped port provided by BeginUpdate.

        jsr     DrawWindowHeader

        jsr     AdjustUpdatePortForEntries
        jmp     DrawWindowEntries
.endproc ; UpdateWindow

;;; ============================================================
;;; Menu Dispatch

.proc HandleKeydown
        ;; Handle accelerator keys
        lda     event_params::modifiers
        bne     modifiers       ; either Open-Apple or Solid-Apple ?

        ;; --------------------------------------------------
        ;; No modifiers

        CALL    CheckTypeDown, A=event_params::key
        RTS_IF ZERO

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
    IF A = #3                   ; both Open-Apple + Solid-Apple ?
        ;; Double-modifier shortcuts
        CALL    ToUpperCase, A=event_params::key
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
        cmp     #CHAR_ESCAPE    ; Apple-Esc (Clear Selection)
        jeq     ClearSelection

        ldx     active_window_id
    IF NOT_ZERO
        cmp     #kShortcutGrowWindow ; Apple-G (Resize)
        jeq     CmdResize
        cmp     #kShortcutMoveWindow ; Apple-M (Move)
        jeq     CmdMove

      IF A IN #'`', #'~', #CHAR_TAB ; Apple-`, Shift-Apple-`, Apple-Tab (Cycle Windows)
        jmp     CmdCycleWindows
      END_IF
    END_IF

        ;; Not one of our shortcuts - check for menu keys
        ;; (shortcuts or entering keyboard menu mode)
menu_accelerators:
        copy8   event_params::key, menu_click_params::which_key
        copy8   event_params::modifiers, menu_click_params::key_mods
        CLEAR_BIT7_FLAG menu_modified_click_flag ; note that source is not Apple+click
        MGTK_CALL MGTK::MenuKey, menu_click_params

        FALL_THROUGH_TO MenuDispatch
.endproc ; HandleKeydown

.proc MenuDispatch
        ldx     menu_click_params::menu_id ; X = menu id (1-based)
        RTS_IF ZERO

        copy8   offset_table-1,x, tmp ; A = `dispatch_table` offset for that menu
        lda     menu_click_params::item_num ; A = menu item id (1-based)
        asl     a                           ; *= 2; Assert: C=0
        tmp := *+1
        adc     #SELF_MODIFIED_BYTE
        tax
        copy16  dispatch_table-2,x, proc_addr
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
        .addr   0               ; --------
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
        .addr   0               ; --------
        .addr   CmdGetInfo
        .addr   CmdRename
        .addr   CmdDuplicate
        .addr   0               ; --------
        .addr   CmdCopySelection
        .addr   CmdDeleteSelection
        .addr   0               ; --------
        .addr   CmdQuit
        ASSERT_ADDRESS_TABLE_SIZE menu2_start, ::kMenuSizeFile

        ;; Edit menu (3)
        menu3_start := *
        .addr   CmdCut
        .addr   CmdCopy
        .addr   CmdPaste
        .addr   CmdClear
        .addr   0               ; --------
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
        .addr   CmdCheckAllDrives
        .addr   CmdCheckDrive
        .addr   CmdEject
        .addr   0               ; --------
        .addr   CmdFormatDisk
        .addr   CmdEraseDisk
        .addr   CmdDiskCopy
        .addr   0               ; --------
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
        .addr   0               ; --------
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
    IF ZERO
        ;; Click on desktop
        lda     #0
        sta     clicked_window_id
        sta     findwindow_params::window_id
        ITK_CALL IconTK::FindIcon, event_params::coords
        lda     findicon_params::which_icon
      IF NOT ZERO
        ldx     #0
        stx     focused_window_id
        jmp     _IconClick
      END_IF

        TAIL_CALL DragSelect, A=#0
    END_IF

    IF A = #MGTK::Area::menubar ; menu?

        ;; Maybe clock?
        lda     MACHID
        and     #kMachIDHasClock
      IF NOT_ZERO
        cmp16   event_params::xcoord, #460 ; TODO: Hard coded?
       IF GE
        TAIL_CALL InvokeDeskAccWithIcon, Y=#$FF, AX=#str_date_and_time
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
    END_IF

        SET_BIT7_FLAG maybe_select_parent_flag
        jsr     window_click

        maybe_select_parent_flag := *+1
        lda     #SELF_MODIFIED_BYTE
    IF NS
        lda     selected_icon_count
      IF ZERO
        ;; Try to select the window's parent icon.
        lda     active_window_id
       IF NOT_ZERO
        jsr     GetWindowPath
        jsr     IconToAnimate
        jmp     SelectIcon
       END_IF
      END_IF
    END_IF
        rts

        ;; --------------------------------------------------

window_click:
    IF A <> #MGTK::Area::content
        pha                     ; A = MGTK::Area::*
        ;; Activate if needed
        CALL    ActivateWindow, A=findwindow_params::window_id ; no-op if already active
        pla                     ; A = MGTK::Area::*

        cmp     #MGTK::Area::dragbar
        jeq     DoWindowDrag
        cmp     #MGTK::Area::grow_box
        jeq     DoWindowResize
        cmp     #MGTK::Area::close_box
        jeq     HandleCloseClick
        rts
    END_IF

;;; --------------------------------------------------

.scope _ContentClick
        lda     findwindow_params::window_id
        sta     clicked_window_id
        sta     focused_window_id
        sta     findcontrolex_params::window_id

        MGTK_CALL MGTK::FindControlEx, findcontrolex_params
        lda     findcontrol_params::which_ctl

        ASSERT_EQUALS MGTK::Ctl::not_a_control, 0
    IF ZERO
        ;; Ignore clicks in the header area
        copy8   clicked_window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     screentowindow_params::windowy
      IF A < #kWindowHeaderHeight
        jmp     _ActivateClickedWindow ; no-op if already active
      END_IF

        ;; On an icon?
        copy8   clicked_window_id, findicon_params::window_id
        ITK_CALL IconTK::FindIcon, findicon_params
        lda     findicon_params::which_icon
        jne     _IconClick

        ;; Not an icon - maybe a drag?
        jsr     _ActivateClickedWindow ; no-op if already active
        TAIL_CALL DragSelect, A=active_window_id
    END_IF

        ;; --------------------------------------------------

        ;; If not the active window, just activate it
        lda     clicked_window_id
        cmp     active_window_id
        jne     ActivateWindow

        lda     findcontrol_params::which_ctl
        RTS_IF A = #MGTK::Ctl::dead_zone

        ;; Thumb?
        ldy     findcontrol_params::which_part
        cpy     #MGTK::Part::thumb
        beq     _TrackThumb

    IF A = #MGTK::Ctl::vertical_scroll_bar
        ;; Vertical scrollbar
        lda     v_proc_lo,y      ; A = proc lo
        ldx     v_proc_hi,y      ; X = proc hi
        bne     _DoScrollbarPart ; always; Y = part
    END_IF

        ;; Horizontal scrollbar
        lda     h_proc_lo,y     ; A = proc hi
        ldx     h_proc_hi,y     ; X = proc hi
        FALL_THROUGH_TO _DoScrollbarPart ; Y = part

;;; ------------------------------------------------------------

;;; Input: A,X = proc, Y = part
.proc _DoScrollbarPart
        stax    proc
        sty     part
        copy8   findcontrol_params::which_ctl, ctl
    DO
        ;; Dispatch to handler
        proc := *+1
        jsr     SELF_MODIFIED

        ;; Check for control repeat
        jsr     PeekEvent
        lda     event_params::kind
        BREAK_IF A <> #MGTK::EventKind::drag

        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        ctl := *+1
        cmp     #SELF_MODIFIED_BYTE
        BREAK_IF NE

        lda     findcontrol_params::which_part
        part := *+1
        cmp     #SELF_MODIFIED_BYTE
    WHILE EQ
        FALL_THROUGH_TO ScrollNoOp
.endproc ; _DoScrollbarPart

ScrollNoOp:
        rts

v_proc_lo:        .lobytes ScrollNoOp, ScrollUp, ScrollDown, ScrollPageUp, ScrollPageDown
v_proc_hi:        .hibytes ScrollNoOp, ScrollUp, ScrollDown, ScrollPageUp, ScrollPageDown
h_proc_lo:        .lobytes ScrollNoOp, ScrollLeft, ScrollRight, ScrollPageLeft, ScrollPageRight
h_proc_hi:        .hibytes ScrollNoOp, ScrollLeft, ScrollRight, ScrollPageLeft, ScrollPageRight

;;; ------------------------------------------------------------

.proc _TrackThumb
        copy8   findcontrol_params::which_ctl, trackthumb_params::which_ctl
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        RTS_IF ZERO

        lda     trackthumb_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        jeq     ScrollTrackVThumb
        jmp     ScrollTrackHThumb
.endproc ; _TrackThumb

.endscope ; _ContentClick

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

        ;; Stash initial coords so dragging is accurate
        COPY_STRUCT event_params::coords, drag_drop_params::coords

        pla

        jsr     IsIconSelected
    IF EQ
        ;; --------------------------------------------------
        ;; Icon was already selected
        jsr     ExtendSelectionModifierDown
      IF NS
        ;; Modifier down - remove from selection
        CALL    UnhighlightAndDeselectIcon, A=findicon_params::which_icon
        CLEAR_BIT7_FLAG maybe_select_parent_flag
        jmp     _ActivateClickedWindow ; no-op if already active
      END_IF
    ELSE
        ;; --------------------------------------------------
        ;; Icon was not already selected
        jsr     ExtendSelectionModifierDown
      IF NS
        ;; Modifier down - add to selection
        ;; ...if there is a selection, and it is same window
        lda     selected_icon_count
       IF NOT_ZERO
        lda     findicon_params::window_id
        IF A <> selected_window_id
        jsr     ClearSelection
        END_IF
       END_IF
        copy8   findicon_params::window_id, selected_window_id
        CALL    AddIconToSelection, A=findicon_params::which_icon
        jmp     check_drag
      END_IF

        ;; Otherwise, replace selection with clicked icon
        CALL    SelectIcon, A=findicon_params::which_icon
    END_IF

        ;; --------------------------------------------------
        ;; Check for double-click

        jsr     DetectDoubleClick
    IF NC
        jsr     _ActivateClickedWindow ; no-op if already active
        jmp     CmdOpenFromDoubleClick
    END_IF

        ;; --------------------------------------------------
        ;; Drag of icon?

check_drag:

        copy8   findicon_params::which_icon, drag_drop_params::icon
        ITK_CALL IconTK::DragHighlighted, drag_drop_params

        RTS_IF A = #IconTK::kDragResultCanceled

    IF A = #IconTK::kDragResultNotADrag
        jsr     _ActivateClickedWindow ; no-op if already active
        jmp     _CheckRenameClick
    END_IF

        ;; ----------------------------------------

    IF A = #IconTK::kDragResultMove
        jsr     RedrawSelectedIcons

        jsr     _ActivateClickedWindow ; no-op if already active

        lda     selected_window_id
        RTS_IF ZERO

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

    IF A = #IconTK::kDragResultMoveModified
        lda     selected_window_id
        RTS_IF ZERO

        jsr     _ActivateClickedWindow

        ;; File drop on same window, but with modifier(s) down so not a move

        jsr     GetSingleSelectedIcon
        RTS_IF ZERO

        ;; Double modifier?
        lda     BUTN0
        and     BUTN1
      IF NS
        jsr     SetOperationDstPathFromDragDropResult
        RTS_IF CS               ; failure, e.g. path too long
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
    IF A = trash_icon_num
        lda     selected_window_id
        jeq     CmdEject
        jmp     CmdDeleteSelection
    END_IF

        ;; Desktop?
        RTS_IF A = #$80         ; ignore

        ;; Path for target
        jsr     SetOperationDstPathFromDragDropResult
        RTS_IF CS               ; failure, e.g. path too long

        ;; Double modifier?
        lda     BUTN0
        and     BUTN1
    IF NS
        jsr     GetSingleSelectedIcon
        RTS_IF ZERO
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
    IF NOT_ZERO
      IF A = prev_selected_icon
       IF A <> trash_icon_num
        sta     icon_param
        ITK_CALL IconTK::GetRenameRect, icon_param
        MGTK_CALL MGTK::MoveTo, event_params::coords
        MGTK_CALL MGTK::InRect, tmp_rect
        jne     CmdRename
       END_IF
      END_IF
    END_IF
        rts
.endproc ; _CheckRenameClick

;;;------------------------------------------------------------
;;; After an icon drop (file or volume), update any affected
;;; windows.
;;; Inputs: A = `kOperationXYZ`, and `drag_drop_params::target`

.proc _PerformPostDropUpdates
        ;; --------------------------------------------------
        ;; (1/4) Canceled?

        RTS_IF A = #kOperationCanceled

        ;; --------------------------------------------------
        ;; (2/4) Was a move?
        ;; NOTE: Only applies in file icon case.

        PREDEFINE_SCOPE ::main::operations

        bit     operations::move_flags
    IF NS
        ;; Update source vol's contents
        jsr     _MaybeStashDropTargetName ; in case target is in window...
        jsr     UpdateActivateAndRefreshSelectedWindow
        jsr     _MaybeUpdateDropTargetFromName ; ...restore after update.
    END_IF

        ;; --------------------------------------------------
        ;; (3/4) Dropped on icon?

        lda     drag_drop_params::target
    IF NC
        ;; Yes, on an icon; update used/free for same-vol windows
        pha
        jsr     GetIconPath     ; `operation_src_path` set to path, A=0 on success
      IF ZERO
        CALL    UpdateUsedFreeViaPath, AX=#operation_src_path
      END_IF
        pla

        jsr     FindWindowIndexForDirIcon ; X = window id-1 if found
      IF EQ
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

;;; --------------------------------------------------
;;; Save/Restore drop target icon ID in case the window was rebuilt.

;;; Inputs: `drag_drop_params::target`
;;; Assert: If target is a file icon, icon is in active window.
;;; Trashes $06
.proc _MaybeStashDropTargetName
        ;; Flag as not stashed
        copy8   #0, stashed_name

        ;; Is the target an icon?
        lda     drag_drop_params::target
    IF NC                       ; high bit clear = icon
        ;; Is the target in a window?
        jsr     GetIconWindow
      IF NOT_ZERO
        ;; Stash name
        ptr1 := $06
        CALL    GetIconName, A=drag_drop_params::target
        stax    ptr1
        CALL    CopyPtr1ToBuf, AX=#stashed_name
      END_IF
    END_IF
        rts
.endproc ; _MaybeStashDropTargetName

;;; --------------------------------------------------
;;; Outputs: `drag_drop_params::target` updated if needed
;;; Assert: `_MaybeStashDropTargetName` was previously called
;;; Trashes $06

.proc _MaybeUpdateDropTargetFromName
        ;; Did we previously stash an icon's name?
        lda     stashed_name
    IF NOT_ZERO
        ;; Try to find the icon by name.
        ldy     active_window_id
        CALL    FindIconByName, AX=#stashed_name
      IF NOT_ZERO
        ;; Update drop target with new icon id.
        sta     drag_drop_params::target
      END_IF
    END_IF
        rts
.endproc ; _MaybeUpdateDropTargetFromName

;;; --------------------------------------------------

.proc _ActivateClickedWindow
        window_id := *+1
        lda     #SELF_MODIFIED_BYTE
        FALL_THROUGH_TO ActivateWindow
.endproc ; _ActivateClickedWindow
clicked_window_id := _ActivateClickedWindow::window_id

.endproc ; HandleClick

;;; ============================================================
;;; Activate the window, draw contents, and update menu items
;;; No-op if the window is already active, or if 0 passed.
;;; Inputs: A = window id to activate

.proc ActivateWindow
        sta     focused_window_id

        RTS_IF A = active_window_id

        RTS_IF A = #0

        ;; Make the window active.
        sta     active_window_id
        MGTK_CALL MGTK::SelectWindow, active_window_id

        ;; Repaint the contents
        jsr     UpdateWindowUsedFreeDisplayValues
        jsr     CacheActiveWindowIconList
        FALL_THROUGH_TO DrawCachedWindowHeaderAndEntries
.endproc ; ActivateWindow

;;; ============================================================

.proc DrawCachedWindowHeaderAndEntries
        CALL    UnsafeSetPortFromWindowId, A=cached_window_id ; CHECKED
    IF ZERO
        jsr     DrawWindowHeader
        jsr     AdjustWindowPortForEntries
        jsr     DrawWindowEntries
    END_IF
        rts
.endproc ; DrawCachedWindowHeaderAndEntries

;;; ============================================================
;;; Redraw the active window's entries. The header is not redrawn.

.proc ClearAndDrawActiveWindowEntries
        CALL    UnsafeSetPortFromWindowIdAndAdjustForEntries, A=active_window_id ; CHECKED
    IF ZERO
        jsr     EraseWindowBackground
        jsr     DrawWindowEntries
    END_IF
        rts
.endproc ; ClearAndDrawActiveWindowEntries

;;; ============================================================

;;; Assumes `window_grafport` is selected/initialized
.proc EraseWindowBackground
        MGTK_CALL MGTK::ShieldCursor, window_grafport+MGTK::GrafPort::maprect
        MGTK_CALL MGTK::PaintRect, window_grafport+MGTK::GrafPort::maprect
        MGTK_CALL MGTK::UnshieldCursor
        rts
.endproc ; EraseWindowBackground

;;; ============================================================

;;; Used only for file windows; adjusts port to account for header.
;;; Returns 0 if ok, `MGTK::Error::window_obscured` if the window is obscured.
.proc UnsafeSetPortFromWindowIdAndAdjustForEntries
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF ZERO                     ; not MGTK::Error::window_obscured
        jsr     AdjustWindowPortForEntries
    END_IF
        rts
.endproc ; UnsafeSetPortFromWindowIdAndAdjustForEntries

;;; Used for all sorts of windows, not just file windows.
;;; For file windows, used for drawing headers (sometimes);
;;; Returns 0 if ok, `MGTK::Error::window_obscured` if the window is obscured.
.proc UnsafeSetPortFromWindowId
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF ZERO                     ; not MGTK::Error::window_obscured
        MGTK_CALL MGTK::SetPort, window_grafport
    END_IF
        rts
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
    IF NOT_ZERO
        jsr     CheckDisksInDevices
        ldx     disk_in_device_table
      DO
        lda     disk_in_device_table,x
        cmp     last_disk_in_devices_table,x
        bne     changed
        dex
      WHILE NOT_ZERO
    END_IF
        RETURN  A=#0

changed:
        copy8   disk_in_device_table,x, last_disk_in_devices_table,x

        lda     removable_device_table,x
        ldy     DEVCNT
    DO
        cmp     DEVLST,y
        beq     found
        dey
    WHILE POS
        rts

found:
        tya
        TAIL_CALL CheckDriveByIndex, Y=#kCheckDriveShowUnexpectedErrors ; A = DEVLST index
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
    IF NOT_ZERO
        stx     disk_in_device_table
      DO
        CALL    check_disk_in_drive, A=removable_device_table,x
        sta     disk_in_device_table,x
        dex
      WHILE NOT_ZERO
    END_IF

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
    IF CC                       ; is SmartPort
        stax    dispatch
        sty     status_params::unit_num

        ;; Execute SmartPort call
        dispatch := *+1
        jsr     SELF_MODIFIED
        .byte   SPCall::Status
        .addr   status_params

        lda     status_buffer
        and     #$10            ; general status byte, $10 = disk in drive
      IF NOT_ZERO
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
    IF NOT_ZERO
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
    IF NOT_ZERO
        ora     #kHasShortcuts  ; A = flags
    END_IF

        ;; --------------------------------------------------
        ;; Selected Icons

        ldx     selected_icon_count
    IF NOT_ZERO
        ;; Single?
      IF X = #1
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
       IF X = #IconType::link
        ora     #kLinkSel       ; A = flags
       END_IF
      END_IF

        ;; Files or Volumes?
        ldx     selected_window_id ; In a window?
      IF NOT_ZERO
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
    DO
        lda     table,y         ; menu_id
        RTS_IF ZERO             ; sentinel
        sta     disableitem_params::menu_id
        iny

        lda     table,y         ; menu_item
        sta     disableitem_params::menu_item
        iny

        ldx     #MGTK::disableitem_disable
        lda     table,y         ; flags
        flags := *+1
        and     #SELF_MODIFIED_BYTE
      IF A = table,y
        ldx     #MGTK::disableitem_enable
      END_IF
        stx     disableitem_params::disable
        iny

        tya
        pha
        MGTK_CALL MGTK::DisableItem, disableitem_params
        pla
        tay
    WHILE NOT_ZERO              ; always

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
        ENTRY_POINTS_FOR_A check, MGTK::checkitem_check, uncheck, MGTK::checkitem_uncheck

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

.proc LaunchFileWithPathImpl
        ENTRY_POINTS_FOR_BIT7_FLAG sys_disk, normal_disk, sys_prompt_flag

        ;; --------------------------------------------------
        jsr     SetCursorWatch  ; before invoking file
        jsr     rest
        jmp     SetCursorPointer ; after invoking file
rest:
        ;; --------------------------------------------------

        ;; Easiest to assume absolute path later.
        jsr     _MakeSrcPathAbsolute ; Trashes `INVOKER_INTERPRETER`

        ;; Assume no interpreter to start
        lda     #0
        sta     INVOKER_INTERPRETER
        sta     INVOKER_BITSY_COMPAT

        ;; Get the file info to determine type.
retry:  jsr     GetSrcFileInfo
    IF CS
        sys_prompt_flag := *+1
        lda     #SELF_MODIFIED_BYTE
        jpl     ShowAlert

        CALL    ShowAlert, A=#kErrInsertSystemDisk
        cmp     #kAlertResultOK
        beq     retry           ; ok, so try again
        rts                     ; cancel, so fail
    END_IF

        ;; Check file type.
        CALL    DetermineIconType, AX=#src_path_buf ; uses passed name and `src_file_info_params`

        ;; Handler based on type
        asl                     ; *= 4
        asl
        tax

        copy16  invoke_table,x, handler
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
    IF CC                       ; yes, continue below
        SET_BIT7_FLAG INVOKER_BITSY_COMPAT
        bmi     launch          ; always
    END_IF
        TAIL_CALL ShowAlertParams, Y=#AlertButtonOptions::OK, AX=#aux::str_alert_cannot_open

        ;; --------------------------------------------------
        ;; Launch interpreter (system file that accepts path).
interpreter:
        ptr1 := $06
        stax    ptr1            ; save for later

        ;; Is the interpreter where we expect it?
        jsr     GetFileInfo
        RTS_IF  CS              ; nope, just ignore

        ;; Construct absolute path
        CALL    _MakeRelPathAbsoluteIntoInvokerInterpreter, AX=ptr1
        FALL_THROUGH_TO launch

        ;; --------------------------------------------------
        ;; Generic launch
launch:
        CALL    IconToAnimate, AX=#src_path_buf
        CALL    AnimateWindowOpen, X=#$FF ; desktop

        CALL    UpcaseString, AX=#INVOKER_PREFIX
        CALL    UpcaseString, AX=#INVOKER_INTERPRETER
        jsr     SplitInvokerPath

        copy16  #INVOKER, reset_and_invoke_target
        jmp     ResetAndInvoke

        ;; --------------------------------------------------
        ;; BASIC program
basic:  jsr     _CheckBasicSystem ; Only launch if BASIC.SYSTEM is found
        jcc     launch
        TAIL_CALL ShowAlert, A=#kErrBasicSysNotFound

        ;; --------------------------------------------------
        ;; Binary file
binary:
        lda     menu_click_params::menu_id ; From a menu (File, Selector)
        jne     launch
        jsr     ModifierDown ; Otherwise, only launch if a button is down
        jmi     launch
        CALL    ShowAlertParams,  Y=#AlertButtonOptions::OKCancel, AX=#aux::str_alert_confirm_running
        RTS_IF A <> #kAlertResultOK
        jmp     launch

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

        ;; "BASI?" -> "BASIC", "BASI?" -> "BASIS"
        ENTRY_POINTS_FOR_A basic, 'C', basis, 'S'
        sta     str_basix_system + kBSOffset

        ;; Start off with `interp_path` = `launch_path`
        COPY_STRING launch_path, interp_path

        ;; Pop off a path segment.
    DO
        CALL    RemovePathSegment, AX=#interp_path
        BREAK_IF A < #2
        inc     interp_path     ; restore trailing '/'

        ;; Append BASI?.SYSTEM to path and check for file.
        CALL    _AppendToInvokerInterpreter, AX=#str_basix_system
        CALL    GetFileInfo, AX=#interp_path
        bcc     ret

        CALL    RemovePathSegment, AX=#interp_path
    WHILE NOT_ZERO              ; always

        copy8   #0, interp_path ; null out the path
        sec

ret:    rts
.endproc ; _CheckBasixSystemImpl
_CheckBasisSystem        := _CheckBasixSystemImpl::basis

.proc _CheckBasicSystem
        CALL    _MakeRelPathAbsoluteIntoInvokerInterpreter, AX=#str_extras_basic
        CALL    GetFileInfo, AX=#INVOKER_INTERPRETER
        jcs     _CheckBasixSystemImpl::basic ; nope, look relative to launch path
        rts
.endproc ; _CheckBasicSystem

;;; --------------------------------------------------

;;; Input: A,X = relative path to append
;;; Output: `INVOKER_INTERPRETER` has absolute path
.proc _MakeRelPathAbsoluteIntoInvokerInterpreter
        phax
        MLI_CALL GET_PREFIX, get_prefix_params
        plax
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
        copy8   (ptr1),y, len
    DO
        iny
        inx
        copy8   (ptr1),y, INVOKER_INTERPRETER,x
    WHILE Y <> len
        stx     INVOKER_INTERPRETER

        jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc ; _AppendToInvokerInterpreter

;;; --------------------------------------------------

.proc _OpenFolder
        tsx
        stx     saved_stack

        jsr     OpenWindowForPath ; do not tail-call optimize!
        rts
.endproc ; _OpenFolder


;;; --------------------------------------------------
;;; Invoke a Preview DA
;;; Inputs: A,X = relative path to DA; `src_path_buf` is file to preview

.proc _InvokePreview
        phax
        CALL    IconToAnimate, AX=#src_path_buf
        tay
        plax
        jmp     InvokeDeskAccWithIcon
.endproc ; _InvokePreview

;;; --------------------------------------------------

.proc _InvokeLink
        jsr     ReadLinkFile
        RTS_IF CS
        jmp     LaunchFileWithPath
.endproc ; _InvokeLink

;;; --------------------------------------------------

;;; Trashes: `INVOKER_INTERPRETER`
.proc _MakeSrcPathAbsolute
        ;; Already absolute?
        lda     src_path_buf+1
    IF A <> #'/'
        ;; Get prefix and append path
        CALL    _MakeRelPathAbsoluteIntoInvokerInterpreter, AX=#src_path_buf

        ;; Copy back to original buffer
        CALL    CopyToSrcPath, AX=#INVOKER_INTERPRETER
    END_IF

        rts
.endproc ; _MakeSrcPathAbsolute

;;; --------------------------------------------------

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, INVOKER_INTERPRETER

.endproc ; LaunchFileWithPathImpl
LaunchFileWithPathOnSystemDisk := LaunchFileWithPathImpl::sys_disk
LaunchFileWithPath := LaunchFileWithPathImpl::normal_disk

;;; ============================================================

;;; Inputs: `src_path_buf` has path to LNK file
;;; Output: C=0, `src_path_buf` has target on success
;;;         C=1 and alert is shown on error

.proc ReadLinkFile
        read_buf := $800

        MLI_CALL OPEN, open_params
        bcs     err
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        php
        MLI_CALL CLOSE, close_params
        plp
        bcs     err

        lda     read_params::trans_count
    IF A >= #kLinkFilePathLengthOffset

        ldx     #kCheckHeaderLength-1
      DO
        lda     read_buf,x
        cmp     check_header,x
        bne     bad
        dex
      WHILE POS

        CALL    CopyToSrcPath, AX=#read_buf + kLinkFilePathLengthOffset
        RETURN  C=0
    END_IF

bad:    lda     #kErrUnknown
err:    jsr     ShowAlert
        RETURN  C=1

check_header:
        .byte   kLinkFileSig1Value, kLinkFileSig2Value, kLinkFileCurrentVersion
        kCheckHeaderLength = * - check_header

        DEFINE_OPEN_PARAMS open_params, src_path_buf, $1C00
        DEFINE_READWRITE_PARAMS read_params, read_buf, kLinkFileMaxSize
        DEFINE_CLOSE_PARAMS close_params

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
    IF NOT_ZERO
        tay
      DO
        lda     (ptr),y
        jsr     ToUpperCase
        sta     (ptr),y
        dey
      WHILE NOT_ZERO
    END_IF
        rts
.endproc ; UpcaseString

;;; ============================================================
;;; Inputs: Character in A
;;; Outputs: Z=1 if alpha, 0 otherwise
;;; A is trashed

.proc IsAlpha
        jsr     ToUpperCase
    IF A BETWEEN #'A', #'Z'
        lda     #0              ; set Z=1
        rts
    END_IF

        lda     #$FF            ; set Z=0
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
    DO
        copy8   devlst_backup,x, DEVLST-1,x ; DEVCNT is at DEVLST-1
        dex
    WHILE POS
        rts
.endproc ; RestoreDeviceList

;;; Backup copy of DEVLST made before reordering and detaching offline devices
devlst_backup:
        .res    ::kMaxDevListSize+1, 0 ; +1 for DEVCNT itself

;;; ============================================================

.proc CmdSelectorAction
        ;; If adding, try to default to the current selection.
        lda     menu_click_params::item_num
    IF A = #kMenuItemIdSelectorAdd
        copy8   #0, path_buf0

        ;; If there's a selection, put it in `path_buf0`
        lda     selected_icon_count
      IF NOT_ZERO
        CALL    GetIconPath, A=selected_icon_list ; `operation_src_path` set to path; A=0 on success
        jne     ShowAlert       ; too long

        CALL    CopyToBuf0, AX=#operation_src_path
      END_IF
    END_IF

        CALL    LoadDynamicRoutine, A=#kDynamicRoutineShortcutPick
        bmi     done

        lda     menu_click_params::item_num
    IF A < #SelectorAction::delete
        ;; Add or Edit - need more overlays
        CALL    LoadDynamicRoutine, A=#kDynamicRoutineShortcutEdit
        bmi     done
        CALL    LoadDynamicRoutine, A=#kDynamicRoutineFileDialog
        bmi     done
    END_IF

        ;; Invoke routine
        CALL    SelectorPickOverlay::Exec, A=menu_click_params::item_num
        sta     result

        ;; Restore from overlays
        ;; (restore from file dialog overlay handled in picker overlay)
        CALL    RestoreDynamicRoutine, A=#kDynamicRoutineRestoreSP ; restore from picker dialog

        bit     result
        bmi     done            ; N=1 for Cancel

        lda     menu_click_params::item_num
    IF A = #SelectorAction::run
        ;; "Run" command
        result := *+1
        lda     #SELF_MODIFIED_BYTE
        bpl     InvokeSelectorEntry ; always
    END_IF

done:   rts
.endproc ; CmdSelectorAction

;;; ============================================================

.proc CmdSelectorItem
        lda     menu_click_params::item_num
        sec
        sbc     #kSelectorMenuFixedItems + 1 ; make 0 based

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
        CALL    CopyPtr1ToBuf, AX=#entry_path

        ;; Is there a RAMCard at all?
        jsr     GetCopiedToRAMCardFlag
        beq     use_entry_path  ; no RAMCard, skip

        ;; Look at the entry's flags
        CALL    _SetEntryPtr, A=entry_num

        ldy     #kSelectorEntryFlagsOffset ; flag byte following name
        lda     (ptr),y
        ASSERT_EQUALS ::kSelectorEntryCopyOnBoot, 0
        beq     on_boot
        cmp     #kSelectorEntryCopyNever
        beq     use_entry_path  ; not copied

        ;; --------------------------------------------------
        ;; `kSelectorEntryCopyOnUse`
        CALL    GetEntryCopiedToRAMCardFlag, X=entry_num
        bmi     use_ramcard_path ; already copied!

        ;; Need to copy to RAMCard
        jsr     _PrepEntryCopyPaths
        jsr     DoCopyToRAM

        RTS_IF A = #kOperationCanceled

    IF A = #kOperationFailed
        CALL    CopyRAMCardPrefix, AX=#operation_dst_path
        jmp     RefreshWindowForOperationDstPath
    END_IF

        ;; Success!
        CALL    SetEntryCopiedToRAMCardFlag, X=entry_num, A=#$FF
        jmp     use_ramcard_path

        ;; --------------------------------------------------
        ;; `kSelectorEntryCopyOnBoot`
on_boot:
        CALL    GetEntryCopiedToRAMCardFlag, X=entry_num
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

launch: CALL    CopyPtr1ToBuf, AX=#INVOKER_PREFIX
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
        CALL    CopyPtr1ToBuf, AX=#entry_ramcard_path

        ;; Strip segment off path at `entry_original_path`
        ;; e.g. "/VOL/MOUSEPAINT/MP.SYSTEM" -> "/VOL/MOUSEPAINT"
        CALL    RemovePathSegment, AX=#entry_original_path

        ;; Strip segment off path at `entry_ramcard_path`
        ;; e.g. "/RAM/MOUSEPAINT/MP.SYSTEM" -> "/RAM/MOUSEPAINT"
        CALL    RemovePathSegment, AX=#entry_ramcard_path

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
        CALL    CopyRAMCardPrefix, AX=#src_path_buf
        ldy     entry_path

        ;; Walk back two segments
        ldx     #2
    DO
        ;; Walk back one segment
      DO
        lda     entry_path,y
        BREAK_IF A = #'/'
        dey
      WHILE NOT_ZERO
        dey
        dex
    WHILE NOT ZERO

        ;; Append last two segments to `src_path_buf`
        ldx     src_path_buf
    DO
        inx
        iny
        copy8   entry_path,y, src_path_buf,x
    WHILE Y <> entry_path

        stx     src_path_buf
        RETURN  AX=#src_path_buf
.endproc ; _ComposeRAMCardEntryPath

;;; --------------------------------------------------
;;; Input: A = entry num
;;; Output: $06 points at entry
;;; NOTE: If in the "primary" list, points at the permanently loaded
;;; copy. Otherwise, assumes the picker just ran and points at the
;;; temporarily loaded copy.
.proc _SetEntryPtr
        ptr := $06

    IF A < #kSelectorListNumPrimaryRunListEntries
        jsr     ATimes16
        addax   #run_list_entries, ptr
        rts
    END_IF

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

    IF A < #kSelectorListNumPrimaryRunListEntries
        jsr     ATimes64
        addax   #run_list_paths, ptr
        rts
    END_IF

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
    DO
        lda     (ptr1),y
        addr := *+1
        sta     SELF_MODIFIED,y
        dey
    WHILE POS
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
    DO
        lda     (ptr2),y
        addr := *+1
        sta     SELF_MODIFIED,y
        dey
    WHILE POS
        rts
.endproc ; CopyPtr2ToBuf

;;; ============================================================

CmdAbout := AboutDialogProc

;;; ============================================================

.proc CmdAboutThisApple
        TAIL_CALL InvokeDeskAccWithIcon, Y=#$FF, AX=#str_about_this_apple
.endproc ; CmdAboutThisApple

;;; ============================================================

.proc CmdDeskAccImpl
        ptr := $6
        len := $8
        path := INVOKER_PREFIX

str_desk_acc:
        PASCAL_STRING .concat(kFilenameDADir, "/")

start:
        ;; Append DA directory name
        CALL    CopyToSrcPath, AX=#str_desk_acc

        ;; Find DA name
        lda     menu_click_params::item_num ; menu item index (1-based)
        sec
        sbc     #kAppleMenuFixedItems+1
        tay
        CALL    Multiply_16_8_16, AX=#kDAMenuItemSize
        addax   #desk_acc_names, ptr

        ;; Append name to path
        ldx     path
        ldy     #0
        copy8   ($06),y, len
    DO
        inx
skip:   iny
        lda     ($06),y
        cmp     #' '            ; Convert spaces back to periods
        bcc     skip            ; Ignore control characters (i.e. folder glyphs)
      IF EQ
        lda     #'.'
      END_IF
        sta     path,x
    WHILE Y <> len
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
    IF NOT_ZERO
        lda     selected_icon_list ; first selected icon
      IF A <> trash_icon_num    ; ignore trash
        jsr     GetIconPath     ; `operation_src_path` set to path; A=0 on success
        jne     ShowAlert       ; too long
        CALL    CopyToSrcPath, AX=#operation_src_path
      END_IF
    END_IF
        CALL    IconToAnimate, AX=#tmp_path_buf
        tay
        ldax    #tmp_path_buf
        FALL_THROUGH_TO InvokeDeskAccWithIcon
.endproc ; InvokeDeskAccByPath

;;; ============================================================
;;; Invoke Desk Accessory
;;; Input: A,X = DA pathname (relative is OK)
;;;        Y = icon id to animate ($FF for none)

.proc InvokeDeskAccWithIcon
        stax    open_params::pathname

        tya
        sta     icon            ; can't use stack, as DAs can modify
    IF NC
        CALL    AnimateWindowOpen, X=#$FF ; desktop
    END_IF

        ;; Load the DA
retry:  MLI_CALL OPEN, open_params
    IF CS
        CALL    ShowAlert, A=#kErrInsertSystemDisk
        cmp     #kAlertResultOK
        beq     retry           ; ok, so try again
        rts                     ; cancel, so fail
    END_IF

        lda     open_params::ref_num
        sta     read_header_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_header_params

        lda     DAHeader::aux_length
        ora     DAHeader::aux_length+1
        beq     main

        ;; Aux memory segment
        copy16  DAHeader::aux_length, read_params::request_count
        MLI_CALL READ, read_params
        copy16  #DA_LOAD_ADDRESS, STARTLO
        copy16  #DA_LOAD_ADDRESS, DESTINATIONLO
        add16   #DA_LOAD_ADDRESS-1, DAHeader::aux_length, ENDLO
        CALL    AUXMOVE, C=1    ; main>aux

        ;; Main memory segment
main:   copy16  DAHeader::main_length, read_params::request_count
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
    IF NC
        CALL    AnimateWindowClose, X=#$FF ; desktop
    END_IF

        jmp     SetCursorPointer ; after invoking DA

.params DAHeader
aux_length:     .word   0
main_length:    .word   0
.endparams

        DEFINE_OPEN_PARAMS open_params, 0, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS read_header_params, DAHeader, .sizeof(DAHeader)
        DEFINE_READWRITE_PARAMS read_params, DA_LOAD_ADDRESS, kDAMaxSize
        DEFINE_CLOSE_PARAMS close_params

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
    IF ZERO
        ;; No, just use volume path

        ;; Save length
        ldy     #0
        lda     (ptr),y
        pha

        CALL    MakeVolumePath, AX=ptr
        CALL    FindIconForPath, AX=ptr
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
        copy8   (ptr),y, pathlen
        iny                     ; start at 2nd character
    DO
        iny
        cpy     pathlen
        beq     :+
        lda     (ptr),y
    WHILE A <> #'/'
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
        CALL    LoadDynamicRoutine, A=#kDynamicRoutineFileDialog
        RTS_IF NS

        CALL    LoadDynamicRoutine, A=#kDynamicRoutineFileCopy
        RTS_IF NS

        jsr     ::FileCopyOverlay::Run
        pha                     ; A = dialog result
        CALL    RestoreDynamicRoutine, A=#kDynamicRoutineRestoreFD
        jsr     PushPointers    ; $06 = dst
        jsr     ClearUpdates    ; following picker dialog close
        jsr     PopPointers     ; $06 = dst
        pla                     ; A = dialog result
        RTS_IF NS

        ;; --------------------------------------------------
        ;; Try the copy

        CALL    CopyPtr1ToBuf, AX=#operation_dst_path
        jsr     DoCopySelection

        RTS_IF A = #kOperationCanceled

        FALL_THROUGH_TO RefreshWindowForOperationDstPath

.endproc ; CmdCopySelection

;;; ============================================================

.proc RefreshWindowForOperationDstPath
        ;; See if there's a window we should activate later.
        CALL    FindWindowForPath, AX=#operation_dst_path
        pha                     ; save for later

        ;; Update cached used/free for all same-volume windows
        CALL    UpdateUsedFreeViaPath, AX=#operation_dst_path

        ;; Select/refresh window if there was one
        pla
        jne     ActivateAndRefreshWindowOrClose

        rts
.endproc ; RefreshWindowForOperationDstPath

;;; ============================================================
;;; Copy string at ($6) to `operation_src_path`, string at ($8) to `operation_dst_path`,
;;; split filename off `operation_dst_path` and store in `filename_buf`

.proc CopyPathsFromPtrsToBufsAndSplitName

        ;; Copy string at $6 to `operation_src_path`
        CALL    CopyPtr1ToBuf, AX=#operation_src_path

        ;; Copy string at $8 to `operation_dst_path`
        CALL    CopyPtr2ToBuf, AX=#operation_dst_path
        FALL_THROUGH_TO SplitOperationDstPath
.endproc ; CopyPathsFromPtrsToBufsAndSplitName

;;; Split filename off `operation_dst_path` and store in `filename_buf`
;;; If a volume name, splits off leading "/" (e.g. "/VOL" to "/" and "VOL")
.proc SplitOperationDstPath
        CALL    FindLastPathSegment, AX=#operation_dst_path

    IF Y <> operation_dst_path
        tya                     ; Y = position of last '/'
        pha

        ;; Shorter, so file - Copy filename part to buf
        ldx     #1
        iny                     ; +1 for length byte
        iny                     ; +1 to skip past '/'
      DO
        copy8   operation_dst_path,y, filename_buf,x
        BREAK_IF Y = operation_dst_path
        iny
        inx
      WHILE NOT_ZERO
        stx     filename_buf

        ;; And remove from `operation_dst_path`
        pla
        tay                     ; Y = position of last '/'
        sty     operation_dst_path
        rts
    END_IF

        ;; Unchanged, so volume - Copy, removing leading slash
        dey
        sty     filename_buf
    DO
        copy8   operation_dst_path+1,y, filename_buf,y
        dey
    WHILE NOT_ZERO
        copy8   #1, operation_dst_path
        rts
.endproc ; SplitOperationDstPath

;;; ============================================================
;;; Split filename off `INVOKER_PREFIX` into `INVOKER_FILENAME`
;;; Assert: `INVOKER_PREFIX` is a file path not volume path

.proc SplitInvokerPath
        CALL    FindLastPathSegment, AX=#INVOKER_PREFIX ; point Y at last '/'
        tya
        pha
        ldx     #1
        iny                     ; +1 for length byte
        iny                     ; +1 to skip past '/'
    DO
        copy8   INVOKER_PREFIX,y, INVOKER_FILENAME,x
        BREAK_IF Y = INVOKER_PREFIX
        iny
        inx
    WHILE NOT_ZERO              ; always
        stx     INVOKER_FILENAME
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
    IF NS
        lda     selected_window_id
    END_IF
        sta     window_id_to_close
        jmp     common

        ;; --------------------------------------------------
        ;; Entry point from OA+SA+O / OA+SA+Down

open_then_close_current:
        lda     selected_icon_count
        RTS_IF ZERO

        copy8   selected_window_id, window_id_to_close
        bpl     common          ; always

        ;; --------------------------------------------------
        ;; Entry point from Apple+Down

        ;; Never close after open only.
from_keyboard:
        lda     selected_icon_count
        RTS_IF ZERO

        copy8   #0, window_id_to_close
        beq     common          ; always

        ;; --------------------------------------------------
        ;; Entry point from double-click

        ;; Close after open if modifier is down.
from_double_click:
        copy8   #0, window_id_to_close
        jsr     ModifierDown
    IF NS
        copy8   selected_window_id, window_id_to_close
    END_IF
        FALL_THROUGH_TO common

        ;; --------------------------------------------------
common:
        CLEAR_BIT7_FLAG dir_flag

        ;; Make a copy of selection
        ldx     selected_icon_count
        stx     selected_icon_count_copy
    DO
        copy8   selected_icon_list-1,x, selected_icon_list_copy-1,x
        dex
    WHILE NOT_ZERO

        ;; Iterate selected icons
        ldx     #0
    DO
        cpx     selected_icon_count_copy
        bne     next

        ;; Finish up...

        ;; Were any directories opened?
        dir_flag := *+1
        lda     #SELF_MODIFIED_BYTE ; bit7
      IF NS
        ;; Maybe close the previously active window, depending on source/modifiers
        jsr     MaybeCloseWindowAfterOpen
      END_IF
        rts

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
        beq     maybe_open_file ; nope

        ;; Directory
        SET_BIT7_FLAG dir_flag

        pla                     ; A = icon id
        jsr     OpenWindowForIcon

next_icon:
        pla                     ; A = index
        tax
        inx
    WHILE NOT_ZERO              ; always

        ;; File (executable or data)
maybe_open_file:
        pla                     ; A = icon id
        tax                     ; X = icon id

        lda     selected_icon_count_copy
        cmp     #2              ; multiple files open?
        bcs     next_icon       ; don't try to invoke

        pla                     ; A = index; no longer needed

        txa                     ; A = icon id
        jsr     GetIconPath     ; `operation_src_path` set to path; A=0 on success
        jne     ShowAlert       ; too long
        CALL    CopyToSrcPath, AX=#operation_src_path

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
    IF NOT_ZERO
        jsr     CloseSpecifiedWindow
    END_IF
        rts
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
        CALL    FindLastPathSegment, AX=#src_path_buf ; point Y at last '/'
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
    IF ZERO
        CALL    SelectFileIconByName, AX=#INVOKER_FILENAME
    END_IF

done:   rts

        ;; --------------------------------------------------
        ;; Find volume icon by name and select it.

volume:
        jsr     MaybeCloseWindowAfterOpen

        CALL    FindIconForPath, AX=#src_path_buf
    IF NOT_ZERO
        jsr     SelectIconAndEnsureVisible
    END_IF
        rts
.endproc ; CmdOpenParentImpl
CmdOpenParent := CmdOpenParentImpl::normal
CmdOpenParentThenCloseCurrent := CmdOpenParentImpl::close_current

;;; ============================================================

;;; Assert: Window open

.proc CmdClose
        bit     menu_modified_click_flag
        bmi     CmdCloseAll

        jmp     CloseActiveWindow
.endproc ; CmdClose

;;; ============================================================

.proc CmdCloseAll
repeat:
        lda     active_window_id ; current window
        RTS_IF ZERO              ; nope, done!

        jsr     CloseActiveWindow ; close it...
        jmp     repeat            ; and try again
.endproc ; CmdCloseAll

;;; ============================================================

.proc CmdDiskCopyImpl
        DEFINE_OPEN_PARAMS open_params, str_disk_copy, IO_BUFFER
        DEFINE_READWRITE_PARAMS read_params, DISK_COPY_BOOTSTRAP, kDiskCopyBootstrapLength
        DEFINE_CLOSE_PARAMS close_params

str_disk_copy:
        PASCAL_STRING kPathnameDiskCopy

start:
retry:
        jsr     SetCursorWatch  ; before loading module (undone in module or failure)

        ;; Do this now since we'll use up the space later.
        jsr     SaveWindows

        ;; Smuggle through the selected unit, if any.
        jsr     GetSelectedUnitNum
        sta     DISK_COPY_INITIAL_UNIT_NUM

        MLI_CALL OPEN, open_params
    IF CS
        CALL    ShowAlert, A=#kErrInsertSystemDisk
        cmp     #kAlertResultOK
        beq     retry           ; ok, so try again
        jmp     SetCursorPointer ; after loading module (failure)
    END_IF

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
    IF NOT_ZERO
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
retry:
        CALL    GetWindowPath, A=active_window_id
        jsr     CopyToSrcPath
        CALL    AppendFilenameToSrcPath, AX=#stashed_name
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
        CALL    UpdateActivateAndRefreshWindow, A=active_window_id
        RTS_IF NE

        ;; Select and rename the file
        jmp     TriggerRenameForFileIconWithStashedName

        ;; --------------------------------------------------
error:
        TAIL_CALL ShowAlertOption, X=#AlertButtonOptions::OK

.endproc ; CmdNewFolderImpl
CmdNewFolder    := CmdNewFolderImpl::start

;;; ============================================================
;;; Select and scroll into view an icon in the active window.
;;; Inputs: A,X = name
;;; Output: C=0 on success
;;; Trashes $06

.proc SelectFileIconByName
        CALL    FindIconByName, Y=active_window_id
    IF ZERO                     ; not found
        RETURN  C=1
    END_IF

        jsr     SelectIconAndEnsureVisible
        RETURN  C=0
.endproc ; SelectFileIconByName

;;; ============================================================
;;; Find an icon by name in the given window.
;;; Inputs: Y = window id, A,X = name
;;; Outputs: Z=0, A = icon id (or Z=1, A=0 if not found)
;;; Preserves $06/$08

.proc FindIconByName
        ptr_name := $06

        ;; TODO: Do we need to save pointers?
        jsr     PushPointers
        stax    ptr_name

        lda     cached_window_id
        pha                     ; A = previous `cached_window_id`

        tya
        jsr     CacheWindowIconList

        jsr     FindIconByNameInCachedWindow
        sta     icon

        pla                     ; A = previous `cached_window_id`
        jsr     CacheWindowIconList
        jsr     PopPointers

        icon := *+1
        lda     #SELF_MODIFIED_BYTE
        rts
.endproc ; FindIconByName

;;; ============================================================
;;; Input: $06 has name
;;; Output: A = icon id (and Z=0), or A=0 and Z=1 if not found
;;; Trashes $08

.proc FindIconByNameInCachedWindow
        ptr_icon_name := $08

        ;; Iterate icons
        copy8   #0, index
    DO
        index := *+1
        ldx     #SELF_MODIFIED_BYTE
      IF X = cached_window_icon_count
        ;; Not found
        RETURN  A=#0
      END_IF

        ;; Compare with name from dialog
        lda     cached_window_icon_list,x
      IF A <> trash_icon_num

        jsr     GetIconName
        stax    ptr_icon_name
        jsr     CompareStrings
       IF EQ
        ;; Match!
        ldx     index
        RETURN  A=cached_window_icon_list,x
       END_IF
      END_IF

        inc     index
    WHILE NOT_ZERO              ; always

.endproc ; FindIconByNameInCachedWindow

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
    DO
        sta     digits,y
        dey
    WHILE NOT_ZERO

        ;; While digits, pop from string (X=len) onto digits (Y=len)
        ldx     stashed_name
    DO
        lda     stashed_name,x
        BREAK_IF A NOT_BETWEEN #'0', #'9'
        iny
        sta     digits,y        ; stash digits as we go
        dex
    WHILE NOT_ZERO              ; always (name must start w/ letter)

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
    DO
      DO
        inc     digits+1,x
        lda     digits+1,x
        cmp     #'9'+1
        bne     concatenate     ; done
        copy8   #'0', digits+1,x
        inx
      WHILE X <> digits
        inc     digits
    WHILE X <> #13              ; max of 13 digits
        beq     SpinName        ; restart

        ;; --------------------------------------------------
just_append:
        copy8   #1, digits
        copy8   #'2', digits+1
        FALL_THROUGH_TO concatenate

        ;; --------------------------------------------------
concatenate:
        lda     #14
        sec
        sbc     digits
    IF A < stashed_name
        sta     stashed_name
    END_IF

        ldx     stashed_name
        inx
        copy8   #'.', stashed_name,x
        ldy     digits
    DO
        lda     digits,y
        inx
        sta     stashed_name,x
        dey
    WHILE NOT_ZERO
        stx     stashed_name
        rts
.endproc ; SpinName

;;; ============================================================
;;; Input: Icon number in A.
;;; Assert: Icon in active window.

.proc ScrollIconIntoView
        sta     icon_param
        jsr     CacheActiveWindowIconList

        ;; Grab the icon bounds
        ITK_CALL IconTK::GetIconBounds, icon_param ; inits `tmp_rect`
        jsr     PrepActiveWindowScreenMapping
        CALL    MapCoordsScreenToWindow, AX=#tmp_rect::topleft
        CALL    MapCoordsScreenToWindow, AX=#tmp_rect::bottomright

        viewport := window_grafport+MGTK::GrafPort::maprect

        ;; Get the viewport, and adjust for header
        jsr     ApplyActiveWinfoToWindowGrafport
        add16_8 viewport+MGTK::Rect::y1, #kWindowHeaderHeight - 1

        ;; Padding
        MGTK_CALL MGTK::InflateRect, bbox_pad_tmp_rect

        ;; --------------------------------------------------
        ;; Adjustments

        delta := $06
        dirty := $08

        copy8   #0, dirty
        ldx     #2              ; loop over dimensions
    DO
        ;; Is left/top of icon beyond window? If so, adjust by delta (negative)
        sub16   tmp_rect::topleft,x, viewport+MGTK::Rect::topleft,x, delta
        bmi     adjust

        ;; Is right/bottom of icon beyond window? If so, adjust by delta (positive)
        sub16   tmp_rect::bottomright,x, viewport+MGTK::Rect::bottomright,x, delta
        bmi     done

adjust:
        lda     delta
        ora     delta+1
      IF NOT_ZERO
        inc     dirty
        add16   viewport+MGTK::Rect::topleft,x, delta, viewport+MGTK::Rect::topleft,x
        add16   viewport+MGTK::Rect::bottomright,x, delta, viewport+MGTK::Rect::bottomright,x
      END_IF

done:
        dex                     ; next dimension
        dex
    WHILE POS

        lda     dirty
    IF NOT_ZERO
        ;; Apply the viewport (accounting for header)
        sub16_8 viewport+MGTK::Rect::y1, #kWindowHeaderHeight - 1
        jsr     AssignActiveWindowCliprectAndUpdateCachedIcons
        jsr     ClearAndDrawActiveWindowEntries
        jsr     ScrollUpdate
    END_IF

        rts

.endproc ; ScrollIconIntoView

;;; ============================================================

.proc CmdCheckOrEjectImpl
        ENTRY_POINTS_FOR_BIT7_FLAG eject, check, eject_flag

        ;; Ensure that volumes are selected
        lda     selected_window_id
    IF NOT_ZERO
done:   rts
    END_IF

        ;; And if there's only one, it's not Trash
        jsr     GetSingleSelectedIcon
        cmp     trash_icon_num  ; if it's Trash, skip it
        beq     done

        ldx     selected_icon_count
        stx     selection_count_copy
    DO
        copy8   selected_icon_list-1,x, selection_list_copy-1,x
        dex
    WHILE NOT_ZERO

        ;; If ejecting, clear selection
        bit     eject_flag
    IF NS
        jsr     ClearSelection
    END_IF

        ;; Iterate the recorded volumes
        ldx     #0              ; X = index
    DO
        txa                     ; A = index
        pha

        lda     selection_list_copy,x
      IF A <> trash_icon_num
        ldy     #kCheckDriveShowUnexpectedErrors
        bit     eject_flag
       IF NS
        pha
        jsr     SmartportEject
        pla
        ldy     #kCheckDriveDoNotShowUnexpectedErrors
       END_IF
        jsr     CheckDriveByIconNumber ; A = icon number
      END_IF

        pla                     ; A = index
        tax                     ; X = index
        inx
    WHILE X <> selection_count_copy

        rts

eject_flag:
        .byte   0

selection_count_copy:
        .byte   0

selection_list_copy:
        .res    ::kMaxVolumes

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
        DEFINE_READWRITE_PARAMS read_params, quit_code_addr, quit_code_size
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
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
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
        CLEAR_BIT7_FLAG main::mli_relay_checkevents_flag

        jsr     SaveWindows

        MGTK_CALL MGTK::StopDeskTop

        ;; Switch back to main ZP/LC, preserving return address.
        plax
        sta     ALTZPOFF
        phax

        ;; Exit graphics mode entirely
        bit     ROMIN2

        sta     SET80STORE      ; 80-col firmware expects this
        lda     #0              ; INIT is not used as that briefly
        sta     WNDLFT          ; displays the dirty text page
        sta     WNDTOP
        copy8   #80, WNDWDTH
        copy8   #24, WNDBTM
        jsr     HOME            ; Clear 80-col screen
        sta     TXTSET          ; ... and show it

        CALL    COUT, A=#$95    ; Ctrl-U - disable 80-col firmware
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

;;; Assert: Window is open

.proc CmdViewBy
        jsr     GetActiveWindowViewBy
        sta     current

        ldx     menu_click_params::item_num
        lda     menu_item_to_view_by-1,x

        ;; Is this a change?
        current := *+1
        cmp     #SELF_MODIFIED_BYTE
        RTS_IF EQ

        ;; Update view menu/table
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
        jsr     CacheActiveWindowIconList
        jsr     RemoveAndFreeCachedWindowIcons

;;; Entry point when refreshing window contents
entry3:
        ;; Clear selection if in the window
        lda     selected_window_id
    IF A = active_window_id
        lda     #0
        sta     selected_icon_count
        sta     selected_window_id
    END_IF

        ;; Reset the viewport
        jsr     ResetActiveWindowViewport ; Must precede icon creation

        ;; Create the icons
        jsr     CacheActiveWindowIconList
        jsr     InitWindowIcons
        jsr     AdjustViewportForNewIcons
        jsr     CachedIconsWindowToScreen

        jsr     _RestoreSelection

        jsr     ClearAndDrawActiveWindowEntries
        jmp     ScrollUpdate

;;; --------------------------------------------------
;;; Preserves selection by replacing selected icon ids
;;; with their corresponding record indexes, which remain
;;; valid across view changes.

.proc _PreserveSelection
        lda     selected_window_id
    IF A = active_window_id
        lda     selected_icon_count
      IF NOT_ZERO
        sta     selection_preserved_count

        ;; For each selected icon, replace icon number
        ;; with its corresponding file record number.
       DO
        ldx     selected_icon_count
        CALL    GetIconRecordNum, A=selected_icon_list-1,x
        ldx     selected_icon_count
        sta     selected_icon_list-1,x
        dec     selected_icon_count
       WHILE NOT_ZERO

        copy8   #0, selected_window_id
      END_IF
    END_IF
        rts
.endproc ; _PreserveSelection

;;; --------------------------------------------------
;;; Restores selection after a view change, reversing what
;;; `_PreserveSelection` did.
;;; Uses $800 as a temporary buffer

.proc _RestoreSelection
        lda     selection_preserved_count
    IF NOT_ZERO

        ;; Build mapping of record number to icon
        mapping := $800
        ldx     cached_window_icon_count
        dex
      DO
        txa                     ; X = index
        pha

        lda     cached_window_icon_list-1,x
        pha                     ; A = icon id
        jsr     GetIconRecordNum
        tay                     ; Y = record num
        pla                     ; A = icon id
        sta     mapping,y

        pla
        tax                     ; X = index
        dex
      WHILE POS

        ;; For each record num in the list, find and
        ;; highlight the corresponding icon.
      DO
        ldx     selected_icon_count
        ldy     selected_icon_list,x
        CALL    AddToSelectionList, A=mapping,y
        sta     icon_param
        ITK_CALL IconTK::HighlightIcon, icon_param
        dec     selection_preserved_count
      WHILE NOT_ZERO

        copy8   cached_window_id, selected_window_id
    END_IF

        rts
.endproc ; _RestoreSelection

selection_preserved_count:
        .byte   0
.endproc ; RefreshViewImpl
RefreshViewPreserveSelection := RefreshViewImpl::entry2
RefreshView := RefreshViewImpl::entry3


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
        sbc     cached_window_icon_count
        sta     icon_count

        ITK_CALL IconTK::FreeAll, cached_window_id

        ;; Remove any associations with windows
        ldx     cached_window_icon_count
    IF NOT_ZERO
      DO
        txa                     ; X = index+1
        pha                     ; A = index+1
        CALL    FindWindowIndexForDirIcon, A=cached_window_icon_list-1,x ; X = window id-1 if found
       IF EQ
        copy8   #kWindowToDirIconNone, window_to_dir_icon_table,x
       END_IF
        pla                     ; A = index+1
        tax                     ; X = index+1
        dex
      WHILE NOT_ZERO
    END_IF

        rts
.endproc ; RemoveAndFreeCachedWindowIcons

;;; ============================================================

.proc CmdFormatEraseDiskImpl
        ENTRY_POINTS_FOR_A format, FormatEraseAction::format, erase, FormatEraseAction::erase
        sta     action

        jsr     GetSelectedUnitNum
        sta     unit_num

exec:
        CALL    LoadDynamicRoutine, A=#kDynamicRoutineFormatErase
        RTS_IF NS

        unit_num := *+1
        ldx     #SELF_MODIFIED_BYTE
        action := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     ::FormatEraseOverlay::Exec
        RTS_IF NOT_ZERO

        txa
        TAIL_CALL CheckDriveByUnitNumber, Y=#kCheckDriveDoNotShowUnexpectedErrors ; A = unit number

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

fail:   RETURN  A=#0

found:  lda     DEVLST,x
        and     #UNIT_NUM_MASK
        rts
.endproc ; GetSelectedUnitNum

;;; ============================================================

;;; Input: A = icon id
;;; Output: if found, Z=1 and X = index in DEVLST; Z=0 otherwise

.proc IconToDeviceIndex
        ldx     #kMaxVolumes-1
    DO
        BREAK_IF A = device_to_icon_map,x
        dex
    WHILE POS

        rts
.endproc ; IconToDeviceIndex

;;; ============================================================

;;; Assert: Icon(s) selected

.proc CmdGetInfo
        jsr     DoGetInfo
    IF NS
        ;; Selected items were modified (e.g. locked), so refresh
        lda     selected_window_id
      IF NOT_ZERO               ; windowed (not desktop); refresh needed
        cmp     active_window_id
        jeq     ClearAndDrawActiveWindowEntries ; active - just repaint
        jmp     ActivateWindow  ; inactive - activate, it will repaint
      END_IF
    END_IF

        rts
.endproc ; CmdGetInfo

;;; ============================================================

;;; Assert: File(s) are selected

.proc CmdDeleteSelection
        jsr     DoDeleteSelection
        RTS_IF A = #kOperationCanceled

        SET_BIT7_FLAG validate_windows_flag
        jmp     UpdateActivateAndRefreshSelectedWindow
.endproc ; CmdDeleteSelection

;;; ============================================================

;;; Assert: Single icon selected, and it's not Trash

.proc CmdCopy
        CALL    GetIconName, A=selected_icon_list
        stax    $06
        TAIL_CALL CopyPtr1ToBuf, AX=#clipboard
.endproc ; CmdCopy

.proc CmdPaste
        ;; MacOS 6 behavior - no-op if clipboard is empty
        lda     clipboard
        RTS_IF ZERO

        ldax    #clipboard
        ASSERT_NOT_EQUALS .hibyte(clipboard), 0
        bne     CmdRenameWithDefaultNameGiven
.endproc ; CmdPaste

.proc CmdCut
        jsr     CmdCopy
        FALL_THROUGH_TO CmdClear
.endproc ; CmdCut

.proc CmdClear
        ldax    #str_empty
        ASSERT_NOT_EQUALS .hibyte(str_empty), 0
        beq     CmdRenameWithDefaultNameGiven
.endproc ; CmdClear

;;; ============================================================

.proc TriggerRenameForFileIconWithStashedName
        CALL    SelectFileIconByName, AX=#stashed_name
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
        CALL    ActivateWindow, A=selected_window_id ; no-op if already active, or 0

        ;; If selection is in a window with View > by Name, refresh
        lda     selected_window_id
    IF NOT_ZERO
        jsr     GetSelectionViewBy
      IF A = #DeskTopSettings::kViewByName
        txa                     ; X = window id
        jsr     RefreshViewPreserveSelection

        CALL    ScrollIconIntoView, A=selected_icon_list
      ELSE
        ;; Scrollbars may need adjusting
        jsr     ScrollUpdate
      END_IF
    END_IF

        pla                     ; A = result
    IF NS                       ; N = window renamed
        ;; TODO: Avoid repainting everything
        MGTK_CALL MGTK::RedrawDeskTop
    END_IF

        rts
.endproc ; CmdRename
CmdRenameWithDefaultNameGiven := CmdRename::ep2 ; A,X = name

;;; ============================================================

;;; Assert: Single file icon selected
.proc CmdDuplicate

        ;; --------------------------------------------------
        ;; Determine the name to use

        ;; Start with original name
        CALL    GetIconName, A=selected_icon_list
        stax    $06
        CALL    CopyPtr1ToBuf, AX=#stashed_name

        ;; Construct src path
        jsr     GetSelectionWindow
        jsr     GetWindowPath
        jsr     CopyToSrcPath
        CALL    AppendFilenameToSrcPath, AX=#stashed_name

        ;; Repeat to find a free name
spin:   jsr     GetSelectionWindow
        jsr     GetWindowPath
        jsr     CopyToDstPath
        jsr     SpinName
        CALL    AppendFilenameToDstPath, AX=#stashed_name
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

        RTS_IF A = #kOperationCanceled

        ;; Update name case bits on disk, if possible.
        CALL    CopyToSrcPath, AX=#dst_path_buf
        jsr     ApplyCaseBits   ; applies `stashed_name` to `src_path_buf`

        ;; Update cached used/free for all same-volume windows, and refresh
        CALL    UpdateActivateAndRefreshWindow, A=selected_window_id
        RTS_IF NE

        ;; If operation failed, then just leave the default name.
        result := *+1
        lda     #SELF_MODIFIED_BYTE
        ASSERT_NOT_EQUALS kOperationFailed, 0
        RTS_IF NOT_ZERO

        ;; Select and rename the file
        jmp     TriggerRenameForFileIconWithStashedName

        ;; --------------------------------------------------
error:
        TAIL_CALL ShowAlertOption, X=#AlertButtonOptions::OK

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

        ENTRY_POINTS_FOR_A a_prev, AS_BYTE(-1), a_next, 1

        sta     delta
        jsr     GetKeyboardSelectableIconsSorted
        jmp     common

        ;; ----------------------------------------
        ;; Arrows - next/prev in icon order

        ENTRY_POINTS_FOR_A prev, AS_BYTE(-1), next, 1

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
    DO
        cmp     buffer+1,x
        beq     pick_next_prev
        dex
    WHILE POS

        ;; If not in our list, use a fallback.
fallback:
        ldx     #0
        ldy     delta
    IF NEG
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
        TAIL_CALL SelectIconAndEnsureVisible, A=buffer+1,x

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

        ENTRY_POINTS_FOR_A left, kDirLeft, right, kDirRight, up, kDirUp, down, kDirDown
        sta     dir

        jsr     CacheFocusedWindowIconList

;;; --------------------------------------------------
;;; If a list view, use index-based logic

        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
    IF NS
        lda     dir
        cmp     #kDirUp
        beq     KeyboardHighlightPrev
        bcs     KeyboardHighlightNext
        rts                     ; ignore if left/right
    END_IF

;;; --------------------------------------------------
;;; Identify a starting icon

        lda     selected_icon_count
        jeq     fallback
        cmp     cached_window_icon_count
        jeq     fallback

        copy8   selected_icon_list, icon_param ; use first

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

    DO
        ldx     index
        BREAK_IF X = cached_window_icon_count

        lda     cached_window_icon_list,x
        sta     cur_icon
        sta     icon_param
        jsr     IsIconSelected
        beq     next_icon

        ITK_CALL IconTK::IconInRect, icon_param ; tests against `tmp_rect`
        beq     next_icon

        ;; NOTE: This is the only IconTK call which passes a param block
        ;; on the zero page; it must not collide with IconTK's own use
        ;; of the zero page.
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
    WHILE NOT_ZERO              ; always

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
        ;; Assert: `cached_window_id` = `active_window_id`
        ldy     cached_window_icon_count
        beq     ret

        ;; Default to first (X) / last (Y) icon
        ldx     #0
        dey
        lda     cached_window_id
    IF ZERO
        ;; ...except on desktop, since first is Trash.
        tay                     ; make last (Y) be Trash (0)
        inx                     ; and first (X) be 1st volume icon
      IF X = cached_window_icon_count ; unless there isn't one
        dex
      END_IF
    END_IF
        ror     dir             ; C = 1 if right/down
        lda     cached_window_icon_list,x
    IF CC
        lda     cached_window_icon_list,y
    END_IF

select:
        jmp     SelectIconAndEnsureVisible

.endproc ; KeyboardHighlightSpatialImpl
KeyboardHighlightLeft  := KeyboardHighlightSpatialImpl::left
KeyboardHighlightRight := KeyboardHighlightSpatialImpl::right
KeyboardHighlightDown  := KeyboardHighlightSpatialImpl::down
KeyboardHighlightUp    := KeyboardHighlightSpatialImpl::up

;;; ============================================================
;;; Type Down Selection

;;; Output: Z=1 (always)
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
        RETURN  A=#$FF          ; Z=0 to ignore

file_char:
        ldx     typedown_buf
        RTS_IF X = #kMaxFilenameLength ; Z=1 to consume

        inx
        stx     typedown_buf
        sta     typedown_buf,x

        ;; Collect and sort the potential type-down matches
    IF X = #1
        jsr     GetKeyboardSelectableIconsSorted
    END_IF

        lda     num_filenames
    IF NOT_ZERO

        ;; Find a match.
        jsr     _FindMatch

        ;; Icon to select
        tax
        copy8   table,x, icon   ; index to icon

        ;; Already the selection?
        jsr     GetSingleSelectedIcon
      IF A <> icon
        ;; Update the selection.
        icon := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     SelectIconAndEnsureVisible
      END_IF
    END_IF

        RETURN  A=#0

        num_filenames := $1800
        table := $1801

;;; Find the substring match for `typedown_buf`, or the next
;;; match in lexicographic order, or the last item in the table.
.proc _FindMatch
        ptr     := $06
        len     := $08

        copy8   #0, index

    DO
        index := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     GetNthSelectableIconName
        stax    ptr

        ;; NOTE: Can't use `CompareStrings` as we want to match
        ;; on subset-or-equals.
        ldy     #0
        copy8   (ptr),y, len

cloop:  iny
        lda     (ptr),y
        jsr     ToUpperCase
        cmp     typedown_buf,y
        bcc     next
        beq     :+
        bcs     found
:
        cpy     typedown_buf
        beq     found

        cpy     len
        bcc     cloop

next:   inc     index
        lda     index
    WHILE A <> num_filenames

        dec     index
found:  RETURN  A=index
.endproc ; _FindMatch

.endproc ; CheckTypeDown

;;; Length plus filename
typedown_buf:
        .res    16, 0

;;; ============================================================
;;; Load the entry table for the window to be used for keyboard
;;; selection - usually the active window, unless the desktop
;;; has been clicked. Also clears selection if it isn't in
;;; that window.

.proc CacheFocusedWindowIconList
        lda     focused_window_id
    IF A <> selected_window_id
        pha
        jsr     ClearSelection
        pla
    END_IF
        jmp     CacheWindowIconList

.endproc ; CacheFocusedWindowIconList

;;; ============================================================
;;; Build list of keyboard-selectable icons.
;;; Output: Buffer at $1800 (length prefixed)
;;;         X = number of icons

.proc GetKeyboardSelectableIcons
        buffer := $1800

        jsr     CacheFocusedWindowIconList

        ldx     #0
    DO
        BREAK_IF X = cached_window_icon_count
        copy8   cached_window_icon_list,x, buffer+1,x
        inx
    WHILE NOT_ZERO              ; always

        stx     buffer
        rts
.endproc ; GetKeyboardSelectableIcons

;;; Gather the keyboard-selectable icons into buffer at $1800, and
;;; sort them by name.
;;; Output: Buffer at $1800 (length prefixed)

.proc GetKeyboardSelectableIconsSorted
        buffer := $1800

        jsr     GetKeyboardSelectableIcons

        RTS_IF X < #2

        copy16  #GetNthSelectableIconName, Quicksort_GetPtrProc
        copy16  #CompareStrings, Quicksort_CompareProc
        copy16  #_SwapProc, Quicksort_SwapProc

        txa
        jmp     Quicksort       ; A = count

.proc _SwapProc
        swap8   buffer+1,x, buffer+1,y
        rts
.endproc ; _SwapProc
.endproc ; GetKeyboardSelectableIconsSorted

;;; Assuming selectable icon buffer at $1800 is populated by the
;;; above functions, return ptr to nth icon's name in A,X
;;; Input: A = index
;;; Output: A,X = icon name pointer
.proc GetNthSelectableIconName
        buffer := $1800

        tax
        TAIL_CALL GetIconName, A=buffer+1,x ; A = icon num
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

    DO
        lda     (ptr2),y
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
      IF EQ
        cpy     len2            ; 1<2 or 1=2 ?
        rts
      END_IF

        ;; End of string 2?
        len2 := *+1
        cpy     #SELF_MODIFIED_BYTE
        beq     gt              ; 1>2
        iny
    WHILE NOT_ZERO              ; always

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
        CALL    GetIconWindow, A=icon_param
        sta     selected_window_id
        copy8   #1, selected_icon_count
        copy8   icon_param, selected_icon_list

        ;; If windowed, ensure it is visible
        lda     selected_window_id
    IF NOT_ZERO
        CALL    ScrollIconIntoView, A=selected_icon_list
    END_IF

        ITK_CALL IconTK::DrawIcon, selected_icon_list

ret:    rts
.endproc ; SelectIconAndEnsureVisible

;;; ============================================================

.proc CmdSelectAll
        jsr     ClearSelection

        jsr     CacheFocusedWindowIconList
        lda     cached_window_icon_count
        beq     finish          ; nothing to select!

        ldx     cached_window_icon_count
        dex
    DO
        copy8   cached_window_icon_list,x, selected_icon_list,x
        dex
    WHILE POS

        copy8   cached_window_icon_count, selected_icon_count
        copy8   cached_window_id, selected_window_id

        ;; --------------------------------------------------
        ;; Mark all icons as highlighted

        ITK_CALL IconTK::HighlightAll, cached_window_id

        ;; --------------------------------------------------
        ;; Repaint the icons

        lda     cached_window_id
    IF ZERO
        jsr     InitSetDesktopPort
    ELSE
        jsr     UnsafeSetPortFromWindowIdAndAdjustForEntries ; CHECKED
    END_IF
    IF ZERO                     ; Skip drawing if obscured
        jsr     CachedIconsScreenToWindow
        ITK_CALL IconTK::DrawAll, cached_window_id ; CHECKED
        jsr     CachedIconsWindowToScreen
    END_IF

finish: rts
.endproc ; CmdSelectAll

;;; ============================================================
;;; Cycle Through Windows
;;; Input: A = Key used; '~' is reversed

.proc CmdCycleWindows
        tay

        ;; Need at least two windows to cycle.
        lda     num_open_windows
    IF A >= #2
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
      DO
       IF X = #kMaxDeskTopWindows
        ldx     #0
       END_IF
        lda     window_to_dir_icon_table,x
        bne     found           ; not `kWindowToDirIconFree`
        inx
      WHILE NOT_ZERO            ; always

        ;; --------------------------------------------------
        ;; Search downwards through window-icon map to find next.
        ;; ID is 1-based, table is 0-based, start with decrements.
reverse:
        ldx     active_window_id
        dex
      DO
        dex
       IF NEG
        ldx     #kMaxDeskTopWindows-1
       END_IF
        lda     window_to_dir_icon_table,x
      WHILE ZERO                ; is `kWindowToDirIconFree`

        FALL_THROUGH_TO found

found:  inx
        txa
        jmp     ActivateWindow
    END_IF
        rts
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
;;; Centralized logic for scrolling directory windows

.scope ScrollManager

;;; Terminology:
;;; * "offset" - When the icons would fit entirely within the viewport
;;;   (for a given dimension) but the viewport is offset so a scrollbar
;;;   must still be shown.


;;; Effective viewport  ("Effective" discounts the window header.)
viewport := window_grafport+MGTK::GrafPort::maprect

;;; Local variables on ZP
PARAM_BLOCK, $50
;;; `ubox` is a union of the effective viewport and icon bounding box
ubox    .tag    MGTK::Rect

;;; Effective dimensions of the viewport
.union
viewport_size   .word   2
.struct
width   .word
height  .word
.endstruct
.endunion

;;; Bounding box dimensions
.union
bbox_size       .word   2
.struct
bbox_w  .word
bbox_h  .word
.endstruct
.endunion

;;; Initial effective viewport top/left
old     .tag    MGTK::Point

;;; Increment/decrement sizes (depends on view type)
tick_h  .byte
tick_v  .byte

tmpw    .word
END_PARAM_BLOCK

;;; --------------------------------------------------
;;; Compute the necessary data for scroll operations:
;;; * `viewport` - effective viewport of active window
;;; * `ubox` - union of icon bounding box and viewport
;;; * `tick_h` and `tick_v` sizes (based on view type)
;;; * `width` and `height` of the effective viewport
;;; * `bbox_w` and `bbox_h` - size of icon bounding box
;;; * `old` - initial top/left of viewport (to detect changes)

_Preamble:
        jsr     CacheActiveWindowIconList

        jsr     GetActiveWindowViewBy ; N=0 is icon view, N=1 is list view
    IF NC
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

        ldx     #2              ; loop over dimensions
    DO
        sub16   viewport+MGTK::Rect::bottomright,x, viewport+MGTK::Rect::topleft,x, viewport_size,x
        dex                     ; next dimension
        dex
    WHILE POS

        lda     cached_window_icon_count
    IF ZERO
        ;; If no icons in window, the viewport is fine.
        COPY_STRUCT MGTK::Rect, viewport, ubox
        rts
    END_IF

        ;; Make `ubox` bound both viewport and icons; needed to ensure
        ;; offset cases are handled.

        jsr     ComputeIconsBBox
        CALL    PrepWindowScreenMapping, A=cached_window_id

        CALL    MapCoordsScreenToWindow, AX=#iconbb_rect+MGTK::Rect::topleft
        CALL    MapCoordsScreenToWindow, AX=#iconbb_rect+MGTK::Rect::bottomright

        ldx     #2              ; loop over dimensions
    DO
        ;; stash bbox dimensions before union below
        sub16   iconbb_rect+MGTK::Rect::bottomright,x, iconbb_rect+MGTK::Rect::topleft,x, bbox_size,x
        dex                     ; next dimension
        dex
    WHILE POS

        MGTK_CALL MGTK::UnionRects, unionrects_viewport_iconbb
        COPY_STRUCT MGTK::Rect, iconbb_rect, ubox
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
        CALL    _Page_hi, X=#MGTK::Point::xcoord
        jmp     _Clamp_x2
.endproc ; PageRight

.proc PageDown
        jsr     _Preamble
        CALL    _Page_hi, X=#MGTK::Point::ycoord
        jmp     _Clamp_y2
.endproc ; PageDown

.proc _Page_hi
        add16 viewport+MGTK::Rect::bottomright,x, viewport_size,x, viewport+MGTK::Rect::bottomright,x
        rts
.endproc ; _Page_hi

;;; --------------------------------------------------
;;; When page decrement area is clicked:
;;;   1. vp.lo -= size
;;;   2. goto _Clamp_lo

.proc PageLeft
        jsr     _Preamble
        CALL    _Page_lo, X=#MGTK::Point::xcoord
        jmp     _Clamp_x1
.endproc ; PageLeft

.proc PageUp
        jsr     _Preamble
        CALL    _Page_lo, X=#MGTK::Point::ycoord
        jmp     _Clamp_y1
.endproc ; PageUp

.proc _Page_lo
        sub16   viewport+MGTK::Rect::topleft,x, viewport_size,x, viewport+MGTK::Rect::topleft,x
        rts
.endproc ; _Page_lo

;;; --------------------------------------------------
;;; When thumb is moved by user:
;;;   1. vp.lo = ubox.lo + (ubox.hi - ubox.lo - size) * (newpos / thumb.max)
;;;   2. vp.hi = vp.lo + size
;;;   3. goto update

.proc TrackHThumb
        jsr     _Preamble
        CALL    _TrackMulDiv, X=#MGTK::Point::xcoord
        jmp     _MaybeUpdateHThumb
.endproc ; TrackHThumb

.proc TrackVThumb
        jsr     _Preamble
        CALL    _TrackMulDiv, X=#MGTK::Point::ycoord
        jmp     _MaybeUpdateVThumb
.endproc ; TrackVThumb

.proc _TrackMulDiv
        sub16   ubox+MGTK::Rect::bottomright,x, ubox+MGTK::Rect::topleft,x, tmpw
        sub16   tmpw, viewport_size,x, track_muldiv_params::number
        copy8   trackthumb_params::thumbpos, track_muldiv_params::numerator
        txa
        pha
        MGTK_CALL MGTK::MulDiv, track_muldiv_params
        pla
        tax
        add16   track_muldiv_params::result, ubox+MGTK::Rect::topleft,x, viewport+MGTK::Rect::topleft,x
        add16   viewport+MGTK::Rect::topleft,x, viewport_size,x, viewport+MGTK::Rect::bottomright,x
        rts
.endproc ; _TrackMulDiv

;;; --------------------------------------------------
;;; _Clamp_hi:
;;;   1. if vp.hi > ubox.hi: vp.hi = ubox.hi
;;;   2. vp.lo = vp.hi - size
;;;   3. goto update

.proc _Clamp_hi
        scmp16  viewport+MGTK::Rect::bottomright,x, ubox+MGTK::Rect::bottomright,x
    IF POS
        copy16  ubox+MGTK::Rect::bottomright,x, viewport+MGTK::Rect::bottomright,x
    END_IF
        sub16   viewport+MGTK::Rect::bottomright,x, viewport_size,x, viewport+MGTK::Rect::topleft,x
        rts
.endproc ; _Clamp_hi

.proc _Clamp_x2
        CALL    _Clamp_hi, X=#MGTK::Point::xcoord
        jmp     _MaybeUpdateHThumb
.endproc ; _Clamp_x2

.proc _Clamp_y2
        CALL    _Clamp_hi, X=#MGTK::Point::ycoord
        jmp     _MaybeUpdateVThumb
.endproc ; _Clamp_y2

;;; --------------------------------------------------
;;; _Clamp_lo:
;;;   1. if vp.lo < ubox.lo: vp.lo = ubox.lo
;;;   2. vp.hi = vp.lo + size
;;;   3. goto update

.proc _Clamp_lo
        scmp16  viewport+MGTK::Rect::topleft,x, ubox+MGTK::Rect::topleft,x
    IF NEG
        copy16  ubox+MGTK::Rect::topleft,x, viewport+MGTK::Rect::topleft,x
    END_IF
        add16   viewport+MGTK::Rect::topleft,x, viewport_size,x, viewport+MGTK::Rect::bottomright,x
        rts
.endproc ; _Clamp_lo

.proc _Clamp_x1
        CALL    _Clamp_lo, X=#MGTK::Point::xcoord
        jmp     _MaybeUpdateHThumb
.endproc ; _Clamp_x1

.proc _Clamp_y1
        CALL    _Clamp_lo, X=#MGTK::Point::ycoord
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
    IF NE
        jsr     _SetHThumbFromViewport
        jsr     _UpdateViewport
        jsr     ClearAndDrawActiveWindowEntries

        ;; Handle offset case - may be able to deactivate scrollbar now
        cmp16   width, bbox_w
      IF GE
        jsr     _Preamble       ; Need updated `ubox` and `maprect`
        CALL    _CheckDeactivate, X=#MGTK::Point::xcoord
       IF POS
        CALL    _ActivateCtl, X=#MGTK::Ctl::horizontal_scroll_bar, A=#MGTK::activatectl_deactivate
       END_IF
      END_IF
    END_IF
        rts
.endproc ; _MaybeUpdateHThumb

.proc _MaybeUpdateVThumb
        ecmp16  viewport+MGTK::Rect::y1, old+MGTK::Point::ycoord
    IF NE
        jsr     _SetVThumbFromViewport
        jsr     _UpdateViewport
        jsr     ClearAndDrawActiveWindowEntries

        ;; Handle offset case - may be able to deactivate scrollbar now
        cmp16   height, bbox_h
      IF GE
        jsr     _Preamble       ; Need updated `ubox` and `maprect`
        CALL    _CheckDeactivate, X=#MGTK::Point::ycoord
       IF POS
        CALL    _ActivateCtl, X=#MGTK::Ctl::vertical_scroll_bar, A=#MGTK::activatectl_deactivate
       END_IF
      END_IF
    END_IF
        rts
.endproc ; _MaybeUpdateVThumb

.proc _CheckDeactivate
        scmp16  ubox+MGTK::Rect::topleft,x, viewport+MGTK::Rect::topleft,x
    IF POS
        scmp16  viewport+MGTK::Rect::bottomright,x, ubox+MGTK::Rect::bottomright,x
    END_IF
        rts
.endproc ; _CheckDeactivate

;;; Set hthumb position relative to `maprect` and `ubox`.
.proc _SetHThumbFromViewport
        CALL    _CalcThumbFromViewport, X=#MGTK::Point::xcoord
        TAIL_CALL _UpdateThumb, A=setthumb_muldiv_params::result, X=#MGTK::Ctl::horizontal_scroll_bar
.endproc ; _SetHThumbFromViewport

;;; Set vthumb position relative to `maprect` and `ubox`.
.proc _SetVThumbFromViewport
        CALL    _CalcThumbFromViewport, X=#MGTK::Point::ycoord
        TAIL_CALL _UpdateThumb, A=setthumb_muldiv_params::result, X=#MGTK::Ctl::vertical_scroll_bar
.endproc ; _SetVThumbFromViewport

.proc _CalcThumbFromViewport
        sub16   viewport+MGTK::Rect::topleft,x, ubox+MGTK::Rect::topleft,x, setthumb_muldiv_params::number
        sub16   ubox+MGTK::Rect::bottomright,x, ubox+MGTK::Rect::topleft,x, tmpw
        sub16   tmpw, viewport_size,x, setthumb_muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, setthumb_muldiv_params
        rts
.endproc ; _CalcThumbFromViewport

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
        CALL    _ActivateCtl, X=#MGTK::Ctl::horizontal_scroll_bar, A=#MGTK::activatectl_deactivate
        beq     check_vscroll   ; always

activate_hscroll:
        ;; activate horizontal scrollbar
        CALL    _ActivateCtl, X=#MGTK::Ctl::horizontal_scroll_bar, A=#MGTK::activatectl_activate

        jsr     _SetHThumbFromViewport
        FALL_THROUGH_TO check_vscroll

        ;; --------------------------------------------------

check_vscroll:
        scmp16  ubox+MGTK::Rect::y1, viewport+MGTK::Rect::y1
        bmi     activate_vscroll
        scmp16  viewport+MGTK::Rect::y2, ubox+MGTK::Rect::y2
        bmi     activate_vscroll

        ;; deactivate vertical scrollbar
        TAIL_CALL _ActivateCtl, X=#MGTK::Ctl::vertical_scroll_bar, A=#MGTK::activatectl_deactivate

activate_vscroll:
        ;; activate vertical scrollbar
        CALL    _ActivateCtl, X=#MGTK::Ctl::vertical_scroll_bar, A=#MGTK::activatectl_activate
        jmp     _SetVThumbFromViewport
.endproc ; ActivateCtlsSetThumbs

;;; --------------------------------------------------
;;; Inputs: A=activate/deactivate, X=which_ctl
;;; Output: Z=1
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

.proc CmdCheckAllDrives
        ;; Enumerate DEVLST in reverse order (most important volumes first)
        ldx     DEVCNT          ; X = index
    DO
        txa                     ; A = index
        pha

        CALL    CheckDriveByIndex, Y=#kCheckDriveShowUnexpectedErrors ; A = DEVLST index

        pla                     ; A = index
        tax                     ; X = index
        dex
    WHILE POS
        rts
.endproc ; CmdCheckAllDrives

;;; ============================================================

pending_alert:
        .byte   0

;;; ============================================================
;;; Check > [drive] command - obsolete, but core still used
;;; following Format (etc)
;;;

kCheckDriveDoNotShowUnexpectedErrors = $00
kCheckDriveShowUnexpectedErrors = $80

.proc CheckDriveImpl

;;; --------------------------------------------------
;;; After a Format/Erase action
;;; Input: A = unit number, Y = show unexpected errors flag

by_unit_number:
        ;; Map unit number to index in DEVLST
        sta     compare
        ldx     DEVCNT
    DO
        lda     DEVLST,x
        and     #UNIT_NUM_MASK
        compare := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     common
        dex
    WHILE POS                   ; always

;;; --------------------------------------------------
;;; After an Open/Eject/Rename action
;;; Input: A = icon id, Y = show unexpected errors flag

by_icon_number:
        ;; Map icon number to index in DEVLST
        jsr     IconToDeviceIndex
        RTS_IF NOT_ZERO         ; Not found - not a volume icon
        beq     common          ; always

;;; --------------------------------------------------
;;; After polling drives
;;; Input: A = DEVLST index, Y = show unexpected errors flag

by_index:
        tax                     ; X = index
        FALL_THROUGH_TO common

;;; --------------------------------------------------

common:
        stx     devlst_index
        sty     show_unexpected_errors_flag

        ;; --------------------------------------------------
        ;; Close any associated windows

        lda     device_to_icon_map,x
    IF NOT_ZERO

        ;; A = icon number
        jsr     GetIconName
        stax    $06

        path_buf := $1F00

        ;; Copy volume path to $1F00
        CALL    CopyPtr1ToBuf, AX=#path_buf+1

        ;; Find all windows with path as prefix, and close them.
        sta     path_buf
        inc     path_buf
        copy8   #'/', path_buf+1

close_loop:
        ;; NOTE: This is called within loop because the list
        ;; (`found_windows_count` / `found_windows_list`) is trashed
        ;; during close when animating window.
        CALL    FindWindowsForPrefix, AX=#path_buf
        ldx     found_windows_count
      IF NOT_ZERO
        CALL    CloseSpecifiedWindow, A=found_windows_list-1,x
        jmp     close_loop
      END_IF
    END_IF

        ;; --------------------------------------------------
        ;; If there was an existing icon, destroy it

        jsr     ClearSelection

        jsr     CacheDesktopIconList
        ldy     devlst_index
        copy8   device_to_icon_map,y, icon_param
    IF NOT_ZERO
        jsr     RemoveIconFromWindow
        dec     icon_count
        CALL    FreeDesktopIconPosition, A=icon_param
        ITK_CALL IconTK::EraseIcon, icon_param
        ITK_CALL IconTK::FreeIcon, icon_param
        jsr     StoreCachedWindowIconList
    END_IF

        ;; --------------------------------------------------
        ;; Try to create a new volume icon

        ldy     devlst_index
        lda     DEVLST,y
        ;; NOTE: Not masked with `UNIT_NUM_MASK`, for `CreateVolumeIcon`.
        jsr     CreateVolumeIcon ; A = unmasked unit num, Y = device index
    IF ZERO
        ldx     cached_window_icon_count
        copy8   cached_window_icon_list-1,x, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param
        jmp     StoreCachedWindowIconList
    END_IF

        ;; --------------------------------------------------
        ;; Error cases:

        ;; Always show this error
        cmp     #ERR_DUPLICATE_VOLUME
        beq     show_error

        ;; Per Technical Note: ProDOS #21
        ;; https://prodos8.com/docs/technote/21/
        ;; `ERR_DEVICE_OFFLINE`: "... there is no disk in the drive."
        ;; ... so ignore
        cmp     #ERR_DEVICE_OFFLINE
        beq     ret

        ;; `ERR_IO_ERROR`: "... the disk in the drive is either
        ;; damaged or blank (not formatted)." - but this seems to be
        ;; returned for empty Disk II and SmartPort devices, so we
        ;; ignore it.
        cmp     #ERR_IO_ERROR
        beq     ret

    IF A = #ERR_NOT_PRODOS_VOLUME
        CALL    ShowAlertParams, Y=#AlertButtonOptions::OKCancel, AX=#aux::str_alert_unreadable_format
        cmp     #kAlertResultCancel
        beq     ret

        ldy     devlst_index
        lda     DEVLST,y
        and     #UNIT_NUM_MASK
        jmp     FormatUnitNum
    END_IF

        ;; Show an alert for other errors only if requested by the
        ;; caller. The history here is that an error should only be
        ;; shown if there is an unexpected type of error (i.e. not one
        ;; of the above) when polling or as explicit command
        ;; (originally Check > Slot S drive D).
        bit     show_unexpected_errors_flag
        bmi     show_error

ret:    rts

        ;; --------------------------------------------------

show_error:
        jmp     ShowAlert

        ;; --------------------------------------------------

devlst_index:
        .byte   0
show_unexpected_errors_flag:
        .byte   0

.endproc ; CheckDriveImpl

        CheckDriveByIndex := CheckDriveImpl::by_index
        CheckDriveByUnitNumber := CheckDriveImpl::by_unit_number
        CheckDriveByIconNumber := CheckDriveImpl::by_icon_number

;;; ============================================================

.proc CmdStartupItem
        ldx     menu_click_params::item_num
        lda     startup_slot_table-1,x
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
        DEFINE_READWRITE_PARAMS write_params, link_struct, 0
        DEFINE_CLOSE_PARAMS close_params

        ;; --------------------------------------------------
        ;; Stash target directory name

;;; Entry point where selection's window is used as target path
target_selection:
        jsr     GetSelectionWindow
        jsr     GetWindowPath
        jsr     CopyToOperationDstPath

;;; Entry point where caller sets `operation_dst_path`
arbitrary_target:

        ;; --------------------------------------------------
        ;; Prep struct for writing

        CALL    GetIconPath, A=selected_icon_list ; `operation_src_path` set to path; A=0 on success
        jne     ShowAlert       ; too long

        ldx     #kHeaderSize-1
    DO
        copy8   header,x, link_struct,x
        dex
    WHILE POS

        COPY_STRING operation_src_path, link_struct::path
        lda     link_struct::path
        clc
        adc     #link_struct::path-link_struct+1
        sta     write_params::request_count

        ;; --------------------------------------------------
        ;; Determine the name to use

        ;; Start with original name
        CALL    GetIconName, A=selected_icon_list
        stax    $06
        CALL    CopyPtr1ToBuf, AX=#stashed_name

        ;; Append ".alias"
        lda     stashed_name
        clc
        adc     #.strlen(kAliasSuffix)
    IF A >= #kMaxFilenameLength+1
        lda     #kMaxFilenameLength
    END_IF
        tax
        sta     stashed_name
        ldy     #.strlen(kAliasSuffix)-1
    DO
        copy8   suffix,y, stashed_name,x
        dex
        dey
    WHILE POS

        ;; Repeat to find a free name
retry:  CALL    CopyToDstPath, AX=#operation_dst_path
        CALL    AppendFilenameToDstPath, AX=#stashed_name
        jsr     GetDstFileInfo
    IF CS
        cmp     #ERR_FILE_NOT_FOUND
        beq     create
        bne     err
    END_IF
        jsr     SpinName
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
        CALL    CopyToSrcPath, AX=#dst_path_buf
        jsr     ApplyCaseBits ; applies `stashed_name` to `src_path_buf`

        ;; --------------------------------------------------
        ;; Update cached used/free for all same-volume windows, and refresh

        CALL    UpdateUsedFreeViaPath, AX=#dst_path_buf

        jsr     ShowFileWithPath
        RTS_IF CS

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
        jsr     GetIconPath     ; `operation_src_path` set to path, A=0 on success
        bne     alert           ; too long
        CALL    CopyToSrcPath, AX=#operation_src_path
        jsr     ReadLinkFile
        RTS_IF CS

        ;; File or volume?
        CALL    FindLastPathSegment, AX=#src_path_buf ; point Y at last '/'
        cpy     src_path_buf
        jne     ShowFileWithPath

        ;; Volume
        CALL    FindIconForPath, AX=#src_path_buf
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
        pha
        ITK_CALL IconTK::HighlightIcon, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param

        pla
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
    DO
        dex
    WHILE A <> selected_icon_list,x

        ;; Move everything down
    DO
        copy8   selected_icon_list+1,x, selected_icon_list,x
        inx
    WHILE X <> selected_icon_count

        dec     selected_icon_count
    IF ZERO
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
        pha                     ; A = window id
        jsr     _TryActivateAndRefreshWindow
        pla                     ; A = window id

        bit     exception_flag
    IF NC
        RETURN  A=#0
    END_IF

        jsr     CloseSpecifiedWindow ; A = window id
        RETURN  A=#$FF

.proc _TryActivateAndRefreshWindow
        SET_BIT7_FLAG exception_flag ; set bit7, preserving A
        tsx
        stx     saved_stack
        jsr     ActivateAndRefreshWindow
        CLEAR_BIT7_FLAG exception_flag ; clear bit7, preserving A
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
    IF A <> active_window_id
        sta     active_window_id
        sta     focused_window_id
        MGTK_CALL MGTK::SelectWindow, active_window_id
    END_IF

        ;; Clear background
        CALL    UnsafeSetPortFromWindowId, A=active_window_id ; CHECKED
        pha                     ; A = obscured?
    IF ZERO                     ; skip if obscured
        jsr     EraseWindowBackground
    END_IF

        ;; Remove old FileRecords
        lda     active_window_id
        pha                     ; A = `active_window_id`
        jsr     RemoveWindowFileRecords

        ;; Remove old icons
        jsr     CacheActiveWindowIconList
        jsr     RemoveAndFreeCachedWindowIcons
        jsr     ClearActiveWindowEntryCount

        ;; Copy window path to `src_path_buf`
        pla                     ; A = `active_window_id`
        pha                     ; A = `active_window_id`
        jsr     GetWindowPath
        jsr     CopyToSrcPath

        ;; Load new FileRecords
        pla                     ; A = `active_window_id`
        jsr     CreateFileRecordsForRefreshedWindow

        ;; Draw header
        jsr     UpdateWindowUsedFreeDisplayValues
        pla                     ; A = obscured?
    IF ZERO                     ; skip if obscured
        jsr     CacheActiveWindowIconList
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
        jsr     CacheWindowIconList

        lda     window_id
    IF NOT_ZERO
        ;; Map initial event coordinates
        jsr     PrepActiveWindowScreenMapping
        jsr     _CoordsScreenToWindow
    END_IF

        ;; Stash initial coords
        COPY_STRUCT MGTK::Point, event_params::coords, initial_pos

        ;; Is this actually a drag?
        jsr     PeekEvent
        lda     event_params::kind
    IF A <> #MGTK::EventKind::drag
        ;; No, just a click; optionally clear selection
        jsr     ExtendSelectionModifierDown
        jpl     ClearSelection  ; don't clear if mis-clicking
        rts
    END_IF

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
    IF NOT_ZERO
        jsr     UnsafeSetPortFromWindowIdAndAdjustForEntries ; ASSERT: not obscured
    ELSE
        jsr     InitSetDesktopPort
    END_IF

        ;; Any `ClearSelection` calls above may modify `tmp_rect`
        ldx     #.sizeof(MGTK::Point)-1
    DO
        lda     initial_pos,x
        sta     tmp_rect::topleft,x
        sta     tmp_rect::bottomright,x
        dex
    WHILE POS

        jsr     FrameTmpRect

        ;; --------------------------------------------------
        ;; Event loop
event_loop:

        ;; Done the drag?
        jsr     PeekEvent
        lda     event_params::kind
    IF A <> #MGTK::EventKind::drag

        jsr     FrameTmpRect

        jsr     CachedIconsScreenToWindow

        ;; Process all icons in window
        ldx     #0              ; X = index
      DO
       IF X = cached_window_icon_count
        jmp     CachedIconsWindowToScreen
       END_IF

        txa
        pha                     ; A = index

        ;; Check if icon should be selected
        copy8   cached_window_icon_list,x, icon_param
        ITK_CALL IconTK::IconInRect, icon_param
       IF NOT ZERO

        ;; Already selected?
        CALL    IsIconSelected, A=icon_param
        IF NE
        ;; Highlight and add to selection
        ;; NOTE: Does not use `AddIconToSelection` because we perform
        ;; a more optimized drawing below.
        ITK_CALL IconTK::HighlightIcon, icon_param
        CALL    AddToSelectionList, A=icon_param
        copy8   window_id, selected_window_id
        ELSE
        ;; Unhighlight and remove from selection
        ITK_CALL IconTK::UnhighlightIcon, icon_param
        CALL    RemoveFromSelectionList, A=icon_param
        END_IF

        lda     window_id
        IF ZERO
        ITK_CALL IconTK::DrawIcon, icon_param
        ELSE
        ITK_CALL IconTK::DrawIconRaw, icon_param ; CHECKED (drag select)
        END_IF
       ELSE
        MGTK_CALL MGTK::CheckEvents
       END_IF

        pla                     ; A = index
        tax                     ; X = index
        inx
      WHILE NOT_ZERO            ; always
    END_IF

        ;; --------------------------------------------------
        ;; Check movement threshold
        lda     window_id
    IF NOT_ZERO
        jsr     _CoordsScreenToWindow
    END_IF

        ldx     #2              ; loop over dimensions
    DO
        sub16   event_params::coords,x, last_pos,x, delta,x

        lda     delta+1,x
      IF NEG
        lda     delta,x         ; negate
        eor     #$FF
        sta     delta,x
        inc     delta,x
      END_IF

        ;; TODO: Experiment with making this lower.
        kDragBoundThreshold = 5

        lda     delta,x
        cmp     #kDragBoundThreshold
        bcs     beyond

        dex                     ; next dimension
        dex
    WHILE POS
        jmp     event_loop

        ;; Beyond threshold; erase rect
beyond:
        jsr     FrameTmpRect

        COPY_STRUCT event_params::coords, last_pos

        ;; --------------------------------------------------
        ;; Figure out coords for rect's left/top/bottom/right

        ldx     #2              ; loop over dimensions
    DO
        scmp16  event_params::coords,x, initial_pos,x
      IF NEG
        copy16  event_params::coords,x, tmp_rect::topleft,x
        copy16  initial_pos,x, tmp_rect::bottomright,x
      ELSE
        copy16  initial_pos,x, tmp_rect::topleft,x
        copy16  event_params::coords,x, tmp_rect::bottomright,x
      END_IF
        dex                     ; next dimension
        dex
    WHILE POS

        jsr     FrameTmpRect
        jmp     event_loop

.proc _CoordsScreenToWindow
        TAIL_CALL MapCoordsScreenToWindow, AX=#event_params::coords
.endproc ; _CoordsScreenToWindow
.endproc ; DragSelect

;;; ============================================================
;;; Initiate keyboard-based window moving

.proc CmdMove
        MGTK_CALL MGTK::KeyboardMouse
        FALL_THROUGH_TO DoWindowDrag
.endproc ; CmdMove

;;; ============================================================

.proc DoWindowDrag
        copy8   active_window_id, dragwindow_params::window_id

        jsr     CacheActiveWindowIconList
        jsr     CachedIconsScreenToWindow

        MGTK_CALL MGTK::DragWindow, dragwindow_params
        ;; `dragwindow_params::moved` is not checked; harmless if it didn't.

        jmp     CachedIconsWindowToScreen
.endproc ; DoWindowDrag

;;; ============================================================
;;; Initiate keyboard-based resizing

.proc CmdResize
        MGTK_CALL MGTK::KeyboardMouse
        FALL_THROUGH_TO DoWindowResize
.endproc ; CmdResize

;;; ============================================================

.proc DoWindowResize
        copy8   active_window_id, growwindow_params::window_id
        MGTK_CALL MGTK::GrowWindow, growwindow_params
        jmp     ScrollUpdate
.endproc ; DoWindowResize

;;; ============================================================

.proc HandleCloseClick
        lda     active_window_id
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        RTS_IF ZERO

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
        jsr     CacheWindowIconList

        ;; --------------------------------------------------
        ;; Do we have a parent icon for this window?

        lda     #0
        ldx     cached_window_id
        ldy     window_to_dir_icon_table-1,x
    IF NC                       ; is not `kWindowToDirIconNone`
        tya
    END_IF
        sta     icon

        ;; --------------------------------------------------
        ;; Prep for animation

        CALL    GetWindowPath, A=cached_window_id
        jsr     IconToAnimate
        pha                     ; A = animation icon
        lda     cached_window_id
        pha                     ; A = animation window

        ;; --------------------------------------------------
        ;; Close and tidy up

        jsr     ClearSelection

        jsr     RemoveAndFreeCachedWindowIcons
        jsr     ClearAndStoreCachedWindowIconList
        CALL    RemoveWindowFileRecords, A=cached_window_id

        MGTK_CALL MGTK::CloseWindow, cached_window_id
        dec     num_open_windows

        ldx     cached_window_id
        ASSERT_EQUALS ::kWindowToDirIconFree, 0
        ASSERT_EQUALS DeskTopSettings::kViewByIcon, 0
        copy8   #0, window_to_dir_icon_table-1,x ; `kWindowToDirIconFree`

        ;; Record the new active window
        MGTK_CALL MGTK::FrontWindow, active_window_id
        copy8   active_window_id, focused_window_id

        jsr     ClearUpdates    ; following CloseWindow above

        ;; --------------------------------------------------
        ;; Animate closing

        pla                     ; A = animation window
        tax
        pla                     ; A = animation icon
        pha
        CALL    AnimateWindowClose ; A = icon id, X = window id

        ;; --------------------------------------------------
        ;; Un-dim the parent icon (if any)

        icon := *+1
        lda     #SELF_MODIFIED_BYTE
    IF NOT_ZERO
        jsr     MarkIconNotDimmedNoDraw
        ;; Assert: `icon` == `anim_icon`, and will get redrawn next.
    END_IF

        ;; --------------------------------------------------
        ;; Select the ancestor icon that was animated into

        pla                     ; A = animation icon
        jmp     SelectIcon

.endproc ; CloseSpecifiedWindow

;;; ============================================================
;;; Check windows and close any where the backing volume/file no
;;; longer exists.

;;; Set bit7 to run a validation pass and close as needed.
validate_windows_flag:
        .byte   0

.proc ValidateWindows
        bit     validate_windows_flag
    IF NS
        CLEAR_BIT7_FLAG validate_windows_flag
        copy8   #kMaxDeskTopWindows, window_id

      DO
        ;; Check if the window is in use
        window_id := *+1
        ldx     #SELF_MODIFIED_BYTE
        lda     window_to_dir_icon_table-1,x
       IF NOT_ZERO              ; isn't `kWindowToDirIconFree`
        ;; Get and copy its path somewhere useful
        txa
        jsr     GetWindowPath
        jsr     CopyToSrcPath

        ;; See if it exists
        jsr     GetSrcFileInfo
        IF CS
        ;; Nope - close the window
        CALL    CloseSpecifiedWindow, A=window_id
        END_IF
       END_IF

        dec     window_id
      WHILE NOT_ZERO
    END_IF

        rts
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
    DO
        copy8   (ptr),y, window_grafport,y
        dey
    WHILE POS
        rts
.endproc ; ApplyWinfoToWindowGrafport

;;; NOTE: Does not update icon positions, so only use in empty windows.
.proc ResetActiveWindowViewport
        jsr     ApplyActiveWinfoToWindowGrafport
        ldx     #2              ; loop over dimensions
    DO
        viewport := window_grafport+MGTK::GrafPort::maprect

        sub16   viewport+MGTK::Rect::bottomright,x, viewport+MGTK::Rect::topleft,x, viewport+MGTK::Rect::bottomright,x
        copy16  #0, viewport+MGTK::Rect::topleft,x
        dex                     ; next dimension
        dex
    WHILE POS
        FALL_THROUGH_TO AssignActiveWindowCliprect
.endproc ; ResetActiveWindowViewport

.proc AssignActiveWindowCliprect
        ptr := $6

        CALL    GetWindowPtr, A=active_window_id
        stax    ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
    DO
        copy8   window_grafport+MGTK::GrafPort::maprect,x, (ptr),y
        dey
        dex
    WHILE POS
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
    IF A <> #1
        RETURN  A=#0
    END_IF
        RETURN  A=selected_icon_list
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
    IF EQ
        inx
        txa
        jmp     ActivateWindow  ; no-op if already active
    END_IF

        ;; Compute the path, if it fits
        CALL    GetIconPath, A=icon_param ; `operation_src_path` set to path, A=0 on success
    IF NOT_ZERO
        jsr     ShowAlert       ; A has error if `GetIconPath` fails
        ldx     saved_stack
        txs
        rts
    END_IF
        CALL    CopyToSrcPath, AX=#operation_src_path ; set `src_path_buf`
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
        CALL    FindIconForPath, AX=#src_path_buf
    IF NOT_ZERO
        sta     icon_param
    END_IF

        FALL_THROUGH_TO no_win

        ;; --------------------------------------------------
        ;; No window - need to open one.

        ;; `src_path_buf` has path
        ;; `icon_param` has icon (or `kWindowToDirIconNone`)

no_win:
        ;; Is there a free window?
        lda     num_open_windows
    IF A >= #kMaxDeskTopWindows
        ;; Nope, show error.
        CALL    ShowAlertParams, Y=#AlertButtonOptions::OK, AX=#aux::str_warning_too_many_windows
        ldx     saved_stack
        txs
        rts
    END_IF

        ;; Search window-icon map to find an unused window.
        ldx     #0
    DO
        lda     window_to_dir_icon_table,x
        BREAK_IF ZERO           ; is `kWindowToDirIconFree`
        inx
    WHILE NOT_ZERO              ; always

        ;; Map the window to its source icon
        copy8   icon_param, window_to_dir_icon_table,x ; possibly `kWindowToDirIconNone` if opening via path
        inx                     ; 0-based to 1-based

        txa
        jsr     CacheWindowIconList ; sets `cached_window_id`

        inc     num_open_windows

        ;; Initial "View By" setting
        CALL    ReadSetting, X=#DeskTopSettings::default_view
        ldx     cached_window_id
        sta     win_view_by_table-1,x ; default

        lda     icon_param
    IF NC                       ; no source icon, use default
        jsr     GetIconWindow
      IF NOT_ZERO               ; not windowed, use default
        tax
        lda     win_view_by_table-1,x
        ldx     cached_window_id
        sta     win_view_by_table-1,x ; override by parent window
      END_IF
    END_IF

        lda     icon_param ; set to `kWindowToDirIconNone` if opening via path
    IF POS
        jsr     MarkIconDimmed
    END_IF

        ;; Set path, name, size, contents, and volume free/used.
        jsr     _PrepareNewWindow

        ;; Create the window
        CALL    GetWindowPtr, A=cached_window_id ; A,X points at Winfo
        stax    @addr
        MGTK_CALL MGTK::OpenWindow, 0, @addr

        jsr     CachedIconsWindowToScreen
        jsr     DrawCachedWindowHeaderAndEntries
        jmp     ScrollUpdate

;;; ------------------------------------------------------------
;;; Set up path and coords for new window, contents and free/used.
;;; Inputs: New window id in `cached_window_id`, `src_path_buf` has full path
;;; Outputs: Winfo configured, window path table entry set

.proc _PrepareNewWindow

        ;; --------------------------------------------------
        ;; Prepare window title

        ;; Find last '/'
        ldy     src_path_buf
    DO
        lda     src_path_buf,y
        BREAK_IF A = #'/'
        dey
    WHILE POS

        ;; Copy to `filename_buf`
        ldx     #0
    DO
        iny
        inx
        copy8   src_path_buf,y, filename_buf,x
    WHILE Y <> src_path_buf
        stx     filename_buf

        ;; Copy into window title
        title_ptr := $08
        CALL    GetWindowTitle, A=cached_window_id
        stax    title_ptr

        ldy     #kMaxFilenameLength
    DO
        copy8   filename_buf,y, (title_ptr),y
        dey
    WHILE POS

        ;; --------------------------------------------------
        ;; Prepare path

        path_ptr := $08

        ;; Copy previously composed path into window path
        CALL    GetWindowPath, A=cached_window_id
        stax    path_ptr
        ldy     src_path_buf
    DO
        copy8   src_path_buf,y, (path_ptr),y
        dey
    WHILE POS

        ;; --------------------------------------------------

        winfo_ptr := $06

        ;; Set window coordinates
        CALL    GetWindowPtr, A=cached_window_id
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
        copy8   #0, (winfo_ptr),y
        iny
        pla

        lsr     a               ; / 2
        clc
        adc     #kWindowYOffset
        sta     (winfo_ptr),y   ; viewloc::ycoord
        iny
        copy8   #0, (winfo_ptr),y

        ;; Map rect (initially empty, size assigned in `ComputeInitialWindowSize`)
        lda     #0
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
    DO
        sta     (winfo_ptr),y
        dey
        dex
    WHILE POS

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

        CALL    CreateFileRecordsForNewWindow, A=cached_window_id

        ;; --------------------------------------------------
        ;; Update used/free table

        lda     icon_param      ; set to `kWindowToDirIconNone` if opening via path
    IF NC
        ;; If a windowed icon, source from that
        jsr     GetIconWindow
      IF NOT_ZERO
        ;; Windowed (folder) icon
        asl     a
        tax
        copy16  window_blocks_used_table-2,x, vol_blocks_used ; 1-based to 0-based
        copy16  window_blocks_free_table-2,x, vol_blocks_free
      END_IF
    END_IF

        ;; Used cached window's details, which are correct now.
        lda     cached_window_id
        jsr     AssignWindowBlockCounts

        copy16  window_blocks_used_table-2,x, window_draw_blocks_used_table-2,x ; 1-based to 0-based
        copy16  window_blocks_free_table-2,x, window_draw_blocks_free_table-2,x

        ;; --------------------------------------------------
        ;; Create window and icons

        bit     copy_new_window_bounds_flag
    IF NS
        ;; DeskTopSettings::kViewByXXX
        ldx     cached_window_id
        copy8   new_window_view_by, win_view_by_table-1,x

        ;; viewloc
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + .sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
      DO
        copy8   new_window_viewloc,x, (winfo_ptr),y
        dey
        dex
      WHILE POS

        ;; maprect
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
      DO
        copy8   new_window_maprect,x, (winfo_ptr),y
        dey
        dex
      WHILE POS
    END_IF

        jsr     InitWindowIcons

        bit     copy_new_window_bounds_flag
    IF NC
        jsr     ComputeInitialWindowSize
        jsr     AdjustViewportForNewIcons
    END_IF

        ;; --------------------------------------------------
        ;; Animate the window being opened

        CALL    GetWindowPath, A=cached_window_id
        jsr     IconToAnimate
        CALL    AnimateWindowOpen, X=cached_window_id

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
        ;; Find open window for the icon
        lda     icon_param
        beq     ret

        jsr     FindWindowIndexForDirIcon ; X = window id-1 if found
    IF EQ
        ;; If found, remove from the table.
        copy8   #kWindowToDirIconFree, window_to_dir_icon_table,x
    END_IF

        ;; Update the icon and redraw
        CALL    MarkIconNotDimmedNoDraw, A=icon_param
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

        copy8   num_open_windows, old

        tsx
        stx     saved_stack
        jsr     OpenWindowForPath

        ;; If an existing window was shown, refresh the contents.
        lda     num_open_windows
        old := *+1
        cmp     #SELF_MODIFIED_BYTE
    IF ZERO
        CALL    ActivateAndRefreshWindowOrClose, A=active_window_id
        bne     err
    END_IF

        CALL    SelectFileIconByName, AX=#INVOKER_FILENAME
        RETURN  C=0

err:    RETURN  C=1
.endproc ; ShowFileWithPath

;;; ============================================================
;;; Find an icon for a given path. May be volume or in any window.
;;;
;;; Inputs: A,X has path
;;; Output: A=icon id and Z=0 if found, Z=1 if no match
;;; Trashes $06 and `operation_dst_path`

.proc FindIconForPath
        jsr     CopyToOperationDstPath
        CALL    FindLastPathSegment, AX=#operation_dst_path
    IF Y = operation_dst_path      ; was there a filename?
        ;; Volume - make it a filename
        ldx     operation_dst_path ; Strip '/'
        dex
        stx     operation_dst_path+1
        ldax    #operation_dst_path+1 ; A,X=volname
        ldy     #0                    ; 0=desktop
    ELSE
        ;; File - need to see if there's a window
        jsr     SplitOperationDstPath
        CALL    FindWindowForPath, AX=#operation_dst_path
        RTS_IF ZERO             ; no matching window

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
    IF NS
        ;; Find FileRecord list
        CALL    GetFileRecordListForWindow, A=cached_window_id
        stax    file_record_ptr ; points at head of list (entry count)
        inc16   file_record_ptr ; now points at first entry in list

        ;; First row
        ldax    #kListViewFirstBaseline
        stax    pos_col::ycoord

        ;; Draw each list view row
        ldx     #0              ; X = index
rloop:  cpx     cached_window_icon_count
        beq     done
        txa                     ; A = index
        pha
        lda     cached_window_icon_list,x

        ;; Look up file record number
        jsr     GetIconRecordNum
        jsr     DrawListViewRow

        MGTK_CALL MGTK::CheckEvents

        pla                     ; A = index
        tax                     ; X = index
        inx
        jmp     rloop
    END_IF

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
        RETURN  A=(ptr),y
.endproc ; GetIconRecordNum

;;; ============================================================

.proc ClearSelection
        lda     selected_icon_count
        RTS_IF ZERO

        ;; --------------------------------------------------
        ;; Mark the icons as not highlighted

        ITK_CALL IconTK::UnhighlightAll

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
    IF NOT_ZERO                 ; Desktop
      IF A = active_window_id
        ;; --------------------------------------------------
        ;; Fast path. Since selection is in the top-most window,
        ;; drawing can be done using `IconTK::DrawIconRaw` in a
        ;; clipped port.

        jsr     UnsafeSetPortFromWindowIdAndAdjustForEntries ; CHECKED
        RTS_IF NOT_ZERO         ; obscured

        jsr     PushPointers
        jsr     CacheActiveWindowIconList
        jsr     CachedIconsScreenToWindow

        COPY_STRUCT MGTK::Rect, window_grafport+MGTK::GrafPort::maprect, tmp_rect

        ldx     #0
       DO
        txa
        pha                     ; A = index

        copy8   selected_icon_list,x, icon_param

        ITK_CALL IconTK::IconInRect, icon_param
        IF NOT ZERO
        ITK_CALL IconTK::DrawIconRaw, icon_param ; CHECKED
        ELSE
        MGTK_CALL MGTK::CheckEvents
        END_IF

        pla                     ; A = index
        tax
        inx
       WHILE X <> selected_icon_count

        jsr     CachedIconsWindowToScreen
        jsr     PopPointers     ; do not tail-call optimize!
        rts
      END_IF
    END_IF

        ;; --------------------------------------------------
        ;; Slow path. This uses `IconTK::DrawIcon` which clips icons
        ;; against overlapping windows.

        ldx     #0
    DO
        txa
        pha
        copy8   selected_icon_list,x, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param
        pla
        tax
        inx
    WHILE X <> selected_icon_count

        rts
.endproc ; RedrawSelectedIcons

;;; ============================================================

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc CachedIconsXToYImpl
        ENTRY_POINTS_FOR_BIT7_FLAG s2w, w2s, s2w_flag

        jsr     PushPointers
        lda     cached_window_id
    IF NOT_ZERO
        sta     offset_icons_params::window_id
        jsr     PrepWindowScreenMapping

        ldx     #2              ; loop over dimensions
      DO
        s2w_flag := *+1
        lda     #SELF_MODIFIED_BYTE
       IF NS
        copy16  map_delta,x, offset_icons_params::delta,x
       ELSE
        sub16   #0, map_delta,x, offset_icons_params::delta,x
       END_IF
        dex
        dex
      WHILE POS

        ITK_CALL IconTK::OffsetAll, offset_icons_params
    END_IF
        jsr     PopPointers
        rts
.endproc ; CachedIconsXToYImpl
CachedIconsScreenToWindow := CachedIconsXToYImpl::s2w
CachedIconsWindowToScreen := CachedIconsXToYImpl::w2s

;;; ============================================================
;;; Adjust grafport for header.

.proc AdjustWindowPortForEntries
        add16_8 window_grafport+MGTK::GrafPort::viewloc+MGTK::Point::ycoord, #kWindowHeaderHeight
        add16_8 window_grafport+MGTK::GrafPort::maprect+MGTK::Rect::y1, #kWindowHeaderHeight
        MGTK_CALL MGTK::SetPort, window_grafport
        rts
.endproc ; AdjustWindowPortForEntries

;;; ============================================================

.proc UpdateWindowUsedFreeDisplayValues
        lda     active_window_id
        asl
        tax
        copy16  window_blocks_used_table-2,x, window_draw_blocks_used_table-2,x ; 1-based to 0-based
        copy16  window_blocks_free_table-2,x, window_draw_blocks_free_table-2,x
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

        CALL    MakeVolumePath, AX=ptr

        ;; Update `found_windows_count` and `found_windows_list`
        CALL    FindWindowsForPrefix, AX=ptr

        ;; Restore path length
        pla
        ldy     #0
        sta     (ptr),y

        ;; Determine if there are windows to update
        jsr     PopPointers     ; $06 = vol path

        CALL    CopyToSrcPath, AX=ptr
        jsr     GetVolUsedFreeViaPath
    IF ZS
        ldy     found_windows_count
      IF NOT_ZERO
       DO
        lda     found_windows_list-1,y
        jsr     AssignWindowBlockCounts
        dey
       WHILE NOT_ZERO
      END_IF
    END_IF

        rts
.endproc ; UpdateUsedFreeViaPath

;;; Update `window_blocks_used_table`/`window_blocks_free_table`
;;; Input: A = window_id, `vol_blocks_used`/`vol_blocks_free` set
;;; Output: X = window_id*2, Y unchanged
.proc AssignWindowBlockCounts
        asl     a
        tax
        copy16  vol_blocks_used, window_blocks_used_table-2,x ; 1-based to 0-based
        copy16  vol_blocks_free, window_blocks_free_table-2,x
        rts
.endproc ; AssignWindowBlockCounts

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
    DO
        lda     (ptr),y
        cmp     #'/'
        beq     slash
        dey
    WHILE POS

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

exact:  sec
        bcs     start           ; always

prefix: clc


start:  stax    ptr1
        ror     exact_match_flag

        lda     #0
        sta     found_windows_count
        sta     window_num
    DO
        inc     window_num

        window_num := *+1
        lda     #SELF_MODIFIED_BYTE
      IF A >= #kMaxDeskTopWindows+1 ; directory windows are 1-8
        bit     exact_match_flag
       IF NS
        lda     #0
       END_IF
        rts
      END_IF

        tax
        lda     window_to_dir_icon_table-1,x
        ASSERT_EQUALS ::kWindowToDirIconFree, 0
        CONTINUE_IF ZERO

        CALL    GetWindowPath, A=window_num
        stax    ptr2

        bit     exact_match_flag
      IF NS
        jsr     CompareStrings  ; Z=1 if equal
        CONTINUE_IF ZC
        RETURN  A=window_num
      END_IF

        jsr     IsPathPrefixOf  ; Z=0 if prefix
        CONTINUE_IF ZS
        ldx     found_windows_count
        copy8   window_num, found_windows_list,x
        inc     found_windows_count
    WHILE NOT_ZERO              ; always

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
        DEFINE_OPEN_PARAMS open_params, src_path_buf, DIR_READ_IO_BUFFER

        dir_buffer := DIR_READ_DATA_BUFFER

        DEFINE_READWRITE_PARAMS read_params, dir_buffer, kDirReadDataBufferSize
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

new_window_flag:        .byte   0

        ENTRY_POINTS_FOR_BIT7_FLAG new_window, refresh_window, new_window_flag

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
    DO
        copy8   dir_buffer+SubdirectoryHeader::entry_length,x, dir_header,x
        inx
    WHILE X <> #.sizeof(dir_header)

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

        ;; Show error, unless this is during window restore.
        bit     suppress_error_on_open_flag
    IF NC
        ldax    #aux::str_warning_window_must_be_closed ; too many files to show
        ldy     active_window_id ; is a window open?
      IF ZERO
        ldax    #aux::str_warning_too_many_files ; suggest closing a window
      END_IF
        CALL    ShowAlertParams, Y=#AlertButtonOptions::OK ; A,X = string
    END_IF

        TAIL_CALL _HandleFailure, C=0 ; check vol flag (no)

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
    IF A <> dir_header::entries_per_block
        add16_8 entry_ptr, dir_header::entry_length
    ELSE
        copy8   #$00, index_in_block
        copy16  #$0C04, entry_ptr
        jsr     _DoRead
    END_IF

        ldx     #$00
        ldy     #$00
        lda     (entry_ptr),y
        and     #NAME_LENGTH_MASK
        beq     next            ; inactive entry
        sta     record,x        ; name length

        CALL    ReadSetting, X=#DeskTopSettings::options
        and     #DeskTopSettings::kOptionsShowInvisible
    IF ZERO
        ldy     #FileEntry::access
        lda     (entry_ptr),y
        and     #ACCESS_I
        bne     do_entry
    END_IF

        inc     record_count

        CALL    AdjustFileEntryCase, AX=entry_ptr

        ;; Copy fields from `FileEntry` to `FileRecord`
        ;; (name length handled above, hence off-by-ones)
        ldx     #1
    DO
        ldy     file_entry_to_file_record_mapping_table-1,x
        copy8   (entry_ptr),y, record,x
        inx
    WHILE X <> #.sizeof(FileRecord)

        ;; Copy entry composed at $1F00 to buffer in Aux LC Bank 2
        bit     LCBANK2
        bit     LCBANK2
        ldy     #.sizeof(FileRecord)-1
    DO
        copy8   record,y, (record_ptr),y
        dey
    WHILE POS
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
        jsr     SetCursorPointer ; after loading directory (success)
        jsr     PopPointers      ; do not tail-call optimise!
        rts

;;; index is offset in `FileRecord`-1, value is offset in `FileEntry`
file_entry_to_file_record_mapping_table:
        ;; name length needs masking and is handled separately
        .repeat ::kMaxFilenameLength,i
        .byte   FileEntry::file_name+i
        .endrepeat
        .byte   FileEntry::file_type
        .byte   FileEntry::blocks_used+0
        .byte   FileEntry::blocks_used+1
        .byte   FileEntry::creation_date+0
        .byte   FileEntry::creation_date+1
        .byte   FileEntry::creation_date+2
        .byte   FileEntry::creation_date+3
        .byte   FileEntry::mod_date+0
        .byte   FileEntry::mod_date+1
        .byte   FileEntry::mod_date+2
        .byte   FileEntry::mod_date+3
        .byte   FileEntry::access
        .byte   FileEntry::header_pointer+0
        .byte   FileEntry::header_pointer+1
        .byte   FileEntry::aux_type+0
        .byte   FileEntry::aux_type+1
        ASSERT_TABLE_SIZE file_entry_to_file_record_mapping_table, .sizeof(FileRecord)-1

;;; --------------------------------------------------

.proc _DoOpen
        MLI_CALL OPEN, open_params
    IF CS
        ;; Show error, unless this is during window restore.
        bit     suppress_error_on_open_flag
      IF NC
        jsr     ShowAlert
      END_IF

        TAIL_CALL _HandleFailure, C=1 ; check vol flag (yes)
    END_IF

        rts
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

;;; Input: A = check vol flag
.proc _HandleFailure
        php                     ; C = check vol flag

        bit     new_window_flag
    IF NS
        ;; If opening an icon, need to reset icon state.
        bit     icon_param      ; Were we opening a path? (N=1)
      IF NC
        jsr     MarkIconNotDimmed
      END_IF

        ;; A window was allocated but unused, so restore the count.
        dec     num_open_windows

        ;; A table entry was possibly allocated - free it.
        ldy     cached_window_id
      IF NOT_ZERO
        copy8   #0, cached_window_id
        copy8   #kWindowToDirIconFree, window_to_dir_icon_table-1,y
      END_IF
    END_IF

        plp                     ; C = check vol flag
    IF CS
        lda     selected_window_id
      IF ZERO
        ;; Volume icon - check that it's still valid.
        CALL    CheckDriveByIconNumber, A=icon_param, Y=#kCheckDriveDoNotShowUnexpectedErrors
      END_IF
    END_IF

        ;; And return via saved stack.
        jsr     SetCursorPointer ; after loading directory (failure)
        ldx     saved_stack
        txs
.endproc ; _HandleFailure

;;; --------------------------------------------------
.endproc ; CreateFileRecordsForWindowImpl
CreateFileRecordsForNewWindow := CreateFileRecordsForWindowImpl::new_window
CreateFileRecordsForRefreshedWindow := CreateFileRecordsForWindowImpl::refresh_window

;;; ============================================================
;;; Inputs: `src_path_buf` set to full path (not modified)
;;; Outputs: Z=1 on success, `vol_blocks_used` and `vol_blocks_free` updated.
;;; TODO: Skip if same-vol windows already have data.

.proc GetVolUsedFreeViaPath
        lda     src_path_buf
        pha                     ; A = original length

        ;; Strip to vol name - either end of string or next slash
        CALL    MakeVolumePath, AX=#src_path_buf

        ;; Get volume information
        jsr     GetSrcFileInfo

        pla                     ; A = original length
        sta     src_path_buf

    IF CS
        RETURN  A=#$FF          ; failure
    END_IF

        ;; aux = total blocks
        copy16  src_file_info_params::blocks_used, vol_blocks_used
        ;; total - used = free
        sub16   src_file_info_params::aux_type, vol_blocks_used, vol_blocks_free

        RETURN  A=#0            ; success
.endproc ; GetVolUsedFreeViaPath

vol_blocks_free:  .word   0
vol_blocks_used:  .word   0

;;; ============================================================
;;; Remove the FileRecord entries for a window, and free/compact
;;; the space.
;;; A = window id

.proc RemoveWindowFileRecords
        ;; Find address of FileRecord list
        jsr     FindIndexInFileRecordListEntries
        RTS_IF ZC

        ;; Move list entries down by one
        stx     index
        dex
    DO
        inx
        copy8   window_id_to_filerecord_list_entries+1,x, window_id_to_filerecord_list_entries,x
    WHILE X <> window_id_to_filerecord_list_count

        ;; List is now shorter by one...
        dec     window_id_to_filerecord_list_count

        ;; Was that the last one?
        index := *+1
        lda     #SELF_MODIFIED_BYTE
    IF A = window_id_to_filerecord_list_count
        asl     a               ; so update the start of free space
        tax
        copy16  window_filerecord_table,x, filerecords_free_start
        rts                     ; and done!
    END_IF

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

        lda     index
        asl     a
        tax
        copy16  window_filerecord_table,x, ptr_dst
        inx
        inx
        copy16  window_filerecord_table,x, ptr_src

        ldy     #0
        jsr     PushPointers
    DO
        bit     LCBANK2
        bit     LCBANK2
        copy8   (ptr_src),y, (ptr_dst),y
        bit     LCBANK1
        bit     LCBANK1
        inc16   ptr_dst
        inc16   ptr_src

        ;; All the way to top of used space
        ecmp16  ptr_src, filerecords_free_start
    WHILE NE
        jsr     PopPointers     ; do not tail-call optimise!

        ;; Offset affected list pointers down
        lda     window_id_to_filerecord_list_count
        asl     a
        tax
        sub16   filerecords_free_start, window_filerecord_table,x, deltam
        inc     index

    DO
        lda     index
        BREAK_IF A = window_id_to_filerecord_list_count

        lda     index
        asl     a
        tax
        sub16   window_filerecord_table+2,x, window_filerecord_table,x, size
        add16   window_filerecord_table-2,x, size, window_filerecord_table,x
        inc     index
    WHILE NOT_ZERO              ; always

        ;; Update "start of free memory" pointer
        lda     window_id_to_filerecord_list_count
        asl     a
        tax
        add16   window_filerecord_table-2,x, deltam, filerecords_free_start
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
        ;; Results in `iconbb_rect` are ignored if window is empty
        jsr     ComputeIconsBBox

        winfo_ptr := $06

        CALL    GetWindowPtr, A=cached_window_id
        stax    winfo_ptr

        ;; convert right/bottom to width/height
        bbox_dx := iconbb_rect+MGTK::Rect::x2
        bbox_dy := iconbb_rect+MGTK::Rect::y2

        ldx     #2              ; loop over dimensions
    DO
        sub16   bbox_dx,x, iconbb_rect+MGTK::Rect::topleft,x, bbox_dx,x
        dex
        dex
    WHILE POS

        ;; Account for window header
        add16_8 bbox_dy, #kWindowHeaderHeight

        ;; --------------------------------------------------
        ;; Width

        lda     cached_window_icon_count
        beq     use_minw        ; `iconbb_rect` is bogus if there are no icons

        ;; Check if width is < min or > max
        cmp16   bbox_dx, #kMinWindowWidth
        bcc     use_minw
        cmp16   bbox_dx, #kMaxWindowWidth
        bcs     use_maxw
        ldax    bbox_dx
        bcc     assign_width    ; always

use_minw:
        ldax    #kMinWindowWidth
        ASSERT_EQUALS .hibyte(::kMinWindowWidth), 0
        beq     assign_width    ; always

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

        lda     cached_window_icon_count
        beq     use_minh        ; `iconbb_rect` is bogus if there are no icons

        ;; Check if height is < min or > max
        cmp16   bbox_dy, #kMinWindowHeight
        bcc     use_minh
        cmp16   bbox_dy, #kMaxWindowHeight
        bcs     use_maxh
        ldax    bbox_dy
        bcc     assign_height   ; always

use_minh:
        ldax    #kMinWindowHeight
        ASSERT_EQUALS .hibyte(::kMinWindowHeight), 0
        beq     assign_height   ; always

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
;;;
;;; Note: Assumes icons are in window coordinates.
.proc AdjustViewportForNewIcons
        ;; No-op if window is empty
        lda     cached_window_icon_count
    IF NOT_ZERO
        ;; Window space
        jsr     ComputeIconsBBox

        winfo_ptr := $06
        tmpw := $08

        CALL    GetWindowPtr, A=cached_window_id
        stax    winfo_ptr

        ;; Adjust view bounds of new window so it matches icon bounding box.
        ;; (Only done for width because height is treated as fixed.)

        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Rect::x1
        add16in (winfo_ptr),y, iconbb_rect+MGTK::Rect::x1, (winfo_ptr),y
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Rect::x2
        add16in (winfo_ptr),y, iconbb_rect+MGTK::Rect::x1, (winfo_ptr),y
    END_IF
        rts
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
    IF A = #kICTSentinel
        jsr     PopPointers
        RETURN  A=#IconType::generic
    END_IF

        ;; Check type (with mask)
        and     file_type       ; A = type & mask
        iny                     ; ASSERT: Y = ICTRecord::filetype
        ASSERT_EQUALS ICTRecord::filetype, ICTRecord::mask+1
        cmp     (ptr),y         ; type check
        bne     next

        ;; Flags
        iny                     ; ASSERT: Y = ICTRecord::flags
        ASSERT_EQUALS ICTRecord::flags, ICTRecord::filetype+1
        copy8   (ptr),y, flags

        ;; Does Aux Type matter, and if so does it match?
        bit     flags
    IF NS                       ; bit 7 = compare aux
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
    IF VS                       ; bit 6 = compare blocks
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
    IF NOT_ZERO
        ;; Set up pointers to suffix and filename
        ptr_suffix      := $08
        ldy     #ICTRecord::aux_suf
        copy16in (ptr),y, ptr_suffix
        ;; Start at the end of the strings
        ldy     #0
        copy8   (ptr_suffix),y, suffix_pos
        copy8   (ptr_filename),y, filename_pos

        ;; Case-insensitive compare each character
      DO
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
        BREAK_IF ZERO           ; if we ran out of suffix, it's a match
        dec     filename_pos
        beq     next            ; but if we ran out of filename, it's not
      WHILE NOT_ZERO            ; otherwise, keep going
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
;;; Cache the given directory window's `MapInfo` (view geometry) on
;;; the zero page, to avoid pointer gymnastics. It does not require
;;; that the window has been created in MGTK yet.
;;;
;;; Input: A = `window_id`
;;; Output: $40...$4F holds copy of window's `MapInfo`
;;; Trashes $06

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"

window_mapinfo_cache := $40

.proc CacheWindowMapInfo
        winfo_ptr := $06

        jsr     GetWindowPtr
        stax    winfo_ptr

        ldy     #MGTK::Winfo::port + .sizeof(MGTK::MapInfo) - 1
        ldx     #.sizeof(MGTK::MapInfo) - 1
    DO
        copy8   (winfo_ptr),y, window_mapinfo_cache,x
        dey
        dex
    WHILE POS

        rts
.endproc ; CacheWindowMapInfo

;;; ============================================================
;;; Draw header (items/K in disk/K available/lines) for `cached_window_id`

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc DrawWindowHeader

;;; Local variables on ZP
;;; Note that this collides with the `window_mapinfo_cache` but we
;;; finish using it before the fields that collide are touched.
PARAM_BLOCK, $40
gap                     .word

num_items               .word
blocks_in_disk          .word
blocks_available        .word

width_num_items         .word
width_k_in_disk         .word
width_k_available       .word
END_PARAM_BLOCK

        ;; --------------------------------------------------
        ;; Window header doesn't scroll with window's maprect so we
        ;; need to "undo" the offset. Stash the maprect somewhere
        ;; handy and calculate coordinates with it.

        CALL    CacheWindowMapInfo, A=cached_window_id
        maprect := window_mapinfo_cache + MGTK::MapInfo::maprect

        ;; separator line x/y coords
        copy16  maprect+MGTK::Rect::x1, header_line_left::xcoord
        add16_8 maprect+MGTK::Rect::y1, #kWindowHeaderHeight - 3, header_line_left::ycoord

        ;; label x/y coords
        add16_8 maprect+MGTK::Rect::x1, #kWindowHeaderInsetX, header_text_pos::xcoord
        add16_8 maprect+MGTK::Rect::y1, #kWindowHeaderHeight-5, header_text_pos::ycoord

        ;; window width
        ;; Note that `gap` is in `window_mapinfo_cache`'s `MapInfo::viewloc`
        sub16   maprect+MGTK::Rect::x2, maprect+MGTK::Rect::x1, gap

        ;; Now we're done with `window_mapinfo_cache`

        ;; --------------------------------------------------
        ;; Separator Lines

        jsr     SetPenModeNotCopy

        ;; Draw top line
        MGTK_CALL MGTK::MoveTo, header_line_left
        MGTK_CALL MGTK::Line, header_line_right

        ;; Offset down by 2px
        add16_8 header_line_left::ycoord, #2

        ;; Draw bottom line
        MGTK_CALL MGTK::MoveTo, header_line_left
        MGTK_CALL MGTK::Line, header_line_right

        ;; --------------------------------------------------
        ;; Labels (Items/K in disk/K available)

        ;; Cache values
        CALL    GetFileRecordCountForWindow, A=cached_window_id
        ldx     #0              ; hi
        stax    num_items

        ldx     cached_window_id
        txa
        asl     a
        tay
        ldax    window_draw_blocks_used_table-2,y ; 1-based to 0-based
        stax    blocks_in_disk
        ldax    window_draw_blocks_free_table-2,y
        stax    blocks_available

        ;; Measure strings
        jsr     _PrepItems
        jsr     _Measure
        stax    width_num_items

        jsr     _PrepInDisk
        jsr     _Measure
        stax    width_k_in_disk

        jsr     _PrepAvailable
        jsr     _Measure
        stax    width_k_available

        ;; Determine gap for centering
        sub16_8 gap, #kWindowHeaderInsetX * 2 ; minus left/right insets
        sub16   gap, width_num_items, gap ; minus width of all text
        sub16   gap, width_k_in_disk, gap
        sub16   gap, width_k_available, gap
        asr16   gap                         ; divided evenly
        scmp16  #kWindowHeaderSpacingX, gap ; is it below the minimum?
    IF POS
        copy16  #kWindowHeaderSpacingX, gap ; yes, use the minimum
    END_IF
        copy16  gap, header_text_delta::xcoord

        ;; Draw "XXX items"
        MGTK_CALL MGTK::MoveTo, header_text_pos
        jsr     _PrepItems
        jsr     draw

        ;; Draw "XXXK in disk"
        MGTK_CALL MGTK::Move, header_text_delta
        jsr     _PrepInDisk
        jsr     draw

        ;; Draw "XXXK available"
        MGTK_CALL MGTK::Move, header_text_delta
        jsr     _PrepAvailable
draw:   MGTK_CALL MGTK::DrawString, text_input_buf
        rts

.proc _PrepItems
        push16  num_items
        CALL    IsPlural, AX=num_items
    IF CS
        FORMAT_MESSAGE 1, aux::str_item_count_singular_format
        rts
    END_IF
        FORMAT_MESSAGE 1, aux::str_item_count_plural_format
        rts
.endproc ; _PrepItems

.proc _PrepInDisk
        push16  blocks_in_disk
        FORMAT_MESSAGE 1, aux::str_k_in_disk_format
        rts
.endproc ; _PrepInDisk

.proc _PrepAvailable
        push16  blocks_available
        FORMAT_MESSAGE 1, aux::str_k_available_format
        rts
.endproc ; _PrepAvailable

.proc _Measure
        ldax    #text_input_buf
        FALL_THROUGH_TO _MeasureString
.endproc ; _Measure

;;; Measure text, pascal string address in A,X; result in A,X
;;; String must be in LC area (visible to both main and aux code)
.proc _MeasureString
        ptr := $6
        result := $8

        stax    ptr
        MGTK_CALL MGTK::StringWidth, ptr
        RETURN  AX=result
.endproc ; _MeasureString

.endproc ; DrawWindowHeader

;;; ============================================================
;;; Compute bounding box for icons within cached window
;;; Inputs: `cached_window_id` is set
;;; Outputs: `iconbb_rect` updated (unless cached window is empty)
.proc ComputeIconsBBox

        lda     cached_window_icon_count
        RTS_IF ZERO

        copy8   cached_window_id, get_iconbb::window_id
        ITK_CALL IconTK::GetAllBounds, get_iconbb ; inits `iconbb_rect`

        ;; List view?
        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
    IF NS
        ;; max.x = kListViewWidth
        add16   iconbb_rect+MGTK::Rect::x1, #kListViewWidth, iconbb_rect+MGTK::Rect::x2
    END_IF

        ;; Add padding around bbox
        MGTK_CALL MGTK::InflateRect, bbox_pad_iconbb_rect
        rts

.endproc ; ComputeIconsBBox

;;; ============================================================
;;; Prepares a window's icons from its `FileRecord`s.
;;;
;;; Inputs: `cached_window_id` is set
;;; Outputs: Populates `cached_window_icon_count` with count and
;;;          `cached_window_icon_list` with indexes 1...N
;;; Assert: LCBANK1 is active
;;; Note that icons are left in window coordinates, and must
;;; eventually be remapped to screen coordinates as IconTK expects.

.proc InitWindowIcons
        ;; --------------------------------------------------
        ;; Create generic entries for window

        jsr     PushPointers

        ;; Get the entry count via FileRecord list
        CALL    GetFileRecordCountForWindow, A=cached_window_id

        ;; Store the count
        sta     cached_window_icon_count

        ;; Init the entries, monotonically increasing
        tax
    IF NOT_ZERO
      DO
        txa
        sta     cached_window_icon_list-1,x ; entries are 1-based
        dex
      WHILE NOT_ZERO
    END_IF

        jsr     PopPointers     ; do not tail-call optimize!

        ;; --------------------------------------------------
        ;; Sort (if needed)

        jsr     GetCachedWindowViewBy ; N=0 is icon view, N=1 is list view
    IF NS
        jsr     _SortFileRecords
    END_IF

        ;; --------------------------------------------------
        ;; Create icons

        jsr     _CreateIconsForWindow
        jmp     StoreCachedWindowIconList

;;; ------------------------------------------------------------
;;; Populates and sorts `cached_window_icon_list` while that
;;; list is temporarily a list of `FileRecords`.
;;; Inputs: A=`DeskTopSettings::kViewBy*` for `cached_window_id`

.proc _SortFileRecords

list_start_ptr  := $801
num_records     := $803
scratch_space   := $804         ; can be used by comparison funcs

        sta     _CompareFileRecords_sort_by

        lda     cached_window_icon_count
        RTS_IF A < #2           ; can't sort < 2 records

        sta     num_records

        CALL    GetFileRecordListForWindow, A=cached_window_id
        stax    list_start_ptr
        inc16   list_start_ptr

        copy16  #_CalcPtr, Quicksort_GetPtrProc
        copy16  #_CompareProc, Quicksort_CompareProc
        copy16  #_SwapProc, Quicksort_SwapProc

        TAIL_CALL Quicksort, A=num_records

.proc _CompareProc
        bit     LCBANK2
        bit     LCBANK2
        jsr     _CompareFileRecords
        php
        bit     LCBANK1
        bit     LCBANK1
        plp
        rts
.endproc ; _CompareProc

.proc _SwapProc
        swap8   cached_window_icon_list,x, cached_window_icon_list,y
        rts
.endproc ; _SwapProc

;;; --------------------------------------------------
;;; Input: A = index in list being sorted
;;; Output: A,X = pointer to FileRecord
;;; Assert: LCBANK1 banked in so `cached_window_icon_list` is visible

.proc _CalcPtr
        ;; Map from sorting list index to FileRecord index
        tax
        ldy     cached_window_icon_list,x
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
    IF A = #DeskTopSettings::kViewByName
        ASSERT_EQUALS FileRecord::name, 0
        jmp     CompareStrings
    END_IF

    IF A = #DeskTopSettings::kViewByDate
PARAM_BLOCK scratch, $804       ; `scratch_space`
date_a  .tag    DateTime
date_b  .tag    DateTime
parsed_a .tag ParsedDateTime
parsed_b .tag ParsedDateTime
END_PARAM_BLOCK

        ;; Copy the dates somewhere easier to work with
        ldy     #FileRecord::modification_date + .sizeof(DateTime)-1
        ldx     #.sizeof(DateTime)-1
      DO
        copy8   (ptr2),y, scratch::date_a,x ; order descending
        copy8   (ptr1),y, scratch::date_b,x
        dey
        dex
      WHILE POS

        ;; Crack the ProDOS values into more useful structs, and
        ;; handle various year encodings.
        ptr := $0A

        copy16  #scratch::parsed_a, ptr
        CALL    ParseDatetime, AX=#scratch::date_a

        copy16  #scratch::parsed_b, ptr
        CALL    ParseDatetime, AX=#scratch::date_b

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

    IF A = #DeskTopSettings::kViewBySize
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
      IF A = #FT_DIRECTORY
        copy16  #0, size1
      END_IF
        lda     (ptr2),y
      IF A = #FT_DIRECTORY
        copy16  #0, size2
      END_IF

        ;; Compare!
        ecmp16  size2, size1    ; order descending, with Z and C
        rts
    END_IF

        ;; Assert: DeskTopSettings::kViewByType
        ldy     #FileRecord::file_type
        CALL    _ComposeFileTypeStringForSorting, A=(ptr1),y
        COPY_STRING str_file_type, scratch
        ldy     #FileRecord::file_type
        CALL    _ComposeFileTypeStringForSorting, A=(ptr2),y

        bit     LCBANK1
        bit     LCBANK1
        jsr     PushPointers
        copy16  #scratch, $06
        copy16  #str_file_type, $08
        jsr     CompareStrings
        php                     ; preserve Z,C
        pla
        jsr     PopPointers
        bit     LCBANK2
        bit     LCBANK2
        pha
        plp                     ; restore Z,C

        rts

.endproc ; _CompareFileRecords
_CompareFileRecords_sort_by := _CompareFileRecords::sort_by

.proc _ComposeFileTypeStringForSorting
        jsr     ComposeFileTypeString
        lda     str_file_type+1
    IF A = #'$'
        copy8   #$FF, str_file_type+1
    END_IF
        rts
.endproc ; _ComposeFileTypeStringForSorting

.endproc ; _SortFileRecords

;;; ------------------------------------------------------------
;;; File Icon Construction
;;; Inputs: `cached_window_id` must be set

.proc _CreateIconsForWindow

;;; Local variables on ZP
PARAM_BLOCK, $50
icon_type       .addr
icon_flags      .byte
icon_width_half .byte
icon_height     .byte

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
    IF NS
        ldy     #init_list_view - init_views + init_view_size-1
    ELSE_IF ZERO
        ASSERT_EQUALS DeskTopSettings::kViewByIcon, 0
        ldy     #init_icon_view - init_views + init_view_size-1
    ELSE
        ldy     #init_smicon_view - init_views + init_view_size-1
    END_IF

        ;; Populate the initial values from the template
        ldx     #init_view_size-1
    DO
        copy8   init_views,y, init_view,x
        dey
        dex
    WHILE POS

        ;; Init/zero out the rest of the state
        copy16  icon_coords+MGTK::Point::xcoord, initial_xcoord

        lda     #0
        sta     icons_this_row

        ;; Copy `cached_window_icon_list` to temp location
        record_order_list := $800
        ldx     cached_window_icon_count
        stx     num_files
        dex
    DO
        copy8   cached_window_icon_list,x, record_order_list,x
        dex
    WHILE POS

        copy8   #0, cached_window_icon_count

        ;; Get base pointer to records
        CALL    GetFileRecordListForWindow, A=cached_window_id
        addax   #1, records_base_ptr ; first byte in list is the list size

        lda     cached_window_id
        sta     active_window_id
        sta     focused_window_id

        ;; Loop over files, creating icon for each
        ldx     #0              ; X = index
    DO
        num_files := *+1
        cpx     #SELF_MODIFIED_BYTE
        BREAK_IF EQ
        txa                     ; A = index
        pha

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

        pla                     ; A = index
        tax                     ; X = index
        inx
    WHILE NOT_ZERO              ; always

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
        copy8   get_icon_entry_params::id, icon_num
        ldx     cached_window_icon_count
        inc     cached_window_icon_count
        sta     cached_window_icon_list,x

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
    DO
        copy8   (file_record),y, name_tmp,y
        dey
    WHILE POS

        ;; Copy out file metadata needed to determine icon type
        jsr     FileRecordToSrcFileInfo ; uses `FileRecord` ptr in $08

        ;; Done with `FileRecord` entries
        bit     LCBANK1
        bit     LCBANK1

        ;; Determine icon type
        jsr     GetCachedWindowViewBy
        sta     view_by
        CALL    DetermineIconType, AX=#name_tmp ; uses passed name and `src_file_info_params`
        view_by := *+1
        ldy     #SELF_MODIFIED_BYTE
        jsr     _FindIconDetailsForIconType

        ;; Copy name into `IconEntry`
        ldy     #IconEntry::name + kMaxFilenameLength
        ldx     #kMaxFilenameLength
    DO
        copy8   name_tmp,x, (icon_entry),y
        dey
        dex
    WHILE POS

        ;; Assign location
        ldy     #IconEntry::iconx + .sizeof(MGTK::Point) - 1
        ldx     #.sizeof(MGTK::Point) - 1
    DO
        copy8   icon_coords,x, (icon_entry),y
        dey
        dex
    WHILE POS

        jsr     GetCachedWindowViewBy
        ASSERT_EQUALS DeskTopSettings::kViewByIcon, 0
    IF ZERO
        ;; Icon view: include x- and y-offset
        ldy     #IconEntry::iconx
        ldx     #0              ; loop over dimensions
      DO
        ;; First iteration: `icon_entry[IconEntry::iconx]` += `icon_width_half`
        ;; Second iteration: `icon_entry[IconEntry::icony]` += `icon_height`
        lda     (icon_entry),y
        sec
        sbc     icon_width_half,x
        sta     (icon_entry),y
        iny
        lda     (icon_entry),y
        sbc     #0
        sta     (icon_entry),y
        iny
        inx
      WHILE X < #2
    END_IF

        ;; Next col
        add16_8 icon_coords+MGTK::Point::xcoord, col_spacing
        inc     icons_this_row
        ;; Next row?
        lda     icons_this_row
    IF A = icons_per_row
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
    IF A = #FT_DIRECTORY
        icon_num := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     GetIconPath     ; `operation_src_path` set to path; A=0 on success
      IF ZERO
        jsr     PushPointers
        CALL    FindWindowForPath, AX=#operation_src_path
        jsr     PopPointers
        tax                     ; A = window id, 0 if none
       IF NOT_ZERO
        copy8   icon_num, window_to_dir_icon_table-1,x

        ;; Update `IconEntry::state`
        ldy     #IconEntry::state ; mark as dimmed
        lda     (icon_entry),y
        ora     #kIconEntryStateDimmed
        sta     (icon_entry),y
       END_IF
      END_IF
    END_IF

        rts
.endproc ; _AllocAndPopulateFileIcon

;;; ============================================================
;;; Inputs: A = `IconType` member, Y = `DeskTopSettings::kViewByXXX` value
;;; Outputs: Populates `icon_flags`, `icon_type`, `icon_width_half`, `icon_height`

.proc _FindIconDetailsForIconType
        ptr := $6

        sty     view_by
        jsr     PushPointers

        ;; For populating `IconEntry::win_flags`
        tay                     ; Y = `IconType`
        copy8   icontype_iconentryflags_table,y, icon_flags

        ;; Adjust type and flags based on view
        view_by := *+1
        lda     #SELF_MODIFIED_BYTE
        ASSERT_EQUALS DeskTopSettings::kViewByIcon, 0
    IF NOT_ZERO
        ;; List View / Small Icon View
        php
        lda     icon_flags
        ora     #kIconEntryFlagsSmall
        plp
      IF NS
        ora     #kIconEntryFlagsFixed
      END_IF
        sta     icon_flags

        lda     icontype_to_smicon_table,y
        tay
    END_IF

        ;; For populating `IconEntry::type`
        sty     icon_type

        ;; Icon width/height will be needed too
        tya
        asl                     ; *= 2
        tay
        ldax    type_icons_table,y
        stax    ptr
        ldy     #IconResource::maprect + MGTK::Rect::x2
        lda     (ptr),y
        lsr                     ; /= 2
        sta     icon_width_half
        ldy     #IconResource::maprect + MGTK::Rect::y2
        copy8   (ptr),y, icon_height

        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; _FindIconDetailsForIconType

.endproc ; _CreateIconsForWindow

.endproc ; InitWindowIcons

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
;;; A = entry number

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc DrawListViewRow

        ptr := $06

        ASSERT_EQUALS .sizeof(FileRecord), 32
        jsr     ATimes32        ; A,X = A * 32
        addax   file_record_ptr, ptr

        ;; Copy into more convenient location (LCBANK1)
        bit     LCBANK2
        bit     LCBANK2
        ldy     #.sizeof(FileRecord)-1
    DO
        copy8   (ptr),y, list_view_filerecord,y
        dey
    WHILE POS
        bit     LCBANK1
        bit     LCBANK1

        viewport := window_grafport+MGTK::GrafPort::maprect

        ;; Below bottom?
        scmp16  pos_col::ycoord, viewport+MGTK::Rect::y2
        bpl     ret

        add16   pos_col::ycoord, #kListViewRowHeight, pos_col::ycoord

        ;; Above top?
        scmp16  pos_col::ycoord, viewport+MGTK::Rect::y1
        bpl     in_range
ret:    rts

        ;; Draw it!
in_range:
        CALL    set_pos, AX=#kColLock
        jsr     _PrepareColLock
        lda     text_buffer2
    IF NOT ZERO
        MGTK_CALL MGTK::DrawString, text_buffer2
    END_IF

        CALL    set_pos, AX=#kColType
        jsr     _PrepareColType
        MGTK_CALL MGTK::DrawString, text_buffer2

        CALL    set_pos, AX=#kColSize
        jsr     _PrepareColSize
        CALL    DrawStringRight, AX=#text_buffer2

        CALL    set_pos, AX=#kColDate
        jsr     ComposeDateString
        MGTK_CALL MGTK::DrawString, text_buffer2
        rts

set_pos:
        stax    pos_col::xcoord
        MGTK_CALL MGTK::MoveTo, pos_col
        rts

;;; ============================================================

.proc _PrepareColType
        file_type := list_view_filerecord + FileRecord::file_type

        CALL    ComposeFileTypeString, A=file_type

        COPY_BYTES 4, str_file_type, text_buffer2 ; 3 characters + length

        rts
.endproc ; _PrepareColType

.proc _PrepareColLock
        copy8   #0, text_buffer2

        access := list_view_filerecord + FileRecord::access
        lda     access
        and     #ACCESS_DEFAULT
    IF A <> #ACCESS_DEFAULT
        inc     text_buffer2
        copy8   #kGlyphLock, text_buffer2+1
    END_IF

        rts
.endproc ; _PrepareColLock

.proc _PrepareColSize
        file_type := list_view_filerecord + FileRecord::file_type

        lda     file_type
    IF A = #FT_DIRECTORY
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

        CALL    ReadSetting, X=#DeskTopSettings::intl_deci_sep
        sta     deci_sep

        CLEAR_BIT7_FLAG frac_flag
        cmp16   value, #20
    IF LT
        lsr16   value           ; Convert blocks to K, rounding up
        ror     frac_flag       ; If < 10k and odd, show ".5" suffix"
    ELSE
        lsr16   value           ; Convert blocks to K, rounding up
      IF CS                     ; NOTE: divide then maybe inc, rather than
        inc16   value           ; always inc then divide, to handle $FFFF
      END_IF
    END_IF

        CALL    IntToStringWithSeparators, AX=value
        ldx     #0

        ;; Append number
        ldy     #0
    DO
        copy8   str_from_int+1,y, text_buffer2+1,x
        iny
        inx
    WHILE Y <> str_from_int

        ;; Append ".5" if needed
        frac_flag := *+1
        lda     #SELF_MODIFIED_BYTE ; bit7
    IF NS
        deci_sep := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     text_buffer2+1,x
        inx
        copy8   #'5', text_buffer2+1,x
        inx
    END_IF

        ;; Append suffix
        ldy     #0
    DO
        copy8   str_kb_suffix+1, y, text_buffer2+1,x
        iny
        inx
    WHILE Y <> str_kb_suffix

        stx     text_buffer2
        rts
.endproc ; ComposeSizeString

;;; ============================================================

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc ComposeDateString
        lda     datetime_for_conversion ; any bits set?
        ora     datetime_for_conversion+1
    IF ZERO
        COPY_STRING str_no_date, text_buffer2
        rts
    END_IF

        copy16  #parsed_date, $0A
        CALL    ParseDatetime, AX=#datetime_for_conversion

        ;; --------------------------------------------------
        ;; Date

        ecmp16  datetime_for_conversion, DATELO
    IF EQ
        TAIL_CALL finish_date, AX=#str_today
    END_IF

        tmp_date := $A

        copy16  datetime_for_conversion, tmp_date
        jsr     _DecP8Date
        ecmp16  DATELO, tmp_date
    IF EQ
        TAIL_CALL finish_date, AX=#str_tomorrow
    END_IF

        copy16  DATELO, tmp_date
        jsr     _DecP8Date
        ecmp16  datetime_for_conversion, tmp_date
    IF EQ
        TAIL_CALL finish_date, AX=#str_yesterday
    END_IF

        ;; arg0 = day
        lda     day
        pha
        lda     #0
        pha

        ;; arg1 = month
        lda     month
        asl     a
        tay
        lda     month_table,y
        pha
        lda     month_table+1,y
        pha

        ;; arg2 = year
        push16  year

        CALL    ReadSetting, X=#DeskTopSettings::intl_date_order
        ASSERT_EQUALS DeskTopSettings::kDateOrderMDY, 0
    IF ZERO
        ;; Month Day, Year
        FORMAT_MESSAGE 3, str_mdy_format
    ELSE
        ;; Day Month Year
        FORMAT_MESSAGE 3, str_dmy_format
    END_IF

        COPY_STRING text_input_buf, text_buffer2
        ldax    #text_buffer2

finish_date:
        ;; arg0 = date
        phax

        ;; --------------------------------------------------
        ;; Time

        ;; arg1 = time
        CALL    MakeTimeString, AX=#parsed_date
        push16  #str_time

        FORMAT_MESSAGE 2, str_datetime_format
        COPY_STRING text_input_buf, text_buffer2
        rts

year    := parsed_date + ParsedDateTime::year
month   := parsed_date + ParsedDateTime::month
day     := parsed_date + ParsedDateTime::day
hour    := parsed_date + ParsedDateTime::hour
min     := parsed_date + ParsedDateTime::minute

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
    IF NEG
        copy8   #99, DATEHI     ; wrap to year 99 (not 127)
    END_IF
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
        RETURN  AX=get_icon_entry_params::addr
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
        RETURN  AX=#str_root_path

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
;;; Outputs: Z=1/A=0/`operation_src_path` populated with full path on success
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
    IF ZERO
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
        copy8   #'/', src_path_buf,x

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
        copy8   #'/', dst_path_buf,x

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
        params := $06
        str := params
        width := params+2

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params
        sub16   #0, width, params+MGTK::Point::xcoord
        copy16  #0, params+MGTK::Point::ycoord
        MGTK_CALL MGTK::Move, params
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawStringRight

;;; ============================================================

map_delta:
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
        .assert window_mapinfo_cache + .sizeof(MGTK::MapInfo) <= $50, error, "collision"

        ;; NOTE: Can't use `MGTK::ScreenToWindow` as that doesn't take
        ;; into account scroll position (i.e. the GrafPort's `maprect`)

        jsr     CacheWindowMapInfo

        ldx     #2              ; loop over dimensions
    DO
        sub16   window_mapinfo_cache+MGTK::GrafPort::maprect+MGTK::Rect::topleft,x, window_mapinfo_cache+MGTK::GrafPort::viewloc,x, map_delta,x
        dex
        dex
    WHILE POS
        rts

.endproc ; PrepWindowScreenMapping

;;; Input: A,X = point coords
.proc MapCoordsScreenToWindow
        ptr := $06

        jsr     PushPointers
        stax    ptr

        ldy     #MGTK::Point::xcoord
        add16in map_delta_x, (ptr),y, (ptr),y
        iny                     ; Y = #MGTK::Point::ycoord
        add16in map_delta_y, (ptr),y, (ptr),y

        jsr     PopPointers     ; do not tail-call optimize!
        rts
.endproc ; MapCoordsScreenToWindow

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

;;; Roughly follows:
;;; Technical Note: ProDOS #21: Identifying ProDOS Devices
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/pdos/tn.pdos.21.html

.proc GetDeviceTypeImpl
dib_buffer := $800
        DEFINE_SP_STATUS_PARAMS status_params, 1, dib_buffer, 3 ; Return Device Information Block (DIB)

        ;; Avoid Initializer memory ($800-$1200)
        block_buffer := $1E00

start:
        sta     block_params::unit_num

        ;; Special case for RAM.DRV.SYSTEM/RAMAUX.SYSTEM
    IF A IN #kRamDrvSystemUnitNum, #kRamAuxSystemUnitNum
        RETURN  AX=#str_device_type_ramdisk, Y=#IconType::ramdisk
    END_IF

        ;; Special case for VEDRIVE
        jsr     DeviceDriverAddress
        cmp     #<kVEDRIVEDriverAddress
        bne     :+
        cpx     #>kVEDRIVEDriverAddress
        bne     :+
vdrive: RETURN  AX=#str_device_type_vdrive, Y=#IconType::fileshare
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
        CALL    IsDiskII, A=block_params::unit_num
    IF ZS
        RETURN  AX=#str_device_type_diskii, Y=#IconType::floppy140
    END_IF

        ;; Look up driver address
        CALL    DeviceDriverAddress, A=block_params::unit_num ; Z=1 if $Cn
        bvs     is_sp
        bne     generic         ; not $CnXX, unknown type

        ;; Firmware driver; maybe SmartPort?
is_sp:  CALL    FindSmartportDispatchAddress, A=block_params::unit_num
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
    IF NOT_ZERO
      DO
        lda     dib_buffer+SPDIB::Device_Name-1,y
        BREAK_IF A <> #' '
        dey
      WHILE NOT_ZERO
    END_IF
        sty     dib_buffer+SPDIB::ID_String_Length
.endscope

.if kBuildSupportsLowercase
        ;; Case-adjust
.scope
        ldy     dib_buffer+SPDIB::ID_String_Length
    IF NOT_ZERO
        dey
      IF NOT_ZERO

        ;; Look at prior and current character; if both are alpha,
        ;; lowercase current.
       DO
        CALL    IsAlpha, A=dib_buffer+SPDIB::Device_Name-1,y ; Test previous character
        IF ZS
        CALL    IsAlpha, A=dib_buffer+SPDIB::Device_Name,y ; Adjust this one if also alpha
         IF ZS
        lda     dib_buffer+SPDIB::Device_Name,y
        ora     #AS_BYTE(~CASE_MASK) ; guarded by `kBuildSupportsLowercase`
        sta     dib_buffer+SPDIB::Device_Name,y
         END_IF
        END_IF
        dey
       WHILE NOT_ZERO
      END_IF
    END_IF
.endscope
.endif

        ;; Check device type
        ;; Technical Note: SmartPort #4: SmartPort Device Types
        ;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/smpt/tn.smpt.4.html
        lda     dib_buffer+SPDIB::Device_Type_Code
        ASSERT_EQUALS SPDeviceType::MemoryExpansionCard, 0
    IF ZERO                     ; $00 = Memory Expansion Card (RAM Disk)
        RETURN  AX=#dib_buffer+SPDIB::ID_String_Length, Y=#IconType::ramdisk
    END_IF

        cmp     #SPDeviceType::SCSICDROM
        bne     test_size
        RETURN  AX=#dib_buffer+SPDIB::ID_String_Length, Y=#IconType::cdrom

        ;; NOTE: Codes for 3.5" disk ($01) and 5-1/4" disk ($0A) are not trusted
        ;; since emulators do weird things.
        ;; TODO: Is that comment about false positives or false negatives?
        ;; i.e. if $01 or $0A is seen, can that be trusted?

not_sp:
        ;; Not SmartPort - try AppleTalk
        MLI_CALL READ_BLOCK, block_params
    IF A = #ERR_NETWORK_ERROR
        RETURN  AX=#str_device_type_appletalk, Y=#IconType::fileshare
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

        CALL    GetBlockCount, A=block_params::unit_num
    IF CC
        stax    blocks
        cmp16   blocks, #kMax525FloppyBlocks+1
        bcc     f525
        cmp16   blocks, #kMax35FloppyBlocks+1
        bcc     f35
    END_IF

        RETURN  AX=#dib_buffer+SPDIB::ID_String_Length, Y=#IconType::profile

f525:   RETURN  AX=#dib_buffer+SPDIB::ID_String_Length, Y=#IconType::floppy140

f35:    RETURN  AX=#dib_buffer+SPDIB::ID_String_Length, Y=#IconType::floppy800

        DEFINE_READWRITE_BLOCK_PARAMS block_params, block_buffer, kVolumeDirKeyBlock

blocks: .word   0

.endproc ; GetDeviceTypeImpl
GetDeviceType := GetDeviceTypeImpl::start

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

        CALL    GetFileInfo, AX=#path
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
        sta     unit_number     ; unmasked, for `GetDeviceType`
        sty     devlst_index
        and     #UNIT_NUM_MASK
        sta     on_line_params::unit_num
        MLI_CALL ON_LINE, on_line_params
    IF CS
error:
        pha                     ; A = error
        ldy     devlst_index    ; remove unit from list
        copy8   #0, device_to_icon_map,y
        pla                     ; A = error
        rts
    END_IF

        lda     cvi_data_buffer ; dr/slot/name_len
        and     #NAME_LENGTH_MASK
    IF ZERO
        lda     cvi_data_buffer+1 ; if name len is zero, second byte is error
        bne     error           ; always
    END_IF

        CALL    AdjustOnLineEntryCase, AX=#cvi_data_buffer
        jsr     _CompareNames
        bne     error           ; duplicate

        ;; --------------------------------------------------
        ;; Success, proceed with icon creation

        icon_ptr := $6
        icon_defn_ptr := $8
        offset := $A

        jsr     PushPointers

        ITK_CALL IconTK::AllocIcon, get_icon_entry_params
        inc     icon_count

        ;; Assign icon number
        lda     get_icon_entry_params::id
        ldy     devlst_index
        sta     device_to_icon_map,y
        inc     cached_window_icon_count
        ldx     cached_window_icon_count
        sta     cached_window_icon_list-1,x

        ;; Copy name
        copy16  get_icon_entry_params::addr, icon_ptr
        ldy     #IconEntry::name+kMaxFilenameLength
        ldx     #kMaxFilenameLength
    DO
        copy8   cvi_data_buffer,x, (icon_ptr),y
        dey
        dex
    WHILE POS

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
        copy8   #kIconEntryFlagsDropTarget, (icon_ptr),y

        ;; Invalid record
        ldy     #IconEntry::record_num
        copy8   #$FF, (icon_ptr),y

        ;; Assign icon coordinates
        devlst_index := *+1
        ldy     #SELF_MODIFIED_BYTE
        CALL    AllocDesktopIconPosition, A=device_to_icon_map,y
        txa
        asl                     ; * 4 = .sizeof(MGTK::Point)
        asl
        tax
        ldy     #IconEntry::iconx
    DO
        copy8   desktop_icon_coords_table,x, (icon_ptr),y
        inx
        iny
    WHILE Y <> #IconEntry::iconx + .sizeof(MGTK::Point)

        ;; Center it horizontally
        ldy     #IconResource::maprect + MGTK::Rect::x2
        copy16in (icon_defn_ptr),y, offset
        lsr16   offset          ; offset = (icon_width-1) / 2
        ldy     #IconEntry::iconx
        sub16in (icon_ptr),y, offset, (icon_ptr),y

        ;; Adjust vertically
        ldy     #IconResource::maprect + MGTK::Rect::y2
        copy16in (icon_defn_ptr),y, offset ; offset = (icon_height-1)
        ldy     #IconEntry::icony
        sub16in (icon_ptr),y, offset, (icon_ptr),y

        jsr     PopPointers
        RETURN  A=#0

;;; Compare a volume name against existing volume icons for drives.
;;; Inputs: String to compare against is in `cvi_data_buffer`
;;; Output: A=0 if not a duplicate, ERR_DUPLICATE_VOLUME if there is a duplicate.
.proc _CompareNames
        jsr     PushPointers
        copy16  #cvi_data_buffer, $06

        jsr     FindIconByNameInCachedWindow
    IF NOT_ZERO
        lda     #ERR_DUPLICATE_VOLUME
        bne     finish          ; always
    END_IF

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

        ldx     #AS_BYTE(-1)
    DO
        inx
        lda     desktop_icon_usage_table,x
    WHILE NOT_ZERO

        pla
        sta     desktop_icon_usage_table,x
        rts
.endproc ; AllocDesktopIconPosition

;;; Input: A = icon num
.proc FreeDesktopIconPosition
        ldx     #kMaxVolumes-1
    DO
        dex
    WHILE A <> desktop_icon_usage_table,x
        copy8   #0, desktop_icon_usage_table,x
        rts
.endproc ; FreeDesktopIconPosition

;;; ============================================================

.proc RemoveIconFromWindow
        ldx     cached_window_icon_count
        dex
    DO
        cmp     cached_window_icon_list,x
        beq     remove
        dex
    WHILE POS
        rts

remove:
        copy8   cached_window_icon_list+1,x, cached_window_icon_list,x
        inx
        cpx     cached_window_icon_count
        bne     remove
        dec     cached_window_icon_count
        rts
.endproc ; RemoveIconFromWindow

;;; ============================================================
;;; Search the window->dir_icon mapping table.
;;; Inputs: A = icon number
;;; Outputs: Z=1 && N=0 if found, X = index (0-7), A unchanged

.proc FindWindowIndexForDirIcon
        ldx     #kMaxDeskTopWindows-1
    DO
        BREAK_IF A = window_to_dir_icon_table,x
        dex
    WHILE POS
        rts
.endproc ; FindWindowIndexForDirIcon

;;; ============================================================

kMaxAnimationStep = 7

.proc AnimateWindowImpl
        rect_table := $800

        ENTRY_POINTS_FOR_BIT7_FLAG close, open, close_flag

        sta     icon_param
        txa                     ; A = window_id

        win_rect := rect_table + kMaxAnimationStep * .sizeof(MGTK::Rect)
        icon_rect := rect_table

    IF NS
        ;; --------------------------------------------------
        ;; Use desktop rect

        COPY_STRUCT MGTK::Rect, desktop_rect, win_rect
    ELSE
        ;; --------------------------------------------------
        ;; Get window rect

        ;; Note: can't use `MGTK::GetWinFrameRect` as the window
        ;; either doesn't exist yet or has already been closed.

        jsr     ApplyWinfoToWindowGrafport

        ;; Convert viewloc and maprect to bounding rect
        viewloc := window_grafport+MGTK::GrafPort::viewloc
        maprect := window_grafport+MGTK::GrafPort::maprect

        COPY_STRUCT MGTK::Point, viewloc, win_rect + MGTK::Rect::topleft
        ldx     #2              ; loop over dimensions
      DO
        sub16   maprect+MGTK::Rect::bottomright,x, maprect+MGTK::Rect::topleft,x, win_rect + MGTK::Rect::bottomright,x
        add16   win_rect + MGTK::Rect::topleft,x, win_rect + MGTK::Rect::bottomright,x, win_rect + MGTK::Rect::bottomright,x
        dex                     ; next dimension
        dex
      WHILE POS
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
    DO
        sub16   win_rect,y, icon_rect,y, delta

        ;; Iterate over all N animation steps
        ldx     #0              ; X = step
      DO
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
      WHILE X <> #kMaxAnimationStep-1

        iny
        iny
    WHILE Y <> #.sizeof(MGTK::Rect)

        ;; --------------------------------------------------
        ;; Animate it

        bit     close_flag
        bpl     _AnimateOpen
        bmi     _AnimateClose   ; always

close_flag:
        .byte   0

table:
        .repeat main::kMaxAnimationStep, i
        .byte   (main::kMaxAnimationStep - 1 - i) * .sizeof(MGTK::Rect)
        .endrepeat

        DEFINE_RECT desktop_rect, 0, kMenuBarHeight, kScreenWidth-1, kScreenHeight-1

.proc _AnimateOpen
        ;; Loop N = 0 to 13
        ;; If N in 0..11, draw N
        ;; If N in 2..13, erase N-2 (i.e. 0..11, 2 behind)

        copy8   #0, step
        jsr     InitSetDesktopPort

    DO
        MGTK_CALL MGTK::WaitVBL

        ;; If N in 0..11, draw N
        lda     step            ; draw the Nth
      IF A < #kMaxAnimationStep+1
        jsr     _FrameTableRect
      END_IF

        ;; If N in 2..13, erase N-2 (i.e. 0..11, 2 behind)
        lda     step
        sec
        sbc     #2              ; erase the (N-2)th
      IF POS
        jsr     _FrameTableRect
      END_IF

        inc     step
        step := *+1
        lda     #SELF_MODIFIED_BYTE
    WHILE A <> #kMaxAnimationStep+3
        rts
.endproc ; _AnimateOpen

;;; ============================================================

.proc _AnimateClose
        ;; Loop N = 11 to -2
        ;; If N in 0..11, draw N
        ;; If N in -2..9, erase N+2 (0..11, i.e. 2 behind)

        copy8   #kMaxAnimationStep, step
        jsr     InitSetDesktopPort

    DO
        MGTK_CALL MGTK::WaitVBL

        ;; If N in 0..11, draw N
        lda     step
      IF POS
        jsr     _FrameTableRect
      END_IF

        ;; If N in -2..9, erase N+2 (0..11, i.e. 2 behind)
        lda     step
        clc
        adc     #2
      IF A < #kMaxAnimationStep+1
        jsr     _FrameTableRect
      END_IF

        dec     step
        step := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     #AS_BYTE(-3)
    WHILE NE
        rts
.endproc ; _AnimateClose

;;; ============================================================

;;; Inputs: A = rect in `rect_table` to frame
.proc _FrameTableRect
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
    DO
        copy8   rect_table,x, tmp_rect,y
        dex
        dey
    WHILE POS

        FALL_THROUGH_TO FrameTmpRect
.endproc ; _FrameTableRect

.endproc ; AnimateWindowImpl
AnimateWindowClose      := AnimateWindowImpl::close
AnimateWindowOpen       := AnimateWindowImpl::open

;;; ============================================================

.proc FrameTmpRect
        ;; Skip if degenerate, to avoid cursor flashes
        ldx     #2              ; loop over dimensions
    DO
        ecmp16  tmp_rect::topleft,x, tmp_rect::bottomright,x
        beq     ret
        dex
        dex
    WHILE POS

        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        jsr     SetPenModeXOR
        MGTK_CALL MGTK::FrameRect, tmp_rect

ret:    rts
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
;;; Output: C=0, `operation_dst_path` populated with target path
;;;         C=1 on error (e.g. path too long); alert is shown
.proc SetOperationDstPathFromDragDropResult
        ;; Is drop on a window or an icon?
        ;; hi bit clear = target is an icon
        ;; hi bit set = target is a window; get window number
        lda     drag_drop_params::target
        bpl     target_is_icon

        ;; Drop is on a window
        and     #%01111111      ; get window id
        jsr     GetWindowPath
        jsr     CopyToOperationDstPath
        RETURN  C=0             ; success

        ;; Drop is on an icon.
target_is_icon:
        jsr     GetIconPath     ; `operation_src_path` set to path; A=0 on success
    IF NE
        jsr     ShowAlert
        RETURN  C=1             ; failure
    END_IF

        CALL    CopyToOperationDstPath, AX=#operation_src_path
        RETURN  C=0             ; success
.endproc ; SetOperationDstPathFromDragDropResult

;;; ============================================================

.scope operations

;;; ============================================================
;;; Operations where source/target paths are passed by callers

        kOperationFlagsNone         = %00000000
        kOperationFlagsCheckBadCopy = %01000000
        kOperationFlagsCheckVolFree = %10000000

;;; File > Duplicate - for a single file copy
;;; Caller sets `operation_src_path` (source) and `operation_dst_path` (destination)
.proc DoCopyFile
        copy8   #kOperationFlagsCheckBadCopy, operation_flags
        copy8   #0, move_flags
        tsx
        stx     saved_stack

        jsr     PrepTraversalCallbacksForEnumeration
        jsr     OpenCopyProgressDialog
        jsr     SetDstIsAppleShareFlag  ; uses `operation_dst_path`, may fail
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
        RETURN  A=#kOperationSucceeded

;;; Shortcuts > Run a Shortcut... w/ "Copy to RAMCard"/"at first use"
;;; Caller sets `operation_src_path` (source) and `operation_dst_path` (destination)
.proc DoCopyToRAM
        copy8   #0, move_flags
        copy8   #kOperationFlagsCheckVolFree, operation_flags
        CLEAR_BIT7_FLAG dst_is_appleshare_flag  ; by definition, not AppleShare
        tsx
        stx     saved_stack

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
;;; Caller sets `operation_dst_path` (destination)
.proc DoCopyOrMoveSelection
        lda     selected_window_id
    IF NOT_ZERO                 ; dragging volume always copies
        jsr     GetWindowPath
        jsr     CheckMoveOrCopy
    END_IF
        SKIP_NEXT_2_BYTE_INSTRUCTION

ep_always_copy:
        lda     #0              ; do not convert to `copy8`!

        sta     move_flags

        copy8   #kOperationFlagsCheckBadCopy, operation_flags
        tsx
        stx     saved_stack

        jsr     PrepTraversalCallbacksForEnumeration
        jsr     OpenCopyProgressDialog
        jsr     SetDstIsAppleShareFlag  ; uses `operation_dst_path`, may fail
        jmp     OperationOnSelection
.endproc ; DoCopyOrMoveSelection
DoCopySelection := DoCopyOrMoveSelection::ep_always_copy

;;; File > Delete
;;; Drag / Drop to Trash (except volumes)
.proc DoDeleteSelection
        copy8   #0, move_flags
        copy8   #kOperationFlagsNone, operation_flags
        tsx
        stx     saved_stack

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

    DO
        txa                     ; X = index
        pha                     ; A = index
        lda     selected_icon_list,x
      IF A <> trash_icon_num
        jsr     GetIconPath     ; `operation_src_path` set to path; A=0 on success
        jne     ShowErrorAlert  ; too long

        ;; During selection iteration, allow Escape to cancel the operation.
        jsr     CheckCancel

        ;; If copy, validate the source vs. target during enumeration phase
        ;; NOTE: Here rather than in `CopyProcessSelectedFile` because we don't
        ;; run this for copy using paths (i.e. Duplicate, Copy to RAMCard)
        bit     do_op_flag
       IF NC
        bit     operation_flags
        ASSERT_EQUALS operations::kOperationFlagsCheckBadCopy, $40
        IF VS
        jsr     CopyPathsFromBufsToSrcAndDst

        ;; Check for copying/moving an item into itself.
        copy16  #src_path_buf, $06
        copy16  #dst_path_buf, $08
        jsr     IsPathPrefixOf
         IF NE
        CALL    ShowAlertParams, Y=#AlertButtonOptions::OK, AX=#aux::str_alert_move_copy_into_self
        jmp     CloseFilesCancelDialogWithCanceledResult
         END_IF
        jsr     AppendSrcPathLastSegmentToDstPath

        ;; Check for replacing an item with itself or a descendant.
        copy16  #dst_path_buf, $06
        copy16  #src_path_buf, $08
        jsr     IsPathPrefixOf
         IF NE
        CALL    ShowAlertParams, Y=#AlertButtonOptions::OK, AX=#aux::str_alert_bad_replacement
        jmp     CloseFilesCancelDialogWithCanceledResult
         END_IF
        END_IF
       END_IF

        jsr     OpProcessSelectedFile
      END_IF

        pla                     ; A = index
        tax                     ; X = index
        inx
    WHILE X <> selected_icon_count

        ;; --------------------------------------------------

        ;; Done icons - did we complete the operation?
        bit     do_op_flag
    IF NS
        jsr     InvokeOperationCompleteCallback
        RETURN  A=#0
    END_IF

        ;; No, we finished enumerating. Now do the real work.
        jsr     InvokeOperationConfirmCallback
        jsr     InvokeOperationPrepTraversalCallback

        ;; And iterate selection again.
        jmp     iterate_selection

.endproc ; OperationOnSelection

;;; ============================================================

saved_stack:
        .byte   0


operation_flags:
        .byte   0

        ;; bit 7 set = move, clear = copy
        ;; bit 6 set = same volume move and relink supported
move_flags:
        .byte   0

        ;; bit 7 set = "all" selected in Yes / No / All prompt
all_flag:
        .byte   0

        ;; bit 7 set = destination is an AppleShare (network) drive
dst_is_appleshare_flag:
        .byte   0

;;; ============================================================

;;; Memory Map

;;; $BF00 - $FFFF   - ProDOS
;;; $__00 - $BEFF   - file data buffer
;;; $4000 - $__FF   - DeskTop code
;;; $2000 - $3FFF   - graphics page
;;; $1F80 - $1FFF   - dst path buffer
;;; $1600 - $1F7F   - unused
;;; $1500 - $15FF   - ON_LINE buffer
;;; $1100 - $14FF   - dst file I/O buffer
;;; $0D00 - $10FF   - src file I/O buffer
;;; $0C00 - $0CFF   - dir data buffer
;;; $0800 - $0BFF   - src dir I/O buffer
;;; ...

dir_io_buffer   :=  $800        ; 1024 bytes for I/O
dir_data_buffer :=  $C00        ; 256 bytes for directory data
src_io_buffer   :=  $D00        ; 1024 bytes for I/O
dst_io_buffer   := $1100        ; 1024 bytes for I/O
on_line_buffer  := $1500        ; 256 bytes for ON_LINE call

;;; Memory from end of this segment through ProDOS MLI entry point is
;;; used for the copy buffer. This is (currently) nearly twice the
;;; size of the free memory in the $1500 - $1E00 range, permitting
;;; faster copies.

copy_buffer := kSegmentDeskTopMainAddress + kSegmentDeskTopMainLength
kCopyBufferSize = ((MLI - copy_buffer) / BLOCK_SIZE) * BLOCK_SIZE

        .assert .lobyte(dir_io_buffer) = 0, error, "I/O buffers must be page-aligned"
        .assert .lobyte(src_io_buffer) = 0, error, "I/O buffers must be page-aligned"
        .assert .lobyte(dst_io_buffer) = 0, error, "I/O buffers must be page-aligned"
        .assert .lobyte(copy_buffer) = 0, error, "page-align copy buffer for better performance"
        .assert (kCopyBufferSize .mod BLOCK_SIZE) = 0, error, "integral number of blocks needed for sparse copies and performance"

        DEFINE_ON_LINE_PARAMS on_line_all_drives_params,, on_line_buffer

        block_buffer := copy_buffer
        DEFINE_READWRITE_BLOCK_PARAMS block_params, block_buffer, SELF_MODIFIED
        DEFINE_READWRITE_BLOCK_PARAMS vol_key_block_params, block_buffer, kVolumeDirKeyBlock

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
PAD_IF_NEEDED_TO_AVOID_PAGE_BOUNDARY 4
operation_lifecycle_callbacks:
operation_enumeration_callback: .addr   SELF_MODIFIED
operation_complete_callback:    .addr   SELF_MODIFIED
operation_confirm_callback:     .addr   SELF_MODIFIED
operation_prep_callback:        .addr   SELF_MODIFIED
        kOpLifecycleCallbacksSize = * - operation_lifecycle_callbacks

;;; NOTE: These are referenced by indirect JMP and *must not*
;;; cross page boundaries.
PAD_IF_NEEDED_TO_AVOID_PAGE_BOUNDARY 3
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

;;; bit7=0 for count/size pass, bit7=1 for actual operation
do_op_flag:
        .byte   0

;;; ============================================================
;;; Generic Recursive Operation Logic
;;; ============================================================

;;; TODO: Unify with `../lib/recursive_copy.s`

pathname_src := src_path_buf
pathname_dst := dst_path_buf

OpCheckCancel := CheckCancel
OpCheckRetry  := CheckRetry
OpUpdateCopyProgress := CopyUpdateProgress

::kCopyCheckSpaceAvailable = 1
::kCopyInteractive = 1
::kCopyCheckAppleShare = 1
::kCopyValidateStorageType = 1
::kCopySupportMove = 1
::kCopyUseOwnSetDstInfo = 1
::kCopyCaseBits = 1

;;; ============================================================
;;; Directory enumeration parameter blocks and state

        ;; 4 bytes is .sizeof(SubdirectoryHeader) - .sizeof(FileEntry)
        kBlockPointersSize = 4
        ;; Blocks are 512 bytes, 13 entries of 39 bytes each leaves 5 bytes between.
        ;; Except first block, directory header is 39+4 bytes, leaving 1 byte, but then
        ;; block pointers are the next 4.
        kMaxPaddingBytes = 5

        ASSERT_EQUALS .sizeof(SubdirectoryHeader) - .sizeof(FileEntry), kBlockPointersSize

PARAM_BLOCK, dir_data_buffer
;;; Read buffers
buf_block_pointers      .res    kBlockPointersSize
buf_padding_bytes       .res    kMaxPaddingBytes
file_entry              .tag    FileEntry

;;; State for directory recursion
recursion_depth         .byte   ; How far down the directory structure are we
entries_per_block       .byte   ; Number of file entries per directory block
entry_index_in_dir      .word
target_index            .word

;;; During directory traversal, the number of file entries processed
;;; at the current level is pushed here, so that following a descent
;;; the previous entries can be skipped.
index_stack_lo          .res    ::kDirStackSize
index_stack_hi          .res    ::kDirStackSize
stack_index             .byte

entry_index_in_block    .byte
dir_data_buffer_end     .byte

src_vol_devnum          .byte
dst_vol_blocks_free     .word
END_PARAM_BLOCK

        .assert dir_data_buffer_end - dir_data_buffer <= 256, error, "too big"

        DEFINE_OPEN_PARAMS open_src_dir_params, pathname_src, dir_io_buffer
        DEFINE_READWRITE_PARAMS read_block_pointers_params, buf_block_pointers, kBlockPointersSize ; For skipping prev/next pointers in directory data
        DEFINE_READWRITE_PARAMS read_src_dir_entry_params, file_entry, .sizeof(FileEntry)
        DEFINE_READWRITE_PARAMS read_padding_bytes_params, buf_padding_bytes, kMaxPaddingBytes
        DEFINE_CLOSE_PARAMS close_src_dir_params

;;; ============================================================
;;; Iterate directory entries
;;; Inputs: `pathname_src` points at source directory

.proc ProcessDirectory
        lda     #0
        sta     recursion_depth
        sta     stack_index

        jsr     _OpenSrcDir
loop:
        jsr     _ReadFileEntry
    IF ZERO
        CALL    AdjustFileEntryCase, AX=#file_entry

        lda     file_entry + FileEntry::storage_type_name_length
        beq     loop            ; deleted
        pha                     ; A = `storage_type_name_length`

        ;; Requires `storage_type_name_length` to be intact
        jsr     _ConvertFileEntryToFileInfo

        ;; Simplify to length-prefixed string
        pla                     ; A = `storage_type_name_length`
        and     #NAME_LENGTH_MASK
        sta     file_entry

        jsr     OpCheckCancel

        CLEAR_BIT7_FLAG entry_err_flag
        jsr     OpProcessDirectoryEntry
        bit     entry_err_flag  ; don't recurse if the copy failed
        bmi     loop

        lda     file_entry + FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     loop            ; and don't recurse unless it's a directory

        ;; Recurse into child directory
        jsr     _DescendDirectory
        inc     recursion_depth
        bpl     loop            ; always
    END_IF

        lda     recursion_depth
    IF NOT_ZERO
        jsr     _AscendDirectory
        dec     recursion_depth
        bpl     loop            ; always
    END_IF

        jmp     _CloseSrcDir
.endproc ; ProcessDirectory

;;; Set on error during copying of a single file
entry_err_flag: .byte   0       ; bit7

;;; ============================================================

;;; Populate `src_file_info_params` from `file_entry`

.proc _ConvertFileEntryToFileInfo
        ldx     #kMapSize-1
    DO
        ldy     map,x
        copy8   file_entry,y, src_file_info_params::access,x
        dex
    WHILE POS

        ;; Fix `storage_type`
        ldx     #4
    DO
        lsr     src_file_info_params::storage_type
        dex
    WHILE NOT_ZERO

        rts

;;; index is offset in `src_file_info_params`, value is offset in `file_entry`
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
.endproc ; _ConvertFileEntryToFileInfo

;;; ============================================================

.proc _PushIndexToStack
        ldx     stack_index
        copy8   target_index, index_stack_lo,x
        copy8   target_index+1, index_stack_hi,x
        inc     stack_index
        rts
.endproc ; _PushIndexToStack

;;; ============================================================

.proc _PopIndexFromStack
        dec     stack_index
        ldx     stack_index
        copy8   index_stack_lo,x, target_index
        copy8   index_stack_hi,x, target_index+1
        rts
.endproc ; _PopIndexFromStack

;;; ============================================================
;;; Open the source directory for reading, skipping header.
;;; Inputs: `pathname_src` set to dir

.proc _OpenSrcDir
        lda     #0
        sta     entry_index_in_dir
        sta     entry_index_in_dir+1
        sta     entry_index_in_block

retry:  MLI_CALL OPEN, open_src_dir_params
    IF CS
.if ::kCopyInteractive
        jsr     OpCheckRetry
        beq     retry           ; always
.else
        .refto retry
fail:   jmp     OpHandleErrorCode
.endif
    END_IF

        lda     open_src_dir_params::ref_num
        sta     read_block_pointers_params::ref_num
        sta     read_src_dir_entry_params::ref_num
        sta     read_padding_bytes_params::ref_num
        sta     close_src_dir_params::ref_num

        ;; Skip over prev/next block pointers in header
retry2: MLI_CALL READ, read_block_pointers_params
.if ::kCopyInteractive
    IF CS
        jsr     OpCheckRetry
        beq     retry2          ; always
    END_IF
.else
        .refto retry2
        bcs     fail
.endif

        ;; Header size is next/prev blocks + a file entry
        copy8   #13, entries_per_block ; so `_ReadFileEntry` doesn't immediately advance
        jsr     _ReadFileEntry         ; read the rest of the header

        ASSERT_EQUALS .sizeof(SubdirectoryHeader), .sizeof(FileEntry) + 4
        copy8   file_entry-4 + SubdirectoryHeader::entries_per_block, entries_per_block

        rts
.endproc ; _OpenSrcDir

;;; ============================================================

.proc _CloseSrcDir
retry:  MLI_CALL CLOSE, close_src_dir_params
    IF CS
.if ::kCopyInteractive
        jsr     OpCheckRetry
        beq     retry           ; always
.else
        .refto retry
        jmp     OpHandleErrorCode
.endif
    END_IF
        rts
.endproc ; _CloseSrcDir

;;; ============================================================
;;; Read the next file entry in the directory into `file_entry`
;;; NOTE: Also used to read the vol/dir header.

.proc _ReadFileEntry
        inc16   entry_index_in_dir

retry:  MLI_CALL READ, read_src_dir_entry_params
    IF CS
        cmp     #ERR_END_OF_FILE
        beq     eof

.if ::kCopyInteractive
        jsr     OpCheckRetry
        beq     retry           ; always
.else
        .refto retry
fail:   jmp     OpHandleErrorCode
.endif
    END_IF

        inc     entry_index_in_block
        lda     entry_index_in_block
    IF A >= entries_per_block
        ;; Advance to first entry in next "block"
        copy8   #0, entry_index_in_block
retry2: MLI_CALL READ, read_padding_bytes_params
.if ::kCopyInteractive
      IF CS
        jsr     OpCheckRetry
        beq     retry2          ; always
      END_IF
.else
        .refto retry2
        bcs     fail
.endif
    END_IF

        RETURN  A=#0

eof:    RETURN  A=#$FF
.endproc ; _ReadFileEntry

;;; ============================================================
;;; Record the current index in the current directory, and
;;; recurse to the child directory in `file_entry`.

.proc _DescendDirectory
        copy16  entry_index_in_dir, target_index
        jsr     _CloseSrcDir
        jsr     _PushIndexToStack
        jsr     AppendFileEntryToSrcPath
        jmp     _OpenSrcDir
.endproc ; _DescendDirectory

;;; ============================================================
;;; Close the current directory and resume iterating in the
;;; parent directory where we left off.

.proc _AscendDirectory
        jsr     _CloseSrcDir
        jsr     OpFinishDirectory
        jsr     RemoveSrcPathSegment
        jsr     _PopIndexFromStack
        jsr     _OpenSrcDir

:       cmp16   entry_index_in_dir, target_index
    IF LT
        jsr     _ReadFileEntry
        jmp     :-
    END_IF

        rts
.endproc ; _AscendDirectory

;;; ============================================================
;;; Append name at `file_entry` to path at `pathname_src`

.proc AppendFileEntryToSrcPath
        TAIL_CALL AppendFilenameToSrcPath, AX=#file_entry
.endproc ; AppendFileEntryToSrcPath

;;; ============================================================
;;; Remove segment from path at `pathname_src`

.proc RemoveSrcPathSegment
        TAIL_CALL RemovePathSegment, AX=#pathname_src
.endproc ; RemoveSrcPathSegment

;;; ============================================================
;;; Append name at `file_entry` to path at `pathname_dst`

.proc AppendFileEntryToDstPath
        TAIL_CALL AppendFilenameToDstPath, AX=#file_entry
.endproc ; AppendFileEntryToDstPath

;;; ============================================================
;;; Remove segment from path at `pathname_dst`

.proc RemoveDstPathSegment
        TAIL_CALL RemovePathSegment, AX=#pathname_dst
.endproc ; RemoveDstPathSegment

;;; ============================================================
;;; Remove segment from path at A,X
;;; Input: A,X = path to modify
;;; Output: A = length
;;; Trashes $06

.proc RemovePathSegment
        path_ptr := $06
        stax    path_ptr

        ldy     #0
        lda     (path_ptr),y    ; length
    IF NOT_ZERO
        tay
      DO
        lda     (path_ptr),y
        cmp     #'/'
        beq     :+
        dey
      WHILE NOT_ZERO
        iny
:
        dey
        tya
        ldy     #0
        sta     (path_ptr),y
    END_IF

        rts
.endproc ; RemovePathSegment

;;; ============================================================
;;; Generic Helpers
;;; ============================================================

;;; Verify that file is not forked (etc); if it is an OK/Cancel alert is shown.
;;; If the user selects cancel, the operation is cancelled.
;;;
;;; Input: A=`storage_type`
;;; Output: C=0 if supported type, C=1 if unsupported but user picks OK.
;;; Exception: If user selects Cancel, `CloseFilesCancelDialogWithFailedResult` is invoked.
;;; Assert: Type is not `ST_VOLUME_DIRECTORY` or `ST_LINKED_DIRECTORY`
.proc ValidateStorageType
    IF A >= #ST_TREE_FILE+1     ; only seedling/sapling/tree supported
        ;; Unsupported type - show error, and either abort or return failure
        CALL    ShowAlertParams, Y=#AlertButtonOptions::OKCancel, AX=#aux::str_alert_unsupported_type
        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialogWithFailedResult
        RETURN  C=1
    END_IF

        ;; Return success
        RETURN  C=0
.endproc ; ValidateStorageType

;;; ============================================================

;;; Input: Destination path in `operation_dst_path`
;;; Output: `dst_is_appleshare_flag` is set
.proc SetDstIsAppleShareFlag
        CLEAR_BIT7_FLAG dst_is_appleshare_flag

        ;; Issue a `GET_FILE_INFO` on destination to set `DEVNUM`
retry:  CALL    GetFileInfo, AX=#operation_dst_path
    IF CS
        jsr     ShowErrorAlertDst
        jmp     retry
    END_IF

        ;; Try to read a block off device; if AppleShare will fail.
        copy8   DEVNUM, vol_key_block_params::unit_num
        MLI_CALL READ_BLOCK, vol_key_block_params
    IF A = #ERR_NETWORK_ERROR
        SET_BIT7_FLAG dst_is_appleshare_flag
    END_IF
        rts
.endproc ; SetDstIsAppleShareFlag

;;; ============================================================
;;; "Copy" (including Drag/Drop/Move) files state and logic
;;; ============================================================

;;; ============================================================
;;; File copy parameter blocks

.if ::kCopySupportMove
        ;; Also used by "Delete"
        DEFINE_DESTROY_PARAMS destroy_src_params, pathname_src
.endif
.if ::kCopyInteractive
        DEFINE_DESTROY_PARAMS destroy_dst_params, pathname_dst
.endif

        ;; Used for both files and directories
        DEFINE_CREATE_PARAMS create_params, pathname_dst, ACCESS_DEFAULT

        DEFINE_OPEN_PARAMS open_src_params, pathname_src, src_io_buffer
        DEFINE_OPEN_PARAMS open_dst_params, pathname_dst, dst_io_buffer
        DEFINE_READWRITE_PARAMS read_src_params, copy_buffer, kCopyBufferSize
        DEFINE_READWRITE_PARAMS write_dst_params, copy_buffer, kCopyBufferSize
.if ::kCopyInteractive
        DEFINE_SET_MARK_PARAMS mark_src_params, 0
.endif
        DEFINE_SET_MARK_PARAMS mark_dst_params, 0
        DEFINE_CLOSE_PARAMS close_src_params
        DEFINE_CLOSE_PARAMS close_dst_params


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
        jsr     SetPortForProgressDialog
        bit     move_flags
    IF NC
        CALL    DrawProgressDialogLabel, Y=#0, AX=#aux::str_copy_copying
    ELSE
        CALL    DrawProgressDialogLabel, Y=#0, AX=#aux::str_move_moving
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

        CLEAR_BIT7_FLAG operations::all_flag
        SET_BIT7_FLAG do_op_flag
        rts
.endproc ; PrepTraversalCallbacksForCopy

;;; ============================================================
;;; "Download" - shares heavily with Copy

.proc PrepTraversalCallbacksForDownload
        COPY_BYTES kOpTraversalCallbacksSize, operation_traversal_callbacks_for_copy, operation_traversal_callbacks

        SET_BIT7_FLAG operations::all_flag
        SET_BIT7_FLAG do_op_flag
        rts
.endproc ; PrepTraversalCallbacksForDownload

;;; ============================================================
;;; Handle copying of a file.
;;; Calls into the recursion logic of `ProcessDirectory` as necessary.

;;; Used for these operations:
;;; * File > Duplicate (via `not_selected` entry point) - operates on passed path, `operation_flags` = `kOperationFlagsCheckBadCopy`
;;; * Run a Shortcut (via `not_selected` entry point) - operates on passed path, `operation_flags` = `kOperationFlagsCheckVolFree`
;;; * File > Copy To - operates on selection, `operation_flags` = `kOperationFlagsCheckBadCopy`
;;; * Drag/Drop (to non-Trash) - operates on selection, `operation_flags` = `kOperationFlagsCheckBadCopy`

.proc CopyProcessFileImpl
        ENTRY_POINTS_FOR_BIT7_FLAG selected, not_selected, use_selection_flag

        jsr     CopyPathsFromBufsToSrcAndDst

        use_selection_flag := *+1
        lda     #SELF_MODIFIED_BYTE
    IF NS
        ;; File > Copy To...
        ;; Drag/Drop

        ;; Use last segment of source for destination (e.g. for Copy/Move)
        jsr     AppendSrcPathLastSegmentToDstPath
    ELSE
        ;; File > Duplicate
        ;; Shortcuts > Run a Shortcut...

        ;; Used passed filename for destination (e.g. for Duplicate)
        CALL    AppendFilenameToDstPath, AX=#filename_buf
    END_IF

        ;; Paths are set up - update dialog
        jsr     OpUpdateCopyProgress

        ;; Populate `src_file_info_params`
retry:  jsr     GetSrcFileInfo
    IF CS
        jsr     ShowErrorAlert
        jmp     retry
    END_IF
        copy8   DEVNUM, src_vol_devnum

        jsr     _RecordDestVolBlocksFree

        ;; If "Copy to RAMCard", make sure there's enough room.
        bit     operations::operation_flags
        ASSERT_EQUALS operations::kOperationFlagsCheckVolFree, $80
    IF NS
        cmp16   dst_vol_blocks_free, block_count
      IF LT
        CALL    ShowAlertParams, Y=#AlertButtonOptions::OK, AX=#aux::str_ramcard_full
        jmp     CloseFilesCancelDialogWithFailedResult
      END_IF
    END_IF

        ;; Regular file or directory?
        lda     src_file_info_params::storage_type
    IF A NOT_IN #ST_VOLUME_DIRECTORY, #ST_LINKED_DIRECTORY

        ;; --------------------------------------------------
        ;; File

        jsr     ValidateStorageType
        bcs     done

        jsr     _CopyCreateFile
        bcs     done

        bit     move_flags      ; same volume relink move?
      IF VS
        jmp     RelinkFile
      END_IF

        jsr     _CopyNormalFile
        jmp     MaybeFinishFileMove
    END_IF

        ;; --------------------------------------------------
        ;; Directory

        jsr     _CopyCreateFile
        bcs     done

        bit     move_flags      ; same volume relink move?
    IF VS
        jsr     RelinkFile
        jmp     NotifyPathChanged
    END_IF

        ;; Copy directory contents
        jsr     ProcessDirectory
        jsr     GetAndApplySrcInfoToDst ; copy modified date/time
        jsr     MaybeFinishFileMove

        bit     move_flags
    IF NS
        jsr     NotifyPathChanged
    END_IF

done:
        rts
.endproc ; CopyProcessFileImpl

;;; Operations on selection (e.g. drag/drop, File > Copy To..., etc)
CopyProcessSelectedFile := CopyProcessFileImpl::selected

;;; Operations on paths (e.g. File > Duplicate, Copy to RAMCard, etc)
CopyProcessNotSelectedFile := CopyProcessFileImpl::not_selected

;;; ============================================================
;;; Called by `ProcessDirectory` to process a single file
;;; Inputs: `file_entry` populated with `FileEntry`
;;;         `src_file_info_params` populated
;;;         `pathname_src` has source directory path
;;;         `pathname_dst` has destination directory path

.proc CopyProcessDirectoryEntry
        jsr     AppendFileEntryToDstPath
        jsr     AppendFileEntryToSrcPath
        jsr     OpUpdateCopyProgress

        ;; Called with `src_file_info_params` pre-populated
        lda     src_file_info_params::storage_type
    IF A <> #ST_LINKED_DIRECTORY

        ;; --------------------------------------------------
        ;; File

.if ::kCopyValidateStorageType
        jsr     ValidateStorageType
        bcs     done
.endif

        jsr     _CopyCreateFile
        bcs     done

        jsr     _CopyNormalFile
.if ::kCopySupportMove
        jsr     MaybeFinishFileMove
.endif

    ELSE

        ;; --------------------------------------------------
        ;; Directory

        jsr     _CopyCreateFile
        bcc     ok_dir          ; leave dst path segment in place for recursion
        SET_BIT7_FLAG entry_err_flag

    END_IF

        ;; --------------------------------------------------

done:   jsr     RemoveDstPathSegment
ok_dir: jsr     RemoveSrcPathSegment
        rts
.endproc ; CopyProcessDirectoryEntry

;;; ============================================================
;;; Record the number of blocks free on the destination volume.
;;; Input: `pathname_dst` is path on destination volume
;;; Output: `dst_vol_blocks_free` has the free block count

.if ::kCopyCheckSpaceAvailable
.proc _RecordDestVolBlocksFree
        ;; Isolate destination volume name
        lda     pathname_dst
        pha                     ; A = `pathname_dst` saved length

        ;; Strip to vol name - either end of string or next slash
        CALL    MakeVolumePath, AX=#pathname_dst

        ;; Get total blocks/used blocks on destination volume
retry:  MLI_CALL GET_FILE_INFO, dst_file_info_params
.if ::kCopyInteractive
    IF NOT_ZERO
        jsr     ShowErrorAlertDst
        jmp     retry
    END_IF
.else
        .refto retry
        jcs     OpHandleErrorCode
.endif

        ;; Free = Total (aux) - Used
        sub16   dst_file_info_params::aux_type, dst_file_info_params::blocks_used, dst_vol_blocks_free

        pla                     ; A = `pathname_dst` saved length
        sta     pathname_dst
        rts
.endproc ; _RecordDestVolBlocksFree
.endif

;;; ============================================================
;;; Used when copying a single file.
;;; Inputs: `src_file_info_params` is populated; `pathname_dst` is target
;;; and `_RecordDestVolBlocksFree` has been called.

.proc _CheckSpaceAvailable

        ;; Copying a volume? If so, `src_file_info_params` has total
        ;; blocks used on the volume, which isn't useful for an
        ;; incremental copy.
        lda     src_file_info_params::storage_type
    IF A = #ST_VOLUME_DIRECTORY
        RETURN  C=0
    END_IF

        ;; --------------------------------------------------
        ;; Check how much space might be reclaimed if we're
        ;; overwriting an existing file.

        copy16  #0, dst_file_info_params::blocks_used
retry:  jsr     GetDstFileInfo
    IF CS
      IF A <> #ERR_FILE_NOT_FOUND
        jsr     ShowErrorAlertDst
        jmp     retry
      END_IF
    END_IF

        ;; --------------------------------------------------
        ;; Check if there is enough room

        blocks_free := $06

        add16   dst_vol_blocks_free, dst_file_info_params::blocks_used, blocks_free
        cmp16   blocks_free, src_file_info_params::blocks_used
    IF GE
        ;; Assume those blocks will be used
        sub16   blocks_free, src_file_info_params::blocks_used, dst_vol_blocks_free
        RETURN  C=0
    END_IF

        ;; --------------------------------------------------
        ;; Show appropriate message

        ldax    #aux::str_large_copy_prompt
        bit     move_flags
    IF NS
        ldax    #aux::str_large_move_prompt
    END_IF
        CALL    ShowAlertParams, Y=#AlertButtonOptions::OKCancel ; A,X = string
        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialogWithFailedResult

        RETURN  C=1
.endproc ; _CheckSpaceAvailable

;;; ============================================================
;;; If moving, delete src file/directory.

.proc CopyFinishDirectory
        jsr     GetAndApplySrcInfoToDst ; apply modification date/time
        jsr     RemoveDstPathSegment
        FALL_THROUGH_TO MaybeFinishFileMove
.endproc ; CopyFinishDirectory

.proc MaybeFinishFileMove
        ;; Copy or move?
        bit     move_flags
    IF NS
        ;; Was a move - delete file
retry:  MLI_CALL DESTROY, destroy_src_params
      IF CS
       IF A = #ERR_ACCESS_ERROR
        jsr     UnlockSrcFile
        beq     retry
        rts                     ; silently leave file
       END_IF

        jsr     ShowErrorAlert
        jmp     retry
      END_IF
    END_IF
        rts
.endproc ; MaybeFinishFileMove

;;; ============================================================

.proc CopyUpdateProgress
        jsr     DecrementFileCount
        jsr     SetPortForProgressDialog

        CALL    CopyToBuf0, AX=#src_path_buf
        CALL    DrawProgressDialogLabel, Y=#1, AX=#aux::str_copy_from
        jsr     DrawTargetFilePath

        CALL    CopyToBuf0, AX=#dst_path_buf
        CALL    DrawProgressDialogLabel, Y=#2, AX=#aux::str_copy_to
        jsr     DrawDestFilePath

        jmp     DrawProgressDialogFilesRemaining
.endproc ; CopyUpdateProgress

;;; ============================================================
;;; Common implementation used by both `CopyProcessSelectedFile`
;;; and `CopyProcessDirectoryEntry`
;;; Output: C=0 on success, C=1 on failure

.proc _CopyCreateFile
        ;; Check space if we didn't pre-flight via enumeration,
        ;; and we're not just doing a relink.
        bit     operations::operation_flags
        ASSERT_EQUALS operations::kOperationFlagsCheckVolFree, $80
    IF NC
        bit     move_flags      ; same volume relink move?
      IF VC
        ;; No, verify that there is room.
        jsr     _CheckSpaceAvailable
        RTS_IF CS
      END_IF
    END_IF

        ;; Copy `file_type`, `aux_type`, and `storage_type`
        COPY_BYTES src_file_info_params::storage_type - src_file_info_params::file_type + 1, src_file_info_params::file_type, create_params::file_type

        ;; Copy `create_date`/`create_time`
        COPY_STRUCT DateTime, src_file_info_params::create_date, create_params::create_date

.if ::kCopyCaseBits
        jsr     _ReadSrcCaseBits
.endif

        ;; If source is volume, create directory instead
        lda     create_params::storage_type
    IF A = #ST_VOLUME_DIRECTORY
        copy8   #ST_LINKED_DIRECTORY, create_params::storage_type
    END_IF

        ;; --------------------------------------------------
        ;; Create the file

retry:
        MLI_CALL CREATE, create_params
    IF CS
      IF A <> #ERR_DUPLICATE_FILENAME
        jsr     ShowErrorAlertDst
        jmp     retry
      END_IF

.if ::kCopyInteractive
        ;; File exists
        jsr     GetDstFileInfo
      IF CS
        jsr     ShowErrorAlertDst
        jmp     retry
      END_IF

        ;; Directory?
        lda     dst_file_info_params::storage_type
      IF A = #ST_LINKED_DIRECTORY
        ;; TODO: Prompt and recursively delete
        CALL    ShowAlertParams, Y=#AlertButtonOptions::OK, AX=#aux::str_no_overwrite_dir
        jmp     CloseFilesCancelDialogWithFailedResult
      END_IF

        ;; Regular file - prompt to replace
        bit     operations::all_flag
      IF NC
        CALL    ShowAlertParams, Y=#AlertButtonOptions::YesNoAllCancel, AX=#aux::str_exists_prompt

        cmp     #kAlertResultNo
        beq     failure

        cmp     #kAlertResultCancel
        jeq     CloseFilesCancelDialogWithFailedResult

        cmp     #kAlertResultAll
       IF EQ
        SET_BIT7_FLAG operations::all_flag
       END_IF
      END_IF

retry2: MLI_CALL DESTROY, destroy_dst_params
      IF CS
       IF A = #ERR_ACCESS_ERROR
        jsr     UnlockDstFile
        beq     retry2
       END_IF
        jsr     ShowErrorAlertDst
        jmp     retry2
      END_IF
.endif

        jmp     retry
    END_IF

        ;; --------------------------------------------------

.if ::kCopyCaseBits
        lda     case_bits
        ora     case_bits+1
    IF NOT_ZERO
        jsr     _WriteDstCaseBits
    END_IF
.endif
        RETURN  C=0

        ;; --------------------------------------------------

failure:
        RETURN  C=1

;;; ============================================================
;;; Case Bits
;;; Input: `src_file_info_params` pre-populated

.proc _ReadSrcCaseBits
        copy16  #0, case_bits   ; best effort

        lda     src_file_info_params::storage_type
    IF A = #ST_VOLUME_DIRECTORY
        ;; Volume
        copy8   src_vol_devnum, vol_key_block_params::unit_num
        MLI_CALL READ_BLOCK, vol_key_block_params
        bcs     ret
        copy16  block_buffer + VolumeDirectoryHeader::case_bits, case_bits
    ELSE
        ;; File
        CALL    GetFileEntryBlock, AX=#src_path_buf ; leaves $06 pointing at `FileEntry`
        bcs     ret
        entry_ptr := $06
        ldy     #FileEntry::case_bits
        copy16in (entry_ptr),y, case_bits
    END_IF

        clc                     ; success
ret:    rts
.endproc ; _ReadSrcCaseBits

.proc _WriteDstCaseBits
        CALL    GetFileEntryBlock, AX=#dst_path_buf
        bcs     ret
        stax    block_params::block_num

        block_ptr := $06
        CALL    GetFileEntryBlockOffset, AX=#block_buffer ; Y is already the entry number
        stax    block_ptr

        copy8   DEVNUM, block_params::unit_num
        MLI_CALL READ_BLOCK, block_params
        bcs     ret
        ldy     #FileEntry::case_bits
        copy16in case_bits, (block_ptr),y
        MLI_CALL WRITE_BLOCK, block_params

ret:    rts
.endproc ; _WriteDstCaseBits

.endproc ; _CopyCreateFile

;;; ============================================================
;;; Relink - swaps source and target, then deletes source.
;;;
;;; Assert: `_CopyCreateFile` has succeeded

.proc RelinkFileImpl
        src_block := $800
        dst_block := $A00

        DEFINE_READWRITE_BLOCK_PARAMS src_block_params, src_block, 0
        DEFINE_READWRITE_BLOCK_PARAMS dst_block_params, dst_block, 0
src_entry_num:  .byte   0
dst_entry_num:  .byte   0

Start:  lda     DEVNUM
        sta     src_block_params::unit_num
        sta     dst_block_params::unit_num

        ;; --------------------------------------------------
        ;; Locate the source/destination directory blocks

:
        CALL    GetFileEntryBlock, AX=#src_path_buf
    IF CS
        CALL    ShowErrorAlert, A=#ERR_PATH_NOT_FOUND
        jmp     :-
    END_IF
        stax    src_block_params::block_num
        sty     src_entry_num
:
        CALL    GetFileEntryBlock, AX=#dst_path_buf
    IF CS
        CALL    ShowErrorAlert, A=#ERR_PATH_NOT_FOUND
        jmp     :-
    END_IF
        stax    dst_block_params::block_num
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
        CALL    GetFileEntryBlockOffset, AX=#src_block, Y=src_entry_num
        stax    src_ptr

        CALL    GetFileEntryBlockOffset, AX=#dst_block, Y=dst_entry_num
        stax    dst_ptr

        ;; Swap everything but `header_pointer`
        ldy     #FileEntry::header_pointer-1
    DO
        swap8   (src_ptr),y, (dst_ptr),y
        dey
    WHILE POS

        ;; --------------------------------------------------
        ;; Write out the updated blocks

        jsr     _WriteBlocks

        ;; --------------------------------------------------
        ;; If a subdirectory, need to modify parent links

        ldy     #FileEntry::storage_type_name_length
        lda     (src_ptr),y
        and     #STORAGE_TYPE_MASK
    IF A = #ST_LINKED_DIRECTORY<<4
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
      DO
        swap8   src_block + SubdirectoryHeader::parent_pointer,x, dst_block + SubdirectoryHeader::parent_pointer,x
        dex
      WHILE POS

        ;; Write out the updated key blocks
        jsr     _WriteBlocks
    END_IF

        ;; --------------------------------------------------
        ;; Delete the file at the source location.

:       MLI_CALL DESTROY, destroy_src_params
    IF CS
        jsr     ShowErrorAlert
        jmp     :-
    END_IF
        rts

;;; --------------------------------------------------

.proc _ReadBlocks
:       MLI_CALL READ_BLOCK, src_block_params
    IF CS
        jsr     ShowErrorAlert
        jmp     :-
    END_IF

:       MLI_CALL READ_BLOCK, dst_block_params
    IF CS
        jsr     ShowErrorAlert
        jmp     :-
    END_IF

        rts
.endproc ; _ReadBlocks

;;; --------------------------------------------------

.proc _WriteBlocks
:       MLI_CALL WRITE_BLOCK, src_block_params
    IF CS
        jsr     ShowErrorAlert
        jmp     :-
    END_IF

:       MLI_CALL WRITE_BLOCK, dst_block_params
    IF CS
        jsr     ShowErrorAlert
        jmp     :-
    END_IF

        rts
.endproc ; _WriteBlocks

.endproc ; RelinkFileImpl
        RelinkFile := RelinkFileImpl::Start

;;; ============================================================
;;; Actual byte-for-byte file copy routine

.proc _CopyNormalFile
        lda     #0
        sta     mark_dst_params::position
        sta     mark_dst_params::position+1
        sta     mark_dst_params::position+2
.if ::kCopyInteractive
        sta     src_dst_exclusive_flag
        sta     mark_src_params::position
        sta     mark_src_params::position+1
        sta     mark_src_params::position+2
.endif

        jsr     _OpenSrc
.if ::kCopyInteractive
        jsr     _OpenDstOrFail
    IF NOT_ZERO
        ;; Destination not available; note it, can prompt later
        SET_BIT7_FLAG src_dst_exclusive_flag
    END_IF
.else
        jsr     _OpenDst
.endif

        ;; Read a chunk
    DO
        copy16  #kCopyBufferSize, read_src_params::request_count
        jsr     OpCheckCancel

retry:  MLI_CALL READ, read_src_params
      IF CS
        cmp     #ERR_END_OF_FILE
        beq     close
.if ::kCopyInteractive
        jsr     ShowErrorAlert
        jmp     retry
.else
        .refto retry
fail:   jmp     OpHandleErrorCode
.endif
      END_IF

.if ::kCopyInteractive
        bit     src_dst_exclusive_flag
      IF NS
        ;; Swap
        MLI_CALL GET_MARK, mark_src_params
        MLI_CALL CLOSE, close_src_params
       DO
        jsr     _OpenDst
       WHILE NOT_ZERO
        MLI_CALL SET_MARK, mark_dst_params
      END_IF
.endif

        ;; Write the chunk
        jsr     OpCheckCancel
        jsr     _WriteDst
.if ::kCopyInteractive
        bit     src_dst_exclusive_flag
        CONTINUE_IF NC

        ;; Swap
        MLI_CALL CLOSE, close_dst_params
        jsr     _OpenSrc
        MLI_CALL SET_MARK, mark_src_params
.else
        bcs     fail
.endif

    WHILE CC                    ; always

        ;; Close source and destination
close:
        MLI_CALL CLOSE, close_dst_params
.if ::kCopyInteractive
        bit     src_dst_exclusive_flag
    IF NC
        MLI_CALL CLOSE, close_src_params
    END_IF
.else
        MLI_CALL CLOSE, close_src_params
.endif

        ;; Copy file info
.if ::kCopyUseOwnSetDstInfo
        jmp     ApplySrcInfoToDst
.else
        COPY_BYTES $B, src_file_info_params::access, dst_file_info_params::access

        copy8   #7, dst_file_info_params ; `SET_FILE_INFO` param_count
        MLI_CALL SET_FILE_INFO, dst_file_info_params
        copy8   #10, dst_file_info_params ; `GET_FILE_INFO` param_count

        rts
.endif

.if ::kCopyInteractive
        ;; Set if src/dst can't be open simultaneously.
src_dst_exclusive_flag:
        .byte   0
.endif

;;; --------------------------------------------------

.proc _OpenSrc
retry:  MLI_CALL OPEN, open_src_params
.if ::kCopyInteractive
    IF CS
        jsr     ShowErrorAlert
        jmp     retry
    END_IF
.else
        .refto retry
        bcs     fail
.endif

        lda     open_src_params::ref_num
        sta     read_src_params::ref_num
        sta     close_src_params::ref_num
.if ::kCopyInteractive
        sta     mark_src_params::ref_num
.endif
        rts
.endproc ; _OpenSrc

;;; --------------------------------------------------

.if ::kCopyInteractive
.proc _OpenDstImpl
        ENTRY_POINTS_FOR_BIT7_FLAG fail_ok, no_fail, fail_ok_flag
.else
.proc _OpenDst
.endif

retry:  MLI_CALL OPEN, open_dst_params
.if ::kCopyInteractive
    IF CS
        fail_ok_flag := *+1
        ldy     #SELF_MODIFIED_BYTE
      IF NS
        cmp     #ERR_VOL_NOT_FOUND
        beq     finish
      END_IF
        jsr     ShowErrorAlertDst
        jmp     retry
    END_IF
.else
        .refto retry
        bcs     fail
.endif

finish:
.if ::kCopyInteractive
        pha                     ; A = result
.endif
        lda     open_dst_params::ref_num ; harmless if failed
        sta     mark_dst_params::ref_num
        sta     write_dst_params::ref_num
        sta     close_dst_params::ref_num
.if ::kCopyInteractive
        pla                     ; A = result, set N and Z
.endif
        rts

.if ::kCopyInteractive
.endproc ; _OpenDstImpl
_OpenDst := _OpenDstImpl::no_fail
_OpenDstOrFail := _OpenDstImpl::fail_ok
.else
.endproc ; _OpenDst
.endif

;;; --------------------------------------------------

;;; Write the buffer to the destination file, being mindful of sparse blocks.
.proc _WriteDst
        ;; Always start off at start of copy buffer
        copy16  read_src_params::data_buffer, write_dst_params::data_buffer
    DO
        ;; Assume we're going to write everything we read. We may
        ;; later determine we need to write it out block-by-block.
        copy16  read_src_params::trans_count, write_dst_params::request_count

.if ::kCopyCheckAppleShare
        ;; ProDOS Tech Note #30: AppleShare servers do not support
        ;; sparse files. https://prodos8.com/docs/technote/30
        bit     dst_is_appleshare_flag
        bmi     do_write        ; ...and done!
.else
        ;; Assert: We're only ever copying to a RAMDisk, not AppleShare.
        ;; https://prodos8.com/docs/technote/30
.endif

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
      IF NOT_ZERO
        ;; Is this block all zeros? Scan all $200 bytes
        ;; (Note: coded for size, not speed, since we're I/O bound)
        ptr := $06
        copy16  write_dst_params::data_buffer, ptr ; first half
        ldy     #0
        tya
       DO
        ora     (ptr),y
        iny
       WHILE NOT_ZERO
        inc     ptr+1           ; second half
       DO
        ora     (ptr),y
        iny
       WHILE NOT_ZERO
        tay
       IF ZERO
        ;; Block is all zeros, skip over it
        add16_8 mark_dst_params::position+1, #.hibyte(BLOCK_SIZE)
        MLI_CALL SET_EOF, mark_dst_params
        MLI_CALL SET_MARK, mark_dst_params
        jmp     next_block
       END_IF
      END_IF

        ;; Block is not sparse, write it
        jsr     do_write
.if ::kCopyInteractive
        ;; `do_write` will exit on failure
.else
        bcs     ret
.endif
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
    WHILE NOT_ZERO
        RETURN  C=0

do_write:
retry:  MLI_CALL WRITE, write_dst_params
.if ::kCopyInteractive
        .refto ret
    IF CS
        jsr     ShowErrorAlertDst
        jmp     retry
    END_IF
.else
        .refto retry
        bcs     ret
.endif
        MLI_CALL GET_MARK, mark_dst_params
ret:    rts
.endproc ; _WriteDst

.endproc ; _CopyNormalFile

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
        jsr     SetPortForProgressDialog
        CALL    DrawProgressDialogLabel, Y=#0, AX=#aux::str_delete_count
        jmp     DrawFileCountWithSuffix
.endproc ; _DeleteDialogEnumerationCallback

.proc _DeleteDialogConfirmCallback
        ;; arg0 = count
        push16  file_count

        CALL    IsPlural, AX=file_count
    IF CS
        FORMAT_MESSAGE 1, aux::str_delete_confirm_singular_format
    ELSE
        FORMAT_MESSAGE 1, aux::str_delete_confirm_plural_format
    END_IF

        CALL    ShowAlertParams, Y=#AlertButtonOptions::OKCancel, AX=#text_input_buf
        cmp     #kAlertResultOK
        jne     CloseFilesCancelDialogWithCanceledResult
        rts
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

        CLEAR_BIT7_FLAG operations::all_flag
        SET_BIT7_FLAG do_op_flag
        rts
.endproc ; PrepTraversalCallbacksForDelete

;;; ============================================================
;;; Handle deletion of a selected file.
;;; Calls into the recursion logic of `ProcessDirectory` as necessary.

.proc DeleteProcessSelectedFile
        jsr     CopyPathsFromBufsToSrcAndDst

        ;; Path is set up - update dialog and populate `src_file_info_params`
        jsr     DeleteUpdateProgress

retry:  jsr     GetSrcFileInfo
    IF CS
        jsr     ShowErrorAlert
        jmp     retry
    END_IF

        ;; Check if it's a regular file or directory
        lda     src_file_info_params::storage_type
        ;; ST_VOLUME_DIRECTORY excluded because volumes are ejected.
    IF A <> #ST_LINKED_DIRECTORY
        jsr     ValidateStorageType
        bcc     do_destroy
        rts
    END_IF

        ;; Recurse, and process directory
        jsr     ProcessDirectory
        jsr     DeleteRefreshProgress ; update path display
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

        CALL    ShowAlertParams, Y=#AlertButtonOptions::YesNoAllCancel, AX=#aux::str_delete_locked_file
        cmp     #kAlertResultNo
        beq     done
        cmp     #kAlertResultYes
        beq     unlock
        cmp     #kAlertResultAll
        bne     :+
        SET_BIT7_FLAG operations::all_flag
        bmi     unlock          ; always
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
        ora     #LOCKED_MASK    ; all 1 = unlocked
        sta     src_file_info_params::access
        jsr     SetSrcFileInfo
        rts
.endproc ; UnlockSrcFile

.proc UnlockDstFile
        jsr     GetDstFileInfo
        lda     dst_file_info_params::access
        ora     #LOCKED_MASK    ; all 1 = unlocked
        sta     dst_file_info_params::access
        jsr     SetDstFileInfo
        rts
.endproc ; UnlockDstFile

;;; ============================================================
;;; Called by `ProcessDir` to process a single file

.proc DeleteProcessDirectoryEntry
        jsr     AppendFileEntryToSrcPath
        jsr     DeleteUpdateProgress

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
        jsr     DeleteRefreshProgress
        jmp     DeleteFileCommon
.endproc ; DeleteFinishDirectory

;;; ============================================================

.proc DeleteUpdateProgress
        jsr     DecrementFileCount
        FALL_THROUGH_TO DeleteRefreshProgress
.endproc ; DeleteUpdateProgress

;;; Does not decrement count, just repaints path so that the correct
;;; path is visible if an alert is shown when finishing a directory.
.proc DeleteRefreshProgress
        jsr     SetPortForProgressDialog

        CALL    CopyToBuf0, AX=#src_path_buf
        CALL    DrawProgressDialogLabel, Y=#1, AX=#aux::str_file_colon
        jsr     DrawTargetFilePath

        jmp     DrawProgressDialogFilesRemaining
.endproc ; DeleteRefreshProgress

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
        sta     file_count
        sta     file_count+1
        sta     block_count
        sta     block_count+1
        sta     do_op_flag

        rts
.endproc ; PrepTraversalCallbacksForEnumeration

;;; ============================================================
;;; Handle sizing (or just counting) of a selected file.
;;; Calls into the recursion logic of `ProcessDirectory` as necessary.

.proc EnumerationProcessSelectedFile
        jsr     CopyPathsFromBufsToSrcAndDst
retry:  jsr     GetSrcFileInfo
    IF CS
        jsr     ShowErrorAlert
        jmp     retry
    END_IF

        ;; Visit the key file
        lda     src_file_info_params::storage_type
        pha                     ; A = `storage_type`
    IF A = #ST_VOLUME_DIRECTORY
        copy16  #0, src_file_info_params::blocks_used ; dummy value
    END_IF
        jsr     EnumerationProcessDirectoryEntry
        pla                     ; A = `storage_type`

        bit     move_flags      ; same volume relink move?
        RTS_IF VS

        ;; Traverse if necessary
    IF A IN #ST_VOLUME_DIRECTORY, #ST_LINKED_DIRECTORY
        jsr     ProcessDirectory
    END_IF

        rts
.endproc ; EnumerationProcessSelectedFile

;;; ============================================================
;;; Called by `ProcessDirectory` to process a single file
;;; Input: `src_file_info_params::blocks_used` populated

.proc EnumerationProcessDirectoryEntry
        ;; Called with `src_file_info_params` pre-populated
        add16   block_count, src_file_info_params::blocks_used, block_count

        inc16   file_count
        copy16  file_count, total_count
        jmp     operations::InvokeOperationEnumerationCallback
.endproc ; EnumerationProcessDirectoryEntry

;;; ============================================================

.proc DecrementFileCount
        dec16   file_count
        rts
.endproc ; DecrementFileCount

;;; ============================================================
;;; Copy `operation_src_path` to `src_path_buf`, `operation_dst_path` to `dst_path_buf`
;;; and note last '/' in src.

.proc CopyPathsFromBufsToSrcAndDst
        ldy     #0
        sty     src_path_slash_index
        dey

        ;; Copy `operation_src_path` to `src_path_buf`
        ;; ... but record index of last '/'
    DO
        iny
        lda     operation_src_path,y
      IF A = #'/'
        sty     src_path_slash_index
      END_IF
        sta     src_path_buf,y
    WHILE Y <> operation_src_path

        ;; Copy `operation_dst_path` to `dst_path_buf`
        TAIL_CALL CopyToDstPath, AX=#operation_dst_path
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
    DO
        iny
        inx
        copy8   src_path_buf,y, dst_path_buf,x
    WHILE Y <> src_path_buf

        stx     dst_path_buf
        rts
.endproc ; AppendSrcPathLastSegmentToDstPath

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
        push16  file_count

        CALL    IsPlural, AX=file_count
    IF CS
        FORMAT_MESSAGE 1, aux::str_file_count_singular_format
    ELSE
        FORMAT_MESSAGE 1, aux::str_file_count_plural_format
    END_IF
        MGTK_CALL MGTK::DrawString, text_input_buf
        rts
.endproc ; DrawFileCountWithSuffix

;;; `file_count` must be populated
.proc DrawProgressDialogFilesRemaining
        MGTK_CALL MGTK::MoveTo, progress_dialog_remaining_pos
        MGTK_CALL MGTK::DrawString, aux::str_files_remaining

        CALL    IntToStringWithSeparators, AX=file_count
        MGTK_CALL MGTK::DrawString, str_from_int
        MGTK_CALL MGTK::DrawString, str_4_spaces

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
;;; Prompt the user to retry the operation. Abort if canceled.
;;; Input: A = error code
;;; Output: Z=1 (if it returns)

.proc CheckRetry
        CALL    ShowAlertOption, X=#AlertButtonOptions::TryAgainCancel
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        bne     CloseFilesCancelDialogWithFailedResult
        rts
.endproc ; CheckRetry

;;; ============================================================
;;; If Escape is pressed, abort the operation.

.proc CheckCancel
        jsr     GetEvent        ; no need to synthesize events
    IF A = #MGTK::EventKind::key_down
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     cancel
    END_IF
        rts

cancel: bit     do_op_flag
        bpl     CloseFilesCancelDialogWithCanceledResult
        FALL_THROUGH_TO CloseFilesCancelDialogWithFailedResult
.endproc ; CheckCancel

;;; ============================================================
;;; Closes dialog, closes all open files, and restores stack.

.proc CloseFilesCancelDialogImpl
        ENTRY_POINTS_FOR_A failed, kOperationFailed, canceled, kOperationCanceled

        sta     @result
        jsr     operations::InvokeOperationCompleteCallback

        MLI_CALL CLOSE, close_params

        ldx     operations::saved_stack     ; restore stack, in case recursion was aborted
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
        dst_buf := operation_dst_path

        stax    src_ptr

        jsr     ModifierDown    ; Apple inverts the default
        and     #%10000000
        sta     flag

        ;; Check if same volume
        ldy     #0
        copy8   (src_ptr),y, src_len
        iny                     ; skip leading '/'
        bne     check           ; always

    DO
        ;; Chars the same?
        lda     (src_ptr),y
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
      IF GE
        cpy     dst_buf         ; dst also done?
        bcs     match
        lda     operation_dst_path+1,y ; is next char in dst a slash?
        bne     check_slash     ; always
      END_IF

      IF Y >= dst_buf           ; src is not done, is dst?
        iny
        lda     (src_ptr),y     ; is next char in src a slash?
        bne     check_slash     ; always
      END_IF

        iny                     ; next char
    WHILE NOT_ZERO              ; always

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
retry:  CALL    GetFileInfo, AX=src_ptr
    IF CS
        jsr     ShowErrorAlert
        jmp     retry
    END_IF

        copy8   DEVNUM, vol_key_block_params::unit_num
        MLI_CALL READ_BLOCK, vol_key_block_params
        lda     #$80            ; bit 7 = move
    IF CC
        eor     #$40            ; bit 6 = relink supported
    END_IF
        rts
.endproc ; CheckMoveOrCopy

;;; ============================================================

.proc GetAndApplySrcInfoToDst
        jsr     GetSrcFileInfo

        ;; Skip if source is volume; the contents are copied not the
        ;; item itself, so it doesn't make sense.
        lda     src_file_info_params::storage_type
        RTS_IF A = #ST_VOLUME_DIRECTORY

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
    IF CS
        jsr     ShowErrorAlertDst
        jmp     :-
    END_IF
        rts
.endproc ; SetDstFileInfo

;;; ============================================================
;;; Show Alert Dialog
;;; A=error. If `ERR_VOL_NOT_FOUND` or `ERR_FILE_NOT_FOUND`, will show
;;; "please insert the disk: ..." using `operation_src_path` (or `operation_dst_path` if
;;; destination) to supply the disk name.

.proc ShowErrorAlertImpl
        ENTRY_POINTS_FOR_BIT7_FLAG dst, src, dst_flag

    IF A NOT_IN #ERR_VOL_NOT_FOUND, #ERR_PATH_NOT_FOUND
        jsr     ShowAlert
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        bne     close           ; not kAlertResultTryAgain = 0
        rts
    END_IF

        ;; if err is "not found" prompt specifically for src/dst disk
        ldax    #operation_src_path
        bit     dst_flag
    IF NS
        ldax    #operation_dst_path
    END_IF
        jsr     GetVolumeName   ; populates `filename_buf`
        push16  #filename_buf
        FORMAT_MESSAGE 1, aux::str_alert_insert_disk_format

        CALL    ShowAlertParams, Y=#AlertButtonOptions::TryAgainCancel, AX=#text_input_buf
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        bne     close           ; not kAlertResultTryAgain = 0

        ;; Poll drives before trying again
        MLI_CALL ON_LINE, on_line_all_drives_params
        rts

close:  jmp     CloseFilesCancelDialogWithFailedResult

dst_flag:       .byte   0       ; bit7

.endproc ; ShowErrorAlertImpl
ShowErrorAlert := ShowErrorAlertImpl::src
ShowErrorAlertDst := ShowErrorAlertImpl::dst

;;; ============================================================

;;; Input: A,X = path
;;; Output: `filename_buf` populated with volume name

.proc GetVolumeName
        ptr := $06
        stax    ptr

        ldx     #0
        ldy     #0
        lda     (ptr),y
        sta     len
        iny                     ; skip past '/'

    DO
        iny
        lda     (ptr),y
        BREAK_IF A = #'/'

        inx
        sta     filename_buf,x

        len := *+1
        cpy     #SELF_MODIFIED_BYTE
    WHILE NE

        stx     filename_buf
        rts

.endproc ; GetVolumeName

;;; ============================================================
;;; "Get Info" dialog state and logic
;;; ============================================================

;;; NOTE: Inside `operations` scope due to reuse of recursive
;;; directory enumeration logic (`ProcessDirectory` etc)

.scope get_info

        DEFINE_READWRITE_BLOCK_PARAMS getinfo_block_params, $800, $A

;;; ============================================================
;;; Get Info
;;; Returns: A has bit7 = 1 if selected items were modified
;;; Assert: At least one icon is selected

.proc DoGetInfo

        ;; --------------------------------------------------
        ;; Loop over selected icons

        lda     #0
        sta     icon_index
        sta     result_flag

loop:
        icon_index := *+1
        ldx     #SELF_MODIFIED_BYTE
        cpx     selected_icon_count
        jeq     done

        lda     selected_icon_list,x
        cmp     trash_icon_num
        beq     next

        ;; --------------------------------------------------
        ;; Get the file / volume info from ProDOS

        jsr     GetIconPath     ; `operation_src_path` set to path; A=0 on success
    IF NE
        jsr     ShowAlert
        jmp     next
    END_IF
        CALL    CopyToSrcPath, AX=#operation_src_path

        ;; Try to get file/volume info
common: jsr     GetSrcFileInfo
    IF CS
        jsr     ShowAlert
        cmp     #kAlertResultTryAgain
        beq     common
        jmp     next
    END_IF

        ;; Special cases for volumes
        lda     selected_window_id
    IF ZERO
        ;; Volume - determine write-protect state
        CLEAR_BIT7_FLAG write_protected_flag
        ldx     icon_index
        CALL    IconToDeviceIndex, A=selected_icon_list,x
      IF ZERO
        lda     DEVLST,x
        and     #UNIT_NUM_MASK
        sta     getinfo_block_params::unit_num
        MLI_CALL READ_BLOCK, getinfo_block_params
       IF CC
        MLI_CALL WRITE_BLOCK, getinfo_block_params
        IF A = #ERR_WRITE_PROTECTED
        SET_BIT7_FLAG write_protected_flag
        END_IF
       END_IF
      END_IF
    END_IF

        ;; --------------------------------------------------
        ;; Open and populate dialog

        jsr     _DialogOpen

        ;; --------------------------------------------------
        ;; Descendant size/file count

        lda     src_file_info_params::storage_type
    IF A IN #ST_VOLUME_DIRECTORY, #ST_LINKED_DIRECTORY
        jsr     SetCursorWatch  ; before directory enumeration
        jsr     _GetDirSize
        jsr     SetCursorPointer ; after directory enumeration
        jsr     GetSrcFileInfo  ; needed for toggling lock
    END_IF
        ;; --------------------------------------------------
        ;; Run the dialog, until OK or Cancel

        jsr     _DialogRun
        bne     done

next:   inc     icon_index
        jmp     loop

done:   copy8   #0, operation_dst_path
        RETURN  A=result_flag

result_flag:                    ; bit7
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
        CLEAR_BIT7_FLAG has_input_field_flag

        lda     #kPromptButtonsOKCancel
        ldx     icon_index
        inx
    IF X = selected_icon_count
        lda     #kPromptButtonsOKOnly
    END_IF
        jsr     OpenPromptDialog
        jsr     SetPortForPromptDialog

        CALL    DrawDialogTitle, AX=#aux::label_get_info

        ;; Draw labels
        CALL    DrawDialogLabel, Y=#1 | DDL_LRIGHT, AX=#aux::str_info_name
        CALL    DrawDialogLabel, Y=#2 | DDL_LRIGHT, AX=#aux::str_info_type
        CALL    DrawDialogLabel, Y=#4 | DDL_LRIGHT, AX=#aux::str_info_create
        CALL    DrawDialogLabel, Y=#5 | DDL_LRIGHT, AX=#aux::str_info_mod

        lda     selected_window_id
    IF ZERO
        CALL    DrawDialogLabel, Y=#3 | DDL_LRIGHT, AX=#aux::str_info_vol_size
        CALL    DrawDialogLabel, Y=#6 | DDL_LRIGHT, AX=#aux::str_info_protected
    ELSE
        CALL    DrawDialogLabel, Y=#3 | DDL_LRIGHT, AX=#aux::str_info_file_size
    END_IF

        ;; --------------------------------------------------
        ;; Name

        ldx     icon_index
        CALL    GetIconName, A=selected_icon_list,x
        CALL    DrawDialogLabel, Y=#1 | DDL_VALUE

        ;; --------------------------------------------------
        ;; Type

        lda     selected_window_id
    IF ZERO
        ;; Volume
        CALL    DrawDialogLabel, Y=#2 | DDL_VALUE, AX=#aux::str_info_type_volume
    ELSE
        ;; File
        lda     src_file_info_params::file_type
      IF A = #FT_DIRECTORY
        CALL    DrawDialogLabel, Y=#2 | DDL_VALUE, AX=#aux::str_info_type_dir
      ELSE
        CALL    ComposeFileTypeString, A=src_file_info_params::file_type
        push16  #str_file_type
        push16  src_file_info_params::aux_type
        FORMAT_MESSAGE 2, aux::str_info_type_auxtype_format
        CALL    DrawDialogLabel, Y=#2 | DDL_VALUE, AX=#text_input_buf
      END_IF
    END_IF

        ;; --------------------------------------------------
        ;; Size/Blocks

        ldax    src_file_info_params::blocks_used
        ldy     src_file_info_params::storage_type
    IF Y = #ST_VOLUME_DIRECTORY
        ;; ProDOS TRM 4.4.5:
        ;; "When file information about a volume directory is requested, the
        ;; total number of blocks on the volume is returned in the `aux_type`
        ;; field and the total blocks for all files is returned in `blocks_used`.
        stax    vol_used_blocks
        copy16  src_file_info_params::aux_type, vol_total_blocks

        ;; Display will be handled later via `_GetDirSize`
    ELSE
        ;; A regular file, so just show the size
        phax
        FORMAT_MESSAGE 1, aux::str_info_size_file_format
        CALL    DrawDialogLabel, Y=#3 | DDL_VALUE, AX=#text_input_buf
    END_IF

        ;; --------------------------------------------------
        ;; Created date

        COPY_STRUCT DateTime, src_file_info_params::create_date, datetime_for_conversion
        jsr     ComposeDateString
        CALL    DrawDialogLabel, Y=#4 | DDL_VALUE, AX=#text_buffer2

        ;; --------------------------------------------------
        ;; Modified date

        COPY_STRUCT DateTime, src_file_info_params::mod_date, datetime_for_conversion
        jsr     ComposeDateString
        CALL    DrawDialogLabel, Y=#5 | DDL_VALUE, AX=#text_buffer2

        ;; --------------------------------------------------
        ;; Locked/Protected

        lda     selected_window_id
    IF ZERO
        ;; Volume - regular label
        ldax    #aux::str_info_no
        bit     write_protected_flag
      IF NS
        ldax    #aux::str_info_yes
      END_IF
        CALL    DrawDialogLabel, Y=#6 | DDL_VALUE
    ELSE
        ;; File - checkbox control
        ldx     #BTK::kButtonStateNormal
        lda     src_file_info_params::access
        and     #ACCESS_DEFAULT
      IF A <> #ACCESS_DEFAULT
        ldx     #BTK::kButtonStateChecked ; locked
      END_IF
        stx     locked_button::state
        BTK_CALL BTK::CheckboxDraw, locked_button

        ;; Assign hooks; reset in `OpenPromptDialog`
        copy16  #_HandleClick, main::PromptDialogClickHandlerHook
        copy16  #_HandleKey, main::PromptDialogKeyHandlerHook
    END_IF

        rts
.endproc ; _DialogOpen

;;; ------------------------------------------------------------
;;; Recursively count child files / sizes

.proc _GetDirSize
        lda     selected_window_id
    IF NOT_ZERO
        copy16  #1, file_count
        copy16  src_file_info_params::blocks_used, num_blocks
    ELSE
        copy16  #0, file_count
        copy16  #0, num_blocks
    END_IF

        COPY_BYTES kOpTraversalCallbacksSize, operation_traversal_callbacks_for_getinfo, operation_traversal_callbacks

        copy16  #DoNothing, operations::operation_complete_callback ; handle error
        tsx
        stx     operations::saved_stack
        jsr     ProcessDirectory
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
        ;; Vol: "<size>K for <count> file(s) / <total>K"

        ;; arg0 = size
        push16  num_blocks

        ;; arg1 = count
        push16  file_count

        CALL    IsPlural, AX=file_count ; sets C

        lda     selected_window_id
    IF ZERO
        ;; arg3 = vol size
        push16  vol_total_blocks
      IF CS                     ; C from `IsPlural` above
        FORMAT_MESSAGE 3, aux::str_info_size_vol_singular_format
      ELSE
        FORMAT_MESSAGE 3, aux::str_info_size_vol_plural_format
      END_IF
    ELSE
      IF CS                     ; C from `IsPlural` above
        FORMAT_MESSAGE 2, aux::str_info_size_dir_singular_format
      ELSE
        FORMAT_MESSAGE 2, aux::str_info_size_dir_plural_format
      END_IF
    END_IF

        jsr     SetPortForPromptDialog
        TAIL_CALL DrawDialogLabel, Y=#3 | DDL_VALUE, AX=#text_input_buf
.endproc ; _UpdateDirSizeDisplay

num_blocks:
        .word   0
.endproc ; _GetDirSize

;;; ------------------------------------------------------------
;;; Input loop and (hooked) event handlers

.proc _DialogRun
    DO
        jsr     PromptInputLoop
    WHILE NS

        pha
        jsr     ClosePromptDialog
        pla
        rts

.endproc ; _DialogRun

.proc _HandleClick
        MGTK_CALL MGTK::InRect, locked_button::rect
    IF NOT_ZERO
        jsr     _ToggleFileLock
    END_IF
        RETURN  A=#$FF
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
    IF NS
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
        CALL    GetIconEntry, A=selected_icon_list,x
        stax    icon_ptr
        jsr     SetFileRecordPtrFromIconPtr

        bit     LCBANK2
        bit     LCBANK2
        lda     src_file_info_params::access
        ldy     #FileRecord::access
        sta     (file_record_ptr),y
        bit     LCBANK1
        bit     LCBANK1

        SET_BIT7_FLAG result_flag

ret:    RETURN  A=#$FF
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

        DoGetInfo := operations::get_info::DoGetInfo
        RemovePathSegment := operations::RemovePathSegment

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

        copy8   #0, result_flags

        ;; Dialog needs base path to ensure new name is valid path
        jsr     GetSelectionWindow
        jsr     GetWindowOrRootPath
        stax    rename_dialog_params::a_path

        ;; Original path
        CALL    GetIconPath, A=selected_icon_list ; `operation_src_path` set to path; A=0 on success
    IF NE
        jsr     ShowAlert
        RETURN  A=result_flags
    END_IF
        CALL    CopyToSrcPath, AX=#operation_src_path

        ;; Copy original name for display/default
        CALL    GetIconName, A=selected_icon_list
        stax    $06
        CALL    CopyPtr1ToBuf, AX=#old_name_buf

        copy8   selected_icon_list, icon_param
        ITK_CALL IconTK::GetRenameRect, icon_param ; populates `tmp_rect`

        ;; Open the dialog
        jsr     _DialogOpen

        ;; Run the dialog
retry:  jsr     _DialogRun
        beq     success

        ;; Failure
fail:   RETURN  A=result_flags

        ;; --------------------------------------------------
        ;; Success, new name in X,Y

success:
        new_name_ptr := $08
        stxy    new_name_ptr

        ;; Copy the name somewhere LCBANK-safe
        CALL    CopyPtr2ToBuf, AX=#new_name_buf

        ;; File or Volume?
        lda     selected_window_id
    IF NOT_ZERO
        jsr     GetWindowPath
    ELSE
        ldax    #str_empty
    END_IF

        ;; Copy window path as prefix
        jsr     CopyToDstPath

        ;; Append new filename
        CALL    AppendFilenameToDstPath, AX=#new_name_buf

        ;; Did the name change (ignoring case)?
        copy16  #old_name_buf, $06
        copy16  #new_name_buf, $08
        jsr     CompareStrings
        beq     no_change

        ;; Already exists? (Mostly for volumes, but works for files as well)
        jsr     GetDstFileInfo
    IF CC
        CALL    ShowAlert, A=#ERR_DUPLICATE_FILENAME
        jmp     retry
    END_IF
        ;; Try to rename

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

        ;; Erase the icon, in case new name is shorter
        copy8   selected_icon_list, icon_param
        ITK_CALL IconTK::EraseIcon, icon_param

        ;; Copy new string in
        icon_name_ptr := $06
        CALL    GetIconName, A=selected_icon_list
        stax    icon_name_ptr

        ldy     new_name_buf
    DO
        copy8   new_name_buf,y, (icon_name_ptr),y
        dey
    WHILE POS

        ;; If not volume, find and update associated FileEntry
        lda     selected_window_id
        beq     end_filerecord_and_icon_update

        ;; Dig up the index of the icon within the window.
        icon_ptr := $06
        CALL    GetIconEntry, A=icon_param
        stax    icon_ptr

        file_record_ptr := $08
        jsr     SetFileRecordPtrFromIconPtr

        ;; Bank in the `FileRecord` entries
        bit     LCBANK2
        bit     LCBANK2

        ;; Copy the new name in
        ASSERT_EQUALS FileRecord::name, 0, "Name must be at start of FileRecord"
        ldy     new_name_buf
    DO
        copy8   new_name_buf,y, (file_record_ptr),y
        dey
    WHILE POS

        ;; Copy out file metadata needed to determine icon type
        jsr     FileRecordToSrcFileInfo ; uses `FileRecord` ptr in $08

        ;; Done with `FileRecord` entries
        bit     LCBANK1
        bit     LCBANK1

        ;; Determine new icon type
        jsr     GetSelectionViewBy
        ASSERT_EQUALS DeskTopSettings::kViewByIcon, 0
    IF ZERO

        tmpc := $50
        tmpx := tmpc + MGTK::Point::xcoord
        tmpy := tmpc + MGTK::Point::ycoord
        delta := $54

        ;; Compute old bounds of icon bitmap
        jsr     _GetIconBitmapSize
        COPY_STRUCT tmp_rect::bottomright, tmpc

        CALL    DetermineIconType, AX=#new_name_buf ; uses passed name and `src_file_info_params`
        ldy     #IconEntry::type
        sta     (icon_ptr),y
        ;; Assumes flags will not change, regardless of icon.

        ;; Compute new bounds of icon bitmap
        jsr     _GetIconBitmapSize

        ;; Compute and apply deltas
        ldx     #0              ; loop over dimensions
        ldy     #IconEntry::iconx
      DO
        sub16   tmpc,x, tmp_rect::bottomright,x, delta
        add16in (icon_ptr),y, delta, (icon_ptr),y
        iny
        inx
        inx
      WHILE X <> #4
    END_IF

end_filerecord_and_icon_update:

        ;; Draw the (maybe new) icon
        ITK_CALL IconTK::DrawIcon, icon_param

        ;; Is there a window for the folder/volume?
        jsr     FindWindowForSrcPath
    IF NOT_ZERO
        dst := $06
        ;; Update the window title
        jsr     GetWindowTitle
        stax    dst
        ldy     new_name_buf
      DO
        copy8   new_name_buf,y, (dst),y
        dey
      WHILE POS

        lda     result_flags
        ora     #$80
        sta     result_flags
    END_IF

        ;; Update affected window paths, ProDOS prefix
        jsr     NotifyPathChanged

        ;; --------------------------------------------------
        ;; Totally done

        RETURN  A=result_flags

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
        jsr     GetSelectionViewBy ; preserves Y
    IF A = #DeskTopSettings::kViewByIcon
        ldy     #LETK::kLineEditOptionsCentered
    END_IF
        sty     rename_line_edit_rec::options

        COPY_STRUCT MGTK::Point, tmp_rect::topleft, winfo_rename_dialog::viewloc

        MGTK_CALL MGTK::OpenWindow, winfo_rename_dialog

        copy16  rename_dialog_params::a_prev, $08
        CALL    CopyPtr2ToBuf, AX=#text_input_buf
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
        CALL    CopyPtr2ToBuf, AX=#path_buf0
        lda     path_buf0       ; full path okay?
        clc
        adc     text_input_buf
    IF A >= #::kMaxPathLength   ; not +1 because we'll add '/'
        CALL    ShowAlertParams, Y=#AlertButtonOptions::OK, AX=#aux::str_alert_name_too_long
        jmp     loop
    END_IF

        ldxy    #text_input_buf
        RETURN  A=#0
.endproc ; _DialogRun

;;; ============================================================

.proc _DialogClose
        MGTK_CALL MGTK::CloseWindow, winfo_rename_dialog
        jsr     ClearUpdates     ; following CloseWindow
        jsr     SetCursorPointer ; when closing rename dialog (might be I-beam)
        RETURN  A=#1
.endproc ; _DialogClose

;;; ============================================================

;;; Outputs: N=0/Z=1 if ok, N=0/Z=0 if canceled; N=1 means call again

.proc _InputLoop
        LETK_CALL LETK::Idle, rename_le_params

        jsr     SystemTask
        jsr     GetNextEvent

        cmp     #MGTK::EventKind::button_down
        beq     _ClickHandler

        cmp     #MGTK::EventKind::key_down
        beq     _KeyHandler

        cmp     #kEventKindMouseMoved
        bne     _InputLoop

        ;; Check if mouse is over window, change cursor appropriately.
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
    IF A = #MGTK::Area::content
        lda     findwindow_params::window_id
      IF A = #winfo_rename_dialog::kWindowId

        jsr     SetCursorIBeam  ; over rename line edit
        jmp     _InputLoop
      END_IF
    END_IF

        jsr     SetCursorPointer ; not over rename line edit
        jmp     _InputLoop
.endproc ; _InputLoop

;;; Click handler for rename dialog

.proc _ClickHandler
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
    IF A <> #MGTK::Area::content
        RETURN  A=#PromptResult::ok
    END_IF

        lda     findwindow_params::window_id
    IF A <> #winfo_rename_dialog::kWindowId
        RETURN  A=#PromptResult::ok
    END_IF

        copy8   winfo_rename_dialog, event_params
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        COPY_STRUCT screentowindow_params::window, rename_le_params::coords
        LETK_CALL LETK::Click, rename_le_params

        RETURN  A=#$FF
.endproc ; _ClickHandler

;;; Key handler for rename dialog

.proc _KeyHandler
        copy8   event_params::key, rename_le_params::key

        ;; Modifiers?
        ldx     event_params::modifiers
        stx     rename_le_params::modifiers
        bne     allow           ; pass through modified keys

        ;; No modifiers
    IF A = #CHAR_RETURN
        RETURN  A=#PromptResult::ok
    END_IF

    IF A = #CHAR_ESCAPE
        RETURN  A=#PromptResult::cancel
    END_IF

        jsr     IsControlChar   ; pass through control characters
        bcc     allow
        CALL    IsFilenameChar, Y=rename_line_edit_rec+LETK::LineEditRecord::caret_pos
        bcs     ignore
allow:  LETK_CALL LETK::Key, rename_le_params
ignore:
        RETURN  A=#$FF
.endproc ; _KeyHandler

;;; Inputs: `icon_param` set
;;; Outputs: `tmp_rect::x2` is half bitmap width and `tmp_rect::y2` is bitmap height
.proc _GetIconBitmapSize
        ITK_CALL IconTK::GetBitmapRect, icon_param ; inits `tmp_rect`

        ldx     #2              ; loop over dimensions
    DO
        sub16   tmp_rect::bottomright,x, tmp_rect::topleft,x, tmp_rect::bottomright,x
        dex
        dex
    WHILE POS

        ;; Assert: width is < 256, so operating on lower byte is enough
        lsr   tmp_rect::x2      ; want half, for centering

        rts
.endproc ; _GetIconBitmapSize

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
        CALL    GetFileRecordListForWindow, A=selected_window_id
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
        addax8  #IconEntry::name
        rts
.endproc ; GetIconName

;;; ============================================================
;;; Concatenate paths.
;;; Inputs: Base path in $08, second path in $06
;;; Output: `operation_src_path`

.proc JoinPaths
        str1 := $8
        str2 := $6
        buf  := operation_src_path

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
        copy8   (str1),y, buf,x
        @len := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     :-

do_str2:
        ;; Add path separator
        inx
        copy8   #'/', buf,x

        ;; Append $6 (str2)
        ldy     #0
        lda     (str2),y
    IF NOT_ZERO
        sta     @len
:       iny
        inx
        copy8   (str2),y, buf,x
        @len := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     :-
    END_IF

        stx     buf
        rts
.endproc ; JoinPaths

;;; ============================================================
;;; Inputs: A = icon number

.proc SmartportEject
        dib_buffer := ::IO_BUFFER

        ;; Look up device index by icon number
        jsr     IconToDeviceIndex
        RTS_IF ZC

        lda     DEVLST,x        ; A = unit_number
        ;; NOTE: Not masked with `UNIT_NUM_MASK`, `FindSmartportDispatchAddress` handles it.

        ;; Compute SmartPort dispatch address
        jsr     FindSmartportDispatchAddress
    IF CC
        stax    status_dispatch
        stax    control_dispatch
        sty     status_params::unit_num
        sty     control_params::unit_number

        ;; Execute SmartPort call
        status_dispatch := *+1
        jsr     SELF_MODIFIED
        .byte   SPCall::Status
        .addr   status_params
      IF CC
        lda     dib_buffer+SPDIB::Device_Type_Code
       IF A = #SPDeviceType::Disk35
        ;; Execute SmartPort call
        control_dispatch := *+1
        jsr     SELF_MODIFIED
        .byte   SPCall::Control
        .addr   control_params
       END_IF
      END_IF
    END_IF

        rts

        DEFINE_SP_STATUS_PARAMS status_params, SELF_MODIFIED_BYTE, dib_buffer, 3 ; Return Device Information Block (DIB)
        DEFINE_SP_CONTROL_PARAMS control_params, SELF_MODIFIED_BYTE, list, $04 ; For Apple/UniDisk 3.3: Eject disk

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
    DO
        txa
        pha
        ldy     window_to_dir_icon_table-1,x ; X = 1-based id, so -1 to index
      IF NOT_ZERO               ; isn't `kWindowToDirIconFree`
        jsr     GetWindowPath
        jsr     _MaybeUpdateTargetPath
      END_IF
        pla
        tax
        dex
    WHILE NOT_ZERO

        ;; --------------------------------------------------
        ;; Update prefixes

        path := tmp_path_buf    ; depends on `src_path_buf`, `dst_path_buf`

        ;; ProDOS Prefix
        MLI_CALL GET_PREFIX, get_set_prefix_params
        CALL    _MaybeUpdateTargetPath, AX=#path
    IF NE
        MLI_CALL SET_PREFIX, get_set_prefix_params
    END_IF

        ;; Original Prefix
        jsr     GetCopiedToRAMCardFlag
    IF NS
        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2
        CALL    _MaybeUpdateTargetPath, AX=#DESKTOP_ORIG_PREFIX
        CALL    _MaybeUpdateTargetPath, AX=#RAMCARD_PREFIX
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1
    END_IF

        ;; Restart Prefix
        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2
        CALL    _MaybeUpdateTargetPath, AX=#SELECTOR + QuitRoutine::prefix_buffer_offset
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
        CALL    CopyPtr1ToBuf, AX=#old_path

        ;; Set `new_path` to the new prefix
        ldy     dst_path_buf
    DO
        copy8   dst_path_buf,y, new_path,y
        dey
    WHILE POS

        ;; Copy the suffix from `old_path` to `new_path`
        ldx     src_path_buf
        cpx     old_path
        beq     assign          ; paths are equal, no copying needed

        ldy     dst_path_buf
    DO
        inx                     ; advance into suffix
        iny
        copy8   old_path,x, new_path,y
    WHILE X <> old_path
        sty     new_path

        ;; Assign the new window path
assign: ldy     new_path
    DO
        copy8   new_path,y, (dst),y
        dey
    WHILE POS

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
    IF ZC
        ;; It's a prefix! Do the replacement
        CALL    _UpdateTargetPath, AX=ptr
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
    IF A = #'/'
        sta     slash_flag      ; need to restore it later, but
        ldy     #0              ; remove the '/' for now
        lda     (ptr),y
        sec
        sbc     #1
        sta     (ptr),y
    END_IF
        rts
.endproc ; _MaybeStripSlash

.proc _MaybeRestoreSlash
        ;; Restore trailing '/' if needed
        slash_flag := *+1       ; non-zero if trailing slash needed
        lda     #SELF_MODIFIED_BYTE
    IF NOT_ZERO
        ldy     #0
        lda     (ptr),y
        clc
        adc     #1
        sta     (ptr),y
        tay
        copy8   #'/', (ptr),y
    END_IF
        rts
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
    DO
        lda     (ptr1),y
        jsr     ToUpperCase
        sta     @char
        lda     (ptr2),y
        jsr     ToUpperCase
        @char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     ok
        dey
    WHILE NOT_ZERO

        ;; Self or subfolder
        RETURN  A=#$FF

ok:     RETURN  A=#0
.endproc ; IsPathPrefixOf

;;; ============================================================
;;; "About" dialog

.proc AboutDialogProc

        MGTK_CALL MGTK::OpenWindow, winfo_about_dialog
        CALL    SafeSetPortFromWindowId, A=#winfo_about_dialog::kWindowId
        CALL    DrawDialogFrame, AX=#aux::about_dialog_frame_rect
        jsr     SetPenModeXOR
        CALL    DrawDialogTitle, AX=#aux::str_about1
        CALL    DrawDialogLabel, Y=#1 | DDL_CENTER, AX=#aux::str_about2
        CALL    DrawDialogLabel, Y=#2 | DDL_CENTER, AX=#aux::str_about3
        CALL    DrawDialogLabel, Y=#3 | DDL_CENTER, AX=#aux::str_about4
        CALL    DrawDialogLabel, Y=#5 | DDL_CENTER, AX=#aux::str_about5
        CALL    DrawDialogLabel, Y=#6 | DDL_CENTER, AX=#aux::str_about6
        CALL    DrawDialogLabel, Y=#7 | DDL_CENTER, AX=#aux::str_about7
        CALL    DrawDialogLabel, Y=#9, AX=#aux::str_about8
        CALL    DrawDialogLabel, Y=#9 | DDL_RIGHT, AX=#aux::str_about9

    DO
        jsr     SystemTask
        jsr     GetNextEvent
        BREAK_IF A = #MGTK::EventKind::button_down
    WHILE A <> #MGTK::EventKind::key_down

        MGTK_CALL MGTK::CloseWindow, winfo_about_dialog
        jmp     ClearUpdates ; following CloseWindow
.endproc ; AboutDialogProc

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
        CALL    CalculateCaseBits, AX=#stashed_name
        stax    case_bits

        jsr     GetSrcFileInfo
        bcs     ret
        copy8   DEVNUM, block_params::unit_num

        lda     src_file_info_params::storage_type
    IF A <> #ST_VOLUME_DIRECTORY
        ;; --------------------------------------------------
        ;; File

        CALL    GetFileEntryBlock, AX=#src_path_buf
        bcs     ret
        stax    block_params::block_num

        block_ptr := $08
        CALL    GetFileEntryBlockOffset, AX=#block_buffer ; Y is already the entry number
        stax    block_ptr

        MLI_CALL READ_BLOCK, block_params
        bcs     ret

        ;; Is AppleWorks?
        ldy     #FileEntry::file_type
        lda     (block_ptr),y
      IF A NOT_IN #FT_ADB, #FT_AWP, #FT_ASP

        ;; --------------------------------------------------
        ;; Non-AppleWorks file

        jsr     get_case_bits_per_option_and_adjust_string
      ELSE

        ;; --------------------------------------------------
        ;; AppleWorks file

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
       IF ZERO
        ;; Option not set, so zero case bits; memory string preserved
        ldax    #0
       ELSE
        ;; Option set, so write case bits as is.
        ldax    case_bits
       END_IF
      END_IF

        ldy     #FileEntry::case_bits
        sta     (block_ptr),y
        iny
        txa
        sta     (block_ptr),y
        FALL_THROUGH_TO write_block

write_block:
        MLI_CALL WRITE_BLOCK, block_params
ret:    rts

    END_IF

        ;; --------------------------------------------------
        ;; Volume

        copy16  #kVolumeDirKeyBlock, block_params::block_num
        MLI_CALL READ_BLOCK, block_params
        bcs     ret

        jsr     get_case_bits_per_option_and_adjust_string
        stax    block_buffer + VolumeDirectoryHeader::case_bits
        jmp     write_block

        ;; --------------------------------------------------
        ;; Helpers

        ;; Returns Z=0 if option set, Z=1 otherwise
get_option:
        CALL    ReadSetting, X=#DeskTopSettings::options
        and     #DeskTopSettings::kOptionsSetCaseBits
        rts

        ;; Returns A,X=case bits if option set, A,X=0 otherwise
get_case_bits_per_option_and_adjust_string:
        jsr     get_option
    IF ZERO
        ;; Option not set, so zero case bits, adjust memory string
        CALL    UpcaseString, AX=#stashed_name
        CALL    AdjustFileNameCase, AX=#stashed_name
        ldax    #0
    ELSE
        ;; Option set, so write case bits as is, leave string alone
        ldax    case_bits
    END_IF
        rts

        ;; --------------------------------------------------
        block_buffer := $800
        DEFINE_READWRITE_BLOCK_PARAMS block_params, block_buffer, SELF_MODIFIED
.endproc ; ApplyCaseBits

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

        DEFINE_READWRITE_PARAMS read_params, 0, 0
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

        copy8   pos_table+0,x, set_mark_params::position+0
        copy8   pos_table+1,x, set_mark_params::position+1
        copy8   pos_table+2,x, set_mark_params::position+2

        copy16  len_table,y, read_params::request_count
        copy16  addr_table,y, read_params::data_buffer

retry:  MLI_CALL OPEN, open_params
    IF CS
        lda     #kErrInsertSystemDisk
        button_options := *+1
        ldx     #SELF_MODIFIED_BYTE
        jsr     ShowAlertOption
        cmp     #kAlertResultOK
        beq     retry
        jsr     SetCursorPointer ; after loading overlay (failure)
        RETURN  A=#$FF          ; failed
    END_IF

        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num
        MLI_CALL SET_MARK, set_mark_params
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_params
        jmp     SetCursorPointer ; after loading overlay (success)

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
        FALL_THROUGH_TO AShiftX
.endproc ; ATimes64

;;; A,X = A << X
.proc AShiftX
        ldy     #0
        sty     hi
    DO
        asl     a
        rol     hi
        dex
    WHILE NOT_ZERO

        hi := *+1
        ldx     #SELF_MODIFIED_BYTE
        rts
.endproc ; AShiftX

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
    DO
        lda     (ptr),y
        cmp     #'a'            ; set C if lowercase
        ror     bits+1
        ror     bits
        dey
    WHILE NOT_ZERO
        sec
        ror     bits+1
        ror     bits

        RETURN  AX=bits
.endproc ; CalculateCaseBits

;;; ============================================================
;;; Message handler for OK/Cancel dialog

;;; Outputs: N=0/Z=1 if ok, N=0/Z=0 if canceled; N=1 means call again

        PROC_USED_IN_OVERLAY

.proc PromptInputLoop
        bit     has_input_field_flag
    IF NS
        LETK_CALL LETK::Idle, prompt_le_params
    END_IF

        jsr     SystemTask
        jsr     GetNextEvent

        cmp     #MGTK::EventKind::button_down
        beq     _ClickHandler

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
    IF NOT ZERO
        jsr     SetCursorIBeam  ; over prompt line edit
        jmp     PromptInputLoop
    END_IF

        jsr     SetCursorPointer ; not over prompt line edit
        jmp     PromptInputLoop

;;; Click handler for prompt dialog

.proc _ClickHandler
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
    IF A <> #MGTK::Area::content
        RETURN  A=#$FF
    END_IF

        lda     findwindow_params::window_id
    IF A <> #winfo_prompt_dialog::kWindowId
        RETURN  A=#$FF
    END_IF

        copy8   winfo_prompt_dialog, event_params
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, ok_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, ok_button
      IF NC
        lda     #PromptResult::ok
      END_IF
        rts
    END_IF

        bit     prompt_button_flags
        ASSERT_EQUALS ::kPromptButtonsOKCancel & $80, $00
    IF NC
        MGTK_CALL MGTK::InRect, cancel_button::rect
      IF NOT_ZERO
        BTK_CALL BTK::Track, cancel_button
       IF NC
        lda     #PromptResult::cancel
       END_IF
        rts
      END_IF
    END_IF

        bit     has_input_field_flag
    IF NC
        lda     #$FF            ; in case handler is just RTS
        jmp     (PromptDialogClickHandlerHook)
    END_IF

        ;; Was click inside text box?
        MGTK_CALL MGTK::InRect, name_input_rect
    IF NOT_ZERO
        COPY_STRUCT screentowindow_params::window, prompt_le_params::coords
        LETK_CALL LETK::Click, prompt_le_params
    END_IF

        RETURN  A=#$FF
.endproc ; _ClickHandler

;;; Key handler for prompt dialog

.proc _KeyHandler
        copy8   event_params::key, prompt_le_params::key

        ldx     event_params::modifiers
        stx     prompt_le_params::modifiers
    IF NOT_ZERO
        ;; Modifiers

        bit     has_input_field_flag
      IF NS
        LETK_CALL LETK::Key, prompt_le_params
        jsr     UpdateOKButton
      ELSE
        jsr     KeyHookRelay
        RETURN  A=#$FF
      END_IF

    ELSE
        ;; No modifiers

        cmp     #CHAR_RETURN
        beq     _HandleKeyOK

      IF A = #CHAR_ESCAPE
        bit     prompt_button_flags
        ASSERT_EQUALS ::kPromptButtonsOKCancel & $80, $00
        bpl     _HandleKeyCancel
        bmi     _HandleKeyOK    ; always
      END_IF

        bit     has_input_field_flag
      IF NS
        jsr     IsControlChar   ; pass through control characters
        bcc     allow
        CALL    IsFilenameChar, Y=prompt_line_edit_rec+LETK::LineEditRecord::caret_pos
        bcs     ignore
allow:  LETK_CALL LETK::Key, prompt_le_params
        jsr     UpdateOKButton
ignore:
      ELSE
        jsr     KeyHookRelay
        RETURN  A=#$FF
      END_IF

    END_IF
        RETURN  A=#$FF

        ;; --------------------------------------------------

KeyHookRelay:
        jmp     (PromptDialogKeyHandlerHook)

.proc _HandleKeyOK
        BTK_CALL BTK::Flash, ok_button
    IF NS
        RETURN  A=#$FF          ; ignore
    END_IF
        RETURN  A=#PromptResult::ok
.endproc ; _HandleKeyOK

.proc _HandleKeyCancel
        BTK_CALL BTK::Flash, cancel_button
        RETURN  A=#PromptResult::cancel
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

yes:    RETURN  C=0
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

allow:  RETURN  C=0

ignore: RETURN  C=1
.endproc ; IsFilenameChar

;;; ============================================================

.proc OpenProgressDialog
        MGTK_CALL MGTK::OpenWindow, winfo_progress_dialog
        jsr     SetPortForProgressDialog
        CALL    DrawDialogFrame, AX=#aux::progress_dialog_frame_rect
        MGTK_CALL MGTK::FrameRect, progress_dialog_bar_frame
        jmp     SetCursorWatch  ; before progress dialog
.endproc ; OpenProgressDialog

;;; ============================================================

.proc SetPortForProgressDialog
        TAIL_CALL SafeSetPortFromWindowId, A=#winfo_progress_dialog::kWindowId
.endproc ; SetPortForProgressDialog

;;; ============================================================

.proc CloseProgressDialog
        MGTK_CALL MGTK::CloseWindow, winfo_progress_dialog::window_id
        jsr     ClearUpdates     ; following CloseWindow
        jmp     SetCursorPointer ; after progress dialog
.endproc ; CloseProgressDialog

;;; ============================================================
;;; Draw Progress Dialog Label
;;; A,X = string
;;; Y = row number (0, 1, 2, ... )

.proc DrawProgressDialogLabel
        stax    @addr

        ;; y = base + aux::kDialogLabelHeight * line
        tya                     ; low byte
        ldx     #0              ; high byte
        ldy     #aux::kDialogLabelHeight
        jsr     Multiply_16_8_16
        addax   #kProgressDialogLabelBaseY, progress_dialog_label_pos::ycoord
        MGTK_CALL MGTK::MoveTo, progress_dialog_label_pos
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
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
        DEFINE_READWRITE_PARAMS rw_params, desktop_file_data_buf, kFileSize
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
        CALL    CopyDeskTopOriginalPrefix, AX=#tmp_path_buf

        ;; Append '/'
        ldy     tmp_path_buf
        iny
        copy8   #'/', tmp_path_buf,y

        ;; Append filename
        ldx     #0
    DO
        inx
        iny
        copy8   str_desktop_file,x, tmp_path_buf,y
    WHILE X <> str_desktop_file
        sty     tmp_path_buf

        ;; Write the file
        ldax    #tmp_path_buf
        stax    create_params::pathname
        stax    open_params::pathname
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
    DO
        copy8   (path_ptr),y, (data_ptr),y
        dey
    WHILE POS

        ;; Copy view_by in
        pla                     ; A = window_id
        tax
        lda     win_view_by_table-1,x
        ldy     #DeskTopFileItem::view_by
        sta     (data_ptr),y

        ;; Location - copy to `new_window_viewloc` as a temp location, then into data
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + .sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
    DO
        copy8   (winfo_ptr),y, new_window_viewloc,x
        dey
        dex
    WHILE POS

        ldy     #DeskTopFileItem::viewloc+.sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
    DO
        copy8   new_window_viewloc,x, (data_ptr),y
        dey
        dex
    WHILE POS

        ;; Bounds - copy to `new_window_maprect` as a temp location, then into data
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + .sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
    DO
        copy8   (winfo_ptr),y, new_window_maprect,x
        dey
        dex
    WHILE POS

        ldy     #DeskTopFileItem::maprect+.sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
    DO
        copy8   new_window_maprect,x, (data_ptr),y
        dey
        dex
    WHILE POS

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
    IF CC
        lda     open_params::ref_num
        sta     rw_params::ref_num
        sta     close_params::ref_num
        MLI_CALL WRITE, rw_params
        jsr     Close
    END_IF
        rts
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
        CALL    CopyPtr1ToBuf, AX=#path_buf

        ;; Clear out pointer to next block; used to identify
        ;; the current block.
        lda     #0
        sta     block_buf+2
        sta     block_buf+3
        sta     saw_header_flag

        ;; --------------------------------------------------
        ;; Split path into dir path and filename

        ldy     path_buf
    DO
        lda     path_buf,y      ; find last '/'
        BREAK_IF A = #'/'
        inx                     ; length of filename
        dey
    WHILE NOT_ZERO

        dey                     ; length not including '/'
    IF ZERO
        RETURN  C=1             ; was a volume path - failure
    END_IF

        tya
        pha                     ; A = new path length

        iny
        ldx     #0              ; copy out filename
    DO
        inx
        iny
        lda     path_buf,y
        jsr     ToUpperCase
        sta     filename,x
    WHILE Y <> path_buf
        stx     filename

        pla                     ; A = new path length
        sta     path_buf

        ;; --------------------------------------------------
        ;; Open directory, search blocks for filename

        JUMP_TABLE_MLI_CALL OPEN, open_params
        jcs     exit

        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num

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
    IF ZERO
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
    IF ZERO
        ldy     #FileEntry::header_pointer
        copy16in (entry_ptr),y, current_block
    END_IF

        ;; See if this is the file we're looking for
        txa                     ; A = `storage_type_name_length`
        and     #NAME_LENGTH_MASK
        cmp     filename
        bne     next_entry
        tay
        ASSERT_EQUALS FileEntry::file_name, 1
    DO
        lda     (entry_ptr),y
        cmp     filename,y
        bne     next_entry
        dey
    WHILE NOT_ZERO

        ;; Match!
        clc

close:  php
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        plp
exit:
        ;; Only valid if C=0
        RETURN  AX=current_block, Y=entry_num

        DEFINE_OPEN_PARAMS open_params, path_buf, io_buf
        DEFINE_READWRITE_PARAMS read_params, block_buf, BLOCK_SIZE
        DEFINE_CLOSE_PARAMS close_params

.endproc ; GetFileEntryBlock

;;; ============================================================
;;; After calling `GetFileEntryBlock`, this can be used to translate
;;; the entry number in Y into the address of the corresponding
;;; `FileEntry` with a memory buffer for the block.

;;; Inputs: A,X = directory block, Y = entry number in block
;;; Outputs: A,X = pointer to `FileEntry`

.proc GetFileEntryBlockOffset
        ;; Skip prev/next block pointers
        addax8  #4
        ;; Iterate through entries
    IF Y <> #0
      DO
        addax8  #.sizeof(FileEntry)
        dey
      WHILE NOT_ZERO
    END_IF

        rts

.endproc ; GetFileEntryBlockOffset

;;; ============================================================
;;;
;;; Routines beyond this point are used by overlays
;;;
;;; ============================================================

        PROC_USED_IN_OVERLAY

;;; ============================================================

mli_relay_checkevents_flag:     ; bit7
        .byte   0

.proc MLIRelayImpl
        params_src := $7E

        ;; Since this is likely to be I/O bound, process events
        ;; so the mouse stays responsive.
        bit     mli_relay_checkevents_flag
    IF NS
        MGTK_CALL MGTK::CheckEvents
    END_IF

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
        phax

        ;; Copy the params here
        ldy     #3      ; ptr is off by 1
    DO
        copy8   (params_src),y, params-1,y
        dey
    WHILE NOT_ZERO

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
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        rts
.endproc ; SetCursorWatch

        PROC_USED_IN_OVERLAY
.proc SetCursorPointer
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts
.endproc ; SetCursorPointer

        PROC_USED_IN_OVERLAY
.proc SetCursorIBeam
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::ibeam
        rts
.endproc ; SetCursorIBeam

;;; ============================================================

;;; Inputs: A = new `prompt_button_flags` value

        PROC_USED_IN_OVERLAY

.proc OpenPromptDialog
        sta     prompt_button_flags

        copy8   #0, text_input_buf

        copy8   #BTK::kButtonStateNormal, ok_button::state

        lda     #0
        sta     has_input_field_flag
        sta     has_device_picker_flag

        copy16  #NoOp, PromptDialogClickHandlerHook
        copy16  #NoOp, PromptDialogKeyHandlerHook

        MGTK_CALL MGTK::OpenWindow, winfo_prompt_dialog
        jsr     SetPortForPromptDialog
        CALL    DrawDialogFrame, AX=#aux::prompt_dialog_frame_rect

        BTK_CALL BTK::Draw, ok_button
        bit     prompt_button_flags
        ASSERT_EQUALS ::kPromptButtonsOKCancel & $80, $00
    IF NC
        BTK_CALL BTK::Draw, cancel_button
    END_IF

        rts
.endproc ; OpenPromptDialog

;;; ============================================================

        PROC_USED_IN_OVERLAY

.proc ClosePromptDialog
        MGTK_CALL MGTK::CloseWindow, winfo_prompt_dialog
        jsr     ClearUpdates     ; following CloseWindow
        jmp     SetCursorPointer ; when closing prompt dialog (might be I-beam)
.endproc ; ClosePromptDialog

;;; ============================================================

        PROC_USED_IN_OVERLAY

.proc SetPortForPromptDialog
        TAIL_CALL SafeSetPortFromWindowId, A=#winfo_prompt_dialog::kWindowId
.endproc ; SetPortForPromptDialog

;;; ============================================================

;;; Draw dialog label.
;;; A,X has pointer to string
;;; Y has row number (1, 2, ... ) in low nibble, alignment in top nibble

        DDL_LEFT   = $00      ; Left aligned relative to `kDialogLabelDefaultX`
        DDL_VALUE  = $10      ; Left aligned relative to `kDialogValueLeft`
        DDL_CENTER = $20      ; centered within dialog
        DDL_RIGHT  = $30      ; Right aligned
        DDL_LRIGHT = $40      ; Right aligned relative to `kDialogLabelRightX`

        PROC_USED_IN_OVERLAY
.proc DrawDialogLabel
        stringwidth_params := $8
        stringptr := $8
        result  := $A

        ptr := $6

        stax    ptr
        tya
        and     #%00001111
        sta     row
        tya
        and     #%11110000      ; A = flags
        beq     calc_y          ; DDL_LEFT

    IF A = #DDL_VALUE
        copy16  #kDialogValueLeft, dialog_label_pos::xcoord
        ASSERT_EQUALS .hibyte(::kDialogValueLeft), 0
        beq     calc_y
    END_IF

        ;; Compute string width
        pha                     ; A = flags
        copy16  ptr, stringptr
        MGTK_CALL MGTK::StringWidth, stringwidth_params
        pla                     ; A = flags

    IF A = #DDL_CENTER
        sub16   #kPromptDialogWidth, result, dialog_label_pos::xcoord
        lsr16   dialog_label_pos::xcoord
        jmp     calc_y
    END_IF

    IF A = #DDL_RIGHT
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
        copy16  ptr, @addr
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr

        ;; Restore default X position
        copy16  #kDialogLabelDefaultX, dialog_label_pos::xcoord
        rts
.endproc ; DrawDialogLabel

;;; ============================================================

        PROC_USED_IN_OVERLAY
.proc UpdateOKButton
        bit     has_device_picker_flag
    IF NS
        lda     #0
        jsr     ::FormatEraseOverlay::ValidSelection ; preserves A
        bpl     set_state
        lda     #$80
        bne     set_state       ; always
    END_IF

        bit     has_input_field_flag
        bpl     ret

        lda     #BTK::kButtonStateNormal
        ldx     text_input_buf
    IF ZERO
        lda     #BTK::kButtonStateChecked
    END_IF

set_state:
    IF A <> ok_button::state
        sta     ok_button::state
        BTK_CALL BTK::Hilite, ok_button
    END_IF

ret:    rts
.endproc ; UpdateOKButton

;;; ============================================================

        PROC_USED_IN_OVERLAY
.proc DrawDialogTitle
        text_params     := $6
        text_addr       := text_params + 0
        text_width      := text_params + 2

        stax    text_addr       ; input is length-prefixed string
        stax    @addr
        MGTK_CALL MGTK::StringWidth, text_params

        sub16   #kPromptDialogWidth, text_width, pos_dialog_title::xcoord
        lsr16   pos_dialog_title::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, pos_dialog_title
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawDialogTitle


;;; ============================================================

        PROC_USED_IN_OVERLAY

.proc NoOp
        rts
.endproc ; NoOp

;;; ============================================================

;;; Input: A,X = number
;;; Output: C=0 if plural, C=1 if singular; A,X unchanged
.proc IsPlural
        cpx     #0              ; >= 256?
        bne     plural          ; yes, so plural
        cmp     #1              ; == 1?
        bne     plural          ; no, so plural

        ;; singular
        RETURN  C=1

plural: RETURN  C=0
.endproc ; IsPlural

;;; ============================================================

;;; Input: A,X = string to copy
;;; Trashes: $06
        PROC_USED_IN_OVERLAY
.proc CopyToBuf0
        ptr1 := $06
        stax    ptr1
        TAIL_CALL CopyPtr1ToBuf, AX=#path_buf0
.endproc ; CopyToBuf0

;;; ============================================================

;;; Input: A,X = string to copy
;;; Trashes: $06
.proc CopyToOperationDstPath
        ptr1 := $06
        stax    ptr1
        TAIL_CALL CopyPtr1ToBuf, AX=#operation_dst_path
.endproc ; CopyToOperationDstPath

;;; ============================================================

        PROC_USED_IN_OVERLAY

;;; Wrapper for `MGTK::GetEvent`, returns the `EventKind` in A
.proc GetEvent
        MGTK_CALL MGTK::GetEvent, event_params
        RETURN  A=event_params::kind
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

.proc DrawDialogFrame
        stax    addr
        jsr     SetPenModeNotCopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, SELF_MODIFIED, addr
        MGTK_CALL MGTK::SetPenSize, pensize_normal
        rts
.endproc ; DrawDialogFrame

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
;;; Output: A = number of selected icons

.proc GetSelectionCount
        RETURN  A=selected_icon_count
.endproc ; GetSelectionCount

;;; ============================================================
;;; Input: A = index in selection
;;; Output: A,X = IconEntry address

.proc GetSelectedIcon
        tax
        TAIL_CALL GetIconEntry, A=selected_icon_list,x
.endproc ; GetSelectedIcon

;;; ============================================================
;;; Output: A = window with selection, 0 if desktop

.proc GetSelectionWindow
        RETURN  A=selected_window_id
.endproc ; GetSelectionWindow

;;; ============================================================
;;; Determine if an icon is in the current selection.
;;; Inputs: A=icon number
;;; Outputs: Z=1 if found

.proc IsIconSelected
        sta     icon_param
        icon_entry := $06
        jsr     GetIconEntry
        stax    icon_entry

        ldy     #IconEntry::state ; mark as dimmed
        lda     (icon_entry),y
        and     #kIconEntryStateHighlighted
        cmp     #kIconEntryStateHighlighted
        rts
.endproc ; IsIconSelected

;;; ============================================================
;;; Inputs: A = window id
;;; Outputs: Z = 1 if found, and X = index in `window_id_to_filerecord_list_entries`

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc FindIndexInFileRecordListEntries
        ldx     window_id_to_filerecord_list_count
        dex
    DO
        BREAK_IF A = window_id_to_filerecord_list_entries,x
        dex
    WHILE POS
        rts
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
        RETURN  A=win_view_by_table-1,x
.endproc ; GetActiveWindowViewBy

;;; Assert: There is a cached window
        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc GetCachedWindowViewBy
        ldx     cached_window_id
        RETURN  A=win_view_by_table-1,x
.endproc ; GetCachedWindowViewBy

;;; Assert: There is a selection.
;;; NOTE: This variant works even if selection is on desktop
;;; Preserves Y
.proc GetSelectionViewBy
        ldx     selected_window_id
        RETURN  A=win_view_by_table-1,x
.endproc ; GetSelectionViewBy

;;; ============================================================

        PROC_USED_IN_OVERLAY
.proc ToggleMenuHilite
        lda     menu_click_params::menu_id
    IF NOT_ZERO
        MGTK_CALL MGTK::HiliteMenu, menu_click_params
    END_IF
        rts
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
        CALL    ReadSetting, X=#DeskTopSettings::system_capabilities
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
        CALL    ReadSetting, X=#DeskTopSettings::system_capabilities
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
        CALL    ReadSetting, X=#DeskTopSettings::system_capabilities

        ;; If a IIe, maybe use shift key mod
        ;; Not IIc/Laser 128 as BUTN2 set when mouse button clicked
        and     #DeskTopSettings::kSysCapIsIIc | DeskTopSettings::kSysCapIsLaser128
    IF ZERO
        ;; It's a IIe, compare shift key state
        lda     pb2_initial_state ; if shift key mod installed, %1xxxxxxx
        eor     BUTN2             ; ... and if shift is down, %0xxxxxxx
    END_IF

        rts
.endproc ; TestShiftMod

;;; ============================================================
;;; Window Entry Tables
;;; ============================================================


        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
;;; Input: A = window_id (0=desktop)
.proc CacheWindowIconList
        sta     cached_window_id

        ;; Load count & entries
        tax
        copy8   window_entry_count_table,x, cached_window_icon_count
    IF NOT_ZERO
        lda     window_entry_offset_table,x
        tax                     ; X = offset in table
        ldy     #0              ; Y = index in win
      DO
        copy8   window_entry_table,x, cached_window_icon_list,y
        inx
        iny
        cpy     cached_window_icon_count
      WHILE NE
    END_IF

        rts
.endproc ; CacheWindowIconList

.proc ClearActiveWindowEntryCount
        jsr     CacheActiveWindowIconList
        FALL_THROUGH_TO ClearAndStoreCachedWindowIconList
.endproc ; ClearActiveWindowEntryCount

.proc ClearAndStoreCachedWindowIconList
        copy8   #0, cached_window_icon_count
        FALL_THROUGH_TO StoreCachedWindowIconList
.endproc ; ClearAndStoreCachedWindowIconList

;;; Assert: `cached_window_id` and `icon_count` is up-to-date
.proc StoreCachedWindowIconList
        lda     cached_window_id
        cmp     #kMaxDeskTopWindows ; last window?
        beq     done_shift       ; yes, no need to shift

        ;; Compute delta to shift up (or down)
        tax                     ; X = window_id
        lda     cached_window_icon_count
        sec
        sbc     window_entry_count_table,x ; A = amount to shift up (may be <0)
        beq     done_shift
        sta     delta

        ;; Offset entries by delta
        bmi     shift_down

        ;; Shift up
        inx                     ; X = next window_id
        copy8   window_entry_offset_table,x, last
        ldy     icon_count      ; Y = new offset
        tya
        sec
        sbc     delta
        tax                     ; X = old offset

:       copy8   window_entry_table,x, window_entry_table,y
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

:       copy8   window_entry_table,x, window_entry_table,y
        cpy     icon_count
        beq     shift_offsets
        inx
        iny
        jmp     :-

shift_offsets:
        ;; Update offsets table by delta
        ldx     cached_window_id
        inx
    DO
        lda     window_entry_offset_table,x
        clc
        delta := *+1
        adc     #SELF_MODIFIED_BYTE
        sta     window_entry_offset_table,x
        inx
    WHILE X <> #kMaxDeskTopWindows+1

done_shift:

        ;; Store count & entries
        ldx     cached_window_id
        copy8   cached_window_icon_count, window_entry_count_table,x
    IF NOT_ZERO
        lda     window_entry_offset_table,x
        tax                     ; X = offset in table
        ldy     #0              ; Y = index in win
      DO
        copy8   cached_window_icon_list,y, window_entry_table,x
        inx
        iny
        cpy     cached_window_icon_count
      WHILE NE
    END_IF

        rts
.endproc ; StoreCachedWindowIconList

window_entry_count_table:       .res    ::kMaxDeskTopWindows+1, 0
window_entry_offset_table:      .res    ::kMaxDeskTopWindows+1, 0
window_entry_table:             .res    ::kMaxIconCount+1, 0
;;; NOTE: +1 in above is to address an off-by-one case in the shift-up
;;; logic with 127 icons. A simpler fix may be possible, see commit
;;; 41ebde49 for another attempt, but that introduces other issues.

        .assert * < OVERLAY_BUFFER || * >= $6000, error, "Routine used when clearing updates in overlay zone"
.proc CacheActiveWindowIconList
        TAIL_CALL CacheWindowIconList, A=active_window_id
.endproc ; CacheActiveWindowIconList

.proc CacheDesktopIconList
        TAIL_CALL CacheWindowIconList, A=#0
.endproc ; CacheDesktopIconList

;;; ============================================================

;;; A,X = A,X * Y
;;; Uses $10..$19
.proc Multiply_16_8_16
PARAM_BLOCK muldiv_params, $10
number          .word           ; (in)
numerator       .word           ; (in)
denominator     .word           ; (in)
result          .word           ; (out)
remainder       .word           ; (out)
END_PARAM_BLOCK

        ;; number = A,X
        stax    muldiv_params::number

        ;; numerator = Y
        sty     muldiv_params::numerator ; lo
        ldy     #0
        sty     muldiv_params::numerator+1 ; hi

        ;; denominator = 1
        sty     muldiv_params::denominator+1 ; hi
        iny
        sty     muldiv_params::denominator ; lo

        MGTK_CALL MGTK::MulDiv, muldiv_params
        RETURN  AX=muldiv_params::result
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
        .include "../lib/quicksort.s"

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
window_blocks_used_table:  .res    ::kMaxDeskTopWindows*2, 0
window_blocks_free_table:  .res    ::kMaxDeskTopWindows*2, 0

;;; To avoid artifacts, the values drawn are only updated when
;;; a window becomes active.
window_draw_blocks_used_table:  .res    ::kMaxDeskTopWindows*2, 0
window_draw_blocks_free_table:  .res    ::kMaxDeskTopWindows*2, 0

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
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $400, 3,  IconType::graphics ; LR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $400, 5,  IconType::graphics ; DLR image as FOT

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

        kVolIconDeltaY = 29
        kVolIconDeltaX = 90

        ;; Volume icons are positioned at:
        ;; * pos_x - ((icon_width-1) / 2)
        ;; * pos_y - (icon_height-1)
        ;; The "-1" is because the bitmap's x2/y2 are used, not w/h.
        ;; So the coordinates represent the center-bottom of the
        ;; bitmap.

        kVolIconRow1 = 30
        kVolIconRow2 = kVolIconRow1 + kVolIconDeltaY*1
        kVolIconRow3 = kVolIconRow1 + kVolIconDeltaY*2
        kVolIconRow4 = kVolIconRow1 + kVolIconDeltaY*3
        kVolIconRow5 = kVolIconRow1 + kVolIconDeltaY*4
        kVolIconRow6 = kVolIconRow1 + kVolIconDeltaY*5 + 2

        kVolIconCol1 = 516
        kVolIconCol2 = kVolIconCol1 - kVolIconDeltaX*1
        kVolIconCol3 = kVolIconCol1 - kVolIconDeltaX*2
        kVolIconCol4 = kVolIconCol1 - kVolIconDeltaX*3
        kVolIconCol5 = kVolIconCol1 - kVolIconDeltaX*4
        kVolIconCol6 = kVolIconCol1 - kVolIconDeltaX*5

        ;; Trash icon is positioned at exactly these coordinates:
        kTrashIconX = kVolIconCol1 - ((kTrashIconWidth-1) / 2)
        kTrashIconY = kVolIconRow6 - (kTrashIconHeight-1)

desktop_icon_coords_table:
        .word   kVolIconCol1, kVolIconRow1 ; 1
        .word   kVolIconCol1, kVolIconRow2 ; 2
        .word   kVolIconCol1, kVolIconRow3 ; 3
        .word   kVolIconCol1, kVolIconRow4 ; 4
        .word   kVolIconCol1, kVolIconRow5 ; 5
        .word   kVolIconCol2, kVolIconRow6 ; 6
        .word   kVolIconCol3, kVolIconRow6 ; 7
        .word   kVolIconCol4, kVolIconRow6 ; 8
        .word   kVolIconCol5, kVolIconRow6 ; 9
        .word   kVolIconCol6, kVolIconRow6 ; 10
        .word   kVolIconCol2, kVolIconRow5 ; 11
        .word   kVolIconCol3, kVolIconRow5 ; 12
        .word   kVolIconCol4, kVolIconRow5 ; 13
        .word   kVolIconCol5, kVolIconRow5 ; 14
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

saved_stack:
        .byte   0

case_bits:      .word   0

;;; Holds a single filename
clipboard:
        .res    16, 0

operation_dst_path:
        .res    ::kPathBufferSize, 0
operation_src_path:
        .res    ::kPathBufferSize, 0
filename_buf:
        .res    16, 0

stashed_name:
        .res    16, 0

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

;;; High bit set if menu dispatch via mouse with option, clear otherwise.
menu_modified_click_flag:
        .byte   0

;;; ============================================================
;;; Map IconType to other icon/details

;;; Table mapping IconType to kIconEntryFlags*
icontype_iconentryflags_table := * - IconType::VOL_COUNT
        ;; Volume types skipped via above math.
        .byte   0               ; generic
        .byte   0               ; text
        .byte   0               ; binary
        .byte   0               ; graphics
        .byte   0               ; animation
        .byte   0               ; music
        .byte   0               ; tracker
        .byte   0               ; audio
        .byte   0               ; speech
        .byte   0               ; font
        .byte   0               ; relocatable
        .byte   0               ; command
        .byte   kIconEntryFlagsDropTarget ; folder
        .byte   kIconEntryFlagsDropTarget ; system_folder
        .byte   0               ; iigs
        .byte   0               ; appleworks_db
        .byte   0               ; appleworks_wp
        .byte   0               ; appleworks_sp
        .byte   0               ; archive
        .byte   0               ; encoded
        .byte   0               ; link
        .byte   0               ; desk_accessory
        .byte   0               ; basic
        .byte   0               ; intbasic
        .byte   0               ; variables
        .byte   0               ; system
        .byte   0               ; application
        ;; Small Icon types skipped via math below
        ASSERT_TABLE_SIZE icontype_iconentryflags_table, IconType::COUNT - IconType::SMALL_COUNT

icontype_to_smicon_table := * - IconType::VOL_COUNT
        ;; Volume types skipped via above math
        .byte   IconType::small_generic ; generic
        .byte   IconType::small_generic ; text
        .byte   IconType::small_generic ; binary
        .byte   IconType::small_generic ; graphics
        .byte   IconType::small_generic ; animation/video
        .byte   IconType::small_generic ; music
        .byte   IconType::small_generic ; tracker
        .byte   IconType::small_generic ; audio
        .byte   IconType::small_generic ; speech
        .byte   IconType::small_generic ; font
        .byte   IconType::small_generic ; relocatable
        .byte   IconType::small_generic ; command
        .byte   IconType::small_folder  ; folder
        .byte   IconType::small_folder  ; system_folder
        .byte   IconType::small_generic ; iigs
        .byte   IconType::small_generic ; appleworks_db
        .byte   IconType::small_generic ; appleworks_wp
        .byte   IconType::small_generic ; appleworks_sp
        .byte   IconType::small_generic ; archive
        .byte   IconType::small_generic ; encoded
        .byte   IconType::small_generic ; link
        .byte   IconType::small_generic ; desk_accessory
        .byte   IconType::small_generic ; basic
        .byte   IconType::small_generic ; intbasic
        .byte   IconType::small_generic ; variables
        .byte   IconType::small_generic ; system
        .byte   IconType::small_generic ; application
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

        IntToString := main::IntToString
        IntToStringWithSeparators := main::IntToStringWithSeparators
        ComposeSizeString := main::ComposeSizeString

;;; ============================================================

        ENDSEG SegmentDeskTopMain
