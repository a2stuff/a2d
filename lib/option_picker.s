;;; ============================================================
;;; Option Picker Control
;;;
;;; API:
;;; * `DrawOption` - call when drawing labels (caller responsible)
;;; * `IsOptionPickerKey` - call to see if key would be handled
;;; * `HandleOptionPickerKey` - call to handle key
;;; * `HandleOptionPickerClick` - `screentowindow_params` must be mapped
;;; * `SetOptionPickerSelection` - A = selection ($FF to clear)
;;;
;;; Required includes:
;;; * lib/muldiv.s
;;; Requires `MGTK_CALL` macro to be functional.
;;;
;;; Required constants:
;;; * `kOptionPickerRows` - const
;;; * `kOptionPickerCols` - const
;;; * `kOptionPickerItemWidth` - const
;;; * `kOptionPickerItemHeight` - const
;;; * `kOptionPickerTextHOffset` - const
;;; * `kOptionPickerItemVOffset` - const
;;; * `kOptionPickerLeft` - const
;;; * `kOptionPickerTop` - const
;;; Required definitions:
;;; * `selected_index` - byte, $FF if no selection
;;; * `screentowindow_params`
;;; Requires the following proc definitions:
;;; * `IsIndexValid` - proc, Z=1 if A is valid index, Z=0 otherwise
;;; Notes:
;;; * Routines dirty $20...$2F
;;; ============================================================

.scope option_picker_impl

kOptionPickerMaxEntries = kOptionPickerRows * kOptionPickerCols

;;; ============================================================

.proc SetOptionPickerSelection
        cmp     selected_index  ; same as previous?
        RTS_IF_EQ

        pha
        lda     selected_index
        jsr     _HighlightIndex
        pla
        sta     selected_index
        jmp     _HighlightIndex
.endproc ; SetOptionPickerSelection

;;; ============================================================

.proc HandleOptionPickerClick
        jsr     _GetOptionIndexFromCoords
        bmi     done

        ;; Is it valid?
        jsr     IsIndexValid
        bpl     handle_entry_click

        ;; No, clear selection
        lda     selected_index
        jsr     _HighlightIndex
        copy    #$FF, selected_index

done:   return  #$FF

handle_entry_click:
        jmp     SetOptionPickerSelection
.endproc ; HandleOptionPickerClick

;;; ============================================================
;;; Toggle the highlight on an entry in the list
;;; Input: A = entry number (negative if no selection)

.proc _HighlightIndex
        bmi     ret

        rect := $20

        jsr     _GetOptionPos
        stax    rect + MGTK::Rect::x1
        addax   #kOptionPickerItemWidth-1, rect + MGTK::Rect::x2
        tya                     ; y lo
        ldx     #0              ; y hi
        stax    rect + MGTK::Rect::y1
        addax   #kOptionPickerItemHeight-1, rect + MGTK::Rect::y2

        MGTK_CALL MGTK::SetPattern, solid_pattern
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect

ret:    rts
.endproc ; _HighlightIndex

;;; ============================================================
;;; Get the coordinates of an option by index.
;;; Input: A = volume index
;;; Output: A,X = x coordinate, Y = y coordinate
.proc _GetOptionPos
        ldx     #0              ; hi
        ldy     #option_picker::kOptionPickerRows
        jsr     Divide_16_8_16
        sty     remainder
        ldy     #kOptionPickerItemWidth
        jsr     Multiply_16_8_16
        clc
        adc     #<kOptionPickerLeft
        pha                     ; lo
        txa
        adc     #>kOptionPickerLeft
        pha                     ; hi

        ;; Y coordinate
        remainder := *+1
        lda     #SELF_MODIFIED_BYTE ; lo
        ldx     #0                  ; hi
        ldy     #kOptionPickerItemHeight
        jsr     Multiply_16_8_16
        clc
        adc     #kOptionPickerTop

        tay                     ; Y coord
        pla
        tax                     ; X coord hi
        pla                     ; X coord lo

        rts
.endproc ; _GetOptionPos

;;; ============================================================

.proc DrawOption
        textptr := $20
        textlen := $22
        point   := $23

        sty     index
        stax    textptr
        ldy     #0
        lda     (textptr),y
        beq     ret

        sta     textlen
        inc16   textptr

        index := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     _GetOptionPos
        addax   #kOptionPickerTextHOffset, point + MGTK::Point::xcoord
        tya
        ldx     #0
        addax   #kOptionPickerTextVOffset, point + MGTK::Point::ycoord
        MGTK_CALL MGTK::MoveTo, point
        MGTK_CALL MGTK::DrawText, textptr

ret:    rts
.endproc ; DrawOption

;;; ============================================================
;;; Inputs: `screentowindow_params` has `windowx` and `windowy` mapped
;;; Outputs: A=index, N=1 if no match
.proc _GetOptionIndexFromCoords
        ;; Row
        sub16   screentowindow_params::windowy, #kOptionPickerTop, screentowindow_params::windowy
        bmi     done

        ldax    screentowindow_params::windowy
        ldy     #kOptionPickerItemHeight
        jsr     Divide_16_8_16  ; A = row

        cmp     #kOptionPickerRows
        bcs     done
        sta     row

        ;; Column
        sub16   screentowindow_params::windowx, #kOptionPickerLeft, screentowindow_params::windowx
        bmi     done

        ldax    screentowindow_params::windowx
        ldy     #kOptionPickerItemWidth
        jsr     Divide_16_8_16  ; A = col

        cmp     #kOptionPickerCols
        bcs     done

        ;; Index
        ldx     #0              ; hi
        ldy     #option_picker::kOptionPickerRows
        jsr     Multiply_16_8_16
        clc
        row := *+1
        adc     #SELF_MODIFIED_BYTE
        rts

done:   return  #$FF
.endproc ; _GetOptionIndexFromCoords

;;; ============================================================

.proc IsOptionPickerKey
        cmp     #CHAR_LEFT
        beq     ret
        cmp     #CHAR_RIGHT
        beq     ret
        cmp     #CHAR_DOWN
        beq     ret
        cmp     #CHAR_UP
ret:    rts
.endproc ; IsOptionPickerKey

;;; ============================================================

.proc HandleOptionPickerKey
        cmp     #CHAR_LEFT
        beq     _HandleKeyLeft

        cmp     #CHAR_RIGHT
        beq     _HandleKeyRight

        cmp     #CHAR_DOWN
        beq     _HandleKeyDown

        bne     _HandleKeyUp    ; always
.endproc ; HandleOptionPickerKey

;;; ============================================================

.proc _HandleKeyRight
        jsr     _PreKey
    IF_NS
        lda     #AS_BYTE(-kOptionPickerRows) ; no selection, start at first
    END_IF

loop:
        cmp     #kOptionPickerMaxEntries-1
    IF_EQ
        lda     #AS_BYTE(-kOptionPickerRows) ; last, wrap to first
    END_IF
        clc
        adc     #kOptionPickerRows
        cmp     #kOptionPickerMaxEntries
    IF_GE
        sec
        sbc     #kOptionPickerMaxEntries-1
    END_IF
        jsr     IsIndexValid
        bmi     loop

        sta     selected_index
        jmp     _HighlightIndex
.endproc ; _HandleKeyRight

;;; ============================================================

.proc _HandleKeyLeft
        jsr     _PreKey
    IF_NS
        lda     #kOptionPickerMaxEntries-1+kOptionPickerRows ; no selection, start at last
    END_IF
    IF_EQ
        lda     #kOptionPickerMaxEntries-1+kOptionPickerRows ; first, start at last
    END_IF

loop:   sec
        sbc     #kOptionPickerRows
    IF_NEG
        clc
        adc     #kOptionPickerMaxEntries-1
    END_IF
        jsr     IsIndexValid
        bmi     loop

        sta     selected_index
        jmp     _HighlightIndex
.endproc ; _HandleKeyLeft

;;; ============================================================

.proc _HandleKeyUp
        jsr     _PreKey
    IF_NS
        lda     #kOptionPickerMaxEntries ; no selection, start with last
    END_IF
    IF_EQ
        lda     #kOptionPickerMaxEntries ; first, start with last
    END_IF

loop:   sec
        sbc     #1
    IF_NEG
        lda     #kOptionPickerMaxEntries-1
    END_IF
        jsr     IsIndexValid
        bmi     loop

        sta     selected_index
        jmp     _HighlightIndex
.endproc ; _HandleKeyUp

;;; ============================================================

.proc _HandleKeyDown
        jsr     _PreKey
    IF_NS
        lda     #AS_BYTE(-1)    ; no selection, start at first
    END_IF

loop:   clc
        adc     #1
        cmp     #kOptionPickerMaxEntries
    IF_EQ
        lda     #0
    END_IF
        jsr     IsIndexValid
        bmi     loop

        sta     selected_index
        jmp     _HighlightIndex
.endproc ; _HandleKeyDown

;;; ============================================================

.proc _PreKey
        lda     selected_index
        pha
        jsr     _HighlightIndex
        pla
        rts
.endproc ; _PreKey

;;; ============================================================

.endscope ; option_picker_impl

;;; "Exports"
DrawOption := option_picker_impl::DrawOption
IsOptionPickerKey := option_picker_impl::IsOptionPickerKey
HandleOptionPickerKey := option_picker_impl::HandleOptionPickerKey
HandleOptionPickerClick := option_picker_impl::HandleOptionPickerClick
SetOptionPickerSelection := option_picker_impl::SetOptionPickerSelection
