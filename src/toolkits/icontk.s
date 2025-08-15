;;; ============================================================
;;; Entry point for "Icon ToolKit"
;;; ============================================================

.scope icon_toolkit
        ITKEntry := *

        ;; Zero Page usage (saved/restored around calls)

PARAM_BLOCK, $06
generic_ptr1    .addr
generic_ptr2    .addr

poly_coords     .tag    MGTK::Point ; used in `DragHighlighted`
initial_coords  .tag    MGTK::Point ; used in `DragHighlighted`
last_coords     .tag    MGTK::Point ; used in `DragHighlighted`

clip_coords     .tag    MGTK::Point ; Used for clipped drawing
clip_bounds     .tag    MGTK::Rect  ; Used for clipped drawing

bitmap_rect     .tag    MGTK::Rect  ; populated by `CalcIconRects`
label_rect      .tag    MGTK::Rect  ; populated by `CalcIconRects`
bounding_rect   .tag    MGTK::Rect  ; populated by `CalcIconRects`
rename_rect     .tag    MGTK::Rect  ; populated by `CalcIconRects`
END_PARAM_BLOCK
        ASSERT_EQUALS rename_rect + .sizeof(MGTK::Rect), $42
        kBytesToSave = $42 - $06

        .assert ITKEntry = Dispatch, error, "dispatch addr"
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


        ;; Save $06... on the stack
        ldx     #AS_BYTE(-kBytesToSave)
:       lda     $06 + kBytesToSave,x
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

        ;; Restore $06...
        ldx     #kBytesToSave-1
:       pla
        sta     $06,x
        dex
        bpl     :-

        tya                     ; A = result
        rts

call_params:  .addr     0
.endproc ; Dispatch

jump_table_low:
        .byte   <InitToolKitImpl
        .byte   <AllocIconImpl
        .byte   <HighlightIconImpl
        .byte   <DrawIconRawImpl
        .byte   <FreeIconImpl
        .byte   <FreeAllImpl
        .byte   <FindIconImpl
        .byte   <DragHighlightedImpl
        .byte   <UnhighlightIconImpl
        .byte   <DrawAllImpl
        .byte   <IconInRectImpl
        .byte   <EraseIconImpl
        .byte   <GetIconBoundsImpl
        .byte   <DrawIconImpl
        .byte   <GetIconEntryImpl
        .byte   <GetRenameRectImpl
        .byte   <GetBitmapRectImpl

jump_table_high:
        .byte   >InitToolKitImpl
        .byte   >AllocIconImpl
        .byte   >HighlightIconImpl
        .byte   >DrawIconRawImpl
        .byte   >FreeIconImpl
        .byte   >FreeAllImpl
        .byte   >FindIconImpl
        .byte   >DragHighlightedImpl
        .byte   >UnhighlightIconImpl
        .byte   >DrawAllImpl
        .byte   >IconInRectImpl
        .byte   >EraseIconImpl
        .byte   >GetIconBoundsImpl
        .byte   >DrawIconImpl
        .byte   >GetIconEntryImpl
        .byte   >GetRenameRectImpl
        .byte   >GetBitmapRectImpl

;;; ============================================================

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
        REF_MAPINFO_MEMBERS
.endparams

.params mask_paintbits_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 0, 0
        REF_MAPINFO_MEMBERS
.endparams

.params textwidth_params
textptr:        .addr   text_buffer
textlen:        .byte   0
result:         .word   0
.endparams
settextbg_params    := textwidth_params::result + 1  ; re-used

settextbg_white:
        .byte   MGTK::textbg_white

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

;;; Used by `DrawAllImpl` and `EraseIconCommon` (which are not
;;; mutually re-entrant)
.params icon_in_rect_params
icon:   .byte   0
rect:   .tag    MGTK::Rect
.endparams

;;; ============================================================
;;; Icon (i.e. file, volume) details

num_icons:  .byte   0
icon_list:  .res    (::kMaxIconCount+1), 0   ; list of allocated icons (index 0 not used)

icon_ptrs_low:  .res    (::kMaxIconCount+1), 0 ; addresses of icon details (index 0 not used)
icon_ptrs_high: .res    (::kMaxIconCount+1), 0 ; addresses of icon details (index 0 not used)

;;; Input: A = icon number
;;; Output: A,X = address of IconEntry
.proc GetIconPtr
        tay
        ldx     icon_ptrs_high,y
        lda     icon_ptrs_low,y
        rts
.endproc ; GetIconPtr


;;; ============================================================
;;; Initialization parameters passed by client

;;; Vertical offset within windows
header_height:  .byte   0

;;; Polygon holding the composite outlines of all icons being dragged.
;;; Re-use the "save area" ($800-$1AFF) since menus won't show during
;;; this kOperation.
polybuf_addr:           .addr   0
max_draggable_icons:    .byte   0

;;; Mapping of `IconEntry::type` to `IconResource`
typemap_addr:   .addr   0

;;; ============================================================

.params peekevent_params
kind:   .byte   0               ; spills into next block
.endparams

;;; `findwindow_params::window_id` is used as first part of
;;; GetWinPtr params structure including `window_ptr`.
.params findwindow_params
mousex:         .word   0
mousey:         .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams
window_ptr:     .word   0       ; do not move this; see above
        ASSERT_EQUALS window_ptr, findwindow_params::window_id + 1, "struct moved"

.params findcontrol_params
mousex:         .word   0
mousey:         .word   0
which_ctl:      .byte   0
which_part:     .byte   0
window_id:      .byte   0       ; For FindControlEx
.endparams

;;; GrafPort used to draw icon outlines during drag. Set up with the
;;; correct pen and pattern. Does not include the menu bar area.
.params drag_outline_grafport
viewloc:        .word   0, kMenuBarHeight
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        .word   0, kMenuBarHeight, kScreenWidth-1, kScreenHeight-1
pattern:        .byte   %01010101
                .byte   %10101010
                .byte   %01010101
                .byte   %10101010
                .byte   %01010101
                .byte   %10101010
                .byte   %01010101
                .byte   %10101010
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         .word   0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::penXOR
textback:       .byte   MGTK::textbg_black
textfont:       .addr   0
        REF_GRAFPORT_MEMBERS
.endparams
        ASSERT_EQUALS .sizeof(drag_outline_grafport), .sizeof(MGTK::GrafPort)
desktop_bounds := drag_outline_grafport::maprect


.params getwinport_params
window_id:      .byte   0
a_grafport:     .addr   icon_grafport
.endparams

icon_grafport:  .tag    MGTK::GrafPort

;;; ============================================================
;;; InitToolKit

.proc InitToolKitImpl
        params := $06
.struct InitToolKitParams
headersize      .byte
a_polybuf       .addr
bufsize         .word
a_typemap       .addr
a_heap          .addr
.endstruct

        table_ptr := $08

        ldy     #InitToolKitParams::headersize
        copy8   (params),y, header_height
        iny                     ; Y = InitToolKitParams::a_polybuf
        copy16in (params),y, polybuf_addr
        iny                     ; Y = InitToolKitParams::bufsize
        copy16in (params),y, bufsize
        iny                     ; Y = InitToolKitParams::a_typemap
        copy16in (params),y, typemap_addr
        iny                     ; Y = InitToolKitParams::a_heap
        copy16in (params),y, table_ptr

        ;; --------------------------------------------------
        ;; Populate `icon_ptrs_low/high` table

        ldx     #1
:
        ;; Populate table entry
        lda     table_ptr
        sta     icon_ptrs_low,x
        lda     table_ptr+1
        sta     icon_ptrs_high,x

        ;; Next entry
        add16_8 table_ptr, #.sizeof(IconEntry)
        inx
        cpx     #kMaxIconCount+1 ; allow up to the maximum
        bne     :-

        ;; --------------------------------------------------
        ;; MaxDraggableItems = BufferSize / kIconPolySize

        ldy     #0
:       sub16_8 bufsize, #kIconPolySize
        bit     bufsize+1
        bmi     :+
        iny
        bne     :-              ; always
:       sty     max_draggable_icons

        rts

bufsize:
        .word   0
.endproc ; InitToolKitImpl

;;; ============================================================
;;; AllocIcon

.proc AllocIconImpl
        params := $06
.struct AllocIconParams
        icon    .byte           ; out
        entry   .addr           ; out
.endstruct

        jsr     AllocateIcon
        ldy     #AllocIconParams::icon
        sta     (params),y

        ;; Add it to `icon_list`
        ldx     num_icons
        sta     icon_list,x
        inc     num_icons

        ;; Grab the `IconEntry`, to return it and update it
        ptr_icon := $08
        jsr     GetIconPtr
        stax    ptr_icon
        ldy     #AllocIconParams::entry
        sta     (params),y
        txa
        iny
        sta     (params),y

        ;; Initialize IconEntry::state
        lda     #0
        ;; ldy     #IconEntry::state
        ASSERT_EQUALS IconEntry::state, 0
        tay
        sta     (ptr_icon),y

        rts
.endproc ; AllocIconImpl

;;; ============================================================
;;; Tests if the passed icon id is in `icon_list`
;;; Inputs: A = icon id
;;; Outputs: Z=1 if found (and X = index), Z=0 otherwise
;;; A is unmodified, X is trashed
.ifdef DEBUG
.proc IsInIconList
        ldx     num_icons
:       dex
        bmi     done            ; X=#$FF, Z=0
        cmp     icon_list,x
        bne     :-              ; not found

done:   rts
.endproc ; IsInIconList
.endif

;;; ============================================================
;;; HighlightIcon

;;; param is pointer to icon id

.proc HighlightIconImpl
        params := $06
.struct HighlightIconParams
        icon    .byte
.endstruct

        ;; Pointer to IconEntry
        ldy     #HighlightIconParams::icon
        lda     (params),y
        pha                     ; A = icon
        ptr := $06              ; Overwrites params
        jsr     GetIconState    ; sets `ptr`/$06 too

        ;; Mark highlighted
        ora     #kIconEntryStateHighlighted
        sta     (ptr),y

        pla                     ; A = icon
        jmp     MaybeMoveIconToTop
.endproc ; HighlightIconImpl

;;; ============================================================
;;; FreeIcon

;;; param is pointer to icon number

.proc FreeIconImpl
        params := $06
.struct FreeIconParams
        icon    .byte
.endstruct

        ldy     #FreeIconParams::icon
        lda     (params),y

.ifdef DEBUG
        ;; Is it in `icon_list`?
        jsr     IsInIconList
        beq     :+
        return  #1              ; Not found
:
.endif ; DEBUG

        jsr     FreeIconCommon ; A = icon id
        return  #0
.endproc ; FreeIconImpl

;;; ============================================================
;;; Remove the icon
;;; Inputs: A = icon id

.proc FreeIconCommon
        ;; Remove it
        jsr     RemoveIconFromList ; returns A unchanged
        dec     num_icons

        ;; Mark it as free
        jmp     FreeIcon
.endproc ; FreeIconCommon

;;; ============================================================

;;; Remove icon from `icon_list` and compact list, but don't
;;; modify `num_icons`; the last entry of the list will be garbage.
;;; Input: A = icon
;;; Output: A unchanged, X = `num_icons`
;;; Assert: icon is in `icon_list`
.proc RemoveIconFromList
        pha                     ; A = icon

        ;; Find index
        ldx     num_icons
:       dex
        cmp     icon_list,x
        bne     :-

        ;; Shift items down
:       lda     icon_list+1,x
        sta     icon_list,x
        inx
        cpx     num_icons
        bne     :-

        pla                     ; A = icon
        rts
.endproc ; RemoveIconFromList

;;; ============================================================

;;; Input: A = icon
;;; Output: Z=0 if fixed, Z=1 if not fixed
;;; Trashes $06
.proc IsIconFixed
        jsr     GetIconPtr
        stax    $06
        ldy     #IconEntry::win_flags
        lda     ($06),y
        and     #kIconEntryFlagsFixed
        rts
.endproc ; IsIconFixed

;;; ============================================================

;;; Move icon to end of `icon_list`, i.e. top of z-order, unless
;;; it has `kIconEntryFlagsFixed`.
;;; Input: A = icon
;;; Trashes $06
;;; Assert: icon is in `icon_list`
.proc MaybeMoveIconToTop
        pha                     ; A = icon
        jsr     IsIconFixed
    IF_NOT_ZERO
        pla                     ; discard
        rts
    END_IF

        pla                     ; A = icon
        jsr     RemoveIconFromList ; returns with A unchanged, X = `num_icons`
        sta     icon_list-1,x
        rts
.endproc ; MaybeMoveIconToTop

;;; ============================================================
;;; EraseIcon

.proc EraseIconImpl
        params := $06
.struct EraseIconParams
        icon    .byte
.endstruct

        ;; Pointer to IconEntry
        ldy     #EraseIconParams::icon
        lda     (params),y
        ldx     #$80            ; do clip
        sec                     ; do redraw highlighted
        jmp     EraseIconCommon ; A = icon id, X = clip flag, C = redraw flag
.endproc ; EraseIconImpl

;;; ============================================================
;;; FreeAll

;;; param is window id (0 = desktop)

.proc FreeAllImpl
        params := $06
.struct FreeAllParams
        window_id       .byte
.endstruct

        ldy     #FreeAllParams::window_id
        lda     (params),y
        sta     window_id

        lda     num_icons
        sta     count
count := * + 1
loop:   ldx     #SELF_MODIFIED_BYTE
        bne     :+
        txa
        rts

:       dec     count
        dex

        lda     icon_list,x
        jsr     GetIconWin
        window_id := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     loop                 ; nope

        ldx     count
        lda     icon_list,x
        jsr     FreeIconCommon ; A = icon id

        jmp     loop
.endproc ; FreeAllImpl

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

        ldax    params
        stax    out_params
        ASSERT_EQUALS FindIconParams::coords, 0, "coords must be first"
        stax    moveto_params_addr

        ldy     #FindIconParams::window_id
        lda     (params),y
        sta     window_id

        MGTK_CALL MGTK::MoveTo, SELF_MODIFIED, moveto_params_addr

        ldx     num_icons
        beq     failed
loop:   dex
        txa
        pha

        ;; Check the icon
        lda     icon_list,x
        jsr     GetIconWin      ; sets `icon_ptr`/$06 too

        ;; Matching window?
        window_id := * + 1
        cmp     #SELF_MODIFIED_BYTE
        bne     next            ; nope, ignore

        ;; In poly?
        jsr     CalcIconPoly    ; requires `icon_ptr` set
        MGTK_CALL MGTK::InRect, bounding_rect
        beq     next            ; nope, skip poly test

        MGTK_CALL MGTK::InPoly, poly
        bne     inside          ; yes!

next:
        ;; Nope, next
        pla
        tax
        bne     loop

failed:
        ;; Nothing found
        ldy     #FindIconParams::result
        lda     #0
        sta     (out_params),y
        rts

        ;; Found one!
inside: pla
        tax
        lda     icon_list,x
        ldy     #FindIconParams::result
        sta     (out_params),y
        rts
.endproc ; FindIconImpl

;;; ============================================================
;;; DragHighlighted

.proc DragHighlightedImpl
        params := $06
.struct DragHighlightedParams
        icon    .byte
        coords  .tag    MGTK::Point
.endstruct

        poly_dx := poly_coords + MGTK::Point::xcoord
        poly_dy := poly_coords + MGTK::Point::ycoord

        ldy     #DragHighlightedParams::icon
        lda     (params),y
        sta     icon_id
        ASSERT_EQUALS DragHighlightedParams::icon, 0
        tya
        sta     (params),y

        ;; Copy initial coords to `initial_coords` and `last_coords`
        ldy     #DragHighlightedParams::coords + .sizeof(MGTK::Point)-1
:       lda     (params),y
        sta     initial_coords-1,y
        sta     last_coords-1,y
        dey
        ;;cpy     #DragHighlightedParams::coords-1
        ASSERT_EQUALS DragHighlightedParams::coords, 1
        bne     :-

        jsr     PushPointers    ; save `params`

        lda     #0
        sta     highlight_icon_id
        sta     trash_flag

;;; Determine if it's a drag or just a click
.proc _DragDetectImpl

peek:   MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::EventKind::drag
    IF_NE
        lda     #IconTK::kDragResultNotADrag
        jmp     exit_with_a
    END_IF

        kDragDelta = 5

        ;; Compute mouse delta
        ldx     #2              ; loop over dimensions
loop:   lda     findwindow_params,x
        sec
        sbc     last_coords,x
        tay
        lda     findwindow_params+1,x
        sbc     last_coords+1,x
    IF_NEG
        cpy     #AS_BYTE(-kDragDelta)
        bcc     is_drag         ; above threshold, so drag
        bcs     next            ; always
    END_IF
        cpy     #kDragDelta     ; above threshold, so drag
        bcs     is_drag

next:   dex
        dex
        bpl     loop
        bmi     peek            ; always
.endproc ; _DragDetectImpl

        ;; --------------------------------------------------
        ;; Meets the threshold - it is a drag, not just a click.
is_drag:

        ;; Count number of highlighted icons
        copy8   #0, highlight_count

        INVOKE_WITH_LAMBDA _IterateHighlightedIcons
        ;; Count this one, and remember as potentially last
        inc     highlight_count
        sta     last_highlighted_icon

        ;; Also check if Trash, and set flag appropriately
        jsr     GetIconFlags
        and     #kIconEntryFlagsNotDropSource
        beq     :+
        copy8   #$80, trash_flag
:
        rts
        END_OF_LAMBDA

        ;; Assert: there are highlighted icons

        ;; Make sure there's room
        lda     highlight_count
        cmp     max_draggable_icons
        beq     :+                      ; equal okay
        jcs     exit_canceled           ; too many
:
        lda     last_highlighted_icon
        jsr     GetIconWin
        sta     source_window_id

        ;; --------------------------------------------------
        ;; Build drag polygon

        copy16  polybuf_addr, $08
        copy8   #$80, poly::lastpoly  ; more to follow

        INVOKE_WITH_LAMBDA _IterateHighlightedIcons

        jsr     CalcIconPoly

        ;; Copy poly into place
        ldy     #kIconPolySize-1
:       lda     poly,y
        sta     ($08),y
        dey
        bpl     :-

        add16_8 $08, #kIconPolySize
        rts
        END_OF_LAMBDA

        ;; Mark last icon
        sub16_8 $08, #kIconPolySize
        ldy     #1              ; MGTK Polygon "not last" flag
        lda     #0              ; last polygon
        sta     ($08),y

        copy8   #0, poly::lastpoly ; restore default

        ;; --------------------------------------------------

        jsr     _XDrawOutline

peek:   MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::EventKind::drag
        jne     not_drag

        ;; Escape key?
        lda     KBD             ; MGTK doesn't process keys during drag
        cmp     #CHAR_ESCAPE | $80
        bne     :+
        bit     KBDSTRB         ; consume the keypress
        copy8   #MGTK::EventKind::key_down, peekevent_params::kind
        jmp     not_drag
:
        ;; Coords changed?
        ldx     #.sizeof(MGTK::Point)-1
:       lda     findwindow_params,x
        cmp     last_coords,x
        bne     moved
        dex
        bpl     :-
        bmi     peek            ; always

        ;; --------------------------------------------------
        ;; Mouse moved - check for (un)highlighting, and
        ;; update the drag outline.
moved:
        jsr     _XDrawOutline

        ;; Check for highlighting changes
        bit     trash_flag      ; Trash is not drop-able, so skip if in selection
        bmi     update_poly

        jsr     _FindIconValidateWindow
        cmp     highlight_icon_id
        beq     update_poly     ; no change

        ;; No longer over the highlighted icon - unhighlight it
        pha
        lda     highlight_icon_id
        beq     :+
        jsr     _UnhighlightIcon
        copy8   #0, highlight_icon_id
:
        ;; Is the new icon valid?
        pla
        beq     update_poly
        jsr     _ValidateTargetAndHighlight

update_poly:
        ;; Update poly coordinates
        ldx     #2              ; loop over dimensions
:       sub16   findwindow_params,x, last_coords,x, poly_coords,x
        dex                     ; next dimension
        dex
        bpl     :-
        COPY_STRUCT MGTK::Point, findwindow_params, last_coords

        poly_ptr := $08
        copy16  polybuf_addr, poly_ptr
ploop:  ldy     #2              ; offset in poly to first vertex
vloop:  add16in (poly_ptr),y, poly_dx, (poly_ptr),y
        iny
        add16in (poly_ptr),y, poly_dy, (poly_ptr),y
        iny
        cpy     #kIconPolySize
        bne     vloop
        ldy     #1              ; MGTK Polygon "not last" flag
        lda     (poly_ptr),y
        beq     :+
        lda     poly_ptr
        clc
        adc     #kIconPolySize
        sta     poly_ptr
        bcc     ploop
        inc     poly_ptr+1
        bcs     ploop
:
        jsr     _XDrawOutline
        jmp     peek

        ;; --------------------------------------------------
        ;; End of the drag - figure out how to finish up
not_drag:
        jsr     _XDrawOutline

        lda     highlight_icon_id
        beq     :+
        jsr     _UnhighlightIcon
:
        ;; Drag ended by a keystroke?
        lda     peekevent_params::kind
        cmp     #MGTK::EventKind::key_down ; cancel?
        jeq     exit_canceled

        ;; Drag ended over an icon?
        lda     highlight_icon_id
        jne     exit_drop

        ;; Drag ended over a window or desktop?
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        pha
        ora     #$80
        sta     highlight_icon_id
        pla

        cmp     source_window_id
        beq     same_window

        bit     trash_flag
        jmi     exit_canceled

        jmp     exit_drop

        ;; Drag within same window (or desktop)
same_window:
        ldx     #$80            ; clip (if desktop)
        lda     findwindow_params::which_area
        ASSERT_EQUALS MGTK::Area::desktop, 0
        beq     move_ok

        cmp     #MGTK::Area::content
        jne     exit_canceled   ; don't move

        jsr     _CheckRealContentArea
        jcs     exit_canceled   ; don't move

        lda     last_highlighted_icon
        jsr     IsIconFixed     ; Z=0 if fixed
        jne     exit_canceled   ; don't move

        ;; --------------------------------------------------
        ;; Probably a move within the same window...

        ldx     #0              ; don't clip (not desktop; unnecessary)
move_ok:
        stx     ::drag_highlighted_lambda_clip_flag

        ;; ... but skip if modifier(s) down; allows other gestures.
        lda     BUTN0
        ora     BUTN1
    IF_NS
        lda     #IconTK::kDragResultMoveModified
        ASSERT_NOT_EQUALS IconTK::kDragResultMoveModified, 0
        bne     exit_with_a
    END_IF

        INVOKE_WITH_LAMBDA _IterateHighlightedIcons
        ::drag_highlighted_lambda_clip_flag := *+1
        ldx     #SELF_MODIFIED_BYTE
        clc                     ; don't redraw highlighted
        jmp     EraseIconCommon ; A = icon id, X = clip flag, C = redraw flag
        END_OF_LAMBDA

        ;; --------------------------------------------------
        ;; Update icons with new positions (based on delta)

        ldx     #2              ; loop over dimensions
:       sub16   findwindow_params,x, initial_coords,x, poly_coords,x
        dex                     ; next dimension
        dex
        bpl     :-

        INVOKE_WITH_LAMBDA _IterateHighlightedIcons
        jsr     GetIconPtr
        stax    $06

        ldy     #IconEntry::iconx
        add16in ($06),y, poly_dx, ($06),y
        iny
        add16in ($06),y, poly_dy, ($06),y
        rts
        END_OF_LAMBDA

        lda     #IconTK::kDragResultMove
        FALL_THROUGH_TO exit_with_a

        ;; --------------------------------------------------

exit_with_a:
        tay                     ; A = return value
        jsr     PopPointers     ; restore `params`
        tya                     ; A = return value
        tax                     ; A = return value
        ldy     #0
        lda     highlight_icon_id
        sta     (params),y
        txa                     ; A = return value
        rts

exit_drop:
        lda     #IconTK::kDragResultDrop
        ASSERT_EQUALS IconTK::kDragResultDrop, 0
        beq     exit_with_a

exit_canceled:
        lda     #IconTK::kDragResultCanceled
        ASSERT_NOT_EQUALS IconTK::kDragResultCanceled, 0
        bne     exit_with_a


;;; ============================================================

icon_id:
        .byte   0

        ;; IconTK::HighlightIcon params
        ;; also used as the return value
highlight_icon_id:  .byte   $00

source_window_id:       .byte   0 ; source window of drag (0=desktop)
trash_flag:             .byte   0 ; if Trash is included in selection

highlight_count:
        .byte   0
last_highlighted_icon:
        .byte   0

;;; Inputs: A,X = proc; called with A = icon id
;;;
.proc _IterateHighlightedIcons
        stax    proc

        ldx     #0
        stx     index

loop:   lda     icon_list,x
        jsr     GetIconState
        and     #kIconEntryStateHighlighted
        beq     next

        ldx     index
        lda     icon_list,x

        proc := *+1
        jsr     SELF_MODIFIED

next:   inc     index
        index := *+1
        ldx     #SELF_MODIFIED_BYTE
        cpx     num_icons
        bne     loop

        rts
.endproc ; _IterateHighlightedIcons



;;; Like `FindIcon`, but validates that the passed coordinates are
;;; in the true content area of the window (not scrollbars/grow box/header)
;;;
;;; Inputs: `findwindow_params` mouse coords populated
;;; Outputs: A = icon (0 if none found), `findwindow_params::window_id` populated
;;; Trashes $06

.proc _FindIconValidateWindow
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        ASSERT_EQUALS MGTK::Area::desktop, 0
        beq     desktop

        ;; --------------------------------------------------
        ;; In a window - ensure it's in the content area
        cmp     #MGTK::Area::content
        bne     fail            ; menubar, titlebar, etc

        jsr     _CheckRealContentArea
        bcc     find_icon

fail:   return  #0              ; no icon

        ;; --------------------------------------------------
        ;; On desktop - A=0, note that as window_id
desktop:
        sta     findwindow_params::window_id

        ;; --------------------------------------------------
        ;; Is there an icon there?
find_icon:
        ITK_CALL IconTK::FindIcon, findwindow_params
        lda     findwindow_params::which_area ; Icon ID
        rts
.endproc ; _FindIconValidateWindow

;;; Dig deeper into FindWindow results to ensure it's really content.
;;; Input: `findwindow_params` populated
;;; Output: C=0 if content, C=1 if non-content
;;; Assert: `FindWindow` was called and returned `Area::content`
;;; Trashes $06
.proc _CheckRealContentArea
        COPY_STRUCT MGTK::Point, findwindow_params::mousex, findcontrol_params::mousex
        copy8   findwindow_params::window_id, findcontrol_params::window_id
        MGTK_CALL MGTK::FindControlEx, findcontrol_params
        bne     fail
        lda     findcontrol_params::which_ctl
        ASSERT_EQUALS MGTK::Ctl::not_a_control, 0
        bne     fail            ; scrollbar, etc.

        ;; Ignore if y coord < window's header height
        MGTK_CALL MGTK::GetWinPtr, findwindow_params::window_id
        win_ptr := $06
        copy16  window_ptr, win_ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        lda     (win_ptr),y
        copy16in (win_ptr),y, headery
        add16_8 headery, header_height
        cmp16   findwindow_params::mousey, headery
        bcc     fail

        clc
        rts

fail:   sec
        rts

headery:
        .word   0
.endproc ; _CheckRealContentArea

;;; Trashes $06
.proc _ValidateTargetAndHighlight
        ;; Over an icon
        sta     icon_num

        ptr := $06
        jsr     GetIconState    ; sets `ptr`/$06 too

        ;; Highlighted?
        ;;and     #kIconEntryStateHighlighted
        ASSERT_EQUALS ::kIconEntryStateHighlighted, $40
        asl
        bmi     done            ; Not valid (it's being dragged)

        ;; Is it a drop target?
        ;;ldy     #IconEntry::win_flags
        ASSERT_EQUALS (IconEntry::win_flags - IconEntry::state), 1
        iny
        lda     (ptr),y
        ;;and     #kIconEntryFlagsDropTarget
        ASSERT_EQUALS ::kIconEntryFlagsDropTarget, $40
        asl
        bpl     done

        ;; Highlight it!
        icon_num := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     highlight_icon_id
        jsr     _HighlightIcon

done:   rts
.endproc ; _ValidateTargetAndHighlight

.proc _XDrawOutline
        copy16  polybuf_addr, addr
        MGTK_CALL MGTK::SetPort, drag_outline_grafport
        MGTK_CALL MGTK::FramePoly, SELF_MODIFIED, addr
        rts
.endproc ; _XDrawOutline

.proc _HighlightIcon
        ITK_CALL IconTK::HighlightIcon, highlight_icon_id
        ITK_CALL IconTK::DrawIcon, highlight_icon_id
        rts
.endproc ; _HighlightIcon

.proc _UnhighlightIcon
        ITK_CALL IconTK::UnhighlightIcon, highlight_icon_id
        ITK_CALL IconTK::DrawIcon, highlight_icon_id
        rts
.endproc ; _UnhighlightIcon

.endproc ; DragHighlightedImpl

;;; ============================================================

;;; Input: A = icon number
;;; Output: A = window id (0=desktop), $06 = icon ptr
.proc GetIconWin
        jsr     GetIconFlags
        and     #kIconEntryWinIdMask
        rts
.endproc ; GetIconWin

;;; Input: A = icon number
;;; Output: A = flags (including window), Y = IconEntry::win_flags, $06 = icon ptr
.proc GetIconFlags
        ptr := $06

        jsr     GetIconPtr
        stax    ptr
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        rts
.endproc ; GetIconFlags

;;; Input: A = icon number
;;; Output: A = state, Y = IconEntry::state, $06 icon ptr
.proc GetIconState
        ptr := $06

        jsr     GetIconPtr
        stax    ptr
        ldy     #IconEntry::state
        lda     (ptr),y
        rts
.endproc ; GetIconState

;;; ============================================================
;;; UnhighlightIcon

;;; param is pointer to IconEntry

.proc UnhighlightIconImpl
        params := $06
.struct UnhighlightIconParams
        icon    .byte
.endstruct

        ;; Pointer to IconEntry
        ldy     #UnhighlightIconParams::icon
        lda     (params),y
        pha                     ; A = icon
        ptr := $06              ; Overwrites params
        jsr     GetIconState    ; sets `ptr`/$06 too

        ;; Mark not highlighted
        and     #AS_BYTE(~kIconEntryStateHighlighted)
        sta     (ptr),y

        pla                     ; A = icon
        jmp     MaybeMoveIconToTop
.endproc ; UnhighlightIconImpl

;;; ============================================================
;;; IconInRect

.proc IconInRectImplImpl
        params := $06
.struct IconInRectParams
        icon    .byte
        rect    .tag    MGTK::Rect
.endstruct

        ptr := $06

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

        lda     icon
        jsr     GetIconPtr
        stax    ptr
        jsr     CalcIconRects

        ;; Compare the rect against both the bitmap and label rects

        ;; --------------------------------------------------
        ;; Bitmap
        ldx     #2              ; loop over dimensions
:
        ;; top/left of bitmap > bottom/right of rect --> outside
        scmp16  rect::bottomright,x, bitmap_rect+MGTK::Rect::topleft,x
        bmi     :+

        ;; bottom/right of bitmap < top/left of rect --> outside
        scmp16  bitmap_rect+MGTK::Rect::bottomright,x, rect::topleft,x
        bmi     :+

        dex                     ; next dimension
        dex
        bpl     :-
        bmi     inside          ; always
:
        ;; --------------------------------------------------
        ;; Label

        ldx     #2              ; loop over dimensions
:
        ;; top/left of text > bottom/right of rect --> outside
        scmp16  rect::bottomright,x, label_rect+MGTK::Rect::topleft,x
        bmi     outside

        ;; bottom/right of text < top/left of rect --> outside
        scmp16  label_rect+MGTK::Rect::bottomright,x, rect::topleft,x
        bmi     outside

        dex                     ; next dimension
        dex
        bpl     :-

inside:
        return  #1

outside:
        return  #0
.endproc ; IconInRectImplImpl
IconInRectImpl := IconInRectImplImpl::start

;;; ============================================================
;;; GetIconBounds

.proc GetIconBoundsImpl
        params := $06
.struct GetIconBoundsParams
        icon    .byte
        rect    .tag    MGTK::Rect ; out
.endstruct

        ;; Calc icon bounds
        jsr     PushPointers
        ptr := $06
        ldy     #GetIconBoundsParams::icon
        lda     (params),y
        jsr     GetIconPtr
        stax    ptr
        jsr     CalcIconBoundingRect
        jsr     PopPointers

        ;; Copy rect into out params
        ldx     #.sizeof(MGTK::Rect)-1
        ldy     #GetIconBoundsParams::rect + .sizeof(MGTK::Rect)-1
:       lda     bounding_rect,x
        sta     (params),y
        dey
        dex
        bpl     :-

        rts
.endproc ; GetIconBoundsImpl

;;; ============================================================
;;; GetRenameRect

.proc GetRenameRectImpl
        params := $06
.struct GetRenameRectParams
        icon    .byte
        rect    .tag    MGTK::Rect ; out
.endstruct

        ;; Calc icon bounds
        ASSERT_EQUALS params, $06
        ASSERT_EQUALS GetRenameRectParams::icon, 0
        jsr     GetXYZRectImplHelper

        ;; Copy rect into out params
        ldx     #.sizeof(MGTK::Rect)-1
        ldy     #GetRenameRectParams::rect + .sizeof(MGTK::Rect)-1
:       lda     rename_rect,x
        sta     (params),y
        dey
        dex
        bpl     :-

        rts
.endproc ; GetRenameRectImpl

;;; ============================================================
;;; GetBitmapRect

.proc GetBitmapRectImpl
        params := $06
.struct GetBitmapRectParams
        icon    .byte
        rect    .tag    MGTK::Rect ; out
.endstruct

        ;; Calc icon bounds
        ASSERT_EQUALS params, $06
        ASSERT_EQUALS GetBitmapRectParams::icon, 0
        jsr     GetXYZRectImplHelper

        ;; Copy rect into out params
        ldx     #.sizeof(MGTK::Rect)-1
        ldy     #GetBitmapRectParams::rect + .sizeof(MGTK::Rect)-1
:       lda     bitmap_rect,x
        sta     (params),y
        dey
        dex
        bpl     :-

        rts
.endproc ; GetBitmapRectImpl

.proc GetXYZRectImplHelper
        params := $06
        params_icon_offset = 0

        ;; Calc icon bounds
        jsr     PushPointers
        ptr := $06
        ldy     #params_icon_offset
        lda     (params),y
        jsr     GetIconPtr
        stax    ptr
        jsr     CalcIconRects
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; GetXYZRectImplHelper

;;; ============================================================

;;; Used by `DrawIcon` and `EraseIcon`. Has bit7 = 0 on first call
;;; to `CalcWindowIntersections` to signal the start of a clipping
;;; sequence. Set bit7 if a subsequent call is needed, and clear
;;; once all drawing is complete.
more_drawing_needed_flag:
        .byte   0

;;; Set by some callers of `DrawIconCommon` and `EraseIconCommon`
clip_icons_flag:
        .byte   0

;;; Window containing the icon, used during clipping/redrawing
clip_window_id:
        .byte   0

;;; ============================================================
;;; DrawIconRaw

;;; * Assumes correct grafport already selected/maprect specified
;;; * Does not erase background

.proc DrawIconRawImpl
        lda     #0              ; `clip_icons_flag`
        jmp     DrawIconCommon
.endproc ; DrawIconRawImpl

;;; ============================================================
;;; DrawIcon

;;; * Draws icon clipping against any overlapping windows.
;;; * Does not erase background

.proc DrawIconImpl
        jsr     InitSetIconPort

        lda     #$80            ; `clip_icons_flag`
        FALL_THROUGH_TO DrawIconCommon
.endproc ; DrawIconImpl

;;; ============================================================

.proc DrawIconCommon
        params := $06
.struct DrawIconParams
        icon    .byte
.endstruct
        sta     clip_icons_flag

        ptr := $06              ; Overwrites params

        ;; Slow enough that events should be checked; this allows
        ;; double-clicks during icon repaints (e.g. deselects)
        MGTK_CALL MGTK::CheckEvents

        ;; Pointer to IconEntry
        ldy     #DrawIconParams::icon
        lda     (params),y
        jsr     GetIconPtr
        stax    ptr

        jsr     CalcIconRects

        ;; Stash some flags
        ldy     #IconEntry::state
        lda     (ptr),y
        sta     state
        ASSERT_EQUALS IconEntry::win_flags, IconEntry::state + 1
        iny
        lda     ($06),y
        sta     win_flags

        ;; For quick access
        and     #kIconEntryWinIdMask
        sta     clip_window_id

        jsr     PushPointers

        ;; copy icon definition bits
        jsr     GetIconResource
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

        ;; Determine if we want clipping, based on icon type and flags.

        bit     clip_icons_flag
        bpl     _DoPaint        ; no clipping, just paint

        ;; Set up clipping structs and port
        lda     clip_window_id
    IF_ZERO
        jsr     SetPortForVolIcon
    ELSE
        jsr     SetPortForWinIcon
        bne     ret             ; obscured
    END_IF

        ;; Paint icon iteratively, handling overlapping windows
:       jsr     CalcWindowIntersections
        bcs     ret             ; nothing remaining to draw

        jsr     OffsetPortAndIcon
        jsr     _DoPaint
        jsr     OffsetPortAndIcon

        bit     more_drawing_needed_flag
        bmi     :-

ret:    rts


.proc _DoPaint
        label_pos := $06

        ;; Prep coords
        copy16  label_rect+MGTK::Rect::x1, label_pos+MGTK::Point::xcoord
        add16_8 label_rect+MGTK::Rect::y1, #kSystemFontHeight-1, label_pos+MGTK::Point::ycoord

        ldax    bitmap_rect+MGTK::Rect::x1
        stax    icon_paintbits_params::viewloc::xcoord
        stax    mask_paintbits_params::viewloc::xcoord
        ldax    bitmap_rect+MGTK::Rect::y1
        stax    icon_paintbits_params::viewloc::ycoord
        stax    mask_paintbits_params::viewloc::ycoord

        ;; Set text background color
        lda     #MGTK::textbg_white
        ASSERT_EQUALS ::kIconEntryStateHighlighted, $40
        bit     state           ; highlighted?
        bvc     :+
        lda     #MGTK::textbg_black
:       sta     settextbg_params
        MGTK_CALL MGTK::SetTextBG, settextbg_params

        MGTK_CALL MGTK::HideCursor

        ;; --------------------------------------------------
        ;; Icon

        ;; Shade (XORs background)
        ASSERT_EQUALS ::kIconEntryStateDimmed, $80
        bit     state
    IF_NS
        MGTK_CALL MGTK::SetPattern, dark_pattern
        jsr     _Shade
    END_IF

        ;; Mask (cleared to white or black)
        ASSERT_EQUALS ::kIconEntryStateHighlighted, $40
        bit     state
    IF_VS
        MGTK_CALL MGTK::SetPenMode, penBIC
    ELSE
        MGTK_CALL MGTK::SetPenMode, penOR
    END_IF
        MGTK_CALL MGTK::PaintBitsHC, mask_paintbits_params

        ;; Shade again (restores background)
        ASSERT_EQUALS ::kIconEntryStateDimmed, $80
        bit     state
    IF_NS
        jsr     _Shade
    END_IF

        ;; Icon (drawn in black or white)
        ASSERT_EQUALS ::kIconEntryStateHighlighted, $40
        bit     state
    IF_VS
        MGTK_CALL MGTK::SetPenMode, penOR
    ELSE
        MGTK_CALL MGTK::SetPenMode, penBIC
    END_IF
        MGTK_CALL MGTK::PaintBitsHC, icon_paintbits_params

        ;; --------------------------------------------------
        ;; Label

        MGTK_CALL MGTK::MoveTo, label_pos

        MGTK_CALL MGTK::DrawText, drawtext_params
        MGTK_CALL MGTK::ShowCursor

        MGTK_CALL MGTK::SetTextBG, settextbg_white

        return  #0

.proc _Shade
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, bitmap_rect
        rts
.endproc ; _Shade

.endproc ; _DoPaint

state:                          ; copy of IconEntry::state
        .byte   0
win_flags:                      ; copy of IconEntry::win_flags
        .byte   0

.endproc ; DrawIconCommon

;;; ============================================================

;;; Inputs: $06 = IconEntry
;;; Output: $08 = IconResource
.proc GetIconResource
        icon_ptr := $06
        res_ptr := $08

        ldy     #IconEntry::type
        lda     (icon_ptr),y         ; A = type
        asl                     ; *= 2
        tay
        copy16  typemap_addr, $08
        lda     ($08),y
        pha
        iny
        lda     ($08),y
        sta     res_ptr+1
        pla
        sta     res_ptr
        rts
.endproc ; GetIconResource

;;; ============================================================

kIconLabelGapV = 2

;;; Input: $06 points at icon
;;; Output: Populates `bitmap_rect` and `label_rect` and `text_buffer`
;;; Preserves $06/$08
.proc CalcIconRects
        entry_ptr := $6
        bitmap_ptr := $8

        jsr     PushPointers

        ;; Copy, pad, and measure name
        jsr     PrepareName

        jsr     GetIconResource ; sets $08 based on $06

        ;; Bitmap top/left - copy from icon entry
        ldy     #IconEntry::iconx+3
        ldx     #3
:       lda     (entry_ptr),y
        sta     bitmap_rect+MGTK::Rect::topleft,x
        dey
        dex
        bpl     :-

        ;; Bitmap bottom/right
        ldy     #IconResource::maprect + MGTK::Rect::x2
        add16in bitmap_rect+MGTK::Rect::x1, (bitmap_ptr),y, bitmap_rect+MGTK::Rect::x2
        iny
        add16in bitmap_rect+MGTK::Rect::y1, (bitmap_ptr),y, bitmap_rect+MGTK::Rect::y2

        ldy     #IconEntry::win_flags
        lda     (entry_ptr),y
        and     #kIconEntryFlagsSmall
    IF_NOT_ZERO
        ;; ----------------------------------------
        ;; Small icon

        ;; Label top
        copy16  bitmap_rect+MGTK::Rect::y1, label_rect+MGTK::Rect::y1

        ;; Label bottom
        add16_8 label_rect+MGTK::Rect::y1, #kSystemFontHeight+1, label_rect+MGTK::Rect::y2

        ;; Left edge of label
        add16_8 bitmap_rect+MGTK::Rect::x2, #kListViewIconGap-2, label_rect+MGTK::Rect::x1

        jsr     stash_rename_rect

        ;; Force bitmap bottom to same height
        copy16  label_rect+MGTK::Rect::y2, bitmap_rect+MGTK::Rect::y2
    ELSE
        ;; ----------------------------------------
        ;; Regular icon

        ;; Label top
        add16_8 bitmap_rect+MGTK::Rect::y2, #kIconLabelGapV, label_rect+MGTK::Rect::y1

        ;; Label bottom
        add16_8 label_rect+MGTK::Rect::y1, #kSystemFontHeight, label_rect+MGTK::Rect::y2

        ;; Center horizontally

        ;; Left edge of label
        ;;  text_left = icon_left + icon_width/2 - text_width/2
        ;;            = (icon_left*2 + icon_width - text_width) / 2
        ;; NOTE: Left is computed before right to match rendering code
        copy16  bitmap_rect+MGTK::Rect::x1, label_rect+MGTK::Rect::x1
        asl16   label_rect+MGTK::Rect::x1
        ldy     #IconResource::maprect + MGTK::Rect::x2
        add16in label_rect+MGTK::Rect::x1, (bitmap_ptr),y, label_rect+MGTK::Rect::x1
        jsr     stash_rename_rect
        sub16   label_rect+MGTK::Rect::x1, textwidth_params::result, label_rect+MGTK::Rect::x1
        asr16   label_rect+MGTK::Rect::x1 ; signed

        sub16_8 rename_rect+MGTK::Rect::x1, #kIconRenameLineEditWidth, rename_rect+MGTK::Rect::x1
        asr16   rename_rect+MGTK::Rect::x1

    END_IF

        ;; Label right
        add16   label_rect+MGTK::Rect::x1, textwidth_params::result, label_rect+MGTK::Rect::x2

        add16_8 rename_rect+MGTK::Rect::x1, #kIconRenameLineEditWidth, rename_rect+MGTK::Rect::x2
        dec16   rename_rect+MGTK::Rect::y1

        jsr     PopPointers     ; do not tail-call optimise!
        rts

stash_rename_rect:
        COPY_STRUCT MGTK::Rect, label_rect, rename_rect
        rts
.endproc ; CalcIconRects

;;; Input: $06 points at icon
;;; Output: Populates `bitmap_rect` and `label_rect` and `bounding_rect`
;;; Preserves $06/$08
.proc CalcIconBoundingRect
        jsr     PushPointers

        jsr     CalcIconRects

        COPY_BLOCK bitmap_rect, bounding_rect

        ;; Union of rectangles (expand `bounding_rect` to encompass `label_rect`)
        MGTK_CALL MGTK::UnionRects, unionrects_label_bounding

        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; CalcIconBoundingRect

.params unionrects_label_bounding
        .addr   label_rect
        .addr   bounding_rect
.endparams

kIconPolySize = (8 * .sizeof(MGTK::Point)) + 2

;;; Input: $06 points at icon
;;; Output: Populates `bitmap_rect` and `label_rect` and `bounding_rect`
;;;         and (of course) `poly`
;;; Preserves $06/$08
.proc CalcIconPoly
        entry_ptr := $6

        jsr     PushPointers

        jsr     CalcIconBoundingRect

        ldy     #IconEntry::win_flags
        lda     (entry_ptr),y
        and     #kIconEntryFlagsSmall
    IF_NOT_ZERO
        ;; ----------------------------------------
        ;; Small icon

        ;;      v0/v1/v2/v3/v4             v5
        ;;        +-----------------------+
        ;;        |                       |
        ;;        |                       |
        ;;        +-----------------------+
        ;;      v7                         v6

        ;; Start off making all (except v6) the same
        ldy     #.sizeof(MGTK::Point)-1
:       lda     bitmap_rect+MGTK::Rect::topleft,y
        sta     poly::v0,y
        sta     poly::v1,y
        sta     poly::v2,y
        sta     poly::v3,y
        sta     poly::v4,y
        sta     poly::v5,y
        sta     poly::v7,y
        dey
        bpl     :-

        ;; Then tweak remaining vertices on right/bottom
        ldax    label_rect+MGTK::Rect::x2
        stax    poly::v5::xcoord
        stax    poly::v6::xcoord

        ldax    bitmap_rect+MGTK::Rect::y2
        stax    poly::v6::ycoord
        stax    poly::v7::ycoord

    ELSE

        ;; ----------------------------------------
        ;; Normal icon

        ;;              v0          v1
        ;;               +----------+
        ;;               |          |
        ;;               |          |
        ;;               |          |
        ;;            v7 |          | v2
        ;;      v6 +-----+          +-----+ v3
        ;;         |                      |
        ;;      v5 +----------------------+ v4

        ;; Even vertexes are (mostly) direct copies from rects

        ;; v0/v2 (and extend bitmap rect down to top of text)
        COPY_STRUCT MGTK::Point, bitmap_rect+MGTK::Rect::topleft, poly::v0
        copy16  bitmap_rect+MGTK::Rect::x2, poly::v2::xcoord
        copy16  label_rect+MGTK::Rect::y1, poly::v2::ycoord

        ;; v6/v4
        COPY_STRUCT MGTK::Point, label_rect+MGTK::Rect::topleft, poly::v6
        COPY_STRUCT MGTK::Point, label_rect+MGTK::Rect::bottomright, poly::v4

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

        ;; ----------------------------------------

    END_IF

        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc ; CalcIconPoly

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

        copy8   drawtext_params::textlen, textwidth_params::textlen
        MGTK_CALL MGTK::TextWidth, textwidth_params

        rts
.endproc ; PrepareName

;;; ============================================================
;;; DrawAll

.proc DrawAllImpl
        params := $06
.struct DrawAllParams
        window_id       .byte
.endstruct

        ldy     #DrawAllParams::window_id
        lda     (params),y
        sta     window_id

        ;; Get current clip rect
        port_ptr := $06
        MGTK_CALL MGTK::GetPort, port_ptr
        ldx     #.sizeof(MGTK::Rect)-1
        ldy     #MGTK::MapInfo::maprect + .sizeof(MGTK::Rect)-1
:       lda     (port_ptr),y
        sta     icon_in_rect_params::rect,x
        dey
        dex
        bpl     :-

        ;; Loop over all icons
        ldx     #AS_BYTE(-1)
loop:   inx
        cpx     num_icons
        beq     done
        txa
        pha

        lda     icon_list,x
        sta     icon_in_rect_params::icon
        ptr := $06
        jsr     GetIconWin      ; sets `ptr`/$06 too

        ;; Is it in the target window?
        window_id := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     next            ; no, skip it

        ;; In maprect?
        ITK_CALL IconTK::IconInRect, icon_in_rect_params
        beq     next            ; no, skip it

        ITK_CALL IconTK::DrawIconRaw, icon_in_rect_params::icon

next:   pla
        tax
        bpl     loop            ; always

done:   rts


.endproc ; DrawAllImpl

;;; ============================================================
;;; GetIconEntry

.proc GetIconEntryImpl
        params := $06
.struct GetIconEntryParams
        icon    .byte           ; in
        entry   .addr           ; out
.endstruct

        ldy     #GetIconEntryParams::icon
        lda     (params),y      ; A = icon id

        jsr     GetIconPtr
        ldy     #GetIconEntryParams::entry
        sta     (params),y
        txa
        iny
        sta     (params),y

        rts
.endproc ; GetIconEntryImpl

;;; ============================================================
;;; Erase an icon; redraws overlapping icons as needed
;;; Inputs: A = icon id, X = clip_icons_flag, C = redraw highlighted flag
.proc EraseIconCommon
        sta     erase_icon_id
        stx     clip_icons_flag
        ror     redraw_highlighted_flag ; shift C into high bit

        ptr := $06
        jsr     GetIconPtr
        stax    ptr
        jsr     CalcIconPoly

        jsr     InitSetIconPort

        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        sta     clip_window_id
        sta     getwinport_params::window_id

    IF_ZERO
        jsr     SetPortForVolIcon
        MGTK_CALL MGTK::GetDeskPat, addr
        MGTK_CALL MGTK::SetPattern, SELF_MODIFIED, addr
    ELSE
        jsr     SetPortForWinIcon
        RTS_IF_NE               ; obscured!
        MGTK_CALL MGTK::SetPattern, white_pattern
    END_IF

        bit     clip_icons_flag
    IF_NC
        MGTK_CALL MGTK::PaintPoly, poly
    ELSE
:       jsr     CalcWindowIntersections
        bcs     :+              ; nothing remaining to draw
        MGTK_CALL MGTK::PaintPoly, poly
        bit     more_drawing_needed_flag
        bmi     :-
:
    END_IF
        FALL_THROUGH_TO _RedrawIconsAfterErase

;;; ============================================================
;;; After erasing an icon, redraw any overlapping icons

.proc _RedrawIconsAfterErase
        COPY_BLOCK bounding_rect, icon_in_rect_params::rect

        jsr     PushPointers
        ldx     num_icons
loop:   dex                     ; any icons to draw?
        bpl     :+

        jsr     PopPointers     ; do not tail-call optimise!
        rts

:       txa
        pha
        lda     icon_list,x
        cmp     erase_icon_id
        beq     next

        sta     icon_in_rect_params::icon
        ptr := $06
        jsr     GetIconWin      ; sets `ptr`/$06 too

        ;; Same window?
        cmp     clip_window_id
        bne     next

        bit     redraw_highlighted_flag
    IF_NC
        ldy     #IconEntry::state
        lda     (ptr),y
        and     #kIconEntryStateHighlighted
        bne     next
    END_IF

        ITK_CALL IconTK::IconInRect, icon_in_rect_params
    IF_NOT_ZERO
        lda     clip_window_id
      IF_ZERO
        ITK_CALL IconTK::DrawIcon, icon_in_rect_params::icon
      ELSE
        ITK_CALL IconTK::DrawIconRaw, icon_in_rect_params::icon
      END_IF
    END_IF

next:   pla
        tax
        bpl     loop            ; always

.endproc ; _RedrawIconsAfterErase

        ;; For `_RedrawIconsAfterErase`
redraw_highlighted_flag:
        .byte   0
erase_icon_id:
        .byte   0
.endproc ; EraseIconCommon


;;; ============================================================
;;; This handles drawing icons "behind" windows. It is
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

.params portbits
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 0, 0
        REF_MAPINFO_MEMBERS
.endparams

;;; ============================================================

.proc SetPortForVolIcon
        jsr     CalcIconPoly    ; also populates `bounding_rect` (needed in erase case)

        ;; Will need to clip to screen bounds
        COPY_STRUCT MGTK::Rect, desktop_bounds, portbits::maprect

        jmp     DuplicateClipStructsAndSetPortBits
.endproc ; SetPortForVolIcon

;;; ============================================================

.proc SetPortForWinIcon
        jsr     CalcIconBoundingRect

        ;; Get window clip rect (in screen space)
        lda     clip_window_id
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params ; into `icon_grafport`
        RTS_IF_NE                                     ; obscured

        viewloc := icon_grafport+MGTK::GrafPort::viewloc
        maprect := icon_grafport+MGTK::GrafPort::maprect

        ldx     #2              ; loop over dimensions
:
        ;; Stash, needed to offset port when drawing to get correct patterns
        sub16   maprect+MGTK::Rect::topleft,x, viewloc,x, clip_coords,x

        ;; Adjust `icon_grafport` so that `viewloc` and `maprect` are just
        ;; a clipping rectangle in screen coords.
        sub16   maprect+MGTK::Rect::bottomright,x, maprect+MGTK::Rect::topleft,x, portbits::maprect+MGTK::Rect::bottomright,x
        copy16  viewloc,x, portbits::maprect::topleft,x
        add16   portbits::maprect+MGTK::Rect::topleft,x, portbits::maprect+MGTK::Rect::bottomright,x, portbits::maprect+MGTK::Rect::bottomright,x

        dex                     ; next dimension
        dex
        bpl     :-

        ;; For window's items/used/free space bar
        add16_8 portbits::maprect+MGTK::Rect::y1, header_height

        FALL_THROUGH_TO DuplicateClipStructsAndSetPortBits
.endproc ; SetPortForWinIcon

;;; Call with these populated:
;;; * `portbits::maprect` - screen space clip rect
;;; * `bounding_rect` - screen space icon bounds
;;; Output: Z=1 if ready to paint, Z=0 if nothing to draw

.proc DuplicateClipStructsAndSetPortBits
        ;; Intersect `portbits::maprect` with `bounding_rect`

        ldx     #2              ; loop over dimensions
:
        scmp16  portbits::maprect::topleft,x, bounding_rect+MGTK::Rect::topleft,x
    IF_NEG
        copy16  bounding_rect+MGTK::Rect::topleft,x, portbits::maprect::topleft,x
    END_IF

        scmp16  bounding_rect+MGTK::Rect::bottomright,x, portbits::maprect::bottomright,x
    IF_NEG
        copy16  bounding_rect+MGTK::Rect::bottomright,x, portbits::maprect::bottomright,x
    END_IF

        ;; Is there anything left?
        scmp16  portbits::maprect::bottomright,x, portbits::maprect::topleft,x
        bmi     empty

        dex                     ; next dimension
        dex
        bpl     :-

        ;; Duplicate structs needed for clipping
        COPY_BLOCK portbits::maprect, clip_bounds
        COPY_STRUCT MGTK::Point, portbits::maprect::topleft, portbits::viewloc

        MGTK_CALL MGTK::SetPortBits, portbits
        rts

empty:  return #$FF
.endproc ; DuplicateClipStructsAndSetPortBits

;;; ============================================================

;;; Returns C=0 if a non-degenerate clipping rect is returned, so a
;;; paint call is needed, and `more_drawing_needed_flag` bit7 = 1
;;; if another call to this proc is needed after the paint. Returns
;;; C=1 if no clipping rect remains, so no drawing is needed.
.proc CalcWindowIntersectionsImpl

pt_num: .byte   0

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

start:  bit     more_drawing_needed_flag
        bpl     reclip

        ;; --------------------------------------------------
        ;; Re-entry - pick up where we left off

reentry:
        ;; cr_l = cr_r + 1
        ldxy    cr_r
        inxy
        stxy    cr_l

        ;; cr_t = clip_bounds::y1
        ;; cr_r = clip_bounds::x2
        ;; cr_b = clip_bounds::y2
        COPY_BYTES 6, clip_bounds+MGTK::Rect::y1, cr_t

        ;; vy = cr_t

        ;; Are we (re)starting with a degenerate width? If so we are
        ;; completely done with this icon.
        jsr     is_degenerate
    IF_NEG
        clc
        ror     more_drawing_needed_flag ; clear bit7
        sec
        rts
    END_IF

        ;; --------------------------------------------------
        ;; Reduce the clip rect to the next minimal chunk to paint;
        ;; may be called multiple times before returning to caller.

reclip:
        ;; Did we end up with a degenerate width? If so, this clipping
        ;; rect was exhausted. Start with the next chunk.
        jsr     is_degenerate
        bmi     reentry

        ;; Corners of bounding rect (clockwise from upper-left)
        ;; pt1::xcoord = pt4::xcoord = cr_l
        ;; pt1::ycoord = pt2::ycoord = cr_t
        ;; pt2::xcoord = pt3::xcoord = cr_r
        ;; pt3::ycoord = pt4::ycoord = cr_b

        lda     cr_l
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
        cmp     #4
        bne     do_pt

        ;; --------------------------------------------------
        ;; Finish up

        copy16  cr_l, vx
        copy16  cr_t, vy

        scmp16   cr_r, clip_bounds+MGTK::Rect::x2
        ;; if (cr_r < clip_bounds::x2) more drawing is needed
        sta     more_drawing_needed_flag ; update bit7

        MGTK_CALL MGTK::SetPortBits, portbits
        clc                     ; C=0 means clipping rect is valid
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
        cmp     clip_window_id
        beq     next_pt

        ;; --------------------------------------------------
        ;; Compute window edges (including non-content area)

        win_l := getwinframerect_params::rect::x1
        win_t := getwinframerect_params::rect::y1
        win_r := getwinframerect_params::rect::x2
        win_b := getwinframerect_params::rect::y2

        copy8   findwindow_params::window_id, getwinframerect_params::window_id
        MGTK_CALL MGTK::GetWinFrameRect, getwinframerect_params

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

        ;; Cases 7/8/9 (and done)
        ;; if (win_l > cr_l)
        ;; . cr_r = win_l - 1
        scmp16  cr_l, win_l
    IF_NEG
        sub16   win_l, #1, cr_r
        jmp     reclip
    END_IF

        ;; Cases 1/2/3 (and continue below)
        ;; if (cr_r > win_r)
        ;; . cr_r = win_r
        scmp16  win_r, cr_r
    IF_NEG
        copy16  win_r, cr_r
        ;; in case 2 this will be reset
    END_IF

        ;; Cases 3/6 (and done)
        ;; if (win_t > cr_t)
        ;; . cr_b = win_t - 1
        scmp16  cr_t, win_t
    IF_NEG
        sub16   win_t, #1, cr_b
        jmp     reclip
    END_IF

        ;; Cases 1/4 (and done)
        ;; if (win_b < cr_b)
        ;; . cr_t = win_b + 1
        scmp16  win_b, cr_b
    IF_NEG
        ldxy    win_b
        inxy
        stxy    cr_t
        jmp     reclip
    END_IF

        ;; Case 2
        ;; if (win_r < stash_r)
        ;; . cr_l = win_r + 1
        ;; . cr_r = stash_r
        scmp16  stash_r, win_r
    IF_POS
        ldxy    win_r
        inxy
        stxy    cr_l
        copy16  stash_r, cr_r
        jmp     reclip
    END_IF

        ;; Case 5 - done!
        ;; ... with this clip rect, but whole icon may need more painting.
        jmp     reentry

        ;; --------------------------------------------------

is_degenerate:
        scmp16  cr_r, cr_l
        rts

.endproc ; CalcWindowIntersectionsImpl
CalcWindowIntersections := CalcWindowIntersectionsImpl::start

;;; ============================================================
;;; Used when doing clipped drawing to map viewport and icon
;;; being drawn back to window coordinates, so that shade
;;; patterns are correct.

.proc OffsetPortAndIcon
        lda     clip_window_id
        RTS_IF_ZERO

        clip_dx := clip_coords + MGTK::Point::xcoord
        clip_dy := clip_coords + MGTK::Point::xcoord

        ldxy    clip_dx
        addxy   portbits::maprect::x1
        addxy   portbits::maprect::x2
        addxy   bitmap_rect+MGTK::Rect::x1
        addxy   bitmap_rect+MGTK::Rect::x2 ; `bitmap_rect` used for dimming
        addxy   label_rect+MGTK::Rect::x1  ; x2 not used for clipping

        ldxy    clip_dy
        addxy   portbits::maprect::y1
        addxy   portbits::maprect::y2
        addxy   bitmap_rect+MGTK::Rect::y1
        addxy   bitmap_rect+MGTK::Rect::y2 ; `bitmap_rect` used for dimming
        addxy   label_rect+MGTK::Rect::y1  ; y2 not used for clipping

        MGTK_CALL MGTK::SetPortBits, portbits

        ;; Invert for the next call
        ldx     #2              ; loop over dimensions
:       sub16   #0, clip_coords,x, clip_coords,x
        dex                     ; next dimension
        dex
        bpl     :-
        rts
.endproc ; OffsetPortAndIcon

;;; ============================================================
;;; Used/Free icon map
;;; ============================================================

;;; Find first available free icon in the map; if
;;; available, mark it and return index+1.

.proc AllocateIcon
        ;; Search for first byte with a set (available) bit
        ldx     #0
loop:   lda     free_icon_map,x
        bne     :+
        inx
        bne     loop            ; always
:
        ;; X has byte offset - turn into index
        pha                     ; A = table byte
        txa                     ; X = offset
        asl                     ; *= 8
        asl
        asl
        tax                     ; X = index

        ;; Add in the bit offset
        pla                     ; A = table byte
        dex
:       inx
        ror
        bcc     :-              ; clear = in use
        txa

        ;; Mark it used
        pha
        jsr     IconMapIndexToOffsetMask
        eor     #$FF
        and     free_icon_map,x ; clear bit to mark used
        sta     free_icon_map,x

        pla
        rts
.endproc ; AllocateIcon

;;; Mark the specified icon as free

.proc FreeIcon
        jsr     IconMapIndexToOffsetMask
        ora     free_icon_map,x ; set bit to mark free
        sta     free_icon_map,x
        rts
.endproc ; FreeIcon

;;; Input: A = icon num (1...127)
;;; Output: X = index in `free_icon_map`, A = bit mask (e.g. %0001000)
.proc IconMapIndexToOffsetMask
        pha                     ; A = index
        and     #7
        tax
        ldy     table,x         ; Y = mask

        pla                     ; A = index
        lsr                     ; /= 8
        lsr
        lsr
        tax                     ; X = offset

        tya                     ; A = mask
        rts

table:  .byte   1<<0, 1<<1, 1<<2, 1<<3, 1<<4, 1<<5, 1<<6, 1<<7

.endproc ; IconMapIndexToOffsetMask

;;; Each byte represents 8 icons. id 0 is unused.
free_icon_map:
        .byte   $FE, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        .byte   $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        ASSERT_TABLE_SIZE free_icon_map, (::kMaxIconCount + 7)/8

;;; ============================================================

.proc InitSetIconPort
        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::SetPort, icon_grafport
        rts
.endproc ; InitSetIconPort

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
.endproc ; PushPointers

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
.endproc ; PopPointers

.endscope ; icon_toolkit
