# DeskTop APIs

There are three distinct API classes that need to be used:

* MouseGraphics ToolKit - graphics primitives, windowing and events
* DeskTop Jump Table - simple JSR calls starting at $4003 MAIN, no arguments
* DeskTop API - another MLI-style interface starting at $8E00 AUX

In addition, some DeskTop data structures can be accessed directly.


<!-- ============================================================ -->

## MouseGraphics ToolKit

This is a complex API library written by Apple circa 1985. It consists of:

* Graphics Primitives - screen management, lines, rects, polys, text, patterns, pens
* Mouse Graphics - windows, menus, events, cursors

Entry point is fixed at $4000 AUX, called MLI-style (JSR followed by command type and address of param block).

See [MGTK.md](MGTK.md) for further documentation.

<!-- ============================================================ -->

## DeskTop Jump Table

Call from MAIN (RAMRDOFF/RAMWRTOFF); AUX language card RAM must be banked in. Call style:
```
   jsr $xxxx
```
Some calls take parameters in registers.

> NOTE: Not all of the calls have been identified.
> Routines marked with * are used by Desk Accessories.

#### `JUMP_TABLE_MAIN_LOOP` ($4000)

Enter DeskTop main loop

#### `JUMP_TABLE_MGTK_RELAY` ($4003)

MGTK relay call (main>aux)

#### `JUMP_TABLE_SIZE_STRING` ($4006)

Compose "nnn Blocks" string into internal buffer

#### `JUMP_TABLE_DATE_STRING` ($4009)

Compose date string into internal buffer

#### `JUMP_TABLE_0C` ($400C)

???

#### `JUMP_TABLE_0F` ($400F)

Auxload

#### `JUMP_TABLE_EJECT` ($4012)

Eject command

#### `JUMP_TABLE_REDRAW_ALL` ($4015) *

Redraws all DeskTop windows. Required after a drag or resize.
Follow with `DT_REDRAW_ICONS` call.

#### `JUMP_TABLE_DESKTOP_RELAY` ($4018)

DESKTOP relay call (main>aux)

#### `JUMP_TABLE_LOAD_OVL` ($401B)

Load overlay routine

#### `JUMP_TABLE_CLEAR_SEL` ($401E) *

Deselect all DeskTop icons (volumes/files).

#### `JUMP_TABLE_MLI` ($4021)

ProDOS MLI call (Y=call, X,A=params addr) *

#### `JUMP_TABLE_COPY_TO_BUF` ($4024)

Copy to buffer

#### `JUMP_TABLE_COPY_FROM_BUF` ($4027)

Copy from buffer

#### `JUMP_TABLE_NOOP` ($402A)

No-Op command (RTS)

#### `JUMP_TABLE_2D` ($402D)

??? (Draw type/size/date in non-icon views?)

#### `JUMP_TABLE_ALERT_0` ($4030)

Show alert in A, default options

#### `JUMP_TABLE_ALERT_X` ($4033)

Show alert in A, options in X

#### `JUMP_TABLE_LAUNCH_FILE` ($4036)

Launch file

#### `JUMP_TABLE_CUR_POINTER` ($4039)

Changes mouse cursor to pointer.

#### `JUMP_TABLE_CUR_WATCH` ($403C)

Changes mouse cursor to watch.

#### `JUMP_TABLE_RESTORE_OVL` ($403F)

Restore from overlay routine

#### `JUMP_TABLE_COLOR_MODE` ($4042) *
#### `JUMP_TABLE_MONO_MODE` ($4045) *

Set DHR color or monochrome mode, respectively. DHR monochrome mode is supported natively on the Apple IIgs, and via the AppleColor card and Le Chat Mauve, and is used by default by DeskTop. Desk Accessories that display images or exit DeskTop can can toggle the mode.

#### `JUMP_TABLE_RESTORE_SYS` ($4048) *

Used when exiting DeskTop; exit DHR mode, restores DHR mode to color, restores detached devices and reformats /RAM if needed, and banks in ROM and main ZP.

<!-- ============================================================ -->

## DeskTop API

Call from AUX (RAMRDON/RAMWRTON). Call style:
```
   jsr $8E00
   .byte command
   .addr params
```

Return value in A, 0=success.

> NOTE: Only some of the calls have been identified.

Commands:

### `DT_ADD_ICON` ($01)

Parameters: { addr icondata }

Inserts an icon record into the table.

### `DT_HIGHLIGHT_ICON` ($02)

Parameters: { byte icon }

Highlights (selects) an icon by number.

### `DT_REDRAW_ICON` ($03)

Parameters: { byte icon }

Redraws an icon by number.

### `DT_REMOVE_ICON` ($04)

Parameters: { byte icon }

Removes an icon by number.

### `DT_HIGHLIGHT_ALL` ($05)

Parameters: { byte window_id }

Highlights (selects) all icons in specified window (0 = desktop).

### `DT_REMOVE_ALL` ($06)

Parameters: { byte window_id }

Removes all icons from specified window (0 = desktop).

### `DT_CLOSE_WINDOW` ($07)

Parameters: { byte window_id }

Closes the specified window.

### `DT_GET_HIGHLIGHTED` ($08)

Parameters: { .res 20 }

Copies the numbers of the first 20 selected icons to the given buffer.

### `DT_FIND_ICON` ($09)

Parameters: { word mousex, word mousey, (out) byte result }

Find the icon number at the given coordinates.

### `DT_DRAG_HIGHLIGHTED` ($0A)

Parameters: { byte param }

Initiates a drag of the highlighted icon(s). On entry, set param to
the specific icon being dragged. On return, the param has 0 if the
drop was on the desktop, high bit clear if the drop target was an icon
(and the low bits are the icon number), high bit set if the drop
target was a window (and the low bits are the window number).

### `DT_UNHIGHLIGHT_ICON` ($0B)

Parameters: { addr iconentry }

Unhighlights the specified icon. Note that the address of the icon
entry is passed, not the number.

### `DT_REDRAW_ICONS` ($0C)

Parameters: none (pass $0000 as address)

Redraws the icons on the desktop (mounted volumes, trash). This call
is required after destroying, moving, or resizing a desk accessory window.

### `DT_ICON_IN_RECT` ($0D)

Parameters: { byte icon, rect bounds }

Tests to see if the given icon (by number) overlaps the passed rect.

### `DT_ERASE_ICON` ($0E)

Parameters: { byte icon }

Erases the specified icon by number. No error checking is done.


<!-- ============================================================ -->

## DeskTop Data Structures

DeskTop's state - selection, windows, icons - is only partially accessible
via APIs. Operations such as opening the selected file requires accessing
internal data structures directly.

### Window - representing an open directory

* `path_index` (byte) - id of active window in `path_table`
* `path_table` (array of addrs) - maps window id to window record address

Window record: 65-byte pathname buffer; it is a length-prefixed
absolute path (e.g. `/VOL/GAMES`)

### Selection

* `selected_file_count` (byte) - number of selected icons
* `selected_file_list` (array of bytes) - ids of selected icons

### Icon - representing a file (in a window) or volume (on the desktop)

* `file_table` (array of addrs) - maps icon id to icon record address

Icon record: 27-byte structure optimized for rendering the file/volume icon.

```
.byte icon      icon index
.byte state     $80 = highlighted, 0 = otherwise
.byte type/window_id
                (bits 0-3 window_id)
                (bits 4,5,6)
                       000 = directory
                       001 = system
                       010 = binary (maybe runnable)
                       011 = basic
                       100 = (unused)
                       101 = data (text/generic/...)
                       110 = (unused)
                       111 = trash
                (bit 7 = open flag)
.word iconx     (pixels)
.word icony     (pixels)
.addr iconbits  (addr of {mapbits, mapwidth, reserved, maprect})
.byte len       (name length + 2)
.res  17  name  (name, with a space before and after)
```
