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

### Launcher

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

### Selector

* Selector is now named "Shortcuts" in UI strings.
* Errors encountered when copying to RAMCard now show standard alerts.
* Fully clear and reset text screen when quick-booting from a slot.

### Disk Copy

* Ensure /RAM is correctly restored after exiting. ([#766](https://github.com/a2stuff/a2d/issues/766))
* Re-verify block counts when Read Drives is clicked, so correct desination drives are shown.

### Desk Accessories

* Sort Directory: Correctly order SYS files with ".SYSTEM" suffix. ([#762](https://github.com/a2stuff/a2d/issues/762))
* This Apple:
  * Detect Grappler, ThunderClock, Apple-CAT, and Workstation card.
  * Detect NVRAM and BOOTI block devices.
  * Prevent hang on IIc and IIc+ in MAME.
* Image Preview: Add slideshow mode - press 'S' to auto-advance images.
* Text Preview: Fix memory corruption causing incorrect line display. ([#770](https://github.com/a2stuff/a2d/issues/770))
* System Speed: Add support for Titan Accelerator IIe c/o @buserror.
* Sounds: Add Cancel button c/o @buserror.

### Misc

* Add additional MGTK fonts Fairfax, Magdalena, McMillen, Mischke, and Monterey, c/o RebeccaRGB.


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
