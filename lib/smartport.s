;;; ============================================================
;;; Look up SmartPort dispatch address.
;;; Input: A = unit number
;;; Output: Z=1 if SP, $0A/$0B dispatch address, X = SP unit num
;;;         Z=0 if not SP

.proc FindSmartportDispatchAddress
        sp_addr := $0A

        sta     unit_number     ; DSSSnnnn

        ;; Get device driver address
        jsr     DeviceDriverAddress
        bne     exit            ; RAM-based driver

        ;; Find actual address
        copy    #0, sp_addr     ; point at $Cn00 for firmware lookups

        ldy     #$07            ; SmartPort signature byte ($Cn07)
        lda     (sp_addr),y     ; $00 = SmartPort
        bne     exit

        ;; Locate SmartPort entry point: $Cn00 + ($CnFF) + 3
        ldy     #$FF
        lda     (sp_addr),y
        clc
        adc     #3
        sta     sp_addr

        ;; Figure out SmartPort control unit number in X
        ldx     #1              ; start with unit 1
        bit     unit_number     ; high bit is D
        bpl     :+
        inx                     ; X = 1 or 2 (for Drive 1 or 2)

:       lda     unit_number
        and     #%01110000      ; 0SSSnnnn
        lsr
        lsr
        lsr
        lsr
        sta     mapped_slot     ; 00000SSS

        lda     sp_addr+1       ; $Cn
        and     #%00001111      ; $0n
        cmp     mapped_slot     ; equal = not remapped
        beq     :+
        inx                     ; now X = 3 or 4
        inx

:       lda     #0              ; exit with Z set on success
exit:   rts

unit_number:
        .byte   0
mapped_slot:                    ; from unit_number, not driver
        .byte   0
.endproc

;;; ============================================================
;;; Look up device driver address.
;;; Input: A = unit number
;;; Output: $0A/$0B ptr to driver; Z set if $CnXX

.proc DeviceDriverAddress
        slot_addr := $0A

        and     #%11110000      ; mask off drive/slot
        lsr                     ; 0DSSS000
        lsr                     ; 00DSSS00
        lsr                     ; 000DSSS0
        tax                     ; = slot * 2 + (drive == 2 ? 0x10 + 0x00)

        lda     DEVADR,x
        sta     slot_addr
        lda     DEVADR+1,x
        sta     slot_addr+1

        and     #$F0            ; is it $Cn ?
        cmp     #$C0            ; leave Z flag set if so
        rts
.endproc
