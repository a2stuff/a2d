;;; ============================================================
;;; Detect Phasor
;;;
;;; A Phasor will also be detected as a Mockingboard, so first
;;; detect the Mockingboard, and if successful detect the Phasor
;;;
;;; Inputs: $06 points at $Cs00
;;; Outputs: C=1 if detected, C=0 otherwise
;;; Assert: Interrupts disabled
;;; ============================================================

.proc DetectPhasor
        ptr := $06

        txa
        pha                     ; preserve caller's X

        lda     ptr+1           ; $Cs00 high byte
        and     #$07            ; slot
        asl
        asl
        asl
        asl                     ; X offset = slot * 16
        tax

        ;; Force Phasor native mode: $C0(8+s)D
        lda     $C08D,X

        ;; In native mode, $Cs04 should no longer be VIA0.
        ldy     #$04
        jsr     ProbeViaTimerPreserveX
        bcs     fail_restore

        ;; In native mode, VIA0 timer-low appears at $Cs14.
        ldy     #$14
        jsr     ProbeViaTimerPreserveX
        bcc     fail_restore

        ;; Restore Mockingboard-compatible mode: $C0(8+s)8
        lda     $C088,X

        pla
        tax
        RETURN  C=1

fail_restore:
        lda     $C088,X

        pla
        tax
        RETURN  C=0
.endproc

.proc ProbeViaTimerPreserveX
        ptr := $06
        tmp := $08

        txa
        pha

        ldx     #2

loop:   lda     (ptr),Y
        sta     tmp
        lda     (ptr),Y

        sec
        sbc     tmp
        cmp     #($100 - 8)
        bne     fail

        dex
        bne     loop

        pla
        tax
        RETURN  C=1

fail:   pla
        tax
        RETURN  C=0
.endproc
