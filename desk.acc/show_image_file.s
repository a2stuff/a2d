        .setcpu "65C02"
        .org $800

        .include "apple2.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"
        .include "a2d.inc"

        ;; Big questions:
        ;; * How can we hide/show the cursor on demand?
        ;; * Can we trigger menu redraw? (if not, need to preserve for fullscreen)

start:  jmp     copy2aux

save_stack:.byte   0

;;; Copy $800 through $13FF (the DA) to aux
.proc copy2aux
        tsx
        stx     save_stack
        sta     RAMWRTON
        ldy     #0
src:    lda     start,y         ; self-modified
dst:    sta     start,y         ; self-modified
        dey
        bne     src
        sta     RAMWRTOFF
        inc     src+2
        inc     dst+2
        sta     RAMWRTON
        lda     dst+2
        cmp     #$14
        bne     src
.endproc

call_main_trampoline   := $20 ; installed on ZP, turns off auxmem and calls...
call_main_addr         := call_main_trampoline+7        ; address patched in here

;;; Copy the following "call_main_template" routine to $20
.scope
        sta     RAMWRTON
        sta     RAMRDON
        ldx     #sizeof_routine
loop:   lda     routine,x
        sta     call_main_trampoline,x
        dex
        bpl     loop
        jmp     call_init
.endscope

.proc routine
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     $1000           ; overwritten (in zp version)
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
        sizeof_routine := * - routine ; can't .sizeof(proc) before declaration
        ;; https://github.com/cc65/cc65/issues/478

.proc call_init
        ;; run the DA
        jsr     init

        ;; tear down/exit
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        sta     RAMRDOFF
        sta     RAMWRTOFF
        ldx     save_stack
        txs
        rts
.endproc

;;; ==================================================
;;; ProDOS MLI calls

.proc open_file
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL OPEN, open_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

.proc get_file_eof
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL GET_EOF, get_eof_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

.proc read_file
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL READ, read_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

.proc close_file
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL CLOSE, close_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

;;; ==================================================

;;; Copies param blocks from Aux to Main
.proc copy_params_aux_to_main
        ldy     #(params_end - params_start + 1)
        sta     RAMWRTOFF
loop:   lda     params_start - 1,y
        sta     params_start - 1,y
        dey
        bne     loop
        sta     RAMRDOFF
        rts
.endproc

;;; Copies param blocks from Main to Aux
.proc copy_params_main_to_aux
        pha
        php
        sta     RAMWRTON
        ldy     #(params_end - params_start + 1)
loop:   lda     params_start - 1,y
        sta     params_start - 1,y
        dey
        bne     loop
        sta     RAMRDON
        plp
        pla
        rts
.endproc

;;; ----------------------------------------

params_start:
;;; This block gets copied between main/aux

;;; ProDOS MLI param blocks

.proc open_params
        .byte   3               ; param_count
        .addr   pathname        ; pathname
        .addr   $0C00           ; io_buffer
ref_num:.byte   0               ; ref_num
.endproc

.proc get_eof_params
        .byte   2               ; param_count
ref_num:.byte   0               ; ref_num
length: .byte   0,0,0           ; EOF (lo, mid, hi)
.endproc

        hires   := $2000
        hires_size := $2000

.proc read_params
        .byte   4               ; param_count
ref_num:.byte   0               ; ref_num
buffer: .addr   hires           ; data_buffer
request:.word   hires_size      ; request_count
        .word   0               ; trans_count
.endproc

.proc close_params
        .byte   1               ; param_count
ref_num:.byte   0               ; ref_num
.endproc

.proc pathname                 ; 1st byte is length, rest is full path
length: .byte   $00
data:   .res    64, 0
.endproc


params_end:
;;; ----------------------------------------

        window_id := $64

.proc line_pos
left:   .word   0
base:   .word   0
.endproc


.proc input_params             ; queried to track mouse-up
state:  .byte   $00
.endproc

        default_width := 560
        default_height := 192
        default_left := 0
        default_top := 0

.proc window_title
        .byte 0                 ; length
.endproc

.proc window_params
id:     .byte   window_id       ; window identifier
flags:  .byte   A2D_CWF_NOTITLE
title:  .addr   window_title

hscroll:.byte   A2D_CWS_NOSCROLL
vscroll:.byte   A2D_CWS_NOSCROLL
hsmax:  .byte   32
hspos:  .byte   0
vsmax:  .byte   32
vspos:  .byte   0
        .byte   0, 0            ; ???
widtha: .word   default_width
heighta:.word   default_height
widthb: .word   default_width
heightb:.word   default_height

.proc box
left:   .word   default_left
top:    .word   default_top
addr:   .word   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoffset:.word   0
voffset:.word   0
width:  .word   default_width
height: .word   default_height
.endproc

pattern:.res    8, 0
mskand: .byte   A2D_DEFAULT_MSKAND
mskor:  .byte   A2D_DEFAULT_MSKOR
        .byte   $00,$00,$00,$00
hthick: .byte   1
vthick: .byte   1
        .byte   $00,$7F,$00,$88,$00,$00
.endproc


.proc init
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ;; Get filename by checking DeskTop selected window/icon

        ;; Check that an icon is selected
        lda     #0
        sta     pathname::length
        lda     file_selected
        beq     abort           ; some file properties?
        lda     path_index      ; prefix index in table
        bne     :+
abort:  rts

        ;; Copy path (prefix) into pathname buffer.
:       src := $06
        dst := $08

        asl     a               ; (since address table is 2 bytes wide)
        tax
        lda     path_table,x          ; pathname ???
        sta     src
        lda     path_table+1,x
        sta     src+1
        ldy     #0
        lda     (src),y
        tax
        inc     src
        bne     :+
        inc     src+1
:       lda     #<(pathname::data)
        sta     dst
        lda     #>(pathname::data)
        sta     dst+1
        jsr     copy_pathname   ; copy x bytes (src) to (dst)

        ;; Append separator.
        lda     #'/'
        ldy     #0
        sta     (dst),y
        inc     pathname::length
        inc     dst
        bne     :+
        inc     dst+1

        ;; Get file entry.
:       lda     file_index      ; file index in table
        asl     a               ; (since table is 2 bytes wide)
        tax
        lda     file_table,x
        sta     src
        lda     file_table+1,x
        sta     src+1

        ;; Exit if a directory.
        ldy     #2              ; 2nd byte of entry
        lda     (src),y
        and     #$70            ; check that one of bits 4,5,6 is set ???
        ;; some vague patterns, but unclear
        ;; basic = $32,$33, text = $52, sys = $11,$14,??, bin = $23,$24,$33
        ;; dir = $01 (so not shown)
        bne     :+
        rts                     ; abort ???

        ;; Append filename to path.
:       ldy     #9
        lda     (src),y         ; grab length
        tax                     ; name has spaces before/after
        dex                     ; so subtract 2 to get actual length
        dex
        clc
        lda     src
        adc     #11             ; 9 = length, 10 = space, 11 = name
        sta     src
        bcc     :+
        inc     src+1
:       jsr     copy_pathname   ; copy x bytes (src) to (dst)

        jmp     open_file_and_init_window

.proc copy_pathname             ; copy x bytes from src to dst
        ldy     #0              ; incrementing path length and dst
loop:   lda     (src),y
        sta     (dst),y
        iny
        inc     pathname::length
        dex
        bne     loop
        tya
        clc
        adc     dst
        sta     dst
        bcc     end
        inc     dst+1
end:    rts
.endproc

.endproc

.proc open_file_and_init_window
        jsr     open_file
        lda     open_params::ref_num
        sta     get_eof_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num

        jsr     stash_menu

        ;; create window
        A2D_CALL A2D_CREATE_WINDOW, window_params
        A2D_CALL A2D_SET_STATE, window_params::box

        jsr     show_file

        A2D_CALL $2B            ; ???
        ;; fall through
.endproc

;;; ==================================================
;;; Main Input Loop

.proc input_loop
        A2D_CALL A2D_GET_INPUT, input_params
        lda     input_params::state
        cmp     #1              ; was clicked?
        bne     input_loop      ; nope, keep waiting

        A2D_CALL A2D_DESTROY_WINDOW, window_params
        DESKTOP_CALL DESKTOP_REDRAW_ICONS
        jsr     unstash_menu

        rts                     ; exits input loop
.endproc

.proc show_file
        A2D_CALL A2D_HIDE_CURSOR
        jsr     get_file_eof

        ;; If bigger than $2000, assume DHR

        lda     get_eof_params::length ; fancy 3-byte unsigned compare
        cmp     #<(hires_size+1)
        lda     get_eof_params::length+1
        sbc     #>(hires_size+1)
        lda     get_eof_params::length+2
        sbc     #^(hires_size+1)
        bcs     dhr

        jsr     show_shr_file
        jmp     close

dhr:    jsr     show_dhr_file

close:  jsr     close_file
        A2D_CALL A2D_SHOW_CURSOR
        rts
.endproc

.proc show_shr_file
        sta     PAGE2OFF
        jsr     read_file
        jsr     close_file

        jsr     hgr_to_dhr
        rts
.endproc

.proc show_dhr_file
        ;; AUX memory half
        sta     PAGE2ON
        jsr     read_file

        ;; MAIN memory half
        sta     PAGE2OFF
        jsr     read_file

        ;; TODO: Restore PAGE2 state?

        rts
.endproc

;;; ==================================================
;;; Convert single hires to double hires

;;; Assumes the image is loaded to MAIN $2000 and
;;; relies on the hgr_to_dhr.inc table.

.proc hgr_to_dhr
        ptr     := $06
        rows    := 192
        cols    := 40
        spill   := $08          ; spill-over

        lda     #0              ; row
rloop:  pha
        tax
        lda     hires_table_lo,x
        sta     ptr
        lda     hires_table_hi,x
        sta     ptr+1

        ldy     #cols-1         ; col

        lda     #0
        sta     spill           ; spill-over

cloop:  lda     (ptr),y
        tax

        bmi     hibitset

        ;; complex case - need to spill in bit from prev col and store

        lda     hgr_to_dhr_aux,x
        sta     PAGE2ON
        sta     (ptr),y
        lda     hgr_to_dhr_main,x
        ora     spill           ; apply previous spill bit (to bit 6)
        sta     PAGE2OFF
        sta     (ptr),y

        ror                     ; move high bit to bit 6
        and     #(1 << 6)
        sta     spill

        jmp     next

hibitset:
        ;; simple case - no bit spillage
        lda     hgr_to_dhr_aux,x
        sta     PAGE2ON
        sta     (ptr),y
        lda     hgr_to_dhr_main,x
        sta     PAGE2OFF
        sta     (ptr),y

        lda     #0              ; no spill bit
        sta     spill
next:
        dey
        bpl     cloop

        pla
        inc
        cmp     #rows
        bne     rloop

        ;; TODO: Restore PAGE2 state?
done:   sta     PAGE2OFF
        rts
.endproc

;;; ==================================================
;;; Stash/Unstash Menu Bar

;;; Have not yet figured out how to force the menu to
;;; redraw, so instead we save the top 13 rows of the
;;; screen to a scratch buffer and restore after
;;; destroying the window.

        stash := $1200          ; Past DA code
        rows = 13
        cols = 40

.proc stash_menu
        src := $08
        dst := $06
        lda     #<stash
        sta     dst
        lda     #>stash
        sta     dst+1

        sta     PAGE2ON
        jsr     inner
        sta     PAGE2OFF

inner:

        lda     #0              ; row #
rloop:  pha
        tax
        lda     hires_table_lo,x
        sta     src
        lda     hires_table_hi,x
        sta     src+1
        ldy     #cols-1
cloop:  lda     (src),y
        sta     (dst),y
        dey
        bpl     cloop

        clc                     ; src += cols
        lda     src
        adc     #<cols
        sta     src
        lda     src+1
        adc     #>cols
        sta     src+1

        clc                     ; dst += cols
        lda     dst
        adc     #<cols
        sta     dst
        lda     dst+1
        adc     #>cols
        sta     dst+1

        pla
        inc
        cmp     #rows
        bcc     rloop
        rts
.endproc

.proc unstash_menu
        src := $08
        dst := $06
        lda     #<stash
        sta     src
        lda     #>stash
        sta     src+1

        sta     PAGE2ON
        jsr     inner
        sta     PAGE2OFF

inner:

        lda     #0              ; row #
rloop:  pha
        tax
        lda     hires_table_lo,x
        sta     dst
        lda     hires_table_hi,x
        sta     dst+1
        ldy     #cols-1
cloop:  lda     (src),y
        sta     (dst),y
        dey
        bpl     cloop

        clc                     ; src += cols
        lda     src
        adc     #<cols
        sta     src
        lda     src+1
        adc     #>cols
        sta     src+1

        clc                     ; dst += cols
        lda     dst
        adc     #<cols
        sta     dst
        lda     dst+1
        adc     #>cols
        sta     dst+1

        pla
        inc
        cmp     #rows
        bcc     rloop
        rts
.endproc

        .include "inc/hires_table.inc"
        .include "inc/hgr_to_dhr.inc"
