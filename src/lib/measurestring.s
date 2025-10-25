;;; ============================================================
;;; Measure text, pascal string address in A,X; result in A,X

.proc MeasureString
        ptr := $6
        len := $8
        result := $9

        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     len
        inc16   ptr
        MGTK_CALL MGTK::TextWidth, ptr
        RETURN  AX=result
.endproc ; MeasureString
