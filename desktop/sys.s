        .setcpu "6502"

        .org $2000

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../macros.inc"

L0045           := $0045
L0300           := $0300

L400C           := $400C
L402B           := $402B
L402C           := $402C

L9F8C           := $9F8C
L9FAB           := $9FAB
L9FB0           := $9FB0
LA1F5           := $A1F5
LA24C           := $A24C
LA62F           := $A62F
LA66C           := $A66C
LAB37           := $AB37
LAD46           := $AD46
LB1A0           := $B1A0
LB245           := $B245
LB2FB           := $B2FB
LB3EB           := $B3EB
LB41F           := $B41F
LB462           := $B462
LB4A5           := $B4A5
LB522           := $B522
LB666           := $B666
LB7D0           := $B7D0
LBE50           := $BE50
LBE70           := $BE70

L2000:  jmp     L24B6

L2003:  .word   0
L2005:

        .res    256, 0
        .res    256, 0
        .res    256, 0
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $02,$00,$63,$23,$02,$00,$0D,$0A
        .byte   $00,$0D,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$01,$62,$23,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00
L2372:  .byte   $00
L2373:  .byte   $00

        DEFINE_ON_LINE_PARAMS on_line_params,, $237A

L2378:  .byte   $00,$00
L237A:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, $26F5
        DEFINE_SET_PREFIX_PARAMS set_prefix_params, $2B60
        .byte   $0A
        .byte   $79,$23,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$07,$60,$2B,$C3,$0F
        .byte   $00,$00,$0D,$00,$00,$00,$00,$04
        .byte   $00,$00,$03,$00,$01,$00,$00,$01
        .byte   $00,$03,$F5,$26,$00,$08,$00,$04
        .byte   $00,$C9,$23,$04,$00,$00,$00,$00
        .byte   $00,$00,$00,$01,$00,$04,$00,$21
        .byte   $28,$27,$00,$00,$00,$04,$00,$DF
        .byte   $23,$05,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00

        DEFINE_CLOSE_PARAMS close_params2
        DEFINE_CLOSE_PARAMS close_params3

        .byte   $01,$F5,$26,$03,$F5,$26,$00
        .byte   $0D
L23F4:  .byte   $00,$03,$60,$2B,$00,$11
L23FA:  .byte   $00,$04
L23FC:  .byte   $00,$00,$40
L23FF:  .addr   $7F00
L2401:  .byte   $00,$00,$04
L2404:  .byte   $00,$00,$40
L2407:  .addr   $7F00
L2409:  .byte   $00
L240A:  .byte   $00
L240B:  .byte   $07,$60,$2B,$C3,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$07,$60,$2B,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, $26F5
        .byte   0
        PASCAL_STRING "DESKTOP1"
        PASCAL_STRING "DESKTOP2"
        PASCAL_STRING "DESK.ACC"
        PASCAL_STRING "SELECTOR.LIST"
        PASCAL_STRING "SELECTOR"
        PASCAL_STRING "PRODOS"
L2471:  .byte   $38
L2472:  .byte   $24,$41,$24,$4A,$24,$53,$24,$61
        .byte   $24,$6A,$24
L247D:  PASCAL_STRING "Copying Apple II DeskTop into RAMCard"
L24A3:  .byte   $60
L24A4:  .byte   $20,$00,$03,$00
L24A8:  .byte   $01,$03,$05,$07
L24AC:  .byte   $00
L24AD:  .byte   $AD,$8B,$C0,$18,$FB,$5C,$04,$D0
        .byte   $E0
L24B6:  sta     $C052
        sta     $C057
        sta     $C050
        sta     $C00C
        sta     $C05E
        sta     $C05F
        sta     $C05E
        sta     $C05F
        sta     $C00D
        sta     $C05E
        sta     $C051
        lda     $BF90
        ora     $BF91
        bne     L24EB
        copy16  L2003, $BF90
L24EB:  lda     $BF98
        and     #$30
        cmp     #$30
        beq     L2504
        ldy     #$D0
L24F6:  lda     routine,y
        sta     L0300,y
        dey
        cpy     #$FF
        bne     L24F6
        jmp     L0300

L2504:  lda     #$00
        sta     $C035
        lda     $BF30
        sta     L24AC
        lda     $C083
        lda     $C083
        ldx     #$08
L2517:  lda     $D100,x
        cmp     L24AD,x
        bne     L2526
        dex
        bpl     L2517
        lda     #$00
        beq     L2528
L2526:  lda     #$80
L2528:  sta     $D3AC
        lda     ROMIN2
        ldx     #$00
        jsr     L26A5
        lda     #$00
        sta     L2BE2
        sta     $08
        lda     #$C1
        sta     $09
L253E:  ldx     #$00
L2540:  lda     L24A8,x
        tay
        lda     ($08),y
        cmp     L24A4,x
        bne     L255A
        inx
        cpx     #$04
        bcc     L2540
        ldy     #$FB
        lda     ($08),y
        and     #$01
        beq     L255A
        bne     L2576
L255A:  inc     $09
        lda     $09
        cmp     #$C8
        bcc     L253E
        ldy     $BF31
L2565:  lda     $BF32,y
        cmp     #$3E
        beq     L2572
        dey
        bpl     L2565
        jmp     L26E8

L2572:  lda     #$03
        bne     L257A
L2576:  lda     $09
        and     #$0F
L257A:  sta     L2BE3
        asl     a
        asl     a
        asl     a
        asl     a
        sta     on_line_params::unit_num
        sta     L2373
        MLI_CALL ON_LINE, on_line_params
        beq     L2592
        jmp     L26E8

L2592:  lda     L2373
        cmp     #$30
        beq     L25AD
        sta     write_block_params_unit_num
        sta     write_block_params2_unit_num
        MLI_CALL WRITE_BLOCK, write_block_params
        bne     L25AD
        MLI_CALL WRITE_BLOCK, write_block_params2
L25AD:  lda     L237A
        and     #$0F
        tay
        iny
        sty     L2B60
        lda     #$2F
        sta     L237A
        sta     L2B61
L25BF:  lda     L237A,y
        sta     L2B61,y
        dey
        bne     L25BF
        ldx     #$C0
        jsr     L26A5
        addr_call L26B2, $2B60
        jsr     L2AB2
        bcs     L25E4
        ldx     #$80
        jsr     L26A5
        jsr     L2B57
        jmp     L26E8

L25E4:  lda     $C062
        sta     L2372
        lda     $C061
        bpl     L2603
        jmp     L26E8

L25F2:  PASCAL_STRING "/DeskTop"
L25FB:  .byte   $0A,$00,$00,$C3,$0F,$00,$00,$0D
L2603:  .byte   $20,$CD
        plp
        MLI_CALL GET_PREFIX, get_prefix_params
        beq     L2611
        jmp     L28F4

L2611:  dec     L26F5
        ldx     #$80
        jsr     L26A5
        ldy     L26F5
L261C:  lda     L26F5,y
        sta     L2005,y
        dey
        bpl     L261C
        ldy     L2B60
        ldx     #$00
L262A:  iny
        inx
        lda     L25F2,x
        sta     L2B60,y
        cpx     L25F2
        bne     L262A
        sty     L2B60
        ldx     #$07
L263C:  lda     L25FB,x
        sta     get_file_info_params,x
        dex
        cpx     #$03
        bne     L263C
        jsr     L2A95
        lda     L2B60
        sta     L2378
        lda     #$00
        sta     L2BE1
L2655:  lda     L2BE1
        asl     a
        tax
        lda     L2471,x
        sta     $06
        lda     L2472,x
        sta     $07
        ldy     #$00
        lda     ($06),y
        tay
L2669:  lda     ($06),y
        sta     L2821,y
        dey
        bpl     L2669
        jsr     L2912
        inc     L2BE1
        lda     L2BE1
        cmp     #$06
        bne     L2655
        jmp     L2681

L2681:  lda     L2378
        beq     L268F
        sta     L2B60
        MLI_CALL SET_PREFIX, set_prefix_params
L268F:  jsr     L2B37
        jsr     L2B57
        lda     #$00
        sta     $C071
        ldy     #$17
L269C:  sta     $BF58,y
        dey
        bpl     L269C
        jmp     L3000

L26A5:  lda     $C083
        lda     $C083
        stx     $D3FF
        lda     ROMIN2
        rts

L26B2:  stax    $06
        lda     $C083
        lda     $C083
        ldy     #$00
        lda     ($06),y
        tay
L26C1:  lda     ($06),y
        sta     $D3EE,y
        dey
        bpl     L26C1
        lda     ROMIN2
        rts

L26CD:  stax    $06
        lda     $C083
        lda     $C083
        ldy     #$00
        lda     ($06),y
        tay
L26DC:  lda     ($06),y
        sta     $D3AD,y
        dey
        bpl     L26DC
        lda     ROMIN2
        rts

L26E8:  lda     #$00
        sta     L2BE2
        jmp     L2681

        .byte   0
        ora     a:$00
        .byte   0
L26F5:  .byte   0
L26F6:  .res 299, 0
L2821:  .byte   0
L2822:  .res 15, 0
L2831:  .res 32, 0
L2851:  lda     L2821
        bne     L2857
        rts

L2857:  ldx     #$00
        ldy     L26F5
        lda     #$2F
        sta     L26F6,y
        iny
L2862:  cpx     L2821
        bcs     L2872
        lda     L2822,x
        sta     L26F6,y
        inx
        iny
        jmp     L2862

L2872:  sty     L26F5
        rts

L2876:  ldx     L26F5
        bne     L287C
        rts

L287C:  lda     L26F5,x
        cmp     #$2F
        beq     L288A
        dex
        bne     L287C
        stx     L26F5
        rts

L288A:  dex
        stx     L26F5
        rts

L288F:  lda     L2821
        bne     L2895
        rts

L2895:  ldx     #$00
        ldy     L2B60
        lda     #$2F
        sta     L2B61,y
        iny
L28A0:  cpx     L2821
        bcs     L28B0
        lda     L2822,x
        sta     L2B61,y
        inx
        iny
        jmp     L28A0

L28B0:  sty     L2B60
        rts

L28B4:  ldx     L2B60
        bne     L28BA
        rts

L28BA:  lda     L2B60,x
        cmp     #$2F
        beq     L28C8
        dex
        bne     L28BA
        stx     L2B60
        rts

L28C8:  dex
        stx     L2B60
        rts

        jsr     SLOT3ENTRY
        jsr     HOME
        lda     #$50
        sec
        sbc     L247D
        lsr     a
        sta     $24
        lda     #$0C
        sta     $25
        jsr     VTAB
        ldy     #$00
L28E5:  iny
        lda     L247D,y
        ora     #$80
        jsr     COUT
        cpy     L247D
        bne     L28E5
        rts

L28F4:  lda     #$00
        sta     L2378
        jmp     L26E8

        ldy     #$00
L28FE:  lda     $0200,y
        cmp     #$8D
        beq     L290E
        and     #$7F
        sta     L26F6,y
        iny
        jmp     L28FE

L290E:  sty     L26F5
        rts

L2912:  jsr     L288F
        jsr     L2851
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        cmp     #$46
        beq     L294B
        jmp     L26E8

:       lda     get_file_info_params::file_type
        sta     L2831
        cmp     #$0F
        bne     L2937
        jsr     L2962
        jmp     L2951

L2937:  jsr     L2A95
        cmp     #$47
        bne     L2948
        lda     L2BE1
        bne     L294B
        pla
        pla
        jmp     L2681

L2948:  jsr     L2A11
L294B:  jsr     L2876
        jsr     L28B4
L2951:  rts

        .byte   $03,$F5,$26,$00,$A0
L2957:  .byte   $00,$04
L2959:  .byte   $00,$00,$A4,$00,$02,$00,$00

        DEFINE_CLOSE_PARAMS close_params

L2962:  jsr     L2A95
        cmp     #$47
        beq     L2974
        MLI_CALL OPEN, $2952
        beq     :+
        jsr     L28F4
L2974:  rts

:       lda     L2957
        sta     L2959
        sta     close_params::ref_num
        MLI_CALL READ, $2958
        beq     :+
        jsr     L28F4
        rts

:       lda     #$00
        sta     L2A10
        lda     #$2B
        sta     $06
        lda     #$A4
        sta     $07
L2997:  lda     $A425
        cmp     L2A10
        bne     L29B1
L299F:  MLI_CALL CLOSE, close_params
        beq     L29AA
        jmp     L28F4

L29AA:  jsr     L2876
        jsr     L28B4
        rts

L29B1:  ldy     #$00
        lda     ($06),y
        bne     L29BA
        jmp     L29F6

L29BA:  and     #$0F
        tay
L29BD:  lda     ($06),y
        sta     L2821,y
        dey
        bne     L29BD
        lda     ($06),y
        and     #$0F
        sta     L2821,y
        jsr     L288F
        jsr     L2851
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        jmp     L28F4

:       lda     get_file_info_params::file_type
        sta     L2831
        jsr     L2A95
        cmp     #$47
        beq     L29ED
        jsr     L2A11
L29ED:  jsr     L2876
        jsr     L28B4
        inc     L2A10
L29F6:  lda     $06
        clc
        adc     $A423
        sta     $06
        lda     $07
        adc     #$00
        sta     $07
        lda     $07
        cmp     #$A6
        bcs     L2A0D
        jmp     L2997

L2A0D:  jmp     L299F

L2A10:  .byte   0
L2A11:  MLI_CALL OPEN, $23EF
        beq     L2A1F
        jsr     L28F4
        jmp     L2A11

L2A1F:  MLI_CALL OPEN, $23F5
        beq     L2A2D
        jsr     L28F4
        jmp     L2A1F

L2A2D:  lda     L23F4
        sta     L23FC
        sta     close_params2::ref_num
        lda     L23FA
        sta     L2404
        sta     close_params3::ref_num
L2A3F:  copy16  #$7F00, L23FF
L2A49:  MLI_CALL READ, $23FB
        beq     L2A5B
        cmp     #$4C
        beq     L2A88
        jsr     L28F4
        jmp     L2A49

L2A5B:  copy16  L2401, L2407
        ora     L2401
        beq     L2A88
L2A6C:  MLI_CALL WRITE, $2403
        beq     :+
        jsr     L28F4
        jmp     L2A6C

:       lda     L2409
        cmp     #$00
        bne     L2A88
        lda     L240A
        cmp     #$7F
        beq     L2A3F
L2A88:  MLI_CALL CLOSE, close_params2
        MLI_CALL CLOSE, close_params3
        rts

L2A95:  ldx     #$07
L2A97:  lda     get_file_info_params,x
        sta     L240B,x
        dex
        cpx     #$03
        bne     L2A97
        MLI_CALL CREATE, $240B
        beq     L2AB1
        cmp     #$47
        beq     L2AB1
        jsr     L28F4
L2AB1:  rts

L2AB2:  lda     L24AC
        cmp     #$3E
        bne     L2ABC
        jmp     L2AE6

L2ABC:  and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$C0
        sta     $09
        lda     #$00
        sta     $08
        ldx     #$00
L2ACC:  lda     L24A8,x
        tay
        lda     ($08),y
        cmp     L24A4,x
        bne     L2AE4
        inx
        cpx     #$04
        bcc     L2ACC
        ldy     #$FB
        lda     ($08),y
        and     #$01
        bne     L2AE6
L2AE4:  sec
        rts

L2AE6:  MLI_CALL GET_PREFIX, $2349
        bne     L2AE4
        ldx     $0D00
        ldy     #$00
L2AF3:  inx
        iny
        lda     L2B0D,y
        sta     $0D00,x
        cpy     L2B0D
        bne     L2AF3
        stx     $0D00
        MLI_CALL GET_FILE_INFO, $234C
        beq     L2AE4
        clc
        rts

L2B0D:  PASCAL_STRING "DeskTop2"
        .byte   $03,$1C,$2B,$00,$10
L2B1B:  .byte   $00
        PASCAL_STRING "DeskTop/DESKTOP1"
        .byte   $04
L2B2E:  .byte   0
        .byte   0
        jsr     L0045
        .byte   0
        .byte   0

        DEFINE_CLOSE_PARAMS close_params4

L2B37:  MLI_CALL OPEN, $2B16
        bne     L2B56
        lda     L2B1B
        sta     L2B2E
        sta     close_params4::ref_num
        MLI_CALL WRITE, $2B2D
        bne     L2B56
        MLI_CALL CLOSE, close_params4
L2B56:  rts

L2B57:  addr_call L26CD, $2005
        rts

        .byte   0
L2B60:  .byte   0
L2B61:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

;;; ============================================================
        ;; Relocated to $300

.proc routine
        .org $300

        sys_start := $2000

        MLI_CALL OPEN, open_params
        beq     :+
        jmp     L24A3

:       lda     open_params_ref_num
        sta     read_params_ref_num
        MLI_CALL READ, read_params
        beq     :+
        jmp     L24A3

:       MLI_CALL CLOSE, close_params
        beq     :+
        jmp     L24A3

:       jmp     sys_start

        DEFINE_OPEN_PARAMS open_params, filename, $800
        open_params_ref_num := open_params::ref_num

        DEFINE_READ_PARAMS read_params, sys_start, MLI - sys_start
        read_params_ref_num := read_params::ref_num

        DEFINE_CLOSE_PARAMS close_params

filename:  PASCAL_STRING "FILER"
.endproc

;;; ============================================================

        .org $2BE1

L2BE1:  .byte   $00
L2BE2:  .byte   $00
L2BE3:  .byte   $00

        DEFINE_WRITE_BLOCK_PARAMS write_block_params, $2C00, 0
        write_block_params_unit_num := write_block_params::unit_num
        DEFINE_WRITE_BLOCK_PARAMS write_block_params2, $2E00, 1
        write_block_params2_unit_num := write_block_params2::unit_num

        PAD_TO $2C00

;;; ============================================================
        .assert * = $2C00, error, "Segment length mismatch"
        .incbin "inc/pdload.dat"
        .assert * = $3000, error, "Segment length mismatch"
;;; ============================================================

L3000:  jsr     SLOT3ENTRY
        jsr     HOME
        lda     $C083
        lda     $C083
        lda     $D3FF
        pha
        lda     $C082
        pla
        bne     L3019
        jmp     L3880

L3019:  lda     $C083
        lda     $C083
        ldx     #$17
        lda     #$00
L3023:  sta     $D395,x
        dex
        bpl     L3023
        lda     $C082
        jsr     L37FF
        beq     L3034
        jmp     L30B8

L3034:  lda     #$00
        sta     L30BB
L3039:  lda     L30BB
        cmp     $4400
        beq     L3071
        jsr     L37C5
        stax    $06
        ldy     #$0F
        lda     ($06),y
        bne     L306B
        lda     L30BB
        jsr     L37D2
        jsr     L38B2
        jsr     L3489
        lda     $C083
        lda     $C083
        ldx     L30BB
        lda     #$FF
        sta     $D395,x
        lda     $C082
L306B:  inc     L30BB
        jmp     L3039

L3071:  lda     #$00
        sta     L30BB
L3076:  lda     L30BB
        cmp     $4401
        beq     L30B8
        clc
        adc     #$08
        jsr     L37C5
        stax    $06
        ldy     #$0F
        lda     ($06),y
        bne     L30B2
        lda     L30BB
        clc
        adc     #$08
        jsr     L37D2
        jsr     L38B2
        jsr     L3489
        lda     $C083
        lda     $C083
        lda     L30BB
        clc
        adc     #$08
        tax
        lda     #$FF
        sta     $D395,x
        lda     $C082
L30B2:  inc     L30BB
        jmp     L3076

L30B8:  jmp     L3880

L30BB:  .byte   $00,$03,$C9,$31,$00,$08
L30C1:  .byte   $00,$04
L30C3:  .byte   $00,$CA,$30,$04,$00,$00,$00,$00
        .byte   $00,$00,$00
L30CE:  .byte   $01
L30CF:  .byte   $00,$04
L30D1:  .byte   $00,$50,$31,$27,$00,$00,$00,$04
L30D9:  .byte   $00,$E0,$30
L30DC:  .byte   $05,$00
L30DE:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00
L30E9:  .byte   $01
L30EA:  .byte   $00
L30EB:  .byte   $01
L30EC:  .byte   $00,$01,$C9,$31,$03,$C9,$31,$00
        .byte   $0D
L30F5:  .byte   $00,$03,$88,$31,$00,$1C
L30FB:  .byte   $00,$04
L30FD:  .byte   $00,$00,$11
L3100:  .byte   $00
L3101:  .byte   $0B
L3102:  .byte   $00,$00,$04
L3105:  .byte   $00,$00,$11
L3108:  .byte   $00,$0B
L310A:  .byte   $00
L310B:  .byte   $00
L310C:  .byte   $07,$88,$31
L310F:  .byte   $C3,$00,$00,$00
L3113:  .byte   $00
L3114:  .byte   $00,$00,$00,$00
L3118:  .byte   $07,$88,$31
L311B:  .byte   $00,$00,$00,$00
L311F:  .byte   $00
L3120:  .byte   $00,$00,$00,$00,$00,$00
L3126:  .byte   $0A,$C9,$31
L3129:  .byte   $00,$00,$00,$00
L312D:  .byte   $00
L312E:  .byte   $00,$00,$00,$00,$00,$00
L3134:  .byte   $00,$00,$00,$00,$00
L3139:  .byte   $0A,$88,$31
L313C:  .byte   $00,$00
L313E:  .byte   $00,$00,$00
L3141:  .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$02,$00,$00,$00
L3150:  .byte   $00
L3151:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00
L3160:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $40,$35,$3D,$35,$86,$31,$60,$00
L3188:  .byte   $00
L3189:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L31C9:  .byte   $00
L31CA:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L320A:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L324A:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L328A:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L329A:  .byte   $00
L329B:  .byte   $0D
L329C:  .byte   $00
L329D:  .byte   $00
L329E:  .byte   $00
L329F:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00
L3349:  .byte   $00
L334A:  .byte   $00
L334B:  ldx     L3349
        lda     L329E
        sta     L329F,x
        inx
        stx     L3349
        rts

L3359:  ldx     L3349
        dex
        lda     L329F,x
        sta     L329E
        stx     L3349
        rts

L3367:  lda     #$00
        sta     L329C
        sta     L334A
        MLI_CALL OPEN, $30BC
        beq     L337A
        jmp     L3A43

L337A:  lda     L30C1
        sta     L329D
        sta     L30C3
        MLI_CALL READ, $30C2
        beq     :+
        jmp     L3A43

:       jsr     L33A4
        rts

L3392:  lda     L329D
        sta     L30CF
        MLI_CALL CLOSE, L30CE
        beq     L33A3
        jmp     L3A43

L33A3:  rts

L33A4:  inc     L329C
        lda     L329D
        sta     L30D1
        MLI_CALL READ, $30D0
        beq     L33B8
        jmp     L3A43

L33B8:  inc     L334A
        lda     L334A
        cmp     L329B
        bcc     L33E0
        lda     #$00
        sta     L334A
        lda     L329D
        sta     L30D9
        MLI_CALL READ, $30D8
        beq     :+
        jmp     L3A43

:       lda     L30DE
        cmp     L30DC
        rts

L33E0:  return  #$00

L33E3:  lda     L329C
        sta     L329E
        jsr     L3392
        jsr     L334B
        jsr     L36FB
        jsr     L3367
        rts

L33F6:  jsr     L3392
        jsr     L346E
        jsr     L3720
        jsr     L3359
        jsr     L3367
        jsr     L340C
        jsr     L346B
        rts

L340C:  lda     L329C
        cmp     L329E
        beq     L341A
        jsr     L33A4
        jmp     L340C

L341A:  rts

L341B:  lda     #$00
        sta     L329A
        jsr     L3367
L3423:  jsr     L33A4
        bne     L3455
        lda     L3150
        beq     L3423
        lda     L3150
        sta     L346F
        and     #$0F
        sta     L3150
        lda     #$00
        sta     L3467
        jsr     L3468
        lda     L3467
        bne     L3423
        lda     L3160
        cmp     #$0F
        bne     L3423
        jsr     L33E3
        inc     L329A
        jmp     L3423

L3455:  lda     L329A
        beq     L3463
        jsr     L33F6
        dec     L329A
        jmp     L3423

L3463:  jsr     L3392
        rts

L3467:  .byte   0
L3468:  jmp     L3540

L346B:  jmp     L353D

L346E:  rts

L346F:  .byte   0
        ldy     #$00
L3472:  lda     $0200,y
        cmp     #$8D
        beq     L3482
        and     #$7F
        sta     L31CA,y
        iny
        jmp     L3472

L3482:  sty     L31C9
        rts

        .byte   0
        .byte   0
        .byte   0
L3489:  lda     #$FF
        sta     L353B
        jsr     L3777
        ldx     L3188
        lda     #$2F
        sta     L3189,x
        inc     L3188
        ldy     #$00
        ldx     L3188
L34A1:  iny
        inx
        lda     L328A,y
        sta     L3188,x
        cpy     L328A
        bne     L34A1
        stx     L3188
        MLI_CALL GET_FILE_INFO, $3139
        cmp     #$46
        beq     L34C4
        cmp     #$45
        beq     L34C4
        cmp     #$44
        beq     L34C4
        rts

L34C4:  MLI_CALL GET_FILE_INFO, $3126
        beq     L34DD
        cmp     #$45
        beq     L34D4
        cmp     #$46
        bne     L34DA
L34D4:  jsr     L3A0A
        jmp     L34C4

L34DA:  jmp     L3A43

L34DD:  lda     L312D
        cmp     #$0F
        beq     L34EC
        cmp     #$0D
        beq     L34EC
        lda     #$00
        beq     L34EE
L34EC:  lda     #$FF
L34EE:  sta     L353A
        ldy     #$07
L34F3:  lda     L3126,y
        sta     L3118,y
        dey
        cpy     #$03
        bne     L34F3
        lda     #$C3
        sta     L311B
        jsr     L35A9
        bcc     L350B
        jmp     L3A29

L350B:  ldx     #$03
L350D:  lda     L3134,x
        sta     L3120,x
        dex
        bpl     L350D
        lda     L311F
        cmp     #$0F
        bne     L3522
        lda     #$0D
        sta     L311F
L3522:  MLI_CALL CREATE, $3118
        beq     :+
        jmp     L3A43

:       lda     L353A
        beq     L3537
        jmp     L341B

        .byte   0
        rts

L3537:  jmp     L3643

L353A:  .byte   0
L353B:  .byte   0
L353C:  .byte   0
L353D:  jmp     L375E

L3540:  lda     L3160
        cmp     #$0F
        bne     L3574
        jsr     L36FB
        jsr     L39EE
        MLI_CALL GET_FILE_INFO, $3126
        beq     L3566
        jmp     L3A43
L3558:  jsr     L375E
        jsr     L3720
        lda     #$FF
        sta     L3467
        jmp     L35A4

L3566:  jsr     L3739
        jsr     L36C1
        bcs     L3558
        jsr     L3720
        jmp     L35A4

L3574:  jsr     L3739
        jsr     L36FB
        jsr     L39EE
        MLI_CALL GET_FILE_INFO, $3126
        beq     :+
        jmp     L3A43

:       jsr     L35A9
        bcc     L3590
        jmp     L3A29

L3590:  jsr     L3720
        jsr     L36C1
        bcs     L35A5
        jsr     L36FB
        jsr     L3643
        jsr     L3720
        jsr     L375E
L35A4:  rts

L35A5:  jsr     L375E
        rts

L35A9:  MLI_CALL GET_FILE_INFO, $3126
        beq     :+
        jmp     L3A43

:       lda     #$00
        sta     L3641
        sta     L3642
        MLI_CALL GET_FILE_INFO, $3139
        beq     :+
        cmp     #$46
        beq     L35D7
        jmp     L3A43

:       copy16  L3141, L3641
L35D7:  lda     L3188
        sta     L363F
        ldy     #$01
L35DF:  iny
        cpy     L3188
        bcs     L3635
        lda     L3188,y
        cmp     #$2F
        bne     L35DF
        tya
        sta     L3188
        sta     L3640
        MLI_CALL GET_FILE_INFO, $3139
        beq     :+
        jmp     L3A43

:       sub16   L313E, L3141, L363D
        sub16   L363D, L3641, L363D
        cmp16   L363D, L312E
        bcs     L3635
        sec
        bcs     L3636
L3635:  clc
L3636:  lda     L363F
        sta     L3188
        rts

L363D:  .byte   0,0
L363F:  .byte   0
L3640:  .byte   0
L3641:  .byte   0
L3642:  .byte   0
L3643:  MLI_CALL OPEN, $30F0
        beq     L364E
        jsr     L3A43
L364E:  MLI_CALL OPEN, $30F6
        beq     L3659
        jmp     L3A43

L3659:  lda     L30F5
        sta     L30FD
        sta     L30EA
        lda     L30FB
        sta     L3105
        sta     L30EC
L366B:  lda     #0
        sta     L3100
        lda     #$0B
        sta     L3101
        MLI_CALL READ, $30FC
        beq     :+
        cmp     #$4C
        beq     L36AE
        jmp     L3A43

:       copy16  L3102, L3108
        ora     L3102
        beq     L36AE
        MLI_CALL WRITE, $3104
        beq     :+
        jmp     L3A43

:       lda     L310A
        cmp     #$00
        bne     L36AE
        lda     L310B
        cmp     #$0B
        beq     L366B
L36AE:  MLI_CALL CLOSE, L30EB
        MLI_CALL CLOSE, L30E9
        jsr     L37AE
        jsr     L379D
        rts

L36C1:  ldx     #$07
L36C3:  lda     L3126,x
        sta     L310C,x
        dex
        cpx     #$03
        bne     L36C3
        lda     #$C3
        sta     L310F
        ldx     #$03
L36D5:  lda     L3134,x
        sta     L3114,x
        dex
        bpl     L36D5
        lda     L3113
        cmp     #$0F
        bne     L36EA
        lda     #$0D
        sta     L3113
L36EA:  MLI_CALL CREATE, $310C
        clc
        beq     L36F6
        jmp     L3A43

L36F6:  rts

        .byte   0
        .byte   0
        .byte   0
        .byte   0
L36FB:  lda     L3150
        bne     L3701
        rts

L3701:  ldx     #$00
        ldy     L31C9
        lda     #$2F
        sta     L31CA,y
        iny
L370C:  cpx     L3150
        bcs     L371C
        lda     L3151,x
        sta     L31CA,y
        inx
        iny
        jmp     L370C

L371C:  sty     L31C9
        rts

L3720:  ldx     L31C9
        bne     L3726
        rts

L3726:  lda     L31C9,x
        cmp     #$2F
        beq     L3734
        dex
        bne     L3726
        stx     L31C9
        rts

L3734:  dex
        stx     L31C9
        rts

L3739:  lda     L3150
        bne     L373F
        rts

L373F:  ldx     #$00
        ldy     L3188
        lda     #$2F
        sta     L3189,y
        iny
L374A:  cpx     L3150
        bcs     L375A
        lda     L3151,x
        sta     L3189,y
        inx
        iny
        jmp     L374A

L375A:  sty     L3188
        rts

L375E:  ldx     L3188
        bne     L3764
        rts

L3764:  lda     L3188,x
        cmp     #$2F
        beq     L3772
        dex
        bne     L3764
        stx     L3188
        rts

L3772:  dex
        stx     L3188
        rts

L3777:  ldy     #$00
        sta     L353C
        dey
L377D:  iny
        lda     L324A,y
        cmp     #$2F
        bne     L3788
        sty     L353C
L3788:  sta     L31C9,y
        cpy     L324A
        bne     L377D
        ldy     L320A
L3793:  lda     L320A,y
        sta     L3188,y
        dey
        bpl     L3793
        rts

L379D:  lda     #$07
        sta     L3139
        MLI_CALL SET_FILE_INFO, $3139
        lda     #10
        sta     L3139
        rts

L37AE:  MLI_CALL GET_FILE_INFO, $3126
        bne     :+
        ldx     #$0A
L37B8:  lda     L3129,x
        sta     L313C,x
        dex
        bpl     L37B8
        rts

:       pla
        pla
        rts

L37C5:  jsr     L381C
        clc
        adc     #$02
        tay
        txa
        adc     #$44
        tax
        tya
        rts

L37D2:  jsr     L3836
        clc
        adc     #$82
        tay
        txa
        adc     #$45
        tax
        tya
        rts

        .byte   $00,$00,$03,$E7,$37,$00,$40
L37E6:  .byte   $00
        PASCAL_STRING "Selector.List"
        .byte   $04
L37F6:  .byte   $00,$00,$44,$00,$08,$00,$00

        DEFINE_CLOSE_PARAMS L37FD

L37FF:  MLI_CALL OPEN, $37E1
        bne     L381B
        lda     L37E6
        sta     L37F6
        MLI_CALL READ, $37F5
        MLI_CALL CLOSE, L37FD
        lda     #$00
L381B:  rts

L381C:  ldx     #$00
        stx     L3835
        asl     a
        rol     L3835
        asl     a
        rol     L3835
        asl     a
        rol     L3835
        asl     a
        rol     L3835
        ldx     L3835
        rts

L3835:  .byte   0
L3836:  ldx     #$00
        stx     L3857
        asl     a
        rol     L3857
        asl     a
        rol     L3857
        asl     a
        rol     L3857
        asl     a
        rol     L3857
        asl     a
        rol     L3857
        asl     a
        rol     L3857
        ldx     L3857
        rts

L3857:  .byte   $00,$03,$77,$38,$00,$50
L385D:  .byte   $00,$03,$6E,$38,$00,$54
L3863:  .byte   $00,$04
L3865:  .byte   $00,$00,$20,$00,$04,$00,$00
        DEFINE_CLOSE_PARAMS L386C
        PASCAL_STRING "Selector"
        PASCAL_STRING "DeskTop2"

L3880:  MLI_CALL CLOSE, L386C
        MLI_CALL OPEN, $385E
        beq     :+
        MLI_CALL OPEN, $3858
        beq     L3897
        brk

L3897:  lda     L385D
        jmp     L38A0

:       lda     L3863
L38A0:  sta     L3865
        MLI_CALL READ, $3864
        MLI_CALL CLOSE, $386C
        jmp     L2000

L38B2:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L38BB:  lda     ($06),y
        sta     L324A,y
        dey
        bpl     L38BB
        ldy     L324A
L38C6:  lda     L324A,y
        and     #$7F
        cmp     #$2F
        beq     L38D2
        dey
        bne     L38C6
L38D2:  dey
        sty     L324A
L38D6:  lda     L324A,y
        and     #$7F
        cmp     #$2F
        beq     L38E2
        dey
        bpl     L38D6
L38E2:  ldx     #$00
L38E4:  iny
        inx
        lda     L324A,y
        sta     L328A,x
        cpy     L324A
        bne     L38E4
        stx     L328A
        lda     $C083
        lda     $C083
        ldy     $D3EE
L38FD:  lda     $D3EE,y
        sta     L320A,y
        dey
        bpl     L38FD
        lda     ROMIN2
        rts

        PASCAL_STRING "Copying:"
        PASCAL_STRING "Insert the source disk and press <Return> to continue or <ESC> to cancel"
        PASCAL_STRING "Not enough room in the RAMCard, press <Return> to continue"
        PASCAL_STRING "Error $"
        PASCAL_STRING " occured when copying "
        PASCAL_STRING "The copy was not completed, press <Return> to continue."
L39EE:  jsr     HOME
        lda     #$00
        jsr     VTABZ
        lda     #$00
        jsr     L3ABC
        addr_call L3AA2, $390A
        addr_call L3A9A, $31C9
        rts

L3A0A:  lda     #$00
        jsr     VTABZ
        lda     #$00
        jsr     L3ABC
        addr_call L3AA2, $3913
        jsr     L3ABF
        cmp     #$1B
        bne     L3A25
        jmp     L3AD2

L3A25:  jsr     HOME
        rts

L3A29:  lda     #$00
        jsr     VTABZ
        lda     #$00
        jsr     L3ABC
        addr_call L3AA2, $395C
        jsr     L3ABF
        jsr     HOME
        jmp     L3880

L3A43:  cmp     #$48
        bne     L3A4D
        jsr     L3A29
        jmp     L3AD2

L3A4D:  cmp     #$49
        bne     L3A57
        jsr     L3A29
        jmp     L3AD2

L3A57:  pha
        addr_call L3AA2, $3997
        pla
        jsr     PRBYTE
        addr_call L3AA2, $399F
        addr_call L3A9A, $31C9
        addr_call L3AA2, $39B6
        sta     $C010
L3A7B:  lda     $C000
        bpl     L3A7B
        and     #$7F
        sta     $C010
        cmp     #$4D
        beq     L3A97
        cmp     #$6D
        beq     L3A97
        cmp     #$0D
        bne     L3A7B
        jsr     HOME
        jmp     L3880

L3A97:  jmp     MONZ

L3A9A:  jsr     L3AA2
        lda     #$8D
        jmp     COUT

L3AA2:  stax    $06
        ldy     #$00
        lda     ($06),y
        sta     L3AB8
        beq     L3ABB
L3AAF:  iny
        lda     ($06),y
        ora     #$80
        jsr     COUT
L3AB7:  .byte   $C0
L3AB8:  .byte   0
        bne     L3AAF
L3ABB:  rts

L3ABC:  sta     $24
        rts

L3ABF:  lda     $C000
        bpl     L3ABF
        sta     $C010
        and     #$7F
        cmp     #$1B
        beq     L3AD1
        cmp     #$0D
        bne     L3ABF
L3AD1:  rts

L3AD2:  jsr     HOME
        jmp     L3880

        .byte   0
        .byte   $02
        iny
        inx
        dec     $0200
        bne     L3AD2
        lda     #$A2
        sta     $0200
        rts

        copy16  #$BCBD, $BEC8
        lda     $BF30
        sta     $BEC7
        lda     #$C5
        jsr     LBE70
        bcs     L3AB7
        lda     $BCBD
        and     #$0F
        tax
        inx
        stx     $BCBC
        lda     #$AF
        sta     $BCBD
        jsr     LB7D0
        bcs     L3AB7
        jsr     LA66C
        ldx     #$36
        jsr     L9FB0
        jsr     LAB37
        lda     $BEB9
        ldx     $BEBA
        ldy     #$3D
        jsr     LA62F
        lda     $BEBC
        ldx     $BEBD
        ldy     #$26
        jsr     LA62F
        lda     $BEB9
        sec
        sbc     $BEBC
        pha
        lda     $BEBA
        sbc     $BEBD
        tax
        pla
        ldy     #$10
        jsr     LA62F
        clc
        rts

        ldax    #$0F01
        ldy     $BEBB
        cpy     #$0F
        bne     L3B58
        stx     $BEB8
L3B58:  jsr     LB1A0
        bcs     L3B93
        copy16  #$0259, $BED7
        copy16  #$002B, $BED9
        lda     #$CA
        jsr     LBE70
        bcs     L3B93
        ldx     #$03
L3B7A:  lda     $027C,x
        sta     $BCB7,x
        dex
        bpl     L3B7A
        sta     $BED9
        lda     #$01
        sta     $BCBB
        lda     #$00
        sta     $BEC9
        sta     $BECA
L3B93:  rts

        pha
        lda     $BE56
        and     #$04
        beq     L3B9F
        ldx     $BE6A
L3B9F:  pla
        cpx     $BEB8
        bne     L3BC9
        and     $BEB7
        beq     L3BCD
        lda     $BC88
        sta     $BECF
        lda     #$0F
        sta     $BF94
        lda     #$C8
        jsr     LBE70
        bcs     L3BC8
        lda     $BED0
        sta     $BED6
        sta     $BEDE
        sta     $BEC7
L3BC8:  rts

L3BC9:  lda     #$0D
        sec
        rts

L3BCD:  lda     #$0A
        sec
        rts

L3BD1:  lda     $BEC9
        and     #$FE
        sta     $BEC9
        ldy     $BCBB
        lda     #$00
        cpy     $BCB8
        bcc     L3BED
        tay
        sty     $BCBB
        inc     $BEC9
L3BEA:  inc     $BEC9
L3BED:  dey
        clc
        bmi     L3BF8
        adc     $BCB7
        bcc     L3BED
        bcs     L3BEA
L3BF8:  adc     #$04
        sta     $BEC8
        lda     #$CE
        jsr     LBE70
        bcs     L3C1D
        lda     #$CA
        jsr     LBE70
        bcs     L3C1D
        inc     $BCBB
        lda     $0259
        and     #$F0
        beq     L3BD1
        dec     $BCB9
        bne     L3C1D
        dec     $BCBA
L3C1D:  rts

        jmp     (LBE50)

        jsr     LB41F
        bcs     L3C50
        bit     $BE4E
        bpl     L3C4C
        sta     $BEC7
        lda     #$00
        sta     $BEC8
        sta     $BEC9
        sta     $BECA
        lda     #$CE
        jsr     LBE70
        bcs     L3C45
        lda     $BEC7
        bne     L3CC3
L3C45:  pha
        jsr     LB2FB
        pla
        sec
        rts

L3C4C:  lda     #$14
        sec
        rts

L3C50:  bit     $BE43
        bpl     L3C5A
        jsr     LB2FB
        bcs     L3C63
L3C5A:  lda     $BEB8
        cmp     #$04
        beq     L3C65
        lda     #$0D
L3C63:  sec
        rts

L3C65:  jsr     LA1F5
        bcs     L3C63
        lda     #$00
        sta     $BEC8
        lda     $BC88
        sta     $BEC9
        ldx     $BE4D
        beq     L3C9E
        tay
        txa
        asl     a
        asl     a
        adc     $BC88
        pha
L3C82:  cmp     $BC93,x
        beq     L3C8B
        dex
        bne     L3C82
        .byte   0
L3C8B:  tya
        sta     $BC93,x
        lda     $BC9B,x
        sta     $BEC7
        lda     #$D2
        jsr     LBE70
        bcc     L3C9D
        .byte   0
L3C9D:  pla
L3C9E:  sta     $BC88
        sta     $BECF
        lda     #$00
        sta     $BF94
        lda     #$C8
        jsr     LBE70
        bcc     L3CB7
        pha
        jsr     LA24C
        pla
        sec
        rts

L3CB7:  ldx     $BECF
        stx     $BC9B
        lda     $BED0
        sta     $BCA3
L3CC3:  sta     $BED6
        sta     $BEC7
        sta     $BED2
        ldx     $BEB9
        stx     $BE5F
        ldx     $BEBA
        stx     $BE60
        jsr     LB3EB
        lda     #$7F
        sta     $BED3
        lda     #$C9
        jsr     LBE70
        lda     $BE57
        and     #$03
        beq     L3CF4
        jsr     LB522
        bcc     L3CF4
        jmp     LB245

L3CF4:  lda     #$FF
        sta     $BE43
        clc
        rts

        lda     $BE43
        bpl     L3D0B
        sta     $BE4E
        ldx     #$08
        lda     $BC9B,x
        jsr     LB4A5
L3D0B:  rts

        bcs     L3D47
        lda     $BE56
        and     #$01
        bne     L3D1D
        ldx     #$00
        jsr     L9F8C
        jsr     L9FAB
L3D1D:  clc
        rts

        lda     #$00
        beq     L3D2F
        lda     $BE56
        and     #$01
        beq     L3D2F
        jsr     LB41F
        bcs     L3D37
L3D2F:  sta     $BEDE
        lda     #$CD
        jsr     LBE70
L3D37:  rts

        php
        jsr     LB41F
        bcs     L3D4B
        plp
        lda     #$14
        sec
        rts

L3D43:  lda     #$0D
        sec
        rts

L3D47:  lda     #$06
L3D49:  sec
        rts

L3D4B:  plp
        ldx     #$00
        ldy     #$00
        lda     $BE57
        and     #$10
        bne     L3D5D
        stx     $BE60
        sty     $BE5F
L3D5D:  lda     $BE56
        and     #$04
        eor     #$04
        beq     L3D6B
        lda     #$04
        sta     $BE6A
L3D6B:  bcc     L3D8E
        beq     L3D47
        sta     $BEB8
        lda     #$C3
        sta     $BEB7
        ldx     $BE60
        ldy     $BE5F
        stx     $BEA6
        stx     $BEBA
        sty     $BEA5
        sty     $BEB9
        jsr     LAD46
        bcs     L3D49
L3D8E:  lda     $BEB8
        cmp     $BE6A
        bne     L3D43
        cmp     #$04
        bne     L3DAD
        ldx     $BEBA
        ldy     $BEB9
        lda     $BE57
        and     #$10
        bne     L3DAD
        stx     $BE60
        sty     $BE5F
L3DAD:  jsr     LA1F5
        bcs     L3D49
        lda     $BC88
        sta     $BECF
        lda     #$07
        sta     $BF94
        lda     #$C8
        jsr     LBE70
        bcc     L3DCB
        pha
        jsr     LA24C
        pla
        sec
        rts

L3DCB:  lda     $BEB8
        cmp     #$0F
        beq     L3DD3
        clc
L3DD3:  lda     #$00
        ror     a
        sta     $BE47
        ldx     $BE4D
        lda     $BC88
        sta     $BC94,x
        lda     $BED0
        sta     $BC9C,x
        inc     $BE4D
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        lda     $0280
        ora     $BE47
        sta     $BCFE,x
        and     #$7F
        tay
        cmp     #$1E
        bcc     L3E03
        lda     #$1D
L3E03:  sta     $3A
        lda     $BE5F
        sta     $BCFF,x
        lda     $BE60
        sta     $BD00,x
L3E11:  inx
        lda     $0280,y
        sta     $BD00,x
        dey
        dec     $3A
        bne     L3E11
        clc
        rts

        lda     $BE56
        and     #$01
        bne     L3E2A
        lda     #$10
        sec
        rts

L3E2A:  ldx     $BE4D
        beq     L3E48
        stx     $BE4E
L3E32:  stx     $3B
        lda     $BC9B,x
        jsr     LB462
        bne     L3E43
        ldx     $3B
L3E3E:  lda     $BC9B,x
L3E41:  clc
        rts

L3E43:  ldx     $3B
        dex
        bne     L3E32
L3E48:  lda     $BE43
        bpl     L3E5E
        lda     $BCA3
        jsr     LB462
        bne     L3E5E
        lda     #$FF
        sta     $BE4E
        ldx     #$08
        bne     L3E3E
L3E5E:  lda     #$12
        sec
        rts

        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        lda     $BCFE,x
        sta     $BE47
        and     #$7F
        cmp     $0280
        bne     L3E98
        tay
        cmp     #$1E
        bcc     L3E7C
        lda     #$1D
L3E7C:  sta     $3A
        lda     $BCFF,x
        sta     $BCA4
        lda     $BD00,x
        sta     $BCA5
L3E8A:  inx
        lda     $0280,y
        cmp     $BD00,x
        bne     L3E98
        dey
        dec     $3A
        bne     L3E8A
L3E98:  rts

        lda     $BE56
        and     #$01
        beq     L3EF2
        jsr     LB41F
        bcs     L3E41
        sta     $BEDE
        lda     $BC93,x
        sta     $BC88
        bit     $BE4E
        bmi     L3ECF
        ldy     $BE4D
        pha
        lda     $BC93,y
        sta     $BC93,x
        pla
        sta     $BC93,y
        lda     $BC9B,x
        pha
        lda     $BC9B,y
        sta     $BC9B,x
        pla
        sta     $BC9B,y
L3ECF:  lda     #$00
        sta     $BF94
        lda     #$CC
        jsr     LBE70
        bcs     L3F02
        jsr     LA24C
        bit     $BE4E
        bpl     L3EEE
        pha
        lda     #$00
        sta     $BE43
        sta     $BE4E
        pla
        rts

L3EEE:  dec     $BE4D
        rts

L3EF2:  ldx     $BE4D
        beq     L3F03
        stx     $BE4E
        lda     $BC9B,x
        jsr     LB4A5
        bcc     L3EF2
L3F02:  rts

L3F03:  lda     #$00
        sta     $BEDE
        lda     #$07
        sta     $BF94
        lda     #$CC
        jmp     LBE70

        jsr     LB41F
        bcs     L3F7F
        sta     $BED6
        sta     $BED2
        bit     $BE47
        bmi     L3F80
        .byte   $AD
        .byte   $57
        ldx     $0329,y
        beq     L3F7D
        cmp     #$03
        beq     L3F7D
        and     #$01
        beq     L3F3D
        copy16  $BE65, $BE63
L3F3D:  copy16  #$00EF, $BED9
        sta     $BED7
        lda     #$02
        sta     $BED8
        lda     #$7F
        sta     $BED3
        lda     #$C9
        jsr     LBE70
        bcs     L3F7F
L3F5B:  lda     $BE63
        ora     $BE64
        clc
        beq     L3F80
        lda     #$CA
        jsr     LBE70
        bcs     L3F7F
        lda     $BE63
        sbc     #$00
        sta     $BE63
        lda     $BE64
        sbc     #$00
        sta     $BE64
        bcs     L3F5B
L3F7D:  lda     #$0B
L3F7F:  sec
L3F80:  rts

        copy16  $BCA4, $BCAF
        lda     #$00
        sta     $BCB1
        sta     $BCB2
        sta     $BEC8
        sta     $BEC9
        sta     $BECA
L3F9E:  lsr16   $BE65
        ldx     #$00
        bcc     L3FBF
        clc
L3FA9:  lda     $BCAF,x
        adc     $BEC8,x
        sta     $BEC8,x
        inx
        txa
        eor     #$03
        bne     L3FA9
        bcs     L3FD2
        ldx     $BCB2
        bne     L3FD2
L3FBF:  rol     $BCAF,x
        inx
        txa
        eor     #$04
        bne     L3FBF
        lda     $BE65
        ora     $BE66
        bne     L3F9E
        clc
        rts

L3FD2:  lda     #$02
        sec
        rts

        jsr     LB41F
        bcs     L402B
        sta     $BED6
        sta     $BEC7
        sta     $BED2
        bit     $BE47
        bmi     L402C
        jsr     LB666
        bcs     L402B
        ldx     #$7F
        ldy     #$EF
        lda     $BE57
        and     #$10
        beq     L400C
        ldy     $BE5F
        ldx     $BE60
        .byte   $D0
