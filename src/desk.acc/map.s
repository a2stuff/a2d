;;; ============================================================
;;; MAP - Desk Accessory
;;;
;;; A simple world map
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "map.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/letk.inc"
        .include "../toolkits/btk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================
;;; Resources

kMapLeft = 10
kMapTop = 5
kMapWidth = 230
kMapHeight = 52

.params y_to_lat
number:         .word   180        ; (in) constant
numerator:      .word   0          ; (in) populated dynamically
denominator:    .word   kMapHeight ; (in) constant
result:         .word   0          ; (out)
remainder:      .word   0          ; (out)
.endparams

.params x_to_long
number:         .word   360       ; (in) constant
numerator:      .word   0         ; (in) populated dynamically
denominator:    .word   kMapWidth ; (in) constant
result:         .word   0         ; (out)
remainder:      .word   0         ; (out)
.endparams

.params lat_to_y
number:         .word   kMapHeight ; (in) constant
numerator:      .word   0          ; (in) populated dynamically
denominator:    .word   180        ; (in) constant
result:         .word   0          ; (out)
remainder:      .word   0          ; (out)
.endparams

.params long_to_x
number:         .word   kMapWidth ; (in) constant
numerator:      .word   0         ; (in) populated dynamically
denominator:    .word   360       ; (in) constant
result:         .word   0         ; (out)
remainder:      .word   0         ; (out)
.endparams


pensize_normal: .byte   1, 1
pensize_frame:  .byte   2, 1

        DEFINE_RECT_SZ frame_rect, kMapLeft - 4, kMapTop - 2, kMapWidth + 6, kMapHeight + 3
        DEFINE_RECT_SZ map_rect, kMapLeft, kMapTop, kMapWidth, kMapHeight

kControlsLeft = 6
kControlsRight = kDAWidth - kControlsLeft

kRow1 = kMapTop + kMapHeight + 6
kRow2 = kRow1 + kTextBoxHeight + 4
kRow3 = kRow2 + kSystemFontHeight + 4

kTextBoxLeft = kControlsLeft
kTextBoxTop = kRow1
kTextBoxWidth = kControlsRight - kButtonWidth - kControlsLeft * 2
        DEFINE_RECT_SZ input_rect, kTextBoxLeft, kTextBoxTop, kTextBoxWidth, kTextBoxHeight
        DEFINE_BUTTON find_button, kDAWindowId, res_string_button_find, kGlyphReturn, kControlsRight - kButtonWidth, kTextBoxTop

kLabelLeft = kControlsLeft + kTextBoxTextHOffset
kValueLeft = 80
        DEFINE_LABEL lat, res_string_latitude, kLabelLeft, kRow2 + kSystemFontHeight
        DEFINE_POINT pos_lat, kValueLeft, kRow2 + kSystemFontHeight
        DEFINE_LABEL long, res_string_longitude, kLabelLeft, kRow3 + kSystemFontHeight
        DEFINE_POINT pos_long, kValueLeft, kRow3 + kSystemFontHeight


str_spaces:
        PASCAL_STRING "      "
str_degree_suffix:
        PASCAL_STRING {kGlyphDegreeSign, " "}
str_n:  PASCAL_STRING res_string_dir_n
str_s:  PASCAL_STRING res_string_dir_s
str_e:  PASCAL_STRING res_string_dir_e
str_w:  PASCAL_STRING res_string_dir_w

.params map_params
        DEFINE_POINT viewloc, kMapLeft, kMapTop
mapbits:        .addr   map_bitmap
mapwidth:       .byte   (kMapWidth+6)/7
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kMapWidth-1, kMapHeight-1
        REF_MAPINFO_MEMBERS
.endparams

map_bitmap:
        PIXELS  "......................................................................................................................................................................................................................................"
        PIXELS  ".........................................................................................##########..................................................................................................................................."
        PIXELS  "..........................................................##############...################################.....................###...............##..#####...................###....................................................."
        PIXELS  "..........................................#########################..##################################...................########...............................................####................................................."
        PIXELS  "...................................############################...............########################...............................................####................####################....##........#####......................"
        PIXELS  "#...........##########........#####.....########....###...#############.........####################...........................########.............###.......###.###################################..##################............."
        PIXELS  "######...#####################################################.....########......###############....#.####..................#################.....####################################################################################"
        PIXELS  "...###..######################################################.......####.........#######............####...............########.####################################################################################################."
        PIXELS  "..........#############################################..........#####...#..........####..............................########...#####################################################################################...#.######....."
        PIXELS  ".............####...........##############################.......###########...................................##.......#..##...############################################################################..........####..#........."
        PIXELS  ".........##....................###############################..###############.............................##..####...####################################################################################.#.........###........#...."
        PIXELS  ".#..#.............................###########################################.##...............................###..########################################################################################.#.......#................"
        PIXELS  "....................................######################################....####...............................#################################..#######################################################..#........................"
        PIXELS  "....................................##################################.......................................########################.......#####...#####################################################....##......................."
        PIXELS  "....................................################################.............................#...........######.....#...#..##..###############...###############################################........#........................."
        PIXELS  ".....................................#############################............................................###...#####....#..##..############################################################...##..#####.........................."
        PIXELS  ".......................................#########################.............................................###############....##.......#######################################################......####............................"
        PIXELS  ".........................................##.###########......##........................................#....#####################################################################################....................................."
        PIXELS  ".........#................................##.########..........#..#.......................................##############################..########...###########################################......................................"
        PIXELS  "............#..#............................#..######.....##.####.......................................##################################..############......###############################..#......................................"
        PIXELS  "...............##................................######..###......#.####...#............................###################################..##########..........########.....########..#......................#......................"
        PIXELS  ".....................................................#########..............#......................#....####################################..#####..............#####..........########.......##....................................."
        PIXELS  "...........................................................###......####................................######################################....#...............####.......#....######........##...................................."
        PIXELS  "..............................................................###############.............................#########################################.............#..##.#...........#...#..........##....#...#.......#.........#..#....."
        PIXELS  "..................................................................################..........................#########..###########################....................#........#...##......###.........................#.............."
        PIXELS  "..............#.........................................#........##################......................................#######################.................#..............#####....#####.....#.........................#........"
        PIXELS  "..........................................................#.....########################................................#####################.....................................####...####..#....####.####........................."
        PIXELS  "...#............#..............................................#############################..............................##################........................................##.........#.#.......#######...#.................."
        PIXELS  "............#.............#.....................................#############################..............................#################...........................................##.##.#....#........#######....##.............."
        PIXELS  ".....#...#........................................................#########################................................##################.....#...................................................###...##............#..........."
        PIXELS  "....................#...#..........................................#######################................................##################....###..............................................#########..###..............#........"
        PIXELS  ".#..#........#............#...........................................###################..................................###############.....###.............................................##################.............#....#.."
        PIXELS  "......................................................................#################.....................................#############.....###..........................................#######################.........#.........."
        PIXELS  ".......................#..............................................##############........................................############.......#...........................................#########################.................."
        PIXELS  ".....................................................................##############..........................................##########.....................................................########################.................."
        PIXELS  ".....................................................................############..............................................######........................................................####.......###########..................."
        PIXELS  "....................................................................##########.............................................................................................................................#######...............##..."
        PIXELS  "....................................................................########.....................................................................................................................................................###.."
        PIXELS  "..#.................................................................#####......................................................................................................................................##............####....."
        PIXELS  "...................................................................#####....................................................................................................................................................###......."
        PIXELS  "...................................................................####.....##................................................................................##......................................................................"
        PIXELS  "....................................................................#####.................##.........................................................................................................................................."
        PIXELS  "..................................................................................................#..................................................................................................................................."
        PIXELS  "......................................................................................#..............................................................................................................................................."
        PIXELS  "..........................................................................####........................................................................................................................................................"
        PIXELS  "........................................................................####...................................................................###########..............########################################......................"
        PIXELS  "..................................................#####...........##########................................###################################################################################################################......."
        PIXELS  "...........................##################....############################........................#######################################################################################################################.........."
        PIXELS  ".######...############################################################################.....################################################################################################################################...#####..."
        PIXELS  "######################################################################################################################################################################################################################################"
        PIXELS  "######################################################################################################################################################################################################################################"
        PIXELS  "######################################################################################################################################################################################################################################"

;;; ============================================================

str_from_int:   PASCAL_STRING "000,000" ; filled in by IntToString

;;; ============================================================

kDAWindowId     = $80
kDAWidth        = kMapWidth + 19
kDAHeight       = kMapHeight + 51
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


;;; ============================================================

        .include "../lib/event_params.s"

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport_win
.endparams

grafport_win:   .tag    MGTK::GrafPort

.params trackgoaway_params
clicked:        .byte   0
.endparams

;;; ============================================================

lat:    .word   0
long:   .word   0

kPositionMarkerWidth = 11
kPositionMarkerHeight = 7
.params position_marker_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   position_marker_bitmap
mapwidth:       .byte   2
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kPositionMarkerWidth-1, kPositionMarkerHeight-1
        REF_MAPINFO_MEMBERS
.endparams

xcoord := position_marker_params::viewloc::xcoord
ycoord := position_marker_params::viewloc::ycoord

position_marker_bitmap:
        PIXELS  ".....#....."
        PIXELS  "..#..#..#.."
        PIXELS  "...#...#..."
        PIXELS  "###.....###"
        PIXELS  "...#...#..."
        PIXELS  "..#..#..#.."
        PIXELS  ".....#....."

;;; ============================================================
;;; Line Edit

cursor_ibeam_flag: .byte   0    ; bit7

kBufSize = 16                       ; max length = 15, length
buf_search:     .res    kBufSize, 0 ; search term

        DEFINE_LINE_EDIT line_edit_rec, kDAWindowId, buf_search, kTextBoxLeft, kTextBoxTop, kTextBoxWidth, kBufSize - 1
        DEFINE_LINE_EDIT_PARAMS le_params, line_edit_rec

;;; ============================================================

.proc Init
        copy8   #0, buf_search

        MGTK_CALL MGTK::OpenWindow, winfo
        LETK_CALL LETK::Init, le_params
        jsr     UpdateCoordsFromLatLong
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        LETK_CALL LETK::Activate, le_params
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        LETK_CALL LETK::Idle, le_params
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        jsr     IdlePositionIndicator
        jsr     GetNextEvent

        cmp     #kEventKindMouseMoved
        jeq     HandleMouseMove

        cmp     #MGTK::EventKind::button_down
        beq     HandleDown

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

.proc HandleKey
        copy8   event_params::key, le_params::key
        copy8   event_params::modifiers, le_params::modifiers

        lda     event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        beq     Exit

        LETK_CALL LETK::Key, le_params
        jmp     InputLoop
    END_IF

        cmp     #CHAR_ESCAPE
        beq     Exit

    IF A = #CHAR_RETURN
        BTK_CALL BTK::Flash, find_button
        jsr     DoFind
        jmp     InputLoop
    END_IF

        LETK_CALL LETK::Key, le_params
        jmp     InputLoop
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
        jeq     HandleClick
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
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        bit     dragwindow_params::moved
    IF NS
        ;; Draw DeskTop's windows and icons.
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow

        LETK_CALL LETK::Update, le_params ; window moved
    END_IF

        jmp     InputLoop

.endproc ; HandleDrag

;;; ============================================================

.proc DoFind
        ptr := $06

        ;; Erase old position
        jsr     SetPort
    IF ZERO
        jsr     HidePositionIndicator
    END_IF

        copy16  #location_table, ptr
        copy8   #0, index

loop:
        ;; Compare lengths
        ldy     #0
        lda     (ptr),y
        cmp     buf_search
        bne     next

        tay
    DO
        lda     buf_search,y
        jsr     ToUpperCase
        cmp     (ptr),y
        bne     next
        dey
    WHILE NOT_ZERO

        ;; Match!
        ldy     #0
        lda     (ptr),y
        tay
        iny                  ; past end of string
        ldx     #0           ; copy next 4 bytes into `lat` and `long`
    DO
        copy8   (ptr),y, lat,x
        iny
        inx
    WHILE X <> #4
        jmp     done

        ;; Advance pointer to next record
next:   inc     index
        lda     index
        cmp     #kNumLocations
        beq     fail

        ldy     #0              ; string length
        lda     (ptr),y
        clc
        adc     #1+4            ; size of length byte + coords
        clc
        adc     ptr
        sta     ptr
        bcc     :+
        inc     ptr+1
:
        jmp     loop



fail:   JSR_TO_MAIN JUMP_TABLE_BELL

done:   ;; Update display
        jsr     SetPort
    IF ZERO
        jsr     DrawLatLong
    END_IF
        rts


index:  .byte   0
.endproc ; DoFind

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

.proc HandleClick
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; Click in button?
        MGTK_CALL MGTK::InRect, find_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, find_button
      IF NC
        jsr     DoFind
      END_IF
        jmp     done
    END_IF

        ;; Click in line edit?
        MGTK_CALL MGTK::InRect, input_rect
    IF NOT_ZERO
        COPY_STRUCT screentowindow_params::window, le_params::coords
        LETK_CALL LETK::Click, le_params
        jmp     done
    END_IF

        ;; Click in map?
        MGTK_CALL MGTK::InRect, map_rect
        jeq     done            ; nope

        ;; Erase old position
        jsr     SetPort
    IF ZERO
        jsr     HidePositionIndicator
    END_IF

        ;; Compute new position

        ;; Map latitude to +90...-90
        sub16   screentowindow_params::windowy, #kMapTop, y_to_lat::numerator
        MGTK_CALL MGTK::MulDiv, y_to_lat
        sub16   #90, y_to_lat::result, lat

        ;; Map longitude to -180...+180
        sub16   screentowindow_params::windowx, #kMapLeft+1, x_to_long::numerator
        MGTK_CALL MGTK::MulDiv, x_to_long
        sub16   x_to_long::result, #180, long

        ;; Update display
        jsr     SetPort
    IF ZERO
        jsr     DrawLatLong
    END_IF

done:   jmp     InputLoop
.endproc ; HandleClick

;;; ============================================================

penXOR:         .byte   MGTK::penXOR
notpencopy:     .byte   MGTK::notpencopy

;;; ============================================================
;;; Output: Z=1 if ok, Z=0 / A = MGTK::Error on error

.proc SetPort
        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF ZERO
        MGTK_CALL MGTK::SetPort, grafport_win
    END_IF
        rts
.endproc ; SetPort

;;; ============================================================

.proc HandleMouseMove
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, input_rect
        bne     inside

outside:
        bit     cursor_ibeam_flag
        bpl     done
        CLEAR_BIT7_FLAG cursor_ibeam_flag
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        jmp     done

inside:
        bit     cursor_ibeam_flag
        bmi     done
        SET_BIT7_FLAG cursor_ibeam_flag
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::ibeam

done:   jmp     InputLoop
.endproc ; HandleMouseMove

;;; ============================================================

.proc DrawWindow
        ;; If we're drawing the window, the indicator is implicitly
        ;; not currently visible.
        CLEAR_BIT7_FLAG indicator_flag

        ;; Defer if content area is not visible
        jsr     SetPort
    IF ZERO
        MGTK_CALL MGTK::HideCursor

        ;; ==============================

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal
        MGTK_CALL MGTK::PaintBitsHC, map_params

        MGTK_CALL MGTK::MoveTo, lat_label_pos
        CALL    DrawString, AX=#lat_label_str
        MGTK_CALL MGTK::MoveTo, long_label_pos
        CALL    DrawString, AX=#long_label_str

        jsr     DrawLatLong

        BTK_CALL BTK::Draw, find_button

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, input_rect

        ;; ==============================

        MGTK_CALL MGTK::ShowCursor
    END_IF
        rts

.endproc ; DrawWindow

;;; ============================================================
;;; Assert: Correct GrafPort selected

.proc DrawLatLong
        ;; Latitude
        copy16  lat, tmp
        CLEAR_BIT7_FLAG sflag
        bit     tmp+1
    IF NS
        SET_BIT7_FLAG sflag
        sub16   #0, tmp, tmp
    END_IF

        CALL    IntToString, AX=tmp
        MGTK_CALL MGTK::MoveTo, pos_lat
        CALL    DrawString, AX=#str_from_int
        CALL    DrawString, AX=#str_degree_suffix
        bit     sflag
    IF NC
        CALL    DrawString, AX=#str_n
    ELSE
        CALL    DrawString, AX=#str_s
    END_IF
        CALL    DrawString, AX=#str_spaces

        ;; Longitude
        copy16  long, tmp
        CLEAR_BIT7_FLAG sflag
        bit     tmp+1
    IF NS
        SET_BIT7_FLAG sflag
        sub16   #0, tmp, tmp
    END_IF

        CALL    IntToString, AX=tmp
        MGTK_CALL MGTK::MoveTo, pos_long
        CALL    DrawString, AX=#str_from_int
        CALL    DrawString, AX=#str_degree_suffix
        bit     sflag
    IF NC
        CALL    DrawString, AX=#str_e
    ELSE
        CALL    DrawString, AX=#str_w
    END_IF
        CALL    DrawString, AX=#str_spaces

        jsr     UpdateCoordsFromLatLong
        jmp     ShowPositionIndicator

tmp:    .word   0
sflag:  .byte   0
.endproc ; DrawLatLong

;;; ============================================================

.proc IdlePositionIndicator
        lda     blink_counter
        ora     blink_counter+1
    IF ZERO
        jsr     ResetBlinkCounter
        jsr     SetPort
      IF ZERO
        jsr     XDrawPositionIndicator
      END_IF
    END_IF
        dec16   blink_counter
        rts
.endproc ; IdlePositionIndicator

;;; ============================================================
;;; Assert: Correct GrafPort selected
;;; Assert: `UpdateCoordsFromLatLong` has been called

.proc ShowPositionIndicator
        bit     indicator_flag
        RTS_IF NC
        FALL_THROUGH_TO XDrawPositionIndicator
.endproc ; ShowPositionIndicator
HidePositionIndicator := ShowPositionIndicator

.proc XDrawPositionIndicator
        lda     indicator_flag
        eor     #$80
        sta     indicator_flag
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintBitsHC, position_marker_params
        rts
.endproc ; XDrawPositionIndicator

indicator_flag:                 ; bit7 = indicator is visible
        .byte   0

.proc ResetBlinkCounter
        CALL    ReadSetting, X=#DeskTopSettings::caret_blink_speed
        sta     blink_counter
        inx                     ; `ReadSetting` preserves X
        jsr     ReadSetting
        sta     blink_counter+1
        lsr16   blink_counter
        rts
.endproc ; ResetBlinkCounter

blink_counter:
        .word   0

;;; ============================================================

.proc UpdateCoordsFromLatLong
        ;; Map latitude from +90...-90
        sub16   #90, lat, lat_to_y::numerator ; 90...-90 to 0...180
        MGTK_CALL MGTK::MulDiv, lat_to_y
        add16   lat_to_y::result, #kMapTop    - (kPositionMarkerHeight/2), ycoord

        ;; Map longitude from -180...+180
        add16   long, #180, long_to_x::numerator ; -180...180 to 0...360
        MGTK_CALL MGTK::MulDiv, long_to_x
        add16   long_to_x::result, #kMapLeft+1 - (kPositionMarkerWidth/2), xcoord

        rts
.endproc ; UpdateCoordsFromLatLong

;;; ============================================================

        .include "../lib/drawstring.s"
        .include "../lib/inttostring.s"
        .include "../lib/get_next_event.s"

;;; ============================================================

        loc_count .set 0
.macro DEFINE_LOCATION name, lat, long
        PASCAL_STRING name
        .word   AS_WORD(lat)
        .word   AS_WORD(long)
        loc_count .set loc_count+1
.endmacro

location_table:
        DEFINE_LOCATION "ABIDJAN", 5, -4
        DEFINE_LOCATION "ALEXANDRIA", 31, 29
        DEFINE_LOCATION "AUCKLAND", -36, 174
        DEFINE_LOCATION "BANGALORE", 12, 77
        DEFINE_LOCATION "BANGKOK", 13, 100
        DEFINE_LOCATION "BEIJING", 39, 116
        DEFINE_LOCATION "BERLIN", 52, 13
        DEFINE_LOCATION "BOGOTA", 4, -74
        DEFINE_LOCATION "BUCHAREST", 44, 26
        DEFINE_LOCATION "BUENOS AIRES", -34, -58
        DEFINE_LOCATION "CAIRO", 30, 31
        DEFINE_LOCATION "CALGARY", 51, -114
        DEFINE_LOCATION "CAPE TOWN", -33, 18
        DEFINE_LOCATION "CARACAS", 10, -66
        DEFINE_LOCATION "CHENGDU", 30, 104
        DEFINE_LOCATION "CHENNAI", 13, 80
        DEFINE_LOCATION "CHICAGO", 41, -87
        DEFINE_LOCATION "CHONGQING", 29, 106
        DEFINE_LOCATION "CUPERTINO", 37, -122
        DEFINE_LOCATION "DAR ES SALAAM", -6, 39
        DEFINE_LOCATION "DELHI", 28, 77
        DEFINE_LOCATION "DHAKA", 23, 90
        DEFINE_LOCATION "GUANGZHOU", 23, 113
        DEFINE_LOCATION "HAVANA", 23, -82
        DEFINE_LOCATION "HO CHI MINH", 10, 106
        DEFINE_LOCATION "HONG KONG", 22, 114
        DEFINE_LOCATION "HONOLULU", 21, -157
        DEFINE_LOCATION "HOUSTON", 29, -95
        DEFINE_LOCATION "HYDERABAD", 17, 78
        DEFINE_LOCATION "ISTANBUL", 41, 28
        DEFINE_LOCATION "JAKARTA", -6, 106
        DEFINE_LOCATION "JOHANNESBURG", -26, 28
        DEFINE_LOCATION "KANSAS CITY", 39, -94
        DEFINE_LOCATION "KARACHI", 24, 67
        DEFINE_LOCATION "KHARTOUM", 15, 32
        DEFINE_LOCATION "KINSHASA", -4, 15
        DEFINE_LOCATION "KOLKATA", 22, 88
        DEFINE_LOCATION "KYIV", 50, 30
        DEFINE_LOCATION "LAGOS", 6, 3
        DEFINE_LOCATION "LAHORE", 31, 74
        DEFINE_LOCATION "LIMA", -12, -77
        DEFINE_LOCATION "LISBON", 38, -9
        DEFINE_LOCATION "LONDON", 51, 0
        DEFINE_LOCATION "LOS ANGELES", 34, -118
        DEFINE_LOCATION "MADRID", 40, -3
        DEFINE_LOCATION "MANILA", 14, 120
        DEFINE_LOCATION "MEXICO CITY", 19, -99
        DEFINE_LOCATION "MOSCOW", 55, 37
        DEFINE_LOCATION "MONTREAL", 45, -73
        DEFINE_LOCATION "MUMBAI", 19, 72
        DEFINE_LOCATION "NAGOYA", 35, 136
        DEFINE_LOCATION "NAIROBI", -1, 36
        DEFINE_LOCATION "NEW YORK", 40, -74
        DEFINE_LOCATION "OSAKA", 34, 135
        DEFINE_LOCATION "OTTAWA", 45, -75
        DEFINE_LOCATION "PAPEETE", -17, -149
        DEFINE_LOCATION "PARIS", 48, 2
        DEFINE_LOCATION "RIO DE JANEIRO", -22, -43
        DEFINE_LOCATION "ROME", 41, 12
        DEFINE_LOCATION "ST PETERSBURG", 59, 30
        DEFINE_LOCATION "SAN FRANCISCO", 37, -122
        DEFINE_LOCATION "SANTIAGO", -33, -70
        DEFINE_LOCATION "SAO PAULO", -23, -46
        DEFINE_LOCATION "SEATTLE", 47, -122
        DEFINE_LOCATION "SEOUL", 37, 126
        DEFINE_LOCATION "SHANGHAI", 31, 121
        DEFINE_LOCATION "SHENZHEN", 22, 114
        DEFINE_LOCATION "SINGAPORE", 1, 103
        DEFINE_LOCATION "SOFIA", 43, 23
        DEFINE_LOCATION "SPRINGFIELD", 40, -90
        DEFINE_LOCATION "SUZHOU", 31, 120
        DEFINE_LOCATION "SYDNEY", -33, 151
        DEFINE_LOCATION "TIANJIN", 39, 117
        DEFINE_LOCATION "TEHRAN", 35, 51
        DEFINE_LOCATION "TOKYO", 35, 139
        DEFINE_LOCATION "TORONTO", 43, -79
        DEFINE_LOCATION "VANCOUVER", 49, -123
        DEFINE_LOCATION "VICTORIA", 48, -123
        DEFINE_LOCATION "WASHINGTON", 38, -77
        DEFINE_LOCATION "XIAMEN", 24, 118

kNumLocations = loc_count

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX aux::Init
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
