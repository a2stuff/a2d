;;; ============================================================
;;; Quit Handler
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        RESOURCE_FILE "loader.res"

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
splash_string:
        PASCAL_STRING .sprintf(res_string_splash_string, kDeskTopProductName)

filename:
        PASCAL_STRING kFilenameDeskTop

        ;; ProDOS MLI call param blocks

        ;; Arrange these so loader is placed at target address
        load_target = LOADER_ADDRESS - kLoaderOffset
        kLoadSize = kSegmentLoaderLength ; preamble + loader
        io_buf := $1A00
        .assert io_buf + $400 <= load_target, error, "memory overlap"

        DEFINE_READ_PARAMS read_params, load_target, kLoadSize
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_GET_PREFIX_PARAMS prefix_params, prefix_buffer
        DEFINE_OPEN_PARAMS open_params, filename, io_buf

start:
        ;; Show a splash message on 80 column text screen
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

        lda     #kSplashVtab
        jsr     VTABZ

        lda     #80             ; HTAB (80-width)/2
        sec                     ; to center
        sbc     splash_string
        lsr     a
        sta     OURCH

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
        lsr
:       sta     BITMAP,x
        dex
        bne     :-
        lda     #%11001111       ; Protect ZP, stack, Text Page 1
        sta     BITMAP

        lda     reinstall_flag
        bne     no_reinstall

        ;; Re-install quit routine (with prefix memorized)
        MLI_CALL GET_PREFIX, prefix_params
        beq     :+
        jmp     ErrorHandler
:       dec     reinstall_flag

        tay
        copy16  IRQLOC, irq_saved
        bit     LCBANK2
        bit     LCBANK2

:       lda     self,y
        sta     SELECTOR,y
        lda     self+$100,y
        sta     SELECTOR+$100,y
        dey
        bne     :-

        bit     ROMIN2
        jmp     done_reinstall

no_reinstall:
        copy16  irq_saved, IRQLOC

done_reinstall:
        ;; Set the prefix, read the first $400 bytes of this system
        ;; file in (at $1E00), and invoke $200 bytes into it (at $2000)

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
        jmp     $2000           ; Invoke system file


;;; ============================================================

        ;; Display a string, and wait for Return keypress
prompt_for_system_disk:
        jsr     SLOT3ENTRY      ; 80 column mode
        jsr     HOME
        lda     #12             ; VTAB 12
        jsr     VTABZ

        lda     #80             ; HTAB (80 - width)/2
        sec                     ; to center the string
        sbc     disk_prompt
        lsr     a
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

irq_saved:
        .addr   0

;;; ============================================================
;;; Error Handler

.proc ErrorHandler
        sta     $6              ; Crash?
        jmp     MONZ
.endproc

prefix_buffer:
        .res    64, 0

;;; Updated by DeskTop if parts of the path are renamed.
prefix_buffer_offset := prefix_buffer - self

.endproc ; QuitRoutine
sizeof_QuitRoutine = .sizeof(QuitRoutine)
