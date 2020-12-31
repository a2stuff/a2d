;;; Draw a Pascal (length prefixed) string.
;;; Trashes $6-$8

.proc DrawString
        params := $6
        textptr := $6
        textlen := $8

        stax    textptr
        ldy     #0
        lda     (textptr),y
        beq     done
        sta     textlen
        inc16   textptr
        MGTK_CALL MGTK::DrawText, params
done:   rts
.endproc
