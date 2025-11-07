;;; ============================================================
;;; SHOW.IMAGE.FILE - Desk Accessory
;;;
;;; Preview accessory for graphics (image) files.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================
;;; Memory map
;;;
;;;              Main           Aux
;;;          :           : :           :
;;;          |           | |           |
;;;          | DHR       | | DHR       |
;;;  $2000   +-----------+ +-----------+
;;;          | IO Buffer | |           |
;;;  $1C00   +-----------+ |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          | MP Src    | | MP Dst    |
;;;  $1800   +-----------+ +-----------+
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          | DA        | | resources |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

        hires   := $2000        ; HR/DHR images are loaded directly into screen buffer
        kHiresSize = $2000

        ;; Minipix/Print Shop images are loaded/converted
        minipix_src_buf := $1800 ; Load address (main)
        kMinipixSrcSize = 576
        minipix_dst_buf := $1800 ; Convert address (aux)
        kMinipixDstSize = 26*52

        ;; LR/DLR-Lores images are loaded/converted
        lores_src_buf := $1800  ; Load address (main
        kLoresBufferSize = $400

        dir_path := $380

        .assert (minipix_src_buf + kMinipixSrcSize) <= DA_IO_BUFFER, error, "Not enough room for Minipix load buffer"
        .assert (minipix_dst_buf + kMinipixDstSize) <= $2000, error, "Not enough room for Minipix convert buffer"

        .assert (lores_src_buf + kLoresBufferSize) <= DA_IO_BUFFER, error, "Lores buffer size too small"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

event_params:   .tag MGTK::Event

        kMinipixWidth = 88 * 2
        kMinipixHeight = 52

grafport:       .tag    MGTK::GrafPort

notpencopy:     .byte   MGTK::notpencopy

.params paintbits_params
        DEFINE_POINT viewloc, (kScreenWidth - kMinipixWidth)/2, (kScreenHeight - kMinipixHeight)/2
mapbits:        .addr   minipix_dst_buf
mapwidth:       .byte   26
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kMinipixWidth-1, kMinipixHeight-1
        REF_MAPINFO_MEMBERS
.endparams

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        jmp     Init

;;; ============================================================
;;; ProDOS MLI param blocks

        INVOKE_PATH := $220

        DEFINE_OPEN_PARAMS open_image_params, INVOKE_PATH, DA_IO_BUFFER
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, INVOKE_PATH
        DEFINE_GET_EOF_PARAMS get_eof_params

        DEFINE_READWRITE_PARAMS read_image_params, hires, kHiresSize
        DEFINE_READWRITE_PARAMS read_minipix_params, minipix_src_buf, kMinipixSrcSize
        DEFINE_READWRITE_PARAMS read_lores_params, lores_src_buf, kLoresBufferSize

        DEFINE_CLOSE_PARAMS close_image_params

;;; ============================================================

event_params:   .tag MGTK::Event

;;; ============================================================

.proc CopyEventAuxToMain
        copy16  #aux::event_params, STARTLO
        copy16  #aux::event_params + .sizeof(MGTK::Event) - 1, ENDLO
        copy16  #event_params, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=0    ; aux > main
.endproc ; CopyEventAuxToMain

;;; ============================================================

.proc Init
        CLEAR_BIT7_FLAG color_mode_flag

        ;; In case we're re-entered c/o switching to another file
        jsr     MaybeCallExitHook

        JUMP_TABLE_MLI_CALL OPEN, open_image_params
        lda     open_image_params::ref_num
        sta     get_eof_params::ref_num
        sta     read_image_params::ref_num
        sta     read_minipix_params::ref_num
        sta     read_lores_params::ref_num
        sta     close_image_params::ref_num

        JUMP_TABLE_MGTK_CALL MGTK::HideCursor
        jsr     ClearScreen
        jsr     SetColorMode
        jsr     ShowFile        ; C=1 on failure
        php
        JUMP_TABLE_MGTK_CALL MGTK::ShowCursor
        JUMP_TABLE_MLI_CALL CLOSE, close_image_params
        plp
        jcs     Exit

        JUMP_TABLE_MGTK_CALL MGTK::FlushEvents
        JUMP_TABLE_MGTK_CALL MGTK::ObscureCursor

        FALL_THROUGH_TO InputLoop
.endproc ; Init

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
        JUMP_TABLE_MGTK_CALL MGTK::GetEvent, aux::event_params
        jsr     CopyEventAuxToMain

        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        jeq     Exit
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     on_key

        bit     slideshow_flag
        bpl     InputLoop

        ;; --------------------------------------------------
        ;; Slideshow mode

        dec16   slideshow_counter
        lda     slideshow_counter
        ora     slideshow_counter+1
        bne     InputLoop
        jsr     InitSlideshowCounter
        jmp     NextFile

        ;; --------------------------------------------------
        ;; Key Event
on_key:
        ;; Stop slideshow on any keypress
        ldy     slideshow_flag  ; Y = previous `slideshow_flag` state
        CLEAR_BIT7_FLAG slideshow_flag

        lda     event_params + MGTK::Event::key
        jsr     ToUpperCase

        ldx     event_params + MGTK::Event::modifiers
    IF NOT_ZERO
        cmp     #kShortcutCloseWindow
        beq     Exit
        cmp     #CHAR_LEFT
        jeq     FirstFile
        cmp     #CHAR_RIGHT
        jeq     LastFile
        bne     InputLoop       ; always
    END_IF

        cmp     #CHAR_ESCAPE
        beq     Exit
        cmp     #CHAR_RETURN
        beq     Exit
        cmp     #CHAR_LEFT
        jeq     PreviousFile
        cmp     #CHAR_RIGHT
        jeq     NextFile

    IF A = #'S'
        tya               ; Y = previous `slideshow_flag` state
        bmi     InputLoop        ; Ignore (so toggle) if slideshow mode was on
        bpl     SetSlideshowMode ; always
    END_IF

    IF A = #' '
        jsr     ToggleMode
    END_IF

        jmp     InputLoop
.endproc ; InputLoop

;;; ============================================================

.proc SetSlideshowMode
        SET_BIT7_FLAG slideshow_flag
        jsr     InitSlideshowCounter
        jmp     InputLoop
.endproc ; SetSlideshowMode

.proc InitSlideshowCounter
        CALL    JUMP_TABLE_READ_SETTING, X=#DeskTopSettings::dblclick_speed
        sta     slideshow_counter
        inx                     ; `ReadSetting` preserves X
        jsr     JUMP_TABLE_READ_SETTING
        sta     slideshow_counter+1
        asl16   slideshow_counter
        rts
.endproc ; InitSlideshowCounter

slideshow_flag:
        .byte   0
slideshow_counter:
        .word   0

;;; ============================================================

restore_buffer_overlay_flag:
        .byte   0

.proc Exit
        jsr     MaybeCallExitHook

        bit     restore_buffer_overlay_flag
    IF NS
        CALL    JUMP_TABLE_RESTORE_OVL, A=#kDynamicRoutineRestoreBuffer
    END_IF

        jsr     JUMP_TABLE_RGB_MODE

        ;; Restore desktop and menu
        JUMP_TABLE_MGTK_CALL MGTK::RedrawDeskTop
        JUMP_TABLE_MGTK_CALL MGTK::DrawMenuBar
        jsr     JUMP_TABLE_HILITE_MENU

        rts
.endproc ; Exit

;;; ============================================================

.proc MaybeCallExitHook
        lda     hook
        ora     hook+1
    IF NOT_ZERO
        hook := *+1
        jsr     $0000           ; self-modified; 0 = no hook
        copy16  #0, hook
    END_IF
        rts
.endproc ; MaybeCallExitHook

exit_hook := MaybeCallExitHook::hook

;;; ============================================================

;;; Tail-called routines must exit with C=0 on success

.proc ShowFile
        ;; Check file type
        JUMP_TABLE_MLI_CALL GET_FILE_INFO, get_file_info_params
    IF CS
fail:   rts
    END_IF

        lda     get_file_info_params::file_type

        RTS_IF A = #FT_DIRECTORY ; C=1 signals failure

        cmp     #FT_PNT
        jeq     ShowPackedSHR

        cmp     #FT_PIC
        jeq     ShowUnpackedSHR

        cmp     #FT_GRAPHICS
        bne     get_eof

        ;; FOT files
        lda     get_file_info_params::aux_type
        ldx     get_file_info_params::aux_type+1

        ;; auxtype $8066 - LZ4FH packed image
    IF X = #$80
      IF A = #$66
        jmp     ShowLZ4FHFile
      END_IF
    END_IF

        ;; auxtype $4000 / $4001 are packed hires/double-hires
        cpx     #$40
        bne     ShowFOTFile

        cmp     #$00
        jeq     ShowPackedHRFile

        cmp     #$01
        bne     ShowFOTFile
        jmp     ShowPackedDHRFile

        ;; Otherwise, rely on size heuristics to determine the type
get_eof:
        JUMP_TABLE_MLI_CALL GET_EOF, get_eof_params

        ;; Maybe LR/DLR?
        ecmp16  get_file_info_params::aux_type, #$400
    IF EQ
        ecmp24  get_eof_params::eof, #$400
        jeq     ShowLRFile

        ecmp24  get_eof_params::eof, #$800
        jeq     ShowDLRFile
    END_IF

        ;; If bigger than $2000, assume DHR

        ucmp24  get_eof_params::eof, #(kHiresSize+1)
        jcs     ShowDHRFile

        ;; If bigger than 576, assume HR

        cmp16   get_eof_params::eof, #kMinipixSrcSize+1
        jcs     ShowHRFile

        ;; Otherwise, assume Minipix

        jmp     ShowMinipixFile
.endproc ; ShowFile

;;; ============================================================

;;; Output: C=0 on success, C=1 on failure
.proc ShowFOTFile
        ;; Per File Type $08 (8) Note:

        ;; ...you can determine the mode of the file by examining byte
        ;; +120 (+$78). The value of this byte, which ranges from zero
        ;; to seven, is interpreted as follows:
        ;;
        ;; Mode                         Page 1    Page 2
        ;; 280 x 192 Black & White        0         4
        ;; 280 x 192 Limited Color        1         5
        ;; 560 x 192 Black & White        2         6
        ;; 140 x 192 Full Color           3         7

SIGNATURE       := hires + 120
kSigColor       = %00000001
kSigDHR         = %00000010

        ;; At least one page...
        sta     PAGE2OFF
        JUMP_TABLE_MLI_CALL READ, read_image_params

        copy8   SIGNATURE, signature

        ;; HR or DHR?
        and     #kSigDHR
        bne     dhr

        ;; If HR, convert to DHR.
        jsr     HRToDHR
        jmp     finish

        ;; If DHR, copy Main>Aux and load Main page.
dhr:    jsr     CopyHiresToAux
        JUMP_TABLE_MLI_CALL READ, read_image_params

finish:
        lda     signature
        and     #kSigColor
    IF ZERO
        jsr     SetBWMode
    END_IF

        RETURN  C=0             ; success

signature:
        .byte   0
.endproc ; ShowFOTFile

;;; ============================================================

;;; Output: C=0 on success, C=1 on failure
.proc ShowLZ4FHFile
        sta     PAGE2OFF

        SET_BIT7_FLAG restore_buffer_overlay_flag
        copy16  #OVERLAY_BUFFER, read_image_params::data_buffer
        JUMP_TABLE_MLI_CALL READ, read_image_params
        copy16  #$2000, read_image_params::data_buffer

        ;; NOTE: `Init` also calls `CLOSE`, but it's harmless to call
        ;; it twice.
        JUMP_TABLE_MLI_CALL CLOSE, close_image_params

        copy16  #OVERLAY_BUFFER, z:::LZ4FH::in_src
        copy16  #$2000, z:::LZ4FH::in_dst
        jsr     LZ4FH
        bne     fail

        jsr     HRToDHR

        RETURN  C=0             ; success

fail:   RETURN  C=1             ; failure

.endproc ; ShowLZ4FHFile

;;; ============================================================

;;; Output: C=0 on success, C=1 on failure
.proc ShowHRFile
        ;; If suffix is ".A2HR" show in mono mode
        CALL    CheckSuffix, AX=#str_a2hr_suffix
    IF CC
        jsr     SetBWMode
    END_IF

        sta     PAGE2OFF
        JUMP_TABLE_MLI_CALL READ, read_image_params

        jsr     HRToDHR

        RETURN  C=0             ; success

.endproc ; ShowHRFile

;;; ============================================================

;;; Output: C=0 on success, C=1 on failure
.proc ShowDHRFile
        ptr := $06

        ;; If suffix is ".A2FM" show in mono mode
        CALL    CheckSuffix, AX=#str_a2fm_suffix
    IF CC
        jsr     SetBWMode
    END_IF

        ;; AUX memory half
        sta     PAGE2OFF
        JUMP_TABLE_MLI_CALL READ, read_image_params

        ;; NOTE: Why not just load into Aux directly by setting
        ;; PAGE2ON? This works unless loading from a RamWorks-based
        ;; RAM Disk, where things get messed up. This is slightly
        ;; slower in the non-RamWorks case.
        ;; TODO: Load directly into Aux if RamWorks is not present.

        jsr     CopyHiresToAux

        ;; MAIN memory half
        JUMP_TABLE_MLI_CALL READ, read_image_params

        RETURN  C=0             ; success

.endproc ; ShowDHRFile

;;; ============================================================

.proc CopyHiresToAux
        ptr := $06

        sta     CLR80STORE
        sta     RAMWRTON

        copy16  #hires, ptr
        ldx     #>kHiresSize    ; number of pages to copy
        ldy     #0
    DO
      DO
        copy8   (ptr),y, (ptr),y
        iny
      WHILE NOT_ZERO
        inc     ptr+1
        dex
    WHILE NOT_ZERO

        sta     SET80STORE
        sta     RAMWRTOFF
        rts
.endproc ; CopyHiresToAux

;;; ============================================================

;;; Output: C=0 on success, C=1 on failure
.proc ShowMinipixFile
        jsr     SetBWMode

        ;; Load file at minipix_src_buf (MAIN $1800)
        JUMP_TABLE_MLI_CALL READ, read_minipix_params

        ;; Convert (main to aux)
        jsr     ConvertMinipixToBitmap

        ;; Draw
        JUMP_TABLE_MGTK_CALL MGTK::InitPort, aux::grafport
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, aux::grafport
        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, aux::notpencopy
        JUMP_TABLE_MGTK_CALL MGTK::PaintBitsHC, aux::paintbits_params

        RETURN  C=0             ; success
.endproc ; ShowMinipixFile

;;; ============================================================
;;; Convert single hires to double hires

;;; Assumes the image is loaded to MAIN $2000 and
;;; relies on the hr_to_dhr.inc table.

.proc HRToDHR
        ptr     := $06
        kRows   = 192
        kCols   = 40
        spill   := $08          ; spill-over

        lda     #0              ; row
    DO
        pha
        tax
        copy8   hires_table_lo,x, ptr
        copy8   hires_table_hi,x, ptr+1

        ldy     #kCols-1         ; col

        copy8   #0, spill       ; spill-over

      DO
        lda     (ptr),y
        tax

        bmi     hibitset

        ;; spill bit in from previous column; main bit7 encodes bit to spill

        lda     hr_to_dhr_aux,x
        sta     PAGE2ON
        sta     (ptr),y
        lda     hr_to_dhr_main,x
        ora     spill           ; apply previous spill bit (to bit 6)
        sta     PAGE2OFF
        sta     (ptr),y

        jmp     next

hibitset:
        ;; no bit to spill in, but spill out leftmost pixel

        lda     hr_to_dhr_aux,x
        pha
        sta     PAGE2ON
        sta     (ptr),y
        lda     hr_to_dhr_main,x
        sta     PAGE2OFF
        sta     (ptr),y

        pla
        ror
        ror

next:
        ror
        and     #(1 << 6)
        sta     spill

        dey
      WHILE POS

        pla
        clc
        adc     #1
    WHILE A <> #kRows

done:   rts
.endproc ; HRToDHR

;;; ============================================================

;;; Output: C=0 on success, C=1 on failure
.proc ShowLRFileImpl
        ENTRY_POINTS_FOR_BIT7_FLAG double, single, double_flag

        sta     PAGE2OFF

        hr_ptr := $06
        lr_ptr := $08

        kRows   = 192
        kCols   = 40

        ;; Aux
        JUMP_TABLE_MLI_CALL READ, read_lores_params
        sta     PAGE2ON
        CALL    convert, A=#0   ; aux
        sta     PAGE2OFF

        ;; Main
        double_flag := *+1
        lda     #SELF_MODIFIED_BYTE
    IF NS
        JUMP_TABLE_MLI_CALL READ, read_lores_params
    END_IF
        lda     #$80            ; main
        FALL_THROUGH_TO convert

convert:
        sta     is_main

        ;; Loop over HR rows
        lda     #0              ; A = row
    DO
        pha                     ; A = row

        ;; Destination hires row
        tax
        copylohi hires_table_lo,x, hires_table_hi,x, hr_ptr

        ;; Source lores row (in `lores_src_buf`)
        lda     hr_ptr
        clc
        adc     #<lores_src_buf
        sta     lr_ptr          ; lo
        lda     hr_ptr+1
        and     #%00000011
        adc     #>lores_src_buf
        sta     lr_ptr+1        ; hi

        ;; Loop over columns
        ldy     #0
      DO
        lda     (lr_ptr),y      ; read source
        tax                     ; X = double pixel

        ;; Which nibble?
        pla                     ; A = row
        pha                     ; A = row
        and     #%0000100
       IF ZERO
        ;; Top nibble
        txa                     ; A = double pixel
        and     #%00001111      ; A = pixel
       ELSE
        ;; Bottom nibble
        txa                     ; A = double pixel
        lsr
        lsr
        lsr
        lsr                     ; A = pixel
       END_IF

        ;; In double-lores, the aux-bank patterns are shifted
        bit     double_flag
       IF NS
        bit     is_main
        IF NC
        ;; rotate lo nibble left, A = 0000abcd
        asl                     ; A = 000abcd0
        adc     #%11110000      ; A = xxxxbcd0 C=a
        adc     #0              ; A = xxxxbcda
        and     #%00001111      ; A = 0000bcda
        END_IF
       END_IF

        ;; Convert pixel bit pattern into lookup
        pha                     ; A = 0000PPPP (P = pattern)
        tya                     ; A = col
        ror                     ; C = odd?
        pla                     ; A = 0000PPPP (P = pattern)
        rol                     ; A = 000PPPPO (P = pattern, O = odd?)
        is_main := *+1          ; N = main?
        ldx     #SELF_MODIFIED_BYTE
        cpx     #$80-1          ; C = main?
        rol                     ; A = 00PPPPOM (P = pattern, O = odd? M = main?)
        tax                     ; X = 00CCCCOM C = color O = odd? M = main?

        ;; Splat into 4 hires rows
        lda     hr_ptr+1        ; save ptr
        pha

        lda     bitmap_table,x
        ldx     #4              ; 4 hires rows = 1 lores pixel
       DO
        sta     (hr_ptr),y
        inc     hr_ptr+1
        inc     hr_ptr+1
        inc     hr_ptr+1
        inc     hr_ptr+1
        dex
       WHILE NOT_ZERO
        pla                     ; restore ptr
        sta     hr_ptr+1

        iny                     ; next col
      WHILE Y <> #kCols

        pla                     ; A = row
        clc
        adc     #4
    WHILE A < #kRows

        RETURN  C=0             ; success

bitmap_table:
        .byte   %0000000,%0000000,%0000000,%0000000
        .byte   %0001000,%0010001,%0100010,%1000100
        .byte   %0010001,%0100010,%1000100,%0001000
        .byte   %0011001,%0110011,%1100110,%1001100
        .byte   %0100010,%1000100,%0001000,%0010001
        .byte   %0101010,%1010101,%0101010,%1010101
        .byte   %0110011,%1100110,%1001100,%0011001
        .byte   %0111011,%1110111,%1101110,%1011101
        .byte   %1000100,%0001000,%0010001,%0100010
        .byte   %1001100,%0011001,%0110011,%1100110
        .byte   %1010101,%0101010,%1010101,%0101010
        .byte   %1011101,%0111011,%1110111,%1101110
        .byte   %1100110,%1001100,%0011001,%0110011
        .byte   %1101110,%1011101,%0111011,%1110111
        .byte   %1110111,%1101110,%1011101,%0111011
        .byte   %1111111,%1111111,%1111111,%1111111

.endproc ; ShowDLRFile
ShowLRFile := ShowLRFileImpl::single
ShowDLRFile := ShowLRFileImpl::double

;;; ============================================================
;;; Minipix images

;;; Assert: Running from Main
;;; Source is in Main, destination is in Aux

.proc ConvertMinipixToBitmap
        kRows   = 52
        kCols   = 88            ; pixels

        src := $06
        dst := $08

        srcbit := $0A
        dstbit := $0B
        row    := $0C

        ;; Copy the writing code to the ZP
        COPY_BYTES sizeof_PutBitProc, PutBitProc, z:PutBitProcTarget

        copy16  #minipix_src_buf, src
        copy16  #minipix_dst_buf, dst

        ;; c/o Kent Dickey on comp.sys.apple2.programmer
        ;; https://groups.google.com/d/msg/comp.sys.apple2.programmer/XB0jUEvrAhE/loRorS5fBwAJ

        ldx     #kRows
        stx     row
        ldy     #0              ; Y remains unchanged throughout

        ;; For each row...
dorow:  ldx     #8
        stx     srcbit
        ldx     #7
        stx     dstbit
        ldx     #kCols

        ;; Process each bit
    DO
        jsr     GetBit
        jsr     PutBit2
        dex
    WHILE NOT_ZERO

        ;; We've written out 88*2 bits = 176 bits.  This means 1 bit was shifted into
        ;; the last bit.  We need to get it from the MSB to the LSB, so it needs
        ;; to be shifted down 7 bits
    DO
        clc
        jsr     PutBit1
        dex
    WHILE X <> #AS_BYTE(-7)     ; do 7 times == 7 bits

        dec     row
        bne     dorow

        rts

.proc GetBit
        lda     (src),y
        rol
        sta     (src),y
        dec     srcbit
        bne     done

        inc16   src
        copy8   #8, srcbit

done:   rts
.endproc ; GetBit

PutBitProcTarget = $10
PROC_AT PutBitProc, $10
.proc PutBit2
        php
        jsr     PutBit1
        plp
        FALL_THROUGH_TO PutBit1
.endproc ; PutBit2
.proc PutBit1
        sta     RAMRDON
        sta     RAMWRTON

        lda     (dst),y
        ror
        sta     (dst),y
        dec     dstbit
        bne     done

        ror                     ; shift once more to get bits in right place
        sta     (dst),y
        inc16   dst
        copy8   #7, dstbit

done:
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc ; PutBit1
END_PROC_AT
        PutBit1 := PutBitProc::PutBit1
        PutBit2 := PutBitProc::PutBit2
        sizeof_PutBitProc = .sizeof(PutBitProc)
.endproc ; ConvertMinipixToBitmap

;;; ============================================================
;;; Color/B&W Toggle

color_mode_flag:   .byte   0    ; bit7=0 = B&W, bit7=1 = color

.proc ToggleMode
        bit     color_mode_flag
        bmi     SetBWMode
        FALL_THROUGH_TO SetColorMode
.endproc ; ToggleMode

.proc SetColorMode
        bit     color_mode_flag
    IF NC
        SET_BIT7_FLAG color_mode_flag
        jsr     JUMP_TABLE_COLOR_MODE
    END_IF
        rts
.endproc ; SetColorMode

.proc SetBWMode
        bit     color_mode_flag
    IF NS
        CLEAR_BIT7_FLAG color_mode_flag
        jsr     JUMP_TABLE_MONO_MODE
    END_IF
        rts
.endproc ; SetBWMode

;;; ============================================================

;;; Input: A,X = callback proc, called with:
;;;    A = byte, Y = 0 on entry/exit
;;; Output: C=0 on success, C=1 on failure
.proc UnpackReadImpl
        DEFINE_READWRITE_PARAMS read_buf_params, read_buf, 0

start:
        stax    write_proc

        copy8   open_image_params::ref_num, read_buf_params::ref_num

        ;; Read next op/count byte
loop:   copy8   #1, read_buf_params::request_count
        JUMP_TABLE_MLI_CALL READ, read_buf_params
        bcc     body

        ;; EOF (or other error) - finish up
        RETURN  C=0             ; success

        ;; Process op/count
body:   lda     read_buf
        and     #%00111111      ; count is low 6 bits + 1
        sta     count
        inc     count

        lda     read_buf
        and     #%11000000      ; operation is top 2 bits
        bne     not_00

        ;; --------------------------------------------------
        ;; %00...... = 1 to 64 bytes follow - all different

        copy8   count, read_buf_params::request_count
        JUMP_TABLE_MLI_CALL READ, read_buf_params
        ldy     #0

        ldx     #0
    DO
        CALL    Write, A=read_buf,x
        inx
    WHILE X <> count

        jmp     loop

        ;; --------------------------------------------------

not_00: cmp     #%01000000
        bne     not_01

        ;; --------------------------------------------------
        ;; %01...... = 3, 5, 6, or 7 repeats of next byte

        copy8   #1, read_buf_params::request_count
        JUMP_TABLE_MLI_CALL READ, read_buf_params
        ldy     #0
        lda     read_buf

    DO
        jsr     Write
        dec     count
    WHILE NOT_ZERO

        jmp     loop

        ;; --------------------------------------------------

not_01: cmp     #%10000000
        bne     not_10

        ;; --------------------------------------------------
        ;; %10...... = 1 to 64 repeats of next 4 bytes

        copy8   #4, read_buf_params::request_count
        JUMP_TABLE_MLI_CALL READ, read_buf_params
        ldy     #0

    DO
        CALL    Write, A=read_buf+0
        CALL    Write, A=read_buf+1
        CALL    Write, A=read_buf+2
        CALL    Write, A=read_buf+3
        dec     count
    WHILE NOT_ZERO

        jmp     loop

        ;; --------------------------------------------------

not_10:
        ;; --------------------------------------------------
        ;; %11...... = 1 to 64 repeats of next byte taken as 4 bytes

        copy8   #1, read_buf_params::request_count
        JUMP_TABLE_MLI_CALL READ, read_buf_params
        ldy     #0
        lda     read_buf

    DO
        jsr     Write
        jsr     Write
        jsr     Write
        jsr     Write
        dec     count
    WHILE NOT_ZERO

        jmp     loop


        write_proc := *+1
Write:  jmp     SELF_MODIFIED

count:  .byte   0

read_buf:
        .res    64

.endproc ; UnpackReadImpl
UnpackRead := UnpackReadImpl::start

;;; ============================================================

;;; Unpack HR / DHR
;;; Output: C=0 on success, C=1 on failure
.proc ShowPackedHRDHRFileImpl
        ptr := $06

        ;; N = is dhr?, V = is aux page?
        ENTRY_POINTS_FOR_A dhr_file, $C0, hr_file, $00
        sta     dhr_flags

        copy16  #hires, ptr

        sta     PAGE2OFF

        CALL    UnpackRead, AX=#Write

        bit     dhr_flags       ; if hires, need to convert
    IF NC
        jsr     HRToDHR
    END_IF

        RETURN  C=0             ; success

        ;; --------------------------------------------------
        ;; Callback for each unique byte to write
        ;; A = byte
        ;; Y = 0 on entry/exit

.proc Write
        ;; ASSERT: Y=0
        sta     (ptr),y
        inc     ptr
        RTS_IF NOT_ZERO

        pha

        inc     ptr+1
        lda     ptr+1
        cmp     #$40            ; did we hit page 2?
        bne     exit
        copy8   #$20, ptr+1     ; yes, back to page 1

        bit     dhr_flags       ; if DHR aux half, need to copy page to aux
        bvc     exit            ; nope
        copy8   #$80, dhr_flags

        ;; Save ptr, X, Y
        lda     ptr
        pha
        lda     ptr+1
        pha
        txa
        pha
        tya
        pha

        jsr     CopyHiresToAux

        ;; Restore ptr, X, Y
        pla
        tay
        pla
        tax
        pla
        sta     ptr+1
        pla
        sta     ptr

exit:   pla
        rts
.endproc ; Write

        ;; --------------------------------------------------

dhr_flags:
        .byte   0               ; bit7 = is dhr, bit6 = is aux page

.endproc ; ShowPackedHRDHRFileImpl
ShowPackedHRFile     := ShowPackedHRDHRFileImpl::hr_file
ShowPackedDHRFile    := ShowPackedHRDHRFileImpl::dhr_file

;;; ============================================================
;;; Clear screen to black

.proc ClearScreen
        ptr := $6
        kHiresSize = $2000

        sta     PAGE2ON         ; Clear aux
        jsr     clear
        sta     PAGE2OFF        ; Clear main
        FALL_THROUGH_TO clear

clear:  copy16  #hires, ptr
        lda     #0              ; clear to black
        ldx     #>kHiresSize    ; number of pages
        ldy     #0              ; pointer within page
    DO
      DO
        sta     (ptr),y
        iny
      WHILE NOT_ZERO
        inc     ptr+1
        dex
    WHILE NOT_ZERO
        rts

done:
.endproc ; ClearScreen

;;; ============================================================
;;; Check suffix on `INVOKE_PATH` to see if it matches passed string
;;; Inputs: A,X = pointer to suffix (uppercase)
;;; Outputs: C=0 on match, C=1 otherwise
;;; Trashes $06

.proc CheckSuffix
        ptr := $06

        stax    ptr

        ldy     #0
        lda     (ptr),y
        tay
        ldx     INVOKE_PATH
    DO
        lda     INVOKE_PATH,x
        jsr     ToUpperCase     ; passed suffix is always uppercase
        cmp     (ptr),y
        bne     no              ; different - not a match
        dey
        beq     yes             ; out of suffix - it's a match
        dex
    WHILE NOT_ZERO

no:     RETURN  C=1             ; no match

yes:    RETURN  C=0             ; match!

.endproc ; CheckSuffix

;;; ============================================================

;;; Output: C=0 on success, C=1 on failure
.proc ShowSHRImpl

        ENTRY_POINTS_FOR_BIT7_FLAG packed, unpacked, packed_flag

        ;; IIgs?
        bit     ROMIN2
        CALL    IDROUTINE, C=1  ; Clears carry if IIgs
        bit     LCBANK1
        bit     LCBANK1
        bcc     is_iigs

        ;; Not IIgs - just fail fast
        RETURN  C=1             ; failure

        ;; --------------------------------------------------

is_iigs:
        SHR_SCREEN = $E12000
        kSHRSize = $8000

        jsr     InitSHR
        bit     packed_flag
    IF NS
        jsr     LoadPackedSHR
    ELSE
        jsr     LoadUnpackedSHR
    END_IF
        copy16  #ExitSHR, exit_hook

        RETURN  C=0             ; success

packed_flag:                    ; bit7
        .byte   0

        ;; --------------------------------------------------

.proc InitSHR
        .pushcpu
        .p816
        .a8

        ;; Disable shadowing
        lda     #%00111111
        tsb     SHADOW

        ;; Enable SHR
        lda     #%11000000
        tsb     NEWVIDEO

        clc                     ; leave emulation mode
        xce

        ;; Memory fill
        copy8   #0, SHR_SCREEN  ; initialize first byte

        .a16
        .i16
        rep     #$30            ; 16-bit accum/memory, index registers

        phb                     ; save data bank
        ldx     #.loword(SHR_SCREEN)
        ldy     #.loword(SHR_SCREEN)+1
        lda     #kSHRSize - 2
        mvn     #^SHR_SCREEN, #^SHR_SCREEN
        plb                     ; restore data bank

        sec                     ; re-enter emulation mode
        xce

        .popcpu

        rts
.endproc ; InitSHR

        ;; --------------------------------------------------

.proc LoadUnpackedSHR
        ;; Load $2000 bytes at a time, and copy them to
        ;; the SHR screen

        copy8   #>.loword(SHR_SCREEN), dest+1

    DO
        ;; Load data
        JUMP_TABLE_MLI_CALL READ, read_image_params

        ;; Copy into SHR screen
        .pushcpu
        .p816
        clc                     ; leave emulation mode
        xce

        ;; Block move
        .a16
        .i16
        rep     #$30            ; 16-bit accum/memory, index registers
        phb                     ; preserve data bank
        ldx     #hires          ; source
        dest := *+1              ; destination
        ldy     #.loword(SHR_SCREEN) ; high byte is self-modified
        lda     #kHiresSize-1   ; length-1
        mvn     #^hires, #^SHR_SCREEN
        plb                     ; restore data bank

        sec                     ; re-enter emulation mode
        xce
        .popcpu

        lda     dest+1
        clc
        adc     #>kHiresSize
        sta     dest+1
    WHILE A <> #>(SHR_SCREEN+kSHRSize)

        rts
.endproc ; LoadUnpackedSHR

        ;; --------------------------------------------------

.proc LoadPackedSHR

        copy24  #SHR_SCREEN, addr

        TAIL_CALL UnpackRead, AX=#write

        ;; A = byte
        ;; Y = 0 on entry/exit
write:

        ;; Copy into SHR screen
        .pushcpu
        .p816

        addr := *+1
        sta     $123456

        inc24   addr
        rts
        .popcpu

.endproc ; LoadPackedSHR

        ;; --------------------------------------------------

.proc ExitSHR
        .pushcpu
        .p816
        .a8

        ;; Re-enable shadowing
        lda     #%00111111
        trb     SHADOW

        ;; Disable SHR
        lda     #%11000000
        trb     NEWVIDEO

        .popcpu

        rts
.endproc ; ExitSHR

.endproc ; ShowSHRImpl
ShowPackedSHR := ShowSHRImpl::packed
ShowUnpackedSHR := ShowSHRImpl::unpacked

;;; ============================================================

;;; Inputs: A,X = `FileEntry`
;;; Output: C=1 if it's an image file we can preview, C=0 otherwise
;;; Trashes: $06

.proc IsImageFileEntry
        ;; Copy somewhere more convenient
        ptr := $06
        stax    ptr
        ldy     #.sizeof(FileEntry)-1
    DO
        copy8   (ptr),y, entry,y
        dey
    WHILE POS

        ;; TODO: Keep this logic in sync with DeskTop's
        ;; `ICT_RECORD` definitions for graphics files.

        ;; Check file suffixes
        lda     entry+FileEntry::storage_type_name_length
        and     #NAME_LENGTH_MASK
        sta     entry+FileEntry::storage_type_name_length
        CALL    check_suffix, AX=#str_a2fc_suffix
        jcc     yes
        CALL    check_suffix, AX=#str_a2fm_suffix
        jcc     yes
        CALL    check_suffix, AX=#str_a2lc_suffix
        jcc     yes
        CALL    check_suffix, AX=#str_a2hr_suffix
        jcc     yes

        ;; File type
        lda     entry+FileEntry::file_type
        cmp     #FT_GRAPHICS
        jeq     yes

    IF A = #FT_PNT
        ecmp16  entry+FileEntry::aux_type, #$0001
        jeq     yes
        jmp     no
    END_IF

    IF A = #FT_PIC
        ecmp16  entry+FileEntry::aux_type, #$0000
        jeq     yes
        jne     no              ; always
    END_IF

        cmp     #FT_BINARY
        jne     no

        ;; Binary: Must match size/address
        ecmp16  entry+FileEntry::blocks_used, #33 ; DHR
    IF EQ
        ecmp16  entry+FileEntry::aux_type, #$2000
        jeq     yes
        ecmp16  entry+FileEntry::aux_type, #$4000
        jeq     yes
    END_IF

        ecmp16  entry+FileEntry::blocks_used, #17 ; HR
    IF EQ
        ecmp16  entry+FileEntry::aux_type, #$2000
        beq     yes
        ecmp16  entry+FileEntry::aux_type, #$4000
        beq     yes
    END_IF

        ecmp16  entry+FileEntry::blocks_used, #3 ; MiniPix
    IF EQ
        ecmp16  entry+FileEntry::aux_type, #$5800
        beq     yes
    END_IF

        ecmp16  entry+FileEntry::blocks_used, #3 ; LR
    IF EQ
        ecmp16  entry+FileEntry::aux_type, #$400
        beq     yes
    END_IF

        ecmp16  entry+FileEntry::blocks_used, #5 ; DLR
    IF EQ
        ecmp16  entry+FileEntry::aux_type, #$400
        beq     yes
    END_IF

no:     RETURN  C=0

yes:    RETURN  C=1

        ;; --------------------------------------------------

;;; Input: A,X = suffix to check against `entry` (uppercase)
;;; Output: C=0 on match, C=1 otherwise
.proc check_suffix
        ptr := $06
        path := entry+FileEntry::storage_type_name_length

        stax    ptr

        ldy     #0
        lda     (ptr),y
        tay
        ldx     path
    DO
        lda     path,x
        jsr     ToUpperCase     ; passed suffix is always uppercase
        cmp     (ptr),y
        bne     no              ; different - not a match
        dey
        beq     yes             ; out of suffix - it's a match
        dex
    WHILE NOT_ZERO

no:     RETURN  C=1             ; no match

yes:    RETURN  C=0             ; match!

.endproc ; check_suffix

        ;; --------------------------------------------------

entry:  .tag    FileEntry
.endproc ; IsImageFileEntry

;;; ============================================================

;;; Inputs: A,X = callback, invoked with A,X=`FileEntry`
;;;         `dir_path` populated
;;; Note: Callbacks must not modify $08, but can use $06

.proc EnumerateDirectory

;;; Memory Map
io_buf    := DA_IO_BUFFER              ; $1C00-$1FFF
block_buf := DA_IO_BUFFER - BLOCK_SIZE ; $1A00-$1BFF

kEntriesPerBlock = $0D

        stax    callback

        CLEAR_BIT7_FLAG saw_header_flag

        ;; Open directory
        JUMP_TABLE_MLI_CALL OPEN, open_params
        jcs     exit

        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num

next_block:
        JUMP_TABLE_MLI_CALL READ, read_params
        bcs     close
        copy8   #AS_BYTE(-1), entry_in_block
        entry_ptr := $08
        copy16  #(block_buf+4 - .sizeof(FileEntry)), entry_ptr

next_entry:
        ;; Advance to next entry
        lda     entry_in_block
        cmp     #kEntriesPerBlock
        beq     next_block

        inc     entry_in_block
        add16_8 entry_ptr, #.sizeof(FileEntry)

        ;; Header?
        bit     saw_header_flag
    IF NC
        SET_BIT7_FLAG saw_header_flag
        bmi     next_entry      ; always
    END_IF

        ;; Active entry?
        ldy     #FileEntry::storage_type_name_length
        lda     (entry_ptr),y
        beq     next_entry

        ;; Invoke callback
        ldax    entry_ptr
        callback := *+1
        jsr     SELF_MODIFIED

        jmp     next_entry

close:  php
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        plp
exit:
        rts

        DEFINE_OPEN_PARAMS open_params, dir_path, io_buf
        DEFINE_READWRITE_PARAMS read_params, block_buf, BLOCK_SIZE
        DEFINE_CLOSE_PARAMS close_params

entry_in_block:
        .byte   0
saw_header_flag:                ; bit7
        .byte   0

.endproc ; EnumerateDirectory

;;; ============================================================

.proc NextFile
        lda     #$80
        bne     ChangeFile  ; always
.endproc ; NextFile
.proc LastFile
        lda     #$C0
        bne     ChangeFile  ; always
.endproc ; LastFile
.proc PreviousFile
        lda     #$00
        beq     ChangeFile  ; always
.endproc ; PreviousFile
.proc FirstFile
        lda     #$40
        FALL_THROUGH_TO ChangeFile
.endproc ; FirstFile

;;; Input: A = flags, bit6 = modified, bit7 = advance
.proc ChangeFile
        sta     flags

        ;; Init state
        lda     #0
        sta     seen_flag
        sta     first_filename
        sta     last_filename
        sta     prev_filename
        sta     next_filename

        ;; Extract current path's dir
        COPY_STRING INVOKE_PATH, dir_path
        ldx     dir_path
        inx
    DO
        dex
        lda     dir_path,x
    WHILE A <> #'/'
        dex
        stx     dir_path

        ;; Copy current path's file
        inx
        ldy     #0
    DO
        inx
        iny
        lda     dir_path,x
        jsr     ToUpperCase
        sta     cur_filename,y
    WHILE X <> INVOKE_PATH
        sty     cur_filename

        CALL    EnumerateDirectory, AX=#callback

        ;; `first_filename` and `last_filename` are now populated,
        ;; along with maybe `prev_filename` and `next_filename`.
        ;; Based on `flags`, pick the right file to show.
        bit     flags
    IF VS
      IF NS
        ldax    #last_filename
      ELSE
        ldax    #first_filename
      END_IF
    ELSE_IF NS
        lda     next_filename
      IF NOT_ZERO
        ldax    #next_filename
      ELSE
        ldax    #first_filename
      END_IF
    ELSE
        lda     prev_filename
      IF NOT_ZERO
        ldax    #prev_filename
      ELSE
        ldax    #last_filename
      END_IF
    END_IF

        fnptr   := $06
        stax    fnptr

        ;; Append filename to `dir_path`
        ldy     #0
        lda     (fnptr),y
        beq     fail            ; in case something went wrong
        sta     len
        ldx     dir_path
        inx
    DO
        inx
        iny
        copy8   (fnptr),y, dir_path,x
        len := *+1
        cpy     #SELF_MODIFIED_BYTE
    WHILE NE
        stx     dir_path

        COPY_STRING dir_path, INVOKE_PATH
fail:   jmp     Init

;;; Called with A,X = `FileEntry`
.proc callback
        stax    tmp
        jsr     IsImageFileEntry ; A,X = `FileEntry`
        bcc     ret

        ptr := $06
        ldax    tmp
        stax    ptr

        ;; Always record this as the last one seen
        ldy     #0
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        sta     (ptr),y
        tay
    DO
        lda     (ptr),y
        jsr     ToUpperCase
        sta     last_filename,y
        dey
    WHILE POS

        ;; First seen? might need it
        lda     first_filename
    IF ZERO
        COPY_STRING last_filename, first_filename
    END_IF

        ;; Is this the current file?
        ldx     cur_filename
        cpx     last_filename
        bne     not_cur
    DO
        lda     cur_filename,x
        cmp     last_filename,x
        bne     not_cur
        dex
    WHILE NOT_ZERO

        SET_BIT7_FLAG seen_flag
        rts

not_cur:
        ;; No, might be prev or next though

        ;; Seen the current file yet? If not, save it as previous
        bit     seen_flag
    IF NC
        COPY_STRING last_filename, prev_filename
        rts
    END_IF

        ;; Yes... have we seen one after it? If not, save it as next
        lda     next_filename
    IF ZERO
        COPY_STRING last_filename, next_filename
    END_IF

ret:    rts

tmp:    .addr   0
.endproc ; callback

flags:                          ; bit 6 = modified, bit 7 = advance
        .byte   0
seen_flag:                      ; bit7
        .byte   0
cur_filename:
        .res    16
first_filename:
        .res    16
prev_filename:
        .res    16
next_filename:
        .res    16
last_filename:
        .res    16

.endproc ; ChangeFile


;;; ============================================================

str_a2fc_suffix:
        PASCAL_STRING ".A2FC"
str_a2fm_suffix:
        PASCAL_STRING ".A2FM"
str_a2lc_suffix:
        PASCAL_STRING ".A2LC"
str_a2hr_suffix:
        PASCAL_STRING ".A2HR"

;;; ============================================================

        .include "../lib/uppercase.s"
        .include "../inc/hires_table.inc"
        .include "inc/hr_to_dhr.inc"

.proc LZ4FH
        .include "../lib/lz4fh6502.s"
.endproc ; LZ4FH

;;; ============================================================

        .assert * < minipix_src_buf, error, "buffer collision!"
        .assert * < lores_src_buf, error, "buffer collision!"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
