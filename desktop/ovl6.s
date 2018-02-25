        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ==================================================
;;; Overlay for File Delete
;;; ==================================================

        .org $7000
.proc file_delete_overlay

        winfo12 := $D5B7
        winfo15 := $D5F1

        path_buf0 := $D402
        path_buf1 := $D443
        path_buf2 := $D484

        grafport3 := $D239

        dialog_rect1 := $DA9E
        dialog_rect2 := $DAAA

;;; Routines in common overlay segment ($5000-$6FFF)
L5106   := $5106
L55BA   := $55BA
L5CF7   := $5CF7
L5E0A   := $5E0A
L5E57   := $5E57
L5E87   := $5E87
L5F5B   := $5F5B
L606D   := $606D
L6161   := $6161
L61B1   := $61B1
L62C8   := $62C8
L647C   := $647C
L6D27   := $6D27
L6D30   := $6D30

        jsr     L5CF7
        jsr     L704D
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

L7026:  ldx     L7086
L7029:  lda     L7087,x
        sta     $6D1E,x
        dex
        lda     L7087,x
        sta     $6D1E,x
        dex
        dex
        bpl     L7029
        lda     #$00
        sta     path_buf0
        sta     $51AE
        lda     #$01
        sta     path_buf2
        lda     #$06
        sta     path_buf2+1     ; ???
        rts

L704D:  lda     winfo12
        jsr     L62C8
        addr_call L5E0A, $DAB6  ; "Delete a File ..."
        addr_call L5E57, $DAC8  ; "File to delete:"
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202 ; penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, dialog_rect1
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

.macro entry arg1, arg2
        .byte arg1
        .addr arg2
.endmacro

L7086:  .byte $29               ; length of the following data block
L7087:  entry 0, L70B1
        entry 0, L70EA
        entry 0, $6593
        entry 0, $664E
        entry 0, $6DC2
        entry 0, $6DD0
        entry 0, $6E1D
        entry 0, $69C6
        entry 0, $6A18
        entry 0, $6A53
        entry 0, $6AAC
        entry 0, $6B01
        entry 0, $6B44
        entry 0, $66D8


L70B1:  addr_call L647C, path_buf0
        beq     L70C0
        lda     #$40
        jsr     JUMP_TABLE_ALERT_0
        rts

L70C0:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo15
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo12
        lda     #0
        sta     $D8EC
        jsr     L55BA
        copy16  #path_buf0, $6
        ldx     $50AA
        txs
        lda     #0
        rts

        .byte   0

L70EA:  MGTK_RELAY_CALL MGTK::CloseWindow, winfo15
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo12
        lda     #0
        sta     $D8EC
        jsr     L55BA
        ldx     $50AA
        txs
        return  #$FF

;;; ==================================================

        PAD_TO $7800
.endproc ; file_delete_overlay