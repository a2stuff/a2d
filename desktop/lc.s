;;; ============================================================
;;; DeskTop - "Language Card" Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into AUX $D000-$D1FF
;;; ============================================================

        .org $D000

;;; Various routines callable from MAIN

;;; ============================================================
;;; Common code for main>aux relays with MLI-style params

.proc ParamsRelayImpl
        params_src := $80

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
        copy16  #MGTK::MLI, ParamsRelayImpl::call_addr
        jmp     ParamsRelayImpl
.endproc

;;; ============================================================
;;; IconTK call from main>aux, MLI-style params

.proc ITKRelayImpl
        copy16  #IconTK::MLI, ParamsRelayImpl::call_addr
        jmp     ParamsRelayImpl
.endproc


;;; ============================================================
;;; SET_POS with params at (X,A) followed by DRAW_TEXT call

.proc SetPosDrawText
        stax    addr
        jsr     BankInAux
        MGTK_CALL MGTK::MoveTo, 0, addr
        MGTK_CALL MGTK::DrawText, text_buffer2
        jmp     BankInMain
.endproc

;;; ============================================================
;;; Used/Free icon map (Aux $1F80 - $1FFF)

        free_icon_map := $1F80

;;; Find first available free icon in the map; if
;;; available, mark it and return index+1.

.proc AllocateIcon
        jsr     BankInAux

        ldx     #0
loop:   lda     free_icon_map,x
        beq     :+
        inx
        cpx     #$7F
        bne     loop
        rts

:       inx
        txa
        dex
        tay
        lda     #1
        sta     free_icon_map,x
        tya

        jmp     BankInMain
.endproc

;;; Mark the specified icon as free

.proc FreeIcon
        jsr     BankInAux

        tay
        dey
        lda     #0
        sta     free_icon_map,y

        jmp     BankInMain
.endproc

;;; ============================================================
;;; Copy data to/from buffers (see cached_window_id / cached_window_icon_list / window_icon_count_table/2) ???

.proc XferWindowIconTable
        ptr := $6

from:
        lda     #$80
        bne     :+              ; always

to:
        lda     #$00

:       sta     flag
        jsr     main__push_pointers

        lda     cached_window_id
        asl     a               ; * 2
        tax
        copy16  window_icon_count_table,x, ptr

        jsr     BankInAux
        bit     flag
        bpl     set_length

        ;; assign length from cached_window_icon_list
        lda     cached_window_icon_count
        ldy     #0
        sta     (ptr),y
        jmp     set_copy_ptr

        ;; assign length to cached_window_icon_list
set_length:
        ldy     #0
        lda     (ptr),y
        sta     cached_window_icon_count

set_copy_ptr:
        copy16  window_icon_list_table,x, ptr
        bit     flag
        bmi     copy_from

        ;; copy into cached_window_icon_list
        ldy     #0              ; flag clear...
:       cpy     cached_window_icon_count
        beq     done
        lda     (ptr),y
        sta     cached_window_icon_list,y
        iny
        jmp     :-

        ;; copy from cached_window_icon_list
copy_from:
        ldy     #0
:       cpy     cached_window_icon_count
        beq     done
        lda     cached_window_icon_list,y
        sta     (ptr),y
        iny
        jmp     :-

done:   jsr     BankInMain
        jsr     main__pop_pointers
        rts

flag:   .byte   0
.endproc
        StoreWindowIconTable := XferWindowIconTable::from
        LoadWindowIconTable := XferWindowIconTable::to

.proc LoadActiveWindowIconTable
        copy    active_window_id, cached_window_id
        jmp     LoadWindowIconTable
.endproc

.proc LoadDesktopIconTable
        copy    #0, cached_window_id
        jmp     LoadWindowIconTable
.endproc


;;; ============================================================
;;; Assign active state to active_window_id window

.proc OverwriteWindowPort
        src := $6
        dst := $8

        jsr     BankInAux

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

;;; ...with prompt #0
.proc ShowAlert
        ldx     #$00
        ;; fall through
.endproc

;;; ... with prompt # in X
.proc ShowAlertOption
        jsr     BankInAux
        jsr     aux::Alert
        jmp     BankInMain
.endproc

;;; ============================================================
;;; Input: numbers in A,X, Y (all unsigned)
;;; Output: number in A,X (unsigned)
;;; Assert: Main is banked in

.proc Multiply_16_8_16
        jsr     BankInAux
        jsr     aux::Multiply_16_8_16
        jmp     BankInMain
.endproc

;;; ============================================================
;;; Input: dividend in A,X, divisor in Y (all unsigned)
;;; Output: quotient in A,X (unsigned)
;;; Assert: Main is banked in

.proc Divide_16_8_16
        jsr     BankInAux
        jsr     aux::Divide_16_8_16
        jmp     BankInMain
.endproc

;;; ============================================================
;;; ButtonEventLoop
;;; Assert: Main is banked in

.proc ButtonEventLoopRelay
        jsr     BankInAux
        jsr     aux::ButtonEventLoop
        jmp     BankInMain
.endproc

;;; ============================================================
;;; Bell
;;; Assert: Main is banked in

.proc Bell
        jsr     BankInAux
        jsr     aux::Bell
        jmp     BankInMain
.endproc

;;; ============================================================
;;; Detect double click
;;; Assert: Main is banked in

.proc DetectDoubleClick
        jsr     BankInAux
        jsr     aux::DetectDoubleClick
        jmp     BankInMain
.endproc

;;; ============================================================
;;; Copy current GrafPort MapInfo into target buffer
;;; Inputs: A,X = mapinfo address
;;; Assert: Main is banked in

.proc GetPortBits
        jsr     BankInAux
        jsr     aux::GetPortBits
        jmp     BankInMain
.endproc

;;; ============================================================
;;; Yield from a nested event loop, for periodic tasks.
;;; Assert: Aux is banked in

.proc YieldLoopFromAux
        jsr     BankInMain
        jsr     main__yield_loop
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

        PAD_TO $D200
