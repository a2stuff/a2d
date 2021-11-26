;;; ============================================================
;;; Disk II - Format
;;; Inputs: A = unit_number

.proc FormatDiskII
        .assert .lobyte(*) = 0, error, "Must be page aligned"

.macro exit_with_result arg
        lda     #arg
        jmp     Exit
.endmacro

        php
        sei
        jsr     L083A
        plp
        cmp     #$00
        bne     L080C
        clc
        rts

L080C:  cmp     #$02
        bne     L0815
        lda     #ERR_WRITE_PROTECTED
        jmp     L0821

L0815:  cmp     #$01
        bne     L081E
        lda     #$27
        jmp     L0821

L081E:  clc
        adc     #$30
L0821:  sec
        rts

L0823:  asl     a
        asl     current_track
        sta     seltrack_track
        txa
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     seltrack_track
        jsr     SelectTrack
        lsr     current_track
        rts

L083A:  tax                     ; A=DSSSxxxx
        and     #$70            ; Slot
        sta     L0C23
        txa
        ldx     L0C23
        rol     a               ; Drive
        lda     #$00
        rol     a
        bne     :+
        lda     SELECT,x        ; Select drive 1 or 2
        jmp     L0853

:       lda     LCBANK1,x
L0853:  lda     ENABLE,x        ; Turn drive on
        lda     #$D7
        sta     $DA
        lda     #$50
        sta     current_track
        lda     #$00
        jsr     L0823
L0864:  lda     $DA
        beq     L086E
        jsr     L0B3A
        jmp     L0864

L086E:  lda     #$01
        sta     $D3
        lda     #$AA
        sta     $D0
        lda     L0C20
        clc
        adc     #$02
        sta     $D4
        lda     #$00
        sta     $D1
L0882:  lda     $D1
        ldx     L0C23
        jsr     L0823
        ldx     L0C23
        lda     TESTWP,x        ; Check write protect
        lda     WPRES,x
        tay
        lda     RDMODE,x        ; Activate read mode
        lda     XMIT,x
        tya
        bpl     :+              ; WP mode?
        exit_with_result 2      ; Yes

:       jsr     L0B63
        bcc     L08B5
        lda     #$01
        ldy     $D4
        cpy     L0C1F
        bcs     L08B2
        lda     #4
L08B2:  jmp     Exit

L08B5:  ldy     $D4
        cpy     L0C1F
        bcs     L08C1
        exit_with_result 4

L08C1:  cpy     L0C20
        bcc     L08CB
        exit_with_result 3

L08CB:  lda     L0C22
        sta     L0C25
L08D1:  dec     L0C25
        bne     L08DB
        exit_with_result 1

L08DB:  ldx     L0C23
        jsr     L096A
        bcs     L08D1
        lda     $D8
        bne     L08D1
        ldx     L0C23
        jsr     L0907
        bcs     L08D1
        inc     $D1
        lda     $D1
        cmp     #$23
        bcc     L0882

        lda     #0
        ;; fall through

.proc Exit
        pha
        ldx     L0C23
        lda     DISABLE,x       ; Turn drive off
        lda     #0
        jsr     L0823
        pla
        rts
.endproc

;;; ============================================================

.proc L0907
        ldy     #$20
L0909:  dey
        beq     return_with_carry_set
:       lda     XMIT,x
        bpl     :-

L0911:  eor     #$D5
        bne     L0909
        nop
:       lda     XMIT,x
        bpl     :-
        cmp     #$AA
        bne     L0911
        ldy     #$56
:       lda     XMIT,x
        bpl     :-
        cmp     #$AD
        bne     L0911

        lda     #$00
L092C:  dey
        sty     $D5
:       lda     XMIT,x
        bpl     :-
        cmp     #$96
        bne     return_with_carry_set
        ldy     $D5
        bne     L092C

L093C:  sty     $D5
:       lda     XMIT,x
        bpl     :-
        cmp     #$96
        bne     return_with_carry_set
        ldy     $D5
        iny
        bne     L093C

:       lda     XMIT,x
        bpl     :-
        cmp     #$96
        bne     return_with_carry_set
:       lda     XMIT,x
        bpl     :-
        cmp     #$DE
        bne     return_with_carry_set
        nop
:       lda     XMIT,x
        bpl     :-
        cmp     #$AA
        beq     return_with_carry_clear
.endproc
return_with_carry_set:
        sec
        rts

.proc L096A
        ldy     #$FC
        sty     $DC
L096E:  iny
        bne     :+
        inc     $DC
        beq     return_with_carry_set
:       lda     XMIT,x
        bpl     :-

L097A:  cmp     #$D5
        bne     L096E
        nop
:       lda     XMIT,x
        bpl     :-
        cmp     #$AA
        bne     L097A
        ldy     #$03
:       lda     XMIT,x
        bpl     :-
        cmp     #$96
        bne     L097A

        lda     #$00
L0995:  sta     $DB
:       lda     XMIT,x
        bpl     :-
        rol     a
        sta     $DD
:       lda     XMIT,x
        bpl     :-
        and     $DD
        sta     $D7,y
        eor     $DB
        dey
        bpl     L0995

        tay
        bne     return_with_carry_set
:       lda     XMIT,x
        bpl     :-
        cmp     #$DE
        bne     return_with_carry_set
        nop
:       lda     XMIT,x
        bpl     :-
        cmp     #$AA
        bne     return_with_carry_set
.endproc
return_with_carry_clear:
        clc
        rts

;;; ============================================================
;;; Move head to track - A = track, X = slot * 16

.proc SelectTrack
        stx     seltrack_slot
        sta     seltrack_track
        cmp     current_track
        beq     done
        lda     #$00
        sta     L0C38
L09D6:  lda     current_track
        sta     L0C39
        sec
        sbc     seltrack_track
        beq     L0A19
        bcs     L09EB
        eor     #$FF
        inc     current_track
        bcc     L09F0
L09EB:  adc     #$FE
        dec     current_track
L09F0:  cmp     L0C38
        bcc     L09F8
        lda     L0C38
L09F8:  cmp     #$0C
        bcs     L09FD
        tay
L09FD:  sec
        jsr     L0A1D
        lda     phase_on_table,y
        jsr     L0B3A
        lda     L0C39
        clc
        jsr     motor
        lda     phase_off_table,y
        jsr     L0B3A
        inc     L0C38
        bne     L09D6
L0A19:  jsr     L0B3A
        clc
L0A1D:  lda     current_track

motor:  and     #$03            ; PHASE0 + 2 * phase
        rol     a
        ora     seltrack_slot
        tax
        lda     PHASE0,x
        ldx     seltrack_slot

done:   rts
.endproc

;;; ============================================================

.proc FormatSector
        jsr     rts2
        lda     TESTWP,x        ; Check write protect
        lda     WPRES,x

        lda     #$FF            ; Self-sync data
        sta     WRMODE,x        ; Turn on write mode
        cmp     XMIT,x          ; Start sending bits to disk
        pha                     ; 32 cycles...
        pla
        nop
        ldy     #4

sync:   pha
        pla
        jsr     Write2
        dey
        bne     sync

        ;; Address marks
        lda     #$D5
        jsr     Write
        lda     #$AA
        jsr     Write
        lda     #$AD
        jsr     Write
        ldy     #$56
        nop
        nop
        nop
        bne     :+

        ;; Data
loop:   jsr     rts2
:       nop
        nop
        lda     #$96
        sta     DATA,x
        cmp     XMIT,x
        dey
        bne     loop

        ;; Checksum
        bit     $00
        nop
check:  jsr     rts2
        lda     #$96
        sta     DATA,x
        cmp     XMIT,x
        lda     #$96
        nop
        iny
        bne     check

        ;; Slip marks
        jsr     Write
        lda     #$DE
        jsr     Write
        lda     #$AA
        jsr     Write
        lda     #$EB
        jsr     Write
        lda     #$FF
        jsr     Write
        lda     RDMODE,x        ; Turn off write mode
        lda     XMIT,x
        rts

        ;; Write with appropriate cycle counts
Write:  nop
Write2: pha
        pla
        sta     DATA,x
        cmp     XMIT,x
        rts
.endproc

;;; ============================================================

.proc L0AAE
        sec
        lda     TESTWP,x        ; Check write protect
        lda     WPRES,x
        bmi     L0B15
        lda     #$FF
        sta     WRMODE,x        ; Turn on write mode
        cmp     XMIT,x          ; Start sending bits to disk
        pha                     ; 32 cycles...
        pla
loop:   jsr     rts1
        jsr     rts1
        sta     DATA,x
        cmp     XMIT,x
        nop
        dey
        bne     loop
        lda     #$D5
        jsr     L0B2D
        lda     #$AA
        jsr     L0B2D
        lda     #$96
        jsr     L0B2D
        lda     $D3
        jsr     L0B1C
        lda     $D1
        jsr     L0B1C
        lda     $D2
        jsr     L0B1C
        lda     $D3
        eor     $D1
        eor     $D2
        pha
        lsr     a
        ora     $D0
        sta     DATA,x
        lda     XMIT,x
        pla
        ora     #$AA
        jsr     L0B2C
        lda     #$DE
        jsr     L0B2D
        lda     #$AA
        jsr     L0B2D
        lda     #$EB
        jsr     L0B2D
        clc
L0B15:  lda     RDMODE,x        ; Turn off write mode
        lda     XMIT,x
rts1:   rts
.endproc

;;; ============================================================

L0B1C:  pha
        lsr     a
        ora     $D0
        sta     DATA,x
        cmp     XMIT,x
        pla
        nop
        nop
        nop
        ora     #$AA
L0B2C:  nop
L0B2D:  nop
        pha
        pla
        sta     DATA,x
        cmp     XMIT,x
        rts

        .byte   0
        .byte   0
        .byte   0

.proc L0B3A
start:  ldx     #$11
:       dex
        bne     :-
        inc16   $D9
        sec
        sbc     #1
        bne     start
        rts
.endproc

;;; Timing (100-usecs)
phase_on_table:  .byte   $01, $30, $28, $24, $20, $1E, $1D, $1C, $1C, $1C, $1C, $1C
phase_off_table: .byte   $70, $2C, $26, $22, $1F, $1E, $1D, $1C, $1C, $1C, $1C, $1C

L0B63:  lda     L0C21
        sta     $D6
L0B68:  ldy     #$80
        lda     #$00
        sta     $D2
        jmp     L0B73

L0B71:  ldy     $D4
L0B73:  ldx     L0C23
        jsr     L0AAE
        bcc     L0B7E
        jmp     rts2

L0B7E:  ldx     L0C23
        jsr     FormatSector
        inc     $D2
        lda     $D2
        cmp     #$10
        bcc     L0B71
        ldy     #$0F
        sty     $D2
        lda     L0C22
        sta     L0C25
L0B96:  sta     L0C26,y
        dey
        bpl     L0B96
        lda     $D4
        sec
        sbc     #$05
        tay
L0BA2:  jsr     rts2
        jsr     rts2
        pha
        pla
        nop
        nop
        dey
        bne     L0BA2
        ldx     L0C23
        jsr     L096A
        bcs     L0BF3
        lda     $D8
        beq     L0BCE
        dec     $D4
        lda     $D4
        cmp     L0C1F
        bcs     L0BF3
        sec
        rts

L0BC6:  ldx     L0C23
        jsr     L096A
        bcs     L0BE8
L0BCE:  ldx     L0C23
        jsr     L0907
        bcs     L0BE8
        ldy     $D8
        lda     L0C26,y
        bmi     L0BE8
        lda     #$FF
        sta     L0C26,y
        dec     $D2
        bpl     L0BC6
        clc
        rts

L0BE8:  dec     L0C25
        bne     L0BC6
        dec     $D6
        bne     L0BF3
        sec
        rts

L0BF3:  lda     L0C22
        asl     a
        sta     L0C25
L0BFA:  ldx     L0C23
        jsr     L096A
        bcs     L0C08
        lda     $D8
        cmp     #$0F
        beq     L0C0F
L0C08:  dec     L0C25
        bne     L0BFA
        sec
rts2:   rts

L0C0F:  ldx     #$D6
L0C11:  jsr     rts2
        jsr     rts2
        bit     $00
        dex
        bne     L0C11
        jmp     L0B68

L0C1F:  .byte   $0E
L0C20:  .byte   $1B
L0C21:  .byte   $03
L0C22:  .byte   $10
L0C23:  .byte   0

current_track:
        .byte   0

L0C25:  .byte   0
L0C26:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

seltrack_track:
        .byte   0
seltrack_slot:
        .byte   0

L0C38:  .byte   0
L0C39:  .byte   0

.delmacro exit_with_result

.endproc ; FormatDiskII
