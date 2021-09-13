        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================
;;; Memory map
;;;
;;;              Main           Aux
;;;          :           : :           :
;;;          |           | |           |
;;;          | DHR       | | DHR       |
;;;  $2000   +-----------+ +-----------+
;;;          | IO Buffer | |Win Tables |
;;;  $1C00   +-----------+ |           |
;;;  $1B00   |           | +-----------+
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | | Font      |
;;;          | Font      | | (Copy)    |
;;;   $D00   +-----------+ +-----------+
;;;          |           | |           |
;;;          |           | |           |
;;;          | DA        | | DA (Copy) |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

        .org DA_LOAD_ADDRESS

        jmp     entry

;;; ============================================================

pathbuf:        .res    kPathBufferSize, 0

font_buffer     := $D00
kReadLength      = WINDOW_ENTRY_TABLES-font_buffer

;;; Maximum font size is $E00 = 3584 bytes
;;; (largest known is Athens, 3203 bytes)

        DEFINE_OPEN_PARAMS open_params, pathbuf, DA_IO_BUFFER
        DEFINE_READ_PARAMS read_params, font_buffer, kReadLength
        DEFINE_CLOSE_PARAMS close_params

;;; ============================================================
;;; Get filename from DeskTop

.proc entry
        INVOKE_PATH := $220
        lda     INVOKE_PATH
    IF_EQ
        rts
    END_IF
        COPY_STRING INVOKE_PATH, pathbuf

        ;; Set window title to filename
        ldy     pathbuf
:       lda     pathbuf,y       ; find last '/'
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       ldx     #1
:       lda     pathbuf+1,y     ; copy filename
        sta     titlebuf,x
        inx
        iny
        cpy     pathbuf
        bne     :-
        stx     titlebuf

        jmp     load_file_and_run_da
.endproc

;;; ============================================================
;;; Load the file

.proc load_file_and_run_da

        ;; TODO: Ensure there's enough room, fail if not

        ;; --------------------------------------------------
        ;; Load the file

        JUMP_TABLE_MLI_CALL OPEN, open_params
        beq     :+
        rts
:       lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL READ, read_params ; TODO: Check for error
        JUMP_TABLE_MLI_CALL CLOSE, close_params

        ;; --------------------------------------------------
        ;; Try to verify that this is a font file

        lda     font_buffer + MGTK::Font::fonttype ; $00 or $80
        cmp     #$00            ; regular?
        beq     :+
        cmp     #$80            ; double-width?
        bne     exit

:       lda     font_buffer + MGTK::Font::lastchar ; usually $7F
        beq     exit
        bmi     exit

        lda     font_buffer + MGTK::Font::height ; 1-16
        beq     exit
        cmp     #16+1
        bcs     exit

        ;; File size should be 3 + lastchar + (lastchar * height) * (double?2:1)
        ;; ... but files aren't exactly this size, so don't enforce this. (?!?)

        ;; --------------------------------------------------
        ;; Copy the DA code and loaded data to AUX

        copy16  #DA_LOAD_ADDRESS, STARTLO
        copy16  #WINDOW_ENTRY_TABLES-1, ENDLO
        copy16  #DA_LOAD_ADDRESS, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE

        ;; --------------------------------------------------
        ;; Run the DA from Aux, back to Main when done

        sta     RAMRDON
        sta     RAMWRTON
        jsr     init
        sta     RAMRDOFF
        sta     RAMWRTOFF

exit:   rts

size:   .word   0
.endproc

;;; ============================================================

kDAWindowId    = 60
kDAWidth        = 380
kDAHeight       = 140
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::go_away_box
title:          .addr   titlebuf
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
penwidth:       .byte   2
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   font_buffer
nextwinfo:      .addr   0
.endparams

titlebuf:
        .res    16, 0


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

.params winport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

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

.params drawtext_params_char
        .addr   char_label
        .byte   1
.endparams
char_label:  .byte   0

;;; ============================================================


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
        cmp     #MGTK::EventKind::button_down ; was clicked?
        bne     :+
        jmp     handle_down


:       cmp     #MGTK::EventKind::key_down  ; any key?
        bne     :+
        jmp     handle_key


:       jmp     input_loop
.endproc

.proc yield_loop
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_YIELD_LOOP
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

.proc clear_updates
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_CLEAR_UPDATES
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

.proc exit
        MGTK_CALL MGTK::CloseWindow, winfo
        jsr     clear_updates
        rts                     ; exits input loop
.endproc

;;; ============================================================

.proc handle_key
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        bne     :+
        jmp     exit
:       jmp     input_loop
.endproc

;;; ============================================================

.proc handle_down
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        bpl     :+
        jmp     exit
:       lda     findwindow_params::window_id
        cmp     winfo::window_id
        bpl     :+
        jmp     input_loop
:       lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     handle_close
        cmp     #MGTK::Area::dragbar
        beq     handle_drag
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_close
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        bne     :+
        jmp     input_loop
:       jmp     exit
.endproc

;;; ============================================================

.proc handle_drag
        copy    winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        lda     dragwindow_params::moved
        bpl     :+

        ;; Draw DeskTop's windows and icons (from Main)
        jsr     clear_updates

        ;; Draw DA's window
        jsr     draw_window

:       jmp     input_loop

.endproc

;;; ============================================================

line1:  PASCAL_STRING "\x00 \x01 \x02 \x03 \x04 \x05 \x06 \x07 \x08 \x09 \x0A \x0B \x0C \x0D \x0E \x0F" ; do not localize
line2:  PASCAL_STRING "\x10 \x11 \x12 \x13 \x14 \x15 \x16 \x17 \x18 \x19 \x1A \x1B \x1C \x1D \x1E \x1F" ; do not localize
line3:  PASCAL_STRING "  ! \x22 # $ % & ' ( ) * + , - . /" ; do not localize
line4:  PASCAL_STRING "0 1 2 3 4 5 6 7 8 9 : ; < = > ?" ; do not localize
line5:  PASCAL_STRING "@ A B C D E F G H I J K L M N O" ; do not localize
line6:  PASCAL_STRING "P Q R S T U V W X Y Z [ \x5C ] ^ _" ; do not localize
line7:  PASCAL_STRING "` a b c d e f g h i j k l m n o" ; do not localize
line8:  PASCAL_STRING "p q r s t u v w x y z { | } ~ \x7F" ; do not localize

        kLineCount = 8
line_addrs:
        .addr line1, line2, line3, line4, line5, line6, line7, line8

        DEFINE_POINT pos, 0, 0

        kInitialY = 5
        kLineHeight = 15


.proc draw_window
        ptr := $06

PARAM_BLOCK params, $06
data    .addr
len     .byte
width   .word
END_PARAM_BLOCK

        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        bne     :+
        rts

:       MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        copy16  #kInitialY, pos::ycoord


        copy    #0, index
loop:   lda     index
        asl
        tax
        copy16  line_addrs,x, ptr

        ldy     #0
        lda     (ptr),y         ; length
        sta     params::len
        add16   ptr, #1, params::data ; offset past length

        ;; Position the string
        MGTK_CALL MGTK::TextWidth, params
        sub16   #kDAWidth, params::width, pos::xcoord ; center it
        lsr16   pos::xcoord
        add16   pos::ycoord, #kLineHeight, pos::ycoord ; next row

        MGTK_CALL MGTK::MoveTo, pos
        MGTK_CALL MGTK::DrawText, params

        inc     index
        lda     index
        cmp     #kLineCount
        bne     loop

        MGTK_CALL MGTK::ShowCursor
        rts

index:  .byte   0

.endproc


;;; ============================================================

.assert * < font_buffer, error, "DA too big"
