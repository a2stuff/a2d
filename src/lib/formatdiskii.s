;;; ============================================================
;;; Disk II - Format
;;; Inputs: A = unit_number

;;; This is byte-identical to Apple's "ProDOS DISK ][ Formatter Device
;;; Driver", which is documented as:

;;; * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;;; * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;;; * *                                                 * *
;;; * * M U S T   B E   O N   P A G E   B O U N D A R Y * *
;;; * *                                                 * *
;;; * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;;; * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;;; *                                                     *
;;; *  ProDOS DISK ][ Formatter Device Driver             *
;;; *                                                     *
;;; *  Copyright Apple Computer, Inc., 1982-1984          *
;;; *                                                     *
;;; *  Enter with ProDOS device number in A-register:     *
;;; *         Zero    = bits 0, 1, 2, 3                   *
;;; *         Slot No.= bits 4, 5, 6                      *
;;; *         Drive 1 = bit 7 off                         *
;;; *         Drive 2 = bit 7 on                          *
;;; *                                                     *
;;; *  Error codes returned in A-register:                *
;;; *         $00 : Good completion                       *
;;; *         $27 : Unable to format                      *
;;; *         $2B : Write-Protected                       *
;;; *         $33 : Drive too SLOW                        *
;;; *         $34 : Drive too FAST                        *
;;; *         NOTE: Carry flag is set if error occured.   *
;;; *                                                     *
;;; *  Uses zero page locations $D0 thru $DD              *
;;; *                                                     *
;;; * - - - - - - - - - - - - - - - - - - - - - - - - - - *
;;; * Modified 15 December 1983 to disable interrupts     *
;;; * Modified 20 December 1983 to increase tolerance     *
;;; *    of disk speed check                              *
;;; * Modified 30 March 1983 to increase tolerance of     *
;;; *    disk speed                                       *
;;; * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;;; There is an annotated disassembly by @tomcw at:
;;;
;;; https://github.com/AppleWin/AppleWin/blob/master/docs/DiskII%20Formatter/Format1.1.1-annotated.txt
;;;
;;; Many of the symbols below are derived from that work.

.proc FormatDiskII
        .assert .lobyte(*) = 0, error, "Must be page aligned"

        php
        sei
        jsr     FormatDisk
        plp
        cmp     #0
        bne     :+
        clc
        rts
:
        ;; Map result to MLI error code
        cmp     #2
        bne     :+
        lda     #ERR_WRITE_PROTECTED
        jmp     L0821
:
        cmp     #1
        bne     :+
        lda     #ERR_IO_ERROR
        jmp     L0821
:
        clc
        adc     #$30            ; 3/4 to $33/$34 (drive too slow/fast)
L0821:  sec
        rts

;;; ============================================================

SeekTrack:
        asl     a
        asl     HalfTrack
        sta     seltrack_track
        txa
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     seltrack_track
        jsr     SeekHalfTrack
        lsr     HalfTrack
        rts

;;; ============================================================

FormatDisk:
        tax                     ; A=DSSSxxxx
        and     #$70            ; Slot
        sta     Slotx16
        txa
        ldx     Slotx16
        rol     a               ; Drive
        lda     #$00
        rol     a
        bne     :+
        lda     SELECT1,x       ; Select drive 1 or 2
        jmp     L0853

:       lda     SELECT2,x
L0853:  lda     ENABLE,x        ; Turn drive on
        lda     #$D7
        sta     $DA
        lda     #$50
        sta     HalfTrack
        lda     #$00
        jsr     SeekTrack
:
        lda     $DA
        beq     :+
        jsr     WaitA
        jmp     :-
:
        lda     #$01
        sta     $D3
        lda     #$AA
        sta     $D0
        lda     kMaxGap3
        clc
        adc     #$02
        sta     $D4
        lda     #$00
        sta     $D1
WriteNextTrack:
        lda     $D1
        ldx     Slotx16
        jsr     SeekTrack
        ldx     Slotx16
        lda     TESTWP,x        ; Check write protect
        lda     WPRES,x
        tay
        lda     RDMODE,x        ; Activate read mode
        lda     XMIT,x
        tya
        bpl     WriteTrack      ; WP mode?
        lda     #2              ; Yes, error
        jmp     Done

WriteTrack:
        jsr     WriteAndVerifyTrack
        bcc     CheckGap3Count
        lda     #$01
        ldy     $D4
        cpy     kMinGap3
        bcs     :+
        lda     #4              ; error (too fast)
:
        jmp     Done

CheckGap3Count:
        ldy     $D4
        cpy     kMinGap3
        bcs     :+
        lda     #4              ; error (too fast)
        jmp     Done
:
        cpy     kMaxGap3
        bcc     FindSector00Init
        lda     #3              ; error (too slow)
        jmp     Done

FindSector00Init:
        lda     k10
        sta     RetryCount
FindSector00Cont:
        dec     RetryCount
        bne     :+
        lda     #1              ; error (generic)
        jmp     Done
:
        ldx     Slotx16
        jsr     ReadAddressField
        bcs     FindSector00Cont
        lda     $D8
        bne     FindSector00Cont

VerifySector:
        ldx     Slotx16
        jsr     ReadSectorData
        bcs     FindSector00Cont

NextTrack:
        inc     $D1
        lda     $D1
        cmp     #$23
        bcc     WriteNextTrack

        lda     #0              ; success

Done:
        pha
        ldx     Slotx16
        lda     DISABLE,x       ; Turn drive off
        lda     #0
        jsr     SeekTrack
        pla
        rts

;;; ============================================================

;;; Verify sector

ReadSectorData:
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
        FALL_THROUGH_TO return_with_carry_set

return_with_carry_set:
        sec
        rts

;;; ============================================================

ReadAddressField:
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
        FALL_THROUGH_TO return_with_carry_clear

return_with_carry_clear:
        clc
        rts

;;; ============================================================
;;; Move head to track - A = track, X = slot * 16

SeekHalfTrack:
        stx     seltrack_slot
        sta     seltrack_track
        cmp     HalfTrack
        beq     done
        lda     #$00
        sta     L0C38
L09D6:  lda     HalfTrack
        sta     L0C39
        sec
        sbc     seltrack_track
        beq     L0A19
        bcs     L09EB
        eor     #$FF
        inc     HalfTrack
        bcc     L09F0
L09EB:  adc     #$FE
        dec     HalfTrack
L09F0:  cmp     L0C38
        bcc     :+
        lda     L0C38
:       cmp     #$0C
        bcs     :+
        tay
:       sec
        jsr     L0A1D
        lda     phase_on_table,y
        jsr     WaitA
        lda     L0C39
        clc
        jsr     motor
        lda     phase_off_table,y
        jsr     WaitA
        inc     L0C38
        bne     L09D6
L0A19:  jsr     WaitA
        clc
L0A1D:  lda     HalfTrack

motor:  and     #$03            ; PHASE0 + 2 * phase
        rol     a
        ora     seltrack_slot
        tax
        lda     PHASE0,x
        ldx     seltrack_slot

done:   rts

;;; ============================================================

WriteGap2AndData:
        jsr     RTS_
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
        jsr     WriteNibble1b
        dey
        bne     sync

        ;; Address marks
        lda     #$D5
        jsr     WriteNibble1a
        lda     #$AA
        jsr     WriteNibble1a
        lda     #$AD
        jsr     WriteNibble1a
        ldy     #$56
        nop
        nop
        nop
        bne     :+

        ;; Data
loop:   jsr     RTS_
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
check:  jsr     RTS_
        lda     #$96
        sta     DATA,x
        cmp     XMIT,x
        lda     #$96
        nop
        iny
        bne     check

        ;; Slip marks
        jsr     WriteNibble1a
        lda     #$DE
        jsr     WriteNibble1a
        lda     #$AA
        jsr     WriteNibble1a
        lda     #$EB
        jsr     WriteNibble1a
        lda     #$FF
        jsr     WriteNibble1a
        lda     RDMODE,x        ; Turn off write mode
        lda     XMIT,x
        rts

        ;; Write with appropriate cycle counts
WriteNibble1a:
        nop
WriteNibble1b:
        pha
        pla
        sta     DATA,x
        cmp     XMIT,x
        rts

;;; ============================================================

CheckWriteProt:
        sec
        lda     TESTWP,x        ; Check write protect
        lda     WPRES,x
        bmi     L0B15

WriteGap0Or3AndAddress:
        lda     #$FF
        sta     WRMODE,x        ; Turn on write mode
        cmp     XMIT,x          ; Start sending bits to disk
        pha                     ; 32 cycles...
        pla
:       jsr     rts1
        jsr     rts1
        sta     DATA,x
        cmp     XMIT,x
        nop
        dey
        bne     :-
        lda     #$D5
        jsr     WriteNibble2b
        lda     #$AA
        jsr     WriteNibble2b
        lda     #$96
        jsr     WriteNibble2b
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
        jsr     WriteNibble2a
        lda     #$DE
        jsr     WriteNibble2b
        lda     #$AA
        jsr     WriteNibble2b
        lda     #$EB
        jsr     WriteNibble2b
        clc
L0B15:  lda     RDMODE,x        ; Turn off write mode
        lda     XMIT,x
rts1:   rts

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
WriteNibble2a:
        nop
WriteNibble2b:
        nop
        pha
        pla
        sta     DATA,x
        cmp     XMIT,x
        rts

Unused3:
        .byte   0
        .byte   0
        .byte   0

WaitA:
        ldx     #$11
:       dex
        bne     :-
        inc16   $D9
        sec
        sbc     #1
        bne     WaitA
        rts

;;; Timing (100-usecs)
phase_on_table:  .byte   $01, $30, $28, $24, $20, $1E, $1D, $1C, $1C, $1C, $1C, $1C
phase_off_table: .byte   $70, $2C, $26, $22, $1F, $1E, $1D, $1C, $1C, $1C, $1C, $1C

;;; ============================================================

WriteAndVerifyTrack:
        lda     kNibCountHi
        sta     $D6
WriteGap1AndAddress2:
        ldy     #$80
        lda     #$00
        sta     $D2
        jmp     L0B73

WriteGap3AndAddress:
        ldy     $D4
L0B73:  ldx     Slotx16
        jsr     CheckWriteProt
        bcc     :+
        jmp     RTS_
:
        ldx     Slotx16
        jsr     WriteGap2AndData
        inc     $D2
        lda     $D2
        cmp     #$10
        bcc     WriteGap3AndAddress

VerifyTrack:
        ldy     #$0F
        sty     $D2
        lda     k10
        sta     RetryCount
ResetSectorFlags:
        sta     SectorFlags,y
        dey
        bpl     ResetSectorFlags
        lda     $D4
        sec
        sbc     #$05
        tay
WaitGap3Count:
        jsr     RTS_
        jsr     RTS_
        pha
        pla
        nop
        nop
        dey
        bne     WaitGap3Count
        ldx     Slotx16
        jsr     ReadAddressField
        bcs     Retry2
        lda     $D8
        beq     VerifyNextSector2

DecGap3Count:
        dec     $D4
        lda     $D4
        cmp     kMinGap3
        bcs     Retry2
        sec
        rts

VerifyNextSector:
        ldx     Slotx16
        jsr     ReadAddressField
        bcs     Retry
VerifyNextSector2:
        ldx     Slotx16
        jsr     ReadSectorData
        bcs     Retry
        ldy     $D8
        lda     SectorFlags,y
        bmi     Retry
        lda     #$FF
        sta     SectorFlags,y
        dec     $D2
        bpl     VerifyNextSector
        clc
        rts

Retry:  dec     RetryCount
        bne     VerifyNextSector
        dec     $D6
        bne     Retry2
        sec
        rts

Retry2:  lda     k10
        asl     a
        sta     RetryCount
FindSector0FCont:
        ldx     Slotx16
        jsr     ReadAddressField
        bcs     :+
        lda     $D8
        cmp     #$0F
        beq     RetryWait
:
        dec     RetryCount
        bne     FindSector0FCont
        sec
RTS_:   rts

RetryWait:
        ldx     #$D6
:       jsr     RTS_
        jsr     RTS_
        bit     $00
        dex
        bne     :-
        jmp     WriteGap1AndAddress2

;;; ============================================================

kMinGap3:
        .byte   $0E
kMaxGap3:
        .byte   $1B
kNibCountHi:
        .byte   $03
k10:
        .byte   $10
Slotx16:
        .byte   0
HalfTrack:
        .byte   0
RetryCount:
        .byte   0

SectorFlags:
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
        .byte   0

seltrack_track:
        .byte   0
seltrack_slot:
        .byte   0

L0C38:  .byte   0
L0C39:  .byte   0

.endproc ; FormatDiskII
