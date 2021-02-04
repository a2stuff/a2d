        .include "../config.inc"
        RESOURCE_FILE "desktop.system.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"

        .include "../common.inc"

;;; ============================================================
;;; Memory map
;;;
;;;              Main
;;;          :             :
;;;          | ProDOS      |
;;;   $BF00  +-------------+
;;;          |             |
;;;          :             :
;;;          |             |
;;;          | Copy Buffer |
;;;   $4000  +-------------+
;;;          |             |
;;;          |             |
;;;          |             |
;;;          | Code        |
;;;   $2000  +-------------+
;;;          |.(unused)....|
;;;   $1E00  +-------------+
;;;          |             |
;;;          | Sel List    |    * holds selector list
;;;   $1600  +-------------+
;;;          |             |
;;;          | Dst IO Buf  |    * writing copied files, DESKTOP.SYSTEM
;;;   $1200  +-------------+
;;;          |             |    * reading copied files, SELECTOR.LIST
;;;          | Src I/O Buf |
;;;    $E00  +-------------+
;;;          | Dir Rd Buf  |    * holds "block" read from directory
;;;    $C00  +-------------+
;;;          |             |
;;;          | Dir I/O Buf |
;;;    $800  +-------------+
;;;          :             :

dir_io_buffer   := $800         ; 1024 bytes for I/O
dir_buffer      := $C00         ; 512 bytes (BLOCK_SIZE)
kDirBufSize     = BLOCK_SIZE

src_io_buffer   := $E00         ; 1024 bytes for I/O
dst_io_buffer   := $1200        ; 1024 bytes for I/O
selector_buffer := $1600        ; Room for kSelectorListBufSize

copy_buffer     := $4000
kCopyBufferSize = MLI - copy_buffer

        .org PRODOS_SYS_START

;;; ============================================================

;;; Execution:
;;; 1. Copy DeskTop Files to RAMCard
;;;   * Init screen, system bitmap
;;;   * Save existing ProDOS Quit handler
;;;   * Search for RAMCard
;;;   * Copy DeskTop Files to RAMCard
;;; 2. Copy Selector Entries to RAMCard
;;; 3. Invoke Selector or DeskTop


;;; ============================================================
;;; First few bytes of file get updated by this and other
;;; executables, so this header format should not change.

        jmp     copy_desktop_to_ramcard

header_date:   .word   0               ; written into file by Date DA
header_orig_prefix:
        .res    64, 0           ; written into file with original path

        kWriteBackSize = * - PRODOS_SYS_START

;;; ============================================================
;;;
;;; Generic recursive file copy routine
;;;
;;; ============================================================

;;; Entry point is generic_copy::do_copy
;;; * Source path is generic_copy::path2
;;; * Destination path is generic_copy::path1
;;; * Callbacks (generic_copy::hook_*) must be populated

.proc generic_copy

;;; ============================================================

;;; Source/Destination paths - caller must initialize these
path1:  .res    ::kPathBufferSize, 0
path2:  .res    ::kPathBufferSize, 0

;;; Callbacks - caller must initialize these
hook_handle_error_code:   .addr   0 ; fatal; A = ProDOS error code
hook_handle_no_space:     .addr   0 ; fatal
hook_insert_source:       .addr   0 ; if this returns, copy is retried
hook_show_file:           .addr   0 ; called when |path2| updated

;;; ============================================================

show_insert_prompt:
        jmp     (hook_insert_source)

show_copying_screen:
        jmp     (hook_show_file)

        DEFINE_GET_FILE_INFO_PARAMS get_path2_info_params, path2
        DEFINE_GET_FILE_INFO_PARAMS get_path1_info_params, path1
        DEFINE_CREATE_PARAMS create_params, path1, 0
        DEFINE_OPEN_PARAMS open_path2_params, path2, dir_io_buffer

        ;; Used for reading directory structure
        DEFINE_READ_PARAMS read_4bytes_params, buf_4_bytes, 4 ; For skipping pref/next pointers in directory data
buf_4_bytes:  .res    4, 0
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_READ_PARAMS read_fileentry_params, filename, 39 ; For reading entry data
        DEFINE_READ_PARAMS read_5bytes_params, buf_5_bytes, 5 ; For skipping over "block" boundaries
buf_5_bytes:  .res    5, 0
        .res    4, 0
        DEFINE_CLOSE_PARAMS close_srcfile_params
        DEFINE_CLOSE_PARAMS close_dstfile_params

        DEFINE_OPEN_PARAMS open_srcfile_params, path2, src_io_buffer
        DEFINE_OPEN_PARAMS open_dstfile_params, path1, dst_io_buffer
        DEFINE_READ_PARAMS read_srcfile_params, copy_buffer, kCopyBufferSize
        DEFINE_WRITE_PARAMS write_dstfile_params, copy_buffer, kCopyBufferSize
        DEFINE_CREATE_PARAMS create_dir_params, path1, ACCESS_DEFAULT

file_entry:
filename:
        .res    48, 0           ; big enough for FileEntry

;;; ============================================================
;;; Perform the file copy.
;;; Inputs: |path2| is source path
;;;         |path1| is destination path
.proc do_copy
        ;; Check destination dir
        MLI_CALL GET_FILE_INFO, get_path1_info_params
        cmp     #ERR_FILE_NOT_FOUND
        beq     okerr
        cmp     #ERR_VOL_NOT_FOUND
        beq     okerr
        cmp     #ERR_PATH_NOT_FOUND
        beq     okerr
        rts                     ; Otherwise, fail the copy

        ;; Get source dir info
okerr:  MLI_CALL GET_FILE_INFO, get_path2_info_params
        beq     gfi_ok
        cmp     #ERR_VOL_NOT_FOUND
        beq     prompt
        cmp     #ERR_FILE_NOT_FOUND
        bne     fail

prompt: jsr     show_insert_prompt
        jmp     okerr

fail:   jmp     (hook_handle_error_code)

        ;; Prepare for copy...
gfi_ok: lda     get_path2_info_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        lda     #0
        beq     :+
is_dir: lda     #$FF
:       sta     is_dir_flag

        ;; copy file_type, aux_type, storage_type
        ldy     #7
:       lda     get_path2_info_params,y
        sta     create_params,y
        dey
        cpy     #3
        bne     :-
        lda     #ACCESS_DEFAULT
        sta     create_params::access
        jsr     check_space_available
        bcc     :+
        jmp     (hook_handle_no_space)

        ;; copy dates
:       COPY_STRUCT DateTime, get_path2_info_params::create_date, create_params::create_date

        ;; create the file
        lda     create_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY ; if it was a volume dir, make sure we create a subdir
        bne     :+                   ; (if it was not a directory, just keep the type)
        lda     #ST_LINKED_DIRECTORY
        sta     create_params::storage_type
:       MLI_CALL CREATE, create_params
        beq     :+
        jmp     (hook_handle_error_code)

:       lda     is_dir_flag
        beq     :+
        jmp     copy_directory
:       jmp     copy_normal_file

is_dir_flag:
        .byte   0
.endproc

;;; ============================================================
;;; Copy an entry in a directory. For files, the content is copied.
;;; For directories, the target is created but the caller is responsible
;;; for copying the child entries.
;;; Inputs: |file_entry| populated with FileEntry
;;;         |path2| has source directory path
;;;         |path1| has destination directory path
;;; Errors: handle_error_code is invoked

.proc copy_entry
        lda     file_entry + FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     do_file

        ;; --------------------------------------------------
        ;; Directory
        jsr     append_filename_to_path2
        jsr     show_copying_screen
        MLI_CALL GET_FILE_INFO, get_path2_info_params
        beq     ok
        jmp     (hook_handle_error_code)

onerr:  jsr     remove_filename_from_path1
        jsr     remove_filename_from_path2
        lda     #$FF
        sta     copy_err_flag
        jmp     exit

ok:     jsr     append_filename_to_path1
        jsr     create_dir
        bcs     onerr
        jsr     remove_filename_from_path2
        jmp     exit

        ;; --------------------------------------------------
        ;; File
do_file:
        jsr     append_filename_to_path1
        jsr     append_filename_to_path2
        jsr     show_copying_screen
        MLI_CALL GET_FILE_INFO, get_path2_info_params
        beq     :+
        jmp     (hook_handle_error_code)

:       jsr     check_space_available
        bcc     :+
        jmp     (hook_handle_no_space)

        ;; Create parent dir if necessary
:       jsr     remove_filename_from_path2
        jsr     create_dir
        bcs     cleanup
        jsr     append_filename_to_path2

        ;; Do the copy
        jsr     copy_normal_file
        jsr     remove_filename_from_path2
        jsr     remove_filename_from_path1

exit:   rts

cleanup:
        jsr     remove_filename_from_path1
        rts
.endproc

;;; ============================================================
;;; Check that there is room to copy a file. Handles overwrites.
;;; Inputs: |path2| is source; |path1| is target
;;; Outputs: C=0 if there is sufficient space, C=1 otherwise

.proc check_space_available

        ;; --------------------------------------------------
        ;; Get source size

        MLI_CALL GET_FILE_INFO, get_path2_info_params
        beq     :+
        jmp     (hook_handle_error_code)

        ;; --------------------------------------------------
        ;; Get destination size (in case of overwrite)

:       lda     #0
        sta     dst_size        ; default 0, if it doesn't exist
        sta     dst_size+1
        MLI_CALL GET_FILE_INFO, get_path1_info_params
        beq     :+
        cmp     #ERR_FILE_NOT_FOUND
        beq     got_dst_size    ; this is fine
        jmp     (hook_handle_error_code)
:       copy16  get_path1_info_params::blocks_used, dst_size
got_dst_size:

        ;; --------------------------------------------------
        ;; Get destination volume free space

        ;; Isolate destination volume name
        lda     path1
        sta     path1_length    ; save

        ldy     #1
:       iny
        cpy     path1
        bcs     have_space
        lda     path1,y
        cmp     #'/'
        bne     :-
        tya
        sta     path1

        ;; Get volume info
        MLI_CALL GET_FILE_INFO, get_path1_info_params
        beq     :+
        jmp     (hook_handle_error_code)

        ;; Free = Total - Used
:       sub16   get_path1_info_params::aux_type, get_path1_info_params::blocks_used, vol_free
        ;; Take away size to overwrite - BUG: Shouldn't this be add, not subtract???
        sub16   vol_free, dst_size, vol_free
        ;; Does it fit? (free >= needed)
        cmp16   vol_free, get_path2_info_params::blocks_used
        bcs     have_space

        sec                     ; no space
        bcs     :+              ; always

have_space:
        clc
:       lda     path1_length    ; restore
        sta     path1
        rts

vol_free:       .word   0
path1_length:   .byte   0       ; save full length of path
dst_size:       .word   0
.endproc


;;; ============================================================
;;; Copy a normal (non-directory) file. File info is copied too.
;;; Inputs: |open_srcfile_params| populated
;;;         |open_dstfile_params| populated; file already created
;;; Errors: handle_error_code is invoked

.proc copy_normal_file
        ;; Open source
        MLI_CALL OPEN, open_srcfile_params
        beq     :+
        jmp     (hook_handle_error_code)

        ;; Open destination
:       MLI_CALL OPEN, open_dstfile_params
        beq     :+
        jmp     (hook_handle_error_code)

:       lda     open_srcfile_params::ref_num
        sta     read_srcfile_params::ref_num
        sta     close_srcfile_params::ref_num
        lda     open_dstfile_params::ref_num
        sta     write_dstfile_params::ref_num
        sta     close_dstfile_params::ref_num

        ;; Read a chunk
loop:   copy16  #kCopyBufferSize, read_srcfile_params::request_count
        MLI_CALL READ, read_srcfile_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     close
        jmp     (hook_handle_error_code)

        ;; Write the chunk
:       copy16  read_srcfile_params::trans_count, write_dstfile_params::request_count
        ora     read_srcfile_params::trans_count
        beq     close
        MLI_CALL WRITE, write_dstfile_params
        beq     :+
        jmp     (hook_handle_error_code)

        ;; More to copy?
:       lda     write_dstfile_params::trans_count
        cmp     #<kCopyBufferSize
        bne     close
        lda     write_dstfile_params::trans_count+1
        cmp     #>kCopyBufferSize
        beq     loop

        ;; Close source and destination
close:  MLI_CALL CLOSE, close_dstfile_params
        MLI_CALL CLOSE, close_srcfile_params

        ;; Copy file info
        MLI_CALL GET_FILE_INFO, get_path2_info_params
        beq     :+
        jmp     (hook_handle_error_code)
:       COPY_BYTES $B, get_path2_info_params::access, get_path1_info_params::access

        copy    #7, get_path1_info_params ; SET_FILE_INFO param_count
        MLI_CALL SET_FILE_INFO, get_path1_info_params
        copy    #10, get_path1_info_params ; GET_FILE_INFO param_count

        rts
.endproc

;;; ============================================================

.proc create_dir
        ;; Copy file_type, aux_type, storage_type
        ldx     #7
:       lda     get_path2_info_params,x
        sta     create_dir_params,x
        dex
        cpx     #3
        bne     :-
        lda     #ACCESS_DEFAULT
        sta     create_dir_params::access

        ;; Copy dates
        COPY_STRUCT DateTime, get_path2_info_params::create_date, create_dir_params::create_date

        ;; Create it
        lda     create_dir_params::storage_type
        cmp     #ST_VOLUME_DIRECTORY
        bne     :+
        lda     #ST_LINKED_DIRECTORY
        sta     create_dir_params::storage_type
:       MLI_CALL CREATE, create_dir_params
        clc
        beq     :+
        jmp     (hook_handle_error_code)
:       rts
.endproc

recursion_depth:        .byte   0 ; How far down the directory structure are we

entries_per_block:      .byte   13 ; TODO: Read this from directory header
entry_index_in_dir:     .byte   0
ref_num:                .byte   0
target_index:           .byte   0

;;; Stack used when descending directories; keeps track of entry index within
;;; directories.
index_stack:    .res    170, 0
stack_index:    .byte   0

entry_index_in_block:   .byte   0


;;; ============================================================

.proc push_index_to_stack
        ldx     stack_index
        lda     target_index
        sta     index_stack,x
        inx
        stx     stack_index
        rts
.endproc

;;; ============================================================

.proc pop_index_from_stack
        ldx     stack_index
        dex
        lda     index_stack,x
        sta     target_index
        stx     stack_index
        rts
.endproc

;;; ============================================================
;;; Open the source directory for reading, skipping header.
;;; Inputs: path2 set to dir
;;; Outputs: ref_num

.proc open_src_dir
        lda     #0
        sta     entry_index_in_dir
        sta     entry_index_in_block
        MLI_CALL OPEN, open_path2_params
        beq     :+
        jmp     (hook_handle_error_code)

        ;; Skip over prev/next block pointers
:       lda     open_path2_params::ref_num
        sta     ref_num
        sta     read_4bytes_params::ref_num
        MLI_CALL READ, read_4bytes_params
        beq     :+
        jmp     (hook_handle_error_code)

        ;; Header size is next/prev blocks + a file entry
        .assert .sizeof(SubdirectoryHeader) = .sizeof(FileEntry) + 4, error, "incorrect struct size"
:       jsr     read_file_entry
        rts
.endproc

;;; ============================================================

.proc do_close_file
        lda     ref_num
        sta     close_params::ref_num
        MLI_CALL CLOSE, close_params
        beq     :+
        jmp     (hook_handle_error_code)
:       rts
.endproc

;;; ============================================================

.proc read_file_entry
        inc     entry_index_in_dir

        ;; Skip entry
        lda     ref_num
        sta     read_fileentry_params::ref_num
        MLI_CALL READ, read_fileentry_params
        beq     :+
        jmp     (hook_handle_error_code)
:       inc     entry_index_in_block
        lda     entry_index_in_block
        cmp     entries_per_block
        bcc     done

        ;; Advance to first entry in next "block"
        lda     #0
        sta     entry_index_in_block
        lda     ref_num
        sta     read_5bytes_params::ref_num
        MLI_CALL READ, read_5bytes_params
        beq     :+
        jmp     (hook_handle_error_code)
:       lda     read_5bytes_params::trans_count
        cmp     read_5bytes_params::request_count
        rts

done:   return  #0
.endproc

;;; ============================================================

.proc descend_directory
        lda     entry_index_in_dir
        sta     target_index
        jsr     do_close_file
        jsr     push_index_to_stack
        jsr     append_filename_to_path2
        jsr     open_src_dir
        rts
.endproc

.proc ascend_directory
        jsr     do_close_file
        jsr     remove_filename_from_path2
        jsr     pop_index_from_stack
        jsr     open_src_dir
        jsr     advance_to_target_entry
        jsr     remove_filename_from_path1
        rts
.endproc

.proc advance_to_target_entry
:       lda     entry_index_in_dir
        cmp     target_index
        beq     :+
        jsr     read_file_entry
        jmp     :-
:       rts
.endproc

;;; ============================================================
;;; Recursively copy
;;; Inputs: path2 points at source directory

.proc copy_directory
        lda     #0
        sta     recursion_depth
        jsr     open_src_dir

loop:   jsr     read_file_entry
        bne     next

        lda     file_entry + FileEntry::storage_type_name_length
        beq     loop            ; deleted

        lda     file_entry + FileEntry::storage_type_name_length
        and     #$0F            ; mask off name_length
        sta     filename

        lda     #0
        sta     copy_err_flag

        jsr     copy_entry

        lda     copy_err_flag   ; don't recurse if the copy failed
        bne     loop
        lda     file_entry + FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     loop            ; and don't recurse unless it's a directory

        ;; Recurse into child directory
        jsr     descend_directory
        inc     recursion_depth
        jmp     loop

next:   lda     recursion_depth
        beq     done
        jsr     ascend_directory
        dec     recursion_depth
        jmp     loop

done:   jsr     do_close_file
        rts
.endproc

;;; ============================================================

        ;; Set on error during copying of a single file
copy_err_flag:
        .byte   0


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

.endproc

;;; ============================================================
;;;
;;; Part 1: Copy DeskTop Files to RAMCard
;;;
;;; ============================================================

.proc copy_desktop_to_ramcard_impl

;;; ============================================================
;;; Data buffers and param blocks

        ;; Used in check_desktop2_on_device
        path_buf := $D00
        DEFINE_GET_PREFIX_PARAMS get_prefix_params2, path_buf
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params4, path_buf

unit_num:
        .byte   0

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer
on_line_buffer: .res 17, 0

copied_flag:                    ; set to dst_path's length, or reset
        .byte   0

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, src_path
        DEFINE_SET_PREFIX_PARAMS set_prefix_params, dst_path

        DEFINE_CREATE_PARAMS create_dt_dir_params, dst_path, ACCESS_DEFAULT, FT_DIRECTORY, 0, ST_LINKED_DIRECTORY
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, src_path

kNumFilenames = 10

        ;; Files/Directories to copy
str_f1: PASCAL_STRING "DESKTOP.SYSTEM" ; do not localize
str_f2: PASCAL_STRING "DESKTOP2"       ; do not localize
str_f3: PASCAL_STRING "DESK.ACC"       ; do not localize
str_f4: PASCAL_STRING "PREVIEW"        ; do not localize
str_f5: PASCAL_STRING "SELECTOR.LIST"  ; do not localize
str_f6: PASCAL_STRING "SELECTOR"       ; do not localize
str_f7: PASCAL_STRING "PRODOS"         ; do not localize
str_f8: PASCAL_STRING "Quit.tmp"       ; do not localize
str_f9: PASCAL_STRING "DeskTop.config" ; do not localize
str_f10:PASCAL_STRING "DeskTop.file"   ; do not localize

filename_table:
        .addr str_f1,str_f2,str_f3,str_f4,str_f5,str_f6,str_f7,str_f8,str_f9,str_f10
        ASSERT_ADDRESS_TABLE_SIZE filename_table, kNumFilenames

        kVtabCopyingMsg = 12
str_copying_to_ramcard:
        PASCAL_STRING .sprintf(res_string_copying_to_ramcard, kDeskTopProductName)

        kVtabCopyingTip = 23
str_tip_skip_copying:
        PASCAL_STRING res_string_label_tip_skip_copying

;;; Signature of block storage devices ($Cn0x)
kNumSigBytes = 4
sig_bytes:
        .byte   $20,$00,$03,$00
        ASSERT_TABLE_SIZE sig_bytes, kNumSigBytes
sig_offsets:
        .byte   $01,$03,$05,$07
        ASSERT_TABLE_SIZE sig_offsets, kNumSigBytes

active_device:
        .byte   0

        ;; Selector signature (65816 opcodes used)
selector_signature:
        .byte   $AD,$8B,$C0,$18,$FB,$5C,$04,$D0,$E0

;;; Save stack to restore on error during copy.
saved_stack:
        .byte   0

;;; Holds the destination path, e.g. "/RAM/DESKTOP"
dst_path:  .res    ::kPathBufferSize, 0

;;; Holds the source path, e.g. "/HD/A2D"
src_path: .res    ::kPathBufferSize, 0

;;; Current file being copied
filename_buf:
        .res 16, 0

filenum:
        .byte   0               ; index of file being copied

        DEFINE_WRITE_BLOCK_PARAMS write_block_params, prodos_loader_blocks, 0
        DEFINE_WRITE_BLOCK_PARAMS write_block2_params, prodos_loader_blocks + BLOCK_SIZE, 1

str_slash_desktop:
        PASCAL_STRING "/DeskTop" ; do not localize

;;; ============================================================

.proc start
        sta     MIXCLR
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
        copy16  header_date, DATELO ; Copy timestamp embedded in this file
:       lda     MACHID
        and     #$30            ; bits 4,5 set = 128k
        cmp     #$30
        beq     have128k

        ;;  If not 128k machine, just quit back to ProDOS
        MLI_CALL QUIT, quit_params
        DEFINE_QUIT_PARAMS quit_params

have128k:
        ;; Turn on 80-column mode
        jsr     SLOT3ENTRY
        jsr     HOME

        ;; Save original Quit routine and small loader
        ;; TODO: Assumes prefix is retained. Compose correct path.

        jsr     preserve_quit_code

resume:
        ;; IIgs: Reset shadowing
        sec
        jsr     IDROUTINE
        bcs     :+
        copy    #0, SHADOW
:

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

match:  sta     $D3AC           ; ??? Last entry in ENTRY_COPIED_FLAGS ?

        lda     ROMIN2

        ;; Clear flag - ramcard not found or unknown state.
        ldx     #0
        jsr     set_copied_to_ramcard_flag

        ;; Skip RAMCard install if button is down
        lda     BUTN0
        ora     BUTN1
        bpl     scan_slots
        jmp     did_not_copy

        ;; Start at $C100
        slot_ptr = $8

scan_slots:
        lda     #0
        sta     slot_ptr
        lda     #$C1
        sta     slot_ptr+1

        ;; Check slot for signature bytes
check_slot:
        ldx     #0
:       lda     sig_offsets,x   ; Check $CnXX
        tay
        lda     (slot_ptr),y
        cmp     sig_bytes,x
        bne     next_slot
        inx
        cpx     #kNumSigBytes
        bcc     :-

        ldy     #$FB
        lda     (slot_ptr),y         ; Also check $CnFB for low bit (=RAMDisk)
        and     #$01
        beq     next_slot
        bne     found_slot

next_slot:
        inc     slot_ptr+1
        lda     slot_ptr+1
        cmp     #$C8            ; stop at $C800
        bcc     check_slot

        ;; Did not find signature in any slot - look for
        ;; RAM.DRV.SYSTEM signature in DEVLST.
        ldy     DEVCNT
:       lda     DEVLST,y
        cmp     #kRamDrvSystemUnitNum
        beq     :+
        dey
        bpl     :-
        jmp     did_not_copy

:       lda     #$03
        bne     :+              ; always

        ;; RAM device was found!
found_slot:
        lda     slot_ptr+1
        and     #$0F            ; slot # in A

        ;; Synthesize unit_num, verify it's a device
:       asl     a
        asl     a
        asl     a
        asl     a
        sta     on_line_params::unit_num
        sta     unit_num
        MLI_CALL ON_LINE, on_line_params
        beq     :+
        jmp     did_not_copy

:       lda     unit_num
        cmp     #$30            ; make sure it's not slot 3 (aux)
        beq     :+
        sta     write_block_params::unit_num ; Init device as ProDOS
        sta     write_block2_params::unit_num
        MLI_CALL WRITE_BLOCK, write_block_params
        bne     :+
        MLI_CALL WRITE_BLOCK, write_block2_params
:       lda     on_line_buffer
        and     #$0F
        tay

        iny
        sty     dst_path
        lda     #'/'
        sta     on_line_buffer
        sta     dst_path+1
:       lda     on_line_buffer,y
        sta     dst_path+1,y
        dey
        bne     :-

        ;; Record that candidate device is found.
        ldx     #$C0
        jsr     set_copied_to_ramcard_flag

        ;; Already installed?
        param_call set_ramcard_prefix, dst_path
        jsr     check_desktop2_on_device
        bcs     start_copy      ; No, start copy.

        ;; Already copied - record that it was installed and grab path.
        ldx     #$80
        jsr     set_copied_to_ramcard_flag
        jsr     copy_orig_prefix_to_desktop_orig_prefix
        jmp     did_not_copy
.endproc

.proc start_copy
        ptr := $06

        jsr     show_copying_screen
        MLI_CALL GET_PREFIX, get_prefix_params
        beq     :+
        jmp     did_not_copy
:       dec     src_path

        ;; Record that the copy was performed.
        ldx     #$80
        jsr     set_copied_to_ramcard_flag

        ldy     src_path
:       lda     src_path,y
        sta     header_orig_prefix,y
        dey
        bpl     :-

        ;; --------------------------------------------------
        ;; Create desktop directory, e.g. "/RAM/DESKTOP"
        ldy     dst_path
        ldx     #0
:       iny
        inx
        lda     str_slash_desktop,x
        sta     dst_path,y
        cpx     str_slash_desktop
        bne     :-
        sty     dst_path

        MLI_CALL CREATE, create_dt_dir_params
        beq     :+
        cmp     #ERR_DUPLICATE_FILENAME
        beq     :+
        jsr     did_not_copy
:

        ;; --------------------------------------------------
        ;; Loop over listed files to copy

        tsx                     ; In case of error
        stx     saved_stack

        copy    dst_path, copied_flag ; reset on error
        copy    #0, filenum

file_loop:
        jsr     update_progress

        lda     filenum
        asl     a
        tax
        copy16  filename_table,x, ptr
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     filename_buf,y
        dey
        bpl     :-
        jsr     copy_file
        inc     filenum
        lda     filenum
        cmp     #kNumFilenames
        bne     file_loop

        jsr     update_progress
        ;; fall through
.endproc

.proc finish_dt_copy
        lda     copied_flag
        beq     :+
        sta     dst_path
        MLI_CALL SET_PREFIX, set_prefix_params
:       jsr     update_self_file
        jsr     copy_orig_prefix_to_desktop_orig_prefix

        lda     #0
        sta     RAMWORKS_BANK   ; Just in case?
        ldy     #BITMAP_SIZE-1
:       sta     BITMAP,y
        dey
        bpl     :-

        ;; Done! Move on to Part 2.
        jmp     copy_selector_entries_to_ramcard
.endproc

;;; ============================================================

.proc did_not_copy
        copy    #0, copied_flag
        jmp     finish_dt_copy
.endproc

;;; ============================================================

.proc set_copied_to_ramcard_flag
        lda     LCBANK2
        lda     LCBANK2
        stx     COPIED_TO_RAMCARD_FLAG
        lda     ROMIN2
        rts
.endproc

.proc set_ramcard_prefix
        ptr := $6
        target := RAMCARD_PREFIX

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

.proc set_desktop_orig_prefix
        ptr := $6
        target := DESKTOP_ORIG_PREFIX

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

;;; ============================================================

.proc update_progress

        kProgressVtab = 14
        kProgressStops = kNumFilenames + 1
        kProgressTick = 40 / kProgressStops
        kProgressHtab = (80 - (kProgressTick * kProgressStops)) / 2

        lda     #kProgressVtab
        jsr     VTABZ
        lda     #kProgressHtab
        sta     CH

        lda     count
        clc
        adc     #kProgressTick
        sta     count

        tax
        lda     #' '
:       jsr     COUT
        dex
        bne     :-

        rts

count:  .byte   0
.endproc

;;; ============================================================

.proc append_filename_to_src_path
        lda     filename_buf
        bne     :+
        rts

:       ldx     #0
        ldy     src_path
        lda     #'/'
        sta     src_path+1,y
        iny
loop:   cpx     filename_buf
        bcs     done
        lda     filename_buf+1,x
        sta     src_path+1,y
        inx
        iny
        jmp     loop

done:   sty     src_path
        rts
.endproc

;;; ============================================================

.proc remove_filename_from_src_path
        ldx     src_path
        bne     :+
        rts

:       lda     src_path,x
        cmp     #'/'
        beq     done
        dex
        bne     :-
        stx     src_path
        rts

done:   dex
        stx     src_path
        rts
.endproc

;;; ============================================================

.proc append_filename_to_dst_path
        lda     filename_buf
        bne     :+
        rts

:       ldx     #0
        ldy     dst_path
        lda     #'/'
        sta     dst_path+1,y
        iny
loop:   cpx     filename_buf
        bcs     done
        lda     filename_buf+1,x
        sta     dst_path+1,y
        inx
        iny
        jmp     loop

done:   sty     dst_path
        rts
.endproc

;;; ============================================================

.proc remove_filename_from_dst_path
        ldx     dst_path
        bne     :+
        rts

:       lda     dst_path,x
        cmp     #'/'
        beq     done
        dex
        bne     :-
        stx     dst_path
        rts

done:   dex
        stx     dst_path
        rts
.endproc

;;; ============================================================

.proc show_copying_screen
        ;; Center string
        lda     #80
        sec
        sbc     str_copying_to_ramcard
        lsr     a               ; / 2 to center
        sta     CH
        lda     #kVtabCopyingMsg
        jsr     VTABZ
        ldy     #0
:       iny
        lda     str_copying_to_ramcard,y
        ora     #$80
        jsr     COUT
        cpy     str_copying_to_ramcard
        bne     :-

        ;; Center string
        lda     #80
        sec
        sbc     str_tip_skip_copying
        clc
        adc     #4              ; 4 control characters (for MouseText)
        lsr     a               ; / 2 to center
        sta     CH
        lda     #kVtabCopyingTip
        jsr     VTABZ
        ldy     #0
:       iny
        lda     str_tip_skip_copying,y
        ora     #$80
        jsr     COUT
        cpy     str_tip_skip_copying
        bne     :-

        rts
.endproc

;;; ============================================================
;;; Callback from copy failure; restores stack and proceeds.

.proc fail_copy
        ldx     saved_stack
        txs

        jmp     did_not_copy
.endproc

;;; ============================================================
;;; Copy |filename| from |src_path| to |dst_path|

.proc copy_file
        jsr     append_filename_to_dst_path
        jsr     append_filename_to_src_path
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        cmp     #ERR_FILE_NOT_FOUND
        beq     cleanup
        jmp     did_not_copy
:

        ;; Set up source path
        ldy     src_path
:       lda     src_path,y
        sta     generic_copy::path2,y
        dey
        bpl     :-

        ;; Set up destination path
        ldy     dst_path
:       lda     dst_path,y
        sta     generic_copy::path1,y
        dey
        bpl     :-

        copy16  #fail_copy, generic_copy::hook_handle_error_code
        copy16  #fail_copy, generic_copy::hook_handle_no_space
        copy16  #fail_copy, generic_copy::hook_insert_source
        copy16  #noop, generic_copy::hook_show_file

        jsr     generic_copy::do_copy

cleanup:
        jsr     remove_filename_from_src_path
        jsr     remove_filename_from_dst_path

noop:
done:   rts
.endproc

;;; ============================================================

.proc check_desktop2_on_device
        slot_ptr = $8

        lda     active_device
        cmp     #kRamDrvSystemUnitNum
        bne     :+
        jmp     next

        ;; Check slot for signature bytes
:       and     #$70            ; Compute $Cn00
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$C0
        sta     slot_ptr+1
        lda     #0
        sta     slot_ptr
        ldx     #0              ; Compare signature bytes
bloop:  lda     sig_offsets,x
        tay
        lda     (slot_ptr),y
        cmp     sig_bytes,x
        bne     error
        inx
        cpx     #4              ; Number of signature bytes
        bcc     bloop
        ldy     #$FB            ; Also check $CnFB
        lda     (slot_ptr),y
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
        PASCAL_STRING "DeskTop2" ; do not localize
.endproc

;;; ============================================================
;;; Update the live (RAM or disk) copy of this file with the
;;; original prefix.

.proc update_self_file_impl
        dt1_addr := $2000

        DEFINE_OPEN_PARAMS open_params, str_desktop1_path, dst_io_buffer
str_desktop1_path:
        PASCAL_STRING "DeskTop/DESKTOP.SYSTEM" ; do not localize
        DEFINE_WRITE_PARAMS write_params, dt1_addr, kWriteBackSize
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
        update_self_file := update_self_file_impl::start

;;; ============================================================

.proc copy_orig_prefix_to_desktop_orig_prefix
        param_call set_desktop_orig_prefix, header_orig_prefix
        rts
.endproc



;;; ============================================================

prodos_loader_blocks:
        .incbin "../inc/pdload.dat"

.endproc ; copy_desktop_to_ramcard_impl

copy_desktop_to_ramcard := copy_desktop_to_ramcard_impl::start


;;; ============================================================
;;;
;;; Part 2: Copy Selector Entries to RAMCard
;;;
;;; ============================================================

.proc copy_selector_entries_to_ramcard


;;; See docs/Selector_List_Format.md for file format

.proc process_selector_list
        ptr := $6

        ;; Clear screen
        jsr     SLOT3ENTRY
        jsr     HOME

        ;; Is there a RAMCard?
        lda     LCBANK2
        lda     LCBANK2
        lda     COPIED_TO_RAMCARD_FLAG
        pha
        lda     ROMIN2
        pla
        bne     :+
        jmp     invoke_selector_or_desktop ; no RAMCard - skip!

        ;; Clear "Copied to RAMCard" flags
:       lda     LCBANK2
        lda     LCBANK2
        ldx     #kSelectorListNumEntries-1
        lda     #0
:       sta     ENTRY_COPIED_FLAGS,x
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
        cmp     selector_buffer + kSelectorListNumRunListOffset
        beq     done_entries
        jsr     compute_label_addr
        stax    ptr

        ldy     #kSelectorEntryFlagsOffset ; Check Copy-to-RamCARD flags
        lda     (ptr),y
        bne     next_entry      ; not "On first use"
        lda     entry_num
        jsr     compute_path_addr

        jsr     prepare_entry_paths
        jsr     copy_using_entry_paths

        lda     LCBANK2         ; Mark copied
        lda     LCBANK2
        ldx     entry_num
        lda     #$FF
        sta     ENTRY_COPIED_FLAGS,x
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
        cmp     selector_buffer + kSelectorListNumOtherListOffset
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

        jsr     prepare_entry_paths
        jsr     copy_using_entry_paths

        lda     LCBANK2
        lda     LCBANK2
        lda     entry_num
        clc
        adc     #8
        tax
        lda     #$FF
        sta     ENTRY_COPIED_FLAGS,x
        lda     ROMIN2
next_entry2:
        inc     entry_num
        jmp     entry_loop2

bail:   jmp     invoke_selector_or_desktop

entry_num:
        .byte   0
.endproc

;;; ============================================================


entry_path1:  .res    ::kSelectorListPathLength, 0
entry_path2:  .res    ::kSelectorListPathLength, 0
entry_dir_name:
        .res    16, 0  ; e.g. "APPLEWORKS" from ".../APPLEWORKS/AW.SYSTEM"


;;; ============================================================

.proc copy_using_entry_paths
        jsr     prepare_paths_from_entry_paths

        ;; Set up destination dir path, e.g. "/RAM/APPLEWORKS"
        ldx     generic_copy::path1           ; Append '/' to path1
        lda     #'/'
        sta     generic_copy::path1+1,x
        inc     generic_copy::path1

        ldy     #0              ; Append entry_dir_name to path1
        ldx     generic_copy::path1
:       iny
        inx
        lda     entry_dir_name,y
        sta     generic_copy::path1,x
        cpy     entry_dir_name
        bne     :-
        stx     generic_copy::path1

        ;; Install callbacks and invoke
        copy16  #handle_error_code, generic_copy::hook_handle_error_code
        copy16  #show_no_space_prompt, generic_copy::hook_handle_no_space
        copy16  #show_insert_prompt, generic_copy::hook_insert_source
        copy16  #show_copying_screen, generic_copy::hook_show_file
        jmp     generic_copy::do_copy
.endproc

;;; ============================================================
;;; Copy entry_path1/2 to path1/2

.proc prepare_paths_from_entry_paths
        ldy     #$FF

        ;; Copy entry_path2 to path2
loop:   iny
        lda     entry_path2,y
        sta     generic_copy::path2,y
        cpy     entry_path2
        bne     loop

        ;; Copy entry_path1 to path1
        ldy     entry_path1
loop2:  lda     entry_path1,y
        sta     generic_copy::path1,y
        dey
        bpl     loop2

        rts
.endproc


;;; ============================================================
;;; Compute first offset into selector file - A*16 + 2

.proc compute_label_addr
        addr := selector_buffer + kSelectorListEntriesOffset

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
        addr := selector_buffer + kSelectorListPathsOffset

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

.proc read_selector_list_impl
        DEFINE_OPEN_PARAMS open_params, str_selector_list, src_io_buffer
str_selector_list:
        PASCAL_STRING "Selector.List" ; do not localize
        DEFINE_READ_PARAMS read_params, selector_buffer, kSelectorListBufSize
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
;;; Prepare entry paths
;;; Input: A,X = address of full entry path
;;;            e.g. ".../APPLEWORKS/AW.SYSTEM"
;;; Output: entry_path2 set to path of entry parent dir
;;;            e.g. ".../APPLEWORKS"
;;;         entry_dir_name set to name of entry parent dir
;;;            e.g. "APPLEWORKS"
;;;         entry_path1 set to RAMCARD_PREFIX
;;;            e.g. "/RAM"
;;; Trashes $06

.proc prepare_entry_paths
        ptr := $6

        stax    ptr

        ;; Copy passed address to entry_path2
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     entry_path2,y
        dey
        bpl     :-

        ;; Strip last segment, e.g. ".../APPLEWORKS/AW.SYSTEM" -> ".../APPLEWORKS"
        ldy     entry_path2
:       lda     entry_path2,y
        and     #CHAR_MASK
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       dey
        sty     entry_path2

        ;; Find offset of parent directory name, e.g. "APPLEWORKS"
:       lda     entry_path2,y
        and     #CHAR_MASK
        cmp     #'/'
        beq     :+
        dey
        bpl     :-

        ;; ... and copy to entry_dir_name
:       ldx     #0
:       iny
        inx
        lda     entry_path2,y
        sta     entry_dir_name,x
        cpy     entry_path2
        bne     :-
        stx     entry_dir_name

        ;; Prep entry_path1 with RAMCARD_PREFIX
        lda     LCBANK2
        lda     LCBANK2
        ldy     RAMCARD_PREFIX
:       lda     RAMCARD_PREFIX,y
        sta     entry_path1,y
        dey
        bpl     :-
        lda     ROMIN2

        rts
.endproc

;;; ============================================================

str_copying:
        PASCAL_STRING res_string_label_copying

str_insert:
        PASCAL_STRING res_string_prompt_insert_source

str_not_enough:
        PASCAL_STRING res_string_prompt_ramcard_full

str_error:
        PASCAL_STRING res_string_error_prefix

str_occured:
        PASCAL_STRING res_string_error_suffix

str_not_completed:
        PASCAL_STRING res_string_prompt_copy_not_completed

;;; ============================================================

;;; Callback; used for generic_copy::hook_show_file
.proc show_copying_screen
        jsr     HOME
        lda     #0
        jsr     VTABZ
        lda     #0
        sta     CH
        param_call cout_string, str_copying
        param_call cout_string_newline, generic_copy::path2
        rts
.endproc

;;; ============================================================

;;; Callback; used for generic_copy::hook_insert_source
.proc show_insert_prompt
        lda     #0
        jsr     VTABZ
        lda     #0
        sta     CH
        param_call cout_string, str_insert
        jsr     wait_enter_escape
        cmp     #CHAR_ESCAPE
        bne     :+
        jmp     finish_and_invoke

:       jsr     HOME
        rts
.endproc

;;; ============================================================

;;; Callback; used for generic_copy::hook_handle_no_space
.proc show_no_space_prompt
        ;; TODO: Reset stack?

        lda     #0
        jsr     VTABZ
        lda     #0
        sta     CH
        param_call cout_string, str_not_enough
        jsr     wait_enter_escape
        jsr     HOME
        jmp     invoke_selector_or_desktop
.endproc

;;; ============================================================
;;; On copy failure, show an appropriate error; wait for key
;;; and invoke app.

;;; Callback; used for generic_copy::hook_handle_error_code
.proc handle_error_code
        ;; TODO: Reset stack?

        cmp     #ERR_OVERRUN_ERROR
        bne     :+
        jsr     show_no_space_prompt
        jmp     finish_and_invoke

:       cmp     #ERR_VOLUME_DIR_FULL
        bne     :+
        jsr     show_no_space_prompt
        jmp     finish_and_invoke

        ;; Show generic error
:       pha
        param_call cout_string, str_error
        pla
        jsr     PRBYTE
        param_call cout_string, str_occured
        param_call cout_string_newline, generic_copy::path2
        param_call cout_string, str_not_completed

        ;; Wait for keyboard
        sta     KBDSTRB
loop:   lda     KBD
        bpl     loop
        and     #CHAR_MASK
        sta     KBDSTRB

        cmp     #'M'            ; Easter Egg: If 'M', enter monitor
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
        sta     @len
        beq     done
:       iny
        lda     ($06),y
        ora     #$80
        jsr     COUT
        @len := *+1
        cpy     #0              ; self-modified
        bne     :-
done:   rts
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


;;; ============================================================
;;;
;;; Part 3: Invoke Selector or DeskTop
;;;
;;; ============================================================

.proc invoke_selector_or_desktop_impl
        app_bootstrap_start := $2000
        kAppBootstrapSize = $400

        .assert * >= app_bootstrap_start + kAppBootstrapSize, error, "overlapping addresses"

        DEFINE_OPEN_PARAMS open_desktop2_params, str_desktop2, src_io_buffer
        DEFINE_OPEN_PARAMS open_selector_params, str_selector, src_io_buffer
        DEFINE_READ_PARAMS read_params, app_bootstrap_start, kAppBootstrapSize
        DEFINE_CLOSE_PARAMS close_everything_params

str_selector:
        PASCAL_STRING "Selector" ; do not localize
str_desktop2:
        PASCAL_STRING "DeskTop2" ; do not localize


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
        jmp     app_bootstrap_start
.endproc
        invoke_selector_or_desktop := invoke_selector_or_desktop_impl::start


;;; ============================================================
;;; Loaded at $1000 by DeskTop2 on Quit, and copies $1100-$13FF
;;; to Language Card Bank 2 $D100-$D3FF, to restore saved quit
;;; (selector/dispatch) handler, then does ProDOS QUIT.

quit_code_addr := $1000
quit_code_save := $1100

str_quit_code:  PASCAL_STRING "Quit.tmp" ; do not localize
PROC_AT quit_restore_proc, ::quit_code_addr

        lda     LCBANK2
        lda     LCBANK2
        ldx     #0
:
        .repeat 3, i
        lda     quit_code_save + ($100 * i), x
        sta     SELECTOR + ($100 * i), x
        .endrepeat
        dex
        bne     :-

        lda     ROMIN2

        MLI_CALL QUIT, quit_params
        DEFINE_QUIT_PARAMS quit_params

        PAD_TO ::quit_code_save
END_PROC_AT
        .assert .sizeof(quit_restore_proc) = $100, error, "Proc length mismatch"

.proc preserve_quit_code_impl
        quit_code_io := $800
        kQuitCodeSize = $400
        DEFINE_CREATE_PARAMS create_params, str_quit_code, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_params, str_quit_code, quit_code_io
        DEFINE_WRITE_PARAMS write_params, quit_code_addr, kQuitCodeSize
        DEFINE_CLOSE_PARAMS close_params

start:  lda     LCBANK2
        lda     LCBANK2
        ldx     #0
:
        lda     quit_restore_proc, x
        sta     quit_code_addr, x
        .repeat 3, i
        lda     SELECTOR + ($100 * i), x
        sta     quit_code_save + ($100 * i), x
        .endrepeat
        dex
        bne     :-

        lda     ROMIN2

        ;; Create file (if needed)
        copy16  DATELO, create_params::create_date
        copy16  TIMELO, create_params::create_time
        MLI_CALL CREATE, create_params
        beq     :+
        cmp     #ERR_DUPLICATE_FILENAME
        bne     done

        ;; Populate it
:       MLI_CALL OPEN, open_params
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_CALL WRITE, write_params
        MLI_CALL CLOSE, close_params

done:   rts

.endproc
        preserve_quit_code := preserve_quit_code_impl::start

;;; ============================================================

        PAD_TO $4000
