;;; ============================================================

;;; Day of the Week calculation (valid 1900-03-01 to 2155-12-31)
;;; c/o http://6502.org/source/misc/dow.htm
;;; Inputs: Y = year (0=1900), X = month (1=Jan), A = day (1...31)
;;; Output: A = weekday (0=Sunday)
.proc DayOfWeek
        tmp := $06

        cpx     #3              ; Year starts in March to bypass
        bcs     :+              ; leap year problem
        dey                     ; If Jan or Feb, decrement year
:       eor     #$7F            ; Invert A so carry works right
        cpy     #200            ; Carry will be 1 if 22nd century
        adc     month_offset_table-1,X ; A is now day+month offset
        sta     tmp
        tya                     ; Get the year
        jsr     mod7            ; Do a modulo to prevent overflow
        sbc     tmp             ; Combine with day+month
        sta     tmp
        tya                     ; Get the year again
        lsr                     ; Divide it by 4
        lsr
        clc                     ; Add it to y+m+d and fall through
        adc     tmp

mod7:   adc     #7              ; Returns (A+3) modulo 7
        bcc     mod7            ; for A in 0..255
        rts

month_offset_table:
        .byte   1,5,6,3,1,5,3,0,4,2,6,4
        ASSERT_TABLE_SIZE month_offset_table, 12
.endproc ; DayOfWeek
