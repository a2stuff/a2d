Apple II DeskTop
================

A2DeskTop.po is an 800k image containing the full application and
all accessories. It can be transferred to an 3.5" floppy using ADTPro.

DeskTop.po, DeskAccessories.po and Preview.po are 140k images
containing different parts of the application, and can be trasnferred to
5.25" floppies using ADTPro.

Installation
------------

This is a ProDOS 8 application, and works best on a mass storage
device or at least an 800k floppy. Running from 140k is possible
(without desk accessories) but is not recommended.

An Apple II DeskTop installation has the following structure on a mass
storage device:

* `A2.DESKTOP/` - any name is allowed, can be in any subdirectory
  * `DESKTOP.SYSTEM` - invoked to launch DeskTop
  * `DESKTOP2` - application file
  * `DESK.ACC/` - contains Desk Accessories (DAs)
  * `PREVIEW/` - contains file preview handlers (special type of DAs)

At runtime, other files will be created within the application
directory:

* `QUIT.TMP` holds the original ProDOS quit routine.
* `SELECTOR.LIST` holds the Selector menu entries, which allow
   for quick launching of other applications.

Other Files
-----------

The `RAM.SYSTEM` file will create a RAM Disk on RamWorks drives. It can
be run manually before launching `DeskTop`

Tips and Tricks
---------------

You can use the Sort Directory DA to order the files, which controls
the menu order:

* Open the A2.DESKTOP/DESK.ACC folder
* Hold Open-Apple and click on each file in the desired order
* Select Sort Directory from the Apple menu, and verify the order
* Restart

Source code can be found at: https://github.com/inexorabletash/a2d
