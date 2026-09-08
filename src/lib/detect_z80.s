;;; ============================================================
;;; Detect Z80
;;; Assumes $06/$07 points at $Cn00, returns carry set if found

;;; Requires a `IsIIgs` routine defined that returns C=0 if IIgs

;;; This routine gets swapped into $0FFD for execution
.assert * < $0FFD || * > $0FFD + sizeof_Z80Routine, error, "Z80 collision"

.proc Z80Routine
        target := $0FFD
        ;; .org $FFFD
        patch := *+2
        .byte   $32, $00, $e0   ; ld ($Es00),a   ; s=slot being probed turn off Z80, next PC is $0000
        .byte   $3e, $01        ; ld a,$01
        .byte   $32, $08, $00   ; ld (flag),a
        .byte   $c3, $fd, $ff   ; jp $FFFD
        flag := *
        .byte   $00             ; flag: .db $00
.endproc ; Z80Routine
        sizeof_Z80Routine = .sizeof(Z80Routine)

.proc DetectZ80
        ;; Convert $Cn to $En, update Z80 code
        lda     $07             ; $Cn
        ora     #$E0
        sta     Z80Routine::patch

        ;; Clear detection flag
        copy8   #0, Z80Routine::flag

        ;; Put routine in place
        jsr     SwapRoutine

        ;; On IIgs, slow mode
        jsr     IsIIgs
    IF CC
        lda     CYAREG          ; bit=7 = fast mode
        pha                     ; save
        and     #$7F            ; mask it off
        sta     CYAREG          ; update it
    END_IF

        ;; Try to invoke Z80
        ldy     #0
        sta     ($06),y

        ;; On IIgs, restore mode
        jsr     IsIIgs
    IF CC
        pla
        sta     CYAREG
    END_IF

        ;; Restore memory
        jsr     SwapRoutine

        ;; Flag will be set to 1 by routine if Z80 was present.
        lda     Z80Routine::flag
        ror                     ; move flag into carry
        rts

.proc SwapRoutine
        ldx     #.sizeof(Z80Routine)-1
    DO
        swap8   Z80Routine::target,x, Z80Routine,x
    WHILE dex : POS
        rts
.endproc ; SwapRoutine
.endproc ; DetectZ80

.assert * < $0FFD || * > $0FFD + sizeof_Z80Routine, error, "Z80 collision"
