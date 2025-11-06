;;; ============================================================
;;; CD.REMOTE - Desk Accessory
;;;
;;; Control an AppleCD SC via SCSI card
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "cd.remote.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"
        .include "../inc/smartport.inc"

.define FAKE_HARDWARE 0

;;; ============================================================
;;; Memory map
;;;
;;;               Main            Aux
;;;          :             : :             :
;;;          |             | |             |
;;;          | DHR         | | DHR         |
;;;  $2000   +-------------+ +-------------+
;;;          | IO Buffer/  | |             |
;;;          | SP Data Buf | |             |
;;;  $1C00   +-------------+ |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          | (unused)    | | (unused)    |
;;; ~$1800   +-------------+ +-------------+
;;;          |             | |             |
;;;          |             | |             |
;;;          | app logic   | |             |
;;;          | cd control  | | bitmaps     |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;
;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

kDAWindowId     = $80
kDAWidth        = 271
kDAHeight       = 57
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
textback:       .byte   MGTK::textbg_black
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

;;; ============================================================

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy

;;; ============================================================

;;; [track       min:sec]      (logo?)
;;; stop play pause eject
;;; |<<  >>|  <<    >>     loop shuffle

kCDButtonW = 40
kCDButtonH = 10
kColW = 60

kRow1 = 4
kRow2 = 27
kRow3 = 42

kCol1 = 10
kCol2 = kCol1 + kCDButtonW + 10
kCol3 = kCol2 + kCDButtonW + 10
kCol4 = kCol3 + kCDButtonW + 10
kCol5 = kCol4 + kCDButtonW + 10 + 10
kCol6 = kCol5 + kCDButtonW + 10

        DEFINE_RECT_SZ display_rect, kCol1, kRow1, 190, 17


.macro DEFINE_CD_BUTTON name, xpos, ypos
        DEFINE_RECT_SZ .ident(.sprintf("%s_button_rect", .string(name))), xpos, ypos, kCDButtonW, kCDButtonH
.params .ident(.sprintf("%s_bitmap_params", .string(name)))
        DEFINE_POINT viewloc, xpos + 12, ypos + 2
mapbits:        .addr   .ident(.sprintf("%s_bitmap", .string(name)))
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 17, 6
        REF_MAPINFO_MEMBERS
.endparams
.endmacro

        DEFINE_CD_BUTTON stop, kCol1, kRow2
        DEFINE_CD_BUTTON play, kCol2, kRow2
        DEFINE_CD_BUTTON pause, kCol3, kRow2
        DEFINE_CD_BUTTON eject, kCol4, kRow2

        DEFINE_CD_BUTTON prev, kCol1, kRow3
        DEFINE_CD_BUTTON next, kCol2, kRow3
        DEFINE_CD_BUTTON back, kCol3, kRow3
        DEFINE_CD_BUTTON fwd, kCol4, kRow3

        DEFINE_CD_BUTTON loop, kCol5, kRow2
        DEFINE_CD_BUTTON shuffle, kCol5, kRow3

;;; ============================================================

stop_bitmap:
        PIXELS  "..##############.."
        PIXELS  "..##############.."
        PIXELS  "..##############.."
        PIXELS  "..##############.."
        PIXELS  "..##############.."
        PIXELS  "..##############.."
        PIXELS  "..##############.."
pause_bitmap:
        PIXELS  "..#####....#####.."
        PIXELS  "..#####....#####.."
        PIXELS  "..#####....#####.."
        PIXELS  "..#####....#####.."
        PIXELS  "..#####....#####.."
        PIXELS  "..#####....#####.."
        PIXELS  "..#####....#####.."
play_bitmap:
        PIXELS  "....##............"
        PIXELS  "....#####........."
        PIXELS  "....########......"
        PIXELS  "....##########...."
        PIXELS  "....########......"
        PIXELS  "....#####........."
        PIXELS  "....##............"
fwd_bitmap:
        PIXELS  ".##......##......."
        PIXELS  ".####....####....."
        PIXELS  ".######..######..."
        PIXELS  ".################."
        PIXELS  ".######..######..."
        PIXELS  ".####....####....."
        PIXELS  ".##......##......."
next_bitmap:
        PIXELS  "##......##......##"
        PIXELS  "####....####....##"
        PIXELS  "######..######..##"
        PIXELS  "##################"
        PIXELS  "######..######..##"
        PIXELS  "####....####....##"
        PIXELS  "##......##......##"
back_bitmap:
        PIXELS  ".......##......##."
        PIXELS  ".....####....####."
        PIXELS  "...######..######."
        PIXELS  ".################."
        PIXELS  "...######..######."
        PIXELS  ".....####....####."
        PIXELS  ".......##......##."
prev_bitmap:
        PIXELS  "##......##......##"
        PIXELS  "##....####....####"
        PIXELS  "##..######..######"
        PIXELS  "##################"
        PIXELS  "##..######..######"
        PIXELS  "##....####....####"
        PIXELS  "##......##......##"
eject_bitmap:
        PIXELS  "........##........"
        PIXELS  "......######......"
        PIXELS  "....##########...."
        PIXELS  "..##############.."
        PIXELS  ".................."
        PIXELS  "..##############.."
        PIXELS  "..##############.."
shuffle_bitmap:
        PIXELS  "..............##.."
        PIXELS  "#####......#######"
        PIXELS  ".....##..##...##.."
        PIXELS  ".......##........."
        PIXELS  ".....##..##...##.."
        PIXELS  "#####......#######"
        PIXELS  "..............##.."
loop_bitmap:
        PIXELS  "...........##....."
        PIXELS  ".##############..."
        PIXELS  "##.........##...##"
        PIXELS  "##..............##"
        PIXELS  "##...##.........##"
        PIXELS  "...##############."
        PIXELS  ".....##..........."


;;; ============================================================

logo_bitmap:
        PIXELS  ".......#####..###.####.##.##.###..#..###.###."
        PIXELS  ".......#...#..#...#..#.#.#.#.###.###.#....#.."
        PIXELS  ".......#...#..###.####.#...#.#...#.#.###..#.."
        PIXELS  ".......#...#................................."
        PIXELS  ".#######...#..#####...#########...##########."
        PIXELS  "#..........#..#...#..#........#..#..........#"
        PIXELS  "#...####...#..#...#..#........#..#...####...#"
        PIXELS  "#...#..#...#..#...#..#...#####...#...#...####"
        PIXELS  "#...#..#...#..#...#..#........#..#...#......."
        PIXELS  "#...#..#...#..#...#..#........#..#...#......."
        PIXELS  "#...#..#...#..#...#...#####...#..#...#...####"
        PIXELS  "#...####...#..#...#..#........#..#...####...#"
        PIXELS  "#..........#..#...#..#........#..#..........#"
        PIXELS  ".###########..#####..#########....##########."
        PIXELS  "............................................."
        PIXELS  "###..#.##...#.###..#..#.....#..#.#.###..#.###"
        PIXELS  "#..#.#.#..#.#..#..###.#....###.#.#.#..#.#.#.#"
        PIXELS  "###..#.####.#..#..#.#.###..#.#.###.###..#.###"

.params logo_bitmap_params
        DEFINE_POINT viewloc, kCol5-3, kRow1
mapbits:        .addr   logo_bitmap
mapwidth:       .byte   7
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 44, 17
        REF_MAPINFO_MEMBERS
.endparams

;;; ============================================================

        DEFINE_POINT pos_track, kCol1 + 20, kRow1 + 13

        DEFINE_POINT pos_time, kCol4-8, kRow1 + 13

;;; ============================================================

ep_start := *
        .include        "../lib/event_params.s"

.params trackgoaway_params
clicked:        .byte   0
.endparams

ep_size = * - ep_start

;;; ============================================================

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort

tmp_rect:       .tag    MGTK::Rect

;;; ============================================================

buf_string := *
.assert buf_string + 256 < $2000, error, "DA too large"

;;; ============================================================

        DA_END_AUX_SEGMENT
        DA_START_MAIN_SEGMENT

;;; ============================================================

;;; ============================================================

        jmp     ::cdremote::MAIN

;;; ============================================================

.proc Init
        JUMP_TABLE_MGTK_CALL MGTK::OpenWindow, aux::winfo
        jsr     DrawWindow
        JUMP_TABLE_MGTK_CALL MGTK::FlushEvents
        rts
.endproc ; Init

.proc Exit
        JUMP_TABLE_MGTK_CALL MGTK::CloseWindow, aux::winfo
        jmp     JUMP_TABLE_CLEAR_UPDATES
.endproc ; Exit

;;; ============================================================

ep_start := *
        .include        "../lib/event_params.s"

.params trackgoaway_params
clicked:        .byte   0
.endparams

ep_size = * - ep_start
.assert aux::ep_size = ep_size, error, "event params main/aux mismatch"

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
;;; Handle `EventKind::button_down`.
;;; Output: N=1 if event was not a button click
;;;         N=0 if event was a button click; in this case,
;;;         `event_params::key` and `event_params::modifier` will
;;;         be set to the keyboard equivalent.

.proc HandleDown
        JUMP_TABLE_MGTK_CALL MGTK::FindWindow, aux::findwindow_params
        jsr     CopyEventDataToMain

        lda     findwindow_params::window_id
    IF A = #aux::kDAWindowId
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        beq     HandleDrag
        cmp     #MGTK::Area::content
        beq     HandleClick
    END_IF
        lda     #$FF            ; not a button
        rts
.endproc ; HandleDown

;;; ============================================================

.proc HandleClose
        JUMP_TABLE_MGTK_CALL MGTK::TrackGoAway, aux::trackgoaway_params
        jsr     CopyEventDataToMain

        lda     trackgoaway_params::clicked
    IF NOT_ZERO
        pla                     ; not returning to the caller
        pla
        jmp     Exit
    END_IF

        lda     #$FF            ; not a button
        rts
.endproc ; HandleClose

;;; ============================================================

.proc HandleDrag
        copy8   #aux::kDAWindowId, dragwindow_params::window_id
        jsr     CopyEventDataToAux
        JUMP_TABLE_MGTK_CALL MGTK::DragWindow, aux::dragwindow_params
        jsr     CopyEventDataToMain
        bit     dragwindow_params::moved
        bpl     skip

        ;; Draw DeskTop's windows and icons.
        jsr     JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow

skip:   lda     #$FF            ; not a button
        rts
.endproc ; HandleDrag

;;; ============================================================

.proc HandleClick
        copy8   #aux::kDAWindowId, screentowindow_params::window_id
        jsr     CopyEventDataToAux
        JUMP_TABLE_MGTK_CALL MGTK::ScreenToWindow, aux::screentowindow_params
        JUMP_TABLE_MGTK_CALL MGTK::MoveTo, aux::screentowindow_params::window

        ;; ----------------------------------------

        copy8   #0, event_params::modifiers

        JUMP_TABLE_MGTK_CALL MGTK::InRect, aux::play_button_rect
    IF NOT_ZERO
        lda     #'P'
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, aux::stop_button_rect
    IF NOT_ZERO
        lda     #'S'
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, aux::pause_button_rect
    IF NOT_ZERO
        lda     #' '
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, aux::eject_button_rect
    IF NOT_ZERO
        lda     #'E'
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, aux::loop_button_rect
    IF NOT_ZERO
        lda     #'L'
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, aux::shuffle_button_rect
    IF NOT_ZERO
        lda     #'R'
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, aux::prev_button_rect
    IF NOT_ZERO
        lda     #CHAR_LEFT
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, aux::next_button_rect
    IF NOT_ZERO
        lda     #CHAR_RIGHT
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, aux::back_button_rect
    IF NOT_ZERO
        copy8   #1, event_params::modifiers
        lda     #CHAR_LEFT
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, aux::fwd_button_rect
    IF NOT_ZERO
        copy8   #1, event_params::modifiers
        lda     #CHAR_RIGHT
        bne     set_key         ; always
    END_IF

        lda     #$FF            ; not a button
        rts

set_key:
        sta     event_params::key
        rts
.endproc ; HandleClick


;;; ============================================================

.proc DrawWindow
        ;; Defer if content area is not visible
        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, aux::getwinport_params
        RTS_IF NOT_ZERO

        JUMP_TABLE_MGTK_CALL MGTK::SetPort, aux::grafport
        JUMP_TABLE_MGTK_CALL MGTK::HideCursor

        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, aux::notpencopy
        JUMP_TABLE_MGTK_CALL MGTK::PaintRect, aux::winfo::maprect

        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, aux::pencopy
        JUMP_TABLE_MGTK_CALL MGTK::FrameRect, aux::display_rect

        ;; --------------------------------------------------

        jsr     DrawTrack
        jsr     DrawTime

        ;; --------------------------------------------------

        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, aux::penXOR

.macro DRAW_CD_BUTTON name, flag
        JUMP_TABLE_MGTK_CALL MGTK::FrameRect, aux::.ident(.sprintf("%s_button_rect", .string(name)))
        JUMP_TABLE_MGTK_CALL MGTK::PaintBitsHC, aux::.ident(.sprintf("%s_bitmap_params", .string(name)))
  .if .paramcount > 1
        bit     ::cdremote::flag
    IF NS
        CALL    InvertButton, AX=#aux::.ident(.sprintf("%s_button_rect", .string(name)))
    END_IF
  .endif
.endmacro

        DRAW_CD_BUTTON stop, StopButtonState
        DRAW_CD_BUTTON play, PlayButtonState
        DRAW_CD_BUTTON pause, PauseButtonState
        DRAW_CD_BUTTON eject
        DRAW_CD_BUTTON prev
        DRAW_CD_BUTTON next
        DRAW_CD_BUTTON back
        DRAW_CD_BUTTON fwd
        DRAW_CD_BUTTON loop, LoopButtonState
        DRAW_CD_BUTTON shuffle, RandomButtonState

        ;; --------------------------------------------------

        JUMP_TABLE_MGTK_CALL MGTK::PaintBitsHC, aux::logo_bitmap_params

        ;; --------------------------------------------------

        JUMP_TABLE_MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; DrawWindow

;;; ============================================================

str_track:
        PASCAL_STRING res_string_label_track
str_track_num:
        PASCAL_STRING "##  "
str_time:
        PASCAL_STRING "##:##  "

;;; Caller is responsible for setting port.
.proc DrawTrack
        JUMP_TABLE_MGTK_CALL MGTK::MoveTo, aux::pos_track
        CALL    DrawStringFromMain, AX=#str_track
        TAIL_CALL DrawStringFromMain, AX=#str_track_num
.endproc ; DrawTrack

;;; Caller is responsible for setting port.
.proc DrawTime
        JUMP_TABLE_MGTK_CALL MGTK::MoveTo, aux::pos_time
        TAIL_CALL DrawStringFromMain, AX=#str_time
.endproc ; DrawTime

;;; ============================================================
;;; Copies string main>aux before drawing
;;; Input: A,X = address of length-prefixed string

.proc DrawStringFromMain
        params  := $06
        textptr := $06
        textlen := $08

        stax    textptr
        stax    STARTLO
        ldy     #0
        lda     (textptr),y
        beq     done
        sta     textlen
        copy16  #aux::buf_string+1, textptr

        copy16  #aux::buf_string, DESTINATIONLO
        add16_8 STARTLO, textlen, ENDLO
        CALL    AUXMOVE, C=1    ; main>aux

        JUMP_TABLE_MGTK_CALL MGTK::DrawText, params
done:   rts
.endproc ; DrawStringFromMain

;;; ============================================================
;;; Inputs: A,X = rect address
;;; Assert: Called from Main
;;; Trashes: $06/$07

.proc InvertButton
        ptr := $06
        stax    ptr

        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, aux::getwinport_params
    IF ZERO
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, aux::grafport

        ;; Copy rectangle
        copy16  ptr, STARTLO
        add16_8 STARTLO, #.sizeof(MGTK::Rect)-1, ENDLO
        copy16  #rect, DESTINATIONLO
        CALL    AUXMOVE, C=0    ; aux>main

        ;; Deflate
        inc16   rect+MGTK::Rect::x1
        inc16   rect+MGTK::Rect::y1
        dec16   rect+MGTK::Rect::x2
        dec16   rect+MGTK::Rect::y2

        ;; Copy rectangle back to aux
        copy16  #rect, STARTLO
        copy16  #rect+.sizeof(MGTK::Rect)-1, ENDLO
        copy16  #aux::tmp_rect, DESTINATIONLO
        CALL    AUXMOVE, C=1    ; main>aux

        ;; Invert it
        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, aux::penXOR
        JUMP_TABLE_MGTK_CALL MGTK::PaintRect, aux::tmp_rect
    END_IF
        rts

rect:   .tag    MGTK::Rect

.endproc ; InvertButton


;;; ============================================================

.scope cdremote


ZP1                 := $19      ; used when probing for hardware
PlayedListPtr       := $1F

MAIN:                           ; "Null" out T/M/S values
        lda     #$aa
        sta     BCDRelTrack
        sta     BCDRelMinutes
        sta     BCDRelSeconds

                                ; Locate an Apple SCSI card and CDSC/CDSC+ drive
        jsr     FindHardware
.if !FAKE_HARDWARE
    IF CS
        TAIL_CALL JUMP_TABLE_SHOW_ALERT, A=#ERR_DEVICE_NOT_CONNECTED
    END_IF
.else ; FAKE_HARDWARE
        ;;         lda     #$38            ; SEC
        lda     #$18            ; CLC
        sta     SPCallVector
        lda     #$60            ; RTS
        sta     SPCallVector+1
.endif ; FAKE_HARDWARE

        ;; Application setup
        jsr     ::Init          ; Open/draw DA window

        jsr     InitDriveAndDisc
        jsr     InitPlayedList

                                ; Do all the things!
        jsr     MainLoop

EXIT:
        jmp     ::Exit

;;; ============================================================

.proc InitDriveAndDisc
        ;; Is drive online?
        jsr     StatusDrive
        bcs     ExitInitDriveDisc

        ;; Read the TOC for Track numbers - TOC VALUES ARE BCD!!
        jsr     C27ReadTOC

        sed
        clc
        lda     BCDLastTrackTOC
        sbc     BCDFirstTrackTOC
        adc     #$01
        sta     BCDTrackCount0Base
        cld

        jsr     C24AudioStatus
        lda     SPBuffer
        ;; Audio Status = $00 (currently playing)
        beq     Playing
        sec
        sbc     #1
        ;; Audio status = $01 (currently paused)
        beq     Paused
        ;; Audio status = anything else - stop operation explicitly
        jsr     DoStopAction
        jmp     ExitInitDriveDisc

        ;; Set Pause button to active
Paused:
        dec     PauseButtonState
        jsr     ToggleUIPauseButton
        ;; Read the current disc position and update the Track and Time display
        jsr     C28ReadQSubcode
        jsr     DrawTrack
        jsr     DrawTime

        ;; Set Play button to active
Playing:
        dec     PlayButtonState
        ;; Set drive playing flag to true
        dec     DrivePlayingFlag
        jsr     ToggleUIPlayButton
        jmp     ExitInitDriveDisc
ExitInitDriveDisc:
        rts
.endproc ; InitDriveAndDisc

;;; ============================================================

        ;; This is the start of where all the real action takes place
.proc MainLoop
        lda     TOCInvalidFlag
        ;; Have we read in a valid, usable TOC from an audio CD?
    IF NOT_ZERO
        ;; We don't have a valid TOC - poll the drive to see if it's online so we can try to read a TOC
        jsr     StatusDrive
        ;; No - drive is offline, go check for user input instead
        bcs     CheckUserInput
        ;; Yes - make another attempt at reading a TOC
        jsr     ReReadTOC
    END_IF

        ;; ----------------------------------------

        ;; Re-check the status of the drive
        jsr     StatusDrive
        lda     DrivePlayingFlag
    IF NOT_ZERO
        ;; Drive is playing audio, watch for an AudioStatus return code of $03 = "Play operation complete"
        jsr     C24AudioStatus
        lda     SPBuffer
        cmp     #$03
        ;; Audio playback operation is not complete
      IF EQ
        ;; Deal with reaching the end of a playback operation.  It's complicated.  :)
        jsr     PlayBackComplete
      END_IF

        ;; Go read the QSubcode channel and update the Track & Time display
        jsr     C28ReadQSubcode
        bcs     CheckUserInput
        jsr     DrawTrack
        jsr     DrawTime
    END_IF

        ;; ----------------------------------------

        ;; Read and process any Keyboard inputs from the user
CheckUserInput:
        jsr     JUMP_TABLE_SYSTEM_TASK
        JUMP_TABLE_MGTK_CALL MGTK::GetEvent, aux::event_params
        jsr     CopyEventDataToMain

        lda     event_params::kind
    IF A = #MGTK::EventKind::button_down
        jsr     ::HandleDown
        bpl     HandleKey       ; was a button, mapped to key event
        jmp     MainLoop
    END_IF

        cmp     #MGTK::EventKind::key_down
        bne     MainLoop

        ;; ----------------------------------------

HandleKey:
        lda     event_params::key
        jsr     ToUpperCase

        ldx     event_params::modifiers
    IF NOT_ZERO
        cmp     #kShortcutCloseWindow
        jeq     DoQuitAction
    END_IF

        ;; $51 = Q (Quit)
        cmp     #'Q'
        jeq     DoQuitAction

        ;; $1B = ESC (Quit)
        cmp     #CHAR_ESCAPE
        jeq     DoQuitAction

        ;; $4C = L (Continuous Play)
    IF A = #'L'
        jsr     ToggleLoopMode
        jmp     MainLoop
    END_IF

        ;; $52 = R (Random Play)
    IF A = #'R'
        jsr     ToggleRandomMode
        jmp     MainLoop
    END_IF

        ;; All other key operations (Play/Stop/Pause/Next/Prev/Eject) require an online drive/disc, so check one more time
        jsr     StatusDrive
        jcs     MainLoop

        ;; Loop falls through to here only if the drive is online
        pha
        lda     TOCInvalidFlag
        ;; Valid TOC has been read, we can skip the re-read
    IF NOT_ZERO
        jsr     ReReadTOC
    END_IF
        pla

        ;; $50 = P (Play)
    IF A = #'P'
        jsr     DoPlayAction
        jmp     MainLoop
    END_IF

        ;; $53 = S (Stop)
    IF A = #'S'
        jsr     DoStopAction
        jmp     MainLoop
    END_IF

        ;; $20 = Space (Pause)
    IF A = #' '
        jsr     DoPauseAction
        jmp     MainLoop
    END_IF

        ;; $08 = ^H, LA (Previous Track, Scan Backward)
    IF A = #CHAR_LEFT
        lda     event_params::modifiers
      IF NOT_ZERO
        jsr     DoScanBackAction
        jmp     MainLoop
      END_IF

        jsr     DoPrevTrackAction
        jmp     MainLoop
    END_IF

        ;; $15 = ^U, RA (Next Track/Scan Forward)
    IF A = #CHAR_RIGHT
        lda     event_params::modifiers
      IF NOT_ZERO
        jsr     DoScanFwdAction
        jmp     MainLoop
      END_IF

        jsr     DoNextTrackAction
        jmp     MainLoop
    END_IF

        ;; $45 = E (Eject)
    IF A = #'E'
        jsr     C26Eject
    END_IF

        jmp     MainLoop
.endproc ; MainLoop

;;; ============================================================

.proc DoQuitAction
                    rts
.endproc ; DoQuitAction

;;; ============================================================

.proc PlayBackComplete
        lda     RandomButtonState
    IF NOT_ZERO

        ;; Random button is active - handle rollover to next random track
        lda     PlayButtonState
        ;; Play button is inactive - bail out, there's nothing to do
        beq     ExitHandler

        ;; Increment the count of how many tracks have been played
        inc     HexPlayedCount0Base
        lda     HexPlayedCount0Base
        cmp     HexTrackCount0Base
        ;; Haven't played all the tracks on the disc, so pick another one
        bne     PlayARandomTrack

        ;; All tracks have been played randomly - clear the Play button STATE to inactive (with no UI change) ...
        lda     #$00
        sta     PlayButtonState
        ;; re-randomize from scratch ...
        jsr     RandomModeInit
        ;; then reset the Play button STATE back to active (again with no UI change)
        lda     #$ff
        sta     PlayButtonState

        lda     LoopButtonState
        ;; Loop button is active, so play the whole disc over again - start by picking a new track
        bne     PlayARandomTrack

        ;; Loop button is inactive - reset the first/last/current values to the TOC values and stop
        lda     BCDFirstTrackTOC
        sta     BCDFirstTrackNow
        sta     BCDRelTrack
        lda     BCDLastTrackTOC
        sta     BCDLastTrackNow
        jsr     DoStopAction
        jmp     ExitHandler

        ;; --------------------------------------------------

PlayARandomTrack:
        jsr     PickARandomTrack
        lda     BCDRandomPickedTrk

        ;; We're in random mode, "playing" just one track now, so Current/First/Last are all the same
        sta     BCDRelTrack
        sta     BCDFirstTrackNow
        sta     BCDLastTrackNow
        ;; and we're "stopping" at the end of the current track
        jsr     SetStopToEoBCDLTN

        ;; Set flag to Track mode, because we're in random mode
        lda     #$ff
        sta     TrackOrMSFFlag

        ;; Call AudioPlay function and exit
        jsr     C21AudioPlay
    ELSE
        ;; Entire disc has been played to the end, do we need to loop?
        lda     LoopButtonState
      IF NOT_ZERO
        ;; Loop button is active - reset stop point to EoT LastTrack
        jsr     C23AudioStop
        lda     PlayButtonState
        ;; Play button is inactive - bail out, there's nothing to do
        beq     ExitHandler

        ;; Make sure we start fresh from the first track on the disc
        lda     BCDFirstTrackTOC
        sta     BCDFirstTrackNow
        ;; Set flag to MSF mode, because we're not in random mode
        dec     TrackOrMSFFlag
        ;; Call AudioPlay function and exit
        jsr     C21AudioPlay
      ELSE
        ;; Stop, because Loop is inactive
        lda     PlayButtonState
        ;; Play button is inactive (already) - bail out, there's nothing to do
        beq     ExitHandler

        ;; Use the existing StopAction to stop everything
        jsr     DoStopAction
      END_IF
    END_IF

ExitHandler:
        rts
.endproc ; PlayBackComplete

;;; ============================================================

.proc StatusDrive
        pha
        ;; Try three times for a good status return
        lda     #$03
        sta     RetryCount

RetryLoop:
        lda     #SPCall::Status
        sta     SPCommandType
        ;; $00 = Code
        lda     #$00
        sta     SPCode
        jsr     SPCallVector
        bcc     GotStatus
        dec     RetryCount
        bne     RetryLoop
        sec
        ;; Failed Status call three times - exit with carry set
        bcs     ExitStatusDrive ; always

        ;; First byte is general status byte
GotStatus:
        lda     SPBuffer
        ;; $B4 means Block Device, Read-Only, and Online (CD-ROM)
        cmp     #$b4
        beq     StatusDriveSuccess

        lda     TOCInvalidFlag
        ;; TOC is currently flagged invalid - that's expected, so just return the Status call failure
        bne     StatusDriveFail

        ;; EXCEPTION - Call a HardShutdown if we encounter a bad Status call with an existing valid TOC because something's gone very wrong
        jsr     HardShutdown
        ;; Hard-flag the TOC as now invalid
        lda     #$ff
        sta     TOCInvalidFlag

        ;; Exit with carry set
StatusDriveFail:
        sec
        bcs     ExitStatusDrive ; always

        ;; Exit with carry clear
StatusDriveSuccess:
        clc
ExitStatusDrive:
        pla
        rts
.endproc ; StatusDrive

;;; ============================================================

        ;; EXCEPTION - Explicitly stop the CD drive, forcibly clear the Play/Pause buttons, forcibly set the Stop button, and wipe the Track/Time display clean
.proc HardShutdown
        jsr     DoStopAction
        lda     PauseButtonState
    IF NOT_ZERO
        ;; Clear Pause button to inactive
        lda     #$00
        sta     PauseButtonState
        jsr     ToggleUIPauseButton
    END_IF

        lda     PlayButtonState
    IF NOT_ZERO
        ;; Clear Play button to inactive
        lda     #$00
        sta     PlayButtonState
        jsr     ToggleUIPlayButton
    END_IF

        lda     StopButtonState
    IF ZERO
        ;; Set Stop button to active
        lda     #$ff
        sta     StopButtonState
        jsr     ToggleUIStopButton
    END_IF

        ;; "Null" out T/M/S values and blank Track & Time display
        lda     #$aa
        sta     BCDRelTrack
        sta     BCDRelMinutes
        sta     BCDRelSeconds

        jsr     DrawTrack
        jsr     DrawTime

        rts
.endproc ; HardShutdown

;;; ============================================================

        ;; Called in the background if the drive reports a valid/online Status and we still have an invalid TOC.
.proc ReReadTOC
        lda     #$00
        sta     TOCInvalidFlag
        jsr     C27ReadTOC

        sed
        clc
        lda     BCDLastTrackTOC
        sbc     BCDFirstTrackTOC
        adc     #$01
        ;; Calculate the number of tracks on the disc, minus 1, and stash it
        sta     BCDTrackCount0Base
        cld

        ;; Explicitly stop playback and set stop point to EoT LastTrack
        jsr     C23AudioStop
        ;; Set flag to Track mode
        lda     #$ff
        sta     TrackOrMSFFlag

        ;; Update Track and Time display
        jsr     C28ReadQSubcode
        jsr     DrawTrack
        jsr     DrawTime

        lda     RandomButtonState
        ;; Random button is inactive, so nothing else to do
        beq     ExitReReadTOC

        ;; Random button is active, so set up random mode
        jsr     RandomModeInit
ExitReReadTOC:
        rts
.endproc ; ReReadTOC

;;; ============================================================

;;; Returns N=0 if the gesture has ended, N=1 otherwise
;;; * If the last event was `MGTK::EventKind::key_down`, assume it has ended
;;; * Otherwise, sample until `MGTK::EventKind::button_up`

.proc CheckGestureEnded
        lda     event_params::kind
        cmp     #MGTK::EventKind::key_down
        beq     ended

        JUMP_TABLE_MGTK_CALL MGTK::GetEvent, aux::event_params
        jsr     CopyEventDataToMain
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_up
        beq     ended

        lda     #$FF            ; N=1
        rts

ended:  lda     #$00            ; N=0
        rts
.endproc ; CheckGestureEnded

;;; ============================================================

.proc DoPlayAction
        lda     PauseButtonState
    IF NOT_ZERO
        ;; Pause button is active - forcibly clear it to inactive and then...
        lda     #$00
        sta     PauseButtonState
        jsr     ToggleUIPauseButton
        ;; call AudioPause to release Pause (resume playing) and exit
        jsr     C22AudioPause
    ELSE

        lda     PlayButtonState
      IF ZERO
        ;; Play button is inactive, we're starting from scratch - before activating, check the random mode
        lda     RandomButtonState
       IF NOT_ZERO
        ;; Random button is active - initialize random mode, pick a Track, and start it
        jsr     RandomModeInit
        jsr     PickARandomTrack
        lda     BCDRandomPickedTrk

        ;; In random mode, we're "playing" just one track, so Current/First/Last are all the same
        sta     BCDRelTrack
        sta     BCDFirstTrackNow
        sta     BCDLastTrackNow
        ;; and we "stop" playing at the end of that track
        jsr     SetStopToEoBCDLTN
        jsr     C20AudioSearch
       END_IF

        ;; Set Play button to active
        dec     PlayButtonState
        jsr     ToggleUIPlayButton

        lda     StopButtonState
       IF NOT_ZERO
        ;; Set Stop button to inactive, then start the playback and exit
        lda     #$00
        sta     StopButtonState
        jsr     ToggleUIStopButton
       END_IF

        jsr     C21AudioPlay
      END_IF
    END_IF
        rts
.endproc ; DoPlayAction

;;; ============================================================

.proc DoStopAction
        lda     StopButtonState
    IF ZERO
        ;; Reset First/Last to TOC values
        lda     BCDFirstTrackTOC
        sta     BCDFirstTrackNow
        lda     BCDLastTrackTOC
        sta     BCDLastTrackNow

        lda     PlayButtonState
      IF NOT_ZERO
        ;; Clear Play button to inactive
        lda     #$00
        sta     PlayButtonState
        jsr     ToggleUIPlayButton
      END_IF

        lda     PauseButtonState
      IF NOT_ZERO
        ;; Clear Pause button to inactive
        lda     #$00
        sta     PauseButtonState
        jsr     ToggleUIPauseButton
      END_IF

        ;; Set Stop button to active
        lda     #$ff
        sta     StopButtonState
        ;; Switch Stop Flag to EoTrack mode
        dec     TrackOrMSFFlag
        jsr     ToggleUIStopButton

        ;; Force drive to seek to first track
        lda     BCDFirstTrackNow
        sta     BCDRelTrack
        jsr     C20AudioSearch

        ;; Explicitly stop playback and set stop point to EoT last Track
        jsr     C23AudioStop

        ;; Update Track and Time display
        jsr     C28ReadQSubcode
        jsr     DrawTrack
        jsr     DrawTime

    END_IF
        rts
.endproc ; DoStopAction

;;; ============================================================

.proc DoPauseAction
        lda     StopButtonState
    IF ZERO
        ;; Toggle Pause button
        lda     #$ff
        eor     PauseButtonState
        sta     PauseButtonState
        jsr     ToggleUIPauseButton

        ;; Execute pause action (pause or resume) based on new button state
        jsr     C22AudioPause
    END_IF
        rts
.endproc ; DoPauseAction

;;; ============================================================

.proc ToggleLoopMode
        lda     #$ff
        eor     LoopButtonState
        sta     LoopButtonState
        jsr     ToggleUILoopButton
        rts
.endproc ; ToggleLoopMode

;;; ============================================================

.proc ToggleRandomMode
        lda     #$ff
        eor     RandomButtonState
        sta     RandomButtonState
    IF NOT_ZERO
        ;; Random button is now active - re-initialize random mode and exit
        jsr     RandomModeInit
    ELSE
        ;; Random button is now inactive - reset First/Last to TOC values and update stop point to EoT last Track
RandomIsInactive:
        lda     BCDLastTrackTOC
        sta     BCDLastTrackNow
        lda     BCDFirstTrackTOC
        sta     BCDFirstTrackNow
        jsr     SetStopToEoBCDLTN
    END_IF

        ;; Update UI, wait for key release, and exit
        jsr     ToggleUIRandButton
        rts
.endproc ; ToggleRandomMode

;;; ============================================================

.proc RandomModeInit
        ;; Zero the Played Track Counter
        lda     #$00
        sta     HexPlayedCount0Base
        ;; Clear the list of what Tracks have been played
        jsr     ClearPlayedList

        ;; Convert the BCD count-of-tracks-minus-1 into a Hex count-of-tracks-minus-1 and store it in HexTrackCount0Base
        lda     BCDTrackCount0Base
        and     #$0f
        sta     HexTrackCount0Base
        lda     BCDTrackCount0Base
        and     #$f0
        lsr     a
        sta     RandFuncTempStorage
        lsr     a
        lsr     a
        clc
        adc     RandFuncTempStorage
        clc
        adc     HexTrackCount0Base
        ;; This value is used to compare against HexPlayedCount0Base so we can determine when we've random-played the whole disc
        sta     HexTrackCount0Base

        lda     PlayButtonState
        ;; Play button is inactive - don't do anything else
        beq     ExitRandomInit

        ;; Play button is active - set the current Track as First/Last/Picked, and set the proper random Stop mode
        lda     BCDRelTrack
        sta     BCDRandomPickedTrk
        sta     BCDFirstTrackNow
        sta     BCDLastTrackNow
        jsr     SetStopToEoBCDLTN

        ;; Mark the current Track's element of the Played List as $FF ("played")
        tya
        pha
        ldy     BCDRelTrack
        lda     #$ff
        sta     (PlayedListPtr),y
        pla
        tay

ExitRandomInit:
        rts
.endproc ; RandomModeInit

;;; ============================================================

.proc DoScanBackAction
        lda     PlayButtonState
        ;; Play button is inactive - bail out, there's nothing to do
        beq     ExitScanBackAction

        lda     PauseButtonState
        ;; Pause button is active - bail out, there's nothing to do
        bne     ExitScanBackAction

        ;; Highlight the Scan Back button and engage "scan" mode backwards
        jsr     ToggleUIScanBackButton
        jsr     C25AudioScanBack

        ;; Keep updating the time display as long as you get good QSub reads
Loop:
        jsr     C28ReadQSubcode
        bcs     QSubReadErr
        jsr     DrawTrack
        jsr     DrawTime

        ;; Keep scanning as long as the key is held down
QSubReadErr:
        jsr     CheckGestureEnded
        bmi     Loop

        ;; Key released - dim the Scan Back button, and resume playing from where we are
        jsr     ToggleUIScanBackButton
        jsr     C22AudioPause
ExitScanBackAction:
        rts
.endproc ; DoScanBackAction

;;; ============================================================

.proc DoScanFwdAction
        lda     PlayButtonState
        ;; Play button is inactive - bail out, there's nothing to do
        beq     ExitScanFwdAction

        lda     PauseButtonState
        ;; Pause button is active - bail out, there's nothing to do
        bne     ExitScanFwdAction

        ;; Highlight the Scan Forward button and engage "scan" mode forward
        jsr     ToggleUIScanFwdButton
        jsr     C25AudioScanFwd

        ;; Keep updating the time display as long as you get good QSub reads
Loop:
        jsr     C28ReadQSubcode
        bcs     QSubReadErr
        jsr     DrawTrack
        jsr     DrawTime

        ;; Keep scanning as long as the key is held down
QSubReadErr:
        jsr     CheckGestureEnded
        bmi     Loop

        ;; Key released - dim the Scan Forward button, and resume playing from where we are
        jsr     ToggleUIScanFwdButton
        jsr     C22AudioPause
ExitScanFwdAction:
        rts
.endproc ; DoScanFwdAction

;;; ============================================================

.proc DoPrevTrackAction
        jsr     ToggleUIPrevButton

        ;; Reset to start of track
        lda     #$00
        sta     BCDRelMinutes
        sta     BCDRelSeconds
        jsr     DrawTime

WrapCheck:
        lda     BCDRelTrack
    IF A = BCDFirstTrackTOC
        ;; If we're not at the "first" track, just decrement track #
        ;; Otherwise, wrap to the "last" track instead
        lda     BCDLastTrackTOC
        sta     BCDRelTrack
    ELSE
        ;; BCD decrement
        sed
        lda     BCDRelTrack
        sbc     #$01
        sta     BCDRelTrack
        cld
    END_IF

        lda     RandomButtonState
    IF NOT_ZERO
        ;; Random button is active - set the current Track as First/Last/Picked, and set the proper random Stop mode
        lda     BCDRelTrack
        sta     BCDFirstTrackNow
        sta     BCDLastTrackNow
        sta     BCDRandomPickedTrk
        jsr     SetStopToEoBCDLTN
    END_IF

        ;; Seek to new Track and update Track display
        jsr     C20AudioSearch
        jsr     DrawTrack

        lda     #$FF            ; TODO: Does this need to be a word?
        sta     Counter
HeldKeyCheck:
        jsr     CheckGestureEnded
        bpl     KeyReleased
        dec     Counter
        beq     WrapCheck   ; Repeat the action
        bne     HeldKeyCheck ; always

KeyReleased:
        jsr     ToggleUIPrevButton
        rts

Counter:
        .byte   0
.endproc ; DoPrevTrackAction

;;; ============================================================

.proc DoNextTrackAction
        jsr     ToggleUINextButton

        ;; Reset to start of track
        lda     #$00
        sta     BCDRelMinutes
        sta     BCDRelSeconds
        jsr     DrawTime

WrapCheck:
        lda     BCDRelTrack
    IF A = BCDLastTrackTOC
        ;; If we're not at the "last" track, just increment track #
        ;; Otherwise, wrap to the "first" track instead
        lda     BCDFirstTrackTOC
        sta     BCDRelTrack
    ELSE
        ;; BCD increment
        sed
        lda     BCDRelTrack
        adc     #$01
        sta     BCDRelTrack
        cld
    END_IF

        lda     RandomButtonState
    IF NOT_ZERO
        ;; Random button is active - set the current Track as First/Last/Picked, and set the proper random Stop mode
        lda     BCDRelTrack
        sta     BCDFirstTrackNow
        sta     BCDLastTrackNow
        sta     BCDRandomPickedTrk
        jsr     SetStopToEoBCDLTN
    END_IF

        ;; Seek to new Track and update Track display
        jsr     C20AudioSearch
        jsr     DrawTrack

        lda     #$FF            ; TODO: Does this need to be a word?
        sta     Counter
HeldKeyCheck:
        jsr     CheckGestureEnded
        bpl     KeyReleased
        dec     Counter
        beq     WrapCheck   ; Repeat the action
        bne     HeldKeyCheck ; always

KeyReleased:
        jsr     ToggleUINextButton
        rts

Counter:
        .byte   0
.endproc ; DoNextTrackAction

;;; ============================================================

.proc C26Eject
        jsr     ToggleUIEjectButton

        lda     #SPControlSCSIAudio::Eject
        sta     SPCode
        lda     #SPCall::Control
        sta     SPCommandType
        jsr     SPCallVector

        jsr     ToggleUIEjectButton

        lda     StopButtonState
    IF ZERO
        ;; Stop button was active

        lda     PauseButtonState
      IF NOT_ZERO
        ;; Clear Pause button to inactive
        lda     #$00
        sta     PauseButtonState
        jsr     ToggleUIPauseButton
      END_IF

        lda     PlayButtonState
      IF NOT_ZERO
        ;; Clear Play button to inactive
        lda     #$00
        sta     PlayButtonState
        jsr     ToggleUIPlayButton
      END_IF

        ;; Clear Drive Playing state
        lda     #$00
        sta     DrivePlayingFlag

        ;; Set Stop button to active
        sec
        sbc     #1
        sta     StopButtonState
        jsr     ToggleUIStopButton
    END_IF

        ;; "Null" out T/M/S, blank Track & Time display, and invalidate the TOC
        lda     #$aa
        sta     BCDRelTrack
        sta     BCDRelMinutes
        sta     BCDRelSeconds

        jsr     DrawTrack
        jsr     DrawTime

        lda     #$ff
        sta     TOCInvalidFlag

        rts
.endproc ; C26Eject

;;; ============================================================

.proc C21AudioPlay
        lda     #$ff
        sta     DrivePlayingFlag
        lda     #SPCall::Control
        sta     SPCommandType
        lda     #SPControlSCSIAudio::AudioPlay
        sta     SPCode
        jsr     ZeroOutSPBuffer

        ;; Stop flag = $00 (stop address in 2-5)  LA I think this is wrong, and it should be start address?
        lda     #$00
        sta     SPBuffer
        ;; Play mode = $09 (Standard stereo)
        lda     #$09
        sta     SPBuffer + 1

        lda     TrackOrMSFFlag
        ;; Use M/S/F to stop playback at the end of the disc for sequential mode
        beq     StopAtMSF

        ;; Use end of currently-selected Track as "stop" point for random mode
StopAtTrack:
        lda     BCDFirstTrackNow
        sta     SPBuffer + 2
        ;; Address Type = $02 (Track)
        lda     #$02
        sta     SPBuffer + 6
        lda     #$00
        sta     TrackOrMSFFlag
        beq     CallAudioPlay   ; always

StopAtMSF:
        lda     BCDAbsMinutes
        sta     SPBuffer + 4
        lda     BCDAbsSeconds
        sta     SPBuffer + 3
        lda     BCDAbsFrame
        sta     SPBuffer + 2
        ;; Address Type = $01 (MSF)
        lda     #$01
        sta     SPBuffer + 6

CallAudioPlay:
        jsr     SPCallVector
        rts
.endproc ; C21AudioPlay

;;; ============================================================


.proc C20AudioSearch
        lda     #SPCall::Control
        sta     SPCommandType
        lda     #SPControlSCSIAudio::AudioSearch
        sta     SPCode
        jsr     ZeroOutSPBuffer

        lda     PlayButtonState
        ;; Play button is inactive - seek and hold
        beq     HoldAfterSearch

        ;; Play button is active - seek and play
PlayAfterSearch:
        lda     #$ff
        ;; Set the Drive Playing flag to active
        sta     DrivePlayingFlag

        ;; $01 = Play after search
        lda     #$01
        bne     ExecuteSearch ; always

        ;; $00 = Hold after search
HoldAfterSearch:
        lda     #$00
ExecuteSearch:
        sta     SPBuffer
        ;; $09 = Play mode (Standard stereo)
        lda     #$09
        sta     SPBuffer + 1
        ;; Search address = Track
        lda     BCDRelTrack
        sta     SPBuffer + 2
        ;; Address Type = $02 (Track)
        lda     #$02
        sta     SPBuffer + 6
        jsr     SPCallVector

        lda     PauseButtonState
    IF NOT_ZERO
        ;; Clear Pause button to inactive
        inc     PauseButtonState
        jsr     ToggleUIPauseButton
    END_IF

        lda     BCDRelTrack
        sta     BCDFirstTrackNow
        rts
.endproc ; C20AudioSearch

;;; ============================================================

.proc C24AudioStatus
        lda     #SPCall::Control
        sta     SPCommandType
        lda     #SPControlSCSIAudio::AudioStatus
        sta     SPCode

        ;; Try 3 times to fetch the Audio Status, then give up.
        lda     #$03
        sta     RetryCount
AudioStatusRetry:
        jsr     SPCallVector
        bcc     ExitAudioStatus
        dec     RetryCount
        bne     AudioStatusRetry

ExitAudioStatus:
        rts
.endproc ; C24AudioStatus

;;; ============================================================

.proc C27ReadTOC
        lda     #SPCall::Control
        sta     SPCommandType
        lda     #SPControlSCSIAudio::ReadTOC
        sta     SPCode
        ;; Start Track # = $00 (Whole Disc), Type = $00 (request First/Last Track numbers)
        jsr     ZeroOutSPBuffer
        ;; Allocation Length = $0A (even though this space is unused)
        lda     #$0a
        sta     SPBuffer + 1

        ;; Try 3 times to read the TOC, then give up.
        lda     #$03
        sta     RetryCount
ReadTOCRetry:
        jsr     SPCallVector
        bcc     ReadTOCSuccess
        dec     RetryCount
        bne     ReadTOCRetry
        sec
        bcs     ExitReadTOC     ; always

        ;; First Track #
ReadTOCSuccess:
        lda     SPBuffer
        sta     BCDFirstTrackTOC
        sta     BCDFirstTrackNow
        ;; Last Track #
        lda     SPBuffer + 1
        sta     BCDLastTrackTOC
        sta     BCDLastTrackNow
        clc
ExitReadTOC:
        rts
.endproc ; C27ReadTOC

;;; ============================================================

.proc C28ReadQSubcode
        lda     #SPCall::Control
        sta     SPCommandType
        lda     #SPControlSCSIAudio::ReadQSubcode
        sta     SPCode

        ;; Try 3 times to read the QSubcode, then give up.
        lda     #$03
        sta     RetryCount
RetryReadQSubcode:
        jsr     SPCallVector
        bcc     ReadQSubcodeSuccess
        dec     RetryCount
        bne     RetryReadQSubcode
        beq     ExitReadQSubcode ; always

        ;; Data is the control flag, the track number (BCD), the index
        ;; number, then minutes/seconds/frames (BCD) relative to the
        ;; start of the track, then minutes/seconds/frames (BCD)
        ;; absolute disc position. (c/o @MESSDrivers on YouTube)
ReadQSubcodeSuccess:
        lda     SPBuffer + 1
        sta     BCDRelTrack
        lda     SPBuffer + 3
        sta     BCDRelMinutes
        lda     SPBuffer + 4
        sta     BCDRelSeconds
        lda     SPBuffer + 6
        sta     BCDAbsMinutes
        lda     SPBuffer + 7
        sta     BCDAbsSeconds
        lda     SPBuffer + 8
        sta     BCDAbsFrame

        lda     SPBuffer + 2
        beq     ReadQSubcodeFail

        ;; Clear carry on success
        clc
        bcc     ExitReadQSubcode ; always

        ;; Set carry on failure
ReadQSubcodeFail:
        sec
ExitReadQSubcode:
        rts
.endproc ; C28ReadQSubcode

;;; ============================================================

.proc C23AudioStop
        lda     #$00
        sta     DrivePlayingFlag

        lda     #SPCall::Control
        sta     SPCommandType
        lda     #SPControlSCSIAudio::AudioStop
        sta     SPCode
        ;; Address type = $00 (Block), Block = 0
        jsr     ZeroOutSPBuffer
        ;; All-zeros AudioStop stops immediately. Unknown if it
        ;; affects the saved stop position. (c/o @MESSDrivers on
        ;; YouTube)
        jsr     SPCallVector
        FALL_THROUGH_TO SetStopToEoBCDLTN
.endproc ; C23AudioStop

;;; ============================================================

.proc SetStopToEoBCDLTN
        lda     #SPCall::Control
        sta     SPCommandType
        lda     #SPControlSCSIAudio::AudioStop
        sta     SPCode
        jsr     ZeroOutSPBuffer
        ;; Address = Last Track
        lda     BCDLastTrackNow
        sta     SPBuffer
        ;; Address Type = $02 (Track)
        lda     #$02
        sta     SPBuffer + 4
        ;; Set a stop point at EoT, last Track
        jsr     SPCallVector
        rts
.endproc ; SetStopToEoBCDLTN

;;; ============================================================

.proc C22AudioPause
        lda     #SPCall::Control
        sta     SPCommandType
        lda     #SPControlSCSIAudio::AudioPause
        sta     SPCode
        jsr     ZeroOutSPBuffer

        lda     PauseButtonState
        ;; Invert the current Pause button state...
        eor     #$ff
        ;; and make it the Drive Playing state
        sta     DrivePlayingFlag
        ;; Mask off the low bit in order to use the new Drive Playing state value to set the Pause/Unpause parameter for the call
        and     #$01
        ;; $00 = Pause, $01 = UnPause/Resume (Button $00 = Paused, $FF = Unpaused)
        sta     SPBuffer
        jsr     SPCallVector
        rts
.endproc ; C22AudioPause

;;; ============================================================

.proc C25AudioScanFwd
        lda     #SPControlSCSIAudio::AudioScan
        sta     SPCode
        lda     #SPCall::Control
        sta     SPCommandType
        jsr     ZeroOutSPBuffer

        ;; $00 = Forward
        lda     #$00
        sta     SPBuffer
        ;; Start from the current M/S/F
        lda     BCDAbsMinutes
        sta     SPBuffer + 4
        lda     BCDAbsSeconds
        sta     SPBuffer + 3
        lda     BCDAbsFrame
        sta     SPBuffer + 2
        ;; $01 = Type (MSF)
        lda     #$01
        sta     SPBuffer + 6
        jsr     SPCallVector
        rts
.endproc ; C25AudioScanFwd

;;; ============================================================

.proc C25AudioScanBack
        lda     #SPCall::Control
        sta     SPCommandType
        lda     #SPControlSCSIAudio::AudioScan
        sta     SPCode
        jsr     ZeroOutSPBuffer

        ;; $01 = Backward
        lda     #$01
        sta     SPBuffer
        ;; Start from the current M/S/F
        lda     BCDAbsMinutes
        sta     SPBuffer + 4
        lda     BCDAbsSeconds
        sta     SPBuffer + 3
        lda     BCDAbsFrame
        sta     SPBuffer + 2
        ;; $01 = Type (MSF)
        lda     #$01
        sta     SPBuffer + 6
        jsr     SPCallVector
        rts
.endproc ; C25AudioScanBack

;;; ============================================================

.proc ZeroOutSPBuffer
        lda     #$00
        ldx     #$0e
SPZeroLoop:
        sta     SPBuffer,x
        dex
        bpl     SPZeroLoop
        rts
.endproc ; ZeroOutSPBuffer

;;; ============================================================

.proc FindHardware
        ;; Save state
        jsr     FindSCSICard
        bcs     ExitFindHardware
        jsr     SmartPortCallSetup
        jsr     FindCDROM
ExitFindHardware:
        rts

;;; --------------------------------------------------

.proc FindSCSICard
        lda     #$07
CheckSlot:
        sta     CardSlot
        and     #$0f
        ora     #$c0
        sta     ZP1 + 1
        lda     #$fb
        sta     ZP1
        ldy     #0              ; TODO: Preserve Y?
        lda     (ZP1),y
        ;; $82 = SCSI card, extended SP calls
        cmp     #$82
        beq     YesFound
        lda     CardSlot
        sec
        sbc     #1
        bne     CheckSlot
        ;; Set carry on error
        sec
        bcs     ExitFindSCSICard ; always
        ;; Clear carry on success
YesFound:
        clc
ExitFindSCSICard:
        rts
.endproc ; FindSCSICard

;;; --------------------------------------------------

.proc FindCDROM
        lda     #SPCall::Status
        sta     SPCommandType

        ;; UnitNum = $00, StatusCode = $00 returns status of SmartPort itself
        lda     #$00
        sta     SPUnitNumber
        sta     SPCode

        ;; ParmCount = 3
        lda     #$03
        sta     SPParmCount

        jsr     SPCallVector

        ;; Byte offset $00 = Number of devices connected
        ldx     SPBuffer
        ;; $03 = Return Device Information Block (DIB), 25 bytes
        lda     #$03
        sta     SPCode

NextDevice:
        stx     CD_SPDevNum
        stx     SPUnitNumber
        ;; Make DIB call for current device
        jsr     SPCallVector

        ;; Byte 1 = Device status
        lda     SPBuffer
        ;; Force "online" bit true
        ora     #$10
        ;; $B4 = 10110100 = Block device, Not writeable, Readable, Can't format, Write protected (aka CD-ROM)
        cmp     #$b4
        beq     CDROMFound

        ldx     CD_SPDevNum
        dex
        bne     NextDevice
        ;; Set carry on failure
        sec
        bcs     ExitFindCDROM   ; always
        ;; Clear carry on success
CDROMFound:
        clc
ExitFindCDROM:
        rts
.endproc ; FindCDROM

;;; --------------------------------------------------

.proc SmartPortCallSetup
        pha
        lda     CardSlot
        ora     #$c0
        sta     SPCallVector + 2
        sta     SelfModLDA + 2
SelfModLDA:
        lda     $C0FF   ; high byte is modified
        clc
        adc     #$03
        sta     SPCallVector + 1
        pla
        rts
.endproc ; SmartPortCallSetup

.endproc ; FindHardware

;;; ============================================================

SPCallVector:
        jsr     $0000
SPCommandType:
        .byte   $00
SPParmsAddr:
        .addr   SPParmCount
        rts

        ;; SmartPort Parameter Table
SPParmCount:    .byte   $00
SPUnitNumber:   .byte   $00
SPBufferAddr:   .addr   SPBuffer
        ;; Status code for SPCommandType Status ($00), Control code for SPCommandType Control ($04)
SPCode: .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

SPBuffer        := DA_IO_BUFFER  ; 1K free to use in Main after loading

;;; ============================================================

.proc DrawTrack
        pha

        ;; Only update/draw if changed
        lda     BCDRelTrack
        cmp     last_track
        beq     skip

        txa
        pha
        tya
        pha
        lda     BCDRelTrack
        sta     last_track
        jsr     HighBCDDigitToASCII
        sta     str_track_num+1 ; "0_"
        lda     BCDRelTrack
        jsr     LowBCDDigitToASCII
        sta     str_track_num+2 ; "_0"

        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, aux::getwinport_params
    IF ZERO
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, aux::grafport
        jsr     ::DrawTrack
    END_IF

        pla
        tay
        pla
        tax
skip:
        pla
        rts
.endproc ; DrawTrack

.proc DrawTime
        pha

        ;; Only update/draw if changed
        lda     BCDRelMinutes
        cmp     last_min
        bne     :+
        lda     BCDRelSeconds
        cmp     last_sec
        beq     skip
:
        txa
        pha
        tya
        pha
        lda     BCDRelMinutes
        sta     last_min
        jsr     HighBCDDigitToASCII
        sta     str_time+1      ; "0_:__"
        lda     BCDRelMinutes
        jsr     LowBCDDigitToASCII
        sta     str_time+2      ; "_0:__"

        lda     BCDRelSeconds
        sta     last_sec
        jsr     HighBCDDigitToASCII
        sta     str_time+4      ; "__:0_"
        lda     BCDRelSeconds
        jsr     LowBCDDigitToASCII
        sta     str_time+5      ; "__:_0"

        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, aux::getwinport_params
    IF ZERO
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, aux::grafport
        jsr     ::DrawTime
    END_IF

        pla
        tay
        pla
        tax
skip:
        pla
        rts
.endproc ; DrawTime

last_track:
        .byte   $FF
last_min:
        .byte   $FF
last_sec:
        .byte   $FF

.proc HighBCDDigitToASCII
        and     #$F0
        clc
        ror
        ror
        ror
        ror
    IF A < #10                  ; stuffed with $AA to blank
        ora     #'0'
        rts
    END_IF
        lda     #' '
        rts
.endproc ; HighBCDDigitToASCII

.proc LowBCDDigitToASCII
        and     #$0F
    IF A < #10                  ; stuffed with $AA to blank
        ora     #'0'
        rts
    END_IF
        lda     #' '
        rts
.endproc ; LowBCDDigitToASCII

;;; ============================================================

ToggleUIStopButton:
        TAIL_CALL ::InvertButton, AX=#aux::stop_button_rect

ToggleUIPlayButton:
        TAIL_CALL ::InvertButton, AX=#aux::play_button_rect

ToggleUIEjectButton:
        TAIL_CALL ::InvertButton, AX=#aux::eject_button_rect

ToggleUIPauseButton:
        TAIL_CALL ::InvertButton, AX=#aux::pause_button_rect

ToggleUINextButton:
        TAIL_CALL ::InvertButton, AX=#aux::next_button_rect

ToggleUIPrevButton:
        TAIL_CALL ::InvertButton, AX=#aux::prev_button_rect

ToggleUIScanBackButton:
        TAIL_CALL ::InvertButton, AX=#aux::back_button_rect

ToggleUIScanFwdButton:
        TAIL_CALL ::InvertButton, AX=#aux::fwd_button_rect

ToggleUILoopButton:
        TAIL_CALL ::InvertButton, AX=#aux::loop_button_rect

ToggleUIRandButton:
        TAIL_CALL ::InvertButton, AX=#aux::shuffle_button_rect

;;; ============================================================

.proc PickARandomTrack
        pha
        ;; Pick a random, unplayed track
        txa
        pha
        tya
        pha

        ;; Try five times to find a Played List element that is $00
        ldx     #$05
FindRandomUnplayed:
        jsr     TrackPseudoRNGSub
        tay
        lda     (PlayedListPtr),y
        beq     FoundUnplayedTrack
        dex
        bne     FindRandomUnplayed

        ;; Toggle PLDirection from $01 to $FF (+1 to -1)
        lda     #$fe
        eor     PlayedListDirection
        sta     PlayedListDirection

        ;; Fallback routine to always find an unplayed track by adding "Direction" to the offset until one is found
FallbackTrackSelect:
        tya
        clc
        adc     PlayedListDirection
        tay
        bne     OffsetNotZero
        ldy     HexTrackCount0Base
        jmp     TryThisTrack

OffsetNotZero:
        cpy     HexTrackCount0Base
        beq     TryThisTrack
        bmi     TryThisTrack
        ldy     #$01

TryThisTrack:
        lda     (PlayedListPtr),y
        bne     FallbackTrackSelect

        ;; Mark the PlayedList element for the selected Track to $FF ("played") and set BCDRandomPickedTrk to the BCD Track number
FoundUnplayedTrack:
        lda     #$ff
        sta     (PlayedListPtr),y
        tya
        jsr     Hex2BCDSorta
        sta     BCDRandomPickedTrk

        pla
        tay
        pla
        tax
        pla
        rts
.endproc ; PickARandomTrack

PlayedListDirection:
        .byte   $00

;;; ============================================================

        ;; TODO: Analysis - Understand the operation of this subroutine better, improve comments
.proc TrackPseudoRNGSub
        stx     PRNGSaveX
        ;; Return A as (Seed * 253) mod HexMaxTrackOffset
        sty     PRNGSaveY

        ;; 253 - not sure why?
        ldx     #$fd
        lda     RandomSeed
        bne     PRNGSeedIsValid
        clc
        adc     #1

        ;; A = RandFuncTempStorage = Seed (adjusted to 1-255)
PRNGSeedIsValid:
        sta     RandFuncTempStorage
        dex

        ;; Add the seed to A, 252 times.
PRNGMathLoop1:
        clc
        adc     RandFuncTempStorage
        dex
        bne     PRNGMathLoop1

        clc
        adc     #$01
        and     #$7f
        bne     PRNGMathLoop2
        clc
        adc     #1

PRNGMathLoop2:
        cmp     HexTrackCount0Base
        bmi     ExitMathLoop2
        clc
        sbc     HexTrackCount0Base
        jmp     PRNGMathLoop2

ExitMathLoop2:
        clc
        adc     #1

PRNGSaveY       := *+1
        ldy     #SELF_MODIFIED_BYTE
PRNGSaveX       := *+1
        ldx     #SELF_MODIFIED_BYTE
        rts
.endproc ; TrackPseudoRNGSub

;;; ============================================================

        ;; This just zeroes all 99 elements in the Played List
.proc ClearPlayedList
        lda     #$00
        ldy     #99

CPLLoop:
        sta     (PlayedListPtr),y
        dey
        bpl     CPLLoop

        rts
.endproc ; ClearPlayedList

;;; ============================================================

        ;; Set up the ($1F) Played List ZP pointer and zero all the Played List elements
.proc InitPlayedList
        lda     PlayedListAddr
        sta     PlayedListPtr
        lda     PlayedListAddr + 1
        sta     PlayedListPtr + 1

        jsr     ClearPlayedList

        ;; Zero the Played Track Counter
        lda     #$00
        sta     HexPlayedCount0Base

        ;; Set the PLDirection initially to +1
        lda     #$01
        sta     PlayedListDirection
        rts
.endproc ; InitPlayedList

;;; ============================================================

        ;; TODO: Analysis - WTF is going on here?? This *seems* like an attempt to convert from BCD to binary, but it's... not.  It's kinda wonky.
.proc Hex2BCDSorta
        stx     Hex2BCDSaveX
        ;; TODO: Analysis - The return values from this function seem bizarre and inexplicable.  Better analysis needs to be done on this code.
        sty     Hex2BCDSaveY

        ldx     #$00
DivideBy10:
        cmp     #$0a
        bmi     TenOrLess
        inx
        clc
        sbc     #$0a
        jmp     DivideBy10

TenOrLess:
        sta     Hex2BCDTemp
        txa
        clc
        rol     a
        rol     a
        rol     a
        rol     a
        clc
        adc     Hex2BCDTemp

Hex2BCDSaveY    := *+1
        ldy     #SELF_MODIFIED_BYTE
Hex2BCDSaveX    := *+1
        ldx     #SELF_MODIFIED_BYTE
        rts

Hex2BCDTemp:
        .byte   $00
.endproc ; Hex2BCDSorta

;;; ============================================================

        ;; UI Button Flags: $00 = "Inactive" button and dim in UI, $FF = "Active" button and highlighted in UI
PlayButtonState:        .byte   $00
StopButtonState:        .byte   $00
PauseButtonState:       .byte   $00
LoopButtonState:        .byte   $00
RandomButtonState:      .byte   $00

        ;; $00 = M/S/F, $FF = Track
TrackOrMSFFlag: .byte   $00
        ;; $00 = Not Playing, $FF = Playing
DrivePlayingFlag:       .byte   $00
        ;; $00 = TOC has been read and is valid, $FF = TOC has not been read and is invalid
TOCInvalidFlag: .byte   $00

        ;; SmartPort Unit Number of the CD-ROM
CD_SPDevNum:    .byte   $00
        ;; Slot with the SCSI card
CardSlot:       .byte   $00

        ;; Counter for SmartPort/SCSI operation retries
RetryCount:     .byte   $00

        ;; BCD T/M/S values of the Relative (track-level) current read position as reported by the disc's Q Subcode channel
BCDRelTrack:    .byte   $00
BCDRelMinutes:  .byte   $00
BCDRelSeconds:  .byte   $00
        ;; BCD values of the "First" and "Last" Tracks for the current playback mode (random/sequential)
BCDFirstTrackNow:       .byte   $00
BCDLastTrackNow:        .byte   $00
        ;; BCD value of the randomly picked Track to play
BCDRandomPickedTrk:     .byte   $00
        ;; Hex value of the number of tracks played in the current random session, minus 1 (0-based)
HexPlayedCount0Base:    .byte   $00
        ;; BCD values of the First and Last Tracks on the disc as read from the TOC
BCDFirstTrackTOC:       .byte   $00
BCDLastTrackTOC:        .byte   $00
        ;; BCD value of the number of Tracks on the disc, minus 1 (0-based)
BCDTrackCount0Base:     .byte   $00
        ;; BCD M/S/F values of the Absolute (disc-level) current read position as reported by the disc's Q Subcode channel
BCDAbsMinutes:  .byte   $00
BCDAbsSeconds:  .byte   $00
BCDAbsFrame:    .byte   $00
        ;; Hex value of the number of Tracks on the disc, minus 1 (0-based)
HexTrackCount0Base:     .byte   $00
        ;; Random seed, generated by continuously incrementing while iterating the main program loop
RandomSeed:     .byte   $00
        ;; Temporary variable for randomization operations
RandFuncTempStorage:    .byte   $00

        ;; List of flags identifying Tracks that have been played in the current random session (provides no-repeat random capability)
PlayedList:
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
PlayedListAddr:
        .addr   PlayedList

.endscope ; cdremote

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
