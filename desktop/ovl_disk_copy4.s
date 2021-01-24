;;; ============================================================
;;; Overlay for Disk Copy - $0800 - $12FF (file 4/4)
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc disk_copy_overlay4
        .org $800

;;; ============================================================

        .include "../lib/formatdiskii.s"

;;; ============================================================

        default_block_buffer := $1C00

        DEFINE_QUIT_PARAMS quit_params

        DEFINE_ON_LINE_PARAMS on_line_params2,, $1300

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer

on_line_buffer:
        .res    16, 0

        DEFINE_READ_BLOCK_PARAMS block_params, default_block_buffer, 0

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

.proc format_device
        ldx     disk_copy_overlay3::dest_drive_index
        lda     disk_copy_overlay3::drive_unitnum_table,x
        sta     unit_number
        and     #$0F
        beq     disk_ii

        ;; Get driver address
        lda     unit_number
        jsr     unit_number_to_driver_address

        lda     #DRIVER_COMMAND_FORMAT
        sta     DRIVER_COMMAND
        lda     unit_number
        and     #$F0
        sta     DRIVER_UNIT_NUMBER
        jmp     ($06)

        ;; Use Disk II-specific code
disk_ii:
        lda     unit_number
        jsr     FormatDiskII
        rts

unit_number:
        .byte   0
.endproc

;;; ============================================================
;;; Eject Disk via SmartPort

.proc eject_disk
        ptr := $6

        sta     unit_num
        jsr     unit_number_to_driver_address
        bne     done            ; not firmware; can't tell if SmartPort or not

        lda     #$00            ; Point at $Cn00
        sta     ptr

        ldy     #$07            ; Check firmware bytes
        lda     (ptr),y         ; $Cn07 = $00 ??
        bne     done

        ldy     #$FB
        lda     (ptr),y         ; $CnFB = $7F ??
        and     #$7F
        bne     done

        ldy     #$FF
        lda     (ptr),y
        clc
        adc     #3              ; Locate dispatch routine (offset $CnFF + 3)
        sta     ptr

        lda     unit_num
        jsr     unit_num_to_sp_unit_number
        sta     control_params_unit_number

        ;; Do SmartPort call
        jsr     smartport_call
        .byte   $04             ; SmartPort: CONTROL
        .addr   control_params

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
unit_num:
        .byte   0
        .byte   0

.endproc

;;; ============================================================
;;; Get driver address for unit number
;;; Input: unit_number in A
;;; Output: $6/$7 points at driver address
;;;         Z=1 if a firmware address ($CnXX)

.proc unit_number_to_driver_address
        addr := $06

        and     #%11110000      ; mask off drive/slot
        lsr                     ; 0DSSS000
        lsr                     ; 00DSSS00
        lsr                     ; 000DSSS0
        tax                     ; = slot * 2 + (drive == 2 ? 0x10 + 0x00)

        lda     DEVADR,x
        sta     addr
        lda     DEVADR+1,x
        sta     addr+1

        and     #$F0            ; is it $Cn ?
        cmp     #$C0            ; leave Z flag set if so
        rts
.endproc

;;; ============================================================
;;; Map unit number to smartport device number (1-4)
;;; TODO: The logic looks sketchy, assumes specific remapping.

.proc unit_num_to_sp_unit_number
        pha                     ; DSSS0000
        rol     a               ; C=D
        pla
        php                     ; DSSS0000
        and     #$20            ; 00100000 - "is an odd slot" ???
        lsr     a
        lsr     a
        lsr     a
        lsr     a               ; 00000010
        plp                     ; C=D
        adc     #$01            ;
        rts
.endproc

;;; ============================================================

L0D5F:  ldx     disk_copy_overlay3::source_drive_index
        lda     disk_copy_overlay3::drive_unitnum_table,x
        sta     block_params::unit_num
        lda     #$00
        sta     block_params::block_num
        sta     block_params::block_num+1
        jsr     read_block
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

L0D90:  param_call disk_copy_overlay3::LDE9F, $1300
        param_call disk_copy_overlay3::adjust_case, $1300
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
;;; Reads the volume bitmap (blocks 6 through ...)

.proc read_volume_bitmap

        volume_bitmap_buffer := $1400

        lda     #$14
        jsr     clear_bit_in_bitmap
        lda     disk_copy_overlay3::source_drive_index
        asl     a
        tax
        copy16  disk_copy_overlay3::block_count_table,x, block_count_div8
        lsr16   block_count_div8    ; /= 8
        lsr16   block_count_div8
        lsr16   block_count_div8
        copy16  block_count_div8, disk_copy_overlay3::block_count_div8
        bit     disk_copy_overlay3::LD44D
        bmi     :+
        lda     disk_copy_overlay3::disk_copy_flag
        bne     :+
        jmp     L0E4D
:

        ;; --------------------------------------------------
        ;; Disk Copy
.scope
        ptr := $06


        add16   #volume_bitmap_buffer - 1, disk_copy_overlay3::block_count_div8, ptr

        ;; Zero out volume_bitmap_buffer
        ldy     #0
loop1:  lda     #0
        sta     (ptr),y

        dec     ptr             ; dec16 ptr
        lda     ptr
        cmp     #$FF
        bne     :+
        dec     ptr+1
:
        lda     ptr+1
        cmp     #>volume_bitmap_buffer
        bne     loop1
        lda     ptr
        cmp     #<volume_bitmap_buffer
        bne     loop1

        lda     #$00            ; special case for last byte
        sta     (ptr),y         ; (this algorithm could be improved)

        ;; Bail early if < 4096 blocks ???
        lda     disk_copy_overlay3::block_count_div8+1
        cmp     #$02
        bcs     :+
        rts

:       lda     #>volume_bitmap_buffer
        sta     ptr
        lda     disk_copy_overlay3::block_count_div8+1
        pha
loop:   inc     ptr
        inc     ptr
        pla
        sec
        sbc     #$02
        pha
        bmi     l5
        jsr     l6
        jmp     loop

l5:     pla

l6:     lda     ptr
        jsr     clear_bit_in_bitmap
        rts
.endscope

        ;; --------------------------------------------------
        ;; Quick Copy
.proc L0E4D
        copy16  #6, block_params::block_num
        ldx     disk_copy_overlay3::source_drive_index
        lda     disk_copy_overlay3::drive_unitnum_table,x
        sta     block_params::unit_num
        copy16  #volume_bitmap_buffer, block_params::data_buffer
        jsr     read_block
        beq     loop
        brk                     ; rude!

        ;; Each volume bitmap block holds $200*8 bits, so keep reading
        ;; blocks until we've accounted for all blocks on the volume.
        ;; BUG: This blows past $1C00 on large volumes. Issue #386
        ;; (A 32MB volume requires $2000 bytes for the bitmap!)
loop:   sub16   block_count_div8, #$200, block_count_div8
        lda     block_count_div8+1
        bpl     :+
        rts

:       lda     block_count_div8
        bne     :+
        rts

:       add16   block_params::data_buffer, #$200, block_params::data_buffer

        inc     block_params::block_num
        lda     block_params::data_buffer+1
        jsr     clear_bit_in_bitmap
        jsr     read_block
        beq     :+
        brk                     ; rude!

:       jmp     loop
.endproc

        ;; Number of blocks to copy, divided by 8
block_count_div8:
        .word   0
.endproc

;;; ============================================================
;;; Check if device is removable.
;;; NOTE: Test is flawed, relies on deprecated detection method.
;;; Inputs: A=%DSSSnnnn (drive/slot part of unit number)
;;; Outputs: A=0 if "removable", $80 otherwise

.proc is_drive_removable
        ;; Search in DEVLST for the matching drive/slot combo.
        and     #$F0
        sta     unit_num
        ldx     DEVCNT
:       lda     DEVLST,x
        and     #$F0
        cmp     unit_num
        beq     found
        dex
        bpl     :-
success:
        return  #$00

        ;; Look in the low nibble for device type. (See note)
found:  lda     DEVLST,x
        and     #$0F

;;; This assumes the low nibble of the unit number is an "id nibble" which
;;; is wrong. When MouseDesk was written, $xB signaled a "removable" device
;;; like the UniDisk 3.5, but this is not valid.
;;;
;;; Technical Note: ProDOS #21: Identifying ProDOS Devices
;;; http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.21.html

        cmp     #$0B
        bne     success
        return  #$80

unit_num:
        .byte   0
.endproc

;;; ============================================================

.proc L0ED7
        bit     KBDSTRB         ; clear strobe

        sta     write_flag
        and     #$FF
        bpl     :+
        copy16  disk_copy_overlay3::LD424, disk_copy_overlay3::LD421
        lda     disk_copy_overlay3::LD426
        sta     disk_copy_overlay3::LD423
        ldx     disk_copy_overlay3::dest_drive_index
        lda     disk_copy_overlay3::drive_unitnum_table,x
        sta     block_params::unit_num
        jmp     common

:       copy16  disk_copy_overlay3::LD421, disk_copy_overlay3::LD424
        lda     disk_copy_overlay3::LD423
        sta     disk_copy_overlay3::LD426
        ldx     disk_copy_overlay3::source_drive_index
        lda     disk_copy_overlay3::drive_unitnum_table,x
        sta     block_params::unit_num

common: lda     #$07
        sta     disk_copy_overlay3::block_num_shift
        lda     #0
        sta     disk_copy_overlay3::block_num_div8
        sta     L0FE4
        sta     L0FE5

loop:
        ;; Check for keypress
        lda     KBD
        cmp     #(CHAR_ESCAPE | $80)
        bne     :+
        jsr     disk_copy_overlay3::flash_escape_message
        jmp     error
:

        bit     L0FE4
        bmi     success
        bit     L0FE5
        bmi     L0F69

        jsr     L107F
        bcc     L0F51
        bne     :+
        cpx     #$00
        beq     success
:       ldy     #$80
        sty     L0FE4
L0F51:  stax    mem_block_addr
        jsr     L0FE9
        bcc     L0F72
        bne     L0F62
        cpx     #$00
        beq     L0F69
L0F62:  ldy     #$80
        sty     L0FE5
        bne     L0F72

L0F69:  return  #$80

success:
        return  #0

error:  return  #1

.proc L0F72
        stax    block_params::block_num

        ;; A,X = address in memory
        ldx     mem_block_addr+1
        lda     mem_block_addr

        ;; Y = block number / 8
        ldy     disk_copy_overlay3::block_num_div8

        cpy     #$10
        bcs     need_move

        ;; --------------------------------------------------
        ;; read/write block directly to/from main mem buffer
        ;; $4000-$BEFF

        bit     write_flag      ; 0-15
        bmi     :+
        jsr     read_block_direct
        bmi     error
        jmp     loop

:       jsr     write_block_direct
        bmi     error
        jmp     loop

        ;; --------------------------------------------------

need_move:
        cpy     #$1D
        bcc     use_auxmem

        cpy     #$20
        bcs     use_lcbank2

        ;; --------------------------------------------------
        ;; read/write block to/from main, with a move
        ;; $F200-$FFFF

        bit     write_flag      ; 29-31
        bmi     :+
        jsr     read_block_to_main
        bmi     error
        jmp     loop

:       jsr     write_block_from_main
        bmi     error
        jmp     loop

        ;; --------------------------------------------------
        ;; read/write block to/from aux
        ;; $0C00-$1FFF
        ;; $9000-$BFFF
use_auxmem:
        bit     write_flag      ; 16-28
        bmi     :+
        jsr     disk_copy_overlay3::read_block_to_auxmem
        bmi     error
        jmp     loop

:       jsr     disk_copy_overlay3::write_block_from_auxmem
        bmi     error
        jmp     loop

        ;; --------------------------------------------------
        ;; read/write block to/from aux lcbank2
        ;; $D000-$DFFF
use_lcbank2:
        bit     write_flag      ; 32+
        bmi     :+
        jsr     read_block_to_lcbank2
        bmi     error
        jmp     loop

:       jsr     write_block_from_lcbank2
        bmi     l4
        jmp     loop

l4:     jmp     error
.endproc

L0FE4:  .byte   0
L0FE5:  .byte   0

write_flag:                     ; high bit set if writing
        .byte   0

mem_block_addr:
        .word   0
.endproc

;;; ============================================================

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
        cmp     disk_copy_overlay3::block_count_div8+1
        bne     L1009
        lda     disk_copy_overlay3::LD421
        cmp     disk_copy_overlay3::block_count_div8
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
L1077:  .byte   7, 6, 5, 4, 3, 2, 1, 0

;;; ============================================================

.proc L107F
        jsr     L10B2
        cpy     #0
        beq     :+
        pha
        jsr     next
        pla
        rts

:       jsr     next
        bcc     L107F
        lda     #$00
        tax
        rts

;;; Advance to next
.proc next
        dec     disk_copy_overlay3::block_num_shift
        lda     disk_copy_overlay3::block_num_shift
        cmp     #$FF
        beq     :+
ok:     clc
        rts

:       lda     #7
        sta     disk_copy_overlay3::block_num_shift
        inc     disk_copy_overlay3::block_num_div8
        lda     disk_copy_overlay3::block_num_div8
        cmp     #$21
        bcc     ok

        sec
        rts
.endproc
.endproc

;;; ============================================================
;;; Output: A,X=address to store block; Y=bit is set in bitmap

.proc L10B2
        ;; Read from bitmap
        ldx     disk_copy_overlay3::block_num_div8
        lda     bitmap,x
        ldx     disk_copy_overlay3::block_num_shift
        cpx     #0
        beq     skip
:       lsr     a
        dex
        bne     :-
skip:   and     #$01

        bne     set
        ldy     #$00
        beq     :+              ; always
set:    ldy     #$FF
:

        ;; Now compute address to store in memory
        lda     disk_copy_overlay3::block_num_div8
        cmp     #$10
        bcs     :+

        ;; $00-$0F end up based at $0000
        ;; $10-$1F end up based at $0000 as well
        ;; $20.... end up based at $D000

calc:   asl     a               ; *= 16
        asl     a
        asl     a
        asl     a
        ldx     disk_copy_overlay3::block_num_shift
        clc
        adc     table,x
        tax
        lda     #$00
        rts

:       cmp     #$20            ; 16-31
        bcs     :+
        sec
        sbc     #$10
        jmp     calc

:       sec
        sbc     #$13
        jmp     calc

table:  .byte   $0E, $0C, $0A, $08, $06, $04, $02, $00
.endproc

;;; ============================================================

.proc L10FB
        lda     #$14
        sta     $06
        lda     #$00
        sta     tmp
loop:   lda     $06
        jsr     set_bit_in_bitmap
        inc     $06
        inc     $06
        inc     tmp
        inc     tmp
        lda     tmp
        cmp     disk_copy_overlay3::block_count_div8+1
        beq     loop
        bcc     loop
        rts

tmp:    .byte   0

.proc set_bit_in_bitmap
        jsr     get_bitmap_offset_shift
        tay
        sec
        cpx     #0
        beq     skip

:       asl     a
        dex
        bne     :-

skip:   ora     bitmap,y
        sta     bitmap,y
        rts
.endproc
.endproc

;;; ============================================================

.proc clear_bit_in_bitmap
        jsr     get_bitmap_offset_shift
        tay
        sec
        cpx     #0
        beq     skip

:       asl     a
        dex
        bne     :-

skip:   eor     #$FF
        and     bitmap,y
        sta     bitmap,y
        rts
.endproc

;;; ============================================================
;;; Sets X to 7 - (low nibble of A / 2) -- bit shift
;;; Sets A to the high nibble of A -- bitmap offset
;;; e.g. $76 ==> A = $07
;;;              X = $04

.proc get_bitmap_offset_shift
        pha
        and     #$0F
        lsr     a
        tax
        lda     table,x
        tax
        pla
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        rts

table:  .byte   7, 6, 5, 4, 3, 2, 1, 0
.endproc

;;; ============================================================
;;; Read block (w/ retries) directly to main memory (no move)
;;; Inputs: A,X=mem address to store it
;;; Outputs: A=0 on success, nonzero otherwise

.proc read_block_direct
        stax    block_params::data_buffer
retry:  jsr     read_block
        beq     done
        ldx     #0              ; reading
        jsr     disk_copy_overlay3::show_block_error
        bmi     done
        bne     retry
done:   rts
.endproc

;;; ============================================================
;;; Read block (w/ retries) and store it to main memory
;;; Inputs: A,X=mem address to store it
;;; Outputs: A=0 on success, nonzero otherwise

.proc read_block_to_main
        ptr1 := $06
        ptr2 := $08             ; one page up

        sta     ptr1
        sta     ptr2
        stx     ptr1+1
        stx     ptr2+1
        inc     ptr2+1

        copy16  #default_block_buffer, block_params::data_buffer
retry:  jsr     read_block
        beq     move
        ldx     #0              ; reading
        jsr     disk_copy_overlay3::show_block_error
        beq     move
        bpl     retry
        return  #$80

move:   ldy     #$FF
        iny
loop:   lda     default_block_buffer,y
        sta     (ptr1),y
        lda     default_block_buffer+$100,y
        sta     (ptr2),y
        iny
        bne     loop

        return  #0
.endproc

;;; ============================================================
;;; Read block (w/ retries) and store it to aux LCBANK2 memory
;;; Inputs: A,X=mem address to store it
;;; Outputs: A=0 on success, nonzero otherwise

.proc read_block_to_lcbank2
        ptr1 := $06
        ptr2 := $08             ; one page up

        sta     ptr1
        sta     ptr2
        stx     ptr1+1
        stx     ptr2+1
        inc     ptr2+1

        copy16  #default_block_buffer, block_params::data_buffer
retry:  jsr     read_block
        beq     move
        ldx     #0              ; reading
        jsr     disk_copy_overlay3::show_block_error
        beq     move
        bpl     retry
        lda     LCBANK1
        lda     LCBANK1
        return  #$80

move:   lda     LCBANK2
        lda     LCBANK2
        ldy     #$FF
        iny
loop:   lda     default_block_buffer,y
        sta     (ptr1),y
        lda     default_block_buffer+$100,y
        sta     (ptr2),y
        iny
        bne     loop
        lda     LCBANK1
        lda     LCBANK1
        return  #$00
.endproc

;;; ============================================================
;;; Write block (w/ retries) directly from main memory (no move)
;;; Inputs: A,X=address to read from
;;; Outputs: A=0 on success, nonzero otherwise

.proc write_block_direct
        stax    block_params::data_buffer
retry:  jsr     write_block
        beq     done
        ldx     #$80            ; writing
        jsr     disk_copy_overlay3::show_block_error
        beq     done
        bpl     retry
done:   rts
.endproc

;;; ============================================================
;;; Write block (w/ retries) from main memory
;;; Inputs: A,X=address to read from
;;; Outputs: A=0 on success, nonzero otherwise

.proc write_block_from_main
        ptr1 := $06
        ptr2 := $08             ; one page up

        sta     ptr1
        sta     ptr2
        stx     ptr1+1
        stx     ptr2+1
        inc     ptr2+1

        copy16  #default_block_buffer, block_params::data_buffer
        ldy     #$FF
        iny
L1223:  lda     (ptr1),y
        sta     default_block_buffer,y
        lda     (ptr2),y
        sta     default_block_buffer+$100,y
        iny
        bne     L1223
retry:  jsr     write_block
        beq     done
        ldx     #$80            ; writing
        jsr     disk_copy_overlay3::show_block_error
        beq     done
        bpl     retry
done:   rts
.endproc

;;; ============================================================
;;; Write block (w/ retries) from aux LCBANK2 memory
;;; Inputs: A,X=address to read from
;;; Outputs: A=0 on success, nonzero otherwise

.proc write_block_from_lcbank2
        bit     LCBANK2
        bit     LCBANK2

        ptr1 := $06
        ptr2 := $08             ; one page up

        sta     ptr1
        sta     ptr2
        stx     ptr1+1
        stx     ptr2+1
        inc     ptr2+1

        copy16  #default_block_buffer, block_params::data_buffer
        ldy     #$FF
        iny
loop:   lda     (ptr1),y
        sta     default_block_buffer,y
        lda     (ptr2),y
        sta     default_block_buffer+$100,y
        iny
        bne     loop

        lda     LCBANK1
        lda     LCBANK1
retry:  jsr     write_block
        beq     done
        ldx     #$80            ; writing
        jsr     disk_copy_overlay3::show_block_error
        beq     done
        bpl     retry
done:   rts
.endproc

;;; ============================================================

.proc bell
        sta     ALTZPOFF
        sta     ROMIN2
        jsr     BELL1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

.proc call_on_line2
        MLI_RELAY_CALL ON_LINE, on_line_params2
        rts
.endproc

.proc call_on_line
        MLI_RELAY_CALL ON_LINE, on_line_params
        rts
.endproc

.proc write_block
        MLI_RELAY_CALL WRITE_BLOCK, block_params
        rts
.endproc

.proc read_block
        MLI_RELAY_CALL READ_BLOCK, block_params
        rts
.endproc

;;; ============================================================

bitmap: .byte   0
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
;;; Inputs: A = device num (DSSSxxxx), X,Y = driver address
;;; Outputs: X,Y = blocks

.proc get_device_blocks_using_driver
        sta     ALTZPOFF

        and     #$F0
        sta     DRIVER_UNIT_NUMBER
        stxy    @driver

        lda     #$00
        sta     DRIVER_COMMAND  ; $00 = STATUS
        sta     DRIVER_BUFFER
        sta     DRIVER_BUFFER+1
        sta     DRIVER_BLOCK_NUMBER
        sta     DRIVER_BLOCK_NUMBER+1

        @driver := *+1
        jsr     dummy0000

        sta     ALTZPON
        rts
.endproc

;;; ============================================================

        PAD_TO $1300

.endproc

disk_copy_overlay4_format_device        := disk_copy_overlay4::format_device
disk_copy_overlay4_unit_num_to_sp_unit_number        := disk_copy_overlay4::unit_num_to_sp_unit_number
disk_copy_overlay4_L0D5F        := disk_copy_overlay4::L0D5F
disk_copy_overlay4_read_volume_bitmap   := disk_copy_overlay4::read_volume_bitmap
disk_copy_overlay4_is_drive_removable        := disk_copy_overlay4::is_drive_removable
disk_copy_overlay4_L0ED7        := disk_copy_overlay4::L0ED7
disk_copy_overlay4_L10FB        := disk_copy_overlay4::L10FB
disk_copy_overlay4_bell         := disk_copy_overlay4::bell
disk_copy_overlay4_call_on_line2        := disk_copy_overlay4::call_on_line2
disk_copy_overlay4_call_on_line         := disk_copy_overlay4::call_on_line
disk_copy_overlay4_write_block          := disk_copy_overlay4::write_block
disk_copy_overlay4_read_block           := disk_copy_overlay4::read_block
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
disk_copy_overlay4_get_device_blocks_using_driver := disk_copy_overlay4::get_device_blocks_using_driver