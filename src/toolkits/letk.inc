;;; ============================================================
;;; LineEdit ToolKit
;;; ============================================================

.scope LETK

.struct LineEditRecord

;;; --------------------------------------------------
;;; These fields are:
;;; * static for the life of the control
;;; * don't change within calls
;;; * are adjacent
;;; * order matters

;;; Window containing the control
window_id       .byte

;;; Address of the text buffer
a_buf           .addr

;;; Bounding rect of the control
rect            .tag    MGTK::Rect

;;; Set to the maximum length
max_length      .byte

;;; Options. bit7 = centered
options         .byte

;;; --------------------------------------------------

;;; Internal: Set when the caret in the control should blink.
active_flag     .byte
;;; Internal: Position of the caret.
caret_pos       .byte
;;; Internal: Set during the caret blink cycle while the caret is visible.
caret_flag      .byte
;;; Internal: counter for the caret blink cycle.
caret_counter   .word

.endstruct

kLineEditOptionsNormal   = %00000000
kLineEditOptionsCentered = %10000000

.macro DEFINE_LINE_EDIT name, winid, buf, left, top, width, maxlen, options_param
        WARN_IF_SHADOWING name
.params name
window_id:      .byte   winid
a_buf:          .addr   buf
        DEFINE_RECT_SZ rect, left+1, top+1, width-2, kTextBoxHeight-2
max_length:     .byte   maxlen
.if .paramcount > 7
options:        .byte   options_param
.else
options:        .byte   0
.endif
dirty_flag:     .byte   0
        .res    .sizeof(LETK::LineEditRecord) - (*-window_id)

        .refto window_id
        .refto a_buf
        .refto rect
        .refto max_length
        .refto options
        .refto dirty_flag

.endparams
.assert .sizeof(name) = .sizeof(LETK::LineEditRecord), error, "struct size"
.endmacro


;;; ============================================================

Init            = $00           ; Initialize LineEditRecord members
;;; .addr       record

Idle            = $01           ; Call from event loop; blinks caret
;;; .addr       record

Activate        = $02           ; Move caret to the end and shows it
;;; .addr       record

Deactivate      = $03           ; Hide caret
;;; .addr       record

Click           = $04           ; Handle click within control bounds
;;; .addr       record
;;; .word       xcoord          Click x location
;;; .word       ycoord          Click y location
;;; NOTE: Coordinates should be mapped from screen to window

Key             = $05           ; Handle key press
;;; .addr       record
;;; .byte       key             From MGTK::Event::key
;;; .byte       modifiers       From MGTK::Event::modifiers
;;; NOTE: Caller is responsible for filtering out undesired printables ($20-$7E)

Update          = $06           ; Redraw control, e.g. after control moves or text changes
;;; .addr       record

.endscope ; LETK

;;; ============================================================

.macro DEFINE_LINE_EDIT_PARAMS name, rec
        WARN_IF_SHADOWING name
.params name
record: .addr   rec
;;; For `LETK::Key` calls:
key       := * + 0
modifiers := * + 1
;;; For `LETK::Click` calls:
coords  := * + 0
xcoord  := * + 0
ycoord  := * + 2
        .res 4

        .refto record
        .refto key
        .refto modifiers
        .refto coords
        .refto xcoord
        .refto ycoord
.endparams
.endmacro

;;; ============================================================


;;; Scopes define their own LETKEntry identifiers
;;; This allows for helpers that e.g. bank switch before calling.
.macro LETK_CALL call, addr
        jsr     LETKEntry
        .byte   call
    .if .paramcount > 1
        .addr   addr
    .else
        .addr   0
    .endif
.endmacro
