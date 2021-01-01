;;; ============================================================
;;; Double Click Detection
;;; Returns with A=0 if double click, A=$FF otherwise.

.proc DetectDoubleClick
        ;; Stash initial coords
        ldx     #.sizeof(MGTK::Point)-1
:       copy    event_coords,x, coords,x

        dex
        bpl     :-

        copy16  SETTINGS + DeskTopSettings::dblclick_speed, counter

        ;; Decrement counter, bail if time delta exceeded
loop:   dec16   counter
        lda     counter
        ora     counter+1
        beq     exit

        MGTK_CALL MGTK::PeekEvent, event_params

        ;; Check coords, bail if pixel delta exceeded
        jsr     check_delta
        bmi     exit            ; moved past delta; no double-click

        lda     event_kind
        cmp     #MGTK::EventKind::no_event
        beq     loop
        cmp     #MGTK::EventKind::drag
        beq     loop
        cmp     #MGTK::EventKind::button_up
        bne     :+

        MGTK_CALL MGTK::GetEvent, event_params
        jmp     loop

:       cmp     #MGTK::EventKind::button_down
        beq     :+
        cmp     #MGTK::EventKind::apple_key ; modified-click
        bne     exit

:       MGTK_CALL MGTK::GetEvent, event_params
        return  #0              ; double-click

exit:   return  #$FF            ; not double-click

        ;; Is the new coord within range of the old coord?
.proc check_delta
        ;; compute x delta
        lda     event_xcoord
        sec
        sbc     xcoord
        sta     delta
        lda     event_xcoord+1
        sbc     xcoord+1
        bpl     :+

        ;; is -delta < x < 0 ?
        lda     delta
        cmp     #AS_BYTE(-kDoubleClickDeltaX)
        bcs     check_y
fail:   return  #$FF

        ;; is 0 < x < delta ?
:       lda     delta
        cmp     #kDoubleClickDeltaX
        bcs     fail

        ;; compute y delta
check_y:
        lda     event_ycoord
        sec
        sbc     ycoord
        sta     delta
        lda     event_ycoord+1
        sbc     ycoord+1
        bpl     :+

        ;; is -delta < y < 0 ?
        lda     delta
        cmp     #AS_BYTE(-kDoubleClickDeltaY)
        bcs     ok

        ;; is 0 < y < delta ?
:       lda     delta
        cmp     #kDoubleClickDeltaY
        bcs     fail
ok:     return  #0
.endproc

counter:
        .word   0
coords:
xcoord: .word   0
ycoord: .word   0
delta:  .byte   0
.endproc
