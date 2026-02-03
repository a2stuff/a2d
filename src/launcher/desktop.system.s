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
;;;   $3900  +-------------+
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
;;;          | Dir Data    |
;;;    $C00  +-------------+
;;;          |             |
;;;          | Dir I/O Buf |
;;;    $800  +-------------+
;;;          :             :

MLIEntry        := MLI

;;; I/O usage (See also: `GenericCopy`)
misc_io_buffer  :=  $E00        ; 1024 bytes for I/O
block_buffer    :=  $800        ; 512 bytes for block read
selector_buffer := $1600        ; Room for `kSelectorListBufSize`

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
        .tag    DateTime

header_orig_prefix:
        .res    64, 0           ; written into file with original path

        kWriteBackSize = * - PRODOS_SYS_START

;;; ============================================================

start:
        ;; Old ProDOS leaves interrupts inhibited on start.
        ;; Do this for good measure.
        cli

        ;; Clear stack, because ProDOS doesn't.
        ldx     #$FF
        txs

        jsr     Check128K       ; QUITs if check fails
        jsr     ClearScreenEnable80Cols
        jsr     CheckRAMEmpty   ; QUITs if user cancels

        jsr     EnsurePrefixSet
        jsr     BrandSystemFolder
        jsr     DetectMousetext
        jsr     CreateLocalDir
        jsr     PreserveQuitCode
        jsr     LoadSettings
        jsr     DetectSystem
        jmp     CopyDesktopToRAMCard

;;; ============================================================

.proc Check128K
        lda     MACHID
        and     #kMachIDHasClock
    IF ZERO
        lda     DATELO          ; Any date already set?
        ora     DATEHI
      IF ZERO
        COPY_STRUCT DateTime, header_date, DATELO
      END_IF
    END_IF

        lda     MACHID
        and     #kMachIDHas128k
        RTS_IF A = #kMachIDHas128k

        ;;  If not 128k machine, just quit back to ProDOS
        jsr     HOME
        CALL    CoutString, AX=#str_128k_required
        sta     KBDSTRB
    DO
        lda     KBD
    WHILE NC
        sta     KBDSTRB
        MLI_CALL QUIT, quit_params
        DEFINE_QUIT_PARAMS quit_params

str_128k_required:
        PASCAL_STRING res_string_128k_required

.endproc ; Check128K

;;; ============================================================

.proc ClearScreenEnable80Cols
        lda     #$FF
        sta     INVFLG
        sta     FW80MODE

        sta     KBDSTRB
        sta     TXTSET

        ;; Clear Main & AUX text screen memory so
        ;; junk doesn't show on switch to 80-column,
        ;; while protecting 'screen holes' for //c & //c+
        jsr     HOME
        sta     RAMWRTON
        lda     #$A0
        ldx     #$77
    DO
        sta     $400,x
        sta     $480,x
        sta     $500,x
        sta     $580,x
        sta     $600,x
        sta     $680,x
        sta     $700,x
        sta     $780,x
        dex
    WHILE POS
        sta     RAMWRTOFF

        ;; Turn on 80-column mode
        jsr     SLOT3ENTRY
        jsr     HOME

        ;; IIgs: Reset shadowing
        CALL    IDROUTINE, C=1
    IF CC
        .pushcpu
        .p816
        .a8
        lda     #%01111111      ; bit 7 is reserved
        trb     SHADOW          ; ensure shadowing is enabled
        lda     #%11100000      ; bits 1-4 are reserved, bit 0 unchanged
        trb     NEWVIDEO        ; color DHR, etc
        .popcpu
    END_IF
        rts
.endproc ; ClearScreenEnable80Cols

;;; ============================================================

;;; Dispatchers (e.g. Bitsy Bye) will set the prefix to the
;;; directory containing this file. But if not, we need to set
;;; it to the containing directory. The ProDOS convention for
;;; starting SYSTEM programs is that the absolute or relative
;;; path is set at $280, so use that if needed.

.proc EnsurePrefixSet
        ;; Does the current prefix contain this file?
        ;; NOTE: If everything followed the convention, we could
        ;; skip this and set the prefix unconditionally.
        MLI_CALL GET_FILE_INFO, get_file_info_params
    IF CS

        ;; Ensure path has high bits clear. Workaround for Bitsy Bye bug:
        ;; https://github.com/ProDOS-8/ProDOS8-Testing/issues/68
        ldx     PRODOS_SYS_PATH
      DO
        asl     PRODOS_SYS_PATH,x
        lsr     PRODOS_SYS_PATH,x
        dex
      WHILE NOT_ZERO

        ;; Strip last filename segment
        ldx     PRODOS_SYS_PATH
        lda     #'/'
      DO
        dex
        beq     ret
      WHILE A <> PRODOS_SYS_PATH,x
        dex
        stx     PRODOS_SYS_PATH

        ;; Set prefix
        MLI_CALL SET_PREFIX, set_prefix_params
    END_IF

ret:    rts

str_self_filename:
        PASCAL_STRING kFilenameLauncher
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, str_self_filename
        DEFINE_SET_PREFIX_PARAMS set_prefix_params, PRODOS_SYS_PATH
.endproc ; EnsurePrefixSet

;;; ============================================================

.proc BrandSystemFolder
        MLI_CALL GET_PREFIX, get_prefix_params
        MLI_CALL GET_FILE_INFO, file_info_params
    IF CC
        lda     file_info_params + 7 ; storage_type
      IF A = #ST_LINKED_DIRECTORY
        copy8   #7, file_info_params + 0 ; SET_FILE_INFO param_count
        copy16  #$8000, file_info_params + 5 ; aux_type
        MLI_CALL SET_FILE_INFO, file_info_params
      END_IF
    END_IF
        rts

prefix_buf := $800
        DEFINE_GET_PREFIX_PARAMS get_prefix_params, prefix_buf
        DEFINE_GET_FILE_INFO_PARAMS file_info_params, prefix_buf
.endproc ; BrandSystemFolder

;;; ============================================================

local_dir:      PASCAL_STRING kFilenameLocalDir
        DEFINE_CREATE_PARAMS create_localdir_params, local_dir, ACCESS_DEFAULT, FT_DIRECTORY,, ST_LINKED_DIRECTORY

.proc CreateLocalDir
        MLI_CALL CREATE, create_localdir_params
        rts
.endproc ; CreateLocalDir

;;; ============================================================

        SETTINGS_IO_BUF := misc_io_buffer
        .include "../lib/load_settings.s"
        .include "../lib/readwrite_settings.s"

;;; ============================================================

;;; Probe system capabilities, `DeskTopSettings::system_capabilities`
;;; Assert: ROM is banked in
.proc DetectSystem
        copy8   #0, syscap

        ;; IIgs?
        CALL    IDROUTINE, C=1  ; Follow detection protocol
    IF CC
        CALL    set_bit, A=#DeskTopSettings::kSysCapIsIIgs
        jmp     done_machid
    END_IF

        ;; IIc?
        lda     ZIDBYTE         ; $00 = IIc or later
    IF ZERO
        CALL    set_bit, A=#DeskTopSettings::kSysCapIsIIc

        ;; IIc Plus?
        lda     ZIDBYTE2        ; ROM version
      IF A = #$05               ; IIc Plus = $05
        CALL    set_bit, A=#DeskTopSettings::kSysCapIsIIcPlus
      END_IF
        jmp     done_machid
    END_IF

        ;; Laser 128?
        lda     IDBYTELASER128
    IF A = #$AC
        CALL    set_bit, A=#DeskTopSettings::kSysCapIsLaser128
        jmp     done_machid
    END_IF

        ;; Macintosh IIe Option Card?
        lda     ZIDBYTE
    IF A = #$E0                 ; Enhanced IIe
        lda     IDBYTEMACIIE
      IF A = #$02               ; Mac IIe Option Card
        CALL    set_bit, A=#DeskTopSettings::kSysCapIsIIeCard
        jmp     done_machid
      END_IF
    END_IF

done_machid:

        ;; Le Chat Mauve Eve?
        jsr     DetectLeChatMauveEve
    IF NOT_ZERO                 ; non-zero if LCM Eve detected
        CALL    set_bit, A=#DeskTopSettings::kSysCapLCMEve
    END_IF

        ;; Mega II?
        jsr     DetectMegaII
    IF ZERO                     ; Z=1 if Mega II, Z=0 otherwise
        CALL    set_bit, A=#DeskTopSettings::kSysCapMegaII
    END_IF

        ;; Write to settings
        TAIL_CALL WriteSetting, X=#DeskTopSettings::system_capabilities, A=syscap

.proc set_bit
        ora     syscap
        sta     syscap
        rts
.endproc ; set_bit

syscap: .byte   0

.endproc ; DetectSystem

        .include "../lib/detect_lcmeve.s"
        .include "../lib/detect_megaii.s"

;;; ============================================================
;;;
;;; Generic recursive file copy routine
;;;
;;; ============================================================

;;; Entry point is `GenericCopy::DoCopy`
;;; * Source path is `GenericCopy::pathname_src`
;;; * Destination path is `GenericCopy::pathname_dst`
;;; * Callbacks (`GenericCopy::hook_*`) must be populated

.proc GenericCopy

;;; ============================================================

ShowInsertSourceDiskPrompt:
        jmp     (hook_insert_source)

ShowCopyingScreen:
        jmp     (hook_show_file)

;;; Callbacks - caller must initialize these
hook_handle_error_code:   .addr   0 ; fatal; A = ProDOS error code or kErrCancel
hook_handle_no_space:     .addr   0 ; fatal
hook_insert_source:       .addr   0 ; if this returns, copy is retried
hook_show_file:           .addr   0 ; called when `pathname_src` updated

kErrCancel = $FF

;;; --------------------------------------------------
;;; Identifiers
;;; --------------------------------------------------

;;; For recursive copy operations
dir_io_buffer   :=  $800        ; 1024 bytes for I/O
dir_data_buffer :=  $C00        ; 256 bytes for directory data
src_io_buffer   :=  $E00        ; 1024 bytes for I/O
dst_io_buffer   := $1200        ; 1024 bytes for I/O
copy_buffer     := $3900        ; Read/Write buffer
kCopyBufferSize = MLI - copy_buffer

;;; Since this is only ever "copy to RAMCard" / "at boot" we assume it
;;; is okay if it already exists.
::kCopyIgnoreDuplicateErrorOnCreate = 1

;;; No enumeration pass before the copy, so check as we go.
::kCopyCheckSpaceAvailable = 1

;;; --------------------------------------------------
;;; Callbacks
;;; --------------------------------------------------

OpCheckCancel  := CheckCancel
OpInsertSource := ShowInsertSourceDiskPrompt
OpHandleErrorCode:
        jmp     (hook_handle_error_code)
OpHandleNoSpace:
        jmp     (hook_handle_no_space)
OpUpdateCopyProgress := ShowCopyingScreen

;;; Previously this used a jump table, but since there is only a
;;; copy operation and no enumeration (etc) the jump table was
;;; removed.
OpProcessDirectoryEntry := CopyProcessDirectoryEntry
OpFinishDirectory       := RemoveDstPathSegment

;;; --------------------------------------------------
;;; Library
;;; --------------------------------------------------

        .include "../lib/recursive_copy.s"

;;; ============================================================

.proc CheckCancel
        lda     KBD
        bpl     ret
        sta     KBDSTRB
        cmp     #$80|CHAR_ESCAPE
        beq     cancel
ret:    rts

cancel: lda     #kErrCancel
        jmp     (hook_handle_error_code)
.endproc ; CheckCancel

;;; ============================================================


.endproc ; GenericCopy

;;; ============================================================
;;;
;;; Part 1: Copy DeskTop Files to RAMCard
;;;
;;; ============================================================

.proc CopyDesktopToRAMCardImpl

;;; ============================================================
;;; Data buffers and param blocks

        ;; Used in `CheckDesktopOnDevice`
        path_buf := $D00
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params4, path_buf

unit_num:
        .byte   0

current_unit_num:
        .byte   0

;;; Index into DEVLST while iterating devices.
devnum: .byte   0

        DEFINE_SP_STATUS_PARAMS status_params, SELF_MODIFIED_BYTE, dib_buffer, SPStatusRequest::DIB

dib_buffer:     .tag SPDIB

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer
on_line_buffer: .res 17, 0

copied_flag:                    ; set to `dst_path`'s length, or reset
        .byte   0

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, src_path
        DEFINE_SET_PREFIX_PARAMS set_prefix_params, dst_path

        DEFINE_CREATE_PARAMS create_dt_dir_params, dst_path, ACCESS_DEFAULT, FT_DIRECTORY, 0, ST_LINKED_DIRECTORY
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, src_path

kNumFilenames = 5

        ;; Files/Directories to copy
str_f1: PASCAL_STRING kFilenameModulesDir
str_f2: PASCAL_STRING kFilenameLocalDir
str_f3: PASCAL_STRING kFilenameDADir
str_f4: PASCAL_STRING kFilenameExtrasDir
str_f5: PASCAL_STRING kFilenameLauncher ; last - serves as a sentinel

filename_table:
        .addr str_f1,str_f2,str_f3,str_f4,str_f5
        ASSERT_ADDRESS_TABLE_SIZE filename_table, kNumFilenames

        kHtabCopyingMsg = (80 - .strlen(res_string_copying_to_ramcard)) / 2
        kVtabCopyingMsg = 12
str_copying_to_ramcard:
        PASCAL_STRING res_string_copying_to_ramcard

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
        ;; Clear flag - ramcard not found or unknown state.
        CALL    SetCopiedToRAMCardFlag, A=#0

        ;; Remember the current volume
        copy8   DEVNUM, current_unit_num

        ;; Skip RAMCard install if flag is set
        CALL    ReadSetting, X=#DeskTopSettings::options
        and     #DeskTopSettings::kOptionsSkipRAMCard
    IF ZERO
        ;; Skip RAMCard install if button is down
        lda     BUTN0
        ora     BUTN1
        bpl     SearchDevices
    END_IF
        jmp     DidNotCopy

        ;; --------------------------------------------------
        ;; Look for RAM disk

.proc SearchDevices
        copy8   DEVCNT, devnum
    DO
        ldx     devnum
        lda     DEVLST,x
        ;; NOTE: Not masked with `UNIT_NUM_MASK` for tests below.
        sta     unit_num

        ;; Ignore current volume
        and     #UNIT_NUM_MASK
        cmp     current_unit_num
        beq     next_unit

        lda     unit_num        ; not masked

        ;; Special case for RAM.DRV.SYSTEM/RAMAUX.SYSTEM.
        cmp     #kRamDrvSystemUnitNum
        beq     test_unit_num
        cmp     #kRamAuxSystemUnitNum
        beq     test_unit_num

        ;; Smartport?
        jsr     FindSmartportDispatchAddress ; handles unmasked unit num
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
        lda     dib_buffer+SPDIB::Device_Statbyte1
        and     #$10            ; general status byte, $10 = disk in drive
        beq     next_unit

        ;; Check device type
        ;; Technical Note: SmartPort #4: SmartPort Device Types
        ;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/smpt/tn.smpt.4.html
        lda     dib_buffer+SPDIB::Device_Type_Code
        ASSERT_EQUALS SPDeviceType::MemoryExpansionCard, 0
        bne     next_unit       ; $00 = Memory Expansion Card (RAM Disk)
        lda     unit_num
        bne     test_unit_num   ; always

next_unit:
        dec     devnum
    WHILE POS
        jmp     DidNotCopy

        ;; Have a prospective device.
test_unit_num:
        ;; Verify it's online.
        lda     unit_num
        and     #UNIT_NUM_MASK  ; explicitly not masked above
        sta     on_line_params::unit_num
        MLI_CALL ON_LINE, on_line_params
        bcs     next_unit
        lda     on_line_buffer
        and     #NAME_LENGTH_MASK
        beq     next_unit

        CALL    AdjustOnLineEntryCase, AX=#on_line_buffer

        ;; Copy the name prepended with '/' to `dst_path`
        ldy     on_line_buffer
        iny
        sty     dst_path
        copy8   #'/', on_line_buffer
        sta     dst_path+1
    DO
        copy8   on_line_buffer,y, dst_path+1,y
        dey
    WHILE NOT_ZERO

        ;; Record that candidate device is found.
        CALL    SetCopiedToRAMCardFlag, A=#$C0

        ;; Keep root path (e.g. "/RAM5") for selector entry copies
        CALL    SetRAMCardPrefix, AX=#dst_path

        ;; Append app dir name, e.g. "/RAM5/DESKTOP"
        ldy     dst_path
        ldx     #0
    DO
        iny
        inx
        copy8   str_slash_desktop,x, dst_path,y
    WHILE X <> str_slash_desktop
        sty     dst_path

        ;; Is it already present?
        jsr     CheckDesktopOnDevice
        bcs     StartCopy       ; No, start copy.

        ;; Already copied - record that it was installed and grab path.
        CALL    SetCopiedToRAMCardFlag, A=#$80
        jsr     SetHeaderOrigPrefix
        jsr     CopyOrigPrefixToDesktopOrigPrefix
        copy8   dst_path, copied_flag
        jmp     FinishDeskTopCopy ; sets prefix, etc.
.endproc ; SearchDevices
.endproc ; Start

.proc SetHeaderOrigPrefix
        MLI_CALL GET_PREFIX, get_prefix_params
        dec     src_path

        ldy     src_path
    DO
        copy8   src_path,y, header_orig_prefix,y
        dey
    WHILE POS

        rts
.endproc ; SetHeaderOrigPrefix

.proc StartCopy
        ptr := $06

        jsr     ShowCopyingDeskTopScreen
        jsr     InitProgress

        ;; Record that the copy was performed.
        CALL    SetCopiedToRAMCardFlag, A=#$80

        jsr     SetHeaderOrigPrefix

        ;; --------------------------------------------------
        ;; Create desktop directory, e.g. "/RAM/DESKTOP"

        MLI_CALL CREATE, create_dt_dir_params
    IF CS AND A <> #ERR_DUPLICATE_FILENAME
        jsr     DidNotCopy
    END_IF

        ;; --------------------------------------------------
        ;; Loop over listed files to copy

        tsx                     ; In case of error
        stx     saved_stack

        copy8   dst_path, copied_flag ; reset on error
        copy8   #0, filenum

    DO
        jsr     UpdateProgress

        lda     filenum
        asl     a
        tax
        copy16  filename_table,x, ptr
        ldy     #0
        lda     (ptr),y
        tay
      DO
        copy8   (ptr),y, filename_buf,y
        dey
      WHILE POS
        jsr     CopyFile
        inc     filenum
        lda     filenum
    WHILE A <> #kNumFilenames

        jsr     UpdateProgress
        FALL_THROUGH_TO FinishDeskTopCopy
.endproc ; StartCopy

.proc FinishDeskTopCopy
        lda     copied_flag
    IF NOT_ZERO
        sta     dst_path
        MLI_CALL SET_PREFIX, set_prefix_params
    END_IF

        jsr     UpdateSelfFile
        jsr     CopyOrigPrefixToDesktopOrigPrefix

        copy8   #0, RAMWORKS_BANK ; Just in case???

        ;; Initialize system bitmap
        ldx     #BITMAP_SIZE-2
    DO
        sta     BITMAP,x
        dex
    WHILE NOT_ZERO
        copy8   #%00000001, BITMAP+BITMAP_SIZE-1 ; ProDOS global page
        copy8   #%11001111, BITMAP ; ZP, Stack, Text Page 1

        ;; Done! Move on to Part 2.
        jmp     CopySelectorEntriesToRAMCard
.endproc ; FinishDeskTopCopy

;;; ============================================================

.proc DidNotCopy
        copy8   #0, copied_flag
        jmp     FinishDeskTopCopy
.endproc ; DidNotCopy

;;; ============================================================

;;; Input: A = new flag
.proc SetCopiedToRAMCardFlag
        bit     LCBANK2
        bit     LCBANK2
        sta     COPIED_TO_RAMCARD_FLAG
        bit     ROMIN2
        rts
.endproc ; SetCopiedToRAMCardFlag

.proc GetCopiedToRAMCardFlag
        bit     LCBANK2
        bit     LCBANK2
        lda     COPIED_TO_RAMCARD_FLAG
        sta     ROMIN2
        rts
.endproc ; GetCopiedToRAMCardFlag

.proc SetRAMCardPrefix
        ptr := $6
        target := RAMCARD_PREFIX

        stax    ptr
        bit     LCBANK2
        bit     LCBANK2

        ldy     #0
        lda     (ptr),y
        tay
    DO
        copy8   (ptr),y, target,y
        dey
    WHILE POS

        bit     ROMIN2
        rts
.endproc ; SetRAMCardPrefix

.proc SetDesktopOrigPrefix
        ptr := $6
        target := DESKTOP_ORIG_PREFIX

        stax    ptr
        bit     LCBANK2
        bit     LCBANK2

        ldy     #0
        lda     (ptr),y
        tay
    DO
        copy8   (ptr),y, target,y
        dey
    WHILE POS

        bit     ROMIN2
        rts
.endproc ; SetDesktopOrigPrefix

;;; ============================================================

.proc AppendFilenameToSrcPath
        lda     filename_buf
    IF NOT_ZERO
        ldx     #0
        ldy     src_path
        copy8   #'/', src_path+1,y
      DO
        iny
        BREAK_IF X >= filename_buf
        copy8   filename_buf+1,x, src_path+1,y
        inx
      WHILE NOT_ZERO            ; always
        sty     src_path
    END_IF
        rts
.endproc ; AppendFilenameToSrcPath

;;; ============================================================

.proc RemoveFilenameFromSrcPath
        ldx     src_path
    IF NOT_ZERO
        lda     #'/'
      DO
        cmp     src_path,x
        beq     done
        dex
      WHILE NOT_ZERO
        inx

done:   dex
        stx     src_path
    END_IF
        rts
.endproc ; RemoveFilenameFromSrcPath

;;; ============================================================

.proc AppendFilenameToDstPath
        lda     filename_buf
    IF NOT_ZERO
        ldx     #0
        ldy     dst_path
        copy8   #'/', dst_path+1,y
      DO
        iny
        BREAK_IF X >= filename_buf
        copy8   filename_buf+1,x, dst_path+1,y
        inx
      WHILE NOT_ZERO            ; always
        sty     dst_path
    END_IF
        rts
.endproc ; AppendFilenameToDstPath

;;; ============================================================

.proc RemoveFilenameFromDstPath
        ldx     dst_path
    IF NOT_ZERO

        lda     #'/'
      DO
        cmp     dst_path,x
        beq     done
        dex
      WHILE NOT_ZERO
        inx

done:   dex
        stx     dst_path
    END_IF
        rts
.endproc ; RemoveFilenameFromDstPath

;;; ============================================================

.proc ShowCopyingDeskTopScreen

        ;; Message
        copy8   #kHtabCopyingMsg, OURCH
        CALL    VTABZ, A=#kVtabCopyingMsg
        CALL    CoutString, AX=#str_copying_to_ramcard

        ;; Esc to Cancel
        copy8   #kHtabCancelMsg, OURCH
        CALL    VTABZ, A=#kVtabCancelMsg
        CALL    CoutString, AX=#str_esc_to_cancel

        ;; Tip
        bit     supports_mousetext
    IF NS
        copy8   #kHtabCopyingTip, OURCH
        CALL    VTABZ, A=#kVtabCopyingTip
        CALL    CoutString, AX=#str_tip_skip_copying
    END_IF
        rts
.endproc ; ShowCopyingDeskTopScreen

;;; ============================================================
;;; Callback from copy failure; restores stack and proceeds.

.proc FailCopy
        CALL    SetCopiedToRAMCardFlag, A=#0 ; treat as no RAMCard

        ldx     saved_stack
        txs
        MLI_CALL CLOSE, close_everything_params

        jmp     DidNotCopy
.endproc ; FailCopy

;;; ============================================================
;;; Copy `filename` from `src_path` to `dst_path`

.proc CopyFile
        jsr     AppendFilenameToDstPath
        jsr     AppendFilenameToSrcPath
        MLI_CALL GET_FILE_INFO, get_file_info_params
    IF CS
        cmp     #ERR_FILE_NOT_FOUND
        beq     cleanup
        jmp     DidNotCopy
    END_IF

        ;; Set up source path
        ldy     src_path
    DO
        copy8   src_path,y, GenericCopy::pathname_src,y
        dey
    WHILE POS

        ;; Set up destination path
        ldy     dst_path
    DO
        copy8   dst_path,y, GenericCopy::pathname_dst,y
        dey
    WHILE POS

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
.endproc ; CopyFile

;;; ============================================================
;;; Input: `dst_path` set to RAMCard app dir (e.g. "/RAM5/DESKTOP")

;;; DeskTop.system itself is used as a sentinel, as it is the last
;;; file copied to the folder.

.proc CheckDesktopOnDevice
        ;; `path_buf` = `dst_path`
        COPY_STRING dst_path, path_buf

        ;; `path_buf` += "/DeskTop.system"
        ldx     path_buf
        ldy     #0
    DO
        inx
        iny
        copy8   str_sentinel_path,y, path_buf,x
    WHILE Y <> str_sentinel_path
        stx     path_buf

        ;; ... and get info
        MLI_CALL GET_FILE_INFO, get_file_info_params4
    IF CC
        cmp16   #2, get_file_info_params4::blocks_used
        ;; Ensure at least something was written to the file
        ;; (uses 1 block at creation)
    END_IF
        rts

        ;; Appended to RAMCard root path e.g. "/RAM5"
str_sentinel_path:
        PASCAL_STRING .concat("/", kFilenameLauncher)
.endproc ; CheckDesktopOnDevice

;;; ============================================================
;;; Update the live (RAM or disk) copy of this file with the
;;; original prefix.

.proc UpdateSelfFileImpl
        DEFINE_OPEN_PARAMS open_params, str_self_filename, misc_io_buffer
str_self_filename:
        PASCAL_STRING kFilenameLauncher
        DEFINE_READWRITE_PARAMS write_params, PRODOS_SYS_START, kWriteBackSize
        DEFINE_CLOSE_PARAMS close_params

start:  MLI_CALL OPEN, open_params
    IF CC
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_CALL WRITE, write_params
        MLI_CALL CLOSE, close_params
    END_IF
        rts
.endproc ; UpdateSelfFileImpl
UpdateSelfFile  := UpdateSelfFileImpl::start

;;; ============================================================

.proc CopyOrigPrefixToDesktopOrigPrefix
        CALL    SetDesktopOrigPrefix, AX=#header_orig_prefix
        rts
.endproc ; CopyOrigPrefixToDesktopOrigPrefix

;;; ============================================================

.endproc ; CopyDesktopToRAMCardImpl
CopyDesktopToRAMCard := CopyDesktopToRAMCardImpl::Start
GetCopiedToRAMCardFlag := CopyDesktopToRAMCardImpl::GetCopiedToRAMCardFlag

;;; ============================================================

        kProgressStops = CopyDesktopToRAMCardImpl::kNumFilenames + 1
        .include "../lib/loader_progress.s"

;;; ============================================================
;;;
;;; Part 2: Copy Selector Entries to RAMCard
;;;
;;; ============================================================

.proc CopySelectorEntriesToRAMCardImpl

;;; Save stack to restore on error during copy.
saved_stack:
        .byte   0

.proc Start
        sta     KBDSTRB

        ;; Clear screen
        jsr     SLOT3ENTRY
        jsr     HOME

        FALL_THROUGH_TO ProcessSelectorList
.endproc ; Start

;;; See docs/Selector_List_Format.md for file format

.proc ProcessSelectorList
        ptr := $6

        ;; Is there a RAMCard?
        jsr     GetCopiedToRAMCardFlag
        jeq     InvokeSelectorOrDesktop ; no RAMCard - skip!

        ;; Clear "Copied to RAMCard" flags
        bit     LCBANK2
        bit     LCBANK2
        ldx     #kSelectorListNumEntries-1
        lda     #0
    DO
        sta     ENTRY_COPIED_FLAGS,x
        dex
    WHILE POS
        bit     ROMIN2

        ;; Load and iterate over the selector file
        jsr     ReadSelectorList
        jne     bail

        tsx                     ; in case of error
        stx     saved_stack

        ;; Process "primary list" entries (first 8)
        copy8   #0, entry_num
    REPEAT
        lda     entry_num
        BREAK_IF A = selector_buffer + kSelectorListNumPrimaryRunListOffset
        jsr     ComputeLabelAddr
        stax    ptr

        ldy     #kSelectorEntryFlagsOffset ; Check Copy-to-RamCARD flags
        lda     (ptr),y
        ASSERT_EQUALS ::kSelectorEntryCopyOnBoot, 0
      IF ZERO
        CALL    ComputePathAddr, A=entry_num

        jsr     PrepareEntryPaths
        jsr     CopyUsingEntryPaths

        bit     LCBANK2         ; Mark copied
        bit     LCBANK2
        ldx     entry_num
        copy8   #$FF, ENTRY_COPIED_FLAGS,x
        bit     ROMIN2
      END_IF

        inc     entry_num
    FOREVER

        ;; Process "secondary run list" entries (final 16)
        copy8   #0, entry_num
    REPEAT
        lda     entry_num
        BREAK_IF A = selector_buffer + kSelectorListNumSecondaryRunListOffset
        clc
        adc     #8
        jsr     ComputeLabelAddr
        stax    ptr

        ldy     #kSelectorEntryFlagsOffset ; Check Copy-to-RamCARD flags
        lda     (ptr),y
        ASSERT_EQUALS ::kSelectorEntryCopyOnBoot, 0
      IF ZERO
        lda     entry_num
        clc
        adc     #8
        jsr     ComputePathAddr

        jsr     PrepareEntryPaths
        jsr     CopyUsingEntryPaths

        bit     LCBANK2
        bit     LCBANK2
        ldx     entry_num
        copy8   #$FF, ENTRY_COPIED_FLAGS+8,x
        bit     ROMIN2
      END_IF
        inc     entry_num
    FOREVER

bail:
        jmp     InvokeSelectorOrDesktop

entry_num:
        .byte   0
.endproc ; ProcessSelectorList

;;; ============================================================


entry_path1:  .res    ::kSelectorListPathLength, 0
entry_path2:  .res    ::kSelectorListPathLength, 0
entry_dir_name:
        .res    16, 0  ; e.g. "APPLEWORKS" from ".../APPLEWORKS/AW.SYSTEM"


;;; ============================================================

.proc CopyUsingEntryPaths
        jsr     PreparePathsFromEntryPaths

        ;; Set up destination dir path, e.g. "/RAM/APPLEWORKS"
        ldx     GenericCopy::pathname_dst ; Append '/' to `path1`
        copy8   #'/', GenericCopy::pathname_dst+1,x
        inc     GenericCopy::pathname_dst

        ldy     #0              ; Append `entry_dir_name` to `path1`
        ldx     GenericCopy::pathname_dst
    DO
        iny
        inx
        copy8   entry_dir_name,y, GenericCopy::pathname_dst,x
    WHILE Y <> entry_dir_name
        stx     GenericCopy::pathname_dst

        ;; If already exists, consider that a success
        MLI_CALL GET_FILE_INFO, gfi_params
        RTS_IF CC

        ;; Install callbacks and invoke
        copy16  #HandleErrorCode, GenericCopy::hook_handle_error_code
        copy16  #ShowNoSpacePrompt, GenericCopy::hook_handle_no_space
        copy16  #ShowInsertSourceDiskPrompt, GenericCopy::hook_insert_source
        copy16  #ShowCopyingEntryScreen, GenericCopy::hook_show_file
        jmp     GenericCopy::DoCopy

        DEFINE_GET_FILE_INFO_PARAMS gfi_params, GenericCopy::pathname_dst
.endproc ; CopyUsingEntryPaths

;;; ============================================================
;;; Copy `entry_path1/2` to `path1/2`

.proc PreparePathsFromEntryPaths

        ;; Copy `entry_path2` to `pathname_src`
        ldy     #AS_BYTE(-1)
    DO
        iny
        copy8   entry_path2,y, GenericCopy::pathname_src,y
    WHILE Y <> entry_path2

        ;; Copy `entry_path1` to `path1`
        ldy     entry_path1
    DO
        copy8   entry_path1,y, GenericCopy::pathname_dst,y
        dey
    WHILE POS

        rts
.endproc ; PreparePathsFromEntryPaths


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
.endproc ; ComputeLabelAddr

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
.endproc ; ComputePathAddr

;;; ============================================================

.proc ReadSelectorListImpl
        DEFINE_OPEN_PARAMS open_params, str_selector_list, misc_io_buffer
str_selector_list:
        PASCAL_STRING kPathnameSelectorList
        DEFINE_READWRITE_PARAMS read_params, selector_buffer, kSelectorListBufSize
        DEFINE_CLOSE_PARAMS close_params

start:  MLI_CALL OPEN, open_params
    IF CC
        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        php
        MLI_CALL CLOSE, close_params
        plp
    END_IF
        rts
.endproc ; ReadSelectorListImpl
ReadSelectorList        := ReadSelectorListImpl::start

;;; ============================================================

.proc AxTimes16
        ldx     #0
        stx     bits

        .repeat 4
        asl     a
        rol     bits
        .endrepeat

        RETURN  X=bits

bits:   .byte   0
.endproc ; AxTimes16

;;; ============================================================

.proc AxTimes64
        ldx     #0
        stx     bits

        .repeat 6
        asl     a
        rol     bits
        .endrepeat

        RETURN  X=bits

bits:   .byte   $00
.endproc ; AxTimes64

;;; ============================================================
;;; Prepare entry paths
;;; Input: A,X = address of full entry path
;;;            e.g. ".../APPLEWORKS/AW.SYSTEM"
;;; Output: `entry_path2` set to path of entry parent dir
;;;            e.g. ".../APPLEWORKS"
;;;         `entry_dir_name` set to name of entry parent dir
;;;            e.g. "APPLEWORKS"
;;;         `entry_path1` set to RAMCARD_PREFIX
;;;            e.g. "/RAM"
;;; Trashes $06

.proc PrepareEntryPaths
        ptr := $6

        stax    ptr

        ;; Copy passed address to `entry_path2`
        ldy     #0
        lda     (ptr),y
        tay
    DO
        copy8   (ptr),y, entry_path2,y
        dey
    WHILE POS

        ;; Strip last segment, e.g. ".../APPLEWORKS/AW.SYSTEM" -> ".../APPLEWORKS"
        ldy     entry_path2
        lda     #'/'
    DO
        BREAK_IF A = entry_path2,y
        dey
    WHILE NOT_ZERO
        dey
        sty     entry_path2

        ;; Find offset of parent directory name, e.g. "APPLEWORKS"
    DO
        BREAK_IF A = entry_path2,y
        dey
    WHILE POS

        ;; ... and copy to `entry_dir_name`
        ldx     #0
    DO
        iny
        inx
        copy8   entry_path2,y, entry_dir_name,x
    WHILE Y <> entry_path2
        stx     entry_dir_name

        ;; Prep `entry_path1` with `RAMCARD_PREFIX`
        bit     LCBANK2
        bit     LCBANK2
        ldy     RAMCARD_PREFIX
    DO
        copy8   RAMCARD_PREFIX,y, entry_path1,y
        dey
    WHILE POS
        bit     ROMIN2

        rts
.endproc ; PrepareEntryPaths

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

;;; Callback; used for `GenericCopy::hook_show_file`
.proc ShowCopyingEntryScreen
        jsr     HOME
        CALL    VTABZ, A=#0
        copy8   #0, OURCH
        CALL    CoutString, AX=#str_copying
        CALL    CoutStringNewline, AX=#GenericCopy::pathname_src
        rts
.endproc ; ShowCopyingEntryScreen

;;; ============================================================

;;; Callback; used for `GenericCopy::hook_insert_source`
.proc ShowInsertSourceDiskPrompt
        CALL    VTABZ, A=#0
        copy8   #0, OURCH
        CALL    CoutString, AX=#str_insert

        jsr     WaitEnterEscape
    IF A = #$80|CHAR_ESCAPE
        ldx     saved_stack
        txs
        MLI_CALL CLOSE, close_everything_params
        jmp     FinishAndInvoke
    END_IF

        jmp     HOME            ; and implicitly continue
.endproc ; ShowInsertSourceDiskPrompt

;;; ============================================================

;;; Callback; used for `GenericCopy::hook_handle_no_space`
.proc ShowNoSpacePrompt
        ldx     saved_stack
        txs
        MLI_CALL CLOSE, close_everything_params

        CALL    VTABZ, A=#0
        copy8   #0, OURCH
        CALL    CoutString, AX=#str_not_enough
        jsr     WaitEnterEscape

        jmp     FinishAndInvoke
.endproc ; ShowNoSpacePrompt

;;; ============================================================
;;; On copy failure, show an appropriate error; wait for key
;;; and invoke app.

;;; Callback; used for `GenericCopy::hook_handle_error_code`
.proc HandleErrorCode
        ldx     saved_stack
        txs
        pha
        MLI_CALL CLOSE, close_everything_params
        pla

        cmp     #GenericCopy::kErrCancel
        jeq     FinishAndInvoke

        cmp     #ERR_OVERRUN_ERROR
        jeq     ShowNoSpacePrompt

        cmp     #ERR_VOLUME_DIR_FULL
        jeq     ShowNoSpacePrompt

        ;; Show generic error
        pha
        CALL    CoutString, AX=#str_error_prefix
        pla
        jsr     PRBYTE
        CALL    CoutString, AX=#str_error_suffix
        CALL    CoutStringNewline, AX=#GenericCopy::pathname_src
        CALL    CoutString, AX=#str_not_completed

        ;; Wait for keyboard
        sta     KBDSTRB
loop:   lda     KBD
        bpl     loop
        sta     KBDSTRB

        cmp     #$80|kShortcutMonitor ; Easter Egg: If 'M', enter monitor
        beq     monitor

.if kBuildSupportsLowercase
        cmp     #$80|TO_LOWER(kShortcutMonitor)
        beq     monitor
.endif

        cmp     #$80|CHAR_RETURN
        bne     loop

        jmp     FinishAndInvoke
.endproc ; HandleErrorCode

monitor:
        jmp     MONZ

;;; ============================================================

.proc FinishAndInvoke
        jsr     HOME
        jmp     InvokeSelectorOrDesktop
.endproc ; FinishAndInvoke

;;; ============================================================

.endproc ; CopySelectorEntriesToRAMCardImpl
CopySelectorEntriesToRAMCard := CopySelectorEntriesToRAMCardImpl::Start


;;; ============================================================
;;;
;;; Part 3: Invoke Selector or DeskTop
;;;
;;; ============================================================

.proc InvokeSelectorOrDesktopImpl

        .assert * >= MODULE_BOOTSTRAP + kModuleBootstrapSize, error, "overlapping addresses"

        DEFINE_OPEN_PARAMS open_desktop_params, str_desktop, misc_io_buffer
        DEFINE_OPEN_PARAMS open_selector_params, str_selector, misc_io_buffer
        DEFINE_READWRITE_PARAMS read_params, MODULE_BOOTSTRAP, kModuleBootstrapSize

str_selector:
        PASCAL_STRING kPathnameSelector
str_desktop:
        PASCAL_STRING kPathnameDeskTop


start:  MLI_CALL CLOSE, close_everything_params

        ;; Don't try selector if flag is set
        CALL    ReadSetting, X=#DeskTopSettings::options
        and     #DeskTopSettings::kOptionsSkipSelector
    IF ZERO
        MLI_CALL OPEN, open_selector_params
        bcc     selector
    END_IF

        MLI_CALL OPEN, open_desktop_params
        bcc     desktop

        ;; But if DeskTop wasn't present, ignore options and try Selector.
        ;; This supports a Selector-only install without config, e.g. by admins.
        MLI_CALL OPEN, open_selector_params
        bcc     selector

crash:  brk                     ; just crash

desktop:
        lda     open_desktop_params::ref_num
        jmp     read

selector:
        lda     open_selector_params::ref_num


read:   sta     read_params::ref_num
        MLI_CALL READ, read_params
        php
        MLI_CALL CLOSE, close_everything_params
        plp
        ;; If the load failed, this would re-enter this code at $2000;
        ;; better to just crash.
        bne     crash

        jmp     MODULE_BOOTSTRAP
.endproc ; InvokeSelectorOrDesktopImpl
InvokeSelectorOrDesktop := InvokeSelectorOrDesktopImpl::start

;;; ============================================================

        ;; Used by `InvokeSelectorOrDesktop` so outside the danger zone
        .assert * >= MODULE_BOOTSTRAP + kModuleBootstrapSize, error, "overlapping addresses"
        DEFINE_CLOSE_PARAMS close_everything_params

;;; ============================================================
;;; Loaded at $1000 by DeskTop on Quit, and copies $1100-$13FF
;;; to Language Card Bank 2 $D100-$D3FF, to restore saved quit
;;; (selector/dispatch) handler, then does ProDOS QUIT.

quit_code_addr := $1000
quit_code_save := $1100

str_quit_code:  PASCAL_STRING kPathnameQuitSave
PROC_AT quit_restore_proc, ::quit_code_addr

        bit     LCBANK2
        bit     LCBANK2
        ldx     #0
    DO
        .repeat 3, i
        copy8   quit_code_save + ($100 * i),x, SELECTOR + ($100 * i),x
        .endrepeat
        dex
    WHILE NOT_ZERO

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
        DEFINE_READWRITE_PARAMS write_params, quit_code_addr, kQuitCodeSize
        DEFINE_CLOSE_PARAMS close_params

start:  bit     LCBANK2
        bit     LCBANK2
        ldx     #0
    DO
        copy8   quit_restore_proc,x, quit_code_addr,x
        .repeat 3, i
        copy8   SELECTOR + ($100 * i),x, quit_code_save + ($100 * i),x
        .endrepeat
        dex
    WHILE NOT_ZERO

        bit     ROMIN2

        ;; Create file (if needed)
        copy16  DATELO, create_params::create_date
        copy16  TIMELO, create_params::create_time
        MLI_CALL CREATE, create_params
    IF CS
        cmp     #ERR_DUPLICATE_FILENAME
        bne     done
    END_IF

        ;; Populate it
        MLI_CALL OPEN, open_params
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_CALL WRITE, write_params
        MLI_CALL CLOSE, close_params

done:   rts

.endproc ; PreserveQuitCodeImpl
PreserveQuitCode        := PreserveQuitCodeImpl::start


;;; ============================================================

.proc CheckRAMEmpty
        ;; See if /RAM exists
        ldx     DEVCNT
    DO
        lda     DEVLST,x
.ifndef PRODOS_2_5
        and     #$F3            ; per ProDOS 8 Technical Reference Manual
        cmp     #$B3            ; 5.2.2.3 - one of $BF, $BB, $B7, $B3
.else
        cmp     #$B0            ; ProDOS 2.5 uses $B0
.endif ; PRODOS_2_5
        beq     found
        dex
    WHILE POS

        rts                     ; not found

        DEFINE_READWRITE_BLOCK_PARAMS read_block_params, block_buffer, kVolumeDirKeyBlock

found:
        ;; Found it in DEVLST, X = index
        copy8   DEVLST,x, read_block_params::unit_num
        MLI_CALL READ_BLOCK, read_block_params
        bcs     ret

        ;; Look at file count
        lda     block_buffer + VolumeDirectoryHeader::file_count
        ora     block_buffer + VolumeDirectoryHeader::file_count+1
        beq     ret

        copy8   #kHtabRamNotEmptyMsg, OURCH
        CALL    VTABZ, A=#kVtabRamNotEmptyMsg
        CALL    CoutString, AX=#str_ram_not_empty
        jsr     WaitEnterEscape
        cmp     #$80|CHAR_ESCAPE
        beq     quit
        jsr     HOME

ret:    rts

quit:   jsr     HOME
        CALL    COUT, A=#$95    ; Ctrl-U - disable 80-col firmware
        MLI_CALL QUIT, quit_params
        DEFINE_QUIT_PARAMS quit_params

        ;; TODO: "/RAM" might not be volume name

        kHtabRamNotEmptyMsg = (80 - .strlen(res_string_prompt_ram_not_empty)) / 2
        kVtabRamNotEmptyMsg = 12
str_ram_not_empty:
        PASCAL_STRING res_string_prompt_ram_not_empty

.endproc ; CheckRAMEmpty

;;; ============================================================

.proc CoutStringNewline
        jsr     CoutString
        TAIL_CALL COUT, A=#$80|CHAR_RETURN
.endproc ; CoutStringNewline

.proc CoutString
        ptr := $6

        stax    ptr
        ldy     #0
        copy8   (ptr),y, len
    IF NOT_ZERO
      DO
        iny
        lda     ($06),y
        ora     #$80
        jsr     COUT
        len := *+1
        cpy     #SELF_MODIFIED_BYTE
      WHILE NE
    END_IF
        rts
.endproc ; CoutString

;;; ============================================================

.proc WaitEnterEscape
        sta     KBDSTRB
    DO
      DO
        lda     KBD
      WHILE NC
        sta     KBDSTRB
        BREAK_IF A = #$80|CHAR_ESCAPE
    WHILE A <> #$80|CHAR_RETURN
        rts
.endproc ; WaitEnterEscape

;;; ============================================================

        .include "../lib/smartport.s"
        ADJUSTCASE_BLOCK_BUFFER := misc_io_buffer
        .include "../lib/adjustfilecase.s"

;;; ============================================================

        .assert * <= GenericCopy::copy_buffer, error, "copy_buffer collides with code"
