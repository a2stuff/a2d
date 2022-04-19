;;; ============================================================
;;; Loader
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        RESOURCE_FILE "loader.res"

        MLIEntry := MLI

;;; ============================================================
;;; Patch self in as ProDOS QUIT routine (LCBank2 $D100)
;;; and invoke QUIT. Note that only $200 bytes are copied.

.proc InstallAsQuit
        .org ::kSegmentLoaderAddress

        src     := QuitRoutine
        dst     := SELECTOR

        bit     LCBANK2
        bit     LCBANK2

        ldy     #$00
loop:   lda     src,y
        sta     dst,y
        lda     src+$100,y
        sta     dst+$100,y
        dey
        bne     loop
        bit     ROMIN2

        MLI_CALL QUIT, quit_params

        DEFINE_QUIT_PARAMS quit_params
.endproc ; InstallAsQuit

;;; ============================================================
;;; New QUIT routine. Gets relocated to $1000 by ProDOS before
;;; being executed.

.proc QuitRoutine
        .org    $1000
self:
        jmp     start

reinstall_flag:                 ; set once prefix saved and reinstalled
        .byte   0

kSplashVtab = 12
splash_string:
        PASCAL_STRING .sprintf(res_string_splash_string, kDeskTopProductName)

filename:
        PASCAL_STRING kFilenameDeskTop

        DEFINE_READ_PARAMS read_params, $1E00, kSegmentLoaderLength ; so the $200 byte mark ends up at $2000
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_SET_PREFIX_PARAMS prefix_params, prefix_buffer
        DEFINE_OPEN_PARAMS open_params, filename, $1A00

start:  bit     ROMIN2

        ;; Show a splash message on 80 column text screen
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
        jmp     crash
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
        bne     crash
        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        bne     crash
        MLI_CALL CLOSE, close_params
        bne     crash
        jmp     $2000           ; Invoke system file


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
        cmp     #CHAR_RETURN | $80
        bne     wait
        jmp     start

disk_prompt:
        PASCAL_STRING res_string_prompt_insert_system_disk

irq_saved:
        .addr   0

crash:  sta     $6              ; Crash?
        jmp     MONZ

prefix_buffer:
        .res    64, 0

;;; Updated by DeskTop if parts of the path are renamed.
prefix_buffer_offset := prefix_buffer - self

.endproc ; QuitRoutine

;;; ============================================================
;;; This chunk is invoked at $2000 after the quit handler has been invoked
;;; and updated itself. Using the segment_*_tables below, this loads the
;;; DeskTop application into various parts of main, aux, and bank-switched
;;; memory, then invokes the DeskTop initialization routine.

.proc InstallSegments
        ;; Pad to be at $200 into the file
        .res    $200 - (.sizeof(InstallAsQuit) + .sizeof(QuitRoutine)), 0

        .org $2000

        jmp     start

        DEFINE_OPEN_PARAMS open_params, filename, $3000

        DEFINE_READ_PARAMS read_params, 0, 0

        DEFINE_CLOSE_PARAMS close_params
        DEFINE_SET_MARK_PARAMS set_mark_params, $580 ; This many bytes before the good stuff.

filename:
        PASCAL_STRING kFilenameDeskTop

;;; Consecutive segments are loaded, `size` bytes are loaded at `addr`
;;; then relocated to `dest` according to `type`.

;;; Segments are:
;;; $4000 aux        - MGTK and DeskTop code
;;; $D000 aux/banked - DeskTop code callable from main, and resources
;;; $FB00 aux/banked - more DeskTop resources (icons, strings, etc)
;;; $4000 main       - more DeskTop code
;;; $0800 main       - DeskTop initialization code; later overwritten by DAs, etc
;;; $0290 main       - Routine to invoke other programs

kNumSegments = 6

segment_addr_table_low:         ; Temporary load addresses
        .byte   <$3F00,<$4000,<$4000 ; loaded here and then moved into Aux / LC banks
        .byte   <kSegmentDeskTopMainAddress,<kSegmentInitializerAddress,<kSegmentInvokerAddress ; "moved" in place
        ASSERT_TABLE_SIZE segment_addr_table_low, kNumSegments

segment_addr_table_high:        ; Temporary load addresses
        .byte   >$3F00,>$4000,>$4000 ; loaded here and then moved into Aux / LC banks
        .byte   >kSegmentDeskTopMainAddress,>kSegmentInitializerAddress,>kSegmentInvokerAddress ; "moved" in place
        ASSERT_TABLE_SIZE segment_addr_table_high, kNumSegments

segment_dest_table_high:        ; Runtime addresses (moved here)
        .byte   >kSegmentDeskTopAuxAddress,>kSegmentDeskTopLC1AAddress,>kSegmentDeskTopLC1BAddress
        .byte   >kSegmentDeskTopMainAddress,>kSegmentInitializerAddress,>kSegmentInvokerAddress
        ASSERT_TABLE_SIZE segment_dest_table_high, kNumSegments

segment_size_table_low:
        .byte   <kSegmentDeskTopAuxLength,<kSegmentDeskTopLC1ALength,<kSegmentDeskTopLC1BLength
        .byte   <kSegmentDeskTopMainLength,<kSegmentInitializerLength,<kSegmentInvokerLength
        ASSERT_TABLE_SIZE segment_size_table_low, kNumSegments

segment_size_table_high:
        .byte   >kSegmentDeskTopAuxLength,>kSegmentDeskTopLC1ALength,>kSegmentDeskTopLC1BLength
        .byte   >kSegmentDeskTopMainLength,>kSegmentInitializerLength,>kSegmentInvokerLength
        ASSERT_TABLE_SIZE segment_size_table_high, kNumSegments

segment_type_table:             ; 0 = main, 1 = aux, 2 = banked (aux)
        .byte   1,2,2,0,0,0
        ASSERT_TABLE_SIZE segment_type_table, kNumSegments

start:
        ;; Configure system bitmap - everything is available
        ldx     #BITMAP_SIZE-1
        lda     #0
:       sta     BITMAP+1,x
        dex
        bpl     :-

        jsr     DetectMousetext
        jsr     InitProgress

        ;; Open this system file
        MLI_CALL OPEN, open_params
        beq     :+
        brk                     ; crash
:       lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     read_params::ref_num
        MLI_CALL SET_MARK, set_mark_params
        beq     :+
        brk                     ; crash
:       sta     segment_num

loop:   jsr     UpdateProgress
segment_num := * + 1
        ldx     #0
        cpx     #kNumSegments
        bne     continue

        ;; Close
        MLI_CALL CLOSE, close_params
        beq     :+
        brk                     ; crash
:       jsr     LoadSettings

        jmp     kSegmentInitializerAddress

continue:
        copylohi segment_addr_table_low,x, segment_addr_table_high,x, read_params::data_buffer
        copylohi segment_size_table_low,x, segment_size_table_high,x, read_params::request_count
        MLI_CALL READ, read_params
        beq     :+
        brk                     ; crash
:       ldx     segment_num
        inc     segment_num
        lda     segment_type_table,x
        beq     loop            ; type 0 = main, so done
        cmp     #2              ; carry set if banked, clear if aux
        bcc     :+

        ;; Handle bank-switched memory segment
        ;; Disable interrupts, since we may overwrite IRQ vector
        php
        sei

        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        COPY_BYTES kIntVectorsSize, VECTORS, vector_buf
        ldx     segment_num
        dex

        ;; Set stack pointers to arbitrarily low values for use when
        ;; interrupts occur. DeskTop does not utilize this convention,
        ;; so the values are set low so that interrupts which do (for
        ;; example, the IIgs Control Panel) don't trash DeskTop's use
        ;; of the stacks.
        lda     #$80
        sta     $0100           ; Main stack pointer, in Aux ZP
        sta     $0101           ; Aux stack pointer, in Aux ZP

        src := $6
        dst := $8
:       ldy     #0
        sty     src
        sty     dst
        ldy     segment_dest_table_high,x
        sty     dst+1
        ldy     read_params::data_buffer+1
        sty     src+1

        ldy     segment_size_table_high,x
        lda     segment_size_table_low,x
        beq     :+
        iny
:       tya
        tax
        ldy     #0
        sta     RAMWRTON
        jsr     CopySegment
        sta     RAMWRTOFF
        bcc     :+

        COPY_BYTES kIntVectorsSize, vector_buf, VECTORS

        sta     ALTZPOFF
        bit     ROMIN2

        plp
:       jmp     loop

vector_buf:
        .res    ::kIntVectorsSize, 0

        ;; Handle banked/aux memory segment
        ;; Corresponding vectors are set before call
.proc CopySegment
loop:   lda     (src),y
        sta     (dst),y
        iny
        bne     loop
        inc     src+1
        inc     dst+1
        dex
        bne     loop
        rts
.endproc

;;; ============================================================

        kProgressStops = kNumSegments + 1
        .include "../lib/loader_progress.s"

;;; ============================================================

        .include "../lib/load_settings.s"
        DEFINEPROC_LOAD_SETTINGS $1A00, $1E00

;;; ============================================================

        PAD_TO ::kSegmentLoaderAddress + ::kSegmentLoaderLength - $200
.endproc ; InstallSegments

;;; ============================================================

        .assert .sizeof(InstallAsQuit) + .sizeof(QuitRoutine) + .sizeof(InstallSegments) = $580, error, "Size mismatch"
