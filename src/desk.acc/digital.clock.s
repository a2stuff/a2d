;;; ============================================================
;;; DIGITAL.CLOCK - Desk Accessory
;;;
;;; Clears the screen and shows the current time/date.
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

pensize:        .byte   8, 4

kCharWidth  = 6
kCharHeight = 6
kCharXShift = 3
kCharYShift = 3

kCharAdvance = (kCharWidth+1) << kCharXShift
kCharY = (kScreenHeight + (kCharHeight << kCharYShift)) / 2

        DEFINE_POINT vector_cursor, 0, 0
        DEFINE_POINT cur, 0, 0

;;; ============================================================

str_time:
        PASCAL_STRING "00:00 XM"

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
        dex
    WHILE POS
        rts                     ; no change

        ;; Different! update
diff:   COPY_STRUCT DateTime, datetime, last
        jmp     Update

last:   .tag    DateTime
.endproc ; MaybeUpdate

.proc Update
        copy16  #parsed, $A
        CALL    ParseDatetime, AX=#datetime
        CALL    MakeTimeString, AX=#parsed ; populates `str_time`

        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport

        ;; Clear to black
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintRect, grafport + MGTK::GrafPort::maprect

        ;; Init cursor
        copy16  #kCharY, vector_cursor::ycoord
        copy16  #0, vector_cursor::xcoord
        ldx     str_time        ; A = string length
    DO
        add16_8 vector_cursor::xcoord, #kCharWidth+1
        dex
    WHILE NOT_ZERO

        dec16   vector_cursor::xcoord
        ldx     #kCharXShift    ; scale x
    DO
        asl16   vector_cursor::xcoord
        dex
    WHILE NOT_ZERO

        sub16   #kScreenWidth, vector_cursor::xcoord, vector_cursor::xcoord
        asr16   vector_cursor::xcoord

        ;; Set up for drawing
        MGTK_CALL MGTK::SetPenSize, pensize
        MGTK_CALL MGTK::SetPenMode, pencopy

        ;; Iterate over string, draw each char
        copy8   #1, idx
    DO
        idx := *+1
        ldx     #SELF_MODIFIED_BYTE
        CALL    DrawVectorChar, A=str_time,x

        lda     idx
        BREAK_IF A = str_time
        inc     idx
    WHILE NOT_ZERO

done:
        rts
.endproc ; Update

;;; ============================================================

;;; A = char
.proc DrawVectorChar
        cmp     #' '
        jeq     advance

        ptr := $06

        jsr     GetPoly
        stax    ptr
        ldy     #0

        ;; For each poly...
ploop:  copy8   (ptr),y, num_verts ; A = num vertices
        iny

        ;; For each vertex...
        copy8   #0, vindex
    DO
        copy8   (ptr),y, cur::xcoord
        iny
        copy8   (ptr),y, cur::ycoord
        iny
        lda     #0
        sta     cur::xcoord+1   ; extend to 16 bits
        sta     cur::ycoord+1

        ;; Scale
        ldx     #kCharXShift    ; scale x
      DO
        asl16   cur::xcoord
        dex
      WHILE NOT_ZERO

        ldx     #kCharYShift    ; scale y
      DO
        asl16   cur::ycoord
        dex
      WHILE NOT_ZERO

        ;; Offset
        add16   vector_cursor::xcoord, cur::xcoord, cur::xcoord
        sub16   vector_cursor::ycoord, cur::ycoord, cur::ycoord

        tya                     ; Y = ptr offset
        pha

        lda     vindex
      IF ZERO
        MGTK_CALL MGTK::MoveTo, cur
      ELSE
        MGTK_CALL MGTK::LineTo, cur
      END_IF

        pla
        tay                     ; Y = ptr offset

        inc     vindex

        dec     num_verts
    WHILE NOT_ZERO

        lda     (ptr),y         ; A = num vertices, 0 if done
        beq     advance         ; done
        jmp     ploop

advance:
        add16   vector_cursor::xcoord, #kCharAdvance, vector_cursor::xcoord
        rts

vindex:         .byte   0
num_verts:      .byte   0
more_flag:      .byte   0

.endproc ; DrawVectorChar


;;; ============================================================

;;; Input: A = char
;;; Output: A,X = poly addr
.proc GetPoly
        ;; Find index
        ldx     #0
    DO
        BREAK_IF A = char_to_index,x
        inx
    WHILE NOT_ZERO              ; always

        ;; Get poly address
        txa
        asl
        tax
        lda     index_to_poly,x
        pha
        lda     index_to_poly+1,x
        tax
        pla

        rts
.endproc ; GetPoly

;;; ============================================================

char_to_index:
        .byte   "0123456789APM:"
index_to_poly:
        .addr   poly_0, poly_1, poly_2, poly_3
        .addr   poly_4, poly_5, poly_6, poly_7
        .addr   poly_8, poly_9, poly_A, poly_P
        .addr   poly_M, poly_colon

;;; Adapted from: https://wiki.tcl-lang.org/page/Vector+Font
;;; Format is a list of polylines:
;;;   num_verts (0 = done)
;;;   x1, y1, x2, y2 ...
;;; Coords are [0..4],[0..6] with 0,0 in lower left of box
poly_0:
        .byte   5
        .byte   0,0, 0,6, 4,6, 4,0, 0,0
        .byte   2
        .byte   0,0, 4,6
        .byte   0
poly_1:
        .byte   3
        .byte   2,0, 2,6, 0,4
        .byte   2
        .byte   0,0,4,0
        .byte   0
poly_2:
        .byte   6
        .byte   0,6, 4,6, 4,3, 0,3, 0,0, 4,0
        .byte   0
poly_3:
        .byte   4
        .byte   0,6, 4,6, 4,0, 0,0
        .byte   2
        .byte   0,3, 4,3
        .byte   0
poly_4:
        .byte   3
        .byte   0,6, 0,3, 4,3
        .byte   2
        .byte   4,6, 4,0
        .byte   0
poly_5:
        .byte   6
        .byte   0,0, 4,0, 4,3, 0,3, 0,6, 4,6
        .byte   0
poly_6:
        .byte   6
        .byte   4,6, 0,6, 0,0, 4,0, 4,3, 0,3
        .byte   0
poly_7:
        .byte   3
        .byte   0,6, 4,6, 4,0
        .byte   0
poly_8:
        .byte   5
        .byte   0,0, 0,6, 4,6, 4,0, 0,0
        .byte   2
        .byte   0,3, 4,3
        .byte   0
poly_9:
        .byte   5
        .byte   4,0, 4,6, 0,6, 0,3, 4,3
        .byte   0
poly_A:
        .byte   5
        .byte   0,0, 0,4, 2,6, 4,4, 4,0
        .byte   2
        .byte   0,2, 4,2
        .byte   0
poly_P:
        .byte   5
        .byte   0,0, 0,6, 4,6, 4,3, 0,3
        .byte   0
poly_M:
        .byte   5
        .byte   0,0, 0,6, 2,4, 4,6, 4,0
        .byte   0
poly_colon:
        .byte   2
        .byte   2,1, 2,2
        .byte   2
        .byte   2,4, 2,5
        .byte   0

;;; ============================================================

        .include "../lib/datetime.s"

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
