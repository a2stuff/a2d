;;; ============================================================
;;; LineEdit ToolKit
;;; ============================================================

.scope letk
        LETKEntry := *

;;; ============================================================
;;; Zero Page usage (saved/restored around calls)

        zp_start := $50
        kMaxCommandDataSize = 6
        kMaxTmpSpace = .sizeof(MGTK::Point)

PARAM_BLOCK, zp_start
;;; Points at call parameters (i.e. ButtonRecord)
params_addr     .addr

;;; Copy of the passed params
command_data    .res    kMaxCommandDataSize

;;; A temporary copy of the control record
ler_copy        .tag    LETK::LineEditRecord

;;; Other ZP usage
pos             .tag    MGTK::Point ; Calculated from rect
text_params     .tag    MGTK::TextWidthParams
tmp_space       .res    kMaxTmpSpace

;;; For size calculation, not actually used
zp_end          .byte
END_PARAM_BLOCK

        .assert zp_end <= $78, error, "too big"
        kBytesToSave = zp_end - zp_start

        a_record        := command_data ; always first element of `command_data`
        tmpw            := tmp_space

        ;; Aliases for the copy's members:
        window_id  := ler_copy + LETK::LineEditRecord::window_id
        a_buf      := ler_copy + LETK::LineEditRecord::a_buf
        rect       := ler_copy + LETK::LineEditRecord::rect
        max_length := ler_copy + LETK::LineEditRecord::max_length
        options    := ler_copy + LETK::LineEditRecord::options

;;; ============================================================

        .assert LETKEntry = Dispatch, error, "dispatch addr"
.proc Dispatch
        ;; Adjust stack/stash
        pla
        sta     params_lo
        clc
        adc     #<3
        tax
        pla
        sta     params_hi
        adc     #>3
        phax

        ;; Save ZP
        PUSH_BYTES kBytesToSave, zp_start

        ;; Point `params_addr` at the call site
        params_lo := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     params_addr
        params_hi := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     params_addr+1

        ;; Grab command number
        ldy     #1              ; Note: rts address is off-by-one
        lda     (params_addr),y
        tax
        copylohi jump_table_lo,x, jump_table_hi,x, dispatch

        ;; Point `params_addr` at actual params
        iny
        lda     (params_addr),y
        tax
        iny
        lda     (params_addr),y
        sta     params_addr+1
        stx     params_addr

        ;; Copy param data to `command_data`
        ldy     #kMaxCommandDataSize-1
:       copy8   (params_addr),y, command_data,y
        dey
        bpl     :-

        ;; Cache static copy of the record in `ler_copy`, for convenience
        ldy     #.sizeof(LETK::LineEditRecord)-1
:       copy8   (a_record),y, ler_copy,y
        dey
        bpl     :-

        ;; Compute constants
        jsr     _CalcPos

        ;; Invoke the command
        dispatch := *+1
        jsr     SELF_MODIFIED
        tay                     ; A = result

        ;; Restore ZP
        POP_BYTES kBytesToSave, zp_start

        tya                     ; A = result
        rts

jump_table_lo:
        .lobytes   InitImpl
        .lobytes   IdleImpl
        .lobytes   ActivateImpl
        .lobytes   DeactivateImpl
        .lobytes   ClickImpl
        .lobytes   KeyImpl
        .lobytes   UpdateImpl

jump_table_hi:
        .hibytes   InitImpl
        .hibytes   IdleImpl
        .hibytes   ActivateImpl
        .hibytes   DeactivateImpl
        .hibytes   ClickImpl
        .hibytes   KeyImpl
        .hibytes   UpdateImpl

        ASSERT_EQUALS *-jump_table_hi, jump_table_hi-jump_table_lo
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
    IF NS
        add16   rect+MGTK::Rect::x1, rect+MGTK::Rect::x2, pos+MGTK::Point::xcoord

        jsr     _PrepTextParams
      IF NOT_ZERO
        MGTK_CALL MGTK::TextWidth, text_params
      END_IF

        sub16   pos+MGTK::Point::xcoord, text_params+MGTK::TextWidthParams::width, pos+MGTK::Point::xcoord
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
        CALL    ReadSetting, X=#DeskTopSettings::caret_blink_speed+1
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
    IF NC
ret:    rts
    END_IF

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
PARAM_BLOCK point, letk::tmp_space
xcoord  .word
ycoord  .word
END_PARAM_BLOCK

        jsr     _SetPort        ; aborts rest of this proc if obscured

        jsr     _CalcCaretPos
        stax    point::xcoord
        dec16   point::xcoord          ; between characters
        copy16  pos + MGTK::Point::ycoord, point::ycoord

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

;;; If obscured, caller is popped so returns to caller's caller.
;;; Output: If this returns, Z=1
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
        copy8   #$80, (a_record),y

        bne     _ShowCaret      ; always
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
        jsr     _SetPort        ; aborts rest of this proc if obscured

PARAM_BLOCK point, letk::tmp_space
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
        copy8   (a_record),y, caret_pos

        add16_8 text_params+MGTK::TextWidthParams::data, caret_pos
        pla                     ; A = len
        sec
        sbc     caret_pos
    IF NOT_ZERO
        sta     text_params+MGTK::TextWidthParams::length
        MGTK_CALL MGTK::DrawText, text_params
    END_IF
        rts
.endproc ; _RedrawRightOfCaret

;;; ============================================================
;;; Prepare params for a TextWidth or DrawText call
;;; Output: A=length (and Z=1 if empty)
;;;         `text_params+MGTK::TextWidthParams::width` set to 0

.proc _PrepTextParams
        ldxy    a_buf
        inxy
        stxy    text_params+MGTK::TextWidthParams::data
        ldy     #0
        sty     text_params+MGTK::TextWidthParams::width
        sty     text_params+MGTK::TextWidthParams::width+1
        copy8   (a_buf),y, text_params+MGTK::TextWidthParams::length
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
    IF NEG
        lda     #0
        beq     set             ; always
    END_IF

        ;; Iterate to find the position
        lda     #0
        sta     text_params+MGTK::TextWidthParams::width
        sta     text_params+MGTK::TextWidthParams::width+1
        sta     text_params+MGTK::TextWidthParams::length
    DO
        cmp16   text_params+MGTK::TextWidthParams::width, params::xcoord
        BREAK_IF GE
        inc     text_params+MGTK::TextWidthParams::length
        lda     text_params+MGTK::TextWidthParams::length
        BREAK_IF A = len
        MGTK_CALL MGTK::TextWidth, text_params
    WHILE ZERO                  ; always

        lda     text_params+MGTK::TextWidthParams::length
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
    IF A <> (a_buf),y
        clc
        adc     #1
        ldy     #LETK::LineEditRecord::caret_pos
        sta     (a_record),y
    END_IF

        rts
.endproc ; _MoveCaretRight

;;; ============================================================
;;; When delete (backspace) is hit

.proc _DeleteLeft
        ;; Anything to delete?
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y    ; A = caret_pos
    IF NOT_ZERO
        sec
        sbc     #1
        sta     (a_record),y
        jsr     _DeleteCharCommon
    END_IF

        rts
.endproc ; _DeleteLeft

;;; ============================================================
;;; Forward-delete

.proc _DeleteRight
        ;; Anything to delete?
        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y    ; A = caret_pos

        ldy     #0
    IF A <> (a_buf),y
        jsr     _DeleteCharCommon
    END_IF

        rts
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
        copy8   (a_record),y, caret_pos

        ;; Is there room?
        ldy     #0
        lda     (a_buf),y
    IF A < max_length
        ;; Move everything to right of caret up
        tay
      DO
        BREAK_IF Y = caret_pos
        lda     (a_buf),y
        iny
        sta     (a_buf),y
        dey
        dey
      WHILE NOT_ZERO            ; always

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
      IF NS
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
    END_IF

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
    DO
        BREAK_IF Y = len
        iny
        iny
        lda     (a_buf),y
        dey
        sta     (a_buf),y
    WHILE NOT_ZERO              ; always

        bit     options         ; bit7 = centered
    IF NS
        ;; Redraw everything
        jmp     _ClearAndDrawText
    END_IF

        ;; Redraw everything to the right of the caret
        jsr     _RedrawRightOfCaret
        jsr     _PrepTextParams
    IF NOT_ZERO
        MGTK_CALL MGTK::TextWidth, text_params
        add16   pos, text_params+MGTK::TextWidthParams::width, rect+MGTK::Rect::x1
    END_IF
        jsr     _SetPort        ; aborts rest of this proc if obscured
        beq     _ClearRect      ; always
.endproc ; _DeleteCharCommon

;;; ============================================================
;;; Output: A,X = X coordinate of caret

.proc _CalcCaretPos
        jsr     _PrepTextParams

        ldy     #LETK::LineEditRecord::caret_pos
        lda     (a_record),y
    IF NOT_ZERO
        sta     text_params+MGTK::TextWidthParams::length
        MGTK_CALL MGTK::TextWidth, text_params
    END_IF

        lda     text_params+MGTK::TextWidthParams::width
        clc
        adc     pos + MGTK::Point::xcoord
        tay
        lda     text_params+MGTK::TextWidthParams::width+1
        adc     pos + MGTK::Point::xcoord+1
        tax
        tya
        rts
.endproc ; _CalcCaretPos

;;; ============================================================
;;; Clears and redraws text. The caret must be redrawn afterwards
;;; by the caller.

.proc _ClearAndDrawText
        jsr     _SetPort        ; aborts rest of this proc if obscured

        jsr     _ClearRect
        jsr     _CalcPos
        MGTK_CALL MGTK::MoveTo, pos

        jsr     _PrepTextParams
    IF NOT_ZERO
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
    IF LT
        sta     (a_record),y    ; no, clamp caret_pos
    END_IF

        jmp     _ShowCaret
.endproc ; UpdateImpl

;;; ============================================================

.endscope ; letk
