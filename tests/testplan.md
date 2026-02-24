# Release Qualification Test Cases

Most tests have now been automated. This document captures tests that must be run manually (for now at least).

> Status: Work in Progress

The `/TESTS` volume can be found as `tests/images/tests.hdv` in the repo. Test cases should start with a fresh copy of this volume, as some cases will modify the volume.

When steps say to a path e.g. `/TESTS/FOLDER/SUBFOLDER`, open the volume then each subsequent folder, leaving intermediate windows open.

## Launcher

> Coverage in `tests/launcher/`

## DeskTop

> Coverage in `tests/desktop/`

The following tests have not (yet) been automated because the Escape key conflicts with exiting Mouse Keys mode.

* Launch DeskTop. Select a volume icon. Drag it over an empty space on the desktop. Without releasing the mouse button, press the Escape key. Verify that the drag is canceled and the icon does not move.
> This can not be (currently) tested in MAME.

* Launch DeskTop. Select a volume icon. Drag it over another icon on the desktop, which should highlight. Without releasing the mouse button, press the Escape key. Verify that the drag is canceled, the target icon is unhighlighted, and the dragged icon does not move.
> This can not be (currently) tested in MAME.

* Launch DeskTop. Select a file icon. Drag it over an empty space in the window. Without releasing the mouse button, press the Escape key. Verify that the drag is canceled and the icon does not move.
> This can not be (currently) tested in MAME.

* Launch DeskTop. Select a file icon. Drag it over a folder icon, which should highlight. Without releasing the mouse button, press the Escape key. Verify that the drag is canceled, the target icon is unhighlighted, and the dragged icon does not move.
> This can not be (currently) tested in MAME.

* Use real hardware, not an emulator. Launch DeskTop. Select a volume icon. File > Get Info. Verify that a "The specified path name is invalid." alert is not shown.
> This can not be (currently) tested in MAME.

## Shortcuts (Module)

> Coverage in `tests/selector/`

## Disk Copy (Module)

> Coverage in `tests/disk_copy/`

* Configure Virtual II with two OmniDisks formatted as ProDOS volumes mounted. Launch DeskTop. Special > Copy Disk.... Select the  OmniDisks as Source and Destination. Verify that after being prompted to insert the source and destination disks, a "Are you sure  you want to erase ...?" confirmation prompt is shown.
> NOTE: See fd51f6d - the issue is that Virtual ][ OmniDisks do not report support for formatting.
> This can not be (currently) tested in MAME.

## Desk Accessories

> Coverage in `tests/desk_acc`

### About This Apple II

* Configure a IIe system with a 16MB RAMFactor card (e.g. GR8RAM from https://garrettsworkshop.com/) with a single 16MB partition. Apple > About This Apple II. Verify that the calculated memory size is accurate, i.e. it is not off by 64k.
> This can not be (currently) tested in MAME.

### Calculator & Sci.Calc

* Slow any acceleration. Position the cursor over the 1px border of various buttons, all 4 edges. Press the mouse button. Verify the button inverts. Drag in and outside the button. Verify that the button is inverted on the 1px border and within, not inverted inside. Verify that the button does not flash but stays inverted until the button is released. Note that the 1px shadow on the right and bottom is not considered part of the button.
> This can not be (currently) tested in MAME.

### Puzzle

* Launch DeskTop. Apple Menu > Puzzle. Scramble then solve the puzzle. After the victory sound plays, click on the puzzle again. Verify that the puzzle scrambles and that it can be solved again.
> Solving the puzzle is beyond the scope of automated testing.

### Print Screen

* Configure a system with an SSC in Slot 1 and an ImageWriter II. Invoke the Print Screen DA. Verify it prints a screenshot.
> This can not be (currently) tested in MAME.

* Configure a system with an SSC in Slot 1 and an ImageWriter II. Invoke the Print Screen DA. Invoke the Print Catalog DA. Verify that the catalog is printed on separate lines, not all overprinted on the same line onto one.
> This can not be (currently) tested in MAME.

* Using MAME (e.g. via Ample), configure a system with an SSC in Slot 1 and a Serial Printer. Invoke the Print Screen DA. Verify that the File menu is not corrupted.
> This can not be (currently) tested in MAME.

### Control Panels

Repeat for each of:
* Control Panel
* Date & Time
* International
* Options
* Sounds
* Views

* Start with a fresh disk image. Launch DeskTop. Apple Menu > Control Panels. Open the DA. Toggle a setting. Close the DA. Write protect the disk. Then:
  * Open the DA. Toggle a setting. Close the DA. Verify an alert shows asking about saving the changes. Click Cancel. Open the DA. Verify the DA opens correctly. Close the DA.
  * Open the DA. Toggle a setting. Close the DA. Verify an alert shows asking about saving the changes. Click OK. Verify an alert shows that the disk is write protected. Click Try Again. Verify the same alert shows. Click Cancel.
  * Open the DA. Toggle a setting. Close the DA. Verify an alert shows asking about saving the changes. Click OK. Verify an alert shows that the disk is write protected. Click Try Again. Verify the same alert shows. Un-protect the disk. Click Try Again. Verify the settings are saved.

> This can not be (currently) tested in MAME. (A write-protected disk can be emulated by providing a ZIP file containing the image, but dynamically toggling the protection state is TBD.)

## Hardware Configurations

> Coverage throughout `tests` where possible

### SmartPort

* With a Floppy Emu in SmartPort mode, ensure that the 32MB image shows up as an option.
> This can not be (currently) tested in MAME.

### Z80 Card

* Configure a system with a Z80 card and without a No-Slot Clock. Boot a package disk including the CLOCK.SYSTEM driver. Verify that it doesn't hang.
> This can not be (currently) tested in MAME.

### Apple IIgs

* On the KEGS, GSport or GSplus IIgs emulators, launch DeskTop. Verify the emulator does not crash.
> This can not be (currently) tested in MAME.

* On the Crossrunner IIgs emulator, launch DeskTop. Verify it does not hang on startup.
> This can not be (currently) tested in MAME.

### Apple IIc+

* Run DeskTop on a IIc+ from a 3.5" floppy on internal drive. Verify that the disk doesn't spin constantly.
> This can not be (currently) tested in MAME.

### Laser 128

* Run on Laser 128; verify that 800k image files on Floppy Emu show as 3.5" floppy icons.
> This can not be (currently) tested in MAME.

* Run on Laser 128, with a Floppy Emu. Select a volume icon. Special > Eject Disk. Verify that the Floppy Emu does not crash.
> This can not be (currently) tested in MAME.

* Run on Laser 128. Launch DeskTop. Open a volume. Click on icons one by one. Verify selection changes from icon to icon, and isn't extended as if a Open-Apple key/button or Shift is down.
> This can not be (currently) tested in MAME.

* Run on Laser 128EX at 3.6MHz and multiple SmartPort devices. Launch DeskTop. Move the mouse for several seconds. Verify that the system does not hang.
> This can not be (currently) tested in MAME.

### Macintosh IIe Option Card

* Run on a Macintosh equipped with the IIe Option Card. Verify that DeskTop runs and the system does not hang.
> This can not be (currently) tested in MAME.

## Localization

Repeat these tests for all language builds:

* Launch DeskTop. Click the Apple Menu. Verify that no screen corruption occurs.
* Launch DeskTop. Click the Shortcuts menu. Verify that no screen corruption occurs.
* Launch DeskTop. Select a file. File > Copy To.... Verify that directories appear within volumes.

## Performance

For the following tests, run on non-IIgs system with any acceleration disabled.

* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Click the down arrow in the vertical scroll bar. Verify that the window repaints in under 1s, and that the mouse cursor remains responsive.
* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Press Apple-A to Select All. Verify that the visible icons all become selected in under 1s, and that the mouse cursor remains responsive. Click a blank area within the window to clear selection. Verify that the visible icons all become selected in under 1s, and that the mouse cursor remains responsive.
* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Type `F`. Verify that icon `F1` becomes selected in under 2s. Without moving the mouse, type `9`. Verify that icon `F9` becomes selected in under 1s. Without moving the mouse, type `9`. Verify that icon `F99` becomes selected and scrolled into view in under 2s.
* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Press the Left Arrow key. Verify that icon `F1` becomes selected. Use the arrow keys to move selection. Verify that changing selection takes under 0.5s when scrolling is not required.
* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Drag a select rectangle around all the visible icons in the window. Verify that the icons all become selected in under 1s, and that the mouse cursor remains responsive.

* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Verify that the mouse cursor doesn't flicker as icons far away from the cursor are drawn.
* Launch DeskTop. Click on the desktop, away from any icons. Verify that the mouse cursor doesn't flicker.
* Launch DeskTop. Click on in a window, away from any icons. Verify that the mouse cursor doesn't flicker.
