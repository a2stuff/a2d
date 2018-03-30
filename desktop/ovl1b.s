        .setcpu "6502"

        .include "apple2.inc"
        .include "../macros.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"

L0000           := $0000
L0006           := $0006
L0080           := $0080
L012C           := $012C
L0720           := $0720
L0A65           := $0A65
L0CAF           := $0CAF
L0CED           := $0CED
L0D26           := $0D26
L0D51           := $0D51
L0D5F           := $0D5F
L0DB5           := $0DB5
L0EB2           := $0EB2
L0ED7           := $0ED7
L1020           := $1020
L10FB           := $10FB
L1120           := $1120
L127E           := $127E
L1291           := $1291
L129B           := $129B
L12A5           := $12A5
L12AF           := $12AF
L1521           := $1521
L1721           := $1721
L1B2E           := $1B2E
L2008           := $2008
L2020           := $2020
L202D           := $202D
L202E           := $202E
L2053           := $2053
L2065           := $2065
L2E2E           := $2E2E
L2E33           := $2E33
L322E           := $322E
L3F20           := $3F20
L4210           := $4210
L4214           := $4214
L4324           := $4324
L440A           := $440A
L4420           := $4420
L4519           := $4519
L4520           := $4520
L4B4F           := $4B4F
L5110           := $5110
L51ED           := $51ED
L5220           := $5220
L5307           := $5307
L5345           := $5345
L5507           := $5507
L614E           := $614E
L6162           := $6162
L6163           := $6163
L6177           := $6177
L6369           := $6369
L636F           := $636F
L6520           := $6520
L6544           := $6544
L6552           := $6552
L6556           := $6556
L6562           := $6562
L6564           := $6564
L6572           := $6572
L6874           := $6874
L6877           := $6877
L6964           := $6964
L6C62           := $6C62
L6C63           := $6C63
L6C73           := $6C73
L6D75           := $6D75
L6E49           := $6E49
L6E61           := $6E61
L6E69           := $6E69
L6F43           := $6F43
L6F63           := $6F63
L6F66           := $6F66
L6F67           := $6F67
L6F6E           := $6F6E
L6F73           := $6F73
L6F74           := $6F74
L6F79           := $6F79
L7041           := $7041
L7244           := $7244
L7257           := $7257
L7265           := $7265
L7266           := $7266
L726F           := $726F
L7270           := $7270
L7274           := $7274
L7277           := $7277
L7345           := $7345
L746F           := $746F
L7473           := $7473
L7551           := $7551
L7564           := $7564
L7573           := $7573


        .org $D000

        jmp     LD5E1

LD003:  .byte   0
        ora     ($02,x)
        .byte   $03
        .byte   $04
        ora     L0006
        .byte   $07
LD00B:  .byte   0
LD00C:  .byte   0
LD00D:  .byte   0
LD00E:  .byte   0
LD00F:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $03
        .byte   0
        ora     (L0000,x)
        .byte   $6B
        bne     LD057
        bne     LD01E
LD01E:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $02
        .byte   0
        .byte   $7F
        bne     $D087
        bne     LD02A
LD02A:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $03
        .byte   0
        sty     $D0
        adc     a:$D0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     L0000
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $8F
        bne     LD048
LD048:  .byte   0
        .byte   0
        .byte   0
        ldy     a:$D0
        .byte   0
        .byte   0
        .byte   0
        ldx     a:$D0
        .byte   0
        .byte   0
        .byte   0
LD057:  .byte   $D3
        bne     LD05A
LD05A:  .byte   0
        .byte   0
        .byte   0
        sed
        bne     LD061
        .byte   0
LD061:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     (L0000,x)
        eor     ($71),y
        .byte   $0C
        cmp     ($01),y
        asl     a:$02,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .addr   str_quick_copy
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .addr   str_disk_copy

        PASCAL_STRING "File"
        PASCAL_STRING "Facilities"
        PASCAL_STRING "Apple II DeskTop version 1.1"
        PASCAL_STRING " "
        PASCAL_STRING "Copyright Apple Computer Inc., 1986 "
        PASCAL_STRING "Copyright Version Soft, 1985 - 1986 "
        PASCAL_STRING "All Rights reserved"
        PASCAL_STRING "Quit"

str_quick_copy:
        PASCAL_STRING "Quick Copy "

str_disk_copy:
        PASCAL_STRING "Disk Copy "

        .byte   $03
LD129:  .byte   0
        .byte   $03
LD12B:  .byte   0
LD12C:  .byte   0
LD12D:  .byte   0
LD12E:  .byte   0
LD12F:  .byte   0
LD130:  .byte   0
LD131:  .byte   0
LD132:  .byte   0
LD133:  .byte   0
LD134:  .byte   0
LD135:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD15B:  .byte   0
        lsr     a:$D1,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
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
LD18D:  ora     ($01,x)
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD195:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        stx     L0000,y
        .byte   $32
        .byte   0
        .byte   $F4
        ora     ($8C,x)
LD1A0:  .byte   0
        ora     $1400,y
        .byte   0
        .byte   0
        jsr     L0080
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $F4
        ora     ($96,x)
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
LD1C7:  .byte   $02
        ora     (L0000,x)
        .byte   0
        .byte   0
        .byte   $80
        .byte   0
        .byte   0
        .byte   $03
        .byte   0
        .byte   0
        .byte   0
        .byte   $64
        .byte   0
        .byte   $32
        .byte   0
        stx     L0000,y
        stx     L0000,y
        and     $3200
        .byte   0
        .byte   0
        jsr     L0080
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        stx     L0000,y
        lsr     L0000
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
LD200:  .byte   0
        .byte   $04
        .byte   0
        .byte   $02
        .byte   0
        beq     LD208
        .byte   $94
LD208:  .byte   0
        ora     L0000
        .byte   $03
        .byte   0
        .byte   $EF
        ora     ($93,x)
        .byte   0
        asl     L0000
        .byte   $14
        .byte   0
        inc     $6601
        .byte   0
        asl     L0000
        .byte   $67
        .byte   0
        inc     $9101
        .byte   0
        lsr     $5A01,x
        .byte   0
        .byte   $C2
        ora     ($65,x)
        .byte   0
        .byte   $D2
        .byte   0
        .byte   $5A
        .byte   0
        rol     $01,x
        adc     L0000
        .byte   $63
        ora     ($64,x)
        .byte   0

str_ok_label:
        PASCAL_STRING {"OK            ",CHAR_RETURN}
        .byte   $D7, 0
        .byte   $64
        .byte   0
LD249:  .byte   0
LD24A:  .byte   0
        .byte   $0F
        .byte   0
        .byte   $14
        .byte   0
        .byte   $1C
        .byte   0
        asl     $2E01
        .byte   0
        asl     $2601
        .byte   0
        ldy     $01
        rol     LD200
        .byte   0
        .byte   $44
        .byte   0
        .byte   $D2
        .byte   0
        .byte   $44
        .byte   0
        .byte   $D2
        .byte   0
        .byte   $44
        .byte   0

str_read_drive:
        PASCAL_STRING "Read Drive   D"
str_disk_copy_padded:
        PASCAL_STRING "     Disk Copy    "
str_quick_copy_padded:
        PASCAL_STRING "Quick Copy      "
str_slot_drive_name:
        PASCAL_STRING "Slot, Drive, Name"
str_select_source:
        PASCAL_STRING "Select source disk"
str_select_destination:
        PASCAL_STRING "Select destination disk"
str_formatting:
        PASCAL_STRING "Formatting the disk ...."
str_writing:
        PASCAL_STRING "Writing ....   "
str_reading:
        PASCAL_STRING "Reading ....    "
str_unknown:
        PASCAL_STRING "Unknown"
str_select_quit:
        PASCAL_STRING {"Select Quit from the file menu (",GLYPH_OAPPLE,"Q) to go back to the DeskTop"}
        .byte   0
LD35A:  .byte   $7F
        .byte   0
        .byte   0
LD35D:  .byte   0
        .byte   0
        stx     L0000,y
LD361:  .byte   0
        .byte   0
LD363:  .byte   0
        .byte   0
        .byte   0
        .byte   0
LD367:  .byte   0
LD368:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD36D:  .byte   0
        .byte   0
LD36F:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $47
        .byte   0
LD375:  .byte   0
LD376:  .byte   0
LD377:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD3F7:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD3FF:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD407:  .byte   0
LD408:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD417:  .byte   0
LD418:  .byte   0

str_d:  PASCAL_STRING 0
str_s:  PASCAL_STRING 0
LD41D:  .byte   0
LD41E:  .byte   0
        .byte   0
        .byte   0
LD421:  .byte   0
LD422:  .byte   0
LD423:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD429:  .byte   0
        .byte   $12
        .byte   0
        .byte   $14
        .byte   0
        nop
        ora     ($58,x)
        .byte   0
        .byte   $13
        .byte   0
        ora     $C300,x
        .byte   0
        adc     L0000
LD43A:  .res 18, 0
LD44C:  .byte   0
LD44D:  .byte   0
LD44E:  .byte   0
        .byte   0
        .byte   0
LD451:  .byte   0
        ora     (L0000,x)
str_2_spaces:   PASCAL_STRING "  "
str_7_spaces:   PASCAL_STRING "       "
        bit     $7D01
        .byte   0
        bit     $8701
        .byte   0
        bit     $7301
        .byte   0
        plp
        .byte   0
        adc     $6E00,x
        .byte   0
        adc     $2800,x
        .byte   0
        .byte   $87
        .byte   0
        ror     $8700
        .byte   0
        plp
        .byte   0
        .byte   $73
        .byte   0
        .byte   $14
        .byte   0
        sta     (L0000),y
        .byte   $14
        .byte   0
        dey
        .byte   0
        bcc     LD48A
        .byte   $91
LD48A:  .byte   0
        bit     $9101
        .byte   0
        plp
        .byte   0
        .byte   $64
        .byte   0
        plp
        .byte   0
        .byte   $5A
        .byte   0
LD497:  asl     a
LD498:  .byte   $e

str_blocks_read:
        PASCAL_STRING "Blocks Read: "
str_blocks_written:
        PASCAL_STRING "Blocks Written: "
str_blocks_to_transfer:
        PASCAL_STRING "Blocks to transfer: "
str_source:
        PASCAL_STRING "Source "
str_destination:
        PASCAL_STRING "Destination "
str_slot:
        PASCAL_STRING "Slot "
str_drive:
        PASCAL_STRING "  Drive "

str_dos33_s_d:
        PASCAL_STRING "DOS 3.3 S , D  "

str_dos33_disk_copy:
        PASCAL_STRING "DOS 3.3 disk copy"

str_pascal_disk_copy:
        PASCAL_STRING "Pascal disk copy"

str_prodos_disk_copy:
        PASCAL_STRING "ProDOS disk copy"

str_escape_stop_copy:
        PASCAL_STRING " ESC stop the copy"

str_error_writing:
        PASCAL_STRING "Error when writing block "

str_error_reading:
        PASCAL_STRING "Error when reading block "

        .byte   0, 0
        .byte   $02
        .byte   0
        asl     L0000
        asl     $1E00
        .byte   0
        rol     $7E00,x
        .byte   0
        .byte   $1A
        .byte   0
LD58C:  bmi     LD58E
LD58E:  bmi     LD590
LD590:  rts

        .byte   0
        .byte   0
        .byte   0
        .byte   $03
        .byte   0
        .byte   $07
        .byte   0
        .byte   $0F
        .byte   0
        .byte   $1F
        .byte   0
        .byte   $3F
LD59D:  .byte   0
        .byte   $7F
        .byte   0
        .byte   $7F
        ora     ($7F,x)
        .byte   0
        sei
        .byte   0
        sei
        .byte   0
        bvs     LD5AB
        .byte   $70
LD5AB:  ora     ($01,x)
        .byte   $01
LD5AE:  .byte   0
        .byte   0
        .byte   $7C
        .byte   $03
        .byte   $7C
        .byte   $03
        .byte   $02
        .byte   $04
        .byte   $42
        .byte   $04
        .byte   $32
        .byte   $0C
        .byte   $02
        .byte   $04
        .byte   $02
        .byte   $04
        .byte   $7C
        .byte   $03
        .byte   $7C
LD5C1:  .byte   $03
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $7C
        .byte   $03
        ror     $7E07,x
        .byte   $07
        .byte   $7F
        .byte   $0F
        .byte   $7F
        .byte   $0F
        .byte   $7F
        .byte   $1F
        .byte   $7F
        .byte   $0F
        .byte   $7F
        .byte   $0F
        ror     $7E07,x
        .byte   $07
        .byte   $7C
        .byte   $03
        .byte   0
        .byte   0
        ora     $05
LD5E0:  .byte   0
LD5E1:  jsr     LDF73
        yax_call LDBE0, $30, $D015
        jsr     LDDE0
        copy16  #$0101, LD12B
        yax_call LDBE0, $36, $D12A
        lda     #$01
        sta     LD129
        yax_call LDBE0, $34, $D128
        lda     #$00
        sta     LD451
        sta     LD5E0
        jsr     LDFA0
LD61C:  lda     #$00
        sta     LD367
        sta     LD368
        sta     LD44C
        lda     #$FF
        sta     LD363
        lda     #$81
        sta     LD44D
        lda     #$00
        sta     LD129
        yax_call LDBE0, $34, $D128
        lda     #$01
        sta     LD12C
        yax_call LDBE0, $36, $D12A
        jsr     LDFDD
        yax_call LDBE0, $38, $D1C7
        lda     #$00
        sta     LD429
        lda     #$FF
        sta     LD44C
        jsr     LE16C
        lda     LD5E0
        bne     LD66E
        jsr     LE3A3
LD66E:  jsr     LE28D
        inc     LD5E0
LD674:  jsr     LD986
        bmi     LD674
        beq     LD687
        yax_call LDBE0, $39, $D1C7
        jmp     LD61C

LD687:  lda     LD363
        bmi     LD674
        lda     #$01
        sta     LD129
        yax_call LDBE0, $34, $D128
        lda     LD363
        sta     LD417
        lda     LD1C7
        jsr     LE137
        yax_call LDBE0, $07, LD003
        yax_call LDBE0, $11, $D1E3
        lda     LD18D
        jsr     LE137
        yax_call LDBE0, $07, LD003
        yax_call LDBE0, $11, $D255
        yax_call LDBE0, $0E, $D251
        addr_call LE09A, str_select_destination
        jsr     LE559
        jsr     LE2B1
LD6E6:  jsr     LD986
        bmi     LD6E6
        beq     LD6F9
        yax_call LDBE0, $39, $D1C7
        jmp     LD61C

LD6F9:  lda     LD363
        bmi     LD6E6
        tax
        lda     LD3FF,x
        sta     LD418
        lda     #$00
        sta     LD44C
        lda     LD18D
        jsr     LE137
        yax_call LDBE0, $07, LD003
        yax_call LDBE0, $11, $D211
        yax_call LDBE0, $39, $D1C7
        yax_call LDBE0, $11, $D432
LD734:  addr_call LEB84, $0000
        beq     LD740
        jmp     LD61C

LD740:  lda     #$00
        sta     LD44D
        ldx     LD417
        lda     LD3F7,x
        sta     $0C42
        jsr     L1291
        beq     LD77E
        cmp     #$52
        bne     LD763
        jsr     L0D5F
        jsr     LE674
        jsr     LE559
        jmp     LD7AD

LD763:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $07, LD003
        yax_call LDBE0, $11, $D42A
        jmp     LD734

LD77E:  lda     $1300
        and     #$0F
        bne     LD798
        lda     $1301
        cmp     #$52
        bne     LD763
        jsr     L0D5F
        jsr     LE674
        jsr     LE559
        jmp     LD7AD

LD798:  lda     $1300
        and     #$0F
        sta     $1300
        addr_call LE0FE, $1300
        jsr     LE674
        jsr     LE559
LD7AD:  lda     LD417
        jsr     LE3B8
        jsr     LE5E1
        jsr     LE63F
        ldx     LD418
        lda     LD3F7,x
        tay
        ldx     #$00
        lda     #$01
        jsr     LEB84
        beq     LD7CC
        jmp     LD61C

LD7CC:  ldx     LD418
        lda     LD3F7,x
        sta     $0C42
        jsr     L1291
        beq     LD7E1
        cmp     #$52
        beq     LD7F2
        jmp     LD852

LD7E1:  lda     $1300
        and     #$0F
        bne     LD7F2
        lda     $1301
        cmp     #$52
        beq     LD7F2
        jmp     LD852

LD7F2:  ldx     LD418
        lda     LD3F7,x
        and     #$0F
        beq     LD817
        lda     LD3F7,x
        jsr     L0D26
        ldy     #$FF
        lda     (L0006),y
        beq     LD817
        cmp     #$FF
        beq     LD817
        ldy     #$FE
        lda     (L0006),y
        and     #$08
        bne     LD817
        jmp     LD8A9

LD817:  lda     $1300
        and     #$0F
        bne     LD82C
        ldx     LD418
        lda     LD3F7,x
        and     #$F0
        tax
        lda     #$07
        jmp     LD83C

LD82C:  sta     $1300
        addr_call LE0FE, $1300
        ldx     #$00
        ldy     #$13
        lda     #$02
LD83C:  jsr     LEB84
        cmp     #$01
        beq     LD847
        cmp     #$02
        beq     LD84A
LD847:  jmp     LD61C

LD84A:  lda     LD451
        bne     LD852
        jmp     LD8A9

LD852:  ldx     LD418
        lda     LD3F7,x
        and     #$0F
        beq     LD87C
        lda     LD3F7,x
        jsr     L0D26
        ldy     #$FE
        lda     (L0006),y
        and     #$08
        bne     LD87C
        ldy     #$FF
        lda     (L0006),y
        beq     LD87C
        cmp     #$FF
        beq     LD87C
        lda     #$03
        jsr     LEB84
        jmp     LD61C

LD87C:  yax_call LDBE0, $0E, $D25D
        addr_call LE09A, str_formatting
        jsr     L0CAF
        bcc     LD8A9
        cmp     #$2B
        beq     LD89F
        lda     #$04
        jsr     LEB84
        beq     LD852
        jmp     LD61C

LD89F:  lda     #$05
        jsr     LEB84
        beq     LD852
        jmp     LD61C

LD8A9:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $07, LD003
        yax_call LDBE0, $11, $D211
        lda     LD417
        cmp     LD418
        bne     LD8DF
        tax
        lda     LD3F7,x
        pha
        jsr     L0CED
        pla
        tay
        ldx     #$80
        lda     #$00
        jsr     LEB84
        beq     LD8DF
        jmp     LD61C

LD8DF:  jsr     L0DB5
        lda     #$00
        sta     LD421
        sta     LD422
        lda     #$07
        sta     LD423
        jsr     LE4BF
        jsr     LE4EC
        jsr     LE507
        jsr     LE694
LD8FB:  jsr     LE4A8
        lda     #$00
        jsr     L0ED7
        cmp     #$01
        beq     LD97A
        jsr     LE4EC
        lda     LD417
        cmp     LD418
        bne     LD928
        tax
        lda     LD3F7,x
        pha
        jsr     L0CED
        pla
        tay
        ldx     #$80
        lda     #$01
        jsr     LEB84
        beq     LD928
        jmp     LD61C

LD928:  jsr     LE491
        lda     #$80
        jsr     L0ED7
        bmi     LD955
        bne     LD97A
        jsr     LE507
        lda     LD417
        cmp     LD418
        bne     LD8FB
        tax
        lda     LD3F7,x
        pha
        jsr     L0CED
        pla
        tay
        ldx     #$80
        lda     #$00
        jsr     LEB84
        beq     LD8FB
        jmp     LD61C

LD955:  jsr     LE507
        jsr     L10FB
        ldx     LD417
        lda     LD3F7,x
        jsr     L0CED
        ldx     LD418
        cpx     LD417
        beq     LD972
        lda     LD3F7,x
        jsr     L0CED
LD972:  lda     #$09
        jsr     LEB84
        jmp     LD61C

LD97A:  jsr     L10FB
        lda     #$0A
        jsr     LEB84
        jmp     LD61C

        .byte   0
LD986:  yax_call LDBE0, $03, $D137
        yax_call LDBE0, $04, $D137
LD998:  bit     LD368
        bpl     LD9A7
        dec     LD367
        bne     LD9A7
        lda     #$00
        sta     LD368
LD9A7:  yax_call LDBE0, $2A, $D12D
        lda     LD12D
        cmp     #$01
        bne     LD9BA
        jmp     LDAB1

LD9BA:  cmp     #$03
        bne     LD998
        jmp     LD9D5

LD9C1:  .byte   $83
LD9C2:  .byte   $0C
        .byte   $83
        .byte   $0C
        .byte   $83
        .byte   $0C
        .byte   $83
        .byte   $0C
        .byte   $83
        .byte   $0C
        sty     $0C
        .byte   $3C
        .byte   $DA
        .byte   $77
        .byte   $DA
LD9D1:  .byte   0
        asl     a
        .byte   $0C
        .byte   $10
LD9D5:  lda     LD12F
        bne     LD9E6
        lda     LD12E
        and     #$7F
        cmp     #$1B
        beq     LD9E6
        jmp     LDBFC

LD9E6:  lda     #$01
        sta     LD12F
        copy16  LD12E, LD00E
        yax_call LDBE0, $32, LD00C
LDA00:  ldx     LD00C
        bne     LDA06
        rts

LDA06:  dex
        lda     LD9D1,x
        tax
        ldy     LD00D
        dey
        tya
        asl     a
        sta     LDA3A
        txa
        clc
        adc     LDA3A
        tax
        lda     LD9C1,x
        sta     LDA3A
        lda     LD9C2,x
        sta     LDA3B
        jsr     LDA35
        yax_call LDBE0, $33, LD00C
        jmp     LD986

LDA35:  tsx
        stx     LD00B
        .byte   $4C
LDA3A:  .byte   $34
LDA3B:  .byte   $12
        lda     LD451
        bne     LDA42
        rts

LDA42:  lda     #$00
        sta     LD12C
        yax_call LDBE0, $36, $D12A
        lda     LD451
        sta     LD12B
        lda     #$01
        sta     LD12C
        yax_call LDBE0, $36, $D12A
        lda     #$00
        sta     LD451
        lda     LD18D
        jsr     LE137
        addr_call LE0B4, str_quick_copy_padded
        rts

        lda     LD451
        beq     LDA7D
        rts

LDA7D:  lda     #$00
        sta     LD12C
        yax_call LDBE0, $36, $D12A
        copy16  #$0102, LD12B
        yax_call LDBE0, $36, $D12A
        lda     #$01
        sta     LD451
        lda     LD18D
        jsr     LE137
        addr_call LE0B4, $D278
        rts

LDAB1:  yax_call LDBE0, $40, $D12E
        lda     LD132
        bne     LDAC0
        rts

LDAC0:  cmp     #$01
        bne     LDAD0
        yax_call LDBE0, $31, LD00C
        jmp     LDA00

LDAD0:  cmp     #$02
        bne     LDAD7
        jmp     LDADA

LDAD7:  return  #$FF

LDADA:  lda     LD133
        cmp     LD18D
        bne     LDAE5
        jmp     LDAEE

LDAE5:  cmp     LD1C7
        bne     LDAED
        jmp     LDB55

LDAED:  rts

LDAEE:  lda     LD18D
        sta     LD12D
        jsr     LE137
        yax_call LDBE0, $46, $D12D
        yax_call LDBE0, $0E, $D132
        yax_call LDBE0, $13, $D221
        cmp     #$80
        beq     LDB19
        jmp     LDB2F

LDB19:  yax_call LDBE0, $07, $D005
        yax_call LDBE0, $11, $D221
        jsr     LDD38
        rts

LDB2F:  yax_call LDBE0, $13, $D229
        cmp     #$80
        bne     LDB52
        yax_call LDBE0, $07, $D005
        yax_call LDBE0, $11, $D229
        jsr     LDCAC
        rts

LDB52:  return  #$FF

LDB55:  lda     LD1C7
        sta     LD12D
        jsr     LE137
        yax_call LDBE0, $46, $D12D
        yax_call LDBE0, $0E, $D132
        lsr16   LD134
        lsr16   LD134
        lsr16   LD134
        lda     LD134
        cmp     LD375
        bcc     LDB98
        lda     LD363
        jsr     LE14D
        lda     #$FF
        sta     LD363
        jmp     LDBCA

LDB98:  cmp     LD363
        bne     LDBCD
        bit     LD368
        bpl     LDBC0
        yax_call LDBE0, $07, $D005
        yax_call LDBE0, $11, $D221
        yax_call LDBE0, $11, $D221
        return  #$00

LDBC0:  lda     #$FF
        sta     LD368
        lda     #$64
        sta     LD367
LDBCA:  return  #$FF

LDBCD:  pha
        lda     LD363
        bmi     LDBD6
        jsr     LE14D
LDBD6:  pla
        sta     LD363
        jsr     LE14D
        jmp     LDBC0

LDBE0:  sty     LDBF2
        stax    LDBF3
        sta     RAMRDON
        sta     RAMWRTON
        jsr     MGTK::MLI
LDBF2:  .byte   0
LDBF3:  .byte   0
LDBF4:  .byte   0
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts

LDBFC:  lda     LD12E
        and     #$7F
        cmp     #$44
        beq     LDC09
        cmp     #$64
        bne     LDC2D
LDC09:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $07, $D005
        yax_call LDBE0, $11, $D229
        yax_call LDBE0, $11, $D229
        return  #$01

LDC2D:  cmp     #$0D
        bne     LDC55
        lda     LD18D
        jsr     LE137
        yax_call LDBE0, $07, $D005
        yax_call LDBE0, $11, $D221
        yax_call LDBE0, $11, $D221
        return  #$00

LDC55:  bit     LD44C
        bmi     LDC5D
        jmp     LDCA9

LDC5D:  cmp     #$0A
        bne     LDC85
        lda     LD1C7
        jsr     LE137
        lda     LD363
        bmi     LDC6F
        jsr     LE14D
LDC6F:  inc     LD363
        lda     LD363
        cmp     LD375
        bcc     LDC7F
        lda     #$00
        sta     LD363
LDC7F:  jsr     LE14D
        jmp     LDCA9

LDC85:  cmp     #$0B
        bne     LDCA9
        lda     LD1C7
        jsr     LE137
        lda     LD363
        bmi     LDC9C
        jsr     LE14D
        dec     LD363
        bpl     LDCA3
LDC9C:  ldx     LD375
        dex
        stx     LD363
LDCA3:  lda     LD363
        jsr     LE14D
LDCA9:  return  #$FF

LDCAC:  lda     #$00
        sta     LDD37
LDCB1:  yax_call LDBE0, $2A, $D12D
        lda     LD12D
        cmp     #$02
        beq     LDD14
        lda     LD18D
        sta     LD12D
        yax_call LDBE0, $46, $D12D
        yax_call LDBE0, $0E, $D132
        yax_call LDBE0, $13, $D229
        cmp     #$80
        beq     LDCEE
        lda     LDD37
        beq     LDCF6
        jmp     LDCB1

LDCEE:  lda     LDD37
        bne     LDCF6
        jmp     LDCB1

LDCF6:  yax_call LDBE0, $07, $D005
        yax_call LDBE0, $11, $D229
        lda     LDD37
        clc
        adc     #$80
        sta     LDD37
        jmp     LDCB1

LDD14:  lda     LDD37
        beq     LDD1C
        return  #$FF

LDD1C:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $07, $D005
        yax_call LDBE0, $11, $D229
        return  #$01

LDD37:  .byte   0
LDD38:  lda     #$00
        sta     LDDC3
LDD3D:  yax_call LDBE0, $2A, $D12D
        lda     LD12D
        cmp     #$02
        beq     LDDA0
        lda     LD18D
        sta     LD12D
        yax_call LDBE0, $46, $D12D
        yax_call LDBE0, $0E, $D132
        yax_call LDBE0, $13, $D221
        cmp     #$80
        beq     LDD7A
        lda     LDDC3
        beq     LDD82
        jmp     LDD3D

LDD7A:  lda     LDDC3
        bne     LDD82
        jmp     LDD3D

LDD82:  yax_call LDBE0, $07, $D005
        yax_call LDBE0, $11, $D221
        lda     LDDC3
        clc
        adc     #$80
        sta     LDDC3
        jmp     LDD3D

LDDA0:  lda     LDDC3
        beq     LDDA8
        return  #$FF

LDDA8:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $07, $D005
        yax_call LDBE0, $11, $D221
        return  #$00

LDDC3:  .byte   0
        yax_call LDBE0, $26, $0000
        yax_call LDBE0, $24, $D5AE
        yax_call LDBE0, $25, $0000
        rts

LDDE0:  yax_call LDBE0, $26, $0000
        yax_call LDBE0, $24, $D57C
        yax_call LDBE0, $25, $0000
        rts

LDDFC:  sta     $0C5A
        lda     #$00
        sta     $0C5D
        sta     $0C5E
        copy16  #$1C00, $0C5B
        jsr     L12AF
        beq     LDE19
        return  #$FF

LDE19:  lda     $1C01
        cmp     #$E0
        beq     LDE23
        jmp     LDE4D

LDE23:  lda     $1C02
        cmp     #$70
        beq     LDE31
        cmp     #$60
        beq     LDE31
LDE2E:  return  #$FF

LDE31:  lda     LD375
        asl     a
        asl     a
        asl     a
        asl     a
        clc
        adc     #$77
        tay
        lda     #$D3
        adc     #$00
        tax
        tya
        jsr     LDE9F
        lda     #$80
        sta     LD44E
        return  #$00

LDE4D:  cmp     #$A5
        bne     LDE2E
        lda     $1C02
        cmp     #$27
        bne     LDE2E
        lda     $0C5A
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #$30
        ldx     LD497
        sta     str_dos33_s_d,x
        lda     $0C5A
        and     #$80
        asl     a
        rol     a
        adc     #$31
        ldx     LD498
        sta     str_dos33_s_d,x
        lda     LD375
        asl     a
        asl     a
        asl     a
        asl     a
        tay
        ldx     #$00
LDE83:  lda     str_dos33_s_d,x
        sta     LD377,y
        iny
        inx
        cpx     str_dos33_s_d
        bne     LDE83
        lda     str_dos33_s_d,x
        sta     LD377,y
        lda     #$43
        sta     $0300
        return  #$00

        .byte   0
LDE9F:  stax    L0006
        copy16  #$0002, $0C5D
        jsr     L12AF
        beq     LDEBE
        ldy     #$00
        lda     #$01
        sta     (L0006),y
        iny
        lda     #$20
        sta     (L0006),y
        rts

LDEBE:  ldy     #$00
        ldx     #$00
LDEC2:  lda     $1C06,x
        sta     (L0006),y
        inx
        iny
        cpx     $1C06
        bne     LDEC2
        lda     $1C06,x
        sta     (L0006),y
        lda     $1C06
        cmp     #$0F
        bcs     LDEE6
        ldy     #$00
        lda     (L0006),y
        clc
        adc     #$01
        sta     (L0006),y
        lda     (L0006),y
        tay
LDEE6:  lda     #$3A
        sta     (L0006),y
        rts

LDEEB:  stax    LDF6F
        ldx     #$07
        lda     #$20
LDEF5:  sta     str_7_spaces,x
        dex
        bne     LDEF5
        lda     #$00
        sta     LDF72
        ldy     #$00
        ldx     #$00
LDF04:  lda     #$00
        sta     LDF71
LDF09:  lda     LDF6F
        cmp     LDF67,x
        lda     LDF70
        sbc     LDF68,x
        bpl     LDF45
        lda     LDF71
        bne     LDF25
        bit     LDF72
        bmi     LDF25
        lda     #$20
        bne     LDF38
LDF25:  cmp     #$0A
        bcc     LDF2F
        clc
        adc     #$37
        jmp     LDF31

LDF2F:  adc     #$30
LDF31:  pha
        lda     #$80
        sta     LDF72
        pla
LDF38:  sta     str_7_spaces+2,y
        iny
        inx
        inx
        cpx     #$08
        beq     LDF5E
        jmp     LDF04

LDF45:  inc     LDF71
        lda     LDF6F
        sec
        sbc     LDF67,x
        sta     LDF6F
        lda     LDF70
        sbc     LDF68,x
        sta     LDF70
        jmp     LDF09

LDF5E:  lda     LDF6F
        ora     #$30
        sta     str_7_spaces+2,y
        rts

LDF67:  .byte   $10
LDF68:  .byte   $27
        inx
        .byte   $03
        .byte   $64
        .byte   0
        asl     a
        .byte   0
LDF6F:  .byte   0
LDF70:  .byte   0
LDF71:  .byte   0
LDF72:  .byte   0
LDF73:  ldx     $BF31
LDF76:  lda     $BF32,x
        cmp     #$BF
        beq     LDF81
        dex
        bpl     LDF76
        rts

LDF81:  lda     $BF33,x
        sta     $BF32,x
        cpx     $BF31
        beq     LDF90
        inx
        jmp     LDF81

LDF90:  dec     $BF31
        rts

        inc     $BF31
        ldx     $BF31
        lda     #$BF
        sta     $BF32,x
        rts

LDFA0:  yax_call LDBE0, $38, $D18D
        lda     LD18D
        jsr     LE137
        yax_call LDBE0, $07, $D005
        yax_call LDBE0, $12, $D201
        yax_call LDBE0, $12, $D209
        yax_call LDBE0, $03, $D137
        yax_call LDBE0, $04, $D137
        rts

LDFDD:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $07, LD003
        yax_call LDBE0, $11, $D211
        yax_call LDBE0, $11, $D219
        lda     LD451
        bne     LE00D
        addr_call LE0B4, str_quick_copy_padded
        jmp     LE014

LE00D:  addr_call LE0B4, $D278
LE014:  yax_call LDBE0, $07, $D005
        yax_call LDBE0, $12, $D221
        yax_call LDBE0, $12, $D229
        jsr     LE078
        jsr     LE089
        yax_call LDBE0, $0E, $D24D
        addr_call LE09A, str_slot_drive_name
        yax_call LDBE0, $0E, $D251
        addr_call LE09A, str_select_source
        yax_call LDBE0, $0E, $D47F
        addr_call LE09A, str_select_quit
        yax_call LDBE0, $03, $D137
        yax_call LDBE0, $04, $D137
        rts

LE078:  yax_call LDBE0, $0E, $D231
        addr_call LE09A, str_ok_label
        rts

LE089:  yax_call LDBE0, $0E, $D245
        addr_call LE09A, str_read_drive
        rts

LE09A:  stax    $0A
        ldy     #$00
        lda     ($0A),y
        sta     $0C
        inc16   $0A
LE0AA:  yax_call LDBE0, $19, $000A
        rts

LE0B4:  stax    L0006
        ldy     #$00
        lda     (L0006),y
        sta     $08
        inc16   L0006
LE0C4:  yax_call LDBE0, $18, $0006
        lsr16   $09
        lda     #$01
        sta     LE0FD
        lda     #$F4
        lsr     LE0FD
        ror     a
        sec
        sbc     $09
        sta     LD249
        lda     LE0FD
        sbc     $0A
        sta     LD24A
        yax_call LDBE0, $0E, $D249
        yax_call LDBE0, $19, $0006
        rts

LE0FD:  .byte   0
LE0FE:  stx     $0B
        sta     $0A
        ldy     #$00
        lda     ($0A),y
        tay
        bne     LE10A
        rts

LE10A:  dey
        beq     LE10F
        bpl     LE110
LE10F:  rts

LE110:  lda     ($0A),y
        and     #$7F
        cmp     #$2F
        beq     LE11C
        cmp     #$2E
        bne     LE120
LE11C:  dey
        jmp     LE10A

LE120:  iny
        lda     ($0A),y
        and     #$7F
        cmp     #$41
        bcc     LE132
        cmp     #$5B
        bcs     LE132
        clc
        adc     #$20
        sta     ($0A),y
LE132:  dey
        jmp     LE10A

        .byte   0
LE137:  sta     LD15B
        yax_call LDBE0, $3C, $D15B
        yax_call LDBE0, $04, $D15E
        rts

LE14D:  asl     a
        asl     a
        asl     a
        sta     LD35D
        clc
        adc     #$07
        sta     LD361
        yax_call LDBE0, $07, $D005
        yax_call LDBE0, $11, $D35B
        rts

LE16C:  lda     #$00
        sta     LD44E
        sta     $0C42
        jsr     L1291
        beq     LE17A
        .byte   0
LE17A:  lda     #$00
        sta     LE263
        sta     LD375
LE182:  lda     #$13
        sta     $07
        lda     #$00
        sta     L0006
        sta     LE264
        lda     LE263
        asl     a
        rol     LE264
        asl     a
        rol     LE264
        asl     a
        rol     LE264
        asl     a
        rol     LE264
        clc
        adc     L0006
        sta     L0006
        lda     LE264
        adc     $07
        sta     $07
        ldy     #$00
        lda     (L0006),y
        and     #$0F
        bne     LE20D
        lda     (L0006),y
        beq     LE1CC
        iny
        lda     (L0006),y
        cmp     #$28
        bne     LE1CD
        dey
        lda     (L0006),y
        jsr     LE265
        lda     #$28
        bcc     LE1CD
        jmp     LE255

LE1CC:  rts

LE1CD:  pha
        ldy     #$00
        lda     (L0006),y
        jsr     LE285
        ldx     LD375
        sta     LD3F7,x
        pla
        cmp     #$52
        bne     LE1EA
        lda     LD3F7,x
        and     #$F0
        jsr     LDDFC
        beq     LE207
LE1EA:  lda     LD375
        asl     a
        asl     a
        asl     a
        asl     a
        tay
        ldx     #$00
LE1F4:  lda     str_unknown,x
        sta     LD377,y
        iny
        inx
        cpx     str_unknown
        bne     LE1F4
        lda     str_unknown,x
        sta     LD377,y
LE207:  inc     LD375
        jmp     LE255

LE20D:  ldx     LD375
        ldy     #$00
        lda     (L0006),y
        and     #$70
        cmp     #$30
        bne     LE21D
        jmp     LE255

LE21D:  ldy     #$00
        lda     (L0006),y
        jsr     LE285
        ldx     LD375
        sta     LD3F7,x
        lda     LD375
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        ldy     #$00
        lda     (L0006),y
        and     #$0F
        sta     LD377,x
        sta     LE264
LE23E:  inx
        iny
        cpy     LE264
        beq     LE24D
        lda     (L0006),y
        sta     LD377,x
        jmp     LE23E

LE24D:  lda     (L0006),y
        sta     LD377,x
        inc     LD375
LE255:  inc     LE263
        lda     LE263
        cmp     #$08
        beq     LE262
        jmp     LE182

LE262:  rts

LE263:  .byte   0
LE264:  .byte   0
LE265:  and     #$F0
        sta     LE28C
        ldx     $BF31
LE26D:  lda     $BF32,x
        and     #$F0
        cmp     LE28C
        beq     LE27C
        dex
        bpl     LE26D
LE27A:  sec
        rts

LE27C:  lda     $BF32,x
        and     #$0F
        bne     LE27A
        clc
        rts

LE285:  jsr     LE265
        lda     $BF32,x
        rts

LE28C:  .byte   0
LE28D:  lda     LD1C7
        jsr     LE137
        lda     #$00
        sta     LE2B0
LE298:  lda     LE2B0
        jsr     LE39A
        lda     LE2B0
        jsr     LE31B
        inc     LE2B0
        lda     LE2B0
        cmp     LD375
        bne     LE298
        rts

LE2B0:  .byte   0
LE2B1:  lda     LD1C7
        jsr     LE137
        lda     LD363
        asl     a
        tax
        lda     LD407,x
        sta     LE318
        lda     LD408,x
        sta     LE319
        lda     LD375
        sta     LD376
        lda     #$00
        sta     LD375
        sta     LE317
LE2D6:  lda     LE317
        asl     a
        tax
        lda     LD407,x
        cmp     LE318
        bne     LE303
        lda     LD408,x
        cmp     LE319
        bne     LE303
        lda     LE317
        ldx     LD375
        sta     LD3FF,x
        lda     LD375
        jsr     LE39A
        lda     LE317
        jsr     LE31B
        inc     LD375
LE303:  inc     LE317
        lda     LE317
        cmp     LD376
        beq     LE311
        jmp     LE2D6

LE311:  lda     #$FF
        sta     LD363
        rts

LE317:  .byte   0
LE318:  .byte   0
LE319:  .byte   0
        .byte   0
LE31B:  sta     LE399
        lda     #$08
        sta     LD36D
        yax_call LDBE0, $0E, $D36D
        ldx     LE399
        lda     LD3F7,x
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #'0'
        sta     str_s + 1
        addr_call LE09A, str_s
        lda     #$28
        sta     LD36D
        yax_call LDBE0, $0E, $D36D
        ldx     LE399
        lda     LD3F7,x
        and     #$80
        asl     a
        rol     a
        clc
        adc     #'1'
        sta     str_d + 1
        addr_call LE09A, str_d
        lda     #$41
        sta     LD36D
        yax_call LDBE0, $0E, $D36D
        lda     LE399
        asl     a
        asl     a
        asl     a
        asl     a
        clc
        adc     #$77
        sta     L0006
        lda     #$D3
        adc     #$00
        sta     $07
        lda     L0006
        ldx     $07
        jsr     LE0FE
        lda     L0006
        ldx     $07
        jsr     LE09A
        rts

LE399:  .byte   0
LE39A:  asl     a
        asl     a
        asl     a
        adc     #$08
        sta     LD36F
        rts

LE3A3:  lda     #$00
        sta     LE3B7
LE3A8:  jsr     LE3B8
        inc     LE3B7
        lda     LE3B7
        cmp     LD375
        bne     LE3A8
        rts

LE3B7:  .byte   0
LE3B8:  pha
        tax
        lda     LD3F7,x
        and     #$0F
        beq     LE3CC
        lda     LD3F7,x
        and     #$F0
        jsr     L0D26
        jmp     LE3DA

LE3CC:  pla
        asl     a
        tax
        lda     #$18
        sta     LD407,x
        lda     #$01
        sta     LD408,x
        rts

LE3DA:  ldy     #$07
        lda     (L0006),y
        bne     LE3E3
        jmp     LE44A

LE3E3:  lda     #$00
        sta     LE448
        ldy     #$FC
        lda     (L0006),y
        sta     LE449
        beq     LE3F6
        lda     #$80
        sta     LE448
LE3F6:  ldy     #$FD
        lda     (L0006),y
        tax
        bne     LE402
        bit     LE448
        bpl     LE415
LE402:  stx     LE448
        pla
        asl     a
        tax
        lda     LE448
        sta     LD407,x
        lda     LE449
        sta     LD408,x
        rts

LE415:  ldy     #$FF
        lda     (L0006),y
        sta     L0006
        lda     #$00
        sta     $42
        sta     $44
        sta     $45
        sta     $46
        sta     $47
        pla
        pha
        tax
        lda     LD3F7,x
        and     #$F0
        sta     $43
        jsr     LE445
        stx     LE448
        pla
        asl     a
        tax
        lda     LE448
        sta     LD407,x
        tya
        sta     LD408,x
        rts

LE445:  jmp     (L0006)

LE448:  .byte   0
LE449:  .byte   0
LE44A:  ldy     #$FF
        lda     (L0006),y
        clc
        adc     #$03
        sta     L0006
        pla
        pha
        tax
        lda     LD3F7,x
        and     #$F0
        jsr     L0D51
        sta     LE47D
        jsr     LE477
        .byte   0
        .byte   $7C
        cpx     $68
        asl     a
        tax
        lda     LE482
        sta     LD407,x
        lda     LE483
        sta     LD408,x
        rts

LE477:  jmp     (L0006)

        .byte   0
        .byte   0
        .byte   $03
LE47D:  ora     ($81,x)
        cpx     L0000
        .byte   0
LE482:  .byte   0
LE483:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LE491:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $0E, $D261
        addr_call LE09A, str_writing
        rts

LE4A8:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $0E, $D265
        addr_call LE09A, str_reading
        rts

LE4BF:  lda     LD18D
        jsr     LE137
        lda     LD417
        asl     a
        tay
        lda     LD408,y
        tax
        lda     LD407,y
        jsr     LDEEB
        yax_call LDBE0, $0E, $D467
        addr_call LE09A, str_blocks_to_transfer
        addr_call LE09A, str_7_spaces
        rts

LE4EC:  jsr     LE522
        yax_call LDBE0, $0E, $D45F
        addr_call LE09A, str_blocks_read
        .byte   $A9
LE500:  .byte   $57
        ldx     #$D4
        jsr     LE09A
        rts

LE507:  jsr     LE522
        yax_call LDBE0, $0E, $D463
        addr_call LE09A, str_blocks_written
        addr_call LE09A, str_7_spaces
        rts

LE522:  lda     LD18D
        jsr     LE137
        lda     LD422
        sta     LE558
        lda     LD421
        asl     a
        rol     LE558
        asl     a
        rol     LE558
        asl     a
        rol     LE558
        ldx     LD423
        clc
        adc     LE550,x
        tay
        lda     LE558
        adc     #$00
        tax
        tya
        jsr     LDEEB
        rts

LE550:  .byte   $07
        asl     $05
        .byte   $04
        .byte   $03
        .byte   $02
        ora     (L0000,x)
LE558:  .byte   0
LE559:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $0E, $D46B
        addr_call LE09A, str_source
        ldx     LD417
        lda     LD3F7,x
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #'0'
        sta     str_s + 1
        ldx     LD417
        lda     LD3F7,x
        and     #$80
        clc
        rol     a
        rol     a
        clc
        adc     #'1'
        sta     str_d + 1
        yax_call LDBE0, $0E, $D46F
        addr_call LE09A, str_slot
        addr_call LE09A, str_s
        addr_call LE09A, str_drive
        addr_call LE09A, str_d
        bit     LD44D
        bpl     LE5C6
        bvc     LE5C5
        lda     LD44D
        and     #$0F
        beq     LE5C6
LE5C5:  rts

LE5C6:  addr_call LE09A, str_2_spaces
        ldx     $1300
LE5D0:  lda     $1300,x
        sta     LD43A,x
        dex
        bpl     LE5D0
        addr_call LE09A, LD43A
        rts

LE5E1:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $0E, $D473
        addr_call LE09A, str_destination
        ldx     LD418
        lda     LD3F7,x
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #'0'
        sta     str_s + 1
        ldx     LD418
        lda     LD3F7,x
        and     #$80
        asl     a
        rol     a
        clc
        adc     #'1'
        sta     str_d + 1
        yax_call LDBE0, $0E, $D477
        addr_call LE09A, str_slot
        addr_call LE09A, str_s
        addr_call LE09A, str_drive
        addr_call LE09A, str_d
        rts

LE63F:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $0E, $D47B
        bit     LD44D
        bmi     LE65B
        addr_call LE09A, str_prodos_disk_copy
        rts

LE65B:  bvs     LE665
        addr_call LE09A, str_dos33_disk_copy
        rts

LE665:  lda     LD44D
        and     #$0F
        bne     LE673
        addr_call LE09A, str_pascal_disk_copy
LE673:  rts

LE674:  lda     LD44D
        cmp     #$C0
        beq     LE693
        lda     LD18D
        jsr     LE137
        yax_call LDBE0, $07, LD003
        yax_call LDBE0, $11, $D483
LE693:  rts

LE694:  lda     LD18D
        jsr     LE137
        yax_call LDBE0, $0E, $D48B
        addr_call LE09A, str_escape_stop_copy
        rts

        lda     LD18D
        jsr     LE137
        copy16  #$800A, LE6FB
LE6BB:  dec     LE6FB
        beq     LE6F1
        lda     LE6FC
        eor     #$80
        sta     LE6FC
        beq     LE6D5
        yax_call LDBE0, $0C, $D35A
        beq     LE6DE
LE6D5:  yax_call LDBE0, $0C, $D359
LE6DE:  yax_call LDBE0, $0E, $D48B
        addr_call LE09A, str_escape_stop_copy
        jmp     LE6BB

LE6F1:  yax_call LDBE0, $0C, $D35A
        rts

LE6FB:  .byte   0
LE6FC:  .byte   0
LE6FD:  stx     LE765
        cmp     #$2B
        bne     LE71A
        jsr     L127E
        lda     #$05
        jsr     LEB84
        bne     LE714
        jsr     LE491
        return  #$01

LE714:  jsr     L10FB
        return  #$80

LE71A:  jsr     L127E
        lda     LD18D
        jsr     LE137
        lda     $0C5D
        ldx     $0C5E
        jsr     LDEEB
        lda     LE765
        bne     LE74B
        yax_call LDBE0, $0E, $D493
        addr_call LE09A, str_error_reading
        addr_call LE09A, str_7_spaces
        return  #$00

LE74B:  yax_call LDBE0, $0E, $D48F
        addr_call LE09A, str_error_writing
        addr_call LE09A, str_7_spaces
        return  #$00

LE765:  .byte   0
        sta     L0006
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        copy16  #$1C00, $0C5B
LE77A:  jsr     L12AF
        beq     LE789
        ldx     #$00
        jsr     LE6FD
        beq     LE789
        bpl     LE77A
        rts

LE789:  sta     RAMRDOFF
        sta     RAMWRTON
        ldy     #$FF
        iny
LE792:  lda     $1C00,y
        sta     (L0006),y
        lda     $1D00,y
        sta     ($08),y
        iny
        bne     LE792
        sta     RAMRDOFF
        sta     RAMWRTOFF
        lda     #$00
        rts

        sta     L0006
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        copy16  #$1C00, $0C5B
        .byte   $8D
        .byte   $03
        cpy     #$8D
        .byte   $04
        cpy     #$A0
        .byte   $FF
        iny
LE7C5:  lda     (L0006),y
        sta     $1C00,y
        lda     ($08),y
        sta     $1D00,y
        iny
        bne     LE7C5
        sta     RAMRDOFF
        sta     RAMWRTOFF
LE7D8:  jsr     L12A5
        beq     LE7E6
        ldx     #$80
        jsr     LE6FD
        beq     LE7E6
        bpl     LE7D8
LE7E6:  rts

        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        asl     $401F,x
        .byte   $07
        beq     LE810
LE810:  .byte   0
        asl     $601F,x
        .byte   $03
        rts

        .byte   0
        .byte   0
        inc     LF01F,x
        .byte   $F3
        .byte   $4F
        .byte   0
        .byte   0
        inc     $F81F,x
        .byte   $F3
        .byte   $4F
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        .byte   $4F
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        .byte   $67
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        .byte   $F3
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        sbc     L0000,y
        inc     $FC1F,x
        .byte   $FF
        .byte   $FC
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $3F
        inc     a:L0000,x
        inc     $FC1F,x
        .byte   $1F
        .byte   $FF
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $1F
        .byte   $FF
        .byte   0
        .byte   0
        rol     $FE00,x
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        inc     $FF03,x
        .byte   $1F
        .byte   $FF
        .byte   0
        .byte   0
        inc     $FF43,x
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        asl     $FF60
        .byte   $FF
        .byte   $3F
        .byte   0
        .byte   0
        inc     a:$03,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$03,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $14
        .byte   0
        php
        .byte   0
        .byte   $E7
        .byte   $E7
        .byte   $07
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        bit     L0000
        .byte   $17
        .byte   0
        eor     (L0000,x)
        and     LE500
        ora     ($64,x)
        .byte   0
        .byte   $04
        .byte   0
        .byte   $02
        .byte   0
        ldy     #$01
        and     L0000,x
        ora     L0000
        .byte   $03
        .byte   0
        .byte   $9F
        ora     ($34,x)
        .byte   0
LE8B7:  .byte   $41
LE8B8:  .byte   0
LE8B9:  .byte   $2D
LE8BA:  .byte   0
        .byte   0
        jsr     L0080
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ldy     $01
        .byte   $37
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        jsr     L0080
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $2F
        .byte   $02
        .byte   $BF
        .byte   0
        .byte   $0F
        .byte   $4F
        .byte   $4B
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        ora     $430E
        adc     ($6E,x)
        .byte   $63
        adc     $6C
        jsr     L2020
        jsr     L4520
        .byte   $73
        .byte   $63
        .byte   $0F
        .byte   $54
        .byte   $72
        adc     $4120,y
        .byte   $67
        adc     ($69,x)
        ror     L2020
        jsr     L2020
        eor     ($03,x)
        eor     $7365,y
        .byte   $02
        lsr     $FA6F
        .byte   0
        and     L0000
        bit     $3001
        .byte   0
        .byte   $FF
        .byte   0
        .byte   $2F
        .byte   0
        lsr     $2501,x
        .byte   0
        bcc     LE920
        .byte   $30
LE920:  .byte   0
        .byte   $63
        ora     ($2F,x)
        .byte   0
        bit     $2501
        .byte   0
        bcc     LE92C
        .byte   $30
LE92C:  .byte   0
        and     ($01),y
        .byte   $2F
        .byte   0
        .byte   $14
        .byte   0
        and     L0000
        sei
        .byte   0
        bmi     LE939
LE939:  ora     $2F00,y
        .byte   0
        .byte   $64
        .byte   0
        clc
        .byte   0
LE941:  .byte   0
LE942:  .byte   0
LE943:  .byte   0

        PASCAL_STRING "Insert source disk and click OK."
        PASCAL_STRING "Insert destination disk and click OK."
LE98B:  PASCAL_STRING "Do you want to erase "
LE9A0 := *-1
        .res    18, 0
        PASCAL_STRING "The destination disk cannot be formated !"
        PASCAL_STRING "Error during formating."
        PASCAL_STRING "The destination volume is write protected !"
        PASCAL_STRING "Do you want to erase "
        .res    18, 0
LEA49:  PASCAL_STRING "Do you want to  erase  the disk in slot   drive   ?"
LEA7D:  PASCAL_STRING "Do you want to erase the disk in slot   drive   ?"
        PASCAL_STRING "The copy was successful."
        PASCAL_STRING "The copy was not completed."
        PASCAL_STRING "Insert source disk or press Escape to cancel."
        PASCAL_STRING "Insert destination disk or press Escape to cancel."
LEB45:  .byte   $20
LEB46:  .byte   $3F
LEB47:  .byte   $29
LEB48:  .byte   $31
LEB49:  .byte   $27
LEB4A:  .byte   $2F
LEB4B:  .byte   $17
LEB4C:  .byte   $15
LEB4D:  .byte   0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
LEB5A:  .byte   $44
LEB5B:  sbc     #$65
        sbc     #$8B
        sbc     #$B3
        sbc     #$DD
        sbc     #$F5
        sbc     #$21
        nop
        eor     #$EA
        adc     $AFEA,x
        nop
        iny
        nop
        cpx     $EA
        .byte   $12
        .byte   $EB
LEB74:  cpy     #$C0
        sta     (L0000,x)
        .byte   $80
        .byte   $80
        sta     ($81,x)
        sta     (L0000,x)
        .byte   0
        .byte   0
        .byte   0
LEB81:  .byte   0
LEB82:  .byte   0
LEB83:  .byte   0
LEB84:  stax    LEB81
        sty     LEB83
        ldy     #$03
        ldax    #$D137
        jsr     LDBE0
        yax_call LDBE0, $04, $D137
        yax_call LDBE0, $07, LD003
        yax_call LDBE0, $11, $E89F
        jsr     LF0DF
        yax_call LDBE0, $12, $E89F
        yax_call LDBE0, $06, $E8B7
        yax_call LDBE0, $12, $E8A7
        yax_call LDBE0, $12, $E8AF
        yax_call LDBE0, $07, LD003
        yax_call LDBE0, $26, $0000
        yax_call LDBE0, $14, $E88F
        yax_call LDBE0, $25, $0000
        lda     #$00
        sta     LD41E
        lda     LEB81
        jsr     LF1CC
        ldy     LEB83
        ldx     LEB82
        lda     LEB81
        bne     LEC1F
        cpx     #$00
        beq     LEC5E
        jsr     LF185
        beq     LEC5E
        lda     #$0B
        bne     LEC5E
LEC1F:  cmp     #$01
        bne     LEC34
        cpx     #$00
        beq     LEC5E
        jsr     LF185
        beq     LEC30
        lda     #$0C
        bne     LEC5E
LEC30:  lda     #$01
        bne     LEC5E
LEC34:  cmp     #$02
        bne     LEC3F
        jsr     LF0E9
        lda     #$02
        bne     LEC5E
LEC3F:  cmp     #$06
        bne     :+
        jsr     LF119
        lda     #$06
        bne     LEC5E
:       cmp     #$07
        bne     LEC55
        jsr     LF149
        lda     #$07
        bne     LEC5E
LEC55:  cmp     #$08
        bne     LEC5E
        jsr     LF167
        lda     #$08
LEC5E:  ldy     #$00
LEC60:  cmp     LEB4D,y
        beq     LEC6C
        iny
        cpy     #$1E
        bne     LEC60
        ldy     #$00
LEC6C:  tya
        asl     a
        tay
        lda     LEB5A,y
        sta     LE942
        lda     LEB5B,y
        sta     LE943
        tya
        lsr     a
        tay
        lda     LEB74,y
        sta     LE941
        bit     LD41E
        bpl     LEC8C
        jmp     LED23

LEC8C:  jsr     LF0DF
        bit     LE941
        bpl     LED0A
        yax_call LDBE0, $12, $E931
        yax_call LDBE0, $0E, $E939
        addr_call LE09A, $E8E7
        bit     LE941
        bvs     LED0A
        lda     LE941
        and     #$0F
        beq     LECEE
        yax_call LDBE0, $12, $E90D
        yax_call LDBE0, $0E, $E915
        addr_call LE09A, $E906
        yax_call LDBE0, $12, $E919
        yax_call LDBE0, $0E, $E921
        addr_call LE09A, $E90A
        jmp     LED23

LECEE:  yax_call LDBE0, $12, $E925
        yax_call LDBE0, $0E, $E92D
        addr_call LE09A, $E8F6
        jmp     LED23

LED0A:  yax_call LDBE0, $12, $E925
        yax_call LDBE0, $0E, $E92D
        addr_call LE09A, $E8D7
LED23:  yax_call LDBE0, $0E, $E93D
        lda     LE942
        ldx     LE943
        .byte   $20
        txs
        .byte   $E0
LED35:  bit     LD41E
        bpl     $ED45
        jsr     LF192
        bne     LED42
        jmp     LEDF2

LED42:  jmp     LED79

        yax_call LDBE0, $2A, $D12D
        lda     LD12D
        cmp     #$01
        bne     LED58
        jmp     LEDFA

LED58:  cmp     #$03
        bne     LED35
        lda     LD12E
        and     #$7F
        bit     LE941
        bmi     LED69
        jmp     LEDE2

LED69:  cmp     #$1B
        bne     LED7E
        jsr     LF0DF
        yax_call LDBE0, $11, $E931
LED79:  lda     #$01
        jmp     LEE6A

LED7E:  bit     LE941
        bvs     LEDE2
        pha
        lda     LE941
        and     #$0F
        beq     LEDC1
        pla
        cmp     #$4E
        beq     LED9F
        cmp     #$6E
        beq     LED9F
        cmp     #$59
        beq     LEDB0
        cmp     #$79
        beq     LEDB0
        jmp     LED35

LED9F:  jsr     LF0DF
        yax_call LDBE0, $11, $E919
        lda     #$03
        jmp     LEE6A

LEDB0:  jsr     LF0DF
        yax_call LDBE0, $11, $E90D
        lda     #$02
        jmp     LEE6A

LEDC1:  pla
        cmp     #$61
        bne     LEDD7
LEDC6:  jsr     LF0DF
        yax_call LDBE0, $11, $E925
        lda     #$00
        jmp     LEE6A

LEDD7:  cmp     #$41
        beq     LEDC6
        cmp     #$0D
        beq     LEDC6
        jmp     LED35

LEDE2:  cmp     #$0D
        bne     LEDF7
        jsr     LF0DF
        yax_call LDBE0, $11, $E925
LEDF2:  lda     #$00
        jmp     LEE6A

LEDF7:  jmp     LED35

LEDFA:  jsr     LF0B8
        yax_call LDBE0, $0E, $D12E
        bit     LE941
        bpl     LEE57
        yax_call LDBE0, $13, $E931
        cmp     #$80
        bne     LEE1B
        jmp     LEEF8

LEE1B:  bit     LE941
        bvs     LEE57
        lda     LE941
        and     #$0F
        beq     LEE47
        yax_call LDBE0, $13, $E919
        cmp     #$80
        bne     LEE37
        jmp     LEFD8

LEE37:  yax_call LDBE0, $13, $E90D
        cmp     #$80
        bne     LEE67
        jmp     LF048

LEE47:  yax_call LDBE0, $13, $E925
        cmp     #$80
        bne     LEE67
        jmp     LEE88

LEE57:  yax_call LDBE0, $13, $E925
        cmp     #$80
        bne     LEE67
        jmp     LEF68

LEE67:  jmp     LED35

LEE6A:  pha
        yax_call LDBE0, $06, $E8C7
        yax_call LDBE0, $07, LD003
        yax_call LDBE0, $11, $E89F
        pla
        rts

LEE88:  jsr     LF0DF
        yax_call LDBE0, $11, $E925
        lda     #$00
        sta     LEEF7
LEE99:  yax_call LDBE0, $2A, $D12D
        lda     LD12D
        cmp     #$02
        beq     LEEEA
        jsr     LF0B8
        yax_call LDBE0, $0E, $D12E
        yax_call LDBE0, $13, $E925
        cmp     #$80
        beq     LEECA
        lda     LEEF7
        beq     LEED2
        jmp     LEE99

LEECA:  lda     LEEF7
        bne     LEED2
        jmp     LEE99

LEED2:  jsr     LF0DF
        yax_call LDBE0, $11, $E925
        lda     LEEF7
        clc
        adc     #$80
        sta     LEEF7
        jmp     LEE99

LEEEA:  lda     LEEF7
        beq     LEEF2
        jmp     LED35

LEEF2:  lda     #$00
        jmp     LEE6A

LEEF7:  .byte   0
LEEF8:  jsr     LF0DF
        yax_call LDBE0, $11, $E931
        lda     #$00
        sta     LEF67
LEF09:  yax_call LDBE0, $2A, $D12D
        lda     LD12D
        cmp     #$02
        beq     LEF5A
        jsr     LF0B8
        yax_call LDBE0, $0E, $D12E
        yax_call LDBE0, $13, $E931
        cmp     #$80
        beq     LEF3A
        lda     LEF67
        beq     LEF42
        jmp     LEF09

LEF3A:  lda     LEF67
        bne     LEF42
        jmp     LEF09

LEF42:  jsr     LF0DF
        yax_call LDBE0, $11, $E931
        lda     LEF67
        clc
        adc     #$80
        sta     LEF67
        jmp     LEF09

LEF5A:  lda     LEF67
        beq     LEF62
        jmp     LED35

LEF62:  lda     #$01
        jmp     LEE6A

LEF67:  .byte   0
LEF68:  lda     #$00
        sta     LEFD7
        jsr     LF0DF
        yax_call LDBE0, $11, $E925
LEF79:  yax_call LDBE0, $2A, $D12D
        lda     LD12D
        cmp     #$02
        beq     LEFCA
        jsr     LF0B8
        yax_call LDBE0, $0E, $D12E
        yax_call LDBE0, $13, $E925
        cmp     #$80
        beq     LEFAA
        lda     LEFD7
        beq     LEFB2
        jmp     LEF79

LEFAA:  lda     LEFD7
        bne     LEFB2
        jmp     LEF79

LEFB2:  jsr     LF0DF
        yax_call LDBE0, $11, $E925
        lda     LEFD7
        clc
        adc     #$80
        sta     LEFD7
        jmp     LEF79

LEFCA:  lda     LEFD7
        beq     LEFD2
        jmp     LED35

LEFD2:  lda     #$00
        jmp     LEE6A

LEFD7:  .byte   0
LEFD8:  lda     #$00
        sta     LF047
        jsr     LF0DF
        yax_call LDBE0, $11, $E919
LEFE9:  yax_call LDBE0, $2A, $D12D
        lda     LD12D
        cmp     #$02
        beq     LF03A
        jsr     LF0B8
        yax_call LDBE0, $0E, $D12E
        yax_call LDBE0, $13, $E919
        cmp     #$80
        beq     LF01A
        lda     LF047
        beq     LF022
        jmp     LEFE9

LF01A:  lda     LF047
        bne     LF022
LF01F:  jmp     LEFE9

LF022:  jsr     LF0DF
        yax_call LDBE0, $11, $E919
        lda     LF047
        clc
        adc     #$80
        sta     LF047
        jmp     LEFE9

LF03A:  lda     LF047
        beq     LF042
        jmp     LED35

LF042:  lda     #$03
        jmp     LEE6A

LF047:  .byte   0
LF048:  lda     #$00
        sta     LF0B7
        jsr     LF0DF
        yax_call LDBE0, $11, $E90D
LF059:  yax_call LDBE0, $2A, $D12D
        lda     LD12D
        cmp     #$02
        beq     LF0AA
        jsr     LF0B8
        yax_call LDBE0, $0E, $D12E
        yax_call LDBE0, $13, $E90D
        cmp     #$80
        beq     LF08A
        lda     LF0B7
        beq     LF092
        jmp     LF059

LF08A:  lda     LF0B7
        bne     LF092
        jmp     LF059

LF092:  jsr     LF0DF
        yax_call LDBE0, $11, $E90D
        lda     LF0B7
        clc
        adc     #$80
        sta     LF0B7
        jmp     LF059

LF0AA:  lda     LF0B7
        beq     LF0B2
        jmp     LED35

LF0B2:  lda     #$02
        jmp     LEE6A

LF0B7:  .byte   0
LF0B8:  sub16   LD12E, LE8B7, LD12E
        sub16   LD130, LE8B9, LD130
        rts

LF0DF:  yax_call LDBE0, $07, $D005
        rts

LF0E9:  stx     L0006
        sty     $07
        ldy     #$00
        lda     (L0006),y
        pha
        tay
LF0F3:  lda     (L0006),y
        sta     LE9A0,y
        dey
        bne     LF0F3
        pla
        clc
        adc     LEB4B
        sta     LE98B
        tay
        inc     LE98B
        inc     LE98B
        lda     LEB45
        iny
        sta     LE98B,y
        lda     LEB46
        iny
        sta     LE98B,y
        rts

LF119:  stx     L0006
        sty     $07
        ldy     #$00
        lda     (L0006),y
        pha
        tay
LF123:  lda     (L0006),y
        sta     $EA36,y
        dey
        bne     LF123
        pla
        clc
        adc     LEB4C
        sta     $EA21
        tay
        inc     $EA21
        inc     $EA21
        lda     LEB45
        iny
        sta     $EA21,y
        lda     LEB46
        iny
        sta     $EA21,y
        rts

LF149:  txa
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #$30
        ldy     LEB47
        sta     LEA49,y
        txa
        and     #$80
        asl     a
        rol     a
        adc     #$31
        ldy     LEB48
        sta     LEA49,y
        rts

LF167:  txa
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #$30
        ldy     LEB49
        sta     LEA7D,y
        txa
        and     #$80
        asl     a
        rol     a
        adc     #$31
        ldy     LEB4A
        sta     LEA7D,y
        rts

LF185:  sty     LD41D
        tya
        jsr     L0EB2
        beq     LF191
        sta     LD41E
LF191:  rts

LF192:  lda     LD41D
        sta     $0C46
        jsr     L129B
        beq     LF1C9
        cmp     #$52
        beq     LF1C9
        lda     $0C49
        and     #$0F
        bne     LF1C9
        lda     $0C4A
        cmp     #$52
        beq     LF1C9
        yax_call LDBE0, $2A, $D12D
        lda     LD12D
        cmp     #$03
        bne     LF192
        lda     LD12E
        cmp     #$1B
        bne     LF192
        return  #$80

LF1C9:  return  #$00

LF1CC:  cmp     #$03
        bcc     LF1D7
        cmp     #$06
        bcs     LF1D7
        jsr     L127E
LF1D7:  rts

        tya
        lsr     a
        bcs     LF1DF
        bit     $C055
LF1DF:  tay
        lda     ($28),y
        pha
        cmp     #$E0
        bcc     LF1E9
        sbc     #$20
LF1E9:  and     #$3F
        sta     ($28),y
        lda     $C000
        bmi     LF1F5
        jmp     L51ED

LF1F5:  pla
        sta     ($28),y
        bit     $C054
        lda     $C000
        .byte   $2C
        .byte   $10
