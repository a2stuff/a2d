        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================
;;; Memory map
;;;
;;;              Main           Aux
;;;          :           : :           :
;;;          |           | |           |
;;;          | DHR       | | DHR       |
;;;  $2000   +-----------+ +-----------+
;;;          | IO Buffer | |Win Tables |
;;;  $1C00   +-----------+ |           |
;;;  $1B00   |           | +-----------+
;;;          |           | |           |
;;;          |           | |           |
;;;          | MP Src    | | MP Dst    |
;;;  $1580   +-----------+ +-----------+
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          | DA        | | DA (Copy) |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

        hires   := $2000        ; HR/DHR images are loaded directly into screen buffer
        kHiresSize = $2000

        ;; Minipix/Print Shop images are loaded/converted
        minipix_src_buf := $1580 ; Load address (main)
        kMinipixSrcSize = 576
        minipix_dst_buf := $1580 ; Convert address (aux)
        kMinipixDstSize = 26*52

        .assert (minipix_src_buf + kMinipixSrcSize) < DA_IO_BUFFER, error, "Not enough room for Minipix load buffer"
        .assert (minipix_dst_buf + kMinipixDstSize) < WINDOW_ICON_TABLES, error, "Not enough room for Minipix convert buffer"

;;; ============================================================

        .org $800

da_start:
        jmp     start

save_stack:
        .byte   0

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

        ;; Copy "call_main_template" routine to zero page
        COPY_BYTES sizeof_routine+1, routine, call_main_trampoline

        ;; run the DA
        jsr     init

        ;; tear down/exit
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ldx     save_stack
        txs

        rts
.endproc

call_main_trampoline   := $20 ; installed on ZP, turns off auxmem and calls...
call_main_addr         := call_main_trampoline+7 ; address patched in here

.proc routine
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     $1000  ; overwritten (in zp version)
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
        sizeof_routine = .sizeof(routine) ; can't .sizeof(proc) before declaration

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

.proc read_minipix_file
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL READ, read_minipix_params
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

params_start:
;;; This block gets copied between main/aux

;;; ProDOS MLI param blocks

        DEFINE_OPEN_PARAMS open_params, pathbuff, DA_IO_BUFFER
        DEFINE_GET_EOF_PARAMS get_eof_params

        DEFINE_READ_PARAMS read_params, hires, kHiresSize
        DEFINE_READ_PARAMS read_minipix_params, minipix_src_buf, kMinipixSrcSize

        DEFINE_CLOSE_PARAMS close_params

.params pathbuff                 ; 1st byte is length, rest is full path
length: .byte   $00
data:   .res    64, 0
.endparams


params_end:
;;; ----------------------------------------

        kDAWindowId = 100

.params line_pos
left:   .word   0
base:   .word   0
.endparams


event_params:   .tag MGTK::Event

.params window_title
        .byte 0                 ; length
.endparams

.params winfo
window_id:      .byte   kDAWindowId ; window identifier
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
mincontwidth:   .word   kScreenWidth
mincontlength:  .word   kScreenHeight
maxcontwidth:   .word   kScreenWidth
maxcontlength:  .word   kScreenHeight

.params port
viewloc:        DEFINE_POINT 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kScreenWidth, kScreenHeight
.endparams

pattern:        .res    8, 0
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams


.proc init
        copy    #0, mode

        ;; Get filename by checking DeskTop selected window/icon

        ;; Check that an icon is selected
        copy    #0, pathbuff::length
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
        inc16   src
        copy16  #(pathbuff::data), dst
        jsr     copy_pathbuff   ; copy x bytes (src) to (dst)

        ;; Append separator.
        lda     #'/'
        ldy     #0
        sta     (dst),y
        inc     pathbuff::length
        inc16   dst

        ;; Get file entry.
        lda     selected_file_list      ; file index in table
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
        sta     read_minipix_params::ref_num
        sta     close_params::ref_num

        MGTK_CALL MGTK::HideCursor
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
        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     exit
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     on_key
        bne     input_loop

on_key:
        lda     event_params + MGTK::Event::modifiers
        bne     input_loop
        lda     event_params + MGTK::Event::key
        cmp     #CHAR_ESCAPE
        beq     exit
        cmp     #' '
        bne     :+
        jsr     toggle_mode
:       jmp     input_loop

exit:
        jsr     set_bw_mode
        MGTK_CALL MGTK::HideCursor

        ;; Restore menu
        MGTK_CALL MGTK::DrawMenu
        sta     RAMWRTOFF
        sta     RAMRDOFF
        yax_call JUMP_TABLE_MGTK_RELAY, MGTK::HiliteMenu, last_menu_click_params
        sta     RAMWRTON
        sta     RAMRDON

        ;; Force desktop redraw
        MGTK_CALL MGTK::CloseWindow, winfo

        MGTK_CALL MGTK::ShowCursor
        rts                     ; exits input loop
.endproc

.proc show_file
        jsr     get_file_eof

        ;; If bigger than $2000, assume DHR

        lda     get_eof_params::eof ; fancy 3-byte unsigned compare
        cmp     #<(kHiresSize+1)
        lda     get_eof_params::eof+1
        sbc     #>(kHiresSize+1)
        lda     get_eof_params::eof+2
        sbc     #^(kHiresSize+1)
        bcc     :+
        jmp     show_dhr_file

        ;; If bigger than 576, assume HR

:       lda     get_eof_params::eof
        cmp     #<(kMinipixSrcSize+1)
        lda     get_eof_params::eof+1
        sbc     #>(kMinipixSrcSize+1)
        bcc     :+
        jmp     show_hr_file

        ;; Otherwise, assume Minipix

:       jmp     show_minipix_file
.endproc

.proc show_hr_file
        sta     PAGE2OFF
        jsr     read_file
        jsr     close_file

        jsr     hr_to_dhr
        rts
.endproc

.proc show_dhr_file
        ptr := $06

        ;; AUX memory half
        sta     PAGE2OFF
        jsr     read_file

        ;; NOTE: Why not just load into Aux directly by setting
        ;; PAGE2ON? This works unless loading from a RamWorks-based
        ;; RAM Disk, where things get messed up. This is slightly
        ;; slower in the non-RamWorks case.
        ;; TODO: Load directly into Aux if RamWorks is not present.

        ;; Copy MAIN to AUX

        sta     CLR80COL        ; read main, write aux
        sta     RAMRDOFF
        sta     RAMWRTON

        copy16  #hires, ptr
        ldx     #>kHiresSize    ; number of pages to copy
        ldy     #0
:       lda     (ptr),y
        sta     (ptr),y
        iny
        bne     :-
        inc     ptr+1
        dex
        bne     :-

        sta     RAMWRTON        ; read aux, write aux
        sta     RAMRDON
        sta     SET80COL

        ;; MAIN memory half
        sta     PAGE2OFF
        jsr     read_file
        jsr     close_file

        rts
.endproc


.proc show_minipix_file
        jsr     set_bw_mode

        ;; Load file at minipix_src_buf (MAIN $1800)
        jsr     read_minipix_file
        jsr     close_file

        ;; Convert (main to aux)
        jsr     convert_minipix_to_bitmap

        ;; Draw
        MGTK_CALL MGTK::PaintBits, paintbits_params

        rts

        kMinipixWidth = 88 * 2
        kMinipixHeight = 52

.params paintbits_params
viewloc:        DEFINE_POINT (kScreenWidth - kMinipixWidth)/2, (kScreenHeight - kMinipixHeight)/2
mapbits:        .addr   minipix_dst_buf
mapwidth:       .byte   26
reserved:       .byte   0
maprect:        DEFINE_RECT 0,0,kMinipixWidth-1,kMinipixHeight-1
.endparams

.endproc



;;; ============================================================
;;; Convert single hires to double hires

;;; Assumes the image is loaded to MAIN $2000 and
;;; relies on the hr_to_dhr.inc table.

.proc hr_to_dhr
        ptr     := $06
        kRows   = 192
        kCols   = 40
        spill   := $08          ; spill-over

        lda     #0              ; row
rloop:  pha
        tax
        copy    hires_table_lo,x, ptr
        copy    hires_table_hi,x, ptr+1

        ldy     #kCols-1         ; col

        copy    #0, spill       ; spill-over

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

        copy    #0, spill       ; no spill bit
next:
        dey
        bpl     cloop

        pla
        clc
        adc     #1
        cmp     #kRows
        bne     rloop

        ;; TODO: Restore PAGE2 state?
done:   sta     PAGE2OFF
        rts
.endproc

;;; ============================================================
;;; Minipix images

;;; Assert: Running from Aux
;;; Source is in Main, destination is in Aux

.proc convert_minipix_to_bitmap
        kRows   = 52
        kCols   = 88            ; pixels

        src := $06
        dst := $08

        srcbit := $0A
        dstbit := $0B
        row    := $0C

        copy16  #minipix_src_buf, src
        copy16  #minipix_dst_buf, dst

        ;; c/o Kent Dickey on comp.sys.apple2.programmer
        ;; https://groups.google.com/d/msg/comp.sys.apple2.programmer/XB0jUEvrAhE/loRorS5fBwAJ

        ldx     #kRows
        stx     row
        ldy     #0              ; Y remains unchanged throughout

        ;; For each row...
dorow:  ldx     #8
        stx     srcbit
        ldx     #7
        stx     dstbit
        ldx     #kCols

        ;; Process each bit
:       jsr     getbit
        jsr     putbit2
        dex
        bne     :-

        ;; We've written out 88*2 bits = 176 bits.  This means 1 bit was shifted into
        ;; the last bit.  We need to get it from the MSB to the LSB, so it needs
        ;; to be shifted down 7 bits
:       clc
        jsr     putbit1
        dex
        cpx     #AS_BYTE(-7)    ; do 7 times == 7 bits
        bne     :-

        dec     row
        bne     dorow

        ;; Resume running from Aux
        sta     RAMRDON
        sta     RAMWRTON
        rts

.proc getbit
        sta     RAMRDOFF
        sta     RAMWRTOFF

        lda     (src),y
        rol
        sta     (src),y
        dec     srcbit
        bne     done

        inc     src
        bne     :+
        inc     src+1
:       lda     #8
        sta     srcbit

done:   rts
.endproc

.proc putbit2
        php
        jsr     putbit1
        plp
        ;; fall through
.endproc
.proc putbit1
        sta     RAMRDON
        sta     RAMWRTON

        lda     (dst),y
        ror
        sta     (dst),y
        dec     dstbit
        bne     done

        ror                     ; shift once more to get bits in right place
        sta     (dst),y
        inc     dst
        bne     :+
        inc     dst+1
:       lda     #7
        sta     dstbit

done:   rts
.endproc

.endproc

;;; ============================================================
;;; Color/B&W Toggle

mode:   .byte   0               ; 0 = B&W, $80 = color

.proc toggle_mode
        lda     mode
        bne     set_bw_mode
        ;; fall through
.endproc

.proc set_color_mode
        lda     mode
        bne     done
        copy    #$80, mode

        copy16  #JUMP_TABLE_COLOR_MODE, call_main_addr
        jsr     call_main_trampoline

done:   rts
.endproc

.proc set_bw_mode
        lda     mode
        beq     done
        copy    #0, mode

        copy16  #JUMP_TABLE_MONO_MODE, call_main_addr
        jsr     call_main_trampoline

done:   rts
.endproc

;;; ============================================================

        .include "inc/hires_table.inc"
        .include "inc/hr_to_dhr.inc"

;;; ============================================================

da_end:
