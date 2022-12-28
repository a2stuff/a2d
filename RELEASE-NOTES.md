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

### DeskTop

* File > Copy a File... is now File > Copy To... and operates on current selection.
* File > Delete a File... is now File > Delete and operates on current selection.
* Support up to 14 devices. ([#712](https://github.com/a2stuff/a2d/issues/712))
* Improve scrolling in directory windows. ([#711](https://github.com/a2stuff/a2d/issues/711))
* Shortcut > Add a Shortcut... defaults to currently selected file.
* Simplify list views by omitting directory file sizes.
* Fix corruption/crash after closing a window.
* CD-ROM drives now shown with a CD icon.
* Unhighlight more correctly when dragging icons over folders.
* Show keyboard shortcut for File > Delete in menu.
* Support selection in list views. ([#28](https://github.com/a2stuff/a2d/issues/28))
* View style for windows is saved/restored across restarts.
* Scroll position for windows is saved/restored across restarts.
* Don't clamp drag highlight to screen bounds.
* Dimmed icons in inactive windows now render correctly. ([#613](https://github.com/a2stuff/a2d/issues/613))
* Enable dropping files onto folders in inactive windows. ([#418](https://github.com/a2stuff/a2d/issues/418))
* Pressing the Esc key cancels an in-progress drag. ([#719](https://github.com/a2stuff/a2d/issues/719))
* Don't move icons when dragged over source window's non-content area.
* Make sure scrollbars activate/deactivate if needed when an icon is renamed.
* Improve label spacing in several dialogs.
* Don't poll drives multiple times on startup when restoring windows.
* Treat files with .A2LC, .A2HR, and .A2FM extensions as images.
* File > Rename... is now disabled if multiple icons are selected.
* The default double-click speed is now the middle setting.
* View > as Small Icons added.
* Format/Erase: Show volume's previous name with adjusted case. ([#426](https://github.com/a2stuff/a2d/issues/426), [#427](https://github.com/a2stuff/a2d/issues/427))
* Format/Erase: Default device to selected volume.
* Icon for audio files (.BTC and .ZC, $D8/SND), video files ($5B/ANM)

### Selector

* Fix clearing the text screen when launching programs.

### Disk Copy

* Support up to 14 devices. ([#712](https://github.com/a2stuff/a2d/issues/712))
* Show Pascal volume names more consistently.
* Ensure a confirmation prompt is shown before overwriting, unless destination is not formatted.

### Desk Accessories

#### New Accessories

* Digital Clock: A new DA that shows the current time. ([#590](https://github.com/a2stuff/a2d/issues/590))
* Analog Clock: A new DA that shows the current time. ([#590](https://github.com/a2stuff/a2d/issues/590))
* Rod's Color Pattern: A new DA based on the classic demo. c/o @frankmilliron
* Neko: A new DA which provides a playful cat desk toy. (In Extras)

#### Updates

* The `DESK.ACC` folder has been renamed to `APPLE.MENU`.
* Date & Time: Show shortcut key for OK button.
* Date & Time: Better translations for 12/24-hour buttons.
* Date & Time: Support Tab key for changing fields.
* Sounds: New sounds from Gorgon, Apple Panic, and more, c/o @frankmilliron
* Sounds: Play current selection if clicked again. ([#715](https://github.com/a2stuff/a2d/issues/715))
* International: A new control panel DA for setting international options - date/time/number separators, date format and clock style.
* Calc/Sci.Calc: Show leading zero before decimal in results.
* Show.Duet.File: Add alternate players: during playback, press 3 for Mockingboard, 4 for Cricket!
* Find Files: Double-click a result to open the containing widow and select the file icon. ([#255](https://github.com/a2stuff/a2d/issues/255))
* Find Files: If no window is open, all on-line volumes are searched. ([#255](https://github.com/a2stuff/a2d/issues/255))
* Text Preview: Handle rendering long text files more intelligently.
* Flying Toasters: Improve animation speed and reduce flicker.
* Image Preview: Show .A2HR files in B&W
* Joystick: Visualize second joystick (paddles 2/3) if active.

## 1.2

An unofficial release with bug fixes and enhancements. See the release notes at:

https://github.com/a2stuff/a2d/blob/release-1.2/RELEASE-NOTES.md

## 1.1

Final release by Version Soft/Apple Computer dated November 26, 1986.

See also:

* Jay Edwards' [Mouse Desk/DeskTop History](https://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Misc/mousedesk.info)
* https://www.a2desktop.com/history
* https://www.a2desktop.com/releases
