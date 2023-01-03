;;; ============================================================
;;; Quit Handler
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; New QUIT routine. Gets relocated to $1000 by ProDOS before
;;; being executed.

.proc QuitRoutine
        .org $1000

        MLIEntry := MLI

self:
        jmp     start

reinstall_flag:                ; set once prefix saved and reinstalled
        .byte   0

kSplashVtab = 12
str_loading:
        PASCAL_STRING .sprintf(res_string_splash_string, kDeskTopProductName)

filename:
        PASCAL_STRING kFilenameDeskTop

        ;; ProDOS MLI call param blocks

        ;; Arrange these so loader is placed at target address
        load_target := kSegmentLoaderAddress - kSegmentLoaderOffset
        kLoadSize = kSegmentLoaderOffset + kSegmentLoaderLength
        io_buf := $1A00
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

        ;; Set stack pointers to arbitrarily low values for use when
        ;; interrupts occur. DeskTop does not utilize this convention,
        ;; so the values are set low so that interrupts which do (for
        ;; example, the IIgs Control Panel) don't trash DeskTop's
        ;; stacks.
        ;; See the Apple IIe Technical Reference Manual, pp. 153-154
        lda     #$40
        sta     ALTZPON
        sta     $0100           ; Main stack pointer, in Aux ZP
        sta     $0101           ; Aux stack pointer, in Aux ZP
        sta     ALTZPOFF

        ;; --------------------------------------------------

        ;; Display the loading string
        lda     #kSplashVtab
        jsr     VTABZ

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
        lda     #0
:       sta     BITMAP,x
        dex
        bpl     :-
        lda     #%00000001      ; ProDOS global page
        sta     BITMAP+BITMAP_SIZE-1
        lda     #%11001111      ; ZP, Stack, Text Page 1
        sta     BITMAP

        lda     reinstall_flag
        bne     proceed

        ;; Re-install quit routine (with prefix memorized)
        MLI_CALL GET_PREFIX, prefix_params
        beq     :+
        jmp     ErrorHandler
:
        ;; --------------------------------------------------

        dec     reinstall_flag

        tay
        copy16  IRQLOC, irq_vector_stash

        ;; --------------------------------------------------
        ;; Copy self into the ProDOS QUIT routine
        bit     LCBANK2
        bit     LCBANK2

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
        bne     prompt_for_system_disk
        MLI_CALL OPEN, open_params
        bne     ErrorHandler
        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        bne     ErrorHandler
        MLI_CALL CLOSE, close_params
        bne     ErrorHandler

        jmp     kSegmentLoaderAddress

;;; ============================================================
;;; Display a string, and wait for Return keypress

prompt_for_system_disk:
        jsr     SLOT3ENTRY      ; 80 column mode
        jsr     HOME            ; clear screen
        lda     #kSplashVtab    ; VTAB 12
        jsr     VTABZ

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
        cmp     #CHAR_RETURN | $80
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

;;; Updated by DeskTop if parts of the path are renamed.
prefix_buffer_offset := prefix_buffer - self

.endproc ; QuitRoutine
sizeof_QuitRoutine = .sizeof(QuitRoutine)
