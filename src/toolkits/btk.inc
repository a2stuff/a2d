;;; ============================================================
;;; Button ToolKit
;;; ============================================================

.scope BTK

.struct ButtonRecord

;;; --------------------------------------------------
;;; These fields:
;;; * don't change within calls
;;; * are adjacent
;;; * order matters

;;; Window containing the control (0 for desktop)
window_id       .byte

;;; Address of the label string
a_label         .addr

;;; Address of the shortcut string (null if none)
a_shortcut      .addr

;;; Bounding rect of the control
rect            .tag    MGTK::Rect

;;; State
state           .byte

.endstruct

kButtonStateNormal   = %00000000
kButtonStateDisabled = %10000000 ; push buttons
kButtonStateChecked  = %10000000 ; checkboxes/radio buttons

;;; Macro for defining a `ButtonRecord`
.macro DEFINE_BUTTON name, winid, label, shortcut, left, top, width, height
        WARN_IF_SHADOWING name
.params name
window_id:      .byte   winid

.local str_label
.local str_shortcut

.ifnblank label
a_label:        .addr   str_label
.else
a_label:        .addr   0
.endif

.ifnblank shortcut
a_shortcut:     .addr   str_shortcut
.else
a_shortcut:     .addr   0
.endif


.if     .paramcount = 8
        DEFINE_RECT_SZ rect, (left), (top), (width), (height)
.elseif .paramcount = 7
        DEFINE_RECT_SZ rect, (left), (top), (width), kButtonHeight
.else
        DEFINE_RECT_SZ rect, (left), (top), kButtonWidth, kButtonHeight
.endif

state:          .byte   0

        .refto window_id
        .refto a_label
        .refto a_shortcut
        .refto rect
        .refto state
.endparams
.assert .sizeof(name) = .sizeof(BTK::ButtonRecord), error, "struct size"

        ;; TODO: Use a string pool for these, somehow
.ifnblank label
str_label:      PASCAL_STRING {label}
.endif
.ifnblank shortcut
str_shortcut:   PASCAL_STRING {shortcut}
.endif
.endmacro

;;; ============================================================
;;; Calls

Draw            = $00           ; Draw button
;;; .addr       record

Update          = $01           ; Draw button (during update event)
;;; .addr       record

Flash           = $02           ; Flash button
;;; .addr       record

Hilite          = $03           ; Redraw label (after state change)
;;; .addr       record

Track           = $04           ; Handle click within control bounds
;;; .addr       record

.ifndef BTK_SHORT
RadioDraw       = $05           ; Draw a radio button (and update hit rect)
;;; .addr       record

RadioUpdate     = $06           ; Update a radio button after a click
;;; .addr       record

CheckboxDraw    = $07           ; Draw a checkbox button (and update hit rect)
;;; .addr       record

CheckboxUpdate  = $08           ; Update a checkbox button after a click
;;; .addr       record

kRadioButtonWidth       = 15
kRadioButtonHeight      = 7

kCheckboxWidth       = 17
kCheckboxHeight      = 8

.endif

.endscope ; BTK

;;; ============================================================

;;; Scopes define their own BTKEntry identifiers
;;; This allows for helpers that e.g. bank switch before calling.
.macro BTK_CALL call, addr, label
        jsr     BTKEntry
        .byte   call

    .if .paramcount > 2
        label := *
    .endif

    .if .paramcount > 1
        .addr   addr
    .else
        .addr   0
    .endif
.endmacro
