;;; ============================================================
;;; Quit Handler
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        RESOURCE_FILE "quit_handler.res"

        .org $1000

;;; This gets invoked via ProDOS QUIT, which relocated it to
;;; $1000 Main.

.scope
        MLIEntry := MLI

        self := *

        jmp     start


        PRODOS_QUIT_ROUTINE := $D100


flag:   .byte   0

str_loading:
        PASCAL_STRING res_string_status_loading

filename:
        PASCAL_STRING kFilenameSelector

        ;; ProDOS MLI call param blocks

        io_buf := $1800
        load_target := $1C00
        kLoadSize = $600

        DEFINE_READ_PARAMS read_params, load_target, kLoadSize
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_GET_PREFIX_PARAMS get_prefix_params, prefix_buf
        DEFINE_OPEN_PARAMS open_params, filename, io_buf

start:
        ;; Show and clear 80-column text screen
        bit     ROMIN2
        jsr     SETVID
        jsr     SETKBD
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SLOT3ENTRY
        jsr     HOME

        ;; IIgs: Reset shadowing
        sec
        jsr     IDROUTINE
        bcs     :+
        copy    #0, SHADOW
:

        ;; --------------------------------------------------

        ;; Display the loading string
        lda     #12             ; vtab
        sta     CV
        jsr     VTAB
        lda     #80             ; htab - center the string
        sec
        sbc     str_loading
        lsr     a               ; /= 2
        sta     OURCH
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
        jmp     ErrorHandler

        ;; --------------------------------------------------

install:
        lda     #$FF
        sta     flag
        copy16  IRQLOC, irq_vector_stash

        ;; Copy self into the ProDOS QUIT routine
        bit     LCBANK2
        bit     LCBANK2
        ldy     #0
:       lda     self,y
        sta     PRODOS_QUIT_ROUTINE,y
        lda     self+$100,y
        sta     PRODOS_QUIT_ROUTINE+$100,y
        dey
        bne     :-
        bit     ROMIN2

        jmp     L10F2

proceed:
        copy16  irq_vector_stash, IRQLOC

;;; ============================================================
;;; Load the Loader at $2000 and invoke it.
;;; The code is at offset $400 length $200 in the file; load it
;;; by loading $600 at $2000-$400=$1C00 as a shortcut (?!?).

L10F2:  MLI_CALL SET_PREFIX, get_prefix_params
        beq     :+
        jmp     disk_prompt

:       MLI_CALL OPEN, open_params
        beq     :+
        jmp     ErrorHandler

:       lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        beq     :+
        jmp     ErrorHandler

:       MLI_CALL CLOSE, close_params
        beq     :+
        jmp     ErrorHandler

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
        sta     OURCH

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
        PASCAL_STRING res_string_prompt_insert_system_disk

irq_vector_stash:
        .word   0

;;; ============================================================
;;; Error Handler

.proc ErrorHandler
        sta     $06
        jmp     MONZ
.endproc

prefix_buf:
        .res 64, 0

;;; ============================================================

.endscope

        PAD_TO $1200
