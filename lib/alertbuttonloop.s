;;; ============================================================
;;; Event loop during button press - initial invert and
;;; inverting as mouse is dragged in/out.
;;; (The `ButtonEventLoop` proc is not used as these buttons
;;; are not in a window, so ScreenToWindow can not be used.)
;;; A `MapEventCoords` proc must be defined.
;;; Inputs: A,X = rect address
;;; Output: A=0/N=0/Z=1 = click, A=$80/N=1/Z=0 = cancel

.proc AlertButtonEventLoop
        stax    rect_addr1
        stax    rect_addr2
        lda     #0
        sta     flag
        MGTK_CALL MGTK::SetPenMode, penXOR
        jsr     Invert

loop:   MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     button_up
        jsr     MapEventCoords
        MGTK_CALL MGTK::MoveTo, event_coords
        MGTK_CALL MGTK::InRect, SELF_MODIFIED, rect_addr1
        cmp     #MGTK::inrect_inside
        beq     inside
        lda     flag
        beq     toggle
        bne     loop

inside: lda     flag
        beq     loop

toggle: jsr     Invert
        lda     flag
        eor     #$80
        sta     flag
        jmp     loop

button_up:
        lda     flag
        rts

Invert:
        MGTK_CALL MGTK::PaintRect, SELF_MODIFIED, rect_addr2
        rts

        ;; High bit clear if button is depressed
flag:   .byte   0
.endproc
