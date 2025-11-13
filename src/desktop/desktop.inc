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

;;; BTK loaded into AUX
BTKAuxEntry     := $4003
;;; LETK loaded into AUX
LETKAuxEntry    := $4006
;;; LBTK loaded into AUX
LBTKAuxEntry    := $4009
;;; OPTK loaded into AUX
OPTKAuxEntry    := $400C

;;; Desk Accessories are loaded in Main ($800-$1BFF) and Aux
;;; ($800-$1BFF) using an I/O buffer (Main $1C00-1FFF).
;;; If they show alerts, they must not use the "save area" buffer
;;; Aux $E00-$1FFF since that is used to save the alert background.
DA_LOAD_ADDRESS := $800         ; Loaded into Main
DA_IO_BUFFER    := $1C00        ; ...through $1FFF
kDAMaxSize      = DA_IO_BUFFER - DA_LOAD_ADDRESS

;;; Used by DAs for window definitions
DEFAULT_FONT    := $8800

;;; A 16k buffer that can be restored using overlays; load
;;; `kDynamicRoutineRestoreBuffer` and call `JUMP_TABLE_RESTORE_OVL`
;;; to restore DeskTop afterwards.
OVERLAY_BUFFER      := $5000
kOverlayBufferSize   = $4000

;;; DAs must start with a header declaring sizes of the two
;;; segments (aux and main).
.macro DA_HEADER
        .word   __da_aux_segment_end__ - DA_LOAD_ADDRESS
        .word   __da_main_segment_end__ - DA_LOAD_ADDRESS
.endmacro
.macro DA_START_AUX_SEGMENT
        .org DA_LOAD_ADDRESS
        DA_IN_AUX_SEGMENT .set 1
.scope aux
        MGTKEntry := MGTKAuxEntry
        BTKEntry := BTKAuxEntry
        LETKEntry := LETKAuxEntry
        LBTKEntry := LBTKAuxEntry
        ReadSetting := ReadSettingFromAux
        WriteSetting := WriteSettingFromAux

.endmacro
.macro DA_END_AUX_SEGMENT
.endscope ; aux
        DA_IN_AUX_SEGMENT .set 0
        __da_aux_segment_end__ := *
        .assert * < DA_IO_BUFFER, error, .sprintf("DA too big (at $%X)", *)
.endmacro
.macro DA_START_MAIN_SEGMENT
    .ifndef __da_aux_segment_end__
        __da_aux_segment_end__ := DA_LOAD_ADDRESS
    .endif
        .org DA_LOAD_ADDRESS
.endmacro
.macro DA_END_MAIN_SEGMENT
        __da_main_segment_end__ := *
        .assert * < DA_IO_BUFFER, error, .sprintf("DA too big (at $%X)", *)
.endmacro

        DA_IN_AUX_SEGMENT .set 0

;;; ============================================================
;;; Constants

kMaxDeskTopWindows      = 8

kShortcutCloseWindow  = res_char_shortcut_close
kShortcutGrowWindow   = res_char_shortcut_resize
kShortcutMoveWindow   = res_char_shortcut_move
kShortcutScrollWindow = res_char_shortcut_scroll

;;; ============================================================
;;; Direct Calls (from main memory)

;;; * = Used by Desk Accessories

JT_INIT $4000
JT_ENTRY JUMP_TABLE_MGTK_CALL    ; MGTK call (MLI-style, params follow) *
JT_ENTRY JUMP_TABLE_MLI_CALL     ; ProDOS MLI call (MLI-style, params follow) *
JT_ENTRY JUMP_TABLE_CLEAR_UPDATES ; Clear update events (e.g. after a drag) *
JT_ENTRY JUMP_TABLE_SYSTEM_TASK   ; Yield the event loop *
JT_ENTRY JUMP_TABLE_ACTIVATE_WINDOW ; Activate and refresh given window *
JT_ENTRY JUMP_TABLE_SHOW_ALERT    ; Show alert (A=kErrXXX or ProDOS error code, default options)
JT_ENTRY JUMP_TABLE_SHOW_ALERT_PARAMS        ; Show alert (A,X = `AlertParams`)
JT_ENTRY JUMP_TABLE_LAUNCH_FILE   ; Launch file
JT_ENTRY JUMP_TABLE_SHOW_FILE     ; Show file *
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
JT_ENTRY JUMP_TABLE_ADJUST_ONLINEENTRY; Adjust case in volume name (in: A,X=ON_LINE entry) *
JT_ENTRY JUMP_TABLE_GET_RAMCARD_FLAG  ; Returns high bit set if copied to RAMCard *
JT_ENTRY JUMP_TABLE_GET_ORIG_PREFIX   ; Returns original prefix, if copied (in: A,X=buffer) *
JT_ENTRY JUMP_TABLE_BELL          ; Play settings-specified alert sound *
JT_ENTRY JUMP_TABLE_SLOW_SPEED    ; Disable accelerator *
JT_ENTRY JUMP_TABLE_RESUME_SPEED  ; Resume accelerator *
JT_ENTRY JUMP_TABLE_READ_SETTING  ; Read setting byte (in: X=offset) *
JT_ENTRY JUMP_TABLE_GET_TICKS     ; Read 24-bit tick counter (out: A,X) *
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
kDynamicRoutineShortcutPick     = 1
kDynamicRoutineFileDialog       = 2
kDynamicRoutineFileCopy         = 3
kDynamicRoutineShortcutEdit     = 4
kDynamicRoutineRestoreSP        = 5
kDynamicRoutineRestoreFD        = 6
kDynamicRoutineRestoreBuffer       = 7

;;; ============================================================
;;; Error codes used for alerts which are not ProDOS errors

kErrUnknown             = $00
kErrInsertSystemDisk    = $FA
kErrSaveChanges         = $FB
kErrDuplicateVolName    = $FD
kErrBasicSysNotFound    = $FE

;;; ============================================================
;;; Control Transfer
;;; ============================================================

;;; Main>Aux and Aux>Main relays
CallMainToAux := $D000          ; A,X = target address in Aux
CallAuxToMain := $D000+15       ; A,X = target address in Main

.macro JSR_TO_AUX addr
        CALL CallMainToAux, AX=#addr
.endmacro

.macro JSR_TO_MAIN addr
        CALL CallAuxToMain, AX=#addr
.endmacro

;;; ============================================================
;;; Settings
;;; ============================================================

ReadSettingFromAux      := $D000+30 ; X=index, A=value (out)
WriteSettingFromAux     := $D000+39 ; X=index, A=value
