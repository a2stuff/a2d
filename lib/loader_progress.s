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

.proc InitProgress
        bit     supports_mousetext
        bpl     done

        lda     #kProgressVtab
        jsr     VTABZ
        lda     #kProgressHtab
        sta     OURCH

        ;; Enable MouseText
        lda     #$0F|$80
        jsr     COUT
        lda     #$1B|$80
        jsr     COUT

        ;; Draw progress track (alternating checkerboards)
        ldx     #kProgressWidth
:       lda     #'V'|$80
        jsr     COUT
        dex
        beq     :+
        lda     #'W'|$80
        jsr     COUT
        dex
        bne     :-

        ;; Disable MouseText
:       lda     #$18|$80
        jsr     COUT
        lda     #$0E|$80
        jsr     COUT

done:   rts
.endproc

.proc UpdateProgress
        lda     #kProgressVtab
        jsr     VTABZ
        lda     #kProgressHtab
        sta     OURCH

        count := *+1
        lda     #0              ; must start as 0
        clc
        adc     #kProgressTick
        sta     count

        tax
        lda     #' '
:       jsr     COUT
        dex
        bne     :-

        rts
.endproc

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

enh:    copy    #$80, supports_mousetext

done:   rts
.endproc

supports_mousetext:
        .byte   0
