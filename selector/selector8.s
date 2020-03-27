L0080           := $0080
L05A0           := $05A0
L1400           := $1400
L2004           := $2004
L2020           := $2020
L461E           := $461E
L4B4F           := $4B4F
L6177           := $6177
L6369           := $6369
L636F           := $636F
L6562           := $6562
L6572           := $6572
L6874           := $6874
L6E65           := $6E65
L6E69           := $6E69
L6F63           := $6F63
L6F72           := $6F72
L6F74           := $6F74
L7564           := $7564
L95A0           := $95A0
L98C1           := $98C1
L98D4           := $98D4
L9984           := $9984
L99DC           := $99DC
L9A15           := $9A15
L9A47           := $9A47
L9F74           := $9F74
LAD03           := $AD03
LAD11           := $AD11

        sta     LA027
        jsr     LAA01
        lda     LA027
        jsr     L9A47
        jsr     LA802
        jsr     LA6BD
        jsr     LAA2D
        lda     LA027
        jsr     L9A47
        jsr     LA802
        jsr     LA3F6
        pha
        jsr     LAC5B
        pla
        rts

LA027:  .byte   0
        .byte   $03
        and     $A1,x
        .byte   0
        php
LA02D:  .byte   0
        .byte   $04
LA02F:  .byte   0
        rol     $A0,x
        .byte   $04
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LA03B           := * + 1
        ora     ($00,x)
        .byte   $04
LA03D:  .byte   0
        ldy     $27A0,x
        .byte   0
        .byte   0
        .byte   0
        .byte   $04
LA045:  .byte   0
LA048           := * + 2
        jmp     L05A0

        .byte   0
LA04A:  .byte   0
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
LA056           := * + 1
        ora     ($00,x)
LA058           := * + 1
        ora     ($00,x)
        ora     ($35,x)
        lda     ($03,x)
        and     $A1,x
        .byte   0
LA061           := * + 1
        ora     $0300
        .byte   $F4
        ldy     #$00
LA067           := * + 1
        ora     ($00),y
        .byte   $04
LA069:  .byte   0
        .byte   0
LA06C           := * + 1
        ora     $00,x
LA06D:  .byte   $0B
LA06E:  .byte   0
LA06F:  .byte   0
        .byte   $04
LA071:  .byte   0
        .byte   0
LA074           := * + 1
        ora     $00,x
LA075:  .byte   $0B
LA076:  .byte   0
LA077:  .byte   0
LA078:  .byte   $07
        .byte   $F4
        ldy     #$C3
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LA084:  .byte   $07
        .byte   $F4
LA087           := * + 1
        ldy     #$00
        .byte   0
        .byte   0
        .byte   0
LA08B:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LA092:  asl     a
        and     $A1,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LA099:  .byte   0
LA09A:  .byte   0
LA09B:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        asl     a
        .byte   $F4
        ldy     #$00
        .byte   0
LA0AA:  .byte   0
LA0AB:  .byte   0
        .byte   0
LA0AD:  .byte   0
LA0AE:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $02
        .byte   0
        .byte   0
        .byte   0
LA0BC:  .byte   0
LA0BD:  .byte   0
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
LA0CC:  .byte   0
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
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LA0EC:  .byte   $FF
LA0EE           := * + 1
        ldy     $FC
LA0F0           := * + 1
        ldy     $F2
        ldy     #$60
        .byte   0
LA0F4:  .byte   0
LA0F5:  .byte   0
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
LA135:  .byte   0
LA136:  .byte   0
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
LA176:  .byte   0
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
LA1B6:  .byte   0
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
LA1F6:  .byte   0
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
LA206:  .byte   0
LA207:
LA208           := * + 1
LA209           := * + 2
        ora     a:$00
LA20A:  .byte   0
LA20B:  .byte   0
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
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LA2B5:  .byte   0
LA2B6:  .byte   0
LA2B7:  ldx     LA2B5
        lda     LA20A
        sta     LA20B,x
        inx
        stx     LA2B5
        rts

LA2C5:  ldx     LA2B5
        dex
        lda     LA20B,x
        sta     LA20A
        stx     LA2B5
        rts

LA2D3:  lda     #$00
        sta     LA208
        sta     LA2B6
        yax_call L95A0, $C8, $A028
        beq     LA2E9
        jmp     LAB16

LA2E9:  lda     LA02D
        sta     LA209
        sta     LA02F
        yax_call L95A0, $CA, $A02E
        beq     LA300
        jmp     LAB16

LA300:  jsr     LA319
        rts

LA304:  lda     LA209
        sta     LA03B
        yax_call L95A0, $CC, $A03A
        beq     LA318
        jmp     LAB16

LA318:  rts

LA319:  inc     LA208
        lda     LA209
        sta     LA03D
        yax_call L95A0, $CA, $A03C
        beq     LA330
        jmp     LAB16

LA330:  inc     LA2B6
        lda     LA2B6
        cmp     LA207
        bcc     LA35B
        lda     #$00
        sta     LA2B6
        lda     LA209
        sta     LA045
        yax_call L95A0, $CA, $A044
        beq     LA354
        jmp     LAB16

LA354:  lda     LA04A
        cmp     LA048
        rts

LA35B:  return  #$00

LA35E:  lda     LA208
        sta     LA20A
        jsr     LA304
        jsr     LA2B7
        jsr     LA75D
        jsr     LA2D3
        rts

LA371:  jsr     LA304
        jsr     LA3E9
        jsr     LA782
        jsr     LA2C5
        jsr     LA2D3
        jsr     LA387
        jsr     LA3E6
        rts

LA387:  lda     LA208
        cmp     LA20A
        beq     LA395
        jsr     LA319
        jmp     LA387

LA395:  rts

LA396:  lda     #$00
        sta     LA206
        jsr     LA2D3
LA39E:  jsr     LA319
        bne     LA3D0
        lda     LA0BC
        beq     LA39E
        lda     LA0BC
        sta     LA3EC
        and     #$0F
        sta     LA0BC
        lda     #$00
        sta     LA3E2
        jsr     LA3E3
        lda     LA3E2
        bne     LA39E
        lda     LA0CC
        cmp     #$0F
        bne     LA39E
        jsr     LA35E
        inc     LA206
        jmp     LA39E

LA3D0:  lda     LA206
        beq     LA3DE
        jsr     LA371
        dec     LA206
        jmp     LA39E

LA3DE:  jsr     LA304
        rts

LA3E2:  .byte   0
LA3E3:  jmp     (LA0EC)

LA3E6:  jmp     (LA0EE)

LA3E9:  jmp     (LA0F0)

LA3EC:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $FF
        ldy     $FC
        ldy     $F2
LA3F6           := * + 1
        ldy     #$A0
LA3F8           := * + 1
        ora     $B9
        beq     LA39E
        sta     LA0EC,y
        dey
        bpl     LA3F8
        tsx
        stx     LA4FB
        lda     #$FF
        sta     LA4F9
        jsr     LA7D9
        yax_call L95A0, $C4, $A0A5
        beq     LA41B
        jmp     LAB16

LA41B:  sub16   LA0AA, LA0AD, LA4F3
        cmp16   LA4F3, LA75B
        bcs     LA43F
        jmp     LAACB

LA43F:  ldx     LA0F4
        lda     #$2F
        sta     LA0F5,x
        inc     LA0F4
        ldy     #$00
        ldx     LA0F4
LA44F:  iny
        inx
        lda     LA1F6,y
        sta     LA0F4,x
        cpy     LA1F6
        bne     LA44F
        stx     LA0F4
        yax_call L95A0, $C4, $A0A5
        cmp     #$46
        beq     LA475
        cmp     #$45
        beq     LA475
        cmp     #$44
        beq     LA475
        rts

LA475:  yax_call L95A0, $C4, $A092
        beq     LA491
        cmp     #$45
        beq     LA488
        cmp     #$46
        bne     LA48E
LA488:  jsr     LAABD
        jmp     LA475

LA48E:  jmp     LAB16

LA491:  lda     LA099
        cmp     #$0F
        beq     LA4A0
        cmp     #$0D
        beq     LA4A0
        lda     #$00
        beq     LA4A2
LA4A0:  lda     #$FF
LA4A2:  sta     LA4F8
        ldy     #$07
LA4A7:  lda     LA092,y
        sta     LA084,y
        dey
        cpy     #$02
        bne     LA4A7
        lda     #$C3
        sta     LA087
        jsr     LA56D
        bcc     LA4BF
        jmp     LAACB

LA4BF:  ldy     #$11
        ldx     #$0B
LA4C3:  lda     LA092,y
        sta     LA084,x
        dex
        dey
        cpy     #$0D
        bne     LA4C3
        lda     LA08B
        cmp     #$0F
        bne     LA4DB
        lda     #$0D
        sta     LA08B
LA4DB:  yax_call L95A0, $C0, $A084
        beq     LA4E9
        jmp     LAB16

LA4E9:  lda     LA4F8
        beq     LA4F5
        jmp     LA396

        .byte   0
        rts

LA4F3:  .byte   0
LA4F4:  .byte   0
LA4F5:  jmp     LA610

LA4F8:  .byte   0
LA4F9:  .byte   0
LA4FA:  .byte   0
LA4FB:  .byte   0
        jmp     LA7C0

        lda     LA0CC
        cmp     #$0F
        bne     LA536
        jsr     LA75D
        jsr     LAA3F
        yax_call L95A0, $C4, $A092
        beq     LA528
        jmp     LAB16

LA51A:  jsr     LA7C0
        jsr     LA782
        lda     #$FF
        sta     LA3E2
        jmp     LA569

LA528:  jsr     LA79B
        jsr     LA69A
        bcs     LA51A
        jsr     LA782
        jmp     LA569

LA536:  jsr     LA79B
        jsr     LA75D
        jsr     LAA3F
        yax_call L95A0, $C4, $A092
        beq     LA54D
        jmp     LAB16

LA54D:  jsr     LA56D
        bcc     LA555
        jmp     LAACB

LA555:  jsr     LA782
        jsr     LA69A
        bcs     LA56A
        jsr     LA75D
        jsr     LA610
        jsr     LA782
        jsr     LA7C0
LA569:  rts

LA56A:  jsr     LA7C0
LA56D:  yax_call L95A0, $C4, $A092
        beq     LA57B
        jmp     LAB16

LA57B:  lda     #$00
        sta     LA60E
        sta     LA60F
        yax_call L95A0, $C4, $A0A5
        beq     LA595
        cmp     #$46
        beq     LA5A1
        jmp     LAB16

LA595:  copy16  LA0AD, LA60E
LA5A1:  lda     LA0F4
        sta     LA60C
        ldy     #$01
LA5A9:  iny
        cpy     LA0F4
        bcs     LA602
        lda     LA0F4,y
        cmp     #$2F
        bne     LA5A9
        tya
        sta     LA0F4
        sta     LA60D
        yax_call L95A0, $C4, $A0A5
        beq     LA5CB
        jmp     LAB16

LA5CB:  sub16   LA0AA, LA0AD, LA60A
        sub16   LA60A, LA60E, LA60A
        cmp16   LA60A, LA09A
        bcs     LA602
        sec
        bcs     LA603
LA602:  clc
LA603:  lda     LA60C
        sta     LA0F4
        rts

LA60A:  .byte   0
LA60B:  .byte   0
LA60C:  .byte   0
LA60D:  .byte   0
LA60E:  .byte   0
LA60F:  .byte   0
LA610:  yax_call L95A0, $C8, $A05C
        beq     LA61E
        jsr     LAB16
LA61E:  yax_call L95A0, $C8, $A062
        beq     LA62C
        jmp     LAB16

LA62C:  lda     LA061
        sta     LA069
        sta     LA056
        lda     LA067
        sta     LA071
        sta     LA058
LA63E:  copy16  #$0B00, LA06C
        yax_call L95A0, $CA, $A068
        beq     LA65A
        cmp     #$4C
        beq     LA687
        jmp     LAB16

LA65A:  copy16  LA06E, LA074
        ora     LA06E
        beq     LA687
        yax_call L95A0, $CB, $A070
        beq     LA679
        jmp     LAB16

LA679:  lda     LA076
        cmp     #$00
        bne     LA687
        lda     LA077
        cmp     #$0B
        beq     LA63E
LA687:  yax_call L95A0, $CC, $A057
        yax_call L95A0, $CC, $A055
        rts

LA69A:  ldx     #$07
LA69C:  lda     LA092,x
        sta     LA078,x
        dex
        cpx     #$03
        bne     LA69C
        yax_call L95A0, $C0, $A078
        clc
        beq     LA6B6
        jmp     LAB16

LA6B6:  rts

        and     #$A7
        plp
        .byte   $A7
        .byte   $F2
LA6BD           := * + 1
        ldy     #$A0
LA6BF           := * + 1
        ora     $B9
        .byte   $B7
        ldx     $99
        cpx     $88A0
        bpl     LA6BF
        lda     #$00
        sta     LA759
        sta     LA75A
        sta     LA75B
        sta     LA75C
        ldy     #$17
        lda     #$00
LA6DA:  sta     $BF58,y
        dey
        bpl     LA6DA
        jsr     LA7D9
LA6E3:  yax_call L95A0, $C4, $A092
        beq     LA6FF
        cmp     #$45
        beq     LA6F6
        cmp     #$46
        bne     LA6FC
LA6F6:  jsr     LAABD
        jmp     LA6E3

LA6FC:  jmp     LAB16

LA6FF:  lda     LA099
        sta     LA724
        cmp     #$0F
        beq     LA711
        cmp     #$0D
        beq     LA711
        lda     #$00
        beq     LA713
LA711:  lda     #$FF
LA713:  sta     LA723
        beq     LA725
        jsr     LA396
        lda     LA724
        cmp     #$0F
        bne     LA725
        rts

LA723:  .byte   0
LA724:  .byte   0
LA725:  jmp     LA729

        rts

LA729:  jsr     LA75D
        yax_call L95A0, $C4, $A092
        bne     LA74A
        add16   LA75B, LA09A, LA75B
LA74A:  inc16   LA759
LA752:  jsr     LA782
        jsr     LAA98
        rts

LA759:  .byte   0
LA75A:  .byte   0
LA75B:  .byte   0
LA75C:  .byte   0
LA75D:  lda     LA0BC
        bne     LA763
        rts

LA763:  ldx     #$00
        ldy     LA135
        lda     #$2F
        sta     LA136,y
        iny
LA76E:  cpx     LA0BC
        bcs     LA77E
        lda     LA0BD,x
        sta     LA136,y
        inx
        iny
        jmp     LA76E

LA77E:  sty     LA135
        rts

LA782:  ldx     LA135
        bne     LA788
        rts

LA788:  lda     LA135,x
        cmp     #$2F
        beq     LA796
        dex
        bne     LA788
        stx     LA135
        rts

LA796:  dex
        stx     LA135
        rts

LA79B:  lda     LA0BC
        bne     LA7A1
        rts

LA7A1:  ldx     #$00
        ldy     LA0F4
        lda     #$2F
        sta     LA0F5,y
        iny
LA7AC:  cpx     LA0BC
        bcs     LA7BC
        lda     LA0BD,x
        sta     LA0F5,y
        inx
        iny
        jmp     LA7AC

LA7BC:  sty     LA0F4
        rts

LA7C0:  ldx     LA0F4
        bne     LA7C6
        rts

LA7C6:  lda     LA0F4,x
        cmp     #$2F
        beq     LA7D4
        dex
        bne     LA7C6
        stx     LA0F4
        rts

LA7D4:  dex
        stx     LA0F4
        rts

LA7D9:  ldy     #$00
        sta     LA4FA
        dey
LA7DF:  iny
        lda     LA1B6,y
        cmp     #$2F
        bne     LA7EA
        sty     LA4FA
LA7EA:  sta     LA135,y
        cpy     LA1B6
        bne     LA7DF
        ldy     LA176
LA7F5:  lda     LA176,y
        sta     LA0F4,y
        dey
        bpl     LA7F5
        rts

        return  #$00

LA802:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
LA80B:  lda     ($06),y
        sta     LA1B6,y
        dey
        bpl     LA80B
        ldy     LA1B6
LA816:  lda     LA1B6,y
        and     #$7F
        cmp     #$2F
        beq     LA822
        dey
        bne     LA816
LA822:  dey
        sty     LA1B6
LA826:  lda     LA1B6,y
        and     #$7F
        cmp     #$2F
        beq     LA832
        dey
        bpl     LA826
LA832:  ldx     #$00
LA834:  iny
        inx
        lda     LA1B6,y
        sta     LA1F6,x
        cpy     LA1B6
        bne     LA834
        stx     LA1F6
        lda     LCBANK2
        lda     LCBANK2
        ldy     $D3EE
LA84D:  lda     $D3EE,y
        sta     LA176,y
        dey
        bpl     LA84D
        lda     ROMIN2
        rts

LA85A:  .byte   $0B
        ora     ($00,x)
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        stx     $00,y
        .byte   $32
        .byte   0
        .byte   $F4
        ora     ($8C,x)
        .byte   0
        .byte   $64
        .byte   0
        .byte   $32
        .byte   0
        .byte   0
        jsr     L0080
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        lsr     $4601,x
        .byte   0
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     ($01,x)
        .byte   0
        .byte   $7F
        .byte   0
        dey
        .byte   0
        .byte   0
        .byte   $14
        .byte   0
        and     ($00),y
        sei
        .byte   0
        .byte   $3C
        .byte   0
        clc
        .byte   0
        .byte   $3B
        .byte   0
        .byte   $04
        .byte   0
        .byte   $02
        .byte   0
        .byte   $5C
        ora     ($44,x)
        .byte   0
        ora     $00
        .byte   $03
        .byte   0
        .byte   $5B
        ora     ($43,x)
        .byte   0
        .byte   $64
        .byte   0
        bpl     LA8B4
LA8B4:  clc
        .byte   $44
        .byte   $6F
        .byte   $77
        ror     $6C20
        .byte   $6F
        adc     ($64,x)
        jsr     L6E69
        jsr     L6874
        adc     WNDLFT
        .byte   $52
        eor     ($4D,x)
        .byte   $43
        adc     ($72,x)
        .byte   $64
        .byte   $14
        .byte   0
        jsr     L1400
        .byte   0
        plp
        .byte   0
        php
        .byte   $43
        .byte   $6F
        bvs     LA953
        adc     #$6E
        .byte   $67
        .byte   $3A
        .byte   $12
        .byte   0
        clc
        .byte   0
        .byte   $5A
        ora     (WNDLFT,x)
        .byte   0
        asl     $00
        clc
        .byte   0
        .byte   $5A
        ora     ($42,x)
        .byte   0
        .byte   $64
        .byte   0
        .byte   $32
        .byte   0
        .byte   0
        jsr     L0080
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $5A
        ora     ($42,x)
        .byte   0
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     ($01,x)
        .byte   0
        .byte   $7F
        .byte   0
        dey
        .byte   0
        .byte   0
        .byte   $37
        lsr     $746F
        jsr     L6E65
        .byte   $6F
        adc     $67,x
        pla
        jsr     L6F72
        .byte   $6F
        adc     $6920
        ror     $7420
        pla
        adc     WNDLFT
        .byte   $52
        eor     ($4D,x)
        .byte   $43
        adc     ($72,x)
        .byte   $64
        jsr     L6F74
        jsr     L6F63
        bvs     LA9B4
        jsr     L6874
        adc     WNDLFT
        adc     ($70,x)
        bvs     LA9B0
        adc     #$63
        adc     ($74,x)
        adc     #$6F
        ror     $152E
        .byte   $43
        jmp     (L6369)

        .byte   $6B
LA953           := * + 1
        jsr     L4B4F
        jsr     L6F74
        jsr     L6F63
        ror     $6974
        ror     $6575
        rol     $4125
LA965           := * + 1
        ror     $6520
        .byte   $72
        .byte   $72
        .byte   $6F
        .byte   $72
        jsr     L636F
        .byte   $63
        adc     $72,x
        adc     $64
        jsr     L7564
        .byte   $72
        adc     #$6E
        .byte   $67
        jsr     L6874
        adc     WNDLFT
        .byte   $64
        .byte   $6F
        .byte   $77
        ror     $6F6C
        adc     ($64,x)
        rol     $5430
        pla
        adc     WNDLFT
        .byte   $63
        .byte   $6F
        bvs     LAA0A
        jsr     L6177
        .byte   $73
        ror     $7427
        jsr     L6F63
        adc     $6C70
        adc     $74
        adc     $64
        bit     $6320
        jmp     (L6369)

        .byte   $6B
        jsr     L4B4F
        jsr     L6F74
LA9B0           := * + 1
        jsr     L6F63
LA9B4           := * + 2
        ror     $6974
        ror     $6575
        rol     $4623
        adc     #$6C
        adc     HIMEM
        jsr     L6F74
        jsr     L6562
        jsr     L6F63
        bvs     LAA33
        adc     $64
        jsr     L6E69
        jsr     L6874
        adc     WNDLFT
        .byte   $52
        eor     ($4D,x)
        .byte   $43
        adc     ($72,x)
        .byte   $64
        .byte   $3A
        jsr     L461E
        adc     #$6C
        adc     HIMEM
        jsr     L6572
        adc     $6961
        ror     L6E69
        .byte   $67
        jsr     L6F74
        jsr     L6562
        jsr     L6F63
        bvs     LAA61
        adc     $64
        .byte   $3A
        jsr     L2004
        jsr     L2020
LAA01:  MGTK_CALL MGTK::SetMark, $A85A
        lda     LA85A
LAA0A:  jsr     L9A15
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::FrameRect, $A8A0
        MGTK_CALL MGTK::FrameRect, $A8A8
        MGTK_CALL MGTK::MoveTo, $A8B0
        addr_call L9984, $A8B4
        rts

LAA2D:  lda     LA85A
        jsr     L9A15
LAA33:  MGTK_CALL MGTK::SetPenMode, $8E03
        MGTK_CALL MGTK::PaintRect, $A8E6
LAA3F:  dec     LA759
        lda     LA759
        cmp     #$FF
        bne     LAA4C
        dec     LA75A
LAA4C:  jsr     LAC62
        MGTK_CALL MGTK::SetPortBits, $A8EE
        MGTK_CALL MGTK::SetPenMode, $8E03
        MGTK_CALL MGTK::PaintRect, $A8DE
LAA61:  addr_call L99DC, $A135
        MGTK_CALL MGTK::MoveTo, $A8CD
        addr_call L9984, $A8D5
        addr_call L9984, $A135
        MGTK_CALL MGTK::MoveTo, $A8D1
        addr_call L9984, $A9DD
        addr_call L9984, $ACE6
        addr_call L9984, $A9FC
        rts

LAA98:  jsr     LAC62
        MGTK_CALL MGTK::SetPortBits, $A8EE
        MGTK_CALL MGTK::MoveTo, $A8CD
        addr_call L9984, $A9B9
        addr_call L9984, $ACE6
        addr_call L9984, $A9FC
        rts

LAABD:  lda     #$FD
        jsr     L9F74
        bne     LAAC8
        jsr     L98C1
        rts

LAAC8:  jmp     LAC54

LAACB:  lda     LA85A
        jsr     L9A15
        MGTK_CALL MGTK::SetPenMode, $8E03
        MGTK_CALL MGTK::PaintRect, $A8E6
        MGTK_CALL MGTK::MoveTo, $A8CD
        addr_call L9984, $A914
        MGTK_CALL MGTK::MoveTo, $A8D1
        addr_call L9984, $A94C
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::FrameRect, $A894
        MGTK_CALL MGTK::MoveTo, $A89C
        addr_call L9984, $902F
        jsr     LAB61
        jmp     LAC54

LAB16:  lda     LA85A
        jsr     L9A15
        MGTK_CALL MGTK::SetPenMode, $8E03
        MGTK_CALL MGTK::PaintRect, $A8E6
        MGTK_CALL MGTK::MoveTo, $A8CD
        addr_call L9984, $A962
        MGTK_CALL MGTK::MoveTo, $A8D1
        addr_call L9984, $A988
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::FrameRect, $A894
        MGTK_CALL MGTK::MoveTo, $A89C
        addr_call L9984, $902F
        jsr     LAB61
        jmp     LAC54

LAB61:  jsr     L98D4
LAB64:  MGTK_CALL MGTK::CheckEvents, $8F79
        lda     $8F79
        cmp     #$01
        beq     LAB98
        cmp     #$03
        bne     LAB64
        lda     $8F7A
        cmp     #$0D
        bne     LAB64
        lda     LA85A
        jsr     L9A15
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $A894
        MGTK_CALL MGTK::PaintRect, $A894
        jsr     L98C1
        rts

LAB98:  MGTK_CALL MGTK::EndUpdate, $8F7A
        lda     $8F7E
        beq     LAB64
        cmp     #$02
        bne     LAB64
        lda     $8F7F
        cmp     LA85A
        bne     LAB64
        lda     LA85A
        jsr     L9A15
        lda     LA85A
        sta     $8F79
        MGTK_CALL MGTK::GrowWindow, $8F79
        MGTK_CALL MGTK::MoveTo, $8F7E
        MGTK_CALL MGTK::InRect, $A894
        cmp     #$80
        bne     LAB64
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $A894
        jsr     LABE6
        bmi     LAB64
        jsr     L98C1
        rts

LABE6:  lda     #$00
        sta     LAC53
LABEB:  MGTK_CALL MGTK::CheckEvents, $8F79
        lda     $8F79
        cmp     #$02
        beq     LAC3C
        lda     LA85A
        sta     $8F79
        MGTK_CALL MGTK::GrowWindow, $8F79
        MGTK_CALL MGTK::MoveTo, $8F7E
        MGTK_CALL MGTK::InRect, $A894
        cmp     #$80
        beq     LAC1C
        lda     LAC53
        beq     LAC24
        jmp     LABEB

LAC1C:  lda     LAC53
        bne     LAC24
        jmp     LABEB

LAC24:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $A894
        lda     LAC53
        clc
        adc     #$80
        sta     LAC53
        jmp     LABEB

LAC3C:  lda     LAC53
        beq     LAC44
        return  #$FF

LAC44:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $A894
        return  #$00

LAC53:  .byte   0
LAC54:  ldx     LA4FB
        txs
        return  #$FF

LAC5B:  MGTK_CALL MGTK::OpenWindow, $A85A
        rts

LAC62:  copy16  LA759, LACE2
        ldx     #$07
        lda     #$20
LAC72:  sta     LACE6,x
        dex
        bne     LAC72
        lda     #$00
        sta     LACE5
        ldy     #$00
        ldx     #$00
LAC81:  lda     #$00
        sta     LACE4
LAC86:  lda     LACE2
        cmp     LACDA,x
        lda     LACE3
        sbc     LACDB,x
        bpl     LACB8
        lda     LACE4
        bne     LACA2
        bit     LACE5
        bmi     LACA2
        lda     #$20
        bne     LACAB
LACA2:  ora     #$30
        pha
        lda     #$80
        sta     LACE5
        pla
LACAB:  sta     LACE8,y
        iny
        inx
        inx
        cpx     #$08
        beq     LACD1
        jmp     LAC81

LACB8:  inc     LACE4
        lda     LACE2
        sec
        sbc     LACDA,x
        sta     LACE2
        lda     LACE3
        sbc     LACDB,x
        sta     LACE3
        jmp     LAC86

LACD1:  lda     LACE2
        ora     #$30
        sta     LACE8,y
        rts

LACDA:
LACDB           := * + 1
        bpl     LAD03
        inx
        .byte   $03
        .byte   $64
        .byte   0
        asl     a
        .byte   0
LACE2:  .byte   0
LACE3:  .byte   0
LACE4:  .byte   0
LACE5:  .byte   0
LACE6:  .byte   $07
LACE8           := * + 1
        jsr     L2020
        jsr     L2020
        MGTK_CALL MGTK::PaintRect, $A243
        MGTK_CALL MGTK::PaintRect, $A243
        jsr     LA965
        jmp     LAD11

        .byte   $C9
