;;; ============================================================
;;; ToUpperCase
;;; ============================================================

;;; Input: A = char
;;; Output: A = Uppercased if in 'a'...'z', otherwise unchanged
.proc ToUpperCase
        cmp     #'a'
        bcc     ret
        cmp     #'z'+1
        bcs     ret
        and     #CASE_MASK
ret:    rts
.endproc ; ToUpperCase
