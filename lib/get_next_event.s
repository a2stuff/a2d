;;; ============================================================
;;; GetNextEvent helper

;;; `GetNextEvent` - calls MGTK::GetEvent but synthesizes:
;;; * `kEventKindMouseMoved` if the mouse moves
;;;
;;; It is not necessary to use this, but useful in event loops
;;; where mouse movement is worth distinguishing.
;;;
;;; Requires:
;;; * lib/event_params.s

;;; ============================================================

;;; Output:
;;; * A = `kEventKindXXX` or `MGTK::EventKind::XXX`
.proc GetNextEvent
        ;; GetEvent
        MGTK_CALL MGTK::GetEvent, event_params

        lda     event_params::kind
        .assert MGTK::EventKind::no_event = 0, error, "enum mismatch"
    IF_ZERO
        ldx     #.sizeof(MGTK::Point)-1
:       lda     event_params::coords,x
        cmp     coords,x
        bne     diff
        dex
        bpl     :-
        lda     #MGTK::EventKind::no_event
        beq     set             ; always

diff:   COPY_STRUCT MGTK::Point, event_params::coords, coords
        lda     #kEventKindMouseMoved
        FALL_THROUGH_TO set
    END_IF

set:    sta     event_params::kind
        rts

        DEFINE_POINT coords, 0, 0

.endproc ; GetNextEvent
