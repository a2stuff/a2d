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
        bne     exit            ; RAM-based driver (exit with Z=0 on failure)

        ;; Find actual address
        copy    #$00, sp_addr   ; point at $Cn00 for firmware lookups

        ldy     #$07            ; SmartPort signature byte ($Cn07)
        lda     (sp_addr),y     ; $00 = SmartPort
        bne     exit            ; nope (exit with Z=0 on failure)

        ;; Locate SmartPort entry point: $Cn00 + ($CnFF) + 3
        ldy     #$FF
        lda     (sp_addr),y
        clc
        adc     #3
        sta     sp_addr

        ;; Figure out SmartPort control unit number in X

;;; Per Technical Note: ProDOS #21: Mirrored Devices and SmartPort
;;; http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.20.html
;;; ... but that predates ProDOS 2.x, which changes the scheme.
;;;
;;; * ProDOS 1.2...1.9 mirror S5,D3/4 to S2,D1/2 only, and leave `DEVADR`
;;;   entry pointing at $C5xx. Therefore, if the unit number slot matches
;;;   the driver slot, the device is not mirrored, and SmartPort unit is
;;;   1 or 2. Otherwise, the device is mirrored, and SmarPort unit is 3
;;;   or 4.
;;;
;;; * ProDOS 2.x mirror to non-device slots, and point `DEVADR` at
;;;   RAM-based drivers, which are already excluded above. Therefore the
;;;   device is not mirrored, the unit number slot will match the driver
;;;   slot, and the SmartPort unit is 1 or 2.

        ldx     #1              ; start with unit 1
        bit     unit_number     ; high bit is D
        bpl     :+
        inx                     ; X = 1 or 2 (for Drive 1 or 2)
:
        ;; Was it remapped? (ProDOS 1.x-only behavior)
        lda     unit_number
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
:
        lda     #0              ; exit with Z set on success
exit:   rts

unit_number:
        .byte   0
mapped_slot:
        .byte   0
.endproc

;;; ============================================================
;;; Get driver address for unit number
;;; Input: A = unit number
;;; Output: $A/$B points at driver address
;;;         Z=1 if a firmware address ($CnXX)

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
