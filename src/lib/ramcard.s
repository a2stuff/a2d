;;; ============================================================
;;; Access data stashed in Main LCBANK2 by DESKTOP.SYSTEM which
;;; indicates whether or not DeskTop was copied to a RAMCard.
;;; If stashed, then both the RAMCard prefix and the original
;;; prefix can be fetched.

;;; Define `RC_AUXMEM` if caller is running with `ALTZPON` (vs. `ALTZPOFF`)
;;; Define `RC_LCBANK` if caller is running with `LCBANK1` (vs. `ROMIN2`)

;;; Return the `COPIED_TO_RAMCARD_FLAG`.
.proc GetCopiedToRAMCardFlag

.ifdef RC_AUXMEM
        sta     ALTZPOFF
.endif ; RC_AUXMEM

        bit     LCBANK2
        bit     LCBANK2
        lda     COPIED_TO_RAMCARD_FLAG

.ifdef RC_AUXMEM
        sta     ALTZPON
.endif ; RC_AUXMEM

        php
.ifdef RC_LCBANK
        bit     LCBANK1
        bit     LCBANK1
.else ; !RC_LCBANK
        bit     ROMIN2
.endif ; RC_LCBANK
        plp
        rts
.endproc ; GetCopiedToRAMCardFlag

;;; Copy the RAMCard prefix (e.g. "/RAM") to the passed buffer.
;;; Input: A,X=destination buffer
.proc CopyRAMCardPrefix
        stax    addr

.ifdef RC_AUXMEM
        sta     ALTZPOFF
.endif ; RC_AUXMEM

        bit     LCBANK2
        bit     LCBANK2

        ldx     RAMCARD_PREFIX
    DO
        lda     RAMCARD_PREFIX,x
        addr := *+1
        sta     SELF_MODIFIED,x
        dex
    WHILE POS

.ifdef RC_AUXMEM
        sta     ALTZPON
.endif ; RC_AUXMEM

.ifdef RC_LCBANK
        bit     LCBANK1
        bit     LCBANK1
.else ; !RC_LCBANK
        bit     ROMIN2
.endif ; RC_LCBANK

        rts
.endproc ; CopyRAMCardPrefix

;;; Copy the original DeskTop prefix (e.g. "/HD/A2D") to the passed buffer.
;;; Input: A,X=destination buffer
.proc CopyDeskTopOriginalPrefix
        stax    addr

.ifdef RC_AUXMEM
        sta     ALTZPOFF
.endif ; RC_AUXMEM

        bit     LCBANK2
        bit     LCBANK2

        ldx     DESKTOP_ORIG_PREFIX
    DO
        lda     DESKTOP_ORIG_PREFIX,x
        addr := *+1
        sta     SELF_MODIFIED,x
        dex
    WHILE POS

.ifdef RC_AUXMEM
        sta     ALTZPON
.endif ; RC_AUXMEM

.ifdef RC_LCBANK
        bit     LCBANK1
        bit     LCBANK1
.else ; !RC_LCBANK
        bit     ROMIN2
.endif ; RC_LCBANK

        rts
.endproc ; CopyDeskTopOriginalPrefix

;;; Get the "was it copied to RAMCard?" flag for the specified entry
;;; Input: X = `entry_num`
;;; Output: A = flag, and Z/N set appropriately
.proc GetEntryCopiedToRAMCardFlag

.ifdef RC_AUXMEM
        sta     ALTZPOFF
.endif ; RC_AUXMEM

        bit     LCBANK2
        bit     LCBANK2
        lda     ENTRY_COPIED_FLAGS,x

.ifdef RC_AUXMEM
        sta     ALTZPON
.endif ; RC_AUXMEM

        php
.ifdef RC_LCBANK
        bit     LCBANK1
        bit     LCBANK1
.else ; !RC_LCBANK
        bit     ROMIN2
.endif ; RC_LCBANK
        plp
        rts
.endproc ; GetEntryCopiedToRAMCardFlag

;;; Set the "was it copied to RAMCard?" flag for the specified entry
;;; Input: A = flag, X = `entry_num`
.proc SetEntryCopiedToRAMCardFlag

.ifdef RC_AUXMEM
        sta     ALTZPOFF
.endif ; RC_AUXMEM

        bit     LCBANK2
        bit     LCBANK2
        sta     ENTRY_COPIED_FLAGS,x

.ifdef RC_AUXMEM
        sta     ALTZPON
.endif ; RC_AUXMEM

.ifdef RC_LCBANK
        bit     LCBANK1
        bit     LCBANK1
.else ; !RC_LCBANK
        bit     ROMIN2
.endif ; RC_LCBANK

        rts
.endproc ; SetEntryCopiedToRAMCardFlag
