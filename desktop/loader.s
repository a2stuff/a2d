        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"

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
L0800           := $0800

IRQ_VECTOR      := $3FE

L7ECA           := $7ECA        ; ???
MONZ            := $FF69

SELECTOR        := $D100

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
buffer: .addr   $1E00
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
;;; This chunk is invoked at $2000 after the quit
;;; handler has been invoked and updated itself.

.proc rest

        .byte   $4C,$4C,$20,$03,$18,$20,$00
        .byte   $30,$00,$04,$00,$00,$00,$00,$00
        .byte   $00,$00,$01,$00,$02,$00,$80,$05
        .byte   $00

        PASCAL_STRING "DeskTop2"

        .byte   $00,$3F,$00,$40,$00,$40

        .byte   $00,$40,$00,$08,$90,$02,$00,$40
        .byte   $00,$D0,$00,$FB,$00,$40,$00,$08
        .byte   $90,$02,$00,$80,$00,$1D,$00,$05
        .byte   $00,$7F,$00,$08,$60,$01,$01,$02
        .byte   $02,$00,$00,$00,$06,$A2,$17,$A9
        .byte   $00

L1229:  sta     $BF59,x
        dex
        bpl     L1229
        php
        sei
        MLI_CALL OPEN, $2003
        plp
        and     #$FF
        beq     L123D
        brk
L123D:  lda     $2008
        sta     $2014
        sta     $200A
        php
        sei
        MLI_CALL SET_MARK, $2013
        plp
        and     #$FF
        beq     L1254
        brk
L1254:  lda     #$00
        sta     $20DC
        lda     $20DC
        cmp     $204B
        bne     L1272
        php
        sei
        MLI_CALL CLOSE, $2011
        plp
        and     #$FF
        beq     L126F
        brk
L126F:  jmp     L0800

L1272:  asl     a
        tax
        lda     $2021,x
        sta     $200B
        lda     $2022,x
        sta     $200C
        lda     $2039,x
        sta     $200D
        lda     $203A,x
        sta     $200E
        php
        sei
        MLI_CALL READ, $2009
        plp
        and     #$FF
        beq     L129A
        brk
L129A:  ldx     $20DC
        lda     $2045,x
        beq     L12AF
        cmp     #$02
        beq     L12AC
        jsr     $212E
        jmp     $20D6

L12AC:  jsr     $20DD
L12AF:  inc     $20DC
        jmp     $2080

        brk
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        lda     #$80
        sta     $0100
        sta     $0101
        lda     #$00
        sta     $06
        sta     $08
        lda     $20DC
        asl     a
        tax
        lda     $202E,x
        sta     $09
        lda     $200C
        sta     $07
        clc
        adc     $203A,x
        sta     $212D
        lda     $2039,x
        beq     L12EB
        inc     $212D
L12EB:  ldy     #$00
L12ED:  lda     ($06),y
        sta     ($08),y
        iny
        bne     L12ED
        inc     $07
        inc     $09
        lda     $07
        cmp     $212D
        bne     L12ED
        sta     ALTZPOFF
        lda     ROMIN2
        rts

        brk
        lda     #$00
        sta     $06
        sta     $08
        lda     $20DC
        asl     a
        tax
        lda     $202E,x
        sta     $09
        lda     $200C
        sta     $07
        clc
        adc     $203A,x
        sta     $2168
        sta     RAMRDOFF
        sta     RAMWRTON
        ldy     #$00
L132B:  lda     ($06),y
        sta     ($08),y
        iny
        bne     L132B
        inc     $07
        inc     $09
        lda     $07
        cmp     $2168
        bne     L132B
        sta     RAMWRTOFF
        rts

        .res    152,0

        ;; Test for OpenApple+ClosedApple+P
        pha
        lda     BUTN0
        and     BUTN1
        bpl     L13E9
        lda     KBD
        cmp     #('P' | $80)
        beq     L13ED
L13E9:  pla
        jmp     L7ECA

        ;; Invoked if OA+CA+P is held
L13ED:  sta     KBDSTRB
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
        beq     L141B
        jsr     L03C1
        iny
        jmp     L02B6

L141B:  rts

        ldy     #$00
        lda     $03DE,y
        beq     L142A
        jsr     L03C1
        iny
        jmp     L02C5

L142A:  rts

        ldx     #$00
L142D:  lda     $02E0,x
        jsr     L03C1
        inx
        cpx     #$06
        bne     L142D
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
L1454:  lda     #$08
        sta     $03CB
        lda     $03C5
        sta     $03C8
L145F:  lda     $03C8
        jsr     L0393
        lda     $03CC
        lsr     a
        tay
        sta     LOWSCR
        bcs     L1472
        sta     HISCR
L1472:  lda     ($06),y
        and     $03C9
        cmp     #$01
        ror     $03CA
        inc     $03C8
        dec     $03CB
        bne     L145F
        lda     $03CA
        eor     #$FF
        sta     LOWSCR
        jsr     L03C1
        lda     $03C6
        cmp     #$2F
        bne     L149D
        lda     $03C7
        cmp     #$02
        beq     L14B4
L149D:  asl     $03C9
        bpl     L14AA
        lda     #$01
        sta     $03C9
        inc     $03CC
L14AA:  inc     $03C6
        bne     L1454
        inc     $03C7
        bne     L1454
L14B4:  sta     LOWSCR
        rts

        jsr     L03B3
        jsr     L02B4
L14BE:  jsr     L02E6
        lda     #$0D
        jsr     L03C1
        lda     #$0A
        jsr     L03C1
        lda     $03C8
        sta     $03C5
        cmp     #$C0
        bcc     L14BE
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

L151E:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$1B,$65,$1B,$54,$31,$36
        .byte   $09,$4C,$20,$44,$8D,$09,$5A,$8D
        .byte   $00,$1B,$4E,$1B,$54,$32,$34,$00
        .byte   $4C,$00,$C1,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00
.endproc ; rest
