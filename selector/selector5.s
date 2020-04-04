;;; ============================================================
;;; Selector Application
;;; ============================================================

        .org $4000

.scope selector5

L2000           := $2000
LA000           := $A000        ; selector7/8 entry points
LA003           := $A003        ; selector7 entry point
LD23E           := $D23E        ; in selector6

selector_list := $B300

;;; ============================================================
;;; MGTK library
;;; ============================================================

MGTK:
        .scope
        .include "../mgtk/mgtk_100B4.s"
        .endscope

;;; ============================================================
;;; End of MGTK
;;; ============================================================

;;; ???

        .byte   $04,$04,$04,$04,$04,$04,$04,$04
        .byte   $04,$05,$05,$05,$05,$05,$05,$05
        .byte   $05,$05,$05,$05,$05,$05,$05,$05
        .byte   $05,$06,$06,$06,$06,$06,$06,$06
        .byte   $06,$06,$06,$06,$06,$00,$52,$54
        .byte   $55,$56,$57,$58,$59,$5A,$5B,$5C
        .byte   $5D,$5E,$5F,$60,$61,$62,$63,$64
        .byte   $65,$66,$67,$68,$69,$6A,$6B,$6C
        .byte   $6D,$6E,$6F,$70,$71,$72,$73,$74
        .byte   $75,$76,$77,$78,$79,$7A,$7B,$7C
        .byte   $7D,$7E,$7F,$80,$81,$82,$83,$84
        .byte   $85,$86,$87,$88,$89,$8A,$8B,$8C
        .byte   $8D,$8E,$8F,$90,$91,$92,$93

        .res    447, 0

        .byte   $6C,$00,$04,$00,$A8,$00,$E1,$00
        .byte   $00,$00,$02,$00,$BE,$00,$E1,$00
        .byte   $00,$00,$02,$00,$FE,$03,$00,$00
        .byte   $00,$00,$A8,$02,$00,$95,$00,$00
        .byte   $00,$10,$57,$27,$A8,$97,$00,$00
        .byte   $00,$18,$10,$00,$EE,$9A,$00,$00
        .byte   $00,$40,$10,$00,$62,$D0,$E0,$00
        .byte   $00,$40,$41,$00,$76,$D0,$E0,$00
        .byte   $00,$20,$D5,$17,$00,$E8,$01,$00
        .byte   $00,$00,$F3,$01,$00,$D4,$00,$00
        .byte   $00,$80,$7D,$3C,$00,$20,$00,$00
        .byte   $00,$00,$00,$18,$00,$D0,$01,$00
        .byte   $00,$00,$00,$10,$00,$D0,$01,$00
        .byte   $00,$80,$00,$00,$5C,$17,$95,$00
        .byte   $01,$00,$00,$95,$AF,$68,$C0,$00
        .byte   $48,$AF,$83,$C0,$00,$AF,$83,$C0
        .byte   $00,$22,$7F,$FB,$01,$68,$8F,$68
        .byte   $C0,$00,$40,$08,$78,$18,$FB,$08
        .byte   $E2,$30,$A9,$00,$90,$02,$A9,$80
        .byte   $8F,$F5,$95,$00,$22,$64,$00,$E1
        .byte   $C2,$30,$AF,$BE,$00,$E1,$30,$34
        .byte   $09,$00,$80,$8F,$BE,$00,$E1,$68
        .byte   $48,$EB,$E2,$30,$48,$28,$E2,$30
        .byte   $AF,$68,$C0,$00,$8F,$F6,$95,$00
        .byte   $29,$04,$D0,$0A,$AF,$8B,$C0,$00
        .byte   $AF,$8B,$C0,$00,$80,$08,$AF,$83
        .byte   $C0,$00,$AF,$83,$C0,$00,$0B,$8B
        .byte   $5C,$00,$E8,$01,$AF,$EE,$95,$00
        .byte   $8F,$F0,$95,$00,$A9,$07,$00,$8F
        .byte   $EE,$95,$00,$18,$A3,$03,$69,$06
        .byte   $00,$83,$03,$90,$09,$E2,$20,$A3
        .byte   $05,$69,$00,$00,$83,$05,$80,$19
        .byte   $AB,$2B,$C2,$30,$AF,$EE,$95,$00
        .byte   $29,$FF,$00,$D0,$0C,$A3,$02,$29
        .byte   $FE,$FF,$09,$02,$00,$83,$02,$80
        .byte   $0C,$C2,$30,$A3,$02,$29,$FD,$FF
        .byte   $09,$01,$00,$83,$02,$78,$E2,$30
        .byte   $AF,$F6,$95,$00,$8F,$68,$C0,$00
        .byte   $C2,$30,$AF,$EE,$95,$00,$29,$FF
        .byte   $00,$C9,$07,$00,$F0,$0B,$AF,$BE
        .byte   $00,$E1,$29,$FF,$7F,$8F,$BE,$00
        .byte   $E1,$22,$68,$00,$E1,$AF,$EE,$95
        .byte   $00,$29,$FF,$00,$48,$AF,$F0,$95
        .byte   $00,$8F,$EE,$95,$00,$68,$28,$FB
        .byte   $28,$6B,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$38,$FB,$20,$00
        .byte   $BF,$C0,$09,$97,$08,$18,$FB,$28
        .byte   $6B,$38,$FB,$20,$00,$BF,$C1,$15
        .byte   $97,$08,$18,$FB,$28,$6B,$38,$FB
        .byte   $20,$00,$BF,$C2,$18,$97,$08,$18
        .byte   $FB,$28,$6B,$38,$FB,$20,$00,$BF
        .byte   $C3,$1D,$97,$08,$18,$FB,$28,$6B
        .byte   $38,$FB,$20,$00,$BF,$C4,$2B,$97
        .byte   $08,$18,$FB,$28,$6B,$38,$FB,$20
        .byte   $00,$BF,$C5,$3D,$97,$08,$18,$FB
        .byte   $28,$6B,$38,$FB,$20,$00,$BF,$C6
        .byte   $41,$97,$08,$18,$FB,$28,$6B,$38
        .byte   $FB,$20,$00,$BF,$C8,$44,$97,$08
        .byte   $18,$FB,$28,$6B,$38,$FB,$20,$00
        .byte   $BF,$C9,$4A,$97,$08,$18,$FB,$28
        .byte   $6B,$38,$FB,$20,$00,$BF,$CA,$4E
        .byte   $97,$08,$18,$FB,$28,$6B,$38,$FB
        .byte   $20,$00,$BF,$CB,$56,$97,$08,$18
        .byte   $FB,$28,$6B,$38,$FB,$20,$00,$BF

;;; Font
        .assert * = $8800, error, "Font location mismatch"
        .incbin "../fonts/SELECTOR.FONT"

;;; ???
        .byte   $8D,$3F,$07
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$03,$03,$03
        .byte   $03,$03,$03,$03,$03,$04,$04,$04
        .byte   $04,$04,$04,$04,$04,$05,$05,$05
        .byte   $05,$05,$05,$05,$05,$06,$06,$06
        .byte   $06,$06,$06,$06,$06,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$08,$08,$08
        .byte   $08,$08,$08,$08,$08,$09,$09,$09
        .byte   $09,$09,$09,$09,$09,$0A,$0A,$0A
        .byte   $0A,$0A,$0A,$0A,$0A,$0B,$0B,$0B
        .byte   $0B,$0B,$0B,$0B,$0B,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0D,$0D,$0D
        .byte   $0D,$0D

;;; Application entry point

START:  jmp     entry

pencopy:        .byte   MGTK::pencopy
penOR:          .byte   MGTK::penOR
penXOR:         .byte   MGTK::penXOR
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy
notpenOR:       .byte   MGTK::notpenOR
notpenXOR:      .byte   MGTK::notpenXOR
notpenBIC:      .byte   MGTK::notpenBIC

saved_stack:
        .byte   $00

;;; for MenuSelect, HiliteMenu, MenuKey
.params menu_params
menu_id:
        .byte   $00
menu_item:
        .byte   $00

;;; for MenuKey only
which_key:
        .byte   $00
key_mods:
        .byte   $00
.endparams

        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00

menu:   DEFINE_MENU_BAR 3
        DEFINE_MENU_BAR_ITEM 1, str_apple, apple_menu
        DEFINE_MENU_BAR_ITEM 2, str_file, file_menu
        DEFINE_MENU_BAR_ITEM 3, str_startup, startup_menu

apple_menu:
        DEFINE_MENU 5
        DEFINE_MENU_ITEM str_a2desktop
        DEFINE_MENU_ITEM str_blank
        DEFINE_MENU_ITEM str_copyright1
        DEFINE_MENU_ITEM str_copyright2
        DEFINE_MENU_ITEM str_copyright3

file_menu:
        DEFINE_MENU 1
        DEFINE_MENU_ITEM str_run_a_program, 'R', 'r'

startup_menu:
        DEFINE_MENU 1

kMenuItemShortcutOffset = 2

mi_x1:  DEFINE_MENU_ITEM str_slot_x1, '0', '0'
mi_x2:  DEFINE_MENU_ITEM str_slot_x2, '0', '0'
mi_x3:  DEFINE_MENU_ITEM str_slot_x3, '0', '0'
mi_x4:  DEFINE_MENU_ITEM str_slot_x4, '0', '0'
mi_x5:  DEFINE_MENU_ITEM str_slot_x5, '0', '0'
mi_x6:  DEFINE_MENU_ITEM str_slot_x6, '0', '0'
mi_x7:  DEFINE_MENU_ITEM str_slot_x7, '0', '0'

str_apple:
        PASCAL_STRING $1E       ; TODO: GLYPH_SAPPLE

str_file:
        PASCAL_STRING "File"
str_startup:
        PASCAL_STRING "Startup"

str_a2desktop:
        PASCAL_STRING "Apple II DeskTop Version 1.1"
str_blank:
        PASCAL_STRING " "
str_copyright1:
        PASCAL_STRING "Copyright Apple Computer Inc., 1986 "
str_copyright2:
        PASCAL_STRING "Copyright Version Soft, 1985 - 1986"
str_copyright3:
        PASCAL_STRING "All Rights reserved "

str_run_a_program:
        PASCAL_STRING "Run a Program ..."


        kStrSlotXOffset = 6
str_slot_x1:
        PASCAL_STRING "Slot x "
str_slot_x2:
        PASCAL_STRING "Slot x "
str_slot_x3:
        PASCAL_STRING "Slot x "
str_slot_x4:
        PASCAL_STRING "Slot x "
str_slot_x5:
        PASCAL_STRING "Slot x "
str_slot_x6:
        PASCAL_STRING "Slot x "
str_slot_x7:
        PASCAL_STRING "Slot x "


;;; Slot numbers
slot_table:     .byte   0       ; number of entries

slot_x1:        .byte   0
slot_x2:        .byte   0
slot_x3:        .byte   0
slot_x4:        .byte   0
slot_x5:        .byte   0
slot_x6:        .byte   0
slot_x7:        .byte   0

;;; ============================================================
;;; Event Params (and overlapping param structs)

event_params := *
event_kind := event_params + 0
        ;; if kind is key_down
event_key := event_params + 1
event_modifiers := event_params + 2
        ;; if kind is no_event, button_down/up, drag, or apple_key:
event_coords := event_params + 1
event_xcoord := event_params + 1
event_ycoord := event_params + 3
        ;; if kind is update:
event_window_id := event_params + 1

screentowindow_params := *
screentowindow_window_id := screentowindow_params + 0
screentowindow_screenx := screentowindow_params + 1
screentowindow_screeny := screentowindow_params + 3
screentowindow_windowx := screentowindow_params + 5
screentowindow_windowy := screentowindow_params + 7
        .assert screentowindow_screenx = event_xcoord, error, "param mismatch"
        .assert screentowindow_screeny = event_ycoord, error, "param mismatch"

findwindow_params := * + 1    ; offset to x/y overlap event_params x/y
findwindow_mousex := findwindow_params + 0
findwindow_mousey := findwindow_params + 2
findwindow_which_area := findwindow_params + 4
findwindow_window_id := findwindow_params + 5
        .assert findwindow_mousex = event_xcoord, error, "param mismatch"
        .assert findwindow_mousey = event_ycoord, error, "param mismatch"

beginupdate_params := * + 1
beginupdate_window_id := beginupdate_params + 0

        .byte   0
        .byte   0
L8F7B:  .byte   0
        .byte   0
        .byte   0
L8F7E:  .byte   0
L8F7F:  .byte   0
L8F80:  .byte   0
L8F81:  .byte   0
        .byte   0

grafport2:
        .tag    MGTK::GrafPort

.params getwinport_params
window_id:     .byte   0
a_grafport:    .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort

.params startdesktop_params
machine:        .byte   $06
subid:          .byte   $EA
op_sys:         .byte   0
slot_num:       .byte   0
use_interrupts: .byte   0
sysfontptr:     .addr   FONT
savearea:       .addr   $800
savesize:       .word   $800
.endparams

.params winfo
window_id:
        .byte   $01
        .byte   $01
        .addr   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .word   150
        .word   50
        .word   500
        .word   140

viewloc:.word   25, 40
        .word   $2000
        .byte   $80
        .byte   $00

        .word   0, 0, 500, 110

        .res    8, $FF
        .byte   $FF
        .byte   0
        .word   0, 0
        .byte   1, 1
        .byte   0
        .byte   $7F
        .word   $8800
        .byte   0
        .byte   0
.endparams

rect_frame:
        DEFINE_RECT 4, 2, 496, 108

rect_ok_btn:
        DEFINE_RECT 340, 94, 440, 105

rect_desktop_btn:
        DEFINE_RECT 60, 94, 160, 105

pos_ok_label:
        DEFINE_POINT 344, 104
str_ok_btn:
        PASCAL_STRING {" OK           ",CHAR_RETURN}

pos_desktop_label:
        DEFINE_POINT 64, 104
str_desktop_btn:
        PASCAL_STRING " DeskTop       Q "

setpensize_params:
        .byte   2, 1

pos_title_string:
        .word   0, $F

        PASCAL_STRING "Selector"

pt0:    DEFINE_POINT 5, 22, pt0

pt1:    DEFINE_POINT   5, 20
pt2:    DEFINE_POINT   495, 20
pt3:    DEFINE_POINT   5, 90
pt4:    DEFINE_POINT   495, 90

pt5:    DEFINE_POINT 10, 30, pt5
pt6:    DEFINE_POINT 0, 0, pt6

rect2:  DEFINE_RECT 5, 21, 132, 29, rect2

rect1:  DEFINE_RECT 0, 0, 0, 0, rect1

        .byte   0
        .byte   $7F

        DEFINE_OPEN_PARAMS open_selector_list_params, str_selector_list, $BB00
        DEFINE_READ_PARAMS read_selector_list_params, selector_list, $800

        DEFINE_OPEN_PARAMS open_desktop2_params, str_desktop2, $1C00
        DEFINE_READ_PARAMS read_desktop2_params, $2000, $400

str_selector_list:
        PASCAL_STRING "Selector.List"

str_desktop2:
        PASCAL_STRING "DeskTop2"

        DEFINE_CLOSE_PARAMS close_params

        DEFINE_OPEN_PARAMS open_selector_params, str_selector, $800

str_selector:
        PASCAL_STRING "selector"

        DEFINE_SET_MARK_PARAMS set_mark_overlay1_params, overlay1_offset
        DEFINE_SET_MARK_PARAMS set_mark_overlay2_params, overlay2_offset
        DEFINE_READ_PARAMS read_overlay1_params, overlay_addr, overlay1_size
        DEFINE_READ_PARAMS read_overlay2_params, overlay_addr, overlay2_size
        DEFINE_CLOSE_PARAMS close_params2

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_desktop2_params, str_desktop2_2
str_desktop2_2:
        PASCAL_STRING "DeskTop2"

desktop_available_flag:
        .byte   0


;;; Index of selected entry, or $FF if none
selected_entry:
        .byte   0

        .byte   0
L9110:  .byte   0
L9111:  .byte   0
L9112:  .byte   0
L9113:  .byte   0
L9114:  .byte   0
L9115:  .byte   0
L9116:  .byte   0
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

num_run_list_entries:
        .byte   0
num_other_run_list_entries:
        .byte   0

L9129:  .byte   0

;;; ============================================================
;;; App Initialization

entry:
.proc app_init
        cli
        copy    #$FF, selected_entry
        jsr     load_selector_list
        copy    #1, L9129
        lda     num_other_run_list_entries
        ora     num_run_list_entries
        bne     check_key_down

quick_run_desktop:
        yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_desktop2_params
        beq     :+
        jmp     done_keys
:       jmp     run_desktop

        ;; --------------------------------------------------
        ;; Check for key down

check_key_down:
        lda     #0
        sta     quick_boot_slot

        lda     KBD
        bpl     done_keys
        sta     KBDSTRB
        and     #CHAR_MASK
        bit     BUTN0           ; Open Apple?
        bmi     :+
        bit     BUTN1           ; Solid Apple?
        bpl     check_key
:       cmp     #'1'            ; Solid Apple + 1...7 = boot slot
        bcc     check_key
        cmp     #'8'
        bcs     check_key
        sec
        sbc     #$30            ; ASCII to number
        sta     quick_boot_slot
        jmp     done_keys

check_key:
        cmp     #'Q'            ; If Q is down, try launching DeskTop
        beq     quick_run_desktop
        cmp     #'q'
        beq     quick_run_desktop

        sec
        sbc     #'1'            ; 1-8 run that selector entry
        bmi     done_keys
        cmp     num_run_list_entries
        bcs     done_keys
        sta     selected_entry
        jsr     get_selector_list_entry_addr
        stax    $06
        ldy     #$0F
        lda     ($06),y
        cmp     #$C0
        beq     L91AC
        jsr     get_copied_to_ramcard_flag
        beq     done_keys
        jsr     L9DFF
        beq     L91AC
        jmp     done_keys

L91AC:  lda     selected_entry
        jsr     L9C07

        ;; --------------------------------------------------

done_keys:
        sta     KBDSTRB
        copy    #0, L9129

        ;; --------------------------------------------------

        jsr     disconnect_ramdisk

        ;; --------------------------------------------------
        ;; Find slots with devices

        ldx     #1
sloop:  cpx     #3
        beq     L91DE
        cpx     #2
        beq     L91DE
        ldy     DEVCNT
:       lda     DEVLST,y
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     L91E5
        cpx     L91E5
        beq     add_slot_table_entry
        dey
        bpl     :-

L91DE:  cpx     #$07
        beq     L91F2
        inx
        bne     sloop

L91E5:  .byte   0

add_slot_table_entry:
        inc     slot_table
        ldy     slot_table
        sta     slot_table,y
        jmp     L91DE

        ;; --------------------------------------------------
        ;; Set up Startup menu

L91F2:  lda     quick_boot_slot
        beq     set_startup_menu_items
        ldy     slot_table
L91FA:  cmp     slot_table,y
        beq     L9205
        dey
        bne     L91FA
        jmp     set_startup_menu_items

L9205:  ora     #$C0
        sta     @addr+1
        @addr := *+1
        jmp     CLR80COL

set_startup_menu_items:
        lda     slot_table
        sta     startup_menu

        lda     slot_x1
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x1 + kStrSlotXOffset
        sta     mi_x1 + kMenuItemShortcutOffset
        sta     mi_x1 + kMenuItemShortcutOffset + 1

        lda     slot_x2
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x2 + kStrSlotXOffset
        sta     mi_x2 + kMenuItemShortcutOffset
        sta     mi_x2 + kMenuItemShortcutOffset + 1

        lda     slot_x3
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x3 + kStrSlotXOffset
        sta     mi_x3 + kMenuItemShortcutOffset
        sta     mi_x3 + kMenuItemShortcutOffset + 1

        lda     slot_x4
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x4 + kStrSlotXOffset
        sta     mi_x4 + kMenuItemShortcutOffset
        sta     mi_x4 + kMenuItemShortcutOffset + 1

        lda     slot_x5
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x5 + kStrSlotXOffset
        sta     mi_x5 + kMenuItemShortcutOffset
        sta     mi_x5 + kMenuItemShortcutOffset + 1

        lda     slot_x6
        ora     #$30            ; number to ASCII digit
        sta     str_slot_x6 + kStrSlotXOffset
        sta     mi_x6 + kMenuItemShortcutOffset
        sta     mi_x6 + kMenuItemShortcutOffset + 1

        lda     slot_x7
        ora     #$30            ; number to ASCII digit
        sta     mi_x7 + kMenuItemShortcutOffset
        sta     mi_x7 + kMenuItemShortcutOffset + 1
        sta     str_slot_x7 + kStrSlotXOffset

        MGTK_CALL MGTK::StartDeskTop, startdesktop_params
        MGTK_CALL MGTK::SetMenu, menu
        MGTK_CALL MGTK::ShowCursor
        MGTK_CALL MGTK::FlushEvents

        ;; --------------------------------------------------

        ;; Is DeskTop available?
        yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_desktop2_params
        beq     :+
        lda     #$80
:       sta     desktop_available_flag

        ;; --------------------------------------------------
        ;; Open the window

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     L9914
        lda     #0
        sta     L9112
        sta     L9110
        lda     #$01
        sta     L9111
        lda     #$FF
        sta     selected_entry
        jsr     load_selector_list
        jsr     draw_entries
        jmp     event_loop

quick_boot_slot:
        .byte   0
.endproc

;;; ============================================================
;;; Event Loop

event_loop:
        bit     L9112
        bpl     L92D6
        dec     L9110
        bne     L92D6
        dec     L9111
        bne     L92D6
        lda     #$00
        sta     L9112
L92D6:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     handle_button_down
        jmp     event_loop
:       cmp     #MGTK::EventKind::key_down
        bne     not_key

        ;; Key Down
        bit     desktop_available_flag
        bmi     not_desktop
        lda     event_key
        and     #CHAR_MASK
        cmp     #'Q'
        beq     :+
        cmp     #'q'
        bne     not_desktop
:       yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_desktop2_params
        beq     found_desktop
        lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        bne     not_desktop
        beq     :-
found_desktop:
        jmp     run_desktop

not_desktop:
        jsr     L937B
        jmp     event_loop

        ;; --------------------------------------------------

not_key:
        cmp     #MGTK::EventKind::update
        bne     not_update
        jsr     L9339

not_update:
        jmp     event_loop

L9326:  MGTK_CALL MGTK::PeekEvent, event_params
        lda     event_kind
        cmp     #$06
        bne     L9351
        MGTK_CALL MGTK::GetEvent, event_params
L9339:  jsr     L933F
        jmp     L9326

L933F:  MGTK_CALL MGTK::BeginUpdate, beginupdate_params
        bne     L9351
        jsr     L9352
        MGTK_CALL MGTK::EndUpdate
        rts

L9351:  rts

L9352:  jsr     L991A
        jsr     draw_entries
        rts

;;; ============================================================
;;; Menu dispatch tables

menu_dispatch_table:
        ;; Apple menu
menu1:  .addr   noop
        .addr   noop
        .addr   noop
        .addr   noop
        .addr   noop
        .addr   noop
        .addr   noop

        ;; File menu
menu2:  .addr   cmd_run_a_program

        ;; Startup menu
menu3:  .addr   cmd_startup
        .addr   cmd_startup
        .addr   cmd_startup
        .addr   cmd_startup
        .addr   cmd_startup
        .addr   cmd_startup
        .addr   cmd_startup
menu_end:

menu_addr_table:
        .byte   menu1 - menu_dispatch_table
        .byte   menu2 - menu_dispatch_table
        .byte   menu3 - menu_dispatch_table
        .byte   menu_end - menu_dispatch_table

;;; ============================================================

L937B:  lda     L8F7B
        bne     L938C
        lda     event_key
        and     #CHAR_MASK
        cmp     #CHAR_ESCAPE
        beq     L93A5
L9389:  jmp     L95F5

L938C:  lda     event_key
        and     #CHAR_MASK
        cmp     #CHAR_ESCAPE
        beq     L93A5
        cmp     #'R'
        beq     L93A5
        cmp     #'r'
        beq     L93A5
        cmp     #'9'+1
        bcs     L9389
        cmp     #'1'
        bcc     L9389
L93A5:  sta     menu_params::which_key
        lda     L8F7B
        sta     menu_params::key_mods
        MGTK_CALL MGTK::MenuKey, menu_params::menu_id
L93B4:  ldx     menu_params::menu_item
        beq     L93BE
        ldx     menu_params::menu_id
        bne     L93C1
L93BE:  jmp     event_loop

L93C1:  dex
        lda     menu_addr_table,x
        tax
        ldy     menu_params::menu_item
        dey
        tya
        asl     a
        sta     addr
        txa
        clc
        adc     addr
        tax
        copy16  menu_dispatch_table,x, addr
        jsr     L93EB
        MGTK_CALL MGTK::HiliteMenu, menu_params
        rts

L93EB:  tsx
        stx     saved_stack

        addr := *+1
        jmp     dummy1234


;;; ============================================================

.proc cmd_run_a_program
        lda     selected_entry
        bmi     L93FF
        jsr     L9B42
        lda     #$FF
        sta     selected_entry
L93FF:  jsr     set_watch_cursor
        yax_call MLI_WRAPPER, OPEN, open_selector_params
        bne     L9443
        lda     open_selector_params::ref_num
        sta     set_mark_overlay1_params::ref_num
        sta     read_overlay1_params::ref_num
        yax_call MLI_WRAPPER, SET_MARK, set_mark_overlay1_params
        yax_call MLI_WRAPPER, READ, read_overlay1_params
        yax_call MLI_WRAPPER, CLOSE, close_params2
        jsr     LA000
        bne     L943F
L9436:  tya
        jsr     L9C1A
        jsr     LA003
        beq     L9436
L943F:  jsr     load_selector_list
        rts

L9443:  lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        bne     L9450
        jsr     set_watch_cursor
        jmp     L93FF

L9450:  rts
.endproc

;;; ============================================================

handle_button_down:
        MGTK_CALL MGTK::FindWindow, selector5::event_coords
        lda     L8F7E
        bne     L945D
        rts

L945D:  cmp     #$01
        bne     L946A
        MGTK_CALL MGTK::MenuSelect, menu_params
        jmp     L93B4

L946A:  cmp     #$02
        bne     L9472
        jmp     L9473

        rts

L9472:  rts

L9473:  lda     L8F7F
        cmp     winfo::window_id
        beq     L947C
        rts

L947C:  lda     winfo::window_id
        jsr     L9A15
        lda     winfo::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect_ok_btn
        cmp     #MGTK::inrect_inside
        beq     L94A1
        jmp     L94B6

L94A1:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect_ok_btn
        jsr     ok_btn_event_loop
        bmi     L94B5
        jsr     L97BD
L94B5:  rts

L94B6:  bit     desktop_available_flag
        bmi     L94F0
        MGTK_CALL MGTK::InRect, rect_desktop_btn
        cmp     #MGTK::inrect_inside
        beq     L94C8
        jmp     L94F0

L94C8:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect_desktop_btn
        jsr     desktop_btn_event_loop
        bmi     L94B5
L94D9:  yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_desktop2_params
        beq     L94ED
        lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        bne     L94B5
        beq     L94D9
L94ED:  jmp     run_desktop

L94F0:  sub16   L8F7E, pt5::xcoord, L8F7E
        sub16   L8F80, pt0::ycoord, L8F80
        lda     L8F81
        bpl     L9527
        lda     selected_entry
        jsr     L9B42
        lda     #$FF
        sta     selected_entry
        rts

L9527:  lsr16   L8F80
        lsr16   L8F80
        lsr16   L8F80
        lda     L8F80
        cmp     #$08
        bcc     L954C
        lda     selected_entry
        jsr     L9B42
        lda     #$FF
        sta     selected_entry
        rts

L954C:  sta     L959D
        lda     #$00
        sta     L959F
        asl     L8F7E
        rol     L8F7F
        rol     L959F
        lda     L8F7F
        asl     a
        asl     a
        asl     a
        clc
        adc     L959D
        sta     L959E
        cmp     #$08
        bcc     L9571
        jmp     L9582

L9571:  cmp     num_run_list_entries
        bcc     L9596
        lda     selected_entry
        jsr     L9B42
        lda     #$FF
        sta     selected_entry
        rts

L9582:  sec
        sbc     #$08
        cmp     num_other_run_list_entries
        bcc     L9596
        lda     selected_entry
        jsr     L9B42
        lda     #$FF
        sta     selected_entry
        rts

L9596:  lda     L959E
        jsr     L9AFD
        rts

L959D:  .byte   0
L959E:  .byte   0
L959F:  .byte   0

MLI_WRAPPER:
        sty     $95AE
        stax    $95AF
        php
        sei
        MLI_CALL $00, $0000
        plp
        and     #$FF
        rts

;;; ============================================================

noop:   rts

;;; ============================================================

.proc run_desktop
        yax_call MLI_WRAPPER, OPEN, open_desktop2_params
        lda     open_desktop2_params::ref_num
        sta     read_desktop2_params::ref_num
        sta     DHIRESOFF
        sta     TXTCLR
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        yax_call MLI_WRAPPER, READ, read_desktop2_params
        yax_call MLI_WRAPPER, CLOSE, close_params
        jmp     L2000
.endproc

;;; ============================================================

L95F5:  lda     winfo::window_id
        jsr     L9A15
        lda     event_key
        and     #CHAR_MASK
        cmp     #$1C            ; ??? CHAR_ESCAPE + 1 ?
        bcs     L9607
        jmp     L9638

L9607:  cmp     #'1'
        bcs     L960C
        rts

L960C:  cmp     #'9'
        bcc     L9611
        rts

L9611:  sec
        sbc     #'1'
        sta     L97BC
        cmp     num_run_list_entries
        bcc     L961D
        rts

L961D:  lda     selected_entry
        bmi     L962E
        cmp     L97BC
        bne     L9628
        rts

L9628:  lda     selected_entry
        jsr     L9B42
L962E:  lda     L97BC
        sta     selected_entry
        jsr     L9B42
        rts

L9638:  cmp     #CHAR_RETURN
        bne     L9658
        lda     winfo::window_id
        jsr     L9A15
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect_ok_btn
        MGTK_CALL MGTK::PaintRect, rect_ok_btn
        jsr     L97BD
        rts

L9658:  cmp     #$15
        beq     L965F
        jmp     L96B5

L965F:  lda     num_run_list_entries
        bne     L966A
        lda     num_other_run_list_entries
        bne     L966A
        rts

L966A:  lda     selected_entry
        bpl     L9678
        lda     #$00
        sta     selected_entry
        jsr     L9B42
        rts

L9678:  lda     selected_entry
        cmp     #$08
        bcc     L9682
        jmp     L969A

L9682:  cmp     num_other_run_list_entries
        bcc     L9688
        rts

L9688:  clc
        adc     #$08
        pha
        lda     selected_entry
        jsr     L9B42
        pla
        sta     selected_entry
        jsr     L9B42
        rts

L969A:  cmp     num_other_run_list_entries
        bcc     L96A0
        rts

L96A0:  lda     selected_entry
        clc
        adc     #$08
        pha
        lda     selected_entry
        jsr     L9B42
        pla
        sta     selected_entry
        jsr     L9B42
        rts

L96B5:  cmp     #$08
        beq     L96BC
        jmp     L96EA

L96BC:  lda     selected_entry
        bpl     L96C2
        rts

L96C2:  cmp     #$08
        bcs     L96C7
        rts

L96C7:  lda     selected_entry
        sec
        sbc     #$08
        cmp     #$08
        bcs     L96D7
        cmp     num_run_list_entries
        bcc     L96D7
        rts

L96D7:  lda     selected_entry
        jsr     L9B42
        lda     selected_entry
        sec
        sbc     #$08
        sta     selected_entry
        jsr     L9B42
        rts

L96EA:  cmp     #$0B
        beq     L96F1
        jmp     L976B

L96F1:  lda     selected_entry
        bpl     L96F7
        rts

L96F7:  lda     selected_entry
        jsr     L9B42
        jsr     L9728
        lda     selected_entry
        cmp     #$08
        bcc     L970E
        sec
        sbc     #$08
        clc
        adc     num_run_list_entries
L970E:  sec
        sbc     #$01
        bpl     L971D
        lda     num_run_list_entries
        clc
        adc     num_other_run_list_entries
        sec
        sbc     #$01
L971D:  tax
        lda     L974B,x
        sta     selected_entry
        jsr     L9B42
        rts

L9728:  ldx     #$00
L972A:  cpx     num_run_list_entries
        beq     L9737
        txa
        sta     L974B,x
        inx
        jmp     L972A

L9737:  ldy     #$00
L9739:  cpy     num_other_run_list_entries
        bne     L973F
        rts

L973F:  tya
        clc
        adc     #$08
        sta     L974B,x
        inx
        iny
        jmp     L9739

L974B:  .byte   0
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
L976B:  cmp     #$0A
        beq     L9770
        rts

L9770:  lda     num_run_list_entries
        bne     L977B
        lda     num_other_run_list_entries
        bne     L977B
        rts

L977B:  lda     selected_entry
        bpl     L9789
        lda     #$00
        sta     selected_entry
        jsr     L9B42
        rts

L9789:  lda     selected_entry
        jsr     L9B42
        jsr     L9728
        lda     num_run_list_entries
        clc
        adc     num_other_run_list_entries
        sta     L97BC
        ldx     #$00
L979E:  lda     L974B,x
        cmp     selected_entry
        beq     L97AA
        inx
        jmp     L979E

L97AA:  inx
        cpx     L97BC
        bne     L97B2
        ldx     #$00
L97B2:  lda     L974B,x
        sta     selected_entry
        jsr     L9B42
        rts

L97BC:  .byte   0
L97BD:  lda     selected_entry
        bmi     L97C5
        jsr     L9C07
L97C5:  rts

;;; ============================================================

.proc draw_entries

        ;; Run List
        lda     #0
        sta     count
:       lda     count
        cmp     num_run_list_entries
        beq     :+
        jsr     draw_list_entry
        inc     count
        jmp     :-

        ;; Other Run List
:       lda     #0
        sta     count
:       lda     count
        cmp     num_other_run_list_entries
        beq     done
        clc
        adc     #8
        jsr     draw_list_entry
        inc     count
        jmp     :-

done:   rts

count:  .byte   0
.endproc

;;; ============================================================

.proc load_selector_list
        yax_call MLI_WRAPPER, OPEN, open_selector_list_params
        lda     open_selector_list_params::ref_num
        sta     read_selector_list_params::ref_num
        yax_call MLI_WRAPPER, READ, read_selector_list_params
        yax_call MLI_WRAPPER, CLOSE, close_params
        copy    selector_list, num_run_list_entries
        copy    selector_list+1, num_other_run_list_entries
        rts
.endproc

;;; ============================================================

.proc load_overlay2
start:  yax_call MLI_WRAPPER, OPEN, open_selector_params
        bne     error
        lda     open_selector_params::ref_num
        sta     set_mark_overlay2_params::ref_num
        sta     read_overlay2_params::ref_num
        yax_call MLI_WRAPPER, SET_MARK, set_mark_overlay2_params
        yax_call MLI_WRAPPER, READ, read_overlay2_params
        yax_call MLI_WRAPPER, CLOSE, close_params2
        rts

error:  lda     #AlertID::insert_system_disk
        jsr     ShowAlert
        beq     start
        rts
.endproc

;;; ============================================================

pointer_cursor:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0100000),px(%0000000)
        .byte   px(%0110000),px(%0000000)
        .byte   px(%0111000),px(%0000000)
        .byte   px(%0111100),px(%0000000)
        .byte   px(%0111110),px(%0000000)
        .byte   px(%0111111),px(%0000000)
        .byte   px(%0101100),px(%0000000)
        .byte   px(%0000110),px(%0000000)
        .byte   px(%0000110),px(%0000000)
        .byte   px(%0000011),px(%0000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000)
        .byte   px(%1110000),px(%0000000)
        .byte   px(%1111000),px(%0000000)
        .byte   px(%1111100),px(%0000000)
        .byte   px(%1111110),px(%0000000)
        .byte   px(%1111111),px(%0000000)
        .byte   px(%1111111),px(%1000000)
        .byte   px(%1111111),px(%0000000)
        .byte   px(%0001111),px(%0000000)
        .byte   px(%0001111),px(%0000000)
        .byte   px(%0000111),px(%1000000)
        .byte   px(%0000111),px(%1000000)
        .byte   1,1

watch_cursor:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0100001),px(%0010000)
        .byte   px(%0100110),px(%0011000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111100)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0000000),px(%0000000)
        .byte   5, 5

;;; ============================================================

.proc set_watch_cursor
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetCursor, watch_cursor
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

.proc set_pointer_cursor
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetCursor, pointer_cursor
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

;;; Disconnect /RAM
.proc disconnect_ramdisk
        ldx     DEVCNT
:       lda     DEVLST,x
        cmp     #$BF
        beq     loop
        dex
        bpl     :-
        rts

loop:   lda     DEVLST+1,x
        sta     DEVLST,x
        cpx     DEVCNT
        beq     L9904
        inx
        jmp     loop

L9904:  dec     DEVCNT
        rts
.endproc

;;; Restore /RAM
.proc reconnect_ramdisk
        inc     DEVCNT
        ldx     DEVCNT
        lda     #$BF
        sta     DEVLST,x
        rts
.endproc

;;; ============================================================

L9914:  lda     winfo::window_id
        jsr     L9A15
L991A:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::SetPenSize, setpensize_params

        MGTK_CALL MGTK::FrameRect, rect_frame
        MGTK_CALL MGTK::FrameRect, rect_ok_btn

        bit     desktop_available_flag
        bmi     :+
        MGTK_CALL MGTK::FrameRect, rect_desktop_btn
:
        addr_call L999B, $905B
        jsr     draw_ok_label
        bit     desktop_available_flag
        bmi     :+
        jsr     draw_desktop_label
:
        MGTK_CALL MGTK::MoveTo, pt1
        MGTK_CALL MGTK::LineTo, pt2
        MGTK_CALL MGTK::MoveTo, pt3
        MGTK_CALL MGTK::LineTo, pt4
        rts

;;; ============================================================

draw_ok_label:
        MGTK_CALL MGTK::MoveTo, pos_ok_label
        addr_call DrawString, str_ok_btn
        rts

draw_desktop_label:
        MGTK_CALL MGTK::MoveTo, pos_desktop_label
        addr_call DrawString, str_desktop_btn
        rts

;;; ============================================================
;;; Draw Pascal String
;;; Input: A,X = string address

        ASSERT_ADDRESS ::DrawString
.proc DrawString
        ptr := $06
        params := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     $08
        inc16   ptr
        MGTK_CALL MGTK::DrawText, params
        rts
.endproc

;;; ============================================================
;;; Draw Title String (centered at top of port)
;;; Input: A,X = string address

.proc L999B
        ptr := $06
        params := $06

        stax    ptr
        ldy     #$00
        lda     (ptr),y
        sta     $08
        inc16   ptr
        MGTK_CALL MGTK::TextWidth, params

        lsr16   $09
        lda     #1
        sta     tmp
        lda     #244
        lsr     tmp
        ror     a
        sec
        sbc     $09
        sta     pos_title_string
        lda     tmp
        sbc     $0A
        sta     pos_title_string+1

        MGTK_CALL MGTK::MoveTo, pos_title_string
        MGTK_CALL MGTK::DrawText, params
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

L99DC:  stx     $0B
        sta     $0A
        ldy     #$00
        lda     ($0A),y
        tay
        bne     L99E8
        rts

L99E8:  dey
        beq     L99ED
        bpl     L99EE
L99ED:  rts

L99EE:  lda     ($0A),y
        and     #CHAR_MASK
        cmp     #'/'
        beq     L99FA
        cmp     #'.'
        bne     L99FE
L99FA:  dey
        jmp     L99E8

L99FE:  iny
        lda     ($0A),y
        and     #CHAR_MASK
        cmp     #'A'
        bcc     L9A10
        cmp     #'Z'+1
        bcs     L9A10
        clc
        adc     #$20            ; to lower case
        sta     ($0A),y
L9A10:  dey
        jmp     L99E8

        .byte   0
L9A15:  sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport
        rts

;;; ============================================================
;;; Input: Entry number in A
;;; Output: Entry address in A,X

.proc get_selector_list_entry_addr
        ldx     #$00
        stx     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        asl     a
        rol     tmp
        clc
        adc     #$02
        tay
        lda     tmp
        adc     #>selector_list
        tax
        tya
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

.proc L9A47
        ldx     #$00
        stx     tmp
        lsr     a
        ror     tmp
        lsr     a
        ror     tmp
        pha
        lda     tmp
        adc     #$82
        tay
        pla
        adc     #$B4
        tax
        tya
        rts

tmp:    .byte   0
.endproc

;;; ============================================================

.proc L9A62
        pha
        lsr     a
        lsr     a
        lsr     a
        pha
        ldx     #0
        stx     tmp
        lsr     a
        ror     tmp
        tay
        lda     tmp
        clc
        adc     pt5::xcoord
        sta     pt6::xcoord
        tya
        adc     pt5::xcoord+1
        sta     pt6::xcoord+1
        pla
        asl     a
        asl     a
        asl     a
        sta     tmp
        pla
        sec
        sbc     tmp
        asl     a
        asl     a
        asl     a
        clc
        adc     pt5::ycoord
        sta     pt6::ycoord
        lda     #$00
        adc     pt5::ycoord+1
        sta     pt6::ycoord+1
        rts

tmp:    .byte   0
.endproc

;;; ============================================================
;;; Input: A = entry number

.proc draw_list_entry
        ptr := $06

        pha
        jsr     get_selector_list_entry_addr
        stax    ptr
        ldy     #$00
        lda     (ptr),y
        tay
L9AAF:  lda     (ptr),y
        sta     L9116,y
        dey
        bne     L9AAF
        ldy     #$00
        lda     (ptr),y
        clc
        adc     #$03
        sta     L9113
        pla
        pha
        cmp     #$08
        bcc     L9AD5
        lda     #$20
        sta     L9114
        sta     L9115
        sta     L9116
        jmp     L9AE5

L9AD5:  pla
        pha
        clc
        adc     #$31
        sta     L9114
        lda     #$20
        sta     L9115
        sta     L9116
L9AE5:  lda     winfo::window_id
        jsr     L9A15
        pla
        jsr     L9A62
        MGTK_CALL MGTK::MoveTo, pt6
        addr_call DrawString, $9113
        rts
.endproc

;;; ============================================================

L9AFD:  cmp     selected_entry
        beq     L9B05
        jmp     L9B22

L9B05:  bit     L9112
        bpl     L9B17
        jsr     L9C07
        jsr     BELL1
        jsr     BELL1
        jsr     BELL1
        rts

L9B17:  lda     #$FF
        sta     L9112
        lda     #$1E
        sta     L9110
        rts

L9B22:  pha
        lda     selected_entry
        bmi     L9B2E
        lda     selected_entry
        jsr     L9B42
L9B2E:  pla
        sta     selected_entry
        jsr     L9B42
        lda     #$FF
        sta     L9112
        lda     #$1E
        sta     L9110
        jmp     L9B17

L9B42:  pha
        lsr     a
        lsr     a
        lsr     a
        sta     L9BBC
        asl     a
        asl     a
        asl     a
        sta     L9BBA
        pla
        sec
        sbc     L9BBA
        sta     L9BBB
        lda     #$00
        sta     L9BBA
        lda     L9BBC
        lsr     a
        ror     L9BBA
        pha
        lda     L9BBA
        clc
        adc     rect2::x1
        sta     rect1::x1
        pla
        pha
        adc     rect2::x1+1
        sta     rect1::x1+1
        lda     L9BBA
        clc
        adc     rect2::x2
        sta     rect1::x2
        pla
        adc     rect2::x2+1
        sta     rect1::x2+1
        lda     L9BBB
        asl     a
        asl     a
        asl     a
        pha
        clc
        adc     rect2::y1
        sta     rect1::y1
        lda     #$00
        adc     rect2::y1+1
        sta     rect1::y1+1
        pla
        clc
        adc     rect2::y2
        sta     rect1::y2
        lda     #$00
        adc     rect2::y2+1
        sta     rect1::y2+1
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        rts

L9BBA:  .byte   0
L9BBB:  .byte   0
L9BBC:  .byte   0

;;; ============================================================

.proc cmd_startup
        ldy     menu_params::menu_item
        lda     slot_table,y
        ora     #$C0
        sta     @addr+1
        sta     ALTZPOFF
        lda     ROMIN2
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR
        sta     DHIRESOFF
        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80COL
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME

        @addr := * + 1
        jmp     $0000
.endproc

;;; ============================================================

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params3, INVOKER_PREFIX

L9C07:  lda     L9129
        bne     L9C17
        jsr     set_watch_cursor
        lda     selected_entry
        bmi     L9C17
        jsr     L9B42
L9C17:  jmp     L9C1D

L9C1A:  jmp     L9C7E

L9C1D:  lda     L9129
        bne     L9C32
        bit     BUTN0
        bpl     L9C2A
        jmp     L9C78

L9C2A:  jsr     get_copied_to_ramcard_flag
        bne     L9C32
        jmp     L9C78

L9C32:  lda     selected_entry
        jsr     get_selector_list_entry_addr
        stax    $06
        ldy     #$0F
        lda     ($06),y
        asl     a
        bmi     L9C78
        bcc     L9C65
        lda     L9129
        bne     L9C6F
        jsr     L9DFF
        beq     L9C6F
        jsr     load_overlay2
        lda     selected_entry
        jsr     LA000
        pha
        jsr     L9326
        pla
        beq     L9C6F
        jsr     set_pointer_cursor
        jmp     L9D44

L9C65:  lda     L9129
        bne     L9C6F
        jsr     L9DFF
        bne     L9C78
L9C6F:  lda     selected_entry
        jsr     L9F27
        jmp     L9C7E

L9C78:  lda     selected_entry
        jsr     L9A47
L9C7E:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9C87:  lda     ($06),y
        sta     INVOKER_PREFIX,y
        dey
        bpl     L9C87
        yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_params3
        beq     L9CB7
        tax
        lda     L9129
        bne     L9CB4
        txa
        pha
        jsr     ShowAlert
        tax
        pla
        cmp     #$45
        bne     L9CB4
        txa
        bne     L9CB4
        jsr     set_watch_cursor
        jmp     L9C78

L9CB4:  jmp     L9D44

L9CB7:  lda     get_file_info_params3::file_type
        cmp     #FT_BASIC
        bne     L9CC4
        jsr     L9D61
        jmp     L9CD8

L9CC4:  cmp     #FT_BINARY
        beq     L9CD8
        cmp     #FT_SYSTEM
        beq     L9CD8
        cmp     #FT_S16
        beq     L9CD8
        lda     #AlertID::selector_unable_to_run
        jsr     ShowAlert
        jmp     L9D44

L9CD8:  ldy     INVOKER_PREFIX
L9CDB:  lda     INVOKER_PREFIX,y
        cmp     #'/'
        beq     L9CEF
        dey
        bne     L9CDB
        lda     #AlertID::insert_source_disk
        jsr     ShowAlert
        bne     L9D44
        jmp     L9C1D

L9CEF:  dey
        tya
        pha
        iny
        ldx     #$00
L9CF5:  iny
        inx
        lda     INVOKER_PREFIX,y
        sta     INVOKER_FILENAME,x
        cpy     INVOKER_PREFIX
        bne     L9CF5
        stx     INVOKER_FILENAME
        pla
        sta     INVOKER_PREFIX
        addr_call L9DE4, INVOKER_PREFIX
        addr_call L9DE4, INVOKER_FILENAME
        jsr     reconnect_ramdisk
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        sta     DHIRESOFF
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR
        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80COL
        jsr     INVOKER
        jsr     disconnect_ramdisk
L9D44:  lda     L9129
        bne     L9D4E
        lda     #$FF
        sta     selected_entry
L9D4E:  rts

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params4, $1C00

L9D61:  ldx     INVOKER_PREFIX
:       lda     INVOKER_PREFIX,x
        cmp     #'/'
        beq     L9D71
        dex
        bne     :-
        jmp     L9DBA

L9D71:  dex
        stx     L9DD6
        stx     $1C00
L9D78:  lda     INVOKER_PREFIX,x
        sta     $1C00,x
        dex
        bne     L9D78
        inc     $1C00
        ldx     $1C00
        lda     #'/'
        sta     $1C00,x
L9D8C:  ldx     $1C00
        ldy     #$00
L9D91:  inx
        iny
        lda     L9DD7,y
        sta     $1C00,x
        cpy     L9DD7
        bne     L9D91
        stx     $1C00
        yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_params4
        bne     L9DAD
        rts

L9DAD:  ldx     L9DD6
L9DB0:  lda     $1C00,x
        cmp     #'/'
        beq     L9DC8
        dex
        bne     L9DB0
L9DBA:  lda     #AlertID::basic_system_not_found
        jsr     ShowAlert
        jsr     L9D44
        jsr     set_pointer_cursor
        pla
        pla
        rts

L9DC8:  cpx     #$01
        beq     L9DBA
        stx     $1C00
        dex
        stx     L9DD6
        jmp     L9D8C

L9DD6:  .byte   0
L9DD7:  .byte   $0C
        .byte   $42
        adc     (HIMEM,x)
        adc     #$63
        rol     $7973
        .byte   $73
        .byte   $74
        adc     $6D
L9DE4:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9DED:  lda     ($06),y
        cmp     #'a'
        bcc     L9DFB
        cmp     #'z'+1
        bcs     L9DFB
        and     #CASE_MASK
        sta     ($06),y
L9DFB:  dey
        bne     L9DED
        rts

L9DFF:  lda     selected_entry
        jsr     L9F27
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9E0E:  lda     ($06),y
        sta     INVOKER_PREFIX,y
        dey
        bpl     L9E0E
        yax_call MLI_WRAPPER, GET_FILE_INFO, get_file_info_params3
        rts

;;; ============================================================

.proc ok_btn_event_loop
        lda     #$00
        sta     L9E8D
L9E25:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #$02
        beq     L9E76
        lda     winfo::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect_ok_btn
        cmp     #MGTK::inrect_inside
        beq     L9E56
        lda     L9E8D
        beq     L9E5E
        jmp     L9E25

L9E56:  lda     L9E8D
        bne     L9E5E
        jmp     L9E25

L9E5E:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect_ok_btn
        lda     L9E8D
        clc
        adc     #$80
        sta     L9E8D
        jmp     L9E25

L9E76:  lda     L9E8D
        beq     L9E7E
        return  #$FF

L9E7E:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect_ok_btn
        return  #$00

L9E8D:  .byte   0
.endproc

;;; ============================================================

.proc desktop_btn_event_loop
        lda     #$00
        sta     L9EFB
L9E93:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #$02
        beq     L9EE4
        lda     winfo::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect_desktop_btn
        cmp     #MGTK::inrect_inside
        beq     L9EC4
        lda     L9EFB
        beq     L9ECC
        jmp     L9E93

L9EC4:  lda     L9EFB
        bne     L9ECC
        jmp     L9E93

L9ECC:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect_desktop_btn
        lda     L9EFB
        clc
        adc     #$80
        sta     L9EFB
        jmp     L9E93

L9EE4:  lda     L9EFB
        beq     L9EEC
        return  #$FF

L9EEC:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect_desktop_btn
        return  #$01

L9EFB:  .byte   0
.endproc

;;; ============================================================

;;; DESKTOP.SYSTEM flags/state

copied_to_ramcard_flag  := $D3FF
ramcard_prefix          := $D3EE

.proc get_copied_to_ramcard_flag
        lda     LCBANK2
        lda     LCBANK2
        lda     copied_to_ramcard_flag
        tax
        lda     ROMIN2
        txa
        rts
.endproc

.proc copy_ramcard_prefix
        stax    @addr
        lda     LCBANK2
        lda     LCBANK2
        ldx     ramcard_prefix
:       lda     ramcard_prefix,x
        @addr := * + 1
        sta     dummy1234,x
        dex
        bpl     :-
        lda     ROMIN2
        rts
.endproc

;;; ============================================================

L9F27:  sta     L9F72
        addr_call copy_ramcard_prefix, $0800
        lda     L9F72
        jsr     L9A47
        stax    $06
        ldy     #$00
        lda     ($06),y
        sta     L9F73
        tay
L9F43:  lda     ($06),y
        and     #CHAR_MASK
        cmp     #'/'
        beq     L9F4E
        dey
        bne     L9F43
L9F4E:  dey
L9F4F:  lda     ($06),y
        and     #CHAR_MASK
        cmp     #'/'
        beq     L9F5A
        dey
        bne     L9F4F
L9F5A:  dey
        ldx     $0800
L9F5E:  inx
        iny
        lda     ($06),y
        sta     $0800,x
        cpy     L9F73
        bne     L9F5E
        stx     $0800
        ldax    #$0800
        rts

L9F72:  .byte   0
L9F73:  .byte   0

;;; ============================================================
;;; Show Alert Message
;;; Inputs: A=AlertID

        ASSERT_ADDRESS ::ShowAlert
.proc ShowAlert
        pha
        jsr     BELL1
        pla
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        jsr     LD23E
        tax
        sta     ALTZPOFF
        sta     ROMIN2
        rts
.endproc

;;; ============================================================

.endscope

        .incbin "inc/mgtk.dat"

        ASSERT_ADDRESS $A000
