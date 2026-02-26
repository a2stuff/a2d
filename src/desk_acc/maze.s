;;; ============================================================
;;; MAZE - Desk Accessory
;;;
;;; Draws a random maze.
;;; ============================================================

        .include "../config.inc"

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

.macro PHXY
        txa                     ; Save X,Y
        pha
        tya
        pha
.endmacro

.macro PLXY
        pla                     ; Restore X,Y
        tay
        pla
        tax
.endmacro

;;; ============================================================
;;; Graphics Resources

event_params:   .tag MGTK::Event
grafport:       .tag MGTK::GrafPort
checkerboard_pattern:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

carvepen:       .byte MGTK::penOR
wallpen:        .byte MGTK::penBIC
pencopy:        .byte MGTK::pencopy

;;; ============================================================
;;; DA Init

.proc Init
        jsr     InitRand

        copy16  #0, counter

        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     exit
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     exit

        lda     counter
        ora     counter+1
    IF ZERO
        copy16  #kCountdown, counter
        jsr     InitMaze
    END_IF
        dec16   counter

        MGTK_CALL MGTK::WaitVBL
        jsr     StepMaze
        jmp     InputLoop

exit:
        MGTK_CALL MGTK::RedrawDeskTop

        MGTK_CALL MGTK::DrawMenuBar
        JSR_TO_MAIN JUMP_TABLE_HILITE_MENU

        MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; InputLoop

kSecondsBetweenMazes = 10
kCountdown = kNumCells + 60 * kSecondsBetweenMazes
counter:        .word   0

;;; ============================================================

.proc ClearScreen
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        MGTK_CALL MGTK::PaintRect, grafport + MGTK::GrafPort::maprect
        MGTK_CALL MGTK::SetPenMode, pencopy
        rts
.endproc ; ClearScreen

;;; ============================================================

kCellWidth  = 14
kCellHeight =  8
kNumCols    = 40
kNumRows    = 24
kNumCells = kNumCols * kNumRows

.params paintbits_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   pixels_cell
mapwidth:       .byte   kCellWidth / 7
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCellWidth-1, kCellHeight-1
        REF_MAPINFO_MEMBERS
.endparams

.proc InitMaze
        jsr     ClearScreen
        jsr     ClearVisitedCells
        copy16  #0, stack_size

        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport

        ;; Random starting position
     DO
        jsr     Random
        and     #63
     WHILE A >= #kNumCols
        pha
     DO
        jsr     Random
        and     #31
     WHILE A >= #kNumRows
        tay
        pla
        tax
        jsr     VisitCell

        FALL_THROUGH_TO DoMaze
.endproc ; InitMaze

.proc DoMaze
backtrack:
        jsr     PopCell
        RTS_IF  CS              ; done!
        stx     col
        sty     row

step:
        ldx     col
        ldy     row

        jsr     CountFreeNeighbors
        beq     backtrack

        ;; At least one neighbor free - try directions at random until
        ;; we find one.
    REPEAT
        jsr     Random
        and     #3              ; 0..3

        ldx     col
        ldy     row

        ;; Try right
      IF A = #0
        inx
        jsr     IsCellFree
        REDO_IF CS
        jsr     VisitCell
        jsr     CarveLeft
        jmp     yield
      END_IF

        ;; Try down
      IF A = #1
        iny
        jsr     IsCellFree
        REDO_IF CS
        jsr     VisitCell
        jsr     CarveUp
        jmp     yield
      END_IF

        ;; Try left
      IF A = #2
        dex
        jsr     IsCellFree
        REDO_IF CS
        jsr     VisitCell
        jsr     CarveRight
        jmp     yield
      END_IF

        ;; Try up
      IF A = #3
        dey
        jsr     IsCellFree
        REDO_IF CS
        jsr     VisitCell
        jsr     CarveDown
        jmp     yield
      END_IF

        ;; Try another random direction; we know one is free!
    FOREVER

yield:
        stx     col
        sty     row
        clc
        rts

row:    .byte   0
col:    .byte   0
.endproc ; DoMaze
StepMaze := DoMaze::step

;;; ============================================================

;;; Input: X,Y = col,row
;;; Output X,Y unchanged
.proc VisitCell
        PHXY

        jsr     SetPaintCoords

        ;; Add to stack
        jsr     PushCell

        ;; Mark visited
        ptr := $06
        jsr     SetVisitedCellPtr
        ldy     #0
        lda     #$FF
        sta     (ptr),y

        ;; Paint it
        copy16  #pixels_cell, paintbits_params::mapbits
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintBits, paintbits_params

        PLXY
        rts
.endproc ; VisitCell

;;; Input: X,Y = col,row
;;; Output: X,Y unchanged
.proc PushCell
        PHXY

        ptr := $06
        add16   stack_size, #stack_y, ptr
        tya
        ldy     #0
        sta     (ptr),y

        add16   stack_size, #stack_x, ptr
        txa
        ldy     #0
        sta     (ptr),y

        inc16   stack_size

        PLXY
        rts
.endproc ; PushCell

;;; Output: C=1 if stack empty, else X,Y = col,row
.proc PopCell
        lda     stack_size
        ora     stack_size+1
    IF ZERO
        sec
        rts
    END_IF

        dec16   stack_size

        ptr := $06
        add16   stack_size, #stack_x, ptr
        ldy     #0
        lda     (ptr),y
        tax

        add16   stack_size, #stack_y, ptr
        ldy     #0
        lda     (ptr),y
        tay

        clc
        rts
.endproc ; PopCell

.proc ClearVisitedCells
        ;; Clear the visited cell table
        ptr := $06
        copy16  #visited_cells + kNumCells - 1, ptr
        ldy     #0
    DO
        tya
        sta     (ptr),y
        dec16   ptr
        cmp16   ptr, #visited_cells
    WHILE GE
        rts
.endproc ; ClearVisitedCells

;;; Input: X,Y = col,row
;;; Output: C=0 if free, C=1 if used; $06 set to `visited_cells` entry; X,Y unchanged
.proc IsCellFree
        PHXY

        cpx     #kNumCols
        bcs     used
        cpy     #kNumRows
        bcs     used

        jsr     SetVisitedCellPtr
        ldy     #0
        lda     ($06),y
        bne     used
        FALL_THROUGH_TO free

free:   clc
        bcc     restore


used:   sec
        FALL_THROUGH_TO restore

restore:
        PLXY
        rts
.endproc ; IsCellFree

;;; Input: X,Y = col,row
;;; Output: $06 is pointer into `visited_cells`
.proc SetVisitedCellPtr
        ptr := $06

        lda     ptr_table_lo,y
        sta     ptr
        lda     ptr_table_hi,y
        sta     ptr+1

        txa
        clc
        adc     ptr
        sta     ptr
        lda     #0
        adc     ptr+1
        sta     ptr+1

        rts
.endproc ; SetVisitedCellPtr

;;; ============================================================

;;; Input: X,Y = col,row
;;; Output: A/Z = num free neighbors
.proc CountFreeNeighbors
        stx     col
        sty     row

        copy8   #0, count

        ;; Try right
        ldx     col
        ldy     row
        inx
        jsr     IsCellFree
    IF CC
        inc     count
    END_IF

        ;; Try down
        ldx     col
        ldy     row
        iny
        jsr     IsCellFree
    IF CC
        inc     count
    END_IF

        ;; Try left
        ldx     col
        ldy     row
        dex
        jsr     IsCellFree
    IF CC
        inc     count
    END_IF

        ;; Try up
        ldx     col
        ldy     row
        dey
        jsr     IsCellFree
    IF CC
        inc     count
    END_IF

        lda     count
        rts

count:  .byte   0
row:    .byte   0
col:    .byte   0

.endproc ; CountFreeNeighbors

;;; ============================================================

;;; Input: X,Y = col,row
;;; Output: X,Y unchanged
.proc SetPaintCoords
        copylohi x_table_lo,x, x_table_hi,x, paintbits_params::viewloc::xcoord
        copylohi y_table_lo,y, y_table_hi,y, paintbits_params::viewloc::ycoord
        rts
.endproc ; SetPaintCoords

;;; ============================================================

;;; Input: X,Y = starting cell
;;; Output: X,Y unchanged
.proc CarveRight
        jsr     DrawRight
        inx
        jsr     DrawLeft
        dex
        rts
.endproc ; CarveRight

;;; Input: X,Y = starting cell
;;; Output: X,Y unchanged
.proc CarveLeft
        jsr     DrawLeft
        dex
        jsr     DrawRight
        inx
        rts
.endproc ; CarveLeft

;;; Input: X,Y = starting cell
;;; Output: X,Y unchanged
.proc CarveDown
        jsr     DrawDown
        iny
        jsr     DrawUp
        dey
        rts
.endproc ; CarveDown

;;; Input: X,Y = starting cell
;;; Output: X,Y unchanged
.proc CarveUp
        jsr     DrawUp
        dey
        jsr     DrawDown
        iny
        rts
.endproc ; CarveUp

;;; ============================================================

;;; Input: X,Y = starting cell
;;; Output: X,Y unchanged
.proc DrawRight
        PHXY
        jsr     SetPaintCoords
        copy16  #pixels_right_w, paintbits_params::mapbits
        MGTK_CALL MGTK::SetPenMode, carvepen
        MGTK_CALL MGTK::PaintBits, paintbits_params
        copy16  #pixels_right_b, paintbits_params::mapbits
        MGTK_CALL MGTK::SetPenMode, wallpen
        MGTK_CALL MGTK::PaintBits, paintbits_params
        PLXY
        rts
.endproc ; DrawRight

;;; Input: X,Y = starting cell
;;; Output: X,Y unchanged
.proc DrawLeft
        PHXY
        jsr     SetPaintCoords
        copy16  #pixels_left_w, paintbits_params::mapbits
        MGTK_CALL MGTK::SetPenMode, carvepen
        MGTK_CALL MGTK::PaintBits, paintbits_params
        copy16  #pixels_left_b, paintbits_params::mapbits
        MGTK_CALL MGTK::SetPenMode, wallpen
        MGTK_CALL MGTK::PaintBits, paintbits_params
        PLXY
        rts
.endproc ; DrawLeft

;;; Input: X,Y = starting cell
;;; Output: X,Y unchanged
.proc DrawDown
        PHXY
        jsr     SetPaintCoords
        copy16  #pixels_bottom_w, paintbits_params::mapbits
        MGTK_CALL MGTK::SetPenMode, carvepen
        MGTK_CALL MGTK::PaintBits, paintbits_params
        copy16  #pixels_bottom_b, paintbits_params::mapbits
        MGTK_CALL MGTK::SetPenMode, wallpen
        MGTK_CALL MGTK::PaintBits, paintbits_params
        PLXY
        rts
.endproc ; DrawDown

;;; Input: X,Y = starting cell
;;; Output: X,Y unchanged
.proc DrawUp
        PHXY
        jsr     SetPaintCoords
        copy16  #pixels_top_w, paintbits_params::mapbits
        MGTK_CALL MGTK::SetPenMode, carvepen
        MGTK_CALL MGTK::PaintBits, paintbits_params
        copy16  #pixels_top_b, paintbits_params::mapbits
        MGTK_CALL MGTK::SetPenMode, wallpen
        MGTK_CALL MGTK::PaintBits, paintbits_params
        PLXY
        rts
.endproc ; DrawUp

;;; ============================================================

;;; Offsets for `visited_cells`
ptr_table_lo:
        .repeat kNumRows, i
        .byte   .lobyte(visited_cells + kNumCols * i)
        .endrepeat
ptr_table_hi:
        .repeat kNumRows, i
        .byte   .hibyte(visited_cells + kNumCols * i)
        .endrepeat

;;; Offsets for drawing
x_table_lo:
        .repeat kNumCols, i
        .byte   .lobyte(kCellWidth * i)
        .endrepeat
x_table_hi:
        .repeat kNumCols, i
        .byte   .hibyte(kCellWidth * i)
        .endrepeat
y_table_lo:
        .repeat kNumRows, i
        .byte   .lobyte(kCellHeight * i)
        .endrepeat
y_table_hi:
        .repeat kNumRows, i
        .byte   .hibyte(kCellHeight * i)
        .endrepeat

pixels_cell:
        PIXELS ".#.#.#.#.#.#.#"
        PIXELS "#...........#."
        PIXELS ".#..######...#"
        PIXELS "#...######..#."
        PIXELS ".#..######...#"
        PIXELS "#...######..#."
        PIXELS ".#...........#"
        PIXELS "#.#.#.#.#.#.#."

pixels_top_w:
        PIXELS "....######...."
        PIXELS "....######...."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."

pixels_top_b:
        PIXELS "..##......##.."
        PIXELS "..##......##.."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."

pixels_bottom_w:
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS "....######...."
        PIXELS "....######...."

pixels_bottom_b:
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS "..##......##.."
        PIXELS "..##......##.."

pixels_left_w:
        PIXELS ".............."
        PIXELS ".............."
        PIXELS "####.........."
        PIXELS "####.........."
        PIXELS "####.........."
        PIXELS "####.........."
        PIXELS ".............."
        PIXELS ".............."

pixels_left_b:
        PIXELS ".............."
        PIXELS "####.........."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS "####.........."
        PIXELS ".............."

pixels_right_w:
        PIXELS ".............."
        PIXELS ".............."
        PIXELS "..........####"
        PIXELS "..........####"
        PIXELS "..........####"
        PIXELS "..........####"
        PIXELS ".............."
        PIXELS ".............."

pixels_right_b:
        PIXELS ".............."
        PIXELS "..........####"
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS ".............."
        PIXELS "..........####"
        PIXELS ".............."


;;; ============================================================

        .include "../lib/prng.s"

;;; ============================================================




stack_size:
        .word   0

        .assert ($2000 - *) >= (3 * kNumCells), error, "not enough space"

visited_cells := *
stack_x       := * + kNumCells
stack_y       := * + kNumCells * 2

        .out .sprintf("Space remaining: %d", ($2000 - * - (3 * kNumCells)))

        .out .sprintf("visited_cells: %04X", visited_cells)
        .out .sprintf("stack_size: %04X", stack_size)
        .out .sprintf("stack_x: %04X", stack_x)
        .out .sprintf("stack_y: %04X", stack_y)

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX aux::Init
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
