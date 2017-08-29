        .setcpu "65C02"
        .org $800

        .include "prodos.inc"
        .include "auxmem.inc"
        .include "a2d.inc"

NULL            := 0

;;; TODO: Figure this one out
L0020           := $0020





start:  jmp     copy2aux

stash_x:.byte   $00
copy2aux:
        tsx
        stx     stash_x
        sta     RAMWRTON
        ldy     #$00
copy_src:
        lda     start,y
copy_dst:
        sta     start,y
        dey
        bne     copy_src
        sta     RAMWRTOFF
        inc     copy_src+2
        inc     copy_dst+2
        sta     RAMWRTON
        lda     copy_dst+2
        cmp     #$14
        bne     copy_src
        sta     RAMWRTON
        sta     RAMRDON
        ldx     #$10
L0831:  lda     L083C,x
        sta     L0020,x
        dex
        bpl     L0831
        jmp     L084C

L083C:  sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     L1000
        sta     RAMRDON
        sta     RAMWRTON
        rts

L084C:  jsr     L09DE
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        sta     RAMRDOFF
        sta     RAMWRTOFF
        ldx     stash_x
        txs
        rts

L0863:  jsr     L08C2
        sta     ALTZPOFF
        MLI_CALL OPEN, open_params
        sta     ALTZPON
        jsr     L08D4
        rts

L0876:  jsr     L08C2
        sta     ALTZPOFF
        MLI_CALL READ, read_params
        sta     ALTZPON
        jsr     L08D4
        rts

L0889:  jsr     L08C2
        sta     ALTZPOFF
        MLI_CALL GET_EOF, get_eof_params
        sta     ALTZPON
        jsr     L08D4
        rts

L089C:  jsr     L08C2
        sta     ALTZPOFF
        MLI_CALL SET_MARK, L08FD
        sta     ALTZPON
        jsr     L08D4
        rts

L08AF:  jsr     L08C2
        sta     ALTZPOFF
        MLI_CALL CLOSE, close_params
        sta     ALTZPON
        jsr     L08D4
        rts

L08C2:  ldy     #$65
        sta     RAMWRTOFF
L08C7:  lda     L08E9,y
        sta     L08E9,y
        dey
        bne     L08C7
        sta     RAMRDOFF
        rts

L08D4:  pha
        php
        sta     RAMWRTON
        ldy     #$65
L08DB:  lda     L08E9,y
        sta     L08E9,y
        dey
        bne     L08DB
        sta     RAMRDON
        plp
        pla
L08E9:  rts


open_params:
        .byte   3               ; param_count
        .addr   L0904           ; pathname
        .addr   $0C00           ; io_buffer
open_ref_num:.byte   0          ; ref_num


read_params:
        .byte   4               ; param_count
read_ref_num:
        .byte   0               ; ref_num
read_db:.addr   $1200           ; data_buffer
        .word   $100            ; request_count
        .word   0               ; trans_count

get_eof_params:
        .byte   2               ; param_count
get_eof_ref_num:
        .byte   0               ; ref_num
        .byte   0,0,0           ; EOF (low, mid, high)

L08FD:  .byte   $02
L08FE:  .byte   $00,$00,$00,$00

close_params:
        .byte   1               ; param_count
close_ref_num:
        .byte   0               ; ref_num

L0904:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00
L0945:  .byte   $00
L0946:  .byte   $00
L0947:  .byte   $00
L0948:  .byte   $00
L0949:  .byte   $00
L094A:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
L0952:  .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
L095A:  .byte   $00
L095B:  .byte   $FA
L095C:  .byte   $01
L095D:  .byte   $00
L095E:  .byte   $00
L095F:  .byte   $00
L0960:  .byte   $00
L0961:  .byte   $00
L0962:  .byte   $00
L0963:  .byte   $00
L0964:  .byte   $00
L0965:  .byte   $00
L0966:  .byte   $00,$00
L0968:  .byte   $00
L0969:  .byte   $00
L096A:  .byte   $00
L096B:  .byte   $00
L096C:  .byte   $00
L096D:  .byte   $00
L096E:  .byte   $00
L096F:  .byte   $00
L0970:  .byte   $00
L0971:  .byte   $00
L0972:  .byte   $00
L0973:  .byte   $00,$00
L0975:  .byte   $00
L0976:  .byte   $00
L0977:  .byte   $64
L0978:  .byte   $00
L0979:  .byte   $00
L097A:  .byte   $00,$00,$00
L097D:  .byte   $00,$00,$00
L0980:  .byte   $00
L0981:  .byte   $00
L0982:  .byte   $00,$00
L0984:  .byte   $00
L0985:  .byte   $00
L0986:  .byte   $00
L0987:  .byte   $00
L0988:  .byte   $00
L0989:  .byte   $00
L098A:  .byte   $00
L098B:  .byte   $00
L098C:  .byte   $00
L098D:  .byte   $00,$00
L098F:  .byte   $00
L0990:  .byte   $00
L0991:  .byte   $00
L0992:  .byte   $00
L0993:  .byte   $00
L0994:  .byte   $64,$02
L0996:  .byte   $00
L0997:  .byte   $10
L0998:  .byte   $00,$C1
L099A:  .byte   $20
L099B:  .byte   $00,$FF
L099D:  .byte   $00,$00,$00,$C8,$00,$33,$00,$00
        .byte   $02,$96,$00
L09A8:  .byte   $0A
L09A9:  .byte   $00
L09AA:  .byte   $1C,$00,$00,$20,$80,$00
L09B0:  .byte   $00
L09B1:  .byte   $00
L09B2:  .byte   $00
L09B3:  .byte   $00
L09B4:  .byte   $00
L09B5:  .byte   $02
L09B6:  .byte   $96
L09B7:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$00,$00,$00,$00,$00,$01
        .byte   $01,$00,$7F,$00,$88,$00,$00
L09CE:  .byte   $0A,$00,$1C,$00,$00,$20,$80,$00
        .byte   $00,$00,$00,$00,$00,$02,$96,$00
L09DE:  sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        lda     #$00
        sta     L0904
        lda     $DF21
        beq     L09F6
        lda     $DF20
        bne     L09F7
L09F6:  rts

L09F7:  asl     a
        tax
        lda     $DFB3,x
        sta     $06
        lda     $DFB4,x
        sta     $07
        ldy     #$00
        lda     ($06),y
        tax
        inc     $06
        bne     L0A0E
        inc     $07
L0A0E:  lda     #$05
        sta     $08
        lda     #$09
        sta     $09
        jsr     L0A72
        lda     #$2F
        ldy     #$00
        sta     ($08),y
        inc     L0904
        inc     $08
        bne     L0A28
        inc     $09
L0A28:  lda     $DF22
        asl     a
        tax
        lda     $DD9F,x
        sta     $06
        lda     $DDA0,x
        sta     $07
        ldy     #$02
        lda     ($06),y
        and     #$70
        bne     L0A40
        rts

L0A40:  clc
        lda     $06
        adc     #$09
        sta     L0996
        lda     $07
        adc     #$00
        sta     L0997
        ldy     #$09
        lda     ($06),y
        tax
        dex
        dex
        clc
        lda     $06
        adc     #$0B
        sta     $06
        bcc     L0A61
        inc     $07
L0A61:  jsr     L0A72
        lda     #$1E
        sta     $27
        lda     #$40
        sta     $28
        jsr     L0020
        jmp     L0A8A

L0A72:  ldy     #$00
L0A74:  lda     ($06),y
        sta     ($08),y
        iny
        inc     L0904
        dex
        bne     L0A74
        tya
        clc
        adc     $08
        sta     $08
        bcc     L0A89
        inc     $09
L0A89:  rts

L0A8A:  lda     #$00
        sta     L096F
        ldx     $8801
        sta     RAMWRTOFF
L0A95:  lda     $8802,x
        sta     L10FF,x
        dex
        bne     L0A95
        sta     RAMWRTON
        jsr     L0863
        lda     open_ref_num
        sta     read_ref_num
        sta     L08FE
        sta     get_eof_ref_num
        sta     close_ref_num
        jsr     L0889
        A2D_CALL $38, L0994
        A2D_CALL $04, L09A8
        jsr     L1088
        jsr     L1198
        jsr     L0E30
        A2D_CALL $2B, NULL
L0AD1:  A2D_CALL $2A, L0970
        lda     L0970
        cmp     #$01
        bne     L0AD1
        A2D_CALL $40, L0971
        lda     L0976
        cmp     #$64
        bne     L0AD1
        lda     L0975
        cmp     #$05
        beq     L0B21
        ldx     L0971
        stx     L0978
        stx     L0980
        ldx     L0972
        stx     L0979
        stx     L0981
        ldx     L0973
        stx     L097A
        stx     L0982
        cmp     #$03
        beq     L0B1B
        cmp     #$04
        beq     L0AD1
        jsr     L0BB4
        jmp     L0AD1

L0B1B:  jsr     L113A
        jmp     L0AD1

L0B21:  A2D_CALL $43, L097D
        lda     L097D
        beq     L0AD1
        jsr     L08AF
        A2D_CALL $39, L0994
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   NULL
        rts

        A2D_CALL $45, L0977
        jsr     L10FD
        jsr     L1088
        lda     #$02
        cmp     L09B5
        bne     L0B54
        lda     #$00
        cmp     L09B4
L0B54:  bcs     L0B73
        lda     #$00
        sta     L09B4
        lda     #$02
        sta     L09B5
        sec
        lda     L09B4
        sbc     L0961
        sta     L09B0
        lda     L09B5
        sbc     L0962
        sta     L09B1
L0B73:  lda     L0998
        ldx     L0961
        cpx     #$00
        bne     L0B89
        ldx     L0962
        cpx     #$02
        bne     L0B89
        and     #$FE
        jmp     L0B8B

L0B89:  ora     #$01
L0B8B:  sta     L0998
        sec
        lda     #$00
        sbc     L0961
        sta     $06
        lda     #$02
        sbc     L0962
        sta     $07
        jsr     L10DF
        sta     L0987
        lda     #$02
        sta     L0986
        A2D_CALL $49, L0986
        jsr     L1198
        jmp     L0DF9

L0BB4:  A2D_CALL $48, L0980
        lda     L0984
        cmp     #$01
        beq     L0BC9
        cmp     #$02
        bne     L0BC8
        jmp     L0C95

L0BC8:  rts

L0BC9:  lda     #$01
        sta     L098A
        sta     L0988
        lda     L0985
        cmp     #$05
        beq     L0BEC
        cmp     #$04
        beq     L0C3E
        cmp     #$03
        beq     L0C11
        cmp     #$01
        beq     L0C2D
        cmp     #$02
        bne     L0BEB
        jmp     L0C60

L0BEB:  rts

L0BEC:  jsr     L0D39
        lda     L0990
        beq     L0C10
        lda     L098F
        sta     L0989
        jsr     L0D7C
        jsr     L0DED
        jsr     L0E30
        lda     L0947
        beq     L0C10
        lda     L0949
        bne     L0C10
        jsr     L0E1D
L0C10:  rts

L0C11:  lda     L099D
        beq     L0C2C
        jsr     L0C84
        sec
        lda     L099D
        sbc     L096E
        bcs     L0C24
        lda     #$00
L0C24:  sta     L0989
        jsr     L0C73
        bcc     L0C11
L0C2C:  rts

L0C2D:  lda     L099D
        beq     L0C3D
        sec
        sbc     #$01
        sta     L0989
        jsr     L0C73
        bcc     L0C2D
L0C3D:  rts

L0C3E:  lda     L099D
        cmp     #$FA
        beq     L0C5F
        jsr     L0C84
        clc
        lda     L099D
        adc     L096E
        bcs     L0C55
        cmp     #$FB
        bcc     L0C57
L0C55:  lda     #$FA
L0C57:  sta     L0989
        jsr     L0C73
        bcc     L0C3E
L0C5F:  rts

L0C60:  lda     L099D
        cmp     #$FA
        beq     L0C72
        clc
        adc     #$01
        sta     L0989
        jsr     L0C73
        bcc     L0C60
L0C72:  rts

L0C73:  jsr     L0D7C
        jsr     L0DED
        jsr     L0E30
        jsr     L0D52
        clc
        bne     L0C83
        sec
L0C83:  rts

L0C84:  lda     L0963
        ldx     #$00
L0C89:  inx
        sec
        sbc     #$32
        cmp     #$32
        bcs     L0C89
        stx     L096E
        rts

L0C95:  lda     #$02
        sta     L098A
        sta     L0988
        lda     L0985
        cmp     #$05
        beq     L0CB5
        cmp     #$04
        beq     L0CE7
        cmp     #$03
        beq     L0CEF
        cmp     #$01
        beq     L0CFE
        cmp     #$02
        beq     L0CF6
        rts

L0CB5:  jsr     L0D39
        lda     L0990
        beq     L0CE6
        lda     L098F
        jsr     L10EC
        lda     $06
        sta     L09B0
        lda     $07
        sta     L09B1
        clc
        lda     L09B0
        adc     L0961
        sta     L09B4
        lda     L09B1
        adc     L0962
        sta     L09B5
        jsr     L0DD1
        jsr     L0E30
L0CE6:  rts

L0CE7:  ldx     #$02
        lda     L099A
        jmp     L0D02

L0CEF:  ldx     #$FE
        lda     #$00
        jmp     L0D02

L0CF6:  ldx     #$01
        lda     L099A
        jmp     L0D02

L0CFE:  ldx     #$FF
        lda     #$00
L0D02:  sta     L0D0C
        stx     L0D15
L0D08:  lda     L099B
L0D0C           := * + 1
        cmp     #$0A
        bne     L0D10
        rts

L0D10:  clc
        lda     L099B
L0D15           := * + 1
        adc     #$01
        bmi     L0D25
        cmp     L099A
        beq     L0D27
        bcc     L0D27
        lda     L099A
        jmp     L0D27

L0D25:  lda     #$00
L0D27:  sta     L099B
        jsr     L0D5E
        jsr     L0DD1
        jsr     L0E30
        jsr     L0D52
        bne     L0D08
        rts

L0D39:  lda     L0971
        sta     L098B
        lda     L0972
        sta     L098C
        lda     L0973
        sta     L098D
        A2D_CALL $4A, L098A
        rts

L0D52:  A2D_CALL $2A, L0970
        lda     L0970
        cmp     #$02
        rts

L0D5E:  lda     L099B
        jsr     L10EC
        clc
        lda     $06
        sta     L09B0
        adc     L0961
        sta     L09B4
        lda     $07
        sta     L09B1
        adc     L0962
        sta     L09B5
        rts

L0D7C:  lda     #$00
        sta     L09B2
        sta     L09B3
        ldx     L0989
L0D87:  beq     L0D9B
        clc
        lda     L09B2
        adc     #$32
        sta     L09B2
        bcc     L0D97
        inc     L09B3
L0D97:  dex
        jmp     L0D87

L0D9B:  clc
        lda     L09B2
        adc     L0963
        sta     L09B6
        lda     L09B3
        adc     L0964
        sta     L09B7
        jsr     L10A5
        lda     #$00
        sta     L096A
        sta     L096B
        ldx     L0989
L0DBC:  beq     L0DD0
        clc
        lda     L096A
        adc     #$05
        sta     L096A
        bcc     L0DCC
        inc     L096B
L0DCC:  dex
        jmp     L0DBC

L0DD0:  rts

L0DD1:  lda     #$02
        sta     L0988
        lda     L09B0
        sta     $06
        lda     L09B1
        sta     $07
        jsr     L10DF
        sta     L0989
        A2D_CALL $4B, L0988
        rts

L0DED:  lda     #$01
        sta     L0988
        A2D_CALL $4B, L0988
        rts

L0DF9:  jsr     UNKNOWN_CALL
        tsb     a:NULL
        A2D_CALL $04, L09A8
        lda     L0998
        ror     a
        bcc     L0E0E
        jsr     L0DD1
L0E0E:  lda     L099D
        sta     L0989
        jsr     L0DED
        jsr     L0E30
        jmp     L0AD1

L0E1D:  A2D_CALL $08, L0952
        A2D_CALL $11, L09B0
        A2D_CALL $08, L094A
        rts

L0E30:  lda     #$00
        sta     L0949
        jsr     L1129
        jsr     L089C
        lda     #$00
        sta     read_db
        sta     $06
        lda     #$12
        sta     read_db+1
        sta     $07
        lda     #$00
        sta     L0945
        sta     L0946
        sta     L0947
        sta     L0960
        sta     L096C
        sta     L096D
        sta     L0948
        lda     #$0A
        sta     L095F
        jsr     L0EDB
L0E68:  lda     L096D
        cmp     L096B
        bne     L0E7E
        lda     L096C
        cmp     L096A
        bne     L0E7E
        jsr     L0E1D
        inc     L0948
L0E7E:  A2D_CALL $0E, L095D
        sec
        lda     #$FA
        sbc     L095D
        sta     L095B
        lda     #$01
        sbc     L095E
        sta     L095C
        jsr     L0EF3
        bcs     L0ED7
        clc
        lda     L0993
        adc     $06
        sta     $06
        bcc     L0EA6
        inc     $07
L0EA6:  lda     L095A
        bne     L0E68
        clc
        lda     L095F
        adc     #$0A
        sta     L095F
        bcc     L0EB9
        inc     L0960
L0EB9:  jsr     L0EDB
        lda     L096C
        cmp     L0968
        bne     L0ECC
        lda     L096D
        cmp     L0969
        beq     L0ED7
L0ECC:  inc     L096C
        bne     L0ED4
        inc     L096D
L0ED4:  jmp     L0E68

L0ED7:  jsr     L1109
        rts

L0EDB:  lda     #$FA
        sta     L095B
        lda     #$01
        sta     L095C
        lda     #$03
        sta     L095D
        lda     #$00
        sta     L095E
        sta     L095A
        rts

L0EF3:  lda     #$FF
        sta     L0F9B
        lda     #$00
        sta     L0F9C
        sta     L0F9D
        sta     L095A
        sta     L0993
        lda     $06
        sta     L0991
        lda     $07
        sta     L0992
L0F10:  lda     L0945
        bne     L0F22
        lda     L0947
        beq     L0F1F
        jsr     L0FF6
        sec
        rts

L0F1F:  jsr     L100C
L0F22:  ldy     L0993
        lda     ($06),y
        and     #$7F
        sta     ($06),y
        inc     L0945
        cmp     #$0D
        beq     L0F86
        cmp     #$20
        bne     L0F41
        sty     L0F9B
        pha
        lda     L0945
        sta     L0946
        pla
L0F41:  cmp     #$09
        bne     L0F48
        jmp     L0F9E

L0F48:  tay
        lda     $8803,y
        clc
        adc     L0F9C
        sta     L0F9C
        bcc     L0F58
        inc     L0F9D
L0F58:  lda     L095C
        cmp     L0F9D
        bne     L0F66
        lda     L095B
        cmp     L0F9C
L0F66:  bcc     L0F6E
        inc     L0993
        jmp     L0F10

L0F6E:  lda     #$00
        sta     L095A
        lda     L0F9B
        cmp     #$FF
        beq     L0F83
        sta     L0993
        lda     L0946
        sta     L0945
L0F83:  inc     L0993
L0F86:  jsr     L0FF6
        ldy     L0993
        lda     ($06),y
        cmp     #$09
        beq     L0F96
        cmp     #$0D
        bne     L0F99
L0F96:  inc     L0993
L0F99:  clc
        rts

L0F9B:  brk
L0F9C:  brk
L0F9D:  brk
L0F9E:  lda     #$01
        sta     L095A
        clc
        lda     L0F9C
        adc     L095D
        sta     L095D
        lda     L0F9D
        adc     L095E
        sta     L095E
        ldx     #$00
L0FB8:  lda     L0FE9,x
        cmp     L095E
        bne     L0FC6
        lda     L0FE8,x
        cmp     L095D
L0FC6:  bcs     L0FD1
        inx
        inx
        cpx     #$0E
        beq     L0FE0
        jmp     L0FB8

L0FD1:  lda     L0FE8,x
        sta     L095D
        lda     L0FE9,x
        sta     L095E
        jmp     L0F86

L0FE0:  lda     #$00
        sta     L095A
        jmp     L0F86

L0FE8:  .byte   $46
L0FE9:  .byte   $00,$8C,$00,$D2,$00,$18,$01,$5E
        .byte   $01,$A4,$01,$EA,$01
L0FF6:  lda     L0948
        beq     L100B
        lda     L0993
        beq     L100B
L1000:  A2D_CALL $19, L0991
        lda     #$01
        sta     L0949
L100B:  rts

L100C:  lda     L0992
        cmp     #$12
        beq     L102B
        ldy     #$00
L1015:  lda     $1300,y
        sta     $1200,y
        iny
        bne     L1015
        dec     L0992
        lda     L0991
        sta     $06
        lda     L0992
        sta     $07
L102B:  lda     #$00
        sta     L0945
        jsr     L103E
        lda     read_db+1
        cmp     #$12
        bne     L103D
        inc     read_db+1
L103D:  rts

L103E:  lda     read_db
        sta     L1052
        lda     read_db+1
        sta     L1053
        lda     #$20
        ldx     #$00
        sta     RAMWRTOFF
L1051:
L1052           := * + 1
L1053           := * + 2
        sta     $1200,x
        inx
        bne     L1051
        sta     RAMWRTON
        lda     #$00
        sta     L0947
        jsr     L0876
        pha
        lda     #$00
        sta     $3C
        sta     $42
        lda     #$FF
        sta     $3E
        lda     read_db+1
        sta     $43
        sta     $3D
        sta     $3F
        sec
        jsr     AUXMOVE
        pla
        beq     L1087
        cmp     #$4C
        beq     L1082
        brk
L1082:  lda     #$01
        sta     L0947
L1087:  rts

L1088:  sec
        lda     L09B4
        sbc     L09B0
        sta     L0961
        lda     L09B5
        sbc     L09B1
        sta     L0962
        sec
        lda     L09B6
        sbc     L09B2
        sta     L0963
L10A5:  lda     L09B6
        sta     L0965
        lda     L09B7
        sta     L0966
        lda     #$00
        sta     L0968
        sta     L0969
L10B9:  lda     L0966
        bne     L10C5
        lda     L0965
        cmp     #$0A
        bcc     L10DE
L10C5:  sec
        lda     L0965
        sbc     #$0A
        sta     L0965
        bcs     L10D3
        dec     L0966
L10D3:  inc     L0968
        bne     L10B9
        inc     L0969
        jmp     L10B9

L10DE:  rts

L10DF:  ldx     #$04
L10E1:  clc
        ror     $07
        ror     $06
        dex
        bne     L10E1
        lda     $06
        rts

L10EC:  sta     $06
        lda     #$00
        sta     $07
        ldx     #$04
L10F4:  clc
        rol     $06
        rol     $07
        dex
        bne     L10F4
        rts

L10FD:  lda     #$15
L10FF:  sta     $27
        lda     #$40
        sta     $28
        jsr     L0020
        rts

L1109:  lda     L096F
        beq     L1128
        lda     #$00
        sta     $3C
        lda     #$7E
        sta     $3E
        lda     #$11
        sta     $3D
        sta     $3F
        lda     #$88
        sta     $43
        lda     #$03
        sta     $42
        sec
        jsr     AUXMOVE
L1128:  rts

L1129:  lda     L096F
        beq     L1139
        ldx     $8801
        lda     #$07
L1133:  sta     $8802,x
        dex
        bne     L1133
L1139:  rts

L113A:  lda     L0972
        cmp     L1185
        bne     L1148
        lda     L0971
        cmp     L1184
L1148:  bcc     L1163
        lda     L096F
        beq     L1158
        dec     L096F
        jsr     L1109
        jmp     L115B

L1158:  inc     L096F
L115B:  jsr     L11BD
        jsr     L0E30
        sec
        rts

L1163:  clc
        rts

fixed_str:      A2D_DEFSTRING "Fixed        "
prop_str:       A2D_DEFSTRING "Proportional"

L1184:  .byte   $00
L1185:  .byte   $00
L1186:  .byte   $00,$00,$00,$20,$80,$00,$00,$00
        .byte   $00,$00,$50,$00,$0A,$00
L1194:  .byte   $00,$00,$0A,$00
L1198:  sec
        lda     L09AA
        sbc     #$0C
        sta     L1186
        clc
        lda     L09A8
        adc     L0961
        pha
        lda     L09A9
        adc     L0962
        tax
        sec
        pla
        sbc     #$32
        sta     L1184
        txa
        sbc     #$00
        sta     L1185
L11BD:  A2D_CALL $06, L1184
        A2D_CALL $0E, L1194
        lda     L096F
        beq     L11D7
        A2D_CALL A2D_TEXT, fixed_str
        jmp     L11DD

L11D7:  A2D_CALL A2D_TEXT, prop_str
L11DD:  ldx     #$0F
L11DF:  lda     L09CE,x
        sta     L09A8,x
        dex
        bpl     L11DF
        A2D_CALL $06, L09A8
        rts
