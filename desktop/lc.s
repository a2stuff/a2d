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
;;; MGTK call from main>aux, call in Y, params at (X,A)

.proc MGTKRelayImpl
        sty     addr-1
        stax    addr
        sta     RAMRDON
        sta     RAMWRTON
        MGTK_CALL 0, 0, addr
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; SET_POS with params at (X,A) followed by DRAW_TEXT call

.proc SetPosDrawText
        stax    addr
        sta     RAMRDON
        sta     RAMWRTON
        MGTK_CALL MGTK::MoveTo, 0, addr
        MGTK_CALL MGTK::DrawText, text_buffer2
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; IconTK call from main>aux, call in Y params at (X,A)

.proc ITKRelayImpl
        sty     addr-1
        stax    addr
        sta     RAMRDON
        sta     RAMWRTON
        ITK_CALL 0, 0, addr
        tay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts
.endproc

;;; ============================================================
;;; Used/Free icon map (Aux $1F80 - $1FFF)

        free_icon_map := $1F80

;;; Find first available free icon in the map; if
;;; available, mark it and return index+1.

.proc AllocateIcon
        sta     RAMRDON
        sta     RAMWRTON
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
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts
.endproc

;;; Mark the specified icon as free

.proc FreeIcon
        tay
        sta     RAMRDON
        sta     RAMWRTON
        dey
        lda     #0
        sta     free_icon_map,y
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
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
        jsr     desktop_main_push_pointers

        lda     cached_window_id
        asl     a               ; * 2
        tax
        copy16  window_icon_count_table,x, ptr

        sta     RAMRDON
        sta     RAMWRTON
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

done:   sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     desktop_main_pop_pointers
        rts

flag:   .byte   0
        rts                     ; ???
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

        sta     RAMRDON
        sta     RAMWRTON
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

        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; From MAIN, load AUX (A,X) into A

.proc AuxLoad
        stx     op+2
        sta     op+1
        sta     RAMRDON
op:     lda     dummy1234
        sta     RAMRDOFF
        rts
.endproc

;;; ============================================================
;;; From MAIN, show alert

;;; ...with prompt #0
.proc ShowAlert
        ldx     #$00
        ;; fall through
.endproc

;;; ... with prompt # in X
.proc ShowAlertOption
        sta     RAMRDON
        sta     RAMWRTON
        jsr     aux::Alert
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; Input: numbers in A,X, Y (all unsigned)
;;; Output: number in A,X (unsigned)

.proc Multiply_16_8_16
        sta     RAMRDON
        sta     RAMWRTON
        jsr     aux::Multiply_16_8_16
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; Input: dividend in A,X, divisor in Y (all unsigned)
;;; Output: quotient in A,X (unsigned)

.proc Divide_16_8_16
        sta     RAMRDON
        sta     RAMWRTON
        jsr     aux::Divide_16_8_16
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; ButtonEventLoop

.proc ButtonEventLoopRelay
        sta     RAMRDON
        sta     RAMWRTON
        jsr     aux::ButtonEventLoop
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; Bell

.proc Bell
        sta     RAMRDON
        sta     RAMWRTON
        jsr     aux::Bell
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; Detect double click

.proc DetectDoubleClick
        sta     RAMRDON
        sta     RAMWRTON
        jsr     aux::DetectDoubleClick
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================

        PAD_TO $D200
