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
.scope aux

;;; ============================================================

        MGTKEntry := MGTKAuxEntry

kDAWindowId    = 60
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
textback:       .byte   $7F
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
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1001111),PX(%1111110),PX(%0000001)
        .byte   PX(%1001100),PX(%0000111),PX(%1111001)
        .byte   PX(%1001100),PX(%0000110),PX(%0011001)
        .byte   PX(%1001100),PX(%0000110),PX(%0011001)
        .byte   PX(%1001111),PX(%1111110),PX(%0011001)
        .byte   PX(%1000011),PX(%0000000),PX(%0011001)
        .byte   PX(%1000011),PX(%1111111),PX(%1111001)
        .byte   PX(%1000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)

;;; ============================================================
;;; Draw resize box
;;; Assert: An appropriate GrafPort is selected.

.proc DrawGrowBox
        MGTK_CALL MGTK::SetPenMode, notpencopy
        sub16_8 winfo::maprect::x2, #kGrowBoxWidth, grow_box_params::viewloc::xcoord
        sub16_8 winfo::maprect::y2, #kGrowBoxHeight, grow_box_params::viewloc::ycoord
        MGTK_CALL MGTK::PaintBitsHC, grow_box_params
        rts
.endproc

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

;;; The compressed frames are used as a (poor) source of pseudo-random bytes.
noise:

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
        copy    frame_addr_table_lo,x, LZSA_SRC_LO
        copy    frame_addr_table_hi,x, LZSA_SRC_LO+1
        copy16  #FRAMEBUFFER, LZSA_DST_LO
        jsr     decompress_lzsa2_fast
        jsr     FrameDouble
        MGTK_CALL MGTK::PaintBitsHC, frame_params

        ;; Stash rect of this frame so we can optionally erase it next time
        COPY_STRUCT MGTK::Point, frame_params::viewloc, erase_rect::topleft
        add16_8 frame_params::viewloc::xcoord, #kNekoWidth-1, erase_rect::x2
        add16_8 frame_params::viewloc::ycoord, #kNekoHeight-1, erase_rect::y2

        rts

frame:  .byte   0
.endproc

.proc EraseFrame
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, erase_rect
        rts
.endproc

;;; ============================================================


.proc FrameDouble
        src := $06
        dst := $08
        tmp := $0A
        count := $0C

        kFrameSizeUndoubled = 160
        copy    #kFrameSizeUndoubled, count
        copy16  #FRAMEBUFFER+kFrameSizeUndoubled, src
        copy16  #FRAMEBUFFER+kFrameSizeUndoubled*2, dst
        ldy     #0

byte_loop:
        dec16   src
        lda     (src),y

        ldx     #8
bit_loop:
        ror
        php
        ror     tmp+1
        ror     tmp
        plp
        ror     tmp+1
        ror     tmp
        dex
        bne     bit_loop

        rol     tmp
        rol     tmp+1
        ror     tmp

        dec16   dst
        lda     tmp+1
        sta     (dst),y
        dec16   dst
        lda     tmp
        sta     (dst),y

        dec     count
        bne     byte_loop
        rts
.endproc

;;; ============================================================

        .include "../lib/lzsa.s"

;;; ============================================================

.endscope ; aux
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
        clc                     ; aux>main
        jmp     AUXMOVE
.endproc

.proc CopyEventDataToAux
        copy16  #event_params, STARTLO
        copy16  #event_params+ep_size-1, ENDLO
        copy16  #aux::event_params, DESTINATIONLO
        sec                     ; main>aux
        jmp     AUXMOVE
.endproc

;;; ============================================================

        DEFINE_RECT win_rect, 0,0,0,0

.proc GetWindowRect
        copy16  #aux::winfo::maprect, STARTLO
        copy16  #aux::winfo::maprect+.sizeof(MGTK::Rect)-1, ENDLO
        copy16  #win_rect, DESTINATIONLO
        clc                     ; aux>main
        jmp     AUXMOVE
.endproc

;;; ============================================================

.proc Init
        JUMP_TABLE_MGTK_CALL MGTK::OpenWindow, aux::winfo
        jsr     DrawWindow
        JUMP_TABLE_MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc

.proc InputLoop
        jsr JUMP_TABLE_YIELD_LOOP
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
.endproc

;;; ============================================================

.proc HandleKey
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        bne     InputLoop
        FALL_THROUGH_TO Exit
.endproc

.proc Exit
        JUMP_TABLE_MGTK_CALL MGTK::CloseWindow, aux::winfo
        jmp JUMP_TABLE_CLEAR_UPDATES
.endproc

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
.endproc

;;; ============================================================

.proc HandleClose
        JUMP_TABLE_MGTK_CALL MGTK::TrackGoAway, aux::trackgoaway_params
        jsr     CopyEventDataToMain
        lda     trackgoaway_params::clicked
        bne     Exit
        beq     InputLoop       ; always
.endproc

;;; ============================================================

.proc HandleDrag
        copy    #aux::kDAWindowId, dragwindow_params::window_id
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
.endproc

;;; ============================================================

;;; TODO: Clamp Neko's position?

.proc HandleGrow
        tmpw := $06

        ;; Is the hit within the grow box area?
        copy    #aux::kDAWindowId, screentowindow_params::window_id
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
        copy    #aux::kDAWindowId, dragwindow_params::window_id
        jsr     CopyEventDataToAux
        JUMP_TABLE_MGTK_CALL MGTK::GrowWindow, aux::dragwindow_params
        jmp     HandleDrag::common
.endproc

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
        beq     :+
        dec16   skip
        jmp     InputLoop
:       copy16  #175, skip

        ;; --------------------------------------------------
        ;; Tick once per frame; used to alternate frames
        ;; and select "random" numbers

        inc     tick

        ;; --------------------------------------------------
        ;; First, figure out vector from Neko to the cursor.

        x_delta := $06
        y_delta := $08
        x_neg   := $0A          ; high-bit set if negative
        y_neg   := $0B          ; high-bit set if negative
        tmp16   := $0C
        dir     := $0E

        copy    #aux::kDAWindowId, screentowindow_params::window_id
        jsr     CopyEventDataToAux
        JUMP_TABLE_MGTK_CALL MGTK::ScreenToWindow, aux::screentowindow_params
        jsr     CopyEventDataToMain
        jsr     CopyPosToMain
        x_pos := pos+MGTK::Point::xcoord
        y_pos := pos+MGTK::Point::ycoord

        sub16   screentowindow_params::windowx, x_pos, x_delta
        sub16   x_delta, #kNekoWidth / 2, x_delta
        lda     x_delta+1
        sta     x_neg
    IF_NEG
        sub16   #0, x_delta, x_delta
    END_IF
        lsr16   x_delta          ; force down to 8 bits
        lsr16   x_delta          ; and scale to match Y

        sub16   screentowindow_params::windowy, y_pos, y_delta
        sub16   y_delta, #kNekoHeight / 2, y_delta
        lda     y_delta+1
        sta     y_neg
    IF_NEG
        sub16   #0, y_delta, y_delta
    END_IF
        lsr16   y_delta          ; force down to 8 bits

        ;; Beyond threshold?
        lda     x_delta
        cmp     #kThreshold
        bcs     :+
        lda     y_delta
        cmp     #kThreshold
        bcs     :+

        ldx     #0              ; no; null out the deltas
        beq     skip_encode     ; always
:
        ;; Yes - do math to scale the deltas
        lda     x_delta
        cmp     y_delta
    IF_CS
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
        copy    #kMove, x_delta
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
        copy    #kMove, y_delta
    END_IF

        ;; --------------------------------------------------
        ;; Encode direction into 4 bits %0000xxyy
        ;;  00 = no, 01 = +ve, 10 = -ve, 11 = (not used)
        ldx     #0
        lda     x_delta
        cmp     #kMove/2
        bcc     @done_x
        bit     x_neg
        bpl     :+
        inx
:       inx
@done_x:
        txa
        asl
        asl
        tax

        lda     y_delta
        cmp     #kMove/2
        bcc     @done_y
        bit     y_neg
        bpl     :+
        inx
:       inx
@done_y:
skip_encode:
        stx     dir

        ;; --------------------------------------------------
        ;; Now we have dir/deltas/signs figured out. Decide
        ;; on the behavior.

        clc                     ; clear `moved_flag`
        ror     moved_flag

        lda     state
new_state:
        sta     state           ; for states that swap

        pha
        lda     tick
        jsr     GetRandom
        tay
        pla

        ;; ------------------------------
        cmp     #NekoState::rest
        ;; ------------------------------
    IF_EQ
        lda     dir
      IF_NOT_ZERO
        ldx     #NekoState::chase
        lda     #NekoFrame::surprise
        jmp     set_state_and_frame
      END_IF

        cpy     #$10            ; Y = random
      IF_CC
        ldx     #NekoState::itch
        lda     #NekoFrame::itch1
        jmp     set_state_and_frame
      END_IF

        cpy     #$20            ; Y = random
      IF_CC
        ldx     #NekoState::yawn
        lda     #NekoFrame::yawning
        jmp     set_state_and_frame
      END_IF

        cpy     #$30            ; Y = random
      IF_CC
        lda     #NekoFrame::lick
        jmp     set_frame
      END_IF

        lda     #NekoFrame::sitting
        jmp     set_frame
    END_IF

        ;; ------------------------------
        cmp     #NekoState::chase
        ;; ------------------------------
    IF_EQ
        lda     dir
      IF_ZERO
        ldx     #NekoState::rest
        lda     #NekoFrame::sitting
        jmp     set_state_and_frame
      END_IF

        sec                     ; set `moved_flag`
        ror     moved_flag

        jsr     MoveAndClamp
        cpy     #0              ; Y = clamped
      IF_NE
        copy    dir, scratch_dir
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
    IF_EQ
        lda     dir
        cmp     scratch_dir
      IF_NE
        ldx     #NekoState::chase
        lda     #NekoFrame::surprise
        jmp     set_state_and_frame
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
    IF_EQ
        cpy     #$20            ; Y = random
      IF_CC
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
    IF_EQ
        cpy     #$20            ; Y = random
      IF_CC
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
        ;; IF_EQ
        lda     dir
      IF_NOT_ZERO
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
    IF_POS
        add16_8 x_pos, x_delta
    ELSE
        sub16_8 x_pos, x_delta
    END_IF
        lsr     x_delta

        bit     y_neg
    IF_POS
        add16_8 y_pos, y_delta
    ELSE
        sub16_8 y_pos, y_delta
    END_IF

        ;; Clamp
        ldy     #0

        lda     x_pos+1
    IF_NEG
        copy16  #0, x_pos
        iny
    END_IF

        lda     y_pos+1
    IF_NEG
        copy16  #0, y_pos
        iny
    END_IF

        jsr     GetWindowRect

        sub16   win_rect::x2, win_rect::x1, tmp16
        sub16_8 tmp16, #kNekoWidth-1, tmp16
        cmp16   x_pos, tmp16
    IF_CS
        copy16  tmp16, x_pos
        iny
    END_IF

        sub16   win_rect::y2, win_rect::y1, tmp16
        sub16_8 tmp16, #kNekoHeight + aux::kGrowBoxHeight, tmp16
        cmp16   y_pos, tmp16
    IF_CS
        copy16  tmp16, y_pos
        iny
    END_IF

        tya
        pha
        jsr     CopyPosToAux
        pla
        tay

        rts
.endproc

.endproc

;;; ============================================================

        DEFINE_POINT pos, 0,0

.proc CopyPosToMain
        copy16  #aux::frame_params::viewloc, STARTLO
        copy16  #aux::frame_params::viewloc+.sizeof(MGTK::Point)-1, ENDLO
        copy16  #pos, DESTINATIONLO
        clc                     ; aux>main
        jmp     AUXMOVE
.endproc

.proc CopyPosToAux
        copy16  #pos, STARTLO
        copy16  #pos+.sizeof(MGTK::Point)-1, ENDLO
        copy16  #aux::frame_params::viewloc, DESTINATIONLO
        sec                     ; main>aux
        jmp     AUXMOVE
.endproc

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
        bne     ret             ; obscured
        JSR_TO_AUX aux::DrawGrowBox
ret:    rts
.endproc

;;; ============================================================

;;; Output: Z=0 on success, Z=1 on failure (e.g. obscured)
.proc GetSetPort
        ;; Defer if content area is not visible
        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, aux::getwinport_params
        bne     ret
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, aux::grafport
ret:    rts
.endproc

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
        bne     ret

        ;; Erase if needed
        bit     moved_flag
    IF_NS
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

ret:    rts
.endproc

;;; ============================================================

;;; A really bad random number generator; this uses the
;;; compressed data over in Aux as the entropy.

;;; Input: A = seed
;;; Output: A = "random" value
.proc GetRandom
        clc
        adc     #<aux::noise
        sta     STARTLO
        sta     ENDLO
        lda     #>aux::noise
        adc     #0
        sta     STARTHI
        sta     ENDHI
        copy16  #result, DESTINATIONLO
        clc                     ; aux>main
        jsr     AUXMOVE

        lda     result
        rts

result: .byte   1
.endproc

;;; ============================================================

        .include "../lib/muldiv.s"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
