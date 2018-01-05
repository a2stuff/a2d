
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

* segment 0: load - address $2000-$257F, length $0580, file offset $000000
* segment 1: aux1 - address $4000-$BFFF, length $8000, file offset $000580
* segment 2: aux2 - address $D000-$ECFF, length $1D00, file offset $008580
* segment 3: aux3 - address $FB00-$FFFF, length $0500, file offset $00A280
* segment 4: main - address $4000-$BEFF, length $7F00, file offset $00A780
* segment 5: main - address $0800-$0FFF, length $0800, file offset $012680
* segment 6: main - address $0290-$03EF, length $0160, file offset $012E80

* segment N: _TBD_ - 38k so must be further subdivided. Disk Copy???

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

There's fourth chunk of code; it's unclear where that ends up or how
it is invoked, but it appears to handle an OpenApple+ClosedApple+P
key sequence and invoke slot one code - possibly debugging support?

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
       Main              Aux               ROM
$FFFF +------------+    +------------+    +------------+
      | ProDOS     |    | DeskTop    |    | Monitor    |
$F800 |            |    | Resources/ |    +------------+
      |            |    | Buffers    |    | Applesoft  |
      |            |    |            |    |            |
      |            |    |            |    |            |
      |            |    |            |    |            |
$D000 +------------+    +------------+    +------------+    +------------+
                                                            | I/O        |
                                                            |            |
$C000 +------------+    +------------+                      +------------+
      | ProDOS     |    | DeskTop    |
$BF00 +------------+    | App Code   |
      | DeskTop    |    |            |
      | App Code   |    |            |
      |            |    |            |
      |            |    |            |
      |            |    |            |
      |            |    |            |
      |            |    |            |
$8E00 |            |    +------------+
      |            |    | A2D GUI    |
      |            |    | Library    |
      |            |    |            |
      |            |    |            |
      |            |    |            |
      |            |    |            |
      |            |    |            |
      |            |    |            |
$4000 +------------+    +------------+
      | Graphics   |    | Graphics   |
      |            |    |            |
      |            |    |            |
      |            |    |            |
      |            |    |            |
      |            |    |            |
      |            |    |            |
      |            |    |            |
$2000 +------------+    +------------+
      | Init &     |    | Desk Acc   |
      | Desk Acc   |    |            |
      |            |    |            |
$0800 +------------+    +------------+
      | Text       |    | Text       |
$0400 +------------+    +------------+
      |            |    |            |
$0300 +------------+    +------------+
      | Input Buf  |    | Input Buf  |
$0200 +------------+    +------------+
      | Stack      |    | Stack      |
$0100 +------------+    +------------+
      | Zero Page  |    | Zero Page  |
$0000 +------------+    +------------+
```
