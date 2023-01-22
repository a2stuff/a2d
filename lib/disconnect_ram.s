;;; ============================================================
;;; Disconnect /RAM (Slot 3, Drive 2) if present.
;;; Requires:
;;; * `saved_ram_unitnum` (byte) to be defined
;;; * `saved_ram_drvec` (word) to be defined
;;; ============================================================

.proc DisconnectRAM
        ;; Find Slot 3 Drive 2 /RAM device
        ldx     DEVCNT
:       lda     DEVLST,x
.ifndef PRODOS_2_5
        and     #$F3            ; per ProDOS 8 Technical Reference Manual
        cmp     #$B3            ; 5.2.2.3 - one of $BF, $BB, $B7, $B3
.else
        cmp     #$B0            ; ProDOS 2.5 uses $B0
.endif ; PRODOS_2_5
        beq     remove
        dex
        bpl     :-
        rts

        ;; Remove it, shuffle everything else down.
remove: copy    DEVLST,x, saved_ram_unitnum
        copy16  RAMSLOT, saved_ram_drvec
        copy16  NODEV, RAMSLOT

shift:  lda     DEVLST+1,x
        sta     DEVLST,x
        cpx     DEVCNT
        beq     :+
        inx
        bne     shift           ; always

:       dec     DEVCNT

        ;; TODO: Issue ON_LINE call to device after disconnecting it
        ;; to erases the VCB entry for the disconnected device, per
        ;; Technical Note: ProDOS #8: Dealing with /RAM
        ;; http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.08.html

        rts
.endproc ; DisconnectRAM
