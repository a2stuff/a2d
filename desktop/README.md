
# DeskTop diassembly notes

## DESKTOP.SYSTEM

`sys.s`

A short (8k) loader program. This is responsible for copying
the rest to a RAM card (if available), then invoking the main app.

NOTE: The second half may be used for "Down load", i.e. copy
Selector entries to RAMCard as well.

## DESKTOP2.$F1

This is large - 111k. It includes a loader and the DeskTop app with
both main memory and aux memory segments, filling everything from
$4000 to $FFFF (except for I/O space and ProDOS), and still having
more code segments swapped in dynamically.

The file is broken down into multiple segments:

* segment 0: load  - A$2000-$257F, L$0580, B$000000 (`loader.s`; Loader)
* segment 1: aux   - A$4000-$BFFF, L$8000, B$000580 (`mgtk.s`, `desktop.s`; MGTK, DeskTop)
* segment 2: auxlc - A$D000-$ECFF, L$1D00, B$008580 (`desktop.s`; DeskTop)
* segment 3: auxlc - A$FB00-$FFFF, L$0500, B$00A280 (`desktop.s`; DeskTop)
* segment 4: main  - A$4000-$BEFF, L$7F00, B$00A780 (`desktop.s`; DeskTop)
* segment 5: main  - A$0800-$0FFF, L$0800, B$012680 (`desktop.s`; Initializer)
* segment 6: main  - A$0290-$03EF, L$0160, B$012E80 (`invoker.s`; Invoker)
* overlays dynamically loaded for these actions:
  * disk copy     - A$0800-$09FF, L$0200, B$012FE0 (`ovl1.s`)
    * which loads - A$1800-$19FF, L$0200, B$0131E0 (`ovl1a.s`)
    * which loads - A$D000-$F1FF, L$2200, B$0133E0 (`ovl1b.s`; overwrites the aux LC)
    * and...      - A$0800-$12FF, L$0B00, B$0155E0 (`ovl1c.s`)
  * format/erase  - A$0800-$1BFF, L$1400, B$0160E0 (`ovl2.s`)
  * selector      - A$9000-$9FFF, L$1000, B$0174E0 (`ovl3.s`)
  * common        - A$5000-$6FFF, L$2000, B$0184E0 (`ovl4.s`; used by selector, copy, delete)
  * file copy     - A$7000-$77FF, L$0800, B$01A4E0 (`ovl5.s`)
  * file delete   - A$7000-$77FF, L$0800, B$01ACE0 (`ovl6.s`)
  * selector      - A$7000-$77FF, L$0800, B$01B4E0 (`ovl7.s`)
* (EOF is $01BCE0)

The DeskTop segments loaded into the Aux bank switched ("language
card") memory can be used from both main and aux, so contain relay
routines, resources, and buffers. More details below.

## Structure

### Loader

`loader.s`

Invoked at $2000; patches the ProDOS QUIT routine (at LC2 $D100) then
invokes it. That gets copied to $1000-$11FF and run by ProDOS.

The invoked code stashes the current prefix and re-patches ProDOS with
itself. It then (in a convoluted way) loads in the second $200 bytes of
`DESKTOP2` at $2000 and invokes that.

This code then loads the rest of the file as a sequence of segments,
moving them to the appropriate destination in aux/banked/main memory.

There's fourth chunk of code, which expects to live at $280 so it
can't co-exist with the Invoker; it may be temporary code, as there is
no sign that it is ever moved into place. It's also unclear how it
would be hooked in. The routine detects OA+CA+P and prints the DHR
screen to an ImageWriter II printer attached to Slot 1. (This may have
been used to produce screenshots during development for manuals.)

### Invoker

`invoker.s`

Loaded at $290-$03EF, this small routine is used to invoke a target,
e.g. a double-clicked file. System files are loaded/run at $2000,
binary files at the location specified by their aux type, and BASIC
files loaded by searching for BASIC.SYSTEM and running it with the
pathname passed at $2006 (see ProDOS TLM).

### Initializer

(in `desktop.s`)

Loaded at $800-$FFF, this does one-time initialization of the
DeskTop. It is later overwritten when any desk accessories are
run.

### MouseGraphics ToolKit (MGTK)

`mgtk.s`

Aux $4000-$851E is the [MouseGraphics ToolKit](../MGTK.md) - a
GUI library used for the DeskTop application.

Since this resides in Aux memory, DeskTop spends most of its time
with Aux read/write enabled. The state and logic for rendering
the desktop and window contents resides in Aux to avoid proxying
data.

### "DeskTop" Application

`desktop.s`

DeskTop application code is in the lower 48k of both Aux and Main:

* Aux $851F-$BFFF - sitting above the GUI library
* Main $4000-$BEFF

...and in the Aux language card area (accessible from both aux and
main code) are relays, buffers and resources:

* Aux $D000-$ECFF - relays and other aux/main helpers, resources (menus, strings, window)
* Aux $ED00-$FAFF - hole for data buffer - entries for each icon on desktop/in windows
* Aux $FB00-$FFFF - more resources (file types, icons)

($C000-$CFFF is reserved for I/O, and main $BF page and language card is ProDOS)

Aux $1B00-$1F7F holds lists of icons, one for the desktop then one for up
to 8 windows. First byte is a count, up to 127 icon entries. Icon numbers
map indirectly into a table at $ED00 that holds the type, coordinates, etc.
Aux $1F80-$1FFF is a map of used/free icon numbers, as they are reassigned
as windows are opened and closed.

### Overlays

`ovl1.s` etc

Interactive commands including disk copy/format/erase, file
copy/delete, and Selector add/edit/delete/run all dynamically load
main memory code overlays into one or more of: $800-$1BFF,
$5000-$6FFF, $7000-$77FF, and $9000-$9FFF. When complete, any original
code above $4000 is reloaded.

## Memory Map

```
       Main               Aux                 ROM
$FFFF +-------------+    +-------------+    +-------------+
      | ProDOS      |    | DeskTop     |    | Monitor     |
$F800 |             |    | Resources/  |    +-------------+
      |             |    | Buffers     |    | Applesoft   |
      |             |    |             |    |             |
      |             |    |             |    |             |
      |             |    |             |    |             |
$D000 +-------------+    +-------------+    +-------------+    +-------------+
                                                               | I/O         |
                                                               |             |
$C000 +-------------+    +-------------+                       +-------------+
      | ProDOS GP   |    | DeskTop     |
$BF00 +-------------+    | App Code    |
      | DeskTop     |    |             |
      | App Code    |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
$A000 |      +------+    |             |
      |      | Ovl  |    |             |
      |      |      |    |             |
      |      |      |    |             |
$9000 |      +------+    |             |
      |             |    |             |
$8E00 |             |    | Entry Point |
      |             |    |             |
$8800 |             |    | Font        |
      |             |    |             |
$851F |             |    +-------------+
      |             |    | MGTK        |
      |             |    |             |
      |             |    |             |
      |             |    |             |
$7800 |      +------+    |             |
      |      | Ovl  |    |             |
$7000 |      +------+    |             |
      |      | Ovl  |    |             |
      |      |      |    |             |
      |      |      |    |             |
      |      |      |    |             |
      |      |      |    |             |
      |      |      |    |             |
      |      |      |    |             |
      |      |      |    |             |
$5000 |      +------+    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
$4000 +-------------+    +-------------+
      | Graphics    |    | Graphics    |
      |             |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
$2000 +-------------+    +-------------+
      | Initializer |    | Win/Icn Map |
$1B00 | & Desk Acc  |    +-------------+
      | & Overlays  |    | Desk Acc &  |
      |             |    | Save Area   |
      |             |    |             |
$0800 +-------------+    +-------------+
      | Drawing     |    | Drawing     |
      | Temp Buffer |    | Temp Buffer |
$0400 +-------------+    +-------------+
      | Invoker     |    |             |
$0300 +-------------+    +-------------+
      | Input Buf   |    | Input Buf   |
$0200 +-------------+    +-------------+
      | Stack       |    | Stack       |
$0100 +-------------+    +-------------+
      | Zero Page   |    | Zero Page   |
$0000 +-------------+    +-------------+
```

The Disk Copy command replaces large chunks of memory and is best
thought of as a separate application. When exiting, the DeskTop is
restarted from the beginning.
