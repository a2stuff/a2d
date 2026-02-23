;;; ============================================================
;;; OPTIONS - Desk Accessory
;;;
;;; A control panel offering option settings:
;;;   * Copy to RAMCard on startup
;;;   * Start Selector if present
;;;   * Show shortcuts for buttons
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "options.res"

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
kDAWidth        = 375
kDAHeight       = 100
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
kButtonLeft     = 10
kButtonTop      = 10
kButtonSpacing  = kSystemFontHeight + 2

        DEFINE_BUTTON ramcard_button, kDAWindowId, res_string_label_ramcard, res_string_shortcut_apple_1, kButtonLeft, kButtonTop + kButtonSpacing * 0

        DEFINE_BUTTON selector_button, kDAWindowId, res_string_label_selector, res_string_shortcut_apple_2, kButtonLeft, kButtonTop + kButtonSpacing * 1

        DEFINE_BUTTON shortcuts_button, kDAWindowId, res_string_label_shortcuts, res_string_shortcut_apple_3, kButtonLeft, kButtonTop + kButtonSpacing * 2

        DEFINE_BUTTON casebits_button, kDAWindowId, res_string_label_case, res_string_shortcut_apple_4, kButtonLeft, kButtonTop + kButtonSpacing * 3

        DEFINE_BUTTON invisible_button, kDAWindowId, res_string_label_invisible, res_string_shortcut_apple_5, kButtonLeft, kButtonTop + kButtonSpacing * 4

        DEFINE_BUTTON check525_button, kDAWindowId, "Check 5.25\" drives on startup", res_string_shortcut_apple_6, kButtonLeft, kButtonTop + kButtonSpacing * 5

button_button_table:
        .addr   ramcard_button, selector_button, shortcuts_button, casebits_button, invisible_button, check525_button
        ASSERT_ADDRESS_TABLE_SIZE button_button_table, kNumButtons

;;; Which bit in DeskTopSettings::options this checkbox corresponds to
button_mask_table:
        .byte   DeskTopSettings::kOptionsSkipRAMCard, DeskTopSettings::kOptionsSkipSelector, DeskTopSettings::kOptionsShowShortcuts, DeskTopSettings::kOptionsSetCaseBits, DeskTopSettings::kOptionsShowInvisible, DeskTopSettings::kOptionsSkipCheck525
        ASSERT_TABLE_SIZE button_mask_table, kNumButtons

;;; For inverting the sense of a bit vs. its checkbox; high bit set to invert
button_eor_table:
        .byte   0, 0, BTK::kButtonStateChecked, BTK::kButtonStateChecked, BTK::kButtonStateChecked, 0
        ASSERT_TABLE_SIZE button_eor_table, kNumButtons


;;; ============================================================

.proc Init
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
common:
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

        copy8   #kNumButtons-1, index
    DO
        index := *+1
        lda     #SELF_MODIFIED_BYTE
        asl
        tax
        copy16  button_button_table,x, rec_addr
        copy16  button_button_table,x, params_addr

        ldx     index
        CALL    GetBit, A=button_mask_table,x
        ldx     index
        eor     button_eor_table,x

        ldy     #BTK::ButtonRecord::state
        rec_addr := *+1
        sta     SELF_MODIFIED,y

        BTK_CALL BTK::CheckboxDraw, SELF_MODIFIED, params_addr

        dec     index
    WHILE POS

        ;; --------------------------------------------------

        MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; DrawWindow

;;; Inputs: A = bit to read from DeskTopSettings::options
;;; Outputs: A = $80 if set, $00 if unset
ASSERT_EQUALS BTK::kButtonStateNormal, $00
ASSERT_EQUALS BTK::kButtonStateChecked, $80
.proc GetBit
        sta     mask
        CALL    ReadSetting, X=#DeskTopSettings::options
        mask := *+1
        and     #SELF_MODIFIED_BYTE
        beq     set
        RETURN  A=#0

set:    RETURN  A=#$80
.endproc ; GetBit

;;; ============================================================

.proc ToggleButton
        sta     index

        asl
        tay
        ldax    button_button_table,y
        stax    rec_addr
        stax    params_addr

        CALL    ReadSetting, X=#DeskTopSettings::options
        ldx     index
        eor     button_mask_table,x
        CALL    WriteSetting, X=#DeskTopSettings::options

        ldx     index
        CALL    GetBit, A=button_mask_table,x
        ldx     index
        eor     button_eor_table,x

        ldy     #BTK::ButtonRecord::state
        rec_addr := *+1
        sta     SELF_MODIFIED,y

        BTK_CALL BTK::CheckboxUpdate, SELF_MODIFIED, params_addr

        jsr     MarkDirty
        jmp     InputLoop

index:  .byte   0
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
