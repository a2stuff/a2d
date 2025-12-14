;;; ============================================================
;;; SOUNDS - Desk Accessory
;;;
;;; A control panel offering selecting different alert sounds.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "sounds.res"

        .include "apple2.inc"
        .include "opcodes.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
        .include "../toolkits/lbtk.inc"
        .include "../lib/alert_dialog.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================
;;; Memory map
;;;
;;;               Main            Aux
;;;          :             : :             :
;;;          |             | |             |
;;;          | DHR         | | DHR         |
;;;  $2000   +-------------+ +-------------+
;;;          | IO Buffer   | |             |
;;;  $1C00   +-------------+ |             |
;;;          | write_buffer| |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          | stub & save | | GUI code &  |
;;;          | settings    | | resource    |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;
;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

.proc AuxEntry
        jsr     Init
        RETURN  A=dialog_result
.endproc ; AuxEntry

;;; High bit set when anything changes.
dialog_result:
        .byte   0

.proc MarkDirty
        lda     #$80
        ora     dialog_result
        sta     dialog_result
        rts
.endproc ; MarkDirty

;;; Cancel any changes, restore saved proc
.proc DoCancel
        copy8   #$00, dialog_result
        CALL    InstallIndex, A=original_index
        jmp     Exit
.endproc ; DoCancel

;;; ============================================================
;;; Resources
;;; ============================================================

kDAWindowId     = $80
kDAWidth        = 300
kDAHeight       = 100
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

str_title:
        PASCAL_STRING res_string_window_title

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::dialog_box
title:          .addr   str_title
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
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        DEFINE_RECT_FRAME frame_rect, kDAWidth, kDAHeight

;;; ============================================================

        kMarginX = 18
        kMarginY = 10
        kTextHeight = kSystemFontHeight

        DEFINE_BUTTON ok_button, kDAWindowId, res_string_button_ok, kGlyphReturn, kDAWidth - kMarginX - kButtonWidth, kDAHeight - kMarginY - kButtonHeight

        DEFINE_BUTTON cancel_button, kDAWindowId, res_string_button_cancel, res_string_button_cancel_shortcut, kMarginX, kDAHeight - kMarginY - kButtonHeight

        DEFINE_LABEL alert_sound, res_string_label_alert, kMarginX, kMarginY+kTextHeight
        kLabelWidth = 105

        kScrollBarWidth = 20
        kListRows = 6
        kListLeft = kMarginX + kLabelWidth
        kListTop = kMarginY
        kListRight  = kDAWidth - kMarginX - kScrollBarWidth
        kListHeight = kListItemHeight * kListRows - 1
        kListBottom = kListTop + kListHeight

        DEFINE_RECT listbox_rect, kListLeft, kListTop, kListRight, kListBottom

;;; ============================================================
;;; List Box
;;; ============================================================

kListBoxWindowId = kDAWindowId + 1

        DEFINE_LIST_BOX_WINFO winfo_listbox, \
                kListBoxWindowId, \
                kListLeft + kDALeft, \
                kListTop + kDATop, \
                kListRight - kListLeft, \
                kListHeight, \
                DEFAULT_FONT
        DEFINE_LIST_BOX listbox_rec, winfo_listbox, \
                kListRows, kNumSounds, \
                DrawListEntryProc, OnListSelectionChange, OnListSelectionChange
        DEFINE_LIST_BOX_PARAMS lb_params, listbox_rec

;;; ============================================================

str_buzz:       PASCAL_STRING res_string_name_prodos_buzz
str_bonk:       PASCAL_STRING res_string_name_iigs_bonk
str_bell:       PASCAL_STRING res_string_name_control_g_bell
str_silent:     PASCAL_STRING res_string_name_silent
str_awbeep:     PASCAL_STRING res_string_name_apple_writer_ii
str_dazzledraw: PASCAL_STRING res_string_name_dazzle_draw
str_koala:      PASCAL_STRING res_string_name_koala_illustrator
str_816paint:   PASCAL_STRING res_string_name_816_paint
str_panic1:     PASCAL_STRING res_string_name_apple_panic_1
str_panic2:     PASCAL_STRING res_string_name_apple_panic_2
str_bombdrop:   PASCAL_STRING res_string_name_bombdrop
str_detonate:   PASCAL_STRING res_string_name_detonate
str_gorgon:     PASCAL_STRING res_string_name_gorgon
str_versiontel: PASCAL_STRING res_string_name_versiontel
str_aal_swoop:  PASCAL_STRING res_string_name_assembly_line_swoop
str_aal_blast:  PASCAL_STRING res_string_name_assembly_line_laser
str_aal_bell:   PASCAL_STRING res_string_name_assembly_line_bell
str_aal_klaxon: PASCAL_STRING res_string_name_assembly_line_klaxon
str_obn_whopi:  PASCAL_STRING res_string_name_obnoxious_whopidoop
str_obn_phasor: PASCAL_STRING res_string_name_obnoxious_phasor
str_obn_gleep:  PASCAL_STRING res_string_name_obnoxious_gleep
        kNumSounds = 21

name_table:
        .addr   str_buzz, str_bonk, str_bell, str_silent, str_awbeep
        .addr   str_dazzledraw, str_koala, str_816paint, str_panic1
        .addr   str_panic2, str_bombdrop, str_detonate, str_gorgon
        .addr   str_versiontel, str_aal_swoop, str_aal_blast
        .addr   str_aal_bell, str_aal_klaxon, str_obn_whopi
        .addr   str_obn_phasor, str_obn_gleep
        ASSERT_ADDRESS_TABLE_SIZE name_table, kNumSounds

proc_table:
        .addr   Buzz, Bonk, ClassicBeep, Silent, AwBeep, DazzleDraw
        .addr   Koala, Paint816, Panic1, Panic2, Bombdrop, Detonate, Gorgon
        .addr   VersionTel, AALLaserSwoop, AALLaserBlast, AALSCBell
        .addr   AALKlaxon, OBNWhopi, OBNPhasor, OBNGleep
        ASSERT_ADDRESS_TABLE_SIZE proc_table, kNumSounds

original_index:
        .byte   $FF

;;; ============================================================

        .include "../lib/event_params.s"

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport_win
.endparams

grafport_win:       .tag    MGTK::GrafPort

;;; ============================================================
;;; Dialog Logic
;;; ============================================================

.proc Init
        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow

        MGTK_CALL MGTK::OpenWindow, winfo_listbox
        LBTK_CALL LBTK::Init, lb_params

        jsr     SearchForCurrent
        ; keep it around in case we want to cancel
        sta     original_index
        sta     lb_params::new_selection
        LBTK_CALL LBTK::SetSelection, lb_params

        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        jeq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        jmp     InputLoop
.endproc ; InputLoop

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo_listbox
        MGTK_CALL MGTK::CloseWindow, winfo
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Exit

;;; ============================================================

.proc HandleKey
        lda     event_params::key
        ldx     event_params::modifiers

    IF A IN #CHAR_UP, #CHAR_DOWN
        sta     lb_params::key
        stx     lb_params::modifiers
        LBTK_CALL LBTK::Key, lb_params
        jmp     InputLoop
    END_IF

    IF X <> #0
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        jeq     Exit
        jmp     InputLoop
    END_IF

    IF A = #CHAR_ESCAPE
        BTK_CALL BTK::Flash, cancel_button
        jmp     DoCancel
    END_IF

    IF A = #CHAR_RETURN
        BTK_CALL BTK::Flash, ok_button
        jmp     Exit
    END_IF

        jmp     InputLoop
.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        MGTK_CALL MGTK::FindWindow, findwindow_params

        lda     findwindow_params::window_id
    IF A = #kDAWindowId
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        beq     HandleDialogClick
        jmp     InputLoop
    END_IF

    IF A = #kListBoxWindowId
        lda     findwindow_params::which_area
      IF A = #MGTK::Area::content
        COPY_STRUCT event_params::coords, lb_params::coords
        LBTK_CALL LBTK::Click, lb_params
        jmp     InputLoop
      END_IF
    END_IF

        jmp     InputLoop
.endproc ; HandleDown

;;; ============================================================

.proc HandleDialogClick
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; ----------------------------------------

        copy8   winfo::window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, ok_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, ok_button
        jeq     Exit
        jmp     InputLoop
    END_IF

        MGTK_CALL MGTK::InRect, cancel_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, cancel_button
        jeq     DoCancel
        jmp     InputLoop
    END_IF

        ;; ----------------------------------------

        jmp     InputLoop
.endproc ; HandleDialogClick

;;; ============================================================

.proc InstallIndex
        ptr := $06

        ;; Look up routine
        asl
        tax
        copy16  proc_table,x, ptr

        ;; Put routine into location
        jsr     Install

        rts

.proc Install
        ldax    ptr
        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2
        stax    ptr

        .assert kBellProcLength <= 128, error, "Can't BPL this loop"
        ldy     #kBellProcLength - 1
    DO
        copy8   (ptr),y, BELLDATA,y
        dey
    WHILE POS

        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        rts
.endproc ; Install

.endproc ; InstallIndex

;;; ============================================================

.proc PlayIndex
        jsr     InstallIndex

        ;; Play it
        JSR_TO_MAIN JUMP_TABLE_BELL

        jmp     MarkDirty
.endproc ; PlayIndex

;;; ============================================================

.proc SetPortForDialog
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured.
        MGTK_CALL MGTK::SetPort, grafport_win
        rts
.endproc ; SetPortForDialog

;;; ============================================================

.proc DrawWindow

        ;; Dialog Box
        jsr     SetPortForDialog

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::MoveTo, alert_sound_label_pos
        MGTK_CALL MGTK::DrawString, alert_sound_label_str

        BTK_CALL BTK::Draw, cancel_button
        BTK_CALL BTK::Draw, ok_button

        rts
.endproc ; DrawWindow

;;; ============================================================

.proc SearchForCurrent
        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2

        CALL    CRC, AX=#BELLDATA, Y=#kChecksumLength
        sta     crc_lo
        stx     crc_hi

        copy8   #0, index

        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE

        asl
        tay
        CALL    CRC, {AX=proc_table,y}, Y=#kChecksumLength

        crc_lo := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     next
        crc_hi := *+1
        cpx     #SELF_MODIFIED_BYTE
        bne     next

        ;; Match!
        lda     index
        jmp     finish

next:   inc     index
        lda     index
        cmp     listbox_rec::num_items
        bne     loop

        ;; Not Found
        lda     #$FF
        FALL_THROUGH_TO finish

finish: sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1
        rts

.endproc ; SearchForCurrent


;;; ============================================================

;;; Inputs: A,X = address, Y = number of bytes (<=128)
.proc CRC
        stax    addr

        copy8   #0, hi
        dey

    DO
        addr := *+1
        eor     SELF_MODIFIED,y
        rol                     ; shift left 16
        rol     hi
        php                     ; but stash the high bit that
        ror                     ; was shifted out, and shift
        plp                     ; it back in as the new low bit
        rol

        dey
    WHILE POS

        hi := *+1
        ldx     #SELF_MODIFIED_BYTE
        rts
.endproc ; CRC

;;; ============================================================
;;; Sound Routines
;;; ============================================================

;;; Wrappers for sound procs, which place the routine at the
;;; correct location and verify the length.

kChecksumLength = 16

.macro SOUND_PROC name
        .define __CURRENT_SOUND_PROC name
.proc name
        .pushorg ::BELLPROC
.endmacro

.macro END_SOUND_PROC
        .poporg
.endproc ; name
        .assert .sizeof(__CURRENT_SOUND_PROC) <= kBellProcLength, error, "Sound proc too large"
        .assert .sizeof(__CURRENT_SOUND_PROC) >= kChecksumLength, error, "Sound proc too small"
        .undefine __CURRENT_SOUND_PROC
.endmacro

;;; ============================================================
;;; Sound Routine: ProDOS Buzz

Buzz := *
        .include "../lib/default_sound.s"

;;; ============================================================
;;; Sound Routine: Control-G Bell

SOUND_PROC ClassicBeep
        ;; Based on Apple II Monitor ROMs

bell1:  lda     #$40
        jsr     wait
        ldy     #$C0
bell2:  lda     #$0C
        jsr     wait
        lda     SPKR
        dey
        bne     bell2
        rts

wait:   sec
wait2:  pha
wait3:  sbc     #1
        bne     wait3
        pla
        sbc     #1
        bne     wait2
        rts

END_SOUND_PROC


;;; ============================================================
;;; Sound Routine: IIgs "Bonk"

;;; https://groups.google.com/g/comp.sys.apple2/c/bhDLdYXnmnE/m/I2-OCScyZaAJ
SOUND_PROC Bonk

;;; **********************************************************
;;; *                                                        *
;;; *         "Bonk" sound routine for Apple II              *
;;; *                                                        *
;;; *       Copyright Michael J. Mahon, 12/08/2009           *
;;; *                                                        *
;;; *  Uses 21.3kHz PWM to synthesize a squarewave sound of  *
;;; *  diminishing volume, mimicking the "bonk" IIgs sound.  *
;;; *                                                        *
;;; *  The PWM pulses are generated in 46-cycle loops, with  *
;;; *  the high duty cycle pulses varying between 7 cycles   *
;;; *  and 37 cycles, and the low duty cycle pulses always   *
;;; *  7 cycles.                                             *
;;; *                                                        *
;;; *  Sound generator begins at maximum duty cycle (volume) *
;;; *  and diminshes by 1/15 on each volume step, until the  *
;;; *  volume has been reduced to zero (equal high and low   *
;;; *  duty cycle half-periods).                             *
;;; *                                                        *
;;; *  Input parameters are:                                 *
;;; *   'hperiod'  = Half-period of tone in 46-cycle samples *
;;; *   'vperiods' = Tone (full) periods per volume step     *
;;; *                                                        *
;;; *  Since 15 volume steps are required to diminish the    *
;;; *  volume to zero, the total sound duration is 15 times  *
;;; *  'vperiods' cycles of the generated tone.              *
;;; *                                                        *
;;; **********************************************************

;;; * Page zero data

;;; hperiod  :=   $06    ; Half-period in samples (<129) (Inlined to save bytes)
vperiods :=   $07        ; Periods until vol step
vctr     :=   $08        ; Volume step counter

;;; * Hardware definitions

SPKR     :=   $C030      ; Apple II speaker toggle

;;; Added to initialize ZP addr
        kHPeriod  = 83
        kVPeriods = 2

        lda     #kVPeriods
        sta     vperiods

;;; * Initialize

BONK:     lda   #15        ; Init to 15 steps
          sta   vctr       ;  of dimishing volume.
          lda   #0         ; Init modified branches.
          sta   vinc+1
          lda   #(hiduty-vdec-2)&$ff ; Point to hiduty
          sta   vdec+1
          ldy   #kHPeriod  ; Samples in half-period
          dey              ;  minus 1.
          tya              ; Save half-period count.
          ldx   vperiods   ; Countdown to volume step.

;;; * Generate high duty-cycle half of squarewave

          nop              ; String of NOPs is target
          nop              ;  of varying 'vdec' branch.
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
hidutym2:       nop
hiduty: sta   SPKR       ; Toggle speaker hi
vinc:   bpl   *+2        ; <modified: 0..15> (always)
          nop              ; String of NOPs is target
          nop              ;  of varying 'vinc' branch.
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          sta   SPKR       ; Toggle speaker lo
          dey              ; Count down half-period
vdec:   bpl   hiduty     ; <modified>

;;; * Generate first low duty-cycle half cycle of squarewave

          sta   SPKR       ; Toggle speaker hi
          bpl   *+2        ; (always)
          sta   SPKR       ; Toggle speaker lo
          dex              ; Time to dec volume?
          bne   dnostep    ; -No, delay then rejoin.
          dec   vctr       ; -Yes, volume = zero?
          beq   ret        ; -Yes, return.
          dec   vdec+1     ; -No, decrease duty
          inc   vinc+1     ;       cycle (volume).
          ldx   vperiods   ; Reload vol step counter
nostep:   tay              ; Reload half-period ctr
          bne   lodutym4   ; >0, gen more low pulses.
          beq   hidutym2   ; (always)

lodutym6:       nop              ; Kill 2 cycles
lodutym4:       nop              ; Kill 2 cycles
          nop              ; Kill 2 cycles
          sta   SPKR       ; Toggle speaker hi
          bpl   *+2        ; (always)
          sta   SPKR       ; Toggle speaker lo
          jsr   ret        ; Kill 12
          jsr   ret        ; Kill 12
          dey              ; Half-period expired?
          bpl   lodutym6   ; -No, keep looping.
          tay              ; -Yes, reset for hi loop
          bpl   hidutym2   ; (always)

dnostep:        jsr   ret        ; Kill 18 cycles
          nop
          nop
          nop
          bne   nostep     ;  and rejoin...

ret:    rts

END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: DazzleDraw's alert sound

SOUND_PROC DazzleDraw
        ldy     #$20
:       lda     #$1C
        sta     SPKR
        jsr     L9843
        dey
        bne     :-
        rts

L9843:
        sec
        pha
:       sbc     #$01
        bne     :-
        pla
        sbc     #$01
        bne     L9843
        rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Apple Writer ]['s alert sound

SOUND_PROC AwBeep
        lda     #$80            ; STRAIGHT FROM APPLE WRITER ][
        jsr     beep1           ; (CANNIBALISM IS THE SINCEREST
        lda     #$a0            ; FORM OF FLATTERY)
beep1:  ldy     #$80
beep2:  tax
beep3:  dex
        bne     beep3
        bit     $c030           ; WHAP SPEAKER
        dey
        bne     beep2
nobeep: rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Koala Illustrator's alert sound

SOUND_PROC Koala
        ;; From Koala Illustrator
        ;; $63B2

        ldy     #$60
        bne     L63BD
        ldy     #$08
        lda     L634F
        beq     L63C9
L63BD:  tya
        jsr     L63CA
        eor     #$FF
        jsr     L63CA
        dey
        bne     L63BD
        rts

L63CA:  tax
L63CB:  dex
        bne     L63CB
        bit     SPKR
L63C9:  rts

L634F:  .byte   $FF

END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: 816/Paint's alert sound

SOUND_PROC Paint816
        ;; $E5F6
        ldy     #$40
        ldx     #$15
        jsr     LE601
        ldy     #$30
        ldx     #$1A

LE601:  php
        sei
LE603:  txa
        jsr     LE612
        bit     SPKR
        dey
        bne     LE603
        plp
        rts

LE612:  sec
LE613:  pha
LE614:  sbc     #$01
        bne     LE614
        pla
        sbc     #$01
        bne     LE613
        rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Apple Panic 1

SOUND_PROC Panic1
        ;; Played during intro to 'Apple Panic'
        ;; Adapted for A2D by @frankmilliron

        lda     #$C0
        sta     $14
        lda     #$01
        sta     $15
core:   jsr     part2
        inc     $14
        bne     core
        rts
part2:  lda     $14
        eor     #$FF
        sta     $12
loop1:  ldx     $15
loop2:  ldy     $14
        lda     SPKR
loop3:  iny
        bne     loop3
        dex
        bne     loop2
        dec     $12
        bne     loop1
        rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Apple Panic 2

SOUND_PROC Panic2
        ;; Played during intro to 'Apple Panic'
        ;; Adapted for A2D by @frankmilliron

        ldx     #$06
loop1:  lda     #$60
        sta     $14
loop2:  ldy     $14
        lda     SPKR
loop3:  dey
        bne     loop3
        dec     $14
        bne     loop2
        lda     #$40
        sta     $14
        eor     #$FF
        sta     $15
loop4:  ldy     $15
        lda     SPKR
loop5:  iny
        bne     loop5
        dec     $15
        dec     $14
        bne     loop4
        dex
        bne     loop1
        rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Bombdrop

SOUND_PROC Bombdrop
        ;; From ftp.apple.asimov.net/images/sound/ripped_off_routines.zip
        ;; BRUN BOMBDROP(CALL3091)
        ;; Adapted for A2D by @frankmilliron

        LDA     #$00
        STA     $FF
        LDA     #$FF
        STA     $FE
loop1:  LDA     #$00
        STA     SPKR
        INC     SPKR
        DEC     SPKR
        LDY     #$05
loop2:  LDX     $FF
loop3:  DEX
        BNE     loop3
        DEY
        BEQ     loop4
        JMP     loop2
loop4:  DEC     $FE
        BEQ     exit
        INC     $FF
        JMP     loop1
exit:   RTS
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Detonate

SOUND_PROC Detonate
        ;; Played during intro to 'Short Circuit' by David H. Schroeder
        ;; Adapted for A2D by @frankmilliron

        ldx     #6-1
move:   lda     patch, x
        sta     $00, x
        dex
        bne     move       ; setup initial conditions

        SEC
        INC     $03
        LDX     $04
L9483:  ROL     $00
        ROL     $01
        TXA
        BEQ     L948B
        DEX
L948B:  BNE     L9497
        BCC     L9497
        LDX     thirty
        LDA     $C000,X
        LDX     $04
L9497:  ROR     A
        ROR     A
        ROR     A
        EOR     $01
        ASL     A
        ASL     A
        ASL     A
        PHP
        LDA     $05
        BEQ     L94B8
        DEY
        BNE     L94B8
        TAY
        BMI     L94B3
        LDA     $04
        BEQ     L94B8
        DEC     $04
        TYA
        BNE     L94B8
L94B3:  INC     $04
        AND     #$7F
        TAY
L94B8:  PLP
        DEC     $02
        BNE     L9483
        DEC     $03
        BNE     L9483
        RTS
thirty: .byte   $30
patch:  .byte   $00,$08,$00,$50,$FF,$FF
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Gorgon

SOUND_PROC Gorgon
        ;; Played during intro to 'Gorgon' by Nasir Gabelli
        ;; Adapted for A2D by @frankmilliron

        lda     #0
        jsr     wait
        nop
        ldx     #0
loop1:  lda     SPKR
        txa
loop2:  clc
        adc     #1
        bne     loop2
        lda     SPKR
        txa
loop3:  nop
        sec
        sbc     #1
        bne     loop3
        inx
        cpx     #$C0
        bne     loop1
        rts

wait:   sec
wait2:  pha
wait3:  sbc     #1
        bne     wait3
        pla
        sbc     #1
        bne     wait2
        rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: VersionTel

SOUND_PROC VersionTel
        ;; Alert sound from VersionSoft's VersionTel
        ;; Adapted for A2D by @frankmilliron

        ldy     #$5A
l9632:  tya
        jsr     l964c
        pha
        pha
        pha
        jsr     l0815
        pla
        pla
        pla
        eor     #$FF
        jsr     l964c
        dey
        bne     l9632
        rts

l964c:  tax
l964d:  dex
        bne     l964d
        bit     SPKR
        rts

l0815:  jmp     l0818
l0818:  rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Laser Swoop from Apple Assembly Line

;;; http://www.txbobsc.com/aal/1981/aal8102.html#a1
SOUND_PROC AALLaserSwoop
;;; ---------------------------------
SPEAKER     := $C030
;;; ---------------------------------
PULSE_COUNT := $00
PULSE_WIDTH := $01
SWOOP_COUNT := $02
;;; ---------------------------------
SWOOP:  LDA #1                  ; ONE PULSE AT EACH WIDTH
        STA PULSE_COUNT
        LDA #160                ; START WITH MAXIMUM WIDTH
;;; (ALSO TRY VALUES OF 40, 80, 128, AND 160.)
        STA PULSE_WIDTH
@l1:    LDY PULSE_COUNT
@l2:    LDA SPEAKER             ; TOGGLE SPEAKER
        LDX PULSE_WIDTH
@l3:    DEX                     ; DELAY LOOP FOR ONE PULSE
        BNE @l3
        DEY                     ; LOOP FOR NUMBER OF PULSES
        BNE @l2                 ; AT EACH PULSE WIDTH
        DEC PULSE_WIDTH         ; SHRINK PULSE WIDTH
        BNE @l1                 ; TO LIMIT OF ZERO
        RTS
;;; ---------------------------------
;;; MULTI-SWOOPER
;;; ---------------------------------
SWOOP2: LDA #10                 ; NUMBER OF SWOOPS
        STA SWOOP_COUNT
@l1:    JSR SWOOP
        DEC SWOOP_COUNT
        BNE @l1
        RTS
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Laser Blast from Apple Assembly Line

;;; http://www.txbobsc.com/aal/1981/aal8102.html#a1
SOUND_PROC AALLaserBlast
;;; ---------------------------------
;;;       ANOTHER LASER BLAST
;;; ---------------------------------
SPEAKER     := $C030
;;; ---------------------------------
BLAST:  LDY #4                  ; NUMBER OF SHOTS (NB: was 10 in original)
@l1:    LDX #64                 ; PULSE WIDTH OF FIRST PULSE
@l2:    TXA                     ; START A PULSE WITHIN A SHOT
@l3:    DEX                     ; DELAY FOR ONE PULSE
        BNE @l3
        TAX
        LDA SPEAKER             ; TOGGLE SPEAKER
        INX
        CPX #192                ; PULSE WIDTH OF LAST PULSE
        BNE @l2
        DEY                     ; FINISHED SHOOTING?
        BNE @l1                 ; NO
        RTS
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: "My Own Little Bell" from Apple Assembly Line

;;; https://www.txbobsc.com/aal/1982/aal8206.html#a7
SOUND_PROC AALSCBell
;;; ---------------------------------
;;; MY OWN LITTLE BELL
;;; --------------------------------
SPEAKER := $C030
;;; --------------------------------
SC_BELL:
        LDX #50
@l1:    LDA #14
        JSR MON_DELAY
        LDA SPEAKER
        LDA #10
        JSR MON_DELAY
        LDA SPEAKER
        LDA #6
        JSR MON_DELAY
        LDA SPEAKER
        DEX
        BNE @l1
        RTS

MON_DELAY:
wait:           sec
wait2:          pha
wait3:          sbc     #1
        bne     wait3
        pla
        sbc     #1
        bne     wait2
        rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Klaxon from Apple Assembly Line

;;; https://www.txbobsc.com/aal/1988/aal8805.html#a3
SOUND_PROC AALKlaxon
;;; --------------------------------
;;;    from Robert C. Moore, Laurel, Maryland.
;;; --------------------------------
DURATION1  := 0
DURATION2  := 1
PITCH      := 2
;;; --------------------------------
SPEAKER    := $C030
;;; --------------------------------
BOBSC: JSR KLAXON
KLAXON:LDY #50      ; FIRST PRIMARY PITCH
       JSR SOUNDS
       LDY #80      ; SECOND PRIMARY PITCH
;;; --------------------------------
SOUNDS:
       STY PITCH    ; SAVE CALLER'S Y-PITCH
       LDA #20      ; LENGTH OF SOUND
       STA DURATION1
       LDX #63      ; SECONDARY PITCH
;;; --------------------------------
@l2:   DEX          ; COUNT DOWN SECONDARY CYCLE
       BNE @l3       ; ...NOT TIME FOR CLICK YET
       BIT SPEAKER  ; ...CLICK NOW
       LDX #63      ; START ANOTHER CYCLE
;;; --------------------------------
@l3:   DEY          ; COUNT DOWN PRIMARY CYCLE
       BNE @l4       ; ...NOT TIME FOR CLICK YET
       BIT SPEAKER  ; ...CLICK NOW
       LDY PITCH    ; START ANOTHER CYCLE
;;; --------------------------------
@l4:   DEC DURATION2 ; 256*20 TIMES ALTOGETHER
       BNE @l2
       DEC DURATION1
       BNE @l2
       RTS
;;; --------------------------------
T:     JSR KLAXON_2
KLAXON_2:
       LDY #60      ; FIRST PRIMARY PITCH
       JSR SOUNDS_2
       LDY #96      ; SECOND PRIMARY PITCH
;;; --------------------------------
SOUNDS_2:
       STY PITCH    ; SAVE CALLER'S Y-PITCH
       LDX #76      ; SECONDARY PITCH
       LDA #100     ; LENGTH OF SOUND
;;; --------------------------------
@l1:   PHA
@l2:   DEX          ; COUNT DOWN SECONDARY CYCLE
       BNE @l3       ; ...NOT TIME FOR CLICK YET
       BIT SPEAKER  ; ...CLICK NOW
       LDX #76      ; START ANOTHER CYCLE
;;; --------------------------------
@l3:   DEY          ; COUNT DOWN PRIMARY CYCLE
       BNE @l4       ; ...NOT TIME FOR CLICK YET
       BIT SPEAKER  ; ...CLICK NOW
       LDY PITCH    ; START ANOTHER CYCLE
;;; --------------------------------
@l4:   SBC #1       ; COUNT DOWN TOTAL TIME
       BNE @l2
       PLA
       SBC #1
       BNE @l1
       RTS
;;; --------------------------------
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Obnoxious: WHOPIDOOP

SOUND_PROC OBNWhopi
        ;; Taken from "Assembly Cookbook for the Apple II/IIe" 
        ;; by Don Lancaster. (Chapter 4: "Obnoxious Sounds")
        ;; Adapted for A2D by @frankmilliron

        LDA     #$01
        STA     TRPCNT
SWEEP:  LDY     #$18            ; WHOPIDOOP

NXTSWP: TYA
        TAX                     ; DURATION
NXTCYC: TYA                     ; PITCH
        JSR     WAIT
        BIT     SPKR            ; WHAP SPEAKER
        CPX     #$80            ; BYPASS IF GEIGER
        BEQ     EXIT            ;  SPECIAL EFFECT
        DEX
        BNE     NXTCYC          ; ANOTHER CYCLE
        DEY
        BNE     NXTSWP          ; GO UP IN PITCH
        DEC     TRPCNT          ; MADE ALL TRIPS?
        BNE     SWEEP           ;  NO, REPEAT

EXIT:   RTS                     ; AND EXIT

TRPCNT: .byte $01               ; TRIP COUNT DECREMENTED HERE

WAIT:   SEC
WAIT2:  PHA
WAIT3:  SBC     #1
        BNE     WAIT3
        PLA
        SBC     #1
        BNE     WAIT2
        RTS
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Obnoxious: PHASOR

SOUND_PROC OBNPhasor
        ;; Taken from "Assembly Cookbook for the Apple II/IIe" 
        ;; by Don Lancaster. (Chapter 4: "Obnoxious Sounds")
        ;; Adapted for A2D by @frankmilliron

        LDA     #$06
        STA     TRPCNT
SWEEP:  LDY     #$10            ; PHASOR

NXTSWP: TYA
        TAX                     ; DURATION
NXTCYC: TYA                     ; PITCH
        JSR     WAIT
        BIT     SPKR            ; WHAP SPEAKER
        CPX     #$80            ; BYPASS IF GEIGER
        BEQ     EXIT            ;  SPECIAL EFFECT
        DEX
        BNE     NXTCYC          ; ANOTHER CYCLE
        DEY
        BNE     NXTSWP          ; GO UP IN PITCH
        DEC     TRPCNT          ; MADE ALL TRIPS?
        BNE     SWEEP           ;  NO, REPEAT

EXIT:   RTS                     ; AND EXIT

TRPCNT: .byte $01               ; TRIP COUNT DECREMENTED HERE

WAIT:   SEC
WAIT2:  PHA
WAIT3:  SBC     #1
        BNE     WAIT3
        PLA
        SBC     #1
        BNE     WAIT2
        RTS
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Obnoxious: GLEEP

SOUND_PROC OBNGleep
        ;; Taken from "Assembly Cookbook for the Apple II/IIe" 
        ;; by Don Lancaster. (Chapter 4: "Obnoxious Sounds")
        ;; Adapted for A2D by @frankmilliron

        LDA     #$FF
        STA     TRPCNT
SWEEP:  LDY     #$02            ; GLEEP

NXTSWP: TYA
        TAX                     ; DURATION
NXTCYC: TYA                     ; PITCH
        JSR     WAIT
        BIT     SPKR            ; WHAP SPEAKER
        CPX     #$80            ; BYPASS IF GEIGER
        BEQ     EXIT            ;  SPECIAL EFFECT
        DEX
        BNE     NXTCYC          ; ANOTHER CYCLE
        DEY
        BNE     NXTSWP          ; GO UP IN PITCH
        DEC     TRPCNT          ; MADE ALL TRIPS?
        BNE     SWEEP           ;  NO, REPEAT

EXIT:   RTS                     ; AND EXIT

TRPCNT: .byte $01               ; TRIP COUNT DECREMENTED HERE

WAIT:   SEC
WAIT2:  PHA
WAIT3:  SBC     #1
        BNE     WAIT3
        PLA
        SBC     #1
        BNE     WAIT2
        RTS
END_SOUND_PROC

;;; ============================================================
;;; "Silent" - flashes the menu bar

SOUND_PROC Silent
        .res    16, 0 ; see lib/bell.s - first byte 0 signals silent
        .assert 16 >= kChecksumLength, error, "too small"
END_SOUND_PROC

;;; ============================================================

        ;; Since we swap the proc into place, need to ensure last proc
        ;; has sufficient padding before routines we actually use
        .res    ::kBellProcLength

;;; ============================================================
;;; List Box
;;; ============================================================

.proc OnListSelectionChange
        lda     listbox_rec::selected_index
        RTS_IF NS

        jmp     PlayIndex
.endproc ; OnListSelectionChange

;;; Play sound if same item is re-clicked.
OnListSelectionNoChange := OnListSelectionChange

;;; Called with A = index
.proc DrawListEntryProc
        asl
        tax

        copy16  name_table,x, @addr
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawListEntryProc

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

;;; ============================================================

        JSR_TO_AUX aux::AuxEntry
        bmi     SaveSettings
        rts

;;; ============================================================

filename:
        PASCAL_STRING kPathnameBellProc

filename_buffer:
        .res kPathBufferSize

        write_buffer := DA_IO_BUFFER - kBellProcLength

        DEFINE_CREATE_PARAMS create_params, filename, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS write_params, write_buffer, kBellProcLength
        DEFINE_CLOSE_PARAMS close_params

;;; ============================================================

.proc SaveSettings
        ;; Run from Main, but with Aux LCBANK1 in

        ;; Copy from Main LCBANK2 to somewhere ProDOS can read.
        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2
        COPY_BYTES kBellProcLength, BELLDATA, write_buffer
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        ;; Write to desktop current prefix
        ldax    #filename
        stax    create_params::pathname
        stax    open_params::pathname
        jsr     DoWrite
        bcs     done            ; failed and canceled

        ;; Write to the original file location, if necessary
        jsr     JUMP_TABLE_GET_RAMCARD_FLAG
        beq     done
        ldax    #filename_buffer
        stax    create_params::pathname
        stax    open_params::pathname
        jsr     JUMP_TABLE_GET_ORIG_PREFIX
        jsr     AppendFilename
        jsr     DoWrite

done:   rts

.proc AppendFilename
        ;; Append filename to buffer
        inc     filename_buffer ; Add '/' separator
        ldx     filename_buffer
        copy8   #'/', filename_buffer,x

        ldx     #0              ; Append filename
        ldy     filename_buffer
    DO
        inx
        iny
        copy8   filename,x, filename_buffer,y
    WHILE X <> filename
        sty     filename_buffer
        rts
.endproc ; AppendFilename

.proc DoWrite
        ;; First time - ask if we should even try.
        copy8   #kErrSaveChanges, message

retry:
        ;; Create if necessary
        copy16  DATELO, create_params::create_date
        copy16  TIMELO, create_params::create_time
        JUMP_TABLE_MLI_CALL CREATE, create_params

        JUMP_TABLE_MLI_CALL OPEN, open_params
        bcs     error
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL WRITE, write_params
        php                     ; preserve result
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        plp
        bcc     ret             ; succeeded

error:
        message := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     JUMP_TABLE_SHOW_ALERT

        ;; Second time - prompt to insert.
        ldx     #kErrInsertSystemDisk
        stx     message

        cmp     #kAlertResultOK
        beq     retry

        sec                     ; failed
ret:    rts

second_try_flag:
        .byte   0
.endproc ; DoWrite

.endproc ; SaveSettings

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
