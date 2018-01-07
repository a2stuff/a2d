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

        ;; ???
L11D0:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00
.endproc ; quit_routine

;;; ==================================================
;;; This chunk is invoked at $2000 after the quit handler has been invoked
;;; and updated itself. Using the segment_*_tables below, this loads the
;;; DeskTop application into various parts of main, aux, and bank-switched
;;; memory, then invokes the DeskTop initialization routine.

.proc install_segments
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
        and     #$FF
        beq     :+
        brk                     ; crash
:       lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     read_params::ref_num
        php
        sei
        MLI_CALL SET_MARK, set_mark_params
        plp
        and     #$FF
        beq     :+
        brk                     ; crash
:       lda     #0
        sta     segment_num

loop:   lda     segment_num
        cmp     num_segments
        bne     continue

        ;; Close and invoke... $800 ???
        php
        sei
        MLI_CALL CLOSE, close_params
        plp
        and     #$FF
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

L02B4           := $02B4
L02B6           := $02B6
L02C3           := $02C3
L02C5           := $02C5
L02E6           := $02E6
L035F           := $035F
L0393           := $0393
L03B3           := $03B3
L03C1           := $03C1
L03E5           := $03E5


        ;; Test for OpenApple+ClosedApple+P
        pha
        lda     BUTN0
        and     BUTN1
        bpl     L2210
        lda     KBD
        cmp     #('P' | $80)
        beq     L2214
L2210:  pla
        jmp     L7ECA

        ;; Invoked if OA+CA+P is held
L2214:  sta     KBDSTRB
        sta     SET80COL
        sta     SET80VID
        sta     DHIRESON
        lda     TXTCLR
        lda     HIRES
        sta     ALTZPOFF
        sta     ROMIN2
        lda     #$00
        sta     $03C5
        jmp     L035F


        ldy     #$00
        lda     $03CF,y
        beq     L2242
        jsr     L03C1
        iny
        jmp     L02B6

L2242:  rts

        ldy     #$00
        lda     $03DE,y
        beq     L2251
        jsr     L03C1
        iny
        jmp     L02C5

L2251:  rts

        ldx     #$00
L2254:  lda     $02E0,x
        jsr     L03C1
        inx
        cpx     #$06
        bne     L2254
        rts

        .byte   $1B,$47,$30,$35,$36,$30 ; ???

        jsr     $02D2
        ldy     #$00
        sty     $03CC
        lda     #$01
        sta     $03C9
        lda     #$00
        sta     $03C6
        sta     $03C7
L227B:  lda     #$08
        sta     $03CB
        lda     $03C5
        sta     $03C8
L2286:  lda     $03C8
        jsr     L0393
        lda     $03CC
        lsr     a
        tay
        sta     LOWSCR
        bcs     L2299
        sta     HISCR
L2299:  lda     ($06),y
        and     $03C9
        cmp     #$01
        ror     $03CA
        inc     $03C8
        dec     $03CB
        bne     L2286
        lda     $03CA
        eor     #$FF
        sta     LOWSCR
        jsr     L03C1
        lda     $03C6
        cmp     #$2F
        bne     L22C4
        lda     $03C7
        cmp     #$02
        beq     L22DB
L22C4:  asl     $03C9
        bpl     L22D1
        lda     #$01
        sta     $03C9
        inc     $03CC
L22D1:  inc     $03C6
        bne     L227B
        inc     $03C7
        bne     L227B
L22DB:  sta     LOWSCR
        rts

        jsr     L03B3
        jsr     L02B4
L22E5:  jsr     L02E6
        lda     #$0D
        jsr     L03C1
        lda     #$0A
        jsr     L03C1
        lda     $03C8
        sta     $03C5
        cmp     #$C0
        bcc     L22E5
        lda     #$0D
        jsr     L03C1
        lda     #$0D
        jsr     L03C1
        jsr     L02C3
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

        pha
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

        lda     #>$C100
        sta     COUT_HOOK+1
        lda     #<$C100
        sta     COUT_HOOK

        lda     #$8D
        jsr     L03E5
        rts

        jsr     COUT
        rts

L2345:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$1B,$65,$1B,$54,$31,$36
        .byte   $09,$4C,$20,$44,$8D,$09,$5A,$8D
        .byte   $00,$1B,$4E,$1B,$54,$32,$34,$00
        .byte   $4C,$00,$C1,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00
.endproc ; rest
