# Apple II DeskTop

## 1.2 - alpha

### Enhancements

* Current time shown on right side of menu bar, if system has a clock. (#7)
* Up to 13 volumes are shown on the desktop. (#20)
* Up to 12 Desk Accessories are shown in the menu. (#90)
* Menus allow click-to-drop, click-to-select interaction. (#104)
* Add Special > Check Drive command to refresh a single drive. (#97)
* Show Text File DA: Keyboard support. Escape quits, arrows scroll. (#4)
* Reorganized/renamed several menu items. (#13)
* New icons for graphics, AppleWorks, relocatable, and IIgs-specific file types. (#105)
* Improvements to several existing icon bitmaps. (#74)
* DAs with high bit in aux-type set are skipped. (#102)

### Additional Desk Accessories

* Show Image File
  * Select an image file (8k Hires or 16k Double Hires, aux-first), then choose DA to view it.
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

### Notable Fixes

* Dates 00-39 are treated as 2000-2039; dates 100-127 are treated as 2000-2027. (#15)
* File > Quit returns to ProDOS 8 selector, and /RAM is reattached. (#3)
* Date DA: Read-only on systems with a clock. On systems without a clock, date is saved for next session. (#30, #39)
* Calculator DA: don't mis-paint when moved offscreen and other fixes. (#33, #34)
* Sort Directory DA: don't need to click before sorting. (#17)
* SELECTOR.LIST created if missing. (#92)
* Position desktop icons based on Slot/Drive assignment. (#94)
* Don't crash after renaming volume. (#99)
* Startup menu will include Slot 2. (#106)
* Correct odd behavior for file type $08 (#103)
* Hardware/Emulator Specific:
  * IIc Plus: don't spin slot 5 drives constantly. (Use Special > Check Drive) (#25)
  * Macintosh LC IIe Option Card: don't crash on startup. (#93)
  * IIgs: color DHR is re-enabled on exit. (#43)
  * KEGS-based IIgs emulators no longer crash on startup. (#85)

# 1.1

Final release by Apple Computer. November 26, 1986.

See Jay Edwards' [MouseDesk/DeskTop History](https://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Misc/mousedesk.info)
for more version information.
