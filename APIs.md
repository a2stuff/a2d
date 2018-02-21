# DeskTop APIs

There are three distinct API classes that need to be used:

* MouseGraphics ToolKit - graphics primitives, windowing and events
* DeskTop Jump Table - simple JSR calls starting at $4003 MAIN, no arguments
* DeskTop API - another MLI-style interface starting at $8E00 AUX

## MouseGraphics ToolKit

This is a complex API library written by Apple circa 1985. It consists of:

* Graphics Primitives - screen management, lines, rects, polys, text, patterns, pens
* Mouse Graphics - windows, menus, events, cursors

Entry point is fixed at $4000 AUX, called MLI-style (JSR followed by command type and address of param block).

See [MGTK.md](MGTK.md) for further documentation.

## DeskTop Jump Table

Call from MAIN (RAMRDOFF/RAMWRTOFF). Call style:

```
   jsr $xxxx
```

> NOTE: Most of these calls have not been identified yet.

#### JUMP_TABLE_REDRAW_ALL ($4015)

Redraws all DeskTop windows. Required after a drag or resize. Follow with DESKTOP_REDRAW_ICONS call.

#### JUMP_TABLE_CLEAR_SEL ($401E)

Deselect all DeskTop icons (volumes/files).

#### JUMP_TABLE_CUR_POINTER ($4039)

Changes mouse cursor to the default pointer. Note that bitmap is in the language card memory so it must be swapped in.

#### JUMP_TABLE_CUR_WATCH ($403C)

Changes mouse cursor to a watch. Note that bitmap is in the language card memory so it must be swapped in.

## DeskTop API

Call from AUX (RAMRDON/RAMWRTON). Call style:

```
   jsr $8E00
   .byte command
   .addr params
```

> NOTE: Only a single call has been identified so far.

Commands:

#### DESKTOP_REDRAW_ICONS ($0C)

Parameters: none (pass $0000 as address)

Redraws the icons on the desktop (mounted volumes, trash). This call is required in these cases:

* After destroying a window (CloseWindow)
* After repainting the desktop (JUMP_TABLE_REDRAW_ALL) following a drag (DragWindow)
* After repainting the desktop (JUMP_TABLE_REDRAW_ALL) following a resize (GrowWindow)

## DeskTop Data Structures

DeskTop's state - windows, icons - is accessible indirectly via APIs,
and data structures can be accessed directly.

### Selection

* `path_index` (byte) - id of active window in `path_table`

* `selected_file_count` (byte) - number of selected icons
* `selected_file_list` (array of bytes) - ids of selected icons

### Window - representing an open directory

* `path_table` (array of addrs) - maps window id to window record address

Window record: 65-byte pathname buffer; it is a length-prefixed
absolute path (e.g. `/HD/GAMES`)

### Icon - representing a file (in a window) or volume (on the desktop)

* `file_table` (array of addrs) - maps icon id to icon record address

Icon record: 27-byte structure optimized for rendering the file/volume icon.

```
.byte icon      icon index
.byte ??
.byte type/window_id
                (bits 0-3 window_id)
                (bits 4,5,6)
                       000 = directory
                       001 = system
                       010 = binary
                       011 = basic
                       100 = (unused)
                       101 = text/generic
                       110 = (unused)
                       111 = trash
                (bit 7 = open flag)
.word iconx     (pixels)
.word icony     (pixels)
.addr iconbits  (addr of {mapbits, mapwidth, reserved, maprect})
.byte len       (name length + 2)
.res  17  name  (name, with a space before and after)
```
