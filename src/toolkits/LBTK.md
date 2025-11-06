# ListBox ToolKit

This is an API library that uses the [MouseGraphics ToolKit](../mgtk/MGTK.md) to implement a list box control.

DeskTop originally had multiple copies of the code implementing similar functionality, tightly coupled to the application. The logic has been rewritten and enhanced, and moved into a library with an MLI-style interface, allowing the same code to service multiple instances without duplication.

Client code must define `LBTKEntry` (referencing the instance's `lbtk::LBTKEntry`) and can then use the `LBTK_CALL` macro, with the typical call number / parameter address supplied. The code must be instantiated in the same memory bank as MGTK so it can make calls and reference resources directly.

> Desk Accessories running from Aux can define `LBTKEntry := LBTKAuxEntry` defined in desktop/desktop.inc.

## Concepts

### List Box Window

A list box control is implemented as a top-level, frameless window. The caller is required to do more work than controls like buttons or line edits. This includes:

* Defining a `Winfo` structure.
* Calling `MGTK::OpenWindow` to create the window.
* Calling `MGTK::CloseWindow` to destroy the window.

Events are delegated to the control using `LBTK::Click` and `LBTK::Key` commands.

List box windows are not expected to be moved or placed offscreen.

### ListBoxRecord
This defines the state of a list box control instance.
```
.addr       winfo           Winfo used by the list box.
.byte       num_rows        Number of rows visible in the list box.
.byte       num_items       Number of items in the list box.
.byte       selected_index  Selected index. ($FF = none)
.addr       draw_entry_proc Callback to draw an item (A = index, X,Y = addr of MGTK::Point)
.addr       on_sel_change   Callback when click or key changes selection.
.addr       on_no_change    Callback when click does not change selection.
MGTK::Point item_pos        Position when drawing item. Can be modified for columns.
```

#### Callbacks

The `draw_entry_proc` callback is invoked for each item whenever the list is redrawn, e.g. when `LBTK::Init` is called or a scroll event happens. `A` is populated with the item index; `X,Y` hold the address of an `MGTK::Point` representing the text position of the item. This is already set as the drawing position via `MGTK::MoveTo` so a basic implementation should just call `MGTK::DrawString` with the item string. A more elaborate implementation that e.g. displays multiple columns can use the position as the basis for its own `MGTK::MoveTo` calls. Note that the passed `MGTK::Point` must not be modified.

The `on_sel_change` callback is invoked whenever selection changes as a result of an `LBTK::Click` or `LBTK::Key` action. This is useful to update other UI elements in response to the selection. The new selection can be inspected via the `selected_index` record member. This will be $FF if no item is selected, e.g. if the user clicked on empty space within the list.

The `on_no_change` callback is invoked when an `LBTK::Click` action does *not* result in a selection change. This is useful if an action is performed in response to clicking an item, e.g. playing the sound associated with the current item.

Note that all of the callbacks must be valid procedures callable from the LBTK implementation. This implies:

* If the callback is not needed (e.g. `on_no_change`), provide the address of an `RTS` opcode.
* If the actual callback implementation resides in a different memory bank (e.g. Main) from the LBTK implementation (e.g. Aux), a relay routine must be provided that does the appropriate bank switching.

## Commands

### Init ($00)
Initialize and draw the List Box. The caller is responsible for previously calling `MGTK::OpenWindow` to create the list box's window.

This call can be made multiple times, e.g. if the contents are changed.

Parameters:
```
.addr       a_record        Address of the ListBoxRecord
```

### Click ($01)
Handle click within window.

In response to an `EventKind::button_down` event, the caller should identify the target window using `MGTK::FindWindow`. If the target is the list box's window, the caller should copy the unmapped coordinates (an `MGTK::Point`) from the event into the parameter block for this call.

Returns with N=0 if an item was clicked, N=1 otherwise.

Parameters:
```
.addr       a_record        Address of the ListBoxRecord
.word       xcoord          Click x location (screen coordinates)
.word       ycoord          Click y location (screen coordinates)
```

### Key ($02)
Handle key press.

In response to an `EventKind::key_down` event, the caller should inspect the `key` property of the event to determine if the key is `CHAR_UP` or `CHAR_DOWN`. If it is, the caller should copy the `key` and `modifiers` properties of the event into the parameter block for this call.

Parameters:
```
.addr       a_record        Address of the ListBoxRecord
.byte       key             From MGTK::Event::key
.byte       modifiers       From MGTK::Event::modifiers
```

### SetSelection ($03)
Set the selected index.

Note that no callbacks are invoked.

Parameters:
```
.addr       a_record        Address of the ListBoxRecord
.byte       new_selection   Index of new selection ($FF for none)
```

### SetSize ($04)
Set the number of items. Useful when dynamically populated, e.g. when enumerating files. Updates the scrollbar.

Parameters:
```
.addr       a_record        Address of the ListBoxRecord
.byte       new_size        Number of items.
```

## Convenience Macros

* `LBTK_CALL` can be used to make calls in the form `LBTK_CALL command, params`, if `LBTKEntry` is defined.
* `DEFINE_LIST_BOX_WINFO` can be used to instantiate a `Winfo` for the list box. Parameters are:
  * symbol (name) for the record
  * window id
  * left / top / width / height
  * pointer to font
* `DEFINE_LIST_BOX` can be used to instantiate a record. Parameters are:
  * symbol (name) for the record
  * pointer to `Winfo`
  * number of rows
  * number of items
  * callback proc to draw entry
  * callback proc when selection changes
  * callback proc if click results in no selection change
* `DEFINE_LIST_BOX_PARAMS` can be used to instantiate a union-style parameter block. Callers can then pass this to LBTK calls, populating additional fields for `Click` and `Key` calls. Parameters are:
  * symbol (name) for the parameter block
  * symbol (name) of the associated `ListBoxRecord`

Example:
```
        DEFINE_LIST_BOX_WINFO winfo_lb, kLBWinId, kLBLeft, kLBTop, kLBWidth, kLBHeight, FONT_ADDR
        DEFINE_LIST_BOX listbox_rec, winfo_lb, kListRows, kNumItems, DrawEntryProc, OnSelChange, OnNoChange
        DEFINE_LIST_BOX_PARAMS lb_params, listbox_rec
        ...
        LBTK_CALL LBTK::Init, lb_params
```
