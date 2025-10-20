;;; ============================================================
;;; Icon ToolKit
;;; ============================================================

.scope icontk
        ITKEntry := *

;;; ============================================================
;;; Zero Page usage (saved/restored around calls)

        zp_start := $06
        kMaxZPAddress = $50
        kMaxCommandDataSize = 9

PARAM_BLOCK, zp_start
;;; Initially points at the call site, then at passed params
params_addr     .addr

;;; Copy of the passed params
command_data    .res    kMaxCommandDataSize

;;; Other ZP usage
generic_ptr     .addr

icon_ptr        .addr           ; Set by `SetIconPtr`, used everywhere
res_ptr         .addr           ; Set by `GetIconResource`

poly_coords     .tag    MGTK::Point ; used in `DragHighlighted`
last_coords     .tag    MGTK::Point ; used in `DragHighlighted`

clip_coords     .tag    MGTK::Point ; Used for clipped drawing
clip_bounds     .tag    MGTK::Rect  ; Used for clipped drawing

bitmap_rect     .tag    MGTK::Rect  ; populated by `CalcIconRects`
label_rect      .tag    MGTK::Rect  ; populated by `CalcIconRects`
bounding_rect   .tag    MGTK::Rect  ; populated by `CalcIconRects`
rename_rect     .tag    MGTK::Rect  ; populated by `CalcIconRects`

;;; For size calculation, not actually used
zp_end          .byte
END_PARAM_BLOCK

        .assert zp_end <= kMaxZPAddress, error, "too big"
        kBytesToSave = zp_end - zp_start

;;; ============================================================

        .assert ITKEntry = Dispatch, error, "dispatch addr"
.proc Dispatch
        ;; Adjust stack/stash
        pla
        sta     params_lo
        clc
        adc     #<3
        tax
        pla
        sta     params_hi
        adc     #>3
        phax

        ;; Save ZP
        PUSH_BYTES kBytesToSave, zp_start

        ;; Point `params_addr` at the call site
        params_lo := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     params_addr
        params_hi := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     params_addr+1

        ;; Grab command number
        ldy     #1              ; Note: rts address is off-by-one
        lda     (params_addr),y
        tax
        copylohi jump_table_lo,x, jump_table_hi,x, dispatch

        ;; Point `params_addr` at actual params
        iny
        lda     (params_addr),y
        tax
        iny
        lda     (params_addr),y
        sta     params_addr+1
        stx     params_addr

.ifdef DEBUG
        ;; Bad if param block overlaps our zero page useage
        cmp16   params_addr, #zp_end
    IF LT
        brk
    END_IF
.endif ; DEBUG

        ;; Copy param data to `command_data`
        ldy     #kMaxCommandDataSize-1
:       copy8   (params_addr),y, command_data,y
        dey
        bpl     :-

        ;; Invoke the command
        dispatch := *+1
        jsr     SELF_MODIFIED
        tay                     ; A = result

        ;; Restore ZP
        POP_BYTES kBytesToSave, zp_start

        tya                     ; A = result
        rts

jump_table_lo:
        .lobytes   InitToolKitImpl
        .lobytes   AllocIconImpl
        .lobytes   HighlightIconImpl
        .lobytes   DrawIconRawImpl
        .lobytes   FreeIconImpl
        .lobytes   FreeAllImpl
        .lobytes   FindIconImpl
        .lobytes   DragHighlightedImpl
        .lobytes   UnhighlightIconImpl
        .lobytes   DrawAllImpl
        .lobytes   IconInRectImpl
        .lobytes   EraseIconImpl
        .lobytes   GetIconBoundsImpl
        .lobytes   DrawIconImpl
        .lobytes   GetIconEntryImpl
        .lobytes   GetRenameRectImpl
        .lobytes   GetBitmapRectImpl
        .lobytes   OffsetAllImpl
        .lobytes   GetAllBoundsImpl

jump_table_hi:
        .hibytes   InitToolKitImpl
        .hibytes   AllocIconImpl
        .hibytes   HighlightIconImpl
        .hibytes   DrawIconRawImpl
        .hibytes   FreeIconImpl
        .hibytes   FreeAllImpl
        .hibytes   FindIconImpl
        .hibytes   DragHighlightedImpl
        .hibytes   UnhighlightIconImpl
        .hibytes   DrawAllImpl
        .hibytes   IconInRectImpl
        .hibytes   EraseIconImpl
        .hibytes   GetIconBoundsImpl
        .hibytes   DrawIconImpl
        .hibytes   GetIconEntryImpl
        .hibytes   GetRenameRectImpl
        .hibytes   GetBitmapRectImpl
        .hibytes   OffsetAllImpl
        .hibytes   GetAllBoundsImpl

        ASSERT_EQUALS *-jump_table_hi, jump_table_hi-jump_table_lo
.endproc ; Dispatch

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
;;; Output: `icon_ptr` = A,X = address of IconEntry
.proc SetIconPtr
        tay
        ldx     icon_ptrs_high,y
        lda     icon_ptrs_low,y
        stax    icon_ptr
        rts
.endproc ; SetIconPtr


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
PARAM_BLOCK params, icontk::command_data
headersize      .byte
a_polybuf       .addr
bufsize         .word
a_typemap       .addr
a_heap          .addr
END_PARAM_BLOCK

        table_ptr := generic_ptr

        copy8   params::headersize, header_height
        copy16  params::a_polybuf, polybuf_addr
        copy16  params::bufsize, bufsize
        copy16  params::a_typemap, typemap_addr
        copy16  params::a_heap, table_ptr

        ;; --------------------------------------------------
        ;; Populate `icon_ptrs_low/high` table

        ldx     #1
    DO
        ;; Populate table entry
        copy8   table_ptr, icon_ptrs_low,x
        copy8   table_ptr+1, icon_ptrs_high,x

        ;; Next entry
        add16_8 table_ptr, #.sizeof(IconEntry)
        inx
    WHILE X <> #kMaxIconCount+1 ; allow up to the maximum

        ;; --------------------------------------------------
        ;; MaxDraggableItems = BufferSize / kIconPolySize

        ldy     #0
    DO
        sub16_8 bufsize, #kIconPolySize
        bit     bufsize+1
        BREAK_IF NS
        iny
    WHILE NOT_ZERO              ; always
        sty     max_draggable_icons

        rts

bufsize:
        .word   0
.endproc ; InitToolKitImpl

;;; ============================================================
;;; AllocIcon

.proc AllocIconImpl
.struct AllocIconParams
        icon    .byte           ; out
        entry   .addr           ; out
.endstruct

        jsr     AllocateIcon
        ldy     #AllocIconParams::icon
        sta     (params_addr),y

        ;; Add it to `icon_list`
        ldx     num_icons
        sta     icon_list,x
        inc     num_icons

        ;; Grab the `IconEntry`, to return it and update it
        jsr     SetIconPtr
        ldy     #AllocIconParams::entry
        sta     (params_addr),y
        txa
        iny
        sta     (params_addr),y

        ;; Initialize IconEntry::state
        lda     #0
        ;; ldy     #IconEntry::state
        ASSERT_EQUALS IconEntry::state, 0
        tay
        sta     (icon_ptr),y

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
PARAM_BLOCK params, icontk::command_data
icon    .byte
END_PARAM_BLOCK

        ;; Pointer to IconEntry
        lda     params::icon
        pha                     ; A = icon

        ;; Mark highlighted
        jsr     GetIconState    ; A = state, sets `icon_ptr` too
        ora     #kIconEntryStateHighlighted
        sta     (icon_ptr),y

        pla                     ; A = icon
        jmp     MaybeMoveIconToTop
.endproc ; HighlightIconImpl

;;; ============================================================
;;; FreeIcon

;;; param is pointer to icon number

.proc FreeIconImpl
PARAM_BLOCK params, icontk::command_data
icon    .byte
END_PARAM_BLOCK

        lda     params::icon

.ifdef DEBUG
        ;; Is it in `icon_list`?
        jsr     IsInIconList
    IF NOT_ZERO
        return8 #1              ; Not found
    END_IF
.endif ; DEBUG

        jsr     FreeIconCommon ; A = icon id
        return8 #0
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
:       copy8   icon_list+1,x, icon_list,x
        inx
        cpx     num_icons
        bne     :-

        pla                     ; A = icon
        rts
.endproc ; RemoveIconFromList

;;; ============================================================

;;; Input: A = icon
;;; Output: Z=0 if fixed, Z=1 if not fixed
.proc IsIconFixed
        jsr     SetIconPtr
        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryFlagsFixed
        rts
.endproc ; IsIconFixed

;;; ============================================================

;;; Move icon to end of `icon_list`, i.e. top of z-order, unless
;;; it has `kIconEntryFlagsFixed`.
;;; Input: A = icon
;;; Trashes `icon_ptr`
;;; Assert: icon is in `icon_list`
.proc MaybeMoveIconToTop
        pha                     ; A = icon
        jsr     IsIconFixed
    IF NOT_ZERO
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
PARAM_BLOCK params, icontk::command_data
icon    .byte
END_PARAM_BLOCK

        ;; Pointer to IconEntry
        lda     params::icon
        ldx     #$80            ; do clip
        sec                     ; do redraw highlighted
        jmp     EraseIconCommon ; A = icon id, X = clip flag, C = redraw flag
.endproc ; EraseIconImpl

;;; ============================================================
;;; FreeAll

;;; param is window id (0 = desktop)

.proc FreeAllImpl
PARAM_BLOCK params, icontk::command_data
window_id       .byte
icon            .byte
END_PARAM_BLOCK

        ldx     num_icons
        dex
    DO
        txa
        pha

        lda     icon_list,x
        jsr     GetIconWin      ; A = window_id
      IF A = params::window_id
        pla
        pha
        tax
        lda     icon_list,x
        jsr     FreeIconCommon  ; A = icon id
      END_IF

        pla
        tax
        dex
    WHILE POS
        rts
.endproc ; FreeAllImpl

;;; ============================================================
;;; FindIcon

.proc FindIconImpl
PARAM_BLOCK params, icontk::command_data
coords          .tag MGTK::Point
result          .byte           ; out
window_id       .byte
END_PARAM_BLOCK

        MGTK_CALL MGTK::MoveTo, params::coords

        ldx     num_icons
    IF NOT_ZERO

      DO
        dex
        txa
        pha

        ;; Check the icon
        lda     icon_list,x
        jsr     GetIconWin      ; A = window_id, sets `icon_ptr` too

        ;; Matching window?
       IF A = params::window_id
        ;; In poly?
        jsr     CalcIconPoly    ; requires `icon_ptr` set
        MGTK_CALL MGTK::InRect, bounding_rect
        IF NOT_ZERO
        MGTK_CALL MGTK::InPoly, poly
        bne     inside          ; yes!
        END_IF
       END_IF

        ;; Nope, next
        pla
        tax
      WHILE NOT_ZERO
    END_IF

        ;; Nothing found
        lda     #0
        beq     finish          ; always

        ;; Found one!
inside: pla
        tax
        lda     icon_list,x

finish:
        ldy     #params::result - params
        sta     (params_addr),y
        rts
.endproc ; FindIconImpl

;;; ============================================================
;;; DragHighlighted

.proc DragHighlightedImpl
PARAM_BLOCK params, icontk::command_data
icon    .byte                   ; in/out
coords  .tag    MGTK::Point
END_PARAM_BLOCK

        initial_coords := params::coords

        poly_dx := poly_coords + MGTK::Point::xcoord
        poly_dy := poly_coords + MGTK::Point::ycoord

        ;; Copy initial coords to `last_coords`
        COPY_STRUCT MGTK::Point, initial_coords, last_coords

        lda     #0
        sta     highlight_icon_id
        sta     trash_flag

;;; Determine if it's a drag or just a click
.scope _DragDetectImpl

peek:   MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
    IF A <> #MGTK::EventKind::drag
        lda     #IconTK::kDragResultNotADrag
        jmp     exit_with_a
    END_IF

        kDragDelta = 5

        ;; Compute mouse delta
        ldx     #2              ; loop over dimensions
    DO
        lda     findwindow_params,x
        sec
        sbc     z:last_coords,x
        tay
        lda     findwindow_params+1,x
        sbc     z:last_coords+1,x
    IF NEG
        cpy     #AS_BYTE(-kDragDelta)
        bcc     is_drag         ; above threshold, so drag
        bcs     next            ; always
    END_IF
        cpy     #kDragDelta     ; above threshold, so drag
        bcs     is_drag

next:   dex
        dex
    WHILE POS
        bmi     peek            ; always
.endscope ; _DragDetectImpl

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
    IF NOT_ZERO
        copy8   #$80, trash_flag
    END_IF
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

        poly_ptr := generic_ptr
        copy16  polybuf_addr, poly_ptr
        copy8   #$80, poly::lastpoly  ; more to follow

        INVOKE_WITH_LAMBDA _IterateHighlightedIcons

        jsr     CalcIconPoly    ; sets `res_ptr`

        ;; Copy poly into place
        ldy     #kIconPolySize-1
    DO
        copy8   poly,y, (poly_ptr),y
        dey
    WHILE POS

        add16_8 poly_ptr, #kIconPolySize
        rts
        END_OF_LAMBDA

        ;; Mark last icon
        sub16_8 poly_ptr, #kIconPolySize
        ldy     #1              ; MGTK Polygon "not last" flag
        copy8   #0, (poly_ptr),y ; last polygon

        copy8   #0, poly::lastpoly ; restore default

        ;; --------------------------------------------------

        jsr     _XDrawOutline

peek:   MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::EventKind::drag
        jne     not_drag

        ;; Escape key?
        lda     KBD             ; MGTK doesn't process keys during drag
    IF A = #CHAR_ESCAPE | $80
        bit     KBDSTRB         ; consume the keypress
        copy8   #MGTK::EventKind::key_down, peekevent_params::kind
        jmp     not_drag
    END_IF

        ;; Coords changed?
        ldx     #.sizeof(MGTK::Point)-1
    DO
        lda     findwindow_params,x
        cmp     last_coords,x
        bne     moved
        dex
    WHILE POS
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
    IF NOT_ZERO
        jsr     _UnhighlightIcon
        copy8   #0, highlight_icon_id
    END_IF

        ;; Is the new icon valid?
        pla
        beq     update_poly
        jsr     _ValidateTargetAndHighlight

update_poly:
        ;; Update poly coordinates
        ldx     #2              ; loop over dimensions
    DO
        sub16   findwindow_params,x, last_coords,x, poly_coords,x
        dex                     ; next dimension
        dex
    WHILE POS
        COPY_STRUCT MGTK::Point, findwindow_params::mousex, last_coords

        copy16  polybuf_addr, poly_ptr
ploop:  ldy     #2              ; offset in poly to first vertex
    DO
        add16in (poly_ptr),y, poly_dx, (poly_ptr),y
        iny
        add16in (poly_ptr),y, poly_dy, (poly_ptr),y
        iny
    WHILE Y <> #kIconPolySize

        ldy     #1              ; MGTK Polygon "not last" flag
        lda     (poly_ptr),y
    IF NOT_ZERO
        lda     poly_ptr
        clc
        adc     #kIconPolySize
        sta     poly_ptr
        bcc     ploop
        inc     poly_ptr+1
        bcs     ploop           ; always
    END_IF
        jsr     _XDrawOutline
        jmp     peek

        ;; --------------------------------------------------
        ;; End of the drag - figure out how to finish up
not_drag:
        jsr     _XDrawOutline

        lda     highlight_icon_id
    IF NOT_ZERO
        jsr     _UnhighlightIcon
    END_IF

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
    IF NS
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
    DO
        sub16   findwindow_params,x, initial_coords,x, poly_coords,x
        dex                     ; next dimension
        dex
    WHILE POS

        INVOKE_WITH_LAMBDA _IterateHighlightedIcons
        jsr     SetIconPtr

        ldy     #IconEntry::iconx
        add16in (icon_ptr),y, poly_dx, (icon_ptr),y
        iny
        add16in (icon_ptr),y, poly_dy, (icon_ptr),y
        rts
        END_OF_LAMBDA

        lda     #IconTK::kDragResultMove
        FALL_THROUGH_TO exit_with_a

        ;; --------------------------------------------------

exit_with_a:
        tax                     ; A = return value
        ldy     #params::icon - params
        copy8   highlight_icon_id, (params_addr),y
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
    DO
        lda     icon_list,x
        jsr     GetIconState
        and     #kIconEntryStateHighlighted
      IF NOT_ZERO
        ldx     index
        lda     icon_list,x

        proc := *+1
        jsr     SELF_MODIFIED
      END_IF

        inc     index
        index := *+1
        ldx     #SELF_MODIFIED_BYTE
    WHILE X <> num_icons

        rts
.endproc ; _IterateHighlightedIcons



;;; Like `FindIcon`, but validates that the passed coordinates are
;;; in the true content area of the window (not scrollbars/grow box/header)
;;;
;;; Inputs: `findwindow_params` mouse coords populated
;;; Outputs: A = icon (0 if none found), `findwindow_params::window_id` populated
;;; Trashes `generic_ptr`

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

fail:   return8 #0              ; no icon

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
;;; Trashes `generic_ptr`
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
        win_ptr := generic_ptr
        copy16  window_ptr, z:win_ptr
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

.proc _ValidateTargetAndHighlight
        ;; Over an icon
        sta     icon_num

        jsr     GetIconState    ; A = state, sets `icon_ptr` too

        ;; Highlighted?
        ;;and     #kIconEntryStateHighlighted
        ASSERT_EQUALS ::kIconEntryStateHighlighted, $40
        asl
        bmi     done            ; Not valid (it's being dragged)

        ;; Is it a drop target?
        ;;ldy     #IconEntry::win_flags
        ASSERT_EQUALS (IconEntry::win_flags - IconEntry::state), 1
        iny
        lda     (icon_ptr),y
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
;;; Output: A = window id (0=desktop), `icon_ptr` set
.proc GetIconWin
        jsr     GetIconFlags
        and     #kIconEntryWinIdMask
        rts
.endproc ; GetIconWin

;;; Input: A = icon number
;;; Output: A = flags (including window), Y = IconEntry::win_flags, `icon_ptr` set
.proc GetIconFlags
        jsr     SetIconPtr
        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        rts
.endproc ; GetIconFlags

;;; Input: A = icon number
;;; Output: A = state, Y = IconEntry::state, `icon_ptr` set
.proc GetIconState
        jsr     SetIconPtr
        ldy     #IconEntry::state
        lda     (icon_ptr),y
        rts
.endproc ; GetIconState

;;; ============================================================
;;; UnhighlightIcon

;;; param is pointer to IconEntry

.proc UnhighlightIconImpl
PARAM_BLOCK params, icontk::command_data
icon    .byte
END_PARAM_BLOCK

        ;; Pointer to IconEntry
        lda     params::icon
        pha                     ; A = icon

        ;; Mark not highlighted
        jsr     GetIconState    ; A = state, sets `icon_ptr` too
        and     #AS_BYTE(~kIconEntryStateHighlighted)
        sta     (icon_ptr),y

        pla                     ; A = icon
        jmp     MaybeMoveIconToTop
.endproc ; UnhighlightIconImpl

;;; ============================================================
;;; IconInRect

.proc IconInRectImplImpl
PARAM_BLOCK params, icontk::command_data
icon    .byte
rect    .tag    MGTK::Rect
END_PARAM_BLOCK

start:
        lda     params::icon
        jsr     SetIconPtr
        jsr     CalcIconRects

        ;; Compare the rect against both the bitmap and label rects

        ;; --------------------------------------------------
        ;; Bitmap
        ldx     #2              ; loop over dimensions
    DO
        ;; top/left of bitmap > bottom/right of rect --> outside
        scmp16  params::rect+MGTK::Rect::bottomright,x, bitmap_rect+MGTK::Rect::topleft,x
        bmi     :+

        ;; bottom/right of bitmap < top/left of rect --> outside
        scmp16  bitmap_rect+MGTK::Rect::bottomright,x, params::rect+MGTK::Rect::topleft,x
        bmi     :+

        dex                     ; next dimension
        dex
    WHILE POS
        bmi     inside          ; always
:
        ;; --------------------------------------------------
        ;; Label

        ldx     #2              ; loop over dimensions
    DO
        ;; top/left of text > bottom/right of rect --> outside
        scmp16  params::rect+MGTK::Rect::bottomright,x, label_rect+MGTK::Rect::topleft,x
        bmi     outside

        ;; bottom/right of text < top/left of rect --> outside
        scmp16  label_rect+MGTK::Rect::bottomright,x, params::rect+MGTK::Rect::topleft,x
        bmi     outside

        dex                     ; next dimension
        dex
    WHILE POS

inside:
        return8 #1

outside:
        return8 #0
.endproc ; IconInRectImplImpl
IconInRectImpl := IconInRectImplImpl::start

;;; ============================================================
;;; GetIconBounds

.proc GetIconBoundsImpl
PARAM_BLOCK params, icontk::command_data
icon    .byte
rect    .tag    MGTK::Rect ; out
END_PARAM_BLOCK

        ;; Calc icon bounds
        lda     params::icon
        jsr     SetIconPtr
        jsr     CalcIconBoundingRect

        ASSERT_EQUALS params::rect - params, 1
        FALL_THROUGH_TO CopyBoundingRectIntoOutParams
.endproc ; GetIconBoundsImpl

;;; Assert: out rect is at offset 1
.proc CopyBoundingRectIntoOutParams
        ;; Copy rect into out params
        ldx     #.sizeof(MGTK::Rect)-1
        ldy     #1 + .sizeof(MGTK::Rect)-1
    DO
        copy8   bounding_rect,x, (params_addr),y
        dey
        dex
    WHILE POS

        rts
.endproc ; GetIconBoundsImpl

;;; ============================================================
;;; GetRenameRect

.proc GetRenameRectImpl
PARAM_BLOCK params, icontk::command_data
icon    .byte
rect    .tag    MGTK::Rect ; out
END_PARAM_BLOCK

        ;; Calc icon bounds
        ASSERT_EQUALS params::icon, icontk::command_data
        jsr     GetXYZRectImplHelper

        ;; Copy rect into out params
        ldx     #.sizeof(MGTK::Rect)-1
        ldy     #(params::rect - params) + .sizeof(MGTK::Rect)-1
    DO
        copy8   rename_rect,x, (params_addr),y
        dey
        dex
    WHILE POS

        rts
.endproc ; GetRenameRectImpl

;;; ============================================================
;;; GetBitmapRect

.proc GetBitmapRectImpl
PARAM_BLOCK params, icontk::command_data
icon    .byte
rect    .tag    MGTK::Rect ; out
END_PARAM_BLOCK

        ;; Calc icon bounds
        ASSERT_EQUALS params::icon, icontk::command_data
        jsr     GetXYZRectImplHelper

        ;; Copy rect into out params
        ldx     #.sizeof(MGTK::Rect)-1
        ldy     #(params::rect - params) + .sizeof(MGTK::Rect)-1
    DO
        copy8   bitmap_rect,x, (params_addr),y
        dey
        dex
    WHILE POS

        rts
.endproc ; GetBitmapRectImpl

.proc GetXYZRectImplHelper
        lda     command_data    ; a.k.a. `params::icon`
        jsr     SetIconPtr
        jmp     CalcIconRects
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
PARAM_BLOCK params, icontk::command_data
        icon    .byte
END_PARAM_BLOCK

        sta     clip_icons_flag

        ;; Slow enough that events should be checked; this allows
        ;; double-clicks during icon repaints (e.g. deselects)
        MGTK_CALL MGTK::CheckEvents

        ;; Pointer to IconEntry
        lda     params::icon
        jsr     SetIconPtr

        jsr     CalcIconRects

        ;; Stash some flags
        ldy     #IconEntry::state
        copy8   (icon_ptr),y, state
        ASSERT_EQUALS IconEntry::win_flags, IconEntry::state + 1
        iny
        copy8   (icon_ptr),y, win_flags

        ;; For quick access
        and     #kIconEntryWinIdMask
        sta     clip_window_id

        ;; copy icon definition bits
        jsr     GetIconResource ; sets `res_ptr` based on `icon_ptr`
        ldy     #.sizeof(MGTK::MapInfo) - .sizeof(MGTK::Point) - 1
    DO
        lda     (res_ptr),y
        sta     icon_paintbits_params::mapbits,y
        sta     mask_paintbits_params::mapbits,y
        dey
    WHILE POS

        ;; Icon definition is followed by pointer to mask address.
        ldy     #.sizeof(MGTK::MapInfo) - .sizeof(MGTK::Point)
        copy16in (res_ptr),y, mask_paintbits_params::mapbits

        ;; Determine if we want clipping, based on icon type and flags.

        bit     clip_icons_flag
        bpl     _DoPaint        ; no clipping, just paint

        ;; Set up clipping structs and port
        lda     clip_window_id
    IF ZERO
        jsr     SetPortForVolIcon
    ELSE
        jsr     SetPortForWinIcon
        bne     ret             ; obscured
    END_IF

        ;; Paint icon iteratively, handling overlapping windows
    DO
        jsr     CalcWindowIntersections
        BREAK_IF CS             ; nothing remaining to draw

        jsr     OffsetPortAndIcon
        jsr     _DoPaint
        jsr     OffsetPortAndIcon

        bit     more_drawing_needed_flag
    WHILE NS

ret:    rts


.proc _DoPaint
        label_pos := generic_ptr

        ;; Prep coords
        copy16  label_rect+MGTK::Rect::x1, label_pos+MGTK::Point::xcoord
        add16_8 label_rect+MGTK::Rect::y1, #kSystemFontHeight-1, label_pos+MGTK::Point::ycoord

        ldx     #.sizeof(MGTK::Point)-1
    DO
        lda     bitmap_rect+MGTK::Rect::topleft,x
        sta     icon_paintbits_params::viewloc,x
        sta     mask_paintbits_params::viewloc,x
        dex
    WHILE POS

        ;; Set text background color
        lda     #MGTK::textbg_white
        ASSERT_EQUALS ::kIconEntryStateHighlighted, $40
        bit     state           ; highlighted?
    IF VS
        lda     #MGTK::textbg_black
    END_IF
        sta     settextbg_params
        MGTK_CALL MGTK::SetTextBG, settextbg_params

        MGTK_CALL MGTK::HideCursor

        ;; --------------------------------------------------
        ;; Icon

        ;; Shade (XORs background)
        ASSERT_EQUALS ::kIconEntryStateDimmed, $80
        bit     state
    IF NS
        MGTK_CALL MGTK::SetPattern, dark_pattern
        jsr     _Shade
    END_IF

        ;; Mask (cleared to white or black)
        ASSERT_EQUALS ::kIconEntryStateHighlighted, $40
        bit     state
    IF VS
        MGTK_CALL MGTK::SetPenMode, penBIC
    ELSE
        MGTK_CALL MGTK::SetPenMode, penOR
    END_IF
        MGTK_CALL MGTK::PaintBitsHC, mask_paintbits_params

        ;; Shade again (restores background)
        ASSERT_EQUALS ::kIconEntryStateDimmed, $80
        bit     state
    IF NS
        jsr     _Shade
    END_IF

        ;; Icon (drawn in black or white)
        ASSERT_EQUALS ::kIconEntryStateHighlighted, $40
        bit     state
    IF VS
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

        return8 #0

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

;;; Inputs: `icon_ptr` = `IconEntry`
;;; Output: `res_ptr` = `IconResource`
.proc GetIconResource
        ldy     #IconEntry::type
        lda     (icon_ptr),y         ; A = type
        asl                          ; *= 2
        tay                          ; Y = table offset

        ;; Re-use `res_ptr` temporarily
        copy16  typemap_addr, res_ptr

        lda     (res_ptr),y
        tax
        iny
        lda     (res_ptr),y
        sta     res_ptr+1
        stx     res_ptr
        rts
.endproc ; GetIconResource

;;; ============================================================

;;; Input: `icon_ptr` points at icon
;;; Output: Populates `bitmap_rect` and `label_rect` and `text_buffer`
;;; Sets `res_ptr`
.proc CalcIconRects
        ;; Copy, pad, and measure name
        jsr     PrepareName

        jsr     GetIconResource ; sets `res_ptr` based on `icon_ptr`

        ;; Bitmap top/left - copy from icon entry
        ldy     #IconEntry::iconx+3
        ldx     #3
    DO
        copy8   (icon_ptr),y, bitmap_rect+MGTK::Rect::topleft,x
        dey
        dex
    WHILE POS

        ;; Bitmap bottom/right
        ldy     #IconResource::maprect + MGTK::Rect::x2
        add16in bitmap_rect+MGTK::Rect::x1, (res_ptr),y, bitmap_rect+MGTK::Rect::x2
        iny
        add16in bitmap_rect+MGTK::Rect::y1, (res_ptr),y, bitmap_rect+MGTK::Rect::y2

        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryFlagsSmall
    IF NOT_ZERO
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
        add16in label_rect+MGTK::Rect::x1, (res_ptr),y, label_rect+MGTK::Rect::x1
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

        rts

stash_rename_rect:
        COPY_STRUCT MGTK::Rect, label_rect, rename_rect
        rts
.endproc ; CalcIconRects

;;; Input: `icon_ptr` points at icon
;;; Output: Populates `bitmap_rect` and `label_rect` and `bounding_rect`
;;; Sets `res_ptr`
.proc CalcIconBoundingRect
        jsr     CalcIconRects

        COPY_BLOCK bitmap_rect, bounding_rect

        ;; Union of rectangles (expand `bounding_rect` to encompass `label_rect`)
        MGTK_CALL MGTK::UnionRects, unionrects_label_bounding

        rts
.endproc ; CalcIconBoundingRect

.params unionrects_label_bounding
        .addr   label_rect
        .addr   bounding_rect
.endparams

kIconPolySize = (8 * .sizeof(MGTK::Point)) + 2

;;; Input: `icon_ptr` points at icon
;;; Output: Populates `bitmap_rect` and `label_rect` and `bounding_rect`
;;;         and (of course) `poly`
.proc CalcIconPoly
        jsr     CalcIconBoundingRect

        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryFlagsSmall
    IF NOT_ZERO
        ;; ----------------------------------------
        ;; Small icon

        ;;      v0/v1/v2/v3/v4             v5
        ;;        +-----------------------+
        ;;        |                       |
        ;;        |                       |
        ;;        +-----------------------+
        ;;      v7                         v6

        ;; Start off making all (except v6) the same
        ldx     #.sizeof(MGTK::Point)-1
    DO
        lda     bitmap_rect+MGTK::Rect::topleft,x
        sta     poly::v0,x
        sta     poly::v1,x
        sta     poly::v2,x
        sta     poly::v3,x
        sta     poly::v4,x
        sta     poly::v5,x
        sta     poly::v7,x
        dex
    WHILE POS

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

        rts
.endproc ; CalcIconPoly

;;; Copy name from IconEntry (`icon_ptr`) to text_buffer,
;;; with leading/trailing spaces, and measure it.

.proc PrepareName
        .assert text_buffer - 1 = drawtext_params::textlen, error, "location mismatch"

        dest := drawtext_params::textlen

        ldy     #.sizeof(IconEntry)
        ldx     #.sizeof(IconEntry) - IconEntry::name
    DO
        copy8   (icon_ptr),y, dest + 1,x
        dey
        dex
    WHILE POS

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
PARAM_BLOCK params, icontk::command_data
window_id       .byte
END_PARAM_BLOCK

        ;; Get current clip rect
        port_ptr := generic_ptr
        MGTK_CALL MGTK::GetPort, port_ptr
        ldx     #.sizeof(MGTK::Rect)-1
        ldy     #MGTK::MapInfo::maprect + .sizeof(MGTK::Rect)-1
    DO
        copy8   (port_ptr),y, icon_in_rect_params::rect,x
        dey
        dex
    WHILE POS

        ;; Loop over all icons
        ldx     #AS_BYTE(-1)
    DO
        inx
        BREAK_IF X = num_icons
        txa
        pha

        copy8   icon_list,x, icon_in_rect_params::icon

        ;; Is it in the target window?
        jsr     GetIconWin      ; A = window_id, sets `icon_ptr` too
      IF A = params::window_id
        ;; In maprect?
        ITK_CALL IconTK::IconInRect, icon_in_rect_params
       IF NOT_ZERO
        ITK_CALL IconTK::DrawIconRaw, icon_in_rect_params::icon
       END_IF
      END_IF

        pla
        tax
    WHILE POS                   ; always

        rts
.endproc ; DrawAllImpl

;;; ============================================================
;;; OffsetAll

.proc OffsetAllImpl
PARAM_BLOCK params, icontk::command_data
window_id       .byte
delta_x         .word
delta_y         .word
END_PARAM_BLOCK

        ldx     num_icons
    DO
        dex
        RTS_IF NEG
        txa
        pha

        lda     icon_list,x
        jsr     GetIconWin      ; A = window_id, sets `icon_ptr` too
      IF A = params::window_id
        ldy     #IconEntry::iconx
        add16in (icon_ptr),y, params::delta_x, (icon_ptr),y
        iny
        add16in (icon_ptr),y, params::delta_y, (icon_ptr),y
      END_IF

        pla
        tax
    WHILE POS                   ; always

        rts
.endproc ; OffsetAllImpl

;;; ============================================================
;;; GetAllBounds

.proc GetAllBoundsImpl
PARAM_BLOCK params, icontk::command_data
window_id       .byte
rect            .tag    MGTK::Rect ; out
END_PARAM_BLOCK

        COPY_STRUCT MGTK::Rect, initial_rect, bounding_rect

        ldx     num_icons
    DO
        dex
        BREAK_IF NEG
        txa
        pha

        lda     icon_list,x
        jsr     GetIconWin      ; A = window_id, sets `icon_ptr` too
      IF A = params::window_id
        jsr     CalcIconRects

        ;; Hack inherited from DeskTop: treat large icons as if they
        ;; always have a full-height bitmap. When combined with
        ;; careful default window size and icon placement calculations
        ;; in DeskTop means that icons stay vertically aligned as
        ;; windows are scrolled to the top and bottom.
        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryFlagsSmall
       IF ZERO
        sub16_8 bitmap_rect+MGTK::Rect::y2, #kMaxIconBitmapHeight, bitmap_rect+MGTK::Rect::y1
       END_IF

        MGTK_CALL MGTK::UnionRects, unionrects_bitmap_bounding
        MGTK_CALL MGTK::UnionRects, unionrects_label_bounding
      END_IF

        pla
        tax
    WHILE POS                   ; always

        ASSERT_EQUALS params::rect - params, 1
        jmp     CopyBoundingRectIntoOutParams

.params unionrects_bitmap_bounding
        .addr   bitmap_rect
        .addr   bounding_rect
.endparams

;;; Rect that will overwritten by anything unioned with it
.params initial_rect
        .word   $7FFF
        .word   $7FFF
        .word   $8000
        .word   $8000
.endparams

.endproc ; GetAllBoundsImpl

;;; ============================================================
;;; GetIconEntry

.proc GetIconEntryImpl
PARAM_BLOCK params, icontk::command_data
icon    .byte           ; in
entry   .addr           ; out
END_PARAM_BLOCK

        lda     params::icon
        jsr     SetIconPtr

        ldy     #params::entry - params
        sta     (params_addr),y
        txa
        iny
        sta     (params_addr),y

        rts
.endproc ; GetIconEntryImpl

;;; ============================================================
;;; Erase an icon; redraws overlapping icons as needed
;;; Inputs: A = icon id, X = clip_icons_flag, C = redraw highlighted flag
.proc EraseIconCommon
        sta     erase_icon_id
        stx     clip_icons_flag
        ror     redraw_highlighted_flag ; shift C into high bit

        jsr     SetIconPtr
        jsr     CalcIconPoly

        jsr     InitSetIconPort

        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        sta     clip_window_id
        sta     getwinport_params::window_id

    IF ZERO
        jsr     SetPortForVolIcon
        MGTK_CALL MGTK::GetDeskPat, addr
        MGTK_CALL MGTK::SetPattern, SELF_MODIFIED, addr
    ELSE
        jsr     SetPortForWinIcon
        RTS_IF NOT_ZERO         ; obscured!
        MGTK_CALL MGTK::SetPattern, white_pattern
    END_IF

        bit     clip_icons_flag
    IF NC
        MGTK_CALL MGTK::PaintPoly, poly
    ELSE
      DO
        jsr     CalcWindowIntersections
        BREAK_IF CS             ; nothing remaining to draw
        MGTK_CALL MGTK::PaintPoly, poly
        bit     more_drawing_needed_flag
      WHILE NS
    END_IF
        FALL_THROUGH_TO _RedrawIconsAfterErase

;;; ============================================================
;;; After erasing an icon, redraw any overlapping icons

.proc _RedrawIconsAfterErase
        COPY_BLOCK bounding_rect, icon_in_rect_params::rect

        ldx     num_icons
    DO
        dex                     ; any icons to draw?
        RTS_IF NEG

        txa
        pha
        lda     icon_list,x
        cmp     erase_icon_id
        beq     next

        sta     icon_in_rect_params::icon
        jsr     GetIconWin      ; A = window_id, sets `icon_ptr` too

        ;; Same window?
        cmp     clip_window_id
        bne     next

        bit     redraw_highlighted_flag
      IF NC
        ldy     #IconEntry::state
        lda     (icon_ptr),y
        and     #kIconEntryStateHighlighted
        bne     next
      END_IF

        ITK_CALL IconTK::IconInRect, icon_in_rect_params
      IF NOT_ZERO
        lda     clip_window_id
       IF ZERO
        ITK_CALL IconTK::DrawIcon, icon_in_rect_params::icon
       ELSE
        ITK_CALL IconTK::DrawIconRaw, icon_in_rect_params::icon
       END_IF
      END_IF

next:   pla
        tax
    WHILE POS                   ; always

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

;;; Sets `res_ptr`
.proc SetPortForVolIcon
        jsr     CalcIconBoundingRect

        ;; Will need to clip to screen bounds
        COPY_STRUCT MGTK::Rect, desktop_bounds, portbits::maprect

        jmp     DuplicateClipStructsAndSetPortBits
.endproc ; SetPortForVolIcon

;;; ============================================================

;;; Sets `res_ptr`
.proc SetPortForWinIcon
        jsr     CalcIconBoundingRect

        ;; Get window clip rect (in screen space)
        copy8   clip_window_id, getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params ; into `icon_grafport`
        RTS_IF NOT_ZERO                               ; obscured

        viewloc := icon_grafport+MGTK::GrafPort::viewloc
        maprect := icon_grafport+MGTK::GrafPort::maprect

        ldx     #2              ; loop over dimensions
    DO
        ;; Stash, needed to offset port when drawing to get correct patterns
        sub16   maprect+MGTK::Rect::topleft,x, viewloc,x, clip_coords,x

        ;; Adjust `icon_grafport` so that `viewloc` and `maprect` are just
        ;; a clipping rectangle in screen coords.
        sub16   maprect+MGTK::Rect::bottomright,x, maprect+MGTK::Rect::topleft,x, portbits::maprect+MGTK::Rect::bottomright,x
        copy16  viewloc,x, portbits::maprect::topleft,x
        add16   portbits::maprect+MGTK::Rect::topleft,x, portbits::maprect+MGTK::Rect::bottomright,x, portbits::maprect+MGTK::Rect::bottomright,x

        dex                     ; next dimension
        dex
    WHILE POS

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
    DO
        scmp16  portbits::maprect::topleft,x, bounding_rect+MGTK::Rect::topleft,x
      IF NEG
        copy16  bounding_rect+MGTK::Rect::topleft,x, portbits::maprect::topleft,x
      END_IF

        scmp16  bounding_rect+MGTK::Rect::bottomright,x, portbits::maprect::bottomright,x
      IF NEG
        copy16  bounding_rect+MGTK::Rect::bottomright,x, portbits::maprect::bottomright,x
      END_IF

        ;; Is there anything left?
        scmp16  portbits::maprect::bottomright,x, portbits::maprect::topleft,x
        bmi     empty

        dex                     ; next dimension
        dex
    WHILE POS

        ;; Duplicate structs needed for clipping
        COPY_BLOCK portbits::maprect, clip_bounds
        COPY_STRUCT portbits::maprect::topleft, portbits::viewloc

        MGTK_CALL MGTK::SetPortBits, portbits
        rts

empty:  return8 #$FF
.endproc ; DuplicateClipStructsAndSetPortBits

;;; ============================================================

;;; Returns C=0 if a non-degenerate clipping rect is returned, so a
;;; paint call is needed, and `more_drawing_needed_flag` bit7 = 1
;;; if another call to this proc is needed after the paint. Returns
;;; C=1 if no clipping rect remains, so no drawing is needed.
.proc CalcWindowIntersectionsImpl

.params cwi_findwindow_params
mousex:         .word   0
mousey:         .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams

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
    IF NEG
        CLEAR_BIT7_FLAG more_drawing_needed_flag
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

        copy8   #0, pt_num

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
    DO
        copy8   pt1::xcoord,x, cwi_findwindow_params,y
        iny
        inx
    WHILE Y <> #4

        inc     pt_num
        MGTK_CALL MGTK::FindWindow, cwi_findwindow_params
        lda     cwi_findwindow_params::window_id
        cmp     clip_window_id
        beq     next_pt

        ;; --------------------------------------------------
        ;; Compute window edges (including non-content area)

        win_l := getwinframerect_params::rect::x1
        win_t := getwinframerect_params::rect::y1
        win_r := getwinframerect_params::rect::x2
        win_b := getwinframerect_params::rect::y2

        copy8   cwi_findwindow_params::window_id, getwinframerect_params::window_id
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
    IF NEG
        sub16   win_l, #1, cr_r
        jmp     reclip
    END_IF

        ;; Cases 1/2/3 (and continue below)
        ;; if (cr_r > win_r)
        ;; . cr_r = win_r
        scmp16  win_r, cr_r
    IF NEG
        copy16  win_r, cr_r
        ;; in case 2 this will be reset
    END_IF

        ;; Cases 3/6 (and done)
        ;; if (win_t > cr_t)
        ;; . cr_b = win_t - 1
        scmp16  cr_t, win_t
    IF NEG
        sub16   win_t, #1, cr_b
        jmp     reclip
    END_IF

        ;; Cases 1/4 (and done)
        ;; if (win_b < cr_b)
        ;; . cr_t = win_b + 1
        scmp16  win_b, cr_b
    IF NEG
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
    IF POS
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
        RTS_IF ZERO

        clip_dx := clip_coords + MGTK::Point::xcoord
        clip_dy := clip_coords + MGTK::Point::ycoord

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
    DO
        sub16   #0, clip_coords,x, clip_coords,x
        dex                     ; next dimension
        dex
    WHILE POS
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
    DO
        lda     free_icon_map,x
        BREAK_IF NOT_ZERO
        inx
    WHILE NOT_ZERO              ; always

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
    DO
        inx
        ror
    WHILE CC                    ; clear = in use
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

.endscope ; icontk
