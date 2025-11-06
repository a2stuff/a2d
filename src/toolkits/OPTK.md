# Option Picker ToolKit

This is an API library that uses the [MouseGraphics ToolKit](../mgtk/MGTK.md) to implement an option picker control. The options are arranged in a grid with a fixed number of rows and columns.

DeskTop originally had multiple copies of the code implementing similar functionality, tightly coupled to the application. The logic has been rewritten and enhanced, and moved into a library with an MLI-style interface, allowing the same code to service multiple instances without duplication.

Client code must define `OPTKEntry` (referencing the instance's `optk::OPTKEntry`) and can then use the `OPTK_CALL` macro, with the typical call number / parameter address supplied. The code must be instantiated in the same memory bank as MGTK so it can make calls and reference resources directly.

> Desk Accessories running from Aux can define `OPTKEntry := OPTKAuxEntry` defined in desktop/desktop.inc.

## Concepts

The control supports sparse population - not every grid location needs to be a valid entry, and the entries are not required to be contiguous. When referring to entries by index, the layout is column-major.

### OptionPickerRecord

This defines the state of a control instance.
```
.byte       window_id       ID of the Winfo containing the control.
.word       left            Left edge (window coords).
.word       top             Top edge (window coords).
.byte       num_rows        Number of rows in the grid.
.byte       num_cols        Number of columns in the grid.
.byte       item_width      Item width.
.byte       item_height     Item height.
.byte       hoffset         Item label horizontal offset.
.byte       voffset         Item label vertical offset.
.byte       selected_index  Selected index, or $FF if none.
.addr       is_entry_proc   Callback to validate an item (A=index, return N=0 if valid).
.addr       draw_entry_proc Callback to draw an item (A=index).
.addr       on_sel_change   Called when `selected_index` has changed.
```

#### Callbacks

The `is_entry_proc` callback is invoked to determine if the entry exists, when drawing or responding to input events. `A` is populated with the index (column-major). The callback must return `N=0` if the entry exists, `N=1` if it does not.

The `draw_entry_proc` callback is invoked for each entry when whenever the control is redrawn, e.g. when `OPTK::Draw` or `OPTK::Update` is called. `A` is populated with the item index. The draw position assuming a simple text label is already set as the drawing position via `MGTK::MoveTo` so a basic implementation should just call `MGTK::DrawString` with the item string.

The `on_sel_change` callback is invoked whenever selection changes as a result of an `OPTK::Click` or `OPTK::Key` action. This is useful to update other UI elements in response to the selection. The new selection can be inspected via the `selected_index` record member. This will be $FF if no item is selected, e.g. if the user clicked on empty space within the control.

Note that all of the callbacks must be valid procedures callable from the OPTK implementation. If the actual callback implementation resides in a different memory bank (e.g. Main) from the OPTK implementation (e.g. Aux), a relay routine must be provided that does the appropriate bank switching.

## Commands

### Draw ($00)
Draw the Option Picker.

Parameters:
```
.addr       a_record        Address of the OptionPickerRecord
```

### Draw ($00)
Draw the Option Picker.

Parameters:
```
.addr       a_record        Address of the OptionPickerRecord
```

The control's window GrafPort is selected before any drawing is performed. When processing update events, use `Update` instead.

### Update ($01)

Draw the option picker. This should be used when processing update events i.e. between `MGTK::BeginUpdate` and `MGTK::EndUpdate` calls. The current GrafPort is used.

Parameters:
```
.addr       a_record        Address of the OptionPickerRecord
```

### Click ($02)

In response to an `EventKind::button_down` event, the caller should identify the target window using `MGTK::FindWindow`. Assuming it is the containing window, the caller should map the coordinates (using `MGTK::ScreenToWindow`). If it is not targeted at another control, copy the mapped coordinates (an `MGTK::Point`) into the parameter block for this call.

The `is_entry_callback` will be invoked to determine if the target is a valid entry. The `sel_change_callback` will be invoked if selection changes, with `selected_index` updated.

Returns with N=0 if an item was clicked, N=1 otherwise.

Parameters:
```
.addr       a_record        Address of the OptionPickerRecord
.word       xcoord          Click x location (window coordinates)
.word       ycoord          Click y location (window coordinates)
```

### Key ($03)
Handle key press.

In response to an `EventKind::key_down` event, the caller should inspect the `key` property of the event to determine if the key is `CHAR_UP`, `CHAR_DOWN`, `CHAR_LEFT` or `CHAR_RIGHT`. If it is, the caller should copy the `key`` property of the event into the parameter block for this call.

The `is_entry_callback` will be invoked (multiple times if necessary) to determine the new selection. The `sel_change_callback` will be invoked if selection changes, with `selected_index` updated.

Parameters:
```
.addr       a_record        Address of the OptionPickerRecord
.byte       key             From MGTK::Event::key
```

### SetSelection ($04)
Set the selected index.

Note that no callbacks are invoked.

Parameters:
```
.addr       a_record        Address of the OptionPickerRecord
.byte       new_selection   Index of new selection ($FF for none)
```

## Convenience Macros

* `OPTK_CALL` can be used to make calls in the form `OPTK_CALL command, params`, if `OPTKEntry` is defined.
* `DEFINE_OPTION_PICKER` can be used to instantiate a record. Parameters are:
  * symbol (name) for the record
  * window id
  * left offset (within window)
  * top offset (within window)
  * number of rows
  * number of items
  * item width (pixels)
  * item height (pixels)
  * horizontal offset from entry top-left to label position
  * vertical offset from entry top-left to label position
  * callback proc to validate entry
  * callback proc to draw entry
  * callback proc when selection changes
* `DEFINE_OPTION_PICKER_PARAMS` can be used to instantiate a union-style parameter block. Callers can then pass this to OPTK calls, populating additional fields for `Click` and `Key` calls. Parameters are:
  * symbol (name) for the parameter block
  * symbol (name) of the associated `OptionPickerRecord`

Example:
```
        DEFINE_OPTION_PICKER options_record, kWindowId, kLeft, kTop, kNumRows, kNumCols, kItemWidth, kItemHeight, kHOffset, kVOffset, IsEntryProc, DrawEntryProc, OnSelChange
        DEFINE_OPTION_PICKER_PARAMS options_params, options_record
        ...
        OPTK_CALL OPTK::Draw, options_params
```
