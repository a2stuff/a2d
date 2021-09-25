;;; ============================================================
;;; SHOW.DUET.FILE - Desk Accessory
;;;
;;; Electric Duet by Paul Lutus
;;; Player by Alexander Patalenski
;;;
;;; Preview accessory for playing Electric Duet files.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "show.duet.file.res"

        .include "apple2.inc"
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
;;;          | IO Buffer | |Win Tables |
;;;  $1C00   +-----------+ |           |
;;;  $1B00   |           | +-----------+
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          | DA        | | DA (Copy) |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

;;; There is not enough room in the DA load area to hold 6k of audio
;;; data. A 10k buffer is available in DeskTop itself, in an area
;;; that can be restored after use.
data_buf        := OVERLAY_10K_BUFFER
kReadLength      = kOverlay10KBufferSize

        .org DA_LOAD_ADDRESS

da_start:
        jmp     entry

;;; ============================================================

pathbuf:        .res    kPathBufferSize, 0

        DEFINE_OPEN_PARAMS open_params, pathbuf, DA_IO_BUFFER
        DEFINE_READ_PARAMS read_params, data_buf, kReadLength
        DEFINE_CLOSE_PARAMS close_params

;;; ============================================================
;;; Get filename from DeskTop

.proc entry
        INVOKE_PATH := $220
        lda     INVOKE_PATH
    IF_EQ
        rts
    END_IF
        COPY_STRING INVOKE_PATH, pathbuf

        ;; Extract filename
        ldy     pathbuf
:       lda     pathbuf,y       ; find last '/'
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       ldx     #0
:       lda     pathbuf+1,y     ; copy filename
        sta     name_buf+1,x
        inx
        iny
        cpy     pathbuf
        bne     :-
        stx     name_buf

        jmp     load_file_and_run_da
.endproc

;;; ============================================================
;;; Load the file

.proc load_file_and_run_da

        ;; TODO: Ensure there's enough room, fail if not

        ;; --------------------------------------------------
        ;; Load the file

        jsr     JUMP_TABLE_CUR_WATCH
        JUMP_TABLE_MLI_CALL OPEN, open_params
        beq     :+
        jsr     JUMP_TABLE_CUR_POINTER
        rts
:       lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL READ, read_params ; TODO: Check for error
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        jsr     JUMP_TABLE_CUR_POINTER

        ;; TODO: Try to verify that this is a duet file

        ;; --------------------------------------------------
        ;; Copy the DA code and loaded data to AUX

        copy16  #da_start, STARTLO
        copy16  #da_end, ENDLO
        copy16  #da_start, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE

        ;; --------------------------------------------------
        ;; Run the DA from Aux, back to Main when done

        sta     RAMRDON
        sta     RAMWRTON
        jsr     init
        sta     RAMRDOFF
        sta     RAMWRTOFF

exit:   lda     #kDynamicRoutineRestore5000
        jmp     JUMP_TABLE_RESTORE_OVL

.endproc

;;; ============================================================

kDAWindowId     = 61
kDAWidth        = 310
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
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

        DEFINE_RECT_INSET frame_rect1, 4, 2, kDAWidth, kDAHeight
        DEFINE_RECT_INSET frame_rect2, 5, 3, kDAWidth, kDAHeight

penXOR: .byte   MGTK::penXOR

name_buf:
        .res    16, 0

        DEFINE_LABEL playing, res_string_playing, 20, 18
        DEFINE_LABEL credit1, res_string_credit1, 20, 34
        DEFINE_LABEL credit2, res_string_credit2, 20, 45
        DEFINE_LABEL instructions, res_string_instructions, 20, 62

;;; ============================================================

.proc init
        MGTK_CALL MGTK::OpenWindow, winfo

        ;; --------------------------------------------------
        ;; Draw the window contents

        MGTK_CALL MGTK::SetPort, winfo::port
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, frame_rect1
        MGTK_CALL MGTK::FrameRect, frame_rect2

        MGTK_CALL MGTK::MoveTo, playing_label_pos
        param_call DrawString, playing_label_str
        param_call DrawString, name_buf

        MGTK_CALL MGTK::MoveTo, credit1_label_pos
        param_call DrawString, credit1_label_str

        MGTK_CALL MGTK::MoveTo, credit2_label_pos
        param_call DrawString, credit2_label_str

        MGTK_CALL MGTK::MoveTo, instructions_label_pos
        param_call DrawString, instructions_label_str

        MGTK_CALL MGTK::FlushEvents

        ;; --------------------------------------------------
        ;; Play the music

        jsr     play_file

        ;; --------------------------------------------------
        ;; Close the window

        MGTK_CALL MGTK::CloseWindow, winfo
        jsr     clear_updates

        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

.proc clear_updates
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_CLEAR_UPDATES
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

.proc play_file
        sta     RAMRDOFF
        sta     RAMWRTOFF
        ldax    #data_buf
        bit     KBDSTRB         ; player will stop on keypress
        jsr     player
        bit     KBDSTRB         ; swallow the keypress
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

;;; ============================================================
;;; Player

;;; Electric Duet player by Alex Patalenski
;;; https://www.reddit.com/r/apple2/comments/pue775/improved_electric_duet_player_by_alex_patalenski/

.proc player

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
        jsr     sub
        sta     l30+1
        sta     l37+1
        stx     l31+1
        stx     l38+1

        ldx     #$01
        jsr     sub
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

.proc sub
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
.endproc

.endproc

;;; ============================================================

        .include "../lib/drawstring.s"

;;; ============================================================

da_end:
.assert * < WINDOW_ENTRY_TABLES, error, .sprintf("DA too big (at $%X)", *)
        ;; I/O Buffer starts at MAIN 7168
        ;; ... but entry tables start at AUX 6912
