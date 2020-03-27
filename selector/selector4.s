;;; ============================================================
;;; Invoker
;;; ============================================================

        .org $290

.scope
        jmp     start

        DEFINE_SET_PREFIX_PARAMS set_prefix_params, $220

L0296:  .byte   0

        DEFINE_OPEN_PARAMS open_params, $280, $800, 1

        DEFINE_READ_PARAMS read_params, $2000, $9F00

        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, $280

        .byte   0,0,0

        PASCAL_STRING "BASIC.SYSTEM"

        DEFINE_QUIT_PARAMS quit_params, $EE, $280

L02D0:  MLI_CALL SET_PREFIX, set_prefix_params
        beq     L02DD
        pla
        pla
        jmp     L03CB

L02DD:  rts

L02DE:  MLI_CALL OPEN, open_params
        rts


;;; ============================================================

start:  lda     ROMIN2
        copy16  #$2000, invoke_addr
        ldx     #$16
        lda     #$00
L02F6:  sta     $BF58,x
        dex
        bne     L02F6
        jsr     L02D0
        lda     $0220
        sta     L0296
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     L0310
        jmp     L03CB

L0310:  lda     get_file_info_params::file_type
        cmp     #FT_S16
        bne     L031A
        jmp     L03C2

L031A:  cmp     #FT_BINARY
        bne     L0342

        lda     get_file_info_params::aux_type
        sta     invoke_addr
        sta     read_params::data_buffer

        lda     get_file_info_params::aux_type+1
        sta     invoke_addr+1
        sta     read_params::data_buffer+1

        cmp     #$0C
        bcs     L033B
        lda     #$BB
        sta     open_params::io_buffer+1
        bne     L037A
L033B:  lda     #$08
        sta     open_params::io_buffer+1
        bne     L037A
L0342:  cmp     #FT_BASIC
        bne     L037A
        copy16  #$02BC, open_params::pathname
L0350:  jsr     L02DE
        beq     L0371
        ldy     $0220
L0358:  lda     $0220,y
        cmp     #$2F
        beq     L0367
        dey
        cpy     #$01
        bne     L0358
        jmp     L03CB

L0367:  dey
        sty     $0220
        jsr     L02D0
        jmp     L0350

L0371:  lda     L0296
        sta     $0220
        jmp     L037F

L037A:  jsr     L02DE
        bne     L03CB
L037F:  lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        bne     L03CB
        MLI_CALL CLOSE, close_params
        bne     L03CB
        lda     get_file_info_params::file_type
        cmp     #FT_BASIC
        bne     L03AB
        jsr     L02D0
        ldy     $0280
L03A2:  lda     $0280,y
        sta     $2006,y
        dey
        bpl     L03A2
L03AB:  lda     #$03
        pha
        lda     #$C1
        pha
        jsr     L03C1
        lda     #$01
        sta     $BF6F
        lda     #$CF
        sta     $BF58

        invoke_addr := *+1
        jmp     $2000

L03C1:  rts

L03C2:  jsr     L03C1
        MLI_CALL QUIT, quit_params
L03CB:  rts

        ;; ???

L118B           := $118B

        .byte   $03
        jmp     L118B

        MLI_CALL CLOSE, $102F
        beq     L03DB
        jmp     L118B

L03DB:  jmp     $2000

        jsr     SLOT3ENTRY
        jsr     HOME
        lda     #$0C
        sta     CV
        jsr     VTAB
        lda     #$50
        sec
        .byte   $ED
        .byte   $5E

.endscope
