;;; ============================================================
;;; Disk Copy - Main Memory Segment $0800
;;;
;;; Compiled as part of disk_copy.s
;;; ============================================================

        BEGINSEG SegmentMain

.scope main

        MLIEntry := MLIRelayImpl
        MGTKEntry := auxlc::MGTKRelayImpl

;;; ============================================================

        .include "../lib/formatdiskii.s"

;;; ============================================================

        default_block_buffer := $1C00 ; if this is changed, update `memory_bitmap`

        DEFINE_QUIT_PARAMS quit_params

        ;; Used only for single device
        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer
.struct
        .org $300
on_line_buffer  .res    16      ; enough for single device
.endstruct

        ;; Used for enumerating all devices and single device
        DEFINE_ON_LINE_PARAMS on_line_params2,, on_line_buffer2
.struct
        .org  ::kSegmentMainAddress + ::kSegmentMainLength
on_line_buffer2 .res    256     ; enough for all devices
.endstruct

        DEFINE_READWRITE_BLOCK_PARAMS block_params, default_block_buffer, 0

;;; This must allow $2000 bytes of contiguous space in the
;;; default memory bitmap.
volume_bitmap   := $4000

;;; ============================================================

.proc MLIRelayImpl
        params_src := $7E

        jsr     auxlc::CheckEvents

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
        phax

        ;; Copy the params here
        ldy     #3      ; ptr is off by 1
    DO
        copy8   (params_src),y, params-1,y
        dey
    WHILE NOT_ZERO

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
.endproc ; MLIRelayImpl

;;; ============================================================

.proc NoOp
        rts
.endproc ; NoOp

;;; ============================================================
;;; Quit back to ProDOS (which will launch DeskTop)

.proc Quit
        ;; Override in this scope
        MLIEntry := MLI

        jsr     auxlc::StopDeskTop

        sta     ALTZPOFF
        bit     ROMIN2

        sta     SET80STORE      ; 80-col firmware expects this
        lda     #0              ; INIT is not used as that briefly
        sta     WNDLFT          ; displays the dirty text page
        sta     WNDTOP
        lda     #80
        sta     WNDWDTH
        lda     #24
        sta     WNDBTM
        jsr     HOME            ; Clear 80-col screen
        sta     TXTSET          ; ... and show it

        CALL    COUT, A=#$95    ; Ctrl-U - disable 80-col firmware
        jsr     INIT            ; reset text window again
        jsr     SETVID          ; after INIT so WNDTOP is set properly
        jsr     SETKBD

        ;; We'd switch back to color mode here, but since we're
        ;; launching DeskTop there's no point.

        jsr     ReconnectRAM

        MLI_CALL QUIT, quit_params
        rts
.endproc ; Quit

;;; ============================================================

.proc FormatDevice
        ldx     auxlc::dest_drive_index
        lda     auxlc::drive_unitnum_table,x
        sta     unit_number
        jsr     auxlc::IsDiskII
        beq     disk_ii

        ;; Get driver address
        CALL    DeviceDriverAddress, A=unit_number
        stax    $06

        lda     #DRIVER_COMMAND_FORMAT
        sta     DRIVER_COMMAND
        lda     unit_number
        sta     DRIVER_UNIT_NUMBER
        jmp     ($06)

        ;; Use Disk II-specific code
disk_ii:
        unit_number := *+1
        lda     #SELF_MODIFIED_BYTE
        jmp     FormatDiskII
.endproc ; FormatDevice

;;; ============================================================
;;; Eject Disk via SmartPort

.proc EjectDiskImpl

        DEFINE_SP_CONTROL_PARAMS control_params, 0, list, $04 ; For Apple/UniDisk 3.3: Eject disk

list:   .word   0               ; 0 items in list

start:
        jsr     FindSmartportDispatchAddress
        bcs     done

        stax    dispatch
        sty     control_params::unit_number

        ;; Do SmartPort call
        dispatch := *+1
        jsr     SELF_MODIFIED
        .byte   SPCall::Control
        .addr   control_params

done:   rts

.endproc ; EjectDiskImpl
EjectDisk := EjectDiskImpl::start

;;; ============================================================
;;; Identify the disk type by reading the first block.
;;; NOTE: Not used for ProDOS disks.
;;; Inputs: `source_drive_index` must be set
;;; Outputs: sets `source_disk_format`
.proc IdentifySourceNonProDOSDiskType
        ldx     auxlc::source_drive_index
        lda     auxlc::drive_unitnum_table,x
        sta     block_params::unit_num
        lda     #$00
        sta     block_params::block_num
        sta     block_params::block_num+1
        jsr     ReadBlock
        bcs     fail

        ;; Pascal?
        jsr     auxlc::IsPascalBootBlock
    IF CC
        CALL    auxlc::GetPascalVolName, AX=#on_line_buffer2
        copy8   #$C0, auxlc::source_disk_format ; Pascal
        rts
    END_IF

        ;; DOS 3.3?
        jsr     auxlc::IsDOS33BootBlock
    IF CC
        copy8   #$80,auxlc::source_disk_format ; DOS 3.3
        rts
    END_IF

        ;; Anything else
fail:   copy8   #$81, auxlc::source_disk_format ; Other
        rts
.endproc ; IdentifySourceNonProDOSDiskType

;;; ============================================================
;;; Reads the volume bitmap (blocks 6 through ...)

.proc ReadVolumeBitmap
        ;; Number of blocks to copy, divided by 8
        block_count_div8 := $08 ; word

        lda     auxlc::source_drive_index
        asl     a
        tax
        copy16  auxlc::block_count_table,x, block_count_div8
        lsr16   block_count_div8    ; /= 8
        lsr16   block_count_div8
        lsr16   block_count_div8
        copy16  block_count_div8, auxlc::block_count_div8
        bit     auxlc::source_disk_format
        bmi     :+              ; not ProDOS
        bit     auxlc::disk_copy_flag
        bmi     :+
        jmp     QuickCopy
:

        ;; --------------------------------------------------
        ;; Disk Copy - initialize a fake volume bitmap so that
        ;; all pages are copied.
.scope
        ptr := $06

        ;; Zero out the volume bitmap
        add16   #volume_bitmap, auxlc::block_count_div8, ptr
        ldy     #0
    DO
        dec16   ptr
        tya
        sta     (ptr),y
        ecmp16  ptr, #volume_bitmap
    WHILE NE

        ;; Now mark block-pages used in memory bitmap
        page := $07          ; high byte of `volume_bitmap` from above
        count := $06         ; no longer needed

        sty     count
loop:
        CALL    MarkUsedInMemoryBitmap, A=page
        inc     page
        inc     page
        inc     count
        inc     count

        lda     auxlc::block_count_div8+1
        cmp     count
        bcs     loop
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

        ;; Each volume bitmap block holds $200*8 bits, so keep reading
        ;; blocks until we've accounted for all blocks on the volume.
    DO
        CALL    MarkUsedInMemoryBitmap, A=block_params::data_buffer+1
        jsr     ReadBlock
      IF CS
        brk                     ; rude!
      END_IF

        sub16   block_count_div8, #$200, block_count_div8
        RTS_IF NEG

        lda     block_count_div8
        RTS_IF ZERO

        add16   block_params::data_buffer, #$200, block_params::data_buffer

        inc     block_params::block_num
    WHILE NOT_ZERO              ; always
.endproc ; QuickCopy
.endproc ; ReadVolumeBitmap

;;; ============================================================
;;; Check if device is removable.
;;; Inputs: A=%DSSSnnnn (drive/slot part of unit number)
;;; Outputs: A=$80 if "removable", 0 otherwise

.proc IsDriveEjectableImpl

        DEFINE_SP_STATUS_PARAMS status_params, 1, dib_buffer, 3 ; Return Device Information Block (DIB)

        dib_buffer := $220

start:
        jsr     FindSmartportDispatchAddress
    IF CC
        stax    dispatch
        sty     status_params::unit_num

        ;; Do SmartPort call
        dispatch := *+1
        jsr     SELF_MODIFIED
        .byte   SPCall::Status
        .addr   status_params

      IF CC
        lda     dib_buffer+SPDIB::Device_Type_Code
       IF A = #SPDeviceType::Disk35
        ;; Assume all 3.5" drives are ejectable
        RETURN  A=#$80
       END_IF
      END_IF
    END_IF

        RETURN  A=#0

.endproc ; IsDriveEjectableImpl

IsDriveEjectable := IsDriveEjectableImpl::start

;;; ============================================================

;;; Input: C = write flag (0=reading, 1=writing)
.proc CopyBlocks
        ror     write_flag

    IF NEG
        copy16  auxlc::start_block_div8, auxlc::block_num_div8
        copy8   auxlc::start_block_shift, auxlc::block_num_shift
        ldx     auxlc::dest_drive_index
    ELSE
        copy16  auxlc::block_num_div8, auxlc::start_block_div8
        copy8   auxlc::block_num_shift, auxlc::start_block_shift
        ldx     auxlc::source_drive_index
    END_IF
        lda     auxlc::drive_unitnum_table,x
        sta     block_params::unit_num

        lda     #7              ; 7 - (n % 8)
        sta     auxlc::block_index_shift
        lda     #0
        sta     auxlc::block_index_div8
        sta     flag1
        sta     flag2

        beq     check           ; always

loop:
        ;; Update displayed counts
        bit     write_flag
    IF NC
        jsr     auxlc::IncAndDrawBlocksRead
    ELSE
        jsr     auxlc::IncAndDrawBlocksWritten
    END_IF
        jsr     auxlc::DrawProgressBar

check:
        ;; Check for keypress
        lda     KBD
    IF A = #(CHAR_ESCAPE | $80)
        bit     KBDSTRB
        jmp     error
    END_IF

        bit     flag1
        bmi     success
        bit     flag2
        bmi     continue

        jsr     AdvanceToNextBlockIndex
    IF CS
      IF ZERO
        cpx     #$00
        beq     success
      END_IF
        ldy     #$80
        sty     flag1
    END_IF

        stax    mem_block_addr
        jsr     AdvanceToNextBlock
        bcc     _ReadOrWriteBlock
      IF ZERO
        cpx     #$00
        beq     continue
      END_IF
        ldy     #$80
        sty     flag2
        bne     _ReadOrWriteBlock

continue:
        RETURN  A=#$80

success:
        RETURN  A=#0

error:  RETURN  A=#1

.proc _ReadOrWriteBlock
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
    IF NC
        jsr     ReadBlockToMain
        bmi     error
        jmp     loop
    END_IF

        jsr     WriteBlockFromMain
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
    IF NC
        jsr     ReadBlockToLCBank1
        bmi     error
        jmp     loop
    END_IF

        jsr     WriteBlockFromLCBank1
        bmi     error
        jmp     loop

        ;; --------------------------------------------------
        ;; read/write block to/from aux
        ;; $10-$1C = 1/$0000 - 1/$CFFF
use_auxmem:
        bit     write_flag      ; 16-28
    IF NC
        jsr     auxlc::ReadBlockToAuxmem
        bmi     error
        jmp     loop
    END_IF

        jsr     auxlc::WriteBlockFromAuxmem
        bmi     error
        jmp     loop

        ;; --------------------------------------------------
        ;; read/write block to/from aux lcbank2
        ;; $20+ = 1b/$D000 - 1b/$DFFF
use_lcbank2:
        bit     write_flag
    IF NC
        jsr     ReadBlockToLCBank2
        bmi     error
        jmp     loop
    END_IF

        jsr     WriteBlockFromLCBank2
        bmi     error
        jmp     loop
.endproc ; _ReadOrWriteBlock

flag1:  .byte   0               ; ???
flag2:  .byte   0               ; ???

write_flag:                     ; high bit set if writing
        .byte   0

mem_block_addr:
        .word   0
.endproc ; CopyBlocks

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
        jsr     _Next
        pla
        rts

free:   jsr     _Next
        bcc     repeat          ; repeat unless last block
        lda     #0
        tax
        rts

.proc _Next
        dec     auxlc::block_num_shift
        bmi     :+

not_last:
        RETURN  C=0

:       lda     #7              ; 7 - (n % 8)
        sta     auxlc::block_num_shift
        inc16   auxlc::block_num_div8
        ecmp16  auxlc::block_num_div8, auxlc::block_count_div8
        bne     not_last

        RETURN  C=1
.endproc ; _Next
.endproc ; AdvanceToNextBlock

;;; ============================================================
;;; Count active blocks in volume bitmap
;;; Output: A,X = block count

.proc CountActiveBlocksInVolumeBitmap
        ptr := $06
        count := $08

        copy16  #0, count

        add16   #volume_bitmap, auxlc::block_count_div8, ptr

        ldy     #0
    DO
        dec16   ptr
        lda     (ptr),y

        ;; Count 0 bits in byte
        eor     #$FF
        ldx     #AS_BYTE(-1)
incr:   inx
bloop:  asl
        bcs     incr
        bne     bloop
        txa

        clc
        adc     count
        sta     count
        lda     #0
        adc     count+1
        sta     count+1

        ecmp16  ptr, #volume_bitmap
    WHILE NE

        RETURN  AX=count
.endproc ; CountActiveBlocksInVolumeBitmap

;;; ============================================================
;;; Look up block in volume bitmap
;;; Input: Uses `block_num_div8` and `block_num_shift`
;;; Output: A,X = block number, Y = masked bit from bitmap

.proc LookupInVolumeBitmap
        ptr := $06

        ;; Find byte in volume bitmap
        add16   #volume_bitmap, auxlc::block_num_div8, ptr

        ;; Find bit in volume bitmap
        ldy     #0
        lda     (ptr),y
        ldx     auxlc::block_num_shift
        and     bit_shift_table,x
        tay                     ; Y = masked bit

        ;; Now compute block number
        hi := $06
        lda     auxlc::block_num_div8+1
        sta     hi
        lda     auxlc::block_num_div8
        asl     a               ; *=8
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        ldx     auxlc::block_num_shift
        ora     table,x
        RETURN  X=hi

table:  .byte   7,6,5,4,3,2,1,0
.endproc ; LookupInVolumeBitmap

;;; ============================================================

.proc AdvanceToNextBlockIndex
        jsr     ComputeMemoryPageSignature
    IF Y <> #0
        pha
        jsr     _Next
        pla
        rts
    END_IF

        jsr     _Next
        bcc     AdvanceToNextBlockIndex
        lda     #$00
        tax
        rts

;;; Advance to next
.proc _Next
        dec     auxlc::block_index_shift
    IF POS
ok:     RETURN  C=0
    END_IF

        lda     #7
        sta     auxlc::block_index_shift
        inc     auxlc::block_index_div8
        lda     auxlc::block_index_div8
        cmp     #kMemoryBitmapSize
        bcc     ok

        RETURN  C=1
.endproc ; _Next
.endproc ; AdvanceToNextBlockIndex

;;; ============================================================
;;; Compute memory page signature; low nibble is high nibble of
;;; page, high nibble is "bank" (0=main, 1=aux, 2=aux lcbank2)
;;; Input: `block_index_div8` and `block_index_shift`
;;; Output: A,X=address to store block; Y=masked bit from bitmap

.proc ComputeMemoryPageSignature
        ;; Read from bitmap
        ldx     auxlc::block_index_div8
        lda     memory_bitmap,x
        ldx     auxlc::block_index_shift
        and     bit_shift_table,x
        tay                     ; Y = masked bit

        ;; Now compute address to store in memory
        lda     auxlc::block_index_div8
    IF A < #$10

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
        RETURN  A=#0
    END_IF

    IF A < #$20                 ; 16-31
        sec
        sbc     #$10
        jmp     calc
    END_IF

        sec
        sbc     #$13
        jmp     calc

table:  .byte   $0E, $0C, $0A, $08, $06, $04, $02, $00
.endproc ; ComputeMemoryPageSignature

bit_shift_table:
        .byte   1<<0, 1<<1, 1<<2, 1<<3, 1<<4, 1<<5, 1<<6, 1<<7

;;; ============================================================

.proc FreeVolBitmapPages
        page_num := $06         ; not a pointer, for once!

        lda     #>volume_bitmap
        sta     page_num
        lda     #0
        sta     count
loop:
        CALL    _MarkFreeInMemoryBitmap, A=page_num
        inc     page_num
        inc     page_num
        inc     count
        inc     count

        lda     auxlc::block_count_div8+1
        count := *+1
        cmp     #SELF_MODIFIED_BYTE
        bcs     loop
        rts

.proc _MarkFreeInMemoryBitmap
        jsr     GetBitmapOffsetMask
        ora     memory_bitmap,y
        sta     memory_bitmap,y
        rts
.endproc ; _MarkFreeInMemoryBitmap
.endproc ; FreeVolBitmapPages

;;; ============================================================

.proc MarkUsedInMemoryBitmap
        jsr     GetBitmapOffsetMask
        eor     #$FF
        and     memory_bitmap,y
        sta     memory_bitmap,y
        rts
.endproc ; MarkUsedInMemoryBitmap

;;; ============================================================
;;; Sets Y to offset in `memory_bitmap`
;;; Sets A to mask bit
;;; e.g. $76 ==> Y = $07
;;;              A = %00010000

.proc GetBitmapOffsetMask
        pha
        lsr     a               ; /=16
        lsr     a
        lsr     a
        lsr     a
        tay

        pla
        and     #$0F
        lsr     a               ; /=2 (1 bit for 2 pages)
        tax
        lda     table,x

        rts

table:
        .byte   1<<7, 1<<6, 1<<5, 1<<4, 1<<3, 1<<2, 1<<1, 1<<0
.endproc ; GetBitmapOffsetMask

;;; ============================================================

;;; Inputs: A,X = target block
;;; Output: $06/$08 set to A,X, A,X+1; `block_params::data_buffer` init
.proc PrepBlockPtrs
        ptr1 := $06
        ptr2 := $08             ; one page up

        sta     ptr1
        sta     ptr2
        stx     ptr1+1
        stx     ptr2+1
        inc     ptr2+1

        copy16  #default_block_buffer, block_params::data_buffer
        rts
.endproc ; PrepBlockPtrs

;;; ============================================================
;;; Read block (w/ retries) to main memory
;;; Inputs: A,X=mem address to store it
;;; Outputs: A=0 on success, nonzero otherwise

.proc ReadBlockToMain
        stax    block_params::data_buffer
        FALL_THROUGH_TO ReadBlockWithRetry
.endproc ; ReadBlockToMain

;;; Returns with 0 on success or N=1 on failure
.proc ReadBlockWithRetry
retry:  jsr     ReadBlock
        bcc     done
        CALL    auxlc::ShowBlockError, X=#0 ; reading
        bmi     done
        bne     retry
done:   rts
.endproc ; ReadBlockWithRetry

;;; ============================================================
;;; Read block (w/ retries) to aux LCBANK1 memory
;;; Inputs: A,X=mem address to store it
;;; Outputs: A=0 on success, nonzero otherwise

.proc ReadBlockToLCBank1
        jsr     PrepBlockPtrs
        jsr     ReadBlockWithRetry
    IF ZERO
        jsr     CopyFromBlockBuffer
        lda     #0              ; success
    END_IF
        rts
.endproc ; ReadBlockToLCBank1

;;; ============================================================
;;; Read block (w/ retries) to aux LCBANK2 memory
;;; Inputs: A,X=mem address to store it
;;; Outputs: A=0 on success, nonzero otherwise

.proc ReadBlockToLCBank2
        jsr     PrepBlockPtrs
        jsr     ReadBlockWithRetry
    IF ZERO
        bit     LCBANK2
        bit     LCBANK2

        jsr     CopyFromBlockBuffer

        bit     LCBANK1
        bit     LCBANK1

        lda     #0              ; success
    END_IF
        rts
.endproc ; ReadBlockToLCBank2

;;; ============================================================
;;; Copies block from `default_block_buffer`
;;; Inputs: $06/$08 point at target pages

.proc CopyFromBlockBuffer
        ptr1 := $06
        ptr2 := $08             ; one page up

        ldy     #$FF
        iny
    DO
        lda     default_block_buffer,y
        sta     (ptr1),y
        lda     default_block_buffer+$100,y
        sta     (ptr2),y
        iny
    WHILE NOT_ZERO
        rts
.endproc ; CopyFromBlockBuffer

;;; ============================================================
;;; Write block (w/ retries) from main memory
;;; Inputs: A,X=address to read from
;;; Outputs: A=0 on success, nonzero otherwise

.proc WriteBlockFromMain
        stax    block_params::data_buffer
        FALL_THROUGH_TO WriteBlockWithRetry
.endproc ; WriteBlockFromMain

;;; Input: `block_params::data_buffer` populated
.proc WriteBlockWithRetry
retry:  jsr     WriteBlock
        bcc     done
        CALL    auxlc::ShowBlockError, X=#$80 ; writing
        beq     done
        bpl     retry
done:   rts
.endproc ; WriteBlockWithRetry

;;; ============================================================
;;; Write block (w/ retries) from aux LCBANK1 memory
;;; Inputs: A,X=address to read from
;;; Outputs: A=0 on success, nonzero otherwise

.proc WriteBlockFromLCBank1
        jsr     PrepBlockPtrs
        jsr     CopyToBlockBuffer

        jmp     WriteBlockWithRetry
.endproc ; WriteBlockFromLCBank1

;;; ============================================================
;;; Write block (w/ retries) from aux LCBANK2 memory
;;; Inputs: A,X=address to read from
;;; Outputs: A=0 on success, nonzero otherwise

.proc WriteBlockFromLCBank2
        jsr     PrepBlockPtrs

        bit     LCBANK2
        bit     LCBANK2

        jsr     CopyToBlockBuffer

        bit     LCBANK1
        bit     LCBANK1

        jmp     WriteBlockWithRetry
.endproc ; WriteBlockFromLCBank2

;;; ============================================================
;;; Copies block to `default_block_buffer`
;;; Inputs: $06/$08 point at source pages

.proc CopyToBlockBuffer
        ptr1 := $06
        ptr2 := $08             ; one page up

        ldy     #$FF
        iny
    DO
        lda     (ptr1),y
        sta     default_block_buffer,y
        lda     (ptr2),y
        sta     default_block_buffer+$100,y
        iny
    WHILE NOT_ZERO
        rts
.endproc ; CopyToBlockBuffer

;;; ============================================================

.proc CallOnLine2
        MLI_CALL ON_LINE, on_line_params2
        rts
.endproc ; CallOnLine2

.proc CallOnLine
        MLI_CALL ON_LINE, on_line_params
        rts
.endproc ; CallOnLine

.proc WriteBlock
        MLI_CALL WRITE_BLOCK, block_params
        rts
.endproc ; WriteBlock

.proc ReadBlock
        MLI_CALL READ_BLOCK, block_params
        rts
.endproc ; ReadBlock

;;; ============================================================

;;; Memory Availability Bitmap
;;;
;;; Each bit represents a double-page, enough for one 512-byte
;;; disk block. 1 = available, 0 = reserved.
;;;
;;; Note that the `memory_bitmap` has _lowest_ address represented
;;; by the _highest_ bit in the corresponding byte. So page 0 is
;;; represented as available by %1xxxxxxx, page 1 by %x1xxxxxx, etc.

memory_bitmap:
        ;; Main memory
        .byte   %00000000       ; $00-$0F - ZP/Stack/Text, then Disk Copy code...
        .byte   %00111100       ; $10-$1F - but $14-1B free ($1C = I/O buffer)
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
        .byte   %00000001       ; $80-$8F - MGTK, font (but $8E-$8F free)
        .byte   %11111111       ; $90-$9F - free
        .byte   %11111111       ; $A0-$AF - free
        .byte   %11111111       ; $B0-$BF - free
        .byte   %00000000       ; $C0-$CF - I/O
        .byte   %00000000       ; $D0-$DF - Disk Copy code
        .byte   %00000000       ; $E0-$EF - Disk Copy code
        .byte   %01111111       ; $F0-$FF - free $F2 and up

        ;; Aux memory - LCBANK2
        .byte   %11111111       ; $D0-$DF - free
kMemoryBitmapSize = * - memory_bitmap

        .assert DEFAULT_FONT + 1283 < $8E00, error, "Update memory_bitmap if MGTK+font extends past $8E00"
        .assert end_of_main <= $1400, error, "Update memory_bitmap if code extends past $1400"

;;; ============================================================
;;; Inputs: A = unit num (DSSS0000), X,Y = driver address
;;; Outputs: X,Y = blocks

.proc GetDeviceBlocksUsingDriver
        sta     ALTZPOFF

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
.endproc ; GetDeviceBlocksUsingDriver

;;; ============================================================
;;; On IIgs, force preferred RGB mode. No-op otherwise.
;;; Assert: LCBANK1 is banked in

.proc ResetIIgsRGB
        CALL    ReadSetting, X=#DeskTopSettings::system_capabilities
        and     #DeskTopSettings::kSysCapIsIIgs
        beq     done

        CALL    ReadSetting, X=#DeskTopSettings::rgb_color
        bmi     color

        ldy     #$80            ; MONOCOLOR - Mono
        lda     NEWVIDEO
        ora     #(1<<5)         ; B&W
        bne     store           ; always

color:  ldy     #$00            ; MONOCOLOR - Color
        lda     NEWVIDEO
        and     #<~(1<<5)       ; Color

store:  sta     NEWVIDEO
        sty     MONOCOLOR

done:   rts
.endproc ; ResetIIgsRGB

;;; ============================================================

        .include "../lib/smartport.s"
        .include "../lib/reconnect_ram.s"
        .include "../lib/readwrite_settings.s"
        .include "../lib/speed.s"
        .include "../lib/bell.s"

;;; ============================================================

        end_of_main := *
.endscope ; main

ReadSetting := main::ReadSetting

        ENDSEG SegmentMain
