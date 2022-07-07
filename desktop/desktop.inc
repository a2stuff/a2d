;;; ============================================================
;;; DeskTop - Public Definitions
;;; ============================================================
;;; Used by:
;;;  * DeskTop itself
;;;  * DeskTop.system (launcher)
;;;  * Desk Accessories & Preview Accessories
;;; ============================================================

;;; MGTK loaded into AUX; to call from MAIN use JUMP_TABLE_MGTK_CALL
MGTKAuxEntry    := $4000

;;; Desk Accessories are loaded in Main ($800-$1BFF) using
;;; an I/O buffer (Main $1C00-1FFF). DAs often copy themselves
;;; into Aux but can only use $800-$1AFF due to entry tables.
;;; If they show alerts, they must not use scratch area (below).

DA_LOAD_ADDRESS := $800         ; Loaded into Main
DA_IO_BUFFER    := $1C00        ; ...through $1FFF
kDAMaxSize      = DA_IO_BUFFER - DA_LOAD_ADDRESS

;;; Memory in Aux - $80 bytes for desktop and 8 windows. First byte is a
;;; count, up to 127 entries. Entries are icon numbers if in icon view.
;;; $1F80-$1FFF is a map of used/free icon numbers.
WINDOW_ENTRY_TABLES      := $1B00

;;; Used by DAs for window definitions
DEFAULT_FONT    := $8600

;;; Settings loaded from disk on startup.
SETTINGS        := $FF80 - kIntVectorsSize
BELLDATA        := SETTINGS - kBellProcLength

;;; A 10k buffer that can be restored using overlays; load
;;; `kDynamicRoutineRestore5000` and call `JUMP_TABLE_RESTORE_OVL`
;;; to restore DeskTop afterwards.
OVERLAY_10K_BUFFER      := $5000
kOverlay10KBufferSize   = $2800

;;; ============================================================
;;; Constants

kMaxDeskTopWindows      = 8


;;; ============================================================
;;; Direct Calls (from main memory)

;;; * = Used by Desk Accessories

JT_INIT $4000
JT_ENTRY JUMP_TABLE_MGTK_CALL    ; MGTK call (MLI-style, params follow) *
JT_ENTRY JUMP_TABLE_MLI_CALL     ; ProDOS MLI call (MLI-style, params follow) *
JT_ENTRY JUMP_TABLE_CLEAR_UPDATES ; Clear update events (e.g. after a drag) *
JT_ENTRY JUMP_TABLE_YIELD_LOOP    ; Yield the event loop *
JT_ENTRY JUMP_TABLE_SELECT_WINDOW ; Select and refresh given window *
JT_ENTRY JUMP_TABLE_SHOW_ALERT    ; Show alert (A=kErrXXX or ProDOS error code, default options)
JT_ENTRY JUMP_TABLE_SHOW_ALERT_OPTIONS       ; Show alert X (A=err code, X=options)
JT_ENTRY JUMP_TABLE_LAUNCH_FILE   ; Launch file
JT_ENTRY JUMP_TABLE_CUR_POINTER   ; Changes mouse cursor to pointer *
JT_ENTRY JUMP_TABLE_CUR_WATCH     ; Changes mouse cursor to watch *
JT_ENTRY JUMP_TABLE_CUR_IBEAM     ; Changes mouse cursor to I-beam *
JT_ENTRY JUMP_TABLE_RESTORE_OVL   ; Restore from overlay routine
JT_ENTRY JUMP_TABLE_COLOR_MODE    ; Set DHR color mode (IIgs, AppleColor, Le Chat Mauve) *
JT_ENTRY JUMP_TABLE_MONO_MODE     ; Set DHR mono mode (IIgs, AppleColor, Le Chat Mauve) *
JT_ENTRY JUMP_TABLE_RGB_MODE      ; Reset DHR mode to settings (IIgs, AppleColor, Le Chat Mauve) *
JT_ENTRY JUMP_TABLE_RESTORE_SYS   ; Exit DHR, restore devices and /RAM, bank in ROM and ZP. *
JT_ENTRY JUMP_TABLE_GET_SEL_COUNT ; Get number of selected icons (out: A=count) *
JT_ENTRY JUMP_TABLE_GET_SEL_ICON  ; Get selected IconEntry address (in: A=index, out: A,X=addr) *
JT_ENTRY JUMP_TABLE_GET_SEL_WIN   ; Get window containing selection (out: A=window_id, 0 if none) *
JT_ENTRY JUMP_TABLE_GET_WIN_PATH  ; Get path to window (in: A=window_id; out: A,X=path address) *
JT_ENTRY JUMP_TABLE_HILITE_MENU   ; Toggle hilite on last clicked menu *
JT_ENTRY JUMP_TABLE_ADJUST_FILEENTRY  ; Adjust case in FileEntry structure (in: A,X=FileEntry) *
JT_ENTRY JUMP_TABLE_GET_RAMCARD_FLAG  ; Returns high bit set if copied to RAMCard *
JT_ENTRY JUMP_TABLE_GET_ORIG_PREFIX   ; Returns original prefix, if copied (in: A,X=buffer) *
JT_ENTRY JUMP_TABLE_BELL          ; Play settings-specified alert sound *
JT_ENTRY JUMP_TABLE_LAST

;;; ============================================================
;;; Call MGTK
;;;     JUMP_TABLE_MGTK_CALL n - params is $0000
;;;     JUMP_TABLE_MGTK_CALL n, params_addr
;;;     JUMP_TABLE_MGTK_CALL m, params_addr, label  - params_addr is labeled for modifying

.macro  JUMP_TABLE_MGTK_CALL    op, addr, label
        jsr JUMP_TABLE_MGTK_CALL
        .byte op
.if .paramcount > 2
        label := *
.endif
.if .paramcount > 1
        .addr addr
.else
        .addr 0
.endif
.endmacro

;;; ============================================================
;;; Call ProDOS MLI
;;;     JUMP_TABLE_MLI_CALL n - params is $0000
;;;     JUMP_TABLE_MLI_CALL n, params_addr
;;;     JUMP_TABLE_MLI_CALL m, params_addr, label  - params_addr is labeled for modifying

.macro  JUMP_TABLE_MLI_CALL    op, addr, label
        jsr JUMP_TABLE_MLI_CALL
        .byte op
.if .paramcount > 2
        label := *
.endif
.if .paramcount > 1
        .addr addr
.else
        .addr 0
.endif
.endmacro

;;; ============================================================
;;; Overlay routines, for JUMP_TABLE_LOAD_OVL

kDynamicRoutineFormatErase      = 0
kDynamicRoutineSelector1        = 1
kDynamicRoutineFileDialog       = 2
kDynamicRoutineFileCopy         = 3
kDynamicRoutineFileDelete       = 4
kDynamicRoutineSelector2        = 5
kDynamicRoutineRestore5000      = 6
kDynamicRoutineRestore9000      = 7

;;; ============================================================
;;; Results from JUMP_TABLE_SHOW_ALERT / JUMP_TABLE_SHOW_ALERT_OPTIONS

kAlertResultTryAgain    = 0
kAlertResultCancel      = 1
kAlertResultOK          = 2
;;; NOTE: Selector and Disk Copy have OK = 0 (same as Try Again) and
;;; therefore only distinguish Cancel. See the Rename code in DeskTop
;;; for a use case for having them differ, namely where the error code
;;; determines the options (OK vs. Try Again / Cancel), and OK after a
;;; failure is the same as Cancel (give up), not Try Again.

;;; ============================================================
;;; Error codes used for alerts which are not ProDOS errors

kErrInsertSystemDisk    = $E0
kErrSelectorListFull    = $E1
kErrWindowMustBeClosed  = $E2
kErrTooManyFiles        = $E3
kErrTooManyWindows      = $E4
kErrSaveChanges         = $E5

kErrBadReplacement      = $F5
kErrUnsupportedFileType = $F6
kErrNoWindowsOpen       = $F7
kErrMoveCopyIntoSelf    = $F8
kErrDuplicateVolName    = $F9
kErrFileNotOpenable     = $FA
kErrNameTooLong         = $FB
kErrInsertSrcDisk       = $FC
kErrInsertDstDisk       = $FD
kErrBasicSysNotFound    = $FE

;;; ============================================================
;;; Warning messages (JUMP_TABLE_SHOW_WARNING)

kNumWarningTypes = 6
