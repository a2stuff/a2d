# Apple II DeskTop

Home Page: https://a2desktop.com

Project Page: https://github.com/a2stuff/a2d

## 1.5 Alpha

### General

* Correctly exit 80-column firmware when exiting.
* Option "Copy to RAMCard" now defaults to off.
* Option "Preserve uppercase and lowercase in names" no defaults to on.
* Hide "invisible" files in file dialogs by default.
* New localization: Bulgarian

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
* Add Text-to-Speech file type ($D9) and icon.
* Ensure DHIRES mode is exited when exiting to BASIC.
* Fix clipping bug when icon is underneath aligned right edges of two windows.
* Fix clipping bug when icon's middle is obscured by overlapping windows.
* Improve adding/editing shortcuts for volumes. ([#831](https://github.com/a2stuff/a2d/issues/831))
* Enable File > Copy To... for volume icons. ([#830](https://github.com/a2stuff/a2d/issues/830))
* Dragging and dropping a file within the same window while holding either Apple key now duplicates it. ([#837](https://github.com/a2stuff/a2d/issues/837))
* Dragging and dropping a file with both Apple keys down now creates alias. ([#838](https://github.com/a2stuff/a2d/issues/838))
* Fix memory corruption causing operations on 8th window to fail.
* Added Special > Show Original command for inspecting aliases. ([#811](https://github.com/a2stuff/a2d/issues/811))
* Create containing folder when copying volume to another disk. ([#846](https://github.com/a2stuff/a2d/issues/846))

### Selector

* Prevent crash after alert is shown from File > Run a Program... ([#832](https://github.com/a2stuff/a2d/issues/832))

### Disk Copy

### Desk Accessories

* About This Apple II
  * Detect Microdigital TK-3000 //e.
  * Detect Pravetz 8A/C.
  * Detect Passport MIDI card.
  * Detect Xdrive card. ([#841](https://github.com/a2stuff/a2d/issues/841))
  * Show duplicate SmartPort device names with counts.
* Print Screen
  * Renamed from "Screen Dump"
  * Improve use of SSC and IW2.
  * Show alert on startup if no SSC found.
  * Don't corrupt "File" on menu bar. ([#810](https://github.com/a2stuff/a2d/issues/810))
* Print Catalog
  * Improve use of SSC and IW2.
  * Show alert on startup if no printer card found.
* Options: Add option to show invisible files.
* Calendar:
  * Allow modifiers when clicking, double-modifiers for decade. ([#693](https://github.com/a2stuff/a2d/issues/693))
  * Follow "first day of week" setting in Control Panel > International.
* Show Image File: Allow 'S' to toggle slideshow off. ([#825](https://github.com/a2stuff/a2d/issues/825))
* Find Files: Make mouse cursor responsive during iteration.
* Date and Time:
  * Refresh windows if 12/24-hour setting changes. ([#835](https://github.com/a2stuff/a2d/issues/835))
  * Refresh windows if date changes. ([#843](https://github.com/a2stuff/a2d/issues/843))
* International: Add "first day of week" setting.
* New DA (in Extras): "Screenshot" - saves screenshot file to application directory.
* New DA (in Extras): "DOS33.Import" - allows importing files from DOS 3.3 disks.
* New DA (in Control Panels): "Views" - allows setting the default view style.

### Misc

* Add TTS.system (and SAM) for playing "speech" files.

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
