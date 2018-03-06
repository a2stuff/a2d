        .setcpu "6502"

        .org $2000

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../macros.inc"

;;; ============================================================
.proc bootstrap

        jmp     start

;;; ============================================================
;;; Data buffers and param blocks

date:   .word   0               ; written into file

L2005:
        .res    832, 0

        .byte   $02,$00
        .addr   L2363

.proc get_prefix_params2
param_count:    .byte   2       ; GET_PREFIX, but param_count is 2 ??? Bug???
data_buffer:    .addr   $0D00
.endproc

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params4, $0D00
        .byte   $00,$01
        .addr   L2362
L2362:  .byte   $00
L2363:  .res    15, 0

butn1:  .byte   0               ; written, but not read

unit_num:
        .byte   0

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer

copy_flag:
        .byte   0
L2379:  .byte   0

on_line_buffer: .res 17, 0

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, buffer
        DEFINE_SET_PREFIX_PARAMS set_prefix_params, path0

        .byte   $0A
        .addr   L2379
        .byte   $00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00

        .byte   $07,$60,$2B,$C3,$0F
        .byte   $00,$00,$0D,$00,$00,$00,$00,$04
        .byte   $00,$00,$03,$00,$01,$00,$00,$01
        .byte   $00,$03,$F5,$26,$00,$08,$00,$04
        .byte   $00
        .addr   L23C9
        .byte   $04,$00,$00,$00
L23C9:  .byte   $00
        .byte   $00,$00,$00,$01,$00,$04,$00,$21
        .byte   $28,$27,$00,$00,$00,$04,$00
        .addr   L23DF
        .byte   $05,$00,$00,$00
L23DF:  .byte   $00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00

        DEFINE_CLOSE_PARAMS close_srcfile_params
        DEFINE_CLOSE_PARAMS close_dstfile_params

        .byte   $01
        .addr   buffer

        copy_buffer := $4000
        max_copy_count := MLI - copy_buffer

        DEFINE_OPEN_PARAMS open_srcfile_params, buffer, $0D00
        DEFINE_OPEN_PARAMS open_dstfile_params, path0, $1100
        DEFINE_READ_PARAMS read_srcfile_params, copy_buffer, max_copy_count
        DEFINE_WRITE_PARAMS write_dstfile_params, copy_buffer, max_copy_count

        DEFINE_CREATE_PARAMS create_params, path0, %11000011, 0, 0
        .byte   $07
        .addr   path0
        .byte   $00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, buffer
        .byte   0


        ;; Files/Directories to copy
str_f1: PASCAL_STRING "DESKTOP1"
str_f2: PASCAL_STRING "DESKTOP2"
str_f3: PASCAL_STRING "DESK.ACC"
str_f4: PASCAL_STRING "SELECTOR.LIST"
str_f5: PASCAL_STRING "SELECTOR"
str_f6: PASCAL_STRING "PRODOS"

filename_table:
        .addr str_f1,str_f2,str_f3,str_f4,str_f5,str_f6

str_copying_to_ramcard:
        PASCAL_STRING "Copying Apple II DeskTop into RAMCard"

        ;; Jump target from filer launcher - why???
rts1:   rts

        ;; Signature of block storage devices ($Cn0x)
sig_bytes:
        .byte   $20,$00,$03,$00
sig_offsets:
        .byte   $01,$03,$05,$07

active_device:
        .byte   0

        ;; Selector signature
selector_signature:
        .byte   $AD,$8B,$C0,$18,$FB,$5C,$04,$D0,$E0

;;; ============================================================

start:  sta     MIXCLR
        sta     HIRES
        sta     TXTCLR
        sta     CLR80VID
        sta     AN3_OFF
        sta     AN3_ON
        sta     AN3_OFF
        sta     AN3_ON
        sta     SET80VID
        sta     DHIRESON
        sta     TXTSET

        lda     DATELO          ; Any date set?
        ora     DATEHI
        bne     L24EB
        copy16  date, DATELO    ; Copy timestamp embedded in this file
L24EB:  lda     MACHID
        and     #$30            ; bits 4,5 set = 128k
        cmp     #$30
        beq     have128k

        ;; Relocate FILER launch routine to $300 and invoke
.scope
        target := $300
        length := $D0

        ldy     #length
:       lda     launch_filer,y
        sta     target,y
        dey
        cpy     #$FF            ; why not bpl ???
        bne     :-
        jmp     target
.endscope

have128k:
        lda     #$00
        sta     SHADOW          ; IIgs ???

        lda     DEVNUM          ; Most recent device
        sta     active_device
        lda     LCBANK2
        lda     LCBANK2

        ;; Check quit routine
        ldx     #$08
:       lda     SELECTOR,x         ; Quit routine?
        cmp     selector_signature,x
        bne     nomatch
        dex
        bpl     :-
        lda     #0
        beq     match

nomatch:
        lda     #$80

match:  sta     $D3AC

        lda     ROMIN2
        ldx     #$00
        jsr     L26A5

        ;; Point $8 at $C100
        lda     #0
        sta     L2BE2
        sta     $08
        lda     #$C1
        sta     $08+1

        ;; Check slot for signature bytes
check_slot:
        ldx     #0
:       lda     sig_offsets,x   ; Check $CnXX
        tay
        lda     ($08),y
        cmp     sig_bytes,x
        bne     next_slot
        inx
        cpx     #4              ; number of signature bytes
        bcc     :-

        ldy     #$FB
        lda     ($08),y         ; Also check $CnFB for low bit
        and     #$01
        beq     next_slot
        bne     found_slot

next_slot:
        inc     $08+1
        lda     $08+1
        cmp     #$C8            ; stop at $C800
        bcc     check_slot


        ldy     DEVCNT
L2565:  lda     DEVLST,y
        cmp     #$3E
        beq     L2572
        dey
        bpl     L2565
        jmp     fail

L2572:  lda     #$03
        bne     L257A
found_slot:
        lda     $08+1
        and     #$0F            ; slot # in A
L257A:  sta     slot

        ;; Synthesize unit_num, verify it's a device
        asl     a
        asl     a
        asl     a
        asl     a
        sta     on_line_params::unit_num
        sta     unit_num
        MLI_CALL ON_LINE, on_line_params
        beq     :+
        jmp     fail

:       lda     unit_num
        cmp     #$30            ; make sure it's not slot 3 (aux)
        beq     :+
        sta     write_block_params_unit_num
        sta     write_block_params2_unit_num
        MLI_CALL WRITE_BLOCK, write_block_params
        bne     :+
        MLI_CALL WRITE_BLOCK, write_block_params2
:       lda     on_line_buffer
        and     #$0F
        tay
        iny
        sty     path0
        lda     #'/'
        sta     on_line_buffer
        sta     path0+1
L25BF:  lda     on_line_buffer,y
        sta     path0+1,y
        dey
        bne     L25BF
        ldx     #$C0
        jsr     L26A5
        addr_call L26B2, path0
        jsr     check_desktop2_on_device
        bcs     L25E4
        ldx     #$80
        jsr     L26A5
        jsr     L2B57
        jmp     fail

L25E4:  lda     BUTN1
        sta     butn1
        lda     BUTN0
        bpl     start_copy
        jmp     fail

str_slash_desktop:
        PASCAL_STRING "/DeskTop"

        ;; Overwrite first bytes of get_file_info_params
.proc file_info_ovl
        .byte   $A              ; param_count
        .addr   0               ; pathname
        .byte   %11000011       ; access
        .byte   FT_DIRECTORY    ; filetype
        .word   0               ; aux_type
        .byte   ST_LINKED_DIRECTORY ; storage_type
.endproc

start_copy:
        jsr     show_copying_screen
        MLI_CALL GET_PREFIX, get_prefix_params
        beq     L2611
        jmp     fail_copy

L2611:  dec     buffer
        ldx     #$80
        jsr     L26A5
        ldy     buffer
L261C:  lda     buffer,y
        sta     L2005,y
        dey
        bpl     L261C
        ldy     path0
        ldx     #$00
L262A:  iny
        inx
        lda     str_slash_desktop,x
        sta     path0,y
        cpx     str_slash_desktop
        bne     L262A
        sty     path0
        ldx     #7
L263C:  lda     file_info_ovl,x
        sta     get_file_info_params,x
        dex
        cpx     #3
        bne     L263C
        jsr     create_file_for_copy
        lda     path0
        sta     copy_flag
        lda     #0
        sta     filenum

file_loop:
        lda     filenum
        asl     a
        tax
        lda     filename_table,x
        sta     $06
        lda     filename_table+1,x
        sta     $06+1
        ldy     #0
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     filename_buf,y
        dey
        bpl     :-
        jsr     copy_file
        inc     filenum
        lda     filenum
        cmp     #$06
        bne     file_loop
        jmp     fail2

fail2:  lda     copy_flag
        beq     L268F
        sta     path0
        MLI_CALL SET_PREFIX, set_prefix_params
L268F:  jsr     write_desktop1
        jsr     L2B57
        lda     #$00
        sta     $C071           ; ???
        ldy     #BITMAP_SIZE-1
:       sta     BITMAP,y
        dey
        bpl     :-
        jmp     part2

L26A5:  lda     LCBANK2
        lda     LCBANK2
        stx     $D3FF
        lda     ROMIN2
        rts

L26B2:  stax    $06
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     $D3EE,y
        dey
        bpl     :-
        lda     ROMIN2
        rts

L26CD:  stax    $06
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     $D3AD,y
        dey
        bpl     :-
        lda     ROMIN2
        rts

fail:   lda     #$00
        sta     L2BE2
        jmp     fail2

        .byte   0, $D, 0, 0, 0

        ;; Generic buffer?
buffer: .res 300, 0

filename_buf:
        .res 16, 0

file_type:                      ; written but not read ???
        .byte   0

L2832:  .res 31, 0              ; unused ???

;;; ============================================================

.proc append_filename_to_buffer
        lda     filename_buf
        bne     :+
        rts

:       ldx     #0
        ldy     buffer
        lda     #'/'
        sta     buffer+1,y
        iny
loop:   cpx     filename_buf
        bcs     done
        lda     filename_buf+1,x
        sta     buffer+1,y
        inx
        iny
        jmp     loop

done:   sty     buffer
        rts
.endproc

;;; ============================================================

.proc remove_filename_from_buffer
        ldx     buffer
        bne     :+
        rts

:       lda     buffer,x
        cmp     #'/'
        beq     done
        dex
        bne     :-
        stx     buffer
        rts

done:   dex
        stx     buffer
        rts
.endproc

;;; ============================================================

.proc append_filename_to_path0
        lda     filename_buf
        bne     :+
        rts

:       ldx     #0
        ldy     path0
        lda     #'/'
        sta     path0+1,y
        iny
loop:   cpx     filename_buf
        bcs     done
        lda     filename_buf+1,x
        sta     path0+1,y
        inx
        iny
        jmp     loop

done:   sty     path0
        rts
.endproc

;;; ============================================================

.proc remove_filename_from_path0
        ldx     path0
        bne     :+
        rts

:       lda     path0,x
        cmp     #'/'
        beq     done
        dex
        bne     :-
        stx     path0
        rts

done:   dex
        stx     path0
        rts
.endproc

;;; ============================================================

.proc show_copying_screen
        ;; Turn on 80-column mode
        jsr     SLOT3ENTRY
        jsr     HOME

        ;; Center string
        lda     #80
        sec
        sbc     str_copying_to_ramcard
        lsr     a               ; / 2 to center
        sta     CH
        lda     #12
        sta     CV
        jsr     VTAB
        ldy     #0
loop:   iny
        lda     str_copying_to_ramcard,y
        ora     #$80
        jsr     COUT
        cpy     str_copying_to_ramcard
        bne     loop
        rts
.endproc

;;; ============================================================

.proc fail_copy
        lda     #0
        sta     copy_flag
        jmp     fail
.endproc

;;; ============================================================
;;; Unreferenced ???

.proc copy_input_to_buffer
        ldy     #$00
loop:   lda     $0200,y
        cmp     #$80|CHAR_RETURN
        beq     done
        and     #$7F
        sta     buffer+1,y
        iny
        jmp     loop

done:   sty     buffer
        rts
.endproc

;;; ============================================================

.proc copy_file
        jsr     append_filename_to_path0
        jsr     append_filename_to_buffer
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        cmp     #ERR_FILE_NOT_FOUND
        beq     cleanup
        jmp     fail

:       lda     get_file_info_params::file_type
        sta     file_type
        cmp     #FT_DIRECTORY
        bne     :+
        jsr     copy_directory
        jmp     done

:       jsr     create_file_for_copy
        cmp     #ERR_DUPLICATE_FILENAME
        bne     :+
        lda     filenum
        bne     cleanup
        pla
        pla
        jmp     fail2

:       jsr     copy_normal_file

cleanup:
        jsr     remove_filename_from_buffer
        jsr     remove_filename_from_path0
done:   rts
.endproc

;;; ============================================================

.proc copy_directory_impl
        ptr := $6

        dir_buffer := $A400

        entry_length_offset := $23
        file_count_offset := $25
        header_length := $2B

        DEFINE_OPEN_PARAMS open_params, buffer, $A000
        DEFINE_READ_PARAMS read_params, dir_buffer, $0200
        DEFINE_CLOSE_PARAMS close_params

start:  jsr     create_file_for_copy
        cmp     #ERR_DUPLICATE_FILENAME
        beq     bail
        MLI_CALL OPEN, open_params
        beq     :+
        jsr     fail_copy
bail:   rts

:       lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        beq     :+
        jsr     fail_copy
        rts

:       lda     #0
        sta     L2A10
        lda     #<(dir_buffer + header_length)
        sta     ptr
        lda     #>(dir_buffer + header_length)
        sta     ptr+1
L2997:  lda     dir_buffer + file_count_offset
        cmp     L2A10
        bne     L29B1
L299F:  MLI_CALL CLOSE, close_params
        beq     :+
        jmp     fail_copy

:       jsr     remove_filename_from_buffer
        jsr     remove_filename_from_path0
        rts

L29B1:  ldy     #0
        lda     (ptr),y
        bne     L29BA
        jmp     L29F6

L29BA:  and     #$0F
        tay
L29BD:  lda     (ptr),y
        sta     filename_buf,y
        dey
        bne     L29BD
        lda     (ptr),y
        and     #$0F
        sta     filename_buf,y
        jsr     append_filename_to_path0
        jsr     append_filename_to_buffer
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        jmp     fail_copy

:       lda     get_file_info_params::file_type
        sta     file_type
        jsr     create_file_for_copy
        cmp     #ERR_DUPLICATE_FILENAME
        beq     :+
        jsr     copy_normal_file
:       jsr     remove_filename_from_buffer
        jsr     remove_filename_from_path0
        inc     L2A10
L29F6:  add16_8 ptr, dir_buffer + entry_length_offset, ptr
        lda     ptr+1
        cmp     #>(dir_buffer + $200)
        bcs     L2A0D
        jmp     L2997

L2A0D:  jmp     L299F

L2A10:  .byte   0
.endproc
        copy_directory := copy_directory_impl::start

;;; ============================================================

.proc copy_normal_file
        ;; Open source
:       MLI_CALL OPEN, open_srcfile_params
        beq     :+
        jsr     fail_copy
        jmp     :-

        ;; Open destination
:       MLI_CALL OPEN, open_dstfile_params
        beq     :+
        jsr     fail_copy
        jmp     :-

:       lda     open_srcfile_params::ref_num
        sta     read_srcfile_params::ref_num
        sta     close_srcfile_params::ref_num
        lda     open_dstfile_params::ref_num
        sta     write_dstfile_params::ref_num
        sta     close_dstfile_params::ref_num

        ;; Read a chunk
loop:   copy16  #max_copy_count, read_srcfile_params::request_count
read:   MLI_CALL READ, read_srcfile_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     done
        jsr     fail_copy
        jmp     read

        ;; Write the chunk
:       copy16  read_srcfile_params::trans_count, write_dstfile_params::request_count
        ora     read_srcfile_params::trans_count
        beq     done
write:  MLI_CALL WRITE, write_dstfile_params
        beq     :+
        jsr     fail_copy
        jmp     write

        ;; More to copy?
:       lda     write_dstfile_params::trans_count
        cmp     #<max_copy_count
        bne     done
        lda     write_dstfile_params::trans_count+1
        cmp     #>max_copy_count
        beq     loop

        ;; Close source and destination
done:   MLI_CALL CLOSE, close_srcfile_params
        MLI_CALL CLOSE, close_dstfile_params
        rts
.endproc

;;; ============================================================

.proc create_file_for_copy
        ;; Copy file_type, aux_type, storage_type
        ldx     #7
:       lda     get_file_info_params,x
        sta     create_params,x
        dex
        cpx     #3
        bne     :-
        MLI_CALL CREATE, create_params
        beq     :+
        cmp     #ERR_DUPLICATE_FILENAME
        beq     :+
        jsr     fail_copy
:       rts
.endproc

;;; ============================================================

.proc check_desktop2_on_device
        lda     active_device
        cmp     #$3E            ; ???
        bne     :+
        jmp     next

        ;; Check slot for signature bytes
:       and     #$70            ; Compute $Cn00
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$C0
        sta     $08+1
        lda     #0
        sta     $08
        ldx     #0              ; Compare signature bytes
bloop:  lda     sig_offsets,x
        tay
        lda     ($08),y
        cmp     sig_bytes,x
        bne     error
        inx
        cpx     #4              ; Number of signature bytes
        bcc     bloop
        ldy     #$FB            ; Also check $CnFB
        lda     ($08),y
        and     #$01
        bne     next
error:  sec
        rts

next:   MLI_CALL GET_PREFIX, get_prefix_params2
        bne     error

        ;; Append "DeskTop2" to path at $D00
        ldx     $0D00
        ldy     #0
loop:   inx
        iny
        lda     str_desktop2,y
        sta     $0D00,x
        cpy     str_desktop2
        bne     loop
        stx     $0D00

        ;; ... and get info
        MLI_CALL GET_FILE_INFO, get_file_info_params4
        beq     error
        clc                     ; ok
        rts

str_desktop2:
        PASCAL_STRING "DeskTop2"
.endproc

;;; ============================================================

.proc write_desktop1_impl
        DEFINE_OPEN_PARAMS open_params, str_desktop1_path, $1000
str_desktop1_path:
        PASCAL_STRING "DeskTop/DESKTOP1"
        DEFINE_WRITE_PARAMS write_params, $2000, $45
        DEFINE_CLOSE_PARAMS close_params

start:  MLI_CALL OPEN, open_params
        bne     :+
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_CALL WRITE, write_params
        bne     :+
        MLI_CALL CLOSE, close_params
:       rts
.endproc
        write_desktop1 := write_desktop1_impl::start

;;; ============================================================

L2B57:  addr_call L26CD, L2005
        rts

        .byte   0

path0:  .res    65, 0

;;; ============================================================
;;; Launch FILER - used if machine is not 128k
;;; Relocated to $300 before invoking

        saved_org := *
.proc launch_filer
        .org $300

        sys_start := $2000

        MLI_CALL OPEN, open_params
        beq     :+
        jmp     rts1

:       lda     open_params_ref_num
        sta     read_params_ref_num
        MLI_CALL READ, read_params
        beq     :+
        jmp     rts1

:       MLI_CALL CLOSE, close_params
        beq     :+
        jmp     rts1

:       jmp     sys_start

        DEFINE_OPEN_PARAMS open_params, filename, $800
        open_params_ref_num := open_params::ref_num

        DEFINE_READ_PARAMS read_params, sys_start, MLI - sys_start
        read_params_ref_num := read_params::ref_num

        DEFINE_CLOSE_PARAMS close_params

filename:
        PASCAL_STRING "FILER"
.endproc
        .assert .sizeof(launch_filer) <= $D0, error, "Routine length exceeded"

;;; ============================================================

        .org (saved_org + .sizeof(launch_filer))

filenum:
        .byte   0               ; index of file being copied
L2BE2:  .byte   $00
slot:   .byte   0

        DEFINE_WRITE_BLOCK_PARAMS write_block_params, prodos_loader_blocks, 0
        write_block_params_unit_num := write_block_params::unit_num
        DEFINE_WRITE_BLOCK_PARAMS write_block_params2, prodos_loader_blocks + 512, 1
        write_block_params2_unit_num := write_block_params2::unit_num

        PAD_TO $2C00

;;; ============================================================

prodos_loader_blocks:
        .assert * = $2C00, error, "Segment length mismatch"
        .incbin "inc/pdload.dat"

.endproc ;  bootstrap

;;; ============================================================

        .assert * = $3000, error, "Segment length mismatch"

.proc part2
        jsr     SLOT3ENTRY
        jsr     HOME
        lda     LCBANK2
        lda     LCBANK2
        lda     $D3FF
        pha
        lda     ROMIN2
        pla
        bne     L3019
        jmp     invoke_selector_or_desktop

L3019:  lda     LCBANK2
        lda     LCBANK2
        ldx     #$17
        lda     #$00
L3023:  sta     $D395,x
        dex
        bpl     L3023
        lda     ROMIN2
        jsr     read_selector_list
        beq     :+
        jmp     L30B8

:       lda     #0
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
        lda     LCBANK2
        lda     LCBANK2
        ldx     L30BB
        lda     #$FF
        sta     $D395,x
        lda     ROMIN2
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
        lda     LCBANK2
        lda     LCBANK2
        lda     L30BB
        clc
        adc     #$08
        tax
        lda     #$FF
        sta     $D395,x
        lda     ROMIN2
L30B2:  inc     L30BB
        jmp     L3076

L30B8:  jmp     invoke_selector_or_desktop

L30BB:  .byte   $00
        DEFINE_OPEN_PARAMS open_params6, path2, $0800
        DEFINE_READ_PARAMS read_params4, L30CA, 4
L30CA:  .res    4, 0
        DEFINE_CLOSE_PARAMS close_params5
        DEFINE_READ_PARAMS read_params5, L3150, $27
        DEFINE_READ_PARAMS read_params6, L30E0, 5
L30E0:  .res    5, 0
        .byte   $00,$00,$00,$00
        DEFINE_CLOSE_PARAMS close_params7
        DEFINE_CLOSE_PARAMS close_params6
        .byte   $01
        .addr   path2
        DEFINE_OPEN_PARAMS open_params7, path2, $0D00
        DEFINE_OPEN_PARAMS open_params8, path1, $1C00
        DEFINE_READ_PARAMS read_params7, $1100, $0B00
        DEFINE_WRITE_PARAMS write_params3, $1100, $0B00

        DEFINE_CREATE_PARAMS create_params3, path1, %11000011

        DEFINE_CREATE_PARAMS create_params2, path1, 0

L3124:  .byte   $00,$00

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params2, path2
        .byte   $00

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params3, path1
        .byte   $00,$02,$00,$00,$00

L3150:  .byte   $00
L3151:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00
L3160:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $40,$35,$3D,$35,$86,$31,$60,$00

path1:  .res    65, 0
path2:  .res    65, 0

L320A:  .res    64, 0
L324A:  .res    64, 0
L328A:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L329A:  .byte   $00
L329B:  .byte   $0D
L329C:  .byte   $00
L329D:  .byte   $00
L329E:  .byte   $00
L329F:  .res    170, 0
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
        MLI_CALL OPEN, open_params6
        beq     L337A
        jmp     handle_error_code

L337A:  lda     open_params6::ref_num
        sta     L329D
        sta     read_params4::ref_num
        MLI_CALL READ, read_params4
        beq     :+
        jmp     handle_error_code

:       jsr     L33A4
        rts

L3392:  lda     L329D
        sta     close_params5::ref_num
        MLI_CALL CLOSE, close_params5
        beq     L33A3
        jmp     handle_error_code

L33A3:  rts

L33A4:  inc     L329C
        lda     L329D
        sta     read_params5::ref_num
        MLI_CALL READ, read_params5
        beq     L33B8
        jmp     handle_error_code

L33B8:  inc     L334A
        lda     L334A
        cmp     L329B
        bcc     L33E0
        lda     #$00
        sta     L334A
        lda     L329D
        sta     read_params6::ref_num
        MLI_CALL READ, read_params6
        beq     :+
        jmp     handle_error_code

:       lda     read_params6::trans_count
        cmp     read_params6::request_count
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
        sta     path2+1,y
        iny
        jmp     L3472

L3482:  sty     path2
        rts

        .byte   0
        .byte   0
        .byte   0
L3489:  lda     #$FF
        sta     L353B
        jsr     L3777
        ldx     path1
        lda     #'/'
        sta     path1+1,x
        inc     path1
        ldy     #$00
        ldx     path1
L34A1:  iny
        inx
        lda     L328A,y
        sta     path1,x
        cpy     L328A
        bne     L34A1
        stx     path1
        MLI_CALL GET_FILE_INFO, get_file_info_params3
        cmp     #ERR_FILE_NOT_FOUND
        beq     L34C4
        cmp     #ERR_VOL_NOT_FOUND
        beq     L34C4
        cmp     #ERR_PATH_NOT_FOUND
        beq     L34C4
        rts

L34C4:  MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     L34DD
        cmp     #ERR_VOL_NOT_FOUND
        beq     L34D4
        cmp     #ERR_FILE_NOT_FOUND
        bne     L34DA
L34D4:  jsr     show_insert_prompt
        jmp     L34C4

L34DA:  jmp     handle_error_code

L34DD:  lda     get_file_info_params2::storage_type
        cmp     #$0F
        beq     L34EC
        cmp     #$0D
        beq     L34EC
        lda     #$00
        beq     L34EE
L34EC:  lda     #$FF
L34EE:  sta     L353A

        ;; copy file_type, aux_type, storage_type
        ldy     #7
:       lda     get_file_info_params2,y
        sta     create_params2,y
        dey
        cpy     #3
        bne     :-
        lda     #$C3
        sta     create_params2::access
        jsr     L35A9
        bcc     L350B
        jmp     show_no_space_prompt

L350B:  ldx     #$03
L350D:  lda     get_file_info_params2::create_date,x
        sta     create_params2::create_date,x
        dex
        bpl     L350D
        lda     create_params2::storage_type
        cmp     #$0F
        bne     L3522
        lda     #$0D
        sta     create_params2::storage_type
L3522:  MLI_CALL CREATE, create_params2
        beq     :+
        jmp     handle_error_code

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
        jsr     show_copying_screen
        MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     L3566
        jmp     handle_error_code
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
        jsr     show_copying_screen
        MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     :+
        jmp     handle_error_code

:       jsr     L35A9
        bcc     L3590
        jmp     show_no_space_prompt

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

L35A9:  MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     :+
        jmp     handle_error_code

:       lda     #$00
        sta     L3641
        sta     L3642
        MLI_CALL GET_FILE_INFO, get_file_info_params3
        beq     :+
        cmp     #ERR_FILE_NOT_FOUND
        beq     L35D7
        jmp     handle_error_code

:       copy16  get_file_info_params3::blocks_used, L3641
L35D7:  lda     path1
        sta     L363F
        ldy     #$01
L35DF:  iny
        cpy     path1
        bcs     L3635
        lda     path1,y
        cmp     #'/'
        bne     L35DF
        tya
        sta     path1
        sta     L3640
        MLI_CALL GET_FILE_INFO, get_file_info_params3
        beq     :+
        jmp     handle_error_code

:       sub16   get_file_info_params3::aux_type, get_file_info_params3::blocks_used, L363D
        sub16   L363D, L3641, L363D
        cmp16   L363D, get_file_info_params2::blocks_used
        bcs     L3635
        sec
        bcs     L3636
L3635:  clc
L3636:  lda     L363F
        sta     path1
        rts

L363D:  .byte   0,0
L363F:  .byte   0
L3640:  .byte   0
L3641:  .byte   0
L3642:  .byte   0
L3643:  MLI_CALL OPEN, open_params7
        beq     L364E
        jsr     handle_error_code
L364E:  MLI_CALL OPEN, open_params8
        beq     L3659
        jmp     handle_error_code

L3659:  lda     open_params7::ref_num
        sta     read_params7::ref_num
        sta     close_params7::ref_num
        lda     open_params8::ref_num
        sta     write_params3::ref_num
        sta     close_params6::ref_num

L366B:  copy16  #$0B00, read_params7::request_count
        MLI_CALL READ, read_params7
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     L36AE
        jmp     handle_error_code

:       copy16  read_params7::trans_count, write_params3::request_count
        ora     read_params7::trans_count
        beq     L36AE
        MLI_CALL WRITE, write_params3
        beq     :+
        jmp     handle_error_code

:       lda     write_params3::trans_count
        cmp     #<$0B00
        bne     L36AE
        lda     write_params3::trans_count+1
        cmp     #>$0B00
        beq     L366B
L36AE:  MLI_CALL CLOSE, close_params6
        MLI_CALL CLOSE, close_params7
        jsr     get_file_info_and_copy
        jsr     do_set_file_info
        rts

        ;; copy file_type, aux_type, storage_type
L36C1:  ldx     #7
:       lda     get_file_info_params2,x
        sta     create_params3,x
        dex
        cpx     #3
        bne     :-
        lda     #$C3
        sta     create_params3::access
        ldx     #$03
L36D5:  lda     get_file_info_params2::create_date,x
        sta     create_params3::create_date,x
        dex
        bpl     L36D5
        lda     create_params3::storage_type
        cmp     #$0F
        bne     L36EA
        lda     #$0D
        sta     create_params3::storage_type
L36EA:  MLI_CALL CREATE, create_params3
        clc
        beq     L36F6
        jmp     handle_error_code

L36F6:  rts

        .byte   0
        .byte   0
        .byte   0
        .byte   0

L36FB:  lda     L3150
        bne     L3701
        rts

L3701:  ldx     #$00
        ldy     path2
        lda     #'/'
        sta     path2+1,y
        iny
L370C:  cpx     L3150
        bcs     L371C
        lda     L3151,x
        sta     path2+1,y
        inx
        iny
        jmp     L370C

L371C:  sty     path2
        rts

L3720:  ldx     path2
        bne     L3726
        rts

L3726:  lda     path2,x
        cmp     #'/'
        beq     L3734
        dex
        bne     L3726
        stx     path2
        rts

L3734:  dex
        stx     path2
        rts

L3739:  lda     L3150
        bne     L373F
        rts

L373F:  ldx     #$00
        ldy     path1
        lda     #'/'
        sta     path1+1,y
        iny
L374A:  cpx     L3150
        bcs     L375A
        lda     L3151,x
        sta     path1+1,y
        inx
        iny
        jmp     L374A

L375A:  sty     path1
        rts

L375E:  ldx     path1
        bne     L3764
        rts

L3764:  lda     path1,x
        cmp     #'/'
        beq     L3772
        dex
        bne     L3764
        stx     path1
        rts

L3772:  dex
        stx     path1
        rts

L3777:  ldy     #0
        sta     L353C
        dey
L377D:  iny
        lda     L324A,y
        cmp     #'/'
        bne     L3788
        sty     L353C
L3788:  sta     path2,y
        cpy     L324A
        bne     L377D
        ldy     L320A
L3793:  lda     L320A,y
        sta     path1,y
        dey
        bpl     L3793
        rts

.proc do_set_file_info
        lda     #7              ; SET_FILE_INFO param_count
        sta     get_file_info_params3
        MLI_CALL SET_FILE_INFO, get_file_info_params3
        lda     #10             ; GET_FILE_INFO param_count
        sta     get_file_info_params3
        rts
.endproc

.proc get_file_info_and_copy
        MLI_CALL GET_FILE_INFO, get_file_info_params2
        bne     fail
        ldx     #$0A
:       lda     get_file_info_params2::access,x
        sta     get_file_info_params3::access,x
        dex
        bpl     :-
        rts

fail:   pla
        pla
        rts
.endproc

L37C5:  jsr     L381C
        clc
        adc     #<$4402
        tay
        txa
        adc     #>$4402
        tax
        tya
        rts

L37D2:  jsr     L3836
        clc
        adc     #<$4582
        tay
        txa
        adc     #>$4582
        tax
        tya
        rts

        .byte   $00,$00

;;; ============================================================

.proc read_selector_list_impl
        DEFINE_OPEN_PARAMS open_params, str_selector_list, $4000
str_selector_list:
        PASCAL_STRING "Selector.List"
        DEFINE_READ_PARAMS read_params, $4400, $0800
        DEFINE_CLOSE_PARAMS close_params

start:  MLI_CALL OPEN, open_params
        bne     :+
        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_params
        lda     #0
:       rts
.endproc
        read_selector_list := read_selector_list_impl::start

;;; ============================================================

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

L3857:  .byte   $00

;;; ============================================================

.proc invoke_selector_or_desktop_impl
        sys_start := $2000

        DEFINE_OPEN_PARAMS open_desktop2_params, str_desktop2, $5000
        DEFINE_OPEN_PARAMS open_selector_params, str_selector, $5400
        DEFINE_READ_PARAMS read_params, sys_start, $0400
        DEFINE_CLOSE_PARAMS close_everything_params

str_selector:
        PASCAL_STRING "Selector"
str_desktop2:
        PASCAL_STRING "DeskTop2"


start:  MLI_CALL CLOSE, close_everything_params
        MLI_CALL OPEN, open_selector_params
        beq     selector
        MLI_CALL OPEN, open_desktop2_params
        beq     desktop2

        brk                     ; just crash

desktop2:
        lda     open_desktop2_params::ref_num
        jmp     read

selector:
        lda     open_selector_params::ref_num


read:   sta     read_params::ref_num
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_everything_params
        jmp     sys_start
.endproc
        invoke_selector_or_desktop := invoke_selector_or_desktop_impl::start

;;; ============================================================

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
        cmp     #'/'
        beq     L38D2
        dey
        bne     L38C6
L38D2:  dey
        sty     L324A
L38D6:  lda     L324A,y
        and     #$7F
        cmp     #'/'
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
        lda     LCBANK2
        lda     LCBANK2
        ldy     $D3EE
L38FD:  lda     $D3EE,y
        sta     L320A,y
        dey
        bpl     L38FD
        lda     ROMIN2
        rts

str_copying:
        PASCAL_STRING "Copying:"

str_insert:
        PASCAL_STRING "Insert the source disk and press <Return> to continue or <ESC> to cancel"

str_not_enough:
        PASCAL_STRING "Not enough room in the RAMCard, press <Return> to continue"

str_error:
        PASCAL_STRING "Error $"

str_occured:
        PASCAL_STRING " occured when copying "

str_not_completed:
        PASCAL_STRING "The copy was not completed, press <Return> to continue."

;;; ============================================================

.proc show_copying_screen
        jsr     HOME
        lda     #0
        jsr     VTABZ
        lda     #0
        jsr     set_htab
        addr_call cout_string, str_copying
        addr_call cout_string_newline, path2
        rts
.endproc

;;; ============================================================

.proc show_insert_prompt
        lda     #0
        jsr     VTABZ
        lda     #0
        jsr     set_htab
        addr_call cout_string, str_insert
        jsr     wait_enter_escape
        cmp     #CHAR_ESCAPE
        bne     :+
        jmp     finish_and_invoke

:       jsr     HOME
        rts
.endproc

;;; ============================================================

.proc show_no_space_prompt
        lda     #0
        jsr     VTABZ
        lda     #0
        jsr     set_htab
        addr_call cout_string, str_not_enough
        jsr     wait_enter_escape
        jsr     HOME
        jmp     invoke_selector_or_desktop
.endproc

;;; ============================================================

.proc handle_error_code
        cmp     #ERR_OVERRUN_ERROR
        bne     :+
        jsr     show_no_space_prompt
        jmp     finish_and_invoke

:       cmp     #ERR_VOLUME_DIR_FULL
        bne     show_error
        jsr     show_no_space_prompt
        jmp     finish_and_invoke
.endproc

;;; ============================================================

.proc show_error
        ;; Show error
        pha
        addr_call cout_string, str_error
        pla
        jsr     PRBYTE
        addr_call cout_string, str_occured
        addr_call cout_string_newline, path2
        addr_call cout_string, str_not_completed

        ;; Wait for keyboard
        sta     KBDSTRB
loop:   lda      KBD
        bpl     loop
        and     #$7F
        sta     KBDSTRB
        cmp     #'M'
        beq     L3A97
        cmp     #'m'
        beq     L3A97
        cmp     #CHAR_RETURN
        bne     loop
        jsr     HOME
        jmp     invoke_selector_or_desktop
.endproc

L3A97:  jmp     MONZ

;;; ============================================================

.proc cout_string_newline
        jsr     cout_string
        lda     #$80|CHAR_RETURN
        jmp     COUT
        ;; fall through
.endproc

.proc cout_string
        ptr := $6

        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     len
        beq     done
loop:   iny
        lda     ($06),y
        ora     #$80
        jsr     COUT
        len := *+1
        cpy     #0              ; self-modified
        bne     loop
done:   rts
.endproc

.proc set_htab
        sta     CH
        rts
.endproc

;;; ============================================================

.proc wait_enter_escape
        lda     KBD
        bpl     wait_enter_escape
        sta     KBDSTRB
        and     #$7F
        cmp     #CHAR_ESCAPE
        beq     done
        cmp     #CHAR_RETURN
        bne     wait_enter_escape
done:   rts
.endproc

;;; ============================================================

.proc finish_and_invoke
        jsr     HOME
        jmp     invoke_selector_or_desktop
.endproc

;;; ============================================================

L3AD8:  .byte   0               ; ???
        .byte   $02

L3ADA:  iny
        inx
        dec     $0200
        bne     finish_and_invoke
        lda     #$A2
        sta     $0200
        rts
.endproc ; part2

;;; ============================================================
;;; ??? Is this relocated? Part of ProDOS? RAMCard driver?
.proc WTF

        ;; Branch targets before/after this block
L3AB7           := $3AB7
L400C           := $400C
L402B           := $402B
L402C           := $402C

        ;; Routines and data outside this block
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


        copy16  #$BCBD, $BEC8
        lda     DEVNUM
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
        sta     LEVEL
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
        sta     LEVEL
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
        sta     LEVEL
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
        sta     LEVEL
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
        sta     LEVEL
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

.endproc ; WTF