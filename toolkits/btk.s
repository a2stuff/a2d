
;;; Routines dirty $06...$2F

.scope btk
        BTKEntry := *

        ;; Points at call parameters
        params_addr := $10

        ;; Cache of static fields from the record
        cache       := $12
        window_id   := cache + BTK::ButtonRecord::window_id
        a_label     := cache + BTK::ButtonRecord::a_label
        rect        := cache + BTK::ButtonRecord::rect
        state       := cache + BTK::ButtonRecord::state

        ;; Call parameters copied here (0...6 bytes)
        command_data = cache + .sizeof(BTK::ButtonRecord)

        ;; ButtonRecord address, in all param blocks
        a_record = command_data

.proc Dispatch

        ;; Adjust stack/stash at `params_addr`
        pla
        sta     params_addr
        clc
        adc     #<3
        tax
        pla
        sta     params_addr+1
        adc     #>3
        pha
        txa
        pha

        ;; Grab command number
        ldy     #1              ; Note: rts address is off-by-one
        lda     (params_addr),y
        pha                     ; A = command number
        asl     a
        tax
        copy16  jump_table,x, jump_addr

        ;; Point `params_addr` at actual params
        iny
        lda     (params_addr),y
        pha
        iny
        lda     (params_addr),y
        sta     params_addr+1
        pla
        sta     params_addr

        ;; Copy param data to `command_data`
        pla                       ; A = command number
        tay
        lda     length_table,y
        tay
        dey
:       copy    (params_addr),y, command_data,y
        dey
        bpl     :-

        ;; Cache static fields from the record, for convenience
        ldy     #.sizeof(BTK::ButtonRecord)-1
:       copy    (a_record),y, window_id,y
        dey
        bpl     :-

        jump_addr := *+1
        jmp     SELF_MODIFIED

jump_table:
        .addr   DrawImpl
        .addr   FlashImpl
        .addr   HiliteImpl
        .addr   TrackImpl

        ;; Must be non-zero
length_table:
        .byte   2               ; Draw
        .byte   2               ; Flash
        .byte   2               ; Hilite
        .byte   2               ; Track
.endproc

;;; ============================================================

penOR:  .byte   MGTK::penOR
penXOR: .byte   MGTK::penXOR
solid_pattern:
        .byte   $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
checkerboard_pattern:
        .byte   $55, $AA, $55, $AA, $55, $AA, $55, $AA

;;; ============================================================

.params getwinport_params
window_id:      .byte   0
port:           .addr   grafport_win
.endparams

grafport_win:   .tag    MGTK::GrafPort

.proc _SetPort
        ;; Set the port
        copy    window_id, getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured
        MGTK_CALL MGTK::SetPort, grafport_win
        rts
.endproc


;;; ============================================================

.proc DrawImpl
        PARAM_BLOCK params, btk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        jsr     _SetPort

        MGTK_CALL MGTK::SetPattern, solid_pattern
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, rect

        jmp     HiliteImpl__skip_port

.endproc ; DrawImpl


;;; ============================================================

.proc FlashImpl
        PARAM_BLOCK params, btk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        jsr     _SetPort

        jsr     _Invert
        FALL_THROUGH_TO _Invert
.endproc ; FlashImpl

.proc _Invert
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect
        rts
.endproc

;;; ============================================================

.proc HiliteImpl
        PARAM_BLOCK params, btk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        jsr     _SetPort
skip_port:

        pos := $06

        add16_8 rect+MGTK::Rect::x1, #kButtonTextHOffset, pos+MGTK::Point::xcoord
        ;; Y-offset from bottom for shorter-than-normal buttons, e.g. arrow glyphs
        sub16_8 rect+MGTK::Rect::y2, #(kButtonHeight - kButtonTextVOffset), pos+MGTK::Point::ycoord
        MGTK_CALL MGTK::MoveTo, pos

        ldax    a_label
        jsr     DrawString

        bit     state
    IF_NS
        inc16   rect+MGTK::Rect::x1
        inc16   rect+MGTK::Rect::y1
        dec16   rect+MGTK::Rect::x2
        dec16   rect+MGTK::Rect::y2

        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        MGTK_CALL MGTK::SetPenMode, penOR
        MGTK_CALL MGTK::PaintRect, rect
    END_IF

        rts
.endproc ; HiliteImpl
HiliteImpl__skip_port := HiliteImpl::skip_port

;;; ============================================================

.params event_params
kind := * + 0
        ;; if `kind` is key_down
key := * + 1
modifiers := * + 2
        ;; if `kind` is no_event, button_down/up, drag, or apple_key:
coords := * + 1
xcoord := * + 1
ycoord := * + 3
        ;; if `kind` is update:
window_id := * + 1
.endparams
.params screentowindow_params
window_id := * + 0
screen  := * + 1
screenx := * + 1
screeny := * + 3
window  := * + 5
windowx := * + 5
windowy := * + 7
        .assert screenx = event_params::xcoord, error, "param mismatch"
        .assert screeny = event_params::ycoord, error, "param mismatch"
.endproc
        .res    9

.proc TrackImpl
        PARAM_BLOCK params, btk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        jsr     _SetPort

        ;; Initial state
        copy    #0, down_flag

        ;; Do initial inversion
        jsr     _Invert

        ;; Event loop
loop:   MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_up
        beq     exit
        copy    window_id, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, rect
        cmp     #MGTK::inrect_inside
        beq     inside
        lda     down_flag       ; outside but was inside?
        beq     toggle
        bne     loop            ; always

inside: lda     down_flag       ; already depressed?
        beq     loop

toggle: jsr     _Invert
        lda     down_flag
        eor     #$80
        sta     down_flag
        jmp     loop

exit:   lda     down_flag       ; was depressed?
        bne     :+
        jsr     _Invert
:       lda     down_flag
        rts

        ;; --------------------------------------------------

down_flag:
        .byte   0


.endproc ; TrackImpl


;;; ============================================================

.endscope
