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
        lda     #0
        sta     UpdateProgress::count

        bit     supports_mousetext
        bpl     done

        CALL    VTABZ, A=#kProgressVtab
        lda     #kProgressHtab
        sta     OURCH

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

done:   rts
.endproc ; InitProgress

.proc UpdateProgress
        CALL    VTABZ, A=#kProgressVtab
        lda     #kProgressHtab
        sta     OURCH

        count := *+1
        lda     #0              ; must start as 0
        clc
        adc     #kProgressTick
        sta     count

        tax
        lda     #' '            ; inverse
    DO
        jsr     COUT
        dex
    WHILE NOT_ZERO

        rts
.endproc ; UpdateProgress

;;; ============================================================
;;; Try to detect an Enhanced IIe or later (IIc, IIgs, etc),
;;; to infer support for MouseText characters.
;;; Done by testing testing for a ROM signature.
;;; Output: Sets `supports_mousetext` to $80.

.proc DetectMousetext
        lda     ZIDBYTE
        beq     enh    ; IIc/IIc+ have $00
        cmp     #$E0   ; IIe original has $EA, Enh. IIe, IIgs have $E0
        bne     done

enh:    copy8   #$80, supports_mousetext

done:   rts
.endproc ; DetectMousetext

supports_mousetext:
        .byte   0
