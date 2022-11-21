;;; ============================================================
;;; Bell
;;;
;;; Requires these definitions:
;;; * `kBellProcLength` - size of sound procs
;;; * `BELLPROC` - runtime location of sound procs
;;; * `BELLDATA` - storage location for sound procs (app specific)
;;; * `is_iigs_flag` - high bit set if on IIgs

.proc Bell
        .assert .lobyte(::BELLPROC) = 0, error, "Must be page-aligned"

        ;; Put routine into location
        jsr     Swap

        ;; Suppress interrupts
        php
        sei

        ;; Slow down on IIgs
        bit     is_iigs_flag
    IF_NS
        lda     CYAREG
        pha
        and     #%01111111      ; clear bit 7
        sta     CYAREG
    END_IF

        ;; Play it
        proc := *+1
        jsr     BELLPROC

        ;; Restore speed on IIgs
        bit     is_iigs_flag
    IF_NS
        pla
        sta     CYAREG
    END_IF

        ;; Restore interrupt state
        plp

        ;; Restore memory
        FALL_THROUGH_TO Swap

.proc Swap
        .assert kBellProcLength <= 128, error, "Can't BPL this loop"
        ldy     #kBellProcLength - 1
:       lda     BELLPROC,y
        pha
        lda     BELLDATA,y
        sta     BELLPROC,y
        pla
        sta     BELLDATA,y
        dey
        bpl     :-

        rts
.endproc

.endproc
