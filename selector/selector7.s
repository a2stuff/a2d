;;; ============================================================
;;; Overlay #1 ???
;;; ============================================================

        .org $A000

.scope
        jmp     LA44A

        jmp     LA480

pencopy:        .byte   MGTK::pencopy
penOR:          .byte   MGTK::penOR
penXOR:         .byte   MGTK::penXOR
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy
notpenOR:       .byte   MGTK::notpenOR
notpenXOR:      .byte   MGTK::notpenXOR
notpenBIC:      .byte   MGTK::notpenBIC

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

activatectl_params := *
activatectl_which_ctl := activatectl_params + 0
activatectl_activate  := activatectl_params + 1

trackthumb_params := *
trackthumb_which_ctl := trackthumb_params + 0
trackthumb_mousex := trackthumb_params + 1
trackthumb_mousey := trackthumb_params + 3
trackthumb_thumbpos := trackthumb_params + 5
trackthumb_thumbmoved := trackthumb_params + 6
        .assert trackthumb_mousex = event_xcoord, error, "param mismatch"
        .assert trackthumb_mousey = event_ycoord, error, "param mismatch"

updatethumb_params := *
updatethumb_which_ctl := updatethumb_params
updatethumb_thumbpos := updatethumb_params + 1
updatethumb_stash := updatethumb_params + 5 ; not part of struct

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

findcontrol_params := * + 1   ; offset to x/y overlap event_params x/y
findcontrol_mousex := findcontrol_params + 0
findcontrol_mousey := findcontrol_params + 2
findcontrol_which_ctl := findcontrol_params + 4
findcontrol_which_part := findcontrol_params + 5
        .assert findcontrol_mousex = event_xcoord, error, "param mismatch"
        .assert findcontrol_mousey = event_ycoord, error, "param mismatch"

;;; UNION of preceding param blocks
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
LA013:  .byte   $00
        .byte   $00
LA015:
        .byte   $00
        .byte   $00
        .byte   $00

.params getwinport_params
window_id:     .byte   0
a_grafport:    .addr   grafport
.endparams

grafport:
        .tag    MGTK::GrafPort
grafport2:
        .tag    MGTK::GrafPort

double_click_counter_init:
        .byte   $FF

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

insertion_point_cursor:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%0001010),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0001010),px(%0000000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%1111011),px(%1100000)
        .byte   px(%0111111),px(%1000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0111111),px(%1000000)
        .byte   px(%1111011),px(%1100000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%0000000),px(%0000000)
        .byte   4, 5

;;; Text Input Field
LA0C8:  .res    68, 0
LA10C:  .res    68, 0
LA150:  .res    68, 0


.params winfo1
window_id:
        .byte   $3E
        .byte   $01, $00
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

        .byte   $96,$00
        .byte   $32
        .byte   $00
        .byte   $F4
        .byte   $01,$8C
        .byte   $00
        .byte   $19,$00,$14
        .byte   $00
        .byte   $00
        .byte   $20,$80,$00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $F4
        .byte   $01,$99

        .byte   0
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

        .byte   $01,$01
        .byte   $00
        .byte   $7F
        .byte   $00
        .byte   $88
        .byte   $00
        .byte   $00
.endparams


.params winfo2
window_id:
        .byte   $3F
        .byte   $01,$00
        .byte   $00
        .byte   $00
vscroll:
        .byte   $C1,$00
        .byte   $00
vthumbmax:
        .byte   $03
vthumbpos:
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $64
        .byte   $00
        .byte   $46,$00
        .byte   $64
        .byte   $00
        .byte   $46,$00
        .byte   $35,$00
        .byte   $32
        .byte   $00
        .byte   $00
        .byte   $20,$80,$00
x1:     .word   0
y1:     .word   0
x2:     .word   125
y2:     .word   70
pattern:.byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0

        .byte   $01,$01
        .byte   $00
        .byte   $7F
        .byte   $00
        .byte   $88
        .byte   $00
        .byte   $00
.endparams


        .byte   $00
        .byte   $00
LA20A:
        .byte   $14
        .byte   $00
LA20C:
        .byte   $00
LA20D:
        .byte   $00
        .byte   $00
LA20F:
LA210   := * + 1
        .byte   $01,$06
LA211:
        .byte   $00
        .byte   $00
        .byte   $00
LA214:
        .byte   $00
LA215:
        .byte   $00
        .byte   $00
LA218   := * + 1
        .byte   $01,$00
        .byte   $02
LA21C   := * + 2
        .byte   $20,$20,$00
LA21D:
        .byte   $00
        .byte   $0D,$00,$00
        .byte   $00
LA222:
        .byte   $00
LA223:
        .byte   $00
LA226   := * + 2
        .byte   $7D,$00,$00

LA227:  .byte   0


pos:    DEFINE_POINT 2, 0, pos



        .byte   0
        .byte   0

str_folder:
        PASCAL_STRING {$01, $02} ; kGlyphFolderLeft, kGlyphFolderRight

LA231:
        .byte   $00
        .byte   $00

rect_frame:
        DEFINE_RECT 4, 2, 496, 151

        .byte   $1B
        .byte   $00
        .byte   $10,$00
        .byte   $AE,$00,$1A
        .byte   $00

rect1:  DEFINE_RECT $C1, $3A, $125, $45
rect2:  DEFINE_RECT $C1, $59, $125, $64
rect3:  DEFINE_RECT $C1, $2C, $125, $37
rect4:  DEFINE_RECT $C1, $49, $125, $54
rect5:  DEFINE_RECT $C1, $1E, $125, $29

;;; Dividing line
pt1:    DEFINE_POINT 323, 30
pt2:    DEFINE_POINT 323, 100

pos_ok_btn:
        DEFINE_POINT 198,99
str_ok_btn:
        PASCAL_STRING {"OK            ",CHAR_RETURN}

pos_close_btn:
        DEFINE_POINT 198,68
str_close_btn:
        PASCAL_STRING "Close"

pos_open_btn:
        DEFINE_POINT 198, 54
str_open_btn:
        PASCAL_STRING "Open"

pos_cancel_btn:
        DEFINE_POINT 198, 83
str_cancel_btn:
        PASCAL_STRING "Cancel   Esc"

pos_change_drive_btn:
        DEFINE_POINT 198, 40
str_change_drive_btn:
        PASCAL_STRING "Change Drive"

        .byte   $1C
        .byte   $00
        .byte   $19,$00,$1C
        .byte   $00
        .byte   $70,$00

        .byte   $1C
        .byte   0
        .byte   $87
        .byte   0
        .byte   0
        .byte   $7F
str_disk:
        PASCAL_STRING " Disk: "

rect_input:
        DEFINE_RECT 28, 113, 428, 124

LA2DA:
LA2DB   := * + 1
LA2DC   := * + 2
        .byte   $1E,$00,$7B
        .byte   $00
        .byte   $1C
        .byte   $00
        .byte   $88
        .byte   $00
        .byte   $AC,$01,$93
        .byte   $00
        .byte   $1E,$00,$92
        .byte   $00
str_run_a_program:
        PASCAL_STRING "Run a Program ..."
str_file_to_run:
        PASCAL_STRING "File to run:"

LA309:  jsr     LAF46
        jsr     LA342
        jsr     LB051
        jsr     LB118
        jsr     LB309
        jsr     LB350
        jsr     LB22A
        jsr     LA32F
        jsr     LBB1D
        jsr     LB760
        lda     #$FF
        sta     LA20D
        jmp     LA480

LA32F:  lda     #$00
        sta     LA10C
        sta     LA50E
        copy16  #$0601, LA150
        rts

LA342:  lda     winfo1::window_id
        jsr     LB443
        addr_call LAFFE, $A2EA
        addr_call LB03F, $A2FC
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, rect_input
        MGTK_CALL MGTK::InitPort, grafport2
        MGTK_CALL MGTK::SetPort, grafport2
        rts

LA36F:  addr_call LB5F1, LA10C
        beq     LA379
        rts

LA379:  ldx     LA449
        txs
        ldy     #$0C
        ldx     #$A1
        sta     $07
        return  #$00

        .byte   0
LA387:  MGTK_CALL MGTK::CloseWindow, winfo2
        MGTK_CALL MGTK::CloseWindow, winfo1
        lda     #$00
        sta     LA20D
        jsr     LA8AE
        ldx     LA449
        txs
        return  #$FF

        .byte   $02
LA3A3:
        .byte   $00
        .byte   $B6,$A3
        .byte   $03
        .byte   $C7
        .byte   $A3
        .byte   $00
LA3AB := * + 1
        .byte   $10,$00
        .byte   $04
LA3AD:
        .byte   $00
        .byte   $00
        .byte   $14
        .byte   $00
        .byte   $02
        .byte   $00
        .byte   $00
LA3B5 := * + 1
        .byte   $01,$00

LA3B6:  .byte   0
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
LA3C6:  .byte   0
LA3C7:  .byte   0
LA3C8:  .byte   0
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
LA447:  .byte   0
LA448:  .byte   0
LA449:  .byte   0
LA44A:  tsx
        stx     LA449
        jsr     set_pointer_cursor
        lda     #$00
        sta     LA3C6
        sta     LA214
        sta     LA215
        sta     LA447
        sta     LA20C
        sta     LA211
        sta     LA8EC
        sta     LA47D
        sta     LA47F
        lda     #$28
        sta     LA20A
        lda     #$FF
        sta     LA231
        jmp     LA309

        .byte   0
        .byte   0
LA47D:  .byte   0
        .byte   0
LA47F:  .byte   0
LA480:  bit     LA20D
        bpl     LA492
        dec     LA20A
        bne     LA492
        jsr     LB70F
        lda     #$28
        sta     LA20A
LA492:  bit     LA214
        bpl     LA4A1
        dec     LA215
        bne     LA4A1
        lda     #$00
        sta     LA214
LA4A1:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #$01
        bne     LA4B4
        jsr     LA50F
        jmp     LA480

LA4B4:  cmp     #$03
        bne     LA4BB
        jsr     LAC1D
LA4BB:  MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     LA4C9
        jmp     LA480

LA4C9:  lda     findwindow_window_id
        cmp     winfo1::window_id
        beq     LA4D4
        jmp     LA480

LA4D4:  lda     winfo1::window_id
        jsr     LB443
        lda     winfo1::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect_input
        cmp     #MGTK::inrect_inside
        bne     LA4FC
        jsr     set_ip_cursor
        jmp     LA4FF

LA4FC:  jsr     LA8AE
LA4FF:  MGTK_CALL MGTK::InitPort, grafport2
        MGTK_CALL MGTK::SetPort, grafport2
        jmp     LA480

LA50E:  .byte   0
LA50F:  MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     LA51B
        rts

LA51B:  cmp     #$02
        bne     LA523
        jmp     LA524

        rts

LA523:  rts

LA524:  lda     findwindow_window_id
        cmp     winfo1::window_id
        beq     LA52F
        jmp     LA643

LA52F:  lda     winfo1::window_id
        jsr     LB443
        lda     winfo1::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect3
        cmp     #MGTK::inrect_inside
        beq     LA554
        jmp     LA587

LA554:  bit     LA47F
        bmi     LA55E
        lda     LA231
        bpl     LA561
LA55E:  jmp     LA632

LA561:  tax
        lda     $1780,x
        bmi     LA56A
LA567:  jmp     LA632

LA56A:  lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect3
        jsr     LAAD3
        bmi     LA567
        jsr     LA8ED
        jmp     LA632

LA587:  MGTK_CALL MGTK::InRect, rect5
        cmp     #MGTK::inrect_inside
        beq     LA594
        jmp     LA5B0

LA594:  bit     LA47F
        bmi     LA5AD
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect5
        jsr     LAB41
        bmi     LA5AD
        jsr     LA942
LA5AD:  jmp     LA632

LA5B0:  MGTK_CALL MGTK::InRect, rect1
        cmp     #MGTK::inrect_inside
        beq     LA5BD
        jmp     LA5D9

LA5BD:  bit     LA47F
        bmi     LA5D6
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        jsr     LABAF
        bmi     LA5D6
        jsr     LA965
LA5D6:  jmp     LA632

LA5D9:  MGTK_CALL MGTK::InRect, rect2
        cmp     #MGTK::inrect_inside
        beq     LA5E6
        jmp     LA600

LA5E6:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect2
        jsr     LA9F7
        bmi     LA5FD
        jsr     LBA5E
        jsr     LA36F
LA5FD:  jmp     LA632

LA600:  MGTK_CALL MGTK::InRect, rect4
        cmp     #MGTK::inrect_inside
        beq     LA60D
        jmp     LA624

LA60D:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect4
        jsr     LAA65
        bmi     LA621
        jsr     LA387
LA621:  jmp     LA632

LA624:  bit     LA47D
        bpl     LA62E
        jsr     LA63F
        bmi     LA632
LA62E:  jsr     LB799
        rts

LA632:  MGTK_CALL MGTK::InitPort, grafport2
        MGTK_CALL MGTK::SetPort, grafport
        rts

LA63F:  jsr     LAEA6
        rts

LA643:  bit     LA47F
        bmi     LA661
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_which_ctl
        beq     LA662
        cmp     #$01
        bne     LA661
        lda     winfo2::vscroll
        and     #$01
        beq     LA661
        jmp     LA77B

LA661:  rts

LA662:  lda     winfo2::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        add16   screentowindow_windowy, winfo2::y1, screentowindow_windowy
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
        lda     LA231
        cmp     screentowindow_windowy
        beq     LA69E
        jmp     LA73F

LA69E:  bit     LA214
        bmi     LA6AE
        lda     #$30
        sta     LA215
        lda     #$FF
        sta     LA214
        rts

LA6AE:  ldx     LA231
        lda     $1780,x
        bmi     LA6D4
        lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect2
        MGTK_CALL MGTK::PaintRect, rect2
        jsr     LA36F
        jmp     LA661

LA6D4:  and     #$7F
        pha
        lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect3
        MGTK_CALL MGTK::PaintRect, rect3
        lda     #$00
        sta     LA73E
        lda     #$00
        sta     $08
        lda     #$18
        sta     $09
        pla
        asl     a
        rol     LA73E
        asl     a
        rol     LA73E
        asl     a
        rol     LA73E
        asl     a
        rol     LA73E
        clc
        adc     $08
        sta     $08
        lda     LA73E
        adc     $09
        sta     $09
        ldx     $09
        lda     $08
        jsr     LB0D6
        jsr     LB118
        jsr     LB309
        lda     #$00
        jsr     LB3B7
        jsr     LB350
        jsr     LB22A
        MGTK_CALL MGTK::InitPort, grafport2
        MGTK_CALL MGTK::SetPort, grafport
        rts

LA73E:  .byte   0
LA73F:  lda     LA015
        cmp     $177F
        bcc     LA748
        rts

LA748:  lda     LA231
        bmi     LA756
        jsr     LBAC9
        lda     LA231
        jsr     LB404
LA756:  lda     LA015
        sta     LA231
        bit     LA211
        bpl     LA767
        jsr     LBB1D
        jsr     LB760
LA767:  lda     LA231
        jsr     LB404
        jsr     LBAD0
        lda     #$30
        sta     LA215
        lda     #$FF
        sta     LA214
        rts

LA77B:  lda     findcontrol_which_part
        cmp     #$01
        bne     LA785
        jmp     LA810

LA785:  cmp     #$02
        bne     LA78C
        jmp     LA836

LA78C:  cmp     #$03
        bne     LA793
        jmp     LA7C6

LA793:  cmp     #$04
        bne     LA79A
        jmp     LA7E8

LA79A:  lda     #$01
        sta     trackthumb_which_ctl
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_thumbmoved
        bne     LA7AB
        rts

LA7AB:  lda     trackthumb_thumbpos
        sta     updatethumb_thumbpos
        lda     #$01
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_stash
        jsr     LB3B7
        jsr     LB22A
        rts

LA7C6:  lda     winfo2::vthumbpos
        sec
        sbc     #$09
        bpl     :+
        lda     #$00
:       sta     updatethumb_thumbpos
        lda     #$01
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     LB3B7
        jsr     LB22A
        rts

LA7E8:  lda     winfo2::vthumbpos
        clc
        adc     #$09
        cmp     $177F
        beq     LA7F8
        bcc     LA7F8
        lda     $177F
LA7F8:  sta     updatethumb_thumbpos
        lda     #$01
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     LB3B7
        jsr     LB22A
        rts

LA810:  lda     winfo2::vthumbpos
        bne     LA816
        rts

LA816:  sec
        sbc     #$01
        sta     updatethumb_thumbpos
        lda     #$01
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     LB3B7
        jsr     LB22A
        jsr     LA85F
        jmp     LA810

LA836:  lda     winfo2::vthumbpos
        cmp     winfo2::vthumbmax
        bne     LA83F
        rts

LA83F:  clc
        adc     #$01
        sta     updatethumb_thumbpos
        lda     #$01
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     LB3B7
        jsr     LB22A
        jsr     LA85F
        jmp     LA836

LA85F:  MGTK_CALL MGTK::PeekEvent, event_params
        lda     event_kind
        cmp     #$01
        beq     LA873
        cmp     #$04
        beq     LA873
        pla
        pla
        rts

LA873:  MGTK_CALL MGTK::GetEvent, event_params
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_window_id
        cmp     winfo2::window_id
        beq     LA88A
        pla
        pla
        rts

LA88A:  lda     findwindow_which_area
        cmp     #$02
        beq     LA894
        pla
        pla
        rts

LA894:  MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_which_ctl
        cmp     #$01
        beq     LA8A4
        pla
        pla
        rts

LA8A4:  lda     findcontrol_which_part
        cmp     #$03
        bcc     LA8AD
        pla
        pla
LA8AD:  rts

LA8AE:  bit     LA8EC
        bpl     :+
        jsr     set_pointer_cursor
        lda     #$00
        sta     LA8EC
:       rts

set_pointer_cursor:
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetCursor, pointer_cursor
        MGTK_CALL MGTK::ShowCursor
        rts

set_ip_cursor:
        bit     LA8EC
        bmi     LA8EB
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetCursor, insertion_point_cursor
        MGTK_CALL MGTK::ShowCursor
        lda     #$80
        sta     LA8EC
LA8EB:  rts

LA8EC:  .byte   0
LA8ED:  ldx     LA231
        lda     $1780,x
        and     #$7F
        pha
        bit     LA211
        bpl     :+
        jsr     LBB1D
:       lda     #$00
        sta     LA941
        lda     #$00
        sta     $08
        lda     #$18
        sta     $09
        pla
        asl     a
        rol     LA941
        asl     a
        rol     LA941
        asl     a
        rol     LA941
        asl     a
        rol     LA941
        clc
        adc     $08
        sta     $08
        lda     LA941
        adc     $09
        sta     $09
        ldx     $09
        lda     $08
        jsr     LB0D6
        jsr     LB118
        jsr     LB309
        lda     #$00
        jsr     LB3B7
        jsr     LB350
        jsr     LB22A
        rts

LA941:  .byte   0
LA942:  lda     #$FF
        sta     LA231
        jsr     LB082
        jsr     LB051
        jsr     LB118
        jsr     LB309
        lda     #$00
        jsr     LB3B7
LA95A           := * + 2
        jsr     LB350
        jsr     LB22A
        jsr     LBB1D
        jsr     LB760
        rts

LA965:  lda     #$00
        sta     LA9C8
        ldx     LA3C7
        bne     LA972
        jmp     LA9C7

LA972:  lda     LA3C7,x
        and     #CHAR_MASK
        cmp     #'/'
        beq     LA981
        dex
        bpl     LA972
        jmp     LA9C7

LA981:  cpx     #$01
        bne     LA988
        jmp     LA9C7

LA988:  jsr     LB106
        lda     LA231
        pha
        lda     #$FF
        sta     LA231
        jsr     LB118
        jsr     LB309
        lda     #$00
        jsr     LB3B7
        jsr     LB350
        jsr     LB22A
        pla
        sta     LA231
        bit     LA9C8
        bmi     LA9BC
        jsr     LBAC9
        lda     LA231
        bmi     LA9C2
        jsr     LBAC9
        jmp     LA9C2

LA9BC:  jsr     LBB1D
        jsr     LB760
LA9C2:  lda     #$FF
        sta     LA231
LA9C7:  rts

LA9C8:  .byte   0
LA9C9:  MGTK_CALL MGTK::InitPort, grafport2
        ldx     #$03
        lda     #$00
:       sta     grafport2,x
        sta     grafport2++MGTK::GrafPort::maprect,x
        dex
        bpl     :-
        copy16  #$0226, grafport2+MGTK::GrafPort::maprect+MGTK::Rect::x2
        copy16  #$00B9, grafport2+MGTK::GrafPort::maprect+MGTK::Rect::y2
        MGTK_CALL MGTK::SetPort, grafport2
        rts

LA9F7:  lda     #$00
        sta     LAA64
LA9FC:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #$02
        beq     LAA4D
        lda     winfo1::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect2
        cmp     #MGTK::inrect_inside
        beq     LAA2D
        lda     LAA64
        beq     LAA35
        jmp     LA9FC

LAA2D:  lda     LAA64
        bne     LAA35
        jmp     LA9FC

LAA35:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect2
        lda     LAA64
        clc
        adc     #$80
        sta     LAA64
        jmp     LA9FC

LAA4D:  lda     LAA64
        beq     LAA55
        return  #$FF

LAA55:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect2
        return  #$00

LAA64:  .byte   0
LAA65:  lda     #$00
        sta     LAAD2
LAA6A:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #$02
        beq     LAABB
        lda     winfo1::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect4
        cmp     #MGTK::inrect_inside
        beq     LAA9B
        lda     LAAD2
        beq     LAAA3
        jmp     LAA6A

LAA9B:  lda     LAAD2
        bne     LAAA3
        jmp     LAA6A

LAAA3:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect4
        lda     LAAD2
        clc
        adc     #$80
        sta     LAAD2
        jmp     LAA6A

LAABB:  lda     LAAD2
        beq     LAAC3
        return  #$FF

LAAC3:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect4
        return  #$01

LAAD2:  .byte   0
LAAD3:  lda     #$00
        sta     LAB40
LAAD8:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #$02
        beq     LAB29
        lda     winfo1::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect3
        cmp     #MGTK::inrect_inside
        beq     LAB09
        lda     LAB40
        beq     LAB11
        jmp     LAAD8

LAB09:  lda     LAB40
        bne     LAB11
        jmp     LAAD8

LAB11:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect3
        lda     LAB40
        clc
        adc     #$80
        sta     LAB40
        jmp     LAAD8

LAB29:  lda     LAB40
        beq     LAB31
        return  #$FF

LAB31:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect3
        return  #$00

LAB40:  .byte   0
LAB41:  lda     #$00
        sta     LABAE
LAB46:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #$02
        beq     LAB97
        lda     winfo1::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect5
        cmp     #MGTK::inrect_inside
        beq     LAB77
        lda     LABAE
        beq     LAB7F
        jmp     LAB46

LAB77:  lda     LABAE
        bne     LAB7F
        jmp     LAB46

LAB7F:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect5
        lda     LABAE
        clc
        adc     #$80
        sta     LABAE
        jmp     LAB46

LAB97:  lda     LABAE
        beq     LAB9F
        return  #$FF

LAB9F:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect5
        return  #$01

LABAE:  .byte   0
LABAF:  lda     #$00
        sta     LAC1C
LABB4:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #$02
        beq     LAC05
        lda     winfo1::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect1
        cmp     #MGTK::inrect_inside
        beq     LABE5
        lda     LAC1C
        beq     LABED
        jmp     LABB4

LABE5:  lda     LAC1C
        bne     LABED
        jmp     LABB4

LABED:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        lda     LAC1C
        clc
        adc     #$80
        sta     LAC1C
        jmp     LABB4

LAC05:  lda     LAC1C
        beq     LAC0D
        return  #$FF

LAC0D:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        return  #$00

LAC1C:  .byte   0
LAC1D:  lda     event_modifiers
        beq     LAC5B
        lda     event_key
        and     #CHAR_MASK
        cmp     #CHAR_LEFT
        bne     LAC2E
        jmp     LBA1B

LAC2E:  cmp     #CHAR_RIGHT
        bne     LAC35
        jmp     LBA5E

LAC35:  bit     LA47F
        bmi     LAC48
        cmp     #CHAR_DOWN
        bne     LAC41
        jmp     LAE50

LAC41:  cmp     #CHAR_UP
        bne     LAC48
        jmp     LAE38

LAC48:  cmp     #'0'
        bcc     LAC53
        cmp     #'9'+1
        bcs     LAC53
        jmp     LAD65

LAC53:  bit     LA47F
        bmi     LACAA
        jmp     LADB2

LAC5B:  lda     event_key
        and     #CHAR_MASK
        cmp     #CHAR_LEFT
        bne     LAC67
        jmp     LB973

LAC67:  cmp     #CHAR_RIGHT
        bne     LAC6E
        jmp     LB9C9

LAC6E:  cmp     #CHAR_RETURN
        bne     LAC75
        jmp     LAD15

LAC75:  cmp     #CHAR_ESCAPE
        bne     LAC7C
        jmp     LAD42

LAC7C:  cmp     #CHAR_DELETE
        bne     LAC83
        jmp     LAD61

LAC83:  bit     LA47F
        bpl     LAC8B
        jmp     LAD0D

LAC8B:  cmp     #$09
        bne     LACAD
        lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect5
        MGTK_CALL MGTK::PaintRect, rect5
        jsr     LA942
LACAA:  jmp     LAD11

LACAD:  cmp     #$0F
        bne     LACDD
        lda     LA231
        bmi     LAD11
        tax
        lda     $1780,x
        bmi     LACBF
        jmp     LAD11

LACBF:  lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect3
        MGTK_CALL MGTK::PaintRect, rect3
        jsr     LA8ED
        jmp     LAD11

LACDD:  cmp     #$03
        bne     LACFF
        lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect1
        MGTK_CALL MGTK::PaintRect, rect1
        jsr     LA965
        jmp     LAD11

LACFF:  cmp     #$0A
        bne     LAD06
        jmp     LAD68

LAD06:  cmp     #$0B
        bne     LAD0D
        jmp     LAD8E

LAD0D:  jsr     LB8EC
        rts

LAD11:  jsr     LA9C9
        rts

LAD15:  lda     LA231
        bpl     LAD20
        bit     LA211
        bmi     LAD20
        rts

LAD20:  lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect2
        MGTK_CALL MGTK::PaintRect, rect2
        jsr     LBA5E
        jsr     LA36F
        jsr     LA9C9
        rts

LAD42:  lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect4
        MGTK_CALL MGTK::PaintRect, rect4
        jsr     LA387
        jsr     LA9C9
        rts

LAD61:  jsr     LB93B
        rts

LAD65:  jmp     LAEA6

LAD68:  lda     $177F
        beq     LAD79
        lda     LA231
        bmi     LAD89
        tax
        inx
        cpx     $177F
        bcc     LAD7A
LAD79:  rts

LAD7A:  jsr     LB404
        jsr     LBAC9
        inc     LA231
        lda     LA231
        jmp     LAE71

LAD89:  lda     #$00
        jmp     LAE71

LAD8E:  lda     $177F
        beq     LAD9A
        lda     LA231
        bmi     LADAA
        bne     LAD9B
LAD9A:  rts

LAD9B:  jsr     LB404
        jsr     LBAC9
        dec     LA231
        lda     LA231
        jmp     LAE71

LADAA:  ldx     $177F
        dex
        txa
        jmp     LAE71

LADB2:  cmp     #'A'
        bcs     LADB7
LADB6:  rts

LADB7:  cmp     #'Z'+1
        bcc     LADC5
        cmp     #'a'
        bcc     LADB6
        cmp     #'z'+1
        bcs     LADB6
        and     #$5F
LADC5:  jsr     LADDF
        bmi     LADB6
        cmp     LA231
        beq     LADB6
        pha
        lda     LA231
        bmi     LADDB
        jsr     LB404
        jsr     LBAC9
LADDB:  pla
        jmp     LAE71

LADDF:  sta     LAE37
        lda     #$00
        sta     LAE35
LADE7:  lda     LAE35
        cmp     $177F
        beq     LAE06
        jsr     LAE0D
        ldy     #$01
        lda     ($06),y
        cmp     LAE37
        bcc     LAE00
        beq     LAE09
        jmp     LAE06

LAE00:  inc     LAE35
        jmp     LADE7

LAE06:  return  #$FF

LAE09:  return  LAE35

LAE0D:  tax
        lda     $1780,x
        and     #$7F
        ldx     #$00
        stx     LAE36
        asl     a
        rol     LAE36
        asl     a
        rol     LAE36
        asl     a
        rol     LAE36
        asl     a
        rol     LAE36
        clc
        adc     #$00
        sta     $06
        lda     LAE36
        adc     #$18
        sta     $07
        rts

LAE35:  .byte   0
LAE36:  .byte   0
LAE37:  .byte   0
LAE38:  lda     $177F
        beq     LAE44
        lda     LA231
        bmi     LAE4B
        bne     LAE45
LAE44:  rts

LAE45:  jsr     LB404
        jsr     LBAC9
LAE4B:  lda     #$00
        jmp     LAE71

LAE50:  lda     $177F
        beq     LAE60
        ldx     LA231
        bmi     LAE69
        inx
        cpx     $177F
        bne     LAE61
LAE60:  rts

LAE61:  dex
        txa
        jsr     LB404
        jsr     LBAC9
LAE69:  ldx     $177F
        dex
        txa
        jmp     LAE71

LAE71:  sta     LA231
        jsr     LBAD0
        lda     LA231
        jsr     LB702
        jsr     LB30B
        jsr     LB22A
        copy16  #$2001, LA150
        jsr     LB760
        rts

LAE91:  sty     $AE9F
        stax    $AEA0
        php
        sei
        MLI_CALL $00, $0000
        plp
        and     #$FF
        rts

LAEA6:  rts

.proc detect_double_click

        ldx     #.sizeof(MGTK::Point)-1
:       copy    event_coords,x, xcoord,x
        dex
        bpl     :-
        lda     double_click_counter_init
        sta     counter
LAEB8:  dec     counter
        beq     LAEF5
        MGTK_CALL MGTK::PeekEvent, event_params
        jsr     check_delta
        bmi     LAEF5
        lda     #$FF
        sta     LAF45
        lda     event_kind      ; TODO: wrong ???
        sta     kind
        cmp     #$00
        beq     LAEB8
        cmp     #$04
        beq     LAEB8
        cmp     #$02
        bne     LAEE8
        MGTK_CALL MGTK::GetEvent, event_params
        jmp     LAEB8

LAEE8:  cmp     #$01
        bne     LAEF5
        MGTK_CALL MGTK::GetEvent, event_params
        return  #$00

LAEF5:  return  #$FF

check_delta:
        lda     event_xcoord
        sec
        sbc     xcoord
        sta     mouse_delta
        lda     event_xcoord+1
        sbc     xcoord+1
        bpl     LAF14
        lda     mouse_delta
        cmp     #$FB
        bcs     LAF1B
LAF11:  return  #$FF

LAF14:  lda     mouse_delta
        cmp     #$05
        bcs     LAF11
LAF1B:  lda     event_ycoord
        sec
        sbc     ycoord
        sta     mouse_delta
        lda     event_ycoord+1
        sbc     ycoord+1
        bpl     LAF34
        lda     mouse_delta
        cmp     #$FC
        bcs     LAF3B
LAF34:  lda     mouse_delta
        cmp     #$04
        bcs     LAF11
LAF3B:  return  #$00

counter:
        .byte   0
xcoord: .word   0
ycoord: .word   0

mouse_delta:
        .byte   0

kind:   .byte   0
LAF45:  .byte   0
.endproc

LAF46:  MGTK_CALL MGTK::OpenWindow, winfo1
        MGTK_CALL MGTK::OpenWindow, winfo2
        lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, rect_frame
        MGTK_CALL MGTK::FrameRect, rect2
        MGTK_CALL MGTK::FrameRect, rect3
        MGTK_CALL MGTK::FrameRect, rect1
        MGTK_CALL MGTK::FrameRect, rect4
        MGTK_CALL MGTK::FrameRect, rect5
        jsr     LAFA1
        jsr     LAFAF
        jsr     LAFBD
        jsr     LAFCB
        jsr     LAFD9
        MGTK_CALL MGTK::MoveTo, pt1
        MGTK_CALL MGTK::LineTo, pt2
        jsr     LA9C9
        rts

LAFA1:  MGTK_CALL MGTK::MoveTo, pos_ok_btn
        addr_call draw_string, str_ok_btn
        rts

LAFAF:  MGTK_CALL MGTK::MoveTo, pos_open_btn
        addr_call draw_string, str_open_btn
        rts

LAFBD:  MGTK_CALL MGTK::MoveTo, pos_close_btn
        addr_call draw_string, str_close_btn
        rts

LAFCB:  MGTK_CALL MGTK::MoveTo, pos_cancel_btn
        addr_call draw_string, str_cancel_btn
        rts

LAFD9:  MGTK_CALL MGTK::MoveTo, pos_change_drive_btn
        addr_call draw_string, str_change_drive_btn
        rts

draw_string:  stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
        MGTK_CALL MGTK::DrawText, $0006
        rts

LAFFE:  stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
        MGTK_CALL MGTK::TextWidth, $0006
        lsr16   $09
        lda     #$01
        sta     LB03E
        lda     #$F4
        lsr     LB03E
        ror     a
        sec
        sbc     $09
        sta     LA21C
        lda     LB03E
        sbc     $0A
        sta     LA21D
        MGTK_CALL MGTK::MoveTo, $A21C
        MGTK_CALL MGTK::DrawText, $0006
        rts

LB03E:  .byte   0
LB03F:  stax    $06
        MGTK_CALL MGTK::MoveTo, $A2C0
        lda     $06
        ldx     $07
        jsr     draw_string
        rts

LB051:  ldx     LA3C6
        lda     DEVLST,x
        and     #$F0
        sta     LA3A3
        yax_call LAE91, $C5, $A3A2
        lda     LA3B6
        and     #$0F
        sta     LA3B6
        bne     LB075
        jsr     LB082
        jmp     LB051

LB075:  lda     #$00
        sta     LA3C7
        addr_call LB0D6, $A3B6
        rts

LB082:  inc     LA3C6
        lda     LA3C6
        cmp     DEVCNT
        beq     LB094
        bcc     LB094
        lda     #$00
        sta     LA3C6
LB094:  rts

LB095:  lda     #$00
        sta     LB0D5
        yax_call LAE91, $C8, $A3A6
        beq     LB0B5
        jsr     LB051
        lda     #$FF
        sta     LA231
        lda     #$FF
        sta     LB0D5
        jmp     LB095

LB0B5:  lda     LA3AB
        sta     LA3AD
        sta     LA3B5
        yax_call LAE91, $CA, $A3AC
        beq     LB0D4
        jsr     LB051
        lda     #$FF
        sta     LA231
        jmp     LB095

LB0D4:  rts

LB0D5:  .byte   0
LB0D6:  stax    $06
        ldx     LA3C7
        lda     #'/'
        sta     LA3C8,x
        inc     LA3C7
        ldy     #$00
        lda     ($06),y
        tay
        clc
        adc     LA3C7
        pha
        tax
LB0F0:  lda     ($06),y
        sta     LA3C7,x
        dey
        dex
        cpx     LA3C7
        bne     LB0F0
        pla
        sta     LA3C7
        lda     #$FF
        sta     LA231
        rts

LB106:  ldx     LA3C7
        cpx     #$00
        beq     LB117
        dec     LA3C7
        lda     LA3C7,x
        cmp     #'/'
        bne     LB106
LB117:  rts

LB118:  jsr     LB095
        lda     #$00
        sta     LB224
        sta     LB225
        sta     LA448
        lda     #$01
        sta     LB226
        copy16  $1423, LB227
        lda     $1425
        and     #$7F
        sta     $177F
        bne     LB144
        jmp     LB1CF

LB144:  copy16  #$142B, $06
LB14C:  ldy     #$00
        lda     ($06),y
        and     #$0F
        bne     LB157
        jmp     LB1C4

LB157:  ldx     LB224
        txa
        sta     $1780,x
        ldy     #$00
        lda     ($06),y
        and     #$F0
        cmp     #$D0
        beq     LB173
        bit     LA447
        bpl     LB17E
        inc     LB225
        jmp     LB1C4

LB173:  lda     $1780,x
        ora     #$80
        sta     $1780,x
        inc     LA448
LB17E:  ldy     #$00
        lda     ($06),y
        and     #$0F
        sta     ($06),y
        copy16  #$1800, $08
        lda     #$00
        sta     LB229
        lda     LB224
        asl     a
        rol     LB229
        asl     a
        rol     LB229
        asl     a
        rol     LB229
        asl     a
        rol     LB229
        clc
        adc     $08
        sta     $08
        lda     LB229
        adc     $09
        sta     $09
        ldy     #$00
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     ($08),y
        dey
        bpl     :-
        inc     LB224
        inc     LB225
LB1C4:  inc     LB226
        lda     LB225
        cmp     $177F
        bne     LB1F2
LB1CF:  yax_call LAE91, $CC, $A3B4
        bit     LA447
        bpl     :+
        lda     LA448
        sta     $177F
:       jsr     LB453
        jsr     LB65E
        lda     LB0D5
        bpl     LB1F0
        sec
        rts

LB1F0:  clc
        rts

LB1F2:  lda     LB226
        cmp     LB228
        beq     LB20B
        lda     $06
        clc
        adc     LB227
        sta     $06
        lda     $07
        adc     #$00
        sta     $07
        jmp     LB14C

LB20B:  yax_call LAE91, $CA, $A3AC
        copy16  #$1404, $06
        lda     #$00
        sta     LB226
        jmp     LB14C

LB224:  .byte   0
LB225:  .byte   0
LB226:  .byte   0
LB227:  .byte   0
LB228:  .byte   0
LB229:  .byte   0



LB22A:  jsr     LA9C9
        lda     winfo2::window_id
        jsr     LB443
        MGTK_CALL MGTK::PaintRect, $A1EA
        lda     #16
        sta     pos::xcoord
        lda     #8
        sta     pos::ycoord
        lda     #0
        sta     pos::ycoord+1
        sta     LB2D0
LB24B:  lda     LB2D0
        cmp     $177F
        bne     LB257
        jsr     LA9C9
        rts

LB257:  MGTK_CALL MGTK::MoveTo, pos
        ldx     LB2D0
        lda     $1780,x
        and     #$7F
        ldx     #$00
        stx     LB2CF
        asl     a
        rol     LB2CF
        asl     a
        rol     LB2CF
        asl     a
        rol     LB2CF
        asl     a
        rol     LB2CF
        clc
        adc     #$00
        tay
        lda     LB2CF
        adc     #$18
        tax
        tya
        jsr     draw_string
        ldx     LB2D0
        lda     $1780,x
        bpl     LB2A7
        lda     #$01
        sta     pos
        MGTK_CALL MGTK::MoveTo, pos
        addr_call draw_string, str_folder
        lda     #$10
        sta     pos
LB2A7:  lda     LB2D0
        cmp     LA231
        bne     LB2B8
        jsr     LB404
        lda     winfo2::window_id
        jsr     LB443
LB2B8:  inc     LB2D0
        add16   pos::ycoord, #8, pos::ycoord
        jmp     LB24B

LB2CF:  .byte   0
LB2D0:  .byte   0
LB2D1:  stx     $0B
        sta     $0A
        ldy     #$00
        lda     ($0A),y
        tay
        bne     LB2DD
        rts

LB2DD:  dey
        beq     LB2E2
        bpl     LB2E3
LB2E2:  rts

LB2E3:  lda     ($0A),y
        and     #$7F
        cmp     #'/'
        beq     LB2EF
        cmp     #$2E
        bne     LB2F3
LB2EF:  dey
        jmp     LB2DD

LB2F3:  iny
        lda     ($0A),y
        and     #$7F
        cmp     #'A'
        bcc     LB305
        cmp     #'Z'+1
        bcs     LB305
        clc
        adc     #$20            ; to lower case
        sta     ($0A),y
LB305:  dey
        jmp     LB2DD

LB309:  lda     #$00
LB30B:  sta     LB34F
        lda     $177F
        cmp     #$0A
        bcs     LB326
        copy    #$01, activatectl_which_ctl
        copy    #$00, activatectl_activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts

LB326:  lda     $177F
        sta     winfo2::vthumbmax
        lda     #$01
        sta     activatectl_which_ctl
        sta     activatectl_activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        lda     LB34F
        sta     updatethumb_thumbpos
        jsr     LB3B7
        lda     #$01
        sta     updatethumb_which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        rts

LB34F:  .byte   0
LB350:  lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::PaintRect, $A23B
        MGTK_CALL MGTK::SetPenMode, penXOR
        copy16  #$A3C7, $06
        ldy     #$00
        lda     ($06),y
        sta     LB3B6
        iny
LB372:  iny
        lda     ($06),y
        cmp     #'/'
        beq     LB380
        cpy     LB3B6
        bne     LB372
        beq     LB384
LB380:  dey
        sty     LB3B6
LB384:  ldy     #$00
        ldx     #$00
LB388:  inx
        iny
        lda     ($06),y
        sta     $0220,x
        cpy     LB3B6
        bne     LB388
        stx     $0220
        addr_call LB2D1, $0220
        MGTK_CALL MGTK::MoveTo, $A2BC
        addr_call draw_string, str_disk
        addr_call draw_string, $0220
        jsr     LA9C9
        rts

LB3B6:  .byte   0
LB3B7:  sta     LB403
        clc
        adc     #$09
        cmp     $177F
        beq     LB3C4
        bcs     LB3CA
LB3C4:  lda     LB403
        jmp     LB3DA

LB3CA:  lda     $177F
        cmp     #$0A
        bcs     LB3D7
        lda     LB403
        jmp     LB3DA

LB3D7:  sec
        sbc     #$09
LB3DA:  ldx     #$00
        stx     LB403
        asl     a
        rol     LB403
        asl     a
        rol     LB403
        asl     a
        rol     LB403
        sta     winfo2::y1
        ldx     LB403
        stx     winfo2::y1+1
        clc
        adc     #$46
        sta     winfo2::y2
        lda     LB403
        adc     #$00
        sta     winfo2::y2+1
        rts

LB403:  .byte   0
LB404:  ldx     #$00
        stx     LB442
        asl     a
        rol     LB442
        asl     a
        rol     LB442
        asl     a
        rol     LB442
        sta     LA222
        ldx     LB442
        stx     LA223
        clc
        adc     #$07
        sta     LA226
        lda     LB442
        adc     #$00
        sta     LA227
        lda     winfo2::window_id
        jsr     LB443
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, $A220
        jsr     LA9C9
        rts

LB442:  .byte   0
LB443:  sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport
        rts

LB453:  lda     #$5A
        ldx     #$0F
:       sta     LB537,x
        dex
        bpl     :-
        lda     #$00
        sta     LB534
        sta     LB533
LB465:  lda     LB534
        cmp     $177F
        bne     LB470
        jmp     LB4EC

LB470:  lda     LB533
        jsr     LB5C6
        ldy     #$00
        lda     ($06),y
        bmi     LB4B2
        and     #$0F
        sta     LB536
        ldy     #$01
LB483:  lda     ($06),y
        cmp     LB536,y
        beq     LB48F
        bcs     LB4B2
        jmp     LB497

LB48F:  iny
        cpy     #$10
        bne     LB483
        jmp     LB4B2

LB497:  lda     LB533
        sta     LB535
        ldx     #$0F
        lda     #$20
:       sta     LB537,x
        dex
        bpl     :-
        ldy     LB536
LB4AA:  lda     ($06),y
        sta     LB536,y
        dey
        bne     LB4AA
LB4B2:  inc     LB533
        lda     LB533
        cmp     $177F
        beq     LB4C0
        jmp     LB470

LB4C0:  lda     LB535
        jsr     LB5C6
        ldy     #$00
        lda     ($06),y
        ora     #$80
        sta     ($06),y
        ldax    #$0F5A
:       sta     LB537,x
        dex
        bpl     :-
        ldx     LB534
        lda     LB535
        sta     LB547,x
        lda     #$00
        sta     LB533
        inc     LB534
        jmp     LB465

LB4EC:  ldx     $177F
        dex
        stx     LB534
LB4F3:  lda     LB534
        bpl     LB522
        ldx     $177F
        beq     LB521
        dex
LB4FE:  lda     LB547,x
        tay
        lda     $1780,y
        bpl     LB50F
        lda     LB547,x
        ora     #$80
        sta     LB547,x
LB50F:  dex
        bpl     LB4FE
        ldx     $177F
        beq     LB521
        dex
:       lda     LB547,x
        sta     $1780,x
        dex
        bpl     :-
LB521:  rts

LB522:  jsr     LB5C6
        ldy     #$00
        lda     ($06),y
        and     #$7F
        sta     ($06),y
        dec     LB534
        jmp     LB4F3

LB533:  .byte   0
LB534:  .byte   0
LB535:  .byte   0
LB536:  .byte   0
LB537:  .byte   0
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
LB547:  .byte   0
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
LB5C6:  ldx     #$00
        stx     $06
        ldx     #$18
        stx     $07
        ldx     #$00
        stx     LB5F0
        asl     a
        rol     LB5F0
        asl     a
        rol     LB5F0
        asl     a
        rol     LB5F0
        asl     a
        rol     LB5F0
        clc
        adc     $06
        sta     $06
        lda     LB5F0
        adc     $07
        sta     $07
        rts

LB5F0:  .byte   0
LB5F1:  stax    $06
        ldy     #$01
        lda     ($06),y
        cmp     #'/'
        bne     LB65A
        dey
        lda     ($06),y
        cmp     #$02
        bcc     LB65A
        tay
        lda     ($06),y
        cmp     #'/'
        beq     LB65A
        ldx     #$00
        stx     LB65D
LB610:  lda     ($06),y
        cmp     #'/'
        beq     LB620
        inx
        cpx     #$10
        beq     LB65A
        dey
        bne     LB610
        beq     LB628
LB620:  inc     LB65D
        ldx     #$00
        dey
        bne     LB610
LB628:  lda     LB65D
        cmp     #$02
        bcc     LB65A
        ldy     #$00
        lda     ($06),y
        tay
LB634:  lda     ($06),y
        and     #$7F
        cmp     #'.'
        beq     LB654
        cmp     #'/'
        bcc     LB65A
        cmp     #'9'+1
        bcc     LB654
        cmp     #'A'
        bcc     LB65A
        cmp     #'Z'+1
        bcc     LB654
        cmp     #'a'
        bcc     LB65A
        cmp     #'z'+1
        bcs     LB65A
LB654:  dey
        bne     LB634
        return  #$00

LB65A:  return  #$FF

LB65D:  .byte   0
LB65E:  lda     $177F
        bne     LB664
LB663:  rts

LB664:  lda     #$00
        sta     LB691
        lda     #$00
        sta     $06
        lda     #$18
        sta     $07
LB671:  lda     LB691
        cmp     $177F
        beq     LB663
        lda     $06
        ldx     $07
        jsr     LB2D1
        inc     LB691
        lda     $06
        clc
        adc     #$10
        sta     $06
        bcc     LB671
        inc     $07
        jmp     LB671

LB691:  .byte   0
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     LB6F2,y
        dey
        bpl     :-
        lda     #$00
        sta     LB6F1
        lda     #$00
        sta     $06
        lda     #$18
        sta     $07
LB6B0:  lda     LB6F1
        cmp     $177F
        beq     LB6E0
        ldy     #$00
        lda     ($06),y
        cmp     LB6F2
        bne     LB6CF
        tay
LB6C2:  lda     ($06),y
        cmp     LB6F2,y
        bne     LB6CF
        dey
        bne     LB6C2
        jmp     LB6E3

LB6CF:  inc     LB6F1
        lda     $06
        clc
        adc     #$10
        sta     $06
        bcc     LB6B0
        inc     $07
        jmp     LB6B0

LB6E0:  return  #$FF

LB6E3:  ldx     $177F
        lda     LB6F1
LB6E9:  dex
        cmp     $1780,x
        bne     LB6E9
        txa
        rts

LB6F1:  .byte   0
LB6F2:  .byte   0
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
LB702:  bpl     LB707
LB704:  return  #$00

LB707:  cmp     #$09
        bcc     LB704
        sec
        sbc     #$08
        rts

LB70F:  lda     winfo1::window_id
        jsr     LB443
        jsr     LBB31
        stax    $06
        copy16  LA2DC, $08
        MGTK_CALL MGTK::MoveTo, $0006
        bit     LA20C
        bpl     LB73E
        MGTK_CALL MGTK::SetTextBG, $A2C8
        lda     #$00
        sta     LA20C
        beq     LB749
LB73E:  MGTK_CALL MGTK::SetTextBG, $A2C9
        lda     #$FF
        sta     LA20C
LB749:  copy16  #$A210, $06
        lda     LA20F
        sta     $08
        MGTK_CALL MGTK::DrawText, $0006
        jsr     LA9C9
        rts

LB760:  lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::PaintRect, rect_input
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, rect_input
        MGTK_CALL MGTK::MoveTo, $A2DA
        lda     LA10C
        beq     LB78A
        addr_call draw_string, LA10C
LB78A:  addr_call draw_string, $A150
        addr_call draw_string, $A219
        rts

LB799:  lda     winfo1::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, rect_input
        cmp     #MGTK::inrect_inside
        beq     LB7BC
        rts

LB7BC:  jsr     LBB31
        stax    $06
        cmp16   LA013, $06
        bcs     LB7D2
        jmp     LB864

LB7D2:  jsr     LBB31
        stax    LB8EA
        ldx     LA150
        inx
        lda     #$20
        sta     LA150,x
        inc     LA150
        copy16  #$A150, $06
        lda     LA150
        sta     $08
LB7F4:  MGTK_CALL MGTK::TextWidth, $0006
        add16   $09, LB8EA, $09
        cmp16   $09, LA013
        bcc     LB823
        dec     $08
        lda     $08
        cmp     #$01
        bne     LB7F4
        dec     LA150
        jmp     LB8E3

LB823:  lda     $08
        cmp     LA150
        bcc     LB830
        dec     LA150
        jmp     LBA5E

LB830:  ldx     #$02
        ldy     LA10C
        iny
LB836:  lda     LA150,x
        sta     LA10C,y
        cpx     $08
        beq     LB845
        iny
        inx
        jmp     LB836

LB845:  sty     LA10C
        ldy     #$02
        ldx     $08
        inx
LB84D:  lda     LA150,x
        sta     LA150,y
        cpx     LA150
        beq     LB85D
        iny
        inx
LB85A:  jmp     LB84D

LB85D:  dey
        sty     LA150
        jmp     LB8E3

LB864:  copy16  #LA10C, $06
        lda     LA10C
        sta     $08
LB871:  MGTK_CALL MGTK::TextWidth, $0006
        add16   $09, LA2DA, $09
        cmp16   $09, LA013
        bcc     LB89D
        dec     $08
        lda     $08
        cmp     #$01
        bcs     LB871
        jmp     LBA1B

LB89D:  inc     $08
        ldy     #$00
        ldx     $08
LB8A3:  cpx     LA10C
        beq     LB8B3
        inx
        iny
        lda     LA10C,x
        sta     LA0C8+1,y
        jmp     LB8A3

LB8B3:  iny
        sty     LA0C8
        ldx     #$01
        ldy     LA0C8
LB8BC:  cpx     LA150
        beq     LB8CC
        inx
        iny
        lda     LA150,x
        sta     LA0C8,y
        jmp     LB8BC

LB8CC:  sty     LA0C8
        lda     LA210
        sta     LA0C8+1
:       lda     LA0C8,y
        sta     LA150,y
        dey
        bpl     :-
        lda     $08
        sta     LA10C
LB8E3:  jsr     LB760
        jsr     LBB5B
        rts

LB8EA:  .word   0
LB8EC:  sta     LB8FB
        lda     LA10C
        clc
        adc     LA150
        cmp     #$41
        bcc     LB8FC
        rts

LB8FB:  .byte   0
LB8FC:  lda     LB8FB
        ldx     LA10C
        inx
        sta     LA10C,x
        sta     LA218
        jsr     LBB31
        inc     LA10C
        stax    $06
        copy16  LA2DC, $08
        lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::MoveTo, $0006
        addr_call draw_string, $A217
        addr_call draw_string, $A150
        jsr     LBB5B
        rts

LB93B:  lda     LA10C
        bne     LB941
        rts

LB941:  dec     LA10C
        jsr     LBB31
        stax    $06
        copy16  LA2DC, $08
        lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::MoveTo, $0006
        addr_call draw_string, $A150
        addr_call draw_string, $A219
        jsr     LBB5B
        rts

LB973:  lda     LA10C
        bne     LB979
        rts

LB979:  ldx     LA150
        cpx     #$01
        beq     LB98B
LB980:  lda     LA150,x
        sta     LA150+1,x
        dex
        cpx     #$01
        bne     LB980
LB98B:  ldx     LA10C
        lda     LA10C,x
        sta     LA150+2
        dec     LA10C
        inc     LA150
        jsr     LBB31
        stax    $06
        copy16  LA2DC, $08
        lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::MoveTo, $0006
        addr_call draw_string, $A150
        addr_call draw_string, $A219
        jsr     LBB5B
        rts

LB9C9:  lda     LA150
        cmp     #$02
        bcs     LB9D1
        rts

LB9D1:  ldx     LA10C
        inx
        lda     LA150+2
        sta     LA10C,x
        inc     LA10C
        ldx     LA150
        cpx     #$03
        bcc     LB9F3
        ldx     #$02
LB9E7:  lda     LA150+1,x
        sta     LA150,x
        inx
        cpx     LA150
        bne     LB9E7
LB9F3:  dec     LA150
        lda     winfo1::window_id
        jsr     LB443
        MGTK_CALL MGTK::MoveTo, $A2DA
        addr_call draw_string, LA10C
        addr_call draw_string, $A150
        addr_call draw_string, $A219
        jsr     LBB5B
        rts

LBA1B:  lda     LA10C
        bne     LBA21
        rts

LBA21:  ldy     LA10C
        lda     LA150
        cmp     #$02
        bcc     LBA3A
        ldx     #$01
LBA2D:  iny
        inx
        lda     LA150,x
        sta     LA10C,y
        cpx     LA150
        bne     LBA2D
LBA3A:  sty     LA10C
LBA3D:  lda     LA10C,y
        sta     LA150+1,y
        dey
        bne     LBA3D
        ldx     LA10C
        inx
        stx     LA150
        lda     #$06
        sta     LA150+1
        lda     #$00
        sta     LA10C
        jsr     LB760
        jsr     LBB5B
        rts

LBA5E:  lda     LA150
        cmp     #$02
        bcs     LBA66
        rts

LBA66:  ldx     #$01
        ldy     LA10C
LBA6B:  inx
        iny
        lda     LA150,x
        sta     LA10C,y
        cpx     LA150
        bne     LBA6B
        sty     LA10C
        copy16  #$0601, LA150
        jsr     LB760
        jsr     LBB5B
        rts

LBA8C:  stax    $06
        ldx     LA10C
        lda     #'/'
        sta     LA10C+1,x
        inc     LA10C
        ldy     #$00
        lda     ($06),y
        tay
        clc
        adc     LA10C
        pha
        tax
LBAA6:  lda     ($06),y
        sta     LA10C,x
        dey
        dex
        cpx     LA10C
        bne     LBAA6
        pla
        sta     LA10C
        rts

LBAB7:  ldx     LA10C
        cpx     #$00
        beq     LBAC8
        dec     LA10C
        lda     LA10C,x
        cmp     #'/'
        bne     LBAB7
LBAC8:  rts

LBAC9:  jsr     LBAB7
        jsr     LB760
        rts

LBAD0:  copy16  #$1800, $06
        ldx     LA231
        lda     $1780,x
        and     #$7F
        ldx     #$00
        stx     LBB07
        asl     a
        rol     LBB07
        asl     a
        rol     LBB07
        asl     a
        rol     LBB07
        asl     a
        rol     LBB07
        clc
        adc     $06
        tay
        lda     LBB07
        adc     $07
        tax
        tya
        jsr     LBA8C
        jsr     LB760
        rts

LBB07:  .byte   0
        .byte   0
        ldx     LA3C7
:       lda     LA3C7,x
        sta     LA10C,x
        dex
        bpl     :-
        addr_call LB2D1, LA10C
        rts

LBB1D:  ldx     LA3C7
:       lda     LA3C7,x
        sta     LA10C,x
        dex
        bpl     :-
        addr_call LB2D1, LA10C
        rts

LBB31:  lda     #$00
        sta     $09
        sta     $0A
        lda     LA10C
        beq     LBB4C
        sta     $08
        copy16  #LA10C+1, $06
        MGTK_CALL MGTK::TextWidth, $0006
LBB4C:  lda     $09
        clc
        adc     LA2DA
        tay
        lda     $0A
        adc     LA2DB
        tax
        tya
        rts

LBB5B:  ldx     LA10C
:       lda     LA10C,x
        sta     LA0C8,x
        dex
        bpl     :-
        lda     LA231
        sta     LBBE2
        bmi     LBBA0
        ldx     #$00
        stx     $06
        ldx     #$18
        stx     $07
        ldx     #$00
        stx     LBBE1
        tax
        lda     $1780,x
        and     #$7F
        asl     a
        rol     LBBE1
        asl     a
        rol     LBBE1
        asl     a
        rol     LBBE1
        asl     a
        rol     LBBE1
        clc
        adc     $06
        tay
        lda     LBBE1
        adc     $07
        tax
        tya
        jsr     LB0D6
LBBA0:  addr_call LB2D1, $A0C8
        addr_call LB2D1, $A3C7
        lda     LA0C8
        cmp     LA3C7
        bne     LBBCB
        tax
LBBB7:  lda     LA0C8,x
        cmp     LA3C7,x
        bne     LBBCB
        dex
        bne     LBBB7
        lda     #$00
        sta     LA211
        jsr     LBBD4
        rts

LBBCB:  lda     #$FF
        sta     LA211
        jsr     LBBD4
        rts

LBBD4:  lda     LBBE2
        sta     LA231
        bpl     LBBDD
        rts

LBBDD:  jsr     LB106
        rts

LBBE1:  .byte   0
LBBE2:  .byte   0


.endscope

        ;; Random chunk of MGTK padding out the file
        .incbin "inc/junk3.dat"

        ASSERT_ADDRESS $BF00
