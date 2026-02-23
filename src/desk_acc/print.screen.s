;;; ============================================================
;;; PRINT.SCREEN - Desk Accessory
;;;
;;; Dumps the contents of the graphics screen to an ImageWriter
;;; printer connected to a Super Serial Card in Slot 1.
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
        DA_START_MAIN_SEGMENT

;;; ============================================================

        JUMP_TABLE_MGTK_CALL MGTK::HideCursor
        jsr     JUMP_TABLE_HILITE_MENU
        jsr     DumpScreen
        jsr     JUMP_TABLE_HILITE_MENU
        JUMP_TABLE_MGTK_CALL MGTK::ShowCursor
        rts

;;; ============================================================

kSigLen = 4
sig_offsets:
        .byte   $05, $07, $0B, $0C
        ASSERT_TABLE_SIZE sig_offsets, kSigLen
sig_bytes:
        .byte   $38, $18, $01, $31
        ASSERT_TABLE_SIZE sig_bytes, kSigLen

.proc DumpScreen

        SLOT1   := $C100

        ;; Check for hardware signature - SSC in Slot 1

        ldy     #kSigLen-1
    DO
        ldx     sig_offsets,y
        lda     SLOT1,x
        cmp     sig_bytes,y
        bne     no_device
    WHILE dey : POS

        hbasl := $6
        kScreenWidth  = 560
        kScreenHeight = 192

        sta     ALTZPOFF
        bit     ROMIN2

        ;; SSC operations trash the text page (if 80 col firmware active?)
        jsr     SaveTextPage
        jsr     PrintScreen
        jsr     RestoreTextPage

        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1
ret:    rts

no_device:
        TAIL_CALL JUMP_TABLE_SHOW_ALERT, A=#ERR_DEVICE_NOT_CONNECTED

.proc SendSpacing
        ldy     #0
    DO
        CALL    COut, A=spacing_sequence,y
    WHILE iny : Y <> #kLenSpacingSequence
        rts
.endproc ; SendSpacing

.proc SendRestoreState
        ldy     #0
    DO
        CALL    COut, A=restore_sequence,y
    WHILE iny : Y <> #kLenRestoreSequence
        rts
.endproc ; SendRestoreState

.proc SendInitGraphics
        ldx     #0
    DO
        CALL    COut, A=init_graphics,x
    WHILE inx : X <> #kLenInitGraphics
        rts
init_graphics:
        .byte   CHAR_ESCAPE,"G0560"     ; Graphics, 560 data bytes
        kLenInitGraphics = * - init_graphics
.endproc ; SendInitGraphics

.proc SendRow
        ;; Tell printer to expect graphics
        jsr     SendInitGraphics
        ldy     #0
        sty     col_num
        copy8   #1, mask
        copy16  #0, x_coord

        ;; Uses PAGE2 flag to control main/aux reads
        sta     SET80STORE

col_loop:
        copy8   #4, count       ; 8 vertical pixels per row (doubled)
        copy8   y_row, y_coord

        ;; Accumulate 8 pixels
    DO
        CALL    ComputeHBASL, A=y_coord ; Row address in screen

        lda     col_num
        lsr     a               ; Even or odd column?
        tay
        sta     PAGE2OFF        ; By default, read main mem $2000-$3FFF
      IF CC                     ; But even columns come from aux, so...
        sta     PAGE2ON         ; Read aux mem $2000-$3FFF
      END_IF
        lda     (hbasl),y       ; Grab the whole byte
        and     mask            ; Isolate the pixel we care about
        cmp     #1              ; Set carry if non-zero
        php
        ror     accum           ; And slide it into place
        plp
        ror     accum           ; Doubled
        inc     y_coord
    WHILE dec count : NOT_ZERO

        ;; Send the 8 pixels to the printer.
        lda     accum           ; Now output it
        eor     #$FF            ; Invert pixels (screen vs. print)
        sta     PAGE2OFF        ; Read main mem $2000-$3FFF
        jsr     COut            ; And actually print

        ;; Done all pixels across?
        lda     x_coord
    IF A = #<(kScreenWidth-1)
        lda     x_coord+1
        cmp     #>(kScreenWidth-1)
        beq     done
    END_IF

        ;; Next pixel to the right
        asl     mask
    IF NS                       ; Only 7 pixels per column
        copy8   #1, mask
        inc     col_num
    END_IF

        inc     x_coord
        bne     col_loop
        inc     x_coord+1
        bne     col_loop

done:   sta     PAGE2OFF        ; Read main mem $2000-$3FFF
        rts
.endproc ; SendRow

.proc PrintScreen
        ;; Init printer
        CALL    GoCard, Y=#SSC::PInit

        jsr     SendSpacing

        copy8   #0, y_row

        ;; Print a row (560x8), CR+LF
    DO
        jsr     SendRow
        CALL    COut, A=#CHAR_RETURN
        CALL    COut, A=#CHAR_DOWN

        copy8   y_coord, y_row
    WHILE A < #kScreenHeight

        ;; Finish up
        CALL    COut, A=#CHAR_RETURN
        CALL    COut, A=#CHAR_DOWN

        jsr     SendRestoreState

        rts
.endproc ; PrintScreen

        ;; Given y-coordinate in A, compute HBASL-equivalent
.proc ComputeHBASL
        pha
        and     #$C7
        eor     #$08
        sta     hbasl+1
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        sta     hbasl
        pla
        and     #$38
        asl     a
        asl     a
        eor     hbasl
        asl     a
        rol     hbasl+1
        asl     a
        rol     hbasl+1
        eor     hbasl
        sta     hbasl
        rts
.endproc ; ComputeHBASL

;;; Inputs: Y = entry point, A = char to output (for `PWrite`)
.proc GoCard
        ldx     SLOT1,y
        stx     vector+1
        ldx     #>SLOT1                  ; X = $Cn
        ldy     #((>SLOT1)<<4)&%11110000 ; Y = $n0
        ;; A2MISC TechNote #3 SSC C800 space
        stx     MSLOT
        stx     $CFFF
vector: jmp     SLOT1                    ; self-modified
.endproc ; GoCard

.proc COut
        sta     asave
        stx     xsave
        sty     ysave

        CALL    GoCard, Y=#SSC::PWrite

        lda     asave
        ldx     xsave
        ldy     ysave

        rts

asave:  .byte   0
xsave:  .byte   0
ysave:  .byte   0
.endproc ; COut

y_row:  .byte   0              ; y-coordinate of row start (0, 8, ...)
x_coord:.word   0              ; x-coordinate of pixels being accumulated
y_coord:.byte   0              ; iterates y_row to y_row+7
mask:   .byte   0              ; mask for pixel being processed
accum:  .byte   0              ; accumulates pixels for output
count:  .byte   0              ; 8...1 while a row is output
col_num:.byte   0              ; 0...79

        .byte   0, 0

spacing_sequence:
        .byte   CHAR_ESCAPE,'n'    ; IW2: 72 DPI (horizontal; "Extended")
        .byte   CHAR_ESCAPE,"T16"  ; IW2: 72 DPI (vertical; 8 strikers / 72 = 16/144")
        ;;         .byte   CHAR_TAB,"L D",$8D ; SSC: Disable LF after CR
        .byte   CHAR_ESCAPE,'Z',$80,$00
        kLenSpacingSequence = * - spacing_sequence

restore_sequence:
        .byte   CHAR_ESCAPE,'N'    ; IW2: 80 DPI (horizontal)
        .byte   CHAR_ESCAPE,"T24"  ; IW2: distance between lines (24/144")
        kLenRestoreSequence = * - restore_sequence

.endproc ; DumpScreen

        .include "../lib/save_textpage.s"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
