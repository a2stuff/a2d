# Button ToolKit

This is an API library that uses the [MouseGraphics ToolKit](../mgtk/MGTK.md) to implement a button control.

DeskTop originally had multiple copies of the code implementing similar functionality, tightly coupled to the application. The logic has been rewritten and enhanced, and moved into a library with an MLI-style interface, allowing the same code to service multiple instances without duplication.

Client code must define `BTKEntry` (referencing the instance's `btk::BTKEntry`) and can then use the `BTK_CALL` macro, with the typical call number / parameter address supplied. The code must be instantiated in the same memory bank as MGTK so it can make calls and reference resources directly.

> Desk Accessories running from Aux can define `BTKEntry := BTKAuxEntry` defined in desktop/desktop.inc.

NOTE: Define `BTK_SHORT = 1` before including the toolkit to omit support for Radio and Checkbox controls, which reduces the binary size.

## Concepts

### ButtonRecord
This defines the state of a control instance.
```
.byte       window_id       ID of the Winfo containing the control.
.addr       a_label         Address of the button label.
.addr       a_shortcut      Address of the button shortcut label, null if none).
MGTK:Rect   rect            Bounding rect of the control.
.byte       state           Button state. bit7 = disabled (or checked, if radio/checkbox).
```

If `window_id` is set to 0 then (1) the port is never set to the window's port and (2) event coordinates are not mapped to the window's space. This can be used for buttons drawn directly to the screen port, e.g. alerts.

## Commands

The parameter for every call is just the address of the `ButtonRecord`.

### Draw ($00)
Draw the button, including frame and label, considering the disable state.

If the `window_id` is no-zero, the control's window GrafPort is selected before any drawing is performed. When processing update events, use `Update` instead.


### Update ($01)
Draw the button, including frame and label, considering the disable state.

This should only be used when processing update events i.e. between `MGTK::BeginUpdate` and `MGTK::EndUpdate` calls. The current GrafPort is used.


### Flash ($02)
Flash the button label (if enabled). Used after a keypress. Returns with N=0/Z=1 normally, but N=1/Z=0 if disabled.

### Hilite ($03)
Redraw the control label, considering the disable state.


### Track ($04)
Start a nested event loop tracking after a click is initiated in the control. Returns with N=0/Z=1 if clicked, N=1/Z=0 if cancelled (or disabled).


### RadioDraw ($05)
Draw a radio button.


The high bit of the `ButtonRecord::state` signifies whether or not the button is checked.

The shortcut is ignored. After the call, the `ButtonRecord::rect` is updated to the bounding box of the button and (if not null) the label. This can be used for later hit testing.


### RadioUpdate ($06)
Update the bitmap of a radio button.

The high bit of the `ButtonRecord::state` signifies whether or not the button is checked.


### CheckboxDraw ($07)
Draw a checkbox button.

The high bit of the `ButtonRecord::state` signifies whether or not the button is checked.

The shortcut is ignored. After the call, the `ButtonRecord::rect` is updated to the bounding box of the button and (if not null) the label. This can be used for later hit testing.


### CheckboxUpdate ($08)
Update the bitmap of a checkbox button.

The high bit of the `ButtonRecord::state` signifies whether or not the button is checked.


## Convenience Macros

* `BTK_CALL` can be used to make calls in the form `BTK_CALL command, params`, if `BTKEntry` is defined.
* `DEFINE_BUTTON` can be used to instantiate a record. Parameters are:
  * symbol (name) for the record
  * window ID
  * label string
  * shortcut string (blank if none)
  * left, top, width (optional), and height (optional)

Example:
```
        DEFINE_BUTTON my_button, kWindowId, "Press Me", kLeft, kTop ; default width/height
        ...
        BTK_CALL BTK::Draw, my_button
```
