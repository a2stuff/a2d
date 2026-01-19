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

        DEFINE_READWRITE_PARAMS read_params, 0, 0

        DEFINE_CLOSE_PARAMS close_params
        DEFINE_SET_MARK_PARAMS set_mark_params, 0

filename:
        PASCAL_STRING kPathnameDeskTop

;;; Consecutive segments are loaded, `size` bytes are loaded at `addr`
;;; then relocated to `dest` according to `type`.

;;; Segments are:
;;; $4000 aux        - MGTK and DeskTop code
;;; $D000 aux/banked - DeskTop code callable from main, and resources
;;; $4000 main       - more DeskTop code
;;; $0800 main       - DeskTop initialization code; later overwritten by DAs, etc
;;; $0290 main       - Routine to invoke other programs

kNumSegments = 5

segment_addr_table_low:         ; Temporary load addresses
        .byte   <$3F00,<$4000 ; loaded here and then moved into Aux / LC banks
        .byte   <kSegmentDeskTopMainAddress,<kSegmentInitializerAddress,<kSegmentInvokerAddress ; "moved" in place
        ASSERT_TABLE_SIZE segment_addr_table_low, kNumSegments

segment_addr_table_high:        ; Temporary load addresses
        .byte   >$3F00,>$4000 ; loaded here and then moved into Aux / LC banks
        .byte   >kSegmentDeskTopMainAddress,>kSegmentInitializerAddress,>kSegmentInvokerAddress ; "moved" in place
        ASSERT_TABLE_SIZE segment_addr_table_high, kNumSegments

segment_dest_table_low:         ; Runtime addresses (moved here)
        .byte   <kSegmentDeskTopAuxAddress,<kSegmentDeskTopLCAddress
        .byte   0,0,0           ; loaded directly into final address, no need to move
        ASSERT_TABLE_SIZE segment_dest_table_low, kNumSegments

segment_dest_table_high:        ; Runtime addresses (moved here)
        .byte   >kSegmentDeskTopAuxAddress,>kSegmentDeskTopLCAddress
        .byte   0,0,0           ; loaded directly into final address, no need to move
        ASSERT_TABLE_SIZE segment_dest_table_high, kNumSegments

segment_size_table_low:
        .byte   <kSegmentDeskTopAuxLength,<kSegmentDeskTopLCLength
        .byte   <kSegmentDeskTopMainLength,<kSegmentInitializerLength,<kSegmentInvokerLength
        ASSERT_TABLE_SIZE segment_size_table_low, kNumSegments

segment_size_table_high:
        .byte   >kSegmentDeskTopAuxLength,>kSegmentDeskTopLCLength
        .byte   >kSegmentDeskTopMainLength,>kSegmentInitializerLength,>kSegmentInvokerLength
        ASSERT_TABLE_SIZE segment_size_table_high, kNumSegments

segment_offset_table_low:
        .byte   <kSegmentDeskTopAuxOffset,<kSegmentDeskTopLCOffset
        .byte   <kSegmentDeskTopMainOffset,<kSegmentInitializerOffset,<kSegmentInvokerOffset
        ASSERT_TABLE_SIZE segment_offset_table_low, kNumSegments

segment_offset_table_high:
        .byte   >kSegmentDeskTopAuxOffset,>kSegmentDeskTopLCOffset
        .byte   >kSegmentDeskTopMainOffset,>kSegmentInitializerOffset,>kSegmentInvokerOffset
        ASSERT_TABLE_SIZE segment_offset_table_high, kNumSegments

segment_offset_table_bank:
        .byte   ^kSegmentDeskTopAuxOffset,^kSegmentDeskTopLCOffset
        .byte   ^kSegmentDeskTopMainOffset,^kSegmentInitializerOffset,^kSegmentInvokerOffset
        ASSERT_TABLE_SIZE segment_offset_table_bank, kNumSegments

segment_type_table:             ; 0 = main, 1 = aux, 2 = banked (aux)
        .byte   1,2,0,0,0
        ASSERT_TABLE_SIZE segment_type_table, kNumSegments

start:
        ;; Old ProDOS leaves interrupts inhibited on start.
        ;; Do this for good measure.
        cli

        jsr     DetectMousetext
        jsr     InitProgress

        ;; Open this system file
        MLI_CALL OPEN, open_params
    IF CS
        brk                     ; crash
    END_IF
        lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     read_params::ref_num

        copy8   #0, segment_num

    REPEAT
        jsr     UpdateProgress
segment_num := * + 1
        ldx     #0
        cpx     #kNumSegments
        bne     continue

        ;; Close
        MLI_CALL CLOSE, close_params
      IF CS
        brk                     ; crash
      END_IF
        jmp     kSegmentInitializerAddress

continue:
        copy8   segment_offset_table_low,x,  set_mark_params::position+0
        copy8   segment_offset_table_high,x, set_mark_params::position+1
        copy8   segment_offset_table_bank,x, set_mark_params::position+2
        MLI_CALL SET_MARK, set_mark_params
      IF CS
        brk                     ; crash
      END_IF

        copylohi segment_addr_table_low,x, segment_addr_table_high,x, read_params::data_buffer
        copylohi segment_size_table_low,x, segment_size_table_high,x, read_params::request_count
        MLI_CALL READ, read_params
      IF CS
        brk                     ; crash
      END_IF

        ldx     segment_num
        inc     segment_num
        lda     segment_type_table,x
        CONTINUE_IF ZERO        ; type 0 = main, so done
        cmp     #2              ; carry set if banked, clear if aux
      IF GE
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
      END_IF

        src := $6
        dst := $8

        ldy     #0
        sty     src
        ldy     segment_dest_table_low,x
        sty     dst
        ldy     segment_dest_table_high,x
        sty     dst+1
        ldy     read_params::data_buffer+1
        sty     src+1

        ldy     segment_size_table_high,x ; Y = number of pages
        lda     segment_size_table_low,x ; fractional?
      IF NOT_ZERO
        iny                     ; if so, round up
      END_IF

        tya
        tax                     ; X = number of pages to copy
        sta     RAMWRTON
        jsr     CopySegment
        sta     RAMWRTOFF
      IF CS                     ; carry set if banked
        COPY_BYTES kIntVectorsSize, vector_buf, VECTORS
        sta     ALTZPOFF
        bit     ROMIN2
        plp
      END_IF

    FOREVER

vector_buf:
        .res    ::kIntVectorsSize, 0

        ;; Handle banked/aux memory segment
        ;; Corresponding vectors are set before call
.proc CopySegment
        ldy     #0
    DO
        copy8   (src),y, (dst),y
        iny
        CONTINUE_IF NOT_ZERO
        inc     src+1
        inc     dst+1
        dex
    WHILE NOT_ZERO
        rts
.endproc ; CopySegment

;;; ============================================================

        kProgressStops = kNumSegments + 1
        .include "../lib/loader_progress.s"

;;; ============================================================


.endscope ; InstallSegments

;;; ============================================================

        ENDSEG SegmentLoader
