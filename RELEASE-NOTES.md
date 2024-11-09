# Apple II DeskTop

Home Page: https://a2desktop.com

Project Page: https://github.com/a2stuff/a2d

## 1.5 Alpha

### General

* Correctly exit 80-column firmware when exiting.
* Option "Copy to RAMCard" now defaults to off.
* Option "Preserve uppercase and lowercase in names" no defaults to on.

### Launcher

* Don't trust a partial copy of DeskTop on RAMCard; use DESKTOP.SYSTEM itself as a sentinel.
* If running from a RAMCard, don't try to copy DeskTop to it.

### DeskTop

* Don't always select window's icon after refresh (just usually)
* When closing window, select volume icon if folder icon absent.
* Ignore non-alpha character typed at start when naming file/volume.
* Hold either Apple key when selecting File > Close to Close All.
* Fix Apple+O to not "Open and Close" when menu already showing. ([#796](https://github.com/a2stuff/a2d/issues/796))
* Show tip about copying PRODOS during Format/Erase process.
* Arrow keys now move icon selection in appropriate direction. ([#300](https://github.com/a2stuff/a2d/issues/300))
* More consistently refresh (or don't refresh) window contents after canceled or failed operations.
* Special > Make Alias now creates link file in same directory as original.
* Add Edit menu with Cut/Copy/Paste/Clear, relocate Select All.
* Ensure the modification date for copied folders matches the original.
* Prompt to re-insert system disk when launching Apple Menu items.

### Selector

### Disk Copy

### Desk Accessories

* About This Apple II
  * Detect Microdigital TK-3000 //e
  * Detect Pravetz 8A/C
* Screen Dump: Improve use of SSC and IW2.
* Print Catalog: Improve use of SSC and IW2.
* Options: Add option to show invisible files.
* Calendar: Allow modifiers when clicking, double-modifiers for decade. ([#693](https://github.com/a2stuff/a2d/issues/693))

## 1.4

An unofficial release with bug fixes and enhancements. July 28, 2024.

See the release notes at:
https://github.com/a2stuff/a2d/blob/release-1.4/RELEASE-NOTES.md

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
