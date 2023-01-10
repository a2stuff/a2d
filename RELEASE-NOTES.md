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

### Launcher

* Ensure DeskTop is correctly detected on RAMCard when re-launched.
* Allow pressing Escape to cancel copy to RAMCard.

### DeskTop

#### Enhanced Features

* Support selection in list views. ([#28](https://github.com/a2stuff/a2d/issues/28))
* Simplify list views by omitting directory file sizes.
* View > as Small Icons added.
* File > Copy a File... is now File > Copy To... and operates on current selection.
* File > Delete a File... is now File > Delete and operates on current selection.
* Shortcut > Add a Shortcut... defaults to currently selected file.
* Format/Erase: Default device to selected volume.
* Format/Erase: Show volume's previous name with adjusted case. ([#426](https://github.com/a2stuff/a2d/issues/426), [#427](https://github.com/a2stuff/a2d/issues/427))
* Show keyboard shortcut for File > Delete in menu.
* View style for windows is saved/restored across restarts.
* Scroll position for windows is saved/restored across restarts.
* Show NON, ANM, S16, and SND type names in list views.

#### Disks & Files

* Supports up to 14 devices. ([#712](https://github.com/a2stuff/a2d/issues/712))
* CD-ROM drives now shown with a CD icon.
* Treat files with .A2LC, .A2HR, and .A2FM extensions as images.
* Icon for audio files (.BTC and .ZC, $D8/SND), video files ($5B/ANM)

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

### Selector

* Fix clearing the text screen when launching programs.
* Allow pressing Escape to cancel copy to RAMCard.

### Disk Copy

* Supports up to 14 devices. ([#712](https://github.com/a2stuff/a2d/issues/712))
* Show Pascal volume names more consistently.
* Ensure a confirmation prompt is shown before overwriting, unless destination is not formatted.

### Desk Accessories

#### New Accessories

* International: A new control panel for setting international options - date/time/number separators, date format and clock style.
* Digital Clock: A new screen saver that shows the current time. ([#590](https://github.com/a2stuff/a2d/issues/590))
* Analog Clock: A new screen saver that shows the current time. ([#590](https://github.com/a2stuff/a2d/issues/590))
* Rod's Color Pattern: A new screen saver based on the classic demo. c/o @frankmilliron
* Neko: Provides a playful cat desk toy. (In Extras)

#### Updates

* The `DESK.ACC` folder has been renamed to `APPLE.MENU`.
* Date & Time
  * Show shortcut key for OK button.
  * Support Tab key for changing fields.
  * Better translations for 12/24-hour buttons.
* Sounds
  * New sounds from Gorgon, Apple Panic, and more, c/o @frankmilliron
  * Play current selection if clicked again. ([#715](https://github.com/a2stuff/a2d/issues/715))
* Calc/Sci.Calc: Show leading zero before decimal in results.
* Find Files
  * Double-click a result to open the containing widow and select the file icon. ([#255](https://github.com/a2stuff/a2d/issues/255))
  * If no window is open, all on-line volumes are searched. ([#255](https://github.com/a2stuff/a2d/issues/255))
* Joystick: Visualize second joystick (paddles 2/3) if active.
* Flying Toasters: Improve animation speed and reduce flicker.
* Text Preview: Handle rendering long text files more intelligently.
* Image Preview: Show .A2HR and .A2FM files in B&W.
* Electric Duet Preview: Add alternate players: during playback, press 3 for Mockingboard, 4 for Cricket!
* Puzzle: Added keyboard support - arrow keys move a tile into the hole.

## 1.2

An unofficial release with bug fixes and enhancements. December 28, 2022.

See the release notes at:
https://github.com/a2stuff/a2d/blob/release-1.2/RELEASE-NOTES.md

## 1.1

Final release by Version Soft/Apple Computer dated November 26, 1986.

See also:

* Jay Edwards' [Mouse Desk/DeskTop History](https://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Misc/mousedesk.info)
* https://www.a2desktop.com/history
