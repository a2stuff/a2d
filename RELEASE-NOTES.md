# Apple II DeskTop

Home Page: https://a2desktop.com

Project Page: https://github.com/a2stuff/a2d

## 1.4 Alpha

### General

* Improve mouse responsiveness and event ordering.
* Prevent spurrious clicks following double-click.
* File Picker Dialog: Show watch cursor when polling all drives.
* Eliminate top level PREVIEW/ directory.
* IIgs: Reset video banking state on launch to prevent garbled screen. ([#764](https://github.com/a2stuff/a2d/issues/764))
* Improve wording and fix spelling/grammar mistakes in various strings.
* Added Dutch (`nl`) localization. ([#767](https://github.com/a2stuff/a2d/issues/767))
* Improve sound played when entering/exiting Mouse Keys mode.
* Improve window title bar apperance.
* Prevent scrollbar thumb jumping when not moved. ([#778](https://github.com/a2stuff/a2d/issues/778))
* Package now includes ProDOS 2.4.3 and BASIC.system 1.7.
* Improve appearance of buttons when clicked. c/o @buserror
* Fix corruption issues when replacing files with folders and folders with anything during copy.

### Launcher
* If starting from a folder, brand it as a system folder.
* Prevent crash or hang when quitting back to launcher on unsupported system.

### DeskTop

* Add file type string "LBR" for $E0 ("archival library")
* Show drag outlines even for icons outside visible area.
* Prevent crash launching program after previewing images. ([#765](https://github.com/a2stuff/a2d/issues/765))
* Filetype and support for Vortex Tracker PT3 files.
* Added an easter egg. Can you find it?
* Improve layout of Add/Edit a Shortcut dialog.
* Remove 12 volume limit from Format/Erase picker.
* Update label in Add/Edit a Shortcut dialog.
* Reduce drive poll frequency to ~0.33Hz for 1MHz systems.
* Fix tracking of Yes/No/All buttons in alerts.
* Add checkbox to lock/unlock file in Get Info dialog. (([#149](https://github.com/a2stuff/a2d/issues/149))
* Remove Special > Lock and Special > Unlock commands.
* Show icon for locked files in list views.
* Reorder columns in list views.
* Allow selection to remain in inactive windows.
* Fix off-by-one in used/free values in window headers.
* Fix updating of window headers following File > New Folder.
* Select new file after File > Duplicate...
* Improve menu item names for Format, Erase and Copy Disk.
* Fix refreshing volume icon after Format/Erase.
* Show special icon for folders with AuxType $8000.
* Show progress bar during copy and delete operations.
* Click on menu bar clock now shows Date & Time DA.
* Refresh correct window after renaming an icon, if view is by name.
* Fix corruption when exiting Shortcuts dialogs with a list view window. (([#790](https://github.com/a2stuff/a2d/issues/790))
* Clear GS/OS "case bits" when renaming files/volumes. (([#352](https://github.com/a2stuff/a2d/issues/352))
* Preserve GS/OS "case bits" when copying files. (([#352](https://github.com/a2stuff/a2d/issues/352))

### Selector

* Selector is now named "Shortcuts" in UI strings.
* Errors encountered when copying to RAMCard now show standard alerts.
* Fully clear and reset text screen when quick-booting from a slot.
* Show progress bar while copying shortcut to RAMCard.
* Prevent crash on IIc+ under ProDOS 2.4.3. ([#789](https://github.com/a2stuff/a2d/issues/789))

### Disk Copy

* Ensure /RAM is correctly restored after exiting. ([#766](https://github.com/a2stuff/a2d/issues/766))
* Re-verify block counts when Read Drives is clicked, so correct destination drives are shown.
* Hide "Select Quit..." once menu is not accessible.
* Show correct block counts during Quick Copy.
* Show progress bar during copy.
* Show ProDOS volume names with GS/OS "case bits", if present. ([#428](https://github.com/a2stuff/a2d/issues/428))

### Desk Accessories

* Sort Directory: Correctly order SYS files with ".SYSTEM" suffix. ([#762](https://github.com/a2stuff/a2d/issues/762))
* This Apple:
  * Detect Grappler, ThunderClock, Apple-CAT, and Workstation card.
  * Detect NVRAM and BOOTI block devices.
  * Prevent hang on IIc and IIc+ in MAME.
  * Detect ZIP CHIP accelerator.
  * Display larger memory sizes in MB.
* Image Preview
  * Add slideshow mode - press 'S' to auto-advance images.
  * Add support for LZ4FH-compressed files. (https://github.com/fadden/fhpack)
  * Packed Super Hi-Res PNT files ($C0/$0001) can be previewed on Apple IIgs.
* Text Preview
  * Fix memory corruption causing incorrect line display. ([#770](https://github.com/a2stuff/a2d/issues/770))
  * Align Proportional/Fixed text with window title. ([#787](https://github.com/a2stuff/a2d/issues/787))
* System Speed: Add support for Titan Accelerator IIe c/o @buserror.
* Sounds
  * Add Cancel button c/o @buserror.
  * Add several new sounds c/o@ frankmilliron.
* New DA: Change Type - allows changing the type and auxtype of files. (([#149](https://github.com/a2stuff/a2d/issues/149))
* Control Panel: Show shortcut keys for buttons (if that option is enabled).
* Date & Time: Show shortcut keys for buttons (if that option is enabled).
* Map
  * Show shortcut key for button (if that option is enabled).
  * Larger map image is shown.
* Matrix: Show green-on-black text on IIgs.
* New Screen Saver: Helix.
* Electric Duet Preview: Detect Mockingboard and The Cricket!, and use for playback if found.
* New DA: Benchmark - measures CPU speed using VBL.
* New Screen Saver: Message


### Misc

* Add additional MGTK fonts Fairfax, Magdalena, McMillen, Mischke, and Monterey, c/o RebeccaRGB.
* Improve compatibility with older AppleWorks files.


## 1.3

An unofficial release with bug fixes and enhancements. July 1, 2023.

See the release notes at:
https://github.com/a2stuff/a2d/blob/release-1.3/RELEASE-NOTES.md

## 1.2

An unofficial release with bug fixes and enhancements. December 28, 2022.

See the release notes at:
https://github.com/a2stuff/a2d/blob/release-1.2/RELEASE-NOTES.md

## 1.1

Final release by Version Soft/Apple Computer dated November 26, 1986.

See also:

* Jay Edwards' [Mouse Desk/DeskTop History](https://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Misc/mousedesk.info)
* https://www.a2desktop.com/history
