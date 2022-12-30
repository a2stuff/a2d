;;; ============================================================
;;; DeskTop - "Language Card" Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into AUX $D000-$D1FF
;;; ============================================================

        .org ::kSegmentDeskTopLC1AAddress

;;; ============================================================
;;; Exported entry points for main>aux and aux>main calls

.assert * = CallMainToAux, error, "entry point mismatch"
.proc CallMainToAuxImpl
        stax    call_addr
        jsr     BankInAux
        call_addr := *+1
        jsr     SELF_MODIFIED
        jmp     BankInMain
.endproc

.assert * = CallAuxToMain, error, "entry point mismatch"
.proc CallAuxToMainImpl
        stax    call_addr
        jsr     BankInMain
        call_addr := *+1
        jsr     SELF_MODIFIED
        jmp     BankInAux
.endproc

;;; ============================================================
;;; Common code for main>aux relays with MLI-style params
;;; Inputs: A,X = target address
;;; Uses $7E/$7F

.proc ParamsRelayImpl
        params_src := $7E
        stax    call_addr

        ;; Adjust return address on stack, compute
        ;; original params address.
        pla
        sta     params_src
        clc
        adc     #<3
        tax
        pla
        sta     params_src+1
        adc     #>3
        pha
        txa
        pha

        ;; Copy the params here
        ldy     #3      ; ptr is off by 1
:       lda     (params_src),y
        sta     params-1,y
        dey
        bne     :-

        ;; Bank and call
        jsr     BankInAux
call_addr := * + 1
        jsr     SELF_MODIFIED
params:  .res    3
        jmp     BankInMain
.endproc

;;; ============================================================
;;; MGTK call from main>aux, MLI-style params

.proc MGTKRelayImpl
        ldax    #MGTKAuxEntry
        jmp     ParamsRelayImpl
.endproc

;;; ============================================================
;;; IconTK call from main>aux, MLI-style params

.proc ITKRelayImpl
        ldax    #aux::ITKEntry
        jmp     ParamsRelayImpl
.endproc

;;; ============================================================
;;; LineEditTK call from main>aux, MLI-style params

.proc LETKRelayImpl
        ldax    #aux::letk::LETKEntry
        jmp     ParamsRelayImpl
.endproc


;;; ============================================================
;;; ButtonTK call from main>aux, MLI-style params

.proc BTKRelayImpl
        ldax    #aux::btk::BTKEntry
        jmp     ParamsRelayImpl
.endproc


;;; ============================================================
;;; Assign active state to active_window_id window

.proc OverwriteWindowPort
        src := $6
        dst := $8

        jsr     BankInAux

        MGTKEntry := aux::MGTKEntry
        MGTK_CALL MGTK::GetPort, src ; grab window state

        lda     active_window_id   ; which desktop window?
        asl     a
        tax
        copy16  win_table,x, dst
        lda     dst
        clc
        adc     #MGTK::Winfo::port
        sta     dst
        bcc     :+
        inc     dst+1

:       ldy     #.sizeof(MGTK::GrafPort)-1
loop:   lda     (src),y
        sta     (dst),y
        dey
        bpl     loop

        jmp     BankInMain
.endproc

;;; ============================================================
;;; From MAIN, load AUX (A,X) into A
;;; Assert: Main is banked in

.proc AuxLoad
        stax    op+1
        sta     RAMRDON
op:     lda     SELF_MODIFIED
        sta     RAMRDOFF
        rts
.endproc

;;; ============================================================
;;; From MAIN, show alert
;;; Assert: Main is banked in

;;; A=alert number, with default options
.proc ShowAlert
        ldx     #$00
        FALL_THROUGH_TO ShowAlertOption
.endproc

;;; A=alert number, X=custom options
.proc ShowAlertOption
        jsr     BankInAux
        jsr     aux::AlertById
        jmp     BankInMain
.endproc

;;; ============================================================
;;; Bell
;;; Assert: Aux is banked in

.proc BellFromAux
        jsr     BankInMain
        jsr     Bell
        jmp     BankInAux
.endproc

;;; ============================================================
;;; Yield from a nested event loop, for periodic tasks.
;;; Assert: Aux is banked in

.proc YieldLoopFromAux
        jsr     BankInMain
        jsr     main__YieldLoop
        jmp     BankInAux
.endproc

;;; ============================================================
;;; Helpers for banking in Aux/Main $200-$BFFF.
;;; (These save 3 bytes per call.)

.proc BankInAux
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

.proc BankInMain
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; Pushes two words from $6/$8 to stack; preserves A,X,Y

.proc PushPointers
        ;; Stash A,X
        sta     a_save
        stx     x_save

        ;; Stash return address
        pla
        sta     lo
        pla
        sta     hi

        ;; Copy 4 bytes from $8 to stack
        ldx     #AS_BYTE(-4)
:       lda     $06 + 4,x
        pha
        inx
        bne     :-

        ;; Restore return address
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        ;; Restore A,X
        x_save := *+1
        ldx     #SELF_MODIFIED_BYTE
        a_save := *+1
        lda     #SELF_MODIFIED_BYTE

        rts
.endproc

;;; ============================================================
;;; Pops two words from stack to $6/$8; preserves A,X,Y

.proc PopPointers
        ;; Stash A,X
        sta     a_save
        stx     x_save

        ;; Stash return address
        pla
        sta     lo
        pla
        sta     hi

        ;; Copy 4 bytes from stack to $6
        ldx     #3
:       pla
        sta     $06,x
        dex
        bpl     :-

        ;; Restore return address to stack
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        ;; Restore A,X
        x_save := *+1
        ldx     #SELF_MODIFIED_BYTE
        a_save := *+1
        lda     #SELF_MODIFIED_BYTE

        rts
.endproc

;;; ============================================================

        PAD_TO $D200
