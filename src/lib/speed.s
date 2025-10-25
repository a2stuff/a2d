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

;;; Assert: Aux LC is banked in; interrupts are inhibited
;;; NOTE: Must be called after `SlowSpeed`
.proc ResumeSpeed
        CALL    ReadSetting, X=#DeskTopSettings::system_capabilities

        tax                     ; A = X = kSysCapXYZ bitmap
        and     #DeskTopSettings::kSysCapIsIIgs
    IF NOT_ZERO
        ResumeSpeed::saved_cyareg := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     CYAREG
        rts
    END_IF

        ;; Restore speed on Mac IIe Option Card
        txa                     ; A = X = kSysCapXYZ bitmap
        and     #DeskTopSettings::kSysCapIsIIeCard
    IF NOT_ZERO
        ResumeSpeed::saved_maciie := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     MACIIE
        rts
    END_IF

        ;; Restore speed on Laser 128
        txa                     ; A = X = kSysCapXYZ bitmap
        and     #DeskTopSettings::kSysCapIsLaser128
    IF NOT_ZERO
        ResumeSpeed::saved_laserreg := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     LASER128EX_CFG
    END_IF

        rts
.endproc ; ResumeSpeed

;;; Assert: Aux LC is banked in; interrupts are inhibited
;;; NOTE: Must be followed by a call to `ResumeSpeed`
.proc SlowSpeed
        CALL    ReadSetting, X=#DeskTopSettings::system_capabilities

        ;; Slow down on IIgs
        tax                     ; A = X = kSysCapXYZ bitmap
        and     #DeskTopSettings::kSysCapIsIIgs
    IF NOT_ZERO
        lda     CYAREG
        sta     ResumeSpeed::saved_cyareg
        and     #%01111111      ; clear bit 7
        sta     CYAREG
        rts
    END_IF

        ;; Slow down on Mac IIe Option Card
        ;; Per Technical Note: Apple IIe #10: The Apple IIe Card for the Macintosh LC
        ;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/aiie/tn.aiie.10.html
        ;; Restore speed on Mac IIe Option Card
        txa                     ; A = X = kSysCapXYZ bitmap
        and     #DeskTopSettings::kSysCapIsIIeCard
    IF NOT_ZERO
        lda     MACIIE
        sta     ResumeSpeed::saved_maciie
        and     #%11111011      ; clear bit 2
        sta     MACIIE
        rts
    END_IF

        ;; Slow down on Laser 128 (EX or EX/2)
        txa                     ; A = X = kSysCapXYZ bitmap
        and     #DeskTopSettings::kSysCapIsLaser128
    IF NOT_ZERO
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
