;;; ============================================================
;;; Double Click Detection
;;; Returns with A=0 if double click, A=$FF otherwise.

.proc DetectDoubleClick
        ;; Stash initial coords
        ldx     #.sizeof(MGTK::Point)-1
    DO
        copy8   event_params+MGTK::Event::coords,x, coords,x
        dex
    WHILE POS

        ldx     #DeskTopSettings::dblclick_speed
        jsr     ReadSetting
        sta     counter
        inx                     ; `ReadSetting` preserves X
        jsr     ReadSetting
        sta     counter+1

        ;; Decrement counter, bail if time delta exceeded
loop:   dec16   counter
        lda     counter
        ora     counter+1
        beq     exit

        MGTK_CALL MGTK::PeekEvent, event_params

        ;; Check coords, bail if pixel delta exceeded
        jsr     _CheckDelta
        bmi     exit            ; moved past delta; no double-click

        lda     event_params+MGTK::Event::kind
        cmp     #MGTK::EventKind::no_event
        beq     loop            ; nothing to consume

        cmp     #MGTK::EventKind::drag
        beq     consume
        cmp     #MGTK::EventKind::button_up
        beq     consume
        cmp     #MGTK::EventKind::button_down
        beq     :+
        cmp     #MGTK::EventKind::apple_key ; modified-click
        bne     exit

:
        ;; Double-click! Flush events rather than just getting the
        ;; next event to ensure there isn't a lingering button event.
        ;; (Observed on real hardware, e.g. IIc+)
        MGTK_CALL MGTK::FlushEvents
        return8 #0              ; double-click

exit:   return8 #$FF            ; not double-click

consume:
        MGTK_CALL MGTK::GetEvent, event_params
        jmp     loop

        ;; Is the new coord within range of the old coord?
.proc _CheckDelta
        ;; compute x delta
        lda     event_params + MGTK::Event::xcoord
        sec
        sbc     xcoord
        sta     delta
        lda     event_params + MGTK::Event::xcoord+1
        sbc     xcoord+1
    IF NEG
        ;; is -delta < x < 0 ?
        lda     delta
        cmp     #AS_BYTE(-kDoubleClickDeltaX)
        bcs     check_y
fail:   return8 #$FF
    END_IF
        ;; is 0 < x < delta ?
        lda     delta
        cmp     #kDoubleClickDeltaX
        bcs     fail

        ;; compute y delta
check_y:
        lda     event_params+MGTK::Event::ycoord
        sec
        sbc     ycoord
        sta     delta
        lda     event_params+MGTK::Event::ycoord+1
        sbc     ycoord+1
    IF NEG
        ;; is -delta < y < 0 ?
        lda     delta
        cmp     #AS_BYTE(-kDoubleClickDeltaY)
        bcs     ok
    END_IF
        ;; is 0 < y < delta ?
        lda     delta
        cmp     #kDoubleClickDeltaY
        bcs     fail

ok:     return8 #0
.endproc ; _CheckDelta

counter:
        .word   0
coords:
xcoord: .word   0
ycoord: .word   0
delta:  .byte   0
.endproc ; DetectDoubleClick
