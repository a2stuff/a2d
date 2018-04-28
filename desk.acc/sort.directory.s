        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"

        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

        .org $800


CHAR_MASK       := $7F
CASE_MASK       := $DF


;;; ============================================================

        cli
        jmp     start

        ;; unit_num for active window, for block operations
unit_num:  .byte   0

save_stack:
        .byte   0

;;; ============================================================

start:  tsx
        stx     save_stack
        jmp     start2

.proc exit
        ldx     save_stack
        txs
        lda     a:$0A
        bne     :+
        rts

:       lda     #$40
        pha
        lda     #$0B
        pha
        lda     a:$0A
        rts
.endproc

;;; ============================================================
;;; ProDOS Relays

.proc open
        sta     ALTZPOFF
        MLI_CALL OPEN, open_params
        sta     ALTZPON
        rts
.endproc

.proc read
        sta     ALTZPOFF
        MLI_CALL READ, read_params
        sta     ALTZPON
        rts
.endproc

.proc write_block
        sta     ALTZPOFF
        MLI_CALL WRITE_BLOCK, block_params
        sta     ALTZPON
        rts
.endproc

.proc read_block
        sta     ALTZPOFF
        MLI_CALL READ_BLOCK, block_params
        sta     ALTZPON
        rts
.endproc

.proc on_line
        sta     ALTZPOFF
        MLI_CALL ON_LINE, on_line_params
        sta     ALTZPON
        rts
.endproc
        .byte   0

;;; unused ???
.proc write
        sta     ALTZPOFF
        MLI_CALL WRITE, write_params
        sta     ALTZPON
        rts
.endproc

;;; unused ???
.proc set_mark
        sta     ALTZPOFF
        MLI_CALL SET_MARK, set_mark_params
        sta     ALTZPON
        rts
.endproc

;;; unused ???
.proc get_file_info
        sta     ALTZPOFF
        MLI_CALL GET_FILE_INFO, file_info_params
        sta     ALTZPON
        rts
.endproc

;;; unused ???
.proc set_file_info
        sta     ALTZPOFF
        MLI_CALL SET_FILE_INFO, file_info_params
        sta     ALTZPON
        rts
.endproc

.proc close
        sta     ALTZPOFF
        MLI_CALL CLOSE, close_params
        sta     ALTZPON
        rts
.endproc

;;; ============================================================
;;; ProDOS call parameter blocks

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer
on_line_buffer:
        .res    16, 0

        DEFINE_SET_MARK_PARAMS set_mark_params, $2B
        DEFINE_READ_BLOCK_PARAMS block_params, 0, 0

        .byte   0

        io_buf := $1C00
        buffer := $0E00
        buffer_len := $0E00

        DEFINE_OPEN_PARAMS open_params, path_buf, io_buf
        DEFINE_READ_PARAMS read_params, buffer, buffer_len
        DEFINE_WRITE_PARAMS write_params, buffer, buffer_len
        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_FILE_INFO_PARAMS file_info_params, path_buf
        .res    3               ; for SET_FILE_INFO ???

path_buf:
        .res    65, 0

;;; ============================================================
;;; Main DA logic

.proc start2
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ptr := $0A

        yax_call JUMP_TABLE_MGTK_RELAY, MGTK::FrontWindow, ptr
        lda     ptr             ; any window open?
        beq     bail            ; nope, bail

        cmp     #9              ; DeskTop windows are 1-8
        bcc     has_window
bail:   jmp     exit
.endproc

has_window:

.scope
        ;; Copy window path to buffer
        asl     a               ; window index * 2
        tay
        copy16  path_table,y, $06
        ldy     #0
        sty     $10             ; ???
        lda     ($06),y
        sta     len
        sta     path_buf
loop:   iny
        lda     ($06),y
        and     #CHAR_MASK
        cmp     #'a'            ; lower case?
        bcc     :+
        and     #CASE_MASK      ; restore to upper-case
:       sta     path_buf,y
        len := *+1
        cpy     #0
        bne     loop
.endscope

.scope
        ;; Enumerate devices to find unit_num matching path.
        ldy     DEVCNT
        sty     dev_num
loop:   ldy     dev_num
        lda     DEVLST,y
        and     #$F0            ; mask off drive/slot
        sta     on_line_params::unit_num
        jsr     on_line
        bne     next
        jsr     compare_paths_for_unit_num
        beq     found_unit_num
next:   dec     dev_num
        bpl     loop
.endscope

exit1:  jmp     exit

found_unit_num:
        lda     on_line_params::unit_num
        sta     unit_num
        jsr     open
        bne     exit1
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num

        ;; Read a chunk of the directory
        jsr     read
        jsr     close
        bne     exit1
        ldx     #$02

        L09BC := *+2
L09BA:  lda     buffer + 2

        sta     L0A95,x

        L09C2 := *+2
        lda     buffer + 3

        sta     L0A95+1,x

        ora     L0A95,x
        beq     L09DD
        inc     L09BC
        inc     L09BC
        inc     L09C2
        inc     L09C2
        inx
        inx
        cpx     #$0E
        bne     L09BA

L09DD:  txa
        clc
        adc     #$0E
        sta     L0A93
        jsr     L0B40
L09E7:  jsr     L0B16
        bcs     L0A3B
        ldy     #0
        lda     ($06),y
        and     #STORAGE_TYPE_MASK
        beq     L09E7
        ldy     #SubdirectoryHeader::file_count
        lda     ($06),y
        sta     L0A95
        iny
        lda     ($06),y
        sta     L0A95+1
        jsr     L0AE8
        lda     unit_num
        sta     block_params::unit_num
        lda     #$00
        sta     L0A94
L0A0F:  lda     L0A94
        asl     a
        tay
        copy16  L0A95,y, block_params::block_num
        ora     block_params::block_num
        beq     L0A3E
        tya
        clc
        adc     #$0E
        sta     block_params::data_buffer+1
        lda     #$00
        sta     block_params::data_buffer
        jsr     write_block
        bne     L0A3B
        inc     L0A94
        bne     L0A0F
L0A3B:  jmp     exit

L0A3E:  copy16  #$1C00, block_params::data_buffer
        jsr     L0B40
L0A4B:  jsr     L0B16
        bcs     L0A8E
        ldy     #0
        lda     ($06),y
        and     #STORAGE_TYPE_MASK
        beq     L0A4B
        cmp     #(ST_LINKED_DIRECTORY << 4)
        bne     L0A4B
        ldy     #$11
        lda     ($06),y
        sta     block_params::block_num
        iny
        lda     ($06),y
        sta     block_params::block_num+1
        jsr     read_block
        bne     L0A8F
        lda     $07
        sec
        sbc     #$0E
        and     #$FE
        tay
        copy16  L0A95,y, $1C27
        copy    L0AAF, $1C29
        jsr     write_block
        jmp     L0A4B

L0A8E:  pla
L0A8F:  jmp     exit

dev_num:
        .byte   0

L0A93:  .byte   0
L0A94:  .byte   0

L0A95:  .res 26, 0

L0AAF:  .byte   0

;;; ============================================================
;;; Compare path from ON_LINE vs. path from window, since we
;;; need unit_num for block operations.

.proc compare_paths_for_unit_num
        lda     on_line_buffer
        and     #$0F
        sta     on_line_buffer
        ldy     #0
L0ABA:  iny
        lda     on_line_buffer,y
        and     #CHAR_MASK
        cmp     #'a'
        bcc     L0AC6
        and     #CASE_MASK            ; make upper-case
L0AC6:  cmp     path_buf+1,y
        bne     L0AE5
        cpy     on_line_buffer
        bne     L0ABA
        lda     on_line_buffer
        clc
        adc     #$01
        cmp     path_buf
        beq     L0AE2
        lda     path_buf+2,y
        cmp     #'/'
        bne     L0AE5
L0AE2:  return  #$00

L0AE5:  return  #$FF
.endproc

;;; ============================================================

.proc L0AE8
        lda     #$00
        sta     L0B15
        jsr     L0B40
        jsr     L0B16
L0AF3:  copy16  $06, $08
        jsr     L0B16
        bcs     L0B0F
        jsr     L0B5E
        bcc     L0AF3
        jsr     swap_entries
        lda     #$FF
        sta     L0B15
        bne     L0AF3
L0B0F:  lda     L0B15
        bne     L0AE8
        rts

L0B15:  .byte   0
.endproc

;;; ============================================================

.proc L0B16
        ptr := $06

        inc     L0AAF
        lda     ptr
        clc
        adc     #.sizeof(FileEntry)
        sta     ptr
        bcc     :+
        inc     ptr+1

:       lda     ptr
        cmp     #$FF
        bne     rtcc
        inc     ptr+1
        lda     #1
        sta     L0AAF
        lda     #$04            ; skip over block header ???
        sta     ptr
        lda     ptr+1
        cmp     L0A93
        bcs     rtcs

rtcc:   clc
        rts

rtcs:   sec
        rts
.endproc

;;; ============================================================

L0B40:  lda     #$01
        sta     L0AAF
        copy16  #$0E04, $06
        rts

;;; ============================================================
;;; Swap file entries

.proc swap_entries
        ptr1 := $06
        ptr2 := $08

        ldy     #.sizeof(FileEntry) - 1
loop:   lda     (ptr1),y
        pha
        lda     (ptr2),y
        sta     (ptr1),y
        pla
        sta     (ptr2),y
        dey
        bpl     loop
        rts
.endproc

;;; ============================================================

.proc L0B5E
        ptr1 := $06
        ptr2 := $08

        ldy     #0
        lda     (ptr1),y
        and     #STORAGE_TYPE_MASK ; Active file entry?
        bne     L0B69
        jmp     rtcc

L0B69:  lda     (ptr2),y
        and     #STORAGE_TYPE_MASK ; Active file entry?
        bne     L0B72
        jmp     rtcs

L0B72:  lda     selected_file_count
        beq     L0B7F
        lda     path_index
        beq     L0B7F
        jmp     L0BF5

L0B7F:
        ldax    ptr2
        jsr     check_system_file
        bcc     rtcc

        ldax    ptr1
        jsr     check_system_file
        bcc     rtcs

        ldy     #0
        lda     (ptr2),y
        and     #STORAGE_TYPE_MASK
        sta     storage_type2

        ldy     #0
        lda     (ptr1),y
        and     #STORAGE_TYPE_MASK
        sta     storage_type1

        ;; Why does this dir-first comparison not just use FT_DIRECTORY ???

        ;; Is #2 a dir?
        lda     storage_type2
        cmp     #(ST_LINKED_DIRECTORY << 4)
        beq     dirs            ; yep, check #1

        ;; Is #1 a dir?
        lda     storage_type1
        cmp     #(ST_LINKED_DIRECTORY << 4)
        beq     rtcs            ; yep, but 2 wasn't, so order
        bne     check_types     ; neither are dirs - check types

        ;; #2 was a dir - is #1?
dirs:   lda     storage_type1
        cmp     #(ST_LINKED_DIRECTORY << 4)
        bne     rtcc

        ;; Both are dirs, order by name
        jsr     compare_file_entry_names
        bcc     rtcc
        bcs     rtcs

        ;; TXT files first
check_types:
        lda     #FT_TEXT
        jsr     compare_entry_types_and_names
        bne     :+
        bcc     rtcc
        bcs     rtcs

        ;; SYS files next
:       lda     #FT_SYSTEM
        jsr     compare_entry_types_and_names
        bne     :+
        bcc     rtcc
        bcs     rtcs

        ;; Then order by type from $FD down
:       lda     #$FD
        sta     type
loop:   dec     type
        lda     type
        beq     rtcc
        jsr     compare_entry_types_and_names
        bne     loop
        bcs     rtcs
        jmp     rtcc

rtcs:   sec
        rts

rtcc:   clc
        rts

storage_type2:
        .byte   0
storage_type1:
        .byte   0
type:   .byte   0
.endproc

;;; ============================================================

.proc L0BF5
        ldx     selected_file_count
L0BF8:  dex
        bmi     L0C4A
        lda     selected_file_list,x
        asl     a
        tay
        add16   file_table,y, #9, $10
        ldy     #$00
        lda     ($10),y
        sec
        sbc     #$02
        sta     L0C24
        inc16   $10
        lda     ($06),y
        and     #$0F

        L0C24 := *+1
        cmp     #$0

        bne     L0BF8
        sta     L0C47
L0C2A:  iny
        lda     ($10),y
        and     #CHAR_MASK
        cmp     #'a'
        bcc     L0C35
        and     #CASE_MASK            ; make upper-case
L0C35:  sta     L0C43
        lda     ($06),y
        and     #CHAR_MASK
        cmp     #'a'
        bcc     L0C42
        and     #CASE_MASK            ; make upper-case

        L0C43 := *+1
L0C42:  cmp     #0

        bne     L0BF8

        L0C47 := *+1
        cpy     #0

        bne     L0C2A
L0C4A:  stx     L0CBC
        ldx     selected_file_count
L0C50:  dex
        bmi     L0CA2
        lda     selected_file_list,x
        asl     a
        tay

        add16   file_table,y, #9, $10

        ldy     #$00
        lda     ($10),y
        sec
        sbc     #$02
        sta     L0C7C
        inc16   $10
        lda     ($08),y
        and     #$0F

        L0C7C := *+1
        cmp     #0

        bne     L0C50
        sta     L0C9F
L0C82:  iny
        lda     ($10),y
        and     #CHAR_MASK
        cmp     #'a'
        bcc     L0C8D
        and     #CASE_MASK
L0C8D:  sta     L0C9B
        lda     ($08),y
        and     #CHAR_MASK
        cmp     #'a'
        bcc     L0C9A
        and     #CASE_MASK

        L0C9B := *+1
L0C9A:  cmp     #0

        bne     L0C50

        L0C9F := *+1
        cpy     #0

        bne     L0C82
L0CA2:  stx     L0CBD
        lda     L0CBC
        and     L0CBD
        cmp     #$FF
        beq     L0CBA
        lda     L0CBD
        cmp     L0CBC
        beq     L0CBA
        rts

        sec
        rts

L0CBA:  clc
        rts

L0CBC:  .byte   0
L0CBD:  .byte   0
.endproc

;;; ============================================================
;;; Compare file types/names ($06, $08 = ptrs, A=type)
;;;
;;; Output: A=$FF if neither matches type; A=$00 and carry is order

.proc compare_entry_types_and_names
        ptr1 := $06
        ptr2 := $08
        max_length := 16

        sta     type0

        ldy     #max_length
        lda     (ptr2),y
        sta     type2
        lda     (ptr1),y
        sta     type1

        lda     type2
        cmp     type0
        beq     :+

        lda     type1
        cmp     type0
        beq     rtcs

        bne     neither

:       lda     type1
        cmp     type0
        bne     rtcc
        jsr     compare_file_entry_names
        bcc     rtcc
        bcs     rtcs

neither:
        return  #$FF

type2:  .byte   0
type1:  .byte   0

rtcc:   lda     #0
        clc
        rts

rtcs:   lda     #0
        sec
        rts

type0:  .byte   0
.endproc

;;; ============================================================
;;; Is the file entry a SYS file with .SYSTEM suffix?
;;; Returns carry clear if true, set if false.

.proc check_system_file
        ptr := $00

        ;; Check for SYS
        stax    ptr
        ldy     #FileEntry::file_type
        lda     (ptr),y
        cmp     #$FF            ; type=SYS
        bne     fail

        ;; Could name end in .SYSTEM?
        ldy     #FileEntry::storage_type_name_length
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        sec
        sbc     #.strlen(".SYSTEM")-1
        bcc     fail            ; too short
        tay

        ;; Check name suffix
        ldx     #0
        dey
loop:   iny
        inx
        lda     (ptr),y
        and     #CHAR_MASK
        cmp     str_system,x
        bne     fail
        cpx     str_system
        bne     loop

        clc
        rts

fail:   sec
        rts

str_system:
        PASCAL_STRING ".SYSTEM"
.endproc

;;; ============================================================
;;; Compare file entry names; carry indicates order

.proc compare_file_entry_names
        ptr1 := $06
        ptr2 := $08

        ldy     #0
        lda     (ptr2),y
        and     #NAME_LENGTH_MASK
        sta     len2

        sta     len
        lda     (ptr1),y
        and     #NAME_LENGTH_MASK
        sta     len1
        cmp     len
        bcs     :+
        sta     len

:       ldy     #0
loop:   iny
        lda     (ptr2),y
        cmp     (ptr1),y
        beq     next
        bcc     rtcc
rtcs:   sec
        rts

        len := *+1
next:   cpy     #0

        bne     loop
        lda     len2
        cmp     len1
        beq     rtcc
        bcs     rtcs
rtcc:   clc
        rts

len2:   .byte   0
len1:   .byte   0

.endproc
