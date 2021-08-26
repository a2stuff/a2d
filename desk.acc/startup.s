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
        jsr     init

        ;; tear down/exit
        sta     RAMRDOFF        ; Back to Main
        sta     RAMWRTOFF

        jsr     save_settings

        rts
.endscope

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
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams


;;; ============================================================


.params event_params
kind:  .byte   0
;;; event_kind_key_down
key             := *
modifiers       := * + 1
;;; event_kind_update
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

.params winport_params
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

.params grafport
        DEFINE_POINT viewloc, 0, 0
mapbits:        .word   0
mapwidth:       .byte   0
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 0, 0
pattern:        .res    8, 0
colormasks:     .byte   0, 0
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textback:       .byte   0
textfont:       .addr   0
.endparams


;;; ============================================================
;;; Common Resources

kCheckboxWidth       = 17
kCheckboxHeight      = 8

.params checked_cb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   checked_cb_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, kCheckboxWidth, kCheckboxHeight
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
        DEFINE_RECT cliprect, 0, 0, kCheckboxWidth, kCheckboxHeight
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

;;; ============================================================


        kSelectorX = 10
        kSelectorY = 21

        DEFINE_LABEL selector, res_string_label_selector, kSelectorX + kCheckboxLabelOffsetX, kSelectorY + kCheckboxLabelOffsetY
        DEFINE_RECT_SZ rect_selector, kSelectorX, kSelectorY, kCheckboxWidth, kCheckboxHeight

;;; ============================================================

.proc init
        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     draw_window
        MGTK_CALL MGTK::FlushEvents
        ;; fall through
.endproc

.proc input_loop
        jsr     yield_loop
        MGTK_CALL MGTK::GetEvent, event_params
        bne     exit
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     handle_down
        cmp     #MGTK::EventKind::key_down
        beq     handle_key

        jmp     input_loop
.endproc

.proc yield_loop
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_YIELD_LOOP
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

.proc exit
        MGTK_CALL MGTK::CloseWindow, winfo
        rts
.endproc

;;; ============================================================

.proc handle_key
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     exit
        bne     input_loop
.endproc

;;; ============================================================

.proc handle_down
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        bne     exit
        lda     findwindow_params::window_id
        cmp     winfo::window_id
        bne     input_loop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     handle_close
        cmp     #MGTK::Area::dragbar
        beq     handle_drag
        cmp     #MGTK::Area::content
        beq     handle_click
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_close
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        bne     exit
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_drag
        copy    winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
common: bit     dragwindow_params::moved
        bpl     :+

        ;; Draw DeskTop's windows and icons.
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_CLEAR_UPDATES_REDRAW_ICONS
        sta     RAMRDON
        sta     RAMWRTON

        ;; Draw DA's window
        jsr     draw_window

:       jmp     input_loop

.endproc


;;; ============================================================

.proc handle_click
        copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, rect_ramcard
        cmp     #MGTK::inrect_inside
        IF_EQ
        jmp     handle_ramcard_click
        END_IF

        MGTK_CALL MGTK::InRect, rect_selector
        cmp     #MGTK::inrect_inside
        IF_EQ
        jmp     handle_selector_click
        END_IF

        ;; ----------------------------------------

        jmp     input_loop
.endproc


;;; ============================================================

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy


;;; ============================================================

.proc draw_window
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, winport_params
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
        bit     SETTINGS + DeskTopSettings::startup_ramcard
        jsr     draw_checkbox

        ;; --------------------------------------------------

        MGTK_CALL MGTK::MoveTo, selector_label_pos
        param_call DrawString, selector_label_str

        ldax    #rect_selector
        bit     SETTINGS + DeskTopSettings::startup_selector
        jsr     draw_checkbox

        ;; --------------------------------------------------

        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; A,X = pos ptr, N = unchecked
.proc draw_checkbox
        ptr := $06

        stax    ptr
        php
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::HideCursor
        plp
        bpl     checked

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

.proc handle_ramcard_click
        lda     SETTINGS + DeskTopSettings::startup_ramcard
        eor     #$80
        sta     SETTINGS + DeskTopSettings::startup_ramcard

        MGTK_CALL MGTK::SetPenMode, notpencopy
        ldax    #rect_ramcard
        bit     SETTINGS + DeskTopSettings::startup_ramcard
        jsr     draw_checkbox

        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_selector_click
        lda     SETTINGS + DeskTopSettings::startup_selector
        eor     #$80
        sta     SETTINGS + DeskTopSettings::startup_selector

        MGTK_CALL MGTK::SetPenMode, notpencopy
        ldax    #rect_selector
        bit     SETTINGS + DeskTopSettings::startup_selector
        jsr     draw_checkbox

        jmp     input_loop
.endproc

;;; ============================================================
;;; Save Settings

filename:
        PASCAL_STRING kFilenameDeskTopConfig

filename_buffer:
        .res kPathBufferSize

write_buffer:
        .res .sizeof(DeskTopSettings)

        DEFINE_CREATE_PARAMS create_params, filename, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
        DEFINE_WRITE_PARAMS write_params, write_buffer, .sizeof(DeskTopSettings)
        DEFINE_CLOSE_PARAMS close_params

.proc save_settings
        ;; Run from Main, but with LCBANK1 in

        ;; Copy from LCBANK to somewhere ProDOS can read.
        COPY_STRUCT DeskTopSettings, SETTINGS, write_buffer

        ;; Write to desktop current prefix
        ldax    #filename
        stax    create_params::pathname
        stax    open_params::pathname
        jsr     do_write

        ;; Write to the original file location, if necessary
        jsr     GetCopiedToRAMCardFlag
        beq     done
        ldax    #filename_buffer
        stax    create_params::pathname
        stax    open_params::pathname
        jsr     CopyDeskTopOriginalPrefix
        jsr     append_filename
        jsr     do_write

done:   rts

.proc append_filename
        ;; Append filename to buffer
        inc     filename_buffer ; Add '/' separator
        ldx     filename_buffer
        lda     #'/'
        sta     filename_buffer,x

        ldx     #0              ; Append filename
        ldy     filename_buffer
:       inx
        iny
        lda     filename,x
        sta     filename_buffer,y
        cpx     filename
        bne     :-
        sty     filename_buffer
        rts
.endproc

.proc do_write
        ;; Create if necessary
        copy16  DATELO, create_params::create_date
        copy16  TIMELO, create_params::create_time
        JUMP_TABLE_MLI_CALL CREATE, create_params

        JUMP_TABLE_MLI_CALL OPEN, open_params
        bcs     done
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL WRITE, write_params
close:  JUMP_TABLE_MLI_CALL CLOSE, close_params
done:   rts
.endproc

.endproc

;;; ============================================================

        .include "../lib/ramcard.s"
        .include "../lib/drawstring.s"

;;; ============================================================

da_end  := *
.assert * < WINDOW_ENTRY_TABLES, error, .sprintf("DA too big (at $%X)", *)
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00

;;; ============================================================
