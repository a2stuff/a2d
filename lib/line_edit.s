;;; ============================================================

.proc BlinkIP
        ;; Toggle flag
        lda     line_edit_res::ip_flag
        eor     #$80
        sta     line_edit_res::ip_flag

        FALL_THROUGH_TO XDrawIP
.endproc

.proc XDrawIP
        point := $6
        xcoord := $6
        ycoord := $8

        jsr     SetPort

        ;; TODO: Do this with a 1px rect instead of a line
        jsr     CalcIPPos
        stax    xcoord
        dec16   xcoord
        copy16  textpos + MGTK::Point::ycoord, ycoord

        MGTK_CALL MGTK::MoveTo, point
        MGTK_CALL MGTK::SetPenMode, penXOR
        copy16  #0, xcoord
        copy16  #AS_WORD(-kSystemFontHeight), ycoord
        MGTK_CALL MGTK::Line, point
        MGTK_CALL MGTK::SetPenMode, pencopy

        rts
.endproc

.proc HideIP
        bit     line_edit_res::ip_flag
        bmi     XDrawIP
        rts
.endproc
ShowIP := HideIP

;;; ============================================================

.proc Redraw
        jsr     SetPort

        ;; Unnecessary - the entire field will be repainted.
        ;; jsr     HideIP        ; Redraw

        MGTK_CALL MGTK::PaintRect, clear_rect
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::MoveTo, textpos
        param_call DrawString, buf_left
        param_call DrawString, buf_right

        jsr     ShowIP

        rts
.endproc

;;; ============================================================
;;; A click when f1 has focus (click may be elsewhere)

.proc HandleClick
        ;; Is click to left or right of insertion point?
        jsr     CalcIPPos
        width := $06
        stax    width
        cmp16   click_coords, width
        jcc     ToLeft
        FALL_THROUGH_TO ToRight

        PARAM_BLOCK tw_params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        ;; --------------------------------------------------
        ;; Click is to the right of IP

.proc ToRight
        lda     buf_right
        beq     ret

        jsr     CalcIPPos
        stax    ip_pos

        ;; Iterate to find the position
        copy16  #buf_right, tw_params::data
        copy    buf_right, tw_params::length
@loop:  MGTK_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, ip_pos, tw_params::width
        cmp16   tw_params::width, click_coords
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        bne     @loop
ret:    rts

        ;; Was it to the right of the string?
:       lda     tw_params::length
        beq     ret
        cmp     buf_right
        bcc     :+
        jmp     MoveIPEnd
:
        copy    tw_params::length, len
        jsr     HideIP          ; Click Right

        ;; Append from `buf_right` into `buf_left`
        ldx     #1
        ldy     buf_left
        iny
:       lda     buf_right,x
        sta     buf_left,y
        cpx     len
        beq     :+
        iny
        inx
        jmp     :-
:       sty     buf_left

        ;; Shift contents of `buf_right` down
        ldy     #1
        len := *+1
        ldx     #SELF_MODIFIED_BYTE
        inx
:       lda     buf_right,x
        sta     buf_right,y
        cpx     buf_right
        beq     :+
        iny
        inx
        jmp     :-

:       sty     buf_right
        jmp     finish
.endproc

        ;; --------------------------------------------------
        ;; Click to left of IP

.proc ToLeft
        lda     buf_left
        bne     :+
ret:    rts
:
        ;; Iterate to find the position
        copy16  #buf_left, tw_params::data
        copy    buf_left, tw_params::length
@loop:  MGTK_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, textpos + MGTK::Point::xcoord, tw_params::width
        cmp16   tw_params::width, click_coords
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bcs     @loop
        jmp     MoveIPStart
:
        lda     tw_params::length
        cmp     buf_left
        bcs     ret
        sta     len

        jsr     HideIP          ; Click Left
        inc     len

        ;; Shift everything in `buf_right` up to make room
        lda     buf_right
        pha
        lda     buf_left
        sec
        sbc     len
        clc
        adc     buf_right
        sta     buf_right
        tax
        pla
    IF_NOT_ZERO
        tay
:       lda     buf_right,y
        sta     buf_right,x
        dex
        dey
        bne     :-
    END_IF

        ;; Copy everything to the right from `buf_left` to `buf_right`
        ldy     #0
        len := *+1
        ldx     #SELF_MODIFIED_BYTE
:       cpx     buf_left
        beq     :+
        inx
        iny
        lda     buf_left,x
        sta     buf_right,y
        jmp     :-
:
        ;; Adjust length
        copy    len, buf_left
        FALL_THROUGH_TO finish
.endproc

finish: jsr     ShowIP
        rts

ip_pos: .word   0
.endproc ; HandleClick

;;; ============================================================
;;; Handle a key. Requires `event_params` to be defined.

.proc HandleKey
        MGTK_CALL MGTK::ObscureCursor

        lda     event_params::key

        ldx     event_params::modifiers
    IF_ZERO
        ;; Not modified
        cmp     #CHAR_LEFT
        jeq     MoveIPLeft

        cmp     #CHAR_RIGHT
        jeq     MoveIPRight

        cmp     #CHAR_DELETE
        jeq     DeleteLeft

        cmp     #CHAR_CTRL_F
        jeq     DeleteRight

        cmp     #CHAR_CLEAR
        jeq     DeleteLine

        cmp     #' '
        jcs     InsertChar
    ELSE
        ;; Modified
        cmp     #CHAR_LEFT
        jeq     MoveIPStart

        cmp     #CHAR_RIGHT
        jeq     MoveIPEnd
    END_IF

        rts
.endproc

;;; ============================================================
;;; When a non-control key is hit - insert the passed character

.proc InsertChar
        sta     char

        ;; Is it allowed?
        bit     line_edit_res::allow_all_chars_flag
        bmi     :+
        jsr     IsAllowedChar
        bcs     ret
:
        ;; Is there room?
        lda     buf_left
        clc
        adc     buf_right
        cmp     #kLineEditMaxLength ; TODO: Off-by-one now that IP is gone?
        bcs     ret

        jsr     HideIP          ; Insert

        ;; Insert, and redraw single char and right string
        char := *+1
        lda     #SELF_MODIFIED_BYTE
        ldx     buf_left
        inx
        sta     buf_left,x
        sta     line_edit_res::str_1_char+1

        ;; Redraw string to right of IP

        point := $6
        xcoord := $6
        ycoord := $8

        jsr     CalcIPPos ; measure before updating length
        inc     buf_left

        stax    xcoord
        copy16  textpos + MGTK::Point::ycoord, ycoord
        jsr     SetPort
        MGTK_CALL MGTK::MoveTo, point
        param_call DrawString, line_edit_res::str_1_char
        param_call DrawString, buf_right

        jsr     ShowIP
        jsr     NotifyTextChanged

ret:    rts
.endproc

;;; ============================================================
;;; When delete (backspace) is hit - shrink left buffer by one

.proc DeleteLeft
        ;; Anything to delete?
        lda     buf_left
        beq     ret

        jsr     HideIP          ; Delete

        point := $6
        xcoord := $6
        ycoord := $8

        ;; Decrease length of left string, measure and redraw right string
        dec     buf_left
        jsr     CalcIPPos
        stax    xcoord
        copy16  textpos + MGTK::Point::ycoord, ycoord
        jsr     SetPort
        MGTK_CALL MGTK::MoveTo, point
        param_call DrawString, buf_right
        param_call DrawString, line_edit_res::str_2_spaces

        jsr     ShowIP
        jsr     NotifyTextChanged

ret:    rts
.endproc

;;; ============================================================
;;; Forward-delete

.proc DeleteRight
        ;; Anything to delete?
        lda     buf_right
        beq     ret

        jsr     HideIP          ; Delete

        ;; Shift right string down
        ldx     #1
:       cpx     buf_right
        beq     :+
        lda     buf_right+1,x
        sta     buf_right,x
        inx
        bne     :-              ; always

:       dec     buf_right

        ;; Redraw string to right of IP

        point := $6
        xcoord := $6
        ycoord := $8

        jsr     CalcIPPos
        stax    xcoord
        copy16  textpos + MGTK::Point::ycoord, ycoord
        jsr     SetPort
        MGTK_CALL MGTK::MoveTo, point
        param_call DrawString, buf_right
        param_call DrawString, line_edit_res::str_2_spaces

        jsr     ShowIP
        jsr     NotifyTextChanged

ret:    rts
.endproc

;;; ============================================================

.proc DeleteLine
        ;; Anything to delete?
        lda     buf_left
        ora     buf_right
        beq     ret

        ;; Unnecessary - the entire field will be repainted.
        ;; jsr     HideIP          ; Clear

        lda     #0
        sta     buf_left
        sta     buf_right

        jsr     SetPort
        MGTK_CALL MGTK::PaintRect, clear_rect

        jsr     ShowIP
        jsr     NotifyTextChanged

ret:    rts
.endproc

;;; ============================================================
;;; Move IP one character left.

.proc MoveIPLeft
        ;; Any characters to left of IP?
        lda     buf_left
        beq     ret

        jsr     HideIP          ; Left

        ;; Shift right up by a character if needed.
        ldx     buf_right
    IF_NOT_ZERO
:       lda     buf_right,x
        sta     buf_right+1,x
        dex
        bne     :-
    END_IF

        ;; Copy character left to right and adjust lengths.
        ldx     buf_left
        lda     buf_left,x
        sta     buf_right+1
        dec     buf_left
        inc     buf_right

        ;; Finish up
        jsr     ShowIP

ret:    rts
.endproc

;;; ============================================================
;;; Move IP one character right.

.proc MoveIPRight
        ;; Any characters to right of IP?
        lda     buf_right
        beq     ret

        jsr     HideIP          ; Right

        ;; Copy first char from right to left and adjust left length.
        lda     buf_right+1
        ldx     buf_left
        inx
        sta     buf_left,x
        inc     buf_left

        ;; Shift right string down, if needed.
        lda     buf_right
        cmp     #2
    IF_GE
        ldx     #1
:       lda     buf_right+1,x
        sta     buf_right,x
        inx
        cpx     buf_right
        bne     :-
    END_IF
        dec     buf_right

        ;; Finish up
        jsr     ShowIP

ret:    rts
.endproc

;;; ============================================================
;;; Move IP to start of input field.

.proc MoveIPStart
        ;; Any characters to left of IP?
        lda     buf_left
        beq     ret

        jsr     HideIP          ; Home

        ;; Shift right string up N
        lda     buf_left
        clc
        adc     buf_right
        tay
        ldx     buf_right
:       beq     move
        copy    buf_right,x, buf_right,y
        dex
        dey
        bne     :-              ; always

        ;; Move chars from left string to right string
move:   ldx     buf_left
:       copy    buf_left,x, buf_right,x
        dex
        bne     :-

        ;; Adjust lengths
        lda     buf_left
        clc
        adc     buf_right
        sta     buf_right

        copy    #0, buf_left

        ;; Finish up
        jsr     ShowIP

ret:    rts
.endproc

;;; ============================================================

.proc MoveIPEnd
        lda     buf_right
        beq     ret

        jsr     HideIP          ; End

        ;; Append right string to left
        ldx     #0
        ldy     buf_left
:       inx
        iny
        lda     buf_right,x
        sta     buf_left,y
        cpx     buf_right
        bne     :-
        sty     buf_left

        ;; Clear right string
        copy    #0, buf_right

        jsr     ShowIP

ret:    rts
.endproc

;;; ============================================================
;;; Output: A,X = X coordinate of insertion point

.proc CalcIPPos
        PARAM_BLOCK params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        copy16  #0, params::width
        lda     buf_left
        beq     :+

        sta     params::length
        copy16  #buf_left+1, params::data
        MGTK_CALL MGTK::TextWidth, params

:       lda     params::width
        clc
        adc     textpos + MGTK::Point::xcoord
        tay
        lda     params::width+1
        adc     textpos + MGTK::Point::xcoord+1
        tax
        tya
        rts
.endproc
