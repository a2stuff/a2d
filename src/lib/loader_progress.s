;;; ============================================================
;;; Display progress bar on text screen.
;;; Used by Desktop.system, Desktop and Selector
;;;
;;; Clients:
;;; * must define `kProgressStops`
;;; * call `InitProgress` once
;;; * call `UpdateProgress` for each stop
;;; Assertions:
;;; * ROM is banked in, 80 column firmware active
;;;
;;; `DetectMousetext` is also defined, since all clients use it.
;;; ============================================================

        kProgressVtab = 14
        kProgressTick = 40 / kProgressStops
        kProgressHtab = (80 - (kProgressTick * kProgressStops)) / 2
        kProgressWidth = kProgressStops * kProgressTick

PREDEFINE_SCOPE UpdateProgress

.proc InitProgress
        copy8   #0, UpdateProgress::count

    IF bit supports_mousetext : NS
        CALL    VTABZ, A=#kProgressVtab
        copy8   #kProgressHtab, OURCH

        ;; Enable MouseText
        CALL    COUT, A=#$0F|$80
        CALL    COUT, A=#$1B|$80

        ;; Draw progress track (alternating checkerboards)
        ldx     #kProgressWidth
      DO
        CALL    COUT, A=#'V'|$80
        dex
        BREAK_IF ZERO

        CALL    COUT, A=#'W'|$80
        dex
      WHILE NOT_ZERO

        ;; Disable MouseText
        CALL    COUT, A=#$18|$80
        CALL    COUT, A=#$0E|$80
    END_IF
        rts
.endproc ; InitProgress

.proc UpdateProgress
        CALL    VTABZ, A=#kProgressVtab
        copy8   #kProgressHtab, OURCH

        count := *+1
        lda     #0              ; must start as 0
        clc
        adc     #kProgressTick
        sta     count

        tax
        lda     #' '            ; inverse
    DO
        jsr     COUT
    WHILE dex : NOT_ZERO

        rts
.endproc ; UpdateProgress

;;; ============================================================
;;; Try to detect an Enhanced IIe or later (IIc, IIgs, etc),
;;; to infer support for MouseText characters.
;;; Done by testing testing for a ROM signature.
;;; Output: Sets high bit of `supports_mousetext`

.proc DetectMousetext
        ;; IIc/IIc+ have $00
        ;; IIe original has $EA, Enh. IIe, IIgs have $E0
    IF lda ZIDBYTE : ZERO OR A = #$E0
        SET_BIT7_FLAG supports_mousetext
    END_IF
        rts
.endproc ; DetectMousetext

supports_mousetext:             ; bit7
        .byte   0
