;;; ============================================================
;;; Bell
;;;
;;; Requires these definitions:
;;; * `kBellProcLength` - size of sound procs
;;; * `BELLPROC` - runtime location of sound procs
;;; * `SlowSpeed` - slow accelerator, if needed
;;; * `ResumeSpeed` - resume accelerator, if needed

.proc Bell
        .assert .lobyte(::BELLPROC) = 0, error, "Must be page-aligned"

        ;; Put routine into location
        jsr     Swap

        ;; Suppress interrupts
        php
        sei

        ;; Play it
        jsr     SlowSpeed
        proc := *+1
        jsr     BELLPROC
        jsr     ResumeSpeed

        ;; Restore interrupt state
        plp

        ;; Restore memory
        FALL_THROUGH_TO Swap

.proc Swap
        .assert kBellProcLength <= 128, error, "Can't BPL this loop"

        ;; Save and change banking
        ldy     RDALTZP
        sty     rdaltzp_flag

        ldy     RDLCRAM
        sty     rdlcram_flag

        ldy     RDBNK2
        sty     rdbnk2_flag

        sty     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2

        ;; Swap proc into place
        ldy     #kBellProcLength - 1
:       lda     BELLPROC,y
        pha
        lda     BELLDATA,y
        sta     BELLPROC,y
        pla
        sta     BELLDATA,y
        dey
        bpl     :-

        ;; Restore banking
        rdaltzp_flag := *+1
        ldy     #SELF_MODIFIED_BYTE
        bpl     :+              ; leave ALTZPOFF
        sty     ALTZPON         ; restore ALTZPON
:
        rdbnk2_flag := *+1
        ldy     #SELF_MODIFIED_BYTE
        bmi     :+              ; leave LCBANK2
        bit     LCBANK1         ; restore LCBANK1
        bit     LCBANK1
:
        rdlcram_flag := *+1
        ldy     #SELF_MODIFIED_BYTE
        bmi     :+
        bit     ROMIN2          ; restore ROMIN2
:
        rts
.endproc ; Swap

.endproc ; Bell
