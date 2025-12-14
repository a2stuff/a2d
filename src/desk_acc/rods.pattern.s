;;; ============================================================
;;; RODS.PATTERN - Desk Accessory
;;;
;;; Rod’s Color Pattern - From the Apple ][ "Red Book"
;;; Adapted from Dr. John B. Matthews for A2D by Frank Milliron
;;; https://sites.google.com/site/drjohnbmatthews/apple2
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        forty     :=   $28
        gbasl     :=   $26
        color     :=   $30
        cgs       :=   $31
        textpt    :=   $3A
        A1        :=   $3C
        A2        :=   $3E
        A3        :=   $40
        A4        :=   $42
        A5        :=   $44
        w         :=   $E0
        i         :=   $E1
        j         :=   $E2
        k         :=   $E3
        fmi       :=   $E4
        fmk       :=   $E5

        key       :=   $C000
        strobe    :=   $C010
        fullscr   :=   $C052

        pread     :=   $FB1E
        settx     :=   $FB39
        setgr     :=   $FB40
        vtab      :=   $FB5B
        wait      :=   $FCA8
        cout1     :=   $FDF0

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
        sta     DHIRESOFF

        ;; IIgs: save text & border colors & set white-on-black text
        CALL    IDROUTINE, C=1
    IF CC
        .pushcpu
        .setcpu "65816"
        lda     TBCOLOR         ; save text fg/bg
        pha
        lda     #$F0            ; assign text fg/bg
        sta     TBCOLOR

        lda     CLOCKCTL        ; save border
        and     #$0F
        pha
        .popcpu
    END_IF

        jsr     Run

        ;; IIgs: restore original border color
        CALL    IDROUTINE, C=1
    IF CC
        .pushcpu
        .setcpu "65816"
        lda     #$0F
        trb     CLOCKCTL
        pla
        tsb     CLOCKCTL        ; restore border
        pla
        sta     TBCOLOR         ; restore text fg/bg
        .popcpu
    END_IF

        sta     TXTCLR
        sta     SET80VID
        sta     DHIRESON
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
    DO
        jsr     VTAB
        add16   BASL, #save_buffer-$400, ptr1
        add16   ptr1, #$400, ptr2
        ldy     #39

      DO
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
      WHILE POS

        inc     CV
        lda     CV
    WHILE A <> #24

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
    DO
        jsr     VTAB
        add16   BASL, #save_buffer-$400, ptr1
        add16   ptr1, #$400, ptr2
        ldy     #39

      DO
        ;; Main
        lda     (ptr1),y
        sta     (BASL),y

        ;; Aux
        sta     PAGE2ON
        lda     (ptr2),y
        sta     (BASL),y
        sta     PAGE2OFF

        dey
      WHILE POS

        inc     CV
        lda     CV
    WHILE A <> #24

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
        TAIL_CALL AUXMOVE, C=0  ; aux > main
.endproc ; CopyEventAuxToMain

;;; ============================================================
;;; DA Guts of the screen saver

.proc Run

        lda     HIRESOFF
        jsr     setgr
        jsr     HOME
        lda     #$16
        jsr     vtab
        jsr     prtext

        .byte   "    PDL(0) controls speed of display"
        .byte   $8D
        .byte   "          Press any key to exit"
        .byte   $00

begin:  lda     #$03            ;init loop counters
        sta     w
nxtw:   lda     #$01
        sta     i
nxti:   lda     #$00
        sta     j
nxtj:   clc
        lda     i
        adc     j
        sta     k
        jsr     colsel
        ldy     i               ;plot i,k
        lda     k
        jsr     plot
        ldy     k               ;plot k,i
        lda     i
        jsr     plot
        sec                     ;plot 40-i, 40-k
        lda     #forty
        sbc     i
        sta     fmi
        tay
        sec
        lda     #forty
        sbc     k
        sta     fmk
        jsr     plot
        ldy     fmk             ;plot 40-k, 40-i
        lda     fmi
        jsr     plot
        ldy     k               ;plot k, 40-i
        lda     fmi
        jsr     plot
        ldy     fmi             ;plot 40-i, k
        lda     k
        jsr     plot
        ldy     i               ;plot i, 40-k
        lda     fmk
        jsr     plot
        ldy     fmk             ;plot 40-k, i
        lda     i
        jsr     plot
        jsr     delay
        inc     j               ;close loops
        lda     j
        cmp     #$14
        bcc     nxtj
        inc     i
        lda     i
        cmp     #$14
        bcc     nxti
        inc     w
        lda     w
        cmp     #$33
        bcc     nxtw
        jmp     begin
;
; Delay by setting of PDL(0)
;
delay:  ldx     #$00
        jsr     pread           ;read pdl(0)
        tya
        lsr                     ;divide by 4
        lsr
        beq     del1
        jsr     wait

del1:   ;; See if there's an event that should make us exit.
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
        rts

exit:   pla                     ;pop stack
        pla
        jsr     settx
        lda     fullscr
        lda     HIRESON
        rts                     ;return to A2D
;
; Plot via table lookup
; A = y coordinate; Y = x coordinate
;
plot:   lsr
        php
        tax
        lda     basl,x
        sta     gbasl
        lda     bash,x
        sta     gbasl+1
        jmp     $F805           ;undocumented entry to ROM PLOT routine
basl:   .byte   $00,$80,$00,$80,$00,$80,$00,$80
        .byte   $28,$A8,$28,$A8,$28,$A8,$28,$A8
        .byte   $50,$D0,$50,$D0,$50,$D0,$50,$D0
bash:   .byte   $04,$04,$05,$05,$06,$06,$07,$07
        .byte   $04,$04,$05,$05,$06,$06,$07,$07
        .byte   $04,$04,$05,$05,$06,$06,$07,$07
;
; Print text up to next null
;
prtext: pla
        sta     textpt
        pla
        sta     textpt+1
        ldy     #$00
prt1:   inc     textpt
        bne     prt2
        inc     textpt+1
prt2:   lda     (textpt),y
        beq     prt3
        ora     #$80
        jsr     cout1
        jmp     prt1
prt3:   lda     textpt+1
        pha
        lda     textpt
        pha
        rts
;
; Color = j*3/(i+3)+i*w/12
;
colsel: clc                     ;A5 = j*3
        lda     j
        adc     j
        adc     j
        sta     A5
        lda     i               ;A4 = i+3
        adc     #$03
        sta     A4
        ldy     #$FF            ;A5 = A5/A4
        sec
        lda     A5
divi3:  sbc     A4
        iny
        bcs     divi3
        sty     A5
        lda     i               ;A1 = i
        sta     A1
        lda     w               ;A2 = w
        sta     A2
        lda     #$00            ;A3 = A1*A2
        sta     A3+1
        ldx     #$08
shift:  asl
        rol     A3+1
        asl     A2
        bcc     bitcnt
        clc
        adc     A1
        bcc     bitcnt
        inc     A3+1
bitcnt: dex
        bne     shift
        sta     A3
        lda     #$0C            ;A2 = 12
        sta     A2
        ldx     #$08
        lda     A3              ;A1 = A3
        sta     A1
        lda     A3+1            ;A1 = A1/A2
div:    asl     A1
        rol     A
        cmp     A2
        bcc     bcnt
        sbc     A2
        inc     A1
bcnt:   dex
        bne     div
        clc                     ;A = A1+A5
        lda     A1
        adc     A5
        and     #$0F            ;copy to upper nibble
        sta     color
        sta     cgs             ;for IIgs only
        asl
        asl
        asl
        asl
        ora     color
        sta     color

        ;; If IIgs, set border to plot color
        CALL    IDROUTINE, C=1
    IF CC
        .pushcpu
        .setcpu "65816"
        lda     #$0F
        trb     CLOCKCTL
        lda     cgs
        tsb     CLOCKCTL
        .popcpu
    END_IF

        rts

.endproc ; Run

;;; ============================================================

da_end  := *

save_buffer := *

;;; Ensure there's enough room for both main and aux text page
.assert * + $800 < $2000, error, .sprintf("Not enough room for save buffers")

        DA_END_MAIN_SEGMENT

;;; ============================================================
