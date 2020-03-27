L103A           := $103A
L10F2           := $10F2
L1127           := $1127
L118B           := $118B
L223B           := $223B
L3000           := $3000
MGTK            := $4000
L523C           := $523C
L6874           := $6874
L6964           := $6964
L6E61           := $6E61
L7270           := $7270
FONT            := $8800
START           := $8E00
LA75E           := $A75E
LA839           := $A839
LA88F           := $A88F
LA8CB           := $A8CB
LA9B6           := $A9B6
LAA3A           := $AA3A
LAA5C           := $AA5C
LAAAE           := $AAAE
LAB37           := $AB37
LBCAB           := $BCAB
LBE70           := $BE70

        asl     $07C9
        bne     L1E3B
        lda     $BE54
        and     #$08
        bne     L1E36
        return  #$06

L1E36:  jmp     (LBCAB)

        lda     #$10
L1E3B:  sec
        rts

        lda     $BE61
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        pha
        lda     $BE62
        eor     #$01
        lsr     a
        pla
        ror     a
        sta     $BEC7
        copy16  #$0201, $BEC8
        lda     #$C5
        jsr     LBE70
        bcs     L1E3B
        lda     $BE62
        sta     $BE3D
        lda     $BE61
        sta     $BE3C
        lda     $BCBD
        eor     #$2F
        beq     L1EE6
        lda     $0201
        and     #$0F
        adc     #$02
        sta     $0201
        adc     $BCBC
        cmp     #$40
        tax
        lda     #$10
        bcs     L1EE7
        ldy     $BCBC
        stx     $BCBC
        dex
        dey
        bmi     L1E9C
        lda     $BCBD,y
        sta     $BCBD,x
        jmp     LA88F

L1E9C:  lda     #$2F
        sta     $BCBD
L1EA1:  sta     $BCBD,x
        lda     IN,x
        dex
        bne     L1EA1
        lda     $BE53
        cmp     #$0B
        beq     L1EE6
        cmp     #$16
        beq     L1EE6
        cmp     #$08
        beq     L1EE6
        lda     $0280
        tay
        clc
        adc     $0201
        cmp     #$40
        tax
        lda     #$10
        bcs     L1EE7
        stx     $0280
        dex
        dey
        bmi     L1ED8
        lda     $0281,y
        sta     $0281,x
        jmp     LA8CB

L1ED8:  lda     #$2F
        sta     $0281
L1EDD:  sta     $0281,x
        lda     IN,x
        dex
        bne     L1EDD
L1EE6:  clc
L1EE7:  rts

        jsr     LAB37
        ldy     #$09
L1EED:  cmp     $B96B,y
        beq     L1F27
        dey
        bpl     L1EED
        cmp     #$54
        beq     L1EFC
L1EF9:  jmp     LA839

L1EFC:  lda     #$04
        and     $BE54
        beq     L1F23
        ora     $BE56
        sta     $BE56
        copy16  #$1200, $BCAD
        jsr     LAA3A
        beq     L1EF9
        cmp     #$24
        beq     L1F76
        cmp     #$41
        bcc     L1F60
        jmp     LA9B6

L1F23:  sec
        return  #$0B

L1F27:  lda     $B975,y
        beq     L1F47
        and     $BE55
        beq     L1F23
        cmp     #$04
        bne     L1F41
        and     $BE57
        bne     L1F47
        lda     #$01
        sta     $BE62
        lda     #$04
L1F41:  ora     $BE57
        sta     $BE57
L1F47:  lda     $B97F,y
        and     #$03
        sta     $BCAD
        lda     $B97F,y
        lsr     a
        lsr     a
        sta     $BCAE
        jsr     LAA3A
        beq     L1FB0
        cmp     #$24
        beq     L1F76
L1F60:  stx     $BE4B
        jsr     LAA5C
        bcc     L1F6C
        bmi     L1FB3
        bcs     L1FB0
L1F6C:  ldx     $BE4B
        jsr     LAA3A
        bne     L1F60
        beq     L1F8F
L1F76:  jsr     LAA3A
        beq     L1FB0
L1F7B:  stx     $BE4B
        jsr     LAAAE
        bcc     L1F87
        bmi     L1FB3
        bcs     L1FB0
L1F87:  ldx     $BE4B
        jsr     LAA3A
        bne     L1F7B
L1F8F:  ldx     #$02
L1F91:  cpx     $BCAD
        beq     L1F9E
        lda     $BCAF,x
        bne     L1FB3
        dex
        bne     L1F91
L1F9E:  ldy     $BCAE
L1FA1:  lda     $BCAF,x
        sta     $BE58,y
        dey
        dex
        bpl     L1FA1
        ldx     $BE4B
        clc
        rts

L1FB0:  jmp     LA839

L1FB3:  jmp     LA75E

        ldy     #$00
L1FB8:  sta     $BCAF,y
        iny
        cpy     #$03
        beq     L1FC7
        jsr     LAA3A
        bne     L1FB8
        beq     L1FB0
L1FC7:  stx     $BE4B
L1FCA:  ldx     #$00
        lda     $BCAD
        cmp     #$0E
        beq     L1FB0
        asl     a
        adc     $BCAD
        tay
L1FD8:  lda     $BCAF,x
        eor     $B997,y
        asl     a
        bne     L1FE9
        iny
        inx
        cpx     #$03
        bne     L1FD8
        beq     L1FEE
L1FE9:  inc     $BCAD
        bne     L1FCA
L1FEE:  lda     #$0D
        sec
        sbc     $BCAD
        tay
        lda     $B989,y
        sta     $BE6A
        ldx     $BE4B
        clc
        rts

L2000:  jmp     L2031

        .byte   $03
        plp
        jsr     L3000
L2008:  .byte   0
        .byte   $04
L200A:  .byte   0
        bcc     L200F
        rts

L200F           := * + 1
        ora     ($00,x)
        .byte   0
        .byte   $04
L2012:  .byte   0
        .byte   0
        rti

        .byte   0
        rts

        .byte   0
        .byte   0
        .byte   $04
L201A:  .byte   0
        .byte   0
        .byte   $34
        .byte   0
        php
        .byte   0
        .byte   0
        .byte   $02
L2022:  .byte   0
        .byte   0
        asl     $00
        ora     ($00,x)
        php
        .byte   $53
        adc     $6C
        adc     $63
        .byte   $74
        .byte   $6F
        .byte   $72
L2031:  ldax    #$1700
L2035:  sta     $BF59,x
        dex
        bpl     L2035
        php
        sei
        MLI_CALL OPEN, $2003
        plp
        and     #$FF
        beq     L2049
        .byte   0
L2049:  lda     L2008
        sta     L2022
        sta     L200A
        sta     L2012
        sta     L201A
        php
        sei
        MLI_CALL SET_MARK, $2021
        plp
        and     #$FF
        beq     L2066
        .byte   0
L2066:  php
        sei
        MLI_CALL READ, $2009
        plp
        and     #$FF
        beq     L2074
        .byte   0
L2074:  php
        sei
        MLI_CALL READ, $2011
        plp
        and     #$FF
        beq     L2082
        .byte   0
L2082:  php
        sei
        MLI_CALL READ, $2019
        plp
        and     #$FF
        beq     L2090
        .byte   0
L2090:
L2092           := * + 2
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        ldx     #$00
L209B:  lda     $3400,x
        sta     $D000,x
        lda     $3500,x
        sta     $D100,x
        lda     $3600,x
        sta     $D200,x
        lda     $3700,x
        sta     $D300,x
        lda     $3800,x
        sta     $D400,x
        lda     $3900,x
        sta     $D500,x
        lda     $3A00,x
        sta     $D600,x
        lda     $3B00,x
        sta     $D700,x
        inx
        bne     L209B
        sta     ALTZPOFF
        sta     ROMIN2
        php
        sei
        MLI_CALL CLOSE, $2026
        plp
        and     #$FF
        jmp     START

        .byte   $03
        bpl     L2092
        inc     $8D03,x
        .byte   $89
        ora     ($AD),y
        .byte   $FF
        .byte   $03
        sta     $118A
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
L20F8:  lda     $1000,y
        sta     $D100,y
        lda     $1100,y
        sta     $D200,y
        dey
        bne     L20F8
        lda     ROMIN2
        jmp     L10F2

        lda     $1189
        sta     IRQ_VECTOR
        lda     $118A
        sta     $03FF
        MLI_CALL SET_PREFIX, $1031
        beq     L2124
        jmp     L1127

L2124:  MLI_CALL OPEN, $1034
        beq     L212F
        jmp     L118B

L212F:  lda     $1039
        sta     $1028
        MLI_CALL READ, $1027
        beq     L2140
        jmp     L118B

L2140:  MLI_CALL CLOSE, $102F
        beq     L214B
        jmp     L118B

L214B:  jmp     L2000

        jsr     SLOT3ENTRY
        jsr     HOME
        lda     #$0C
        sta     CV
        jsr     VTAB
        lda     #$50
        sec
        sbc     $115E
        lsr     a
        sta     CH
        ldy     #$00
L2166:  lda     $115F,y
        ora     #$80
        jsr     COUT
        iny
        cpy     $115E
        bne     L2166
L2174:  sta     KBDSTRB
L2177:  lda     CLR80COL
        bpl     L2177
        and     #$7F
        cmp     #$0D
        bne     L2174
        jmp     L103A

        PASCAL_STRING "Insert the system disk and press <Return>."

        .byte   0
        .byte   0
        sta     $06
        jmp     MONZ

        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ldx     $3D20,y
        tay
        bcs     L223B
        lda     $BE53
