L0000           := $0000
L0002           := $0002
L000C           := $000C
L0030           := $0030
L0080           := $0080
L0088           := $0088
L0290           := $0290
L0400           := $0400
L05A3           := $05A3
L0765           := $0765
L0D20           := $0D20
L1234           := $1234
L17D5           := $17D5
L2000           := $2000
L2020           := $2020
L202D           := $202D
L2061           := $2061
L2078           := $2078
L2120           := $2120
L2121           := $2121
L2824           := $2824
L2E2E           := $2E2E
L3028           := $3028
LA000           := $A000
LA003           := $A003

LD23E           := $D23E
LF0A5           := $F0A5
LFFFF           := $FFFF


;;; Pointers into the guts of MGTK ???
;;; (possibly from bogus code, e.g. chunks of BASIC.SYSTEM etc)

L4E7F := $4E7F
L5158 := $5158
L5159 := $5159
L4DAE := $4DAE
L5099 := $5099
L7973 := $7973
L5400 := $5400
L5F8E := $5F8E

;;; ============================================================
;;; MGTK library
;;; ============================================================

MGTK:
        .scope
        .include "../mgtk/mgtk_100B4.s"
        .endscope

;;; ============================================================
;;; End of MGTK
;;; ============================================================

;;; ???

        .byte   $04,$04,$04,$04,$04,$04,$04,$04
        .byte   $04,$05,$05,$05,$05,$05,$05,$05
        .byte   $05,$05,$05,$05,$05,$05,$05,$05
        .byte   $05,$06,$06,$06,$06,$06,$06,$06
        .byte   $06,$06,$06,$06,$06,$00,$52,$54
        .byte   $55,$56,$57,$58,$59,$5A,$5B,$5C
        .byte   $5D,$5E,$5F,$60,$61,$62,$63,$64
        .byte   $65,$66,$67,$68,$69,$6A,$6B,$6C
        .byte   $6D,$6E,$6F,$70,$71,$72,$73,$74
        .byte   $75,$76,$77,$78,$79,$7A,$7B,$7C
        .byte   $7D,$7E,$7F,$80,$81,$82,$83,$84
        .byte   $85,$86,$87,$88,$89,$8A,$8B,$8C
        .byte   $8D,$8E,$8F,$90,$91,$92,$93

        .res    447, 0

        .byte   $6C,$00,$04,$00,$A8,$00,$E1,$00
        .byte   $00,$00,$02,$00,$BE,$00,$E1,$00
        .byte   $00,$00,$02,$00,$FE,$03,$00,$00
        .byte   $00,$00,$A8,$02,$00,$95,$00,$00
        .byte   $00,$10,$57,$27,$A8,$97,$00,$00
        .byte   $00,$18,$10,$00,$EE,$9A,$00,$00
        .byte   $00,$40,$10,$00,$62,$D0,$E0,$00
        .byte   $00,$40,$41,$00,$76,$D0,$E0,$00
        .byte   $00,$20,$D5,$17,$00,$E8,$01,$00
        .byte   $00,$00,$F3,$01,$00,$D4,$00,$00
        .byte   $00,$80,$7D,$3C,$00,$20,$00,$00
        .byte   $00,$00,$00,$18,$00,$D0,$01,$00
        .byte   $00,$00,$00,$10,$00,$D0,$01,$00
        .byte   $00,$80,$00,$00,$5C,$17,$95,$00
        .byte   $01,$00,$00,$95,$AF,$68,$C0,$00
        .byte   $48,$AF,$83,$C0,$00,$AF,$83,$C0
        .byte   $00,$22,$7F,$FB,$01,$68,$8F,$68
        .byte   $C0,$00,$40,$08,$78,$18,$FB,$08
        .byte   $E2,$30,$A9,$00,$90,$02,$A9,$80
        .byte   $8F,$F5,$95,$00,$22,$64,$00,$E1
        .byte   $C2,$30,$AF,$BE,$00,$E1,$30,$34
        .byte   $09,$00,$80,$8F,$BE,$00,$E1,$68
        .byte   $48,$EB,$E2,$30,$48,$28,$E2,$30
        .byte   $AF,$68,$C0,$00,$8F,$F6,$95,$00
        .byte   $29,$04,$D0,$0A,$AF,$8B,$C0,$00
        .byte   $AF,$8B,$C0,$00,$80,$08,$AF,$83
        .byte   $C0,$00,$AF,$83,$C0,$00,$0B,$8B
        .byte   $5C,$00,$E8,$01,$AF,$EE,$95,$00
        .byte   $8F,$F0,$95,$00,$A9,$07,$00,$8F
        .byte   $EE,$95,$00,$18,$A3,$03,$69,$06
        .byte   $00,$83,$03,$90,$09,$E2,$20,$A3
        .byte   $05,$69,$00,$00,$83,$05,$80,$19
        .byte   $AB,$2B,$C2,$30,$AF,$EE,$95,$00
        .byte   $29,$FF,$00,$D0,$0C,$A3,$02,$29
        .byte   $FE,$FF,$09,$02,$00,$83,$02,$80
        .byte   $0C,$C2,$30,$A3,$02,$29,$FD,$FF
        .byte   $09,$01,$00,$83,$02,$78,$E2,$30
        .byte   $AF,$F6,$95,$00,$8F,$68,$C0,$00
        .byte   $C2,$30,$AF,$EE,$95,$00,$29,$FF
        .byte   $00,$C9,$07,$00,$F0,$0B,$AF,$BE
        .byte   $00,$E1,$29,$FF,$7F,$8F,$BE,$00
        .byte   $E1,$22,$68,$00,$E1,$AF,$EE,$95
        .byte   $00,$29,$FF,$00,$48,$AF,$F0,$95
        .byte   $00,$8F,$EE,$95,$00,$68,$28,$FB
        .byte   $28,$6B,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$38,$FB,$20,$00
        .byte   $BF,$C0,$09,$97,$08,$18,$FB,$28
        .byte   $6B,$38,$FB,$20,$00,$BF,$C1,$15
        .byte   $97,$08,$18,$FB,$28,$6B,$38,$FB
        .byte   $20,$00,$BF,$C2,$18,$97,$08,$18
        .byte   $FB,$28,$6B,$38,$FB,$20,$00,$BF
        .byte   $C3,$1D,$97,$08,$18,$FB,$28,$6B
        .byte   $38,$FB,$20,$00,$BF,$C4,$2B,$97
        .byte   $08,$18,$FB,$28,$6B,$38,$FB,$20
        .byte   $00,$BF,$C5,$3D,$97,$08,$18,$FB
        .byte   $28,$6B,$38,$FB,$20,$00,$BF,$C6
        .byte   $41,$97,$08,$18,$FB,$28,$6B,$38
        .byte   $FB,$20,$00,$BF,$C8,$44,$97,$08
        .byte   $18,$FB,$28,$6B,$38,$FB,$20,$00
        .byte   $BF,$C9,$4A,$97,$08,$18,$FB,$28
        .byte   $6B,$38,$FB,$20,$00,$BF,$CA,$4E
        .byte   $97,$08,$18,$FB,$28,$6B,$38,$FB
        .byte   $20,$00,$BF,$CB,$56,$97,$08,$18
        .byte   $FB,$28,$6B,$38,$FB,$20,$00,$BF

;;; Font
        .assert * = $8800, error, "Font location mismatch"
        .incbin "../fonts/SELECTOR.FONT"

;;; ???
        .byte   $8D,$3F,$07
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$03,$03,$03
        .byte   $03,$03,$03,$03,$03,$04,$04,$04
        .byte   $04,$04,$04,$04,$04,$05,$05,$05
        .byte   $05,$05,$05,$05,$05,$06,$06,$06
        .byte   $06,$06,$06,$06,$06,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$08,$08,$08
        .byte   $08,$08,$08,$08,$08,$09,$09,$09
        .byte   $09,$09,$09,$09,$09,$0A,$0A,$0A
        .byte   $0A,$0A,$0A,$0A,$0A,$0B,$0B,$0B
        .byte   $0B,$0B,$0B,$0B,$0B,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0D,$0D,$0D
        .byte   $0D,$0D

;;; Application entry point

START:  jmp     L912A

        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   $07
L8E0B:  .byte   0
L8E0C:  .byte   0
L8E0D:  .byte   0
L8E0E:  .byte   0
L8E0F:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $03
        .byte   0
        ora     (L0000,x)
        .byte   $9B
        stx     L8E3B
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $02
        .byte   0
        sta     L5F8E,x
        stx     a:L0000
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $03
        .byte   0
        ldx     #$8E
        .byte   $6B
        stx     a:L0000
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L8E3B:  ora     L0000
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        tax
        stx     a:L0000
        .byte   0
        .byte   0
        .byte   $C7
        stx     a:L0000
        .byte   0
        .byte   0
        cmp     #$8E
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$8E
        .byte   0
        .byte   0
        .byte   0
        .byte   $12
        .byte   $8F
        ora     (L0000,x)
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     (L0000,x)
        .byte   $52
        .byte   $72
        .byte   $27
        .byte   $8F
L8E6B:  ora     (L0000,x)
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     (L0000,x)
L8E73:
L8E74           := * + 1
        bmi     $8EA5
        and     $018F,y
        .byte   0
L8E79:
L8E7A           := * + 1
        bmi     $8EAB
        eor     ($8F,x)
        ora     (L0000,x)
L8E7F:
L8E80           := * + 1
        bmi     $8EB1
        eor     #$8F
        ora     (L0000,x)
L8E85:
L8E86           := * + 1
        bmi     $8EB7
        eor     ($8F),y
        ora     (L0000,x)
L8E8B:
L8E8C           := * + 1
        bmi     $8EBD
L8E8D:  eor     $018F,y
        .byte   0
L8E91:
L8E92           := * + 1
        bmi     $8EC3
        adc     ($8F,x)
        ora     (L0000,x)
L8E97:
L8E98           := * + 1
        bmi     $8EC9
        adc     #$8F
        ora     ($1E,x)

        PASCAL_STRING "File"
        PASCAL_STRING "Startup"
        PASCAL_STRING "Apple II DeskTop Version 1.1"
        PASCAL_STRING " "
        PASCAL_STRING "Copyright Apple Computer Inc., 1986 "
        PASCAL_STRING "Copyright Version Soft, 1985 - 1986"
        PASCAL_STRING "All Rights reserved "
        PASCAL_STRING "Run a Program ..."
        PASCAL_STRING "Slot x "
        PASCAL_STRING "Slot x "
        PASCAL_STRING "Slot x "
        PASCAL_STRING "Slot x "
        PASCAL_STRING "Slot x "
        PASCAL_STRING "Slot x "
        PASCAL_STRING "Slot x "

L8F71:  .byte   0
L8F72:  .byte   0
L8F73:  .byte   0
L8F74:  .byte   0
L8F75:  .byte   0
L8F76:  .byte   0
L8F77:  .byte   0
L8F78:  .byte   0
L8F79:  .byte   0
L8F7A:  .byte   0
L8F7B:  .byte   0
        .byte   0
        .byte   0
L8F7E:  .byte   0
L8F7F:  .byte   0
L8F80:  .byte   0
L8F81:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L8FA2:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L8FA7:  .byte   0
        tax
        .byte   $8F
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        asl     $EA
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        dey
        .byte   0
        php
        .byte   0
        php
L8FD9:  ora     ($01,x)
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        stx     L0000,y
        .byte   $32
        .byte   0
        .byte   $F4
        ora     ($8C,x)
        .byte   0
        ora     $2800,y
        .byte   0
        .byte   0
        jsr     L0080
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $F4
        ora     ($6E,x)
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
        .byte   $04
        .byte   0
        .byte   $02
        .byte   0
        beq     L901A
L901A           := * + 1
        jmp     (L5400)

        ora     ($5E,x)
        .byte   0
        clv
        ora     ($69,x)
        .byte   0
        .byte   $3C
        .byte   0
        lsr     LA000,x
        .byte   0
        adc     #$00
        cli
        ora     ($68,x)
        .byte   0

        PASCAL_STRING {" OK           ",CHAR_RETURN}

        rti

        .byte   0
        pla
        .byte   0

        PASCAL_STRING " DeskTop       Q "
        .byte   $02
L9057           := * + 1
        ora     (L0000,x)
L9058:  .byte   0
        .byte   $0F
        .byte   0

        PASCAL_STRING "Selector"

        ora     L0000
L9066:
L9067           := * + 1
        asl     L0000,x
        ora     L0000
        .byte   $14
        .byte   0
        .byte   $EF
L906D:  ora     ($14,x)
        .byte   0
        ora     L0000
        .byte   $5A
        .byte   0
        .byte   $EF
        ora     ($5A,x)
        .byte   0
L9078:  asl     a
L9079:  .byte   0
L907A:
L907B           := * + 1
L907C           := * + 2
        asl     a:L0000,x
L907D:  .byte   0
L907E:  .byte   0
L907F:  .byte   0
L9080:
L9081           := * + 1
        ora     L0000
L9082:
L9083           := * + 1
        ora     L0000,x
L9084:
L9085           := * + 1
        sty     L0000
L9086:
L9087           := * + 1
L9088           := * + 2
        ora     a:L0000,x
L9089:  .byte   0
L908A:  .byte   0
L908B:  .byte   0
L908C:  .byte   0
L908D:  .byte   0
L908E:  .byte   0
L908F:  .byte   0
        .byte   0
        .byte   $7F

        DEFINE_OPEN_PARAMS open_params, str_selector_list, $BB00
        DEFINE_READ_PARAMS read_params, $B300, $800

        DEFINE_OPEN_PARAMS open_params3, $90BC, $1C00
        DEFINE_READ_PARAMS read_params4, $2000, $400

str_selector_list:
        PASCAL_STRING "Selector.List"

str_desktop2:
        PASCAL_STRING "DeskTop2"

        DEFINE_CLOSE_PARAMS close_params
        DEFINE_OPEN_PARAMS open_params2, str_selector, $800

str_selector:
        PASCAL_STRING "selector"

        DEFINE_SET_MARK_PARAMS set_mark_params, $6F60
        DEFINE_SET_MARK_PARAMS set_mark_params2, $8E60
        DEFINE_READ_PARAMS read_params2, $A000, $1F00
        DEFINE_READ_PARAMS read_params3, $A000, $D00
        DEFINE_CLOSE_PARAMS close_params2
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, $9104

str_desktop2_2:
        PASCAL_STRING "DeskTop2"

L910D:  .byte   0
L910E:  .byte   0
        .byte   0
L9110:  .byte   0
L9111:  .byte   0
L9112:  .byte   0
L9113:  .byte   0
L9114:  .byte   0
L9115:  .byte   0
L9116:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L9127:  .byte   0
L9128:  .byte   0
L9129:  .byte   0
L912A:  cli
        lda     #$FF
        sta     L910E
        jsr     L97F7
        lda     #$01
        sta     L9129
        lda     L9128
        ora     L9127
L913F           := * + 1
        bne     L9151
L9140:  yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_params
        beq     L914E
        jmp     L91B2

L914E:  jmp     L95B6

L9151:  lda     #$00
        sta     L92C1
        lda     CLR80COL
        bpl     L91B2
        sta     KBDSTRB
        and     #$7F
        bit     BUTN0
        bmi     L916A
        bit     BUTN1
        bpl     L917B
L916A:  cmp     #$31
        bcc     L917B
        cmp     #$38
        bcs     L917B
        sec
        sbc     #$30
        sta     L92C1
        jmp     L91B2

L917B:  cmp     #$51
        beq     L9140
        cmp     #$71
        beq     L9140
        sec
        sbc     #$31
        bmi     L91B2
        cmp     L9127
        bcs     L91B2
        sta     L910E
        jsr     L9A25
        stax    $06
        ldy     #$0F
        lda     ($06),y
        cmp     #$C0
        beq     L91AC
        jsr     L9EFC
        beq     L91B2
        jsr     L9DFF
        beq     L91AC
        jmp     L91B2

L91AC:  lda     L910E
        jsr     L9C07
L91B2:  sta     KBDSTRB
        lda     #$00
        sta     L9129
        jsr     L98E7
        ldx     #$01
L91BF:  cpx     #$03
        beq     L91DE
        cpx     #$02
        beq     L91DE
        ldy     $BF31
L91CA:  lda     $BF32,y
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     L91E5
        cpx     L91E5
        beq     L91E6
        dey
        bpl     L91CA
L91DE:  cpx     #$07
        beq     L91F2
        inx
        bne     L91BF
L91E5:  .byte   0
L91E6:  inc     L8F71
        ldy     L8F71
        sta     L8F71,y
        jmp     L91DE

L91F2:  lda     L92C1
        beq     L920D
        ldy     L8F71
L91FA:  cmp     L8F71,y
        beq     L9205
        dey
        bne     L91FA
        jmp     L920D

L9205:  ora     #$C0
        sta     L920C
L920C           := * + 2
        jmp     CLR80COL

L920D:  lda     L8F71
        sta     L8E6B
        lda     L8F72
        ora     #$30
        sta     $8F3F
        sta     L8E73
        sta     L8E74
        lda     L8F73
        ora     #$30
        sta     $8F47
        sta     L8E79
        sta     L8E7A
        lda     L8F74
        ora     #$30
        sta     $8F4F
        sta     L8E7F
        sta     L8E80
        lda     L8F75
        ora     #$30
        sta     $8F57
        sta     L8E85
        sta     L8E86
        lda     L8F76
        ora     #$30
        sta     $8F5F
        sta     L8E8B
        sta     L8E8C
        lda     $8F77
        ora     #$30
        sta     $8F67
        sta     L8E91
        sta     L8E92
        lda     L8F78
        ora     #$30
        sta     L8E97
        sta     L8E98
        sta     $8F6F
        MGTK_CALL MGTK::StartDeskTop, $8FCE
        MGTK_CALL MGTK::InitMenu, $8E15
        MGTK_CALL MGTK::SetCursor, $0000
        MGTK_CALL MGTK::GetEvent, $0000
        yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_params
        beq     L929A
        lda     #$80
L929A:  sta     L910D
        MGTK_CALL MGTK::SetMark, $8FD9
        jsr     L9914
        lda     #$00
        sta     L9112
        sta     L9110
        lda     #$01
        sta     L9111
        lda     #$FF
        sta     L910E
        jsr     L97F7
        jsr     L97C6
        jmp     L92C2

L92C1:  .byte   0
L92C2:  bit     L9112
        bpl     L92D6
        dec     L9110
        bne     L92D6
        dec     L9111
        bne     L92D6
        lda     #$00
        sta     L9112
L92D6:  MGTK_CALL MGTK::CheckEvents, $8F79
        lda     L8F79
        cmp     #$01
        bne     L92E9
        jsr     L9451
        jmp     L92C2

L92E9:  cmp     #$03
        bne     L931C
        bit     L910D
        bmi     L9316
        lda     L8F7A
        and     #$7F
        cmp     #$51
        beq     L92FF
        cmp     #$71
        bne     L9316
L92FF:  yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_params
        beq     L9313
        lda     #$FE
        jsr     L9F74
        bne     L9316
        beq     L92FF
L9313:  jmp     L95B6

L9316:  jsr     L937B
        jmp     L92C2

L931C:  cmp     #$06
        bne     L9323
        jsr     L9339
L9323:  jmp     L92C2

L9326:  MGTK_CALL MGTK::FlushEvents, $8F79
        lda     L8F79
        cmp     #$06
        bne     L9351
        MGTK_CALL MGTK::CheckEvents, $8F79
L9339:  jsr     L933F
        jmp     L9326

L933F:  MGTK_CALL MGTK::SetWinPort, $8F7A
        bne     L9351
        jsr     L9352
        MGTK_CALL MGTK::BeginUpdate, $0000
        rts

L9351:  rts

L9352:  jsr     L991A
        jsr     L97C6
        rts

L9359:
L935A           := * + 1
        lda     $95,x
        lda     $95,x
        lda     $95,x
        lda     $95,x
        lda     $95,x
        lda     $95,x
        lda     $95,x
        .byte   $F2
        .byte   $93
        lda     $BD9B,x
        .byte   $9B
        lda     $BD9B,x
        .byte   $9B
        lda     $BD9B,x
        .byte   $9B
L9377           := * + 2
        lda     a:$9B,x
        asl     $1E10
L937B:  lda     L8F7B
        bne     L938C
        lda     L8F7A
        and     #$7F
        cmp     #$1B
        beq     L93A5
L9389:  jmp     L95F5

L938C:  lda     L8F7A
        and     #$7F
        cmp     #$1B
        beq     L93A5
        cmp     #$52
        beq     L93A5
        cmp     #$72
        beq     L93A5
        cmp     #$3A
        bcs     L9389
        cmp     #$31
        bcc     L9389
L93A5:  sta     L8E0E
        lda     L8F7B
        sta     L8E0F
        MGTK_CALL MGTK::MenuSelect, $8E0C
L93B4:  ldx     L8E0D
        beq     L93BE
        ldx     L8E0C
        bne     L93C1
L93BE:  jmp     L92C2

L93C1:  dex
        lda     L9377,x
        tax
        ldy     L8E0D
        dey
        tya
        asl     a
        sta     L93F0
        txa
        clc
        adc     L93F0
        tax
        lda     L9359,x
        sta     L93F0
        lda     L935A,x
        sta     L93F1
        jsr     L93EB
        MGTK_CALL MGTK::MenuKey, $8E0C
        rts

L93EB:  tsx
        stx     L8E0B
L93F0           := * + 1
L93F1           := * + 2
        jmp     L1234

        lda     L910E
        bmi     L93FF
        jsr     L9B42
        lda     #$FF
        sta     L910E
L93FF:  jsr     L98C1
        yax_call MLI_WRAPPER, OPEN, open_params2
        bne     L9443
        lda     open_params2::ref_num
        sta     set_mark_params::ref_num
        sta     read_params2::ref_num
        yax_call MLI_WRAPPER, SET_MARK, set_mark_params
        yax_call MLI_WRAPPER, READ, read_params2
        yax_call MLI_WRAPPER, CLOSE, close_params2
        jsr     LA000
        bne     L943F
L9436:  tya
        jsr     L9C1A
        jsr     LA003
        beq     L9436
L943F:  jsr     L97F7
        rts

L9443:  lda     #$FE
        jsr     L9F74
        bne     L9450
        jsr     L98C1
        jmp     L93FF

L9450:  rts

L9451:  MGTK_CALL MGTK::EndUpdate, $8F7A
        lda     L8F7E
        bne     L945D
        rts

L945D:  cmp     #$01
        bne     L946A
        MGTK_CALL MGTK::SetMenu, $8E0C
        jmp     L93B4

L946A:  cmp     #$02
        bne     L9472
        jmp     L9473

        rts

L9472:  rts

L9473:  lda     L8F7F
        cmp     L8FD9
        beq     L947C
        rts

L947C:  lda     L8FD9
        jsr     L9A15
        lda     L8FD9
        sta     L8F79
        MGTK_CALL MGTK::GrowWindow, $8F79
        MGTK_CALL MGTK::MoveTo, $8F7E
        MGTK_CALL MGTK::InRect, $901B
        cmp     #$80
        beq     L94A1
        jmp     L94B6

L94A1:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $901B
        jsr     L9E20
        bmi     L94B5
        jsr     L97BD
L94B5:  rts

L94B6:  bit     L910D
        bmi     L94F0
        MGTK_CALL MGTK::InRect, $9023
        cmp     #$80
        beq     L94C8
        jmp     L94F0

L94C8:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $9023
        jsr     L9E8E
        bmi     L94B5
L94D9:  yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_params
        beq     L94ED
        lda     #$FE
        jsr     L9F74
        bne     L94B5
        beq     L94D9
L94ED:  jmp     L95B6

L94F0:  sub16   L8F7E, L9078, L8F7E
        sub16   L8F80, L9066, L8F80
        lda     L8F81
        bpl     L9527
        lda     L910E
        jsr     L9B42
        lda     #$FF
        sta     L910E
        rts

L9527:  lsr16   L8F80
        lsr16   L8F80
        lsr16   L8F80
        lda     L8F80
        cmp     #$08
        bcc     L954C
        lda     L910E
        jsr     L9B42
        lda     #$FF
        sta     L910E
        rts

L954C:  sta     L959D
        lda     #$00
        sta     L959F
        asl     L8F7E
        rol     L8F7F
        rol     L959F
        lda     L8F7F
        asl     a
        asl     a
        asl     a
        clc
        adc     L959D
        sta     L959E
        cmp     #$08
        bcc     L9571
        jmp     L9582

L9571:  cmp     L9127
        bcc     L9596
        lda     L910E
        jsr     L9B42
        lda     #$FF
        sta     L910E
        rts

L9582:  sec
        sbc     #$08
        cmp     L9128
        bcc     L9596
        lda     L910E
        jsr     L9B42
        lda     #$FF
        sta     L910E
        rts

L9596:  lda     L959E
        jsr     L9AFD
        rts

L959D:  .byte   0
L959E:  .byte   0
L959F:  .byte   0

MLI_WRAPPER:
        sty     $95AE
        stax    $95AF
        php
        sei
        MLI_CALL $00, $0000
        plp
        and     #$FF
        rts

        rts

L95B6:  yax_call MLI_WRAPPER, OPEN, open_params3
        lda     open_params3::ref_num
        sta     read_params4::ref_num
        sta     DHIRESOFF
        sta     TXTCLR
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        yax_call MLI_WRAPPER, READ, read_params4
        yax_call MLI_WRAPPER, CLOSE, close_params
        jmp     L2000

L95F5:  lda     L8FD9
        jsr     L9A15
        lda     L8F7A
        and     #$7F
        cmp     #$1C
        bcs     L9607
        jmp     L9638

L9607:  cmp     #'1'
        bcs     L960C
        rts

L960C:  cmp     #'9'
        bcc     L9611
        rts

L9611:  sec
        sbc     #'1'
        sta     L97BC
        cmp     L9127
        bcc     L961D
        rts

L961D:  lda     L910E
        bmi     L962E
        cmp     L97BC
        bne     L9628
        rts

L9628:  lda     L910E
        jsr     L9B42
L962E:  lda     L97BC
        sta     L910E
        jsr     L9B42
        rts

L9638:  cmp     #$0D
        bne     L9658
        lda     L8FD9
        jsr     L9A15
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $901B
        MGTK_CALL MGTK::PaintRect, $901B
        jsr     L97BD
        rts

L9658:  cmp     #$15
        beq     L965F
        jmp     L96B5

L965F:  lda     L9127
        bne     L966A
        lda     L9128
        bne     L966A
        rts

L966A:  lda     L910E
        bpl     L9678
        lda     #$00
        sta     L910E
        jsr     L9B42
        rts

L9678:  lda     L910E
        cmp     #$08
        bcc     L9682
        jmp     L969A

L9682:  cmp     L9128
        bcc     L9688
        rts

L9688:  clc
        adc     #$08
        pha
        lda     L910E
        jsr     L9B42
        pla
        sta     L910E
        jsr     L9B42
        rts

L969A:  cmp     L9128
        bcc     L96A0
        rts

L96A0:  lda     L910E
        clc
        adc     #$08
        pha
        lda     L910E
        jsr     L9B42
        pla
        sta     L910E
        jsr     L9B42
        rts

L96B5:  cmp     #$08
        beq     L96BC
        jmp     L96EA

L96BC:  lda     L910E
        bpl     L96C2
        rts

L96C2:  cmp     #$08
        bcs     L96C7
        rts

L96C7:  lda     L910E
        sec
        sbc     #$08
        cmp     #$08
        bcs     L96D7
        cmp     L9127
        bcc     L96D7
        rts

L96D7:  lda     L910E
        jsr     L9B42
        lda     L910E
        sec
        sbc     #$08
        sta     L910E
        jsr     L9B42
        rts

L96EA:  cmp     #$0B
        beq     L96F1
        jmp     L976B

L96F1:  lda     L910E
        bpl     L96F7
        rts

L96F7:  lda     L910E
        jsr     L9B42
        jsr     L9728
        lda     L910E
        cmp     #$08
        bcc     L970E
        sec
        sbc     #$08
        clc
        adc     L9127
L970E:  sec
        sbc     #$01
        bpl     L971D
        lda     L9127
        clc
        adc     L9128
        sec
        sbc     #$01
L971D:  tax
        lda     L974B,x
        sta     L910E
        jsr     L9B42
        rts

L9728:  ldx     #$00
L972A:  cpx     L9127
        beq     L9737
        txa
        sta     L974B,x
        inx
        jmp     L972A

L9737:  ldy     #$00
L9739:  cpy     L9128
        bne     L973F
        rts

L973F:  tya
        clc
        adc     #$08
        sta     L974B,x
        inx
        iny
        jmp     L9739

L974B:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L976B:  cmp     #$0A
        beq     L9770
        rts

L9770:  lda     L9127
        bne     L977B
        lda     L9128
        bne     L977B
        rts

L977B:  lda     L910E
        bpl     L9789
        lda     #$00
        sta     L910E
        jsr     L9B42
        rts

L9789:  lda     L910E
        jsr     L9B42
        jsr     L9728
        lda     L9127
        clc
        adc     L9128
        sta     L97BC
        ldx     #$00
L979E:  lda     L974B,x
        cmp     L910E
        beq     L97AA
        inx
        jmp     L979E

L97AA:  inx
        cpx     L97BC
        bne     L97B2
        ldx     #$00
L97B2:  lda     L974B,x
        sta     L910E
        jsr     L9B42
        rts

L97BC:  .byte   0
L97BD:  lda     L910E
        bmi     L97C5
        jsr     L9C07
L97C5:  rts

L97C6:  lda     #$00
        sta     L97F6
L97CB:  lda     L97F6
        cmp     L9127
        beq     L97DC
        jsr     L9AA2
        inc     L97F6
        jmp     L97CB

L97DC:  lda     #$00
        sta     L97F6
L97E1:  lda     L97F6
        cmp     L9128
        beq     L97F5
        clc
        adc     #$08
        jsr     L9AA2
        inc     L97F6
        jmp     L97E1

L97F5:  rts

L97F6:  .byte   0
L97F7:  yax_call MLI_WRAPPER, OPEN, open_params
        lda     open_params::ref_num
        sta     read_params::ref_num
        yax_call MLI_WRAPPER, READ, read_params
        yax_call MLI_WRAPPER, CLOSE, close_params
        copy16  $B300, L9127
        rts

L9825:  yax_call MLI_WRAPPER, OPEN, open_params2
        bne     L9855
        lda     open_params2::ref_num
        sta     set_mark_params2::ref_num
        sta     read_params3::ref_num
        yax_call MLI_WRAPPER, SET_MARK, set_mark_params2
        yax_call MLI_WRAPPER, READ, read_params3
        yax_call MLI_WRAPPER, CLOSE, close_params2
        rts

L9855:  lda     #$FE
        jsr     L9F74
        beq     L9825
        rts

pointer_cursor:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0100000),px(%0000000)
        .byte   px(%0110000),px(%0000000)
        .byte   px(%0111000),px(%0000000)
        .byte   px(%0111100),px(%0000000)
        .byte   px(%0111110),px(%0000000)
        .byte   px(%0111111),px(%0000000)
        .byte   px(%0101100),px(%0000000)
        .byte   px(%0000110),px(%0000000)
        .byte   px(%0000110),px(%0000000)
        .byte   px(%0000011),px(%0000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000)
        .byte   px(%1110000),px(%0000000)
        .byte   px(%1111000),px(%0000000)
        .byte   px(%1111100),px(%0000000)
        .byte   px(%1111110),px(%0000000)
        .byte   px(%1111111),px(%0000000)
        .byte   px(%1111111),px(%1000000)
        .byte   px(%1111111),px(%0000000)
        .byte   px(%0001111),px(%0000000)
        .byte   px(%0001111),px(%0000000)
        .byte   px(%0000111),px(%1000000)
        .byte   px(%0000111),px(%1000000)
        .byte   1,1

watch_cursor:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0100001),px(%0010000)
        .byte   px(%0100110),px(%0011000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111100)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0000000),px(%0000000)
        .byte   5, 5



L98C1:  MGTK_CALL MGTK::ShowCursor, $0000
        MGTK_CALL MGTK::GetIntHandler, watch_cursor
        MGTK_CALL MGTK::SetCursor, $0000
        rts

L98D4:  MGTK_CALL MGTK::ShowCursor, $0000
        MGTK_CALL MGTK::GetIntHandler, pointer_cursor
        MGTK_CALL MGTK::SetCursor, $0000
        rts

L98E7:  ldx     $BF31
L98EA:  lda     $BF32,x
        cmp     #$BF
        beq     L98F5
        dex
        bpl     L98EA
        rts

L98F5:  lda     $BF33,x
        sta     $BF32,x
        cpx     $BF31
        beq     L9904
        inx
        jmp     L98F5

L9904:  dec     $BF31
        rts

L9908:  inc     $BF31
        ldx     $BF31
        lda     #$BF
        sta     $BF32,x
        rts

L9914:  lda     L8FD9
        jsr     L9A15
L991A:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::SetPenSize, $9055
        MGTK_CALL MGTK::FrameRect, $9013
        MGTK_CALL MGTK::FrameRect, $901B
        bit     L910D
        bmi     L993D
        MGTK_CALL MGTK::FrameRect, $9023
L993D:  addr_call L999B, $905B
        jsr     L9968
        bit     L910D
        bmi     L994F
        jsr     L9976
L994F:  MGTK_CALL MGTK::MoveTo, $9068
        MGTK_CALL MGTK::LineTo, $906C
        MGTK_CALL MGTK::MoveTo, $9070
        MGTK_CALL MGTK::LineTo, $9074
        rts

L9968:  MGTK_CALL MGTK::MoveTo, $902B
        addr_call L9984, $902F
        rts

L9976:  MGTK_CALL MGTK::MoveTo, $903F
        addr_call L9984, $9043
        rts

L9984:  stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
L9994:  MGTK_CALL MGTK::DrawText, $0006
        rts

L999B:  stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
L99AB:  MGTK_CALL MGTK::TextWidth, $0006
        lsr16   $09
        lda     #$01
        sta     L99DB
        lda     #$F4
        lsr     L99DB
        ror     a
        sec
        sbc     $09
        sta     L9057
        lda     L99DB
        sbc     $0A
        sta     L9058
        MGTK_CALL MGTK::MoveTo, $9057
        MGTK_CALL MGTK::DrawText, $0006
        rts

L99DB:  .byte   0
        stx     $0B
        sta     $0A
        ldy     #$00
        lda     ($0A),y
        tay
        bne     L99E8
        rts

L99E8:  dey
        beq     L99ED
        bpl     L99EE
L99ED:  rts

L99EE:  lda     ($0A),y
        and     #$7F
        cmp     #$2F
        beq     L99FA
        cmp     #$2E
        bne     L99FE
L99FA:  dey
        jmp     L99E8

L99FE:  iny
        lda     ($0A),y
        and     #$7F
        cmp     #$41
        bcc     L9A10
        cmp     #$5B
        bcs     L9A10
        clc
        adc     #$20
        sta     ($0A),y
L9A10:  dey
        jmp     L99E8

        .byte   0
L9A15:  sta     L8FA7
        MGTK_CALL MGTK::GetWinPtr, $8FA7
        MGTK_CALL MGTK::SetPort, $8FAA
        rts

L9A25:  ldx     #$00
        stx     L9A46
        asl     a
        rol     L9A46
        asl     a
        rol     L9A46
        asl     a
        rol     L9A46
        asl     a
        rol     L9A46
        clc
        adc     #$02
        tay
        lda     L9A46
        adc     #$B3
        tax
        tya
        rts

L9A46:  .byte   0
L9A47:  ldx     #$00
        stx     L9A61
        lsr     a
        ror     L9A61
        lsr     a
        ror     L9A61
        pha
        lda     L9A61
        adc     #$82
        tay
        pla
        adc     #$B4
        tax
        tya
        rts

L9A61:  .byte   0
L9A62:  pha
        lsr     a
        lsr     a
        lsr     a
        pha
        ldx     #$00
        stx     L9AA1
        lsr     a
        ror     L9AA1
        tay
        lda     L9AA1
        clc
        adc     L9078
        sta     L907C
        tya
        adc     L9079
        sta     L907D
        pla
        asl     a
        asl     a
        asl     a
        sta     L9AA1
        pla
        sec
        sbc     L9AA1
        asl     a
        asl     a
        asl     a
        clc
        adc     L907A
        sta     L907E
        lda     #$00
        adc     L907B
        sta     L907F
        rts

L9AA1:  .byte   0
L9AA2:  pha
        jsr     L9A25
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9AAF:  lda     ($06),y
        sta     L9116,y
        dey
        bne     L9AAF
        ldy     #$00
        lda     ($06),y
        clc
        adc     #$03
        sta     L9113
        pla
        pha
        cmp     #$08
        bcc     L9AD5
        lda     #$20
        sta     L9114
        sta     L9115
        sta     L9116
        jmp     L9AE5

L9AD5:  pla
        pha
        clc
        adc     #$31
        sta     L9114
        lda     #$20
        sta     L9115
        sta     L9116
L9AE5:  lda     L8FD9
        jsr     L9A15
        pla
        jsr     L9A62
        MGTK_CALL MGTK::MoveTo, $907C
        addr_call L9984, $9113
        rts

L9AFD:  cmp     L910E
        beq     L9B05
        jmp     L9B22

L9B05:  bit     L9112
        bpl     L9B17
        jsr     L9C07
        jsr     BELL1
        jsr     BELL1
        jsr     BELL1
        rts

L9B17:  lda     #$FF
        sta     L9112
        lda     #$1E
        sta     L9110
        rts

L9B22:  pha
        lda     L910E
        bmi     L9B2E
        lda     L910E
        jsr     L9B42
L9B2E:  pla
        sta     L910E
        jsr     L9B42
        lda     #$FF
        sta     L9112
        lda     #$1E
        sta     L9110
        jmp     L9B17

L9B42:  pha
        lsr     a
        lsr     a
        lsr     a
        sta     L9BBC
        asl     a
        asl     a
        asl     a
        sta     L9BBA
        pla
        sec
        sbc     L9BBA
        sta     L9BBB
        lda     #$00
        sta     L9BBA
        lda     L9BBC
        lsr     a
        ror     L9BBA
        pha
        lda     L9BBA
        clc
        adc     L9080
        sta     L9088
        pla
        pha
        adc     L9081
        sta     L9089
        lda     L9BBA
        clc
        adc     L9084
        sta     L908C
        pla
        adc     L9085
        sta     L908D
        lda     L9BBB
        asl     a
        asl     a
        asl     a
        pha
        clc
        adc     L9082
        sta     L908A
        lda     #$00
        adc     L9083
        sta     L908B
        pla
        clc
        adc     L9086
        sta     L908E
        lda     #$00
        adc     L9087
        sta     L908F
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $9088
        rts

L9BBA:  .byte   0
L9BBB:  .byte   0
L9BBC:  .byte   0
        ldy     L8E0D
        lda     L8F71,y
        ora     #$C0
        sta     L9BF4
        sta     ALTZPOFF
        lda     ROMIN2
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR
        sta     DHIRESOFF
        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80COL
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
L9BF4           := * + 2
        jmp     L0000

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params3, $220

L9C07:  lda     L9129
        bne     L9C17
        jsr     L98C1
        lda     L910E
        bmi     L9C17
        jsr     L9B42
L9C17:  jmp     L9C1D

L9C1A:  jmp     L9C7E

L9C1D:  lda     L9129
        bne     L9C32
        bit     BUTN0
        bpl     L9C2A
        jmp     L9C78

L9C2A:  jsr     L9EFC
        bne     L9C32
        jmp     L9C78

L9C32:  lda     L910E
        jsr     L9A25
        stax    $06
        ldy     #$0F
        lda     ($06),y
        asl     a
        bmi     L9C78
        bcc     L9C65
        lda     L9129
        bne     L9C6F
        jsr     L9DFF
        beq     L9C6F
        jsr     L9825
        lda     L910E
        jsr     LA000
        pha
        jsr     L9326
        pla
        beq     L9C6F
        jsr     L98D4
        jmp     L9D44

L9C65:  lda     L9129
        bne     L9C6F
        jsr     L9DFF
        bne     L9C78
L9C6F:  lda     L910E
        jsr     L9F27
        jmp     L9C7E

L9C78:  lda     L910E
        jsr     L9A47
L9C7E:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9C87:  lda     ($06),y
        sta     $0220,y
        dey
        bpl     L9C87
        yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_params3
        beq     L9CB7
        tax
        lda     L9129
        bne     L9CB4
        txa
        pha
        jsr     L9F74
        tax
        pla
        cmp     #$45
        bne     L9CB4
        txa
        bne     L9CB4
        jsr     L98C1
        jmp     L9C78

L9CB4:  jmp     L9D44

L9CB7:  lda     get_file_info_params3::file_type
        cmp     #FT_BASIC
        bne     L9CC4
        jsr     L9D61
        jmp     L9CD8

L9CC4:  cmp     #FT_BINARY
        beq     L9CD8
        cmp     #FT_SYSTEM
        beq     L9CD8
        cmp     #FT_S16
        beq     L9CD8
        lda     #$00
        jsr     L9F74
        jmp     L9D44

L9CD8:  ldy     $0220
L9CDB:  lda     $0220,y
        cmp     #'/'
        beq     L9CEF
        dey
        bne     L9CDB
        lda     #$45
        jsr     L9F74
        bne     L9D44
        jmp     L9C1D

L9CEF:  dey
        tya
        pha
        iny
        ldx     #$00
L9CF5:  iny
        inx
        lda     $0220,y
        sta     $0280,x
        cpy     $0220
        bne     L9CF5
        stx     $0280
        pla
        sta     $0220
        addr_call L9DE4, $0220
        addr_call L9DE4, $0280
        jsr     L9908
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        sta     DHIRESOFF
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR
        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80COL
        jsr     L0290
        jsr     L98E7
L9D44:  lda     L9129
        bne     L9D4E
        lda     #$FF
        sta     L910E
L9D4E:  rts

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params4, $1C00

L9D61:  ldx     $0220
L9D64:  lda     $0220,x
        cmp     #$2F
        beq     L9D71
        dex
        bne     L9D64
        jmp     L9DBA

L9D71:  dex
        stx     L9DD6
        stx     $1C00
L9D78:  lda     $0220,x
        sta     $1C00,x
        dex
        bne     L9D78
        inc     $1C00
        ldx     $1C00
        lda     #$2F
        sta     $1C00,x
L9D8C:  ldx     $1C00
        ldy     #$00
L9D91:  inx
        iny
        lda     L9DD7,y
        sta     $1C00,x
        cpy     L9DD7
        bne     L9D91
        stx     $1C00
        yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_params4
        bne     L9DAD
        rts

L9DAD:  ldx     L9DD6
L9DB0:  lda     $1C00,x
        cmp     #$2F
        beq     L9DC8
        dex
        bne     L9DB0
L9DBA:  lda     #$FF
        jsr     L9F74
        jsr     L9D44
        jsr     L98D4
        pla
        pla
        rts

L9DC8:  cpx     #$01
        beq     L9DBA
        stx     $1C00
        dex
        stx     L9DD6
        jmp     L9D8C

L9DD6:  .byte   0
L9DD7:  .byte   $0C
        .byte   $42
        adc     (HIMEM,x)
        adc     #$63
        rol     L7973
        .byte   $73
        .byte   $74
        adc     $6D
L9DE4:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9DED:  lda     ($06),y
        cmp     #$61
        bcc     L9DFB
        cmp     #$7B
        bcs     L9DFB
        and     #$DF
        sta     ($06),y
L9DFB:  dey
        bne     L9DED
        rts

L9DFF:  lda     L910E
        jsr     L9F27
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9E0E:  lda     ($06),y
        sta     $0220,y
        dey
        bpl     L9E0E
        yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_params3
        rts

L9E20:  lda     #$00
        sta     L9E8D
L9E25:  MGTK_CALL MGTK::CheckEvents, $8F79
        lda     L8F79
        cmp     #$02
        beq     L9E76
        lda     L8FD9
        sta     L8F79
        MGTK_CALL MGTK::GrowWindow, $8F79
        MGTK_CALL MGTK::MoveTo, $8F7E
        MGTK_CALL MGTK::InRect, $901B
        cmp     #$80
        beq     L9E56
        lda     L9E8D
        beq     L9E5E
        jmp     L9E25

L9E56:  lda     L9E8D
        bne     L9E5E
        jmp     L9E25

L9E5E:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $901B
        lda     L9E8D
        clc
        adc     #$80
        sta     L9E8D
        jmp     L9E25

L9E76:  lda     L9E8D
        beq     L9E7E
        return  #$FF

L9E7E:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $901B
        return  #$00

L9E8D:  .byte   0
L9E8E:  lda     #$00
        sta     L9EFB
L9E93:  MGTK_CALL MGTK::CheckEvents, $8F79
        lda     L8F79
        cmp     #$02
        beq     L9EE4
        lda     L8FD9
        sta     L8F79
        MGTK_CALL MGTK::GrowWindow, $8F79
        MGTK_CALL MGTK::MoveTo, $8F7E
        MGTK_CALL MGTK::InRect, $9023
        cmp     #$80
        beq     L9EC4
        lda     L9EFB
        beq     L9ECC
        jmp     L9E93

L9EC4:  lda     L9EFB
        bne     L9ECC
        jmp     L9E93

L9ECC:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $9023
        lda     L9EFB
        clc
        adc     #$80
        sta     L9EFB
        jmp     L9E93

L9EE4:  lda     L9EFB
        beq     L9EEC
        return  #$FF

L9EEC:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $9023
        return  #$01

L9EFB:  .byte   0
L9EFC:  lda     LCBANK2
        lda     LCBANK2
        lda     $D3FF
        tax
        lda     ROMIN2
        txa
        rts

L9F0B:  stax    L9F1E
        lda     LCBANK2
        lda     LCBANK2
        ldx     $D3EE
L9F1A:  lda     $D3EE,x
L9F1E           := * + 1
L9F1F           := * + 2
        sta     L1234,x
        dex
        bpl     L9F1A
        lda     ROMIN2
        rts

L9F27:  sta     L9F72
        addr_call L9F0B, $0800
        lda     L9F72
        jsr     L9A47
        stax    $06
        ldy     #$00
        lda     ($06),y
        sta     L9F73
        tay
L9F43:  lda     ($06),y
        and     #$7F
        cmp     #$2F
        beq     L9F4E
        dey
        bne     L9F43
L9F4E:  dey
L9F4F:  lda     ($06),y
        and     #$7F
        cmp     #$2F
        beq     L9F5A
        dey
        bne     L9F4F
L9F5A:  dey
        ldx     $0800
L9F5E:  inx
        iny
        lda     ($06),y
        sta     $0800,x
        cpy     L9F73
        bne     L9F5E
        stx     $0800
        ldax    #$0800
        rts

L9F72:  .byte   0
L9F73:  .byte   0
L9F74:  pha
        jsr     BELL1
        pla
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        jsr     LD23E
        tax
        sta     ALTZPOFF
        sta     ROMIN2
        rts

        sta     $85,x
        .byte   $83
        lda     $9D
        sta     $94
        clc
        adc     $82
        sta     $98
        lda     $9E
        sta     $95
        adc     $83
        sta     $99
        lda     #$00
        sta     $9B
        sta     $9C
        sta     $9D
        lda     $8F
        sta     L0080
        jsr     L5099
        bcs     L9FB5
        rts

L9FB5:  jsr     L4DAE
        lda     $91
        asl     a
        ldx     $93
        beq     L9FC1
        adc     #$01
L9FC1:  ldx     $96
        beq     L9FC7
        adc     #$01
L9FC7:  sta     L5159
        sta     L5158
        lda     #$02
        sta     $81
        lda     #$00
        sec
        sbc     $9D
        clc
        adc     $8C
        sta     $8C
        lda     #$00
        sec
        sbc     $9B
        tax
        lda     #$00
        sbc     $9C
        tay
        txa
        clc
        adc     $8A
        tax
        tya
        adc     $8B
        jsr     L4E7F
        sta     $8A
        tya
        rol     a
        cmp     #$07
        ldx     #$01
        bcc     L9FFE
        dex
        sbc     #$07
L9FFE:  .byte   $8E
        .byte   $7C
