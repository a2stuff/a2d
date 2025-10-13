;;; ============================================================
;;; Detect the Mega II, the Apple II "computer-on-a-chip" used to
;;; implement a substantial amount of the logic for the IIgs. Notably,
;;; it provides `NEWVIDEO` softswitch support, which allows software
;;; control over color/monochrome DHGR graphics. This chip is used in
;;; experimental systems like the Mega IIe by @baldengineer.
;;;
;;; (This may possibly allow software control over DHGR color/mono on
;;; the TLC and VOC, but this has not yet been tested.)
;;;
;;; Detection is done using `STATEREG` which is also provided by the
;;; Mega II chip.

;;; Output: Z=1 if Mega II, Z=0 otherwise
;;; Trashes A, X
.proc DetectMegaII
        ldx     RDPAGE2
        stx     rdpage2_flag
        ldx     RDALTZP
        stx     rdaltzp_flag

        ;; Set to known state
        sta     PAGE2OFF
        sta     ALTZPOFF

        ;; Test state
        lda     STATEREG

        ;; Invert state
        sta     PAGE2ON
        sta     ALTZPON

        ;; Record what bits changed
        eor     STATEREG

        ;; Restore banking
        rdaltzp_flag := *+1
        ldx     #SELF_MODIFIED_BYTE
    IF NC
        stx     ALTZPOFF        ; restore ALTZOFF
    END_IF

        rdpage2_flag := *+1
        ldx     #SELF_MODIFIED_BYTE
    IF NC
        bit     PAGE2OFF        ; restore PAGE2OFF
    END_IF

        cmp     #%11000000      ; bit7=ALTZP, bit6=PAGE2
        rts
.endproc ; DetectMegaII
