# Apple II DeskTop

Home Page: https://a2desktop.com

Project Page: https://github.com/a2stuff/a2d/

Numbers like (#123) refer to items in the issue tracker.
https://github.com/a2stuff/a2d/issues

# 1.2 Pre-Alpha

### DeskTop Enhancements

* Current day/time shown on right side of menu bar, if system has a clock. (#7, #142, #220)
* Up to 13 volumes are shown on the desktop (was 10). (#20)
* Windows restored when DeskTop is relaunched. (#210)
* Drag "unlimited" number of icons (was 20). (#18)
* Dragging files to same volume moves instead of copies; hold Apple while dragging to force copy. (#8)
* Menu bar menus are now drop-down in addition to pull-down. (#104)
* Add Special > Check Drive command to refresh a single drive. (#97)
* Reorganized/renamed several menu items. (#13)
* New file type icons: graphics, IIgs-specific, AppleWorks, relocatable, command, fonts, and DAs. (#105, #116)
* Desktop icon shown for AppleTalk file shares. (#88)
* Improvements to several existing icon bitmaps. (#74)
* Icons for volumes positioned more predictably and sensibly. (#94)
* Short icon names are centered. (#208)
* AppleWorks filenames are shown with correct case. (#179)
* GS/OS filenames (supported by ProDOS 2.5) are shown with correct case. (#64)
* Tip about skipping copy to RAMCard is shown during startup. (#140)
* Holding Apple while double-clicking or using File > Open closes parent folder. (#9)
* Apple-` or Apple-Tab cycles through open windows; Apple-~ cycles in reverse. (#143, #230)
* Apple-Delete deletes selected files. (#150)
* File > Get Info command shows aux type for files. (#148)
* ProDOS 2.5 extended dates (through year 4095) are supported. (#169)
* File > New Folder scrolls the new folder icon into view. (#16)
* If present, BASIS.SYSTEM is used to launch unknown file types. (#40)
* Use standard ProDOS alert tone.
* File modification time-of-day is shown in file lists and File > Get Info. (#221)
* File > Rename dialog pre-filled with previous name. (#156)

### Desk Accessory Enhancements

* Up to 12 desk accessories are shown in the menu (was 8). (#90)
* Desk accessory files can be executed directly. (#101)
* Desk accessory files with high bit in aux type set are hidden in Apple menu. (#102)
* Show Text File DA: Keyboard support. Escape quits, arrows scroll. (#4)
* Apple menu can contain directories, which launch windows. (#209)

### Additional Desk Accessories

* This Apple
  * Gives details about the computer, expanded memory, and what's in each slot. (#29)
* Control Panel
  * Allows editing the desktop pattern (#31), double-click speed (#2), insertion point blink speed, and clock 12/24hr setting (#220). Also shows joystick calibration. (#72)
* Run Basic Here
  * Launch BASIC.SYSTEM with PREFIX set to the current window's pathname. (#42)
* Key Caps
  * Shows an on-screen keyboard map and indicates which key is pressed.
* Screen Dump
  * Dumps a screenshot to an ImageWriter II attached to a Super Serial Card in slot 1. (#46)
* Eyes
  * Eyes that follow the mouse. (#53)
* Flying Toasters
  * Homage to the classic After Dark screen saver by Jack Eastman. (#27)
* Melt
  * Another classic screen saver effect: the screen melts down like dripping wax. (#27)
* System Speed
  * Enable/disable built-in and some popular add-on system accelerators. (#26)
* Find Files
  * Search a directory and descendants for filenames. Use ? and * as wildcards. (#21)

Note that the desk accessories from version 1.2 will not work with older versions
of Apple II DeskTop/MouseDesk, due to dependence on new APIs.

The former Show Text File DA is now part of the file preview
functionality (see below).

### File Preview

Text, graphics, and font files with the correct file types can be
previewed without leaving DeskTop; select the file icon and then select
File > Open, or double-click the file icon.

* Text files must be type TXT ($04).
* Graphics files must be type FOT ($08), or BIN ($06) with specific aux type:
  * BIN ($06) Files:
    * Aux type $2000 or $4000 and 17 blocks are hi-res images.
    * Aux type $2000 or $4000 and 33 blocks are double hi-res images.
    * Aux type $5800 and 3 blocks are Minipix (Print Shop) images.
  * FOT ($08) Files:
    * Aux type $4000 or $4001 are packed hi-res/double hi-res images. (#107)
    * 17 block files are hi-res images.
    * 33 block files are double hi-res images.
* Font files must be type FNT ($07) and must be MGTK font resources. (This file type is officially reserved for Apple /// SOS font files, but unlikely to be confused.)

To preview files of other types (e.g. view a BIN file as text), you
can copy the appropriate preview handler (e.g. `SHOW.TEXT.FILE`) from
the `PREVIEW` folder to the `DESK.ACC` folder, and restart DeskTop. To
use them, select the file icon and then select the appropriate command
from the Apple menu.

### Notable Fixes

* Date years 00-39 are treated as 2000-2039; years 100-127 are treated as 2000-2027. (#15)
* Fix resource exhaustion when opening/closing many windows. (#19)
* File > Quit returns to ProDOS 8 selector, and /RAM is reattached. (#3)
* SELECTOR.LIST file created if missing. (#92)
* Prevent crash after renaming volume. (#99)
* Prevent crash with more than two volumes on a SmartPort interface. (#45)
* Startup menu will include slot 2. (#106)
* Correct odd behavior for file type $08. (#103)
* New Folder/Rename file dialog no longer truncated after IP. (#118)
* Correct rendering issues with desktop volume icons. (#117, #152)
* Prevent occasional rectangle drawn on desktop after window close. (#120)
* Empty directories can be copied/moved. (#121)
* Ctrl+Reset quits cleanly back to ProDOS (except buggy emulators). (#141)
* Prevent crash with more than 8 removable devices.
* Desk Accessories:
  * Date: Read-only on systems with a clock. On systems without a clock, date is saved for next session. (#30, #39)
  * Calculator: Don't mis-paint when moved offscreen and other fixes. (#33, #34)
  * Sort Directory: Don't need to click before sorting. (#17)
* Hardware/Emulator Specific:
  * IIc Plus: Don't spin slot 5 drives constantly. (Use Special > Check Drive) (#25)
  * Laser 128: Avoid hangs checking SmartPort status. (Use Special > Check Drive) (#138)
  * IIgs: Color DHR is re-enabled on exit. (#43)
  * IIgs: Mono DHR is re-enabled when returning from system control panel. (#193)
  * Macintosh LC PDS IIe Option Card: Don't crash on startup. (#93)
  * Macintosh LC PDS IIe Option Card: Correct problems with interrupts affecting AppleTalk. (#129)
  * KEGS-based IIgs Emulators: Don't crash on startup. (#85)

### Known Issues

* Special > Disk Copy app is not substantially modified, and may suffer bugs fixed in DeskTop (e.g. SmartPort behavior).
* Other issues can be found at https://github.com/a2stuff/a2d/issues.


# 1.1

Final release by VersionSoft/Apple Computer dated November 26, 1986.

See Jay Edwards' [MouseDesk/DeskTop History](https://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Misc/mousedesk.info)
for more version information.
