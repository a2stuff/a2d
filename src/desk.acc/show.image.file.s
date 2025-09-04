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
;;;  $1900   +-----------+ +-----------+
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
        minipix_src_buf := $1900 ; Load address (main)
        kMinipixSrcSize = 576
        minipix_dst_buf := $1900 ; Convert address (aux)
        kMinipixDstSize = 26*52

        dir_path := $380

        .assert (minipix_src_buf + kMinipixSrcSize) < DA_IO_BUFFER, error, "Not enough room for Minipix load buffer"
        .assert (minipix_dst_buf + kMinipixDstSize) < $2000, error, "Not enough room for Minipix convert buffer"

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

        DEFINE_OPEN_PARAMS open_params, INVOKE_PATH, DA_IO_BUFFER
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, INVOKE_PATH
        DEFINE_GET_EOF_PARAMS get_eof_params

        DEFINE_READWRITE_PARAMS read_params, hires, kHiresSize
        DEFINE_READWRITE_PARAMS read_minipix_params, minipix_src_buf, kMinipixSrcSize

        DEFINE_CLOSE_PARAMS close_params

;;; ============================================================

event_params:   .tag MGTK::Event

;;; ============================================================

.proc CopyEventAuxToMain
        copy16  #aux::event_params, STARTLO
        copy16  #aux::event_params + .sizeof(MGTK::Event) - 1, ENDLO
        copy16  #event_params, DESTINATIONLO
        clc                     ; aux > main
        jmp     AUXMOVE
.endproc ; CopyEventAuxToMain

;;; ============================================================

.proc Init
        copy8   #0, mode

        ;; In case we're re-entered c/o switching to another file
        jsr     MaybeCallExitHook

        JUMP_TABLE_MLI_CALL OPEN, open_params
        lda     open_params::ref_num
        sta     get_eof_params::ref_num
        sta     read_params::ref_num
        sta     read_minipix_params::ref_num
        sta     close_params::ref_num

        JUMP_TABLE_MGTK_CALL MGTK::HideCursor
        jsr     ClearScreen
        jsr     SetColorMode
        jsr     ShowFile        ; C=1 on failure
        php
        JUMP_TABLE_MGTK_CALL MGTK::ShowCursor
        JUMP_TABLE_MLI_CALL CLOSE, close_params
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
        copy8   #0, slideshow_flag

        lda     event_params + MGTK::Event::key
        jsr     ToUpperCase

        ldx     event_params + MGTK::Event::modifiers
    IF_NOT_ZERO
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

    IF_A_EQ     #'S'
        cpy     #$00             ; Y = previous `slideshow_flag` state
        bne     InputLoop        ; Ignore (so toggle) if slideshow mode was on
        beq     SetSlideshowMode ; always
    END_IF

    IF_A_EQ     #' '
        jsr     ToggleMode
    END_IF

        jmp     InputLoop
.endproc ; InputLoop

;;; ============================================================

.proc SetSlideshowMode
        copy8   #$80, slideshow_flag
        jsr     InitSlideshowCounter
        jmp     InputLoop
.endproc ; SetSlideshowMode

.proc InitSlideshowCounter
        ldx     #DeskTopSettings::dblclick_speed
        jsr     JUMP_TABLE_READ_SETTING
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
    IF_NS
        lda     #kDynamicRoutineRestoreBuffer
        jsr     JUMP_TABLE_RESTORE_OVL
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
    IF_NOT_ZERO
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
    IF_CS
fail:   rts
    END_IF

        lda     get_file_info_params::file_type

        cmp     #FT_DIRECTORY
        RTS_IF_EQ               ; C=1 signals failure

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
    IF_X_EQ     #$80
      IF_A_EQ   #$66
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

        ;; If bigger than $2000, assume DHR

        lda     get_eof_params::eof ; fancy 3-byte unsigned compare
        cmp     #<(kHiresSize+1)
        lda     get_eof_params::eof+1
        sbc     #>(kHiresSize+1)
        lda     get_eof_params::eof+2
        sbc     #^(kHiresSize+1)
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
        JUMP_TABLE_MLI_CALL READ, read_params

        lda     SIGNATURE
        sta     signature

        ;; HR or DHR?
        and     #kSigDHR
        bne     dhr

        ;; If HR, convert to DHR.
        jsr     HRToDHR
        jmp     finish

        ;; If DHR, copy Main>Aux and load Main page.
dhr:    jsr     CopyHiresToAux
        JUMP_TABLE_MLI_CALL READ, read_params

finish:
        lda     signature
        and     #kSigColor
    IF_ZERO
        jsr     SetBWMode
    END_IF

        clc                     ; success
        rts

signature:
        .byte   0
.endproc ; ShowFOTFile

;;; ============================================================

;;; Output: C=0 on success, C=1 on failure
.proc ShowLZ4FHFile
        sta     PAGE2OFF

        copy8   #$80, restore_buffer_overlay_flag
        copy16  #OVERLAY_BUFFER, read_params::data_buffer
        JUMP_TABLE_MLI_CALL READ, read_params
        copy16  #$2000, read_params::data_buffer

        ;; NOTE: `Init` also calls `CLOSE`, but it's harmless to call
        ;; it twice.
        JUMP_TABLE_MLI_CALL CLOSE, close_params

        copy16  #OVERLAY_BUFFER, z:LZ4FH__in_src
        copy16  #$2000, z:LZ4FH__in_dst
        jsr     LZ4FH
        bne     fail

        jsr     HRToDHR

        clc                     ; success
        rts

fail:   sec                     ; failure
        rts

.endproc ; ShowLZ4FHFile

;;; ============================================================

;;; Output: C=0 on success, C=1 on failure
.proc ShowHRFile
        ;; If suffix is ".A2HR" show in mono mode
        param_call CheckSuffix, str_a2hr_suffix
    IF_CC
        jsr     SetBWMode
    END_IF

        sta     PAGE2OFF
        JUMP_TABLE_MLI_CALL READ, read_params

        jsr     HRToDHR

        clc                     ; success
        rts

.endproc ; ShowHRFile

;;; ============================================================

;;; Output: C=0 on success, C=1 on failure
.proc ShowDHRFile
        ptr := $06

        ;; If suffix is ".A2FM" show in mono mode
        param_call CheckSuffix, str_a2fm_suffix
    IF_CC
        jsr     SetBWMode
    END_IF

        ;; AUX memory half
        sta     PAGE2OFF
        JUMP_TABLE_MLI_CALL READ, read_params

        ;; NOTE: Why not just load into Aux directly by setting
        ;; PAGE2ON? This works unless loading from a RamWorks-based
        ;; RAM Disk, where things get messed up. This is slightly
        ;; slower in the non-RamWorks case.
        ;; TODO: Load directly into Aux if RamWorks is not present.

        jsr     CopyHiresToAux

        ;; MAIN memory half
        JUMP_TABLE_MLI_CALL READ, read_params

        clc                     ; success
        rts

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
      WHILE_NOT_ZERO
        inc     ptr+1
        dex
    WHILE_NOT_ZERO

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

        clc                     ; success
        rts
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
rloop:  pha
        tax
        copy8   hires_table_lo,x, ptr
        copy8   hires_table_hi,x, ptr+1

        ldy     #kCols-1         ; col

        copy8   #0, spill       ; spill-over

cloop:  lda     (ptr),y
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
        bpl     cloop

        pla
        clc
        adc     #1
        cmp     #kRows
        bne     rloop

done:   rts
.endproc ; HRToDHR

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
    WHILE_NOT_ZERO

        ;; We've written out 88*2 bits = 176 bits.  This means 1 bit was shifted into
        ;; the last bit.  We need to get it from the MSB to the LSB, so it needs
        ;; to be shifted down 7 bits
    DO
        clc
        jsr     PutBit1
        dex
    WHILE_X_NE  #AS_BYTE(-7)    ; do 7 times == 7 bits

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
        lda     #8
        sta     srcbit

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
        lda     #7
        sta     dstbit

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

mode:   .byte   0               ; 0 = B&W, $80 = color

.proc ToggleMode
        lda     mode
        bne     SetBWMode
        FALL_THROUGH_TO SetColorMode
.endproc ; ToggleMode

.proc SetColorMode
        lda     mode
        bne     done
        copy8   #$80, mode

        jsr     JUMP_TABLE_COLOR_MODE

done:   rts
.endproc ; SetColorMode

.proc SetBWMode
        lda     mode
        beq     done
        copy8   #0, mode

        jsr     JUMP_TABLE_MONO_MODE

done:   rts
.endproc ; SetBWMode

;;; ============================================================

;;; Input: A,X = callback proc, called with:
;;;    A = byte, Y = 0 on entry/exit
;;; Output: C=0 on success, C=1 on failure
.proc UnpackReadImpl
        DEFINE_READWRITE_PARAMS read_buf_params, read_buf, 0

start:
        stax    write_proc

        copy8   open_params::ref_num, read_buf_params::ref_num

        ;; Read next op/count byte
loop:   copy8   #1, read_buf_params::request_count
        JUMP_TABLE_MLI_CALL READ, read_buf_params
        bcc     body

        ;; EOF (or other error) - finish up
        clc                     ; success
        rts

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
        lda     read_buf,x
        jsr     Write
        inx
    WHILE_X_NE  count

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
     WHILE_NOT_ZERO

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
        lda     read_buf+0
        jsr     Write
        lda     read_buf+1
        jsr     Write
        lda     read_buf+2
        jsr     Write
        lda     read_buf+3
        jsr     Write
        dec     count
    WHILE_NOT_ZERO

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
    WHILE_NOT_ZERO

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

dhr_file:
        lda     #$C0            ; S = is dhr?, V = is aux page?
        SKIP_NEXT_2_BYTE_INSTRUCTION
hr_file:
        lda     #0
        sta     dhr_flag

        copy16  #hires, ptr

        sta     PAGE2OFF

        param_call UnpackRead, Write

        bit     dhr_flag        ; if hires, need to convert
    IF_NC
        jsr     HRToDHR
    END_IF

        clc                     ; success
        rts

        ;; --------------------------------------------------
        ;; Callback for each unique byte to write
        ;; A = byte
        ;; Y = 0 on entry/exit

.proc Write
        ;; ASSERT: Y=0
        sta     (ptr),y
        inc     ptr
        RTS_IF_NOT_ZERO

        pha

        inc     ptr+1
        lda     ptr+1
        cmp     #$40            ; did we hit page 2?
        bne     exit
        lda     #$20            ; yes, back to page 1
        sta     ptr+1

        bit     dhr_flag        ; if DHR aux half, need to copy page to aux
        bvc     exit            ; nope
        copy8   #$80, dhr_flag

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

dhr_flag:
        .byte   0

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
      WHILE_NOT_ZERO
        inc     ptr+1
        dex
    WHILE_NOT_ZERO
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
    WHILE_NOT_ZERO

no:     sec                     ; no match
        rts

yes:    clc                     ; match!
        rts

.endproc ; CheckSuffix

;;; ============================================================

;;; Output: C=0 on success, C=1 on failure
.proc ShowSHRImpl

packed:
        lda     #$80
        SKIP_NEXT_2_BYTE_INSTRUCTION
unpacked:
        lda     #0
        sta     packed_flag

        ;; IIgs?
        bit     ROMIN2
        sec
        jsr     IDROUTINE       ; Clears carry if IIgs
        bit     LCBANK1
        bit     LCBANK1
        bcc     is_iigs

        ;; Not IIgs - just fail fast
        sec                     ; failure
        rts

        ;; --------------------------------------------------

is_iigs:
        SHR_SCREEN = $E12000
        kSHRSize = $8000

        jsr     InitSHR
        bit     packed_flag
    IF_NS
        jsr     LoadPackedSHR
    ELSE
        jsr     LoadUnpackedSHR
    END_IF
        copy16  #ExitSHR, exit_hook

        clc                     ; success
        rts

packed_flag:
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
        lda     #0              ; initialize first byte
        sta     SHR_SCREEN

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

        lda     #>.loword(SHR_SCREEN)
        sta     dest+1

loop:
        ;; Load data
        JUMP_TABLE_MLI_CALL READ, read_params

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
        dest := *+1             ; destination
        ldy     #.loword(SHR_SCREEN) ; high byte is self-modified
        lda     #kHiresSize-1        ; length-1
        mvn     #^hires, #^SHR_SCREEN
        plb                     ; restore data bank

        sec                     ; re-enter emulation mode
        xce
        .popcpu

        lda     dest+1
        clc
        adc     #>kHiresSize
        sta     dest+1
        cmp     #>(SHR_SCREEN+kSHRSize) ; done?
        bne     loop

        rts
.endproc ; LoadUnpackedSHR

        ;; --------------------------------------------------

.proc LoadPackedSHR

        lda     #<SHR_SCREEN
        sta     addr
        lda     #>SHR_SCREEN
        sta     addr+1
        lda     #^SHR_SCREEN
        sta     addr+2

        param_jump UnpackRead, write

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
    WHILE_POS

        ;; TODO: Keep this logic in sync with DeskTop's
        ;; `ICT_RECORD` definitions for graphics files.

        ;; Check file suffixes
        lda     entry+FileEntry::storage_type_name_length
        and     #NAME_LENGTH_MASK
        sta     entry+FileEntry::storage_type_name_length
        param_call check_suffix, str_a2fc_suffix
        jcc     yes
        param_call check_suffix, str_a2fm_suffix
        jcc     yes
        param_call check_suffix, str_a2lc_suffix
        jcc     yes
        param_call check_suffix, str_a2hr_suffix
        jcc     yes

        ;; File type
        lda     entry+FileEntry::file_type
        cmp     #FT_GRAPHICS
        jeq     yes

    IF_A_EQ     #FT_PNT
        ecmp16  entry+FileEntry::aux_type, #$0001
        jeq     yes
        jmp     no
    END_IF

    IF_A_EQ     #FT_PIC
        ecmp16  entry+FileEntry::aux_type, #$0000
        beq     yes
        bne     no              ; always
    END_IF

        cmp     #FT_BINARY
        bne     no

        ;; Binary: Must match size/address
        ecmp16  entry+FileEntry::blocks_used, #33
    IF_EQ
        ecmp16  entry+FileEntry::aux_type, #$2000
        beq     yes
        ecmp16  entry+FileEntry::aux_type, #$4000
        beq     yes
    END_IF

        ecmp16  entry+FileEntry::blocks_used, #17
    IF_EQ
        ecmp16  entry+FileEntry::aux_type, #$2000
        beq     yes
        ecmp16  entry+FileEntry::aux_type, #$4000
        beq     yes
    END_IF

        ecmp16  entry+FileEntry::blocks_used, #3
    IF_EQ
        ecmp16  entry+FileEntry::aux_type, #$5800
        beq     yes
    END_IF

no:     clc
        rts

yes:    sec
        rts

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
    WHILE_NOT_ZERO

no:     sec                     ; no match
        rts

yes:    clc                     ; match!
        rts

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

        copy8   #0, saw_header_flag

        ;; Open directory
        JUMP_TABLE_MLI_CALL OPEN, open_params
        jcs     exit

        lda     open_params_ref_num
        sta     read_params_ref_num
        sta     close_params_ref_num

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
        lda     saw_header_flag
    IF_ZERO
        inc     saw_header_flag
        bne     next_entry      ; always
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
        open_params_ref_num := open_params::ref_num
        read_params_ref_num := read_params::ref_num
        close_params_ref_num := close_params::ref_num

entry_in_block:
        .byte   0
saw_header_flag:
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
    WHILE_A_NE  #'/'
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
    WHILE_X_NE  INVOKE_PATH
        sty     cur_filename

        param_call EnumerateDirectory, callback

        ;; `first_filename` and `last_filename` are now populated,
        ;; along with maybe `prev_filename` and `next_filename`.
        ;; Based on `flags`, pick the right file to show.
        bit     flags
    IF_VS
      IF_NS
        ldax    #last_filename
      ELSE
        ldax    #first_filename
      END_IF
    ELSE_IF_NS
        lda     next_filename
      IF_NOT_ZERO
        ldax    #next_filename
      ELSE
        ldax    #first_filename
      END_IF
    ELSE
        lda     prev_filename
      IF_NOT_ZERO
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
        lda     (fnptr),y
        sta     dir_path,x
        len := *+1
        cpy     #SELF_MODIFIED_BYTE
    WHILE_NE
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
    WHILE_POS

        ;; First seen? might need it
        lda     first_filename
    IF_ZERO
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
    WHILE_NOT_ZERO

        lda     #$80
        sta     seen_flag
        rts

not_cur:
        ;; No, might be prev or next though

        ;; Seen the current file yet? If not, save it as previous
        bit     seen_flag
    IF_NC
        COPY_STRING last_filename, prev_filename
        rts
    END_IF

        ;; Yes... have we seen one after it? If not, save it as next
        lda     next_filename
    IF_ZERO
        COPY_STRING last_filename, next_filename
    END_IF

ret:    rts

tmp:    .addr   0
.endproc ; callback

flags:                          ; bit 6 = modified, bit 7 = advance
        .byte   0
seen_flag:
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
LZ4FH__in_src := LZ4FH::in_src
LZ4FH__in_dst := LZ4FH::in_dst

;;; ============================================================

        .assert * < minipix_src_buf, error, "buffer collision!"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
