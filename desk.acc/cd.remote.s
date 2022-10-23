;;; ============================================================
;;; CD.REMOTE - Desk Accessory
;;;
;;; Control an AppleCD SC via SCSI card
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "startup.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
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
;;;          | IO Buffer/  | |Win Tables   |
;;;          | SP Data Buf | |             |
;;;  $1C00   +-------------+ |             |
;;;  $1B00   |             | +-------------+
;;;          |             | |             |
;;;          | (unused)    | | (unused)    |
;;; ~$1800   +-------------+ +-------------+
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          | DA          | | DA (copy)   |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;
;;; ============================================================

        .org DA_LOAD_ADDRESS

da_start:

;;; Copy the DA to AUX for MGTK resources
.scope
        copy16  #da_start, STARTLO
        copy16  #da_end, ENDLO
        copy16  #da_start, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
.endscope

.scope
        jmp     cdremote__MAIN
.endscope

;;; ============================================================


kDAWindowId     = 63
kDAWidth        = 271
kDAHeight       = 57
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

str_title:
        PASCAL_STRING "CD Remote"

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
mincontlength:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontlength:  .word   kDAHeight
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
textback:       .byte   $00
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
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
        .byte   PX(%0011111),PX(%1111111),PX(%1100000)
        .byte   PX(%0011111),PX(%1111111),PX(%1100000)
        .byte   PX(%0011111),PX(%1111111),PX(%1100000)
        .byte   PX(%0011111),PX(%1111111),PX(%1100000)
        .byte   PX(%0011111),PX(%1111111),PX(%1100000)
        .byte   PX(%0011111),PX(%1111111),PX(%1100000)
        .byte   PX(%0011111),PX(%1111111),PX(%1100000)
pause_bitmap:
        .byte   PX(%0011111),PX(%0000111),PX(%1100000)
        .byte   PX(%0011111),PX(%0000111),PX(%1100000)
        .byte   PX(%0011111),PX(%0000111),PX(%1100000)
        .byte   PX(%0011111),PX(%0000111),PX(%1100000)
        .byte   PX(%0011111),PX(%0000111),PX(%1100000)
        .byte   PX(%0011111),PX(%0000111),PX(%1100000)
        .byte   PX(%0011111),PX(%0000111),PX(%1100000)
play_bitmap:
        .byte   PX(%0000110),PX(%0000000),PX(%0000000)
        .byte   PX(%0000111),PX(%1100000),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0000111),PX(%1111111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0000111),PX(%1100000),PX(%0000000)
        .byte   PX(%0000110),PX(%0000000),PX(%0000000)
fwd_bitmap:
        .byte   PX(%0110000),PX(%0011000),PX(%0000000)
        .byte   PX(%0111100),PX(%0011110),PX(%0000000)
        .byte   PX(%0111111),PX(%0011111),PX(%1000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1110000)
        .byte   PX(%0111111),PX(%0011111),PX(%1000000)
        .byte   PX(%0111100),PX(%0011110),PX(%0000000)
        .byte   PX(%0110000),PX(%0011000),PX(%0000000)
next_bitmap:
        .byte   PX(%1100000),PX(%0110000),PX(%0011000)
        .byte   PX(%1111000),PX(%0111100),PX(%0011000)
        .byte   PX(%1111110),PX(%0111111),PX(%0011000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111110),PX(%0111111),PX(%0011000)
        .byte   PX(%1111000),PX(%0111100),PX(%0011000)
        .byte   PX(%1100000),PX(%0110000),PX(%0011000)
back_bitmap:
        .byte   PX(%0000000),PX(%1100000),PX(%0110000)
        .byte   PX(%0000011),PX(%1100001),PX(%1110000)
        .byte   PX(%0001111),PX(%1100111),PX(%1110000)
        .byte   PX(%0111111),PX(%1111111),PX(%1110000)
        .byte   PX(%0001111),PX(%1100111),PX(%1110000)
        .byte   PX(%0000011),PX(%1100001),PX(%1110000)
        .byte   PX(%0000000),PX(%1100000),PX(%0110000)
prev_bitmap:
        .byte   PX(%1100000),PX(%0110000),PX(%0011000)
        .byte   PX(%1100001),PX(%1110000),PX(%1111000)
        .byte   PX(%1100111),PX(%1110011),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1100111),PX(%1110011),PX(%1111000)
        .byte   PX(%1100001),PX(%1110000),PX(%1111000)
        .byte   PX(%1100000),PX(%0110000),PX(%0011000)
eject_bitmap:
        .byte   PX(%0000000),PX(%0110000),PX(%0000000)
        .byte   PX(%0000001),PX(%1111100),PX(%0000000)
        .byte   PX(%0000111),PX(%1111111),PX(%0000000)
        .byte   PX(%0011111),PX(%1111111),PX(%1100000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0011111),PX(%1111111),PX(%1100000)
        .byte   PX(%0011111),PX(%1111111),PX(%1100000)
shuffle_bitmap:
        .byte   PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%1111100),PX(%0000111),PX(%1111000)
        .byte   PX(%0000011),PX(%0011000),PX(%1100000)
        .byte   PX(%0000000),PX(%1100000),PX(%0000000)
        .byte   PX(%0000011),PX(%0011000),PX(%1100000)
        .byte   PX(%1111100),PX(%0000111),PX(%1111000)
        .byte   PX(%0000000),PX(%0000000),PX(%1100000)
loop_bitmap:
        .byte   PX(%0000000),PX(%0000110),PX(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1000000)
        .byte   PX(%1100000),PX(%0000110),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100011),PX(%0000000),PX(%0011000)
        .byte   PX(%0001111),PX(%1111111),PX(%1110000)
        .byte   PX(%0000011),PX(%0000000),PX(%0000000)


;;; ============================================================

logo_bitmap:
        .byte   PX(%0000000),PX(%1111100),PX(%1110111),PX(%1011011),PX(%0111001),PX(%0011101),PX(%1100000)
        .byte   PX(%0000000),PX(%1000100),PX(%1000100),PX(%1010101),PX(%0111011),PX(%1010000),PX(%1000000)
        .byte   PX(%0000000),PX(%1000100),PX(%1110111),PX(%1010001),PX(%0100010),PX(%1011100),PX(%1000000)
        .byte   PX(%0000000),PX(%1000100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1000100),PX(%1111100),PX(%0111111),PX(%1110001),PX(%1111111),PX(%1100000)
        .byte   PX(%1000000),PX(%0000100),PX(%1000100),PX(%1000000),PX(%0010010),PX(%0000000),PX(%0010000)
        .byte   PX(%1000111),PX(%1000100),PX(%1000100),PX(%1000000),PX(%0010010),PX(%0011110),PX(%0010000)
        .byte   PX(%1000100),PX(%1000100),PX(%1000100),PX(%1000111),PX(%1100010),PX(%0010001),PX(%1110000)
        .byte   PX(%1000100),PX(%1000100),PX(%1000100),PX(%1000000),PX(%0010010),PX(%0010000),PX(%0000000)
        .byte   PX(%1000100),PX(%1000100),PX(%1000100),PX(%1000000),PX(%0010010),PX(%0010000),PX(%0000000)
        .byte   PX(%1000100),PX(%1000100),PX(%1000100),PX(%0111110),PX(%0010010),PX(%0010001),PX(%1110000)
        .byte   PX(%1000111),PX(%1000100),PX(%1000100),PX(%1000000),PX(%0010010),PX(%0011110),PX(%0010000)
        .byte   PX(%1000000),PX(%0000100),PX(%1000100),PX(%1000000),PX(%0010010),PX(%0000000),PX(%0010000)
        .byte   PX(%0111111),PX(%1111100),PX(%1111100),PX(%1111111),PX(%1100001),PX(%1111111),PX(%1100000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%1110010),PX(%1100010),PX(%1110010),PX(%0100000),PX(%1001010),PX(%1110010),PX(%1110000)
        .byte   PX(%1001010),PX(%1001010),PX(%0100111),PX(%0100001),PX(%1101010),PX(%1001010),PX(%1010000)
        .byte   PX(%1110010),PX(%1111010),PX(%0100101),PX(%0111001),PX(%0101110),PX(%1110010),PX(%1110000)

.params logo_bitmap_params
        DEFINE_POINT viewloc, kCol5-3, kRow1
mapbits:        .addr   logo_bitmap
mapwidth:       .byte   7
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 44, 17
.endparams

;;; ============================================================

str_track:
        PASCAL_STRING "Track: "
str_track_num:
        PASCAL_STRING "##  "
        DEFINE_POINT pos_track, kCol1 + 20, kRow1 + 13

str_time:
        PASCAL_STRING "##:##  "
        DEFINE_POINT pos_time, kCol4-8, kRow1 + 13

;;; ============================================================

        .include        "../lib/event_params.s"

.params trackgoaway_params
clicked:        .byte   0
.endparams

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort

;;; ============================================================

.proc Init
        JUMP_TABLE_MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        JUMP_TABLE_MGTK_CALL MGTK::FlushEvents
        rts
.endproc

.proc Exit
        JUMP_TABLE_MGTK_CALL MGTK::CloseWindow, winfo
        jmp     JUMP_TABLE_CLEAR_UPDATES
.endproc

;;; ============================================================

.proc CopyEventDataToMain
        copy16  #event_params, STARTLO
        copy16  #event_params+10, ENDLO
        copy16  #event_params, DESTINATIONLO
        clc                     ; aux>main
        jsr     AUXMOVE
        rts
.endproc

.proc CopyEventDataToAux
        copy16  #event_params, STARTLO
        copy16  #event_params+10, ENDLO
        copy16  #event_params, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
        rts
.endproc

;;; ============================================================
;;; Handle `EventKind::button_down`.
;;; Output: N=1 if event was not a button click
;;;         N=0 if event was a button click; in this case,
;;;         `event_params::key` and `event_params::modifier` will
;;;         be set to the keyboard equivalent.

.proc HandleDown
        JUMP_TABLE_MGTK_CALL MGTK::FindWindow, findwindow_params
        jsr     CopyEventDataToMain

        lda     findwindow_params::window_id
        cmp     winfo::window_id
        bne     ret

        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        beq     HandleDrag
        cmp     #MGTK::Area::content
        beq     HandleClick

ret:    lda     #$FF            ; not a button
        rts
.endproc

;;; ============================================================

.proc HandleClose
        JUMP_TABLE_MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        jsr     CopyEventDataToMain

        lda     trackgoaway_params::clicked
    IF_NE
        pla                     ; not returning to the caller
        pla
        jmp     Exit
    END_IF

        lda     #$FF            ; not a button
        rts
.endproc

;;; ============================================================

.proc HandleDrag
        copy    winfo::window_id, dragwindow_params::window_id
        jsr     CopyEventDataToAux
        JUMP_TABLE_MGTK_CALL MGTK::DragWindow, dragwindow_params
        jsr     CopyEventDataToMain
        bit     dragwindow_params::moved
        bpl     skip

        ;; Draw DeskTop's windows and icons.
        jsr     JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow

skip:   lda     #$FF            ; not a button
        rts
.endproc

;;; ============================================================

.proc HandleClick
        copy    winfo::window_id, screentowindow_params::window_id
        jsr     CopyEventDataToAux
        JUMP_TABLE_MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        JUMP_TABLE_MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; ----------------------------------------

        copy    #0, event_params::modifiers

        JUMP_TABLE_MGTK_CALL MGTK::InRect, play_button_rect
    IF_NOT_ZERO
        lda     #'P'
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, stop_button_rect
    IF_NOT_ZERO
        lda     #'S'
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, pause_button_rect
    IF_NOT_ZERO
        lda     #' '
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, eject_button_rect
    IF_NOT_ZERO
        lda     #'E'
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, loop_button_rect
    IF_NOT_ZERO
        lda     #'L'
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, shuffle_button_rect
    IF_NOT_ZERO
        lda     #'R'
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, prev_button_rect
    IF_NOT_ZERO
        lda     #CHAR_LEFT
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, next_button_rect
    IF_NOT_ZERO
        lda     #CHAR_RIGHT
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, back_button_rect
    IF_NOT_ZERO
        copy    #1, event_params::modifiers
        lda     #CHAR_LEFT
        bne     set_key         ; always
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::InRect, fwd_button_rect
    IF_NOT_ZERO
        copy    #1, event_params::modifiers
        lda     #CHAR_RIGHT
        bne     set_key         ; always
    END_IF

        lda     #$FF            ; not a button
        rts

set_key:
        sta     event_params::key
        rts
.endproc


;;; ============================================================

.proc DrawWindow
        ;; Defer if content area is not visible
        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
    IF_EQ
        rts
    END_IF

        JUMP_TABLE_MGTK_CALL MGTK::SetPort, grafport
        JUMP_TABLE_MGTK_CALL MGTK::HideCursor

        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, notpencopy
        JUMP_TABLE_MGTK_CALL MGTK::PaintRect, winfo::maprect

        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, pencopy
        JUMP_TABLE_MGTK_CALL MGTK::FrameRect, display_rect

        ;; --------------------------------------------------

        jsr     DrawTrack
        jsr     DrawTime

        ;; --------------------------------------------------

        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, penXOR

.macro DRAW_CD_BUTTON name, flag
        JUMP_TABLE_MGTK_CALL MGTK::FrameRect, .ident(.sprintf("%s_button_rect", .string(name)))
        JUMP_TABLE_MGTK_CALL MGTK::PaintBits, .ident(.sprintf("%s_bitmap_params", .string(name)))
  .if .paramcount > 1
        bit     .ident(.sprintf("cdremote__%s", .string(flag)))
    IF_NS
        param_call InvertButton, .ident(.sprintf("%s_button_rect", .string(name)))
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

        JUMP_TABLE_MGTK_CALL MGTK::PaintBits, logo_bitmap_params

        ;; --------------------------------------------------

        JUMP_TABLE_MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

;;; Caller is responsible for setting port.
.proc DrawTrack
        JUMP_TABLE_MGTK_CALL MGTK::MoveTo, pos_track
        param_call DrawString, str_track
        param_jump DrawString, str_track_num
.endproc

;;; Caller is responsible for setting port.
.proc DrawTime
        JUMP_TABLE_MGTK_CALL MGTK::MoveTo, pos_time
        param_jump DrawString, str_time
.endproc

;;; ============================================================
;;; Copies string main>aux before drawing
;;; Input: A,X = address of length-prefixed string

.proc DrawString
        params  := $06
        textptr := $06
        textlen := $08

        stax    textptr
        ldy     #0
        lda     (textptr),y
        beq     done
        sta     textlen
        inc16   textptr

        copy16  textptr, STARTLO
        copy16  textptr, DESTINATIONLO
        add16_8 textptr, textlen, ENDLO
        sec                     ; main>aux
        jsr     AUXMOVE

        JUMP_TABLE_MGTK_CALL MGTK::DrawText, params
done:   rts
.endproc

;;; ============================================================
;;; Inputs: A,X = rect address
;;; Assert: Called from Main
;;; Trashes: $06/$07

.proc InvertButton
        ptr := $06
        stax    ptr

        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        beq     ret
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, grafport

        ;; Run from Aux
        sta     RAMRDON
        sta     RAMWRTON

        ;; Copy rectangle
        ldy     #.sizeof(MGTK::Rect)-1
:       copy    (ptr),y, rect,y
        dey
        bpl     :-

        ;; Deflate
        inc16   rect+MGTK::Rect::x1
        inc16   rect+MGTK::Rect::y1
        dec16   rect+MGTK::Rect::x2
        dec16   rect+MGTK::Rect::y2

        ;; Back to Main
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ;; Invert it
        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, penXOR
        JUMP_TABLE_MGTK_CALL MGTK::PaintRect, rect
ret:    rts

rect:   .tag    MGTK::Rect

.endproc


;;; ============================================================

.scope cdremote


ZP1                 := $19
ZP2                 := $1B
ZP3                 := $1D
PlayedListPtr       := $1F

MAIN:                           ; "Null" out T/M/S values
        lda     #$aa
        sta     BCDRelTrack
        sta     BCDRelMinutes
        sta     BCDRelSeconds

                                ; Locate an Apple SCSI card and CDSC/CDSC+ drive
        jsr     FindHardware
.if !FAKE_HARDWARE
        IF_CS
        lda     #ERR_DEVICE_NOT_CONNECTED
        jmp     JUMP_TABLE_SHOW_ALERT
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
        beq     IDDPlaying
        sec
        sbc     #1
        ;; Audio status = $01 (currently paused)
        beq     IDDPaused
        ;; Audio status = anything else - stop operation explicitly
        jsr     DoStopAction
        jmp     ExitInitDriveDisc

        ;; Set Pause button to active
IDDPaused:
        dec     PauseButtonState
        jsr     ToggleUIPauseButton
        ;; Read the current disc position and update the Track and Time display
        jsr     C28ReadQSubcode
        jsr     DrawTrack
        jsr     DrawTime

        ;; Set Play button to active
IDDPlaying:
        dec     PlayButtonState
        ;; Set drive playing flag to true
        dec     DrivePlayingFlag
        jsr     ToggleUIPlayButton
        jmp     ExitInitDriveDisc
ExitInitDriveDisc:
        rts
.endproc

;;; ============================================================

        ;; This is the start of where all the real action takes place
.proc MainLoop
        lda     TOCInvalidFlag
        ;; Have we read in a valid, usable TOC from an audio CD?
        beq     TOCisValid

        ;; We don't have a valid TOC - poll the drive to see if it's online so we can try to read a TOC
        jsr     StatusDrive
        ;; No - drive is offline, go check for user input instead
        bcs     NoFurtherBGAction
        ;; Yes - make another attempt at reading a TOC
        jsr     ReReadTOC

        ;; Re-check the status of the drive
TOCisValid:
        jsr     StatusDrive
        lda     DrivePlayingFlag
        ;; Drive is not currently playing audio, go check for user input
        beq     NoFurtherBGAction

        ;; Drive is playing audio, watch for an AudioStatus return code of $03 = "Play operation complete"
        jsr     C24AudioStatus
        lda     SPBuffer
        cmp     #$03
        ;; Audio playback operation is not complete
        bne     StillPlaying

        ;; Deal with reaching the end of a playback operation.  It's complicated.  :)
        jsr     PlayBackComplete

        ;; Go read the QSubcode channel and update the Track & Time display
StillPlaying:
        jsr     C28ReadQSubcode
        bcs     NoFurtherBGAction
        jsr     DrawTrack
        jsr     DrawTime

        ;; Read and process any Keyboard inputs from the user
NoFurtherBGAction:
        jsr     JUMP_TABLE_YIELD_LOOP
        JUMP_TABLE_MGTK_CALL MGTK::GetEvent, event_params
        jsr     CopyEventDataToMain

        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
    IF_EQ
        jsr     ::HandleDown
        bpl     HandleKey       ; was a button, mapped to key event
        jmp     MainLoop
    END_IF
        cmp     #MGTK::EventKind::key_down
        bne     MainLoop

HandleKey:
        lda     event_params::key

        ;; Map lowercase to uppercase
        cmp     #'a'
        bcc     :+
        cmp     #'z'
        bcs     :+
        and     #CASE_MASK
:

        ;; $51 = Q (Quit)
        cmp     #$51
        bne     NotQ
        jmp     DoQuitAction

        ;; $1B = ESC (Quit)
NotQ:   cmp     #$1b
        bne     NotESC
        jmp     DoQuitAction

        ;; $4C = L (Continuous Play)
NotESC: cmp     #$4c
        bne     NotL
        jsr     ToggleLoopMode
        jmp     MainLoop

        ;; $52 = R (Random Play)
NotL:   cmp     #$52
        bne     NotR
        jsr     ToggleRandomMode
        jmp     MainLoop

        ;; All other key operations (Play/Stop/Pause/Next/Prev/Eject) require an online drive/disc, so check one more time
NotR:   jsr     StatusDrive
        jcs     MainLoop

        ;; Loop falls through to here only if the drive is online
        pha
        lda     TOCInvalidFlag
        ;; Valid TOC has been read, we can skip the re-read
        beq     SkipTOCRead
        jsr     ReReadTOC
SkipTOCRead:
        pla

        ;; $50 = P (Play)
        cmp     #$50
        bne     NotP
        jsr     DoPlayAction
        jmp     MainLoop

        ;; $53 = S (Stop)
NotP:   cmp     #$53
        bne     NotS
        jsr     DoStopAction
        jmp     MainLoop

        ;; $20 = Space (Pause)
NotS:   cmp     #$20
        bne     NotSpace
        jsr     DoPauseAction
        jmp     MainLoop

        ;; $08 = ^H, LA (Previous Track, Scan Backward)
NotSpace:
        cmp     #$08
        bne     NotCtrlH
        lda     event_params::modifiers
        beq     JustLeftArrow
OA_LeftArrow:
        jsr     DoScanBackAction
        jmp     MainLoop

JustLeftArrow:
        jsr     DoPrevTrackAction
        jmp     MainLoop

        ;; $15 = ^U, RA (Next Track/Scan Forward)
NotCtrlH:
        cmp     #$15
        bne     NotCtrlU
        lda     event_params::modifiers
        beq     JustRightArrow
OA_RightArrow:
        jsr     DoScanFwdAction
        jmp     MainLoop

JustRightArrow:
        jsr     DoNextTrackAction
        jmp     MainLoop

        ;; $45 = E (Eject)
NotCtrlU:
        cmp     #$45
        bne     UnsupportedKeypress
        jsr     C26Eject
UnsupportedKeypress:
        jmp     MainLoop
.endproc

;;; ============================================================

.proc DoQuitAction
                    rts
.endproc

;;; ============================================================

.proc PlayBackComplete
        lda     RandomButtonState
        ;; Random button is inactive - the entire Disc has been played to the end
        beq     PBCRandomIsInactive

        ;; Random button is active - handle rollover to next random track
        lda     PlayButtonState
        ;; Play button is inactive - bail out, there's nothing to do
        beq     ExitPBCHandler

        ;; Increment the count of how many tracks have been played
        inc     HexPlayedCount0Base
        lda     HexPlayedCount0Base
        cmp     HexTrackCount0Base
        ;; Haven't played all the tracks on the disc, so pick another one
        bne     PBCPlayARandomTrack

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
        bne     PBCPlayARandomTrack

        ;; Loop button is inactive - reset the first/last/current values to the TOC values and stop
        lda     BCDFirstTrackTOC
        sta     BCDFirstTrackNow
        sta     BCDRelTrack
        lda     BCDLastTrackTOC
        sta     BCDLastTrackNow
        jsr     DoStopAction
        jmp     ExitPBCHandler

PBCPlayARandomTrack:
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
        jmp     ExitPBCHandler

        ;; Entire disc has been played to the end, do we need to loop?
PBCRandomIsInactive:
        lda     LoopButtonState
        ;; Loop Button is inactive - so we just stop
        beq     PBCLoopIsInactive

        ;; Loop button is active - reset stop point to EoT LastTrack
        jsr     C23AudioStop
        lda     PlayButtonState
        ;; Play button is inactive - bail out, there's nothing to do
        beq     ExitPBCHandler

        ;; Make sure we start fresh from the first track on the disc
        lda     BCDFirstTrackTOC
        sta     BCDFirstTrackNow
        ;; Set flag to MSF mode, because we're not in random mode
        dec     TrackOrMSFFlag
        ;; Call AudioPlay function and exit
        jsr     C21AudioPlay
        jmp     ExitPBCHandler

        ;; Stop, because Loop is inactive
PBCLoopIsInactive:
        lda     PlayButtonState
        ;; Play button is inactive (already) - bail out, there's nothing to do
        beq     ExitPBCHandler

        ;; Use the existing StopAction to stop everything
        jsr     DoStopAction

ExitPBCHandler:
        rts
.endproc

;;; ============================================================

.proc StatusDrive
        pha
        ;; Try three times for a good status return
        lda     #$03
        sta     RetryCount

        ;; $00 = Status
RetryLoop:
        lda     #$00
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
.endproc

;;; ============================================================

        ;; EXCEPTION - Explicitly stop the CD drive, forcibly clear the Play/Pause buttons, forcibly set the Stop button, and wipe the Track/Time display clean
.proc HardShutdown
        jsr     DoStopAction
        lda     PauseButtonState
        ;; Pause button is inactive (already) - nothing to do
        beq     NoPauseButtonChange

        ;; Clear Pause button to inactive
        lda     #$00
        sta     PauseButtonState
        jsr     ToggleUIPauseButton

NoPauseButtonChange:
        lda     PlayButtonState
        ;; Play button is inactive (already) - nothing to do
        beq     NoPlayButtonChange

        ;; Clear Play button to inactive
        lda     #$00
        sta     PlayButtonState
        jsr     ToggleUIPlayButton

NoPlayButtonChange:
        lda     StopButtonState
        ;; Stop button is active (already) - nothing to do
        bne     ClearTrackAndTime

        ;; Set Stop button to active
        lda     #$ff
        sta     StopButtonState
        jsr     ToggleUIStopButton

        ;; "Null" out T/M/S values and blank Track & Time display
ClearTrackAndTime:
        lda     #$aa
        sta     BCDRelTrack
        sta     BCDRelMinutes
        sta     BCDRelSeconds

        jsr     DrawTrack
        jsr     DrawTime

        rts
.endproc

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
.endproc

;;; ============================================================

;;; Returns N=0 if the gesture has ended, N=1 otherwise
;;; * If the last event was `MGTK::EventKind::key_down`, assume it has ended
;;; * Otherwise, sample until `MGTK::EventKind::button_up`

.proc CheckGestureEnded
        lda     event_params::kind
        cmp     #MGTK::EventKind::key_down
        beq     ended

        JUMP_TABLE_MGTK_CALL MGTK::GetEvent, event_params
        jsr     CopyEventDataToMain
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_up
        beq     ended

        lda     #$FF            ; N=1
        rts

ended:  lda     #$00            ; N=0
        rts
.endproc

;;; ============================================================

.proc DoPlayAction
        lda     PauseButtonState
        ;; Pause button is inactive - nothing to do yet
        beq     DPAPauseIsInactive

        ;; Pause button is active - forcibly clear it to inactive and then...
        lda     #$00
        sta     PauseButtonState
        jsr     ToggleUIPauseButton
        ;; call AudioPause to release Pause (resume playing) and exit
        jsr     C22AudioPause
        jmp     ExitPlayAction

DPAPauseIsInactive:
        lda     PlayButtonState
        ;; Play button is active (already) - bail out, there's nothing to do
        bne     ExitPlayAction

        ;; Play button is inactive, we're starting from scratch - before activating, check the random mode
        lda     RandomButtonState
        ;; Random button is inactive - just update the UI buttons and start playback
        beq     DPARandomIsInactive

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

        ;; Set Play button to active
DPARandomIsInactive:
        dec     PlayButtonState
        jsr     ToggleUIPlayButton

        lda     StopButtonState
        ;; Stop button is inactive (already) - just start the playback and exit
        beq     DPAStopIsInactive

        ;; Set Stop button to inactive, then start the playback and exit
        lda     #$00
        sta     StopButtonState
        jsr     ToggleUIStopButton

DPAStopIsInactive:
        jsr     C21AudioPlay
ExitPlayAction:
        rts
.endproc

;;; ============================================================

.proc DoStopAction
        lda     StopButtonState
        ;; Stop button is active (already) - bail out, there's nothing to do
        bne     ExitStopAction

        ;; Reset First/Last to TOC values
        lda     BCDFirstTrackTOC
        sta     BCDFirstTrackNow
        lda     BCDLastTrackTOC
        sta     BCDLastTrackNow

        lda     PlayButtonState
        ;; Play button is inactive (already) - nothing to do
        beq     DSAPlayIsInactive

        ;; Clear Play button to inactive
        lda     #$00
        sta     PlayButtonState
        jsr     ToggleUIPlayButton

DSAPlayIsInactive:
        lda     PauseButtonState
        ;; Pause button is inactive (already) - nothing to do
        beq     DSAPauseIsInactive

        ;; Clear Pause button to inactive
        lda     #$00
        sta     PauseButtonState
        jsr     ToggleUIPauseButton

        ;; Set Stop button to active
DSAPauseIsInactive:
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

ExitStopAction:
        rts
.endproc

;;; ============================================================

.proc DoPauseAction
        lda     StopButtonState
        ;; Stop button is active - bail out, there's nothing to do
        bne     ExitPauseAction

        ;; Toggle Pause button
        lda     #$ff
        eor     PauseButtonState
        sta     PauseButtonState
        jsr     ToggleUIPauseButton

        ;; Execute pause action (pause or resume) based on new button state
        jsr     C22AudioPause

ExitPauseAction:
        rts
.endproc

;;; ============================================================

.proc ToggleLoopMode
        lda     #$ff
        eor     LoopButtonState
        sta     LoopButtonState
        jsr     ToggleUILoopButton
        rts
.endproc

;;; ============================================================

.proc ToggleRandomMode
        lda     #$ff
        eor     RandomButtonState
        sta     RandomButtonState
        beq     TRMRandomIsInactive

        ;; Random button is now active - re-initialize random mode and exit
        jsr     RandomModeInit
        jmp     TRMUpdateButton

        ;; Random button is now inactive - reset First/Last to TOC values and update stop point to EoT last Track
TRMRandomIsInactive:
        lda     BCDLastTrackTOC
        sta     BCDLastTrackNow
        lda     BCDFirstTrackTOC
        sta     BCDFirstTrackNow
        jsr     SetStopToEoBCDLTN

        ;; Update UI, wait for key release, and exit
TRMUpdateButton:
        jsr     ToggleUIRandButton
        rts
.endproc

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
.endproc

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
DSBALoop:
        jsr     C28ReadQSubcode
        bcs     DSBAQSubReadErr
        jsr     DrawTrack
        jsr     DrawTime

        ;; Keep scanning as long as the key is held down
DSBAQSubReadErr:
        jsr     CheckGestureEnded
        bmi     DSBALoop

        ;; Key released - dim the Scan Back button, and resume playing from where we are
        jsr     ToggleUIScanBackButton
        jsr     C22AudioPause
ExitScanBackAction:
        rts
.endproc

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
DSFALoop:
        jsr     C28ReadQSubcode
        bcs     DSFAQSubReadErr
        jsr     DrawTrack
        jsr     DrawTime

        ;; Keep scanning as long as the key is held down
DSFAQSubReadErr:
        jsr     CheckGestureEnded
        bmi     DSFALoop

        ;; Key released - dim the Scan Forward button, and resume playing from where we are
        jsr     ToggleUIScanFwdButton
        jsr     C22AudioPause
ExitScanFwdAction:
        rts
.endproc

;;; ============================================================

.proc DoPrevTrackAction
        jsr     ToggleUIPrevButton

        ;; Reset to start of track
        lda     #$00
        sta     BCDRelMinutes
        sta     BCDRelSeconds
        jsr     DrawTime

DPTAWrapCheck:
        lda     BCDRelTrack
        cmp     BCDFirstTrackTOC
        ;; If we're not at the "first" track, just decrement track #
        bne     DPTAJustPrev

        ;; Otherwise, wrap to the "last" track instead
        lda     BCDLastTrackTOC
        sta     BCDRelTrack
        jmp     DPTACheckRandom

        ;; BCD decrement
DPTAJustPrev:
        sed
        lda     BCDRelTrack
        sbc     #$01
        sta     BCDRelTrack
        cld

DPTACheckRandom:
        lda     RandomButtonState
        ;; Random button is inactive - just execute playback
        beq     DPTARandomInactive

        ;; Random button is active - set the current Track as First/Last/Picked, and set the proper random Stop mode
        lda     BCDRelTrack
        sta     BCDFirstTrackNow
        sta     BCDLastTrackNow
        sta     BCDRandomPickedTrk
        jsr     SetStopToEoBCDLTN

        ;; Seek to new Track and update Track display
DPTARandomInactive:
        jsr     C20AudioSearch
        jsr     DrawTrack

        lda     #$FF            ; TODO: Does this need to be a word?
        sta     DPTACounter
DPTAHeldKeyCheck:
        jsr     CheckGestureEnded
        bpl     DPTAKeyReleased
        dec     DPTACounter
        beq     DPTAWrapCheck   ; Repeat the action
        bne     DPTAHeldKeyCheck ; always

DPTAKeyReleased:
        jsr     ToggleUIPrevButton
        rts

DPTACounter:
        .byte   0
.endproc

;;; ============================================================

.proc DoNextTrackAction
        jsr     ToggleUINextButton

        ;; Reset to start of track
        lda     #$00
        sta     BCDRelMinutes
        sta     BCDRelSeconds
        jsr     DrawTime

DNTAWrapCheck:
        lda     BCDRelTrack
        cmp     BCDLastTrackTOC
        ;; If we're not at the "last" track, just increment track #
        bne     DNTAJustNext

        ;; Otherwise, wrap to the "first" track instead
        lda     BCDFirstTrackTOC
        sta     BCDRelTrack
        jmp     DNTACheckRandom

        ;; BCD increment
DNTAJustNext:
        sed
        lda     BCDRelTrack
        adc     #$01
        sta     BCDRelTrack
        cld

DNTACheckRandom:
        lda     RandomButtonState
        ;; Random button is inactive - just execute playback
        beq     DNTARandomInactive

        ;; Random button is active - set the current Track as First/Last/Picked, and set the proper random Stop mode
        lda     BCDRelTrack
        sta     BCDFirstTrackNow
        sta     BCDLastTrackNow
        sta     BCDRandomPickedTrk
        jsr     SetStopToEoBCDLTN

        ;; Seek to new Track and update Track display
DNTARandomInactive:
        jsr     C20AudioSearch
        jsr     DrawTrack

        lda     #$FF            ; TODO: Does this need to be a word?
        sta     DNTACounter
DNTAHeldKeyCheck:
        jsr     CheckGestureEnded
        bpl     DNTAKeyReleased
        dec     DNTACounter
        beq     DNTAWrapCheck   ; Repeat the action
        bne     DNTAHeldKeyCheck ; always

DNTAKeyReleased:
        jsr     ToggleUINextButton
        rts

DNTACounter:
        .byte   0
.endproc

;;; ============================================================

.proc C26Eject
        jsr     ToggleUIEjectButton

        ;; $26 = Eject
        lda     #$26
        sta     SPCode
        ;; $04 = Control
        lda     #$04
        sta     SPCommandType
        jsr     SPCallVector

        jsr     ToggleUIEjectButton

        lda     StopButtonState
        ;; Stop button is active - just go wipe the Track & Time display and clear the TOC
        bne     ClearTrackTime_TOC

        lda     PauseButtonState
        ;; Pause button is inactive (already) - nothing to do
        beq     EjPauseIsInactive

        ;; Clear Pause button to inactive
        lda     #$00
        sta     PauseButtonState
        jsr     ToggleUIPauseButton

EjPauseIsInactive:
        lda     PlayButtonState
        ;; Play button is inactive (already) - nothing to do
        beq     EjPlayIsInactive

        ;; Clear Play button to inactive
        lda     #$00
        sta     PlayButtonState
        jsr     ToggleUIPlayButton

        ;; Clear Drive Playing state
EjPlayIsInactive:
        lda     #$00
        sta     DrivePlayingFlag

        ;; Set Stop button to active
        sec
        sbc     #1
        sta     StopButtonState
        jsr     ToggleUIStopButton

        ;; "Null" out T/M/S, blank Track & Time display, and invalidate the TOC
ClearTrackTime_TOC:
        lda     #$aa
        sta     BCDRelTrack
        sta     BCDRelMinutes
        sta     BCDRelSeconds

        jsr     DrawTrack
        jsr     DrawTime

        lda     #$ff
        sta     TOCInvalidFlag

        rts
.endproc

;;; ============================================================

.proc C21AudioPlay
        lda     #$ff
        sta     DrivePlayingFlag
        ;; $04 = Control
        lda     #$04
        sta     SPCommandType
        ;; $21 = AudioPlay
        lda     #$21
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
        beq     APStopAtMSF

        ;; Use end of currently-selected Track as "stop" point for random mode
APStopAtTrack:
        lda     BCDFirstTrackNow
        sta     SPBuffer + 2
        ;; Address Type = $02 (Track)
        lda     #$02
        sta     SPBuffer + 6
        lda     #$00
        sta     TrackOrMSFFlag
        beq     CallAudioPlay   ; always

APStopAtMSF:
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
.endproc

;;; ============================================================


.proc C20AudioSearch
        ;; $04 = Control
        lda     #$04
        sta     SPCommandType
        lda     #$20
        sta     SPCode
        jsr     ZeroOutSPBuffer

        lda     PlayButtonState
        ;; Play button is inactive - seek and hold
        beq     ASHoldAfterSearch

        ;; Play button is active - seek and play
ASPlayAfterSearch:
        lda     #$ff
        ;; Set the Drive Playing flag to active
        sta     DrivePlayingFlag

        ;; $01 = Play after search
        lda     #$01
        bne     ASExecuteSearch ; always

        ;; $00 = Hold after search
ASHoldAfterSearch:
        lda     #$00
ASExecuteSearch:
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

ASSkipDeadCode:
        lda     PauseButtonState
        ;; Pause button is inactive (already) - nothing to do
        beq     ASPauseIsInactive

        ;; Clear Pause button to inactive
        inc     PauseButtonState
        jsr     ToggleUIPauseButton

ASPauseIsInactive:
        lda     BCDRelTrack
        sta     BCDFirstTrackNow
        rts
.endproc

;;; ============================================================

.proc C24AudioStatus
        ;; $04 = Control
        lda     #$04
        sta     SPCommandType
        ;; $24 = Audio Status
        lda     #$24
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
.endproc

;;; ============================================================

.proc C27ReadTOC
        ;; $04 = Control
        lda     #$04
        sta     SPCommandType
        ;; $27 = ReadTOC
        lda     #$27
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
.endproc

;;; ============================================================

.proc C28ReadQSubcode
        ;; $04 = Control
        lda     #$04
        sta     SPCommandType
        ;; $28 = ReadQSubcode
        lda     #$28
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

        ;; TODO: Analysis - What do these returned values actually represent?  Are the variable names being used here appropriate?
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
        ;; TODO: Analysis - Is this value perhaps the Track Index?  Does Index 0 (gap/transition) get treated as a QSub read error?
        beq     ReadQSubcodeFail

        ;; Clear carry on success
        clc
        bcc     ExitReadQSubcode ; always

        ;; Set carry on failure
ReadQSubcodeFail:
        sec
ExitReadQSubcode:
        rts
.endproc

;;; ============================================================

.proc C23AudioStop
        lda     #$00
        sta     DrivePlayingFlag

        ;; $04 = Control
        lda     #$04
        sta     SPCommandType
        ;; $23 = AudioStop
        lda     #$23
        sta     SPCode
        ;; Address type = $00 (Block), Block = 0
        jsr     ZeroOutSPBuffer
        ;; TODO: Analysis - What does an all-zeroes AudioStop call actually do?  Just clear any existing set stop point?  Explicitly stop playback now?  Something else?
        jsr     SPCallVector
        FALL_THROUGH_TO SetStopToEoBCDLTN
.endproc

;;; ============================================================

.proc SetStopToEoBCDLTN
        ;; $04 = Control
        lda     #$04
        sta     SPCommandType
        ;; $23 = AudioStop
        lda     #$23
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
.endproc

;;; ============================================================

.proc C22AudioPause
        ;; $04 = Control
        lda     #$04
        sta     SPCommandType
        ;; $22 = AudoPause
        lda     #$22
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
.endproc

;;; ============================================================

.proc C25AudioScanFwd
        ;; $25 = AudioScan
        lda     #$25
        sta     SPCode
        ;; $04 = Control
        lda     #$04
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
.endproc

;;; ============================================================

.proc C25AudioScanBack
        ;; $04 = Control
        lda     #$04
        sta     SPCommandType
        ;; $25 = AudioScan
        lda     #$25
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
.endproc

;;; ============================================================

.proc ZeroOutSPBuffer
        lda     #$00
        ldx     #$0e
SPZeroLoop:
        sta     SPBuffer,x
        dex
        bpl     SPZeroLoop
        rts
.endproc

;;; ============================================================

.proc FindHardware
        ;; Save state
        jsr     FindSCSICard
        bcs     ExitFindHardware
        jsr     SmartPortCallSetup
        jsr     FindCDROM
ExitFindHardware:
        rts

FindSCSICard:
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


        ;; $00 = Status
FindCDROM:
        lda     #$00
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


SmartPortCallSetup:
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
.endproc

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

        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
    IF_NE
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, grafport
        jsr     ::DrawTrack
    END_IF

        pla
        tay
        pla
        tax
skip:
        pla
        rts
.endproc

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

        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
    IF_NE
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, grafport
        jsr     ::DrawTime
    END_IF

        pla
        tay
        pla
        tax
skip:
        pla
        rts
.endproc

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
        cmp     #10             ; stuffed with $AA to blank
        bcs     :+
        ora     #'0'
        rts
:       lda     #' '
        rts
.endproc

.proc LowBCDDigitToASCII
        and     #$0F
        cmp     #10             ; stuffed with $AA to blank
        bcs     :+
        ora     #'0'
        rts
:       lda     #' '
        rts
.endproc

;;; ============================================================

ToggleUIStopButton:
        param_jump      ::InvertButton, stop_button_rect

ToggleUIPlayButton:
        param_jump      ::InvertButton, play_button_rect

ToggleUIEjectButton:
        param_jump      ::InvertButton, eject_button_rect

ToggleUIPauseButton:
        param_jump      ::InvertButton, pause_button_rect

ToggleUINextButton:
        param_jump      ::InvertButton, next_button_rect

ToggleUIPrevButton:
        param_jump      ::InvertButton, prev_button_rect

ToggleUIScanBackButton:
        param_jump      ::InvertButton, back_button_rect

ToggleUIScanFwdButton:
        param_jump      ::InvertButton, fwd_button_rect

ToggleUILoopButton:
        param_jump      ::InvertButton, loop_button_rect

ToggleUIRandButton:
        param_jump      ::InvertButton, shuffle_button_rect

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
.endproc

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
.endproc

;;; ============================================================

        ;; This just zeroes all 99 elements in the Played List
.proc ClearPlayedList
        lda     #$00
        ldy     #$63

CPLLoop:
        sta     (PlayedListPtr),y
        dey
        bpl     CPLLoop

        rts
.endproc

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
.endproc

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
.endproc

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

.endscope

;;; Exports
cdremote__MAIN  := cdremote::MAIN
cdremote__StopButtonState       := cdremote::StopButtonState
cdremote__PlayButtonState       := cdremote::PlayButtonState
cdremote__PauseButtonState      := cdremote::PauseButtonState
cdremote__LoopButtonState       := cdremote::LoopButtonState
cdremote__RandomButtonState     := cdremote::RandomButtonState

;;; ============================================================

da_end  := *
        .assert * < WINDOW_ENTRY_TABLES, error, .sprintf("DA too big (at $%X)", *)
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00

;;; ============================================================
