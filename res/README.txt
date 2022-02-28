Apple II DeskTop
================

A2DeskTop-1.2-..._800k.2mg and .hdv files are 800k images containing
the full application and all accessories. The .2mg file can be
transferred to a 3.5" floppy using ADTPro. The .hdv file has the same
contents, just a slightly different file format which other
tools/emulators/solid state drives prefer.

A2DeskTop-1.2-..._140k_disk1.po and A2DeskTop-1.2-..._140k_disk2.po
are 140k images containing different parts of the application, and can
be transferred to 5.25" floppies using ADTPro.


Documentation
-------------

See https://a2desktop.com for more information.

Source code can be found at: https://github.com/a2stuff/a2d


Installation
------------

This is a ProDOS 8 application. It works best on a mass storage
device, or at least an 800k floppy. Running from a 140k floppy is
possible (without desk accessories) but is not recommended.

An Apple II DeskTop installation has the following structure on a mass
storage device:

* `A2.DESKTOP/` - any name is allowed, can be in any subdirectory
  * `DESKTOP.SYSTEM` - run this to launch DeskTop
  * `DESKTOP2` - application file
  * `SELECTOR` - application file (enable in Startup Options)
  * `DESK.ACC/` - contains Desk Accessories (DAs), including Control Panels
  * `PREVIEW/` - contains file preview handlers (special type of DAs)
  * `EXTRAS/` - contains additional utilities
