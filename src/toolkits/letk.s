;;; ============================================================
;;; LineEdit ToolKit
;;; ============================================================

;;; Routines dirty $06...$2F
;;; TODO: Spill to stack?

.scope letk
        LETKEntry := *

        ;; Points at call parameters
        params_addr := $10

        ;; Cache of static fields from the record
        window_id  := $12
        a_buf      := $13
        rect       := $15
        max_length := $1D
        options    := $1E
        ASSERT_EQUALS a_buf - window_id, LETK::LineEditRecord::a_buf - LETK::LineEditRecord::window_id
        ASSERT_EQUALS rect - window_id, LETK::LineEditRecord::rect - LETK::LineEditRecord::window_id
        ASSERT_EQUALS max_length - window_id, LETK::LineEditRecord::max_length - LETK::LineEditRecord::window_id
        ASSERT_EQUALS options - window_id, LETK::LineEditRecord::options - LETK::LineEditRecord::window_id
        kCacheSize = options - window_id

        ;; Calculated from rect
        pos        := $1F

        ;; Call parameters copied here (0...6 bytes)
        command_data := pos + .sizeof(MGTK::Point)

        ;; LineEditRecord address, in all param blocks
        a_record := command_data

        PARAM_BLOCK text_params, $29
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK
        ASSERT_EQUALS text_params, command_data + 6

        tmpw := text_params+.sizeof(text_params)

        .assert tmpw+2 <= $30, error, "mismatch"

        .assert LETKEntry = Dispatch, error, "dispatch addr"
.proc Dispatch

        jump_addr := tmpw

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
:       copy8   (params_addr),y, command_data,y
        dey
        bpl     :-

        ;; Cache static fields from the record, for convenience
        ASSERT_EQUALS LETK::LineEditRecord::window_id, 0
        ldy     #kCacheSize
:       copy8   (a_record),y, window_id,y
        dey
        bpl     :-

        jsr     _CalcPos

        jmp     (jump_addr)

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

;;; ============================================================

.proc _CalcPos
        ;; Default position
        add16_8 rect+MGTK::Rect::x1, #kTextBoxTextHOffset-1, pos+MGTK::Point::xcoord
        add16_8 rect+MGTK::Rect::y1, #kTextBoxTextVOffset-1, pos+MGTK::Point::ycoord

        bit     options         ; bit7 = centered
    IF_NS
        add16   rect+MGTK::Rect::x1, rect+MGTK::Rect::x2, pos+MGTK::Point::xcoord

        jsr     _PrepTextParams
      IF_NOT_ZERO
        MGTK_CALL MGTK::TextWidth, text_params
      END_IF

        sub16   pos+MGTK::Point::xcoord, text_params::width, pos+MGTK::Point::xcoord
        lsr16   pos+MGTK::Point::xcoord
   END_IF

        rts
.endproc ; _CalcPos

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
        ASSERT_EQUALS LETK::LineEditRecord::caret_pos - LETK::LineEditRecord::active_flag, 1
        iny
        sta     (a_record),y
        ASSERT_EQUALS LETK::LineEditRecord::caret_flag - LETK::LineEditRecord::caret_pos, 1
        iny
        sta     (a_record),y
        ASSERT_EQUALS LETK::LineEditRecord::caret_counter - LETK::LineEditRecord::caret_flag, 1

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
        copy8   window_id, getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     obscured
        MGTK_CALL MGTK::SetPort, grafport_win
        beq     ret

obscured:
        pla
        pla
ret:
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
        jsr     _MoveCaretEnd

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

        jsr     _PrepTextParams
        pha                     ; A = len

        caret_pos := tmpw
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y
        sta     caret_pos

        add16_8 text_params::data, caret_pos
        pla                     ; A = len
        sec
        sbc     caret_pos
        beq     :+
        sta     text_params::length
        MGTK_CALL MGTK::DrawText, text_params
:
        rts
.endproc ; _RedrawRightOfCaret

;;; ============================================================
;;; Prepare params for a TextWidth or DrawText call
;;; Output: A=length (and Z=1 if empty)
;;;         `text_params::width` set to 0

.proc _PrepTextParams
        ldxy    a_buf
        inxy
        stxy    text_params::data
        ldy     #0
        sty     text_params::width
        sty     text_params::width+1
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

        len := tmpw

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
        sta     text_params::width
        sta     text_params::width+1
        sta     text_params::length
loop:   cmp16   text_params::width, params::xcoord
        bcs     :+
        inc     text_params::length
        lda     text_params::length
        cmp     len
        beq     :+
        MGTK_CALL MGTK::TextWidth, text_params
        beq     loop            ; always
:
        lda     text_params::length
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
        char := tmpw
        caret_pos := tmpw+1

        sta     char

        ;; Stash current caret pos
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y
        sta     caret_pos

        ;; Is there room?
        ldy     #0
        lda     (a_buf),y
        cmp     max_length
        bcs     ret

        ;; Move everything to right of caret up
        tay
:       cpy     caret_pos
        beq     :+
        lda     (a_buf),y
        iny
        sta     (a_buf),y
        dey
        dey
        bne     :-              ; always
:
        ;; Insert
        lda     char
        iny
        sta     (a_buf),y
        ldy     #0
        lda     (a_buf),y
        clc
        adc     #1
        sta     (a_buf),y

        bit     options         ; bit7 = centered
    IF_NS
        ;; Redraw everything
        jsr     _ClearAndDrawText
    ELSE
        ;; Redraw string to right of old caret position
        jsr     _RedrawRightOfCaret
    END_IF

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
        beq     _InsertChar::ret

        lda     #0
        sta     (a_buf),y
        ldy     #LETK::LineEditRecord::caret_pos
        sta     (a_record),y

        jmp     _ClearAndDrawText
.endproc ; _DeleteLine

;;; ============================================================

.proc _ClearRect
        ;; NOTE: Don't include `_SetPort` call in `_ClearRect`
        ;; because if the port is obscured then `_SetPort` pops
        ;; the caller!
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, rect
        rts
.endproc ; _ClearRect

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
        len := tmpw

        ;; Shrink buffer
        ldy     #0
        lda     (a_buf),y
        sec
        sbc     #1
        sta     (a_buf),y
        sta     len

        ;; Move everything to the right of the caret down
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y
        tay
:       cpy     len
        beq     :+
        iny
        iny
        lda     (a_buf),y
        dey
        sta     (a_buf),y
        bne     :-              ; always
:
        bit     options         ; bit7 = centered
    IF_NS
        ;; Redraw everything
        jmp     _ClearAndDrawText
    END_IF

        ;; Redraw everything to the right of the caret
        jsr     _RedrawRightOfCaret
        jsr     _PrepTextParams
    IF_NOT_ZERO
        MGTK_CALL MGTK::TextWidth, text_params
        add16   pos, text_params::width, rect+MGTK::Rect::x1
    END_IF
        jmp     _ClearRect
.endproc ; _DeleteCharCommon

;;; ============================================================
;;; Output: A,X = X coordinate of caret

.proc _CalcCaretPos
        jsr     _PrepTextParams

        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y
    IF_NOT_ZERO
        sta     text_params::length
        MGTK_CALL MGTK::TextWidth, text_params
    END_IF

        lda     text_params::width
        clc
        adc     pos + MGTK::Point::xcoord
        tay
        lda     text_params::width+1
        adc     pos + MGTK::Point::xcoord+1
        tax
        tya
        rts
.endproc ; _CalcCaretPos

;;; ============================================================
;;; Clears and redraws text. The caret must be redrawn afterwards
;;; by the caller.

.proc _ClearAndDrawText
        jsr     _SetPort

        jsr     _ClearRect
        jsr     _CalcPos
        MGTK_CALL MGTK::MoveTo, pos

        jsr     _PrepTextParams
    IF_NOT_ZERO
        MGTK_CALL MGTK::DrawText, text_params
    END_IF

        rts
.endproc ; _ClearAndDrawText

;;; ============================================================
;;; Redraw the contents of the control; used after a window move or string change.

.proc UpdateImpl
        PARAM_BLOCK params, letk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        ;; Implicitly hides caret
        jsr     _ClearAndDrawText

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
