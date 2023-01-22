;;; ============================================================
;;; Utility to find the entry for a file within the containing
;;; directory, providing the block number and offset.
;;;
;;; The intended use is to modify properties of the entry that
;;; GET/SET_FILE_INFO MLI calls can't provide, such as:
;;; * Modifying the `version`/`min_version` bytes, which are
;;;   used by GS/OS to store filename case bits.
;;; * Modifying the `key_pointer` and other sensitive fields,
;;;   e.g. to allow relinking files.
;;;
;;; NOTE: Currently unused, so untested/unmaintained.
;;; ============================================================

;;; Block buffer is right before I/O buffer
kBlockSize = 512
blockbuf := DA_IO_BUFFER - kBlockSize

;;; Use zero page for data to keep code size down.
PARAM_BLOCK params, $06
entry_ptr               .addr
entry_num               .byte   ; entry number in current block
current_block           .word   ; current block number
name_len                .byte
name_ptr                .addr
END_PARAM_BLOCK

kEntriesPerBlock        = $0D

;;; ============================================================

.proc Start
        ;; Stash original path length
        lda     INVOKE_PATH
        pha

        ;; Clear out pointer to next block; used to identify
        ;; the current block.
        ldx     #0
        stx     blockbuf+2
        stx     blockbuf+3

        ;; --------------------------------------------------
        ;; Extract filename
        ldy     INVOKE_PATH
sloop:  lda     INVOKE_PATH,y   ; find last '/'
        cmp     #'/'
        beq     :+
        inx                     ; length of filename
        dey
        bne     sloop
:
        dey                     ; length not including '/'
        bne     :+
        pla                     ; was a volume path
        sec                     ; failure
        rts

:       sty     INVOKE_PATH
        stx     params::name_len

        iny
        tya
        clc
        adc     #<INVOKE_PATH
        sta     params::name_ptr
        lda     #>INVOKE_PATH
        adc     #0
        sta     params::name_ptr+1

        ;; --------------------------------------------------
        ;; Open directory, search blocks for filename

        JUMP_TABLE_MLI_CALL OPEN, open_params
        pla                     ; A = original length
        sta     INVOKE_PATH
        bcs     exit

        lda     open_params_ref_num
        sta     read_params_ref_num
        sta     close_params_ref_num

next_block:
        ;; This is the block we're about to read; save for later.
        copy16  blockbuf+2, params::current_block

        JUMP_TABLE_MLI_CALL READ, read_params
        bcs     close
        copy    #0, params::entry_num
        copy16  #(blockbuf+4 - .sizeof(FileEntry)), params::entry_ptr

next_entry:
        ;; Advance to next entry
        lda     params::entry_num
        cmp     #kEntriesPerBlock
        beq     next_block

        inc     params::entry_num
        add16_8 params::entry_ptr, #.sizeof(FileEntry)

        ;; Valid entry?
        ldy     #FileEntry::storage_type_name_length
        lda     (params::entry_ptr),y
        tax                     ; X = storage_type_name_length
        and     #STORAGE_TYPE_MASK
        beq     next_entry

        ;; Is this the first block? Get block num from entry's pointer.
        lda     params::current_block
        ora     params::current_block+1
        bne     :+
        ldy     #FileEntry::header_pointer
        copy16in (params::entry_ptr),y, params::current_block
:
        ;; See if this is the file we're looking for
        txa                     ; A = storage_type_name_length
        and     #NAME_LENGTH_MASK
        cmp     params::name_len
        bne     next_entry
        tay
        .assert FileEntry::file_name = 1, error, "member offset"
nloop:  lda     (params::name_ptr),y
        cmp     #'a'
        bcc     :+
        and     #CASE_MASK
:       cmp     (params::entry_ptr),y
        bne     next_entry
        dey
        bne     nloop

        ;; Match!
        ;; `current_block` is disk block
        ;; `params::entry_ptr` - `blockbuf` is `FileEntry` offset within block
        ;; `entry_num` is the index (1-based) of entry within block
        ;;
        ;; The `current_block` and `entry_num` fields are needed if
        ;; a subdirectory entry is altered, in order to update the
        ;; subdirectory's key block's `parent_pointer`/`parent_entry_number`

        clc

close:  php
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        plp
exit:   rts

.endproc ; Start

;;; ============================================================
;;; ProDOS MLI param blocks

        DEFINE_OPEN_PARAMS open_params, INVOKE_PATH, DA_IO_BUFFER
        DEFINE_READ_PARAMS read_params, blockbuf, kBlockSize
        DEFINE_CLOSE_PARAMS close_params
        open_params_ref_num := open_params::ref_num
        read_params_ref_num := read_params::ref_num
        close_params_ref_num := close_params::ref_num

;;; ============================================================
