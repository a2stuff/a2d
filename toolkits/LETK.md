# LineEdit ToolKit

This is an API library that uses the [MouseGraphics ToolKit](../mgtk/MGTK.md) to implement a "line edit" or text field control.

DeskTop originally had multiple copies of the code implementing similar functionality, tightly coupled to the application. The logic has been rewritten and enhanced, and moved into a library with an MLI-style interface, allowing the same code to service multiple instances without duplication.

Client code must define `LETKEntry` (referencing the instance's `letk::LETKEntry`) and can then use the `LETK_CALL` macro, with the typical call number / parameter address supplied. The code must be instantiated in the same memory bank as MGTK so it can make calls and reference resources directly.

> Desk Accessories running from Aux can define `LETKEntry := LETKAuxEntry` defined in desktop/desktop.inc.

## Concepts

### LineEditRecord
This defines the state of a control instance.
```
.byte       window_id       ID of the Winfo containing the control.
.addr       a_buf           Address of the text buffer.
MGTK:Rect   rect            Bounding rect of the control.
MGTK::Point pos             Text origin within the control.
.byte       max_length      Set to the maximum allowed length.

.byte       dirty_flag      Set when the control's value has changed.

.byte       active_flag     Internal: Set when the caret in the control should blink.
.byte       caret_pos       Internal: Position of the caret.
.byte       caret_flag      Internal: Set during the caret blink cycle while the caret is visible.
.word       caret_counter   Internal: counter for the caret blink cycle.
```

## Commands

### Init ($00)
Initialize internal LineEditRecord members.

Parameters:
```
.addr       a_record        Address of the LineEditRecord
```

### Idle ($01)
Call from event loop; blinks the caret.

Parameters:
```
.addr       a_record        Address of the LineEditRecord
```

### Activate ($02)
Moves caret to end and makes it visible.

Parameters:
```
.addr       a_record        Address of the LineEditRecord
```

NOTE: It is safe to call this more than once without calling `Deactivate`, e.g. to move caret to the end.

### Deactivate ($03)
Hide the caret.

Parameters:
```
.addr       a_record        Address of the LineEditRecord
```

### Click ($04)
Handle click within control bounds.

Mouse coordinates must be mapped from screen to window before calling.

Parameters:
```
.addr       record
.word       xcoord          Click x location (window coordinates)
.word       ycoord          Click y location (window coordinates)
```

### Key ($05)
Handle key press.

Non-printable (control) characters are used to move the caret and/or erase text:

* Delete key - delete character to left of caret.
* Control+F - delete character to right of caret.
* Control+X (or Clear key on IIgs) - clear all text.
* Left/Right Arrow - move caret one character to the left/right.
* Apple+Left/Right Arrow - move caret to the start/end of the text.

Printable characters ($20-$7E) are inserted at the caret position, if there is room in the buffer. The caller is responsible for filtering out undesired printables.

Also obscures the mouse cursor, i.e. it is hidden until moved.

Parameters:
```
.addr       record
.byte       key             From MGTK::Event::key
.byte       modifiers       From MGTK::Event::modifiers
```

### Update ($06)
Redraw the control. Useful after the control moves or the text changes.

Parameters:
```
.addr       a_record        Address of the LineEditRecord
```

## Convenience Macros

* `LETK_CALL` can be used to make calls in the form `LETK_CALL command, params`, if `LETKEntry` is defined.
* `DEFINE_LINE_EDIT` can be used to instantiate a record. Parameters are:
  * symbol (name) for the record
  * window ID
  * text buffer address
  * left, top, and width of the frame rect; this will be inset by 1px as a convenience
  * maximum length of the text
* `DEFINE_LINE_EDIT_PARAMS` can be used to instantiate a union-style parameter block. Callers can then pass this to LETK calls, populating additional fields for `Click` and `Key` calls. Parameters are:
  * symbol (name) for the parameter block
  * symbol (name) of the associated `LineEditRecord`

Example:
```
        DEFINE_LINE_EDIT line_edit_rec, kWindowId, buf_text, kLeft, kTop, kWidth, kMaxLength
        DEFINE_LINE_EDIT_PARAMS le_params, line_edit_rec
        ...
        LETK_CALL LETK::Init, le_params
```
