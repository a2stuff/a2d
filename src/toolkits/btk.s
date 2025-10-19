;;; ============================================================
;;; Button ToolKit
;;; ============================================================

.scope btk
        BTKEntry := *

;;; ============================================================
;;; Zero Page usage (saved/restored around calls)

        zp_start := $50
        ;; BTK doesn't have "command data" - just the button record
        kMaxTmpSpace = 10

PARAM_BLOCK, zp_start
;;; Points at call parameters (i.e. ButtonRecord)
params_addr     .addr

;;; A temporary copy of the control record
cache           .tag    BTK::ButtonRecord

;;; Used in `TrackImpl`
down_flag       .byte

zp_scratch      .res    kMaxTmpSpace

;;; For size calculation, not actually used
zp_end          .byte
END_PARAM_BLOCK

        .assert zp_end <= $78, error, "too big"
        kBytesToSave = zp_end - zp_start

        ;; Aliases for the cache's members:
        window_id   := cache + BTK::ButtonRecord::window_id
        a_label     := cache + BTK::ButtonRecord::a_label
        a_shortcut  := cache + BTK::ButtonRecord::a_shortcut
        rect        := cache + BTK::ButtonRecord::rect
        state       := cache + BTK::ButtonRecord::state

;;; ============================================================

        .assert BTKEntry = Dispatch, error, "dispatch addr"
.proc Dispatch
        ;; Adjust stack/stash
        pla
        sta     params_lo
        clc
        adc     #<3
        tax
        pla
        sta     params_hi
        adc     #>3
        phax

        ;; Save ZP
        PUSH_BYTES kBytesToSave, zp_start

        ;; Point `params_addr` at the call site
        params_lo := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     params_addr
        params_hi := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     params_addr+1

        ;; Grab command number
        ldy     #1              ; Note: rts address is off-by-one
        lda     (params_addr),y
        tax
        copylohi jump_table_lo,x, jump_table_hi,x, dispatch

        ;; Point `params_addr` at actual params
        iny
        lda     (params_addr),y
        tax
        iny
        lda     (params_addr),y
        sta     params_addr+1
        stx     params_addr

        ;; Cache static copy of the record in `cache`, for convenience
        ldy     #.sizeof(BTK::ButtonRecord)-1
:       copy8   (params_addr),y, cache,y
        dey
        bpl     :-

        ;; Invoke the command
        dispatch := *+1
        jsr     SELF_MODIFIED
        tay                     ; A = result

        ;; Restore ZP
        POP_BYTES kBytesToSave, zp_start

        tya                     ; A = result
        rts

jump_table_lo:
        .lobytes   DrawImpl
        .lobytes   UpdateImpl
        .lobytes   FlashImpl
        .lobytes   HiliteImpl
        .lobytes   TrackImpl
.ifndef BTK_SHORT
        .lobytes   RadioDrawImpl
        .lobytes   RadioUpdateImpl
        .lobytes   CheckboxDrawImpl
        .lobytes   CheckboxUpdateImpl
.endif ; BTK_SHORT

jump_table_hi:
        .hibytes   DrawImpl
        .hibytes   UpdateImpl
        .hibytes   FlashImpl
        .hibytes   HiliteImpl
        .hibytes   TrackImpl
.ifndef BTK_SHORT
        .hibytes   RadioDrawImpl
        .hibytes   RadioUpdateImpl
        .hibytes   CheckboxDrawImpl
        .hibytes   CheckboxUpdateImpl
.endif ; BTK_SHORT

        ASSERT_EQUALS *-jump_table_hi, jump_table_hi-jump_table_lo
.endproc ; Dispatch

;;; ============================================================

penOR:  .byte   MGTK::penOR
penXOR: .byte   MGTK::penXOR
solid_pattern:
        .byte   $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
checkerboard_pattern:
        .byte   $55, $AA, $55, $AA, $55, $AA, $55, $AA

.params shrink_rect
        .addr   rect
        .word   AS_WORD(-1), AS_WORD(-1)
.endparams

.params grow_rect
        .addr   rect
        .word   1, 1
.endparams

;;; ============================================================

;;; Shadows params in Selector's `app` and Disk Copy's `auxlc` scopes.
;;; TODO: Rework scoping to eliminate this.
SUPPRESS_SHADOW_WARNING
.params getwinport_params
window_id:      .byte   0
port:           .addr   grafport_win
.endparams
UNSUPPRESS_SHADOW_WARNING

grafport_win:   .tag    MGTK::GrafPort

;;; If obscured, execution will not return to the caller.
.proc _SetPort
        ;; Set the port
        lda     window_id
        beq     ret
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     obscured
        MGTK_CALL MGTK::SetPort, grafport_win
        beq     ret

obscured:
        pla
        pla
ret:
        rts
.endproc ; _SetPort

;;; ============================================================

.proc DrawImpl
        jsr     _SetPort

        FALL_THROUGH_TO UpdateImpl
.endproc ; DrawImpl


;;; ============================================================

.proc UpdateImpl
        MGTK_CALL MGTK::SetPattern, solid_pattern
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, rect
        beq     btk::HiliteImpl::skip_port ; always
.endproc ; UpdateImpl

;;; ============================================================

.proc FlashImpl
        ;; If disabled, return canceled
        bit     state
    IF NS
        return8 #$80
    END_IF

        jsr     _SetPort
        jsr     _Invert
        FALL_THROUGH_TO _Invert
.endproc ; FlashImpl

.proc _Invert
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::InflateRect, shrink_rect
        MGTK_CALL MGTK::PaintRect, rect
        MGTK_CALL MGTK::InflateRect, grow_rect
        ;; returns MGTK success (A=0/Z=1/N=0)
        rts
.endproc ; _Invert

;;; ============================================================

.proc HiliteImpl
        jsr     _SetPort
skip_port:

        pos := $0B

        ;; Y-offset from bottom for shorter-than-normal buttons, e.g. arrow glyphs
        sub16_8 rect+MGTK::Rect::y2, #(kButtonHeight - kButtonTextVOffset), pos+MGTK::Point::ycoord

        ldx     #DeskTopSettings::options
        jsr     ReadSetting
        and     #DeskTopSettings::kOptionsShowShortcuts
    IF NOT_ZERO
        ;; Draw the string (left aligned)
        add16_8 rect+MGTK::Rect::x1, #kButtonTextHOffset, pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, pos
        jsr     _DrawLabel

        ;; Draw the shortcut (if present, right aligned)
        lda     a_shortcut
        ora     a_shortcut+1
      IF NOT_ZERO
        @width := $9
        jsr     _MeasureShortcut
        stax    @width
        sub16_8 rect+MGTK::Rect::x2, #kButtonTextHOffset-2, pos+MGTK::Point::xcoord
        sub16   pos+MGTK::Point::xcoord, @width, pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, pos
        jsr     _DrawShortcut
      END_IF
    ELSE
        ;; Draw the label (centered)
        @width := $9
        jsr     _MeasureLabel
        stax    @width

        add16   rect+MGTK::Rect::x1, rect+MGTK::Rect::x2, pos+MGTK::Point::xcoord
        sub16   pos+MGTK::Point::xcoord, @width, pos+MGTK::Point::xcoord
        asr16   pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, pos
        jsr     _DrawLabel
    END_IF

        bit     state
    IF NS
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        MGTK_CALL MGTK::SetPenMode, penOR
        MGTK_CALL MGTK::InflateRect, shrink_rect
        MGTK_CALL MGTK::PaintRect, rect
    END_IF

        rts
.endproc ; HiliteImpl

;;; ============================================================

;;; Input: `a_shortcut` points at string
.proc _DrawShortcut
        ldax    a_shortcut
        jmp     _DrawString
.endproc ; _DrawShortcut

;;; Input: `a_label` points at string
.proc _DrawLabel
        ldax    a_label
        FALL_THROUGH_TO _DrawString
.endproc ; _DrawLabel

;;; Inputs: A,X points at string
.proc _DrawString
PARAM_BLOCK dt_params, btk::zp_scratch
textptr .addr
textlen .byte
END_PARAM_BLOCK
        stax    dt_params::textptr
        ldy     #0
        lda     (dt_params::textptr),y
    IF NOT_ZERO
        sta     dt_params::textlen
        inc16   dt_params::textptr
        MGTK_CALL MGTK::DrawText, dt_params
    END_IF
        rts
.endproc ; _DrawString

;;; Inputs: `a_shortcut` points at string
;;; Output: A,X = width
.proc _MeasureShortcut
        ldax    a_shortcut
        jmp     _MeasureString
.endproc ; _MeasureShortcut

;;; Inputs: `a_label` points at string
;;; Output: A,X = width
.proc _MeasureLabel
        ldax    a_label
        FALL_THROUGH_TO _MeasureString
.endproc ; _MeasureLabel

;;; Inputs: A,X points at string
;;; Output: A,X = width
.proc _MeasureString
PARAM_BLOCK tw_params, btk::zp_scratch
textptr .addr
textlen .byte
width   .word
END_PARAM_BLOCK
        stax    tw_params::textptr

        ldy     #0
        lda     (tw_params::textptr),y
    IF ZERO
        lda     #0
        tax
        rts
    END_IF

        sta     tw_params::textlen
        inc16   tw_params::textptr
        MGTK_CALL MGTK::TextWidth, tw_params
        ldax    tw_params::width
        rts
.endproc ; _MeasureString

;;; ============================================================


.proc TrackImpl

;;; Shadows params in Selector's `app` and Disk Copy's `auxlc` scopes.
;;; TODO: Rework scoping to eliminate this.
SUPPRESS_SHADOW_WARNING
        ;; Use ZP for temporary params
        PARAM_BLOCK event_params, btk::zp_scratch
kind    .byte
coords  .tag MGTK::Point
        END_PARAM_BLOCK
        .assert .sizeof(event_params) = .sizeof(MGTK::Event), error, "size mismatch"
        .assert .sizeof(event_params) <= kMaxTmpSpace, error, "size mismatch"
        PARAM_BLOCK screentowindow_params, btk::zp_scratch
window_id       .byte
screen          .tag MGTK::Point
window          .tag MGTK::Point
        END_PARAM_BLOCK
        .assert screentowindow_params::screen = event_params::coords, error, "mismatch"
        .assert .sizeof(screentowindow_params) <= kMaxTmpSpace, error, "size mismatch"
UNSUPPRESS_SHADOW_WARNING

        ;; If disabled, return canceled
        bit     state
    IF NS
        return8 #$80
    END_IF

        jsr     _SetPort

        ;; Initial state
        copy8   #0, down_flag

        ;; Do initial inversion
loop_i: jsr     _Invert

        ;; Event loop
loop:   MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_up
        beq     exit
        lda     window_id
    IF ZERO
        MGTK_CALL MGTK::MoveTo, event_params::coords
    ELSE
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
    END_IF
        MGTK_CALL MGTK::InRect, rect
        bne     inside
        lda     down_flag       ; outside but was inside?
        beq     toggle
        bne     loop            ; always

inside: lda     down_flag       ; already depressed?
        beq     loop

toggle: lda     down_flag
        eor     #$80
        sta     down_flag
        jmp     loop_i          ; invert and continue

exit:   lda     down_flag       ; was depressed?
    IF ZERO
        jsr     _Invert
    END_IF
        ;; Note that we want N=0 and Z=1 if clicked, so bits<7 matter.
        lda     down_flag
        rts
.endproc ; TrackImpl

.ifndef BTK_SHORT
;;; ============================================================

notpencopy:     .byte   MGTK::notpencopy

;;; Padding between radio/checkbox and label
kLabelPadding = 5

.params rb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   SELF_MODIFIED
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, BTK::kRadioButtonWidth, BTK::kRadioButtonHeight
        REF_MAPINFO_MEMBERS
.endparams

checked_rb_bitmap:
        PIXELS  "....########...."
        PIXELS  "..###......###.."
        PIXELS  "###...####...###"
        PIXELS  "##..########..##"
        PIXELS  "##..########..##"
        PIXELS  "###...####...###"
        PIXELS  "..###......###.."
        PIXELS  "....########...."

unchecked_rb_bitmap:
        PIXELS  "....########...."
        PIXELS  "..###......###.."
        PIXELS  "###..........###"
        PIXELS  "##............##"
        PIXELS  "##............##"
        PIXELS  "###..........###"
        PIXELS  "..###......###.."
        PIXELS  "....########...."

;;; ============================================================

.proc RadioDrawImpl
        jsr     _SetPort

        ;; Initial size is just the button
        add16_8 rect+MGTK::Rect::x1, #BTK::kRadioButtonWidth, rect+MGTK::Rect::x2
        add16_8 rect+MGTK::Rect::y1, #BTK::kRadioButtonHeight, rect+MGTK::Rect::y2

        lda     a_label
        ora     a_label+1
    IF NOT_ZERO
        ;; Draw the label
        pos := $B
        add16_8 rect+MGTK::Rect::x1, #kLabelPadding + BTK::kRadioButtonWidth, pos+MGTK::Point::xcoord
        add16_8 rect+MGTK::Rect::y1, #kSystemFontHeight - 1, pos+MGTK::Point::ycoord
        MGTK_CALL MGTK::MoveTo, pos
        jsr     _DrawLabel

        ;; And measure it for hit testing
        jsr     _MeasureLabel
        addax   rect+MGTK::Rect::x2
        add16_8 rect+MGTK::Rect::x2, #kLabelPadding
        add16_8 rect+MGTK::Rect::y2, #kSystemFontHeight - BTK::kRadioButtonHeight
    END_IF

        jsr     _MaybeDrawAndMeasureShortcut
        jsr     _WriteRectBackToButtonRecord

        jmp     _DrawRadioBitmap
.endproc ; RadioDrawImpl

;;; ============================================================

.proc RadioUpdateImpl
        jsr     _SetPort

        FALL_THROUGH_TO _DrawRadioBitmap
.endproc ; RadioUpdateImpl

.proc _DrawRadioBitmap
        COPY_STRUCT MGTK::Point, rect+MGTK::Rect::topleft, rb_params::viewloc
        ldax    #unchecked_rb_bitmap
        bit     state
    IF NS
        ldax    #checked_rb_bitmap
    END_IF
        stax    rb_params::mapbits

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintBitsHC, rb_params
        rts
.endproc ; _DrawRadioBitmap

;;; ============================================================

.params cb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   SELF_MODIFIED
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, BTK::kCheckboxWidth, BTK::kCheckboxHeight
        REF_MAPINFO_MEMBERS
.endparams

checked_cb_bitmap:
        PIXELS  "##################"
        PIXELS  "####..........####"
        PIXELS  "##..##......##..##"
        PIXELS  "##....##..##....##"
        PIXELS  "##......##......##"
        PIXELS  "##....##..##....##"
        PIXELS  "##..##......##..##"
        PIXELS  "####..........####"
        PIXELS  "##################"

unchecked_cb_bitmap:
        PIXELS  "##################"
        PIXELS  "##..............##"
        PIXELS  "##..............##"
        PIXELS  "##..............##"
        PIXELS  "##..............##"
        PIXELS  "##..............##"
        PIXELS  "##..............##"
        PIXELS  "##..............##"
        PIXELS  "##################"

;;; ============================================================

.proc CheckboxDrawImpl
        jsr     _SetPort

        ;; Initial size is just the button
        add16_8 rect+MGTK::Rect::x1, #BTK::kCheckboxWidth, rect+MGTK::Rect::x2
        add16_8 rect+MGTK::Rect::y1, #BTK::kCheckboxHeight, rect+MGTK::Rect::y2

        lda     a_label
        ora     a_label+1
    IF NOT_ZERO
        ;; Draw the label
        pos := $B
        add16_8 rect+MGTK::Rect::x1, #kLabelPadding + BTK::kCheckboxWidth, pos+MGTK::Point::xcoord
        add16_8 rect+MGTK::Rect::y1, #kSystemFontHeight, pos+MGTK::Point::ycoord
        MGTK_CALL MGTK::MoveTo, pos
        jsr     _DrawLabel

        ;; And measure it for hit testing
        jsr     _MeasureLabel
        addax   rect+MGTK::Rect::x2
        add16_8 rect+MGTK::Rect::x2, #kLabelPadding
        add16_8 rect+MGTK::Rect::y2, #kSystemFontHeight - BTK::kCheckboxHeight
    END_IF

        jsr     _MaybeDrawAndMeasureShortcut
        jsr     _WriteRectBackToButtonRecord

        jmp     _DrawCheckboxBitmap
.endproc ; CheckboxDrawImpl

;;; ============================================================

.proc CheckboxUpdateImpl
        jsr     _SetPort

        FALL_THROUGH_TO _DrawCheckboxBitmap
.endproc ; CheckboxUpdateImpl

.proc _DrawCheckboxBitmap
        COPY_STRUCT MGTK::Point, rect+MGTK::Rect::topleft, cb_params::viewloc
        ldax    #unchecked_cb_bitmap
        bit     state
    IF NS
        ldax    #checked_cb_bitmap
    END_IF
        stax    cb_params::mapbits

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintBitsHC, cb_params
        rts
.endproc ; _DrawCheckboxBitmap

;;; ============================================================

;;; If option is enabled, and if `a_shortcut` is not null,
;;; draw it and add the width to `rect`.
.proc _MaybeDrawAndMeasureShortcut
        ldx     #DeskTopSettings::options
        jsr     ReadSetting
        and     #DeskTopSettings::kOptionsShowShortcuts
    IF NOT_ZERO
        lda     a_shortcut
        ora     a_shortcut+1
      IF NOT_ZERO
        jsr     _DrawShortcut

        jsr     _MeasureShortcut
        addax   rect+MGTK::Rect::x2
      END_IF
    END_IF

        rts
.endproc ; _MaybeDrawAndMeasureShortcut

;;; Copies `rect` back into `a_record`
.proc _WriteRectBackToButtonRecord
        ;; Write rect back to button record
        ldx     #.sizeof(MGTK::Rect)-1
        ldy     #BTK::ButtonRecord::rect + .sizeof(MGTK::Rect)-1
    DO
        copy8   rect,x, (params_addr),y
        dey
        dex
    WHILE POS
        rts
.endproc ; _WriteRectBackToButtonRecord

;;; ============================================================
.endif ; BTK_SHORT

.endscope ; btk
