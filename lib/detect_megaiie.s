;;; ============================================================
;;; Detect the "Mega IIe" machine, a project by @baldengineer to
;;; build a IIe-compatible machine using the Mega II chip from a
;;; IIgs on a custom motherboard with the minimum necessary
;;; support chips.
;;;
;;; The Mega II provides NEWVIDEO softswitch support, which allows
;;; software control over color/monochrome DHGR graphics.

;;; Output: Z=1 if Mega IIe, Z=0 otherwise
;;; Assert: ROM is banked in
;;; Trashes A, X
.proc DetectMegaIIe
        ldx     #AS_BYTE(-1)
:       inx
        lda     sig,x
        beq     :+
        cmp     SIG_ADDR,x
        beq     :-
:
        rts

        ;; Context: https://www.youtube.com/watch?v=gFCD4s_hsb4
        SIG_ADDR := $FB09
sig:    scrcode "Mega IIe"
        .byte   0

.endproc ; DetectMegaIIe
