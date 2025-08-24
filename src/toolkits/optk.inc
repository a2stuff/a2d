.scope OPTK

.struct OptionPickerRecord
window_id       .byte            ; +$00 window containg the control
left            .word            ; +$01 left edge (window coords)
top             .word            ; +$03 top edge (window coords)
num_rows        .byte            ; +$05 number of rows in the grid
num_cols        .byte            ; +$06 number of columns in the grid
item_width      .byte            ; +$07 item width
item_height     .byte            ; +$08 item height
hoffset         .byte            ; +$09 item label horizontal offset
voffset         .byte            ; +$0A item label vertical offset
selected_index  .byte            ; +$0B selected index, or $FF if none
is_entry_proc   .addr            ; +$0C called to draw an item (A=index)
draw_entry_proc .addr            ; +$0E called to draw an item (A=index)
on_sel_change   .addr            ; +$10 called when `selected_index` has changed
.endstruct                       ; length = $12
ASSERT_EQUALS .sizeof(OptionPickerRecord), $12

.macro DEFINE_OPTION_PICKER name, _window_id, _left, _top, _num_rows, _num_cols, _item_width, _item_height, _hoffset, _voffset, _is_entry_proc, _draw_entry_proc, _on_sel_change
        WARN_IF_SHADOWING name
.params name
window_id:      .byte   _window_id
left:           .word   _left
top:            .word   _top
num_rows:       .byte   _num_rows
num_cols:       .byte   _num_cols
item_width:     .byte   _item_width
item_height:    .byte   _item_height
hoffset:        .byte   _hoffset
voffset:        .byte   _voffset
selected_index: .byte   $FF
is_entry_proc:  .addr   _is_entry_proc
draw_entry_proc:.addr   _draw_entry_proc
on_sel_change:  .addr   _on_sel_change

        .refto window_id
        .refto left
        .refto top
        .refto num_rows
        .refto num_cols
        .refto item_width
        .refto item_height
        .refto hoffset
        .refto voffset
        .refto selected_index
        .refto is_entry_proc
        .refto draw_entry_proc
        .refto on_sel_change

.endparams
.assert .sizeof(name) = .sizeof(OPTK::OptionPickerRecord), error, "struct size"
.endmacro

;;; ============================================================

Draw            = $00
;;; .addr       record

Update          = $01
;;; .addr       record

Click           = $02
;;; .addr       record
;;; .word       xcoord          Click x location
;;; .word       ycoord          Click y location
;;; NOTE: Coordinates should be mapped (i.e. window)

Key             = $03
;;; .addr       record
;;; .byte       key             From MGTK::Event::key
;;; NOTE: Only CHAR_UP/CHAR_DOWN/CHAR_LEFT/CHAR_RIGHT should be passed

SetSelection    = $04
;;; .addr       record
;;; .byte       new_selection

.endscope ; OPTK

;;; ============================================================

.macro DEFINE_OPTION_PICKER_PARAMS name, _record
        WARN_IF_SHADOWING name
.params name
record: .addr   _record
;;; For `OPTK::SetSelection` calls:
new_selection := *+0
;;; For `OPTK::Key` calls:
key           := *+0
;;; For `OPTK::Click` calls:
coords        := *+0
xcoord        := *+0
ycoord        := *+2

        .res 4

        .refto record
        .refto new_selection
        .refto key
        .refto coords
        .refto xcoord
        .refto ycoord
.endparams
.endmacro

;;; ============================================================

;;; Scopes define their own OPTKEntry identifiers
;;; This allows for helpers that e.g. bank switch before calling.
.macro OPTK_CALL call, addr, label
        jsr     OPTKEntry
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
