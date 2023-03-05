;;; ============================================================
;;; PUZZLE - Desk Accessory
;;;
;;; A classic 15-square sliding puzzle.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "puzzle.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

        kDAWindowId = 51

;;; ============================================================
;;; Redraw the DA window

        ;; called with window_id in A
redraw_window:
        sta     getwinport_params_window_id
        lda     winfo_viewloc_ycoord ; is top on screen?
        cmp     #kScreenHeight-1
        bcc     :+              ; yes
        rts

:       MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, setport_params
        lda     getwinport_params_window_id
        cmp     #kDAWindowId
        jeq     DrawWindow

        rts

;;; ============================================================
;;; Param Blocks

        ;; following memory space is re-used so x/y overlap
.params dragwindow_params
window_id       := * + 0
dragx           := * + 1                 ; x overlap
dragy           := * + 3                 ; y overlap
it_moved        := * + 5                 ; ignored
.endparams

.params screentowindow_params
window_id       := * + 0
screenx         := * + 1                 ; x overlap
screeny         := * + 3                 ; y overlap
windowx         := * + 5
windowy         := * + 7
.endparams

.params event_params
kind:           .byte   0
key             := *
modifiers       := *+1

xcoord          := *            ; x overlap
ycoord          := *+2          ; y overlap
.endparams

.params findwindow_params
mousex          := *            ; x overlap
mousey          := * + 2        ; y overlap
which_area      := * + 4
window_id       := * + 5
.endparams

        .res    8, 0            ; storage for above

        .byte   0,0             ; ???

.params trackgoaway_params
goaway: .byte   0
.endparams

.params getwinport_params
window_id:      .byte   0
a_grafport:     .addr   setport_params
.endparams
getwinport_params_window_id := getwinport_params::window_id

        ;; Puzzle piece row/columns
        kColWidth = 28
        kCol1 = 5
        kCol2 = kCol1 + kColWidth
        kCol3 = kCol2 + kColWidth
        kCol4 = kCol3 + kColWidth
        kRowHeight = 16
        kRow1 = 3
        kRow2 = kRow1 + kRowHeight
        kRow3 = kRow2 + kRowHeight
        kRow4 = kRow3 + kRowHeight

space_positions:                 ; left, top for all 16 holes
        .word   kCol1,kRow1
        .word   kCol2,kRow1
        .word   kCol3,kRow1
        .word   kCol4,kRow1
        .word   kCol1,kRow2
        .word   kCol2,kRow2
        .word   kCol3,kRow2
        .word   kCol4,kRow2
        .word   kCol1,kRow3
        .word   kCol2,kRow3
        .word   kCol3,kRow3
        .word   kCol4,kRow3
        .word   kCol1,kRow4
        .word   kCol2,kRow4
        .word   kCol3,kRow4
        .word   kCol4,kRow4

.params bitmap_table
        .addr   piece1, piece2, piece3, piece4
        .addr   piece5, piece6, piece7, piece8
        .addr   piece9, piece10, piece11, piece12
        .addr   piece13, piece14, piece15, piece16
.endparams

        ;; Current position table
position_table:
        .res    16, 0

.params paintbits_params
left:           .word   0
top:            .word   0
mapbits:        .addr   0
mapwidth:       .byte   4
        .byte   0               ; reserved
        DEFINE_RECT maprect, 0, 0, 27, 15
.endparams

piece1:
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece2:
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%0000000),PX(%0011111),PX(%1111110)
        .byte PX(%0111000),PX(%1010101),PX(%0100001),PX(%1111110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece3:
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1110001),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%0010101),PX(%0111110)
        .byte PX(%0111111),PX(%1111101),PX(%0101010),PX(%1011110)
        .byte PX(%0111111),PX(%1110010),PX(%1010101),PX(%0111110)
        .byte PX(%0111111),PX(%1100101),PX(%0101010),PX(%0111110)
        .byte PX(%0111111),PX(%0001010),PX(%1010100),PX(%1111110)
        .byte PX(%0111110),PX(%1010101),PX(%0101001),PX(%1111110)
        .byte PX(%0111101),PX(%0101010),PX(%1000111),PX(%1111110)
        .byte PX(%0111010),PX(%1010101),PX(%0011111),PX(%1111110)
        .byte PX(%0110101),PX(%0101000),PX(%0111111),PX(%1111110)
        .byte PX(%0110010),PX(%1010011),PX(%1111111),PX(%1111110)
        .byte PX(%0110101),PX(%0001111),PX(%1111100),PX(%0000000)
        .byte PX(%0110000),PX(%1111111),PX(%1000010),PX(%1010100)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece4:
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0101000),PX(%0111111),PX(%1111111),PX(%1111110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece5:
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1110100)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1101010)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1011110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%0111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111110),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111101),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111101),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111011),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1110111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1110111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1110110),PX(%1101100)
        .byte PX(%0111111),PX(%1111111),PX(%1101101),PX(%1011010)
        .byte PX(%0111111),PX(%1111111),PX(%1101011),PX(%0110110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece6:
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0010101),PX(%0101010),PX(%1010101),PX(%0101010)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0010101),PX(%0101010),PX(%1010101),PX(%0101010)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0011011),PX(%0110110),PX(%1101101),PX(%1011010)
        .byte PX(%0110110),PX(%1101101),PX(%1011011),PX(%0110110)
        .byte PX(%0101101),PX(%1011011),PX(%0110110),PX(%1101100)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece7:
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0010101),PX(%0101010),PX(%1010101),PX(%0101010)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0010101),PX(%0101010),PX(%1010101),PX(%0101010)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0110110),PX(%1101101),PX(%1011011),PX(%0110110)
        .byte PX(%0101101),PX(%1011011),PX(%0110110),PX(%1101100)
        .byte PX(%0011011),PX(%0110110),PX(%1101101),PX(%1011010)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece8:
        .byte PX(%0101010),PX(%1010001),PX(%1111111),PX(%1111110)
        .byte PX(%0010101),PX(%0101010),PX(%0111111),PX(%1111110)
        .byte PX(%0101010),PX(%1010101),PX(%0001111),PX(%1111110)
        .byte PX(%0010101),PX(%0101010),PX(%1000111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%0011111),PX(%1111110)
        .byte PX(%0111111),PX(%1111110),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111101),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111011),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1110111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1110111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1101111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1101111),PX(%1111111),PX(%1111110)
        .byte PX(%0101101),PX(%1001111),PX(%1111111),PX(%1111110)
        .byte PX(%0011011),PX(%0011111),PX(%1111111),PX(%1111110)
        .byte PX(%0110110),PX(%1011111),PX(%1111111),PX(%1111110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece9:
        .byte PX(%0111111),PX(%1111111),PX(%1110011),PX(%0110110)
        .byte PX(%0111111),PX(%1111111),PX(%1110110),PX(%1101100)
        .byte PX(%0111111),PX(%1111111),PX(%1110101),PX(%1011010)
        .byte PX(%0111111),PX(%1111111),PX(%1110011),PX(%0110110)
        .byte PX(%0111111),PX(%1111111),PX(%1111010),PX(%1010100)
        .byte PX(%0111111),PX(%1111111),PX(%1111010),PX(%1010100)
        .byte PX(%0111111),PX(%1111111),PX(%1111100),PX(%1010100)
        .byte PX(%0111111),PX(%1111111),PX(%1111110),PX(%1010100)
        .byte PX(%0111111),PX(%1111111),PX(%1111110),PX(%1010100)
        .byte PX(%0111111),PX(%1111111),PX(%1111110),PX(%1010100)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%0010100)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1001100)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1100110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1110100)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111010)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece10:
        .byte PX(%0101101),PX(%1011011),PX(%0110110),PX(%1101100)
        .byte PX(%0011011),PX(%0110110),PX(%1101101),PX(%1011010)
        .byte PX(%0110110),PX(%1101101),PX(%1011011),PX(%0110110)
        .byte PX(%0101101),PX(%1011011),PX(%0110110),PX(%1101100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0100110),PX(%0110011),PX(%0011001),PX(%1001100)
        .byte PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110)
        .byte PX(%0100110),PX(%0110011),PX(%0011001),PX(%1001100)
        .byte PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece11:
        .byte PX(%0011011),PX(%0110110),PX(%1101101),PX(%1011010)
        .byte PX(%0110110),PX(%1101101),PX(%1011011),PX(%0110110)
        .byte PX(%0101101),PX(%1011011),PX(%0110110),PX(%1101100)
        .byte PX(%0011011),PX(%0110110),PX(%1101101),PX(%1011010)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0101010),PX(%1010101),PX(%0101010),PX(%1010100)
        .byte PX(%0100110),PX(%0110011),PX(%0011001),PX(%1001100)
        .byte PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110)
        .byte PX(%0100110),PX(%0110011),PX(%0011001),PX(%1001100)
        .byte PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece12:
        .byte PX(%0110110),PX(%1011111),PX(%1111111),PX(%1111110)
        .byte PX(%0101101),PX(%1011111),PX(%1111111),PX(%1111110)
        .byte PX(%0011011),PX(%0101111),PX(%1111111),PX(%1111110)
        .byte PX(%0110110),PX(%1101111),PX(%1111111),PX(%1111110)
        .byte PX(%0101010),PX(%1010111),PX(%1111111),PX(%1111110)
        .byte PX(%0101010),PX(%1010011),PX(%1111111),PX(%1111110)
        .byte PX(%0101010),PX(%1010011),PX(%1111111),PX(%1111110)
        .byte PX(%0101010),PX(%1010101),PX(%1111111),PX(%1111110)
        .byte PX(%0101010),PX(%1010100),PX(%1111111),PX(%1111110)
        .byte PX(%0101010),PX(%1010101),PX(%0011111),PX(%1111110)
        .byte PX(%0101010),PX(%1010101),PX(%0100111),PX(%1111110)
        .byte PX(%0100110),PX(%0110011),PX(%0010111),PX(%1111110)
        .byte PX(%0110011),PX(%0011001),PX(%1001111),PX(%1111110)
        .byte PX(%0100110),PX(%0110011),PX(%0001111),PX(%1111110)
        .byte PX(%0110011),PX(%0011001),PX(%1011111),PX(%1111110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece13:                       ; the hole
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111011),PX(%1011101),PX(%1101110),PX(%1110110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0101110),PX(%1110111),PX(%0111011),PX(%1011100)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111011),PX(%1011101),PX(%1101110),PX(%1110110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0101110),PX(%1110111),PX(%0111011),PX(%1011100)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111011),PX(%1011101),PX(%1101110),PX(%1110110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0101110),PX(%1110111),PX(%0111011),PX(%1011100)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111011),PX(%1011101),PX(%1101110),PX(%1110110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece14:
        .byte PX(%0001100),PX(%1100110),PX(%0110011),PX(%0011000)
        .byte PX(%0100110),PX(%0110011),PX(%0011001),PX(%1001100)
        .byte PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110)
        .byte PX(%0011011),PX(%0110110),PX(%1101101),PX(%1011010)
        .byte PX(%0100101),PX(%1011011),PX(%0110110),PX(%1101100)
        .byte PX(%0110010),PX(%1101101),PX(%1011011),PX(%0110110)
        .byte PX(%0111001),PX(%0110110),PX(%1101101),PX(%1011010)
        .byte PX(%0111110),PX(%0111011),PX(%0110110),PX(%1101100)
        .byte PX(%0111111),PX(%1000101),PX(%1011000),PX(%0000000)
        .byte PX(%0111111),PX(%1111000),PX(%0000001),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece15:
        .byte PX(%0001100),PX(%1100110),PX(%0110011),PX(%0011000)
        .byte PX(%0100110),PX(%0110011),PX(%0011001),PX(%1001100)
        .byte PX(%0110011),PX(%0011001),PX(%1001100),PX(%1100110)
        .byte PX(%0110110),PX(%1101101),PX(%1011011),PX(%0110110)
        .byte PX(%0011011),PX(%0110110),PX(%1101101),PX(%1011010)
        .byte PX(%0101101),PX(%1011011),PX(%0110110),PX(%1101100)
        .byte PX(%0110110),PX(%1101101),PX(%1011011),PX(%0110110)
        .byte PX(%0011011),PX(%0110110),PX(%1101101),PX(%1011010)
        .byte PX(%0000000),PX(%0000000),PX(%0000110),PX(%1101100)
        .byte PX(%0111111),PX(%1111111),PX(%1100000),PX(%0000010)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
piece16:
        .byte PX(%0001100),PX(%1100110),PX(%0011111),PX(%1111110)
        .byte PX(%0100110),PX(%0110011),PX(%0111111),PX(%1111110)
        .byte PX(%0110011),PX(%0011000),PX(%1111111),PX(%1111110)
        .byte PX(%0101101),PX(%1011001),PX(%1111111),PX(%1111110)
        .byte PX(%0110110),PX(%1100111),PX(%1111111),PX(%1111110)
        .byte PX(%0011011),PX(%0011111),PX(%1111111),PX(%1111110)
        .byte PX(%0101110),PX(%0111111),PX(%1111111),PX(%1111110)
        .byte PX(%0100111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)


.params paintrect_params
        DEFINE_RECT rect, 1, 0, kDefaultWidth, kDefaultHeight
.endparams

.params pattern_speckles
        .byte %01110111
        .byte %11011101
        .byte %01110111
        .byte %11011101
        .byte %01110111
        .byte %11011101
        .byte %01110111
        .byte %11011101
.endparams

.params pattern_black
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
.endparams

;; line across top of puzzle (bitmaps include bottom edges)
.params moveto_params
xcoord: .word   5
ycoord: .word   2
.endparams
.params line_params
xdelta: .word   112
ydelta: .word   0
.endparams

        ;; hole position (0..3, 0..3)
hole_x: .byte   0
hole_y: .byte   0

        ;; click location (0..3, 0..3)
click_x:  .byte   $00
click_y:  .byte   $00

        ;; param for DrawRow/DrawCol
draw_rc:  .byte   $00

        ;; params for DrawSelected
draw_end:  .byte   $00
draw_inc:  .byte   $00

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

        ;; SET_STATE params (filled in by QUERY_STATE)
setport_params:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$0D
        .byte   $00,$00,$20,$80,$00,$00,$00,$00
        .byte   $00,$2F,$02,$B1,$00,$00,$01,$02
        .byte   $06

        kDefaultLeft    = 220
        kDefaultTop     = 80
        kDefaultWidth   = 121
        kDefaultHeight  = 68

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::go_away_box
title:          .addr   name
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kDefaultWidth
mincontheight:  .word   kDefaultHeight
maxcontwidth:   .word   kDefaultWidth
maxcontheight:  .word   kDefaultHeight
port:
        DEFINE_POINT viewloc, kDefaultLeft, kDefaultTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDefaultWidth, kDefaultHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams
        winfo_viewloc_ycoord := winfo::viewloc::ycoord

name:   PASCAL_STRING res_string_window_title  ; window title

;;; ============================================================
;;; Create the window

.proc CreateWindow
        MGTK_CALL MGTK::OpenWindow, winfo

        ;; init pieces
        ldy     #15
loop:   tya
        sta     position_table,y
        dey
        bpl     loop

        lda     #kDAWindowId
        jsr     redraw_window
        MGTK_CALL MGTK::FlushEvents

        ;; Scramble?
.proc Scramble
        ldy     #3
sloop:  tya
        pha
        ldx     position_table
        ldy     #0
ploop:  lda     position_table+1,y
        sta     position_table,y
        iny
        cpy     #15
        bcc     ploop

        stx     position_table+15
        pla
        tay
        dey
        bne     sloop
        ldx     position_table
        lda     position_table+1
        sta     position_table
        stx     position_table+1
.endproc ; Scramble

        JSR_TO_MAIN JUMP_TABLE_YIELD_LOOP
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     :+
        cmp     #MGTK::EventKind::key_down
        bne     Scramble
:
        jsr     CheckVictory
        bcs     Scramble        ; BUG: This would require a second click!
        jsr     DrawAll
        jsr     FindHole
        FALL_THROUGH_TO InputLoop
.endproc ; CreateWindow

;;; ============================================================
;;; Input loop and processing

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_YIELD_LOOP
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     OnClick
        jmp     InputLoop

        ;; key?
:       cmp     #MGTK::EventKind::key_down
        bne     InputLoop
        jsr     CheckKey
        jmp     InputLoop
.endproc ; InputLoop

        ;; click - where?
.proc OnClick
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        bne     bail
        lda     findwindow_params::which_area
        bne     :+
bail:   rts

        ;; client area?
:       cmp     #MGTK::Area::content
        bne     :+
        jsr     FindClickPiece
        bcc     bail
        jmp     ProcessClick

        ;; close port?
:       cmp     #MGTK::Area::close_box
        bne     check_title
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        beq     bail
destroy:
        pla                     ; bust out of OnXXX proc
        pla
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts


        ;; title bar?
check_title:
        cmp     #MGTK::Area::dragbar
        bne     bail
        lda     #kDAWindowId
        sta     dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        bit     dragwindow_params::it_moved
        bpl     ret
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        lda     #kDAWindowId
        jmp     redraw_window
ret:    rts
.endproc ; OnClick

        ;; on key press - exit if Escape
.proc CheckKey
        lda     event_params::modifiers
        bne     ret

        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     OnClick::destroy

        ldx     hole_x
        ldy     hole_y

        cmp     #CHAR_DOWN
    IF_EQ
        dey
        bmi     ret
        bpl     move            ; always
    END_IF

        cmp     #CHAR_UP
    IF_EQ
        iny
        cpy     #4
        bcs     ret
        bcc     move            ; always
    END_IF

        cmp     #CHAR_RIGHT
    IF_EQ
        dex
        bmi     ret
        bpl     move            ; always
    END_IF

        cmp     #CHAR_LEFT
    IF_EQ
        inx
        cpx     #4
        bcs     ret
        bcc     move            ; always
    END_IF

ret:    rts

move:   stx     click_x
        sty     click_y
        jmp     ProcessClick
.endproc ; CheckKey

;;; ============================================================
;;; Map click to piece x/y

.proc FindClickPiece
        lda     #kDAWindowId
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     screentowindow_params::windowx+1
        ora     screentowindow_params::windowy+1
        bne     nope            ; ensure high bytes are 0

        lda     screentowindow_params::windowy
        ldx     screentowindow_params::windowx

        cmp     #kRow1
        bcc     nope
        cmp     #kRow2+1
        bcs     :+
        jsr     FindClickX
        bcc     nope
        lda     #0
        beq     yep
:       cmp     #kRow3+1
        bcs     :+
        jsr     FindClickX
        bcc     nope
        lda     #1
        bne     yep
:       cmp     #kRow4+1
        bcs     :+
        jsr     FindClickX
        bcc     nope
        lda     #2
        bne     yep
:       cmp     #kRow4+kRowHeight+1
        bcs     nope
        jsr     FindClickX
        bcc     nope
        lda     #3

yep:    sta     click_y
        sec
        rts

nope:   clc
        rts
.endproc ; FindClickPiece

.proc FindClickX
        cpx     #kCol1
        bcc     nope
        cpx     #kCol2
        bcs     :+
        lda     #0
        beq     yep
:       cpx     #kCol3+1
        bcs     :+
        lda     #1
        bne     yep
:       cpx     #kCol4+1
        bcs     :+
        lda     #2
        bne     yep
:       cpx     #kCol4+kColWidth
        bcs     nope
        lda     #3

yep:    sta     click_x
        sec
        rts

nope:   clc
        rts
.endproc ; FindClickX

;;; ============================================================
;;; Process piece click

        kHolePiece = 12

.proc ProcessClick

        lda     #0
        ldy     hole_y
        beq     found
:       clc
        adc     #4
        dey
        bne     :-

found:  sta     draw_rc
        clc
        adc     hole_x
        tay
        lda     click_x
        cmp     hole_x
        beq     ClickInCol
        lda     click_y
        cmp     hole_y
        beq     ClickInRow

miss:   rts                     ; Click on hole, or not row/col with hole

.proc ClickInRow
        lda     click_x
        cmp     hole_x
        beq     miss
        bcs     after

        lda     hole_x          ; click before of hole
        sec
        sbc     click_x
        tax
bloop:  lda     position_table-1,y
        sta     position_table,y
        dey
        dex
        bne     bloop
        beq     row

after:  lda     click_x         ; click after hole
        sec
        sbc     hole_x
        tax
aloop:  lda     position_table+1,y
        sta     position_table,y
        iny
        dex
        bne     aloop
        beq     row             ; always
.endproc ; ClickInRow

.proc ClickInCol
        lda     click_y
        cmp     hole_y
        beq     miss
        bcs     after

        lda     hole_y          ; click before hole
        sec
        sbc     click_y
        tax
bloop:  lda     position_table-4,y
        sta     position_table,y
        dey
        dey
        dey
        dey
        dex
        bne     bloop
        beq     col

after:  lda     click_y         ; click after hole
        sec
        sbc     hole_y
        tax
aloop:  lda     position_table+4,y
        sta     position_table,y
        iny
        iny
        iny
        iny
        dex
        bne     aloop
.endproc ; ClickInCol

col:    lda     #kHolePiece
        sta     position_table,y
        jsr     DrawCol
        jmp     done

row:    lda     #kHolePiece
        sta     position_table,y
        jsr     DrawRow

done:   jsr     CheckVictory
        bcc     after_click

        ;; Yay! Play the sound 4 times
.proc OnVictory
        ldx     #4
loop:   txa
        pha
        jsr     PlaySound
        pla
        tax
        dex
        bne     loop
.endproc ; OnVictory

after_click:
        jmp     FindHole
.endproc ; ProcessClick

;;; ============================================================
;;; Clear the background

DrawWindow:
        MGTK_CALL MGTK::SetPattern, pattern_speckles
        MGTK_CALL MGTK::PaintRect, paintrect_params
        MGTK_CALL MGTK::SetPattern, pattern_black

        MGTK_CALL MGTK::MoveTo, moveto_params
        MGTK_CALL MGTK::Line, line_params

        jsr     DrawAll

        lda     #kDAWindowId
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, setport_params
        rts

;;; ============================================================
;;; Draw pieces

.proc DrawAll
        ldy     #1
        sty     draw_inc
        dey
        lda     #16
        sta     draw_end
        bne     DrawSelected    ; always
.endproc ; DrawAll

.proc DrawRow                   ; row specified in draw_rc
        lda     #1
        sta     draw_inc
        lda     draw_rc
        tay
        clc
        adc     #4
        sta     draw_end
        bne     DrawSelected    ; always
.endproc ; DrawRow

.proc DrawCol                   ; col specified in draw_rc
        lda     #4
        sta     draw_inc
        ldy     hole_x
        lda     #16
        sta     draw_end
        FALL_THROUGH_TO DrawSelected
.endproc ; DrawCol

        ;; Draw pieces from A to draw_end, step draw_inc
.proc DrawSelected
        tya
        pha
        MGTK_CALL MGTK::HideCursor
        lda     #kDAWindowId
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, setport_params
        pla
        tay

loop:   tya
        pha
        asl     a
        asl     a
        tax
        copy16  space_positions,x, paintbits_params::left
        copy16  space_positions+2,x, paintbits_params::top
        lda     position_table,y
        asl     a
        tax
        copy16  bitmap_table,x, paintbits_params::mapbits
        MGTK_CALL MGTK::PaintBitsHC, paintbits_params
        pla
        clc
        adc     draw_inc
        tay
        cpy     draw_end
        bcc     loop
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; DrawSelected

;;; ============================================================
;;; Play sound

.proc PlaySound
        ldx     #$80
loop1:  lda     #88
loop2:  ldy     #27
delay1: dey
        bne     delay1
        bit     SPKR
        tay
delay2: dey
        bne     delay2
        sbc     #1
        beq     loop1
        bit     SPKR
        dex
        bne     loop2
        rts
.endproc ; PlaySound

;;; ============================================================
;;; Puzzle complete?

        ;; Returns with carry set if puzzle complete
.proc CheckVictory        ; Allows for swapped indistinct pieces, etc.
        ;; 0/12 can be swapped
        lda     position_table
        beq     :+
        cmp     #12
        bne     nope

:       ldy     #1
c1234:  tya
        cmp     position_table,y
        bne     nope
        iny
        cpy     #5
        bcc     c1234

        ;; 5/6 are identical
        lda     position_table+5
        cmp     #5
        beq     :+
        cmp     #6
        bne     nope
:       lda     position_table+6
        cmp     #5
        beq     :+
        cmp     #6
        bne     nope
:       lda     position_table+7
        cmp     #7
        bne     nope
        lda     position_table+8
        cmp     #8
        bne     nope

        ;; 9/10 are identical
        lda     position_table+9
        cmp     #9
        beq     :+
        cmp     #10
        bne     nope
:       lda     position_table+10
        cmp     #9
        beq     :+
        cmp     #10
        bne     nope

:       lda     position_table+11
        cmp     #11
        bne     nope

        ;; 0/12 can be swapped
        lda     position_table+12
        beq     :+
        cmp     #12
        bne     nope

:       ldy     #13
c131415:tya
        cmp     position_table,y
        bne     nope
        iny
        cpy     #16
        bcc     c131415
        rts

nope:   clc
        rts
.endproc ; CheckVictory

;;; ============================================================
;;; Find hole piece

.proc FindHole
        ldy     #15
loop:   lda     position_table,y
        cmp     #kHolePiece
        beq     :+
        dey
        bpl     loop

:       lda     #0
        sta     hole_x
        sta     hole_y

        tya
again:  cmp     #4
        bcc     done
        sbc     #4
        inc     hole_y
        bne     again

done:   sta     hole_x
        rts
.endproc ; FindHole

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX aux::CreateWindow
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
