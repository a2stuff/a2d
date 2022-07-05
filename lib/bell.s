;;; ============================================================
;;; Bell
;;;
;;; Requires these definitions:
;;; * `kBellProcLength` - size of sound procs
;;; * `BELLPROC` - runtime location of sound procs
;;; * `BELLDATA` - storage location for sound procs (app specific)

.proc Bell
        .assert .lobyte(::BELLPROC) = 0, error, "Must be page-aligned"

        ;; Put routine into location
        jsr     Swap

        ;; Play it
        php
        sei
        proc := *+1
        jsr     BELLPROC
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
