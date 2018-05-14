       .setcpu "6502"

        .include "apple2.inc"
        .include "../macros.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"

L0000           := $0000
L0080           := $0080
L0CAF           := $0CAF
eject_disk      := $0CED
L0D26           := $0D26
L0D51           := $0D51
L0D5F           := $0D5F
L0DB5           := $0DB5
L0EB2           := $0EB2
L0ED7           := $0ED7
L10FB           := $10FB
L127E           := $127E
L1291           := $1291
L129B           := $129B
L12A5           := $12A5
L12AF           := $12AF
L51ED           := $51ED

.macro MGTK_RELAY_CALL2 call, params
    .if .paramcount > 1
        yax_call MGTK_RELAY2, call, params
    .else
        yax_call MGTK_RELAY2, call, 0
    .endif
.endmacro

        .org $D000

        jmp     LD5E1

;;; ============================================================
;;; Resources

pencopy:        .byte   0
penOR:          .byte   1
penXOR:         .byte   2
penBIC:         .byte   3
notpencopy:     .byte   4
notpenOR:       .byte   5
notpenXOR:      .byte   6
notpenBIC:      .byte   7

LD00B:  .byte   0

.proc hilitemenu_params
menu_id   := * + 0
.endproc
.proc menuselect_params
menu_id   := * + 0
menu_item := * + 1
.endproc
.proc menukey_params
menu_id   := * + 0
menu_item := * + 1
which_key := * + 2
key_mods  := * + 3
.endproc
        .res    4, 0



        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

;;; ============================================================
;;; Menu definition

        menu_id_apple := 1
        menu_id_file := 2
        menu_id_facilities := 3

menu_definition:
        DEFINE_MENU_BAR 3
        DEFINE_MENU_BAR_ITEM menu_id_apple, label_apple, menu_apple
        DEFINE_MENU_BAR_ITEM menu_id_file, label_file, menu_file
        DEFINE_MENU_BAR_ITEM menu_id_facilities, label_facilities, menu_facilities

menu_apple:
        DEFINE_MENU 5
        DEFINE_MENU_ITEM label_desktop
        DEFINE_MENU_ITEM label_blank
        DEFINE_MENU_ITEM label_copyright1
        DEFINE_MENU_ITEM label_copyright2
        DEFINE_MENU_ITEM label_rights

menu_file:
        DEFINE_MENU 1
        DEFINE_MENU_ITEM label_quit, 'Q', 'q'

label_apple:
        PASCAL_STRING GLYPH_SAPPLE

menu_facilities:
        DEFINE_MENU 2
        DEFINE_MENU_ITEM label_quick_copy
        DEFINE_MENU_ITEM label_disk_copy

label_file:
        PASCAL_STRING "File"
label_facilities:
        PASCAL_STRING "Facilities"

label_desktop:
        PASCAL_STRING "Apple II DeskTop version 1.1"
label_blank:
        PASCAL_STRING " "
label_copyright1:
        PASCAL_STRING "Copyright Apple Computer Inc., 1986 "
label_copyright2:
        PASCAL_STRING "Copyright Version Soft, 1985 - 1986 "
label_rights:
        PASCAL_STRING "All Rights reserved"

label_quit:
        PASCAL_STRING "Quit"

label_quick_copy:
        PASCAL_STRING "Quick Copy "

label_disk_copy:
        PASCAL_STRING "Disk Copy "

;;; ============================================================

disablemenu_params:
        .byte   3
LD129:  .byte   0

checkitem_params:
        .byte   3
LD12B:  .byte   0
LD12C:  .byte   0

event_params := *
        event_kind := event_params + 0
        ;;  if kind is key_down
        event_key := event_params + 1
        event_modifiers := event_params + 2
        ;;  if kind is no_event, button_down/up, drag, or apple_key:
        event_coords := event_params + 1
        event_xcoord := event_params + 1
        event_ycoord := event_params + 3
        ;;  if kind is update:
        event_window_id := event_params + 1

screentowindow_params := *
        screentowindow_window_id := screentowindow_params + 0
        screentowindow_screenx := screentowindow_params + 1
        screentowindow_screeny := screentowindow_params + 3
        screentowindow_windowx := screentowindow_params + 5
        screentowindow_windowy := screentowindow_params + 7

findwindow_params := * + 1    ; offset to x/y overlap event_params x/y
        findwindow_mousex := findwindow_params + 0
        findwindow_mousey := findwindow_params + 2
        findwindow_which_area := findwindow_params + 4
        findwindow_window_id := findwindow_params + 5


        .byte   0
        .byte   0
LD12F:  .byte   0
        .byte   0
        .byte   0
        .byte   0

LD133:  .byte   0

LD134:  .byte   0
        .byte   0
        .byte   0

grafport:  .res MGTK::grafport_size, 0

.proc getwinport_params
window_id:      .byte   0
port:           .addr   grafport_win
.endproc

grafport_win:  .res    MGTK::grafport_size, 0

        asl     $EA
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        dey
        .byte   0
        php
        .byte   0
        php



.proc winfo_dialog
window_id:      .byte   1
options:        .byte   MGTK::option_dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   150
mincontlength:  .word   50
maxcontwidth:   .word   500
maxcontlength:  .word   140
port:
viewloc:        DEFINE_POINT 25, 20
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, 500, 150
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc

.proc winfo_drive_select
window_id:      .byte   $02
options:        .byte   MGTK::option_dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_present
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   3
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   100
mincontlength:  .word   50
maxcontwidth:   .word   150
maxcontlength:  .word   150
port:
viewloc:        DEFINE_POINT 45, 50
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, 150, 70
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc

LD201:  .byte   $04
        .byte   0
        .byte   $02
        .byte   0
        beq     LD208
        .byte   $94
LD208:  .byte   0
        ora     L0000
        .byte   $03
        .byte   0
        .byte   $EF
        ora     ($93,x)
        .byte   0
        asl     L0000
        .byte   $14
        .byte   0
        inc     $6601
        .byte   0
        asl     L0000
        .byte   $67
        .byte   0
        inc     $9101
        .byte   0
        lsr     $5A01,x
        .byte   0
        .byte   $C2
        ora     ($65,x)
        .byte   0
        .byte   $D2
        .byte   0
        .byte   $5A
        .byte   0
        rol     $01,x
        adc     L0000
        .byte   $63
        ora     ($64,x)
        .byte   0

str_ok_label:
        PASCAL_STRING {"OK            ",CHAR_RETURN}

        .byte   $D7, 0
        .byte   $64
        .byte   0
LD249:  .byte   0
LD24A:  .byte   0
        .byte   $0F
        .byte   0
        .byte   $14
        .byte   0
        .byte   $1C
        .byte   0
        asl     $2E01
        .byte   0
        asl     $2601
        .byte   0
        ldy     $01
        .byte   $2E, 0, $D2
        .byte   0
        .byte   $44
        .byte   0
        .byte   $D2
        .byte   0
        .byte   $44
        .byte   0
        .byte   $D2
        .byte   0
        .byte   $44
        .byte   0

str_read_drive:
        PASCAL_STRING "Read Drive   D"
str_disk_copy_padded:
        PASCAL_STRING "     Disk Copy    "
str_quick_copy_padded:
        PASCAL_STRING "Quick Copy      "
str_slot_drive_name:
        PASCAL_STRING "Slot, Drive, Name"
str_select_source:
        PASCAL_STRING "Select source disk"
str_select_destination:
        PASCAL_STRING "Select destination disk"
str_formatting:
        PASCAL_STRING "Formatting the disk ...."
str_writing:
        PASCAL_STRING "Writing ....   "
str_reading:
        PASCAL_STRING "Reading ....    "
str_unknown:
        PASCAL_STRING "Unknown"
str_select_quit:
        PASCAL_STRING {"Select Quit from the file menu (",GLYPH_OAPPLE,"Q) to go back to the DeskTop"}
        .byte   0
        .byte   $7F
        .byte   0
        .byte   0
LD35D:  .byte   0
        .byte   0
        stx     L0000,y
LD361:  .byte   0
        .byte   0
LD363:  .byte   0
        .byte   0
        .byte   0
        .byte   0
LD367:  .byte   0
LD368:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD36D:  .byte   0
        .byte   0
LD36F:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $47
        .byte   0
LD375:  .byte   0
LD376:  .byte   0
LD377:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD3F7:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD3FF:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD407:  .byte   0
LD408:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD417:  .byte   0
LD418:  .byte   0

str_d:  PASCAL_STRING 0
str_s:  PASCAL_STRING 0
LD41D:  .byte   0
LD41E:  .byte   0
        .byte   0
        .byte   0
LD421:  .byte   0
LD422:  .byte   0
LD423:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LD429:  .byte   0
        .byte   $12
        .byte   0
        .byte   $14
        .byte   0
        nop
        ora     ($58,x)
        .byte   0
        .byte   $13
        .byte   0
        ora     $C300,x
        .byte   0
        adc     L0000
LD43A:  .res 18, 0
LD44C:  .byte   0
LD44D:  .byte   0
LD44E:  .byte   0
        .byte   0
        .byte   0
LD451:  .byte   0
        ora     (L0000,x)
str_2_spaces:   PASCAL_STRING "  "
str_7_spaces:   PASCAL_STRING "       "
        bit     $7D01
        .byte   0
        bit     $8701
        .byte   0
        bit     $7301
        .byte   0
        plp
        .byte   0
        adc     $6E00,x
        .byte   0
        adc     $2800,x
        .byte   0
        .byte   $87
        .byte   0
        ror     $8700
        .byte   0
        plp
        .byte   0
        .byte   $73
        .byte   0
        .byte   $14
        .byte   0
        sta     (L0000),y
        .byte   $14
        .byte   0
        dey
        .byte   0
        bcc     LD48A
        .byte   $91
LD48A:  .byte   0
        bit     $9101
        .byte   0
        plp
        .byte   0
        .byte   $64
        .byte   0
        plp
        .byte   0
        .byte   $5A
        .byte   0
LD497:  asl     a
LD498:  .byte   $e

str_blocks_read:
        PASCAL_STRING "Blocks Read: "
str_blocks_written:
        PASCAL_STRING "Blocks Written: "
str_blocks_to_transfer:
        PASCAL_STRING "Blocks to transfer: "
str_source:
        PASCAL_STRING "Source "
str_destination:
        PASCAL_STRING "Destination "
str_slot:
        PASCAL_STRING "Slot "
str_drive:
        PASCAL_STRING "  Drive "

str_dos33_s_d:
        PASCAL_STRING "DOS 3.3 S , D  "

str_dos33_disk_copy:
        PASCAL_STRING "DOS 3.3 disk copy"

str_pascal_disk_copy:
        PASCAL_STRING "Pascal disk copy"

str_prodos_disk_copy:
        PASCAL_STRING "ProDOS disk copy"

str_escape_stop_copy:
        PASCAL_STRING " ESC stop the copy"

str_error_writing:
        PASCAL_STRING "Error when writing block "

str_error_reading:
        PASCAL_STRING "Error when reading block "

        .byte   0, 0
        .byte   $02
        .byte   0
        asl     L0000
        asl     $1E00
        .byte   0
        rol     $7E00,x
        .byte   0
        .byte   $1A
        .byte   0
        bmi     LD58E
LD58E:  bmi     LD590
LD590:  rts

        .byte   0
        .byte   0
        .byte   0
        .byte   $03
        .byte   0
        .byte   $07
        .byte   0
        .byte   $0F
        .byte   0
        .byte   $1F
        .byte   0
        .byte   $3F
        .byte   0
        .byte   $7F
        .byte   0
        .byte   $7F
        ora     ($7F,x)
        .byte   0
        sei
        .byte   0
        sei
        .byte   0
        bvs     LD5AB
        .byte   $70
LD5AB:  ora     ($01,x)
        .byte   $01
LD5AE:  .byte   0
        .byte   0
        .byte   $7C
        .byte   $03
        .byte   $7C
        .byte   $03
        .byte   $02
        .byte   $04
        .byte   $42
        .byte   $04
        .byte   $32
        .byte   $0C
        .byte   $02
        .byte   $04
        .byte   $02
        .byte   $04
        .byte   $7C
        .byte   $03
        .byte   $7C
        .byte   $03
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $7C
        .byte   $03
        ror     $7E07,x
        .byte   $07
        .byte   $7F
        .byte   $0F
        .byte   $7F
        .byte   $0F
        .byte   $7F
        .byte   $1F
        .byte   $7F
        .byte   $0F
        .byte   $7F
        .byte   $0F
        ror     $7E07,x
        .byte   $07
        .byte   $7C
        .byte   $03
        .byte   0
        .byte   0
        ora     $05
LD5E0:  .byte   0
LD5E1:  jsr     LDF73
        MGTK_RELAY_CALL2 MGTK::SetMenu, menu_definition
        jsr     LDDE0
        copy16  #$0101, LD12B
        MGTK_RELAY_CALL2 MGTK::CheckItem, checkitem_params
        lda     #$01
        sta     LD129
        MGTK_RELAY_CALL2 MGTK::DisableMenu, disablemenu_params
        lda     #$00
        sta     LD451
        sta     LD5E0
        jsr     LDFA0
LD61C:  lda     #$00
        sta     LD367
        sta     LD368
        sta     LD44C
        lda     #$FF
        sta     LD363
        lda     #$81
        sta     LD44D
        lda     #$00
        sta     LD129
        MGTK_RELAY_CALL2 MGTK::DisableMenu, disablemenu_params
        lda     #$01
        sta     LD12C
        MGTK_RELAY_CALL2 MGTK::CheckItem, checkitem_params
        jsr     LDFDD
        MGTK_RELAY_CALL2 MGTK::OpenWindow, winfo_drive_select
        lda     #$00
        sta     LD429
        lda     #$FF
        sta     LD44C
        jsr     LE16C
        lda     LD5E0
        bne     LD66E
        jsr     LE3A3
LD66E:  jsr     LE28D
        inc     LD5E0
LD674:  jsr     LD986
        bmi     LD674
        beq     LD687
        MGTK_RELAY_CALL2 MGTK::CloseWindow, winfo_drive_select
        jmp     LD61C

LD687:  lda     LD363
        bmi     LD674
        lda     #$01
        sta     LD129
        MGTK_RELAY_CALL2 MGTK::DisableMenu, disablemenu_params
        lda     LD363
        sta     LD417
        lda     winfo_drive_select
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D1E3
        lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D255
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D251
        addr_call draw_text, str_select_destination
        jsr     LE559
        jsr     LE2B1
LD6E6:  jsr     LD986
        bmi     LD6E6
        beq     LD6F9
        MGTK_RELAY_CALL2 MGTK::CloseWindow, winfo_drive_select
        jmp     LD61C

LD6F9:  lda     LD363
        bmi     LD6E6
        tax
        lda     LD3FF,x
        sta     LD418
        lda     #$00
        sta     LD44C
        lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D211
        MGTK_RELAY_CALL2 MGTK::CloseWindow, winfo_drive_select
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D432
LD734:  addr_call LEB84, $0000
        beq     LD740
        jmp     LD61C

LD740:  lda     #$00
        sta     LD44D
        ldx     LD417
        lda     LD3F7,x
        sta     $0C42
        jsr     L1291
        beq     LD77E
        cmp     #$52
        bne     LD763
        jsr     L0D5F
        jsr     LE674
        jsr     LE559
        jmp     LD7AD

LD763:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D42A
        jmp     LD734

LD77E:  lda     $1300
        and     #$0F
        bne     LD798
        lda     $1301
        cmp     #$52
        bne     LD763
        jsr     L0D5F
        jsr     LE674
        jsr     LE559
        jmp     LD7AD

LD798:  lda     $1300
        and     #$0F
        sta     $1300
        addr_call LE0FE, $1300
        jsr     LE674
        jsr     LE559
LD7AD:  lda     LD417
        jsr     LE3B8
        jsr     LE5E1
        jsr     LE63F
        ldx     LD418
        lda     LD3F7,x
        tay
        ldx     #$00
        lda     #$01
        jsr     LEB84
        beq     LD7CC
        jmp     LD61C

LD7CC:  ldx     LD418
        lda     LD3F7,x
        sta     $0C42
        jsr     L1291
        beq     LD7E1
        cmp     #$52
        beq     LD7F2
        jmp     LD852

LD7E1:  lda     $1300
        and     #$0F
        bne     LD7F2
        lda     $1301
        cmp     #$52
        beq     LD7F2
        jmp     LD852

LD7F2:  ldx     LD418
        lda     LD3F7,x
        and     #$0F
        beq     LD817
        lda     LD3F7,x
        jsr     L0D26
        ldy     #$FF
        lda     ($06),y
        beq     LD817
        cmp     #$FF
        beq     LD817
        ldy     #$FE
        lda     ($06),y
        and     #$08
        bne     LD817
        jmp     LD8A9

LD817:  lda     $1300
        and     #$0F
        bne     LD82C
        ldx     LD418
        lda     LD3F7,x
        and     #$F0
        tax
        lda     #$07
        jmp     LD83C

LD82C:  sta     $1300
        addr_call LE0FE, $1300
        ldx     #$00
        ldy     #$13
        lda     #$02
LD83C:  jsr     LEB84
        cmp     #$01
        beq     LD847
        cmp     #$02
        beq     LD84A
LD847:  jmp     LD61C

LD84A:  lda     LD451
        bne     LD852
        jmp     LD8A9

LD852:  ldx     LD418
        lda     LD3F7,x
        and     #$0F
        beq     LD87C
        lda     LD3F7,x
        jsr     L0D26
        ldy     #$FE
        lda     ($06),y
        and     #$08
        bne     LD87C
        ldy     #$FF
        lda     ($06),y
        beq     LD87C
        cmp     #$FF
        beq     LD87C
        lda     #$03
        jsr     LEB84
        jmp     LD61C

LD87C:  MGTK_RELAY_CALL2 MGTK::MoveTo, $D25D
        addr_call draw_text, str_formatting
        jsr     L0CAF
        bcc     LD8A9
        cmp     #$2B
        beq     LD89F
        lda     #$04
        jsr     LEB84
        beq     LD852
        jmp     LD61C

LD89F:  lda     #$05
        jsr     LEB84
        beq     LD852
        jmp     LD61C

LD8A9:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D211
        lda     LD417
        cmp     LD418
        bne     LD8DF
        tax
        lda     LD3F7,x
        pha
        jsr     eject_disk
        pla
        tay
        ldx     #$80
        lda     #$00
        jsr     LEB84
        beq     LD8DF
        jmp     LD61C

LD8DF:  jsr     L0DB5
        lda     #$00
        sta     LD421
        sta     LD422
        lda     #$07
        sta     LD423
        jsr     LE4BF
        jsr     LE4EC
        jsr     LE507
        jsr     LE694
LD8FB:  jsr     LE4A8
        lda     #$00
        jsr     L0ED7
        cmp     #$01
        beq     LD97A
        jsr     LE4EC
        lda     LD417
        cmp     LD418
        bne     LD928
        tax
        lda     LD3F7,x
        pha
        jsr     eject_disk
        pla
        tay
        ldx     #$80
        lda     #$01
        jsr     LEB84
        beq     LD928
        jmp     LD61C

LD928:  jsr     LE491
        lda     #$80
        jsr     L0ED7
        bmi     LD955
        bne     LD97A
        jsr     LE507
        lda     LD417
        cmp     LD418
        bne     LD8FB
        tax
        lda     LD3F7,x
        pha
        jsr     eject_disk
        pla
        tay
        ldx     #$80
        lda     #$00
        jsr     LEB84
        beq     LD8FB
        jmp     LD61C

LD955:  jsr     LE507
        jsr     L10FB
        ldx     LD417
        lda     LD3F7,x
        jsr     eject_disk
        ldx     LD418
        cpx     LD417
        beq     LD972
        lda     LD3F7,x
        jsr     eject_disk
LD972:  lda     #$09
        jsr     LEB84
        jmp     LD61C

LD97A:  jsr     L10FB
        lda     #$0A
        jsr     LEB84
        jmp     LD61C

        .byte   0
LD986:  MGTK_RELAY_CALL2 MGTK::InitPort, grafport
        MGTK_RELAY_CALL2 MGTK::SetPort, grafport
LD998:  bit     LD368
        bpl     LD9A7
        dec     LD367
        bne     LD9A7
        lda     #$00
        sta     LD368
LD9A7:  MGTK_RELAY_CALL2 MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_down
        bne     LD9BA
        jmp     LDAB1

LD9BA:  cmp     #MGTK::event_kind_key_down
        bne     LD998
        jmp     LD9D5

LD9C1:  .addr   $0C83
        .addr   $0C83
        .addr   $0C83
        .addr   $0C83
        .addr   $0C83
        .addr   $0C84
        .addr   $DA3C
        .addr   $DA77

LD9D1:  .byte   0, $A, $C, $10

LD9D5:  lda     event_modifiers
        bne     LD9E6
        lda     event_key
        and     #$7F
        cmp     #CHAR_ESCAPE
        beq     LD9E6
        jmp     LDBFC

LD9E6:  lda     #$01
        sta     LD12F
        lda     event_key
        sta     menukey_params::which_key
        lda     event_modifiers
        sta     menukey_params::key_mods
        MGTK_RELAY_CALL2 MGTK::MenuKey, menukey_params
LDA00:  ldx     menukey_params::menu_id
        bne     LDA06
        rts

LDA06:  dex
        lda     LD9D1,x
        tax
        ldy     $D00D
        dey
        tya
        asl     a
        sta     jump_addr
        txa
        clc
        adc     jump_addr
        tax
        copy16  LD9C1,x, jump_addr
        jsr     LDA35
        MGTK_RELAY_CALL2 MGTK::HiliteMenu, hilitemenu_params
        jmp     LD986

LDA35:  tsx
        stx     LD00B
        jump_addr := *+1
        jmp     $1234
        lda     LD451
        bne     LDA42
        rts

LDA42:  lda     #$00
        sta     LD12C
        MGTK_RELAY_CALL2 MGTK::CheckItem, checkitem_params
        lda     LD451
        sta     LD12B
        lda     #$01
        sta     LD12C
        MGTK_RELAY_CALL2 MGTK::CheckItem, checkitem_params
        lda     #$00
        sta     LD451
        lda     winfo_dialog::window_id
        jsr     LE137
        addr_call LE0B4, str_quick_copy_padded
        rts

        lda     LD451
        beq     LDA7D
        rts

LDA7D:  lda     #$00
        sta     LD12C
        MGTK_RELAY_CALL2 MGTK::CheckItem, checkitem_params
        copy16  #$0102, LD12B
        MGTK_RELAY_CALL2 MGTK::CheckItem, checkitem_params
        lda     #$01
        sta     LD451
        lda     winfo_dialog::window_id
        jsr     LE137
        addr_call LE0B4, $D278
        rts

LDAB1:  MGTK_RELAY_CALL2 MGTK::FindWindow, event_xcoord
        lda     findwindow_which_area
        bne     LDAC0
        rts

LDAC0:  cmp     #$01
        bne     LDAD0
        MGTK_RELAY_CALL2 MGTK::MenuSelect, menuselect_params
        jmp     LDA00

LDAD0:  cmp     #$02
        bne     LDAD7
        jmp     LDADA

LDAD7:  return  #$FF

LDADA:  lda     LD133
        cmp     winfo_dialog::window_id
        bne     LDAE5
        jmp     LDAEE

LDAE5:  cmp     winfo_drive_select
        bne     LDAED
        jmp     LDB55

LDAED:  rts

LDAEE:  lda     winfo_dialog::window_id
        sta     screentowindow_window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL2 MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL2 MGTK::InRect, $D221
        cmp     #MGTK::inrect_inside
        beq     LDB19
        jmp     LDB2F

LDB19:  MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D221
        jsr     LDD38
        rts

LDB2F:  MGTK_RELAY_CALL2 MGTK::InRect, $D229
        cmp     #MGTK::inrect_inside
        bne     LDB52
        MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D229
        jsr     LDCAC
        rts

LDB52:  return  #$FF

LDB55:  lda     winfo_drive_select
        sta     screentowindow_window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL2 MGTK::MoveTo, screentowindow_windowx
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
        lda     screentowindow_windowy
        cmp     LD375
        bcc     LDB98
        lda     LD363
        jsr     LE14D
        lda     #$FF
        sta     LD363
        jmp     LDBCA

LDB98:  cmp     LD363
        bne     LDBCD
        bit     LD368
        bpl     LDBC0
        MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D221
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D221
        return  #$00

LDBC0:  lda     #$FF
        sta     LD368
        lda     #$64
        sta     LD367
LDBCA:  return  #$FF

LDBCD:  pha
        lda     LD363
        bmi     LDBD6
        jsr     LE14D
LDBD6:  pla
        sta     LD363
        jsr     LE14D
        jmp     LDBC0

.proc MGTK_RELAY2
        sty     LDBF2
        stax    LDBF3
        sta     RAMRDON
        sta     RAMWRTON
        jsr     MGTK::MLI
LDBF2:  .byte   0
LDBF3:  .addr   0
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

LDBFC:  lda     event_key
        and     #$7F
        cmp     #'D'
        beq     LDC09
        cmp     #'d'
        bne     LDC2D
LDC09:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D229
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D229
        return  #$01

LDC2D:  cmp     #CHAR_RETURN
        bne     LDC55
        lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D221
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D221
        return  #$00

LDC55:  bit     LD44C
        bmi     LDC5D
        jmp     LDCA9

LDC5D:  cmp     #CHAR_DOWN
        bne     LDC85
        lda     winfo_drive_select
        jsr     LE137
        lda     LD363
        bmi     LDC6F
        jsr     LE14D
LDC6F:  inc     LD363
        lda     LD363
        cmp     LD375
        bcc     LDC7F
        lda     #$00
        sta     LD363
LDC7F:  jsr     LE14D
        jmp     LDCA9

LDC85:  cmp     #CHAR_UP
        bne     LDCA9
        lda     winfo_drive_select
        jsr     LE137
        lda     LD363
        bmi     LDC9C
        jsr     LE14D
        dec     LD363
        bpl     LDCA3
LDC9C:  ldx     LD375
        dex
        stx     LD363
LDCA3:  lda     LD363
        jsr     LE14D
LDCA9:  return  #$FF

LDCAC:  lda     #$00
        sta     LDD37
LDCB1:  MGTK_RELAY_CALL2 MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_up
        beq     LDD14
        lda     winfo_dialog::window_id
        sta     screentowindow_window_id
        MGTK_RELAY_CALL2 MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL2 MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL2 MGTK::InRect, $D229
        cmp     #MGTK::inrect_inside
        beq     LDCEE
        lda     LDD37
        beq     LDCF6
        jmp     LDCB1

LDCEE:  lda     LDD37
        bne     LDCF6
        jmp     LDCB1

LDCF6:  MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D229
        lda     LDD37
        clc
        adc     #$80
        sta     LDD37
        jmp     LDCB1

LDD14:  lda     LDD37
        beq     LDD1C
        return  #$FF

LDD1C:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D229
        return  #$01

LDD37:  .byte   0
LDD38:  lda     #$00
        sta     LDDC3
LDD3D:  MGTK_RELAY_CALL2 MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_up
        beq     LDDA0
        lda     winfo_dialog::window_id
        sta     screentowindow_window_id
        MGTK_RELAY_CALL2 MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL2 MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL2 MGTK::InRect, $D221
        cmp     #MGTK::inrect_inside
        beq     LDD7A
        lda     LDDC3
        beq     LDD82
        jmp     LDD3D

LDD7A:  lda     LDDC3
        bne     LDD82
        jmp     LDD3D

LDD82:  MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D221
        lda     LDDC3
        clc
        adc     #$80
        sta     LDDC3
        jmp     LDD3D

LDDA0:  lda     LDDC3
        beq     LDDA8
        return  #$FF

LDDA8:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D221
        return  #$00

LDDC3:  .byte   0
        MGTK_RELAY_CALL2 MGTK::HideCursor
        MGTK_RELAY_CALL2 MGTK::SetCursor, LD5AE
        MGTK_RELAY_CALL2 MGTK::ShowCursor
        rts

LDDE0:  MGTK_RELAY_CALL2 MGTK::HideCursor
        MGTK_RELAY_CALL2 MGTK::SetCursor, $D57C
        MGTK_RELAY_CALL2 MGTK::ShowCursor
        rts

LDDFC:  sta     $0C5A
        lda     #$00
        sta     $0C5D
        sta     $0C5E
        copy16  #$1C00, $0C5B
        jsr     L12AF
        beq     LDE19
        return  #$FF

LDE19:  lda     $1C01
        cmp     #$E0
        beq     LDE23
        jmp     LDE4D

LDE23:  lda     $1C02
        cmp     #$70
        beq     LDE31
        cmp     #$60
        beq     LDE31
LDE2E:  return  #$FF

LDE31:  lda     LD375
        asl     a
        asl     a
        asl     a
        asl     a
        clc
        adc     #$77
        tay
        lda     #$D3
        adc     #$00
        tax
        tya
        jsr     LDE9F
        lda     #$80
        sta     LD44E
        return  #$00

LDE4D:  cmp     #$A5
        bne     LDE2E
        lda     $1C02
        cmp     #$27
        bne     LDE2E
        lda     $0C5A
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #$30
        ldx     LD497
        sta     str_dos33_s_d,x
        lda     $0C5A
        and     #$80
        asl     a
        rol     a
        adc     #$31
        ldx     LD498
        sta     str_dos33_s_d,x
        lda     LD375
        asl     a
        asl     a
        asl     a
        asl     a
        tay
        ldx     #$00
LDE83:  lda     str_dos33_s_d,x
        sta     LD377,y
        iny
        inx
        cpx     str_dos33_s_d
        bne     LDE83
        lda     str_dos33_s_d,x
        sta     LD377,y
        lda     #$43
        sta     $0300
        return  #$00

        .byte   0
LDE9F:  stax    $06
        copy16  #$0002, $0C5D
        jsr     L12AF
        beq     LDEBE
        ldy     #$00
        lda     #$01
        sta     ($06),y
        iny
        lda     #$20
        sta     ($06),y
        rts

LDEBE:  ldy     #$00
        ldx     #$00
LDEC2:  lda     $1C06,x
        sta     ($06),y
        inx
        iny
        cpx     $1C06
        bne     LDEC2
        lda     $1C06,x
        sta     ($06),y
        lda     $1C06
        cmp     #$0F
        bcs     LDEE6
        ldy     #$00
        lda     ($06),y
        clc
        adc     #$01
        sta     ($06),y
        lda     ($06),y
        tay
LDEE6:  lda     #$3A
        sta     ($06),y
        rts

LDEEB:  stax    LDF6F
        ldx     #$07
        lda     #$20
LDEF5:  sta     str_7_spaces,x
        dex
        bne     LDEF5
        lda     #$00
        sta     LDF72
        ldy     #$00
        ldx     #$00
LDF04:  lda     #$00
        sta     LDF71
LDF09:  lda     LDF6F
        cmp     LDF67,x
        lda     LDF70
        sbc     LDF68,x
        bpl     LDF45
        lda     LDF71
        bne     LDF25
        bit     LDF72
        bmi     LDF25
        lda     #$20
        bne     LDF38
LDF25:  cmp     #$0A
        bcc     LDF2F
        clc
        adc     #$37
        jmp     LDF31

LDF2F:  adc     #$30
LDF31:  pha
        lda     #$80
        sta     LDF72
        pla
LDF38:  sta     str_7_spaces+2,y
        iny
        inx
        inx
        cpx     #$08
        beq     LDF5E
        jmp     LDF04

LDF45:  inc     LDF71
        lda     LDF6F
        sec
        sbc     LDF67,x
        sta     LDF6F
        lda     LDF70
        sbc     LDF68,x
        sta     LDF70
        jmp     LDF09

LDF5E:  lda     LDF6F
        ora     #$30
        sta     str_7_spaces+2,y
        rts

LDF67:  .byte   $10
LDF68:  .byte   $27
        inx
        .byte   $03
        .byte   $64
        .byte   0
        asl     a
        .byte   0
LDF6F:  .byte   0
LDF70:  .byte   0
LDF71:  .byte   0
LDF72:  .byte   0
LDF73:  ldx     $BF31
LDF76:  lda     $BF32,x
        cmp     #$BF
        beq     LDF81
        dex
        bpl     LDF76
        rts

LDF81:  lda     $BF33,x
        sta     $BF32,x
        cpx     $BF31
        beq     LDF90
        inx
        jmp     LDF81

LDF90:  dec     $BF31
        rts

        inc     $BF31
        ldx     $BF31
        lda     #$BF
        sta     $BF32,x
        rts

LDFA0:  MGTK_RELAY_CALL2 MGTK::OpenWindow, winfo_dialog
        lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::FrameRect, $D201
        MGTK_RELAY_CALL2 MGTK::FrameRect, $D209

        MGTK_RELAY_CALL2 MGTK::InitPort, grafport
        MGTK_RELAY_CALL2 MGTK::SetPort, grafport
        rts

LDFDD:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D211
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D219
        lda     LD451
        bne     LE00D
        addr_call LE0B4, str_quick_copy_padded
        jmp     LE014

LE00D:  addr_call LE0B4, $D278
LE014:  MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::FrameRect, $D221
        MGTK_RELAY_CALL2 MGTK::FrameRect, $D229
        jsr     LE078
        jsr     LE089
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D24D
        addr_call draw_text, str_slot_drive_name
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D251
        addr_call draw_text, str_select_source
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D47F
        addr_call draw_text, str_select_quit

        MGTK_RELAY_CALL2 MGTK::InitPort, grafport
        MGTK_RELAY_CALL2 MGTK::SetPort, grafport
        rts

LE078:  MGTK_RELAY_CALL2 MGTK::MoveTo, $D231
        addr_call draw_text, str_ok_label
        rts

LE089:  MGTK_RELAY_CALL2 MGTK::MoveTo, $D245
        addr_call draw_text, str_read_drive
        rts

.proc draw_text
        ptr := $0A

        stax    ptr
        ldy     #$00
        lda     (ptr),y
        sta     ptr+2
        inc16   ptr
        MGTK_RELAY_CALL2 MGTK::DrawText, ptr
        rts
.endproc

LE0B4:  stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
        MGTK_RELAY_CALL2 MGTK::TextWidth, $06
        lsr16   $09
        lda     #$01
        sta     LE0FD
        lda     #$F4
        lsr     LE0FD
        ror     a
        sec
        sbc     $09
        sta     LD249
        lda     LE0FD
        sbc     $0A
        sta     LD24A
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D249
        MGTK_RELAY_CALL2 MGTK::DrawText, $06
        rts

LE0FD:  .byte   0
LE0FE:  stx     $0B
        sta     $0A
        ldy     #$00
        lda     ($0A),y
        tay
        bne     LE10A
        rts

LE10A:  dey
        beq     LE10F
        bpl     LE110
LE10F:  rts

LE110:  lda     ($0A),y
        and     #$7F
        cmp     #'/'
        beq     LE11C
        cmp     #'.'
        bne     LE120
LE11C:  dey
        jmp     LE10A

LE120:  iny
        lda     ($0A),y
        and     #$7F
        cmp     #'A'
        bcc     LE132
        cmp     #'Z'+1
        bcs     LE132
        clc
        adc     #('a' - 'A')
        sta     ($0A),y
LE132:  dey
        jmp     LE10A

        .byte   0
LE137:  sta     getwinport_params::window_id
        MGTK_RELAY_CALL2 MGTK::GetWinPort, getwinport_params
        MGTK_RELAY_CALL2 MGTK::SetPort, grafport_win
        rts

LE14D:  asl     a
        asl     a
        asl     a
        sta     LD35D
        clc
        adc     #$07
        sta     LD361
        MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D35B
        rts

LE16C:  lda     #$00
        sta     LD44E
        sta     $0C42
        jsr     L1291
        beq     LE17A
        .byte   0
LE17A:  lda     #$00
        sta     LE263
        sta     LD375
LE182:  lda     #$13
        sta     $07
        lda     #$00
        sta     $06
        sta     LE264
        lda     LE263
        asl     a
        rol     LE264
        asl     a
        rol     LE264
        asl     a
        rol     LE264
        asl     a
        rol     LE264
        clc
        adc     $06
        sta     $06
        lda     LE264
        adc     $07
        sta     $07
        ldy     #$00
        lda     ($06),y
        and     #$0F
        bne     LE20D
        lda     ($06),y
        beq     LE1CC
        iny
        lda     ($06),y
        cmp     #$28
        bne     LE1CD
        dey
        lda     ($06),y
        jsr     LE265
        lda     #$28
        bcc     LE1CD
        jmp     LE255

LE1CC:  rts

LE1CD:  pha
        ldy     #$00
        lda     ($06),y
        jsr     LE285
        ldx     LD375
        sta     LD3F7,x
        pla
        cmp     #$52
        bne     LE1EA
        lda     LD3F7,x
        and     #$F0
        jsr     LDDFC
        beq     LE207
LE1EA:  lda     LD375
        asl     a
        asl     a
        asl     a
        asl     a
        tay
        ldx     #$00
LE1F4:  lda     str_unknown,x
        sta     LD377,y
        iny
        inx
        cpx     str_unknown
        bne     LE1F4
        lda     str_unknown,x
        sta     LD377,y
LE207:  inc     LD375
        jmp     LE255

LE20D:  ldx     LD375
        ldy     #$00
        lda     ($06),y
        and     #$70
        cmp     #$30
        bne     LE21D
        jmp     LE255

LE21D:  ldy     #$00
        lda     ($06),y
        jsr     LE285
        ldx     LD375
        sta     LD3F7,x
        lda     LD375
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        ldy     #$00
        lda     ($06),y
        and     #$0F
        sta     LD377,x
        sta     LE264
LE23E:  inx
        iny
        cpy     LE264
        beq     LE24D
        lda     ($06),y
        sta     LD377,x
        jmp     LE23E

LE24D:  lda     ($06),y
        sta     LD377,x
        inc     LD375
LE255:  inc     LE263
        lda     LE263
        cmp     #$08
        beq     LE262
        jmp     LE182

LE262:  rts

LE263:  .byte   0
LE264:  .byte   0
LE265:  and     #$F0
        sta     LE28C
        ldx     $BF31
LE26D:  lda     $BF32,x
        and     #$F0
        cmp     LE28C
        beq     LE27C
        dex
        bpl     LE26D
LE27A:  sec
        rts

LE27C:  lda     $BF32,x
        and     #$0F
        bne     LE27A
        clc
        rts

LE285:  jsr     LE265
        lda     $BF32,x
        rts

LE28C:  .byte   0
LE28D:  lda     winfo_drive_select
        jsr     LE137
        lda     #$00
        sta     LE2B0
LE298:  lda     LE2B0
        jsr     LE39A
        lda     LE2B0
        jsr     LE31B
        inc     LE2B0
        lda     LE2B0
        cmp     LD375
        bne     LE298
        rts

LE2B0:  .byte   0
LE2B1:  lda     winfo_drive_select
        jsr     LE137
        lda     LD363
        asl     a
        tax
        lda     LD407,x
        sta     LE318
        lda     LD408,x
        sta     LE319
        lda     LD375
        sta     LD376
        lda     #$00
        sta     LD375
        sta     LE317
LE2D6:  lda     LE317
        asl     a
        tax
        lda     LD407,x
        cmp     LE318
        bne     LE303
        lda     LD408,x
        cmp     LE319
        bne     LE303
        lda     LE317
        ldx     LD375
        sta     LD3FF,x
        lda     LD375
        jsr     LE39A
        lda     LE317
        jsr     LE31B
        inc     LD375
LE303:  inc     LE317
        lda     LE317
        cmp     LD376
        beq     LE311
        jmp     LE2D6

LE311:  lda     #$FF
        sta     LD363
        rts

LE317:  .byte   0
LE318:  .byte   0
LE319:  .byte   0
        .byte   0
LE31B:  sta     LE399
        lda     #$08
        sta     LD36D
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D36D
        ldx     LE399
        lda     LD3F7,x
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #'0'
        sta     str_s + 1
        addr_call draw_text, str_s
        lda     #$28
        sta     LD36D
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D36D
        ldx     LE399
        lda     LD3F7,x
        and     #$80
        asl     a
        rol     a
        clc
        adc     #'1'
        sta     str_d + 1
        addr_call draw_text, str_d
        lda     #$41
        sta     LD36D
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D36D
        lda     LE399
        asl     a
        asl     a
        asl     a
        asl     a
        clc
        adc     #$77
        sta     $06
        lda     #$D3
        adc     #$00
        sta     $07
        lda     $06
        ldx     $07
        jsr     LE0FE
        lda     $06
        ldx     $07
        jsr     draw_text
        rts

LE399:  .byte   0
LE39A:  asl     a
        asl     a
        asl     a
        adc     #$08
        sta     LD36F
        rts

LE3A3:  lda     #$00
        sta     LE3B7
LE3A8:  jsr     LE3B8
        inc     LE3B7
        lda     LE3B7
        cmp     LD375
        bne     LE3A8
        rts

LE3B7:  .byte   0
LE3B8:  pha
        tax
        lda     LD3F7,x
        and     #$0F
        beq     LE3CC
        lda     LD3F7,x
        and     #$F0
        jsr     L0D26
        jmp     LE3DA

LE3CC:  pla
        asl     a
        tax
        lda     #$18
        sta     LD407,x
        lda     #$01
        sta     LD408,x
        rts

LE3DA:  ldy     #$07
        lda     ($06),y
        bne     LE3E3
        jmp     LE44A

LE3E3:  lda     #$00
        sta     LE448
        ldy     #$FC
        lda     ($06),y
        sta     LE449
        beq     LE3F6
        lda     #$80
        sta     LE448
LE3F6:  ldy     #$FD
        lda     ($06),y
        tax
        bne     LE402
        bit     LE448
        bpl     LE415
LE402:  stx     LE448
        pla
        asl     a
        tax
        lda     LE448
        sta     LD407,x
        lda     LE449
        sta     LD408,x
        rts

LE415:  ldy     #$FF
        lda     ($06),y
        sta     $06
        lda     #$00
        sta     $42
        sta     $44
        sta     $45
        sta     $46
        sta     $47
        pla
        pha
        tax
        lda     LD3F7,x
        and     #$F0
        sta     $43
        jsr     LE445
        stx     LE448
        pla
        asl     a
        tax
        lda     LE448
        sta     LD407,x
        tya
        sta     LD408,x
        rts

LE445:  jmp     ($06)

LE448:  .byte   0
LE449:  .byte   0
LE44A:  ldy     #$FF
        lda     ($06),y
        clc
        adc     #$03
        sta     $06
        pla
        pha
        tax
        lda     LD3F7,x
        and     #$F0
        jsr     L0D51
        sta     LE47D
        jsr     LE477
        .byte   0
        .byte   $7C
        cpx     $68
        asl     a
        tax
        lda     LE482
        sta     LD407,x
        lda     LE483
        sta     LD408,x
        rts

LE477:  jmp     ($06)

        .byte   0
        .byte   0
        .byte   $03
LE47D:  ora     ($81,x)
        cpx     L0000
        .byte   0
LE482:  .byte   0
LE483:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
LE491:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D261
        addr_call draw_text, str_writing
        rts

LE4A8:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D265
        addr_call draw_text, str_reading
        rts

LE4BF:  lda     winfo_dialog::window_id
        jsr     LE137
        lda     LD417
        asl     a
        tay
        lda     LD408,y
        tax
        lda     LD407,y
        jsr     LDEEB
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D467
        addr_call draw_text, str_blocks_to_transfer
        addr_call draw_text, str_7_spaces
        rts

LE4EC:  jsr     LE522
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D45F
        addr_call draw_text, str_blocks_read
        .byte   $A9
LE500:  .byte   $57
        ldx     #$D4
        jsr     draw_text
        rts

LE507:  jsr     LE522
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D463
        addr_call draw_text, str_blocks_written
        addr_call draw_text, str_7_spaces
        rts

LE522:  lda     winfo_dialog::window_id
        jsr     LE137
        lda     LD422
        sta     LE558
        lda     LD421
        asl     a
        rol     LE558
        asl     a
        rol     LE558
        asl     a
        rol     LE558
        ldx     LD423
        clc
        adc     LE550,x
        tay
        lda     LE558
        adc     #$00
        tax
        tya
        jsr     LDEEB
        rts

LE550:  .byte   $07
        asl     $05
        .byte   $04
        .byte   $03
        .byte   $02
        ora     (L0000,x)
LE558:  .byte   0
LE559:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D46B
        addr_call draw_text, str_source
        ldx     LD417
        lda     LD3F7,x
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #'0'
        sta     str_s + 1
        ldx     LD417
        lda     LD3F7,x
        and     #$80
        clc
        rol     a
        rol     a
        clc
        adc     #'1'
        sta     str_d + 1
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D46F
        addr_call draw_text, str_slot
        addr_call draw_text, str_s
        addr_call draw_text, str_drive
        addr_call draw_text, str_d
        bit     LD44D
        bpl     LE5C6
        bvc     LE5C5
        lda     LD44D
        and     #$0F
        beq     LE5C6
LE5C5:  rts

LE5C6:  addr_call draw_text, str_2_spaces
        ldx     $1300
LE5D0:  lda     $1300,x
        sta     LD43A,x
        dex
        bpl     LE5D0
        addr_call draw_text, LD43A
        rts

LE5E1:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D473
        addr_call draw_text, str_destination
        ldx     LD418
        lda     LD3F7,x
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #'0'
        sta     str_s + 1
        ldx     LD418
        lda     LD3F7,x
        and     #$80
        asl     a
        rol     a
        clc
        adc     #'1'
        sta     str_d + 1
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D477
        addr_call draw_text, str_slot
        addr_call draw_text, str_s
        addr_call draw_text, str_drive
        addr_call draw_text, str_d
        rts

LE63F:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D47B
        bit     LD44D
        bmi     LE65B
        addr_call draw_text, str_prodos_disk_copy
        rts

LE65B:  bvs     LE665
        addr_call draw_text, str_dos33_disk_copy
        rts

LE665:  lda     LD44D
        and     #$0F
        bne     LE673
        addr_call draw_text, str_pascal_disk_copy
LE673:  rts

LE674:  lda     LD44D
        cmp     #$C0
        beq     LE693
        lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL2 MGTK::PaintRect, $D483
LE693:  rts

LE694:  lda     winfo_dialog::window_id
        jsr     LE137
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D48B
        addr_call draw_text, str_escape_stop_copy
        rts

        lda     winfo_dialog::window_id
        jsr     LE137
        copy16  #$800A, LE6FB
LE6BB:  dec     LE6FB
        beq     LE6F1
        lda     LE6FC
        eor     #$80
        sta     LE6FC
        beq     LE6D5
        MGTK_RELAY_CALL2 MGTK::SetTextBG, $D35A
        beq     LE6DE
LE6D5:  MGTK_RELAY_CALL2 MGTK::SetTextBG, $D359
LE6DE:  MGTK_RELAY_CALL2 MGTK::MoveTo, $D48B
        addr_call draw_text, str_escape_stop_copy
        jmp     LE6BB

LE6F1:  MGTK_RELAY_CALL2 MGTK::SetTextBG, $D35A
        rts

LE6FB:  .byte   0
LE6FC:  .byte   0
LE6FD:  stx     LE765
        cmp     #$2B
        bne     LE71A
        jsr     L127E
        lda     #$05
        jsr     LEB84
        bne     LE714
        jsr     LE491
        return  #$01

LE714:  jsr     L10FB
        return  #$80

LE71A:  jsr     L127E
        lda     winfo_dialog::window_id
        jsr     LE137
        lda     $0C5D
        ldx     $0C5E
        jsr     LDEEB
        lda     LE765
        bne     LE74B
        MGTK_RELAY_CALL2 MGTK::MoveTo, $D493
        addr_call draw_text, str_error_reading
        addr_call draw_text, str_7_spaces
        return  #$00

LE74B:  MGTK_RELAY_CALL2 MGTK::MoveTo, $D48F
        addr_call draw_text, str_error_writing
        addr_call draw_text, str_7_spaces
        return  #$00

LE765:  .byte   0
        sta     $06
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        copy16  #$1C00, $0C5B
LE77A:  jsr     L12AF
        beq     LE789
        ldx     #$00
        jsr     LE6FD
        beq     LE789
        bpl     LE77A
        rts

LE789:  sta     RAMRDOFF
        sta     RAMWRTON
        ldy     #$FF
        iny
LE792:  lda     $1C00,y
        sta     ($06),y
        lda     $1D00,y
        sta     ($08),y
        iny
        bne     LE792
        sta     RAMRDOFF
        sta     RAMWRTOFF
        lda     #$00
        rts

        sta     $06
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        copy16  #$1C00, $0C5B
        .byte   $8D
        .byte   $03
        cpy     #$8D
        .byte   $04
        cpy     #$A0
        .byte   $FF
        iny
LE7C5:  lda     ($06),y
        sta     $1C00,y
        lda     ($08),y
        sta     $1D00,y
        iny
        bne     LE7C5
        sta     RAMRDOFF
        sta     RAMWRTOFF
LE7D8:  jsr     L12A5
        beq     LE7E6
        ldx     #$80
        jsr     LE6FD
        beq     LE7E6
        bpl     LE7D8
LE7E6:  rts

        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$1F,x
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        asl     $401F,x
        .byte   $07
        beq     LE810
LE810:  .byte   0
        asl     $601F,x
        .byte   $03
        rts

        .byte   0
        .byte   0
        inc     LF01F,x
        .byte   $F3
        .byte   $4F
        .byte   0
        .byte   0
        inc     $F81F,x
        .byte   $F3
        .byte   $4F
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        .byte   $4F
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        .byte   $67
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        .byte   $F3
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $FF
        sbc     L0000,y
        inc     $FC1F,x
        .byte   $FF
        .byte   $FC
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $3F
        inc     a:L0000,x
        inc     $FC1F,x
        .byte   $1F
        .byte   $FF
        .byte   0
        .byte   0
        inc     $FC1F,x
        .byte   $1F
        .byte   $FF
        .byte   0
        .byte   0
        rol     $FE00,x
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        inc     $FF03,x
        .byte   $1F
        .byte   $FF
        .byte   0
        .byte   0
        inc     $FF43,x
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        asl     $FF60
        .byte   $FF
        .byte   $3F
        .byte   0
        .byte   0
        inc     a:$03,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$03,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $14
        .byte   0
        php
        .byte   0
        .byte   $E7
        .byte   $E7
        .byte   $07
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        bit     L0000
        .byte   $17
        .byte   0
        eor     (L0000,x)
        and     LE500
        ora     ($64,x)
        .byte   0
        .byte   $04
        .byte   0
        .byte   $02
        .byte   0
        ldy     #$01
        and     L0000,x
        ora     L0000
        .byte   $03
        .byte   0
        .byte   $9F
        ora     ($34,x)
        .byte   0


.proc portbits1
viewloc:        DEFINE_POINT 65, 45, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, 420, 55
.endproc

.proc portbits2
viewloc:        DEFINE_POINT 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, $22F, $BF
.endproc

str_ok_btn:
        PASCAL_STRING {"OK            ",GLYPH_RETURN}

str_cancel_btn:
        PASCAL_STRING "Cancel     Esc"

str_try_again_btn:
        PASCAL_STRING "Try Again     A"

str_yes_btn:
        PASCAL_STRING "Yes"

str_no_btn:
        PASCAL_STRING "No"

yes_rect:  DEFINE_RECT 250, 37, 300, 48
yes_pos:  DEFINE_POINT 255, 47

no_rect:  DEFINE_RECT 350, 37, 400, 48
no_pos:  DEFINE_POINT 355, 47

ok_try_again_rect:  DEFINE_RECT 300, 37, 400, 48
ok_try_again_pos:  DEFINE_POINT 305, 47

cancel_rect:  DEFINE_RECT 20, 37, 120, 48
cancel_pos:  DEFINE_POINT 25, 47

LE93D:  DEFINE_POINT 100, 24

LE941:  .byte   0
LE942:  .byte   0
LE943:  .byte   0

        PASCAL_STRING "Insert source disk and click OK."
        PASCAL_STRING "Insert destination disk and click OK."
LE98B:  PASCAL_STRING "Do you want to erase "
LE9A0 := *-1
        .res    18, 0
        PASCAL_STRING "The destination disk cannot be formated !"
        PASCAL_STRING "Error during formating."
        PASCAL_STRING "The destination volume is write protected !"
        PASCAL_STRING "Do you want to erase "
        .res    18, 0
LEA49:  PASCAL_STRING "Do you want to  erase  the disk in slot   drive   ?"
LEA7D:  PASCAL_STRING "Do you want to erase the disk in slot   drive   ?"
        PASCAL_STRING "The copy was successful."
        PASCAL_STRING "The copy was not completed."
        PASCAL_STRING "Insert source disk or press Escape to cancel."
        PASCAL_STRING "Insert destination disk or press Escape to cancel."
LEB45:  .byte   $20
LEB46:  .byte   $3F
LEB47:  .byte   $29
LEB48:  .byte   $31
LEB49:  .byte   $27
LEB4A:  .byte   $2F
LEB4B:  .byte   $17
LEB4C:  .byte   $15
LEB4D:  .byte   0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
LEB5A:  .byte   $44
LEB5B:  sbc     #$65
        sbc     #$8B
        sbc     #$B3
        sbc     #$DD
        sbc     #$F5
        sbc     #$21
        nop
        eor     #$EA
        adc     $AFEA,x
        nop
        iny
        nop
        cpx     $EA
        .byte   $12
        .byte   $EB
LEB74:  cpy     #$C0
        sta     (L0000,x)
        .byte   $80
        .byte   $80
        sta     ($81,x)
        sta     (L0000,x)
        .byte   0
        .byte   0
        .byte   0
LEB81:  .byte   0
LEB82:  .byte   0
LEB83:  .byte   0
LEB84:  stax    LEB81
        sty     LEB83
        MGTK_RELAY_CALL2 MGTK::InitPort, grafport
        MGTK_RELAY_CALL2 MGTK::SetPort, grafport
        MGTK_RELAY_CALL2 MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL2 MGTK::PaintRect, $E89F
        jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::FrameRect, $E89F
        MGTK_RELAY_CALL2 MGTK::SetPortBits, portbits1
        MGTK_RELAY_CALL2 MGTK::FrameRect, $E8A7
        MGTK_RELAY_CALL2 MGTK::FrameRect, $E8AF
        MGTK_RELAY_CALL2 MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL2 MGTK::HideCursor
        MGTK_RELAY_CALL2 MGTK::PaintBits, $E88F
        MGTK_RELAY_CALL2 MGTK::ShowCursor
        lda     #$00
        sta     LD41E
        lda     LEB81
        jsr     LF1CC
        ldy     LEB83
        ldx     LEB82
        lda     LEB81
        bne     LEC1F
        cpx     #$00
        beq     LEC5E
        jsr     LF185
        beq     LEC5E
        lda     #$0B
        bne     LEC5E
LEC1F:  cmp     #$01
        bne     LEC34
        cpx     #$00
        beq     LEC5E
        jsr     LF185
        beq     LEC30
        lda     #$0C
        bne     LEC5E
LEC30:  lda     #$01
        bne     LEC5E
LEC34:  cmp     #$02
        bne     LEC3F
        jsr     LF0E9
        lda     #$02
        bne     LEC5E
LEC3F:  cmp     #$06
        bne     :+
        jsr     LF119
        lda     #$06
        bne     LEC5E
:       cmp     #$07
        bne     LEC55
        jsr     LF149
        lda     #$07
        bne     LEC5E
LEC55:  cmp     #$08
        bne     LEC5E
        jsr     LF167
        lda     #$08
LEC5E:  ldy     #$00
LEC60:  cmp     LEB4D,y
        beq     LEC6C
        iny
        cpy     #$1E
        bne     LEC60
        ldy     #$00
LEC6C:  tya
        asl     a
        tay
        lda     LEB5A,y
        sta     LE942
        lda     LEB5B,y
        sta     LE943
        tya
        lsr     a
        tay
        lda     LEB74,y
        sta     LE941
        bit     LD41E
        bpl     LEC8C
        jmp     LED23

LEC8C:  jsr     LF0DF
        bit     LE941
        bpl     draw_ok_btn
        MGTK_RELAY_CALL2 MGTK::FrameRect, cancel_rect
        MGTK_RELAY_CALL2 MGTK::MoveTo, cancel_pos
        addr_call draw_text, str_cancel_btn
        bit     LE941
        bvs     draw_ok_btn
        lda     LE941
        and     #$0F
        beq     draw_try_again_btn

        MGTK_RELAY_CALL2 MGTK::FrameRect, yes_rect
        MGTK_RELAY_CALL2 MGTK::MoveTo, yes_pos
        addr_call draw_text, str_yes_btn

        MGTK_RELAY_CALL2 MGTK::FrameRect, no_rect
        MGTK_RELAY_CALL2 MGTK::MoveTo, no_pos
        addr_call draw_text, str_no_btn
        jmp     LED23

draw_try_again_btn:
        MGTK_RELAY_CALL2 MGTK::FrameRect, ok_try_again_rect
        MGTK_RELAY_CALL2 MGTK::MoveTo, ok_try_again_pos
        addr_call draw_text, str_try_again_btn
        jmp     LED23

draw_ok_btn:
        MGTK_RELAY_CALL2 MGTK::FrameRect, ok_try_again_rect
        MGTK_RELAY_CALL2 MGTK::MoveTo, ok_try_again_pos
        addr_call draw_text, str_ok_btn

LED23:  MGTK_RELAY_CALL2 MGTK::MoveTo, LE93D
        addr_call_indirect draw_text, LE942
LED35:  bit     LD41E
        bpl     $ED45
        jsr     LF192
        bne     LED42
        jmp     LEDF2

LED42:  jmp     LED79

        MGTK_RELAY_CALL2 MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_down
        bne     LED58
        jmp     LEDFA

LED58:  cmp     #MGTK::event_kind_key_down
        bne     LED35
        lda     event_key
        and     #$7F
        bit     LE941
        bmi     LED69
        jmp     LEDE2

LED69:  cmp     #CHAR_ESCAPE
        bne     LED7E
        jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, cancel_rect
LED79:  lda     #$01
        jmp     LEE6A

LED7E:  bit     LE941
        bvs     LEDE2
        pha
        lda     LE941
        and     #$0F
        beq     LEDC1
        pla
        cmp     #'N'
        beq     LED9F
        cmp     #'n'
        beq     LED9F
        cmp     #'Y'
        beq     LEDB0
        cmp     #'y'
        beq     LEDB0
        jmp     LED35

LED9F:  jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, no_rect
        lda     #$03
        jmp     LEE6A

LEDB0:  jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, yes_rect
        lda     #$02
        jmp     LEE6A

LEDC1:  pla
        cmp     #$61
        bne     LEDD7
LEDC6:  jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, ok_try_again_rect
        lda     #$00
        jmp     LEE6A

LEDD7:  cmp     #$41
        beq     LEDC6
        cmp     #$0D
        beq     LEDC6
        jmp     LED35

LEDE2:  cmp     #$0D
        bne     LEDF7
        jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, ok_try_again_rect
LEDF2:  lda     #$00
        jmp     LEE6A

LEDF7:  jmp     LED35

LEDFA:  jsr     LF0B8
        MGTK_RELAY_CALL2 MGTK::MoveTo, event_coords
        bit     LE941
        bpl     LEE57
        MGTK_RELAY_CALL2 MGTK::InRect, cancel_rect
        cmp     #MGTK::inrect_inside
        bne     LEE1B
        jmp     LEEF8

LEE1B:  bit     LE941
        bvs     LEE57
        lda     LE941
        and     #$0F
        beq     LEE47
        MGTK_RELAY_CALL2 MGTK::InRect, no_rect
        cmp     #MGTK::inrect_inside
        bne     LEE37
        jmp     LEFD8

LEE37:  MGTK_RELAY_CALL2 MGTK::InRect, yes_rect
        cmp     #MGTK::inrect_inside
        bne     LEE67
        jmp     LF048

LEE47:  MGTK_RELAY_CALL2 MGTK::InRect, ok_try_again_rect
        cmp     #MGTK::inrect_inside
        bne     LEE67
        jmp     LEE88

LEE57:  MGTK_RELAY_CALL2 MGTK::InRect, ok_try_again_rect
        cmp     #MGTK::inrect_inside
        bne     LEE67
        jmp     LEF68

LEE67:  jmp     LED35

LEE6A:  pha
        MGTK_RELAY_CALL2 MGTK::SetPortBits, portbits2
        MGTK_RELAY_CALL2 MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL2 MGTK::PaintRect, $E89F
        pla
        rts

LEE88:  jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, ok_try_again_rect
        lda     #$00
        sta     LEEF7
LEE99:  MGTK_RELAY_CALL2 MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_up
        beq     LEEEA
        jsr     LF0B8
        MGTK_RELAY_CALL2 MGTK::MoveTo, event_coords
        MGTK_RELAY_CALL2 MGTK::InRect, ok_try_again_rect
        cmp     #MGTK::inrect_inside
        beq     LEECA
        lda     LEEF7
        beq     LEED2
        jmp     LEE99

LEECA:  lda     LEEF7
        bne     LEED2
        jmp     LEE99

LEED2:  jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, ok_try_again_rect
        lda     LEEF7
        clc
        adc     #$80
        sta     LEEF7
        jmp     LEE99

LEEEA:  lda     LEEF7
        beq     LEEF2
        jmp     LED35

LEEF2:  lda     #$00
        jmp     LEE6A

LEEF7:  .byte   0
LEEF8:  jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, cancel_rect
        lda     #$00
        sta     LEF67
LEF09:  MGTK_RELAY_CALL2 MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_up
        beq     LEF5A
        jsr     LF0B8
        MGTK_RELAY_CALL2 MGTK::MoveTo, event_coords
        MGTK_RELAY_CALL2 MGTK::InRect, cancel_rect
        cmp     #MGTK::inrect_inside
        beq     LEF3A
        lda     LEF67
        beq     LEF42
        jmp     LEF09

LEF3A:  lda     LEF67
        bne     LEF42
        jmp     LEF09

LEF42:  jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, cancel_rect
        lda     LEF67
        clc
        adc     #$80
        sta     LEF67
        jmp     LEF09

LEF5A:  lda     LEF67
        beq     LEF62
        jmp     LED35

LEF62:  lda     #$01
        jmp     LEE6A

LEF67:  .byte   0
LEF68:  lda     #$00
        sta     LEFD7
        jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, ok_try_again_rect
LEF79:  MGTK_RELAY_CALL2 MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_up
        beq     LEFCA
        jsr     LF0B8
        MGTK_RELAY_CALL2 MGTK::MoveTo, event_coords
        MGTK_RELAY_CALL2 MGTK::InRect, ok_try_again_rect
        cmp     #MGTK::inrect_inside
        beq     LEFAA
        lda     LEFD7
        beq     LEFB2
        jmp     LEF79

LEFAA:  lda     LEFD7
        bne     LEFB2
        jmp     LEF79

LEFB2:  jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, ok_try_again_rect
        lda     LEFD7
        clc
        adc     #$80
        sta     LEFD7
        jmp     LEF79

LEFCA:  lda     LEFD7
        beq     LEFD2
        jmp     LED35

LEFD2:  lda     #$00
        jmp     LEE6A

LEFD7:  .byte   0
LEFD8:  lda     #$00
        sta     LF047
        jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, no_rect
LEFE9:  MGTK_RELAY_CALL2 MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_up
        beq     LF03A
        jsr     LF0B8
        MGTK_RELAY_CALL2 MGTK::MoveTo, event_coords
        MGTK_RELAY_CALL2 MGTK::InRect, no_rect
        cmp     #MGTK::inrect_inside
        beq     LF01A
        lda     LF047
        beq     LF022
        jmp     LEFE9

LF01A:  lda     LF047
        bne     LF022
LF01F:  jmp     LEFE9

LF022:  jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, no_rect
        lda     LF047
        clc
        adc     #$80
        sta     LF047
        jmp     LEFE9

LF03A:  lda     LF047
        beq     LF042
        jmp     LED35

LF042:  lda     #$03
        jmp     LEE6A

LF047:  .byte   0
LF048:  lda     #$00
        sta     LF0B7
        jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, yes_rect
LF059:  MGTK_RELAY_CALL2 MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_up
        beq     LF0AA
        jsr     LF0B8
        MGTK_RELAY_CALL2 MGTK::MoveTo, event_coords
        MGTK_RELAY_CALL2 MGTK::InRect, yes_rect
        cmp     #MGTK::inrect_inside
        beq     LF08A
        lda     LF0B7
        beq     LF092
        jmp     LF059

LF08A:  lda     LF0B7
        bne     LF092
        jmp     LF059

LF092:  jsr     LF0DF
        MGTK_RELAY_CALL2 MGTK::PaintRect, yes_rect
        lda     LF0B7
        clc
        adc     #$80
        sta     LF0B7
        jmp     LF059

LF0AA:  lda     LF0B7
        beq     LF0B2
        jmp     LED35

LF0B2:  lda     #$02
        jmp     LEE6A

LF0B7:  .byte   0
LF0B8:  sub16   event_xcoord, portbits1::viewloc::xcoord, event_xcoord
        sub16   event_ycoord, portbits1::viewloc::ycoord, event_ycoord
        rts

LF0DF:  MGTK_RELAY_CALL2 MGTK::SetPenMode, penXOR
        rts

LF0E9:  stx     $06
        sty     $07
        ldy     #$00
        lda     ($06),y
        pha
        tay
LF0F3:  lda     ($06),y
        sta     LE9A0,y
        dey
        bne     LF0F3
        pla
        clc
        adc     LEB4B
        sta     LE98B
        tay
        inc     LE98B
        inc     LE98B
        lda     LEB45
        iny
        sta     LE98B,y
        lda     LEB46
        iny
        sta     LE98B,y
        rts

LF119:  stx     $06
        sty     $07
        ldy     #$00
        lda     ($06),y
        pha
        tay
LF123:  lda     ($06),y
        sta     $EA36,y
        dey
        bne     LF123
        pla
        clc
        adc     LEB4C
        sta     $EA21
        tay
        inc     $EA21
        inc     $EA21
        lda     LEB45
        iny
        sta     $EA21,y
        lda     LEB46
        iny
        sta     $EA21,y
        rts

LF149:  txa
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #$30
        ldy     LEB47
        sta     LEA49,y
        txa
        and     #$80
        asl     a
        rol     a
        adc     #$31
        ldy     LEB48
        sta     LEA49,y
        rts

LF167:  txa
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #$30
        ldy     LEB49
        sta     LEA7D,y
        txa
        and     #$80
        asl     a
        rol     a
        adc     #$31
        ldy     LEB4A
        sta     LEA7D,y
        rts

LF185:  sty     LD41D
        tya
        jsr     L0EB2
        beq     LF191
        sta     LD41E
LF191:  rts

LF192:  lda     LD41D
        sta     $0C46
        jsr     L129B
        beq     LF1C9
        cmp     #$52
        beq     LF1C9
        lda     $0C49
        and     #$0F
        bne     LF1C9
        lda     $0C4A
        cmp     #$52
        beq     LF1C9
        MGTK_RELAY_CALL2 MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_key_down
        bne     LF192
        lda     event_key
        cmp     #CHAR_ESCAPE
        bne     LF192
        return  #$80

LF1C9:  return  #$00

LF1CC:  cmp     #$03
        bcc     LF1D7
        cmp     #$06
        bcs     LF1D7
        jsr     L127E
LF1D7:  rts

        tya
        lsr     a
        bcs     LF1DF
        bit     $C055
LF1DF:  tay
        lda     ($28),y
        pha
        cmp     #$E0
        bcc     LF1E9
        sbc     #$20
LF1E9:  and     #$3F
        sta     ($28),y
        lda     $C000
        bmi     LF1F5
        jmp     L51ED

LF1F5:  pla
        sta     ($28),y
        bit     $C054
        lda     $C000
        .byte   $2C
        .byte   $10
