;;; ============================================================
;;; ToUpperCase
;;; ============================================================

;;; Translates ASCII lowercase ('a'-'z') to ASCII uppercase ('A'-'Z')
;;; If the build encoding does not include ASCII lowercase, a no-op.

;;; Input: A = char
;;; Output: A = Uppercased if in 'a'...'z', otherwise unchanged
.proc ToUpperCase
.if kBuildSupportsLowercase
    IF A BETWEEN #'a', #'z'
        and     #CASE_MASK      ; guarded by `kBuildSupportsLowercase`
    END_IF
.endif
        rts
.endproc ; ToUpperCase
