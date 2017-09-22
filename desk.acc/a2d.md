# A2D API

There are three distinct API classes that need to be used:

* Main A2D API - entry point $4000 AUX, called MLI-style (JSR followed by command type and address of param block)
* DeskTop Jump Table - simple JSR calls starting at $4003 MAIN, no arguments
* DeskTop API - another MLI-style interface starting at $8E00 AUX

## Main A2D API

### Concepts

#### Box

The _box_ block is reused in several places. It has the following structure

```
        .word left           pixels from screen left edge
        .word top            pixels from screen top edge
        .addr addr           A2D_SCREEN_ADDR ($2000)
        .word stride         A2D_SCREEN_STRIDE ($80)
        .word hoffset        pixels scrolled left
        .word voffset        pixels scrolled up
        .word width          pixels wide
        .word height         pixels tall
```

Drawing state can be set to a box (A2D_SET_BOX) and then subsequent operations will occur 
within the box: they will be clipped to the bounds and the offset will be taken into account.
For example, if hoffset is 15 and voffset is 5 then a pixel plotted at 40, 40 will appear
at 40 - 15 = 25 pixels from the left edge and 40 - 5 = 35 pixels from the top edge.

#### Pattern

A simple repeating 8x8 _pattern_ is defined by 8 bytes. All bits of each byte are used.

#### Window Parts

Windows have a _client area_ which has the requested dimensions. Above this is an optional
_title bar_ which in turn has an optional _close box_. Within the client area are an 
optional _resize box_ and optional _scroll bars_.


### Desk Accessory Lifecycle

* Save stack
* Copy DA code from MAIN to AUX



### Event Loop




### Commands


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

* After destroying a window (A2D_DESTROY_WINDOW)
* After repainting the desktop (JUMP_TABLE_REDRAW_ALL) following a drag (A2D_DRAG_WINDOW)
* After repainting the desktop (JUMP_TABLE_REDRAW_ALL) following a resize (A2D_DRAG_RESIZE/A2D_RESIZE_WINDOW)
