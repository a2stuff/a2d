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

        kDAWindowId = $80

;;; ============================================================
;;; Param Blocks

        .include "../lib/event_params.s"

        .res 1                  ; unused

.params trackgoaway_params
goaway: .byte   0
.endparams

.params getwinport_params
window_id:      .byte   kDAWindowId
a_grafport:     .addr   setport_params
.endparams

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

;;; Alternate table - when not yet scrambled (to the user), this is
;;; temporarily swapped in, scrambled, and swapped out every event
;;; loop tick. When (to the user) scrambling happens, it is swapped
;;; in for real.
swapped_table:
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
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  "............................"
piece2:
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".######.........###########."
        PIXELS  ".###...#.#.#.#.#....#######."
        PIXELS  "............................"
piece3:
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".################...#######."
        PIXELS  ".#############..#.#.#.#####."
        PIXELS  ".###########.#.#.#.#.#.####."
        PIXELS  ".#########..#.#.#.#.#.#####."
        PIXELS  ".########..#.#.#.#.#..#####."
        PIXELS  ".######...#.#.#.#.#..######."
        PIXELS  ".#####.#.#.#.#.#.#..#######."
        PIXELS  ".####.#.#.#.#.#...#########."
        PIXELS  ".###.#.#.#.#.#..###########."
        PIXELS  ".##.#.#.#.#....############."
        PIXELS  ".##..#.#.#..###############."
        PIXELS  ".##.#.#...#########........."
        PIXELS  ".##....########....#.#.#.#.."
        PIXELS  "............................"
piece4:
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  "....#######################."
        PIXELS  ".#.#....###################."
        PIXELS  "............................"
piece5:
        PIXELS  ".#########################.."
        PIXELS  ".#########################.."
        PIXELS  ".#######################.#.."
        PIXELS  ".######################.#.#."
        PIXELS  ".#####################.####."
        PIXELS  ".####################.#####."
        PIXELS  ".###################.######."
        PIXELS  ".##################.#######."
        PIXELS  ".##################.#######."
        PIXELS  ".#################.########."
        PIXELS  ".################.#########."
        PIXELS  ".################.#########."
        PIXELS  ".################.##.##.##.."
        PIXELS  ".###############.##.##.##.#."
        PIXELS  ".###############.#.##.##.##."
        PIXELS  "............................"
piece6:
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  "..#.#.#.#.#.#.#.#.#.#.#.#.#."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  "..#.#.#.#.#.#.#.#.#.#.#.#.#."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  "..##.##.##.##.##.##.##.##.#."
        PIXELS  ".##.##.##.##.##.##.##.##.##."
        PIXELS  ".#.##.##.##.##.##.##.##.##.."
        PIXELS  "............................"
piece7:
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  "..#.#.#.#.#.#.#.#.#.#.#.#.#."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  "..#.#.#.#.#.#.#.#.#.#.#.#.#."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##.##.##.##.##.##.##.##.##."
        PIXELS  ".#.##.##.##.##.##.##.##.##.."
        PIXELS  "..##.##.##.##.##.##.##.##.#."
        PIXELS  "............................"
piece8:
        PIXELS  ".#.#.#.#.#...##############."
        PIXELS  "..#.#.#.#.#.#..############."
        PIXELS  ".#.#.#.#.#.#.#...##########."
        PIXELS  "..#.#.#.#.#.#.#...#########."
        PIXELS  ".#############..###########."
        PIXELS  ".############.#############."
        PIXELS  ".###########.##############."
        PIXELS  ".##########.###############."
        PIXELS  ".#########.################."
        PIXELS  ".#########.################."
        PIXELS  ".########.#################."
        PIXELS  ".########.#################."
        PIXELS  ".#.##.##..#################."
        PIXELS  "..##.##..##################."
        PIXELS  ".##.##.#.##################."
        PIXELS  "............................"
piece9:
        PIXELS  ".################..##.##.##."
        PIXELS  ".################.##.##.##.."
        PIXELS  ".################.#.##.##.#."
        PIXELS  ".################..##.##.##."
        PIXELS  ".#################.#.#.#.#.."
        PIXELS  ".#################.#.#.#.#.."
        PIXELS  ".##################..#.#.#.."
        PIXELS  ".###################.#.#.#.."
        PIXELS  ".###################.#.#.#.."
        PIXELS  ".###################.#.#.#.."
        PIXELS  ".####################..#.#.."
        PIXELS  ".#####################..##.."
        PIXELS  ".######################..##."
        PIXELS  ".#######################.#.."
        PIXELS  ".########################.#."
        PIXELS  "............................"
piece10:
        PIXELS  ".#.##.##.##.##.##.##.##.##.."
        PIXELS  "..##.##.##.##.##.##.##.##.#."
        PIXELS  ".##.##.##.##.##.##.##.##.##."
        PIXELS  ".#.##.##.##.##.##.##.##.##.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#..##..##..##..##..##..##.."
        PIXELS  ".##..##..##..##..##..##..##."
        PIXELS  ".#..##..##..##..##..##..##.."
        PIXELS  ".##..##..##..##..##..##..##."
        PIXELS  "............................"
piece11:
        PIXELS  "..##.##.##.##.##.##.##.##.#."
        PIXELS  ".##.##.##.##.##.##.##.##.##."
        PIXELS  ".#.##.##.##.##.##.##.##.##.."
        PIXELS  "..##.##.##.##.##.##.##.##.#."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#.#.#.#.#.#.#.#.#.#.#.#.#.."
        PIXELS  ".#..##..##..##..##..##..##.."
        PIXELS  ".##..##..##..##..##..##..##."
        PIXELS  ".#..##..##..##..##..##..##.."
        PIXELS  ".##..##..##..##..##..##..##."
        PIXELS  "............................"
piece12:
        PIXELS  ".##.##.#.##################."
        PIXELS  ".#.##.##.##################."
        PIXELS  "..##.##.#.#################."
        PIXELS  ".##.##.##.#################."
        PIXELS  ".#.#.#.#.#.################."
        PIXELS  ".#.#.#.#.#..###############."
        PIXELS  ".#.#.#.#.#..###############."
        PIXELS  ".#.#.#.#.#.#.##############."
        PIXELS  ".#.#.#.#.#.#..#############."
        PIXELS  ".#.#.#.#.#.#.#..###########."
        PIXELS  ".#.#.#.#.#.#.#.#..#########."
        PIXELS  ".#..##..##..##..#.#########."
        PIXELS  ".##..##..##..##..##########."
        PIXELS  ".#..##..##..##...##########."
        PIXELS  ".##..##..##..##.###########."
        PIXELS  "............................"
piece13:                       ; the hole
        PIXELS  ".##########################."
        PIXELS  ".###.###.###.###.###.###.##."
        PIXELS  ".##########################."
        PIXELS  ".#.###.###.###.###.###.###.."
        PIXELS  ".##########################."
        PIXELS  ".###.###.###.###.###.###.##."
        PIXELS  ".##########################."
        PIXELS  ".#.###.###.###.###.###.###.."
        PIXELS  ".##########################."
        PIXELS  ".###.###.###.###.###.###.##."
        PIXELS  ".##########################."
        PIXELS  ".#.###.###.###.###.###.###.."
        PIXELS  ".##########################."
        PIXELS  ".###.###.###.###.###.###.##."
        PIXELS  ".##########################."
        PIXELS  "............................"
piece14:
        PIXELS  "...##..##..##..##..##..##..."
        PIXELS  ".#..##..##..##..##..##..##.."
        PIXELS  ".##..##..##..##..##..##..##."
        PIXELS  "..##.##.##.##.##.##.##.##.#."
        PIXELS  ".#..#.##.##.##.##.##.##.##.."
        PIXELS  ".##..#.##.##.##.##.##.##.##."
        PIXELS  ".###..#.##.##.##.##.##.##.#."
        PIXELS  ".#####..###.##.##.##.##.##.."
        PIXELS  ".#######...#.##.##.........."
        PIXELS  ".##########.........#######."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  "............................"
piece15:
        PIXELS  "...##..##..##..##..##..##..."
        PIXELS  ".#..##..##..##..##..##..##.."
        PIXELS  ".##..##..##..##..##..##..##."
        PIXELS  ".##.##.##.##.##.##.##.##.##."
        PIXELS  "..##.##.##.##.##.##.##.##.#."
        PIXELS  ".#.##.##.##.##.##.##.##.##.."
        PIXELS  ".##.##.##.##.##.##.##.##.##."
        PIXELS  "..##.##.##.##.##.##.##.##.#."
        PIXELS  "..................##.##.##.."
        PIXELS  ".###############..........#."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  "............................"
piece16:
        PIXELS  "...##..##..##...###########."
        PIXELS  ".#..##..##..##.############."
        PIXELS  ".##..##..##...#############."
        PIXELS  ".#.##.##.##..##############."
        PIXELS  ".##.##.##..################."
        PIXELS  "..##.##..##################."
        PIXELS  ".#.###..###################."
        PIXELS  ".#..#######################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  ".##########################."
        PIXELS  "............................"


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
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams
        winfo_viewloc_ycoord := winfo::viewloc::ycoord

pencopy:         .byte  MGTK::pencopy
notpenXOR:       .byte  MGTK::notpenXOR

name:   PASCAL_STRING res_string_window_title

scrambled_flag:                 ; bit7
        .byte   0

;;; ============================================================
;;; Create the window

.proc CreateWindow
        MGTK_CALL MGTK::OpenWindow, winfo

        ;; init pieces
        ldy     #15
    DO
        tya
        sta     position_table,y
        sta     swapped_table,y
    WHILE dey : POS

        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents

        jsr     DrawAll
        jsr     FindHole
        FALL_THROUGH_TO InputLoop
.endproc ; CreateWindow

;;; ============================================================
;;; Input loop and processing

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params

    IF bit scrambled_flag : NC
        jsr     PreScramble
    END_IF

        lda     event_params::kind
    IF A = #MGTK::EventKind::button_down
        jsr     OnClick
        jmp     InputLoop
    END_IF

        ;; key?
        cmp     #MGTK::EventKind::key_down
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
    IF ZERO
bail:   rts
    END_IF

        ;; client area?
    IF A = #MGTK::Area::content
      IF bit scrambled_flag : NC
        jmp     Scramble
      END_IF

        jsr     FindClickPiece
        bcc     bail
        jmp     ProcessClick
    END_IF

        ;; close port?
    IF A = #MGTK::Area::close_box
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        beq     bail
destroy:
        pla                     ; bust out of OnXXX proc
        pla
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
    END_IF

        ;; title bar?
        cmp     #MGTK::Area::dragbar
        bne     bail
        copy8   #kDAWindowId, dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
    IF bit dragwindow_params::moved : NS
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        jmp     DrawWindow
    END_IF

ret:    rts
.endproc ; OnClick

        ;; on key press - exit if Escape
.proc CheckKey
        lda     event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        beq     OnClick::destroy
        bne     ret             ; always
    END_IF

        cmp     #CHAR_ESCAPE
        beq     OnClick::destroy

    IF bit scrambled_flag : NC
        jmp     Scramble
    END_IF

        ldx     hole_x
        ldy     hole_y

    IF A = #CHAR_DOWN
        dey
        bmi     ret
        bpl     move            ; always
    END_IF

    IF A = #CHAR_UP
        iny
        cpy     #4
        bcs     ret
        bcc     move            ; always
    END_IF

    IF A = #CHAR_RIGHT
        dex
        bmi     ret
        bpl     move            ; always
    END_IF

    IF A = #CHAR_LEFT
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
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     screentowindow_params::windowx+1
        ora     screentowindow_params::windowy+1
        bne     nope            ; ensure high bytes are 0

        lda     screentowindow_params::windowy
        ldx     screentowindow_params::windowx

        cmp     #kRow1
        bcc     nope
    IF A < #kRow2+1
        jsr     FindClickX
        bcc     nope
        lda     #0
        beq     yep             ; always
    END_IF

    IF A < #kRow3+1
        jsr     FindClickX
        bcc     nope
        lda     #1
        bne     yep             ; always
    END_IF

    IF A < #kRow4+1
        jsr     FindClickX
        bcc     nope
        lda     #2
        bne     yep             ; always
    END_IF

        cmp     #kRow4+kRowHeight+1
        bcs     nope
        jsr     FindClickX
        bcc     nope
        lda     #3

yep:    sta     click_y
        RETURN  C=1

nope:   RETURN  C=0
.endproc ; FindClickPiece

.proc FindClickX
        cpx     #kCol1
        bcc     nope
    IF X < #kCol2
        lda     #0
        beq     yep             ; always
    END_IF

    IF X < #kCol3+1
        lda     #1
        bne     yep             ; always
    END_IF

    IF X < #kCol4+1
        lda     #2
        bne     yep             ; always
    END_IF

        cpx     #kCol4+kColWidth
        bcs     nope
        lda     #3

yep:    sta     click_x
        RETURN  C=1

nope:   RETURN  C=0
.endproc ; FindClickX

;;; ============================================================
;;; Process piece click

        kHolePiece = 12

.proc ProcessClick

        lda     #0
        ldy     hole_y
    IF NOT_ZERO
      DO
        clc
        adc     #4
      WHILE dey : NOT_ZERO
    END_IF

        sta     draw_rc
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
    IF LT
        lda     hole_x          ; click before of hole
        sec
        sbc     click_x
        tax
      DO
        copy8   position_table-1,y, position_table,y
        dey
        dex
      WHILE NOT_ZERO
        beq     row             ; always
    END_IF

        lda     click_x         ; click after hole
        sec
        sbc     hole_x
        tax
    DO
        copy8   position_table+1,y, position_table,y
        iny
    WHILE dex : NOT_ZERO
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

    DO
        copy8   position_table-4,y, position_table,y
        dey
        dey
        dey
        dey
    WHILE dex : NOT_ZERO
        beq     col

after:  lda     click_y         ; click after hole
        sec
        sbc     hole_y
        tax
    DO
        copy8   position_table+4,y, position_table,y
        iny
        iny
        iny
        iny
    WHILE dex : NOT_ZERO
.endproc ; ClickInCol

col:    copy8   #kHolePiece, position_table,y
        jsr     DrawCol
        jmp     done

row:    copy8   #kHolePiece, position_table,y
        jsr     DrawRow

done:   jsr     CheckVictory
        bcc     after_click

        ;; Yay! Play the sound 4 times
.proc OnVictory
        ldx     #4
    DO
        txa
        pha
        jsr     PlaySound
        jsr     InvertWindow
        pla
        tax
    WHILE dex : NOT_ZERO
        CLEAR_BIT7_FLAG scrambled_flag
.endproc ; OnVictory

after_click:
        jmp     FindHole
.endproc ; ProcessClick

;;; ============================================================
;;; Draw the DA window

.proc DrawWindow
        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF ZERO                     ; not obscured
        MGTK_CALL MGTK::SetPort, setport_params

        MGTK_CALL MGTK::SetPattern, pattern_speckles
        MGTK_CALL MGTK::PaintRect, paintrect_params
        MGTK_CALL MGTK::SetPattern, pattern_black

        MGTK_CALL MGTK::MoveTo, moveto_params
        MGTK_CALL MGTK::Line, line_params

        jsr     DrawAll
    END_IF
        rts
.endproc ; DrawWindow

;;; ============================================================
;;; Draw pieces

.proc DrawAll
        ldy     #1
        sty     draw_inc
        dey
        copy8   #16, draw_end
        bne     DrawSelected    ; always
.endproc ; DrawAll

.proc DrawRow                   ; row specified in draw_rc
        copy8   #1, draw_inc
        lda     draw_rc
        tay
        clc
        adc     #4
        sta     draw_end
        bne     DrawSelected    ; always
.endproc ; DrawRow

.proc DrawCol                   ; col specified in `draw_rc`
        copy8   #4, draw_inc
        ldy     hole_x
        copy8   #16, draw_end
        FALL_THROUGH_TO DrawSelected
.endproc ; DrawCol

        ;; Draw pieces from A to `draw_end`, step `draw_inc`
.proc DrawSelected
        tya
        pha
        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF NOT_ZERO
        ;; obscured
        pla
        rts
    END_IF
        MGTK_CALL MGTK::SetPort, setport_params
        MGTK_CALL MGTK::HideCursor
        pla
        tay

    DO
        tya
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
    WHILE Y < draw_end

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

.proc InvertWindow
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     ret             ; obscured
        MGTK_CALL MGTK::SetPort, setport_params

        MGTK_CALL MGTK::SetPattern, pattern_black
        MGTK_CALL MGTK::SetPenMode, notpenXOR
        MGTK_CALL MGTK::PaintRect, paintrect_params
        MGTK_CALL MGTK::SetPenMode, pencopy

ret:    rts
.endproc ; InvertWindow

;;; ============================================================
;;; Puzzle complete?

        ;; Returns with carry set if puzzle complete
.proc CheckVictory        ; Allows for swapped indistinct pieces, etc.
        ;; 0/12 can be swapped
        lda     position_table
    IF NOT_ZERO
        cmp     #12
        bne     nope
    END_IF

        ;; Check 1/2/3/4
        ldy     #1
    DO
        tya
        cmp     position_table,y
        bne     nope
    WHILE iny : Y < #5

        ;; 5/6 are identical
        lda     position_table+5
    IF A <> #5
        cmp     #6
        bne     nope
    END_IF

        lda     position_table+6
    IF A <> #5
        cmp     #6
        bne     nope
    END_IF

        ;; Check 7/8
        lda     position_table+7
        cmp     #7
        bne     nope
        lda     position_table+8
        cmp     #8
        bne     nope

        ;; 9/10 are identical
        lda     position_table+9
    IF A <> #9
        cmp     #10
        bne     nope
    END_IF

        lda     position_table+10
    IF A <> #9
        cmp     #10
        bne     nope
    END_IF

        ;; Check 11
        lda     position_table+11
        cmp     #11
        bne     nope

        ;; 0/12 can be swapped
        lda     position_table+12
    IF NOT_ZERO
        cmp     #12
        bne     nope
    END_IF

        ;; Check 13/14/15/16
        ldy     #13
    DO
        tya
        cmp     position_table,y
        bne     nope
    WHILE iny : Y < #16
        rts

nope:   RETURN  C=0
.endproc ; CheckVictory

;;; ============================================================
;;; Find hole piece

.proc FindHole
        ldy     #15
    DO
        lda     position_table,y
        BREAK_IF A = #kHolePiece
        dey
    WHILE POS                   ; always

        lda     #0
        sta     hole_x
        sta     hole_y

        tya
    DO
        BREAK_IF A < #4
        sbc     #4
        inc     hole_y
    WHILE NOT_ZERO

        sta     hole_x
        rts
.endproc ; FindHole

;;; ============================================================

;;; Called during event loop if not scrambled - gets the puzzle good
;;; and randomized.
.proc PreScramble
        jsr     SwapTables      ; save

redo:
        ldy     #3

    DO
        tya
        pha
        ldx     position_table
        ldy     #0
      DO
        copy8   position_table+1,y, position_table,y
      WHILE iny : Y < #15

        stx     position_table+15
        pla
        tay
    WHILE dey : NOT_ZERO

        swap8   position_table, position_table+1

        jsr     CheckVictory
        bcs     redo

        jmp     SwapTables      ; restore
.endproc ; PreScramble

;;; ============================================================

;;; Called to apply the scrambled positions and paint
.proc Scramble
        jsr     SwapTables      ; swap

        SET_BIT7_FLAG scrambled_flag
        jsr     DrawAll
        jsr     FindHole

        rts
.endproc ; Scramble

;;; ============================================================

.proc SwapTables
        ldy     #15
    DO
        swap8   position_table,y, swapped_table,y
    WHILE dey : POS
        rts
.endproc ; SwapTables

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX aux::CreateWindow
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
