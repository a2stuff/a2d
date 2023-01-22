;;; ============================================================
;;; Save/Restore Dialog Background
;;;
;;; This reuses the "save area" ($800-$1AFF) used by MGTK for
;;; quickly restoring menu backgrounds.

.scope dialog_background

        ptr := $06

.proc Save
        copy16  #SAVE_AREA_BUFFER, addr
        lda     save_y1
        jsr     SetPtrForRow
        lda     save_y2
        sec
        sbc     save_y1
        tax
        inx

        ;; Loop over rows
loop:   lda     save_x1_byte
        sta     xbyte

        ;; Loop over columns (bytes)
col:    lda     xbyte
        lsr     a
        tay
        sta     PAGE2OFF        ; main $2000-$3FFF
        bcs     :+
        sta     PAGE2ON         ; aux $2000-$3FFF
:       lda     (ptr),y
        addr := *+1
        sta     SELF_MODIFIED
        inc16   addr
        lda     xbyte
        cmp     save_x2_byte
        bcs     :+
        inc     xbyte
        bne     col

        ;; next row
:       jsr     NextPtrForRow
        dex
        bne     loop

        ldax    addr
        rts
.endproc ; Save

;;; Restore

.proc Restore
        copy16  #SAVE_AREA_BUFFER, addr
        lda     save_y1
        jsr     SetPtrForRow
        lda     save_y2
        sec
        sbc     save_y1
        tax
        inx

        ;; Loop over rows
loop:   lda     save_x1_byte
        sta     xbyte

        ;; Loop over columns (bytes)
col:    lda     xbyte
        lsr     a
        tay
        sta     PAGE2OFF        ; main $2000-$3FFF
        bcs     :+
        sta     PAGE2ON         ; aux $2000-$3FFF

        addr := *+1
:       lda     SELF_MODIFIED
        sta     (ptr),y
        inc16   addr
        lda     xbyte
        cmp     save_x2_byte
        bcs     :+
        inc     xbyte
        bne     col             ; always

:       jsr     NextPtrForRow
        dex
        bne     loop
        rts
.endproc ; Restore

;;; Address calculations for dialog background display buffer.

;;; ============================================================
;;; Input: A=row (0...191)
;;; Output: $06 set to base address of row

.proc SetPtrForRow
        sta     row_tmp
        jmp     ComputeHBASL
.endproc ; SetPtrForRow

;;; ============================================================
;;; Increment ptr ($06) to next row
;;; Output: $06 set to base address of row

.proc NextPtrForRow
        inc     row_tmp
        lda     row_tmp
        bne     ComputeHBASL    ; always
.endproc ; NextPtrForRow

;;; ============================================================
;;; Input: A = row
;;; Output: $06 points at first byte of row
.proc ComputeHBASL
        hbasl := $06

        pha
        and     #$C7
        eor     #$08
        sta     hbasl+1
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        sta     hbasl
        pla
        and     #$38
        asl     a
        asl     a
        eor     hbasl
        asl     a
        rol     hbasl+1
        asl     a
        rol     hbasl+1
        eor     hbasl
        sta     hbasl
        rts
.endproc ; ComputeHBASL

;;; Coordinates when looping save/restore
row_tmp:
        .byte   0
xbyte:  .byte   0

.endscope ; dialog_background

;;; ============================================================
;;; Map X coord (A=lo, X=hi) to byte/bit (Y=byte, A=bit)

.proc CalcXSaveBounds
        ldy     #0
        cpx     #2              ; X >= 512 ?
        bne     :+
        ldy     #$200 / 7
        clc
        adc     #1

:       cpx     #1              ; 512 > X >= 256 ?
        bne     :+
        ldy     #$100 / 7
        clc
        adc     #4
        bcc     :+
        iny
        sbc     #7

:       cmp     #7
        bcc     :+
        sbc     #7
        iny
        bne     :-

:       rts
.endproc ; CalcXSaveBounds

;;; ============================================================
;;; Dialog bound coordinates (input to dialog_background)

save_y1:        .byte   0
save_x1_byte:   .byte   0
save_y2:        .byte   0
save_x2_byte:   .byte   0
save_x1_bit:    .byte   0
save_x2_bit:    .byte   0
