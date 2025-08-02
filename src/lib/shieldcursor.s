;;; ============================================================
;;; Routines to conditionally hide cursor
;;;
;;; * Call `PrepShieldCursor` in response to `MGTK::EventKind::no_event`
;;;   with cursor position in window coordinates.
;;; * Call `ShieldCursor` before drawing, with an `MGTK::MapInfo` e.g.
;;;   the same params for an `MGTK::PaintBits` call.
;;; * Call `UnShieldCursor` after drawing; will re-show the cursor if
;;;   it was hidden by a previous call to `ShieldCursor`
;;;
;;; Routines use $10...$13
;;; ============================================================

;;; TODO: Incorporate this into MGTK itself. This would allow skipping
;;; the `PrepShieldCursor` call and the intersection test could be
;;; made more precise since the cursor size/hotspot is known.

;;; Input: A,X = current cursor position (in window coords)
;;; Trashes $10
.proc PrepShieldCursor
        ptr := $10
        stax    ptr
        ldy     #.sizeof(MGTK::Point)-1
:       lda     (ptr),y
        sta     shield_cursor_pos,y
        dey
        bpl     :-
        rts
.endproc ; PrepShieldCursor

;;; Input: A,X = MGTK::MapInfo to shield (in window coords)
;;; Trashes $10, $12
.proc ShieldCursor
        ptr := $10
        pos := $12

        stax    ptr

        kCursorWidth    = 14
        kCursorHeight   = 12
        kSlop           = 14    ; Two DHR bytes worth of pixels

        ;; Left edge
        ldy     #MGTK::MapInfo::viewloc + MGTK::Point::xcoord
        sub16in (ptr),y, #kCursorWidth + kSlop, pos
        scmp16  shield_cursor_pos + MGTK::Point::xcoord, pos
        bmi     ret

        ;; Right edge
        ldy     #MGTK::MapInfo::maprect + MGTK::Rect::x2
        add16in (ptr),y, pos, pos
        add16_8  pos, #(kCursorWidth + kSlop) * 2
        scmp16  pos, shield_cursor_pos + MGTK::Point::xcoord
        bmi     ret

        ;; Top edge
        ldy     #MGTK::MapInfo::viewloc + MGTK::Point::ycoord
        sub16in (ptr),y, #kCursorHeight, pos
        scmp16  shield_cursor_pos + MGTK::Point::ycoord, pos
        bmi     ret

        ;; Bottom edge
        ldy     #MGTK::MapInfo::maprect + MGTK::Rect::y2
        add16in (ptr),y, pos, pos
        add16_8 pos, #kCursorHeight * 2
        scmp16  pos, shield_cursor_pos + MGTK::Point::ycoord
        bmi     ret

        inc     shield_cursor_count
        MGTK_CALL MGTK::HideCursor

ret:    rts
.endproc ; ShieldCursor

.proc UnShieldCursor
        lda     shield_cursor_count
        beq     ret
        dec     shield_cursor_count
        MGTK_CALL MGTK::ShowCursor
ret:    rts
.endproc ; UnShieldCursor
shield_cursor_count:    .byte 0
        DEFINE_POINT shield_cursor_pos, 0, 0
