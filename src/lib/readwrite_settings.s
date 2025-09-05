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

.scope readwrite_settings_impl

read:   ldy     #OPC_LDA_abx
        SKIP_NEXT_2_BYTE_INSTRUCTION
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

        bit     LCBANK2
        bit     LCBANK2

        ;; Read or write
op:     lda     SETTINGS,x      ; self-modified

        ;; Restore banking
        plp
    IF_NC
        bit     LCBANK1         ; restore LCBANK1
        bit     LCBANK1
    END_IF

        plp
    IF_NC
        bit     ROMIN2          ; restore ROMIN2
    END_IF

        plp
    IF_NS
        sta     ALTZPON         ; restore ALTZPON
    END_IF

        pha                     ; ensure Z/N are set
        pla
        rts

.endscope ; readwrite_settings_impl

;;; Exports
ReadSetting     := readwrite_settings_impl::read
WriteSetting    := readwrite_settings_impl::write
