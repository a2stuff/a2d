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

        .org DA_LOAD_ADDRESS

.proc Start
        sta     ROMIN2
        sta     ALTZPOFF
        jsr     SaveText
        sta     TXTSET
        sta     CLR80VID
        sta     DHIRESOFF

        jsr     Run

        sta     DHIRESON
        sta     TXTCLR
        sta     SET80VID
        jsr     RestoreText
        sta     ALTZPON
        sta     LCBANK1
        sta     LCBANK1
        jsr     JUMP_TABLE_RGB_MODE
        rts
.endproc

;;; ============================================================

;;; Save text page 1 (not screen holes)
.proc SaveText
        lda     #0
        sta     CV

        ptr := $06

        ;; Set BASL/H
loop:   jsr     VTAB
        add16   BASL, #save_buffer-$400, ptr
        ldy     #39
        ldx     #0

:       lda     (BASL),y
        sta     (ptr),y
        lda     #' '|$80
        sta     (BASL),y
        dey
        bpl     :-

        inc     CV
        lda     CV
        cmp     #24
        bne     loop

        rts
.endproc

;;; Restore text page 1 (not screen holes)
.proc RestoreText
        lda     #0
        sta     CV

        ptr := $06

        ;; Set BASL/H
loop:   jsr     VTAB
        add16   BASL, #save_buffer-$400, ptr
        ldy     #39

:       lda     (ptr),y
        sta     (BASL),y
        dey
        bpl     :-

        inc     CV
        lda     CV
        cmp     #24
        bne     loop

        rts
.endproc

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


        sta     KBDSTRB

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
        ;; End on keypress
        lda     KBD
        bpl     :+
        sta     KBDSTRB
        rts
:
        ;; Speed control
        lda     #64
        jsr     Wait

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

        ;; --------------------------------------------------

.proc AdvanceCursor
        ;; Still on screen? If not, skip (until reset)
        ldy     #Cursor::vpos
        lda     (ptr),y
        cmp     #24
        bcc     :+
        rts
:
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
.endproc

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
.endproc

        ;; --------------------------------------------------

;;; Generate random horizontal position (0-39)
.proc GetRandomH
:       jsr     Random
        and     #%00111111      ; 0...63
        cmp     #40
        bcs     :-              ; retry if >= 40
        rts
.endproc

        ;; --------------------------------------------------

;;; Generate random character
.proc GetRandomChar
:       jsr     Random
        and     #%01111111      ; 0...127
        cmp     #' '+1
        bcc     :-              ; retry if control or space
        rts
.endproc

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
.endproc

        ;; --------------------------------------------------

index:  .byte   0

c1:     .tag    Cursor
c2:     .tag    Cursor
c3:     .tag    Cursor
c4:     .tag    Cursor

list:   .addr   c1, c2, c3, c4
        ASSERT_ADDRESS_TABLE_SIZE list, kNumCursors
.endproc

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
.endproc

.proc InitRand
        lda $4E                 ; Seed the random number generator
        sta R1                  ; based on delay between keypresses
        sta R3
        lda $4F
        sta R2
        sta R4
        ldx #$20                ; Generate a few random numbers
InitLoop:
        jsr Random              ; to kick things off
        dex
        bne InitLoop
        rts
.endproc

;;; ============================================================

save_buffer:

;;; ============================================================

.assert * + $400 < WINDOW_ENTRY_TABLES, error, .sprintf("DA too big (at $%X)", *)
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00
