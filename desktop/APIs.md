
# DeskTop APIs

There are three distinct API classes that are used within DeskTop and
Desk Accessories:

* MouseGraphics ToolKit - graphics primitives, windowing and events
* Icon ToolKit - internal API, MLI-style interface providing icon services
* DeskTop Jump Table - simple JSR calls starting at $4003 MAIN, no arguments

In addition, some DeskTop data structures must be accessed directly in
Desk Accessories.

<!-- ============================================================ -->

## MouseGraphics ToolKit

This is a complex API library written by Apple circa 1985. It consists of:

* Graphics Primitives - screen management, lines, rects, polys, text, patterns, pens
* Mouse Graphics - windows, menus, events, cursors

Entry point is fixed at $4000 AUX, called MLI-style (JSR followed by command type and address of param block).

See [MGTK.md](../mgtk/MGTK.md) for further documentation.

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

MouseGraphics ToolKit call (main>aux). Y = call number, A,X = params address.

(Params must reside in aux memory, lower 48k or LC banks.)

#### `JUMP_TABLE_SIZE_STRING` ($4006)

Compose "nnn Blocks" string into internal buffer

Input is block count in (A,X).
Output string is in `text_buffer2`.

#### `JUMP_TABLE_DATE_STRING` ($4009)

Compose date string into internal buffer.

Input date/time must be in `datetime_for_conversion`.
Output string is in `text_buffer2`.

#### `JUMP_TABLE_SELECT_WINDOW` ($400C)

Select and refresh the specified window (A = window id)

#### `JUMP_TABLE_AUXLOAD` ($400F)

Load (A,X) from Aux memory into A.

#### `JUMP_TABLE_EJECT` ($4012)

Eject selected drive icon.

#### `JUMP_TABLE_REDRAW_ALL` ($4015) *

Redraws all DeskTop windows.

Required after a drag or resize in a DA. Follow with `IconTK::RedrawIcons` call.

#### `JUMP_TABLE_ITK_RELAY` ($4018)

Icon ToolKit call (main>aux). Y = call number, A,X = params address.

(Params must reside in aux memory, lower 48k or LC banks.)

#### `JUMP_TABLE_LOAD_OVL` ($401B)

Load overlay routine.

Routines are defined in `desktop/desktop.inc`.

#### `JUMP_TABLE_CLEAR_SEL` ($401E) *

Deselect all DeskTop icons (volumes/files).

#### `JUMP_TABLE_MLI` ($4021)

ProDOS MLI call. Y=call number, X,A=params address. *

(Params must reside in main memory, lower 48k.)

#### `JUMP_TABLE_COPY_TO_BUF` ($4024)

Copy to buffer.

#### `JUMP_TABLE_COPY_FROM_BUF` ($4027)

Copy from buffer.

#### `JUMP_TABLE_NOOP` ($402A)

No-Op command (RTS)

#### `JUMP_TABLE_FILE_TYPE_STRING` ($402D)

Composes file type string.

Input is ProDOS file type in A.
Output string is in `str_file_type`.

#### `JUMP_TABLE_ALERT_0` ($4030)

Show alert, with default button options for error number

Error number is in A - either a ProDOS error number, or a DeskTop error as defined in `desktop/desktop.inc`.

#### `JUMP_TABLE_ALERT_X` ($4033)

Show alert, with custom button options.

Error number is in A - either a ProDOS error number, or a DeskTop error as defined in `desktop/desktop.inc`.

Button options are in X per `desktop/desktop.inc`.

#### `JUMP_TABLE_LAUNCH_FILE` ($4036)

Launch file. Equivalent of **File > Open** command.

#### `JUMP_TABLE_CUR_POINTER` ($4039)

Changes mouse cursor to pointer.

#### `JUMP_TABLE_CUR_WATCH` ($403C)

Changes mouse cursor to watch.

#### `JUMP_TABLE_RESTORE_OVL` ($403F)

Restore from overlay routine

Routines are defined in `desktop/desktop.inc`.

#### `JUMP_TABLE_COLOR_MODE` ($4042) *
#### `JUMP_TABLE_MONO_MODE` ($4045) *

Set DHR color or monochrome mode, respectively. DHR monochrome mode is supported natively on the Apple IIgs, and via the AppleColor card and Le Chat Mauve, and is used by default by DeskTop. Desk Accessories that display images or exit DeskTop can can toggle the mode.

#### `JUMP_TABLE_RESTORE_SYS` ($4048) *

Used when exiting DeskTop; exit DHR mode, restores DHR mode to color, restores detached devices and reformats /RAM if needed, and banks in ROM and main ZP.

<!-- ============================================================ -->

## Icon ToolKit

This is part of DeskTop (unlike MGTK), but is written to be (mostly) isolated from the rest of the application logic, depending only on MGTK.

* An internal table of icon number &rarr; IconEntry is maintained.
* An internal list of highlighted (selected) icons is maintained.
* Window-centric calls assume a GrafPort for the window is already the current GrafPort.

Call from AUX (RAMRDON/RAMWRTON). Call style:
```
   jsr IconTK::MLI
   .byte command
   .addr params
```

Return value in A, 0=success.

Commands:

### `IconTK::AddIcon` ($01)

Parameters: address of IconEntry

Inserts an icon record into the table.

### `IconTK::HighlightIcon` ($02)

Parameters: { byte icon }

Highlights (selects) an icon by number.

### `IconTK::RedrawIcon` ($03)

Parameters: { byte icon }

Redraws an icon by number.

### `IconTK::RemoveIcon` ($04)

Parameters: { byte icon }

Removes an icon by number.

### `IconTK::HighlightAll` ($05)

Parameters: { byte window_id }

Highlights (selects) all icons in specified window (0 = desktop).

### `IconTK::RemoveAll` ($06)

Parameters: { byte window_id }

Removes all icons from specified window (0 = desktop).

### `IconTK::CloseWindow` ($07)

Parameters: { byte window_id }

Remove all icons associated with the specified window. No redrawing is done.

### `IconTK::GetHighlighted` ($08)

Parameters: { .res 127 }

Copies the selected icon numbers to the given buffer.

### `IconTK::FindIcon` ($09)

Parameters: { word mousex, word mousey, (out) byte result }

Find the icon number at the given coordinates.

### `IconTK::DragHighlighted` ($0A)

Parameters: { byte param, word mousex, word mousey }

Initiates a drag of the highlighted icon(s). On entry, set param to
the specific icon being dragged. On return, the param has 0 if the
drop was on the desktop, high bit clear if the drop target was an icon
(and the low bits are the icon number), high bit set if the drop
target was a window (and the low bits are the window number).

### `IconTK::UnhighlightIcon` ($0B)

Parameters: { byte icon }

Unhighlights the specified icon.

### `IconTK::RedrawIcons` ($0C)

Parameters: none (pass $0000 as address)

Redraws the icons on the desktop (mounted volumes, trash). This call
is required after destroying, moving, or resizing a desk accessory window.

### `IconTK::IconInRect` ($0D)

Parameters: { byte icon, rect bounds }

Tests to see if the given icon (by number) overlaps the passed rect.

### `IconTK::EraseIcon` ($0E)

Parameters: { byte icon }

Erases the specified icon by number. No error checking is done.

### IconEntry

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

<!-- ============================================================ -->

## DeskTop Data Structures

DeskTop's state - selection, windows, icons - is only partially
accessible via APIs. Operations such as determining the path to
selected file(s) requires accessing internal data structures directly.

### Window - representing an open directory

* `path_index` (byte) - id of active window in `path_table`
* `path_table` (array of addrs) - maps window id to window record address

Window record: 65-byte pathname buffer; it is a length-prefixed
absolute path (e.g. `/VOL/GAMES`)

### Selection

* `selected_file_count` (byte) - number of selected icons
* `selected_file_list` (array of bytes) - ids of selected icons

### Icon - representing a file (in a window) or volume (on the desktop)

* `file_table` (array of addrs) - maps icon id to icon entry address
