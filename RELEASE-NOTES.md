# Apple II DeskTop

Home Page: https://a2desktop.com

Project Page: https://github.com/a2stuff/a2d

## 1.4

### General

* Improve mouse responsiveness and event ordering.
* Prevent spurrious clicks following double-click.
* File Picker Dialog: Show watch cursor when polling all drives.
* IIgs: Reset video banking state on launch to prevent garbled screen. ([#764](https://github.com/a2stuff/a2d/issues/764))
* Improve wording and fix spelling/grammar mistakes in various strings.
* Added Dutch (`nl`) localization. ([#767](https://github.com/a2stuff/a2d/issues/767))
* Improve sound played when entering/exiting Mouse Keys mode.
* Improve window title bar apperance.
* Prevent scrollbar thumb jumping when not moved. ([#778](https://github.com/a2stuff/a2d/issues/778))
* Package now includes ProDOS 2.4.3 and BASIC.system 1.7.
* Improve appearance of buttons when clicked. c/o @buserror
* Reduce vertical spacing between menu items. ([#794](https://github.com/a2stuff/a2d/issues/794))
* Include all code page fonts for System and Monaco in packages.
* Fix width of 'ö' and 'ü' in German System font, 'ö' in Swedish System font.
* Fix '9' glyph in System and Monaco fonts.
* Add additional MGTK fonts Fairfax, Magdalena, McMillen, Mischke, and Monterey, c/o @RebeccaRGB.
* Add Quark Catalyst font, c/o @eric-ja.
* Improve compatibility with older AppleWorks files, c/o Hugh Hood.

### Launcher

* If starting from a folder, brand it as a system folder (AuxType $8000).
* Prevent crash or hang when quitting back to launcher on unsupported system.

### DeskTop

#### Enhanced Features

* Remove 12 volume limit from Format/Erase picker.
* Improve layout of Add/Edit a Shortcut dialog.
* Update label in Add/Edit a Shortcut dialog.
* Add checkbox to lock/unlock file in Get Info dialog. ([#149](https://github.com/a2stuff/a2d/issues/149))
* Remove Special > Lock and Special > Unlock commands.
* Reorder columns in list views.
* Allow selection to remain in inactive windows. ([#361](https://github.com/a2stuff/a2d/issues/361))
* Improve menu item names for Format, Erase and Copy Disk.
* Show progress bar during copy and delete operations.
* Click on menu bar clock now shows Date & Time DA.
* Increase number of items that can be added to the Apple Menu to 13.
* Added an easter egg. Can you find it?

#### Disks & Files

* Add file type string "LBR" for $E0 ("archival library")
* Filetype and support for Vortex Tracker PT3 files.
* Show drag outlines even for icons outside visible area.
* Show icon for locked files in list views.
* Show special icon for folders with AuxType $8000.
* Update GS/OS "case bits" when renaming files/volumes. ([#352](https://github.com/a2stuff/a2d/issues/352))
* Preserve GS/OS "case bits" when copying files. ([#352](https://github.com/a2stuff/a2d/issues/352))
* File > Rename is now modeless, and can be invoked by clicking a selected icon's name. ([#203](https://github.com/a2stuff/a2d/issues/203))
* File > New Folder now creates a directory called "New.Folder", then prompts to rename it.
* File > Duplicate now copies the selected file, then prompts to rename it.
* Pbageby Bcra-Nccyr Fbyvq-Nccyr S.

#### Performance & Fixes

* Prevent crash launching program after previewing images. ([#765](https://github.com/a2stuff/a2d/issues/765))
* Reduce drive poll frequency to ~0.33Hz for 1MHz systems.
* Fix tracking of Yes/No/All buttons in alerts.
* Fix off-by-one in used/free values in window headers.
* Fix updating of window headers following File > New Folder.
* Fix refreshing volume icon after Format/Erase.
* Refresh correct window after renaming an icon, if view is by name.
* Fix corruption when exiting Shortcuts dialogs with a list view window. ([#790](https://github.com/a2stuff/a2d/issues/790))
* Don't close File > Rename and File > Duplicate prompt if path is too long.
* Fix corruption issues when replacing files with folders and folders with anything during copy.
* Fix initial window size calculation for list views so scrollbar is not shown. ([#792](https://github.com/a2stuff/a2d/issues/792))

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

#### New Accessories

* Benchmark - measures CPU speed using VBL.
* Change Type - allows changing the type and auxtype of files. ([#149](https://github.com/a2stuff/a2d/issues/149))
* Round Corners - temporarily makes the corners of the screen rounded.
* Screen Saver: Helix.
* Screen Saver: Message

#### Preview Updates

* Image Preview
  * Add slideshow mode - press 'S' to auto-advance images.
  * Add support for LZ4FH-compressed files. (https://github.com/fadden/fhpack)
  * IIgs: Add support for Packed Super Hi-Res PNT files ($C0/$0001).
* Text Preview
  * Fix memory corruption causing incorrect line display. ([#770](https://github.com/a2stuff/a2d/issues/770))
  * Align Proportional/Fixed text with window title. ([#787](https://github.com/a2stuff/a2d/issues/787))
* Electric Duet Preview: Detect Mockingboard and The Cricket!, and use for playback if found.
* Eliminate top level PREVIEW/ directory.

#### Control Panel Updates

* Control Panel: Show shortcut keys for buttons (if that option is enabled).
* Date & Time: Show shortcut keys for buttons (if that option is enabled).
* Sounds
  * Add Cancel button c/o @buserror.
  * Add several new sounds c/o @frankmilliron.
* Options: Add setting to preserve upper/lowercase when naming files and volumes. ([#352](https://github.com/a2stuff/a2d/issues/352))
* System Speed: Add support for Titan Accelerator IIe c/o @buserror.
* Map
  * Show shortcut key for button (if that option is enabled).
  * Larger map image is shown.

#### Other Accessory Updates

* Sort Directory: Correctly order SYS files with ".SYSTEM" suffix. ([#762](https://github.com/a2stuff/a2d/issues/762))
* This Apple:
  * Detect Grappler, ThunderClock, Apple-CAT, and Workstation card.
  * Detect NVRAM and BOOTI block devices.
  * Prevent hang on IIc and IIc+ in MAME.
  * Detect ZIP CHIP accelerator.
  * Display larger memory sizes in MB.
  * Round up bank counts from Slinky memory if needed.
* Matrix: Show green-on-black text on IIgs.
* Screen Dump: Improve output aspect ratio.


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
