;;; Draw a path (long string) in the progress dialog by without intruding
;;; into the border. If the string is too long, it is shrunk from the
;;; center with "..." inserted.
;;; Inputs: A,X = string address
;;; Trashes $06...$0C

;;; `kProgressDialogPathWidth` must be defined

.proc DrawDialogPath
        ptr := $6
        stax    ptr

    REPEAT
        jsr     measure
        BREAK_IF LT             ; already short enough

        jsr     ellipsify
    FOREVER

        ;; Draw
        MGTK_CALL MGTK::DrawText, txt
        rts

        ;; Measure
measure:
        txt := $8
        len := $A
        result := $B

        ldy     #0
        lda     (ptr),y
        sta     len
        ldxy    ptr
        inxy
        stxy    txt
        MGTK_CALL MGTK::TextWidth, txt
        cmp16   result, #kProgressDialogPathWidth
        rts

ellipsify:
        ldy     #0
        lda     (ptr),y         ; length
        sta     length
        pha
        sec                     ; shrink length by one
        sbc     #1
        sta     (ptr),y
        pla
        lsr                     ; /= 2

        pha                     ; A = length/2

        tay
    DO
        iny                     ; shift chars from midpoint to
        lda     (ptr),y         ; end of string down by one
        dey
        sta     (ptr),y
        iny
        length := *+1
        cpy     #SELF_MODIFIED_BYTE
    WHILE NE

        pla                     ; A = length/2

        tay                     ; overwrite midpoint with
        lda     #'.'            ; "..."
        sta     (ptr),y
        iny
        sta     (ptr),y
        iny
        sta     (ptr),y
        rts
.endproc ; DrawDialogPath

