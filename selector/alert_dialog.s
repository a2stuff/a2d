;;; ============================================================
;;; Resources
;;; ============================================================

        .org $D000

.scope

alert_bitmap:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0000001),PX(%1110000),PX(%0000111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0000011),PX(%1100000),PX(%0000011),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000111),PX(%1100111),PX(%1111001),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0001111),PX(%1100111),PX(%1111001),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1111001),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1110011),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1100111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1001111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%0011111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111110),PX(%0111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111100),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111100),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111110),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%1111111),PX(%1111100),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111000),PX(%0000011),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)

.params alert_bitmap_params
viewloc:        DEFINE_POINT 20, 8
mapbits:        .addr   alert_bitmap
mapwidth:       .byte   7
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, 36, 23
.endparams

rect1:
        DEFINE_RECT 65,87,485,142

rect_frame1:
        DEFINE_RECT 4, 2, 416, 53
rect_frame2:
        DEFINE_RECT 5, 3, 415, 52

.params mapinfo
        DEFINE_POINT 65, 87, viewloc
        .addr   MGTK::screen_mapbits
        .byte   MGTK::screen_mapwidth
        .byte   $00
        DEFINE_RECT 0, 0, 420, 55, maprect
.endparams

str_cancel_btn:
        PASCAL_STRING "Cancel    Esc"
str_ok_btn:
        PASCAL_STRING {"OK            ", kGlyphReturn}
str_try_again_btn:
        PASCAL_STRING "Try Again  A"

rect_ok_try_again_btn:
        DEFINE_RECT 300, 37, 400, 48
pos_ok_try_again_btn:
        DEFINE_POINT 305, 47

rect_cancel_btn:
        DEFINE_RECT_SZ 20, 37, kButtonWidth, kButtonHeight
pos_cancel_btn:
        DEFINE_POINT 25,47

        DEFINE_POINT 190,16
pt2:    DEFINE_POINT 75,29


        PASCAL_STRING "System Error number XX"

LD142:  .byte   0
LD143:  .byte   0
LD144:  .byte   0

;;; ============================================================
;;; Alert Dialog

str_selector_unable_to_run:
        PASCAL_STRING "The Selector is unable to run the program."
str_io_error:
        PASCAL_STRING "I/O Error"
str_no_device:
        PASCAL_STRING "No device connected."
str_pathname_does_not_exist:
        PASCAL_STRING "Part of the pathname doesn't exist."
str_insert_source_disk:
        PASCAL_STRING "Please insert source disk."
str_file_not_found:
        PASCAL_STRING "The file cannot be found."
str_insert_system_disk:
        PASCAL_STRING "Please insert the system disk"
str_basic_system_not_found:
        PASCAL_STRING "BASIC.SYSTEM not found"

kNumErrorMessages = 8

num_error_messages:
        .byte   kNumErrorMessages

error_message_index_table:
        .byte   AlertID::selector_unable_to_run
        .byte   AlertID::io_error
        .byte   AlertID::no_device
        .byte   AlertID::pathname_does_not_exist
        .byte   AlertID::insert_source_disk
        .byte   AlertID::file_not_found
        .byte   AlertID::insert_system_disk
        .byte   AlertID::basic_system_not_found
        ASSERT_TABLE_SIZE error_message_index_table, kNumErrorMessages

error_message_table:
        .addr   str_selector_unable_to_run
        .addr   str_io_error
        .addr   str_no_device
        .addr   str_pathname_does_not_exist
        .addr   str_insert_source_disk
        .addr   str_file_not_found
        .addr   str_insert_system_disk
        .addr   str_basic_system_not_found
        ASSERT_ADDRESS_TABLE_SIZE error_message_table, kNumErrorMessages

alert_message_flag_table:
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $80
        .byte   $00
        .byte   $80
        .byte   $00
        ASSERT_TABLE_SIZE alert_message_flag_table, kNumErrorMessages


        ASSERT_ADDRESS $D23E
.proc ShowAlertImpl
        pha
        lda     selector5::L9129
        beq     :+
        pla
        return  #$01
:       jsr     selector5::set_pointer_cursor
        MGTK_CALL MGTK::InitPort, selector5::grafport2
        MGTK_CALL MGTK::SetPort, selector5::grafport2
        ldax    mapinfo::viewloc::xcoord
        jsr     LD725
        sty     LD764
        sta     LD767
        lda     mapinfo::viewloc::xcoord
        clc
        adc     mapinfo::maprect::x2
        pha
        lda     mapinfo::viewloc::xcoord+1
        adc     mapinfo::maprect::x2+1
        tax
        pla
        jsr     LD725
        sty     LD766
        sta     LD768
        lda     mapinfo::viewloc::ycoord
        sta     LD763
        clc
        adc     mapinfo::maprect::y2
        sta     LD765
        MGTK_CALL MGTK::HideCursor
        jsr     dialog_background_save
        MGTK_CALL MGTK::ShowCursor
        ldx     #.sizeof(MGTK::Point)-1
        lda     #0
:       sta     selector5::grafport2+MGTK::GrafPort::viewloc,x
        sta     selector5::grafport2+MGTK::GrafPort::maprect,x
        dex
        bpl     :-
        copy16  #550, selector5::grafport2 + MGTK::GrafPort::maprect + MGTK::Rect::x2
        copy16  #185, selector5::grafport2 + MGTK::GrafPort::maprect + MGTK::Rect::y2
        MGTK_CALL MGTK::SetPort, selector5::grafport2
        MGTK_CALL MGTK::SetPenMode, selector5::pencopy
        MGTK_CALL MGTK::PaintRect, rect1
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::FrameRect, rect1
        MGTK_CALL MGTK::SetPortBits, mapinfo
        MGTK_CALL MGTK::FrameRect, rect_frame1
        MGTK_CALL MGTK::FrameRect, rect_frame2
        MGTK_CALL MGTK::SetPenMode, selector5::pencopy
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::PaintBits, alert_bitmap_params
        MGTK_CALL MGTK::ShowCursor
        pla
        ldy     #$00
LD307:  cmp     error_message_index_table,y
        beq     LD314
        iny
        cpy     num_error_messages
        bne     LD307
        ldy     #$00
LD314:  tya
        asl     a
        tay
        lda     error_message_table,y
        sta     LD143
        lda     error_message_table+1,y
        sta     LD144
        tya
        lsr     a
        tay
        lda     alert_message_flag_table,y
        sta     LD142
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        bit     LD142
        bpl     LD365
        MGTK_CALL MGTK::FrameRect, rect_cancel_btn
        MGTK_CALL MGTK::MoveTo, pos_cancel_btn
        addr_call selector5::DrawString, str_cancel_btn
        bit     LD142
        bvs     LD365
        MGTK_CALL MGTK::FrameRect, rect_ok_try_again_btn
        MGTK_CALL MGTK::MoveTo, pos_ok_try_again_btn
        addr_call selector5::DrawString, str_try_again_btn
        jmp     LD378

LD365:  MGTK_CALL MGTK::FrameRect, rect_ok_try_again_btn
        MGTK_CALL MGTK::MoveTo, pos_ok_try_again_btn
        addr_call selector5::DrawString, str_ok_btn

LD378:  MGTK_CALL MGTK::MoveTo, pt2
        lda     LD143
        ldx     LD144
        jsr     selector5::DrawString


event_loop:
        MGTK_CALL MGTK::GetEvent, selector5::event_params
        lda     selector5::event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jmp     handle_button

:       cmp     #MGTK::EventKind::key_down
        bne     event_loop

        ;; Key Press

        lda     selector5::event_key
        and     #CHAR_MASK
        bit     LD142           ; Escape = Cancel?
        bpl     LD3DF
        cmp     #CHAR_ESCAPE
        bne     LD3BA
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect_cancel_btn
        lda     #$01
        jmp     LD434

LD3BA:  bit     LD142           ; A = Try Again?
        bvs     LD3DF
        cmp     #'a'
        bne     LD3D4
LD3C3:  MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect_ok_try_again_btn
        lda     #$00
        jmp     LD434

LD3D4:  cmp     #'A'
        beq     LD3C3
        cmp     #CHAR_RETURN
        beq     LD3C3
        jmp     event_loop

LD3DF:  cmp     #CHAR_RETURN    ; Return = OK?
        bne     LD3F4
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect_ok_try_again_btn
        lda     #$00
        jmp     LD434

LD3F4:  jmp     event_loop

        ;; Button Press

handle_button:
        jsr     map_alert_coords
        MGTK_CALL MGTK::MoveTo, selector5::event_coords

        bit     LD142           ; Cancel?
        bpl     LD424
        MGTK_CALL MGTK::InRect, rect_cancel_btn
        cmp     #MGTK::inrect_inside
        bne     LD412
        jmp     cancel_btn_event_loop

LD412:  bit     LD142           ; Try Again?
        bvs     LD424
        MGTK_CALL MGTK::InRect, rect_ok_try_again_btn
        cmp     #MGTK::inrect_inside
        bne     LD431
        jmp     try_again_btn_event_loop

LD424:  MGTK_CALL MGTK::InRect, rect_ok_try_again_btn
        cmp     #MGTK::inrect_inside ; OK?
        bne     LD431
        jmp     ok_button_event_loop

LD431:  jmp     event_loop

LD434:  pha
        MGTK_CALL MGTK::HideCursor
        jsr     dialog_background_restore
        MGTK_CALL MGTK::ShowCursor
        pla
        rts

        ;; --------------------------------------------------
        ;; Try Again Button Event Loop

.proc try_again_btn_event_loop
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect_ok_try_again_btn
        lda     #$00
        sta     LD4AC
LD457:  MGTK_CALL MGTK::GetEvent, selector5::event_params
        lda     selector5::event_kind
        cmp     #MGTK::EventKind::button_up
        beq     LD49F
        jsr     map_alert_coords
        MGTK_CALL MGTK::MoveTo, selector5::event_coords
        MGTK_CALL MGTK::InRect, rect_ok_try_again_btn
        cmp     #MGTK::inrect_inside
        beq     LD47F
        lda     LD4AC
        beq     LD487
        jmp     LD457

LD47F:  lda     LD4AC
        bne     LD487
        jmp     LD457

LD487:  MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect_ok_try_again_btn
        lda     LD4AC
        clc
        adc     #$80
        sta     LD4AC
        jmp     LD457

LD49F:  lda     LD4AC
        beq     LD4A7
        jmp     event_loop

LD4A7:  lda     #$00
        jmp     LD434

LD4AC:  .byte   0
.endproc

        ;; --------------------------------------------------
        ;; Cancel Button Event Loop

.proc cancel_btn_event_loop
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect_cancel_btn
        lda     #$00
        sta     LD513
LD4BE:  MGTK_CALL MGTK::GetEvent, selector5::event_params
        lda     selector5::event_kind
        cmp     #MGTK::EventKind::button_up
        beq     LD506
        jsr     map_alert_coords
        MGTK_CALL MGTK::MoveTo, selector5::event_coords
        MGTK_CALL MGTK::InRect, rect_cancel_btn
        cmp     #MGTK::inrect_inside
        beq     LD4E6
        lda     LD513
        beq     LD4EE
        jmp     LD4BE

LD4E6:  lda     LD513
        bne     LD4EE
        jmp     LD4BE

LD4EE:  MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect_cancel_btn
        lda     LD513
        clc
        adc     #$80
        sta     LD513
        jmp     LD4BE

LD506:  lda     LD513
        beq     LD50E
        jmp     event_loop

LD50E:  lda     #$01
        jmp     LD434

LD513:  .byte   0
.endproc

        ;; --------------------------------------------------
        ;; OK Button Event Loop

.proc ok_button_event_loop
        lda     #$00
        sta     LD57A
        MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect_ok_try_again_btn
LD525:  MGTK_CALL MGTK::GetEvent, selector5::event_params
        lda     selector5::event_kind
        cmp     #MGTK::EventKind::button_up
        beq     LD56D
        jsr     map_alert_coords
        MGTK_CALL MGTK::MoveTo, selector5::event_coords
        MGTK_CALL MGTK::InRect, rect_ok_try_again_btn
        cmp     #MGTK::inrect_inside
        beq     LD54D
        lda     LD57A
        beq     LD555
        jmp     LD525

LD54D:  lda     LD57A
        bne     LD555
        jmp     LD525

LD555:  MGTK_CALL MGTK::SetPenMode, selector5::penXOR
        MGTK_CALL MGTK::PaintRect, rect_ok_try_again_btn
        lda     LD57A
        clc
        adc     #$80
        sta     LD57A
        jmp     LD525

LD56D:  lda     LD57A
        beq     LD575
        jmp     event_loop

LD575:  lda     #$00
        jmp     LD434

LD57A:  .byte   0
.endproc

;;; ============================================================


.proc map_alert_coords
        sub16   selector5::event_xcoord, mapinfo::viewloc::xcoord, selector5::event_xcoord
        sub16   selector5::event_ycoord, mapinfo::viewloc::ycoord, selector5::event_ycoord
        rts
.endproc

;;; ============================================================

.scope dialog_background

        save_buffer := $800

.proc save
        copy16  #save_buffer, LD5D1
        lda     LD763
        jsr     LD6AA
        lda     LD765
        sec
        sbc     LD763
        tax
        inx
LD5BB:  lda     LD764
        sta     LD5F6
LD5C1:  lda     LD5F6
        lsr     a
        tay
        sta     LOWSCR
        bcs     LD5CE
        sta     HISCR
LD5CE:  lda     ($06),y
LD5D1           := * + 1
LD5D2           := * + 2
        sta     dummy1234
        inc16   LD5D1
        lda     LD5F6
        cmp     LD766
        bcs     LD5E8
        inc     LD5F6
        bne     LD5C1
LD5E8:  jsr     LD6EC
        dex
        bne     LD5BB
        lda     LD5D1
        ldx     LD5D2
        rts

        .byte   0
LD5F6:  .byte   0
.endproc

;;; ============================================================

.proc restore
        copy16  #save_buffer, LD656
        ldx     LD767
        ldy     LD768
        lda     #$FF
        cpx     #$00
        beq     LD612
LD60D:  clc
        rol     a
        dex
        bne     LD60D
LD612:  sta     LD6A6
        eor     #$FF
        sta     LD6A7
        lda     #$01
        cpy     #$00
        beq     LD625
LD620:  sec
        rol     a
        dey
        bne     LD620
LD625:  sta     LD6A8
        eor     #$FF
        sta     LD6A9
        lda     LD763
        jsr     LD6AA
        lda     LD765
        sec
        sbc     LD763
        tax
        inx
        lda     LD764
        sta     LD6A5
LD642:  lda     LD764
        sta     LD6A5
LD648:  lda     LD6A5
        lsr     a
        tay
        sta     LOWSCR
        bcs     LD655
        sta     HISCR
LD655:
LD656           := * + 1
        lda     save_buffer
        pha
        lda     LD6A5
        cmp     LD764
        beq     LD677
        cmp     LD766
        bne     LD685
        lda     ($06),y
        and     LD6A9
        sta     ($06),y
        pla
        and     LD6A8
        ora     ($06),y
        pha
        jmp     LD685

LD677:  lda     ($06),y
        and     LD6A7
        sta     ($06),y
        pla
        and     LD6A6
        ora     ($06),y
        pha
LD685:  pla
        sta     ($06),y
        inc16   LD656
        lda     LD6A5
        cmp     LD766
        bcs     LD69D
        inc     LD6A5
        bne     LD648
LD69D:  jsr     LD6EC
        dex
        bne     LD642
        rts

        .byte   0
LD6A5:  .byte   0
LD6A6:  .byte   0
LD6A7:  .byte   0
LD6A8:  .byte   0
LD6A9:  .byte   0
.endproc

;;; ============================================================

LD6AA:  sta     LD769
        and     #$07
        sta     LD74A
        lda     LD769
        and     #$38
        sta     LD749
        lda     LD769
        and     #$C0
        sta     LD748
        jsr     LD6C6
        rts

LD6C6:  lda     LD748
        lsr     a
        lsr     a
        ora     LD748
        pha
        lda     LD749
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     LD6EB
        pla
        ror     a
        sta     $06
        lda     LD74A
        asl     a
        asl     a
        ora     LD6EB
        ora     #$20
        sta     $07
        clc
        rts

LD6EB:  .byte   0

;;; ============================================================

LD6EC:  lda     LD74A
        cmp     #$07
        beq     LD6F9
        inc     LD74A
        jmp     LD6C6

LD6F9:  lda     #$00
        sta     LD74A
        lda     LD749
        cmp     #$38
        beq     LD70E
        clc
        adc     #$08
        sta     LD749
        jmp     LD6C6

LD70E:  lda     #$00
        sta     LD749
        lda     LD748
        clc
        adc     #$40
        sta     LD748
        cmp     #$C0
        beq     LD723
        jmp     LD6C6

LD723:  sec
        rts

.endscope
        dialog_background_save := dialog_background::save
        dialog_background_restore := dialog_background::restore



LD725:  ldy     #$00
        cpx     #$02
        bne     LD730
        ldy     #$49
        clc
        adc     #$01
LD730:  cpx     #$01
        bne     LD73E
        ldy     #$24
        clc
        adc     #$04
        bcc     LD73E
        iny
        sbc     #$07
LD73E:  cmp     #$07
        bcc     LD747
        sbc     #$07
        iny
        bne     LD73E
LD747:  rts

LD748:  .byte   0
LD749:  .byte   0
LD74A:  .byte   0
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0


LD763:  .byte   0
LD764:  .byte   0
LD765:  .byte   0
LD766:  .byte   0
LD767:  .byte   0
LD768:  .byte   0
LD769:  .byte   0

.endproc


;;; ============================================================

.endscope

        PAD_TO $D800
