        .include "../config.inc"

        .include "apple2.inc"
        .include "opcodes.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry

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
;;;  $1580   +-----------+ +-----------+
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           | DA is copied to AUX for MGTK param blocks
;;;          | DA        | | DA (Copy) |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

        hires   := $2000        ; HR/DHR images are loaded directly into screen buffer
        kHiresSize = $2000

        ;; Minipix/Print Shop images are loaded/converted
        minipix_src_buf := $1580 ; Load address (main)
        kMinipixSrcSize = 576
        minipix_dst_buf := $1580 ; Convert address (aux)
        kMinipixDstSize = 26*52

        .assert (minipix_src_buf + kMinipixSrcSize) < DA_IO_BUFFER, error, "Not enough room for Minipix load buffer"
        .assert (minipix_dst_buf + kMinipixDstSize) < DA_IO_BUFFER, error, "Not enough room for Minipix convert buffer"

;;; ============================================================

        .org DA_LOAD_ADDRESS

da_start:
        jmp     Start

save_stack:
        .byte   0

.proc Start
        tsx
        stx     save_stack

        ;; Copy DA to AUX (for resources)
        copy16  #da_start, STARTLO
        copy16  #da_start, DESTINATIONLO
        copy16  #da_end, ENDLO
        sec                     ; main>aux
        jsr     AUXMOVE

        ;; run the DA
        jsr     Init

        ldx     save_stack
        txs

        rts
.endproc

;;; ============================================================
;;; ProDOS MLI param blocks

        DEFINE_OPEN_PARAMS open_params, pathbuf, DA_IO_BUFFER
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, pathbuf
        DEFINE_GET_EOF_PARAMS get_eof_params

        DEFINE_READ_PARAMS read_params, hires, kHiresSize
        DEFINE_READ_PARAMS read_minipix_params, minipix_src_buf, kMinipixSrcSize

        DEFINE_CLOSE_PARAMS close_params

pathbuf:        .res    kPathBufferSize, 0

;;; ============================================================

event_params:   .tag MGTK::Event


;;; ============================================================

.proc CopyEventAuxToMain
        copy16  #event_params, STARTLO
        copy16  #event_params + .sizeof(MGTK::Event) - 1, ENDLO
        copy16  #event_params, DESTINATIONLO
        clc                     ; aux > main
        jmp     AUXMOVE
.endproc

;;; ============================================================


.proc Init
        copy    #0, mode

        INVOKE_PATH := $220
        lda     INVOKE_PATH
    IF_EQ
        rts
    END_IF
        COPY_STRING     INVOKE_PATH, pathbuf

        JUMP_TABLE_MLI_CALL OPEN, open_params
        lda     open_params::ref_num
        sta     get_eof_params::ref_num
        sta     read_params::ref_num
        sta     read_minipix_params::ref_num
        sta     close_params::ref_num

        JUMP_TABLE_MGTK_CALL MGTK::HideCursor
        jsr     ClearScreen
        jsr     SetColorMode
        jsr     ShowFile
        JUMP_TABLE_MGTK_CALL MGTK::ShowCursor

        JUMP_TABLE_MGTK_CALL MGTK::FlushEvents
        JUMP_TABLE_MGTK_CALL MGTK::ObscureCursor

        FALL_THROUGH_TO InputLoop
.endproc

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
        JUMP_TABLE_MGTK_CALL MGTK::GetEvent, event_params
        jsr     CopyEventAuxToMain

        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     exit
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     on_key
        bne     InputLoop

on_key:
        lda     event_params + MGTK::Event::modifiers
        bne     InputLoop
        lda     event_params + MGTK::Event::key
        cmp     #CHAR_ESCAPE
        beq     exit
        cmp     #CHAR_RETURN
        beq     exit
        cmp     #' '
        bne     :+
        jsr     ToggleMode
:       jmp     InputLoop

exit:
        jsr     JUMP_TABLE_RGB_MODE

        ;; Restore desktop and menu
        JUMP_TABLE_MGTK_CALL MGTK::RedrawDeskTop
        JUMP_TABLE_MGTK_CALL MGTK::DrawMenu
        jsr     JUMP_TABLE_HILITE_MENU

        rts                     ; exits input loop
.endproc

.proc ShowFile
        ;; Check file type
        JUMP_TABLE_MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
fail:   rts

:       lda     get_file_info_params::file_type
        cmp     #FT_GRAPHICS
        bne     get_eof

        ;; FOT files - auxtype $4000 / $4001 are packed hires/double-hires
        lda     get_file_info_params::aux_type+1
        cmp     #$40
        bne     ShowFOTFile

        lda     get_file_info_params::aux_type
        cmp     #$00
        bne     :+
        jmp     ShowPackedHRFile
:       cmp     #$01
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
        bcc     :+
        jmp     ShowDHRFile

        ;; If bigger than 576, assume HR

:       cmp16   get_eof_params::eof, #kMinipixSrcSize+1
        jcs     ShowHRFile

        ;; Otherwise, assume Minipix

        jmp     ShowMinipixFile
.endproc

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

finish: JUMP_TABLE_MLI_CALL CLOSE, close_params

        lda     signature
        and     #kSigColor
        bne     :+
        jsr     SetBWMode
:       rts

signature:
        .byte   0
.endproc


.proc ShowHRFile
        sta     PAGE2OFF
        JUMP_TABLE_MLI_CALL READ, read_params
        JUMP_TABLE_MLI_CALL CLOSE, close_params

        jmp     HRToDHR
.endproc

.proc ShowDHRFile
        ptr := $06

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
        JUMP_TABLE_MLI_CALL CLOSE, close_params

        rts
.endproc

.proc CopyHiresToAux
        ptr := $06

        sta     CLR80STORE
        sta     RAMWRTON

        copy16  #hires, ptr
        ldx     #>kHiresSize    ; number of pages to copy
        ldy     #0
:       lda     (ptr),y
        sta     (ptr),y
        iny
        bne     :-
        inc     ptr+1
        dex
        bne     :-

        sta     SET80STORE
        sta     RAMWRTOFF
        rts
.endproc


.proc ShowMinipixFile
        jsr     SetBWMode

        ;; Load file at minipix_src_buf (MAIN $1800)
        JUMP_TABLE_MLI_CALL READ, read_minipix_params
        JUMP_TABLE_MLI_CALL CLOSE, close_params

        ;; Convert (main to aux)
        jsr     ConvertMinipixToBitmap

        ;; Draw
        JUMP_TABLE_MGTK_CALL MGTK::InitPort, grafport
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, grafport
        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, notpencopy
        JUMP_TABLE_MGTK_CALL MGTK::PaintBits, paintbits_params

        rts

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

.endproc



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
        copy    hires_table_lo,x, ptr
        copy    hires_table_hi,x, ptr+1

        ldy     #kCols-1         ; col

        copy    #0, spill       ; spill-over

cloop:  lda     (ptr),y
        tax

        bmi     hibitset

        ;; complex case - need to spill in bit from prev col and store

        lda     hr_to_dhr_aux,x
        sta     PAGE2ON
        sta     (ptr),y
        lda     hr_to_dhr_main,x
        ora     spill           ; apply previous spill bit (to bit 6)
        sta     PAGE2OFF
        sta     (ptr),y

        ror                     ; move high bit to bit 6
        and     #(1 << 6)
        sta     spill

        jmp     next

hibitset:
        ;; simple case - no bit spillage
        lda     hr_to_dhr_aux,x
        sta     PAGE2ON
        sta     (ptr),y
        lda     hr_to_dhr_main,x
        sta     PAGE2OFF
        sta     (ptr),y

        copy    #0, spill       ; no spill bit
next:
        dey
        bpl     cloop

        pla
        clc
        adc     #1
        cmp     #kRows
        bne     rloop

done:   rts
.endproc

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
:       jsr     GetBit
        jsr     PutBit2
        dex
        bne     :-

        ;; We've written out 88*2 bits = 176 bits.  This means 1 bit was shifted into
        ;; the last bit.  We need to get it from the MSB to the LSB, so it needs
        ;; to be shifted down 7 bits
:       clc
        jsr     PutBit1
        dex
        cpx     #AS_BYTE(-7)    ; do 7 times == 7 bits
        bne     :-

        dec     row
        bne     dorow

        rts

.proc GetBit
        lda     (src),y
        rol
        sta     (src),y
        dec     srcbit
        bne     done

        inc     src
        bne     :+
        inc     src+1
:       lda     #8
        sta     srcbit

done:   rts
.endproc

.proc PutBit2
        php
        jsr     PutBit1
        plp
        FALL_THROUGH_TO PutBit1
.endproc
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
        inc     dst
        bne     :+
        inc     dst+1
:       lda     #7
        sta     dstbit

done:
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

.endproc

;;; ============================================================
;;; Color/B&W Toggle

mode:   .byte   0               ; 0 = B&W, $80 = color

.proc ToggleMode
        lda     mode
        bne     SetBWMode
        FALL_THROUGH_TO SetColorMode
.endproc

.proc SetColorMode
        lda     mode
        bne     done
        copy    #$80, mode

        jsr     JUMP_TABLE_COLOR_MODE

done:   rts
.endproc

.proc SetBWMode
        lda     mode
        beq     done
        copy    #0, mode

        jsr     JUMP_TABLE_MONO_MODE

done:   rts
.endproc

;;; ============================================================

.proc UnpackRead
        DEFINE_READ_PARAMS read_buf_params, read_buf, 0

        ptr := $06

dhr_file:
        lda     #$C0            ; S = is dhr?, V = is aux page?
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
hr_file:
        lda     #0
        sta     dhr_flag

        copy16  #hires, ptr

        sta     PAGE2OFF

        copy    open_params::ref_num, read_buf_params::ref_num

        ;; Read next op/count byte
loop:   copy    #1, read_buf_params::request_count
        JUMP_TABLE_MLI_CALL READ, read_buf_params
        bcc     body

        ;; EOF (or other error) - finish up
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        bit     dhr_flag        ; if hires, need to convert
        bmi     :+
        jsr     HRToDHR
:       rts

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

        copy    count, read_buf_params::request_count
        JUMP_TABLE_MLI_CALL READ, read_buf_params
        ldy     #0

        ldx     #0
:       lda     read_buf,x
        jsr     Write
        inx
        cpx     count
        bne     :-

        jmp     loop

        ;; --------------------------------------------------

not_00: cmp     #%01000000
        bne     not_01

        ;; --------------------------------------------------
        ;; %01...... = 3, 5, 6, or 7 repeats of next byte

        copy    #1, read_buf_params::request_count
        JUMP_TABLE_MLI_CALL READ, read_buf_params
        ldy     #0
        lda     read_buf

:       jsr     Write
        dec     count
        bne     :-

        jmp     loop

        ;; --------------------------------------------------

not_01: cmp     #%10000000
        bne     not_10

        ;; --------------------------------------------------
        ;; %10...... = 1 to 64 repeats of next 4 bytes

        copy    #4, read_buf_params::request_count
        JUMP_TABLE_MLI_CALL READ, read_buf_params
        ldy     #0

:       lda     read_buf+0
        jsr     Write
        lda     read_buf+1
        jsr     Write
        lda     read_buf+2
        jsr     Write
        lda     read_buf+3
        jsr     Write
        dec     count
        bne     :-

        jmp     loop

        ;; --------------------------------------------------

not_10:
        ;; --------------------------------------------------
        ;; %11...... = 1 to 64 repeats of next byte taken as 4 bytes

        copy    #1, read_buf_params::request_count
        JUMP_TABLE_MLI_CALL READ, read_buf_params
        ldy     #0
        lda     read_buf

:       jsr     Write
        jsr     Write
        jsr     Write
        jsr     Write
        dec     count
        bne     :-

        jmp     loop

        ;; --------------------------------------------------

.proc Write
        ;; ASSERT: Y=0
        sta     (ptr),y
        inc     ptr
        beq     :+
        rts

:       pha

        inc     ptr+1
        lda     ptr+1
        cmp     #$40            ; did we hit page 2?
        bne     exit
        lda     #$20            ; yes, back to page 1
        sta     ptr+1

        bit     dhr_flag        ; if DHR aux half, need to copy page to aux
        bvc     exit            ; nope
        copy    #$80, dhr_flag

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
.endproc

        ;; --------------------------------------------------

dhr_flag:
        .byte   0

count:  .byte   0

read_buf:
        .res    64

.endproc
ShowPackedHRFile     := UnpackRead::hr_file
ShowPackedDHRFile    := UnpackRead::dhr_file

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
:       sta     (ptr),y
        iny
        bne     :-
        inc     ptr+1
        dex
        bne     :-
        rts

done:
.endproc

;;; ============================================================

        .include "../inc/hires_table.inc"
        .include "inc/hr_to_dhr.inc"

;;; ============================================================

da_end:
