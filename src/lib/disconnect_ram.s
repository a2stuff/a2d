;;; ============================================================
;;; Disconnect /RAM (Slot 3, Drive 2) if present.
;;; Requires:
;;; * `saved_ram_unitnum` (byte) to be defined
;;; * `saved_ram_drvec` (word) to be defined
;;; * `saved_ram_buffer` (16 bytes) to be defined
;;; ============================================================

.proc DisconnectRAM
        ;; Find Slot 3 Drive 2 /RAM device
        ldx     DEVCNT
    DO
        lda     DEVLST,x
.ifndef PRODOS_2_5
        and     #$F3            ; per ProDOS 8 Technical Reference Manual
        cmp     #$B3            ; 5.2.2.3 - one of $BF, $BB, $B7, $B3
.else
        cmp     #$B0            ; ProDOS 2.5 uses $B0
.endif ; PRODOS_2_5
        beq     remove
        dex
    WHILE POS
        rts

        ;; Remove it, shuffle everything else down.
remove: lda     DEVLST,x
        sta     saved_ram_unitnum
        and     #UNIT_NUM_MASK
        sta     on_line_params::unit_num
        copy16  RAMSLOT, saved_ram_drvec
        copy16  NODEV, RAMSLOT

shift:  lda     DEVLST+1,x
        sta     DEVLST,x
        cpx     DEVCNT
    IF NE
        inx
        bne     shift           ; always
    END_IF
        dec     DEVCNT

        ;; Issue ON_LINE call to device after disconnecting it to
        ;; erase the VCB entry for the disconnected device, per
        ;; Technical Note: ProDOS #8: Dealing with /RAM
        ;; https://prodos8.com/docs/technote/08/
        MLI_CALL ON_LINE, on_line_params
        ;; Should fail with `ERR_DEVICE_NOT_CONNECTED` ($28)

        rts

        DEFINE_ON_LINE_PARAMS on_line_params, SELF_MODIFIED_BYTE, saved_ram_buffer

.endproc ; DisconnectRAM
