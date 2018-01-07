        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"

DESKTOP_INIT    := $0800        ; init location
L7ECA           := $7ECA        ; ???

;;; ==================================================
;;; Patch self in as ProDOS QUIT routine (LCBank2 $D100)
;;; and invoke QUIT. Note that only $200 bytes are copied.

.proc install_as_quit
        .org $2000

        src     := quit_routine
        dst     := SELECTOR

        lda     LCBANK2
        lda     LCBANK2

        ldy     #$00
loop:   lda     src,y
        sta     dst,y
        lda     src+$100,y
        sta     dst+$100,y
        dey
        bne     loop
        lda     ROMIN2

        MLI_CALL QUIT, quit_params

.proc quit_params
params: .byte   4
        .byte   0
        .word   0
        .byte   0
        .word   0
.endproc
.endproc ; install_as_quit

;;; ==================================================
;;; New QUIT routine. Gets relocated to $1000 by ProDOS before
;;; being executed.

.proc quit_routine
        .org    $1000
self:
        jmp     start

reinstall_flag:                 ; set once prefix saved and reinstalled
        .byte   0

        .byte   "Mouse Desk"
        .byte   0

splash_string:
        PASCAL_STRING "Loading Apple II DeskTop"

pathname:
        PASCAL_STRING "DeskTop2"

.proc read_params
params: .byte   4
ref_num:.byte   0
buffer: .addr   $1E00           ; so the $200 byte mark ends up at $2000
request:.word   $0400
trans:  .word   0
.endproc

.proc close_params
params: .byte   1
ref_num:.byte   0               ; close all
.endproc

.proc prefix_params
params: .byte   1
buffer: .addr   prefix_buffer
.endproc

.proc open_params
params: .byte   3
path:   .addr   pathname
buffer: .addr   $1A00
ref_num:.byte   0
.endproc


start:  lda     ROMIN2

        ;; Show a splash message on 80 column text screen
        jsr     SETVID
        jsr     SETKBD
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SLOT3ENTRY
        jsr     HOME

        lda     #$00            ; IIgs specific ???
        sta     SHADOW
        lda     #$40
        sta     RAMWRTON
        sta     $0100           ; ???
        sta     $0101           ; ???
        sta     RAMWRTOFF

        lda     #12             ; VTAB 12
        sta     CV
        jsr     VTAB

        lda     #80             ; HTAB (80-width)/2
        sec                     ; to center
        sbc     splash_string
        lsr     a
        sta     CH

        ldy     #$00
:       lda     splash_string+1,y
        ora     #$80
        jsr     COUT
        iny
        cpy     splash_string
        bne     :-

        ;; Close all open files (???)
        MLI_CALL CLOSE, close_params

        ;; Initialize system memory bitmap
        ldx     #BITMAP_SIZE-1
        lda     #$01            ; Protect ProDOS global page
        sta     BITMAP,x
        dex
        lda     #$00
L109F:  sta     BITMAP,x
        dex
        bpl     L109F
        lda     #%11001111       ; Protect ZP, stack, Text Page 1
        sta     BITMAP

        lda     reinstall_flag
        bne     no_reinstall

        ;; Re-install quit routine (with prefix memorized)
L10AF:  MLI_CALL GET_PREFIX, prefix_params
        beq     :+
        jmp     crash
:       lda     #$FF
        sta     reinstall_flag

        lda     IRQ_VECTOR
        sta     irq_saved
        lda     IRQ_VECTOR+1
        sta     irq_saved+1
        lda     LCBANK2
        lda     LCBANK2

        ldy     #0
:       lda     self,y
        sta     SELECTOR,y
        lda     self+$100,y
        sta     SELECTOR+$100,y
        dey
        bne     :-

        lda     ROMIN2
        jmp     done_reinstall

no_reinstall:
        lda     irq_saved
        sta     IRQ_VECTOR
        lda     irq_saved+1
        sta     IRQ_VECTOR+1

done_reinstall:
        ;; Set the prefix, read the first $400 bytes of this system
        ;; file in (at $1E00), and invoke $200 bytes into it (at $2000)

        MLI_CALL SET_PREFIX, prefix_params
        beq     :+
        jmp     prompt_for_system_disk
:       MLI_CALL OPEN, open_params
        beq     :+
        jmp     crash
:       lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        beq     :+
        jmp     crash
:       MLI_CALL CLOSE, close_params
        beq     :+
        jmp     crash
:       jmp     $2000           ; Invoke system file


        ;; Display a string, and wait for Return keypress
prompt_for_system_disk:
        jsr     SLOT3ENTRY      ; 80 column mode
        jsr     HOME
        lda     #12             ; VTAB 12
        sta     CV
        jsr     VTAB

        lda     #80             ; HTAB (80 - width)/2
        sec                     ; to center the string
        sbc     disk_prompt
        lsr     a
        sta     CH

        ldy     #$00
:       lda     disk_prompt+1,y
        ora     #$80
        jsr     COUT
        iny
        cpy     disk_prompt
        bne     :-

wait:   sta     KBDSTRB
:       lda     KBD
        bpl     :-
        and     #$7F
        cmp     #$0D            ; Return
        bne     wait
        jmp     start

disk_prompt:
        PASCAL_STRING "Insert the system disk and Press Return."

irq_saved:
        .addr   0

crash:  sta     $6              ; Crash?
        jmp     MONZ

prefix_buffer:
        .res    64, 0

.endproc ; quit_routine

;;; ==================================================
;;; This chunk is invoked at $2000 after the quit handler has been invoked
;;; and updated itself. Using the segment_*_tables below, this loads the
;;; DeskTop application into various parts of main, aux, and bank-switched
;;; memory, then invokes the DeskTop initialization routine.

.proc install_segments
        ;; Pad to be at $200 into the file
        .res    $200 - (.sizeof(install_as_quit) + .sizeof(quit_routine)), 0

        .org $2000

        jmp     start

.proc open_params
params: .byte   3
path:   .addr   pathname
buffer: .addr   $3000
ref_num:.byte   0
.endproc

.proc read_params
params: .byte   4
ref_num:.byte   0
buffer: .addr   0
request:.word   0
trans:  .word   0
.endproc

.proc close_params
params: .byte   1
ref_num:.byte   0
.endproc

.proc set_mark_params
params: .byte   2
ref_num:.byte   0
pos:    .faraddr $580           ; This many bytes before the good stuff.
.endproc

pathname:
        PASCAL_STRING "DeskTop2"

;;; Consecutive segments are loaded, |size| bytes are loaded at |addr|
;;; then relocated to |dest| according to |type|.

;;; Segments are:
;;; $4000 aux        - A2D GUI library and DeskTop code
;;; $D000 aux/banked - DeskTop code callable from main, and resources
;;; $FB00 aux/banked - more DeskTop resources (icons, strings, etc)
;;; $4000 main       - more DeskTop code
;;; $0800 main       - DeskTop initialization code; later overwritten by DAs
;;; $0290 main       - Routine to invoke other programs

segment_addr_table:
        .word   $3F00,$4000,$4000,$4000,$0800,$0290

segment_dest_table:
        .addr   $4000,$D000,$FB00,$4000,$0800,$0290

segment_size_table:
        .word   $8000,$1D00,$0500,$7F00,$0800,$0160

segment_type_table:             ; 0 = main, 1 = aux, 2 = banked (aux)
        .byte   1,2,2,0,0,0

num_segments:
        .byte   6

start:
        ;; Configure system bitmap - everything is available
        ldx     #BITMAP_SIZE-1
        lda     #0
:       sta     BITMAP+1,x
        dex
        bpl     :-

        ;; Open this system file
        php
        sei
        MLI_CALL OPEN, open_params
        plp
        and     #$FF            ; ???
        beq     :+
        brk                     ; crash
:       lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     read_params::ref_num
        php
        sei
        MLI_CALL SET_MARK, set_mark_params
        plp
        and     #$FF            ; ???
        beq     :+
        brk                     ; crash
:       lda     #0
        sta     segment_num

loop:   lda     segment_num
        cmp     num_segments
        bne     continue

        ;; Close and invoke DeskTop init routine
        php
        sei
        MLI_CALL CLOSE, close_params
        plp
        and     #$FF            ; ???
        beq     :+
        brk                     ; crash
:       jmp     DESKTOP_INIT

continue:
        asl     a
        tax
        lda     segment_addr_table,x
        sta     read_params::buffer
        lda     segment_addr_table+1,x
        sta     read_params::buffer+1
        lda     segment_size_table,x
        sta     read_params::request
        lda     segment_size_table+1,x
        sta     read_params::request+1
        php
        sei
        MLI_CALL READ, read_params
        plp
        and     #$FF            ; ???
        beq     :+
        brk                     ; crash
:       ldx     segment_num
        lda     segment_type_table,x
        beq     next_segment    ; type 0 = main, so done
        cmp     #2
        beq     :+
        jsr     aux_segment
        jmp     next_segment
:       jsr     banked_segment

next_segment:
        inc     segment_num
        jmp     loop

segment_num:  .byte   0

        ;; Handle bank-switched memory segment
.proc banked_segment
        src := $6
        dst := $8

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        lda     #$80            ; ???
        sta     $0100
        sta     $0101

        lda     #0
        sta     src
        sta     dst
        lda     segment_num
        asl     a
        tax
        lda     segment_dest_table+1,x
        sta     dst+1
        lda     read_params::buffer+1
        sta     src+1
        clc
        adc     segment_size_table+1,x
        sta     max_page
        lda     segment_size_table,x
        beq     :+
        inc     max_page

:       ldy     #0
loop:   lda     (src),y
        sta     (dst),y
        iny
        bne     loop
        inc     src+1
        inc     dst+1
        lda     src+1
        cmp     max_page
        bne     loop

        sta     ALTZPOFF
        lda     ROMIN2
        rts

max_page:
        .byte   0
.endproc

        ;; Handle aux memory segment
.proc aux_segment
        src := $6
        dst := $8

        lda     #0
        sta     src
        sta     dst
        lda     segment_num
        asl     a
        tax
        lda     segment_dest_table+1,x
        sta     dst+1
        lda     read_params::buffer+1
        sta     src+1
        clc
        adc     segment_size_table+1,x
        sta     max_page
        sta     RAMRDOFF
        sta     RAMWRTON
        ldy     #0
loop:   lda     (src),y
        sta     (dst),y
        iny
        bne     loop
        inc     src+1
        inc     dst+1
        lda     src+1
        cmp     max_page
        bne     loop
        sta     RAMWRTOFF
        rts

max_page:
        .byte   0
.endproc

        ;; Padding
        .res    $2200 - *,0
.endproc ; install_segments

;;; ==================================================
;;; Not sure where this could be invoked from

.proc rest
        .org $280

        SLOT1   := $C100
        TAB     := $09
        LF      := $0A
        CR      := $0D
        ESC     := $1B

        ;; Test for OpenApple+ClosedApple+P
        pha
        lda     BUTN0
        and     BUTN1
        bpl     :+
        lda     KBD
        cmp     #('P' | $80)
        beq     L0294
:       pla
        jmp     L7ECA           ; ???

        ;; Invoked if OA+CA+P is held
L0294:  sta     KBDSTRB
        sta     SET80COL
        sta     SET80VID
        sta     DHIRESON
        lda     TXTCLR
        lda     HIRES
        sta     ALTZPOFF
        sta     ROMIN2
        lda     #0
        sta     L03C5
        jmp     L035F


.proc send_spacing_sequence
        ldy     #0
:       lda     spacing_sequence,y
        beq     done
        jsr     cout
        iny
        jmp     :-
done:   rts
.endproc

.proc send_restore_state
        ldy     #$00
:       lda     restore_state,y
        beq     done
        jsr     cout
        iny
        jmp     :-
done:   rts
.endproc

.proc send_init_graphics
        ldx     #0
:       lda     init_graphics,x
        jsr     cout
        inx
        cpx     #6
        bne     :-
        rts
init_graphics:
        .byte   ESC,"G0560"     ; Graphics, 560 data bytes
.endproc

L02E6:  jsr     send_init_graphics
        ldy     #$00
        sty     L03CC
        lda     #$01
        sta     L03C9
        lda     #$00
        sta     L03C6
        sta     L03C7
L02FB:  lda     #$08
        sta     L03CB
        lda     L03C5
        sta     L03C8
L0306:  lda     L03C8
        jsr     L0393
        lda     L03CC
        lsr     a
        tay
        sta     LOWSCR
        bcs     L0319
        sta     HISCR
L0319:  lda     ($06),y
        and     L03C9
        cmp     #1
        ror     L03CA
        inc     L03C8
        dec     L03CB
        bne     L0306
        lda     L03CA
        eor     #$FF
        sta     LOWSCR
        jsr     cout
        lda     L03C6
        cmp     #$2F
        bne     L0344
        lda     L03C7
        cmp     #2
        beq     L035B
L0344:  asl     L03C9
        bpl     L0351
        lda     #1
        sta     L03C9
        inc     L03CC
L0351:  inc     L03C6
        bne     L02FB
        inc     L03C7
        bne     L02FB
L035B:  sta     LOWSCR
        rts

L035F:  jsr     pr_num_1
        jsr     send_spacing_sequence
L0365:  jsr     L02E6
        lda     #CR
        jsr     cout
        lda     #LF
        jsr     cout
        lda     L03C8
        sta     L03C5
        cmp     #192            ; screen height in pixels
        bcc     L0365
        lda     #CR
        jsr     cout
        lda     #CR
        jsr     cout
        jsr     send_restore_state
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

L0393:  pha
        and     #$C7
        eor     #$08
        sta     $07
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        sta     $06
        pla
        and     #$38
        asl     a
        asl     a
        eor     $06
        asl     a
        rol     $07
        asl     a
        rol     $07
        eor     $06
        sta     $06
        rts

pr_num_1:
        lda     #>SLOT1
        sta     COUT_HOOK+1
        lda     #<SLOT1
        sta     COUT_HOOK
        lda     #(CR | $80)
        jsr     invoke_slot1
        rts

cout:   jsr     COUT
        rts

L03C5:  .byte   0
L03C6:  .byte   0
L03C7:  .byte   0
L03C8:  .byte   0
L03C9:  .byte   0
L03CA:  .byte   0
L03CB:  .byte   0
L03CC:  .byte   0
        .byte   $00,$00

spacing_sequence:
        .byte   ESC,'e'         ; 107 DPI (horizontal)
        .byte   ESC,"T16"       ; distance between lines (16/144")
        .byte   TAB,$4C,$20,$44,$8D ; ???
        .byte   TAB,$5A,$8D     ; ???
        .byte   0

restore_state:
        .byte   ESC,'N'         ; 80 DPI (horizontal)
        .byte   ESC,"T24"       ; distance between lines (24/144")
        .byte   0

invoke_slot1:
        jmp     SLOT1

        ;; Padding
        .res    $400 - *, 0
.endproc ; rest

        .assert .sizeof(install_as_quit) + .sizeof(quit_routine) + .sizeof(install_segments) + .sizeof(rest) = $580, error, "Size mismatch"
