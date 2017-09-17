.org $D000
; da65 V2.16 - Git f5e9b401
; Created:    2017-09-17 11:30:59
; Input file: orig/DESKTOP2_s2_aux2
; Page:       1


        .setcpu "65C02"

L0000           := $0000
L0003           := $0003
L0006           := $0006
L0080           := $0080
L00E4           := $00E4
L03E4           := $03E4
L0520           := $0520
L0665           := $0665
L1020           := $1020
L1420           := $1420
L2020           := $2020
L2030           := $2030
L2065           := $2065
L206C           := $206C
L2078           := $2078
L2E33           := $2E33
L37E4           := $37E4
L3A65           := $3A65
L3F20           := $3F20
A2D             := $4000
L5214           := $5214
L5513           := $5513
L616D           := $616D
L616F           := $616F
L6261           := $6261
L6420           := $6420
L6544           := $6544
L6863           := $6863
L6874           := $6874
L6964           := $6964
L6966           := $6966
L6C73           := $6C73
L6E45           := $6E45
L6E61           := $6E61
L6E65           := $6E65
L6E69           := $6E69
L6F74           := $6F74
L6F79           := $6F79
L7041           := $7041
L7061           := $7061
L7264           := $7264
L7365           := $7365
L736F           := $736F
L7461           := $7461
L746F           := $746F
L7552           := $7552
L7661           := $7661
L7853           := $7853
L7C03           := $7C03
L7E03           := $7E03
L87F6           := $87F6
L8813           := $8813
UNKNOWN_CALL    := $8E00
LB600           := $B600
MLI             := $BF00
RAMRDOFF        := $C002
RAMRDON         := $C003
RAMWRTOFF       := $C004
RAMWRTON        := $C005
ALTZPOFF        := $C008
ALTZPON         := $C009
LCBANK1         := $C08B
AUXMOVE         := $C311
XFER            := $C314
FOUT            := $ED34
COUT            := $FDED
LD000:  sty     LD012
        sta     LD013
        stx     LD013+1
        sta     RAMRDON
        sta     RAMWRTON
        jsr     A2D
LD012:  .byte   $00
LD013:  .addr   L0000
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts

        sta     LD02C
        stx     LD02C+1
        sta     RAMRDON
        sta     RAMWRTON
        jsr     A2D
        .byte   $0E
LD02C:  .addr   L0000
        ldy     #$19
        lda     #$E9
        ldx     #$E6
        jsr     LD000
        tay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts

        sty     LD052
        sta     LD053
        stx     LD053+1
        sta     RAMRDON
        sta     RAMWRTON
        jsr     UNKNOWN_CALL
LD052:  .byte   $00
LD053:  .addr   L0000
        tay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts

        sta     RAMRDON
        sta     RAMWRTON
        ldx     #$00
LD066:  lda     $1F80,x
        beq     LD071
        inx
        cpx     #$7F
        bne     LD066
        rts

LD071:  inx
        txa
        dex
        tay
        lda     #$01
        sta     $1F80,x
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts

        tay
        sta     RAMRDON
        sta     RAMWRTON
        dey
        lda     #$00
        sta     $1F80,y
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts

        lda     #$80
        bne     LD09C
        lda     #$00
LD09C:  sta     LD106
        jsr     L87F6
        lda     LDE9F
        asl     a
        tax
        lda     LEC01,x
        sta     L0006
        lda     LEC02,x
        sta     $07
        sta     RAMRDON
        sta     RAMWRTON
        bit     LD106
        bpl     LD0C6
        lda     LDEA0
        ldy     #$00
        sta     (L0006),y
        jmp     LD0CD

LD0C6:  ldy     #$00
        lda     (L0006),y
        sta     LDEA0
LD0CD:  lda     LEC13,x
        sta     L0006
        lda     LEC14,x
        sta     $07
        bit     LD106
        bmi     LD0EC
        ldy     #$00
LD0DE:  cpy     LDEA0
        beq     LD0FC
        lda     (L0006),y
        sta     LDEA1,y
        iny
        jmp     LD0DE

LD0EC:  ldy     #$00
LD0EE:  cpy     LDEA0
        beq     LD0FC
        lda     LDEA1,y
        sta     (L0006),y
        iny
        jmp     LD0EE

LD0FC:  sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     L8813
        rts

LD106:  brk
        rts

        sta     RAMRDON
        sta     RAMWRTON
        jsr     A2D
        .byte   $05
        .addr   L0006
        lda     LEC25
        asl     a
        tax
        lda     LDFA1,x
        sta     $08
        lda     LDFA2,x
        sta     $09
        lda     $08
        clc
        adc     #$14
        sta     $08
        bcc     LD12E
        inc     $09
LD12E:  ldy     #$23
LD130:  lda     (L0006),y
        sta     ($08),y
        dey
        bpl     LD130
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts

        stx     LD14C
        sta     LD14B
        sta     RAMRDON
        sta     RAMWRTON
        .byte   $AD
LD14B:  .byte   $34
LD14C:  ora     ($8D)
        .byte   $02
        cpy     #$8D
        tsb     $C0
        rts

        ldx     #$00
        sta     RAMRDON
        sta     RAMWRTON
        jsr     LB600
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts

        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        ora     ($02,x)
        .byte   $03
        tsb     $05
        asl     $07
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        ora     $D2,x
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
LD23F:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        asl     a
        brk
        asl     a
        brk
        .byte   $FF
        .byte   $FF
LD26F:  bbs7    $FF,$D271
LD272:  bbs7    $FF,$D274
LD275:  bbs7    L0000,$D278
        brk
        brk
        brk
        ora     ($01,x)
        brk
        brk
        brk
        dey
        .byte   $FF
        .byte   $FF
LD283:  bbs7    $FF,$D285
LD286:  .byte   $FF
        .byte   $FF
LD288:  .byte   $FF
LD289:  bbs7    L0000,$D28C
        brk
        brk
        brk
        brk
        brk
        brk
        bbs7    $55,LD23F
        eor     $AA,x
        eor     $AA,x
        eor     $AA,x
        bbs7    L0006,LD288
        brk
        brk
        brk
        brk
        dey
        brk
        php
        brk
        .byte   $13
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $02
        brk
        asl     L0000
        asl     $1E00
        brk
        rol     $7E00,x
        brk
        inc     a
        brk
        bmi     LD2BF
LD2BF:  bmi     LD2C1
LD2C1:  rts

        brk
        brk
        brk
        .byte   $03
        brk
        rmb0    L0000
        bbr0    L0000,LD2EB
        brk
        bbr3    L0000,LD34F
        brk
        bbr7    $01,LD353
        brk
        sei
        brk
        sei
        brk
        bvs     LD2DC
        .byte   $70
LD2DC:  ora     ($01,x)
        ora     (L0000,x)
        brk
        lsr     $01
        plp
        brk
        bpl     LD2E7
LD2E7:  bpl     LD2E9
LD2E9:  bpl     LD2EB
LD2EB:  bpl     LD2ED
LD2ED:  bpl     LD2EF
LD2EF:  plp
        brk
        lsr     $01
        brk
        brk
        brk
        brk
        lsr     $01
        bbr6    L0003,LD37A
        ora     ($38,x)
        brk
        sec
        brk
        sec
        brk
        sec
        brk
        sec
        brk
        ror     $6F01,x
        .byte   $03
        lsr     $01
        brk
        brk
        tsb     $05
        brk
        brk
        jmp     (L7C03,x)
        .byte   $03
        .byte   $02
        tsb     $42
        tsb     $32
        tsb     $0402
        .byte   $02
        tsb     $7C
        .byte   $03
        jmp     (L0003,x)
        brk
        brk
        brk
        jmp     (L7E03,x)
        rmb0    $7E
        rmb0    $7F
        bbr0    $7F,LD342
        bbr7    $1F,LD3B5
        bbr0    $7F,LD348
        ror     $7E07,x
        rmb0    $7C
        .byte   $03
        brk
        brk
        .byte   $05
LD342:  ora     L0000
        brk
        brk
        brk
        brk
LD348:  brk
        brk
        brk
        brk
        brk
        brk
        brk
LD34F:  brk
        brk
        brk
        brk
LD353:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
LD37A:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
LD3B5:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        inc     a:$1F,x
        brk
        brk
        brk
        brk
        inc     a:$1F,x
        brk
        brk
        brk
        brk
        inc     a:$1F,x
        brk
        brk
        brk
        brk
        inc     a:$1F,x
        bbs7    $FF,LD4E7
LD4E7:  brk
        asl     $401F,x
        rmb0    $F0
        brk
        brk
        asl     $601F,x
        .byte   $03
        rts

        brk
        brk
        inc     $F01F,x
        .byte   $F3
        bbr4    L0000,LD4FD
LD4FD:  inc     $F81F,x
        .byte   $F3
        bbr4    L0000,LD504
LD504:  inc     $FC1F,x
        bbs7    $4F,LD50A
LD50A:  brk
        inc     $FC1F,x
        bbs7    $67,LD511
LD511:  brk
        inc     $FC1F,x
        bbs7    $F3,LD518
LD518:  brk
        inc     $FC1F,x
        bbs7    $F9,LD51F
LD51F:  brk
        inc     $FC1F,x
        bbs7    $FC,LD526
LD526:  brk
        inc     $FC1F,x
        bbr3    $FE,LD52D
LD52D:  brk
        inc     $FC1F,x
        bbr1    $FF,LD534
LD534:  brk
        inc     $FC1F,x
        bbr1    $FF,LD53B
LD53B:  brk
        .byte   $3E
LD53D:  brk
        inc     $FFFF,x
        brk
LD542:  brk
        inc     $FF03,x
        bbr1    $FF,LD549
LD549:  brk
        inc     $FF43,x
        bbs7    $FF,LD550
LD550:  brk
        asl     $FF60
        bbs7    $3F,LD557
LD557:  brk
        inc     a:L0003,x
        brk
        brk
        brk
        brk
        inc     a:L0003,x
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        plp
        brk
        php
        brk
        cmp     $D4
        rmb0    L0000
        brk
        brk
LD577:  brk
        brk
        bit     L0000
        rmb1    L0000
        bbr0    $01,LD580
LD580:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        stx     L0000,y
        and     (L0000)
        .byte   $F4
        ora     ($8C,x)
        brk
        .byte   $4B
        brk
        .byte   $23
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        bcc     LD5A0
        .byte   $64
LD5A0:  brk
        .byte   $FF
        .byte   $FF
LD5A3:  bbs7    $FF,$D5A5
LD5A6:  bbs7    $FF,$D5A8
LD5A9:  bbs7    L0000,$D5AC
        brk
        brk
        brk
        ora     ($01,x)
LD5B1:  brk
        bbr7    L0000,LD53D
        brk
        brk
        ora     ($01)
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        stx     L0000,y
        and     (L0000)
        .byte   $F4
        ora     ($8C,x)
        brk
        ora     $1400,y
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        .byte   $F4
        ora     ($99,x)
        brk
        .byte   $FF
        .byte   $FF
LD5DD:  bbs7    $FF,$D5DF
LD5E0:  bbs7    $FF,$D5E2
LD5E3:  bbs7    L0000,$D5E6
        brk
        brk
        brk
        ora     ($01,x)
LD5EB:  brk
        bbr7    L0000,LD577
        brk
        brk
        ora     $01,x
        brk
        brk
        brk
        cmp     (L0000,x)
        brk
        .byte   $03
        brk
        brk
        brk
        stz     L0000
        lsr     L0000
        stz     L0000
        lsr     L0000
        and     L0000,x
        and     (L0000)
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        adc     $4600,x
        brk
        .byte   $FF
        .byte   $FF
LD617:  bbs7    $FF,$D619
LD61A:  bbs7    $FF,$D61C
LD61D:  bbs7    L0000,$D620
        brk
        brk
        brk
        ora     ($01,x)
LD625:  brk
        bbr7    L0000,LD5B1
        brk
        brk
        clc
        ora     (L0000,x)
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        stx     L0000,y
        and     (L0000)
        .byte   $F4
        ora     ($8C,x)
        brk
        bvc     LD641
LD641:  plp
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        bcc     LD64E
        .byte   $6E
LD64E:  brk
        .byte   $FF
        .byte   $FF
LD651:  bbs7    $FF,$D653
LD654:  bbs7    $FF,$D656
LD657:  bbs7    L0000,$D65A
        brk
        brk
        brk
        ora     ($01,x)
        brk
        bbr7    L0000,LD5EB
        brk
        brk
        .byte   $1B
        ora     (L0000,x)
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        stx     L0000,y
        and     (L0000)
        .byte   $F4
        ora     ($8C,x)
        brk
        adc     #$00
        ora     L0000,y
        jsr     L0080
        brk
        brk
        brk
        brk
        lsr     $6E01,x
        brk
        .byte   $FF
        .byte   $FF
LD68B:  bbs7    $FF,$D68D
LD68E:  bbs7    $FF,$D690
LD691:  bbs7    L0000,$D694
        brk
        brk
        brk
        ora     ($01,x)
        brk
        bbr7    L0000,LD625
        brk
        brk
        plp
        brk
        and     L0000
        pla
        ora     ($2F,x)
        brk
        and     $2E00
        brk
        plp
        brk
        and     $6800,x
        ora     ($47,x)
        brk
        and     $4600
        brk
        brk
        brk
        ora     (L0000)
        plp
        brk
        ora     (L0000)
        plp
        brk
        .byte   $23
        brk
        plp
        brk
        brk
        brk
        .byte   $4B
        brk
        .byte   $23
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        ror     $01
        stz     L0000
        brk
        tsb     L0000
        .byte   $02
        brk
        phy
        ora     ($6C,x)
        brk
        ora     L0000
        .byte   $03
        brk
        eor     $6B01,y
        brk
        asl     L0000
        asl     L0000,x
        cli
        ora     ($16,x)
        brk
        asl     L0000
        eor     $5800,y
        ora     ($59,x)
        brk
        cmp     (L0000)
        .byte   $5C
        brk
        rol     $01,x
        rmb6    L0000
        plp
        brk
        .byte   $5C
        brk
        sty     $6700
        brk
        smb5    L0000
        ror     L0000
        and     $6600
        brk
        .byte   $82
        brk
        rmb0    L0000
        .byte   $DC
        brk
        .byte   $13
        brk
        bpl     LD75B
        stz     $64
        jsr     L6E61
        jsr     L6E45
        stz     $72,x
        adc     $2E20,y
        rol     $112E
        eor     $64
        adc     #$74
        jsr     L6E61
        jsr     L6E45
        stz     $72,x
        adc     $2E20,y
        rol     $132E
        .byte   $44
        adc     $6C
        adc     $74
        adc     $20
        adc     ($6E,x)
        jsr     L6E45
        stz     $72,x
        adc     $2E20,y
        rol     $102E
        eor     ($75)
        ror     $6120
        ror     $4520
        ror     $7274
LD75B:  adc     $2E20,y
        rol     $082E
        eor     ($75)
        ror     $6C20
        adc     #$73
        stz     $2D,x
        eor     $6E
        stz     $65,x
        adc     ($20)
        stz     $68,x
        adc     $20
        ror     $75
        jmp     (L206C)

        bvs     LD7DC
        stz     $68,x
        ror     $6D61
        adc     $20
        bbr6    $66,LD7A5
        stz     $68,x
        adc     $20
        adc     ($75)
        ror     $6C20
        adc     #$73
        stz     $20,x
        ror     $69
        jmp     (L3A65)

        lsr     $45
        ror     $6574
        adc     ($20)
        stz     $68,x
        adc     $20
        ror     $6D61
LD7A5:  adc     $20
        plp
        and     ($34),y
        jsr     L6863
        adc     ($72,x)
        adc     ($63,x)
        stz     $65,x
        adc     ($73)
        jsr     L616D
        sei
        and     #$20
        jsr     L6F79
        adc     $20,x
        rmb7    $69
        .byte   $73
        pla
        jsr     L6F74
        jsr     L7061
        bvs     LD831
        adc     ($72,x)
        jsr     L6E69
        jsr     L6874
        adc     $20
        adc     ($75)
        ror     $6C20
        .byte   $69
LD7DC:  .byte   $73
        stz     $17,x
        eor     ($64,x)
        stz     $20
        adc     ($20,x)
        ror     $7765
        jsr     L6E65
        stz     $72,x
        adc     $7420,y
        bbr6    $20,LD867
        pla
        adc     $3A
        .byte   $0B
        bbr1    $31,LD81A
        eor     ($75)
        ror     $6C20
        adc     #$73
        stz     $11,x
        bbr1    $32,LD826
        bbr4    $74,LD871
        adc     $72
        jsr     L7552
        ror     $6C20
        adc     #$73
        stz     $0A,x
        .byte   $44
        bbr6    $77,LD887
        .byte   $20
LD81A:  jmp     (L616F)

        stz     $3A
        bpl     LD840
        .byte   $33
        jsr     L7461
        .byte   $20
LD826:  ror     $69
        adc     ($73)
        stz     $20,x
        .byte   $62
        bbr6    $6F,LD8A4
        .byte   $0F
LD831:  bbr1    $34,LD854
        adc     ($74,x)
        jsr     L6966
        adc     ($73)
        stz     $20,x
        adc     $73,x
        .byte   $65
LD840:  php
        bbr1    $35,LD864
        ror     $7665
        adc     $72
        and     L6E45
        stz     $65,x
        adc     ($20)
        stz     $68,x
        adc     $20
LD854:  ror     $75
        jmp     (L206C)

        bvs     LD8BC
        stz     $68,x
        ror     $6D61
        adc     $20
        .byte   $6F
        .byte   $66
LD864:  jsr     L6874
LD867:  adc     $20
        adc     ($75)
        ror     $6C20
        adc     #$73
        .byte   $74
LD871:  jsr     L6966
        jmp     (L3A65)

        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        asl     L0000
        rmb1    L0000
        cli
        ora     ($57,x)
        brk
LD887:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        bit     $74
        pla
        adc     $20
        .byte   $44
        bbr4    $53,LD8BA
        .byte   $33
        rol     $2033
        stz     $69
        .byte   $73
        .byte   $6B
        .byte   $20
        .byte   $69
LD8A4:  ror     $7320
        jmp     (L746F)

        jsr     L2020
        stz     $72
        adc     #$76
        adc     $20
        jsr     L3F20
        inc     a
        .byte   $22
        .byte   $1C
        .byte   $74
LD8BA:  pla
        .byte   $65
LD8BC:  jsr     L6964
        .byte   $73
        .byte   $6B
        jsr     L6E69
        jsr     L6C73
        bbr6    $74,LD8EA
        jsr     L6420
        adc     ($69)
        ror     $65,x
        jsr     L2020
        bbr3    $12,LD8F1
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $14
LD8EA:  brk
        brk
        brk
        brk
        ora     (L0006,x)
        brk
LD8F1:  brk
        brk
        brk
        brk
        brk
        ora     (L0000,x)
        .byte   $02
        jsr     L0520
        lsr     $69
        jmp     (L7365)

        rmb0    $20
        jsr     L2020
        jsr     L2020
        brk
        brk
        brk
        brk
        ora     a:L0000
        brk
        brk
        brk
        adc     a:L0000,x
        brk
        .byte   $02
        brk
        brk
        brk
        brk
        brk
        .byte   $02
        ora     ($02,x)
        brk
        brk
        rmb5    $01
        plp
        brk
        .byte   $6B
        ora     ($30,x)
        brk
        .byte   $6B
        ora     ($38,x)
        brk
        rmb5    $01
        .byte   $4B
        brk
        .byte   $6B
        ora     ($53,x)
        brk
        .byte   $6B
        ora     ($5B,x)
        brk
        .byte   $6B
        ora     ($63,x)
        brk
        phy
        ora     ($29,x)
        brk
        stz     $01
        bbr2    L0000,LD9A1
        ora     ($31,x)
        brk
        stz     $01
        rmb3    L0000
        phy
        ora     ($4C,x)
        brk
        stz     $01
        eor     (L0000)
        phy
        ora     ($54,x)
        brk
        stz     $01
        phy
        brk
        phy
        ora     ($5C,x)
        brk
        stz     $01
        .byte   $62
        brk
        phy
        ora     ($29,x)
        brk
        cpx     #$01
        bmi     LD96E
LD96E:  phy
        ora     ($31,x)
        brk
        cpx     #$01
        rmb3    L0000
        phy
        ora     ($4C,x)
        brk
        cpx     #$01
        .byte   $53
        brk
        phy
        ora     ($54,x)
        brk
        cpx     #$01
        .byte   $5B
        brk
        phy
        ora     ($5C,x)
        brk
        cpx     #$01
        .byte   $63
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
LD9A1:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        tsb     L0000
        .byte   $02
        brk
        beq     LD9C7
        .byte   $97
LD9C7:  brk
        .byte   $1B
        brk
        bpl     LD9CC
LD9CC:  ldx     $1A00
        brk
        cmp     (L0000,x)
        dec     a
        brk
        and     $01
        eor     L0000
        cmp     (L0000,x)
        eor     $2500,y
        ora     ($64,x)
        brk
        cmp     (L0000,x)
        bit     $2500
        ora     ($37,x)
        brk
LD9E8:  cmp     (L0000,x)
        eor     #$00
        and     $01
        .byte   $54
        brk
        cmp     (L0000,x)
        asl     $2500,x
        ora     ($29,x)
        brk
        .byte   $43
        ora     ($1E,x)
        brk
        .byte   $43
        ora     ($64,x)
        brk
        sta     ($D3,x)
        brk
        dec     L0000
        .byte   $63
        brk
        bbr0    $4F,LDA55
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        ora     a:$C6
        .byte   $44
        brk
        ora     $43
        jmp     (L736F)

        .byte   $65,$C6,$00,$36,$00,$04,$4F,$70
        .byte   $65,$6E,$C6,$00,$53,$00,$11,$43
        .byte   $61,$6E,$63,$65,$6C,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$45,$73,$63
        .byte   $C6,$00,$28,$00,$0C,$43,$68,$61
        .byte   $6E,$67,$65,$20,$44,$72,$69,$76
        .byte   $65,$1C,$00,$19,$00
LDA55:  .byte   $1C,$00,$70,$00,$1C,$00,$87,$00
        .byte   $00,$7F,$07,$20,$44,$69,$73,$6B
        .byte   $3A,$20,$0F,$43,$6F,$70,$79,$20
        .byte   $61,$20,$46,$69,$6C,$65,$20,$2E
        .byte   $2E,$2E,$10,$53,$6F,$75,$72,$63
        .byte   $65,$20,$66,$69,$6C,$65,$6E,$61
        .byte   $6D,$65,$3A,$15,$44,$65,$73,$74
        .byte   $69,$6E,$61,$74,$69,$6F,$6E,$20
        .byte   $66,$69,$6C,$65,$6E,$61,$6D,$65
        .byte   $3A,$1C,$00,$71,$00,$CF
LDAA3:  .byte   $01,$7C,$00,$1E,$00,$7B,$00,$1C
        .byte   $00,$88,$00,$CF,$01,$93,$00,$1E
        .byte   $00,$92,$00,$11,$44,$65,$6C,$65
        .byte   $74,$65,$20,$61,$20,$46,$69,$6C
        .byte   $65,$20,$2E,$2E,$2E,$0F,$46,$69
        .byte   $6C,$65,$20,$74,$6F,$20,$64,$65
        .byte   $6C,$65,$74,$65,$3A,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00
        tsb     $23E3
        .byte   $E3
        dec     a
        .byte   $E3
        eor     ($E3),y
        pla
        .byte   $E3
        bbr7    $E3,LDAA3
        .byte   $E3
        lda     $C4E3
        .byte   $E3
        stp
        .byte   $E3
        sbc     ($E3)
        ora     #$E4
        jsr     L37E4
        cpx     $F2
        cpx     L0000
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
LDE9F:  brk
LDEA0:  brk
LDEA1:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
LDF9B:  brk
        brk
        brk
        brk
        brk
        brk
LDFA1:  brk
LDFA2:  brk
        .byte   $23
        smb6    $6F
        smb6    $BB
        smb6    $07
        inx
        .byte   $53
        inx
        bbs1    $E8,LDF9B
        inx
        rmb3    $E9
        brk
        brk
        .byte   $83
        sbc     #$C4
        sbc     #$05
        nop
        lsr     $EA
        smb0    $EA
        iny
        nop
        ora     #$EB
        lsr     a
        .byte   $EB
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        ora     a:L0000
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        bbr7    $64,LE221
LE221:  trb     $1E00
        brk
        and     (L0000)
        asl     A2D,x
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        tsb     L0000
        brk
        brk
        tsb     L0000
        brk
        tsb     L0000
        brk
        brk
        brk
        brk
        tsb     L0000
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        asl     $E3
        rti

        brk
        .byte   $13
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        tsb     a:$E3
        brk
        brk
        brk
        .byte   $23
        .byte   $E3
        brk
        brk
        brk
        brk
        dec     a
        .byte   $E3
        brk
        brk
        brk
        brk
        eor     ($E3),y
        brk
        brk
        brk
        brk
        pla
        .byte   $E3
        brk
        brk
        brk
        brk
        bbr7    $E3,LE2A7
LE2A7:  brk
        brk
        brk
        stx     $E3,y
        brk
        brk
        brk
        brk
        lda     a:$E3
        brk
        brk
        brk
        cpy     $E3
        brk
        brk
        brk
        brk
        stp
        .byte   $E3
        brk
        brk
        brk
        brk
        sbc     ($E3)
        brk
        brk
        brk
        brk
        ora     #$E4
        brk
        brk
        brk
        brk
        jsr     L00E4
        brk
        brk
        brk
        rmb3    L00E4
        rmb0    L0000
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        jmp     L00E4

        brk
        brk
        brk
        .byte   $54
        cpx     L0000
        brk
        brk
        brk
        .byte   $5C
        cpx     L0000
        brk
        brk
        brk
        stz     L00E4
        brk
        brk
        brk
        brk
        jmp     (L00E4)

        brk
        brk
        brk
        stz     L00E4,x
        brk
        brk
        brk
        brk
        jmp     (L03E4,x)
        eor     ($6C,x)
        jmp     (LE30D)

        .byte   $14
LE30D:  .byte   $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        bit     $E3
        trb     $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        .byte   $3B
        .byte   $E3
        trb     $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        eor     ($E3)
        trb     $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        .byte   $20
        .byte   $20
LE362:  jsr     L2020
        jsr     $E369
        trb     $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        bra     LE362
        trb     $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        smb1    $E3
        trb     $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        ldx     $14E3
        .byte   $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        cmp     $E3
        trb     $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        .byte   $DC
        .byte   $E3
        trb     $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        .byte   $F3
        .byte   $E3
        trb     $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        asl     a
        cpx     $14
        .byte   $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        and     (L00E4,x)
        trb     $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        sec
        cpx     $14
        .byte   $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        rmb0    $53
        jmp     (L746F)

        jsr     L2030
        rmb0    $53
        jmp     (L746F)

        jsr     L2030
        rmb0    $53
        jmp     (L746F)

        jsr     L2030
        rmb0    $53
        jmp     (L746F)

        jsr     L2030
        rmb0    $53
        jmp     (L746F)

        jsr     L2030
        rmb0    $53
        jmp     (L746F)

        jsr     L2030
        rmb0    $53
        jmp     (L746F)

        jsr     L2030
        asl     a
        .byte   $E3
        and     ($E3,x)
        sec
        .byte   $E3
        bbr4    $E3,LE4F3
        .byte   $E3
        adc     $94E3,x
        .byte   $E3
        .byte   $AB
        .byte   $E3
        .byte   $C2
        .byte   $E3
        cmp     $F0E3,y
        .byte   $E3
        rmb0    L00E4
        asl     $35E4,x
        cpx     $13
        bvc     LE515
        bbr6    $46,LE50F
        jmp     (L2065)

        .byte   $53
        jmp     (L746F)

        jsr     L2078
        jsr     L2020
        jsr     L5513
        ror     $4469
        adc     #$73
        .byte   $6B
        jsr     L2E33
        and     $20,x
        jsr     L7853
        bit     $2079
        jsr     L5214
        eor     ($4D,x)
        .byte   $43
        adc     ($72,x)
        stz     $20
        .byte   $53
        jmp     (L746F)

        jsr     L2078
        jsr     L2020
        jsr     L1420
        .byte   $53
        jmp     (L746F)

        jsr     L2020
        jsr     L7264
        adc     #$76
        adc     $20
        jsr     L2020
        jsr     L2020
        .byte   $05
LE4F3:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        lsr     $E5
        brk
        brk
        brk
        brk
        rmb5    $E5
        brk
        brk
        brk
        brk
        adc     #$E5
        ora     (L0000,x)
        bmi     LE53E
        .byte   $83
LE50F:  sbc     $40
        brk
        .byte   $13
        brk
        brk
LE515:  brk
        ora     (L0000,x)
        and     ($31),y
        asl     $01DB,x
        brk
        and     ($32)
        rol     $01DB
        brk
        .byte   $33
        .byte   $33
        rol     $01DB,x
        brk
        bit     $34,x
        lsr     $01DB
        brk
        and     $35,x
        lsr     $01DB,x
        brk
        rol     $36,x
        ror     $01DB
        brk
        rmb3    $37
LE53E:  ror     $01DB,x
        brk
        sec
        sec
        stx     $10DB
        eor     ($64,x)
        stz     $20
        adc     ($6E,x)
        jsr     L6E45
        stz     $72,x
        adc     $2E20,y
        rol     $112E
        eor     $64
        adc     #$74
        jsr     L6E61
        jsr     L6E45
        stz     $72,x
        adc     $2E20,y
        rol     $192E
        .byte   $44
        adc     $6C
        adc     $74
        adc     $20
        adc     ($6E,x)
        jsr     L6E45
        stz     $72,x
        adc     $2E20,y
        rol     $202E
        jsr     L2020
        jsr     L1020
        eor     ($75)
        ror     $6120
        ror     $4520
        ror     $7274
        adc     $2E20,y
        rol     $012E
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        dec     $E5,x
        rti

        brk
        .byte   $13
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        sbc     ($E5)
        brk
        brk
        brk
        brk
        .byte   $02
        inc     L0000
        brk
        brk
        brk
        ora     ($E6)
        brk
        brk
        brk
        brk
        .byte   $22
        inc     L0000
        brk
        brk
        brk
        and     ($E6)
        brk
        brk
        brk
        brk
        .byte   $42
        inc     L0000
        brk
        brk
        brk
        eor     ($E6)
        brk
        brk
        brk
        brk
        .byte   $62
        inc     $1B
        eor     ($62,x)
        bbr6    $75,LE650
        jsr     L7041
        bvs     LE64D
        adc     $20
        eor     #$49
        jsr     L6544
        .byte   $73
        .byte   $6B
        .byte   $54
        bbr6    $70,LE60E
        rol     $2E2E
        jsr     L0000
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
LE60E:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
LE64D:  brk
        brk
        brk
LE650:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        ora     (L0000,x)
        ora     (L0000,x)
        txs
        inc     $8E
        inc     L0000
        brk
        brk
        brk
        brk
        brk
        ora     (L0000,x)
        ora     (L0000,x)
        smb3    $E6
        stx     a:$E6
        brk
        brk
        brk
        brk
        brk
        ora     (L0000,x)
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $B9,$E6,$1C,$41,$70,$70,$6C,$65
        .byte   $20,$49,$49,$20,$44,$65,$73,$6B
        .byte   $54,$6F,$70,$20,$56,$65,$72,$73
        .byte   $69,$6F,$6E,$20,$31,$2E,$31,$01
        .byte   $20,$04,$52,$69,$65,$6E,$00,$00
        brk
        eor     $A9E7,x
        smb6    $F5
        smb6    $41
        inx
        sta     LD9E8
        inx
        and     $E9
        adc     ($E9),y
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        bvs     LE6DF
LE6DF:  brk
        brk
        .byte   $8C
        brk
LE6E3:  brk
        brk
        smb6    L0000
        brk
        brk
        cpx     a:$E6
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        ora     (L0006,x)
        eor     $C1E7,x
        cmp     (L0003,x)
        brk
        .byte   $03
        brk
        brk
        brk
LE72F:  tax
        brk
        and     (L0000)
        and     ($02,x)
        bbs2    L0000,LE74C
        brk
        .byte   $1B
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        clv
        ora     ($78,x)
        brk
        .byte   $FF
        .byte   $FF
LE749:  bbs7    $FF,$E74B
LE74C:  .byte   $FF
        .byte   $FF
LE74E:  bbs7    $FF,$E751
        brk
LE752:  brk
        brk
        brk
        ora     ($01,x)
        brk
        bbr7    L0000,LE6E3
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $02
        asl     $A9
        smb6    $C1
        cmp     (L0003,x)
        brk
        .byte   $03
        brk
        brk
        brk
LE77B:  tax
        brk
        and     (L0000)
        and     ($02,x)
        bbs2    L0000,LE798
        brk
        .byte   $1B
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        clv
        ora     ($78,x)
        brk
        .byte   $FF
        .byte   $FF
LE795:  bbs7    $FF,$E797
LE798:  .byte   $FF
        .byte   $FF
LE79A:  bbs7    $FF,$E79D
        brk
LE79E:  brk
        brk
        brk
        ora     ($01,x)
        brk
        bbr7    L0000,LE72F
FSUB:   brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $03
        asl     $F5
FADD:   smb6    $C1
        cmp     (L0003,x)
        brk
        .byte   $03
        brk
        brk
        brk
LE7C7:  tax
        brk
        and     (L0000)
        and     ($02,x)
        bbs2    L0000,LE7E4
        brk
        .byte   $1B
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        clv
        ora     ($78,x)
        brk
        .byte   $FF
        .byte   $FF
LE7E1:  bbs7    $FF,$E7E3
LE7E4:  .byte   $FF
        .byte   $FF
LE7E6:  bbs7    $FF,$E7E9
        brk
LE7EA:  brk
        brk
        brk
        ora     ($01,x)
        brk
        bbr7    L0000,LE77B
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        tsb     L0006
        eor     ($E8,x)
        cmp     ($C1,x)
        .byte   $03
        brk
        .byte   $03
        brk
        brk
        brk
LE813:  tax
        brk
        and     (L0000)
        and     ($02,x)
        bbs2    L0000,LE830
        brk
        .byte   $1B
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        clv
        ora     ($78,x)
        brk
        .byte   $FF
        .byte   $FF
LE82D:  bbs7    $FF,$E82F
LE830:  .byte   $FF
        .byte   $FF
LE832:  bbs7    $FF,$E835
        brk
LE836:  brk
        brk
        brk
        ora     ($01,x)
        brk
        bbr7    L0000,LE7C7
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        ora     L0006
        sta     $C1E8
        cmp     (L0003,x)
        brk
        .byte   $03
        brk
        brk
        brk
LE85F:  tax
        brk
        and     (L0000)
        and     ($02,x)
        bbs2    L0000,LE87C
        brk
        .byte   $1B
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        clv
        ora     ($78,x)
        brk
        .byte   $FF
        .byte   $FF
LE879:  bbs7    $FF,$E87B
LE87C:  .byte   $FF
        .byte   $FF
LE87E:  bbs7    $FF,$E881
        brk
LE882:  brk
        brk
        brk
        ora     ($01,x)
        brk
        bbr7    L0000,LE813
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        asl     L0006
        cmp     $C1E8,y
        cmp     (L0003,x)
        brk
        .byte   $03
        brk
        brk
        brk
LE8AB:  tax
        brk
        and     (L0000)
        and     ($02,x)
        bbs2    L0000,LE8C8
        brk
        .byte   $1B
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        clv
        ora     ($78,x)
        brk
        .byte   $FF
        .byte   $FF
LE8C5:  bbs7    $FF,$E8C7
LE8C8:  .byte   $FF
        .byte   $FF
LE8CA:  bbs7    $FF,$E8CD
        brk
LE8CE:  brk
        brk
        brk
        ora     ($01,x)
        brk
        bbr7    L0000,LE85F
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        rmb0    L0006
        and     $E9
        cmp     ($C1,x)
        .byte   $03
        brk
        .byte   $03
        brk
        brk
        brk
LE8F7:  tax
        brk
        and     (L0000)
        and     ($02,x)
        bbs2    L0000,LE914
        brk
        .byte   $1B
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        clv
        ora     ($78,x)
        brk
        .byte   $FF
        .byte   $FF
LE911:  bbs7    $FF,$E913
LE914:  .byte   $FF
        .byte   $FF
LE916:  bbs7    $FF,$E919
        brk
LE91A:  brk
        brk
        brk
        ora     ($01,x)
        brk
        bbr7    L0000,LE8AB
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        php
        asl     $71
        sbc     #$C1
        cmp     (L0003,x)
        brk
        .byte   $03
        brk
        brk
        brk
        tax
        brk
        and     (L0000)
        and     ($02,x)
        bbs2    L0000,LE960
        brk
        .byte   $1B
        brk
        brk
        jsr     L0080
        brk
        brk
        brk
        brk
        clv
        ora     ($78,x)
        brk
        .byte   $FF
        .byte   $FF
LE95D:  bbs7    $FF,$E95F
LE960:  .byte   $FF
        .byte   $FF
LE962:  bbs7    $FF,$E965
        brk
LE966:  brk
        brk
        brk
        ora     ($01,x)
        brk
        bbr7    L0000,LE8F7
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
FMULT:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
FDIV:   brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
ROUND:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
FLOAT:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        asl     $20
        eor     #$74
        adc     $6D
        .byte   $73
        php
        brk
        asl     a
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        ora     #$4B
        jsr     L6E69
        jsr     L6964
        .byte   $73
        .byte   $6B
        .byte   $0B
        .byte   $4B
        jsr     L7661
        adc     ($69,x)
        jmp     (L6261)

        jmp     (L0665)

        jsr     L2020
        jsr     L2020
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
LEC01:  brk
LEC02:  .byte   $1B
        bra     LEC20
        brk
        trb     $1C80
        brk
        ora     $1D80,x
        brk
        asl     $1E80,x
        brk
        .byte   $1F
LEC13:  .byte   $01
LEC14:  .byte   $1B
        sta     ($1B,x)
        ora     ($1C,x)
        sta     ($1C,x)
        ora     ($1D,x)
        sta     ($1D,x)
        .byte   $01
LEC20:  asl     $1E81,x
        ora     ($1F,x)
LEC25:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
FIN:    brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $F4
        ora     ($A0,x)
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
