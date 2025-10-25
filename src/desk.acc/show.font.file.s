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
;;;          | IO Buffer | |           |
;;;  $1C00   +-----------+ |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | | Font      |
;;;          | Font      | |           |
;;;          |           | +-----------+
;;;          +-----------+ |           |
;;;          | font      | | UI code & |
;;;          | loader    | | resources |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================


;;; ============================================================

kDAWindowId     = $80
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
penwidth:       .byte   2
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   font_buffer
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
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

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort

.params drawtext_params_char
        .addr   char_label
        .byte   1
.endparams
char_label:  .byte   0

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
        cmp     #MGTK::EventKind::button_down ; was clicked?
        jeq     HandleDown

        cmp     #MGTK::EventKind::key_down  ; any key?
        jeq     HandleKey

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
        jeq     Exit
        jmp     InputLoop
    END_IF

        cmp     #CHAR_ESCAPE
        jeq     Exit

        jmp     InputLoop
.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params

        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        jne     InputLoop

        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        beq     HandleDrag
        jmp     InputLoop
.endproc ; HandleDown

;;; ============================================================

.proc HandleClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        jeq     InputLoop

        jmp     Exit
.endproc ; HandleClose

;;; ============================================================

.proc HandleDrag
        copy8   winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        lda     dragwindow_params::moved
    IF NS
        ;; Draw DeskTop's windows and icons (from Main)
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow
    END_IF

        jmp     InputLoop
.endproc ; HandleDrag

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

        DEFINE_POINT pos, 0, 0

        kInitialY = 5
        kLineHeight = 15


.proc DrawWindow
        ptr := $06

PARAM_BLOCK params, $06
data    .addr
len     .byte
width   .word
END_PARAM_BLOCK

        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF A = #MGTK::Error::window_obscured

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        copy16  #kInitialY, pos::ycoord


        copy8   #0, index
    DO
        lda     index
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
    WHILE A <> #kLineCount

        MGTK_CALL MGTK::ShowCursor
        rts

index:  .byte   0

.endproc ; DrawWindow

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        font_buffer := *

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        jmp     Entry

        INVOKE_PATH := $220

filename:       .res    16

        DEFINE_OPEN_PARAMS open_params, INVOKE_PATH, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS read_params, font_buffer, kReadLength
        DEFINE_CLOSE_PARAMS close_params

;;; ============================================================

.proc Entry
        FALL_THROUGH_TO LoadFileAndRunDA
.endproc ; Entry

;;; ============================================================
;;; Load the file

.proc LoadFileAndRunDA

        ;; TODO: Ensure there's enough room, fail if not

        ;; --------------------------------------------------
        ;; Load the file

        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        JUMP_TABLE_MLI_CALL OPEN, open_params
    IF CS
        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts
    END_IF

        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL READ, read_params
        php                     ; preserve error
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        plp
        jcs     exit

        ;; --------------------------------------------------
        ;; Try to verify that this is a font file

        lda     font_buffer + MGTK::Font::fonttype ; $00 or $80
    IF A NOT_IN #$00, #$80   ; regular, double-width?
        jmp     exit
    END_IF

        lda     font_buffer + MGTK::Font::lastchar ; usually $7F
        jeq     exit
        jmi     exit

        lda     font_buffer + MGTK::Font::height ; 1-16
        beq     exit
        cmp     #16+1
        bcs     exit

        jsr     CalcFontSize
        ecmp16  expected_size, read_params::trans_count
        bne     exit

        ;; --------------------------------------------------
        ;; Copy the loaded data to AUX

        copy16  #font_buffer, STARTLO
        add16   #font_buffer-1, read_params::trans_count, ENDLO
        copy16  #aux::font_buffer, DESTINATIONLO
        CALL    AUXMOVE, C=1    ; main>aux

        ;; --------------------------------------------------
        ;; Set window title to filename

        ldy     INVOKE_PATH
    DO
        lda     INVOKE_PATH,y       ; find last '/'
        BREAK_IF A = #'/'
        dey
    WHILE NOT_ZERO

        ldx     #0
    DO
        copy8   INVOKE_PATH+1,y, filename+1,x ; copy filename
        inx
        iny
    WHILE Y <> INVOKE_PATH
        stx     filename

        copy16  #filename, STARTLO
        copy16  #filename+kMaxFilenameLength, ENDLO
        copy16  #aux::titlebuf, DESTINATIONLO
        CALL    AUXMOVE, C=1    ; main>aux

        ;; --------------------------------------------------
        ;; Run the DA from Aux, back to Main when done

        JSR_TO_AUX aux::Init

exit:   rts

.endproc ; LoadFileAndRunDA

;;; ============================================================
;;; Calculate expected font file size, given font header
;;; Populates `expected_size`

expected_size:
        .word   0

.proc CalcFontSize
        copy8   #0, expected_size

        ;; File size should be 3 + (lastchar + 1) + ((lastchar + 1) * height) * (double?2:1)

        ldx     font_buffer + MGTK::Font::lastchar
        inx                     ; lastchar + 1
    DO
        add16_8 expected_size, font_buffer + MGTK::Font::height
        dex
    WHILE NOT_ZERO              ; = (lastchar + 1) * height

        bit     font_buffer + MGTK::Font::fonttype
    IF NS
        asl16   expected_size   ; *= 2 if double width
    END_IF

        add16_8 expected_size, font_buffer + MGTK::Font::lastchar ; += lastchar
        add16_8 expected_size, #4 ; += 3 + 1

        rts
.endproc ; CalcFontSize

;;; ============================================================

font_buffer     := *
kReadLength     = DA_IO_BUFFER-font_buffer

        DA_END_MAIN_SEGMENT

;;; ============================================================
