;;; ============================================================
;;; Alert Dialog Definition
;;;
;;; Call `Alert` with A,X = `AlertParams` struct
;;;
;;; Requires the following proc definitions:
;;; * `Bell`
;;; * `SystemTask`
;;; Requires the following data definitions:
;;; * `alert_grafport`
;;; Requires the following macro definitions:
;;; * `MGTK_CALL`
;;; * `BTK_CALL`
;;; Optionally define:
;;; * `AD_YESNOALL` (if defined, yes/no/all buttons supported)
;;; * `AD_SAVEBG` (if defined, background saved/restored)
;;; * `AD_EJECTABLE` (if defined, polls for certain messages)
;;; If `AD_EJECTABLE`. requires `WaitForDiskOrEsc` and `ejectable_flag`
;;; ============================================================

.proc Alert
        jmp     start

question_bitmap:
        PIXELS  "....................................."
        PIXELS  ".###########........................."
        PIXELS  ".###########........................."
        PIXELS  ".###########........................."
        PIXELS  ".###########.........#########......."
        PIXELS  ".####..#####......###############...."
        PIXELS  ".####..#####.....####.........####..."
        PIXELS  ".####..#####....####...........####.."
        PIXELS  ".###########....####...#####...####.."
        PIXELS  ".###########....####...#####...####.."
        PIXELS  ".###########....############...####.."
        PIXELS  ".###########....###########...#####.."
        PIXELS  ".###########....##########...######.."
        PIXELS  ".###########....#########...#######.."
        PIXELS  ".###########....########...########.."
        PIXELS  ".###########....#######...#########.."
        PIXELS  ".###########....#######...#########.."
        PIXELS  ".#####..........###################.."
        PIXELS  ".########.......#######...########..."
        PIXELS  ".########......########...#######...."
        PIXELS  ".###........##################......."
        PIXELS  ".########............................"
        PIXELS  ".########............................"
        PIXELS  "....................................."

exclamation_bitmap:
        PIXELS  "....................................."
        PIXELS  ".###########........................."
        PIXELS  ".###########........................."
        PIXELS  ".###########........................."
        PIXELS  ".###########.........#########......."
        PIXELS  ".####..#####......###############...."
        PIXELS  ".####..#####.....######....#######..."
        PIXELS  ".####..#####....#######....########.."
        PIXELS  ".###########....#######....########.."
        PIXELS  ".###########....#######....########.."
        PIXELS  ".###########....#######....########.."
        PIXELS  ".###########....#######....########.."
        PIXELS  ".###########....#######....########.."
        PIXELS  ".###########....#######....########.."
        PIXELS  ".###########....#######....########.."
        PIXELS  ".###########....#######....########.."
        PIXELS  ".###########....###################.."
        PIXELS  ".#####..........#######....########.."
        PIXELS  ".########.......#######....#######..."
        PIXELS  ".########......##################...."
        PIXELS  ".###........##################......."
        PIXELS  ".########............................"
        PIXELS  ".########............................"
        PIXELS  "....................................."

        kAlertXMargin = 20

.params alert_bitmap_params
        DEFINE_POINT viewloc, kAlertRectLeft + kAlertXMargin, kAlertRectTop + 8
mapbits:        .addr   SELF_MODIFIED
mapwidth:       .byte   6
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 36, 23
        REF_MAPINFO_MEMBERS
.endparams

pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy

event_params:   .tag    MGTK::Event
event_kind      := event_params + MGTK::Event::kind
event_coords    := event_params + MGTK::Event::xcoord
event_key       := event_params + MGTK::Event::key

;;; Bounds of the alert "window"
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

;;; Inner frame
pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_SZ alert_inner_frame_rect, kAlertRectLeft + kBorderDX, kAlertRectTop + kBorderDY, kAlertRectWidth - kBorderDX*3 + 1, kAlertRectHeight - kBorderDY*3 + 1

;;; --------------------------------------------------

        kAlertButtonTop = kAlertRectTop + 37

        DEFINE_BUTTON ok_button,        0, res_string_button_ok, kGlyphReturn, kAlertRectLeft + 300, kAlertButtonTop
        DEFINE_BUTTON try_again_button, 0, res_string_button_try_again, res_char_button_try_again_shortcut, kAlertRectLeft + 300, kAlertButtonTop
        DEFINE_BUTTON cancel_button,    0, res_string_button_cancel, res_string_button_cancel_shortcut, kAlertRectLeft + 20, kAlertButtonTop

.ifdef AD_YESNOALL
        DEFINE_BUTTON yes_button,  0, res_string_button_yes, res_char_button_yes_shortcut, kAlertRectLeft + 175, kAlertButtonTop, 65
        DEFINE_BUTTON no_button,   0, res_string_button_no,  res_char_button_no_shortcut,  kAlertRectLeft + 255, kAlertButtonTop, 65
        DEFINE_BUTTON all_button,  0, res_string_button_all, res_char_button_all_shortcut, kAlertRectLeft + 335, kAlertButtonTop, 65
.endif ; AD_YESNOALL

        kTextLeft = kAlertRectLeft + 75
        kTextRight = kAlertRectLeft + kAlertRectWidth - kAlertXMargin

        kWrapWidth = kTextRight - kTextLeft

        DEFINE_POINT pos_prompt1, kTextLeft, kAlertRectTop + 29-11
        DEFINE_POINT pos_prompt2, kTextLeft, kAlertRectTop + 29

.params textwidth_params        ; Used for spitting/drawing the text.
data:   .addr   0
length: .byte   0
width:  .word   0
.endparams
len:    .byte   0               ; total string length
split_pos:                      ; last known split position
        .byte   0

.params alert_params
text:           .addr   0
buttons:        .byte   0       ; AlertButtonOptions
options:        .byte   0       ; AlertOptions flags
.endparams
ASSERT_EQUALS .sizeof(alert_params), .sizeof(AlertParams)

        kShortcutTryAgain = res_char_button_try_again_shortcut

.ifdef AD_YESNOALL
        kShortcutYes      = res_char_button_yes_shortcut
        kShortcutNo       = res_char_button_no_shortcut
        kShortcutAll      = res_char_button_all_shortcut
.endif ; AD_YESNOALL

        ;; Actual entry point
start:
        ;; Copy passed params
        stax    addr
        ldx     #.sizeof(AlertParams)-1
    DO
        addr := *+1
        lda     SELF_MODIFIED,x
        sta     alert_params,x
        dex
    WHILE POS

        MGTK_CALL MGTK::GetCursorAdr, saved_cursor_addr
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer

        ;; --------------------------------------------------
        ;; Draw alert


.ifdef AD_SAVEBG
        bit     alert_params::options
    IF VS                       ; V = use save area
        MGTK_CALL MGTK::SaveScreenRect, alert_rect
    END_IF
.endif ; AD_SAVEBG

        ;; Set up GrafPort - all drawing is in screen coordinates
        MGTK_CALL MGTK::InitPort, alert_grafport
        MGTK_CALL MGTK::SetPort, alert_grafport

        MGTK_CALL MGTK::HideCursor

        ;; --------------------------------------------------
        ;; Draw alert box and bitmap

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, alert_rect ; alert background
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, alert_rect ; alert outline

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, alert_inner_frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        ldax    #exclamation_bitmap
        ldy     alert_params::buttons
    IF NOT_ZERO
        ldax    #question_bitmap
    END_IF
        stax    alert_bitmap_params::mapbits
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintBits, alert_bitmap_params

        ;; --------------------------------------------------
        ;; Draw appropriate buttons

.ifdef AD_EJECTABLE
        bit     ejectable_flag
        jmi     done_buttons
.endif

        bit     alert_params::buttons ; high bit clear = OK only
        bpl     draw_ok_btn

        ;; Cancel button
        BTK_CALL BTK::Draw, cancel_button

        bit     alert_params::buttons ; V bit set = Cancel + OK
        bvs     draw_ok_btn

.ifdef AD_YESNOALL
        ;; Yes/No/All?
        lda     alert_params::buttons
        and     #$0F
    IF NOT_ZERO
        BTK_CALL BTK::Draw, yes_button
        BTK_CALL BTK::Draw, no_button
        BTK_CALL BTK::Draw, all_button
        jmp     done_buttons
    END_IF
.endif

        ;; Try Again button
        BTK_CALL BTK::Draw, try_again_button
        jmp     done_buttons

        ;; OK button
draw_ok_btn:
        BTK_CALL BTK::Draw, ok_button

done_buttons:

        ;; --------------------------------------------------
        ;; Prompt string
.scope
        ;; Measure for splitting
        ldxy    alert_params::text
        inxy
        stxy    textwidth_params::data

        ptr := $06
        copy16  alert_params::text, ptr
        ldy     #0
        sty     split_pos       ; initialize
        lda     (ptr),y
        sta     len             ; total length

        ;; Search for space or end of string
advance:
    DO
        iny
        BREAK_IF Y = len
        lda     (ptr),y
    WHILE A <> #' '

        ;; Does this much fit?
        sty     textwidth_params::length
        MGTK_CALL MGTK::TextWidth, textwidth_params
        cmp16   textwidth_params::width, #kWrapWidth
    IF LT
        ;; Yes, record possible split position, maybe continue.
        ldy     textwidth_params::length
        sty     split_pos
        cpy     len             ; hit end of string?
        bne     advance         ; no, keep looking

        ;; Whole string fits, just draw it.
        copy8   len, textwidth_params::length
        MGTK_CALL MGTK::MoveTo, pos_prompt2
        MGTK_CALL MGTK::DrawText, textwidth_params
        beq     done            ; always
    END_IF

        ;; Split string over two lines.
        copy8   split_pos, textwidth_params::length
        MGTK_CALL MGTK::MoveTo, pos_prompt1
        MGTK_CALL MGTK::DrawText, textwidth_params
        add16_8 textwidth_params::data, split_pos
        lda     len
        sec
        sbc     split_pos
        sta     textwidth_params::length
        MGTK_CALL MGTK::MoveTo, pos_prompt2
        MGTK_CALL MGTK::DrawText, textwidth_params

done:
.endscope
        MGTK_CALL MGTK::ShowCursor

        ;; --------------------------------------------------
        ;; Play bell

        bit     alert_params::options
    IF NS                       ; N = play sound
        jsr     Bell
    END_IF

        ;; --------------------------------------------------
        ;; Event Loop

event_loop:
.ifdef AD_EJECTABLE
        bit     ejectable_flag
    IF NS
        jsr     WaitForDiskOrEsc
        jeq     finish_ok
        jmp     finish_cancel
    END_IF
.endif ; AD_EJECTABLE

        jsr     SystemTask
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        jeq     HandleButtonDown

        cmp     #MGTK::EventKind::key_down
        bne     event_loop

        ;; --------------------------------------------------
        ;; Key Down
        lda     event_key
        jsr     ToUpperCase

        bit     alert_params::buttons ; high bit clear = OK only
        bpl     check_only_ok

        cmp     #CHAR_ESCAPE
    IF EQ
        ;; Cancel
        BTK_CALL BTK::Flash, cancel_button
finish_cancel:
        lda     #kAlertResultCancel
        jmp     finish
    END_IF

        bit     alert_params::buttons ; V bit set = Cancel + OK
        bvs     check_ok

.ifdef AD_YESNOALL
        pha
        lda     alert_params::buttons
        and     #$0F
    IF NOT_ZERO
        pla

      IF A = #kShortcutNo
        BTK_CALL BTK::Flash, no_button
        lda     #kAlertResultNo
        jmp     finish
      END_IF

      IF A = #kShortcutYes
        BTK_CALL BTK::Flash, yes_button
        lda     #kAlertResultYes
        jmp     finish
      END_IF

      IF A = #kShortcutAll
        BTK_CALL BTK::Flash, all_button
        lda     #kAlertResultAll
        jmp     finish
      END_IF

        bne     event_loop      ; always
    END_IF
        pla
.endif ; AD_YESNOALL

    IF A = #kShortcutTryAgain
do_try_again:
        BTK_CALL BTK::Flash, try_again_button
        lda     #kAlertResultTryAgain
        jmp     finish
    END_IF

        cmp     #CHAR_RETURN    ; also allow Return as default
        beq     do_try_again
        jmp     event_loop

check_only_ok:
        cmp     #CHAR_ESCAPE    ; also allow Escape as default
        beq     do_ok
check_ok:
        cmp     #CHAR_RETURN
        jne     event_loop

do_ok:  BTK_CALL BTK::Flash, ok_button
finish_ok:
        lda     #kAlertResultOK
        jmp     finish          ; not a fixed value, cannot BNE/BEQ

        ;; --------------------------------------------------
        ;; Buttons

HandleButtonDown:
        MGTK_CALL MGTK::MoveTo, event_coords

        bit     alert_params::buttons ; high bit clear = OK only
        bpl     check_ok_rect

        ;; Cancel
        MGTK_CALL MGTK::InRect, cancel_button+BTK::ButtonRecord::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, cancel_button
        bne     was_no_button
        lda     #kAlertResultCancel
        ASSERT_NOT_EQUALS ::kAlertResultCancel, 0
        bne     finish          ; always
    END_IF

        bit     alert_params::buttons  ; V bit set = Cancel + OK
        bvs     check_ok_rect

.ifdef AD_YESNOALL
        lda     alert_params::buttons
        and     #$0F
    IF NOT_ZERO
        ;; Yes & No & All
        MGTK_CALL MGTK::InRect, yes_button+BTK::ButtonRecord::rect
      IF NOT_ZERO
        BTK_CALL BTK::Track, yes_button
        bne     was_no_button
        lda     #kAlertResultYes
        ASSERT_NOT_EQUALS ::kAlertResultYes, 0
        bne     finish          ; always
      END_IF

        MGTK_CALL MGTK::InRect, no_button+BTK::ButtonRecord::rect
      IF NOT_ZERO
        BTK_CALL BTK::Track, no_button
        bne     was_no_button
        lda     #kAlertResultNo
        ASSERT_NOT_EQUALS ::kAlertResultNo, 0
        bne     finish          ; always
      END_IF

        MGTK_CALL MGTK::InRect, all_button+BTK::ButtonRecord::rect
        beq     was_no_button
        BTK_CALL BTK::Track, all_button
        bne     was_no_button
        lda     #kAlertResultAll
        ASSERT_NOT_EQUALS ::kAlertResultAll, 0
        bne     finish          ; always
    END_IF
.endif

        ;; Try Again
        MGTK_CALL MGTK::InRect, try_again_button+BTK::ButtonRecord::rect
        beq     was_no_button
        BTK_CALL BTK::Track, try_again_button
        bne     was_no_button
        lda     #kAlertResultTryAgain
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     finish          ; always

        ;; OK
check_ok_rect:
        MGTK_CALL MGTK::InRect, ok_button+BTK::ButtonRecord::rect
        beq     was_no_button
        BTK_CALL BTK::Track, ok_button
        bne     was_no_button
        lda     #kAlertResultOK
        ASSERT_NOT_EQUALS ::kAlertResultOK, 0
        bne     finish          ; always

was_no_button:
        jmp     event_loop

;;; ============================================================

finish:
        pha

.ifdef AD_SAVEBG
        bit     alert_params::options
    IF VS                       ; V = use save area
        MGTK_CALL MGTK::RestoreScreenRect, alert_rect
    END_IF
.else
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, alert_rect
.endif ; AD_SAVEBG

        MGTK_CALL MGTK::SetCursor, SELF_MODIFIED, saved_cursor_addr

        pla
        rts

;;; ============================================================

        .include "uppercase.s"

.endproc ; Alert
