;;; ============================================================
;;; List Box ToolKit
;;; ============================================================

;;; * Routines dirty $50...$6F

.scope lbtk
        LBTKEntry := *

        kMaxCommandDataSize = 6

        params_addr     := $50
        command_data    := $52
        lbr_ptr         := $52  ; always first element of `command_data`

        lbr_copy        := command_data + kMaxCommandDataSize
        winfo_ptr       := lbr_copy + LBTK::ListBoxRecord::winfo

        tmp_space       := $63
        tmp_point       := $63  ; used by `_Draw`
        tmp_rect        := $67  ; used by `_Draw`
        .assert tmp_space >= lbr_copy + .sizeof(LBTK::ListBoxRecord), error, "collision"

;;; ============================================================

;;; Shadows params in Selector's `app` and Disk Copy's `auxlc` scopes.
;;; TODO: Rework scoping to eliminate this.
SUPPRESS_SHADOW_WARNING

PARAM_BLOCK event_params, lbtk::tmp_space
kind    .byte
.union
;;; if `kind` is key_down
  .struct
    key             .byte
    modifiers       .byte
  .endstruct
;;; if `kind` is no_event, button_down/up, drag, or apple_key:
  .struct
    coords           .tag MGTK::Point
  .endstruct
  .struct
    xcoord          .word
    ycoord          .word
  .endstruct
;;; if `kind` is update:
  .struct
    window_id       .byte
  .endstruct
.endunion
END_PARAM_BLOCK

PARAM_BLOCK setctlmax_params, lbtk::tmp_space
which_ctl       .byte
ctlmax          .byte
END_PARAM_BLOCK

PARAM_BLOCK activatectl_params, lbtk::tmp_space
which_ctl       .byte
activate        .byte
END_PARAM_BLOCK

PARAM_BLOCK updatethumb_params, lbtk::tmp_space
which_ctl       .byte
thumbpos        .byte
END_PARAM_BLOCK

PARAM_BLOCK trackthumb_params, lbtk::tmp_space
which_ctl       .byte
mousex          .word
mousey          .word
thumbpos        .byte
thumbmoved      .byte
END_PARAM_BLOCK
ASSERT_EQUALS trackthumb_params::mousex, event_params::xcoord
ASSERT_EQUALS trackthumb_params::mousey, event_params::ycoord

ASSERT_EQUALS setctlmax_params::which_ctl, activatectl_params::which_ctl
ASSERT_EQUALS trackthumb_params::which_ctl, activatectl_params::which_ctl
ASSERT_EQUALS updatethumb_params::which_ctl, activatectl_params::which_ctl

PARAM_BLOCK screentowindow_params, lbtk::tmp_space
window_id       .byte
.union
   screen       .tag MGTK::Point
   .struct
     screenx    .word
     screeny    .word
   .endstruct
.endunion
.union
   window       .tag MGTK::Point
   .struct
     windowx    .word
     windowy    .word
   .endstruct
.endunion
END_PARAM_BLOCK
ASSERT_EQUALS screentowindow_params::screenx, event_params::xcoord
ASSERT_EQUALS screentowindow_params::screeny, event_params::ycoord

PARAM_BLOCK findwindow_params, lbtk::tmp_space+1
mousex          .word
mousey          .word
which_area      .byte
window_id       .byte
END_PARAM_BLOCK
ASSERT_EQUALS findwindow_params::mousex, event_params::xcoord
ASSERT_EQUALS findwindow_params::mousey, event_params::ycoord

PARAM_BLOCK findcontrol_params, lbtk::tmp_space+1
mousex          .word
mousey          .word
which_ctl       .byte
which_part      .byte
END_PARAM_BLOCK
ASSERT_EQUALS findcontrol_params::mousex, event_params::xcoord
ASSERT_EQUALS findcontrol_params::mousey, event_params::ycoord

UNSUPPRESS_SHADOW_WARNING

;;; ============================================================

        .assert LBTKEntry = Dispatch, error, "dispatch addr"
.proc Dispatch

        jump_addr := tmp_space

        ;; Adjust stack/stash at `params_addr`
        pla
        sta     params_addr
        clc
        adc     #<3
        tax
        pla
        sta     params_addr+1
        adc     #>3
        pha
        txa
        pha

        ;; Grab command number
        ldy     #1              ; Note: rts address is off-by-one
        lda     (params_addr),y
        asl     a
        tax
        copy16  jump_table,x, jump_addr

        ;; Point `params_addr` at actual params
        iny
        lda     (params_addr),y
        pha
        iny
        lda     (params_addr),y
        sta     params_addr+1
        pla
        sta     params_addr

        ;; Copy param data to `command_data`
        ldy     #kMaxCommandDataSize-1
:       copy8   (params_addr),y, command_data,y
        dey
        bpl     :-

        ;; Cache static of the record in `lbr_copy`, for convenience
        ldy     #.sizeof(LBTK::ListBoxRecord)-1
:       lda     (lbr_ptr),y
        sta     lbr_copy,y
        dey
        bpl     :-

        jmp     (jump_addr)

jump_table:
        .addr   InitImpl
        .addr   ClickImpl
        .addr   KeyImpl
        .addr   SetSelectionImpl
        .addr   SetSizeImpl

.endproc ; Dispatch

;;; ============================================================

DrawEntryProc:  jmp     (lbr_copy + LBTK::ListBoxRecord::draw_entry_proc)
OnSelChange:    jmp     (lbr_copy + LBTK::ListBoxRecord::on_sel_change)
OnNoChange:     jmp     (lbr_copy + LBTK::ListBoxRecord::on_no_change)

;;; ============================================================

pencopy:        .byte   MGTK::pencopy
penXOR:         .byte   MGTK::penXOR

;;; ============================================================
;;; Call to initialize (or reset) the list. The caller must set
;;; `LBTK::ListBoxRecord::num_items` and `LBTK::ListBoxRecord::selected_index` first.
;;; This procedure will:
;;; * Update the scrollbar, based on `LBTK::ListBoxRecord::num_items`
;;; * Draw the list items
;;; * If `LBTK::ListBoxRecord::selected_index` is not none, that item will
;;;   be scrolled into view and highlighted.

.proc InitImpl
        PARAM_BLOCK params, lbtk::command_data
a_record        .addr
        END_PARAM_BLOCK

        jsr     _EnableScrollbar
        lda     lbr_copy + LBTK::ListBoxRecord::selected_index
        bpl     :+
        lda     #0
:       ora     #$80            ; high bit = force draw
        jmp     _ScrollIntoView
.endproc ; InitImpl

;;; ============================================================
;;; Call when a button down event occurs on the list Winfo.
;;;
;;; Output: Z=1/A=$00 on click on an item
;;;         N=1/A=$FF otherwise

.params divide_params
number:         .word   1               ; (in) constant
numerator:      .word   0               ; (in) populated dynamically
denominator:    .word   kListItemHeight ; (in) constant
result:         .word   0               ; (out)
remainder:      .word   0               ; (out)
        REF_MULDIV_MEMBERS
.endparams

.proc ClickImpl
        PARAM_BLOCK params, lbtk::command_data
a_record        .addr
coords          .tag MGTK::Point
        END_PARAM_BLOCK

        COPY_STRUCT MGTK::Point, params::coords, event_params::coords

        jsr     _FindControlIsVerticalScrollBar
    IF_EQ
        jsr     _HandleListScroll
        return  #$FF            ; not an item
    END_IF

        cmp     #MGTK::Ctl::not_a_control
    IF_NE
        return  #$FF            ; not an item
    END_IF

        ldy     #MGTK::Winfo::window_id
        lda     (winfo_ptr),y
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        ldy     #MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::y1
        add16in (winfo_ptr),y, screentowindow_params::windowy, screentowindow_params::windowy

        copy16  screentowindow_params::windowy, divide_params::numerator
        MGTK_CALL MGTK::MulDiv, divide_params
        lda     divide_params::result

        ;; Validate
        cmp     lbr_copy + LBTK::ListBoxRecord::num_items
    IF_GE
        lda     #$FF
        jsr     _SetSelectionAndNotify
        return  #$FF            ; not an item
    END_IF

        ;; Update selection (if different)
        cmp     lbr_copy + LBTK::ListBoxRecord::selected_index
    IF_NE
        jsr     _SetSelectionAndNotify
    ELSE
        jsr     OnNoChange
    END_IF

        return  #0              ; an item
.endproc ; ClickImpl

;;; ============================================================
;;; Handle scroll bar

.proc _HandleListScrollWithPart
        sta     findcontrol_params::which_part
        FALL_THROUGH_TO _HandleListScroll
.endproc ; _HandleListScrollWithPart

.proc _HandleListScroll
        ;; Ignore unless vscroll is enabled
        ldy     #MGTK::Winfo::vscroll
        lda     (winfo_ptr),y
        ASSERT_EQUALS MGTK::Scroll::option_active, %00000001
        ror                     ; C = "active?"
        bcs     :+
ret:    rts
:
        lda     findcontrol_params::which_part

        ;; --------------------------------------------------

        cmp     #MGTK::Part::up_arrow
    IF_EQ
repeat:
        ldy     #MGTK::Winfo::vthumbpos
        lda     (winfo_ptr),y
        beq     ret

        sec
        sbc     #1
        jsr     update
        lda     #MGTK::Part::up_arrow
        jsr     _CheckControlRepeat
        beq     repeat          ; always
    END_IF

        ;; --------------------------------------------------

        cmp     #MGTK::Part::down_arrow
    IF_EQ
repeat:
        ldy     #MGTK::Winfo::vthumbpos
        lda     (winfo_ptr),y
        ASSERT_EQUALS MGTK::Winfo::vthumbmax, MGTK::Winfo::vthumbpos - 1
        dey                     ; Y = MGTK::Winfo::vthumbmax
        cmp     (winfo_ptr),y
        beq     ret

        clc
        adc     #1
        jsr     update
        lda     #MGTK::Part::down_arrow
        jsr     _CheckControlRepeat
        beq     repeat          ; always
    END_IF

        ;; --------------------------------------------------

        cmp     #MGTK::Part::page_up
    IF_EQ
repeat:
        ldy     #MGTK::Winfo::vthumbpos
        lda     (winfo_ptr),y
        cmp     lbr_copy + LBTK::ListBoxRecord::num_rows
        bcs     :+
        lda     #0
        SKIP_NEXT_2_BYTE_INSTRUCTION
        ASSERT_NOT_EQUALS lbr_copy + LBTK::ListBoxRecord::num_rows, $C0, "bad BIT skip"
:       sbc     lbr_copy + LBTK::ListBoxRecord::num_rows
do:     jsr     update
        lda     #MGTK::Part::page_up
        jsr     _CheckControlRepeat
        beq     repeat          ; always
    END_IF

        ;; --------------------------------------------------

        cmp     #MGTK::Part::page_down
    IF_EQ
repeat:
        ldy     #MGTK::Winfo::vthumbpos
        lda     (winfo_ptr),y
        clc
        adc     lbr_copy + LBTK::ListBoxRecord::num_rows
        ASSERT_EQUALS MGTK::Winfo::vthumbmax, MGTK::Winfo::vthumbpos - 1
        dey                     ; Y = MGTK::Winfo::vthumbmax
        cmp     (winfo_ptr),y
        bcc     do
        ;; Assert: Y = MGTK::Winfo::vthumbmax
        lda     (winfo_ptr),y
do:     jsr     update
        lda     #MGTK::Part::page_down
        jsr     _CheckControlRepeat
        beq     repeat          ; always
    END_IF

        ;; --------------------------------------------------
        ;; MGTK::Part::thumb

        copy8   #MGTK::Ctl::vertical_scroll_bar, trackthumb_params::which_ctl
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        beq     ret
        lda     trackthumb_params::thumbpos
        FALL_THROUGH_TO update

        ;; --------------------------------------------------

update: jmp     _UpdateThumbAndDraw
.endproc ; _HandleListScroll

;;; ============================================================

;;; Output: Z=1 if repeat, or pops caller off stack otherwise
.proc _CheckControlRepeat
        sta     ctl

        MGTK_CALL MGTK::PeekEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag
        bne     cancel

        MGTK_CALL MGTK::GetEvent, event_params
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        ldy     #MGTK::Winfo::window_id
        cmp     (winfo_ptr),y
        bne     cancel

        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        bne     cancel

        jsr     _FindControlIsVerticalScrollBar
        bne     cancel

        lda     findcontrol_params::which_part
        ctl := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     ret                  ; Yes, continue

cancel: pla
        pla
ret:    rts
.endproc ; _CheckControlRepeat

;;; ============================================================
;;; Call when a key event occurs, if `LBIsListKey` indicates it
;;; will be handled. This handles scrolling and/or updating
;;; the selection.

.proc KeyImpl
        PARAM_BLOCK params, lbtk::command_data
a_record        .addr
key             .byte
modifiers       .byte
        END_PARAM_BLOCK

        lda     lbr_copy + LBTK::ListBoxRecord::num_items
        bne     :+
ret:    rts
:
        lda     params::key
        ldx     params::modifiers

        ;; --------------------------------------------------
        ;; No modifiers

        ;; Up/Down move selection
    IF_ZERO
        cmp     #CHAR_UP
      IF_EQ
        ldx     lbr_copy + LBTK::ListBoxRecord::selected_index
        beq     ret
       IF_NS
        ldx     lbr_copy + LBTK::ListBoxRecord::num_items
       END_IF
        dex
        txa
        bpl     _SetSelectionAndNotify ; always
      END_IF
        ;; CHAR_DOWN
        ldx     lbr_copy + LBTK::ListBoxRecord::selected_index
      IF_NS
        lda     #0
        beq     _SetSelectionAndNotify ; always
      END_IF
        inx
        cpx     lbr_copy + LBTK::ListBoxRecord::num_items
        beq     ret
        txa
        bpl     _SetSelectionAndNotify ; always
    END_IF

        ;; --------------------------------------------------
        ;; Double modifiers

        ;; Home/End move selection to first/last
        cpx     #3
    IF_EQ
        cmp     #CHAR_UP
      IF_EQ
        lda     lbr_copy + LBTK::ListBoxRecord::selected_index
        beq     ret
        lda     #0
        bpl     _SetSelectionAndNotify ; always
      END_IF
        ;; CHAR_DOWN
        ldx     lbr_copy + LBTK::ListBoxRecord::selected_index
      IF_NC
        inx
        cpx     lbr_copy + LBTK::ListBoxRecord::num_items
        beq     ret
      END_IF
        ldx     lbr_copy + LBTK::ListBoxRecord::num_items
        dex
        txa
        bpl     _SetSelectionAndNotify ; always
    END_IF

        ;; --------------------------------------------------
        ;; Single modifier
        cmp     #CHAR_UP
    IF_EQ
        lda     #MGTK::Part::page_up
        SKIP_NEXT_2_BYTE_INSTRUCTION
    END_IF
        ;; CHAR_DOWN
        lda     #MGTK::Part::page_down
        jmp     _HandleListScrollWithPart
.endproc ; KeyImpl

;;; ============================================================

.proc _SetSelectionAndNotify
        jsr     _SetSelection
        jmp     OnSelChange
.endproc ; _SetSelectionAndNotify

;;; ============================================================

.proc SetSelectionImpl
        PARAM_BLOCK params, lbtk::command_data
a_record        .addr
new_selection   .byte
        END_PARAM_BLOCK

        lda     params::new_selection
        FALL_THROUGH_TO _SetSelection
.endproc ; SetSelectionImpl

;;; ============================================================
;;; Sets the selected item index. If not none, it is scrolled
;;; into view.
;;; Input: A = new selection (negative if none)
;;; Note: Does not call `OnListSelectionChange`

.proc _SetSelection
        pha                     ; A = new selection
        lda     lbr_copy + LBTK::ListBoxRecord::selected_index
        jsr     _HighlightIndex
        ldy     #LBTK::ListBoxRecord::selected_index
        pla                     ; A = new selection
        sta     (lbr_ptr),y
        sta     lbr_copy + LBTK::ListBoxRecord::selected_index ; keep copy in sync
        bmi     :+
        jmp     _ScrollIntoView
:       rts
.endproc ; _SetSelection

;;; ============================================================
;;; Input: A = row to highlight

.proc _HighlightIndex
        cmp     #0              ; don't assume caller has flags set
        bmi     ret

        pha                     ; A = row
        jsr     _SetPort        ; also uses `tmp_rect`
        pla                     ; A = row

        ldx     #0              ; hi (A=lo)
        ldy     #kListItemHeight
        jsr     _Multiply
        stax    tmp_rect+MGTK::Rect::y1
        addax   #kListItemHeight-1, tmp_rect+MGTK::Rect::y2
        copy16  #0, tmp_rect+MGTK::Rect::x1
        copy16  #kScreenWidth, tmp_rect+MGTK::Rect::x2

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, tmp_rect
ret:    rts
.endproc ; _HighlightIndex

;;; ============================================================
;;; Call to update `LBTK::ListBoxRecord::num_items` after `LBInit` is called,
;;; to update the scrollbar alone. The list items will not be redrawn.
;;; This is useful if the list is populated asynchronously.

.proc SetSizeImpl
        PARAM_BLOCK params, lbtk::command_data
a_record        .addr
new_size        .byte
        END_PARAM_BLOCK

        lda     params::new_size
        ldy     #LBTK::ListBoxRecord::num_items
        sta     (lbr_ptr),y
        sta     lbr_copy + LBTK::ListBoxRecord::num_items ; keep copy in sync
        FALL_THROUGH_TO _EnableScrollbar
.endproc ; SetSizeImpl

;;; ============================================================
;;; Enable/disable scrollbar as appropriate; resets thumb pos.
;;; Assert: `LBTK::ListBoxRecord::num_items` is set.

.proc _EnableScrollbar
        ;; Reset thumb pos
        lda     #0
        jsr     _UpdateThumb

        lda     lbr_copy + LBTK::ListBoxRecord::num_items
        cmp     lbr_copy + LBTK::ListBoxRecord::num_rows
        beq     :+
        bcs     greater
:
        ;; Deactivate
        lda     #MGTK::activatectl_deactivate
        ASSERT_EQUALS MGTK::activatectl_deactivate, 0
        beq     activate        ; always

greater:
        ;; Set max and activate
        lda     lbr_copy + LBTK::ListBoxRecord::num_items
        sec
        sbc     lbr_copy + LBTK::ListBoxRecord::num_rows
        sta     setctlmax_params::ctlmax
        MGTK_CALL MGTK::SetCtlMax, setctlmax_params

        lda     #MGTK::activatectl_activate

activate:
        sta     activatectl_params::activate
        copy8   #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts
.endproc ; _EnableScrollbar

;;; ============================================================
;;; Input: A = row to ensure visible; high bit = force redraw,
;;;   even if no scrolling occurred.
;;; Assert: `LBTK::ListBoxRecord::winfo`'s `MGTK::Winfo::vthumbpos` is set.

.proc _ScrollIntoView
        force_draw_flag := tmp_space

        sta     force_draw_flag
        and     #$7F            ; A = index

        ldy     #MGTK::Winfo::vthumbpos
        cmp     (winfo_ptr),y
        bcc     update

        sec
        sbc     lbr_copy + LBTK::ListBoxRecord::num_rows
        clc
        adc     #1
        bmi     skip
        ;; Assert: Y = MGTK::Winfo::vthumbpos
        cmp     (winfo_ptr),y
        beq     skip
        bcs     update
skip:
        lda     force_draw_flag
        bmi     _Draw ; will highlight selection

        lda     lbr_copy + LBTK::ListBoxRecord::selected_index
        jmp     _HighlightIndex

update:
        jmp     _UpdateThumbAndDraw
.endproc ; _ScrollIntoView

;;; ============================================================
;;; Update thumb position.
;;; Input: A = new thumb pos
.proc _UpdateThumb
        sta     updatethumb_params::thumbpos
        copy8   #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
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
        ldy     #MGTK::Winfo::port+MGTK::GrafPort::maprect+.sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     (winfo_ptr),y
        sta     tmp_rect,x
        dey
        dex
        bpl     :-

        ;; Set y2 to height
        sub16   tmp_rect+MGTK::Rect::y2, tmp_rect+MGTK::Rect::y1, tmp_rect+MGTK::Rect::y2

        ldy     #MGTK::Winfo::vthumbpos
        lda     (winfo_ptr),y
        tay
        ldax    #kListItemHeight
        jsr     _Multiply
        stax    tmp_rect+MGTK::Rect::y1

        ;; Set y2 to bottom
        addax   tmp_rect+MGTK::Rect::y2, tmp_rect+MGTK::Rect::y2

        ldy     #MGTK::Winfo::port+MGTK::GrafPort::maprect+.sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     tmp_rect,x
        sta     (winfo_ptr),y
        dey
        dex
        bpl     :-

        add16   winfo_ptr, #MGTK::Winfo::port, setport_addr
        MGTK_CALL MGTK::SetPort, SELF_MODIFIED, setport_addr
        rts

.endproc ; _SetPort

;;; ============================================================

.proc _UpdateThumbAndDraw
        jsr     _UpdateThumb
        FALL_THROUGH_TO _Draw
.endproc ; _UpdateThumbAndDraw

;;; Calls `DrawListEntryProc` for each entry.
.proc _Draw
        jsr     _SetPort

        add16   winfo_ptr, #MGTK::Winfo::port+MGTK::GrafPort::maprect, rect_addr

        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, SELF_MODIFIED, rect_addr

        lda     lbr_copy + LBTK::ListBoxRecord::num_items
        beq     finish

        lda     lbr_copy + LBTK::ListBoxRecord::num_rows
        sta     rows
        ldy     #MGTK::Winfo::vthumbpos
        lda     (winfo_ptr),y
        sta     index

        copy16  #kListItemTextOffsetX, tmp_point+MGTK::Point::xcoord
        ldy     #MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::y1
        add16in (winfo_ptr),y, #kListItemTextOffsetY, tmp_point+MGTK::Point::ycoord

loop:
        MGTK_CALL MGTK::MoveTo, tmp_point

        index := *+1
        lda     #SELF_MODIFIED_BYTE
        ldxy    #tmp_point
        jsr     DrawEntryProc

        add16_8 tmp_point+MGTK::Point::ycoord, #kListItemHeight

        lda     index
        cmp     lbr_copy + LBTK::ListBoxRecord::selected_index
    IF_EQ
        jsr     _HighlightIndex
    END_IF

        inc     index
        lda     index
        cmp     lbr_copy + LBTK::ListBoxRecord::num_items
        beq     :+
        dec     rows
        bne     loop
:

finish: MGTK_CALL MGTK::ShowCursor
        rts

rows:   .byte   0
.endproc ; _Draw

;;; ============================================================

.params multiply_params
number:         .word   0       ; (in) populated dynamically
numerator:      .word   0       ; (in) populated dynamically
denominator:    .word   1       ; (in) constant
result:         .word   0       ; (out)
remainder:      .word   0       ; (out)
        REF_MULDIV_MEMBERS
.endparams

;;; A,X = A,X * Y
.proc _Multiply
        stax    multiply_params::number
        sty     multiply_params::numerator ; high byte remains 0
        MGTK_CALL MGTK::MulDiv, multiply_params
        ldax    multiply_params::result
        rts
.endproc ; _Multiply

;;; ============================================================

.endscope ; lbtk
