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

        ;; `BELLPROC` starting with 0 byte (BRK) signals silent bell
        lda     BELLPROC
    IF_ZERO
        MGTK_CALL MGTK::FlashMenuBar

        ;; Delay using some heuristic.

        ;; Option #1: Slow accelerator down to 1MHz
        ;;
        ;; 1a: Using documented accelerator access for each type of
        ;;     hardware (IIgs, Mac IIe Card, IIc+, Laser, add-ons, ...)
        ;;     like NORMFAST does it.
        ;;
        ;;   * This now happens by default on some systems, c/o
        ;;     general beep slowdown. See `lib/sounds.s`
        ;;   * This doesn't slow emulators.
        ;;
        ;; 1b: Touching the speaker quickly (i.e. STA SPKR twice), to
        ;;      temporarily slow accelerators; this is inaudible on real
        ;;      hardware.
        ;;
        ;;   * This causes Virtual ][ to stop playing sounds for a bit.
        ;;   * This has an audible click in MAME.
        ;;
        ;; 1c: Hit slot 6 (e.g. BIT $C0EC) to temporarily slow accelerator.
        ;; 1d: Hit PTRIG to temporarily slow accelerator.
        ;;
        ;;   * These doesn't slow emulators like Virtual ][.

        ;; Option #2: Wait based on double-click setting.
        ;;
        ;; The assumption is that users will adjust the setting based on
        ;; factors such as acceleration/emulation speed, so use it as
        ;; the basis of a timing loop.
        ;;
        ;;  * Since we slow the machine to 1MHz while playing sound,
        ;;    this ends up being unacceptably slow.

        ptr := $06
        copy16  #kDefaultDblClickSpeed, ptr
loop:   ldx     #48
:       dex
        bne     :-
        dec     ptr
        bne     loop
        dec     ptr+1
        bne     loop

        ;; Option #3: Use VBL on Enh IIe/IIc/IIgs
        ;; https://comp.sys.apple2.narkive.com/dHkvl39d/vblank-apple-iic
        ;;
        ;; * Emulators don't throttle to 60/50Hz, and rather sync VBL to
        ;;   cycle counts.

        ;; Option #4: Use interrupt timer from mouse card
        ;;
        ;; * Interrupts are hard. PRs welcome!

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
        FALL_THROUGH_TO Swap

.proc Swap
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
:       lda     BELLPROC,y
        pha
        lda     BELLDATA,y
        sta     BELLPROC,y
        pla
        sta     BELLDATA,y
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
.endproc ; Swap

.endproc ; Bell
