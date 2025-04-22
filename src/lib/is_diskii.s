;;; ============================================================
;;; Test if a device is a Disk II, following ProDOS rules.
;;; Only 16-sector Disk II devices are considered, as ProDOS
;;; does not support 13-sector Disk II devices.
;;; Inputs: unit number in A
;;; Outputs: Z=1 if Disk II, Z=0 otherwise
;;; Notes: A,X,Y trashed, $06 preserved

.proc IsDiskII
        ptr := $06

        tay
        lda     ptr             ; save $06
        pha
        lda     ptr+1
        pha
        tya

        ;; Get device driver address
        and     #UNIT_NUM_MASK
        lsr
        lsr
        lsr
        tax
        copy16  DEVADR,x, ptr

        ;; Is the driver in firmware? (i.e. is driver in $CnXX)
        lda     ptr
        and     #$F0
        cmp     #$C0
        beq     not_diskii      ; yes, so not Disk II

        ;; Check slot. Per Technical Note: ProDOS #21, Disk II
        ;; devices are never remapped. In general we can't trust
        ;; the slot bits in the unit number, due to remapping.
        ;; But if the slot *actually* contains a Disk II device,
        ;; we know it *wasn't* remapped so the slot bits were
        ;; correct. Q.E.D.

        tya
        and     #UNIT_NUM_SLOT_MASK ; 0SSS0000
        lsr                         ; 00SSS000
        lsr                         ; 000SSS00
        lsr                         ; 0000SSS0
        lsr                         ; 00000SSS
        ora     #$C0                ; $Cn
        sta     ptr+1
        lda     #0
        sta     ptr             ; ptr = $Cn00

        ;; Does this slot contain an actual ProDOS device? We
        ;; Need to test this in case a device was remapped into
        ;; this slot. Look for the signature bytes.
        ldy     #$01            ; $Cn01 = $20 ?
        lda     (ptr),y
        cmp     #$20
        bne     not_diskii
        ldy     #$03            ; $Cn03 = $00 ?
        lda     (ptr),y
        cmp     #$00
        bne     not_diskii
        ldy     #$05            ; $Cn05 = $03 ?
        lda     (ptr),y
        cmp     #$03
        bne     not_diskii

        ;; Slot contains a ProDOS device. But is it a Disk II?
        ldy     #$FF            ; $CnFF = $00 is a 16-sector Disk II
        lda     (ptr),y
        cmp     #$00
        beq     finish          ; Yes, finish with A=0

        ;; NOTE: $CnFF = $FF would signify a 13-sector Disk II, which
        ;; ProDOS does not support, so we don't probe for that.

not_diskii:
        lda     #$FF            ; nope

finish: tay
        pla                     ; restore $06
        sta     ptr+1
        pla
        sta     ptr
        tya
        rts
.endproc ; IsDiskII
