;;; ============================================================
;;; Detect Mockingboard
;;;
;;; Inputs: $06 points at $Cs00
;;; Outputs: C=1 if detected, C=0 otherwise
;;; Assert: Interrupts disabled
;;; ============================================================

.proc DetectMockingboard
        ptr := $06
        tmp := $08

        ;; Hit Slot 6, which causes accelerators e.g. Zip Chip
        ;; to slow down.
        ;; NOTE: $C0E0 causes Virtual ][ emulator to make sound;
        ;; $C0EC (data read location) does not.
        bit     $C0EC

        ldy     #4              ; $Cn04
        ldx     #2              ; try 2 times

loop:   lda     (ptr),Y         ; 6522 Low-Order Counter
        sta     tmp             ; read 8 cycles apart
        lda     (ptr),Y

        sec                     ; compare counter offset
        sbc     tmp
        cmp     #($100 - 8)
        bne     fail
        dex
        bne     loop

        RETURN  C=1

fail:   RETURN  C=0
.endproc ; DetectMockingboard
