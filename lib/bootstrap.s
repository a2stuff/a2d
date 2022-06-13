;;; ============================================================
;;; Bootstrap
;;;
;;; Compiled as part of DeskTop and Selector
;;; ============================================================

        .org $2000

;;; Install QuitRoutine to the ProDOS QUIT routine
;;; (Main, LCBANK2) and invoke it.

.proc InstallAsQuit
        MLIEntry := MLI

        src     := QuitRoutine
        dst     := SELECTOR
        .assert sizeof_QuitRoutine <= $200, error, "too large"

        bit     LCBANK2
        bit     LCBANK2

        ldy     #0
:       lda     src,y
        sta     dst,y
        lda     src+$100,y
        sta     dst+$100,y
        dey
        bne     :-

        bit     ROMIN2

        MLI_CALL QUIT, quit_params
        DEFINE_QUIT_PARAMS quit_params
.endproc ; InstallAsQuit
