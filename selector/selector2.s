;;; ============================================================
;;; Quit Handler
;;; ============================================================

        .org $1000

;;; This gets invoked via ProDOS QUIT, which relocated it to
;;; $1000 Main.

.scope
        self := *

        jmp     start


        PRODOS_QUIT_ROUTINE := $D100


flag:   .byte   0

        ;; Unreferenced?
        .byte   "Selector"
        .byte   0

str_loading:
        PASCAL_STRING "Loading Selector"

str_selector:
        PASCAL_STRING "Selector"

        ;; ProDOS MLI call param blocks

        io_buf := $1800
        load_target := $1C00
        kLoadSize = $600

        DEFINE_READ_PARAMS read_params, load_target, kLoadSize
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_GET_PREFIX_PARAMS get_prefix_params, prefix_buf
        DEFINE_OPEN_PARAMS open_params, str_selector, io_buf

start:
        ;; Show and clear 80-column text screen
        lda     ROMIN2
        jsr     SETVID
        jsr     SETKBD
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SLOT3ENTRY
        jsr     HOME
        lda     #$00
        sta     SHADOW          ; TODO: Only do this on IIgs
        lda     #$80
        sta     ALTZPON
        sta     $0100           ; ???
        sta     $0101           ; ???
        sta     ALTZPOFF

        ;; Disable IIgs video
        ;; TODO: Only do this on IIgs
        lda     NEWVIDEO
        ora     #$20
        sta     NEWVIDEO

        ;; Display the loading string
        lda     #12             ; vtab
        sta     CV
        jsr     VTAB
        lda     #80             ; htab - center the string
        sec
        sbc     str_loading
        lsr     a               ; /= 2
        sta     CH
        ldy     #0
:       lda     str_loading+1,y
        ora     #$80
        jsr     COUT
        iny
        cpy     str_loading
        bne     :-

        ;; Close all open files
        MLI_CALL CLOSE, close_params

        ;; Initialize system bitmap
        ldx     #BITMAP_SIZE-1
        lda     #$01            ; Protect ProDOS global page
        sta     BITMAP,x
        dex
        lda     #$00
:       sta     BITMAP,x
        dex
        bpl     :-
        lda     #%11001111      ; Protect ZP, Stack, Text Page 1
        sta     BITMAP

        lda     flag
        bne     proceed
        MLI_CALL GET_PREFIX, get_prefix_params
        beq     install
        jmp     error_handler

        ;; --------------------------------------------------

install:
        lda     #$FF
        sta     flag
        copy16  IRQ_VECTOR, irq_vector_stash

        ;; Copy self into the ProDOS QUIT routine
        ;; TODO: Why do this again?
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
:       lda     self,y
        sta     PRODOS_QUIT_ROUTINE,y
        lda     self+$100,y
        sta     PRODOS_QUIT_ROUTINE+$100,y
        dey
        bne     :-
        lda     ROMIN2

        jmp     L10F2

proceed:
        copy16  irq_vector_stash, IRQ_VECTOR

;;; ============================================================
;;; Load the Loader at $2000 and invoke it.
;;; The code is at offset $400 length $200 in the file; load it
;;; by loading $600 at $2000-$400=$1C00 as a shortcut (?!?).

L10F2:  MLI_CALL SET_PREFIX, get_prefix_params
        beq     :+
        jmp     disk_prompt

:       MLI_CALL OPEN, open_params
        beq     :+
        jmp     error_handler

:       lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        beq     :+
        jmp     error_handler

:       MLI_CALL CLOSE, close_params
        beq     :+
        jmp     error_handler

:       jmp     LOADER

;;; ============================================================

disk_prompt:
        ;; Clear screen and center text
        jsr     SLOT3ENTRY
        jsr     HOME
        lda     #12
        sta     CV
        jsr     VTAB
        lda     #80
        sec
        sbc     prompt
        lsr     a               ; /= 2
        sta     CH

        ;; Display prompt
        ldy     #0
:       lda     prompt+1,y
        ora     #$80
        jsr     COUT
        iny
        cpy     prompt
        bne     :-


loop:   sta     KBDSTRB
:       lda     KBD
        bpl     :-
        and     #CHAR_MASK
        cmp     #CHAR_RETURN
        bne     loop
        jmp     start

prompt:
        PASCAL_STRING "Insert the system disk and press <Return>."

irq_vector_stash:
        .word   0

;;; ============================================================
;;; Error Handler

.proc error_handler
        sta     $06
        jmp     MONZ
.endproc

prefix_buf:
        .res 64, 0

.endscope
