;;; ============================================================
;;; ANALOG.CLOCK - Desk Accessory
;;;
;;; Clears the screen and shows the current time.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

;;; Copy of DATELO/HI and TIMELO/HI
datetime:
        .tag    DateTime

;;; Assert: Called from Aux
.proc GetDateTime
        JSR_TO_MAIN DoMLIGetTime

        copy16  #DATELO, STARTLO
        copy16  #DATELO+.sizeof(DateTime)-1, ENDLO
        copy16  #datetime, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=1  ; main>aux
.endproc ; GetDateTime

;;; ============================================================
;;; Graphics Resources

event_params:   .tag MGTK::Event

grafport:       .tag MGTK::GrafPort

notpencopy:     .byte   MGTK::notpencopy
pencopy:        .byte   MGTK::pencopy

pensize:        .byte   2, 1

        DEFINE_POINT pt1, 0, 0
        DEFINE_POINT pt2, 0, 0

        DEFINE_POINT pt_center, kScreenWidth/2, kScreenHeight/2
        DEFINE_POINT pt_m, 0, 0
        DEFINE_POINT pt_h, 0, 0

;;; ============================================================

parsed: .tag    ParsedDateTime

;;; ============================================================
;;; DA Init

.proc Init
        MGTK_CALL MGTK::ObscureCursor

        ;; Clear screen to black
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintRect, grafport + MGTK::GrafPort::maprect
        jsr     DrawTicks

        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
        jsr     MaybeUpdate

        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     exit
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     exit

        jmp     InputLoop

exit:
        MGTK_CALL MGTK::RedrawDeskTop

        MGTK_CALL MGTK::DrawMenuBar
        JSR_TO_MAIN JUMP_TABLE_HILITE_MENU

        rts                     ; exits input loop
.endproc ; InputLoop

;;; ============================================================

.proc DrawTicks
        ;; Set up for drawing
        MGTK_CALL MGTK::SetPenSize, pensize
        MGTK_CALL MGTK::SetPenMode, pencopy

        ;; Draw ticks
        lda     #0
        sta     tindex
        sta     tfives
    DO
        ldx     tindex
        txa
        asl
        tax

        copy16  ticks_outer_xs,x, pt1::xcoord
        copy16  ticks_outer_ys,x, pt1::ycoord

        lda     tfives
      IF ZERO
        copy16  ticks_inner2_xs,x, pt2::xcoord
        copy16  ticks_inner2_ys,x, pt2::ycoord
        copy8   #4, tfives
      ELSE
        copy16  ticks_inner1_xs,x, pt2::xcoord
        copy16  ticks_inner1_ys,x, pt2::ycoord
        dec     tfives
      END_IF

        MGTK_CALL MGTK::MoveTo, pt1
        MGTK_CALL MGTK::LineTo, pt2

    WHILE inc tindex : lda tindex : A <> #60

        rts

tindex: .byte   0
tfives: .byte   0
.endproc ; DrawTicks

;;; ============================================================
;;; Update

;;; Call `Update` if there's a change from last time
.proc MaybeUpdate
        jsr     GetDateTime

        ;; Compare
        ldx     #.sizeof(DateTime)-1
    DO
        lda     datetime,x
        cmp     last,x
        bne     diff
    WHILE dex : POS
        rts                     ; no change

        ;; Different! update
diff:   COPY_STRUCT DateTime, datetime, last
        jmp     Update

last:   .tag    DateTime
.endproc ; MaybeUpdate

.proc Update
        copy16  #parsed, $A
        CALL    ParseDatetime, AX=#datetime

        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenSize, pensize

        ;; Erase
        MGTK_CALL MGTK::SetPenMode, notpencopy
        jsr     draw

        ;; Update minute hand
        lda     parsed+ParsedDateTime::minute
        asl
        tax
        copy16  min_hand_xs,x, pt_m::xcoord
        copy16  min_hand_ys,x, pt_m::ycoord

        ;; Update hour hand
        ldx     parsed+ParsedDateTime::hour
        lda     hour_base,x
        ldx     parsed+ParsedDateTime::minute
        adc     min_offset,x
        asl
        tax
        copy16  hour_hand_xs,x, pt_h::xcoord
        copy16  hour_hand_ys,x, pt_h::ycoord

        ;; Draw
        MGTK_CALL MGTK::SetPenMode, pencopy
draw:   MGTK_CALL MGTK::MoveTo, pt_center
        MGTK_CALL MGTK::LineTo, pt_m
        MGTK_CALL MGTK::MoveTo, pt_center
        MGTK_CALL MGTK::LineTo, pt_h

        rts

.endproc ; Update

;;; ============================================================

ticks_outer_xs:
        .word   280,299,317,336,354,371,387,402,415,427,437,446,453,458,461,462,461,458,453,446,437,427,415,402,387,371,354,336,317,299,280,260,242,223,205,188,172,157,144,132,122,113,106,101,98,97,98,101,106,113,122,132,144,157,172,188,205,223,242,260
ticks_outer_ys:
        .word   4,5,6,9,12,17,22,28,34,42,50,58,67,77,86,96,105,114,124,133,141,149,157,163,169,174,179,182,185,186,187,186,185,182,179,174,169,163,157,149,141,133,124,114,105,96,86,77,67,58,50,42,34,28,22,17,12,9,6,5
ticks_inner1_xs:
        .word   280,298,315,333,350,366,381,395,408,419,429,437,444,449,451,452,451,449,444,437,429,419,408,395,381,366,350,333,315,298,280,261,244,226,209,193,178,164,151,140,130,122,115,110,108,107,108,110,115,122,130,140,151,164,178,193,209,226,244,261
ticks_inner1_ys:
        .word   9,10,11,13,17,21,26,31,38,45,52,60,69,78,86,96,105,113,122,131,139,146,153,160,165,170,174,178,180,181,182,181,180,178,174,170,165,160,153,146,139,131,122,113,105,96,86,78,69,60,52,45,38,31,26,21,17,13,11,10
ticks_inner2_xs:
        .word   280,297,313,330,346,361,375,389,401,412,421,429,435,439,442,443,442,439,435,429,421,412,401,389,375,361,346,330,313,297,280,262,246,229,213,198,184,170,158,147,138,130,124,120,117,116,117,120,124,130,138,147,158,170,184,198,213,229,246,262
ticks_inner2_ys:
        .word   14,14,16,18,21,25,29,35,41,48,55,62,70,79,87,96,104,112,121,129,136,143,150,156,162,166,170,173,175,177,177,177,175,173,170,166,162,156,150,143,136,129,121,112,104,96,87,79,70,62,55,48,41,35,29,25,21,18,16,14
min_hand_xs:
        .word   280,296,311,327,342,356,370,382,394,404,413,420,426,430,432,433,432,430,426,420,413,404,394,382,370,356,342,327,311,296,280,263,248,232,217,203,189,177,165,155,146,139,133,129,127,126,127,129,133,139,146,155,165,177,189,203,217,232,248,263
min_hand_ys:
        .word   19,19,20,22,25,29,33,38,44,50,57,64,72,80,87,96,104,111,119,127,134,141,147,153,158,162,166,169,171,172,172,172,171,169,166,162,158,153,147,141,134,127,119,111,104,96,87,80,72,64,57,50,44,38,33,29,25,22,20,19
hour_hand_xs:
        .word   280,290,299,309,319,328,336,344,351,357,363,367,371,373,375,376,375,373,371,367,363,357,351,344,336,328,319,309,299,290,280,269,260,250,240,232,223,215,208,202,196,192,188,186,184,184,184,186,188,192,196,202,208,215,223,231,240,250,260,269
hour_hand_ys:
        .word   48,48,49,50,52,54,57,60,63,67,72,76,81,86,90,96,101,105,110,115,119,124,128,131,134,137,139,141,142,143,144,143,142,141,139,137,134,131,128,124,120,115,110,105,101,96,90,86,81,76,72,67,63,60,57,54,52,50,49,48
hour_base:
        .byte   0,5,10,15,20,25,30,35,40,45,50,55,0,5,10,15,20,25,30,35,40,45,50,55
min_offset:
        .byte   0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4

;;; ============================================================

        .include "../lib/datetime.s"
        str_time := *           ; unused, but needed

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        lda     MACHID
        and     #kMachIDHasClock
    IF ZERO
        TAIL_CALL JUMP_TABLE_SHOW_ALERT, A=#ERR_DEVICE_NOT_CONNECTED
    END_IF

        JSR_TO_AUX aux::Init
        rts

.proc DoMLIGetTime
        JUMP_TABLE_MLI_CALL GET_TIME
        rts
.endproc ; DoMLIGetTime

        DA_END_MAIN_SEGMENT

;;; ============================================================
