;;; ============================================================
;;; ListBox ToolKit
;;; ============================================================

.scope LBTK

.struct ListBoxRecord
winfo           .addr            ; +$00 pointer to Winfo of list contrl
num_rows        .byte            ; +$02 number of visible rows in the list
num_items       .byte            ; +$03 number of items in the list
selected_index  .byte            ; +$04 selected index, or $FF if none
draw_entry_proc .addr            ; +$05 called to draw an item (A=index)
on_sel_change   .addr            ; +$07 called when `selected_index` has changed
on_no_change    .addr            ; +$09 called on click when `selected_index` has not changed
.endstruct                       ; length = $0B

;;; Macro for defining a `ListBoxRecord`
.macro DEFINE_LIST_BOX name, _winfo, _num_rows, _num_items, _draw_entry_proc, _on_sel_change, _on_no_change
        WARN_IF_SHADOWING name
.params name
winfo:          .addr   _winfo
num_rows:       .byte   _num_rows
num_items:      .byte   _num_items
selected_index: .byte   $FF
draw_entry_proc:.addr   _draw_entry_proc
on_sel_change:  .addr   _on_sel_change
on_no_change:   .addr   _on_no_change

        .refto winfo
        .refto num_rows
        .refto num_items
        .refto selected_index
        .refto draw_entry_proc
        .refto on_sel_change
        .refto on_no_change

.endparams
.assert .sizeof(name) = .sizeof(LBTK::ListBoxRecord), error, "struct size"
.endmacro

;;; ============================================================
;;; Calls

Init            = $00
;;; .addr       record

Click           = $01
;;; .addr       record
;;; .word       xcoord          Click x location
;;; .word       ycoord          Click y location
;;; NOTE: Coordinates should be unmapped (i.e. screen)

Key             = $02
;;; .addr       record
;;; .byte       key             From MGTK::Event::key
;;; .byte       modifiers       From MGTK::Event::modifiers
;;; NOTE: Only CHAR_UP and CHAR_DOWN should be passed

SetSelection    = $03
;;; .addr       record
;;; .byte       new_selection

SetSize         = $04
;;; .addr       record
;;; .byte       new_size

.endscope ; LBTK

;;; ============================================================

.struct ListBoxParams
record          .addr
.union

.struct ; Click
.union
coords          .tag MGTK::Point
.struct
xcoord          .word
ycoord          .word
.endstruct
.endunion
.endstruct

.struct ; Key
key             .byte
modifiers       .byte
.endstruct

.struct ; SetSelection
new_selection   .byte
.endstruct

.struct ; SetSize
new_size        .byte
.endstruct

.endunion
.endstruct

;;; ============================================================

;;; Macro for defining a call parameter block for a specific record
.macro DEFINE_LIST_BOX_PARAMS name, _record
        WARN_IF_SHADOWING name
.params name
record: .addr   _record

;;; For `LBTK::SetSelection` calls:
new_selection := name + ListBoxParams::new_selection
;;; For `LBTK::SetSize` calls:
new_size      := name + ListBoxParams::new_size
;;; For `LBTK::Key` calls:
key           := name + ListBoxParams::key
modifiers     := name + ListBoxParams::modifiers
;;; For `LBTK::Click` calls:
coords        := name + ListBoxParams::coords
xcoord        := name + ListBoxParams::xcoord
ycoord        := name + ListBoxParams::ycoord

        .res .sizeof(ListBoxParams) - 2

        .refto record
        .refto new_selection
        .refto new_size
        .refto key
        .refto modifiers
        .refto coords
        .refto xcoord
        .refto ycoord
.endparams
.endmacro

;;; ============================================================

;;; Macro for defining a list box's window
.macro DEFINE_LIST_BOX_WINFO name, id, left, top, width, height, font
        WARN_IF_SHADOWING name
.params name
window_id:      .byte   id
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_normal
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   0
mincontheight:  .word   0
maxcontwidth:   .word   0
maxcontheight:  .word   0
port:
        DEFINE_POINT viewloc, left, top
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, width, height
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   font
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams
.endmacro

;;; ============================================================

;;; Scopes define their own LBTKEntry identifiers
;;; This allows for helpers that e.g. bank switch before calling.
.macro LBTK_CALL call, addr, label
        jsr     LBTKEntry
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


