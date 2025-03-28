;;; Adjust a filename's case according to heuristics.
;;; The start of a word (period-delimited) is left capitalized,
;;; otherwise lowercased.

;;; Requires `ptr` to be defined.

.assert kBuildSupportsLowercase, error, "Do not use if lowercase not allowed"
.scope
        ldy     #0
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        beq     done

        ;; Walk backwards through string. At char N, check char N-1; if
        ;; it is a letter, and char N is also a letter, lower-case it.
        tay

loop:   dey
        beq     done
        bpl     :+
done:   rts

:       lda     (ptr),y
        cmp     #'A'
        bcs     check_alpha
        dey
        bpl     loop            ; always

check_alpha:
        iny
        lda     (ptr),y
        cmp     #'A'
        bcc     :+
        ora     #AS_BYTE(~CASE_MASK) ; guarded by `kBuildSupportsLowercase`
        sta     (ptr),y
:       dey
        bpl     loop            ; always
.endscope
