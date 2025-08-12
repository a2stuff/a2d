;;; ============================================================
;;; Pseudorandom Number Generation

;;; From https://www.apple2.org.za/gswv/a2zine/GS.WorldView/v1999/Nov/Articles.and.Reviews/Apple2RandomNumberGenerator.htm
;;; By David Empson

;;; NOTE: low bit of N and high bit of N+2 are coupled

.scope PRNGState
R1:     .byte  0
R2:     .byte  0
R3:     .byte  0
R4:     .byte  0
.endscope ; PRNGState

.proc Random
        ror PRNGState::R4       ; Bit 25 to carry
        lda PRNGState::R3       ; Shift left 8 bits
        sta PRNGState::R4
        lda PRNGState::R2
        sta PRNGState::R3
        lda PRNGState::R1
        sta PRNGState::R2
        lda PRNGState::R4       ; Get original bits 17-24
        ror                     ; Now bits 18-25 in ACC
        rol PRNGState::R1       ; R1 holds bits 1-7
        eor PRNGState::R1       ; Seven bits at once
        ror PRNGState::R4       ; Shift right by one bit
        ror PRNGState::R3
        ror PRNGState::R2
        ror
        sta PRNGState::R1
        rts
.endproc ; Random

.proc InitRand
        ;; Use current 24-bit tick count as seed
    .if ::DA_IN_AUX_SEGMENT
        JSR_TO_MAIN JUMP_TABLE_GET_TICKS
    .else
        jsr JUMP_TABLE_GET_TICKS
    .endif
        sta PRNGState::R1
        sta PRNGState::R2
        stx PRNGState::R3
        sty PRNGState::R4
        ldx #$20                ; Generate a few random numbers
InitLoop:
        jsr Random              ; to kick things off
        dex
        bne InitLoop
        rts
.endproc ; InitRand

