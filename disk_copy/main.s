;;; ============================================================
;;; Overlay for Disk Copy - $0800 - $12FF (file 4/4)
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.scope main
        .org $800

        MLIEntry := MLIRelayImpl

;;; ============================================================

        .include "../lib/formatdiskii.s"

;;; ============================================================

        default_block_buffer := $1C00

        DEFINE_QUIT_PARAMS quit_params

on_line_buffer2 := $1300
        DEFINE_ON_LINE_PARAMS on_line_params2,, on_line_buffer2

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer

on_line_buffer:                 ; TODO: Move to $240 ?
        .res    16, 0

        DEFINE_READ_BLOCK_PARAMS block_params, default_block_buffer, 0

;;; This must allow $2000 bytes of contiguous space in the
;;; default memory bitmap.
volume_bitmap   := $4000

;;; ============================================================

.proc MLIRelayImpl
        params_src := $7E

        ;; Adjust return address on stack, compute
        ;; original params address.
        pla
        sta     params_src
        clc
        adc     #<3
        tax
        pla
        sta     params_src+1
        adc     #>3
        pha
        txa
        pha

        ;; Copy the params here
        ldy     #3      ; ptr is off by 1
:       lda     (params_src),y
        sta     params-1,y
        dey
        bne     :-

        ;; Bank and call
        sta     ALTZPOFF
        bit     ROMIN2

        jsr     MLI
params:  .res    3

        sta     ALTZPON
        php
        bit     LCBANK1
        bit     LCBANK1
        plp
        rts
.endproc

;;; ============================================================

.proc NoOp
        rts
.endproc

;;; ============================================================
;;; Quit back to ProDOS (which will launch DeskTop)

.proc Quit
        ;; Override in this scope
        MLIEntry := MLI

        jsr     auxlc::RestoreRamDisk
        sta     ALTZPOFF
        bit     ROMIN2

        jsr     HOME            ; Clear 80-col screen
        lda     #$11            ; Ctrl-Q - disable 80-col firmware
        jsr     COUT

        jsr     SETVID
        jsr     SETKBD
        jsr     INIT

        sta     DHIRESOFF
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR

        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80COL

        MLI_CALL QUIT, quit_params
        rts
.endproc

;;; ============================================================

.proc FormatDevice
        ldx     auxlc::dest_drive_index
        lda     auxlc::drive_unitnum_table,x
        sta     unit_number
        jsr     auxlc::IsDiskII
        beq     disk_ii

        ;; Get driver address
        lda     unit_number
        jsr     UnitNumberToDriverAddress ; sets $06, Z=1 if firmware

        lda     #DRIVER_COMMAND_FORMAT
        sta     DRIVER_COMMAND
        lda     unit_number
        and     #UNIT_NUM_MASK
        sta     DRIVER_UNIT_NUMBER
        jmp     ($06)

        ;; Use Disk II-specific code
disk_ii:
        unit_number := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     FormatDiskII
        rts
.endproc

;;; ============================================================
;;; Eject Disk via SmartPort

.proc EjectDiskImpl

.params control_params
param_count:    .byte   3
unit_number:    .byte   0
control_list:   .addr   list
control_code:   .byte   $04     ; For Apple/UniDisk 3.3: Eject disk
.endparams
control_params_unit_number := control_params::unit_number
list:   .word   0               ; 0 items in list


start:
        ptr := $6

        jsr     CheckSmartport
        bcs     done
        stx     control_params_unit_number

        ;; Do SmartPort call
        jsr     SmartportCall
        .byte   SPCall::Control
        .addr   control_params

done:   rts

SmartportCall:
        jmp     ($06)

.endproc
EjectDisk := EjectDiskImpl::start

;;; ============================================================
;;; Given $06 points at a firmware location ($CnXX), determine
;;; if it's SmartPort and (if so) point $06 at the dispatch address.
;;; Input: A = unit_number
;;; Output: C = 0 if SmartPort, C = 1 otherwise.
;;;         X = SmartPort unit number
;;; Assert: $06 points at a firmware location $CnXX

;;; TODO: Merge with lib/smartport.s

.proc CheckSmartport
        sp_addr := $06

        sta     unit_number

        ;; Get device driver address
        jsr     UnitNumberToDriverAddress ; sets $06, Z=1 if firmware
        beq     :+
fail:   sec                     ; not firmware
        rts
:
        ;; Find actual address
        copy    #$00, sp_addr   ; Point at $Cn00

        ldy     #$07            ; SmartPort signature byte ($Cn07)
        lda     (sp_addr),y     ; $00 = SmartPort
        bne     fail            ; nope

        ;; Locate SmartPort entry point: $Cn00 + ($CnFF) + 3
        ldy     #$FF
        lda     (sp_addr),y
        clc
        adc     #3
        sta     sp_addr

        ;; Figure out SmartPort control unit number in X

;;; Per Technical Note: ProDOS #21: Mirrored Devices and SmartPort
;;; http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.20.html
;;; ... but that predates ProDOS 2.x, which changes the scheme.
;;;
;;; * ProDOS 1.2...1.9 mirror S5,D3/4 to S2,D1/2 only, and leave `DEVADR`
;;;   entry pointing at $C5xx. Therefore, if the unit number slot matches
;;;   the driver slot, the device is not mirrored, and SmartPort unit is
;;;   1 or 2. Otherwise, the device is mirrored, and SmarPort unit is 3
;;;   or 4.
;;;
;;; * ProDOS 2.x mirror to non-device slots, and point `DEVADR` at
;;;   RAM-based drivers, which are already excluded above. Therefore the
;;;   device is not mirrored, the unit number slot will match the driver
;;;   slot, and the SmartPort unit is 1 or 2.

        ldx     #1              ; start with unit 1
        bit     unit_number     ; high bit is D
        bpl     :+
        inx                     ; X = 1 or 2 (for Drive 1 or 2)
:
        ;; Was it remapped? (ProDOS 1.x-only behavior)
        unit_number := *+1
        lda     #SELF_MODIFIED_BYTE
        and     #%01110000      ; 0SSSnnnn
        lsr
        lsr
        lsr
        lsr
        sta     mapped_slot     ; 00000SSS

        lda     sp_addr+1       ; $Cn
        and     #%00001111      ; $0n

        mapped_slot := *+1
        cmp     #SELF_MODIFIED_BYTE ; equal = not remapped
        beq     :+
        inx                     ; now X = 3 or 4
        inx
:
        clc                     ; exit with C=0 on success
        rts
.endproc

;;; ============================================================
;;; Get driver address for unit number
;;; Input: unit_number in A
;;; Output: $6/$7 points at driver address
;;;         Z=1 if a firmware address ($CnXX)

.proc UnitNumberToDriverAddress
        slot_addr := $06

        and     #%11110000      ; mask off drive/slot
        lsr                     ; 0DSSS000
        lsr                     ; 00DSSS00
        lsr                     ; 000DSSS0
        tax                     ; = slot * 2 + (drive == 2 ? 0x10 + 0x00)

        lda     DEVADR,x
        sta     slot_addr
        lda     DEVADR+1,x
        sta     slot_addr+1

        and     #$F0            ; is it $Cn ?
        cmp     #$C0            ; leave Z flag set if so
        rts
.endproc

;;; ============================================================
;;; Identify the disk type by reading the first block.
;;; NOTE: Not used for ProDOS disks.
;;; Inputs: `source_drive_index` must be set
;;; Outputs: sets `LD44D` to:
;;;            $81 = unknown/failure
;;;            $C0 = Pascal
;;;            $80 = DOS 3.3
.proc IdentifyNonprodosDiskType
        ldx     auxlc::source_drive_index
        lda     auxlc::drive_unitnum_table,x
        sta     block_params::unit_num
        lda     #$00
        sta     block_params::block_num
        sta     block_params::block_num+1
        jsr     ReadBlock
        bne     fail

        lda     default_block_buffer+1
        cmp     #$E0
        beq     :+
        jmp     l3

:       lda     default_block_buffer+2
        cmp     #$70
        beq     l2
        cmp     #$60
        beq     l2

fail:   lda     #$81
        sta     auxlc::LD44D
        rts

l2:     param_call auxlc::LDE9F, on_line_buffer2
        param_call auxlc::AdjustCase, on_line_buffer2
        lda     #$C0
        sta     auxlc::LD44D
        rts

l3:     cmp     #$A5
        bne     fail
        lda     default_block_buffer+2
        cmp     #$27
        bne     fail
        lda     #$80
        sta     auxlc::LD44D
        rts
.endproc

;;; ============================================================
;;; Reads the volume bitmap (blocks 6 through ...)

.proc ReadVolumeBitmap

        lda     #>volume_bitmap
        jsr     MarkUsedInMemoryBitmap

        lda     auxlc::source_drive_index
        asl     a
        tax
        copy16  auxlc::block_count_table,x, block_count_div8
        lsr16   block_count_div8    ; /= 8
        lsr16   block_count_div8
        lsr16   block_count_div8
        copy16  block_count_div8, auxlc::block_count_div8
        bit     auxlc::LD44D
        bmi     :+
        lda     auxlc::disk_copy_flag
        bne     :+
        jmp     QuickCopy
:

        ;; --------------------------------------------------
        ;; Disk Copy - initialize a fake volume bitmap so that
        ;; all pages are copied.
.scope
        ptr := $06


        add16   #volume_bitmap - 1, auxlc::block_count_div8, ptr

        ;; Zero out the volume bitmap
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
        cmp     #>volume_bitmap
        bne     loop1
        lda     ptr
        cmp     #<volume_bitmap
        bne     loop1

        lda     #$00            ; special case for last byte
        sta     (ptr),y         ; (this algorithm could be improved)

        ;; Now mark block-pages used in memory bitmap
        lda     #>volume_bitmap
        sta     ptr
        lda     auxlc::block_count_div8+1
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
        jsr     MarkUsedInMemoryBitmap
        rts
.endscope

        ;; --------------------------------------------------
        ;; Quick Copy - load volume bitmap from disk
        ;; so only used blocks are copied
.proc QuickCopy
        copy16  #6, block_params::block_num
        ldx     auxlc::source_drive_index
        lda     auxlc::drive_unitnum_table,x
        sta     block_params::unit_num
        copy16  #volume_bitmap, block_params::data_buffer
        jsr     ReadBlock
        beq     loop
        brk                     ; rude!

        ;; Each volume bitmap block holds $200*8 bits, so keep reading
        ;; blocks until we've accounted for all blocks on the volume.
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
        jsr     MarkUsedInMemoryBitmap
        jsr     ReadBlock
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
;;; Inputs: A=%DSSSnnnn (drive/slot part of unit number)
;;; Outputs: A=$80 if "removable", 0 otherwise

.proc IsDriveEjectableImpl

.params status_params
param_count:    .byte   3
unit_num:       .byte   1
list_ptr:       .addr   dib_buffer
status_code:    .byte   3       ; Return Device Information Block (DIB)
.endparams

PARAM_BLOCK dib_buffer, $220
Device_Statbyte1       .byte
Device_Size_Lo         .byte
Device_Size_Med        .byte
Device_Size_Hi         .byte
ID_String_Length       .byte
Device_Name            .res    16
Device_Type_Code       .byte
Device_Subtype_Code    .byte
Version                .word
END_PARAM_BLOCK

start:
        ptr := $6

        jsr     CheckSmartport
        bcs     not_removable
        stx     status_params::unit_num

        ;; Do SmartPort call
        jsr     SmartportCall
        .byte   SPCall::Status
        .addr   status_params
        bcs     not_removable

        lda     dib_buffer::Device_Type_Code
        cmp     #SPDeviceType::Disk35
        bne     not_removable

        ;; Assume all 3.5" drives are ejectable
        return  #$80

not_removable:
        return  #0

SmartportCall:
        jmp     ($06)
.endproc

IsDriveEjectable := IsDriveEjectableImpl::start

;;; ============================================================

.proc CopyBlocks
        sta     write_flag
        and     #$FF
        bpl     :+
        copy16  auxlc::start_block_div8, auxlc::block_num_div8
        copy    auxlc::start_block_shift, auxlc::block_num_shift
        ldx     auxlc::dest_drive_index
        lda     auxlc::drive_unitnum_table,x
        sta     block_params::unit_num
        jmp     common

:       copy16  auxlc::block_num_div8, auxlc::start_block_div8
        copy    auxlc::block_num_shift, auxlc::start_block_shift
        ldx     auxlc::source_drive_index
        lda     auxlc::drive_unitnum_table,x
        sta     block_params::unit_num

common: lda     #7
        sta     auxlc::block_index_shift
        lda     #0
        sta     auxlc::block_index_div8
        sta     L0FE4
        sta     L0FE5

loop:
        ;; Check for keypress
        lda     KBD
        cmp     #(CHAR_ESCAPE | $80)
        bne     :+
        bit     KBDSTRB
        jsr     auxlc::FlashEscapeMessage
        jmp     error
:

        bit     L0FE4
        bmi     success
        bit     L0FE5
        bmi     L0F69

        jsr     AdvanceToNextBlockIndex
        bcc     L0F51
        bne     :+
        cpx     #$00
        beq     success
:       ldy     #$80
        sty     L0FE4
L0F51:  stax    mem_block_addr
        jsr     AdvanceToNextBlock
        bcc     ReadOrWriteBlock
        bne     L0F62
        cpx     #$00
        beq     L0F69
L0F62:  ldy     #$80
        sty     L0FE5
        bne     ReadOrWriteBlock

L0F69:  return  #$80

success:
        return  #0

error:  return  #1

.proc ReadOrWriteBlock
        stax    block_params::block_num

        ;; A,X = address in memory
        ldx     mem_block_addr+1
        lda     mem_block_addr

        ;; Y = block number / 8
        ldy     auxlc::block_index_div8

        cpy     #$10
        bcs     need_move

        ;; --------------------------------------------------
        ;; read/write block directly to/from main mem buffer
        ;; $00-$0F = 0/$0000 - 0/$FFFF

        bit     write_flag
        bmi     :+
        jsr     ReadBlockToMain
        bmi     error
        jmp     loop

:       jsr     WriteBlockFromMain
        bmi     error
        jmp     loop

        ;; --------------------------------------------------

need_move:
        cpy     #$1D
        bcc     use_auxmem

        cpy     #$20
        bcs     use_lcbank2

        ;; --------------------------------------------------
        ;; read/write block to/from aux lcbank1
        ;; $1D-$1F = 1/$D000 - 1/$FFFF

        bit     write_flag
        bmi     :+
        jsr     ReadBlockToLcbank1
        bmi     error
        jmp     loop

:       jsr     WriteBlockFromLcbank1
        bmi     error
        jmp     loop

        ;; --------------------------------------------------
        ;; read/write block to/from aux
        ;; $10-$1C = 1/$0000 - 1/$CFFF
use_auxmem:
        bit     write_flag      ; 16-28
        bmi     :+
        jsr     auxlc::ReadBlockToAuxmem
        bmi     error
        jmp     loop

:       jsr     auxlc::WriteBlockFromAuxmem
        bmi     error
        jmp     loop

        ;; --------------------------------------------------
        ;; read/write block to/from aux lcbank2
        ;; $20+ = 1b/$D000 - 1b/$DFFF
use_lcbank2:
        bit     write_flag
        bmi     :+
        jsr     ReadBlockToLcbank2
        bmi     error
        jmp     loop

:       jsr     WriteBlockFromLcbank2
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
;;; Advance `block_num_div8` and `block_num_shift` to next used
;;; block per volume bitmap.
;;; Inputs: `block_num_div8` and `block_num_shift`
;;; Output: C=0 and A,X=block number if one exists
;;;         C=1 and A,X=$0000 if last block reached

.proc AdvanceToNextBlock
repeat: jsr     LookupInVolumeBitmap ; A,X=block number, Y=free?
        cpy     #0
        bne     free
        pha
        jsr     Next
        pla
        rts

free:   jsr     Next
        bcc     repeat          ; repeat unless last block
        lda     #0
        tax
        rts

.proc Next
        dec     auxlc::block_num_shift
        lda     auxlc::block_num_shift
        cmp     #$FF
        beq     :+

not_last:
        clc
        rts

:       lda     #$07
        sta     auxlc::block_num_shift
        inc16   auxlc::block_num_div8
        lda     auxlc::block_num_div8+1
        cmp     auxlc::block_count_div8+1
        bne     not_last
        lda     auxlc::block_num_div8
        cmp     auxlc::block_count_div8
        bne     not_last

        sec
        rts
.endproc
.endproc

;;; ============================================================
;;; Look up block in volume bitmap
;;; Input: Uses `block_num_div8` and `block_num_shift`
;;; Output: A,X = block number, Y = $FF if set in vol bitmap, $0 otherwise

.proc LookupInVolumeBitmap
        ptr := $06

        ;; Find byte in volume bitmap
        lda     #<volume_bitmap
        clc
        adc     auxlc::block_num_div8
        sta     ptr
        lda     #>volume_bitmap
        adc     auxlc::block_num_div8+1
        sta     ptr+1

        ;; Find bit in volume bitmap
        ldy     #0
        lda     (ptr),y
        ldx     auxlc::block_num_shift
        cpx     #$00
        beq     mask
:       lsr     a
        dex
        bne     :-
mask:   and     #$01

        ;; Set Y to 0 (if clear) or $FF (if set)
        bne     set
        tay                     ; Y=A=0
        beq     :+              ; always
set:    ldy     #$FF
:

        ;; Now compute block number
        ;; Why do this? Isn't this stashed anywhere else???
        lda     auxlc::block_num_div8+1
        sta     tmp
        lda     auxlc::block_num_div8
        asl     a               ; * 8
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp

        ldx     auxlc::block_num_shift
        clc
        adc     table,x

        pha
        tmp := *+1
        lda     #SELF_MODIFIED_BYTE
        adc     #$00
        tax
        pla

        ;; A,X = block number
        rts

table:  .byte   7, 6, 5, 4, 3, 2, 1, 0
.endproc

;;; ============================================================

.proc AdvanceToNextBlockIndex
        jsr     ComputeMemoryPageSignature
        cpy     #0
        beq     :+
        pha
        jsr     Next
        pla
        rts

:       jsr     Next
        bcc     AdvanceToNextBlockIndex
        lda     #$00
        tax
        rts

;;; Advance to next
.proc Next
        dec     auxlc::block_index_shift
        lda     auxlc::block_index_shift
        cmp     #$FF
        beq     :+
ok:     clc
        rts

:       lda     #7
        sta     auxlc::block_index_shift
        inc     auxlc::block_index_div8
        lda     auxlc::block_index_div8
        cmp     #$21
        bcc     ok

        sec
        rts
.endproc
.endproc

;;; ============================================================
;;; Compute memory page signature; low nibble is high nibble of
;;; page, high nibble is "bank" (0=main, 1=aux, 2=aux lcbank2)
;;; Input: `block_index_div8` and `block_index_shift`
;;; Output: A,X=address to store block; Y=bit is set in bitmap

.proc ComputeMemoryPageSignature
        ;; Read from bitmap
        ldx     auxlc::block_index_div8
        lda     memory_bitmap,x
        ldx     auxlc::block_index_shift
        cpx     #0
        beq     mask
:       lsr     a
        dex
        bne     :-
mask:   and     #$01

        bne     set
        ldy     #$00
        beq     :+              ; always
set:    ldy     #$FF
:

        ;; Now compute address to store in memory
        lda     auxlc::block_index_div8
        cmp     #$10
        bcs     :+

        ;; $00-$0F is main pages $00...$FE
        ;; $10-$1F is aux  pages $00...$FE
        ;; $20.... is aux lcbank2 $D000...

calc:   asl     a               ; *= 16
        asl     a
        asl     a
        asl     a
        ldx     auxlc::block_index_shift
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

.proc FreeVolBitmapPages
        page_num := $06         ; not a pointer, for once!

        lda     #>volume_bitmap
        sta     page_num
        lda     #0
        sta     count
loop:   lda     page_num
        jsr     MarkFreeInMemoryBitmap
        inc     page_num
        inc     page_num
        inc     count
        inc     count

        count := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     auxlc::block_count_div8+1
        beq     loop
        bcc     loop
        rts

.proc MarkFreeInMemoryBitmap
        jsr     GetBitmapOffsetShift
        tay
        lda     #1
        cpx     #0
        beq     mask

:       asl     a
        dex
        bne     :-

mask:   ora     memory_bitmap,y
        sta     memory_bitmap,y
        rts
.endproc
.endproc

;;; ============================================================

.proc MarkUsedInMemoryBitmap
        jsr     GetBitmapOffsetShift
        tay
        lda     #1
        cpx     #0
        beq     mask

:       asl     a
        dex
        bne     :-

mask:   eor     #$FF
        and     memory_bitmap,y
        sta     memory_bitmap,y
        rts
.endproc

;;; ============================================================
;;; Sets X to 7 - (low nibble of A / 2) -- bit shift
;;; Sets A to the high nibble of A -- bitmap offset
;;; e.g. $76 ==> A = $07
;;;              X = $04

.proc GetBitmapOffsetShift
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
;;; Read block (w/ retries) to main memory
;;; Inputs: A,X=mem address to store it
;;; Outputs: A=0 on success, nonzero otherwise

.proc ReadBlockToMain
        stax    block_params::data_buffer
retry:  jsr     ReadBlock
        beq     done
        ldx     #0              ; reading
        jsr     auxlc::ShowBlockError
        bmi     done
        bne     retry
done:   rts
.endproc

;;; ============================================================
;;; Read block (w/ retries) to aux LCBANK1 memory
;;; Inputs: A,X=mem address to store it
;;; Outputs: A=0 on success, nonzero otherwise

.proc ReadBlockToLcbank1
        ptr1 := $06
        ptr2 := $08             ; one page up

        sta     ptr1
        sta     ptr2
        stx     ptr1+1
        stx     ptr2+1
        inc     ptr2+1

        copy16  #default_block_buffer, block_params::data_buffer
retry:  jsr     ReadBlock
        beq     move
        ldx     #0              ; reading
        jsr     auxlc::ShowBlockError
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
;;; Read block (w/ retries) to aux LCBANK2 memory
;;; Inputs: A,X=mem address to store it
;;; Outputs: A=0 on success, nonzero otherwise

.proc ReadBlockToLcbank2
        ptr1 := $06
        ptr2 := $08             ; one page up

        sta     ptr1
        sta     ptr2
        stx     ptr1+1
        stx     ptr2+1
        inc     ptr2+1

        copy16  #default_block_buffer, block_params::data_buffer
retry:  jsr     ReadBlock
        beq     move
        ldx     #0              ; reading
        jsr     auxlc::ShowBlockError
        beq     move
        bpl     retry
        bit     LCBANK1
        bit     LCBANK1
        return  #$80

move:   bit     LCBANK2
        bit     LCBANK2
        ldy     #$FF
        iny
loop:   lda     default_block_buffer,y
        sta     (ptr1),y
        lda     default_block_buffer+$100,y
        sta     (ptr2),y
        iny
        bne     loop
        bit     LCBANK1
        bit     LCBANK1
        return  #$00
.endproc

;;; ============================================================
;;; Write block (w/ retries) from main memory
;;; Inputs: A,X=address to read from
;;; Outputs: A=0 on success, nonzero otherwise

.proc WriteBlockFromMain
        stax    block_params::data_buffer
retry:  jsr     WriteBlock
        beq     done
        ldx     #$80            ; writing
        jsr     auxlc::ShowBlockError
        beq     done
        bpl     retry
done:   rts
.endproc

;;; ============================================================
;;; Write block (w/ retries) from aux LCBANK1 memory
;;; Inputs: A,X=address to read from
;;; Outputs: A=0 on success, nonzero otherwise

.proc WriteBlockFromLcbank1
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

retry:  jsr     WriteBlock
        beq     done
        ldx     #$80            ; writing
        jsr     auxlc::ShowBlockError
        beq     done
        bpl     retry
done:   rts
.endproc

;;; ============================================================
;;; Write block (w/ retries) from aux LCBANK2 memory
;;; Inputs: A,X=address to read from
;;; Outputs: A=0 on success, nonzero otherwise

.proc WriteBlockFromLcbank2
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

        bit     LCBANK1
        bit     LCBANK1
retry:  jsr     WriteBlock
        beq     done
        ldx     #$80            ; writing
        jsr     auxlc::ShowBlockError
        beq     done
        bpl     retry
done:   rts
.endproc

;;; ============================================================

.proc CallOnLine2
        MLI_CALL ON_LINE, on_line_params2
        rts
.endproc

.proc CallOnLine
        MLI_CALL ON_LINE, on_line_params
        rts
.endproc

.proc WriteBlock
        MLI_CALL WRITE_BLOCK, block_params
        rts
.endproc

.proc ReadBlock
        MLI_CALL READ_BLOCK, block_params
        rts
.endproc

;;; ============================================================

;;; Memory Availability Bitmap
;;;
;;; Each bit represents a double-page, enough for one 512-byte
;;; disk block. 1 = available, 0 = reserved.

memory_bitmap:
        ;; Main memory
        .byte   %00000000       ; $00-$0F - ZP/Stack/Text, then Disk Copy code...
        .byte   %00111100       ; $10-$1F - but $14-1B free ($1C = i/o buf)
        .byte   %00000000       ; $20-$2F - DHR graphics page
        .byte   %00000000       ; $30-$3F - DHR graphics page
        .byte   %11111111       ; $40-$4F - free
        .byte   %11111111       ; $50-$5F - free
        .byte   %11111111       ; $60-$6F - free
        .byte   %11111111       ; $70-$7F - free
        .byte   %11111111       ; $80-$8F - free
        .byte   %11111111       ; $90-$9F - free
        .byte   %11111111       ; $A0-$AF - free
        .byte   %11111110       ; $B0-$BF - free except $BE/F pages (ProDOS GP)
        .byte   %00000000       ; $C0-$CF - I/O
        .byte   %00000000       ; $D0-$DF - ProDOS
        .byte   %00000000       ; $E0-$EF - ProDOS
        .byte   %00000000       ; $F0-$FF - ProDOS

        ;; Aux memory
        .byte   %00001111       ; $00-$0F - free after ZP/Stack/Text
        .byte   %11111111       ; $10-$1F - free
        .byte   %00000000       ; $20-$2F - DHR graphics page
        .byte   %00000000       ; $30-$3F - DHR graphics page
        .byte   %00000000       ; $40-$4F - MGTK code
        .byte   %00000000       ; $50-$5F - MGTK code
        .byte   %00000000       ; $60-$6F - MGTK code
        .byte   %00000000       ; $70-$7F - MGTK code
        .byte   %00000000       ; $80-$8F - MGTK, font
        .byte   %11111111       ; $90-$9F - free
        .byte   %11111111       ; $A0-$AF - free
        .byte   %11111111       ; $B0-$BF - free
        .byte   %00000000       ; $C0-$CF - I/O
        .byte   %00000000       ; $D0-$DF - Disk Copy code
        .byte   %00000000       ; $E0-$EF - Disk Copy code
        .byte   %01111111       ; $F0-$FF - free $F2 and up

        ;; Aux memory - LCBANK2
        .byte   %11111111       ; $D0-$DF - free

;;; ============================================================
;;; Inputs: A = unit num (DSSSxxxx), X,Y = driver address
;;; Outputs: X,Y = blocks

.proc GetDeviceBlocksUsingDriver
        sta     ALTZPOFF

        and     #UNIT_NUM_MASK
        sta     DRIVER_UNIT_NUMBER
        stxy    @driver

        lda     #$00
        sta     DRIVER_COMMAND  ; $00 = STATUS
        sta     DRIVER_BUFFER
        sta     DRIVER_BUFFER+1
        sta     DRIVER_BLOCK_NUMBER
        sta     DRIVER_BLOCK_NUMBER+1

        @driver := *+1
        jsr     SELF_MODIFIED

        sta     ALTZPON
        rts
.endproc

;;; ============================================================
;;; On IIgs, force preferred RGB mode. No-op otherwise.
;;; Assert: LCBANK1 is banked in

.proc ResetIIgsRGB
        bit     ROMIN2
        sec
        jsr     IDROUTINE
        bit     LCBANK1
        bit     LCBANK1
        bcs     done

        bit     SETTINGS + DeskTopSettings::rgb_color
        bmi     color

mono:   ldy     #$80            ; MONOCOLOR - Mono
        lda     NEWVIDEO
        ora     #(1<<5)         ; B&W
        bne     store           ; always

color:  ldy     #$00            ; MONOCOLOR - Color
        lda     NEWVIDEO
        and     #<~(1<<5)       ; Color

store:  sta     NEWVIDEO
        sty     MONOCOLOR

done:   rts
.endproc


;;; ============================================================

        PAD_TO $1300

.endscope

main__FormatDevice              := main::FormatDevice
main__IdentifyNonprodosDiskType := main::IdentifyNonprodosDiskType
main__ReadVolumeBitmap          := main::ReadVolumeBitmap
main__IsDriveEjectable          := main::IsDriveEjectable
main__CopyBlocks                := main::CopyBlocks
main__FreeVolBitmapPages        := main::FreeVolBitmapPages
main__CallOnLine2               := main::CallOnLine2
main__CallOnLine                := main::CallOnLine
main__WriteBlock                := main::WriteBlock
main__ReadBlock                 := main::ReadBlock
main__block_params_block_num    := main::block_params::block_num
main__block_params_data_buffer  := main::block_params::data_buffer
main__block_params_unit_num     := main::block_params::unit_num
main__EjectDisk                 := main::EjectDisk
main__NoOp                      := main::NoOp
main__on_line_buffer            := main::on_line_buffer
main__on_line_params2_unit_num  := main::on_line_params2::unit_num
main__on_line_params_unit_num   := main::on_line_params::unit_num
main__Quit                      := main::Quit
main__UnitNumberToDriverAddress := main::UnitNumberToDriverAddress
main__GetDeviceBlocksUsingDriver := main::GetDeviceBlocksUsingDriver
main__on_line_buffer2           := main::on_line_buffer2
main__ResetIIgsRGB              := main::ResetIIgsRGB
