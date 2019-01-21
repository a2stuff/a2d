;;; ============================================================
;;; DeskTop Internals
;;; ============================================================

screen_width    = 560
screen_height   = 192

;;; ============================================================

VERSION_MAJOR = 1
VERSION_MINOR = 2
.define VERSION_SUFFIX "-alpha1"

DA_FILE_TYPE    = $F1

max_desk_acc_count = 12

INVOKER                 := $290 ; Invoke other programs
INVOKER_FILENAME        := $280 ; File to invoke (PREFIX must be set)

DA_LOAD_ADDRESS := $800         ; Loaded into MAIN
DA_IO_BUFFER    := $1C00        ; ...through $1FFF
DA_MAX_SIZE     = DA_IO_BUFFER - DA_LOAD_ADDRESS
        ;; Can't load DA past I/O Buffer at MAIN $1C00,
        ;; but icon tables start at AUX $1B00 so can't clone there.

;;; Memory in AUX - $80 bytes for desktop and 8 windows. First byte is a
;;; count, up to 127 icon entries. $1F80-$1FFF is a map of used/free icon
;;; numbers.
WINDOW_ICON_TABLES := $1B00

        ;; Quit routine signature/data
        copied_to_ramcard_flag := $D3FF
        ramcard_prefix := $D3EE
        desktop_orig_prefix := $D3AD

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
JUMP_TABLE_DESKTOP_RELAY:= $4018 ; DESKTOP relay call (main>aux)
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
;;; Error codes used for alerts which are not ProDOS errors

ERR_DUPLICATE_VOL_NAME  = $F9
ERR_FILE_NOT_OPENABLE   = $FA
ERR_NAME_TOO_LONG       = $FB
ERR_INSERT_SRC_DISK     = $FC
ERR_INSERT_DST_DISK     = $FD
ERR_BASIC_SYS_NOT_FOUND = $FE

;;; ============================================================
;;; API Calls (from aux memory)

;;; * = Used by Desk Accessories

DESKTOP    := $8E00
        ;; MLI-style call (jsr DEKSTOP ; .byte call ; .addr params)
        ;; Call from AUX (RAMRDON/RAMWRTON)

        ;; Implementation bounces to $93BC, uses jump table at $939E

DT_ADD_ICON             = $01   ; { .addr icondata }
DT_HIGHLIGHT_ICON       = $02   ; { .byte icon }
DT_REDRAW_ICON          = $03   ; { .byte icon }
DT_REMOVE_ICON          = $04   ; { .byte icon }
DT_HIGHLIGHT_ALL        = $05   ; { .byte window_id }
DT_UNHIGHLIGHT_ALL      = $06
DT_CLOSE_WINDOW         = $07   ; { .byte window_id }
DT_GET_HIGHLIGHTED      = $08   ; { .res 20 }
DT_FIND_ICON            = $09   ; { .word mousex, .word mousey, .byte result }
DT_DRAG_HIGHLIGHTED     = $0A   ; { .byte param }
                                ; Input: specific icon being dragged
                                ; Output: 0 = on desktop (no-op)
                                ;  hi bit clear: low bits are target icon
                                ;  hi bit set:   low bits are target window
DT_UNHIGHLIGHT_ICON     = $0B   ; { .addr iconentry }
DT_REDRAW_ICONS         = $0C   ; Repaints desktop icons *
DT_ICON_IN_RECT         = $0D   ; { .byte icon, rect bounds }
DT_REDRAW_ICON_IDX      = $0E   ; { .byte icon_index }

;;; `icon` is the icon number, i.e. first field in icon entry
;;; `icon_index` is the index in the icon table

;;; Call a DESKTOP entry point:
;;;     DESKTOP_CALL n                      - params is $0000
;;;     DESKTOP_CALL n, params_addr
;;;     DESKTOP_CALL m, params_addr, label  - params_addr is labeled for modifying

.macro DESKTOP_CALL    op, addr, label
        jsr     DESKTOP
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
;;; Relays from Main to Aux (params must be in ZP or LC)

MGTK_RELAY      := $D000
DESKTOP_RELAY   := $D040

.macro MGTK_RELAY_CALL call, addr
    .if .paramcount > 1
        yax_call        MGTK_RELAY, (call), (addr)
    .else
        yax_call        MGTK_RELAY, (call), 0
    .endif
.endmacro

.macro DESKTOP_RELAY_CALL call, addr
    .if .paramcount > 1
        yax_call        DESKTOP_RELAY, (call), (addr)
    .else
        yax_call        DESKTOP_RELAY, (call), 0
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
        id              .byte
        state           .byte
        win_type        .byte
        iconx           .word
        icony           .word
        iconbits        .addr
        len             .byte
        name            .res 17 ; 15 chars plus leading/trailing spaces
.endstruct

max_icon_count  = 127

icon_entry_open_mask    = %10000000
icon_entry_type_mask    = %01110000
icon_entry_winid_mask   = %00001111
icon_entry_type_dir     = %00000000
icon_entry_type_system  = %00010000
icon_entry_type_binary  = %00100000
icon_entry_type_basic   = %00110000
icon_entry_type_generic = %01010000
icon_entry_type_trash   = %01110000

;;; ============================================================
;;; Internals - Default Font

;;; Used by DAs for window definitions
DEFAULT_FONT := $8800

;;; Control Character Glyphs
;;;
;;; Glyphs $00-$1F are useful symbols; some overlap with MouseText
;;; (called out as MT:X in the table below)
;;;
;;; $00 = space                $10 = TM left
;;; $01 = folder left  (MT:X)  $11 = TM right
;;; $02 = folder right (MT:Y)  $12 = pound
;;; $03 = hourglass    (MT:C)  $13 = pi
;;; $04 = insertion pt         $14 = divide
;;; $05 = pointer      (MT:B)  $15 = rarrow       (MT:U)
;;; $06 = vbar         (MT:_)  $16 = tri
;;; $07 = hbar         (MT:S)  $17 = open circ
;;; $08 = larrow       (MT:H)  $18 = close        (MT:])
;;; $09 = left box             $19 = gray odd     (MT:W)
;;; $0A = darrow       (MT:J)  $1A = gray even    (MT:V)
;;; $0B = uarrow       (MT:K)  $1B = solid circ
;;; $0C = right box            $1C = inv check    (MT:E)
;;; $0D = return       (MT:M)  $1D = check        (MT:D)
;;; $0E = (C)                  $1E = solid apple  (MT:@)
;;; $0F = (R)                  $1F = open apple   (MT:A)

GLYPH_FOLDERL = $01
GLYPH_FOLDERR = $02

GLYPH_SPC     = $00
GLYPH_INSPT   = $06

GLYPH_LARROW  = $08
GLYPH_RARROW  = $15
GLYPH_UARROW  = $0B
GLYPH_DARROW  = $0A
GLYPH_RETURN  = $0D
GLYPH_OAPPLE  = $1F
GLYPH_SAPPLE  = $1E

;;; Menu (by default) uses:
;;;   Solid Mod   $1E
;;;   Open Mod    $1F
;;;   Check       $1D
;;;   Control     $01
;;;   Inactive    $7F

;;; ============================================================
;;; Internals - miscellaneous structures

.struct IconDefinition
        ;; First part is MGTK::MapInfo without leading viewloc
        mapbits         .addr   ; address of bitmap bits
        mapwidth        .byte   ; stride of bitmap bits
        reserved        .byte   ; 0
        maprect         .tag MGTK::Rect ; x1,y1 must be 0,0

        ;; Next part is address of mask bits; must be same
        ;; dimensions as rect of icon.
        maskbits        .addr
.endstruct

.macro  DEFICON mapbits, mapwidth, dx, dy, maskbits
        ;; First part is MGTK::MapInfo without leading viewloc
        .addr   mapbits
        .byte   mapwidth
        .byte   0             ; reserved
        .word   0, 0, dx, dy  ; maprect
        ;; Next part is link to mask
        .addr   maskbits
.endmacro

.struct FileRecord
        name                    .res 16
        file_type               .byte ; 16 $10
        blocks                  .word ; 17 $11
        creation_date           .word ; 19 $13
        creation_time           .word ; 21 $15
        modification_date       .word ; 23 $17
        modification_time       .word ; 25 $19
        access                  .byte ; 27 $1B
        header_pointer          .word ; 28 $1C
        reserved                .word ; ???
.endstruct
