;;; ============================================================
;;; Option Picker ToolKit
;;; ============================================================

;;; Routines dirty $50...$77
;;; TODO: Spill to stack?

.scope optk
        OPTKEntry := *

        kMaxCommandDataSize = 6

        ;; Initially points at the call site, then at passed params
        params_addr     := $50

        ;; Copy of the passed params
        command_data    := params_addr+2
        opr_ptr         := params_addr+2 ; always first element of `command_data`

        ;; A temporary copy of the `OptionPickerRecord` is placed here:
        opr_copy        := command_data + kMaxCommandDataSize

        ;; Aliases for the copy's members:
        oprc_window_id  := opr_copy + OPTK::OptionPickerRecord::window_id
        oprc_left       := opr_copy + OPTK::OptionPickerRecord::left
        oprc_top        := opr_copy + OPTK::OptionPickerRecord::top
        oprc_num_rows   := opr_copy + OPTK::OptionPickerRecord::num_rows
        oprc_num_cols   := opr_copy + OPTK::OptionPickerRecord::num_cols
        oprc_item_width := opr_copy + OPTK::OptionPickerRecord::item_width
        oprc_item_height := opr_copy + OPTK::OptionPickerRecord::item_height
        oprc_hoffset    := opr_copy + OPTK::OptionPickerRecord::hoffset
        oprc_voffset    := opr_copy + OPTK::OptionPickerRecord::voffset
        oprc_selected_index := opr_copy + OPTK::OptionPickerRecord::selected_index

        ;; Other ZP usage
        max_entries     := opr_copy + .sizeof(OPTK::OptionPickerRecord)
        max_entries_minus_one := opr_copy + .sizeof(OPTK::OptionPickerRecord) + 1
        tmp_space       := max_entries + 2

        kMaxTmpSpace = 10       ; MulDiv param size

        .assert tmp_space + kMaxTmpSpace <= $78, error, "too big"

;;; ============================================================

        .assert OPTKEntry = Dispatch, error, "dispatch addr"
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

        ;; Cache static of the record in `opr_copy`, for convenience
        ldy     #.sizeof(OPTK::OptionPickerRecord)-1
:       lda     (opr_ptr),y
        sta     opr_copy,y
        dey
        bpl     :-

        ;; Compute constants
        ;; `_Multiply` is not used as it trashes `tmp_space`
        ldx     oprc_num_cols
        lda     #0
        clc
:       adc     oprc_num_rows
        dex
        bne     :-
        sta     max_entries
        sta     max_entries_minus_one
        dec     max_entries_minus_one

        jmp     (jump_addr)

jump_table:
        .addr   DrawImpl
        .addr   UpdateImpl
        .addr   ClickImpl
        .addr   KeyImpl
        .addr   SetSelectionImpl

.endproc ; Dispatch

;;; ============================================================

IsEntryProc:    jmp     (opr_copy + OPTK::OptionPickerRecord::is_entry_proc)
DrawEntryProc:  jmp     (opr_copy + OPTK::OptionPickerRecord::draw_entry_proc)
OnSelChange:    jmp     (opr_copy + OPTK::OptionPickerRecord::on_sel_change)


;;; ============================================================

;;; Shadows params in Selector's `app` and Disk Copy's `auxlc` scopes.
;;; TODO: Rework scoping to eliminate this.
SUPPRESS_SHADOW_WARNING
.params getwinport_params
window_id:      .byte   0
port:           .addr   grafport_win
.endparams
UNSUPPRESS_SHADOW_WARNING

grafport_win:   .tag    MGTK::GrafPort

.proc _SetPort
        copy8   oprc_window_id, getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured.
        MGTK_CALL MGTK::SetPort, grafport_win
        rts
.endproc ; _SetPort

;;; ============================================================

.proc DrawImpl
        jsr     _SetPort
        FALL_THROUGH_TO UpdateImpl
.endproc ; DrawImpl

;;; ============================================================

.proc UpdateImpl
        ldx     #0
loop:   txa

        jsr     _CallIsEntryProc ; preserves A, sets N
    IF_NC
        point := tmp_space

        ;; Is a real entry - prep to draw it
        pha                     ; A = index
        jsr     _GetOptionPos   ; returns A,X=x , Y=y
        clc
        adc     oprc_hoffset
        bcc     :+
        inx
:       stax    point + MGTK::Point::xcoord

        tya
        ldx     #0
        clc
        adc     oprc_voffset
        bcc     :+
        inx
:       stax    point + MGTK::Point::ycoord

        MGTK_CALL MGTK::MoveTo, point

        pla                     ; A = index
        pha                     ; A = index
        jsr     DrawEntryProc
        pla                     ; A = index
    END_IF

        tax                     ; X = index
        inx
        cpx     max_entries
        bne     loop

        rts
.endproc ; UpdateImpl

;;; ============================================================

.proc ClickImpl
        PARAM_BLOCK params, optk::command_data
a_record        .addr
coords          .tag MGTK::Point
        END_PARAM_BLOCK

        xcoord := params::coords + MGTK::Point::xcoord
        ycoord := params::coords + MGTK::Point::ycoord

        ;; Row
        sub16   ycoord, oprc_top, ycoord
        bmi     fail

        ldax    ycoord
        ldy     oprc_item_height
        jsr     _Divide         ; A = row

        cmp     oprc_num_rows
        bcs     fail
        sta     row

        ;; Column
        sub16   xcoord, oprc_left, xcoord
        bmi     fail

        ldax    xcoord
        ldy     oprc_item_width
        jsr     _Divide         ; A = col

        cmp     oprc_num_cols
        bcs     fail

        ;; Index
        ldx     #0              ; hi
        ldy     oprc_num_rows
        jsr     _Multiply
        clc
        row := *+1
        adc     #SELF_MODIFIED_BYTE

        ;; Is it valid?
        jsr     _CallIsEntryProc
    IF_NS
        lda     #$FF
    END_IF
        jmp     _SetSelectionAndNotify

fail:   return  #$FF
.endproc ; ClickImpl

;;; ============================================================

.proc KeyImpl
        PARAM_BLOCK params, optk::command_data
a_record        .addr
key             .byte
        END_PARAM_BLOCK

        lda     params::key

        cmp     #CHAR_LEFT
        beq     _HandleKeyLeft

        cmp     #CHAR_UP
        beq     _HandleKeyUp

        cmp     #CHAR_DOWN
        beq     _HandleKeyDown

        FALL_THROUGH_TO _HandleKeyRight

;;; --------------------------------------------------

.proc _HandleKeyRight
        lda     oprc_selected_index
    IF_NS
        lda     #0              ; no selection, start at first
        sec
        sbc     oprc_num_rows
    END_IF

loop:
        cmp     max_entries_minus_one
    IF_EQ
        lda     #0              ; last, wrap to first
    ELSE
        clc
        adc     oprc_num_rows
    END_IF

        cmp     max_entries
    IF_GE
        sec
        sbc     max_entries_minus_one
    END_IF
        jsr     _CallIsEntryProc
        bmi     loop

        jmp     _SetSelectionAndNotify
.endproc ; _HandleKeyRight

;;; --------------------------------------------------

.proc _HandleKeyLeft
        lda     oprc_selected_index
    IF_NS
        lda     max_entries     ; no selection, start at last
        sec
        sbc     #1
        clc
        adc     oprc_num_rows
    END_IF
    IF_EQ
        lda     max_entries_minus_one ; first, start at last
        clc
        adc     oprc_num_rows
    END_IF

loop:   sec
        sbc     oprc_num_rows
    IF_NEG
        clc
        adc     max_entries_minus_one
    END_IF
        jsr     _CallIsEntryProc
        bmi     loop

        jmp     _SetSelectionAndNotify
.endproc ; _HandleKeyLeft

;;; --------------------------------------------------

.proc _HandleKeyUp
        lda     oprc_selected_index
    IF_NS
        lda     max_entries     ; no selection, start with last
    END_IF
    IF_EQ
        lda     max_entries     ; first, start with last
    END_IF

loop:   sec
        sbc     #1
    IF_NEG
        lda     max_entries
        bne     loop            ; always
    END_IF
        jsr     _CallIsEntryProc
        bmi     loop

        jmp     _SetSelectionAndNotify
.endproc ; _HandleKeyUp

;;; --------------------------------------------------

.proc _HandleKeyDown
        lda     oprc_selected_index
    IF_NS
        lda     #AS_BYTE(-1)    ; no selection, start at first
    END_IF

loop:   clc
        adc     #1
        cmp     max_entries
    IF_EQ
        lda     #0
    END_IF
        jsr     _CallIsEntryProc
        bmi     loop

        jmp     _SetSelectionAndNotify
.endproc ; _HandleKeyDown

.endproc ; KeyImpl

;;; ============================================================

;;; Input: A=index
;;; Output: A=index, N=0 if valid proc
.proc _CallIsEntryProc
        sta     save_a
        jsr     IsEntryProc
        php
        save_a := *+1
        lda     #SELF_MODIFIED_BYTE
        plp
        rts
.endproc ; _CallIsEntryProc

;;; ============================================================

.proc _SetSelectionAndNotify
        jsr     _SetSelection
        jsr     OnSelChange
        lda     oprc_selected_index
        rts
.endproc ; _SetSelectionAndNotify

;;; ============================================================

.proc SetSelectionImpl
        PARAM_BLOCK params, optk::command_data
a_record        .addr
new_selection   .byte
        END_PARAM_BLOCK

        lda     params::new_selection
        FALL_THROUGH_TO _SetSelection
.endproc ; SetSelectionImpl

;;; ============================================================

.proc _SetSelection
        cmp     oprc_selected_index ; same as previous?
        RTS_IF_EQ

        pha                     ; A = new selection
        jsr     _SetPort
        lda     oprc_selected_index
        jsr     _HighlightIndex
        ldy     #OPTK::OptionPickerRecord::selected_index
        pla                     ; A = new selection
        sta     (opr_ptr),y
        sta     oprc_selected_index ; keep copy in sync
        jmp     _HighlightIndex
.endproc ; SetSelectionImpl

;;; ============================================================
;;; Toggle the highlight on an entry in the list
;;; Input: A = entry number (negative if no selection)

.proc _HighlightIndex
        bmi     ret

        rect := tmp_space

        jsr     _GetOptionPos
        stax    rect + MGTK::Rect::x1
        clc
        adc     oprc_item_width
        bcc     :+
        inx
:       stax    rect + MGTK::Rect::x2
        dec16   rect + MGTK::Rect::x2

        tya                     ; y lo
        ldx     #0              ; y hi
        stax    rect + MGTK::Rect::y1
        clc
        adc     oprc_item_height
        bcc     :+
        inx
:       stax    rect + MGTK::Rect::y2
        dec16   rect + MGTK::Rect::y2

        MGTK_CALL MGTK::SetPattern, solid_pattern
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect

ret:    rts
.endproc ; _HighlightIndex

;;; ============================================================
;;; Get the coordinates of an option by index.
;;; Input: A = index
;;; Output: A,X = x coordinate, Y = y coordinate
.proc _GetOptionPos
        ldx     #0              ; hi
        ldy     oprc_num_rows
        jsr     _Divide
        sty     remainder
        ldy     oprc_item_width
        jsr     _Multiply
        clc
        adc     oprc_left
        pha                     ; lo
        txa
        adc     oprc_left+1
        pha                     ; hi

        ;; Y coordinate
        remainder := *+1
        lda     #SELF_MODIFIED_BYTE ; lo
        ldx     #0                  ; hi
        ldy     oprc_item_height
        jsr     _Multiply
        clc
        adc     oprc_top

        tay                     ; Y coord
        pla
        tax                     ; X coord hi
        pla                     ; X coord lo

        rts
.endproc ; _GetOptionPos


;;; ============================================================

PARAM_BLOCK muldiv_params, optk::tmp_space
number          .word           ; (in)
numerator       .word           ; (in)
denominator     .word           ; (in)
result          .word           ; (out)
remainder       .word           ; (out)
END_PARAM_BLOCK

;;; A,X = A,X * Y
.proc _Multiply
        stax    muldiv_params::number
        sty     muldiv_params::numerator
        copy8   #0, muldiv_params::numerator+1
        copy16  #1, muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, muldiv_params
        ldax    muldiv_params::result
        rts
.endproc ; _Multiply

;;; ============================================================

;;; A,X = A,X / Y, Y = remainder
.proc _Divide
        stax    muldiv_params::numerator
        sty     muldiv_params::denominator
        copy8   #0, muldiv_params::denominator+1
        copy16  #1, muldiv_params::number
        MGTK_CALL MGTK::MulDiv, muldiv_params
        ldax    muldiv_params::result
        ldy     muldiv_params::remainder
        rts
.endproc ; _Divide

;;; ============================================================

.endscope ; optk


