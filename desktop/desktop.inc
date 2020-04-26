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
JUMP_TABLE_REDRAW_ALL   := $4015 ; Redraw all windows (e.g. after a drag) *
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
;;; Icon ToolKit Calls (from aux memory)

.scope IconTK

;;; * = Used by Desk Accessories

MLI := $8E00
        ;; MLI-style call (jsr IconTK::MLI ; .byte call ; .addr params)
        ;; Call from Aux (RAMRDON/RAMWRTON)

AddIcon         = $01   ; param is address of IconEntry
HighlightIcon   = $02   ; { .byte icon }
RedrawIcon      = $03   ; { .byte icon }
RemoveIcon      = $04   ; { .byte icon }
HighlightAll    = $05   ; { .byte window_id }
RemoveAll       = $06   ; { .byte window_id }
CloseWindow     = $07   ; { .byte window_id }
GetHighlighted  = $08   ; { .res 127 }
FindIcon        = $09   ; { .word mousex, .word mousey, .byte result }
DragHighlighted = $0A   ; { .byte param, .word mousex, .word mousey }
                        ; Input: specific icon being dragged, mouse coords
                        ; Output: 0 = on desktop (no-op)
                        ;  hi bit clear: low bits are target icon
                        ;  hi bit set:   low bits are target window
UnhighlightIcon = $0B   ; { .byte icon }
RedrawIcons     = $0C   ; Repaints desktop icons *
IconInRect      = $0D   ; { .byte icon, rect bounds }
EraseIcon       = $0E   ; { .byte icon }

;;; `icon` is the icon number, i.e. first field in icon entry
;;; `icon_index` is the index in the icon table

.endscope ; IconTK

;;; Call a IconTK entry point:
;;;     ITK_CALL n                      - params is $0000
;;;     ITK_CALL n, params_addr
;;;     ITK_CALL m, params_addr, label  - params_addr is labeled for modifying

.macro ITK_CALL    op, addr, label
        jsr     IconTK::MLI
        .byte   op

    .if .paramcount > 2
label   := *
    .endif

    .if .paramcount > 1
        .addr   addr
    .else
        .addr   0
    .endif
.endmacro


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

;;; Icon (file/volume) entries - length 27 bytes, maximum of 127
;;;      .byte icon      icon index
;;;      .byte state     $80 = highlighted, 0 = otherwise
;;;      .byte type/window_id
;;;                      (bits 0-3 window_id)
;;;                      (bits 4,5,6)
;;;                             000 = directory
;;;                             001 = system
;;;                             010 = binary (maybe runnable)
;;;                             011 = basic
;;;                             100 = (unused)
;;;                             101 = data (text/generic/...)
;;;                             110 = (unused)
;;;                             111 = trash
;;;                      (bit 7 = open flag)
;;;      .word iconx     (pixels)
;;;      .word icony     (pixels)
;;;      .addr iconbits  (addr of {mapbits, mapwidth, reserved, maprect})
;;;      .byte len       (name length + 2)
;;;      .res  17  name  (name, with a space before and after)

.struct IconEntry
        id              .byte   ; 0
        state           .byte   ; 1
        win_type        .byte   ; 2
        iconx           .word   ; 3
        icony           .word   ; 5
        iconbits        .addr   ; 7
        len             .byte   ; 9
        name            .res 17 ; 10 (15 chars plus leading/trailing spaces)
.endstruct

kMaxIconCount   = 127

kIconEntryOpenMask    = %10000000
kIconEntryTypeMask    = %01110000
kIconEntryWinIdMask   = %00001111
kIconEntryTypeDir     = %00000000
kIconEntryTypeSystem  = %00010000
kIconEntryTypeBinary  = %00100000
kIconEntryTypeBasic   = %00110000
kIconEntryTypeGeneric = %01010000
kIconEntryTypeTrash   = %01110000

;;; ============================================================
;;; Internals - Default Font

;;; Used by DAs for window definitions
DEFAULT_FONT := $8800

;;; ============================================================
;;; Internals - Settings (modified by Control Panel)

SETTINGS        := $FF80
