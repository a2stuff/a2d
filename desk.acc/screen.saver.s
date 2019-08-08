        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../mgtk/mgtk.inc"
        .include "../desktop.inc"
        .include "../inc/macros.inc"


;;; ============================================================

        .org $800

da_start:
        jmp     start

save_stack:.byte   0

.proc start
        tsx
        stx     save_stack

        ;; Copy DA to AUX
        copy16  #da_start, STARTLO
        copy16  #da_start, DESTINATIONLO
        copy16  #da_end, ENDLO
        sec                     ; main>aux
        jsr     AUXMOVE

        ;; Transfer control to aux
        sta     RAMWRTON
        sta     RAMRDON

        ;; run the DA
        jsr     init

        ;; tear down/exit
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ldx     save_stack
        txs

        rts
.endproc

;;; ============================================================
;;; Animation Resources

        toaster_height = 32
        toaster_width  = 64

        toaster_count = 4

xpos_table:
        .word   screen_width+toaster_width
        .word   screen_width+toaster_width+150
        .word   screen_width+toaster_width+300
        .word   screen_width+toaster_width+450

ypos_table:
        .word   AS_WORD(-toaster_height)
        .word   AS_WORD(-toaster_height)+160
        .word   AS_WORD(-toaster_height)+40
        .word   AS_WORD(-toaster_height)+99

frame_table:
        .byte   0,1,2,3

;;; ============================================================
;;; Graphics Resources

        da_window_id = 100

event_params:   .tag MGTK::Event

.proc window_title
        .byte 0                 ; length
.endproc

.proc winfo
window_id:      .byte   da_window_id ; window identifier
options:        .byte   MGTK::Option::dialog_box
title:          .addr   window_title
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   32
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   screen_width
mincontlength:  .word   screen_height
maxcontwidth:   .word   screen_width
maxcontlength:  .word   screen_height
.proc port
viewloc:        DEFINE_POINT 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
maprect:        DEFINE_RECT 0, 0, screen_width, screen_height
.endproc
pattern:        .res    8, 0
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc

.proc paintbits_params
viewloc:        DEFINE_POINT 0,0,viewloc
mapbits:        .addr   0
mapwidth:       .byte   10
reserved:       .byte   0
maprect:        DEFINE_RECT 0,0,toaster_width-1,toaster_height-1
.endproc

notpencopy:     .byte   MGTK::notpencopy
penXOR:         .byte   MGTK::penXOR

.proc getwinport_params
window_id:     .byte   da_window_id
        .addr   grafport
.endproc

grafport:       .tag MGTK::GrafPort

;;; ============================================================
;;; DA Init

.proc init
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::SetPort, winfo::port

        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintRect, grafport + MGTK::GrafPort::maprect

        MGTK_CALL MGTK::FlushEvents
.endproc

;;; ============================================================
;;; Main Input Loop

.proc input_loop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     exit
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     exit

        jsr     animate
        jmp     input_loop

exit:
        MGTK_CALL MGTK::DrawMenu
        sta     RAMWRTOFF
        sta     RAMRDOFF
        yax_call JUMP_TABLE_MGTK_RELAY, MGTK::HiliteMenu, last_menu_click_params
        sta     RAMWRTON
        sta     RAMRDON

        ;; Force desktop redraw
        MGTK_CALL MGTK::CloseWindow, winfo
        ITK_CALL IconTK::RedrawIcons

        MGTK_CALL MGTK::ShowCursor
        rts                     ; exits input loop
.endproc

;;; ============================================================
;;; Animate

.proc animate
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, penXOR

        ;; For each toaster...
        copy    #toaster_count-1, index
loop:

        ;; Stash current toaster's values
        ldx     index
        copy    frame_table,x, frame
        txa
        asl
        tax
        copy16  xpos_table,x, xpos
        copy16  ypos_table,x, ypos

        ;; Erase previous pos
        copy16  xpos, paintbits_params::viewloc::xcoord
        copy16  ypos, paintbits_params::viewloc::ycoord
        lda     frame
        asl                     ; *2
        tax
        copy16  toaster_frames,x, paintbits_params::mapbits


        MGTK_CALL MGTK::PaintBits, paintbits_params

        ;; Move
        add16   ypos, #1, ypos
        sub16   xpos, #4, xpos

        ;; Wrap Y
        cmp16   ypos, #screen_height
        bvc     :+
        eor     #$80
:       bmi     :+
        copy16  #AS_WORD(-toaster_height), ypos
:

        ;; Wrap X
        cmp16   xpos, #AS_WORD(-toaster_width)
        bvc     :+
        eor     #$80
:       bpl     :+
        copy16  #screen_width+toaster_width, xpos
:

        ;; Next frame
        inc     frame
        lda     frame
        cmp     #4              ; num frames
        bne     :+
        copy    #0, frame
:

        ;; Draw new pos
        copy16  xpos, paintbits_params::viewloc::xcoord
        copy16  ypos, paintbits_params::viewloc::ycoord
        lda     frame
        asl                     ; *2
        tax
        copy16  toaster_frames,x, paintbits_params::mapbits
        MGTK_CALL MGTK::PaintBits, paintbits_params

        ;; Store updated values
        ldx     index
        copy    frame, frame_table,x
        txa
        asl
        tax
        copy16  xpos, xpos_table,x
        copy16  ypos, ypos_table,x

        ;; Next
        dec     index
        bmi     :+
        jmp     loop
:       rts


index:  .byte   0
xpos:   .word   0
ypos:   .word   0
frame:  .byte   0

.endproc


;;; ============================================================

toaster_frames:
        .addr   toaster_bits1
        .addr   toaster_bits2
        .addr   toaster_bits3
        .addr   toaster_bits2

toaster_bits1:
        .byte   px(%0000000),px(%0000000),px(%0000001),px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0011111),px(%1001100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%1111110),px(%0111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000011),px(%1100111),px(%1110011),px(%0000111),px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0001111),px(%1111111),px(%1001111),px(%1111111),px(%1111111),px(%1111000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0001111),px(%1111001),px(%1111111),px(%0000000),px(%0000000),px(%1111111),px(%1000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0111111),px(%1111111),px(%1000000),px(%0000001),px(%1111111),px(%1111111),px(%1111100),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0111111),px(%1111000),px(%0000000),px(%1111111),px(%1000000),px(%0000000),px(%0111111),px(%0000000),px(%0000000)
        .byte   px(%0000001),px(%1111111),px(%0000000),px(%0001111),px(%1100000),px(%0000000),px(%1111110),px(%0000000),px(%1100000),px(%0000000)
        .byte   px(%0000001),px(%1110000),px(%0000001),px(%1111100),px(%0000000),px(%0111111),px(%0000001),px(%1111111),px(%1111111),px(%1000000)
        .byte   px(%0000111),px(%1000000),px(%0011111),px(%1000000),px(%0000111),px(%1111100),px(%1111111),px(%1110011),px(%0011000),px(%0000000)
        .byte   px(%0011110),px(%0000000),px(%1111000),px(%0000000),px(%1111111),px(%1110011),px(%1111001),px(%1111111),px(%1111111),px(%1000000)
        .byte   px(%0011111),px(%1110011),px(%1100000),px(%0001111),px(%1111111),px(%1001111),px(%1111111),px(%1001100),px(%1100000),px(%0000000)
        .byte   px(%1100001),px(%1111111),px(%0000000),px(%0111100),px(%1111111),px(%1001111),px(%1100111),px(%1111111),px(%1111110),px(%0000000)
        .byte   px(%1100000),px(%0001111),px(%1111001),px(%1110011),px(%1111110),px(%0111111),px(%1111110),px(%0110011),px(%0000000),px(%0000000)
        .byte   px(%1100111),px(%1000000),px(%1111111),px(%1001111),px(%1111110),px(%0111111),px(%0011111),px(%1111111),px(%1100000),px(%0000000)
        .byte   px(%1100110),px(%0111100),px(%0000111),px(%1001111),px(%1111001),px(%1111111),px(%1111000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%1100110),px(%0000011),px(%1100110),px(%0111111),px(%1111001),px(%1110011),px(%1111111),px(%1001100),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000011),px(%1100110),px(%0111111),px(%1100111),px(%1111111),px(%0000000),px(%0111100),px(%1100000),px(%0000000)
        .byte   px(%1100000),px(%0110011),px(%1100110),px(%0111111),px(%1100111),px(%1001111),px(%1111001),px(%1110000),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0001100),px(%1100111),px(%1111100),px(%0000111),px(%1110000),px(%1100000),px(%0000000)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0001111),px(%1111001),px(%1110011),px(%1111111),px(%1000000),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0001100),px(%1111110),px(%0001111),px(%1111110),px(%0000000),px(%1100000),px(%0000000)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0000011),px(%0000111),px(%1111111),px(%1100000),px(%0000011),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000000),px(%1111111),px(%1111100),px(%0000000),px(%0001100),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0000000),px(%0000000),px(%0000000),px(%0000001),px(%1110000),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000000),px(%0000000),px(%0000000),px(%0011110),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0011000),px(%0000000),px(%0000110),px(%0000000),px(%0000000),px(%0000011),px(%1100000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000110),px(%0000000),px(%0000110),px(%0000000),px(%0000000),px(%0111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000001),px(%1110000),px(%0000110),px(%0000000),px(%0011111),px(%1000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0001111),px(%0000110),px(%0001111),px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%1111111),px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)

toaster_bits2:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000001),px(%1110000),px(%0000111),px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0011111),px(%1110011),px(%1111111),px(%1111111),px(%1111000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%1111001),px(%1111111),px(%0000000),px(%0000000),px(%1111111),px(%1000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000011),px(%1111111),px(%1000000),px(%0000001),px(%1111111),px(%1111111),px(%1111100),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0001111),px(%1111000),px(%0000000),px(%1111111),px(%1000000),px(%0000000),px(%0111111),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0111111),px(%0000000),px(%0001111),px(%1100000),px(%0000000),px(%1111111),px(%1111111),px(%1100000),px(%0000000)
        .byte   px(%0000001),px(%1110000),px(%0000001),px(%1111100),px(%0000000),px(%0111111),px(%1111000),px(%0000011),px(%1100000),px(%0000000)
        .byte   px(%0000111),px(%1000000),px(%0011111),px(%1000000),px(%0000111),px(%1111111),px(%0000111),px(%1111100),px(%1100000),px(%0000000)
        .byte   px(%0011110),px(%0000000),px(%1111000),px(%0000000),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1100000),px(%0000000)
        .byte   px(%0011111),px(%1110011),px(%1100000),px(%0001111),px(%1111111),px(%1111111),px(%0000000),px(%0000000),px(%1100000),px(%0000000)
        .byte   px(%1100001),px(%1111111),px(%0000000),px(%0111100),px(%1111111),px(%1110000),px(%1111111),px(%1111111),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0001111),px(%1111001),px(%1110011),px(%1111111),px(%1001111),px(%1111110),px(%0111111),px(%1111111),px(%1000000)
        .byte   px(%1100111),px(%1000000),px(%1111111),px(%1001111),px(%1111110),px(%0111111),px(%1111111),px(%1110011),px(%0011000),px(%0000000)
        .byte   px(%1100110),px(%0111100),px(%0000111),px(%1001111),px(%1111001),px(%1111111),px(%1111001),px(%1111111),px(%1111111),px(%1000000)
        .byte   px(%1100110),px(%0000011),px(%1100110),px(%0111111),px(%1111001),px(%1111111),px(%1111111),px(%1001100),px(%0011110),px(%0000000)
        .byte   px(%1100000),px(%0000011),px(%1100110),px(%0111111),px(%1100111),px(%1111111),px(%1100111),px(%1111111),px(%1100000),px(%0000000)
        .byte   px(%1100000),px(%0110011),px(%1100110),px(%0111111),px(%1100111),px(%1001100),px(%1111110),px(%0110000),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0001100),px(%1100111),px(%1111100),px(%0000000),px(%0000000),px(%1100000),px(%0000000)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0001111),px(%1111001),px(%1110011),px(%1111111),px(%1000000),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0001100),px(%1111110),px(%0001111),px(%1111110),px(%0000000),px(%1100000),px(%0000000)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0000011),px(%0000111),px(%1111111),px(%1100000),px(%0000011),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000000),px(%1111111),px(%1111100),px(%0000000),px(%0001100),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0000000),px(%0000000),px(%0000000),px(%0000001),px(%1110000),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000000),px(%0000000),px(%0000000),px(%0011110),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0011000),px(%0000000),px(%0000110),px(%0000000),px(%0000000),px(%0000011),px(%1100000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000110),px(%0000000),px(%0000110),px(%0000000),px(%0000000),px(%0111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000001),px(%1110000),px(%0000110),px(%0000000),px(%0011111),px(%1000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0001111),px(%0000110),px(%0001111),px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%1111111),px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)

toaster_bits3:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000001),px(%1111111),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%1111111),px(%1111111),px(%1111000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0111111),px(%1100000),px(%0000000),px(%0011111),px(%1110000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0011111),px(%1000000),px(%0000001),px(%1111111),px(%1111111),px(%1111100),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000011),px(%1111000),px(%0000000),px(%1111111),px(%1000000),px(%0000000),px(%0111111),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0111111),px(%0000000),px(%0001111),px(%1100000),px(%0000000),px(%1111111),px(%1111111),px(%1100000),px(%0000000)
        .byte   px(%0000001),px(%1110000),px(%0000001),px(%1111100),px(%0000000),px(%0111111),px(%1111000),px(%0000011),px(%1100000),px(%0000000)
        .byte   px(%0000111),px(%1000000),px(%0011111),px(%1000000),px(%0000111),px(%1111111),px(%0000111),px(%1111100),px(%1100000),px(%0000000)
        .byte   px(%0011110),px(%0000000),px(%1111000),px(%0000000),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1100000),px(%0000000)
        .byte   px(%0011111),px(%1110011),px(%1100000),px(%0001111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1100000),px(%0000000)
        .byte   px(%1100001),px(%1111111),px(%0000000),px(%0111100),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0001111),px(%1111001),px(%1110011),px(%1111111),px(%1111111),px(%1111111),px(%1111100),px(%1100000),px(%0000000)
        .byte   px(%1100111),px(%1000000),px(%1111111),px(%1001111),px(%1111111),px(%1111111),px(%1111111),px(%1111100),px(%0000000),px(%0000000)
        .byte   px(%1100110),px(%0111100),px(%0000111),px(%1001111),px(%1111110),px(%0001111),px(%1111111),px(%1000000),px(%1100000),px(%0000000)
        .byte   px(%1100110),px(%0000011),px(%1100110),px(%0111111),px(%1111001),px(%1110000),px(%0000000),px(%0001111),px(%0011110),px(%0000000)
        .byte   px(%1100000),px(%0000011),px(%1100110),px(%0111111),px(%1100111),px(%1111111),px(%0011110),px(%0111100),px(%1111001),px(%1000000)
        .byte   px(%1100000),px(%0110011),px(%1100110),px(%0111111),px(%1100111),px(%1111100),px(%1111001),px(%1110011),px(%1100111),px(%1000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0001100),px(%1100111),px(%1111111),px(%1100111),px(%1001111),px(%0011110),px(%0000000)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0001111),px(%1111001),px(%1111111),px(%1111111),px(%1111100),px(%1111110),px(%0000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0001100),px(%1111110),px(%0111111),px(%1111001),px(%1111111),px(%1111000),px(%0000000)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0000011),px(%0000111),px(%1001111),px(%1111111),px(%1001111),px(%1111000),px(%0000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000000),px(%1111111),px(%1110011),px(%1111111),px(%1111111),px(%1100000),px(%0000000)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0000000),px(%0000000),px(%0000000),px(%1111111),px(%1111111),px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000000),px(%0000000),px(%0000000),px(%0011111),px(%1111100),px(%0000000),px(%0000000)
        .byte   px(%0011000),px(%0000000),px(%0000110),px(%0000000),px(%0000000),px(%0000011),px(%1100001),px(%1110000),px(%0000000),px(%0000000)
        .byte   px(%0000110),px(%0000000),px(%0000110),px(%0000000),px(%0000000),px(%0111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000001),px(%1110000),px(%0000110),px(%0000000),px(%0011111),px(%1000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0001111),px(%0000110),px(%0001111),px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%1111111),px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)

;;; ============================================================

da_end:
