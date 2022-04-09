;;; ============================================================
;;; API:
;;; * `Idle` - call from event loop; blinks IP
;;; * `Update` - call to repaint control entirely, IP moved to end
;;; * `Click` - call with mapped `click_coords` populated
;;; * `Key` - call with `event_params` populated
;;; * `ShowIP` / `HideIP` - when changing focus
;;; Internal procs are prefixed with `_`
;;; TODO:
;;; * Add Init the resets state
;;; * Add Activate/Deactivate that handle showing/hiding/positioning IP
;;;
;;; Requirements:
;;; * `buf_text` - string to edit
;;; * `kLineEditMaxLength` - max length of string
;;; * `frame_rect` - outline of control
;;; * `clear_rect` - to erase contents of control
;;; * `textpos` - position of text
;;; * `SetPort` - called to set up GrafPort for drawing
;;; * `NotifyTextChanged` - called when string changes
;;; * `click_coords` - for `Click`, in window coords
;;; * `event_params` - for `Key`
;;; * `IsAllowedChar` - filter, called if `line_edit_res::allow_all_chars_flag` is set
;;; * `line_edit_res::allow_all_chars_flag` - set if more than path chars allowed
;;; * `line_edit_res::blink_ip_flag` - set to enable blinking IP
;;; * `line_edit_res::ip_pos` - IP position
;;; ============================================================

.proc Idle
        bit     line_edit_res::blink_ip_flag
        bmi     :+
ret:    rts
:
        dec16   line_edit_res::ip_counter
        lda     line_edit_res::ip_counter
        ora     line_edit_res::ip_counter+1
        bne     ret

        copy16  SETTINGS + DeskTopSettings::ip_blink_speed, line_edit_res::ip_counter
        lda     line_edit_res::ip_flag
        eor     #$80
        sta     line_edit_res::ip_flag

        FALL_THROUGH_TO _XDrawIP
.endproc

.proc _XDrawIP
        point := $6
        xcoord := $6
        ycoord := $8

        jsr     SetPort

        ;; TODO: Do this with a 1px rect instead of a line
        jsr     _CalcIPPos
        stax    xcoord
        dec16   xcoord          ; between characters
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
        bmi     _XDrawIP
        rts
.endproc
ShowIP := HideIP

;;; ============================================================

.proc Update
        jsr     SetPort

        ;; Unnecessary - the entire field will be repainted.
        ;; jsr     HideIP

        MGTK_CALL MGTK::PaintRect, clear_rect
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::MoveTo, textpos
        param_call DrawString, buf_text
        copy    buf_text, line_edit_res::ip_pos
        jmp     ShowIP
.endproc

;;; ============================================================
;;; Internal proc: used as part of insert/delete procs

.proc _RedrawRightOfIP
        jsr     SetPort

PARAM_BLOCK point, $06
xcoord  .word
ycoord  .word
END_PARAM_BLOCK

        jsr     _CalcIPPos
        stax    point::xcoord
        copy16  textpos + MGTK::Point::ycoord, point::ycoord
        MGTK_CALL MGTK::MoveTo, point

PARAM_BLOCK dt_params, $06
data    .addr
length  .byte
END_PARAM_BLOCK

        add16_8 #buf_text+1, line_edit_res::ip_pos, dt_params::data
        lda     buf_text
        sec
        sbc     line_edit_res::ip_pos
        beq     :+
        sta     dt_params::length
        MGTK_CALL MGTK::DrawText, dt_params
:
        rts
.endproc

;;; ============================================================
;;; A click when f1 has focus (click may be elsewhere)

.proc Click
        lda     buf_text
        beq     ret

        PARAM_BLOCK tw_params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        ;; Iterate to find the position
        copy16  #buf_text+1, tw_params::data
        copy16  #0, tw_params::width
        copy    #0, tw_params::length
loop:   add16   tw_params::width, textpos + MGTK::Point::xcoord, tw_params::width
        cmp16   tw_params::width, click_coords
        bpl     :+
        inc     tw_params::length
        lda     tw_params::length
        cmp     buf_text
        beq     :+
        MGTK_CALL MGTK::TextWidth, tw_params
        beq     loop            ; always
:
        lda     tw_params::length
        pha
        jsr     HideIP
        pla
        sta     line_edit_res::ip_pos
        jsr     ShowIP

ret:    rts
.endproc ; Click

;;; ============================================================
;;; Handle a key. Requires `event_params` to be defined.

.proc Key
        MGTK_CALL MGTK::ObscureCursor

        lda     event_params::key

        ldx     event_params::modifiers
    IF_ZERO
        ;; Not modified
        cmp     #CHAR_LEFT
        jeq     _MoveIPLeft

        cmp     #CHAR_RIGHT
        jeq     _MoveIPRight

        cmp     #CHAR_DELETE
        jeq     _DeleteLeft

        cmp     #CHAR_CTRL_F
        jeq     _DeleteRight

        cmp     #CHAR_CLEAR
        jeq     _DeleteLine

        cmp     #' '
        jcs     _InsertChar
    ELSE
        ;; Modified
        cmp     #CHAR_LEFT
        jeq     _MoveIPStart

        cmp     #CHAR_RIGHT
        jeq     _MoveIPEnd
    END_IF

        rts
.endproc

;;; ============================================================
;;; When a non-control key is hit - insert the passed character

.proc _InsertChar
        sta     char

        ;; Is it allowed?
        bit     line_edit_res::allow_all_chars_flag
        bmi     :+
        jsr     IsAllowedChar
        bcs     ret
:
        ;; Is there room?
        lda     buf_text
        cmp     #kLineEditMaxLength ; TODO: Off-by-one now that IP is gone?
        bcs     ret

        jsr     HideIP

        ;; Move everything to right of IP up
        ldx     buf_text
:       cpx     line_edit_res::ip_pos
        beq     :+
        lda     buf_text,x
        sta     buf_text+1,x
        dex
        bne     :-              ; always
:
        ;; Insert
        char := *+1
        lda     #SELF_MODIFIED_BYTE
        inx
        sta     buf_text,x
        inc     buf_text

        ;; Redraw string to right of old IP position
        jsr     _RedrawRightOfIP

        ;; Now move IP to new position
        inc     line_edit_res::ip_pos

        jsr     ShowIP
        jsr     NotifyTextChanged

ret:    rts
.endproc

;;; ============================================================
;;; When delete (backspace) is hit

.proc _DeleteLeft
        ;; Anything to delete?
        lda     line_edit_res::ip_pos
        beq     ret

        jsr     HideIP

        dec     line_edit_res::ip_pos

        jsr     _DeleteCharCommon

ret:    rts
.endproc

;;; ============================================================
;;; Forward-delete

.proc _DeleteRight
        ;; Anything to delete?
        lda     line_edit_res::ip_pos
        cmp     buf_text
        beq     ret

        jsr     HideIP

        jsr     _DeleteCharCommon

ret:    rts
.endproc

;;; ============================================================
;;; Common logic for DeleteLeft/DeleteRight

.proc _DeleteCharCommon
        ;; Shrink buffer
        dec     buf_text

        ;; Move everything to the right of the IP down
        ldx     line_edit_res::ip_pos
:       cpx     buf_text
        beq     :+
        lda     buf_text+2,x
        sta     buf_text+1,x
        inx
        bne     :-              ; always
:
        ;; Redraw everything to the right of the IP
        jsr     _RedrawRightOfIP
        param_call DrawString, line_edit_res::str_2_spaces

        jsr     ShowIP
        jmp     NotifyTextChanged
.endproc

;;; ============================================================

.proc _DeleteLine
        ;; Anything to delete?
        lda     buf_text
        beq     ret

        ;; Unnecessary - the entire field will be repainted.
        ;; jsr     HideIP

        lda     #0
        sta     buf_text
        sta     line_edit_res::ip_pos

        jsr     SetPort
        MGTK_CALL MGTK::PaintRect, clear_rect

        jsr     ShowIP
        jsr     NotifyTextChanged

ret:    rts
.endproc

;;; ============================================================
;;; Move IP one character left.

.proc _MoveIPLeft
        ;; Any characters to left of IP?
        lda     line_edit_res::ip_pos
        beq     ret

        jsr     HideIP
        dec     line_edit_res::ip_pos
        jsr     ShowIP

ret:    rts
.endproc

;;; ============================================================
;;; Move IP one character right.

.proc _MoveIPRight
        ;; Any characters to right of IP?
        lda     line_edit_res::ip_pos
        cmp     buf_text
        beq     ret

        jsr     HideIP
        inc     line_edit_res::ip_pos
        jsr     ShowIP

ret:    rts
.endproc

;;; ============================================================
;;; Move IP to start of input field.

.proc _MoveIPStart
        jsr     HideIP
        copy    #0, line_edit_res::ip_pos
        jmp     ShowIP
.endproc

;;; ============================================================

.proc _MoveIPEnd
        jsr     HideIP
        copy    buf_text, line_edit_res::ip_pos
        jmp     ShowIP
.endproc

;;; ============================================================
;;; Output: A,X = X coordinate of insertion point

.proc _CalcIPPos
        PARAM_BLOCK params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        copy16  #0, params::width
        lda     line_edit_res::ip_pos
        beq     :+

        sta     params::length
        copy16  #buf_text+1, params::data
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

;;; ============================================================
;;; Handy debugging routine; draws an edit control's full text under
;;; the control itself. Drop calls in whenever the text would have
;;; changed.

.if 0
.proc _DebugText
PARAM_BLOCK point, $06
xcoord  .word
ycoord  .word
END_PARAM_BLOCK

        copy16  textpos + MGTK::Point::xcoord, point::xcoord
        add16_8 textpos + MGTK::Point::ycoord, #12, point::ycoord
        MGTK_CALL MGTK::MoveTo, point

PARAM_BLOCK dt_params, $06
data    .addr
length  .byte
END_PARAM_BLOCK

        copy16  #buf_text+1, dt_params::data
        copy    buf_text, dt_params::length
        beq     :+
        MGTK_CALL MGTK::DrawText, dt_params
:       param_jump DrawString, line_edit_res::str_2_spaces
.endproc
.endif