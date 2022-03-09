# Apple II DeskTop

Home Page: https://a2desktop.com

Project Page: https://github.com/a2stuff/a2d

## 1.2 Alpha

### General Enhancements

* Localizations into these languages: ([#327](https://github.com/a2stuff/a2d/issues/327))
  * English
  * French
  * Italian
  * Spanish
  * Portuguese
  * German
* Mouse Keys mode simplified: ([#185](https://github.com/a2stuff/a2d/issues/185))
  * OA+SA+Space to enter Mouse Keys mode. A sound will play.
  * SA acts as mouse button.
  * Escape to exit Mouse Keys mode. A sound will play.

### DeskTop Enhancements

* Progress bar shown while loading, and when copying to RAMCard. ([#330](https://github.com/a2stuff/a2d/issues/330))
* Tip about skipping copy to RAMCard is shown during startup. ([#140](https://github.com/a2stuff/a2d/issues/140))
* Current day/time shown on right side of menu bar, if system has a clock. ([#7](https://github.com/a2stuff/a2d/issues/7), [#142](https://github.com/a2stuff/a2d/issues/142), [#220](https://github.com/a2stuff/a2d/issues/220), [#444](https://github.com/a2stuff/a2d/issues/444))
* Up to 13 volumes are shown on the desktop (was 10). ([#20](https://github.com/a2stuff/a2d/issues/20))
* Windows restored when DeskTop is relaunched. ([#210](https://github.com/a2stuff/a2d/issues/210))
* Drag "unlimited" number of icons (was 20). ([#18](https://github.com/a2stuff/a2d/issues/18))
* Menu bar menus are now drop-down in addition to pull-down. ([#104](https://github.com/a2stuff/a2d/issues/104))
* Menu filler items appear with a visible separator. ([#135](https://github.com/a2stuff/a2d/issues/135))
* Reorganized/renamed several menu items. ([#13](https://github.com/a2stuff/a2d/issues/13), [#303](https://github.com/a2stuff/a2d/issues/303), [#304](https://github.com/a2stuff/a2d/issues/304), [#305](https://github.com/a2stuff/a2d/issues/305), [#378](https://github.com/a2stuff/a2d/issues/378))
* Add **Special > Check Drive** command to refresh a single drive. ([#97](https://github.com/a2stuff/a2d/issues/97))
* Add **File > Duplicate...** command to duplicate files. ([#228](https://github.com/a2stuff/a2d/issues/228))
* New file type icons: graphics, IIgs-specific, AppleWorks, relocatable, command, fonts, music, and DAs. ([#105](https://github.com/a2stuff/a2d/issues/105), [#116](https://github.com/a2stuff/a2d/issues/116))
* Desktop icon shown for AppleTalk file shares. ([#88](https://github.com/a2stuff/a2d/issues/88))
* Improvements to several existing icon bitmaps. ([#74](https://github.com/a2stuff/a2d/issues/74))
* Icons for volumes positioned more predictably and sensibly. ([#94](https://github.com/a2stuff/a2d/issues/94), [#375](https://github.com/a2stuff/a2d/issues/375), [#540](https://github.com/a2stuff/a2d/issues/540))
* Short icon names are centered. ([#208](https://github.com/a2stuff/a2d/issues/208))
* AppleWorks filenames are shown with correct case. ([#179](https://github.com/a2stuff/a2d/issues/179))
* GS/OS filenames (supported by ProDOS 2.5) are shown with correct case. ([#64](https://github.com/a2stuff/a2d/issues/64), [#385](https://github.com/a2stuff/a2d/issues/385))
* ProDOS 2.5 extended dates (through year 4095) are supported. ([#169](https://github.com/a2stuff/a2d/issues/169))
* If present, **BASIS.SYSTEM** is used to launch unknown file types. ([#40](https://github.com/a2stuff/a2d/issues/40))
* Use standard ProDOS alert tone.
* File modification time-of-day is shown in file lists and **File > Get Info**. ([#221](https://github.com/a2stuff/a2d/issues/221))
* **File > New Folder...** scrolls the new folder icon into view. ([#16](https://github.com/a2stuff/a2d/issues/16))
* **File > Rename...** dialog pre-filled with previous name. ([#156](https://github.com/a2stuff/a2d/issues/156))
* **File > Get Info**, list views, etc. show file and volume sizes in kilobytes rather than blocks. ([#308](https://github.com/a2stuff/a2d/issues/308))
* **File > Get Info** shows used/total for volumes, rather than free/total.
* **File > Get Info** command shows aux type for files. ([#148](https://github.com/a2stuff/a2d/issues/148))
* Use commas as a numeric separator. ([#270](https://github.com/a2stuff/a2d/issues/270), [#377](https://github.com/a2stuff/a2d/issues/377))
* BIN files can be opened with menu items without a modifier key. ([#530](https://github.com/a2stuff/a2d/issues/530), [#531](https://github.com/a2stuff/a2d/issues/531))
* Double-clicking opens all selected folders/volumes. ([#363](https://github.com/a2stuff/a2d/issues/363))
* Renaming volumes/folders doesn't close affected windows. ([#469](https://github.com/a2stuff/a2d/issues/469))
* Show appropriate error when copying a file onto itself. ([#630](https://github.com/a2stuff/a2d/issues/630))
* Show appropriate error when trying to replace an item with itself or an item it contains. ([#634](https://github.com/a2stuff/a2d/issues/634), [#635](https://github.com/a2stuff/a2d/issues/635), [#636](https://github.com/a2stuff/a2d/issues/636))

* Show appropriate error when a non-ProDOS-8 storage type (e.g. GS/OS forked file) is encountered. ([#631](https://github.com/a2stuff/a2d/issues/631))
* Support opening archives using AUTO UnShrinkIt by Andrew E. Nicholas.
* Keyboard-related changes:
  * Holding **Solid-Apple** while double-clicking, or holding **Apple** while using **File > Open**, or **Open-Apple+Solid-Apple+O**, or **Open-Apple+Solid-Apple+Down** opens the selected items then closes parent window. ([#9](https://github.com/a2stuff/a2d/issues/9), [#625](https://github.com/a2stuff/a2d/issues/625), ([#660](https://github.com/a2stuff/a2d/issues/660))
  * Holding **Apple** while clicking a window's close box, or pressing **Open-Apple+Solid-Apple+W**  closes all windows. ([#266](https://github.com/a2stuff/a2d/issues/266), [#626](https://github.com/a2stuff/a2d/issues/626))
  * Holding **Open-Apple** on while clicking a selected file deselects it. ([#359](https://github.com/a2stuff/a2d/issues/359))
  * Holding **Open-Apple** while dragging a selection box around files extends selection. ([#546](https://github.com/a2stuff/a2d/issues/546))
  * **Shift** key works as modifier to extend selection, on IIgs and systems with shift key mod. ([#340](https://github.com/a2stuff/a2d/issues/340))
  * When dragging files to a different volume, hold **Apple** while dragging to force move. ([#256](https://github.com/a2stuff/a2d/issues/256))
  * Dragging files to same volume moves instead of copies; hold **Apple** while dragging to force copy. ([#8](https://github.com/a2stuff/a2d/issues/8))
  * **Apple+\`** or **Apple+Tab** cycles through open windows; **Shift+Apple+\`** (and **Shift+Apple+Tab**, when detectable) cycles in reverse. ([#143](https://github.com/a2stuff/a2d/issues/143), [#230](https://github.com/a2stuff/a2d/issues/230))
  * **Apple+Delete** deletes selected files. ([#150](https://github.com/a2stuff/a2d/issues/150))
  * **Apple+Down** opens/previews selection. ([#254](https://github.com/a2stuff/a2d/issues/254))
  * **Apple+Up** opens parent window or selects volume icon. ([#254](https://github.com/a2stuff/a2d/issues/254), [#314](https://github.com/a2stuff/a2d/issues/314))
  * **Open-Apple+Solid-Apple+Up** opens parent window or selects volume icon and closes current window. ([#661](https://github.com/a2stuff/a2d/issues/661))
  * **Return** is a shortcut for **File > Rename...**. ([#275](https://github.com/a2stuff/a2d/issues/275))
  * Arrow keys change selected icon. ([#274](https://github.com/a2stuff/a2d/issues/274))
  * **Tab**/**Shift+Tab** (or **\`**/**Shift+\`**) change selected icon in alphabetical order. ([#275](https://github.com/a2stuff/a2d/issues/275), [#671](https://github.com/a2stuff/a2d/issues/671))
  * Type-down selection is supported. ([#275](https://github.com/a2stuff/a2d/issues/275))

### Desk Accessory Enhancements

* Up to 12 desk accessories are shown in the **Apple** menu (was 8). ([#90](https://github.com/a2stuff/a2d/issues/90))
* Desk accessory files can be executed directly. ([#101](https://github.com/a2stuff/a2d/issues/101))
* Desk accessory files with high bit in aux type set are hidden in the **Apple** menu. ([#102](https://github.com/a2stuff/a2d/issues/102))
* Show Text File DA: Keyboard support. **Esc** quits, arrows scroll, **Space** toggles modes. ([#4](https://github.com/a2stuff/a2d/issues/4), [#403](https://github.com/a2stuff/a2d/issues/403))
* The **Apple** menu can contain directories, which launch windows. ([#209](https://github.com/a2stuff/a2d/issues/209), [#292](https://github.com/a2stuff/a2d/issues/292))
* Other executable files and previewable files can be launched from the **Apple** menu. ([#293](https://github.com/a2stuff/a2d/issues/293), [#295](https://github.com/a2stuff/a2d/issues/295))

### Additional Desk Accessories

* **Control Panels**
  * **Control Panel**
    * Allows editing the double-click speed ([#2](https://github.com/a2stuff/a2d/issues/2)), desktop pattern ([#31](https://github.com/a2stuff/a2d/issues/31)), insertion point blink speed, and mouse tracking speed ([#273](https://github.com/a2stuff/a2d/issues/273)).
  * **Joystick**
    * A joystick/paddle calibration tool. ([#72](https://github.com/a2stuff/a2d/issues/72))
  * **System Speed**
    * Enable/disable built-in and some popular add-on system accelerators. ([#26](https://github.com/a2stuff/a2d/issues/26))
  * **Startup Options**
    * Toggle startup options. ([#476](https://github.com/a2stuff/a2d/issues/476))
* **This Apple**
  * Gives details about the computer, expanded memory, and what's in each slot. ([#29](https://github.com/a2stuff/a2d/issues/29))
* **Run Basic Here**
  * Launch **BASIC.SYSTEM** with `PREFIX` set to the current window's pathname. ([#42](https://github.com/a2stuff/a2d/issues/42))
* **Key Caps**
  * Shows an on-screen keyboard map and indicates which key is pressed.
* **Screen Dump**
  * Dumps a screenshot to an ImageWriter II attached to a Super Serial Card in slot 1. ([#46](https://github.com/a2stuff/a2d/issues/46))
* **Calendar**
  * Displays any month, from 1901 through 2155. ([#231](https://github.com/a2stuff/a2d/issues/231))
* **Eyes**
  * Eyes that follow the mouse. ([#53](https://github.com/a2stuff/a2d/issues/53))
* **Find Files**
  * Search a directory and descendants for filenames. Use ? and * as wildcards. ([#21](https://github.com/a2stuff/a2d/issues/21))
* **Darkness** (optional)
  * A debugging tool that paints the whole screen a dark pattern.
* **Screen Savers**
  * **Flying Toasters**
    * Homage to the classic After Dark screen saver by Jack Eastman. ([#27](https://github.com/a2stuff/a2d/issues/27))
  * **Melt**
    * Another classic screen saver effect: the screen melts down like dripping wax. ([#27](https://github.com/a2stuff/a2d/issues/27))
  * **Invert**
    * Invert the screen until the next click/key. ([#261](https://github.com/a2stuff/a2d/issues/261))
  * **Matrix**
    * Digital rain effect, inspired by https://github.com/neilk/apple-ii-matrix

Note that the desk accessories from version 1.2 will not work with older versions
of Apple II DeskTop/MouseDesk, due to dependence on new APIs.

The Show Text File DA is now part of the file preview functionality (see below).

### File Preview

Text, graphics, music, and font files with the correct file types can be
previewed without leaving DeskTop; select the file icon and then select
**File > Open**, or double-click the file icon.

* Text files must be type TXT ($04).
* Graphics files must be type FOT ($08), or BIN ($06) with specific aux type:
  * BIN ($06) Files:
    * Aux type $2000 or $4000 and 17 blocks are hi-res images.
    * Aux type $2000 or $4000 and 33 blocks are double hi-res images.
    * Aux type $5800 and 3 blocks are Minipix (Print Shop) images.
  * FOT ($08) Files:
    * Aux type $4000 or $4001 are packed hi-res/double hi-res images. ([#107](https://github.com/a2stuff/a2d/issues/107))
    * 17 block files are hi-res images.
    * 33 block files are double hi-res images.
* Music files must be Electric Duet files with type $D5, aux type $D0E7.
* Font files must be type FNT ($07) and must be MGTK font resources. (This file type is officially reserved for Apple /// SOS font files, but unlikely to be confused.)

To preview files of other types (e.g. view a BIN file as text), you
can copy the appropriate preview handler (e.g. `SHOW.TEXT.FILE`) from
the `PREVIEW` folder to the `DESK.ACC` folder, and restart DeskTop. To
use them, select the file icon and then select the appropriate command
from the **Apple** menu.

### Notable Fixes

* Date years 00-39 are treated as 2000-2039; years 100-127 are treated as 2000-2027. ([#15](https://github.com/a2stuff/a2d/issues/15))
* Fix resource exhaustion when opening/closing many windows. ([#19](https://github.com/a2stuff/a2d/issues/19))
* Fix inconsistencies around maximum number of icons allowed. ([#529](https://github.com/a2stuff/a2d/issues/529), [#537](https://github.com/a2stuff/a2d/issues/537), and more)
* Fix crashes when maximum number of icons is exceeded. ([#527](https://github.com/a2stuff/a2d/issues/527), [#538](https://github.com/a2stuff/a2d/issues/538))
* **File > Quit** returns to ProDOS 8 selector, and `/RAM` is reattached. ([#3](https://github.com/a2stuff/a2d/issues/3))
* `SELECTOR.LIST` file created if missing. ([#92](https://github.com/a2stuff/a2d/issues/92), [#497](https://github.com/a2stuff/a2d/issues/497))
* Handle `SELECTOR.LIST` being modified while DeskTop is running. ([#526](https://github.com/a2stuff/a2d/issues/526))
* Handle `SELECTOR.LIST` missing when Selector is launched. ([#485](https://github.com/a2stuff/a2d/issues/485))
* Update the **Shortcuts** menu size when entries are modified. ([#518](https://github.com/a2stuff/a2d/issues/518))
* Prevent crash after renaming volume. ([#99](https://github.com/a2stuff/a2d/issues/99))
* Prevent crash with more than two volumes on a SmartPort interface. ([#45](https://github.com/a2stuff/a2d/issues/45))
* The **Startup** menu now includes slot 2. ([#106](https://github.com/a2stuff/a2d/issues/106))
* Correct odd behavior for file type $08. ([#103](https://github.com/a2stuff/a2d/issues/103))
* Correct rendering issues with desktop volume icons. ([#117](https://github.com/a2stuff/a2d/issues/117), [#152](https://github.com/a2stuff/a2d/issues/152), [#153](https://github.com/a2stuff/a2d/issues/153), [#182](https://github.com/a2stuff/a2d/issues/182), [#505](https://github.com/a2stuff/a2d/issues/505))
* Correct rendering issues with file icons. ([#151](https://github.com/a2stuff/a2d/issues/151), [#181](https://github.com/a2stuff/a2d/issues/181), [#365](https://github.com/a2stuff/a2d/issues/365), [#366](https://github.com/a2stuff/a2d/issues/366), [#369](https://github.com/a2stuff/a2d/issues/369))
* Prevent occasional rectangle drawn on desktop after window close. ([#120](https://github.com/a2stuff/a2d/issues/120))
* Fix window animation after **File > Close**. ([#145](https://github.com/a2stuff/a2d/issues/145))
* Empty directories can be copied. ([#121](https://github.com/a2stuff/a2d/issues/121))
* **Control-Reset** quits cleanly back to ProDOS (except buggy emulators). ([#141](https://github.com/a2stuff/a2d/issues/141))
* Prevent crash with more than 8 removable devices.
* Disk Copy works with disks over 8MB. ([#386](https://github.com/a2stuff/a2d/issues/386))
* Prevent Disk Copy crash with remapped drives. ([#306](https://github.com/a2stuff/a2d/issues/306))
* Format/Erase now works correctly with disks over 20MB. ([#557](https://github.com/a2stuff/a2d/issues/557))
* Scrollbars no longer activate unnecessarily. ([#347](https://github.com/a2stuff/a2d/issues/347), [#348](https://github.com/a2stuff/a2d/issues/348), [#394](https://github.com/a2stuff/a2d/issues/394))
* "There are 2 volumes with the same name." alert is now shown correctly. ([#542](https://github.com/a2stuff/a2d/issues/542))
* "Files remaining" counts were incorrect in various cases. ([#462](https://github.com/a2stuff/a2d/issues/462), [#470](https://github.com/a2stuff/a2d/issues/470), [#534](https://github.com/a2stuff/a2d/issues/534))
* Copying to RAMCard on startup could fail for directories with specific numbers of files. ([#509](https://github.com/a2stuff/a2d/issues/509))
* Handle "Device off-line" errors after ejecting disks. ([#536](https://github.com/a2stuff/a2d/issues/536))
* Prevent copying a folder or volume into itself. ([#495](https://github.com/a2stuff/a2d/issues/495))
* Don't clear selection when clicking on a window's header. ([#362](https://github.com/a2stuff/a2d/issues/362))
* Don't initiate drag-select after a double-click. ([#545](https://github.com/a2stuff/a2d/issues/545))
* Don't wait for possible double click when clicking scrollbars. ([#183](https://github.com/a2stuff/a2d/issues/183))
* Conditionally restore `/RAM` after quitting Disk Copy. ([#333](https://github.com/a2stuff/a2d/issues/333))
* Clip target icon rendering while dragging. ([#381](https://github.com/a2stuff/a2d/issues/381))
* Fix various window sizing problems. ([#180](https://github.com/a2stuff/a2d/issues/180), [#514](https://github.com/a2stuff/a2d/issues/514))
* Prevent duplicate windows for the same directory. ([#144](https://github.com/a2stuff/a2d/issues/144))
* Fix **File > New Folder...** name field behavior when re-prompted. ([#127](https://github.com/a2stuff/a2d/issues/127))
* Fix **File > Rename...** name field when IP at the start. ([#232](https://github.com/a2stuff/a2d/issues/232))
* **File > New Folder...** / **File > Rename...** input no longer truncated after IP. ([#118](https://github.com/a2stuff/a2d/issues/118))
* Fix issues with **Special > Format a Disk...** dialog when re-shown. ([#177](https://github.com/a2stuff/a2d/issues/177))
* Fix vertical text overlaps in dialogs. ([#126](https://github.com/a2stuff/a2d/issues/126))
* Fix dialog inconsistencies. ([#207](https://github.com/a2stuff/a2d/issues/207), [#411](https://github.com/a2stuff/a2d/issues/411), [#528](https://github.com/a2stuff/a2d/issues/528))
* Fix numerous keyboard consistency issues. ([#328](https://github.com/a2stuff/a2d/issues/328), [#332](https://github.com/a2stuff/a2d/issues/332), [#336](https://github.com/a2stuff/a2d/issues/336), [#337](https://github.com/a2stuff/a2d/issues/337), [#341](https://github.com/a2stuff/a2d/issues/341), [#396](https://github.com/a2stuff/a2d/issues/396), [#406](https://github.com/a2stuff/a2d/issues/406))
* Clip long strings in dialogs. ([#465](https://github.com/a2stuff/a2d/issues/465))
* Prevent crashes and mis-painting when windows are offscreen. ([#555](https://github.com/a2stuff/a2d/issues/555))
* Prevent renaming, formatting, or erasing a volume to have the same name as another volume. ([#570](https://github.com/a2stuff/a2d/issues/570), [#577](https://github.com/a2stuff/a2d/issues/577))
* Disk Copy moved to a separate file that can be optionally removed, allowing other components to fit on a floppy disk. [#216](https://github.com/a2stuff/a2d/issues/216)
* File Picker Dialogs:
  * Correct sort order. ([#489](https://github.com/a2stuff/a2d/issues/489))
  * Correct IP placement/truncation when switching focus. ([#446](https://github.com/a2stuff/a2d/issues/446))
  * Fix iteration with Change Drive button. ([#410](https://github.com/a2stuff/a2d/issues/410))
  * Type-down selection (while holding Apple) is supported. ([#610](https://github.com/a2stuff/a2d/issues/610))
* Desk Accessories:
  * Date and Time:
    * Expanded to include both date and time. ([#11](https://github.com/a2stuff/a2d/issues/11))
    * Read-only on systems with a clock. On systems without a clock, date is saved for next session. ([#30](https://github.com/a2stuff/a2d/issues/30), [#39](https://github.com/a2stuff/a2d/issues/39))
    * Shows 12/24hr setting. ([#220](https://github.com/a2stuff/a2d/issues/220))
  * Calculator: Doesn't mis-paint when moved offscreen and other fixes. ([#33](https://github.com/a2stuff/a2d/issues/33), [#34](https://github.com/a2stuff/a2d/issues/34))
  * Sort Directory: Don't need to click before sorting. ([#17](https://github.com/a2stuff/a2d/issues/17))
  * Sort Directory: Support as many entries as DeskTop supports. ([#86](https://github.com/a2stuff/a2d/issues/86))
  * Prevent files in list from disappearing in certain cases. ([#487](https://github.com/a2stuff/a2d/issues/487))
* Hardware/Emulator Specific:
  * IIc Plus: Doesn't spin slot 5 drives constantly. (Use **Special > Check Drive**) ([#25](https://github.com/a2stuff/a2d/issues/25))
  * Laser 128: Avoid hangs checking SmartPort status. (Use **Special > Check Drive**) ([#138](https://github.com/a2stuff/a2d/issues/138))
  * IIgs: Color DHR is re-enabled on exit. ([#43](https://github.com/a2stuff/a2d/issues/43))
  * IIgs: Mono DHR is re-enabled when returning from system control panel. ([#193](https://github.com/a2stuff/a2d/issues/193), [#440](https://github.com/a2stuff/a2d/issues/440))
  * IIgs: `/RAM5` is now correctly recognized as a RAMCard. ([#438](https://github.com/a2stuff/a2d/issues/438), [#439](https://github.com/a2stuff/a2d/issues/439))
  * Macintosh LC PDS IIe Option Card: Doesn't crash on startup. ([#93](https://github.com/a2stuff/a2d/issues/93))
  * Macintosh LC PDS IIe Option Card: Correct problems with interrupts affecting AppleTalk. ([#129](https://github.com/a2stuff/a2d/issues/129))
  * KEGS-based IIgs Emulators: Don't crash on startup. ([#85](https://github.com/a2stuff/a2d/issues/85))
  * RGB cards: Color DHR is re-enabled on exit. ([#111](https://github.com/a2stuff/a2d/issues/111))
  * Avoid modifying Uthernet II registers. ([#280](https://github.com/a2stuff/a2d/issues/280))
  * GSplus: Fix formatting SmartPort devices. ([#309](https://github.com/a2stuff/a2d/issues/309))

A full list of fixes in 1.2 can be found at: https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aclosed+milestone%3A1.2

### Known Issues

* Other issues can be found at https://github.com/a2stuff/a2d/issues.

## 1.1

Final release by Version Soft/Apple Computer dated November 26, 1986.

See also:

* Jay Edwards' [MouseDesk/DeskTop History](https://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Misc/mousedesk.info)
* https://www.a2desktop.com/history
* https://www.a2desktop.com/releases
