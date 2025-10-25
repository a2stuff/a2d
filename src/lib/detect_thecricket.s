;;; ============================================================
;;; Detect The Cricket! attached to SSC in slot 2
;;;
;;; Inputs: $06 points at $Cs00
;;; Outputs: C=1 if detected, C=0 otherwise
;;; Assert: Interrupts disabled
;;; ============================================================

.proc DetectTheCricket
        ptr := $06

        ;; Look for SSC
        ldx     #kSigSize-1
    DO
        ldy     sig_offset,x
        lda     (ptr),y
        cmp     sig_value,x
        bne     not_found
        dex
    WHILE POS

        ;; Change ptr from $Cs00 to $C0s0
        lda     ptr+1
        pha
        and     #$F0
        sta     ptr+1
        pla                     ; A = %1100ssss
        asl                     ; A = $100ssss0
        asl                     ; A = $00ssss00
        asl                     ; A = $0ssss000
        asl                     ; A = $ssss0000
        sta     ptr

        TDREG   = $88           ; ACIA Transmit Register (write)
        RDREG   = $88           ; ACIA Receive Register (read)
        STATUS  = $89           ; ACIA Status/Reset Register
        COMMAND = $8A           ; ACIA Command Register
        CONTROL = $8B           ; ACIA Control Register

        ;; Save register states
        ldy     #COMMAND
        lda     (ptr),y
        sta     restore_command
        ldy     #CONTROL
        lda     (ptr),y
        sta     restore_control

        ;; Configure SSC
        ldy     #COMMAND
        lda     #%00001011      ; no parity/echo/interrupts, RTS low, DTR low
        sta     (ptr),y
        ldy     #CONTROL
        lda     #%10011110      ; 9600 baud, 8 data bits, 2 stop bits
        sta     (ptr),y

        ;; Send "Read Cricket ID", code 0
        lda     #0
        jsr     _SendByte
        bcs     not_found_with_restore ; timeout

        jsr     _ReadByte
        bcs     not_found_with_restore ; timeout
        cmp     #'C'|$80
        bne     not_found_with_restore

        jsr     _ReadByte
        bcs     not_found_with_restore ; timeout
        bcc     digit           ; always

:       jsr     _ReadByte
        bcs     not_found_with_restore ; timeout
        cmp     #CHAR_RETURN|$80
        beq     found
digit:  cmp     #'0'|$80        ; < '0' ?
        bcc     not_found_with_restore
        cmp     #'9'|$80+1      ; > '9' ?
        bcc     :-
        FALL_THROUGH_TO not_found_with_restore

not_found_with_restore:
        jsr     restore
        FALL_THROUGH_TO not_found
not_found:
        RETURN  C=0

found:
        sec
        FALL_THROUGH_TO restore

        ;; Restore register states; preserves C
restore:
        ldy     #CONTROL
        restore_control := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     (ptr),y
        ldy     #COMMAND
        restore_command := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     (ptr),y
        rts

        ;; Write byte in A
.proc _SendByte
        WRITE_DELAY_HI = $3 * 3 ; ($300 iterations is normal * 3.6MHz)

        tries := $100 * WRITE_DELAY_HI
        counter := $08

        pha

        copy16  #tries, counter
        ldy     #STATUS
check:  lda     (ptr),y
        and     #(1 << 4)       ; transmit register empty? (bit 4)
        bne     ready           ; yes, ready to write

        dec     counter
        bne     check
        dec     counter+1
        bne     check

        pla
        RETURN  C=1             ; failed

ready:  pla
        ldy     #TDREG
        sta     (ptr),y         ; actually write to the register
        RETURN  C=0
.endproc ; _SendByte

        ;; Read byte into A, or carry set if timed out
.proc _ReadByte
        READ_DELAY_HI = $3 * 3 ; ($300 iterations is normal * 3.6MHz)

        tries := $100 * READ_DELAY_HI
        counter := $08

        copy16  #tries, counter

        ldy     #STATUS
check:  lda     (ptr),y         ; did we get it?
        and     #(1 << 3)       ; receive register full? (bit 3)
        bne     ready           ; yes, we read the value

        dec     counter
        bne     check
        dec     counter+1
        bne     check

        RETURN  C=1             ; failed

ready:  ldy     #RDREG
        lda     (ptr),y         ; actually read the register
        RETURN  C=0
.endproc ; _ReadByte

;;; SSC Signature
sig_offset:     .byte   $05, $07, $0B, $0C
sig_value:      .byte   $38, $18, $01, $31
        kSigSize = * - sig_value
.endproc ; DetectTheCricket
