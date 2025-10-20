# Apple II DeskTop

Home Page: https://a2desktop.com

Project Page: https://github.com/a2stuff/a2d

## 1.5 Alpha

### General

* Correctly exit 80-column firmware when quitting.
* Option "Copy to RAMCard" now defaults to off.
* Option "Preserve uppercase and lowercase in names" now defaults to on.
* Hide "invisible" files in file dialogs by default.
* New localization: Bulgarian
* ProDOS "sparse" files are now copied correctly. ([#878](https://github.com/a2stuff/a2d/issues/878))
* Issue ON_LINE call after disconnecting /RAM.

### Launcher

* Don't trust a partial copy of DeskTop on RAMCard; use DESKTOP.SYSTEM itself as a sentinel.
* If running from a RAMCard, don't try to copy DeskTop to it.
* Consume Esc keypress when canceling shortcut copy to RAMCard. ([#868](https://github.com/a2stuff/a2d/issues/868))

### DeskTop

* Don't always select window's icon after refresh (just usually)
* When closing window, select volume icon if folder icon absent.
* Ignore non-alpha character typed at start when naming file/volume.
* Hold either Apple key when selecting File > Close to Close All.
* Fix Apple+O to not "Open and Close" when menu already showing. ([#796](https://github.com/a2stuff/a2d/issues/796))
* Show tip about copying `PRODOS` during Format/Erase process.
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
* Enable OK button in File > Copy To... when a volume is selected as the target. ([#851](https://github.com/a2stuff/a2d/issues/851))
* Dragging and dropping a file within the same window while holding either Apple key now duplicates it. ([#837](https://github.com/a2stuff/a2d/issues/837))
* Dragging and dropping a file with both Apple keys down now creates alias. ([#838](https://github.com/a2stuff/a2d/issues/838))
* Fix memory corruption causing operations on 8th window to fail.
* Added Special > Show Original command for inspecting aliases. ([#811](https://github.com/a2stuff/a2d/issues/811))
* Create containing folder when copying volume to another disk. ([#846](https://github.com/a2stuff/a2d/issues/846))
* Show "Yesterday" and "Tomorrow" when appropriate in file dates. ([#836](https://github.com/a2stuff/a2d/issues/836))
* Prevent initiating rename of Trash icon. ([#871](https://github.com/a2stuff/a2d/issues/871))
* Disallow creating a shortcut for an alias copied to RAMCard.
* Support dragging from inactive windows. ([#353](https://github.com/a2stuff/a2d/issues/353))
* Improve rendering of overlapping icons. ([#875](https://github.com/a2stuff/a2d/issues/875))
* Improve the appearance of the Trash icon.
* Ignore suffix when determining icon type for directories.
* Improve mouse responsiveness while list views are drawn.
* Prevent crash after clicking Cancel if `LOCAL/SELECTOR.LIST` is unavailable.
* Show error when unable to move shortcut to "list only".
* Draw volume icons during load/check for better feedback.
* Improve startup time by creating `LOCAL/SELECTOR.LIST` lazily.
* Fix restoring a volume window named "Trash".
* Fix behavior after Special > Check Drive with non-ProDOS disks.
* Fix locking/unlocking directories.
* Fix capacity check when copying a volume.
* Fix copying of files when disk swapping is required.
* Fix memory corruption following multi-select.
* Improve type-down selection and sorted view performance.
* Fix some edge cases around modified selection.
* Performance improvements for scrolling and selection.

### Selector

* Prevent crash after alert is shown from File > Run a Program... ([#832](https://github.com/a2stuff/a2d/issues/832))
* Ellipsify long paths in "Copying to RAMCard..." dialog. ([#867](https://github.com/a2stuff/a2d/issues/867))
* Support launching aliases. ([#880](https://github.com/a2stuff/a2d/issues/880))
* Disable OK in File > Run a Program.... if folder selected. ([#888](https://github.com/a2stuff/a2d/issues/888))
* Support launching Integer BASIC programs. ([#879](https://github.com/a2stuff/a2d/issues/879))
* Support launching AppleWorks files. ([#879](https://github.com/a2stuff/a2d/issues/879))

### Disk Copy

* Preselect volume if one was selected in DeskTop. ([#849](https://github.com/a2stuff/a2d/issues/849))
* Simplify/improve naming/prompts for DOS 3.3 disks.

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
  * Show modification date.
* Options: Add option to show invisible files.
* Calendar:
  * Allow modifiers when clicking, double-modifiers for decade. ([#693](https://github.com/a2stuff/a2d/issues/693))
  * Follow "first day of week" setting in Control Panel > International.
* Show Image File: Allow 'S' to toggle slideshow off. ([#825](https://github.com/a2stuff/a2d/issues/825))
* Find Files
  * Make mouse cursor responsive during iteration.
  * Prevent crash on overly long paths.
* Date and Time
  * Refresh windows if 12/24-hour setting changes. ([#835](https://github.com/a2stuff/a2d/issues/835))
  * Refresh windows if date changes. ([#843](https://github.com/a2stuff/a2d/issues/843))
* International: Add "first day of week" setting.
* Benchmark: Don't overflow meter if over 16MHz.
* Map
  * Fix indicator updated after window is moved.
  * Support Apple-Arrow keys in edit box.
  * Prevent mispaint when deleting if obscured.
* Text Preview: Fix scrollbar behavior when toggling fixed/proportional.
* Image Preview: Support lo-res and double lo-res graphics files.
* Change Type: Prevent modifying directories.
* New DA (in Extras): "Screenshot" - saves screenshot file to application directory.
* New DA (in Extras): "DOS33.Import" - allows importing files from DOS 3.3 disks.
* New DA (in Control Panels): "Views" - allows setting the default view style.
* New DA (in Toys): "Lights Out" game.
* New DA (in Toys): "Bounce".
* New DA (in Screen Savers): "Random" - runs a random screen saver.

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
