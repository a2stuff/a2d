;;; ============================================================
;;; Access data stashed in Main LCBANK2 by DESKTOP.SYSTEM which
;;; indicates whether or not DeskTop was copied to a RAMCard.
;;; If stashed, then both the RAMCard prefix and the original
;;; prefix can be fetched.

;;; Return the `COPIED_TO_RAMCARD_FLAG`.
;;; Assert: Running with ALTZPON and LCBANK1.
.proc GetCopiedToRAMCardFlag
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2
        lda     COPIED_TO_RAMCARD_FLAG
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts
.endproc

;;; Copy the RAMCard prefix (e.g. "/RAM") to the passed buffer.
;;; Input: A,X=destination buffer
;;; Assert: Running with ALTZPON and LCBANK1.
.proc CopyRAMCardPrefix
        stax    @addr
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2

        ldx     RAMCARD_PREFIX
:       lda     RAMCARD_PREFIX,x
        @addr := *+1
        sta     SELF_MODIFIED,x
        dex
        bpl     :-

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

;;; Copy the original DeskTop prefix (e.g. "/HD/A2D") to the passed buffer.
;;; Input: A,X=destination buffer
;;; Assert: Running with ALTZPON and LCBANK1.
.proc CopyDeskTopOriginalPrefix
        stax    @addr
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2

        ldx     DESKTOP_ORIG_PREFIX
:       lda     DESKTOP_ORIG_PREFIX,x
        @addr := *+1
        sta     SELF_MODIFIED,x
        dex
        bpl     :-

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc
