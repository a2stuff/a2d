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
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry

;;; ============================================================

        .org DA_LOAD_ADDRESS

da_start:

;;; Copy the DA to AUX for easy bank switching
.scope
        copy16  #da_start, STARTLO
        copy16  #da_end, ENDLO
        copy16  #da_start, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
.endscope

.scope
        ;; run the DA
        sta     RAMRDON         ; Run from Aux
        sta     RAMWRTON
        jsr     Init

        ;; tear down/exit
        lda     dialog_result
        sta     RAMRDOFF        ; Back to Main
        sta     RAMWRTOFF

        ;; Save settings if dirty
        jmi     SaveSettings
        rts

.endscope

;;; ============================================================

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
mincontlength:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontlength:  .word   kDAHeight
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
        mx := screentowindow_params::window::xcoord
        my := screentowindow_params::window::ycoord

grafport:       .tag    MGTK::GrafPort


;;; ============================================================
;;; Common Resources

kCheckboxWidth       = 17
kCheckboxHeight      = 8

.params checked_cb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   checked_cb_bitmap
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

kCheckboxLabelOffsetX = kCheckboxWidth + 5
kCheckboxLabelOffsetY = kCheckboxHeight + 1

;;; ============================================================


        kRamCardX = 10
        kRamCardY = 10

        DEFINE_LABEL ramcard, res_string_label_ramcard, kRamCardX + kCheckboxLabelOffsetX, kRamCardY + kCheckboxLabelOffsetY
        DEFINE_RECT_SZ rect_ramcard, kRamCardX, kRamCardY, kCheckboxWidth, kCheckboxHeight
        DEFINE_RECT_SZ rect_ramcard_click, kRamCardX, kRamCardY, kCheckboxLabelOffsetX, kCheckboxHeight

;;; ============================================================


        kSelectorX = 10
        kSelectorY = 21

        DEFINE_LABEL selector, res_string_label_selector, kSelectorX + kCheckboxLabelOffsetX, kSelectorY + kCheckboxLabelOffsetY
        DEFINE_RECT_SZ rect_selector, kSelectorX, kSelectorY, kCheckboxWidth, kCheckboxHeight
        DEFINE_RECT_SZ rect_selector_click, kSelectorX, kSelectorY, kCheckboxLabelOffsetX, kCheckboxHeight

;;; ============================================================

.proc Init
        param_call MeasureString, ramcard_label_str
        addax   rect_ramcard_click::x2
        param_call MeasureString, selector_label_str
        addax   rect_selector_click::x2

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc

.proc InputLoop
        jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        jmp     InputLoop
.endproc

.proc YieldLoop
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_YIELD_LOOP
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

.proc ClearUpdates
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_CLEAR_UPDATES
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo
        jmp     ClearUpdates
.endproc

;;; ============================================================

.proc HandleKey
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     Exit
        bne     InputLoop
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
        jsr     ClearUpdates

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

        MGTK_CALL MGTK::InRect, rect_ramcard_click
        cmp     #MGTK::inrect_inside
        IF_EQ
        jmp     HandleRamcardClick
        END_IF

        MGTK_CALL MGTK::InRect, rect_selector_click
        cmp     #MGTK::inrect_inside
        IF_EQ
        jmp     HandleSelectorClick
        END_IF

        ;; ----------------------------------------

        jmp     InputLoop
.endproc


;;; ============================================================

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy


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

        MGTK_CALL MGTK::MoveTo, ramcard_label_pos
        param_call DrawString, ramcard_label_str

        ldax    #rect_ramcard
        ldy     #DeskTopSettings::kStartupSkipRAMCard
        jsr     GetBit
        jsr     DrawCheckbox

        ;; --------------------------------------------------

        MGTK_CALL MGTK::MoveTo, selector_label_pos
        param_call DrawString, selector_label_str

        ldax    #rect_selector
        ldy     #DeskTopSettings::kStartupSkipSelector
        jsr     GetBit
        jsr     DrawCheckbox

        ;; --------------------------------------------------

        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; Inputs: Y = bit to read from DeskTopSettings::startup
;;; Outputs: Z = bit set
;;; Note: A,X untouched
.proc GetBit
        pha
        tya
        and     SETTINGS + DeskTopSettings::startup
        tay
        pla
        sty     tmp
        ldy     tmp
        rts

tmp:    .byte   0
.endproc

;;; A,X = pos ptr, Z = checked
.proc DrawCheckbox
        ptr := $06

        stax    ptr
        php
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::HideCursor
        plp
        beq     checked

unchecked:
        ldy     #3
:       lda     (ptr),y
        sta     unchecked_cb_params::viewloc,y
        dey
        bpl     :-
        MGTK_CALL MGTK::PaintBits, unchecked_cb_params
        jmp     finish

checked:
        ldy     #3
:       lda     (ptr),y
        sta     checked_cb_params::viewloc,y
        dey
        bpl     :-
        MGTK_CALL MGTK::PaintBits, checked_cb_params


finish: MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

.proc HandleRamcardClick
        lda     SETTINGS + DeskTopSettings::startup
        eor     #DeskTopSettings::kStartupSkipRAMCard
        sta     SETTINGS + DeskTopSettings::startup

        MGTK_CALL MGTK::SetPenMode, notpencopy
        ldax    #rect_ramcard
        ldy     #DeskTopSettings::kStartupSkipRAMCard
        jsr     GetBit
        jsr     DrawCheckbox

        jsr     MarkDirty
        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleSelectorClick
        lda     SETTINGS + DeskTopSettings::startup
        eor     #DeskTopSettings::kStartupSkipSelector
        sta     SETTINGS + DeskTopSettings::startup

        MGTK_CALL MGTK::SetPenMode, notpencopy
        ldax    #rect_selector
        ldy     #DeskTopSettings::kStartupSkipSelector
        jsr     GetBit
        jsr     DrawCheckbox

        jsr     MarkDirty
        jmp     InputLoop
.endproc

;;; ============================================================

        .include "../lib/save_settings.s"
        .include "../lib/drawstring.s"
        .include "../lib/measurestring.s"

;;; ============================================================

da_end  := *
.assert * < WINDOW_ENTRY_TABLES, error, .sprintf("DA too big (at $%X)", *)
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00

;;; ============================================================
