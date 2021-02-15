;;; ============================================================
;;; Loader
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        RESOURCE_FILE "loader.res"

;;; ============================================================
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

        DEFINE_QUIT_PARAMS quit_params
.endproc ; install_as_quit

;;; ============================================================
;;; New QUIT routine. Gets relocated to $1000 by ProDOS before
;;; being executed.

.proc quit_routine
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

        DEFINE_READ_PARAMS read_params, $1E00, $400 ; so the $200 byte mark ends up at $2000
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_SET_PREFIX_PARAMS prefix_params, prefix_buffer
        DEFINE_OPEN_PARAMS open_params, filename, $1A00

start:  lda     ROMIN2

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

        lda     #$40
        sta     RAMWRTON
        sta     $0100           ; ???
        sta     $0101           ; ???
        sta     RAMWRTOFF

        lda     #kSplashVtab
        jsr     VTABZ

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
:       sta     BITMAP,x
        dex
        bpl     :-
        lda     #%11001111       ; Protect ZP, stack, Text Page 1
        sta     BITMAP

        lda     reinstall_flag
        bne     no_reinstall

        ;; Re-install quit routine (with prefix memorized)
        MLI_CALL GET_PREFIX, prefix_params
        beq     :+
        jmp     crash
:       lda     #$FF
        sta     reinstall_flag

        copy16  IRQLOC, irq_saved
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
        copy16  irq_saved, IRQLOC

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
        jsr     VTABZ

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
        and     #CHAR_MASK
        cmp     #$0D            ; Return
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

.endproc ; quit_routine

;;; ============================================================
;;; This chunk is invoked at $2000 after the quit handler has been invoked
;;; and updated itself. Using the segment_*_tables below, this loads the
;;; DeskTop application into various parts of main, aux, and bank-switched
;;; memory, then invokes the DeskTop initialization routine.

.proc install_segments
        ;; Pad to be at $200 into the file
        .res    $200 - (.sizeof(install_as_quit) + .sizeof(quit_routine)), 0

        .org $2000

        jmp     start

        DEFINE_OPEN_PARAMS open_params, filename, $3000

        DEFINE_READ_PARAMS read_params, 0, 0

        DEFINE_CLOSE_PARAMS close_params
        DEFINE_SET_MARK_PARAMS set_mark_params, $580 ; This many bytes before the good stuff.

filename:
        PASCAL_STRING kFilenameDeskTop

;;; Consecutive segments are loaded, |size| bytes are loaded at |addr|
;;; then relocated to |dest| according to |type|.

;;; Segments are:
;;; $4000 aux        - MGTK and DeskTop code
;;; $D000 aux/banked - DeskTop code callable from main, and resources
;;; $FB00 aux/banked - more DeskTop resources (icons, strings, etc)
;;; $4000 main       - more DeskTop code
;;; $0800 main       - DeskTop initialization code; later overwritten by DAs, etc
;;; $0290 main       - Routine to invoke other programs

kNumSegments = 6

segment_addr_table:             ; Temporary load addresses
        .word   $3F00,$4000,$4000 ; loaded here and then moved into Aux / LC banks
        .word   kSegmentDeskTopMainAddress,kSegmentInitializerAddress,kSegmentInvokerAddress ; "moved" in place
        ASSERT_ADDRESS_TABLE_SIZE segment_addr_table, kNumSegments

segment_dest_table:             ; Runtime addresses (moved here)
        .addr   kSegmentDeskTopAuxAddress,kSegmentDeskTopLC1AAddress,kSegmentDeskTopLC1BAddress
        .addr   kSegmentDeskTopMainAddress,kSegmentInitializerAddress,kSegmentInvokerAddress
        ASSERT_ADDRESS_TABLE_SIZE segment_dest_table, kNumSegments

segment_size_table:
        .word   kSegmentDeskTopAuxLength,kSegmentDeskTopLC1ALength,kSegmentDeskTopLC1BLength
        .word   kSegmentDeskTopMainLength,kSegmentInitializerLength,kSegmentInvokerLength
        ASSERT_ADDRESS_TABLE_SIZE segment_size_table, kNumSegments

segment_type_table:             ; 0 = main, 1 = aux, 2 = banked (aux)
        .byte   1,2,2,0,0,0
        ASSERT_TABLE_SIZE segment_type_table, kNumSegments

num_segments:
        .byte   kNumSegments

start:
        ;; Configure system bitmap - everything is available
        ldx     #BITMAP_SIZE-1
        lda     #0
:       sta     BITMAP+1,x
        dex
        bpl     :-

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
:       lda     #0
        sta     segment_num

loop:   jsr     update_progress
        lda     segment_num
        cmp     num_segments
        bne     continue

        ;; Close
        MLI_CALL CLOSE, close_params
        beq     :+
        brk                     ; crash
:       jmp     load_settings

continue:
        asl     a
        tax
        copy16  segment_addr_table,x, read_params::data_buffer
        copy16  segment_size_table,x, read_params::request_count
        MLI_CALL READ, read_params
        beq     :+
        brk                     ; crash
:       ldx     segment_num
        lda     segment_type_table,x
        beq     next_segment    ; type 0 = main, so done
        cmp     #2
        beq     :+
        jsr     aux_segment
        jmp     next_segment
:       jsr     banked_segment

next_segment:
        inc     segment_num
        jmp     loop

segment_num:  .byte   0

        ;; Handle bank-switched memory segment
.proc banked_segment
        src := $6
        dst := $8

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        lda     #$80            ; ???
        sta     $0100
        sta     $0101

        lda     #0
        sta     src
        sta     dst
        lda     segment_num
        asl     a
        tax
        lda     segment_dest_table+1,x
        sta     dst+1
        lda     read_params::data_buffer+1
        sta     src+1
        clc
        adc     segment_size_table+1,x
        sta     max_page
        lda     segment_size_table,x
        beq     :+
        inc     max_page

:       ldy     #0
loop:   lda     (src),y
        sta     (dst),y
        iny
        bne     loop
        inc     src+1
        inc     dst+1
        lda     src+1
        cmp     max_page
        bne     loop

        sta     ALTZPOFF
        lda     ROMIN2
        rts

max_page:
        .byte   0
.endproc

        ;; Handle aux memory segment
.proc aux_segment
        src := $6
        dst := $8

        lda     #0
        sta     src
        sta     dst
        lda     segment_num
        asl     a
        tax
        lda     segment_dest_table+1,x
        sta     dst+1
        lda     read_params::data_buffer+1
        sta     src+1
        clc
        adc     segment_size_table+1,x
        sta     max_page
        sta     RAMRDOFF
        sta     RAMWRTON
        ldy     #0
loop:   lda     (src),y
        sta     (dst),y
        iny
        bne     loop
        inc     src+1
        inc     dst+1
        lda     src+1
        cmp     max_page
        bne     loop
        sta     RAMWRTOFF
        rts

max_page:
        .byte   0
.endproc

;;; ============================================================
;;; Load settings file (if present), and copy into LC,
;;; overwriting default settings.

.proc load_settings

        jmp     start

        io_buf := $1A00
        read_buf := $1E00

        DEFINE_OPEN_PARAMS open_params, filename, io_buf
        DEFINE_READ_PARAMS read_params, read_buf, .sizeof(DeskTopSettings)
        DEFINE_CLOSE_PARAMS close_params

filename:
        PASCAL_STRING kFilenameDeskTopConfig

start:
        ;; Load the settings file; on failure, just skip
        MLI_CALL OPEN, open_params
        bcs     finish
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        bcs     close

        ;; Check version bytes; ignore on mismatch
        lda     read_buf + DeskTopSettings::version_major
        cmp     #kDeskTopVersionMajor
        bne     close
        lda     read_buf + DeskTopSettings::version_minor
        cmp     #kDeskTopVersionMinor
        bne     close

        ;; Move settings block into place
        sta     ALTZPON         ; Bank in Aux LC Bank 1
        lda     LCBANK1
        lda     LCBANK1

        COPY_STRUCT DeskTopSettings, read_buf, SETTINGS

        sta     ALTZPOFF        ; Bank in Main ZP/LC and ROM
        lda     ROMIN2

        ;; Finish up
close:  MLI_CALL CLOSE, close_params

finish: jmp     kSegmentInitializerAddress

.endproc

.proc update_progress

        kProgressVtab = 14
        kProgressStops = kNumSegments + 1
        kProgressTick = 40 / kProgressStops
        kProgressHtab = (80 - (kProgressTick * kProgressStops)) / 2

        lda     #kProgressVtab
        jsr     VTABZ
        lda     #kProgressHtab
        sta     CH

        lda     count
        clc
        adc     #kProgressTick
        sta     count

        tax
        lda     #' '
:       jsr     COUT
        dex
        bne     :-

        rts

count:  .byte   0
.endproc

        PAD_TO $2380
.endproc ; install_segments

;;; ============================================================

        .assert .sizeof(install_as_quit) + .sizeof(quit_routine) + .sizeof(install_segments) = $580, error, "Size mismatch"
