# Desk Accessory API

Desk Accessories for DeskTop have general access to the Mouse Graphics
Tool Kit MLI, ProDOS MLI, and DeskTop APIs. Special considerations for
DAs are documented here.

### Desk Accessory Lifecycle

* DAs are loaded/invoked at $800 MAIN
  * Up to $1C00 MAIN is available
  * But AUX $1B00 and on must be preserved.
* Save stack pointer
* Copy DA code from MAIN to AUX (e.g. using `AUXMOVE`) at same address.
* Transfer control to the AUX copy
  * This allows direct access to MGTK/DeskTop MLI
  * Retaining a copy in MAIN allows easy access to ProDOS MLI
* Turn on ALTZP and LCBANK1
* Create window (`OpenWindow`)
* Draw everything
* Flush event queue (`FlushEvents`)
* Run an event Loop (`GetEvent`, and subsequent processing, per MGTK)
  * Normal event processing per MGTK
  * In addition, following a window drag/resize, DeskTop calls must be made:
     * `JUMP_TABLE_REDRAW_ALL`
     * `DESKTOP_REDRAW_ICONS`
  * ...
* Destroy window (`CloseWindow`)
* Tell DeskTop to redraw desktop icons (`DESKTOP_REDRAW_ICONS`)
* Switch control back to MAIN (`RAMRDOFF`/`RAMWRTOFF`)
* Ensure ALTZP and LCBANK1 are still on
* Restore stack pointer
* `rts`
