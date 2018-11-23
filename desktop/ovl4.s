;;; ============================================================
;;; Overlay for Common Routines (Selector, File Copy/Delete)
;;; ============================================================

.proc common_overlay
        .org $5000

;;; ============================================================

L5000:  jmp     L50B1

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer
        DEFINE_OPEN_PARAMS open_params, path_buf, $1000
        DEFINE_READ_PARAMS read_params, $1400, $200
        DEFINE_CLOSE_PARAMS close_params

on_line_buffer: .res    16, 0
device_num:  .byte   $00        ; next device number to try
path_buf:       .res    128, 0
L50A8:  .byte   $00
L50A9:  .byte   $00

;;; ============================================================

stash_stack:    .byte   0
routine_table:  .addr   $7000, $7000, $7000

.proc L50B1
        sty     stash_y
        stx     stash_x
        tsx
        stx     stash_stack
        pha
        lda     #0
        sta     device_num
        sta     L50A8
        sta     prompt_ip_flag
        sta     LD8EC
        sta     $D8F0
        sta     $D8F1
        sta     $D8F2
        sta     cursor_ip_flag
        sta     L5104
        sta     L5103
        sta     L5105
        lda     #prompt_insertion_point_blink_count
        sta     prompt_ip_counter
        lda     #$FF
        sta     $D920
        pla
        asl     a
        tax
        copy16  routine_table,x, jump
        ldy     stash_y
        ldx     stash_x

        jump := * + 1
        jmp     dummy1234

stash_x:        .byte   0
stash_y:        .byte   0
.endproc

;;; ============================================================
;;; Flags set by invoker to alter behavior

L5103:  .byte   0               ; ??? something before jt_13 invoked
L5104:  .byte   0               ; ??? something about inputs
L5105:  .byte   0               ; ??? something about the picker

;;; ============================================================

L5106:  bit     LD8EC
        bpl     :+
        dec     prompt_ip_counter
        bne     :+
        jsr     jt_02
        lda     #prompt_insertion_point_blink_count
        sta     prompt_ip_counter
:       MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     L51AF
        jmp     L5106

:       cmp     #MGTK::EventKind::key_down
        bne     :+
        jsr     L59B9
:       MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     :+
        jmp     L5106
:       lda     findwindow_window_id
        cmp     winfo_entrydlg
        beq     L5151
        jmp     L5106

L5151:  lda     winfo_entrydlg
        jsr     set_port_for_window
        lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        bit     L51AE
        bmi     L5183
        MGTK_RELAY_CALL MGTK::InRect, common_input1_rect
        cmp     #MGTK::inrect_inside
        bne     L5196
        beq     L5190
L5183:  MGTK_RELAY_CALL MGTK::InRect, common_input2_rect
        cmp     #MGTK::inrect_inside
        bne     L5196
L5190:  jsr     set_cursor_insertion
        jmp     L5199

L5196:  jsr     set_cursor_pointer
L5199:  MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        jmp     L5106

L51AE:  .byte   0

;;; ============================================================

L51AF:  MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     :+
        rts
:       cmp     #MGTK::Area::content
        bne     :+
        jmp     L51C7
        rts                     ; ???
:       rts

L51C7:  lda     findwindow_window_id
        cmp     winfo_entrydlg
        beq     L51D2
        jmp     L531F

L51D2:  lda     winfo_entrydlg
        jsr     set_port_for_window
        lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx

        ;; In open button?
.proc check_open_button
        MGTK_RELAY_CALL MGTK::InRect, common_open_button_rect
        cmp     #MGTK::inrect_inside
        beq     clicked
        jmp     check_change_drive_button

clicked:
        bit     L5105
        bmi     L520A
        lda     $D920
        bpl     L520D
L520A:  jmp     set_up_ports

L520D:  tax
        lda     $1780,x
        bmi     L5216
L5213:  jmp     set_up_ports

L5216:  lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_open_button_rect
        jsr     track_open_button_click
        bmi     L5213
        jsr     L5607
        jmp     set_up_ports
.endproc

.proc check_change_drive_button
        MGTK_RELAY_CALL MGTK::InRect, common_change_drive_button_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        jmp     check_close_button
:       bit     L5105
        bmi     L5268
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_change_drive_button_rect
        jsr     track_change_drive_button_click
        bmi     L5268
        jsr     L565C
L5268:  jmp     set_up_ports
.endproc

.proc check_close_button
        MGTK_RELAY_CALL MGTK::InRect, common_close_button_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        jmp     check_ok_button
:       bit     L5105
        bmi     L529A
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_close_button_rect
        jsr     track_close_button_click
        bmi     L529A
        jsr     L567F
L529A:  jmp     set_up_ports
.endproc

.proc check_ok_button
        MGTK_RELAY_CALL MGTK::InRect, common_ok_button_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        jmp     check_cancel_button
:       MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_ok_button_rect
        jsr     track_ok_button_click
        bmi     L52CA
        jsr     jt_12
        jsr     jt_00
L52CA:  jmp     set_up_ports
.endproc

.proc check_cancel_button
        MGTK_RELAY_CALL MGTK::InRect, common_cancel_button_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        jmp     check_other_click
:       MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_cancel_button_rect
        jsr     track_cancel_button_click
        bmi     L52F7
        jsr     jt_01
L52F7:  jmp     set_up_ports
.endproc

.proc check_other_click
        bit     L5103
        bpl     :+
        jsr     L531B
        bmi     set_up_ports
:       jsr     jt_13
        rts
.endproc

set_up_ports:
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport2
        rts

L531B:  jsr     L59B8
        rts

L531F:  bit     L5105
        bmi     L5340
        MGTK_RELAY_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_which_ctl
        beq     L5341
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     L5340
        lda     winfo_entrydlg_file_picker::vscroll
        and     #$01
        beq     L5340
        jmp     L5469

L5340:  rts

L5341:  lda     winfo_entrydlg_file_picker
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        add16   screentowindow_windowy, winfo_entrydlg_file_picker::cliprect+2, screentowindow_windowy
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
        lda     $D920
        cmp     screentowindow_windowy
        beq     L5380
        jmp     L542F

L5380:  jsr     L5C4F
        beq     L5386
        rts

L5386:  ldx     $D920
        lda     $1780,x
        bmi     L53B5
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_ok_button_rect
        jsr     jt_00
        jmp     L5340

L53B5:  and     #$7F
        pha
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_open_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_open_button_rect
        lda     #$00
        sta     L542E
        copy16  #$1800, $08
        pla
        asl     a
        rol     L542E
        asl     a
        rol     L542E
        asl     a
        rol     L542E
        asl     a
        rol     L542E
        clc
        adc     $08
        sta     $08
        lda     L542E
        adc     $09
        sta     $09
        ldx     $09
        lda     $08
        jsr     L5F0D
        jsr     L5F5B
        jsr     L6161
        lda     #$00
        jsr     L6227
        jsr     L61B1
        jsr     L606D
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport2
        rts

L542E:  .byte   0

L542F:  lda     screentowindow_windowy
        cmp     $177F
        bcc     L5438
        rts

L5438:  lda     $D920
        bmi     L5446
        jsr     jt_04
        lda     $D920
        jsr     L6274
L5446:  lda     screentowindow_windowy
        sta     $D920
        bit     $D8F0
        bpl     L5457
        jsr     jt_06
        jsr     jt_03
L5457:  lda     $D920
        jsr     L6274
        jsr     jt_05
        jsr     L5C4F
        bmi     L5468
        jmp     L5386

L5468:  rts

L5469:  lda     findcontrol_which_part
        cmp     #MGTK::Part::up_arrow
        bne     L5473
        jmp     L550A

L5473:  cmp     #MGTK::Part::down_arrow
        bne     L547A
        jmp     L5533

L547A:  cmp     #MGTK::Part::page_up
        bne     L5481
        jmp     L54BA

L5481:  cmp     #MGTK::Part::page_down
        bne     L5488
        jmp     L54DF

L5488:  lda     #MGTK::Ctl::vertical_scroll_bar
        sta     trackthumb_params
        MGTK_RELAY_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_thumbmoved
        bne     :+
        rts
:       lda     trackthumb_thumbpos
        sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_stash
        jsr     L6227
        jsr     L606D
        rts

L54BA:  lda     winfo_entrydlg_file_picker::vthumbpos
        sec
        sbc     #$09
        bpl     L54C4
        lda     #$00
L54C4:  sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     L6227
        jsr     L606D
        rts

L54DF:  lda     winfo_entrydlg_file_picker::vthumbpos
        clc
        adc     #$09
        cmp     $177F
        beq     L54EF
        bcc     L54EF
        lda     $177F
L54EF:  sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     L6227
        jsr     L606D
        rts

L550A:  lda     winfo_entrydlg_file_picker::vthumbpos
        bne     L5510
        rts

L5510:  sec
        sbc     #$01
        sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     L6227
        jsr     L606D
        jsr     L555F
        jmp     L550A

L5533:  lda     winfo_entrydlg_file_picker::vthumbpos
        cmp     winfo_entrydlg_file_picker::vthumbmax
        bne     L553C
        rts

L553C:  clc
        adc     #$01
        sta     updatethumb_thumbpos
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        lda     updatethumb_thumbpos
        jsr     L6227
        jsr     L606D
        jsr     L555F
        jmp     L5533

L555F:  MGTK_RELAY_CALL MGTK::PeekEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        beq     L5576
        cmp     #MGTK::EventKind::drag
        beq     L5576
        pla
        pla
        rts

L5576:  MGTK_RELAY_CALL MGTK::GetEvent, event_params
        MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_window_id
        cmp     winfo_entrydlg_file_picker
        beq     :+
        pla
        pla
        rts

:       lda     findwindow_which_area
        cmp     #MGTK::Area::content
        beq     :+
        pla
        pla
        rts

:       MGTK_RELAY_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        beq     :+
        pla
        pla
        rts

:       lda     findcontrol_which_part
        cmp     #MGTK::Part::page_up
        bcc     L55B9
        pla
        pla
L55B9:  rts

;;; ============================================================

.proc set_cursor_pointer
        bit     cursor_ip_flag
        bpl     done
        MGTK_RELAY_CALL MGTK::HideCursor
        MGTK_RELAY_CALL MGTK::SetCursor, pointer_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor
        lda     #$00
        sta     cursor_ip_flag
done:   rts
.endproc

.proc set_cursor_insertion
        bit     cursor_ip_flag
        bmi     done
        MGTK_RELAY_CALL MGTK::HideCursor
        MGTK_RELAY_CALL MGTK::SetCursor, insertion_point_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor
        lda     #$80
        sta     cursor_ip_flag
done:   rts
.endproc

cursor_ip_flag:                 ; high bit set when cursor is IP
        .byte   0

;;; ============================================================

L5607:  ldx     $D920
        lda     $1780,x
        and     #$7F
        pha
        bit     $D8F0
        bpl     L5618
        jsr     jt_06
L5618:  lda     #$00
        sta     L565B
        copy16  #$1800, $08
        pla
        asl     a
        rol     L565B
        asl     a
        rol     L565B
        asl     a
        rol     L565B
        asl     a
        rol     L565B
        clc
        adc     $08
        sta     $08
        lda     L565B
        adc     $09
        sta     $09
        ldx     $09
        lda     $08
        jsr     L5F0D
        jsr     L5F5B
        jsr     L6161
        lda     #$00
        jsr     L6227
        jsr     L61B1
        jsr     L606D
        rts

L565B:  .byte   0

L565C:  lda     #$FF
        sta     $D920
        jsr     inc_device_num
        jsr     device_on_line
        jsr     L5F5B
        jsr     L6161
        lda     #$00
        jsr     L6227
        jsr     L61B1
        jsr     L606D
        jsr     jt_06
        jsr     jt_03
        rts

L567F:  lda     #$00
        sta     L56E2
        ldx     path_buf
        bne     L568C
        jmp     L56E1

L568C:  lda     path_buf,x
        and     #CHAR_MASK
        cmp     #'/'
        beq     L569B
        dex
        bpl     L568C
        jmp     L56E1

L569B:  cpx     #$01
        bne     L56A2
        jmp     L56E1

L56A2:  jsr     L5F49
        lda     $D920
        pha
        lda     #$FF
        sta     $D920
        jsr     L5F5B
        jsr     L6161
        lda     #$00
        jsr     L6227
        jsr     L61B1
        jsr     L606D
        pla
        sta     $D920
        bit     L56E2
        bmi     L56D6
        jsr     jt_04
        lda     $D920
        bmi     L56DC
        jsr     jt_04
        jmp     L56DC

L56D6:  jsr     jt_06
        jsr     jt_03
L56DC:  lda     #$FF
        sta     $D920
L56E1:  rts

L56E2:  .byte   0

L56E3:  MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

;;; ============================================================

.proc track_ok_button_click
        lda     #$00
        sta     L577B
L56FB:  MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     L575E
        lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, common_ok_button_rect
        cmp     #MGTK::inrect_inside
        beq     L5738
        lda     L577B
        beq     L5740
        jmp     L56FB

L5738:  lda     L577B
        bne     L5740
        jmp     L56FB

L5740:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_ok_button_rect
        lda     L577B
        clc
        adc     #$80
        sta     L577B
        jmp     L56FB

L575E:  lda     L577B
        beq     L5766
        return  #$FF

L5766:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_ok_button_rect
        return  #$00

L577B:  .byte   0
.endproc

;;; ============================================================

.proc track_close_button_click
        lda     #$00
        sta     L5801
L5781:  MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     L57E4
        lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, common_close_button_rect
        cmp     #MGTK::inrect_inside
        beq     L57BE
        lda     L5801
        beq     L57C6
        jmp     L5781

L57BE:  lda     L5801
        bne     L57C6
        jmp     L5781

L57C6:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_close_button_rect
        lda     L5801
        clc
        adc     #$80
        sta     L5801
        jmp     L5781

L57E4:  lda     L5801
        beq     L57EC
        return  #$FF

L57EC:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_close_button_rect
        return  #$00

L5801:  .byte   0
.endproc

;;; ============================================================

.proc track_cancel_button_click
        lda     #$00
        sta     L5887
L5807:  MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     L586A
        lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, common_cancel_button_rect
        cmp     #MGTK::inrect_inside
        beq     L5844
        lda     L5887
        beq     L584C
        jmp     L5807

L5844:  lda     L5887
        bne     L584C
        jmp     L5807

L584C:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_cancel_button_rect
        lda     L5887
        clc
        adc     #$80
        sta     L5887
        jmp     L5807

L586A:  lda     L5887
        beq     L5872
        return  #$FF

L5872:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_cancel_button_rect
        return  #$01

L5887:  .byte   0
.endproc

;;; ============================================================

.proc track_open_button_click
        lda     #$00
        sta     L590D
L588D:  MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     L58F0
        lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, common_open_button_rect
        cmp     #MGTK::inrect_inside
        beq     L58CA
        lda     L590D
        beq     L58D2
        jmp     L588D

L58CA:  lda     L590D
        bne     L58D2
        jmp     L588D

L58D2:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_open_button_rect
        lda     L590D
        clc
        adc     #$80
        sta     L590D
        jmp     L588D

L58F0:  lda     L590D
        beq     L58F8
        return  #$FF

L58F8:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_open_button_rect
        return  #$00

L590D:  .byte   0
.endproc

;;; ============================================================

.proc track_change_drive_button_click
        lda     #$00
        sta     L5993
L5913:  MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     L5976
        lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, common_change_drive_button_rect
        cmp     #MGTK::inrect_inside
        beq     L5950
        lda     L5993
        beq     L5958
        jmp     L5913

L5950:  lda     L5993
        bne     L5958
        jmp     L5913

L5958:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_change_drive_button_rect
        lda     L5993
        clc
        adc     #$80
        sta     L5993
        jmp     L5913

L5976:  lda     L5993
        beq     L597E
        return  #$FF

L597E:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_change_drive_button_rect
        return  #$01

L5993:  .byte   0
.endproc

;;; ============================================================

.proc MLI_RELAY
        sty     call
        stax    params
        php
        sei
        sta     ALTZPOFF
        lda     ROMIN2
        jsr     MLI
call:   .byte   0
params: .addr   0
        sta     ALTZPON
        tax
        lda     LCBANK1
        lda     LCBANK1
        plp
        txa
        rts
.endproc

;;; ============================================================

just_rts:
L59B8:  rts

;;; ============================================================
;;; Key handler

.proc L59B9
        lda     event_modifiers
        beq     L59F7

        ;; With modifiers
        lda     event_key
        and     #CHAR_MASK

        cmp     #CHAR_LEFT
        bne     :+
        jmp     jt_11           ; start of line

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     jt_12           ; end of line

:       bit     L5105
        bmi     L59E4
        cmp     #CHAR_DOWN
        bne     :+
        jmp     scroll_list_bottom ; end of list

:       cmp     #CHAR_UP
        bne     L59E4
        jmp     scroll_list_top ; start of list

L59E4:  cmp     #'0'
        bcc     :+
        cmp     #'9'+1
        bcs     :+
        jmp     key_meta_digit

:       bit     L5105
        bmi     L5A4F
        jmp     L5B70

;;; ============================================================
;;; Key - without modifiers

L59F7:  lda     event_key
        and     #CHAR_MASK

        cmp     #CHAR_LEFT
        bne     :+
        jmp     jt_09

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     jt_10

:       cmp     #CHAR_RETURN
        bne     :+
        jmp     key_return

:       cmp     #CHAR_ESCAPE
        bne     :+
        jmp     key_escape

:       cmp     #CHAR_DELETE
        bne     :+
        jmp     key_delete

:       bit     L5105
        bpl     L5A27
        jmp     L5AC4

L5A27:  cmp     #CHAR_TAB
        bne     L5A52
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_change_drive_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_change_drive_button_rect
        jsr     L565C
L5A4F:  jmp     L5AC8

L5A52:  cmp     #CHAR_CTRL_O    ; Open
        bne     L5A8B
        lda     $D920
        bmi     L5AC8
        tax
        lda     $1780,x
        bmi     :+
        jmp     L5AC8
:       lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_open_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_open_button_rect
        jsr     L5607
        jmp     L5AC8

L5A8B:  cmp     #CHAR_CTRL_C    ; Close
        bne     :+
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, common_close_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_close_button_rect
        jsr     L567F
        jmp     L5AC8

:       cmp     #CHAR_DOWN
        bne     :+
        jmp     key_down

:       cmp     #CHAR_UP
        bne     L5AC4
        jmp     key_up

L5AC4:  jsr     jt_07
        rts

L5AC8:  jsr     L56E3
        rts

key_return:
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_RELAY_CALL MGTK::PaintRect, common_ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_ok_button_rect
        jsr     jt_12
        jsr     jt_00
        jsr     L56E3
        rts

key_escape:
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_RELAY_CALL MGTK::PaintRect, common_cancel_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, common_cancel_button_rect
        jsr     jt_01
        jsr     L56E3
        rts

key_delete:
        jsr     jt_08
        rts

key_meta_digit:
        jmp     L59B8

.proc key_down
        lda     $177F
        beq     L5B37
        lda     $D920
        bmi     L5B47
        tax
        inx
        cpx     $177F
        bcc     L5B38
L5B37:  rts

L5B38:  jsr     L6274
        jsr     jt_04
        inc     $D920
        lda     $D920
        jmp     update_list_selection

L5B47:  lda     #0
        jmp     update_list_selection
.endproc

.proc key_up
        lda     $177F
        beq     L5B58
        lda     $D920
        bmi     L5B68
        bne     L5B59
L5B58:  rts

L5B59:  jsr     L6274
        jsr     jt_04
        dec     $D920
        lda     $D920
        jmp     update_list_selection

L5B68:  ldx     $177F
        dex
        txa
        jmp     update_list_selection
.endproc

L5B70:  cmp     #'A'            ; upper alpha?
        bcs     :+
done:   rts
:       cmp     #'Z'+1
        bcc     L5B83
        cmp     #'a'            ; Lower alpha?
        bcc     done
        cmp     #'z'+1
        bcs     done
        and     #$5F            ; convert lowercase to upperase

L5B83:  jsr     L5B9D
        bmi     done
        cmp     $D920
        beq     done
        pha
        lda     $D920
        bmi     L5B99
        jsr     L6274
        jsr     jt_04
L5B99:  pla
        jmp     update_list_selection

L5B9D:  sta     L5BF5
        lda     #0
        sta     L5BF3
L5BA5:  lda     L5BF3
        cmp     $177F
        beq     L5BC4
        jsr     L5BCB
        ldy     #1
        lda     ($06),y
        cmp     L5BF5
        bcc     L5BBE
        beq     L5BC7
        jmp     L5BC4

L5BBE:  inc     L5BF3
        jmp     L5BA5

L5BC4:  return  #$FF

L5BC7:  return  L5BF3

L5BCB:  tax
        lda     $1780,x
        and     #$7F
        ldx     #$00
        stx     L5BF4
        asl     a
        rol     L5BF4
        asl     a
        rol     L5BF4
        asl     a
        rol     L5BF4
        asl     a
        rol     L5BF4
        clc
        adc     #$00
        sta     $06
        lda     L5BF4
        adc     #$18
        sta     $07
        rts

L5BF3:  .byte   0
L5BF4:  .byte   0
L5BF5:  .byte   0
.endproc

;;; ============================================================

.proc scroll_list_top
        lda     $177F
        beq     L5C02
        lda     $D920
        bmi     L5C09
        bne     L5C03
L5C02:  rts

L5C03:  jsr     L6274
        jsr     jt_04
L5C09:  lda     #$00
        jmp     update_list_selection
.endproc

.proc scroll_list_bottom
        lda     $177F
        beq     L5C1E
        ldx     $D920
        bmi     L5C27
        inx
        cpx     $177F
        bne     L5C1F
L5C1E:  rts

L5C1F:  dex
        txa
        jsr     L6274
        jsr     jt_04
L5C27:  ldx     $177F
        dex
        txa
        jmp     update_list_selection
.endproc

;;; ============================================================

.proc update_list_selection
        sta     $D920
        jsr     jt_05
        lda     $D920
        jsr     L6586
        jsr     L6163
        jsr     L606D

        copy    #1, path_buf2
        copy    #' ', path_buf2+1

        jsr     jt_03
        rts
.endproc

;;; ============================================================

.proc L5C4F
        ldx     #3
:       lda     screentowindow_screenx,x
        sta     L5CF0,x
        dex
        bpl     :-

        lda     machine_type    ; Timer for insertion point blink
        sta     ip_blink_counter
L5C60:  dec     ip_blink_counter
        beq     L5CA6
        MGTK_RELAY_CALL MGTK::PeekEvent, event_params
        jsr     L5CA9
        bmi     L5CA6
        lda     #$FF
        sta     L5CF6
        lda     event_kind
        sta     L5CF5
        cmp     #MGTK::EventKind::no_event
        beq     L5C60
        cmp     #MGTK::EventKind::drag
        beq     L5C60
        cmp     #MGTK::EventKind::button_up
        bne     L5C96
        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        jmp     L5C60

L5C96:  cmp     #MGTK::EventKind::button_down
        bne     L5CA6
        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        return  #$00

L5CA6:  return  #$FF

L5CA9:  lda     event_xcoord
        sec
        sbc     L5CF0
        sta     L5CF4
        lda     event_xcoord+1
        sbc     L5CF1
        bpl     L5CC5
        lda     L5CF4
        cmp     #$FB
        bcs     L5CCC
L5CC2:  return  #$FF

L5CC5:  lda     L5CF4
        cmp     #$05
        bcs     L5CC2
L5CCC:  lda     event_ycoord
        sec
        sbc     L5CF2
        sta     L5CF4
        lda     event_ycoord+1
        sbc     L5CF3
        bpl     L5CE5
        lda     L5CF4
        cmp     #$FC
        bcs     L5CEC
L5CE5:  lda     L5CF4
        cmp     #$04
        bcs     L5CC2
L5CEC:  return  #$00

ip_blink_counter:
        .byte   0

L5CF0:  .byte   0
L5CF1:  .byte   0
L5CF2:  .byte   0
L5CF3:  .byte   0
L5CF4:  .byte   0
L5CF5:  .byte   0
L5CF6:  .byte   0
.endproc

;;; ============================================================

.proc create_common_dialog
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_entrydlg
        MGTK_RELAY_CALL MGTK::OpenWindow, winfo_entrydlg_file_picker
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, common_dialog_frame_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_ok_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_open_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_close_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_cancel_button_rect
        MGTK_RELAY_CALL MGTK::FrameRect, common_change_drive_button_rect
        jsr     draw_ok_button_label
        jsr     draw_open_button_label
        jsr     draw_close_button_label
        jsr     draw_cancel_button_label
        jsr     draw_change_drive_button_label
        MGTK_RELAY_CALL MGTK::MoveTo, common_dialog_sep_start
        MGTK_RELAY_CALL MGTK::LineTo, common_dialog_sep_end
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts
.endproc

draw_ok_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, ok_button_pos
        addr_call draw_string, ok_button_label
        rts

draw_open_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, open_button_pos
        addr_call draw_string, open_button_label
        rts

draw_close_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, close_button_pos
        addr_call draw_string, close_button_label
        rts

draw_cancel_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, cancel_button_pos
        addr_call draw_string, cancel_button_label
        rts

draw_change_drive_button_label:
        MGTK_RELAY_CALL MGTK::MoveTo, change_drive_button_pos
        addr_call draw_string, change_drive_button_label
        rts

;;; ============================================================

.proc copy_string_to_lcbuf
        ptr := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     temp_string_buf,y
        dey
        bpl     :-
        ldax    #temp_string_buf
        rts
.endproc

;;; ============================================================

.proc draw_string
        jsr     copy_string_to_lcbuf
        stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
        MGTK_RELAY_CALL MGTK::DrawText, $06
        rts
.endproc

;;; ============================================================

.proc L5E0A
        jsr     copy_string_to_lcbuf
        stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
        MGTK_RELAY_CALL MGTK::TextWidth, $06
        lsr16    $09
        lda     #$01
        sta     L5E56
        lda     #$F4
        lsr     L5E56
        ror     a
        sec
        sbc     $09
        sta     pos_D90B
        lda     L5E56
        sbc     $0A
        sta     pos_D90B+1
        MGTK_RELAY_CALL MGTK::MoveTo, pos_D90B
        MGTK_RELAY_CALL MGTK::DrawText, $06
        rts

L5E56:  .byte   0
.endproc

;;; ============================================================

L5E57:  jsr     copy_string_to_lcbuf
        stax    $06
        MGTK_RELAY_CALL MGTK::MoveTo, common_input1_label_pos
        ldax    $06
        jsr     draw_string
        rts

;;; ============================================================

L5E6F:  jsr     copy_string_to_lcbuf
        stax    $06
        MGTK_RELAY_CALL MGTK::MoveTo, common_input2_label_pos
        ldax    $06
        jsr     draw_string
        rts

;;; ============================================================

.proc device_on_line
:       ldx     device_num
        lda     DEVLST,x
        and     #$F0
        sta     on_line_params::unit_num
        yax_call MLI_RELAY, ON_LINE, on_line_params
        lda     on_line_buffer
        and     #$0F
        sta     on_line_buffer
        bne     found
        jsr     inc_device_num
        jmp     :-

found:  lda     #0
        sta     path_buf
        addr_call L5F0D, on_line_buffer
        rts
.endproc

;;; ============================================================

.proc inc_device_num
        inc     device_num
        lda     device_num
        cmp     DEVCNT
        beq     :+
        bcc     :+
        lda     #0
        sta     device_num
:       rts
.endproc

;;; ============================================================


L5ECB:  lda     #$00
        sta     L5F0C
L5ED0:  yax_call MLI_RELAY, OPEN, open_params
        beq     L5EE9
        jsr     device_on_line
        lda     #$FF
        sta     $D920
        sta     L5F0C
        jmp     L5ED0

L5EE9:  lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        yax_call MLI_RELAY, READ, read_params
        beq     L5F0B
        jsr     device_on_line
        lda     #$FF
        sta     $D920
        sta     L5F0C
        jmp     L5ED0

L5F0B:  rts

L5F0C:  .byte   0
L5F0D:  jsr     copy_string_to_lcbuf
        stax    $06
        ldx     path_buf
        lda     #'/'
        sta     path_buf+1,x
        inc     path_buf
        ldy     #0
        lda     ($06),y
        tay
        clc
        adc     path_buf
        cmp     #'A'
        bcc     L5F2F
        return  #$FF

L5F2F:  pha
        tax
L5F31:  lda     ($06),y
        sta     path_buf,x
        dey
        dex
        cpx     path_buf
        bne     L5F31
        pla
        sta     path_buf
        lda     #$FF
        sta     $D920
        return  #$00

;;; ============================================================

L5F49:  ldx     path_buf
        cpx     #$00
        beq     L5F5A
        dec     path_buf
        lda     path_buf,x
        cmp     #'/'
        bne     L5F49
L5F5A:  rts

;;; ============================================================

L5F5B:  jsr     L5ECB
        lda     #$00
        sta     L6067
        sta     L6068
        sta     L50A9
        lda     #$01
        sta     L6069
        copy16  $1423, L606A
        lda     $1425
        and     #$7F
        sta     $177F
        bne     L5F87
        jmp     L6012

L5F87:  copy16  #$142B, $06
L5F8F:  ldy     #$00
        lda     ($06),y
        and     #$0F
        bne     L5F9A
        jmp     L6007

L5F9A:  ldx     L6067
        txa
        sta     $1780,x
        ldy     #$00
        lda     ($06),y
        and     #$F0
        cmp     #$D0
        beq     L5FB6
        bit     L50A8
        bpl     L5FC1
        inc     L6068
        jmp     L6007

L5FB6:  lda     $1780,x
        ora     #$80
        sta     $1780,x
        inc     L50A9
L5FC1:  ldy     #$00
        lda     ($06),y
        and     #$0F
        sta     ($06),y
        copy16  #$1800, $08
        lda     #$00
        sta     L606C
        lda     L6067
        asl     a
        rol     L606C
        asl     a
        rol     L606C
        asl     a
        rol     L606C
        asl     a
        rol     L606C
        clc
        adc     $08
        sta     $08
        lda     L606C
        adc     $09
        sta     $09
        ldy     #$00
        lda     ($06),y
        tay
L5FFA:  lda     ($06),y
        sta     ($08),y
        dey
        bpl     L5FFA
        inc     L6067
        inc     L6068
L6007:  inc     L6069
        lda     L6068
        cmp     $177F
        bne     L6035
L6012:  yax_call MLI_RELAY, CLOSE, close_params
        bit     L50A8
        bpl     L6026
        lda     L50A9
        sta     $177F
L6026:  jsr     L62DE
        jsr     L64E2
        lda     L5F0C
        bpl     L6033
        sec
        rts

L6033:  clc
        rts

L6035:  lda     L6069
        cmp     L606B
        beq     L604E
        lda     $06
        clc
        adc     L606A
        sta     $06
        lda     $07
        adc     #$00
        sta     $07
        jmp     L5F8F

L604E:  yax_call MLI_RELAY, READ, read_params
        copy16  #$1404, $06
        lda     #$00
        sta     L6069
        jmp     L5F8F

L6067:  .byte   0
L6068:  .byte   0
L6069:  .byte   0
L606A:  .byte   0
L606B:  .byte   0
L606C:  .byte   0

;;; ============================================================

L606D:  lda     winfo_entrydlg_file_picker
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, winfo_entrydlg_file_picker::cliprect
        lda     #$10
        sta     picker_entry_pos
        lda     #$08
        sta     picker_entry_pos+2
        lda     #$00
        sta     picker_entry_pos+3
        sta     L6128
L608E:  lda     L6128
        cmp     $177F
        bne     L60A9
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

L60A9:  MGTK_RELAY_CALL MGTK::MoveTo, picker_entry_pos
        ldx     L6128
        lda     $1780,x
        and     #$7F
        ldx     #$00
        stx     L6127
        asl     a
        rol     L6127
        asl     a
        rol     L6127
        asl     a
        rol     L6127
        asl     a
        rol     L6127
        clc
        adc     #$00
        tay
        lda     L6127
        adc     #$18
        tax
        tya
        jsr     draw_string
        ldx     L6128
        lda     $1780,x
        bpl     L60FF
        lda     #$01
        sta     picker_entry_pos
        MGTK_RELAY_CALL MGTK::MoveTo, picker_entry_pos
        addr_call draw_string, str_folder
        lda     #$10
        sta     picker_entry_pos
L60FF:  lda     L6128
        cmp     $D920
        bne     L6110
        jsr     L6274
        lda     winfo_entrydlg_file_picker
        jsr     set_port_for_window
L6110:  inc     L6128
        add16   picker_entry_pos+2, #8, picker_entry_pos+2
        jmp     L608E

L6127:  .byte   0
L6128:  .byte   0

;;; ============================================================

.proc adjust_filename_case
        ptr := $A

        stx     ptr+1
        sta     ptr
        ldy     #0
        lda     (ptr),y
        tay
        bne     loop
        rts

loop:   dey
        beq     done
        bpl     :+
done:   rts

:       lda     (ptr),y
        and     #CHAR_MASK      ; convert to ASCII
        cmp     #'/'
        beq     next
        cmp     #'.'
        bne     check_alpha
next:   dey
        jmp     loop

check_alpha:
        iny
        lda     (ptr),y
        and     #CHAR_MASK
        cmp     #'A'
        bcc     :+
        cmp     #'Z'+1
        bcs     :+
        clc
        adc     #('a' - 'A')    ; convert to lower case
        sta     (ptr),y
:       dey
        jmp     loop
.endproc

;;; ============================================================

L6161:  lda     #$00
L6163:  sta     L61B0
        lda     $177F
        cmp     #$0A
        bcs     L6181
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_which_ctl
        lda     #MGTK::activatectl_deactivate
        sta     activatectl_activate
        MGTK_RELAY_CALL MGTK::ActivateCtl, activatectl_params
        rts

L6181:  lda     $177F
        sta     winfo_entrydlg_file_picker::vthumbmax
        .assert MGTK::Ctl::vertical_scroll_bar = MGTK::activatectl_activate, error, "need to match"
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     activatectl_which_ctl
        sta     activatectl_activate
        MGTK_RELAY_CALL MGTK::ActivateCtl, activatectl_params
        lda     L61B0
        sta     updatethumb_thumbpos
        jsr     L6227
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_which_ctl
        MGTK_RELAY_CALL MGTK::UpdateThumb, updatethumb_params
        rts

L61B0:  .byte   0

;;; ============================================================

L61B1:  lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D9C8
        copy16  #path_buf, $06
        ldy     #$00
        lda     ($06),y
        sta     L6226
        iny
L61D0:  iny
        lda     ($06),y
        cmp     #'/'
        beq     L61DE
        cpy     L6226
        bne     L61D0
        beq     L61E2
L61DE:  dey
        sty     L6226
L61E2:  ldy     #$00
        ldx     #$00
L61E6:  inx
        iny
        lda     ($06),y
        sta     $0220,x
        cpy     L6226
        bne     L61E6
        stx     $0220
        addr_call adjust_filename_case, $0220
        MGTK_RELAY_CALL MGTK::MoveTo, disk_label_pos
        addr_call draw_string, disk_label
        addr_call draw_string, $0220
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

L6226:  .byte   0

;;; ============================================================

L6227:  sta     L6273
        clc
        adc     #$09
        cmp     $177F
        beq     L6234
        bcs     L623A
L6234:  lda     L6273
        jmp     L624A

L623A:  lda     $177F
        cmp     #$0A
        bcs     L6247
        lda     L6273
        jmp     L624A

L6247:  sec
        sbc     #$09
L624A:  ldx     #$00
        stx     L6273
        asl     a
        rol     L6273
        asl     a
        rol     L6273
        asl     a
        rol     L6273
        sta     winfo_entrydlg_file_picker::cliprect+2
        ldx     L6273
        stx     winfo_entrydlg_file_picker::cliprect+3
        clc
        adc     #70
        sta     winfo_entrydlg_file_picker::cliprect+6
        lda     L6273
        adc     #0
        sta     winfo_entrydlg_file_picker::cliprect+7
        rts

L6273:  .byte   0


L6274:  ldx     #0
        stx     L62C7
        asl     a
        rol     L62C7
        asl     a
        rol     L62C7
        asl     a
        rol     L62C7
        sta     rect_D90F+2
        ldx     L62C7
        stx     rect_D90F+3
        clc
        adc     #7
        sta     rect_D90F+6
        lda     L62C7
        adc     #0
        sta     rect_D90F+7
        lda     winfo_entrydlg_file_picker
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D90F
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

L62C7:  .byte   0

;;; ============================================================

.proc set_port_for_window
        sta     getwinport_params2::window_id
        MGTK_RELAY_CALL MGTK::GetWinPort, getwinport_params2
        MGTK_RELAY_CALL MGTK::SetPort, grafport2
        rts
.endproc

;;; ============================================================

L62DE:  ldax    #$0F5A
L62E2:  sta     L63C2,x
        dex
        bpl     L62E2
        lda     #$00
        sta     L63BF
        sta     L63BE
L62F0:  lda     L63BF
        cmp     $177F
        bne     L62FB
        jmp     L6377

L62FB:  lda     L63BE
        jsr     L6451
        ldy     #$00
        lda     ($06),y
        bmi     L633D
        and     #$0F
        sta     L63C1
        ldy     #$01
L630E:  lda     ($06),y
        cmp     L63C1,y
        beq     L631A
        bcs     L633D
        jmp     L6322

L631A:  iny
        cpy     #$10
        bne     L630E
        jmp     L633D

L6322:  lda     L63BE
        sta     L63C0
        ldx     #$0F
        lda     #$20
L632C:  sta     L63C2,x
        dex
        bpl     L632C
        ldy     L63C1
L6335:  lda     ($06),y
        sta     L63C1,y
        dey
        bne     L6335
L633D:  inc     L63BE
        lda     L63BE
        cmp     $177F
        beq     L634B
        jmp     L62FB

L634B:  lda     L63C0
        jsr     L6451
        ldy     #$00
        lda     ($06),y
        ora     #$80
        sta     ($06),y
        ldax    #$0F5A
L635D:  sta     L63C2,x
        dex
        bpl     L635D
        ldx     L63BF
        lda     L63C0
        sta     L63D2,x
        lda     #$00
        sta     L63BE
        inc     L63BF
        jmp     L62F0

L6377:  ldx     $177F
        dex
        stx     L63BF
L637E:  lda     L63BF
        bpl     L63AD
        ldx     $177F
        beq     L63AC
        dex
L6389:  lda     L63D2,x
        tay
        lda     $1780,y
        bpl     L639A
        lda     L63D2,x
        ora     #$80
        sta     L63D2,x
L639A:  dex
        bpl     L6389
        ldx     $177F
        beq     L63AC
        dex
L63A3:  lda     L63D2,x
        sta     $1780,x
        dex
        bpl     L63A3
L63AC:  rts

L63AD:  jsr     L6451
        ldy     #$00
        lda     ($06),y
        and     #$7F
        sta     ($06),y
        dec     L63BF
        jmp     L637E

L63BE:  .byte   0
L63BF:  .byte   0
L63C0:  .byte   0
L63C1:  .byte   0
L63C2:  .res 16, 0
L63D2:  .res 127, 0
L6451:  ldx     #$00
        stx     $06
        ldx     #$18
        stx     $07
        ldx     #$00
        stx     L647B
        asl     a
        rol     L647B
        asl     a
        rol     L647B
        asl     a
        rol     L647B
        asl     a
        rol     L647B
        clc
        adc     $06
        sta     $06
        lda     L647B
        adc     $07
        sta     $07
        rts

L647B:  .byte   0

;;; ============================================================

L647C:  stax    $06
        ldy     #$01
        lda     ($06),y
        cmp     #'/'
        bne     L64DE
        dey
        lda     ($06),y
        cmp     #$02
        bcc     L64DE
        tay
        lda     ($06),y
        cmp     #'/'
        beq     L64DE
        ldx     #$00
        stx     L64E1
L649B:  lda     ($06),y
        cmp     #'/'
        beq     L64AB
        inx
        cpx     #$10
        beq     L64DE
        dey
        bne     L649B
        beq     L64B3
L64AB:  inc     L64E1
        ldx     #$00
        dey
        bne     L649B
L64B3:  ldy     #$00
        lda     ($06),y
        tay
L64B8:  lda     ($06),y
        and     #CHAR_MASK
        cmp     #'.'
        beq     L64D8
        cmp     #'/'
        bcc     L64DE
        cmp     #'9'+1
        bcc     L64D8
        cmp     #'A'
        bcc     L64DE
        cmp     #'Z'+1
        bcc     L64D8
        cmp     #'a'
        bcc     L64DE
        cmp     #'z'+1
        bcs     L64DE
L64D8:  dey
        bne     L64B8
        return  #$00

L64DE:  return  #$FF

L64E1:  .byte   0
L64E2:  lda     $177F
        bne     L64E8
L64E7:  rts

L64E8:  lda     #$00
        sta     L6515
        copy16  #$1800, $06
L64F5:  lda     L6515
        cmp     $177F
        beq     L64E7
        lda     $06
        ldx     $07
        jsr     adjust_filename_case
        inc     L6515
        lda     $06
        clc
        adc     #$10
        sta     $06
        bcc     L64F5
        inc     $07
        jmp     L64F5

L6515:  .byte   0

;;; ============================================================

L6516:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L651F:  lda     ($06),y
        sta     L6576,y
        dey
        bpl     L651F
        lda     #$00
        sta     L6575
        copy16  #$1800, $06
L6534:  lda     L6575
        cmp     $177F
        beq     L6564
        ldy     #$00
        lda     ($06),y
        cmp     L6576
        bne     L6553
        tay
L6546:  lda     ($06),y
        cmp     L6576,y
        bne     L6553
        dey
        bne     L6546
        jmp     L6567

L6553:  inc     L6575
        lda     $06
        clc
        adc     #$10
        sta     $06
        bcc     L6534
        inc     $07
        jmp     L6534

L6564:  return  #$FF

L6567:  ldx     $177F
        lda     L6575
L656D:  dex
        cmp     $1780,x
        bne     L656D
        txa
        rts

L6575:  .byte   0
L6576:  .res 16, 0

;;; ============================================================

L6586:  bpl     L658B
L6588:  return  #$00

L658B:  cmp     #$09
        bcc     L6588
        sec
        sbc     #$08
        rts

L6593:  lda     winfo_entrydlg
        jsr     set_port_for_window
        jsr     L6E45
        stax    $06
        copy16  common_input1_textpos+2, $08
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        bit     prompt_ip_flag
        bpl     L65C8
        MGTK_RELAY_CALL MGTK::SetTextBG, textbg1
        lda     #$00
        sta     prompt_ip_flag
        beq     L65D6
L65C8:  MGTK_RELAY_CALL MGTK::SetTextBG, textbg2
        lda     #$FF
        sta     prompt_ip_flag
L65D6:  copy16  #$D8EF, $06
        lda     $D8EE
        sta     $08
        MGTK_RELAY_CALL MGTK::DrawText, $06
        jsr     L56E3
        rts

L65F0:  lda     winfo_entrydlg
        jsr     set_port_for_window
        jsr     L6E72
        stax    $06
        copy16  common_input2_textpos+2, $08
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        bit     prompt_ip_flag
        bpl     L6626
        MGTK_RELAY_CALL MGTK::SetTextBG, textbg1
        lda     #$00
        sta     prompt_ip_flag
        jmp     L6634

L6626:  MGTK_RELAY_CALL MGTK::SetTextBG, textbg2
        lda     #$FF
        sta     prompt_ip_flag
L6634:  copy16  #$D8EF, $06
        lda     $D8EE
        sta     $08
        MGTK_RELAY_CALL MGTK::DrawText, $06
        jsr     L56E3
        rts

L664E:  lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, common_input1_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, common_input1_rect
        MGTK_RELAY_CALL MGTK::MoveTo, common_input1_textpos
        lda     path_buf0
        beq     L6684
        addr_call draw_string, path_buf0
L6684:  addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        rts

;;; ============================================================

L6693:  lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::PaintRect, common_input2_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, common_input2_rect
        MGTK_RELAY_CALL MGTK::MoveTo, common_input2_textpos
        lda     path_buf1
        beq     L66C9
        addr_call draw_string, path_buf1
L66C9:  addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        rts

L66D8:  lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, common_input1_rect
        cmp     #MGTK::inrect_inside
        beq     L6719
        bit     L5104
        bpl     L6718
        MGTK_RELAY_CALL MGTK::InRect, common_input2_rect
        cmp     #MGTK::inrect_inside
        bne     L6718
        jmp     jt_00

L6718:  rts

L6719:  jsr     L6E45
        stax    $06
        cmp16   screentowindow_windowx, $06
        bcs     L672F
        jmp     L67C4

L672F:  jsr     L6E45
        stax    L684D
        ldx     path_buf2
        inx
        lda     #' '
        sta     path_buf2,x
        inc     path_buf2
        copy16  #path_buf2, $06
        lda     path_buf2
        sta     $08
L6751:  MGTK_RELAY_CALL MGTK::TextWidth, $06
        add16   $09, L684D, $09
        cmp16   $09, screentowindow_windowx
        bcc     L6783
        dec     $08
        lda     $08
        cmp     #$01
        bne     L6751
        dec     path_buf2
        jmp     L6846

L6783:  lda     $08
        cmp     path_buf2
        bcc     L6790
        dec     path_buf2
        jmp     L6B44

L6790:  ldx     #$02
        ldy     path_buf0
        iny
L6796:  lda     path_buf2,x
        sta     path_buf0,y
        cpx     $08
        beq     L67A5
        iny
        inx
        jmp     L6796

L67A5:  sty     path_buf0
        ldy     #$02
        ldx     $08
        inx
L67AD:  lda     path_buf2,x
        sta     path_buf2,y
        cpx     path_buf2
        beq     L67BD
        iny
        inx
        jmp     L67AD

L67BD:  dey
        sty     path_buf2
        jmp     L6846

L67C4:  copy16  #path_buf0, $06
        lda     path_buf0
        sta     $08
L67D1:  MGTK_RELAY_CALL MGTK::TextWidth, $06
        add16   $09, common_input1_textpos, $09
        cmp16   $09, screentowindow_windowx
        bcc     L6800
        dec     $08
        lda     $08
        cmp     #$01
        bcs     L67D1
        jmp     L6B01

L6800:  inc     $08
        ldy     #$00
        ldx     $08
L6806:  cpx     path_buf0
        beq     L6816
        inx
        iny
        lda     path_buf0,x
        sta     $D3C2,y
        jmp     L6806

L6816:  iny
        sty     $D3C1
        ldx     #$01
        ldy     $D3C1
L681F:  cpx     path_buf2
        beq     L682F
        inx
        iny
        lda     path_buf2,x
        sta     $D3C1,y
        jmp     L681F

L682F:  sty     $D3C1
        lda     $D8EF
        sta     $D3C2
L6838:  lda     $D3C1,y
        sta     path_buf2,y
        dey
        bpl     L6838
        lda     $08
        sta     path_buf0
L6846:  jsr     jt_03
        jsr     L6EA3
        rts

L684D:  .word   0
L684F:  lda     winfo_entrydlg
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, common_input2_rect
        cmp     #MGTK::inrect_inside
        beq     L6890
        bit     L5104
        bpl     L688F
        MGTK_RELAY_CALL MGTK::InRect, common_input1_rect
        cmp     #MGTK::inrect_inside
        bne     L688F
        jmp     jt_01

L688F:  rts

L6890:  jsr     L6E72
        stax    $06
        cmp16   screentowindow_windowx, $06
        bcs     L68A6
        jmp     L693B

L68A6:  jsr     L6E72
        stax    L69C4
        ldx     path_buf2
        inx
        lda     #' '
        sta     path_buf2,x
        inc     path_buf2
        copy16  #path_buf2, $06
        lda     path_buf2
        sta     $08
L68C8:  MGTK_RELAY_CALL MGTK::TextWidth, $06
        add16   $09, L69C4, $09
        cmp16   $09, screentowindow_windowx
        bcc     L68FA
        dec     $08
        lda     $08
        cmp     #$01
        bne     L68C8
        dec     path_buf2
        jmp     L69BD

L68FA:  lda     $08
        cmp     path_buf2
        bcc     L6907
        dec     path_buf2
        jmp     L6CF0

L6907:  ldx     #$02
        ldy     path_buf1
        iny
L690D:  lda     path_buf2,x
        sta     path_buf1,y
        cpx     $08
        beq     L691C
        iny
        inx
        jmp     L690D

L691C:  sty     path_buf1
        ldy     #$02
        ldx     $08
        inx
L6924:  lda     path_buf2,x
        sta     path_buf2,y
        cpx     path_buf2
        beq     L6934
        iny
        inx
        jmp     L6924

L6934:  dey
        sty     path_buf2
        jmp     L69BD

L693B:  copy16  #path_buf1, $06
        lda     path_buf1
        sta     $08
L6948:  MGTK_RELAY_CALL MGTK::TextWidth, $06
        add16   $09, common_input2_textpos, $09
        cmp16   $09, screentowindow_windowx
        bcc     L6977
        dec     $08
        lda     $08
        cmp     #$01
        bcs     L6948
        jmp     L6CAD

L6977:  inc     $08
        ldy     #$00
        ldx     $08
L697D:  cpx     path_buf1
        beq     L698D
        inx
        iny
        lda     path_buf1,x
        sta     $D3C2,y
        jmp     L697D

L698D:  iny
        sty     $D3C1
        ldx     #$01
        ldy     $D3C1
L6996:  cpx     path_buf2
        beq     L69A6
        inx
        iny
        lda     path_buf2,x
        sta     $D3C1,y
        jmp     L6996

L69A6:  sty     $D3C1
        lda     $D8EF
        sta     $D3C2
L69AF:  lda     $D3C1,y
        sta     path_buf2,y
        dey
        bpl     L69AF
        lda     $08
        sta     path_buf1
L69BD:  jsr     jt_03
        jsr     L6E9F
        rts

L69C4:  .word   0
L69C6:  sta     L6A17
        lda     path_buf0
        clc
        adc     path_buf2
        cmp     #$3F
        bcc     L69D5
        rts

L69D5:  lda     L6A17
        ldx     path_buf0
        inx
        sta     path_buf0,x
        sta     str_1_char+1
        jsr     L6E45
        inc     path_buf0
        stax    $06
        copy16  common_input1_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, str_1_char
        addr_call draw_string, path_buf2
        jsr     L6EA3
        rts

L6A17:  .byte   0
L6A18:  lda     path_buf0
        bne     L6A1E
        rts

L6A1E:  dec     path_buf0
        jsr     L6E45
        stax    $06
        copy16  common_input1_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6EA3
        rts

L6A53:  lda     path_buf0
        bne     L6A59
        rts

L6A59:  ldx     path_buf2
        cpx     #$01
        beq     L6A6B
L6A60:  lda     path_buf2,x
        sta     path_buf2+1,x
        dex
        cpx     #$01
        bne     L6A60
L6A6B:  ldx     path_buf0
        lda     path_buf0,x
        sta     path_buf2+2
        dec     path_buf0
        inc     path_buf2
        jsr     L6E45
        stax    $06
        copy16  common_input1_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6EA3
        rts

L6AAC:  lda     path_buf2
        cmp     #$02
        bcs     L6AB4
        rts

L6AB4:  ldx     path_buf0
        inx
        lda     path_buf2+2
        sta     path_buf0,x
        inc     path_buf0
        ldx     path_buf2
        cpx     #$03
        bcc     L6AD6
        ldx     #$02
L6ACA:  lda     path_buf2+1,x
        sta     path_buf2,x
        inx
        cpx     path_buf2
        bne     L6ACA
L6AD6:  dec     path_buf2
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, common_input1_textpos
        addr_call draw_string, path_buf0
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6EA3
        rts

L6B01:  lda     path_buf0
        bne     L6B07
        rts

L6B07:  ldy     path_buf0
        lda     path_buf2
        cmp     #$02
        bcc     L6B20
        ldx     #$01
L6B13:  iny
        inx
        lda     path_buf2,x
        sta     path_buf0,y
        cpx     path_buf2
        bne     L6B13
L6B20:  sty     path_buf0
L6B23:  lda     path_buf0,y
        sta     path_buf2+1,y
        dey
        bne     L6B23
        ldx     path_buf0
        inx
        stx     path_buf2
        lda     #GLYPH_INSPT
        sta     path_buf2+1
        lda     #$00
        sta     path_buf0
        jsr     jt_03
        jsr     L6EA3
        rts

L6B44:  lda     path_buf2
        cmp     #$02
        bcs     L6B4C
        rts

L6B4C:  ldx     #$01
        ldy     path_buf0
L6B51:  inx
        iny
        lda     path_buf2,x
        sta     path_buf0,y
        cpx     path_buf2
        bne     L6B51
        sty     path_buf0
        copy    #1, path_buf2
        copy    #GLYPH_INSPT, path_buf2+1
        jsr     jt_03
        jsr     L6EA3
        rts

L6B72:  sta     L6BC3
        lda     path_buf1
        clc
        adc     path_buf2
        cmp     #$3F
        bcc     L6B81
        rts

L6B81:  lda     L6BC3
        ldx     path_buf1
        inx
        sta     path_buf1,x
        sta     str_1_char+1
        jsr     L6E72
        inc     path_buf1
        stax    $06
        copy16  common_input2_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, str_1_char
        addr_call draw_string, path_buf2
        jsr     L6E9F
        rts

L6BC3:  .byte   0
L6BC4:  lda     path_buf1
        bne     L6BCA
        rts

L6BCA:  dec     path_buf1
        jsr     L6E72
        stax    $06
        copy16  common_input2_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6E9F
        rts

L6BFF:  lda     path_buf1
        bne     L6C05
        rts

L6C05:  ldx     path_buf2
        cpx     #$01
        beq     L6C17
L6C0C:  lda     path_buf2,x
        sta     path_buf2+1,x
        dex
        cpx     #$01
        bne     L6C0C
L6C17:  ldx     path_buf1
        lda     path_buf1,x
        sta     path_buf2+2
        dec     path_buf1
        inc     path_buf2
        jsr     L6E72
        stax    $06
        copy16  common_input2_textpos+2, $08
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, $06
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6E9F
        rts

L6C58:  lda     path_buf2
        cmp     #$02
        bcs     L6C60
        rts

L6C60:  ldx     path_buf1
        inx
        lda     path_buf2+2
        sta     path_buf1,x
        inc     path_buf1
        ldx     path_buf2
        cpx     #$03
        bcc     L6C82
        ldx     #$02
L6C76:  lda     path_buf2+1,x
        sta     path_buf2,x
        inx
        cpx     path_buf2
        bne     L6C76
L6C82:  dec     path_buf2
        lda     winfo_entrydlg
        jsr     set_port_for_window
        MGTK_RELAY_CALL MGTK::MoveTo, common_input2_textpos
        addr_call draw_string, path_buf1
        addr_call draw_string, path_buf2
        addr_call draw_string, str_2_spaces
        jsr     L6E9F
        rts

L6CAD:  lda     path_buf1
        bne     L6CB3
        rts

L6CB3:  ldy     path_buf1
        lda     path_buf2
        cmp     #$02
        bcc     L6CCC
        ldx     #$01
L6CBF:  iny
        inx
        lda     path_buf2,x
        sta     path_buf1,y
        cpx     path_buf2
        bne     L6CBF
L6CCC:  sty     path_buf1
L6CCF:  lda     path_buf1,y
        sta     path_buf2+1,y
        dey
        bne     L6CCF
        ldx     path_buf1
        inx
        stx     path_buf2
        lda     #GLYPH_INSPT
        sta     path_buf2+1
        lda     #$00
        sta     path_buf1
        jsr     jt_03
        jsr     L6E9F
        rts

L6CF0:  lda     path_buf2
        cmp     #$02
        bcs     L6CF8
        rts

L6CF8:  ldx     #$01
        ldy     path_buf1
L6CFD:  inx
        iny
        lda     path_buf2,x
        sta     path_buf1,y
        cpx     path_buf2
        bne     L6CFD
        sty     path_buf1
        copy    #1, path_buf2
        copy    #GLYPH_INSPT, path_buf2+1
        jsr     jt_03
        jsr     L6E9F
        rts

jump_table:
jt_00:  jmp     0               ; ok button ???
jt_01:  jmp     0               ; cancel button ???
jt_02:  jmp     0               ; input loop
jt_03:  jmp     0
jt_04:  jmp     0
jt_05:  jmp     0
jt_06:  jmp     0
jt_07:  jmp     0
jt_08:  jmp     0               ; delete key ???
jt_09:  jmp     0               ; left key ???
jt_10:  jmp     0               ; right key ???
jt_11:  jmp     0               ; meta-left key ???
jt_12:  jmp     0               ; meta-right key ???
jt_13:  jmp     0               ; click handler ???

L6D48:  stax    $06
        ldx     path_buf0
        lda     #'/'
        sta     path_buf0+1,x
        inc     path_buf0
        ldy     #$00
        lda     ($06),y
        tay
        clc
        adc     path_buf0
        pha
        tax
L6D62:  lda     ($06),y
        sta     path_buf0,x
        dey
        dex
        cpx     path_buf0
        bne     L6D62
        pla
        sta     path_buf0
        rts

L6D73:  stax    $06
        ldx     path_buf1
        lda     #'/'
        sta     path_buf1+1,x
        inc     path_buf1
        ldy     #$00
        lda     ($06),y
        tay
        clc
        adc     path_buf1
        pha
        tax
L6D8D:  lda     ($06),y
        sta     path_buf1,x
        dey
        dex
        cpx     path_buf1
        bne     L6D8D
        pla
        sta     path_buf1
        rts

L6D9E:  ldx     path_buf0
        cpx     #$00
        beq     L6DAF
        dec     path_buf0
        lda     path_buf0,x
        cmp     #'/'
        bne     L6D9E
L6DAF:  rts

L6DB0:  ldx     path_buf1
        cpx     #$00
        beq     L6DC1
        dec     path_buf1
        lda     path_buf1,x
        cmp     #'/'
        bne     L6DB0
L6DC1:  rts

L6DC2:  jsr     L6D9E
        jsr     jt_03
        rts

L6DC9:  jsr     L6DB0
        jsr     jt_03
        rts

L6DD0:  lda     #$00
        beq     L6DD6
L6DD4:  lda     #$80
L6DD6:  sta     L6E1C
        copy16  #$1800, $06
        ldx     $D920
        lda     $1780,x
        and     #$7F
        ldx     #$00
        stx     L6E1B
        asl     a
        rol     L6E1B
        asl     a
        rol     L6E1B
        asl     a
        rol     L6E1B
        asl     a
        rol     L6E1B
        clc
        adc     $06
        tay
        lda     L6E1B
        adc     $07
        tax
        tya
        bit     L6E1C
        bpl     L6E14
        jsr     L6D73
        jmp     L6E17

L6E14:  jsr     L6D48
L6E17:  jsr     jt_03
        rts

L6E1B:  .byte   0
L6E1C:  .byte   0
L6E1D:  ldx     path_buf
L6E20:  lda     path_buf,x
        sta     path_buf0,x
        dex
        bpl     L6E20
        addr_call adjust_filename_case, path_buf0
        rts

L6E31:  ldx     path_buf
:       lda     path_buf,x
        sta     path_buf1,x
        dex
        bpl     :-
        addr_call adjust_filename_case, path_buf1
        rts

L6E45:  lda     #$00
        sta     $09
        sta     $0A
        lda     path_buf0
        beq     L6E63
        sta     $08
        copy16  #path_buf0+1, $06
        MGTK_RELAY_CALL MGTK::TextWidth, $06
L6E63:  lda     $09
        clc
        adc     common_input1_textpos
        tay
        lda     $0A
        adc     common_input1_textpos+1
        tax
        tya
        rts

L6E72:  lda     #$00
        sta     $09
        sta     $0A
        lda     path_buf1
        beq     L6E90
        sta     $08
        copy16  #path_buf1+1, $06
        MGTK_RELAY_CALL MGTK::TextWidth, $06
L6E90:  lda     $09
        clc
        adc     common_input2_textpos
        tay
        lda     $0A
        adc     common_input2_textpos+1
        tax
        tya
        rts

L6E9F:  lda     #$FF
        bmi     L6EA5
L6EA3:  lda     #$00
L6EA5:  bmi     L6EB6
        ldx     path_buf0
L6EAA:  lda     path_buf0,x
        sta     $D3C1,x
        dex
        bpl     L6EAA
        jmp     L6EC2

L6EB6:  ldx     path_buf1
L6EB9:  lda     path_buf1,x
        sta     $D3C1,x
        dex
        bpl     L6EB9
L6EC2:  lda     $D920
        sta     L6F3D
        bmi     L6EFB
        ldx     #$00
        stx     $06
        ldx     #$18
        stx     $07
        ldx     #$00
        stx     L6F3C
        tax
        lda     $1780,x
        and     #$7F
        asl     a
        rol     L6F3C
        asl     a
        rol     L6F3C
        asl     a
        rol     L6F3C
        asl     a
        rol     L6F3C
        clc
        adc     $06
        tay
        lda     L6F3C
        adc     $07
        tax
        tya
        jsr     L5F0D
L6EFB:  addr_call adjust_filename_case, $D3C1
        addr_call adjust_filename_case, path_buf
        lda     $D3C1
        cmp     path_buf
        bne     L6F26
        tax
L6F12:  lda     $D3C1,x
        cmp     path_buf,x
        bne     L6F26
        dex
        bne     L6F12
        lda     #$00
        sta     $D8F0
        jsr     L6F2F
        rts

L6F26:  lda     #$FF
        sta     $D8F0
        jsr     L6F2F
        rts

L6F2F:  lda     L6F3D
        sta     $D920
        bpl     L6F38
        rts

L6F38:  jsr     L5F49
        rts

L6F3C:  .byte   0
L6F3D:  .byte   0

;;; ============================================================

        PAD_TO $7000

.endproc ; common_overlay
