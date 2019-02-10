# Apple II DeskTop

Project page: https://github.com/inexorabletash/a2d/

Numbers like (#123) refer to items in the issue tracker.
https://github.com/inexorabletash/a2d/issues

## 1.2 - alpha

### Enhancements

* Current time shown on right side of menu bar, if system has a clock. (#7)
* Up to 13 volumes are shown on the desktop (was 10). (#20)
* Up to 12 Desk Accessories are shown in the menu (was 8). (#90)
* Drag "unlimited" number of icons (was 20). (#18)
* Dragging files to same volume moves; use Open-Apple to force copy. (#8)
* Menus allow click-to-drop, click-to-select interaction. (#104)
* Add Special > Check Drive command to refresh a single drive. (#97)
* Show Text File DA: Keyboard support. Escape quits, arrows scroll. (#4)
* Reorganized/renamed several menu items. (#13)
* New icons for graphics, AppleWorks, relocatable, command, and IIgs-specific file types. (#105)
* Desktop icon shown for AppleTalk file shares. (#88)
* Improvements to several existing icon bitmaps. (#74)
* DAs with high bit in aux-type set are skipped. (#102)
* Icons for volumes positioned more predictably and sensibly. (#94)
* GS/OS filenames (supported by ProDOS 2.5) are shown with correct case. (#64)

### Additional Desk Accessories

* This Apple
  * Gives details about the computer, expanded memory, and what's in each slot. (#29)
* Eyes
  * Eyes that follow the mouse. (#53)
* Screen Dump
  * Dumps a screenshot to an ImageWriter II attached to a Super Serial Card in Slot 1. (#46)
* Key Caps
  * Shows an on-screen keyboard map and indicates which key is pressed.
* Run Basic Here
  * Launch BASIC.SYSTEM with PREFIX set to the current window's pathname. (#42)

Note that several of the new Desk Accessories will not work with older versions
of Apple II DeskTop/MouseDesk, due to dependence on new APIs.

The former "Show Text File" DA is now part of automatic preview
functionality (see below).


### Automatic Preview

Text and Graphics files with the correct file types can be previewed
without leaving DeskTop; select the file icon then select File > Open,
or double-click the file icon. Text files must be type TXT ($04).
Graphics files must be type FOT ($08).

To preview files of other types, you can copy the preview handlers
named `SHOW.TEXT.FILE` and `SHOW.IMAGE.FILE` from the `PREVIEW` folder
to the `DESK.ACC` folder, and restart DeskTop. To use them, select the
file, then select the appropriate command from the Apple menu.


### Notable Fixes

* Dates 00-39 are treated as 2000-2039; dates 100-127 are treated as 2000-2027. (#15)
* File > Quit returns to ProDOS 8 selector, and /RAM is reattached. (#3)
* SELECTOR.LIST created if missing. (#92)
* Prevent crash after renaming volume. (#99)
* Prevent crash with more than two volumes on a SmartPort interface. (#45)
* Startup menu will include Slot 2. (#106)
* Correct odd behavior for file type $08. (#103)
* New Folder/Rename file dialog no longer truncated after IP. (#118)
* Correct rendering issues with desktop volume icons. (#117)
* Prevent occasional rectangle drawn on desktop after window close. (#120)
* Desk Accessories:
  * Date: Read-only on systems with a clock. On systems without a clock, date is saved for next session. (#30, #39)
  * Calculator: don't mis-paint when moved offscreen and other fixes. (#33, #34)
  * Sort Directory: don't need to click before sorting. (#17)
* Hardware/Emulator Specific:
  * IIc Plus: don't spin slot 5 drives constantly. (Use Special > Check Drive) (#25)
  * Macintosh LC IIe Option Card: don't crash on startup. (#93)
  * IIgs: color DHR is re-enabled on exit. (#43)
  * KEGS-based IIgs emulators no longer crash on startup. (#85)


### Known Issues

* Selector app is unmodified.
* Special > Disk Copy app is unmodified, and may suffer bugs fixed in DeskTop (e.g. SmartPort behavior)
* Locked files are moved without prompting.

# 1.1

Final release by Apple Computer. November 26, 1986.

See Jay Edwards' [MouseDesk/DeskTop History](https://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Misc/mousedesk.info)
for more version information.
