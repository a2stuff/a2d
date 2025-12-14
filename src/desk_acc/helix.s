;;; ============================================================
;;; HELIX - Desk Accessory
;;;
;;; Clears the screen and animates a pleasing distraction.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

.proc AuxStart
        ;; Run the DA
        jmp     Init
.endproc ; AuxStart

;;; ============================================================
;;; Animation Resources

deltax1: .word   0
deltay1: .word   0
deltax2: .word   0
deltay2: .word   0

kNumPoints = 16
cur_point:
        .byte   0

x1pos:   .res    kNumPoints * 2
y1pos:   .res    kNumPoints * 2
x2pos:   .res    kNumPoints * 2
y2pos:   .res    kNumPoints * 2

;;; ============================================================
;;; Graphics Resources

event_params:   .tag MGTK::Event

notpencopy:     .byte   MGTK::notpencopy
pencopy:        .byte   MGTK::pencopy

grafport:       .tag MGTK::GrafPort

;;; ============================================================
;;; DA Init

.proc Init
        jsr     InitRand

        ;; Initialize positions (x = 0...511, y = 0...127)
        jsr     Random
        sta     x1pos           ; low 8 bits
        jsr     Random
        and     #%00000001
        sta     x1pos+1         ; high 8 bits

        jsr     Random
        sta     x2pos           ; low 8 bits
        jsr     Random
        and     #%00000001
        sta     x2pos+1         ; high 8 bits

        jsr     Random
        and     #%01111111
        sta     y1pos

        jsr     Random
        and     #%01111111
        sta     y2pos

        ;; Initialize deltas
        jsr     GetRandomDelta
        stax    deltax1
        jsr     GetRandomDelta
        stax    deltax2
        jsr     GetRandomDelta
        stax    deltay1
        jsr     GetRandomDelta
        stax    deltay2

        ;; Scale for more dramatic motion, and 2:1 x:y pixel ratio
        asl16   deltax1
        asl16   deltax1
        asl16   deltax2
        asl16   deltax2
        asl16   deltay1
        asl16   deltay2


        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintRect, grafport + MGTK::GrafPort::maprect

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

        jsr     Animate
        jmp     InputLoop

exit:
        MGTK_CALL MGTK::RedrawDeskTop

        MGTK_CALL MGTK::DrawMenuBar
        JSR_TO_MAIN JUMP_TABLE_HILITE_MENU

        MGTK_CALL MGTK::ShowCursor
        rts                     ; exits input loop
.endproc ; InputLoop

;;; ============================================================
;;; Animate

.proc Animate
        MGTK_CALL MGTK::SetPort, grafport

        pt1  := $06
        pt2  := $0A

        ;; --------------------------------------------------
        ;; Erase oldest

        ldx     cur_point
        inx
    IF X = #kNumPoints
        ldx     #0
    END_IF
        txa
        asl
        tax

        copy16  x1pos,x, pt1+MGTK::Point::xcoord
        copy16  y1pos,x, pt1+MGTK::Point::ycoord
        copy16  x2pos,x, pt2+MGTK::Point::xcoord
        copy16  y2pos,x, pt2+MGTK::Point::ycoord

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::MoveTo, pt1
        MGTK_CALL MGTK::LineTo, pt2

        lda     cur_point
        asl
        tax

        ;; --------------------------------------------------
        ;; Create newest

        add16   x1pos,x, deltax1, pt1+MGTK::Point::xcoord
        add16   y1pos,x, deltay1, pt1+MGTK::Point::ycoord
        scmp16   pt1+MGTK::Point::xcoord, #0
    IF NEG
        copy16  #0, pt1+MGTK::Point::xcoord
        sub16   #0, deltax1, deltax1
    END_IF
        scmp16   pt1+MGTK::Point::xcoord, #kScreenWidth
    IF POS
        copy16  #kScreenWidth-1, pt1+MGTK::Point::xcoord
        sub16   #0, deltax1, deltax1
    END_IF
        scmp16   pt1+MGTK::Point::ycoord, #0
    IF NEG
        copy16  #0, pt1+MGTK::Point::ycoord
        sub16   #0, deltay1, deltay1
    END_IF
        scmp16   pt1+MGTK::Point::ycoord, #kScreenHeight
    IF POS
        copy16  #kScreenHeight-1, pt1+MGTK::Point::ycoord
        sub16   #0, deltay1, deltay1
    END_IF

        add16   x2pos,x, deltax2, pt2+MGTK::Point::xcoord
        add16   y2pos,x, deltay2, pt2+MGTK::Point::ycoord
        scmp16   pt2+MGTK::Point::xcoord, #0
    IF NEG
        copy16  #0, pt2+MGTK::Point::xcoord
        sub16   #0, deltax2, deltax2
    END_IF
        scmp16   pt2+MGTK::Point::xcoord, #kScreenWidth
    IF POS
        copy16  #kScreenWidth-1, pt2+MGTK::Point::xcoord
        sub16   #0, deltax2, deltax2
    END_IF
        scmp16   pt2+MGTK::Point::ycoord, #0
    IF NEG
        copy16  #0, pt2+MGTK::Point::ycoord
        sub16   #0, deltay2, deltay2
    END_IF
        scmp16   pt2+MGTK::Point::ycoord, #kScreenHeight
    IF POS
        copy16  #kScreenHeight-1, pt2+MGTK::Point::ycoord
        sub16   #0, deltay2, deltay2
    END_IF

        ;; --------------------------------------------------
        ;; Replace oldest

        ldx     cur_point
        inx
    IF X = #kNumPoints
        ldx     #0
    END_IF
        stx     cur_point
        txa
        asl
        tax

        copy16  pt1+MGTK::Point::xcoord, x1pos,x
        copy16  pt1+MGTK::Point::ycoord, y1pos,x
        copy16  pt2+MGTK::Point::xcoord, x2pos,x
        copy16  pt2+MGTK::Point::ycoord, y2pos,x

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::MoveTo, pt1
        MGTK_CALL MGTK::LineTo, pt2

        rts

.endproc ; Animate

;;; ============================================================

        .include "../lib/prng.s"

;;; ============================================================

;;; Output: A,X = signed in -7...7 but not 0
.proc GetRandomDelta
        ldx     #0
    DO
        jsr     Random
        and     #%00001111      ; clamp to 0...15
        sec
        sbc     #8              ; map to -7...7
    WHILE ZERO                  ; retry if 0

    IF NEG
        ldx     #$FF            ; sign-extend into X
    END_IF

        rts
.endproc ; GetRandomDelta

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        jsr     JUMP_TABLE_COLOR_MODE
        JSR_TO_AUX aux::AuxStart
        jmp     JUMP_TABLE_RGB_MODE

        DA_END_MAIN_SEGMENT

;;; ============================================================
