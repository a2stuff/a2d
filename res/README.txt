Apple II DeskTop
================

A2DeskTop .2mg and .hdv files are disk images containing the full
application and all accessories. The .2mg file can be transferred to a
3.5" floppy using ADTPro. The .hdv file has the same contents, just a
slightly different file format which other tools/emulators/solid state
drives prefer, and is a 32 MB image so you have plenty of space to
copy other things onto the disk.

A2DeskTop...140k_disk1.po, ...disk2.po and ...disk3.po are 140k images
containing different parts of the application, and can be transferred
to 5.25" floppies using ADTPro.


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
  * `MODULES/` - contains parts of the application
    * `DESKTOP` - application file
    * `DISK.COPY` - application file
    * `SELECTOR` - application file
    * ... and the `THIS.APPLE` DA plus Preview Accessories
  * `APPLE.MENU/` - contains Desk Accessories (DAs)
    * `CONTROL.PANELS/` - DAs for modifying DeskTop settings
    * `SCREEN.SAVERS/` - DAs that provide full-screen entertainment
  * `EXTRAS/` - contains additional utilities
  * `LOCAL/` - contains files created at runtime (settings, etc)
