;;; ============================================================
;;; 32 bit by 32 bit division with 32 bit result
;;; Based on: https://www.reddit.com/r/asm/comments/nbu2dj/32_bit_division_subroutine_on_the_6502/gy21eog/

numerator       := $10
denominator     := $14
quotient        := numerator

.proc Div_32_32
remainder       := $18
temp            := $1C

        ldx     #4-1
        lda     #0
:       sta     remainder,x
        dex
        bpl     :-

        ldx     #32             ; bits
divloop:
        asl     numerator+0
        rol     numerator+1
        rol     numerator+2
        rol     numerator+3

        rol     remainder+0
        rol     remainder+1
        rol     remainder+2
        rol     remainder+3

        sec
        lda     remainder+0
        sbc     denominator+0
        sta     temp+0

        lda     remainder+1
        sbc     denominator+1
        sta     temp+1

        lda     remainder+2
        sbc     denominator+2
        sta     temp+2

        lda     remainder+3
        sbc     denominator+3
        sta     temp+3

        bcc     next            ; remainder > divisor?
        inc     numerator       ; yes

        ldy     #4-1            ; remainder = temp
:       lda     temp,y
        sta     remainder,y
        dey
        bpl     :-

next:   dex
        bne     divloop

        rts
.endproc ; Div_32_32

;;; ============================================================
;;; 16 bit by 16 bit multiply with 32 bit product

multiplier      := $10
multiplicand    := $12
product         := $14

.proc Mul_16_16
        lda     #0
        sta     product+2
        sta     product+3

        ldx     #16
shift:
        lsr     multiplier+1
        ror     multiplier
        bcc     rotate
        lda     product+2
        clc
        adc     multiplicand
        sta     product+2
        lda     product+3
        adc     multiplicand+1
rotate:
        ror     a
        sta     product+3
        ror     product+2
        ror     product+1
        ror     product
        dex
        bne     shift

        rts
.endproc ; Mul_16_16
