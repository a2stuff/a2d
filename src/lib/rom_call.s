;;; ============================================================
;;; ROMCall - this allows calling into the ROM while LCBANK1
;;; is banked in, while preserving A,X,Y,P into and out of the
;;; call. Callers provide the ROM entry point as two bytes
;;; after the JSR, e.g. JSR ROMCall / .addr ADDR

.proc ROMCall
        sta     saved_a
        stx     saved_x
        sty     saved_y
        php
        pla
        sta     saved_p

        ;; Adjust return address on stack, compute
        ;; original params address.
        pla
        sta     params
        clc
        adc     #<2
        tax
        pla
        sta     params+1
        adc     #>2
        phax

        ;; Copy the actual address
        ldy     #2      ; ptr is off by 1
    DO
        params := *+1
        lda     SELF_MODIFIED,y
        sta     addr-1,y
        dey
    WHILE NOT_ZERO

        ;; Bank in ROM for call
        bit     ROMIN2

        ;; Restore registers
        saved_p := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        saved_a := *+1
        lda     #SELF_MODIFIED_BYTE
        saved_x := *+1
        ldx     #SELF_MODIFIED_BYTE
        saved_y := *+1
        ldy     #SELF_MODIFIED_BYTE
        plp

        ;; Make the call
        addr := *+1
        jsr     SELF_MODIFIED

        ;; Bank in LC again
        php
        bit     LCBANK1
        bit     LCBANK1
        plp

        rts
.endproc ; ROMCall
