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
        jsr     _Swap

        ;; `BELLPROC` starting with 0 byte (BRK) signals silent bell
        lda     BELLPROC
    IF ZERO
        MGTK_CALL MGTK::FlashMenuBar

        ldx     #10
      DO
        txa
        pha
        MGTK_CALL MGTK::WaitVBL
        pla
        tax
        dex
      WHILE POS

        MGTK_CALL MGTK::FlashMenuBar
    ELSE
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
    END_IF

        ;; Restore memory
        FALL_THROUGH_TO _Swap

.proc _Swap
        .assert kBellProcLength <= 128, error, "Can't BPL this loop"

        ;; Save and change banking
        bit     RDALTZP
        sta     ALTZPOFF        ; preserve state on main stack
        php

        bit     RDLCRAM
        php

        bit     RDBNK2
        php

        bit     LCBANK2
        bit     LCBANK2

        ;; Swap proc into place
        ldy     #kBellProcLength - 1
    DO
        swap8   BELLPROC,y, BELLDATA,y
        dey
    WHILE POS

        ;; Restore banking
        plp
    IF NC
        bit     LCBANK1         ; restore LCBANK1
        bit     LCBANK1
    END_IF

        plp
    IF NC
        bit     ROMIN2          ; restore ROMIN2
    END_IF

        plp
    IF NS
        sta     ALTZPON         ; restore ALTZPON
    END_IF

        rts
.endproc ; _Swap

.endproc ; Bell
