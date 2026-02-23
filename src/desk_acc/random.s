;;; ============================================================
;;; RANDOM - Desk Accessory
;;;
;;; Launches a random desk accessory in the same folder.
;;; ============================================================

        ;; BUG: Saw an infinite loop (make sense since ticks don't change)


        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_MAIN_SEGMENT

;;; ============================================================

        ;; Path we were launched with, and will launch target with
        dir_path := INVOKER_PREFIX

        ;; Convenient buffer to re-use
        self_filename := INVOKER_FILENAME ; filename buffer

        ;; We're dumb and re-enumerate directory until we get to the
        ;; Nth file, so cap the maximum we'll consider.
        kMaxDAsToConsider = 16  ; must be power of 2
        ASSERT_EQUALS kMaxDAsToConsider & (kMaxDAsToConsider-1), 0

.proc Init
        ;; Use time ticks as randomness - low byte is enough entropy
        jsr     JUMP_TABLE_GET_TICKS ; returns A,X,Y = tick count
        and     #kMaxDAsToConsider - 1
        sta     file_num

        ;; Extract this DA's directory path
        ldx     dir_path
        inx
    DO
        dex
        lda     dir_path,x
    WHILE A <> #'/'
        dex
        txa
        pha                     ; A = new `dir_path` length

        ;; And this DA's file name
        inx
        ldy     #0
    DO
        inx
        iny
        lda     dir_path,x
        jsr     ToUpperCase
        sta     self_filename,y
    WHILE X <> dir_path
        sty     self_filename

        pla                     ; A = new `dir_path` length
        sta     dir_path

        ;; Keep going until we find the Nth candidate
    DO
        CALL    EnumerateDirectory, AX=#callback
        lda     file_num
    WHILE NOT_ZERO

        ;; Append filename to `dir_path`
        ldy     #0
        ldx     dir_path
        inx                     ; past '/'
    DO
        inx
        iny
        copy8   filename,y, dir_path,x
    WHILE Y <> filename
        stx     dir_path

        ;; Inject JT call to stack
        pla
        tax
        pla
        tay

        PUSH_RETURN_ADDRESS JUMP_TABLE_LAUNCH_FILE

        tya
        pha
        txa
        pha

        rts

;;; Called with A,X = `FileEntry`
.proc callback
        entry_ptr := $06

        stax    entry_ptr
        jsr     _IsDAFile
        bcs     continue

        jsr     _IsSelfFile
        bcc     continue

        dec     file_num
        bne     continue

        ;; Found one - stop enumeration
        ASSERT_EQUALS FileEntry::storage_type_name_length, 0
        ASSERT_EQUALS FileEntry::file_name, 1
        ldy     #0
        lda     (entry_ptr),y
        and     #NAME_LENGTH_MASK
        sta     filename
        tay
    DO
        copy8   (entry_ptr),y, filename,y
    WHILE dey : NOT_ZERO

        RETURN  C=1

continue:
        RETURN  C=0


;;; Output: C=0 if DA
.proc _IsDAFile
        ;; Check file type
        ldy     #FileEntry::file_type
        lda     (entry_ptr),y
        cmp     #kDAFileType
        bne     nope

        ;; Check aux type
        ldy     #FileEntry::aux_type
        lda     (entry_ptr),y
        cmp     #<kDAFileAuxType
        bne     nope
        iny
        lda     (entry_ptr),y
        cmp     #>kDAFileAuxType
        bne     nope

        RETURN  C=0

nope:   RETURN  C=1
.endproc ; _IsDAFile

;;; Output: C=0 if is this DA
.proc _IsSelfFile
        ;; Assert: `cur_filename` was up-cased

        ;; Lengths match?
        ldy     #FileEntry::storage_type_name_length
        lda     (entry_ptr),y
        and     #NAME_LENGTH_MASK
        cmp     self_filename
        bne     nope
        tay

        ;; Yes, check characters
        ASSERT_EQUALS FileEntry::file_name, 1
    DO
        lda     (entry_ptr),y
        cmp     self_filename,y
        bne     nope
    WHILE dey : NOT_ZERO

        RETURN  C=0

nope:   RETURN  C=1
.endproc ; _IsSelfFile

.endproc ; callback

file_num:
        .byte   0
filename:
        .res    16

.endproc ; Init


;;; ============================================================

;;; Inputs: A,X = callback, invoked with A,X=`FileEntry`
;;;         `dir_path` populated
;;; Note: Callbacks must not modify $08, but can use $06

.proc EnumerateDirectory

;;; Memory Map
io_buf    := DA_IO_BUFFER              ; $1C00-$1FFF
block_buf := DA_IO_BUFFER - BLOCK_SIZE ; $1A00-$1BFF

kEntriesPerBlock = $0D

        stax    callback

        CLEAR_BIT7_FLAG saw_header_flag

        ;; Open directory
        JUMP_TABLE_MLI_CALL OPEN, open_params
        jcs     exit

        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num

next_block:
        JUMP_TABLE_MLI_CALL READ, read_params
        bcs     close
        copy8   #AS_BYTE(-1), entry_in_block
        entry_ptr := $08
        copy16  #(block_buf+4 - .sizeof(FileEntry)), entry_ptr

next_entry:
        ;; Advance to next entry
        lda     entry_in_block
        cmp     #kEntriesPerBlock
        beq     next_block

        inc     entry_in_block
        add16_8 entry_ptr, #.sizeof(FileEntry)

        ;; Header?
    IF bit saw_header_flag : NC
        SET_BIT7_FLAG saw_header_flag
        bmi     next_entry      ; always
    END_IF

        ;; Active entry?
        ldy     #FileEntry::storage_type_name_length
        lda     (entry_ptr),y
        beq     next_entry

        ;; Invoke callback
        ldax    entry_ptr
        callback := *+1
        jsr     SELF_MODIFIED
        bcc     next_entry

close:  php
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        plp
exit:
        rts

        DEFINE_OPEN_PARAMS open_params, dir_path, io_buf
        DEFINE_READWRITE_PARAMS read_params, block_buf, BLOCK_SIZE
        DEFINE_CLOSE_PARAMS close_params

entry_in_block:
        .byte   0
saw_header_flag:                ; bit7
        .byte   0

.endproc ; EnumerateDirectory

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
