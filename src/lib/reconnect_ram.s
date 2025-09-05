;;; ============================================================
;;; Reconnect and format /RAM (Slot 3, Drive 2) if it was disconnected.
;;; Assert: ROM is banked in, ALTZP is OFF
;;; Assumes hires screen (main and aux) are safe to destroy.
;;; ============================================================

.proc ReconnectRAM
        ;; Did we detach S3D2 /RAM?
        lda     saved_ram_unitnum
    IF_NOT_ZERO
        inc     DEVCNT
        ldx     DEVCNT
        sta     DEVLST,x

        ;; Restore driver in table
        copy16  saved_ram_drvec, RAMSLOT

        ;; /RAM FORMAT call; see ProDOS 8 TRM 5.2.2.4 for details
        copy8   #$B0, DRIVER_UNIT_NUMBER
        copy8   #DRIVER_COMMAND_FORMAT, DRIVER_COMMAND
        copy16  #$2000, DRIVER_BUFFER
        bit     LCBANK1
        bit     LCBANK1
        jsr     driver
        bit     ROMIN2
    END_IF
        rts

driver: jmp     (RAMSLOT)
.endproc ; ReconnectRAM

saved_ram_unitnum:
        .byte   0
saved_ram_drvec:
        .addr   0
