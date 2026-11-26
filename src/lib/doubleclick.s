;;; ============================================================
;;; Double Click Detection
;;; Returns with A=0 if double click, A=$FF otherwise.
;;; Scrambles: $06...$0C

.proc DetectDoubleClick

PARAM_BLOCK, $06
counter .word
coords  .tag MGTK::Point
delta   .byte
END_PARAM_BLOCK

        ;; Stash initial coords
        ldx     #.sizeof(MGTK::Point)-1
    DO
        copy8   event_params+MGTK::Event::coords,x, coords,x
    WHILE dex : POS

        CALL    ReadSetting, X=#DeskTopSettings::dblclick_speed
        sta     counter
        inx                     ; `ReadSetting` preserves X
        jsr     ReadSetting
        sta     counter+1

        ;; Decrement counter, bail if time delta exceeded
    REPEAT
        dec16   counter
        lda     counter
        ora     counter+1
        beq     exit

        MGTK_CALL MGTK::PeekEvent, event_params

        ;; Check coords, bail if pixel delta exceeded
        jsr     _CheckDelta
        bmi     exit            ; moved past delta; no double-click

        lda     event_params+MGTK::Event::kind
        REDO_IF A = #MGTK::EventKind::no_event ; nothing to consume

        IF A = #MGTK::EventKind::drag GOTO consume
        IF A = #MGTK::EventKind::button_up GOTO consume
        IF A = #MGTK::EventKind::button_down GOTO click
        IF A <> #MGTK::EventKind::apple_key GOTO exit ; modified-click
click:
        ;; Double-click! Flush events rather than just getting the
        ;; next event to ensure there isn't a lingering button event.
        ;; (Observed on real hardware, e.g. IIc+)
        MGTK_CALL MGTK::FlushEvents
        RETURN  A=#0            ; double-click

exit:   RETURN  A=#$FF          ; not double-click

consume:
        MGTK_CALL MGTK::GetEvent, event_params
    FOREVER

        ;; Is the new coord within range of the old coord?
.proc _CheckDelta
        ;; compute x delta
        lda     event_params + MGTK::Event::xcoord
        sec
        sbc     coords+MGTK::Point::xcoord
        sta     delta
        lda     event_params + MGTK::Event::xcoord+1
        sbc     coords+MGTK::Point::xcoord+1
    IF NEG
        ;; is -delta < x < 0 ?
        IF u8 delta >= #AS_BYTE{-kDoubleClickDeltaX} GOTO check_y
fail:   RETURN  A=#$FF
    END_IF
        ;; is 0 < x < delta ?
        IF u8 delta >= #kDoubleClickDeltaX GOTO fail

        ;; compute y delta
check_y:
        lda     event_params+MGTK::Event::ycoord
        sec
        sbc     coords+MGTK::Point::ycoord
        sta     delta
        lda     event_params+MGTK::Event::ycoord+1
        sbc     coords+MGTK::Point::ycoord+1
        ;; is -delta < y < 0 ?
        IF NEG AND u8 delta >= #AS_BYTE{-kDoubleClickDeltaY} GOTO ok
        ;; is 0 < y < delta ?
        ;; NOTE: Not guarded by !NEG, but could only yield a false
        ;; positive if Y delta was greater than screen height.
        IF u8 delta >= #kDoubleClickDeltaY GOTO fail

ok:     RETURN  A=#0
.endproc ; _CheckDelta
.endproc ; DetectDoubleClick
