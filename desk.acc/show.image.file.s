        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"
        .include "../desktop/icontk.inc"

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
;;;          |           | |           | DA is copied to AUX for MGTK param blocks
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

.macro MGTK_RELAY_CALL call, params
    .if .paramcount > 1
        param_call        JUMP_TABLE_MGTK_RELAY, (call), (params)
    .else
        param_call        JUMP_TABLE_MGTK_RELAY, (call), 0
    .endif
.endmacro

;;; ============================================================

        .org $800

da_start:
        jmp     start

save_stack:
        .byte   0

.proc start
        tsx
        stx     save_stack

        ;; Copy DA to AUX (for resources)
        copy16  #da_start, STARTLO
        copy16  #da_start, DESTINATIONLO
        copy16  #da_end, ENDLO
        sec                     ; main>aux
        jsr     AUXMOVE

        ;; run the DA
        jsr     init

        ldx     save_stack
        txs

        rts
.endproc

;;; ============================================================
;;; ProDOS MLI param blocks

        DEFINE_OPEN_PARAMS open_params, pathbuf, DA_IO_BUFFER
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, pathbuf
        DEFINE_GET_EOF_PARAMS get_eof_params

        DEFINE_READ_PARAMS read_params, hires, kHiresSize
        DEFINE_READ_PARAMS read_minipix_params, minipix_src_buf, kMinipixSrcSize

        DEFINE_CLOSE_PARAMS close_params

pathbuf:        .res    kPathBufferSize, 0

;;; ============================================================

        kDAWindowId = 100

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
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kScreenWidth, kScreenHeight
.endparams

pattern:        .res    8, 0
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

;;; ============================================================

.proc copy_event_aux_to_main
        copy16  #event_params, STARTLO
        copy16  #event_params + .sizeof(MGTK::Event) - 1, ENDLO
        copy16  #event_params, DESTINATIONLO
        clc                     ; aux > main
        jmp     AUXMOVE
.endproc

;;; ============================================================


.proc init
        copy    #0, mode

        INVOKE_PATH := $220
        lda     INVOKE_PATH
    IF_EQ
        rts
    END_IF
        COPY_STRING     INVOKE_PATH, pathbuf

        param_call JUMP_TABLE_MLI, OPEN, open_params
        lda     open_params::ref_num
        sta     get_eof_params::ref_num
        sta     read_params::ref_num
        sta     read_minipix_params::ref_num
        sta     close_params::ref_num

        MGTK_RELAY_CALL MGTK::HideCursor
        jsr     clear_screen
        jsr     set_color_mode
        jsr     show_file
        MGTK_RELAY_CALL MGTK::ShowCursor

        MGTK_RELAY_CALL MGTK::FlushEvents
        MGTK_RELAY_CALL MGTK::ObscureCursor

        ;; fall through
.endproc

;;; ============================================================
;;; Main Input Loop

.proc input_loop
        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        jsr     copy_event_aux_to_main

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
        cmp     #CHAR_RETURN
        beq     exit
        cmp     #' '
        bne     :+
        jsr     toggle_mode
:       jmp     input_loop

exit:
        jsr     JUMP_TABLE_RGB_MODE

        ;; Force desktop redraw
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo

        ;; Restore menu
        MGTK_RELAY_CALL MGTK::DrawMenu
        jsr     JUMP_TABLE_HILITE_MENU

        rts                     ; exits input loop
.endproc

.proc show_file
        ;; Check file type
        param_call JUMP_TABLE_MLI, GET_FILE_INFO, get_file_info_params
        lda     get_file_info_params::file_type
        cmp     #FT_GRAPHICS
        bne     get_eof

        ;; FOT files - auxtype $4000 / $4001 are packed hires/double-hires
        lda     get_file_info_params::aux_type+1
        cmp     #$40
        bne     show_fot_file

        lda     get_file_info_params::aux_type
        cmp     #$00
        bne     :+
        jmp     show_packed_hr_file
:       cmp     #$01
        bne     show_fot_file
        jmp     show_packed_dhr_file

        ;; Otherwise, rely on size heuristics to determine the type
get_eof:
        param_call JUMP_TABLE_MLI, GET_EOF, get_eof_params

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

.proc show_fot_file
        ;; Per File Type $08 (8) Note:

        ;; ...you can determine the mode of the file by examining byte
        ;; +120 (+$78). The value of this byte, which ranges from zero
        ;; to seven, is interpreted as follows:
        ;;
        ;; Mode                         Page 1    Page 2
        ;; 280 x 192 Black & White        0         4
        ;; 280 x 192 Limited Color        1         5
        ;; 560 x 192 Black & White        2         6
        ;; 140 x 192 Full Color           3         7

SIGNATURE       := hires + 120
kSigColor       = %00000001
kSigDHR         = %00000010

        ;; At least one page...
        sta     PAGE2OFF
        param_call JUMP_TABLE_MLI, READ, read_params

        lda     SIGNATURE
        sta     signature

        ;; HR or DHR?
        and     #kSigDHR
        bne     dhr

        ;; If HR, convert to DHR.
        jsr     hr_to_dhr
        jmp     finish

        ;; If DHR, copy Main>Aux and load Main page.
dhr:    jsr     copy_hires_to_aux
        param_call JUMP_TABLE_MLI, READ, read_params

finish: param_call JUMP_TABLE_MLI, CLOSE, close_params

        lda     signature
        and     #kSigColor
        bne     :+
        jsr     set_bw_mode
:       rts

signature:
        .byte   0
.endproc


.proc show_hr_file
        sta     PAGE2OFF
        param_call JUMP_TABLE_MLI, READ, read_params
        param_call JUMP_TABLE_MLI, CLOSE, close_params

        jsr     hr_to_dhr
        rts
.endproc

.proc show_dhr_file
        ptr := $06

        ;; AUX memory half
        sta     PAGE2OFF
        param_call JUMP_TABLE_MLI, READ, read_params

        ;; NOTE: Why not just load into Aux directly by setting
        ;; PAGE2ON? This works unless loading from a RamWorks-based
        ;; RAM Disk, where things get messed up. This is slightly
        ;; slower in the non-RamWorks case.
        ;; TODO: Load directly into Aux if RamWorks is not present.

        jsr     copy_hires_to_aux

        ;; MAIN memory half
        param_call JUMP_TABLE_MLI, READ, read_params
        param_call JUMP_TABLE_MLI, CLOSE, close_params

        rts
.endproc

.proc copy_hires_to_aux
        ptr := $06

        sta     CLR80COL
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

        sta     SET80COL
        sta     RAMWRTOFF
        rts
.endproc


.proc show_minipix_file
        jsr     set_bw_mode

        ;; Load file at minipix_src_buf (MAIN $1800)
        param_call JUMP_TABLE_MLI, READ, read_minipix_params
        param_call JUMP_TABLE_MLI, CLOSE, close_params

        ;; Convert (main to aux)
        jsr     convert_minipix_to_bitmap

        ;; Draw
        MGTK_RELAY_CALL MGTK::SetPort, winfo::port
        MGTK_RELAY_CALL MGTK::PaintBits, paintbits_params

        rts

        kMinipixWidth = 88 * 2
        kMinipixHeight = 52

.params paintbits_params
        DEFINE_POINT viewloc, (kScreenWidth - kMinipixWidth)/2, (kScreenHeight - kMinipixHeight)/2
mapbits:        .addr   minipix_dst_buf
mapwidth:       .byte   26
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kMinipixWidth-1, kMinipixHeight-1
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

done:   rts
.endproc

;;; ============================================================
;;; Minipix images

;;; Assert: Running from Main
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

        rts

.proc getbit
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

done:
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
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

        jsr     JUMP_TABLE_COLOR_MODE

done:   rts
.endproc

.proc set_bw_mode
        lda     mode
        beq     done
        copy    #0, mode

        jsr     JUMP_TABLE_MONO_MODE

done:   rts
.endproc

;;; ============================================================

.proc unpack_read
        DEFINE_READ_PARAMS read_buf_params, read_buf, 0

        ptr := $06

hr_file:
        lda     #0
        beq     start           ; Always

dhr_file:
        lda     #$C0            ; S = is dhr?, V = is aux page?
        ;; Fall through


start:  sta     dhr_flag
        copy16  #hires, ptr

        sta     PAGE2OFF

        copy    open_params::ref_num, read_buf_params::ref_num

        ;; Read next op/count byte
loop:   copy    #1, read_buf_params::request_count
        param_call JUMP_TABLE_MLI, READ, read_buf_params
        bcc     body

        ;; EOF (or other error) - finish up
        param_call JUMP_TABLE_MLI, CLOSE, close_params
        bit     dhr_flag        ; if hires, need to convert
        bmi     :+
        jsr     hr_to_dhr
:       rts

        ;; Process op/count
body:   lda     read_buf
        and     #%00111111      ; count is low 6 bits + 1
        sta     count
        inc     count

        lda     read_buf
        and     #%11000000      ; operation is top 2 bits
        bne     not_00

        ;; --------------------------------------------------
        ;; %00...... = 1 to 64 bytes follow - all different

        copy    count, read_buf_params::request_count
        param_call JUMP_TABLE_MLI, READ, read_buf_params
        ldy     #0

        ldx     #0
:       lda     read_buf,x
        jsr     write
        inx
        cpx     count
        bne     :-

        jmp     loop

        ;; --------------------------------------------------

not_00: cmp     #%01000000
        bne     not_01

        ;; --------------------------------------------------
        ;; %01...... = 3, 5, 6, or 7 repeats of next byte

        copy    #1, read_buf_params::request_count
        param_call JUMP_TABLE_MLI, READ, read_buf_params
        ldy     #0
        lda     read_buf

:       jsr     write
        dec     count
        bne     :-

        jmp     loop

        ;; --------------------------------------------------

not_01: cmp     #%10000000
        bne     not_10

        ;; --------------------------------------------------
        ;; %10...... = 1 to 64 repeats of next 4 bytes

        copy    #4, read_buf_params::request_count
        param_call JUMP_TABLE_MLI, READ, read_buf_params
        ldy     #0

:       lda     read_buf+0
        jsr     write
        lda     read_buf+1
        jsr     write
        lda     read_buf+2
        jsr     write
        lda     read_buf+3
        jsr     write
        dec     count
        bne     :-

        jmp     loop

        ;; --------------------------------------------------

not_10:
        ;; --------------------------------------------------
        ;; %11...... = 1 to 64 repeats of next byte taken as 4 bytes

        copy    #1, read_buf_params::request_count
        param_call JUMP_TABLE_MLI, READ, read_buf_params
        ldy     #0
        lda     read_buf

:       jsr     write
        jsr     write
        jsr     write
        jsr     write
        dec     count
        bne     :-

        jmp     loop

        ;; --------------------------------------------------

.proc write
        ;; ASSERT: Y=0
        sta     (ptr),y
        inc     ptr
        beq     :+
        rts

:       pha

        inc     ptr+1
        lda     ptr+1
        cmp     #$40            ; did we hit page 2?
        bne     exit
        lda     #$20            ; yes, back to page 1
        sta     ptr+1

        bit     dhr_flag        ; if DHR aux half, need to copy page to aux
        bvc     exit            ; nope
        copy    #$80, dhr_flag

        ;; Save ptr, X, Y
        lda     ptr
        pha
        lda     ptr+1
        pha
        txa
        pha
        tya
        pha

        jsr     copy_hires_to_aux

        ;; Restore ptr, X, Y
        pla
        tay
        pla
        tax
        pla
        sta     ptr+1
        pla
        sta     ptr

exit:   pla
        rts
.endproc

        ;; --------------------------------------------------

dhr_flag:
        .byte   0

count:  .byte   0

read_buf:
        .res    64

.endproc
show_packed_hr_file     := unpack_read::hr_file
show_packed_dhr_file    := unpack_read::dhr_file

;;; ============================================================
;;; Clear screen to black

.proc clear_screen
        ptr := $6
        kHiresSize = $2000

        sta     PAGE2ON         ; Clear aux
        jsr     clear
        sta     PAGE2OFF        ; Clear main
        jsr     clear
        rts

clear:  copy16  #hires, ptr
        lda     #0              ; clear to black
        ldx     #>kHiresSize    ; number of pages
        ldy     #0              ; pointer within page
:       sta     (ptr),y
        iny
        bne     :-
        inc     ptr+1
        dex
        bne     :-
        rts

done:
.endproc

;;; ============================================================

        .include "../inc/hires_table.inc"
        .include "inc/hr_to_dhr.inc"

;;; ============================================================

da_end:
