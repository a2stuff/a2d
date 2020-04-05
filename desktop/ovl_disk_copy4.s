;;; ============================================================
;;; Overlay for Disk Copy - $0800 - $12FF (file 4/4)
;;; ============================================================

.proc disk_copy_overlay4
        .org $800

.macro exit_with_result arg
        lda     #arg
        jmp     exit
.endmacro


L0800:  php
        sei
        jsr     L083A
        plp
        cmp     #$00
        bne     L080C
        clc
        rts

L080C:  cmp     #$02
        bne     L0815
        lda     #ERR_WRITE_PROTECTED
        jmp     L0821

L0815:  cmp     #$01
        bne     L081E
        lda     #$27
        jmp     L0821

L081E:  clc
        adc     #$30
L0821:  sec
        rts

L0823:  asl     a
        asl     current_track
        sta     seltrack_track
        txa
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     seltrack_track
        jsr     select_track
        lsr     current_track
        rts

L083A:  tax
        and     #$70
        sta     L0C23
        txa
        ldx     L0C23
        rol     a
        lda     #$00
        rol     a
        bne     :+
        lda     SELECT,x        ; Select drive 1 or 2
        jmp     L0853

:       lda     LCBANK1,x
L0853:  lda     ENABLE,x        ; Turn drive on
        lda     #$D7
        sta     $DA
        lda     #$50
        sta     current_track
        lda     #$00
        jsr     L0823
L0864:  lda     $DA
        beq     L086E
        jsr     L0B3A
        jmp     L0864

L086E:  lda     #$01
        sta     $D3
        lda     #$AA
        sta     $D0
        lda     L0C20
        clc
        adc     #$02
        sta     $D4
        lda     #$00
        sta     $D1
L0882:  lda     $D1
        ldx     L0C23
        jsr     L0823
        ldx     L0C23
        lda     TESTWP,x        ; Check write protect???
        lda     WPRES,x
        tay
        lda     RDMODE,x        ; Activate read mode
        lda     XMIT,x
        tya
        bpl     :+              ; WP mode?
        exit_with_result 2      ; Yes

:       jsr     L0B63
        bcc     L08B5
        lda     #$01
        ldy     $D4
        cpy     L0C1F
        bcs     L08B2
        lda     #4
L08B2:  jmp     exit

L08B5:  ldy     $D4
        cpy     L0C1F
        bcs     L08C1
        exit_with_result 4

L08C1:  cpy     L0C20
        bcc     L08CB
        exit_with_result 3

L08CB:  lda     L0C22
        sta     L0C25
L08D1:  dec     L0C25
        bne     L08DB
        exit_with_result 1

L08DB:  ldx     L0C23
        jsr     L096A
        bcs     L08D1
        lda     $D8
        bne     L08D1
        ldx     L0C23
        jsr     L0907
        bcs     L08D1
        inc     $D1
        lda     $D1
        cmp     #$23
        bcc     L0882

        lda     #0
        ;; fall through

.proc exit
        pha
        ldx     L0C23
        lda     DISABLE,x       ; Turn drive off
        lda     #0
        jsr     L0823
        pla
        rts
.endproc

;;; ============================================================

.proc L0907
        ldy     #$20
L0909:  dey
        beq     return_with_carry_set
:       lda     XMIT,x
        bpl     :-

L0911:  eor     #$D5
        bne     L0909
        nop
:       lda     XMIT,x
        bpl     :-
        cmp     #$AA
        bne     L0911
        ldy     #$56
:       lda     XMIT,x
        bpl     :-
        cmp     #$AD
        bne     L0911

        lda     #$00
L092C:  dey
        sty     $D5
:       lda     XMIT,x
        bpl     :-
        cmp     #$96
        bne     return_with_carry_set
        ldy     $D5
        bne     L092C

L093C:  sty     $D5
:       lda     XMIT,x
        bpl     :-
        cmp     #$96
        bne     return_with_carry_set
        ldy     $D5
        iny
        bne     L093C

:       lda     XMIT,x
        bpl     :-
        cmp     #$96
        bne     return_with_carry_set
:       lda     XMIT,x
        bpl     :-
        cmp     #$DE
        bne     return_with_carry_set
        nop
:       lda     XMIT,x
        bpl     :-
        cmp     #$AA
        beq     return_with_carry_clear
.endproc
return_with_carry_set:
        sec
        rts

.proc L096A
        ldy     #$FC
        sty     $DC
L096E:  iny
        bne     :+
        inc     $DC
        beq     return_with_carry_set
:       lda     XMIT,x
        bpl     :-

L097A:  cmp     #$D5
        bne     L096E
        nop
:       lda     XMIT,x
        bpl     :-
        cmp     #$AA
        bne     L097A
        ldy     #$03
:       lda     XMIT,x
        bpl     :-
        cmp     #$96
        bne     L097A

        lda     #$00
L0995:  sta     $DB
:       lda     XMIT,x
        bpl     :-
        rol     a
        sta     $DD
:       lda     XMIT,x
        bpl     :-
        and     $DD
        sta     $D7,y
        eor     $DB
        dey
        bpl     L0995

        tay
        bne     return_with_carry_set
:       lda     XMIT,x
        bpl     :-
        cmp     #$DE
        bne     return_with_carry_set
        nop
:       lda     XMIT,x
        bpl     :-
        cmp     #$AA
        bne     return_with_carry_set
.endproc
return_with_carry_clear:
        clc
        rts

;;; ============================================================
;;; Move head to track - A = track, X = slot * 16

.proc select_track
        stx     seltrack_slot
        sta     seltrack_track
        cmp     current_track
        beq     done
        lda     #$00
        sta     L0C38
L09D6:  lda     current_track
        sta     L0C39
        sec
        sbc     seltrack_track
        beq     L0A19
        bcs     L09EB
        eor     #$FF
        inc     current_track
        bcc     L09F0
L09EB:  adc     #$FE
        dec     current_track
L09F0:  cmp     L0C38
        bcc     L09F8
        lda     L0C38
L09F8:  cmp     #$0C
        bcs     L09FD
        tay
L09FD:  sec
        jsr     L0A1D
        lda     phase_on_table,y
        jsr     L0B3A
        lda     L0C39
        clc
        jsr     motor
        lda     phase_off_table,y
        jsr     L0B3A
        inc     L0C38
        bne     L09D6
L0A19:  jsr     L0B3A
        clc
L0A1D:  lda     current_track

motor:  and     #$03            ; PHASE0 + 2 * phase
        rol     a
        ora     seltrack_slot
        tax
        lda     PHASE0,x
        ldx     seltrack_slot

done:   rts
.endproc

;;; ============================================================

.proc format_sector
        jsr     rts2
        lda     TESTWP,x        ; Check write protect ???
        lda     WPRES,x

        lda     #$FF            ; Self-sync data
        sta     WRMODE,x        ; Turn on write mode
        cmp     XMIT,x          ; Start sending bits to disk
        pha                     ; 32 cycles...
        pla
        nop
        ldy     #4

sync:   pha
        pla
        jsr     write2
        dey
        bne     sync

        ;; Address marks
        lda     #$D5
        jsr     write
        lda     #$AA
        jsr     write
        lda     #$AD
        jsr     write
        ldy     #$56
        nop
        nop
        nop
        bne     :+

        ;; Data
loop:   jsr     rts2
:       nop
        nop
        lda     #$96
        sta     DATA,x
        cmp     XMIT,x
        dey
        bne     loop

        ;; Checksum
        bit     $00
        nop
check:  jsr     rts2
        lda     #$96
        sta     DATA,x
        cmp     XMIT,x
        lda     #$96
        nop
        iny
        bne     check

        ;; Slip marks
        jsr     write
        lda     #$DE
        jsr     write
        lda     #$AA
        jsr     write
        lda     #$EB
        jsr     write
        lda     #$FF
        jsr     write
        lda     RDMODE,x        ; Turn off write mode
        lda     XMIT,x
        rts

        ;; Write with appropriate cycle counts
write:  nop
write2: pha
        pla
        sta     DATA,x
        cmp     XMIT,x
        rts
.endproc

;;; ============================================================

.proc L0AAE
        sec
        lda     TESTWP,x        ; Check write protect
        lda     WPRES,x
        bmi     L0B15
        lda     #$FF
        sta     WRMODE,x        ; Turn on write mode
        cmp     XMIT,x          ; Start sending bits to disk
        pha                     ; 32 cycles...
        pla
loop:   jsr     rts1
        jsr     rts1
        sta     DATA,x
        cmp     XMIT,x
        nop
        dey
        bne     loop
        lda     #$D5
        jsr     L0B2D
        lda     #$AA
        jsr     L0B2D
        lda     #$96
        jsr     L0B2D
        lda     $D3
        jsr     L0B1C
        lda     $D1
        jsr     L0B1C
        lda     $D2
        jsr     L0B1C
        lda     $D3
        eor     $D1
        eor     $D2
        pha
        lsr     a
        ora     $D0
        sta     DATA,x
        lda     XMIT,x
        pla
        ora     #$AA
        jsr     L0B2C
        lda     #$DE
        jsr     L0B2D
        lda     #$AA
        jsr     L0B2D
        lda     #$EB
        jsr     L0B2D
        clc
L0B15:  lda     RDMODE,x        ; Turn off write mode
        lda     XMIT,x
rts1:   rts
.endproc

;;; ============================================================

L0B1C:  pha
        lsr     a
        ora     $D0
        sta     DATA,x
        cmp     XMIT,x
        pla
        nop
        nop
        nop
        ora     #$AA
L0B2C:  nop
L0B2D:  nop
        pha
        pla
        sta     DATA,x
        cmp     XMIT,x
        rts

        .byte   0
        .byte   0
        .byte   0

.proc L0B3A
start:  ldx     #$11
:       dex
        bne     :-
        inc16   $D9
        sec
        sbc     #1
        bne     start
        rts
.endproc

;;; Timing (100-usecs)
phase_on_table:  .byte   $01, $30, $28, $24, $20, $1E, $1D, $1C, $1C, $1C, $1C, $1C
phase_off_table: .byte   $70, $2C, $26, $22, $1F, $1E, $1D, $1C, $1C, $1C, $1C, $1C

L0B63:  lda     L0C21
        sta     $D6
L0B68:  ldy     #$80
        lda     #$00
        sta     $D2
        jmp     L0B73

L0B71:  ldy     $D4
L0B73:  ldx     L0C23
        jsr     L0AAE
        bcc     L0B7E
        jmp     rts2

L0B7E:  ldx     L0C23
        jsr     format_sector
        inc     $D2
        lda     $D2
        cmp     #$10
        bcc     L0B71
        ldy     #$0F
        sty     $D2
        lda     L0C22
        sta     L0C25
L0B96:  sta     L0C26,y
        dey
        bpl     L0B96
        lda     $D4
        sec
        sbc     #$05
        tay
L0BA2:  jsr     rts2
        jsr     rts2
        pha
        pla
        nop
        nop
        dey
        bne     L0BA2
        ldx     L0C23
        jsr     L096A
        bcs     L0BF3
        lda     $D8
        beq     L0BCE
        dec     $D4
        lda     $D4
        cmp     L0C1F
        bcs     L0BF3
        sec
        rts

L0BC6:  ldx     L0C23
        jsr     L096A
        bcs     L0BE8
L0BCE:  ldx     L0C23
        jsr     L0907
        bcs     L0BE8
        ldy     $D8
        lda     L0C26,y
        bmi     L0BE8
        lda     #$FF
        sta     L0C26,y
        dec     $D2
        bpl     L0BC6
        clc
        rts

L0BE8:  dec     L0C25
        bne     L0BC6
        dec     $D6
        bne     L0BF3
        sec
        rts

L0BF3:  lda     L0C22
        asl     a
        sta     L0C25
L0BFA:  ldx     L0C23
        jsr     L096A
        bcs     L0C08
        lda     $D8
        cmp     #$0F
        beq     L0C0F
L0C08:  dec     L0C25
        bne     L0BFA
        sec
rts2:   rts

L0C0F:  ldx     #$D6
L0C11:  jsr     rts2
        jsr     rts2
        bit     $00
        dex
        bne     L0C11
        jmp     L0B68

L0C1F:  .byte   $0E
L0C20:  .byte   $1B
L0C21:  .byte   $03
L0C22:  .byte   $10
L0C23:  .byte   0

current_track:
        .byte   0

L0C25:  .byte   0
L0C26:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

seltrack_track:
        .byte   0
seltrack_slot:
        .byte   0

L0C38:  .byte   0
L0C39:  .byte   0

;;; ============================================================

        DEFINE_QUIT_PARAMS quit_params

        DEFINE_ON_LINE_PARAMS on_line_params2,, $1300

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer
on_line_buffer:
        .res    16, 0

        DEFINE_READ_BLOCK_PARAMS block_params, $1C00, 0

;;; ============================================================

.proc MLI_RELAY
        sty     call
        stax    params
        sta     ALTZPOFF
        lda     ROMIN2
        jsr     MLI
call:   .byte   0
params: .addr   0
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts
.endproc

;;; ============================================================

.proc noop
        rts
.endproc

;;; ============================================================
;;; Quit back to ProDOS (which will launch DeskTop)

.proc quit
        jsr     disk_copy_overlay3::restore_ram_disk
        sta     ALTZPOFF
        lda     ROMIN2
        sta     DHIRESOFF
        sta     TXTCLR
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        MLI_CALL QUIT, quit_params
        rts
.endproc

;;; ============================================================

L0CAF:  ldx     disk_copy_overlay3::dest_drive_index
        lda     disk_copy_overlay3::drive_unitnum_table,x
        sta     unit_number
        and     #$0F
        beq     L0CCC
        lda     disk_copy_overlay3::drive_unitnum_table,x
        jsr     unit_number_to_driver_address
        ldy     #$FF            ; offset to low byte of driver address
        lda     ($06),y
        beq     L0CCC
        cmp     #$FF
        bne     L0CD3
L0CCC:  lda     unit_number
        jsr     L0800
        rts

L0CD3:  lda     unit_number
        jsr     unit_number_to_driver_address

        ldy     #$FF            ; offset to low byte of driver address
        lda     ($06),y
        sta     $06
        lda     #DRIVER_COMMAND_FORMAT
        sta     DRIVER_COMMAND
        lda     unit_number
        sta     DRIVER_UNIT_NUMBER
        jmp     ($06)

        rts

unit_number:
        .byte   0

;;; ============================================================
;;; Eject Disk via SmartPort

.proc eject_disk
        sta     L0D24
        jsr     unit_number_to_driver_address           ; Point $06 at $Cn00

        ldy     #$07            ; Check firmware bytes
        lda     ($06),y       ; $Cn07 = $00 ??
        bne     done

        ldy     #$FB
        lda     ($06),y       ; $CnFB = $7F ??
        and     #$7F
        bne     done

        ldy     #$FF
        lda     ($06),y
        clc
        adc     #3        ; Locate dispatch routine (offset $CnFF + 3)
        sta     $06

        lda     L0D24
        jsr     L0D51
        sta     control_params_unit_number

        ;; Do SmartPort call
        jsr     smartport_call
        .byte   $04             ; SmartPort: CONTROL
        .addr   $0D1D

done:   rts

smartport_call:
        jmp     ($06)

.params control_params
param_count:    .byte   3
unit_number:    .byte   0
control_list:   .addr   L0D22
control_code:   .byte   $04     ; Control Code: Eject disk
.endparams
control_params_unit_number := control_params::unit_number

L0D22:  .byte   0, 0
L0D24:  .byte   0
        .byte   0

.endproc

;;; ============================================================
;;; Get driver address for unit number
;;; Input: unit_number in A
;;; Output: $6/$7 points at driver address

.proc unit_number_to_driver_address
        sta     unit_number
        ldx     #$11            ; $BF11 is DEVADR+1 for S0D1
        lda     unit_number
        and     #$80            ; high bit set?
        beq     :+
        ldx     #$21            ; $BF21 is DEVADR+1 for S0D2
:       stx     @load_addr
        lda     unit_number
        and     #$70            ; mask off slot
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     @load_addr
        sta     @load_addr

        @load_addr := *+1
        lda     MLI             ; self-modified
        sta     $06+1
        lda     #$00
        sta     $06
        rts

unit_number:
        .byte   0
.endproc

;;; ============================================================

L0D51:  pha
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
        rts

;;; ============================================================

L0D5F:  ldx     disk_copy_overlay3::source_drive_index
        lda     disk_copy_overlay3::drive_unitnum_table,x
        sta     block_params::unit_num
        lda     #$00
        sta     block_params::block_num
        sta     block_params::block_num+1
        jsr     L12AF
        bne     L0D8A
        lda     $1C00+1
        cmp     #$E0
        beq     L0D7F
        jmp     L0DA4

L0D7F:  lda     $1C02
        cmp     #$70
        beq     L0D90
        cmp     #$60
        beq     L0D90
L0D8A:  lda     #$81
        sta     disk_copy_overlay3::LD44D
        rts

L0D90:  addr_call disk_copy_overlay3::LDE9F, $1300
        addr_call disk_copy_overlay3::adjust_case, $1300
        lda     #$C0
        sta     disk_copy_overlay3::LD44D
        rts

L0DA4:  cmp     #$A5
        bne     L0D8A
        lda     $1C02
        cmp     #$27
        bne     L0D8A
        lda     #$80
        sta     disk_copy_overlay3::LD44D
        rts

;;; ============================================================

L0DB5:  lda     #$14
        jsr     L1133
        lda     disk_copy_overlay3::source_drive_index
        asl     a
        tax
        lda     disk_copy_overlay3::LD407,x
        sta     L0EB0
        lda     disk_copy_overlay3::LD407+1,x
        sta     L0EB1
        lsr16   L0EB0
        lsr16   L0EB0
        lsr16   L0EB0
        copy16  L0EB0, disk_copy_overlay3::LD427
        bit     disk_copy_overlay3::LD44D
        bmi     L0DF6
        lda     disk_copy_overlay3::quick_copy_flag
        bne     L0DF6
        jmp     L0E4D

L0DF6:  lda     #$FF
        clc
        adc     disk_copy_overlay3::LD427
        sta     $06
        lda     #$13
        adc     disk_copy_overlay3::LD427+1
        sta     $07
        ldy     #$00
L0E07:  lda     #$00
        sta     ($06),y
        dec     $06
        lda     $06
        cmp     #$FF
        bne     L0E15
        dec     $07
L0E15:  lda     $07
        cmp     #$14
        bne     L0E07
        lda     $06
        cmp     #$00
        bne     L0E07
        lda     #$00
        sta     ($06),y
        lda     disk_copy_overlay3::LD427+1
        cmp     #$02
        bcs     L0E2D
        rts

L0E2D:  lda     #$14
        sta     $06
        lda     disk_copy_overlay3::LD427+1
        pha
L0E35:  inc     $06
        inc     $06
        pla
        sec
        sbc     #$02
        pha
        bmi     L0E46
        jsr     L0E47
        jmp     L0E35

L0E46:  pla
L0E47:  lda     $06
        jsr     L1133
        rts

L0E4D:  copy16  #6, block_params::block_num
        ldx     disk_copy_overlay3::source_drive_index
        lda     disk_copy_overlay3::drive_unitnum_table,x
        sta     block_params::unit_num
        copy16  #$1400, block_params::data_buffer
        jsr     L12AF
        beq     L0E70
        .byte   0
L0E70:  lda     L0EB0
        sec
        sbc     #$00
        sta     L0EB0
        lda     L0EB1
        sbc     #$02
        sta     L0EB1
        lda     L0EB1
        bpl     L0E87
        rts

L0E87:  lda     L0EB0
        bne     L0E8D
        rts

L0E8D:  add16   block_params::data_buffer, #$0200, block_params::data_buffer

        inc     block_params::block_num
        lda     block_params::data_buffer+1
        jsr     L1133
        jsr     L12AF
        beq     L0EAD
        .byte   0
L0EAD:  jmp     L0E70

L0EB0:  .byte   0
L0EB1:  .byte   0


;;; ============================================================

L0EB2:  and     #$F0
        sta     L0ED6
        ldx     DEVCNT
L0EBA:  lda     DEVLST,x
        and     #$F0
        cmp     L0ED6
        beq     L0ECA
        dex
        bpl     L0EBA
L0EC7:  return  #$00

L0ECA:  lda     DEVLST,x
        and     #$0F
        cmp     #$0B
        bne     L0EC7
        return  #$80

L0ED6:  .byte   0

;;; ============================================================

L0ED7:  bit     KBDSTRB
        sta     L0FE6
        and     #$FF
        bpl     L0EFF
        copy16  disk_copy_overlay3::LD424, disk_copy_overlay3::LD421
        lda     disk_copy_overlay3::LD426
        sta     disk_copy_overlay3::LD423
        ldx     disk_copy_overlay3::dest_drive_index
        lda     disk_copy_overlay3::drive_unitnum_table,x
        sta     block_params::unit_num
        jmp     L0F1A

L0EFF:  copy16  disk_copy_overlay3::LD421, disk_copy_overlay3::LD424
        lda     disk_copy_overlay3::LD423
        sta     disk_copy_overlay3::LD426
        ldx     disk_copy_overlay3::source_drive_index
        lda     disk_copy_overlay3::drive_unitnum_table,x
        sta     block_params::unit_num
L0F1A:  lda     #$07
        sta     disk_copy_overlay3::LD420
        lda     #$00
        sta     disk_copy_overlay3::LD41F
        sta     L0FE4
        sta     L0FE5
L0F2A:  lda     KBD
        cmp     #(CHAR_ESCAPE | $80)
        bne     L0F37
        jsr     disk_copy_overlay3::LE6AB
        jmp     L0F6F

L0F37:  bit     L0FE4
        bmi     L0F6C
        bit     L0FE5
        bmi     L0F69
        jsr     L107F
        bcc     L0F51
        bne     L0F4C
        cpx     #$00
        beq     L0F6C
L0F4C:  ldy     #$80
        sty     L0FE4
L0F51:  stax    L0FE7
        jsr     L0FE9
        bcc     L0F72
        bne     L0F62
        cpx     #$00
        beq     L0F69
L0F62:  ldy     #$80
        sty     L0FE5
        bne     L0F72
L0F69:  return  #$80

L0F6C:  return  #$00

L0F6F:  return  #$01

L0F72:  stax    block_params::block_num
        ldx     L0FE8
        lda     L0FE7
        ldy     disk_copy_overlay3::LD41F
        cpy     #$10
        bcs     L0F9A
        bit     L0FE6
        bmi     L0F92
        jsr     L1160
        bmi     L0F6F
        jmp     L0F2A

L0F92:  jsr     L11F7
        bmi     L0F6F
        jmp     L0F2A

L0F9A:  cpy     #$1D
        bcc     L0FB7
        cpy     #$20
        bcs     L0FCC
        bit     L0FE6
        bmi     L0FAF
        jsr     L1175
        bmi     L0F6F
        jmp     L0F2A

L0FAF:  jsr     L120C
        bmi     L0F6F
        jmp     L0F2A

L0FB7:  bit     L0FE6
        bmi     L0FC4
        jsr     disk_copy_overlay3::LE766
        bmi     L0F6F
        jmp     L0F2A

L0FC4:  jsr     disk_copy_overlay3::LE7A8
        bmi     L0F6F
        jmp     L0F2A

L0FCC:  bit     L0FE6
        bmi     L0FD9
        jsr     L11AD
        bmi     L0F6F
        jmp     L0F2A

L0FD9:  jsr     L123F
        bmi     L0FE1
        jmp     L0F2A

L0FE1:  jmp     L0F6F

L0FE4:  .byte   0
L0FE5:  .byte   0
L0FE6:  .byte   0
L0FE7:  .byte   0
L0FE8:  .byte   0
L0FE9:  jsr     L102A
        cpy     #$00
        bne     L0FF6
        pha
        jsr     L0FFF
        pla
        rts

L0FF6:  jsr     L0FFF
        bcc     L0FE9
        lda     #$00
        tax
        rts

L0FFF:  dec     disk_copy_overlay3::LD423
        lda     disk_copy_overlay3::LD423
        cmp     #$FF
        beq     L100B
L1009:  clc
        rts

L100B:  lda     #$07
        sta     disk_copy_overlay3::LD423
        inc16   disk_copy_overlay3::LD421
        lda     disk_copy_overlay3::LD421+1
        cmp     disk_copy_overlay3::LD427+1
        bne     L1009
        lda     disk_copy_overlay3::LD421
        cmp     disk_copy_overlay3::LD427
        bne     L1009
        sec
        rts

L102A:  lda     #$00
        clc
        adc     disk_copy_overlay3::LD421
        sta     $06
        lda     #$14
        adc     disk_copy_overlay3::LD421+1
        sta     $07
        ldy     #$00
        lda     ($06),y
        ldx     disk_copy_overlay3::LD423
        cpx     #$00
        beq     L1048
L1044:  lsr     a
        dex
        bne     L1044
L1048:  and     #$01
        bne     L104F
        tay
        beq     L1051
L104F:  ldy     #$FF
L1051:  lda     disk_copy_overlay3::LD421+1
        sta     L1076
        lda     disk_copy_overlay3::LD421
        asl     a
        rol     L1076
        asl     a
        rol     L1076
        asl     a
        rol     L1076
        ldx     disk_copy_overlay3::LD423
        clc
        adc     L1077,x
        pha
        lda     L1076
        adc     #$00
        tax
        pla
        rts

L1076:  .byte   0
L1077:  .byte   $07
        asl     $05
        .byte   $04
        .byte   $03
        .byte   $02
        ora     ($00,x)
L107F:  jsr     L10B2
        cpy     #$00
        beq     L108C
        pha
        jsr     L1095
        pla
        rts

L108C:  jsr     L1095
        bcc     L107F
        lda     #$00
        tax
        rts

L1095:  dec     disk_copy_overlay3::LD420
        lda     disk_copy_overlay3::LD420
        cmp     #$FF
        beq     L10A1
L109F:  clc
        rts

L10A1:  lda     #$07
        sta     disk_copy_overlay3::LD420
        inc     disk_copy_overlay3::LD41F
        lda     disk_copy_overlay3::LD41F
        cmp     #$21
        bcc     L109F
        sec
        rts

L10B2:  ldx     disk_copy_overlay3::LD41F
        lda     L12B9,x
        ldx     disk_copy_overlay3::LD420
        cpx     #$00
        beq     L10C3
L10BF:  lsr     a
        dex
        bne     L10BF
L10C3:  and     #$01
        bne     L10CB
        ldy     #$00
        beq     L10CD
L10CB:  ldy     #$FF
L10CD:  lda     disk_copy_overlay3::LD41F
        cmp     #$10
        bcs     L10E3
L10D4:  asl     a
        asl     a
        asl     a
        asl     a
        ldx     disk_copy_overlay3::LD420
        clc
        adc     L10F3,x
        tax
        return  #$00

L10E3:  cmp     #$20
        bcs     L10ED
        sec
        sbc     #$10
        jmp     L10D4

L10ED:  sec
        sbc     #$13
        jmp     L10D4

L10F3:
        .byte   $0E, $0C, $0A, $08, $06, $04, $02, $00

;;; ============================================================

L10FB:  lda     #$14
        sta     $06
        lda     #$00
        sta     L111E
L1104:  lda     $06
        jsr     L111F
        inc     $06
        inc     $06
        inc     L111E
        inc     L111E
        lda     L111E
        cmp     disk_copy_overlay3::LD427+1
        beq     L1104
        bcc     L1104
        rts

L111E:  .byte   0
L111F:  jsr     L1149
        tay
        sec
        cpx     #$00
        beq     L112C
L1128:  asl     a
        dex
        bne     L1128
L112C:  ora     L12B9,y
        sta     L12B9,y
        rts

L1133:  jsr     L1149
        tay
        sec
        cpx     #$00
        beq     L1140
L113C:  asl     a
        dex
        bne     L113C
L1140:  eor     #$FF
        and     L12B9,y
        sta     L12B9,y
        rts

L1149:  pha
        and     #$0F
        lsr     a
        tax
        lda     L1158,x
        tax
        pla
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        rts

L1158:  .byte   $07
        asl     $05
        .byte   $04
        .byte   $03
        .byte   $02
        ora     ($00,x)
L1160:  stax    block_params::data_buffer
L1166:  jsr     L12AF
        beq     L1174
        ldx     #$00
        jsr     disk_copy_overlay3::LE6FD
        bmi     L1174
        bne     L1166
L1174:  rts

L1175:  sta     $06
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        copy16  #$1C00, block_params::data_buffer
L1189:  jsr     L12AF
        beq     L119A
        ldx     #$00
        jsr     disk_copy_overlay3::LE6FD
        beq     L119A
        bpl     L1189
        return  #$80

L119A:  ldy     #$FF
        iny
L119D:  lda     $1C00,y
        sta     ($06),y
        lda     $1D00,y
        sta     ($08),y
        iny
        bne     L119D
        return  #$00

L11AD:  sta     $06
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        copy16  #$1C00, block_params::data_buffer
L11C1:  jsr     L12AF
        beq     L11D8
        ldx     #$00
        jsr     disk_copy_overlay3::LE6FD
        beq     L11D8
        bpl     L11C1
        lda     LCBANK1
        lda     LCBANK1
        return  #$80

L11D8:  lda     LCBANK2
        lda     LCBANK2
        ldy     #$FF
        iny
L11E1:  lda     $1C00,y
        sta     ($06),y
        lda     $1D00,y
        sta     ($08),y
        iny
        bne     L11E1
        lda     LCBANK1
        lda     LCBANK1
        return  #$00

L11F7:  stax    block_params::data_buffer
L11FD:  jsr     L12A5
        beq     L120B
        ldx     #$80
        jsr     disk_copy_overlay3::LE6FD
        beq     L120B
        bpl     L11FD
L120B:  rts

L120C:  sta     $06
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        copy16  #$1C00, block_params::data_buffer
        ldy     #$FF
        iny
L1223:  lda     ($06),y
        sta     $1C00,y
        lda     ($08),y
        sta     $1D00,y
        iny
        bne     L1223
L1230:  jsr     L12A5
        beq     L123E
        ldx     #$80
        jsr     disk_copy_overlay3::LE6FD
        beq     L123E
        bpl     L1230
L123E:  rts

L123F:  bit     LCBANK2
        bit     LCBANK2
        sta     $06
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        copy16  #$1C00, block_params::data_buffer
        ldy     #$FF
        iny
L125C:  lda     ($06),y
        sta     $1C00,y
        lda     ($08),y
        sta     $1D00,y
        iny
        bne     L125C
        lda     LCBANK1
        lda     LCBANK1
L126F:  jsr     L12A5
        beq     L127D
        ldx     #$80
        jsr     disk_copy_overlay3::LE6FD
        beq     L127D
        bpl     L126F
L127D:  rts

;;; ============================================================

bell:   sta     ALTZPOFF
        sta     ROMIN2
        jsr     BELL1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

L1291:  yax_call MLI_RELAY, ON_LINE, on_line_params2
        rts

L129B:  yax_call MLI_RELAY, ON_LINE, on_line_params
        rts

L12A5:  yax_call MLI_RELAY, WRITE_BLOCK, block_params
        rts

L12AF:  yax_call MLI_RELAY, READ_BLOCK, block_params
        rts

;;; ============================================================

L12B9:  .byte   0
        .byte   $3C
        .byte   0
        .byte   0
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FE
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $0F
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   $7F
        .byte   $FF

;;; ============================================================

        PAD_TO $1300

.endproc

disk_copy_overlay4_L0CAF        := disk_copy_overlay4::L0CAF
disk_copy_overlay4_L0D51        := disk_copy_overlay4::L0D51
disk_copy_overlay4_L0D5F        := disk_copy_overlay4::L0D5F
disk_copy_overlay4_L0DB5        := disk_copy_overlay4::L0DB5
disk_copy_overlay4_L0EB2        := disk_copy_overlay4::L0EB2
disk_copy_overlay4_L0ED7        := disk_copy_overlay4::L0ED7
disk_copy_overlay4_L10FB        := disk_copy_overlay4::L10FB
disk_copy_overlay4_bell         := disk_copy_overlay4::bell
disk_copy_overlay4_L1291        := disk_copy_overlay4::L1291
disk_copy_overlay4_L129B        := disk_copy_overlay4::L129B
disk_copy_overlay4_L12A5        := disk_copy_overlay4::L12A5
disk_copy_overlay4_L12AF        := disk_copy_overlay4::L12AF
disk_copy_overlay4_block_params_block_num       := disk_copy_overlay4::block_params::block_num
disk_copy_overlay4_block_params_data_buffer     := disk_copy_overlay4::block_params::data_buffer
disk_copy_overlay4_block_params_unit_num        := disk_copy_overlay4::block_params::unit_num
disk_copy_overlay4_eject_disk   := disk_copy_overlay4::eject_disk
disk_copy_overlay4_noop := disk_copy_overlay4::noop
disk_copy_overlay4_on_line_buffer       := disk_copy_overlay4::on_line_buffer
disk_copy_overlay4_on_line_params2_unit_num     := disk_copy_overlay4::on_line_params2::unit_num
disk_copy_overlay4_on_line_params_unit_num      := disk_copy_overlay4::on_line_params::unit_num
disk_copy_overlay4_quit := disk_copy_overlay4::quit
disk_copy_overlay4_unit_number_to_driver_address        := disk_copy_overlay4::unit_number_to_driver_address
