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

        MGTKEntry := MGTKAuxEntry

;;; ============================================================

        .org DA_LOAD_ADDRESS

da_start:
        jmp     Start

save_stack:.byte   0

.proc Start
        tsx
        stx     save_stack

        ;; Copy DA to AUX
        copy16  #da_start, STARTLO
        copy16  #da_start, DESTINATIONLO
        copy16  #da_end, ENDLO
        sec                     ; main>aux
        jsr     AUXMOVE

        ;; Transfer control to aux
        sta     RAMWRTON
        sta     RAMRDON

        ;; run the DA
        jsr     Init

        ;; tear down/exit
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ldx     save_stack
        txs

        rts
.endproc

;;; ============================================================
;;; Main Memory Relay

;;; Copy of DATELO/HI and TIMELO/HI
datetime:
        .tag    DateTime

;;; Assert: Called from Aux
.proc GetDateTime
        ;; Back to Main, temporarily
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ;; Poke ProDOS to get the latest from clock driver
        JUMP_TABLE_MLI_CALL GET_TIME, 0

        ;; Copy from ProDOS global page to Aux
        sta     RAMWRTON
        COPY_BYTES 4, DATELO, datetime
        sta     RAMRDON
        rts
.endproc

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
.endproc

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

        MGTK_CALL MGTK::DrawMenu
        sta     RAMWRTOFF
        sta     RAMRDOFF
        jsr     JUMP_TABLE_HILITE_MENU
        sta     RAMWRTON
        sta     RAMRDON

        MGTK_CALL MGTK::ShowCursor
        rts                     ; exits input loop
.endproc

;;; ============================================================
;;; Update

;;; Call `Update` if there's a change from last time
.proc MaybeUpdate
        jsr     GetDateTime

        ;; Compare
        ldx     #.sizeof(DateTime)-1
:       lda     datetime,x
        cmp     last,x
        bne     diff
        dex
        bpl     :-
        rts                     ; no change

        ;; Different! update
diff:   COPY_STRUCT DateTime, datetime, last
        jmp     Update

last:   .tag    DateTime
.endproc

.proc Update
        copy16  #parsed, $A
        param_call ParseDatetime, datetime
        param_call MakeTimeString, parsed ; populates `str_time`

        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport

        ;; Clear to black
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintRect, grafport + MGTK::GrafPort::maprect

        ;; Init cursor
        copy16  #kCharY, vector_cursor::ycoord
        copy16  #0, vector_cursor::xcoord
        ldx     str_time        ; A = string length
:       add16_8 vector_cursor::xcoord, #kCharWidth+1
        dex
        bne     :-
        dec16   vector_cursor::xcoord
        ldx     #kCharXShift    ; scale x
:       asl16   vector_cursor::xcoord
        dex
        bne     :-
        sub16   #kScreenWidth, vector_cursor::xcoord, vector_cursor::xcoord
        asr16   vector_cursor::xcoord

        ;; Set up for drawing
        MGTK_CALL MGTK::SetPenSize, pensize
        MGTK_CALL MGTK::SetPenMode, pencopy

        ;; Iterate over string, draw each char
        copy    #1, idx
        idx := *+1
:       ldx     #SELF_MODIFIED_BYTE
        lda     str_time,x

        jsr     DrawVectorChar

        lda     idx
        cmp     str_time
        beq     done
        inc     idx
        bne     :-

done:
        rts
.endproc

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

ploop:  lda     (ptr),y         ; A = num vertices
        sta     num_verts
        iny

        ;; For each vertex...
        copy    #0, vindex
vloop:  lda     (ptr),y         ; A = x coord
        sta     cur::xcoord
        iny
        lda     (ptr),y         ; A = y coord
        sta     cur::ycoord
        iny
        lda     #0
        sta     cur::xcoord+1   ; extend to 16 bits
        sta     cur::ycoord+1

        ;; Scale
        ldx     #kCharXShift    ; scale x
:       asl16   cur::xcoord
        dex
        bne     :-

        ldx     #kCharYShift    ; scale y
:       asl16   cur::ycoord
        dex
        bne     :-

        ;; Offset
        add16   vector_cursor::xcoord, cur::xcoord, cur::xcoord
        sub16   vector_cursor::ycoord, cur::ycoord, cur::ycoord

        tya                     ; Y = ptr offset
        pha

        lda     vindex
    IF_ZERO
        MGTK_CALL MGTK::MoveTo, cur
    ELSE
        MGTK_CALL MGTK::LineTo, cur
    END_IF

        pla
        tay                     ; Y = ptr offset

        inc     vindex

        dec     num_verts
        bne     vloop

        lda     (ptr),y         ; A = num vertices, 0 if done
        beq     advance         ; done
        jmp     ploop

advance:
        add16   vector_cursor::xcoord, #kCharAdvance, vector_cursor::xcoord
        rts

vindex:         .byte   0
num_verts:      .byte   0
more_flag:      .byte   0

.endproc


;;; ============================================================

;;; Input: A = char
;;; Output: A,X = poly addr
.proc GetPoly
        ;; Find index
        ldx     #0
:       cmp     char_to_index,x
        beq     :+
        inx
        bne     :-              ; always
:
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
.endproc

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

da_end:
