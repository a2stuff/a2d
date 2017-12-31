        .setcpu "65C02"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"
        .include "../a2d.inc"
        .include "../desktop.inc"

L0000           := $0000
L0006           := $0006
L0020           := $0020
L0800           := $0800
L0CB8           := $0CB8
L0CD7           := $0CD7
L0CF9           := $0CF9
L0D14           := $0D14
L2710           := $2710

        ;; Various Main>Aux relays and routines
LD01C           := $D01C
LD05E           := $D05E
LD082           := $D082
LD096           := $D096
LD09A           := $D09A
LD108           := $D108
LD13E           := $D13E
LD154           := $D154
LD156           := $D156

        .org $4000

L4000:   jmp     L4042

L4003:  jmp     A2D_RELAY

L4006:  jmp     L8259

L4009:  jmp     L830F

        jmp     L5E78

        jmp     LD13E

L4012:  jmp     L5050

L4015:  jmp     L40F2

L4018:  jmp     DESKTOP_RELAY

        jmp     L8E81

L401E:  jmp     L6D2B

L4021:  jmp     L46BA

        jmp     LD09A

        jmp     LD096

        jmp     L490E

L402D:  jmp     L8707

L4030:  jmp     LD154

L4033:  jmp     LD156

        jmp     L46DE

        jmp     L489A

        jmp     L488A

        jmp     L8E89

L4042:  cli
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        jsr     L4530
        ldx     #$00
L4051:  cpx     $DEA0
        beq     L4069
        txa
        pha
        lda     $DEA1,x
        jsr     L86E3
        ldy     #$01
        jsr     DESKTOP_RELAY
        pla
        tax
        inx
        jmp     L4051

L4069:  lda     #$00
        sta     $DE9F
        jsr     LD096
        lda     #$00
        sta     $D2A9
        sta     $D2AA
        sta     L40DF
        sta     $E26F
        lda     L599F
        beq     L4088
        tay
        jsr     LD154
L4088:  jsr     L4510
        inc     L40DF
        inc     L40DF
        lda     L40DF
        cmp     $D2AB
        bcc     L40A6
        lda     #$00
        sta     L40DF
        jsr     L4563
        beq     L40A6
        jsr     L40E0
L40A6:  jsr     L464E
        jsr     L48E6
        lda     $D208
        cmp     #$01
        beq     L40B7
        cmp     #$05
        bne     L40BD
L40B7:  jsr     L43E7
        jmp     L4088

L40BD:  cmp     #$03
        bne     L40C7
        jsr     L435A
        jmp     L4088

L40C7:  cmp     #$06
        bne     L40DC
        jsr     L4510
        lda     $EC25
        sta     L40F0
        lda     #$80
        sta     L40F1
        jsr     L410D
L40DC:  jmp     L4088

L40DF:  .byte   $00
L40E0:  tsx
        stx     $E256
        sta     $E25B
        jsr     L59A0
        lda     #$00
        sta     $E25B
        rts

L40F0:  .byte   $00
L40F1:  .byte   $00
L40F2:  jsr     L4510
        lda     $EC25
        sta     L40F0
        lda     #$00
        sta     L40F1
L4100:  jsr     L48F0
        lda     $D208
        cmp     #$06
        bne     L412B
        jsr     L48E6
L410D:  jsr     L4113
        jmp     L4100

L4113:  A2D_RELAY_CALL A2D_REDRAW_WINDOW, $D209
        bne     L4151
        jsr     L4153
        A2D_RELAY_CALL $3F      ; ???
        rts

L412B:  lda     #$00
        sta     $DE9F
        jsr     LD09A
        lda     L40F0
        sta     $EC25
        beq     L4143
        bit     L4CA1
        bmi     L4143
        jsr     L4244
L4143:  bit     L40F1
        bpl     L4151
        DESKTOP_RELAY_CALL $0C, $0000
L4151:  rts

L4152:  brk
L4153:  lda     $D209
        cmp     #$09
        bcc     L415B
        rts

L415B:  sta     $EC25
        sta     $DE9F
        jsr     LD09A
        lda     #$80
        sta     L4152
        lda     $DE9F
        sta     $D212
        jsr     L4505
        jsr     L78EF
        lda     $EC25
        jsr     L8855
        jsr     LD108
        lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$16
        lda     (L0006),y
        sec
        sbc     $D217
        sta     L4242
        iny
        lda     (L0006),y
        sbc     $D218
        sta     L4243
        lda     L4242
        cmp     #$0F
        lda     L4243
        sbc     #$00
        bpl     L41CB
        jsr     L6E8A
        ldx     #$0B
        ldy     #$1F
        lda     $D215,x
        sta     (L0006),y
        dey
        dex
        lda     $D215,x
        sta     (L0006),y
        ldx     #$03
        ldy     #$17
        lda     $D215,x
        sta     (L0006),y
        dey
        dex
        lda     $D215,x
        sta     (L0006),y
L41CB:  ldx     $DE9F
        dex
        lda     $E6D1,x
        bpl     L41E2
        jsr     L6C19
        lda     #$00
        sta     L4152
        lda     $EC25
        jmp     L8874

L41E2:  lda     $DE9F
        sta     $D212
        jsr     L44F2
        jsr     L6E52
        ldx     #$07
L41F0:  lda     $D21D,x
        sta     $E230,x
        dex
        bpl     L41F0
        lda     #$00
        sta     L4241
L41FE:  lda     L4241
        cmp     $DEA0
        beq     L4227
        tax
        lda     $DEA1,x
        sta     $E22F
        DESKTOP_RELAY_CALL $0D, $E22F
        beq     L4221
        DESKTOP_RELAY_CALL $03, $E22F
L4221:  inc     L4241
        jmp     L41FE

L4227:  lda     #$00
        sta     L4152
        lda     $DE9F
        sta     $D212
        jsr     L44F2
        jsr     L6E6E
        lda     $EC25
        jsr     L8874
        jmp     L4510

L4241:  brk
L4242:  brk
L4243:  brk
L4244:  lda     $DF21
        bne     L424A
L4249:  rts

L424A:  lda     #$00
        sta     L42C3
        lda     $DF20
        beq     L42A5
        cmp     $EC25
        bne     L4249
        lda     $EC25
        sta     $D212
        jsr     L4505
        jsr     L6E8E
        ldx     #$07
L4267:  lda     $D21D,x
        sta     $E230,x
        dex
        bpl     L4267
L4270:  lda     L42C3
        cmp     $DF21
        beq     L42A2
        tax
        lda     $DF22,x
        sta     $E22F
        jsr     L8915
        DESKTOP_RELAY_CALL $0D, $E22F
        beq     L4296
        DESKTOP_RELAY_CALL $03, $E22F
L4296:  lda     $E22F
        jsr     L8893
        inc     L42C3
        jmp     L4270

L42A2:  jmp     L4510

L42A5:  lda     L42C3
        cmp     $DF21
        beq     L42A2
        tax
        lda     $DF22,x
        sta     $E22F
        DESKTOP_RELAY_CALL $03, $E22F
        inc     L42C3
        jmp     L42A5

L42C3:  .byte   $00
L42C4:  .byte   $B2
L42C5:  .byte   $4B,$0E,$49,$BF,$4B,$BF,$4B,$BF
        .byte   $4B,$BF,$4B,$BF,$4B,$BF,$4B,$BF
        .byte   $4B,$BF,$4B,$B7,$4F,$0E,$49,$EA
        .byte   $4D,$72,$4E,$50,$4F,$62,$56,$0E
        .byte   $49,$A2,$4C,$5F,$4D,$0E,$49,$50
        .byte   $50,$AA,$50,$0F,$49,$0F,$49,$0F
        .byte   $49,$0F,$49,$0E,$49,$A2,$49,$A2
        .byte   $49,$A2,$49,$A2,$49,$A2,$49,$A2
        .byte   $49,$A2,$49,$A2,$49,$F9,$50,$67
        .byte   $52,$85,$52,$A3,$52,$C1,$52,$01
        .byte   $59,$0E,$49,$40,$53,$5B,$53,$5C
        .byte   $4F,$0E,$49,$87,$53,$81,$53,$0E
        .byte   $49,$75,$53,$7B,$53,$0E,$49,$8D
        .byte   $53,$01,$59,$0E,$49,$A0,$59,$A0
        .byte   $59,$A0,$59,$A0,$59,$A0,$59,$A0
        .byte   $59,$A0,$59,$A0,$59,$D1,$5A,$D1
        .byte   $5A,$D1,$5A,$D1,$5A,$D1,$5A,$D1
        .byte   $5A,$D1,$5A
L4350:  .byte   $00,$14,$2C,$46,$50,$50,$6A,$7E
        .byte   $8C
L4359:  .byte   $00
L435A:  lda     $D20A
        bne     L4362
        jmp     L4394

L4362:  cmp     #$03
        bne     L4367
        rts

L4367:  lda     $D209
        ora     #$20
        cmp     #$68
        bne     L4373
        jmp     L5441

L4373:  bit     L4359
        bpl     L4394
        cmp     #$77
        bne     L437F
        jmp     L5702

L437F:  cmp     #$67
        bne     L4386
        jmp     L578E

L4386:  cmp     #$6D
        bne     L438D
        jmp     L579A

L438D:  cmp     #$78
        bne     L4394
        jmp     L57A6

L4394:  lda     $D209
        sta     $E25C
        lda     $D20A
        beq     L43A1
        lda     #$01
L43A1:  sta     $E25D
        A2D_RELAY_CALL $32, $E25A ; ???
L43AD:  ldx     $E25A
        bne     L43B3
        rts

L43B3:  dex
        lda     L4350,x
        tax
        ldy     $E25B
        dey
        tya
        asl     a
        sta     L43E5
        txa
        clc
        adc     L43E5
        tax
        lda     L42C4,x
        sta     L43E5
        lda     L42C5,x
        sta     L43E6
        jsr     L43E0
        A2D_RELAY_CALL $33, $E25A ; ???
        rts

L43E0:  tsx
        stx     $E256
        .byte   $4C
L43E5:  .byte   $34
L43E6:  .byte   $12
L43E7:  tsx
        stx     $E256
        A2D_RELAY_CALL A2D_QUERY_TARGET, $D209
        lda     $D20D
        bne     L4418
        jsr     L85FC
        sta     $D2AA
        lda     #$00
        sta     $D20E
        DESKTOP_RELAY_CALL $09, $D209
        lda     $D20D
        beq     L4415
        jmp     L67D7

L4415:  jmp     L68AA

L4418:  cmp     #$01
        bne     L4428
        A2D_RELAY_CALL A2D_MENU_CLICK, $E25A
        jmp     L43AD

L4428:  pha
        lda     $EC25
        cmp     $D20E
        beq     L4435
        pla
        jmp     L4459

L4435:  pla
        cmp     #$02
        bne     L4443
        jsr     L85FC
        sta     $D2AA
        jmp     L5B1C

L4443:  cmp     #$03
        bne     L444A
        jmp     L60DB

L444A:  cmp     #$04
        bne     L4451
        jmp     L619B

L4451:  cmp     #$05
        bne     L4458
        jmp     L61CA

L4458:  rts

L4459:  jmp     L445D

L445C:  brk
L445D:  jsr     L6D2B
        ldx     $D20E
        dex
        lda     $EC26,x
        sta     $E22F
        lda     $E22F
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$01
        lda     (L0006),y
        beq     L44A6
        ora     #$80
        sta     (L0006),y
        iny
        lda     (L0006),y
        and     #$0F
        sta     L445C
        jsr     L8997
        DESKTOP_RELAY_CALL $02, $E22F
        jsr     L4510
        lda     L445C
        sta     $DF20
        lda     #$01
        sta     $DF21
        lda     $E22F
        sta     $DF22
L44A6:  A2D_RELAY_CALL A2D_RAISE_WINDOW, $D20E
        lda     $D20E
        sta     $EC25
        sta     $DE9F
L44B8:  jsr     LD09A
        jsr     L6C19
        lda     #$00
        sta     $DE9F
        jsr     LD09A
        lda     #$00
        sta     $E269
        A2D_RELAY_CALL $36, $E267 ; ???
        ldx     $EC25
        dex
        lda     $E6D1,x
        and     #$0F
        sta     $E268
        inc     $E268
        lda     #$01
        sta     $E269
        A2D_RELAY_CALL $36, $E267 ; ???
        rts

L44F2:  A2D_RELAY_CALL A2D_QUERY_STATE, $D212
        A2D_RELAY_CALL A2D_SET_STATE, $D215
        rts

L4505:  A2D_RELAY_CALL A2D_QUERY_STATE, $D212
        rts

        rts

L4510:  A2D_RELAY_CALL A2D_QUERY_SCREEN, $D239
        A2D_RELAY_CALL A2D_SET_STATE, $D239
        rts

L4523:  jsr     L40F2
        DESKTOP_RELAY_CALL $0C, $0000
        rts

L4530:  ldx     #$00
        ldy     $BF31
L4535:  lda     $BF32,y
        and     #$0F
        cmp     #$0B
        beq     L4559
L453E:  dey
        bpl     L4535
        stx     L4597
        stx     L45A0
        jsr     L45B2
        ldx     L45A0
        beq     L4558
L454F:  lda     L45A0,x
        sta     L45A9,x
        dex
        bpl     L454F
L4558:  rts

L4559:  lda     $BF32,y
        inx
        sta     L4597,x
        bne     L453E
        rts

L4563:  lda     L45A0
        beq     L4579
        jsr     L45B2
        ldx     L45A0
L456E:  lda     L45A0,x
        cmp     L45A9,x
        bne     L457C
        dex
        bne     L456E
L4579:  lda     #$00
        rts

L457C:  lda     L45A0,x
        sta     L45A9,x
        lda     L4597,x
        ldy     $BF31
L4588:  cmp     $BF32,y
        beq     L4591
        dey
        bpl     L4588
        rts

L4591:  tya
        clc
        adc     #$03
        rts

        .byte   $00
L4597:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00
L45A0:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00
L45A9:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00
L45B2:  ldx     L4597
        beq     L45C6
        stx     L45A0
L45BA:  lda     L4597,x
        jsr     L45C7
        sta     L45A0,x
        dex
        bne     L45BA
L45C6:  rts

L45C7:  sta     L4637
        txa
        pha
        tya
        pha
        ldx     #$11
        lda     L4637
        and     #$80
        beq     L45D9
        ldx     #$21
L45D9:  stx     L45EC
        lda     L4637
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     L45EC
        sta     L45EC
        .byte   $AD
L45EC:  brk
        bbs3    $85,L45F7
        lda     #$00
        sta     L0006
        ldy     #$07
        .byte   $B1
L45F7:  asl     $D0
        and     $FFA0
        lda     (L0006),y
        clc
        adc     #$03
        sta     L0006
        lda     L4637
        pha
        rol     a
        pla
        php
        and     #$20
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        plp
        .byte   $69
L4612:  ora     ($8D,x)
        dec     a
        lsr     L0020
        bit     $46,x
        brk
        and     LAD46,y
        rol     $2946,x
        bpl     L4612
        tsb     $A9
        bbs7    $D0,L4629
        lda     #$00
L4629:  sta     L4638
        pla
        tay
        pla
        tax
        lda     L4638
        rts

L4634:  jmp     (L0006)

L4637:  .byte   $00
L4638:  .byte   $00,$03
L463A:  .byte   $01,$3E,$46,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00
L464E:  lda     $D343
        beq     L465E
        bit     $D344
        bmi     L4666
        jsr     L67AB
        jmp     L4666

L465E:  bit     $D344
        bmi     L4666
        jsr     L67A3
L4666:  lda     $DF21
        beq     L46A8
        lda     $DF20
        bne     L4691
        lda     $DF21
        cmp     #$02
        bcs     L4697
        lda     $DF22
        cmp     $EBFB
        bne     L468B
        jsr     L678A
        jsr     L670C
        lda     #$00
        sta     $E26F
        rts

L468B:  jsr     L6782
        jmp     L469A

L4691:  jsr     L678A
        jmp     L469A

L4697:  jsr     L6782
L469A:  bit     $E26F
        bmi     L46A7
        jsr     L6747
        lda     #$80
        sta     $E26F
L46A7:  rts

L46A8:  bit     $E26F
        bmi     L46AE
        rts

L46AE:  jsr     L678A
        jsr     L670C
        lda     #$00
        sta     $E26F
        rts

L46BA:  sty     L46CE
        sta     L46CF
        stx     L46CF+1
        php
        sei
        sta     ALTZPOFF
        sta     $C082
        jsr     MLI
L46CE:  .byte   $00
L46CF:  .addr   L0000
        sta     ALTZPON
        tax
        lda     LCBANK1
        lda     LCBANK1
        plp
        txa
        rts

L46DE:  jmp     L46F3

        .byte   $0A,$20,$02,$00
L46E5:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00
L46F3:  jsr     L488A
        ldx     #$FF
L46F8:  inx
        lda     $D355,x
        sta     $0220,x
        cpx     $D355
        bne     L46F8
        inx
        lda     #$2F
        sta     $0220,x
        ldy     #$00
L470C:  iny
        inx
        lda     $D345,y
        sta     $0220,x
        cpy     $D345
        bne     L470C
        stx     $0220
        ldy     #$C4
        lda     #$E1
        ldx     #$46
        jsr     L46BA
        beq     L472B
        jsr     LD154
        rts

L472B:  lda     L46E5
        cmp     #$FC
        bne     L4738
        jsr     L47B8
        jmp     L4755

L4738:  cmp     #$06
        bne     L4748
        lda     $C061
        ora     $C062
        bmi     L4755
        jsr     L489A
        rts

L4748:  cmp     #$FF
        beq     L4755
        cmp     #$B3
        beq     L4755
        lda     #$FA
        jsr     L4802
L4755:  DESKTOP_RELAY_CALL $06, $0000
        A2D_RELAY_CALL $3A      ; ???
        A2D_RELAY_CALL A2D_SET_MENU, $E680
        ldx     $D355
L4773:  lda     $D355,x
        sta     $0220,x
        dex
        bpl     L4773
        ldx     $D345
L477F:  lda     $D345,x
        sta     $0280,x
        dex
        bpl     L477F
        lda     #$80
        ldx     #$02
        jsr     L4842
        lda     #$20
        ldx     #$02
        jsr     L4842
        jsr     L48BE
        lda     #$90
        sta     L5B19
        lda     #$02
        sta     L5B1A
        jmp     L5AEE

        .byte   $0A,$00,$18,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00
L47B8:  ldx     $D355
        stx     L4816
L47BE:  lda     $D355,x
        sta     $1800,x
        dex
        bpl     L47BE
        inc     $1800
        ldx     $1800
        lda     #$2F
        sta     $1800,x
L47D2:  ldx     $1800
        ldy     #$00
L47D7:  inx
        iny
        lda     L4817,y
        sta     $1800,x
        cpy     L4817
        bne     L47D7
        stx     $1800
        ldy     #$C4
        lda     #$A6
        ldx     #$47
        jsr     L46BA
        bne     L47F3
        rts

L47F3:  ldx     L4816
L47F6:  lda     $1800,x
        cmp     #$2F
        beq     L4808
        dex
        bne     L47F6
L4800:  lda     #$FE
L4802:  jsr     LD154
        pla
        pla
        rts

L4808:  cpx     #$01
        beq     L4800
        stx     $1800
        dex
        stx     L4816
        jmp     L47D2

L4816:  .byte   $00
L4817:  PASCAL_STRING "Basic.system"
        .res    30, 0

L4842:  sta     L0006
        stx     $07
        ldy     #$00
        lda     (L0006),y
        tay
L484B:  lda     (L0006),y
        cmp     #$61
        bcc     L4859
        cmp     #$7B
        bcs     L4859
        and     #$DF
        sta     (L0006),y
L4859:  dey
        bne     L484B
        rts

L485D:  .byte   $00
L485E:  .byte   $E0
L485F:  .byte   $00
L4860:  .byte   $D0,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00
L488A:  jsr     L48AA
        A2D_RELAY_CALL A2D_SET_CURSOR, $D311
        jsr     L48B4
        rts

L489A:  jsr     L48AA
        A2D_RELAY_CALL A2D_SET_CURSOR, $D2AD
        jsr     L48B4
        rts

L48AA:  A2D_RELAY_CALL A2D_HIDE_CURSOR
        rts

L48B4:  A2D_RELAY_CALL A2D_SHOW_CURSOR
        rts

L48BE:  ldx     $E196
        inx
L48C2:  lda     $E196,x
        sta     $BF31,x
        dex
        bpl     L48C2
        rts

L48CC:  sta     $D2AC
        ldy     #$0C
        lda     #$AC
        ldx     #$D2
        jsr     LA500
        rts

        lda     #$88
        sta     L48E4
        lda     #$40
        sta     L48E5
        .byte   $4C
L48E4:  .byte   $34
L48E5:  .byte   $12
L48E6:  A2D_RELAY_CALL A2D_GET_INPUT, $D208
        rts

L48F0:  A2D_RELAY_CALL $2C, $D208 ; ???
        rts

L48FA:  A2D_RELAY_CALL A2D_SET_FILL_MODE, $D202
        rts

L4904:  A2D_RELAY_CALL A2D_SET_FILL_MODE, $D200
        rts

L490E:  rts

        jsr     L488A
        lda     #$02
        jsr     L8E81
        bmi     L4961
        lda     $E25B
        cmp     #$03
        bcs     L492E
        lda     #$06
        jsr     L8E81
        bmi     L4961
        lda     #$03
        jsr     L8E81
        bmi     L4961
L492E:  jsr     L489A
        lda     $E25B
        jsr     L9000
        sta     L498F
        jsr     L488A
        lda     #$08
        jsr     L8E89
        lda     $E25B
        cmp     #$04
        bne     L4961
        lda     L498F
        bpl     L4961
        jsr     L4AAD
        jsr     L4A77
        jsr     L4AFD
        bpl     L497A
        jsr     L8F24
        bmi     L4961
        jsr     L4968
L4961:  jsr     L489A
        jsr     L4523
        rts

L4968:  jsr     L4AAD
        ldx     $0840
L496E:  lda     $0840,x
        sta     $D355,x
        dex
        bpl     L496E
        jmp     L4A17

L497A:  jsr     L4AAD
        ldx     L0800
L4980:  lda     L0800,x
        sta     $D355,x
        dex
        bpl     L4980
        jsr     L4A17
        jmp     L4961

L498F:  .byte   $00,$0A
L4991:  .byte   $20
L4992:  .byte   $02,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        jmp     L49A6

L49A5:  brk
L49A6:  lda     $E25B
        sec
        sbc     #$06
        sta     L49A5
        jsr     L86A7
        clc
        adc     #$1E
        sta     L0006
        txa
        adc     #$DB
        sta     $07
        ldy     #$0F
        lda     (L0006),y
        asl     a
        bmi     L49FA
        bcc     L49E0
        jsr     L4AFD
        beq     L49FA
        lda     L49A5
        jsr     L4AEA
        beq     L49ED
        lda     L49A5
        jsr     L4A47
        jsr     L8F24
        bpl     L49ED
        jmp     L4523

L49E0:  jsr     L4AFD
        beq     L49FA
        lda     L49A5
        jsr     L4AEA
        bne     L49FA
L49ED:  lda     L49A5
        jsr     L4B5F
        sta     L0006
        stx     $07
        jmp     L4A0A

L49FA:  lda     L49A5
        jsr     L86C1
        clc
        adc     #$9E
        sta     L0006
        txa
        adc     #$DB
        sta     $07
L4A0A:  ldy     #$00
        lda     (L0006),y
        tay
L4A0F:  lda     (L0006),y
        sta     $D355,y
        dey
        bpl     L4A0F
L4A17:  ldy     $D355
L4A1A:  lda     $D355,y
        cmp     #$2F
        beq     L4A24
        dey
        bpl     L4A1A
L4A24:  dey
        sty     L4A46
        ldx     #$00
        iny
L4A2B:  iny
        inx
        lda     $D355,y
        sta     $D345,x
        cpy     $D355
        bne     L4A2B
        stx     $D345
        lda     L4A46
        sta     $D355
        lda     #$00
        jmp     L46DE

L4A46:  brk
L4A47:  pha
        jsr     L86C1
        clc
        adc     #$9E
        sta     L0006
        txa
        adc     #$DB
        sta     $07
        ldy     #$00
        lda     (L0006),y
        tay
L4A5A:  lda     (L0006),y
        sta     L0800,y
        dey
        bpl     L4A5A
        pla
        jsr     L4B5F
        sta     $08
        stx     $09
        ldy     #$00
        lda     ($08),y
        tay
L4A6F:  lda     ($08),y
        sta     $0840,y
        dey
        bpl     L4A6F
L4A77:  ldy     L0800
L4A7A:  lda     L0800,y
        cmp     #$2F
        beq     L4A84
        dey
        bne     L4A7A
L4A84:  dey
        sty     L0800
        ldy     $0840
L4A8B:  lda     $0840,y
        cmp     #$2F
        beq     L4A95
        dey
        bne     L4A8B
L4A95:  dey
        sty     $0840
        lda     #$00
        sta     L0006
        lda     #$08
        sta     $07
        lda     #$40
        sta     $08
        lda     #$08
        sta     $09
        jsr     L4D19
        rts

L4AAD:  ldy     $D355
L4AB0:  lda     $D355,y
        sta     L0800,y
        dey
        bpl     L4AB0
        lda     #$40
        ldx     #$08
        jsr     L4B15
        ldy     L0800
L4AC3:  lda     L0800,y
        cmp     #$2F
        beq     L4ACD
        dey
        bne     L4AC3
L4ACD:  dey
L4ACE:  lda     L0800,y
        cmp     #$2F
        beq     L4AD8
        dey
        bne     L4ACE
L4AD8:  dey
        ldx     $0840
L4ADC:  iny
        inx
        lda     L0800,y
        sta     $0840,x
        cpy     L0800
        bne     L4ADC
        rts

L4AEA:  jsr     L4B5F
        sta     L4991
        stx     L4992
        ldy     #$C4
        lda     #$90
        ldx     #$49
        jsr     L46BA
        rts

L4AFD:  sta     ALTZPOFF
        lda     $C083
        lda     $C083
        lda     $D3FF
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts

L4B15:  sta     L4B2B
        stx     L4B2C
        sta     ALTZPOFF
        lda     $C083
        lda     $C083
        ldx     $D3EE
L4B27:  lda     $D3EE,x
        .byte   $9D
L4B2B:  .byte   $34
L4B2C:  ora     ($CA)
        bpl     L4B27
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

        sta     L4B50
        stx     L4B51
        sta     ALTZPOFF
        lda     $C083
        lda     $C083
        ldx     $D3AD
L4B4C:  lda     $D3AD,x
        .byte   $9D
L4B50:  .byte   $34
L4B51:  ora     ($CA)
        bpl     L4B4C
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

L4B5F:  sta     L4BB0
        lda     #$76
        ldx     #$4F
        jsr     L4B15
        lda     L4BB0
        jsr     L86C1
        clc
        adc     #$9E
        sta     L0006
        txa
        adc     #$DB
        sta     $07
        ldy     #$00
        lda     (L0006),y
        sta     L4BB1
        tay
L4B81:  lda     (L0006),y
        and     #$7F
        cmp     #$2F
        beq     L4B8C
        dey
        bne     L4B81
L4B8C:  dey
L4B8D:  lda     (L0006),y
        and     #$7F
        cmp     #$2F
        beq     L4B98
        dey
        bne     L4B8D
L4B98:  dey
        ldx     L4F76
L4B9C:  inx
        iny
        lda     (L0006),y
        sta     L4F76,x
        cpy     L4BB1
        bne     L4B9C
        stx     L4F76
        lda     #$76
        ldx     #$4F
        rts

L4BB0:  brk
L4BB1:  brk
        ldy     #$00
        lda     #$00
        ldx     #$00
        jsr     LA500
        jmp     L4523

        bra     L4BE0
        bpl     L4C07
        jsr     L488A
        lda     $E25B
        sec
        sbc     #$03
        jsr     L86A7
        clc
        adc     #$F2
        sta     L0006
        txa
        adc     #$E5
        sta     $07
        ldy     #$00
        lda     (L0006),y
        tay
        clc
        .byte   $6D
        .byte   $87
L4BE0:  jmp     LAA48

L4BE3:  lda     (L0006),y
        sta     L4C88,x
        dex
        dey
        bne     L4BE3
        pla
        sta     L4C88
        ldx     L4C88
L4BF3:  lda     L4C88,x
        cmp     #$20
        bne     L4BFF
        lda     #$2E
        sta     L4C88,x
L4BFF:  dex
        bne     L4BF3
        jsr     L4C4E
        bmi     L4C4A
L4C07:  lda     L4C7C
        sta     L4C7E
        sta     L4C86
        jsr     L4C64
        jsr     L4C6D
        lda     #$80
        sta     L4CA1
        jsr     L489A
        jsr     L4510
        A2D_RELAY_CALL A2D_CONFIGURE_ZP_USE, $D2A7
        A2D_RELAY_CALL A2D_CONFIGURE_ZP_USE, $4BBE
        jsr     L0800
        A2D_RELAY_CALL A2D_CONFIGURE_ZP_USE, $D2A7
        lda     #$00
        sta     L4CA1
        jsr     L4510
        jsr     L4523
L4C4A:  jsr     L489A
        rts

L4C4E:  ldy     #$C8
        ldx     #$4C
        lda     #$77
        jsr     L46BA
        bne     L4C5A
        rts

L4C5A:  lda     #$00
        jsr     L48CC
        beq     L4C4E
        lda     #$FF
        rts

L4C64:  ldy     #$CA
        ldx     #$4C
        lda     #$7D
        jmp     L46BA

L4C6D:  ldy     #$CC
        ldx     #$4C
        lda     #$85
        jmp     L46BA

        .byte   $00,$03,$88,$4C,$00,$1C
L4C7C:  .byte   $00,$04
L4C7E:  .byte   $00,$00,$08,$00,$14,$00,$00,$01
L4C86:  .byte   $00,$09
L4C88:  PASCAL_STRING "Desk.acc/"
        .res    15, 0
L4CA1:  .byte   $00
        jsr     L488A
        lda     #$03
        jsr     L8E81
        bmi     L4CD6
        lda     #$04
        jsr     L8E81
        bmi     L4CD6
        jsr     L489A
        lda     #$00
        jsr     L5000
        pha
        jsr     L488A
        lda     #$07
        jsr     L8E89
        jsr     L489A
        pla
        bpl     L4CCD
        jmp     L4CD6

L4CCD:  jsr     L4D19
        jsr     L4523
        jsr     L8F18
L4CD6:  pha
        jsr     L489A
        pla
        bpl     L4CE0
        jmp     L4523

L4CE0:  lda     #$C9
        ldx     #$DF
        jsr     L6FAF
        beq     L4CF1
        pha
        jsr     L6F0D
        pla
        jmp     L5E78

L4CF1:  ldy     #$01
L4CF3:  iny
        lda     $DFC9,y
        cmp     #$2F
        beq     L4D01
        cpy     $DFC9
        bne     L4CF3
        iny
L4D01:  dey
        sty     $DFC9
        lda     #$C9
        ldx     #$DF
        jsr     L6FB7
        lda     #$C9
        ldx     #$DF
        ldy     $DFC9
        jsr     L6F4B
        jmp     L4523

L4D19:  ldy     #$00
        lda     (L0006),y
        tay
L4D1E:  lda     (L0006),y
        sta     $E00A,y
        dey
        bpl     L4D1E
        ldy     #$00
        lda     ($08),y
        tay
L4D2B:  lda     ($08),y
        sta     $DFC9,y
        dey
        bpl     L4D2B
        lda     #$C9
        ldx     #$DF
        jsr     L6F90
        ldx     #$01
        iny
        iny
L4D3E:  lda     $DFC9,y
        sta     $E04B,x
        cpy     $DFC9
        beq     L4D4E
        iny
        inx
        jmp     L4D3E

L4D4E:  stx     $E04B
        lda     $DFC9
        sec
        sbc     $E04B
        sta     $DFC9
        dec     $DFC9
        rts

        jsr     L488A
        lda     #$03
        jsr     L8E81
        bmi     L4D9D
        lda     #$05
        jsr     L8E81
        bmi     L4D9D
        jsr     L489A
        lda     #$01
        jsr     L5000
        pha
        jsr     L488A
        lda     #$07
        jsr     L8E89
        jsr     L489A
        pla
        bpl     L4D8A
        jmp     L4D9D

L4D8A:  ldy     #$00
        lda     (L0006),y
        tay
L4D8F:  lda     (L0006),y
        sta     $E00A,y
        dey
        bpl     L4D8F
        jsr     L4523
        jsr     L8F1B
L4D9D:  pha
        jsr     L489A
        pla
        bpl     L4DA7
        jmp     L4523

L4DA7:  lda     #$0A
        ldx     #$E0
        jsr     L6F90
        sty     $E00A
        lda     #$0A
        ldx     #$E0
        jsr     L6FAF
        beq     L4DC2
        pha
        jsr     L6F0D
        pla
        jmp     L5E78

L4DC2:  ldy     #$01
L4DC4:  iny
        lda     $E00A,y
        cmp     #$2F
        beq     L4DD2
        cpy     $E00A
        bne     L4DC4
        iny
L4DD2:  dey
        sty     $E00A
        lda     #$0A
        ldx     #$E0
        jsr     L6FB7
        lda     #$0A
        ldx     #$E0
        ldy     $E00A
        jsr     L6F4B
        jmp     L4523

        ldx     #$00
L4DEC:  cpx     $DF21
        bne     L4DF2
        rts

L4DF2:  txa
        pha
        lda     $DF22,x
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     (L0006),y
        and     #$70
        bne     L4E10
        ldy     #$00
        lda     (L0006),y
        jsr     L6A8A
        jmp     L4E14

L4E10:  cmp     #$40
        bcc     L4E1A
L4E14:  pla
        tax
        inx
        jmp     L4DEC

L4E1A:  sta     L4E71
        lda     $DF21
        cmp     #$02
        bcs     L4E14
        pla
        lda     $EC25
        jsr     L86FB
        sta     L0006
        stx     $07
        ldy     #$00
        lda     (L0006),y
        tay
L4E34:  lda     (L0006),y
        sta     $D355,y
        dey
        bpl     L4E34
        lda     $DF22
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$09
        lda     (L0006),y
        tax
        clc
        adc     #$09
        tay
        dex
        dey
L4E51:  lda     (L0006),y
        sta     $D344,x
        dey
        dex
        bne     L4E51
        ldy     #$09
        lda     (L0006),y
        tax
        dex
        dex
        stx     $D345
        lda     L4E71
        cmp     #$20
        bcc     L4E6E
        lda     L4E71
L4E6E:  jmp     L46DE

L4E71:  brk
L4E72:  lda     $EC25
        bne     L4E78
        rts

L4E78:  jsr     L6D2B
        dec     $EC2E
        lda     $EC25
        sta     $DE9F
        jsr     LD09A
        ldx     $EC25
        dex
        lda     $E6D1,x
        bmi     L4EB4
        DESKTOP_RELAY_CALL $07, $EC25
        lda     $DD9E
        sec
        sbc     $DEA0
        sta     $DD9E
        ldx     #$00
L4EA5:  cpx     $DEA0
        beq     L4EB4
        lda     $DEA1,x
        jsr     LD082
        inx
        jmp     L4EA5

L4EB4:  ldx     #$00
        txa
L4EB7:  sta     $DEA1,x
        cpx     $DEA0
        beq     L4EC3
        inx
        jmp     L4EB7

L4EC3:  sta     $DEA0
        jsr     LD096
        lda     #$00
        sta     $DE9F
        jsr     LD09A
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $EC25
        ldx     $EC25
        dex
        lda     $EC26,x
        sta     $E22F
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     (L0006),y
        and     #$7F
        sta     (L0006),y
        and     #$0F
        sta     $DF20
        jsr     L8997
        DESKTOP_RELAY_CALL $02, $E22F
        jsr     L4510
        lda     #$01
        sta     $DF21
        lda     $E22F
        sta     $DF22
        ldx     $EC25
        dex
        lda     $EC26,x
        jsr     L7345
        ldx     $EC25
        dex
        lda     #$00
        sta     $EC26,x
        A2D_RELAY_CALL A2D_QUERY_TOP, $EC25
        lda     $EC25
        bne     L4F3C
        DESKTOP_RELAY_CALL $0C, $0000
L4F3C:  lda     #$00
        sta     $E269
        A2D_RELAY_CALL $36, $E267 ; ???
        jsr     L66A2
        jmp     L4510

L4F50:  lda     $EC25
        beq     L4F5B
        jsr     L4E72
        jmp     L4F50

L4F5B:  rts

        lda     #$00
        jsr     L8E81
        bmi     L4F66
        jmp     L0800

L4F66:  rts

L4F67:  .byte   $00
L4F68:  .byte   $00
L4F69:  .byte   $00,$07,$76,$4F,$C3,$0F,$00,$00
        .byte   $0D
L4F72:  .byte   $00,$00,$00,$00
L4F76:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00
        lda     $EC25
        sta     L4F67
        ldy     #$03
        lda     #$67
        ldx     #$4F
        jsr     LA500
L4FC6:  lda     $EC25
        beq     L4FD4
        jsr     L86FB
        sta     L4F68
        stx     L4F69
L4FD4:  lda     #$80
        sta     L4F67
        ldy     #$03
        lda     #$67
        ldx     #$4F
        jsr     LA500
        beq     L4FE7
        jmp     L504B

L4FE7:  stx     $07
        stx     L504F
        sty     L0006
        sty     L504E
        ldy     #$00
        lda     (L0006),y
        tay
L4FF6:  lda     (L0006),y
        sta     L4F76,y
        dey
        bpl     L4FF6
        ldx     #$03
L5000:  lda     $BF90,x
        sta     L4F72,x
        dex
        bpl     L5000
        ldy     #$C0
        lda     #$6A
        ldx     #$4F
        jsr     L46BA
        beq     L5027
        jsr     LD154
        lda     L504E
        sta     L4F68
        lda     L504F
        sta     L4F69
        jmp     L4FC6

        rts

L5027:  lda     #$40
        sta     L4F67
        ldy     #$03
        lda     #$67
        ldx     #$4F
        jsr     LA500
        lda     #$76
        ldx     #$4F
        jsr     L6F90
        sty     L4F76
        lda     #$76
        ldx     #$4F
        jsr     L6FAF
        beq     L504B
        jsr     L5E78
L504B:  jmp     L4523

L504E:  brk
L504F:  brk
L5050:  lda     $DF20
        beq     L5056
L5055:  rts

L5056:  lda     $DF21
        beq     L5055
        cmp     #$01
        bne     L5067
        lda     $DF22
        cmp     $EBFB
        beq     L5055
L5067:  lda     #$00
        tax
        tay
L506B:  lda     $DF22,y
        cmp     $EBFB
        beq     L5077
        sta     $1800,x
        inx
L5077:  iny
        cpy     $DF21
        bne     L506B
        dex
        stx     L5098
        jsr     L8F15
L5084:  ldx     L5098
        lda     $1800,x
        sta     L533F
        jsr     L59A8
        dec     L5098
        bpl     L5084
        jmp     L4523

L5098:  .byte   $00
L5099:  .byte   $AF,$DE,$AD,$DE
L509D:  .byte   $18,$FB,$5C,$04,$D0,$E0
L50A3:  .byte   $04,$00,$00,$00,$00,$00,$00
        ldx     #$03
L50AC:  lda     L5099,x
        sta     $0102,x
        dex
        bpl     L50AC
        sta     ALTZPOFF
        lda     $C083
        lda     $C083
        ldx     #$05
L50C0:  lda     L509D,x
        sta     $D100,x
        dex
        bpl     L50C0
        sta     ALTZPOFF
        lda     $C082
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        sta     $C051
        sta     $C054
        sta     $C056
        sta     $C052
        sta     $C05F
        sta     $C00E
        sta     $C00C
        sta     $C000
        jsr     MLI
        .byte   $65
        .addr   L50A3
        ldx     $EC25
        bne     L50FF
        rts

L50FF:  dex
        lda     $E6D1,x
        bne     L5106
        rts

L5106:  lda     $EC25
        sta     $DE9F
        jsr     LD09A
        ldx     #$00
        txa
L5112:  cpx     $DEA0
        beq     L511E
        sta     $DEA1,x
        inx
        jmp     L5112

L511E:  sta     $DEA0
        lda     #$00
        ldx     $EC25
        dex
        sta     $E6D1,x
        jsr     L52DF
        lda     $EC25
        sta     $D212
        jsr     L4505
        jsr     L6E8E
        jsr     L4904
        A2D_RELAY_CALL A2D_FILL_RECT, $D21D
        lda     $EC25
        jsr     L7D5D
        sta     L51EB
        stx     L51EC
        sty     L51ED
        lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$1F
        lda     #$00
L5162:  sta     (L0006),y
        dey
        cpy     #$1B
        bne     L5162
        ldy     #$23
        ldx     #$03
L516D:  lda     L51EB,x
        sta     (L0006),y
        dey
        dex
        bpl     L516D
        lda     $EC25
        jsr     L763A
        lda     $EC25
        sta     $D212
        jsr     L44F2
        jsr     L6E52
        lda     #$00
        sta     L51EF
L518D:  lda     L51EF
        cmp     $DEA0
        beq     L51A7
        tax
        lda     $DEA1,x
        jsr     L86E3
        ldy     #$01
        jsr     DESKTOP_RELAY
        inc     L51EF
        jmp     L518D

L51A7:  jsr     L4510
        jsr     L6E6E
        jsr     LD096
        jsr     L6DB1
        lda     $DF20
        beq     L51E3
        lda     $DF21
        beq     L51E3
        sta     L51EF
L51C0:  ldx     L51EF
        lda     $DF21,x
        sta     $E22F
        jsr     L8915
        jsr     L6E8E
        DESKTOP_RELAY_CALL $02, $E22F
        lda     $E22F
        jsr     L8893
        dec     L51EF
        bne     L51C0
L51E3:  lda     #$00
        sta     $DE9F
        jmp     LD09A

L51EB:  brk
L51EC:  brk
L51ED:  brk
        brk
L51EF:  brk
L51F0:  ldx     $EC25
        dex
        sta     $E6D1,x
        lda     $EC25
        sta     $DE9F
        jsr     LD09A
        jsr     L7D9C
        jsr     LD096
        lda     $EC25
        sta     $D212
        jsr     L4505
        jsr     L6E8E
        jsr     L4904
        A2D_RELAY_CALL A2D_FILL_RECT, $D21D
        lda     $EC25
        jsr     L7D5D
        sta     L5263
        stx     L5264
        sty     L5265
        lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$1F
        lda     #$00
L523B:  sta     (L0006),y
        dey
        cpy     #$1B
        bne     L523B
        ldy     #$23
        ldx     #$03
L5246:  lda     L5263,x
        sta     (L0006),y
        dey
        dex
        bpl     L5246
        lda     #$80
        sta     L4152
        jsr     L4510
        jsr     L6C19
        jsr     L6DB1
        lda     #$00
        sta     L4152
        rts

L5263:  brk
L5264:  brk
L5265:  brk
        brk
        ldx     $EC25
        bne     L526D
        rts

L526D:  dex
        lda     $E6D1,x
        cmp     #$81
        bne     L5276
        rts

L5276:  cmp     #$00
        bne     L527D
        jsr     L5302
L527D:  jsr     L52DF
        lda     #$81
        jmp     L51F0

        ldx     $EC25
        bne     L528B
        rts

L528B:  dex
        lda     $E6D1,x
        cmp     #$82
        bne     L5294
        rts

L5294:  cmp     #$00
        bne     L529B
        jsr     L5302
L529B:  jsr     L52DF
        lda     #$82
        jmp     L51F0

        ldx     $EC25
        bne     L52A9
        rts

L52A9:  dex
        lda     $E6D1,x
        cmp     #$83
        bne     L52B2
        rts

L52B2:  cmp     #$00
        bne     L52B9
        jsr     L5302
L52B9:  jsr     L52DF
        lda     #$83
        jmp     L51F0

        ldx     $EC25
        bne     L52C7
        rts

L52C7:  dex
        lda     $E6D1,x
        cmp     #$84
        bne     L52D0
        rts

L52D0:  cmp     #$00
        bne     L52D7
        jsr     L5302
L52D7:  jsr     L52DF
        lda     #$84
        jmp     L51F0

L52DF:  lda     #$00
        sta     $E269
        A2D_RELAY_CALL $36, $E267 ; ???
        lda     $E25B
        sta     $E268
        lda     #$01
        sta     $E269
        A2D_RELAY_CALL $36, $E267 ; ???
        rts

L5302:  DESKTOP_RELAY_CALL $07, $EC25
        lda     $EC25
        sta     $DE9F
        jsr     LD09A
        lda     $DD9E
        sec
        sbc     $DEA0
        sta     $DD9E
        ldx     #$00
L5320:  cpx     $DEA0
        beq     L5334
        lda     $DEA1,x
        jsr     LD082
        lda     #$00
        sta     $DEA1,x
        inx
        jmp     L5320

L5334:  jsr     LD096
        lda     #$00
        sta     $DE9F
        jmp     LD09A

L533F:  brk
        lda     #$01
        jsr     L8E81
        bmi     L535A
        lda     #$04
        jsr     L0800
        bne     L5357
        stx     L533F
        jsr     L4523
        jsr     L59A4
L5357:  jmp     L4523

L535A:  rts

        lda     #$01
        jsr     L8E81
        bmi     L5372
        lda     #$05
        jsr     L0800
        bne     L5372
        stx     L533F
        jsr     L4523
        jsr     L59A4
L5372:  jmp     L4523

        jsr     L8F09
        jmp     L4523

        jsr     L8F27
        jmp     L4523

        jsr     L8F0F
        jmp     L4523

        jsr     L8F0C
        jmp     L4523

        jsr     L8F12
        pha
        jsr     L4523
        pla
        beq     L5398
        rts

L5398:  lda     $DF20
        bne     L53B5
        ldx     #$00
        ldy     #$00
L53A1:  lda     $DF22,x
        cmp     #$01
        beq     L53AC
        sta     L5428,y
        iny
L53AC:  inx
        cpx     $DF22
        bne     L53A1
        sty     L5427
L53B5:  lda     #$FF
        sta     L5426
L53BA:  inc     L5426
        lda     L5426
        cmp     $DF21
        bne     L53D0
        lda     $DF20
        bne     L53CD
        jmp     L540E

L53CD:  jmp     L5E78

L53D0:  tax
        lda     $DF22,x
        jsr     L5431
        bmi     L53BA
        jsr     L86FB
        sta     L0006
        stx     $07
        ldy     #$00
        lda     (L0006),y
        tay
        lda     L0006
        jsr     L6FB7
        lda     L704B
        beq     L53BA
L53EF:  dec     L704B
        ldx     L704B
        lda     L704C,x
        cmp     $EC25
        beq     L5403
        sta     $D20E
        jsr     L4459
L5403:  jsr     L61DC
        lda     L704B
        bne     L53EF
        jmp     L53BA

L540E:  ldx     L5427
L5411:  lda     L5428,x
        sta     L533F
        jsr     L59A8
        ldx     L5427
        dec     L5427
        dex
        bpl     L5411
        jmp     L4523

L5426:  brk
L5427:  brk
L5428:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
L5431:  ldx     #$07
L5433:  cmp     $EC26,x
        beq     L543E
        dex
        bpl     L5433
        lda     #$FF
        rts

L543E:  inx
        txa
        rts

L5441:  jmp     L544D

L5444:  brk
L5445:  brk
L5446:  brk
L5447:  brk
L5448:  brk
L5449:  brk
L544A:  brk
        brk
        brk
L544D:  lda     #$00
        sta     $1800
        .byte   $AD
L5453:  and     $EC
        bne     L545A
        jmp     L54C5

L545A:  tax
        dex
        lda     $E6D1,x
        bpl     L5464
        jmp     L54C5

L5464:  lda     $EC25
        sta     $DE9F
        jsr     LD09A
        lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$1C
L5479:  lda     (L0006),y
        sta     $E214,y
        iny
        cpy     #$24
        bne     L5479
        ldx     #$00
L5485:  cpx     $DEA0
        beq     L54BD
        txa
        pha
        lda     $DEA1,x
        sta     $E22F
        jsr     L8915
        DESKTOP_RELAY_CALL $0D, $E22F
        pha
        lda     $E22F
        jsr     L8893
        pla
        beq     L54B7
        pla
        pha
        tax
        lda     $DEA1,x
        ldx     $1800
        sta     $1801,x
        inc     $1800
L54B7:  pla
        tax
        inx
        jmp     L5485

L54BD:  lda     #$00
        sta     $DE9F
        jsr     LD09A
L54C5:  ldx     $1800
        ldy     #$00
L54CA:  lda     $DEA1,y
        sta     $1801,x
        iny
        inx
        cpy     $DEA0
        bne     L54CA
        lda     $1800
        clc
        adc     $DEA0
        sta     $1800
        lda     #$00
        sta     L544A
        lda     #$FF
        ldx     #$03
L54EA:  sta     L5444,x
        dex
        bpl     L54EA
L54F0:  ldx     L544A
L54F3:  lda     $1801,x
        asl     a
        tay
        lda     $DD9F,y
        sta     L0006
        lda     $DDA0,y
        sta     $07
        ldy     #$06
        lda     (L0006),y
        cmp     L5447
        beq     L5510
        bcc     L5532
        jmp     L5547

L5510:  dey
        lda     (L0006),y
        cmp     L5446
        beq     L551D
        bcc     L5532
        jmp     L5547

L551D:  dey
        lda     (L0006),y
        cmp     L5445
        beq     L552A
        bcc     L5532
        jmp     L5547

L552A:  dey
        lda     (L0006),y
        cmp     L5444
        bcs     L5547
L5532:  lda     $1801,x
        stx     L5449
        sta     L5448
        ldy     #$03
L553D:  lda     (L0006),y
        sta     L5441,y
        iny
        cpy     #$07
        bne     L553D
L5547:  inx
        cpx     $1800
        bne     L54F3
        ldx     L544A
        lda     $1801,x
        tay
        lda     L5448
        sta     $1801,x
        ldx     L5449
        tya
        sta     $1801,x
        lda     #$FF
        ldx     #$03
L5565:  sta     L5444,x
        dex
        bpl     L5565
        inc     L544A
        ldx     L544A
        cpx     $1800
        beq     L5579
        jmp     L54F0

L5579:  lda     #$00
        sta     L544A
        jsr     L6D2B
L5581:  jsr     L55F0
L5584:  jsr     L48E6
        lda     $D208
        cmp     #$03
        beq     L5595
        cmp     #$01
        bne     L5584
        jmp     L55D1

L5595:  lda     $D209
        and     #$7F
        cmp     #$0D
        beq     L55D1
        cmp     #$1B
        beq     L55D1
        cmp     #$08
        beq     L55BE
        cmp     #$15
        bne     L5584
        ldx     L544A
        inx
        cpx     $1800
        bne     L55B5
        ldx     #$00
L55B5:  stx     L544A
        jsr     L562C
        jmp     L5581

L55BE:  ldx     L544A
        dex
        bpl     L55C8
        ldx     $1800
        dex
L55C8:  stx     L544A
        jsr     L562C
        jmp     L5581

L55D1:  ldx     L544A
        lda     $1801,x
        sta     $DF22
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     (L0006),y
        and     #$0F
        sta     $DF20
        lda     #$01
        sta     $DF21
        rts

L55F0:  ldx     L544A
        lda     $1801,x
        sta     $E22F
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     (L0006),y
        and     #$0F
        sta     $D212
        beq     L5614
        jsr     L56F9
        lda     $E22F
        jsr     L8915
L5614:  DESKTOP_RELAY_CALL $02, $E22F
        lda     $D212
        beq     L562B
        lda     $E22F
        jsr     L8893
        jsr     L4510
L562B:  rts

L562C:  lda     $E22F
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     (L0006),y
        and     #$0F
        sta     $D212
        beq     L564A
        jsr     L56F9
        lda     $E22F
        jsr     L8915
L564A:  DESKTOP_RELAY_CALL $0B, $E22F
        lda     $D212
        beq     L5661
        lda     $E22F
        jsr     L8893
        jsr     L4510
L5661:  rts

        lda     $DF21
        beq     L566A
        jsr     L6D2B
L566A:  ldx     $EC25
        beq     L5676
        dex
        lda     $E6D1,x
        bpl     L5676
        rts

L5676:  lda     $EC25
        sta     $DE9F
        jsr     LD09A
        lda     $DEA0
        bne     L5687
        jmp     L56F0

L5687:  ldx     $DEA0
        dex
L568B:  lda     $DEA1,x
        sta     $DF22,x
        dex
        bpl     L568B
        lda     $DEA0
        sta     $DF21
        lda     $EC25
        sta     $DF20
        lda     $DF20
        sta     $E22C
        beq     L56AB
        jsr     L56F9
L56AB:  lda     $DF21
        sta     L56F8
        dec     L56F8
L56B4:  ldx     L56F8
        lda     $DF22,x
        sta     $E22B
        jsr     L86E3
        sta     L0006
        stx     $07
        lda     $E22C
        beq     L56CF
        lda     $E22B
        jsr     L8915
L56CF:  DESKTOP_RELAY_CALL $02, $E22B
        lda     $E22C
        beq     L56E3
        lda     $E22B
        jsr     L8893
L56E3:  dec     L56F8
        bpl     L56B4
        lda     $DF20
        beq     L56F0
        jsr     L4510
L56F0:  lda     #$00
        sta     $DE9F
        jmp     LD09A

L56F8:  brk
L56F9:  sta     $D212
        jsr     L4505
        jmp     L6E8E

L5702:  lda     $EC25
        bne     L5708
        rts

L5708:  sta     L0800
        ldy     #$01
        ldx     #$00
L570F:  lda     $EC26,x
        beq     L5720
        inx
        cpx     $EC25
        beq     L5721
        txa
        dex
        sta     L0800,y
        iny
L5720:  inx
L5721:  cpx     #$08
        bne     L570F
        sty     L578D
        cpy     #$01
        bne     L572D
        rts

L572D:  lda     #$00
        sta     L578C
L5732:  jsr     L48E6
        lda     $D208
        cmp     #$03
        beq     L5743
        cmp     #$01
        bne     L5732
        jmp     L578B

L5743:  lda     $D209
        and     #$7F
        cmp     #$0D
        beq     L578B
        cmp     #$1B
        beq     L578B
        cmp     #$08
        beq     L5772
        cmp     #$15
        bne     L5732
        ldx     L578C
        inx
        cpx     L578D
        bne     L5763
        ldx     #$00
L5763:  stx     L578C
        lda     L0800,x
        sta     $D20E
        jsr     L4459
        jmp     L5732

L5772:  ldx     L578C
        dex
        bpl     L577C
        ldx     L578D
        dex
L577C:  stx     L578C
        lda     L0800,x
        sta     $D20E
        jsr     L4459
        jmp     L5732

L578B:  rts

L578C:  brk
L578D:  brk
L578E:  A2D_RELAY_CALL $22      ; ???
        jmp     L619B

L579A:  A2D_RELAY_CALL $22      ; ???
        jmp     L60DB

L57A6:  jsr     L5803
L57A9:  jsr     L48E6
        lda     $D208
        cmp     #$01
        beq     L57C2
        cmp     #$03
        bne     L57A9
        lda     $D209
        cmp     #$0D
        beq     L57C2
        cmp     #$1B
        bne     L57CB
L57C2:  lda     #$00
        sta     $DE9F
        jsr     LD09A
        rts

L57CB:  bit     L585D
        bmi     L57D3
        jmp     L57E7

L57D3:  cmp     #$15
        bne     L57DD
        jsr     L582F
        jmp     L57A9

L57DD:  cmp     #$08
        bne     L57E7
        jsr     L583C
        jmp     L57A9

L57E7:  bit     L585E
        bmi     L57EF
        jmp     L57A9

L57EF:  cmp     #$0A
        bne     L57F9
        jsr     L5846
        jmp     L57A9

L57F9:  cmp     #$0B
        bne     L57A9
        jsr     L5853
        jmp     L57A9

L5803:  lda     $EC25
        sta     $DE9F
        jsr     LD09A
        ldx     $EC25
        dex
        lda     $E6D1,x
        sta     L5B1B
        jsr     L58C3
        sta     L585F
        stx     L5860
        sty     L585D
        jsr     L58E2
        sta     L5861
        stx     L5862
        sty     L585E
        rts

L582F:  lda     L585F
        ldx     L5860
        jsr     L5863
        sta     L585F
        rts

L583C:  lda     L585F
        jsr     L587E
        sta     L585F
        rts

L5846:  lda     L5861
        ldx     L5862
        jsr     L5893
        sta     L5861
        rts

L5853:  lda     L5861
        jsr     L58AE
        sta     L5861
        rts

L585D:  brk
L585E:  brk
L585F:  brk
L5860:  brk
L5861:  brk
L5862:  brk
L5863:  stx     L587D
        cmp     L587D
        beq     L587C
        sta     $D20D
        inc     $D20D
        lda     #$02
        sta     $D208
        jsr     L5C54
        lda     $D20D
L587C:  rts

L587D:  brk
L587E:  beq     L5891
        sta     $D20D
        dec     $D20D
        lda     #$02
        sta     $D208
        jsr     L5C54
        lda     $D20D
L5891:  rts

        brk
L5893:  stx     L58AD
        cmp     L58AD
        beq     L58AC
        sta     $D20D
        inc     $D20D
        lda     #$01
        sta     $D208
        jsr     L5C54
        lda     $D20D
L58AC:  rts

L58AD:  brk
L58AE:  beq     L58C1
        sta     $D20D
        dec     $D20D
        lda     #$01
        sta     $D208
        jsr     L5C54
        lda     $D20D
L58C1:  rts

        brk
L58C3:  lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$06
        lda     (L0006),y
        tax
        iny
        lda     (L0006),y
        pha
        ldy     #$04
        lda     (L0006),y
        and     #$01
        clc
        ror     a
        ror     a
        tay
        pla
        rts

L58E2:  lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$08
        lda     (L0006),y
        tax
        iny
        lda     (L0006),y
        pha
        ldy     #$05
        lda     (L0006),y
        and     #$01
        clc
        ror     a
        ror     a
        tay
        pla
        rts

        lda     #$00
        sta     L599F
        sta     $DE9F
        jsr     LD09A
        jsr     L4F50
        jsr     L6D2B
        ldx     $DEA0
        dex
L5916:  lda     $DEA1,x
        cmp     $EBFB
        beq     L5942
        txa
        pha
        lda     $DEA1,x
        sta     $E22F
        lda     #$00
        sta     $DEA1,x
        DESKTOP_RELAY_CALL $04, $E22F
        lda     $E22F
        jsr     LD082
        dec     $DEA0
        dec     $DD9E
        pla
        tax
L5942:  dex
        bpl     L5916
        ldy     #$00
        sty     L599E
L594A:  ldy     L599E
        inc     $DEA0
        inc     $DD9E
        lda     #$00
        sta     $E1A0,y
        lda     $BF32,y
        jsr     L89B6
        cmp     #$57
        bne     L5967
        lda     #$F9
        sta     L599F
L5967:  inc     L599E
        lda     L599E
        cmp     $BF31
        beq     L594A
        bcc     L594A
        ldx     #$00
L5976:  cpx     $DEA0
        bne     L5986
        lda     L599F
        beq     L5983
        jsr     LD154
L5983:  jmp     LD096

L5986:  txa
        pha
        lda     $DEA1,x
        cmp     $EBFB
        beq     L5998
        jsr     L86E3
        ldy     #$01
        jsr     DESKTOP_RELAY
L5998:  pla
        tax
        inx
        jmp     L5976

L599E:  brk
L599F:  brk
L59A0:  lda     #$00
        beq     L59AA
L59A4:  lda     #$80
        bne     L59AA
L59A8:  lda     #$C0
L59AA:  sta     L5AD0
        lda     #$00
        sta     $DE9F
        jsr     LD09A
        bit     L5AD0
        bpl     L59EA
        bvc     L59D2
        lda     L533F
        ldy     #$0F
L59C1:  cmp     $E1A0,y
        beq     L59C9
        dey
        bpl     L59C1
L59C9:  sty     L5AC6
        sty     $E25B
        jmp     L59F3

L59D2:  ldy     $BF31
        lda     L533F
L59D8:  cmp     $BF32,y
        beq     L59E1
        dey
        bpl     L59D8
        iny
L59E1:  sty     L5AC6
        sty     $E25B
        jmp     L59F3

L59EA:  lda     $E25B
        sec
        sbc     #$03
        sta     $E25B
L59F3:  ldy     $E25B
        lda     $E1A0,y
        bne     L59FE
        jmp     L5A4C

L59FE:  jsr     L86E3
        clc
        adc     #$09
        sta     L0006
        txa
        adc     #$00
        sta     $07
        ldy     #$00
        lda     (L0006),y
        tay
L5A10:  lda     (L0006),y
        sta     $1F00,y
        dey
        bpl     L5A10
        dec     $1F00
        lda     #$2F
        sta     $1F01
        lda     #$00
        ldx     #$1F
        ldy     $1F00
        jsr     L6FB7
        lda     L704B
        beq     L5A4C
L5A2F:  ldx     L704B
        beq     L5A4C
        dex
        lda     L704C,x
        cmp     $EC25
        beq     L5A43
        sta     $D20E
        jsr     L4459
L5A43:  jsr     L61DC
        dec     L704B
        jmp     L5A2F

L5A4C:  jsr     L4523
        jsr     L6D2B
        lda     #$00
        sta     $DE9F
        jsr     LD09A
        lda     $E25B
        tay
        pha
        lda     $E1A0,y
        sta     $E22F
        beq     L5A7F
        jsr     L8AF4
        dec     $DD9E
        lda     $E22F
        jsr     LD082
        jsr     L4510
        DESKTOP_RELAY_CALL $04, $E22F
L5A7F:  lda     $DEA0
        sta     L5AC6
        inc     $DEA0
        inc     $DD9E
        pla
        tay
        lda     $BF32,y
        jsr     L89B6
        bit     L5AD0
        bmi     L5AA9
        and     #$FF
        beq     L5AA9
        cmp     #$2F
        beq     L5AA9
        pha
        jsr     LD096
        pla
        jsr     LD154
        rts

L5AA9:  lda     $DEA0
        cmp     L5AC6
        beq     L5AC0
        ldx     $DEA0
        dex
        lda     $DEA1,x
        jsr     L86E3
        ldy     #$01
        jsr     DESKTOP_RELAY
L5AC0:  jsr     LD096
        jmp     L4523

L5AC6:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
L5AD0:  brk
        ldx     $E25B
        dex
        txa
        asl     a
        asl     a
        asl     a
        clc
        adc     #$06
        tax
        lda     $E44C,x
        sec
        sbc     #$30
        clc
        adc     #$C0
        sta     L5B1A
        lda     #$00
        sta     L5B19
L5AEE:  sta     ALTZPOFF
        lda     $C082
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        sta     $C051
        sta     $C054
        sta     $C056
        sta     $C052
        sta     $C05F
        sta     $C00E
        sta     $C00C
        sta     $C000
        .byte   $4C
L5B19:  brk
L5B1A:  brk
L5B1B:  brk
L5B1C:  lda     $EC25
        sta     $DE9F
        jsr     LD09A
        ldx     $EC25
        dex
        lda     $E6D1,x
        sta     L5B1B
        ldx     #$03
L5B31:  lda     $EBFD,x
        sta     $D209,x
        dex
        bpl     L5B31
        A2D_RELAY_CALL A2D_QUERY_CLIENT, $D209
        lda     $D20D
        bne     L5B4B
        jmp     L5CB7

L5B4B:  bit     $D2AA
        bmi     L5B53
        jmp     L5C26

L5B53:  cmp     #$03
        bne     L5B58
        rts

L5B58:  cmp     #$01
        bne     L5BC1
        lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$05
        lda     (L0006),y
        and     #$01
        bne     L5B71
        jmp     L5C26

L5B71:  jsr     L5803
        lda     $D20E
        cmp     #$05
        bne     L5B81
        jsr     L5C31
        jmp     L5C26

L5B81:  cmp     #$01
        bne     L5B92
L5B85:  jsr     L5853
        lda     #$01
        jsr     L5C89
        bpl     L5B85
        jmp     L5C26

L5B92:  cmp     #$02
        bne     L5BA3
L5B96:  jsr     L5846
        lda     #$02
        jsr     L5C89
        bpl     L5B96
        jmp     L5C26

L5BA3:  cmp     #$04
        beq     L5BB4
L5BA7:  jsr     L638C
        lda     #$03
        jsr     L5C89
        bpl     L5BA7
        jmp     L5C26

L5BB4:  jsr     L63EC
        lda     #$04
        jsr     L5C89
        bpl     L5BB4
        jmp     L5C26

L5BC1:  lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$04
        lda     (L0006),y
        and     #$01
        bne     L5BD6
        jmp     L5C26

L5BD6:  jsr     L5803
        lda     $D20E
        cmp     #$05
        bne     L5BE6
        jsr     L5C31
        jmp     L5C26

L5BE6:  cmp     #$01
        bne     L5BF7
L5BEA:  jsr     L583C
        lda     #$01
        jsr     L5C89
        bpl     L5BEA
        jmp     L5C26

L5BF7:  cmp     #$02
        bne     L5C08
L5BFB:  jsr     L582F
        lda     #$02
        jsr     L5C89
        bpl     L5BFB
        jmp     L5C26

L5C08:  cmp     #$04
        beq     L5C19
L5C0C:  jsr     L6451
        lda     #$03
        jsr     L5C89
        bpl     L5C0C
        jmp     L5C26

L5C19:  jsr     L64B0
        lda     #$04
        jsr     L5C89
        bpl     L5C19
        jmp     L5C26

L5C26:  jsr     LD096
        lda     #$00
        sta     $DE9F
        jmp     LD09A

L5C31:  lda     $D20D
        sta     $D208
        A2D_RELAY_CALL A2D_DRAG_SCROLL, $D208
        lda     $D20E
        bne     L5C46
        rts

L5C46:  jsr     L5C54
        jsr     LD096
        lda     #$00
        sta     $DE9F
        jmp     LD09A

L5C54:  lda     $D20D
        sta     $D209
        A2D_RELAY_CALL A2D_UPDATE_SCROLL, $D208
        jsr     L6523
        jsr     L84D1
        bit     L5B1B
        bmi     L5C71
        jsr     L6E6E
L5C71:  lda     $EC25
        sta     $D212
        jsr     L44F2
        A2D_RELAY_CALL A2D_FILL_RECT, $D21D
        jsr     L4510
        jmp     L6C19

L5C89:  sta     L5CB6
        jsr     L48F0
        lda     $D208
        cmp     #$04
        beq     L5C99
L5C96:  lda     #$FF
        rts

L5C99:  A2D_RELAY_CALL A2D_QUERY_CLIENT, $D209
        lda     $D20D
        beq     L5C96
        cmp     #$03
        beq     L5C96
        lda     $D20E
        cmp     L5CB6
        bne     L5C96
        lda     #$00
        rts

L5CB6:  brk
L5CB7:  bit     L5B1B
        bpl     L5CBF
        jmp     L6D2B

L5CBF:  lda     $EC25
        sta     $D20E
        DESKTOP_RELAY_CALL $09, $D209
        lda     $D20D
        bne     L5CDA
        jsr     L5F13
        jmp     L5DEC

L5CD9:  brk
L5CDA:  sta     L5CD9
        ldx     $DF21
        beq     L5CFB
        dex
        lda     L5CD9
L5CE6:  cmp     $DF22,x
        beq     L5CF0
        dex
        bpl     L5CE6
        bmi     L5CFB
L5CF0:  bit     $D2AA
        bmi     L5CF8
        jmp     L5DFC

L5CF8:  jmp     L5D55

L5CFB:  bit     $C061
        bpl     L5D08
        lda     $DF20
        cmp     $EC25
        beq     L5D0B
L5D08:  jsr     L6D2B
L5D0B:  ldx     $DF21
        lda     L5CD9
        sta     $DF22,x
        inc     $DF21
        lda     $EC25
        sta     $DF20
        lda     $EC25
        sta     $D212
        jsr     L44F2
        lda     L5CD9
        sta     $E22F
        jsr     L8915
        jsr     L6E8E
        DESKTOP_RELAY_CALL $02, $E22F
        lda     $EC25
        sta     $D212
        jsr     L44F2
        lda     L5CD9
        jsr     L8893
        jsr     L4510
        bit     $D2AA
        bmi     L5D55
        jmp     L5DFC

L5D55:  lda     L5CD9
        sta     $EBFC
        DESKTOP_RELAY_CALL $0A, $EBFC
        tax
        lda     $EBFC
        beq     L5DA6
        jsr     L8F00
        cmp     #$FF
        bne     L5D77
        jsr     L5DEC
        jmp     L4523

L5D77:  lda     $EBFC
        cmp     $EBFB
        bne     L5D8E
        lda     $EC25
        jsr     L6F0D
        lda     $EC25
        jsr     L5E78
        jmp     L4523

L5D8E:  lda     $EBFC
        bmi     L5D99
        jsr     L6A3F
        jmp     L4523

L5D99:  and     #$7F
        pha
        jsr     L6F0D
        pla
        jsr     L5E78
        jmp     L4523

L5DA6:  cpx     #$02
        bne     L5DAD
        jmp     L5DEC

L5DAD:  cpx     #$FF
        beq     L5DF7
        lda     $EC25
        sta     $D212
        jsr     L44F2
        jsr     L6E52
        jsr     L6E8E
        ldx     $DF21
        dex
L5DC4:  txa
        pha
        lda     $DF22,x
        sta     $E22E
        DESKTOP_RELAY_CALL $03, $E22E
        pla
        tax
        dex
        bpl     L5DC4
        lda     $EC25
        sta     $D212
        jsr     L44F2
        jsr     L6DB1
        jsr     L6E6E
        jsr     L4510
L5DEC:  jsr     LD096
        lda     #$00
        sta     $DE9F
        jmp     LD09A

L5DF7:  ldx     $E256
        txs
        rts

L5DFC:  lda     L5CD9
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     (L0006),y
        and     #$70
        cmp     #$10
        beq     L5E28
        cmp     #$20
        beq     L5E28
        cmp     #$30
        beq     L5E28
        cmp     #$00
        bne     L5E27
        lda     L5CD9
        jsr     L6A8A
        bmi     L5E27
        jmp     L5DEC

L5E27:  rts

L5E28:  sta     L5E77
        lda     $EC25
        jsr     L86FB
        sta     L0006
        stx     $07
        ldy     #$00
        lda     (L0006),y
        tay
L5E3A:  lda     (L0006),y
        sta     $D355,y
        dey
        bpl     L5E3A
        lda     L5CD9
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$09
        lda     (L0006),y
        tax
        clc
        adc     #$09
        tay
        dex
        dey
L5E57:  lda     (L0006),y
        sta     $D344,x
        dey
        dex
        bne     L5E57
        ldy     #$09
        lda     (L0006),y
        tax
        dex
        dex
        stx     $D345
        lda     L5E77
        cmp     #$20
        bcc     L5E74
        lda     L5E77
L5E74:  jmp     L46DE

L5E77:  brk
L5E78:  sta     L5F0A
        jsr     L4523
        jsr     L6D2B
        lda     L5F0A
        cmp     $EC25
        beq     L5E8F
        sta     $D20E
        jsr     L4459
L5E8F:  lda     $EC25
        sta     $D212
        jsr     L44F2
        jsr     L4904
        A2D_RELAY_CALL A2D_FILL_RECT, $D21D
        ldx     $EC25
        dex
        lda     $EC26,x
        pha
        jsr     L7345
        lda     L5F0A
        tax
        dex
        lda     $E6D1,x
        bmi     L5EBC
        jsr     L5302
L5EBC:  lda     $EC25
        jsr     L86FB
        sta     L0006
        stx     $07
        ldy     #$00
        lda     (L0006),y
        tay
L5ECB:  lda     (L0006),y
        sta     $E1B0,y
        dey
        bpl     L5ECB
        pla
        jsr     L7054
        jsr     L5106
        jsr     LD096
        lda     $EC25
        sta     $DE9F
        jsr     LD09A
        lda     $EC25
        sta     $D212
        jsr     L4505
        jsr     L78EF
        lda     #$00
        ldx     $EC25
        sta     $E6D0,x
        lda     #$01
        sta     $E25B
        jsr     L52DF
        lda     #$00
        sta     $DE9F
        jmp     LD09A

L5F0A:  brk
L5F0B:  brk
        brk
        brk
        brk
L5F0F:  brk
        brk
        brk
        brk
L5F13:  lda     #$06
        sta     L0006
        lda     #$D2
        sta     $07
        jsr     L60D5
        ldx     #$03
L5F20:  lda     $D209,x
        sta     L5F0B,x
        sta     L5F0F,x
        dex
        bpl     L5F20
        jsr     L48F0
        lda     $D208
        cmp     #$04
        beq     L5F3F
        bit     $C061
        bmi     L5F3E
        jsr     L6D2B
L5F3E:  rts

L5F3F:  jsr     L6D2B
        lda     $EC25
        sta     $D212
        jsr     L4505
        jsr     L6E8E
        ldx     #$03
L5F50:  lda     L5F0B,x
        sta     $E230,x
        lda     L5F0F,x
        sta     $E234,x
        dex
        bpl     L5F50
        jsr     L48FA
        A2D_RELAY_CALL A2D_DRAW_RECT, $E230
L5F6B:  jsr     L48F0
        lda     $D208
        cmp     #$04
        beq     L5FC5
        A2D_RELAY_CALL A2D_DRAW_RECT, $E230
        ldx     #$00
L5F80:  cpx     $DEA0
        bne     L5F88
        jmp     L4510

L5F88:  txa
        pha
        lda     $DEA1,x
        sta     $E22F
        jsr     L8915
        DESKTOP_RELAY_CALL $0D, $E22F
        beq     L5FB9
        DESKTOP_RELAY_CALL $02, $E22F
        ldx     $DF21
        inc     $DF21
        lda     $E22F
        sta     $DF22,x
        lda     $EC25
        sta     $DF20
L5FB9:  lda     $E22F
        jsr     L8893
        pla
        tax
        inx
        jmp     L5F80

L5FC5:  jsr     L60D5
        lda     $D209
        sec
        sbc     L60CF
        sta     L60CB
        lda     $D20A
        sbc     L60D0
        sta     L60CC
        lda     $D20B
        sec
        sbc     L60D1
        sta     L60CD
        lda     $D20C
        sbc     L60D2
        sta     L60CE
        lda     L60CC
        bpl     L5FFE
        lda     L60CB
        eor     #$FF
        sta     L60CB
        inc     L60CB
L5FFE:  lda     L60CE
        bpl     L600E
        lda     L60CD
        eor     #$FF
        sta     L60CD
        inc     L60CD
L600E:  lda     L60CB
        cmp     #$05
        bcs     L601F
        lda     L60CD
        cmp     #$05
        bcs     L601F
        jmp     L5F6B

L601F:  A2D_RELAY_CALL A2D_DRAW_RECT, $E230
        ldx     #$03
L602A:  lda     $D209,x
        sta     L60CF,x
        dex
        bpl     L602A
        lda     $D209
        cmp     $E234
        lda     $D20A
        sbc     $E235
        bpl     L6068
        lda     $D209
        cmp     $E230
        lda     $D20A
        sbc     $E231
        bmi     L6054
        bit     L60D3
        bpl     L6068
L6054:  lda     $D209
        sta     $E230
        lda     $D20A
        sta     $E231
        lda     #$80
        sta     L60D3
        jmp     L6079

L6068:  lda     $D209
        sta     $E234
        lda     $D20A
        sta     $E235
        lda     #$00
        sta     L60D3
L6079:  lda     $D20B
        cmp     $E236
        lda     $D20C
        sbc     $E237
        bpl     L60AE
        lda     $D20B
        cmp     $E232
        lda     $D20C
        sbc     $E233
        bmi     L609A
        bit     L60D4
        bpl     L60AE
L609A:  lda     $D20B
        sta     $E232
        lda     $D20C
        sta     $E233
        lda     #$80
        sta     L60D4
        jmp     L60BF

L60AE:  lda     $D20B
        sta     $E236
        lda     $D20C
        sta     $E237
        lda     #$00
        sta     L60D4
L60BF:  A2D_RELAY_CALL A2D_DRAW_RECT, $E230
        jmp     L5F6B

L60CB:  brk
L60CC:  brk
L60CD:  brk
L60CE:  brk
L60CF:  brk
L60D0:  brk
L60D1:  brk
L60D2:  brk
L60D3:  brk
L60D4:  brk
L60D5:  jsr     L87F6
        jmp     L8921

L60DB:  jmp     L60DE

L60DE:  lda     $EC25
        sta     $D208
        A2D_RELAY_CALL A2D_QUERY_TOP, $EC25
        lda     $EC25
        jsr     L8855
        A2D_RELAY_CALL A2D_DRAG_WINDOW, $D208
        lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$16
        lda     (L0006),y
        cmp     #$19
        bcs     L6112
        lda     #$19
        sta     (L0006),y
L6112:  ldy     #$14
        lda     (L0006),y
        sec
        sbc     L8830
        sta     L6197
        iny
        lda     (L0006),y
        sbc     L8831
        sta     L6198
        iny
        lda     (L0006),y
        sec
        sbc     L8832
        sta     L6199
        iny
        lda     (L0006),y
        sbc     L8833
        sta     L619A
        ldx     $EC25
        dex
        lda     $E6D1,x
        beq     L6143
        rts

L6143:  lda     $EC25
        sta     $DE9F
        jsr     LD09A
        ldx     #$00
L614E:  cpx     $DEA0
        bne     L6161
        jsr     LD096
        lda     #$00
        sta     $DE9F
        jsr     LD09A
        jmp     L6196

L6161:  txa
        pha
        lda     $DEA1,x
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$03
        lda     (L0006),y
        clc
        adc     L6197
        sta     (L0006),y
        iny
        lda     (L0006),y
        adc     L6198
        sta     (L0006),y
        iny
        lda     (L0006),y
        clc
        adc     L6199
        sta     (L0006),y
        iny
        lda     (L0006),y
        adc     L619A
        sta     (L0006),y
        pla
        tax
        inx
        jmp     L614E

L6196:  rts

L6197:  brk
L6198:  brk
L6199:  brk
L619A:  brk
L619B:  lda     $EC25
        sta     $D208
        A2D_RELAY_CALL A2D_DRAG_RESIZE, $D208
        jsr     L4523
        lda     $EC25
        sta     $DE9F
        jsr     LD09A
        jsr     L6E52
        jsr     L6DB1
        jsr     L6E6E
        lda     #$00
        sta     $DE9F
        jsr     LD09A
        jmp     L4510

L61CA:  lda     $EC25
        A2D_RELAY_CALL A2D_CLOSE_CLICK, $D2A8
        lda     $D2A8
        bne     L61DC
        rts

L61DC:  lda     $EC25
        sta     $DE9F
        jsr     LD09A
        jsr     L6D2B
        ldx     $EC25
        dex
        lda     $E6D1,x
        bmi     L6215
        lda     $DD9E
        sec
        sbc     $DEA0
        sta     $DD9E
        DESKTOP_RELAY_CALL $07, $EC25
        ldx     #$00
L6206:  cpx     $DEA0
        beq     L6215
        lda     $DEA1,x
        jsr     LD082
        inx
        jmp     L6206

L6215:  dec     $EC2E
        ldx     #$00
        txa
L621B:  sta     $DEA1,x
        cpx     $DEA0
        beq     L6227
        inx
        jmp     L621B

L6227:  sta     $DEA0
        jsr     LD096
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $EC25
        ldx     $EC25
        dex
        lda     $EC26,x
        sta     $E22F
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$01
        lda     (L0006),y
        and     #$0F
        beq     L6276
        ldy     #$02
        lda     (L0006),y
        and     #$7F
        sta     (L0006),y
        and     #$0F
        sta     $DF20
        jsr     L8997
        DESKTOP_RELAY_CALL $02, $E22F
        jsr     L4510
        lda     #$01
        sta     $DF21
        lda     $E22F
        sta     $DF22
L6276:  ldx     $EC25
        dex
        lda     $EC26,x
        jsr     L7345
        ldx     $EC25
        dex
        lda     $EC26,x
        inx
        jsr     L8B5C
        ldx     $EC25
        dex
        lda     #$00
        sta     $EC26,x
        sta     $E6D1,x
        A2D_RELAY_CALL A2D_QUERY_TOP, $EC25
        lda     #$00
        sta     $DE9F
        jsr     LD09A
        lda     #$00
        sta     $E269
        A2D_RELAY_CALL $36, $E267 ; ???
        jsr     L66A2
        jmp     L4523

L62BC:  cmp     #$01
        bcc     L62C2
        bne     L62C5
L62C2:  lda     #$00
        rts

L62C5:  sta     L638B
        stx     L6386
        sty     L638A
        cmp     L6386
        bcc     L62D5
        tya
        rts

L62D5:  lda     #$00
        sta     L6385
        sta     L6389
        clc
        ror     L6386
        ror     L6385
        clc
        ror     L638A
        ror     L6389
        lda     #$00
        sta     L6383
        sta     L6387
        sta     L6384
        sta     L6388
L62F9:  lda     L6384
        cmp     L638B
        beq     L630F
        bcc     L6309
        jsr     L6319
        jmp     L62F9

L6309:  jsr     L634E
        jmp     L62F9

L630F:  lda     L6388
        cmp     #$01
        bcs     L6318
        lda     #$01
L6318:  rts

L6319:  lda     L6383
        sec
        sbc     L6385
        sta     L6383
        lda     L6384
        sbc     L6386
        sta     L6384
        lda     L6387
        sec
        sbc     L6389
        sta     L6387
        lda     L6388
        sbc     L638A
        sta     L6388
        clc
        ror     L6386
        ror     L6385
        clc
        ror     L638A
        ror     L6389
        rts

L634E:  lda     L6383
        clc
        adc     L6385
        sta     L6383
        lda     L6384
        adc     L6386
        sta     L6384
        lda     L6387
        clc
        adc     L6389
        sta     L6387
        lda     L6388
        adc     L638A
        sta     L6388
        clc
        ror     L6386
        ror     L6385
        clc
        ror     L638A
        ror     L6389
        rts

L6383:  brk
L6384:  brk
L6385:  brk
L6386:  brk
L6387:  brk
L6388:  brk
L6389:  brk
L638A:  brk
L638B:  brk
L638C:  jsr     L650F
        sty     L63E9
        jsr     L644C
        sta     L63E8
        lda     $D21F
        sec
        sbc     L63E8
        sta     L63EA
        lda     $D220
        sbc     #$00
        sta     L63EB
        lda     L63EA
        cmp     L7B61
        lda     L63EB
        sbc     L7B62
        bmi     L63C1
        lda     L63EA
        ldx     L63EB
        jmp     L63C7

L63C1:  lda     L7B61
        ldx     L7B62
L63C7:  sta     $D21F
        stx     $D220
        lda     $D21F
        clc
        adc     L63E9
        sta     $D223
        lda     $D220
        adc     #$00
        sta     $D224
        jsr     L653E
        jsr     L6DB1
        jmp     L6556

L63E8:  brk
L63E9:  brk
L63EA:  brk
L63EB:  brk
L63EC:  jsr     L650F
        sty     L6449
        jsr     L644C
        sta     L6448
        lda     $D223
        clc
        adc     L6448
        sta     L644A
        lda     $D224
        adc     #$00
        sta     L644B
        lda     L644A
        cmp     L7B65
        lda     L644B
        sbc     L7B66
        bpl     L6421
        lda     L644A
        ldx     L644B
        jmp     L6427

L6421:  lda     L7B65
        ldx     L7B66
L6427:  sta     $D223
        stx     $D224
        lda     $D223
        sec
        sbc     L6449
        sta     $D21F
        lda     $D224
        sbc     #$00
        sta     $D220
        jsr     L653E
        jsr     L6DB1
        jmp     L6556

L6448:  brk
L6449:  brk
L644A:  brk
L644B:  brk
L644C:  tya
        sec
        sbc     #$0E
        rts

L6451:  jsr     L650F
        sta     L64AC
        stx     L64AD
        lda     $D21D
        sec
        sbc     L64AC
        sta     L64AE
        lda     $D21E
        sbc     L64AD
        sta     L64AF
        lda     L64AE
        cmp     L7B5F
        lda     L64AF
        sbc     L7B60
        bmi     L6484
        lda     L64AE
        ldx     L64AF
        jmp     L648A

L6484:  lda     L7B5F
        ldx     L7B60
L648A:  sta     $D21D
        stx     $D21E
        lda     $D21D
        clc
        adc     L64AC
        sta     $D221
        lda     $D21E
        adc     L64AD
        sta     $D222
        jsr     L653E
        jsr     L6DB1
        jmp     L6556

L64AC:  brk
L64AD:  brk
L64AE:  brk
L64AF:  brk
L64B0:  jsr     L650F
        sta     L650B
        stx     L650C
        lda     $D221
        clc
        adc     L650B
        sta     L650D
        lda     $D222
        adc     L650C
        sta     L650E
        lda     L650D
        cmp     L7B63
        lda     L650E
        sbc     L7B64
        bpl     L64E3
        lda     L650D
        ldx     L650E
        jmp     L64E9

L64E3:  lda     L7B63
        ldx     L7B64
L64E9:  sta     $D221
        stx     $D222
        lda     $D221
        sec
        sbc     L650B
        sta     $D21D
        lda     $D222
        sbc     L650C
        sta     $D21E
        jsr     L653E
        jsr     L6DB1
        jmp     L6556

L650B:  brk
L650C:  brk
L650D:  brk
L650E:  brk
L650F:  bit     L5B1B
        bmi     L6517
        jsr     L6E52
L6517:  jsr     L6523
        jsr     L7B6B
        lda     $EC25
        jmp     L7D5D

L6523:  lda     $EC25
        jsr     L86EF
        clc
        adc     #$14
        sta     L0006
        txa
        adc     #$00
        sta     $07
        ldy     #$25
L6535:  lda     (L0006),y
        sta     $D215,y
        dey
        bpl     L6535
        rts

L653E:  lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$23
        ldx     #$07
L654C:  lda     $D21D,x
        sta     (L0006),y
        dey
        dex
        bpl     L654C
        rts

L6556:  bit     L5B1B
        bmi     L655E
        jsr     L6E6E
L655E:  A2D_RELAY_CALL A2D_FILL_RECT, $D21D
        jsr     L4510
        jmp     L6C19

L656D:  lda     $EC25
        jsr     L7D5D
        sta     L6600
        stx     L6601
        lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$06
        lda     (L0006),y
        tay
        lda     L7B63
        sec
        sbc     L7B5F
        sta     L6602
        lda     L7B64
        sbc     L7B60
        sta     L6603
        lda     L6602
        sec
        sbc     L6600
        sta     L6602
        lda     L6603
        sbc     L6601
        sta     L6603
        lsr     L6603
        ror     L6602
        ldx     L6602
        lda     $D21D
        sec
        sbc     L7B5F
        sta     L6602
        lda     $D21E
        sbc     L7B60
        sta     L6603
        bpl     L65D0
        lda     #$00
        beq     L65EB
L65D0:  lda     $D221
        cmp     L7B63
        lda     $D222
        sbc     L7B64
        bmi     L65E2
        tya
        jmp     L65EE

L65E2:  lsr     L6603
        ror     L6602
        lda     L6602
L65EB:  jsr     L62BC
L65EE:  sta     $D209
        lda     #$02
        sta     $D208
        A2D_RELAY_CALL A2D_UPDATE_SCROLL, $D208
        rts

L6600:  brk
L6601:  brk
L6602:  brk
L6603:  brk
L6604:  lda     $EC25
        jsr     L7D5D
        sty     L669F
        lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$08
        lda     (L0006),y
        tay
        lda     L7B65
        sec
        sbc     L7B61
        sta     L66A0
        lda     L7B66
        sbc     L7B62
        sta     L66A1
        lda     L66A0
        sec
        sbc     L669F
        sta     L66A0
        lda     L66A1
        sbc     #$00
        sta     L66A1
        lsr     L66A1
        ror     L66A0
        lsr     L66A1
        ror     L66A0
        ldx     L66A0
        lda     $D21F
        sec
        sbc     L7B61
        sta     L66A0
        lda     $D220
        sbc     L7B62
        sta     L66A1
        bpl     L6669
        lda     #$00
        beq     L668A
L6669:  lda     $D223
        cmp     L7B65
        lda     $D224
        sbc     L7B66
        bmi     L667B
        tya
        jmp     L668D

L667B:  lsr     L66A1
        ror     L66A0
        lsr     L66A1
        ror     L66A0
        lda     L66A0
L668A:  jsr     L62BC
L668D:  sta     $D209
        lda     #$01
        sta     $D208
        A2D_RELAY_CALL A2D_UPDATE_SCROLL, $D208
        rts

L669F:  brk
L66A0:  brk
L66A1:  brk
L66A2:  ldx     $EC25
        beq     L66AA
        jmp     L66F2

L66AA:  lda     #$01
        sta     $E26B
        A2D_RELAY_CALL $34, $E26A ; ???
        lda     #$01
        sta     $E26E
        lda     #$02
        sta     $E26C
        lda     #$01
        sta     $E26D
        A2D_RELAY_CALL $35, $E26C ; ???
        lda     #$04
        sta     $E26D
        A2D_RELAY_CALL $35, $E26C ; ???
        lda     #$05
        sta     $E26D
        A2D_RELAY_CALL $35, $E26C ; ???
        lda     #$00
        sta     L4359
        rts

L66F2:  dex
        lda     $E6D1,x
        and     #$0F
        tax
        inx
        stx     $E268
        lda     #$01
        sta     $E269
        A2D_RELAY_CALL $36, $E267 ; ???
        rts

L670C:  lda     #$01
        sta     $E26E
        lda     #$02
        sta     $E26C
        lda     #$03
        jsr     L673A
        lda     #$05
        sta     $E26C
        lda     #$07
        jsr     L673A
        lda     #$08
        jsr     L673A
        lda     #$0A
        jsr     L673A
        lda     #$0B
        jsr     L673A
        lda     #$0D
        jsr     L673A
        rts

L673A:  sta     $E26D
        A2D_RELAY_CALL $35, $E26C ; ???
        rts

L6747:  lda     #$00
        sta     $E26E
        lda     #$02
        sta     $E26C
        lda     #$03
        jsr     L6775
        lda     #$05
        sta     $E26C
        lda     #$07
        jsr     L6775
        lda     #$08
        jsr     L6775
        lda     #$0A
        jsr     L6775
        lda     #$0B
        jsr     L6775
        lda     #$0D
        jsr     L6775
        rts

L6775:  sta     $E26D
        A2D_RELAY_CALL $35, $E26C ; ???
        rts

L6782:  lda     #$00
        sta     $E26E
        jmp     L678F

L678A:  lda     #$01
        sta     $E26E
L678F:  lda     #$02
        sta     $E26C
        lda     #$0B
        sta     $E26D
        A2D_RELAY_CALL $35, $E26C ; ???
        rts

L67A3:  lda     #$01
        sta     $E26E
        jmp     L67B0

L67AB:  lda     #$00
        sta     $E26E
L67B0:  lda     #$03
        sta     $E26C
        lda     #$02
        jsr     L67CA
        lda     #$03
        jsr     L67CA
        lda     #$04
        jsr     L67CA
        lda     #$80
        sta     $D344
        rts

L67CA:  sta     $E26D
        A2D_RELAY_CALL $35, $E26C ; ???
        rts

L67D7:  lda     $DF21
        bne     L67DF
        jmp     L681B

L67DF:  tax
        dex
        lda     $D20D
L67E4:  cmp     $DF22,x
        beq     L67EE
        dex
        bpl     L67E4
        bmi     L67F6
L67EE:  bit     $D2AA
        bmi     L6834
        jmp     L6880

L67F6:  bit     $C061
        bpl     L6818
        lda     $DF20
        bne     L6818
        DESKTOP_RELAY_CALL $02, $D20D
        ldx     $DF21
        lda     $D20D
        sta     $DF22,x
        inc     $DF21
        jmp     L6834

L6818:  jsr     L6D2B
L681B:  DESKTOP_RELAY_CALL $02, $D20D
        lda     #$01
        sta     $DF21
        lda     $D20D
        sta     $DF22
        lda     #$00
        sta     $DF20
L6834:  bit     $D2AA
        bpl     L6880
        lda     $D20D
        sta     $EBFC
        DESKTOP_RELAY_CALL $0A, $EBFC
        tax
        lda     $EBFC
        beq     L6878
        jsr     L8F00
        cmp     #$FF
        bne     L6858
        jmp     L4523

L6858:  lda     $EBFC
        cmp     $EBFB
        bne     L6863
        jmp     L4523

L6863:  lda     $EBFC
        bpl     L6872
        and     #$7F
        pha
        jsr     L6F0D
        pla
        jmp     L5E78

L6872:  jsr     L6A3F
        jmp     L4523

L6878:  txa
        cmp     #$02
        bne     L688F
        jmp     L4523

L6880:  lda     $D20D
        cmp     $EBFB
        beq     L688E
        jsr     L6A8A
        jsr     LD096
L688E:  rts

L688F:  ldx     $DF21
        dex
L6893:  txa
        pha
        lda     $DF22,x
        sta     $E22D
        DESKTOP_RELAY_CALL $03, $E22D
        pla
        tax
        dex
        bpl     L6893
        rts

L68AA:  jsr     L4510
        bit     $C061
        bpl     L68B3
        rts

L68B3:  jsr     L6D2B
        ldx     #$03
L68B8:  lda     $D209,x
        sta     $E230,x
        sta     $E234,x
        dex
        bpl     L68B8
        jsr     L48F0
        lda     $D208
        cmp     #$04
        beq     L68CF
        rts

L68CF:  A2D_RELAY_CALL A2D_SET_PATTERN, $D293
        jsr     L48FA
        A2D_RELAY_CALL A2D_DRAW_RECT, $E230
L68E4:  jsr     L48F0
        lda     $D208
        cmp     #$04
        beq     L6932
        A2D_RELAY_CALL A2D_DRAW_RECT, $E230
        ldx     #$00
L68F9:  cpx     $DEA0
        bne     L6904
        lda     #$00
        sta     $DF20
        rts

L6904:  txa
        pha
        lda     $DEA1,x
        sta     $E22F
        DESKTOP_RELAY_CALL $0D, $E22F
        beq     L692C
        DESKTOP_RELAY_CALL $02, $E22F
        ldx     $DF21
        inc     $DF21
        lda     $E22F
        sta     $DF22,x
L692C:  pla
        tax
        inx
        jmp     L68F9

L6932:  lda     $D209
        sec
        sbc     L6A39
        sta     L6A35
        lda     $D20A
        sbc     L6A3A
        sta     L6A36
        lda     $D20B
        sec
        sbc     L6A3B
        sta     L6A37
        lda     $D20C
        sbc     L6A3C
        sta     L6A38
        lda     L6A36
        bpl     L6968
        lda     L6A35
        eor     #$FF
        sta     L6A35
        inc     L6A35
L6968:  lda     L6A38
        bpl     L6978
        lda     L6A37
        eor     #$FF
        sta     L6A37
        inc     L6A37
L6978:  lda     L6A35
        cmp     #$05
        bcs     L6989
        lda     L6A37
        cmp     #$05
        bcs     L6989
        jmp     L68E4

L6989:  A2D_RELAY_CALL A2D_DRAW_RECT, $E230
        ldx     #$03
L6994:  lda     $D209,x
        sta     L6A39,x
        dex
        bpl     L6994
        lda     $D209
        cmp     $E234
        lda     $D20A
        sbc     $E235
        bpl     L69D2
        lda     $D209
        cmp     $E230
        lda     $D20A
        sbc     $E231
        bmi     L69BE
        bit     L6A3D
        bpl     L69D2
L69BE:  lda     $D209
        sta     $E230
        lda     $D20A
        sta     $E231
        lda     #$80
        sta     L6A3D
        jmp     L69E3

L69D2:  lda     $D209
        sta     $E234
        lda     $D20A
        sta     $E235
        lda     #$00
        sta     L6A3D
L69E3:  lda     $D20B
        cmp     $E236
        lda     $D20C
        sbc     $E237
        bpl     L6A18
        lda     $D20B
        cmp     $E232
        lda     $D20C
        sbc     $E233
        bmi     L6A04
        bit     L6A3E
        bpl     L6A18
L6A04:  lda     $D20B
        sta     $E232
        lda     $D20C
        sta     $E233
        lda     #$80
        sta     L6A3E
        jmp     L6A29

L6A18:  lda     $D20B
        sta     $E236
        lda     $D20C
        sta     $E237
        lda     #$00
        sta     L6A3E
L6A29:  A2D_RELAY_CALL A2D_DRAW_RECT, $E230
        jmp     L68E4

L6A35:  brk
L6A36:  brk
L6A37:  brk
L6A38:  brk
L6A39:  brk
L6A3A:  brk
L6A3B:  brk
L6A3C:  brk
L6A3D:  brk
L6A3E:  brk
L6A3F:  ldx     #$07
L6A41:  cmp     $EC26,x
        beq     L6A80
        dex
        bpl     L6A41
        jsr     L86E3
        clc
        adc     #$09
        sta     L0006
        txa
        adc     #$00
        sta     $07
        ldy     #$00
        lda     (L0006),y
        tay
        dey
L6A5C:  lda     (L0006),y
        sta     $0220,y
        dey
        bpl     L6A5C
        dec     $0220
        lda     #$2F
        sta     $0221
        lda     #$20
        ldx     #$02
        ldy     $0220
        jsr     L6FB7
        lda     #$20
        ldx     #$02
        ldy     $0220
        jmp     L6F4B

L6A80:  inx
        txa
        pha
        jsr     L6F0D
        pla
        jmp     L5E78

L6A8A:  sta     $E6BE
        jsr     LD096
        lda     $E6BE
        ldx     #$07
L6A95:  cmp     $EC26,x
        beq     L6AA0
        dex
        bpl     L6A95
        jmp     L6B1E

L6AA0:  inx
        cpx     $EC25
        bne     L6AA7
        rts

L6AA7:  stx     $DE9F
        jsr     LD09A
        lda     $E6BE
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     (L0006),y
        ora     #$80
        sta     (L0006),y
        ldy     #$02
        lda     (L0006),y
        and     #$0F
        sta     $D212
        beq     L6AD8
        cmp     $EC25
        bne     L6AEF
        jsr     L44F2
        lda     $E6BE
        jsr     L8915
L6AD8:  DESKTOP_RELAY_CALL $03, $E6BE
        lda     $D212
        beq     L6AEF
        lda     $E6BE
        jsr     L8893
        jsr     L4510
L6AEF:  lda     $E6BE
        ldx     $E1F1
        dex
L6AF6:  cmp     $E1F2,x
        beq     L6B01
        dex
        bpl     L6AF6
        jsr     L7054
L6B01:  A2D_RELAY_CALL A2D_RAISE_WINDOW, $DE9F
        lda     $DE9F
        sta     $EC25
        jsr     L6C19
        jsr     L40F2
        lda     #$00
        sta     $DE9F
        jmp     LD09A

L6B1E:  lda     $EC2E
        cmp     #$08
        bcc     L6B2F
        lda     #$05
        jsr     L48CC
        ldx     $E256
        txs
        rts

L6B2F:  ldx     #$00
L6B31:  lda     $EC26,x
        beq     L6B3A
        inx
        jmp     L6B31

L6B3A:  lda     $E6BE
        sta     $EC26,x
        inx
        stx     $DE9F
        jsr     LD09A
        inc     $EC2E
        ldx     $DE9F
        dex
        lda     #$00
        sta     $E6D1,x
        lda     $EC2E
        cmp     #$02
        bcs     L6B60
        jsr     L6EC5
        jmp     L6B68

L6B60:  lda     #$00
        sta     $E269
        jsr     L6C0F
L6B68:  lda     #$01
        sta     $E268
        sta     $E269
        jsr     L6C0F
        lda     $E6BE
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     (L0006),y
        ora     #$80
        sta     (L0006),y
        ldy     #$02
        lda     (L0006),y
        and     #$0F
        sta     $D212
        beq     L6BA1
        cmp     $EC25
        bne     L6BB8
        jsr     L44F2
        jsr     L6E8E
        lda     $E6BE
        jsr     L8915
L6BA1:  DESKTOP_RELAY_CALL $03, $E6BE
        lda     $D212
        beq     L6BB8
        lda     $E6BE
        jsr     L8893
        jsr     L4510
L6BB8:  jsr     L744B
        lda     $DE9F
        jsr     L86EF
        ldy     #$38
        jsr     A2D_RELAY
        lda     $EC25
        sta     $D212
        jsr     L44F2
        jsr     L78EF
        jsr     L6E52
        lda     #$00
        sta     L6C0E
L6BDA:  lda     L6C0E
        cmp     $DEA0
        beq     L6BF4
        tax
        lda     $DEA1,x
        jsr     L86E3
        ldy     #$01
        jsr     DESKTOP_RELAY
        inc     L6C0E
        jmp     L6BDA

L6BF4:  lda     $DE9F
        sta     $EC25
        jsr     L6DB1
        jsr     L6E6E
        jsr     LD096
        lda     #$00
        sta     $DE9F
        jsr     LD09A
        jmp     L4510

L6C0E:  brk
L6C0F:  A2D_RELAY_CALL $36, $E267 ; ???
        rts

L6C19:  ldx     $DE9F
        dex
        lda     $E6D1,x
        bmi     L6C25
        jmp     L6CCD

L6C25:  jsr     L87F6
        lda     $DE9F
        sta     $D212
        jsr     L44F2
        bit     L4152
        bmi     L6C39
        jsr     L78EF
L6C39:  lda     $DE9F
        sta     $D212
        jsr     L4505
L6C42:  bit     L4152
        bmi     L6C4A
        jsr     L6E8E
L6C4A:  ldx     $DE9F
        dex
        lda     $EC26,x
        ldx     #$00
L6C53:  cmp     $E1F2,x
        beq     L6C5F
        inx
        cpx     $E1F1
        bne     L6C53
        rts

L6C5F:  txa
        asl     a
        tax
        lda     $E202,x
        sta     $E71D
        sta     L0006
        lda     $E203,x
        sta     $E71E
        sta     $07
        lda     $C083
        lda     $C083
        ldy     #$00
        lda     (L0006),y
        tay
        lda     LCBANK1
        lda     LCBANK1
        tya
        sta     $E71F
        inc     $E71D
        bne     L6C8F
        inc     $E71E
L6C8F:  lda     #$10
        sta     $E6DB
        sta     $E6DF
        sta     $E6E3
        sta     $E6E7
        lda     #$00
        sta     $E6DC
        sta     $E6E0
        sta     $E6E4
        sta     $E6E8
        lda     #$00
        sta     L6CCC
L6CB0:  lda     L6CCC
        cmp     $DEA0
        beq     L6CC5
        tax
        lda     $DEA1,x
        jsr     L813F
        inc     L6CCC
        jmp     L6CB0

L6CC5:  jsr     L4510
        jsr     L8813
        rts

L6CCC:  brk
L6CCD:  lda     $DE9F
        sta     $D212
        jsr     L44F2
        bit     L4152
        bmi     L6CDE
        jsr     L78EF
L6CDE:  jsr     L6E52
        jsr     L6E8E
        ldx     #$07
L6CE6:  lda     $D21D,x
        sta     $E230,x
        dex
        bpl     L6CE6
        ldx     #$00
        txa
        pha
L6CF3:  cpx     $DEA0
        bne     L6D09
        pla
        jsr     L4510
        lda     $DE9F
        sta     $D212
        jsr     L44F2
        jsr     L6E6E
        rts

L6D09:  txa
        pha
        lda     $DEA1,x
        sta     $E22F
        DESKTOP_RELAY_CALL $0D, $E22F
        beq     L6D25
        DESKTOP_RELAY_CALL $03, $E22F
L6D25:  pla
        tax
        inx
        jmp     L6CF3

L6D2B:  lda     $DF21
        bne     L6D31
        rts

L6D31:  lda     #$00
        sta     L6DB0
        lda     $DF20
        sta     $E230
        beq     L6D7D
        cmp     $EC25
        beq     L6D4D
        jsr     L8997
        lda     #$00
        sta     $E230
        beq     L6D56
L6D4D:  sta     $D212
        jsr     L44F2
        jsr     L6E8E
L6D56:  lda     L6DB0
        cmp     $DF21
        beq     L6D9B
        tax
        lda     $DF22,x
        sta     $E22F
        jsr     L8915
        DESKTOP_RELAY_CALL $0B, $E22F
        lda     $E22F
        jsr     L8893
        inc     L6DB0
        jmp     L6D56

L6D7D:  lda     L6DB0
        cmp     $DF21
        beq     L6D9B
        tax
        lda     $DF22,x
        sta     $E22F
        DESKTOP_RELAY_CALL $0B, $E22F
        inc     L6DB0
        jmp     L6D7D

L6D9B:  lda     #$00
        ldx     $DF21
        dex
L6DA1:  sta     $DF22,x
        dex
        bpl     L6DA1
        sta     $DF21
        sta     $DF20
        jmp     L4510

L6DB0:  brk
L6DB1:  ldx     $EC25
        dex
        lda     $E6D1,x
        bmi     L6DC0
        jsr     L7B6B
        jmp     L6DC9

L6DC0:  jsr     L6E52
        jsr     L7B6B
        jsr     L6E6E
L6DC9:  lda     $EC25
        sta     $D212
        jsr     L44F2
        lda     L7B5F
        cmp     $D21D
        lda     L7B60
        sbc     $D21E
        bmi     L6DFE
        lda     $D221
        cmp     L7B63
        lda     $D222
        sbc     L7B64
        bmi     L6DFE
        lda     #$02
        sta     $D208
        lda     #$00
        sta     $D209
        jsr     L6E48
        jmp     L6E0E

L6DFE:  lda     #$02
        sta     $D208
        lda     #$01
        sta     $D209
        jsr     L6E48
        jsr     L656D
L6E0E:  lda     L7B61
        cmp     $D21F
        lda     L7B62
        sbc     $D220
        bmi     L6E38
        lda     $D223
        cmp     L7B65
        lda     $D224
        sbc     L7B66
        bmi     L6E38
        lda     #$01
        sta     $D208
        lda     #$00
        sta     $D209
        jsr     L6E48
        rts

L6E38:  lda     #$01
        sta     $D208
        lda     #$01
        sta     $D209
        jsr     L6E48
        jmp     L6604

L6E48:  A2D_RELAY_CALL $4C, $D208 ; ???
        rts

L6E52:  lda     #$00
        sta     L6E6D
L6E57:  lda     L6E6D
        cmp     $DEA0
        beq     L6E6C
        tax
        lda     $DEA1,x
        jsr     L8915
        inc     L6E6D
        jmp     L6E57

L6E6C:  rts

L6E6D:  brk
L6E6E:  lda     #$00
        sta     L6E89
L6E73:  lda     L6E89
        cmp     $DEA0
        beq     L6E88
        tax
        lda     $DEA1,x
        jsr     L8893
        inc     L6E89
        jmp     L6E73

L6E88:  rts

L6E89:  brk
L6E8A:  lda     #$80
        beq     L6E90
L6E8E:  lda     #$00
L6E90:  sta     L6EC4
        lda     $D217
        clc
        adc     #$0F
        sta     $D217
        lda     $D218
        adc     #$00
        sta     $D218
        lda     $D21F
        clc
        adc     #$0F
        sta     $D21F
        lda     $D220
        adc     #$00
        sta     $D220
        bit     L6EC4
        bmi     L6EC3
        A2D_RELAY_CALL A2D_SET_STATE, $D215
L6EC3:  rts

L6EC4:  brk
L6EC5:  lda     #$00
        sta     $E26B
        A2D_RELAY_CALL $34, $E26A ; ???
        lda     #$00
        sta     $E26E
        lda     #$02
        sta     $E26C
        lda     #$01
        sta     $E26D
        A2D_RELAY_CALL $35, $E26C ; ???
        lda     #$04
        sta     $E26D
        A2D_RELAY_CALL $35, $E26C ; ???
        lda     #$05
        sta     $E26D
        A2D_RELAY_CALL $35, $E26C ; ???
        lda     #$80
        sta     L4359
        rts

L6F0D:  jsr     L86FB
        sta     L0006
        sta     L6F48
        stx     $07
        stx     L6F49
        ldy     #$00
        lda     (L0006),y
        sta     L6F4A
        iny
L6F22:  iny
        lda     (L0006),y
        cmp     #$2F
        beq     L6F31
        cpy     L6F4A
        beq     L6F32
        jmp     L6F22

L6F31:  dey
L6F32:  sty     L6F4A
        lda     L0006
        ldx     $07
        jsr     L6FB7
        lda     L6F48
        ldx     L6F49
        ldy     L6F4A
        jmp     L6F4B

L6F48:  brk
L6F49:  brk
L6F4A:  brk
L6F4B:  sta     L0006
        stx     $07
        sty     L705D
L6F52:  lda     (L0006),y
        sta     L705D,y
        dey
        bne     L6F52
        jsr     L72EC
        bne     L6F8F
        lda     L704B
        beq     L6F8F
L6F64:  dec     L704B
        bmi     L6F8F
        ldx     L704B
        lda     L704C,x
        sec
        sbc     #$01
        asl     a
        tax
        lda     L70BD
        sta     $EB8B,x
        lda     L70BE
        sta     $EB8C,x
        lda     L70BB
        sta     $EB9B,x
        lda     L70BC
        sta     $EB9C,x
        jmp     L6F64

L6F8F:  rts

L6F90:  sta     $0A
        stx     $0B
        ldy     #$00
        lda     ($0A),y
        tay
L6F99:  lda     ($0A),y
        cmp     #$2F
        beq     L6FA9
        dey
        bpl     L6F99
        ldy     #$01
L6FA4:  dey
        lda     ($0A),y
        tay
        rts

L6FA9:  cpy     #$01
        beq     L6FA4
        dey
        rts

L6FAF:  sta     L0006
        stx     $07
        lda     #$80
        bne     L6FBD
L6FB7:  sta     L0006
        stx     $07
        lda     #$00
L6FBD:  sta     L704A
        bit     L704A
        bpl     L6FCA
        ldy     #$00
        lda     (L0006),y
        tay
L6FCA:  sty     L4F76
L6FCD:  lda     (L0006),y
        sta     L4F76,y
        dey
        bne     L6FCD
        lda     #$76
        ldx     #$4F
        jsr     L87BA
        lda     #$00
        sta     L704B
        sta     L7049
L6FE4:  inc     L7049
        lda     L7049
        cmp     #$09
        bcc     L6FF6
        bit     L704A
        bpl     L6FF5
        lda     #$00
L6FF5:  rts

L6FF6:  jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$0A
        lda     (L0006),y
        beq     L6FE4
        lda     L7049
        jsr     L86FB
        sta     L0006
        stx     $07
        ldy     #$00
        lda     (L0006),y
        tay
        cmp     L4F76
        beq     L7027
        bit     L704A
        bmi     L6FE4
        ldy     L4F76
        iny
        lda     (L0006),y
        cmp     #$2F
        bne     L6FE4
        dey
L7027:  lda     (L0006),y
        cmp     L4F76,y
        bne     L6FE4
        dey
        bne     L7027
        bit     L704A
        bmi     L7045
        ldx     L704B
        lda     L7049
        sta     L704C,x
        inc     L704B
        jmp     L6FE4

L7045:  lda     L7049
        rts

L7049:  brk
L704A:  brk
L704B:  brk
L704C:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
L7054:  jmp     L70C5

        .byte   $03,$5D,$70,$00,$08
L705C:  .byte   $00
L705D:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$04
L709F:  .byte   $00,$00,$0C,$00,$02,$00,$00,$01
L70A7:  .byte   $00,$0A,$5D,$70,$00,$00
L70AD:  .byte   $00
L70AE:  .byte   $00,$00
L70B0:  .byte   $00
L70B1:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00
L70BB:  .byte   $00
L70BC:  .byte   $00
L70BD:  .byte   $00
L70BE:  .byte   $00
L70BF:  .byte   $00
L70C0:  .byte   $00
L70C1:  .byte   $00
L70C2:  .byte   $00
L70C3:  .byte   $00
L70C4:  .byte   $00
L70C5:  sta     L72A7
        jsr     L87F6
        ldx     #$40
L70CD:  lda     $E1B0,x
        sta     L705D,x
        dex
        bpl     L70CD
        jsr     L72AA
        lda     L705C
        sta     L709F
        sta     L70A7
        jsr     L72CE
        jsr     L72E2
        ldx     #$00
L70EA:  lda     $0C23,x
        sta     L70BF,x
        inx
        cpx     #$04
        bne     L70EA
        lda     L485D
        sec
        sbc     L485F
        sta     L72A8
        lda     L485E
        sbc     L4860
        sta     L72A9
        ldx     #$05
L710A:  lsr     L72A9
        ror     L72A8
        dex
        cpx     #$00
        bne     L710A
        lda     L70C2
        bne     L7147
        lda     $DD9E
        clc
        adc     L70C1
        bcs     L7147
        cmp     #$7C
        bcs     L7147
        lda     L72A8
        sec
        sbc     $BF31
        sta     L72A8
        lda     L72A9
        sbc     #$00
        sta     L72A9
        lda     L72A8
        cmp     L70C1
        lda     L72A9
        sbc     L70C2
        bcs     L7169
L7147:  lda     $EC2E
        jsr     L8B19
        dec     $EC2E
        jsr     L4523
        jsr     L72D8
        lda     $EC25
        beq     L715F
        lda     #$03
        bne     L7161
L715F:  lda     #$04
L7161:  jsr     L48CC
        ldx     $E256
        txs
        rts

L7169:  lda     L485F
        sta     L0006
        lda     L4860
        sta     $07
        lda     $E1F1
        asl     a
        tax
        lda     L0006
        sta     $E202,x
        lda     $07
        sta     $E203,x
        ldx     $E1F1
        lda     L72A7
        sta     $E1F2,x
        inc     $E1F1
        lda     L70C1
        pha
        lda     $C083
        lda     $C083
        ldy     #$00
        pla
        sta     (L0006),y
        lda     LCBANK1
        lda     LCBANK1
        lda     #$FF
        sta     L70C4
        lda     #$00
        sta     L70C3
        lda     #$04
        sta     $08
        lda     #$0C
        sta     $09
        inc     L0006
        lda     L0006
        bne     L71BD
        inc     $07
L71BD:  inc     L70C4
        lda     L70C4
        cmp     L70C1
        bne     L71CB
        jmp     L7296

L71CB:  inc     L70C3
        lda     L70C3
        cmp     L70C0
        beq     L71E7
        lda     $08
        clc
        adc     L70BF
        sta     $08
        lda     $09
        adc     #$00
        sta     $09
        jmp     L71F7

L71E7:  lda     #$00
        sta     L70C3
        lda     #$04
        sta     $08
        lda     #$0C
        sta     $09
        jsr     L72CE
L71F7:  ldx     #$00
        ldy     #$00
        lda     ($08),y
        and     #$0F
        sta     $1F00,x
        bne     L7223
        inc     L70C3
        lda     L70C3
        cmp     L70C0
        bne     L7212
        jmp     L71E7

L7212:  lda     $08
        clc
        adc     L70BF
        sta     $08
        lda     $09
        adc     #$00
        sta     $09
        jmp     L71F7

L7223:  iny
        inx
L7225:  lda     ($08),y
        sta     $1F00,x
        iny
        inx
        cpx     #$11
        bne     L7225
        ldy     #$13
        lda     ($08),y
        sta     $1F00,x
        inx
        iny
        lda     ($08),y
        sta     $1F00,x
        ldy     #$18
        inx
L7241:  lda     ($08),y
        sta     $1F00,x
        inx
        iny
        cpy     #$1C
        bne     L7241
        ldy     #$21
L724E:  lda     ($08),y
        sta     $1F00,x
        inx
        iny
        cpy     #$25
        bne     L724E
        ldy     #$1E
        lda     ($08),y
        sta     $1F00,x
        inx
        ldy     #$25
        lda     ($08),y
        sta     $1F00,x
        inx
        iny
        lda     ($08),y
        sta     $1F00,x
        lda     $C083
        lda     $C083
        ldx     #$1F
        ldy     #$1F
L7279:  lda     $1F00,x
        sta     (L0006),y
        dex
        dey
        bpl     L7279
        lda     LCBANK1
        lda     LCBANK1
        lda     #$20
        clc
        adc     L0006
        sta     L0006
        bcc     L7293
        inc     $07
L7293:  jmp     L71BD

L7296:  lda     L0006
        sta     L485F
        lda     $07
        sta     L4860
        jsr     L72D8
        jsr     L8813
        rts

L72A7:  brk
L72A8:  brk
L72A9:  brk
L72AA:  ldy     #$C8
        lda     #$57
        ldx     #$70
        jsr     L46BA
        beq     L72CD
        jsr     LD154
        jsr     L8B1F
        lda     $DF20
        bne     L72C9
        lda     $E6BE
        sta     L533F
        jsr     L59A8
L72C9:  ldx     $E256
        txs
L72CD:  rts

L72CE:  ldy     #$CA
        lda     #$9E
        ldx     #$70
        jsr     L46BA
        rts

L72D8:  ldy     #$CC
        lda     #$A6
        ldx     #$70
        jsr     L46BA
        rts

L72E2:  lda     $0C04
        and     #$F0
        cmp     #$F0
        beq     L72EC
        rts

L72EC:  ldy     #$C4
        lda     #$A8
        ldx     #$70
        jsr     L46BA
        beq     L72F8
        rts

L72F8:  lda     L70AD
        sta     L70BD
        lda     L70AE
        sta     L70BE
        lda     L70AD
        sec
        sbc     L70B0
        sta     L70BB
        lda     L70AE
        sbc     L70B1
        sta     L70BC
        lda     L70BD
        sec
        sbc     L70BB
        sta     L70BD
        lda     L70BE
        sbc     L70BC
        sta     L70BE
        lsr     L70BC
        ror     L70BB
        php
        lsr     L70BE
        ror     L70BD
        plp
        bcc     L7342
        inc     L70BD
        bne     L7342
        inc     L70BE
L7342:  lda     #$00
        rts

L7345:  sta     L7445
        ldx     #$00
L734A:  lda     $E1F2,x
        cmp     L7445
        beq     L7358
        inx
        cpx     #$08
        bne     L734A
        rts

L7358:  stx     L7446
        dex
L735C:  inx
        lda     $E1F3,x
        sta     $E1F2,x
        cpx     $E1F1
        bne     L735C
        dec     $E1F1
        lda     L7446
        cmp     $E1F1
        bne     L7385
        ldx     L7446
        asl     a
        tax
        lda     $E202,x
        sta     L485F
        lda     $E203,x
        sta     L4860
        rts

L7385:  lda     L7446
        asl     a
        tax
        lda     $E202,x
        sta     L0006
        lda     $E203,x
        sta     $07
        inx
        inx
        lda     $E202,x
        sta     $08
        lda     $E203,x
        sta     $09
        ldy     #$00
        jsr     L87F6
L73A5:  lda     $C083
        lda     $C083
        lda     ($08),y
        sta     (L0006),y
        lda     LCBANK1
        lda     LCBANK1
        inc     L0006
        bne     L73BB
        inc     $07
L73BB:  inc     $08
        bne     L73C1
        inc     $09
L73C1:  lda     $09
        cmp     L4860
        bne     L73A5
        lda     $08
        cmp     L485F
        bne     L73A5
        jsr     L8813
        lda     $E1F1
        asl     a
        tax
        lda     L485F
        sec
        sbc     $E202,x
        sta     L7447
        lda     L4860
        sbc     $E203,x
        sta     L7448
        inc     L7446
L73ED:  lda     L7446
        cmp     $E1F1
        bne     L73F8
        jmp     L7429

L73F8:  lda     L7446
        asl     a
        tax
        lda     $E204,x
        sec
        sbc     $E202,x
        sta     L7449
        lda     $E205,x
        sbc     $E203,x
        sta     L744A
        lda     $E200,x
        clc
        adc     L7449
        sta     $E202,x
        lda     $E201,x
        adc     L744A
        sta     $E203,x
        inc     L7446
        jmp     L73ED

L7429:  lda     $E1F1
        sec
        sbc     #$01
        asl     a
        tax
        lda     $E202,x
        clc
        adc     L7447
        sta     L485F
        lda     $E203,x
        adc     L7448
        sta     L4860
        rts

L7445:  brk
L7446:  brk
L7447:  brk
L7448:  brk
L7449:  brk
L744A:  brk
L744B:  lda     $DE9F
        asl     a
        tax
        lda     $E6BF,x
        sta     $08
        lda     $E6C0,x
        sta     $09
        ldy     #$09
        lda     (L0006),y
        tay
        jsr     L87F6
        lda     L0006
        clc
        adc     #$09
        sta     L0006
        bcc     L746D
        inc     $07
L746D:  tya
        tax
        ldy     #$00
L7471:  lda     (L0006),y
        sta     ($08),y
        iny
        dex
        bne     L7471
        lda     #$20
        sta     ($08),y
        ldy     #$02
        lda     ($08),y
        and     #$DF
        sta     ($08),y
        jsr     L8813
        ldy     #$02
        lda     (L0006),y
        and     #$0F
        bne     L74D3
        jsr     L87F6
        lda     $DE9F
        jsr     L86FB
        sta     $08
        stx     $09
        lda     L0006
        clc
        adc     #$09
        sta     L0006
        bcc     L74A8
        inc     $07
L74A8:  ldy     #$00
        lda     (L0006),y
        tay
L74AD:  lda     (L0006),y
        sta     ($08),y
        dey
        bpl     L74AD
        ldy     #$00
        lda     ($08),y
        sec
        sbc     #$01
        sta     ($08),y
        ldy     #$01
        lda     #$2F
        sta     ($08),y
        ldy     #$00
        lda     ($08),y
        tay
L74C8:  lda     ($08),y
        sta     $E1B0,y
        dey
        bpl     L74C8
        jmp     L7569

L74D3:  tay
        lda     #$00
        sta     L7620
        jsr     L87F6
        tya
        pha
        jsr     L86FB
        sta     L0006
        stx     $07
        pla
        asl     a
        tax
        lda     $E6BF,x
        sta     $08
        lda     $E6C0,x
        sta     $09
        ldy     #$00
        lda     (L0006),y
        clc
        adc     ($08),y
        cmp     #$43
        bcc     L750D
        lda     #$40
        jsr     LD154
        jsr     L8B1F
        dec     $EC2E
        ldx     $E256
        txs
        rts

L750D:  ldy     #$00
        lda     (L0006),y
        tay
L7512:  lda     (L0006),y
        sta     $E1B0,y
        dey
        bpl     L7512
        lda     #$2F
        sta     $E1B1
        inc     $E1B0
        ldx     $E1B0
        sta     $E1B0,x
        lda     $E6BE
        jsr     L86E3
        sta     $08
        stx     $09
        ldx     $E1B0
        ldy     #$09
        lda     ($08),y
        clc
        adc     $E1B0
        sta     $E1B0
        dec     $E1B0
        dec     $E1B0
        ldy     #$0A
L7548:  iny
        inx
        lda     ($08),y
        sta     $E1B0,x
        cpx     $E1B0
        bne     L7548
        lda     $DE9F
        jsr     L86FB
        sta     $08
        stx     $09
        ldy     $E1B0
L7561:  lda     $E1B0,y
        sta     ($08),y
        dey
        bpl     L7561
L7569:  lda     $08
        ldx     $09
        jsr     L87BA
        lda     $DE9F
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$14
        lda     $DE9F
        sec
        sbc     #$01
        asl     a
        asl     a
        asl     a
        asl     a
        pha
        adc     #$05
        sta     (L0006),y
        iny
        lda     #$00
        sta     (L0006),y
        iny
        pla
        lsr     a
        clc
        adc     #$1B
        sta     (L0006),y
        iny
        lda     #$00
        sta     (L0006),y
        lda     #$00
        ldy     #$1F
        ldx     #$03
L75A3:  sta     (L0006),y
        dey
        dex
        bpl     L75A3
        ldy     #$04
        lda     (L0006),y
        and     #$FE
        sta     (L0006),y
        iny
        lda     (L0006),y
        and     #$FE
        sta     (L0006),y
        lda     #$00
        ldy     #$07
        sta     (L0006),y
        ldy     #$09
        sta     (L0006),y
        jsr     L8813
        lda     $E6BE
        jsr     L7054
        lda     $E6BE
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     (L0006),y
        and     #$0F
        beq     L75FA
        tax
        dex
        txa
        asl     a
        tax
        lda     $EB8B,x
        sta     L70BD
        lda     $EB8C,x
        sta     L70BE
        lda     $EB9B,x
        sta     L70BB
        lda     $EB9C,x
        sta     L70BC
L75FA:  ldx     $DE9F
        dex
        txa
        asl     a
        tax
        lda     L70BD
        sta     $EB8B,x
        lda     L70BE
        sta     $EB8C,x
        lda     L70BB
        sta     $EB9B,x
        lda     L70BC
        sta     $EB9C,x
        lda     $DE9F
        jsr     L7635
        rts

L7620:  .byte   $00
L7621:  .byte   $00
L7622:  .byte   $00
L7623:  .byte   $00
L7624:  .byte   $00
L7625:  .byte   $00
L7626:  .byte   $34
L7627:  .byte   $00,$10,$00
L762A:  .byte   $00
L762B:  .byte   $00
L762C:  .byte   $00
L762D:  .byte   $00
L762E:  .byte   $05
L762F:  .byte   $00
L7630:  .byte   $00
L7631:  .byte   $00
L7632:  .byte   $00
L7633:  .byte   $00
L7634:  .byte   $00
L7635:  pha
        lda     #$00
        beq     L7647
L763A:  pha
        ldx     $DE9F
        dex
        lda     $EC26,x
        sta     $E6BE
        lda     #$80
L7647:  sta     L7634
        pla
        sta     L7621
        jsr     L87F6
        ldx     #$03
L7653:  lda     L7626,x
        sta     L762A,x
        dex
        bpl     L7653
        lda     #$00
        sta     L762F
        sta     L7625
        ldx     #$03
L7666:  sta     L7630,x
        dex
        bpl     L7666
        lda     $E6BE
        ldx     $E1F1
        dex
L7673:  cmp     $E1F2,x
        beq     L767C
        dex
        bpl     L7673
        rts

L767C:  txa
        asl     a
        tax
        lda     $E202,x
        sta     L0006
        lda     $E203,x
        sta     $07
        lda     $C083
        lda     $C083
        ldy     #$00
        lda     (L0006),y
        sta     L7764
        lda     LCBANK1
        lda     LCBANK1
        inc     L0006
        lda     L0006
        bne     L76A4
        inc     $07
L76A4:  lda     $DE9F
        sta     $EC25
L76AA:  lda     L7625
        cmp     L7764
        beq     L76BB
        jsr     L7768
        inc     L7625
        jmp     L76AA

L76BB:  bit     L7634
        bpl     L76C4
        jsr     L8813
        rts

L76C4:  jsr     L7B6B
        lda     L7621
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$16
        lda     L7B65
        sec
        sbc     (L0006),y
        sta     L7B65
        lda     L7B66
        sbc     #$00
        sta     L7B66
        lda     L7B63
        cmp     #$AA
        lda     L7B64
        sbc     #$00
        bmi     L7705
        lda     L7B63
        cmp     #$C2
        lda     L7B64
        sbc     #$01
        bpl     L770C
        lda     L7B63
        ldx     L7B64
        jmp     L7710

L7705:  lda     #$AA
        ldx     #$00
        jmp     L7710

L770C:  lda     #$C2
        ldx     #$01
L7710:  ldy     #$20
        sta     (L0006),y
        txa
        iny
        sta     (L0006),y
        lda     L7B65
        cmp     #$32
        lda     L7B66
        sbc     #$00
        bmi     L7739
        lda     L7B65
        cmp     #$6C
        lda     L7B66
        sbc     #$00
        bpl     L7740
        lda     L7B65
        ldx     L7B66
        jmp     L7744

L7739:  lda     #$32
        ldx     #$00
        jmp     L7744

L7740:  lda     #$6C
        ldx     #$00
L7744:  ldy     #$22
        sta     (L0006),y
        txa
        iny
        sta     (L0006),y
        lda     L7767
        ldy     #$06
        sta     (L0006),y
        ldy     #$08
        sta     (L0006),y
        lda     $E6BE
        ldx     L7621
        jsr     L8B60
        jsr     L8813
        rts

L7764:  .byte   $00,$00,$00
L7767:  .byte   $14
L7768:  inc     $DD9E
        jsr     LD05E
        ldx     $DEA0
        inc     $DEA0
        sta     $DEA1,x
        jsr     L86E3
        sta     $08
        stx     $09
        lda     $C083
        lda     $C083
        ldy     #$00
        lda     (L0006),y
        sta     $1800
        iny
        ldx     #$00
L778E:  lda     (L0006),y
        sta     $1802,x
        inx
        iny
        cpx     $1800
        bne     L778E
        inc     $1800
        inc     $1800
        lda     #$20
        sta     $1801
        ldx     $1800
        sta     $1800,x
        ldy     #$10
        lda     (L0006),y
        cmp     #$B3
        beq     L77CC
        cmp     #$FF
        bne     L77DA
        ldy     #$00
        lda     (L0006),y
        tay
        ldx     L77D0
L77BF:  lda     (L0006),y
        cmp     L77D0,x
        bne     L77D8
        dey
        beq     L77D8
        dex
        bne     L77BF
L77CC:  lda     #$01
        bne     L77DA
L77D0:  rmb0    $2E
        .byte   $53
        eor     L5453,y
        eor     $4D
L77D8:  lda     #$FF
L77DA:  tay
        lda     LCBANK1
        lda     LCBANK1
        tya
        jsr     L78A1
        lda     #$00
        ldx     #$18
        jsr     L87BA
        ldy     #$09
        ldx     #$00
L77F0:  lda     $1800,x
        sta     ($08),y
        iny
        inx
        cpx     $1800
        bne     L77F0
        lda     $1800,x
        sta     ($08),y
        ldx     #$00
        ldy     #$03
L7805:  lda     L762A,x
        sta     ($08),y
        inx
        iny
        cpx     #$04
        bne     L7805
        lda     $DEA0
        cmp     L762E
        beq     L781A
        bcs     L7826
L781A:  lda     L762A
        sta     L7630
        lda     L762B
        sta     L7631
L7826:  lda     L762C
        sta     L7632
        lda     L762D
        sta     L7633
        inc     L762F
        lda     L762F
        cmp     L762E
        bne     L7862
        lda     L762C
        clc
        adc     #$20
        sta     L762C
        lda     L762D
        adc     #$00
        sta     L762D
        lda     L7626
        sta     L762A
        lda     L7627
        sta     L762B
        lda     #$00
        sta     L762F
        jmp     L7870

L7862:  lda     L762A
        clc
        adc     #$50
        sta     L762A
        bcc     L7870
        inc     L762B
L7870:  lda     $DE9F
        ora     L7624
        ldy     #$02
        sta     ($08),y
        ldy     #$07
        lda     L7622
        sta     ($08),y
        iny
        lda     L7623
        sta     ($08),y
        ldx     $DEA0
        dex
        lda     $DEA1,x
        jsr     L8893
        lda     L0006
        clc
        adc     #$20
        sta     L0006
        lda     $07
        adc     #$00
        sta     $07
        rts

        brk
        brk
L78A1:  sta     L78EE
        jsr     L87F6
        lda     $FB00
        sta     L0006
        lda     $FB01
        sta     $07
        ldy     #$00
        lda     (L0006),y
        tay
L78B6:  lda     (L0006),y
        cmp     L78EE
        beq     L78C2
        dey
        bpl     L78B6
        ldy     #$01
L78C2:  lda     $FB04
        sta     L0006
        lda     $FB05
        sta     $07
        lda     (L0006),y
        sta     L7624
        dey
        tya
        asl     a
        tay
        lda     $FB02
        sta     L0006
        lda     $FB03
        sta     $07
        lda     (L0006),y
        sta     L7622
        iny
        lda     (L0006),y
        sta     L7623
        jsr     L8813
        rts

L78EE:  brk
L78EF:  lda     $D21D
        sta     $EBBE
        clc
        adc     #$05
        sta     $EBBA
        lda     $D21E
        sta     $EBBF
        adc     #$00
        sta     $EBBB
        lda     $D21F
        clc
        adc     #$0C
        sta     $EBC0
        sta     $EBC4
        lda     $D220
        adc     #$00
        sta     $EBC1
        sta     $EBC5
        A2D_RELAY_CALL A2D_SET_POS, $EBBE
        lda     $D221
        sta     $EBC2
        lda     $D222
        sta     $EBC3
        jsr     L48FA
        A2D_RELAY_CALL A2D_DRAW_LINE_ABS, $EBC2
        lda     $EBC0
        clc
        adc     #$02
        sta     $EBC0
        sta     $EBC4
        lda     $EBC1
        adc     #$00
        sta     $EBC1
        sta     $EBC5
        A2D_RELAY_CALL A2D_SET_POS, $EBBE
        A2D_RELAY_CALL A2D_DRAW_LINE_ABS, $EBC2
        lda     $D21F
        clc
        adc     #$0A
        sta     $EBBC
        lda     $D220
        adc     #$00
        sta     $EBBD
        lda     $DEA0
        ldx     #$00
        jsr     L7AE0
        lda     $DEA0
        cmp     #$02
        bcs     L798A
        dec     $EBB3
L798A:  A2D_RELAY_CALL A2D_SET_POS, $EBBA
        jsr     L7AD7
        lda     #$B3
        ldx     #$EB
        jsr     L8780
        lda     $DEA0
        cmp     #$02
        bcs     L79A7
        inc     $EBB3
L79A7:  jsr     L79F7
        ldx     $EC25
        dex
        txa
        asl     a
        tax
        lda     $EB8B,x
        tay
        lda     $EB8C,x
        tax
        tya
        jsr     L7AE0
        A2D_RELAY_CALL A2D_SET_POS, $EBEB
        jsr     L7AD7
        lda     #$C6
        ldx     #$EB
        jsr     L8780
        ldx     $EC25
        dex
        txa
        asl     a
        tax
        lda     $EB9B,x
        tay
        lda     $EB9C,x
        tax
        tya
        jsr     L7AE0
        A2D_RELAY_CALL A2D_SET_POS, $EBEF
        jsr     L7AD7
        lda     #$D0
        ldx     #$EB
        jsr     L8780
        rts

L79F7:  lda     $D221
        sec
        sbc     $D21D
        sta     L7ADE
        lda     $D222
        sbc     $D21E
        sta     L7ADF
        lda     L7ADE
        sec
        sbc     $EBF3
        sta     L7ADE
        lda     L7ADF
        sbc     $EBF4
        sta     L7ADF
        bpl     L7A22
        jmp     L7A86

L7A22:  lda     L7ADE
        sec
        sbc     $EBF9
        sta     L7ADE
        lda     L7ADF
        sbc     $EBFA
        sta     L7ADF
        bpl     L7A3A
        jmp     L7A86

L7A3A:  lda     $EBE7
        clc
        adc     L7ADE
        sta     $EBEF
        lda     $EBE8
        adc     L7ADF
        sta     $EBF0
        lda     L7ADF
        beq     L7A59
        lda     L7ADE
        cmp     #$18
        bcc     L7A6A
L7A59:  lda     $EBEF
        sec
        sbc     #$0C
        sta     $EBEF
        lda     $EBF0
        sbc     #$00
        sta     $EBF0
L7A6A:  lsr     L7ADF
        ror     L7ADE
        lda     $EBE3
        clc
        adc     L7ADE
        sta     $EBEB
        lda     $EBE4
        adc     L7ADF
        sta     $EBEC
        jmp     L7A9E

L7A86:  lda     $EBE3
        sta     $EBEB
        lda     $EBE4
        sta     $EBEC
        lda     $EBE7
        sta     $EBEF
        lda     $EBE8
        sta     $EBF0
L7A9E:  lda     $EBEB
        clc
        adc     $D21D
        sta     $EBEB
        lda     $EBEC
        adc     $D21E
        sta     $EBEC
        lda     $EBEF
        clc
        adc     $D21D
        sta     $EBEF
        lda     $EBF0
        adc     $D21E
        sta     $EBF0
        lda     $EBBC
        sta     $EBED
        sta     $EBF1
        lda     $EBBD
        sta     $EBEE
        sta     $EBF2
        rts

L7AD7:  lda     #$DC
        ldx     #$EB
        jmp     L8780

L7ADE:  brk
L7ADF:  brk
L7AE0:  sta     L7B5B
        stx     L7B5C
        ldx     #$06
        lda     #$20
L7AEA:  sta     $EBDC,x
        dex
        bne     L7AEA
        lda     #$00
        sta     L7B5E
        ldy     #$00
        ldx     #$00
L7AF9:  lda     #$00
        sta     L7B5D
L7AFE:  lda     L7B5B
        cmp     L7B53,x
        lda     L7B5C
        sbc     L7B54,x
        bpl     L7B31
        lda     L7B5D
        bne     L7B1A
        bit     L7B5E
        bmi     L7B1A
        lda     #$20
        bne     L7B24
L7B1A:  clc
        adc     #$30
        pha
        lda     #$80
        sta     L7B5E
        pla
L7B24:  sta     $EBDE,y
        iny
        inx
        inx
        cpx     #$08
        beq     L7B4A
        jmp     L7AF9

L7B31:  inc     L7B5D
        lda     L7B5B
        sec
        sbc     L7B53,x
        sta     L7B5B
        lda     L7B5C
        sbc     L7B54,x
        sta     L7B5C
        jmp     L7AFE

L7B4A:  lda     L7B5B
        ora     #$30
        sta     $EBDE,y
        rts

L7B53:  .byte   $10
L7B54:  rmb2    $E8
        .byte   $03
        stz     L0000
        asl     a
        brk
L7B5B:  brk
L7B5C:  brk
L7B5D:  brk
L7B5E:  brk
L7B5F:  brk
L7B60:  brk
L7B61:  brk
L7B62:  brk
L7B63:  brk
L7B64:  brk
L7B65:  brk
L7B66:  brk
L7B67:  brk
L7B68:  brk
L7B69:  brk
L7B6A:  brk
L7B6B:  ldx     #$03
        lda     #$00
L7B6F:  sta     L7B63,x
        dex
        bpl     L7B6F
        sta     L7D5B
        lda     #$FF
        sta     L7B5F
        sta     L7B61
        lda     #$7F
        sta     L7B60
        sta     L7B62
        ldx     $DE9F
        dex
        lda     $E6D1,x
        bpl     L7BCB
        lda     $DEA0
        bne     L7BA1
L7B96:  lda     #$00
        ldx     #$03
L7B9A:  sta     L7B5F,x
        dex
        bpl     L7B9A
        rts

L7BA1:  clc
        adc     #$02
        ldx     #$00
        stx     L7D5C
        asl     a
        rol     L7D5C
        asl     a
        rol     L7D5C
        asl     a
        rol     L7D5C
        sta     L7B65
        lda     L7D5C
        sta     L7B66
        lda     #$68
        sta     L7B63
        lda     #$01
        sta     L7B64
        jmp     L7B96

L7BCB:  lda     $DEA0
        cmp     #$01
        bne     L7BEF
        lda     $DEA1
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$06
        ldx     #$03
L7BE0:  lda     (L0006),y
        sta     L7B5F,x
        sta     L7B63,x
        dey
        dex
        bpl     L7BE0
        jmp     L7BF7

L7BEF:  lda     L7D5B
        cmp     $DEA0
        bne     L7C36
L7BF7:  lda     L7B63
        clc
        adc     #$32
        sta     L7B63
        bcc     L7C05
        inc     L7B64
L7C05:  lda     L7B65
        clc
        adc     #$20
        sta     L7B65
        bcc     L7C13
        inc     L7B66
L7C13:  lda     L7B5F
        sec
        sbc     #$32
        sta     L7B5F
        lda     L7B60
        sbc     #$00
        sta     L7B60
        lda     L7B61
        sec
        sbc     #$0F
        sta     L7B61
        lda     L7B62
        sbc     #$00
        sta     L7B62
        rts

L7C36:  tax
        lda     $DEA1,x
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     (L0006),y
        and     #$0F
        cmp     L7D5C
        bne     L7C52
        inc     L7D5B
        jmp     L7BEF

L7C52:  ldy     #$06
        ldx     #$03
L7C56:  lda     (L0006),y
        sta     L7B67,x
        dey
        dex
        bpl     L7C56
        bit     L7B60
        bmi     L7C88
        bit     L7B68
        bmi     L7CCE
        lda     L7B67
        cmp     L7B5F
        lda     L7B68
        sbc     L7B60
        bmi     L7CCE
        lda     L7B67
        cmp     L7B63
        lda     L7B68
        sbc     L7B64
        bpl     L7CBF
        jmp     L7CDA

L7C88:  bit     L7B68
        bmi     L7CA3
        bit     L7B64
        bmi     L7CDA
        lda     L7B67
        cmp     L7B63
        lda     L7B68
        sbc     L7B64
        bmi     L7CDA
        jmp     L7CBF

L7CA3:  lda     L7B67
        cmp     L7B5F
        lda     L7B68
        sbc     L7B60
        bmi     L7CCE
        lda     L7B67
        cmp     L7B63
        lda     L7B68
        sbc     L7B64
        bmi     L7CDA
L7CBF:  lda     L7B67
        sta     L7B63
        lda     L7B68
        sta     L7B64
        jmp     L7CDA

L7CCE:  lda     L7B67
        sta     L7B5F
        lda     L7B68
        sta     L7B60
L7CDA:  bit     L7B62
        bmi     L7D03
        bit     L7B6A
        bmi     L7D49
        lda     L7B69
        cmp     L7B61
        lda     L7B6A
        sbc     L7B62
        bmi     L7D49
        lda     L7B69
        cmp     L7B65
        lda     L7B6A
        sbc     L7B66
        bpl     L7D3A
        jmp     L7D55

L7D03:  bit     L7B6A
        bmi     L7D1E
        bit     L7B66
        bmi     L7D55
        lda     L7B69
        cmp     L7B65
        lda     L7B6A
        sbc     L7B66
        bmi     L7D55
        jmp     L7D3A

L7D1E:  lda     L7B69
        cmp     L7B61
        lda     L7B6A
        sbc     L7B62
        bmi     L7D49
        lda     L7B69
        cmp     L7B65
        lda     L7B6A
        sbc     L7B66
        bmi     L7D55
L7D3A:  lda     L7B69
        sta     L7B65
        lda     L7B6A
        sta     L7B66
        jmp     L7D55

L7D49:  lda     L7B69
        sta     L7B61
        lda     L7B6A
        sta     L7B62
L7D55:  inc     L7D5B
        jmp     L7BEF

L7D5B:  brk
L7D5C:  brk
L7D5D:  jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$23
        ldx     #$07
L7D68:  lda     (L0006),y
        sta     L7D94,x
        dey
        dex
        bpl     L7D68
        lda     L7D98
        sec
        sbc     L7D94
        pha
        lda     L7D99
        sbc     L7D95
        pha
        lda     L7D9A
        sec
        sbc     L7D96
        pha
        lda     L7D9B
        sbc     L7D97
        pla
        tay
        pla
        tax
        pla
        rts

L7D94:  brk
L7D95:  brk
L7D96:  brk
L7D97:  brk
L7D98:  brk
L7D99:  brk
L7D9A:  brk
L7D9B:  brk
L7D9C:  jmp     L7D9F

L7D9F:  ldx     $DE9F
        dex
        lda     $EC26,x
        ldx     #$00
L7DA8:  cmp     $E1F2,x
        beq     L7DB4
        inx
        cpx     $E1F1
        bne     L7DA8
        rts

L7DB4:  txa
        asl     a
        tax
        lda     $E202,x
        sta     L0006
        sta     $0801
        lda     $E203,x
        sta     $07
        sta     $0802
        lda     $C083
        lda     $C083
        lda     #$00
        sta     L0800
        tay
        lda     (L0006),y
        sta     $0803
        inc     L0006
        inc     $0801
        bne     L7DE4
        inc     $07
        inc     $0802
L7DE4:  lda     L0800
        cmp     $0803
        beq     L7E0C
        jsr     L80CA
        ldy     #$00
        lda     (L0006),y
        and     #$7F
        sta     (L0006),y
        ldy     #$17
        lda     (L0006),y
        bne     L7E06
        iny
        lda     (L0006),y
        bne     L7E06
        lda     #$01
        sta     (L0006),y
L7E06:  inc     L0800
        jmp     L7DE4

L7E0C:  lda     LCBANK1
        lda     LCBANK1
        ldx     $DE9F
        dex
        lda     $E6D1,x
        cmp     #$81
        beq     L7E20
        jmp     L7EC1

L7E20:  lda     $C083
        lda     $C083
        lda     #$5A
        ldx     #$0F
L7E2A:  sta     $0808,x
        dex
        bpl     L7E2A
        lda     #$00
        sta     $0805
        sta     L0800
L7E38:  lda     $0805
        cmp     $0803
        bne     L7E43
        jmp     L80F5

L7E43:  jsr     L80CA
        ldy     #$00
        lda     (L0006),y
        bmi     L7E82
        and     #$0F
        sta     $0804
        ldy     #$01
L7E53:  lda     (L0006),y
        cmp     $0807,y
        beq     L7E5F
        bcs     L7E82
        jmp     L7E67

L7E5F:  iny
        cpy     #$10
        bne     L7E53
        jmp     L7E82

L7E67:  lda     L0800
        sta     $0806
        ldx     #$0F
        lda     #$20
L7E71:  sta     $0808,x
        dex
        bpl     L7E71
        ldy     $0804
L7E7A:  lda     (L0006),y
        sta     $0807,y
        dey
        bne     L7E7A
L7E82:  inc     L0800
        lda     L0800
        cmp     $0803
        beq     L7E90
        jmp     L7E43

L7E90:  inc     $0805
        lda     $0806
        sta     L0800
        jsr     L80CA
        ldy     #$00
        lda     (L0006),y
        ora     #$80
        sta     (L0006),y
        lda     #$5A
        ldx     #$0F
L7EA8:  sta     $0808,x
        dex
        bpl     L7EA8
        ldx     $0805
        dex
        ldy     $0806
        iny
        jsr     L812B
        lda     #$00
        sta     L0800
        jmp     L7E38

L7EC1:  cmp     #$82
        beq     L7EC8
        jmp     L7F58

L7EC8:  lda     $C083
        lda     $C083
        lda     #$00
        sta     $0808
        sta     $0809
        sta     $0805
        sta     L0800
L7EDC:  lda     $0805
        cmp     $0803
        bne     L7EE7
        jmp     L80F5

L7EE7:  jsr     L80CA
        ldy     #$00
        lda     (L0006),y
        bmi     L7F1B
        ldy     #$18
        lda     (L0006),y
        cmp     $0809
        beq     L7EFE
        bcs     L7F08
        jmp     L7F1B

L7EFE:  dey
        lda     (L0006),y
        cmp     $0808
        beq     L7F1B
        bcc     L7F1B
L7F08:  ldy     #$18
        lda     (L0006),y
        sta     $0809
        dey
        lda     (L0006),y
        sta     $0808
        lda     L0800
        sta     $0806
L7F1B:  inc     L0800
        lda     L0800
        cmp     $0803
        beq     L7F29
        jmp     L7EE7

L7F29:  inc     $0805
        lda     $0806
        sta     L0800
        jsr     L80CA
        ldy     #$00
        lda     (L0006),y
        ora     #$80
        sta     (L0006),y
        lda     #$00
        sta     $0808
        sta     $0809
        ldx     $0805
        dex
        ldy     $0806
        iny
        jsr     L812B
        lda     #$00
        sta     L0800
        jmp     L7EDC

L7F58:  cmp     #$83
        beq     L7F5F
        jmp     L801F

L7F5F:  lda     $C083
        lda     $C083
        lda     #$00
        sta     $0808
        sta     $0809
        sta     $0805
        sta     L0800
L7F73:  lda     $0805
        cmp     $0803
        bne     L7F7E
        jmp     L80F5

L7F7E:  jsr     L80CA
        ldy     #$00
        lda     (L0006),y
        bmi     L7FAD
        ldy     #$12
        lda     (L0006),y
        cmp     $0809
        beq     L7F92
        bcs     L7F9C
L7F92:  dey
        lda     (L0006),y
        cmp     $0808
        beq     L7F9C
        bcc     L7FAD
L7F9C:  lda     (L0006),y
        sta     $0808
        iny
        lda     (L0006),y
        sta     $0809
        lda     L0800
        sta     $0806
L7FAD:  inc     L0800
        lda     L0800
        cmp     $0803
        beq     L7FBB
        jmp     L7F7E

L7FBB:  inc     $0805
        lda     $0806
        sta     L0800
        jsr     L80CA
        ldy     #$00
        lda     (L0006),y
        ora     #$80
        sta     (L0006),y
        lda     #$00
        sta     $0808
        sta     $0809
        ldx     $0805
        dex
        ldy     $0806
        iny
        jsr     L812B
        lda     #$00
        sta     L0800
        jmp     L7F73

        lda     LCBANK1
        lda     LCBANK1
        lda     #$54
        sta     $E6D9
        lda     #$00
        sta     $E6DA
        lda     #$CB
        sta     $E6DD
        lda     #$00
        sta     $E6DE
        lda     #$00
        sta     $E6E1
        sta     $E6E2
        lda     #$E7
        sta     $E6E5
        lda     #$00
        sta     $E6E6
        lda     $C083
        lda     $C083
        jmp     L80F5

L801F:  cmp     #$84
        beq     L8024
        rts

L8024:  lda     $FB00
        sta     $08
        lda     $FB01
        sta     $09
        ldy     #$00
        lda     ($08),y
        sta     $0807
        tay
L8036:  lda     ($08),y
        sta     $0807,y
        dey
        bne     L8036
        lda     $C083
        lda     $C083
        lda     #$00
        sta     $0805
        sta     L0800
        lda     #$FF
        sta     $0806
L8051:  lda     $0805
        cmp     $0803
        bne     L805C
        jmp     L80F5

L805C:  jsr     L80CA
        ldy     #$00
        lda     (L0006),y
        bmi     L807E
        ldy     #$10
        lda     (L0006),y
        ldx     $0807
        cpx     #$00
        beq     L8075
        cmp     $0808,x
        bne     L807E
L8075:  lda     L0800
        sta     $0806
        jmp     L809E

L807E:  inc     L0800
        lda     L0800
        cmp     $0803
        beq     L808C
        jmp     L805C

L808C:  lda     $0806
        cmp     #$FF
        bne     L809E
        dec     $0807
        lda     #$00
        sta     L0800
        jmp     L805C

L809E:  inc     $0805
        lda     $0806
        sta     L0800
        jsr     L80CA
        ldy     #$00
        lda     (L0006),y
        ora     #$80
        sta     (L0006),y
        ldx     $0805
        dex
        ldy     $0806
        iny
        jsr     L812B
        lda     #$00
        sta     L0800
        lda     #$FF
        sta     $0806
        jmp     L8051

L80CA:  lda     #$00
        sta     $0804
        lda     L0800
        asl     a
        rol     $0804
        asl     a
        rol     $0804
        asl     a
        rol     $0804
        asl     a
        rol     $0804
        asl     a
        rol     $0804
        clc
        adc     $0801
        sta     L0006
        lda     $0802
        adc     $0804
        sta     $07
        rts

L80F5:  lda     #$00
        sta     L0800
L80FA:  lda     L0800
        cmp     $0803
        beq     L8124
        jsr     L80CA
        ldy     #$00
        lda     (L0006),y
        and     #$7F
        sta     (L0006),y
        ldy     #$17
        lda     (L0006),y
        bne     L811E
        iny
        lda     (L0006),y
        cmp     #$01
        bne     L811E
        lda     #$00
        sta     (L0006),y
L811E:  inc     L0800
        jmp     L80FA

L8124:  lda     LCBANK1
        lda     LCBANK1
        rts

L812B:  lda     LCBANK1
        lda     LCBANK1
        tya
        sta     $DEA1,x
        lda     $C083
        lda     $C083
        rts

L813C:  brk
        brk
L813E:  php
L813F:  ldy     #$00
        tax
        dex
        txa
        sty     L813C
        asl     a
        rol     L813C
        asl     a
        rol     L813C
        asl     a
        rol     L813C
        asl     a
        rol     L813C
        asl     a
        rol     L813C
        clc
        adc     $E71D
        sta     L0006
        lda     $E71E
        adc     L813C
        sta     $07
        lda     $C083
        lda     $C083
        ldy     #$1F
L8171:  lda     (L0006),y
        sta     $EC43,y
        dey
        bpl     L8171
        lda     LCBANK1
        lda     LCBANK1
        ldx     #$31
        lda     #$20
L8183:  sta     $E6EB,x
        dex
        bpl     L8183
        lda     #$00
        sta     $E6EB
        lda     $E6DF
        clc
        adc     L813E
        sta     $E6DF
        bcc     L819D
        inc     $E6E0
L819D:  lda     $E6E3
        clc
        adc     L813E
        sta     $E6E3
        bcc     L81AC
        inc     $E6E4
L81AC:  lda     $E6E7
        clc
        adc     L813E
        sta     $E6E7
        bcc     L81BB
        inc     $E6E8
L81BB:  lda     $E6DB
        cmp     $D223
        lda     $E6DC
        sbc     $D224
        bmi     L81D9
        lda     $E6DB
        clc
        adc     L813E
        sta     $E6DB
        bcc     L81D8
        inc     $E6DC
L81D8:  rts

L81D9:  lda     $E6DB
        clc
        adc     L813E
        sta     $E6DB
        bcc     L81E8
        inc     $E6DC
L81E8:  lda     $E6DB
        cmp     $D21F
        lda     $E6DC
        sbc     $D220
        bpl     L81F7
        rts

L81F7:  jsr     L821F
        lda     #$D9
        ldx     #$E6
        jsr     LD01C
        jsr     L8241
        lda     #$DD
        ldx     #$E6
        jsr     LD01C
        jsr     L8253
        lda     #$E1
        ldx     #$E6
        jsr     LD01C
        jsr     L830F
        lda     #$E5
        ldx     #$E6
        jmp     LD01C

L821F:  lda     $EC43
        and     #$0F
        sta     $E6EB
        tax
L8228:  lda     $EC43,x
        sta     $E6EC,x
        dex
        bne     L8228
        lda     #$20
        sta     $E6EC
        inc     $E6EB
        lda     #$EB
        ldx     #$E6
        jsr     L87BA
        rts

L8241:  lda     $EC53
        jsr     L8707
        ldx     #$04
L8249:  lda     $DFC5,x
        sta     $E6EB,x
        dex
        bpl     L8249
        rts

L8253:  lda     $EC54
        ldx     $EC55
L8259:  sta     L8272
        stx     L8273
        jmp     L8276

L8262:  .byte   $20
        .byte   "Blocks "
L826A:  .byte   $10             ; ???
L826B:  .byte   $27,$E8
        .byte   $03
        stz     L0000
        asl     a
        brk
L8272:  brk
L8273:  brk
L8274:  brk
L8275:  brk
L8276:  ldx     #$11
        lda     #$20
L827A:  sta     $E6EB,x
        dex
        bpl     L827A
        lda     #$00
        sta     $E6EB
        sta     L8275
        ldy     #$00
        ldx     #$00
L828C:  lda     #$00
        sta     L8274
L8291:  lda     L8272
        cmp     L826A,x
        lda     L8273
        sbc     L826B,x
        bpl     L82C3
        lda     L8274
        bne     L82AD
        bit     L8275
        bmi     L82AD
        lda     #$20
        bne     L82B6
L82AD:  ora     #$30
        pha
        lda     #$80
        sta     L8275
        pla
L82B6:  sta     $E6ED,y
        iny
        inx
        inx
        cpx     #$08
        beq     L82DC
        jmp     L828C

L82C3:  inc     L8274
        lda     L8272
        sec
        sbc     L826A,x
        sta     L8272
        lda     L8273
L82D3:  sbc     L826B,x
        sta     L8273
        jmp     L8291

L82DC:  lda     L8272
        ora     #$30
        sta     $E6ED,y
        iny
        ldx     #$00
L82E7:  lda     L8262,x
        sta     $E6ED,y
        iny
        inx
        cpx     L8262
        bne     L82E7
        lda     L8274
        bne     L8305
        bit     L8275
        bmi     L8305
        lda     L8272
        cmp     #$02
        bcc     L8309
L8305:  lda     #$0D
        bne     L830B
L8309:  lda     #$0C
L830B:  sta     $E6EB
        rts

L830F:  ldx     #$15
        lda     #$20
L8313:  sta     $E6EB,x
        dex
        bpl     L8313
        lda     #$01
        sta     $E6EB
        lda     #$EB
        sta     $08
        lda     #$E6
        sta     $09
        lda     $EC5A
        ora     $EC5B
        bne     L8334
        sta     L83DC
        jmp     L83A9

L8334:  lda     $EC5B
        and     #$FE
        lsr     a
        sta     L83DB
        lda     $EC5B
        ror     a
        lda     $EC5A
        ror     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     L83DC
        lda     $EC5A
        and     #$1F
        sta     L83DD
        jsr     L83A9
        jsr     L835D
        jmp     L83B8

L835D:  lda     #$20
        sta     L83DF
        sta     L83E0
        sta     L83E1
        ldx     #$02
        lda     L83DD
        ora     #$30
        tay
        lda     L83DD
        cmp     #$0A
        bcc     L8386
        inx
        ldy     #$31
        cmp     #$14
        bcc     L8386
        ldy     #$32
        cmp     #$1E
        bcc     L8386
        ldy     #$33
L8386:  stx     L83DE
        sty     L83DF
        cpx     #$02
        beq     L83A2
        tya
        and     #$03
        tay
        lda     L83DD
L8397:  sec
        sbc     #$0A
        dey
        bne     L8397
        ora     #$30
        sta     L83E0
L83A2:  lda     #$DE
        ldx     #$83
        jmp     L84A4

L83A9:  lda     L83DC
        asl     a
        tay
        lda     L83E3,y
        tax
        lda     L83E2,y
        jmp     L84A4

L83B8:  ldx     L8490
L83BB:  lda     L83DB
        sec
        sbc     L8490,x
        bpl     L83C7
        dex
        bne     L83BB
L83C7:  tay
        lda     L849A,x
        sta     L848E
        lda     L849A,y
        sta     L848F
        lda     #$8A
        ldx     #$84
        jmp     L84A4

L83DB:  .byte   $00
L83DC:  .byte   $00
L83DD:  .byte   $00
L83DE:  .byte   $03
L83DF:  .byte   $20
L83E0:  .byte   $20
L83E1:  .byte   $20
L83E2:  .byte   $FC
L83E3:  .byte   $83,$06,$84,$11,$84,$1C,$84,$27
        .byte   $84,$32,$84,$3D,$84,$48,$84,$53
        .byte   $84,$5E,$84,$69,$84,$74,$84,$7F
        .byte   $84
        PASCAL_STRING "no date  "
        PASCAL_STRING "January   "
        PASCAL_STRING "February  "
        PASCAL_STRING "March     "
        PASCAL_STRING "April     "
        PASCAL_STRING "May       "
        PASCAL_STRING "June      "
        PASCAL_STRING "July      "
        PASCAL_STRING "August    "
        PASCAL_STRING "September "
        PASCAL_STRING "October   "
        PASCAL_STRING "November  "
        PASCAL_STRING "December  "
        PASCAL_STRING " 1985"
L848E  := *-2                   ; 10s digit
L848F  := *-1                   ; 1s digit

L8490:  .byte   $09             ; ????
        asl     a
        trb     $1E
        plp
        and     ($3C)
        lsr     $50
        phy
L849A:  .byte   "0123456789"
L84A4:  sta     L0006
        stx     $07
        ldy     #$00
        lda     ($08),y
        sta     L84D0
        clc
        adc     (L0006),y
        sta     ($08),y
        lda     (L0006),y
        sta     L84CB
        inc     L84D0
        iny
        lda     (L0006),y
        sty     L84CF
        ldy     L84D0
        sta     ($08),y
        ldy     L84CF
        .byte   $C0
L84CB:  brk
        .byte   $90
L84CD:  .byte   $EB
        rts

L84CF:  brk
L84D0:  brk
L84D1:  jsr     L87F6
        bit     L5B1B
        bmi     L84DC
        jsr     L6E52
L84DC:  lda     $D221
        sec
        sbc     $D21D
        sta     L85F8
        lda     $D222
        sbc     $D21E
        sta     L85F9
        lda     $D223
        sec
        sbc     $D21F
        sta     L85FA
        lda     $D224
        sbc     $D220
        sta     L85FB
        lda     $D208
        cmp     #$01
        bne     L850C
        asl     a
        bne     L850E
L850C:  lda     #$00
L850E:  sta     L85F1
        lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        lda     #$06
        clc
        adc     L85F1
        tay
        lda     (L0006),y
        pha
        jsr     L7B6B
        ldx     L85F1
        lda     L7B63,x
        sec
        sbc     L7B5F,x
        sta     L85F2
        lda     L7B64,x
        sbc     L7B60,x
        sta     L85F3
        ldx     L85F1
        lda     L85F2
        sec
        sbc     L85F8,x
        sta     L85F2
        lda     L85F3
        sbc     L85F9,x
        sta     L85F3
        bpl     L8562
        lda     L85F8,x
        sta     L85F2
        lda     L85F9,x
        sta     L85F3
L8562:  lsr     L85F3
        ror     L85F2
        lsr     L85F3
        ror     L85F2
        lda     L85F2
        tay
        pla
        tax
        lda     $D209
        jsr     L62BC
        ldx     #$00
        stx     L85F2
        asl     a
        rol     L85F2
        asl     a
        rol     L85F2
        ldx     L85F1
        clc
        adc     L7B5F,x
        sta     $D21D,x
        lda     L85F2
        adc     L7B60,x
        sta     $D21E,x
        lda     $EC25
        jsr     L7D5D
        sta     L85F4
        .byte   $8E
        .byte   $F5
L85A5:  sta     $8C
        inc     $85,x
        lda     L85F1
        beq     L85C3
        lda     $D21F
        clc
        adc     L85F6
        sta     $D223
        lda     $D220
        adc     #$00
        sta     $D224
        jmp     L85D6

L85C3:  lda     $D21D
        clc
        adc     L85F4
        sta     $D221
        lda     $D21E
        adc     L85F5
        sta     $D222
L85D6:  lda     $EC25
        jsr     L86EF
        sta     L0006
        stx     $07
        ldy     #$23
        ldx     #$07
L85E4:  lda     $D21D,x
        sta     (L0006),y
        dey
        dex
        bpl     L85E4
        jsr     L8813
        rts

L85F1:  brk
L85F2:  brk
L85F3:  brk
L85F4:  brk
L85F5:  brk
L85F6:  brk
        brk
L85F8:  brk
L85F9:  brk
L85FA:  brk
L85FB:  brk
L85FC:  ldx     #$03
L85FE:  lda     $D209,x
        sta     L86A0,x
        sta     $EBFD,x
        dex
        bpl     L85FE
        lda     #$00
        sta     L869F
        lda     $D2AB
        asl     a
        rol     L869F
        sta     L869E
L8619:  dec     L869E
        bne     L8626
        dec     L869F
        lda     L869F
        bne     L8655
L8626:  jsr     L48F0
        jsr     L8658
        bmi     L8655
        lda     #$FF
        sta     L86A6
        lda     $D208
        sta     L86A5
        cmp     #$00
        beq     L8619
        cmp     #$04
        beq     L8619
        cmp     #$02
        bne     L864B
        jsr     L48E6
        jmp     L8619

L864B:  cmp     #$01
        bne     L8655
        jsr     L48E6
        lda     #$00
        rts

L8655:  lda     #$FF
        rts

L8658:  lda     $D209
        sec
        sbc     L86A0
        sta     L86A4
        lda     $D20A
        sbc     L86A1
        bpl     L8674
        lda     L86A4
        cmp     #$F8
        bcs     L867B
L8671:  lda     #$FF
        rts

L8674:  lda     L86A4
        cmp     #$08
        bcs     L8671
L867B:  lda     $D20B
        sec
        sbc     L86A2
        sta     L86A4
        lda     $D20C
        sbc     L86A3
        bpl     L8694
        lda     L86A4
        cmp     #$F9
        bcs     L869B
L8694:  lda     L86A4
        cmp     #$07
        bcs     L8671
L869B:  lda     #$00
        rts

L869E:  brk
L869F:  brk
L86A0:  brk
L86A1:  brk
L86A2:  brk
L86A3:  brk
L86A4:  brk
L86A5:  brk
L86A6:  brk
L86A7:  ldx     #$00
        stx     L86C0
        asl     a
        rol     L86C0
        asl     a
        rol     L86C0
        asl     a
        rol     L86C0
        asl     a
        rol     L86C0
        ldx     L86C0
        rts

L86C0:  brk
L86C1:  ldx     #$00
        stx     L86E2
        asl     a
        rol     L86E2
        asl     a
        rol     L86E2
        asl     a
        rol     L86E2
        asl     a
        rol     L86E2
        asl     a
        rol     L86E2
        asl     a
        rol     L86E2
        ldx     L86E2
        rts

L86E2:  brk
L86E3:  asl     a
        tax
        lda     $DD9F,x
        pha
        lda     $DDA0,x
        tax
        pla
        rts

L86EF:  asl     a
        tax
        lda     $DFA1,x
        pha
        lda     $DFA2,x
        tax
        pla
        rts

L86FB:  asl     a
        tax
        lda     $DFB3,x
        pha
        lda     $DFB4,x
        tax
        pla
        rts

L8707:  sta     L877F
        lda     $FB00
        sta     L0006
        lda     $FB01
        sta     $07
        ldy     #$00
        lda     (L0006),y
        tay
L8719:  lda     (L0006),y
        cmp     L877F
        beq     L8726
        dey
        bne     L8719
        jmp     L8745

L8726:  tya
        asl     a
        asl     a
        tay
        lda     $FB06
        sta     L0006
        lda     $FB07
        sta     $07
        ldx     #$00
L8736:  lda     (L0006),y
        sta     $DFC6,x
        iny
        inx
        cpx     #$04
        bne     L8736
        stx     $DFC5
        rts

L8745:  lda     #$04
        sta     $DFC5
        lda     #$20
        sta     $DFC6
        lda     #$24
        sta     $DFC7
        lda     L877F
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        cmp     #$0A
        bcs     L8764
        clc
        adc     #$30
        bne     L8767
L8764:  clc
        adc     #$37
L8767:  sta     $DFC8
        lda     L877F
        and     #$0F
        cmp     #$0A
        bcs     L8778
        clc
        adc     #$30
        bne     L877B
L8778:  clc
        adc     #$37
L877B:  sta     $DFC9
        rts

L877F:  brk
L8780:  sta     L0006
        stx     $07
        ldy     #$00
        lda     (L0006),y
        beq     L879B
        sta     $08
        inc     L0006
        bne     L8792
        inc     $07
L8792:  A2D_RELAY_CALL A2D_DRAW_TEXT, $0006
L879B:  rts

        sta     L0006
        stx     $07
        ldy     #$00
        lda     (L0006),y
        sta     $08
        inc     L0006
        bne     L87AC
        inc     $07
L87AC:  A2D_RELAY_CALL A2D_MEASURE_TEXT, $0006
        lda     $09
        ldx     $0A
        rts

L87BA:  stx     $0B
        sta     $0A
        ldy     #$00
        lda     ($0A),y
        tay
        bne     L87C6
        rts

L87C6:  dey
        beq     L87CB
        bpl     L87CC
L87CB:  rts

L87CC:  lda     ($0A),y
        and     #$7F
        cmp     #$2F
        beq     L87DC
        cmp     #$20
        beq     L87DC
        cmp     #$2E
        bne     L87E0
L87DC:  dey
        jmp     L87C6

L87E0:  iny
        lda     ($0A),y
        and     #$7F
        cmp     #$41
        bcc     L87F2
        cmp     #$5B
        bcs     L87F2
        clc
        adc     #$20
        sta     ($0A),y
L87F2:  dey
        jmp     L87C6

L87F6:  pla
        sta     L8811
        pla
        sta     L8812
        ldx     #$00
L8800:  lda     L0006,x
        pha
        inx
        cpx     #$04
        bne     L8800
        lda     L8812
        pha
        lda     L8811
        pha
        rts

L8811:  brk
L8812:  brk
L8813:  pla
        sta     L882E
        pla
        sta     L882F
        ldx     #$03
L881D:  pla
        sta     L0006,x
        dex
        cpx     #$FF
        bne     L881D
        lda     L882F
        pha
        lda     L882E
        pha
        rts

L882E:  brk
L882F:  brk
L8830:  brk
L8831:  brk
L8832:  brk
L8833:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
L8855:  tay
        jsr     L87F6
        tya
        jsr     L86EF
        sta     L0006
        stx     $07
        ldx     #$00
        ldy     #$14
L8865:  lda     (L0006),y
        sta     L8830,x
        iny
        inx
        cpx     #$24
        bne     L8865
        jsr     L8813
        rts

L8874:  tay
        jsr     L87F6
        tya
        jsr     L86EF
        sta     L0006
        stx     $07
        ldx     #$00
        ldy     #$14
L8884:  lda     L8830,x
        sta     (L0006),y
        iny
        inx
        cpx     #$24
        bne     L8884
        jsr     L8813
        rts

L8893:  tay
        jsr     L87F6
        tya
        jsr     L86E3
        sta     L0006
        stx     $07
        lda     $EC25
        jsr     L86EF
        sta     $08
        stx     $09
        ldy     #$17
        ldx     #$03
L88AD:  lda     ($08),y
        sta     L890D,x
        dey
        dex
        bpl     L88AD
        ldy     #$1F
        ldx     #$03
L88BA:  lda     ($08),y
        sta     L8911,x
        dey
        dex
        bpl     L88BA
        ldy     #$03
        lda     (L0006),y
        clc
        adc     L890D
        sta     (L0006),y
        iny
        lda     (L0006),y
        adc     L890E
        sta     (L0006),y
        iny
        lda     (L0006),y
        clc
        adc     L890F
        sta     (L0006),y
        iny
        lda     (L0006),y
        adc     L8910
        sta     (L0006),y
        ldy     #$03
        lda     (L0006),y
        sec
        sbc     L8911
        sta     (L0006),y
        iny
        lda     (L0006),y
        sbc     L8912
        sta     (L0006),y
        iny
        lda     (L0006),y
        sec
        sbc     L8913
        sta     (L0006),y
        iny
        lda     (L0006),y
        sbc     L8914
        sta     (L0006),y
        jsr     L8813
        rts

L890D:  brk
L890E:  brk
L890F:  brk
L8910:  brk
L8911:  brk
L8912:  brk
L8913:  brk
L8914:  brk
L8915:  tay
        jsr     L87F6
        tya
        jsr     L86E3
        sta     L0006
        stx     $07
L8921:  lda     $EC25
        jsr     L86EF
        sta     $08
        stx     $09
        ldy     #$17
        ldx     #$03
L892F:  lda     ($08),y
        sta     L898F,x
        dey
        dex
        bpl     L892F
        ldy     #$1F
        ldx     #$03
L893C:  lda     ($08),y
        sta     L8993,x
        dey
        dex
        bpl     L893C
        ldy     #$03
        lda     (L0006),y
        sec
        sbc     L898F
        sta     (L0006),y
        iny
        lda     (L0006),y
        sbc     L8990
        sta     (L0006),y
        iny
        lda     (L0006),y
        sec
        sbc     L8991
        sta     (L0006),y
        iny
        lda     (L0006),y
        sbc     L8992
        sta     (L0006),y
        ldy     #$03
        lda     (L0006),y
        clc
        adc     L8993
        sta     (L0006),y
        iny
        lda     (L0006),y
        adc     L8994
        sta     (L0006),y
        iny
        lda     (L0006),y
        clc
        adc     L8995
        sta     (L0006),y
        iny
        lda     (L0006),y
        adc     L8996
        sta     (L0006),y
        jsr     L8813
        rts

L898F:  brk
L8990:  brk
L8991:  brk
L8992:  brk
L8993:  brk
L8994:  brk
L8995:  brk
L8996:  brk
L8997:  lda     #$00
        tax
L899A:  sta     $D265,x
        sta     $D25D,x
        sta     $D269,x
        inx
        cpx     #$04
        bne     L899A
        A2D_RELAY_CALL A2D_SET_STATE, $D25D
        rts

        .byte   $02
L89B3:  brk
        brk
        php
L89B6:  sta     L8AC3
        sty     L8AC4
        and     #$F0
        sta     L89B3
        ldy     #$C5
        lda     #$B2
        ldx     #$89
        jsr     L46BA
        beq     L89DD
L89CC:  pha
        ldy     L8AC4
        lda     #$00
        sta     $E1A0,y
        dec     $DEA0
        dec     $DD9E
        pla
        rts

L89DD:  lda     L0800
        and     #$0F
        bne     L89EA
        lda     $0801
        jmp     L89CC

L89EA:  jsr     L87F6
        jsr     LD05E
        ldy     L8AC4
        sta     $E1A0,y
        jsr     L86E3
        sta     L0006
        stx     $07
        ldx     #$00
        ldy     #$09
        lda     #$20
L8A03:  sta     (L0006),y
        iny
        inx
        cpx     #$12
        bne     L8A03
        ldy     #$09
        lda     L0800
        and     #$0F
        sta     L0800
        sta     (L0006),y
        lda     #$00
        ldx     #$08
        jsr     L87BA
        ldx     #$00
        ldy     #$0B
L8A22:  lda     $0801,x
        sta     (L0006),y
        iny
        inx
        cpx     L0800
        bne     L8A22
        ldy     #$09
        lda     (L0006),y
        clc
        adc     #$02
        sta     (L0006),y
        lda     L8AC3
        cmp     #$3E
        beq     L8A59
        and     #$0F
        cmp     #$04
        bne     L8A75
        lda     L8AC3
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$C0
        sta     L8A54
        .byte   $AD
        .byte   $FB
L8A54:  smb4    $29
        ora     ($F0,x)
        .byte   $0E
L8A59:  ldy     #$07
        lda     #$CC
        sta     (L0006),y
        iny
        lda     #$A9
        sta     (L0006),y
        jmp     L8A96

L8A67:  ldy     #$07
        lda     #$50
        sta     (L0006),y
        iny
        lda     #$AA
        sta     (L0006),y
        jmp     L8A96

L8A75:  cmp     #$0B
        bne     L8A87
        ldy     #$07
        lda     #$20
        sta     (L0006),y
        iny
        lda     #$AA
        sta     (L0006),y
        jmp     L8A96

L8A87:  cmp     #$00
        bne     L8A67
        ldy     #$07
        lda     #$80
        sta     (L0006),y
        iny
        lda     #$A9
        sta     (L0006),y
L8A96:  ldy     #$02
        lda     #$00
        sta     (L0006),y
        inc     L8AC4
        lda     L8AC4
        asl     a
        asl     a
        tax
        ldy     #$03
L8AA7:  lda     L8AC5,x
        sta     (L0006),y
        inx
        iny
        cpy     #$07
        bne     L8AA7
        ldx     $DEA0
        dex
        ldy     #$00
        lda     (L0006),y
        sta     $DEA1,x
        jsr     L8813
        lda     #$00
        rts

L8AC3:  .byte   $00
L8AC4:  .byte   $00
L8AC5:  .byte   $00,$00,$00,$00,$EA,$01,$10,$00
        .byte   $EA,$01,$2D,$00,$EA,$01,$4B,$00
        .byte   $EA,$01,$67,$00,$EA,$01,$83,$00
        .byte   $90,$01,$A0,$00,$36,$01,$A0,$00
        .byte   $DC,$00,$A0,$00,$82,$00,$A0,$00
        .byte   $28,$00,$A0,$00,$01,$24
        pha
L8AF4:  ldx     $DEA0
        dex
L8AF8:  cmp     $DEA1,x
        beq     L8B01
        dex
        bpl     L8AF8
        rts

L8B01:  lda     $DEA2,x
        sta     $DEA1,x
        inx
        cpx     $DEA0
        bne     L8B01
        dec     $DEA0
        ldx     $DEA0
        lda     #$00
        sta     $DEA1,x
        rts

L8B19:  jsr     L87F6
        jmp     L8B2E

L8B1F:  lda     $E6BE
        bne     L8B25
        rts

L8B25:  jsr     L87F6
        lda     $E6BE
        jsr     L7345
L8B2E:  lda     $E6BE
        ldx     #$07
L8B33:  cmp     $EC26,x
        beq     L8B3E
        dex
        bpl     L8B33
        jmp     L8B43

L8B3E:  lda     #$00
        sta     $EC26,x
L8B43:  lda     $E6BE
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     (L0006),y
        and     #$7F
        sta     (L0006),y
        jsr     L4244
        jsr     L8813
        rts

L8B5C:  ldy     #$80
        bne     L8B62
L8B60:  ldy     #$00
L8B62:  sty     L8D4A
        sta     L8D4B
        stx     L8D4C
        txa
        jsr     L86EF
        sta     L0006
        stx     $07
        lda     #$14
        clc
        adc     #$23
        tay
        ldx     #$23
L8B7B:  lda     (L0006),y
        sta     $D215,x
        dey
        dex
        bpl     L8B7B
        lda     L8D4B
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$03
        lda     (L0006),y
        clc
        adc     #$07
        sta     L0800
        sta     $0804
        iny
        lda     (L0006),y
        adc     #$00
        sta     $0801
        sta     $0805
        iny
        lda     (L0006),y
        clc
        adc     #$07
        sta     $0802
        sta     $0806
        iny
        lda     (L0006),y
        adc     #$00
        sta     $0803
        sta     $0807
        ldy     #$5B
        ldx     #$03
L8BC1:  lda     $D215,x
        sta     L0800,y
        dey
        dex
        bpl     L8BC1
        lda     $D221
        sec
        sbc     $D21D
        sta     L8D54
        lda     $D222
        sbc     $D21E
        sta     L8D55
        lda     $D223
        sec
        sbc     $D21F
        sta     L8D56
        lda     $D224
        sbc     $D220
        sta     L8D57
        lda     $0858
        clc
        adc     L8D54
        sta     $085C
        lda     $0859
        adc     L8D55
        sta     $085D
        lda     $085A
        clc
        adc     L8D56
        sta     $085E
        lda     $085B
        adc     L8D57
        sta     $085F
        lda     #$00
        sta     L8D4E
        sta     L8D4F
        sta     L8D4D
        lda     $0858
        sec
        sbc     L0800
        sta     L8D50
        lda     $0859
        sbc     $0801
        sta     L8D51
        lda     $085A
        sec
        sbc     $0802
        sta     L8D52
        lda     $085B
        sbc     $0803
        sta     L8D53
        bit     L8D51
        bpl     L8C6A
        lda     #$80
        sta     L8D4E
        lda     L8D50
        eor     #$FF
        sta     L8D50
        lda     L8D51
        eor     #$FF
        sta     L8D51
        inc     L8D50
        bne     L8C6A
        inc     L8D51
L8C6A:  bit     L8D53
        bpl     L8C8C
        lda     #$80
        sta     L8D4F
        lda     L8D52
        eor     #$FF
        sta     L8D52
        lda     L8D53
        eor     #$FF
        sta     L8D53
        inc     L8D52
        bne     L8C8C
        inc     L8D53
L8C8C:  lsr     L8D51
        ror     L8D50
        lsr     L8D53
        ror     L8D52
        lsr     L8D55
        ror     L8D54
        lsr     L8D57
        ror     L8D56
        lda     #$0A
        sec
        sbc     L8D4D
        asl     a
        asl     a
        asl     a
        tax
        bit     L8D4E
        bpl     L8CC9
        lda     L0800
        sec
        sbc     L8D50
        sta     L0800,x
        lda     $0801
        sbc     L8D51
        sta     $0801,x
        jmp     L8CDC

L8CC9:  lda     L0800
        clc
        adc     L8D50
        sta     L0800,x
        lda     $0801
        adc     L8D51
        sta     $0801,x
L8CDC:  bit     L8D4F
        bpl     L8CF7
        lda     $0802
        sec
        sbc     L8D52
        sta     $0802,x
        lda     $0803
        sbc     L8D53
        sta     $0803,x
        jmp     L8D0A

L8CF7:  lda     $0802
        clc
        adc     L8D52
        sta     $0802,x
        lda     $0803
        adc     L8D53
        sta     $0803,x
L8D0A:  lda     L0800,x
        clc
        adc     L8D54
        sta     $0804,x
        lda     $0801,x
        adc     L8D55
        sta     $0805,x
        lda     $0802,x
        clc
        adc     L8D56
        sta     $0806,x
        lda     $0803,x
        adc     L8D57
        sta     $0807,x
        inc     L8D4D
        lda     L8D4D
        cmp     #$0A
        beq     L8D3D
        jmp     L8C8C

L8D3D:  bit     L8D4A
        bmi     L8D46
        jsr     L8D58
        rts

L8D46:  jsr     L8DB3
        rts

L8D4A:  brk
L8D4B:  brk
L8D4C:  brk
L8D4D:  brk
L8D4E:  brk
L8D4F:  brk
L8D50:  brk
L8D51:  brk
L8D52:  brk
L8D53:  brk
L8D54:  brk
L8D55:  brk
L8D56:  brk
L8D57:  brk
L8D58:  lda     #$00
        sta     L8DB2
        jsr     L4510
        A2D_RELAY_CALL A2D_SET_PATTERN, $D293
        jsr     L48FA
L8D6C:  lda     L8DB2
        cmp     #$0C
        bcs     L8D89
        asl     a
        asl     a
        asl     a
        clc
        adc     #$07
        tax
        ldy     #$07
L8D7C:  lda     L0800,x
        sta     $E230,y
        dex
        dey
        bpl     L8D7C
        jsr     L8E10
L8D89:  lda     L8DB2
        sec
        sbc     #$02
        bmi     L8DA7
        asl     a
L8D92:  asl     a
        asl     a
        clc
        adc     #$07
        tax
        ldy     #$07
L8D9A:  lda     L0800,x
        sta     $E230,y
        dex
        dey
        bpl     L8D9A
        jsr     L8E10
L8DA7:  inc     L8DB2
        lda     L8DB2
        cmp     #$0E
        bne     L8D6C
        rts

L8DB2:  brk
L8DB3:  lda     #$0B
        sta     L8E0F
        jsr     L4510
        A2D_RELAY_CALL A2D_SET_PATTERN, $D293
        jsr     L48FA
L8DC7:  lda     L8E0F
        bmi     L8DE4
        beq     L8DE4
        asl     a
        asl     a
        asl     a
        clc
        adc     #$07
        tax
        ldy     #$07
L8DD7:  lda     L0800,x
        sta     $E230,y
        dex
        dey
        bpl     L8DD7
        jsr     L8E10
L8DE4:  lda     L8E0F
        clc
        adc     #$02
        cmp     #$0E
        bcs     L8E04
        asl     a
        asl     a
        asl     a
        clc
        adc     #$07
        tax
        ldy     #$07
        lda     L0800,x
        sta     $E230,y
        dex
        dey
        .byte   $10
UNKNOWN_CALL:
        inc     L0020,x
        bpl     L8D92
L8E04:  dec     L8E0F
        lda     L8E0F
        cmp     #$FD
        bne     L8DC7
        rts

L8E0F:  brk
L8E10:  A2D_RELAY_CALL A2D_DRAW_RECT, $E230
        rts

L8E1A:  .byte   $E0
L8E1B:  .byte   $2F
L8E1C:  .byte   $01,$00,$E0,$60,$01,$00,$E0,$74
        .byte   $01,$00,$E0,$84,$01,$00,$E0,$A4
        .byte   $01,$00,$E0,$AC,$01,$00,$E0,$B4
        .byte   $01,$00,$80,$B7,$00,$00,$80,$F7
        .byte   $00,$00
L8E3E:  .byte   $00
L8E3F:  .byte   $02,$00,$14,$00,$10,$00,$20,$00
        .byte   $08,$00,$08,$00,$08,$00,$28,$00
        .byte   $10
L8E50:  .byte   $00
L8E51:  .byte   $08,$00,$08,$00,$90,$00,$50,$00
        .byte   $70,$00,$70,$00,$70,$00,$50,$00
        .byte   $90,$03,$68,$8E,$00,$1C
L8E67:  .byte   $00,$08,$44,$65,$73,$6B,$54,$6F
        .byte   $70,$32,$02
L8E72:  .byte   $00
L8E73:  .byte   $00
L8E74:  .byte   $00
L8E75:  .byte   $00,$04
L8E77:  .byte   $00
L8E78:  .byte   $00
L8E79:  .byte   $00
L8E7A:  .byte   $00
L8E7B:  .byte   $00,$00,$00,$01,$00
L8E80:  .byte   $00
L8E81:  pha
        lda     #$00
        sta     L8E80
        beq     L8E8F
L8E89:  pha
        lda     #$80
        sta     L8E80
L8E8F:  pla
        asl     a
        tay
        asl     a
        tax
        lda     L8E1A,x
        sta     L8E73
        lda     L8E1B,x
        sta     L8E74
        lda     L8E1C,x
        sta     L8E75
        lda     L8E3E,y
        sta     L8E7A
        lda     L8E3F,y
        sta     L8E7B
        lda     L8E50,y
        sta     L8E78
        lda     L8E51,y
        sta     L8E79
L8EBE:  ldy     #$C8
        lda     #$62
        ldx     #$8E
        jsr     L46BA
        beq     L8ED6
        lda     #$00
        ora     L8E80
        jsr     L48CC
        beq     L8EBE
        lda     #$FF
        rts

L8ED6:  lda     L8E67
        sta     L8E77
        sta     L8E72
        ldy     #$CE
        lda     #$71
        ldx     #$8E
        jsr     L46BA
        ldy     #$CA
        lda     #$76
        ldx     #$8E
        jsr     L46BA
        ldy     #$CC
        lda     #$7E
        ldx     #$8E
        jsr     L46BA
        rts

        brk
        brk
        brk
        brk
        brk
L8F00:  jmp     L8FC5

        jmp     L97E3

        jmp     L97E3

L8F09:  jmp     L92E7

L8F0C:  jmp     L8F9B

L8F0F:  jmp     L8FA1

L8F12:  jmp     L9571

L8F15:  jmp     L9213

L8F18:  jmp     L8F2A

L8F1B:  jmp     L8F5B

        jmp     L97E3

        jmp     L97E3

L8F24:  jmp     L8F7E

L8F27:  jmp     L8FB8

L8F2A:  lda     #$00
        sta     L9189
        tsx
        stx     L9188
        jsr     LA248
        jsr     L993E
        jsr     LA271
        jsr     L9968
L8F3F:  lda     #$FF
        sta     $E05B
        lda     #$00
        sta     $E05C
        jsr     L9A0D
        jsr     L917F
L8F4F:  jsr     L91E8
        lda     #$00
        rts

        jsr     L91D5
        jmp     L8F4F

L8F5B:  lda     #$00
        sta     L9189
        tsx
        stx     L9188
        jsr     LA248
        lda     #$00
        jsr     L9E7E
        jsr     LA271
        jsr     L9182
        jsr     L9EBF
        jsr     L9EDB
        jsr     L917F
        jmp     L8F4F

L8F7E:  lda     #$80
        sta     L918C
        lda     #$C0
        sta     L9189
        tsx
        stx     L9188
        jsr     LA248
        jsr     L9984
        jsr     LA271
        jsr     L99BC
        jmp     L8F3F

L8F9B:  jsr     L8FDD
        jmp     L8F4F

L8FA1:  jsr     L8FE1
        jmp     L8F4F

L8FA7:  asl     a
        tay
        lda     $DD9F,y
        sta     L0006
        lda     $DDA0,y
        sta     $07
        ldy     #$02
        lda     (L0006),y
        rts

L8FB8:  lda     #$00
        sta     L918C
        lda     #$C0
        sta     L9189
        jmp     L8FEB

L8FC5:  lda     $EBFC
        cmp     #$01
        bne     L8FD0
        lda     #$80
        bne     L8FD2
L8FD0:  lda     #$00
L8FD2:  sta     L918A
        lda     #$00
        sta     L9189
        jmp     L8FEB

L8FDD:  lda     #$00
        beq     L8FE3
L8FE1:  lda     #$80
L8FE3:  sta     L918B
        lda     #$80
        sta     L9189
L8FEB:  tsx
        stx     L9188
        lda     #$00
        sta     $E05C
        jsr     L91D5
        lda     L9189
        beq     L8FFF
        jmp     L908C

L8FFF:  .byte   $2C
L9000:  txa
        sta     ($10),y
        ora     $20AD
        bbs5    $F0,L900C
        jmp     L908C

L900C:  pla
        pla
        jmp     L4012

        lda     $EBFC
        bpl     L9032
        and     #$7F
        asl     a
        tax
        lda     $DFB3,x
        sta     $08
        lda     $DFB4,x
        sta     $09
        lda     #$7B
        sta     L0006
        lda     #$91
        sta     $07
        jsr     L91A0
        jmp     L9076

L9032:  jsr     L8FA7
        and     #$0F
        beq     L9051
        asl     a
        tax
        lda     $DFB3,x
        sta     $08
        lda     $DFB4,x
        sta     $09
        lda     $EBFC
        jsr     L918E
        jsr     L91A0
        jmp     L9076

L9051:  lda     $EBFC
        jsr     L918E
        ldy     #$01
        lda     #$2F
        sta     (L0006),y
        dey
        lda     (L0006),y
        sta     L906D
        sta     $E00A,y
L9066:  iny
        lda     (L0006),y
        sta     $E00A,y
        .byte   $C0
L906D:  brk
        bne     L9066
        ldy     #$01
        lda     #$20
        sta     (L0006),y
L9076:  ldy     #$FF
L9078:  iny
        lda     $E00A,y
        sta     $DFC9,y
        cpy     $E00A
        bne     L9078
        lda     $DFC9
        beq     L908C
        dec     $DFC9
L908C:  lda     #$00
        sta     L97E4
        jsr     LA248
        bit     L9189
        bvs     L90B4
        bmi     L90AE
        bit     L918A
        bmi     L90A6
        jsr     L993E
        jmp     L90DE

L90A6:  lda     #$06
        jsr     L9E7E
        jmp     L90DE

L90AE:  jsr     LA059
        jmp     L90DE

L90B4:  jsr     LA1E4
        jmp     L90DE

L90BA:  bit     L9189
        bvs     L90D8
        bmi     L90D2
        bit     L918A
        bmi     L90CC
        jsr     L9968
        jmp     L90DE

L90CC:  jsr     L9EBF
        jmp     L90DE

L90D2:  jsr     LA0DF
        jmp     L90DE

L90D8:  jsr     LA241
        jmp     L90DE

L90DE:  jsr     L91F5
        lda     $DF21
        bne     L90E9
        jmp     L9168

L90E9:  ldx     #$00
        stx     L917A
L90EE:  jsr     L91F5
        ldx     L917A
        lda     $DF22,x
        cmp     #$01
        beq     L9140
        jsr     L918E
        jsr     L91A0
        lda     #$0A
        sta     L0006
        lda     #$E0
        sta     $07
        ldy     #$00
        lda     (L0006),y
        beq     L9114
        sec
        sbc     #$01
        sta     (L0006),y
L9114:  lda     L97E4
        beq     L913D
        bit     L9189
        bmi     L912F
        bit     L918A
        bmi     L9129
        jsr     L9A01
        jmp     L9140

L9129:  jsr     L9EDB
        jmp     L9140

L912F:  bvs     L9137
        jsr     LA114
        jmp     L9140

L9137:  jsr     LA271
        jmp     L9140

L913D:  jsr     LA271
L9140:  inc     L917A
        ldx     L917A
        cpx     $DF21
        bne     L90EE
        lda     L97E4
        bne     L9168
        inc     L97E4
        bit     L9189
        bmi     L915D
        bit     L918A
        bpl     L9165
L915D:  jsr     L9182
        bit     L9189
        bvs     L9168
L9165:  jmp     L90BA

L9168:  jsr     L917F
        lda     $EBFC
        jsr     L918E
        ldy     #$01
        lda     #$20
        sta     (L0006),y
        lda     #$00
        rts

L917A:  brk
        brk
L917C:  .byte   $4C
L917D:  brk
L917E:  brk
L917F:  .byte   $4C
L9180:  brk
L9181:  brk
L9182:  .byte   $4C
L9183:  brk
L9184:  brk
L9185:  .byte   $4C
L9186:  brk
L9187:  brk
L9188:  brk
L9189:  brk
L918A:  brk
L918B:  brk
L918C:  brk
L918D:  brk
L918E:  asl     a
        tay
        lda     $DD9F,y
        clc
        adc     #$09
        sta     L0006
        lda     $DDA0,y
        adc     #$00
        sta     $07
        rts

L91A0:  ldx     #$00
        ldy     #$00
        lda     ($08),y
        beq     L91B6
        sta     L91B3
L91AB:  iny
        inx
        lda     ($08),y
        sta     $E00A,x
        .byte   $C0
L91B3:  brk
        bne     L91AB
L91B6:  inx
        lda     #$2F
        sta     $E00A,x
        ldy     #$00
        lda     (L0006),y
        beq     L91D1
        sta     L91CE
        iny
L91C6:  iny
        inx
        lda     (L0006),y
        sta     $E00A,x
        .byte   $C0
L91CE:  brk
        bne     L91C6
L91D1:  stx     $E00A
        rts

L91D5:  ldy     #$03
        lda     #$39
        ldx     #$D2
        jsr     L4003
        ldy     #$04
        lda     #$39
        ldx     #$D2
        jsr     L4003
        rts

L91E8:  jsr     L4015
        ldy     #$0C
        lda     #$00
        ldx     #$00
        jsr     L4018
        rts

L91F5:  lda     #$11
        sta     $08
        lda     #$92
        sta     $09
        lda     $DF20
        beq     L9210
        asl     a
        tax
        lda     $DFB3,x
        sta     $08
        lda     $DFB4,x
        sta     $09
        lda     #$00
L9210:  rts

        brk
        brk
L9213:  lda     $DF21
        bne     L9219
        rts

L9219:  ldx     $DF21
        stx     L0800
        dex
L9220:  lda     $DF22,x
        sta     $0801,x
        dex
        bpl     L9220
        jsr     L401E
        ldx     #$00
        stx     L924A
L9231:  ldx     L924A
        lda     $0801,x
        cmp     #$01
        beq     L923E
        jsr     L924B
L923E:  inc     L924A
        ldx     L924A
        cpx     L0800
        bne     L9231
        rts

L924A:  brk
L924B:  sta     L9254
        ldy     #$00
L9250:  lda     $E1A0,y
        .byte   $C9
L9254:  brk
        beq     L9260
        cpy     $BF31
        beq     L925F
        iny
        bne     L9250
L925F:  rts

L9260:  lda     $BF32,y
        sta     L92C7
        ldx     #$11
        lda     L92C7
        and     #$80
        beq     L9271
        ldx     #$21
L9271:  stx     L9284
        lda     L92C7
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     L9284
        sta     L9284
        .byte   $AD
L9284:  brk
        bbs3    $85,L928F
        lda     #$00
        sta     L0006
        ldy     #$07
        .byte   $B1
L928F:  asl     $D0
        cmp     $FBA0
        lda     (L0006),y
        and     #$7F
        bne     L925F
        ldy     #$FF
        lda     (L0006),y
        clc
        adc     #$03
        sta     L0006
        lda     L92C7
        pha
        rol     a
        pla
        php
        and     #$20
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        plp
        adc     #$01
        sta     L92C1
        jsr     L92BD
        tsb     $C0
        sta     ($60)
L92BD:  jmp     (L0006)

        .byte   $03
L92C1:  .byte   $00,$C5,$92,$04,$00,$00
L92C7:  .byte   $00,$00,$0A,$20,$02
L92CC:  .byte   $00
L92CD:  .byte   $00
L92CE:  .byte   $00
L92CF:  .byte   $00,$00
L92D1:  .byte   $00
L92D2:  .byte   $00
L92D3:  .byte   $00
L92D4:  .byte   $00,$00,$00
L92D7:  .byte   $00
L92D8:  .byte   $00,$00,$00,$00,$00,$03
L92DE:  .byte   $00,$00,$08,$0A,$00
L92E3:  .byte   $00
L92E4:  .byte   $00
L92E5:  .byte   $00
L92E6:  .byte   $00
L92E7:  lda     $DF21
        bne     L92ED
        rts

L92ED:  lda     #$00
        sta     L92E6
        jsr     L91D5
L92F5:  ldx     L92E6
        cpx     $DF21
        bne     L9300
        jmp     L9534

L9300:  lda     $DF20
        beq     L9331
        asl     a
        tax
        lda     $DFB3,x
        sta     $08
        lda     $DFB4,x
        sta     $09
        ldx     L92E6
        lda     $DF22,x
        jsr     L918E
        jsr     L91A0
        ldy     #$00
L931F:  lda     $E00A,y
        sta     $0220,y
        iny
        cpy     $0220
        bne     L931F
        dec     $0220
        jmp     L9356

L9331:  ldx     L92E6
        lda     $DF22,x
        cmp     #$01
        bne     L933E
        jmp     L952E

L933E:  jsr     L918E
        ldy     #$00
L9343:  lda     (L0006),y
        sta     $0220,y
        iny
        cpy     $0220
        bne     L9343
        dec     $0220
        lda     #$2F
        sta     $0221
L9356:  ldy     #$C4
        lda     #$C9
        ldx     #$92
        jsr     L4021
        beq     L9366
        jsr     LA49B
        beq     L9356
L9366:  lda     $DF20
        beq     L9387
        lda     #$80
        sta     L92E3
        lda     L92E6
        clc
        adc     #$01
        cmp     $DF21
        beq     L9381
        inc     L92E3
        inc     L92E3
L9381:  jsr     L953F
        jmp     L93DB

L9387:  lda     #$81
        sta     L92E3
        lda     L92E6
        clc
        adc     #$01
        cmp     $DF21
        beq     L939D
        inc     L92E3
        inc     L92E3
L939D:  jsr     L953F
        lda     #$00
        sta     L942E
        ldx     L92E6
        lda     $DF22,x
        ldy     #$0F
L93AD:  cmp     $E1A0,y
        beq     L93B8
        dey
        bpl     L93AD
        jmp     L93DB

L93B8:  lda     $BF32,y
        sta     L92DE
        ldy     #$80
        lda     #$DD
        ldx     #$92
        jsr     L4021
        bne     L93DB
        ldy     #$81
        lda     #$DD
        ldx     #$92
        jsr     L4021
        cmp     #$2B
        bne     L93DB
        lda     #$80
        sta     L942E
L93DB:  ldx     L92E6
        lda     $DF22,x
        jsr     L918E
        lda     #$01
        sta     L92E3
        lda     L0006
        sta     L92E4
        lda     $07
        sta     L92E5
        jsr     L953F
        lda     #$02
        sta     L92E3
        lda     $DF20
        bne     L9413
        bit     L942E
        bmi     L940C
        lda     #$00
        sta     L92E4
        beq     L9428
L940C:  lda     #$01
        sta     L92E4
        bne     L9428
L9413:  lda     L92CC
        and     #$C3
        cmp     #$C3
        beq     L9423
        lda     #$01
        sta     L92E4
        bne     L9428
L9423:  lda     #$00
        sta     L92E4
L9428:  jsr     L953F
        jmp     L942F

L942E:  brk
L942F:  lda     #$03
        sta     L92E3
        lda     #$00
        sta     $0220
        lda     $DF20
        bne     L9472
        lda     L92CE
        sec
        sbc     L92D1
        pha
        lda     L92CF
        sbc     L92D2
        tax
        pla
        jsr     L4006
        jsr     L9549
        ldx     #$00
L9456:  lda     $E6EB,x
        cmp     #$42
        beq     L9460
        inx
        bne     L9456
L9460:  stx     $0220
        lda     #$2F
        sta     $0220,x
        dex
L9469:  lda     $E6EB,x
        sta     $0220,x
        dex
        bne     L9469
L9472:  lda     $DF20
        bne     L9480
        lda     L92CE
        ldx     L92CF
        jmp     L9486

L9480:  lda     L92D1
        ldx     L92D2
L9486:  jsr     L4006
        jsr     L9549
        ldx     $0220
        ldy     #$00
L9491:  lda     $E6EC,y
        sta     $0221,x
        inx
        iny
        cpy     $E6EB
        bne     L9491
        tya
        clc
        adc     $0220
        sta     $0220
        ldx     $0220
L94A9:  lda     $0220,x
        sta     $DFC9,x
        dex
        bpl     L94A9
        lda     #$C9
        sta     L92E4
        lda     #$DF
        sta     L92E5
        jsr     L953F
        lda     #$04
        sta     L92E3
        lda     L92D7
        sta     $EC5A
        lda     L92D8
        sta     $EC5B
        jsr     L4009
        lda     #$EB
        sta     L92E4
        lda     #$E6
        sta     L92E5
        jsr     L953F
        lda     #$05
        sta     L92E3
        lda     L92D3
        sta     $EC5A
        lda     L92D4
        sta     $EC5B
        jsr     L4009
        lda     #$EB
        sta     L92E4
        lda     #$E6
        sta     L92E5
        jsr     L953F
        lda     #$06
        sta     L92E3
        lda     $DF20
        bne     L9519
        ldx     L953A
L950E:  lda     L953A,x
        sta     $DFC5,x
        dex
        bpl     L950E
        bmi     L951F
L9519:  lda     L92CD
        jsr     L402D
L951F:  lda     #$C5
        sta     L92E4
        lda     #$DF
        sta     L92E5
        jsr     L953F
        bne     L9534
L952E:  inc     L92E6
        jmp     L92F5

L9534:  lda     #$00
        sta     $DFC9
        rts

L953A:  PASCAL_STRING " VOL"
L953F:  ldy     #$06
        lda     #$E3
        ldx     #$92
        jsr     LA500
        rts

L9549:  ldx     #$00
L954B:  lda     $E6EC,x
        cmp     #$20
        bne     L9555
        inx
        bne     L954B
L9555:  ldy     #$00
        dex
L9558:  lda     $E6EC,x
        sta     $E6EC,y
        iny
        inx
        cpx     $E6EB
        bne     L9558
        sty     $E6EB
        rts

        .byte   $02
        jsr     RAMRDOFF
        .byte   $1F
L956E:  brk
        brk
L9570:  .byte   $1F
L9571:  lda     #$00
        sta     L9706
L9576:  lda     L9706
        cmp     $DF21
        bne     L9581
        lda     #$00
        rts

L9581:  ldx     L9706
        lda     $DF22,x
        cmp     #$01
        bne     L9591
        inc     L9706
        jmp     L9576

L9591:  lda     $DF20
        beq     L95C2
        asl     a
        tax
        lda     $DFB3,x
        sta     $08
        lda     $DFB4,x
        sta     $09
        ldx     L9706
        lda     $DF22,x
        jsr     L918E
        jsr     L91A0
        ldy     #$00
L95B0:  lda     $E00A,y
        sta     $0220,y
        iny
        cpy     $0220
        bne     L95B0
        dec     $0220
        jmp     L95E0

L95C2:  ldx     L9706
        lda     $DF22,x
        jsr     L918E
        ldy     #$00
L95CD:  lda     (L0006),y
        sta     $0220,y
        iny
        cpy     $0220
        bne     L95CD
        dec     $0220
        lda     #$2F
        sta     $0221
L95E0:  ldx     L9706
        lda     $DF22,x
        jsr     L918E
        ldy     #$00
        lda     (L0006),y
        tay
L95EE:  lda     (L0006),y
        sta     $1F12,y
        dey
        bpl     L95EE
        ldy     #$00
        lda     (L0006),y
        tay
        dey
        sec
        sbc     #$02
        sta     $1F00
L9602:  lda     (L0006),y
        sta     $1EFF,y
        dey
        cpy     #$01
        bne     L9602
        lda     #$00
        jsr     L96F8
L9611:  lda     #$80
        jsr     L96F8
        beq     L962F
L9618:  ldx     L9706
        lda     $DF22,x
        jsr     L918E
        ldy     $1F12
L9624:  lda     $1F12,y
        sta     (L0006),y
        dey
        bpl     L9624
        lda     #$FF
        rts

L962F:  sty     $08
        sty     L9707
        stx     $09
        stx     L9708
        lda     $DF20
        beq     L964D
        asl     a
        tax
        lda     $DFB3,x
        sta     L0006
        lda     $DFB4,x
        sta     $07
        jmp     L9655

L964D:  lda     #$05
        sta     L0006
        lda     #$97
        sta     $07
L9655:  ldy     #$00
        lda     (L0006),y
        tay
L965A:  lda     (L0006),y
        sta     $1FC0,y
        dey
        bpl     L965A
        inc     $1FC0
        ldx     $1FC0
        lda     #$2F
        sta     $1FC0,x
        ldy     #$00
        lda     ($08),y
        sta     L9709
L9674:  inx
        iny
        lda     ($08),y
        sta     $1FC0,x
        cpy     L9709
        bne     L9674
        stx     $1FC0
        ldy     #$C2
        lda     #$69
        ldx     #$95
        jsr     L4021
        beq     L969E
        jsr     L4030
        bne     L9696
        jmp     L9611

L9696:  lda     #$40
        jsr     L96F8
        jmp     L9618

L969E:  lda     #$40
        jsr     L96F8
        ldx     L9706
        lda     $DF22,x
        sta     $E22B
        ldy     #$0E
        lda     #$2B
        ldx     #$E2
        jsr     L4018
        lda     L9707
        sta     $08
        lda     L9708
        sta     $09
        ldx     L9706
        lda     $DF22,x
        jsr     L918E
        ldy     #$00
        lda     ($08),y
        clc
        adc     #$02
        sta     (L0006),y
        lda     ($08),y
        tay
        inc     L0006
        bne     L96DA
        inc     $07
L96DA:  lda     ($08),y
        sta     (L0006),y
        dey
        bne     L96DA
        dec     L0006
        lda     L0006
        cmp     #$FF
        bne     L96EB
        dec     $07
L96EB:  lda     (L0006),y
        tay
        lda     #$20
        sta     (L0006),y
        inc     L9706
        jmp     L9576

L96F8:  sta     L956E
        ldy     #$09
        lda     #$6E
        ldx     #$95
        jsr     LA500
        rts

        .byte   $00
L9706:  .byte   $00
L9707:  .byte   $00
L9708:  .byte   $00
L9709:  .byte   $00,$03,$20,$02,$00,$08
L970F:  .byte   $00,$04
L9711:  .byte   $00,$18,$97,$04,$00,$00,$00,$00
        .byte   $00,$00,$00,$01
L971D:  .byte   $00,$04
L971F:  .byte   $00,$AD,$97,$27,$00,$00,$00,$04
L9727:  .byte   $00,$2E,$97,$05,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $01
L9738:  .byte   $00,$01
L973A:  .byte   $00,$01,$20,$02,$03,$20,$02,$00
        .byte   $0D
L9743:  .byte   $00,$03,$C0,$1F,$00,$11
L9749:  .byte   $00,$04
L974B:  .byte   $00,$00,$15
L974E:  .byte   $C0
L974F:  .byte   $0A
L9750:  .byte   $00
L9751:  .byte   $00,$04
L9753:  .byte   $00,$00,$15
L9756:  .byte   $C0
L9757:  .byte   $0A,$00,$00
L975A:  .byte   $07,$C0,$1F,$C3,$00,$00,$00,$00
        .byte   $00,$00,$00,$00
L9766:  .byte   $07,$C0,$1F
L9769:  .byte   $00,$00,$00,$00
L976D:  .byte   $00,$00,$00,$00,$00,$00,$00
L9774:  .byte   $0A,$20,$02
L9777:  .byte   $00
L9778:  .byte   $00,$00,$00
L977B:  .byte   $00
L977C:  .byte   $00
L977D:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00
L9787:  .byte   $0A,$C0,$1F
L978A:  .byte   $00,$00
L978C:  .byte   $00
L978D:  .byte   $00,$00
L978F:  .byte   $00
L9790:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$02
L979B:  .byte   $00,$00,$00,$00,$02
L97A0:  .byte   $00
L97A1:  .byte   $00
L97A2:  .byte   $00
L97A3:  .byte   $00,$02
L97A5:  .byte   $00
L97A6:  .byte   $00
L97A7:  .byte   $00
L97A8:  .byte   $00,$02,$00,$00,$08
L97AD:  .byte   $00
L97AE:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00
L97BD:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L97DD:  .byte   $36,$9B
L97DF:  .byte   $33,$9B
L97E1:  .byte   $E3,$97
L97E3:  .byte   $60
L97E4:  .byte   $00
L97E5:  ldx     $E10C
        lda     $E061
        sta     $E062,x
        inx
        stx     $E10C
        rts

L97F3:  ldx     $E10C
        dex
        lda     $E062,x
        sta     $E061
        stx     $E10C
        rts

L9801:  lda     #$00
        sta     $E05F
        sta     $E10D
L9809:  ldy     #$C8
        lda     #$0A
        ldx     #$97
        jsr     L4021
        beq     L981E
        ldx     #$80
        jsr     L4033
        beq     L9809
        jmp     LA39F

L981E:  lda     L970F
        sta     $E060
        sta     L9711
L9827:  ldy     #$CA
        lda     #$10
        ldx     #$97
        jsr     L4021
        beq     L983C
        ldx     #$80
        jsr     L4033
        beq     L9827
        jmp     LA39F

L983C:  jmp     L985B

L983F:  lda     $E060
        sta     L971D
L9845:  ldy     #$CC
        lda     #$1C
        ldx     #$97
        jsr     L4021
        beq     L985A
        ldx     #$80
        jsr     L4033
        beq     L9845
        jmp     LA39F

L985A:  rts

L985B:  inc     $E05F
        lda     $E060
        sta     L971F
L9864:  ldy     #$CA
        lda     #$1E
        ldx     #$97
        jsr     L4021
        beq     L987D
        cmp     #$4C
        beq     L989F
        ldx     #$80
        jsr     L4033
        beq     L9864
        jmp     LA39F

L987D:  inc     $E10D
        lda     $E10D
        cmp     $E05E
        bcc     L989C
        lda     #$00
        sta     $E10D
        lda     $E060
        sta     L9727
        ldy     #$CA
        lda     #$26
        ldx     #$97
        jsr     L4021
L989C:  lda     #$00
        rts

L989F:  lda     #$FF
        rts

L98A2:  lda     $E05F
        sta     $E061
        jsr     L983F
        jsr     L97E5
        jsr     LA2FD
        jmp     L9801

L98B4:  jsr     L983F
        jsr     L992A
        jsr     LA322
        jsr     L97F3
        jsr     L9801
        jsr     L98C9
        jmp     L9927

L98C9:  lda     $E05F
        cmp     $E061
        beq     L98D7
        jsr     L985B
        jmp     L98C9

L98D7:  rts

L98D8:  lda     #$00
        sta     $E05D
        jsr     L9801
L98E0:  jsr     L985B
        bne     L9912
        lda     L97AD
        beq     L98E0
        lda     L97AD
        sta     L992D
        and     #$0F
        sta     L97AD
        lda     #$00
        sta     L9923
        jsr     L9924
        lda     L9923
        bne     L98E0
        lda     L97BD
        cmp     #$0F
        bne     L98E0
        jsr     L98A2
        inc     $E05D
        jmp     L98E0

L9912:  lda     $E05D
        beq     L9920
        jsr     L98B4
        dec     $E05D
        jmp     L98E0

L9920:  jmp     L983F

L9923:  brk
L9924:  jmp     (L97DD)

L9927:  jmp     (L97DF)

L992A:  jmp     (L97E1)

L992D:  .byte   $00,$00,$00,$00
L9931:  .byte   $36,$9B,$33,$9B,$E3,$97
L9937:  .byte   $00
L9938:  .byte   $00
L9939:  .byte   $00
        jsr     RAMRDOFF
        .byte   $1F
L993E:  lda     #$00
        sta     L9937
        lda     #$5A
        sta     L917D
        lda     #$99
        sta     L917E
        lda     #$7C
        sta     L9180
        lda     #$99
        sta     L9181
        jmp     L9BBF

        sta     L9938
        stx     L9939
        lda     #$01
        sta     L9937
        jmp     L9BBF

L9968:  ldy     #$05
L996A:  lda     L9931,y
        sta     L97DD,y
        dey
        bpl     L996A
        lda     #$00
        sta     LA425
        sta     L918D
        rts

        lda     #$05
        sta     L9937
        jmp     L9BBF

L9984:  lda     #$00
        sta     L9937
        lda     #$A7
        sta     L917D
        lda     #$99
        sta     L917E
        lda     #$DC
        sta     L9180
        lda     #$99
        sta     L9181
        ldy     #$0A
        lda     #$37
        ldx     #$99
        jsr     LA500
        rts

        sta     L9938
        stx     L9939
        lda     #$01
        sta     L9937
        ldy     #$0A
        lda     #$37
        ldx     #$99
        jsr     LA500
        rts

L99BC:  lda     #$80
        sta     L918D
        ldy     #$05
L99C3:  lda     L9931,y
        sta     L97DD,y
        dey
        bpl     L99C3
        lda     #$00
        sta     LA425
        lda     #$EB
        sta     L9186
        lda     #$99
        sta     L9187
        rts

        lda     #$03
        sta     L9937
        ldy     #$0A
        lda     #$37
        ldx     #$99
        jsr     LA500
        rts

        lda     #$04
        sta     L9937
        ldy     #$0A
        lda     #$37
        ldx     #$99
        jsr     LA500
        cmp     #$02
        bne     L99FE
        rts

L99FE:  jmp     LA39F

L9A01:  lda     #$80
        sta     $E05B
        lda     #$00
        sta     $E05C
        beq     L9A0F
L9A0D:  lda     #$FF
L9A0F:  sta     L9B31
        lda     #$02
        sta     L9937
        jsr     LA379
        bit     L9189
        bvc     L9A22
        jsr     L9BC9
L9A22:  bit     $E05B
        bpl     L9A70
        bvs     L9A50
        lda     L9B31
        bne     L9A36
        lda     $DF20
        bne     L9A36
        jmp     L9B28

L9A36:  ldx     $1FC0
        ldy     L9B32
        dey
L9A3D:  iny
        inx
        lda     $0220,y
        sta     $1FC0,x
        cpy     $0220
        bne     L9A3D
        stx     $1FC0
        jmp     L9A70

L9A50:  ldx     $1FC0
        lda     #$2F
        sta     $1FC1,x
        inc     $1FC0
        ldy     #$00
        ldx     $1FC0
L9A60:  iny
        inx
        lda     $E04B,y
        sta     $1FC0,x
        cpy     $E04B
        bne     L9A60
        stx     $1FC0
L9A70:  ldy     #$C4
        lda     #$74
        ldx     #$97
        jsr     L4021
        beq     L9A81
        jsr     LA49B
        jmp     L9A70

L9A81:  lda     L977B
        cmp     #$0F
        beq     L9A90
        cmp     #$0D
        beq     L9A90
        lda     #$00
        beq     L9A95
L9A90:  jsr     LA2F1
        lda     #$FF
L9A95:  sta     L9B30
        jsr     LA40A
        lda     LA2EE
        bne     L9AA8
        lda     LA2ED
        bne     L9AA8
        jmp     LA39F

L9AA8:  ldy     #$07
L9AAA:  lda     L9774,y
        sta     L9766,y
        dey
        cpy     #$02
        bne     L9AAA
        lda     #$C3
        sta     L9769
        lda     $E05B
        beq     L9B23
        jsr     L9C01
        bcs     L9B2C
        ldy     #$11
        ldx     #$0B
L9AC8:  lda     L9774,y
        sta     L9766,x
        dex
        dey
        cpy     #$0D
        bne     L9AC8
        lda     L976D
        cmp     #$0F
        bne     L9AE0
        lda     #$0D
        sta     L976D
L9AE0:  ldy     #$C0
        lda     #$66
        ldx     #$97
        jsr     L4021
        beq     L9B23
        cmp     #$47
        bne     L9B1D
        bit     L918D
        bmi     L9B14
        lda     #$03
        sta     L9937
        jsr     L9BBF
        pha
        lda     #$02
        sta     L9937
        pla
        cmp     #$02
        beq     L9B14
        cmp     #$03
        beq     L9B2C
        cmp     #$04
        bne     L9B1A
        lda     #$80
        sta     L918D
L9B14:  jsr     LA426
        jmp     L9B23

L9B1A:  jmp     LA39F

L9B1D:  jsr     LA49B
        jmp     L9AE0

L9B23:  lda     L9B30
        beq     L9B2D
L9B28:  jmp     L98D8

        brk
L9B2C:  rts

L9B2D:  jmp     L9CDA

L9B30:  brk
L9B31:  brk
L9B32:  brk
        jmp     LA360

        jsr     LA3D1
        beq     L9B3E
        jmp     LA39F

L9B3E:  lda     L97BD
        cmp     #$0F
        bne     L9B88
        jsr     LA2FD
L9B48:  ldy     #$C4
        lda     #$74
        ldx     #$97
        jsr     L4021
        beq     L9B59
        jsr     LA49B
        jmp     L9B48

L9B59:  jsr     LA33B
        jsr     LA40A
        jsr     LA2F1
        lda     LA2EE
        bne     L9B6F
        lda     LA2ED
        bne     L9B6F
        jmp     LA39F

L9B6F:  jsr     L9E19
        bcs     L9B7A
        jsr     LA322
        jmp     L9BBE

L9B7A:  jsr     LA360
        jsr     LA322
        lda     #$FF
        sta     L9923
        jmp     L9BBE

L9B88:  jsr     LA33B
        jsr     LA2FD
        jsr     LA40A
L9B91:  ldy     #$C4
        lda     #$74
        ldx     #$97
        jsr     L4021
        beq     L9BA2
        jsr     LA49B
        jmp     L9B91

L9BA2:  jsr     L9C01
        bcc     L9BAA
        jmp     LA39F

L9BAA:  jsr     LA322
        jsr     L9E19
        bcs     L9BBB
        jsr     LA2FD
        jsr     L9CDA
        jsr     LA322
L9BBB:  jsr     LA360
L9BBE:  rts

L9BBF:  ldy     #$01
        lda     #$37
        ldx     #$99
        jsr     LA500
        rts

L9BC9:  ldy     #$C4
        lda     #$87
        ldx     #$97
        jsr     L4021
        beq     L9BDA
        jsr     LA497
        jmp     L9BC9

L9BDA:  lda     L978C
        sec
        sbc     L978F
        sta     L9BFF
        lda     L978D
        sbc     L9790
        sta     L9C00
        lda     L9BFF
        cmp     LA2EF
        lda     L9C00
        sbc     LA2F0
        bcs     L9BFE
        jmp     L9185

L9BFE:  rts

L9BFF:  brk
L9C00:  brk
L9C01:  jsr     L9C1A
        bcc     L9C19
        lda     #$04
        sta     L9937
        jsr     L9BBF
        beq     L9C13
        jmp     LA39F

L9C13:  lda     #$03
        sta     L9937
        sec
L9C19:  rts

L9C1A:  ldy     #$C4
        lda     #$74
        ldx     #$97
        jsr     L4021
        beq     L9C2B
        jsr     LA49B
        jmp     L9C1A

L9C2B:  lda     #$00
        sta     L9CD8
        sta     L9CD9
L9C33:  ldy     #$C4
        lda     #$87
        ldx     #$97
        jsr     L4021
        beq     L9C48
        cmp     #$46
        beq     L9C54
        jsr     LA497
        jmp     L9C33

L9C48:  lda     L978F
        sta     L9CD8
        lda     L9790
        sta     L9CD9
L9C54:  lda     $1FC0
        sta     L9CD6
        ldy     #$01
L9C5C:  iny
        cpy     $1FC0
        bcs     L9CCC
        lda     $1FC0,y
        cmp     #$2F
        bne     L9C5C
        tya
        sta     $1FC0
        sta     L9CD7
L9C70:  ldy     #$C4
        lda     #$87
        ldx     #$97
        jsr     L4021
        beq     L9C95
        pha
        lda     L9CD6
        sta     $1FC0
        pla
        jsr     LA497
        jmp     L9C70

        lda     L9CD7
        sta     $1FC0
        jmp     L9C70

        jmp     LA39F

L9C95:  lda     L978C
        sec
        sbc     L978F
        sta     L9CD4
        lda     L978D
        sbc     L9790
        sta     L9CD5
        lda     L9CD4
        clc
        adc     L9CD8
        sta     L9CD4
        lda     L9CD5
        adc     L9CD9
        sta     L9CD5
        lda     L9CD4
        cmp     L977C
        lda     L9CD5
        sbc     L977D
        bcs     L9CCC
        sec
        bcs     L9CCD
L9CCC:  clc
L9CCD:  lda     L9CD6
        sta     $1FC0
        rts

L9CD4:  brk
L9CD5:  brk
L9CD6:  brk
L9CD7:  brk
L9CD8:  brk
L9CD9:  brk
L9CDA:  jsr     LA2F1
        lda     #$00
        sta     L9E17
        sta     L9E18
        sta     L97A1
        sta     L97A2
        sta     L97A3
        sta     L97A6
        sta     L97A7
        sta     L97A8
        jsr     L9D62
        jsr     L9D74
        jsr     L9D81
        beq     L9D09
        lda     #$FF
        sta     L9E17
        bne     L9D0C
L9D09:  jsr     L9D9C
L9D0C:  jsr     L9DA9
        bit     L9E17
        bpl     L9D28
        jsr     L9E0D
L9D17:  jsr     L9D81
        bne     L9D17
        jsr     L9D9C
        ldy     #$CE
        lda     #$A4
        ldx     #$97
        jsr     L4021
L9D28:  bit     L9E18
        bmi     L9D51
        jsr     L9DE8
        bit     L9E17
        bpl     L9D0C
        jsr     L9E03
        jsr     L9D62
        jsr     L9D74
        ldy     #$CE
        lda     #$9F
        ldx     #$97
        jsr     L4021
        beq     L9D0C
        lda     #$FF
        sta     L9E18
        jmp     L9D0C

L9D51:  jsr     L9E03
        bit     L9E17
        bmi     L9D5C
        jsr     L9E0D
L9D5C:  jsr     LA46D
        jmp     LA479

L9D62:  ldy     #$C8
        lda     #$3E
        ldx     #$97
        jsr     L4021
        beq     L9D73
        jsr     LA49B
        jmp     L9D62

L9D73:  rts

L9D74:  lda     L9743
        sta     L974B
        sta     L9738
        sta     L97A0
        rts

L9D81:  ldy     #$C8
        lda     #$44
        ldx     #$97
        jsr     L4021
        beq     L9D9B
        cmp     #$45
        beq     L9D96
        jsr     LA497
        jmp     L9D81

L9D96:  jsr     LA497
        lda     #$45
L9D9B:  rts

L9D9C:  lda     L9749
        sta     L9753
        sta     L973A
        sta     L97A5
        rts

L9DA9:  lda     #$C0
        sta     L974E
        lda     #$0A
        sta     L974F
L9DB3:  ldy     #$CA
        lda     #$4A
        ldx     #$97
        jsr     L4021
        beq     L9DC8
        cmp     #$4C
        beq     L9DD9
        jsr     LA49B
        jmp     L9DB3

L9DC8:  lda     L9750
        sta     L9756
        lda     L9751
        sta     L9757
        ora     L9750
        bne     L9DDE
L9DD9:  lda     #$FF
        sta     L9E18
L9DDE:  ldy     #$CF
        lda     #$9F
        ldx     #$97
        jsr     L4021
        rts

L9DE8:  ldy     #$CB
        lda     #$52
        ldx     #$97
        jsr     L4021
        beq     L9DF9
        jsr     LA497
        jmp     L9DE8

L9DF9:  ldy     #$CF
        lda     #$A4
        ldx     #$97
        jsr     L4021
        rts

L9E03:  ldy     #$CC
        lda     #$39
        ldx     #$97
        jsr     L4021
        rts

L9E0D:  ldy     #$CC
        lda     #$37
        ldx     #$97
        jsr     L4021
        rts

L9E17:  brk
L9E18:  brk
L9E19:  ldx     #$07
L9E1B:  lda     L9774,x
        sta     L975A,x
        dex
        cpx     #$03
        bne     L9E1B
L9E26:  ldy     #$C0
        lda     #$5A
        ldx     #$97
        jsr     L4021
        beq     L9E6F
        cmp     #$47
        bne     L9E69
        bit     L918D
        bmi     L9E60
        lda     #$03
        sta     L9937
        ldy     #$01
        lda     #$37
        ldx     #$99
        jsr     LA500
        pha
        lda     #$02
        sta     L9937
        pla
        cmp     #$02
        beq     L9E60
        cmp     #$03
        beq     L9E71
        cmp     #$04
        bne     L9E66
        lda     #$80
        sta     L918D
L9E60:  jsr     LA426
        jmp     L9E6F

L9E66:  jmp     LA39F

L9E69:  jsr     LA497
        jmp     L9E26

L9E6F:  clc
        rts

L9E71:  sec
        rts

L9E73:  sty     $9F,x
        .byte   $E3
        smb1    $2E
        .byte   $A0
L9E79:  brk
L9E7A:  brk
L9E7B:  brk
        .byte   $20
        .byte   $02
L9E7E:  sta     L9E79
        lda     #$B1
        sta     L9183
        lda     #$9E
        sta     L9184
        lda     #$A3
        sta     L917D
        lda     #$9E
        sta     L917E
        jsr     LA044
        lda     #$D3
        sta     L9180
        lda     #$9E
        sta     L9181
        rts

        sta     L9E7A
        stx     L9E7B
        lda     #$01
        sta     L9E79
        jmp     LA044

        lda     #$02
        sta     L9E79
        jsr     LA044
        beq     L9EBE
        jmp     LA39F

L9EBE:  rts

L9EBF:  ldy     #$05
L9EC1:  lda     L9E73,y
        sta     L97DD,y
        dey
        bpl     L9EC1
        lda     #$00
        sta     LA425
        sta     L918D
        rts

        lda     #$05
        sta     L9E79
        jmp     LA044

L9EDB:  lda     #$03
        sta     L9E79
        jsr     LA379
L9EE3:  ldy     #$C4
        lda     #$74
        ldx     #$97
        jsr     L4021
        beq     L9EF4
        jsr     LA49B
        jmp     L9EE3

L9EF4:  lda     L977B
        sta     L9F1D
        cmp     #$0D
        beq     L9F02
        lda     #$00
        beq     L9F04
L9F02:  lda     #$FF
L9F04:  sta     L9F1C
        beq     L9F1E
        jsr     L98D8
        lda     L9F1D
        cmp     #$0D
        bne     L9F18
        lda     #$FF
        sta     L9F1D
L9F18:  jmp     L9F1E

        rts

L9F1C:  brk
L9F1D:  brk
L9F1E:  bit     $E05C
        bmi     L9F26
        jsr     LA3EF
L9F26:  jsr     LA2F1
L9F29:  ldy     #$C1
        lda     #$3B
        ldx     #$97
        jsr     L4021
        beq     L9F8D
        cmp     #$4E
        bne     L9F8E
        bit     L918D
        bmi     L9F62
        lda     #$04
        sta     L9E79
        jsr     LA044
        pha
        lda     #$03
        sta     L9E79
        pla
        cmp     #$03
        beq     L9F8D
        cmp     #$02
        beq     L9F62
        cmp     #$04
        bne     L9F5F
        lda     #$80
        sta     L918D
        bne     L9F62
L9F5F:  jmp     LA39F

L9F62:  ldy     #$C4
        lda     #$74
        ldx     #$97
        jsr     L4021
        lda     L9777
        and     #$80
        bne     L9F8D
        lda     #$C3
        sta     L9777
        lda     #$07
        sta     L9774
        ldy     #$C3
        lda     #$74
        ldx     #$97
        jsr     L4021
        lda     #$0A
        sta     L9774
        jmp     L9F29

L9F8D:  rts

L9F8E:  jsr     LA49B
        jmp     L9F29

        jsr     LA3D1
        beq     L9F9C
        jmp     LA39F

L9F9C:  jsr     LA2FD
        bit     $E05C
        bmi     L9FA7
        jsr     LA3EF
L9FA7:  jsr     LA2F1
L9FAA:  ldy     #$C4
        lda     #$74
        ldx     #$97
        jsr     L4021
        beq     L9FBB
        jsr     LA49B
        jmp     L9FAA

L9FBB:  lda     L977B
        cmp     #$0D
        beq     LA022
L9FC2:  ldy     #$C1
        lda     #$3B
        ldx     #$97
        jsr     L4021
        beq     LA022
        cmp     #$4E
        bne     LA01C
        bit     L918D
        bmi     LA001
        lda     #$04
        sta     L9E79
        ldy     #$02
        lda     #$79
        ldx     #$9E
        jsr     LA500
        pha
        lda     #$03
        sta     L9E79
        pla
        cmp     #$03
        beq     LA022
        cmp     #$02
L9FF1:  beq     LA001
        cmp     #$04
        bne     L9FFE
        lda     #$80
        sta     L918D
        bne     LA001
L9FFE:  jmp     LA39F

LA001:  lda     #$C3
        sta     L9777
        lda     #$07
        sta     L9774
        ldy     #$C3
        lda     #$74
        ldx     #$97
        jsr     L4021
        lda     #$0A
        sta     L9774
        jmp     L9FC2

LA01C:  jsr     LA49B
        jmp     L9FC2

LA022:  jmp     LA322

        jsr     LA322
        lda     #$FF
        sta     L9923
        rts

LA02E:  ldy     #$C1
        lda     #$3B
        ldx     #$97
        jsr     L4021
        beq     LA043
        cmp     #$4E
        beq     LA043
        jsr     LA49B
        jmp     LA02E

LA043:  rts

LA044:  ldy     #$02
        lda     #$79
        ldx     #$9E
        jsr     LA500
        rts

LA04E:  bvs     L9FF1
        .byte   $E3
        smb1    $E3
        .byte   $97
LA054:  brk
LA055:  brk
LA056:  brk
        .byte   $20
        .byte   $02
LA059:  lda     #$00
        sta     LA054
        bit     L918B
        bpl     LA085
        lda     #$D1
        sta     L9183
        lda     #$A0
        sta     L9184
        lda     #$B5
        sta     L917D
        lda     #$A0
        sta     L917E
        jsr     LA10A
        lda     #$F8
        sta     L9180
        lda     #$A0
        sta     L9181
        rts

LA085:  lda     #$C3
        sta     L9183
        lda     #$A0
        sta     L9184
        lda     #$A7
        sta     L917D
        lda     #$A0
        sta     L917E
        jsr     LA100
        lda     #$F0
        sta     L9180
        lda     #$A0
        sta     L9181
        rts

        sta     LA055
        stx     LA056
        lda     #$01
        sta     LA054
        jmp     LA100

        sta     LA055
        stx     LA056
        lda     #$01
        sta     LA054
        jmp     LA10A

        lda     #$02
        sta     LA054
        jsr     LA100
        beq     LA0D0
        jmp     LA39F

LA0D0:  rts

        lda     #$02
        sta     LA054
        jsr     LA10A
        beq     LA0DE
        jmp     LA39F

LA0DE:  rts

LA0DF:  lda     #$00
        sta     LA425
        ldy     #$05
LA0E6:  lda     LA04E,y
        sta     L97DD,y
        dey
        bpl     LA0E6
        rts

        lda     #$04
        sta     LA054
        jmp     LA100

        lda     #$04
        sta     LA054
        jmp     LA10A

LA100:  ldy     #$07
        lda     #$54
        ldx     #$A0
        jsr     LA500
        rts

LA10A:  ldy     #$08
        lda     #$54
        ldx     #$A0
        jsr     LA500
        rts

LA114:  lda     #$03
        sta     LA054
        jsr     LA379
        ldx     $1FC0
        ldy     L9B32
        dey
LA123:  iny
        inx
        lda     $0220,y
        sta     $1FC0,x
        cpy     $0220
        bne     LA123
        stx     $1FC0
LA133:  ldy     #$C4
        lda     #$74
        ldx     #$97
        jsr     L4021
        beq     LA144
        jsr     LA49B
        jmp     LA133

LA144:  lda     L977B
        sta     LA169
        cmp     #$0F
        beq     LA156
        cmp     #$0D
        beq     LA156
        lda     #$00
        beq     LA158
LA156:  lda     #$FF
LA158:  sta     LA168
        beq     LA16A
        jsr     L98D8
        lda     LA169
        cmp     #$0F
        bne     LA16A
        rts

LA168:  brk
LA169:  brk
LA16A:  jsr     LA173
        jmp     LA2FD

        jsr     LA2FD
LA173:  jsr     LA1C3
        jsr     LA2F1
LA179:  ldy     #$C4
        lda     #$74
        ldx     #$97
        jsr     L4021
        beq     LA18A
        jsr     LA49B
        jmp     LA179

LA18A:  lda     L977B
        cmp     #$0F
        beq     LA1C0
        cmp     #$0D
        beq     LA1C0
        bit     L918B
        bpl     LA19E
        lda     #$C3
        bne     LA1A0
LA19E:  lda     #$21
LA1A0:  sta     L9777
LA1A3:  lda     #$07
        sta     L9774
        ldy     #$C3
        lda     #$74
        ldx     #$97
        jsr     L4021
        pha
        lda     #$0A
        sta     L9774
        pla
        beq     LA1C0
        jsr     LA49B
        jmp     LA1A3

LA1C0:  jmp     LA322

LA1C3:  lda     LA2ED
        sec
        sbc     #$01
        sta     LA055
        lda     LA2EE
        sbc     #$00
        sta     LA056
        bit     L918B
        bpl     LA1DC
        jmp     LA10A

LA1DC:  jmp     LA100

LA1DF:  brk
        sbc     $EFA2
        .byte   $A2
LA1E4:  lda     #$00
        sta     LA1DF
        lda     #$20
        sta     L9183
        lda     #$A2
        sta     L9184
        lda     #$11
        sta     L917D
        lda     #$A2
        sta     L917E
        ldy     #$0B
        lda     #$DF
        ldx     #$A1
        jsr     LA500
        lda     #$33
        sta     L9180
        lda     #$A2
        sta     L9181
        rts

        lda     #$01
        sta     LA1DF
        ldy     #$0B
        lda     #$DF
        ldx     #$A1
        jsr     LA500
LA21F:  rts

        lda     #$02
        sta     LA1DF
        ldy     #$0B
        lda     #$DF
        ldx     #$A1
        jsr     LA500
        beq     LA21F
        jmp     LA39F

        lda     #$03
        sta     LA1DF
        ldy     #$0B
        lda     #$DF
        ldx     #$A1
        jsr     LA500
LA241:  rts

LA242:  ldx     $E3A2
        smb1    $E3
        .byte   $97
LA248:  lda     #$00
        sta     LA425
        ldy     #$05
LA24F:  lda     LA242,y
        sta     L97DD,y
        dey
        bpl     LA24F
        lda     #$00
        sta     LA2ED
        sta     LA2EE
        sta     LA2EF
        sta     LA2F0
        ldy     #$17
        lda     #$00
LA26A:  sta     $BF58,y
        dey
        bpl     LA26A
        rts

LA271:  jsr     LA379
LA274:  ldy     #$C4
        lda     #$74
        ldx     #$97
        jsr     L4021
        beq     LA285
        jsr     LA49B
        jmp     LA274

LA285:  lda     L977B
        sta     LA2AA
        cmp     #$0F
        beq     LA297
        cmp     #$0D
        beq     LA297
        lda     #$00
        beq     LA299
LA297:  lda     #$FF
LA299:  sta     LA2A9
        beq     LA2AB
        jsr     L98D8
        lda     LA2AA
        cmp     #$0F
        bne     LA2AB
        rts

LA2A9:  brk
LA2AA:  brk
LA2AB:  jmp     LA2AE

LA2AE:  bit     L9189
        bvc     LA2D4
        jsr     LA2FD
        ldy     #$C4
        lda     #$74
        ldx     #$97
        jsr     L4021
        bne     LA2D4
        lda     LA2EF
        clc
        adc     L977C
        sta     LA2EF
        lda     LA2F0
        adc     L977D
        sta     LA2F0
LA2D4:  inc     LA2ED
        bne     LA2DC
        inc     LA2EE
LA2DC:  bit     L9189
        bvc     LA2E4
        jsr     LA322
LA2E4:  lda     LA2ED
        ldx     LA2EE
        jmp     L917C

LA2ED:  brk
LA2EE:  brk
LA2EF:  brk
LA2F0:  brk
LA2F1:  lda     LA2ED
        bne     LA2F9
        dec     LA2EE
LA2F9:  dec     LA2ED
        rts

LA2FD:  lda     L97AD
        bne     LA303
        rts

LA303:  ldx     #$00
        ldy     $0220
        lda     #$2F
        sta     $0221,y
        iny
LA30E:  cpx     L97AD
        bcs     LA31E
        lda     L97AE,x
        sta     $0221,y
        inx
        iny
        jmp     LA30E

LA31E:  sty     $0220
        rts

LA322:  ldx     $0220
        bne     LA328
        rts

LA328:  lda     $0220,x
        cmp     #$2F
        beq     LA336
        dex
        bne     LA328
        stx     $0220
        rts

LA336:  dex
        stx     $0220
        rts

LA33B:  lda     L97AD
        bne     LA341
        rts

LA341:  ldx     #$00
        ldy     $1FC0
        lda     #$2F
        sta     $1FC1,y
        iny
LA34C:  cpx     L97AD
        bcs     LA35C
        lda     L97AE,x
        sta     $1FC1,y
        inx
        iny
        jmp     LA34C

LA35C:  sty     $1FC0
        rts

LA360:  ldx     $1FC0
        bne     LA366
        rts

LA366:  lda     $1FC0,x
        cmp     #$2F
        beq     LA374
        dex
        bne     LA366
        stx     $1FC0
        rts

LA374:  dex
        stx     $1FC0
        rts

LA379:  ldy     #$00
        sty     L9B32
        dey
LA37F:  iny
        lda     $E00A,y
        cmp     #$2F
        bne     LA38A
        sty     L9B32
LA38A:  sta     $0220,y
        cpy     $E00A
        bne     LA37F
        ldy     $DFC9
LA395:  lda     $DFC9,y
        sta     $1FC0,y
        dey
        bpl     LA395
        rts

LA39F:  jsr     L917F
        jmp     LA3A7

        ora     (L0000,x)
LA3A7:  ldy     #$CC
        lda     #$A5
        ldx     #$A3
        jsr     L4021
        lda     $DF20
        beq     LA3CA
        sta     $D212
        ldy     #$3C
        lda     #$12
        ldx     #$D2
        jsr     L4003
        ldy     #$04
        lda     #$15
        ldx     #$D2
        jsr     L4003
LA3CA:  ldx     L9188
        txs
        lda     #$FF
        rts

LA3D1:  ldy     #$2A
        lda     #$08
        ldx     #$D2
        jsr     L4003
        lda     $D208
        cmp     #$03
        bne     LA3EC
        lda     $D209
        cmp     #$1B
        bne     LA3EC
        lda     #$FF
        bne     LA3EE
LA3EC:  lda     #$00
LA3EE:  rts

LA3EF:  lda     LA2ED
        sec
        sbc     #$01
        sta     L9E7A
        lda     LA2EE
        sbc     #$00
        sta     L9E7B
        ldy     #$02
        lda     #$79
        ldx     #$9E
        jsr     LA500
        rts

LA40A:  lda     LA2ED
        sec
        sbc     #$01
        sta     L9938
        lda     LA2EE
        sbc     #$00
        sta     L9939
        ldy     #$01
        lda     #$37
        ldx     #$99
        jsr     LA500
        rts

LA425:  brk
LA426:  jsr     LA46D
        lda     #$C3
        sta     L978A
        jsr     LA479
        lda     L9778
        cmp     #$0F
        beq     LA46C
        ldy     #$C8
        lda     #$44
        ldx     #$97
        jsr     L4021
        beq     LA449
        jsr     LA497
        jmp     LA426

LA449:  lda     L9749
        sta     L979B
        sta     L973A
LA452:  ldy     #$D0
        lda     #$9A
        ldx     #$97
        jsr     L4021
        beq     LA463
        jsr     LA497
        jmp     LA452

LA463:  ldy     #$CC
        lda     #$39
        ldx     #$97
        jsr     L4021
LA46C:  rts

LA46D:  ldx     #$0A
LA46F:  lda     L9777,x
        sta     L978A,x
        dex
        bpl     LA46F
        rts

LA479:  lda     #$07
        sta     L9787
        ldy     #$C3
        lda     #$87
        ldx     #$97
        jsr     L4021
        pha
        lda     #$0A
        sta     L9787
        pla
        beq     LA496
        jsr     LA497
        jmp     LA479

LA496:  rts

LA497:  ldx     #$80
        bne     LA49D
LA49B:  ldx     #$00
LA49D:  stx     LA4C5
        cmp     #$45
        beq     LA4AE
        cmp     #$44
        beq     LA4AE
        jsr     L4030
        bne     LA4C2
        rts

LA4AE:  bit     LA4C5
        bpl     LA4B8
        lda     #$FD
        jmp     LA4BA

LA4B8:  lda     #$FC
LA4BA:  jsr     L4030
        bne     LA4C2
        jmp     LA4C6

LA4C2:  jmp     LA39F

LA4C5:  brk
LA4C6:  ldy     #$C5
        lda     #$A9
        ldx     #$97
        jsr     L4021
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
LA500:  jmp     LA520

LA503:  .byte   $9C
LA504:  .byte   $A8,$57,$A9,$D4,$AC,$34,$AE,$98
        .byte   $A8,$98,$A8,$28,$AF,$2C,$B0,$4A
        .byte   $B1,$68,$B2,$E1,$AA,$FA,$AB,$25
        .byte   $B3
LA51D:  .byte   $00
LA51E:  .byte   $00,$00
LA520:  sta     LA51D
        stx     LA51E
        tya
        asl     a
        tax
        lda     LA503,x
        sta     LA565
        lda     LA504,x
        sta     LA566
        lda     #$00
        sta     $D8EB
        sta     $D8EC
        sta     $D8F0
        sta     $D8F1
        sta     $D8F2
        sta     $D8E8
        sta     $D8F5
        sta     $D8ED
        sta     LB3E6
        lda     #$14
        sta     $D8E9
        lda     #$98
        sta     LA89A
        lda     #$A8
        sta     LA89B
        jsr     LB403
        .byte   $4C
LA565:  brk
LA566:  brk
LA567:  lda     $D8E8
        beq     LA579
        dec     $D8E9
        bne     LA579
        jsr     LB8F5
        lda     #$14
        sta     $D8E9
LA579:  A2D_RELAY_CALL A2D_GET_INPUT, $D208
        lda     $D208
        cmp     #$01
        bne     LA58C
        jmp     LA5EE

LA58C:  cmp     #$03
        bne     LA593
        jmp     LA6FD

LA593:  lda     $D8E8
        beq     LA567
        A2D_RELAY_CALL A2D_QUERY_TARGET, $D209
        lda     $D20D
        bne     LA5A9
        jmp     LA567

LA5A9:  lda     $D20E
        cmp     $D57D
        beq     LA5B4
        jmp     LA567

LA5B4:  lda     $D57D
        jsr     LB7B9
        lda     $D57D
        sta     $D208
        A2D_RELAY_CALL A2D_MAP_COORDS, $D208
        A2D_RELAY_CALL A2D_SET_POS, $D20D
LA5D2:  A2D_RELAY_CALL A2D_TEST_BOX, $D6AB
        cmp     #$80
        bne     LA5E5
        jsr     LB3D8
        jmp     LA5E8

LA5E5:  jsr     LB3CA
LA5E8:  jsr     LBEB1
        jmp     LA567

LA5EE:  A2D_RELAY_CALL A2D_QUERY_TARGET, $D209
        lda     $D20D
        bne     LA5FF
        lda     #$FF
        rts

LA5FF:  cmp     #$02
        bne     LA606
        jmp     LA609

LA606:  lda     #$FF
        rts

LA609:  lda     $D20E
        cmp     $D57D
        beq     LA614
        lda     #$FF
        rts

LA614:  lda     $D57D
        jsr     LB7B9
        lda     $D57D
        sta     $D208
        A2D_RELAY_CALL A2D_MAP_COORDS, $D208
        A2D_RELAY_CALL A2D_SET_POS, $D20D
        bit     $D8E7
        bvc     LA63A
        jmp     LA65E

LA63A:  A2D_RELAY_CALL A2D_TEST_BOX, $AE20
        cmp     #$80
        beq     LA64A
        jmp     LA6C1

LA64A:  jsr     LB43B
        A2D_RELAY_CALL A2D_FILL_RECT, $AE20
        jsr     LB7CF
        bmi     LA65D
        lda     #$00
LA65D:  rts

LA65E:  A2D_RELAY_CALL A2D_TEST_BOX, $AE28
        cmp     #$80
        bne     LA67F
        jsr     LB43B
        A2D_RELAY_CALL A2D_FILL_RECT, $AE28
        jsr     LB7D9
        bmi     LA67E
        lda     #$02
LA67E:  rts

LA67F:  A2D_RELAY_CALL A2D_TEST_BOX, $AE30
        cmp     #$80
        bne     LA6A0
        jsr     LB43B
        A2D_RELAY_CALL A2D_FILL_RECT, $AE30
        jsr     LB7DE
        bmi     LA69F
        lda     #$03
LA69F:  rts

LA6A0:  A2D_RELAY_CALL A2D_TEST_BOX, $AE38
        cmp     #$80
        bne     LA6C1
        jsr     LB43B
        A2D_RELAY_CALL A2D_FILL_RECT, $AE38
        jsr     LB7E3
        bmi     LA6C0
        lda     #$04
LA6C0:  rts

LA6C1:  bit     $D8E7
        bpl     LA6C9
        lda     #$FF
        rts

LA6C9:  A2D_RELAY_CALL A2D_TEST_BOX, $AE10
        cmp     #$80
        beq     LA6D9
        jmp     LA6ED

LA6D9:  jsr     LB43B
        A2D_RELAY_CALL A2D_FILL_RECT, $AE10
        jsr     LB7D4
        bmi     LA6EC
        lda     #$01
LA6EC:  rts

LA6ED:  bit     $D8E8
        bmi     LA6F7
        lda     #$FF
        jmp     LA899

LA6F7:  jsr     LB9B8
        lda     #$FF
        rts

LA6FD:  lda     $D20A
        cmp     #$02
        bne     LA71A
        lda     $D209
        and     #$7F
        cmp     #$08
        bne     LA710
        jmp     LA815

LA710:  cmp     #$15
        bne     LA717
        jmp     LA820

LA717:  lda     #$FF
        rts

LA71A:  lda     $D209
        and     #$7F
        cmp     #$08
        bne     LA72E
        bit     $D8ED
        bpl     LA72B
        jmp     L0CB8

LA72B:  jmp     LA82B

LA72E:  cmp     #$15
        bne     LA73D
        bit     $D8ED
        bpl     LA73A
        jmp     L0CD7

LA73A:  jmp     LA83E

LA73D:  cmp     #$0D
        bne     LA749
        bit     $D8E7
        bvs     LA717
        jmp     LA851

LA749:  cmp     #$1B
        bne     LA755
        bit     $D8E7
        bmi     LA717
        jmp     LA86F

LA755:  cmp     #$7F
        bne     LA75C
        jmp     LA88D

LA75C:  cmp     #$0B
        bne     LA76B
        bit     $D8ED
        bmi     LA768
        jmp     LA717

LA768:  jmp     L0D14

LA76B:  cmp     #$0A
        bne     LA77A
        bit     $D8ED
        bmi     LA777
        jmp     LA717

LA777:  jmp     L0CF9

LA77A:  bit     $D8E7
        bvc     LA79B
        cmp     #$59
        beq     LA7E8
        cmp     #$79
        beq     LA7E8
        cmp     #$4E
        beq     LA7F7
        cmp     #$6E
        beq     LA7F7
        cmp     #$41
        beq     LA806
        cmp     #$61
        beq     LA806
        cmp     #$0D
        beq     LA7E8
LA79B:  bit     $D8F5
        bmi     LA7C8
        cmp     #$2E
        beq     LA7D8
        cmp     #$30
        bcs     LA7AB
        jmp     LA717

LA7AB:  cmp     #$7B
        bcc     LA7B2
        jmp     LA717

LA7B2:  cmp     #$3A
        bcc     LA7D8
        cmp     #$41
        bcs     LA7BD
        jmp     LA717

LA7BD:  cmp     #$5B
        bcc     LA7DD
        cmp     #$61
        bcs     LA7DD
        jmp     LA717

LA7C8:  cmp     #$20
        bcs     LA7CF
        jmp     LA717

LA7CF:  cmp     #$7E
        beq     LA7DD
        bcc     LA7DD
        jmp     LA717

LA7D8:  ldx     $D443
        beq     LA7E5
LA7DD:  ldx     $D8E8
        beq     LA7E5
        jsr     LBB0B
LA7E5:  lda     #$FF
        rts

LA7E8:  jsr     LB43B
        A2D_RELAY_CALL A2D_FILL_RECT, $AE28
        lda     #$02
        rts

LA7F7:  jsr     LB43B
        A2D_RELAY_CALL A2D_FILL_RECT, $AE30
        lda     #$03
        rts

LA806:  jsr     LB43B
        A2D_RELAY_CALL A2D_FILL_RECT, $AE38
        lda     #$04
        rts

LA815:  lda     $D8E8
        beq     LA81D
        jsr     LBC5E
LA81D:  lda     #$FF
        rts

LA820:  lda     $D8E8
        beq     LA828
        jsr     LBCC9
LA828:  lda     #$FF
        rts

LA82B:  lda     $D8E8
        beq     LA83B
        bit     $D8ED
        bpl     LA838
        jmp     L0CD7

LA838:  jsr     LBBA4
LA83B:  lda     #$FF
        rts

LA83E:  lda     $D8E8
        beq     LA84E
        bit     $D8ED
        bpl     LA84B
        jmp     L0CB8

LA84B:  jsr     LBC03
LA84E:  lda     #$FF
        rts

LA851:  lda     $D57D
        jsr     LB7B9
        jsr     LB43B
        A2D_RELAY_CALL A2D_FILL_RECT, $AE20
        A2D_RELAY_CALL A2D_FILL_RECT, $AE20
        lda     #$00
        rts

LA86F:  lda     $D57D
        jsr     LB7B9
        jsr     LB43B
        A2D_RELAY_CALL A2D_FILL_RECT, $AE10
        A2D_RELAY_CALL A2D_FILL_RECT, $AE10
        lda     #$01
        rts

LA88D:  lda     $D8E8
        beq     LA895
        jsr     LBB63
LA895:  lda     #$FF
        rts

        rts

LA899:  .byte   $4C
LA89A:  brk
LA89B:  brk
        A2D_RELAY_CALL A2D_CREATE_WINDOW, $D62B
        lda     $D62B
        jsr     LB7B9
        jsr     LB43B
        A2D_RELAY_CALL A2D_DRAW_RECT, $AEDD
        A2D_RELAY_CALL A2D_DRAW_RECT, $AEE5
        lda     #$ED
        ldx     #$AE
        jsr     LB723
        lda     #$FE
        ldx     #$AE
        ldy     #$81
        jsr     LB590
        lda     #$22
        ldx     #$AF
        ldy     #$82
        jsr     LB590
        lda     #$46
        ldx     #$AF
        ldy     #$83
        jsr     LB590
        lda     #$5A
        ldx     #$AF
        ldy     #$05
        jsr     LB590
        lda     #$93
        ldx     #$AF
        ldy     #$86
        jsr     LB590
        lda     #$B4
        ldx     #$AF
        ldy     #$07
        jsr     LB590
        lda     #$EE
        ldx     #$AF
        ldy     #$09
        jsr     LB590
        lda     #$36
        sta     $D6C3
        lda     #$01
        sta     $D6C4
        lda     #$00
        ldx     #$B0
        ldy     #$09
        jsr     LB590
        lda     #$28
        sta     $D6C3
        lda     #$00
        sta     $D6C4
LA923:  A2D_RELAY_CALL A2D_GET_INPUT, $D208
        lda     $D208
        cmp     #$01
        beq     LA947
        cmp     #$03
        bne     LA923
        lda     $D209
        and     #$7F
        cmp     #$1B
        beq     LA947
        cmp     #$0D
        bne     LA923
        jmp     LA947

LA947:  A2D_RELAY_CALL A2D_DESTROY_WINDOW, $D62B
        jsr     LBEB1
        jsr     LB3CA
        rts

        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        cmp     #$01
        bne     LA965
        jmp     LA9B5

LA965:  cmp     #$02
        bne     LA96C
        jmp     LA9E6

LA96C:  cmp     #$03
        bne     LA973
        jmp     LAA6A

LA973:  cmp     #$04
        bne     LA97A
        jmp     LAA9C

LA97A:  cmp     #$05
        bne     LA981
        jmp     LAA5A

LA981:  lda     #$00
        sta     $D8E8
        jsr     LB53A
        lda     #$0C
        ldx     #$B0
        jsr     LB723
        lda     #$15
        ldx     #$B0
        ldy     #$01
        jsr     LB590
        lda     #$22
        ldx     #$B0
        ldy     #$02
        jsr     LB590
        lda     #$28
        ldx     #$B0
        ldy     #$03
        jsr     LB590
        lda     #$2D
        ldx     #$B0
        ldy     #$04
        jsr     LB590
        rts

LA9B5:  ldy     #$01
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDC4
        jsr     LBDDF
        lda     $D57D
        jsr     LB7B9
        A2D_RELAY_CALL A2D_SET_POS, $B0B6
        lda     #$01
        ldx     #$D9
        jsr     LB708
        lda     #$FB
        ldx     #$D8
        jsr     LB708
        rts

LA9E6:  ldy     #$01
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDC4
        jsr     LBDDF
        lda     $D57D
        jsr     LB7B9
        jsr     LBE8D
        jsr     LBE9A
        jsr     LB3BF
        ldy     #$03
        lda     (L0006),y
        tax
        iny
        lda     (L0006),y
        sta     $07
        stx     L0006
        jsr     LBE63
        A2D_RELAY_CALL A2D_SET_POS, $AE7E
        lda     #$02
        ldx     #$D4
        jsr     LB708
        jsr     LB3BF
        ldy     #$05
        lda     (L0006),y
        tax
        iny
        lda     (L0006),y
        sta     $07
        stx     L0006
        jsr     LBE78
        A2D_RELAY_CALL A2D_SET_POS, $AE82
        lda     #$43
        ldx     #$D4
        .byte   $20
        php
LAA48:  smb3    $A0
        asl     LBAA9
        ldx     #$B0
        jsr     A2D_RELAY
        lda     #$01
        ldx     #$D9
        jsr     LB708
        rts

LAA5A:  jsr     LBEB1
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $D57D
        jsr     LB403
        rts

LAA6A:  jsr     LAACE
        lda     $D57D
        jsr     LB7B9
        lda     #$47
        ldx     #$B0
        ldy     #$06
        jsr     LB590
        jsr     LB64E
LAA7F:  jsr     LA567
        bmi     LAA7F
        pha
        jsr     LB687
        A2D_RELAY_CALL A2D_SET_FILL_MODE, $D200
        A2D_RELAY_CALL A2D_FILL_RECT, $AE76
        pla
        rts

LAA9C:  jsr     LAACE
        lda     $D57D
        jsr     LB7B9
        lda     #$80
        ldx     #$B0
        ldy     #$06
        jsr     LB590
        jsr     LB6AF
LAAB1:  jsr     LA567
        bmi     LAAB1
        pha
        jsr     LB6D0
        A2D_RELAY_CALL A2D_SET_FILL_MODE, $D200
        A2D_RELAY_CALL A2D_FILL_RECT, $AE76
        pla
        rts

LAACE:  sta     ALTZPOFF
        sta     $C082
        jsr     BELL1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        cmp     #$01
        bne     LAAEF
        jmp     LAB38

LAAEF:  cmp     #$02
        bne     LAAF6
        jmp     LAB69

LAAF6:  cmp     #$03
        bne     LAAFD
        jmp     LABB8

LAAFD:  cmp     #$04
        bne     LAB04
        jmp     LABC8

LAB04:  lda     #$00
        sta     $D8E8
        jsr     LB53A
        lda     #$73
        ldx     #$B4
        jsr     LB723
        lda     #$15
        ldx     #$B0
        ldy     #$01
        jsr     LB590
        lda     #$22
        ldx     #$B0
        ldy     #$02
        jsr     LB590
        lda     #$28
        ldx     #$B0
        ldy     #$03
        jsr     LB590
        lda     #$2D
        ldx     #$B0
        ldy     #$04
        jsr     LB590
        rts

LAB38:  ldy     #$01
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDC4
        jsr     LBDDF
        lda     $D57D
        jsr     LB7B9
        A2D_RELAY_CALL A2D_SET_POS, $B0B6
        lda     #$01
        ldx     #$D9
        jsr     LB708
        lda     #$FB
        ldx     #$D8
        jsr     LB708
        rts

LAB69:  ldy     #$01
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDC4
        jsr     LBDDF
        lda     $D57D
        jsr     LB7B9
        jsr     LBE8D
        jsr     LB3BF
        ldy     #$03
        lda     (L0006),y
        tax
        iny
        lda     (L0006),y
        sta     $07
        stx     L0006
        jsr     LBE63
        A2D_RELAY_CALL A2D_SET_POS, $AE7E
        lda     #$02
        ldx     #$D4
        jsr     LB708
        A2D_RELAY_CALL A2D_SET_POS, $B0BA
        lda     #$01
        ldx     #$D9
        jsr     LB708
        rts

LABB8:  jsr     LBEB1
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $D57D
        jsr     LB403
        rts

LABC8:  jsr     LAACE
        lda     $D57D
        jsr     LB7B9
        lda     #$80
        ldx     #$B4
        ldy     #$06
        jsr     LB590
        jsr     LB6E6
LABDD:  jsr     LA567
        bmi     LABDD
        pha
        jsr     LB6FB
        A2D_RELAY_CALL A2D_SET_FILL_MODE, $D200
        A2D_RELAY_CALL A2D_FILL_RECT, $AE76
        pla
        rts

        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        cmp     #$01
        bne     LAC08
        jmp     LAC3D

LAC08:  cmp     #$02
        bne     LAC0F
        jmp     LACAE

LAC0F:  cmp     #$03
        bne     LAC16
        jmp     LAC9E

LAC16:  jsr     LB53A
        lda     #$3A
        ldx     #$B4
        jsr     LB723
        lda     #$47
        ldx     #$B4
        ldy     #$01
        jsr     LB590
        ldy     #$01
        jsr     LB01F
        lda     #$57
        ldx     #$B4
        ldy     #$02
        jsr     LB590
        ldy     #$02
        jsr     LB01F
        rts

LAC3D:  ldy     #$01
        lda     (L0006),y
        sta     $D909
        tax
        iny
        lda     (L0006),y
        sta     $07
        stx     L0006
        ldy     #$00
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDDF
        lda     $D57D
        jsr     LB7B9
        lda     #$A5
        sta     $D6C3
        ldy     #$01
        lda     #$01
        ldx     #$D9
        jsr     LB590
        jsr     LB3BF
        ldy     #$03
        lda     (L0006),y
        tax
        iny
        lda     (L0006),y
        sta     $07
        stx     L0006
        ldy     #$00
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDDF
        lda     #$A5
        sta     $D6C3
        ldy     #$02
        lda     #$01
        ldx     #$D9
        jsr     LB590
        rts

LAC9E:  jsr     LBEB1
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $D57D
        jsr     LB403
        rts

LACAE:  lda     $D57D
        jsr     LB7B9
        jsr     LB6E6
LACB7:  jsr     LA567
        bmi     LACB7
        A2D_RELAY_CALL A2D_SET_FILL_MODE, $D200
        A2D_RELAY_CALL A2D_FILL_RECT, $AE6E
        jsr     LB6FB
        lda     #$00
        rts

        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        cmp     #$01
        bne     LACE2
        jmp     LAD2A

LACE2:  cmp     #$02
        bne     LACE9
        jmp     LADBB

LACE9:  cmp     #$03
        bne     LACF0
        jmp     LAD6C

LACF0:  cmp     #$04
        bne     LACF7
        jmp     LAE05

LACF7:  cmp     #$05
        bne     LACFE
        jmp     LADF5

LACFE:  sta     LAD1F
        lda     #$00
        sta     $D8E8
        jsr     LB53A
        lda     #$BE
        ldx     #$B0
        jsr     LB723
        lda     LAD1F
        beq     LAD20
        lda     #$DD
        ldx     #$B0
        ldy     #$04
        jsr     LB590
        rts

LAD1F:  brk
LAD20:  lda     #$C9
        ldx     #$B0
        ldy     #$04
        jsr     LB590
        rts

LAD2A:  ldy     #$01
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDC4
        jsr     LBDDF
        lda     $D57D
        jsr     LB7B9
        lda     LAD1F
LAD46:  bne     LAD54
        A2D_RELAY_CALL A2D_SET_POS, $B16A
        jmp     LAD5D

LAD54:  A2D_RELAY_CALL A2D_SET_POS, $B172
LAD5D:  lda     #$01
        ldx     #$D9
        jsr     LB708
        lda     #$FB
        ldx     #$D8
        jsr     LB708
        rts

LAD6C:  ldy     #$01
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDC4
        jsr     LBDDF
        lda     $D57D
        jsr     LB7B9
        jsr     LBE8D
        jsr     LB3BF
        ldy     #$03
        lda     (L0006),y
        tax
        iny
        lda     (L0006),y
        sta     $07
        stx     L0006
        jsr     LBE63
        A2D_RELAY_CALL A2D_SET_POS, $AE7E
        lda     #$02
        ldx     #$D4
        jsr     LB708
        A2D_RELAY_CALL A2D_SET_POS, $B16E
        lda     #$01
        ldx     #$D9
        jsr     LB708
        rts

LADBB:  lda     $D57D
        jsr     LB7B9
        jsr     LB6AF
LADC4:  jsr     LA567
        bmi     LADC4
        bne     LADF4
        A2D_RELAY_CALL A2D_SET_FILL_MODE, $D200
        A2D_RELAY_CALL A2D_FILL_RECT, $AE6E
        jsr     LB6D0
        ldy     #$02
        lda     #$0E
        ldx     #$B1
        jsr     LB590
        ldy     #$04
        lda     #$14
        ldx     #$B1
        jsr     LB590
        lda     #$00
LADF4:  rts

LADF5:  jsr     LBEB1
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $D57D
        jsr     LB403
        rts

LAE05:  lda     $D57D
        jsr     LB7B9
        lda     #$33
        ldx     #$B1
        ldy     #$06
        jsr     LB590
        jsr     LB64E
LAE17:  jsr     LA567
        bmi     LAE17
        pha
        jsr     LB687
        A2D_RELAY_CALL A2D_SET_FILL_MODE, $D200
        A2D_RELAY_CALL A2D_FILL_RECT, $AE76
        pla
        rts

        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        cmp     #$80
        bne     LAE42
        jmp     LAE70

LAE42:  cmp     #$40
        bne     LAE49
        jmp     LAF16

LAE49:  lda     #$80
        sta     $D8E8
        jsr     LBD69
        lda     #$00
        jsr     LB509
        lda     $D57D
        jsr     LB7B9
        lda     #$76
        ldx     #$B1
        jsr     LB723
        jsr     LB43B
        A2D_RELAY_CALL A2D_DRAW_RECT, $D6AB
        rts

LAE70:  lda     #$80
        sta     $D8E8
        lda     #$00
        sta     $D8E7
        jsr     LBD75
        jsr     LB3BF
        ldy     #$01
        lda     (L0006),y
        sta     $08
        iny
        lda     (L0006),y
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
LAE90:  lda     ($08),y
        sta     $D402,y
        dey
        bpl     LAE90
        lda     $D57D
        jsr     LB7B9
        ldy     #$02
        lda     #$85
        ldx     #$B1
        jsr     LB590
        lda     #$37
        sta     $D6C3
        ldy     #$02
        lda     #$02
        ldx     #$D4
        jsr     LB590
        lda     #$28
        sta     $D6C3
        ldy     #$04
        lda     #$89
        ldx     #$B1
        jsr     LB590
        jsr     LB961
LAEC6:  jsr     LA567
        bmi     LAEC6
        bne     LAF16
        lda     $D443
        beq     LAEC6
        cmp     #$10
        bcc     LAEE1
LAED6:  lda     #$FB
        jsr     L4030
        jsr     LB961
        jmp     LAEC6

LAEE1:  lda     $D402
        clc
        adc     $D443
        clc
        adc     #$01
        cmp     #$41
        bcs     LAED6
        inc     $D402
        ldx     $D402
        lda     #$2F
        sta     $D402,x
        ldx     $D402
        ldy     #$00
LAEFF:  inx
        iny
        lda     $D443,y
        sta     $D402,x
        cpy     $D443
        bne     LAEFF
        stx     $D402
        ldy     #$02
        ldx     #$D4
        lda     #$00
        rts

LAF16:  jsr     LBEB1
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $D57D
        jsr     LB403
        lda     #$01
        rts

        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        bmi     LAF34
        jmp     LAFB9

LAF34:  lda     #$00
        sta     $D8E8
        lda     (L0006),y
        lsr     a
        lsr     a
        ror     a
        eor     #$80
        jsr     LB509
        lda     $D57D
        jsr     LB7B9
        lda     #$C6
        ldx     #$B1
        jsr     LB723
        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        and     #$7F
        lsr     a
        ror     a
        sta     LB01D
        ldy     #$01
        lda     #$D3
        ldx     #$B1
        jsr     LB590
        bit     LB01D
        bmi     LAF78
        ldy     #$02
        lda     #$D8
        ldx     #$B1
        jsr     LB590
        jmp     LAF81

LAF78:  ldy     #$02
        lda     #$09
        ldx     #$B2
        jsr     LB590
LAF81:  bit     LB01D
        bpl     LAF92
        ldy     #$03
        lda     #$19
        ldx     #$B2
        jsr     LB590
        jmp     LAF9B

LAF92:  ldy     #$03
        lda     #$DF
        ldx     #$B1
        jsr     LB590
LAF9B:  ldy     #$04
        lda     #$E4
        ldx     #$B1
        jsr     LB590
        ldy     #$05
        lda     #$F2
        ldx     #$B1
        jsr     LB590
        ldy     #$06
        lda     #$04
        ldx     #$B2
        jsr     LB590
        jmp     LBEB1

LAFB9:  lda     $D57D
        jsr     LB7B9
        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        sta     LB01E
        tay
        jsr     LB01F
        lda     #$A5
        sta     $D6C3
        jsr     LB3BF
        lda     LB01E
        cmp     #$02
        bne     LAFF0
        ldy     #$01
        lda     (L0006),y
        beq     LAFE9
        lda     #$A8
        ldx     #$AE
        jmp     LAFF8

LAFE9:  lda     #$AD
        ldx     #$AE
        jmp     LAFF8

LAFF0:  ldy     #$02
        lda     (L0006),y
        tax
        dey
        lda     (L0006),y
LAFF8:  ldy     LB01E
        jsr     LB590
        lda     LB01E
        cmp     #$06
        beq     LB006
        rts

LB006:  jsr     LA567
        bmi     LB006
        pha
        jsr     LBEB1
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $D57D
        jsr     LB3CA
        pla
        rts

LB01D:  brk
LB01E:  brk
LB01F:  lda     #$A0
        sta     $D6C3
        lda     #$2A
        ldx     #$B2
        jsr     LB590
        rts

        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        cmp     #$01
        bne     LB03A
        jmp     LB068

LB03A:  cmp     #$02
        bne     LB041
        jmp     LB0F1

LB041:  cmp     #$03
        bne     LB048
        jmp     LB0A2

LB048:  cmp     #$04
        bne     LB04F
        jmp     LB13A

LB04F:  lda     #$00
        sta     $D8E8
        jsr     LB53A
        lda     #$00
        ldx     #$B4
        jsr     LB723
        ldy     #$04
        lda     #$09
        ldx     #$B4
        jsr     LB590
        rts

LB068:  ldy     #$01
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDC4
        jsr     LBDDF
        lda     $D57D
        jsr     LB7B9
        A2D_RELAY_CALL A2D_SET_POS, $B231
        lda     #$01
        ldx     #$D9
        jsr     LB708
        A2D_RELAY_CALL A2D_SET_POS, $B239
        lda     #$FB
        ldx     #$D8
        jsr     LB708
        rts

LB0A2:  ldy     #$01
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDC4
        jsr     LBDDF
        lda     $D57D
        jsr     LB7B9
        jsr     LBE8D
        jsr     LB3BF
        ldy     #$03
        lda     (L0006),y
        tax
        iny
        lda     (L0006),y
        sta     $07
        stx     L0006
        jsr     LBE63
        A2D_RELAY_CALL A2D_SET_POS, $AE7E
        lda     #$02
        ldx     #$D4
        jsr     LB708
        A2D_RELAY_CALL A2D_SET_POS, $B241
        lda     #$01
        ldx     #$D9
        jsr     LB708
        rts

LB0F1:  lda     $D57D
        jsr     LB7B9
        jsr     LB6AF
LB0FA:  jsr     LA567
        bmi     LB0FA
        bne     LB139
        A2D_RELAY_CALL A2D_SET_FILL_MODE, $D200
        A2D_RELAY_CALL A2D_FILL_RECT, $AE6E
        A2D_RELAY_CALL A2D_FILL_RECT, $AE20
        A2D_RELAY_CALL A2D_FILL_RECT, $AE10
        ldy     #$02
        lda     #$0E
        ldx     #$B1
        jsr     LB590
        ldy     #$04
        lda     #$1B
        ldx     #$B4
        jsr     LB590
        lda     #$00
LB139:  rts

LB13A:  jsr     LBEB1
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $D57D
        jsr     LB403
        rts

        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        cmp     #$01
        bne     LB158
        jmp     LB186

LB158:  cmp     #$02
        bne     LB15F
        jmp     LB20F

LB15F:  cmp     #$03
        bne     LB166
        jmp     LB1C0

LB166:  cmp     #$04
        bne     LB16D
        jmp     LB258

LB16D:  lda     #$00
        sta     $D8E8
        jsr     LB53A
        lda     #$C0
        ldx     #$B3
        jsr     LB723
        ldy     #$04
        lda     #$CB
        ldx     #$B3
        jsr     LB590
        rts

LB186:  ldy     #$01
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDC4
        jsr     LBDDF
        lda     $D57D
        jsr     LB7B9
        A2D_RELAY_CALL A2D_SET_POS, $B22D
        lda     #$01
        ldx     #$D9
        jsr     LB708
        A2D_RELAY_CALL A2D_SET_POS, $B235
        lda     #$FB
        ldx     #$D8
        jsr     LB708
        rts

LB1C0:  ldy     #$01
        lda     (L0006),y
        sta     $D909
        iny
        lda     (L0006),y
        sta     $D90A
        jsr     LBDC4
        jsr     LBDDF
        lda     $D57D
        jsr     LB7B9
        jsr     LBE8D
        jsr     LB3BF
        ldy     #$03
        lda     (L0006),y
        tax
        iny
        lda     (L0006),y
        sta     $07
        stx     L0006
        jsr     LBE63
        A2D_RELAY_CALL A2D_SET_POS, $AE7E
        lda     #$02
        ldx     #$D4
        jsr     LB708
        A2D_RELAY_CALL A2D_SET_POS, $B23D
        lda     #$01
        ldx     #$D9
        jsr     LB708
        rts

LB20F:  lda     $D57D
        jsr     LB7B9
        jsr     LB6AF
LB218:  jsr     LA567
        bmi     LB218
        bne     LB257
        A2D_RELAY_CALL A2D_SET_FILL_MODE, $D200
        A2D_RELAY_CALL A2D_FILL_RECT, $AE6E
        A2D_RELAY_CALL A2D_FILL_RECT, $AE20
        A2D_RELAY_CALL A2D_FILL_RECT, $AE10
        ldy     #$02
        lda     #$0E
        ldx     #$B1
        jsr     LB590
        ldy     #$04
        lda     #$DF
        ldx     #$B3
        jsr     LB590
        lda     #$00
LB257:  rts

LB258:  jsr     LBEB1
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $D57D
        jsr     LB403
        rts

        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        cmp     #$80
        bne     LB276
        jmp     LB2ED

LB276:  cmp     #$40
        bne     LB27D
        jmp     LB313

LB27D:  jsr     LBD75
        jsr     LB3BF
        lda     #$80
        sta     $D8E8
        jsr     LBD69
        lda     #$00
        jsr     LB509
        lda     $D57D
        jsr     LB7B9
        lda     #$A0
        ldx     #$B1
        jsr     LB723
        jsr     LB43B
        A2D_RELAY_CALL A2D_DRAW_RECT, $D6AB
        ldy     #$02
        lda     #$B3
        ldx     #$B1
        jsr     LB590
        lda     #$55
        sta     $D6C3
        jsr     LB3BF
        ldy     #$01
        lda     (L0006),y
        sta     $08
        iny
        lda     (L0006),y
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
LB2CA:  lda     ($08),y
        sta     $D8D7,y
        dey
        bpl     LB2CA
        ldy     #$02
        lda     #$D7
        ldx     #$D8
        jsr     LB590
        ldy     #$04
        lda     #$BC
        ldx     #$B1
        jsr     LB590
        lda     #$00
        sta     $D443
        jsr     LB961
        rts

LB2ED:  lda     #$00
        sta     $D8E7
        lda     #$80
        sta     $D8E8
        lda     $D57D
        jsr     LB7B9
LB2FD:  jsr     LA567
        bmi     LB2FD
        bne     LB313
        lda     $D443
        beq     LB2FD
        jsr     LBCC9
        ldy     #$43
        ldx     #$D4
        lda     #$00
        rts

LB313:  jsr     LBEB1
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $D57D
        jsr     LB403
        lda     #$01
        rts

        A2D_RELAY_CALL A2D_HIDE_CURSOR
        jsr     LB55F
        lda     $D57D
        jsr     LB7B9
        lda     #$B3
        ldx     #$B4
        jsr     LB723
        A2D_RELAY_CALL A2D_SHOW_CURSOR
        jsr     LB3BF
        ldy     #$00
        lda     (L0006),y
        pha
        bmi     LB357
        tax
        lda     LB39C,x
        bne     LB361
LB357:  pla
        and     #$7F
        pha
        jsr     LB6E6
        jmp     LB364

LB361:  jsr     LB6AF
LB364:  pla
        pha
        asl     a
        asl     a
        tay
        lda     LB3A4,y
        tax
        lda     LB3A3,y
        ldy     #$03
        jsr     LB590
        pla
        asl     a
        asl     a
        tay
        lda     LB3A6,y
        tax
        lda     LB3A5,y
        ldy     #$04
        jsr     LB590
LB385:  jsr     LA567
        bmi     LB385
        pha
        jsr     LBEB1
        A2D_RELAY_CALL A2D_DESTROY_WINDOW, $D57D
        jsr     LB403
        pla
        rts

LB39C:  .byte   $80,$00,$00,$80,$00,$00,$80
LB3A3:  .byte   $BD
LB3A4:  .byte   $B4
LB3A5:  .byte   $B1
LB3A6:  .byte   $B4,$DC,$B4,$10,$B5,$DC,$B4,$10
        .byte   $B5,$30,$B5,$B1,$B4,$30,$B5,$B1
        .byte   $B4,$69,$B5,$B1,$B4,$9A,$B5,$C4
        .byte   $B5
LB3BF:  .byte   $AD
        ora     L85A5,x
        asl     $AD
        asl     L85A5,x
        rmb0    $60
LB3CA:  bit     LB3E6
        bpl     LB3D7
        jsr     LB403
        lda     #$00
        sta     LB3E6
LB3D7:  rts

LB3D8:  bit     LB3E6
        bmi     LB3E5
        jsr     LB41F
        lda     #$80
        sta     LB3E6
LB3E5:  rts

LB3E6:  brk
        A2D_RELAY_CALL A2D_HIDE_CURSOR
        A2D_RELAY_CALL A2D_SET_CURSOR, $D311
        A2D_RELAY_CALL A2D_SHOW_CURSOR
        rts

LB403:  A2D_RELAY_CALL A2D_HIDE_CURSOR
        A2D_RELAY_CALL A2D_SET_CURSOR, $D2AD
        A2D_RELAY_CALL A2D_SHOW_CURSOR
        rts

LB41F:  A2D_RELAY_CALL A2D_HIDE_CURSOR
        A2D_RELAY_CALL A2D_SET_CURSOR, $D2DF
        A2D_RELAY_CALL A2D_SHOW_CURSOR
        rts

LB43B:  A2D_RELAY_CALL A2D_SET_FILL_MODE, $D202
        rts

        ldx     #$03
LB447:  lda     $D209,x
        sta     LB502,x
        dex
        bpl     LB447
        lda     #$00
        sta     LB501
        lda     $D2AB
        asl     a
        sta     LB500
        rol     LB501
LB45F:  dec     LB500
        lda     LB500
        cmp     #$FF
        bne     LB46C
        dec     LB501
LB46C:  lda     LB501
        bne     LB476
        lda     LB500
        beq     LB4B7
LB476:  A2D_RELAY_CALL $2C, $D208 ; ???
        jsr     LB4BA
        bmi     LB4B7
        lda     #$FF
        sta     LB508
        lda     $D208
        sta     LB507
        cmp     #$00
        beq     LB45F
        cmp     #$04
        beq     LB45F
        cmp     #$02
        bne     LB4A7
        A2D_RELAY_CALL A2D_GET_INPUT, $D208
        jmp     LB45F

LB4A7:  cmp     #$01
        bne     LB4B7
        A2D_RELAY_CALL A2D_GET_INPUT, $D208
        lda     #$00
        rts

LB4B7:  lda     #$FF
        rts

LB4BA:  lda     $D209
        sec
        sbc     LB502
        sta     LB506
        lda     $D20A
        sbc     LB503
        bpl     LB4D6
        lda     LB506
        cmp     #$FB
        bcs     LB4DD
LB4D3:  lda     #$FF
        rts

LB4D6:  lda     LB506
        cmp     #$05
        bcs     LB4D3
LB4DD:  lda     $D20B
        sec
        sbc     LB504
        sta     LB506
        lda     $D20C
        sbc     LB505
        bpl     LB4F6
        lda     LB506
        cmp     #$FC
        bcs     LB4FD
LB4F6:  lda     LB506
        cmp     #$04
        bcs     LB4D3
LB4FD:  lda     #$00
        rts

LB500:  brk
LB501:  brk
LB502:  brk
LB503:  brk
LB504:  brk
LB505:  brk
LB506:  brk
LB507:  brk
LB508:  brk
LB509:  sta     $D8E7
        jsr     LB53A
        bit     $D8E7
        bvc     LB51A
        jsr     LB64E
        jmp     LB526

LB51A:  A2D_RELAY_CALL A2D_DRAW_RECT, $AE20
        jsr     LB5F9
LB526:  bit     $D8E7
        bmi     LB537
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE10
        jsr     LB60A
LB537:  jmp     LBEB1

LB53A:  A2D_RELAY_CALL A2D_CREATE_WINDOW, $D57D
        lda     $D57D
        jsr     LB7B9
        jsr     LB43B
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE00
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE08
        rts

LB55F:  A2D_RELAY_CALL A2D_CREATE_WINDOW, $D57D
        lda     $D57D
        jsr     LB7B9
        jsr     LBEA7
        A2D_RELAY_CALL A2D_DRAW_BITMAP, $D56D
        jsr     LB43B
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE00
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE08
        rts

LB590:  stx     $07
        sta     L0006
        tya
        bmi     LB59A
        jmp     LB5CC

LB59A:  tya
        pha
        lda     L0006
        clc
        adc     #$01
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        jsr     LBD7B
        sta     $0A
        A2D_RELAY_CALL A2D_MEASURE_TEXT, $0008
        lsr     $0C
        ror     $0B
        lda     #$C8
        sec
        sbc     $0B
        sta     $D6C3
        lda     #$00
        sbc     $0C
        sta     $D6C4
        pla
        tay
LB5CC:  dey
        tya
        asl     a
        asl     a
        asl     a
        clc
        adc     $D6C1
        sta     $D6C5
        lda     $D6C2
        adc     #$00
        sta     $D6C6
        A2D_RELAY_CALL A2D_SET_POS, $D6C3
        lda     L0006
        ldx     $07
        jsr     LB708
        ldx     $D6C3
        lda     #$28
        sta     $D6C3
        rts

LB5F9:  A2D_RELAY_CALL A2D_SET_POS, $AE50
        lda     #$40
        ldx     #$AE
        jsr     LB708
        rts

LB60A:  A2D_RELAY_CALL A2D_SET_POS, $AE54
        lda     #$96
        ldx     #$AE
        jsr     LB708
        rts

LB61B:  A2D_RELAY_CALL A2D_SET_POS, $AE58
        lda     #$A8
        ldx     #$AE
        jsr     LB708
        rts

LB62C:  A2D_RELAY_CALL A2D_SET_POS, $AE5C
        lda     #$AD
        ldx     #$AE
        jsr     LB708
        rts

LB63D:  A2D_RELAY_CALL A2D_SET_POS, $AE60
        lda     #$B1
        ldx     #$AE
        jsr     LB708
        rts

LB64E:  jsr     LB43B
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE28
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE30
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE38
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE10
        jsr     LB61B
        jsr     LB62C
        jsr     LB63D
        jsr     LB60A
        lda     #$40
        sta     $D8E7
        rts

LB687:  jsr     LBEA7
        A2D_RELAY_CALL A2D_FILL_RECT, $AE28
        A2D_RELAY_CALL A2D_FILL_RECT, $AE30
        A2D_RELAY_CALL A2D_FILL_RECT, $AE38
        A2D_RELAY_CALL A2D_FILL_RECT, $AE10
        rts

LB6AF:  jsr     LB43B
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE20
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE10
        jsr     LB5F9
        jsr     LB60A
        lda     #$00
        sta     $D8E7
        rts

LB6D0:  jsr     LBEA7
        A2D_RELAY_CALL A2D_FILL_RECT, $AE20
        A2D_RELAY_CALL A2D_FILL_RECT, $AE10
        rts

LB6E6:  jsr     LB43B
        A2D_RELAY_CALL A2D_DRAW_RECT, $AE20
        jsr     LB5F9
        lda     #$80
        sta     $D8E7
        rts

LB6FB:  jsr     LBEA7
        A2D_RELAY_CALL A2D_FILL_RECT, $AE20
        rts

LB708:  sta     L0006
        stx     $07
        jsr     LBD7B
        beq     LB722
        sta     $08
        inc     L0006
        bne     LB719
        inc     $07
LB719:  A2D_RELAY_CALL A2D_DRAW_TEXT, $0006
LB722:  rts

LB723:  sta     L0006
        stx     $07
        jsr     LBD7B
        sta     $08
        inc     L0006
        bne     LB732
        inc     $07
LB732:  A2D_RELAY_CALL A2D_MEASURE_TEXT, $0006
        lsr     $0A
        ror     $09
        lda     #$01
        sta     LB76B
        lda     #$90
        lsr     LB76B
        ror     a
        sec
        sbc     $09
        sta     $D6B7
        lda     LB76B
        sbc     $0A
        sta     $D6B8
        A2D_RELAY_CALL A2D_SET_POS, $D6B7
        A2D_RELAY_CALL A2D_DRAW_TEXT, $0006
        rts

LB76B:  brk
        sta     L0006
        stx     $07
        A2D_RELAY_CALL A2D_SET_POS, $D6BB
        lda     L0006
        ldx     $07
        jsr     LB708
        rts

LB781:  stx     $0B
        sta     $0A
        ldy     #$00
        lda     ($0A),y
        tay
        bne     LB78D
        rts

LB78D:  dey
        beq     LB792
        bpl     LB793
LB792:  rts

LB793:  lda     ($0A),y
        and     #$7F
        cmp     #$2F
        beq     LB79F
        cmp     #$2E
        bne     LB7A3
LB79F:  dey
        jmp     LB78D

LB7A3:  iny
        lda     ($0A),y
        and     #$7F
        cmp     #$41
        bcc     LB7B5
        cmp     #$5B
        bcs     LB7B5
        clc
        adc     #$20
        sta     ($0A),y
LB7B5:  dey
        jmp     LB78D

LB7B9:  sta     $D212
        A2D_RELAY_CALL A2D_QUERY_STATE, $D212
        ldy     #$04
        lda     #$15
        .byte   $A2
LB7CA:  cmp     (L0020)
        brk
        bne     $B82F
LB7CF:  lda     #$00
        jmp     LB7E8

LB7D4:  lda     #$01
        jmp     LB7E8

LB7D9:  lda     #$02
        jmp     LB7E8

LB7DE:  lda     #$03
        jmp     LB7E8

LB7E3:  lda     #$04
        jmp     LB7E8

LB7E8:  pha
        asl     a
        asl     a
        tax
        lda     LB808,x
        sta     LB886
        lda     LB809,x
        sta     LB887
        lda     LB80A,x
        sta     LB888
        lda     LB80B,x
        sta     LB889
        pla
        jmp     LB88A

LB808:  .byte   $1C
LB809:  clv
LB80A:  .byte   $4E
LB80B:  clv
        rol     $B8
        cli
        clv
        bmi     LB7CA
        .byte   $62
        clv
        dec     a
        clv
        jmp     (L44B8)

        clv
        ror     $B8,x
        A2D_RELAY_CALL A2D_TEST_BOX, $AE20
        rts

        A2D_RELAY_CALL A2D_TEST_BOX, $AE10
        rts

        A2D_RELAY_CALL A2D_TEST_BOX, $AE28
        rts

        A2D_RELAY_CALL A2D_TEST_BOX, $AE30
        rts

        A2D_RELAY_CALL A2D_TEST_BOX, $AE38
        rts

        A2D_RELAY_CALL A2D_FILL_RECT, $AE20
        rts

        A2D_RELAY_CALL A2D_FILL_RECT, $AE10
        rts

        A2D_RELAY_CALL A2D_FILL_RECT, $AE28
        rts

        A2D_RELAY_CALL A2D_FILL_RECT, $AE30
        rts

        A2D_RELAY_CALL A2D_FILL_RECT, $AE38
        rts

LB880:  jmp     (LB886)

LB883:  jmp     (LB888)

LB886:  brk
LB887:  brk
LB888:  brk
LB889:  brk
LB88A:  sta     LB8F3
        lda     #$00
        sta     LB8F2
LB892:  A2D_RELAY_CALL A2D_GET_INPUT, $D208
        lda     $D208
        cmp     #$02
        beq     LB8E3
        lda     $D57D
        sta     $D208
        A2D_RELAY_CALL A2D_MAP_COORDS, $D208
        A2D_RELAY_CALL A2D_SET_POS, $D20D
        jsr     LB880
        cmp     #$80
        beq     LB8C9
        lda     LB8F2
        beq     LB8D1
        jmp     LB892

LB8C9:  lda     LB8F2
        bne     LB8D1
        jmp     LB892

LB8D1:  jsr     LB43B
        jsr     LB883
        lda     LB8F2
        clc
        adc     #$80
        sta     LB8F2
        jmp     LB892

LB8E3:  lda     LB8F2
        beq     LB8EB
        lda     #$FF
        rts

LB8EB:  jsr     LB883
        lda     LB8F3
        rts

LB8F2:  brk
LB8F3:  brk
        rts

LB8F5:  jsr     LBD3B
        sta     L0006
        stx     $07
        lda     $D6B5
        sta     $08
        lda     $D6B6
        sta     $09
        A2D_RELAY_CALL A2D_SET_POS, $0006
        A2D_RELAY_CALL A2D_SET_BOX, $D6C7
        bit     $D8EB
        bpl     LB92D
        A2D_RELAY_CALL A2D_SET_TEXT_MASK, $AE6C
        lda     #$00
        sta     $D8EB
        beq     LB93B
LB92D:  A2D_RELAY_CALL A2D_SET_TEXT_MASK, $AE6D
        lda     #$FF
        sta     $D8EB
LB93B:  lda     #$EF
        sta     L0006
        lda     #$D8
        sta     $07
        lda     $D8EE
        sta     $08
        A2D_RELAY_CALL A2D_DRAW_TEXT, $0006
        A2D_RELAY_CALL A2D_SET_TEXT_MASK, $AE6D
        lda     $D57D
        jsr     LB7B9
        rts

LB961:  lda     $D443
        beq     LB9B7
        lda     $D57D
        jsr     LB7B9
        jsr     LBEA7
        A2D_RELAY_CALL A2D_FILL_RECT, $D6AB
        A2D_RELAY_CALL A2D_SET_FILL_MODE, $D202
        A2D_RELAY_CALL A2D_DRAW_RECT, $D6AB
        A2D_RELAY_CALL A2D_SET_POS, $D6B3
        A2D_RELAY_CALL A2D_SET_BOX, $D6C7
        lda     #$43
        ldx     #$D4
        jsr     LB708
        lda     #$84
        ldx     #$D4
        jsr     LB708
        lda     #$F8
        ldx     #$D8
        jsr     LB708
        lda     $D57D
        jsr     LB7B9
LB9B7:  rts

LB9B8:  A2D_RELAY_CALL A2D_MAP_COORDS, $D208
        A2D_RELAY_CALL A2D_SET_POS, $D20D
        A2D_RELAY_CALL A2D_TEST_BOX, $D6AB
        cmp     #$80
        beq     LB9D8
        rts

LB9D8:  jsr     LBD3B
        sta     L0006
        stx     $07
        lda     $D20D
        cmp     L0006
        lda     $D20E
        sbc     $07
        bcs     LB9EE
        jmp     LBA83

LB9EE:  jsr     LBD3B
        sta     LBB09
        stx     LBB0A
        ldx     $D484
        inx
        lda     #$20
        sta     $D484,x
        inc     $D484
        lda     #$84
        sta     L0006
        lda     #$D4
        sta     $07
        lda     $D484
        sta     $08
LBA10:  A2D_RELAY_CALL A2D_MEASURE_TEXT, $0006
        lda     $09
        clc
        adc     LBB09
        sta     $09
        lda     $0A
        adc     LBB0A
        sta     $0A
        lda     $09
        cmp     $D20D
        lda     $0A
        sbc     $D20E
        bcc     LBA42
        dec     $08
        lda     $08
        cmp     #$01
        bne     LBA10
        dec     $D484
        jmp     LBB05

LBA42:  lda     $08
        cmp     $D484
        bcc     LBA4F
        dec     $D484
        jmp     LBCC9

LBA4F:  ldx     #$02
        ldy     $D443
        iny
LBA55:  lda     $D484,x
        sta     $D443,y
        cpx     $08
        beq     LBA64
        iny
        inx
        jmp     LBA55

LBA64:  sty     $D443
        ldy     #$02
        ldx     $08
        inx
LBA6C:  lda     $D484,x
        sta     $D484,y
        cpx     $D484
        beq     LBA7C
        iny
        inx
        jmp     LBA6C

LBA7C:  dey
        sty     $D484
        jmp     LBB05

LBA83:  lda     #$43
        sta     L0006
        lda     #$D4
        sta     $07
        lda     $D443
        sta     $08
LBA90:  A2D_RELAY_CALL A2D_MEASURE_TEXT, $0006
        lda     $09
        clc
        adc     $D6B3
        sta     $09
        lda     $0A
        adc     $D6B4
        sta     $0A
        .byte   $A5
LBAA9:  ora     #$CD
        ora     LA5D2
        asl     a
        sbc     $D20E
        bcc     LBABF
        dec     $08
        lda     $08
        cmp     #$01
        bcs     LBA90
        jmp     LBC5E

LBABF:  inc     $08
        ldy     #$00
        ldx     $08
LBAC5:  cpx     $D443
        beq     LBAD5
        inx
        iny
        lda     $D443,x
        sta     $D3C2,y
        jmp     LBAC5

LBAD5:  iny
        sty     $D3C1
        ldx     #$01
        ldy     $D3C1
LBADE:  cpx     $D484
        beq     LBAEE
        inx
        iny
        lda     $D484,x
        sta     $D3C1,y
        jmp     LBADE

LBAEE:  sty     $D3C1
        lda     $D8EF
        sta     $D3C2
LBAF7:  lda     $D3C1,y
        sta     $D484,y
        dey
        bpl     LBAF7
        lda     $08
        sta     $D443
LBB05:  jsr     LB961
        rts

LBB09:  brk
LBB0A:  brk
LBB0B:  sta     LBB62
        lda     $D443
        clc
        adc     $D484
        cmp     #$10
        bcc     LBB1A
        rts

LBB1A:  lda     LBB62
        ldx     $D443
        inx
        sta     $D443,x
        sta     $D8F7
        jsr     LBD3B
        inc     $D443
        sta     L0006
        stx     $07
        lda     $D6B5
        sta     $08
        lda     $D6B6
        sta     $09
        A2D_RELAY_CALL A2D_SET_POS, $0006
        A2D_RELAY_CALL A2D_SET_BOX, $D6C7
        lda     #$F6
        ldx     #$D8
        jsr     LB708
        lda     #$84
        ldx     #$D4
        jsr     LB708
        lda     $D57D
        jsr     LB7B9
        rts

LBB62:  brk
LBB63:  lda     $D443
        bne     LBB69
        rts

LBB69:  dec     $D443
        jsr     LBD3B
        sta     L0006
        stx     $07
        lda     $D6B5
        sta     $08
        lda     $D6B6
        sta     $09
        A2D_RELAY_CALL A2D_SET_POS, $0006
        A2D_RELAY_CALL A2D_SET_BOX, $D6C7
        lda     #$84
        ldx     #$D4
        jsr     LB708
        lda     #$F8
        ldx     #$D8
        jsr     LB708
        lda     $D57D
        jsr     LB7B9
        rts

LBBA4:  lda     $D443
        bne     LBBAA
        rts

LBBAA:  ldx     $D484
        cpx     #$01
        beq     LBBBC
LBBB1:  lda     $D484,x
        sta     $D485,x
        dex
        cpx     #$01
        bne     LBBB1
LBBBC:  ldx     $D443
        lda     $D443,x
        sta     $D486
        dec     $D443
        inc     $D484
        jsr     LBD3B
        sta     L0006
        stx     $07
        lda     $D6B5
        sta     $08
        lda     $D6B6
        sta     $09
        A2D_RELAY_CALL A2D_SET_POS, $0006
        A2D_RELAY_CALL A2D_SET_BOX, $D6C7
        lda     #$84
        ldx     #$D4
        jsr     LB708
        lda     #$F8
        ldx     #$D8
        jsr     LB708
        lda     $D57D
        jsr     LB7B9
        rts

LBC03:  lda     $D484
        cmp     #$02
        bcs     LBC0B
        rts

LBC0B:  ldx     $D443
        inx
        lda     $D486
        sta     $D443,x
        inc     $D443
        ldx     $D484
        cpx     #$03
        bcc     LBC2D
        ldx     #$02
LBC21:  lda     $D485,x
        sta     $D484,x
        inx
        cpx     $D484
        bne     LBC21
LBC2D:  dec     $D484
        A2D_RELAY_CALL A2D_SET_POS, $D6B3
        A2D_RELAY_CALL A2D_SET_BOX, $D6C7
        lda     #$43
        ldx     #$D4
        jsr     LB708
        lda     #$84
        ldx     #$D4
        jsr     LB708
        lda     #$F8
        ldx     #$D8
        jsr     LB708
        lda     $D57D
        jsr     LB7B9
        rts

LBC5E:  lda     $D443
        bne     LBC64
        rts

LBC64:  ldx     $D484
        cpx     #$01
        beq     LBC79
LBC6B:  lda     $D484,x
        sta     $D3C0,x
        dex
        cpx     #$01
        bne     LBC6B
        ldx     $D484
LBC79:  dex
        stx     $D3C1
        ldx     $D443
LBC80:  lda     $D443,x
        sta     $D485,x
        dex
        bne     LBC80
        lda     $D8EF
        sta     $D485
        inc     $D443
        lda     $D443
        sta     $D484
        lda     $D443
        clc
        adc     $D3C1
        tay
        pha
        ldx     $D3C1
        beq     LBCB3
LBCA6:  lda     $D3C1,x
        sta     $D484,y
        dex
        dey
        cpy     $D484
        bne     LBCA6
LBCB3:  pla
        sta     $D484
        lda     #$00
        sta     $D443
        A2D_RELAY_CALL A2D_SET_POS, $D6B3
        jsr     LB961
        rts

LBCC9:  lda     $D484
        cmp     #$02
        bcs     LBCD1
        rts

LBCD1:  ldx     $D484
        dex
        txa
        clc
        adc     $D443
        pha
        tay
        ldx     $D484
LBCDF:  lda     $D484,x
        sta     $D443,y
        dex
        dey
        cpy     $D443
        bne     LBCDF
        pla
        sta     $D443
        lda     #$01
        sta     $D484
        A2D_RELAY_CALL A2D_SET_POS, $D6B3
        jsr     LB961
        rts

        sta     L0006
        stx     $07
        ldy     #$00
        lda     (L0006),y
        tay
        clc
        adc     $D443
        pha
        tax
LBD11:  lda     (L0006),y
        sta     $D443,x
        dey
        dex
        cpx     $D443
        bne     LBD11
        pla
        sta     $D443
        rts

LBD22:  ldx     $D443
        cpx     #$00
        beq     LBD33
        dec     $D443
        lda     $D443,x
        cmp     #$2F
        bne     LBD22
LBD33:  rts

        jsr     LBD22
        jsr     LB961
        rts

LBD3B:  lda     #$44
        sta     L0006
        lda     #$D4
        sta     $07
        lda     $D443
        sta     $08
        bne     LBD51
        lda     $D6B3
        ldx     $D6B4
        rts

LBD51:  A2D_RELAY_CALL A2D_MEASURE_TEXT, $0006
        lda     $09
        clc
        adc     $D6B3
        tay
        lda     $0A
        adc     $D6B4
        tax
        tya
        rts

LBD69:  lda     #$01
        sta     $D484
        lda     $D8EF
        sta     $D485
        rts

LBD75:  lda     #$00
        sta     $D443
        rts

LBD7B:  ldx     #$11
LBD7D:  lda     L0020,x
        sta     LBDB0,x
        dex
        bpl     LBD7D
        ldx     #$11
LBD87:  lda     LBD9F,x
        sta     L0020,x
        dex
        bpl     LBD87
        jsr     L0020
        pha
        ldx     #$11
LBD95:  lda     LBDB0,x
        sta     L0020,x
        dex
        bpl     LBD95
        pla
        rts

LBD9F:  sta     RAMRDON
        sta     RAMWRTON
        ldy     #$00
        lda     (L0006),y
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts

LBDB0:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
LBDC4:  ldx     $D8FB
        lda     $D90A
        bne     LBDD9
        lda     $D909
        cmp     #$02
        bcs     LBDD9
        lda     #$20
        sta     $D8FB,x
        rts

LBDD9:  lda     #$73
        sta     $D8FB,x
        rts

LBDDF:  lda     $D909
        sta     LBE5F
        lda     $D90A
        sta     LBE60
        ldx     #$07
        lda     #$20
LBDEF:  sta     $D901,x
        dex
        bne     LBDEF
        lda     #$00
        sta     LBE62
        ldy     #$00
        ldx     #$00
LBDFE:  lda     #$00
        sta     LBE61
LBE03:  lda     LBE5F
        cmp     LBE57,x
        lda     LBE60
        sbc     LBE58,x
        bpl     LBE35
        lda     LBE61
        bne     LBE1F
        bit     LBE62
        bmi     LBE1F
        lda     #$20
        bne     LBE28
LBE1F:  ora     #$30
        pha
        lda     #$80
        sta     LBE62
        pla
LBE28:  sta     $D903,y
        iny
        inx
        inx
        cpx     #$08
        beq     LBE4E
        jmp     LBDFE

LBE35:  inc     LBE61
        lda     LBE5F
        sec
        sbc     LBE57,x
        sta     LBE5F
        lda     LBE60
        sbc     LBE58,x
        sta     LBE60
        jmp     LBE03

LBE4E:  lda     LBE5F
        ora     #$30
        sta     $D903,y
        rts

LBE57:  .byte   $10
LBE58:  rmb2    $E8
        .byte   $03
        stz     L0000
        asl     a
        brk
LBE5F:  brk
LBE60:  brk
LBE61:  brk
LBE62:  brk
LBE63:  ldy     #$00
        lda     (L0006),y
        tay
LBE68:  lda     (L0006),y
        sta     $D402,y
        dey
        bpl     LBE68
        lda     #$02
        ldx     #$D4
        jsr     LB781
        rts

LBE78:  ldy     #$00
        lda     (L0006),y
        tay
LBE7D:  lda     (L0006),y
        sta     $D443,y
        dey
        bpl     LBE7D
        lda     #$43
        ldx     #$D4
        jsr     LB781
        rts

LBE8D:  jsr     LBEA7
        A2D_RELAY_CALL A2D_FILL_RECT, $AE86
        rts

LBE9A:  jsr     LBEA7
        A2D_RELAY_CALL A2D_FILL_RECT, $AE8E
        rts

LBEA7:  A2D_RELAY_CALL A2D_SET_FILL_MODE, $D200
        rts

LBEB1:  A2D_RELAY_CALL A2D_QUERY_SCREEN, $D239
        A2D_RELAY_CALL A2D_SET_STATE, $D239
        rts

        .res    60, 0
