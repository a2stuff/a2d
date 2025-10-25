;;; ============================================================
;;; NEKO - Desk Accessory
;;;
;;; Playful cat screen saver
;;; Originally by Naoshi Watanabe, Kenji Gotoh, & others
;;;
;;; Icons exported via 'DeRez neko' on macOS 12.6.1 "Monterey"
;;; by Frank Milliron 12/12/22
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "neko.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================
;;; Memory map
;;;
;;;               Main            Aux
;;;          :             : :             :
;;;          |             | |             |
;;;          | DHR         | | DHR         |
;;;  $2000   +-------------+ +-------------+
;;;          |             | |             |
;;;          | IO Buffer   | | scratch     |
;;;  $1C00   +-------------+ +-------------+
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          | stub        | | DA          |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;

kNekoHeight     = 32      ; full height is 32
kNekoWidth      = 64      ; full width is 32, but aspect ratio needs to be doubled
kNumFrames      = 32

.enum NekoFrame
        runUp1          = 0
        runUp2          = 1
        runUpRight1     = 2
        runUpRight2     = 3
        runRight1       = 4
        runRight2       = 5
        runDownRight1   = 6
        runDownRight2   = 7
        runDown1        = 8
        runDown2        = 9
        runDownLeft1    = 10
        runDownLeft2    = 11
        runLeft1        = 12
        runLeft2        = 13
        runUpLeft1      = 14
        runUpLeft2      = 15

        scratchUp1      = 16
        scratchUp2      = 17
        scratchRight1   = 18
        scratchRight2   = 19
        scratchDown1    = 20
        scratchDown2    = 21
        scratchLeft1    = 22
        scratchLeft2    = 23

        sitting         = 24
        yawning         = 25
        itch1           = 26
        itch2           = 27
        sleep1          = 28
        sleep2          = 29
        lick            = 30
        surprise        = 31
.endenum

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

ep_start:
        .include "../lib/event_params.s"

.params trackgoaway_params
clicked:        .byte   0
.endparams

ep_size := * - ep_start

;;; ============================================================

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

.struct scratch
        .org    $1C00
        framebuffer     .res    10*32; kNekoHeight * kNekoStride
        grafport        .tag    MGTK::GrafPort
.endstruct
FRAMEBUFFER := scratch::framebuffer
grafport := scratch::grafport

pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy

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

.ifdef CURSORS
        kCursorHeight = 16
        kCursorWidth  = 16

        kNekoCount    = 32
        kNekoCursor   = 3
.endif

frame_addr_table_lo:
.repeat ::kNumFrames,i
        .byte <.ident(.sprintf("neko_frame_%02d", i+1))
.endrepeat
frame_addr_table_hi:
.repeat ::kNumFrames,i
        .byte >.ident(.sprintf("neko_frame_%02d", i+1))
.endrepeat

.repeat ::kNumFrames, i
        .ident(.sprintf("neko_frame_%02d", i+1)) := *
        .incbin .sprintf("neko_frames/neko_frame_%02d.bin.lzsa", i+1)
.endrepeat


.ifdef CURSORS
        .addr   neko_bird_cursor   ; CURS -16000, "bardCurs" (bird?)
        .addr   neko_bird_mask     ; CURS -16000, "bardCurs" (bird?)

        .addr   neko_fish_cursor   ; CURS -15998, "fishCurs"
        .addr   neko_fish_mask     ; CURS -15998, "fishCurs"

        .addr   neko_mouse_cursor  ; CURS -15999, "mouseCurs"
        .addr   neko_mouse_mask    ; CURS -15999, "mouseCurs"
.endif


;;; ============================================================

kNekoStride = 10                ; in bytes; width / 7 rounded up

.params frame_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   FRAMEBUFFER
mapwidth:       .byte   kNekoStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kNekoWidth-1, kNekoHeight-1
        REF_MAPINFO_MEMBERS
.endparams

        DEFINE_RECT erase_rect, 0, 0, 0, 0

;;; ============================================================

;;; Inputs: Y = frame

.proc DrawFrame
        sty     frame
        MGTK_CALL MGTK::SetPenMode, notpencopy
        ldx     frame
        copy8   frame_addr_table_lo,x, LZSA_SRC_LO
        copy8   frame_addr_table_hi,x, LZSA_SRC_LO+1
        copy16  #FRAMEBUFFER, LZSA_DST_LO
        jsr     decompress_lzsa2_fast
        jsr     FrameDouble
        MGTK_CALL MGTK::PaintBitsHC, frame_params

        ;; Stash rect of this frame so we can optionally erase it next time
        COPY_STRUCT frame_params::viewloc, erase_rect::topleft
        add16_8 frame_params::viewloc::xcoord, #kNekoWidth-1, erase_rect::x2
        add16_8 frame_params::viewloc::ycoord, #kNekoHeight-1, erase_rect::y2

        rts

frame:  .byte   0
.endproc ; DrawFrame

.proc EraseFrame
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, erase_rect
        rts
.endproc ; EraseFrame

;;; ============================================================


.proc FrameDouble
        src := $06
        dst := $08
        tmp := $0A
        count := $0C

        kFrameSizeUndoubled = 160
        copy8   #kFrameSizeUndoubled, count
        copy16  #FRAMEBUFFER+kFrameSizeUndoubled, src
        copy16  #FRAMEBUFFER+kFrameSizeUndoubled*2, dst
        ldy     #0

    DO
        dec16   src
        lda     (src),y

        ldx     #8
      DO
        ror
        php
        ror     tmp+1
        ror     tmp
        plp
        ror     tmp+1
        ror     tmp
        dex
      WHILE NOT_ZERO

        rol     tmp
        rol     tmp+1
        ror     tmp

        dec16   dst
        copy8   tmp+1, (dst),y
        dec16   dst
        copy8   tmp, (dst),y

        dec     count
    WHILE NOT_ZERO
        rts
.endproc ; FrameDouble

;;; ============================================================

        .include "../lib/lzsa.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

;;; ============================================================

        jmp     Init

;;; ============================================================


ep_start:
        .include "../lib/event_params.s"

.params trackgoaway_params
clicked:        .byte   0
.endparams

ep_size := * - ep_start
        .assert ep_size = aux::ep_size, error, "param mismatch aux vs. main"

.proc CopyEventDataToMain
        copy16  #aux::event_params, STARTLO
        copy16  #aux::event_params+ep_size-1, ENDLO
        copy16  #event_params, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=0  ; aux>main
.endproc ; CopyEventDataToMain

.proc CopyEventDataToAux
        copy16  #event_params, STARTLO
        copy16  #event_params+ep_size-1, ENDLO
        copy16  #aux::event_params, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=1  ; main>aux
.endproc ; CopyEventDataToAux

;;; ============================================================

        DEFINE_RECT win_rect, 0,0,0,0

.proc GetWindowRect
        copy16  #aux::winfo::maprect, STARTLO
        copy16  #aux::winfo::maprect+.sizeof(MGTK::Rect)-1, ENDLO
        copy16  #win_rect, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=0  ; aux>main
.endproc ; GetWindowRect

;;; ============================================================

.proc Init
        jsr     InitRand

        JUMP_TABLE_MGTK_CALL MGTK::OpenWindow, aux::winfo
        jsr     DrawWindow
        JUMP_TABLE_MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        jsr JUMP_TABLE_SYSTEM_TASK
        JUMP_TABLE_MGTK_CALL MGTK::GetEvent, aux::event_params
        jsr     CopyEventDataToMain
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
    IF NOT_ZERO
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
        JUMP_TABLE_MGTK_CALL MGTK::CloseWindow, aux::winfo
        jmp JUMP_TABLE_CLEAR_UPDATES
.endproc ; Exit

;;; ============================================================

.proc HandleDown
        JUMP_TABLE_MGTK_CALL MGTK::FindWindow, aux::findwindow_params
        jsr     CopyEventDataToMain
        lda     findwindow_params::window_id
        cmp     #aux::kDAWindowId
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
        JUMP_TABLE_MGTK_CALL MGTK::TrackGoAway, aux::trackgoaway_params
        jsr     CopyEventDataToMain
        lda     trackgoaway_params::clicked
        bne     Exit
        beq     InputLoop       ; always
.endproc ; HandleClose

;;; ============================================================

.proc HandleDrag
        copy8   #aux::kDAWindowId, dragwindow_params::window_id
        jsr     CopyEventDataToAux
        JUMP_TABLE_MGTK_CALL MGTK::DragWindow, aux::dragwindow_params
common: jsr     CopyEventDataToMain
        lda     dragwindow_params::moved
        bpl     finish

        ;; Draw DeskTop's windows and icons
        jsr     JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow

finish: jmp     InputLoop
.endproc ; HandleDrag

;;; ============================================================

;;; TODO: Clamp Neko's position?

.proc HandleGrow
        tmpw := $06

        ;; Is the hit within the grow box area?
        copy8   #aux::kDAWindowId, screentowindow_params::window_id
        jsr     CopyEventDataToAux
        JUMP_TABLE_MGTK_CALL MGTK::ScreenToWindow, aux::screentowindow_params
        jsr     CopyEventDataToMain
        jsr     GetWindowRect
        sub16   win_rect::x2, screentowindow_params::windowx, tmpw
        cmp16   #aux::kGrowBoxWidth, tmpw
        bcc     HandleDrag::finish
        sub16   win_rect::y2, screentowindow_params::windowy, tmpw
        cmp16   #aux::kGrowBoxHeight, tmpw
        bcc     HandleDrag::finish

        ;; Initiate the grow... re-using the drag logic
        copy8   #aux::kDAWindowId, dragwindow_params::window_id
        jsr     CopyEventDataToAux
        JUMP_TABLE_MGTK_CALL MGTK::GrowWindow, aux::dragwindow_params
        jmp     HandleDrag::common
.endproc ; HandleGrow

;;; ============================================================
;;; Behavior State Machine
;;; ============================================================

.enum NekoState
        rest    = 0
        chase   = 1
        scratch = 2
        itch    = 3
        lick    = 4
        yawn    = 5
        sleep   = 6
.endenum

kThreshold = 8
kMove      = 8                   ; scaled 2x in x dimension

skip:   .word   0

.proc HandleNoEvent
        ;; Throttle animation
        lda     skip
        ora     skip+1
    IF NOT_ZERO
        dec16   skip
        jmp     InputLoop
    END_IF

        copy16  #175, skip

        ;; --------------------------------------------------
        ;; Tick once per frame; used to alternate frames

        inc     tick

        ;; --------------------------------------------------
        ;; First, figure out vector from Neko to the cursor.

        x_delta := $06
        y_delta := $08
        x_neg   := $0A          ; high-bit set if negative
        y_neg   := $0B          ; high-bit set if negative
        tmp16   := $0C
        dir     := $0E

        copy8   #aux::kDAWindowId, screentowindow_params::window_id
        jsr     CopyEventDataToAux
        JUMP_TABLE_MGTK_CALL MGTK::ScreenToWindow, aux::screentowindow_params
        jsr     CopyEventDataToMain
        jsr     CopyPosToMain
        x_pos := pos+MGTK::Point::xcoord
        y_pos := pos+MGTK::Point::ycoord

        sub16   screentowindow_params::windowx, x_pos, x_delta
        sub16   x_delta, #kNekoWidth / 2, x_delta
        copy8   x_delta+1, x_neg
    IF NEG
        sub16   #0, x_delta, x_delta
    END_IF
        lsr16   x_delta          ; force down to 8 bits
        lsr16   x_delta          ; and scale to match Y

        sub16   screentowindow_params::windowy, y_pos, y_delta
        sub16   y_delta, #kNekoHeight / 2, y_delta
        copy8   y_delta+1, y_neg
    IF NEG
        sub16   #0, y_delta, y_delta
    END_IF
        lsr16   y_delta          ; force down to 8 bits

        ;; Beyond threshold?
        lda     x_delta
    IF A < #kThreshold
        lda     y_delta
      IF A < #kThreshold
        ldx     #0              ; no; null out the deltas
        beq     skip_encode     ; always
      END_IF
    END_IF

        ;; Yes - do math to scale the deltas
        lda     x_delta
    IF A >= y_delta
        ;; x dominant:
        ;; * y_delta = kMove * y_delta / x_delta
        ;; * x_delta = kMove

        lda     y_delta
        ldx     #0              ; A,X = y_delta
        ldy     #kMove
        jsr     Multiply_16_8_16 ; A,X = kMove * y_delta
        ldy     x_delta
        jsr     Divide_16_8_16  ; A,X = kMove * y_delta / x_delta
        sta     y_delta
        copy8   #kMove, x_delta
    ELSE
        ;; y dominant
        ;; * x_delta = kMove * x_delta / y_delta
        ;; * y_delta = kMove

        lda     x_delta
        ldx     #0              ; A,X = x_delta
        ldy     #kMove
        jsr     Multiply_16_8_16 ; A,X = kMove * x_delta
        ldy     y_delta
        jsr     Divide_16_8_16  ; A,X = kMove * x_delta / y_delta
        sta     x_delta
        copy8   #kMove, y_delta
    END_IF

        ;; --------------------------------------------------
        ;; Encode direction into 4 bits %0000xxyy
        ;;  00 = no, 01 = +ve, 10 = -ve, 11 = (not used)
        ldx     #0
        lda     x_delta
    IF A >= #kMove/2
        bit     x_neg
      IF NEG
        inx
      END_IF
        inx
    END_IF
        txa
        asl
        asl
        tax

        lda     y_delta
    IF A >= #kMove/2
        bit     y_neg
      IF NEG
        inx
      END_IF
        inx
    END_IF


skip_encode:
        stx     dir

        ;; --------------------------------------------------
        ;; Now we have dir/deltas/signs figured out. Decide
        ;; on the behavior.

        CLEAR_BIT7_FLAG moved_flag

        lda     state
new_state:
        sta     state           ; for states that swap

        pha
        jsr     Random
        tay
        pla

        ;; ------------------------------
        cmp     #NekoState::rest
        ;; ------------------------------
    IF EQ
        lda     dir
      IF NOT_ZERO
        TAIL_CALL set_state_and_frame, X=#NekoState::chase, A=#NekoFrame::surprise
      END_IF

      IF Y < #$10               ; Y = random
        TAIL_CALL set_state_and_frame, X=#NekoState::itch, A=#NekoFrame::itch1
      END_IF

      IF Y < #$20               ; Y = random
        TAIL_CALL set_state_and_frame, X=#NekoState::yawn, A=#NekoFrame::yawning
      END_IF

      IF Y < #$30               ; Y = random
        TAIL_CALL set_frame, A=#NekoFrame::lick
      END_IF

        TAIL_CALL set_frame, A=#NekoFrame::sitting
    END_IF

        ;; ------------------------------
        cmp     #NekoState::chase
        ;; ------------------------------
    IF EQ
        lda     dir
      IF ZERO
        TAIL_CALL set_state_and_frame, X=#NekoState::rest, A=#NekoFrame::sitting
      END_IF

        SET_BIT7_FLAG moved_flag

        jsr     MoveAndClamp
      IF Y <> #0                ; Y = clamped
        copy8   dir, scratch_dir
        lda     #NekoState::scratch
        bne     new_state       ; always
      END_IF

        lda     tick
        and     #1
        ldx     dir
        ora     dir_frame_table-1,x ; -1 to save a byte
        jmp     set_frame
    END_IF

        ;; ------------------------------
        cmp     #NekoState::scratch
        ;; ------------------------------
    IF EQ
        lda     dir
      IF A <> scratch_dir
        TAIL_CALL set_state_and_frame, X=#NekoState::chase, A=#NekoFrame::surprise
      END_IF

        tax                     ; X = dir
        lda     tick
        and     #1
        ora     scratch_frame_table-1,x ; -1 to save a byte
        bne     set_frame       ; always
    END_IF

        ;; ------------------------------
        cmp     #NekoState::itch
        ;; ------------------------------
    IF EQ
      IF Y < #$20               ; Y = random
        ldx     #NekoState::rest
        lda     #NekoFrame::sitting
        bne     set_state_and_frame ; always
      END_IF

        lda     cur_frame
        eor     #1
        bne     set_frame       ; always
    END_IF

        ;; ------------------------------
        cmp     #NekoState::yawn
        ;; ------------------------------
    IF EQ
      IF Y < #$20               ; Y = random
        ldx     #NekoState::sleep
        lda     #NekoFrame::sleep1
        bne     set_state_and_frame ; always
      END_IF
        ldx     #NekoState::rest
        lda     #NekoFrame::sitting
        bne     set_state_and_frame ; always
    END_IF

        ;; ------------------------------
        ;; cmp     #NekoState::sleep
        ;; ------------------------------
        ;; IF EQ
        lda     dir
      IF NOT_ZERO
        ldx     #NekoState::chase
        lda     #NekoFrame::surprise
        bne     set_state_and_frame ; always
      END_IF
        lda     cur_frame
        eor     #1
        bne     set_frame       ; always
        ;; END_IF


set_state_and_frame:
        stx     state
set_frame:
        sta     cur_frame
        jsr     DrawCurrentFrame

        jmp     InputLoop

;;; Apply the deltas and clamp
;;; Outputs: Y = number of clampings done (0, 1 or 2)
.proc MoveAndClamp
        ;; Move
        asl     x_delta
        bit     x_neg
    IF POS
        add16_8 x_pos, x_delta
    ELSE
        sub16_8 x_pos, x_delta
    END_IF
        lsr     x_delta

        bit     y_neg
    IF POS
        add16_8 y_pos, y_delta
    ELSE
        sub16_8 y_pos, y_delta
    END_IF

        ;; Clamp
        ldy     #0

        lda     x_pos+1
    IF NEG
        copy16  #0, x_pos
        iny
    END_IF

        lda     y_pos+1
    IF NEG
        copy16  #0, y_pos
        iny
    END_IF

        jsr     GetWindowRect

        sub16   win_rect::x2, win_rect::x1, tmp16
        sub16_8 tmp16, #kNekoWidth-1, tmp16
        cmp16   x_pos, tmp16
    IF GE
        copy16  tmp16, x_pos
        iny
    END_IF

        sub16   win_rect::y2, win_rect::y1, tmp16
        sub16_8 tmp16, #kNekoHeight + aux::kGrowBoxHeight, tmp16
        cmp16   y_pos, tmp16
    IF GE
        copy16  tmp16, y_pos
        iny
    END_IF

        tya
        pha
        jsr     CopyPosToAux
        pla
        tay

        rts
.endproc ; MoveAndClamp

.endproc ; HandleNoEvent

;;; ============================================================

        DEFINE_POINT pos, 0,0

.proc CopyPosToMain
        copy16  #aux::frame_params::viewloc, STARTLO
        copy16  #aux::frame_params::viewloc+.sizeof(MGTK::Point)-1, ENDLO
        copy16  #pos, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=0  ; aux>main
.endproc ; CopyPosToMain

.proc CopyPosToAux
        copy16  #pos, STARTLO
        copy16  #pos+.sizeof(MGTK::Point)-1, ENDLO
        copy16  #aux::frame_params::viewloc, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=1  ; main>aux
.endproc ; CopyPosToAux

;;; ============================================================

        ;; Frame tables, index is direction encoded as:
        ;; 0000 = no move       (not in table, to save a byte)
        ;; 0001 = down
        ;; 0010 = up
        ;; 0011 = (unused)
        ;; 0100 = right
        ;; 0101 = down right
        ;; 0110 = up right
        ;; 0111 = (unused)
        ;; 1000 = left
        ;; 1001 = down left
        ;; 1010 = up left

dir_frame_table:
        .byte   NekoFrame::runDown1
        .byte   NekoFrame::runUp1
        .byte   0
        .byte   NekoFrame::runRight1
        .byte   NekoFrame::runDownRight1
        .byte   NekoFrame::runUpRight1
        .byte   0
        .byte   NekoFrame::runLeft1
        .byte   NekoFrame::runDownLeft1
        .byte   NekoFrame::runUpLeft1

scratch_frame_table:
        .byte   NekoFrame::scratchDown1
        .byte   NekoFrame::scratchUp1
        .byte   0
        .byte   NekoFrame::scratchRight1
        .byte   NekoFrame::scratchRight1
        .byte   NekoFrame::scratchRight1
        .byte   0
        .byte   NekoFrame::scratchLeft1
        .byte   NekoFrame::scratchLeft1
        .byte   NekoFrame::scratchLeft1

;;; ============================================================

.proc DrawWindow
        jsr     GetSetPort
    IF ZERO                     ; not obscured
        JSR_TO_AUX aux::DrawGrowBox
    END_IF
        rts
.endproc ; DrawWindow

;;; ============================================================

;;; Output: Z=0 on success, Z=1 on failure (e.g. obscured)
.proc GetSetPort
        ;; Defer if content area is not visible
        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, aux::getwinport_params
    IF ZERO
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, aux::grafport
    END_IF
        rts
.endproc ; GetSetPort

;;; ============================================================

tick:   .byte   0               ; incremented every event
state:  .byte   NekoState::rest ; NekoState::XXX
scratch_dir:
        .byte   0               ; last scratch direction
moved_flag:
        .byte   0               ; high bit set if moved

cur_frame:                      ; NekoFrame::XXX
        .byte   NekoFrame::sitting

.proc DrawCurrentFrame
        jsr     GetSetPort
    IF ZERO
        ;; Erase if needed
        bit     moved_flag
      IF NS
        JSR_TO_AUX aux::EraseFrame
      END_IF

        ;; Draw frame
        ldy     cur_frame       ; A,X are trashed by macro
        JSR_TO_AUX aux::DrawFrame

.ifdef SLOW_EMULATORS
        ;; Experimental - slows emulators like Virtual II
        sta     SPKR
        sta     SPKR
.endif
    END_IF
        rts
.endproc ; DrawCurrentFrame

;;; ============================================================

PARAM_BLOCK muldiv_params, $10
number          .word           ; (in)
numerator       .word           ; (in)
denominator     .word           ; (in)
result          .word           ; (out)
remainder       .word           ; (out)
END_PARAM_BLOCK

;;; A,X = A,X * Y
.proc Multiply_16_8_16
        stax    muldiv_params::number
        sty     muldiv_params::numerator
        copy8   #0, muldiv_params::numerator+1
        copy16  #1, muldiv_params::denominator
        JUMP_TABLE_MGTK_CALL MGTK::MulDiv, muldiv_params
        RETURN  AX=muldiv_params::result
.endproc ; Multiply_16_8_16

;;; ============================================================

;;; A,X = A,X / Y, Y = remainder
.proc Divide_16_8_16
        stax    muldiv_params::numerator
        sty     muldiv_params::denominator
        copy8   #0, muldiv_params::denominator+1
        copy16  #1, muldiv_params::number
        JUMP_TABLE_MGTK_CALL MGTK::MulDiv, muldiv_params
        RETURN  AX=muldiv_params::result, Y=muldiv_params::remainder
.endproc ; Divide_16_8_16

;;; ============================================================

        .include "../lib/prng.s"
        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
