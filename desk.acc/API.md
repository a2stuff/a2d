# Desk Accessory API

Desk Accessories for DeskTop have general access to the Mouse Graphics
Tool Kit MLI, ProDOS MLI, and DeskTop APIs. Special considerations for
DAs are documented here.

### Desk Accessory Lifecycle

* DAs are loaded/invoked at $800 Main
  * Up to $1C00 Main is available
  * But Aux $1B00 and on must be preserved.
* Save stack pointer
* Copy DA code from Main to Aux (e.g. using `AUXMOVE`) at same address.
  * Needed if any MGTK resources will be used (bitmaps, etc)
* Transfer control to the Aux copy (`RAMRDON`/`RAMWRTON`)
  * This allows direct access to MGTK/IconTK MLI
  * Retaining a copy in Main allows easy access to ProDOS MLI
* Turn on ALTZP and LCBANK1 (should already be the case)
* Create window (`OpenWindow`)
* Draw everything
* Flush event queue (`FlushEvents`)
* Run an event Loop (`GetEvent`, and subsequent processing, per MGTK)
  * Normal event processing per MGTK
  * In addition, following a window drag/resize, a DeskTop call must be made:
     * `JUMP_TABLE_REDRAW_ALL` - redraw all windows and desktop (volume) icons.
  * ...
* Destroy window (`CloseWindow`)
* Switch control back to Main (`RAMRDOFF`/`RAMWRTOFF`)
* Ensure ALTZP and LCBANK1 are still on
* Restore stack pointer
* `rts`

### Accessing Files

As a convenience, DAs are launched with the full path to the first
selected file at $220 Main. This applies to both Preview DAs (executed
automatically when a text/image/etc file is opened) and to DAs invoked
from the menu. If no file is selected, $220 is set to 0.

For more elaborate operations, e.g. on directories or multiple files,
the following DeskTop calls can be used:

* `JUMP_TABLE_GET_SEL_COUNT` - returns the number of selected icons in A
* `JUMP_TABLE_GET_SEL_WIN` - returns the window id holding the selection (0 if desktop) in A
* `JUMP_TABLE_GET_WIN_PATH` - called with window id in A, returns the path (in Aux LC1) in A,X
* `JUMP_TABLE_GET_SEL_ICON` - called with selection index in A, returns IconEntry (in Aux LC1) in A,X
