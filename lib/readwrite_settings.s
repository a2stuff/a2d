;;; ============================================================
;;; Read or write a value to the settings store in Main/LCBank2.
;;;
;;; Can be called with any banking configuration - from Main or Aux.
;;; (`ALTZPON`/`ALTZPOFF`; `ROMIN2`/`LCBANK1`/`LCBANK2`)
;;;
;;; Inputs: X = offset into DeskTopSettings struct
;;;         A = new value (on write)
;;; Output: A = current value (on read), unchanged (on write)
;;;         X is unchanged
;;;         Y is scrambled
;;;         Z/N set appropriately for A
;;; ============================================================

.proc ReadWriteSettingsImpl

read:   ldy     #OPC_LDA_abx
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
write:  ldy     #OPC_STA_abx
        .assert (OPC_STA_abs & $F0) <> $C0, error, "bad BIT usage"
        sty     op

        ;; Save and change banking
        bit     RDALTZP
        sta     ALTZPOFF        ; preserve state on main stack
        php

        bit     RDLCRAM
        php

        bit     RDBNK2
        php

        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2

        ;; Read or write
op:     lda     SETTINGS,x      ; self-modified

        ;; Restore banking
        plp
        bmi     :+              ; leave LCBANK2
        bit     LCBANK1         ; restore LCBANK1
        bit     LCBANK1
:
        plp
        bmi     :+              ; leave LCRAM
        bit     ROMIN2          ; restore ROMIN2
:
        plp
        bpl     :+              ; leave ALTZPOFF
        sta     ALTZPON         ; restore ALTZPON
:
        pha                     ; ensure Z/N are set
        pla
        rts

.endproc ; ReadWriteSettingsImpl
        ReadSetting := ReadWriteSettingsImpl::read
        WriteSetting := ReadWriteSettingsImpl::write
