;;; ============================================================
;;; DeskTop - "Language Card" Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into AUX $D000-$D1FF
;;; ============================================================

        .org ::kSegmentDeskTopLC1AAddress

;;; Various routines callable from MAIN

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
        cpx     #kMaxIconCount  ; allow up to the maximum
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
;;; Copy data to/from buffers (see `cached_window_id` /
;;;  `cached_window_entry_list` / `window_entry_count_table` /2)

.proc XferWindowEntryTable
        ptr := $6

from:   lda     #$80
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
to:     lda     #$00
        sta     flag
        jsr     PushPointers

        lda     cached_window_id
        asl     a               ; * 2
        tax
        copy16  window_entry_count_table,x, ptr

        jsr     BankInAux
        bit     flag
        bpl     set_length

        ;; assign length from `cached_window_entry_list`
        lda     cached_window_entry_count
        ldy     #0
        sta     (ptr),y
        jmp     set_copy_ptr

        ;; assign length to `cached_window_entry_list`
set_length:
        ldy     #0
        lda     (ptr),y
        sta     cached_window_entry_count

set_copy_ptr:
        copy16  window_entry_list_table,x, ptr
        bit     flag
        bmi     copy_from

        ;; copy into `cached_window_entry_list`
        ldy     #0              ; flag clear...
:       cpy     cached_window_entry_count
        beq     done
        lda     (ptr),y
        sta     cached_window_entry_list,y
        iny
        jmp     :-

        ;; copy from `cached_window_entry_list`
copy_from:
        ldy     #0
:       cpy     cached_window_entry_count
        beq     done
        lda     cached_window_entry_list,y
        sta     (ptr),y
        iny
        jmp     :-

done:   jsr     BankInMain
        jsr     PopPointers     ; do not tail-call optimise!
        rts

flag:   .byte   0
.endproc
        StoreWindowEntryTable := XferWindowEntryTable::from
        LoadWindowEntryTable := XferWindowEntryTable::to

.proc LoadActiveWindowEntryTable
        copy    active_window_id, cached_window_id
        jmp     LoadWindowEntryTable
.endproc

.proc LoadDesktopEntryTable
        copy    #0, cached_window_id
        jmp     LoadWindowEntryTable
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
;;; Assert: Main is banked in

.proc Bell
        jsr     BankInAux
        jsr     aux::Bell
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
