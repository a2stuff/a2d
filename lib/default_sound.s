;;; From ProDOS 8 Technical Reference Manual 5.4:
;;; "The standard Apple II "Air-raid" bell has been replaced with a
;;; gentler tone. Use it to give users some aural feedback that
;;; they are using a ProDOS program."

.proc DefaultBell
        .pushorg ::BELLPROC

;;; Generate a nice little tone
;;; Exits with Z-flag set (BEQ) for branching
;;; Destroys the contents of the accumulator
        lda     #32             ;duration of tone
        sta     length
bell1:  lda     #2              ;short delay...click
        jsr     Wait
        sta     SPKR
        lda     #32             ;long delay...click
        jsr     Wait
        sta     SPKR
        dec     length
        bne     bell1           ;repeat length times
        rts

;;; This is the wait routine from the Monitor ROM.
Wait:   sec
wait2:  pha
wait3:  sbc     #1
        bne     wait3
        pla
        sbc     #1
        bne     wait2
        rts

length: .byte   1               ;duration of tone

        .poporg
.endproc ; DefaultBell
