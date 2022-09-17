;;; ============================================================
;;; Entry point for "Icon ToolKit"
;;; ============================================================

.scope icon_toolkit
        ITKEntry := *

.proc Dispatch
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
        ldx     #AS_BYTE(-4)
:       lda     $06 + 4,x
        pha
        inx
        bne     :-

        ;; Point ($06) at call command
        copy16  call_params, $06

        ldy     #1              ; Note: RTS address is off-by-one
        lda     ($06),y         ; command number
        tax
        copylohi jump_table_low,x, jump_table_high,x, dispatch
        iny
        lda     ($06),y         ; params address
        tax
        iny
        lda     ($06),y
        sta     $07             ; point $06 at params
        stx     $06

        dispatch := *+1
        jsr     SELF_MODIFIED
        tay                     ; A = result

        ;; Restore $06..$09
        ldx     #3
:       pla
        sta     $06,x
        dex
        bpl     :-

        tya                     ; A = result
        rts

call_params:  .addr     0
.endproc

jump_table_low:
        .byte   <InitToolKitImpl
        .byte   <AddIconImpl
        .byte   <HighlightIconImpl
        .byte   <DrawIconImpl
        .byte   <RemoveIconImpl
        .byte   <RemoveAllImpl
        .byte   <CloseWindowImpl
        .byte   <FindIconImpl
        .byte   <DragHighlightedImpl
        .byte   <UnhighlightIconImpl
        .byte   <RedrawDesktopIconsImpl
        .byte   <IconInRectImpl
        .byte   <EraseIconImpl

jump_table_high:
        .byte   >InitToolKitImpl
        .byte   >AddIconImpl
        .byte   >HighlightIconImpl
        .byte   >DrawIconImpl
        .byte   >RemoveIconImpl
        .byte   >RemoveAllImpl
        .byte   >CloseWindowImpl
        .byte   >FindIconImpl
        .byte   >DragHighlightedImpl
        .byte   >UnhighlightIconImpl
        .byte   >RedrawDesktopIconsImpl
        .byte   >IconInRectImpl
        .byte   >EraseIconImpl

;;; ============================================================

;;; Set by CalcIconXXXX methods

        DEFINE_RECT bitmap_rect, 0,0,0,0 ; bitmap portion of icon
        DEFINE_RECT label_rect, 0,0,0,0  ; label portion of icon
        DEFINE_RECT bounding_rect, 0,0,0,0 ; overall bounding box of above

kPolySize = 8

.params poly
num_vertices:   .byte   kPolySize
lastpoly:       .byte   0       ; 0 = last poly
vertices:
        DEFINE_POINT v0, 0, 0
        DEFINE_POINT v1, 0, 0
        DEFINE_POINT v2, 0, 0
        DEFINE_POINT v3, 0, 0
        DEFINE_POINT v4, 0, 0
        DEFINE_POINT v5, 0, 0
        DEFINE_POINT v6, 0, 0
        DEFINE_POINT v7, 0, 0
.endparams

;;; ============================================================

.params icon_paintbits_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 0, 0
.endparams

.params mask_paintbits_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 0, 0
.endparams

.params textwidth_params
textptr:        .addr   text_buffer
textlen:        .byte   0
result: .word   0
.endparams
settextbg_params    := textwidth_params::result + 1  ; re-used

.params drawtext_params
textptr:        .addr   text_buffer
textlen:        .byte   0
.endparams
        ;; `text_buffer` contains only the characters; the length
        ;; is in `drawtext_params::textlen`
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

checkerboard_pattern:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

dark_pattern:
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100

penOR:  .byte   MGTK::penOR
penXOR: .byte   MGTK::penXOR
penBIC: .byte   MGTK::penBIC

;;; ============================================================
;;; Icon (i.e. file, volume) details

num_icons:  .byte   0
icon_list:  .res    (::kMaxIconCount+1), 0   ; list of allocated icons (index 0 not used)

icon_ptrs_low:  .res    (::kMaxIconCount+1), 0 ; addresses of icon details (index 0 not used)
icon_ptrs_high: .res    (::kMaxIconCount+1), 0 ; addresses of icon details (index 0 not used)

highlight_count:                ; number of highlighted icons
        .byte   0
highlight_list:                 ; selected icons
        .res    ::kMaxIconCount, 0


;;; ============================================================
;;; Initialization parameters passed by client

;;; Vertical offset within windows
header_height:  .byte   0

;;; Polygon holding the composite outlines of all icons being dragged.
;;; Re-use the "save area" ($800-$1AFF) since menus won't show during
;;; this kOperation.
polybuf_addr:           .addr   0
max_draggable_icons:    .byte  0

;;; ============================================================

.params peekevent_params
kind:   .byte   0               ; spills into next block
.endparams

;;; `findwindow_params::window_id` is used as first part of
;;; GetWinPtr params structure including `window_ptr`.
.params findwindow_params
mousex: .word   0
mousey: .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams
window_ptr:  .word   0          ; do not move this; see above

.params findcontrol_params
mousex: .word   0
mousey: .word   0
which_ctl:      .byte   0
which_part:     .byte   0
.endparams

;;; GrafPort used to restore port after clipping for volume
grafport:       .tag    MGTK::GrafPort

;;; GrafPort used to draw icon outlines during drag
drag_outline_grafport:  .tag    MGTK::GrafPort

.params getwinport_params
window_id:      .byte   0
a_grafport:     .addr   icon_grafport
.endparams

icon_grafport:  .tag    MGTK::GrafPort

.params moveto_params2
xcoord: .word   0
ycoord: .word   0
.endparams

;;; ============================================================
;;; InitToolKit

.proc InitToolKitImpl
        params := $06
.struct InitToolKitParams
headersize      .byte
a_polybuf       .addr
bufsize         .word
.endstruct

        ldy     #InitToolKitParams::headersize
        copy    (params),y, header_height
        iny                     ; Y = InitToolKitParams::a_polybuf
        copy16in (params),y, polybuf_addr
        iny                     ; Y = InitToolKitParams::bufsize
        copy16in (params),y, bufsize

        ;; MaxDraggableItems = BufferSize / kIconPolySize

        ldy     #0
:       sub16_8 bufsize, #kIconPolySize, bufsize
        bit     bufsize+1
        bmi     :+
        iny
        bne     :-              ; always
:       sty     max_draggable_icons

        rts

bufsize:
        .word   0
.endproc

;;; ============================================================
;;; AddIcon

.proc AddIconImpl
        ;; Parameter is an IconEntry
        ptr_icon := $06

        ;; Check if passed ID is already in the icon list
        ldy     #IconEntry::id
        lda     (ptr_icon),y ; A = icon id
        jsr     IsInIconList
        bne     :+
        return  #1              ; That icon id is already in use

        ;; Add it to `icon_list`
:       ldx     num_icons
        sta     icon_list,x
        inc     num_icons

        ;; Add to `icon_ptrs` table
        tax
        copylohi  ptr_icon, icon_ptrs_low,x, icon_ptrs_high,x

        lda     #1              ; $01 = allocated
        tay                     ; And IconEntry::state
        sta     (ptr_icon),y
        lsr

        rts
.endproc

;;; ============================================================
;;; Tests if the passed icon id is in `icon_list`
;;; Inputs: A = icon id
;;; Outputs: Z=1 if found (and X = index), Z=0 otherwise
;;; A is unmodified, X is trashed

.proc IsInIconList
        ldx     num_icons
:       dex
        bmi     done            ; X=#$FF, Z=0
        cmp     icon_list,x
        bne     :-              ; not found

done:   rts
.endproc

;;; ============================================================
;;; HighlightIcon

;;; param is pointer to icon id

.proc HighlightIconImpl
        params := $06
.struct HighlightIconParams
        icon    .byte
.endstruct

        ptr := $06              ; Overwrites params

        ;; Pointer to IconEntry
        ldy     #HighlightIconParams::icon
        lda     (params),y
        tax
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        ldy     #IconEntry::state
        lda     (ptr),y         ; valid icon?
        bne     :+
        return  #2              ; Invalid icon
:
        ;;and     #kIconEntryStateHighlighted
        .assert kIconEntryStateHighlighted = $40, error, "kIconEntryStateHighlighted must be $40"
        asl
        bpl     :+
        return  #3              ; Already highlighted
:
        ;; Mark highlighted
        ror
        ora     #kIconEntryStateHighlighted
        sta     (ptr),y

        ;; Append to highlight list
        ;;ldy     #IconEntry::id
        .assert (IconEntry::state - IconEntry::id) = 1, error, "id must be 1 less than state"
        dey
        lda     (ptr),y         ; A = icon id
        ldx     highlight_count
        sta     highlight_list,x
        inc     highlight_count

        ;; Move it to the head of the highlight list
        ldx     #1              ; new position
        jsr     ChangeHighlightIndex

        ldy     #IconEntry::id
        lda     (ptr),y         ; A = icon id
        ldx     #1              ; new position
        jmp     ChangeIconIndex
.endproc

;;; ============================================================
;;; DrawIcon

;;; * Assumes correct grafport already selected/maprect specified
;;; * Does not erase background

.proc DrawIconImpl
        params := $06
.struct DrawIconParams
        icon    .byte
.endstruct

        ptr := $06              ; Overwrites params

        ;; Pointer to IconEntry
        ldy     #DrawIconParams::icon
        lda     (params),y
        tax
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        jsr     CalcIconRects

        ldy     #IconEntry::state
        lda     (ptr),y         ; highlighted?
        asl
        bmi     :+

        jsr     paint_icon_unhighlighted
        return  #0

:       jsr     paint_icon_highlighted
        return  #0
.endproc

;;; ============================================================
;;; RemoveIcon

;;; param is pointer to icon number

.proc RemoveIconImpl
        params := $06
.struct RemoveIconParams
        icon    .byte
.endstruct

        ptr := $08

        ;; Is it in `icon_list`?
        ldy     #RemoveIconParams::icon
        lda     (params),y
        jsr     IsInIconList
        beq     :+
        return  #1              ; Not found

        ;; Pointer to IconEntry
:       tax
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        ldy     #IconEntry::state ; valid icon?
        lda     (ptr),y
        bne     :+
        return  #2
:
        jsr     RemoveIconCommon
        return  #0
.endproc

;;; ============================================================
;;; Remove the icon at $08

.proc RemoveIconCommon
        ptr := $08

        ;; Move it to the end of `icon_list`
        ldy     #IconEntry::id
        lda     (ptr),y         ; icon num
        ldx     num_icons       ; new position
        jsr     ChangeIconIndex

        ;; Remove it
        dec     num_icons
        lda     #0
        ldx     num_icons
        sta     icon_list,x

        ;; Mark it as free
        ldy     #IconEntry::state
        lda     (ptr),y         ; A = state
        ;; Was it highlighted?
        ;;and     #kIconEntryStateHighlighted
        .assert kIconEntryStateHighlighted = $40, error, "kIconEntryStateHighlighted must be $40"
        asl
        asl                     ; carry set if highlighted
        lda     #0              ; not allocated
        sta     (ptr),y

        bcc     :+              ; not highlighted

        ;;ldy     #IconEntry::id
        .assert (IconEntry::state - IconEntry::id) = 1, error, "id must be 1 less than state"
        dey
        lda     (ptr),y         ; A = icon id
        jsr     RemoveFromHighlightList

:       rts
.endproc

;;; ============================================================
;;; EraseIcon

.proc EraseIconImpl
        params := $06
.struct EraseIconParams
        icon    .byte
.endstruct

        ptr := $06              ; Overwrites params

        ;; Pointer to IconEntry
        ldy     #EraseIconParams::icon
        lda     (params),y
        tax
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        jsr     CalcIconPoly
        lda     #$80            ; redraw highlighted
        jmp     EraseIconCommon
.endproc

;;; ============================================================
;;; RemoveAll

;;; param is window id (0 = desktop)

.proc RemoveAllImpl
        params := $06
.struct RemoveAllParams
        window_id       .byte
.endstruct

        icon_ptr := $08

        lda     num_icons
        sta     count

loop:   ldx     count
        beq     done
        dec     count
        dex

        ldy     icon_list,x
        sty     icon
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, icon_ptr
        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        ldy     #RemoveAllParams::window_id
        cmp     (params),y
        bne     loop
        ITK_CALL IconTK::RemoveIcon, icon

        jmp     loop

done:   return  #0

        ;; IconTK::RemoveIcon params
icon:   .byte   0

count:  .byte   0
.endproc

;;; ============================================================
;;; CloseWindow

;;; param is window id

.proc CloseWindowImpl
        params := $06
.struct CloseWindowParams
        window_id       .byte
.endstruct

        ptr := $08

        lda     num_icons
        sta     count
count := * + 1
loop:   ldx     #SELF_MODIFIED_BYTE
        bne     :+
        txa
        rts

:       dec     count
        dex
        ldy     icon_list,x
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, ptr
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask ; check window
        ldy     #CloseWindowParams::window_id
        cmp     (params),y ; match?
        bne     loop                 ; nope

        jsr     RemoveIconCommon

        jmp     loop
.endproc

;;; ============================================================
;;; FindIcon

.proc FindIconImpl
        params := $06
.struct FindIconParams
        coords  .tag MGTK::Point
        result  .byte
        window_id       .byte
.endstruct

        icon_ptr   := $06       ; for `CalcIconPoly` call
        out_params := $08

        ;; Copy coords at $6 to param block
        .assert FindIconParams::coords = 0, error, "coords must come first"
        ldy     #.sizeof(MGTK::Point)-1
:       lda     (params),y
        sta     moveto_params2,y
        dey
        bpl     :-

        copy16  params, out_params

        ldy     #FindIconParams::window_id
        lda     (params),y
        sta     window_id

        MGTK_CALL MGTK::MoveTo, moveto_params2

        ldx     #0
loop:   cpx     num_icons
        bne     :+

        ;; Nothing found
        ldy     #FindIconParams::result
        lda     #0
        sta     (out_params),y
        rts

        ;; Check the icon
:       txa
        pha
        ldy     icon_list,x
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, icon_ptr

        ;; Matching window?
        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask

window_id := * + 1
        cmp     #SELF_MODIFIED_BYTE
        bne     :+

        ;; In poly?
        jsr     CalcIconPoly    ; requires `icon_ptr` set
        MGTK_CALL MGTK::InPoly, poly
        bne     inside          ; yes!

        ;; Nope, next
:       pla
        tax
        inx
        bne     loop            ; always

        ;; Found one!
inside: pla
        tax
        lda     icon_list,x
        ldy     #FindIconParams::result
        sta     (out_params),y
        rts
.endproc

;;; ============================================================
;;; DragHighlighted

.proc DragHighlightedImpl
        params := $06
.struct DragHighlightedParams
        icon    .byte
        coords  .tag    MGTK::Point
.endstruct

        ldy     #DragHighlightedParams::icon
        lda     ($06),y
        sta     icon_id
        tya
        sta     ($06),y

        ;; Copy coords (at params+1) to
        ldy     #DragHighlightedParams::coords + .sizeof(MGTK::Point)-1
:       lda     ($06),y
        sta     coords1-1,y
        sta     coords2-1,y
        dey
        ;;cpy     #DragHighlightedParams::coords-1
        .assert DragHighlightedParams::coords = 1, error, "coords must be 1"
        bne     :-

        jsr     PushPointers
        jmp     start           ; skip over data

icon_id:
        .byte   $00

deltax: .word   0
deltay: .word   0

        ;; IconTK::HighlightIcon params
highlight_icon_id:  .byte   $00

window_id:              .byte   0
source_window_id:       .byte   0 ; source window of drag (0=desktop)
trash_flag:             .byte   0 ; if Trash is included in selection

        ;; IconTK::IconInRect params
.params iconinrect_params
icon:  .byte    0
rect:  .tag     MGTK::Rect
.endparams

start:  lda     #0
        sta     highlight_icon_id
        sta     trash_flag

;;; Determine if it's a drag or just a click
.proc DragDetect

peek:   MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::EventKind::drag
        beq     drag

ignore_drag:
        lda     #2              ; return value
        jmp     just_select

        ;; Compute mouse delta
drag:   lda     findwindow_params::mousex
        sec
        sbc     coords1x
        tax
        lda     findwindow_params::mousex + 1
        sbc     coords1x + 1

        kDragDelta = 5

        ;; compare x delta
        bpl     x_lo
        cpx     #AS_BYTE(-kDragDelta)
        bcc     is_drag
        bcs     check_deltay
x_lo:   cpx     #kDragDelta
        bcs     is_drag

        ;; compare y delta
check_deltay:
        lda     findwindow_params::mousey
        sec
        sbc     coords1y
        tax
        lda     findwindow_params::mousey + 1
        sbc     coords1y + 1
        bpl     y_lo
        cpx     #AS_BYTE(-kDragDelta)
        bcc     is_drag
        bcs     peek
y_lo:   cpx     #kDragDelta
        bcc     peek
        FALL_THROUGH_TO is_drag
.endproc

        ;; Meets the threshold - it is a drag, not just a click.
is_drag:
        lda     highlight_count
        cmp     max_draggable_icons
        beq     :+                      ; equal okay
        bcs     DragDetect::ignore_drag ; too many
:
        ;; Was there a selection?
        copy16  polybuf_addr, $08
        lda     highlight_count
        bne     :+
        lda     #3              ; return value
        jmp     just_select

:       lda     highlight_list  ; first entry
        jsr     GetIconWin
        sta     source_window_id

        ;; Prepare grafports
        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::InitPort, drag_outline_grafport
        MGTK_CALL MGTK::SetPort, drag_outline_grafport
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        MGTK_CALL MGTK::SetPenMode, penXOR

        ;; Since SetZP1 is used, ask MGTK to update the GrafPort.
        port_ptr := $06
        MGTK_CALL MGTK::GetPort, port_ptr

        COPY_STRUCT MGTK::Rect, drag_outline_grafport+MGTK::GrafPort::maprect, iconinrect_params::rect

        ldx     highlight_count
        stx     L9C74

L98F2:  lda     highlight_count,x
        jsr     GetIconPtr
        stax    $06
        ldy     #IconEntry::id
        lda     ($06),y
        sta     iconinrect_params::icon

        ldy     #IconEntry::win_flags
        lda     ($06),y
        and     #kIconEntryFlagsNotDropSource
        beq     :+
        ldx     #$80
        stx     trash_flag
:
        ITK_CALL IconTK::IconInRect, iconinrect_params::icon
        beq     L9954
        jsr     CalcIconPoly
        lda     L9C74
        cmp     highlight_count
        beq     L9936
        jsr     PushPointers

        lda     $08
        sec
        sbc     #kIconPolySize
        sta     $08
        bcs     :+
        dec     $08+1

:       ldy     #1              ; MGTK Polygon "not last" flag
        lda     #$80            ; more polygons to follow
        sta     ($08),y
        jsr     PopPointers

L9936:  ldy     #kIconPolySize-1

:       lda     poly,y
        sta     ($08),y
        dey
        bpl     :-

        lda     #8
        iny
        sta     ($08),y
        lda     $08
        clc
        adc     #kIconPolySize
        sta     $08
        bcc     L9954
        inc     $08+1
L9954:  dec     L9C74
        ldx     L9C74
        bne     L98F2

        copy16  polybuf_addr, $08
        ;; Copy 8 bytes from poly+2 to rect1
        ldx     #8-1
        ldy     #2+8-1
:       lda     ($08),y
        sta     rect1,x
        dey
        dex
        bpl     :-

L9972:  ldy     #2

L9974:  lda     ($08),y
        cmp     rect1_x1
        iny
        lda     ($08),y
        sbc     rect1_x1+1
        bcs     L9990
        lda     ($08),y
        sta     rect1_x1+1
        dey
        lda     ($08),y
        sta     rect1_x1
        iny
        bne     L99AA           ; always

L9990:  dey
        lda     ($08),y
        cmp     rect1_x2
        iny
        lda     ($08),y
        sbc     rect1_x2+1
        bcc     L99AA

        lda     ($08),y
        sta     rect1_x2+1
        dey
        lda     ($08),y
        sta     rect1_x2
        iny

L99AA:  iny
        lda     ($08),y
        cmp     rect1_y1
        iny
        lda     ($08),y
        sbc     rect1_y1+1
        bcs     L99C7

        lda     ($08),y
        sta     rect1_y1+1
        dey
        lda     ($08),y
        sta     rect1_y1
        iny
        bne     L99E1           ; always

L99C7:  dey
        lda     ($08),y
        cmp     rect1_y2
        iny
        lda     ($08),y
        sbc     rect1_y2+1
        bcc     L99E1

        lda     ($08),y
        sta     rect1_y2+1
        dey
        lda     ($08),y
        sta     rect1_y2
        iny

L99E1:  iny
        cpy     #kIconPolySize
        bne     L9974
        ldy     #1              ; MGTK Polygon "not last" flag
        lda     ($08),y
        beq     L99FC
        lda     $08             ; missing CLC???
        adc     #kIconPolySize - 1 ; why -1 ???
        sta     $08
        bcc     L9972
        inc     $09
        jmp     L9972

L99FC:  jsr     XdrawOutline

peek:   MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::EventKind::drag
        beq     L9A1E
        jmp     L9BA5

L9A1E:  ldx     #3
L9A20:  lda     findwindow_params,x
        cmp     coords2,x
        bne     L9A31
        dex
        bpl     L9A20
        jsr     FindTargetAndHighlight
        jmp     peek

L9A31:  COPY_BYTES 4, findwindow_params, coords2

        ;; Still over the highlighted icon?
        lda     highlight_icon_id
        beq     :+
        copy    window_id, findwindow_params::window_id
        ITK_CALL IconTK::FindIcon, findwindow_params
        lda     findwindow_params::which_area ; Icon ID
        cmp     highlight_icon_id             ; already over it?
        beq     :+

        ;; No longer over the highlighted icon - unhighlight it
        jsr     XdrawOutline
        jsr     UnhighlightIcon
        jsr     XdrawOutline
        lda     #0
        sta     highlight_icon_id

:       sub16   findwindow_params::mousex, coords1x, rect3_x1
        sub16   findwindow_params::mousey, coords1y, rect3_y1
        jsr     SetRect2ToRect1

        ldx     #0
        stx     L9C75
:       add16   rect1_x2,x, rect3_x1,x, rect1_x2,x
        add16   rect1_x1,x, rect3_x1,x, rect1_x1,x
        inx
        inx
        cpx     #4
        bne     :-

        lda     rect1_x1+1
        bmi     L9AF7
        cmp16   rect1_x2, #kScreenWidth
        bcs     L9AFE
        jsr     SetCoords1xToMousex
        bcc     L9B0E           ; always

L9AF7:  jsr     L9CAA
        bmi     L9B0E
        bpl     L9B03
L9AFE:  jsr     L9CD1
        bmi     L9B0E
L9B03:  jsr     SetRect1ToRect2AndZeroRect3X
        sec
        ror     L9C75
L9B0E:  lda     rect1_y1+1
        bmi     L9B31
        cmp16   rect1_y1, #kMenuBarHeight
        bcc     L9B31
        cmp16   rect1_y2, #kScreenHeight
        bcs     L9B38
        jsr     SetCoords1yToMousey
        bcc     L9B48           ; always

L9B31:  jsr     L9D31
        bmi     L9B48
        bpl     L9B3D
L9B38:  jsr     L9D58
        bmi     L9B48
L9B3D:  jsr     SetRect1ToRect2AndZeroRect3Y
        lda     L9C75
        ora     #$40
        sta     L9C75
L9B48:  bit     L9C75
        bpl     L9B52
        bvc     L9B52
        jmp     peek

L9B52:  jsr     XdrawOutline
        copy16  polybuf_addr, $08
L9B60:  ldy     #2
L9B62:  add16in ($08),y, rect3_x1, ($08),y
        iny
        add16in ($08),y, rect3_y1, ($08),y
        iny
        cpy     #kIconPolySize
        bne     L9B62
        ldy     #1              ; MGTK Polygon "not last" flag
        lda     ($08),y
        beq     L9B9C
        lda     $08
        clc
        adc     #kIconPolySize
        sta     $08
        bcc     L9B60
        inc     $08+1
        bcs     L9B60

L9B9C:  jsr     XdrawOutline
        jmp     peek

L9BA5:  jsr     XdrawOutline
        lda     highlight_icon_id
        beq     :+
        jsr     UnhighlightIcon
        jmp     L9C63

:       MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     source_window_id
        beq     same_window

        bit     trash_flag
        bmi     includes_trash

        lda     findwindow_params::window_id
        bne     L9BD4
ignore: jmp     DragDetect::ignore_drag

L9BD4:  ora     #$80
        sta     highlight_icon_id
        bne     L9C63           ; always

        ;; Drop selection including Trash on a window
includes_trash:
        lda     source_window_id
        beq     ignore          ; TODO: always true for Trash?

        ;; Drag within same window (or desktop)
same_window:
        jsr     PushPointers

        ldx     highlight_count
:       dex
        bmi     :+
        txa
        pha
        ldy     highlight_list,x
        copylohi  icon_ptrs_low,y, icon_ptrs_high,y, $06
        jsr     CalcIconPoly
        lda     #0              ; don't redraw highlighted
        jsr     EraseIconCommon
        pla
        tax
        bpl     :-              ; always
:
        jsr     PopPointers

        ldx     highlight_count
        copy16  polybuf_addr, $08
@loop:  dex
        bmi     L9C63
        ldy     highlight_list,x
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, $06
        ldy     #IconEntry::win_flags
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
        lda     $08
        clc
        adc     #kIconPolySize
        sta     $08
        bcc     @loop
        inc     $08+1
        bne     @loop           ; always

L9C63:  lda     #0              ; return value

just_select:                    ; ???
        tay
        jsr     PopPointers
        tya
        tax
        ldy     #0
        lda     highlight_icon_id
        sta     ($06),y
        txa
        rts

L9C74:  .byte   $00
L9C75:  .byte   $00

rect1:
rect1_x1:       .word   0
rect1_y1:       .word   0
rect1_x2:       .word   0
rect1_y2:       .word   0

L9C7E:  .word   0
L9C80:  .word   kMenuBarHeight
const_screen_width:     .word   kScreenWidth
const_screen_height:    .word   kScreenHeight

rect2:
rect2_x1:       .word   0
rect2_y1:       .word   0
rect2_x2:       .word   0
rect2_y2:       .word   0

coords1:
coords1x:       .word   0
coords1y:       .word   0

coords2:        .tag MGTK::Point

rect3:
rect3_x1:       .word   0
rect3_y1:       .word   0
rect3_x2:       .word   0       ; Unused???
rect3_y2:       .word   0       ; Unused???

.proc SetRect2ToRect1
        COPY_STRUCT MGTK::Rect, rect1, rect2
        rts
.endproc

.proc L9CAA
        lda     rect1_x1
        cmp     L9C7E
        bne     :+
        lda     rect1_x1+1
        eor     L9C7E+1
        bne     :+
        rts

:       lda     #0
        sec
        sbc     rect2_x1
        tax
        lda     #0
        sbc     rect2_x1 + 1
        tay
        jmp     L9CF5
.endproc

.proc L9CD1
        lda     rect1_x2
        cmp     const_screen_width
        bne     L9CE4
        lda     rect1_x2+1
        eor     const_screen_width+1
        bne     L9CE4
        rts
.endproc

L9CE4:  lda     #<kScreenWidth
        sec
        sbc     rect2_x2
        tax
        lda     #>kScreenWidth
        sbc     rect2_x2 + 1
        tay
L9CF5:  stx     rect3_x1
        sty     rect3_x1 + 1
        txa
        clc
        adc     rect2_x1
        sta     rect1_x1
        tya
        adc     rect2_x1 + 1
        sta     rect1_x1 + 1
        txa
        clc
        adc     rect2_x2
        sta     rect1_x2
        tya
        adc     rect2_x2 + 1
        sta     rect1_x2 + 1
        txa
        clc
        adc     coords1x
        sta     coords1x
        tya
        adc     coords1x + 1
        sta     coords1x + 1
        return  #$FF

.proc L9D31
        lda     rect1_y1
        cmp     L9C80
        bne     :+
        lda     rect1_y1+1
        eor     L9C80+1
        bne     :+
        rts

:       lda     #<kMenuBarHeight
        sec
        sbc     rect2_y1
        tax
        lda     #>kMenuBarHeight
        sbc     rect2_y1 + 1
        tay
        jmp     L9D7C
.endproc

.proc L9D58
        lda     rect1_y2
        cmp     const_screen_height
        bne     L9D6B
        lda     rect1_y2+1
        eor     const_screen_height+1
        bne     L9D6B
        rts
.endproc

L9D6B:  lda     #<(kScreenHeight-1)
        sec
        sbc     rect2_y2
        tax
        lda     #>(kScreenHeight-1)
        sbc     rect2_y2 + 1
        tay
L9D7C:  stx     rect3_y1
        sty     rect3_y1 + 1
        txa
        clc
        adc     rect2_y1
        sta     rect1_y1
        tya
        adc     rect2_y1 + 1
        sta     rect1_y1 + 1
        txa
        clc
        adc     rect2_y2
        sta     rect1_y2
        tya
        adc     rect2_y2 + 1
        sta     rect1_y2 + 1
        txa
        clc
        adc     coords1y
        sta     coords1y
        tya
        adc     coords1y + 1
        sta     coords1y + 1
        return  #$FF

.proc SetRect1ToRect2AndZeroRect3X
        ldx     #0
        beq     SetRectCommon   ; always
.endproc

.proc SetRect1ToRect2AndZeroRect3Y
        ldx     #rect2_y1 - rect2_x1
        FALL_THROUGH_TO SetRectCommon
.endproc

.proc SetRectCommon
        copy16  rect2_y1,x, rect1_y1,x
        copy16  rect2_y2,x, rect1_y2,x
        copy16  #0, rect3_y1,x
        rts
.endproc

.proc SetCoords1xToMousex
        lda     findwindow_params::mousex+1
        sta     coords1x+1
        lda     findwindow_params::mousex
        sta     coords1x
        rts
.endproc

.proc SetCoords1yToMousey
        lda     findwindow_params::mousey+1
        sta     coords1y+1
        lda     findwindow_params::mousey
        sta     coords1y
        rts
.endproc

.proc FindTargetAndHighlight
        bit     trash_flag      ; Trash is not drop-able, so skip if in selection
        bpl     :+
        rts

:       jsr     PushPointers
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        beq     desktop

        ;; --------------------------------------------------
        ;; In a window - ensure it's in the content area
        cmp     #MGTK::Area::content
        beq     :+
        jmp     done            ; menubar, titlebar, etc
:       COPY_STRUCT MGTK::Point, findwindow_params::mousex, findcontrol_params::mousex
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        bne     done            ; scrollbar, etc.
                                ; else 0 = MGTK::Ctl::not_a_control
        ;; Ignore if y coord < window's header height
        MGTK_CALL MGTK::GetWinPtr, findwindow_params::window_id
        win_ptr := $06
        copy16  window_ptr, win_ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        add16in (win_ptr),y, #kWindowHeaderHeight + 1, headery
        cmp16   findwindow_params::mousey, headery
        bcc     done
        bcs     find_icon       ; always

        ;; --------------------------------------------------
        ;; On desktop - A=0, note that as window_id
desktop:
        sta     findwindow_params::window_id

find_icon:
        ITK_CALL IconTK::FindIcon, findwindow_params
        ldx     findwindow_params::which_area ; Icon ID
        beq     done

        ;; Over an icon
        stx     icon_num

        ptr := $06
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        ;; Highlighted?
        ldy     #IconEntry::state
        lda     (ptr),y
        ;;and     #kIconEntryStateHighlighted
        .assert kIconEntryStateHighlighted = $40, error, "kIconEntryStateHighlighted must be $40"
        asl
        bmi     done            ; Not valid (it's being dragged)

        ;; Is it a drop target?
        ;;ldy     #IconEntry::win_flags
        .assert (IconEntry::win_flags - IconEntry::state) = 1, error, "win_flags must be 1 more than state"
        iny
        lda     (ptr),y
        ;;and     #kIconEntryFlagsDropTarget
        .assert kIconEntryFlagsDropTarget = $40, error, "kIconEntryFlagsDropTarget must be $40"
        asl
        bpl     done

        ;; Stash window for the future
        lsr
        and     #kIconEntryWinIdMask
        sta     window_id

        ;; Highlight it!
        lda     icon_num
        sta     highlight_icon_id
        jsr     XdrawOutline
        jsr     HighlightIcon
        jsr     XdrawOutline

done:   jsr     PopPointers     ; do not tail-call optimise!
        rts

icon_num:
        .byte   0

headery:
        .word   0
.endproc

;;; Input: A = icon number
;;; Output: A,X = address of IconEntry
.proc GetIconPtr
        tay
        ldx     icon_ptrs_high,y
        lda     icon_ptrs_low,y
        rts
.endproc

;;; Input: A = icon number
;;; Output: A = window id (0=desktop)
;;; Trashes $06
.proc GetIconWin
        ptr := $06

        jsr     GetIconPtr
        stax    ptr
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        rts
.endproc

.proc XdrawOutline
        MGTK_CALL MGTK::SetPort, drag_outline_grafport
        copy16  polybuf_addr, addr
        MGTK_CALL MGTK::FramePoly, SELF_MODIFIED, addr
        rts
.endproc

.proc HighlightIcon
        jsr SetPortForHighlightIcon
        ITK_CALL IconTK::HighlightIcon, highlight_icon_id
        ITK_CALL IconTK::DrawIcon, highlight_icon_id
        MGTK_CALL MGTK::InitPort, icon_grafport
        rts
.endproc

.proc UnhighlightIcon
        jsr SetPortForHighlightIcon
        ITK_CALL IconTK::UnhighlightIcon, highlight_icon_id
        ITK_CALL IconTK::DrawIcon, highlight_icon_id
        MGTK_CALL MGTK::InitPort, icon_grafport
        rts
.endproc

;;; Set maprect to `highlight_icon_id`'s window's content area, in screen
;;; space, using `icon_grafport`.
.proc SetPortForHighlightIcon
        ptr := $06

        lda     highlight_icon_id
        jsr     GetIconWin
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params ; into icon_grafport

        sub16   icon_grafport+MGTK::GrafPort::maprect+MGTK::Rect::x2, icon_grafport+MGTK::GrafPort::maprect+MGTK::Rect::x1, width
        sub16   icon_grafport+MGTK::GrafPort::maprect+MGTK::Rect::y2, icon_grafport+MGTK::GrafPort::maprect+MGTK::Rect::y1, height

        COPY_STRUCT MGTK::Point, icon_grafport+MGTK::GrafPort::viewloc, icon_grafport+MGTK::GrafPort::maprect

        add16   icon_grafport+MGTK::GrafPort::maprect+MGTK::Rect::x1, width, icon_grafport+MGTK::GrafPort::maprect+MGTK::Rect::x2
        add16   icon_grafport+MGTK::GrafPort::maprect+MGTK::Rect::y1, height, icon_grafport+MGTK::GrafPort::maprect+MGTK::Rect::y2

        ;; Account for window header, and set port to icon_grafport
        jmp     ShiftPortDown

width:  .word   0
height: .word   0

.endproc


.endproc

;;; ============================================================
;;; UnhighlightIcon

;;; param is pointer to IconEntry

.proc UnhighlightIconImpl
        params := $06
.struct UnhighlightIconParams
        icon    .byte
.endstruct

        ptr := $06              ; Overwrites params

        ;; Pointer to IconEntry
        ldy     #UnhighlightIconParams::icon
        lda     (params),y
        tax
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        ;;ldy     #IconEntry::state
        .assert (IconEntry::state - UnhighlightIconParams::icon) = 1, error, "state must be 1 more than icon"
        iny
        lda     (ptr),y         ; valid icon?
        bne     :+
        return  #2              ; Invalid icon
:
        ;;and     #kIconEntryStateHighlighted
        .assert kIconEntryStateHighlighted = $40, error, "kIconEntryStateHighlighted must be $40"
        asl
        bmi     :+
        return  #3              ; Not highlighted
:
        ;; Mark not highlighted
        ror
        eor     #kIconEntryStateHighlighted
        sta     (ptr),y

        ;;ldy     #IconEntry::id
        .assert (IconEntry::state - IconEntry::id) = 1, error, "id must be 1 less than state"
        dey
        lda     (ptr),y
        jmp     RemoveFromHighlightList
.endproc

;;; ============================================================
;;; IconInRect

.proc IconInRectImpl
        params := $06
.struct IconInRectParams
        icon    .byte
        rect    .tag    MGTK::Rect
.endstruct

        ptr := $06

        jmp     start

icon:   .byte   0
        DEFINE_RECT rect, 0, 0, 0, 0

        ;; Copy params to local data
start:  ldy     #IconInRectParams::icon
        lda     (params),y
        sta     icon

        ldy     #IconInRectParams::rect + .sizeof(MGTK::Rect)-1
:       lda     (params),y
        sta     rect-1,y
        dey
        bne     :-

        ldx     icon
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr
        jsr     CalcIconRects

        ;; Compare the rect against both the bitmap and label rects

        ;; top of bitmap > bottom of rect --> outside
        scmp16  rect::y2, bitmap_rect::y1
        bmi     :+

        ;; left of bitmap > right of rect --> outside
        scmp16  rect::x2, bitmap_rect::x1
        bmi     :+

        ;; bottom of bitmap < top of rect --> outside
        scmp16  bitmap_rect::y2, rect::y1
        bmi     :+

        ;; right of bitmap < left of rect --> outside
        scmp16  bitmap_rect::x2, rect::x1
        bpl     inside

:
        ;; top of text > bottom of rect --> outside
        scmp16  rect::y2, label_rect::y1
        bmi     outside

        ;; left of text > right of rect --> outside
        scmp16  rect::x2, label_rect::x1
        bmi     outside

        ;; bottom of text < top of rect --> outside
        scmp16  label_rect::y2, rect::y1
        bmi     outside

        ;; right of text < left of rect --> outside
        scmp16  label_rect::x2, rect::x1
        bpl     inside

outside:
        return  #0

inside:
        return  #1
.endproc

;;; ============================================================
;;; Paint icon
;;; * Assumes grafport selected and maprect configured
;;; * Does not erase background

icon_flags: ; bit 7 = highlighted, bit 6 = volume icon
        .byte   0

win_flags:  ; copy of IconEntry::win_flags
        .byte   0

more_drawing_needed_flag:
        .byte   0

        DEFINE_POINT label_pos, 0, 0

no_clip_vol_icons_flag:
        .byte   0

.proc PaintIcon

unhighlighted:
        lda     #0
        sta     icon_flags
        beq     common          ; always

highlighted:
        copy    #$80, icon_flags ; is highlighted

common:
        ;; Test if icon is dimmed volume/folder
        ldy     #IconEntry::win_flags
        lda     ($06),y
        sta     win_flags

        lda     ($06),y
        and     #kIconEntryWinIdMask
        bne     :+

        ;;  Mark as "volume icon" on desktop (needs background)
        lda     icon_flags
        ora     #$40
        sta     icon_flags

        ;; copy icon entry coords and bits
        ;;ldy     #IconEntry::iconx
        .assert (IconEntry::iconx - IconEntry::win_flags) = 1, error, "iconx must be 1 more than win_flags"
:       iny
        lda     ($06),y
        sta     icon_paintbits_params::viewloc-IconEntry::iconx,y
        sta     mask_paintbits_params::viewloc-IconEntry::iconx,y
        cpy     #IconEntry::iconx + 5 ; x/y/bits
        bne     :-

        jsr     PushPointers

        ;; copy icon definition bits
        copy16  icon_paintbits_params::mapbits, $08
        ldy     #.sizeof(MGTK::MapInfo) - .sizeof(MGTK::Point) - 1
:       lda     ($08),y
        sta     icon_paintbits_params::mapbits,y
        sta     mask_paintbits_params::mapbits,y
        dey
        bpl     :-

        ;; Icon definition is followed by pointer to mask address.
        ldy     #.sizeof(MGTK::MapInfo) - .sizeof(MGTK::Point)
        copy16in ($08),y, mask_paintbits_params::mapbits
        jsr     PopPointers

        ;; Copy, pad, and measure name
        jsr     PrepareName

        copy16  label_rect+MGTK::Rect::x1, label_pos+MGTK::Point::xcoord
        add16_8 label_rect+MGTK::Rect::y1, #kSystemFontHeight-1, label_pos+MGTK::Point::ycoord

        bit     icon_flags      ; volume icon (on desktop) ?
        bvc     DoPaint         ; nope
        bit     no_clip_vol_icons_flag
        bmi     DoPaint
        ;; TODO: This depends on a previous proc having adjusted
        ;; the grafport (for window maprect and window's items/used/free bar)

        ;; Volume (i.e. icon on desktop)
        MGTK_CALL MGTK::InitPort, grafport
        jsr     SetPortForVolIcon
:       jsr     CalcWindowIntersections
        jsr     DoPaint
        lda     more_drawing_needed_flag
        bne     :-
        MGTK_CALL MGTK::SetPortBits, grafport ; default maprect
        rts

.proc DoPaint
        MGTK_CALL MGTK::HideCursor

        ;; --------------------------------------------------
        ;; Icon

        ;; Shade (XORs background)
        .assert kIconEntryFlagsDimmed = $80, error, "flag mismatch"
        bit     win_flags
        bpl     :+
        jsr     Shade

        ;; Mask (cleared to white or black)
:       MGTK_CALL MGTK::SetPenMode, penOR
        bit     icon_flags
        bpl     :+
        MGTK_CALL MGTK::SetPenMode, penBIC
:       MGTK_CALL MGTK::PaintBits, mask_paintbits_params

        ;; Shade again (restores background)
        .assert kIconEntryFlagsDimmed = $80, error, "flag mismatch"
        bit     win_flags
        bpl     :+
        jsr     Shade

        ;; Icon (drawn in black or white)
:       MGTK_CALL MGTK::SetPenMode, penBIC
        bit     icon_flags
        bpl     :+
        MGTK_CALL MGTK::SetPenMode, penOR
:       MGTK_CALL MGTK::PaintBits, icon_paintbits_params

        ;; --------------------------------------------------

        ;; Label
        COPY_STRUCT MGTK::Point, label_pos, moveto_params2
        MGTK_CALL MGTK::MoveTo, moveto_params2
        bit     icon_flags      ; highlighted?
        bmi     :+
        lda     #MGTK::textbg_white
        bne     setbg
:       lda     #MGTK::textbg_black
setbg:  sta     settextbg_params
        MGTK_CALL MGTK::SetTextBG, settextbg_params
        MGTK_CALL MGTK::DrawText, drawtext_params
        MGTK_CALL MGTK::ShowCursor

        copy    #MGTK::textbg_white, settextbg_params
        MGTK_CALL MGTK::SetTextBG, settextbg_params
        MGTK_CALL MGTK::SetPattern, white_pattern

        rts

.proc Shade
        MGTK_CALL MGTK::SetPattern, dark_pattern
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, bitmap_rect

done:   rts
.endproc

.endproc

;;; ============================================================

.endproc ; PaintIcon
        paint_icon_unhighlighted := PaintIcon::unhighlighted
        paint_icon_highlighted := PaintIcon::highlighted


;;; ============================================================

kIconLabelGapV = 2

;;; Input: $06 points at icon
;;; Output: Populates `bitmap_rect` and `label_rect`
;;; Preserves $06/$08
.proc CalcIconRects
        entry_ptr := $6
        bitmap_ptr := $8

        jsr     PushPointers

        ldy     #IconEntry::iconbits
        copy16in (entry_ptr),y, bitmap_ptr

        ;; Bitmap top/left - copy from icon entry
        ldy     #IconEntry::iconx+3
        ldx     #3
:       lda     (entry_ptr),y
        sta     bitmap_rect::topleft,x
        dey
        dex
        bpl     :-

        ;; Bitmap bottom/right
        ldy     #IconResource::maprect + MGTK::Rect::x2
        add16in bitmap_rect::x1, (bitmap_ptr),y, bitmap_rect::x2
        .assert (MGTK::Rect::y2 - MGTK::Rect::x2) = 2, error, "y2 must be 2 more than x2"
        iny
        add16in bitmap_rect::y1, (bitmap_ptr),y, bitmap_rect::y2

        ;; Label top
        add16_8 bitmap_rect::y2, #kIconLabelGapV, label_rect::y1

        ;; Label bottom
        add16_8 label_rect::y1, #kSystemFontHeight, label_rect::y2

        ;; Copy, pad, and measure name
        jsr     PrepareName

        ;; Center horizontally

        ;; Left edge of label
        ;;  text_left = icon_left + icon_width/2 - text_width/2
        ;;            = (icon_left*2 + icon_width - text_width) / 2
        ;; NOTE: Left is computed before right to match rendering code
        copy16  bitmap_rect::x1, label_rect::x1
        asl16   label_rect::x1
        ldy     #IconResource::maprect + MGTK::Rect::x2
        add16in label_rect::x1, (bitmap_ptr),y, label_rect::x1
        sub16   label_rect::x1, textwidth_params::result, label_rect::x1
        asr16   label_rect::x1 ; signed

        ;; Label right
        add16   label_rect::x1, textwidth_params::result, label_rect::x2

        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc

;;; Input: $06 points at icon
;;; Output: Populates `bitmap_rect` and `label_rect` and `bounding_rect`
;;; Preserves $06/$08
.proc CalcIconBoundingRect
        jsr     PushPointers

        jsr     CalcIconRects

        COPY_STRUCT MGTK::Rect, bitmap_rect, bounding_rect

        scmp16  label_rect::x1, bounding_rect::x1
    IF_NEG
        copy16  label_rect::x1, bounding_rect::x1
    END_IF
        scmp16  label_rect::y1, bounding_rect::y1
    IF_NEG
        copy16  label_rect::y1, bounding_rect::y1
    END_IF

        scmp16  bounding_rect::x2, label_rect::x2
    IF_NEG
        copy16  label_rect::x2, bounding_rect::x2
    END_IF
        scmp16  bounding_rect::y2, label_rect::y2
    IF_NEG
        copy16  label_rect::y2, bounding_rect::y2
    END_IF

        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc

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

kIconPolySize = (8 * .sizeof(MGTK::Point)) + 2

;;; Input: $06 points at icon
;;; Output: Populates `bitmap_rect` and `label_rect` and `bounding_rect`
;;;         and (of course) `poly`
;;; Preserves $06/$08
.proc CalcIconPoly
        entry_ptr := $6

        jsr     PushPointers

        jsr     CalcIconBoundingRect

        ;; Even vertexes are (mostly) direct copies from rects

        ;; v0/v2 (and extend bitmap rect down to top of text)
        COPY_STRUCT MGTK::Point, bitmap_rect::topleft, poly::v0
        copy16  bitmap_rect::x2, poly::v2::xcoord
        copy16  label_rect::y1, poly::v2::ycoord

        ;; v6/v4
        COPY_STRUCT MGTK::Point, label_rect::topleft, poly::v6
        COPY_STRUCT MGTK::Point, label_rect::bottomright, poly::v4

        ;; Odd vertexes are combinations

        ;; v1
        copy16  poly::v2::xcoord, poly::v1::xcoord
        copy16  poly::v0::ycoord, poly::v1::ycoord

        ;; v7
        copy16  poly::v0::xcoord, poly::v7::xcoord
        copy16  poly::v2::ycoord, poly::v7::ycoord

        ;; v3
        copy16  poly::v4::xcoord, poly::v3::xcoord
        copy16  poly::v6::ycoord, poly::v3::ycoord

        ;; v5
        copy16  poly::v6::xcoord, poly::v5::xcoord
        copy16  poly::v4::ycoord, poly::v5::ycoord

        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc

;;; Copy name from IconEntry (ptr $06) to text_buffer,
;;; with leading/trailing spaces, and measure it.

.proc PrepareName
        .assert text_buffer - 1 = drawtext_params::textlen, error, "location mismatch"

        dest := drawtext_params::textlen
        ptr := $06

        ldy     #.sizeof(IconEntry)
        ldx     #.sizeof(IconEntry) - IconEntry::name
:       lda     (ptr),y
        sta     dest + 1,x
        dey
        dex
        bpl     :-

        ldy     dest + 1
        iny
        iny
        sty     dest

        lda     #' '
        sta     dest + 1
        sta     dest,y

        copy    drawtext_params::textlen, textwidth_params::textlen
        MGTK_CALL MGTK::TextWidth, textwidth_params

        rts
.endproc

;;; ============================================================
;;; RedrawDesktopIcons

.proc RedrawDesktopIconsImpl
        ;; No params

        ptr := $06

        copy    #$80, no_clip_vol_icons_flag

        ;; Get current clip rect
        port_ptr := $06
        MGTK_CALL MGTK::GetPort, port_ptr
        ldy     #.sizeof(MGTK::MapInfo)-1
:       lda     (port_ptr),y
        sta     mapinfo,y
        dey
        bpl     :-

        ;; Loop over all icons
        ldx     num_icons
loop:   dex
        bmi     done
        txa
        pha

        ldy     icon_list,x
        sty     icon

        ;; Is it an icon on the desktop?
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, ptr
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask ; desktop icon
        bne     next                 ; no, skip it

        ;; In maprect?
        ITK_CALL IconTK::IconInRect, icon
        beq     next            ; no, skip it

        ITK_CALL IconTK::DrawIcon, icon

next:   pla
        tax
        bpl     loop            ; always

done:   copy    #0, no_clip_vol_icons_flag
        rts

        ;; GetPortBits params
mapinfo:
        .tag    MGTK::MapInfo

        ;; IconTK::DrawIcon and IconTK::IconInRect params
icon    := mapinfo + MGTK::MapInfo::maprect - 1
rect    := mapinfo + MGTK::MapInfo::maprect

.endproc

;;; ============================================================
;;; A = icon number to move
;;; X = position in highlight list

.proc ChangeIconIndex
        stx     new_pos
        sta     icon_num

        ;; Find position of icon in icon table
        ldx     #0
:       lda     icon_list,x
        cmp     icon_num
        beq     :+
        inx
        cpx     num_icons
        bne     :-
        rts

        ;; Shift items down
:       lda     icon_list+1,x
        sta     icon_list,x
        inx
        cpx     num_icons
        bne     :-

        ;; Shift items up
        ldx     num_icons
:       cpx     new_pos
        beq     place
        lda     icon_list-2,x
        sta     icon_list-1,x
        dex
        jmp     :-

        ;; Place at new position
place:  ldx     new_pos
        lda     icon_num
        sta     icon_list-1,x
        rts

new_pos:        .byte   0
icon_num:       .byte   0
.endproc

;;; ============================================================
;;; A = icon number to move
;;; X = new position in highlight list

.proc ChangeHighlightIndex
        stx     new_pos
        sta     icon_num

        ;; Find position of icon in highlight list
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
        beq     place
        lda     highlight_list-2,x
        sta     highlight_list-1,x
        dex
        jmp     :-

        ;; Place at new position
place:  ldx     new_pos
        lda     icon_num
        sta     highlight_list-1,x
        rts

new_pos:        .byte   0
icon_num:       .byte   0
.endproc

;;; ============================================================
;;; Remove icon from highlight list. Does not update icon's state.
;;; Inputs: A=icon id
.proc RemoveFromHighlightList

        ;; Move it to the end of the highlight list
        ldx     highlight_count ; new position
        jsr     ChangeHighlightIndex

        ;; Remove it from the highlight list
        dec     highlight_count
        lda     #0
        ldx     highlight_count
        sta     highlight_list,x

        rts
.endproc

;;; ============================================================
;;; Erase an icon; redraws overlapping icons as needed

EraseIconCommon:
        sta     redraw_highlighted_flag
        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::SetPort, icon_grafport
        jmp     LA3B9

        ;; For `RedrawIconsAfterErase`
redraw_highlighted_flag:
        .byte   0
LA3AC:  .byte   0
window_id:  .byte   0

        ;; IconTK::DrawIcon params
        ;; IconTK::IconInRect params (in `RedrawIconsAfterErase`)
icon:   .byte   0
icon_rect:
        .tag    MGTK::Rect

icon_in_window_flag:
        .byte   0

.params frontwindow_params
window_id:      .byte   0
.endparams

.proc LA3B9
        ldy     #0
        lda     ($06),y
        sta     LA3AC
        iny
        iny
        lda     ($06),y
        and     #kIconEntryWinIdMask
        sta     window_id
        beq     volume

        ;; File (i.e. icon in window)
        copy    #$80, icon_in_window_flag
        MGTK_CALL MGTK::SetPattern, white_pattern
        MGTK_CALL MGTK::FrontWindow, frontwindow_params ; Use window's port
        lda     frontwindow_params::window_id
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     ret             ; obscured!
        jsr     offset_icon_poly_and_rect
        jsr     ShiftPortDown ; Further offset by window's items/used/free bar
        jsr     EraseWindowIcon
        jmp     RedrawIconsAfterErase
ret:    rts

        ;; Volume (i.e. icon on desktop)
volume:
        MGTK_CALL MGTK::InitPort, grafport
        jsr     SetPortForVolIcon
:       jsr     CalcWindowIntersections
        jsr     EraseDesktopIcon
        lda     more_drawing_needed_flag
        bne     :-
        MGTK_CALL MGTK::SetPortBits, grafport ; default maprect
        jmp     RedrawIconsAfterErase
.endproc

;;; ============================================================

.proc EraseDesktopIcon
        lda     #0
        sta     icon_in_window_flag

        MGTK_CALL MGTK::GetDeskPat, addr
        MGTK_CALL MGTK::SetPattern, 0, addr
        FALL_THROUGH_TO EraseWindowIcon
.endproc

;;; Inputs: `bounding_rect` and `poly` must be populated
.proc EraseWindowIcon
        ;; Construct a bounding rect from the icon's polygon.
        ;; Used in `RedrawIconsAfterErase`
        COPY_STRUCT MGTK::Rect, bounding_rect, icon_rect

        MGTK_CALL MGTK::PaintPoly, poly
        rts
.endproc

;;; ============================================================
;;; After erasing an icon, redraw any overlapping icons

.proc RedrawIconsAfterErase
        ptr := $8

        jsr     PushPointers
        ldx     num_icons
loop:   dex                     ; any icons to draw?

        bpl     LA466

        bit     icon_in_window_flag
        bpl     :+
        ;; TODO: Is this restoration necessary?
        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::SetPort, icon_grafport
:       jsr     PopPointers     ; do not tail-call optimise!
        rts

LA466:  txa
        pha
        ldy     icon_list,x
        cpy     LA3AC
        beq     next

        copylohi icon_ptrs_low,y, icon_ptrs_high,y, ptr

        ;; Same window?
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        cmp     window_id
        bne     next

        bit     redraw_highlighted_flag
    IF_NC
        ldy     #IconEntry::state
        lda     (ptr),y
        and     #kIconEntryStateHighlighted
        bne     next
    END_IF

        ldy     #IconEntry::id ; icon num
        lda     (ptr),y
        sta     icon
        bit     icon_in_window_flag ; windowed?
        bpl     :+           ; nope, desktop
        jsr     offset_icon_do  ; yes, adjust rect
:       ITK_CALL IconTK::IconInRect, icon
        beq     :+

        ITK_CALL IconTK::DrawIcon, icon

:       bit     icon_in_window_flag
        bpl     next
        lda     icon
        jsr     offset_icon_undo

next:   pla
        tax
        bpl     loop            ; always
.endproc

;;; ============================================================
;;; Offset coordinates for windowed icons

.proc OffsetIcon

offset_flags:  .byte   0        ; bit 7 = offset poly, bit 6 = undo offset, otherwise do offset

dx:     .word   0
dy:     .word   0

entry_poly_and_rect:
        copy    #$80, offset_flags
        bmi     common          ; always

entry_do:
        pha
        lda     #$40
        sta     offset_flags
        jmp     common

entry_undo:
        pha
        lda     #0
        sta     offset_flags

common:
        sub16   icon_grafport+MGTK::GrafPort::maprect+MGTK::Point::xcoord, icon_grafport+MGTK::GrafPort::viewloc+MGTK::Point::xcoord, dx
        sub16   icon_grafport+MGTK::GrafPort::maprect+MGTK::Point::ycoord, icon_grafport+MGTK::GrafPort::viewloc+MGTK::Point::ycoord, dy

        bit     offset_flags
        bmi     OffsetPoly
        jvc     DoOffset
        jmp     UndoOffset

.proc OffsetPoly
        add16   bounding_rect::x1, dx, bounding_rect::x1
        add16   bounding_rect::y1, dy, bounding_rect::y1
        add16   bounding_rect::x2, dx, bounding_rect::x2
        add16   bounding_rect::y2, dy, bounding_rect::y2

        ldx     #0
loop1:  add16   poly::vertices+0,x, dx, poly::vertices+0,x
        add16   poly::vertices+2,x, dy, poly::vertices+2,x
        inx
        inx
        inx
        inx
        cpx     #kPolySize * .sizeof(MGTK::Point)
        bne     loop1

        rts

.endproc

.proc DoOffset
        ptr := $06

        pla
        tay
        jsr     PushPointers
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, ptr
        ldy     #IconEntry::iconx
        sub16in (ptr),y, dx, (ptr),y ; icony += viewloc::xcoord - maprect::left
        iny
        sub16in (ptr),y, dy, (ptr),y ; icony += viewloc::ycoord - maprect::top
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc

.proc UndoOffset
        ptr := $06

        pla
        tay
        jsr     PushPointers
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, ptr
        ldy     #IconEntry::iconx
        add16in (ptr),y, dx, (ptr),y ; iconx += maprect::left - viewloc::xcoord
        iny
        add16in (ptr),y, dy, (ptr),y ; icony += maprect::top - viewloc::xcoord
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc

.endproc
        offset_icon_poly_and_rect := OffsetIcon::entry_poly_and_rect
        offset_icon_do := OffsetIcon::entry_do
        offset_icon_undo := OffsetIcon::entry_undo

;;; ============================================================
;;; This handles drawing volume icons "behind" windows. It is
;;; done by comparing the bounding rect of the icon (including
;;; label) with windows, and returning a reduced clipping rect.
;;; Since the overlap may be concave, multiple calls may be
;;; necessary; a flag is set if another call is required.
;;;
;;; The algorithm is as follows:
;;;
;;; * Take the bounding box for the icon+label (bounds_*), and
;;;    use it as an initial clipping rect.
;;; * Test each corner of the rect.
;;; * If the corner is inside a window, compute the window bounds.
;;;    (Complicated by title bars, scroll bars, and borders.)
;;; * Consider each case where a window and rect overlap. There
;;;    are 9 cases (8 interesting, one degenerate).
;;; * Reduce the clipping rect to the leftmost exposed portion.
;;; * Recheck the corners, since another window may be overlapped.
;;; * Once a minimal rect is achieved, set a flag indicating if
;;;    another call is needed, and return.
;;; * Caller draws the icon into the clipping rect. If flag was
;;;    set, the caller calls in again.
;;; * On re-entry, return to the initial bounding box but with
;;;    an updated left edge.
;;;
;;; ============================================================

;;; Initial bounds, saved for re-entry.
bounds_t:  .word   0
bounds_r:  .word   0
bounds_b:  .word   0

.params portbits
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 0, 0
.endparams

.proc SetPortForVolIcon
        jsr     CalcIconPoly    ; also populates `bounding_rect`

        ;; Set up bounds_t
        ldax    bounding_rect::y1
        stax    bounds_t
        stax    portbits::maprect::y1
        stax    portbits::viewloc::ycoord

        ;; Set up bounds_l
        ldax    bounding_rect::x1
        stax    portbits::maprect::x1
        stax    portbits::viewloc::xcoord

        ;; Set up bounds_b
        ldax    bounding_rect::y2
        stax    bounds_b
        stax    portbits::maprect::y2

        ;; Set up bounds_r
        ldxy    bounding_rect::x2

        ;; if (bounds_r > kScreenWidth - 1) bounds_r = kScreenWidth - 1
        cpx     #<(kScreenWidth - 1)
        tya
        sbc     #>(kScreenWidth - 1)
        bmi     done
        ldx     #<(kScreenWidth - 1)
        ldy     #>(kScreenWidth - 1)

done:   stxy    bounds_r
        stxy    portbits::maprect::x2
        MGTK_CALL MGTK::SetPortBits, portbits
        rts
.endproc

;;; ============================================================

.proc CalcWindowIntersections
        ptr := $06

        jmp     start

.params findwindow_params
mousex: .word   0
mousey: .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams

pt_num: .byte   0

scrollbar_flags:
        .byte   0               ; bit 7 = hscroll present; bit 6 = vscroll present
dialogbox_flag:
        .byte   0               ; bit 7 = dialog box

;;; Points at corners of icon's bounding rect
;;; pt1 +----+ pt2
;;;     |    |
;;; pt4 +----+ pt3
        DEFINE_POINT pt1, 0, 0
        DEFINE_POINT pt2, 0, 0
        DEFINE_POINT pt3, 0, 0
        DEFINE_POINT pt4, 0, 0

.params getwinframerect_params
window_id:      .byte   0
        DEFINE_RECT rect, 0, 0, 0, 0
.endparams

stash_r: .word   0


        ;; Viewport/Cliprect to adjust
        vx := portbits::viewloc::xcoord
        vy := portbits::viewloc::ycoord
        cr_l := portbits::maprect::x1
        cr_t := portbits::maprect::y1
        cr_r := portbits::maprect::x2
        cr_b := portbits::maprect::y2

start:  lda     more_drawing_needed_flag
        beq     reclip

        ;; --------------------------------------------------
        ;; Re-entry - pick up where we left off

        ;; cr_l = cr_r + 1
        ;; vx   = cr_r + 1
        ldx     cr_r
        ldy     cr_r+1
        inx
        stx     cr_l
        stx     vx
        bne     :+
        iny
:       sty     cr_l+1
        sty     vx+1

        ;; cr_t = bounds_t
        ;; cr_r = bounds_r
        ;; cr_b = bounds_b
        COPY_BYTES 6, bounds_t, cr_t

        ;; vy = cr_t
        copy16  cr_t, vy

        ;; Corners of bounding rect (clockwise from upper-left)
        ;; pt1::xcoord = pt4::xcoord = cr_l
        ;; pt1::ycoord = pt2::ycoord = cr_t
        ;; pt2::xcoord = pt3::xcoord = cr_r
        ;; pt3::ycoord = pt4::ycoord = cr_b
reclip: lda     cr_l
        sta     pt1::xcoord
        sta     pt4::xcoord
        lda     cr_l+1
        sta     pt1::xcoord+1
        sta     pt4::xcoord+1
        lda     cr_t
        sta     pt1::ycoord
        sta     pt2::ycoord
        lda     cr_t+1
        sta     pt1::ycoord+1
        sta     pt2::ycoord+1
        lda     cr_r
        sta     pt2::xcoord
        sta     pt3::xcoord
        lda     cr_r+1
        sta     pt2::xcoord+1
        sta     pt3::xcoord+1
        lda     cr_b
        sta     pt3::ycoord
        sta     pt4::ycoord
        lda     cr_b+1
        sta     pt3::ycoord+1
        sta     pt4::ycoord+1

        lda     #0
        sta     pt_num

next_pt:
        ;; Done all 4 points?
        lda     pt_num
        eor     #4
        bne     do_pt
        sta     pt_num

        ;; --------------------------------------------------
        ;; Finish up

set_bits:
        ;; Ensure clip right does not exceed screen bounds.
        ;; Fixes https://github.com/a2stuff/a2d/issues/182
        ;; TODO: Enforce this in the algorithm instead?
        cmp16   cr_r, bounds_r
        bcc     :+
        copy16  bounds_r, cr_r

:       MGTK_CALL MGTK::SetPortBits, portbits
        ;; if (cr_r < bounds_r) more drawing is needed
        cmp16   cr_r, bounds_r
        asl
        lda     #0
        rol
        sta     more_drawing_needed_flag
        rts

        ;; ==================================================
        ;; Find window at Nth point, and compute bounds

do_pt:  lda     pt_num
        asl     a               ; *4 (.sizeof(Point))
        asl     a
        tax

        ;; Look up window at Nth point
        ldy     #0
:       lda     pt1::xcoord,x
        sta     findwindow_params,y
        iny
        inx
        cpy     #4
        bne     :-

        inc     pt_num
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        beq     next_pt

        ;; --------------------------------------------------
        ;; Compute window edges (including non-content area)

        win_l := getwinframerect_params::rect::x1
        win_t := getwinframerect_params::rect::y1
        win_r := getwinframerect_params::rect::x2
        win_b := getwinframerect_params::rect::y2

        copy    findwindow_params::window_id, getwinframerect_params::window_id
        MGTK_CALL MGTK::GetWinFrameRect, getwinframerect_params

        ;; TODO: Determine why these are necessary:
        dec16   win_l
        dec16   win_t
        dec16   win_r

        ;; ==================================================
        ;; At this point, win_r/t/l/b are the window edges,
        ;; cr_r/t/l/b are the rect we know has at least one
        ;; corner overlapping the window.
        ;;
        ;; Cases (#=icon, %=result, :=window)
        ;;
        ;; .  1 ::::    4 ::::    7 ::::
        ;; .    ::::      ::::      ::::
        ;; .    :::##     :##:     %#:::
        ;; .       %#      %%      %#
        ;; .
        ;; .  2 ::::    5 ::::    8 ::::
        ;; .    :::#%     :##:     %#:::
        ;; .    :::#%     :##:     %#:::
        ;; .    ::::      ::::      ::::
        ;; .
        ;; .       %#      %%      %#
        ;; .  3 :::##   6 :##:   9 %#:::
        ;; .    ::::      ::::      ::::
        ;; .    ::::      ::::      ::::

        copy16  cr_r, stash_r   ; in case this turns out to be case 2

        ;; Cases 1/2/3 (and continue below)
        ;; if (cr_r > win_r)
        ;; . cr_r = win_r + 1
        scmp16  cr_r, win_r
        bmi     case789

        ldx     win_r
        ldy     win_r + 1
        inx
        bne     :+
        iny
:       stx     cr_r
        sty     cr_r + 1
        jmp     vert

        ;; Cases 7/8/9 (and done)
        ;; if (win_l > cr_l)
        ;; . cr_r = win_l
case789:
        scmp16  win_l, cr_l
        bmi     vert

        copy16  win_l, cr_r
        jmp     reclip

        ;; Cases 3/6 (and done)
        ;; if (win_t > cr_t)
        ;; . cr_b = win_t
vert:   scmp16  win_t, cr_t
        bmi     :+

        copy16  win_t, cr_b
        copy    #1, more_drawing_needed_flag
        jmp     reclip

        ;; Cases 1/4 (and done)
        ;; if (win_b < cr_b)
        ;; . cr_t = win_b + 2
        ;; . vy   = win_b + 2
:       scmp16  win_b, cr_b
        bpl     case2

        ldx     win_b
        ldy     win_b+1
        inx
        stx     cr_t
        stx     vy
        bne     :+
        iny
:       sty     cr_t+1
        sty     vy+1
        copy    #1, more_drawing_needed_flag
        jmp     reclip

        ;; Case 2
        ;; if (win_r < stash_r)
        ;; . cr_l = win_r + 2
        ;; . vx   = win_r + 2
        ;; . cr_r = stash_r + 2 (workaround for https://github.com/a2stuff/a2d/issues/153)
case2:
        scmp16  win_r, stash_r
        bpl     :+

        lda     win_r
        clc
        adc     #2
        sta     cr_l
        sta     vx
        lda     win_r+1
        adc     #0
        sta     cr_l+1
        sta     vx+1
        add16   stash_r, #2, cr_r
        jmp     reclip

        ;; Case 5 - done!
:       copy16  bounds_r, cr_r
        ldx     bounds_r
        ldy     bounds_r + 1
        inx
        bne     :+
        iny
:       stx     cr_l
        sty     cr_l + 1
        jmp     set_bits
.endproc

;;; ============================================================

.proc ShiftPortDown
        ;; For window's items/used/free space bar
        kOffset = kWindowHeaderHeight + 1

        add16   icon_grafport+MGTK::GrafPort::viewloc+MGTK::Point::ycoord, #kOffset, icon_grafport+MGTK::GrafPort::viewloc+MGTK::Point::ycoord
        add16   icon_grafport+MGTK::GrafPort::maprect+MGTK::Rect::y1, #kOffset, icon_grafport+MGTK::GrafPort::maprect+MGTK::Rect::y1
        MGTK_CALL MGTK::SetPort, icon_grafport
        rts
.endproc

;;; ============================================================
;;; Pushes two words from $6/$8 to stack; preserves Y only

.proc PushPointers
        ;; Stash return address
        pla
        sta     lo
        pla
        sta     hi

        ;; Copy 4 bytes from $8 to stack
        ldx     #AS_BYTE(-4)
:       lda     $06 + 4,x
        pha
        inx
        bne     :-

        ;; Restore return address
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        rts
.endproc

;;; ============================================================
;;; Pops two words from stack to $6/$8; preserves Y only

.proc PopPointers
        ;; Stash return address
        pla
        sta     lo
        pla
        sta     hi

        ;; Copy 4 bytes from stack to $6
        ldx     #3
:       pla
        sta     $06,x
        dex
        bpl     :-

        ;; Restore return address to stack
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        rts
.endproc

.endscope ; icon_toolkit
