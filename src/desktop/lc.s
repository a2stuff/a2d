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
        pha
        txa
        pha

        ;; Copy the params here
        ldy     #3              ; ptr is off by 1
    DO
        copy8   (params_src),y, params-1,y
        dey
    WHILE_NOT_ZERO

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
        ldax    #MGTKAuxEntry
        jmp     ParamsRelayImpl
.endproc ; MGTKRelayImpl

;;; ============================================================
;;; IconTK call from main>aux, MLI-style params

.proc ITKRelayImpl
        ldax    #aux::ITKEntry
        jmp     ParamsRelayImpl
.endproc ; ITKRelayImpl

;;; ============================================================
;;; LineEditTK call from main>aux, MLI-style params

.proc LETKRelayImpl
        ldax    #aux::letk::LETKEntry
        jmp     ParamsRelayImpl
.endproc ; LETKRelayImpl


;;; ============================================================
;;; ButtonTK call from main>aux, MLI-style params

.proc BTKRelayImpl
        ldax    #aux::btk::BTKEntry
        jmp     ParamsRelayImpl
.endproc ; BTKRelayImpl


;;; ============================================================
;;; ListBoxTK call from main>aux, MLI-style params

.proc LBTKRelayImpl
        ldax    #aux::lbtk::LBTKEntry
        jmp     ParamsRelayImpl
.endproc ; LBTKRelayImpl

;;; ============================================================
;;; OptionPickerTK call from main>aux, MLI-style params

.proc OPTKRelayImpl
        ldax    #aux::optk::OPTKEntry
        jmp     ParamsRelayImpl
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
    WHILE_POS

        ;; Determine if the update's maprect is already below the header; if
        ;; not, we need to offset the maprect below the header to prevent
        ;; icons from drawing over the header when vertically scrolled.
        sub16   desktop_grafport+MGTK::GrafPort::viewloc+MGTK::Point::ycoord, window_grafport+MGTK::GrafPort::viewloc+MGTK::Point::ycoord, tmpw
        scmp16  tmpw, #kWindowHeaderHeight
    IF_NEG
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
        ldx     #$00
        FALL_THROUGH_TO ShowAlertOption
.endproc ; ShowAlert

;;; A=alert number, X=custom options
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
        param_call aux::Alert, alert_params
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
    WHILE_NOT_ZERO

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
    WHILE_POS

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

;;; From main, concatenate aux-visible string to `text_input_buf`
;;; Assert: Main is banked in
.proc AppendToTextInputBuf
        jsr     BankInAux
        jsr     PushPointers
        ptr := $06
        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     len
        iny
        ldx     text_input_buf
        inx
    DO
        copy8   (ptr),y, text_input_buf,x
        len := *+1
        cpy     #SELF_MODIFIED_BYTE
        BREAK_IF_EQ
        inx
        iny
    WHILE_NOT_ZERO              ; always
        stx     text_input_buf

        jsr     PopPointers
        jmp     BankInMain
.endproc ; AppendToTextInputBuf

;;; ============================================================

        .include "res.s"

        ENDSEG SegmentDeskTopLC
