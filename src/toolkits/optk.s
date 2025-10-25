;;; ============================================================
;;; Option Picker ToolKit
;;; ============================================================

.scope optk
        OPTKEntry := *

;;; ============================================================
;;; Zero Page usage (saved/restored around calls)

        zp_start := $50
        kMaxCommandDataSize = 6
        kMaxTmpSpace = 10       ; MulDiv param size

PARAM_BLOCK, zp_start
;;; Initially points at the call site, then at passed params
params_addr     .addr

;;; Copy of the passed params
command_data    .res    kMaxCommandDataSize

;;; A temporary copy of the control record
opr_copy        .tag    OPTK::OptionPickerRecord

;;; Other ZP usage
max_entries     .byte
max_entries_minus_one .byte
tmp_space       .res    kMaxTmpSpace

;;; For size calculation, not actually used
zp_end          .byte
END_PARAM_BLOCK

        .assert zp_end <= $78, error, "too big"
        kBytesToSave = zp_end - zp_start

        a_record        := command_data ; always first element of `command_data`

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

;;; ============================================================

        .assert OPTKEntry = Dispatch, error, "dispatch addr"
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

        ;; Cache static copy of the record in `opr_copy`, for convenience
        ldy     #.sizeof(OPTK::OptionPickerRecord)-1
:       copy8   (a_record),y, opr_copy,y
        dey
        bpl     :-

        ;; Compute constants
        lda     #0              ; lo
        ldx     oprc_num_cols   ; hi
        ldy     oprc_num_rows
        jsr     _Multiply
        stx     max_entries
        dex
        stx     max_entries_minus_one

        ;; Invoke the command
        dispatch := *+1
        jsr     SELF_MODIFIED
        tay                     ; A = result

        ;; Restore ZP
        POP_BYTES kBytesToSave, zp_start

        tya                     ; A = result
        rts

jump_table_lo:
        .lobytes   DrawImpl
        .lobytes   UpdateImpl
        .lobytes   ClickImpl
        .lobytes   KeyImpl
        .lobytes   SetSelectionImpl

jump_table_hi:
        .hibytes   DrawImpl
        .hibytes   UpdateImpl
        .hibytes   ClickImpl
        .hibytes   KeyImpl
        .hibytes   SetSelectionImpl

        ASSERT_EQUALS *-jump_table_hi, jump_table_hi-jump_table_lo
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
    DO
        txa

        jsr     _CallIsEntryProc ; preserves A, sets N
      IF NC
        point := tmp_space

        ;; Is a real entry - prep to draw it
        pha                     ; A = index
        jsr     _GetOptionPos   ; returns A,X=x , Y=y
        addax8  oprc_hoffset
        stax    point + MGTK::Point::xcoord

        tya
        ldx     #0
        addax8  oprc_voffset
        stax    point + MGTK::Point::ycoord

        MGTK_CALL MGTK::MoveTo, point

        pla                     ; A = index
        pha                     ; A = index
        jsr     DrawEntryProc
        pla                     ; A = index
      END_IF

        tax                     ; X = index
        inx
    WHILE X <> max_entries

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

        CALL    _Divide, AX=ycoord, Y=oprc_item_height ; A = row

        cmp     oprc_num_rows
        bcs     fail
        sta     row

        ;; Column
        sub16   xcoord, oprc_left, xcoord
        bmi     fail

        CALL    _Divide, AX=xcoord, Y=oprc_item_width ; A = col

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
    IF NS
        lda     #$FF
    END_IF
        jmp     _SetSelectionAndNotify

fail:   RETURN  A=#$FF
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
    IF NS
        lda     #0              ; no selection, start at first
        sec
        sbc     oprc_num_rows
    END_IF

    REPEAT
      IF A = max_entries_minus_one
        lda     #0              ; last, wrap to first
      ELSE
        clc
        adc     oprc_num_rows
      END_IF

      IF A >= max_entries
        sec
        sbc     max_entries_minus_one
      END_IF
        jsr     _CallIsEntryProc
    UNTIL NC

        bpl     _SetSelectionAndNotify ; always
.endproc ; _HandleKeyRight

;;; --------------------------------------------------

.proc _HandleKeyLeft
        lda     oprc_selected_index
        bmi     last            ; no selection, start at last
    IF ZERO                     ; or if first, start at last
last:   lda     max_entries_minus_one
        clc
        adc     oprc_num_rows
    END_IF

    REPEAT
        sec
        sbc     oprc_num_rows
      IF NEG
        clc
        adc     max_entries_minus_one
      END_IF
        jsr     _CallIsEntryProc
    UNTIL NC

        bpl     _SetSelectionAndNotify ; always
.endproc ; _HandleKeyLeft

;;; --------------------------------------------------

.proc _HandleKeyUp
        lda     oprc_selected_index
    IF NS
        lda     max_entries     ; no selection, start with last
    END_IF
    IF EQ
        lda     max_entries     ; first, start with last
    END_IF

    REPEAT
        sec
        sbc     #1
      IF NEG
        lda     max_entries
        CONTINUE_IF NOT_ZERO    ; always
      END_IF
        jsr     _CallIsEntryProc
    UNTIL NC

        bpl     _SetSelectionAndNotify ; always
.endproc ; _HandleKeyUp

;;; --------------------------------------------------

.proc _HandleKeyDown
        lda     oprc_selected_index
    IF NS
        lda     #AS_BYTE(-1)    ; no selection, start at first
    END_IF

    REPEAT
        clc
        adc     #1
      IF A = max_entries
        lda     #0
      END_IF
        jsr     _CallIsEntryProc
    UNTIL NC

        bpl     _SetSelectionAndNotify ; always
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
        RETURN  A=oprc_selected_index
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
        RTS_IF A = oprc_selected_index ; same as previous?

        pha                     ; A = new selection
        jsr     _SetPort
        CALL    _HighlightIndex, A=oprc_selected_index
        ldy     #OPTK::OptionPickerRecord::selected_index
        pla                     ; A = new selection
        sta     (a_record),y
        sta     oprc_selected_index ; keep copy in sync
        FALL_THROUGH_TO _HighlightIndex
.endproc ; SetSelectionImpl

;;; ============================================================
;;; Toggle the highlight on an entry in the list
;;; Input: A = entry number (negative if no selection)

.proc _HighlightIndex
        bmi     ret

        rect := tmp_space

        jsr     _GetOptionPos
        stax    rect + MGTK::Rect::x1
        addax8  oprc_item_width
        stax    rect + MGTK::Rect::x2
        dec16   rect + MGTK::Rect::x2

        tya                     ; y lo
        ldx     #0              ; y hi
        stax    rect + MGTK::Rect::y1
        addax8  oprc_item_height
        stax    rect + MGTK::Rect::y2
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
        plax                    ; X coord

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
        RETURN  AX=muldiv_params::result
.endproc ; _Multiply

;;; ============================================================

;;; A,X = A,X / Y, Y = remainder
.proc _Divide
        stax    muldiv_params::numerator
        sty     muldiv_params::denominator
        copy8   #0, muldiv_params::denominator+1
        copy16  #1, muldiv_params::number
        MGTK_CALL MGTK::MulDiv, muldiv_params
        RETURN  AX=muldiv_params::result, Y=muldiv_params::remainder
.endproc ; _Divide

;;; ============================================================

.endscope ; optk


