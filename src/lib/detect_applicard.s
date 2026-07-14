;;; ============================================================
;;; Detect PCPI Appli-Card (Z80 coprocessor)
;;;
;;; The Appli-Card has no $Cn00 firmware ROM; its only 6502-visible
;;; surface is a pair of data latches with handshake flags in DEVSEL
;;; space:
;;;   $C0(8+s)1  W: latch a byte for the Z80   R: read the latch back
;;;   $C0(8+s)5  R/W: reset the Z80 (clears latches and flags)
;;; PCPI's own driver detects the card by writing $C0(8+s)1 and
;;; reading the value back; the readback works whether or not the Z80
;;; has consumed the byte. Two complementary patterns rule out
;;; floating-bus echoes, and the reset afterwards keeps the card's
;;; boot ROM from being left mid-protocol. The Franklin ACE 80 and
;;; modern recreations (e.g. GG Labs GZ/80S) use the same design.
;;;
;;; Inputs: $06 points at $Cs00
;;; Outputs: C=1 if detected, C=0 otherwise
;;; Assert: Interrupts disabled
;;; ============================================================

.proc DetectApplicard
        ptr := $06

        txa
        pha                     ; preserve caller's X

        lda     ptr+1           ; $Cs00 high byte
        and     #$07            ; slot
        asl
        asl
        asl
        asl                     ; X offset = slot * 16
        tax

        lda     #$A5
        sta     $C081,X         ; latch a byte for the Z80
        lda     $C081,X         ; and read the latch back
        cmp     #$A5
        bne     fail

        lda     #$5A            ; complementary pattern, in case the
        sta     $C081,X         ; first readback was a floating-bus echo
        lda     $C081,X
        cmp     #$5A
        bne     fail

        lda     $C085,X         ; reset the Z80 to a clean boot state

        pla
        tax
        RETURN  C=1

fail:   pla
        tax
        RETURN  C=0
.endproc ; DetectApplicard
