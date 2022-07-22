
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
.endproc

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
        ldy     #LETK::LineEditRecord::dirty_flag
        sta     (a_record),y
        .assert (LETK::LineEditRecord::active_flag - LETK::LineEditRecord::dirty_flag) = 1, error, "order"
        iny
        sta     (a_record),y
        .assert (LETK::LineEditRecord::ip_pos - LETK::LineEditRecord::active_flag) = 1, error, "order"
        iny
        sta     (a_record),y
        .assert (LETK::LineEditRecord::ip_flag - LETK::LineEditRecord::ip_pos) = 1, error, "order"
        iny
        sta     (a_record),y
        .assert (LETK::LineEditRecord::ip_counter - LETK::LineEditRecord::ip_flag) = 1, error, "order"

        jsr     UpdateImpl

        FALL_THROUGH_TO _ResetIPCounter
.endproc ; InitImpl

.proc _ResetIPCounter
        ldy     #LETK::LineEditRecord::ip_counter
        copy16in SETTINGS + DeskTopSettings::ip_blink_speed, (a_record),y
        rts
.endproc

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

        ldy     #LETK::LineEditRecord::ip_counter
        sub16in (a_record),y, #1, (a_record),y

        lda     (a_record),y  ; Y = LETK::LineEditRecord::ip_counter+1
        dey
        ora     (a_record),y  ; Y = LETK::LineEditRecord::ip_counter
        bne     ret

        jsr     _ResetIPCounter

        ldy     #LETK::LineEditRecord::ip_flag
        lda     (a_record),y
        eor     #$80
        sta     (a_record),y

        FALL_THROUGH_TO _XDrawIP
.endproc ; IdleImpl

.proc _XDrawIP
        point := $6
        xcoord := $6
        ycoord := $8

        jsr     _SetPort

        jsr     _CalcIPPos
        stax    xcoord
        dec16   xcoord          ; between characters
        copy16  pos + MGTK::Point::ycoord, ycoord

        MGTK_CALL MGTK::MoveTo, point
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::Line, ip_move
        MGTK_CALL MGTK::SetPenMode, pencopy

        rts
.endproc

        ;; Delta from text baseline to top of text, for drawing IP
        DEFINE_POINT ip_move, 0, AS_WORD(-kSystemFontHeight)

.proc _HideIP
        ldy     #LETK::LineEditRecord::ip_flag
        lda     (a_record),y
        bmi     _XDrawIP
        rts
.endproc
_ShowIP := _HideIP

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
.endproc

;;; ============================================================

.proc ActivateImpl
        PARAM_BLOCK params, letk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        ;; Idempotent, to allow Activate to be used to just move IP
        jsr     _HideIP

        ;; Move IP to end
        ldy     #0
        lda     (a_buf),y
        ldy     #LETK::LineEditRecord::ip_pos
        sta     (a_record),y

        ;; Set active flag
        ldy     #LETK::LineEditRecord::active_flag
        lda     #$80
        sta     (a_record),y

        jmp     _ShowIP
.endproc ; ActivateImpl

;;; ============================================================

.proc DeactivateImpl
        jsr     _HideIP

        ldy     #LETK::LineEditRecord::active_flag
        lda     #0
        sta     (a_record),y

        ldy     #LETK::LineEditRecord::ip_flag
        sta     (a_record),y

        rts
.endproc ; DeactivateImpl

;;; ============================================================
;;; Internal proc: used as part of insert/delete procs

.proc _RedrawRightOfIP
        jsr     _SetPort

PARAM_BLOCK point, $06
xcoord  .word
ycoord  .word
END_PARAM_BLOCK

        jsr     _CalcIPPos
        stax    point::xcoord
        copy16  pos + MGTK::Point::ycoord, point::ycoord
        MGTK_CALL MGTK::MoveTo, point

PARAM_BLOCK dt_params, $06
data    .addr
length  .byte
END_PARAM_BLOCK

        jsr     _PrepTextParams
        sta     @len

        ldy     #LETK::LineEditRecord::ip_pos
        lda     (a_record),y
        sta     @ip_pos

        add16_8 dt_params::data, @ip_pos, dt_params::data
        @len := *+1
        lda     #SELF_MODIFIED_BYTE
        sec
        @ip_pos := *+1
        sbc     #SELF_MODIFIED_BYTE
        beq     :+
        sta     dt_params::length
        MGTK_CALL MGTK::DrawText, dt_params
:
        rts
.endproc

;;; ============================================================
;;; Prepare params for a TextWidth or DrawText call
;;; Output: A=length (and Z=1 if empty)

.proc _PrepTextParams
PARAM_BLOCK text_params, $06
data    .addr
length  .byte
END_PARAM_BLOCK

        add16_8 a_buf, #1, text_params::data
        ldy     #0
        lda     (a_buf),y
        sta     text_params::length
        rts
.endproc

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
        pha
        jsr     _HideIP
        pla
        ldy     #LETK::LineEditRecord::ip_pos
        sta     (a_record),y
        jsr     _ShowIP

ret:    rts

.endproc ; ClickImpl

;;; ============================================================
;;; Move IP one character left.

.proc _MoveIPLeft
        ;; Any characters to left of IP?
        ldy     #LETK::LineEditRecord::ip_pos
        lda     (a_record),y
        beq     ret

        sec
        sbc     #1
        sta     (a_record),y

ret:    rts
.endproc

;;; ============================================================
;;; Move IP one character right.

.proc _MoveIPRight
        ;; Any characters to right of IP?
        ldy     #LETK::LineEditRecord::ip_pos
        lda     (a_record),y    ; A = ip_pos
        ldy     #0
        cmp     (a_buf),y
        beq     ret

        clc
        adc     #1
        ldy     #LETK::LineEditRecord::ip_pos
        sta     (a_record),y

ret:    rts
.endproc

;;; ============================================================
;;; When delete (backspace) is hit

.proc _DeleteLeft
        ;; Anything to delete?
        ldy     #LETK::LineEditRecord::ip_pos
        lda     (a_record),y    ; A = ip_pos
        beq     ret

        sec
        sbc     #1
        sta     (a_record),y

        jsr     _DeleteCharCommon

ret:    rts
.endproc

;;; ============================================================
;;; Forward-delete

.proc _DeleteRight
        ;; Anything to delete?
        ldy     #LETK::LineEditRecord::ip_pos
        lda     (a_record),y    ; A = ip_pos

        ldy     #0
        cmp     (a_buf),y
        beq     ret

        jsr     _DeleteCharCommon

ret:    rts
.endproc

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
        jsr     _HideIP
        jsr     :+
        jmp     _ShowIP

:       lda     params::key

        ldx     params::modifiers
        bne     modified

        ;; Not modified
        cmp     #CHAR_LEFT
        beq     _MoveIPLeft

        cmp     #CHAR_RIGHT
        beq     _MoveIPRight

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
        beq     _MoveIPStart

        cmp     #CHAR_RIGHT
        beq     _MoveIPEnd

        rts
.endproc ; KeyImpl

;;; ============================================================
;;; When a non-control key is hit - insert the passed character

.proc _InsertChar
        sta     char

        ;; Stash current IP pos
        ldy     #LETK::LineEditRecord::ip_pos
        lda     (a_record),y
        sta     @ip_pos

        ;; Is there room?
        ldy     #0
        lda     (a_buf),y
        cmp     max_length
        bcs     ret

        ;; Move everything to right of IP up
        tay
        @ip_pos := *+1
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

        ;; Redraw string to right of old IP position
        jsr     _RedrawRightOfIP

        ;; Now move IP to new position
        ldy     #LETK::LineEditRecord::ip_pos
        lda     (a_record),y
        clc
        adc     #1
        sta     (a_record),y

        jsr     _SetDirtyFlag

ret:    rts
.endproc

;;; ============================================================

.proc _DeleteLine
        ;; Anything to delete?
        ldy     #0
        lda     (a_buf),y
        beq     ret

        lda     #0
        sta     (a_buf),y
        ldy     #LETK::LineEditRecord::ip_pos
        sta     (a_record),y

        jsr     _SetPort
        MGTK_CALL MGTK::PaintRect, rect

        jsr     _SetDirtyFlag

ret:    rts
.endproc

;;; ============================================================
;;; Move IP to start of input field.

.proc _MoveIPStart
        lda     #0
        ldy     #LETK::LineEditRecord::ip_pos
        sta     (a_record),y
        rts
.endproc

;;; ============================================================
;;; Move IP to end of input field.

.proc _MoveIPEnd
        ldy     #0
        lda     (a_buf),y
        ldy     #LETK::LineEditRecord::ip_pos
        sta     (a_record),y
        rts
.endproc

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

        ;; Move everything to the right of the IP down
        ldy     #LETK::LineEditRecord::ip_pos
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
        ;; Redraw everything to the right of the IP
        jsr     _RedrawRightOfIP
        MGTK_CALL MGTK::DrawText, draw2spaces_params

        FALL_THROUGH_TO _SetDirtyFlag
.endproc

;;; ============================================================

.proc _SetDirtyFlag
        ldy     #LETK::LineEditRecord::dirty_flag
        lda     #$80
        sta     (a_record),y
        rts
.endproc

;;; ============================================================
;;; Output: A,X = X coordinate of insertion point

.proc _CalcIPPos
        PARAM_BLOCK tw_params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        jsr     _PrepTextParams
        copy16  #0, tw_params::width

        ldy     #LETK::LineEditRecord::ip_pos
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
.endproc

;;; ============================================================
;;; Redraw the contents of the control; used after a window move or string change.

.proc UpdateImpl
        PARAM_BLOCK params, letk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        jsr     _SetPort

        ;; Unnecessary - the entire field will be repainted.
        ;; jsr     _HideIP

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
        add16_8 a_buf, #1, dt_params::textptr
        MGTK_CALL MGTK::DrawText, dt_params
:

        ;; Fix IP position if string has shrunk
        ldy     #0
        lda     (a_buf),y
        ldy     #LETK::LineEditRecord::ip_pos
        cmp     (a_record),y    ; len >= ip_pos
        bcs     :+
        sta     (a_record),y    ; no, clamp ip_pos
:
        jmp     _ShowIP
.endproc ; UpdateImpl

;;; ============================================================

.endscope
