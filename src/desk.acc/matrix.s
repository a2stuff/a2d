;;; ============================================================
;;; MATRIX - Desk Accessory
;;;
;;; Digital waterfall effect from The Matrix.
;;; (This is a good sample for text-mode screen savers.)
;;; ============================================================

        .include "../config.inc"

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

event_params:   .tag MGTK::Event

;;; ============================================================

        DA_END_AUX_SEGMENT
        DA_START_MAIN_SEGMENT

;;; ============================================================

kMainPageClearByte = ' '|$80    ; space
kAuxPageClearByte  = $C0        ; light-green on black, for RGB cards

.proc Start
        JUMP_TABLE_MGTK_CALL MGTK::FlushEvents
        JUMP_TABLE_MGTK_CALL MGTK::HideCursor

        bit     ROMIN2
        sta     ALTZPOFF
        jsr     SaveText
        sta     TXTSET
        sta     CLR80VID

        ;; IIgs: set green-on-black
        sec
        jsr     IDROUTINE
    IF_CC
        .pushcpu
        .setcpu "65816"
        lda     TBCOLOR         ; save text fg/bg
        pha
        lda     #$C0            ; assign text fg/bg
        sta     TBCOLOR

        lda     CLOCKCTL        ; save border
        and     #$0F
        pha
        lda     #$0F            ; assign border
        trb     CLOCKCTL
        .popcpu
    END_IF

        jsr     Run

        ;; IIgs: restore color
        sec
        jsr     IDROUTINE
    IF_CC
        .pushcpu
        .setcpu "65816"
        pla                     ; restore border
        tsb     CLOCKCTL

        pla                     ; restore text fg/bg
        sta     TBCOLOR
        .popcpu
    END_IF

        sta     TXTCLR
        sta     SET80VID
        jsr     RestoreText
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        JUMP_TABLE_MGTK_CALL MGTK::ShowCursor
        jmp     JUMP_TABLE_RGB_MODE
.endproc ; Start

;;; ============================================================

;;; Save and clear main/aux text page 1 (preserving screen holes)
.proc SaveText
        sta     SET80STORE      ; let PAGE2 control banking
        lda     #0
        sta     CV

        ptr1 := $06
        ptr2 := $08

        ;; Set BASL/H
rloop:  jsr     VTAB
        add16   BASL, #save_buffer-$400, ptr1
        add16   ptr1, #$400, ptr2
        ldy     #39

cloop:
        ;; Main
        lda     (BASL),y
        sta     (ptr1),y
        lda     #kMainPageClearByte
        sta     (BASL),y

        ;; Aux
        sta     PAGE2ON
        lda     (BASL),y
        sta     (ptr2),y
        lda     #kAuxPageClearByte
        sta     (BASL),y
        sta     PAGE2OFF

        dey
        bpl     cloop

        inc     CV
        lda     CV
        cmp     #24
        bne     rloop

        sta     CLR80STORE
        rts
.endproc ; SaveText

;;; Restore main/aux text page 1 (preserving screen holes)
.proc RestoreText
        sta     SET80STORE      ; let PAGE2 control banking
        lda     #0
        sta     CV

        ptr1 := $06
        ptr2 := $08

        ;; Set BASL/H
rloop:  jsr     VTAB
        add16   BASL, #save_buffer-$400, ptr1
        add16   ptr1, #$400, ptr2
        ldy     #39

cloop:
        ;; Main
        lda     (ptr1),y
        sta     (BASL),y

        ;; Aux
        sta     PAGE2ON
        lda     (ptr2),y
        sta     (BASL),y
        sta     PAGE2OFF

        dey
        bpl     cloop

        inc     CV
        lda     CV
        cmp     #24
        bne     rloop

        sta     CLR80STORE
        rts
.endproc ; RestoreText

;;; ============================================================

event_params:   .tag MGTK::Event

;;; ============================================================

.proc CopyEventAuxToMain
        copy16  #aux::event_params, STARTLO
        copy16  #aux::event_params + .sizeof(MGTK::Event) - 1, ENDLO
        copy16  #event_params, DESTINATIONLO
        clc                     ; aux > main
        jmp     AUXMOVE
.endproc ; CopyEventAuxToMain

;;; ============================================================
;;; Guts of the screen saver

;;; Inspired by: https://github.com/neilk/apple-ii-matrix

.proc Run
        ptr := $06

kNumCursors = 4

.struct Cursor
        hpos    .byte
        vpos    .byte
        mode    .byte           ; high bit set = erase
.endstruct

        jsr     InitRand

        ;; Initialize cursors
        lda     #kNumCursors-1
        sta     index
:       lda     index
        asl
        tax
        copy16  list,x, ptr
        jsr     ResetCursor
        dec     index
        bpl     :-

        ;; --------------------------------------------------

MainLoop:
        ;; See if there's an event that should make us exit.
        bit     LCBANK1
        bit     LCBANK1
        sta     ALTZPON
        JUMP_TABLE_MGTK_CALL MGTK::GetEvent, aux::event_params
        sta     ALTZPOFF
        bit     ROMIN2
        jsr     CopyEventAuxToMain

        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::button_down
        beq     exit
        cmp     #MGTK::EventKind::key_down
        beq     exit

        ;; Iterate over all cursors
        lda     #kNumCursors-1
        sta     index

CursorLoop:
        lda     index
        asl
        tax
        copy16  list,x, ptr

        jsr     Random
        and     #%00011111      ; 1/32 chance of reset
    IF_ZERO
        jsr     ResetCursor
    ELSE
        jsr     AdvanceCursor
    END_IF

        dec     index
        bpl     CursorLoop
        bmi     MainLoop        ; always

exit:   rts

        ;; --------------------------------------------------

.proc AdvanceCursor
        ;; Still on screen? If not, skip (until reset)
        ldy     #Cursor::vpos
        lda     (ptr),y
        cmp     #24
        RTS_IF_GE

        ;; Set BASL/H
        sta     CV
        jsr     VTAB

        ;; Determine character to draw
        ldy     #Cursor::mode
        lda     (ptr),y
        and     #%00000001      ; Use low bit
   IF_ZERO
        lda     #' '
   ELSE
        jsr     GetRandomChar
   END_IF
        ora     #$80

        ;; Draw it
        pha
        ldy     #Cursor::hpos
        lda     (ptr),y
        tay
        pla
        sta     (BASL),y

        ;; Move down
        ldy     #Cursor::vpos
        lda     (ptr),y
        clc
        adc     #1
        sta     (ptr),y

        rts
.endproc ; AdvanceCursor

        ;; --------------------------------------------------

.proc ResetCursor
        jsr     GetRandomH
        ldy     #Cursor::hpos
        sta     (ptr),y

        lda     #0
        ldy     #Cursor::vpos
        sta     (ptr),y

        jsr     Random
        ldy     #Cursor::mode
        sta     (ptr),y

        rts
.endproc ; ResetCursor

        ;; --------------------------------------------------

;;; Generate random horizontal position (0-39)
.proc GetRandomH
:       jsr     Random
        and     #%00111111      ; 0...63
        cmp     #40
        bcs     :-              ; retry if >= 40
        rts
.endproc ; GetRandomH

        ;; --------------------------------------------------

;;; Generate random character
.proc GetRandomChar
:       jsr     Random
        and     #%01111111      ; 0...127
        cmp     #' '+1
        bcc     :-              ; retry if control or space
        rts
.endproc ; GetRandomChar

        ;; --------------------------------------------------

.proc Wait
        sec
wait2:  pha
wait3:  sbc     #1
        bne     wait3
        pla
        sbc     #1
        bne     wait2
        rts
.endproc ; Wait

        ;; --------------------------------------------------

index:  .byte   0

c1:     .tag    Cursor
c2:     .tag    Cursor
c3:     .tag    Cursor
c4:     .tag    Cursor

list:   .addr   c1, c2, c3, c4
        ASSERT_ADDRESS_TABLE_SIZE list, kNumCursors
.endproc ; Run

;;; ============================================================

        .include "../lib/prng.s"

;;; ============================================================

save_buffer := *

;;; Ensure there's enough room for both main and aux text page
.assert * + $800 < $2000, error, .sprintf("Not enough room for save buffers")

        DA_END_MAIN_SEGMENT

;;; ============================================================
