
# DeskTop diassembly notes

## DESKTOP.SYSTEM

A short (8k) loader program. This is likely responsible for copying
the rest to a RAM card (if available), then invoking the main app.

## DESKTOP2.$F1

This is large - 111k. It includes a loader, the DeskTop app (with both
main memory and aux memory segments, filling everything from $4000 to
$FFFF (except for I/O space and ProDOS), and still having more code -
probably the disk copy code which is swapped in dynamically.

The file is broken down into multiple segments:

* segment 0: load - address $2000-$257F, length $0580, file offset $000000 (Loader)
* segment 1: aux1 - address $4000-$BFFF, length $8000, file offset $000580 (A2D, part of DeskTop)
* segment 2: aux2 - address $D000-$ECFF, length $1D00, file offset $008580 (More of DeskTop)
* segment 3: aux3 - address $FB00-$FFFF, length $0500, file offset $00A280 (More of DeskTop)
* segment 4: main - address $4000-$BEFF, length $7F00, file offset $00A780 (More of DeskTop)
* segment 5: main - address $0800-$0FFF, length $0800, file offset $012680 (Initializer)
* segment 6: main - address $0290-$03EF, length $0160, file offset $012E80 (Invoker)
* segment N: _TBD_ - 38k so must be further subdivided. Disk Copy, and ...???

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

### GUI Library "A2D"

`a2d.s`

AUX $4000-$8DFF is the GUI library used for the DeskTop application
and (presumably) for disk copy and Selector apps (TBD).

Entry point is $4000 with a ProDOS MLI-style calling convention

* Font is at $8800

* Part of $8500-$87FF looks like part of "DeskTop" (see below), dealing with online volumes.

### "DeskTop" Application

`desktop.s`

DeskTop application code is in the lower 48k of both Aux and Main:

* Aux $8E00-$BFFF - sitting above the GUI library
* Main $4000-$BEFF

...and in the Aux language card area (accessible from both aux and main code) are relays, buffers and resources:

* Aux $D000-$ECFF - relays and other aux/main helpers, resources (menus, strings, window)
* Aux $ED00-$FAFF - hole for data buffer
* Aux $FB00-$FFFF - more resources (file types, icons)

($C000-$CFFF is reserved for I/O, and main $BF page and language card is ProDOS)


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
      |             |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
$8E00 |             |    +-------------+
      |             |    | A2D GUI     |
      |             |    | Library     |
      |             |    |             |
      |             |    |             |
      |             |    |             |
      |             |    |             |
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
      |             |    |             |
$2000 +-------------+    +-------------+
      | Initializer |    | Desk Acc    |
      | & Desk Acc  |    |             |
      |             |    |             |
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
