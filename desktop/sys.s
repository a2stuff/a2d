        .setcpu "6502"

        .org $2000

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../macros.inc"

;;; ============================================================
.proc copy_desktop_to_ramcard

        jmp     start

;;; ============================================================
;;; Data buffers and param blocks

date:   .word   0               ; written into file

L2005:
        .res    832, 0

        .byte   $02,$00
        .addr   L2363

        path_buf := $D00

.proc get_prefix_params2
param_count:    .byte   2       ; GET_PREFIX, but param_count is 2 ??? Bug???
data_buffer:    .addr   path_buf
.endproc

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params4, path_buf

        .byte   $00,$01
        .addr   L2362
L2362:  .byte   0
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

        open_srcfile_io_buffer := $0D00
        open_dstfile_io_buffer := $1100
        DEFINE_OPEN_PARAMS open_srcfile_params, buffer, open_srcfile_io_buffer
        DEFINE_OPEN_PARAMS open_dstfile_params, path0, open_dstfile_io_buffer
        DEFINE_READ_PARAMS read_srcfile_params, copy_buffer, max_copy_count
        DEFINE_WRITE_PARAMS write_dstfile_params, copy_buffer, max_copy_count

        DEFINE_CREATE_PARAMS create_params, path0, ACCESS_DEFAULT, 0, 0
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
        bne     :+
        copy16  date, DATELO    ; Copy timestamp embedded in this file
:       lda     MACHID
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
        ldx     #0
        jsr     stx_lc_d3ff

        ;; Point $8 at $C100
        lda     #0
        sta     flag
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
:       lda     DEVLST,y
        cmp     #$3E
        beq     :+
        dey
        bpl     :-
        jmp     fail

:       lda     #$03
        bne     :+
found_slot:
        lda     $08+1
        and     #$0F            ; slot # in A
:       sta     slot

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
        sta     write_block2_params_unit_num
        MLI_CALL WRITE_BLOCK, write_block_params
        bne     :+
        MLI_CALL WRITE_BLOCK, write_block2_params
:       lda     on_line_buffer
        and     #$0F
        tay

        iny
        sty     path0
        lda     #'/'
        sta     on_line_buffer
        sta     path0+1
:       lda     on_line_buffer,y
        sta     path0+1,y
        dey
        bne     :-

        ldx     #$C0
        jsr     stx_lc_d3ff
        addr_call copy_to_lc2_b, path0
        jsr     check_desktop2_on_device
        bcs     :+
        ldx     #$80
        jsr     stx_lc_d3ff
        jsr     copy_2005_to_lc2_a
        jmp     fail

:       lda     BUTN1
        sta     butn1
        lda     BUTN0
        bpl     start_copy
        jmp     fail

str_slash_desktop:
        PASCAL_STRING "/DeskTop"

        ;; Overwrite first bytes of get_file_info_params
.proc dir_file_info
        .byte   $A              ; param_count
        .addr   0               ; pathname
        .byte   ACCESS_DEFAULT  ; access
        .byte   FT_DIRECTORY    ; filetype
        .word   0               ; aux_type
        .byte   ST_LINKED_DIRECTORY ; storage_type
.endproc

start_copy:
        jsr     show_copying_screen
        MLI_CALL GET_PREFIX, get_prefix_params
        beq     :+
        jmp     fail_copy
:       dec     buffer
        ldx     #$80
        jsr     stx_lc_d3ff

        ldy     buffer
:       lda     buffer,y
        sta     L2005,y
        dey
        bpl     :-

        ldy     path0
        ldx     #0
:       iny
        inx
        lda     str_slash_desktop,x
        sta     path0,y
        cpx     str_slash_desktop
        bne     :-
        sty     path0

        ;; copy file_type, aux_type, storage_type
        ldx     #7
:       lda     dir_file_info,x
        sta     get_file_info_params,x
        dex
        cpx     #3
        bne     :-

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
        beq     :+
        sta     path0
        MLI_CALL SET_PREFIX, set_prefix_params
:       jsr     write_desktop1
        jsr     copy_2005_to_lc2_a

        lda     #$00
        sta     RAMWORKS_BANK   ; ???

        ldy     #BITMAP_SIZE-1
:       sta     BITMAP,y
        dey
        bpl     :-
        jmp     copy_selector_entries_to_ramcard

.proc stx_lc_d3ff
        lda     LCBANK2
        lda     LCBANK2
        stx     $D3FF
        lda     ROMIN2
        rts
.endproc

.proc copy_to_lc2_b
        ptr := $6
        target := $D3EE

        stax    ptr
        lda     LCBANK2
        lda     LCBANK2
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     target,y
        dey
        bpl     :-
        lda     ROMIN2
        rts
.endproc

.proc copy_to_lc2_a
        ptr := $6
        target := $D3AD

        stax    ptr
        lda     LCBANK2
        lda     LCBANK2
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     target,y
        dey
        bpl     :-
        lda     ROMIN2
        rts
.endproc

fail:   lda     #0
        sta     flag
        jmp     fail2

        .byte   0, $D, 0, 0, 0

        ;; Generic buffer?
buffer: .res 300, 0

filename_buf:
        .res 16, 0

file_type:                      ; written but not read ???
        .byte   0

        .res 31, 0              ; unused ???

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
        ldy     #0
loop:   lda     IN,y
        cmp     #$80|CHAR_RETURN
        beq     done
        and     #CHAR_MASK
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

        open_io_buffer := $A000
        dir_buffer := $A400
        dir_bufsize := BLOCK_SIZE

        entry_length_offset := $23
        file_count_offset := $25
        header_length := $2B

        DEFINE_OPEN_PARAMS open_params, buffer, open_io_buffer
        DEFINE_READ_PARAMS read_params, dir_buffer, dir_bufsize
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
        bne     :+
        jmp     L29F6

:       and     #$0F

        tay
:       lda     (ptr),y
        sta     filename_buf,y
        dey
        bne     :-
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
        cmp     #>(dir_buffer + dir_bufsize)
        bcs     :+
        jmp     L2997

:       jmp     L299F

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

        ;; Append "DeskTop2" to path
        ldx     path_buf
        ldy     #0
loop:   inx
        iny
        lda     str_desktop2,y
        sta     path_buf,x
        cpy     str_desktop2
        bne     loop
        stx     path_buf

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
        open_io_buffer := $1000
        dt1_addr := $2000
        dt1_size := $45

        DEFINE_OPEN_PARAMS open_params, str_desktop1_path, open_io_buffer
str_desktop1_path:
        PASCAL_STRING "DeskTop/DESKTOP1"
        DEFINE_WRITE_PARAMS write_params, dt1_addr, dt1_size
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

.proc copy_2005_to_lc2_a
        addr_call copy_to_lc2_a, L2005
        rts
.endproc

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

flag:   .byte   0               ; written but not read ???

slot:   .byte   0

        DEFINE_WRITE_BLOCK_PARAMS write_block_params, prodos_loader_blocks, 0
        write_block_params_unit_num := write_block_params::unit_num
        DEFINE_WRITE_BLOCK_PARAMS write_block2_params, prodos_loader_blocks + 512, 1
        write_block2_params_unit_num := write_block2_params::unit_num

        PAD_TO $2C00

;;; ============================================================

prodos_loader_blocks:
        .assert * = $2C00, error, "Segment length mismatch"
        .incbin "inc/pdload.dat"

.endproc ; copy_desktop_to_ramcard

;;; ============================================================

        .assert * = $3000, error, "Segment length mismatch"

;;; SPECULATION: This copies Selector entries marked
;;; "Down load" / "At boot" to the RAMCard as well

.proc copy_selector_entries_to_ramcard

        ;; File format:
        ;; $  0 - number of entries (0-7) in first batch (Run List???)
        ;; $  1 - number of entries (0-15) in second batch (Other Run List???)
        ;; $  2 - 24 * 16-byte data entries
        ;;   $0 - label (length-prefixed, 15 bytes)
        ;;   $F - active_flag (other flags, i.e. download on ... ?)
        ;; $182 - 24 * 64-byte pathname
        ;; $782 - EOF

        selector_buffer := $4400
        selector_buflen := $800

.proc process_selector_list
        ptr := $6

        jsr     SLOT3ENTRY
        jsr     HOME
        lda     LCBANK2
        lda     LCBANK2
        lda     $D3FF           ; ??? last byte of selector routine?
        pha
        lda     ROMIN2
        pla
        bne     :+
        jmp     invoke_selector_or_desktop

:       lda     LCBANK2
        lda     LCBANK2
        ldx     #$17
        lda     #0
:       sta     $D395,x
        dex
        bpl     :-
        lda     ROMIN2

        ;; Load and iterate over the selector file
        jsr     read_selector_list
        beq     :+
        jmp     bail
:       lda     #0
        sta     entry_num
entry_loop:
        lda     entry_num
        cmp     selector_buffer ; done?
        beq     done_entries
        jsr     compute_label_addr
        stax    ptr

        ldy     #$0F            ; check active flag
        lda     (ptr),y
        bne     next_entry
        lda     entry_num
        jsr     compute_path_addr

        jsr     L38B2
        jsr     L3489

        lda     LCBANK2
        lda     LCBANK2
        ldx     entry_num
        lda     #$FF
        sta     $D395,x
        lda     ROMIN2

next_entry:
        inc     entry_num
        jmp     entry_loop
done_entries:

        ;; Process entries again ???
        lda     #0
        sta     entry_num

entry_loop2:
        lda     entry_num
        cmp     selector_buffer + 1 ; ???
        beq     bail
        clc
        adc     #8              ; offset by 8 ???
        jsr     compute_label_addr
        stax    ptr

        ldy     #$0F
        lda     (ptr),y         ; check active flag
        bne     next_entry2
        lda     entry_num
        clc
        adc     #8
        jsr     compute_path_addr

        jsr     L38B2
        jsr     L3489

        lda     LCBANK2
        lda     LCBANK2
        lda     entry_num
        clc
        adc     #8
        tax
        lda     #$FF
        sta     $D395,x
        lda     ROMIN2
next_entry2:
        inc     entry_num
        jmp     entry_loop2

bail:   jmp     invoke_selector_or_desktop

entry_num:
        .byte   0
.endproc

;;; ============================================================

        open_path2_io_buffer := $0800
        DEFINE_OPEN_PARAMS open_path2_params, path2, open_path2_io_buffer
        DEFINE_READ_PARAMS read_4bytes_params, buf_4_bytes, 4
buf_4_bytes:  .res    4, 0
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_READ_PARAMS read_39bytes_params, filename, 39
        DEFINE_READ_PARAMS read_5bytes_params, buf_5_bytes, 5
buf_5_bytes:  .res    5, 0
        .res    4, 0
        DEFINE_CLOSE_PARAMS close_srcdir_params
        DEFINE_CLOSE_PARAMS close_dstdir_params

        .byte   1
        .addr   path2

        dircopy_buffer := $1100
        dircopy_bufsize := $0B00

        open_srcdir_io_buffer := $0D00
        open_dstdir_io_buffer := $1C00
        DEFINE_OPEN_PARAMS open_srcdir_params, path2, open_srcdir_io_buffer
        DEFINE_OPEN_PARAMS open_dstdir_params, path1, open_dstdir_io_buffer
        DEFINE_READ_PARAMS read_srcdir_params, dircopy_buffer, dircopy_bufsize
        DEFINE_WRITE_PARAMS write_dstdir_params, dircopy_buffer, dircopy_bufsize
        DEFINE_CREATE_PARAMS create_dir_params, path1, ACCESS_DEFAULT
        DEFINE_CREATE_PARAMS create_params, path1, 0

        .byte   0, 0

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params2, path2

        .byte   0

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params3, path1

        .byte   $00,$02,$00,$00,$00

file_info:
filename:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $40,$35,$3D,$35,$86,$31,$60,$00

path1:  .res    65, 0
path2:  .res    65, 0

L320A:  .res    64, 0
L324A:  .res    64, 0
L328A:  .res    16, 0
L329A:  .byte   $00
L329B:  .byte   $0D
L329C:  .byte   $00
ref_num:.byte   $00
L329E:  .byte   $00
L329F:  .res    170, 0
L3349:  .byte   $00
L334A:  .byte   $00

;;; ============================================================

.proc L334B
        ldx     L3349
        lda     L329E
        sta     L329F,x
        inx
        stx     L3349
        rts
.endproc

;;; ============================================================

.proc L3359
        ldx     L3349
        dex
        lda     L329F,x
        sta     L329E
        stx     L3349
        rts
.endproc

;;; ============================================================

.proc L3367
        lda     #$00
        sta     L329C
        sta     L334A
        MLI_CALL OPEN, open_path2_params
        beq     :+
        jmp     handle_error_code

:       lda     open_path2_params::ref_num
        sta     ref_num
        sta     read_4bytes_params::ref_num
        MLI_CALL READ, read_4bytes_params
        beq     :+
        jmp     handle_error_code
:       jsr     L33A4
        rts
.endproc

;;; ============================================================

.proc L3392
        lda     ref_num
        sta     close_params::ref_num
        MLI_CALL CLOSE, close_params
        beq     :+
        jmp     handle_error_code
:       rts
.endproc

;;; ============================================================

.proc L33A4
        inc     L329C
        lda     ref_num
        sta     read_39bytes_params::ref_num
        MLI_CALL READ, read_39bytes_params
        beq     :+
        jmp     handle_error_code
:       inc     L334A
        lda     L334A
        cmp     L329B
        bcc     done

        lda     #0
        sta     L334A
        lda     ref_num
        sta     read_5bytes_params::ref_num
        MLI_CALL READ, read_5bytes_params
        beq     :+
        jmp     handle_error_code
:       lda     read_5bytes_params::trans_count
        cmp     read_5bytes_params::request_count
        rts

done:   return  #0
.endproc

;;; ============================================================

.proc L33E3
        lda     L329C
        sta     L329E
        jsr     L3392
        jsr     L334B
        jsr     append_filename_to_path2
        jsr     L3367
        rts
.endproc

.proc L33F6
        jsr     L3392
        jsr     noop
        jsr     remove_filename_from_path2
        jsr     L3359
        jsr     L3367
        jsr     L340C
        jsr     remove_filename_from_path1_alt2
        rts
.endproc

.proc L340C
        lda     L329C
        cmp     L329E
        beq     :+
        jsr     L33A4
        jmp     L340C
:       rts
.endproc

;;; ============================================================

.proc L341B
        lda     #$00
        sta     L329A
        jsr     L3367
loop:   jsr     L33A4
        bne     next
        lda     filename
        beq     loop
        lda     filename
        sta     L346F
        and     #$0F
        sta     filename
        lda     #$00
        sta     L3467
        jsr     do_copy_alt
        lda     L3467
        bne     loop
        lda     file_info + 16
        cmp     #$0F
        bne     loop
        jsr     L33E3
        inc     L329A
        jmp     loop

next:   lda     L329A
        beq     done
        jsr     L33F6
        dec     L329A
        jmp     loop

done:   jsr     L3392
        rts
.endproc

;;; ============================================================

L3467:  .byte   0

do_copy_alt:
        jmp     do_copy

remove_filename_from_path1_alt2:
        jmp     remove_filename_from_path1_alt

noop:   rts

L346F:  .byte   0

;;; ============================================================
;;; Unreferenced ???

.proc copy_input_to_path2
        ldy     #0
loop:   lda     IN,y
        cmp     #$80|CHAR_RETURN
        beq     done
        and     #CHAR_MASK
        sta     path2+1,y
        iny
        jmp     loop

done:   sty     path2
        rts
.endproc

;;; ============================================================

        .res    3, 0

.proc L3489
        lda     #$FF
        sta     L353B
        jsr     L3777
        ldx     path1
        lda     #'/'
        sta     path1+1,x
        inc     path1
        ldy     #$00
        ldx     path1
:       iny
        inx
        lda     L328A,y
        sta     path1,x
        cpy     L328A
        bne     :-
        stx     path1
        MLI_CALL GET_FILE_INFO, get_file_info_params3
        cmp     #ERR_FILE_NOT_FOUND
        beq     okerr
        cmp     #ERR_VOL_NOT_FOUND
        beq     okerr
        cmp     #ERR_PATH_NOT_FOUND
        beq     okerr
        rts

okerr:  MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     L34DD
        cmp     #ERR_VOL_NOT_FOUND
        beq     prompt
        cmp     #ERR_FILE_NOT_FOUND
        bne     fail

prompt: jsr     show_insert_prompt
        jmp     okerr

fail:   jmp     handle_error_code

L34DD:  lda     get_file_info_params2::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        lda     #$00
        beq     :+
is_dir: lda     #$FF
:       sta     is_dir_flag

        ;; copy file_type, aux_type, storage_type
        ldy     #7
:       lda     get_file_info_params2,y
        sta     create_params,y
        dey
        cpy     #3
        bne     :-
        lda     #ACCESS_DEFAULT
        sta     create_params::access
        jsr     L35A9
        bcc     :+
        jmp     show_no_space_prompt

        ;; copy dates
:       ldx     #3
:       lda     get_file_info_params2::create_date,x
        sta     create_params::create_date,x
        dex
        bpl     :-

        ;; create the file
        lda     create_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     :+
        lda     #ST_LINKED_DIRECTORY
        sta     create_params::storage_type
:       MLI_CALL CREATE, create_params
        beq     :+
        jmp     handle_error_code

:       lda     is_dir_flag
        beq     do_dir
        jmp     L341B

        .byte   0

        rts

do_dir: jmp     copy_dir

is_dir_flag:
        .byte   0
.endproc

;;; ============================================================

L353B:  .byte   0
L353C:  .byte   0

remove_filename_from_path1_alt:
        jmp     remove_filename_from_path1

;;; ============================================================

.proc do_copy
        lda     file_info + 16  ; file_type ???
        cmp     #$0F            ; FT_DIRECTORY ???
        bne     do_file

        ;; Directory ???
        jsr     append_filename_to_path2
        jsr     show_copying_screen
        MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     ok
        jmp     handle_error_code

onerr:  jsr     remove_filename_from_path1
        jsr     remove_filename_from_path2
        lda     #$FF
        sta     L3467
        jmp     exit

ok:     jsr     append_filename_to_path1
        jsr     create_dir
        bcs     onerr
        jsr     remove_filename_from_path2
        jmp     exit

        ;; File ???
do_file:
        jsr     append_filename_to_path1
        jsr     append_filename_to_path2
        jsr     show_copying_screen
        MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     :+
        jmp     handle_error_code

:       jsr     L35A9
        bcc     :+
        jmp     show_no_space_prompt

:       jsr     remove_filename_from_path2
        jsr     create_dir
        bcs     cleanup
        jsr     append_filename_to_path2
        jsr     copy_dir
        jsr     remove_filename_from_path2
        jsr     remove_filename_from_path1

exit:   rts

cleanup:
        jsr     remove_filename_from_path1
        rts
.endproc

;;; ============================================================

.proc L35A9
        MLI_CALL GET_FILE_INFO, get_file_info_params2
        beq     :+
        jmp     handle_error_code

:       lda     #0
        sta     L3641
        sta     L3641+1
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
        bcs     :+
L3635:  clc
:       lda     L363F
        sta     path1
        rts

L363D:  .word   0
L363F:  .byte   0
L3640:  .byte   0
L3641:  .word   0
.endproc


;;; ============================================================

.proc copy_dir
        MLI_CALL OPEN, open_srcdir_params
        beq     :+
        jsr     handle_error_code
:       MLI_CALL OPEN, open_dstdir_params
        beq     :+
        jmp     handle_error_code
:       lda     open_srcdir_params::ref_num
        sta     read_srcdir_params::ref_num
        sta     close_srcdir_params::ref_num
        lda     open_dstdir_params::ref_num
        sta     write_dstdir_params::ref_num
        sta     close_dstdir_params::ref_num

loop:   copy16  #dircopy_bufsize, read_srcdir_params::request_count
        MLI_CALL READ, read_srcdir_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     finish
        jmp     handle_error_code

:       copy16  read_srcdir_params::trans_count, write_dstdir_params::request_count
        ora     read_srcdir_params::trans_count
        beq     finish
        MLI_CALL WRITE, write_dstdir_params
        beq     :+
        jmp     handle_error_code

:       lda     write_dstdir_params::trans_count
        cmp     #<dircopy_bufsize
        bne     finish
        lda     write_dstdir_params::trans_count+1
        cmp     #>dircopy_bufsize
        beq     loop

finish: MLI_CALL CLOSE, close_dstdir_params
        MLI_CALL CLOSE, close_srcdir_params
        jsr     get_file_info_and_copy
        jsr     do_set_file_info
        rts
.endproc

;;; ============================================================

.proc create_dir
        ;; Copy file_type, aux_type, storage_type
        ldx     #7
:       lda     get_file_info_params2,x
        sta     create_dir_params,x
        dex
        cpx     #3
        bne     :-
        lda     #ACCESS_DEFAULT
        sta     create_dir_params::access

        ;; Copy dates
        ldx     #3
:       lda     get_file_info_params2::create_date,x
        sta     create_dir_params::create_date,x
        dex
        bpl     :-

        ;; Create it
        lda     create_dir_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     :+
        lda     #ST_LINKED_DIRECTORY
        sta     create_dir_params::storage_type
:       MLI_CALL CREATE, create_dir_params
        clc
        beq     :+
        jmp     handle_error_code
:       rts
.endproc

;;; ============================================================

        .res    4, 0

;;; ============================================================

.proc append_filename_to_path2
        lda     filename
        bne     :+
        rts

:       ldx     #$00
        ldy     path2
        lda     #'/'
        sta     path2+1,y
        iny
loop:   cpx     filename
        bcs     done
        lda     filename+1,x
        sta     path2+1,y
        inx
        iny
        jmp     loop

done:   sty     path2
        rts
.endproc

;;; ============================================================

.proc remove_filename_from_path2
        ldx     path2
        bne     loop
        rts

loop:   lda     path2,x
        cmp     #'/'
        beq     done
        dex
        bne     loop
        stx     path2
        rts

done:   dex
        stx     path2
        rts
.endproc

;;; ============================================================

.proc append_filename_to_path1
        lda     filename
        bne     :+
        rts

:       ldx     #0
        ldy     path1
        lda     #'/'
        sta     path1+1,y
        iny
loop:   cpx     filename
        bcs     done
        lda     filename+1,x
        sta     path1+1,y
        inx
        iny
        jmp     loop

done:   sty     path1
        rts
.endproc

;;; ============================================================

.proc remove_filename_from_path1
        ldx     path1
        bne     loop
        rts

loop:   lda     path1,x
        cmp     #'/'
        beq     done
        dex
        bne     loop
        stx     path1
        rts

done:   dex
        stx     path1
        rts
.endproc

;;; ============================================================

.proc L3777
        ldy     #0
        sta     L353C
        dey

loop:   iny
        lda     L324A,y
        cmp     #'/'
        bne     :+
        sty     L353C
:       sta     path2,y
        cpy     L324A
        bne     loop

        ldy     L320A
loop2:  lda     L320A,y
        sta     path1,y
        dey
        bpl     loop2
        rts
.endproc

;;; ============================================================

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

;;; ============================================================
;;; Compute first offset into selector file - A*16 + 2

.proc compute_label_addr
        addr := selector_buffer + $2

        jsr     ax_times_16
        clc
        adc     #<addr
        tay
        txa
        adc     #>addr
        tax
        tya
        rts
.endproc

;;; ============================================================
;;; Compute second offset into selector file - A*64 + $182

.proc compute_path_addr
        addr := selector_buffer + $182

        jsr     ax_times_64
        clc
        adc     #<addr
        tay
        txa
        adc     #>addr
        tax
        tya
        rts
.endproc

;;; ============================================================

        .byte   $00,$00

;;; ============================================================

.proc read_selector_list_impl
        open_io_buffer := $4000

        DEFINE_OPEN_PARAMS open_params, str_selector_list, open_io_buffer
str_selector_list:
        PASCAL_STRING "Selector.List"
        DEFINE_READ_PARAMS read_params, selector_buffer, selector_buflen
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

.proc ax_times_16
        ldx     #0
        stx     bits

        .repeat 4
        asl     a
        rol     bits
        .endrepeat

        ldx     bits
        rts

bits:   .byte   0
.endproc

;;; ============================================================

.proc ax_times_64
        ldx     #0
        stx     bits

        .repeat 6
        asl     a
        rol     bits
        .endrepeat

        ldx     bits
        rts

bits:   .byte   $00
.endproc

;;; ============================================================

.proc invoke_selector_or_desktop_impl
        sys_start := $2000
        sys_size := $400

        open_dt2_io_buffer := $5000
        open_sel_io_buffer := $5400

        DEFINE_OPEN_PARAMS open_desktop2_params, str_desktop2, open_dt2_io_buffer
        DEFINE_OPEN_PARAMS open_selector_params, str_selector, open_sel_io_buffer
        DEFINE_READ_PARAMS read_params, sys_start, sys_size
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

.proc L38B2
        ptr := $6

        stax    ptr
        ldy     #$00
        lda     (ptr),y

        tay
:       lda     (ptr),y
        sta     L324A,y
        dey
        bpl     :-

        ldy     L324A
:       lda     L324A,y
        and     #CHAR_MASK
        cmp     #'/'
        beq     L38D2
        dey
        bne     :-

L38D2:  dey
        sty     L324A
L38D6:  lda     L324A,y
        and     #CHAR_MASK
        cmp     #'/'
        beq     :+
        dey
        bpl     L38D6

:       ldx     #$00
:       iny
        inx
        lda     L324A,y
        sta     L328A,x
        cpy     L324A
        bne     :-

        stx     L328A
        lda     LCBANK2
        lda     LCBANK2

        ldy     $D3EE
:       lda     $D3EE,y
        sta     L320A,y
        dey
        bpl     :-
        lda     ROMIN2
        rts
.endproc

;;; ============================================================

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
loop:   lda     KBD
        bpl     loop
        and     #CHAR_MASK
        sta     KBDSTRB
        cmp     #'M'
        beq     monitor
        cmp     #'m'
        beq     monitor
        cmp     #CHAR_RETURN
        bne     loop
        jsr     HOME
        jmp     invoke_selector_or_desktop
.endproc

monitor:
        jmp     MONZ

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
        and     #CHAR_MASK
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

.endproc ; copy_selector_entries_to_ramcard

        .assert * = $3AD8, error, "Segment size mismatch"

;;; ============================================================
;;; This is a chunk of BASIC.SYSTEM 1.1 !!
;;; (ends up in memory at $B0D8, file offset TBD)

        .incbin "inc/bs.dat"

        .assert * = $4000, error, "Segment size mismatch"
