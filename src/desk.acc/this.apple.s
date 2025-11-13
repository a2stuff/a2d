;;; ============================================================
;;; THIS.APPLE - Desk Accessory
;;;
;;; Displays information about the current computer. The data
;;; shown includes:
;;;    * Model
;;;    * CPU
;;;    * Expanded/RAMWorks Memory
;;;    * ProDOS version
;;;    * Contents of each expansion slot
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "this.apple.res"

        .include "apple2.inc"
        .include "opcodes.inc"

        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../inc/smartport.inc"
        .include "../mgtk/mgtk.inc"
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
;;;          | strings     | |             |
;;;          | app code    | | resources   |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;
;;; ============================================================

;;; Currently there's not enough room for these.
INCLUDE_UNSUPPORTED_MACHINES = 0

kShortcutEasterEgg = res_char_easter_egg_shortcut

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

kDAWindowId     = $80
kDAWidth        = 400
kDAHeight       = 118
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

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

str_title:
        PASCAL_STRING res_string_window_title

notpencopy:     .byte   MGTK::notpencopy


.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort

;;; ============================================================

.macro DEFINE_BITMAP identifier, width, height
        WARN_IF_SHADOWING .ident(.sprintf("%s_bitmap", .string(identifier)))
.params .ident(.sprintf("%s_bitmap", .string(identifier)))
        DEFINE_POINT viewloc, 88 - (width/2), 19 - (height/2)
mapbits:        .addr   .ident(.sprintf("%s_bits", .string(identifier)))
mapwidth:       .byte   (width + 6) / 7
reserved:       .res    1
        DEFINE_RECT maprect, 0, 0, width-1, height-1
        REF_MAPINFO_MEMBERS
.endparams
.endmacro

        DEFINE_BITMAP ii, 51, 19
        DEFINE_BITMAP iii, 55, 25
        DEFINE_BITMAP iie, 51, 26
        DEFINE_BITMAP iic, 46, 28
        DEFINE_BITMAP iigs, 80, 26
        DEFINE_BITMAP iie_card, 56, 22
        DEFINE_BITMAP laser128, 48, 30
        DEFINE_BITMAP ace500, 49, 30
        DEFINE_BITMAP ace2000, 49, 24
        DEFINE_BITMAP tlc, 46, 25
        DEFINE_BITMAP trackstar, 56, 25
        DEFINE_BITMAP mega_iie, 48, 22
        DEFINE_BITMAP pravetz, 51, 24

ii_bits:
        PIXELS  ".......######################....................."
        PIXELS  "......##....................##...................."
        PIXELS  "......##..################..##...................."
        PIXELS  "......##..##............##..################......"
        PIXELS  "......##..##..##..##....##..##............##......"
        PIXELS  "......##..##............##..##..########..##......"
        PIXELS  "......##..##..##........##..##............##......"
        PIXELS  "......##..##............##..################......"
        PIXELS  "......##..##............##..##............##......"
        PIXELS  "......##..################..##..########..##......"
        PIXELS  "......##....................##............##......"
        PIXELS  ".......####################################......."
        PIXELS  ".....###..................................###....."
        PIXELS  "...###....##..##..##..##..##..##..##..##....###..."
        PIXELS  ".###....##..##..##..##..##..##..##..##..##....###."
        PIXELS  "##....##..##..##..##..##..##..##..##..##..##....##"
        PIXELS  "##..............................................##"
        PIXELS  ".###..........................................###."
        PIXELS  "...############################################..."

iii_bits:
        PIXELS  ".......########################################......."
        PIXELS  "......##......................................##......"
        PIXELS  "......##..##########################..........##......"
        PIXELS  "......##..##......................##..........##......"
        PIXELS  "......##..##..##..##..##..##......##..........##......"
        PIXELS  "......##..##......................##..........##......"
        PIXELS  "......##..##..##..##..............##..........##......"
        PIXELS  "......##..##......................##..........##......"
        PIXELS  "......##..##..##..................##..##..##..##......"
        PIXELS  "......##..##......................##..##..##..##......"
        PIXELS  "......##..##########################..........##......"
        PIXELS  "......##......................................##......"
        PIXELS  ".......########################################......."
        PIXELS  "......##......................................##......"
        PIXELS  "......##......................................##......"
        PIXELS  "......##........................##########....##......"
        PIXELS  "......##....######.................####.......##......"
        PIXELS  "......##......................................##......"
        PIXELS  "......##########################################......"
        PIXELS  ".....###......................................###....."
        PIXELS  "...###....##..##..##..##..##..##......##..##....###..."
        PIXELS  ".###....##..##..##..##..##..##..##......##..##....###."
        PIXELS  "##....##..##..##..##..##..##..##..##......##..##....##"
        PIXELS  "##..................................................##"
        PIXELS  ".####################################################."

iie_bits:
        PIXELS  ".......####################################......."
        PIXELS  "......##..................................##......"
        PIXELS  "......##..##########################......##......"
        PIXELS  "......##..##......................##......##......"
        PIXELS  "......##..##..##..##..##..##......##......##......"
        PIXELS  "......##..##......................##......##......"
        PIXELS  "......##..##..##..##..............##......##......"
        PIXELS  "......##..##......................##......##......"
        PIXELS  "......##..##..##..................##......##......"
        PIXELS  "......##..##......................##......##......"
        PIXELS  "......##..##......................##......##......"
        PIXELS  "......##..##......................##..##..##......"
        PIXELS  "......##..##########################..##..##......"
        PIXELS  "......##..................................##......"
        PIXELS  ".......####################################......."
        PIXELS  "......##..................................##......"
        PIXELS  "......##....##########......##########....##......"
        PIXELS  "......##..................................##......"
        PIXELS  ".......####################################......."
        PIXELS  ".....###..................................###....."
        PIXELS  "...###....##..##..##..##..##..##..##..##....###..."
        PIXELS  ".###....##..##..##..##..##..##..##..##..##....###."
        PIXELS  "##....##..##..##..##..##..##..##..##..##..##....##"
        PIXELS  "##..............................................##"
        PIXELS  ".###..........................................###."
        PIXELS  "...############################################..."

iic_bits:
        PIXELS  ".......################################......."
        PIXELS  "......##..............................##......"
        PIXELS  "......##...########################...##......"
        PIXELS  "......##..##......................##..##......"
        PIXELS  "......##..##..##..##..##..##......##..##......"
        PIXELS  "......##..##......................##..##......"
        PIXELS  "......##..##..##..##..............##..##......"
        PIXELS  "......##..##......................##..##......"
        PIXELS  "......##..##..##..................##..##......"
        PIXELS  "......##..##......................##..##......"
        PIXELS  "......##..##......................##..##......"
        PIXELS  "......##..##......................##..##......"
        PIXELS  "......##...########################...##......"
        PIXELS  "......##..............................##......"
        PIXELS  ".......################################......."
        PIXELS  "............##..................##............"
        PIXELS  "...########################################..."
        PIXELS  "..##......................................##.."
        PIXELS  "..##..#..#..#..#..#..#..#..#..#..#..#..#..##.."
        PIXELS  "..##..#..#..#..#..#..#..#..#..#..#..#..#..##.."
        PIXELS  ".##...#..#..#..#..#..#..#..#..#..#..#..#...##."
        PIXELS  ".##...#..#..#..#..#..#..#..#..#..#..#..#...##."
        PIXELS  ".##........................................##."
        PIXELS  "##....##..##..##..##..##..##..##..##..##....##"
        PIXELS  "##..##..##..##..##..##..##..##..##..##..##..##"
        PIXELS  "##....##..##..##..##..##..##..##..##..##....##"
        PIXELS  "##..........................................##"
        PIXELS  ".############################################."

iigs_bits:
        PIXELS  ".......................####################################..................."
        PIXELS  "......................##..................................##.................."
        PIXELS  "......................##..##############################..##.................."
        PIXELS  "......................##..##..........................##..##.................."
        PIXELS  "......................##..##..##..##..##..##..........##..##.................."
        PIXELS  "......................##..##..........................##..##.................."
        PIXELS  "......................##..##..##..##..................##..##.................."
        PIXELS  "......................##..##..........................##..##.................."
        PIXELS  "......................##..##..##......................##..##.................."
        PIXELS  "......................##..##..........................##..##.................."
        PIXELS  "......................##..##..........................##..##.................."
        PIXELS  "......................##..##..........................##..##.................."
        PIXELS  "......................##..##..........................##..##.................."
        PIXELS  "......................##..##############################..##.................."
        PIXELS  "......................##..................................##.................."
        PIXELS  ".......##############..####################################..................."
        PIXELS  "......##............##..##..............................##...................."
        PIXELS  "......##..########..##..##..............................##...................."
        PIXELS  "......##............##..##..............................##...................."
        PIXELS  ".####################...##..............................##...................."
        PIXELS  "##..................##..##..##..######..................##.......####........."
        PIXELS  "##..................##..##..............................##.....##....#........"
        PIXELS  "##....##########....##..##################################...##.....########.."
        PIXELS  "##..................##..##..............................#####.....##........##"
        PIXELS  "##..................##..##..............................##........##........##"
        PIXELS  ".####################....################################.........############"

iie_card_bits:
        PIXELS  "...###########################################.........."
        PIXELS  "..####......................................##.........."
        PIXELS  "..####...............................##.....##.........."
        PIXELS  "..####...................########....##.....##.........."
        PIXELS  "..####..###.....##..##...########...........##....####.."
        PIXELS  "..####..###.....##..##...########...........##....####.."
        PIXELS  "...##...........##..##...########...........##....####.."
        PIXELS  "...##..####..............########....#####..##..########"
        PIXELS  "...##..####....####..................#####..##...######."
        PIXELS  "...##..####....####..................#####..##....####.."
        PIXELS  "...##.......................................##.....##..."
        PIXELS  "...###########################################.........."
        PIXELS  "........................................................"
        PIXELS  "########################################################"
        PIXELS  "##....................................................##"
        PIXELS  "##....................................................##"
        PIXELS  "##...............................##################...##"
        PIXELS  "##....................................................##"
        PIXELS  "##....................................................##"
        PIXELS  "########################################################"
        PIXELS  "...##..............................................##..."
        PIXELS  "...##################################################..."

laser128_bits:
        PIXELS  ".......####################################......"
        PIXELS  "......##..................................##....."
        PIXELS  "......##...########################.......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##..##..##..##..##......##......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##..##..##..............##......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##..##..................##......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##......................##..##..##....."
        PIXELS  "......##..##......................##..##..##....."
        PIXELS  "......##...########################.......##....."
        PIXELS  "......##..................................##....."
        PIXELS  ".......####################################......"
        PIXELS  "................................................."
        PIXELS  "...############################################.."
        PIXELS  "..##..##...##...##............................##."
        PIXELS  "..##...##...##...###############################."
        PIXELS  "..##....##...##...............................##."
        PIXELS  "..##.....##...##################################."
        PIXELS  "..##......##..................................##."
        PIXELS  "..##.......#####################################."
        PIXELS  "..##..........................................##."
        PIXELS  "..##....##..##..##..##..##....................##."
        PIXELS  "..##..##..##..##..##..##..##..##..##..##..##..##."
        PIXELS  "..##....##..##..##..##..##..##..##..##..##....##."
        PIXELS  "..##..##..##..##..##..##..##..##..##..##..##..##."
        PIXELS  "..##..........................................##."
        PIXELS  "...############################################.."

ace500_bits:
        PIXELS  ".......####################################......"
        PIXELS  "......##..................................##....."
        PIXELS  "......##...########################.......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##..##..##..##..##......##......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##..##..##..............##......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##..##..................##......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##......................##..##..##....."
        PIXELS  "......##..##......................##..##..##....."
        PIXELS  "......##...########################.......##....."
        PIXELS  "......##..................................##....."
        PIXELS  ".......####################################......"
        PIXELS  "................................................."
        PIXELS  ".################################################"
        PIXELS  ".####.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.###"
        PIXELS  ".###.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.####"
        PIXELS  ".####.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.###"
        PIXELS  ".################################################"
        PIXELS  ".################################################"
        PIXELS  ".###.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.####"
        PIXELS  "..##############################################."
        PIXELS  "..####..##..##..##..##..##..##..####..##..######."
        PIXELS  "..######..##..##..##..##..##..##..####..##..####."
        PIXELS  "..####..##..##..##..##..##..##..####..##..######."
        PIXELS  "..######..##..##..##..##..##..##..####..##..####."
        PIXELS  "..##############################################."
        PIXELS  "..##############################################."

ace2000_bits:
        PIXELS  ".......####################################......"
        PIXELS  "......##..................................##....."
        PIXELS  "......##...########################.......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##..##..##..##..##......##......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##..##..##..............##......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##..##..................##......##....."
        PIXELS  "......##..##......................##......##....."
        PIXELS  "......##..##......................##..##..##....."
        PIXELS  "......##..##......................##..##..##....."
        PIXELS  "......##...########################.......##....."
        PIXELS  "......##..................................##....."
        PIXELS  ".......####################################......"
        PIXELS  "................................................."
        PIXELS  ".################################################"
        PIXELS  ".##............................................##"
        PIXELS  ".##..########################################..##"
        PIXELS  ".##..##########.............##.............##..##"
        PIXELS  ".##..########################################..##"
        PIXELS  ".##............................................##"
        PIXELS  ".################################################"
        PIXELS  ".################################################"

tlc_bits:
        PIXELS  "....######################################...."
        PIXELS  "...##....................................##..."
        PIXELS  "...##.....######....######....######.....##..."
        PIXELS  "...##.....#....#....#....#....#....#.....##..."
        PIXELS  "...##....##....##..##....##..##....##....##..."
        PIXELS  "...##.....#....#....#....#....#....#.....##..."
        PIXELS  "...##.....######....######....######.....##..."
        PIXELS  "...##....................................##..."
        PIXELS  "...##.....######....######....######.....##..."
        PIXELS  "...##.....#....#....#....#....#....#.....##..."
        PIXELS  "...##....##....##..##....##..##....##....##..."
        PIXELS  "...##.....#....#....#....#....#....#.....##..."
        PIXELS  "...##.....######....######....######.....##..."
        PIXELS  "...##....................................##..."
        PIXELS  "...########################################..."
        PIXELS  ".......##............................##......."
        PIXELS  "...########################################..."
        PIXELS  "..##......................................##.."
        PIXELS  "..##..##..##..##..##..##..##..##..##..##..##.."
        PIXELS  ".##.....##..##..##..##..##..##..##..##.....##."
        PIXELS  ".##...##..##..##..##..##..##..##..##..##...##."
        PIXELS  "##..........................................##"
        PIXELS  "##.................#.#.#.#..................##"
        PIXELS  "##..........................................##"
        PIXELS  ".############################################."

trackstar_bits:
        PIXELS  ".........######################################........."
        PIXELS  "........##....................................##........"
        PIXELS  "........##...##############################...##........"
        PIXELS  "........##..##........................######..##........"
        PIXELS  "........##..##..##..##..##..##........######..##........"
        PIXELS  "........##..##........................######..##........"
        PIXELS  "........##..##..##..##................##..##..##........"
        PIXELS  "........##..##........................######..##........"
        PIXELS  "........##..##..##....................##..##..##........"
        PIXELS  "........##..##........................######..##........"
        PIXELS  "........##..##........................##..##..##........"
        PIXELS  "........##..##........................######..##........"
        PIXELS  "........##...##############################...##........"
        PIXELS  "........##....................................##........"
        PIXELS  ".........######################################........."
        PIXELS  "................##....................##................"
        PIXELS  "..####################################################.."
        PIXELS  ".##..................................................##."
        PIXELS  ".##...###.............#############################..##."
        PIXELS  ".##...###.............##############.##############..##."
        PIXELS  "##....................##..........##.##..........##...##"
        PIXELS  "##..#.#.#.#.#.#.#.#...##############.##############...##"
        PIXELS  "##..#.#.#.#.#.#.#.#...#############################...##"
        PIXELS  "##....................................................##"
        PIXELS  ".######################################################."

mega_iie_bits:
        PIXELS  "....##..##..##..##..##..##..##..##..##..##...."
        PIXELS  "..##########################################.."
        PIXELS  "####......................................####"
        PIXELS  "..##.......#.###..........................##.."
        PIXELS  "####....#.#.#.####..#...#.#.....###.###...####"
        PIXELS  "..##...###.#.#.####.#...#.#....#.....#....##.."
        PIXELS  "####...####.#.#####..#.#..#.....##...#....####"
        PIXELS  "..##...#####.######..#.#..#.......#..#....##.."
        PIXELS  "####....##########....#...####.###..###...####"
        PIXELS  "..##......######..........................##.."
        PIXELS  "####......................................####"
        PIXELS  "..##......................................##.."
        PIXELS  "####..##.##.##.##.##.........##.##.##.##..####"
        PIXELS  "..##......................................##.."
        PIXELS  "####..##.##.##.##.##.##...................####"
        PIXELS  "..##......................................##.."
        PIXELS  "####..##.##.##.##.##.##.##.##.............####"
        PIXELS  "..##......................................##.."
        PIXELS  "####..##.##.##.##.##.##.##.##.##..........####"
        PIXELS  "..##......................................##.."
        PIXELS  "..##########################################.."
        PIXELS  "....##..##..##..##..##..##..##..##..##..##...."

pravetz_bits:
        PIXELS  ".......####################################......."
        PIXELS  "......##..................................##......"
        PIXELS  "......##...########################.......##......"
        PIXELS  "......##..##......................##......##......"
        PIXELS  "......##..##......#####...##......##......##......"
        PIXELS  "......##..##....######......###...##..##..##......"
        PIXELS  "......##..##.....##...##......##..##..##..##......"
        PIXELS  "......##..##............##....##..##......##......"
        PIXELS  "......##..##....####......##..##..##..##..##......"
        PIXELS  "......##..##...##..###......##....##..##..##......"
        PIXELS  "......##..##..##......######..##..##......##......"
        PIXELS  "......##..##......................##..##..##......"
        PIXELS  "......##...########################...##..##......"
        PIXELS  "......##..................................##......"
        PIXELS  ".......####################################......."
        PIXELS  ".........##............................##........."
        PIXELS  ".......####################################......."
        PIXELS  ".....###..................................###....."
        PIXELS  "...###....##..##..##..##..##..##..##..##....###..."
        PIXELS  ".###....##..##..##..##..##..##..##..##..##....###."
        PIXELS  "##....##..##..##..##..##..##..##..##..##..##....##"
        PIXELS  "##..............................................##"
        PIXELS  "##..............................................##"
        PIXELS  ".###############################################.."

;;; ============================================================

        DEFINE_POINT model_pos, 150, 12
        DEFINE_POINT pdver_pos, 150, 23
        DEFINE_POINT mem_pos, 150, 34

        DEFINE_POINT line1, 0, 37
        DEFINE_POINT line2, kDAWidth, 37

        DEFINE_POINT pos_slot1, 45, 50
        DEFINE_POINT pos_slot2, 45, 61
        DEFINE_POINT pos_slot3, 45, 72
        DEFINE_POINT pos_slot4, 45, 83
        DEFINE_POINT pos_slot5, 45, 94
        DEFINE_POINT pos_slot6, 45, 105
        DEFINE_POINT pos_slot7, 45, 116

;;; ============================================================

ep_start:
        .include "../lib/event_params.s"

.params trackgoaway_params
clicked:        .byte   0
.endparams

ep_size := * - ep_start

;;; ============================================================

buf_string := *
.assert buf_string + 256 < $2000, error, "DA too large"

;;; ============================================================

        DA_END_AUX_SEGMENT
        DA_START_MAIN_SEGMENT

;;; ============================================================

        ;; Some static checks where we can cache the results.
        jsr     IdentifyModel
        jsr     IdentifyProDOSVersion
        jsr     IdentifyMemory

        ;; And run from main
        jmp     Init

;;; ============================================================

ep_start:
        .include "../lib/event_params.s"

.params trackgoaway_params
clicked:        .byte   0
.endparams

ep_size := * - ep_start
        .assert ep_size = aux::ep_size, error, "param mismatch aux vs. main"

.proc CopyEventDataToMain
        copy16  #aux::event_params, STARTLO
        copy16  #aux::event_params+ep_size-1, ENDLO
        copy16  #event_params, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=0  ; aux>main
.endproc ; CopyEventDataToMain

.proc CopyEventDataToAux
        copy16  #event_params, STARTLO
        copy16  #event_params+ep_size-1, ENDLO
        copy16  #aux::event_params, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=1  ; main>aux
.endproc ; CopyEventDataToAux

;;; ============================================================

str_ii:
        PASCAL_STRING res_string_model_ii

str_iiplus:
        PASCAL_STRING res_string_model_iiplus

str_iii:
        PASCAL_STRING res_string_model_iii

str_iie_original:
        PASCAL_STRING res_string_model_iie_original

str_iie_enhanced:
        PASCAL_STRING res_string_model_iie_enhanced

str_iie_edm:
        PASCAL_STRING res_string_model_iie_edm

str_iie_card:
        PASCAL_STRING res_string_model_iie_card

str_iic_original:
        PASCAL_STRING res_string_model_iic_original

str_iic_rom0:
        PASCAL_STRING res_string_model_iic_rom0

str_iic_rom3:
        PASCAL_STRING res_string_model_iic_rom3

str_iic_rom4:
        PASCAL_STRING res_string_model_iic_rom4

str_iic_plus:
        PASCAL_STRING res_string_model_iic_plus

str_iigs:
        PASCAL_STRING res_string_model_iigs_pattern
        kStrIIgsROMOffset = res_const_model_iigs_pattern_offset1

str_laser128:
        PASCAL_STRING res_string_model_laser128

str_ace500:
        PASCAL_STRING res_string_model_ace500

str_ace2000:
        PASCAL_STRING res_string_model_ace2000

str_tlc:
        PASCAL_STRING res_string_model_tlc

str_trackstar_e:
        PASCAL_STRING res_string_model_trackstar_e

str_trackstar_plus:
        PASCAL_STRING res_string_model_trackstar_plus

str_mega_iie:
        PASCAL_STRING res_string_model_mega_iie

str_tk3000:
        PASCAL_STRING res_string_model_tk3000

str_pravetz:
        PASCAL_STRING res_string_model_pravetz

;;; ============================================================

str_prodos_version:
        PASCAL_STRING res_string_prodos_version_pattern
        kVersionStrMajor = res_const_prodos_version_pattern_offset1
        kVersionStrMinor = res_const_prodos_version_pattern_offset2
        kVersionStrPatch = res_const_prodos_version_pattern_offset3

str_slot_n:
        PASCAL_STRING res_string_slot_n_pattern
        kStrSlotNOffset = res_const_slot_n_pattern_offset1

str_memory_prefix:
        PASCAL_STRING res_string_memory_prefix

str_memory_kb_suffix:
        PASCAL_STRING res_string_memory_kb_suffix ; memory size suffix for kilobytes
str_memory_mb_suffix:
        PASCAL_STRING res_string_memory_mb_suffix ; memory size suffix for megabytes

str_list_separator:
        PASCAL_STRING ", "

memory:.word    0
memory_is_mb_flag:      .byte   0 ; bit7

;;; ============================================================

str_cpu_prefix: PASCAL_STRING res_string_cpu_prefix
str_6502:       PASCAL_STRING res_string_cpu_type_6502
str_65C02:      PASCAL_STRING res_string_cpu_type_65C02
str_65C02zip:   PASCAL_STRING res_string_cpu_type_65C02zip
str_R65C02:     PASCAL_STRING res_string_cpu_type_R65C02
str_65802:      PASCAL_STRING res_string_cpu_type_65802
str_65816:      PASCAL_STRING res_string_cpu_type_65816

;;; ============================================================

model:                .byte   0
model_str_ptr:        .addr   0
model_pix_ptr:        .addr   0


slot_pos_table:
        .addr 0, aux::pos_slot1, aux::pos_slot2, aux::pos_slot3, aux::pos_slot4, aux::pos_slot5, aux::pos_slot6, aux::pos_slot7

;;; ============================================================

kMaxSmartportDevices = 8

str_diskii:     PASCAL_STRING res_string_card_type_diskii
str_nvram:      PASCAL_STRING res_string_device_type_nvram
str_booti:      PASCAL_STRING res_string_device_type_booti
str_xdrive:     PASCAL_STRING res_string_device_type_xdrive
str_block:      PASCAL_STRING res_string_card_type_block
str_smartport:  PASCAL_STRING res_string_card_type_smartport
str_ssc:        PASCAL_STRING res_string_card_type_ssc
str_80col:      PASCAL_STRING res_string_card_type_80col
str_mouse:      PASCAL_STRING res_string_card_type_mouse
str_silentype:  PASCAL_STRING res_string_card_type_silentype
str_clock:      PASCAL_STRING res_string_card_type_clock
str_comm:       PASCAL_STRING res_string_card_type_comm
str_serial:     PASCAL_STRING res_string_card_type_serial
str_parallel:   PASCAL_STRING res_string_card_type_parallel
str_printer:    PASCAL_STRING res_string_card_type_printer
str_joystick:   PASCAL_STRING res_string_card_type_joystick
str_io:         PASCAL_STRING res_string_card_type_io
str_modem:      PASCAL_STRING res_string_card_type_modem
str_audio:      PASCAL_STRING res_string_card_type_audio
str_storage:    PASCAL_STRING res_string_card_type_storage
str_network:    PASCAL_STRING res_string_card_type_network
str_mockingboard: PASCAL_STRING res_string_card_type_mockingboard
str_z80:        PASCAL_STRING res_string_card_type_z80
str_uthernet2:  PASCAL_STRING res_string_card_type_uthernet2
str_passport:   PASCAL_STRING res_string_card_type_passport
str_lcmeve:     PASCAL_STRING res_string_card_type_lcmeve
str_vidhd:      PASCAL_STRING res_string_card_type_vidhd
str_grappler:   PASCAL_STRING res_string_card_type_grappler
str_thunderclock: PASCAL_STRING res_string_card_type_thunderclock
str_applecat:   PASCAL_STRING res_string_card_type_applecat
str_workstation: PASCAL_STRING res_string_card_type_workstation
str_cricket:    PASCAL_STRING res_string_device_type_cricket
str_unknown:    PASCAL_STRING res_string_unknown
str_empty:      PASCAL_STRING res_string_empty
str_none:       PASCAL_STRING res_string_none

str_duplicate_suffix:   PASCAL_STRING res_string_duplicate_suffix_pattern
kDuplicateCountOffset = res_const_duplicate_suffix_pattern_offset1

;;; ============================================================

dib_buffer:     .tag    SPDIB
kMaxSPDeviceNameLength = SPDIB::Device_Type_Code - SPDIB::Device_Name

;;; ============================================================
;;; Per Technical Note: Apple II Miscellaneous #7: Apple II Family Identification
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/misc/tn.misc.07.html
;;; and c/o JohnMBrooks

;;; Machine                    $FBB3    $FB1E    $FBC0    $FBDD    $FBBF
;;; --------------------------------------------------------------------
;;; Apple ][                    $38     [$AD]    [$60]    [$A9]    [$2F]
;;; Apple ][+                   $EA      $AD     [$EA]    [$A9]    [$EA]
;;; Apple /// (emulation)       $EA      $8A
;;; Apple IIe                   $06     [$AD]     $EA     [$A9]    [$00]
;;; Apple IIe (enhanced)        $06     [$AD]     $E0     [$A9]    [$00]
;;; Apple IIe (Ext. Debug Mon.) $06     [$AD]     $E1
;;; Apple IIe Option Card *     $06     [$AD]     $E0      $02
;;; Apple IIc **                $06     [$4C]     $00     [$A9]     $FF
;;; Apple IIc (3.5 ROM)         $06     [$4C]     $00     [$A9]     $00
;;; Apple IIc (Org. Mem. Exp.)  $06     [$4C]     $00     [$A9]     $03
;;; Apple IIc (Rev. Mem. Exp.)  $06     [$4C]     $00     [$A9]     $04
;;; Apple IIc Plus              $06     [$4C]     $00     [$A9]     $05
;;; Apple IIgs ***              $06     [$4C]     $E0     [$00]    [$00]
;;; Laser 128                   $06      $AC     [$E0]    [$8D]    [$00]
;;; Franklin ACE 500            $06      $AD      $00      $4C     [$00]
;;; Franklin ACE 2000 ****      $06      $AD    $EA/$E0    $4C     [$00]
;;; Trackstar E                 $06     [$AD]     $EA      $A9      $EA
;;; Trackstar Plus              $06     [$AD]     $E0      $A9      $EA
;;;
;;; (Values in [] are for reference, not needed for compatibility check)
;;;
;;; * = $FBBE is the version byte for the Apple IIe Card.
;;;   $00 = v1.0 - first release, requires an original LC, doesn't support hard drives
;;;   $01 = v2.0 - (pic of install disk on vectronics apple world)
;;;   $02 = v2.1
;;;   $03 = v2.2.x - latest Apple release of IIe Startup (c/o MG & Frank M.)
;;;
;;; ** = $FBBF is the version byte for the Apple IIc family:
;;;   $FF = Original
;;;   $00 = 3.5 ROM
;;;   $03 = Original Memory Expansion
;;;   $04 = Revised Memory Expansion
;;;   $05 = IIc Plus
;;;
;;; *** = Apple IIgs looks like an Enhanced IIe. SEC, JSR $FE1F, CC=IIgs
;;;
;;; **** = Franklin ACE 2000 appears to have different ROM versions:
;;;   v5.X - has $FBC0=$EA (like an original IIe), and does not have $60 (RTS)
;;;          at $FE1F, so the IIgs IDROUTINE must be used with caution: it
;;;          will modify A and output text!
;;;   v6.0 - has $FBC0=$E0 (like an enhanced IIe), and has $FE1F=$60
;;;
;;; The Tiger Learning Computer has identical ID bytes to the Enhanced IIe,
;;; but can be distinguished by the sequence $CC $D4 $D7 $C9 $CE $8D at $FACF
;;;
;;; The Microdigital TK-3000 //e has the string "TK3000//e" at $FF0A
;;;
;;; The Pravetz 8A and 8C look like an original IIe, with the string "ПРАВЕЦ" at $FB0A

.enum model
        ii                      ; Apple ][
        iiplus                  ; Apple ][+
        iii                     ; Apple /// (emulation)
        iie_original            ; Apple IIe (original)
        iie_enhanced            ; Apple IIe (enhanced)
        iie_edm                 ; Apple IIe (Extended Debugging Monitor)
        iic_original            ; Apple IIc
        iic_rom0                ; Apple IIc (3.5 ROM)
        iic_rom3                ; Apple IIc (Org. Mem. Exp.)
        iic_rom4                ; Apple IIc (Rev. Mem. Exp.)
        iic_plus                ; Apple IIc Plus
        iigs                    ; Apple IIgs
        iie_card                ; Apple IIe Option Card
        laser128                ; Laser 128
        ace500                  ; Franklin ACE 500
        ace2000                 ; Franklin ACE 2000
        tlc                     ; Tiger Learning Computer
        trackstar_e             ; Trackstar E
        trackstar_plus          ; Trackstar Plus
        mega_iie                ; Mega IIe
        tk3000                  ; Microdigital TK-3000 //e
        pravetz                 ; Pravetz 8A/C
        LAST
.endenum
kNumModels = model::LAST

model_str_table:
        .addr   str_ii           ; Apple ][
        .addr   str_iiplus       ; Apple ][+
        .addr   str_iii          ; Apple /// (emulation)
        .addr   str_iie_original ; Apple IIe (original)
        .addr   str_iie_enhanced ; Apple IIe (enhanced)
        .addr   str_iie_edm      ; Apple IIe (Extended Debugging Monitor)
        .addr   str_iic_original ; Apple IIc
        .addr   str_iic_rom0     ; Apple IIc (3.5 ROM)
        .addr   str_iic_rom3     ; Apple IIc (Org. Mem. Exp.)
        .addr   str_iic_rom4     ; Apple IIc (Rev. Mem. Exp.)
        .addr   str_iic_plus     ; Apple IIc Plus
        .addr   str_iigs         ; Apple IIgs
        .addr   str_iie_card     ; Apple IIe Option Card
        .addr   str_laser128     ; Laser 128
        .addr   str_ace500       ; Franklin ACE 500
        .addr   str_ace2000      ; Franklin ACE 2000
        .addr   str_tlc          ; Tiger Learning Computer
        .addr   str_trackstar_e  ; Trackstar E
        .addr   str_trackstar_plus ; Trackstar Plus
        .addr   str_mega_iie     ; Mega IIe
        .addr   str_tk3000       ; Microdigital TK-3000 //e
        .addr   str_pravetz      ; Pravetz 8A/C
        ASSERT_ADDRESS_TABLE_SIZE model_str_table, kNumModels

model_pix_table:
        .addr   aux::ii_bitmap       ; Apple ][
        .addr   aux::ii_bitmap       ; Apple ][+
        .addr   aux::iii_bitmap      ; Apple /// (emulation)
        .addr   aux::iie_bitmap      ; Apple IIe (original)
        .addr   aux::iie_bitmap      ; Apple IIe (enhanced)
        .addr   aux::iie_bitmap      ; Apple IIe (Extended Debugging Monitor)
        .addr   aux::iic_bitmap      ; Apple IIc
        .addr   aux::iic_bitmap      ; Apple IIc (3.5 ROM)
        .addr   aux::iic_bitmap      ; Apple IIc (Org. Mem. Exp.)
        .addr   aux::iic_bitmap      ; Apple IIc (Rev. Mem. Exp.)
        .addr   aux::iic_bitmap      ; Apple IIc Plus
        .addr   aux::iigs_bitmap     ; Apple IIgs
        .addr   aux::iie_card_bitmap ; Apple IIe Option Card
        .addr   aux::laser128_bitmap ; Laser 128
        .addr   aux::ace500_bitmap   ; Franklin ACE 500
        .addr   aux::ace2000_bitmap  ; Franklin ACE 2000
        .addr   aux::tlc_bitmap      ; Tiger Learning Computer
        .addr   aux::trackstar_bitmap ; Trackstar E
        .addr   aux::trackstar_bitmap ; Trackstar Plus
        .addr   aux::mega_iie_bitmap ; Mega IIe
        .addr   aux::iie_bitmap      ; Microdigital TK-3000 //e
        .addr   aux::pravetz_bitmap  ; Pravetz 8A/C
        ASSERT_ADDRESS_TABLE_SIZE model_pix_table, kNumModels

;;; Based on Technical Note: Miscellaneous #2: Apple II Family Identification Routines 2.1
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/misc/tn.misc.07.html
;;; Note that IIgs resolves as IIe (enh.) and is identified by ROM call.
;;;
;;; Format is: model (enum), then byte pairs [$FBxx, expected], then $00

MODEL_ID_PAGE := $FB00

model_lookup_table:
        .byte   model::ii
        .byte   $B3, $38, 0

        .byte   model::iiplus
        .byte   $B3, $EA, $1E, $AD, 0

        .byte   model::iii
        .byte   $B3, $EA, $1E, $8A, 0

        .byte   model::laser128
        .byte   $B3, $06, $1E, $AC, 0

        .byte   model::ace500
        .byte   $B3, $06, $1E, $AD, $C0, $00, 0

        .byte   model::ace2000  ; must check before IIe
        .byte   $B3, $06, $1E, $AD, $C0, $E0, $DD, $4C, 0

        .byte   model::trackstar_e ; must check before IIe
        .byte   $B3, $06, $C0, $EA, $DD, $A9, $BF, $EA, 0

        .byte   model::trackstar_plus ; must check before IIe
        .byte   $B3, $06, $C0, $E0, $DD, $A9, $BF, $EA, 0

        .byte   model::mega_iie ; must check before IIe
        .byte   $09, $CD, $0A, $E5, $0B, $E7, $0C, $E1, $0D, $A0, $0E, $C9, $0F, $C9, $10, $E5, 0

        .byte   model::iie_original
        .byte   $B3, $06, $C0, $EA, 0

        .byte   model::iie_card ; must check before IIe enhanced check
        .byte   $B3, $06, $C0, $E0, $DD, $02, 0

        .byte   model::iie_enhanced
        .byte   $B3, $06, $C0, $E0, 0

        .byte   model::iic_original
        .byte   $B3, $06, $C0, $00, $BF, $FF, 0

        .byte   model::iic_rom0
        .byte   $B3, $06, $C0, $00, $BF, $00, 0

        .byte   model::iic_rom3
        .byte   $B3, $06, $C0, $00, $BF, $03, 0

        .byte   model::iic_rom4
        .byte   $B3, $06, $C0, $00, $BF, $04, 0

        .byte   model::iic_plus
        .byte   $B3, $06, $C0, $00, $BF, $05, 0

        .byte   $FF             ; sentinel


;;; c/o https://github.com/david-schmidt/tlc-apple2/issues/1
tlc_sequence:
        .byte   $CC, $D4, $D7, $C9, $CE, $8D ; "LTWIN" CR
        kTLCSequenceLength = * - tlc_sequence
        TLC_ID_ADDR = $FAFC

tk3000_sequence:
        .byte   $D4, $CB, $B3, $B0, $B0, $B0, $AF, $AF, $E5 ; "TK3000//e"
        kTK3000SequenceLength = * - tk3000_sequence
        TK3000_ID_ADDR = $FF0A

pravetz_8ac_sequence:
        .byte   $F0, $F2, $E1, $F7, $E5, $E3 ; "ПРАВЕЦ"
        kPravetz8ACSequenceLength = * - pravetz_8ac_sequence
        PRAVETZ_8AC_ID_ADDR = $FB0A

.proc IdentifyModel
        ;; Read from ROM
        bit     ROMIN2

        ldx     #0              ; offset into table

        ;; For each model...
    DO
        ldy     model_lookup_table,x ; model number
        bmi     fail            ; hit end of table
        inx

        ;; For each byte/expected pair in table...
      DO
        lda     model_lookup_table,x ; offset from MODEL_ID_PAGE
        beq     match           ; success!
        sta     @lsb
        inx

        lda     model_lookup_table,x
        inx
        @lsb := *+1
        cmp     MODEL_ID_PAGE   ; self-modified
      WHILE EQ                  ; match, keep looking

        ;; No match, so skip to end of this entry
:       inx
        lda     model_lookup_table-1,x
    WHILE ZERO
        inx
        bne     :-

fail:   ldy     #0

match:  tya

    IF A = #model::iie_original
        ;; Is it a Pravetz 8A/C?
        ldx     #kPravetz8ACSequenceLength-1
      DO
        lda     PRAVETZ_8AC_ID_ADDR,x
        cmp     pravetz_8ac_sequence,x
        bne     :+
        dex
      WHILE POS
        lda     #model::pravetz
        bne     found           ; always
:
        lda     #model::iie_original
        .assert model::iie_original <> 0, error, "enum mismatch"
        bne     found           ; always
    END_IF

        ;; A has model; but now test for IIgs, TLC, and TK3000;
        ;; all masquerade as Enhanced IIe.
    IF A = #model::iie_enhanced

        CALL    IDROUTINE, C=1
      IF CC
        ;; Is IIgs; Y holds ROM revision
        tya
        ora     #'0'            ; convert to ASCII digit
        sta     str_iigs + kStrIIgsROMOffset
        lda     #model::iigs
        bne     found          ; always
      END_IF

        ;; Is it a TLC?
        ldx     #kTLCSequenceLength-1
      DO
        lda     TLC_ID_ADDR,x
        cmp     tlc_sequence,x
        bne     :+
        dex
      WHILE POS
        lda     #model::tlc
        bne     found           ; always
:
        ;; Is it a TK3000?
        ldx     #kTK3000SequenceLength-1
      DO
        lda     TK3000_ID_ADDR,x
        cmp     tk3000_sequence,x
        bne     :+
        dex
      WHILE POS
        lda     #model::tk3000
        bne     found           ; always
:
        lda     #model::iie_enhanced
        FALL_THROUGH_TO found
    END_IF

found:
        ;; A has model
        sta     model
        jsr     SetModelPtrs

        ;; Read from LC RAM
        bit     LCBANK1
        bit     LCBANK1
        rts
.endproc ; IdentifyModel

;;; ============================================================

;;; Input: A = model index
;;; Output: Sets `model_str_ptr` and `model_pix_ptr`
.proc SetModelPtrs
        asl
        tax
        copy16  model_str_table,x, model_str_ptr
        copy16  model_pix_table,x, model_pix_ptr
        rts
.endproc ; SetModelPtrs

;;; ============================================================

;;; KVERSION Table
;;; $00         1.0.1
;;; $01         1.0.2
;;; $01         1.1.1
;;; $04         1.4
;;; $05         1.5
;;; $07         1.7
;;; $08         1.8
;;; $08         1.9
;;; $21         2.0.1
;;; $23         2.0.3
;;; $24         2.4.x

;;; Assert: Main is banked in
.proc IdentifyProDOSVersion

        ;; Read ProDOS version field from global page in main
        lda     KVERSION

        cmp     #$24
        bcs     v_2x
        cmp     #$20
        bcs     v_20x

        ;; $00...$08 are 1.x (roughly)
v_1x:   and     #$0F
        ora     #'0'
        sta     str_prodos_version + kVersionStrMinor
        copy8   #'1', str_prodos_version + kVersionStrMajor
        copy8   #10, str_prodos_version ; length
        rts

        ;; $20...$23 are 2.0.x (roughly)
v_20x:  and     #$0F
        ora     #'0'
        sta     str_prodos_version + kVersionStrPatch
        copy8   #'0', str_prodos_version + kVersionStrMinor
        copy8   #'2', str_prodos_version + kVersionStrMajor
        copy8   #12, str_prodos_version ; length
        rts

        ;; $24...??? are 2.x (so far?)
v_2x:   and     #$0F
        ora     #'0'
        sta     str_prodos_version + kVersionStrMinor
        copy8   #'2', str_prodos_version + kVersionStrMajor
        copy8   #10, str_prodos_version ; length
        rts
.endproc ; IdentifyProDOSVersion

;;; ============================================================

.proc Init
        JUMP_TABLE_MGTK_CALL MGTK::OpenWindow, aux::winfo
        jsr     DrawWindow
        JUMP_TABLE_MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        jsr     JUMP_TABLE_SYSTEM_TASK
        JUMP_TABLE_MGTK_CALL MGTK::GetEvent, aux::event_params
        jsr     CopyEventDataToMain
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     HandleDown
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     HandleKey
        jmp     InputLoop
.endproc ; InputLoop

.proc Exit
        JUMP_TABLE_MGTK_CALL MGTK::CloseWindow, aux::winfo
        jmp     JUMP_TABLE_CLEAR_UPDATES ; exits input loop
.endproc ; Exit

;;; ============================================================

.proc HandleKey
        lda     event_params::key
        jsr     ToUpperCase

        ldx     event_params::modifiers
    IF NOT_ZERO
        cmp     #kShortcutCloseWindow
        beq     Exit
        jmp     InputLoop
    END_IF

        cmp     #CHAR_ESCAPE
        beq     Exit

        cmp     #kShortcutEasterEgg
        beq     HandleEgg

        jmp     InputLoop
.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        JUMP_TABLE_MGTK_CALL MGTK::FindWindow, aux::findwindow_params
        jsr     CopyEventDataToMain
        lda     findwindow_params::window_id
        cmp     #aux::kDAWindowId
        bne     InputLoop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        beq     HandleDrag
        jmp     InputLoop
.endproc ; HandleDown

;;; ============================================================

.proc HandleClose
        JUMP_TABLE_MGTK_CALL MGTK::TrackGoAway, aux::trackgoaway_params
        jsr     CopyEventDataToMain
        lda     trackgoaway_params::clicked
        beq     InputLoop
        bne     Exit            ; always
.endproc ; HandleClose

;;; ============================================================

.proc HandleDrag
        copy8   #aux::kDAWindowId, dragwindow_params::window_id
        jsr     CopyEventDataToAux
        JUMP_TABLE_MGTK_CALL MGTK::DragWindow, aux::dragwindow_params
        jsr     CopyEventDataToMain

        lda     dragwindow_params::moved
    IF NS
        ;; Draw DeskTop's windows and icons.
        jsr     JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow
    END_IF

        jmp     InputLoop

.endproc ; HandleDrag

;;; ============================================================

.proc HandleEgg
        CALL    SetModelPtrs, A=egg

        ldx     egg
        inx
    IF X = #kNumModels
        ldx     #0
    END_IF
        stx     egg

        jsr     ClearWindow
        jsr     DrawWindow
        jmp     InputLoop

egg:    .byte   0
.endproc ; HandleEgg

;;; ============================================================

.proc ClearWindow
        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, aux::getwinport_params
        RTS_IF A = #MGTK::Error::window_obscured

        JUMP_TABLE_MGTK_CALL MGTK::SetPort, aux::grafport
        JUMP_TABLE_MGTK_CALL MGTK::PaintRect, aux::grafport + MGTK::GrafPort::maprect
        rts
.endproc ; ClearWindow

;;; ============================================================

.proc DrawWindow
        JUMP_TABLE_MGTK_CALL MGTK::GetWinPort, aux::getwinport_params
        RTS_IF A = #MGTK::Error::window_obscured

        JUMP_TABLE_MGTK_CALL MGTK::SetPort, aux::grafport
        JUMP_TABLE_MGTK_CALL MGTK::HideCursor

        copy16  model_pix_ptr, bits_addr
        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, aux::notpencopy
        JUMP_TABLE_MGTK_CALL MGTK::PaintBits, SELF_MODIFIED, bits_addr

        JUMP_TABLE_MGTK_CALL MGTK::MoveTo, aux::model_pos
        CALL    DrawStringFromMain, AX=model_str_ptr

        JUMP_TABLE_MGTK_CALL MGTK::MoveTo, aux::pdver_pos
        CALL    DrawStringFromMain, AX=#str_prodos_version

        JUMP_TABLE_MGTK_CALL MGTK::MoveTo, aux::line1
        JUMP_TABLE_MGTK_CALL MGTK::LineTo, aux::line2

        JUMP_TABLE_MGTK_CALL MGTK::MoveTo, aux::mem_pos
        CALL    DrawStringFromMain, AX=#str_memory_prefix
        CALL    DrawStringFromMain, AX=#str_from_int
        bit     memory_is_mb_flag
    IF NS
        CALL    DrawStringFromMain, AX=#str_memory_mb_suffix
    ELSE
        CALL    DrawStringFromMain, AX=#str_memory_kb_suffix
    END_IF
        CALL    DrawStringFromMain, AX=#str_cpu_prefix
        jsr     CPUId
        jsr     DrawStringFromMain

        copy8   #7, slot
        copy8   #1<<7, mask

    DO
        lda     slot
        asl
        tax
        copy16  slot_pos_table,x, slot_pos
        JUMP_TABLE_MGTK_CALL MGTK::MoveTo, 0, slot_pos
        lda     slot
        ora     #'0'
        sta     str_slot_n + kStrSlotNOffset
        CALL    DrawStringFromMain, AX=#str_slot_n

        ;; Possibilities:
        ;; * ProDOS thinks there's a card - may be firmware or no firmware
        ;; * ProDOS thinks there's no card, because it doesn't have firmware
        ;; * ProDOS thinks there's no card, because it's empty

        ;; Check ProDOS slot bit mask
        lda     SLTBYT
        and     mask
      IF NOT_ZERO
        ;; ProDOS thinks there's a card...
        CALL    ProbeSlot, A=slot ; check for matching firmware
        bcs     draw

        ;; check non-firmware cases in case of false-positive (e.g. emulator)
        CALL    ProbeSlotNoFirmware, A=slot
        bcs     draw

        ldax    #str_unknown
        bne     draw            ; always
      END_IF

        CALL    ProbeSlotNoFirmware, A=slot
        bcs     draw

        ldax    #str_empty

draw:   php
        jsr     DrawStringFromMain
        plp
      IF VS
        ;; V=1 means smartport - print out the names
        CALL    SetSlotPtr, A=slot
        jsr     ShowSmartPortDeviceNames
      END_IF

        ;; Special case for Slot 2
        lda     slot
      IF A = #2
        jsr     SetSlotPtr
        CALL    WithInterruptsDisabled, AX=#DetectTheCricket
       IF CS
        CALL    DrawStringFromMain, AX=#str_list_separator
        CALL    DrawStringFromMain, AX=#str_cricket
       END_IF
      END_IF

        ;; Special case for Slot 3 cards
        lda     slot
      IF A = #3
        bit     ROMIN2
        jsr     DetectLeChatMauveEve
        php
        bit     LCBANK1
        bit     LCBANK1
        plp
       IF ZC
        CALL    DrawStringFromMain, AX=#str_list_separator
        CALL    DrawStringFromMain, AX=#str_lcmeve
       ELSE
        CALL    SetSlotPtr, A=slot
        CALL    WithInterruptsDisabled, AX=#DetectUthernet2
        IF CS
        CALL    DrawStringFromMain, AX=#str_list_separator
        CALL    DrawStringFromMain, AX=#str_uthernet2
        END_IF
       END_IF
      END_IF

        lsr     mask
        dec     slot
    WHILE NOT ZERO

        JUMP_TABLE_MGTK_CALL MGTK::ShowCursor
        rts

slot:   .byte   0
mask:   .byte   0
.endproc ; DrawWindow

;;; ============================================================
;;; Point $06/$07 at $Cn00
;;; Input: Slot in A
.proc SetSlotPtr
        ptr     := $6

        ora     #$C0
        sta     ptr+1
        copy8   #0, ptr
        rts
.endproc ; SetSlotPtr

;;; ============================================================
;;; Firmware Detector:
;;; Input: Slot # in A
;;; Output: Carry set and string ptr in A,X if detected, carry clear otherwise
;;;         Overflow set if SmartPort.
;;;
;;; Uses a variety of sources:
;;; * Technical Note: ProDOS #21: Identifying ProDOS Devices
;;;   https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/pdos/tn.pdos.21.html
;;; * Technical Note: Miscellaneous #8: Pascal 1.1 Firmware Protocol ID Bytes
;;;   https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/misc/tn.misc.08.html
;;; * "ProDOS BASIC Programming Examples" disk

.proc ProbeSlot
        ptr     := $6

        ;; Point ptr at $Cn00
        jsr     SetSlotPtr

        ;; Get Firmware Byte
.macro GET_FWB offset
        ldy     #offset
        lda     (ptr),y
.endmacro

        ;; Compare Firmware Byte
.macro COMPARE_FWB offset, value
        GET_FWB  offset
        cmp     #value
.endmacro

;;; ---------------------------------------------
;;; Per Technical Note: Miscellaneous #8: Pascal 1.1 Firmware Protocol ID Bytes
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/misc/tn.misc.08.html

;;; ProDOS and SmartPort Devices

        CALL    SigCheck, AX=#sigtable_prodos_device
    IF CS

;;; Per Technical Note: ProDOS #21: Identifying ProDOS Devices
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/pdos/tn.pdos.21.html
        COMPARE_FWB $FF, $00    ; $CnFF == $00 ?
      IF EQ
        RETURN  AX=#str_diskii
      END_IF

        ;; Smartport?
        COMPARE_FWB $07, $00    ; $Cn07 == $00 ?
      IF EQ
        sec
        bit     ret             ; set V flag to signal SmartPort
        ldax    #str_smartport
ret:    rts
      END_IF

        ;; Block devices - a few signatures
        CALL    SigCheck, AX=#sigtable_nvram
      IF CS
        RETURN  AX=#str_nvram
      END_IF

        CALL    SigCheck, AX=#sigtable_booti
      IF CS
        RETURN  AX=#str_booti
      END_IF

        CALL    SigCheck, AX=#sigtable_xdrive
      IF CS
        RETURN  AX=#str_xdrive
      END_IF

        sec
        RETURN  AX=#str_block

    END_IF

;;; ---------------------------------------------
;;; VidHD

        CALL    SigCheck, AX=#sigtable_vidhd
    IF CS
        RETURN  AX=#str_vidhd
    END_IF

;;; ---------------------------------------------
;;; Apple IIe Technical Reference Manual
;;; Pascal 1.1 firmware protocol
;;;
;;; $Cs05       $38 (like the old Apple II Serial Interface card)
;;; $Cs07       $18 (like the old Apple II Serial Interface card)
;;; $Cs0B       $01 (the generic signature of new cards)
;;; $Cs0C       $ci (the device signature)
;;;              c = device class
;;;              i = unique identifier

        CALL    SigCheck, AX=#sigtable_pascal_device
        jcc     notpas

        ;; Workstation card has same ID bytes as Super Serial Card,
        ;; so test a few more after the Pascal 1.1 firmware signature
        CALL    SigCheck, AX=#sigtable_workstation
    IF CS
        RETURN  AX=#str_workstation
    END_IF

        GET_FWB $0C             ; $Cn0C == ....

.macro IF_SIGNATURE_THEN_RETURN     byte, arg
        cmp     #byte
    IF EQ
        RETURN  AX=#arg         ; C=1 implicitly if Z=1
    END_IF
.endmacro

        ;; Specific Apple cards/built-ins
    IF_SIGNATURE_THEN_RETURN $31, str_ssc
    IF_SIGNATURE_THEN_RETURN $88, str_80col
    IF_SIGNATURE_THEN_RETURN $20, str_mouse
    IF_SIGNATURE_THEN_RETURN $14, str_grappler
    IF_SIGNATURE_THEN_RETURN $41, str_applecat

        ;; Generic cards
        and     #$F0            ; just device class nibble
    IF_SIGNATURE_THEN_RETURN $10, str_printer
    IF_SIGNATURE_THEN_RETURN $20, str_joystick
    IF_SIGNATURE_THEN_RETURN $30, str_io
    IF_SIGNATURE_THEN_RETURN $40, str_modem
    IF_SIGNATURE_THEN_RETURN $50, str_audio
    IF_SIGNATURE_THEN_RETURN $60, str_clock
    IF_SIGNATURE_THEN_RETURN $70, str_storage
    IF_SIGNATURE_THEN_RETURN $80, str_80col
    IF_SIGNATURE_THEN_RETURN $90, str_network

        ;; Pascal Firmware, but unknown type. Return
        ;; "unknown" otherwise it will be detected as serial below.
        sec
        RETURN  AX=#str_unknown

notpas:

;;; ---------------------------------------------
;;; Based on ProDOS detection

;;; ThunderClock
        CALL    SigCheck, AX=#sigtable_thunderclock
    IF CS
        RETURN  AX=#str_thunderclock
    END_IF

;;; ---------------------------------------------
;;; Based on ProDOS BASIC Programming Examples

;;; Silentype
        CALL    SigCheck, AX=#sigtable_silentype
    IF CS
        RETURN  AX=#str_silentype
    END_IF

;;; Clock
        CALL    SigCheck, AX=#sigtable_clock
    IF CS
        RETURN  AX=#str_clock
    END_IF

;;; Communications Card
        CALL    SigCheck, AX=#sigtable_comm
    IF CS
        RETURN  AX=#str_comm
    END_IF

;;; Serial Card
        CALL    SigCheck, AX=#sigtable_serial
    IF CS
        RETURN  AX=#str_serial
    END_IF

;;; Parallel Card
        CALL    SigCheck, AX=#sigtable_parallel
    IF CS
        RETURN  AX=#str_parallel
    END_IF

        rts

;;; Input: A,X = pointer to table (num, offset, value, offset, value, ...)
;;; Output: C=1 on match, C=0 on no match
.proc SigCheck
        stax    table_ptr

        ldx     #0              ; first byte in table is number of pairs
        jsr     get_next
        asl     a               ; if 2 entries, then point at table[4] (etc)
        tax

    DO
        jsr     get_next        ; second byte in pair is value
        sta     @compare_byte
        dex
        jsr     get_next        ; first byte in pair is offset
        tay
        lda     (ptr),y
        @compare_byte := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     no_match
        dex
    WHILE NOT_ZERO

        ;; match
        RETURN  C=1

no_match:
        RETURN  C=0

get_next:
        table_ptr := *+1
        lda     SELF_MODIFIED,x
        rts
.endproc ; SigCheck

;;; --------------------------------------------------
;;; Format is: num, offset, value, offset, value, ...

;;; Firmware protocol signatures
sigtable_pascal_device: .byte   3, $05, $38, $07, $18, $0B, $01
sigtable_prodos_device: .byte   3, $01, $20, $03, $00, $05, $03

;;; Specific device signatures
sigtable_vidhd:         .byte   3, $00, $24, $01, $EA, $02, $4C
sigtable_silentype:     .byte   3, $17, $C9, $37, $CF, $4C, $EA
sigtable_thunderclock:  .byte   4, $00, $08, $02, $28, $04, $58, $06, $70
sigtable_workstation:   .byte   4, $0C, $31, $0D, $9D, $0E, $A3, $0F, $24

;;; Generic signatures (c/o ProDOS BASIC Programming Examples)
sigtable_clock:         .byte   3, $00, $08, $01, $78, $02, $28
sigtable_comm:          .byte   2, $05, $18, $07, $38
sigtable_serial:        .byte   2, $05, $38, $07, $18
sigtable_parallel:      .byte   2, $05, $48, $07, $48

;;; Block Devices
sigtable_nvram:         .byte   3, $07, $3C, $0B, $58, $0C, $FF
sigtable_booti:         .byte   4, $07, $3C, $0B, $B0, $0C, $01, $F0, $D5
sigtable_xdrive:        .byte   4, $07, $3C, $0B, $B0, $0C, $01, $F0, $CA

.endproc ; ProbeSlot

;;; ============================================================
;;; Check for cards without firmware.
;;; Input: Slot # in A
;;; Output: Carry set and string ptr in A,X if detected, carry clear otherwise

.proc ProbeSlotNoFirmware
        ;; Point ptr at $Cn00
        jsr     SetSlotPtr

        CALL    WithInterruptsDisabled, AX=#DetectMockingboard
    IF CS
        RETURN  AX=#str_mockingboard
    END_IF

        CALL    WithInterruptsDisabled, AX=#DetectZ80
    IF CS
        RETURN  AX=#str_z80
    END_IF

        CALL    WithInterruptsDisabled, AX=#DetectUthernet2
    IF CS
        RETURN  AX=#str_uthernet2
    END_IF

        CALL    WithInterruptsDisabled, AX=#DetectPassportMIDI
    IF CS
        RETURN  AX=#str_passport
    END_IF

        RETURN  C=0
.endproc ; ProbeSlotNoFirmware

;;; ============================================================

        .include "../lib/with_interrupts_disabled.s"

;;; ============================================================
;;; Detect Z80
;;; Assumes $06 points at $Cn00, returns carry set if found

;;; This routine gets swapped into $0FFD for execution
.assert * > $0FFD + sizeof_Z80Routine, error, "Z80 collision"

.proc Z80Routine
        target := $0FFD
        ;; .org $FFFD
        patch := *+2
        .byte   $32, $00, $e0   ; ld ($Es00),a   ; s=slot being probed turn off Z80, next PC is $0000
        .byte   $3e, $01        ; ld a,$01
        .byte   $32, $08, $00   ; ld (flag),a
        .byte   $c3, $fd, $ff   ; jp $FFFD
        flag := *
        .byte   $00             ; flag: .db $00
.endproc ; Z80Routine
        sizeof_Z80Routine = .sizeof(Z80Routine)

.proc DetectZ80
        ;; Convert $Cn to $En, update Z80 code
        lda     $07             ; $Cn
        ora     #$E0
        sta     Z80Routine::patch

        ;; Clear detection flag
        copy8   #0, Z80Routine::flag

        ;; Put routine in place
        jsr     SwapRoutine

        ;; Try to invoke Z80
        ldy     #0
        sta     ($06),y

        ;; Restore memory
        jsr     SwapRoutine

        ;; Flag will be set to 1 by routine if Z80 was present.
        lda     Z80Routine::flag
        ror                     ; move flag into carry
        rts

.proc SwapRoutine
        ldx     #.sizeof(Z80Routine)-1
    DO
        swap8   Z80Routine::target,x, Z80Routine,x
        dex
    WHILE POS
        rts
.endproc ; SwapRoutine
.endproc ; DetectZ80

;;; Detect Uthernet II
;;; Assumes $06 points at $Cn00, returns carry set if found

.proc DetectUthernet2
        ;;  Based on the a2RetroSystems Uthernet II manual

        MR := $C084
        ;; Mode Register
        ;; * bit 7 = Software Reset
        ;; * bit 6 = Reserved
        ;; * bit 5 = Reserved
        ;; * bit 4 = Ping Block mode
        ;; * bit 3 = PPPoE mode
        ;; * bit 2 = Not Used
        ;; * bit 1 = Address Auto-Increment
        ;; * bit 0 = Indirect Bus mode (must be 1 to operate)

        lda     $07             ; $Cn
        and     #$0F            ; $0n
        asl
        asl
        asl
        asl                     ; $n0
        tax                     ; Slot in high nibble of X

        ;; First, test if it is potentially an Uthernet II in operation
        ;; (e.g. running VEDRIVE). If so, avoid resetting it.
        lda     MR,x
        and     #%00000001      ; required for operation
        beq     oldtest         ; not set, try reset

        ;; --------------------------------------------------
        ;; Probe without resetting the device

        lda     MR,x
        and     #%01111111      ; Be absolutely sure we don't reset
        eor     #%01110111      ; Flip all the non-significant bits
        sta     MR,x
        cmp     MR,x            ; Did they "stick"?
        bne     fail
        eor     #%01110111      ; Flip them all back
        sta     MR,x
        cmp     MR,x            ; Did they "stick" again?
        beq     success
        bne     fail            ; always

        ;; --------------------------------------------------
        ;; Probe using reset
oldtest:
        ;; Send the RESET command
        copy8   #$80, MR,x
        nop
        nop
        lda     MR,x            ; Should get zero
        bne     fail

        ;; Configure operating mode with auto-increment
        copy8   #3, MR,x        ; Operating mode
        cmp     MR,x            ; Read back MR
        bne     fail

        ;; Probe successful
success:
        RETURN  C=1

fail:   RETURN  C=0
.endproc ; DetectUthernet2

;;; Detect Passport MIDI Card
;;; Assumes $06 points at $Cn00, returns carry set if found

.proc DetectPassportMIDI
        .include "../inc/passport_midi.inc"

        ;; Set up `read` and `write` subroutines
        lda     $07             ; A = $Cn
        asl
        asl
        asl
        asl                     ; A = $n0
        clc
        adc     #$80
        sta     read_lo
        sta     write_lo

        ;; ----------------------------------------
        ;; Initialize 6840 PTM timers

        kOpFlags = kInternalClock | kCounterSingle16Bit | kModeSingleShot | kInterruptsDisabled
        kMSBPattern1 = %10101010
        kLSBPattern1 = %11001001
        kMSBPattern2 = %01010101
        kLSBPattern2 = %00110110

        ;; Reset and hold timers
        CALL    write, A=#(kOpFlags | 1), X=#kOffsetWriteCR2 ; give write access to CR#1
        CALL    write, A=#(kOpFlags | 1), X=#kOffsetWriteCR13 ; timers hold (reset)

        ;; ----------------------------------------
        ;; Write to both Timer 1 and Timer 2

        ;; Write to MSB Buffer
        CALL    write, A=#kMSBPattern1, X=#kOffsetWriteMSBBuffer
        ;; Write to Timer 1 LSB
        CALL    write, A=#kLSBPattern1, X=#kOffsetWriteTimer1LSB
        ;; Write to MSB Buffer
        CALL    write, A=#kMSBPattern2, X=#kOffsetWriteMSBBuffer
        ;; Write to Timer 2 LSB
        CALL    write, A=#kLSBPattern2, X=#kOffsetWriteTimer2LSB

        ;; ----------------------------------------
        ;; Read back and verify

        ;; Read Timer 1 MSB
        CALL    read, X=#kOffsetReadTimer1MSB
        cmp     #kMSBPattern1
        bne     fail
        ;; Read LSB Buffer
        CALL    read, X=#kOffsetReadLSBBuffer
        cmp     #kLSBPattern1
        bne     fail
        ;; Read Timer 2 MSB
        CALL    read, X=#kOffsetReadTimer2MSB
        cmp     #kMSBPattern2
        bne     fail
        ;; Read LSB Buffer
        CALL    read, X=#kOffsetReadLSBBuffer
        cmp     #kLSBPattern2
        bne     fail

        ;; Probe successful
success:
        RETURN  C=1

fail:   RETURN  C=0

        ;; ----------------------------------------
        ;; LDX offset / JSR read / A = value
        read_lo := *+1
read:   lda     $C080,x         ; self-modified to $C0n0
        rts

        ;; ----------------------------------------
        ;; LDA value / LDX offset / JSR write
        write_lo := *+1
write:  sta     $C080,x         ; self-modified to $C0n0
        rts
.endproc ; DetectPassportMIDI

        .include "../lib/detect_mockingboard.s"
        .include "../lib/detect_thecricket.s"

;;; ============================================================
;;; Update `str_memory` with memory count in kilobytes

;;; Assert: Main is banked in (for `CheckSlinkyMemory` call)
.proc IdentifyMemory
        copy16  #0, memory
        jsr     CheckRamworksMemory
        sty     memory          ; Y is number of 64k banks
    IF Y = #0                   ; 0 means 256 banks
        inc     memory+1
    END_IF
        inc16   memory          ; Main 64k memory

        jsr     CheckIIgsMemory
        jsr     CheckSlinkyMemory

        lda     memory+1
        and     #%11111100
    IF ZERO
        ;; Convert number of 64K banks to KB
        ldy     #6
      DO
        asl16   memory          ; * 64
        dey
      WHILE NOT_ZERO
    ELSE
        ;; Convert number of 64K banks to MB
        ldy     #4
      DO
        lsr16   memory          ; / 16
        dey
      WHILE NOT_ZERO
        SET_BIT7_FLAG memory_is_mb_flag
    END_IF

        TAIL_CALL IntToStringWithSeparators, AX=memory
.endproc ; IdentifyMemory

;;; ============================================================
;;; Calculate RamWorks memory; returns number of banks in Y
;;; (256 banks = 0, since there must be at least 1)
;;;
;;; Note the bus floats for RamWorks RAM when the bank has no RAM,
;;; or bank selection may wrap to an earlier bank. This requires
;;; three passes (mark, count, restore); if count and restore are
;;; combined, it will produce false-positives if wrapping occurs
;;; (see https://github.com/a2stuff/a2d/issues/131).
;;;
;;; RamWorks-style cards are not guaranteed to have contiguous banks.
;;; a user can install 64Kb or 256Kb chips in a physical bank, in the
;;; former case, a gap in banks will appear.  Additionally, the piggy
;;; back cards may not have contiguous banks depending on capacity
;;; and installed chips.
;;;
;;; AE RamWorks cards can only support 8M max (banks $00-$7F), but
;;; the various emulators support 16M max (banks $00-$FF).
;;;
;;; If RamWorks is not present, bank switching is a no-op and the
;;; same regular 64Kb AUX bank is present throughout the test; this
;;; will be handled by an invalid signature check for other banks.
;;;
;;; Assert: Main is banked in
.proc CheckRamworksMemory
        sigb0   := $00
        sigb1   := $01

        ;; DAs are loaded with $1C00 as the io_buffer, so
        ;; $1C00-$1FFF MAIN is free.
        buf0    := DA_IO_BUFFER
        buf1    := DA_IO_BUFFER + $100

        php
        sei     ; don't let interrupts happen while the memory map is munged

        ;; Assumes ALTZPON on entry/exit
        ldy     #0              ; populated bank count

        ;; Iterate downwards (in case unpopulated banks wrap to earlier ones),
        ;; saving bytes and marking each bank.
.scope
        ldx     #255            ; bank we are checking
    DO
        stx     RAMWORKS_BANK
        copy8   sigb0, buf0,x   ; preserve bytes
        copy8   sigb1, buf1,x
        txa                     ; bank num as first signature
        sta     sigb0
        eor     #$FF            ; complement as second signature
        sta     sigb1
        dex
    WHILE X <> #255
.endscope

        ;; Iterate upwards, tallying valid banks.
.scope
        ldx     #0              ; bank we are checking
    DO
        stx     RAMWORKS_BANK   ; select bank
        txa
      IF A = sigb0              ; verify first signature
        eor     #$FF
       IF A = sigb1             ; verify second signature
        iny                     ; match - count it
       END_IF
      END_IF
        inx                     ; next bank
    WHILE NOT_ZERO              ; if we hit 256 banks, make sure we exit
.endscope

        ;; Iterate upwards, restoring valid banks.
.scope
        ldx     #0              ; bank we are checking
    DO
        stx     RAMWORKS_BANK   ; select bank
        txa
      IF A = sigb0              ; verify first signature
        eor     #$FF
       IF A = sigb1             ; verify second signature
        copy8   buf0,x, sigb0   ; match - restore it
        copy8   buf1,x, sigb1
       END_IF
      END_IF
        inx                     ; next bank
    WHILE NOT_ZERO              ; if we hit 256 banks, make sure we exit
.endscope

        ;; Switch back to RW bank 0 (normal aux memory)
        copy8   #0, RAMWORKS_BANK

        plp                     ; restore interrupt state
        rts
.endproc ; CheckRamworksMemory

;;; ============================================================

.proc CheckIIgsMemory
        bit     ROMIN2          ; Check ROM - is this a IIgs?
        CALL    IDROUTINE, C=1
        bit     LCBANK1
        bit     LCBANK1
    IF CC
        .pushcpu
        .setcpu "65816"
      IF Y <> #0                ; Y = IIgs ROM revision
        ;; From the IIgs Memory Manager tool set source
        ;; c/o Antoine Vignau and Dagen Brock (ROM 1 & ROM 3)
        NumBanks := $E11624
        copy16  NumBanks, memory
      ELSE
        ;; ROM0 location is slightly different
        ;; c/o Frank Milliron
        NumBanks0 := $E1161A
        copy16  NumBanks0, memory
      END_IF
        ;; The memory manager only counts banks $DF and downward,
        ;; which skips ROM ($Fx) and slow RAM ($Ex). Assume the
        ;; two banks of slow RAM that every IIgs has ($E0/$E1)
        add16_8 memory, #2
        .popcpu
    END_IF
        rts
.endproc ; CheckIIgsMemory

;;; ============================================================

;;; Assert: Main is banked in (due to SmartPort calls)

.proc CheckSlinkyMemory
        slot_ptr := $06

        copy8   #7, slot

    DO
        ;; Point at $Cn00
        CALL    SetSlotPtr, A=slot

        ;; Look for SmartPort signature bytes
        ldx     #3
      DO
        ldy     sig_offsets,x
        lda     (slot_ptr),y
        cmp     sig_values,x
        bne     next
        dex
      WHILE POS

        ;; Now look for device type
        ldy     #$FB            ; $CnFB is SmartPort ID Type byte
        lda     (slot_ptr),y
        and     #%00000001      ; bit 0 = RAM card
        beq     next

        ;; Locate SmartPort entry point: $Cn00 + ($CnFF) + 3
        ldy     #$FF
        lda     (slot_ptr),y
        clc
        adc     #3
        sta     sp_addr
        copy8   slot_ptr+1, sp_addr+1

        ;; Make a STATUS call
        ;; NOTE: Must be done from Main.
        ;; https://github.com/a2stuff/a2d/issues/483
        sp_addr := *+1
        jsr     SELF_MODIFIED
        .byte   $00             ; STATUS
        .addr   status_params
        bcs     next

        ;; Convert blocks (0.5k) to banks (64k)
        ldx     #7
      DO
        lsr     dib_buffer+SPDIB::Device_Size_Hi
        ror     dib_buffer+SPDIB::Device_Size_Med
        ror     dib_buffer+SPDIB::Device_Size_Lo
        dex
      WHILE NOT_ZERO

        ;; Rounding up if needed
      IF CS
        inc16   dib_buffer+SPDIB::Device_Size_Lo
      END_IF

        add16   memory, dib_buffer+SPDIB::Device_Size_Lo, memory

next:   dec     slot
    WHILE NOT_ZERO
        rts

sig_offsets:
        .byte   $01, $03, $05, $07
sig_values:
        .byte   $20, $00, $03, $00
slot:
        .byte   0

        DEFINE_SP_STATUS_PARAMS status_params, 1, dib_buffer, 3 ; Return Device Information Block (DIB)

.endproc ; CheckSlinkyMemory


;;; ============================================================
;;; Input: 16-bit unsigned integer in A,X
;;; Output: `str_from_int` populated, with separator if needed

str_from_int:
        PASCAL_STRING "000,000"


;;; ============================================================
;;; Identify CPU - string pointer returned in A,X

.proc CPUId
        sed
        lda     #$99
        clc
        adc     #$01
        cld
        bmi     p6502
        clc
        .pushcpu
        .setcpu "65816"
        sep     #%00000001    ; two-byte NOP on 65C02
        .popcpu
        bcs     p658xx

        ;; 65C02 - check for ZIP CHIP (except on IIc Plus)
        lda     model           ; cached
    IF A <> #model::iic_plus
        php                     ; timing sensitive
        sei

        ;; Unlock
        lda     #kZCUnlock
        sta     ZC_REG_LOCK
        sta     ZC_REG_LOCK
        sta     ZC_REG_LOCK
        sta     ZC_REG_LOCK

        ;; ZIP CHIP present?
        lda     ZC_REG_SLOTSPKR
        eor     #$FF
        sta     ZC_REG_SLOTSPKR
      IF A = ZC_REG_SLOTSPKR
        eor     #$FF
        sta     ZC_REG_SLOTSPKR
       IF A = ZC_REG_SLOTSPKR

        ;; Lock
        copy8   #kZCLock, ZC_REG_LOCK

        plp
        RETURN  AX=#str_65C02zip
        rts

       END_IF
      END_IF
        plp
    END_IF

        ;; 65C02 - check for Rockwell R65C02
        ;; (inspired by David Empson on comp.sys.apple2)
        .pushcpu
        .setcpu "65C02"
        .assert OPC_NOP = $EA, error, "NOP no no"
        ldx     $EA             ; save $EA
        lda     #$FF
        sta     $EA
        rmb1    $EA             ; Rockwell R65C02 only; else NOP NOP
        cmp     $EA
        stx     $EA             ; restore $EA
        beq     p65C02
        .popcpu

        RETURN  AX=#str_R65C02
p65C02: RETURN  AX=#str_65C02
p6502:  RETURN  AX=#str_6502

        ;; Distinguish 65802 and 65816 by machine ID
p658xx: bit     ROMIN2
        CALL    IDROUTINE, C=1
        bit     LCBANK1
        bit     LCBANK1
    IF CC
        RETURN  AX=#str_65816   ; Only IIgs supports 65816
    END_IF
        RETURN  AX=#str_65802   ; Other boards support 65802
.endproc ; CPUId

;;; ============================================================
;;; Look up and print SmartPort device names to current GrafPort.
;;; Inputs: $06 points at $Cn00

;;; Follows Technical Note: SmartPort #4: SmartPort Device Types
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/smpt/tn.smpt.4.html

.proc ShowSmartPortDeviceNamesImpl

        DEFINE_SP_STATUS_PARAMS status_params, 1, dib_buffer, 3 ; Return Device Information Block (DIB)

        slot_ptr := $06

start:
        SET_BIT7_FLAG empty_flag
        lda     #0
        sta     str_last
        sta     duplicate_count

        ;; Locate SmartPort entry point: $Cn00 + ($CnFF) + 3
        ldy     #$FF
        lda     (slot_ptr),y
        clc
        adc     #3
        sta     sp_addr
        copy8   slot_ptr+1, sp_addr+1

        ;; Query number of devices
        copy8   #0, status_params::unit_num ; SmartPort status itself
        copy8   #0, status_params::status_code
        jsr     SmartPortCall
        lda     dib_buffer+SPDIB::Number_Devices
    IF A >= #kMaxSmartportDevices
        lda     #kMaxSmartportDevices
    END_IF
        sta     num_devices
    IF ZERO
        jmp     finish          ; no devices!
    END_IF

        ;; Start with unit #1
        copy8   #1, status_params::unit_num
        copy8   #3, status_params::status_code ; Return Device Information Block (DIB)

device_loop:
        ;; Make the call
        jsr     SmartPortCall
        bcs     next

        ;; Trim trailing whitespace (seen in CFFA)
.scope
        ldy     dib_buffer+SPDIB::ID_String_Length
    IF NOT_ZERO
      DO
        lda     dib_buffer+SPDIB::Device_Name-1,y
        BREAK_IF A <> #' '
        dey
      WHILE NOT_ZERO
    END_IF
        sty     dib_buffer+SPDIB::ID_String_Length
.endscope

.if kBuildSupportsLowercase
        ;; Case-adjust
.scope
        ldy     dib_buffer+SPDIB::ID_String_Length
    IF NOT_ZERO
        dey
      IF NOT_ZERO
        ;; Look at prior and current character; if both are alpha,
        ;; lowercase current.
       DO
        CALL    IsAlpha, A=dib_buffer+SPDIB::Device_Name-1,y ; Test previous character
        IF EQ
        CALL    IsAlpha, A=dib_buffer+SPDIB::Device_Name,y ; Adjust this one if also alpha
         IF EQ
        lda     dib_buffer+SPDIB::Device_Name,y
        ora     #AS_BYTE(~CASE_MASK) ; guarded by `kBuildSupportsLowercase`
        sta     dib_buffer+SPDIB::Device_Name,y
         END_IF
        END_IF
        dey
       WHILE NOT_ZERO
      END_IF
    END_IF
.endscope
.endif

        str_current := dib_buffer+SPDIB::ID_String_Length

        ;; Empty?
        lda     dib_buffer+SPDIB::ID_String_Length
    IF ZERO
        .assert .strlen(res_string_unknown) < kMaxSPDeviceNameLength, error, "string length"
        COPY_STRING str_unknown, str_current
    END_IF

        ;; Same as last?
        jsr     CompareWithLast
    IF EQ
        inc     duplicate_count
        bne     next            ; always
    END_IF
        jsr     MaybeDrawDuplicateSuffix
        COPY_STRING str_current, str_last

        ;; Need a comma?
        bit     empty_flag
    IF NC
        CALL    DrawStringFromMain, AX=#str_list_separator
    END_IF
        CLEAR_BIT7_FLAG empty_flag ; saw a unit!

        ;; Draw the device name
        CALL    DrawStringFromMain, AX=#str_current

        ;; Next!
next:   lda     status_params::unit_num
        cmp     num_devices
        beq     finish
        inc     status_params::unit_num
        jmp     device_loop

finish:
        jsr     MaybeDrawDuplicateSuffix

        ;; If no units, populate with "(none)"
        bit     empty_flag
    IF NS
        CALL    DrawStringFromMain, AX=#str_none
    END_IF

        rts

str_last:
        .res    ::kMaxSPDeviceNameLength+1
duplicate_count:
        .byte   0
empty_flag:                     ; bit7 set while no entries seen
        .byte   0
num_devices:
        .byte   0

.proc SmartPortCall
        ;; NOTE: Must be done from Main.
        ;; https://github.com/a2stuff/a2d/issues/483
        sp_addr := * + 1
        jsr     SELF_MODIFIED
        .byte   SPCall::Status
        .addr   status_params
        rts
.endproc ; SmartPortCall
        sp_addr = SmartPortCall::sp_addr

.proc CompareWithLast
        lda     str_current
        cmp     str_last
    IF EQ
        tax
      DO
        lda     str_current,x
        BREAK_IF A <> str_last,x
        dex
      WHILE NOT_ZERO
    END_IF
        rts
.endproc ; CompareWithLast

.proc MaybeDrawDuplicateSuffix
        ldx     duplicate_count
    IF NOT_ZERO
        inx
        txa
        ora     #'0'
        sta     str_duplicate_suffix + kDuplicateCountOffset
        CALL    DrawStringFromMain, AX=#str_duplicate_suffix
        copy8   #0, duplicate_count
    END_IF
        rts
.endproc ; MaybeDrawDuplicateSuffix

.endproc ; ShowSmartPortDeviceNamesImpl
ShowSmartPortDeviceNames := ShowSmartPortDeviceNamesImpl::start


;;; ============================================================
;;; Inputs: Character in A
;;; Outputs: Z=1 if alpha, 0 otherwise
;;; A is trashed

.proc IsAlpha
        jsr     ToUpperCase
    IF A BETWEEN #'A', #'Z'
        lda     #0              ; set Z=1
        rts
    END_IF

        lda     #$FF            ; set Z=0
        rts
.endproc ; IsAlpha

;;; ============================================================
;;; Copies string main>aux before drawing
;;; Input: A,X = address of length-prefixed string

.proc DrawStringFromMain
        params  := $06
        textptr := $06
        textlen := $08

        stax    textptr
        stax    STARTLO
        ldy     #0
        lda     (textptr),y
    IF NOT_ZERO
        sta     textlen
        copy16  #aux::buf_string+1, textptr

        copy16  #aux::buf_string, DESTINATIONLO
        add16_8 STARTLO, textlen, ENDLO
        CALL    AUXMOVE, C=1    ; main>aux

        JUMP_TABLE_MGTK_CALL MGTK::DrawText, params
    END_IF
        rts
.endproc ; DrawStringFromMain

;;; ============================================================

        .include  "../lib/uppercase.s"
        .include  "../lib/detect_lcmeve.s"

        ReadSetting = JUMP_TABLE_READ_SETTING
        .include "../lib/inttostring.s"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
