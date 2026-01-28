# MouseGraphics ToolKit

This is a complex API library written by Apple circa 1985. The Apple Programmers and Developers Association (APDA) documentation can be found at:

* [Graphics Primitives](https://drive.google.com/open?id=1YqdtxkMlzEebU5HxL6sOv6PhhddSLhHe)
* [Mouse Graphics Tool Kit](https://drive.google.com/open?id=1EHjwyu77FJAjNhAt8DwMxBhAdUL0RKMM)

> Changes from this documentation are called out below.

---

The Graphics Primitives are likely originally authored by Bill Budge, based on his _The Graphics Page_ series in Softalk magazine:
* [Debut: The Graphics Page](https://archive.org/details/softalkv4n02oct1983) (Oct 1983)
* [De-Wozzing the Apple II](https://archive.org/details/softalkv4n03nov1983) (Nov 1983)
* [Facts of the Apple's hi-res screen](https://archive.org/details/softalkv4n04dec1983) (Dec 1983)
* [Budge's Graphics Zone, HLine](https://archive.org/details/softalkv4n06feb1984) (Feb 1984)
* [Pretzel Logic: HLine, swatches, SetPattern](https://archive.org/details/softalkv4n07mar1984) (Mar 1984)
* [Hi-res clipping and windowing](https://archive.org/details/softalkv4n08apr1984) (Apr 1984)
* [Cartesian square dancing](https://archive.org/details/softalkv4n10jun1984) (Jun 1984)

---

* [Graphics Primitives](#graphics-primitives) - screen management, lines, rects, polys, text, patterns, pens
  * [Concepts](#concepts)
  * [Commands](#commands)
* [Mouse Graphics](#mouse-graphics) - windows, menus, events, cursors
  * [Concepts](#concepts-1)
  * [Commands](#commands-1)
* [Creating Applications and DeskTop Desk Accessories](#creating-applications-and-desktop-desk-accessories)

For the purposes of DeskTop, the entry point is fixed at $4000 AUX, called MLI-style:
```
    JSR $4000
    .byte call
    .addr params
```
Result will be in A, with Z bit set, 0 indicating success (so `BNE error` works).

ca65 syntax is used for primitives: `.byte`, `.word` (interpreted as 16-bit signed integer), `.addr` (16-bit address), `.res N` (N byte buffer)

---

# Graphics Primitives

## Concepts

### Point
```
.word       xcoord
.word       ycoord
```

### Rect
```
.word       x1
.word       y1
.word       x2
.word       y2
```
or equivalently:
```
Point       topleft
Point       bottomright
```

### Pattern
A simple repeating 8x8 pattern is defined by 8 bytes. All bits of each byte are used.
```
.byte       row0
.byte       row1
.byte       row2
.byte       row3
.byte       row4
.byte       row5
.byte       row6
.byte       row7
```

### MapInfo
Used with GrafPorts to define offsets/clipping, and bitmaps for source data.
```
Point       viewloc
.addr       mapbits         $2000 for the screen, or bitmap bits
.byte       mapwidth        $80, or stride for bitmap
.byte       reserved
Rect        maprect         a.k.a. cliprect
```

### GrafPort
There is always a current GrafPort (or "port" for short) that defines
the destination and pen state of drawing operations.
```
MapInfo     portmap
Pattern     penpattern
.byte       colormask_and
.byte       colormask_or
Point       penloc
.byte       penwidth        horizontal pen thickness
.byte       penheight       vertical pen thickness
.byte       penmode
.byte       textback        text background
.addr       textfont
```

### PolyList
```
.byte       count           number of vertices in this polygon
.byte       last            high bit set if there are more polygons
Point       vertex0
... repeats for each vertex
... repeats for each polygon
```

### Font
This is a MousePaint-compatible font. Single- and double-width fonts are
supported; max height is 16 pixels.
```
.byte       fonttype        0=regular, $80=double-width
.byte       lastchar        char code of last character (usually $7F)
.byte       height          pixels (1-16)
.res N      charwidth       pixels, for each char
.res N      row0            bits
.res N      row0right       bits (double-width only)
... repeats for each row
```

## Commands

#### NoOp ($00)
No-op

No parameters.

### Initialization

#### InitGraf ($01)
No parameters.

#### SetSwitches ($02)
Configure display switches

Parameters:
```
 .byte       flags           bit 0=hires, 1=page2, 2=mixed, 3=text
```

### GrafPort - assign, update, query ports

#### InitPort ($03)
Initialize GrafPort to standard values

Parameters:
```
(input is address of GrafPort record)
```

#### SetPort ($04)
Set current port as specified

Parameters:
```
(input is address of GrafPort record)
```

#### GetPort ($05)
Get pointer to current port

Parameters:
```
.addr       port            (out)
```

This also copies the current GrafPort data from the zero page to the current port. When `SetZP1` has been called to disable preserving the zero page, it is necessary to call this manually to retain the GrafPort state.

#### SetPortBits ($06)
Set just the mapinfo (viewloc, mapbits) of the current grafport.

Parameters:
```
(input is address of MapInfo record)
```

#### SetPenMode ($07)
Set the pen mode of the current grafport.

Parameters:
```
.byte       mode            pen*/notpen*
```

Pen modes are:
* 0 = pencopy
* 1 = penOR
* 2 = penXOR
* 3 = penBIC
* 4 = notpencopy
* 5 = notpenOR
* 6 = notpenXOR
* 7 = notpenBIC

#### SetPattern ($08)
Set the pattern of the current grafport.

Parameters:
```
.res 8      pattern         8x8 pixel pattern for PaintRect calls
```

#### SetColorMasks ($09)
Set the color masks of the current grafport.

Parameters:
```
.byte       and_mask
.byte       or_mask
```

These flags are primarily for controlling the high bit of bytes on the double-hires graphics screen, which is useful for certain RGB cards.

#### SetPenSize ($0A)
Set the pen size of the current grafport.

Parameters:
```
.byte       penwidth        horizontal pen thickness
.byte       penheight       vertical pen thickness
```

#### SetFont ($0B)
Set the font of the current grafport.

Parameters:
```
.addr       textfont        font definition
```

#### SetTextBG ($0C)
Set the text background of the current grafport. Text is drawn in the inverse of this color.

Parameters:
```
.byte       backcolor       0=black, $7F=white
```

### Drawing - draw lines; frame, fill, and test rects and polys

#### Move ($0D)
Set pen location (relative) of the current grafport.

Parameters:
```
.word       xdelta
.word       ydelta
```

#### MoveTo ($0E)
Set pen location (absolute) of the current grafport.

Parameters:
```
Point        pos
```

#### Line ($0F)
Draw line from pen location (relative) of the current grafport.

Parameters:
```
.word       xdelta
.word       ydelta
```

This call normally auto-hides the cursor.

#### LineTo ($10)
Draw line from pen location (absolute) of the current grafport.

Parameters:
```
Point       pos
```

This call normally auto-hides the cursor.

#### PaintRect ($11)
Fill rectangle with pattern of the current grafport.

Parameters:
```
Rect        rect
```

This call normally auto-hides the cursor.

#### FrameRect ($12)
Draw rectangle with pen mode/size of the current grafport.

Parameters:
```
Rect        rect
```

This call normally auto-hides the cursor.

#### InRect ($13)
Is current position in bounds? A=$80 true, 0 false

Parameters:
```
Rect        rect
```

#### PaintBits ($14)
Draw bitmap.

Parameters:
```
(input is address of MapInfo record)
```

This call normally auto-hides the cursor.

> It is a modern change that this call auto-hides the cursor.

#### PaintPoly ($15)
Fill multiple closed polygons with the pattern of the current grafport.

Parameters:
```
(input is address of PolyList record)
```

This call normally auto-hides the cursor.

#### FramePoly ($16)
Draw multiple closed polygons with the pen mode/size of the current grafport.

Parameters:
```
(input is address of PolyList record)
```

This call normally auto-hides the cursor.

#### InPoly ($17)
Is pen location of the current grafport within the polygon? A=$80 true, 0 false

Parameters:
```
(input is address of PolyList record)
```

### Text - draw and measure text

#### TextWidth ($18)
Measure the width of a string in pixels

Parameters:
```
.addr       data
.byte       length
.word       width           (out) result in pixels
```

#### DrawText ($19)
Draw string at the pen location of the current graphport (as left, baseline)

Parameters:
```
.addr       data
.byte       length
```

This call normally auto-hides the cursor.

#### StringWidth ($5C)
Measure the width of a Pascal string in pixels

Parameters:
```
.addr       str             Address of Pascal string
.word       width           (out) result in pixels
```

#### DrawString ($5D)
Draw string at the pen location of the current graphport (as left, baseline)

Parameters:
```
(input is the address of Pascal string)
```

This call normally auto-hides the cursor.

### Utility - configuration and version

#### SetZP1 ($1A)
Configure usage of upper ($80-$FF) zero page by the API (speed vs. convenience)

If high bit is set (the default), part of the zero page is preserved across all MGTK calls. This is convenient for callers, at the expense of performance.

If the high bit is clear, MGTK assumes that the caller will not modify this part of the zero page.

Parameters:
```
.byte       preserve        $00=stash/no auto restore; $80=restore now and onward
```

When zero page preservation is turned on (the default), the active GrafPort is automatically updated after each call, and so changes made by calls (e.g. `SetPenMode`) will be retained when the port is re-selected in the future.

If zero page preservation is turned off, the active GrafPort will not be updated by calls. In this mode, the application may force the active GrafPort to be updated by calling `GetPort`.

#### SetZP2 ($1B)
Configure usage of lower ($00-$43) zero page by the API (speed vs. convenience)

If high bit is set (the default), part of the zero page is preserved across `DrawText` calls. This is convenient for callers, at the expense of performance.

If the high bit is clear, MGTK assumes that the caller will not modify this part of the zero page.

Parameters:
```
.byte       preserve        $00=stash/no auto restore; $80=restore now and onward
```

#### Version ($1C)
Get toolkit version

Parameters:
```
.byte       (out) major
.byte       (out) minor
.byte       (out) patch
.byte       (out) status
.word       (out) number
```

---

# Mouse Graphics

## Mouse Keys

* To enter Mouse Keys mode, hold down both the Open-Apple key and the Solid-Apple (Option) key and then press <kbd>Space</kbd>. A confirmation sound will play.
* While in Mouse Keys mode, use these keys:
  * <kbd>←</kbd> <kbd>↑</kbd> <kbd>→</kbd> <kbd>↓</kbd> (Arrow keys) move the mouse cursor
  * <kbd>Space</kbd> click the mouse button
  * <kbd>,</kbd> press and hold the mouse button
  * <kbd>.</kbd> release the mouse button
* To exit Mouse Keys mode, press <kbd>Esc</kbd>. A confirmation sound will play.

> Earlier versions of the toolkit used different key sequences to enter, exit, and control the mouse.

## Concepts

### Cursor
```
.res 24     bitmap          2x12 byte bitmap (XOR'd after mask)
.res 24     mask            2x12 byte mask (OR'd with screen)
.byte       hotx            hotspot coords (pixels)
.byte       hoty
```

### Event
```
.byte       kind            MGTK::EventKind::*
.res 4
```
if `kind` is `MGTK::EventKind::key_down`:
```
.byte       kind            MGTK::EventKind::*
.byte       key             (ASCII code; high bit clear)
.byte       modifiers       (0=none, 1=open-apple, 2=solid-apple, 3=both)
.res 2      reserved
```
if `kind` is `MGTK::EventKind::update:`
```
.byte       kind            MGTK::EventKind::*
.byte       window_id       (0=desktop)
.res 3      reserved
```
otherwise:
```
.byte       kind            MGTK::EventKind::*
.word       mousex
.word       mousey
```

```
MGTK::EventKind::no_event        = 0    ; No mouse or keypress
MGTK::EventKind::button_down     = 1    ; Mouse button was depressed
MGTK::EventKind::button_up       = 2    ; Mouse button was released
MGTK::EventKind::key_down        = 3    ; Key was pressed
MGTK::EventKind::drag            = 4    ; Mouse button still down
MGTK::EventKind::apple_key       = 5    ; Mouse button was depressed, modifier key down
MGTK::EventKind::update          = 6    ; Desktop/window update needed

event_modifier_open_apple  = 1 << 0
event_modifier_solid_apple = 1 << 1
```

### Menu

Menu Bar record:
```
.word       count           Number of menu bar items

.byte       menu_id         Menu identifier
.byte       disabled        Flag
.addr       title           Address of length-prefixed string
.addr       menu            Address of Menu record
.res 6      reserved        Reserved
... repeats for each menu
```

Menu record:
```
.word       count           Number of items in menu
.res  5     reserved        Reserved

.byte       options         bit 0=OA, 1=SA, 2=mark, 5=check, 6=filler, 7=disabled
.byte       mark_char       Custom mark character if mark option set
.byte       char1           ASCII code of shortcut #1 (e.g. uppercase B); MGTK::no_shortcut if none
.byte       char2           ASCII code of shortcut #2 (e.g. lowercase b, or same); MGTK::no_shortcut if none
.addr       name            Address of length-prefixed string
... repeats for each menu item
```

Since 0 is typeable character (Control+Shift+2 a.k.a. ^@, ASCII `NUL`), a byte with the high bit set signals "no shortcut".
```
MGTK::no_shortcut = $FF
```

### Window "winfo"
```
.byte       id
.byte       options         MGTK::Option::*
.addr       title
.byte       hscroll         MGTK::Scroll::option_*
.byte       vscroll         MGTK::Scroll::option_*
.byte       hthumbmax
.byte       hthumbpos
.byte       vthumbmax
.byte       vthumbpos
.byte       status
.byte       reserved
.word       mincontwidth    minimum content size (horizontal)
.word       mincontlength   minimum content size (vertical)
.word       maxcontwidth    maximum content size (horizontal)
.word       maxcontlength   maximum content size (vertical)
GrafPort    windowport      GrafPort record
.addr       nextwinfo       address of next lower window in stack
```

Windows have a _content area_ which has the requested dimensions. Above this is an optional
_title bar_ which in turn has an optional _close box_. Within the content area are an
optional _resize box_ and optional _scroll bars_.

```
MGTK::Option::dialog_box       = 1 << 0
MGTK::Option::go_away_box      = 1 << 1
MGTK::Option::grow_box         = 1 << 2

MGTK::Scroll::option_none      = 0
MGTK::Scroll::option_present   = 1 << 7
MGTK::Scroll::option_thumb     = 1 << 6
MGTK::Scroll::option_active    = 1 << 0
MGTK::Scroll::option_normal    = option_present | option_thumb | option_active
```
## Commands

### Initialization

#### StartDeskTop ($1D)
Inits state, registers interrupt handler, draws desktop

Parameters:
```
.byte       machine         ROM FBB3 ($06 = IIe or later)
.byte       subid           ROM FBC0 ($EA = IIe, $E0 = IIe enh/IIgs, $00 = IIc/IIc+)
.byte       op_sys          0=ProDOS, 1=Pascal
.byte       slot_num:       Mouse slot, 0 = search (will be filled in)
.byte       use_interrupts  0=passive, 1=interrupt
.addr       sysfontptr
.addr       savearea        buffer for saving screen data (e.g. behind menus)
.word       savesize        bytes
```

#### StopDeskTop ($1E)
Deallocates interrupt, hides cursor

No parameters.

#### SetUserHook ($1F)

Parameters:
```
.byte       hook_id         0=before, 1=after event checking
.addr       routine_ptr     0=remove hook_id
```

#### AttachDriver ($20)
Install pointer driver; A=0 on success, $95 if mouse disabled

Parameters:
```
.addr       hook            Mouse hook routine to install
.addr       mouse_state     (out) Address of mouse state (.word x, y; .byte status)
```

#### ScaleMouse ($21)
Set mouse/screen scaling

Parameters:
```
.byte       x_exponent      x-scale factor for mouse, 0...3
.byte       y_exponent      y-scale factor for mouse, 0...3
```

#### KeyboardMouse ($22)
Next operation (`DragWindow` or `GrowWindow`) will be performed by keyboard

No parameters.

#### GetIntHandler ($23)
Get address of interrupt handler

Parameters:
```
.addr       handler         (out) Address of interrupt handler (after `CLD`)
```

> This call is not present in the 1985 APDA documentation. All subsequent call numbers are offset by one.

#### GetDeskPat ($4E)
Get address of desktop pattern.

Parameters:
```
.addr       pattern         (out) 8x8 pixel pattern
```

> This call is a modern addition, so is not present in the 1985 APDA documentation.

#### SetDeskPat ($4F)
Set new desktop pattern. Note that this does NOT redraw anything.
Applications can use `RedrawDeskTop` to force a redraw.

Parameters:
```
.res 8      pattern         8x8 pixel pattern
```

> This call is a modern addition, so is not present in the 1985 APDA documentation.

#### RedrawDeskTop ($52)
Redraws the desktop background, and posts update events for the desktop and all
windows.

No parameters.

> This call is a modern addition, so is not present in the 1985 APDA documentation.

### Cursor Manager - set, show, hide

#### SetCursor ($24)
Set cursor definition.

This forces the cursor visible, resetting any outstanding `HideCursor` calls.

Parameters:
```
(input is address of Cursor record)
```

Instead of an address, one of the `MGTK::SystemCursor::*` enum values can be passed instead: `pointer`, `ibeam`, or `watch`.

> The SystemCursor enum support is a modern addition, so is not present in the 1985 APDA documentation.

#### ShowCursor ($25)
Return cursor to visibility.

No parameters.

#### HideCursor ($26)
Cursor hidden until `ShowCursor` call.

No parameters.

#### ObscureCursor ($27)
Cursor hidden until moved.

No parameters.

#### GetCursorAdr ($28)
Get cursor definition

Parameters:
```
.addr definition            (out) Address of cursor record
```

#### ShieldCursor ($5A)
Conditionally hide the cursor.

Parameters:
```
(input is address of MapInfo record)
```

If the cursor would overlap with the offset/rectangle described by the passed `Rect`, offset by the current `GrafPort`, the cursor is hidden.

Calls to `ShieldCursor` must be balanced by a corresponding `UnshieldCursor` call. Between the `ShieldCursor` and `UnshieldCursor` calls, drawing calls do not auto-hide the cursor. This can be used to reduce the flickering of the cursor during drawing.

Calls to `ShieldCursor` can be nested; each call will hide the cursor if needed, and the cursor will only be shown once the final corresponding `UnshieldCursor` call is made. Nesting `ShieldCursor`/`UnshieldCursor` within `HideCursor`/`ShowCursor` or vice versa is supported as well.

> This call is a modern addition, so is not present in the 1985 APDA documentation.

#### UnshieldCursor ($5B)
Balance a previous call to `UnshieldCursor`.

No parameters.

> This call is a modern addition, so is not present in the 1985 APDA documentation.

### Event Manager - get, peek, post

#### CheckEvents ($29)
Process mouse/kbd if `GetEvent` will be delayed.

No parameters.

#### GetEvent ($2A)
Return the next event from the queue.

Parameters:
```
(parameter is address of Event record)
```

_DA specific:_

* Call `JUMP_TABLE_YIELD_LOOP` to allow DeskTop to do periodic tasks.

#### FlushEvents ($2B)
Drop any pending events from the queue.

No parameters.

#### PeekEvent ($2C)
Observe the next event in the queue, without removing it.

`EventKind::no_event` signals that there was no event in the queue.

Parameters:
```
(parameter is address of Event record)
```

#### PostEvent ($2D)
Post event to queue.

Parameters:
```
(parameter is address of Event record)
```

#### SetKeyEvent ($2E)
If set, keypresses are ignored by Tool Kit

Parameters:
```
.byte       handle_keys     high bit set = ignore keyboard, otherwise check
```

### Menu Manager - configure, enable, disable, select

#### InitMenu ($2F)
Configure characters used for menu glyphs. Optional. The defaults
are open=$1F, solid=$1E, check=$1D, control=$01.

Parameters:
```
.byte       open_char       char code to use for open apple glyph
.byte       solid_char      char code to use for solid apple glyph
.byte       check_char      char code to use for checkmark glyph
.byte       control_char    char code to use for control key glyph
```

> The 1985 APDA documentation defines a `inactive_char` parameter, but this was removed.

#### SetMenu ($30)
Configure (and draw) menu

Parameters:
```
(input is address of Menu Bar record)
```

#### MenuSelect ($31)
Enter modal loop for handling mouse-down on menu bar

Parameters:
```
.byte       menu_id         (out) Top level menu identifier, or 0 if none
.byte       menu_item       (out) Index (1-based) of item in menu, or 0 if none
```

#### MenuKey ($32)
Find menu item corresponding to keypress

Parameters:
```
.byte       menu_id         (out)
.byte       menu_item       (out)
.byte       which_key
.byte       key_mods        bit 0=OA, bit 1=SA
```

#### HiliteMenu ($33)
Toggle highlight state of menu

Parameters:
```
.byte       menu_id
```

#### DisableMenu ($34)
Disable/enable a menu. Effectively disables all items, but individual disable/enable states are restored when re-enabled.

Parameters:
```
.byte       menu_id
.byte       disable         0=enable, 1=disable
```

#### DisableItem ($35)
Disable/enable a specific item in a menu.

Parameters:
```
.byte       menu_id
.byte       menu_item
.byte       disable         0=enable, 1=disable
```

#### CheckItem ($36)
Sets a specific menu item as checked.

Parameters:
```
.byte       menu_id
.byte       menu_item
.byte       check           0=unchecked, 1=checked
```

#### SetMark ($37)
Sets a specific menu item as using a distinct mark character when checked.

Parameters:
```
.byte       menu_id
.byte       menu_item
.byte       set_char        0=use checkmark, 1=use mark_char
.byte       mark_char       char code to use for mark
```

#### DrawMenuBar ($50)
Redraws the current menu bar. Useful after full-screen operations.
Note that hilite state of menu bar items is not restored; this must
be done by a manual call to `HiliteMenu`

No parameters.

> This call is a modern addition, so is not present in the 1985 APDA documentation.

#### FlashMenuBar ($54)
Negates (XOR) the pixels of the menu bar. Useful for silent alerts.
This should be called an even number of times before another MGTK call
is made so the menu bar is left in a normal state.

No parameters.

> This call is a modern addition, so is not present in the 1985 APDA documentation.

### Window Manager - open, close, drag, grow, update

#### OpenWindow ($38)

Parameters:
```
(input is address of WInfo record)
```

#### CloseWindow ($39)

Parameters:
```
.byte window_id
```

#### CloseAll ($3A)

No parameters.

#### GetWinPtr ($3B)
Get pointer to window params by id; A=0 on success

Parameters:
```
.byte       window_id
.addr       window_ptr      (out) winfo address
```

#### GetWinPort ($3C)
Populate GrafPort with current drawing state of window, clipped if the window is partially offscreen.

Parameters:
```
.byte       window_id
.addr       port            address of GrafPort to populate
```

Returns `Error::window_obscured` if the content area of the window is completely offscreen and drawing must be skipped. (The port rect will be invalid.)

#### SetWinPort ($3D)
Update port of window

Parameters:
```
.byte       window_id
.addr       port            GrafPort to copy from
```

#### BeginUpdate ($3E)
Respond to update event for desktop/window

Parameters:
```
.byte       window_id       0 if desktop
```

Returns `Error::window_obscured` if the content area of the window is completely offscreen and drawing should be skipped. (The port rect will be invalid.)

> Update events with `window_id` of 0 are a modern addition, and not present in the 1985 APDA documentation. They are added to support redrawing onto the desktop itself, e.g. volume icons.

#### EndUpdate ($3F)

No parameters.

#### FindWindow ($40)

Parameters:
```
.word       mousex          screen coordinates
.word       mousey
.byte       which_area      (out) MGTK::Area::*
.byte       window_id       (out) of window
```

#### FrontWindow ($41)
Get id of top window

Parameters:
```
.byte       window_id       (out) window, or 0 if none
```

#### SelectWindow ($42)
Make window topmost

Parameters:
```
.byte       window_id
```

#### TrackGoAway ($43)

Parameters:
```
.byte       clicked         (out) 0 = canceled, 1 = close
```

#### DragWindow ($44)

Parameters:
```
.byte       window_id
.word       dragx           mouse coords
.word       dragy
.byte       moved           (out) high bit set if moved, clear if not
```

> The 1986 APDA documentation specified that the `moved` parameter has values of 1 for yes, 0 for no. The implementation uses the high bit instead.

#### GrowWindow ($45)

Parameters:
```
.byte       window_id
.word       mousex
.word       mousey
.byte       itgrew          (out) high bit set if resized, clear if not
```

> The 1986 APDA documentation specified that the `itgrew` parameter has values of 1 for yes, 0 for now. The implementation uses the high bit instead.

#### ScreenToWindow ($46)
Map screen coords to content coords

Parameters:
```
.byte       window_id
.word       screenx
.word       screeny
.word       windowx         (out)
.word       windowy         (out)
```

#### WindowToScreen ($47)
Map content coords to screen coords

Parameters:
```
.byte       window_id
.word       windowx
.word       windowy
.word       screenx         (out)
.word       screeny         (out)
```

#### GetWinFrameRect ($51)
Get the rectangle framing a window. This is in screen coordinates,
and is the same rectangle that would be drawn for grow or move
operations.

Parameters:
```
.byte       window_id
Rect        rect            (out)
```

> This call is a modern addition, so is not present in the 1985 APDA documentation.

### Control Manager - scrollbars

#### FindControl ($48)

Parameters:
```
.word       mousex
.word       mousey
.byte       which_ctl       (out) MGTK::Ctl::*
.byte       which_part      (out) MGTK::Part::*
```

#### FindControlEx ($53)
Like `FindControl`, but works on all windows, not just the topmost window.

Parameters:
```
.word       mousex
.word       mousey
.byte       which_ctl       (out) MGTK::Ctl::*
.byte       which_part      (out) MGTK::Part::*
.byte       window_id
```

> This call is a modern addition, so is not present in the 1985 APDA documentation.

#### SetCtlMax ($49)

Parameters:
```
.byte       which_ctl       MGTK::Ctl::*_scroll_bar
.byte       ctlmax          maximum value
```

#### TrackThumb ($4A)

Parameters:
```
.byte       which_ctl       MGTK::Ctl::*_scroll_bar
.word       mousex
.word       mousey
.byte       thumbpos        (out) 0...255
.byte       thumbmobed      (out) 0 = no change, 1 = moved
```

#### UpdateThumb ($4B)

Parameters:
```
.byte       which_ctl       MGTK::Ctl::*_scroll_bar
.byte       thumbpos        new position 0...250
```

#### ActivateCtl ($4C)
Activate/deactivate scroll bar

Parameters:
```
.byte       which_ctl       MGTK::Ctl::*_scroll_bar
.byte       activate        0=deactivate, 1=activate
```

### Miscellaneous

#### BitBlt ($4D)
Lower level (and screen-only?) than PaintBits.

> Further documentation is needed.

Parameters:
```
(input is address of MapInfo record)
```

> This call was not listed in the 1985 APDA documentation, so the behavior is inferred from the source.

#### SaveScreenRect ($55)
Save the passed screen rectangle to the save area.

Parameters:
```
Rect        rect
```

This exposes the logic used to save the bits behind a menu, allowing
for quickly restoring. This can be used to implement pop-ups, alerts,
or other modal effects without requiring underlying windows to update.

Note that no error checking is done that the passed rect is valid or
that the save area passed to `StartDeskTop` is large enough.

This call normally auto-hides the cursor.

> This call is a modern addition, so is not present in the 1985 APDA documentation.

#### RestoreScreenRect ($56)
Restore the passed screen rectangle from the save area.

Parameters:
```
Rect        rect
```

This must only be used following a `SaveScreenRect` call and must be
passed the same rectangle dimensions. No error checking is done.

This call normally auto-hides the cursor.

> This call is a modern addition, so is not present in the 1985 APDA documentation.

#### InflateRect ($57)
Expand the referenced rectangle by `xdelta` and `ydelta`, which can be negative.

Parameters:
```
.addr       rect            Address of MGTK::Rect
.word       xdelta          pixels
.word       ydelta          pixels
```

> This call is a modern addition, so is not present in the 1985 APDA documentation.

#### UnionRects ($58)
Expand the second rectangle to encompass the first rectangle.

Parameters:
```
.addr       rect1           Address of MGTK::Rect. No modified
.addr       rect2           Address of MGTK::Rect. Expanded if needed.
```

> This call is a modern addition, so is not present in the 1985 APDA documentation.

#### MulDiv ($59)
Multiplies two 16-bit values and then divides the 32-bit result by a
third 16-bit value, yielding a 16-bit result and a 16-bit remainder.

Parameters:
```
.word       number          (in)
.word       numerator       (in)
.word       denominator     (in)
.word       result          (out)
.word       remainder       (out)
```

This operation is commonly used for scaling, for example setting a
scroll bar thumb position based on the viewport offset or vice versa,
or calculating a progress bar's position. By using a denominator or
numerator of 1 this can be used for simple multiplication or division,
respectively.

Note that if the result does not fit into 16 bits, the output is
undefined.

> This call is a modern addition, so is not present in the 1985 APDA documentation.

#### WaitVBL ($5E)
Wait for the start of the video blanking interval, if supported on the system.

No parameters.

This can be used to roughly time animations, assuming the system (or
emulator) correctly reports vertical blank (VBL) at 60Hz (NTSC) or
50Hz (PAL). On systems that do not correctly support VBL it will
return immediately.

Note that MGTK calls are generally too slow to use this to avoid
"tearing" while painting.

> This call is a modern addition, so is not present in the 1985 APDA documentation.

# Creating Applications and DeskTop Desk Accessories

### Application Use

_Notes specific to DeskTop Desk Accessories (DA) are included where usage differs._

#### Initialization

* `SetZP1` (optional)
* `StartDeskTop`
* `InitMenu` (if necessary; the defaults are sensible)
* `SetMenu`
* Run main loop until quit
* `StopDeskTop`

#### Main Loop

* Call a `SystemTask`-equivalent function provided by the app to do periodic tasks.
* `GetEvent`
* If `MGTK::EventKind::button_down` or `MGTK::EventKind::apple_key`:
   * `FindWindow` to figure out what was clicked
   * If `MGTK::Area::desktop` - ignore
   * If `MGTK::Area::menubar` - [handle menu](#handle-menu)
   * If `MGTK::Area::dragbar` - [handle window drag](#handle-window-drag)
   * If `MGTK::Area::grow_box` - [handle window resize](#handle-window-resize)
   * If `MGTK::Area::close_box` - [handle window close](#handle-window-close)
   * If `MGTK::Area::content`:
     * `FindControl`
     * If `MGTK::Ctl::*_scroll_bar` - [handle scrolling](#handle-scrolling)
     * If `MGTK::Ctl::dead_zone` - ignore
     * If `MGTK::Ctl::not_a_control`:
       * If not topmost:
         * `SelectWindow`
       * Otherwise, handle content click per app
* If `MGTK::EventKind::key_down` - [handle key](#handle-key)
* If `MGTK::EventKind::drag`:
  * TODO
* If `MGTK::EventKind::update`:
   * If `window_id` is 0, draw any desktop details into clipped port
   * Otherwise, draw contents of `window_id` into clipped port

_DA specific:_

* Call `JUMP_TABLE_SYSTEM_TASK` to allow DeskTop to handle periodic tasks such as updating the clock.

#### Redraw window

* `GetWinPort` - populate a local GrafPort with an appropriately clipped port
* if `Error::window_obscured` is returned, abort these steps (port will be invalid)
* `SetPort` - make it current
* optional: `HideCursor` - if multiple drawing calls will be made
* ... draw ...
* optional: `ShowCursor` - if it was hidden above
* optional: `SetWinPort` - save changed attributes (penpos, etc) if desired

#### Handle Key

* `MenuKey`
* If `menu_id` is not 0:
  * Dispatch for `menu_id` and `menu_item`
  * `HiliteMenu` to toggle state back off when done
* Otherwise:
  * handle key press per app

_DA specific: Menus are not supported in DAs, so the first steps here can be skipped._

#### Handle Menu

* `MenuSelect` to initiate menu modal loop
* If `menu_id` is 0, done
* Dispatch for `menu_id` and `menu_item`
* `HiliteMenu` to toggle state back off when done

_DA specific: Menus are not supported in DAs._

#### Handle Window Drag

* `SelectWindow` to make topmost if necessary
* `DragWindow` to initiate drag modal loop
* If `moved` is true:
  * [Handle update events](#handle-update-events)
  * [Redraw](#redraw-window) window content if not moved and was made topmost.

_DA specific:_

* Call `JUMP_TABLE_CLEAR_UPDATES` to allow DeskTop to handle update events. This will not redraw the DA window, however.
* [Redraw](#redraw-window) DA window content

#### Handle Window Close

* `TrackGoAway` to initiate modal close loop
* If canceled - done
* `CloseWindow`

_DA specific:_

* Call `JUMP_TABLE_CLEAR_UPDATES` to allow DeskTop to handle update events.

#### Handle Scrolling

* If `MGTK::Part::thumb`:
  * `TrackThumb` to initiate modal scroll loop
  * If thumb did not move - done
  * [Redraw](#redraw-window) window content
  * `UpdateThumb`
* If `MGTK::Part::page_*`:
  * Scroll by a "page"
  * [Redraw](#redraw-window) window content
  * `UpdateThumb`
* If `MGTK::Part::*_arrow`:
  * Scroll by a "line"
  * [Redraw](#redraw-window) window content
  * `UpdateThumb`

#### Handle Window Resize

* `GrowWindow` to initiate modal resize loop
* If `itgrew` is true:
  * `UpdateThumb` if needed to adjust scroll bars
  * [Handle update events](#handle-update-events)
  * [Redraw](#redraw-window) window content

_DA specific:_

* Call `JUMP_TABLE_CLEAR_UPDATES` to allow DeskTop to handle update events. This will not redraw the DA window, however.
* [Redraw](#redraw-window) DA window content

#### Handle Update Events

* Repeat:
  * `PeekEvent`
  * If not `MGTK::EventKind::update` - exit these steps
  * Otherwise:
    * `GetEvent`
    * `BeginUpdate`
    * If error, continue
    * Otherwise:
      * If `window_id` is 0, redraw any desktop content (e.g. icons)
      * Otherwise, [redraw](#redraw-window) `window_id`'s content
      * `EndUpdate`

_DA specific:_

* Following a window move, resize or close, call `JUMP_TABLE_CLEAR_UPDATES` to allow DeskTop to handle update events. This will not redraw the DA window, however.

