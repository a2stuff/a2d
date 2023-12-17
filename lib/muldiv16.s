;;; ============================================================
;;; Multiplies two 16-bit values and then divides the 32-bit result by
;;; a third 16-bit value, yielding a 32-bit value. The result will fit
;;; in 16 bits if it follows the pattern R = A * N / D and N <= D.
;;; Used for scaling e.g. scroll bar or progress bar position.

;;; Uses $10...$1F

muldiv_number       := $10      ; [16]
muldiv_numerator    := $12      ; [16]
muldiv_denominator  := $14      ; [16]
muldiv_result       := $16      ; [16]

;;; $10 \_ number         \
;;; $11 /                 |_ tmp
;;; $12 \_ numerator      |
;;; $13 /                 /
;;; $14 \_ denominator
;;; $15 /
;;; $16 \
;;; $17 |_ result (and intermediate value)
;;; $18 |
;;; $19 /
;;; $1A \
;;; $1B |_ remainder
;;; $1C |
;;; $1D /
;;; $1E :  unused
;;; $1F :  unused

.proc MulDiv

        ;; Zero out rest of scratch space
        lda     #0
        ldx     #$20 - (muldiv_result) - 1
:       sta     muldiv_result,x
        dex
        bpl     :-

.scope
;;; 16 bit by 16 bit multiply with 32 bit product
multiplier      := muldiv_number
multiplicand    := muldiv_numerator
product         := muldiv_result

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
.endscope

.scope
;;; 32 bit by 16 bit division with 32 bit result
;;; Based on: https://www.reddit.com/r/asm/comments/nbu2dj/32_bit_division_subroutine_on_the_6502/gy21eog/
numerator       := muldiv_result      ; [32]
denominator     := muldiv_denominator ; [16]
quotient        := muldiv_result      ; [32]

remainder       := $1C          ; [32]
temp            := $10          ; [32]

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
        sbc     #0              ; denominator+2
        sta     temp+2

        lda     remainder+3
        sbc     #0              ; denominator+3
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
.endscope

        rts

.endproc ; MulDiv
