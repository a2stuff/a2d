;;; ============================================================
;;; PUZZLE - Desk Accessory
;;;
;;; A classic 15-square sliding puzzle.
;;; ============================================================

        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        .org DA_LOAD_ADDRESS

        jmp     copy2aux

        .res    36, 0

;;; ============================================================
;;; Copy the DA to AUX and invoke it

stash_stack:  .byte   0
.proc copy2aux
        tsx
        stx     stash_stack

        start := enter_da
        end := last

        sta     ALTZPOFF
        lda     ROMIN2
        copy16  #start, STARTLO
        copy16  #end, ENDLO
        copy16  #start, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE

        copy16  #enter_da, XFERSTARTLO
        php
        pla
        ora     #$40            ; set overflow: use aux zp/stack
        pha
        plp
        sec                     ; control main>aux
        jmp     XFER
.endproc

;;; ============================================================
;;; Set up / tear down

.proc exit_da
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        ldx     stash_stack
        txs
        rts
.endproc

.proc enter_da
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        lda     #0
        sta     $08
        jmp     create_window
.endproc

        kDAWindowId = 51

;;; ============================================================
;;; Redraw the screen (all windows) after a EventKind::drag

.proc redraw_screen

        dest := $20

        ;; copy following routine to $20 and call it
        COPY_BYTES sizeof_routine+1, routine, dest
        jsr     dest

        lda     #kDAWindowId
        jsr     redraw_window
        rts

.proc routine
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_REDRAW_ALL
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
        sizeof_routine = .sizeof(routine)
.endproc

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
        bne     :+
        jmp     draw_window

:       rts

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
        DEFINE_RECT 0, 0, 27, 15
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
        DEFINE_RECT 1, 0, kDefaultWidth, kDefaultHeight
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

        .byte   $00             ; ???

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

        ;; ???
        .byte   $00
        .res    8, $FF
        .byte   $00

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

        ;; param for draw_row/draw_col
draw_rc:  .byte   $00

        ;; params for draw_selected
draw_end:  .byte   $00
draw_inc:  .byte   $00

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

        .byte   $73,$00,$F7,$FF
        .addr   str
        .byte   $01
        .byte   $00,$00,$00,$00,$00,$06,$00,$05
        .byte   $00
str:    .byte   $41,$35,$47,$37,$36,$49   ; "A#G%#I" ?

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
mincontlength:  .word   kDefaultHeight
maxcontwidth:   .word   kDefaultWidth
maxcontlength:  .word   kDefaultHeight
port:
viewloc:        DEFINE_POINT kDefaultLeft, kDefaultTop, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
cliprect:       DEFINE_RECT 0, 0, kDefaultWidth, kDefaultHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams
        winfo_viewloc_ycoord := winfo::viewloc::ycoord

        ;; This is grafport cruft only below
.params port_cruft                 ; Unknown usage
viewloc:        DEFINE_POINT kDefaultLeft, kDefaultTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, kDefaultWidth, kDefaultHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
.endparams

        .byte   0,0             ; ???

name:   PASCAL_STRING "Puzzle"


;;; ============================================================
;;; Create the window

.proc create_window
        jsr     save_zp
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
.proc scramble
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
.endproc

        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        beq     scramble
        jsr     check_victory
        bcs     scramble
        jsr     draw_all
        jsr     find_hole
        ; fall through
.endproc

;;; ============================================================
;;; Input loop and processing

.proc input_loop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     on_click
        jmp     input_loop

        ;; key?
:       cmp     #MGTK::EventKind::key_down
        bne     input_loop
        jsr     check_key
        jmp     input_loop

        ;; click - where?
on_click:
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
        jsr     find_click_piece
        bcc     bail
        jmp     process_click

        ;; close port?
:       cmp     #MGTK::Area::close_box
        bne     check_title
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        beq     bail
destroy:
        MGTK_CALL MGTK::CloseWindow, closewindow_params

        target := $20           ; copy following to ZP and run it
        COPY_BYTES sizeof_routine+1, routine, target
        jmp     target

.proc routine
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jmp     exit_da
.endproc
        sizeof_routine = .sizeof(routine)

        ;; title bar?
check_title:
        cmp     #MGTK::Area::dragbar
        bne     bail
        lda     #kDAWindowId
        sta     dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        ldx     #$23            ; ???
        jsr     redraw_screen
        rts

        ;; on key press - exit if Escape
check_key:
        lda     event_params::modifiers
        bne     :+
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     destroy
:       rts
.endproc

;;; ============================================================
;;; Map click to piece x/y

.proc find_click_piece
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
        jsr     find_click_x
        bcc     nope
        lda     #0
        beq     yep
:       cmp     #kRow3+1
        bcs     :+
        jsr     find_click_x
        bcc     nope
        lda     #1
        bne     yep
:       cmp     #kRow4+1
        bcs     :+
        jsr     find_click_x
        bcc     nope
        lda     #2
        bne     yep
:       cmp     #kRow4+kRowHeight+1
        bcs     nope
        jsr     find_click_x
        bcc     nope
        lda     #3

yep:    sta     click_y
        sec
        rts

nope:   clc
        rts
.endproc

.proc find_click_x
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
.endproc

;;; ============================================================
;;; Process piece click

        kHolePiece = 12

.proc process_click

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
        beq     click_in_col
        lda     click_y
        cmp     hole_y
        beq     click_in_row

miss:   rts                     ; Click on hole, or not row/col with hole

.proc click_in_row
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
        beq     row
.endproc

.proc click_in_col
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
.endproc

col:    lda     #kHolePiece
        sta     position_table,y
        jsr     draw_col
        jmp     done

row:    lda     #kHolePiece
        sta     position_table,y
        jsr     draw_row

done:   jsr     check_victory
        bcc     after_click

        ;; Yay! Play the sound 4 times
.proc on_victory
        ldx     #4
loop:   txa
        pha
        jsr     play_sound
        pla
        tax
        dex
        bne     loop
.endproc

after_click:
        jmp     find_hole

        rts                     ; ???
.endproc

;;; ============================================================
;;; Clear the background

draw_window:
        MGTK_CALL MGTK::SetPattern, pattern_speckles
        MGTK_CALL MGTK::PaintRect, paintrect_params
        MGTK_CALL MGTK::SetPattern, pattern_black

        MGTK_CALL MGTK::MoveTo, moveto_params
        MGTK_CALL MGTK::Line, line_params

        jsr     draw_all

        lda     #kDAWindowId
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, setport_params
        rts

;;; ============================================================

.proc save_zp
        ldx     #$00
loop:   lda     $00,x
        sta     saved_zp,x
        dex
        bne     loop
        rts
.endproc

.proc restore_zp
        ldx     #$00
loop:   lda     saved_zp,x
        sta     $00,x
        dex
        bne     loop
        rts
.endproc

saved_zp:
        .res    256, 0

;;; ============================================================
;;; Draw pieces

.proc draw_all
        ldy     #1
        sty     draw_inc
        dey
        lda     #16
        sta     draw_end
        bne     draw_selected
.endproc

.proc draw_row                  ; row specified in draw_rc
        lda     #1
        sta     draw_inc
        lda     draw_rc
        tay
        clc
        adc     #4
        sta     draw_end
        bne     draw_selected
.endproc

.proc draw_col                  ; col specified in draw_rc
        lda     #4
        sta     draw_inc
        ldy     hole_x
        lda     #16
        sta     draw_end
        ;; fall through
.endproc

        ;; Draw pieces from A to draw_end, step draw_inc
.proc draw_selected
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
        MGTK_CALL MGTK::PaintBits, paintbits_params
        pla
        clc
        adc     draw_inc
        tay
        cpy     draw_end
        bcc     loop
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================
;;; Play sound

.proc play_sound
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
.endproc

;;; ============================================================
;;; Puzzle complete?

        ;; Returns with carry set if puzzle complete
.proc check_victory             ; Allows for swapped indistinct pieces, etc.
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
.endproc

;;; ============================================================
;;; Find hole piece

.proc find_hole
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
.endproc

last := *
