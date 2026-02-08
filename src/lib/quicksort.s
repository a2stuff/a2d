;;; ============================================================
;;; Quicksort Routine
;;;
;;; Pretty much uses the pseudocode from Wikipedia
;;; * Only does true recursion on the smaller partition to avoid
;;;   blowing out the stack. Tail recursion handles the other.
;;; * "Fat partition" scheme is used
;;;
;;; Caller sets these procs:
;;; * `Quicksort_GetPtrProc` - In: A = index; Out: A,X = ptr
;;; * `Quicksort_CompareProc` - In: $06,$08 ptrs to compare; Out: Z, C
;;; * `Quicksort_SwapProc` - In: X,Y
;;;
;;; Input: A = number of items
;;;
;;; Uses $06/$08 and $20... $2F

.proc Quicksort
        ;; --------------------------------------------------
        ;; Quicksort

        tay
        dey                     ; Y = upper index
        ldx     #0              ; X = lower index
        FALL_THROUGH_TO quicksort

        lo   := $20
        hi   := $21
        lt   := $22
        eq   := $23
        gt   := $24
        s1   := $25

        ;; Input: X = lower index, Y = upper index
.proc quicksort

        ;; X is lo, Y is hi
        stx     lo
        sty     hi

        ;; while lo < hi
        RTS_IF X >= hi

        ;; lt, gt := partition(lo, hi)
        jsr     partition

        ldx     lo
        ldy     hi

        ;; Size of lower partition
        ;; s1 := (lt - 1) - lo
        lda     lt
        sec
        sbc     lo              ; Assert: no borrow, so leaves C=1
    IF ZERO
        ldx     gt              ; partition empty, so do other
        jmp     tc1
    END_IF
        sbc     #1
        sta     s1

        ;; Size of upper partition
        ;; s2 := hi - (gt + 1)
        tya                     ; A = hi
        sec
        sbc     gt              ; Assert: no borrow, so leaves C=1
    IF ZERO
        ldy     lt              ; partition empty, so do other
        jmp     tc2
    END_IF
        sbc     #1              ; A = s2

        ;; Recurse on smaller partition
        cmp     s1
    IF GE
        tya
        pha                     ; A = hi
        lda     gt
        pha                     ; A = gt

        ;; recurse quicksort(lo, lt - 1)
        ldy     lt
        dey                     ; Y = part - 1
        jsr     quicksort       ; X still lo

        ;; tail-call quicksort(gt + 1, hi)
        pla                     ; A = gt
        tax
        pla                     ; A = hi
        tay                     ; Y = hi
tc1:    inx                     ; X = gt + 1
        jmp     quicksort
    END_IF

        txa
        pha                     ; A = lo
        lda     lt
        pha                     ; A = lt

        ;; recurse quicksort(gt + 1, hi)
        ldx     gt
        inx                     ; X = gt + 1
        jsr     quicksort       ; Y still hi

        ;; tail-call quicksort(lo, lt - 1)
        pla                     ; A = lt
        tay
        pla                     ; A = lo
        tax                     ; X = lo
tc2:    dey                     ; Y = lt - 1
        jmp     quicksort

.endproc ; quicksort

        ;; Input: X = `lo` = lower index, Y = `hi` = upper index
        ;; Output: `lt`, `gt`
.proc partition
        pivot := $06
        temp := $08

        ;; lt := lo
        stx     lt
        ;; eq := lo
        stx     eq
        ;; gt := hi
        sty     gt

        ;; pivot := A[(lo + hi) / 2]
        txa
        clc
        adc     hi              ; 9-bit result in A,C
        ror                     ; /= 2 yields 8 bit result
        jsr     getptr
        stax    pivot

        ;; while eq <= gt do
loop:
        lda     gt
        cmp     eq
        RTS_IF LT

        lda     eq
        jsr     getptr
        stax    temp

        CompareProc := *+1
        jsr     SELF_MODIFIED

        ;; if A[eq] = pivot then
    IF EQ
        ;; eq := eq + 1
        inc     eq
        jmp     loop
    END_IF

        ;; if A[eq] < pivot then
    IF GE
        ;; swap A[eq] with A[lt]
        ldx     eq
        ldy     lt
        jsr     swap
        ;; lt := lt + 1
        inc     lt
        ;; eq := eq + 1
        inc     eq
        jmp     loop
    END_IF

        ;; if A[eq] > pivot then
        ;; swap A[eq] with A[gt]
        ldx     eq
        ldy     gt
        jsr     swap
        ;; gt := gt - 1
        dec     gt
        jmp     loop
.endproc ; partition

        GetPtrProc := *+1
getptr: jmp     SELF_MODIFIED

        CompareProc := partition::CompareProc

        SwapProc := *+1
swap:   jmp     SELF_MODIFIED

.endproc ; Quicksort
Quicksort_GetPtrProc := Quicksort::GetPtrProc
Quicksort_CompareProc := Quicksort::CompareProc
Quicksort_SwapProc := Quicksort::SwapProc
