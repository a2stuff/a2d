        .include "../config.inc"
        RESOURCE_FILE "desktop.system.res"

        .include "apple2.inc"
        .include "opcodes.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../inc/smartport.inc"

        .include "../common.inc"

;;; ============================================================
;;; Memory map
;;;
;;;              Main
;;;          :             :
;;;          | ProDOS      |
;;;   $BF00  +-------------+
;;;          |.............|
;;;          :.............:
;;;          |.............|
;;;          |.(buffer)....|    * data buffer for copies to RAMCard
;;;   $3700  +-------------+
;;;          | Settings    |
;;;   $3680  +-------------+
;;;          |             |
;;;          |             |
;;;          |             |
;;;          | Code        |
;;;   $2000  +-------------+
;;;          |.............|
;;;          |.(unused)....|
;;;   $1E00  +-------------+
;;;          |             |
;;;          | Sel List    |    * holds SELECTOR.LIST
;;;   $1600  +-------------+
;;;          |             |
;;;          | Dst IO Buf  |    * writing copied files, DESKTOP.SYSTEM
;;;   $1200  +-------------+
;;;          |             |    * reading copied files, SELECTOR.LIST
;;;          | Src I/O Buf |
;;;    $E00  +-------------+
;;;          |.(unused)....|
;;;    $C00  +-------------+
;;;          |             |
;;;          | Dir I/O Buf |
;;;    $800  +-------------+
;;;          :             :

MLIEntry        := MLI

dir_io_buffer   := $800         ; 1024 bytes for I/O

src_io_buffer   := $E00         ; 1024 bytes for I/O
dst_io_buffer   := $1200        ; 1024 bytes for I/O
selector_buffer := $1600        ; Room for kSelectorListBufSize

copy_buffer     := $3700
kCopyBufferSize = MLI - copy_buffer
        .assert (kCopyBufferSize - ((kCopyBufferSize/$200)*$200)) = 0, error, "better performance for an integral number of blocks"

SETTINGS        := copy_buffer - .sizeof(DeskTopSettings)

;;; ============================================================

kShortcutMonitor = res_char_monitor_shortcut


;;; ============================================================

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

        jmp     start

        ASSERT_ADDRESS PRODOS_SYS_START + kLauncherDateOffset
header_date:                    ; written into file by Date and Time DA
        .res    .sizeof(DateTime)

header_orig_prefix:
        .res    64, 0           ; written into file with original path

        kWriteBackSize = * - PRODOS_SYS_START




;;; ============================================================

start:
        jsr     DetectMousetext
        jsr     CreateLocalDir
        jsr     LoadSettings
        jmp     CopyDesktopToRamcard

;;; ============================================================

local_dir:      PASCAL_STRING kFilenameLocalDir
        DEFINE_CREATE_PARAMS create_params, local_dir, ACCESS_DEFAULT, FT_DIRECTORY,, ST_LINKED_DIRECTORY

.proc CreateLocalDir
        MLI_CALL CREATE, create_params
        rts
.endproc

;;; ============================================================

        SETTINGS_IO_BUF := src_io_buffer
        SETTINGS_LOAD_BUF := copy_buffer
        .include "../lib/load_settings.s"

;;; ============================================================
;;;
;;; Generic recursive file copy routine
;;;
;;; ============================================================

;;; Entry point is GenericCopy::DoCopy
;;; * Source path is GenericCopy::path2
;;; * Destination path is GenericCopy::path1
;;; * Callbacks (GenericCopy::hook_*) must be populated

.proc GenericCopy

;;; ============================================================

;;; Source/Destination paths - caller must initialize these
path1:  .res    ::kPathBufferSize, 0
path2:  .res    ::kPathBufferSize, 0

;;; Callbacks - caller must initialize these
hook_handle_error_code:   .addr   0 ; fatal; A = ProDOS error code or kErrCancel
hook_handle_no_space:     .addr   0 ; fatal
hook_insert_source:       .addr   0 ; if this returns, copy is retried
hook_show_file:           .addr   0 ; called when `path2` updated

kErrCancel = $FF

;;; ============================================================

ShowInsertPrompt:
        jmp     (hook_insert_source)

ShowCopyingScreen:
        jmp     (hook_show_file)

        DEFINE_GET_FILE_INFO_PARAMS get_path2_info_params, path2
        DEFINE_GET_FILE_INFO_PARAMS get_path1_info_params, path1
        DEFINE_CREATE_PARAMS create_params, path1, 0
        DEFINE_OPEN_PARAMS open_path2_params, path2, dir_io_buffer

        ;; Used for reading directory structure
        ;; 4 bytes is .sizeof(SubdirectoryHeader) - .sizeof(FileEntry)
        kBlockPointersSize = 4
        .assert .sizeof(SubdirectoryHeader) - .sizeof(FileEntry) = kBlockPointersSize, error, "bad structs"
        DEFINE_READ_PARAMS read_block_pointers_params, buf_block_pointers, kBlockPointersSize ; For skipping prev/next pointers in directory data
buf_block_pointers:     .res    kBlockPointersSize, 0

        DEFINE_CLOSE_PARAMS close_params
        DEFINE_READ_PARAMS read_fileentry_params, file_entry, .sizeof(FileEntry)

        ;; Blocks are 512 bytes, 13 entries of 39 bytes each leaves 5 bytes between.
        ;; Except first block, directory header is 39+4 bytes, leaving 1 byte, but then
        ;; block pointers are the next 4.
        kMaxPaddingBytes = 5
        DEFINE_READ_PARAMS read_padding_bytes_params, buf_padding_bytes, kMaxPaddingBytes
buf_padding_bytes:      .res    kMaxPaddingBytes, 0
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
;;; Inputs: `path2` is source path
;;;         `path1` is destination path
.proc DoCopy
        ;; Check destination dir
        MLI_CALL GET_FILE_INFO, get_path1_info_params
        cmp     #ERR_FILE_NOT_FOUND
        beq     okerr
        cmp     #ERR_VOL_NOT_FOUND
        beq     okerr
        cmp     #ERR_PATH_NOT_FOUND
        beq     okerr
        jmp     fail
        rts                     ; Otherwise, fail the copy

        ;; Get source dir info
okerr:  MLI_CALL GET_FILE_INFO, get_path2_info_params
        beq     gfi_ok
        cmp     #ERR_VOL_NOT_FOUND
        beq     prompt
        cmp     #ERR_FILE_NOT_FOUND
        bne     fail

prompt: jsr     ShowInsertPrompt
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
        jsr     CheckSpaceAvailable
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
        jmp     CopyDirectory
:       jmp     CopyNormalFile

is_dir_flag:
        .byte   0
.endproc

;;; ============================================================
;;; Copy an entry in a directory. For files, the content is copied.
;;; For directories, the target is created but the caller is responsible
;;; for copying the child entries.
;;; Inputs: `file_entry` populated with FileEntry
;;;         `path2` has source directory path
;;;         `path1` has destination directory path
;;; Errors: HandleErrorCode is invoked

.proc CopyEntry
        lda     file_entry + FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     do_file

        ;; --------------------------------------------------
        ;; Directory
        jsr     AppendFilenameToPath2
        jsr     ShowCopyingScreen
        MLI_CALL GET_FILE_INFO, get_path2_info_params
        beq     ok
        jmp     (hook_handle_error_code)

onerr:  jsr     RemoveFilenameFromPath1
        jsr     RemoveFilenameFromPath2
        lda     #$FF
        sta     copy_err_flag
        jmp     exit

ok:     jsr     AppendFilenameToPath1
        jsr     CreateDir
        bcs     onerr
        jsr     RemoveFilenameFromPath2
        jmp     exit

        ;; --------------------------------------------------
        ;; File
do_file:
        jsr     AppendFilenameToPath1
        jsr     AppendFilenameToPath2
        jsr     ShowCopyingScreen
        MLI_CALL GET_FILE_INFO, get_path2_info_params
        beq     :+
        jmp     (hook_handle_error_code)

:       jsr     CheckSpaceAvailable
        bcc     :+
        jmp     (hook_handle_no_space)

        ;; Create parent dir if necessary
:       jsr     RemoveFilenameFromPath2
        jsr     CreateDir
        bcs     cleanup
        jsr     AppendFilenameToPath2

        ;; Do the copy
        jsr     CopyNormalFile
        jsr     RemoveFilenameFromPath2
        jsr     RemoveFilenameFromPath1

exit:   rts

cleanup:
        jmp     RemoveFilenameFromPath1
.endproc

;;; ============================================================
;;; Check that there is room to copy a file. Handles overwrites.
;;; Inputs: `path2` is source; `path1` is target
;;; Outputs: C=0 if there is sufficient space, C=1 otherwise

.proc CheckSpaceAvailable

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
        ;; If overwriting, some blocks will be reclaimed.
        add16   vol_free, dst_size, vol_free
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
;;; Inputs: `open_srcfile_params` populated
;;;         `open_dstfile_params` populated; file already created
;;; Errors: HandleErrorCode is invoked

.proc CopyNormalFile
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
        jsr     CheckCancel
        MLI_CALL READ, read_srcfile_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     close
        jmp     (hook_handle_error_code)

        ;; Write the chunk
:       copy16  read_srcfile_params::trans_count, write_dstfile_params::request_count
        ora     read_srcfile_params::trans_count
        beq     close
        jsr     CheckCancel
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

.proc CheckCancel
        lda     KBD
        bpl     ret
        cmp     #$80|CHAR_ESCAPE
        beq     cancel
ret:    rts

cancel: lda     #kErrCancel
        jmp     (hook_handle_error_code)
.endproc

;;; ============================================================

.proc CreateDir
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

;;; ============================================================

recursion_depth:        .byte   0 ; How far down the directory structure are we
entries_per_block:      .byte   0
ref_num:                .byte   0
entry_index_in_dir:     .word   0
target_index:           .word   0

;;; Stack used when descending directories; keeps track of entry index within
;;; directories.
index_stack:    .res    ::kDirStackBufferSize, 0
stack_index:    .byte   0

entry_index_in_block:   .byte   0

;;; ============================================================

.proc PushIndexToStack
        ldx     stack_index
        lda     target_index
        sta     index_stack,x
        inx
        lda     target_index+1
        sta     index_stack,x
        inx
        stx     stack_index
        rts
.endproc

;;; ============================================================

.proc PopIndexFromStack
        ldx     stack_index
        dex
        lda     index_stack,x
        sta     target_index+1
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

.proc OpenSrcDir
        lda     #0
        sta     entry_index_in_dir
        sta     entry_index_in_dir+1
        sta     entry_index_in_block
        MLI_CALL OPEN, open_path2_params
        beq     :+
        jmp     (hook_handle_error_code)

        ;; Skip over prev/next block pointers in header
:       lda     open_path2_params::ref_num
        sta     ref_num
        sta     read_block_pointers_params::ref_num
        MLI_CALL READ, read_block_pointers_params
        beq     :+
        jmp     (hook_handle_error_code)

        ;; Header size is next/prev blocks + a file entry
        .assert .sizeof(SubdirectoryHeader) = .sizeof(FileEntry) + 4, error, "incorrect struct size"
:       copy    #13, entries_per_block ; so ReadFileEntry doesn't immediately advance
        jsr     ReadFileEntry          ; read the rest of the header

        copy    file_entry-4 + SubdirectoryHeader::entries_per_block, entries_per_block

        rts
.endproc

;;; ============================================================

.proc DoCloseFile
        lda     ref_num
        sta     close_params::ref_num
        MLI_CALL CLOSE, close_params
        beq     :+
        jmp     (hook_handle_error_code)
:       rts
.endproc

;;; ============================================================
;;; Read the next file entry in the directory into `file_entry`
;;; NOTE: Also used to read the vol/dir header.

.proc ReadFileEntry
        inc16   entry_index_in_dir

        ;; Skip entry
        lda     ref_num
        sta     read_fileentry_params::ref_num
        MLI_CALL READ, read_fileentry_params
        beq     :+
        cmp     #ERR_END_OF_FILE
        beq     eof
        jmp     (hook_handle_error_code)
:
        ldax    #file_entry
        jsr     AdjustFileEntryCase

        inc     entry_index_in_block
        lda     entry_index_in_block
        cmp     entries_per_block
        bcc     done

        ;; Advance to first entry in next "block"
        lda     #0
        sta     entry_index_in_block
        lda     ref_num
        sta     read_padding_bytes_params::ref_num
        MLI_CALL READ, read_padding_bytes_params
        beq     :+
        jmp     (hook_handle_error_code)
:

done:   return  #0

eof:    return  #$FF
.endproc

;;; ============================================================

.proc DescendDirectory
        copy16  entry_index_in_dir, target_index
        jsr     DoCloseFile
        jsr     PushIndexToStack
        jsr     AppendFilenameToPath2
        jmp     OpenSrcDir
.endproc

.proc AscendDirectory
        jsr     DoCloseFile
        jsr     RemoveFilenameFromPath2
        jsr     PopIndexFromStack
        jsr     OpenSrcDir
        jsr     AdvanceToTargetEntry
        jmp     RemoveFilenameFromPath1
.endproc

.proc AdvanceToTargetEntry
:       cmp16   entry_index_in_dir, target_index
        bcs     :+
        jsr     ReadFileEntry
        jmp     :-

:       rts
.endproc

;;; ============================================================
;;; Recursively copy
;;; Inputs: path2 points at source directory

.proc CopyDirectory
        lda     #0
        sta     recursion_depth
        jsr     OpenSrcDir

loop:   jsr     ReadFileEntry
        bne     next

        lda     file_entry + FileEntry::storage_type_name_length
        beq     loop            ; deleted

        lda     file_entry + FileEntry::storage_type_name_length
        and     #NAME_LENGTH_MASK
        sta     filename

        lda     #0
        sta     copy_err_flag

        jsr     CopyEntry

        lda     copy_err_flag   ; don't recurse if the copy failed
        bne     loop
        lda     file_entry + FileEntry::file_type
        cmp     #FT_DIRECTORY
        bne     loop            ; and don't recurse unless it's a directory

        ;; Recurse into child directory
        jsr     DescendDirectory
        inc     recursion_depth
        jmp     loop

next:   lda     recursion_depth
        beq     done
        jsr     AscendDirectory
        dec     recursion_depth
        jmp     loop

done:   jmp     DoCloseFile
.endproc

;;; ============================================================

        ;; Set on error during copying of a single file
copy_err_flag:
        .byte   0


;;; ============================================================

.proc AppendFilenameToPath2
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

.proc RemoveFilenameFromPath2
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

.proc AppendFilenameToPath1
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

.proc RemoveFilenameFromPath1
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

.proc CopyDesktopToRamcardImpl

;;; ============================================================
;;; Data buffers and param blocks

        ;; Used in CheckDesktopOnDevice
        path_buf := $D00
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params4, path_buf

unit_num:
        .byte   0

;;; Index into DEVLST while iterating devices.
devnum: .byte   0

.params status_params
param_count:    .byte   3
unit_num:       .byte   SELF_MODIFIED_BYTE
list_ptr:       .addr   dib_buffer
status_code:    .byte   3       ; Return Device Information Block (DIB)
.endparams

.params dib_buffer
Device_Statbyte1:       .byte   0
Device_Size_Lo:         .byte   0
Device_Size_Med:        .byte   0
Device_Size_Hi:         .byte   0
ID_String_Length:       .byte   0
Device_Name:            .res    16
Device_Type_Code:       .byte   0
Device_Subtype_Code:    .byte   0
Version:                .word   0
.endparams

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer
on_line_buffer: .res 17, 0

copied_flag:                    ; set to dst_path's length, or reset
        .byte   0

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, src_path
        DEFINE_SET_PREFIX_PARAMS set_prefix_params, dst_path

        DEFINE_CREATE_PARAMS create_dt_dir_params, dst_path, ACCESS_DEFAULT, FT_DIRECTORY, 0, ST_LINKED_DIRECTORY
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, src_path

kNumFilenames = 6

        ;; Files/Directories to copy
str_f1: PASCAL_STRING kFilenameLauncher
str_f2: PASCAL_STRING kFilenameModulesDir
str_f3: PASCAL_STRING kFilenameLocalDir
str_f4: PASCAL_STRING kFilenameDADir
str_f5: PASCAL_STRING kFilenamePreviewDir
str_f6: PASCAL_STRING kFilenameExtrasDir

filename_table:
        .addr str_f1,str_f2,str_f3,str_f4,str_f5,str_f6
        ASSERT_ADDRESS_TABLE_SIZE filename_table, kNumFilenames

        kHtabCopyingMsg = (80 - .strlen(.sprintf(res_string_copying_to_ramcard, kDeskTopProductName))) / 2
        kVtabCopyingMsg = 12
str_copying_to_ramcard:
        PASCAL_STRING .sprintf(res_string_copying_to_ramcard, kDeskTopProductName)

        kHtabCancelMsg = (80 - .strlen(res_string_esc_to_cancel)) / 2
        kVtabCancelMsg = 16
str_esc_to_cancel:
        PASCAL_STRING res_string_esc_to_cancel

        ;; String contains four control characters to toggle MouseText charset
        kHtabCopyingTip = (80 - (.strlen(res_string_label_tip_skip_copying) - 4)) / 2
        kVtabCopyingTip = 23
str_tip_skip_copying:
        PASCAL_STRING res_string_label_tip_skip_copying

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

str_slash_desktop:
        PASCAL_STRING .concat("/", kFilenameRAMCardDir)

;;; ============================================================

.proc Start
        sta     KBDSTRB
        sta     TXTSET

        lda     MACHID
        and     #%00000001      ; bit 0 = clock card
        bne     :+
        lda     DATELO          ; Any date already set?
        ora     DATEHI
        bne     :+
        COPY_STRUCT DateTime, header_date, DATELO
:       lda     MACHID
        and     #%00110000      ; bits 4,5 set = 128k
        cmp     #%00110000
        beq     have128k

        ;;  If not 128k machine, just quit back to ProDOS
        MLI_CALL QUIT, quit_params
        DEFINE_QUIT_PARAMS quit_params

have128k:
        ;; Clear Main & AUX text screen memory so
        ;; junk doesn't show on switch to 80-column,
        ;; while protecting 'screen holes' for //c & //c+
        jsr     HOME
        sta     RAMWRTON
        lda     #$A0
        ldx     #$77
:       sta     $400,x
        sta     $480,x
        sta     $500,x
        sta     $580,x
        sta     $600,x
        sta     $680,x
        sta     $700,x
        sta     $780,x
        dex
        bpl     :-
        sta     RAMWRTOFF

        ;; Turn on 80-column mode
        jsr     SLOT3ENTRY
        jsr     HOME

        ;; Save original Quit routine and small loader
        ;; TODO: Assumes prefix is retained. Compose correct path.

        jsr     PreserveQuitCode

resume:
        ;; IIgs: Reset shadowing
        sec
        jsr     IDROUTINE
        bcs     :+
        copy    #0, SHADOW
:

        ;; Clear flag - ramcard not found or unknown state.
        ldx     #0
        jsr     SetCopiedToRamcardFlag

        ;; Skip RAMCard install if flag is set
        lda     SETTINGS + DeskTopSettings::startup
        and     #DeskTopSettings::kStartupSkipRAMCard
        beq     :+
        jmp     DidNotCopy

        ;; Skip RAMCard install if button is down
:       lda     BUTN0
        ora     BUTN1
        bpl     SearchDevices
        jmp     DidNotCopy

        ;; --------------------------------------------------
        ;; Look for RAM disk

.proc SearchDevices
        copy    DEVCNT, devnum

loop:   ldx     devnum
        lda     DEVLST,x
        sta     unit_num

        ;; Special case for RAM.DRV.SYSTEM/RAMAUX.SYSTEM.
        cmp     #kRamDrvSystemUnitNum
        beq     test_unit_num
        cmp     #kRamAuxSystemUnitNum
        beq     test_unit_num

        ;; Smartport?
        jsr     FindSmartportDispatchAddress
        bcs     next_unit
        stax    dispatch
        sty     status_params::unit_num

        ;; Execute SmartPort call
        dispatch := *+1
        jsr     SELF_MODIFIED
        .byte   SPCall::Status
        .addr   status_params
        bcs     next_unit

        ;; Online?
        lda     dib_buffer::Device_Statbyte1
        and     #$10            ; general status byte, $10 = disk in drive
        beq     next_unit

        ;; Check device type
        ;; Technical Note: SmartPort #4: SmartPort Device Types
        ;; http://www.1000bit.it/support/manuali/apple/technotes/smpt/tn.smpt.4.html
        lda     dib_buffer::Device_Type_Code
        .assert SPDeviceType::MemoryExpansionCard = 0, error, "enum mismatch"
        bne     next_unit       ; $00 = Memory Expansion Card (RAM Disk)
        lda     unit_num
        bne     test_unit_num   ; always

next_unit:
        dec     devnum
        bpl     loop
        jmp     DidNotCopy

        ;; Have a prospective device.
test_unit_num:
        ;; Verify it's online.
        lda     unit_num
        and     #UNIT_NUM_MASK
        sta     on_line_params::unit_num
        MLI_CALL ON_LINE, on_line_params
        bne     next_unit
        lda     on_line_buffer
        and     #NAME_LENGTH_MASK
        beq     next_unit
        sta     on_line_buffer
        param_call AdjustVolumeNameCase, on_line_buffer

        ;; Copy the name prepended with '/' to `dst_path`
        ldy     on_line_buffer
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
        jsr     SetCopiedToRamcardFlag

        ;; Keep root path (e.g. "/RAM5") for selector entry copies
        param_call SetRamcardPrefix, dst_path

        ;; Append app dir name, e.g. "/RAM5/DESKTOP"
        ldy     dst_path
        ldx     #0
:       iny
        inx
        lda     str_slash_desktop,x
        sta     dst_path,y
        cpx     str_slash_desktop
        bne     :-
        sty     dst_path

        ;; Is it already present?
        jsr     CheckDesktopOnDevice
        bcs     StartCopy       ; No, start copy.

        ;; Already copied - record that it was installed and grab path.
        ldx     #$80
        jsr     SetCopiedToRamcardFlag
        jsr     CopyOrigPrefixToDesktopOrigPrefix
        copy    dst_path, copied_flag
        jmp     FinishDeskTopCopy ; sets prefix, etc.
.endproc
.endproc

.proc StartCopy
        ptr := $06

        jsr     ShowCopyingDeskTopScreen
        jsr     InitProgress

        MLI_CALL GET_PREFIX, get_prefix_params
        beq     :+
        jmp     DidNotCopy
:       dec     src_path

        ;; Record that the copy was performed.
        ldx     #$80
        jsr     SetCopiedToRamcardFlag

        ldy     src_path
:       lda     src_path,y
        sta     header_orig_prefix,y
        dey
        bpl     :-

        ;; --------------------------------------------------
        ;; Create desktop directory, e.g. "/RAM/DESKTOP"

        MLI_CALL CREATE, create_dt_dir_params
        beq     :+
        cmp     #ERR_DUPLICATE_FILENAME
        beq     :+
        jsr     DidNotCopy
:

        ;; --------------------------------------------------
        ;; Loop over listed files to copy

        tsx                     ; In case of error
        stx     saved_stack

        copy    dst_path, copied_flag ; reset on error
        copy    #0, filenum

file_loop:
        jsr     UpdateProgress

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
        jsr     CopyFile
        inc     filenum
        lda     filenum
        cmp     #kNumFilenames
        bne     file_loop

        jsr     UpdateProgress
        FALL_THROUGH_TO FinishDeskTopCopy
.endproc

.proc FinishDeskTopCopy
        lda     copied_flag
    IF_NOT_ZERO
        sta     dst_path
        MLI_CALL SET_PREFIX, set_prefix_params
    END_IF

        jsr     UpdateSelfFile
        jsr     CopyOrigPrefixToDesktopOrigPrefix

        lda     #0
        sta     RAMWORKS_BANK   ; Just in case???

        ;; Initialize system bitmap
        ldx     #BITMAP_SIZE-1
        lda     #0
:       sta     BITMAP,x
        dex
        bpl     :-
        lda     #%00000001      ; ProDOS global page
        sta     BITMAP+BITMAP_SIZE-1
        lda     #%11001111      ; ZP, Stack, Text Page 1
        sta     BITMAP

        ;; Done! Move on to Part 2.
        jmp     CopySelectorEntriesToRamcard
.endproc

;;; ============================================================

.proc DidNotCopy
        copy    #0, copied_flag
        jmp     FinishDeskTopCopy
.endproc

;;; ============================================================

.proc SetCopiedToRamcardFlag
        bit     LCBANK2
        bit     LCBANK2
        stx     COPIED_TO_RAMCARD_FLAG
        bit     ROMIN2
        rts
.endproc

.proc SetRamcardPrefix
        ptr := $6
        target := RAMCARD_PREFIX

        stax    ptr
        bit     LCBANK2
        bit     LCBANK2
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     target,y
        dey
        bpl     :-
        bit     ROMIN2
        rts
.endproc

.proc SetDesktopOrigPrefix
        ptr := $6
        target := DESKTOP_ORIG_PREFIX

        stax    ptr
        bit     LCBANK2
        bit     LCBANK2

        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     target,y
        dey
        bpl     :-

        bit     ROMIN2
        rts
.endproc

;;; ============================================================

.proc AppendFilenameToSrcPath
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

.proc RemoveFilenameFromSrcPath
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

.proc AppendFilenameToDstPath
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

.proc RemoveFilenameFromDstPath
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

.proc ShowCopyingDeskTopScreen

        ;; Message
        lda     #kHtabCopyingMsg
        sta     OURCH
        lda     #kVtabCopyingMsg
        jsr     VTABZ
        param_call CoutString, str_copying_to_ramcard

        ;; Esc to Cancel
        lda     #kHtabCancelMsg
        sta     OURCH
        lda     #kVtabCancelMsg
        jsr     VTABZ
        param_call CoutString, str_esc_to_cancel

        ;; Tip
        bit     supports_mousetext
        bpl     done

        lda     #kHtabCopyingTip
        sta     OURCH
        lda     #kVtabCopyingTip
        jsr     VTABZ
        param_call CoutString, str_tip_skip_copying

done:   rts
.endproc

;;; ============================================================
;;; Callback from copy failure; restores stack and proceeds.

.proc FailCopy
        ldx     saved_stack
        txs

        jmp     DidNotCopy
.endproc

;;; ============================================================
;;; Copy `filename` from `src_path` to `dst_path`

.proc CopyFile
        jsr     AppendFilenameToDstPath
        jsr     AppendFilenameToSrcPath
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        cmp     #ERR_FILE_NOT_FOUND
        beq     cleanup
        jmp     DidNotCopy
:

        ;; Set up source path
        ldy     src_path
:       lda     src_path,y
        sta     GenericCopy::path2,y
        dey
        bpl     :-

        ;; Set up destination path
        ldy     dst_path
:       lda     dst_path,y
        sta     GenericCopy::path1,y
        dey
        bpl     :-

        copy16  #FailCopy, GenericCopy::hook_handle_error_code
        copy16  #FailCopy, GenericCopy::hook_handle_no_space
        copy16  #FailCopy, GenericCopy::hook_insert_source
        copy16  #noop, GenericCopy::hook_show_file

        jsr     GenericCopy::DoCopy

cleanup:
        jsr     RemoveFilenameFromSrcPath
        jsr     RemoveFilenameFromDstPath

noop:
        rts
.endproc

;;; ============================================================
;;; Input: `dst_path` set to RAMCard app dir (e.g. "/RAM5/DESKTOP")

.proc CheckDesktopOnDevice
        ;; `path_buf` = `dst_path`
        COPY_STRING dst_path, path_buf

        ;; `path_buf` += "/Modules/DeskTop"
        ldx     path_buf
        ldy     #0
loop:   inx
        iny
        lda     str_desktop_path,y
        sta     path_buf,x
        cpy     str_desktop_path
        bne     loop
        stx     path_buf

        ;; ... and get info
        MLI_CALL GET_FILE_INFO, get_file_info_params4
        bcs     ret

        cmp16   #2, get_file_info_params4::blocks_used
        ;; Ensure at least something was written to the file
        ;; (uses 1 block at creation)

ret:    rts

        ;; Appended to RAMCard root path e.g. "/RAM5"
str_desktop_path:
        PASCAL_STRING .concat("/", kFilenameDeskTop)
.endproc

;;; ============================================================
;;; Update the live (RAM or disk) copy of this file with the
;;; original prefix.

.proc UpdateSelfFileImpl
        DEFINE_OPEN_PARAMS open_params, str_self_filename, dst_io_buffer
str_self_filename:
        PASCAL_STRING kFilenameLauncher
        DEFINE_WRITE_PARAMS write_params, PRODOS_SYS_START, kWriteBackSize
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
UpdateSelfFile  := UpdateSelfFileImpl::start

;;; ============================================================

.proc CopyOrigPrefixToDesktopOrigPrefix
        param_call SetDesktopOrigPrefix, header_orig_prefix
        rts
.endproc

;;; ============================================================

.endproc ; CopyDesktopToRamcardImpl

CopyDesktopToRamcard := CopyDesktopToRamcardImpl::Start

;;; ============================================================

        kProgressStops = CopyDesktopToRamcardImpl::kNumFilenames + 1
        .include "../lib/loader_progress.s"

;;; ============================================================
;;;
;;; Part 2: Copy Selector Entries to RAMCard
;;;
;;; ============================================================

.proc CopySelectorEntriesToRamcardImpl

;;; Save stack to restore on error during copy.
saved_stack:
        .byte   0

.proc Start
        sta     KBDSTRB

        ;; Clear screen
        jsr     SLOT3ENTRY
        jsr     HOME

        FALL_THROUGH_TO ProcessSelectorList
.endproc

;;; See docs/Selector_List_Format.md for file format

.proc ProcessSelectorList
        ptr := $6

        ;; Is there a RAMCard?
        bit     LCBANK2
        bit     LCBANK2
        lda     COPIED_TO_RAMCARD_FLAG
        php
        bit     ROMIN2
        plp
        bne     :+
        jmp     InvokeSelectorOrDesktop ; no RAMCard - skip!

        ;; Clear "Copied to RAMCard" flags
:       bit     LCBANK2
        bit     LCBANK2
        ldx     #kSelectorListNumEntries-1
        lda     #0
:       sta     ENTRY_COPIED_FLAGS,x
        dex
        bpl     :-
        bit     ROMIN2

        ;; Load and iterate over the selector file
        jsr     ReadSelectorList
        beq     :+
        jmp     bail
:

        tsx                     ; in case of error
        stx     saved_stack

        ;; Process "primary list" entries (first 8)
.scope
        lda     #0
        sta     entry_num
entry_loop:
        lda     entry_num
        cmp     selector_buffer + kSelectorListNumPrimaryRunListOffset
        beq     done_entries
        jsr     ComputeLabelAddr
        stax    ptr

        ldy     #kSelectorEntryFlagsOffset ; Check Copy-to-RamCARD flags
        lda     (ptr),y
        .assert kSelectorEntryCopyOnBoot = 0, error, "enum mismatch"
        bne     next_entry
        lda     entry_num
        jsr     ComputePathAddr

        jsr     PrepareEntryPaths
        jsr     CopyUsingEntryPaths

        bit     LCBANK2         ; Mark copied
        bit     LCBANK2
        ldx     entry_num
        lda     #$FF
        sta     ENTRY_COPIED_FLAGS,x
        bit     ROMIN2

next_entry:
        inc     entry_num
        jmp     entry_loop
done_entries:
.endscope

        ;; Process "secondary run list" entries (final 16)
.scope
        lda     #0
        sta     entry_num
entry_loop:
        lda     entry_num
        cmp     selector_buffer + kSelectorListNumSecondaryRunListOffset
        beq     done_entries
        clc
        adc     #8
        jsr     ComputeLabelAddr
        stax    ptr

        ldy     #kSelectorEntryFlagsOffset ; Check Copy-to-RamCARD flags
        lda     (ptr),y
        .assert kSelectorEntryCopyOnBoot = 0, error, "enum mismatch"
        bne     next_entry
        lda     entry_num
        clc
        adc     #8
        jsr     ComputePathAddr

        jsr     PrepareEntryPaths
        jsr     CopyUsingEntryPaths

        bit     LCBANK2
        bit     LCBANK2
        lda     entry_num
        clc
        adc     #8
        tax
        lda     #$FF
        sta     ENTRY_COPIED_FLAGS,x
        bit     ROMIN2
next_entry:
        inc     entry_num
        jmp     entry_loop
done_entries:
.endscope

bail:
        jmp     InvokeSelectorOrDesktop

entry_num:
        .byte   0
.endproc

;;; ============================================================


entry_path1:  .res    ::kSelectorListPathLength, 0
entry_path2:  .res    ::kSelectorListPathLength, 0
entry_dir_name:
        .res    16, 0  ; e.g. "APPLEWORKS" from ".../APPLEWORKS/AW.SYSTEM"


;;; ============================================================

.proc CopyUsingEntryPaths
        jsr     PreparePathsFromEntryPaths

        ;; Set up destination dir path, e.g. "/RAM/APPLEWORKS"
        ldx     GenericCopy::path1 ; Append '/' to path1
        lda     #'/'
        sta     GenericCopy::path1+1,x
        inc     GenericCopy::path1

        ldy     #0              ; Append entry_dir_name to path1
        ldx     GenericCopy::path1
:       iny
        inx
        lda     entry_dir_name,y
        sta     GenericCopy::path1,x
        cpy     entry_dir_name
        bne     :-
        stx     GenericCopy::path1

        ;; Install callbacks and invoke
        copy16  #HandleErrorCode, GenericCopy::hook_handle_error_code
        copy16  #ShowNoSpacePrompt, GenericCopy::hook_handle_no_space
        copy16  #ShowInsertPrompt, GenericCopy::hook_insert_source
        copy16  #ShowCopyingEntryScreen, GenericCopy::hook_show_file
        jmp     GenericCopy::DoCopy
.endproc

;;; ============================================================
;;; Copy entry_path1/2 to path1/2

.proc PreparePathsFromEntryPaths
        ldy     #$FF

        ;; Copy entry_path2 to path2
loop:   iny
        lda     entry_path2,y
        sta     GenericCopy::path2,y
        cpy     entry_path2
        bne     loop

        ;; Copy entry_path1 to path1
        ldy     entry_path1
loop2:  lda     entry_path1,y
        sta     GenericCopy::path1,y
        dey
        bpl     loop2

        rts
.endproc


;;; ============================================================
;;; Compute first offset into selector file - A*16 + 2

.proc ComputeLabelAddr
        addr := selector_buffer + kSelectorListEntriesOffset

        jsr     AxTimes16
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

.proc ComputePathAddr
        addr := selector_buffer + kSelectorListPathsOffset

        jsr     AxTimes64
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

.proc ReadSelectorListImpl
        DEFINE_OPEN_PARAMS open_params, str_selector_list, src_io_buffer
str_selector_list:
        PASCAL_STRING kFilenameSelectorList
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
ReadSelectorList        := ReadSelectorListImpl::start

;;; ============================================================

.proc AxTimes16
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

.proc AxTimes64
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

.proc PrepareEntryPaths
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
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       dey
        sty     entry_path2

        ;; Find offset of parent directory name, e.g. "APPLEWORKS"
:       lda     entry_path2,y
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
        bit     LCBANK2
        bit     LCBANK2
        ldy     RAMCARD_PREFIX
:       lda     RAMCARD_PREFIX,y
        sta     entry_path1,y
        dey
        bpl     :-
        bit     ROMIN2

        rts
.endproc

;;; ============================================================

str_copying:
        PASCAL_STRING res_string_label_copying

str_insert:
        PASCAL_STRING res_string_prompt_insert_source

str_not_enough:
        PASCAL_STRING res_string_prompt_ramcard_full

str_error_prefix:
        PASCAL_STRING res_string_error_prefix

str_error_suffix:
        PASCAL_STRING res_string_error_suffix

str_not_completed:
        PASCAL_STRING res_string_prompt_copy_not_completed

;;; ============================================================

;;; Callback; used for GenericCopy::hook_show_file
.proc ShowCopyingEntryScreen
        jsr     HOME
        lda     #0
        jsr     VTABZ
        lda     #0
        sta     OURCH
        param_call CoutString, str_copying
        param_call CoutStringNewline, GenericCopy::path2
        rts
.endproc

;;; ============================================================

;;; Callback; used for GenericCopy::hook_insert_source
.proc ShowInsertPrompt
        lda     #0
        jsr     VTABZ
        lda     #0
        sta     OURCH
        param_call CoutString, str_insert
        jsr     WaitEnterEscape
        cmp     #CHAR_ESCAPE
        bne     :+

        ldx     saved_stack
        txs
        jmp     FinishAndInvoke

:       jmp     HOME            ; and implicitly continue
.endproc

;;; ============================================================

;;; Callback; used for GenericCopy::hook_handle_no_space
.proc ShowNoSpacePrompt
        ldx     saved_stack
        txs

        lda     #0
        jsr     VTABZ
        lda     #0
        sta     OURCH
        param_call CoutString, str_not_enough
        jsr     WaitEnterEscape

        jmp     FinishAndInvoke
.endproc

;;; ============================================================
;;; On copy failure, show an appropriate error; wait for key
;;; and invoke app.

;;; Callback; used for GenericCopy::hook_handle_error_code
.proc HandleErrorCode
        ldx     saved_stack
        txs

        cmp     #GenericCopy::kErrCancel
        bne     :+
        jmp     FinishAndInvoke
:
        cmp     #ERR_OVERRUN_ERROR
        bne     :+
        jmp     ShowNoSpacePrompt

:       cmp     #ERR_VOLUME_DIR_FULL
        bne     :+
        jmp     ShowNoSpacePrompt

        ;; Show generic error
:       pha
        param_call CoutString, str_error_prefix
        pla
        jsr     PRBYTE
        param_call CoutString, str_error_suffix
        param_call CoutStringNewline, GenericCopy::path2
        param_call CoutString, str_not_completed

        ;; Wait for keyboard
        sta     KBDSTRB
loop:   lda     KBD
        bpl     loop
        and     #CHAR_MASK
        sta     KBDSTRB

        cmp     #kShortcutMonitor ; Easter Egg: If 'M', enter monitor
        beq     monitor
        cmp     #TO_LOWER(kShortcutMonitor)
        beq     monitor

        cmp     #CHAR_RETURN
        bne     loop

        jmp     FinishAndInvoke
.endproc

monitor:
        jmp     MONZ

;;; ============================================================

.proc WaitEnterEscape
        sta     KBDSTRB
:       lda     KBD
        bpl     :-
        sta     KBDSTRB
        and     #CHAR_MASK
        cmp     #CHAR_ESCAPE
        beq     done
        cmp     #CHAR_RETURN
        bne     :-
done:   rts
.endproc

;;; ============================================================

.proc FinishAndInvoke
        jsr     HOME
        jmp     InvokeSelectorOrDesktop
.endproc

;;; ============================================================

.endproc ; CopySelectorEntriesToRamcardImpl
CopySelectorEntriesToRamcard := CopySelectorEntriesToRamcardImpl::Start


;;; ============================================================
;;;
;;; Part 3: Invoke Selector or DeskTop
;;;
;;; ============================================================

.proc InvokeSelectorOrDesktopImpl
        app_bootstrap_start := $2000
        kAppBootstrapSize = $400

        .assert * >= app_bootstrap_start + kAppBootstrapSize, error, "overlapping addresses"

        DEFINE_OPEN_PARAMS open_desktop_params, str_desktop, src_io_buffer
        DEFINE_OPEN_PARAMS open_selector_params, str_selector, src_io_buffer
        DEFINE_READ_PARAMS read_params, app_bootstrap_start, kAppBootstrapSize
        DEFINE_CLOSE_PARAMS close_everything_params

str_selector:
        PASCAL_STRING kFilenameSelector
str_desktop:
        PASCAL_STRING kFilenameDeskTop


start:  MLI_CALL CLOSE, close_everything_params

        ;; Don't try selector if flag is set
        lda     SETTINGS + DeskTopSettings::startup
        and     #DeskTopSettings::kStartupSkipSelector
        bne     :+

        MLI_CALL OPEN, open_selector_params
        beq     selector

:       MLI_CALL OPEN, open_desktop_params
        beq     desktop

        ;; But if DeskTop wasn't present, ignore options and try Selector.
        ;; This supports a Selector-only install without config, e.g. by admins.
        MLI_CALL OPEN, open_selector_params
        beq     selector

        brk                     ; just crash

desktop:
        lda     open_desktop_params::ref_num
        jmp     read

selector:
        lda     open_selector_params::ref_num


read:   sta     read_params::ref_num
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_everything_params
        jmp     app_bootstrap_start
.endproc
InvokeSelectorOrDesktop := InvokeSelectorOrDesktopImpl::start


;;; ============================================================
;;; Loaded at $1000 by DeskTop on Quit, and copies $1100-$13FF
;;; to Language Card Bank 2 $D100-$D3FF, to restore saved quit
;;; (selector/dispatch) handler, then does ProDOS QUIT.

quit_code_addr := $1000
quit_code_save := $1100

str_quit_code:  PASCAL_STRING kFilenameQuitSave
PROC_AT quit_restore_proc, ::quit_code_addr

        bit     LCBANK2
        bit     LCBANK2
        ldx     #0
:
        .repeat 3, i
        lda     quit_code_save + ($100 * i), x
        sta     SELECTOR + ($100 * i), x
        .endrepeat
        dex
        bne     :-

        bit     ROMIN2

        MLI_CALL QUIT, quit_params
        DEFINE_QUIT_PARAMS quit_params

        PAD_TO ::quit_code_save
END_PROC_AT
        .assert .sizeof(quit_restore_proc) = $100, error, "Proc length mismatch"

.proc PreserveQuitCodeImpl
        quit_code_io := $800
        kQuitCodeSize = $400
        DEFINE_CREATE_PARAMS create_params, str_quit_code, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_params, str_quit_code, quit_code_io
        DEFINE_WRITE_PARAMS write_params, quit_code_addr, kQuitCodeSize
        DEFINE_CLOSE_PARAMS close_params

start:  bit     LCBANK2
        bit     LCBANK2
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

        bit     ROMIN2

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
PreserveQuitCode        := PreserveQuitCodeImpl::start


;;; ============================================================

.proc CoutStringNewline
        jsr     CoutString
        lda     #$80|CHAR_RETURN
        jmp     COUT
.endproc

.proc CoutString
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
        cpy     #SELF_MODIFIED_BYTE
        bne     :-
done:   rts
.endproc

;;; ============================================================

        .define SP_ALTZP 0
        .define SP_LCBANK1 0
        .include "../lib/smartport.s"
        ADJUSTCASE_VOLPATH := $810
        ADJUSTCASE_VOLBUF  := $820
        ADJUSTCASE_IO_BUFFER := src_io_buffer
        .include "../lib/adjustfilecase.s"

;;; ============================================================
        ;; Reserve $80 bytes for settings
        PAD_TO SETTINGS

;;; ============================================================
;;; Settings - modified by Control Panel
;;; ============================================================

        .include "../lib/default_settings.s"
