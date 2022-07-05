;;; Clear the DHR screen to black.

.proc ClearDHRToBlack
        ptr := $6
        HIRES_ADDR = $2000
        kHiresSize = $2000

        sta     CLR80STORE      ; Make sure RAMWRTON works
        sta     RAMWRTON        ; Clear aux
        jsr     clear
        sta     RAMWRTOFF       ; Clear main
        FALL_THROUGH_TO clear

clear:  copy16  #HIRES_ADDR, ptr
        lda     #0              ; clear to black
        ldx     #>kHiresSize    ; number of pages
        ldy     #0              ; pointer within page
:       sta     (ptr),y
        iny
        bne     :-
        inc     ptr+1
        dex
        bne     :-
        rts
.endproc
