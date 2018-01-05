;;; ==================================================
;;; DeskTop Internals
;;; ==================================================

;;; ==================================================
;;; Direct Calls

;;; NOTE: Some of these are used by Desk Accessories

        ;; These must be called from main memory (RAMRDOFF/RAMWRTOFF)
JUMP_TABLE_03   := $4003        ; Enter DeskTop input loop
JUMP_TABLE_06   := $4006        ; ???
JUMP_TABLE_09   := $4009        ; ???
JUMP_TABLE_0C   := $400C        ; ??? (made "items/in disk/..." redraw oddly)
JUMP_TABLE_0F   := $400F        ; ???
JUMP_TABLE_12   := $4012        ; ???
JUMP_TABLE_REDRAW_ALL  := $4015 ; Redraw all windows (e.g. after a drag)
JUMP_TABLE_18   := $4018        ; ???
JUMP_TABLE_CLEAR_SEL   := $401E ; Clear DeskTop selection
JUMP_TABLE_MLI  := $4021        ; ProDOS MLI call (Y=call, X,A=params addr)
JUMP_TABLE_24   := $4024        ; ???
JUMP_TABLE_27   := $4027        ; ???
JUMP_TABLE_2A   := $402A        ; Just an RTS
JUMP_TABLE_2D   := $402D        ; Draw type/size/date in non-icon views
JUMP_TABLE_30   := $4030        ; ???
JUMP_TABLE_33   := $4033        ; Shows "The syntax of the pathname is invalid.", hangs
JUMP_TABLE_36   := $4036        ; ditto
JUMP_TABLE_CUR_POINTER  := $4039 ; Changes mouse cursor to pointer
JUMP_TABLE_CUR_WATCH    := $403C ; Changes mouse cursor to watch
JUMP_TABLE_3F   := $403F        ; ???

;;; ==================================================
;;; API Calls

;;; NOTE: Some of these are used by Desk Accessories

DESKTOP    := $8E00
        ;; MLI-style call (jsr A2D ; .byte call ; .addr params)
        ;; Call from AUX (RAMRDON/RAMWRTON)

        ;; Implementation bounces to $93BC, uses jump table at $939E

        ;; $02 ???
        ;; $03 ???
        ;; $06 ???
        ;; $07 ???

DESKTOP_REDRAW_ICONS := $0C     ; Repaints desktop icons

        ;; $0D used at start of drag-select
        ;; $09 at end (then another $0D)

;;; Call a DESKTOP entry point:
;;;     DESKTOP_CALL n                      - params is $0000
;;;     DESKTOP_CALL n, params_addr
;;;     DESKTOP_CALL m, params_addr, label  - params_addr is labeled for modifying

.macro  DESKTOP_CALL    op, addr, label
        jsr DESKTOP
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

;;; ==================================================
;;; $D000 routines/pointers (called from MAIN)

;;; These are used by the MAIN (and sometimes AUX) halves of DeskTop itself,
;;; since this bank can be accessed from both AUX and MAIN.

;; Listed here as they are used by weird DeskTop block in A2D space

        ;; Relay for main>aux A2D call (Y=call, X,A=params addr)
A2D_RELAY       := $D000

.macro A2D_RELAY_CALL call, addr
        ldy     #(call)
.if .paramcount > 1
        lda     #<(addr)
        ldx     #>(addr)
.else
        lda     #0
        ldx     #0
.endif
        jsr     A2D_RELAY
.endmacro

DESKTOP_FIND_SPACE      := $D05E ; Find space in AUX $1F80 table


;;; ==================================================
;;; DeskTop Internals

;;; NOTE: Some of these are used by Desk Accessories

        ;; These are DeskTop internals, but it appears there is no
        ;; API for getting the selected file.
        file_selected := $DF21  ; 0 if no selection, 1 otherwise
        path_index := $DF20     ; index of selected window (used to get prefix)
        path_table := $DFB3     ; window address table
        ;; each entry is 65 bytes long
        ;;      length-prefixed path string (no trailing /)
        file_index := $DF22     ; index of selected file (global, not w/in window)
        file_table := $DD9F     ; file address table
        ;; each entry is 27 bytes long
        ;;      .byte ??
        ;;      .byte ??
        ;;      .byte type/icon (bits 4,5,6 clear = directory)
        ;;      .word iconx     (pixels)
        ;;      .word icony     (pixels)
        ;;      .byte ??
        ;;      .byte ??
        ;;      .byte len, name (length-prefixed, spaces before/after; 17 byte buffer)
