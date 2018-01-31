        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"

        .include "../mgtk.inc"
        .include "../desktop.inc" ; redraw icons after window move, font

        .org $800

        jmp     copy2aux

        .res    36, 0

;;; ==================================================
;;; Copy the DA to AUX and invoke it

stash_stack:  .byte   0
.proc copy2aux
        tsx
        stx     stash_stack

        start := enter_da
        end := last

        sta     ALTZPOFF
        lda     ROMIN2
        lda     #<start
        sta     STARTLO
        lda     #>start
        sta     STARTHI
        lda     #<end
        sta     ENDLO
        lda     #>end
        sta     ENDHI
        lda     #<start
        sta     DESTINATIONLO
        lda     #>start
        sta     DESTINATIONHI
        sec                     ; main>aux
        jsr     AUXMOVE

        lda     #<enter_da
        sta     XFERSTARTLO
        lda     #>enter_da
        sta     XFERSTARTHI
        php
        pla
        ora     #$40            ; set overflow: use aux zp/stack
        pha
        plp
        sec                     ; control main>aux
        jmp     XFER
.endproc

;;; ==================================================
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

        da_window_id := 51

;;; ==================================================
;;; Redraw the screen (all windows) after a drag

.proc redraw_screen

        dest := $20

        ;; copy following routine to $20 and call it
        ldx     #sizeof_routine
loop:   lda     routine,x
        sta     dest,x
        dex
        bpl     loop
        jsr     dest

        ;; now check the window pos
        lda     #da_window_id
        jsr     check_window_pos

        bit     window_pos_flag
        bmi     skip

        DESKTOP_CALL DESKTOP_REDRAW_ICONS

skip:   lda     #0
        sta     window_pos_flag
        rts

.proc routine
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_REDRAW_ALL
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
        sizeof_routine := * - routine
.endproc

;;; ==================================================
;;; ???

        screen_height := 192

window_pos_flag:
        .byte   0               ; ???

        ;; called with window_id in A
check_window_pos:
        sta     getwinport_params_window_id
        lda     winfo_viewloc_ycoord ; is top on screen?
        cmp     #screen_height-1
        bcc     :+              ; yes
        lda     #$80            ; no, so ... ???
        sta     window_pos_flag
        rts

:       MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, setport_params
        lda     getwinport_params_window_id
        cmp     #da_window_id
        bne     :+
        jmp     draw_window

:       rts

;;; ==================================================
;;; Param Blocks

        ;; following memory space is re-used so x/y overlap
.proc dragwindow_params
window_id      := * + 0
dragx  := * + 1                ; x overlap
dragy  := * + 3                ; y overlap
it_moved   := * + 5                ; ignored
.endproc

.proc screentowindow_params
window_id      := * + 0
screenx := * + 1                ; x overlap
screeny := * + 3                ; y overlap
windowx := * + 5
windowy := * + 7
.endproc

.proc event_params
kind:  .byte   0
key       := *
modifiers := *+1

xcoord    := *                  ; x overlap
ycoord    := *+2                ; y overlap
.endproc

.proc findwindow_params
mousex  := *                    ; x overlap
mousey  := *+2                  ; y overlap
which_area := *+4
window_id      := *+5
.endproc

        .res    8, 0            ; storage for above

        .byte   0,0             ; ???

.proc trackgoaway_params
goaway:.byte   0
.endproc

.proc getwinport_params
window_id:     .byte   0
a_grafport:   .addr   setport_params
.endproc
getwinport_params_window_id := getwinport_params::window_id

        ;; Puzzle piece row/columns
        cw := 28
        c1 := 5
        c2 := c1 + cw
        c3 := c2 + cw
        c4 := c3 + cw
        rh := 16
        r1 := 3
        r2 := r1 + rh
        r3 := r2 + rh
        r4 := r3 + rh

space_positions:                 ; left, top for all 16 holes
        .word   c1,r1
        .word   c2,r1
        .word   c3,r1
        .word   c4,r1
        .word   c1,r2
        .word   c2,r2
        .word   c3,r2
        .word   c4,r2
        .word   c1,r3
        .word   c2,r3
        .word   c3,r3
        .word   c4,r3
        .word   c1,r4
        .word   c2,r4
        .word   c3,r4
        .word   c4,r4

.proc bitmap_table
        .addr   piece1, piece2, piece3, piece4
        .addr   piece5, piece6, piece7, piece8
        .addr   piece9, piece10, piece11, piece12
        .addr   piece13, piece14, piece15, piece16
.endproc

        ;; Current position table
position_table:
        .res    16, 0

.proc paintbits_params
left:   .word   0
top:    .word   0
mapbits:   .addr   0
mapwidth: .byte   4
        .byte   0               ; reserved
        DEFINE_RECT 0, 0, 27, 15
.endproc

piece1:
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece2:
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%0000000),px(%0011111),px(%1111110)
        .byte px(%0111000),px(%1010101),px(%0100001),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece3:
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1110001),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%0010101),px(%0111110)
        .byte px(%0111111),px(%1111101),px(%0101010),px(%1011110)
        .byte px(%0111111),px(%1110010),px(%1010101),px(%0111110)
        .byte px(%0111111),px(%1100101),px(%0101010),px(%0111110)
        .byte px(%0111111),px(%0001010),px(%1010100),px(%1111110)
        .byte px(%0111110),px(%1010101),px(%0101001),px(%1111110)
        .byte px(%0111101),px(%0101010),px(%1000111),px(%1111110)
        .byte px(%0111010),px(%1010101),px(%0011111),px(%1111110)
        .byte px(%0110101),px(%0101000),px(%0111111),px(%1111110)
        .byte px(%0110010),px(%1010011),px(%1111111),px(%1111110)
        .byte px(%0110101),px(%0001111),px(%1111100),px(%0000000)
        .byte px(%0110000),px(%1111111),px(%1000010),px(%1010100)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece4:
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0101000),px(%0111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece5:
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1110100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1101010)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1011110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%0111110)
        .byte px(%0111111),px(%1111111),px(%1111110),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111101),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111101),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111011),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1110111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1110111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1110110),px(%1101100)
        .byte px(%0111111),px(%1111111),px(%1101101),px(%1011010)
        .byte px(%0111111),px(%1111111),px(%1101011),px(%0110110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece6:
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0010101),px(%0101010),px(%1010101),px(%0101010)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0010101),px(%0101010),px(%1010101),px(%0101010)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece7:
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0010101),px(%0101010),px(%1010101),px(%0101010)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0010101),px(%0101010),px(%1010101),px(%0101010)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece8:
        .byte px(%0101010),px(%1010001),px(%1111111),px(%1111110)
        .byte px(%0010101),px(%0101010),px(%0111111),px(%1111110)
        .byte px(%0101010),px(%1010101),px(%0001111),px(%1111110)
        .byte px(%0010101),px(%0101010),px(%1000111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%0011111),px(%1111110)
        .byte px(%0111111),px(%1111110),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111101),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111011),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1110111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1110111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1101111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1101111),px(%1111111),px(%1111110)
        .byte px(%0101101),px(%1001111),px(%1111111),px(%1111110)
        .byte px(%0011011),px(%0011111),px(%1111111),px(%1111110)
        .byte px(%0110110),px(%1011111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece9:
        .byte px(%0111111),px(%1111111),px(%1110011),px(%0110110)
        .byte px(%0111111),px(%1111111),px(%1110110),px(%1101100)
        .byte px(%0111111),px(%1111111),px(%1110101),px(%1011010)
        .byte px(%0111111),px(%1111111),px(%1110011),px(%0110110)
        .byte px(%0111111),px(%1111111),px(%1111010),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111010),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111100),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111110),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111110),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111110),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%0010100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1001100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1100110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1110100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111010)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece10:
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece11:
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece12:
        .byte px(%0110110),px(%1011111),px(%1111111),px(%1111110)
        .byte px(%0101101),px(%1011111),px(%1111111),px(%1111110)
        .byte px(%0011011),px(%0101111),px(%1111111),px(%1111110)
        .byte px(%0110110),px(%1101111),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010111),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010011),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010011),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010101),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010100),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010101),px(%0011111),px(%1111110)
        .byte px(%0101010),px(%1010101),px(%0100111),px(%1111110)
        .byte px(%0100110),px(%0110011),px(%0010111),px(%1111110)
        .byte px(%0110011),px(%0011001),px(%1001111),px(%1111110)
        .byte px(%0100110),px(%0110011),px(%0001111),px(%1111110)
        .byte px(%0110011),px(%0011001),px(%1011111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece13:                       ; the hole
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111011),px(%1011101),px(%1101110),px(%1110110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0101110),px(%1110111),px(%0111011),px(%1011100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111011),px(%1011101),px(%1101110),px(%1110110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0101110),px(%1110111),px(%0111011),px(%1011100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111011),px(%1011101),px(%1101110),px(%1110110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0101110),px(%1110111),px(%0111011),px(%1011100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111011),px(%1011101),px(%1101110),px(%1110110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece14:
        .byte px(%0001100),px(%1100110),px(%0110011),px(%0011000)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0100101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0110010),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0111001),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0111110),px(%0111011),px(%0110110),px(%1101100)
        .byte px(%0111111),px(%1000101),px(%1011000),px(%0000000)
        .byte px(%0111111),px(%1111000),px(%0000001),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece15:
        .byte px(%0001100),px(%1100110),px(%0110011),px(%0011000)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0000000),px(%0000000),px(%0000110),px(%1101100)
        .byte px(%0111111),px(%1111111),px(%1100000),px(%0000010)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece16:
        .byte px(%0001100),px(%1100110),px(%0011111),px(%1111110)
        .byte px(%0100110),px(%0110011),px(%0111111),px(%1111110)
        .byte px(%0110011),px(%0011000),px(%1111111),px(%1111110)
        .byte px(%0101101),px(%1011001),px(%1111111),px(%1111110)
        .byte px(%0110110),px(%1100111),px(%1111111),px(%1111110)
        .byte px(%0011011),px(%0011111),px(%1111111),px(%1111110)
        .byte px(%0101110),px(%0111111),px(%1111111),px(%1111110)
        .byte px(%0100111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)


.proc fill_rect_params
        DEFINE_RECT 1, 0, default_width, default_height
.endproc

.proc pattern_speckles
        .byte %01110111
        .byte %11011101
        .byte %01110111
        .byte %11011101
        .byte %01110111
        .byte %11011101
        .byte %01110111
        .byte %11011101
.endproc

        .byte   $00             ; ???

.proc pattern_black
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
.endproc

        ;; ???
        .byte   $00
        .res    8, $FF
        .byte   $00

;; line across top of puzzle (bitmaps include bottom edges)
.proc set_pos_params
xcoord: .word   5
ycoord: .word   2
.endproc
.proc line_params
xdelta: .word   112
ydelta: .word   0
.endproc

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

.proc closewindow_params
window_id:     .byte   da_window_id
.endproc

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

        default_left    := 220
        default_top     := 80
        default_width   := $79
        default_height  := $44

.proc winfo
window_id:     .byte   da_window_id
options:  .byte   MGTK::option_go_away_box
title:  .addr   name
hscroll:.byte   MGTK::scroll_option_none
vscroll:.byte   MGTK::scroll_option_none
hthumbmax:  .byte   0
hthumbpos:  .byte   0
vthumbmax:  .byte   0
vthumbpos:  .byte   0
status: .byte   0
reserved:       .byte   0
mincontwidth:     .word   default_width
mincontlength:     .word   default_height
maxcontwidth:     .word   default_width
maxcontlength:     .word   default_height
port:
        DEFINE_POINT default_left, default_top, viewloc
mapbits:   .addr   MGTK::screen_mapbits
mapwidth: .word   MGTK::screen_mapwidth
cliprect:        DEFINE_RECT 0, 0, default_width, default_height
pattern:.res    8, $FF
colormasks:      .byte MGTK::colormask_and, MGTK::colormask_or
penloc: DEFINE_POINT 0, 0
penwidth: .byte   1
penheight: .byte   1
penmode:   .byte   0
textback:  .byte   $7F
textfont:   .addr   DEFAULT_FONT
nextwinfo:   .addr   0
.endproc
        winfo_viewloc_ycoord := winfo::viewloc::ycoord

        ;; This is grafport cruft only below
.proc port_cruft                 ; Unknown usage
viewloc:        DEFINE_POINT default_left, default_top
mapbits:   .addr   MGTK::screen_mapbits
mapwidth: .word   MGTK::screen_mapwidth
cliprect:        DEFINE_RECT 0, 0, default_width, default_height
pattern:.res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc: DEFINE_POINT 0, 0
penwidth: .byte   1
penheight: .byte   1
penmode:   .byte   0
textback:  .byte   $7F
textfont:   .addr   DEFAULT_FONT
.endproc

        .byte   0,0             ; ???

name:   PASCAL_STRING "Puzzle"


;;; ==================================================
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

        lda     #da_window_id
        jsr     check_window_pos
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

;;; ==================================================
;;; Input loop and processing

.proc input_loop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::button_down
        bne     :+
        jsr     on_click
        jmp     input_loop

        ;; key?
:       cmp     #MGTK::key_down
        bne     input_loop
        jsr     check_key
        jmp     input_loop

        ;; click - where?
on_click:
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #da_window_id
        bne     bail
        lda     findwindow_params::which_area
        bne     :+
bail:   rts

        ;; client area?
:       cmp     #MGTK::area_content
        bne     :+
        jsr     find_click_piece
        bcc     bail
        jmp     process_click

        ;; close port?
:       cmp     #MGTK::area_close_box
        bne     check_title
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        beq     bail
destroy:
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        DESKTOP_CALL DESKTOP_REDRAW_ICONS

        target = $20            ; copy following to ZP and run it
        ldx     #sizeof_routine
loop:   lda     routine,x
        sta     target,x
        dex
        bpl     loop
        jmp     target

.proc routine
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jmp     exit_da
.endproc
        sizeof_routine := * - routine

        ;; title bar?
check_title:
        cmp     #MGTK::area_dragbar
        bne     bail
        lda     #da_window_id
        sta     dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        ldx     #$23
        jsr     redraw_screen
        rts

        ;; on key press - exit if Escape
check_key:
        lda     event_params::modifiers
        bne     :+
        lda     event_params::key
        cmp     #KEY_ESCAPE
        beq     destroy
:       rts
.endproc

;;; ==================================================
;;; Map click to piece x/y

.proc find_click_piece
        lda     #da_window_id
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     screentowindow_params::windowx+1
        ora     screentowindow_params::windowy+1
        bne     nope            ; ensure high bytes are 0

        lda     screentowindow_params::windowy
        ldx     screentowindow_params::windowx

        cmp     #r1
        bcc     nope
        cmp     #r2+1
        bcs     :+
        jsr     find_click_x
        bcc     nope
        lda     #0
        beq     yep
:       cmp     #r3+1
        bcs     :+
        jsr     find_click_x
        bcc     nope
        lda     #1
        bne     yep
:       cmp     #r4+1
        bcs     :+
        jsr     find_click_x
        bcc     nope
        lda     #2
        bne     yep
:       cmp     #r4+rh+1
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
        cpx     #c1
        bcc     nope
        cpx     #c2
        bcs     :+
        lda     #0
        beq     yep
:       cpx     #c3+1
        bcs     :+
        lda     #1
        bne     yep
:       cpx     #c4+1
        bcs     :+
        lda     #2
        bne     yep
:       cpx     #c4+cw
        bcs     nope
        lda     #3

yep:    sta     click_x
        sec
        rts

nope:   clc
        rts
.endproc

;;; ==================================================
;;; Process piece click

        hole_piece := 12

.proc process_click

        lda     #0
        ldy     hole_y
        beq     L0FC9
L0FC3:  clc
        adc     #4
        dey
        bne     L0FC3

L0FC9:  sta     draw_rc
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

col:    lda     #hole_piece
        sta     position_table,y
        jsr     draw_col
        jmp     done

row:    lda     #hole_piece
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

;;; ==================================================
;;; Clear the background

draw_window:
        MGTK_CALL MGTK::SetPattern, pattern_speckles
        MGTK_CALL MGTK::PaintRect, fill_rect_params
        MGTK_CALL MGTK::SetPattern, pattern_black

        MGTK_CALL MGTK::MoveTo, set_pos_params
        MGTK_CALL MGTK::Line, line_params

        jsr     draw_all

        lda     #da_window_id
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, setport_params
        rts

;;; ==================================================

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

;;; ==================================================
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
        lda     #da_window_id
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
        lda     space_positions,x
        sta     paintbits_params::left
        lda     space_positions+1,x
        sta     paintbits_params::left+1
        lda     space_positions+2,x
        sta     paintbits_params::top
        lda     space_positions+3,x
        sta     paintbits_params::top+1
        lda     position_table,y
        asl     a
        tax
        lda     bitmap_table,x
        sta     paintbits_params::mapbits
        lda     bitmap_table+1,x
        sta     paintbits_params::mapbits+1
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

;;; ==================================================
;;; Play sound

.proc play_sound
        ldx     #$80
loop1:  lda     #$58
loop2:  ldy     #$1B
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

;;; ==================================================
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

;;; ==================================================
;;; Find hole piece

.proc find_hole
        ldy     #15
loop:   lda     position_table,y
        cmp     #hole_piece
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
