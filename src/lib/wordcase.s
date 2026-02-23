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
    DO
        dey
        beq     done
      IF NEG
done:   rts
      END_IF

        lda     (ptr),y
        cmp     #'A'
        bcs     check_alpha
        dey
        REDO_IF POS             ; always

check_alpha:
        iny
        lda     (ptr),y
        cmp     #'A'
      IF GE
        ora     #AS_BYTE(~CASE_MASK) ; guarded by `kBuildSupportsLowercase`
        sta     (ptr),y
      END_IF
        dey
    WHILE POS                   ; always
.endscope
