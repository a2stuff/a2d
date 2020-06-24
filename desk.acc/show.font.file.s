        .feature string_escapes
        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"
        .include "../desktop/icontk.inc"

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

        .org $800

        jmp     entry

;;; ============================================================

pathbuf:        .res    kPathBufferSize, 0

font_buffer     := $D00
kReadLength      = WINDOW_ICON_TABLES-font_buffer

;;; Maximum font size is $E00 = 3584 bytes
;;; (largest known is Athens, 3203 bytes)

        DEFINE_OPEN_PARAMS open_params, pathbuf, DA_IO_BUFFER
        DEFINE_READ_PARAMS read_params, font_buffer, kReadLength
        DEFINE_CLOSE_PARAMS close_params

;;; ============================================================
;;; Get filename by checking DeskTop selected window/icon

entry:

.proc get_filename
        ;; Check that an icon is selected
        copy    #0, pathbuf

        jsr     JUMP_TABLE_GET_SEL_COUNT
        beq     abort

        jsr     JUMP_TABLE_GET_SEL_WIN
        bne     :+
abort:  rts

        ;; Copy path (prefix) into pathbuf.
:       src := $06
        dst := $08

        jsr     JUMP_TABLE_GET_WIN_PATH
        stax    src

        ldy     #0
        lda     (src),y
        tax
        inc16   src
        copy16  #pathbuf+1, dst
        jsr     copy_pathbuf   ; copy x bytes (src) to (dst)

        ;; Append separator.
        lda     #'/'
        ldy     #0
        sta     (dst),y
        inc     pathbuf
        inc16   dst

        ;; Get file entry.
        lda     #0              ; first icon in selection
        jsr     JUMP_TABLE_GET_SEL_ICON
        stax    src

        ;; Exit if a directory.
        ldy     #2              ; 2nd byte of entry
        lda     (src),y
        and     #kIconEntryTypeMask
        bne     :+
        rts                     ; 000 = directory

        ;; Set window title to point at filename
:       clc
        lda     src
        adc     #IconEntry::name
        sta     winfo_title
        lda     src+1
        adc     #0
        sta     winfo_title+1

        ;; Append filename to path.
        ldy     #IconEntry::name
        lda     (src),y         ; grab length
        tax
        clc
        lda     src
        adc     #IconEntry::name+1
        sta     src
        bcc     :+
        inc     src+1
:       jsr     copy_pathbuf    ; copy x bytes (src) to (dst)

        jmp     load_file_and_run_da

.proc copy_pathbuf              ; copy x bytes from src to dst
        ldy     #0              ; incrementing path length and dst
loop:   lda     (src),y
        sta     (dst),y
        iny
        inc     pathbuf
        dex
        bne     loop
        tya
        clc
        adc     dst
        sta     dst
        bcc     end
        inc     dst+1
end:    rts
.endproc

.endproc

;;; ============================================================
;;; Load the file

.proc load_file_and_run_da

        ;; TODO: Ensure there's enough room, fail if not

        ;; --------------------------------------------------
        ;; Load the file

        yax_call JUMP_TABLE_MLI, OPEN, open_params ; TODO: Check for error
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        yax_call JUMP_TABLE_MLI, READ, read_params ; TODO: Check for error
        yax_call JUMP_TABLE_MLI, CLOSE, close_params

        ;; --------------------------------------------------
        ;; Copy the DA code and loaded data to AUX

        copy16  #DA_LOAD_ADDRESS, STARTLO
        copy16  #WINDOW_ICON_TABLES-1, ENDLO
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
        rts
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
title:          .addr   0       ; overwritten to point at filename
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
viewloc:        DEFINE_POINT kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
maprect:        DEFINE_RECT 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:          DEFINE_POINT 0, 0
penwidth:       .byte   2
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   font_buffer
nextwinfo:      .addr   0
.endparams
        winfo_title := winfo::title

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
viewloc:        DEFINE_POINT 0, 0
mapbits:        .word   0
mapwidth:       .byte   0
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 0, 0
pattern:        .res    8, 0
colormasks:     .byte   0, 0
penloc:         DEFINE_POINT 0, 0
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

.proc exit
        MGTK_CALL MGTK::CloseWindow, winfo
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
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_REDRAW_ALL
        sta     RAMRDON
        sta     RAMWRTON

        ;; Draw DA's window
        jsr     draw_window

:       jmp     input_loop

.endproc

;;; ============================================================

line1:  PASCAL_STRING "\x00 \x01 \x02 \x03 \x04 \x05 \x06 \x07 \x08 \x09 \x0A \x0B \x0C \x0D \x0E \x0F"
line2:  PASCAL_STRING "\x10 \x11 \x12 \x13 \x14 \x15 \x16 \x17 \x18 \x19 \x1A \x1B \x1C \x1D \x1E \x1F"
line3:  PASCAL_STRING "  ! \x22 # $ % & ' ( ) * + , - . /"
line4:  PASCAL_STRING "0 1 2 3 4 5 6 7 8 9 : ; < = > ?"
line5:  PASCAL_STRING "@ A B C D E F G H I J K L M N O"
line6:  PASCAL_STRING "P Q R S T U V W X Y Z [ \x5C ] ^ _"
line7:  PASCAL_STRING "` a b c d e f g h i j k l m n o"
line8:  PASCAL_STRING "p q r s t u v w x y z { | } ~ \x7F"

        kLineCount = 8
line_addrs:
        .addr line1, line2, line3, line4, line5, line6, line7, line8

pos:    DEFINE_POINT 0,0, pos

        kInitialY = 5
        kLineHeight = 15


.proc draw_window
        ptr := $06

PARAM_BLOCK params, $06
data:   .addr   0
len:    .byte   0
width:  .word   0
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
