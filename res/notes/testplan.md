# Release Qualification Test Cases

> Status: Work in Progress

# DeskTop

* Open a volume with double-click.
* Open a directory with double-click.
* Open a text file with double-click.

* Open a volume with File > Open.
* Open a directory with File > Open.
* Open a text file with File > Open.

* Create a new folder (File > New Folder) - verify that it is selected / scrolled into view.

* Move a file by dragging - same volume - target is window.
* Move a file by dragging - same volume - target is volume icon.
* Move a file by dragging - same volume - target is folder icon.

* Repeat the following cases with these modifiers: Open-Apple, Solid-Apple:
  * Copy a file by dragging - same volume - target is window, using modifier.
  * Copy a file by dragging - same volume - target is volume icon, using modifier.
  * Copy a file by dragging - same volume - target is folder icon, using modifier.

* Copy a file by dragging - different volume - target is window.
* Copy a file by dragging - different volume - target is volume icon.
* Copy a file by dragging - different volume - target is folder icon.

* Open a volume, open a folder, close the just volume window; re-open the volume, re-open the folder, ensure the previous window is activated.

* Launch DeskTop. Select a file icon. File > Rename.... Enter a unique name, hit OK. Verify that the icon updates with the new name.
* Launch DeskTop. Select a file icon. File > Rename.... Press OK without changing the name. Verify that the dialog is dismissed and the icon doesn't change.
* Launch DeskTop. Select a volume icon. File > Rename.... Enter a unique name, hit OK. Verify that the icon updates with the new name.
* Launch DeskTop. Select a volume icon. File > Rename.... Press OK without changing the name. Verify that the dialog is dismissed and the icon doesn't change.

* Launch DeskTop. Select an AppleWorks file icon. File > Rename..., and specify a name using a mix of uppercase and lowercase. Click OK. Close the containing window and re-open it. Verify that the filename case is retained.
* Launch DeskTop. Select an AppleWorks file icon. File > Duplicate..., and specify a name using a mix of uppercase and lowercase. Click OK. Close the containing window and re-open it. Verify that the filename case is retained.

* File > Get Info a file.
* File > Get Info a volume.

* Open a window. Position two icons so one overlaps another. Select both. Drag both to a new location. Verify that the icons are repainted in the new location, and erased from the old location.
* Open a window. Position two icons so one overlaps another. Select only one icon. Drag it to a new location. Verify that the the both icons repaint correctly.

* Position a volume icon in the middle of the DeskTop. Incrementally move a window so that it obscures all 8 positions around it (top, top right, right, etc). Ensure the icon repaints fully, and no part of the window is over-drawn.

* Launch DeskTop, File > Quit, run BASIC.SYSTEM. Ensure /RAM exists.

* File > Quit - verify that there is no crash under ProDOS 8.

* Run on Laser 128; verify that 800k image files on Floppy Emu show as 3.5" floppy icons.
* Run on Laser 128, with a Floppy Emu. Select a volume icon. Special > Eject Disk. Verify that the Floppy Emu does not crash.
* Run on system with realtime clock; verify that time shows in top-right of menu.

* Open folder with new files. Use File > Get Info; verify dates after 1999 show correctly.
* Open folder with new files. Use View > By Date; verify dates after 1999 show correctly.

* Open a window for a volume; open a window for a folder; close volume window; close folder window. Repeat 10 times to verify that the volume table doesn't have leaks.

* Run DeskTop on a IIc+ from a 3.5" floppy on internal drive. Verify that the disk doesn't spin constantly.

* Run on a system with a single slot providing 3 or 4 drives (e.g. CFFA, BOOTI, Floppy Emu); verify that all show up.

* Verify that GS/OS filename cases show correctly (e.g. ProDOS 2.5 disk).

* Open two windows. Click the close box on the active window. Verify that only the active window closes.
* Repeat the following case with these modifiers: Open-Apple, Solid-Apple:
  * Open two windows. Hold modifier and click the close box on the active window. Verify that all windows close.
* Open two windows. Press Open-Apple+Solid-Apple+W. Verify that all windows close.

* Run DeskTop on a system with RAMWorks and using RAM.DRV.SYSTEM. Verify that subdirectories under DESK.ACC are copied to /RAM/DESKTOP/DESK.ACC.
* Run DeskTop on a system with Slinky Ramdisk. Verify that subdirectories under DESK.ACC are copied to /RAM5/DESKTOP/DESK.ACC (or appropriate volume path).

* Start DeskTop with a hard disk and a 5.25" floppy mounted. Remove the floppy, and double-click the floppy icon, and dismiss the "The volume cannot be found." dialog. Verify that the floppy icon disappears, and that no additional icons are added.

* On an RGB system (IIgs, etc), go to Control Panel, check RGB Color. Verify that the display shows in color. Preview an image, and verify that the image shows in color and the DeskTop remains in color after exiting.
* On an RGB system (IIgs, etc), go to Control Panel, uncheck RGB Color. Verify that the display shows in monochrome. Preview an image, and verify that the image shows in color and the DeskTop returns to monochrome after exiting.
* On an IIgs, go to Control Panel, check RGB Color. Verify that the display shows in color. Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that DeskTop remains in color.
* On an IIgs, go to Control Panel, uncheck RGB Color. Verify that the display shows in monochrome. Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that DeskTop resets to monochrome.

* Put image file in `DESK.ACC`, start DeskTop. Select it from the Apple menu. Verify image is shown.
* Put text file in `DESK.ACC`, start DeskTop. Select it from the Apple menu. Verify text is shown.
* Put font file in `DESK.ACC`, start DeskTop. Select it from the Apple menu. Verify font is shown.

* Put BASIC program in `DESK.ACC`, start DeskTop. Select it from the Apple menu. Verify it runs.
* Put System program in `DESK.ACC`, start DeskTop. Select it from the Apple menu. Verify it runs.

* Open a folder with no items. Verify window header says "0 Items"
* Open a folder with only one item. Verify window header says "1 Item"
* Open a folder with two or more items. Verify window header says "2 Items"

* Launch DeskTop. Open a window for a removable disk. Quit DeskTop. Remove the disk. Restart DeskTop. Open a different volume's window. Close it. Open it again. Verify that items in the File menu needing a window (New Folder, Close, etc) are correctly enabled.

* Launch DeskTop. Open a window for a removable disk. Quit DeskTop. Remove the disk. Restart DeskTop. Verify that 8 windows can be opened, and no render glitches occur.

* Launch DeskTop. Open a window. Select a file icon. Drag a selection rectangle around another file icon in the same window. Verify that the initial selection is cleared and only the second icon is selected.
* Launch DeskTop. Select a volume icon. Drag a selection rectangle around another volume icon. Verify that the initial selection is cleared and only the second icon is selected.

* Repeat the following cases with these modifiers: Open-Apple, Shift (on a IIgs), Shift (on a Platinum IIe):
  * Launch DeskTop. Click on a volume icon. Hold modifier and click a different volume icon. Verify that selection is extended.
  * Launch DeskTop. Select two volume icons. Hold modifier and click on the desktop, not on an icon. Verify that selection is not cleared.
  * Launch DeskTop. Select one or more volume icons. Hold modifier and click a volume icon. Verify that it is deselected.
  * Launch DeskTop. Hold modifier and double-click on a non-selected volume icon. Verify that it highlights then unhighlights, and does not open.
  * Launch DeskTop. Select a volume icon. Hold modifier and double-click the selected volume icon. Verify that it unhighlights then highlights, and does not open.
  * Launch DeskTop. Select a volume icon. Hold modifier down and drag a selection rectangle around another volume icon. Verify that both are selected.
  * Launch DeskTop. Open a volume containing files. Click on a file icon. Hold modifier and click a different file icon. Verify that selection is extended.
  * Launch DeskTop. Open a volume containing files. Select two file icons. Hold modifier and click on the window, not on an icon. Verify that selection is not cleared.
  * Launch DeskTop. Open a window. Select an icon. Hold modifier and double-click an empty spot in the window (not on an icon). Verify that the selection is not cleared.
  * Launch DeskTop. Open a window. Select an icon. Hold modifier down and drag a selection rectangle around another icon. Verify that both are selected.
  * Launch DeskTop. Open a window. Select one or more file icons. Hold modifier and click a file icon. Verify that it is deselected.
  * Launch DeskTop. Open a window. Hold modifier and double-click on a non-selected file icon. Verify that it highlights then unhighlights, and does not open.
  * Launch DeskTop. Open a window. Select a file icon. Hold modifier and double-click the selected file icon. Verify that it unhighlights then highlights, and does not open.
  * Launch DeskTop. Open a volume window. Hold modifier, and drag-select icons in the window. Release the modifier. Verify that the volume icon is no longer selected. Click an empty area in the window to clear selection. Verify that the selection clears.
  * Launch DeskTop. Open a volume window with many icons. Click on a file icon to select it. Modifier-click the icon to deselect it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.
  * Launch DeskTop. Open a volume window with many icons. Modifier-click on a file icon to select it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.

* Launch DeskTop. Click on a volume icon. Hold Solid-Apple and click on a different volume icon. Verify that selection changes to the second icon.
* Launch DeskTop. Open a volume containing files. Click on a file icon. Hold Solid-Apple and click on a different file icon. Verify that selection changes to the second icon.
* Run on Laser 128. Launch DeskTop. Open a volume. Click on icons one by one. Verify selection changes from icon to icon, and isn't extended as if a Open-Apple key/button or Shift is down.

* Launch DeskTop. Select two volume icons. Double-click one of the volume icons. Verify that two windows open.
* Launch DeskTop. Open a window. Select two folder icons. Double-click one of the folder icons. Verify that two windows open.
* Launch DeskTop. Open a window. Hold Solid-Apple and double-click a folder icon. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Open a window. Select a folder icon. Hold Solid-Apple and select File > Open. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Open a window. Select a folder icon. Hold Open-Apple and select File > Open. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Open a window. Select a folder icon. Press Open-Apple+Solid-Apple+O. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Open a window. Select a folder icon. Press Open-Apple+Solid-Apple+Down. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Ensure nothing is selected. Press Open-Apple+Solid-Apple+O. Verify that nothing happens.
* Launch DeskTop. Ensure nothing is selected. Press Open-Apple+Solid-Apple+Down. Verify that nothing happens.

* Launch DeskTop. Open a window. Locate an executable BIN file icon. Double-click it. Verify that nothing happens.
* Launch DeskTop. Open a window. Locate an executable BIN file icon. Hold Solid-Apple and double-click it. Verify that nothing happens.
* Launch DeskTop. Open a window. Locate an executable BIN file icon. Select File > Open. Verify that it executes.
* Launch DeskTop. Open a window. Locate an executable BIN file icon. Press Open-Apple+O. Verify that it executes.
* Launch DeskTop. Open a window. Locate an executable BIN file icon. Press Solid-Apple+O. Verify that it executes.

* Launch DeskTop. Try to move a file (drag on same volume) where there is not enough space to make a temporary copy. Verify that the error message says that the file is too large to move.
* Launch DeskTop. Try to copy a file (drag to different volume) where there is not enough space to make the copy. Verify that the error message says that the file is too large to copy.

* Launch DeskTop. Open a volume window. Select icons in the window. Switch window's view to by Name. Verify that File > Get Info is disabled. Switch view back to as Icons. Verify that no icons are shown as selected, and that File > Get Info is still disabled.
* Launch DeskTop. Open a volume window. Select volume icons on the desktop. Switch window's view to by Name. Verify that the volume icons are still selected, and that File > Get Info is still enabled (and shows the volume info). Switch window's view back to as Icons. Verify that the desktop volume icons are still selected.

* Launch DeskTop. Open a volume window. Select an icon. Click in the header area (items/use/etc). Verify that selection is not cleared.

* Launch DeskTop. Open a window with only one icon. Drag icon so name is to left of window bounds. Ensure icon name renders.

* Launch DeskTop. Open a volume window with icons. Drag leftmost icon to the left to make horizontal scrollbar activate. Click horizontal scrollbar so viewport shifts left. Verify dragged icon still renders.
* Launch DeskTop. Open a volume window with icons. Drag leftmost icon to the left to make horizontal scrollbar activate. Click horizontal scrollbar so viewport shifts left. Drag window to the right so it overlaps desktop icons. Verify DeskTop doesn't lock up.

* Launch DeskTop. Open a volume window with icons. Drag window so only header is visible. Verify that DeskTop doesn't render garbage or lock up.

* Launch DeskTop. Open two volume windows with icons. Drag top window down so only header is visible. Click on other window to activate it. Verify that the window header does not disappear.

* Launch DeskTop. Open a window with a single icon. Move the icon so it overlaps the left edge of the window. Verify scrollbar appears. Hold scroll arrow. Verify icon scrolls into view, and eventually the scrollbar deactivates. Repeat with right edge.
* Launch DeskTop. Open a window with 11-15 icons. Verify scrollbars are not active.

* Launch DeskTop. Open a folder using Apple menu (e.g. Control Panels) or a shortcut. Verify that the used/free numbers are non-zero.
* Launch DeskTop. Open a subdirectory folder. Quit and relaunch DeskTop. Verify that the used/free numbers in the restored window are non-zero.

* Launch DeskTop. Open a folder containing subfolders. Select all the icons in the folder. Double-click one of the subfolders. Verify that the selection is retained in the parent window. Position the child window over top of the parent so it overlaps some of the icons. Close the child window. Verify that the parent window correctly shows only the previously opened folder as highlighted.

* Launch DeskTop. Open a window containing folders and files. Scroll window so a folder is partially or fully outside the visual area (e.g. behind title bar, header, or scrollbars). Drag a file over the obscured part of the folder. Verify the folder doesn't highlight.
* Launch DeskTop. Open a window containing folders and files. Scroll window so a folder is partially or fully outside the visual area (e.g. behind title bar, header, or scrollbars). Drag a file over the visible part of the folder. Verify the folder highlights but doesn't render past window bounds.

* Launch DeskTop. Select a 32MB volume. File > Get Info. Verify total size shows as 32,768K not 0K.

* Launch DeskTop. Open a window containing folders and files. Open another window, for an empty volume. Drag an icon from the first to the second. Ensure no scrollbars activate in the target window.
* Launch DeskTop. Open a window containing folders and files, with no scrollbars active. Open another window. Drag an icon from the first to the second. Ensure no scrollbars activate in the source window.

* Set up multiple volumes (e.g. V1, V2, V3). Launch DeskTop. Use Shortcuts > Add a Shortcut... to add an shortcut on V2. Run Shortcuts > Edit a Shortcut... and select the added shortcut to edit it, which should init the dialog showing V2. Click Change Drive. Verify that the picker now shows V3.

* Launch DeskTop. Open some windows. Special > Disk Copy. Quit back to DeskTop. Verify that the windows are restored.
* Launch DeskTop. Close all windows. Special > Disk Copy. Quit back to DeskTop. Verify that no windows are restored.

* Repeat the following cases for File > New Folder, File > Rename, and File > Duplicate:
  * Launch DeskTop. Open a window (if needed) select a file. Run the command. Enter a name, but place the IP in the middle of the name (e.g. "exam|ple"). Click OK. Verify that the full name is used.

* Configure a system with removable disks. (e.g. Virtual II OmniDisks) Launch DeskTop. Verify that volume icons are positioned without gaps (down from the top-right, then across the bottom right to left). Eject one of the middle volumes. Verify icon disappears. Insert a new volume. Verify icon takes up the vacated spot. Repeat test, ejecting multiple volumes verify that positions are filled in order (down from the top-right, etc).

* Launch DeskTop. Open a window. File > New Folder..., enter name, OK. Copy the file to another folder or volume. Verify that the "Files remaining" count bottoms out at 0.
* Launch DeskTop. Open a window. File > New Folder..., enter name, OK. Move the file to another folder or volume. Verify that the "Files remaining" count bottoms out at 0.

* Launch DeskTop. Open a volume. File > New Folder..., create A. File > New Folder..., create B. Drag B onto A. File > New folder.... Verify DeskTop doesn't hang.

* Launch DeskTop. Open a window with files with dates with long month names (e.g. "February 29, 2020"). View > by Name. Resize the window so the lines are cut off on the right. Move the horizontal scrollbar all the way to the right. Verify that the right edges of all lines are visible.

* Launch DeskTop. Double-click on a file that DeskTop can't open (and where no BASIS.SYSTEM is present). Click OK in the "This file cannot be opened." alert. Double-click on the file again. Verify that the alert renders with an opaque background.

* Launch DeskTop. Create a sequence of nested folders approaching maximum path length, e.g. /RAM/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789/ABCDEF12345. Try to copy a file into the folder. Verify that stray pixels do not appear in the top line of the screen.

* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Delete the LOCAL/DESKTOP.CONFIG file from the startup disk, if it was present. Go into Control Panels and change a setting. Verify that LOCAL/DESKTOP.CONFIG is written to the startup disk.
* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Delete the LOCAL/SELECTOR.LIST file from the startup disk, if it was present. Shortcuts > Add a Shortcut, and create a new shortcut. When prompted to save to the system disk, select OK. Verify that LOCAL/SELECTOR.LIST is written to the startup disk.

* Load DeskTop. Create a folder e.g. /RAM/F. Try to copy the folder into itself using File > Copy a File. Verify that an error is shown.
* Load DeskTop. Create a folder e.g. /RAM/F. Open the containing window, and the folder itself. Try to move it into itself by dragging. Verify that an error is shown.
* Load DeskTop. Create a folder e.g. /RAM/F, and a sibling folder e.g. /RAM/B. Open the containing window, and the first folder itself. Select both folders, and try to move both into the first folder's window by dragging. Verify that an error is shown before any moves occur.
* Load DeskTop. Create a folder e.g. /RAM/F. Open the containing window, and the folder itself. Try to copy it into itself by dragging with an Apple key depressed. Verify that an error is shown.
* Load DeskTop. Open a volume window. Drag a file from the volume window to the volume icon. Verify that an error is shown.
* Load DeskTop. Create a folder, and a file within the folder with the same name as the folder (e.g. /RAM/F and /RAM/F/F). Try to copy the file over the folder using File > Copy a File.... Verify that an error is shown.
* Load DeskTop. Create a folder, and a file within the folder with the same name as the folder (e.g. /RAM/F and /RAM/F/F). Try to move the file over the folder using drag and drop. Verify that an error is shown.
* Load DeskTop. Create a folder, and a file within the folder with the same name as the folder, and another file (e.g. /RAM/F and /RAM/F/F and /RAM/F/B). Select both files and try to move them into the parent folder using drag and drop. Verify that an error is shown before any files are moved.

* Load DeskTop. Open a volume. Adjust the window size so that horizontal and vertical scrolling is required. Scroll to the bottom-right. Quit DeskTop, reload. Verify that the window size was restored correctly.
* Load DeskTop. Open a volume. Quit DeskTop, reload. Verify that the volume window was restored, and that the volume icon is marked open. Close the volume window. Verify that the volume icon is no longer marked open.

* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Shortcuts > Add a Shortcut.... Create a shortcut, click OK. Verify that when the "Do you want to save the new list on the system disk?" warning appears that the desktop volume icons repaint.

* Ensure the startup volume has a name that would be case-adjusted by DeskTop, e.g. /HD. Launch DeskTop. Open the startup volume. Apple > Control Panels. Drag a DA file to the startup volume window. Verify that the file is moved, not copied.

* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Try opening volumes/folders until there are less than 8 windows but more than 127 icons. Verify that the "A window must be closed..." dialog has no Cancel button.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Verify that 127 icons can be shown.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. File > New Folder. Verify that a warning is shown and the window is closed. Repeat, with multiple windows open. Verify that everything repaints correctly, and that no volume or folder icon incorrectly displays as opened.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. Use File > Copy a File to copy a file into a directory represented by an open window. Verify that after the copy, a warning is shown, the window is closed, and that no volume or folder icon incorrectly displays as opened.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. Drag a file from another volume (to copy it) into an open window. Verify that after a copy, a warning is shown and the window is closed, and that no volume or folder icon incorrectly displays as opened.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. Drag a volume icon into an open window. Verify that after the copy, a warning is shown and the window is closed, and that no volume or folder icon incorrectly displays as opened.

* Load Selector. Put a disk in Slot 6, Drive 1. Startup > Slot 6. Verify that the system boots the disk. Repeat for all other slots with drives.

* Launch DeskTop. Copy multiple selected files to another volume. Repeat the copy. When prompted to overwrite, alternate clicking Yes and No. Verify that the "Files remaining" count decreases to zero.
* Launch DeskTop. Copy a folder containing multiple files to another volume. Repeat the copy. When prompted to overwrite, alternate clicking Yes and No. Verify that the "Files remaining" count decreases to zero.
* Configure a IIgs system with ejectable disks. Launch DeskTop. Select the ejectable volume. Special > Eject Disk. Verify that an alert is not shown.

* Use an emulator that supports dynamically inserting SmartPort disks, e.g. Virtual ][. Insert disks A, B, C, D in drives starting at the highest slot first, e.g. S7D1, S7D2, S5D1, S5D2. Launch DeskTop. Verify that the disks appear in order A, B, C, D. Eject the disks, and wait for DeskTop to remove the icons. Pause the emulator, and reinsert the disks in the same drives. Un-pause the emulator. Verify that the disks appear on the DeskTop in the same order. Eject the disks again, pause, and insert the disks into the drives in reverse order (A in S5D2, etc). Un-pause the emulator. Verify that the disks appear in reverse order on the DeskTop.

* Configure a system with two volumes of the same name. Launch DeskTop. Verify that an error is shown, and only one volume appears.
* Launch DeskTop. Rename a volume to have the same name as another. Verify that an error is shown and the icon is removed.

* Launch DeskTop. Open a window. File > Quit. Launch DeskTop again. Ensure the window is restored. Try to drag-select volume icons. Verify that they are selected.

* Launch DeskTop. Select a volume icon, where the volume contains no files. Special > Get Size. Verify that numbers are shown (0) for number of files and size used.
* Launch DeskTop. Select a file icon. Special > Get Size. Verify that the size shown is correct. Select a directory. Special > Get Size, and dismiss. Now select the original file icon again, and Special > Get Size. Verify that the size shown is still correct.
* Use real hardware, not an emulator. Launch DeskTop. Select a volume icon. Special > Get Size. Verify that a "The specified path name is invalid." alert is not shown.

* Launch DeskTop. Select a volume with more than 255 files in a folder (e.g. Total Replay). Special > Get Size. Verify that the count finishes.
* Configure a system with a RAMCard of at least 1MB. On a physical volume, create a directory with a system file (e.g. BASIC.SYSTEM) and a subdirectory. In the subdirectory, create 256 normal files followed by a subdirectory (with some files) followed by more files. Then run the following tests:
  * Launch DeskTop. Create a shortcut for the system file, set to copy to RAMCard at boot. Ensure DeskTop is set to copy to RAMCard on startup. Restart DeskTop. Verify that the directory is successfully copied.
  * Launch DeskTop. Create a shortcut for the system file, set to copy to RAMCard at first use. Ensure DeskTop is set to copy to RAMCard on startup. Ensure DeskTop is set to launch Selector. Quit DeskTop. Launch Selector. Select the shortcut. Verify that the directory is successfully copied.

* Launch DeskTop. Select a volume. File > Open. Verify that the volume icon is still selected.
* Launch DeskTop. Double-click a volume. Verify that the volume icon is still selected.
* Launch DeskTop. Select a folder. File > Open. Verify that the folder icon is no longer selected.
* Launch DeskTop. Double-click a folder. Verify that the folder icon is no longer selected.
* Launch DeskTop. Open a window containing a folder. Position the window so that the folder icon will not be obscured when opened. Select the folder. File > Open. Verify that the folder icon is no longer selected.
* Launch DeskTop. Open a window containing a folder. Position the window so that the folder icon will not be obscured when opened. Double-click the folder. Verify that the folder icon is no longer selected.

* Configure a system with 14 devices. Launch and then exit DeskTop. Load another ProDOS app that enumerates devices. Verify that all expected devices are present, and that there's no "Slot 0, Drive 1" entry.

* Launch DeskTop. Open a volume window. Open a folder. Close the volume window. Press Open-Apple+Up. Verify that the volume window re-opens, and the that the folder icon is selected. Press Open-Apple+Up again. Verify that the volume icon is selected.
* Launch DeskTop. Open a volume window. Open a folder. Press Open-Apple+Up. Verify that the volume window is activated, and the that the folder icon is selected. Press Open-Apple+Up again. Verify that the volume icon is selected.
* Launch DeskTop. Open a volume window. Open a folder. Activate the volume window. Switch the window's view to by Name. Activate the folder window. Press Open-Apple+Up. Verify that the volume window is activated. Press Open-Apple+Up again. Verify that the volume icon is selected.

* Launch DeskTop. Open a volume window. Open a folder. Close the volume window. Press Open-Apple+Solid-Apple+Up. Verify that the volume window re-opens, and that the folder window closes, and the that the folder icon is selected. Press Open-Apple+Solid-Apple+Up again. Verify that the volume window closes, and the volume icon is selected.
* Launch DeskTop. Open a volume window. Open a folder. Press Open-Apple+Solid-Apple+Up. Verify that the volume window is activated, and that the folder window closes, and the that the folder icon is selected. Press Open-Apple+Solid-Apple+Up again. Verify that the volume window closes, and that the volume icon is selected.
* Launch DeskTop. Open a volume window. Open a folder. Activate the volume window. Switch the window's view to by Name. Activate the folder window. Press Open-Apple+Solid-Apple+Up. Verify that the volume window is activated, and that the folder window closes. Press Open-Apple+Solid-Apple+Up again. Verify that the volume window closes, and that the volume icon is selected.

* Launch DeskTop. Position a volume icon near the center of the screen. Drag another volume onto it. Verify that after the copy dialog closes, the volume icon is still visible.
* Launch DeskTop. Position a volume icon near the center of the screen. Open the volume icon, and move/size the window to ensure the volume icon is visible. Drag another volume onto the window. Verify that after the copy dialog closes, the volume icon is still visible.
* Launch DeskTop. Position a volume icon near the center of the screen. Open the volume icon, and move/size the window to ensure the volume icon is visible. Drag another volume onto the window. Drag the same volume icon onto the window. Cancel the copy. Verify that after the copy dialog closes, the volume icon is still visible.

* Launch DeskTop. Position a volume icon near the center of the screen. Open a second volume icon, and move/size the window to ensure the first volume icon is visible. Drag a file icon onto the first volume icon. Verify that after the copy dialog closes, the volume icon is still visible.
* Launch DeskTop. Position a volume icon near the center of the screen. Open the volume icon, and move/size the window to ensure the volume icon is visible. Open a second volume icon, and move/size the window to ensure the first volume icon is visible. Drag a file icon from the second window into the first window. Verify that after the copy dialog closes, the volume icon is still visible.
* Launch DeskTop. Position a volume icon near the center of the screen. Open the volume icon, and move/size the window to ensure the volume icon is visible. Open a second volume icon, and move/size the window to ensure the first volume icon is visible. Drag a file icon from the second window into the first window. Repeat the drag, and cancel the copy dialog. Verify that after the copy dialog closes, the volume icon is still visible.
* Launch DeskTop. Position a volume icon near the center of the screen. Open the volume icon, and move/size the window to ensure the volume icon is visible. Drag a file icon to the trash. Verify that after the delete dialog closes, the volume icon is still visible.

* Launch DeskTop. Clear the selection (e.g. by clicking on the DeskTop). Verify that:
  * Special > Eject Disk is disabled.
  * Special > Check Drive is disabled.
  * File > Duplicate... is disabled.
  * File > Open, File > Get Info, File > Rename..., Special > Lock..., Special > Unlock..., and Special > Get Size are disabled.
* Launch DeskTop. Select only the Trash icon. Verify that:
  * Special > Eject Disk is disabled.
  * Special > Check Drive is disabled.
  * File > Duplicate... is disabled.
  * File > Open, File > Get Info, File > Rename..., Special > Lock..., Special > Unlock..., and Special > Get Size are disabled.
* Launch DeskTop. Select a volume. Verify that:
  * Special > Eject Disk is enabled.
  * Special > Check Drive is enabled.
  * File > Duplicate... is disabled.
  * File > Open, File > Get Info, File > Rename..., Special > Lock..., Special > Unlock..., and Special > Get Size are enabled.
* Launch DeskTop. Select a volume icon and the Trash icon. Verify that:
  * Special > Eject Disk is enabled.
  * Special > Check Drive is enabled.
  * File > Duplicate... is disabled.
  * File > Open, File > Get Info, File > Rename..., Special > Lock..., Special > Unlock..., and Special > Get Size are enabled.
* Launch DeskTop. Open a volume window, and select a file. Verify that:
  * Special > Eject Disk is disabled.
  * Special > Check Drive is disabled.
  * File > Duplicate... is enabled.
  * File > Open, File > Get Info, File > Rename..., Special > Lock..., Special > Unlock..., and Special > Get Size are enabled.
* Launch DeskTop. Close all windows. Verify that File > New Folder..., File > Close Window, File > Close All, and everything in the View menu are disabled.
* Launch DeskTop. Open a windows. Verify that File > New Folder..., File > Close Window, File > Close All, and everything in the View menu are enabled.
* Delete the LOCAL/SELECTOR.LIST file from the startup disk, if it was present. Launch DeskTop. Verify that Shortcuts > Edit a Shortcut..., Shortcuts > Delete a Shortcut..., and Shortcuts > Run a Shortcut... are disabled. Add a shortcut. Verify that Shortcuts > Edit a Shortcut..., Shortcuts > Delete a Shortcut..., and Shortcuts > Run a Shortcut... are now enabled.

* Launch DeskTop. Create a shortcut, "menu and list" / "at boot". Create a second shortcut, "menu and list", "at first use". Create a third shortcut, "menu and list", "never". Delete the first shortcut. Verify that the remaining shortcuts are "at first use" and "never".
* Launch DeskTop. Create a shortcut, "list only" / "at boot". Create a second shortcut, "list only", "at first use". Create a third shortcut, "list only", "never". Delete the first shortcut. Verify that the remaining shortcuts are "at first use" and "never".

* Launch DeskTop. Open 3 windows. Close the top one. Verify that the repaint is correct.
* Launch DeskTop. Close all windows. Press an arrow key multiple times. Verify that only one volume icon is highlighted at a time.

* For the following cases, "obscure a window" means to move a window to the bottom of the screen so that only the title bar is visible:
  * Launch DeskTop. Open a window with icons. View > by Name. Obscure the window. View > as Icons. Verify that the window contents don't appear on the desktop. Move the window so the contents are visible. Verify that it contains icons.
  * Launch DeskTop. Open a window with icons. Obscure the window. View > by Name. Verify that the window contents don't appear on the desktop. Move the window so the contents are visible. Verify that the contents display as a list.
  * Launch DeskTop. Open a window with at least two icons. Select the first icon. Obscure the window. Press the right arrow key. Verify that the icons don't appear on the desktop.
  * Launch DeskTop. Open a window with icons. Obscure the window. File > Select All icon. Verify that the icons don't appear on the desktop.
  * Launch DeskTop. Open a window with icons. File > Select All icon. Obscure the window. Click on the desktop to clear selection. Verify that the icons don't appear on the desktop.
  * Launch DeskTop. Open a window with folder icons. Open a second window from one of the folders. Verify that the folder icon in the first window is shaded. Obscure the first window. Close the second window. Verify that the folder icon doesn't appear on the desktop.
  * Launch DeskTop. Open a window with icons. Select (but don't open) a folder. Obscure the window. File > Open. Verify that the folder icon does not appear on the desktop.
  * Launch DeskTop. Open a window with icons. Select (but don't open) a folder containing 127 icons. Obscure the window. File > Open. Verify that the folder icon does not appear on the desktop.
  * Launch DeskTop. Open a window. Obscure the window. File > New Folder, enter a name, OK. Verify that the folder icon doesn't appear on the desktop.
  * Launch DeskTop. Open a window with icons. Obscure the window. File > Quit. Relaunch DeskTop. Verify that the restored window's icons don't appear on the desktop, and that the menu bar is not glitched.
  * Launch DeskTop. Open two windows with icons. Obscure one window. Click on the other window's title bar. Click on the obscured window's title bar. Verify that the window contents don't repaint on the desktop.
  * Launch DeskTop. Open two windows with icons. Activate a window, View > by Name, and then obscure the window. Click on the other window's title bar. Click on the obscured window's title bar. Verify that the window contents don't repaint on the desktop.
  * Launch DeskTop. Open a window with icons. Select an icon. Obscure the window. File > Rename..., enter a new name, OK. Verify that the icon does not paint on the desktop.

* Launch DeskTop. Open a window containing a folder. Open the folder's window. Activate the first window by clicking on it. Activate the second window by clicking on it. Verify that the folder icon is not selected by moving the second window around to force repaints.

* Launch DeskTop. Open a window for a volume icon. Open a folder within the window. Select the volume icon. Special > Check Drive. Verify that both windows are closed.

* Launch DeskTop. Drag a file to a same-volume window so it is moved, not copied. Use File > Copy a File... to copy a file. Verify that the file is indeed copied, not moved.
* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Drag a file to a same-volume window so it is moved. Configure a shortcut to copy to RAMCard "at first use". Invoke the shortcut. Verify that the shortcut's files were indeed copied, not moved.

* Launch DeskTop. Open a window. Select a file icon. Apple > Control Panels. Verify that the previously selected file is no longer selected.
* Launch DeskTop. Configure a shortcut with the target being a directory. Open a window. Select a file icon. Invoke the shortcut. Verify that the previously selected file is no longer selected.

* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Configure a shortcut with the target in the root of a volume, and to Copy to RAMCard at first use. Quit DeskTop. Launch Selector. Invoke the shortcut. Verify that the copy count goes to zero and doesn't blank out.
* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Configure a shortcut with the target in a directory, not the root of a volume, and to Copy to RAMCard at first use. Quit DeskTop. Launch Selector. Invoke the shortcut. Verify that the copy count goes to zero and doesn't blank out.
* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Configure a shortcut set to Copy to RAMCard at first use. Invoke the shortcut. Verify that it correctly copies to the RAMCard and runs.

* Launch DeskTop. Open a window containing many folders. Select up to 7 folders. File > Open. Verify that as windows continue to open, the originally selected folders don't mispaint on top of them. (This will be easier to observe in emulators with acceleration disabled.)

* Launch DeskTop. Open a window containing multiple icons. Drag-select several icons. Click in the window to clear selection. Click on a volume icon. Click elsewhere on the desktop. Verify the icon isn't mispainted.
* Launch DeskTop. Open a window containing multiple icons. Drag-select several icons. Click in the window to clear selection. Click on a volume icon. File > Rename.... Enter a new valid name, and click OK. Verify that no alert is shown.

* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Modify a shortcut. Verify that no prompt is shown. Power cycle and launch DeskTop. Verify that the shortcut modifications are present.
* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Modify a shortcut. Verify that a prompt is shown asking about saving the changes. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the shortcut modifications are present.
* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Modify a shortcut. Verify that a prompt is shown asking about saving the changes. Click OK. Verify that another prompt is shown asking to insert the system disk. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the shortcut modifications are present.

* Repeat the following cases with the Startup Options and Control Panel DAs, and the Date and Time DA (on a system without a real-time clock):
  * Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Launch the DA and modify a setting. Verify that no prompt is shown. Power cycle and launch DeskTop. Verify that the modifications are present.
  * Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Launch the DA and Modify a setting. Verify that a prompt is shown asking about saving the changes. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the modifications are present.
  * Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Launch the DA and modify a setting. Verify that a prompt is shown asking about saving the changes. Click OK. Verify that another prompt is shown asking to insert the system disk. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the modifications are present.

* Launch DeskTop. Select a volume icon. File > Rename.... Enter the name of another volume. Verify that a "That name already exists." alert is shown. Click OK. Verify that the Rename dialog is still showing.
* Launch DeskTop. Open a window. Select a file icon. File > Rename.... Enter the name of file in the same window. Verify that a "That name already exists." alert is shown. Click OK. Verify that the Rename dialog is still showing.
* Launch DeskTop. File > Copy a File.... Select a file, and click OK. Click OK without changing the destination name. Verify that a "That name already exists." alert is shown. Click OK. Verify that the Copy a File dialog is still showing.
* Launch DeskTop. File > Copy a File.... Replace the text of the first field with "ABC". Click OK. Verify that the second field is initialized to a valid path.
* Launch DeskTop. Open a volume window. Open a folder window. Select the volume icon and rename it. Verify that neither window is closed, and volume window is renamed.

* Launch DeskTop. Select a SYS file. Rename it to have a .SYSTEM suffix. Verify that it has an application (diamond and hand) icon, without moving.
* Launch DeskTop. Select a SYS file. Rename it to not have a .SYSTEM suffix. Verify that it has a system (computer) icon, without moving.
* Launch DeskTop. Select a TXT file. Rename it to have a .SHK suffix. Verify that it has an archive icon, without moving.
* Launch DeskTop. Select a TXT file. Rename it to have a .BXY suffix. Verify that it has an archive icon, without moving.
* Launch DeskTop. Select a TXT file. Rename it to have a .BNY suffix. Verify that it has an archive icon, without moving.

* Launch DeskTop. Open a window. Create folders A, B and C. Open A, and create a folder X. Open B, and create a folder Y. Drag A and B into C. Double-click on X. Verify it opens. Double-click on Y. Verify it opens. Open C. Double-click on A. Verify that the existing A window activates. Double click on B. Verify that the existing B window activates.

* Launch DeskTop. Open a window. Create a folder with a short name (e.g. "A"). Open the folder. Drag the folder's window so it covers just the left edge of the icon. Drag it away. Verify that the folder repaints. Repeat for the right edge.

* Repeat the following cases for Special > Format a Disk and Special > Erase a Disk:
  * Launch DeskTop. Run the command. Ensure left/right arrows move selection correctly.
  * Launch DeskTop. Run the command. Verify that the device order shown matches the order of volumes shown on the DeskTop (boot device first, etc). Select a device and proceed with the operation. Verify the correct device was formatted or erased.
  * Launch DeskTop. Run the command. For the new name, enter a volume name not currently in use. Verify that you are not prompted for a new name.
  * Launch DeskTop. Run the command. For the new name, enter the name of a volume in a different slot/drive. Verify that an alert shows, indicating that the name is in use.
  * Launch DeskTop. Run the command. For the new name, enter the name of the current disk in that slot/drive. Verify that you are not prompted for a new name.
  * Launch DeskTop. Run the command. Select a disk (other than the startup disk) and click OK. Enter a name, but place the IP in the middle of the name (e.g. "exam|ple"). Click OK. Verify that the full name is used.
  * Configure a system with at least 9 volumes. Launch DeskTop. Run the command. Select a volume in the third column. Click OK. Verify that the selection rect is fully erased.
  * Configure a system with 13 volumes, not counting /RAM. Launch DeskTop. Run the command. Verify that the boot device is excluded from the list so that only 12 devices are shown. Verify using the arrow keys that there aren't any overlapping volume entries.

* Launch DeskTop. Open a window. File > New Folder..., enter a unique name, OK. File > New Folder..., enter the same name, OK. Verify that an alert is shown. Dismiss the alert. Verify that the input field still has the previously typed name.

* Launch DeskTop. Clear selection by closing all windows and clicking on the desktop. Press Apple+Down. Verify that nothing happens.

* Launch DeskTop. Open a volume window. View > by Name. Open a separate volume window. Open a folder window. Open a sub-folder window. View > by Name. Close the window. Verify DeskTop doesn't crash.

* Launch DeskTop. Create 8 shortcuts. Shortcuts > Add a Shortcut.... Check the first radio button. Pick a file, OK. Enter a name, OK. Verify that a relevant alert is shown.

* Repeat the following cases with these modifiers: Open-Apple, Solid-Apple:
  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Tab repeatedly. Verify that windows are activated and cycle in forward order (A, B, C, A, B, C, ...).
  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press \` repeatedly. Verify that windows are activated cycle in forward order (A, B, C, A, B, C, ...).
  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Shift+\` repeatedly. Verify that windows are activated cycle in reverse order (B, A, C, B, A, C, ...).
  * On a IIgs: Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Shift+Tab repeatedly. Verify that windows are activated cycle in reverse order (B, A, C, B, A, C, ...).
  * On a Platinum IIe: Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Shift+Tab repeatedly. Verify that windows are activated cycle in reverse order (B, A, C, B, A, C, ...).

* Launch DeskTop. Open a volume window containing a folder. Open the folder window. Note that the folder icon is shaded. Close the volume window. Open the volume window again. Verify that the folder icon is shaded.
* Launch DeskTop. Open a volume window. In the volume window, create a new folder F1 and open it. Note that the F1 icon is shaded. In the volume window, create a new folder F2. Verify that the F1 icon is still shaded.
* Launch DeskTop. Open a volume window containing a file and a folder. Open the folder window. Drag the file to the folder icon (not the window). Verify that the folder window activates and updates to show the file.

* Launch DeskTop. Shortcuts > Add a Shortcut... and create a shortcut for a volume directory that is not the first volume on the DeskTop. Shortcuts > Edit a Shortcut... and select the new shortcut. Verify that file picker shows both the correct disk name and the correct full path.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Verify that if the pathname is a volume directory (e.g. "/VOL") and either "at boot" or "at first use" is selected, then an alert is shown when trying to commit the dialog.

* Configure a system with a RAMCard, and ensure DeskTop is configured to copy itself to RAMCard on start. Launch DeskTop. Open the RAM Disk volume. Open the Desktop folder. Apple > Control Panels. Drag Desk.Acc from the Desktop folder to the Control.Panels window. Verify that an alert is shown that an item can't be movied or copied into itself.

* Launch DeskTop. Open a volume window. Select two files. File > Duplicate.... Leave the filename unchanged and click OK. Verify that an alert is shown, but the dialog is not dismissed. Change the name and click OK. Verify that a prompt is shown for the second file.
* Launch DeskTop. Open a volume window. Select two files. File > Duplicate.... Change the filename to the name of another file in the directory and click OK. Verify that an alert is shown, but the dialog is not dismissed. Change the name and click OK. Verify that a prompt is shown for the second file.

* Perform the following tests in DeskTop using Mouse Keys mode:
  * Use the arrow keys to move the mouse to the top, bottom, left, and right edges of the screen. Verify that the mouse is clamped to the edges and does not wrap.
  * Select an icon. Press the Return key. Verify that Mouse Keys mode is not silently exited, and the cursor is not distorted.
  * Use keys to click on a menu. Without holding the button down, move over the menu items. Verify that the menu does not spontaneously close.
  * Use keys to double-click on an icon. Verify it opens.

* Configure a IIgs via the system control panel to have a RAM disk:
  * Launch DeskTop. Verify that the Ram5 volume is shown with a RAMDisk icon.
  * Configure DeskTop to copy to RAMCard on startup, and restart. Verify it is copied to /RAM5.

* Launch DeskTop. Try to copy files including a GS/OS forked file in the selection. Verify that an alert is shown. Verify that if OK is clicked, the operation continues with other files, and if Cancel is clicked the operation is aborted.
* Launch DeskTop. Try to copy files including a GS/OS forked file contained in a selected folder. Verify that an alert is shown. Verify that if OK is clicked, the operation continues with other files, and if Cancel is clicked the operation is aborted.
* Launch DeskTop. Try to delete files including a GS/OS forked file in the selection. Verify that an alert is shown. Verify that if OK is clicked, the operation continues with other files, and if Cancel is clicked the operation is aborted.
* Launch DeskTop. Try to delete files including a GS/OS forked file contained in a selected folder. Verify that an alert is shown. Verify that if OK is clicked, the operation continues with other files, and if Cancel is clicked the operation is aborted. Note that non-empty directories will fail to be deleted.
* Launch DeskTop. Using drag/drop, try to copy or move a folder containing a GS/OS forked file, where the source and destination windows are visible. When an alert is shown, click OK. Verify that the source and destination windows are updated.
* Launch DeskTop. Using drag/drop, try to copy a volume containing a GS/OS forked file and other files, where the destination window is visible. When an alert is shown, click OK. Verify that the destination window are updated.
* Launch DeskTop. Using File > Copy a File..., try to copy a folder containing a GS/OS forked file, where the source and destination windows are visible. When an alert is shown, click OK. Verify that the source and destination windows are updated.
* Launch DeskTop. Using drag/drop, try to delete a GS/OS forked file. When the delete confirmation dialog is shown, click Cancel. Verify that the source window is not updated.
* Launch DeskTop. Using drag/drop, try to delete a GS/OS forked file. When the delete confirmation dialog is shown, click OK. When an alert is shown, click OK. Verify that the source window is updated.
* Launch DeskTop. Using File > Delete a File..., try to delete a GS/OS forked file, where the containing window is visible. When the delete confirmation dialog is shown, click OK. When an alert is shown, click OK. Verify that the containing window is updated.

* Repeat the following:
  * For these permutations:
    * DeskTop (1) copied to RAMCard and (2) not copied to RAMCard.
    * Renaming (1) the volume that DeskTop loaded from, and renaming (2) the DeskTop folder itself.
  * Verify that the following still function:
    * File > Copy a File... (overlays)
    * Special > Disk Copy (and that File > Quit returns to DeskTop) (overlay + quit handler)
    * Apple > Calculator (desk accessories)
    * Apple > Control Panels (relative folders)
    * Control Panel, change desktop pattern, close, quit, restart (settings)
    * Windows are saved on exit/restored on restart (configuration)
    * Invoking another application, then quitting back to DeskTop (quit handler)
    * Modifying shortcuts (selector)

* Launch DeskTop. Open a volume window. Create a folder. Open the folder's window. Go back to the volume window, and drag the folder icon to the trash. Click OK in the delete confirmation dialog. Verify that the folder's window closes.
* Launch DeskTop. Open a volume window. Create a folder. Open the folder's window. File > Delete a File.... Select the folder and click OK. Click OK in the delete confirmation dialog. Verify that the folder's window closes.

* Launch DeskTop. Open the Control Panel DA. Use the pattern editor to create a custom pattern, then click the desktop preview to apply it. Close the DA. Open the Control Panel DA. Click the right arrow above the desktop preview. Verify that the default checkerboard pattern is shown.

* Close all windows. Start typing a volume name. Verify that a prefix-matching volume, or the subsequent volume (in lexicographic order) is selected, or the last volume (in lexicographic order).
* Close all windows. Start typing a volume name. Move the moouse. Start typing another filename. Verify that the matching is reset.
* Open a window containing multiple files. Start typing a filename. Verify that a prefix-matching file or volume, or the subsequent file or volume (in lexicographic order), or the last file or volume (in lexicographic order) is selected. For example, if the files "Alfa" and "Whiskey" and the volume "November" are present, typing "A" selects "Alfa", typing "AB" selects "Alfa", typing "AL" selects "Alfa", typing "ALFAA" selects "November", typing "B" selects "November", typing "Z" selects "Whiskey". Repeat including file and volume names with numbers and periods.
* Open a window containing multiple files. Start typing a filename. Move the mouse. Start typing another filename. Verify that the matching is reset.
* Open a window containing no files. Start typing a filename. Verify that matching is done against the volume icons.
* Open a window containing one or more files starting with lowercase letters (AppleWorks or GS/OS). Verify the files appear with correct names. Press a letter. Verify that the first file starting with that letter is selected.

* Repeat the following:
  * For these permutations:
    * Close all windows.
    * Open a window containing no file icons.
    * Open a window containing file icons.
  * Run these steps:
    * Clear selection. Press Tab repeatedly. Verify that icons are selected in lexicographic order.
    * Select an icon. Press Tab. Verify that the next icon in lexicographic order is selected.
    * Clear selection. Press \` repeatedly. Verify that icons are selected in lexicographic order.
    * Select an icon. Press \`. Verify that the next icon in lexicographic order is selected.
    * Clear selection. Press Shift+\` repeatedly. Verify that icons are selected in reverse lexicographic order.
    * Select an icon. Press Shift+\`. Verify that the previous icon in lexicographic order is selected.
  * On a IIgs and a Platinum IIe:
    * Clear selection. Press Shift+Tab repeatedly. Verify that icons are selected in reverse lexicographic order.
    * Select an icon. Press Shift+Tab. Verify that the previous icon in lexicographic order is selected.

* Repeat the following, with a volume icon (A), an open volume window (B) with a folder icon (C), and a window for that folder (D).
  * Drag a file from another volume onto A. Verify that B activates and refreshes, and that B's used/free numbers update. Click on D. Verify that D's used/free numbers update.
  * Drag a file from another volume onto B. Verify that B activates and refreshes, and that B's item count/used/free numbers update. Click on D. Verify that D's used/free numbers update.
  * Copy a file from another volume onto B using File > Copy a File.... Verify that B activates and refreshes, and that B's item count/used/free numbers update. Click on D. Verify that D's used/free numbers update.
  * Drag a file from another volume onto D. Verify that D activates and refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Copy file from another volume onto D using File > Copy File.... Verify that D activates and refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Drag a file from B to the trash. Verify that B refreshes, and that B's item count/used/free numbers update. Click on D. Verify that D's used/free numbers update.
  * Delete a file from B using File > Delete a File.... Verify that B refreshes, and that B's item count/used/free numbers update. Click on D. Verify that D's used/free numbers update.
  * Drag a file from D to the trash. Verify that D refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Delete a file from D using File > Delete a File.... Verify that D refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Duplicate a file in D using File > Duplicate.... Verify that D refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Drag a file in B onto C while holding Apple to copy it. Verify that D activates and refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Drag a file in B onto D while holding Apple to copy it. Verify that D activates and refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.

# Preview

* Preview a text file; verify that up/down arrow keys scroll.
* Preview a text file; verify that Open-Apple plus up/down arrow keys scroll by page.
* Preview a text file; verify that Solid-Apple plus up/down arrow keys scroll by page.
* Preview a text file; verify that Escape key exits.
* Preview an image file; verify that Escape key exits.
* Preview an image file on IIgs or with RGB card; verify that space bar toggles color/mono.

* Configure a system with a realtime clock. Launch DeskTop. Preview an image file. Exit the preview. Verify that the menu bar clock reappears immediately.

# Desk Accessories

* Run Apple > Calculator. Drag Calculator window over a volume icon. Then drag calculator to the bottom of the screen so that only the title bar is visible. Verify that volume icon redraws properly.

* Run Apple > Calculator. Drag Calculator window to bottom of screen so only title bar is visible. Type numbers on the keyboard. Verify no numbers are painted on screen.

* Configure a system with a realtime clock. Launch DeskTop. Run the Date and Time desk accessory. Press Escape key. Verify the desk accessory exits. Repeat with the Return key.

* Configure a system with a Mockingboard and a Zip Chip, with acceleration enabled (MAME works). Launch DeskTop. Run the This Apple DA. Verify that the Mockingboard is detected.

* Run DeskTop on a system without a system clock. Run Apple > Control Panels > Date and Time. Set date. Reboot system, and re-run DeskTop. Create a new folder. Use File > Get Info. Verify that the date was saved/restored.

* On a system with a system clock, invoke Apple > Control Panels > Date and Time. Verify that the date and time are read-only.

* Configure a system with a realtime clock. Launch DeskTop. Run the Date and Time DA, and change the setting to 12 hour. Verify that the time is shown as 12-hour, and if less than 10 is displayed without a leading 0.
* Configure a system with a realtime clock. Launch DeskTop. Run the Date and Time DA, and change the setting to 24 hour. Verify that the time is shown as 24-hour, and if less than 10 is displayed with a leading 0.
* Configure a system without a realtime clock. Launch DeskTop. Run the Date and Time DA, and change the setting to 12 hour. Verify that the time is shown as 12-hour, and if less than 10 is displayed without a leading 0. Use the Right Arrow and Left Arrow keys and the mouse, and verify that the AM/PM field is selectable. Select the AM/PM field. Use the up and down arrow keys and the arrow buttons, and verify that the field toggles. Select the hours field. Use the up and down arrow keys and the arrow buttons, and verify that the field cycles from 1 through 12.
* Configure a system without a realtime clock. Launch DeskTop. Run the Date and Time DA, and change the setting to 24 hour. Verify that the time is shown as 24-hour, and if less than 10 is displayed with a leading 0. Use the Right Arrow and Left Arrow keys and the mouse, and verify that the AM/PM field is not selectable. Use the up and down arrow keys and the arrow buttons, and verify that the field cycles from 0 through 23.
* Configure a system without a realtime clock. Launch DeskTop. Run the Date and Time DA. Change the month and year, and verify that the day range is clamped to 28, 29, 30 or 31 as appropriate, including for leap years.

* Open a folder containing directory. Open a folder by double-clicking. Apple > Sort Directory. Verify that files are sorted by type/name.

* Launch DeskTop. Run Apple > Key Caps desk accessory. Turn Caps Lock off. Hold Apple (either one) and press the Q key. Verify the desk accessory exits.

* Launch DeskTop. Apple > Screen Savers. Select Melt. File > Open (or Apple+O). Click to exit. Press Apple+Down. Click to exit. Verify that the File menu is not highlighted.
* Configure a system with a realtime clock. Launch DeskTop. Apple > Screen Savers. Run a screen saver that uses the full graphics screen and conceals the menu (Flying Toasters or Melt). Exit it. Verify that the menu bar clock reappears immediately.

* Launch DeskTop. Apple > Screen Savers. Run Matrix. Click the mouse button. Verify that the screen saver exits. Run Matrix. Press a key. Verify that the screen saver exits.

* Launch DeskTop. Apple > About Apple II DeskTop. Click anywhere on the screen. Verify that the dialog closes.
* Launch DeskTop. Apple > About Apple II DeskTop. Press any non-modifier key screen. Verify that the dialog closes.

* Launch DeskTop, invoke Control Panel DA. Under Mouse Tracking, toggle Slow and Fast. Verify that the mouse cursor doesn't warp to a new position, and that the mouse cursor doesn't flash briefly on the left edge of the screen.

* Run System Speed DA. Click Normal then click OK. Verify DeskTop does not lock up.
* Run System Speed DA. Click Fast then click OK. Verify DeskTop does not lock up.
* Run DeskTop on a IIc. Launch Control Panel > System Speed. Click Normal and Fast. Verify that display does not switch from DHR to HR.

* Put `SHOW.IMAGE.FILE` in `DESK.ACC`, start DeskTop.
    * Select no icon, select DA from Apple menu. Verify nothing happens.
    * Select volume icon, select DA from Apple menu. Verify nothing happens.
    * Select image file icon, select DA from Apple menu. Verify image is shown.
* Put `SHOW.TEXT.FILE` in `DESK.ACC`, start DeskTop.
    * Select no icon, select DA from Apple menu. Verify nothing happens.
    * Select volume icon, select DA from Apple menu. Verify nothing happens.
    * Select text file icon, select DA from Apple menu. Verify text is shown.
* Put `SHOW.FONT.FILE` in `DESK.ACC`, start DeskTop.
    * Select no icon, select DA from Apple menu. Verify nothing happens.
    * Select volume icon, select DA from Apple menu. Verify nothing happens.
    * Select font file icon, select DA from Apple menu. Verify font is shown.

* Configure a device multiple drives connected to a Smartport controller on a higher slot, a single drive connected to a Smartport controller in a lower slot. Launch DeskTop, run the This Apple DA. Verify that the name on the lower slot doesn't have an extra character at the end.

* Run on Laser 128. Launch DeskTop. Copy a file to Ram5. Launch This Apple DA, close it. Verify that the file is still present on Ram5.

* Launch DeskTop. Apple > Puzzle. Verify that the puzzle does not show as scrambled until the mouse button is pressed. Repeat and verify that the puzzle is scrambled differently each time.

* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Ensure BASIC.SYSTEM is present on the boot volume. Launch DeskTop. Open a window. Apple > Run Basic Here. Verify that BASIC.SYSTEM starts.

* Configure a system without a RAMCard. Launch DeskTop. Verify that the volume containing DeskTop appears in the top right corner of the desktop. File > Copy a File.... Verify that the volume containing DeskTop is the first disk shown.
* Configure a system with a RAMCard, and set DeskTop to copy itself to the RAMCard on startup. Launch DeskTop. Verify that the non-RAMCard volume containing DeskTop appears in the top right corner of the desktop. File > Copy a File.... Verify that the non-RAMCard volume containing DeskTop is the first disk shown. From within DeskTop, launch another app e.g. Basic.system. Eject the DeskTop volume. Exit the app back to DeskTop. Verify that the remaining volumes appear in default order.
* Configure a system with a RAMCard, and set DeskTop to not copy itself to the RAMCard on startup. Launch DeskTop. Verify that the non-RAMCard volume containing DeskTop appears in the top right corner of the desktop. File > Copy a File.... Verify that the non-RAMCard volume containing DeskTop is the first disk shown.

* Open the Control Panel DA. Eject the startup volume. Close the DA without changing any settings. Verify that you are not prompted to save.
* Open the Control Panel DA. Eject the startup volume. Modify a setting and close the DA. Verify that you are prompted to save.
* Open the Startup Options DA. Eject the startup volume. Close the DA without changing any settings. Verify that you are not prompted to save.
* Open the Startup Options DA. Eject the startup volume. Modify a setting and close the DA. Verify that you are prompted to save.

* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open a volume window. Create a folder. Open the folder window, and close the volume window. Apple > Run Basic Here. Run a program such as `10 FOR I = 1 to 127-14 : ?CHR$(4);"SAVE F";I : NEXT` to create as many files as possible while keeping the total icon count to 127. `BYE` to return to DeskTop. Apple > Sort Directory. Make sure all the files are sorted lexicographically (e.g. F1, F10, F100, F101, ...)

# Selector

* Launch Selector, invoke BASIC.SYSTEM. Ensure /RAM exists.
* Launch Selector, invoke DeskTop, File > Quit, run BASIC.SYSTEM. Ensure /RAM exists.

* Launch Selector. Type Open-Apple and R. Ensure "Run a Program..." dialog appears
* Launch Selector. Type Solid-Apple and R. Ensure "Run a Program..." dialog appears
* Launch Selector. Type Open-Apple and 6. Ensure machine boots from Slot 6
* Launch Selector. Type Solid-Apple and 6. Ensure machine boots from Slot 6

* Launch Selector. Eject the disk with DeskTop on it. Type Q (don't click). Dismiss the dialog by hitting Esc. Verify that the dialog disappears, and the Apple menu is not shown.

* Configure a system without a RAMCard. Launch Selector. File > Run a Program.... Verify that the volume containing Selector is the first disk shown.
* Configure a system with a RAMCard, and set DeskTop to copy itself to the RAMCard on startup. Launch Selector. File > Run a Program.... Verify that the non-RAMCard volume containing Selector is the first disk shown.
* Configure a system with a RAMCard, and set DeskTop to not copy itself to the RAMCard on startup. Launch Selector. File > Run a Program.... Verify that the non-RAMCard volume containing Selector is the first disk shown.

# Disk Copy

* Launch DeskTop. Special > Disk Copy.... File > Quit. Special > Disk Copy.... Ensure drive list is correct.

* Launch DeskTop. Special > Disk Copy.... Press Escape key. Verify that menu keyboard mode starts.
* Launch DeskTop. Special > Disk Copy.... Press Open-Apple Q. Verify that DeskTop launches.
* Launch DeskTop. Special > Disk Copy.... Press Solid-Apple Q. Verify that DeskTop launches.

* Launch DeskTop. Special > Disk Copy. Copy a disk with more than 999 blocks. Verify thousands separators are shown in block counts.
* Launch DeskTop. Special > Disk Copy.... Copy a 32MB disk image using Quick Copy (the default mode). Verify that the screen is not garbled, and that the copy is successful.
* Launch DeskTop. Special > Disk Copy.... Copy a 32MB disk image using Disk Copy (the other mode). Verify that the screen is not garbled, and that the copy is successful.

* Launch DeskTop. Special > Disk Copy.... Make a device selection (using mouse or keyboard) but don't click OK. Open the menu (using mouse or keyboard) but dismiss it. Verify that source device wasn't accepted.

* Rename the DISK.COPY file to something else. Launch DeskTop. Special > Disk Copy.... Verify that an alert is shown. Cancel the alert. Verify that DeskTop continues to run.
* Launch DeskTop. Eject the boot volume. Special > Disk Copy.... Verify that an alert is shown. Cancel the alert. Verify that DeskTop continues to run.
* Launch DeskTop. Eject the boot volume. Special > Disk Copy.... Verify that an alert is shown. Re-insert the boot volume. Click OK in the alert. Verify that Disk Copy starts.
* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Special > Disk Copy.... Verify that Disk Copy starts.
* Launch DeskTop. Open and position a window. Special > Disk Copy.... File > Quit. Verify that DeskTop restores the window.
* On a IIgs, go to Control Panel, check RGB Color. Verify that the display shows in color. Special > Disk Copy.... Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that the display remains in color.
* On a IIgs, go to Control Panel, uncheck RGB Color. Verify that the display shows in monochrome. Special > Disk Copy.... Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that the display resets to monochrome.

* Configure a system with a RAMDisk in Slot 3, e.g. using RAM.DRV.SYSTEM or RAMAUX.SYSTEM. Launch DeskTop. Special > Disk Copy.... Verify that the RAMDisk appears.
* Configure a system with 9 or fewer drives. Launch DeskTop. Special > Disk Copy.... Verify that the scrollbar is inactive.
* Configure a system with 10 or more drives. Launch DeskTop. Special > Disk Copy.... Verify that the scrollbar is active.

# Alerts

* Launch DeskTop. Trigger an alert with only OK (e.g. running a shortcut with disk ejected). Verify that Escape key closes alert.
* Launch Selector. Trigger an alert with only OK (e.g. running an shortcut with disk ejected). Verify that Escape key closes alert.
* Launch DeskTop. Run Special > Disk Copy. Trigger an alert with only OK. Verify that Escape key closes alert.

# File Picker

This covers:

* Selector: File > Run a Program...
* DeskTop: File > Copy a File...
* DeskTop: File > Delete a File...
* DeskTop: Shortcuts > Add a Shortcut...
* DeskTop: Shortcuts > Edit a Shortcut...

Test the following in all of the above, except where called out specifically:

* Browse to a directory containing multiple files. Hold an Apple key and start typing a filename. Verify that a prefix-matching file or the subsequent file is selected, or the last file. For example, if the files "Alfa", "November" and "Whiskey" are present, typing "A" selects "Alfa", typing "AB" selects "Alfa", typing "AL" selects "Alfa", typing "ALFAA" selects "November", typing "B" selects "November", typing "Z" selects "Whiskey". Repeat including filenames with numbers and periods.
* Browse to a directory containing multiple files. Hold an Apple key and start typing a filename. Move the mouse, or press a key without holding Apple. Hold an Apple key and start typing another filename. Verify that the matching is reset.
* Browse to a directory containing no files. Hold an Apple key and start typing a filename. Verify nothing happens.
* Browse to a directory containing one or more files starting with lowercase letters (AppleWorks or GS/OS). Verify the files appear with correct names. Press Apple+letter. Verify that the first file starting with that letter is selected.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Press Apple+1 through Apple+5. Verify that the radio buttons on the right are selected.

* Browse to a directory containing one or more files with starting with mixed case (AppleWorks or GS/OS). Verify the filenames appear with correct case.
* Verify that the device order (via clicking Change Drive or pressing Tab) matches the order of volumes shown on the DeskTop (boot device first, etc). Hold either Apple key when clicking Change Drive or pressing Tab, and verify that the order is reversed.
  * On a IIgs: Hold the Shift key when clicking Change Drive, or press Shift+Tab, and verify that the order is reversed.
  * On a Platinum IIe: Hold the Shift key when clicking Change Drive, or press Shift+Tab, and verify that the order is reversed.
* Browse to a directory containing 8 files. Verify that the scrollbar is inactive.
* Browse to a directory containing 9 files. Verify that the scrollbar is active. Press Apple+Down. Verify that the scrollbar thumb moves to the bottom of the track.

* Launch DeskTop. File > Copy a File.... Enter text in the first field. Enter text in the second field. Click in the middle of the text in the first field. Verify that the IP is positioned near the click. Click in the middle of the text in the second field. Verify that the IP is positioned near the click.

* Ensure the default drive has 10 or more files. Verify that an active scrollbar appears in the file list. Click OK. Click Cancel. Verify that the scrollbar is scrolled to the top.

* Launch DeskTop. Special > Format a Disk.... Select a drive with no disk, let the format fail and cancel. File > Copy a File.... Verify that the file list is populated.

* Launch DeskTop. Shortcuts > Add a Shortcut.... Enter text in the first field. Move the IP into the middle of the text. Click in the second field. Verify that the first field is not truncated.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Enter a name in the first field. Move the IP into the middle of the text. Click OK. Verify that the first field is not truncated.
* Launch DeskTop. File > Copy a File.... Enter text in the first field. Move the IP into the middle of the text. Click in the second field. Verify that the first field is not truncated.
* Launch DeskTop. File > Copy a File.... Enter a name in the first field. Move the IP into the middle of the text. Click OK. Verify that the first field is not truncated.

* Launch DeskTop. Shortcuts > Add a Shortcut.... Enter text in the second field. Move the IP into the middle of the text. Click in the first field. Verify that the second field is not truncated.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Enter a name in the second field. Move the IP into the middle of the text. Click Cancel. Verify that the second field is not truncated.
* Launch DeskTop. File > Copy a File.... Enter text in the second field. Move the IP into the middle of the text. Click in the first field. Verify that the second field is not truncated.
* Launch DeskTop. File > Copy a File.... Enter a name in the second field. Move the IP into the middle of the text. Click Cancel. Verify that the second field is not truncated.

* Create a directory, and in the directory create a file named "A.B" then a file named "A". Browse to the directory. Verify "A" sorts before "A.B".

* Browse to a directory with more than 8 files, with at least 1 directory. Note the first directory name. Scroll down so that the first file in the list is not seen. Pick a file and click OK. Verify that the first directory is visible in the list.

* Browse to a directory with files. Select a file. Click in the middle of the pathname. Click Change Drive. Verify that the entire path is replaced with the new volume name. (This does not apply to the second field in DeskTop: File > Copy a File...)

Repeat for each file picker:
* In each pathname field, type in an invalid path name. Click OK (multiple times if needed to commit the dialog). Verify that an alert is shown.
* In each pathname field, type in a volume path (e.g. "/VOL"). Click OK (multiple times if needed to commit dialog).
  * Selector: File > Run a Program... - nothing should happen, and the dialog should remain open.
  * DeskTop: File > Copy a File... - an alert should show.
  * DeskTop: File > Delete a File... - an alert should show.
  * DeskTop: Shortcuts > Add a Shortcut... - the dialog should close.
  * DeskTop: Shortcuts > Edit a Shortcut... - the dialog should close.

Repeat for each file picker:
* In each field, type a control character that is not an alias for an arrow/Tab/Return/Escape, e.g. Control+D. Verify that it is ignored.
* In each pathname field, type a non-path character (i.e. anything other A-Za-z0-9/.). Verify that it is ignored.
* In the Shortcuts > Add/Edit a Shortcut... name field, type a non-path, non-control character. Verify that it is accepted.
* Click a file in the list. Move the IP into an earlier part of the filename (e.g. "/VO|L/FILE"). Click on another file. Verify that the path is updated correctly. Repeat with other mean of changing the selected file: Up, Down, Apple+Up, Apple+Down, and holding Apple while typing a filename.
* Click a folder in the list. Edit the path shown. Click Open. Verify that the selected folder opens and that the path is updated correctly.
* Click a folder in the list. Click Open. Verify that the selected folder opens and that the path is updated correctly.

* Launch DeskTop. File > Copy a File.... Select a file. Click OK. Verify that the name of the file appears in the second field, with the IP at the end. Click a folder. Verify that the path updates, with the file name appended, with the IP at the end. Click Change Drive. Verify that the new path still has the file name appended, with the IP at the end. Repeat the above, but move the insertion point before clicking.
* Launch DeskTop. File > Copy a File.... Select a file. Click OK. Verify that the name of the file appears in the second field, after the insertion point. Edit the file name. Click a folder. Verify that the path updates, with the edited file name appended, with the IP at the end. Click Change Drive. Verify that the new path still has the edited file name appended, with the IP at the end. Repeat the above, but move the insertion point before clicking.

Repeat for each file picker:
* Configure a system with only one drive. Verify that the file picker's Change Drive button is dimmed.
* While there is no selection in the list box, verify that the Open button is dimmed.
* Select a folder in the list box. Verify that the Open button is not dimmed.
* Select a non-folder in the list box. Verify that the Open button is dimmed.
* Navigate to the root directory of a disk. Verify that the Close button is dimmed.
* Open a folder. Verify that the Close button is dimmed, that there is no selection, and that Open is dimmed. Hit Close until at the root. Verify that Close is dimmed.
* Verify that dimmed buttons don't respond to clicks.
* Verify that dimmed buttons don't respond to keyboard shortcuts (Tab for Change Drive, Control+O for Open, Control+C for Close).

For DeskTop's Add/Edit a Shortcut file picker:
* Select a file and click OK. Verify that when focus is in the second input, that all of Change Drive, Open and Close are dimmed. Click Cancel. Verify that the buttons return to their previous state.
* Select a folder and click OK. Verify that when focus is in the second input, that all of Change Drive, Open and Close are dimmed. Click Cancel. Verify that the buttons return to their previous state.

For DeskTop's Copy a File file picker:
* Select a file and click OK. Verify that when focus is in the second input, that all of Change Drive, Open and Close remain active and initialize to the correct state based on the selection. Click Cancel. Verify that the buttons return to their previous state when selection is restored.

# Text Input Fields

This covers:
 * DeskTop's name prompt, used in:
   * File > Duplicate...
   * File > Rename...
   * Special > Format a Disk...
   * Special > Erase a Disk...
 * Find Files DA.
 * File picker - some have two fields.

"IP" = Insertion Point, also known as the caret or cursor.

Repeat for each field:
 * Type a printable character.
   * Should insert a character at IP, unless invalid in context or length limit reached. Length limits are:
     * File path: 64 characters
     * File name: 15 characters
     * Shortcut name: 14 characters
   * Mouse cursor should be hidden until moved.
   * Test with IP at start, in middle, and at end of the string.
 * Delete key
   * Should delete character to left of IP, unless at start of string.
   * Mouse cursor should be hidden until moved.
   * Test with IP at start, in middle, and at end of the string.
 * Control+F (Forward delete)
   * Should delete character to right of IP, unless at end of string.
   * Mouse cursor should be hidden until moved.
   * Test with IP at start, in middle, and at end of the string.
 * Control+X (or Clear key on IIgs)
   * Should clear all text.
   * Mouse cursor should be hidden until moved.
   * Test with IP at start, in middle, and at end of the string.
 * Left Arrow
   * Should move IP one character to the left, unless at start of string.
   * Mouse cursor should be hidden until moved.
   * Test with IP at start, in middle, and at end of the string.
 * Right Arrow
   * Should move IP one character to the right, unless at end of string.
   * Mouse cursor should be hidden until moved.
   * Test with IP at start, in middle, and at end of the string.
 * Apple+Left Arrow
   * Should move IP to start of string.
   * Mouse cursor should be hidden until moved.
   * Test with IP at start, in middle, and at end of the string.
 * Apple+Right Arrow
   * Should move IP to end of string.
   * Mouse cursor should be hidden until moved.
   * Test at start, in middle, and at end of the string.
 * Click to left of string. Verify the mouse cursor is not obscured.
 * Click to left of IP, within the string. Verify the mouse cursor is not obscured.
 * Click to right string. Verify the mouse cursor is not obscured.
 * Click to right of IP, within the string. Verify the mouse cursor is not obscured.
 * Place IP within string, click OK.
 * Place IP at start of string, click OK.
 * Place IP at end of string, click OK.

For file pickers with two fields:
 * Click in first field. Click in second field.
 * Click in second field. Click in first field.
 * Click in first field. Click OK.
 * Click in second field. Click Cancel.

Watch out for:
 * Parts of the IP not erased.
 * Text being truncated when OK clicked.
 * IP being placed in the wrong place by a click.

# List Boxes Controls

This covers:
* File Pickers (which support selection)
* Disk Copy (which supports selection)
* Sounds DA (which supports selection)
* Find Files DA (which does not support selection)

Repeat for each list box:
* Verify the following keyboard shortcuts:
  * If the scrollbar is not enabled, the view should not scroll.
  * Up Arrow
    * If the control does not support selection, scrolls the view up by one line.
    * Otherwise, if there is no selection, selects the last item and scrolls it into view.
    * Otherwise, selects the previous item and scrolls it into view.
  * Down Arrow
    * If the control does not support selection, scrolls the view down by one line.
    * Otherwise, if there is no selection, selects the first item and scrolls it into view.
    * Otherwise, selects the next item and scrolls it into view.
  * Apple+Up Arrow
    * Scrolls one page up.
    * If the control supports selection, selection is not changed.
  * Apple+Down Arrow
    * Scrolls one down up.
    * If the control supports selection, selection is not changed.
  * Open-Apple+Solid-Apple+Up Arrow
    * Scrolls the view so that the first item is visible.
    * If the control supports selection, selects the first item.
  * Open-Apple+Solid-Apple+Down Arrow
    * Scrolls the view so that the last item is visible.
    * If the control supports selection, selects the last item.
