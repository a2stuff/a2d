
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

* segment 0: load - offset $0000, length $0580, loaded at $2000
* segment 1: aux1 - offset $0580, length $8000, loaded at $4000 (through $BFFF)
* segment 2: aux2 - offset $8580, length $1D00, loaded at $D000 (through $ECFF)
* segment 3: aux2 - offset $A280, length $0500, loaded at $FB00 (through $FFFF)
* segment 4: main - offset $A780, length $7F00, loaded at $4000 (through $BEFF)
  * main $BF00-$BFFF is ProDOS buffers
  * main $C000-$CFFF is I/O space
  * main $D000-$FFFF is ProDOS
* segment 5: _TBD_ - 38k so must be further subdivided.

Much of the space is data:

* API jump table at $40E5, param details at $4184
* Font is at $8800

Icon bitmaps are at $FF00-ish (.SYSTEM file is $FF06), stride 5, $22x$11px
