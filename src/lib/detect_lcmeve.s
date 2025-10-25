;;; ============================================================
;;; Detect Le Chat Mauve Eve card
;;; Output: non-zero if LCM Eve detected
;;; Assert: ROM is banked in

.proc DetectLeChatMauveEve
        ;; Based on IDENTIFICATION from the LCM Eve manual, pages 92-94

        kSentinelValue = $EE
        kModeValue = $0F
        .assert kSentinelValue <> kModeValue, error, "Values must differ"

        ;; Skip on IIc/IIc+
        lda     ZIDBYTE
        beq     done

        ;; Skip on IIgs
        CALL    IDROUTINE, C=1
        bcc     done

        ;; Detection routine
        php
        sei
        sta     SET80STORE      ; let PAGE2 control banking
        sta     PAGE2ON         ; access PAGE1X

        ldx     $400            ; save PAGE1X value in X
        lda     #kSentinelValue
        sta     $400            ; write to PAGE1X

        lda     #kModeValue
        sta     TEXT16_ON       ; TEXT16 on
        sta     PAGE2OFF        ; access PAGE1
        ldy     $400            ; save PAGE1 value in Y

        sta     $400            ; write to PAGE1
        sta     TEXT16_OFF      ; TEXT16 off
        sta     PAGE2ON         ; access PAGE1X

        lda     #kSentinelValue
        eor     $400            ; did the value change?
        sta     result          ; if non-zero, Eve was shadowing

        stx     $400            ; restore PAGE1X from X
        sta     PAGE2OFF        ; access PAGE1
        sty     $400            ; restore PAGE1 from Y

        sta     CLR80STORE      ; restore PAGE2 meaning
        plp

        result := *+1
done:   lda     #0              ; self-modified (but not always)
        rts
.endproc ; DetectLeChatMauveEve
