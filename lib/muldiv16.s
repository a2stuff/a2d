;;; ============================================================
;;; Multiplies two 16-bit values and then divides the 32-bit result by
;;; a third 16-bit value, yielding a 16-bit value.
;;; Used for scaling e.g. scroll bar or progress bar position.

;;; Callers should populate:
;;; * `muldiv_number`, `muldiv_numerator`, `muldiv_denominator`
;;; Result is in:
;;; * `muldiv_result`

;;; Uses $10...$17

.proc MulDiv
        ACL     := $10                  ; $50 in original routines
        ACH     := $11
        XTNDL   := $12                  ; $52 in original routines
        XTNDH   := $13
        AUXL    := $14                  ; $54 in original routines
        AUXH    := $15
        AUX2L   := $16                  ; not in original routines
        AUX2H   := $17

        ;; Prepare, per "Apple II Monitors Peeled" pp.71

        lda     #0
        sta     XTNDL
        sta     XTNDH

        ;; From MUL routine in Apple II Monitor, by Woz
        ;; "Apple II Reference Manual" pp.162

        ldy     #16             ; Index for 16 bits
MUL2:   lda     ACL             ; ACX * AUX + XTND
        lsr                     ;   to AC, XTND
        bcc     MUL4            ; If no carry,
        clc                     ;   no partial product.
        ldx     #AS_BYTE(-2)
MUL3:   lda     XTNDL+2,x       ; Add multiplicand (AUX)
        adc     AUXL+2,x        ;  to partial product
        sta     XTNDL+2,x       ;     (XTND).
        inx
        bne     MUL3
MUL4:   ldx     #3
MUL5:   ror     ACL,x
        dex
        bpl     MUL5
        dey
        bne     MUL2

        ;; From DIV routine in Apple II Monitor, by Woz
        ;; "Apple II Reference Manual" pp.162
        ;; (but divisor is AUX2 instead of AUX)

        ldy     #16             ; Index for 16 bits
DIV2:   asl     ACL
        rol     ACH
        rol     XTNDL           ; XTND/AUX2
        rol     XTNDH           ;   to AC.
        sec
        lda     XTNDL
        sbc     AUX2L           ; Modulus to XTND.
        tax
        lda     XTNDH
        sbc     AUX2H
        bcc     DIV3
        stx     XTNDL
        sta     XTNDH
        inc     ACL
DIV3:   dey
        bne     DIV2

        rts

.endproc ; MulDiv

muldiv_number       := MulDiv::ACL      ; [16]
muldiv_numerator    := MulDiv::AUXL     ; [16]
muldiv_denominator  := MulDiv::AUX2L    ; [16]
muldiv_result       := MulDiv::ACL      ; [16]

