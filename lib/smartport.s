;;; define `SP_ALTZP` if called with ALTZPON active, don't if ALTZPOFF
;;; define `SP_LCBANK1` if called with LCBANK1 active, don't if ROMIN2


;;; Internal ProDOS tables are used to handle mirrored drives. The
;;; locations vary between ProDOS versions. For details, see:
;;; https://github.com/a2stuff/a2d/issues/685

;;; TODO: Handle additional versions, either by adding more
;;; logic or building mirroring tables ourselves on startup.
DevAdrP24       = $FCE6
SPUnitP24       = $D6EF
SPVecLP24       = $FD51
SPVecHP24       = $FD60

DevAdrP20x      = $FD08
SPUnitP20x      = $D6EF
SPVecLP20x      = $FD6E
SPVecHP20x      = $FD7D

;;; ============================================================
;;; Look up SmartPort dispatch address.
;;; Input: A = unit number
;;; Output: C=0 if SP, A,X=dispatch address, Y = SP unit num
;;;         C=1 if not SP

.proc FindSmartportDispatchAddress
        sta     unit_number     ; DSSSnnnn

        ;; Get device driver address
        jsr     DeviceDriverAddress
        bvs     mirrored
        bne     fail            ; RAM-based driver
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

        ;; Figure out SmartPort control unit number in Y

;;; Per Technical Note: ProDOS #21: Mirrored Devices and SmartPort
;;; http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.20.html
;;; ... but that predates ProDOS 2.x, which changes the scheme.
;;;
;;; Since we know that the `DEVADR` entry is a firmware ($Cn) address:
;;;
;;; * ProDOS 1.2...1.9 mirror S5,D3/4 to S2,D1/2 only, and leave `DEVADR`
;;;   entry pointing at $C5xx. Therefore, if the unit number slot matches
;;;   the driver slot, the device is not mirrored, and SmartPort unit is
;;;   1 or 2. Otherwise, the device is mirrored, and SmartPort unit is 3
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
        ;; Was it mirrored? (ProDOS 1.x-only behavior)
        unit_number := *+1
        lda     #SELF_MODIFIED_BYTE
        and     #%01110000      ; 0SSSnnnn
        lsr
        lsr
        lsr
        lsr
        sta     mirrored_slot   ; 00000SSS

        lda     dispatch_hi     ; $Cn
        and     #%00001111      ; $0n
        mirrored_slot := *+1
        cmp     #SELF_MODIFIED_BYTE ; equal = not mirrored
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

        ;; --------------------------------------------------
        ;; Mirrored SmartPort device with a known handler.
        ;; Look at ProDOS's internal tables to determine.
mirrored:
        tya
        tax                     ; X = ProDOS version index

        lda     unit_number
        lsr
        lsr
        lsr
        lsr
        tay                     ; Y = offset

.ifdef SP_ALTZP
        sta     ALTZPOFF
.endif
.ifndef SP_LCBANK1
        bit     LCBANK1
        bit     LCBANK1
.endif

        cpx     #1
    IF_EQ
        ;; ProDOS 2.0.x
        ldx     SPVecHP20x,y    ; X = sp vec hi
        lda     SPVecLP20x,y
        pha
        lda     SPUnitP20x,y
    ELSE
        ;; ProDOS 2.4.x
        ldx     SPVecHP24,y     ; X = sp vec hi
        lda     SPVecLP24,y
        pha
        lda     SPUnitP24,y
    END_IF
        tay                     ; Y = sp unit
        pla                     ; A = sp vec lo

.ifdef SP_ALTZP
        sta     ALTZPON
.endif
.ifndef SP_LCBANK1
        bit     ROMIN2
.endif

        clc
        rts
.endproc

;;; ============================================================
;;; Get driver address for unit number
;;; Input: A = unit number
;;; Output: A,X=driver address
;;;         V=1 if a mirrored SmartPort device, and Y is table index
;;;         Z=1 if a firmware address ($CnXX)

.proc DeviceDriverAddress
        clv

        and     #UNIT_NUM_MASK  ; mask off drive/slot
        lsr                     ; 0DSSS000
        lsr                     ; 00DSSS00
        lsr                     ; 000DSSS0
        tay                     ; = slot * 2 + (drive == 2 ? 0x10 + 0x00)

        lda     DEVADR,y        ; A = lo
        ldx     DEVADR+1,y      ; X = hi

        ;; ProDOS 2.x SmartPort mirroring?
        ldy     #0              ; Y=0 = ProDOS 2.4.x
        cmp     #<DevAdrP24
        bne     :+
        cpx     #>DevAdrP24
        beq     mirrored
:
        iny                     ; Y=1 = ProDOS 2.0.x
        cmp     #<DevAdrP20x
        bne     :+
        cpx     #>DevAdrP20x
        beq     mirrored
:
        ;; Not mirrored - set Z flag for firmware address
        pha
        txa
        and     #$F0
        tay
        pla
        cpy     #$C0            ; leave Z set if it is $Cn
        rts

mirrored:
        bit     ret             ; set V
ret:    rts
.endproc
