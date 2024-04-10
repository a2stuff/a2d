;;; ============================================================
;;; List Box Control
;;;
;;; API:
;;; * InitList - called to show the list
;;; * HandleListClick, IsListKey, HandleListKey - handle events
;;; * SetListSelection - update the selection
;;; * SetListSize - update the scrollbar
;;;
;;; Required includes:
;;; * lib/event_params.s
;;; * lib/muldiv.s
;;; Requires `MGTK_CALL` macro to be functional.
;;;
;;; Requires `listbox` scope with:
;;; * `winfo` - winfo of the list control
;;; * `kRows` - number of visible rows in the list
;;; * `num_items` - number of items in the list
;;; * `item_pos` - a scratch MGTK::Point
;;; * `selected_index` - updated to be the selection or $FF if none
;;; Requires the following proc definitions:
;;; * `DrawListEntryProc` - called to draw an item (A=index)
;;; Optionally:
;;; * `OnListSelectionChange` - called when `selected_index` has changed
;;; * `OnListSelectionNoChange` - called on click when `selected_index` has not changed
;;; Notes:
;;; * Routines dirty $20...$2F
;;; ============================================================

.scope listbox_impl

;;; ============================================================
;;; Call to initialize (or reset) the list. The caller must set
;;; `listbox::num_items` and `listbox::selected_index` first.
;;; This procedure will:
;;; * Update the scrollbar, based on `listbox::num_items`
;;; * Draw the list items
;;; * If `listbox::selected_index` is not none, that item will
;;;   be scrolled into view and highlighted.

.proc ListInit
        jsr     _EnableScrollbar
        lda     listbox::selected_index
        bpl     :+
        lda     #0
:       ora     #$80            ; high bit = force draw
        jmp     _ScrollIntoView
.endproc ; ListInit

;;; ============================================================
;;; Call when a button down event occurs on the list Winfo.
;;;
;;; Output: Z=1/A=$00 on click on an item
;;;         N=1/A=$FF otherwise

.proc ListClick
        jsr     _FindControlIsVerticalScrollBar
    IF_EQ
        jsr     _HandleListScroll
        return  #$FF            ; not an item
    END_IF

        cmp     #MGTK::Ctl::not_a_control
    IF_NE
        return  #$FF            ; not an item
    END_IF

        copy    listbox::winfo+MGTK::Winfo::window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        add16   screentowindow_params::windowy, listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::y1, screentowindow_params::windowy

        copy16  screentowindow_params::windowy, muldiv_numerator
        copy16  #kListItemHeight, muldiv_denominator
        copy16  #1, muldiv_number
        jsr     MulDiv
        lda     muldiv_result

        ;; Validate
        cmp     listbox::num_items
    IF_GE
        lda     #$FF
        jsr     ListSetSelection
.ifdef OnListSelectionChange
        jsr     OnListSelectionChange
.endif
        return  #$FF            ; not an item
    END_IF

        ;; Update selection (if different)
        cmp     listbox::selected_index
    IF_NE
        jsr     ListSetSelection
.ifdef OnListSelectionChange
        jsr     OnListSelectionChange
.endif
.ifdef OnListSelectionNoChange
    ELSE
        jsr     OnListSelectionNoChange
.endif
    END_IF

        return  #0              ; an item
.endproc ; ListClick

;;; ============================================================
;;; Handle scroll bar

.proc _HandleListScrollWithPart
        sta     findcontrol_params::which_part
        FALL_THROUGH_TO _HandleListScroll
.endproc ; _HandleListScrollWithPart

.proc _HandleListScroll
        ;; Ignore unless vscroll is enabled
        lda     listbox::winfo+MGTK::Winfo::vscroll
        and     #MGTK::Scroll::option_active
        bne     :+
ret:    rts
:
        lda     findcontrol_params::which_part

        ;; --------------------------------------------------

        cmp     #MGTK::Part::up_arrow
    IF_EQ
repeat: lda     listbox::winfo+MGTK::Winfo::vthumbpos
        beq     ret

        sec
        sbc     #1
        jsr     update
        jsr     _CheckArrowRepeat
        jmp     repeat
    END_IF

        ;; --------------------------------------------------

        cmp     #MGTK::Part::down_arrow
    IF_EQ
repeat: lda     listbox::winfo+MGTK::Winfo::vthumbpos
        cmp     listbox::winfo+MGTK::Winfo::vthumbmax
        beq     ret

        clc
        adc     #1
        jsr     update
        jsr     _CheckArrowRepeat
        jmp     repeat
    END_IF

        ;; --------------------------------------------------

        cmp     #MGTK::Part::page_up
    IF_EQ
        lda     listbox::winfo+MGTK::Winfo::vthumbpos
        cmp     #listbox::kRows
        bcs     :+
        lda     #0
        beq     update          ; always
:       sbc     #listbox::kRows
        jmp     update
    END_IF

        ;; --------------------------------------------------

        cmp     #MGTK::Part::page_down
    IF_EQ
        lda     listbox::winfo+MGTK::Winfo::vthumbpos
        clc
        adc     #listbox::kRows
        cmp     listbox::winfo+MGTK::Winfo::vthumbmax
        bcc     update
        lda     listbox::winfo+MGTK::Winfo::vthumbmax
        jmp     update
    END_IF

        ;; --------------------------------------------------

        copy    #MGTK::Ctl::vertical_scroll_bar, trackthumb_params::which_ctl
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        jeq     ret
        lda     trackthumb_params::thumbpos
        FALL_THROUGH_TO update

        ;; --------------------------------------------------

update: jsr     _UpdateThumb
        jmp     _Draw
.endproc ; _HandleListScroll

;;; ============================================================

.proc _CheckArrowRepeat
        MGTK_CALL MGTK::PeekEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     :+
        cmp     #MGTK::EventKind::drag
        bne     cancel
:
        MGTK_CALL MGTK::GetEvent, event_params
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     listbox::winfo+MGTK::Winfo::window_id
        bne     cancel

        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        bne     cancel

        jsr     _FindControlIsVerticalScrollBar
        bne     cancel

        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::page_up ; up_arrow or down_arrow ?
        bcc     ret                  ; Yes, continue

cancel: pla
        pla
ret:    rts
.endproc ; _CheckArrowRepeat

;;; ============================================================
;;; Call with a key code to determine if the list can handle it.
;;;
;;; Input: A=character
;;; Output: Z=1 if up/down, Z=0 if not

.proc IsListKey
        cmp     #CHAR_UP
        beq     ret
        cmp     #CHAR_DOWN
ret:    rts
.endproc ; IsListKey

;;; ============================================================
;;; Call when a key event occurs, if `IsListKey` indicates it
;;; will be handled. This handles scrolling and/or updating
;;; the selection.

.proc ListKey
        lda     listbox::num_items
        bne     :+
ret:    rts
:
        lda     event_params::key
        ldx     event_params::modifiers

        ;; --------------------------------------------------
        ;; No modifiers

        ;; Up/Down move selection
    IF_ZERO
        cmp     #CHAR_UP
      IF_EQ
        ldx     listbox::selected_index
        beq     ret
       IF_NS
        ldx     listbox::num_items
       END_IF
        dex
        txa
        bpl     SetSelection    ; always
      END_IF
        ;; CHAR_DOWN
        ldx     listbox::selected_index
      IF_NS
        ldx     #0
      ELSE
        inx
        cpx     listbox::num_items
        beq     ret
      END_IF
        txa
        bpl     SetSelection    ; always
    END_IF

        ;; --------------------------------------------------
        ;; Double modifiers

        ;; Home/End move selection to first/last
        cpx     #3
    IF_EQ
        cmp     #CHAR_UP
      IF_EQ
        lda     listbox::selected_index
        beq     ret
        lda     #0
        bpl     SetSelection    ; always
      END_IF
        ;; CHAR_DOWN
        ldx     listbox::selected_index
      IF_NC
        inx
        cpx     listbox::num_items
        beq     ret
      END_IF
        ldx     listbox::num_items
        dex
        txa
        bpl     SetSelection    ; always
    END_IF

        ;; --------------------------------------------------
        ;; Single modifier
        cmp     #CHAR_UP
    IF_EQ
        lda     #MGTK::Part::page_up
        jmp     _HandleListScrollWithPart
    END_IF
        ;; CHAR_DOWN
        lda     #MGTK::Part::page_down
        jmp     _HandleListScrollWithPart

SetSelection:
        jsr     ListSetSelection
.ifdef OnListSelectionChange
        jsr     OnListSelectionChange
.endif
        rts
.endproc ; ListKey

;;; ============================================================
;;; Sets the selected item index. If not none, it is scrolled
;;; into view.
;;; Input: A = new selection (negative if none)
;;; Note: Does not call `OnListSelectionChange`

.proc ListSetSelection
        pha                     ; A = new selection
        lda     listbox::selected_index
        jsr     _HighlightIndex
        pla                     ; A = new selection
        sta     listbox::selected_index
        bmi     :+
        jmp     _ScrollIntoView
:       rts
.endproc ; ListSetSelection

;;; ============================================================
;;; Input: A = row to highlight

.proc _HighlightIndex
        highlight_rect := $20

        cmp     #0              ; don't assume caller has flags set
        bmi     ret

        ldx     #0              ; hi (A=lo)
        ldy     #kListItemHeight
        jsr     _Multiply
        stax    highlight_rect+MGTK::Rect::y1
        addax   #kListItemHeight-1, highlight_rect+MGTK::Rect::y2
        copy16  #0, highlight_rect+MGTK::Rect::x1
        copy16  #kScreenWidth, highlight_rect+MGTK::Rect::x2

        jsr     _SetPort
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, highlight_rect
ret:    rts
.endproc ; _HighlightIndex

;;; ============================================================
;;; Call to update `listbox::num_items` after `ListInit` is called,
;;; to update the scrollbar alone. The list items will not be redrawn.
;;; This is useful if the list is populated asynchronously.

.proc ListSetSize
        sta     listbox::num_items
        FALL_THROUGH_TO _EnableScrollbar
.endproc ; ListSetSize

;;; ============================================================
;;; Enable/disable scrollbar as appropriate; resets thumb pos.
;;; Assert: `listbox::num_items` is set.

.proc _EnableScrollbar
        ;; Reset thumb pos
        lda     #0
        jsr     _UpdateThumb

        lda     listbox::num_items
        cmp     #listbox::kRows + 1
    IF_LT
        ;; Deactivate
        lda     #MGTK::activatectl_deactivate
        .assert MGTK::activatectl_deactivate = 0, error, "enum mismatch"
        beq     activate        ; always
    END_IF

        ;; Set max and activate
        lda     listbox::num_items
        sec
        sbc     #listbox::kRows
        sta     setctlmax_params::ctlmax
        MGTK_CALL MGTK::SetCtlMax, setctlmax_params

        lda     #MGTK::activatectl_activate

activate:
        sta     activatectl_params::activate
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts
.endproc ; _EnableScrollbar

;;; ============================================================
;;; Input: A = row to ensure visible; high bit = force redraw,
;;;   even if no scrolling occured.
;;; Assert: `listbox::winfo+MGTK::Winfo::vthumbpos` is set.

.proc _ScrollIntoView
        sta     force_draw_flag
        and     #$7F            ; A = index

        cmp     listbox::winfo+MGTK::Winfo::vthumbpos
        bcc     update

        sec
        sbc     #listbox::kRows-1
        bmi     skip
        cmp     listbox::winfo+MGTK::Winfo::vthumbpos
        beq     skip
        bcs     update
skip:
        force_draw_flag := *+1
        lda     #SELF_MODIFIED_BYTE
        bmi     _Draw ; will highlight selection

        lda     listbox::selected_index
        jmp     _HighlightIndex

update:
        jsr     _UpdateThumb
        jmp     _Draw
.endproc ; _ScrollIntoView

;;; ============================================================
;;; Update thumb position.
;;; Input: A = new thumb pos
.proc _UpdateThumb
        sta     updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        rts
.endproc ; _UpdateThumb

;;; ============================================================

;;; Runs `MGTK::FindControl` with coords from `event_params`.
;;; Output: Z=1 if over vertical scrollbar, Z=0 otherwise
.proc _FindControlIsVerticalScrollBar
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        rts
.endproc ; _FindControlIsVerticalScrollBar

;;; ============================================================
;;; Adjusts the viewport given the scroll position, and selects
;;; the GrafPort of the control.

.proc _SetPort
        maprect := listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect

        ;; Set y2 to height
        sub16   maprect+MGTK::Rect::y2, maprect+MGTK::Rect::y1, maprect+MGTK::Rect::y2

        ldax    #kListItemHeight
        ldy     listbox::winfo+MGTK::Winfo::vthumbpos
        jsr     _Multiply
        stax    maprect+MGTK::Rect::y1

        ;; Set y2 to bottom
        addax   maprect+MGTK::Rect::y2, maprect+MGTK::Rect::y2

        MGTK_CALL MGTK::SetPort, listbox::winfo+MGTK::Winfo::port
        rts
.endproc ; _SetPort

;;; ============================================================

;;; Calls `DrawListEntryProc` for each entry.
.proc _Draw
        jsr     _SetPort

        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect

        lda     listbox::num_items
        beq     finish

        copy    #listbox::kRows, rows
        copy    listbox::winfo+MGTK::Winfo::vthumbpos, index
        add16   listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::y1, #kListItemTextOffsetY, listbox::item_pos+MGTK::Point::ycoord

loop:   copy16  #kListItemTextOffsetX, listbox::item_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, listbox::item_pos

        index := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     DrawListEntryProc

        add16_8  listbox::item_pos+MGTK::Point::ycoord, #kListItemHeight

        lda     index
        cmp     listbox::selected_index
    IF_EQ
        jsr     _HighlightIndex
    END_IF

        inc     index
        lda     index
        cmp     listbox::num_items
        beq     :+
        dec     rows
        bne     loop
:

finish: MGTK_CALL MGTK::ShowCursor
        rts

rows:   .byte   0
.endproc ; _Draw

;;; ============================================================

;;; A,X = A,X * Y
.proc _Multiply
        stax    muldiv_number
        sty     muldiv_numerator
        copy    #0, muldiv_numerator+1
        copy16  #1, muldiv_denominator
        jsr     MulDiv
        ldax    muldiv_result
        rts
.endproc ; _Multiply

;;; ============================================================

.endscope ; listbox_impl

;;; "Exports"
ListInit := listbox_impl::ListInit
ListClick := listbox_impl::ListClick
IsListKey := listbox_impl::IsListKey
ListKey := listbox_impl::ListKey
ListSetSelection := listbox_impl::ListSetSelection
ListSetSize := listbox_impl::ListSetSize
