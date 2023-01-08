;;; ============================================================
;;; Loader
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; This chunk is invoked at $2000 after the quit handler has been invoked
;;; and updated itself. Using the segment_*_tables below, this loads the
;;; DeskTop application into various parts of main, aux, and bank-switched
;;; memory, then invokes the DeskTop initialization routine.


        BEGINSEG SegmentLoader

.scope InstallSegments
        MLIEntry := MLI

        jmp     start

        DEFINE_OPEN_PARAMS open_params, filename, $3000

        DEFINE_READ_PARAMS read_params, 0, 0

        DEFINE_CLOSE_PARAMS close_params
        DEFINE_SET_MARK_PARAMS set_mark_params, 0

filename:
        PASCAL_STRING kPathnameDeskTop

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

segment_offset_table_low:
        .byte   <kSegmentDeskTopAuxOffset,<kSegmentDeskTopLC1AOffset,<kSegmentDeskTopLC1BOffset
        .byte   <kSegmentDeskTopMainOffset,<kSegmentInitializerOffset,<kSegmentInvokerOffset
        ASSERT_TABLE_SIZE segment_offset_table_low, kNumSegments

segment_offset_table_high:
        .byte   >kSegmentDeskTopAuxOffset,>kSegmentDeskTopLC1AOffset,>kSegmentDeskTopLC1BOffset
        .byte   >kSegmentDeskTopMainOffset,>kSegmentInitializerOffset,>kSegmentInvokerOffset
        ASSERT_TABLE_SIZE segment_offset_table_high, kNumSegments

segment_offset_table_bank:
        .byte   ^kSegmentDeskTopAuxOffset,^kSegmentDeskTopLC1AOffset,^kSegmentDeskTopLC1BOffset
        .byte   ^kSegmentDeskTopMainOffset,^kSegmentInitializerOffset,^kSegmentInvokerOffset
        ASSERT_TABLE_SIZE segment_offset_table_bank, kNumSegments

segment_type_table:             ; 0 = main, 1 = aux, 2 = banked (aux)
        .byte   1,2,2,0,0,0
        ASSERT_TABLE_SIZE segment_type_table, kNumSegments

start:
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

        jsr     DetectMousetext
        jsr     InitProgress

        ;; Open this system file
        MLI_CALL OPEN, open_params
        beq     :+
        brk                     ; crash
:       lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     read_params::ref_num

        copy    #0, segment_num

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
        copy    segment_offset_table_low,x,  set_mark_params::position+0
        copy    segment_offset_table_high,x, set_mark_params::position+1
        copy    segment_offset_table_bank,x, set_mark_params::position+2
        MLI_CALL SET_MARK, set_mark_params
        beq     :+
        brk                     ; crash
:
        copylohi segment_addr_table_low,x, segment_addr_table_high,x, read_params::data_buffer
        copylohi segment_size_table_low,x, segment_size_table_high,x, read_params::request_count
        MLI_CALL READ, read_params
        beq     :+
        brk                     ; crash
:
        ldx     segment_num
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

        SETTINGS_IO_BUF := $1A00
        SETTINGS_LOAD_BUF := $1E00
        .include "../lib/load_settings.s"

;;; ============================================================


.endscope ; InstallSegments

;;; ============================================================

        ENDSEG SegmentLoader
