;;; ============================================================
;;; Bootstrap
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        .org $2000

;;; Copy the subsequent routine to the ProDOS QUIT routine
;;; (Main, LCBANK2) and invoke it.

.scope
        MLIEntry := MLI

        dest := $D100

        bit     LCBANK2
        bit     LCBANK2

        ldy     #0
:       lda     reloc_start,y
        sta     dest,y
        lda     reloc_start+$100,y
        sta     dest+$100,y
        dey
        bne     :-

        bit     ROMIN2

        MLI_CALL QUIT, quit_params
        DEFINE_QUIT_PARAMS quit_params

reloc_start := *

.endscope
