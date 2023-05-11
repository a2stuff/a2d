# Apple II DeskTop

Home Page: https://a2desktop.com

Project Page: https://github.com/a2stuff/a2d

## 1.3 Alpha

### General

* File picker dialogs no longer show paths. ([#699](https://github.com/a2stuff/a2d/issues/699))
* File picker dialogs show drives list. ([#599](https://github.com/a2stuff/a2d/issues/599))
* Language-specific time separators added.
* IIgs and Laser 128: Fix alert sound playback speed.
* A generic ProDOS clock driver is included in disk images.
* The default double-click speed is now the middle setting.
* Button appearance simplified. Showing shortcuts can be enabled with an option.
* Reset text window correctly when exiting/launching other programs.
* Visually center window title bar text. ([#744](https://github.com/a2stuff/a2d/issues/744))
* Menu separators more vertically centered.
* Prevent erratic behavior if keys pressed during menu selection.
* Allow keyboard control of menus even when initiated with the mouse. ([#754](https://github.com/a2stuff/a2d/issues/754))
* Prevent keyboard cursor movement within disabled menus.
* Don't move cursor when controlling menu with keyboard. ([#756](https://github.com/a2stuff/a2d/issues/756))

### Launcher

* Ensure DeskTop is correctly detected on RAMCard when re-launched.
* Allow pressing Escape to cancel copy to RAMCard.
* Handle launching with PREFIX not set to DeskTop's directory.

### DeskTop

#### Enhanced Features

* Support selection in list views. ([#28](https://github.com/a2stuff/a2d/issues/28))
* Simplify list views by omitting directory file sizes.
* Show file sizes right aligned in list views.
* Show file sizes under 10K as "#.5K" if an odd number of blocks. ([#758](https://github.com/a2stuff/a2d/issues/758))
* Show "Today" for date for files modified on the current date.
* Apple Menu > About This Apple II command added - invokes This Apple DA.
* File > Copy a File... is now File > Copy To... and operates on current selection.
* File > Delete a File... is now File > Delete and operates on current selection.
* File > Get Info now shows total size/file count for folders/volumes.
* View > as Small Icons added.
* View > by Type sort order improved.
* View > by Size sort order improved.
* View > by Date sort order now includes times.
* Special > Get Size command is now redundant with File > Get Info, so was removed.
* Special > Make Alias command added - creates a Link file to the selected icon, placed in the LINKS/ folder.
* Shortcuts > Add a Shortcut... defaults to currently selected file.
* Shortcuts > Edit/Delete/Run a Shortcut: OK button is now disabled if there is no selection.
* Format/Erase: Default device to selected volume.
* Format/Erase: Show volume's previous name with adjusted case. ([#426](https://github.com/a2stuff/a2d/issues/426), [#427](https://github.com/a2stuff/a2d/issues/427))
* Format/Erase: OK button is now disabled if there is no selection.
* Format/Erase: Show format location when prompting for new volume name.
* The OK button is now disabled in name input dialogs (New Folder, Rename, Duplicate, Format, Erase) if the name is empty.
* Show keyboard shortcut for File > Delete in menu.
* View style for windows is saved/restored across restarts.
* Scroll position for windows is saved/restored across restarts.
* Show NON, ANM, S16, and SND type names in list views.
* Simplify New Folder dialog by not showing full path. ([#466](https://github.com/a2stuff/a2d/issues/466))
* Filetype and support opening BINSCII files (.BSC and .BSQ).
* Filetype and support for Integer BASIC (INT) files, c/o https://github.com/a2stuff/intbasic
* Improve progress and alert dialogs shown during copy/move, lock/unlock and delete operations.
* Escape key cancels operations (Copy/Move, Delete, Lock/Unlock)
* Support for launching AppleWorks files.
  * AppleWorks 5.1 must be on same volume as DeskTop, in AW5/ directory.
* Default window view style to parent window's view style.
* Show open/close animation for windows without visible folder icons.
* Show open/close animation for desk accessories and previews.
* Show open animation when launching external applications.

#### Disks & Files

* Supports up to 14 devices. ([#712](https://github.com/a2stuff/a2d/issues/712))
* CD-ROM drives now shown with a CD icon.
* Treat files with .A2LC, .A2HR, and .A2FM extensions as images.
* Icon for audio files (.BTC and .ZC, $D8/SND), video files ($5B/ANM)
* Icon for Applesoft and IntBASIC variable files (VAR, IVR)
* Add Link file type support ($E1/LNK)

#### Performance & Fixes

* Fix corruption/crash after closing a window.
* Unhighlight more correctly when dragging icons over folders.
* Improve scrolling in directory windows. ([#711](https://github.com/a2stuff/a2d/issues/711))
* Don't clamp drag highlight to screen bounds.
* Dimmed icons in inactive windows now render correctly. ([#613](https://github.com/a2stuff/a2d/issues/613))
* Enable dropping files onto folders in inactive windows. ([#418](https://github.com/a2stuff/a2d/issues/418))
* Pressing the Esc key cancels an in-progress drag. ([#719](https://github.com/a2stuff/a2d/issues/719))
* Don't move icons when dragged over source window's non-content area.
* Make sure scrollbars activate/deactivate if needed when an icon is renamed.
* Don't poll drives multiple times on startup when restoring windows.
* File > Rename... is now disabled if multiple icons are selected.
* Improve label spacing in several dialogs.
* Ensure newly created SELECTOR.LIST file is completely empty.
* Draw header before entries when refreshing window contents.
* Update header values only when window is activated to avoid visual artifacts.
* Improve double-click responsiveness when updating icons.
* Fix numerous crashes with long pathnames.
* Fix crash in File > Get Info is target is not available.
* Make OA+SA+O and OA+SA+W shortcuts work when Caps Lock is off.
* Improve layout of window header counts/labels. ([#493](https://github.com/a2stuff/a2d/issues/493))
* Improve mouse responsiveness during I/O operations.
* Show watch cursor during Copy/Move/Delete/Lock/Unlock operations.
* Improve performance of Copy/Move, Delete, and Lock/Unlock commands.
* Special > Lock and Special > Unlock now work on folders.
* Allow continuing a copy of nested files if one file is too large to fit.
* Ensure correct paths are visible when displaying alerts during operations.
* Fix "Files remaining" count for volume after failed shortcut / copy to RAMCard.
* Improve performance of moving files on the same volume by relinking rather than copying/deleting. ([#350](https://github.com/a2stuff/a2d/issues/350))
* Allow any file type in Apple Menu (except disabled DAs)
* Improve animation shown when opening/closing a window for an icon.

### Selector

* Fix clearing the text screen when launching programs.
* Allow pressing Escape to cancel copy to RAMCard.
* Change "DeskTop" button shortcut to 'D' in EN builds; corresponding changes in other languages.
* OK button is now disabled if there is no selection.

### Disk Copy

* Supports up to 14 devices. ([#712](https://github.com/a2stuff/a2d/issues/712))
* Show Pascal volume names more consistently.
* Ensure a confirmation prompt is shown before overwriting, unless destination is not formatted.
* Change "Read Drives" button shortcut to 'R' in EN builds; corresponding changes in other languages.
* Improve mouse responsiveness during I/O operations.
* Update block count display continuously during copy.
* OK button is now disabled if there is no selection.

### Desk Accessories

#### New Accessories

* International: A new control panel for setting international options - date/time/number separators, date format and clock style.
* Digital Clock: A new screen saver that shows the current time. ([#590](https://github.com/a2stuff/a2d/issues/590))
* Analog Clock: A new screen saver that shows the current time. ([#590](https://github.com/a2stuff/a2d/issues/590))
* Rod's Color Pattern: A new screen saver based on the classic demo. c/o @frankmilliron
* Neko: Provides a playful cat desk toy. (In Extras)
* Print Catalog: Dumps a recursive catalog of filenames to a printer in Slot 1.

#### Updates

* The `DESK.ACC` folder has been renamed to `APPLE.MENU`.
* New Toys directory for Eyes, Neko and Puzzle
* Apple+W can be used to close windowed accessories.
* Date & Time
  * Show shortcut key for OK button.
  * Support Tab key for changing fields.
  * Better translations for 12/24-hour buttons.
* Sounds
  * New sounds from Gorgon, Apple Panic, and more, c/o @frankmilliron
  * Play current selection if clicked again. ([#715](https://github.com/a2stuff/a2d/issues/715))
  * Fix label translation.
* Calc/Sci.Calc
  * Show leading zero before decimal in results.
  * Don't repaint on title bar click. ([#746](https://github.com/a2stuff/a2d/issues/746))
* Sci.Calc
  * Fix intermediate calculations with functions (SIN, etc). ([#741](https://github.com/a2stuff/a2d/issues/741))
  * Do trig functions (SIN, COS, etc) in degrees rather than radians.
* Find Files
  * Double-click a result to open the containing widow and select the file icon. ([#255](https://github.com/a2stuff/a2d/issues/255))
  * If no window is open, all on-line volumes are searched. ([#255](https://github.com/a2stuff/a2d/issues/255))
* Joystick: Visualize second joystick (paddles 2/3) if active.
* Flying Toasters: Improve animation speed and reduce flicker.
* Text Preview: Handle rendering long text files more intelligently.
* Image Preview
  * Show .A2HR and .A2FM files in B&W.
  * Fix HR image display glitches on palette bit transitions
* Electric Duet Preview: Add alternate players: during playback, press 3 for Mockingboard, 4 for Cricket!
* Puzzle
  * Added keyboard support - arrow keys move a tile into the hole.
  * Don't repaint on title bar click. ([#746](https://github.com/a2stuff/a2d/issues/746))
  * Allow moving and closing the window before scrambling. ([#752](https://github.com/a2stuff/a2d/issues/752))
  * Allow re-scrambling once the puzzle has been completed.
  * Flash window on victory.
  * Don't mispaint onto the desktop if the window is obscured.
* Options
  * Add option to show shortcuts in dialogs.
  * Add keyboard shortcuts for checkboxes.
* Map: Position indicator now blinks.
* Control Panel: Add more obvious button to apply desktop pattern change.
* This Apple
  * Identify and show Tiger Learning Computer
  * Moved into MODULES/ directory, dedicated command added
* Screen Dump: Do nothing unless an SSC is in Slot 1.

## 1.2

An unofficial release with bug fixes and enhancements. December 28, 2022.

See the release notes at:
https://github.com/a2stuff/a2d/blob/release-1.2/RELEASE-NOTES.md

## 1.1

Final release by Version Soft/Apple Computer dated November 26, 1986.

See also:

* Jay Edwards' [Mouse Desk/DeskTop History](https://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Misc/mousedesk.info)
* https://www.a2desktop.com/history
