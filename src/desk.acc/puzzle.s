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

scrambled_flag:
        .byte   0

;;; ============================================================
;;; Create the window

.proc CreateWindow
        MGTK_CALL MGTK::OpenWindow, winfo

        ;; init pieces
        ldy     #15
loop:   tya
        sta     position_table,y
        sta     swapped_table,y
        dey
        bpl     loop

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

        bit     scrambled_flag
    IF_NC
        jsr     PreScramble
    END_IF

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

        bit     scrambled_flag
    IF_NC
        jmp     Scramble
    END_IF

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
        bit     dragwindow_params::moved
        bpl     ret
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        jmp     DrawWindow

ret:    rts
.endproc ; OnClick

        ;; on key press - exit if Escape
.proc CheckKey
        lda     event_params::key

        ldx     event_params::modifiers
    IF_NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        beq     OnClick::destroy
        bne     ret             ; always
    END_IF

        cmp     #CHAR_ESCAPE
        beq     OnClick::destroy

        bit     scrambled_flag
    IF_NC
        jmp     Scramble
    END_IF

        ldx     hole_x
        ldy     hole_y

    IF_A_EQ     #CHAR_DOWN
        dey
        bmi     ret
        bpl     move            ; always
    END_IF

    IF_A_EQ     #CHAR_UP
        iny
        cpy     #4
        bcs     ret
        bcc     move            ; always
    END_IF

    IF_A_EQ     #CHAR_RIGHT
        dex
        bmi     ret
        bpl     move            ; always
    END_IF

    IF_A_EQ     #CHAR_LEFT
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
        jsr     InvertWindow
        pla
        tax
        dex
        bne     loop

        copy8   #0, scrambled_flag
.endproc ; OnVictory

after_click:
        jmp     FindHole
.endproc ; ProcessClick

;;; ============================================================
;;; Draw the DA window

.proc DrawWindow
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     ret             ; obscured
        MGTK_CALL MGTK::SetPort, setport_params

        MGTK_CALL MGTK::SetPattern, pattern_speckles
        MGTK_CALL MGTK::PaintRect, paintrect_params
        MGTK_CALL MGTK::SetPattern, pattern_black

        MGTK_CALL MGTK::MoveTo, moveto_params
        MGTK_CALL MGTK::Line, line_params

        jsr     DrawAll

ret:    rts
.endproc ; DrawWindow

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

.proc DrawCol                   ; col specified in `draw_rc`
        lda     #4
        sta     draw_inc
        ldy     hole_x
        lda     #16
        sta     draw_end
        FALL_THROUGH_TO DrawSelected
.endproc ; DrawCol

        ;; Draw pieces from A to `draw_end`, step `draw_inc`
.proc DrawSelected
        tya
        pha
        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF_NOT_ZERO
        ;; obscured
        pla
        rts
    END_IF
        MGTK_CALL MGTK::SetPort, setport_params
        MGTK_CALL MGTK::HideCursor
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

;;; Called during event loop if not scrambled - gets the puzzle good
;;; and randomized.
.proc PreScramble
        jsr     SwapTables      ; save

redo:
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

        jsr     CheckVictory
        bcs     redo

        jmp     SwapTables      ; restore
.endproc ; PreScramble

;;; ============================================================

;;; Called to apply the scrambled positions and paint
.proc Scramble
        jsr     SwapTables      ; swap

        copy8   #$80, scrambled_flag
        jsr     DrawAll
        jsr     FindHole

        rts
.endproc ; Scramble

;;; ============================================================

.proc SwapTables
        ldy     #15
:       lda     position_table,y
        ldx     swapped_table,y
        sta     swapped_table,y
        txa
        sta     position_table,y
        dey
        bpl     :-
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
