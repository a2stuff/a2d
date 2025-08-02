;;; ============================================================
;;; BOUNCE - Desk Accessory
;;;
;;; Bouncing apples, vaguely inspired by Andy Hertzfeld's 1982
;;; "MacIntosh DeskTop Demo".
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "bounce.res"

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

kDAWindowId     = $80
kDAWidth        = kScreenWidth / 2
kDAHeight       = kScreenHeight / 2
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

str_title:
        PASCAL_STRING res_string_window_title

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::go_away_box
title:          .addr   str_title
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   32
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kScreenWidth / 5
mincontheight:  .word   kScreenHeight / 5
maxcontwidth:   .word   kScreenWidth
maxcontheight:  .word   kScreenHeight
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

;;; ============================================================

        .include "../lib/event_params.s"

.params trackgoaway_params
clicked:        .byte   0
.endparams

;;; ============================================================

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort

pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy
penXOR:         .byte   MGTK::penXOR

;;; ============================================================

kGrowBoxWidth = 17
kGrowBoxHeight = 7

.params grow_box_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   grow_box_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 2, 2, 19, 9
        REF_MAPINFO_MEMBERS
.endparams

grow_box_bitmap:
        PIXELS  "#####################"
        PIXELS  "#...................#"
        PIXELS  "#..##########.......#"
        PIXELS  "#..##......#######..#"
        PIXELS  "#..##......##...##..#"
        PIXELS  "#..##......##...##..#"
        PIXELS  "#..##########...##..#"
        PIXELS  "#....##.........##..#"
        PIXELS  "#....#############..#"
        PIXELS  "#...................#"
        PIXELS  "#####################"

;;; ============================================================
;;; Draw resize box
;;; Assert: An appropriate GrafPort is selected.

.proc DrawGrowBox
        MGTK_CALL MGTK::SetPenMode, notpencopy
        sub16_8 winfo::maprect::x2, #kGrowBoxWidth, grow_box_params::viewloc::xcoord
        sub16_8 winfo::maprect::y2, #kGrowBoxHeight, grow_box_params::viewloc::ycoord
        MGTK_CALL MGTK::PaintBitsHC, grow_box_params
        rts
.endproc ; DrawGrowBox

;;; ============================================================
;;; Animation Resources

kObjectWidth = 21
kObjectHeight = 11

.params object_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   object_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kObjectWidth-1, kObjectHeight-1
        REF_MAPINFO_MEMBERS
.endparams

object_bitmap:
        PIXELS  "........#...####...."
        PIXELS  ".........#.##......."
        PIXELS  "...####...#...####.."
        PIXELS  ".###################"
        PIXELS  "##################.."
        PIXELS  "################...."
        PIXELS  "################...."
        PIXELS  ".#################.."
        PIXELS  "..#################."
        PIXELS  "...###############.."
        PIXELS  "....#####...#####..."

kNumObjects = 5

object_positions:
        .repeat kNumObjects, i
        DEFINE_POINT .ident(.sprintf("pos%d", i)), (kDAWidth - kObjectWidth)/2, (kDAHeight - kObjectHeight)/2
        .endrepeat
        ASSERT_RECORD_TABLE_SIZE object_positions, kNumObjects, .sizeof(MGTK::Point)

object_deltas:
        .repeat kNumObjects
        .tag MGTK::Point
        .endrepeat
        ASSERT_RECORD_TABLE_SIZE object_deltas, kNumObjects, .sizeof(MGTK::Point)

;;; ============================================================

.proc Init
        ;; Generate random delta x/y in -16...15
        tmp := $06
        jsr     InitRand
        copy8   #0, tmp+1       ; hi
        ldx     #kNumObjects*2*2-2
:       jsr     Random
        and     #31
        sta     tmp             ; lo
        sub16   tmp, #16, object_deltas,x
        dex
        dex
        bpl     :-

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey
        cmp     #MGTK::EventKind::no_event
        bne     InputLoop
        jmp     HandleNoEvent
.endproc ; InputLoop

;;; ============================================================

.proc HandleKey
        lda     event_params::key

        ldx     event_params::modifiers
    IF_NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        beq     Exit
        bne     InputLoop       ; always
    END_IF

        cmp     #CHAR_ESCAPE
        bne     InputLoop
        FALL_THROUGH_TO Exit
.endproc ; HandleKey

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Exit

;;; ============================================================

.proc HandleDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        bne     InputLoop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        beq     HandleDrag
        cmp     #MGTK::Area::content
        beq     HandleGrow
        bne     InputLoop       ; always
.endproc ; HandleDown

;;; ============================================================

.proc HandleClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        bne     Exit
        beq     InputLoop       ; always
.endproc ; HandleClose

;;; ============================================================

.proc HandleDrag
        copy8   #kDAWindowId, dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
common: lda     dragwindow_params::moved
        bpl     finish

        ;; Draw DeskTop's windows and icons
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow

finish: jmp     InputLoop
.endproc ; HandleDrag

;;; ============================================================

.proc HandleGrow
        tmpw := $06

        ;; Is the hit within the grow box area?
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        sub16   winfo::maprect::x2, screentowindow_params::windowx, tmpw
        cmp16   #kGrowBoxWidth, tmpw
        bcc     HandleDrag::finish
        sub16   winfo::maprect::y2, screentowindow_params::windowy, tmpw
        cmp16   #kGrowBoxHeight, tmpw
        bcc     HandleDrag::finish

        ;; Initiate the grow... re-using the drag logic
        copy8   #kDAWindowId, dragwindow_params::window_id
        MGTK_CALL MGTK::GrowWindow, dragwindow_params
        jmp     HandleDrag::common
.endproc ; HandleGrow

;;; ============================================================

.proc HandleNoEvent
        copy8   winfo::window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        param_call PrepShieldCursor, screentowindow_params::window

        jsr     AnimateObjects

        jmp     InputLoop
.endproc ; HandleNoEvent

;;; ============================================================

.proc DrawWindow
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF_NOT_ZERO         ; obscured
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::HideCursor
        jsr     DrawGrowBox
        jsr     XDrawObjects
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; DrawWindow

;;; ============================================================

;;; Caller is responsible for hiding the cursor.
.proc XDrawObjects
        MGTK_CALL MGTK::SetPenMode, penXOR

        pos_ptr := $06
        copy16  #object_positions, pos_ptr
        ldx     #kNumObjects-1
loop:   txa
        pha

        ldy     #.sizeof(MGTK::Point)-1
:       lda     (pos_ptr),y
        sta     object_params::viewloc,y
        dey
        bpl     :-
        MGTK_CALL MGTK::PaintBits, object_params

        add16_8 pos_ptr, #.sizeof(MGTK::Point)

        pla
        tax
        dex
        bpl     loop

        rts
.endproc ; XDrawObjects

;;; ============================================================

.proc AnimateObjects
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF_NOT_ZERO         ; obscured
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, penXOR

        pos_ptr   := $06
        delta_ptr := $08
        tmpw      := $0A
        dim       := $0C

        copy16  #object_positions, pos_ptr
        copy16  #object_deltas, delta_ptr
        ldx     #kNumObjects-1
loop:   txa
        pha

        ;; --------------------------------------------------
        ;; Stash old coords

        ldy     #0
:       lda     (pos_ptr),y
        pha
        iny
        cpy     #4
        bne     :-

        ;; --------------------------------------------------
        ;; Update X coordinate and maybe delta

        ldy     #MGTK::Point::xcoord
        add16in (pos_ptr),y, (delta_ptr),y, tmpw

        scmp16  tmpw, #0
    IF_NEG
        copy16  #0, tmpw

        ldy     #MGTK::Point::xcoord
        sub16in #0, (delta_ptr),y, (delta_ptr),y
    END_IF

        sub16   winfo::maprect+MGTK::Rect::x2, #kObjectWidth-1, dim

        scmp16  dim, tmpw
    IF_NEG
        copy16  dim, tmpw

        ldy     #MGTK::Point::xcoord
        sub16in #0, (delta_ptr),y, (delta_ptr),y
    END_IF

        ldy     #MGTK::Point::xcoord
        copy16in tmpw, (pos_ptr),y

        ;; --------------------------------------------------
        ;; Update Y coordinate and maybe delta

        ldy     #MGTK::Point::ycoord
        add16in (pos_ptr),y, (delta_ptr),y, tmpw

        scmp16  tmpw, #0
    IF_NEG
        copy16  #0, tmpw

        ldy     #MGTK::Point::ycoord
        sub16in #0, (delta_ptr),y, (delta_ptr),y
    END_IF

        sub16   winfo::maprect+MGTK::Rect::y2, #kObjectHeight-1, dim
        scmp16  dim, tmpw
    IF_NEG
        copy16  dim, tmpw

        ldy     #MGTK::Point::ycoord
        sub16in #0, (delta_ptr),y, (delta_ptr),y
    END_IF

        ldy     #MGTK::Point::ycoord
        copy16in tmpw, (pos_ptr),y

        ;; --------------------------------------------------
        ;; Draw

        ;; New coords
        ldy     #.sizeof(MGTK::Point)-1
:       lda     (pos_ptr),y
        sta     object_params::viewloc,y
        dey
        bpl     :-
        param_call ShieldCursor, object_params
        MGTK_CALL MGTK::PaintBits, object_params
        jsr     UnShieldCursor

        ;; Old coords
        ldy     #.sizeof(MGTK::Point)-1
:       pla
        sta     object_params::viewloc,y
        dey
        bpl     :-
        param_call ShieldCursor, object_params
        MGTK_CALL MGTK::PaintBits, object_params
        jsr     UnShieldCursor

        ;; --------------------------------------------------
        ;; Next

        add16_8 pos_ptr, #.sizeof(MGTK::Point)
        add16_8 delta_ptr, #.sizeof(MGTK::Point)

        pla
        tax
        dex
        jpl     loop

        rts
.endproc ; AnimateObjects

;;; ============================================================
;;; Pseudorandom Number Generation

;;; From https://www.apple2.org.za/gswv/a2zine/GS.WorldView/v1999/Nov/Articles.and.Reviews/Apple2RandomNumberGenerator.htm
;;; By David Empson

;;; NOTE: low bit of N and high bit of N+2 are coupled

R1:     .byte  0
R2:     .byte  0
R3:     .byte  0
R4:     .byte  0

.proc Random
        ror R4                  ; Bit 25 to carry
        lda R3                  ; Shift left 8 bits
        sta R4
        lda R2
        sta R3
        lda R1
        sta R2
        lda R4                  ; Get original bits 17-24
        ror                     ; Now bits 18-25 in ACC
        rol R1                  ; R1 holds bits 1-7
        eor R1                  ; Seven bits at once
        ror R4                  ; Shift right by one bit
        ror R3
        ror R2
        ror
        sta R1
        rts
.endproc ; Random

.proc InitRand
        ;; Use current 24-bit tick count as seed
        JSR_TO_MAIN JUMP_TABLE_GET_TICKS
        sta R1
        sta R2
        stx R3
        sty R4
        ldx #$20                ; Generate a few random numbers
InitLoop:
        jsr Random              ; to kick things off
        dex
        bne InitLoop
        rts
.endproc ; InitRand

;;; ============================================================

        .include "../lib/shieldcursor.s"
        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX aux::Init
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
