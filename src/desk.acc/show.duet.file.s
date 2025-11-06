;;; ============================================================
;;; SHOW.DUET.FILE - Desk Accessory
;;;
;;; Electric Duet by Paul Lutus
;;; Players by Alexander Patalenski and @cybernesto
;;;
;;; Preview accessory for playing Electric Duet files.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "show.duet.file.res"

        .include "apple2.inc"
        .include "opcodes.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================
;;; Memory map
;;;
;;;              Main           Aux
;;;          :           : :           :
;;;          |           | |           |
;;;  $7800   +-----------+ |           |
;;;          | Audio     | |           |
;;;          | Data      | |           |
;;;          | Buffer    | |           |
;;;  $5000   +-----------+ |           |
;;;          |           | |           |
;;;          :           : :           :
;;;          |           | |           |
;;;  $4000   +-----------+ +-----------+
;;;          |           | |           |
;;;          |           | |           |
;;;          | DHR       | | DHR       |
;;;  $2000   +-----------+ +-----------+
;;;          | IO Buffer | |           |
;;;  $1C00   +-----------+ |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          | loader &  | |           |
;;;          | player    | | GUI       |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

;;; There is not enough room in the DA load area to hold 6k of audio
;;; data. A larger buffer is available in DeskTop itself, in an area
;;; that can be restored after use.
data_buf        := OVERLAY_BUFFER
kReadLength      = kOverlayBufferSize

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

kDAWindowId     = $80
kDAWidth        = 340
kDAHeight       = 70
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kDAHeight)/2

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
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
penwidth:       .byte   kBorderDX
penheight:      .byte   kBorderDY
penmode:        .byte   MGTK::notpencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        DEFINE_RECT_FRAME frame_rect, kDAWidth, kDAHeight

ypos_playing:   .word   18
ypos_credit1:   .word   34
ypos_credit2:   .word   45
ypos_instruct:  .word   62

        DEFINE_POINT pos, 0, 0

str_playing:    PASCAL_STRING res_string_playing
name_buf:       .res    16, 0
str_credit1:    PASCAL_STRING res_string_credit1
str_credit2:    PASCAL_STRING res_string_credit2
str_instruct:   PASCAL_STRING res_string_instructions

;;; ============================================================

.proc Init
        ;; Combine strings
        lda     str_playing
        clc
        adc     name_buf
        sta     str_playing
        ;; Shift it down
        ldx     #0
        ldy     name_buf
    DO
        lda     name_buf+1,x
        sta     name_buf,x
        inx
        dey
    WHILE POS

        MGTK_CALL MGTK::OpenWindow, winfo

        ;; --------------------------------------------------
        ;; Draw the window contents

        MGTK_CALL MGTK::SetPort, winfo::port
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::FrameRect, frame_rect

        copy16  ypos_playing, pos::ycoord
        CALL    DrawStringCentered, AX=#str_playing
        copy16  ypos_credit1, pos::ycoord
        CALL    DrawStringCentered, AX=#str_credit1
        copy16  ypos_credit2, pos::ycoord
        CALL    DrawStringCentered, AX=#str_credit2
        copy16  ypos_instruct, pos::ycoord
        CALL    DrawStringCentered, AX=#str_instruct

        MGTK_CALL MGTK::FlushEvents

        ;; --------------------------------------------------
        ;; Play the music

        JSR_TO_MAIN PlayFile

        ;; --------------------------------------------------
        ;; Close the window

        MGTK_CALL MGTK::CloseWindow, winfo
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; Init

;;; ============================================================
;;; Draw centered string
;;; Input: A,X = string address, `pos` used, has ycoord
;;; Trashes $6...$A
.proc DrawStringCentered
        params := $6
        str := $6
        width := $8

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params

        sub16   #kDAWidth, width, pos::xcoord
        lsr16   pos::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, pos
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawStringCentered

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        jmp     Entry

;;; ============================================================

filename:       .res    16, 0

        INVOKE_PATH := $220

        DEFINE_GET_FILE_INFO_PARAMS get_info_params, INVOKE_PATH
        DEFINE_OPEN_PARAMS open_params, INVOKE_PATH, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS read_params, data_buf, kReadLength
        DEFINE_CLOSE_PARAMS close_params

;;; ============================================================
;;; Get filename from DeskTop

ret:    rts

.proc Entry
        ;; Verify type/auxtype
        JUMP_TABLE_MLI_CALL GET_FILE_INFO, get_info_params
        bcs     ret
        lda     get_info_params::file_type
        cmp     #FT_MUSIC
        bne     ret
        ecmp16  get_info_params::aux_type, #$D0E7
        bne     ret

        ;; Extract filename
        ldy     INVOKE_PATH
    DO
        lda     INVOKE_PATH,y   ; find last '/'
        BREAK_IF A = #'/'
        dey
    WHILE NOT_ZERO

        ldx     #0
    DO
        copy8   INVOKE_PATH+1,y, filename+1,x ; copy filename
        inx
        iny
    WHILE Y <> INVOKE_PATH
        stx     filename

        FALL_THROUGH_TO LoadFileAndRunDA
.endproc ; Entry

;;; ============================================================
;;; Load the file

.proc LoadFileAndRunDA

        ;; TODO: Ensure there's enough room, fail if not

        ;; --------------------------------------------------
        ;; Load the file

        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        JUMP_TABLE_MLI_CALL OPEN, open_params
    IF CS
        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts
    END_IF

        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL READ, read_params
        php                     ; preserve error
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        plp
        bcs     exit

        ;; TODO: Try to verify that this is a duet file

        ;; Copy filename
        copy16  #filename, STARTLO
        copy16  #filename+kMaxFilenameLength, ENDLO
        copy16  #aux::name_buf, DESTINATIONLO
        CALL    AUXMOVE, C=1    ; main>aux

        ;; Show the UI
        JSR_TO_AUX aux::Init

        ;; Page DeskTop's code back in.
        CALL    JUMP_TABLE_RESTORE_OVL, A=#kDynamicRoutineRestoreBuffer

        jsr     JUMP_TABLE_CLEAR_UPDATES

exit:   rts
.endproc ; LoadFileAndRunDA

;;; ============================================================

.proc PlayFile
        jsr     FindTheCricket
    IF CS
        copy16  #PlayerCricket, play_routine
    END_IF

        jsr     FindMockingboard
    IF CS
        copy16  #PlayerMockingboard, play_routine

        ;; When Virtual ][ is running at accelerated speed it seems to
        ;; not slow down immediately during Mockingboard playback,
        ;; leading to glitches. Hitting the speaker seems to resolve
        ;; this.
        bit     SPKR
        bit     SPKR
    END_IF

        ;; --------------------------------------------------

        bit     ROMIN2

        jsr     NORMFAST_norm

        bit     KBDSTRB         ; player will stop on keypress

play:   ldax    #data_buf
        play_routine := *+1
        jsr     Player

redo:
        ;; If a key was pressed, maybe restart with alt player
        lda     KBD
    IF NS
        bit     KBDSTRB         ; swallow the keypress

      IF A = #'1'|$80
        copy16  #Player, play_routine
        jmp     play
      END_IF

      IF A = #'2'|$80
        copy16  #Player2, play_routine
        jmp     play
      END_IF

      IF A = #'3'|$80
        copy16  #PlayerMockingboard, play_routine
        jmp     play
      END_IF

      IF A = #'4'|$80
        copy16  #PlayerCricket, play_routine
        jmp     play
      END_IF
    END_IF

        jsr     NORMFAST_fast

        bit     LCBANK1
        bit     LCBANK1
        rts
.endproc ; PlayFile

;;; ============================================================
;;; Player - uses built-in speaker

;;; Electric Duet player by Alex Patalenski
;;; https://www.reddit.com/r/apple2/comments/pue775/improved_electric_duet_player_by_alex_patalenski/

.proc Player

D2 := $02
D3 := $03
D4 := $04
D5 := $05
D6 := $06
D7 := $07
D8 := $08

        ptr := $09
        stax    ptr

        lda     #$00
        sta     D8
        sta     D6
        sta     D7

l1:     ldy     #$00
        lda     (ptr),Y
        bne     :+
exit:   rts

:       sta     D2
        lda     KBD
        bmi     exit

        ldx     #$00
        jsr     Sub
        sta     l30+1
        sta     l37+1
        stx     l31+1
        stx     l38+1

        ldx     #$01
        jsr     Sub
        sta     l53+1
        sta     l60+1
        stx     l54+1
        stx     l61+1

        lda     #$00
        ldx     #$8A
        ldy     #$40
        sta     D3
l24:    sta     D8
        dey
        bne     l33
        ldy     D4
        bit     D8
        bmi     l41
l30:    bit     SPKR            ; self-modified
l31:    eor     #$A0            ; self-modified
        jmp     l45

l33:    cpy     D6
        bne     l40
        bit     D8
        bpl     l42
l37:    bit     SPKR            ; self-modified
l38:    eor     #$A0            ; self-modified
        jmp     l46

l40:    nop
l41:    nop
l42:    nop
        nop
        nop
l45:    nop
l46:    nop
        sta     D8
        dex
        bne     l56
        ldx     D5
        bit     D8
        bmi     l64
l53:    bit     SPKR            ; self-modified
l54:    eor     #$A0            ; self-modified
        jmp     l68

l56:    cpx     D7
l57:    bne     l63
l58:    bit     D8
        bpl     l65
l60:    bit     SPKR            ; self-modified
l61:    eor     #$A0            ; self-modified
        jmp     l69

l63:    nop
l64:    nop
l65:    nop
l66:    nop
l67:    nop
l68:    nop
l69:    nop
        dec     D3
        bne     l75
        dec     D2
        beq     l79
        jmp     l24

l75:    nop
l76:    nop
l77:    nop
        jmp     l24

l79:    lda     ptr
        clc
        adc     #$03
        sta     ptr
        bcc     :+
        inc     ptr+1
:       jmp     l1

.proc Sub
        iny
        lda     (ptr),Y
        php
        sta     D4,X
        cmp     #$05
        bcc     :+
        lsr
        lsr
:       lsr
        lsr
        sta     D6,X
        plp
        beq     :+
        lda     #$30
        ldx     #$A0
:       rts
.endproc ; Sub

.endproc ; Player

;;; ============================================================
;;; Alt. Player - uses built-in speaker

;;; "I found yet another version of Alex's player, this was included in
;;; a game I had written. I don't know if this is older or newer
;;; than the other one I posted..." - Emil Dotchevski

.proc Player2

Z3C := $00
Z3D := $01
Z3E := $02
Z3F := $03
Z40 := $04
Z41 := $05                      ; Not initialized?
Z42 := $06
Z43 := $07
Z44 := $08
Z45 := $09
Z46 := $0A

        ptr := $0B
        stax    ptr

        lda     #$01
        sta     Z42
        sta     Z43
        sta     Z44
        sta     Z45
L665A:  ldy     #$00
        lda     (ptr),Y
        bne     :+
exit:   rts
:
        bit     KBD
        bmi     exit

        cmp     #$01
        bne     :+
        iny
        lda     (ptr),Y
        sta     Z42
        iny
        lda     (ptr),Y
        sta     Z43
        jmp     L66FF

:       sta     Z40
        iny
        lda     (ptr),Y
        sta     Z3C
        ldx     Z42
:       lsr
        dex
        bne     :-
        sta     Z3E
        iny
        lda     (ptr),Y
        sta     Z3D
        ldx     Z43
:       lsr
        dex
        bne     :-
        sta     Z3F
        ldx     Z3C
        ldy     Z3D
        lda     #$00
L6694:  bit     Z44
        bvs     L66A3
        bmi     L66C3
        bit     Z45
        bmi     L66A9
        nop
        bpl     L66AC
L66A1:  bmi     L66AC
L66A3:  bpl     L66C4
        bit     Z45
        bmi     L66A1
L66A9:  bit     SPKR
L66AC:  sta     Z45
        dex
        beq     L66B9
        cpx     Z3E
        beq     L66BD
        nop
L66B6:  jmp     L66C0

L66B9:  ldx     Z3C
        beq     L66B6
L66BD:  nop
        eor     #$80
L66C0:  jmp     L670E

L66C4   := *+1
L66C3:  bit     OPC_NOP
        bit     SPKR
        dex
        beq     L66D3
        cpx     Z3E
        beq     L66D7
        nop
L66D0:  jmp     L66DA

L66D3:  ldx     Z3C
        beq     L66D0
L66D7:  nop
        eor     #$80
L66DA:  bit     SPKR
        dey
        beq     L66E8
        cpy     Z3F
        beq     L66EC
        nop
L66E5:  jmp     L66EF

L66E8:  ldy     Z3D
        beq     L66E5
L66EC:  nop
        eor     #$40
L66EF:  bit     SPKR
        sta     Z44
        dec     Z41
        sta     SPKR
L66F9:  bne     L6694
        dec     Z40
        bne     L6694
L66FF:  lda     ptr
        clc
        adc     #$03
        sta     ptr
        bcc     L670A
        inc     ptr+1
L670A:  jmp     L665A
        rts

L670E:  dey
        beq     L6719
        cpy     Z3F
        beq     L671D
        nop
L6716:  jmp     L6720

L6719:  ldy     Z3D
        beq     L6716
L671D:  nop
        eor     #$40
L6720:  sta     Z44
        jmp     L6726

L6725:  rts                     ; Unreferenced?

L6726:  dec     Z41
        jmp     L66F9
.endproc ; Player2

;;; ============================================================
;;; Mockingboard Player - A,X = song
;;; By @cybernesto
;;; Used with permission

;;; https://github.com/cybernesto/electric-mock/blob/master/src/MOCKINGDUET.S

.proc PlayerMockingboard
;;; *ELECTRIC DUET MUSIC PLAYER FOR THE MOCKINGBOARD
;;; *COPYRIGHT 2014 CYBERNESTO

CHN             := $1D
SONG            := $1E

LEFTCHN         = $00
RIGHTCHN        = $02
ENAREG          = $07
VOL_A           = $08
VOL_B           = $09
TONE            = $06
DURATION        = $08

        stax    SONG

        ;;         ORG $300

        JSR INIT
        JSR RESET
        JSR ENACHN
        JMP LOOP

SETVOL:
NEXT:   LDA SONG
        CLC
        ADC #$03
        STA SONG
        BCC LOOP
        INC SONG+1
LOOP:   LDY #$00
        LDA (SONG),Y
        CMP #$01
        BEQ SETVOL
        BPL SETNOTE             ;SET DURATION
END:    JSR RESET
        RTS

SETNOTE:
        STA DURATION
        LDA #LEFTCHN
SEND:   STA CHN
        patch1 := *+2
        STA $C401
        JSR SETREG1
        INY
        LDA (SONG),Y
        BEQ SKIP                ;IF 0 KEEP LTTSA
        JSR CONVFREQ
SKIP:   LDA TONE
        patch2 := *+2
        STA $C401
        JSR WRDATA1
        INC CHN
        LDA CHN
        patch3 := *+2
        STA $C401
        JSR SETREG1
        LDA TONE+1
        patch4 := *+2
        STA $C401
        JSR WRDATA1
        LDA #RIGHTCHN
        STA CHN
        CPY #$02
        BNE SEND
        LDX DURATION
W1:     LDY TEMPO
W2:     DEC TEMP
        BNE W2
        DEY
        BNE W2
        DEX
        BNE W1
        BIT $C000
        BMI END
        JMP NEXT

CONVFREQ:
        LDX OCTAVE
        INX
        PHA
        LDA #$00
        STA TONE+1
        PLA
DECOCT: DEX
        BMI LOBYTE
        ASL
        ROL TONE+1
        JMP DECOCT
LOBYTE: STA TONE
        RTS


RESET:  LDA #$00
        patch5 := *+2
        STA $C400
        patch6 := *+2
        STA $C480
        LDA #$04
        patch7 := *+2
        STA $C400
        patch8 := *+2
        STA $C480
        RTS

INIT:   LDA #$FF
        patch9 := *+2
        STA $C403
        patch10 := *+2
        STA $C483
        LDA #$07
        patch11 := *+2
        STA $C402
        patch12 := *+2
        STA $C482
        RTS

SETREG1:
        LDA #$07
        patch13 := *+2
        STA $C400
        LDA #$04
        patch14 := *+2
        STA $C400
        RTS

WRDATA1:
        LDA #$06
        patch15 := *+2
        STA $C400
        LDA #$04
        patch16 := *+2
        STA $C400
        RTS

ENACHN: LDA #ENAREG
        patch17 := *+2
        STA $C401
        JSR SETREG1
        LDA #%00111100
        patch18 := *+2
        STA $C401
        JSR WRDATA1
        LDA #VOL_A
        patch19 := *+2
        STA $C401
        JSR SETREG1
        LDA #$0F
        patch20 := *+2
        STA $C401
        JSR WRDATA1
        LDA #VOL_B
        patch21 := *+2
        STA $C401
        JSR SETREG1
        LDA #$0F
        patch22 := *+2
        STA $C401
        JSR WRDATA1
        RTS

OCTAVE: .byte 1
TEMPO:  .byte 8
TEMP:   .byte 0

.proc ScanSlots
        ptr := $06
        copy16  #$C700, ptr
probe:  CALL    WithInterruptsDisabled, AX=#DetectMockingboard
    IF CS
        ;; Found
        lda     ptr+1
        .repeat 22, i
        sta     .ident(.sprintf("patch%d",i+1))
        .endrepeat
        rts                     ; C=1 is found
    END_IF

        dec     ptr+1
        lda     ptr+1
        cmp     #$C0
        bne     probe

        RETURN  C=0             ; C=0 is not found
.endproc ; ScanSlots
.endproc ; PlayerMockingboard
FindMockingboard := PlayerMockingboard::ScanSlots

;;; ============================================================
;;; The Cricket! Player
;;; By @cybernesto
;;; Used with permission

;;; https://github.com/cybernesto/electric-mock/blob/master/src/CRICKETDUET.S

.proc PlayerCricket
;;; *ELECTRIC DUET MUSIC PLAYER FOR THE CRICKET

CHN             := $1D
SONG            := $1E

LEFTCHN         = $10
RIGHTCHN        = $20
ENAREG          = $07
VOL_A           = $08
TONE            = $06
DURATION        = $08

ACIACMD2        := $C0AA
ACIACTL2        := $C0AB
ACIAST2         := $C0A9
ACIARXTX2       := $C0A8

        stax    SONG

        ;; ORG $300

        JSR INIT
        JSR RESET
        LDA #LEFTCHN
        STA CHN
        JSR ENACHN
        LDA #RIGHTCHN
        STA CHN
        JSR ENACHN
        JMP LOOP

SETVOL: NOP
NEXT:   LDA SONG
        CLC
        ADC #$03
        STA SONG
        BCC LOOP
        INC SONG+1
LOOP:   LDY #$00
        LDA (SONG),Y
        CMP #$01
        BEQ SETVOL
        BPL SETNOTE             ;SET DURATION
END:    JSR RESET
        RTS

SETNOTE:
        STA DURATION
        LDA #LEFTCHN
SEND:   STA CHN
        JSR OUT
        INY
        LDA (SONG),Y
        BEQ SKIP                ;IF 0 KEEP LTTSA
        JSR CONVFREQ
SKIP:   LDA TONE
        JSR OUT
        INC CHN
        LDA CHN
        JSR OUT
        LDA TONE+1
        JSR OUT
        LDA #RIGHTCHN
        STA CHN
        CPY #$02
        BNE SEND
        LDX DURATION
W1:     LDY TEMPO
W2:     DEC TEMP
        BNE W2
        DEY
        BNE W2
        DEX
        BNE W1
        BIT $C000
        BMI END
        JMP NEXT

CONVFREQ:
        LDX OCTAVE
        INX
        PHA
        LDA #$00
        STA TONE+1
        PLA
DECOCT: DEX
        BMI LOBYTE
        ASL
        ROL TONE+1
        JMP DECOCT
LOBYTE: STA TONE
        RTS


INIT:   LDA #$0B
        STA ACIACMD2
        LDA #$9E
        STA ACIACTL2
        RTS

OUT:    PHA                     ;SAVE BYTE TO SEND OUT
WT:     LDA ACIAST2             ;READ STATUS OF SERIAL PORT
        AND #$10                ;SEE IF IT'S READY TO RECEIVE A BYTE
        BEQ WT                  ;NOT READY, WAIT
        PLA                     ;REGET BYTE TO SEND OUT
        STA ACIARXTX2           ;SEND IT
        RTS

IN:     LDA ACIAST2             ;IS THERE A BYTE TO GET YET?
        AND #$08
        BEQ IN                  ;NOPE, WAIT FOR IT
        LDA ACIARXTX2           ;GET INCOMING BYTE
        RTS

RESET:  LDA #$A1
        JSR OUT
        RTS

ENACHN: LDA #ENAREG
        ORA CHN
        JSR OUT
        LDA #%00111110
        JSR OUT
        LDA #VOL_A
        ORA CHN
        JSR OUT
        LDA #$0F
        JSR OUT
        RTS

OCTAVE: .byte   1
TEMPO:  .byte   8
TEMP:   .byte   0
.endproc ; PlayerCricket

.proc FindTheCricket
        ptr := $06
        copy16  #$C200, ptr
        TAIL_CALL WithInterruptsDisabled, AX=#DetectMockingboard
.endproc ; FindTheCricket


;;; ============================================================

        .include "../lib/with_interrupts_disabled.s"
        .include "../lib/detect_mockingboard.s"
        .include "../lib/detect_thecricket.s"
        .include "../lib/normfast.s"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
