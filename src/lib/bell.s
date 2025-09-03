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
    IF_ZERO
        MGTK_CALL MGTK::FlashMenuBar

        ;; Hit Slot 6, which causes accelerators e.g. Zip Chip
        ;; to slow down.
        ;; NOTE: $C0E0 causes Virtual ][ emulator to make sound;
        ;; $C0EC (data read location) does not.
        bit     $C0EC
        ptr := $06
        copy16  #20000, ptr
loop:   dec     ptr
        bne     loop
        dec     ptr+1
        bne     loop

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
:       swap8   BELLPROC,y, BELLDATA,y
        dey
        bpl     :-

        ;; Restore banking
        plp
        bmi     :+              ; leave LCBANK2
        bit     LCBANK1         ; restore LCBANK1
        bit     LCBANK1
:
        plp
        bmi     :+              ; leave LCRAM
        bit     ROMIN2          ; restore ROMIN2
:
        plp
        bpl     :+              ; leave ALTZPOFF
        sta     ALTZPON         ; restore ALTZPON
:
        rts
.endproc ; _Swap

.endproc ; Bell
