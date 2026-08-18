;;; Draw a path (long string) in the progress dialog by without intruding
;;; into the border. If the string is too long, it is shrunk from the
;;; center with "..." inserted.
;;; Inputs: A,X = string address
;;; Trashes $06...$0C

;;; `kProgressDialogPathWidth` must be defined

.proc DrawDialogPath
PARAM_BLOCK params, $06
string  .addr
width   .word
END_PARAM_BLOCK

        stax    params::string
        stax    addr

    REPEAT
        MGTK_CALL MGTK::StringWidth, params
        cmp16   params::width, #kProgressDialogPathWidth
        BREAK_IF LT             ; already short enough

        jsr     ellipsify
    FOREVER

        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, addr
        rts

ellipsify:
        ptr := params::string

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

