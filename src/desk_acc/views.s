;;; ============================================================
;;; VIEWS - Desk Accessory
;;;
;;; A control panel offering option settings:
;;;   * Initial view style
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "views.res"

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
kDAWidth        = 200
kDAHeight       = 90
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
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams


;;; ============================================================


.params event_params
kind:  .byte   0
;;; EventKind::key_down
key             := *
modifiers       := * + 1
;;; EventKind::update
window_id       := *
;;; otherwise
xcoord          := *
ycoord          := * + 2
        .res    4
.endparams

.params findwindow_params
mousex:         .word   0
mousey:         .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams

.params trackgoaway_params
clicked:        .byte   0
.endparams

.params dragwindow_params
window_id:      .byte   0
dragx:          .word   0
dragy:          .word   0
moved:          .byte   0
.endparams

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

.params screentowindow_params
window_id:      .byte   kDAWindowId
        DEFINE_POINT screen, 0, 0
        DEFINE_POINT window, 0, 0
.endparams

grafport:       .tag    MGTK::GrafPort


;;; ============================================================

kNumButtons     = 6
kButtonLeft     = 20
kButtonTop      = 5
kButtonSpacing  = kSystemFontHeight + 2

        DEFINE_LABEL view_style, res_string_initial_view, kButtonLeft - 3, kButtonTop + kSystemFontHeight

        DEFINE_BUTTON as_icons_radiobutton, kDAWindowId, res_string_radio_button_by_icon, res_string_shortcut_apple_1, kButtonLeft, kButtonTop + kButtonSpacing * 1
        DEFINE_BUTTON as_smallicons_radiobutton, kDAWindowId, res_string_radio_button_by_small_icon, res_string_shortcut_apple_2, kButtonLeft, kButtonTop + kButtonSpacing * 2
        DEFINE_BUTTON by_name_radiobutton, kDAWindowId, res_string_radio_button_by_name, res_string_shortcut_apple_3, kButtonLeft, kButtonTop + kButtonSpacing * 3
        DEFINE_BUTTON by_date_radiobutton, kDAWindowId, res_string_radio_button_by_date, res_string_shortcut_apple_4, kButtonLeft, kButtonTop + kButtonSpacing * 4
        DEFINE_BUTTON by_size_radiobutton, kDAWindowId, res_string_radio_button_by_size, res_string_shortcut_apple_5, kButtonLeft, kButtonTop + kButtonSpacing * 5
        DEFINE_BUTTON by_type_radiobutton, kDAWindowId, res_string_radio_button_by_type, res_string_shortcut_apple_6, kButtonLeft, kButtonTop + kButtonSpacing * 6

button_button_table:
        .addr as_icons_radiobutton
        .addr as_smallicons_radiobutton
        .addr by_name_radiobutton
        .addr by_date_radiobutton
        .addr by_size_radiobutton
        .addr by_type_radiobutton
        ASSERT_ADDRESS_TABLE_SIZE button_button_table, kNumButtons


;;; ============================================================

current_view_index:
        .byte   0

        ;; Index to DeskTopSettings::kViewByXYZ value
view_by_table:
        .byte   DeskTopSettings::kViewByIcon
        .byte   DeskTopSettings::kViewBySmallIcon
        .byte   DeskTopSettings::kViewByName
        .byte   DeskTopSettings::kViewByDate
        .byte   DeskTopSettings::kViewBySize
        .byte   DeskTopSettings::kViewByType

;;; ============================================================

.proc Init
        CALL    ReadSetting, X=#DeskTopSettings::default_view
        and     #DeskTopSettings::kViewByIndexMask
        sta     current_view_index

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        jmp     InputLoop
.endproc ; InputLoop

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Exit

;;; ============================================================

.proc HandleKey
        lda     event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        beq     Exit

        ;; Digit key?
        cmp     #'1'
        bcc     InputLoop
        cmp     #'1'+kNumButtons
        bcs     InputLoop

        sec
        sbc     #'1'            ; ASCII -> index

        jmp     ToggleButton
    END_IF

        ;; no modifiers
        cmp     #CHAR_ESCAPE
        beq     Exit
        bne     InputLoop       ; always
.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        bne     InputLoop
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
        bne     Exit
        jmp     InputLoop
.endproc ; HandleClose

;;; ============================================================

.proc HandleDrag
        copy8   #kDAWindowId, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
common: bit     dragwindow_params::moved
    IF NS
        ;; Draw DeskTop's windows and icons.
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow
    END_IF

        jmp     InputLoop

.endproc ; HandleDrag

;;; ============================================================

.proc HandleClick
        copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; ----------------------------------------

        ;; Check all the button rects
        copy8   #kNumButtons-1, index
    DO
        index := *+1
        lda     #SELF_MODIFIED_BYTE
        asl
        tax
        copy16  button_button_table,x, rect_addr
        add16_8 rect_addr, #BTK::ButtonRecord::rect

        MGTK_CALL MGTK::InRect, SELF_MODIFIED, rect_addr
      IF NOT_ZERO

        TAIL_CALL ToggleButton, A=index
      END_IF
    WHILE dec index : POS

        ;; ----------------------------------------

        jmp     InputLoop
.endproc ; HandleClick

;;; ============================================================

.proc DrawWindow
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF A = #MGTK::Error::window_obscured

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        ;; --------------------------------------------------

        MGTK_CALL MGTK::MoveTo, view_style_label_pos
        MGTK_CALL MGTK::DrawString, view_style_label_str

        copy8   #kNumButtons-1, index
    DO
        index := *+1
        lda     #SELF_MODIFIED_BYTE
        asl
        tax
        copy16  button_button_table,x, rec_addr
        copy16  button_button_table,x, params_addr

        lda     #BTK::kButtonStateNormal
      IF ldx current_view_index : X = index
        lda     #BTK::kButtonStateChecked
      END_IF

        ldy     #BTK::ButtonRecord::state
        rec_addr := *+1
        sta     SELF_MODIFIED,y

        BTK_CALL BTK::RadioDraw, SELF_MODIFIED, params_addr

    WHILE dec index : POS

        ;; --------------------------------------------------

        MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; DrawWindow

;;; ============================================================

.proc ToggleButton
        cmp     current_view_index
        jeq     InputLoop

        pha                     ; A = new index
        lda     current_view_index

.scope
        asl
        tay
        ldax    button_button_table,y
        stax    rec_addr
        stax    params_addr

        ldy     #BTK::ButtonRecord::state
        lda     #BTK::kButtonStateNormal
        rec_addr := *+1
        sta     SELF_MODIFIED,y
        BTK_CALL BTK::RadioUpdate, SELF_MODIFIED, params_addr
.endscope

        pla                     ; A = new index
        sta     current_view_index

.scope
        asl
        tay
        ldax    button_button_table,y
        stax    rec_addr
        stax    params_addr

        ldy     #BTK::ButtonRecord::state
        lda     #BTK::kButtonStateChecked
        rec_addr := *+1
        sta     SELF_MODIFIED,y
        BTK_CALL BTK::RadioUpdate, SELF_MODIFIED, params_addr
.endscope

        ldx     current_view_index
        CALL    WriteSetting, A=view_by_table,x, X=#DeskTopSettings::default_view
        jsr     MarkDirty

        jmp     InputLoop
.endproc ; ToggleButton

;;; ============================================================

        .include "../lib/uppercase.s"

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
