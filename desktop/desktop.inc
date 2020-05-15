;;; ============================================================
;;; DeskTop - Public Definitions
;;; ============================================================
;;; Used by:
;;;  * DeskTop itself
;;;  * DeskTop.system (launcher)
;;;  * Desk Accessories & Preview Accessories
;;; ============================================================

;;; DeskTop init routine, after all segments are loaded.

DESKTOP_INIT    := $0800

;;; Desk Accessories are loaded in Main ($800-$1BFF) using
;;; an I/O buffer (Main $1C00-1FFF). DAs often copy themselves
;;; into Aux but can only use $800-$1AFF due to icon tables.
;;; If they show alerts, they must not use scratch area (below).

DA_LOAD_ADDRESS := $800         ; Loaded into Main
DA_IO_BUFFER    := $1C00        ; ...through $1FFF
kDAMaxSize      = DA_IO_BUFFER - DA_LOAD_ADDRESS

;;; Memory in Aux - $80 bytes for desktop and 8 windows. First byte is a
;;; count, up to 127 icon entries. $1F80-$1FFF is a map of used/free icon
;;; numbers.
WINDOW_ICON_TABLES := $1B00

;;; ============================================================
;;; Direct Calls (from main memory)

;;; * = Used by Desk Accessories

JUMP_TABLE_MAIN_LOOP    := $4000 ; Enter DeskTop main loop
JUMP_TABLE_MGTK_RELAY   := $4003 ; MGTK relay call (main>aux)
JUMP_TABLE_SIZE_STRING  := $4006 ; Compose "nnn Blocks" string into internal buffer
JUMP_TABLE_DATE_STRING  := $4009 ; Compose date string into internal buffer
JUMP_TABLE_SELECT_WINDOW:= $400C ; Select and refresh given window
JUMP_TABLE_AUXLOAD      := $400F ; Auxload
JUMP_TABLE_EJECT        := $4012 ; Eject command
JUMP_TABLE_REDRAW_WINDOWS := $4015 ; Redraw all desktop windows (e.g. after a drag) *
JUMP_TABLE_ITK_RELAY    := $4018 ; Icon ToolKit relay call (main>aux)
JUMP_TABLE_LOAD_OVL     := $401B ; Load overlay routine
JUMP_TABLE_CLEAR_SEL    := $401E ; Clear DeskTop selection *
JUMP_TABLE_MLI          := $4021 ; ProDOS MLI call (Y=call, X,A=params addr) *
JUMP_TABLE_COPY_TO_BUF  := $4024 ; Copy to buffer
JUMP_TABLE_COPY_FROM_BUF:= $4027 ; Copy from buffer
JUMP_TABLE_NOOP         := $402A ; No-Op command (RTS)
JUMP_TABLE_FILE_TYPE_STRING := $402D ; Compose file type string into internal buffer
JUMP_TABLE_ALERT_0      := $4030 ; Show alert (A=err code, default options)
JUMP_TABLE_ALERT_X      := $4033 ; Show alert X (A=err code, X=options)
JUMP_TABLE_LAUNCH_FILE  := $4036 ; Launch file
JUMP_TABLE_CUR_POINTER  := $4039 ; Changes mouse cursor to pointer *
JUMP_TABLE_CUR_WATCH    := $403C ; Changes mouse cursor to watch
JUMP_TABLE_RESTORE_OVL  := $403F ; Restore from overlay routine
JUMP_TABLE_COLOR_MODE   := $4042 ; Set DHR color mode (IIgs, AppleColor, Le Chat Mauve) *
JUMP_TABLE_MONO_MODE    := $4045 ; Set DHR mono mode (IIgs, AppleColor, Le Chat Mauve) *
JUMP_TABLE_RESTORE_SYS  := $4048 ; Exit DHR, restore devices and /RAM, bank in ROM and ZP. *
JUMP_TABLE_REDRAW_ALL   := $404B ; Redraw desktop windows and icons (e.g. after a drag) *

;;; ============================================================
;;; Overlay routines, for JUMP_TABLE_LOAD_OVL

kDynamicRoutineDiskCopy         = 0
kDynamicRoutineFormatErase      = 1
kDynamicRoutineSelector1        = 2
kDynamicRoutineFileDialog       = 3
kDynamicRoutineFileCopy         = 4
kDynamicRoutineFileDelete       = 5
kDynamicRoutineSelector2        = 6
kDynamicRoutineRestore5000      = 7
kDynamicRoutineRestore9000      = 8

;;; ============================================================
;;; Options/Results from JUMP_TABLE_ALERT_0 / JUMP_TABLE_ALERT_X

kAlertOptionsDefault            = 0
kAlertOptionsOK                 = 0 ; Used internally only, callers would pass $01
kAlertOptionsTryAgainCancel     = $80
kAlertOptionsOKCancel           = $C0

kAlertResultTryAgain    = 0
kAlertResultCancel      = 1
kAlertResultOK          = 2

;;; ============================================================
;;; Error codes used for alerts which are not ProDOS errors

kErrDuplicateVolName    = $F9
kErrFileNotOpenable     = $FA
kErrNameTooLong         = $FB
kErrInsertSrcDisk       = $FC
kErrInsertDstDisk       = $FD
kErrBasicSysNotFound    = $FE

;;; ============================================================
;;; Internals - Windows (paths) and Icons (files)

;;; NOTE: Some of these are used by Desk Accessories

;;; These are DeskTop internals, but it appears there is no
;;; API for getting the selected file.
selected_file_count := $DF21

path_index := $DF20     ; index of selected window (used to get prefix)
path_table := $DFB3     ; window address table
;;; each entry is 65 bytes long
;;;      length-prefixed path string (no trailing /)

selected_file_list := $DF22     ; indexes of selected file (global, not w/in window, up to 127)
file_table := $DD9F     ; file address table

last_menu_click_params := $E23D

;;; ============================================================
;;; Internals - Default Font

;;; Used by DAs for window definitions
DEFAULT_FONT := $8800

;;; ============================================================
;;; Internals - Settings (modified by Control Panel)

SETTINGS        := $FF80
