;;; ============================================================
;;; Input: numbers in A,X, Y (all unsigned)
;;; Output: number in A,X (unsigned)
;;; Uses $10...$1F

.proc Multiply_16_8_16
.struct
        .org $10
num1    .word
num2    .byte
.endstruct

        stax    num1
        sty     num2

        ;; Accumulate directly into A,X
        lda     #0
        tax
        beq     test

add:    clc
        adc     num1
        tay

        txa
        adc     num1+1
        tax
        tya

loop:   asl     num1
        rol     num1+1
test:   lsr     num2
        bcs     add
        bne     loop

        rts

.endproc ; Multiply_16_8_16

;;; ============================================================
;;; Input: dividend in A,X, divisor in Y (all unsigned)
;;; Output: quotient in A,X (unsigned), Y = remainder
;;; Uses $10...$1F

.proc Divide_16_8_16
.struct
        .org $10
dividend        .word
divisor         .word
remainder       .word
.endstruct

        result := dividend

        stax    dividend
        sty     divisor
        lda     #0
        sta     divisor+1
        sta     remainder
        sta     remainder+1
        ldx     #16             ; bits

loop:   asl     dividend
        rol     dividend+1
        rol     remainder
        rol     remainder+1
        lda     remainder
        sec
        sbc     divisor
        tay
        lda     remainder+1
        sbc     divisor+1
        bcc     skip
        sta     remainder+1
        sty     remainder
        inc     result

skip:   dex
        bne     loop
        ldax    dividend
        ldy     remainder
        rts
.endproc ; Divide_16_8_16
