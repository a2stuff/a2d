
        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ==================================================
;;; Overlay for Format/Erase
;;; ==================================================

        .org $800

L0006           := $0006
L00E8           := $00E8
L2000           := $2000

L4030           := $4030

LA132           := $A132
LA18A           := $A18A
LA1BE           := $A1BE
LA1D4           := $A1D4
LA1EF           := $A1EF
LA567           := $A567
LAACE           := $AACE
LB3E7           := $B3E7
LB403           := $B403
LB445           := $B445
LB509           := $B509
LB590           := $B590
LB708           := $B708
LB723           := $B723
LB781           := $B781
LB7B9           := $B7B9
LBD69           := $BD69
LBD75           := $BD75
LBEB1           := $BEB1

LF479           := $F479

L0800:  pha
        jsr     LB403
        pla
        cmp     #$04
        beq     L080C
        jmp     L09D9

L080C:  lda     #$00
        sta     $D8E8
        jsr     LB509
        lda     $D57D
        jsr     LB7B9
        addr_call LB723, $B245
        axy_call LB590, $01, $B257
        jsr     L0D31
        lda     #$FF
        sta     $D887
L0832:  copy16  #$0B48, $A89A
        lda     #$80
        sta     $D8ED
L0841:  jsr     LA567
        bmi     L0841
        pha
        copy16  #$B8F4, $A89A
        lda     #$00
        sta     $D8F3
        sta     $D8ED
        pla
        beq     L085F
        jmp     L09C2

L085F:  bit     $D887
        bmi     L0832
        lda     $D57D
        jsr     LB7B9
        MGTK_RELAY_CALL MGTK::SetPenMode, $D200
        MGTK_RELAY_CALL MGTK::PaintRect, $AE6E
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::FrameRect, $D6AB
        jsr     LBD75
        lda     #$80
        sta     $D8E8
        lda     #$00
        sta     $D8ED
        jsr     LBD69
        axy_call LB590, $03, $B28D
L08A7:  jsr     LA567
        bmi     L08A7
        beq     L08B7
        jmp     L09C2

L08B1:  jsr     LAACE
        jmp     L08A7

L08B7:  lda     $D443
        beq     L08B1
        cmp     #$10
        bcs     L08B1
        jsr     LB403
        lda     $D57D
        jsr     LB7B9
        MGTK_RELAY_CALL MGTK::SetPenMode, $D200
        MGTK_RELAY_CALL MGTK::PaintRect, $AE6E
        ldx     $D887
        lda     $BF32,x
        sta     L09D8
        sta     L09D7
        lda     #$00
        sta     $D8E8
        axy_call LB590, $03, $B2AF
        lda     L09D7
        jsr     L1A2D
        addr_call LB708, $D909
L0902:  jsr     LA567
        bmi     L0902
        beq     L090C
        jmp     L09C2

L090C:  lda     $D57D
        jsr     LB7B9
L0912:  MGTK_RELAY_CALL MGTK::SetPenMode, $D200
        ldy     #$11
L091D:  ldax    #$AE6E
        jsr     MGTK_RELAY
L0924:  ldax    #$B2C6
        ldy     #$01
L092B           := * + 1
        jsr     LB590
        lda     L09D7
        jsr     L12C1
        and     #$FF
        bne     L0942
        jsr     LB3E7
        lda     L09D7
L093F           := * + 2
        jsr     L126F
        bcs     L099B
L0942:  lda     $D57D
        jsr     LB7B9
        ldy     #$07
        lda     #$00
L094D           := * + 1
        ldx     #$D2
L0950           := * + 2
        jsr     MGTK_RELAY
        MGTK_RELAY_CALL MGTK::PaintRect, $AE6E
        axy_call LB590, $01, $B373
        addr_call L1900, $D443
        ldx     #$43
L096D           := * + 1
        ldy     #$D4
L096F           := * + 1
        lda     L09D7
        jsr     L1307
        pha
        jsr     LB403
        pla
        bne     L0980
        lda     #$00
        jmp     L09C2

L0980:  cmp     #$2B
        bne     L098C
        jsr     L4030
        bne     L09C2
        jmp     L090C

L098C:  jsr     L191B
        ldax    #$B388
L0994           := * + 1
        ldy     #$06
        jsr     LB590
        jmp     L09B8

L099B:  pha
        jsr     LB403
        pla
        cmp     #$2B
        bne     L09AC
        jsr     L4030
        bne     L09C2
        jmp     L090C

L09AC:  jsr     L191B
        axy_call LB590, $06, $B2DE
L09B8:  jsr     LA567
L09BC           := * + 1
        bmi     L09B8
        bne     L09C2
        jmp     L090C

L09C2:  pha
        jsr     LB403
        jsr     LBEB1
        MGTK_RELAY_CALL MGTK::CloseWindow, $D57D
        ldx     L09D8
        pla
        rts

L09D7:  .byte   0
L09D8:  .byte   0
L09D9:  lda     #$00
        sta     $D8E8
        jsr     LB509
        lda     $D57D
        jsr     LB7B9
        addr_call LB723, $B319
        ldax    #$B32A
L09F2:  ldy     #$01
        jsr     LB590
        jsr     L0D31
        lda     #$FF
        sta     $D887
        lda     #$48
        sta     $A89A
        lda     #$0B
        sta     $A89B
        lda     #$80
        sta     $D8ED
L0A0E:  jsr     LA567
        bmi     L0A0E
        beq     L0A18
        jmp     L0B31

L0A18:  bit     $D887
        bmi     L0A0E
        copy16  #$A898, $A89A
        lda     $D57D
        jsr     LB7B9
        MGTK_RELAY_CALL MGTK::SetPenMode, $D200
        MGTK_RELAY_CALL MGTK::PaintRect, $AE6E
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::FrameRect, $D6AB
        jsr     LBD75
        lda     #$80
        sta     $D8E8
        lda     #$00
        sta     $D8ED
        jsr     LBD69
        axy_call LB590, $03, $B28D
L0A6A:  jsr     LA567
        bmi     L0A6A
        beq     L0A7A
        jmp     L0B31

L0A74:  jsr     LAACE
        jmp     L0A6A

L0A7A:  lda     $D443
        beq     L0A74
L0A7F:  cmp     #$10
        bcs     L0A74
        jsr     LB403
        lda     $D57D
        jsr     LB7B9
        MGTK_RELAY_CALL MGTK::SetPenMode, $D200
        MGTK_RELAY_CALL MGTK::PaintRect, $AE6E
        lda     #$00
        sta     $D8E8
        ldx     $D887
        lda     $BF32,x
        sta     L0B47
        sta     L0B46
        axy_call LB590, $03, $B35D
        lda     L0B46
        and     #$F0
        jsr     L1A2D
        addr_call LB708, $D909
L0AC7:  jsr     LA567
        bmi     L0AC7
        beq     L0AD1
        jmp     L0B31

L0AD1:  lda     $D57D
        jsr     LB7B9
        MGTK_RELAY_CALL MGTK::SetPenMode, $D200
        MGTK_RELAY_CALL MGTK::PaintRect, $AE6E
        axy_call LB590, $01, $B373
        addr_call L1900, $D443
        jsr     LB3E7
        ldx     #$43
        ldy     #$D4
        lda     L0B46
        jsr     L1307
        pha
        jsr     LB403
        pla
        bne     L0B12
        lda     #$00
        jmp     L0B31

L0B12:  cmp     #$2B
        bne     L0B1E
        jsr     L4030
        bne     L0B31
        jmp     L0AD1

L0B1E:  jsr     L191B
        axy_call LB590, $06, $B388
L0B2A:  jsr     LA567
        bmi     L0B2A
        beq     L0AD1
L0B31:  pha
        jsr     LB403
        jsr     LBEB1
        MGTK_RELAY_CALL MGTK::CloseWindow, $D57D
        ldx     L0B47
        pla
        rts

L0B46:  .byte   0
L0B47:  .byte   0
        lda     $D20D
        cmp     #$28
        lda     $D20E
        sbc     #$00
        bpl     L0B57
        return  #$FF

L0B57:  lda     $D20D
        cmp     #$68
        lda     $D20E
        sbc     #$01
        bcc     L0B66
        return  #$FF

L0B66:  lda     $D20F
        sec
        sbc     #$2B
        sta     $D20F
        lda     $D210
        sbc     #$00
        bpl     L0B79
        return  #$FF

L0B79:  sta     $D210
        lsr16    $D20F
        lsr16    $D20F
        lsr16    $D20F
        lda     $D20F
        cmp     #$04
        bcc     L0B98
        return  #$FF

L0B98:  lda     #$02
        sta     L0C1F
        lda     $D20D
        cmp     #$18
        lda     $D20E
        sbc     #$01
        bcs     L0BBB
        dec     L0C1F
        lda     $D20D
        cmp     #$A0
        lda     $D20E
        sbc     #$00
        bcs     L0BBB
        dec     L0C1F
L0BBB:  lda     L0C1F
        asl     a
        asl     a
        clc
        adc     $D20F
        cmp     $D890
        bcc     L0BDC
        lda     $D887
        bmi     L0BD9
        lda     $D887
        jsr     L0C20
        lda     #$FF
        sta     $D887
L0BD9:  return  #$FF

L0BDC:  cmp     $D887
        bne     L0C04
        jsr     LB445
        bmi     L0C03
L0BE6:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $AE20
        ldy     #$11
        ldax    #$AE20
L0C00           := * + 2
        jsr     MGTK_RELAY
L0C01:  lda     #$00
L0C03:  rts

L0C04:  sta     L0C1E
        lda     $D887
        bmi     L0C0F
        jsr     L0C20
L0C0F:  lda     L0C1E
        sta     $D887
        jsr     L0C20
        jsr     LB445
        beq     L0BE6
        rts

L0C1E:  .byte   0
L0C1F:  .byte   0
L0C20:  ldy     #$27
L0C23           := * + 1
        sty     $D888
        ldy     #$00
        sty     $D889
        tax
        lsr     a
        lsr     a
        sta     L0CA9
        beq     L0C5B
        add16   $D888, #$0078, $D888
        lda     L0CA9
        cmp     #$01
        beq     L0C5B
        add16   $D888, #$0078, $D888
L0C5B:  asl     L0CA9
        asl     L0CA9
        txa
        sec
        sbc     L0CA9
        asl     a
        asl     a
        asl     a
        clc
        adc     #$2B
        sta     $D88A
        lda     #$00
        sta     $D88B
        add16   $D888, #$0077, $D88C
        add16   $D88A, #$0007, $D88E
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D888
        rts

L0CA9:  .byte   0
L0CAA:  lda     $D887
        bmi     L0CB7
        jsr     L0C20
        lda     #$FF
        sta     $D887
L0CB7:  rts

        lda     $D887
        bpl     L0CC1
        lda     #$00
        beq     L0CCE
L0CC1:  clc
        adc     #$04
        cmp     $D890
        bcs     L0CD4
        pha
        jsr     L0CAA
        pla
L0CCE:  sta     $D887
        jsr     L0C20
L0CD4:  return  #$FF

        lda     $D887
        bpl     L0CE6
        lda     $D890
        lsr     a
        lsr     a
        asl     a
        asl     a
        jmp     L0CF0

L0CE6:  sec
        sbc     #$04
        bmi     L0CF6
        pha
        jsr     L0CAA
        pla
L0CF0:  sta     $D887
        jsr     L0C20
L0CF6:  return  #$FF

        lda     $D887
        clc
        adc     #$01
L0D00           := * + 1
        cmp     $D890
        bcc     L0D06
        lda     #$00
L0D06:  pha
        jsr     L0CAA
        pla
        sta     $D887
        jsr     L0C20
        return  #$FF

        lda     $D887
        bmi     L0D1E
        sec
        sbc     #$01
        bpl     L0D23
L0D1E:  ldx     $D890
        dex
        txa
L0D23:  pha
        jsr     L0CAA
        pla
        sta     $D887
        jsr     L0C20
        return  #$FF

L0D31:  ldx     $BF31
        inx
        stx     $D890
        lda     #$00
        sta     L0D8C
L0D3D:  lda     L0D8C
        cmp     $D890
        bne     L0D46
        rts

L0D46:  cmp     #$08
        bcc     L0D50
        ldx     #$01
        lda     #$40
        bne     L0D5A
L0D50:  cmp     #$04
        bcc     L0D60
        ldx     #$00
        lda     #$A0
        bne     L0D5A
L0D5A:  stax    $D6C3
L0D60:  lda     L0D8C
        asl     a
        tay
        lda     $DB01,y
        tax
        lda     $DB00,y
        pha
        lda     L0D8C
        lsr     a
        lsr     a
        asl     a
        asl     a
        sta     L0D8D
        lda     L0D8C
        sec
        sbc     L0D8D
        tay
        iny
        iny
        iny
        pla
        jsr     LB590
        inc     L0D8C
        jmp     L0D3D

L0D8C:  .byte   0
L0D8D:  .byte   0

        PAD_TO $E00

L0E00:  php
        sei
        jsr     L0E3A
        plp
        cmp     #$00
        bne     L0E0C
        clc
        rts

L0E0C:  cmp     #$02
        bne     L0E15
        lda     #$2B
        jmp     L0E21

L0E15:  cmp     #$01
        bne     L0E1E
        lda     #$27
        jmp     L0E21

L0E1E:  clc
        adc     #$30
L0E21:  sec
        rts

L0E23:  asl     a
        asl     L1224
        sta     L1236
        txa
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     L1236
        jsr     L0FC6
        lsr     L1224
        rts

L0E3A:  tax
        and     #$70
        sta     L1223
        txa
        ldx     L1223
        rol     a
        lda     #$00
        rol     a
        bne     L0E50
        lda     $C08A,x
        jmp     L0E53

L0E50:  lda     LCBANK1,x
L0E53:  lda     $C089,x
        lda     #$D7
        sta     $DA
        lda     #$50
        sta     L1224
        lda     #$00
        jsr     L0E23
L0E64:  lda     $DA
        beq     L0E6E
        jsr     L113A
        jmp     L0E64

L0E6E:  lda     #$01
        sta     $D3
        lda     #$AA
        sta     $D0
        lda     L1220
        clc
        adc     #$02
        sta     $D4
        lda     #$00
        sta     $D1
L0E82:  lda     $D1
        ldx     L1223
        jsr     L0E23
        ldx     L1223
        lda     $C08D,x
        lda     $C08E,x
        tay
        lda     $C08E,x
        lda     $C08C,x
        tya
        bpl     L0EA2
        lda     #$02
        jmp     L0EF9

L0EA2:  jsr     L1163
        bcc     L0EB5
        lda     #$01
        ldy     $D4
        cpy     L121F
        bcs     L0EB2
        lda     #$04
L0EB2:  jmp     L0EF9

L0EB5:  ldy     $D4
        cpy     L121F
        bcs     L0EC1
        lda     #$04
        jmp     L0EF9

L0EC1:  cpy     L1220
        bcc     L0ECB
        lda     #$03
        jmp     L0EF9

L0ECB:  lda     L1222
        sta     L1225
L0ED1:  dec     L1225
        bne     L0EDB
        lda     #$01
        jmp     L0EF9

L0EDB:  ldx     L1223
        jsr     L0F6A
        bcs     L0ED1
        lda     $D8
        bne     L0ED1
        ldx     L1223
        jsr     L0F07
        bcs     L0ED1
        inc     $D1
        lda     $D1
        cmp     #$23
        bcc     L0E82
        lda     #$00
L0EF9:  pha
        ldx     L1223
        lda     $C088,x
        lda     #$00
        jsr     L0E23
        pla
        rts

L0F07:  ldy     #$20
L0F09:  dey
        beq     L0F68
L0F0C:  lda     $C08C,x
        bpl     L0F0C
L0F11:  eor     #$D5
        bne     L0F09
        nop
L0F16:  lda     $C08C,x
        bpl     L0F16
        cmp     #$AA
        bne     L0F11
        ldy     #$56
L0F21:  lda     $C08C,x
        bpl     L0F21
        cmp     #$AD
        bne     L0F11
        lda     #$00
L0F2C:  dey
        sty     $D5
L0F2F:  lda     $C08C,x
        bpl     L0F2F
        cmp     #$96
        bne     L0F68
        ldy     $D5
        bne     L0F2C
L0F3C:  sty     $D5
L0F3E:  lda     $C08C,x
        bpl     L0F3E
        cmp     #$96
        bne     L0F68
        ldy     $D5
        iny
        bne     L0F3C
L0F4C:  lda     $C08C,x
        bpl     L0F4C
        cmp     #$96
        bne     L0F68
L0F55:  lda     $C08C,x
        bpl     L0F55
        cmp     #$DE
        bne     L0F68
        nop
L0F5F:  lda     $C08C,x
        bpl     L0F5F
        cmp     #$AA
        beq     L0FC4
L0F68:  sec
        rts

L0F6A:  ldy     #$FC
        sty     $DC
L0F6E:  iny
        bne     L0F75
        inc     $DC
        beq     L0F68
L0F75:  lda     $C08C,x
        bpl     L0F75
L0F7A:  cmp     #$D5
        bne     L0F6E
        nop
L0F7F:  lda     $C08C,x
        bpl     L0F7F
        cmp     #$AA
        bne     L0F7A
        ldy     #$03
L0F8A:  lda     $C08C,x
        bpl     L0F8A
        cmp     #$96
        bne     L0F7A
        lda     #$00
L0F95:  sta     $DB
L0F97:  lda     $C08C,x
        bpl     L0F97
        rol     a
        sta     $DD
L0F9F:  lda     $C08C,x
        bpl     L0F9F
        and     $DD
        sta     $D7,y
        eor     $DB
        dey
        bpl     L0F95
        tay
        bne     L0F68
L0FB1:  lda     $C08C,x
        bpl     L0FB1
        cmp     #$DE
        bne     L0F68
        nop
L0FBB:  lda     $C08C,x
        bpl     L0FBB
        cmp     #$AA
        bne     L0F68
L0FC4:  clc
        rts

L0FC6:  stx     L1237
        sta     L1236
        cmp     L1224
        beq     L102D
        lda     #$00
        sta     L1238
L0FD6:  lda     L1224
        sta     L1239
        sec
        sbc     L1236
        beq     L1019
        bcs     L0FEB
        eor     #$FF
        inc     L1224
        bcc     L0FF0
L0FEB:  adc     #$FE
        dec     L1224
L0FF0:  cmp     L1238
        bcc     L0FF8
        lda     L1238
L0FF8:  cmp     #$0C
        bcs     L0FFD
        tay
L0FFD:  sec
        jsr     L101D
        lda     L114B,y
        jsr     L113A
        lda     L1239
        clc
        jsr     L1020
        lda     L1157,y
        jsr     L113A
        inc     L1238
        bne     L0FD6
L1019:  jsr     L113A
        clc
L101D:  lda     L1224
L1020:  and     #$03
        rol     a
        ora     L1237
        tax
        lda     $C080,x
        ldx     L1237
L102D:  rts

L102E:  jsr     L120E
        lda     $C08D,x
        lda     $C08E,x
        lda     #$FF
        sta     $C08F,x
        cmp     $C08C,x
        pha
        pla
        nop
        ldy     #$04
L1044:  pha
        pla
        jsr     L10A5
        dey
        bne     L1044
        lda     #$D5
        jsr     L10A4
        lda     #$AA
        jsr     L10A4
        lda     #$AD
        jsr     L10A4
        ldy     #$56
        nop
        nop
        nop
        bne     L1065
L1062:  jsr     L120E
L1065:  nop
        nop
        lda     #$96
        sta     $C08D,x
        cmp     $C08C,x
        dey
        bne     L1062
        bit     $00
        nop
L1075:  jsr     L120E
        lda     #$96
        sta     $C08D,x
        cmp     $C08C,x
        lda     #$96
        nop
        iny
        bne     L1075
        jsr     L10A4
        lda     #$DE
        jsr     L10A4
        lda     #$AA
        jsr     L10A4
        lda     #$EB
        jsr     L10A4
        lda     #$FF
        jsr     L10A4
        lda     $C08E,x
        lda     $C08C,x
        rts

L10A4:  nop
L10A5:  pha
        pla
        sta     $C08D,x
        cmp     $C08C,x
        rts

L10AE:  sec
        lda     $C08D,x
        lda     $C08E,x
        bmi     L1115
        lda     #$FF
        sta     $C08F,x
        cmp     $C08C,x
        pha
        pla
L10C1:  jsr     L111B
        jsr     L111B
        sta     $C08D,x
        cmp     $C08C,x
        nop
        dey
        bne     L10C1
        lda     #$D5
        jsr     L112D
        lda     #$AA
        jsr     L112D
        lda     #$96
        jsr     L112D
        lda     $D3
        jsr     L111C
        lda     $D1
        jsr     L111C
        lda     $D2
        jsr     L111C
        lda     $D3
        eor     $D1
        eor     $D2
        pha
        lsr     a
        ora     $D0
        sta     $C08D,x
        lda     $C08C,x
        pla
        ora     #$AA
        jsr     L112C
        lda     #$DE
        jsr     L112D
        lda     #$AA
        jsr     L112D
        lda     #$EB
        jsr     L112D
        clc
L1115:  lda     $C08E,x
        lda     $C08C,x
L111B:  rts

L111C:  pha
        lsr     a
        ora     $D0
        sta     $C08D,x
        cmp     $C08C,x
        pla
        nop
        nop
        nop
        ora     #$AA
L112C:  nop
L112D:  nop
        pha
        pla
        sta     $C08D,x
        cmp     $C08C,x
        rts

        .byte   0
        .byte   0
        .byte   0
L113A:  ldx     #$11
L113C:  dex
        bne     L113C
        inc     $D9
        bne     L1145
        inc     $DA
L1145:  sec
        sbc     #$01
        bne     L113A
        rts

L114B:  ora     ($30,x)
        plp
        bit     $20
        asl     $1C1D,x
        .byte   $1C
        .byte   $1C
        .byte   $1C
        .byte   $1C
L1157:  bvs     L1185
        rol     $22
        .byte   $1F
        asl     $1C1D,x
        .byte   $1C
        .byte   $1C
        .byte   $1C
        .byte   $1C
L1163:  lda     L1221
        sta     $D6
L1168:  ldy     #$80
        lda     #$00
        sta     $D2
        jmp     L1173

L1171:  ldy     $D4
L1173:  ldx     L1223
        jsr     L10AE
        bcc     L117E
        jmp     L120E

L117E:  ldx     L1223
        jsr     L102E
        .byte   $E6
L1185:  .byte   $D2
        lda     $D2
        cmp     #$10
        bcc     L1171
        ldy     #$0F
        sty     $D2
        lda     L1222
        sta     L1225
L1196:  sta     L1226,y
        dey
        bpl     L1196
        lda     $D4
        sec
        sbc     #$05
        tay
L11A2:  jsr     L120E
        jsr     L120E
        pha
        pla
        nop
        nop
        dey
        bne     L11A2
        ldx     L1223
        jsr     L0F6A
        bcs     L11F3
        lda     $D8
        beq     L11CE
        dec     $D4
        lda     $D4
        cmp     L121F
        bcs     L11F3
        sec
        rts

L11C6:  ldx     L1223
        jsr     L0F6A
        bcs     L11E8
L11CE:  ldx     L1223
        jsr     L0F07
        bcs     L11E8
        ldy     $D8
        lda     L1226,y
        bmi     L11E8
        lda     #$FF
        sta     L1226,y
        dec     $D2
        bpl     L11C6
        clc
        rts

L11E8:  dec     L1225
        bne     L11C6
        dec     $D6
        bne     L11F3
        sec
        rts

L11F3:  lda     L1222
        asl     a
        sta     L1225
L11FA:  ldx     L1223
        jsr     L0F6A
        bcs     L1208
        lda     $D8
        cmp     #$0F
        beq     L120F
L1208:  dec     L1225
        bne     L11FA
        sec
L120E:  rts

L120F:  ldx     #$D6
L1211:  jsr     L120E
        jsr     L120E
        bit     $00
        dex
        bne     L1211
        jmp     L1168

L121F:  .byte   $0E
L1220:  .byte   $1B
L1221:  .byte   $03
L1222:  .byte   $10
L1223:  .byte   $00
L1224:  .byte   $00
L1225:  .byte   $00
L1226:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L1236:  .byte   $00
L1237:  .byte   $00
L1238:  .byte   $00
L1239:  .byte   $00,$02
L123B:  .byte   $00,$00,$1C,$03
L123F:  .byte   $00,$00,$1C
L1242:  .byte   $00
L1243:  .byte   $00,$03
L1245:  .byte   $00
L1246:  .byte   $00
L1247:  .byte   $15
L1248:  .byte   $00
L1249:  .byte   $00
L124A:  .byte   $00
L124B:  sty     L125F
        stax    L1260
        php
        sei
        sta     ALTZPOFF
        lda     $C082
        jsr     MLI
L125F:  .byte   0
L1260:  .byte   0
L1261:  .byte   0
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        plp
        txa
        rts

L126F:  sta     L12C0
        and     #$0F
        beq     L12A6
        ldx     #$11
        lda     L12C0
        and     #$80
        beq     L1281
        ldx     #$21
L1281:  stx     L1294
        lda     L12C0
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     L1294
        sta     L1294
L1294           := * + 1
        lda     MLI
        sta     $07
        lda     #$00
        sta     L0006
        ldy     #$FF
        lda     (L0006),y
        beq     L12A6
        cmp     #$FF
        bne     L12AD
L12A6:  lda     L12C0
        jsr     L0E00
        rts

L12AD:  ldy     #$FF
        lda     (L0006),y
        sta     L0006
        lda     #$03
        sta     $42
        lda     L12C0
        sta     $43
        jmp     (L0006)

        rts

L12C0:  .byte   0
L12C1:  sta     L1306
        and     #$0F
        beq     L1303
        ldx     #$11
        lda     L1306
        and     #$80
        beq     L12D3
        ldx     #$21
L12D3:  stx     L12E6
        lda     L1306
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     L12E6
        sta     L12E6
L12E6           := * + 1
        lda     MLI
        sta     $07
        lda     #$00
        sta     L0006
        ldy     #$FF
        lda     (L0006),y
        beq     L1303
        cmp     #$FF
        beq     L1303
        ldy     #$FE
        lda     (L0006),y
        and     #$08
        bne     L1303
        return  #$FF

L1303:  return  #$00

L1306:  .byte   0
L1307:  sta     L124A
        and     #$F0
        sta     L1245
        stx     L0006
        sty     $07
        ldy     #$01
        lda     (L0006),y
        and     #$7F
        cmp     #$2F
        bne     L132C
        dey
        lda     (L0006),y
        sec
        sbc     #$01
        iny
        sta     (L0006),y
        inc     L0006
        bne     L132C
        inc     $07
L132C:  ldy     #$00
        lda     (L0006),y
        tay
L1331:  lda     (L0006),y
        and     #$7F
        sta     L14E5,y
        dey
        bpl     L1331
        lda     L124A
        and     #$0F
        beq     L1394
        ldx     #$11
        lda     L124A
        and     #$80
        beq     L134D
        ldx     #$21
L134D:  stx     L1360
        lda     L124A
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     L1360
        sta     L1360
L1360           := * + 1
        lda     MLI
        sta     $07
        lda     #$00
        sta     L0006
        ldy     #$FF
        lda     (L0006),y
        beq     L1394
        cmp     #$FF
        beq     L1394
        ldy     #$FF
        lda     (L0006),y
        sta     L0006
        lda     #$00
        sta     $42
        lda     L124A
        and     #$F0
        sta     $43
        lda     #$00
        sta     $46
        sta     $47
        jsr     L1391
        bcc     L1398
        jmp     L1483

L1391:  jmp     (L0006)

L1394:  ldx     #$18
        ldy     #$01
L1398:  stx     L14E3
        sty     L14E4
        copy16  #$1500, L1246
        lda     #$00
        sta     L1248
        sta     L1249
        yax_call L124B, $81, $1244
        beq     L13BE
        jmp     L14B8

L13BE:  inc     L1248
        inc     L1247
        inc     L1247
        jsr     L14BA
        copy16  #$1A00, L1246
        lda     #$03
        sta     L1A02
        ldy     L14E5
        tya
        ora     #$F0
        sta     L1A04
L13E2:  lda     L14E5,y
        sta     L1A04,y
        dey
        bne     L13E2
        ldy     #$08
L13ED:  lda     L14DC,y
        sta     L1A22,y
        dey
        bpl     L13ED
        jsr     L14BA
        lda     #$02
        sta     L1A00
        lda     #$04
        sta     L1A02
        jsr     L14BA
        lda     #$03
        sta     L1A00
        lda     #$05
        sta     L1A02
        jsr     L14BA
        lda     #$04
        sta     L1A00
        jsr     L14BA
        lsr16    L14E3
        lsr16    L14E3
        lsr16    L14E3
        lda     L14E3
        bne     L1435
        dec     L14E4
L1435:  dec     L14E3
L1438:  jsr     L1485
        lda     L1249
        bne     L146A
        lda     L1248
        cmp     #$06
        bne     L146A
        lda     #$01
        sta     L1A00
        lda     L14E4
        cmp     #$02
        bcc     L146A
        lda     #$00
        sta     L1A00
        lda     L14E4
        lsr     a
        tax
        lda     #$FF
        dex
        beq     L1467
L1462:  clc
        rol     a
        dex
        bne     L1462
L1467:  sta     L1A01
L146A:  jsr     L14BA
        dec     L14E4
        dec     L14E4
        lda     L14E4
        beq     L147D
        bmi     L147D
        jmp     L1438

L147D:  lda     #$00
        sta     $08
        clc
        rts

L1483:  sec
        rts

L1485:  ldy     L14E4
        beq     L148E
        ldy     #$FF
        bne     L1491
L148E:  ldy     L14E3
L1491:  lda     #$FF
L1493:  sta     L1A00,y
        dey
        bne     L1493
        sta     L1A00
        ldy     L14E4
        beq     L14B5
        cpy     #$02
        bcc     L14A9
        ldy     #$FF
        bne     L14AC
L14A9:  ldy     L14E3
L14AC:  sta     $1B00,y
        dey
        bne     L14AC
        sta     $1B00
L14B5:  rts

L14B6:  pla
        pla
L14B8:  sec
        rts

L14BA:  yax_call L124B, $81, $1244
        bne     L14B6
        jsr     L14CC
        inc     L1248
        rts

L14CC:  ldy     #$00
        tya
L14CF:  sta     L1A00,y
        dey
        bne     L14CF
L14D5:  sta     $1B00,y
        dey
        bne     L14D5
        rts

L14DC:  .byte   $C3,$27,$0D,$00,$00,$06,$00
L14E3:  .byte   $18
L14E4:  .byte   $01
L14E5:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$01
        sec
        bcs     L1507
        jmp     LA132

L1507:  stx     $43
        cmp     #$03
        php
        txa
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$C0
        sta     $49
        ldy     #$FF
        sty     $48
        plp
        iny
        lda     ($48),y
        bne     L155B
        bcs     L1531
        lda     #$03
        sta     L0800
        inc     $3D
        lda     $49
        pha
        lda     #$5B
        pha
        rts

L1531:  sta     $40
        sta     $48
        ldy     #$63
L1537:  lda     ($48),y
        sta     L0994,y
        iny
        cpy     #$EB
        bne     L1537
        ldx     #$06
L1543:  ldy     L091D,x
        lda     L0924,x
        sta     L09F2,y
        lda     L092B,x
        sta     L0A7F,x
        dex
        bpl     L1543
        lda     #$09
        sta     $49
        lda     #$86
L155B:  ldy     #$00
        cmp     #$F9
        bcs     L1590
        sta     $48
        sty     $60
        sty     $4A
        sty     $4C
        sty     $4E
        sty     $47
        iny
        sty     $42
        iny
        sty     $46
        lda     #$0C
        sta     $61
        sta     $4B
L1579:  jsr     L0912
        bcs     L15E6
        inc     $61
        inc     $61
        inc     $46
        lda     $46
        cmp     #$06
        bcc     L1579
        lda     L0C00
        ora     L0C01
L1590:  bne     L15FF
        lda     #$04
        bne     L1598
L1596:  lda     $4A
L1598:  clc
        adc     L0C23
        tay
        bcc     L15AC
        inc     $4B
        lda     $4B
        lsr     a
        bcs     L15AC
        cmp     #$0A
        beq     L15FF
        ldy     #$04
L15AC:  sty     $4A
        lda     L0902
        and     #$0F
        tay
L15B4:  lda     ($4A),y
        cmp     L0902,y
        bne     L1596
        dey
        bpl     L15B4
        and     #$F0
        cmp     #$20
        bne     L15FF
        ldy     #$10
        lda     ($4A),y
        cmp     #$FF
        bne     L15FF
        iny
        lda     ($4A),y
        sta     $46
        iny
        lda     ($4A),y
        sta     $47
        lda     #$00
        sta     $4A
        ldy     #$1E
        sty     $4B
        sty     $61
        iny
        sty     $4D
L15E3:  jsr     L0912
L15E6:  bcs     L15FF
        inc     $61
        inc     $61
        ldy     $4E
        inc     $4E
        lda     ($4A),y
        sta     $46
        lda     ($4C),y
        sta     $47
        ora     ($4A),y
        bne     L15E3
        jmp     L2000

L15FF:  jmp     L093F

        .byte   $26
        .byte   "PRODOS         "
        .byte   $A5,$60,$85,$44,$A5,$61,$85,$45
        .byte   $6C,$48,$00,$08,$1E,$24,$3F,$45
        .byte   $47,$76,$F4,$D7,$D1,$B6,$4B,$B4
        .byte   $AC,$A6,$2B,$18,$60,$4C,$BC,$09
        .byte   $A9,$9F
        pha
        lda     #$FF
        pha
        addr_jump LF479, $0001

        jsr     HOME
        ldy     #$1C
L1644:  lda     L0950,y
        sta     $05AE,y
        dey
        bpl     L1644
        jmp     L094D

        .byte   $AA,$AA,$AA,$A0,$D5,$CE,$C1,$C2
        .byte   $CC,$C5,$A0,$D4,$CF,$A0,$CC,$CF
        .byte   $C1,$C4,$A0,$D0,$D2,$CF,$C4,$CF
        .byte   $D3,$A0,$AA,$AA,$AA,$A5,$53,$29
        .byte   $03
        rol     a
        ora     $2B
        tax
        lda     $C080,x
        lda     #$2C
L167A:  ldx     #$11
L167C:  dex
        bne     L167C
        sbc     #$01
        bne     L167A
        ldx     $2B
        rts

        lda     $46
        and     #$07
        cmp     #$04
        and     #$03
        php
        asl     a
        plp
        rol     a
        sta     $3D
        lda     $47
        lsr     a
        lda     $46
        ror     a
        lsr     a
        lsr     a
        sta     $41
        asl     a
        sta     $51
        lda     $45
        sta     $27
        ldx     $2B
        lda     $C089,x
        jsr     L09BC
        inc     $27
        inc     $3D
        inc     $3D
        bcs     L16B8
        jsr     L09BC
L16B8:  ldy     $C088,x
L16BB:  rts

        lda     $40
        asl     a
        sta     $53
        lda     #$00
        sta     $54
L16C5:  lda     $53
        sta     $50
        sec
        sbc     $51
        beq     L16E2
        bcs     L16D4
        inc     $53
        bcc     L16D6
L16D4:  dec     $53
L16D6:  sec
        jsr     L096D
        lda     $50
        clc
        jsr     L096F
        bne     L16C5
L16E2:  ldy     #$7F
        sty     $52
        php
L16E7:  plp
        sec
        dec     $52
        beq     L16BB
        clc
        php
        dey
        beq     L16E7
        .byte   $BD,$8C,$C0,$10,$FB,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$4C,$6E
        .byte   $A0
        .byte   "SOS BOOT  1.1 "
        .byte   $0A
        .byte   "SOS.KERNEL     "
        .byte   "SOS KRNL"
        .byte   "I/O ERROR"
        .byte   $08,$00
        .byte   "FILE 'SOS.KERNEL' NOT FOUND"
        .byte   $25,$00
        .byte   "INVALID KERNEL FILE:"
        .byte   $00,$00,$0C,$00,$1E
        .byte   $0E,$1E,$04,$A4,$78,$D8,$A9
        .byte   $77
        sta     $FFDF
        ldx     #$FB
        txs
        bit     $C010
        lda     #$40
        sta     $FFCA
        lda     #$07
        sta     $FFEF
        ldx     #$00
L1787:  dec     $FFEF
        stx     L2000
        lda     L2000
        bne     L1787
        copy16  #$0001, $E0
        copy16  #$A200, $85
        jsr     LA1BE
        inc     $E0
        lda     #$00
        sta     $E6
L17AB:  inc     $86
        inc     $86
        inc     $E6
        jsr     LA1BE
        ldy     #$02
        lda     ($85),y
        sta     $E0
        iny
        lda     ($85),y
        sta     $E1
        bne     L17AB
        lda     $E0
        bne     L17AB
        lda     $A06C
        sta     $E2
        lda     $A06D
        sta     $E3
L17CF:  clc
        lda     $E3
        adc     #$02
        sta     $E5
        sec
        lda     $E2
        sbc     $A423
        sta     $E4
        lda     $E5
        sbc     #$00
        sta     $E5
L17E4:  ldy     #$00
        lda     ($E2),y
        and     #$0F
        cmp     $A011
        bne     L1810
        tay
L17F0:  lda     ($E2),y
        cmp     $A011,y
        bne     L1810
        dey
        bne     L17F0
        ldy     #$00
        lda     ($E2),y
        and     #$F0
        cmp     #$20
        beq     L1842
        cmp     #$F0
        beq     L1810
        ldx     $A064
        ldy     #$13
        jmp     LA1D4

L1810:  clc
        lda     $E2
        adc     $A423
        sta     $E2
        lda     $E3
        adc     #$00
        sta     $E3
        lda     $E4
        cmp     $E2
        lda     $E5
        sbc     $E3
        bcs     L17E4
        clc
        lda     $E4
        adc     $A423
        sta     $E2
        lda     $E5
        adc     #$00
        sta     $E3
        dec     $E6
        bne     L17CF
        ldx     $A04F
        ldy     #$1B
        jmp     LA1D4

L1842:  ldy     #$11
        lda     ($E2),y
        sta     $E0
        iny
        lda     ($E2),y
        sta     $E1
        lda     $A066
        sta     $85
        lda     $A067
        sta     $86
        jsr     LA1BE
        lda     $A068
        sta     $85
        lda     $A069
        sta     $86
        lda     L0C00
        sta     $E0
        lda     L0D00
        sta     $E1
        jsr     LA1BE
        ldx     #$07
L1873:  lda     $1E00,x
        cmp     $A021,x
        beq     L1883
        ldx     $A064
        ldy     #$13
        jmp     LA1D4

L1883:  dex
        bpl     L1873
        lda     #$00
        sta     $E7
        inc     $E7
        inc     $86
        inc     $86
        ldx     $E7
        lda     L0C00,x
        sta     $E0
        lda     L0D00,x
        sta     $E1
        lda     $E0
        bne     L18A4
        lda     $E1
        beq     L18AA
L18A4:  jsr     LA1BE
        jmp     LA18A

L18AA:  clc
        lda     $A06A
        adc     $1E08
        sta     L00E8
        lda     $A06B
        adc     $1E09
        sta     $E9
        jmp     (L00E8)

        lda     #$01
        sta     $87
        lda     $E0
        ldx     $E1
        jsr     LF479
        bcs     L18CC
        rts

L18CC:  ldx     $A032
        ldy     #$09
        jmp     LA1D4

        sty     $E7
        sec
        lda     #$28
        sbc     $E7
        lsr     a
        clc
        adc     $E7
        tay
L18E0:  lda     $A029,x
        sta     $05A7,y
        dex
        dey
        dec     $E7
        bne     L18E0
        lda     $C040
        jmp     LA1EF

        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L1900:  stx     $07
        sta     L0006
        ldy     #$00
        lda     (L0006),y
        tay
L1909:  lda     (L0006),y
        cmp     #$61
        bcc     L1917
        cmp     #$7B
        bcs     L1917
        and     #$DF
        sta     (L0006),y
L1917:  dey
        bpl     L1909
        rts

L191B:  sta     ALTZPOFF
        lda     $C082
        jsr     BELL1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

L192E:  sta     L123F
        lda     #$00
        sta     L1242
        sta     L1243
        yax_call L124B, $80, $123E
        bne     L1959
        lda     $1C01
        cmp     #$E0
        beq     L194E
        jmp     L1986

L194E:  lda     $1C02
        cmp     #$70
        beq     L197E
        cmp     #$60
        beq     L197E
L1959:  lda     L123F
        jsr     L19B7
        ldx     $D8D5
        sta     $D8B8,x
        lda     L123F
        jsr     L19C1
        ldx     $D8D6
        sta     $D8B8,x
        ldx     $D8B8
L1974:  lda     $D8B8,x
        sta     $D909,x
        dex
        bpl     L1974
        rts

L197E:  addr_call L19C8, $D909
        rts

L1986:  cmp     #$A5
        bne     L1959
        lda     $1C02
        cmp     #$27
        bne     L1959
        lda     L123F
        jsr     L19B7
        ldx     $D8B6
        sta     $D891,x
        lda     L123F
        jsr     L19C1
        ldx     $D8B7
        sta     $D891,x
        ldx     $D891
L19AC:  lda     $D891,x
        sta     $D909,x
        dex
        bpl     L19AC
        rts

        .byte   0
L19B7:  and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #$30
        rts

L19C1:  and     #$80
        asl     a
        rol     a
        adc     #$31
        rts

L19C8:  copy16  #$0002, L1242
        yax_call L124B, $80, $123E
        beq     L19F7
        copy16  #$2004, $D909
        copy16  #$203A, $D90B
        lda     #$3F
        sta     $D90C
        rts

L19F7:  lda     $1C06
        tax
L19FB:  lda     $1C06,x
L1A00           := * + 2
        sta     $D909,x
L1A01:  dex
L1A02:  bpl     L19FB
L1A04:  inc     $D909
        ldx     $D909
        lda     #$3A
        sta     $D909,x
        inc     $D909
        ldx     $D909
        lda     #$20
        sta     $D909,x
        inc     $D909
        ldx     $D909
        lda     #$3F
L1A22:  sta     $D909,x
        addr_call LB781, $D909
        rts

L1A2D:  sta     L123B
        yax_call L124B, $C5, $123A
        bne     L1A6D
        lda     $1C00
        and     #$0F
        beq     L1A6D
        sta     $1C00
        tax
L1A46:  lda     $1C00,x
        sta     $D909,x
        dex
        bpl     L1A46
        inc     $D909
        ldx     $D909
        lda     #$20
        sta     $D909,x
        inc     $D909
        ldx     $D909
        lda     #$3F
        sta     $D909,x
        addr_call LB781, $D909
        rts

L1A6D:  lda     L123B
        jsr     L192E
        rts

        PAD_TO $1C00
