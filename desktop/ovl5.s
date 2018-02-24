        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ==================================================
;;; Overlay for File Copy
;;; ==================================================

.proc file_copy_overlay
        .org $7000

        winfo12 := $D5B7
        winfo15 := $D5F1

        path_buf0 := $D402
        path_buf1 := $D443
        path_buf2 := $D484

        grafport3 := $D239

        dialog_rect1 := $DA9E
        dialog_rect2 := $DAAA

L4030           := $4030

;;; Routines in common overlay segment ($5000-$6FFF)
L5106           := $5106
L55BA           := $55BA
L5CF7           := $5CF7
L5E0A           := $5E0A
L5E57           := $5E57
L5E6F           := $5E6F
L5E87           := $5E87
L5F49           := $5F49
L5F5B           := $5F5B
L606D           := $606D
L6129           := $6129
L6161           := $6161
L6163           := $6163
L61B1           := $61B1
L6227           := $6227
L62C8           := $62C8
L647C           := $647C
L6D27           := $6D27
L6D30           := $6D30

        jsr     L5CF7
        jsr     L7052
        jsr     L5E87
        jsr     L5F5B
        jsr     L6161
        jsr     L61B1
        jsr     L606D
        jsr     L7026
        jsr     L6D30
        jsr     L6D27
        lda     #$FF
        sta     $D8EC
        jmp     L5106

L7026:  ldx     L709B
L7029:  lda     L709B+1,x
        sta     $6D1E,x
        dex
        lda     L709B+1,x
        sta     $6D1E,x
        dex
        dex
        bpl     L7029
        lda     #$80
        sta     $5104
        lda     #$00
        sta     path_buf0
        sta     $51AE
        lda     #$01
        sta     path_buf2
        lda     #$06
        sta     $D485
        rts

L7052:  lda     winfo12
        jsr     L62C8
        addr_call L5E0A, $DA67  ; "Copy a File ..."
        addr_call L5E57, $DA77  ; "Source filename:"
        addr_call L5E6F, $DA88  ; "Destination filename:"
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202 ; penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, dialog_rect1
        MGTK_RELAY_CALL MGTK::FrameRect, dialog_rect2
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

.macro entry arg1, arg2
        .byte   arg1
        .addr   arg2
.endmacro

L709B:  .byte   $29             ; length of following data block
        entry   0, L70F1
        entry   0, L71D8

        entry   0, $6593
        entry   0, $664E
        entry   0, $6DC2
        entry   0, $6DD0
        entry   0, $6E1D
        entry   0, $69C6
        entry   0, $6A18
        entry   0, $6A53
        entry   0, $6AAC
        entry   0, $6B01
        entry   0, $6B44
        entry   0, $66D8

L70C6:  .byte   $29             ; length of following data block
        entry   0, L7189
        entry   0, L71F9

        entry   0, $65F0
        entry   0, $6693
        entry   0, $6DC9
        entry   0, $6DD4
        entry   0, $6E31
        entry   0, $6B72
        entry   0, $6BC4
        entry   0, $6BFF
        entry   0, $6C58
        entry   0, $6CAD
        entry   0, $6CF0
        entry   0, $684F

;;; ==================================================

L70F1:  lda     #1
        sta     path_buf2
        lda     #$20
        sta     $D485
        jsr     L6D27

        ldx     L70C6
:       lda     L70C6+1,x
        sta     $6D1E,x
        dex
        lda     L70C6+1,x
        sta     $6D1E,x
        dex
        dex
        bpl     :-

        lda     #$80
        sta     $50A8
        sta     $51AE
        lda     $D920
        sta     $D921
        lda     #$FF
        sta     $D920
        jsr     L5E87
        jsr     L5F5B
        jsr     L6161
        jsr     L61B1

        jsr     L606D
        ldx     $5028
L7137:  lda     $5028,x
        sta     path_buf1,x
        dex
        bpl     L7137
        addr_call L6129, path_buf1  ; path_buf1
        lda     #$01
        sta     path_buf2           ; path_buf2
        lda     #$06
        sta     $D485
        ldx     path_buf0
        beq     L7178
L7156:  lda     path_buf0,x
        and     #$7F
        cmp     #'/'
        beq     L7162
        dex
        bne     L7156
L7162:  ldy     #2
        dex
L7165:  cpx     path_buf0
        beq     L7178
        inx
        lda     path_buf0,x
        sta     path_buf2,y
        inc     path_buf2
        iny
        jmp     L7165

L7178:  jsr     L6D27
        lda     $D8F0
        sta     $D8F1
        lda     $D8F2
        sta     $D8F0
        rts

        .byte   0

;;; ==================================================

L7189:  addr_call L647C, path_buf0
        beq     L7198
L7192:  lda     #$40
        jsr     L4030
        rts

L7198:  addr_call L647C, path_buf1
        bne     L7192
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo15
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo12
        lda     #0
        sta     $50A8
        lda     #0
        sta     $D8EC
        jsr     L55BA

L71C0:  copy16  #path_buf0, $6
        copy16  #path_buf1, $8
        ldx     $50AA
        txs
        return  #$00

        .byte   0

;;; ==================================================

L71D8:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo15
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo12
        lda     #0
        sta     $D8EC
        jsr     L55BA
        ldx     $50AA
        txs
        return  #$FF

;;; ==================================================

L71F9:  lda     #1
        sta     path_buf2
        lda     #' '
L7200:  sta     $D485
        jsr     L6D27
        ldx     L709B
L7209:  lda     L709B+1,x
        sta     $6D1E,x
        dex
        lda     L709B+1,x
        sta     $6D1E,x
        dex
        dex
        bpl     L7209
        lda     #$01
        sta     path_buf2
        lda     #$06
        sta     $D485
        lda     #$00
        sta     $50A8
        lda     #$FF
        sta     $D920
        lda     #$00
        sta     $51AE
        lda     $D8F0
        sta     $D8F2
        lda     $D8F1
        sta     $D8F0

        ldx     path_buf0
:       lda     path_buf0,x
        sta     $5028,x
        dex
        bpl     :-

        jsr     L5F49
        bit     $D8F0
        bpl     L726D
        jsr     L5E87
        lda     #0
        jsr     L6227
        jsr     L5F5B
        jsr     L6161
        jsr     L61B1
        jsr     L606D
        jsr     L6D27
        jmp     L7295

L726D:  lda     $5028
        bne     L7281
L7272:  jsr     L5E87
        lda     #$00
        jsr     L6227
        jsr     L5F5B
        lda     #$FF
        bne     L7289
L7281:  jsr     L5F5B
        bcs     L7272
        lda     $D921
L7289:  sta     $D920
        jsr     L6163
        jsr     L61B1
        jsr     L606D
L7295:  rts

        PAD_TO $7800
.endproc
