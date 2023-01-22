;;; ============================================================
;;; Entry points:
;;;   IntToString - no thousands separators
;;;   IntToStringWithSeparators - thousands separator
;;; Input: 16-bit unsigned integer in A,X
;;; Output: length-prefixed string in str_from_int

.scope IntToStringImpl

;;; Entry point: with thousands separators
sep:    sec
        bcs     common

;;; Entry point: without thousands separators
nosep:  clc
        FALL_THROUGH_TO common

common: stax    value
        ror                     ; move carry to high bit
        sta     separator_flag

        lda     #0
        sta     nonzero_flag
        ldy     #0              ; y = position in string
        ldx     #0              ; x = which power index is subtracted (*2)

        ;; For each power of ten
loop:   lda     #0
        sta     digit

        ;; Keep subtracting/incrementing until zero is hit
sloop:  cmp16   value, powers,x
        bcc     break
        inc     digit
        sub16   value, powers,x, value
        jmp     sloop

break:  lda     digit
        bne     not_pad
        bit     nonzero_flag
        bpl     next

        ;; Convert to ASCII
not_pad:
        ora     #'0'
        pha
        copy    #$80, nonzero_flag
        pla

        ;; Place the character
        iny
        sta     str_from_int,y

        ;; Add thousands separator, if needed
        bit     separator_flag
        bpl     next
        cpx     #2
        bne     next
        iny
        lda     SETTINGS + DeskTopSettings::intl_thou_sep
        sta     str_from_int,y

next:   inx
        inx
        cpx     #8              ; up to 4 digits (*2) via subtraction
        beq     done
        jmp     loop

done:   lda     value           ; handle last digit
        ora     #'0'
        iny
        sta     str_from_int,y
        sty     str_from_int
        rts

powers: .word   10000, 1000, 100, 10
value:  .word   0            ; remaining value as subtraction proceeds
digit:  .byte   0            ; current digit being accumulated
nonzero_flag:                ; high bit set once a non-zero digit seen
        .byte   0
separator_flag:
        .byte   0
.endscope ; IntToStringImpl

IntToString                 := IntToStringImpl::nosep
IntToStringWithSeparators   := IntToStringImpl::sep
