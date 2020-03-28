        .org $D000

.scope
L0080           := $0080
L2000           := $2000
L2020           := $2020
L2065           := $2065
MGTK            := $4000
L4520           := $4520
L5858           := $5858
L6165           := $6165
L6562           := $6562
L666F           := $666F
L6874           := $6874
L6964           := $6964
L6E75           := $6E75
L6F66           := $6F66
L6F6E           := $6F6E
L6F73           := $6F73
L7245           := $7245
L7369           := $7369
L756E           := $756E
L7572           := $7572
L7865           := $7865
FONT            := $8800
START           := $8E00
L9582           := $9582
L95A0           := $95A0
L98D4           := $98D4
L9984           := $9984
L9A15           := $9A15
L9AFD           := $9AFD
L9B42           := $9B42

        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        asl     $401F,x
        .byte   $07
        beq     LD029
LD029:  .byte   0
        asl     $601F,x
        .byte   $03
        rts

        .byte   0
        .byte   0
        inc     $F01F,x
        .byte   $F3
        .byte   $4F
        .byte   0
        .byte   0
        inc     $F81F,x
        .byte   $F3
        .byte   $4F
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        .byte   $4F
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        .byte   $67
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        .byte   $F3
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        sbc     $00,y
        inc     $FC1F,x
        .byte   $FF
        .byte   $FC
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $3F
        inc     a:$00,x
        inc     $FC1F,x
        .byte   $1F
        .byte   $FF
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $1F
        .byte   $FF
        .byte   0
        .byte   0
        rol     $FE00,x
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        inc     $FF03,x
        .byte   $1F
        .byte   $FF
        .byte   0
        .byte   0
        inc     $FF43,x
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        asl     $FF60
        .byte   $FF
        .byte   $3F
        .byte   0
        .byte   0
        inc     a:$03,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$03,x
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
        .byte   $14
        .byte   0
        php
        .byte   0
        .byte   0
        bne     LD0B6
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        bit     $00
LD0B6:  .byte   $17
        .byte   0
        eor     ($00,x)
        .byte   $57
        .byte   0
        sbc     $01
        stx     $0400
        .byte   0
        .byte   $02
        .byte   0
        ldy     #$01
        and     $00,x
        ora     $00
        .byte   $03
        .byte   0
        .byte   $9F
        ora     ($34,x)
        .byte   0
LD0D0:
LD0D1           := * + 1
        eor     ($00,x)
LD0D2:  .byte   $57
LD0D3:  .byte   0
        .byte   0
        jsr     L0080
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD0DC:
LD0DD           := * + 1
        ldy     $01
LD0DE:  .byte   $37
        .byte   0

        PASCAL_STRING "Cancel    Esc"
        PASCAL_STRING {"OK            ", CHAR_RETURN}
        PASCAL_STRING "Try Again  A"

        .byte   $2C
        ora     (CV,x)
        .byte   0
        bcc     LD112
LD112           := * + 1
        bmi     LD113
LD113:  and     ($01),y
        .byte   $2F
        .byte   0
        .byte   $14
        .byte   0
        and     $00
        sei
        .byte   0
        bmi     LD11F
LD11F:  ora     $2F00,y
        .byte   0
        ldx     $1000,y
        .byte   0
        .byte   $4B
        .byte   0, $1D, $00

        PASCAL_STRING "System Error number XX"

LD142:  .byte   0
LD143:  .byte   0
LD144:  .byte   0

        PASCAL_STRING "The Selector is unable to run the program."
        PASCAL_STRING "I/O Error"
        PASCAL_STRING "No device connected."
        PASCAL_STRING "Part of the pathname doesn't exist."
        PASCAL_STRING "Please insert source disk."
        PASCAL_STRING "The file cannot be found."
        PASCAL_STRING "Please insert the system disk"
        PASCAL_STRING "BASIC.SYSTEM not found"

LD21D:  php
LD21E:  .byte   0
        .byte   $27
        plp
        .byte   $44
        eor     $46
LD226           := * + 2
        inc     $45FF,x
LD227:  cmp     ($70),y
        cmp     ($7A),y
        cmp     ($8F),y
        cmp     ($B3),y
        cmp     ($CE),y
        cmp     ($E8),y
        cmp     ($06),y
        .byte   $D2
LD236:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $80
        .byte   0
        .byte   $80
        .byte   0
        pha
        lda     $9129
        beq     LD248
        pla
        return  #$01

LD248:  jsr     L98D4
        MGTK_CALL MGTK::InitPort, $8F83
        MGTK_CALL MGTK::SetPort, $8F83
        lda     LD0D0
        ldx     LD0D1
        jsr     LD725
        sty     LD764
        sta     LD767
        lda     LD0D0
        clc
        adc     LD0DC
        pha
        lda     LD0D1
        adc     LD0DD
        tax
        pla
        jsr     LD725
        sty     LD766
        sta     LD768
        lda     LD0D2
        sta     LD763
        clc
        adc     LD0DE
        sta     LD765
        MGTK_CALL MGTK::HideCursor, $0000
        jsr     LD5A2
        MGTK_CALL MGTK::ShowCursor, $0000
        ldx     #$03
        lda     #$00
LD29F:  sta     $8F83,x
        sta     $8F8B,x
        dex
        bpl     LD29F
        copy16  #$0226, $8F8F
        copy16  #$00B9, $8F91
        MGTK_CALL MGTK::SetPort, $8F83
        MGTK_CALL MGTK::SetPenMode, $8E03
        MGTK_CALL MGTK::PaintRect, $D0B8
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::FrameRect, $D0B8
        MGTK_CALL MGTK::SetPortBits, $D0D0
        MGTK_CALL MGTK::FrameRect, $D0C0
        MGTK_CALL MGTK::FrameRect, $D0C8
        MGTK_CALL MGTK::SetPenMode, $8E03
        MGTK_CALL MGTK::HideCursor, $0000
        MGTK_CALL MGTK::PaintBits, $D0A8
        MGTK_CALL MGTK::ShowCursor, $0000
        pla
        ldy     #$00
LD307:  cmp     LD21E,y
        beq     LD314
        iny
        cpy     LD21D
        bne     LD307
        ldy     #$00
LD314:  tya
        asl     a
        tay
        lda     LD226,y
        sta     LD143
        lda     LD227,y
        sta     LD144
        tya
        lsr     a
        tay
        lda     LD236,y
        sta     LD142
        MGTK_CALL MGTK::SetPenMode, $8E05
        bit     LD142
        bpl     LD365
        MGTK_CALL MGTK::FrameRect, $D117
        MGTK_CALL MGTK::MoveTo, $D11F
        addr_call L9984, $D0E0
        bit     LD142
        bvs     LD365
        MGTK_CALL MGTK::FrameRect, $D10B
        MGTK_CALL MGTK::MoveTo, $D113
        addr_call L9984, $D0FE
        jmp     LD378

LD365:  MGTK_CALL MGTK::FrameRect, $D10B
        MGTK_CALL MGTK::MoveTo, $D113
        addr_call L9984, $D0EE
LD378:  MGTK_CALL MGTK::MoveTo, $D127
        lda     LD143
        ldx     LD144
        jsr     L9984
LD387:  MGTK_CALL MGTK::GetEvent, $8F79
        lda     $8F79
        cmp     #$01
        bne     LD397
        jmp     LD3F7

LD397:  cmp     #$03
        bne     LD387
        lda     $8F7A
        and     #$7F
        bit     LD142
        bpl     LD3DF
        cmp     #$1B
        bne     LD3BA
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $D117
        lda     #$01
        jmp     LD434

LD3BA:  bit     LD142
        bvs     LD3DF
        cmp     #$61
        bne     LD3D4
LD3C3:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $D10B
        lda     #$00
        jmp     LD434

LD3D4:  cmp     #$41
        beq     LD3C3
        cmp     #$0D
        beq     LD3C3
        jmp     LD387

LD3DF:  cmp     #$0D
        bne     LD3F4
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $D10B
        lda     #$00
        jmp     LD434

LD3F4:  jmp     LD387

LD3F7:  jsr     LD57B
        MGTK_CALL MGTK::MoveTo, $8F7A
        bit     LD142
        bpl     LD424
        MGTK_CALL MGTK::InRect, $D117
        cmp     #$80
        bne     LD412
        jmp     LD4AD

LD412:  bit     LD142
        bvs     LD424
        MGTK_CALL MGTK::InRect, $D10B
        cmp     #$80
        bne     LD431
        jmp     LD446

LD424:  MGTK_CALL MGTK::InRect, $D10B
        cmp     #$80
        bne     LD431
        jmp     LD514

LD431:  jmp     LD387

LD434:  pha
        MGTK_CALL MGTK::HideCursor, $0000
        jsr     LD5F7
        MGTK_CALL MGTK::ShowCursor, $0000
        pla
        rts

LD446:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $D10B
        lda     #$00
        sta     LD4AC
LD457:  MGTK_CALL MGTK::GetEvent, $8F79
        lda     $8F79
        cmp     #$02
        beq     LD49F
        jsr     LD57B
        MGTK_CALL MGTK::MoveTo, $8F7A
        MGTK_CALL MGTK::InRect, $D10B
        cmp     #$80
        beq     LD47F
        lda     LD4AC
        beq     LD487
        jmp     LD457

LD47F:  lda     LD4AC
        bne     LD487
        jmp     LD457

LD487:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $D10B
        lda     LD4AC
        clc
        adc     #$80
        sta     LD4AC
        jmp     LD457

LD49F:  lda     LD4AC
        beq     LD4A7
        jmp     LD387

LD4A7:  lda     #$00
        jmp     LD434

LD4AC:  .byte   0
LD4AD:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $D117
        lda     #$00
        sta     LD513
LD4BE:  MGTK_CALL MGTK::GetEvent, $8F79
        lda     $8F79
        cmp     #$02
        beq     LD506
        jsr     LD57B
        MGTK_CALL MGTK::MoveTo, $8F7A
        MGTK_CALL MGTK::InRect, $D117
        cmp     #$80
        beq     LD4E6
        lda     LD513
        beq     LD4EE
        jmp     LD4BE

LD4E6:  lda     LD513
        bne     LD4EE
        jmp     LD4BE

LD4EE:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $D117
        lda     LD513
        clc
        adc     #$80
        sta     LD513
        jmp     LD4BE

LD506:  lda     LD513
        beq     LD50E
        jmp     LD387

LD50E:  lda     #$01
        jmp     LD434

LD513:  .byte   0
LD514:  lda     #$00
        sta     LD57A
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $D10B
LD525:  MGTK_CALL MGTK::GetEvent, $8F79
        lda     $8F79
        cmp     #$02
        beq     LD56D
        jsr     LD57B
        MGTK_CALL MGTK::MoveTo, $8F7A
        MGTK_CALL MGTK::InRect, $D10B
        cmp     #$80
        beq     LD54D
        lda     LD57A
        beq     LD555
        jmp     LD525

LD54D:  lda     LD57A
        bne     LD555
        jmp     LD525

LD555:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $D10B
        lda     LD57A
        clc
        adc     #$80
        sta     LD57A
        jmp     LD525

LD56D:  lda     LD57A
        beq     LD575
        jmp     LD387

LD575:  lda     #$00
        jmp     LD434

LD57A:  .byte   0
LD57B:  sub16   $8F7A, LD0D0, $8F7A
        sub16   $8F7C, LD0D2, $8F7C
        rts

LD5A2:  copy16  #$0800, LD5D1
        lda     LD763
        jsr     LD6AA
        lda     LD765
        sec
        sbc     LD763
        tax
        inx
LD5BB:  lda     LD764
        sta     LD5F6
LD5C1:  lda     LD5F6
        lsr     a
        tay
        sta     LOWSCR
        bcs     LD5CE
        sta     HISCR
LD5CE:  lda     ($06),y
LD5D1           := * + 1
LD5D2           := * + 2
        sta     $1234
        inc16   LD5D1
LD5DB:  lda     LD5F6
        cmp     LD766
        bcs     LD5E8
        inc     LD5F6
        bne     LD5C1
LD5E8:  jsr     LD6EC
        dex
        bne     LD5BB
        lda     LD5D1
        ldx     LD5D2
        rts

        .byte   0
LD5F6:  .byte   0
LD5F7:  copy16  #$0800, LD656
        ldx     LD767
        ldy     LD768
        lda     #$FF
        cpx     #$00
        beq     LD612
LD60D:  clc
        rol     a
        dex
        bne     LD60D
LD612:  sta     LD6A6
        eor     #$FF
        sta     LD6A7
        lda     #$01
        cpy     #$00
        beq     LD625
LD620:  sec
        rol     a
        dey
        bne     LD620
LD625:  sta     LD6A8
        eor     #$FF
        sta     LD6A9
        lda     LD763
        jsr     LD6AA
        lda     LD765
        sec
        sbc     LD763
        tax
        inx
        lda     LD764
        sta     LD6A5
LD642:  lda     LD764
        sta     LD6A5
LD648:  lda     LD6A5
        lsr     a
        tay
        sta     LOWSCR
        bcs     LD655
        sta     HISCR
LD655:
LD656           := * + 1
LD657           := * + 2
        lda     $0800
        pha
        lda     LD6A5
        cmp     LD764
        beq     LD677
        cmp     LD766
        bne     LD685
        lda     ($06),y
        and     LD6A9
        sta     ($06),y
        pla
        and     LD6A8
        ora     ($06),y
        pha
        jmp     LD685

LD677:  lda     ($06),y
        and     LD6A7
        sta     ($06),y
        pla
        and     LD6A6
        ora     ($06),y
        pha
LD685:  pla
        sta     ($06),y
        inc16   LD656
LD690:  lda     LD6A5
        cmp     LD766
        bcs     LD69D
        inc     LD6A5
        bne     LD648
LD69D:  jsr     LD6EC
        dex
        bne     LD642
        rts

        .byte   0
LD6A5:  .byte   0
LD6A6:  .byte   0
LD6A7:  .byte   0
LD6A8:  .byte   0
LD6A9:  .byte   0
LD6AA:  sta     LD769
        and     #$07
        sta     LD74A
        lda     LD769
        and     #$38
        sta     LD749
        lda     LD769
        and     #$C0
        sta     LD748
        jsr     LD6C6
        rts

LD6C6:  lda     LD748
        lsr     a
        lsr     a
        ora     LD748
        pha
        lda     LD749
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     LD6EB
        pla
        ror     a
        sta     $06
        lda     LD74A
        asl     a
        asl     a
        ora     LD6EB
        ora     #$20
        sta     $07
        clc
        rts

LD6EB:  .byte   0
LD6EC:  lda     LD74A
        cmp     #$07
        beq     LD6F9
        inc     LD74A
        jmp     LD6C6

LD6F9:  lda     #$00
        sta     LD74A
        lda     LD749
        cmp     #$38
        beq     LD70E
        clc
        adc     #$08
        sta     LD749
        jmp     LD6C6

LD70E:  lda     #$00
        sta     LD749
        lda     LD748
        clc
        adc     #$40
        sta     LD748
        cmp     #$C0
        beq     LD723
        jmp     LD6C6

LD723:  sec
        rts

LD725:  ldy     #$00
        cpx     #$02
        bne     LD730
        ldy     #$49
        clc
        adc     #$01
LD730:  cpx     #$01
        bne     LD73E
        ldy     #$24
        clc
        adc     #$04
        bcc     LD73E
        iny
        sbc     #$07
LD73E:  cmp     #$07
        bcc     LD747
        sbc     #$07
        iny
        bne     LD73E
LD747:  rts

LD748:  .byte   0
LD749:  .byte   0
LD74A:  .byte   0
        .byte   $FF
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
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD763:  .byte   0
LD764:  .byte   0
LD765:  .byte   0
LD766:  .byte   0
LD767:  .byte   0
LD768:  .byte   0
LD769:  .byte   0
        cmp     #$08
        bcc     LD771
        jmp     L9582

LD771:  cmp     $9127
        bcc     LD796
        lda     $910E
        jsr     L9B42
        lda     #$FF
        sta     $910E
        rts

        sec
        sbc     #$08
        cmp     $9128
        bcc     LD796
        lda     $910E
        jsr     L9B42
        lda     #$FF
        sta     $910E
        rts

LD796:  lda     $959E
        jsr     L9AFD
        rts

        .byte   0
        .byte   0
        .byte   0
        sty     $95AE
        stax    $95AF
        php
        sei
        MLI_CALL $00, $0000
        plp
        and     #$FF
        rts

        rts

        yax_call L95A0, $C8, $90A0
        lda     $90A5
        sta     $90A7
        sta     DHIRESOFF
        sta     TXTCLR
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        yax_call L95A0, $CA, $90A6
        yax_call L95A0, $CC, $90C5
        jmp     L2000

        lda     $8FD9
        jsr     L9A15
        lda     $8F7A
        and     #$7F

.endscope