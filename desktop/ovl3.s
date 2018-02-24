
        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ==================================================
;;; Overlay for Disk Copy
;;; ==================================================

        .org $9000

L4015           := $4015
L4030           := $4030
L4036           := $4036
L403F           := $403F
L5000           := $5000
L6365           := $6365
LA500           := $A500
LB3E7           := $B3E7
LB403           := $B403
LB445           := $B445
LB708           := $B708
LB7B9           := $B7B9

        sta     L938E
        ldx     #$FF
        stx     L938F
        cmp     #$01
        beq     L903C
        jmp     L9105

L900F:  pha
        lda     L938F
        bpl     L9017
L9015:  pla
L9016:  rts

L9017:  lda     $0C00
        clc
        adc     $0C01
        sta     $D343
        lda     #$00
        sta     $D344
        jsr     L9DED
        cmp     #$80
        bne     L9015
        jsr     L4015
        lda     #$06
        jsr     L9C09
        bne     L9015
        jsr     L9C26
        pla
        rts

L903C:  ldx     #$01
        lda     $DB1C
        sta     L904B
        lda     $DB1D
        sta     L904C
        .byte   $AD
L904B:  .byte   $34
L904C:  .byte   $12
        cmp     #$0D
        bcc     L9052
        inx
L9052:  lda     #$00
        sta     $D402
        sta     $D443
        ldy     #$03
        lda     #$02
        jsr     L5000
        pha
        txa
        pha
        tya
        pha
        lda     #$07
        jsr     L403F
        jsr     L4015
        pla
        tay
        pla
        tax
        pla
        bne     L900F
        inc     L938F
        stx     L9103
        sty     L9104
        lda     #$00
L9080:  dey
        beq     L9088
        sec
        ror     a
        jmp     L9080

L9088:  sta     L9104
        jsr     L9CBA
        bpl     L9093
        jmp     L9016

L9093:  lda     $0C00
        sta     L938B
        lda     $0C01
        sta     L938C
        lda     L9103
        cmp     #$01
        bne     L90D3
        lda     L938B
        cmp     #$08
        beq     L90F4
        ldy     L9104
        lda     L938B
        jsr     L9A0A
        inc     $0C00
        lda     $DB1C
        sta     L90C6
        lda     $DB1D
        sta     L90C7
        .byte   $EE
L90C6:  .byte   $34
L90C7:  .byte   $12
        jsr     L9CEA
        bpl     L90D0
        jmp     L9016

L90D0:  jmp     L900F

L90D3:  lda     L938C
        cmp     #$10
        beq     L90FF
        ldy     L9104
        lda     L938C
        clc
        adc     #$08
        jsr     L9A61
        inc     $0C01
        jsr     L9CEA
        bpl     L90F1
        jmp     L9016

L90F1:  jmp     L900F

L90F4:  lda     #$01
L90F6:  jsr     L9C09
        dec     L938F
        jmp     L9016

L90FF:  lda     #$02
        bne     L90F6
L9103:  brk
L9104:  brk
L9105:  lda     #$00
        sta     L938B
        sta     L938C
        lda     #$FF
        sta     L938D
        jsr     L9390
        jsr     L9D22
        bpl     L911D
        jmp     L936E

L911D:  jsr     L99B3
L9120:  jsr     L9646
        bmi     L9120
        beq     L912A
        jmp     L933F

L912A:  lda     L938D
        bmi     L9120
        lda     L938E
        cmp     #$02
        bne     L9139
        jmp     L9174

L9139:  cmp     #$03
        bne     L913F
        beq     L9146
L913F:  cmp     #$04
        bne     L9120
        jmp     L9282

L9146:  lda     L938D
        jsr     L979D
        jsr     LB3E7
        lda     L938D
        jsr     L9A97
        beq     L915D
        jsr     LB403
        jmp     L933F

L915D:  jsr     LB403
        lda     #$FF
        sta     L938D
        jsr     L99F5
        jsr     L9D28
        jsr     L99B3
        inc     L938F
        jmp     L9120

L9174:  lda     L938D
        jsr     L979D
        jsr     L936E
        lda     L938D
        jsr     L9BD5
        sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        tay
L918C:  lda     ($06),y
        sta     $D443,y
        dey
        bpl     L918C
        ldy     #$0F
        lda     ($06),y
        sta     L9281
        lda     L938D
        jsr     L9BE2
        sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        tay
L91AA:  lda     ($06),y
        sta     $D402,y
        dey
        bpl     L91AA
        ldx     #$01
        lda     L938D
        cmp     #$09
        bcc     L91BC
        inx
L91BC:  clc
        lda     L9281
        rol     a
        rol     a
        adc     #$01
        tay
        lda     #$02
        jsr     L5000
        pha
        txa
        pha
        tya
        pha
        lda     #$07
        jsr     L403F
        jsr     L4015
        pla
        tay
        pla
        tax
        pla
        beq     L91DF
        rts

L91DF:  inc     L938F
        stx     L9103
        sty     L9104
        lda     #$00
L91EA:  dey
        beq     L91F2
        sec
        ror     a
        jmp     L91EA

L91F2:  sta     L9104
        jsr     L9CBA
        bpl     L91FD
        jmp     L936E

L91FD:  lda     L938D
        cmp     #$09
        bcc     L923C
        lda     L9103
        cmp     #$02
        beq     L926A
        lda     L938B
        cmp     #$08
        bne     L9215
        jmp     L90F4

L9215:  lda     L938D
        jsr     L9A97
        beq     L9220
        jmp     L936E

L9220:  ldx     L938B
        inc     L938B
        inc     $0C00
        lda     $DB1C
        sta     L9236
        lda     $DB1D
        sta     L9237
        .byte   $EE
L9236:  .byte   $34
L9237:  .byte   $12
        txa
        jmp     L926D

L923C:  lda     L9103
        cmp     #$01
        beq     L926A
        lda     L938C
        cmp     #$10
        bne     L924D
        jmp     L9105

L924D:  lda     L938D
        jsr     L9A97
        beq     L9258
        jmp     L936E

L9258:  ldx     L938C
        inc     L938C
        inc     $0C01
        lda     L938C
        clc
        adc     #$07
        jmp     L926D

L926A:  lda     L938D
L926D:  ldy     L9104
        jsr     L9A0A
        jsr     L9CEA
        beq     L927B
        jmp     L936E

L927B:  jsr     LB403
        jmp     L900F

L9281:  brk
L9282:  lda     L938D
        jsr     L979D
        jsr     LB3E7
        lda     L938D
        jsr     L9BD5
        sta     $06
        stx     $07
        ldy     #$0F
        lda     ($06),y
        cmp     #$C0
        beq     L92F0
        sta     L938A
        jsr     L9DED
        beq     L92F0
        lda     L938A
        beq     L92CE
        lda     L938D
        jsr     L9E61
        beq     L92D6
        lda     L938D
        jsr     L9BE2
        sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        tay
L92C1:  lda     ($06),y
        sta     $D355,y
        dey
        bpl     L92C1
        lda     #$FF
        jmp     L933F

L92CE:  lda     L938D
        jsr     L9E61
        bne     L92F0
L92D6:  lda     L938D
        jsr     L9E74
        sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        tay
L92E5:  lda     ($06),y
        sta     $D355,y
        dey
        bpl     L92E5
        jmp     L9307

L92F0:  lda     L938D
        jsr     L9BE2
        sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        tay
L92FF:  lda     ($06),y
        sta     $D355,y
        dey
        bpl     L92FF
L9307:  ldy     $D355
L930A:  lda     $D355,y
        cmp     #$2F
        beq     L9314
        dey
        bne     L930A
L9314:  dey
        sty     L938A
        iny
        ldx     #$00
L931B:  iny
        inx
        lda     $D355,y
        sta     $D345,x
        cpy     $D355
        bne     L931B
        stx     $D345
        lda     L938A
        sta     $D355
        jsr     L4036
        jsr     LB403
        lda     #$FF
        sta     L938D
        jmp     L936E

L933F:  pha
        lda     L938E
        cmp     #$02
        bne     L934F
        lda     #$07
        jsr     L403F
        jsr     L4015
L934F:  ldy     #$03
        lda     #$39
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$04
        lda     #$39
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$39
        lda     #$65
        ldx     #$D6
        jsr     MGTK_RELAY
        pla
        jmp     L900F

L936E:  ldy     #$03
        lda     #$39
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$04
        lda     #$39
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$39
        lda     #$65
        ldx     #$D6
        jsr     MGTK_RELAY
        rts

L938A:  brk
L938B:  brk
L938C:  brk
L938D:  brk
L938E:  brk
L938F:  brk
L9390:  ldy     #$38
        lda     #$65
        ldx     #$D6
        jsr     MGTK_RELAY
        lda     $D665
        jsr     LB7B9
        ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$12
        lda     #$D8
        ldx     #$D6
        jsr     MGTK_RELAY
        ldy     #$12
        lda     #$E0
        ldx     #$D6
        jsr     MGTK_RELAY
        ldy     #$0E
        lda     #$E8
        ldx     #$D6
        jsr     MGTK_RELAY
        ldy     #$10
        lda     #$EC
        ldx     #$D6
        jsr     MGTK_RELAY
        ldy     #$0E
        lda     #$F0
        ldx     #$D6
        jsr     MGTK_RELAY
        ldy     #$10
        lda     #$F4
        ldx     #$D6
        jsr     MGTK_RELAY
        ldy     #$07
        lda     #$00
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$12
        lda     #$F8
        ldx     #$D6
        jsr     MGTK_RELAY
        ldy     #$12
        lda     #$00
        ldx     #$D7
        jsr     MGTK_RELAY
        jsr     L94A9
        jsr     L94BA
        lda     L938E
        cmp     #$02
        bne     L9417
        lda     #$29
        ldx     #$D7
        jsr     L94F0
        rts

L9417:  cmp     #$03
        bne     L9423
        lda     #$3B
        ldx     #$D7
        jsr     L94F0
        rts

L9423:  lda     #$4F
        ldx     #$D7
        jsr     L94F0
        rts

L942B:  stx     $07
        sta     $06
        lda     $D6C3
        sta     L94A8
        tya
        pha
        cmp     #$10
        bcc     L9441
        sec
        sbc     #$10
        jmp     L9448

L9441:  cmp     #$08
        bcc     L9448
        sec
        sbc     #$08
L9448:  ldx     #$00
        stx     L94A7
        asl     a
        rol     L94A7
        asl     a
        rol     L94A7
        asl     a
        rol     L94A7
        clc
        adc     #$20
        sta     $D6C5
        lda     L94A7
        adc     #$00
        sta     $D6C6
        pla
        cmp     #$08
        bcs     L9471
        lda     #$00
        tax
        beq     L947F
L9471:  cmp     #$10
        bcs     L947B
        ldx     #$00
        lda     #$73
        bne     L947F
L947B:  lda     #$DC
        ldx     #$00
L947F:  clc
        adc     #$0A
        sta     $D6C3
        txa
        adc     #$00
        sta     $D6C4
        ldy     #$0E
        lda     #$C3
        ldx     #$D6
        jsr     MGTK_RELAY
        lda     $06
        ldx     $07
        jsr     L94CB
        lda     L94A8
        sta     $D6C3
        lda     #$00
        sta     $D6C4
        rts

L94A7:  brk
L94A8:  brk
L94A9:  ldy     #$0E
        lda     #$08
        ldx     #$D7
        jsr     MGTK_RELAY
        lda     #$40
        ldx     #$AE
        jsr     LB708
        rts

L94BA:  ldy     #$0E
        lda     #$0C
        ldx     #$D7
        jsr     MGTK_RELAY
        lda     #$96
        ldx     #$AE
        jsr     LB708
        rts

L94CB:  sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        tay
L94D4:  lda     ($06),y
        sta     $D486,y
        dey
        bpl     L94D4
        lda     #$87
        sta     $D484
        lda     #$D4
        sta     $D485
        ldy     #$19
        lda     #$84
        ldx     #$D4
        jsr     MGTK_RELAY
        rts

L94F0:  sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc     $06
        bne     L9500
        inc     $07
L9500:  ldy     #$18
        lda     #$06
        ldx     #$00
        jsr     MGTK_RELAY
        lsr     $0A
        ror     $09
        lda     #$01
        sta     L9539
        lda     #$5E
        lsr     L9539
        ror     a
        sec
        sbc     $09
        sta     $D6B7
        lda     L9539
        sbc     $0A
        sta     $D6B8
        ldy     #$0E
        lda     #$B7
        ldx     #$D6
        jsr     MGTK_RELAY
        ldy     #$19
        lda     #$06
        ldx     #$00
        jsr     MGTK_RELAY
        rts

L9539:  brk
L953A:  lda     #$00
        sta     L95BF
L953F:  ldy     #$2A
        lda     #$08
        ldx     #$D2
        jsr     MGTK_RELAY
        lda     $D208
        cmp     #$02
        beq     L95A2
        lda     $D665
        sta     $D208
        ldy     #$46
        lda     #$08
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$0E
        lda     #$0D
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$13
        lda     #$F8
        ldx     #$D6
        jsr     MGTK_RELAY
        cmp     #$80
        beq     L957C
        lda     L95BF
        beq     L9584
        jmp     L953F

L957C:  lda     L95BF
        bne     L9584
        jmp     L953F

L9584:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$F8
        ldx     #$D6
        jsr     MGTK_RELAY
        lda     L95BF
        clc
        adc     #$80
        sta     L95BF
        jmp     L953F

L95A2:  lda     L95BF
        beq     L95AA
        lda     #$FF
        rts

L95AA:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$F8
        ldx     #$D6
        jsr     MGTK_RELAY
        lda     #$00
        rts

L95BF:  brk
L95C0:  lda     #$00
        sta     L9645
L95C5:  ldy     #$2A
        lda     #$08
        ldx     #$D2
        jsr     MGTK_RELAY
        lda     $D208
        cmp     #$02
        beq     L9628
        lda     $D665
        sta     $D208
        ldy     #$46
        lda     #$08
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$0E
        lda     #$0D
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$13
        lda     #$00
        ldx     #$D7
        jsr     MGTK_RELAY
        cmp     #$80
        beq     L9602
        lda     L9645
        beq     L960A
        jmp     L95C5

L9602:  lda     L9645
        bne     L960A
        jmp     L95C5

L960A:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$00
        ldx     #$D7
        jsr     MGTK_RELAY
        lda     L9645
        clc
        adc     #$80
        sta     L9645
        jmp     L95C5

L9628:  lda     L9645
        beq     L9630
        lda     #$FF
        rts

L9630:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$00
        ldx     #$D7
        jsr     MGTK_RELAY
        lda     #$01
        rts

L9645:  brk
L9646:  ldy     #$2A
        lda     #$08
        ldx     #$D2
        jsr     MGTK_RELAY
        lda     $D208
        cmp     #$01
        bne     L9659
        jmp     L9660

L9659:  cmp     #$03
        bne     L9646
        jmp     L9822

L9660:  ldy     #$40
        lda     #$09
        ldx     #$D2
        jsr     MGTK_RELAY
        lda     $D20D
        bne     L9671
        lda     #$FF
        rts

L9671:  cmp     #$02
        beq     L9678
        lda     #$FF
        rts

L9678:  lda     $D20E
        cmp     $D665
        beq     L9683
        lda     #$FF
        rts

L9683:  lda     $D665
        jsr     LB7B9
        lda     $D665
        sta     $D208
        ldy     #$46
        lda     #$08
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$0E
        lda     #$0D
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$13
        lda     #$F8
        ldx     #$D6
        jsr     MGTK_RELAY
        cmp     #$80
        bne     L96C8
        ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$F8
        ldx     #$D6
        jsr     MGTK_RELAY
        jsr     L953A
        bmi     L96C7
        lda     #$00
L96C7:  rts

L96C8:  ldy     #$13
        lda     #$00
        ldx     #$D7
        jsr     MGTK_RELAY
        cmp     #$80
        bne     L96EF
        ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$00
        ldx     #$D7
        jsr     MGTK_RELAY
        jsr     L95C0
        bmi     L96EE
        lda     #$01
L96EE:  rts

L96EF:  lda     $D20D
        sec
        sbc     #$0A
        sta     $D20D
        lda     $D20E
        sbc     #$00
        sta     $D20E
        lda     $D20F
        sec
        sbc     #$19
        sta     $D20F
        lda     $D210
        sbc     #$00
        sta     $D210
        bpl     L9716
        lda     #$FF
        rts

L9716:  lda     $D20D
        cmp     #$6E
        lda     $D20E
        sbc     #$00
        bmi     L9736
        lda     $D20D
        cmp     #$DC
        lda     $D20E
        sbc     #$00
        bmi     L9732
        lda     #$02
        bne     L9738
L9732:  lda     #$01
        bne     L9738
L9736:  lda     #$00
L9738:  pha
        lsr     $D210
        ror     $D20F
        lsr     $D210
        ror     $D20F
        lsr     $D210
        ror     $D20F
        lda     $D20F
        cmp     #$08
        bcc     L9756
        pla
        lda     #$FF
        rts

L9756:  pla
        asl     a
        asl     a
        asl     a
        clc
        adc     $D20F
        sta     L979C
        cmp     #$08
        bcs     L9782
        cmp     L938B
        bcs     L9790
L976A:  cmp     L938D
        beq     L977E
        lda     L938D
        jsr     L979D
        lda     L979C
        sta     L938D
        jsr     L979D
L977E:  jsr     LB445
        rts

L9782:  sec
        sbc     #$08
        cmp     L938C
        bcs     L9790
        clc
        adc     #$08
        jmp     L976A

L9790:  lda     L938D
        jsr     L979D
        lda     #$FF
        sta     L938D
        rts

L979C:  brk
L979D:  bpl     L97A0
        rts

L97A0:  pha
        lsr     a
        lsr     a
        lsr     a
        tax
        beq     L97B6
        cmp     #$01
        bne     L97B2
        lda     #$69
        ldx     #$00
        jmp     L97B6

L97B2:  lda     #$D2
        ldx     #$00
L97B6:  clc
        adc     #$09
        sta     $D877
        txa
        adc     #$00
        sta     $D878
        pla
        cmp     #$08
        bcc     L97D4
        cmp     #$10
        bcs     L97D1
        sec
        sbc     #$08
        jmp     L97D4

L97D1:  sec
        sbc     #$10
L97D4:  asl     a
        asl     a
        asl     a
        clc
        adc     #$18
        sta     $D879
        lda     #$00
        adc     #$00
        sta     $D87A
        lda     $D877
        clc
        adc     #$6A
        sta     $D87B
        lda     $D878
        adc     #$00
        sta     $D87C
        lda     $D879
        clc
        adc     #$07
        sta     $D87D
        lda     $D87A
        adc     #$00
        sta     $D87E
        ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$77
        ldx     #$D8
        jsr     MGTK_RELAY
        ldy     #$07
        lda     #$00
        ldx     #$D2
        jsr     MGTK_RELAY
        rts

L9822:  lda     $D20A
        cmp     #$02
        bne     L982C
        lda     #$FF
        rts

L982C:  lda     $D209
        and     #$7F
        cmp     #$08
        bne     L9838
        jmp     L98F8

L9838:  cmp     #$15
        bne     L983F
        jmp     L98AC

L983F:  cmp     #$0D
        bne     L9846
        jmp     L985E

L9846:  cmp     #$1B
        bne     L984D
        jmp     L9885

L984D:  cmp     #$0A
        bne     L9854
        jmp     L9978

L9854:  cmp     #$0B
        bne     L985B
        jmp     L993F

L985B:  lda     #$FF
        rts

L985E:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$F8
        ldx     #$D6
        jsr     MGTK_RELAY
        ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$F8
        ldx     #$D6
        jsr     MGTK_RELAY
        lda     #$00
        rts

L9885:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$00
        ldx     #$D7
        jsr     MGTK_RELAY
        ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$00
        ldx     #$D7
        jsr     MGTK_RELAY
        lda     #$01
        rts

L98AC:  lda     L938B
        ora     L938C
        beq     L98F5
        lda     L938D
        bpl     L98CE
        ldx     #$00
        lda     L99DD
        bpl     L98EE
        ldx     #$08
        lda     L99E5
        bpl     L98EE
        ldx     #$10
        lda     L99ED
        bpl     L98EE
L98CE:  lda     L938D
        jsr     L979D
        lda     L938D
L98D7:  clc
        adc     #$08
        cmp     #$18
        bcc     L98E4
        sec
        sbc     #$20
        jmp     L98D7

L98E4:  tax
        lda     L99DD,x
        bpl     L98EE
        txa
        jmp     L98D7

L98EE:  txa
        sta     L938D
        jsr     L979D
L98F5:  lda     #$FF
        rts

L98F8:  lda     L938B
        ora     L938C
        beq     L993C
        lda     L938D
        bpl     L9917
        ldx     #$10
        lda     L99ED
        bpl     L9935
        ldx     #$08
        lda     L99E5
        bpl     L9935
        lda     #$00
        beq     L9936
L9917:  lda     L938D
        jsr     L979D
        lda     L938D
L9920:  sec
        sbc     #$08
        bpl     L992B
        clc
        adc     #$20
        jmp     L9920

L992B:  tax
        lda     L99DD,x
        bpl     L9935
        txa
        jmp     L9920

L9935:  txa
L9936:  sta     L938D
        jsr     L979D
L993C:  lda     #$FF
        rts

L993F:  lda     L938B
        ora     L938C
        beq     L9975
        lda     L938D
        bpl     L9956
        ldx     #$17
L994E:  lda     L99DD,x
        bpl     L996F
        dex
        bpl     L994E
L9956:  lda     L938D
        jsr     L979D
        ldx     L938D
L995F:  dex
        bmi     L996A
        lda     L99DD,x
        bpl     L996F
        jmp     L995F

L996A:  ldx     #$18
        jmp     L995F

L996F:  sta     L938D
        jsr     L979D
L9975:  lda     #$FF
        rts

L9978:  lda     L938B
        ora     L938C
        beq     L99B0
        lda     L938D
        bpl     L998F
        ldx     #$00
L9987:  lda     L99DD,x
        bpl     L99AA
        inx
        bne     L9987
L998F:  lda     L938D
        jsr     L979D
        ldx     L938D
L9998:  inx
        cpx     #$18
        bcs     L99A5
        lda     L99DD,x
        bpl     L99AA
        jmp     L9998

L99A5:  ldx     #$FF
        jmp     L9998

L99AA:  sta     L938D
        jsr     L979D
L99B0:  lda     #$FF
        rts

L99B3:  ldx     #$17
        lda     #$FF
L99B7:  sta     L99DD,x
        dex
        bpl     L99B7
        ldx     #$00
L99BF:  cpx     L938B
        beq     L99CB
        txa
        sta     L99DD,x
        inx
        bne     L99BF
L99CB:  ldx     #$00
L99CD:  cpx     L938C
        beq     L99DC
        txa
        clc
        adc     #$08
        sta     L99E5,x
        inx
        bne     L99CD
L99DC:  rts

L99DD:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
L99E5:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
L99ED:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
L99F5:  ldy     #$07
        lda     #$00
        ldx     #$D2
        jsr     MGTK_RELAY
        ldy     #$11
        lda     #$7F
        ldx     #$D8
        jsr     MGTK_RELAY
        rts

        rts

        rts

L9A0A:  cmp     #$08
        bcc     L9A11
        jmp     L9A61

L9A11:  sta     L9A60
        tya
        pha
        lda     L9A60
        jsr     L9BD5
        sta     $06
        stx     $07
        lda     L9A60
        jsr     L9BEF
        sta     $08
        stx     $09
        ldy     $D443
L9A2D:  lda     $D443,y
        sta     ($06),y
        sta     ($08),y
        dey
        bpl     L9A2D
        ldy     #$0F
        pla
        sta     ($06),y
        sta     ($08),y
        lda     L9A60
        jsr     L9BE2
        sta     $06
        stx     $07
        lda     L9A60
        jsr     L9BFC
        sta     $08
        stx     $09
        ldy     $D402
L9A55:  lda     $D402,y
        sta     ($06),y
        sta     ($08),y
        dey
        bpl     L9A55
        rts

L9A60:  brk
L9A61:  sta     L9A96
        tya
        pha
        lda     L9A96
        jsr     L9BD5
        sta     $06
        stx     $07
        ldy     $D443
L9A73:  lda     $D443,y
        sta     ($06),y
        dey
        bpl     L9A73
        ldy     #$0F
        pla
        sta     ($06),y
        lda     L9A96
        jsr     L9BE2
        sta     $06
        stx     $07
        ldy     $D402
L9A8D:  lda     $D402,y
        sta     ($06),y
        dey
        bpl     L9A8D
        rts

L9A96:  brk
L9A97:  sta     L9BD4
        cmp     #$08
        bcc     L9AA1
        jmp     L9B5F

L9AA1:  tax
        inx
        cpx     L938B
        bne     L9AC0
L9AA8:  dec     $0C00
        dec     L938B
        lda     $DB1C
        sta     L9ABB
        lda     $DB1D
        sta     L9ABC
        .byte   $CE
L9ABB:  .byte   $34
L9ABC:  .byte   $12
        jmp     L9CEA

L9AC0:  lda     L9BD4
        cmp     L938B
        beq     L9AA8
        jsr     L9BD5
        sta     $06
        stx     $07
        lda     $06
        adc     #$10
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9AE0:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9AE0
        ldy     #$0F
        lda     ($08),y
        sta     ($06),y
        lda     L9BD4
        jsr     L9BEF
        sta     $06
        stx     $07
        lda     $06
        adc     #$10
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9B08:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9B08
        ldy     #$0F
        lda     ($08),y
        sta     ($06),y
        lda     L9BD4
        jsr     L9BE2
        sta     $06
        stx     $07
        lda     $06
        adc     #$40
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9B30:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9B30
        lda     L9BD4
        jsr     L9BFC
        sta     $06
        stx     $07
        lda     $06
        adc     #$40
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9B52:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9B52
        inc     L9BD4
        jmp     L9AC0

L9B5F:  sec
        sbc     #$07
        cmp     L938C
        bne     L9B70
        dec     $0C01
        dec     L938C
        jmp     L9CEA

L9B70:  lda     L9BD4
        sec
        sbc     #$08
        cmp     L938C
        bne     L9B84
        dec     $0C01
        dec     L938C
        jmp     L9CEA

L9B84:  lda     L9BD4
        jsr     L9BD5
        sta     $06
        stx     $07
        lda     $06
        adc     #$10
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9B9F:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9B9F
        lda     L9BD4
        jsr     L9BE2
        sta     $06
        stx     $07
        lda     $06
        adc     #$40
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9BC1:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9BC1
        ldy     #$0F
        lda     ($08),y
        sta     ($06),y
        inc     L9BD4
        jmp     L9B70

L9BD4:  brk
L9BD5:  jsr     L9D8D
        clc
        adc     #$02
        tay
        txa
        adc     #$0C
        tax
        tya
        rts

L9BE2:  jsr     L9DA7
        clc
        adc     #$82
        tay
        txa
        adc     #$0D
        tax
        tya
        rts

L9BEF:  jsr     L9D8D
        clc
        adc     #$1E
        tay
        txa
        adc     #$DB
        tax
        tya
        rts

L9BFC:  jsr     L9DA7
        clc
        adc     #$9E
        tay
        txa
        adc     #$DB
        tax
        tya
        rts

L9C09:  sta     $D2AC
        ldy     #$0C
        lda     #$AC
        ldx     #$D2
        jsr     LA500
        rts

        .byte   $03
        brk
        .byte   $1C
        brk
        php
L9C1B:  brk
        .byte   $04
L9C1D:  brk
        brk
        .byte   $0C
        brk
        php
        brk
        brk
        .byte   $01
L9C25:  brk
L9C26:  lda     #$00
        ldx     #$1C
        jsr     L9E2A
        inc     $1C00
        ldx     $1C00
        lda     #$2F
        sta     $1C00,x
        ldx     #$00
        ldy     $1C00
L9C3D:  inx
        iny
        lda     L9C9A,x
        sta     $1C00,y
        cpx     L9C9A
        bne     L9C3D
        sty     $1C00
L9C4D:  ldy     #$C8
        lda     #$16
        ldx     #$9C
        jsr     L9DC9
        beq     L9C60
        lda     #$00
        jsr     L9C09
        beq     L9C4D
L9C5F:  rts

L9C60:  lda     L9C1B
        sta     L9C1D
        sta     L9C25
L9C69:  ldy     #$CB
        lda     #$1C
        ldx     #$9C
        jsr     L9DC9
        beq     L9C81
        pha
        jsr     L4015
        pla
        jsr     L4030
        beq     L9C69
        jmp     L9C5F

L9C81:  ldy     #$CD
        lda     #$24
        ldx     #$9C
        jsr     L9DC9
        ldy     #$CC
        lda     #$24
        ldx     #$9C
        jsr     L9DC9
        rts

        .byte   $03
        txs
        .byte   $9C
        brk
        php
L9C99:  brk
L9C9A:  ora     $6553
        jmp     (L6365)

        .byte   $74
        .byte   $6F
        .byte   $72
        rol     $694C
        .byte   $73
        .byte   $74
        .byte   $04
L9CA9:  brk
        brk
        .byte   $0C
        brk
        php
        brk
        brk
        .byte   $04
L9CB1:  brk
        brk
        .byte   $0C
        brk
        php
        brk
        brk
        ora     ($00,x)
L9CBA:  ldy     #$C8
        lda     #$94
        ldx     #$9C
        jsr     L9DC9
        beq     L9CCF
        lda     #$00
        jsr     L9C09
        beq     L9CBA
        lda     #$FF
        rts

L9CCF:  lda     L9C99
        sta     L9CA9
        ldy     #$CA
        lda     #$A8
        ldx     #$9C
        jsr     L9DC9
        bne     L9CE9
        ldy     #$CC
        lda     #$B8
        ldx     #$9C
        jsr     L9DC9
L9CE9:  rts

L9CEA:  ldy     #$C8
        lda     #$94
        ldx     #$9C
        jsr     L9DC9
        beq     L9CFF
        lda     #$00
        jsr     L9C09
        beq     L9CBA
        lda     #$FF
        rts

L9CFF:  lda     L9C99
        sta     L9CB1
L9D05:  ldy     #$CB
        lda     #$B0
        ldx     #$9C
        jsr     L9DC9
        beq     L9D18
        jsr     L4030
        beq     L9D05
        jmp     L9D21

L9D18:  ldy     #$CC
        lda     #$B8
        ldx     #$9C
        jsr     L9DC9
L9D21:  rts

L9D22:  jsr     L9CBA
        bpl     L9D28
        rts

L9D28:  lda     $0C00
        sta     L938B
        beq     L9D55
        lda     #$00
        sta     L9D8C
L9D35:  lda     L9D8C
        cmp     L938B
        beq     L9D55
        jsr     L9D8D
        clc
        adc     #$02
        pha
        txa
        adc     #$0C
        tax
        pla
        ldy     L9D8C
        jsr     L942B
        inc     L9D8C
        jmp     L9D35

L9D55:  lda     $0C01
        sta     L938C
        beq     L9D89
        lda     #$00
        sta     L9D8C
L9D62:  lda     L9D8C
        cmp     L938C
        beq     L9D89
        clc
        adc     #$08
        jsr     L9D8D
        clc
        adc     #$02
        pha
        txa
        adc     #$0C
        tax
        lda     L9D8C
        clc
        adc     #$08
        tay
        pla
        jsr     L942B
        inc     L9D8C
        jmp     L9D62

L9D89:  lda     #$00
        rts

L9D8C:  brk
L9D8D:  ldx     #$00
        stx     L9DA6
        asl     a
        rol     L9DA6
        asl     a
        rol     L9DA6
        asl     a
        rol     L9DA6
        asl     a
        rol     L9DA6
        ldx     L9DA6
        rts

L9DA6:  brk
L9DA7:  ldx     #$00
        stx     L9DC8
        asl     a
        rol     L9DC8
        asl     a
        rol     L9DC8
        asl     a
        rol     L9DC8
        asl     a
        rol     L9DC8
        asl     a
        rol     L9DC8
        asl     a
        rol     L9DC8
        ldx     L9DC8
        rts

L9DC8:  brk
L9DC9:  sty     L9DDD
        sta     L9DDE
        stx     L9DDF
        php
        sei
        sta     ALTZPOFF
        sta     $C082
        jsr     MLI
L9DDD:  brk
L9DDE:  brk
L9DDF:  brk
        sta     ALTZPON
        tax
        lda     LCBANK1
        lda     LCBANK1
        plp
        txa
        rts

L9DED:  sta     ALTZPOFF
        lda     $C083
        lda     $C083
        lda     $D3FF
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts

L9E05:  sta     L9E1B
        stx     L9E1C
        sta     ALTZPOFF
        lda     $C083
        lda     $C083
        ldx     $D3EE
L9E17:  lda     $D3EE,x
        .byte   $9D
L9E1B:  .byte   $34
L9E1C:  .byte   $12
        dex
        bpl     L9E17
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

L9E2A:  sta     L9E40
        stx     L9E41
        sta     ALTZPOFF
        lda     $C083
        lda     $C083
        ldx     $D3AD
L9E3C:  lda     $D3AD,x
        .byte   $9D
L9E40:  .byte   $34
L9E41:  .byte   $12
        dex
        bpl     L9E3C
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

        asl     a
L9E50:  brk
L9E51:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
L9E61:  jsr     L9E74
        sta     L9E50
        stx     L9E51
        ldy     #$C4
        lda     #$4F
        ldx     #$9E
        jsr     L9DC9
        rts

L9E74:  sta     L9EBF
        lda     #$C1
        ldx     #$9E
        jsr     L9E05
        lda     L9EBF
        jsr     L9BE2
        sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        sta     L9EC0
        tay
L9E90:  lda     ($06),y
        and     #$7F
        cmp     #$2F
        beq     L9E9B
        dey
        bne     L9E90
L9E9B:  dey
L9E9C:  lda     ($06),y
        and     #$7F
        cmp     #$2F
        beq     L9EA7
        dey
        bne     L9E9C
L9EA7:  dey
        ldx     L9EC1
L9EAB:  inx
        iny
        lda     ($06),y
        sta     L9EC1,x
        cpy     L9EC0
        bne     L9EAB
        stx     L9EC1
        lda     #$C1
        ldx     #$9E
        rts

L9EBF:  brk
L9EC0:  brk
L9EC1:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
