# MGTK API

This is a complex API library written by Apple circa 1985. It consists of:

* Graphics Primitives - screen management, lines, rects, polys, text, patterns, pens
* Mouse Graphics - windows, menus, events, cursors

For the purposes of DeskTop, the entry point is fixed at $4000 AUX, called MLI-style (JSR followed by command type and address of param block).

---

# Graphics Primitives

## Concepts

ca65 syntax is used for primitives: `.byte`, `.word` (interpreted as 16-bit signed integer), `.addr` (16-bit address), `.res N` (N byte buffer)

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
.word       y3
```

### Pattern
A simple repeating 8x8 _pattern_ is defined by 8 bytes. All bits of each byte are used.

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
.res 8      penpattern
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

Includes:

* Initialization
* GrafPort - assign, update, query ports
* Drawing - draw lines; frame, fill, and test rects and polys
* Text - draw and measure text
* Utility - configuration and version

---

# Mouse Graphics

Includes:

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
.byte       kind            event_kind_*
.res 4
```
if `kind` is `event_kind_key_down`:
```
.byte       kind            event_kind_*
.byte       key             (ASCII code; high bit clear)
.byte       modifiers       (0=none, 1=open-apple, 2=solid-apple, 3=both)
.res 2      reserved
```
if `kind` is `event_kind_update:`
```
.byte       kind            event_kind_*
.byte       window_id
.res 3      reserved
```
otherwise:
```
.byte       kind            event_kind_*
.word       mousex
.word       mousey
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
.byte       char1           ASCII code of shortcut #1 (e.g. uppercase B); or 0
.byte       char2           ASCII code of shortcut #2 (e.g. lowercase b, or same); or 0
.addr       name            Address of length-prefixed string
... repeats for each menu item
```

### Window "winfo"
```
.byte       id
.byte       options         option_*
.addr       title
.byte       hscroll         scroll_option_*
.byte       vscroll         scroll_option_*
.byte       hthumbmax
.byte       hthumbpos
.byte       vthumbmax
.byte       vthumbpos
.byte       status
.byte       reserved
.word       mincontwidth    minimum content size (horizontal)
.word       maxcontwidth    maximum content size (horizontal)
.word       mincontlength   minimum content size (vertical)
.word       maxcontlength   maximum content size (vertical)
GrafPort    windowport      GrafPort record
.addr       nextwinfo       address of next lower window in stack
```

Windows have a _content area_ which has the requested dimensions. Above this is an optional
_title bar_ which in turn has an optional _close box_. Within the content area are an
optional _resize box_ and optional _scroll bars_.


## Commands

Includes:

* Initialization
* Cursor Manager - set, show, hide
* Event Manager - get, peek, post
* Menu Manager - configure, enable, disable, select
* Window Manager - open, close, drag, grow, update
* Control Manager - scrollbars

## More


> NOTE: Movable windows must maintain an _offscreen_flag_. If a window is moved so that the
> content area is entirely offscreen then various operations should be skipped because
> the window's box coordinates will not be set correctly.

#### Input Loop

* Call GetEvent.
* If a key, then check modifiers (Open/Solid Apple) and key code, ignore or take action.
* If a click, call FindWindow.
* If target id not the window id, ignore.
* If target element is desktop or menu then ignore.
* If target element is close box then initiate [window close](#window-close).
* If target element is title bar then initiate [window drag](#window-drag).
* If target element is resize box then initiate [window resize](#window-resize).
* Otherwise, it is content area; call FindControl.
* If content part is a scrollbar then initiate a [scroll](#window-scroll).
* Otherwise, handle a content click using custom logic (e.g. hit testing buttons, etc)

#### Window Close

* Call TrackGoAway, which enters a modal loop to handle the mouse moving out/in the box.
* Result indicates clicked or canceled

#### Window Drag

* Call DragWindow.
* Call JUMP_TABLE_REDRAW_ALL.
* If _offscreen flag_ was not set, redraw desktop icons (DESKTOP_REDRAW_ICONS).
* Set _offscreen flag_ if window's `top` is greater than or equal to the screen bottom (191), clear otherwise.
* If _offscreen flag_ is not set, redraw window.

#### Window Resize

* Call GrowWindow.
* Call JUMP_TABLE_REDRAW_ALL.
* Call DESKTOP_REDRAW_ICONS.
* Call UpdateThumb if needed to adjust scroll bar settings. (Details TBD).
* Redraw window.

#### Window Scroll
