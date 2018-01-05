
        .setcpu "6502"

        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"

;;; Used to invoke programs from selector menu

PREFIX  := $0220

;;; ==================================================

        .org $290
start:
        jmp     begin

;;; ==================================================

.proc set_prefix_params
params: .byte   1
path:   .addr   PREFIX
.endproc

L0296:  .byte   0

.proc open_params
params: .byte   3
path:   .addr   $280
buffer: .addr   $800
ref_num:.byte   1
.endproc

.proc read_params
params: .byte   4
ref_num:.byte   0
buffer: .addr   $2000
request:.word   $9F00
trans:  .word   0
.endproc

.proc close_params
params: .byte   1
ref_nun:.byte   0
.endproc

.proc get_info_params
params: .byte   $A
path:   .addr   $0280
access: .byte   0
type:   .byte   0
auxtype:.word   0
storage:.byte   0
blocks: .word   0
mod_date:       .word 0
mod_time:       .word 0
create_date:    .word 0
create_time:    .word 0
.endproc

        .res    3

bs_path:
        PASCAL_STRING "BASIC.SYSTEM"

.proc quit_params
params: .byte   4
        .byte   $EE             ; nonstandard ???
        .word   $0280           ; nonstandard ???
        .byte   0
        .word   0
.endproc

;;; ==================================================

bail:  MLI_CALL SET_PREFIX, set_prefix_params
        beq     L02DD
        pla
        pla
        jmp     L03CB

L02DD:  rts

L02DE:  MLI_CALL OPEN, open_params
        rts

begin:  lda     ROMIN2
        lda     #<$0000
        sta     jmp_addr
        lda     #>$2000
        sta     jmp_addr+1
        ldx     #$16
        lda     #$00
:       sta     $BF58,x
        dex
        bne     :-
        jsr     bail
        lda     PREFIX
        sta     L0296
        MLI_CALL GET_FILE_INFO, get_info_params
        beq     L0310
        jmp     L03CB

L0310:  lda     get_info_params::type
        cmp     #FT_S16
        bne     L031D
        jsr     L03C0
        jmp     L03BA

L031D:  cmp     #FT_BINARY
        bne     L0345
        lda     get_info_params::auxtype
        sta     jmp_addr
        sta     read_params::buffer
        lda     get_info_params::auxtype+1
        sta     jmp_addr+1
        sta     read_params::buffer+1
        cmp     #$0C
        bcs     L033E
        lda     #$BB
        sta     open_params::buffer+1
        bne     L037D
L033E:  lda     #$08
        sta     open_params::buffer+1
        bne     L037D

L0345:  cmp     #FT_BASIC
        bne     L037D
        lda     #<bs_path
        sta     open_params::path
        lda     #>bs_path
        sta     open_params::path+1
L0353:  jsr     L02DE
        beq     L0374
        ldy     PREFIX
L035B:  lda     PREFIX,y
        cmp     #$2F
        beq     L036A
        dey
        cpy     #1
        bne     L035B
        jmp     L03CB

L036A:  dey
        sty     PREFIX
        jsr     bail
        jmp     L0353

L0374:  lda     L0296
        sta     PREFIX
        jmp     L0382

L037D:  jsr     L02DE
        bne     L03CB
L0382:  lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        bne     L03CB
        MLI_CALL CLOSE, close_params
        bne     L03CB
        lda     get_info_params::type
        cmp     #FT_BASIC
        bne     L03AE
        jsr     bail
        ldy     $0280
:       lda     $0280,y
        sta     $2006,y
        dey
        bpl     :-
L03AE:  lda     #$03
        pha
        lda     #$B9
        pha
        jsr     L03C0

        jmp_addr := *+1
        jmp     $2000

L03BA:  MLI_CALL QUIT, quit_params

        ;; Initialize system bitmap
L03C0:  lda     #$01            ; ProDOS global page
        sta     BITMAP+BITMAP_SIZE-1
        lda     #%11001111      ; ZP, Stack, Text Page 1
        sta     BITMAP
        rts

L03CB:  rts

        ;; Pad to $160 bytes
        .res    $160 - (* - start), 0
