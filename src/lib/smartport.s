;;; NOTE: Can be called with ALTZPON or OFF, and LCBANK1 or ROMIN2;
;;; the initial banking state will be preserved.

;;; Internal ProDOS tables are used to handle mirrored drives. The
;;; locations vary between ProDOS versions. For details, see:
;;; https://github.com/a2stuff/a2d/issues/685

;;; TODO: Handle additional versions, either by adding more
;;; logic or building mirroring tables ourselves on startup.

DevAdrP24       = $FCE6
SPUnitP24       = $D6EF         ; absolute
SPVecLP24       = $FD51         ; DevAdr + 107
SPVecHP24       = $FD60         ; SPVecL + 15 (constant offset)

DevAdrP20x      = $FD08
SPUnitP20x      = $D6EF         ; absolute
SPVecLP20x      = $FD6E         ; DevAdr + 102
SPVecHP20x      = $FD7D         ; SPVecL + 15 (constant offset)

.assert SPUnitP20x = SPUnitP24, error, "mismatch"
.assert (SPVecHP20x - SPVecLP20x) = (SPVecHP24 - SPVecLP24), error, "mismatch"

;;; ============================================================
;;; Look up SmartPort dispatch address.
;;; Input: A = unit number
;;; Output: C=0 if SP, A,X=dispatch address, Y = SP unit num
;;;         C=1 if not SP
;;; Uses $10...$12 on both zero pages

.proc FindSmartportDispatchAddress

.struct
        .org $10
dispatch        .word
mirrored_slot   .byte
.endstruct

        sta     unit_number     ; DSSSnnnn

        ;; Get device driver address
        jsr     DeviceDriverAddress

        bvs     mirrored        ; mirrored by ProDOS 2.x

        bne     fail            ; RAM-based driver

        ;; --------------------------------------------------
        ;; Not mirrored, or mirrored by ProDOS 1.x

        ;; Find actual SmartPort dispatch address
        lda     #0
        sta     dispatch        ; $Cn00
        stx     dispatch+1
        ldy     #$07
        lda     (dispatch),y    ; SmartPort signature byte ($Cn07)
        bne     fail            ; nope (exit with Z=0 on failure)

;;; Per Technical Note: ProDOS #21: Mirrored Devices and SmartPort
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/pdos/tn.pdos.20.html
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

        ;; Locate SmartPort entry point: $Cn00 + ($CnFF) + 3
        ldy     #$FF
        lda     (dispatch),y
        clc
        adc     #3
        sta     dispatch        ; low byte

        ;; Figure out SmartPort control unit number in Y
        ldy     #1              ; start with unit 1
        bit     unit_number     ; high bit is D
    IF NS
        iny                     ; Y = 1 or 2 (for Drive 1 or 2)
    END_IF

        ;; Was it mirrored? (ProDOS 1.x-only behavior)
        unit_number := *+1
        lda     #SELF_MODIFIED_BYTE
        and     #%01110000      ; 0SSSnnnn
        lsr
        lsr
        lsr
        lsr
        sta     mirrored_slot   ; 00000SSS

        lda     dispatch+1      ; $Cn
        and     #%00001111      ; $0n
    IF A <> mirrored_slot       ; equal = not mirrored
        iny                     ; now Y = 3 or 4
        iny
    END_IF

        RETURN  AX=dispatch, C=0 ; Y = SmartPort unit number

fail:   RETURN  C=1

        ;; --------------------------------------------------
        ;; Mirrored SmartPort device with a known handler.
        ;; Look at ProDOS's internal tables to determine.
mirrored:
        ;; Save and change banking
        bit     RDALTZP
        sta     ALTZPOFF        ; preserve state on main stack
        php

        bit     RDLCRAM
        php

        bit     LCBANK1
        bit     LCBANK1

        ;; Point `dispatch` at SPVecL table
        sta     dispatch
        tya                     ; Y = offset from start of driver
        clc
        adc     dispatch
        sta     dispatch
        bcc     :+
        inx
:       stx     dispatch+1

        ;; Calculate index into table (0...15)
        lda     unit_number
        lsr
        lsr
        lsr
        lsr
        tay                     ; Y = offset into tables

        lda     (dispatch),y
        pha                     ; A = sp vec lo

        lda     SPUnitP20x,y
        pha                     ; A = sp unit

        tya
        clc
        adc     #(SPVecHP20x - SPVecLP20x)
        tay

        lda     (dispatch),y
        tax                     ; X = sp vec hi

        pla
        tay                     ; Y = sp unit

        pla                     ; A = sp vec lo


        ;; Restore banking
        plp
    IF NC
        bit     ROMIN2          ; restore ROMIN2
    END_IF

        plp
    IF NS
        sta     ALTZPON         ; restore ALTZPON
    END_IF

        ;; Exit
        RETURN  C=0


.endproc ; FindSmartportDispatchAddress

;;; ============================================================
;;; Get driver address for unit number
;;; Input: A = unit number (no need to mask it)
;;; Output: A,X=driver address
;;;         V=1 if a mirrored SmartPort device, and Y is table offset
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
        ldy     #(SPVecLP24 - DevAdrP24)
        cmp     #<DevAdrP24
    IF EQ
        cpx     #>DevAdrP24
        beq     mirrored
    END_IF

        ldy     #(SPVecLP20x - DevAdrP20x)
        cmp     #<DevAdrP20x
    IF EQ
        cpx     #>DevAdrP20x
        beq     mirrored
    END_IF

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
.endproc ; DeviceDriverAddress
