;;; ============================================================
;;; CONTROL.PANEL - Desk Accessory
;;;
;;; A control panel offering system settings:
;;;   * DeskTop pattern
;;;   * Mouse tracking speed
;;;   * Double-click speed
;;;   * Insertion point blink rate
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "control.panel.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================
;;; Memory map
;;;
;;;               Main            Aux
;;;          :             : :             :
;;;          |             | |             |
;;;          | DHR         | | DHR         |
;;;  $2000   +-------------+ +-------------+
;;;          | IO Buffer   | |             |
;;;  $1C00   +-------------+ |             |
;;;          | write_buffer| |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          | stub & save | | GUI code &  |
;;;          | settings    | | resource    |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;
;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

.proc RunDA
        jsr     Init
        RETURN  A=dialog_result
.endproc ; RunDA

;;; High bit set when anything changes.
dialog_result:
        .byte   0

.proc MarkDirty
        lda     #$80
        ora     dialog_result
        sta     dialog_result
        rts
.endproc ; MarkDirty

;;; ============================================================

kDAWindowId     = $80
kDAWidth        = 431
kDAHeight       = 132
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

str_title:
        PASCAL_STRING res_string_window_title

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::go_away_box
title:          .addr   str_title
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   32
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kDAWidth
mincontheight:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontheight:  .word   kDAHeight
port:
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

.params frame_pensize
penwidth:       .byte   4
penheight:      .byte   2
.endparams

        DEFINE_POINT frame_l1a, 0, 68
        DEFINE_POINT frame_l1b, 205, 68
        DEFINE_POINT frame_l2a, 205, 68
        DEFINE_POINT frame_l2b, kDAWidth, 68
        DEFINE_POINT frame_l3a, 205, 0
        DEFINE_POINT frame_l3b, 205, kDAHeight

        DEFINE_RECT frame_rect, AS_WORD(-1), AS_WORD(-1), kDAWidth - 2, kDAHeight


;;; ============================================================

        .include "../lib/event_params.s"

last_mouse_pos: .tag    MGTK::Point

.params trackgoaway_params
clicked:        .byte   0
.endparams

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort

;;; ============================================================
;;; Desktop Pattern Editor Resources

kPatternEditX   = 22
kPatternEditY   = 6

kFatBitWidth            = 8
kFatBitWidthShift       = 3
kFatBitHeight           = 4
kFatBitHeightShift      = 2
        DEFINE_RECT_SZ fatbits_frame, kPatternEditX, kPatternEditY,  8 * kFatBitWidth + 1, 8 * kFatBitHeight + 1
        ;; For hit testing
        DEFINE_RECT_SZ fatbits_rect, kPatternEditX+1, kPatternEditY+1,  8 * kFatBitWidth - 1, 8 * kFatBitHeight - 1

        DEFINE_BUTTON pattern_button, kDAWindowId, res_string_label_pattern, "^D", kPatternEditX-10, kPatternEditY + 36, 180

kPreviewLeft    = kPatternEditX + 79
kPreviewTop     = kPatternEditY
kPreviewRight   = kPreviewLeft + 81
kPreviewBottom  = kPreviewTop + 33
kPreviewSpacing = kPreviewTop + 6

        DEFINE_RECT preview_rect, kPreviewLeft+1, kPreviewSpacing + 1, kPreviewRight - 1, kPreviewBottom - 1
        DEFINE_RECT preview_line, kPreviewLeft, kPreviewSpacing, kPreviewRight, kPreviewSpacing
        DEFINE_RECT preview_frame, kPreviewLeft, kPreviewTop, kPreviewRight, kPreviewBottom

kArrowWidth     = 6
kArrowHeight    = 5
kArrowInset     = 5

kRightArrowLeft         = kPreviewRight - kArrowInset - kArrowWidth
kRightArrowTop          = kPreviewTop+1
kRightArrowRight        = kRightArrowLeft + kArrowWidth - 1
kRightArrowBottom       = kRightArrowTop + kArrowHeight - 1

kLeftArrowLeft          = kPreviewLeft + kArrowInset + 1
kLeftArrowTop           = kPreviewTop + 1
kLeftArrowRight         = kLeftArrowLeft + kArrowWidth - 1
kLeftArrowBottom        = kLeftArrowTop + kArrowHeight - 1

.params larr_params
        DEFINE_POINT viewloc, kLeftArrowLeft, kLeftArrowTop
mapbits:        .addr   larr_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kArrowWidth-1, kArrowHeight-1
        REF_MAPINFO_MEMBERS
.endparams

.params rarr_params
        DEFINE_POINT viewloc, kRightArrowLeft, kRightArrowTop
mapbits:        .addr   rarr_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kArrowWidth-1, kArrowHeight-1
        REF_MAPINFO_MEMBERS
.endparams

        DEFINE_RECT larr_rect, kLeftArrowLeft-2, kLeftArrowTop, kLeftArrowRight+2, kLeftArrowBottom
        DEFINE_RECT rarr_rect, kRightArrowLeft-2, kRightArrowTop, kRightArrowRight+2, kRightArrowBottom

larr_bitmap:
        PIXELS  "....##"
        PIXELS  "..####"
        PIXELS  "######"
        PIXELS  "..####"
        PIXELS  "....##"
rarr_bitmap:
        PIXELS  "##...."
        PIXELS  "####.."
        PIXELS  "######"
        PIXELS  "####.."
        PIXELS  "##...."

        DEFINE_BUTTON rgb_color_button, kDAWindowId, res_string_label_rgb_color, res_string_shortcut_apple_1, kPatternEditX + 46, kPatternEditY + 50

;;; ============================================================
;;; Double-Click Speed Resources

kDblClickX      = 223
kDblClickY      = 6

        ;; Selected index (1-3, or 0 for 'no match')
dblclick_selection:
        .byte   1

        ;; Computed counter values
kDblClickSpeedTableSize = 3
dblclick_speed_table:
        .word   kDefaultDblClickSpeed * 1
        .word   kDefaultDblClickSpeed * 4
        .word   kDefaultDblClickSpeed * 16

        DEFINE_LABEL dblclick_speed, res_string_label_dblclick_speed, kDblClickX + 45, kDblClickY + 47

.params dblclick_params
        DEFINE_POINT viewloc, kDblClickX, kDblClickY
mapbits:        .addr   dblclick_bitmap
mapwidth:       .byte   8
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 53, 33
        REF_MAPINFO_MEMBERS
.endparams

        kNumArrows = 6
arrows_table:
        DEFINE_POINT dblclick_arrow_pos1, kDblClickX + 65, kDblClickY + 7
        DEFINE_POINT dblclick_arrow_pos2, kDblClickX + 65, kDblClickY + 22
        DEFINE_POINT dblclick_arrow_pos3, kDblClickX + 110, kDblClickY + 10
        DEFINE_POINT dblclick_arrow_pos4, kDblClickX + 110, kDblClickY + 22
        DEFINE_POINT dblclick_arrow_pos5, kDblClickX + 155, kDblClickY + 13
        DEFINE_POINT dblclick_arrow_pos6, kDblClickX + 155, kDblClickY + 22
        ASSERT_RECORD_TABLE_SIZE arrows_table, kNumArrows, .sizeof(MGTK::Point)

        DEFINE_BUTTON dblclick_button1, kDAWindowId,,, kDblClickX + 175, kDblClickY + 25
        DEFINE_BUTTON dblclick_button2, kDAWindowId,,, kDblClickX + 130, kDblClickY + 25
        DEFINE_BUTTON dblclick_button3, kDAWindowId,,, kDblClickX +  85, kDblClickY + 25

        DEFINE_LABEL dblclick_shortcut1, .sprintf("(%c4)", ::kGlyphOpenApple), kDblClickX +  85, kDblClickY + 22
        DEFINE_LABEL dblclick_shortcut2, .sprintf("(%c5)", ::kGlyphOpenApple), kDblClickX + 130, kDblClickY + 22
        DEFINE_LABEL dblclick_shortcut3, .sprintf("(%c6)", ::kGlyphOpenApple), kDblClickX + 175, kDblClickY + 22

dblclick_bitmap:
        PIXELS  "..........................##.........................."
        PIXELS  "..........................##.........................."
        PIXELS  "..........................##.........................."
        PIXELS  "..........................##.........................."
        PIXELS  "..........................##.........................."
        PIXELS  "..........................##.........................."
        PIXELS  "..........................##.........................."
        PIXELS  "..........................##.........................."
        PIXELS  "..........................##.........................."
        PIXELS  "......................................................"
        PIXELS  "........................######........................"
        PIXELS  "......................................................"
        PIXELS  "......................##########......................"
        PIXELS  "......................................................"
        PIXELS  "..................##################.................."
        PIXELS  "....###############................###############...."
        PIXELS  "..###............................................###.."
        PIXELS  "###................................................###"
        PIXELS  "##......######################################......##"
        PIXELS  "##......##..................................##......##"
        PIXELS  "##......##.............########.............##......##"
        PIXELS  "##......##..........####......####..........##......##"
        PIXELS  "##......##........###.##......##.###........##......##"
        PIXELS  "##......##.#.#.#.###..##......##..###.#.#.#.##......##"
        PIXELS  "##......##........##..##......##..##........##......##"
        PIXELS  "##......##........##..##......##..##........##......##"
        PIXELS  "##......##........##...########...##........##......##"
        PIXELS  "##......##........##..............##........##......##"
        PIXELS  "##......############..............############......##"
        PIXELS  "##................##..............##................##"
        PIXELS  "##................##..............##................##"
        PIXELS  "##................##..............##................##"
        PIXELS  "##................##..............##................##"
        PIXELS  "##................##..............##................##"


.params darrow_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   darr_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 16, 7
        REF_MAPINFO_MEMBERS
.endparams

darr_bitmap:
        PIXELS  ".....#######....."
        PIXELS  ".....#######....."
        PIXELS  ".....#######....."
        PIXELS  "#################"
        PIXELS  "..#############.."
        PIXELS  "....#########...."
        PIXELS  "......#####......"
        PIXELS  "........#........"

;;; ============================================================
;;; Mouse Tracking Resources

kMouseTrackingX = 25
kMouseTrackingY = 78

        DEFINE_LABEL mouse_tracking, res_string_label_mouse_tracking, kMouseTrackingX + 30, kMouseTrackingY + 45

        DEFINE_BUTTON tracking_slow_button, kDAWindowId, res_string_label_slow, res_string_shortcut_apple_2, kMouseTrackingX + 84, kMouseTrackingY + 8
        DEFINE_BUTTON tracking_fast_button, kDAWindowId, res_string_label_fast, res_string_shortcut_apple_3, kMouseTrackingX + 84, kMouseTrackingY + 21

.params mouse_tracking_params
        DEFINE_POINT viewloc, kMouseTrackingX + 5, kMouseTrackingY
mapbits:        .addr   mouse_tracking_bitmap
mapwidth:       .byte   9
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 62, 31
        REF_MAPINFO_MEMBERS
.endparams

mouse_tracking_bitmap:
        PIXELS  "......................##..##..##..######......................"
        PIXELS  "........................................##...................."
        PIXELS  "..........................................##.................."
        PIXELS  "..........................................##.................."
        PIXELS  ".............................................................."
        PIXELS  ".........................................####................."
        PIXELS  ".............................................................."
        PIXELS  ".....................................############............."
        PIXELS  "............................#########............#########...."
        PIXELS  "..........................##..............................##.."
        PIXELS  "............##..##..##..##....#..####################..#....##"
        PIXELS  "........................##...#...##................##...#...##"
        PIXELS  "...........##..##..###..##...#...##.#.#.#.#.#.#.#.###...#...##"
        PIXELS  "........................##...#...##................##...#...##"
        PIXELS  "..........##..##..####..##...#...##................##...#...##"
        PIXELS  "........................##...#...####################...#...##"
        PIXELS  ".........##..##..#####..##...#..........................#...##"
        PIXELS  "........................##...#..........................#...##"
        PIXELS  "........##..##..######..##...#..........................#...##"
        PIXELS  "........................##...#..........................#...##"
        PIXELS  ".......##..##..#######..##...#..........................#...##"
        PIXELS  "........................##...#..........................#...##"
        PIXELS  "......##..##..########..##...#..........................#...##"
        PIXELS  "........................##...#..........................#...##"
        PIXELS  "....##..##..##########..##...#..........................#...##"
        PIXELS  "........................##...#..........................#...##"
        PIXELS  "..##..##..############..##...#..........................#...##"
        PIXELS  "........................##...#..........................#...##"
        PIXELS  "##..##..##############..##...#..........................#...##"
        PIXELS  "........................##....##########################....##"
        PIXELS  "..........................##..............................##.."
        PIXELS  "............................##############################...."

.params scalemouse_params
x_exponent:     .byte   0
y_exponent:     .byte   0
.endparams

;;; ============================================================
;;; Caret Blink Speed Resources

kCaretBlinkDisplayX = 229
kCaretBlinkDisplayY = 85

        ;; Selected index (1-3, or 0 for 'no match')
caret_blink_selection:
        .byte   0

        DEFINE_LABEL caret_blink1, res_string_label_ipblink1, kCaretBlinkDisplayX-4, kCaretBlinkDisplayY + 11
        DEFINE_LABEL caret_blink2, res_string_label_ipblink2, kCaretBlinkDisplayX-4, kCaretBlinkDisplayY + 21
        DEFINE_LABEL caret_blink_slow, res_string_label_slow, kCaretBlinkDisplayX + 100, kCaretBlinkDisplayY + 34
        DEFINE_LABEL caret_blink_fast, res_string_label_fast, kCaretBlinkDisplayX + 189, kCaretBlinkDisplayY + 34

        DEFINE_LABEL caret_blink_button1_shortcut, .sprintf("(%c7)", ::kGlyphOpenApple), kCaretBlinkDisplayX + 100, kCaretBlinkDisplayY + 45
        DEFINE_LABEL caret_blink_button2_shortcut, .sprintf("(%c8)", ::kGlyphOpenApple), kCaretBlinkDisplayX + 144, kCaretBlinkDisplayY + 45
        DEFINE_LABEL caret_blink_button3_shortcut, .sprintf("(%c9)", ::kGlyphOpenApple), kCaretBlinkDisplayX + 189, kCaretBlinkDisplayY + 45

        DEFINE_BUTTON caret_blink_button1, kDAWindowId,,, kCaretBlinkDisplayX + 116, kCaretBlinkDisplayY + 16
        DEFINE_BUTTON caret_blink_button2, kDAWindowId,,, kCaretBlinkDisplayX + 136, kCaretBlinkDisplayY + 16
        DEFINE_BUTTON caret_blink_button3, kDAWindowId,,, kCaretBlinkDisplayX + 156, kCaretBlinkDisplayY + 16

.params caret_blink_bitmap_params
        DEFINE_POINT viewloc, kCaretBlinkDisplayX + 123, kCaretBlinkDisplayY
mapbits:        .addr   caret_blink_bitmap
mapwidth:       .byte   6
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 37, 12
        REF_MAPINFO_MEMBERS
.endparams

caret_blink_bitmap:
        PIXELS  "....##..............##..............##...."
        PIXELS  "....................##...................."
        PIXELS  "........##..........##..........##........"
        PIXELS  "....................##...................."
        PIXELS  "............##......##......##............"
        PIXELS  "....................##...................."
        PIXELS  "##..##..##..##......##......##..##..##..##"
        PIXELS  "....................##...................."
        PIXELS  "............##......##......##............"
        PIXELS  "....................##...................."
        PIXELS  "........##..........##..........##........"
        PIXELS  "....................##...................."
        PIXELS  "....##..............##..............##...."

kCaretBmpPosX = kCaretBlinkDisplayX + 143
kCaretBmpPosY = kCaretBlinkDisplayY
kCaretBmpWidth  = 2
kCaretBmpHeight = 13

.params caret_blink_bitmap_caret_params
        DEFINE_POINT viewloc, kCaretBmpPosX, kCaretBmpPosY
mapbits:        .addr   caret_blink_caret_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCaretBmpWidth - 1, kCaretBmpHeight - 1
        REF_MAPINFO_MEMBERS
.endparams
        DEFINE_RECT_SZ caret_blink_shield_params, kCaretBmpPosX, kCaretBmpPosY, kCaretBmpWidth, kCaretBmpHeight

caret_blink_caret_bitmap:
        PIXELS  "##"
        PIXELS  "##"
        PIXELS  "##"
        PIXELS  "##"
        PIXELS  "##"
        PIXELS  "##"
        PIXELS  "##"
        PIXELS  "##"
        PIXELS  "##"
        PIXELS  "##"
        PIXELS  "##"
        PIXELS  "##"
        PIXELS  "##"


;;; ============================================================

.proc Init
        jsr     InitPattern
        jsr     InitCaretBlink
        jsr     InitDblclick

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        jsr     DoCaretBlink
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        jsr     GetNextEvent

        cmp     #kEventKindMouseMoved
        beq     HandleMove

        cmp     #MGTK::EventKind::button_down
        jeq     HandleDown

        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        bne     InputLoop       ; always
.endproc ; InputLoop

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Exit

;;; ============================================================

.proc HandleMove
        ;; For warping the cursor after scaling change
        COPY_STRUCT event_params::coords, last_mouse_pos

        jmp     InputLoop
.endproc ; HandleMove

;;; ============================================================

.proc HandleKey
        lda     event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        beq     Exit

      IF A BETWEEN #'1', #'9'
        sec
        sbc     #'1'
        tax
        copylohi shortcut_table_addr_lo,x, shortcut_table_addr_hi,x, addr
        lda     shortcut_table_values,x
        addr := *+1
        jmp     SELF_MODIFIED
      END_IF

        jmp     InputLoop
    END_IF

        cmp     #CHAR_ESCAPE
        jeq     Exit

        cmp     #CHAR_LEFT
        jeq     HandleLArrClick

        cmp     #CHAR_RIGHT
        jeq     HandleRArrClick

    IF A = #CHAR_CTRL_D
        BTK_CALL BTK::Flash, pattern_button
        jmp     HandlePatternClick
    END_IF

        jmp     InputLoop


shortcut_table_values:
        .byte   0, 0, 1, 3, 2, 1, 1, 2, 3
shortcut_table_addr_lo:
        .byte   <HandleRGBClick, <HandleTrackingClick, <HandleTrackingClick, <HandleDblclickClick, <HandleDblclickClick, <HandleDblclickClick, <HandleCaretBlinkClick, <HandleCaretBlinkClick, <HandleCaretBlinkClick
shortcut_table_addr_hi:
        .byte   >HandleRGBClick, >HandleTrackingClick, >HandleTrackingClick, >HandleDblclickClick, >HandleDblclickClick, >HandleDblclickClick, >HandleCaretBlinkClick, >HandleCaretBlinkClick, >HandleCaretBlinkClick


.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        jne     InputLoop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        beq     HandleDrag
        cmp     #MGTK::Area::content
        beq     HandleClick
        jmp     InputLoop
.endproc ; HandleDown

;;; ============================================================

.proc HandleClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        jne     Exit
        jmp     InputLoop
.endproc ; HandleClose

;;; ============================================================

.proc HandleDrag
        copy8   #kDAWindowId, dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
    IF bit dragwindow_params::moved : NS
        ;; Draw DeskTop's windows and icons.
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow
    END_IF

        jmp     InputLoop
.endproc ; HandleDrag


;;; ============================================================

.proc HandleClick
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        ;; ----------------------------------------

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, fatbits_rect
        jne     HandleBitsClick

        MGTK_CALL MGTK::InRect, larr_rect
        jne     HandleLArrClick

        MGTK_CALL MGTK::InRect, rarr_rect
        jne     HandleRArrClick

        MGTK_CALL MGTK::InRect, preview_rect
        jne     HandlePatternClick

        MGTK_CALL MGTK::InRect, pattern_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, pattern_button
        jmi     InputLoop
        jmp     HandlePatternClick
    END_IF

        MGTK_CALL MGTK::InRect, rgb_color_button::rect
        jne     HandleRGBClick

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, dblclick_button1::rect
    IF NOT_ZERO
        TAIL_CALL HandleDblclickClick, A=#1
    END_IF

        MGTK_CALL MGTK::InRect, dblclick_button2::rect
    IF NOT_ZERO
        TAIL_CALL HandleDblclickClick, A=#2
    END_IF

        MGTK_CALL MGTK::InRect, dblclick_button3::rect
    IF NOT_ZERO
        TAIL_CALL HandleDblclickClick, A=#3
    END_IF

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, tracking_slow_button::rect
    IF NOT_ZERO
        TAIL_CALL HandleTrackingClick, A=#0
    END_IF

        MGTK_CALL MGTK::InRect, tracking_fast_button::rect
    IF NOT_ZERO
        TAIL_CALL HandleTrackingClick, A=#1
    END_IF

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, caret_blink_button1::rect
    IF NOT_ZERO
        TAIL_CALL HandleCaretBlinkClick, A=#1
    END_IF

        MGTK_CALL MGTK::InRect, caret_blink_button2::rect
    IF NOT_ZERO
        TAIL_CALL HandleCaretBlinkClick, A=#2
    END_IF

        MGTK_CALL MGTK::InRect, caret_blink_button3::rect
    IF NOT_ZERO
        TAIL_CALL HandleCaretBlinkClick, A=#3
    END_IF

        jmp     InputLoop
.endproc ; HandleClick

;;; ============================================================

.proc HandleRArrClick
        inc     pattern_index

        lda     pattern_index
    IF A >= #kPatternCount
        copy8   #0, pattern_index
    END_IF

        jmp     UpdatePattern
.endproc ; HandleRArrClick

.proc HandleLArrClick
        dec     pattern_index

    IF NEG
        copy8   #kPatternCount-1, pattern_index
    END_IF

        jmp     UpdatePattern
.endproc ; HandleLArrClick

.proc UpdatePattern
        ptr := $06
        lda     pattern_index
        asl
        tay
        copy16  patterns,y, ptr
        ldy     #7
    DO
        copy8   (ptr),y, pattern,y
    WHILE dey : POS

        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF ZERO                     ; not obscured
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::HideCursor
        jsr     DrawPreview
        jsr     DrawBits
        MGTK_CALL MGTK::ShowCursor
    END_IF

        jmp     InputLoop
.endproc ; UpdatePattern

;;; ============================================================

.proc HandleBitsClick
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport

        ;; Determine sense flag (0=clear, $FF=set)
        jsr     MapCoords
        ldx     screentowindow_params::windowx
        ldy     screentowindow_params::windowy

        stx     lastx
        sty     lasty

        lda     pattern,y
        and     mask1,x
        beq     :+
        lda     #0
        SKIP_NEXT_2_BYTE_INSTRUCTION
:       lda     #$FF
        sta     flag

        ;; Toggle pattern bit
    REPEAT
        ldx     screentowindow_params::windowx
        ldy     screentowindow_params::windowy
        lda     pattern,y
      IF bit flag : NS
        ora     mask1,x         ; set bit
      ELSE
        and     mask2,x         ; clear bit
      END_IF
        cmp     pattern,y       ; did it change?
      IF NE
        sta     pattern,y

        CALL    DrawBit, X=screentowindow_params::windowx, Y=screentowindow_params::windowy, A=flag

        jsr     DrawPreview
      END_IF

        ;; Repeat until mouse-up
      DO
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_up
        jeq     InputLoop

        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, fatbits_rect
        REDO_IF ZERO

        jsr     MapCoords
        ldx     screentowindow_params::windowx
        ldy     screentowindow_params::windowy
        BREAK_IF X <> lastx
      WHILE Y = lasty

        stx     lastx
        sty     lasty
    FOREVER

mask1:  .byte   1<<0, 1<<1, 1<<2, 1<<3, 1<<4, 1<<5, 1<<6, 1<<7
mask2:  .byte   AS_BYTE(~(1<<0)), AS_BYTE(~(1<<1)), AS_BYTE(~(1<<2)), AS_BYTE(~(1<<3)), AS_BYTE(~(1<<4)), AS_BYTE(~(1<<5)), AS_BYTE(~(1<<6)), AS_BYTE(~(1<<7))

flag:   .byte   0

lastx:  .byte   0
lasty:  .byte   0
.endproc ; HandleBitsClick

;;; Assumes click is within fatbits_rect
.proc MapCoords
        sub16   screentowindow_params::windowx, fatbits_rect::x1, screentowindow_params::windowx
        sub16   screentowindow_params::windowy, fatbits_rect::y1, screentowindow_params::windowy

        ldy     #kFatBitWidthShift
    DO
        lsr16   screentowindow_params::windowx
    WHILE dey : NOT_ZERO

        ldy     #kFatBitHeightShift
    DO
        lsr16   screentowindow_params::windowy
    WHILE dey : NOT_ZERO

        rts
.endproc ; MapCoords

;;; ============================================================

.proc InitDblclick
        CALL    ReadSettingWord, X=#DeskTopSettings::dblclick_speed
        stax    dblclick_speed

        ;; Find matching index in word table, or 0
        ldx     #kDblClickSpeedTableSize * 2
    DO
        ecmp16  dblclick_speed, dblclick_speed_table-2,x
      IF EQ
        ;; Found a match
        txa
        lsr                     ; /= 2
        sta     dblclick_selection
        rts
      END_IF

        dex
        dex
    WHILE POS
        copy8   #0, dblclick_selection ; not found
        rts

dblclick_speed: .word   0
.endproc ; InitDblclick

.proc HandleDblclickClick
        sta     dblclick_selection ; 1, 2 or 3
        asl                     ; *= 2
        tax
        dex
        dex                     ; 0, 2 or 4

        copy16  dblclick_speed_table,x, dblclick_speed

        CALL    WriteSetting, X=#DeskTopSettings::dblclick_speed, A=dblclick_speed
        CALL    WriteSetting, X=#DeskTopSettings::dblclick_speed+1, A=dblclick_speed+1

        jsr     MarkDirty

        jsr     UpdateDblclickButtons
        jmp     InputLoop

dblclick_speed: .word   0
.endproc ; HandleDblclickClick

;;; ============================================================

.proc HandleTrackingClick
        ;; --------------------------------------------------
        ;; Update Settings

        pha
        CALL    WriteSetting, X=#DeskTopSettings::mouse_tracking
        jsr     MarkDirty

        ;; --------------------------------------------------
        ;; Update MGTK

        copy8   #1, scalemouse_params::x_exponent
        copy8   #0, scalemouse_params::y_exponent

        ;; Doubled if option selected
        pla
    IF NOT_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
    END_IF

        ;; Also doubled if a IIc
        bit     ROMIN
        lda     ZIDBYTE
        bit     LCBANK1
        bit     LCBANK1
        cmp     #0              ; ZIDBYTE=0 for IIc / IIc+
    IF EQ
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
    END_IF

        MGTK_CALL MGTK::ScaleMouse, scalemouse_params

        ;; Set the cursor to the same position (c/o last move),
        ;; to avoid it warping due to the scale change.
        copy8   #MGTK::EventKind::no_event, event_params::kind
        COPY_STRUCT MGTK::Point, last_mouse_pos, event_params::coords
        MGTK_CALL MGTK::PostEvent, event_params

        ;; --------------------------------------------------
        ;; Update the UI

        jsr     UpdateTrackingButtons

        jmp     InputLoop
.endproc ; HandleTrackingClick

;;; ============================================================


.proc InitPattern
        ptr := $06

        MGTK_CALL MGTK::GetDeskPat, ptr
        ldy     #.sizeof(MGTK::Pattern)-1
    DO
        copy8   (ptr),y, pattern,y
    WHILE dey : POS
        rts
.endproc ; InitPattern

.proc HandlePatternClick
        MGTK_CALL MGTK::SetDeskPat, pattern

        ldx     #DeskTopSettings::pattern + .sizeof(MGTK::Pattern)-1
    DO
        CALL    WriteSetting, A=pattern - DeskTopSettings::pattern,x
    WHILE dex : X <> #AS_BYTE(DeskTopSettings::pattern-1)

        jsr     MarkDirty

        MGTK_CALL MGTK::RedrawDeskTop

        ;; Draw DeskTop's windows and icons.
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow

        jmp     InputLoop
.endproc ; HandlePatternClick

;;; ============================================================

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy


;;; ============================================================

.proc DrawWindow
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF NOT_ZERO         ; obscured

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        ;; ==============================
        ;; Frame

        MGTK_CALL MGTK::SetPenSize, frame_pensize
        MGTK_CALL MGTK::MoveTo, frame_l1a
        MGTK_CALL MGTK::LineTo, frame_l1b
        MGTK_CALL MGTK::MoveTo, frame_l2a
        MGTK_CALL MGTK::LineTo, frame_l2b
        MGTK_CALL MGTK::MoveTo, frame_l3a
        MGTK_CALL MGTK::LineTo, frame_l3b
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, winfo::penwidth

        ;; ==============================
        ;; Desktop Pattern

        BTK_CALL BTK::Draw, pattern_button

        MGTK_CALL MGTK::FrameRect, fatbits_frame
        MGTK_CALL MGTK::PaintBits, larr_params
        MGTK_CALL MGTK::PaintBits, rarr_params

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, preview_frame

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, preview_line

        jsr     DrawPreview
        jsr     DrawBits

        BTK_CALL BTK::CheckboxDraw, rgb_color_button
        jsr     UpdateRGBCheckbox

        ;; ==============================
        ;; Double-Click Speed

        MGTK_CALL MGTK::MoveTo, dblclick_speed_label_pos
        MGTK_CALL MGTK::DrawString, dblclick_speed_label_str

        ;; Arrows
.scope
        copy8   #0, arrow_num
        copy16  #arrows_table, addr
    DO
        ldy     #3
      DO
        addr := *+1
        lda     SELF_MODIFIED,y
        sta     darrow_params::viewloc,y
      WHILE dey : POS

        MGTK_CALL MGTK::PaintBits, darrow_params
        add16_8 addr, #.sizeof(MGTK::Point)
        inc     arrow_num
    WHILE lda arrow_num : A <> #kNumArrows
.endscope

        BTK_CALL BTK::RadioDraw, dblclick_button1
        BTK_CALL BTK::RadioDraw, dblclick_button2
        BTK_CALL BTK::RadioDraw, dblclick_button3

        CALL    ReadSetting, X=#DeskTopSettings::options
        and     #DeskTopSettings::kOptionsShowShortcuts
    IF NOT_ZERO
        MGTK_CALL MGTK::MoveTo, dblclick_shortcut1_label_pos
        MGTK_CALL MGTK::DrawString, dblclick_shortcut1_label_str
        MGTK_CALL MGTK::MoveTo, dblclick_shortcut2_label_pos
        MGTK_CALL MGTK::DrawString, dblclick_shortcut2_label_str
        MGTK_CALL MGTK::MoveTo, dblclick_shortcut3_label_pos
        MGTK_CALL MGTK::DrawString, dblclick_shortcut3_label_str
    END_IF


        jsr     UpdateDblclickButtons

        MGTK_CALL MGTK::PaintBits, dblclick_params

        ;; ==============================
        ;; Mouse Tracking Speed

        MGTK_CALL MGTK::MoveTo, mouse_tracking_label_pos
        MGTK_CALL MGTK::DrawString, mouse_tracking_label_str

        BTK_CALL BTK::RadioDraw, tracking_slow_button
        BTK_CALL BTK::RadioDraw, tracking_fast_button
        jsr     UpdateTrackingButtons

        MGTK_CALL MGTK::PaintBits, mouse_tracking_params

        ;; ==============================
        ;; Caret Blinking

        MGTK_CALL MGTK::MoveTo, caret_blink1_label_pos
        MGTK_CALL MGTK::DrawString, caret_blink1_label_str

        MGTK_CALL MGTK::MoveTo, caret_blink2_label_pos
        MGTK_CALL MGTK::DrawString, caret_blink2_label_str

        MGTK_CALL MGTK::PaintBits, caret_blink_bitmap_params

        MGTK_CALL MGTK::MoveTo, caret_blink_slow_label_pos
        MGTK_CALL MGTK::DrawString, caret_blink_slow_label_str

        MGTK_CALL MGTK::MoveTo, caret_blink_fast_label_pos
        CALL    DrawStringRight, AX=#caret_blink_fast_label_str

        BTK_CALL BTK::RadioDraw, caret_blink_button1
        BTK_CALL BTK::RadioDraw, caret_blink_button2
        BTK_CALL BTK::RadioDraw, caret_blink_button3
        jsr     UpdateCaretBlinkButtons

        CALL    ReadSetting, X=#DeskTopSettings::options
        and     #DeskTopSettings::kOptionsShowShortcuts
    IF NOT_ZERO
        MGTK_CALL MGTK::MoveTo, caret_blink_button1_shortcut_label_pos
        MGTK_CALL MGTK::DrawString, caret_blink_button1_shortcut_label_str
        MGTK_CALL MGTK::MoveTo, caret_blink_button2_shortcut_label_pos
        CALL    DrawStringCentered, AX=#caret_blink_button2_shortcut_label_str
        MGTK_CALL MGTK::MoveTo, caret_blink_button3_shortcut_label_pos
        CALL    DrawStringRight, AX=#caret_blink_button3_shortcut_label_str
    END_IF


        MGTK_CALL MGTK::ShowCursor
        rts

arrow_num:
        .byte   0

.endproc ; DrawWindow

.proc ZToButtonState
    IF NOT_ZERO
        RETURN  A=#BTK::kButtonStateNormal
    END_IF
        RETURN  A=#BTK::kButtonStateChecked
.endproc ; ZToButtonState

.proc UpdateDblclickButtons
        lda     dblclick_selection
        cmp     #1
        jsr     ZToButtonState
        sta     dblclick_button1::state
        BTK_CALL BTK::RadioUpdate, dblclick_button1

        lda     dblclick_selection
        cmp     #2
        jsr     ZToButtonState
        sta     dblclick_button2::state
        BTK_CALL BTK::RadioUpdate, dblclick_button2

        lda     dblclick_selection
        cmp     #3
        jsr     ZToButtonState
        sta     dblclick_button3::state
        BTK_CALL BTK::RadioUpdate, dblclick_button3

        rts
.endproc ; UpdateDblclickButtons

.proc UpdateTrackingButtons
        CALL    ReadSetting, X=#DeskTopSettings::mouse_tracking
        cmp     #0
        jsr     ZToButtonState
        sta     tracking_slow_button::state
        BTK_CALL BTK::RadioUpdate, tracking_slow_button

        CALL    ReadSetting, X=#DeskTopSettings::mouse_tracking
        cmp     #1
        jsr     ZToButtonState
        sta     tracking_fast_button::state
        BTK_CALL BTK::RadioUpdate, tracking_fast_button

        rts
.endproc ; UpdateTrackingButtons


.proc UpdateCaretBlinkButtons
        lda     caret_blink_selection
        cmp     #1
        jsr     ZToButtonState
        sta     caret_blink_button1::state
        BTK_CALL BTK::RadioUpdate, caret_blink_button1

        lda     caret_blink_selection
        cmp     #2
        jsr     ZToButtonState
        sta     caret_blink_button2::state
        BTK_CALL BTK::RadioUpdate, caret_blink_button2

        lda     caret_blink_selection
        cmp     #3
        jsr     ZToButtonState
        sta     caret_blink_button3::state
        BTK_CALL BTK::RadioUpdate, caret_blink_button3

        rts
.endproc ; UpdateCaretBlinkButtons

.proc UpdateRGBCheckbox
        CALL    ReadSetting, X=#DeskTopSettings::rgb_color
        and     #$80
        .assert BTK::kButtonStateChecked = $80, error, "const mismatch"
        sta     rgb_color_button::state
        BTK_CALL BTK::CheckboxUpdate, rgb_color_button
        rts
.endproc ; UpdateRGBCheckbox

;;; ============================================================

;;; Assert: called with GrafPort already selected
.proc DrawPreview

        COPY_BYTES 8, pattern, rotated_pattern

        ;; Offset c/o window position (mod 8 so 8-bit math okay)
        lda     winfo::viewloc::xcoord
        clc
        adc     #7
        and     #$07            ; pattern is 8 bits wide
        tay

    DO
        ldx     #7              ; 8 rows
      DO
        lda     rotated_pattern,x
        cmp     #$80
        rol     rotated_pattern,x
      WHILE dex : POS
    WHILE dey : POS

        ;; Draw it

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, rotated_pattern
        MGTK_CALL MGTK::PaintRect, preview_rect

        rts

rotated_pattern:
        .res    8
.endproc ; DrawPreview

;;; ============================================================

        DEFINE_RECT bitrect, 0, 0, 0, 0

;;; Assert: called with GrafPort already selected
.proc DrawBits

        ;; Perf: Filling rects is slightly faster than using large pens,
        ;; but 64 draw calls is still slow, ~1s to update fully at 1MHz

        MGTK_CALL MGTK::SetPattern, winfo::pattern
        copy8   #$FF, mode

        copy8   #0, ypos
        copy16  fatbits_rect::y1, bitrect::y1
        add16_8 bitrect::y1, #kFatBitHeight-1, bitrect::y2

yloop:  copy8   #0, xpos
        copy16  fatbits_rect::x1, bitrect::x1
        add16_8 bitrect::x1, #kFatBitWidth-1, bitrect::x2
        ldy     ypos
        copy8   pattern,y, row

xloop:  ror     row
        bcc     zero
        lda     #MGTK::pencopy
        SKIP_NEXT_2_BYTE_INSTRUCTION
        .assert MGTK::notpencopy <> $C0, error, "Bad BIT skip"
zero:   lda     #MGTK::notpencopy
    IF A <> mode
        sta     mode
        MGTK_CALL MGTK::SetPenMode, mode
    END_IF

        MGTK_CALL MGTK::PaintRect, bitrect

        ;; next x
        inc     xpos
    IF lda xpos : A <> #8
        add16_8 bitrect::x1, #kFatBitWidth
        add16_8 bitrect::x2, #kFatBitWidth
        jmp     xloop
    END_IF

        ;; next y
        inc     ypos
    IF lda ypos : A <> #8
        add16_8 bitrect::y1, #kFatBitHeight
        add16_8 bitrect::y2, #kFatBitHeight
        jmp     yloop
    END_IF

        rts

xpos:   .byte   0
ypos:   .byte   0
row:    .byte   0

mode:   .byte   0

.endproc ; DrawBits


;;; Input: A = set/clear X = x coord, Y = y coord
;;; Assert: called with GrafPort already selected
.proc DrawBit
        sta     mode

        stx     bitrect::x1
        sty     bitrect::y1
        lda     #0
        sta     bitrect::x1+1
        sta     bitrect::y1+1

        ldx     #kFatBitWidthShift
    DO
        asl16   bitrect::x1
    WHILE dex : NOT_ZERO

        ldx     #kFatBitHeightShift
    DO
        asl16   bitrect::y1
    WHILE dex : NOT_ZERO

        add16   bitrect::x1, fatbits_rect::x1, bitrect::x1
        add16_8 bitrect::x1, #kFatBitWidth-1, bitrect::x2
        add16   bitrect::y1, fatbits_rect::y1, bitrect::y1
        add16_8 bitrect::y1, #kFatBitHeight-1, bitrect::y2

        lda     #MGTK::pencopy
    IF bit mode : NC
        lda     #MGTK::notpencopy
    END_IF
        sta     mode

        MGTK_CALL MGTK::SetPattern, winfo::pattern
        MGTK_CALL MGTK::SetPenMode, mode
        MGTK_CALL MGTK::PaintRect, bitrect

        rts

mode:   .byte   0
.endproc ; DrawBit


;;; ============================================================

pattern:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

;;; The index of the pattern in the table below. We start with -1
;;; representing the current desktop pattern; either incrementing
;;; to 0 or decrementing (to a negative and wrapping) will start
;;; iterating through the table.
pattern_index:  .byte   AS_BYTE(-1)

kPatternCount = 15 + 14 + 1 ; 15 B&W patterns, 14 solid color patterns + 1
patterns:
        .addr pattern_checkerboard, pattern_dark, pattern_vdark, pattern_black
        .addr pattern_olives, pattern_scales, pattern_stripes
        .addr pattern_light, pattern_vlight, pattern_xlight, pattern_white
        .addr pattern_cane, pattern_brick, pattern_curvy, pattern_abrick
        .addr pattern_rainbow
        .addr pattern_c1, pattern_c2, pattern_c3, pattern_c4
        .addr pattern_c5, pattern_c6, pattern_c7, pattern_c8
        .addr pattern_c9, pattern_cA, pattern_cB, pattern_cC
        .addr pattern_cD, pattern_cE
        ASSERT_ADDRESS_TABLE_SIZE patterns, kPatternCount

pattern_checkerboard:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

pattern_dark:
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001

pattern_vdark:
        .byte   %10001000
        .byte   %00000000
        .byte   %00100010
        .byte   %00000000
        .byte   %10001000
        .byte   %00000000
        .byte   %00100010
        .byte   %00000000

pattern_black:
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000

pattern_olives:
        .byte   %00010001
        .byte   %01101110
        .byte   %00001110
        .byte   %00001110
        .byte   %00010001
        .byte   %11100110
        .byte   %11100000
        .byte   %11100000

pattern_scales:
        .byte   %11111110
        .byte   %11111110
        .byte   %01111101
        .byte   %10000011
        .byte   %11101111
        .byte   %11101111
        .byte   %11010111
        .byte   %00111000

pattern_stripes:
        .byte   %01110111
        .byte   %10111011
        .byte   %11011101
        .byte   %11101110
        .byte   %01110111
        .byte   %10111011
        .byte   %11011101
        .byte   %11101110

pattern_light:
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011

pattern_vlight:
        .byte   %11101110
        .byte   %11111111
        .byte   %10111011
        .byte   %11111111
        .byte   %11101110
        .byte   %11111111
        .byte   %10111011
        .byte   %11111111

pattern_xlight:
        .byte   %11111110
        .byte   %11111111
        .byte   %11101111
        .byte   %11111111
        .byte   %11111110
        .byte   %11111111
        .byte   %11101111
        .byte   %11111111

pattern_white:
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111

pattern_cane:
        .byte   %11100000
        .byte   %11010001
        .byte   %10111011
        .byte   %00011101
        .byte   %00001110
        .byte   %00010111
        .byte   %10111011
        .byte   %01110001

pattern_brick:
        .byte   %00000000
        .byte   %11111110
        .byte   %11111110
        .byte   %11111110
        .byte   %00000000
        .byte   %11101111
        .byte   %11101111
        .byte   %11101111

pattern_curvy:
        .byte   %00111111
        .byte   %11011110
        .byte   %11101101
        .byte   %11110011
        .byte   %11001111
        .byte   %10111111
        .byte   %01111111
        .byte   %01111111

pattern_abrick:
        .byte   %11101111
        .byte   %11000111
        .byte   %10111011
        .byte   %01111100
        .byte   %11111110
        .byte   %01111111
        .byte   %10111111
        .byte   %11011111

pattern_rainbow:
        .byte   $88     ; red
        .byte   $99     ; magenta
        .byte   $33     ; light blue
        .byte   $00     ; black
        .byte   $00     ; black
        .byte   $22     ; green
        .byte   $EE     ; yellow
        .byte   $CC     ; orange


        ;; Solid colors (note that nibbles are flipped)
pattern_c1:      .res 8, $88     ; 1 = red
pattern_c2:      .res 8, $44     ; 2 = brown
pattern_c3:      .res 8, $CC     ; 3 = orange
pattern_c4:      .res 8, $22     ; 4 = green
pattern_c5:      .res 8, $AA     ; 5 = gray1
pattern_c6:      .res 8, $66     ; 6 = light green
pattern_c7:      .res 8, $EE     ; 7 = yellow
pattern_c8:      .res 8, $11     ; 8 = blue
pattern_c9:      .res 8, $99     ; 9 = magenta
pattern_cA:      .res 8, $55     ; A = gray2
pattern_cB:      .res 8, $DD     ; B = pink
pattern_cC:      .res 8, $33     ; C = light blue
pattern_cD:      .res 8, $BB     ; D = lavender
pattern_cE:      .res 8, $77     ; E = aqua

;;; ============================================================
;;; Caret Blink

kCaretBlinkSpeedTableSize = 3

caret_blink_speed_table:
        .word   kDefaultCaretBlinkSpeed * 2
        .word   kDefaultCaretBlinkSpeed * 1
        .word   kDefaultCaretBlinkSpeed * 1/2

caret_blink_counter:
        .word   kDefaultCaretBlinkSpeed

.proc InitCaretBlink
        CALL    ReadSettingWord, X=#DeskTopSettings::caret_blink_speed
        stax    caret_blink_speed

        ;; Find matching index in word table, or 0
        ldx     #kCaretBlinkSpeedTableSize * 2
    DO
        ecmp16  caret_blink_speed, caret_blink_speed_table-2,x
      IF EQ
        ;; Found a match
        txa
        lsr                     ; /= 2
        sta     caret_blink_selection
        rts
      END_IF

        dex
        dex
    WHILE POS
        copy8   #0, caret_blink_selection ; not found
        rts

caret_blink_speed: .word   0
.endproc ; InitCaretBlink

.proc HandleCaretBlinkClick
        sta     caret_blink_selection ; 1, 2 or 3
        asl                     ; *= 2
        tax
        dex
        dex                     ; 0, 2 or 4

        copy16  caret_blink_speed_table,x, caret_blink_speed

        CALL    WriteSetting, X=#DeskTopSettings::caret_blink_speed, A=caret_blink_speed
        CALL    WriteSetting, X=#DeskTopSettings::caret_blink_speed+1, A=caret_blink_speed+1

        jsr     MarkDirty
        jsr     ResetCaretBlinkCounter

        jsr     UpdateCaretBlinkButtons
        jmp     InputLoop

caret_blink_speed: .word   0
.endproc ; HandleCaretBlinkClick

        .proc ResetCaretBlinkCounter
        CALL    ReadSettingWord, X=#DeskTopSettings::caret_blink_speed
        stax    caret_blink_counter
        rts
.endproc ; ResetCaretBlinkCounter


.proc DoCaretBlink
        dec16   caret_blink_counter
        lda     caret_blink_counter
        ora     caret_blink_counter+1
        bne     done

        jsr     ResetCaretBlinkCounter

        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     done            ; obscured
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::ShieldCursor, caret_blink_shield_params
        MGTK_CALL MGTK::PaintBits, caret_blink_bitmap_caret_params
        MGTK_CALL MGTK::UnshieldCursor

done:   rts

.endproc ; DoCaretBlink

;;; ============================================================

.proc HandleRGBClick
        CALL    ReadSetting, X=#DeskTopSettings::rgb_color
        eor     #$80
        jsr     WriteSetting
        jsr     MarkDirty

        jsr     UpdateRGBCheckbox

        JSR_TO_MAIN JUMP_TABLE_RGB_MODE

        jmp     InputLoop
.endproc ; HandleRGBClick

;;; ============================================================

.proc DrawStringRight
        params := $06
        str := params
        width := params+2

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params
        sub16   #0, width, params+MGTK::Point::xcoord
        copy16  #0, params+MGTK::Point::ycoord
        MGTK_CALL MGTK::Move, params
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawStringRight

.proc DrawStringCentered
        params := $06
        str := params
        width := params+2

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params
        lsr16   width
        sub16   #0, width, params+MGTK::Point::xcoord
        copy16  #0, params+MGTK::Point::ycoord
        MGTK_CALL MGTK::Move, params
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawStringCentered

;;; ============================================================

;;; Input: X = `DeskTopSettings::*`
;;; Output: A,X = word

.proc ReadSettingWord
        jsr     ReadSetting
        pha
        inx                     ; `ReadSetting` preserves X
        jsr     ReadSetting
        tax
        pla
        rts
.endproc ; ReadSettingWord

;;; ============================================================

        .include "../lib/uppercase.s"
        .include "../lib/get_next_event.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        JSR_TO_AUX aux::RunDA
        bmi     SaveSettings
        rts

        .include "../lib/save_settings.s"
        .assert * < write_buffer, error, .sprintf("DA too big (at $%X)", *)

        DA_END_MAIN_SEGMENT

;;; ============================================================
