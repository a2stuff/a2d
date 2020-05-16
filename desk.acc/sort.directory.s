;;; ============================================================
;;; SORT.DIRECTORY - Desk Accessory
;;;
;;; Sorts the contents of the directory (current window).
;;; If there is a selection, selected files are placed first
;;; following selection order. If there is no selection, all
;;; files are sorted by type then by name.
;;; ============================================================

        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"
        .include "../desktop/icontk.inc"

;;; ============================================================

        .org $800

dir_data_buffer     := $0E00
kDirDataBufferLen  = $0E00

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

:       lda     #>(JUMP_TABLE_SELECT_WINDOW-1)
        pha
        lda     #<(JUMP_TABLE_SELECT_WINDOW-1)
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
        buffer := dir_data_buffer
        kBufferLen = kDirDataBufferLen

        DEFINE_OPEN_PARAMS open_params, path_buf, io_buf
        DEFINE_READ_PARAMS read_params, buffer, kBufferLen
        DEFINE_WRITE_PARAMS write_params, buffer, kBufferLen
        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_FILE_INFO_PARAMS file_info_params, path_buf
        .res    3               ; for SET_FILE_INFO ???

path_buf:
        .res    kPathBufferSize, 0

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
        jsr     JUMP_TABLE_GET_WIN_PATH
        stax    $06

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

        buf_ptr1_hi := *+2
:       lda     buffer + 2

        sta     L0A95,x

        buf_ptr2_hi := *+2
        lda     buffer + 3

        sta     L0A95+1,x

        ora     L0A95,x
        beq     :+

        inc     buf_ptr1_hi
        inc     buf_ptr1_hi
        inc     buf_ptr2_hi
        inc     buf_ptr2_hi

        inx
        inx
        cpx     #$0E
        bne     :-

:       txa
        clc
        adc     #$0E
        sta     L0A93
        jsr     set_ptr_to_first_entry

:       jsr     set_ptr_to_next_entry
        bcs     jmp_exit
        ldy     #0
        lda     ($06),y
        and     #STORAGE_TYPE_MASK
        beq     :-

        ldy     #SubdirectoryHeader::file_count
        copy16in ($06),y, L0A95
        jsr     bubble_sort
        lda     unit_num
        sta     block_params::unit_num
        lda     #0
        sta     L0A94

:       lda     L0A94
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
        bne     jmp_exit
        inc     L0A94
        bne     :-

jmp_exit:
        jmp     exit

L0A3E:  copy16  #$1C00, block_params::data_buffer
        jsr     set_ptr_to_first_entry
L0A4B:  jsr     set_ptr_to_next_entry
        bcs     L0A8E
        ldy     #0
        lda     ($06),y
        and     #STORAGE_TYPE_MASK
        beq     L0A4B
        cmp     #(ST_LINKED_DIRECTORY << 4)
        bne     L0A4B
        ldy     #$11
        copy16in ($06),y, block_params::block_num
        jsr     read_block
        bne     L0A8F
        lda     $07
        sec
        sbc     #$0E
        and     #$FE
        tay
        copy16  L0A95,y, $1C27
        copy    entry_num, $1C29
        jsr     write_block
        jmp     L0A4B

L0A8E:  pla                     ; WTF ???
L0A8F:  jmp     exit

dev_num:
        .byte   0

L0A93:  .byte   0
L0A94:  .byte   0

L0A95:  .res 26, 0

entry_num:  .byte   0

;;; ============================================================
;;; Compare path from ON_LINE vs. path from window, since we
;;; need unit_num for block operations.

.proc compare_paths_for_unit_num
        lda     on_line_buffer
        and     #$0F
        sta     on_line_buffer

        ldy     #0
loop:   iny
        lda     on_line_buffer,y
        and     #CHAR_MASK
        cmp     #'a'
        bcc     :+
        and     #CASE_MASK            ; make upper-case
:       cmp     path_buf+1,y
        bne     fail
        cpy     on_line_buffer
        bne     loop

        lda     on_line_buffer
        clc
        adc     #$01
        cmp     path_buf
        beq     success
        lda     path_buf+2,y
        cmp     #'/'
        bne     fail
success:
        return  #$00

fail:   return  #$FF
.endproc

;;; ============================================================
;;; Bubble sort entries

.proc bubble_sort
        ptr1 := $06
        ptr2 := $08

start:  lda     #0
        sta     flag
        jsr     set_ptr_to_first_entry
        jsr     set_ptr_to_next_entry

loop:   copy16  ptr1, ptr2
        jsr     set_ptr_to_next_entry
        bcs     done

        jsr     compare_file_entries
        bcc     loop
        jsr     swap_entries
        lda     #$FF
        sta     flag
        bne     loop

done:   lda     flag
        bne     start
        rts

flag:   .byte   0
.endproc

;;; ============================================================

.proc set_ptr_to_next_entry
        ptr := $06

        inc     entry_num
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
        sta     entry_num
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

.proc set_ptr_to_first_entry
        ptr := $06

        lda     #1
        sta     entry_num
        copy16  #dir_data_buffer + 4, ptr
        rts
.endproc

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
;;; Compare file entries ($06, $08); order returned in carry.

;;; Uses compare_selection_orders, compare_file_entry_names,
;;; and compare_entry_types_and_names as appropriate.

.proc compare_file_entries
        ptr1 := $06
        ptr2 := $08

        ldy     #0
        lda     (ptr1),y
        and     #STORAGE_TYPE_MASK ; Active file entry?
        bne     :+
        jmp     rtcc

:       lda     (ptr2),y
        and     #STORAGE_TYPE_MASK ; Active file entry?
        bne     :+
        jmp     rtcs

:       jsr     JUMP_TABLE_GET_SEL_COUNT
        beq     :+
        jsr     JUMP_TABLE_GET_SEL_WIN
        beq     :+
        jmp     compare_selection_orders

:       ldax    ptr2
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
;;; Compare selection order of icons; order returned in carry.
;;; Handles either icon being not selected.

.proc compare_selection_orders
        entry_ptr := $10
        filename  := $06
        filename2 := $08

        jsr     JUMP_TABLE_GET_SEL_COUNT
        tax
loop:   dex
        bmi     done1

        ;; Look up next icon, compare length.
        txa
        pha
        jsr     JUMP_TABLE_GET_SEL_ICON
        stax    entry_ptr
        pla
        tax
        add16   entry_ptr, #IconEntry::len, entry_ptr
        ldy     #0
        lda     (entry_ptr),y
        sec
        sbc     #2              ; remove leading/trailing space
        sta     cmp_len
        inc16   entry_ptr       ; points at start of name

        lda     (filename),y
        and     #NAME_LENGTH_MASK
        cmp_len := *+1
        cmp     #0
        bne     loop            ; lengths don't match, so not a match

        ;; Bytewise compare names.
        sta     cpy_len
next:   iny                     ; skip leading space
        lda     (entry_ptr),y
        and     #CHAR_MASK
        cmp     #'a'
        bcc     :+
        and     #CASE_MASK      ; make upper-case
:       sta     cmp_char
        lda     (filename),y
        and     #CHAR_MASK
        cmp     #'a'
        bcc     :+
        and     #CASE_MASK      ; make upper-case
        cmp_char := *+1
:       cmp     #0
        bne     loop            ; no match - try next icon
        cpy_len := *+1
        cpy     #0
        bne     next

done1:  stx     match           ; match, or $FF if none

        jsr     JUMP_TABLE_GET_SEL_COUNT
        tax
loop2:  dex
        bmi     done2

        ;; Look up next icon, compare length.
        txa
        pha
        jsr     JUMP_TABLE_GET_SEL_ICON
        stax    entry_ptr
        pla
        tax
        add16   entry_ptr, #IconEntry::len, entry_ptr
        ldy     #0
        lda     (entry_ptr),y   ; len
        sec
        sbc     #2              ; remove leading/trailing space
        sta     cmp_len2
        inc16   entry_ptr       ; points at start of name

        lda     (filename2),y
        and     #NAME_LENGTH_MASK
        cmp_len2 := *+1
        cmp     #0
        bne     loop2            ; lengths don't match, so not a match

        ;; Bytewise compare names.
        sta     cpy_len2
next2:  iny
        lda     (entry_ptr),y
        and     #CHAR_MASK
        cmp     #'a'
        bcc     :+
        and     #CASE_MASK      ; make upper-case
:       sta     cmp_char2
        lda     (filename2),y
        and     #CHAR_MASK
        cmp     #'a'
        bcc     :+
        and     #CASE_MASK      ; make upper-case
        cmp_char2 := *+1
:       cmp     #0
        bne     loop2           ; no match - try next icon
        cpy_len2 := *+1
        cpy     #0
        bne     next2

done2:  stx     match2          ; match, or $FF if none

        lda     match
        and     match2
        cmp     #$FF            ; if either didn't match
        beq     clear
        lda     match2
        cmp     match
        beq     clear           ; if they're the same
        rts                     ; otherwise carry is order

        ;; No match
        sec
        rts

clear:  clc
        rts

match:  .byte   0
match2: .byte   0
.endproc

;;; ============================================================
;;; Compare file types/names ($06, $08 = ptrs, A=type)
;;;
;;; Output: A=$FF if neither matches type; A=$00 and carry is order

.proc compare_entry_types_and_names
        ptr1 := $06
        ptr2 := $08
        kMaxLength = 16

        sta     type0

        ldy     #kMaxLength
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
