;;; ============================================================
;;; DeskTop - "Language Card" Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into AUX $D000-$D1FF
;;; ============================================================

        BEGINSEG SegmentDeskTopLC

;;; ============================================================
;;; Exported entry points for main>aux and aux>main calls

ASSERT_EQUALS *, CallMainToAux, "entry point"
.proc CallMainToAuxImpl
        stax    call_addr
        jsr     BankInAux
        call_addr := *+1
        jsr     SELF_MODIFIED
        jmp     BankInMain
.endproc ; CallMainToAuxImpl

ASSERT_EQUALS *, CallAuxToMain, "entry point"
.proc CallAuxToMainImpl
        stax    call_addr
        jsr     BankInMain
        call_addr := *+1
        jsr     SELF_MODIFIED
        jmp     BankInAux
.endproc ; CallAuxToMainImpl

ASSERT_EQUALS *, ReadSettingFromAux, "entry point"
.proc ReadSettingFromAuxImpl
        jsr     BankInMain
        jsr     ReadSetting
        jmp     BankInAux
.endproc ; ReadSettingFromAuxImpl

ASSERT_EQUALS *, WriteSettingFromAux, "entry point"
.proc WriteSettingFromAuxImpl
        jsr     BankInMain
        jsr     WriteSetting
        jmp     BankInAux
.endproc ; WriteSettingFromAuxImpl

;;; ============================================================
;;; Common code for main>aux relays with MLI-style params
;;; Inputs: A,X = target address
;;; Uses $7E/$7F

.proc ParamsRelayImpl
        params_src := $7E
        stax    call_addr

        ;; Adjust return address on stack, compute
        ;; original params address.
        pla
        sta     params_src
        clc
        adc     #<3
        tax
        pla
        sta     params_src+1
        adc     #>3
        phax

        ;; Copy the params here
        ldy     #3              ; ptr is off by 1
    DO
        copy8   (params_src),y, params-1,y
        dey
    WHILE NOT_ZERO

        ;; Bank and call
        jsr     BankInAux
call_addr := * + 1
        jsr     SELF_MODIFIED
params: .res    3
        jmp     BankInMain
.endproc ; ParamsRelayImpl

;;; ============================================================
;;; MGTK call from main>aux, MLI-style params

.proc MGTKRelayImpl
        TAIL_CALL ParamsRelayImpl, AX=#MGTKAuxEntry
.endproc ; MGTKRelayImpl

;;; ============================================================
;;; IconTK call from main>aux, MLI-style params

.proc ITKRelayImpl
        TAIL_CALL ParamsRelayImpl, AX=#aux::ITKEntry
.endproc ; ITKRelayImpl

;;; ============================================================
;;; LineEditTK call from main>aux, MLI-style params

.proc LETKRelayImpl
        TAIL_CALL ParamsRelayImpl, AX=#aux::letk::LETKEntry
.endproc ; LETKRelayImpl


;;; ============================================================
;;; ButtonTK call from main>aux, MLI-style params

.proc BTKRelayImpl
        TAIL_CALL ParamsRelayImpl, AX=#aux::btk::BTKEntry
.endproc ; BTKRelayImpl


;;; ============================================================
;;; ListBoxTK call from main>aux, MLI-style params

.proc LBTKRelayImpl
        TAIL_CALL ParamsRelayImpl, AX=#aux::lbtk::LBTKEntry
.endproc ; LBTKRelayImpl

;;; ============================================================
;;; OptionPickerTK call from main>aux, MLI-style params

.proc OPTKRelayImpl
        TAIL_CALL ParamsRelayImpl, AX=#aux::optk::OPTKEntry
.endproc ; OPTKRelayImpl


;;; ============================================================
;;; Within an update event, adjust the update port of a window after
;;; the header has been drawn, if needed, so that the window contents
;;; are appropriately clipped.
;;;
;;; Assert: Within a `BeginUpdate`...`EndUpdate` sequence with port set
;;; Assert: `window_grafport` is set to window's raw port

.proc AdjustUpdatePortForEntries
        port_ptr := $06
        tmpw := $08

        jsr     BankInAux
        MGTKEntry := aux::MGTKEntry
        MGTK_CALL MGTK::GetPort, port_ptr

        ;; Copy somewhere easier to work with
        ldy     #.sizeof(MGTK::GrafPort)-1
    DO
        copy8   (port_ptr),y, desktop_grafport,y
        dey
    WHILE POS

        ;; Determine if the update's maprect is already below the header; if
        ;; not, we need to offset the maprect below the header to prevent
        ;; icons from drawing over the header when vertically scrolled.
        sub16   desktop_grafport+MGTK::GrafPort::viewloc+MGTK::Point::ycoord, window_grafport+MGTK::GrafPort::viewloc+MGTK::Point::ycoord, tmpw
        scmp16  tmpw, #kWindowHeaderHeight
    IF NEG
        ;; Adjust grafport to account for header
        add16   window_grafport+MGTK::GrafPort::viewloc+MGTK::Point::ycoord, #kWindowHeaderHeight, desktop_grafport+MGTK::GrafPort::viewloc+MGTK::Point::ycoord
        add16   window_grafport+MGTK::GrafPort::maprect+MGTK::Rect::y1, #kWindowHeaderHeight, desktop_grafport+MGTK::GrafPort::maprect+MGTK::Rect::y1

        MGTK_CALL MGTK::SetPort, desktop_grafport
    END_IF

        jmp     BankInMain
.endproc ; AdjustUpdatePortForEntries

;;; ============================================================
;;; From MAIN, load AUX (A,X) into A
;;; Assert: Main is banked in

.proc AuxLoad
        stax    op+1
        sta     RAMRDON
op:     lda     SELF_MODIFIED
        sta     RAMRDOFF
        rts
.endproc ; AuxLoad

;;; ============================================================
;;; From MAIN, show alert
;;; Assert: Main is banked in

;;; A=alert number, with default options
.proc ShowAlert
        ldx     #kShowAlertUseDefaultOptionsForId
        FALL_THROUGH_TO ShowAlertOption
.endproc ; ShowAlert

;;; A=alert number, X=`AlertButtonOptions::*`
.proc ShowAlertOption
        jsr     BankInAux
        jsr     aux::AlertById
        jmp     BankInMain
.endproc ; ShowAlertOption

;;; A,X = string
;;; Y = `AlertButtonOptions`
.proc ShowAlertParams
        jsr     BankInAux
        stax    alert_params+AlertParams::text
        sty     alert_params+AlertParams::buttons
        copy8   #AlertOptions::Beep|AlertOptions::SaveBack, alert_params+AlertParams::options
        CALL    aux::Alert, AX=#alert_params
        jmp     BankInMain
.endproc ; ShowAlertParams

;;; A,X = `AlertParams` struct
.proc ShowAlertStruct
        jsr     BankInAux
        jsr     aux::Alert
        jmp     BankInMain
.endproc ; ShowAlertStruct

;;; ============================================================
;;; Bell
;;; Assert: Aux is banked in

.proc BellFromAux
        jsr     BankInMain
        jsr     Bell
        jmp     BankInAux
.endproc ; BellFromAux

;;; ============================================================
;;; Yield from a nested event loop, for periodic tasks.
;;; Assert: Aux is banked in

.proc SystemTaskFromAux
        jsr     BankInMain
        jsr     SystemTask
        jmp     BankInAux
.endproc ; SystemTaskFromAux

;;; ============================================================
;;; Helpers for banking in Aux/Main $200-$BFFF.
;;; (These save 3 bytes per call.)

.proc BankInAux
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc ; BankInAux

.proc BankInMain
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc ; BankInMain

;;; ============================================================
;;; Pushes two words from $6/$8 to stack; preserves A,X,Y

.proc PushPointers
        ;; Stash A,X
        sta     a_save
        stx     x_save

        ;; Stash return address
        pla
        sta     lo
        pla
        sta     hi

        ;; Copy 4 bytes from $8 to stack
        ldx     #AS_BYTE(-4)
    DO
        lda     $06 + 4,x
        pha
        inx
    WHILE NOT_ZERO

        ;; Restore return address
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        ;; Restore A,X
        x_save := *+1
        ldx     #SELF_MODIFIED_BYTE
        a_save := *+1
        lda     #SELF_MODIFIED_BYTE

        rts
.endproc ; PushPointers

;;; ============================================================
;;; Pops two words from stack to $6/$8; preserves A,X,Y

.proc PopPointers
        ;; Stash A,X
        sta     a_save
        stx     x_save

        ;; Stash return address
        pla
        sta     lo
        pla
        sta     hi

        ;; Copy 4 bytes from stack to $6
        ldx     #3
    DO
        pla
        sta     $06,x
        dex
    WHILE POS

        ;; Restore return address to stack
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        ;; Restore A,X
        x_save := *+1
        ldx     #SELF_MODIFIED_BYTE
        a_save := *+1
        lda     #SELF_MODIFIED_BYTE

        rts
.endproc ; PopPointers

;;; ============================================================

;;; Write formatted data to a string.
;;;
;;; Called MLI style:
;;;     jsr FormatMessage
;;;     .byte argument_count
;;;     .addr format_string
;;;
;;; Use the `FORMAT_MESSAGE` macro:
;;;
;;;     FORMAT_MESSAGE argument_count, format_string
;;;
;;; The format string must be aux-visible.
;;;
;;; Output: `text_input_buf` has the resulting string.
;;;
;;; Message format is a length-prefixed string with percent sequences
;;; of the form %<index><type>. Indexes start at 0.
;;;
;;; Types:
;;;    d - decimal, positive integer, no separators, e.g. "12345"
;;;    n - number, positive integer, separators, e.g. "12,456"
;;;    k - size, from block count, in K, e.g. "8.5K"
;;;    x - hex, hexadecimal word, e.g. "EF12"
;;;    s - string (in main memory)
;;;    c - character (in low byte of argument; high byte is ignored)
;;;    otherwise a literal, e.g. %%
;;;
;;; Example: "Copying %0n files to %1s; %2d%% complete."
;;;
;;; Note that this is different than printf() which processes the
;;; arguments in order encountered in the string; this is intentional
;;; to support localization where the order of items in the string
;;; could change.
;;;
;;; Trashes $06, $08

.proc FormatMessage
        out_buf := text_input_buf

;;; format string assumed to be in aux

        in_ptr  := $06
        arg_ptr := $08

;;; stack on entry; stack grows downwards from $1FF
;;;     ...

;;; $200
;;;     ...
;;;     arg_0_lo  <-- start of arguments / `stack_offset`
;;;     arg_0_hi
;;;     arg_1_lo
;;;     arg_1_hi
;;;     ...
;;;     arg_N_lo
;;;     arg_N_hi  <-- end of arguments
;;;     rts_hi
;;;     rts_lo    <-- stack pointer on entry
;;;     ...
;;; $100

        ;; Adjust stack/stash
        pla
        sta     arg_ptr
        clc
        adc     #<3
        sta     rts_lo
        pla
        sta     arg_ptr+1
        adc     #>3
        sta     rts_hi

        ;; Get args
        ldy     #1              ; Note: rts address is off-by-one
        lda     (arg_ptr),y
        pha                     ; A = arg count
        iny
        lda     (arg_ptr),y
        sta     in_ptr
        iny
        lda     (arg_ptr),y
        sta     in_ptr+1
        pla                     ; A = arg count
        tay

        ;; Get pointer to start of arguments
        tsx
   DO
        inx
        inx
        dey
   WHILE NOT_ZERO
        stx     stack_offset

        ;; Loop over string
        ldx     #0
        stx     out_buf         ; initial length is 0
        dex
        stx     in_pos          ; `read_byte` pre-increments

        jsr     read_byte
        sta     len

        ;; Loop over all bytes in pattern string
    DO
        jsr     read_byte

      IF A = #'%'
        ;; escape sequence: "%<index><type>"

        ;; Get argument index, translate to stack ptr:
        ;; Y = `stack_offset` - (index * 2)
        jsr     read_byte       ; index
        and     #%00001111      ; ASCII to digit
        asl                     ; index * 2
        eor     #$FF            ; negate; usually this is: CLC; ADC #1
        sec                     ; but we're about to ADC anyway so
        adc     stack_offset    ; add 1 via the SEC
        tay

        ;; Read the actual argument, stash on stack
        lda     $100,y          ; lo
        pha
        lda     $100-1,y        ; hi
        pha

        ;; Get type
        jsr     read_byte       ; type
        tay

        ;; Pull argument value off stack
        plax

        ;; Now Y = type, A,X = argument
       IF Y = #'d'              ; decimal - decimal integer
        jsr     IntToString
        TAIL_CALL _AppendString, AX=#str_from_int
       END_IF

       IF Y = #'n'              ; number - decimal integer with separators
        jsr     IntToStringWithSeparators
        TAIL_CALL _AppendString, AX=#str_from_int
       END_IF

       IF Y = #'k'              ; size - in K from blocks
        jsr     PushPointers
        jsr     ComposeSizeString
        jsr     PopPointers
        TAIL_CALL _AppendString, AX=#text_buffer2
       END_IF

       IF Y = #'x'              ; hex - hexadecimal word
        jsr     _AppendHex
        jmp     resume
       END_IF

       IF Y = #'s'              ; string pointer
        jmp     _AppendString
       END_IF

        ;; If 'c', char in A is written, X is ignored
       IF Y <> #'c'             ; char
        ;; Otherwise, so treat as literal (e.g. "%%")
        tya
       END_IF
      END_IF

        jsr     _WriteByte

resume:
        len := *+1
        lda     #SELF_MODIFIED_BYTE
    WHILE A <> in_pos

        ;; Adjust stack
        stack_offset := *+1
        ldx     #SELF_MODIFIED_BYTE
        txs

        ;; Restore return address
        rts_hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        rts_lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        rts

;;; Preserves X
read_byte:
        jsr     BankInAux
        inc     in_pos
        in_pos := *+1
        ldy     #SELF_MODIFIED_BYTE
        lda     (in_ptr),y
        jsr     BankInMain
        rts

;;; Preserves X
.proc _WriteByte
        inc     out_buf
        ldy     out_buf
        sta     out_buf,y
        rts
.endproc ; _WriteByte

.proc _AppendString
        stax    arg_ptr
        ldy     #0
        lda     (arg_ptr),y
        beq     resume

        tax                     ; X = len
    DO
        iny                     ; Y = index
        tya
        pha
        lda     (arg_ptr),y
        jsr     _WriteByte      ; preserves X
        pla
        tay                     ; Y = index
        dex
    WHILE NOT_ZERO
        beq     resume          ; always
.endproc ; _AppendString

.proc _AppendHex
        pha
        txa
        jsr     do_byte
        pla
        FALL_THROUGH_TO do_byte

do_byte:
        pha
        lsr
        lsr
        lsr
        lsr
        jsr     do_nibble
        pla
        FALL_THROUGH_TO do_nibble

do_nibble:
        and     #%00001111
        sed                     ; BCD Hex to ASCII trick c/o Lee Davison
        cmp     #10             ; >= 10?
        adc     #'0'            ; +$30 (i.e. '0') if < 10, +$40 (i.e. 'A') -10 if >= 10
        cld
        jmp     _WriteByte
.endproc ; _AppendHex

.endproc ; FormatMessage

;;; ============================================================

        .include "res.s"

        ENDSEG SegmentDeskTopLC
