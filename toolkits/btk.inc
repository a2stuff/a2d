;;; ============================================================
;;; Button ToolKit
;;; ============================================================

.scope BTK

.struct ButtonRecord

;;; --------------------------------------------------
;;; These fields are:
;;; * don't change within calls
;;; * are adjacent
;;; * order matters

;;; Window containing the control
window_id       .byte

;;; Address of the label string
a_label         .addr

;;; Bounding rect of the control
rect            .tag    MGTK::Rect

;;; State
state           .byte

.endstruct

.macro DEFINE_BUTTON name, winid, label, left, top, width, height
.params name
window_id:      .byte   winid
a_label:        .addr   str_label
.if     .paramcount = 7
        DEFINE_RECT_SZ rect, (left), (top), (width), (height)
.elseif .paramcount = 6
        DEFINE_RECT_SZ rect, (left), (top), (width), kButtonHeight
.else
        DEFINE_RECT_SZ rect, (left), (top), kButtonWidth, kButtonHeight
.endif
state:          .byte   0
        .res    .sizeof(BTK::ButtonRecord) - (*-window_id)
        ;; TODO: Use a string pool for these, somehow
str_label:      PASCAL_STRING label
.endparams
.endmacro

;;; ============================================================

Draw            = $00           ; Draw button
;;; .addr       record

Flash           = $01           ; Flash button
;;; .addr       record

Hilite          = $02           ; Redraw label (after state change)
;;; .addr       record

Track           = $03           ; Handle click within control bounds
;;; .addr       record

.endscope ; BTK

.macro DEFINE_BUTTON_PARAMS name, rec
.params name
record: .addr   rec
.endparams
.endmacro

;;; ============================================================

;;; Scopes define their own BTKEntry identifiers
;;; This allows for helpers that e.g. bank switch before calling.
.macro BTK_CALL call, addr
        jsr     BTKEntry
        .byte   call
    .if .paramcount > 1
        .addr   addr
    .else
        .addr   0
    .endif
.endmacro
