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

;;; Text origin within the control
pos             .tag    MGTK::Point     ; TODO: Derive from rect?

;;; Set to the maximum length
max_length      .byte

;;; --------------------------------------------------

;;; Set when the IP in the control should blink.
blink_ip_flag   .byte

;;; Set when the control's value has changed.
dirty_flag      .byte

;;; --------------------------------------------------

;;; Internal: Position of the insertion point
ip_pos          .byte
;;; Internal: set during the IP blink cycle while the IP is visible.
ip_flag         .byte
;;; Internal: counter for the IP blink cycle.
ip_counter      .word

.endstruct

;;; ============================================================

Init            = $00           ; Initialize LineEditRecord members
;;; .addr       record

Idle            = $01           ; Call from event loop; blinks IP
;;; .addr       record

Activate        = $02           ; Repaint control, show IP, moves IP to end
;;; .addr       record

Deactivate      = $03           ; Hide IP
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

.endscope ; LETK

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
