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
.byte state     bit 0 = allocated
                bit 6 = highlighted
.byte type/window_id
                bits 0-3 = window_id
                bit 4 = unused
                bit 5 = not valid drop source flag (i.e. trash)
                bit 6 = drop target flag (trash, folder, dir)
                bit 7 = open flag
.word iconx     (pixels)
.word icony     (pixels)
.addr iconbits  (addr of IconResource)
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
```

* `headersize` is how much to vertically offset window ports to account for a header
* `a_polybuf` points to a scratch buffer safe to use when doing a modal drag operation; this is used to construct the outline polygon
* `bufsize` is the size of the above buffer

Since the buffer is only used during modal drag operations, it is safe to use the same "save area" given to MGTK, which is used only in modal menu operations. $D00 is enough for the maximum number of supported icons.

### `IconTK::AddIcon` ($01)

Inserts an icon record into the table.

Parameters: address of `IconEntry`

Note that it does not paint the icon. Callers must make a subsequent call to `IconTK::DrawIcon` with an appropriate GrafPort selected. This is because the window may be obscured, so the state change can occur but the paint can not.

Result codes (in A):
* 0 = success
* 1 = icon id already in use

### `IconTK::HighlightIcon` ($02)

Highlights (selects) an icon by number.

Parameters:
```
.byte       icon            Icon number
```

Note that it does not repaint the icon. Callers must make a subsequent call to `IconTK::DrawIcon` with an appropriate GrafPort selected. This is because the window may be obscured, so the state change can occur but the paint can not.

Result codes (in A):
* 0 = success
* 2 = invalid icon
* 3 = already highlighted

### `IconTK::DrawIcon` ($03)

Redraws an icon by number.

Parameters:
```
.byte       icon            Icon number
```

For windowed icons, the appropriate GrafPort must be selected, and the icons must be mapped into appropriate coordinates (i.e. mapped from screen space into window space). Windowed icons are not clipped, so must only be drawn during an update call or into the active window.

For desktop icons, the icon is clipped against any open windows.

Result codes (in A):
* 0 = success
* 1 = icon not found

### `IconTK::RemoveIcon` ($04)

Removes an icon by number.

Parameters:
```
.byte       icon            Icon number
```

Note that it does not erase the icon. Callers must make a previous call to `IconTK::EraseIcon` with an appropriate GrafPort selected. This is because the window may be obscured, so the state change can occur but the paint can not.

Result codes (in A):
* 0 = success
* 1 = icon not found

### `IconTK::RemoveAll` ($05)

Removes all icons from specified window (0 = desktop). No redrawing is done.

Parameters:
```
.byte       window_id       Window ID, or 0 for desktop
```

Result codes (in A):
* 0 = success

### `IconTK::CloseWindow` ($06)

Removes all icons from specified window (0 = desktop). No redrawing is done.

Parameters:
```
.byte       window_id       Window ID, or 0 for desktop
```

Result codes (in A):
* 0 = success

### `IconTK::FindIcon` ($07)

Find the icon number at the given coordinates.

Parameters:
```
.word       mousex          Click x location (screen coordinates)
.word       mousey          Click y location (screen coordinates)
.byte       result          (out) icon number
.byte       window_id       Window (only matches icons in this window)
```

The `result` is set to 0 if no icon is found.

### `IconTK::DragHighlighted` ($08)

Initiates a drag of the highlighted icon(s).

Parameters:
```
.byte       param           (in) icon number; (out) result
.word       mousex          Click x location (screen coordinates)
.word       mousey          Click y location (screen coordinates)
```

Call with set `param` to the specific icon being dragged, and the event mouse coordinates.

If successful, the `param` will be:

* 0 if the drop was just a move, i.e. dragging icons within a window or within the desktop.
* High bit clear if the drop target was an icon, and the low bits are the icon number.
* High bit set if the drop target was a window, and the low bits are the window number.

Result codes (in A):
* 0 = success
* 2 = non-drag event seen
* 3 = no selection

### `IconTK::UnhighlightIcon` ($09)

Unhighlights (deselects) the specified icon.

Parameters:
```
.byte       icon            Icon number
```

Note that it does not repaint the icon. Callers must make a subsequent call to `IconTK::DrawIcon` with an appropriate GrafPort selected. This is because the window may be obscured, so the state change can occur but the paint can not.

Result codes (in A):
* 0 = success
* 2 = invalid icon
* 3 = icon not highlighted

### `IconTK::RedrawDesktopIcons` ($0A)

Redraws the icons on the desktop (mounted volumes, trash).

Parameters: none (pass $0000 as address)

This call should be performed in response to an MGTK `update` event with `window_id` of 0, indicating that the desktop needs to be repainted. It assumes that overlapping windows will be repainted on top so no additional clipping is done beyond the active grafport.

### `IconTK::IconInRect` ($0B)

Tests to see if the given icon (by number) overlaps the passed rect.

Parameters:
```
.byte       icon            Icon number
MGTK::Rect  bounds          Rect to test against
```

Result codes (in A):
* 0 = outside rect
* 1 = inside rect

### `IconTK::EraseIcon` ($0C)

Erases the specified icon by number.

Parameters:
```
.byte       icon            Icon number
```

No error checking is done. If the icon is in a window, it must be in the active window.

Note that unlike `DrawIcon`, this call does _not_ require a GrafPort to be set by the caller. For icons in a window, the active window's GrafPort bounds (including scroll position and subtracting DeskTop's window header) will automatically be taken into account.

For desktop icons, the icon is clipped against any open windows.

## Convenience Macros

* `ITK_CALL` can be used to make calls in the form `ITK_CALL command, params`, if `ITKEntry` is defined.
* `DEFINE_ICON_RESOURCE` will produce an IconResource. Parameters are:
  * symbol (name) for the parameter block
  * icon bitmap
  * bitmap stride (in bytes)
  * bitmap width/height (in pixels)
  * mask bitmap
