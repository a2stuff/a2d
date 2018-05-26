;;; ============================================================
;;; DeskTop - Main Memory Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into AUX $851F-$BFFF (follows MGTK)
;;; ============================================================
.proc desktop_aux

        .org $851F

;;; ============================================================
;;; This chunk of code appears to be used by one of
;;; the dynamically loaded segments.

        .include "ovl0.inc"

;;; ============================================================

        .assert * = DEFAULT_FONT, error, "Entry point mismatch"
        .incbin "../fonts/A2D.FONT"

        font_height     := DEFAULT_FONT+2

;;; ============================================================

        .assert * = $8D03, error, "Segment length mismatch"
        PAD_TO $8E00

;;; ============================================================
;;; Entry point for "DESKTOP"
;;; ============================================================

        .assert * = DESKTOP, error, "DESKTOP entry point must be at $8E00"

        jmp     DESKTOP_DIRECT


;;; ============================================================

.macro MGTK_RELAY2_CALL call, addr
    .if .paramcount > 1
        yax_call MGTK_RELAY2, (call), (addr)
    .else
        yax_call MGTK_RELAY2, (call), 0
    .endif
.endmacro

.proc poly
num_vertices:   .byte   8
lastpoly:       .byte   0       ; 0 = last poly
vertices:
v0:     DEFINE_POINT 0, 0, v0
v1:     DEFINE_POINT 0, 0, v1
v2:     DEFINE_POINT 0, 0, v2
v3:     DEFINE_POINT 0, 0, v3
v4:     DEFINE_POINT 0, 0, v4
v5:     DEFINE_POINT 0, 0, v5
v6:     DEFINE_POINT 0, 0, v6
v7:     DEFINE_POINT 0, 0, v7
.endproc

.proc paintbits_params2
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
maprect:        DEFINE_RECT 0,0,0,0,maprect
.endproc

.proc paintbits_params
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
maprect:        DEFINE_RECT 0,0,0,0,maprect
.endproc

paintrect_params6:      DEFINE_RECT 0,0,0,0, paintrect_params6

.proc textwidth_params
textptr:        .addr   text_buffer
textlen:        .byte   0
result: .word   0
.endproc
settextbg_params    := textwidth_params::result + 1  ; re-used

.proc drawtext_params
textptr:        .addr   text_buffer
textlen:        .byte   0
.endproc

text_buffer:
        .res    19, 0

white_pattern:
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   $FF

black_pattern:
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   $FF

checkerboard_pattern2:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   $FF

dark_pattern:
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   $FF

light_pattern:
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011
        .byte   $FF

;;; ============================================================
;;; Icon (i.e. file, volume) details

num_icons:  .byte   0
icon_table: .res    127, 0      ; index into icon_ptrs
icon_ptrs:  .res    256, 0      ; addresses of icon details

has_highlight:                  ; 1 = has highlight, 0 = no highlight
        .byte   0
highlight_count:                ; number of highlighted icons
        .byte   0
highlight_list:                 ; selected icons
        .res    127, 0

;;; Polygon holding the composite outlines of all icons
;;; being dragged.

drag_outline_buffer:
        .res    680, 0

;;; ============================================================

.proc peekevent_params
kind:   .byte   0               ; spills into next block
.endproc

.proc findwindow_params2
mousex: .word   0
mousey: .word   0
which_area:     .byte   0
window_id:      .byte   0
.endproc

.proc grafport
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, screen_width-1, screen_height-1
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc: DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   $96     ; ???
textbg: .byte   MGTK::textbg_black
fontptr:        .addr   DEFAULT_FONT
.endproc

.proc getwinport_params
window_id:      .byte   0
a_grafport:     .addr   grafport4
.endproc

.proc grafport4
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   0
mapwidth:       .word   0
cliprect:       DEFINE_RECT 0, 0, 0, 0, cliprect
penpattern:     .res    8, 0
colormasks:     .byte   0, 0
penloc: DEFINE_POINT 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textbg: .byte   MGTK::textbg_black
fontptr:        .addr   0
.endproc

        .byte   $00,$00,$00
        .byte   $00,$FF,$80

        ;; Used for FILL_MODE params
pencopy_2:      .byte   0
penOR_2:        .byte   1
penXOR_2:       .byte   2
penBIC_2:       .byte   3
notpencopy_2:   .byte   4
notpenOR_2:     .byte   5
notpenXOR_2:    .byte   6
notpenBIC_2:    .byte   7

;;; ============================================================
;;; DESKTOP command jump table

desktop_jump_table:
        .addr   0               ; $00
        .addr   ADD_ICON_IMPL
        .addr   HIGHLIGHT_ICON_IMPL
        .addr   REDRAW_ICON_IMPL
        .addr   UNHIGHLIGHT_ICON_IMPL
        .addr   HIGHLIGHT_ALL_IMPL
        .addr   UNHIGHLIGHT_ALL_IMPL
        .addr   CLOSE_WINDOW_IMPL
        .addr   GET_HIGHLIGHTED_IMPL
        .addr   FIND_ICON_IMPL
        .addr   L97F7           ; $0A
        .addr   L9EBE           ; $0B
        .addr   REDRAW_ICONS_IMPL
        .addr   ICON_IN_RECT_IMPL
        .addr   REDRAW_ICON_IDX_IMPL

.macro  DESKTOP_DIRECT_CALL    op, addr, label
        jsr DESKTOP_DIRECT
        .byte   op
        .addr   addr
.endmacro

;;; DESKTOP entry point (after jump)

.proc DESKTOP_DIRECT

        ;; Stash return value from stack, adjust by 3
        ;; (command byte, params addr)
        pla
        sta     call_params
        clc
        adc     #<3
        tax
        pla
        sta     call_params+1
        adc     #>3
        pha
        txa
        pha

        ;; Save $06..$09 on the stack
        ldx     #0
:       lda     $06,x
        pha
        inx
        cpx     #4
        bne     :-

        ;; Point ($06) at call command
        add16   call_params, #1, $06

        ldy     #0
        lda     ($06),y
        asl     a
        tax
        copy16  desktop_jump_table,x, dispatch + 1
        iny
        lda     ($06),y
        tax
        iny
        lda     ($06),y
        sta     $07
        stx     $06

dispatch:
        jsr     dummy0000

        tay
        ldx     #3
L9409:  pla
        sta     $06,x
        dex
        cpx     #$FF
        bne     L9409
        tya
        rts

call_params:  .addr     0
.endproc

.proc moveto_params2
xcoord: .word   0
ycoord: .word   0
.endproc

;;; ============================================================
;;; ADD_ICON IMPL

.proc ADD_ICON_IMPL
        PARAM_BLOCK params, $06
ptr_icon:       .addr   0
        END_PARAM_BLOCK

        ldy     #0
        lda     (params::ptr_icon),y
        ldx     num_icons
        beq     proceed
        dex
:       cmp     icon_table,x
        beq     fail
        dex
        bpl     :-
        bmi     proceed
fail:   return  #1

proceed:
        jsr     sub
        jsr     L9F98
        lda     #1
        tay
        sta     (params::ptr_icon),y
        return  #0

sub:    ldx     num_icons       ; ???
        sta     icon_table,x
        inc     num_icons
        asl     a
        tax
        copy16  params::ptr_icon, icon_ptrs,x
        rts
.endproc

;;; ============================================================
;;; HIGHLIGHT_ICON IMPL

.proc HIGHLIGHT_ICON_IMPL
        PARAM_BLOCK params, $06
ptr_icon:       .addr   0
        END_PARAM_BLOCK
        ptr := $06              ; Overwrites param

        ldx     num_icons
        beq     bail1
        dex
        ldy     #0
        lda     (params::ptr_icon),y
L945E:  cmp     icon_table,x
        beq     L9469
        dex
        bpl     L945E

bail1:  return  #1              ; Not found

L9469:  asl     a
        tax
        copy16  icon_ptrs,x, ptr
        ldy     #IconEntry::state
        lda     (ptr),y
        bne     L947E           ; Already set ??? Routine semantics are incorrect ???
        return  #2

L947E:  lda     has_highlight
        beq     L9498

        ;; Already in highlight list?
        dey
        lda     (ptr),y
        ldx     highlight_count
        dex
L948A:  cmp     highlight_list,x
        beq     bail3
        dex
        bpl     L948A
        jmp     L949D

bail3:  return  #3              ; Already in list

L9498:  lda     #1
        sta     has_highlight

        ;; Append to highlight list
L949D:  ldx     highlight_count
        ldy     #0
        lda     (ptr),y
        sta     highlight_list,x
        inc     highlight_count

        lda     (ptr),y ; icon num
        ldx     #1                   ; new position
        jsr     change_highlight_index
        ldy     #0
        lda     (ptr),y
        ldx     #1
        jsr     LA2E3
        jsr     L9F9F
        return  #0              ; Highlighted
.endproc

;;; ============================================================
;;; REDRAW_ICON IMPL

.proc REDRAW_ICON_IMPL
        PARAM_BLOCK params, $06
ptr_icon:       .addr   0
        END_PARAM_BLOCK
        ptr := $06              ; Overwrites param

        ;; Find icon by number
        ldx     num_icons
        beq     bail1
        dex
        ldy     #0
        lda     (params::ptr_icon),y
:       cmp     icon_table,x
        beq     found
        dex
        bpl     :-

bail1:  return  #1              ; Not found

        ;; Pointer to icon details
found:  asl     a
        tax
        copy16  icon_ptrs,x, ptr

        lda     has_highlight   ; Anything highlighted?
        bne     :+
        jmp     done

:       ldx     highlight_count
        dex
        ldy     #0
        lda     (ptr),y

        ;; Find in highlight list
:       cmp     highlight_list,x
        beq     found2
        dex
        bpl     :-
        jmp     done

found2: jsr     L9F9F
        return  #0

done:   jsr     L9F98
        return  #0
.endproc

;;; ============================================================
;;; UNHIGHLIGHT_ICON IMPL

.proc UNHIGHLIGHT_ICON_IMPL
        PARAM_BLOCK params, $06
ptr_icon:       .addr   0
        END_PARAM_BLOCK
        ptr := $06              ; Overwrites param

        ;; Find icon by number
        ldy     #0
        ldx     num_icons
        beq     bail1
        dex
        lda     (params::ptr_icon),y
:       cmp     icon_table,x
        beq     found
        dex
        bpl     :-

bail1:  return  #1              ; Not found

        ;; Pointer to icon details
found:  asl     a
        tax
        copy16  icon_ptrs,x, ptr
        ldy     #IconEntry::state
        lda     (ptr),y
        bne     :+

        return  #2              ; Not highlighted

        ;; Unhighlight
:       jsr     calc_icon_poly
        MGTK_CALL MGTK::SetPenMode, pencopy_2
        jsr     draw_icon
        ldy     #0
        lda     (ptr),y
        ldx     num_icons
        jsr     LA2E3
        dec     num_icons
        lda     #0
        ldx     num_icons
        sta     icon_table,x
        ldy     #IconEntry::state
        lda     #0
        sta     (ptr),y
        lda     has_highlight
        beq     done

        ldx     highlight_count
        dex
        ldy     #0
        lda     (ptr),y
L9566:  cmp     highlight_list,x
        beq     L9571
        dex
        bpl     L9566

        jmp     done

L9571:  ldx     highlight_count ; new position
        jsr     change_highlight_index
        dec     highlight_count
        lda     highlight_count
        bne     L9584
        lda     #0
        sta     has_highlight
L9584:  lda     #0
        ldx     highlight_count
        sta     highlight_list,x

done:   return  #0              ; Unhighlighted
.endproc

;;; ============================================================
;;; REDRAW_ICON_IDX IMPL

.proc REDRAW_ICON_IDX_IMPL
        PARAM_BLOCK params, $06
ptr_icon_idx:   .addr   0
        END_PARAM_BLOCK
        ptr := $06              ; Overwrites param

        ldy     #0
        lda     (params::ptr_icon_idx),y
        asl     a
        tax
        copy16  icon_ptrs,x, ptr
        jmp     draw_icon
.endproc

;;; ============================================================
;;; HIGHLIGHT_ALL IMPL

;;; Highlight all icons in the specified window.
;;; (Unused?)

.proc HIGHLIGHT_ALL_IMPL
        jmp     start

        PARAM_BLOCK params, $06
ptr_window_id:      .addr    0
        END_PARAM_BLOCK

        ptr := $08

        ;; DT_HIGHLIGHT_ICON params
icon:   .byte   0

buffer: .res    127, 0

start:  lda     HIGHLIGHT_ICON_IMPL ; ???
        beq     start2
        lda     highlight_list
        sta     icon
        DESKTOP_DIRECT_CALL $0B, icon
        jmp     start

start2:
        ;; Zero out buffer
        ldx     #max_icon_count-1
        lda     #0
:       sta     buffer,x
        dex
        bpl     :-
        ldx     #0
        stx     icon

        ;; Walk through icons, find ones in the same window
        ;; as the entry at ($06).
loop:   lda     icon_table,x
        asl     a
        tay
        copy16  icon_ptrs,y, ptr
        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #icon_entry_winid_mask
        ldy     #0
        cmp     (params::ptr_window_id),y
        bne     :+

        ;; Append icon number to buffer.
        ldy     #0
        lda     (ptr),y
        ldy     icon
        sta     buffer,y
        inc     icon

:       inx
        cpx     num_icons
        bne     loop

        ldx     #0
        txa
        pha

        ;; Highlight all the icons.
loop2:  lda     buffer,x
        bne     :+
        pla
        rts

:       sta     icon
        DESKTOP_DIRECT_CALL DT_HIGHLIGHT_ICON, icon
        pla
        tax
        inx
        txa
        pha
        jmp     loop2
.endproc

;;; ============================================================
;;; UNHIGHLIGHT_ALL IMPL

.proc UNHIGHLIGHT_ALL_IMPL
        jmp     L9697

L9695:  .byte   0
L9696:  .byte   0

L9697:  lda     num_icons
        sta     L9696
L969D:  ldx     L9696
        cpx     #0
        beq     L96CF
        dec     L9696
        dex
        lda     icon_table,x
        sta     L9695
        asl     a
        tax
        copy16  icon_ptrs,x, $08
        ldy     #IconEntry::win_type
        lda     ($08),y
        and     #icon_entry_winid_mask
        ldy     #0
        cmp     ($06),y
        bne     L969D
        DESKTOP_DIRECT_CALL DT_UNHIGHLIGHT_ICON, L9695
        jmp     L969D
L96CF:  return  #0
.endproc

;;; ============================================================
;;; CLOSE_WINDOW IMPL

.proc CLOSE_WINDOW_IMPL
        jmp     L96D7

L96D5:  .byte   0
L96D6:  .byte   0

L96D7:  lda     num_icons
        sta     L96D6
L96DD:  ldx     L96D6
        bne     L96E5
        return  #0

L96E5:  dec     L96D6
        dex
        lda     icon_table,x
        sta     L96D5
        asl     a
        tax
        copy16  icon_ptrs,x, $08
        ldy     #IconEntry::win_type
        lda     ($08),y
        and     #icon_entry_winid_mask
        ldy     #0
        cmp     ($06),y
        bne     L96DD
        ldy     #0
        lda     ($08),y
        ldx     num_icons
        jsr     LA2E3
        dec     num_icons
        lda     #0
        ldx     num_icons
        sta     icon_table,x
        ldy     #IconEntry::state
        lda     #0
        sta     ($08),y
        lda     has_highlight
        beq     L9758
        ldx     #0
        ldy     #0
L972B:  lda     ($08),y
        cmp     highlight_list,x
        beq     L973B
        inx
        cpx     highlight_count
        bne     L972B
        jmp     L9758

L973B:  lda     ($08),y         ; icon num
        ldx     highlight_count ; new position
        jsr     change_highlight_index
        dec     highlight_count
        lda     highlight_count
        bne     L9750
        lda     #0
        sta     has_highlight
L9750:  lda     #0
        ldx     highlight_count
        sta     highlight_list,x
L9758:  jmp     L96DD
.endproc

;;; ============================================================
;;; GET_HIGHLIGHTED IMPL

;;; Copies first 20 highlighted icon numbers to ($06)

.proc GET_HIGHLIGHTED_IMPL
        ldx     #0
        txa
        tay
:       sta     ($06),y
        iny
        inx
        cpx     #20             ; 20 items
        bne     :-

        ldx     #0
        ldy     #0
:       lda     highlight_list,x
        sta     ($06),y
        cpx     highlight_count
        beq     done
        iny
        inx
        jmp     :-

done:   return  #0
.endproc

;;; ============================================================
;;; FIND_ICON IMPL

.proc FIND_ICON_IMPL
        jmp     start

        .res    9, 0            ; ???


        coords := $6

        ;; Copy coords at $6 to param block
start:  ldy     #3
:       lda     (coords),y
        sta     moveto_params2,y
        dey
        bpl     :-

        ;; Overwrite y with x ???
        copy16  $06, $08

        ;; ???
        ldy     #5
        lda     ($06),y
        sta     L97F5
        MGTK_CALL MGTK::MoveTo, moveto_params2
        ldx     #0
L97AA:  cpx     num_icons
        bne     L97B9
        ldy     #4
        lda     #0
        sta     ($08),y
        sta     L97F6
        rts

L97B9:  txa
        pha
        lda     icon_table,x
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        cmp     L97F5
        bne     L97E0
        jsr     calc_icon_poly
        MGTK_CALL MGTK::InPoly, poly
        bne     inside
L97E0:  pla
        tax
        inx
        jmp     L97AA

inside: pla
        tax
        lda     icon_table,x
        ldy     #4
        sta     ($08),y
        sta     L97F6
        rts

        rts                     ; ???

        .byte   0
L97F5:  .byte   0
L97F6:  .byte   0
.endproc

;;; ============================================================

;;; DESKTOP $0A IMPL

        ;; Desktop icon selection
.proc L97F7
        ldy     #0
        lda     ($06),y
        sta     L982A
        tya
        sta     ($06),y
        ldy     #4
L9803:  lda     ($06),y
        sta     L9C8D,y
        sta     L9C91,y
        dey
        cpy     #0
        bne     L9803
        jsr     push_zp_addrs
        lda     L982A
        jsr     L9EB4
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        sta     L9829
        jmp     L983D

L9829:  .byte   $00
L982A:  .byte   $00,$00
L982C:  .byte   $00
L982D:  .byte   $00
L982E:  .byte   $00
L982F:  .byte   $00

        ;; DT_HIGHLIGHT_ICON params
L9830:  .byte   $00

L9831:  .byte   $00
L9832:  .byte   $00
L9833:  .byte   $00
L9834:  .byte   $00
L9835:  .byte   $00,$00,$00,$00,$00,$00,$00,$00

L983D:  lda     #0
        sta     L9830
        sta     L9833
L9845:  MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::event_kind_drag
        beq     L9857
L9852:  lda     #$02
        jmp     L9C65

L9857:  sub16   findwindow_params2::mousex, L9C8E, L982C
        sub16   findwindow_params2::mousey, L9C90, L982E

        lda     L982D
        bpl     L988C
        lda     L982C
        cmp     #$FB
        bcc     L98AC
        jmp     L9893

L988C:  lda     L982C
        cmp     #$05
        bcs     L98AC
L9893:  lda     L982F
        bpl     L98A2
        lda     L982E
        cmp     #$FB
        bcc     L98AC
        jmp     L9845

L98A2:  lda     L982E
        cmp     #$05
        bcs     L98AC
        jmp     L9845

L98AC:  lda     highlight_count
        cmp     #$15            ; max number of draggable items?
        bcc     :+
        jmp     L9852

:       copy16  #drag_outline_buffer, $08
        lda     has_highlight
        bne     :+
        lda     #$03
        jmp     L9C65

:       lda     highlight_list
        jsr     L9EB4
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        sta     L9832
        MGTK_CALL MGTK::InitPort, grafport
        ldx     #7
L98E3:  lda     grafport::cliprect,x
        sta     L9835,x
        dex
        bpl     L98E3
        ldx     highlight_count
        stx     L9C74
L98F2:  lda     highlight_count,x
        jsr     L9EB4
        stax    $06
        ldy     #0
        lda     ($06),y
        cmp     #1
        bne     L9909
        ldx     #$80
        stx     L9833
L9909:  sta     L9834
        DESKTOP_DIRECT_CALL DT_ICON_IN_RECT, L9834
        beq     L9954
        jsr     calc_icon_poly
        lda     L9C74
        cmp     highlight_count
        beq     L9936
        jsr     push_zp_addrs
        lda     $08
        sec
        sbc     #$22
        sta     $08
        bcs     L992D
        dec     $08+1
L992D:  ldy     #IconEntry::state
        lda     #$80            ; Highlighted
        sta     ($08),y
        jsr     pop_zp_addrs
L9936:  ldx     #$21
        ldy     #$21
L993A:  lda     poly,x
        sta     ($08),y
        dey
        dex
        bpl     L993A
        lda     #8
        ldy     #0
        sta     ($08),y
        lda     $08
        clc
        adc     #$22
        sta     $08
        bcc     L9954
        inc     $08+1
L9954:  dec     L9C74
        beq     L995F
        ldx     L9C74
        jmp     L98F2

L995F:  ldx     #7
L9961:  lda     drag_outline_buffer+2,x
        sta     L9C76,x
        dex
        bpl     L9961
        copy16  #drag_outline_buffer, $08
L9972:  ldy     #IconEntry::win_type
L9974:  lda     ($08),y
        cmp     L9C76
        iny
        lda     ($08),y
        sbc     L9C77
        bcs     L9990
        lda     ($08),y
        sta     L9C77
        dey
        lda     ($08),y
        sta     L9C76
        iny
        jmp     L99AA

L9990:  dey
        lda     ($08),y
        cmp     L9C7A
        iny
        lda     ($08),y
        sbc     L9C7B
        bcc     L99AA
        lda     ($08),y
        sta     L9C7B
        dey
        lda     ($08),y
        sta     L9C7A
        iny
L99AA:  iny
        lda     ($08),y
        cmp     L9C78
        iny
        lda     ($08),y
        sbc     L9C79
        bcs     L99C7
        lda     ($08),y
        sta     L9C79
        dey
        lda     ($08),y
        sta     L9C78
        iny
        jmp     L99E1

L99C7:  dey
        lda     ($08),y
        cmp     L9C7C
        iny
        lda     ($08),y
        sbc     L9C7D
        bcc     L99E1
        lda     ($08),y
        sta     L9C7D
        dey
        lda     ($08),y
        sta     L9C7C
        iny
L99E1:  iny
        cpy     #$22
        bne     L9974
        ldy     #IconEntry::state
        lda     ($08),y
        beq     L99FC
        add16   $08, #34, $08
        jmp     L9972

L99FC:  MGTK_CALL MGTK::SetPattern, checkerboard_pattern2
        MGTK_CALL MGTK::SetPenMode, penXOR_2
        MGTK_CALL MGTK::FramePoly, drag_outline_buffer
L9A0E:  MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::event_kind_drag
        beq     L9A1E
        jmp     L9BA5

L9A1E:  ldx     #3
L9A20:  lda     findwindow_params2,x
        cmp     L9C92,x
        bne     L9A31
        dex
        bpl     L9A20
        jsr     L9E14
        jmp     L9A0E

L9A31:  ldx     #3
L9A33:  lda     findwindow_params2,x
        sta     L9C92,x
        dex
        bpl     L9A33
        lda     L9830
        beq     L9A84
        lda     L9831
        sta     findwindow_params2::window_id
        DESKTOP_DIRECT_CALL DT_FIND_ICON, findwindow_params2
        lda     findwindow_params2::which_area
        cmp     L9830
        beq     L9A84
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern2
        MGTK_CALL MGTK::SetPenMode, penXOR_2
        MGTK_CALL MGTK::FramePoly, drag_outline_buffer
        DESKTOP_DIRECT_CALL $0B, L9830
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern2
        MGTK_CALL MGTK::SetPenMode, penXOR_2
        MGTK_CALL MGTK::FramePoly, drag_outline_buffer
        lda     #0
        sta     L9830
L9A84:  sub16   findwindow_params2::mousex, L9C8E, L9C96
        sub16   findwindow_params2::mousey, L9C90, L9C98
        jsr     L9C9E
        ldx     #0
L9AAF:  add16   L9C7A,x, L9C96,x, L9C7A,x
        add16   L9C76,x, L9C96,x, L9C76,x
        inx
        inx
        cpx     #4
        bne     L9AAF
        lda     #0
        sta     L9C75
        lda     L9C77
        bmi     L9AF7
        cmp16   L9C7A, #screen_width
        bcs     L9AFE
        jsr     L9DFA
        jmp     L9B0E

L9AF7:  jsr     L9CAA
        bmi     L9B0E
        bpl     L9B03
L9AFE:  jsr     L9CD1
        bmi     L9B0E
L9B03:  jsr     L9DB8
        lda     L9C75
        ora     #$80
        sta     L9C75
L9B0E:  lda     L9C79
        bmi     L9B31
        cmp16   L9C78, #13
        bcc     L9B31
        cmp16   L9C7C, #screen_height
        bcs     L9B38
        jsr     L9E07
        jmp     L9B48

L9B31:  jsr     L9D31
        bmi     L9B48
        bpl     L9B3D
L9B38:  jsr     L9D58
        bmi     L9B48
L9B3D:  jsr     L9DD9
        lda     L9C75
        ora     #$40
        sta     L9C75
L9B48:  bit     L9C75
        bpl     L9B52
        bvc     L9B52
        jmp     L9A0E

L9B52:  MGTK_CALL MGTK::FramePoly, drag_outline_buffer
        copy16  #drag_outline_buffer, $08
L9B60:  ldy     #2
L9B62:  lda     ($08),y
        clc
        adc     L9C96
        sta     ($08),y
        iny
        lda     ($08),y
        adc     L9C97
        sta     ($08),y
        iny
        lda     ($08),y
        clc
        adc     L9C98
        sta     ($08),y
        iny
        lda     ($08),y
        adc     L9C99
        sta     ($08),y
        iny
        cpy     #$22
        bne     L9B62
        ldy     #IconEntry::state
        lda     ($08),y
        beq     L9B9C
        lda     $08
        clc
        adc     #$22
        sta     $08
        bcc     L9B99
        inc     $08+1
L9B99:  jmp     L9B60

L9B9C:  MGTK_CALL MGTK::FramePoly, drag_outline_buffer
        jmp     L9A0E

L9BA5:  MGTK_CALL MGTK::FramePoly, drag_outline_buffer
        lda     L9830
        beq     L9BB9
        DESKTOP_DIRECT_CALL $0B, L9830
        jmp     L9C63

L9BB9:  MGTK_CALL MGTK::FindWindow, findwindow_params2
        lda     findwindow_params2::window_id
        cmp     L9832
        beq     L9BE1
        bit     L9833
        bmi     L9BDC
        lda     findwindow_params2::window_id
        bne     L9BD4
L9BD1:  jmp     L9852

L9BD4:  ora     #$80
        sta     L9830
        jmp     L9C63

L9BDC:  lda     L9832
        beq     L9BD1
L9BE1:  jsr     push_zp_addrs
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        ldx     highlight_count
L9BF3:  dex
        bmi     L9C18
        txa
        pha
        lda     highlight_list,x
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        jsr     calc_icon_poly
        MGTK_CALL MGTK::SetPenMode, pencopy_2
        jsr     draw_icon
        pla
        tax
        jmp     L9BF3

L9C18:  jsr     pop_zp_addrs
        ldx     highlight_count
        dex
        txa
        pha
        copy16  #drag_outline_buffer, $08
L9C29:  lda     highlight_list,x
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        ldy     #IconEntry::win_type
        lda     ($08),y
        iny
        sta     ($06),y
        lda     ($08),y
        iny
        sta     ($06),y
        lda     ($08),y
        iny
        sta     ($06),y
        lda     ($08),y
        iny
        sta     ($06),y
        pla
        tax
        dex
        bmi     L9C63
        txa
        pha
        lda     $08
        clc
        adc     #$22
        sta     $08
        bcc     L9C60
        inc     $08+1
L9C60:  jmp     L9C29

L9C63:  lda     #0
L9C65:  tay
        jsr     pop_zp_addrs
        tya
        tax
        ldy     #0
        lda     L9830
        sta     ($06),y
        txa
        rts

L9C74:  .byte   $00
L9C75:  .byte   $00
L9C76:  .byte   $00
L9C77:  .byte   $00
L9C78:  .byte   $00
L9C79:  .byte   $00
L9C7A:  .byte   $00
L9C7B:  .byte   $00
L9C7C:  .byte   $00
L9C7D:  .byte   $00
L9C7E:  .byte   $00
L9C7F:  .byte   $00
L9C80:  .byte   $0D
L9C81:  .byte   $00
L9C82:  .byte   $30
L9C83:  .byte   $02
L9C84:  .byte   $C0
L9C85:  .byte   $00
L9C86:  .word   0
L9C88:  .word   0
L9C8A:  .word   0
L9C8C:  .byte   $00
L9C8D:  .byte   $00
L9C8E:  .byte   $00
L9C8F:  .byte   $00
L9C90:  .byte   $00
L9C91:  .byte   $00
L9C92:  .byte   $00,$00,$00,$00
L9C96:  .byte   $00
L9C97:  .byte   $00
L9C98:  .byte   $00
L9C99:  .byte   $00,$00,$00,$00,$00
L9C9E:  ldx     #7
L9CA0:  lda     L9C76,x
        sta     L9C86,x
        dex
        bpl     L9CA0
        rts

L9CAA:  lda     L9C76
        cmp     L9C7E
        bne     L9CBD
        lda     L9C77
        cmp     L9C7F
        bne     L9CBD
        return  #0

L9CBD:  sub16   #0, L9C86, L9C96
        jmp     L9CF5

L9CD1:  lda     L9C7A
        cmp     L9C82
        bne     L9CE4
        lda     L9C7B
        cmp     L9C83
        bne     L9CE4
        return  #0

L9CE4:  sub16   #screen_width, L9C8A, L9C96
L9CF5:  add16   L9C86, L9C96, L9C76
        add16   L9C8A, L9C96, L9C7A
        add16   L9C8E, L9C96, L9C8E
        return  #$FF

L9D31:  lda     L9C78
        cmp     L9C80
        bne     L9D44
        lda     L9C79
        cmp     L9C81
        bne     L9D44
        return  #0

L9D44:  sub16   #13, L9C88, L9C98
        jmp     L9D7C

L9D58:  lda     L9C7C
        cmp     L9C84
        bne     L9D6B
        lda     L9C7D
        cmp     L9C85
        bne     L9D6B
        return  #0

L9D6B:  sub16   #screen_height-1, L9C8C, L9C98
L9D7C:  add16   L9C88, L9C98, L9C78
        add16   L9C8C, L9C98, L9C7C
        add16   L9C90, L9C98, L9C90
        return  #$FF

L9DB8:  copy16  L9C86, L9C76
        copy16  L9C8A, L9C7A
        lda     #0
        sta     L9C96
        sta     L9C97
        rts

L9DD9:  copy16  L9C88, L9C78
        copy16  L9C8C, L9C7C
        lda     #0
        sta     L9C98
        sta     L9C99
        rts

L9DFA:  lda     findwindow_params2::mousex+1
        sta     L9C8F
        lda     findwindow_params2::mousex
        sta     L9C8E
        rts

L9E07:  lda     findwindow_params2::mousey+1
        sta     L9C91
        lda     findwindow_params2::mousey
        sta     L9C90
        rts

L9E14:  bit     L9833
        bpl     L9E1A
        rts

L9E1A:  jsr     push_zp_addrs
        MGTK_CALL MGTK::FindWindow, findwindow_params2
        lda     findwindow_params2::which_area
        bne     L9E2B
        sta     findwindow_params2::window_id
L9E2B:  DESKTOP_DIRECT_CALL DT_FIND_ICON, findwindow_params2
        lda     findwindow_params2::which_area
        bne     L9E39
        jmp     L9E97

L9E39:  ldx     highlight_count
        dex
L9E3D:  cmp     highlight_list,x
        beq     L9E97
        dex
        bpl     L9E3D
        sta     L9EB3
        cmp     #1
        beq     L9E6A
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        sta     L9831
        lda     ($06),y
        and     #$70            ; type
        bne     L9E97
        lda     L9EB3
L9E6A:  sta     L9830
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern2
        MGTK_CALL MGTK::SetPenMode, penXOR_2
        MGTK_CALL MGTK::FramePoly, drag_outline_buffer
        DESKTOP_DIRECT_CALL DT_HIGHLIGHT_ICON, L9830
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern2
        MGTK_CALL MGTK::SetPenMode, penXOR_2
        MGTK_CALL MGTK::FramePoly, drag_outline_buffer
L9E97:  MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern2
        MGTK_CALL MGTK::SetPenMode, penXOR_2
        jsr     pop_zp_addrs
        rts

L9EB3:  .byte   0
L9EB4:  asl     a
        tay
        lda     icon_ptrs+1,y
        tax
        lda     icon_ptrs,y
        rts
.endproc

;;; ============================================================

;;; DESKTOP $0B IMPL

        ;; Deselect icon ???

.proc L9EBE
        jmp     start

        .byte   0               ; ???

        ;; DT_REDRAW_ICON params
icon:   .byte   0

        ptr := $6

start:  lda     has_highlight
        bne     :+
        return  #1              ; No selection

        ;; Move it to the end of the highlight list
:       ldx     highlight_count ; new position
        ldy     #0
        lda     (ptr),y         ; icon num
        jsr     change_highlight_index

        ;; Remove it from the list
        ldx     highlight_count
        lda     #0
        sta     highlight_count,x
        dec     highlight_count

        ;; Update flag
        lda     highlight_count
        bne     :+
        lda     #0
        sta     has_highlight

        ;; Redraw
:       ldy     #0
        lda     (ptr),y
        sta     icon
        DESKTOP_DIRECT_CALL DT_REDRAW_ICON, icon
        return  #0
.endproc

        rts                     ; unused

;;; ============================================================
;;; ICON_IN_RECT IMPL

.proc ICON_IN_RECT_IMPL
        jmp     start

icon:   .byte   0
rect:   DEFINE_RECT 0,0,0,0,rect

start:  ldy     #0
        lda     ($06),y
        sta     icon
        ldy     #8
:       lda     ($06),y
        sta     rect-1,y
        dey
        bne     :-

        lda     icon
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        jsr     calc_icon_poly

        cmp16   poly::v0::ycoord, rect::y2
        bpl     done

        cmp16   poly::v5::ycoord, rect::y1
        bmi     done

        cmp16   poly::v5::xcoord, rect::x2
        bpl     done

        cmp16   poly::v4::xcoord, rect::x1
        bmi     done

        cmp16   poly::v7::ycoord, rect::y2
        bmi     L9F8F

        cmp16   poly::v7::xcoord, rect::x2
        bpl     done

        cmp16   poly::v2::xcoord, rect::x1
        bpl     L9F8F

done:   return  #0

L9F8F:  return  #1
.endproc

;;; ============================================================

L9F92:  .byte   0
L9F93:  .byte   0
L9F94:  .byte   0
        .byte   0
        .byte   0
        .byte   0

L9F98:  lda     #0
        sta     L9F92
        beq     L9FA4

L9F9F:  lda     #$80
        sta     L9F92

.proc L9FA4
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        bne     :+
        lda     L9F92
        ora     #$40
        sta     L9F92
        ;; copy icon coords and bits
:       ldy     #IconEntry::iconx
:       lda     ($06),y
        sta     paintbits_params2::viewloc-IconEntry::iconx,y
        iny
        cpy     #IconEntry::iconx + 6 ; x/y/bits
        bne     :-

        jsr     push_zp_addrs
        copy16  paintbits_params2::mapbits, $08
        ldy     #11
:       lda     ($08),y
        sta     paintbits_params2::mapbits,y
        dey
        bpl     :-

        bit     L9F92
        bpl     :+
        jsr     LA12C
:       jsr     pop_zp_addrs

        ldy     #9
:       lda     ($06),y
        sta     paintrect_params6::y2,y
        iny
        cpy     #$1D
        bne     :-

:       lda     drawtext_params::textlen
        sta     textwidth_params::textlen
        MGTK_CALL MGTK::TextWidth, textwidth_params
        lda     textwidth_params::result
        cmp     paintbits_params2::maprect::x2
        bcs     :+
        inc     drawtext_params::textlen
        ldx     drawtext_params::textlen
        lda     #' '
        sta     text_buffer-1,x
        jmp     :-

:       lsr     a
        sta     moveto_params2::xcoord+1
        lda     paintbits_params2::maprect::x2
        lsr     a
        sta     moveto_params2::xcoord
        lda     moveto_params2::xcoord+1
        sec
        sbc     moveto_params2::xcoord
        sta     moveto_params2::xcoord
        sub16_8 paintbits_params2::viewloc::xcoord, moveto_params2::xcoord, moveto_params2::xcoord
        add16_8 paintbits_params2::viewloc::ycoord, paintbits_params2::maprect::y2, moveto_params2::ycoord
        add16   moveto_params2::ycoord, #1, moveto_params2::ycoord
        add16_8 moveto_params2::ycoord, font_height, moveto_params2::ycoord
        ldx     #3
:       lda     moveto_params2,x
        sta     L9F94,x
        dex
        bpl     :-
        bit     L9F92
        bvc     LA097
        MGTK_CALL MGTK::InitPort, grafport
        jsr     LA63F
:       jsr     LA6A3
        jsr     LA097
        lda     L9F93
        bne     :-
        MGTK_CALL MGTK::SetPortBits, grafport
        rts

LA097:  MGTK_CALL MGTK::HideCursor, DESKTOP_DIRECT ; These params should be ignored - bogus?
        MGTK_CALL MGTK::SetPenMode, notpencopy_2
        bit     L9F92
        bpl     LA0C2
        bit     L9F92
        bvc     LA0B6
        MGTK_CALL MGTK::SetPenMode, pencopy_2
        jmp     LA0C2

LA0B6:  MGTK_CALL MGTK::PaintBits, paintbits_params
        MGTK_CALL MGTK::SetPenMode, penXOR_2
LA0C2:  MGTK_CALL MGTK::PaintBits, paintbits_params2
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_open_mask
        beq     LA0F2
        jsr     LA14D
        MGTK_CALL MGTK::SetPattern, dark_pattern ; shade for open volume
        bit     L9F92
        bmi     LA0E6
        MGTK_CALL MGTK::SetPenMode, penBIC_2
        beq     LA0EC
LA0E6:  MGTK_CALL MGTK::SetPenMode, penOR_2
LA0EC:  MGTK_CALL MGTK::PaintRect, paintrect_params6

LA0F2:  ldx     #3
:       lda     L9F94,x
        sta     moveto_params2,x
        dex
        bpl     :-

        MGTK_CALL MGTK::MoveTo, moveto_params2
        bit     L9F92
        bmi     :+
        lda     #MGTK::textbg_white
        bne     setbg
:       lda     #MGTK::textbg_black
setbg:  sta     settextbg_params
        MGTK_CALL MGTK::SetTextBG, settextbg_params
        lda     text_buffer+1
        and     #$DF
        sta     text_buffer+1
        MGTK_CALL MGTK::DrawText, drawtext_params
        MGTK_CALL MGTK::ShowCursor
        rts

LA12C:  ldx     #.sizeof(paintbits_params)-1
:       lda     paintbits_params2,x
        sta     paintbits_params,x
        dex
        bpl     :-

        ldy     paintbits_params::maprect::y2
LA13A:  lda     paintbits_params::mapwidth
        clc
        adc     paintbits_params::mapbits
        sta     paintbits_params::mapbits
        bcc     LA149
        inc     paintbits_params::mapbits+1
LA149:  dey
        bpl     LA13A
        rts

LA14D:  ldx     #0
LA14F:  add16   paintbits_params2::viewloc::xcoord,x, paintbits_params2::maprect::x1,x, paintrect_params6::x1,x
        add16   paintbits_params2::viewloc::xcoord,x, paintbits_params2::maprect::x2,x, paintrect_params6::x2,x
        inx
        inx
        cpx     #4
        bne     LA14F
        lda     paintrect_params6::y2
        sec
        sbc     #1
        sta     paintrect_params6::y2
        bcs     LA189
        dec     paintrect_params6::y2+1
LA189:  rts
.endproc

;;; ============================================================

;;;              v0          v1
;;;               +----------+
;;;               |          |
;;;               |          |
;;;               |          |
;;;            v7 |          | v2
;;;      v6 +-----+          +-----+ v3
;;;         |                      |
;;;      v5 +----------------------+ v4
;;;
;;; (Label is always at least as wide as the icon)

.proc calc_icon_poly
        entry_ptr := $6
        bitmap_ptr := $8

        jsr     push_zp_addrs

        ;; v0 - copy from icon entry
        ldy     #IconEntry::iconx+3
        ldx     #3
:       lda     (entry_ptr),y
        sta     poly::v0,x
        dey
        dex
        bpl     :-

        ;; Top edge (v0, v1)
        copy16  poly::v0::ycoord, poly::v1::ycoord

        ;; Left edge of icon (v0, v7)
        copy16  poly::v0::xcoord, poly::v7::xcoord

        ldy     #IconEntry::iconbits
        lda     (entry_ptr),y
        sta     bitmap_ptr
        iny
        lda     (entry_ptr),y
        sta     bitmap_ptr+1

        ;; Right edge of icon (v1, v2)
        ldy     #8              ; bitmap x2
        lda     (bitmap_ptr),y
        clc
        adc     poly::v0::xcoord
        sta     poly::v1::xcoord
        sta     poly::v2::xcoord
        iny
        lda     (bitmap_ptr),y
        adc     poly::v0::xcoord+1
        sta     poly::v1::xcoord+1
        sta     poly::v2::xcoord+1

        ;; Bottom edge of icon (v2, v7)
        ldy     #10             ; bitmap y2
        lda     (bitmap_ptr),y
        clc
        adc     poly::v0::ycoord
        sta     poly::v2::ycoord
        iny
        lda     ($08),y
        adc     poly::v0::ycoord+1
        sta     poly::v2::ycoord+1

        lda     poly::v2::ycoord ; 2px down
        clc
        adc     #2
        sta     poly::v2::ycoord
        sta     poly::v3::ycoord
        sta     poly::v6::ycoord
        sta     poly::v7::ycoord
        lda     poly::v2::ycoord+1
        adc     #0
        sta     poly::v2::ycoord+1
        sta     poly::v3::ycoord+1
        sta     poly::v6::ycoord+1
        sta     poly::v7::ycoord+1

        ;; Bottom edge of label (v4, v5)
        lda     font_height
        clc
        adc     poly::v2::ycoord
        sta     poly::v4::ycoord
        sta     poly::v5::ycoord
        lda     poly::v2::ycoord+1
        adc     #0
        sta     poly::v4::ycoord+1
        sta     poly::v5::ycoord+1

        ;; Compute text width
        ldy     #.sizeof(IconEntry)+1
        ldx     #19             ; len byte + 15 chars + 2 spaces
:       lda     (entry_ptr),y
        sta     text_buffer-1,x
        dey
        dex
        bpl     :-

        ;; Pad with spaces until it's at least as wide as the icon
:       lda     drawtext_params::textlen
        sta     textwidth_params::textlen
        MGTK_CALL MGTK::TextWidth, textwidth_params
        ldy     #8              ; bitmap x2 offset
        lda     textwidth_params::result
        cmp     (bitmap_ptr),y
        bcs     got_width
        inc     drawtext_params::textlen
        ldx     drawtext_params::textlen
        lda     #' '
        sta     text_buffer-1,x
        jmp     :-

got_width:
        lsr     a               ; width / 2
        sta     text_width
        lda     ($08),y         ; still has bitmap x2 offset
        lsr     a               ; / 2
        sta     icon_width

        ;; Left edge of label (v5, v6)
        lda     text_width
        sec
        sbc     icon_width
        sta     icon_width
        lda     poly::v0::xcoord
        sec
        sbc     icon_width
        sta     poly::v6::xcoord
        sta     poly::v5::xcoord
        lda     poly::v0::xcoord+1
        sbc     #0
        sta     poly::v6::xcoord+1
        sta     poly::v5::xcoord+1

        ;; Right edge of label (v3, v4)
        inc     textwidth_params::result
        inc     textwidth_params::result
        lda     poly::v5::xcoord
        clc
        adc     textwidth_params::result
        sta     poly::v3::xcoord
        sta     poly::v4::xcoord
        lda     poly::v5::xcoord+1
        adc     #0
        sta     poly::v3::xcoord+1
        sta     poly::v4::xcoord+1
        jsr     pop_zp_addrs
        rts

icon_width:  .byte   0
text_width:  .byte   0

.endproc

;;; ============================================================
;;; REDRAW_ICONS IMPL

.proc REDRAW_ICONS_IMPL
        jmp     LA2AE

        ;; DT_REDAW_ICON params
LA2A9:  .byte   0

LA2AA:  jsr     pop_zp_addrs
        rts

LA2AE:  jsr     push_zp_addrs
        ldx     num_icons
        dex
LA2B5:  bmi     LA2AA
        txa
        pha
        lda     icon_table,x
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #icon_entry_winid_mask
        bne     LA2DD
        ldy     #0
        lda     ($06),y
        sta     LA2A9
        DESKTOP_DIRECT_CALL DT_REDRAW_ICON, LA2A9
LA2DD:  pla
        tax
        dex
        jmp     LA2B5
.endproc

;;; ============================================================

.proc LA2E3
        stx     LA322
        sta     LA323
        ldx     #0
LA2EB:  lda     icon_table,x
        cmp     LA323
        beq     LA2FA
        inx
        cpx     num_icons
        bne     LA2EB
        rts

LA2FA:  lda     icon_table+1,x
        sta     icon_table,x
        inx
        cpx     num_icons
        bne     LA2FA
        ldx     num_icons
LA309:  cpx     LA322
        beq     LA318
        lda     icon_table-2,x
        sta     icon_table-1,x
        dex
        jmp     LA309

LA318:  ldx     LA322
        lda     LA323
        sta     icon_table-1,x
        rts
LA322:  .byte   0
LA323:  .byte   0
.endproc

;;; ============================================================
;;; A = icon number to move
;;; X = position in highlight list

.proc change_highlight_index
        stx     new_pos
        sta     icon_num

        ;; Find position of icon A in highlight list
        ldx     #0
:       lda     highlight_list,x
        cmp     icon_num
        beq     :+
        inx
        cpx     highlight_count
        bne     :-
        rts

        ;; Shift items down
:       lda     highlight_list+1,x
        sta     highlight_list,x
        inx
        cpx     highlight_count
        bne     :-

        ;; Shift items up
        ldx     highlight_count
:       cpx     new_pos
        beq     LA359
        lda     highlight_list-2,x
        sta     highlight_list-1,x
        dex
        jmp     :-

LA359:  ldx     new_pos
        lda     icon_num
        sta     highlight_list-1,x
        rts

new_pos:        .byte   0
icon_num:       .byte   0
.endproc

;;; ============================================================

.proc push_zp_addrs
        ;; save return addr
        pla
        sta     stash
        pla
        sta     stash+1

        ;; push $06...$09 to stack
        ldx     #0
:       lda     $06,x
        pha
        inx
        cpx     #4
        bne     :-

        ;; restore return addr
        lda     stash+1
        pha
        lda     stash
        pha
        rts

stash:  .word   0
.endproc

;;; ============================================================

.proc pop_zp_addrs
        ;; save return addr
        pla
        sta     stash
        pla
        sta     stash+1

        ;; pull $06...$09 to stack
        ldx     #3
:       pla
        sta     $06,x
        dex
        bpl     :-

        ;; restore return addr
        lda     stash+1
        pha
        lda     stash
        pha
        rts

stash:  .word   0

.endproc

;;; ============================================================

draw_icon:
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        jmp     LA3B9

LA3AC:  .byte   0
LA3AD:  .byte   0

        ;; DT_REDRAW_ICON params
LA3AE:  .byte   0

LA3AF:  .word   0
LA3B1:  .word   0
LA3B3:  .byte   0
        .byte   0
        .byte   0
        .byte   0
LA3B7:  .byte   0

.proc frontwindow_params
window_id:      .byte   0
.endproc

.proc LA3B9
        ldy     #0
        lda     ($06),y
        sta     LA3AC
        iny
        iny
        lda     ($06),y
        and     #$0F            ; type - is volume?
        sta     LA3AD
        beq     volume

        ;; File (i.e. icon in window)
        lda     #$80
        sta     LA3B7
        MGTK_CALL MGTK::SetPattern, white_pattern
        MGTK_CALL MGTK::FrontWindow, frontwindow_params
        lda     frontwindow_params::window_id
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        jsr     LA4CC
        jsr     LA938
        jsr     erase_icon
        jmp     LA446

        ;; Volume (i.e. icon on desktop)
volume:
        MGTK_CALL MGTK::InitPort, grafport
        jsr     LA63F
:       jsr     LA6A3
        jsr     erase_desktop_icon
        lda     L9F93
        bne     :-
        MGTK_CALL MGTK::SetPortBits, grafport
        jmp     LA446
.endproc

;;; ============================================================

.proc erase_desktop_icon
        lda     #0
        sta     LA3B7
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern2
        ;; fall through
.endproc

.proc erase_icon
        copy16  poly::v0::ycoord, LA3B1
        copy16  poly::v6::xcoord, LA3AF
        ldx     #3
:       lda     poly::v4::xcoord,x
        sta     LA3B3,x
        dex
        bpl     :-
        MGTK_CALL MGTK::PaintPoly, poly
        rts
.endproc

;;; ============================================================

LA446:  jsr     push_zp_addrs
        ldx     num_icons
        dex                     ; any icons to draw?

.proc LA44D
        ptr := $8

        cpx     #$FF            ; =-1
        bne     LA466
        bit     LA3B7           ; no, almost done
        bpl     :+
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport4
:       jsr     pop_zp_addrs
        rts

LA466:  txa
        pha
        lda     icon_table,x
        cmp     LA3AC
        beq     LA4C5
        asl     a
        tax
        copy16  icon_ptrs,x, ptr
        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #$07            ; window_id
        cmp     LA3AD
        bne     LA4C5

        ;; Is icon highlighted?
        lda     has_highlight
        beq     LA49D
        ldy     #0              ; icon num
        lda     (ptr),y
        ldx     #0
:       cmp     highlight_list,x
        beq     LA4C5
        inx
        cpx     highlight_count
        bne     :-

LA49D:  ldy     #0              ; icon num
        lda     (ptr),y
        sta     LA3AE
        bit     LA3B7
        bpl     LA4AC
        jsr     LA4D3
LA4AC:  DESKTOP_DIRECT_CALL DT_ICON_IN_RECT, LA3AE
        beq     LA4BA

        DESKTOP_DIRECT_CALL DT_REDRAW_ICON, LA3AE

LA4BA:  bit     LA3B7
        bpl     LA4C5
        lda     LA3AE
        jsr     LA4DC
LA4C5:  pla
        tax
        dex
        jmp     LA44D
.endproc

;;; ============================================================

LA4CB:  .byte   0

LA4CC:  lda     #$80
        sta     LA4CB
        bmi     LA4E2
LA4D3:  pha
        lda     #$40
        sta     LA4CB
        jmp     LA4E2

LA4DC:  pha
        lda     #0
        sta     LA4CB
LA4E2:  ldy     #0
LA4E4:  lda     grafport4,y
        sta     LA567,y
        iny
        cpy     #4
        bne     LA4E4
        ldy     #8
LA4F1:  lda     grafport4,y
        sta     LA567-4,y
        iny
        cpy     #12
        bne     LA4F1
        bit     LA4CB
        bmi     LA506
        bvc     LA56F
        jmp     LA5CB

LA506:  ldx     #0
LA508:  sub16   poly::vertices,x, LA567, poly::vertices,x
        sub16   poly::vertices+2,x, LA569, poly::vertices+2,x
        inx
        inx
        inx
        inx
        cpx     #32
        bne     LA508
        ldx     #0
LA538:  add16   poly::vertices,x, LA56B, poly::vertices,x
        add16   poly::vertices+2,x, LA56D, poly::vertices+2,x
        inx
        inx
        inx
        inx
        cpx     #32
        bne     LA538
        rts

LA567:  .byte   0
LA568:  .byte   0
LA569:  .byte   0
LA56A:  .byte   0
LA56B:  .byte   0
LA56C:  .byte   0
LA56D:  .byte   0
LA56E:  .byte   0
LA56F:  pla
        tay
        jsr     push_zp_addrs
        tya
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        ldy     #3
        lda     ($06),y
        clc
        adc     LA567
        sta     ($06),y
        iny
        lda     ($06),y
        adc     LA568
        sta     ($06),y
        iny
        lda     ($06),y
        clc
        adc     LA569
        sta     ($06),y
        iny
        lda     ($06),y
        adc     LA56A
        sta     ($06),y
        ldy     #3
        lda     ($06),y
        sec
        sbc     LA56B
        sta     ($06),y
        iny
        lda     ($06),y
        sbc     LA56C
        sta     ($06),y
        iny
        lda     ($06),y
        sec
        sbc     LA56D
        sta     ($06),y
        iny
        lda     ($06),y
        sbc     LA56E
        sta     ($06),y
        jsr     pop_zp_addrs
        rts

LA5CB:  pla
        tay
        jsr     push_zp_addrs
        tya
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        ldy     #3
        lda     ($06),y
        sec
        sbc     LA567
        sta     ($06),y
        iny
        lda     ($06),y
        sbc     LA568
        sta     ($06),y
        iny
        lda     ($06),y
        sec
        sbc     LA569
        sta     ($06),y
        iny
        lda     ($06),y
        sbc     LA56A
        sta     ($06),y
        ldy     #3
        lda     ($06),y
        clc
        adc     LA56B
        sta     ($06),y
        iny
        lda     ($06),y
        adc     LA56C
        sta     ($06),y
        iny
        lda     ($06),y
        clc
        adc     LA56D
        sta     ($06),y
        iny
        lda     ($06),y
        adc     LA56E
        sta     ($06),y
        jsr     pop_zp_addrs
        rts

;;; ============================================================

LA627:  .word   0
LA629:  .word   0
LA62B:  DEFINE_POINT 0,0

.proc setportbits_params2
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, 0, 0, cliprect
.endproc

.proc LA63F
        jsr     calc_icon_poly

        lda     poly::v0::ycoord
        sta     LA629
        sta     setportbits_params2::cliprect::y1
        sta     setportbits_params2::viewloc::ycoord
        lda     poly::v0::ycoord+1
        sta     LA629+1
        sta     setportbits_params2::cliprect::y1+1
        sta     setportbits_params2::viewloc::ycoord+1

        lda     poly::v5::xcoord
        sta     LA627
        sta     setportbits_params2::cliprect::x1
        sta     setportbits_params2::viewloc::xcoord
        lda     poly::v5::xcoord+1
        sta     LA627+1
        sta     setportbits_params2::cliprect::x1+1
        sta     setportbits_params2::viewloc::xcoord+1

        ldx     #3
:       lda     poly::v4,x
        sta     LA62B,x
        sta     setportbits_params2::cliprect::x2,x
        dex
        bpl     :-

        cmp16   LA62B, #screen_width - 1
        bmi     done
        lda     #<(screen_width - 2)
        sta     LA62B
        sta     setportbits_params2::cliprect::x2
        lda     #>(screen_width - 2)
        sta     LA62B+1
        sta     setportbits_params2::cliprect::x2+1

done:   MGTK_CALL MGTK::SetPortBits, setportbits_params2
        rts
.endproc

;;; ============================================================

.proc LA6A3
        lda     #$00
        jmp     LA6C7

.proc findwindow_params
mousex: .word   0
mousey: .word   0
which_area:     .byte   0
window_id:      .byte   0
.endproc

LA6AE:  .word   0
LA6B0:  .byte   $00
LA6B1:  .byte   $00
LA6B2:  .byte   $00
LA6B3:  .byte   $00
LA6B4:  .byte   $00
LA6B5:  .byte   $00
LA6B6:  .byte   $00
LA6B7:  .byte   $00
LA6B8:  .byte   $00
LA6B9:  .byte   $00
LA6BA:  .byte   $00
LA6BB:  .byte   $00
LA6BC:  .byte   $00
LA6BD:  .byte   $00
LA6BE:  .byte   $00
LA6BF:  .byte   $00
LA6C0:  .byte   $00
LA6C1:  .byte   $00
LA6C2:  .byte   $00
LA6C3:  .word   0
LA6C5:  .word   0
LA6C7:  lda     L9F93
        beq     LA6FA
        lda     setportbits_params2::cliprect::x2
        clc
        adc     #1
        sta     setportbits_params2::cliprect::x1
        sta     setportbits_params2::viewloc::xcoord
        lda     setportbits_params2::cliprect::x2+1
        adc     #0
        sta     setportbits_params2::cliprect::x1+1
        sta     setportbits_params2::viewloc::xcoord+1
        ldx     #5
LA6E5:  lda     LA629,x
        sta     setportbits_params2::cliprect::y1,x
        dex
        bpl     LA6E5
        lda     setportbits_params2::cliprect::y1
        sta     setportbits_params2::viewloc::ycoord
        lda     setportbits_params2::cliprect::y1+1
        sta     setportbits_params2::viewloc::ycoord+1
LA6FA:  lda     setportbits_params2::cliprect::x1
        sta     LA6B3
        sta     LA6BF
        lda     setportbits_params2::cliprect::x1+1
        sta     LA6B4
        sta     LA6C0
        lda     setportbits_params2::cliprect::y1
        sta     LA6B5
        sta     LA6B9
        lda     setportbits_params2::cliprect::y1+1
        sta     LA6B6
        sta     LA6BA
        lda     setportbits_params2::cliprect::x2
        sta     LA6B7
        sta     LA6BB
        lda     setportbits_params2::cliprect::x2+1
        sta     LA6B8
        sta     LA6BC
        lda     setportbits_params2::cliprect::y2
        sta     LA6BD
        sta     LA6C1
        lda     setportbits_params2::cliprect::y2+1
        sta     LA6BE
        sta     LA6C2
        lda     #0
        sta     LA6B0
LA747:  lda     LA6B0
        cmp     #4
        bne     LA775
        lda     #0
        sta     LA6B0
LA753:  MGTK_CALL MGTK::SetPortBits, setportbits_params2
        lda     setportbits_params2::cliprect::x2+1
        cmp     LA62B+1
        bne     LA76F
        lda     setportbits_params2::cliprect::x2
        cmp     LA62B
        bcc     LA76F
        lda     #$00
        sta     L9F93
        rts

LA76F:  lda     #1
        sta     L9F93
        rts

LA775:  lda     LA6B0
        asl     a
        asl     a
        tax
        ldy     #$00
LA77D:  lda     LA6B3,x
        sta     findwindow_params,y
        iny
        inx
        cpy     #4
        bne     LA77D
        inc     LA6B0
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        beq     LA747
        lda     findwindow_params::window_id
        sta     getwinport_params
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        jsr     push_zp_addrs
        MGTK_CALL MGTK::GetWinPtr, findwindow_params::window_id
        copy16  LA6AE, $06
        ldy     #1
        lda     ($06),y
        and     #$01
        bne     LA7C3
        sta     LA6B2
        beq     LA7C8
LA7C3:  lda     #$80
        sta     LA6B2
LA7C8:  ldy     #4
        lda     ($06),y
        and     #$80
        sta     LA6B1
        iny
        lda     ($06),y
        and     #$80
        lsr     a
        ora     LA6B1
        sta     LA6B1
        sub16   grafport4::viewloc::xcoord, #2, grafport4::viewloc::xcoord
        sub16   grafport4::cliprect::x1, #2, grafport4::cliprect::x1
        bit     LA6B2
        bmi     LA820
        lda     grafport4::viewloc::ycoord
        sec
        sbc     #14
        sta     grafport4::viewloc::ycoord
        bcs     LA812
        dec     grafport4::viewloc::ycoord+1
LA812:  lda     grafport4::cliprect::y1
        sec
        sbc     #14
        sta     grafport4::cliprect::y1
        bcs     LA820
        dec     grafport4::cliprect::y1+1
LA820:  bit     LA6B1
        bpl     LA833
        lda     grafport4::cliprect::y2
        clc
        adc     #12
        sta     grafport4::cliprect::y2
        bcc     LA833
        inc     grafport4::cliprect::y2+1
LA833:  bit     LA6B1
        bvc     LA846
        lda     grafport4::cliprect::x2
        clc
        adc     #20
        sta     grafport4::cliprect::x2
        bcc     LA846
        inc     grafport4::cliprect::x2+1
LA846:  jsr     pop_zp_addrs
        sub16   grafport4::cliprect::x2, grafport4::cliprect::x1, LA6C3
        sub16   grafport4::cliprect::y2, grafport4::cliprect::y1, LA6C5
        lda     LA6C3
        clc
        adc     grafport4::viewloc::xcoord
        sta     LA6C3
        lda     grafport4::viewloc::xcoord+1
        adc     LA6C3+1
        sta     LA6C3+1
        add16   LA6C5, grafport4::viewloc::ycoord, LA6C5
        cmp16   setportbits_params2::cliprect::x2, LA6C3
        bmi     LA8B7
        add16   LA6C3, #1, setportbits_params2::cliprect::x2
        jmp     LA8D4

LA8B7:  cmp16   grafport4::viewloc::xcoord, setportbits_params2::cliprect::x1
        bmi     LA8D4
        copy16  grafport4::viewloc::xcoord, setportbits_params2::cliprect::x2
        jmp     LA6FA

LA8D4:  cmp16   grafport4::viewloc::ycoord, setportbits_params2::cliprect::y1
        bmi     LA8F6
        copy16  grafport4::viewloc::ycoord, setportbits_params2::cliprect::y2
        lda     #1
        sta     L9F93
        jmp     LA6FA

LA8F6:  cmp16   LA6C5, setportbits_params2::cliprect::y2
        bpl     LA923
        lda     LA6C5
        clc
        adc     #2
        sta     setportbits_params2::cliprect::y1
        sta     setportbits_params2::viewloc::ycoord
        lda     LA6C5+1
        adc     #0
        sta     setportbits_params2::cliprect::y1+1
        sta     setportbits_params2::viewloc::ycoord+1
        lda     #1
        sta     L9F93
        jmp     LA6FA

LA923:  lda     setportbits_params2::cliprect::x2
        sta     setportbits_params2::cliprect::x1
        sta     setportbits_params2::viewloc::xcoord
        lda     setportbits_params2::cliprect::x2+1
        sta     setportbits_params2::cliprect::x1+1
        sta     setportbits_params2::viewloc::xcoord+1
        jmp     LA753
.endproc

;;; ============================================================

.proc LA938
        add16   grafport4::viewloc::ycoord, #15, grafport4::viewloc::ycoord
        add16   grafport4::cliprect::y1, #15, grafport4::cliprect::y1
        MGTK_CALL MGTK::SetPort, grafport4
        rts
.endproc

        PAD_TO $A980

;;; ============================================================

        ;; 5.25" Floppy Disk
floppy140_icon:
        .addr   floppy140_pixels; mapbits
        .byte   4               ; mapwidth
        .byte   0               ; reserved
        DEFINE_RECT   0, 1, 26, 15 ; maprect

floppy140_pixels:
        .byte   px(%1010101),px(%0101010),px(%1010101),px(%0101010)
        .byte   px(%1111111),px(%1111111),px(%1111111),px(%1111111)
        .byte   px(%1100000),px(%0000011),px(%1000000),px(%0000110)
        .byte   px(%1100000),px(%0000011),px(%1000000),px(%0000111)
        .byte   px(%1100000),px(%0000011),px(%1000000),px(%0000110)
        .byte   px(%1100000),px(%0000011),px(%1000000),px(%0000111)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000110)
        .byte   px(%1100000),px(%0000011),px(%1000000),px(%0000111)
        .byte   px(%1100000),px(%0000111),px(%1100000),px(%0000110)
        .byte   px(%1100000),px(%0000011),px(%1000000),px(%0000111)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000110)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000111)
        .byte   px(%1011000),px(%0000000),px(%0000000),px(%0000110)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000111)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000110)
        .byte   px(%1111111),px(%1111111),px(%1111111),px(%1111111)

        ;; RAM Disk
ramdisk_icon:
        .addr   ramdisk_pixels  ; mapbits
        .byte   6               ; mapwidth
        .byte   0               ; reserved
        DEFINE_RECT   1, 0, 38, 11 ; maprect

ramdisk_pixels:
        .byte   px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111101)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0001110)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0001101)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0001110)
        .byte   px(%1100000),px(%0001111),px(%1000111),px(%1100110),px(%0000110),px(%0001101)
        .byte   px(%1100000),px(%0001100),px(%1100110),px(%0110111),px(%1011110),px(%0001110)
        .byte   px(%1100000),px(%0001111),px(%1000111),px(%1110110),px(%1110110),px(%0001101)
        .byte   px(%1100000),px(%0001100),px(%1100110),px(%0110110),px(%0000110),px(%0001110)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0001101)
        .byte   px(%1111111),px(%1111111),px(%1111111),px(%1001100),px(%1100110),px(%0001110)
        .byte   px(%0101010),px(%1010101),px(%0101010),px(%1001100),px(%1100110),px(%0001101)
        .byte   px(%1010101),px(%0101010),px(%1010101),px(%1111111),px(%1111111),px(%1111110)

        ;; 3.5" Floppy Disk
floppy800_icon:
        .addr   floppy800_pixels; mapbits
        .byte   3               ; mapwidth
        .byte   0               ; reserved
        DEFINE_RECT   0, 0, 20, 11 ; maprect

floppy800_pixels:
        .byte   px(%1111111),px(%1111111),px(%1111110)
        .byte   px(%1100011),px(%0000000),px(%1100111)
        .byte   px(%1100011),px(%0000000),px(%1100111)
        .byte   px(%1100011),px(%1111111),px(%1100011)
        .byte   px(%1100000),px(%0000000),px(%0000011)
        .byte   px(%1100000),px(%0000000),px(%0000011)
        .byte   px(%1100111),px(%1111111),px(%1110011)
        .byte   px(%1100110),px(%0000000),px(%0110011)
        .byte   px(%1100110),px(%0000000),px(%0110011)
        .byte   px(%1100110),px(%0000000),px(%0110011)
        .byte   px(%1100110),px(%0000000),px(%0110011)
        .byte   px(%1111111),px(%1111111),px(%1111111)

        ;; Hard Disk
profile_icon:
        .addr   profile_pixels  ; mapbits
        .byte   8               ; mapwidth
        .byte   0               ; reserved
        DEFINE_RECT   1, 0, 51, 9 ; maprect

profile_pixels:
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1110101)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011010)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011101)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011010)
        .byte   px(%1100011),px(%1000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011101)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011101)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011010)
        .byte   px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011101)
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1110101)
        .byte   px(%1010111),px(%0101010),px(%1010101),px(%0101010),px(%1010101),px(%0101010),px(%1010111),px(%0101010)

        ;; Trash Can
trash_icon:
        .addr   trash_pixels    ; mapbits
        .byte   5               ; mapwidth
        .byte   0               ; reserved
        DEFINE_RECT   7, 1, 27, 18 ; maprect

trash_pixels:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%1010101),PX(%1111111),px(%1010101),px(%0000000)
        .byte   px(%0000000),px(%0101010),PX(%1100011),px(%0101010),px(%0000000)
        .byte   px(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),px(%0000000)
        .byte   px(%0000000),px(%1100000),px(%0000000),PX(%0000011),px(%0000000)
        .byte   px(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),px(%0000000)
        .byte   px(%0000000),px(%1100000),px(%0000000),px(%0000011),px(%0000000)
        .byte   px(%0000000),px(%1100001),px(%0000100),px(%0010011),px(%0000000)
        .byte   px(%0000000),px(%1100010),px(%0001000),px(%0100011),px(%0000000)
        .byte   px(%0000000),px(%1100010),px(%0001000),px(%0100011),px(%0000000)
        .byte   px(%0000000),px(%1100010),px(%0001000),px(%0100011),px(%0000000)
        .byte   px(%0000000),px(%1100010),px(%0001000),px(%0100011),px(%0000000)
        .byte   px(%0000000),px(%1100010),px(%0001000),px(%0100011),px(%0000000)
        .byte   px(%0000000),px(%1100010),px(%0001000),px(%0100011),px(%0000000)
        .byte   px(%0000000),px(%1100010),px(%0001000),px(%0100011),px(%0000000)
        .byte   px(%0000000),px(%1100010),px(%0001000),px(%0100011),px(%0000000)
        .byte   px(%0000000),px(%1100001),px(%0000100),px(%0010011),px(%0000000)
        .byte   px(%0000000),px(%1100000),px(%0000000),px(%0000011),px(%0000000)
        .byte   px(%0000000),PX(%1111111),PX(%1111111),PX(%1111111),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)

label_apple:
        PASCAL_STRING GLYPH_SAPPLE
label_file:
        PASCAL_STRING "File"
label_view:
        PASCAL_STRING "View"
label_special:
        PASCAL_STRING "Special"
label_startup:
        PASCAL_STRING "Startup"
label_selector:
        PASCAL_STRING "Selector"

label_new_folder:
        PASCAL_STRING "New Folder ..."
label_open:
        PASCAL_STRING "Open"
label_close:
        PASCAL_STRING "Close"
label_close_all:
        PASCAL_STRING "Close All"
label_select_all:
        PASCAL_STRING "Select All"
label_copy_file:
        PASCAL_STRING "Copy a File ..."
label_delete_file:
        PASCAL_STRING "Delete a File ..."
label_eject:
        PASCAL_STRING "Eject"
label_quit:
        PASCAL_STRING "Quit"

label_by_icon:
        PASCAL_STRING "By Icon"
label_by_name:
        PASCAL_STRING "By Name"
label_by_date:
        PASCAL_STRING "By Date"
label_by_size:
        PASCAL_STRING "By Size"
label_by_type:
        PASCAL_STRING "By Type"

label_check_drives:
        PASCAL_STRING "Check Drives"
label_format_disk:
        PASCAL_STRING "Format a Disk ..."
label_erase_disk:
        PASCAL_STRING "Erase a Disk ..."
label_disk_copy:
        PASCAL_STRING "Disk Copy ..."
label_lock:
        PASCAL_STRING "Lock ..."
label_unlock:
        PASCAL_STRING "Unlock ..."
label_get_info:
        PASCAL_STRING "Get Info ..."
label_get_size:
        PASCAL_STRING "Get Size ..."
label_rename_icon:
        PASCAL_STRING "Rename an Icon ..."

desktop_menu:
        DEFINE_MENU_BAR 6
        DEFINE_MENU_BAR_ITEM menu_id_apple, label_apple, apple_menu
        DEFINE_MENU_BAR_ITEM menu_id_file, label_file, file_menu
        DEFINE_MENU_BAR_ITEM menu_id_view, label_view, view_menu
        DEFINE_MENU_BAR_ITEM menu_id_special, label_special, special_menu
        DEFINE_MENU_BAR_ITEM menu_id_startup, label_startup, startup_menu
        DEFINE_MENU_BAR_ITEM menu_id_selector, label_selector, selector_menu

file_menu:
        DEFINE_MENU 12
        DEFINE_MENU_ITEM label_new_folder, 'F', 'f'
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_open, 'O', 'o'
        DEFINE_MENU_ITEM label_close, 'C', 'c'
        DEFINE_MENU_ITEM label_close_all, 'B', 'b'
        DEFINE_MENU_ITEM label_select_all, 'A', 'a'
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_copy_file, 'Y', 'y'
        DEFINE_MENU_ITEM label_delete_file, 'D', 'd'
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_eject, 'E', 'e'
        DEFINE_MENU_ITEM label_quit, 'Q', 'q'

        menu_item_id_new_folder := 1
        menu_item_id_open       := 3
        menu_item_id_close      := 4
        menu_item_id_close_all  := 5
        menu_item_id_select_all := 6
        menu_item_id_copy_file  := 8
        menu_item_id_delete_file := 9
        menu_item_id_eject      := 11
        menu_item_id_quit       := 12

view_menu:
        DEFINE_MENU 5
        DEFINE_MENU_ITEM label_by_icon, 'J', 'j'
        DEFINE_MENU_ITEM label_by_name, 'N', 'n'
        DEFINE_MENU_ITEM label_by_date, 'T', 't'
        DEFINE_MENU_ITEM label_by_size, 'K', 'k'
        DEFINE_MENU_ITEM label_by_type, 'L', 'l'

        menu_item_id_view_by_icon := 1
        menu_item_id_view_by_name := 2
        menu_item_id_view_by_date := 3
        menu_item_id_view_by_size := 4
        menu_item_id_view_by_type := 5

special_menu:
        DEFINE_MENU 13
        DEFINE_MENU_ITEM label_check_drives
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_format_disk, 'S', 's'
        DEFINE_MENU_ITEM label_erase_disk, 'Z', 'z'
        DEFINE_MENU_ITEM label_disk_copy
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_lock
        DEFINE_MENU_ITEM label_unlock
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_get_info, 'I', 'i'
        DEFINE_MENU_ITEM label_get_size
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_rename_icon

        menu_item_id_check_drives := 1
        menu_item_id_format_disk  := 3
        menu_item_id_erase_disk   := 4
        menu_item_id_disk_copy    := 5
        menu_item_id_lock         := 7
        menu_item_id_unlock       := 8
        menu_item_id_get_info     := 10
        menu_item_id_get_size     := 11
        menu_item_id_rename_icon  := 13

        .addr   $0000,$0000

        .assert * = $AD58, error, "Segment length mismatch"
        PAD_TO $AE00

;;; ============================================================

        ;; Rects
confirm_dialog_outer_rect:  DEFINE_RECT 4,2,396,98
confirm_dialog_inner_rect:  DEFINE_RECT 5,3,395,97
cancel_button_rect:  DEFINE_RECT 40,81,140,92
LAE18:  DEFINE_RECT 193,30,293,41
ok_button_rect:  DEFINE_RECT 260,81,360,92
yes_button_rect:  DEFINE_RECT 200,81,240,92
no_button_rect:  DEFINE_RECT 260,81,300,92
all_button_rect:  DEFINE_RECT 320,81,360,92

str_ok_label:
        PASCAL_STRING {"OK            ",GLYPH_RETURN}

ok_label_pos:  DEFINE_POINT 265,91
cancel_label_pos:  DEFINE_POINT 45,91
yes_label_pos:  DEFINE_POINT 205,91
no_label_pos:  DEFINE_POINT 265,91
all_label_pos:  DEFINE_POINT 325,91

        .byte   $1C,$00,$70,$00
        .byte   $1C,$00,$87,$00

textbg_black:  .byte   $00
textbg_white:  .byte   $7F

press_ok_to_rect:  DEFINE_RECT 39,25,360,80
prompt_rect:  DEFINE_RECT 40,60,360,80
LAE7E:  DEFINE_POINT 65,43
LAE82:  DEFINE_POINT 65,51
LAE86:  DEFINE_RECT 65,35,394,42
LAE8E:  DEFINE_RECT 65,43,394,50

str_cancel_label:
        PASCAL_STRING "Cancel        Esc"
str_yes_label:
        PASCAL_STRING " Yes"
str_no_label:
        PASCAL_STRING " No"
str_all_label:
        PASCAL_STRING " All"

LAEB6:  PASCAL_STRING "Source filename:"
LAEC7:  PASCAL_STRING "Destination filename:"

        ;; "About" dialog resources
about_dialog_outer_rect:  DEFINE_RECT 4, 2, 396, 108
about_dialog_inner_rect:  DEFINE_RECT 5, 3, 395, 107

str_about1:  PASCAL_STRING "Apple II DeskTop"
str_about2:  PASCAL_STRING "Copyright Apple Computer Inc., 1986"
str_about3:  PASCAL_STRING "Copyright Version Soft, 1985 - 1986"
str_about4:  PASCAL_STRING "All Rights Reserved"
str_about5:  PASCAL_STRING "Authors: Stephane Cavril, Bernard Gallet, Henri Lamiraux"
str_about6:  PASCAL_STRING "Richard Danais and Luc Barthelet"
str_about7:  PASCAL_STRING "With thanks to: A. Gerard, J. Gerber, P. Pahl, J. Bernard"
str_about8:  PASCAL_STRING "November 26, 1986"
str_about9:  PASCAL_STRING "Version 1.1"

        ;; "Copy File" dialog strings
str_copy_title:
        PASCAL_STRING "Copy ..."
str_copy_copying:
        PASCAL_STRING "Now Copying "
str_copy_from:
        PASCAL_STRING "from:"
str_copy_to:
        PASCAL_STRING "to :"
str_copy_remaining:
        PASCAL_STRING "Files remaining to copy: "

str_exists_prompt:
        PASCAL_STRING "That file already exists. Do you want to write over it ?"
str_large_prompt:
        PASCAL_STRING "This file is too large to copy, click OK to continue."

LB0B6:  DEFINE_POINT 110, 35
LB0BA:  DEFINE_POINT 170, 59

        ;; "Delete" dialog strings
str_delete_title:
        PASCAL_STRING "Delete ..."
str_delete_ok:
        PASCAL_STRING "Click OK to delete:"
str_ok_empty:
        PASCAL_STRING "Clicking OK will immediately empty the trash of:"
str_file_colon:
        PASCAL_STRING "File:"
str_delete_remaining:
        PASCAL_STRING "Files remaining to be deleted:"
str_delete_locked_file:
        PASCAL_STRING "This file is locked, do you want to delete it anyway ?"

LB16A:  DEFINE_POINT 145, 59
LB16E:  DEFINE_POINT 200, 59
LB172:  DEFINE_POINT 300, 59

        ;; "New Folder" dialog strings
str_new_folder_title:
        PASCAL_STRING "New Folder ..."
str_in_colon:
        PASCAL_STRING "in:"
str_enter_folder_name:
        PASCAL_STRING "Enter the folder name:"

        ;; "Rename Icon" dialog strings
str_rename_title:
        PASCAL_STRING "Rename an Icon ..."
str_rename_old:
        PASCAL_STRING "Rename: "
str_rename_new:
        PASCAL_STRING "New name:"

        ;; "Get Info" dialog strings
str_info_title:
        PASCAL_STRING "Get Info ..."
str_info_name:
        PASCAL_STRING "Name"
str_info_locked:
        PASCAL_STRING "Locked"
str_info_size:
        PASCAL_STRING "Size"
str_info_create:
        PASCAL_STRING "Creation date"
str_info_mod:
        PASCAL_STRING "Last modification"
str_info_type:
        PASCAL_STRING "Type"
str_info_protected:
        PASCAL_STRING "Write protected"
str_info_blocks:
        PASCAL_STRING "Blocks free/size"

str_colon:
        PASCAL_STRING ": "

LB22D:  DEFINE_POINT 160,59
LB231:  DEFINE_POINT 145,59
LB235:  DEFINE_POINT 200,59
LB239:  DEFINE_POINT 185,59
LB23D:  DEFINE_POINT 205,59
LB241:  DEFINE_POINT 195,59

LB245:  PASCAL_STRING "Format a Disk ..."
LB257:  PASCAL_STRING "Select the location where the disk is to be formatted"
LB28D:  PASCAL_STRING "Enter the name of the new volume:"
LB2AF:  PASCAL_STRING "Do you want to format "
LB2C6:  PASCAL_STRING "Formatting the disk...."
LB2DE:  PASCAL_STRING "Formatting error. Check drive, then click OK to try again."

LB319:  PASCAL_STRING "Erase a Disk ..."
LB32A:  PASCAL_STRING "Select the location where the disk is to be erased"
LB35D:  PASCAL_STRING "Do you want to erase "
LB373:  PASCAL_STRING "Erasing the disk...."
LB388:  PASCAL_STRING "Erasing error. Check drive, then click OK to try again."

        ;; "Unlock File" dialog strings
str_unlock_title:
        PASCAL_STRING "Unlock ..."
str_unlock_ok:
        PASCAL_STRING "Click OK to unlock "
str_unlock_remaining:
        PASCAL_STRING "Files remaining to be unlocked: "

        ;; "Lock File" dialog strings
str_lock_title:
        PASCAL_STRING "Lock ..."
str_lock_ok:
        PASCAL_STRING "Click OK to lock "
str_lock_remaining:
        PASCAL_STRING "Files remaining to be locked: "

        ;; "Get Size" dialog strings
str_size_title:
        PASCAL_STRING "Get Size ..."
str_size_number:
        PASCAL_STRING "Number of files"
str_size_blocks:
        PASCAL_STRING "Blocks used on disk"

        .byte   $6E,$00,$23,$00,$6E,$00,$2B,$00

str_download:
        PASCAL_STRING "DownLoad ..."

str_ramcard_full:
        PASCAL_STRING "The RAMCard is full. The copy was not completed."

str_1_space:
        PASCAL_STRING " "

str_warning:
        PASCAL_STRING "Warning !"
str_insert_system_disk:
        PASCAL_STRING "Please insert the system disk."
str_selector_list_full:
        PASCAL_STRING "The Selector list is full. You must delete an entry"
str_before_new_entries:
        PASCAL_STRING "before you can add new entries."
str_window_must_be_closed:
        PASCAL_STRING "A window must be closed before opening this new catalog."

str_too_many_windows:
        PASCAL_STRING "There are too many windows open on the desktop !"
str_save_selector_list:
        PASCAL_STRING "Do you want to save the new Selector list"
str_on_system_disk:
        PASCAL_STRING "on the system disk ?"


        .assert * = $B5D9, error, "Segment length mismatch"
        PAD_TO $B600

;;; ============================================================

show_alert_indirection:
        jmp     show_alert_dialog

alert_bitmap:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),PX(%1111111),PX(%1111111),px(%0000000),px(%0000000)
        .byte   px(%0111100),px(%1111100),px(%0000001),px(%1110000),PX(%0000111),px(%0000000),px(%0000000)
        .byte   px(%0111100),px(%1111100),px(%0000011),px(%1100000),px(%0000011),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0000111),PX(%1100111),px(%1111001),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0001111),PX(%1100111),px(%1111001),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),px(%1111001),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),px(%1110011),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),PX(%1100111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),PX(%1001111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),PX(%0011111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),px(%1111110),PX(%0111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),px(%1111100),PX(%1111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),px(%1111100),PX(%1111111),px(%0000000),px(%0000000)
        .byte   px(%0111110),px(%0000000),PX(%0111111),PX(%1111111),PX(%1111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100000),PX(%1111111),px(%1111100),PX(%1111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100001),PX(%1111111),PX(%1111111),PX(%1111111),px(%0000000),px(%0000000)
        .byte   px(%0111000),px(%0000011),PX(%1111111),PX(%1111111),px(%1111110),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)

.proc alert_bitmap_params
        DEFINE_POINT 20, 8      ; viewloc
        .addr   alert_bitmap    ; mapbits
        .byte   7               ; mapwidth
        .byte   0               ; reserved
        DEFINE_RECT 0, 0, 36, 23 ; maprect
.endproc

alert_rect:
        DEFINE_RECT 65, 87, 485, 142
alert_inner_frame_rect1:
        DEFINE_RECT 4, 2, 416, 53
alert_inner_frame_rect2:
        DEFINE_RECT 5, 3, 415, 52

.proc portmap
viewloc:        DEFINE_POINT 65, 87, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, 420, 55, maprect
.endproc


;;; ============================================================
;;; Show Alert Dialog
;;; Call show_alert_dialog with prompt number in X (???), A = ???

.proc show_alert_dialog_impl

ok_label:
        PASCAL_STRING {"OK            ",GLYPH_RETURN}

try_again_rect:
        DEFINE_RECT 20,37,120,48
try_again_pos:
        DEFINE_POINT 25,47

cancel_rect:
        DEFINE_RECT 300,37,400,48
cancel_pos:
        DEFINE_POINT 305,47

        .word   $BE,$10     ; ???

pos_prompt: DEFINE_POINT 75,29, pos_prompt

alert_action:  .byte   $00
prompt_addr:    .addr   0

try_again_label:
        PASCAL_STRING "Try Again     A"
cancel_label:
        PASCAL_STRING "Cancel     Esc"

err_00:  PASCAL_STRING "System Error"
err_27:  PASCAL_STRING "I/O error"
err_28:  PASCAL_STRING "No device connected"
err_2B:  PASCAL_STRING "The disk is write protected."
err_40:  PASCAL_STRING "The syntax of the pathname is invalid."
err_44:  PASCAL_STRING "Part of the pathname doesn't exist."
err_45:  PASCAL_STRING "The volume cannot be found."
err_46:  PASCAL_STRING "The file cannot be found."
err_47:  PASCAL_STRING "That name already exists. Please use another name."
err_48:  PASCAL_STRING "The disk is full."
err_49:  PASCAL_STRING "The volume directory cannot hold more than 51 files."
err_4E:  PASCAL_STRING "The file is locked."
err_52:  PASCAL_STRING "This is not a ProDOS disk."
err_57:  PASCAL_STRING "There is another volume with that name on the desktop."
        ;; Below are internal (not ProDOS MLI) error codes.
err_F9:  PASCAL_STRING "There are 2 volumes with the same name."
err_FA:  PASCAL_STRING "This file cannot be run."
err_FB:  PASCAL_STRING "That name is too long."
err_FC:  PASCAL_STRING "Please insert source disk"
err_FD:  PASCAL_STRING "Please insert destination disk"
err_FE:  PASCAL_STRING "BASIC.SYSTEM not found"

        ;; number of alert messages
alert_count:
        .byte   20

        ;; message number-to-index table
        ;; (look up by scan to determine index)
alert_table:
        ;; ProDOS MLI error codes:
        .byte   $00,$27,$28,$2B,$40,$44,$45,$46
        .byte   $47,$48,$49,$4E,$52,$57
        ;; Internal error codes:
        .byte   $F9,$FA,$FB,$FC,$FD,$FE

        ;; alert index to string address
prompt_table:
        .addr   err_00,err_27,err_28,err_2B,err_40,err_44,err_45,err_46
        .addr   err_47,err_48,err_49,err_4E,err_52,err_57,err_F9,err_FA
        .addr   err_FB,err_FC,err_FD,err_FE

        ;; alert index to action (0 = Cancel, $80 = Try Again)
alert_action_table:
        .byte   $00,$00,$00,$80,$00,$80,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$80,$80,$00

        ;; Actual entry point
start:  pha
        txa
        pha
        MGTK_RELAY2_CALL MGTK::HideCursor
        MGTK_RELAY2_CALL MGTK::SetCursor, pointer_cursor
        MGTK_RELAY2_CALL MGTK::ShowCursor

        ;; play bell
        sta     ALTZPOFF
        sta     ROMIN2
        jsr     BELL1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ldx     #$03
        lda     #$00
LBA0B:  sta     grafport3_viewloc_xcoord,x
        sta     grafport3_cliprect_x1,x
        dex
        bpl     LBA0B
        copy16  #$226, grafport3_cliprect_x2
        copy16  #$B9, grafport3_cliprect_y2
        MGTK_RELAY2_CALL MGTK::SetPort, grafport3
        addr_call_indirect LBF8B, portmap::viewloc::xcoord
        sty     LBFCA
        sta     LBFCD
        lda     portmap::viewloc::xcoord
        clc
        adc     portmap::maprect::x2
        pha
        lda     portmap::viewloc::xcoord+1
        adc     portmap::maprect::x2+1
        tax
        pla
        jsr     LBF8B
        sty     LBFCC
        sta     LBFCE
        lda     portmap::viewloc::ycoord
        sta     LBFC9
        clc
        adc     portmap::maprect::y2
        sta     LBFCB
        MGTK_RELAY2_CALL MGTK::HideCursor
        jsr     LBE08
        MGTK_RELAY2_CALL MGTK::ShowCursor
        MGTK_RELAY2_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY2_CALL MGTK::PaintRect, alert_rect ; alert background
        MGTK_RELAY2_CALL MGTK::SetPenMode, penXOR ; ensures corners are inverted
        MGTK_RELAY2_CALL MGTK::FrameRect, alert_rect ; alert outline
        MGTK_RELAY2_CALL MGTK::SetPortBits, portmap::viewloc::xcoord
        MGTK_RELAY2_CALL MGTK::FrameRect, alert_inner_frame_rect1 ; inner 2x border
        MGTK_RELAY2_CALL MGTK::FrameRect, alert_inner_frame_rect2
        MGTK_RELAY2_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY2_CALL MGTK::HideCursor
        MGTK_RELAY2_CALL MGTK::PaintBits, alert_bitmap_params
        MGTK_RELAY2_CALL MGTK::ShowCursor
        pla
        tax
        pla
        ldy     alert_count
        dey
LBAE5:  cmp     alert_table,y
        beq     LBAEF
        dey
        bpl     LBAE5
        ldy     #$00
LBAEF:  tya
        asl     a
        tay
        copy16  prompt_table,y, prompt_addr
        cpx     #$00
        beq     LBB0B
        txa
        and     #$FE
        sta     alert_action
        jmp     LBB14

LBB0B:  tya
        lsr     a
        tay
        lda     alert_action_table,y
        sta     alert_action
LBB14:  MGTK_RELAY2_CALL MGTK::SetPenMode, penXOR
        bit     alert_action
        bpl     LBB5C
        MGTK_RELAY2_CALL MGTK::FrameRect, cancel_rect
        MGTK_RELAY2_CALL MGTK::MoveTo, cancel_pos
        addr_call draw_pascal_string, cancel_label
        bit     alert_action
        bvs     LBB5C
        MGTK_RELAY2_CALL MGTK::FrameRect, try_again_rect
        MGTK_RELAY2_CALL MGTK::MoveTo, try_again_pos
        addr_call draw_pascal_string, try_again_label
        jmp     LBB75

LBB5C:  MGTK_RELAY2_CALL MGTK::FrameRect, try_again_rect
        MGTK_RELAY2_CALL MGTK::MoveTo, try_again_pos
        addr_call draw_pascal_string, ok_label
LBB75:  MGTK_RELAY2_CALL MGTK::MoveTo, pos_prompt
        addr_call_indirect draw_pascal_string, prompt_addr
LBB87:  MGTK_RELAY2_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_down
        bne     LBB9A
        jmp     LBC0C

LBB9A:  cmp     #MGTK::event_kind_key_down
        bne     LBB87
        lda     event_key
        and     #$7F
        bit     alert_action
        bpl     LBBEE
        cmp     #CHAR_ESCAPE
        bne     LBBC3
        MGTK_RELAY2_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY2_CALL MGTK::PaintRect, cancel_rect
        lda     #$01
        jmp     LBC55

LBBC3:  bit     alert_action
        bvs     LBBEE
        cmp     #'a'
        bne     LBBE3
LBBCC:  MGTK_RELAY2_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY2_CALL MGTK::PaintRect, try_again_rect
        lda     #$00
        jmp     LBC55

LBBE3:  cmp     #'A'
        beq     LBBCC
        cmp     #CHAR_RETURN
        beq     LBBCC
        jmp     LBB87

LBBEE:  cmp     #CHAR_RETURN
        bne     LBC09
        MGTK_RELAY2_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY2_CALL MGTK::PaintRect, try_again_rect
        lda     #$02
        jmp     LBC55

LBC09:  jmp     LBB87

LBC0C:  jsr     LBDE1
        MGTK_RELAY2_CALL MGTK::MoveTo, event_coords
        bit     alert_action
        bpl     LBC42
        MGTK_RELAY2_CALL MGTK::InRect, cancel_rect
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     LBCE9
:       bit     alert_action
        bvs     LBC42
        MGTK_RELAY2_CALL MGTK::InRect, try_again_rect
        cmp     #MGTK::inrect_inside
        bne     LBC52
        jmp     LBC6D

LBC42:  MGTK_RELAY2_CALL MGTK::InRect, try_again_rect
        cmp     #MGTK::inrect_inside
        bne     LBC52
        jmp     LBD65

LBC52:  jmp     LBB87

LBC55:  pha
        MGTK_RELAY2_CALL MGTK::HideCursor
        jsr     LBE5D
        MGTK_RELAY2_CALL MGTK::ShowCursor
        pla
        rts

LBC6D:  MGTK_RELAY2_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY2_CALL MGTK::PaintRect, try_again_rect
        lda     #$00
        sta     LBCE8
LBC84:  MGTK_RELAY2_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_up
        beq     LBCDB
        jsr     LBDE1
        MGTK_RELAY2_CALL MGTK::MoveTo, event_coords
        MGTK_RELAY2_CALL MGTK::InRect, try_again_rect
        cmp     #MGTK::inrect_inside
        beq     LBCB5
        lda     LBCE8
        beq     LBCBD
        jmp     LBC84

LBCB5:  lda     LBCE8
        bne     LBCBD
        jmp     LBC84

LBCBD:  MGTK_RELAY2_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY2_CALL MGTK::PaintRect, try_again_rect
        lda     LBCE8
        clc
        adc     #$80
        sta     LBCE8
        jmp     LBC84

LBCDB:  lda     LBCE8
        beq     LBCE3
        jmp     LBB87

LBCE3:  lda     #$00
        jmp     LBC55

LBCE8:  .byte   0
LBCE9:  MGTK_RELAY2_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY2_CALL MGTK::PaintRect, cancel_rect
        lda     #$00
        sta     LBD64
LBD00:  MGTK_RELAY2_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_up
        beq     LBD57
        jsr     LBDE1
        MGTK_RELAY2_CALL MGTK::MoveTo, event_coords
        MGTK_RELAY2_CALL MGTK::InRect, cancel_rect
        cmp     #MGTK::inrect_inside
        beq     LBD31
        lda     LBD64
        beq     LBD39
        jmp     LBD00

LBD31:  lda     LBD64
        bne     LBD39
        jmp     LBD00

LBD39:  MGTK_RELAY2_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY2_CALL MGTK::PaintRect, cancel_rect
        lda     LBD64
        clc
        adc     #$80
        sta     LBD64
        jmp     LBD00

LBD57:  lda     LBD64
        beq     LBD5F
        jmp     LBB87

LBD5F:  lda     #$01
        jmp     LBC55

LBD64:  .byte   0
LBD65:  lda     #$00
        sta     LBDE0
        MGTK_RELAY2_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY2_CALL MGTK::PaintRect, try_again_rect
LBD7C:  MGTK_RELAY2_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::event_kind_button_up
        beq     LBDD3
        jsr     LBDE1
        MGTK_RELAY2_CALL MGTK::MoveTo, event_coords
        MGTK_RELAY2_CALL MGTK::InRect, try_again_rect
        cmp     #MGTK::inrect_inside
        beq     LBDAD
        lda     LBDE0
        beq     LBDB5
        jmp     LBD7C

LBDAD:  lda     LBDE0
        bne     LBDB5
        jmp     LBD7C

LBDB5:  MGTK_RELAY2_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY2_CALL MGTK::PaintRect, try_again_rect
        lda     LBDE0
        clc
        adc     #$80
        sta     LBDE0
        jmp     LBD7C

LBDD3:  lda     LBDE0
        beq     LBDDB
        jmp     LBB87

LBDDB:  lda     #$02
        jmp     LBC55
.endproc
        show_alert_dialog := show_alert_dialog_impl::start

;;; ============================================================

LBDE0:  .byte   0
LBDE1:  sub16   event_xcoord, portmap::viewloc::xcoord, event_xcoord
        sub16   event_ycoord, portmap::viewloc::ycoord, event_ycoord
        rts

.proc LBE08
        copy16  #$0800, LBE37
        lda     LBFC9
        jsr     LBF10
        lda     LBFCB
        sec
        sbc     LBFC9
        tax
        inx
LBE21:  lda     LBFCA
        sta     LBE5C
LBE27:  lda     LBE5C
        lsr     a
        tay
        sta     PAGE2OFF        ; main $2000-$3FFF
        bcs     LBE34
        sta     PAGE2ON         ; aux $2000-$3FFF
LBE34:  lda     ($06),y
LBE37           := * + 1
LBE38           := * + 2
        sta     dummy1234
        inc16   LBE37
        lda     LBE5C
        cmp     LBFCC
        bcs     LBE4E
        inc     LBE5C
        bne     LBE27
LBE4E:  jsr     LBF52
        dex
        bne     LBE21
        ldax    LBE37
        rts

        .byte   0
LBE5C:  .byte   0
.endproc

.proc LBE5D
        copy16  #$800, LBEBC
        ldx     LBFCD
        ldy     LBFCE
        lda     #$FF
        cpx     #$00
        beq     LBE78
LBE73:  clc
        rol     a
        dex
        bne     LBE73
LBE78:  sta     LBF0C
        eor     #$FF
        sta     LBF0D
        lda     #$01
        cpy     #$00
        beq     LBE8B
LBE86:  sec
        rol     a
        dey
        bne     LBE86
LBE8B:  sta     LBF0E
        eor     #$FF
        sta     LBF0F
        lda     LBFC9
        jsr     LBF10
        lda     LBFCB
        sec
        sbc     LBFC9
        tax
        inx
        lda     LBFCA
        sta     LBF0B
LBEA8:  lda     LBFCA
        sta     LBF0B
LBEAE:  lda     LBF0B
        lsr     a
        tay
        sta     PAGE2OFF        ; main $2000-$3FFF
        bcs     :+
        sta     PAGE2ON         ; aux $2000-$3FFF

        LBEBC := *+1
:       lda     $0800           ; self-modified

        pha
        lda     LBF0B
        cmp     LBFCA
        beq     LBEDD
        cmp     LBFCC
        bne     LBEEB
        lda     ($06),y
        and     LBF0F
        sta     ($06),y
        pla
        and     LBF0E
        ora     ($06),y
        pha
        jmp     LBEEB

LBEDD:  lda     ($06),y
        and     LBF0D
        sta     ($06),y
        pla
        and     LBF0C
        ora     ($06),y
        pha
LBEEB:  pla
        sta     ($06),y
        inc16   LBEBC
        lda     LBF0B
        cmp     LBFCC
        bcs     LBF03
        inc     LBF0B
        bne     LBEAE
LBF03:  jsr     LBF52
        dex
        bne     LBEA8
        rts

        .byte   $00
LBF0B:  .byte   $00
LBF0C:  .byte   $00
LBF0D:  .byte   $00
LBF0E:  .byte   $00
LBF0F:  .byte   $00
.endproc

;;; ============================================================

.proc LBF10
        sta     LBFCF
        and     #$07
        sta     LBFB0
        lda     LBFCF
        and     #$38
        sta     LBFAF
        lda     LBFCF
        and     #$C0
        sta     LBFAE
        jsr     LBF2C
        rts
.endproc

.proc LBF2C
        lda     LBFAE
        lsr     a
        lsr     a
        ora     LBFAE
        pha
        lda     LBFAF
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     LBF51
        pla
        ror     a
        sta     $06
        lda     LBFB0
        asl     a
        asl     a
        ora     LBF51
        ora     #$20
        sta     $07
        clc
        rts

LBF51:  .byte   0

.endproc

.proc LBF52
        lda     LBFB0
        cmp     #$07
        beq     LBF5F
        inc     LBFB0
        jmp     LBF2C

LBF5F:  lda     #$00
        sta     LBFB0
        lda     LBFAF
        cmp     #$38
        beq     LBF74
        clc
        adc     #$08
        sta     LBFAF
        jmp     LBF2C

LBF74:  lda     #$00
        sta     LBFAF
        lda     LBFAE
        clc
        adc     #$40
        sta     LBFAE
        cmp     #$C0
        beq     LBF89
        jmp     LBF2C

LBF89:  sec
        rts
.endproc

.proc LBF8B
        ldy     #$00
        cpx     #$02
        bne     LBF96
        ldy     #$49
        clc
        adc     #$01
LBF96:  cpx     #$01
        bne     LBFA4
        ldy     #$24
        clc
        adc     #$04
        bcc     LBFA4
        iny
        sbc     #$07
LBFA4:  cmp     #$07
        bcc     LBFAD
        sbc     #$07
        iny
        bne     LBFA4
LBFAD:  rts
.endproc

LBFAE:  .byte   $00
LBFAF:  .byte   $00
LBFB0:  .byte   $00,$FF,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00
LBFC9:  .byte   $00
LBFCA:  .byte   $00
LBFCB:  .byte   $00
LBFCC:  .byte   $00
LBFCD:  .byte   $00
LBFCE:  .byte   $00
LBFCF:  .byte   $00

        ;; Draw pascal string; address in (X,A)
.proc draw_pascal_string
        ptr := $06

        stax    ptr
        ldy     #$00
        lda     (ptr),y         ; Check length
        beq     end
        sta     ptr+2
        inc     ptr
        bne     call
        inc     ptr+1
call:   MGTK_RELAY2_CALL MGTK::DrawText, ptr
end:    rts
.endproc

        ;; MGTK call in Y, params addr (X,A)
.proc MGTK_RELAY2
        sty     call
        stax    addr
        jsr     MGTK::MLI
call:   .byte   0
addr:   .addr   0
        rts
.endproc

        .assert * = $BFFC, error, "Segment length mismatch"
        PAD_TO $C000
.endproc ; desktop_aux
