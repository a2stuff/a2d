
# DeskTop diassembly notes

## DESKTOP.SYSTEM

A short (8k) loader program. This is likely responsible for copying
the rest to a RAM card (if available), then invoking the main app.

## DESKTOP2.$F1

This is large - 111k. It includes a loader, the DeskTop app (with both
main memory and aux memory segments, filling everything from $4000 to
$FFFF (except for I/O space and ProDOS), and still having more code
segments swapped in dynamically.

The file is broken down into multiple segments:

* segment 0: load  - A$2000-$257F, L$0580, mark $000000 (Loader)
* segment 1: aux   - A$4000-$BFFF, L$8000, mark $000580 (MGTK, DeskTop)
* segment 2: auxlc - A$D000-$ECFF, L$1D00, mark $008580 (DeskTop)
* segment 3: auxlc - A$FB00-$FFFF, L$0500, mark $00A280 (DeskTop)
* segment 4: main  - A$4000-$BEFF, L$7F00, mark $00A780 (DeskTop)
* segment 5: main  - A$0800-$0FFF, L$0800, mark $012680 (Initializer)
* segment 6: main  - A$0290-$03EF, L$0160, mark $012E80 (Invoker)
* overlays dynamically loaded for these actions:
  * disk copy     - A$0800, L$0200, mark $012FE0
  * _(there's a $2F00 gap here; disk copy overlay itself loads A$1800,L$200,mark $131E0; rest is TBD)_
  * format/erase  - A$0800, L$1400, mark $0160E0
  * selector      - A$9000, L$1000, mark $0174E0
  * common        - A$5000, L$2000, mark $0184E0 (used by selector, copy, delete)
  * file copy     - A$7000, L$0800, mark $01A4E0
  * file delete   - A$7000, L$0800, mark $01ACE0
  * selector      - A$7000, L$0800, mark $01B4E0
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

`desktop.s`

Loaded at $800-$FFF, this does one-time initialization of the
DeskTop. It is later overwritten when any desk accessories are
run.

### Mouse Graphics Tool Kit (MGTK)

`a2d.s`

AUX $4000-$851E is the GUI library used for the DeskTop application
and (presumably) for disk copy and Selector apps (TBD).

Entry point is $4000 with a ProDOS MLI-style calling convention

### "DeskTop" Application

`desktop.s`

DeskTop application code is in the lower 48k of both Aux and Main:

* Aux $851F-$BFFF - sitting above the GUI library
* Main $4000-$BEFF

...and in the Aux language card area (accessible from both aux and
main code) are relays, buffers and resources:

* Aux $D000-$ECFF - relays and other aux/main helpers, resources (menus, strings, window)
* Aux $ED00-$FAFF - hole for data buffer
* Aux $FB00-$FFFF - more resources (file types, icons)

($C000-$CFFF is reserved for I/O, and main $BF page and language card is ProDOS)

Interactive commands including disk copy/format/erase, file
copy/delete, and Selector add/edit/delete/run all dynamically load
main memory code overlays into one or more of: $800-$1FFF,
$5000-$6FFF, $7000-$77FF, and $9000-$9FFF. When complete, any original
code above $4000 is reloaded.

Aux $1B00-$1F7F holds lists of icons, one for the desktop then one for up
to 8 windows. First byte is a count, up to 127 icon entries. Icon numbers
map indirectly into a table at $ED00 that holds the type, coordinates, etc.
Aux $1F80-$1FFF is a map of used/free icon numbers.

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
      | Text        |    | Text        |
      |             |    |             |
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
