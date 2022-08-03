;;; ============================================================
;;; List Box Control
;;;
;;; Required includes:
;;; * lib/event_params.s
;;; * lib/drawstring.s
;;; * lib/muldiv.s
;;; Requires `MGTK_CALL` macro to be functional.
;;;
;;; Requires `listbox` scope with:
;;; * `winfo` - winfo of the list control
;;; * `kHeight` - height of the list in pixels
;;; * `kRows` - number of visible rows in the list
;;; * `num_items` - number of items in the list
;;; * `item_pos` - a scratch MGTK::Point
;;; * `highlight_rect` - a scratch MGTK::Rect
;;; * `selected_index` - updated to be the selection or $FF if none
;;; Requires the following proc definitions:
;;; * `OnListSelectionChange` - called when `selected_index` has changed
;;; * `DrawListEntryProc` - called to draw an item (A=index)
;;; * `SetPortForList` - called to set the port for the window
;;; Requires the following data definitions:
;;; * `LB_SELECTION_ENABLED` if selection is supported
;;; * `LB_CLEAR_SEL_ON_CLICK` if selection should be cleared when whitespace is clicked
;;; ============================================================

;;; ============================================================
;;; Output: Z=1/A=$00 on click on an item
;;;         N=1/A=$FF otherwise

.proc HandleListClick
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
    IF_EQ
        jsr     _HandleListScroll
        return  #$FF            ; not an item
    END_IF

.if !LB_SELECTION_ENABLED
        return  #$FF
.else
        cmp     #MGTK::Ctl::not_a_control
    IF_NE
        return  #$FF            ; not an item
    END_IF

        copy    listbox::winfo+MGTK::Winfo::window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        add16   screentowindow_params::windowy, listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::y1, screentowindow_params::windowy
        ldax    screentowindow_params::windowy
        ldy     #kListItemHeight
        jsr     Divide_16_8_16

        ;; Validate
        cmp     listbox::num_items
    IF_GE
.if LB_CLEAR_SEL_ON_CLICK
        lda     #$FF
        jsr     SetListSelection
.endif
        return  #$FF            ; not an item
    END_IF

        ;; Update selection (if different)
        cmp     listbox::selected_index
    IF_NE
        jsr     SetListSelection
        jsr     OnListSelectionChange
    END_IF

        return  #0              ; an item
.endif
.endproc

;;; ============================================================
;;; Handle scroll bar

;;; Values not part of MGTK::Part enum, but used for keyboard shortcuts
kPartHome = $80
kPartEnd  = $81

.proc _HandleListScrollWithPart
        sta     findcontrol_params::which_part
        FALL_THROUGH_TO _HandleListScroll
.endproc

.proc _HandleListScroll
        ;; Ignore unless vscroll is enabled
        lda     listbox::winfo+MGTK::Winfo::vscroll
        and     #MGTK::Scroll::option_active
        bne     :+
ret:    rts
:
        lda     findcontrol_params::which_part

        ;; --------------------------------------------------

.if !LB_SELECTION_ENABLED
        cmp     #kPartHome
    IF_EQ
        lda     listbox::winfo+MGTK::Winfo::vthumbpos
        beq     ret

        lda     #0
        jmp     update
    END_IF

        ;; --------------------------------------------------

        cmp     #kPartEnd
    IF_EQ
        lda     listbox::winfo+MGTK::Winfo::vthumbpos
        cmp     listbox::winfo+MGTK::Winfo::vthumbmax
        bcs     ret

        lda     listbox::winfo+MGTK::Winfo::vthumbmax
        jmp     update
    END_IF
.endif

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

update: sta     updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params

        jsr     UpdateViewport
        jmp     DrawListEntries
.endproc

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

        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     cancel

        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::page_up ; up_arrow or down_arrow ?
        bcc     ret                  ; Yes, continue

cancel: pla
        pla
ret:    rts
.endproc

;;; ============================================================
;;; Input: A=character
;;; Output: Z=1 if up/down, Z=0 if not

.proc IsListKey
        cmp     #CHAR_UP
        beq     ret
        cmp     #CHAR_DOWN
ret:    rts
.endproc

;;; ============================================================

.proc HandleListKey
        lda     listbox::num_items
        bne     :+
ret:    rts
:
        lda     event_params::key
        ldx     event_params::modifiers

        ;; --------------------------------------------------
        ;; No modifiers
.if LB_SELECTION_ENABLED
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
.else
        ;; Up/Down just scroll
    IF_ZERO
        cmp     #CHAR_UP
      IF_EQ
        lda     #MGTK::Part::up_arrow
        jmp     _HandleListScrollWithPart
      END_IF
        ;; CHAR_DOWN
        lda     #MGTK::Part::down_arrow
        jmp     _HandleListScrollWithPart
    END_IF
.endif

        ;; --------------------------------------------------
        ;; Double modifiers
.if LB_SELECTION_ENABLED
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
.else
        ;; Home/End just scroll
        cpx     #3
    IF_EQ
        cmp     #CHAR_UP
      IF_EQ
        lda     #kPartHome
        jmp     _HandleListScrollWithPart
      END_IF
        ;; CHAR_DOWN
        lda     #kPartEnd
        jmp     _HandleListScrollWithPart
    END_IF
.endif

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

.if LB_SELECTION_ENABLED
SetSelection:
        jsr     SetListSelection
        jmp     OnListSelectionChange
.endif
.endproc

;;; ============================================================
;;; Input: A = new selection (negative if none)
;;; Note: Does not call `OnListSelectionChange`

.if LB_SELECTION_ENABLED
.proc SetListSelection
        pha                     ; A = new selection
        lda     listbox::selected_index
        jsr     HighlightIndex
        pla                     ; A = new selection
        sta     listbox::selected_index
        bmi     :+
        jmp     _ScrollIntoView
:       rts
.endproc
.endif

;;; ============================================================

.if LB_SELECTION_ENABLED
.proc ResetListScroll
        lda     #0
        jmp     _ScrollIntoView
.endproc
.endif

;;; ============================================================
;;; Input: A = row to highlight

;;; TODO: make internal only
.if LB_SELECTION_ENABLED
.proc HighlightIndex
        cmp     #0              ; don't assume caller has flags set
        bmi     ret

        ldx     #0              ; hi (A=lo)
        ldy     #kListItemHeight
        jsr     Multiply_16_8_16
        stax    listbox::highlight_rect+MGTK::Rect::y1
        addax   #kListItemHeight-1, listbox::highlight_rect+MGTK::Rect::y2

        jsr     SetPortForList
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, listbox::highlight_rect
ret:    rts
.endproc
.endif

;;; ============================================================
;;; Enable/disable scrollbar as appropriate; resets thumb pos.
;;; Assert: `listbox::num_items` is set.

;;; TODO: make internal only
.proc EnableScrollbar
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl

        lda     listbox::num_items
        cmp     #listbox::kRows + 1
    IF_LT
        copy    #0, updatethumb_params::thumbpos
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params

        copy    #MGTK::activatectl_deactivate, activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params

        rts
    END_IF

        copy    #0, updatethumb_params::thumbpos
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params

        lda     listbox::num_items
        sec
        sbc     #listbox::kRows
        sta     setctlmax_params::ctlmax
        MGTK_CALL MGTK::SetCtlMax, setctlmax_params

        copy    #MGTK::activatectl_activate, activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params

        rts
.endproc

;;; ============================================================
;;; Input: A = row to ensure visible
;;; Assert: `listbox::winfo+MGTK::Winfo::vthumbpos` is set.

;;; TODO: make internal only
.if LB_SELECTION_ENABLED
.proc _ScrollIntoView
        cmp     listbox::winfo+MGTK::Winfo::vthumbpos
    IF_LT
        sta     updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     UpdateViewport
        jmp     DrawListEntries
    END_IF

        sec
        sbc     #listbox::kRows-1
        bmi     skip
        cmp     listbox::winfo+MGTK::Winfo::vthumbpos
        beq     skip
    IF_GE
        sta     updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     UpdateViewport
        jmp     DrawListEntries
    END_IF

skip:   lda     listbox::selected_index
        jmp     HighlightIndex
.endproc
.endif

;;; ============================================================

;;; TODO: make internal only
.proc UpdateViewport
        ldax    #kListItemHeight
        ldy     listbox::winfo+MGTK::Winfo::vthumbpos
        jsr     Multiply_16_8_16
        stax    listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::y1
        addax   #listbox::kHeight, listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::y2

        rts
.endproc

;;; ============================================================

;;; Calls `DrawListEntryProc` for each entry.
.proc DrawListEntries
        jsr     SetPortForList

        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::PaintRect, listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect

        lda     listbox::num_items
        beq     ret

        copy    #listbox::kRows, rows
        copy    listbox::winfo+MGTK::Winfo::vthumbpos, index
        add16   listbox::winfo+MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::y1, #kListItemTextOffsetY, listbox::item_pos+MGTK::Point::ycoord

loop:   copy16  #kListItemTextOffsetX, listbox::item_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, listbox::item_pos

        index := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     DrawListEntryProc

        add16_8  listbox::item_pos+MGTK::Point::ycoord, #kListItemHeight

.if LB_SELECTION_ENABLED
        lda     index
        cmp     listbox::selected_index
    IF_EQ
        jsr     HighlightIndex
    END_IF
.endif

        inc     index
        lda     index
        cmp     listbox::num_items
        beq     :+
        dec     rows
        bne     loop
:
        MGTK_CALL MGTK::ShowCursor
ret:    rts

rows:   .byte   0
.endproc

;;; ============================================================