
;;; Routines dirty $06...$2F

.scope letk
        LETKEntry := *

        ;; Points at call parameters
        params_addr := $10

        ;; Cache of static fields from the record
        window_id  := $12
        a_buf      := $13
        rect       := $15
        max_length := $1D
        .assert (a_buf - window_id) = (LETK::LineEditRecord::a_buf - LETK::LineEditRecord::window_id), error, "mismatch"
        .assert (rect - window_id) = (LETK::LineEditRecord::rect - LETK::LineEditRecord::window_id), error, "mismatch"
        .assert (max_length - window_id) = (LETK::LineEditRecord::max_length - LETK::LineEditRecord::window_id), error, "mismatch"

        ;; Calculated from rect
        pos        := $1E

        ;; Call parameters copied here (0...6 bytes)
        command_data = $22

        ;; LineEditRecord address, in all param blocks
        a_record = command_data

        .assert LETKEntry = Dispatch, error, "dispatch addr"
.proc Dispatch

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
        pha                     ; A = command number
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
        pla                       ; A = command number
        tay
        lda     length_table,y
        tay
        dey
:       copy    (params_addr),y, command_data,y
        dey
        bpl     :-

        ;; Cache static fields from the record, for convenience
        .assert LETK::LineEditRecord::window_id = 0, error, "mismatch"
        ldy     #LETK::LineEditRecord::max_length
:       copy    (a_record),y, window_id,y
        dey
        bpl     :-

        add16_8 rect+MGTK::Rect::x1, #kTextBoxTextHOffset-1, pos+MGTK::Point::xcoord
        add16_8 rect+MGTK::Rect::y1, #kTextBoxTextVOffset-1, pos+MGTK::Point::ycoord

        jump_addr := *+1
        jmp     SELF_MODIFIED

jump_table:
        .addr   InitImpl
        .addr   IdleImpl
        .addr   ActivateImpl
        .addr   DeactivateImpl
        .addr   ClickImpl
        .addr   KeyImpl
        .addr   UpdateImpl

        ;; Must be non-zero
length_table:
        .byte   2               ; Init
        .byte   2               ; Idle
        .byte   2               ; Activate
        .byte   2               ; Deactivate
        .byte   6               ; Click
        .byte   4               ; Key
        .byte   2               ; Draw
.endproc ; Dispatch

;;; ============================================================

pencopy:        .byte   MGTK::pencopy
penXOR:         .byte   MGTK::penXOR

.params draw2spaces_params
        .addr   spaces
        .byte   2
spaces: .byte   "  "
.endparams

;;; ============================================================

.proc InitImpl
        PARAM_BLOCK params, letk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        lda     #0
        ldy     #LETK::LineEditRecord::active_flag
        sta     (a_record),y
        iny
        sta     (a_record),y
        .assert (LETK::LineEditRecord::caret_pos - LETK::LineEditRecord::active_flag) = 1, error, "order"
        iny
        sta     (a_record),y
        .assert (LETK::LineEditRecord::caret_flag - LETK::LineEditRecord::caret_pos) = 1, error, "order"
        iny
        sta     (a_record),y
        .assert (LETK::LineEditRecord::caret_counter - LETK::LineEditRecord::caret_flag) = 1, error, "order"

        jsr     UpdateImpl

        FALL_THROUGH_TO _ResetCaretCounter
.endproc ; InitImpl

.proc _ResetCaretCounter
        ldx     #DeskTopSettings::caret_blink_speed+1
        jsr     ReadSetting
        pha
        dex                     ; `ReadSetting` preserves X
        jsr     ReadSetting
        ldy     #LETK::LineEditRecord::caret_counter
        sta     (a_record),y
        iny
        pla
        sta     (a_record),y
        rts
.endproc ; _ResetCaretCounter

;;; ============================================================

.proc IdleImpl
        PARAM_BLOCK params, letk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        ldy     #LETK::LineEditRecord::active_flag
        lda     (a_record),y
        bmi     :+
ret:    rts
:

        ldy     #LETK::LineEditRecord::caret_counter
        sub16in (a_record),y, #1, (a_record),y

        lda     (a_record),y  ; Y = LETK::LineEditRecord::caret_counter+1
        dey
        ora     (a_record),y  ; Y = LETK::LineEditRecord::caret_counter
        bne     ret

        jsr     _ResetCaretCounter

        ldy     #LETK::LineEditRecord::caret_flag
        lda     (a_record),y
        eor     #$80
        sta     (a_record),y

        FALL_THROUGH_TO _XDrawCaret
.endproc ; IdleImpl

.proc _XDrawCaret
        point := $6
        xcoord := $6
        ycoord := $8

        jsr     _SetPort

        jsr     _CalcCaretPos
        stax    xcoord
        dec16   xcoord          ; between characters
        copy16  pos + MGTK::Point::ycoord, ycoord

        MGTK_CALL MGTK::MoveTo, point
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::Line, caret_move

        rts
.endproc ; _XDrawCaret

        ;; Delta from text baseline to top of text, for drawing caret
        DEFINE_POINT caret_move, 0, AS_WORD(-kSystemFontHeight)

.proc _HideCaret
        ldy     #LETK::LineEditRecord::caret_flag
        lda     (a_record),y
        bmi     _XDrawCaret
        rts
.endproc ; _HideCaret
_ShowCaret := _HideCaret

;;; ============================================================

.params getwinport_params
window_id:      .byte   0
port:           .addr   grafport_win
.endparams

grafport_win:   .tag    MGTK::GrafPort

.proc _SetPort
        ;; Set the port
        copy    window_id, getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured

        ;; Calculate a clip rect, maintaining the same drawing coordinates.

        ;; Offset viewloc by rect topleft
        add16 grafport_win+MGTK::MapInfo::viewloc+MGTK::Point::xcoord, rect+MGTK::Rect::x1, grafport_win+MGTK::MapInfo::viewloc+MGTK::Point::xcoord
        add16 grafport_win+MGTK::MapInfo::viewloc+MGTK::Point::ycoord, rect+MGTK::Rect::y1, grafport_win+MGTK::MapInfo::viewloc+MGTK::Point::ycoord

        ;; Assign same maprect
        COPY_STRUCT MGTK::Rect, rect, grafport_win + MGTK::GrafPort::maprect

        MGTK_CALL MGTK::SetPort, grafport_win
        rts
.endproc ; _SetPort

;;; ============================================================

.proc ActivateImpl
        PARAM_BLOCK params, letk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        ;; Idempotent, to allow Activate to be used to just move caret
        jsr     _HideCaret

        ;; Move caret to end
        ldy     #0
        lda     (a_buf),y
        ldy     #LETK::LineEditRecord::caret_pos
        sta     (a_record),y

        ;; Set active flag
        ldy     #LETK::LineEditRecord::active_flag
        lda     #$80
        sta     (a_record),y

        jmp     _ShowCaret
.endproc ; ActivateImpl

;;; ============================================================

.proc DeactivateImpl
        jsr     _HideCaret

        ldy     #LETK::LineEditRecord::active_flag
        lda     #0
        sta     (a_record),y

        ldy     #LETK::LineEditRecord::caret_flag
        sta     (a_record),y

        rts
.endproc ; DeactivateImpl

;;; ============================================================
;;; Internal proc: used as part of insert/delete procs

.proc _RedrawRightOfCaret
        jsr     _SetPort

PARAM_BLOCK point, $06
xcoord  .word
ycoord  .word
END_PARAM_BLOCK

        jsr     _CalcCaretPos
        stax    point::xcoord
        copy16  pos + MGTK::Point::ycoord, point::ycoord
        MGTK_CALL MGTK::MoveTo, point

PARAM_BLOCK dt_params, $06
data    .addr
length  .byte
END_PARAM_BLOCK

        jsr     _PrepTextParams
        sta     len

        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y
        sta     caret_pos

        add16_8 dt_params::data, caret_pos
        len := *+1
        lda     #SELF_MODIFIED_BYTE
        sec
        caret_pos := *+1
        sbc     #SELF_MODIFIED_BYTE
        beq     :+
        sta     dt_params::length
        MGTK_CALL MGTK::DrawText, dt_params
:
        rts
.endproc ; _RedrawRightOfCaret

;;; ============================================================
;;; Prepare params for a TextWidth or DrawText call
;;; Output: A=length (and Z=1 if empty)

.proc _PrepTextParams
PARAM_BLOCK text_params, $06
data    .addr
length  .byte
END_PARAM_BLOCK

        ldxy    a_buf
        inxy
        stxy    text_params::data
        ldy     #0
        lda     (a_buf),y
        sta     text_params::length
        rts
.endproc ; _PrepTextParams

;;; ============================================================

.proc ClickImpl
        PARAM_BLOCK params, letk::command_data
a_record  .addr
xcoord  .word
ycoord  .word
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        PARAM_BLOCK tw_params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        jsr     _PrepTextParams
        beq     ret
        sta     len

        sub16   params::xcoord, pos + MGTK::Point::xcoord, params::xcoord
    IF_MINUS
        lda     #0
        beq     set             ; always
    END_IF

        ;; Iterate to find the position
        lda     #0
        sta     tw_params::width
        sta     tw_params::width+1
        sta     tw_params::length
loop:   cmp16   tw_params::width, params::xcoord
        bcs     :+
        inc     tw_params::length
        lda     tw_params::length
        len := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     :+
        MGTK_CALL MGTK::TextWidth, tw_params
        beq     loop            ; always
:
        lda     tw_params::length
set:    pha
        jsr     _HideCaret
        pla
        ldy     #LETK::LineEditRecord::caret_pos
        sta     (a_record),y
        jsr     _ShowCaret

ret:    rts

.endproc ; ClickImpl

;;; ============================================================
;;; Move caret one character left.

.proc _MoveCaretLeft
        ;; Any characters to left of caret?
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y
        beq     ret

        sec
        sbc     #1
        sta     (a_record),y

ret:    rts
.endproc ; _MoveCaretLeft

;;; ============================================================
;;; Move caret one character right.

.proc _MoveCaretRight
        ;; Any characters to right of caret?
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y    ; A = caret_pos
        ldy     #0
        cmp     (a_buf),y
        beq     ret

        clc
        adc     #1
        ldy     #LETK::LineEditRecord::caret_pos
        sta     (a_record),y

ret:    rts
.endproc ; _MoveCaretRight

;;; ============================================================
;;; When delete (backspace) is hit

.proc _DeleteLeft
        ;; Anything to delete?
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y    ; A = caret_pos
        beq     ret

        sec
        sbc     #1
        sta     (a_record),y

        jsr     _DeleteCharCommon

ret:    rts
.endproc ; _DeleteLeft

;;; ============================================================
;;; Forward-delete

.proc _DeleteRight
        ;; Anything to delete?
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y    ; A = caret_pos

        ldy     #0
        cmp     (a_buf),y
        beq     ret

        jsr     _DeleteCharCommon

ret:    rts
.endproc ; _DeleteRight

;;; ============================================================
;;; Handle a key.

.proc KeyImpl
        PARAM_BLOCK params, letk::command_data
a_record  .addr
key     .byte
modifiers .byte
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        MGTK_CALL MGTK::ObscureCursor
        jsr     _HideCaret
        jsr     :+
        jmp     _ShowCaret

:       lda     params::key

        ldx     params::modifiers
        bne     modified

        ;; Not modified
        cmp     #CHAR_LEFT
        beq     _MoveCaretLeft

        cmp     #CHAR_RIGHT
        beq     _MoveCaretRight

        cmp     #CHAR_DELETE
        beq     _DeleteLeft

        cmp     #CHAR_CTRL_F
        beq     _DeleteRight

        cmp     #CHAR_CLEAR
        beq     _DeleteLine

        cmp     #' '
        bcs     _InsertChar

        rts

        ;; Modified
modified:
        cmp     #CHAR_LEFT
        beq     _MoveCaretStart

        cmp     #CHAR_RIGHT
        beq     _MoveCaretEnd

        rts
.endproc ; KeyImpl

;;; ============================================================
;;; When a non-control key is hit - insert the passed character

.proc _InsertChar
        sta     char

        ;; Stash current caret pos
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y
        sta     @caret_pos

        ;; Is there room?
        ldy     #0
        lda     (a_buf),y
        cmp     max_length
        bcs     ret

        ;; Move everything to right of caret up
        tay
        @caret_pos := *+1
:       cpy     #SELF_MODIFIED_BYTE
        beq     :+
        lda     (a_buf),y
        iny
        sta     (a_buf),y
        dey
        dey
        bne     :-              ; always
:
        ;; Insert
        char := *+1
        lda     #SELF_MODIFIED_BYTE
        iny
        sta     (a_buf),y
        ldy     #0
        lda     (a_buf),y
        clc
        adc     #1
        sta     (a_buf),y

        ;; Redraw string to right of old caret position
        jsr     _RedrawRightOfCaret

        ;; Now move caret to new position
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y
        clc
        adc     #1
        sta     (a_record),y

ret:    rts
.endproc ; _InsertChar

;;; ============================================================

.proc _DeleteLine
        ;; Anything to delete?
        ldy     #0
        lda     (a_buf),y
        beq     ret

        lda     #0
        sta     (a_buf),y
        ldy     #LETK::LineEditRecord::caret_pos
        sta     (a_record),y

        jsr     _SetPort
        MGTK_CALL MGTK::PaintRect, rect

ret:    rts
.endproc ; _DeleteLine

;;; ============================================================
;;; Move caret to start of input field.

.proc _MoveCaretStart
        lda     #0
        ldy     #LETK::LineEditRecord::caret_pos
        sta     (a_record),y
        rts
.endproc ; _MoveCaretStart

;;; ============================================================
;;; Move caret to end of input field.

.proc _MoveCaretEnd
        ldy     #0
        lda     (a_buf),y
        ldy     #LETK::LineEditRecord::caret_pos
        sta     (a_record),y
        rts
.endproc ; _MoveCaretEnd

;;; ============================================================
;;; Common logic for DeleteLeft/DeleteRight

.proc _DeleteCharCommon
        ;; Shrink buffer
        ldy     #0
        lda     (a_buf),y
        sec
        sbc     #1
        sta     (a_buf),y
        sta     @len

        ;; Move everything to the right of the caret down
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y
        tay
        @len := *+1
:       cpy     #SELF_MODIFIED_BYTE
        beq     :+
        iny
        iny
        lda     (a_buf),y
        dey
        sta     (a_buf),y
        bne     :-              ; always
:
        ;; Redraw everything to the right of the caret
        jsr     _RedrawRightOfCaret
        MGTK_CALL MGTK::DrawText, draw2spaces_params

        rts
.endproc ; _DeleteCharCommon

;;; ============================================================
;;; Output: A,X = X coordinate of caret

.proc _CalcCaretPos
        PARAM_BLOCK tw_params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        jsr     _PrepTextParams
        copy16  #0, tw_params::width

        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y
    IF_NOT_ZERO
        sta     tw_params::length
        MGTK_CALL MGTK::TextWidth, tw_params
    END_IF

        lda     tw_params::width
        clc
        adc     pos + MGTK::Point::xcoord
        tay
        lda     tw_params::width+1
        adc     pos + MGTK::Point::xcoord+1
        tax
        tya
        rts
.endproc ; _CalcCaretPos

;;; ============================================================
;;; Redraw the contents of the control; used after a window move or string change.

.proc UpdateImpl
        PARAM_BLOCK params, letk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        jsr     _SetPort

        ;; Unnecessary - the entire field will be repainted.
        ;; jsr     _HideCaret

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect
        MGTK_CALL MGTK::MoveTo, pos

PARAM_BLOCK dt_params, $6
textptr .addr
textlen .byte
END_PARAM_BLOCK
        ldy     #0
        lda     (a_buf),y
        beq     :+
        sta     dt_params::textlen
        ldxy    a_buf
        inxy
        stxy    dt_params::textptr
        MGTK_CALL MGTK::DrawText, dt_params
:

        ;; Fix caret position if string has shrunk
        ldy     #0
        lda     (a_buf),y
        ldy     #LETK::LineEditRecord::caret_pos
        cmp     (a_record),y    ; len >= caret_pos
        bcs     :+
        sta     (a_record),y    ; no, clamp caret_pos
:
        jmp     _ShowCaret
.endproc ; UpdateImpl

;;; ============================================================

.endscope ; letk
