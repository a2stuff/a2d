;;; ============================================================
;;; Overlay #2 ???
;;; ============================================================

        .org $A000



.scope

        sta     LA027
        jsr     LAA01
        lda     LA027
        jsr     selector5::L9A47
        jsr     LA802
        jsr     LA6BD
        jsr     LAA2D
        lda     LA027
        jsr     selector5::L9A47
        jsr     LA802
        jsr     LA3F6
        pha
        jsr     LAC5B
        pla
        rts

LA027:
        .byte   $00

        DEFINE_OPEN_PARAMS open_params, $A135, $800
        DEFINE_READ_PARAMS read_params, read_buf, 4
read_buf:
        .res 4, 0
        DEFINE_CLOSE_PARAMS close_params

        DEFINE_READ_PARAMS read_params2, LA0BC, $27
        DEFINE_READ_PARAMS read_params3, LA04C, 5

LA04C:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0


        DEFINE_CLOSE_PARAMS close_params_src
        DEFINE_CLOSE_PARAMS close_params_dst

        .byte   $01,$35,$A1

        DEFINE_OPEN_PARAMS open_params_src, LA135, $D00
        DEFINE_OPEN_PARAMS open_params_dst, LA0F4, $1100

        DEFINE_READ_PARAMS read_params_src, $1500, $B00
        DEFINE_WRITE_PARAMS write_params_dst, $1500, $B00

        DEFINE_CREATE_PARAMS create_params2, LA0F4, $C3

        DEFINE_CREATE_PARAMS create_params, LA0F4,
        .byte   0, 0

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params2, LA135
        .byte   0

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, LA0F4
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
LA0EC:
        .byte   $FF
LA0EE   := * + 1
        .byte   $A4,$FC
LA0F0   := * + 1
        .byte   $A4,$F2
        .byte   $A0,$60
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
        .byte   $0D, $00, $00
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
        yax_call selector5::MLI_WRAPPER, OPEN, open_params
        beq     LA2E9
        jmp     LAB16

LA2E9:  lda     open_params::ref_num
        sta     LA209
        sta     read_params::ref_num
        yax_call selector5::MLI_WRAPPER, READ, read_params
        beq     LA300
        jmp     LAB16

LA300:  jsr     LA319
        rts

LA304:  lda     LA209
        sta     close_params::ref_num
        yax_call selector5::MLI_WRAPPER, CLOSE, close_params
        beq     LA318
        jmp     LAB16

LA318:  rts

LA319:  inc     LA208
        lda     LA209
        sta     read_params2::ref_num
        yax_call selector5::MLI_WRAPPER, READ, read_params2
        beq     LA330
        jmp     LAB16

LA330:  inc     LA2B6
        lda     LA2B6
        cmp     LA207
        bcc     LA35B
        lda     #$00
        sta     LA2B6
        lda     LA209
        sta     read_params3::ref_num
        yax_call selector5::MLI_WRAPPER, READ, read_params3
        beq     LA354
        jmp     LAB16

LA354:  lda     read_params3::trans_count
        cmp     read_params3::request_count
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
        yax_call selector5::MLI_WRAPPER, GET_FILE_INFO, get_file_info_params
        beq     LA41B
        jmp     LAB16

LA41B:  sub16   get_file_info_params::aux_type, get_file_info_params::blocks_used, LA4F3
        cmp16   LA4F3, LA75B
        bcs     LA43F
        jmp     LAACB

LA43F:  ldx     LA0F4
        lda     #'/'
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
        yax_call selector5::MLI_WRAPPER, GET_FILE_INFO, get_file_info_params
        cmp     #$46            ; Error code
        beq     LA475
        cmp     #$45
        beq     LA475
        cmp     #$44
        beq     LA475
        rts

LA475:  yax_call selector5::MLI_WRAPPER, GET_FILE_INFO, get_file_info_params2
        beq     LA491
        cmp     #ERR_VOL_NOT_FOUND
        beq     LA488
        cmp     #$46
        bne     LA48E
LA488:  jsr     LAABD
        jmp     LA475

LA48E:  jmp     LAB16

LA491:  lda     get_file_info_params2::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     LA4A0
        cmp     #ST_LINKED_DIRECTORY
        beq     LA4A0
        lda     #$00
        beq     LA4A2
LA4A0:  lda     #$FF
LA4A2:  sta     LA4F8
        ldy     #$07
LA4A7:  lda     get_file_info_params2,y
        sta     create_params,y
        dey
        cpy     #$02
        bne     LA4A7
        lda     #$C3
        sta     create_params::access
        jsr     LA56D
        bcc     LA4BF
        jmp     LAACB

LA4BF:  ldy     #$11
        ldx     #$0B
LA4C3:  lda     get_file_info_params2,y
        sta     create_params,x
        dex
        dey
        cpy     #$0D
        bne     LA4C3
        lda     create_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     LA4DB
        lda     #$0D
        sta     create_params::storage_type
LA4DB:  yax_call selector5::MLI_WRAPPER, CREATE, create_params
        beq     LA4E9
        jmp     LAB16

LA4E9:  lda     LA4F8
        beq     LA4F5
        jmp     LA396

        .byte   0
        rts

LA4F3:  .byte   0
        .byte   0
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
        yax_call selector5::MLI_WRAPPER, GET_FILE_INFO, get_file_info_params2
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
        yax_call selector5::MLI_WRAPPER, GET_FILE_INFO, get_file_info_params2
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
LA56D:  yax_call selector5::MLI_WRAPPER, GET_FILE_INFO, get_file_info_params2
        beq     LA57B
        jmp     LAB16

LA57B:  lda     #$00
        sta     LA60E
        sta     LA60F
        yax_call selector5::MLI_WRAPPER, GET_FILE_INFO, get_file_info_params
        beq     LA595
        cmp     #ERR_FILE_NOT_FOUND
        beq     LA5A1
        jmp     LAB16

LA595:  copy16  get_file_info_params::blocks_used, LA60E
LA5A1:  lda     LA0F4
        sta     LA60C
        ldy     #$01
LA5A9:  iny
        cpy     LA0F4
        bcs     LA602
        lda     LA0F4,y
        cmp     #'/'
        bne     LA5A9
        tya
        sta     LA0F4
        sta     LA60D
        yax_call selector5::MLI_WRAPPER, GET_FILE_INFO, get_file_info_params
        beq     LA5CB
        jmp     LAB16

LA5CB:  sub16   get_file_info_params::aux_type, get_file_info_params::blocks_used, LA60A
        sub16   LA60A, LA60E, LA60A
        cmp16   LA60A, get_file_info_params2::blocks_used
        bcs     LA602
        sec
        bcs     LA603
LA602:  clc
LA603:  lda     LA60C
        sta     LA0F4
        rts

LA60A:  .byte   0
        .byte   0
LA60C:  .byte   0
LA60D:  .byte   0
LA60E:  .byte   0
LA60F:  .byte   0
LA610:  yax_call selector5::MLI_WRAPPER, OPEN, open_params_src
        beq     LA61E
        jsr     LAB16
LA61E:  yax_call selector5::MLI_WRAPPER, OPEN, open_params_dst
        beq     LA62C
        jmp     LAB16

LA62C:  lda     open_params_src::ref_num
        sta     read_params_src::ref_num
        sta     close_params_src::ref_num
        lda     open_params_dst::ref_num
        sta     write_params_dst::ref_num
        sta     close_params_dst::ref_num
LA63E:  copy16  #$0B00, read_params_src::request_count
        yax_call selector5::MLI_WRAPPER, READ, read_params_src
        beq     LA65A
        cmp     #ERR_END_OF_FILE
        beq     LA687
        jmp     LAB16

LA65A:  copy16  read_params_src::trans_count, write_params_dst::request_count
        ora     read_params_src::trans_count
        beq     LA687
        yax_call selector5::MLI_WRAPPER, WRITE, write_params_dst
        beq     LA679
        jmp     LAB16

LA679:  lda     write_params_dst::trans_count
        cmp     #$00
        bne     LA687
        lda     write_params_dst::trans_count+1
        cmp     #$0B
        beq     LA63E
LA687:  yax_call selector5::MLI_WRAPPER, CLOSE, close_params_dst
        yax_call selector5::MLI_WRAPPER, CLOSE, close_params_src
        rts

LA69A:  ldx     #$07
LA69C:  lda     get_file_info_params2,x
        sta     create_params2,x
        dex
        cpx     #$03
        bne     LA69C
        yax_call selector5::MLI_WRAPPER, CREATE, create_params2
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
LA6E3:  yax_call selector5::MLI_WRAPPER, GET_FILE_INFO, get_file_info_params2
        beq     LA6FF
        cmp     #ERR_VOL_NOT_FOUND
        beq     LA6F6
        cmp     #ERR_FILE_NOT_FOUND
        bne     LA6FC
LA6F6:  jsr     LAABD
        jmp     LA6E3

LA6FC:  jmp     LAB16

LA6FF:  lda     get_file_info_params2::storage_type
        sta     LA724
        cmp     #ST_VOLUME_DIRECTORY
        beq     LA711
        cmp     #ST_LINKED_DIRECTORY
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
        yax_call selector5::MLI_WRAPPER, GET_FILE_INFO, get_file_info_params2
        bne     LA74A
        add16   LA75B, get_file_info_params2::blocks_used, LA75B
LA74A:  inc16   LA759
        jsr     LA782
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
        lda     #'/'
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
        cmp     #'/'
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
        lda     #'/'
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
        cmp     #'/'
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
        cmp     #'/'
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
        and     #CHAR_MASK
        cmp     #'/'
        beq     LA822
        dey
        bne     LA816
LA822:  dey
        sty     LA1B6
LA826:  lda     LA1B6,y
        and     #CHAR_MASK
        cmp     #'/'
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


.proc winfo
window_id:
        .byte   $0B
        .byte   $01,$00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $96,$00
        .byte   $32
        .byte   $00
        .byte   $F4
        .byte   $01,$8C
        .byte   $00
        .byte   $64
        .byte   $00
        .byte   $32
        .byte   $00
        .byte   $00
        .byte   $20,$80,$00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $5E,$01,$46


        .byte   0
        .byte   $FF
        .res    8, $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

        .byte   $01,$01
        .byte   $00
        .byte   $7F
        .addr   $8800
        .addr   0
.endproc

rect1:  DEFINE_RECT 20, 49, 120, 60
pos1:   DEFINE_POINT 24, 59

rect_frame1:
        DEFINE_RECT 4, 2, 348, 68
rect_frame2:
        DEFINE_RECT 5, 3, 347, 67

pos_download:
        DEFINE_POINT 100, 16
str_download:
        PASCAL_STRING "Down load in the RAMCard"

pos_copying:    DEFINE_POINT 20, 32
pt2:    DEFINE_POINT 20, 40

str_copying:
        PASCAL_STRING "Copying:"

rect3:  DEFINE_RECT 18, 24, 346, 32

rect2:  DEFINE_RECT 6, 24, 346, 66

.params setportbits_params
viewloc:        DEFINE_POINT 100, 50
mapbits:        .addr   $2000
mapwidth:       .byte   $80
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, 346, 66
.endparams

        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $01,$01
        .byte   $00
        .byte   $7F
        .byte   $00
        .byte   $88
        .byte   $00
        .byte   $00

str_not_enough_room:
        PASCAL_STRING "Not enough room in the RAMCard to copy the application."
str_click_ok:
        PASCAL_STRING "Click OK to continue."
str_error_download:
        PASCAL_STRING "An error occured during the download."
str_copy_incomplete:
        PASCAL_STRING "The copy wasn't completed, click OK to continue."
str_files_to_copy:
        PASCAL_STRING "Files to be copied in the RAMCard: "
str_files_remaining:
        PASCAL_STRING "Files remaining to be copied: "
str_spaces:
        PASCAL_STRING "    "

LAA01:  MGTK_CALL MGTK::OpenWindow, winfo
        lda     winfo::window_id
        jsr     selector5::L9A15
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::FrameRect, rect_frame1
        MGTK_CALL MGTK::FrameRect, rect_frame2
        MGTK_CALL MGTK::MoveTo, pos_download
        addr_call DrawString, str_download
        rts

LAA2D:  lda     winfo::window_id
        jsr     selector5::L9A15
        MGTK_CALL MGTK::SetPenMode, selector5::pencopy
        MGTK_CALL MGTK::PaintRect, rect2
LAA3F:  dec     LA759
        lda     LA759
        cmp     #$FF
        bne     LAA4C
        dec     LA75A
LAA4C:  jsr     LAC62
        MGTK_CALL MGTK::SetPortBits, setportbits_params
        MGTK_CALL MGTK::SetPenMode, selector5::pencopy
        MGTK_CALL MGTK::PaintRect, rect3
        addr_call selector5::L99DC, LA135
        MGTK_CALL MGTK::MoveTo, pos_copying
        addr_call DrawString, str_copying
        addr_call DrawString, LA135
        MGTK_CALL MGTK::MoveTo, pt2
        addr_call DrawString, str_files_remaining
        addr_call DrawString, LACE6
        addr_call DrawString, str_spaces
        rts

LAA98:  jsr     LAC62
        MGTK_CALL MGTK::SetPortBits, setportbits_params
        MGTK_CALL MGTK::MoveTo, pos_copying
        addr_call DrawString, str_files_to_copy
        addr_call DrawString, $ACE6
        addr_call DrawString, str_spaces
        rts

LAABD:  lda     #$FD            ; ???
        jsr     ShowAlert
        bne     LAAC8
        jsr     selector5::set_watch_cursor
        rts

LAAC8:  jmp     LAC54

LAACB:  lda     winfo::window_id
        jsr     selector5::L9A15
        MGTK_CALL MGTK::SetPenMode, selector5::pencopy
        MGTK_CALL MGTK::PaintRect, rect2
        MGTK_CALL MGTK::MoveTo, pos_copying
        addr_call DrawString, str_not_enough_room
        MGTK_CALL MGTK::MoveTo, pt2
        addr_call DrawString, str_click_ok
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::FrameRect, rect1
        MGTK_CALL MGTK::MoveTo, pos1
        addr_call DrawString, selector5::str_ok_btn
        jsr     LAB61
        jmp     LAC54

LAB16:  lda     winfo::window_id
        jsr     selector5::L9A15
        MGTK_CALL MGTK::SetPenMode, selector5::pencopy
        MGTK_CALL MGTK::PaintRect, rect2
        MGTK_CALL MGTK::MoveTo, pos_copying
        addr_call DrawString, str_error_download
        MGTK_CALL MGTK::MoveTo, pt2
        addr_call DrawString, str_copy_incomplete
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::FrameRect, rect1
        MGTK_CALL MGTK::MoveTo, pos1
        addr_call DrawString, selector5::str_ok_btn
        jsr     LAB61
        jmp     LAC54

LAB61:  jsr     selector5::set_pointer_cursor

event_loop:
        MGTK_CALL MGTK::GetEvent, selector5::event_params
        lda     selector5::event_kind
        cmp     #MGTK::EventKind::button_down
        beq     handle_button_down
        cmp     #MGTK::EventKind::key_down
        bne     event_loop
        lda     $8F7A
        cmp     #CHAR_RETURN
        bne     event_loop
        lda     winfo::window_id
        jsr     selector5::L9A15
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        MGTK_CALL MGTK::PaintRect, rect1
        jsr     selector5::set_watch_cursor
        rts

handle_button_down:
        MGTK_CALL MGTK::FindWindow, selector5::findwindow_params
        lda     selector5::findwindow_which_area
        beq     event_loop
        cmp     #MGTK::Area::content
        bne     event_loop
        lda     $8F7F
        cmp     winfo::window_id
        bne     event_loop
        lda     winfo::window_id
        jsr     selector5::L9A15
        lda     winfo::window_id
        sta     $8F79
        MGTK_CALL MGTK::ScreenToWindow, selector5::screentowindow_params
        MGTK_CALL MGTK::MoveTo, selector5::screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect1
        cmp     #MGTK::inrect_inside
        bne     event_loop
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        jsr     LABE6
        bmi     event_loop
        jsr     selector5::set_watch_cursor
        rts

LABE6:  lda     #$00
        sta     LAC53
LABEB:  MGTK_CALL MGTK::GetEvent, selector5::event_params
        lda     $8F79
        cmp     #$02
        beq     LAC3C
        lda     winfo::window_id
        sta     selector5::screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, selector5::screentowindow_params
        MGTK_CALL MGTK::MoveTo, selector5::screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect1
        cmp     #MGTK::inrect_inside
        beq     LAC1C
        lda     LAC53
        beq     LAC24
        jmp     LABEB

LAC1C:  lda     LAC53
        bne     LAC24
        jmp     LABEB

LAC24:  MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        lda     LAC53
        clc
        adc     #$80
        sta     LAC53
        jmp     LABEB

LAC3C:  lda     LAC53
        beq     LAC44
        return  #$FF

LAC44:  MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        return  #$00

LAC53:  .byte   0
LAC54:  ldx     LA4FB
        txs
        return  #$FF

LAC5B:  MGTK_CALL MGTK::CloseWindow, winfo
        rts

LAC62:  copy16  LA759, LACE2
        ldx     #$07
        lda     #$20
:       sta     LACE6,x
        dex
        bne     :-
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
LACDB   := * + 1
        .byte   $10,$27
        .byte   $E8
        .byte   $03
        .byte   $64
        .byte   $00
        .byte   $0A
        .byte   $00
LACE2:
        .byte   $00
LACE3:
        .byte   $00
LACE4:
        .byte   $00
LACE5:
        .byte   $00
LACE6:
        .byte   $07
LACE8   := * + 1
        .byte   $20,$20,$20
        .byte   $20,$20,$20


        ;; Junk ???

        MGTK_CALL MGTK::PaintRect, $A243
        MGTK_CALL MGTK::PaintRect, $A243
        jsr     $A965           ; ???
        jmp     $AD11

        .byte   $C9

.endscope