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

.byte       blink_ip_flag   Set when the IP in the control should blink.
.byte       dirty_flag      Set when the control's value has changed.

.byte       ip_pos          Internal: Position of the insertion point
.byte       ip_flag         Internal: set during the IP blink cycle while the IP is visible.
.word       ip_counter      Internal: counter for the IP blink cycle.
```

## Commands

### Init ($00)
Initialize internal LineEditRecord members.

Parameters:
```
.addr       record          Address of the LineEditRecord
```

### Idle ($01)
Call from event loop; blinks the insertion point.

Parameters:
```
.addr       record          Address of the LineEditRecord
```

### Activate ($02)
Repaint control, show IP, moves IP to end.

Parameters:
```
.addr       record          Address of the LineEditRecord
```

### Deactivate ($03)
Hide the IP.

Parameters:
```
.addr       record          Address of the LineEditRecord
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

Non-printable (control) characters are used to move the IP and/or erase text:

* Delete key - delete character to left of IP.
* Control+F - delete character to right of IP.
* Control+X (or Clear key on IIgs) - clear all text.
* Left/Right Arrow - move IP one character to the left/right.
* Apple+Left/Right Arrow - move IP to the start/end of the text.

Printable characters ($20-$7E) are inserted at the IP position, if there is room in the buffer. The caller is responsible for filtering out undesired printables.

Also obscures the mouse cursor, i.e. it is hidden until moved.

Parameters:
```
.addr       record
.byte       key             From MGTK::Event::key
.byte       modifiers       From MGTK::Event::modifiers
```
