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
  * In addition, following a window drag/resize, DeskTop calls must be made:
     * `JUMP_TABLE_REDRAW_ALL` - redraw all windows
     * `IconTK::RedrawIcons` - redraw desktop (volume) icons
  * ...
* Destroy window (`CloseWindow`)
* Switch control back to Main (`RAMRDOFF`/`RAMWRTOFF`)
* Ensure ALTZP and LCBANK1 are still on
* Restore stack pointer
* `rts`
