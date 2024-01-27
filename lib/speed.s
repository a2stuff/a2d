;;; ============================================================
;;; Accelerator (speed) control
;;;
;;; Not as full featured as lib/normfast.s - just used for
;;; *temporary* speed changes e.g. around alert sounds.
;;;
;;; Currently handles:
;;; * IIgs built-in accelerator
;;; * Mac IIe Option Card built-in accelerator
;;; * Laser 128 EX and EX/2 built-in accelerator
;;;
;;; The Apple IIc Plus is explicitly *not* handled. Speed
;;; adjustments using the CGGA kick the machine out of
;;; DHIRES mode. This can be restored, but even if done
;;; immediately after a call there are still unacceptable
;;; visual glitches for several scan lines after each call.
;;; (See Apple IIc Technical Reference Manual 2nd Ed.)
;;; ============================================================
;;; Exposes two procs:
;;; * `SlowSpeed` - slows system down to 1MHz
;;; * `ResumeSpeed` - restores accelerator to previous state
;;; ============================================================
;;; Required definitions:
;;; * `machine_config::iigs_flag` - high bit set if on IIgs
;;; * `machine_config::iiecard_flag` - high bit set if on Mac IIe Option Card
;;; * `machine_config::laser128_flag` - high bit set if on Laser 128
;;; ============================================================

;;; Assert: Aux LC is banked in; interrupts are inhibited
;;; NOTE: Must be called after `SlowSpeed`
.proc ResumeSpeed
        ;; Restore speed on IIgs
        bit     machine_config::iigs_flag
    IF_NS
        ResumeSpeed::saved_cyareg := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     CYAREG
    END_IF

        ;; Restore speed on Mac IIe Option Card
        bit     machine_config::iiecard_flag
    IF_NS
        ResumeSpeed::saved_maciie := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     MACIIE
    END_IF

        ;; Restore speed on Laser 128
        bit     machine_config::laser128_flag
    IF_NS
        ResumeSpeed::saved_laserreg := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     LASER128EX_CFG
    END_IF

        rts
.endproc ; ResumeSpeed

;;; Assert: Aux LC is banked in; interrupts are inhibited
;;; NOTE: Must be followed by a call to `ResumeSpeed`
.proc SlowSpeed
        ;; Slow down on IIgs
        bit     machine_config::iigs_flag
    IF_NS
        lda     CYAREG
        sta     ResumeSpeed::saved_cyareg
        and     #%01111111      ; clear bit 7
        sta     CYAREG
    END_IF

        ;; Slow down on Mac IIe Option Card
        ;; Per Technical Note: Apple IIe #10: The Apple IIe Card for the Macintosh LC
        ;; http://www.1000bit.it/support/manuali/apple/technotes/aiie/tn.aiie.10.html
        bit     machine_config::iiecard_flag
    IF_NS
        lda     MACIIE
        sta     ResumeSpeed::saved_maciie
        and     #%11111011      ; clear bit 2
        sta     MACIIE
    END_IF

        ;; Slow down on Laser 128 (EX or EX/2)
        bit     machine_config::laser128_flag
    IF_NS
        lda     LASER128EX_CFG
        sta     ResumeSpeed::saved_laserreg
        and     #$3F            ; mask off
        sta     LASER128EX_CFG
        ;; NOTE: The Laser 128's screen hole location $7FE which is used for
        ;; persistence speed (e.g. to restore speed after disk access) is not
        ;; touched, as we don't want this to persist.
    END_IF

        rts
.endproc ; SlowSpeed
