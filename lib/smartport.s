;;; ============================================================
;;; Look up SmartPort dispatch address.
;;; Input: A = unit number
;;; Output: C=0 if SP, A,X=dispatch address, Y = SP unit num
;;;         C=1 if not SP

.proc FindSmartportDispatchAddress
        sta     unit_number     ; DSSSnnnn

        ;; Get device driver address
        jsr     DeviceDriverAddress
        bne     fail            ; RAM-based driver (exit with Z=0 on failure)
        stx     dispatch_hi     ; just need high byte ($Cn)
        stx     hi1
        stx     hi2

        ;; Find actual address
        hi1 := *+2
        lda     $C007           ; SmartPort signature byte ($Cn07)
        bne     fail            ; nope (exit with Z=0 on failure)

        ;; Locate SmartPort entry point: $Cn00 + ($CnFF) + 3
        hi2 := *+2
        lda     $C0FF
        clc
        adc     #3
        sta     dispatch_lo

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

        ldy     #1              ; start with unit 1
        bit     unit_number     ; high bit is D
        bpl     :+
        iny                     ; Y = 1 or 2 (for Drive 1 or 2)
:
        ;; Was it remapped? (ProDOS 1.x-only behavior)
        unit_number := *+1
        lda     #SELF_MODIFIED_BYTE
        and     #%01110000      ; 0SSSnnnn
        lsr
        lsr
        lsr
        lsr
        sta     mapped_slot     ; 00000SSS

        lda     dispatch_hi     ; $Cn
        and     #%00001111      ; $0n
        mapped_slot := *+1
        cmp     #SELF_MODIFIED_BYTE ; equal = not remapped
        beq     :+
        iny                     ; now Y = 3 or 4
        iny
:
        dispatch_lo := *+1
        lda     #SELF_MODIFIED_BYTE
        dispatch_hi := *+1
        ldx     #SELF_MODIFIED_BYTE
        clc
        rts

fail:   sec
        rts

.endproc

;;; ============================================================
;;; Get driver address for unit number
;;; Input: A = unit number
;;; Output: A,X=driver address
;;;         Z=1 if a firmware address ($CnXX)

.proc DeviceDriverAddress
        and     #%11110000      ; mask off drive/slot
        lsr                     ; 0DSSS000
        lsr                     ; 00DSSS00
        lsr                     ; 000DSSS0
        tax                     ; = slot * 2 + (drive == 2 ? 0x10 + 0x00)

        lda     DEVADR,x
        tay                     ; Y = lo
        lda     DEVADR+1,x
        tax                     ; X = hi

        and     #$F0            ; is it $Cn ?
        cmp     #$C0            ; leave Z flag set if so
        php
        tya                     ; A = lo
        plp
        rts
.endproc
