# Icon ToolKit

This was written specifically for DeskTop (unlike the [MouseGraphics ToolKit](MGTK.md)), but is isolated from the rest of the application logic, depending only on MGTK.

* An internal table of icon number &rarr; IconEntry is maintained.
* An internal list of highlighted (selected) icons is maintained.
* Window-centric calls assume a GrafPort for the window is already the current GrafPort.

Definitions are in `icontk.inc`.

Client code must define `IconTKEntry` (referencing the instance's `icon_toolkit::IconTKEntry`) and can then use the `ITK_CALL` macro, with the typical call number / parameter address supplied. The code must be instantiated in the same memory bank as MGTK so it can make calls and reference resources directly.

The zero page addresses $06..$09 are preserved across calls.

> This is not exposed to Desk Accessories, although DeskTop does provide a jump table API to iterate over selected IconEntry records.

## Concepts

### IconEntry
This defines an icon instance.
```
.byte icon      icon index
.byte state     bits 0-5 = (unused)
                bit 6 = highlighted
                bit 7 = dimmed
.byte type/window_id
                bits 0-3 = window_id
                bit 4 = small icon
                bit 5 = not valid drop source flag (i.e. trash)
                bit 6 = drop target flag (trash, folder, dir)
                bit 7 = (unused)
.word iconx     (pixels)
.word icony     (pixels)
.type type      (type, mapped to IconResource)
.res  16        (length-prefixed name)
.byte record_num (index of icon in window)
```

### IconResource
This defines the visual appearance of an icon type.
```
;; First part is MGTK::MapInfo without leading viewloc
mapbits         .addr   ; address of bitmap bits
mapwidth        .byte   ; stride of bitmap bits
reserved        .byte   ; 0
maprect         .res 8  ; x1,y1 must be 0,0

;; Next part is address of mask bits; must be same
;; dimensions as icon.
maskbits        .addr
```

## Commands

Return value in A, 0=success.

### `IconTK::InitToolKit` ($00)

Initializes the tookit with key information about the client.

Parameters:
```
.byte       headersize
.addr       a_polybuf
.word       bufsize
.addr       a_typemap
```

* `headersize` is how much to vertically offset window ports to account for a header
* `a_polybuf` points to a scratch buffer safe to use when doing a modal drag operation; this is used to construct the outline polygon
* `bufsize` is the size of the above buffer
* `a_typemap` is a table mapping (via index) from `IconEntry::type` to `IconResource`

Since the buffer is only used during modal drag operations, it is safe to use the same "save area" given to MGTK, which is used only in modal menu operations. $D00 is enough for the maximum number of supported icons.

### `IconTK::AllocIcon` ($01)

Allocates an icon, returning the icon id and address of the `IconEntry`.

Parameters:
```
.byte       icon            (out) Icon number
.addr       entry           (out) Address of IconEntry
```

Note that it does not paint the icon. Callers must make a subsequent call to `IconTK::DrawIcon`, etc. `RemoveIcon` will de-allocate the icon.

### `IconTK::HighlightIcon` ($02)

Highlights (selects) an icon by number.

Parameters:
```
.byte       icon            Icon number
```

Note that it does not paint the icon. Callers must make a subsequent call to `IconTK::DrawIcon`, etc.

### `IconTK::DrawIconRaw` ($03)

Draws an icon by number. No clipping is done.

Parameters:
```
.byte       icon            Icon number
```

No error checking is done, no result codes.

The appropriate GrafPort must be selected, and the icons must be mapped into appropriate coordinates (i.e. mapped from screen space into window space). Icons are not clipped against overlapping windows. (See `IconTK::DrawIcon`)

Due to the lack clipping, this call is faster than `IconTK::DrawIcon`, and should be used if possible when multiple icons are being updated.


### `IconTK::RemoveIcon` ($04)

Removes an icon by number.

Parameters:
```
.byte       icon            Icon number
```

Note that it does not erase the icon. Callers must make a previous call to `IconTK::EraseIcon`.

Result codes (in A):
* 0 = success
* 1 = icon not found (`DEBUG` only)

### `IconTK::RemoveAll` ($05)

Removes all icons from specified window (0 = desktop). No redrawing is done.

Parameters:
```
.byte       window_id       Window ID, or 0 for desktop
```

Result codes (in A):
* 0 = success

### `IconTK::FindIcon` ($06)

Find the icon number at the given coordinates.

Parameters:
```
.word       mousex          Click x location (screen coordinates)
.word       mousey          Click y location (screen coordinates)
.byte       result          (out) icon number
.byte       window_id       Window (only matches icons in this window)
```

The `result` is set to 0 if no icon is found.

### `IconTK::DragHighlighted` ($07)

Initiates a drag of the highlighted icon(s).

Parameters:
```
.byte       param           (in) icon number; (out) target
.word       mousex          Click x location (screen coordinates)
.word       mousey          Click y location (screen coordinates)
.byte       fixed           High bit set if layout fixed (i.e. list view)
```

Call with set `param` to the specific icon being dragged, and the event mouse coordinates.

Result codes (in A):
* `kDragResultDrop` = 0 - drop on a target
* `kDragResultNotADrag` = 1 - not a drag; e.g. another click.
* `kDragResultMove` = 2 - icons moved within window/desktop; erased, caller should repaint.
* `kDragResultMoveModified` = 3 - icons moved within window/desktop but modifier down.
* `kDragResultCanceled` = 4 - operation cancelled, e.g. via keypress, drag to non-target, etc.

For `kDragResultDrop`, `kDragResultMove` and `kDragResultMoveModified`, `param` identifies the target:
* High bit clear if the drop target was an icon, and the low bits are the icon number.
* High bit set if the drop target was a window, and the low bits are the window number.

(For `kDragResultMove` and `kDragResultMoveModified` the target is implicitly the dragged icon's parent window, but set as a convenience for callers.)

### `IconTK::UnhighlightIcon` ($08)

Unhighlights (deselects) the specified icon.

Parameters:
```
.byte       icon            Icon number
```

Note that it does not paint the icon. Callers must make a subsequent call to `IconTK::DrawIcon`, etc.

### `IconTK::DrawAll` ($09)

Draws the icons in the selected window. No clipping is done.

Parameters:
```
.byte       window_id       Window ID, or 0 for desktop
```

For the desktop, this call should only be performed in response to an MGTK `update` event with `window_id` of 0, indicating that the desktop needs to be repainted. It assumes that overlapping windows will be repainted on top so no additional clipping is done beyond the active grafport.

For overlapping windows, the active grafport must be set up correctly to clip to the window's content area, excluding the header, scrollbars and grow box.

### `IconTK::IconInRect` ($0A)

Tests to see if the given icon (by number) overlaps the passed rect.

Parameters:
```
.byte       icon            Icon number
MGTK::Rect  bounds          Rect to test against
```

Result codes (in A):
* 0 = outside rect
* 1 = inside rect

### `IconTK::EraseIcon` ($0B)

Erases the specified icon by number. Any overlapping icons are redrawn.

Parameters:
```
.byte       icon            Icon number
```

No error checking is done, no result codes.

Note that unlike `IconTK::DrawIconRaw`, this call does _not_ require a GrafPort to be set by the caller. Icons in windows are clipped to the visible portion of the window (including overlapping windows). Icons on the desktop are clipped against overlapping windows.

### `IconTK::GetIconBounds` ($0C)

Populates the `bounds` rectangle with a bounding rect surrounding the icon bitmap and label.

Parameters:
```
.byte       icon            Icon number
MGTK::Rect  bounds          (out) Bounding rectangle
```

### `IconTK::DrawIcon` ($0D)

Redraws an icon by number, into any window (or the desktop), with appropriate clipping.

Parameters:
```
.byte       icon            Icon number
```

No error checking is done, no result codes.

Note that unlike `IconTK::DrawIconRaw`, this call does _not_ require a GrafPort to be set by the caller. Icons in windows are clipped to the visible portion of the window (including overlapping windows). Icons on the desktop are clipped against overlapping windows.

Due to the clipping, this call is slower than `IconTK::DrawIconRaw`, and should be avoided if possible when multiple icons are being updated.


### `IconTK::GetIconEntry` ($0E)

Given an icon number, returns the address of its `IconEntry` struct.

Parameters:
```
.byte       icon            Icon number
.addr       entry           (out) Address of IconEntry
```

No error checking is done, no result codes.


### `IconTK::GetRenameRect` ($0F)

Given an icon number, returns the maximum bounds of the name, used
for positioning a rename entry field.

Parameters:
```
.byte       icon            Icon number
MGTK::Rect  rect            (out) Bounding rect for name
```

No error checking is done, no result codes.


### `IconTK::GetBitmapRect` ($10)

Populates the `bounds` rectangle with a bounding rect surrounding just the icon bitmap.

Parameters:
```
.byte       icon            Icon number
MGTK::Rect  rect            (out) Bounding rect for bitmap
```

No error checking is done, no result codes.


## Convenience Macros

* `ITK_CALL` can be used to make calls in the form `ITK_CALL command, params`, if `ITKEntry` is defined.
* `DEFINE_ICON_RESOURCE` will produce an IconResource. Parameters are:
  * symbol (name) for the parameter block
  * icon bitmap
  * bitmap stride (in bytes)
  * bitmap width/height (in pixels)
  * mask bitmap
