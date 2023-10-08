;;; Determine if mouse moved (returns w/ carry set if moved)
;;; Used in dialogs to possibly change cursor

.proc CheckMouseMoved
        ldx     #.sizeof(MGTK::Point)-1
:       lda     event_params::coords,x
        cmp     coords,x
        bne     diff
        dex
        bpl     :-
        clc
        rts

diff:   COPY_STRUCT MGTK::Point, event_params::coords, coords
        sec
        rts

        DEFINE_POINT coords, 0, 0
.endproc ; CheckMouseMoved

