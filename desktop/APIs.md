
# DeskTop APIs

There are three distinct API classes that are used within DeskTop and
Desk Accessories:

* MouseGraphics ToolKit - graphics primitives, windowing and events
* Icon ToolKit - internal API, MLI-style interface providing icon services
* DeskTop Jump Table - simple JSR calls starting at $4003 MAIN, no arguments

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
Some calls take MLI-style parameters, or in registers.

> Routines marked with * are used by Desk Accessories.

#### `JUMP_TABLE_MGTK_CALL` *

MouseGraphics ToolKit call (main>aux).

Input: Follow `JSR` by call (`.byte`) and params (`.addr`), MLI-style.
Output: A=result

(Param data must reside in aux memory, lower 48k or LC banks.)

Use the `JUMP_TABLE_MGTK_CALL` macro (yes, same name) for convenience.

#### `JUMP_TABLE_MLI_CALL` *

ProDOS MLI call.

Input: Follow `JSR` by call (`.byte`) and params (`.addr`), MLI-style.
Output: C set on error, A = error code.

(Param data must reside in main memory, lower 48k.)

Use the `JUMP_TABLE_MLI_CALL` macro (yes, same name) for convenience.

#### `JUMP_TABLE_CLEAR_UPDATES` *

Clear update events - i.e. redraw windows as needed after move/resize/close.

#### `JUMP_TABLE_YIELD_LOOP` *

Yield during an event loop for DeskTop to run tasks. This allows the menu bar clock to be updated and similar infrequent operations.

Desk Accessories should call this (from main!) from their event loop unless they need to have total control of the system (e.g. screen savers). A good place to do this is just before a call to `MGTK::GetEvent`. Note that the current grafport may be modified during this call.

Yielding during further nested loops (e.g. button tracking, etc) can be done but is not worth the effort.

#### `JUMP_TABLE_SELECT_WINDOW` *

Select and refresh the specified window (A = window id)

#### `JUMP_TABLE_SHOW_ALERT` *

Show alert, with default button options for error number

Error number is in A - either a ProDOS error number, or a DeskTop `kErrXXX` error as defined in `desktop/desktop.inc`.

NOTE: This will use Aux $800...$1AFF to save the alert background; be careful when calling from a Desk Accessory, which may run from the same area.

#### `JUMP_TABLE_SHOW_ALERT_OPTIONS`

Show alert, with custom button options.

Error number is in A - either a ProDOS error number, or a DeskTop `kErrXXX` error as defined in `desktop/desktop.inc`.

Button options are in X per `desktop/desktop.inc`.

NOTE: This will use Aux $800...$1AFF to save the alert background; be careful when calling from a Desk Accessory, which may run from the same area.

#### `JUMP_TABLE_LAUNCH_FILE`

Launch file. Equivalent of **File > Open** command.

#### `JUMP_TABLE_CUR_POINTER` *

Changes mouse cursor to pointer.

#### `JUMP_TABLE_CUR_WATCH` *

Changes mouse cursor to watch.

#### `JUMP_TABLE_CUR_IBEAM` *

Changes mouse cursor to I-beam.

#### `JUMP_TABLE_RESTORE_OVL` *

Restore from overlay routine

Routines are defined in `desktop/desktop.inc`.

#### `JUMP_TABLE_COLOR_MODE` *
#### `JUMP_TABLE_MONO_MODE` *

Set DHR color or monochrome mode, respectively. DHR monochrome mode is supported natively on the Apple IIgs, and via the AppleColor card and Le Chat Mauve, and is used by default by DeskTop. Desk Accessories that display images or exit DeskTop can can toggle the mode.

#### `JUMP_TABLE_RGB_MODE` *

Set DHR color or monochrome mode, based on control panel setting.

#### `JUMP_TABLE_RESTORE_SYS` *

Used when exiting DeskTop; exit DHR mode, restores DHR mode to color, restores detached devices and reformats /RAM if needed, and banks in ROM and main ZP.

#### `JUMP_TABLE_GET_SEL_COUNT` *

Get number of selected icons.

Output: A = count.

#### `JUMP_TABLE_GET_SEL_ICON` *

Get selected IconEntry address.

Input: A = index within selection.
Output: A,X = address of IconEntry.

#### `JUMP_TABLE_GET_SEL_WIN` *

Get window containing selection (if any).

Output: A = window_id, or 0 for desktop.

#### `JUMP_TABLE_GET_WIN_PATH` *

Get path to window.

Input: A = window_id.
Output: A,X = address of path (length-prefixed).

#### `JUMP_TABLE_HILITE_MENU` *

Toggle hilite on last clicked menu. This should be used by a desk accessory that repaints the entire screen including the menu bar, since when the desk accessory exits the menu used to invoke it (Apple or File) will toggle.

#### `JUMP_TABLE_ADJUST_FILEENTRY` *

Adjust case in FileEntry structure. If GS/OS filename bits are set, those are used. If the file type is an AppleWorks file, the auxtype bits are used. Otherwise, case is inferred.

Input: A,X = FileEntry structure.

#### `JUMP_TABLE_GET_RAMCARD_FLAG` *

Returns Z=1/N=0 if DeskTop is running from its original location, and Z=0/N=1 if DeskTop was copied to RAMCard.

#### `JUMP_TABLE_GET_ORIG_PREFIX` *

If DeskTop was copied to RAMCard, this populates the passed buffer with the original prefix path (with trailing `/`). Do not call unless DeskTop was copied to RAMCard.

Input: A,X = Path buffer.

<!-- ============================================================ -->

## Icon ToolKit

This is part of DeskTop (unlike MGTK), but is written to be (mostly) isolated from the rest of the application logic, depending only on MGTK.

* An internal table of icon number &rarr; IconEntry is maintained.
* An internal list of highlighted (selected) icons is maintained.
* Window-centric calls assume a GrafPort for the window is already the current GrafPort.

Definitions are in `desktop/icontk.inc`.

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

Note that it does not paint the icon. Callers must make a subsequent call to `IconTK::DrawIcon` with an appropriate GrafPort selected. This is because the window may be obscured, so the state change can occur but the paint can not.

### `IconTK::HighlightIcon` ($02)

Parameters: { byte icon }

Highlights (selects) an icon by number.

Note that it does not repaint the icon. Callers must make a subsequent call to `IconTK::DrawIcon` with an appropriate GrafPort selected. This is because the window may be obscured, so the state change can occur but the paint can not.

### `IconTK::DrawIcon` ($03)

Parameters: { byte icon }

Redraws an icon by number.

### `IconTK::RemoveIcon` ($04)

Parameters: { byte icon }

Removes an icon by number.

Note that it does not paint the icon. Callers must make a previous call to `IconTK::EraseIcon` with an appropriate GrafPort selected. This is because the window may be obscured, so the state change can occur but the paint can not.

### `IconTK::RemoveAll` ($05)

Parameters: { byte window_id }

Removes all icons from specified window (0 = desktop).

### `IconTK::CloseWindow` ($06)

Parameters: { byte window_id }

Remove all icons associated with the specified window. No redrawing is done.

### `IconTK::FindIcon` ($07)

Parameters: { word mousex, word mousey, (out) byte result }

Find the icon number at the given coordinates.

### `IconTK::DragHighlighted` ($08)

Parameters: { byte param, word mousex, word mousey }

Initiates a drag of the highlighted icon(s). On entry, set param to
the specific icon being dragged. On return, the param has 0 if the
drop was on the desktop, high bit clear if the drop target was an icon
(and the low bits are the icon number), high bit set if the drop
target was a window (and the low bits are the window number).

### `IconTK::UnhighlightIcon` ($09)

Parameters: { byte icon }

Unhighlights the specified icon.

Note that it does not repaint the icon. Callers must make a subsequent call to `IconTK::DrawIcon` with an appropriate GrafPort selected. This is because the window may be obscured, so the state change can occur but the paint can not.

### `IconTK::RedrawDesktopIcons` ($0A)

Parameters: none (pass $0000 as address)

Redraws the icons on the desktop (mounted volumes, trash). This call should be performed in response to an MGTK `update` event with `window_id` of 0, indicating that the desktop needs to be repainted. It assumes that overlapping windows will be repainted on top so no additional clipping is done beyond the active grafport.

### `IconTK::IconInRect` ($0B)

Parameters: { byte icon, rect bounds }

Tests to see if the given icon (by number) overlaps the passed rect.

### `IconTK::EraseIcon` ($0C)

Parameters: { byte icon }

Erases the specified icon by number. No error checking is done.

### IconEntry

```
.byte icon      icon index
.byte state     bit 0 = allocated
                bit 6 = highlighted
.byte type/window_id
                bits 0-3 = window_id
                bits 4,5 = unused
                bit 6 = drop target flag (trash, folder, dir)
                bit 7 = open flag
.word iconx     (pixels)
.word icony     (pixels)
.addr iconbits  (addr of {mapbits, mapwidth, reserved, maprect})
.res  16        (length-prefixed name)
.byte record_num (index of icon in window)
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
