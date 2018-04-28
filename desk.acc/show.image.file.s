        .setcpu "65C02"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"

        .include "../mgtk.inc"
        .include "../desktop.inc" ; get selection, font
        .include "../macros.inc"

        .org $800

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
call_main_addr         := call_main_trampoline+7 ; address patched in here

;;;  Copy the following "call_main_template" routine to $20
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
        jsr     $1000  ; overwritten (in zp version)
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
        sizeof_routine := * - routine ; can't .sizeof(proc) before declaration
        ;;  https://github.com/cc65/cc

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

;;; ============================================================
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

;;; ============================================================

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

        hires   := $2000
        hires_size := $2000

        DEFINE_OPEN_PARAMS open_params, pathbuff, $C00
        DEFINE_GET_EOF_PARAMS get_eof_params
        DEFINE_READ_PARAMS read_params, hires, hires_size
        DEFINE_CLOSE_PARAMS close_params

.proc pathbuff                 ; 1st byte is length, rest is full path
length: .byte   $00
data:   .res    64, 0
.endproc


params_end:
;;; ----------------------------------------

        da_window_id := 100

.proc line_pos
left:   .word   0
base:   .word   0
.endproc


.proc event_params             ; queried to track mouse-up
kind:  .byte   $00

;;; if state is MGTK::event_kind_key_down
key    := *
modifiers := *+1

;;; otherwise
xcoord := *
ycoord := *+2

        .res    4               ; space for both
.endproc

        default_width := 560
        default_height := 192
        default_left := 0
        default_top := 0

.proc window_title
        .byte 0                 ; length
.endproc

.proc winfo
window_id:     .byte   da_window_id       ; window identifier
options:  .byte   MGTK::option_dialog_box
title:  .addr   window_title
hscroll:.byte   MGTK::scroll_option_none
vscroll:.byte   MGTK::scroll_option_none
hthumbmax:  .byte   32
hthumbpos:  .byte   0
vthumbmax:  .byte   32
vthumbpos:  .byte   0
status: .byte   0
reserved:       .byte   0
mincontwidth:     .word   default_width
mincontlength:     .word   default_height
maxcontwidth:     .word   default_width
maxcontlength:     .word   default_height

.proc port
viewloc:        DEFINE_POINT default_left, default_top
mapbits:   .addr   MGTK::screen_mapbits
mapwidth: .word   MGTK::screen_mapwidth
maprect:        DEFINE_RECT 0, 0, default_width, default_height
.endproc

pattern:.res    8, 0
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc: DEFINE_POINT 0, 0
penwidth: .byte   1
penheight: .byte   1
penmode:   .byte   0
textback:  .byte   $7F
textfont:   .addr   DEFAULT_FONT
nextwinfo:   .addr   0
.endproc


.proc init
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ;; Get filename by checking DeskTop selected window/icon

        ;; Check that an icon is selected
        lda     #0
        sta     pathbuff::length
        lda     selected_file_count
        beq     abort           ; some file properties?
        lda     path_index      ; prefix index in table
        bne     :+
abort:  rts

        ;; Copy path (prefix) into pathbuff buffer.
:       src := $06
        dst := $08

        asl     a               ; (since address table is 2 bytes wide)
        tax
        copy16  path_table,x, src
        ldy     #0
        lda     (src),y
        tax
        inc     src
        bne     :+
        inc     src+1
:       copy16  #(pathbuff::data), dst
        jsr     copy_pathbuff   ; copy x bytes (src) to (dst)

        ;; Append separator.
        lda     #'/'
        ldy     #0
        sta     (dst),y
        inc     pathbuff::length
        inc     dst
        bne     :+
        inc     dst+1

        ;; Get file entry.
:       lda     selected_file_list      ; file index in table
        asl     a               ; (since table is 2 bytes wide)
        tax
        copy16  file_table,x, src

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
:       jsr     copy_pathbuff   ; copy x bytes (src) to (dst)

        jmp     open_file_and_init_window

.proc copy_pathbuff             ; copy x bytes from src to dst
        ldy     #0              ; incrementing path length and dst
loop:   lda     (src),y
        sta     (dst),y
        iny
        inc     pathbuff::length
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

        MGTK_CALL MGTK::HideCursor
        jsr     stash_menu
        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::SetPort, winfo::port
        jsr     set_color_mode
        jsr     show_file
        MGTK_CALL MGTK::ShowCursor

        MGTK_CALL MGTK::FlushEvents
        MGTK_CALL MGTK::ObscureCursor

        ;; fall through
.endproc

;;; ============================================================
;;; Main Input Loop

.proc input_loop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::event_kind_button_down ; was clicked?
        beq     exit
        cmp     #MGTK::event_kind_key_down  ; any key?
        beq     on_key
        bne     input_loop

on_key:
        lda     event_params::modifiers
        bne     input_loop
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     exit
        bne     input_loop

exit:
        jsr     set_bw_mode
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::CloseWindow, winfo
        DESKTOP_CALL DT_REDRAW_ICONS
        jsr     unstash_menu
        MGTK_CALL MGTK::ShowCursor

        rts                     ; exits input loop
.endproc

.proc show_file
        jsr     get_file_eof

        ;; If bigger than $2000, assume DHR

        lda     get_eof_params::eof ; fancy 3-byte unsigned compare
        cmp     #<(hires_size+1)
        lda     get_eof_params::eof+1
        sbc     #>(hires_size+1)
        lda     get_eof_params::eof+2
        sbc     #^(hires_size+1)
        bcs     dhr

        jsr     show_hr_file
        jmp     close

dhr:    jsr     show_dhr_file

close:  jsr     close_file
        rts
.endproc

.proc show_hr_file
        sta     PAGE2OFF
        jsr     read_file
        jsr     close_file

        jsr     hr_to_dhr
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

;;; ============================================================
;;; Convert single hires to double hires

;;; Assumes the image is loaded to MAIN $2000 and
;;; relies on the hr_to_dhr.inc table.

.proc hr_to_dhr
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

        lda     hr_to_dhr_aux,x
        sta     PAGE2ON
        sta     (ptr),y
        lda     hr_to_dhr_main,x
        ora     spill           ; apply previous spill bit (to bit 6)
        sta     PAGE2OFF
        sta     (ptr),y

        ror                     ; move high bit to bit 6
        and     #(1 << 6)
        sta     spill

        jmp     next

hibitset:
        ;; simple case - no bit spillage
        lda     hr_to_dhr_aux,x
        sta     PAGE2ON
        sta     (ptr),y
        lda     hr_to_dhr_main,x
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

;;; ============================================================
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
        copy16  #stash, dst

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
        copy16  #stash, src

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

;;; ============================================================
;;; Color/B&W Toggle

;;; TODO: Also consider Le Chat Mauve BW560 mode.
;;; https://github.com/inexorabletash/a2d/issues/41

.proc set_color_mode
        ;; AppleColor Card - Mode 2 (Color 140x192)
        sta     SET80VID
        lda     AN3_OFF
        lda     AN3_ON
        lda     AN3_OFF
        lda     AN3_ON
        lda     AN3_OFF

        ;; Apple IIgs - DHR Color
        jsr     test_iigs
        bcs     done
        lda     #%00000000
        sta     NEWVIDEO

done:   rts
.endproc

.proc set_bw_mode
        ;; AppleColor Card - Mode 1 (Monochrome 560x192)
        sta     CLR80VID
        lda     AN3_OFF
        lda     AN3_ON
        lda     AN3_OFF
        lda     AN3_ON
        sta     SET80VID
        lda     AN3_OFF

        ;; Apple IIgs - DHR B&W
        jsr     test_iigs
        bcs     done
        lda     #%00100000
        sta     NEWVIDEO

done:   rts
.endproc

;;; Returns with carry clear if IIgs, set otherwise.
.proc test_iigs
        lda     ROMIN2
        sec
        jsr     $FE1F
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

        .include "inc/hires_table.inc"
        .include "inc/hr_to_dhr.inc"
