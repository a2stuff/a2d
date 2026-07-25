;;; ============================================================
;;; MINESWEEPER - Desk Accessory
;;;
;;; Don't blow up
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "minesweeper.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
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

;;; TODO: Make dynamic
kBoardWidth = 10
kBoardHeight = 10
kNumMines = 10

.params trackgoaway_params
goaway: .byte   0
.endparams

.params getwinport_params
window_id:      .byte   kDAWindowId
a_grafport:     .addr   grafport
.endparams
grafport:       .tag    MGTK::GrafPort

kDAWidth        = kTileWidth * kBoardWidth + 2*kHPadding - 2
kDAHeight       = kTileHeight * kBoardHeight + 2*kVPadding - 2
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight


.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

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
mincontwidth:   .word   kDAWidth
mincontheight:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontheight:  .word   kDAHeight
port:
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
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

name:   PASCAL_STRING res_string_window_title

pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy
penBIC:         .byte   MGTK::penBIC


kHPadding = 0
kVPadding = 0

;;; ============================================================

kTileWidth = 17
kTileHeight = 9
.params paintbits_params
        DEFINE_POINT viewloc, SELF_MODIFIED, SELF_MODIFIED
mapbits:        .addr   SELF_MODIFIED
mapwidth:       .byte   (kTileWidth+6)/7
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kTileWidth-1, kTileHeight-1
        REF_MAPINFO_MEMBERS
.endparams

        DEFINE_RECT shield_rect, 0, 0, 0, 0

bits_hidden:
        PIXELS "................#"
        PIXELS "....#...#...#...#"
        PIXELS "..#...#...#...#.#"
        PIXELS "....#...#...#...#"
        PIXELS "..#...#...#...#.#"
        PIXELS "....#...#...#...#"
        PIXELS "..#...#...#...#.#"
        PIXELS "....#...#...#...#"
        PIXELS "#################"
.if 0
bits_flag:
        PIXELS "................."
        PIXELS "...########......"
        PIXELS "...########......"
        PIXELS "...########......"
        PIXELS ".........##......"
        PIXELS ".........##......"
        PIXELS ".........##......"
        PIXELS ".......######...."
        PIXELS "................."
.endif
bits_flag_precomposed:
        PIXELS "................#"
        PIXELS "...########.#...#"
        PIXELS "..#########...#.#"
        PIXELS "...########.#...#"
        PIXELS "..#...#..##...#.#"
        PIXELS "....#...###.#...#"
        PIXELS "..#...#..##...#.#"
        PIXELS "....#..######...#"
        PIXELS "#################"
.if 0
bits_question:
        PIXELS "................."
        PIXELS "....########....."
        PIXELS "...###....###...."
        PIXELS "..........###...."
        PIXELS "........###......"
        PIXELS "......###........"
        PIXELS "................."
        PIXELS "......###........"
        PIXELS "................."
.endif
bits_question_precomposed:
        PIXELS "................#"
        PIXELS "....#########...#"
        PIXELS "..#####...###.#.#"
        PIXELS "....#...#.###...#"
        PIXELS "..#...#.###...#.#"
        PIXELS "....#.###...#...#"
        PIXELS "..#...#...#...#.#"
        PIXELS "....#.###...#...#"
        PIXELS "#################"
bits_mine:
        PIXELS "................."
        PIXELS "....#...#...#...."
        PIXELS ".....#######....."
        PIXELS "....##.######...."
        PIXELS "..###..########.."
        PIXELS "....#########...."
        PIXELS ".....#######....."
        PIXELS "....#...#...#...."
        PIXELS "................."
bits_mine_precomposed:
        PIXELS "................#"
        PIXELS "....#...#...#...#"
        PIXELS "..#..#######..#.#"
        PIXELS "....##.######...#"
        PIXELS "..###.#########.#"
        PIXELS "....#########...#"
        PIXELS "..#..#######..#.#"
        PIXELS "....#...#...#...#"
        PIXELS "#################"
bits_x:
        PIXELS "##.............##"
        PIXELS "..##.........##.."
        PIXELS "....##.....##...."
        PIXELS "......##.##......"
        PIXELS ".......###......."
        PIXELS "......##.##......"
        PIXELS "....##.....##...."
        PIXELS "..##.........##.."
        PIXELS "##.............##"
bits_0:
        PIXELS "................."
        PIXELS "................#"
        PIXELS "................."
        PIXELS "................#"
        PIXELS "................."
        PIXELS "................#"
        PIXELS "................."
        PIXELS "................#"
        PIXELS "..#...#...#...#.."
bits_1:
        PIXELS "................."
        PIXELS ".......##.......#"
        PIXELS "......###........"
        PIXELS ".......##.......#"
        PIXELS ".......##........"
        PIXELS ".......##.......#"
        PIXELS ".....######......"
        PIXELS "................#"
        PIXELS "..#...#...#...#.."
bits_2:
        PIXELS "................."
        PIXELS ".....######.....#"
        PIXELS "....##....##....."
        PIXELS "........###.....#"
        PIXELS "......### ......."
        PIXELS "....###.........#"
        PIXELS "....########....."
        PIXELS "................#"
        PIXELS "..#...#...#...#.."
bits_3:
        PIXELS "................."
        PIXELS "....#######.....#"
        PIXELS "..........##....."
        PIXELS ".......####.....#"
        PIXELS "..........##....."
        PIXELS "..........##....#"
        PIXELS "....#######......"
        PIXELS "................#"
        PIXELS "..#...#...#...#.."
bits_4:
        PIXELS "................."
        PIXELS ".........##.....#"
        PIXELS "....##...##......"
        PIXELS "....##...##.....#"
        PIXELS "....########....."
        PIXELS ".........##.....#"
        PIXELS ".........##......"
        PIXELS "................#"
        PIXELS "..#...#...#...#.."
bits_5:
        PIXELS "................."
        PIXELS "....########....#"
        PIXELS "....##..........."
        PIXELS "....#######.....#"
        PIXELS "..........##....."
        PIXELS "....##....##....#"
        PIXELS ".....######......"
        PIXELS "................#"
        PIXELS "..#...#...#...#.."
bits_6:
        PIXELS "................."
        PIXELS ".....#####......#"
        PIXELS "....##..........."
        PIXELS "....#######.....#"
        PIXELS "....##....##....."
        PIXELS "....##....##....#"
        PIXELS ".....######......"
        PIXELS "................#"
        PIXELS "..#...#...#...#.."
bits_7:
        PIXELS "................."
        PIXELS "....########....#"
        PIXELS "..........##....."
        PIXELS ".........##.....#"
        PIXELS "........##......."
        PIXELS ".......##.......#"
        PIXELS ".......##........"
        PIXELS "................#"
        PIXELS "..#...#...#...#.."
bits_8:
        PIXELS "................."
        PIXELS ".....######.....#"
        PIXELS "....##....##....."
        PIXELS ".....######.....#"
        PIXELS "....##....##....."
        PIXELS "....##....##....#"
        PIXELS ".....######......"
        PIXELS "................#"
        PIXELS "..#...#...#...#.."

num_table:
        .addr   bits_0, bits_1, bits_2, bits_3, bits_4, bits_5, bits_6, bits_7, bits_8


;;; ============================================================

;;; Game State

kMaxWidth = 10
kMaxHeight = 10

board_state:    .res(kMaxWidth * kMaxHeight)

kCellMine       = 1 << 7        ; not shown until end of game
kCellRevealed   = 1 << 6
kCellUnknown    = 0 << 4        ; initial state
kCellFlag       = 1 << 4        ; mod+click once
kCellQuestion   = 2 << 4        ; mod+click twice
kCellX          = 3 << 4        ; bad guess (only at end)
kCellFlagsMask  = $30
kCellNumMask    = $0F           ; count of adjacent mines in low nibble
kCellBoom       = $FF           ; special state

game_over_flag: .byte   0       ; bit7

;;; ============================================================

.macro PUSH_XY
        txa
        pha
        tya
        pha
.endmacro

.macro PULL_XY
        pla
        tay
        pla
        tax
.endmacro

;;; ============================================================
;;; Create the window

.proc CreateWindow
        jsr     InitRand
        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     InitBoard
        jsr     DrawWindow
        FALL_THROUGH_TO InputLoop
.endproc ; CreateWindow

;;; ============================================================
;;; Input loop and processing

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params

        lda     event_params::kind
    IF A = #MGTK::EventKind::button_down OR A = #MGTK::EventKind::apple_key
        jsr     OnClick
        jmp     InputLoop
    END_IF

    IF A = #MGTK::EventKind::key_down
        jsr     OnKey
        jmp     InputLoop
    END_IF

        jmp     InputLoop
.endproc ; InputLoop

;;; ============================================================

.proc OnClick
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
    IF A = #kDAWindowId
        lda     findwindow_params::which_area

        cmp     #MGTK::Area::close_box
        beq     DoClose

        cmp     #MGTK::Area::dragbar
        beq     DoDrag

        cmp     #MGTK::Area::content
        beq     DoClick
    END_IF
        rts
.endproc ; OnClick

;;; ============================================================

.proc OnKey
        lda     event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        beq     DoQuit
        rts
    END_IF

        cmp     #CHAR_ESCAPE
        beq     DoQuit

        ;; TODO: Other keys?

        rts
.endproc ; OnKey

;;; ============================================================

.proc DoClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        bne     DoQuit
        rts
.endproc ; DoClose

;;; ============================================================

.proc DoDrag
        copy8   #kDAWindowId, dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
    IF bit dragwindow_params::moved : NS
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        jsr     DrawWindow
    END_IF

        rts
.endproc ; DoDrag

;;; ============================================================

.proc DoQuit
        pla                     ; bust out of `OnXXX` proc
        pla
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; DoQuit

;;; ============================================================

.proc DoClick
        bit     game_over_flag
    IF NS
        CLEAR_BIT7_FLAG game_over_flag
        jsr     InitBoard
        TAIL_CALL DrawWindow
    END_IF

        copy8   event_params::kind, event_kind

        copy8   winfo::window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        xcoord := screentowindow_params::windowx
        ycoord := screentowindow_params::windowy

        ;; NOTE: `sub16` is used not `sub16_8` so that N flag is set
        sub16  xcoord, #kHPadding, xcoord
        RTS_IF NEG
        ldx     #AS_BYTE(-1)
      DO
        inx
        sub16  xcoord, #kTileWidth, xcoord
      WHILE POS
        RTS_IF X >= #kBoardWidth

        sub16   ycoord, #kVPadding, ycoord
        RTS_IF NEG
        ldy     #AS_BYTE(-1)
      DO
        iny
        sub16   ycoord, #kTileHeight, ycoord
      WHILE POS
        RTS_IF Y >= #kBoardHeight

        PUSH_XY                 ; Save X,Y

        jsr     GetCell

        state := $08
        sta     state

        event_kind := *+1
        ldx     #SELF_MODIFIED_BYTE
    IF X = #MGTK::EventKind::apple_key
        ;; modified click

        lda     state
        and     #kCellRevealed
      IF ZERO
        ;;  not revealed
        lda     state
        and     #kCellFlagsMask

        ;; unknown -> flag
       IF A = #kCellUnknown
        lda     state
        and     #AS_BYTE(~kCellFlagsMask)
        ora     #kCellFlag
        jmp     store_and_redraw
       END_IF

        ;; flag -> question
       IF A = #kCellFlag
        lda     state
        and     #AS_BYTE(~kCellFlagsMask)
        ora     #kCellQuestion
        jmp     store_and_redraw
       END_IF

        ;; question -> unknown
       IF A = #kCellQuestion
        lda     state
        and     #AS_BYTE(~kCellFlagsMask)
        ora     #kCellUnknown
        jmp     store_and_redraw
       END_IF

        ;; Assert: Unreached
        brk

      END_IF

        ;; revealed

        lda     state
        and     #kCellNumMask

        ;; 0 -> no-op
      IF ZERO
        PULL_XY
        rts
      END_IF

        ;; number - reveal if equal to adjacent flag count
        PULL_XY
        PUSH_XY
        jsr     CountFlags
        eor     state
        and     #kCellNumMask
      IF ZERO
        PULL_XY
        jmp     DoChording
      END_IF
        ;; Otherwise beep
        PULL_XY
        JSR_TO_MAIN JUMP_TABLE_BELL
        rts

    ELSE
        ;; not modified click

        lda     state
      IF NS
        ;; mine - game over
        PULL_XY
        CALL    SetCell, A=#kCellBoom
        TAIL_CALL OnDefeat
      END_IF

        ;; 0/number -> no-op
        and     #kCellRevealed
      IF NOT ZERO
        PULL_XY
        rts
      END_IF

        ;; no mine - do a reveal
        PULL_XY
        jsr     RecursiveReveal
        TAIL_CALL CheckVictory

    END_IF

store_and_redraw:
        sta     state

        PULL_XY                 ; Restore X,Y
        CALL    SetCell, A=state

        TAIL_CALL DrawTileAtXY
.endproc ; DoClick

;;; ============================================================

.proc CheckVictory

        ;; ----------------------------------------
        ;; Count number of non-revealed cells

        copy8   #0, count
        INVOKE_WITH_LAMBDA IterateBoard
        pha
        and     #kCellRevealed
    IF ZERO
        inc     count
    END_IF
        pla
        rts
        END_OF_LAMBDA

        count := *+1
        lda     #SELF_MODIFIED_BYTE
        RTS_IF A <> #kNumMines

        ;; ----------------------------------------
        ;; Flag all the unrevealed squares

        INVOKE_WITH_LAMBDA IterateBoard
        tax
        and     #kCellRevealed
    IF ZERO
        ;; Unknown -> Flag
        ;; Question -> Flag
        lda     #kCellFlag
        rts
    END_IF
        txa
        rts
        END_OF_LAMBDA

        ;; ----------------------------------------
        ;; Draw all the unrevealed squares

        INVOKE_WITH_LAMBDA IterateBoard
        pha
        and     #kCellRevealed
    IF ZERO
        jsr     DrawTileAtXY
    END_IF
        pla
        rts
        END_OF_LAMBDA

        jsr     PlaySound
        SET_BIT7_FLAG game_over_flag
        rts

.endproc ; CheckVictory

;;; ============================================================

.proc OnDefeat
        INVOKE_WITH_LAMBDA IterateBoard
        state := $08
        sta     state

        RTS_IF A = #kCellBoom

        and     #kCellRevealed  ; revealed?
    IF NOT ZERO
        RETURN A=state
    END_IF

        lda     state           ; C=x MFABNNNN
        asl                     ; C=M FABNNNN0
        php
        asl                     ; C=F ABNNNN00
        asl                     ; C=A BNNNN000
        rol                     ; C=B NNNN000A
        rol                     ; C=N NNN000AB
        and     #%00000011      ; C=N 000000AB
        plp
        rol                     ; C=x 00000ABM

        tax                     ; as an index
        lda     new_state_table,x
        rts
        END_OF_LAMBDA

        SET_BIT7_FLAG game_over_flag
        TAIL_CALL DrawWindow

new_state_table:
        .assert (kCellUnknown  >> 3) = 0, error, "bad index"
        .byte   kCellUnknown

        .assert ((kCellUnknown >> 3) | (kCellMine >> 7))  = 1, error, "bad index"
        .byte   kCellMine

        .assert (kCellFlag     >> 3) = 2, error, "bad index"
        .byte   kCellX

        .assert ((kCellFlag    >> 3) | (kCellMine >> 7))  = 3, error, "bad index"
        .byte   kCellFlag

        .assert (kCellQuestion >> 3) = 4, error, "bad index"
        .byte   kCellQuestion

        .assert ((kCellQuestion >> 3) | (kCellMine >> 7)) = 5, error, "bad index"
        .byte   kCellMine

.endproc ; OnDefeat

;;; ============================================================

;;; Input: X,Y = coords to start at
;;; Assert: not a mine
.proc RecursiveReveal
        PUSH_XY
        MGTK_CALL MGTK::CheckEvents
        PULL_XY

        ;; Reveal passed cell
        PUSH_XY
        jsr     GetCell
        pha
        and     #kCellRevealed
    IF NOT ZERO
        ;; already revealed
        pla
        PULL_XY
        rts
    END_IF
        pla
        and     #kCellNumMask
        sta     count
        ora     #kCellRevealed
        jsr     SetCell
        PULL_XY
        PUSH_XY
        jsr     DrawTileAtXY
        PULL_XY

        ;; Was it empty?
        count := *+1
        lda     #SELF_MODIFIED_BYTE
        RTS_IF NOT ZERO

        ;; Recursively reveal all neighbors

        ;; Y-1
        dey
    IF POS
        ;; X-1, Y-1
        dex
      IF POS
        jsr     RecursiveReveal
      END_IF
        inx

        ;; X, Y-1
        jsr     RecursiveReveal

        ;; X+1, Y-1
        inx
      IF X < #kBoardWidth
        jsr     RecursiveReveal
      END_IF
        dex
    END_IF
        iny

        ;; X-1, Y
        dex
    IF POS
        jsr     RecursiveReveal
    END_IF
        inx

        ;; X+1, Y
        inx
    IF X < #kBoardWidth
        jsr     RecursiveReveal
    END_IF
        dex

        ;; Y+1
        iny
    IF Y < #kBoardHeight
        ;; X-1, Y+1
        dex
      IF POS
        jsr     RecursiveReveal
      END_IF
        inx

        ;; X, Y+1
        jsr     RecursiveReveal

        ;; X+1, Y+1
        inx
      IF X < #kBoardWidth
        jsr     RecursiveReveal
      END_IF
        dex
    END_IF
        dey

        rts
.endproc ; RecursiveReveal


;;; ============================================================

;;; "Chording" is what the Minesweeper community calls checking
;;; adjacent cells when acting on a revealed cell when the adjacent
;;; flag count matches the adjacent mine count. This terminology
;;; presumably derives from action of two-button clicking.

;;; Input: X,Y = coords to start at
;;; Assert: not a mine
.proc DoChording
        ;; Reveal all non-flagged neighbors, potentially fatal

        ;; Y-1
        dey
    IF POS
        ;; X-1, Y-1
        dex
      IF POS
        jsr     _Check
      END_IF
        inx

        ;; X, Y-1
        jsr     _Check

        ;; X+1, Y-1
        inx
      IF X < #kBoardWidth
        jsr     _Check
      END_IF
        dex
    END_IF
        iny

        ;; X-1, Y
        dex
    IF POS
        jsr     _Check
    END_IF
        inx

        ;; X+1, Y
        inx
    IF X < #kBoardWidth
        jsr     _Check
    END_IF
        dex

        ;; Y+1
        iny
    IF Y < #kBoardHeight
        ;; X-1, Y+1
        dex
      IF POS
        jsr     _Check
      END_IF
        inx

        ;; X, Y+1
        jsr     _Check

        ;; X+1, Y+1
        inx
      IF X < #kBoardWidth
        jsr     _Check
      END_IF
        dex
    END_IF
        dey

        TAIL_CALL CheckVictory

.proc _Check
        PUSH_XY

        jsr     GetCell
        tax
        and     #kCellRevealed
    IF ZERO
        ;; not already revealed

        ;; Note: question mark is treated as unflagged

        ;; mine and not flagged?
        txa
        and     #(kCellMine | kCellFlagsMask)
      IF A = #(kCellMine | kCellUnknown) OR A = #(kCellMine | kCellQuestion)
        ;; oops!
        PULL_XY
        pla                     ; Don't return to caller
        pla
        CALL    SetCell, A=#kCellBoom
        TAIL_CALL OnDefeat
      END_IF

        ;; not flagged
        txa
        and     #kCellFlagsMask
      IF A <> #kCellFlag
        ;; reveal it!
        PULL_XY
        PUSH_XY
        CALL    RecursiveReveal
      END_IF
    END_IF

        PULL_XY
        rts
.endproc ; _Check

.endproc ; DoChording

;;; ============================================================
;;; Draw the DA window

.proc DrawWindow
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF NOT_ZERO         ; obscured
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenMode, notpencopy

        ptr := $06
        copy16  #board_state, ptr

        ldy     #0
        copy16  #kVPadding, paintbits_params::viewloc::ycoord
    DO
        tya
        pha                     ; A = Y coord
        copy16  #kHPadding, paintbits_params::viewloc::xcoord
        ldx     #0
      DO
        txa
        pha                     ; A = X coord

        ldy     #0
        lda     (ptr),y
        jsr     DrawTile

        inc16   ptr
        add16_8 paintbits_params::viewloc::xcoord, #kTileWidth

        pla                     ; A = X coord
        tax
      WHILE inx : X < #kBoardWidth

        add16_8 paintbits_params::viewloc::ycoord, #kTileHeight

        pla                     ; A = Y coord
        tay
    WHILE iny : Y < #kBoardWidth


        MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; DrawWindow

;;; ============================================================

;;; Inputs: X,Y = coords
.proc DrawTileAtXY
        PUSH_XY

        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF NOT ZERO                 ; obscured
        pla
        pla
        rts
    END_IF
        MGTK_CALL MGTK::SetPort, grafport

        PULL_XY
        PUSH_XY

        ;; Compute screen position
        copy16  #kHPadding, paintbits_params::viewloc::xcoord
    IF X >= #1
      DO
        add16_8 paintbits_params::viewloc::xcoord, #kTileWidth
      WHILE dex : NOT ZERO
    END_IF

        copy16  #kVPadding, paintbits_params::viewloc::ycoord
    IF Y >= #1
      DO
        add16_8 paintbits_params::viewloc::ycoord, #kTileHeight
      WHILE dey : NOT ZERO
    END_IF

        ldax    paintbits_params::viewloc::xcoord
        stax    shield_rect::x1
        addax   #kTileWidth, shield_rect::x2
        ldax    paintbits_params::viewloc::ycoord
        stax    shield_rect::y1
        addax   #kTileWidth, shield_rect::y2

        MGTK_CALL MGTK::ShieldCursor, shield_rect

        PULL_XY

        ;; Get the state
        jsr     GetCell

        jsr     DrawTile

        MGTK_CALL MGTK::UnshieldCursor
        rts

.endproc ; DrawTileAtXY

;;; ============================================================

;;; Input: A=state, `paintbits_params::viewloc` updated
.proc DrawTile

        ;; Special case
    IF A = #kCellBoom
        copy16  #bits_mine, paintbits_params::mapbits
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintBits, paintbits_params
        rts
    END_IF

        pha                     ; A = state

        ;; Revealed?
        and     #kCellRevealed
    IF NOT ZERO
        pla                     ; A = state
        and     #kCellNumMask
        asl
        tay
        lda     num_table,y
        ldx     num_table+1,y
        TAIL_CALL _Draw
    END_IF

        pla                     ; A = state
        and     #kCellMine | kCellFlagsMask

        bit     game_over_flag
      IF NS
       IF A = #kCellMine
        TAIL_CALL _Draw, AX=#bits_mine_precomposed
       END_IF
      END_IF

        and     #kCellFlagsMask

      IF A = #kCellUnknown
        TAIL_CALL _Draw, AX=#bits_hidden
      END_IF

      IF A = #kCellFlag
        TAIL_CALL _Draw, AX=#bits_flag_precomposed
      END_IF

      IF A = #kCellQuestion
        TAIL_CALL _Draw, AX=#bits_question_precomposed
      END_IF

      IF A = #kCellX
        TAIL_CALL _Draw, AX=#bits_x
      END_IF

        ;; Assert: Unreached
        brk

.proc _Draw
        stax    paintbits_params::mapbits
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintBits, paintbits_params
        rts
.endproc ; _Draw

.endproc ; DrawTile

;;; ============================================================

.proc InitBoard

        ;; ----------------------------------------
        ;; Init board to empty

        INVOKE_WITH_LAMBDA IterateBoard
        RETURN A=#kCellUnknown
        END_OF_LAMBDA

        ;; ----------------------------------------
        ;; Place mines

.scope
        ldx     #kNumMines
    DO
        txa
        pha                     ; A = index

re_roll:
        ;; Select X
      DO
        jsr     Random
      WHILE A >= #kBoardWidth
        pha                     ; A = X

        ;; Select Y
      DO
        jsr     Random
      WHILE A >= #kBoardHeight
        tay
        pla                     ; A = X
        tax

        jsr     GetCell
        cmp     #kCellMine | kCellUnknown
        beq     re_roll
        lda     #kCellMine | kCellUnknown
        jsr     SetCell

        pla                     ; A = count
        tax
    WHILE dex : NOT ZERO
.endscope

        ;; ----------------------------------------
        ;; Count neighbor mines

        INVOKE_WITH_LAMBDA IterateBoard
        tmp := $06
        sta     tmp
        jsr     CountMines
        ora     tmp
        rts
        END_OF_LAMBDA

        rts

.endproc ; InitBoard

;;; ============================================================

;;; Input: X,Y = coords
;;; Output: A,X = ptr
.proc XYToBoardPtr
        jsr     PushPointers

        tmp := $06
        copy16  #board_state, tmp

    IF Y <> #0
      DO
        add16_8 tmp, #kBoardWidth
      WHILE dey : NOT ZERO
    END_IF

        txa
        clc
        adc     tmp
        pha                     ; A = lo
        lda     #0
        adc     tmp+1
        tax
        pla                     ; A = lo

        jsr     PopPointers
        rts
.endproc ; XYToBoardPtr

;;; ============================================================

;;; Input: X,Y = coords
;;; Output: A = count of adjacent mines; X,Y unchanged
.proc CountMines
        jsr     PushPointers
        count := $08
        copy8   #0, count

        ;; Y-1
        dey
    IF POS
        ;; X-1, Y-1
        dex
      IF POS
        jsr     _Check
      END_IF
        inx

        ;; X, Y-1
        jsr     _Check

        ;; X+1, Y-1
        inx
      IF X < #kBoardWidth
        jsr     _Check
      END_IF
        dex
    END_IF
        iny

        ;; X-1, Y
        dex
    IF POS
        jsr     _Check
    END_IF
        inx

        ;; X+1, Y
        inx
    IF X < #kBoardWidth
        jsr     _Check
    END_IF
        dex

        ;; Y+1
        iny
    IF Y < #kBoardHeight
        ;; X-1, Y+1
        dex
      IF POS
        jsr     _Check
      END_IF
        inx

        ;; X, Y+1
        jsr     _Check

        ;; X+1, Y+1
        inx
      IF X < #kBoardWidth
        jsr     _Check
      END_IF
        dex
    END_IF
        dey

        lda     count
        jsr     PopPointers
        rts

.proc _Check
        jsr     GetCell
        and     #kCellMine
    IF NOT ZERO
        inc     count
    END_IF
        rts
.endproc ;  _Check

.endproc ; CountMines

;;; ============================================================

;;; Inputs: A,X = callback procedure
;;; The callback procedure is invoked with: X,Y = coords, A = cell state
;;; The return value in A is re-applied to the cell.
.proc IterateBoard
        stax    proc

        jsr     PushPointers

        ptr := $06

        copy16  #board_state, ptr

        ldy     #0
    DO
        ldx     #0
      DO
        PUSH_XY
        ldy     #0
        lda     (ptr),y
        sta     tmp
        PULL_XY
        PUSH_XY
        jsr     PushPointers

        tmp := *+1
        lda     #SELF_MODIFIED_BYTE
        proc := *+1
        jsr     SELF_MODIFIED

        jsr     PopPointers

        ldy     #0
        sta     (ptr),y

        inc16   ptr
        PULL_XY
      WHILE inx : X < #kBoardWidth
    WHILE iny : Y < #kBoardHeight

        jsr     PopPointers
        rts
.endproc ; IterateBoard

;;; ============================================================

;;; Input: X,Y = coords
;;; Output: A = count of adjacent flags; X,Y unchanged
.proc CountFlags
        jsr     PushPointers
        count := $08
        copy8   #0, count

        ;; Y-1
        dey
    IF POS
        ;; X-1, Y-1
        dex
      IF POS
        jsr     _Check
      END_IF
        inx

        ;; X, Y-1
        jsr     _Check

        ;; X+1, Y-1
        inx
      IF X < #kBoardWidth
        jsr     _Check
      END_IF
        dex
    END_IF
        iny

        ;; X-1, Y
        dex
    IF POS
        jsr     _Check
    END_IF
        inx

        ;; X+1, Y
        inx
    IF X < #kBoardWidth
        jsr     _Check
    END_IF
        dex

        ;; Y+1
        iny
    IF Y < #kBoardHeight
        ;; X-1, Y+1
        dex
      IF POS
        jsr     _Check
      END_IF
        inx

        ;; X, Y+1
        jsr     _Check

        ;; X+1, Y+1
        inx
      IF X < #kBoardWidth
        jsr     _Check
      END_IF
        dex
    END_IF
        dey

        lda     count
        jsr     PopPointers
        rts

.proc _Check
        jsr     GetCell
        and     #kCellFlagsMask
    IF A = #kCellFlag
        inc     count
    END_IF
        rts
.endproc ;  _Check

.endproc ; CountFlags

;;; ============================================================

;;; Input: X,Y = coords
;;; Output: A=cell value; X,Y unchanged
.proc GetCell
        jsr     PushPointers
        PUSH_XY

        ptr := $06
        tmp := $08

        jsr     XYToBoardPtr
        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     tmp

        PULL_XY
        lda     tmp
        jsr     PopPointers
        rts
.endproc ; GetCell

;;; ============================================================

;;; Input: X,Y = coords, A = new value
;;; Output: X,Y unchanged
.proc SetCell
        jsr     PushPointers

        ptr := $06
        tmp := $08

        sta     tmp
        PUSH_XY

        jsr     XYToBoardPtr
        stax    ptr
        ldy     #0
        lda     tmp
        sta     (ptr),y

        PULL_XY
        jsr     PopPointers
        rts
.endproc ; IsMine

;;; ============================================================
;;; Pushes two words from $6/$8 to stack; preserves A,X,Y

.proc PushPointers
        ;; Stash A,X
        sta     a_save
        stx     x_save

        ;; Stash return address
        pla
        sta     lo
        pla
        sta     hi

        ;; Copy 4 bytes from $8 to stack
        ldx     #AS_BYTE(-4)
    DO
        lda     $06 + 4,x
        pha
    WHILE inx : NOT_ZERO

        ;; Restore return address
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        ;; Restore A,X
        x_save := *+1
        ldx     #SELF_MODIFIED_BYTE
        a_save := *+1
        lda     #SELF_MODIFIED_BYTE

        rts
.endproc ; PushPointers

;;; ============================================================
;;; Pops two words from stack to $6/$8; preserves A,X,Y

.proc PopPointers
        ;; Stash A,X
        sta     a_save
        stx     x_save

        ;; Stash return address
        pla
        sta     lo
        pla
        sta     hi

        ;; Copy 4 bytes from stack to $6
        ldx     #3
    DO
        pla
        sta     $06,x
    WHILE dex : POS

        ;; Restore return address to stack
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        ;; Restore A,X
        x_save := *+1
        ldx     #SELF_MODIFIED_BYTE
        a_save := *+1
        lda     #SELF_MODIFIED_BYTE

        rts
.endproc ; PopPointers

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

        .include "../lib/prng.s"
        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX aux::CreateWindow
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
