;;; ============================================================
;;; Resources for line edit (text input) controls
;;; ============================================================

.scope line_edit_res

;;; Set when the IP in the control should blink.
blink_ip_flag:
        .byte   0

;;; Set for the maximum length
max_length:
        .byte   0

;;; Internal: Position of the insertion point
ip_pos:
        .byte   0

;;; Internal: counter for the IP blink cycle.
ip_counter:
        .word   1             ; immediately decremented to 0 and reset

;;; Internal: set during the IP blink cycle while the IP is visible.
ip_flag:
        .byte   0

;;; Set when the control's value has changed.
input_dirty_flag:
        .byte   0

;;; Internal: used to efficiently draw a character when typed.
str_1_char:
        PASCAL_STRING {0}

;;; Internal: used to clear the end of the string when a character is deleted.
str_2_spaces:
        PASCAL_STRING "  "

;;; Internal: MapInfo for setting a clipping rect
.params clip
        DEFINE_POINT viewloc, 0, 0
        .addr   MGTK::screen_mapbits
        .byte   MGTK::screen_mapwidth
        .byte   0               ; reserved
        DEFINE_RECT maprect, 0, 0, 0, 0
.endparams

.endscope
