;;; ============================================================
;;; Quit Handler
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        RESOURCE_FILE "quit_handler.res"

;;; This gets invoked via ProDOS QUIT, which relocated it to
;;; $1000 Main.

.proc QuitRoutine
        .org $1000

        MLIEntry := MLI

self:
        jmp     start

reinstall_flag:                ; set once prefix saved and reinstalled
        .byte   0

kSplashVtab = 12
str_loading:
        PASCAL_STRING res_string_status_loading

filename:
        PASCAL_STRING kFilenameSelector

        ;; ProDOS MLI call param blocks

        load_target := kSegmentLoaderAddress - kSegmentLoaderOffset
        kLoadSize = kSegmentLoaderOffset + kSegmentLoaderLength
        io_buf := $1800
        .assert io_buf + $400 <= load_target, error, "memory overlap"

        DEFINE_READ_PARAMS read_params, load_target, kLoadSize
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_GET_PREFIX_PARAMS prefix_params, prefix_buffer
        DEFINE_OPEN_PARAMS open_params, filename, io_buf

start:
        ;; Show and clear 80-column text screen
        bit     ROMIN2
        jsr     SETVID
        jsr     SETKBD
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80STORE
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
        lda     #kSplashVtab
        sta     CV
        jsr     VTAB

        lda     #80             ; HTAB (80-width)/2
        sec                     ; to center
        sbc     str_loading     ; -= width
        lsr     a               ; /= 2
        sta     OURCH

        ldy     #0
:       lda     str_loading+1,y
        ora     #$80
        jsr     COUT
        iny
        cpy     str_loading
        bne     :-

        ;; Close all open files (just in case)
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

        lda     reinstall_flag
        bne     proceed

        ;; Re-install quit routine (with prefix memorized)
        MLI_CALL GET_PREFIX, prefix_params
        beq     :+
        jmp     ErrorHandler
:
        ;; --------------------------------------------------

        lda     #$FF
        sta     reinstall_flag
        copy16  IRQLOC, irq_vector_stash

        ;; --------------------------------------------------
        ;; Copy self into the ProDOS QUIT routine
        bit     LCBANK2
        bit     LCBANK2
        ldy     #0
:       lda     self,y
        sta     SELECTOR,y
        lda     self+$100,y
        sta     SELECTOR+$100,y
        dey
        bne     :-

        bit     ROMIN2
        jmp     load_loader

proceed:
        copy16  irq_vector_stash, IRQLOC

;;; ============================================================
;;; Load the Loader at $2000 and invoke it.

load_loader:
        MLI_CALL SET_PREFIX, prefix_params
        beq     :+
        jmp     prompt_for_system_disk

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
:
        jmp     kSegmentLoaderAddress

;;; ============================================================
;;; Display a string, and wait for Return keypress

prompt_for_system_disk:
        jsr     SLOT3ENTRY      ; 80 column mode
        jsr     HOME            ; clear screen
        lda     #kSplashVtab    ; VTAB 12
        sta     CV
        jsr     VTAB

        lda     #80             ; HTAB (80-width)/2
        sec                     ; to center the string
        sbc     disk_prompt     ; -= width
        lsr     a               ; /= 2
        sta     OURCH

        ;; Display prompt
        ldy     #0
:       lda     disk_prompt+1,y
        ora     #$80
        jsr     COUT
        iny
        cpy     disk_prompt
        bne     :-

wait:   sta     KBDSTRB
:       lda     KBD
        bpl     :-
        and     #CHAR_MASK
        cmp     #CHAR_RETURN
        bne     wait
        jmp     start

disk_prompt:
        PASCAL_STRING res_string_prompt_insert_system_disk

;;; ============================================================

irq_vector_stash:
        .word   0

;;; ============================================================
;;; Error Handler

.proc ErrorHandler
        sta     $06             ; Crash?
        jmp     MONZ
.endproc

prefix_buffer:
        .res    64, 0

.endproc ; QuitRoutine
sizeof_QuitRoutine = .sizeof(QuitRoutine)
