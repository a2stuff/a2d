;;; ==================================================
;;; DeskTop Internals
;;; ==================================================

DA_LOAD_ADDRESS := $800
DA_MAX_SIZE     := $1C00 - DA_LOAD_ADDRESS

;;; ==================================================
;;; Direct Calls (from main memory)

;;; * = Used by Desk Accessories

JUMP_TABLE_00           := $4000 ; ???
JUMP_TABLE_MGTK_RELAY   := $4003 ; MGTK relay call (main>aux)
JUMP_TABLE_06           := $4006 ; ???
JUMP_TABLE_09           := $4009 ; ???
JUMP_TABLE_0C           := $400C ; ???
JUMP_TABLE_0F           := $400F ; Auxload
JUMP_TABLE_EJECT        := $4012 ; Eject command
JUMP_TABLE_REDRAW_ALL   := $4015 ; Redraw all windows (e.g. after a drag) *
JUMP_TABLE_DESKTOP_RELAY:= $4018 ; DESKTOP relay call (main>aux)
JUMP_TABLE_LOAD_SEG     := $401B ; Load dynamic routine
JUMP_TABLE_CLEAR_SEL    := $401E ; Clear DeskTop selection *
JUMP_TABLE_MLI          := $4021 ; ProDOS MLI call (Y=call, X,A=params addr) *
JUMP_TABLE_COPY_TO_BUF  := $4024 ; Copy to buffer
JUMP_TABLE_COPY_FROM_BUF:= $4027 ; Copy from buffer
JUMP_TABLE_NOOP         := $402A ; No-Op command (RTS)
JUMP_TABLE_2D           := $402D ; ??? (Draw type/size/date in non-icon views?)
JUMP_TABLE_30           := $4030 ; Show alert 0
JUMP_TABLE_33           := $4033 ; Show alert X
JUMP_TABLE_LAUNCH_FILE  := $4036 ; Launch file
JUMP_TABLE_CUR_POINTER  := $4039 ; Changes mouse cursor to pointer *
JUMP_TABLE_CUR_WATCH    := $403C ; Changes mouse cursor to watch
JUMP_TABLE_RESTORE_SEG  := $403F ; Restore from dynamic routine

;;; ==================================================
;;; API Calls (from aux memory)

;;; * = Used by Desk Accessories

DESKTOP    := $8E00
        ;; MLI-style call (jsr DEKSTOP ; .byte call ; .addr params)
        ;; Call from AUX (RAMRDON/RAMWRTON)

        ;; Implementation bounces to $93BC, uses jump table at $939E

DT_ADD_ICON             := $01  ; { .addr icondata }
DT_HIGHLIGHT_ICON       := $02  ; { .byte icon }
DT_UNHIGHLIGHT_ICON     := $03  ; { .byte icon }
        ;; $06 ???
DT_CLOSE_WINDOW         := $07  ; { .byte window_id }
DT_FIND_ICON            := $09  ; { .word mousex, .word mousey, .byte result }

DT_REDRAW_ICONS         := $0C  ; Repaints desktop icons *
DT_ICON_IN_RECT         := $0D  ; { .byte icon, rect bounds }


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


;;; ==================================================
;;; Internals - Windows (paths) and Icons (files)

;;; NOTE: Some of these are used by Desk Accessories

;; These are DeskTop internals, but it appears there is no
;; API for getting the selected file.
file_selected := $DF21  ; 0 if no selection, 1 otherwise

path_index := $DF20     ; index of selected window (used to get prefix)
path_table := $DFB3     ; window address table
;; each entry is 65 bytes long
;;      length-prefixed path string (no trailing /)

file_index := $DF22     ; indexes of selected file (global, not w/in window, up to 127)
file_table := $DD9F     ; file address table
;; each entry is 27 bytes long
;;      .byte icon      icon index
;;      .byte ??
;;      .byte type/icon (bits 4,5,6 clear = directory; $70=trash, $80=profile, $01=folder, $11=sys, $21=bin, ???)
;;      .word iconx     (pixels)
;;      .word icony     (pixels)
;;      .addr iconbits  (addr of {mapbits, mapwidth, reserved, maprect})
;;      .byte len       (name length + 2)
;;      .res  17  name  (name, with a space before and after)


;;; ==================================================
;;; Internals - Default Font

;;; Used by DAs for window definitions
DEFAULT_FONT := $8800

;;; Modified by Show Text File DA to toggle fixed width
font_flag       := $8800 ; = $00 - if high bit set, glyphs are 2 bytes wide (???)
font_size_count := $8801 ; = $7F - max glyph number (count is this + 1)
font_height     := $8802 ; 9 pixels
font_width_table := $8803 ; width in pixels, indexed by ASCII code

font_glyphs     := $8883 ; $80 glyphs, organized by row, 9 bytes per

;;; So glyph for A $41
;;;  width is at $8803 + $41 = $8844 which is 7
;;;  row0 is at $8883 + $41 + (0 * $80) = $88C4 ~ $1E = %00011110
;;;  row1 is at $8883 + $41 + (1 * $80) = $8944 ~ $33 = %00110011
;;; etc

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
;;; $08 = larrow               $18 = close        (MT:])
;;; $09 = left box             $19 = gray odd     (MT:W)
;;; $0A = darrow       (MT:J)  $1A = gray even    (MT:V)
;;; $0B = uarrow       (MT:K)  $1B = solid circ
;;; $0C = right box            $1C = inv check    (MT:E)
;;; $0D = return       (MT:M)  $1D = check        (MT:D)
;;; $0E = (C)                  $1E = solid apple  (MT:@)
;;; $0F = (R)                  $1F = open apple   (MT:A)

GLYPH_LARROW := $09
GLYPH_RARROW := $15
GLYPH_UARROW := $0B
GLYPH_DARROW := $0A
GLYPH_RETURN := $0D
GLYPH_OAPPLE := $1F
GLYPH_SAPPLE := $1E

;;; Menu (by default) uses:
;;;   Solid Mod   $1E
;;;   Open Mod    $1F
;;;   Check       $1D
;;;   Control     $01
;;;   Inactive    $7F
