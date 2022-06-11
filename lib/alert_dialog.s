;;; ============================================================
;;; Alert Dialog Definition
;;;
;;; Requires the following proc definitions:
;;; * `pointer_cursor`
;;; * `Bell`
;;; * `DrawString`
;;; * `AlertYieldLoop`
;;; Requires the following data definitions:
;;; * `alert_grafport`
;;; Requires the following macro definitions:
;;; * `MGTK_CALL`
;;; Requires the following defines:
;;; * AD_YESNO (if true, yes/no buttons supported)
;;; * AD_SAVEBG (if true, background saved/restored)
;;; * AD_WRAP (if true, message is wrapped)
;;; * AD_EJECTABLE (if true, polls for certain messages)
;;; If AD_EJECTABLE. requires `WaitForDiskOrEsc` and `ejectable_flag`
;;; ============================================================

.proc Alert
        jmp     start

question_bitmap:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%1111111),PX(%1100000),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0000111),PX(%1111111),PX(%1111100),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0001111),PX(%0000000),PX(%0011110),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0011110),PX(%0000000),PX(%0001111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011110),PX(%0011111),PX(%0001111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011110),PX(%0011111),PX(%0001111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%0001111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111110),PX(%0011111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111100),PX(%0111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111000),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1110001),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1100011),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1100011),PX(%1111111),PX(%0000000)
        .byte   PX(%0111110),PX(%0000000),PX(%0011111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0011111),PX(%1100011),PX(%1111110),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0111111),PX(%1100011),PX(%1111100),PX(%0000000)
        .byte   PX(%0111000),PX(%0000011),PX(%1111111),PX(%1111111),PX(%1100000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)

exclamation_bitmap:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%1111111),PX(%1100000),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0000111),PX(%1111111),PX(%1111100),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0001111),PX(%1100001),PX(%1111110),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0011111),PX(%1100001),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1100001),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1100001),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1100001),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1100001),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1100001),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1100001),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1100001),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1100001),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0111110),PX(%0000000),PX(%0011111),PX(%1100001),PX(%1111111),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0011111),PX(%1100001),PX(%1111110),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0111111),PX(%1111111),PX(%1111100),PX(%0000000)
        .byte   PX(%0111000),PX(%0000011),PX(%1111111),PX(%1111111),PX(%1100000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)

        kAlertXMargin = 20

.params alert_bitmap_params
        DEFINE_POINT viewloc, kAlertXMargin, 8
mapbits:        .addr   SELF_MODIFIED
mapwidth:       .byte   6
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 36, 23
.endparams

pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy
penXOR:         .byte   MGTK::penXOR

event_params:   .tag    MGTK::Event
event_kind      := event_params + MGTK::Event::kind
event_coords    := event_params + MGTK::Event::xcoord
event_xcoord    := event_params + MGTK::Event::xcoord
event_ycoord    := event_params + MGTK::Event::ycoord
event_key       := event_params + MGTK::Event::key

kAlertRectWidth         = 420
kAlertRectHeight        = 55
kAlertRectLeft          = (::kScreenWidth - kAlertRectWidth)/2
kAlertRectTop           = (::kScreenHeight - kAlertRectHeight)/2

;;; Window frame is outside the rect proper
kAlertFrameLeft = kAlertRectLeft - 1
kAlertFrameTop = kAlertRectTop - 1
kAlertFrameWidth = kAlertRectWidth + 2
kAlertFrameHeight = kAlertRectHeight + 2
        DEFINE_RECT_SZ alert_rect, kAlertFrameLeft, kAlertFrameTop, kAlertFrameWidth, kAlertFrameHeight

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME alert_inner_frame_rect, kAlertRectWidth, kAlertRectHeight

.if AD_SAVEBG
.params screen_portbits
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kScreenWidth-1, kScreenHeight-1
.endparams
.endif ; AD_SAVEBG

.params portmap
        DEFINE_POINT viewloc, kAlertRectLeft, kAlertRectTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kAlertRectWidth, kAlertRectHeight
.endparams

.if !AD_SAVEBG
;;; TODO: Move out of alert scope
.params portbits2
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kScreenWidth-1, kScreenHeight-1
.endparams
.endif ; AD_SAVEBG

        DEFINE_BUTTON ok,        res_string_button_ok,          300, 37
        DEFINE_BUTTON try_again, res_string_button_try_again,   300, 37
        DEFINE_BUTTON cancel,    res_string_button_cancel,       20, 37

.if AD_YESNO
        DEFINE_BUTTON yes, res_string_button_yes, 250, 37, 50, kButtonHeight
        DEFINE_BUTTON no,  res_string_button_no,  350, 37, 50, kButtonHeight
.endif ; AD_YESNO

        kTextLeft = 75
        kTextRight = kAlertRectWidth - kAlertXMargin
        kWrapWidth = kTextRight - kTextLeft

.if AD_WRAP
        DEFINE_POINT pos_prompt1, kTextLeft, 29-11
        DEFINE_POINT pos_prompt2, kTextLeft, 29

.params textwidth_params        ; Used for spitting/drawing the text.
data:   .addr   0
length: .byte   0
width:  .word   0
.endparams
len:    .byte   0               ; total string length
split_pos:                      ; last known split position
        .byte   0
.else
        DEFINE_POINT pos_prompt, kTextLeft, 29
.endif ; AD_WRAP

.params alert_params
text:           .addr   0
buttons:        .byte   0       ; AlertButtonOptions
options:        .byte   0       ; AlertOptions flags
.endparams

        ;; Actual entry point
start:
        ;; Copy passed params
        stax    @addr
        ldx     #.sizeof(alert_params)-1
        @addr := *+1
:       lda     SELF_MODIFIED,x
        sta     alert_params,x
        dex
        bpl     :-

        MGTK_CALL MGTK::SetCursor, pointer_cursor

        ;; --------------------------------------------------
        ;; Draw alert

        MGTK_CALL MGTK::HideCursor

.if AD_SAVEBG
        bit     alert_params::options
    IF_VS                       ; V = use save area
        ;; Compute save bounds
        ldax    #kAlertFrameLeft
        jsr     CalcXSaveBounds
        sty     save_x1_byte
        sta     save_x1_bit

        ldax    #kAlertFrameLeft + kAlertFrameWidth
        jsr     CalcXSaveBounds
        sty     save_x2_byte
        sta     save_x2_bit

        lda     #kAlertFrameTop
        sta     save_y1
        lda     #kAlertFrameTop + kAlertFrameHeight
        sta     save_y2

        jsr     DialogBackgroundSave
    END_IF
.endif ; AD_SAVEBG

        ;; Set up GrafPort
        MGTK_CALL MGTK::InitPort, alert_grafport
        MGTK_CALL MGTK::SetPort, alert_grafport

.if AD_SAVEBG
        ;; TODO: Is this needed?
        MGTK_CALL MGTK::SetPortBits, screen_portbits ; viewport for screen
.endif

        ;; Draw alert box and bitmap - coordinates are in screen space
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, alert_rect ; alert background
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, alert_rect ; alert outline

        MGTK_CALL MGTK::SetPortBits, portmap ; viewport for remaining operations

        ;; Draw rest of alert - coordinates are relative to portmap
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, alert_inner_frame_rect

        ldax    #exclamation_bitmap
        ldy     alert_params::buttons
    IF_NOT_ZERO
        ldax    #question_bitmap
    END_IF
        stax    alert_bitmap_params::mapbits
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintBits, alert_bitmap_params

        ;; Draw appropriate buttons
.if AD_EJECTABLE
        bit     ejectable_flag
        jmi     done_buttons
.endif

        jsr     SetPenXOR
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        bit     alert_params::buttons ; high bit clear = Cancel
        bpl     draw_ok_btn

        ;; Cancel button
        MGTK_CALL MGTK::FrameRect, cancel_button_rect
        MGTK_CALL MGTK::MoveTo, cancel_button_pos
        param_call DrawString, cancel_button_label

        bit     alert_params::buttons
        bvs     draw_ok_btn

.if AD_YESNO
        ;; Yes/No or Try Again?
        lda     alert_params::buttons
        and     #$0F
        beq     draw_try_again_btn

        ;; Yes button
        MGTK_CALL MGTK::FrameRect, yes_button_rect
        MGTK_CALL MGTK::MoveTo, yes_button_pos
        param_call DrawString, yes_button_label

        ;; No button
        MGTK_CALL MGTK::FrameRect, no_button_rect
        MGTK_CALL MGTK::MoveTo, no_button_pos
        param_call DrawString, no_button_label
        jmp     done_buttons
draw_try_again_btn:
.endif

        ;; Try Again button
        MGTK_CALL MGTK::FrameRect, try_again_button_rect
        MGTK_CALL MGTK::MoveTo, try_again_button_pos
        param_call DrawString, try_again_button_label

        jmp     done_buttons

        ;; OK button
draw_ok_btn:
        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call DrawString, ok_button_label

done_buttons:

        ;; Prompt string
.if AD_WRAP
.scope
        ;; Measure for splitting
        ldx     alert_params::text
        ldy     alert_params::text + 1
        inx
        bne     :+
        iny
:       stx     textwidth_params::data
        sty     textwidth_params::data + 1

        ptr := $06
        copy16  alert_params::text, ptr
        ldy     #0
        sty     split_pos       ; initialize
        lda     (ptr),y
        sta     len             ; total length

        ;; Search for space or end of string
advance:
:       iny
        cpy     len
        beq     test
        lda     (ptr),y
        cmp     #' '
        bne     :-

        ;; Does this much fit?
test:   sty     textwidth_params::length
        MGTK_CALL MGTK::TextWidth, textwidth_params
        cmp16   textwidth_params::width, #kWrapWidth
        bcs     split           ; no! so we know where to split now

        ;; Yes, record possible split position, maybe continue.
        ldy     textwidth_params::length
        sty     split_pos
        cpy     len             ; hit end of string?
        bne     advance         ; no, keep looking

        ;; Whole string fits, just draw it.
        copy    len, textwidth_params::length
        MGTK_CALL MGTK::MoveTo, pos_prompt2
        MGTK_CALL MGTK::DrawText, textwidth_params
        jmp     done

        ;; Split string over two lines.
split:  copy    split_pos, textwidth_params::length
        MGTK_CALL MGTK::MoveTo, pos_prompt1
        MGTK_CALL MGTK::DrawText, textwidth_params
        lda     textwidth_params::data
        clc
        adc     split_pos
        sta     textwidth_params::data
        bcc     :+
        inc     textwidth_params::data + 1
:       lda     len
        sec
        sbc     split_pos
        sta     textwidth_params::length
        MGTK_CALL MGTK::MoveTo, pos_prompt2
        MGTK_CALL MGTK::DrawText, textwidth_params

done:
.endscope
.else
        MGTK_CALL MGTK::MoveTo, pos_prompt
        param_call_indirect DrawString, alert_params::text
.endif  ; AD_WRAP

        MGTK_CALL MGTK::ShowCursor

        ;; --------------------------------------------------
        ;; Play bell

        bit     alert_params::options
    IF_NS                       ; N = play sound
        jsr     Bell
    END_IF

        ;; --------------------------------------------------
        ;; Event Loop

event_loop:
.if AD_EJECTABLE
        bit     ejectable_flag
    IF_NS
        jsr     WaitForDiskOrEsc
        bne     :+
        jmp     finish_ok
:       jmp     finish_cancel
    END_IF
.endif ; AD_EJECTABLE

        jsr     AlertYieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        jeq     HandleButtonDown

        cmp     #MGTK::EventKind::key_down
        bne     event_loop

        ;; --------------------------------------------------
        ;; Key Down
        lda     event_key
        bit     alert_params::buttons ; has Cancel?
        bpl     check_only_ok   ; nope

        cmp     #CHAR_ESCAPE
        bne     :+

        ;; Cancel
        jsr     SetPenXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
finish_cancel:
        lda     #kAlertResultCancel
        jmp     finish

:       bit     alert_params::buttons ; has Try Again?
        bvs     check_ok        ; nope

.if AD_YESNO
        pha
        lda     alert_params::buttons
        and     #$0F
        beq     check_try_again

        pla
        cmp     #kShortcutNo
        beq     do_no
        cmp     #TO_LOWER(kShortcutNo)
        beq     do_no
        cmp     #kShortcutYes
        beq     do_yes
        cmp     #TO_LOWER(kShortcutYes)
        beq     do_yes
        jmp     event_loop

do_no:  jsr     SetPenXOR
        MGTK_CALL MGTK::PaintRect, no_button_rect
        lda     #kAlertResultNo
        jmp     finish

do_yes: jsr     SetPenXOR
        MGTK_CALL MGTK::PaintRect, yes_button_rect
        lda     #kAlertResultYes
        jmp     finish

check_try_again:
        pla
.endif ; AD_YESNO

        cmp     #TO_LOWER(kShortcutTryAgain)
        bne     :+

do_try_again:
        jsr     SetPenXOR
        MGTK_CALL MGTK::PaintRect, try_again_button_rect
        lda     #kAlertResultTryAgain
        jmp     finish

:       cmp     #kShortcutTryAgain
        beq     do_try_again
        cmp     #CHAR_RETURN    ; also allow Return as default
        beq     do_try_again
        jmp     event_loop

check_only_ok:
        cmp     #CHAR_ESCAPE    ; also allow Escape as default
        beq     do_ok
check_ok:
        cmp     #CHAR_RETURN
        jne     event_loop

do_ok:  jsr     SetPenXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
finish_ok:
        lda     #kAlertResultOK
        jmp     finish          ; not a fixed value, cannot BNE/BEQ

        ;; --------------------------------------------------
        ;; Buttons

HandleButtonDown:
        jsr     MapEventCoords
        MGTK_CALL MGTK::MoveTo, event_coords

        bit     alert_params::buttons ; Anything but OK?
        bpl     check_ok_rect   ; nope

        ;; Cancel
        MGTK_CALL MGTK::InRect, cancel_button_rect
        cmp     #MGTK::inrect_inside
        bne     :+
        param_call AlertButtonEventLoop, cancel_button_rect
        bne     no_button
        lda     #kAlertResultCancel
        .assert kAlertResultCancel <> 0, error, "kAlertResultCancel must be non-zero"
        bne     finish          ; always

:       bit     alert_params::buttons ; any other buttons?
        bvs     check_ok_rect   ; nope

.if AD_YESNO
        lda     alert_params::buttons
        and     #$0F            ;
        beq     LEE47           ; Just Cancel/Try Again

        ;; Yes & No
        MGTK_CALL MGTK::InRect, no_button_rect
        cmp     #MGTK::inrect_inside
        bne     :+
        param_call AlertButtonEventLoop, no_button_rect
        bne     no_button
        lda     #kAlertResultNo
        jmp     finish

:       MGTK_CALL MGTK::InRect, yes_button_rect
        cmp     #MGTK::inrect_inside
        bne     no_button
        param_call AlertButtonEventLoop, yes_button_rect
        bne     no_button
        lda     #kAlertResultYes
        jmp     finish
LEE47:
.endif

        ;; Try Again
        MGTK_CALL MGTK::InRect, try_again_button_rect
        cmp     #MGTK::inrect_inside
        bne     no_button
        param_call AlertButtonEventLoop, try_again_button_rect
        bne     no_button
        lda     #kAlertResultTryAgain
        .assert kAlertResultTryAgain = 0, error, "kAlertResultTryAgain must be non-zero"
        beq     finish          ; always

        ;; OK
check_ok_rect:
        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
        bne     no_button
        param_call AlertButtonEventLoop, ok_button_rect
        bne     no_button
        lda     #kAlertResultOK
        jmp     finish          ; not a fixed value, cannot BNE/BEQ

no_button:
        jmp     event_loop

;;; ============================================================

finish:
.if AD_SAVEBG
        bit     alert_params::options
    IF_VS                       ; V = use save area
        pha
        MGTK_CALL MGTK::HideCursor
        jsr     DialogBackgroundRestore
        MGTK_CALL MGTK::ShowCursor
        pla
    END_IF
.else
        pha
        MGTK_CALL MGTK::SetPortBits, portbits2
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, alert_rect
        pla
.endif ; AD_SAVEBG
        rts

;;; ============================================================

.proc MapEventCoords
        sub16   event_xcoord, portmap::viewloc::xcoord, event_xcoord
        sub16   event_ycoord, portmap::viewloc::ycoord, event_ycoord
        rts
.endproc

;;; ============================================================

.proc SetPenXOR
        MGTK_CALL MGTK::SetPenMode, penXOR
        rts
.endproc

;;; ============================================================
;;; Event loop during button press - initial invert and
;;; inverting as mouse is dragged in/out.
;;; (The `ButtonClick` proc is not used as these buttons
;;; are not in a window, so ScreenToWindow can not be used.)
;;; Inputs: A,X = rect address
;;; Output: A=0/N=0/Z=1 = click, A=$80/N=1/Z=0 = cancel

.proc AlertButtonEventLoop
        stax    rect_addr1
        stax    rect_addr2
        lda     #0
        sta     flag
        MGTK_CALL MGTK::SetPenMode, penXOR
        jsr     Invert

loop:   MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     button_up
        jsr     MapEventCoords
        MGTK_CALL MGTK::MoveTo, event_coords
        MGTK_CALL MGTK::InRect, SELF_MODIFIED, rect_addr1
        cmp     #MGTK::inrect_inside
        beq     inside
        lda     flag
        beq     toggle
        bne     loop

inside: lda     flag
        beq     loop

toggle: jsr     Invert
        lda     flag
        eor     #$80
        sta     flag
        jmp     loop

button_up:
        lda     flag
        rts

Invert:
        MGTK_CALL MGTK::PaintRect, SELF_MODIFIED, rect_addr2
        rts

        ;; High bit clear if button is depressed
flag:   .byte   0
.endproc

;;; ============================================================

.if AD_SAVEBG
        .include "savedialogbackground.s"
        DialogBackgroundSave := dialog_background::Save
        DialogBackgroundRestore := dialog_background::Restore
.endif ; AD_SAVEBG

.endproc
