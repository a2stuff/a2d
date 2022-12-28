
;;; Routines dirty $06...$2F

.scope btk
        BTKEntry := *

        ;; Points at call parameters
        params_addr := $10

        ;; Cache of static fields from the record
        cache       := $12
        window_id   := cache + BTK::ButtonRecord::window_id
        a_label     := cache + BTK::ButtonRecord::a_label
        a_shortcut  := cache + BTK::ButtonRecord::a_shortcut
        rect        := cache + BTK::ButtonRecord::rect
        state       := cache + BTK::ButtonRecord::state

        ;; Call parameters copied here (0...6 bytes)
        command_data = cache + .sizeof(BTK::ButtonRecord)

        ;; ButtonRecord address, in all param blocks
        a_record = command_data
        update_flag = command_data + 2

        .assert BTKEntry = Dispatch, error, "dispatch addr"
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

        lda     #0
        sta     update_flag     ; default for most commands

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
.ifndef BTK_SHORT
        .addr   RadioDrawImpl
        .addr   RadioUpdateImpl
        .addr   CheckboxDrawImpl
        .addr   CheckboxUpdateImpl
.endif ; BTK_SHORT

        ;; Must be non-zero
length_table:
        .byte   3               ; Draw
        .byte   2               ; Flash
        .byte   2               ; Hilite
        .byte   2               ; Track
.ifndef BTK_SHORT
        .byte   2               ; RadioDraw
        .byte   2               ; RadioUpdate
        .byte   2               ; CheckboxDraw
        .byte   2               ; CheckboxUpdate
.endif ; BTK_SHORT
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
        bit     update_flag
        bmi     ret

        ;; Set the port
        copy    window_id, getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured
        MGTK_CALL MGTK::SetPort, grafport_win
ret:    rts
.endproc


;;; ============================================================

.proc DrawImpl
        PARAM_BLOCK params, btk::command_data
a_record  .addr
update    .byte
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"
        .assert update_flag = params::update, error, "param mismatch"

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

        pos := $0B

        add16_8 rect+MGTK::Rect::x1, #kButtonTextHOffset, pos+MGTK::Point::xcoord
        ;; Y-offset from bottom for shorter-than-normal buttons, e.g. arrow glyphs
        sub16_8 rect+MGTK::Rect::y2, #(kButtonHeight - kButtonTextVOffset), pos+MGTK::Point::ycoord
        MGTK_CALL MGTK::MoveTo, pos

        ;; Draw the string (left aligned)
        jsr     _DrawLabel

        ;; Draw the shortcut (if present, right aligned)
PARAM_BLOCK tw_params, $6
textptr .addr
textlen .byte
width   .word
END_PARAM_BLOCK
        lda     a_shortcut
        ora     a_shortcut+1
        beq     :+
        ldy     #0
        lda     (a_shortcut),y
        beq     :+
        sta     tw_params::textlen
        add16_8 a_shortcut, #1, tw_params::textptr
        MGTK_CALL MGTK::TextWidth, tw_params

        sub16_8 rect+MGTK::Rect::x2, #kButtonTextHOffset-2, pos+MGTK::Point::xcoord
        sub16   pos+MGTK::Point::xcoord, tw_params::width, pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, pos
        MGTK_CALL MGTK::DrawText, tw_params
:

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

;;; Input: `a_label` points at string
;;; Trashes $06..$08
.proc _DrawLabel
PARAM_BLOCK dt_params, $6
textptr .addr
textlen .byte
END_PARAM_BLOCK
        ldy     #0
        lda     (a_label),y
        beq     :+
        sta     dt_params::textlen
        add16_8 a_label, #1, dt_params::textptr
        MGTK_CALL MGTK::DrawText, dt_params
:       rts
.endproc

;;; Inputs: `a_label` points at string
;;; Output: A,X = width
;;; Trashes: $06..$0A
.proc _MeasureLabel
PARAM_BLOCK tw_params, $6
textptr .addr
textlen .byte
width   .word
END_PARAM_BLOCK
        ldy     #0
        lda     (a_label),y
        bne     :+
        lda     #0
        tax
        rts
:
        sta     tw_params::textlen
        add16_8 a_label, #1, tw_params::textptr
        MGTK_CALL MGTK::TextWidth, tw_params
        ldax    tw_params::width
        rts
.endproc

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

.ifndef BTK_SHORT
;;; ============================================================

;;; Padding between radio/checkbox and label
kLabelPadding = 5

kRadioButtonWidth       = 15
kRadioButtonHeight      = 7

.params rb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   SELF_MODIFIED
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kRadioButtonWidth, kRadioButtonHeight
.endparams

checked_rb_bitmap:
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%1110001),PX(%1110001),PX(%1100000)
        .byte   PX(%1100111),PX(%1111100),PX(%1100000)
        .byte   PX(%1100111),PX(%1111100),PX(%1100000)
        .byte   PX(%1110001),PX(%1110001),PX(%1100000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)

unchecked_rb_bitmap:
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%1110000),PX(%0000001),PX(%1100000)
        .byte   PX(%1100000),PX(%0000000),PX(%1100000)
        .byte   PX(%1100000),PX(%0000000),PX(%1100000)
        .byte   PX(%1110000),PX(%0000001),PX(%1100000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)

;;; ============================================================

.proc RadioDrawImpl
        PARAM_BLOCK params, btk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        jsr     _SetPort

        ;; Initial size is just the button
        add16_8 rect+MGTK::Rect::x1, #kRadioButtonWidth, rect+MGTK::Rect::x2
        add16_8 rect+MGTK::Rect::y1, #kRadioButtonHeight, rect+MGTK::Rect::y2

        ;; No label? skip
        lda     a_label
        ora     a_label+1
        beq     update_rect

        ;; Draw the label
        pos := $B
        add16_8 rect+MGTK::Rect::x1, #kLabelPadding + kRadioButtonWidth, pos+MGTK::Point::xcoord
        add16_8 rect+MGTK::Rect::y1, #kSystemFontHeight - 1, pos+MGTK::Point::ycoord
        MGTK_CALL MGTK::MoveTo, pos
        jsr     _DrawLabel

        ;; And measure it for hit testing
        jsr     _MeasureLabel
        addax   rect+MGTK::Rect::x2
        add16_8 rect+MGTK::Rect::x2, #kLabelPadding
        add16_8 rect+MGTK::Rect::y2, #kSystemFontHeight - kRadioButtonHeight

        ;; Write rect back to button record
update_rect:
        ldx     #.sizeof(MGTK::Rect)-1
        ldy     #BTK::ButtonRecord::rect + .sizeof(MGTK::Rect)-1
:       lda     rect,x
        sta     (a_record),y
        dey
        dex
        bpl     :-

        jmp     _DrawRadioBitmap
.endproc ; RadioDrawImpl

;;; ============================================================

.proc RadioUpdateImpl
        PARAM_BLOCK params, btk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        jsr     _SetPort

        FALL_THROUGH_TO _DrawRadioBitmap
.endproc ; RadioUpdateImpl

.proc _DrawRadioBitmap
        COPY_STRUCT MGTK::Point, rect+MGTK::Rect::topleft, rb_params::viewloc
        ldax    #unchecked_rb_bitmap
        bit     state
    IF_NS
        ldax    #checked_rb_bitmap
    END_IF
        stax    rb_params::mapbits

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintBitsHC, rb_params
        rts
.endproc

;;; ============================================================

kCheckboxWidth       = 17
kCheckboxHeight      = 8

.params cb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   SELF_MODIFIED
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCheckboxWidth, kCheckboxHeight
.endparams

checked_cb_bitmap:
        .byte   PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111000),PX(%0000000),PX(%1111000)
        .byte   PX(%1100110),PX(%0000011),PX(%0011000)
        .byte   PX(%1100001),PX(%1001100),PX(%0011000)
        .byte   PX(%1100000),PX(%0110000),PX(%0011000)
        .byte   PX(%1100001),PX(%1001100),PX(%0011000)
        .byte   PX(%1100110),PX(%0000011),PX(%0011000)
        .byte   PX(%1111000),PX(%0000000),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111000)

.params unchecked_cb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   unchecked_cb_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCheckboxWidth, kCheckboxHeight
.endparams

unchecked_cb_bitmap:
        .byte   PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0011000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111000)

;;; ============================================================

.proc CheckboxDrawImpl
        PARAM_BLOCK params, btk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        jsr     _SetPort

        ;; Initial size is just the button
        add16_8 rect+MGTK::Rect::x1, #kCheckboxWidth, rect+MGTK::Rect::x2
        add16_8 rect+MGTK::Rect::y1, #kCheckboxHeight, rect+MGTK::Rect::y2

        ;; No label? skip
        lda     a_label
        ora     a_label+1
        beq     update_rect

        ;; Draw the label
        pos := $B
        add16_8 rect+MGTK::Rect::x1, #kLabelPadding + kCheckboxWidth, pos+MGTK::Point::xcoord
        add16_8 rect+MGTK::Rect::y1, #kSystemFontHeight, pos+MGTK::Point::ycoord
        MGTK_CALL MGTK::MoveTo, pos
        jsr     _DrawLabel

        ;; And measure it for hit testing
        jsr     _MeasureLabel
        addax   rect+MGTK::Rect::x2
        add16_8 rect+MGTK::Rect::x2, #kLabelPadding
        add16_8 rect+MGTK::Rect::y2, #kSystemFontHeight - kCheckboxHeight

        ;; Write rect back to button record
update_rect:
        ldx     #.sizeof(MGTK::Rect)-1
        ldy     #BTK::ButtonRecord::rect + .sizeof(MGTK::Rect)-1
:       lda     rect,x
        sta     (a_record),y
        dey
        dex
        bpl     :-

        jmp     _DrawCheckboxBitmap
.endproc ; CheckboxDrawImpl

;;; ============================================================

.proc CheckboxUpdateImpl
        PARAM_BLOCK params, btk::command_data
a_record  .addr
        END_PARAM_BLOCK
        .assert a_record = params::a_record, error, "a_record must be first"

        jsr     _SetPort

        FALL_THROUGH_TO _DrawCheckboxBitmap
.endproc ; CheckboxUpdateImpl

.proc _DrawCheckboxBitmap
        COPY_STRUCT MGTK::Point, rect+MGTK::Rect::topleft, cb_params::viewloc
        ldax    #unchecked_cb_bitmap
        bit     state
    IF_NS
        ldax    #checked_cb_bitmap
    END_IF
        stax    cb_params::mapbits

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintBitsHC, cb_params
        rts
.endproc

;;; ============================================================
.endif ; BTK_SHORT

.endscope
