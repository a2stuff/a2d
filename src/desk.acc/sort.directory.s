;;; ============================================================
;;; SORT.DIRECTORY - Desk Accessory
;;;
;;; Sorts the contents of the directory (current window).
;;; If there is a selection, selected files are placed first
;;; following selection order. If there is no selection, all
;;; files are sorted by type then by name.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../lib/alert_dialog.inc"
        .include "../desktop/desktop.inc"
        .include "../toolkits/icontk.inc"

;;; ============================================================
;;; Memory map
;;;
;;;              Main           Aux
;;;          :           : :           :
;;;          |           | |           |
;;;  $7800   +-----------+ |           |
;;;          | Directory | |           |
;;;          | Data      | |           |
;;;          | Buffer    | |           |
;;;  $5000   +-----------+ |           |
;;;          :           : :           :
;;;  $4000   +-----------+ +-----------+
;;;          |           | |           |
;;;          :           : :           :
;;;          | DHR       | | DHR       |
;;;  $2000   +-----------+ +-----------+
;;;          | IO Buffer | | (mostly   |
;;;  $1C00   +-----------+ |  unused)  |
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          | (unused)  | |           |
;;;          |           | |           |
;;;   $E00   +-----------+ |           |
;;;          |           | |           |
;;;          |           | | Alert     |
;;;          | DA        | | Resources |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================
;;; Alerts

.params AlertNoWindowsOpen
        .addr   str_alert_no_windows_open
        .byte   AlertButtonOptions::OK
        .byte   AlertOptions::Beep | AlertOptions::SaveBack
.endparams
str_alert_no_windows_open:
        PASCAL_STRING res_string_alert_no_windows_open

;;; ============================================================

        DA_END_AUX_SEGMENT
        DA_START_MAIN_SEGMENT

;;; ============================================================

        MLIEntry := MLI

;;; There is not enough room in the DA load area to a directory with
;;; 127 entries, the maximum number of icons DeskTop can handle. A
;;; buffer is available in DeskTop itself, in an area that can be
;;; restored after use.
dir_data_buffer         := OVERLAY_BUFFER
        .assert (<dir_data_buffer) = 0, error, "Must be page aligned"

kDirDataBufferLen       = kOverlayBufferSize

;;; ============================================================

;;; ID of window for directory to sort
window_id := $0A

;;; ============================================================

        jmp     start

;;; unit_num for active window, for block operations
unit_num:
        .byte   0

saved_stack:
        .byte   0

;;; ============================================================

start:  tsx
        stx     saved_stack
        jmp     Start2

.proc Exit
        ldx     saved_stack
        txs

        lda     window_id
    IF ZERO
        TAIL_CALL JUMP_TABLE_SHOW_ALERT_PARAMS, AX=#aux::AlertNoWindowsOpen
    END_IF

        CALL    JUMP_TABLE_RESTORE_OVL, A=#kDynamicRoutineRestoreBuffer

        TAIL_CALL JUMP_TABLE_ACTIVATE_WINDOW, A=window_id
.endproc ; Exit

;;; ============================================================
;;; ProDOS Relays

.proc Open
        sta     ALTZPOFF
        MLI_CALL OPEN, open_params
        sta     ALTZPON
        rts
.endproc ; Open

.proc Read
        sta     ALTZPOFF
        MLI_CALL READ, read_params
        sta     ALTZPON
        rts
.endproc ; Read

.proc WriteBlock
        sta     ALTZPOFF
        MLI_CALL WRITE_BLOCK, block_params
        sta     ALTZPON
        rts
.endproc ; WriteBlock

.proc ReadBlock
        sta     ALTZPOFF
        MLI_CALL READ_BLOCK, block_params
        sta     ALTZPON
        rts
.endproc ; ReadBlock

.proc Close
        sta     ALTZPOFF
        MLI_CALL CLOSE, close_params
        sta     ALTZPON
        rts
.endproc ; Close

;;; ============================================================
;;; ProDOS call parameter blocks

        DEFINE_SET_MARK_PARAMS set_mark_params, $2B
        DEFINE_READWRITE_BLOCK_PARAMS block_params, 0, 0

        buffer := dir_data_buffer
        kBufferLen = kDirDataBufferLen

        DEFINE_OPEN_PARAMS open_params, path_buf, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS read_params, buffer, kBufferLen
        DEFINE_READWRITE_PARAMS write_params, buffer, kBufferLen
        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_FILE_INFO_PARAMS file_info_params, path_buf

path_buf:
        .res    kPathBufferSize, 0

;;; ============================================================
;;; Main DA logic

exit1:  jmp     Exit

.proc Start2
        ;; Grab top window
        JUMP_TABLE_MGTK_CALL MGTK::FrontWindow, window_id
        lda     window_id       ; any window open?
        beq     exit1           ; nope, bail

        cmp     #kMaxDeskTopWindows+1 ; is it DeskTop window?
    IF GE
        copy8   #0, window_id   ; nope, bail
        beq     exit1           ; always
    END_IF

        ;; Copy window path to buffer
        ptr := $06

        jsr     JUMP_TABLE_GET_WIN_PATH
        stax    ptr

        ldy     #0
        lda     (ptr),y
        tay
    DO
        copy8   (ptr),y, path_buf,y
        dey
    WHILE POS

        FALL_THROUGH_TO ReadSortWrite
.endproc ; Start2

.proc ReadSortWrite

        ptr := $06

        ;; --------------------------------------------------
        ;; Read the directory (up to 14 blocks)
.scope read

        jsr     Open
        bne     exit1
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num

        ;; Save last accessed device's unit_num for block operations.
        copy8   DEVNUM, unit_num

        jsr     Read
        jsr     Close
        bne     exit1
        ldx     #2

        ;; Process "blocks"
loop:
        buf_ptr1_hi := *+2
        lda     buffer + 2

        sta     block_num_table,x

        buf_ptr2_hi := *+2
        lda     buffer + 3

        sta     block_num_table+1,x

        ora     block_num_table,x
    IF NOT_ZERO
        ;; Move to next "block"
        inc     buf_ptr1_hi
        inc     buf_ptr1_hi
        inc     buf_ptr2_hi
        inc     buf_ptr2_hi

        inx
        inx
        cpx     #>kDirDataBufferLen
        bne     loop
    END_IF

        ;; Prepare for sorting
        txa
        clc
        adc     #>dir_data_buffer
        sta     end_block_page

        ;; Get key block of directory by using header pointer of first entry
        jsr     SetPtrToFirstEntry
    DO
        jsr     SetPtrToNextEntry
        bcs     jmp_exit
        ldy     #0
        lda     (ptr),y
        and     #STORAGE_TYPE_MASK ; skip deleted entries
    WHILE ZERO
        ldy     #FileEntry::header_pointer
        copy16in (ptr),y, block_num_table
.endscope ; read

        ;; --------------------------------------------------
        ;; Sort the directory entries

        jsr     BubbleSort

        ;; --------------------------------------------------
        ;; Write the directory back out

.scope write
        copy8   unit_num, block_params::unit_num
        copy8   #0, block_index

        ;; Write the blocks listed in the table out.
loop1:  lda     block_index
        asl     a
        tay
        copy16  block_num_table,y, block_params::block_num
        ora     block_params::block_num ; done?
        beq     update_dir_blocks

        tya                     ; Find address of block data
        clc
        adc     #>dir_data_buffer
        sta     block_params::data_buffer+1
        copy8   #0, block_params::data_buffer
        jsr     WriteBlock      ; Write it out
        bne     jmp_exit
        inc     block_index
        bne     loop1

jmp_exit:
        jmp     Exit

        block_buf := DA_IO_BUFFER

        ;; For subdirectories, update parent_pointer/parent_entry_number
        ;; See ProDOS 8 Technical Reference Manual B.2.3 - Subdirectory Headers
update_dir_blocks:
        copy16  #block_buf, block_params::data_buffer
        jsr     SetPtrToFirstEntry
loop2:  jsr     SetPtrToNextEntry
        bcs     done
        ldy     #0
        lda     (ptr),y
        and     #STORAGE_TYPE_MASK ; skip deleted entries
        beq     loop2
        cmp     #(ST_LINKED_DIRECTORY << 4) ; skip non-directories
        bne     loop2

        ;; Grab key block, using pointer in directory.
        ldy     #FileEntry::key_pointer
        copy16in (ptr),y, block_params::block_num
        jsr     ReadBlock
        bne     done

        ;; Calculate entry's block index from address
        lda     ptr+1
        sec
        sbc     #>dir_data_buffer
        and     #%11111110      ; /2 to get index, *2 to get table ptr
        tay

        ;; Update pointers and rewrite key block.
        copy16  block_num_table,y, block_buf + SubdirectoryHeader::parent_pointer
        copy8   entry_num, block_buf + SubdirectoryHeader::parent_entry_number
        jsr     WriteBlock
        jmp     loop2

done:   jmp     Exit

.endscope ; write
        jmp_exit := write::jmp_exit

.endproc ; ReadSortWrite

;;; ============================================================

;;; Device number (needed for writing blocks)
dev_num:
        .byte   0

;;; Page (address hi byte) after last block.
end_block_page:
        .byte   0

;;; Block index when writing directory blocks back out.
block_index:
        .byte   0

;;; Table of directory block numbers (words); the directory is read using
;;; file I/O but must be written out using block I/O. The necessary block
;;; numbers to write are extracted and stored here.
block_num_table:
        .res 26, 0

entry_num:
        .byte   0

;;; ============================================================
;;; Bubble sort entries

.proc BubbleSort
        ptr1 := $06
        ptr2 := $08

start:  copy8   #0, flag
        jsr     SetPtrToFirstEntry
        jsr     SetPtrToNextEntry

    DO
        copy16  ptr1, ptr2
        jsr     SetPtrToNextEntry
        BREAK_IF CS

        jsr     CompareFileEntries
        CONTINUE_IF LT

        jsr     SwapEntries
        copy8   #$FF, flag
    WHILE NOT_ZERO              ; always

        lda     flag
        bne     start
        rts

flag:   .byte   0
.endproc ; BubbleSort

;;; ============================================================

.proc SetPtrToNextEntry
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
        copy8   #1, entry_num
        copy8   #4, ptr         ; skip over block header
        lda     ptr+1
        cmp     end_block_page
        bcs     rtcs

rtcc:   RETURN  C=0

rtcs:   RETURN  C=1
.endproc ; SetPtrToNextEntry

;;; ============================================================

.proc SetPtrToFirstEntry
        ptr := $06

        copy8   #1, entry_num
        copy16  #dir_data_buffer + 4, ptr
        rts
.endproc ; SetPtrToFirstEntry

;;; ============================================================
;;; Swap file entries

.proc SwapEntries
        ptr1 := $06
        ptr2 := $08

        ldy     #.sizeof(FileEntry) - 1
    DO
        swap8   (ptr1),y, (ptr2),y
        dey
    WHILE POS
        rts
.endproc ; SwapEntries

;;; ============================================================
;;; Compare file entries ($06, $08); order returned in carry.

;;; Uses CompareSelectionOrders, CompareFileEntryNames,
;;; and CompareEntryTypesAndNames as appropriate.

.proc CompareFileEntries
        ptr1 := $06
        ptr2 := $08

        ldy     #FileEntry::storage_type_name_length
        lda     (ptr1),y
        and     #STORAGE_TYPE_MASK ; Active file entry?
        jeq     rtcc

        lda     (ptr2),y
        and     #STORAGE_TYPE_MASK ; Active file entry?
        jeq     rtcs

        ;; Are we sorting by selection order?
        jsr     JUMP_TABLE_GET_SEL_COUNT
    IF NOT_ZERO                 ; Must have selection
        jsr     JUMP_TABLE_GET_SEL_WIN
      IF A = window_id          ; Is selection in the active window?
        jmp     CompareSelectionOrders
      END_IF
    END_IF

        ;; Sorting by type then name

        ;; SYS files with ".SYSTEM" suffix sort first
        CALL    CheckSystemFile, AX=ptr2
        php                     ; save first result (in C)
        CALL    CheckSystemFile, AX=ptr1
        lda     #0              ; combine both results
        rol
        plp
        rol                     ; now low 2 bits have 0=yes, 1=no
        beq     sys             ; both, so compare as SYS
        cmp     #%00000011      ; neither, so continue
    IF NE
        ror                     ; order back into C
        rts
    END_IF

        ;; DIR next
        CALL    CompareEntryTypesAndNames, A=#FT_DIRECTORY
        beq     ret

        ;; TXT files next
        CALL    CompareEntryTypesAndNames, A=#FT_TEXT
        beq     ret

        ;; SYS files next
sys:
        CALL    CompareEntryTypesAndNames, A=#FT_SYSTEM
        beq     ret

        ;; Then order by type from $FD down
        ldy     #FileEntry::file_type
        lda     (ptr1),y
        cmp     (ptr2),y
        bne     ret
        jmp     CompareEntryTypesAndNames

rtcs:   RETURN  C=1

rtcc:   clc
ret:    rts
.endproc ; CompareFileEntries

;;; ============================================================
;;; Compare selection order of icons; order returned in carry.
;;; Handles either icon being not selected.

.proc CompareSelectionOrders
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
        add16   entry_ptr, #IconEntry::name, entry_ptr
        ldy     #0
        copy8   (entry_ptr),y, cmp_len ; len

        lda     (filename),y
        and     #NAME_LENGTH_MASK
        cmp_len := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     loop            ; lengths don't match, so not a match

        ;; Bytewise compare names.
        sta     cpy_len
next:   iny

        lda     (entry_ptr),y
        jsr     ToUpperCase
        sta     cmp_char

        lda     (filename),y
        jsr     ToUpperCase

        cmp_char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     loop            ; no match - try next icon
        cpy_len := *+1
        cpy     #SELF_MODIFIED_BYTE
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
        add16   entry_ptr, #IconEntry::name, entry_ptr
        ldy     #0
        copy8   (entry_ptr),y, cmp_len2 ; len

        lda     (filename2),y
        and     #NAME_LENGTH_MASK
        cmp_len2 := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     loop2           ; lengths don't match, so not a match

        ;; Bytewise compare names.
        sta     cpy_len2
next2:  iny

        lda     (entry_ptr),y
        jsr     ToUpperCase
        sta     cmp_char2

        lda     (filename2),y
        jsr     ToUpperCase

        cmp_char2 := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     loop2           ; no match - try next icon
        cpy_len2 := *+1
        cpy     #SELF_MODIFIED_BYTE
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
        RETURN  C=1

clear:  RETURN  C=0

match:  .byte   0
match2: .byte   0
.endproc ; CompareSelectionOrders

;;; ============================================================
;;; Compare file types/names ($06, $08 = ptrs, A=type)
;;;
;;; Output: A=$FF if neither matches type; A=$00 and carry is order

.proc CompareEntryTypesAndNames
        ptr1 := $06
        ptr2 := $08
        kMaxLength = 16

        sta     type0

        ldy     #kMaxLength
        copy8   (ptr2),y, type2
        copy8   (ptr1),y, type1

        lda     type2
        cmp     type0
    IF NE
        lda     type1
        cmp     type0
        beq     rtcs

        bne     neither         ; always
    END_IF

        lda     type1
        cmp     type0
        bne     rtcc
        jsr     CompareFileEntryNames
        bcc     rtcc
        bcs     rtcs

neither:
        RETURN  A=#$FF

type2:  .byte   0
type1:  .byte   0

rtcc:   lda     #0
        RETURN  C=0

rtcs:   lda     #0
        RETURN  C=1

type0:  .byte   0
.endproc ; CompareEntryTypesAndNames

;;; ============================================================
;;; Is the file entry a SYS file with .SYSTEM suffix?
;;; Returns carry clear if true, set if false.

.proc CheckSystemFile
        ptr := $00

        ;; Check for SYS
        stax    ptr
        ldy     #FileEntry::file_type
        lda     (ptr),y
        cmp     #FT_SYSTEM
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
    DO
        iny
        inx
        lda     (ptr),y
        cmp     str_system,x
        bne     fail
        cpx     str_system
    WHILE NE

        RETURN  C=0

fail:   RETURN  C=1

str_system:
        PASCAL_STRING ".SYSTEM"
.endproc ; CheckSystemFile

;;; ============================================================
;;; Compare file entry names; carry indicates order

.proc CompareFileEntryNames
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
    IF LT
        sta     len
    END_IF

        ldy     #0
loop:   iny
        lda     (ptr2),y
        cmp     (ptr1),y
        beq     next
        bcc     rtcc
rtcs:   RETURN  C=1

        len := *+1
next:   cpy     #SELF_MODIFIED_BYTE

        bne     loop
        lda     len2
        cmp     len1
        beq     rtcc
        bcs     rtcs
rtcc:   RETURN  C=0

len2:   .byte   0
len1:   .byte   0

.endproc ; CompareFileEntryNames

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
