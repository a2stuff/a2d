;;; ============================================================
;;; STARTUP - Desk Accessory
;;;
;;; A control panel offering startup settings:
;;;   * Copy to RAMCard on startup
;;;   * Start Selector if present
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "startup.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry
        BTKEntry := BTKAuxEntry

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
        lda     dialog_result
        rts
.endproc

;;; High bit set when anything changes.
dialog_result:
        .byte   0

.proc MarkDirty
        lda     #$80
        ora     dialog_result
        sta     dialog_result
        rts
.endproc

;;; ============================================================

kDAWindowId     = 62
kDAWidth        = 300
kDAHeight       = 100
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

str_title:
        PASCAL_STRING res_string_window_title ; window title

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
textback:       .byte   $7F
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

        kRamCardX = 10
        kRamCardY = 10

        DEFINE_BUTTON ramcard_rec, kDAWindowId, res_string_label_ramcard,, kRamCardX, kRamCardY
        DEFINE_BUTTON_PARAMS ramcard_params, ramcard_rec

;;; ============================================================

        kSelectorX = 10
        kSelectorY = 21

        DEFINE_BUTTON selector_rec, kDAWindowId, res_string_label_selector,, kSelectorX, kSelectorY
        DEFINE_BUTTON_PARAMS selector_params, selector_rec

;;; ============================================================

.proc Init
        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_YIELD_LOOP
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        jmp     InputLoop
.endproc

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc

;;; ============================================================

.proc HandleKey
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     Exit
        bne     InputLoop       ; always
.endproc

;;; ============================================================

.proc HandleDown
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     winfo::window_id
        bne     InputLoop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        beq     HandleDrag
        cmp     #MGTK::Area::content
        beq     HandleClick
        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        bne     Exit
        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleDrag
        copy    winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
common: bit     dragwindow_params::moved
        bpl     :+

        ;; Draw DeskTop's windows and icons.
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow

:       jmp     InputLoop

.endproc

;;; ============================================================

.proc HandleClick
        copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, ramcard_rec::rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        jmp     HandleRamcardClick
        END_IF

        MGTK_CALL MGTK::InRect, selector_rec::rect
        cmp     #MGTK::inrect_inside
        IF_EQ
        jmp     HandleSelectorClick
        END_IF

        ;; ----------------------------------------

        jmp     InputLoop
.endproc

;;; ============================================================

.proc DrawWindow
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        IF_EQ
        rts
        END_IF

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        ;; --------------------------------------------------

        lda     #DeskTopSettings::kStartupSkipRAMCard
        jsr     GetBit
        sta     ramcard_rec::state
        BTK_CALL BTK::CheckboxDraw, ramcard_params

        ;; --------------------------------------------------

        lda     #DeskTopSettings::kStartupSkipSelector
        jsr     GetBit
        sta     selector_rec::state
        BTK_CALL BTK::CheckboxDraw, selector_params

        ;; --------------------------------------------------

        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; Inputs: A = bit to read from DeskTopSettings::startup
;;; Outputs: A = $80 if set, $00 if unset
.proc GetBit
        and     SETTINGS + DeskTopSettings::startup
        beq     set
        lda     #0
        rts

set:    lda     #$80
        rts
.endproc

;;; ============================================================

.proc HandleRamcardClick
        lda     SETTINGS + DeskTopSettings::startup
        eor     #DeskTopSettings::kStartupSkipRAMCard
        sta     SETTINGS + DeskTopSettings::startup

        lda     #DeskTopSettings::kStartupSkipRAMCard
        jsr     GetBit
        sta     ramcard_rec::state
        BTK_CALL BTK::CheckboxUpdate, ramcard_params

        jsr     MarkDirty
        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleSelectorClick
        lda     SETTINGS + DeskTopSettings::startup
        eor     #DeskTopSettings::kStartupSkipSelector
        sta     SETTINGS + DeskTopSettings::startup

        lda     #DeskTopSettings::kStartupSkipSelector
        jsr     GetBit
        sta     selector_rec::state
        BTK_CALL BTK::CheckboxUpdate, selector_params

        jsr     MarkDirty
        jmp     InputLoop
.endproc

;;; ============================================================

        .include "../lib/drawstring.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        JSR_TO_AUX RunDA
        bmi     SaveSettings
        rts

        .include "../lib/save_settings.s"
        .assert * < write_buffer, error, .sprintf("DA too big (at $%X)", *)

        DA_END_MAIN_SEGMENT

;;; ============================================================
