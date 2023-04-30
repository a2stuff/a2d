# Release Qualification Test Cases

> Status: Work in Progress

# Launcher

* Without starting DeskTop, launch BASIC.SYSTEM. Set a prefix (e.g. "/RAM"). Invoke DESKTOP.SYSTEM with an absolute path (e.g. "-/A2.DESKTOP/DESKTOP.SYSTEM"). Verify that it starts correctly.
* Move DeskTop into a subdirectory of a volume (e.g. "/VOL/A2D"). Without starting DeskTop, launch BASIC.SYSTEM. Set a prefix to a parent directory of desktop (e.g. "/VOL"). Invoke DESKTOP.SYSTEM with a relative path (e.g. "-A2D/DESKTOP.SYSTEM"). Verify that it starts correctly.

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

* Copy a file by dragging - same volume - target is window, holding Solid-Apple.
* Copy a file by dragging - same volume - target is volume icon, holding Solid-Apple.
* Copy a file by dragging - same volume - target is folder icon, holding Solid-Apple.

* Copy a file by dragging - different volume - target is window.
* Copy a file by dragging - different volume - target is volume icon.

* Select multiple files, including a folder containing files. Drag the files to a folder on the same volume. Verify that the progress dialog shows "Moving" and that the number of files listed matches the number of selected files.
* Select multiple files, including a folder containing files. Hold Solid-Apple and drag the files to a folder on the same volume. Verify that the progress dialog shows "Copying" and that the number of files listed matches the number of selected files plus the number of files in the folder.
* Select multiple files, including a folder containing files. Hold Solid-Apple and drag the files to another volume. Verify that the progress dialog shows "Moving" and that the number of files listed matches the number of selected files plus the number of files in the folder.

* Open a volume, open a folder, close just the volume window; re-open the volume, re-open the folder, ensure the previous window is activated.

* Launch DeskTop. Select a file icon. File > Rename.... Enter a unique name, hit OK. Verify that the icon updates with the new name.
* Launch DeskTop. Select a file icon. File > Rename.... Press OK without changing the name. Verify that the dialog is dismissed and the icon doesn't change.
* Launch DeskTop. Select a volume icon. File > Rename.... Enter a unique name, hit OK. Verify that the icon updates with the new name.
* Launch DeskTop. Select a volume icon. File > Rename.... Press OK without changing the name. Verify that the dialog is dismissed and the icon doesn't change.

* Launch DeskTop. Select an AppleWorks file icon. File > Rename..., and specify a name using a mix of uppercase and lowercase. Click OK. Close the containing window and re-open it. Verify that the filename case is retained.
* Launch DeskTop. Select an AppleWorks file icon. File > Duplicate..., and specify a name using a mix of uppercase and lowercase. Click OK. Close the containing window and re-open it. Verify that the filename case is retained.

* File > Get Info a non-folder file. Verify that the size shows as "_size_K".
* File > Get Info a folder containing 0 files. Verify that the size shows as "_size_K for 0 items".
* File > Get Info a folder containing 1 files. Verify that the size shows as "_size_K for 1 item".
* File > Get Info a folder containing 2 or more files. Verify that the size shows as "_size_K for _count_ items".
* File > Get Info a volume containing 0 files. Verify that the size shows as "_size_K for 0 items / _total_K".
* File > Get Info a volume containing 1 files. Verify that the size shows as "_size_K for 1 item / _total_K".
* File > Get Info a volume containing 2 or more files. Verify that the size shows as "_size_K for _count_ items / _total_K".

* Open a window. Position two icons so one overlaps another. Select both. Drag both to a new location. Verify that the icons are repainted in the new location, and erased from the old location.
* Open a window. Position two icons so one overlaps another. Select only one icon. Drag it to a new location. Verify that the the both icons repaint correctly.

* Position a volume icon in the middle of the DeskTop. Incrementally move a window so that it obscures all 8 positions around it (top, top right, right, etc). Ensure the icon repaints fully, and no part of the window is over-drawn.

* Launch DeskTop, File > Quit, run BASIC.SYSTEM. Ensure /RAM exists.

* File > Quit - verify that there is no crash under ProDOS 8.

* Run on system with realtime clock; verify that time shows in top-right of menu.

* Open folder with new files. Use File > Get Info; verify dates after 1999 show correctly.
* Open folder with new files. Use View > by Date; verify dates after 1999 show correctly.

* Open folder with zero files. Use View > by Name. Verify that there is no crash.
* Open folder with one files. Use View > by Name. Verify that the entry paints correctly.

* Open a window for a volume; open a window for a folder; close volume window; close folder window. Repeat 10 times to verify that the volume table doesn't have leaks.

* Verify that GS/OS volume name cases show correctly (e.g. ProDOS 2.5 disk).
* Verify that GS/OS file name cases show correctly (e.g. ProDOS 2.5 disk).

* Open two windows. Click the close box on the active window. Verify that only the active window closes.
* Repeat the following case with these modifiers: Open-Apple, Solid-Apple:
  * Open two windows. Hold modifier and click the close box on the active window. Verify that all windows close.
* Open two windows. Press Open-Apple+Solid-Apple+W. Verify that all windows close. Repeat with Caps Lock off.


* Start DeskTop with a hard disk and a 5.25" floppy mounted. Remove the floppy, and double-click the floppy icon, and dismiss the "The volume cannot be found." dialog. Verify that the floppy icon disappears, and that no additional icons are added.

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
  * Launch DeskTop. Select one or more volume icons. Hold modifier and click a selected volume icon. Verify that it is deselected.
  * Launch DeskTop. Hold modifier and double-click on a non-selected volume icon. Verify that it highlights then unhighlights, and does not open.
  * Launch DeskTop. Select a volume icon. Hold modifier and double-click the selected volume icon. Verify that it unhighlights then highlights, and does not open.
  * Launch DeskTop. Select a volume icon. Hold modifier down and drag a selection rectangle around another volume icon. Verify that both are selected.
  * Launch DeskTop. Open a volume containing files. Click on a file icon. Hold modifier and click a different file icon. Verify that selection is extended.
  * Launch DeskTop. Open a volume containing files. Select two file icons. Hold modifier and click on the window, not on an icon. Verify that selection is not cleared.
  * Launch DeskTop. Open a window. Select an icon. Hold modifier and double-click an empty spot in the window (not on an icon). Verify that the selection is not cleared.
  * Launch DeskTop. Open a window. Select an icon. Hold modifier down and drag a selection rectangle around another icon. Verify that both are selected.
  * Launch DeskTop. Open a window. Select one or more file icons. Hold modifier and click a selected file icon. Verify that it is deselected.
  * Launch DeskTop. Open a window. Hold modifier and double-click on a non-selected file icon. Verify that it highlights then unhighlights, and does not open.
  * Launch DeskTop. Open a window. Select a file icon. Hold modifier and double-click the selected file icon. Verify that it unhighlights then highlights, and does not open.
  * Launch DeskTop. Open a volume window. Hold modifier, and drag-select icons in the window. Release the modifier. Verify that the volume icon is no longer selected. Click an empty area in the window to clear selection. Verify that the selection in the window clears, and that the volume icon becomes selected.
  * Launch DeskTop. Open a volume window with many icons. Click on a file icon to select it. Modifier-click the icon to deselect it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.
  * Launch DeskTop. Open a volume window with many icons. Modifier-click on a file icon to select it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.

* Launch DeskTop. Click on a volume icon. Hold Solid-Apple and click on a different volume icon. Verify that selection changes to the second icon.
* Launch DeskTop. Open a volume containing files. Click on a file icon. Hold Solid-Apple and click on a different file icon. Verify that selection changes to the second icon.

* Launch DeskTop. Select two volume icons. Double-click one of the volume icons. Verify that two windows open.
* Launch DeskTop. Open a window. Select two folder icons. Double-click one of the folder icons. Verify that two windows open.
* Launch DeskTop. Open a window. Hold Solid-Apple and double-click a folder icon. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Open a window. Select a folder icon. Hold Solid-Apple and select File > Open. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Open a window. Select a folder icon. Hold Open-Apple and select File > Open. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Open a window. Select a folder icon. Press Open-Apple+Solid-Apple+O. Verify that the folder opens, and that the original window closes. Repeat with Caps Lock off.
* Launch DeskTop. Open a window. Select a folder icon. Press Open-Apple+Solid-Apple+Down. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Ensure nothing is selected. Press Open-Apple+Solid-Apple+O. Verify that nothing happens. Repeat with Caps Lock off.
* Launch DeskTop. Ensure nothing is selected. Press Open-Apple+Solid-Apple+Down. Verify that nothing happens.

* Launch DeskTop. Try to move a file (drag on same volume) where there is not enough space to make a temporary copy, e.g. a 100K file on a 140K disk. Verify that the file is moved successfully and no error is shown.
* Launch DeskTop. Try to copy a file (drag to different volume) where there is not enough space to make the copy. Verify that the error message says that the file is too large to copy.
* Launch DeskTop. Drag multiple selected files to a different voluem, where one of the middle files will be too large to fit on the target volume but that subsequently selected files will fit. Verify that an error message says that the file is too large to copy, and that clicking OK continues to copy the remaining files.
* Launch DeskTop. Drag a single folder or volume containing multiple files to a different voluem, where one of the files will be too large to fit on the target volume but all other files will fit. Verify that an error message says that the file is too large to copy, and that clicking OK continues to copy the remaining files.

* Launch DeskTop. Open a volume window. Select volume icons on the desktop. Switch window's view to by Name. Verify that the volume icons are still selected, and that File > Get Info is still enabled (and shows the volume info). Switch window's view back to as Icons. Verify that the desktop volume icons are still selected.
* Launch DeskTop. Open a window containing file icons. Select one or more file icons in the window. Select a different View option. Verify that the icons in the window remain selected.
* Launch DeskTop. Open a window containing file icons. Hold Open-Apple and select multiple files in a specific order. Select a different View option. Apple > Sort Directory. View > as Icons. Verify that the icons appear in the selected order.
* Launch DeskTop. Open a window containing file icons. Select one or more volume icons on the desktop. Select a different View option. Verify that the volume icons on the desktop remain selected.

* Launch DeskTop. Open a volume window. Select an icon. Click in the header area (items/use/etc). Verify that selection is not cleared.

* Launch DeskTop. Open a volume window. Click in the header area (items/use/etc). On the desktop, drag a selection rectangle around the window. Verify that nothing is selected, and that file icons don't paint onto the desktop.
* Launch DeskTop. Open a volume window. Adjust the window so that the scrollbars are active. Scroll the window. On the desktop, drag a selection rectangle around the window. Verify that nothing is selected, and that file icons don't paint onto the desktop.
* Launch DeskTop. Open a volume window. Adjust the window so it is small and roughly centered on the screen. In the middle of the window, start a drag-selection. Move the mouse cursor in circles around the outside of the window and within the window. Verify that one corner of the selection rectangle remains fixed where the drag-selection was started.

* Launch DeskTop. Open a window with only one icon. Drag icon so name is to left of window bounds. Ensure icon name renders.

* Launch DeskTop. Open a volume window with icons. Drag leftmost icon to the left to make horizontal scrollbar activate. Click horizontal scrollbar so viewport shifts left. Verify dragged icon still renders.
* Launch DeskTop. Open a volume window with icons. Drag leftmost icon to the left to make horizontal scrollbar activate. Click horizontal scrollbar so viewport shifts left. Drag window to the right so it overlaps desktop icons. Verify DeskTop doesn't lock up.
* Launch DeskTop. Open a volume window with icons. Resize the window so that the horizontal scrollbar is active. Drag the window so the left edge of the scrollbar thumb is offscreen to the left. Click on the right arrow, and verify that the window scrolls correctly. Repeat for the page right region.

* Launch DeskTop. Open a volume window with icons. Drag window so only header is visible. Verify that DeskTop doesn't render garbage or lock up.

* Launch DeskTop. Open two volume windows with icons. Drag top window down so only header is visible. Click on other window to activate it. Verify that the window header does not disappear.

* Launch DeskTop. Open a window with a single icon. Move the icon so it overlaps the left edge of the window. Verify scrollbar appears. Hold scroll arrow. Verify icon scrolls into view, and eventually the scrollbar deactivates. Repeat with right edge.
* Launch DeskTop. Open a window with 11-15 icons. Verify scrollbars are not active.

* Launch DeskTop. Open a folder using Apple menu (e.g. Control Panels) or a shortcut. Verify that the used/free numbers are non-zero.
* Launch DeskTop. Open a subdirectory folder. Quit and relaunch DeskTop. Verify that the used/free numbers in the restored window are non-zero.

* Launch DeskTop. Open a folder containing subfolders. Select all the icons in the folder. Double-click one of the subfolders. Verify that the selection is not retained in the parent window. Position the child window over top of the parent so it overlaps some of the icons. Close the child window. Verify that the parent window correctly shows only the previously opened folder as highlighted.

* Launch DeskTop. Open a window containing folders and files. Scroll window so a folder is partially or fully outside the visual area (e.g. behind title bar, header, or scrollbars). Drag a file over the obscured part of the folder. Verify the folder doesn't highlight.
* Launch DeskTop. Open a window containing folders and files. Scroll window so a folder is partially or fully outside the visual area (e.g. behind title bar, header, or scrollbars). Drag a file over the visible part of the folder. Verify the folder highlights but doesn't render past window bounds. Continue dragging over the obscured part of the folder. Verify that the folder unhighlights.

* Launch DeskTop. Open two windows containing folders and files. Drag a file from one window over a folder in the other window. Verify that the folder highlights. Drop the file. Verify that the file is copied or moved to the correct target folder.
* Launch DeskTop. Open two windows containing folders and files. Scroll one window so a folder is partially or fully outside the visual area (e.g. behind title bar, header, or scrollbars). Drag a file from the other window over the obscured part of the folder. Verify the folder doesn't highlight.
* Launch DeskTop. Open two windows containing folders and files. Scroll one window so a folder is partially or fully outside the visual area (e.g. behind title bar, header, or scrollbars). Drag a file from the other window over the visible part of the folder. Verify the folder highlights but doesn't render past window bounds. Continue dragging over the obscured part of the folder. Verify that the folder unhighlights.

* Launch DeskTop. Select a 32MB volume. File > Get Info. Verify total size shows as 32,768K not 0K.

* Launch DeskTop. Open a window containing folders and files. Open another window, for an empty volume. Drag an icon from the first to the second. Ensure no scrollbars activate in the target window.
* Launch DeskTop. Open a window containing folders and files, with no scrollbars active. Open another window. Drag an icon from the first to the second. Ensure no scrollbars activate in the source window.

* Launch DeskTop. Open some windows. Special > Disk Copy. Quit back to DeskTop. Verify that the windows are restored.
* Launch DeskTop. Close all windows. Special > Disk Copy. Quit back to DeskTop. Verify that no windows are restored.

* Repeat the following cases for File > New Folder, File > Rename, and File > Duplicate:
  * Launch DeskTop. Open a window and (if needed) select a file. Run the command. Enter a name, but place the IP in the middle of the name (e.g. "exam|ple"). Click OK. Verify that the full name is used.

* Repeat the following cases for File > New Folder, File > Rename, and File > Duplicate:
  * Launch DeskTop. Run the command. Verify if the OK button correctly enabled if the text field is empty, disabled if not. Enter text. Verify that the OK button is enabled. Delete all of the text. Verify that the OK button becomes disabled. Enter text. Verify that the OK button becomes enabled.

* Configure a system with removable disks. (e.g. Virtual II OmniDisks) Launch DeskTop. Verify that volume icons are positioned without gaps (down from the top-right, then across the bottom right to left). Eject one of the middle volumes. Verify icon disappears. Insert a new volume. Verify icon takes up the vacated spot. Repeat test, ejecting multiple volumes verify that positions are filled in order (down from the top-right, etc).

* Launch DeskTop. Open a window. File > New Folder..., enter name, OK. Copy the file to another folder or volume. Verify that the "Files remaining" count bottoms out at 0.
* Launch DeskTop. Open a window. File > New Folder..., enter name, OK. Move the file to another folder or volume. Verify that the "Files remaining" count bottoms out at 0.
* Launch DeskTop. Create a shortcut for a non-executable file at the root of a volume. Run the shortcut. Verify that the "Files remaining" count bottoms out at 0. Close the alert. Drag a volume icon to another volume. Verify that the "Files remaining" count bottoms out at 0.

* Launch DeskTop. Open a volume. File > New Folder..., create A. File > New Folder..., create B. Drag B onto A. File > New folder.... Verify DeskTop doesn't hang.

* Launch DeskTop. Open a window with files with dates with long month names (e.g. "February 29, 2020"). View > by Name. Resize the window so the lines are cut off on the right. Move the horizontal scrollbar all the way to the right. Verify that the right edges of all lines are visible.

* Launch DeskTop. Double-click on a file that DeskTop can't open (and where no BASIS.SYSTEM is present). Click OK in the "This file cannot be opened." alert. Double-click on the file again. Verify that the alert renders with an opaque background.

* Launch DeskTop. Create a sequence of nested folders approaching maximum path length, e.g. /RAM/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789/ABCDEF12345. Try to copy a file into the folder. Verify that stray pixels do not appear in the top line of the screen.


* Load DeskTop. Create a folder e.g. /RAM/F. File > Copy a File. Verify that the destination path is empty.
* Load DeskTop. Create a folder e.g. /RAM/F. Try to copy the folder into itself using File > Copy a File. Verify that an error is shown.
* Load DeskTop. Create a folder e.g. /RAM/F. Open the containing window, and the folder itself. Try to move it into itself by dragging. Verify that an error is shown.
* Load DeskTop. Create a folder e.g. /RAM/F, and a sibling folder e.g. /RAM/B. Open the containing window, and the first folder itself. Select both folders, and try to move both into the first folder's window by dragging. Verify that an error is shown before any moves occur.
* Load DeskTop. Create a folder e.g. /RAM/F. Open the containing window, and the folder itself. Try to copy it into itself by dragging with an Apple key depressed. Verify that an error is shown.
* Load DeskTop. Open a volume window. Drag a file from the volume window to the volume icon. Verify that an error is shown.
* Load DeskTop. Create a folder, and a file within the folder with the same name as the folder (e.g. /RAM/F and /RAM/F/F). Try to copy the file over the folder using File > Copy To.... Verify that an error is shown.
* Load DeskTop. Create a folder, and a file within the folder with the same name as the folder (e.g. /RAM/F and /RAM/F/F). Try to move the file over the folder using drag and drop. Verify that an error is shown.
* Load DeskTop. Create a folder, and a file within the folder with the same name as the folder, and another file (e.g. /RAM/F and /RAM/F/F and /RAM/F/B). Select both files and try to move them into the parent folder using drag and drop. Verify that an error is shown before any files are moved.

* Load DeskTop. Open a volume. Adjust the window size so that horizontal and vertical scrolling is required. Scroll to the bottom-right. Quit DeskTop, reload. Verify that the window size and scroll position was restored correctly.
* Load DeskTop. Open a volume. Quit DeskTop, reload. Verify that the volume window was restored, and that the volume icon is dimmed. Close the volume window. Verify that the volume icon is no longer dimmed.
* Load DeskTop. Open a window containing icons. View > by Name. Quit DeskTop, reload. Verify that the window is restored, and that it shows the icons in a list sorted by name, and that View > by Name is checked. Repeat for other View menu options.
* Load DeskTop. Open a window for a volume in a Disk II drive. Quit DeskTop. Remove the disk from the Disk II drive. Load DeskTop. Verify that the Disk II drive is only polled once on startup, not twice.

* Ensure the startup volume has a name that would be case-adjusted by DeskTop, e.g. /HD. Launch DeskTop. Open the startup volume. Apple > Control Panels. Drag a DA file to the startup volume window. Verify that the file is moved, not copied.

* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Try opening volumes/folders until there are less than 8 windows but more than 127 icons. Verify that the "A window must be closed..." dialog has no Cancel button.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Verify that 127 icons can be shown.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. File > New Folder. Verify that a warning is shown and the window is closed. Repeat, with multiple windows open. Verify that everything repaints correctly, and that no volume or folder icon incorrectly displays as dimmed.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. Use File > Copy a File to copy a file into a directory represented by an open window. Verify that after the copy, a warning is shown, the window is closed, and that no volume or folder icon incorrectly displays as dimmed.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. Drag a file from another volume (to copy it) into an open window. Verify that after a copy, a warning is shown and the window is closed, and that no volume or folder icon incorrectly displays as dimmed.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. Drag a volume icon into an open window. Verify that after the copy, a warning is shown and the window is closed, and that no volume or folder icon incorrectly displays as dimmed.

* Launch DeskTop. Copy multiple selected files to another volume. Repeat the copy. When prompted to overwrite, alternate clicking Yes and No. Verify that the "Files remaining" count decreases to zero.
* Launch DeskTop. Copy a folder containing multiple files to another volume. Repeat the copy. When prompted to overwrite, alternate clicking Yes and No. Verify that the "Files remaining" count decreases to zero.

* Use an emulator that supports dynamically inserting SmartPort disks, e.g. Virtual ][. Insert disks A, B, C, D in drives starting at the highest slot first, e.g. S7D1, S7D2, S5D1, S5D2. Launch DeskTop. Verify that the disks appear in order A, B, C, D. Eject the disks, and wait for DeskTop to remove the icons. Pause the emulator, and reinsert the disks in the same drives. Un-pause the emulator. Verify that the disks appear on the DeskTop in the same order. Eject the disks again, pause, and insert the disks into the drives in reverse order (A in S5D2, etc). Un-pause the emulator. Verify that the disks appear in reverse order on the DeskTop.

* Configure a system with two volumes of the same name. Launch DeskTop. Verify that an error is shown, and only one volume appears.
* Launch DeskTop. Rename a volume to have the same name as another. Verify that an error is shown and the icon is removed.

* Launch DeskTop. Open a window. File > Quit. Launch DeskTop again. Ensure the window is restored. Try to drag-select volume icons. Verify that they are selected.

* Launch DeskTop. Select a volume icon, where the volume contains no files. File > Get Info. Verify that numbers are shown for number of files (0) and space used (a few K).
* Launch DeskTop. Select a file icon. File > Get Info. Verify that the size shown is correct. Select a directory. File > Get Info, and dismiss. Now select the original file icon again, and File > Get Info. Verify that the size shown is still correct.
* Use real hardware, not an emulator. Launch DeskTop. Select a volume icon. File > Get Info. Verify that a "The specified path name is invalid." alert is not shown.

* Launch DeskTop. Select a volume with more than 255 files in a folder (e.g. Total Replay). File > Get Info. Verify that the count finishes.
* Launch DeskTop. Create a folder. Place a file of known size (e.g. 17K) in the folder. Select the folder. File > Get Info. Verify that 2 files are counted, and that the size is the same as the file size or slightly larger (e.g. 17K or 18K) but not twice the size of the file (e.g. 33K).

* Launch DeskTop. Select a volume. File > Open. Verify that the volume icon is dimmed but still selected.
* Launch DeskTop. Double-click a volume. Verify that the volume icon is still selected.
* Launch DeskTop. Select a folder. File > Open. Verify that the folder icon is dimmed but no longer selected.
* Launch DeskTop. Double-click a folder. Verify that the folder icon is no longer selected.
* Launch DeskTop. Open a window containing a folder. Position the window so that the folder icon will not be obscured when opened. Select the folder. File > Open. Verify that the folder icon is no longer selected.
* Launch DeskTop. Open a window containing a folder. Position the window so that the folder icon will not be obscured when opened. Double-click the folder. Verify that the folder icon is no longer selected.

* Configure a system with 14 devices. Launch and then exit DeskTop. Load another ProDOS app that enumerates devices. Verify that all expected devices are present, and that there's no "Slot 0, Drive 1" entry.

* Launch DeskTop. Open a volume window. Open a folder. Close the volume window. Press Open-Apple+Up. Verify that the volume window re-opens, and the that the folder icon is selected. Press Open-Apple+Up again. Verify that the volume icon is selected.
* Launch DeskTop. Open a volume window. Open a folder. Press Open-Apple+Up. Verify that the volume window is activated, and the that the folder icon is selected. Press Open-Apple+Up again. Verify that the volume icon is selected.
* Launch DeskTop. Open a volume window. Open a folder. Activate the volume window. Switch the window's view to by Name. Activate the folder window. Press Open-Apple+Up. Verify that the volume window is activated. Press Open-Apple+Up again. Verify that the volume icon is selected.

* Launch DeskTop. Open a volume window with multiple files. Open a folder. Press Open-Apple+Up. Verify that the volume window is shown and the folder is selected. Press Right Arrow. Verify that only a single icon shows as selected.
* Launch DeskTop. Open a volume window with multiple files. Open a folder. Close the volume window. Press Open-Apple+Up. Verify that the volume window is shown and the folder is selected. Press Right Arrow. Verify that only a single icon shows as selected.
* Launch DeskTop. Open a volume window with multiple files. Open a folder. Press Open-Apple+Solid-Apple+Up. Verify that the folder window is closed, the volume window is shown, and the folder is selected. Press Right Arrow. Verify that only a single icon shows as selected.
* Launch DeskTop. Open a volume window with multiple files. Open a folder. Close the volume window. Press Open-Apple+Solid-Apple+Up. Verify that the folder window is closed, the volume window is shown, and the folder is selected. Press Right Arrow. Verify that only a single icon shows as selected.

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
  * File > Rename... is disabled.
  * File > Open, File > Get Info, Special > Lock, and Special > Unlock are disabled.
* Launch DeskTop. Select only the Trash icon. Verify that:
  * Special > Eject Disk is disabled.
  * Special > Check Drive is disabled.
  * File > Duplicate... is disabled.
  * File > Rename... is disabled.
  * File > Open, File > Get Info, Special > Lock, and Special > Unlock are disabled.
* Launch DeskTop. Select a volume. Verify that:
  * Special > Eject Disk is enabled.
  * Special > Check Drive is enabled.
  * File > Duplicate... is disabled.
  * File > Rename... is enabled.
  * File > Open, File > Get Info, Special > Lock, and Special > Unlock are enabled.
* Launch DeskTop. Select two volume icons. Verify that:
  * Special > Eject Disk is enabled.
  * Special > Check Drive is enabled.
  * File > Duplicate... is disabled.
  * File > Rename... is disabled.
  * File > Open, File > Get Info, Special > Lock, and Special > Unlock are enabled.
* Launch DeskTop. Select a volume icon and the Trash icon. Verify that:
  * Special > Eject Disk is enabled.
  * Special > Check Drive is enabled.
  * File > Duplicate... is disabled.
  * File > Rename... is disabled.
  * File > Open, File > Get Info, Special > Lock, and Special > Unlock are enabled.
* Launch DeskTop. Open a volume window, and select a file. Verify that:
  * Special > Eject Disk is disabled.
  * Special > Check Drive is disabled.
  * File > Rename... is enabled.
  * File > Duplicate... is enabled.
  * File > Open, File > Get Info, Special > Lock, and Special > Unlock are enabled.
* Launch DeskTop. Open a volume window, and select two files. Verify that:
  * Special > Eject Disk is disabled.
  * Special > Check Drive is disabled.
  * File > Rename... is disabled.
  * File > Duplicate... is enabled.
  * File > Open, File > Get Info, Special > Lock, and Special > Unlock are enabled.
* Launch DeskTop. Close all windows. Verify that File > New Folder..., File > Close Window, File > Close All, and everything in the View menu are disabled.
* Launch DeskTop. Open a window. Verify that File > New Folder..., File > Close Window, File > Close All, and everything in the View menu are enabled.


* Launch DeskTop. Open 3 windows. Close the top one. Verify that the repaint is correct.
* Launch DeskTop. Close all windows. Press an arrow key multiple times. Verify that only one volume icon is highlighted at a time.

* For the following cases, "obscure a window" means to move a window to the bottom of the screen so that only the title bar is visible:
  * Launch DeskTop. Open a window with icons. View > by Name. Obscure the window. View > as Icons. Verify that the window contents don't appear on the desktop. Move the window so the contents are visible. Verify that it contains icons.
  * Launch DeskTop. Open a window with icons. Obscure the window. View > by Name. Verify that the window contents don't appear on the desktop. Move the window so the contents are visible. Verify that the contents display as a list.
  * Launch DeskTop. Open a window with at least two icons. Select the first icon. Obscure the window. Press the right arrow key. Verify that the icons don't appear on the desktop.
  * Launch DeskTop. Open a window with icons. Obscure the window. File > Select All icon. Verify that the icons don't appear on the desktop.
  * Launch DeskTop. Open a window with icons. File > Select All icon. Obscure the window. Click on the desktop to clear selection. Verify that the icons don't appear on the desktop.
  * Launch DeskTop. Open a window with folder icons. Open a second window from one of the folders. Verify that the folder icon in the first window is dimmed. Obscure the first window. Close the second window. Verify that the folder icon doesn't appear on the desktop.
  * Launch DeskTop. Open a window with icons. Select (but don't open) a folder. Obscure the window. File > Open. Verify that the folder icon does not appear on the desktop.
  * Launch DeskTop. Open a window with icons. Select (but don't open) a folder containing 127 icons. Obscure the window. File > Open. Verify that the folder icon does not appear on the desktop.
  * Launch DeskTop. Open a window. Obscure the window. File > New Folder, enter a name, OK. Verify that the folder icon doesn't appear on the desktop.
  * Launch DeskTop. Open a window with icons. Obscure the window. File > Quit. Relaunch DeskTop. Verify that the restored window's icons don't appear on the desktop, and that the menu bar is not glitched.
  * Launch DeskTop. Open two windows with icons. Obscure one window. Click on the other window's title bar. Click on the obscured window's title bar. Verify that the window contents don't repaint on the desktop.
  * Launch DeskTop. Open two windows with icons. Activate a window, View > by Name, and then obscure the window. Click on the other window's title bar. Click on the obscured window's title bar. Verify that the window contents don't repaint on the desktop.
  * Launch DeskTop. Open a window with icons. Select an icon. Obscure the window. File > Rename..., enter a new name, OK. Verify that the icon does not paint on the desktop.

* Launch DeskTop. Open a window. Try to drag the window so that the title bar is behind the menu bar. Verify that the window ends up positioned partially behind the menu bar.
* Launch DeskTop. Open two windows. Drag them both so their title bars are partially behind the menu bar. Apple+Tab between the windows. Verify that the title bars do not mispaint on top of the menu bar.

* Launch DeskTop. Open a window containing a folder. Open the folder's window. Activate the first window by clicking on it. Activate the second window by clicking on it. Verify that the folder icon is not selected by moving the second window around to force repaints.

* Launch DeskTop. Open a window for a volume icon. Open a folder within the window. Select the volume icon. Special > Check Drive. Verify that both windows are closed.
* Launch DeskTop. Open a window for a volume icon. Special > Check All Drives. Verify that all windows close, and that volume icons are correctly updated.

* Launch DeskTop. Drag a file to a same-volume window so it is moved, not copied. Use File > Copy To... to copy a file. Verify that the file is indeed copied, not moved.

* Launch DeskTop. Open a window. Select a file icon. Apple > Control Panels. Verify that the previously selected file is no longer selected.

* Launch DeskTop. Open a window containing many folders. Select up to 7 folders. File > Open. Verify that as windows continue to open, the originally selected folders don't mispaint on top of them. (This will be easier to observe in emulators with acceleration disabled.)

* Launch DeskTop. Open a window containing multiple icons. Drag-select several icons. Click in the window to clear selection. Click on a volume icon. Click elsewhere on the desktop. Verify the icon isn't mispainted.
* Launch DeskTop. Open a window containing multiple icons. Drag-select several icons. Click in the window to clear selection. Click on a volume icon. File > Rename.... Enter a new valid name, and click OK. Verify that no alert is shown.

* Launch DeskTop. Select a volume icon. File > Rename.... Enter the name of another volume. Verify that a "That name already exists." alert is shown. Click OK. Verify that the Rename dialog is still showing.
* Launch DeskTop. Open a window. Select a file icon. File > Rename.... Enter the name of file in the same window. Verify that a "That name already exists." alert is shown. Click OK. Verify that the Rename dialog is still showing.
* Launch DeskTop. Open a volume window. Open a folder window. Select the volume icon and rename it. Verify that neither window is closed, and volume window is renamed.
* Launch DeskTop. Open a volume window. Open a folder window. Activate the volume window. View > By Name. Select the folder icon. Rename it. Verify that the folder window is renamed.
* Launch DeskTop. Open a volume window. Position an file icon with a short name near the left edge of the window, but far enough away that the scrollbars are not active. Rename the file icon with a long name. Verify that the window's scrollbars activate.
* Launch DeskTop. Open a volume window. Position an file icon with a long name near the left edge of the window, so that the name is partially cut off and the scrollbars activate. Rename the file icon with a short name. Verify that the window's scrollbars deactivate.
* Launch DeskTop. Close all windows. Select a volume icon. File > Rename..., enter a new name, and click OK. Verify that after the dialog closes there is no mis-painting of a scrollbar on the desktop.

* Launch DeskTop. Open a window. Create folders A, B and C. Open A, and create a folder X. Open B, and create a folder Y. Drag A and B into C. Double-click on X. Verify it opens. Double-click on Y. Verify it opens. Open C. Double-click on A. Verify that the existing A window activates. Double click on B. Verify that the existing B window activates.

* Launch DeskTop. Open a window. Create a folder with a short name (e.g. "A"). Open the folder. Drag the folder's window so it covers just the left edge of the icon. Drag it away. Verify that the folder repaints. Repeat for the right edge.

* Repeat the following cases for Special > Format a Disk and Special > Erase a Disk:
  * Launch DeskTop. Run the command. Ensure left/right arrows move selection correctly.
  * Launch DeskTop. Run the command. Verify that the device order shown matches the order of volumes shown on the DeskTop (boot device first, etc). Select a device and proceed with the operation. Verify the correct device was formatted or erased.
  * Launch DeskTop. Run the command. For the new name, enter a volume name not currently in use. Verify that you are not prompted for a new name.
  * Launch DeskTop. Run the command. For the new name, enter the name of a volume in a different slot/drive. Verify that an alert shows, indicating that the name is in use.
  * Launch DeskTop. Run the command. For the new name, enter the name of the current disk in that slot/drive. Verify that you are not prompted for a new name.
  * Launch DeskTop. Run the command. Select a disk (other than the startup disk) and click OK. Enter a name, but place the IP in the middle of the name (e.g. "exam|ple"). Click OK. Verify that the full name is used.
  * Launch DeskTop. Run the command. Select an empty drive. Let the operation continue until it fails. Verify that an error message is shown.
  * Configure a system with at least 9 volumes. Launch DeskTop. Run the command. Select a volume in the third column. Click OK. Verify that the selection rect is fully erased.
  * Configure a system with 13 volumes, not counting /RAM. Launch DeskTop. Run the command. Verify that the boot device is excluded from the list so that only 12 devices are shown. Verify using the arrow keys that there aren't any overlapping volume entries.
  * Launch DeskTop. Run the command. Select a slot/drive containing an existing volume. Enter a new name and click OK. Verify that the confirmation prompt shows the volume with adjusted case matching the volume's icon, with quotes around the name.
  * Launch DeskTop. Run the command. Select a slot/drive containing an existing volume with a GS/OS-cased name and click OK. Enter a new name and click OK. Verify that the confirmation prompt shows the volume with the correct case matching the volume's icon, with quotes around the name.
  * Launch DeskTop. Run the command. Select a slot/drive containing a Pascal disk. Enter a new name and click OK. Verify that the confirmation prompt shows the Pascal volume name (e.g. "TGP:"), with quotes around the name.
  * Launch DeskTop. Run the command. Select a slot/drive containing a DOS 3.3 disk. Enter a new name and click OK. Verify that the confirmation prompt shows "the DOS 3.3 disk in slot # drive #", without quotes.
  * Launch DeskTop. Run the command. Select a slot/drive containing an unformatted disk. Enter a new name and click OK. Verify that the confirmation prompt shows "the disk in slot # drive #", without quotes.
  * Launch DeskTop. Select a volume icon. Run the command. Verify that the device selector is skipped. Enter a new volume name. Verify that the confirmation prompt refers to the selected volume.
  * Repeat the following case with: no selection, multiple volume icons selected, a single file selected, and multiple files selected:
    * Launch DeskTop. Set selection as specified. Run the command. Verify that the device selector is not skipped.
  * Launch DeskTop. Make sure no volume icon is selected. Run the command. Verify the OK button is disabled. Click on an item. Verify the OK button becomes enabled. Click on a blank option. Verify the OK button becomes disabled. Use the arrow keys to move selection. Verify that the OK button becomes enabled.
  * Launch DeskTop. Make sure no volume icon is selected. Run the command. Click an item, then click OK. Verify that the device location is shown, and that the OK button becomes disabled. Enter text. Verify that the OK button is enabled. Delete all of the text. Verify that the OK button becomes disabled. Enter text. Verify that the OK button becomes enabled.
  * Launch DeskTop. Select a volume icon. Run the command. Verify that the OK button is disabled. Enter text. Verify that the device location is shown, and that the OK button is enabled. Delete all of the text. Verify that the OK button becomes disabled. Enter text. Verify that the OK button becomes enabled.

* Launch DeskTop. Open a window. File > New Folder..., enter a unique name, OK. File > New Folder..., enter the same name, OK. Verify that an alert is shown. Dismiss the alert. Verify that the input field still has the previously typed name.

* Launch DeskTop. Clear selection by closing all windows and clicking on the desktop. Press Apple+Down. Verify that nothing happens.

* Launch DeskTop. Open a volume window. View > by Name. Open a separate volume window. Open a folder window. Open a sub-folder window. View > by Name. Close the window. Verify DeskTop doesn't crash.

* Repeat the following cases with these modifiers: Open-Apple, Solid-Apple:
  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Tab repeatedly. Verify that windows are activated and cycle in forward order (A, B, C, A, B, C, ...).
  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press \` repeatedly. Verify that windows are activated cycle in forward order (A, B, C, A, B, C, ...).
  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Shift+\` repeatedly. Verify that windows are activated cycle in reverse order (B, A, C, B, A, C, ...).
  * On a IIgs: Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Shift+Tab repeatedly. Verify that windows are activated cycle in reverse order (B, A, C, B, A, C, ...).
  * On a Platinum IIe: Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Shift+Tab repeatedly. Verify that windows are activated cycle in reverse order (B, A, C, B, A, C, ...).

* Launch DeskTop. Open a volume window containing a folder. Open the folder window. Note that the folder icon is dimmed. Close the volume window. Open the volume window again. Verify that the folder icon is dimmed.
* Launch DeskTop. Open a volume window. In the volume window, create a new folder F1 and open it. Note that the F1 icon is dimmed. In the volume window, create a new folder F2. Verify that the F1 icon is still dimmed.
* Launch DeskTop. Open a volume window containing a file and a folder. Open the folder window. Drag the file to the folder icon (not the window). Verify that the folder window activates and updates to show the file.

* Launch DeskTop. Open a volume window containing a folder. Open the folder. Verify that the folder appears as dimmed. Position the window partially over the dimmed folder. Move the window to reveal the whole folder. Verify that the folder is repainted cleanly (no visual glitches).
* Launch DeskTop. Open a volume window containing two folders (1 and 2). Open both folder windows, and verify that both folder icons are dimmed. Position folder 1's window partially covering folder 2's icon. Activate folder 1's window, and close it. Verify that the visible portions of folder 2 repaint, not dimmed.

* Launch DeskTop. Open a volume window. Select two files. File > Duplicate.... Leave the filename unchanged and click OK. Verify that an alert is shown, but the dialog is not dismissed. Change the name and click OK. Verify that a prompt is shown for the second file.
* Launch DeskTop. Open a volume window. Select two files. File > Duplicate.... Change the filename to the name of another file in the directory and click OK. Verify that an alert is shown, but the dialog is not dismissed. Change the name and click OK. Verify that a prompt is shown for the second file.

* Perform the following tests in DeskTop using Mouse Keys mode:
  * Use the arrow keys to move the mouse to the top, bottom, left, and right edges of the screen. Verify that the mouse is clamped to the edges and does not wrap.
  * Select an icon. Press the Return key. Verify that Mouse Keys mode is not silently exited, and the cursor is not distorted.
  * Use keys to click on a menu. Without holding the button down, move over the menu items. Verify that the menu does not spontaneously close.
  * Use keys to double-click on an icon. Verify it opens.


* Repeat the following:
  * For these permutations:
    * DeskTop (1) copied to RAMCard and (2) not copied to RAMCard.
    * Renaming (1) the volume that DeskTop loaded from, and renaming (2) the DeskTop folder itself.
  * Verify that the following still function:
    * File > Copy To... (overlays)
    * Special > Disk Copy (and that File > Quit returns to DeskTop) (overlay + quit handler)
    * Apple > Calculator (desk accessories)
    * Apple > Control Panels (relative folders)
    * Control Panel, change desktop pattern, close, quit, restart (settings)
    * Windows are saved on exit/restored on restart (configuration)
    * Invoking another application (e.g. BASIC.SYSTEM), then quitting back to DeskTop (quit handler)
    * Modifying shortcuts (selector)

* Launch DeskTop. Open a volume window. Create a folder. Open the folder's window. Go back to the volume window, and drag the folder icon to the trash. Click OK in the delete confirmation dialog. Verify that the folder's window closes.
* Launch DeskTop. Open a volume window. Create a folder. Open the folder's window. Activate the folder's parent window and select the folder icon. File > Delete. Click OK in the delete confirmation dialog. Verify that the folder's window closes.

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
  * Copy a file from another volume onto B using File > Copy To.... Verify that B activates and refreshes, and that B's item count/used/free numbers update. Click on D. Verify that D's used/free numbers update.
  * Drag a file from another volume onto D. Verify that D activates and refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Copy file from another volume onto D using File > Copy File.... Verify that D activates and refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Drag a file from B to the trash. Verify that B refreshes, and that B's item count/used/free numbers update. Click on D. Verify that D's used/free numbers update.
  * Delete a file from B using File > Delete. Verify that B refreshes, and that B's item count/used/free numbers update. Click on D. Verify that D's used/free numbers update.
  * Drag a file from D to the trash. Verify that D refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Delete a file from D using File > Delete. Verify that D refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Duplicate a file in D using File > Duplicate.... Verify that D refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Drag a file in B onto C while holding Apple to copy it. Verify that D activates and refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.
  * Drag a file in B onto D while holding Apple to copy it. Verify that D activates and refreshes, and that D's item count/used/free numbers update. Click on B. Verify that B's used/free numbers update.

* Launch DeskTop. Open a volume containing no files. Verify that the default minimum window size is used - about 170px by 50px not counting title/scrollbars.

* Launch DeskTop. Open two windows. Attempt to drag the inactive window by dragging its title bar. Verify that the window activates and the drag works.
* Launch DeskTop. Open two windows. Click on an icon in the inactive window. Verify that the window activates and that the icon is selected.
* Launch DeskTop. Open two volume windows. Click and drag in the inactive window without selecting any icons. Verify that the window activates and that the drag rectangle appears, and that when the button is released the volume icon is selected.
* Launch DeskTop. Open two volume windows. Click in the inactive window without selecting any icons. Verify that the window activates and the volume icon is selected.
* Launch DeskTop. Open a volume window. Click on the desktop to clear selection. Click in an empty area within the window. Verify that the volume icon is selected.
* Launch DeskTop. Open a volume window. Select a file icon. Click in an empty area within the window. Verify that the volume icon is selected.
* Launch DeskTop. Apple > Control Panels. Close the window by clicking on the close box. Verify nothing mis-paints.

* Launch DeskTop. On a volume, create folders named "A1", "B1", "A", and "B". View > by Name. Verify that the order is: "A", "A1", "B", "B1".

* Launch DeskTop. Open a window containing multiple file types. View > by Type. Verify that the files are sorted by type name, first alphabetically followed by $XX types in numeric order.
* Launch DeskTop. Open a window containing multiple files. View > by Size. Verify that the files are sorted by size in descending order, with directories at the end.

* Launch DeskTop. Open window containing icons. View > by Name. Verify that selection is supported:
  * The icon bitmap and name can be clicked on.
  * Drag-selecting the icon bitmap and/or name selects.
  * Selected icons can be dragged to other windows or volume icons to initiate a move or copy.
  * Dragging a selected icon over a non-selected folder icon in the same window causes it to highlight, and initiates a move or copy (depending on modifier keys).
* Launch DeskTop. Open window containing icons. View > by Name. Select one or more icons. Drag them within the window but not over any other icons. Release the mouse button. Verify that the icons do not move.
* Launch DeskTop. Open window containing icons. View > by Name. Select an icon. File > Rename. Enter a new name that would change the ordering. Verify that the window is refreshed and the icons are correctly sorted by name, and that the icon is still selected.
* Launch DeskTop. Open a window containing a folder. Open a folder. Activate the parent window and verify that the folder's icon is dimmed. View > by Name. Verify that the folder's icon is still dimmed. View > as Icons. Verify that the folder's icon is still dimmed.
* Launch DeskTop. Open a window containing a folder. View > by Name. Verify that the folder's icon is dimmed. View > as Icon. Verify that the folder's icon is still dimmed.

* Launch DeskTop. Open a volume window. Verify that the default view is "as Icons". View > by Name. Open a folder. Verify that the new folder's view is "by Name". Open a different volume window. Verify that it is "as Icons".
* Launch DeskTop. Open the A2.Desktop folder. View > by Small Icons. Open the Apple.Menu folder. Open the Control.Panels folder. Verify that the view is still "by Small Icons". Activate a different window. Apple Menu > Control Panels. Verify that the Control.Panels window is activated, and the view is still "by Small Icons".

* Launch DeskTop. Select a volume icon. Open it. Verify that the open animation starts at the icon location. (This will be easier to observe in emulators with acceleration disabled.)
* Launch DeskTop, ensuring no windows are open. File > Select All. Verify that the volume icons are selected.

* Launch DeskTop. Select a volume icon. Drag it over an empty space on the desktop. Release the mouse button. Verify that the icon is moved.
* Launch DeskTop. Select a volume icon. Drag it over an empty space on the desktop. Without releasing the mouse button, press the Escape key. Verify that the drag is cancelled and the icon does not move.
* Launch DeskTop. Select a volume icon. Drag it over another icon on the desktop, which should highlight. Without releasing the mouse button, press the Escape key. Verify that the drag is cancelled, the target icon is unhiglighted, and the dragged icon does not move.
* Launch DeskTop. Select a file icon. Drag it over an empty space in the window. Without releasing the mouse button, press the Escape key. Verify that the drag is cancelled and the icon does not move.
* Launch DeskTop. Select a file icon. Drag it over a folder icon, which should highlight. Without releasing the mouse button, press the Escape key. Verify that the drag is cancelled, the target icon is unhiglighted, and the dragged icon does not move.

* Repeat the following:
  * For these permutations, as the specified window area:
    * Title bar
    * Scroll bars
    * Resize box
    * Header (items/in disk/available)
  * Verify:
    * Launch DeskTop. Open a window with a file icon. Drag the icon so that the mouse pointer is over the same window's specified area. Release the mouse button. Verify that the icon does not move.
    * Launch DeskTop. Open two windows for different volumes. Drag an icon from one window over the specified area of the other window. Release the mouse button. Verify that the file is copied to the target volume.

* Repeat the following cases for File > New Folder, File > Duplicate, and File > Delete:
  * Launch DeskTop. Open a window and (if needed) select a file. Run the command. Verify that when the window is refreshed, the scrollbars are inactive or at the top/left positions.

* Launch DeskTop. Navigate to a folder with an image file with ".A2FC" suffix. Preview the image, then exit the preview. Apple Menu > Eyes (or any other DA). Verify that the DA launches correctly.

* Configure a system without a RAMCard. Launch DeskTop. Verify that the volume containing DeskTop appears in the top right corner of the desktop. File > Copy To.... Verify that the volume containing DeskTop is the first disk shown.
* Configure a system with a RAMCard, and set DeskTop to copy itself to the RAMCard on startup. Launch DeskTop. Verify that the non-RAMCard volume containing DeskTop appears in the top right corner of the desktop. File > Copy To.... Verify that the non-RAMCard volume containing DeskTop is the first disk shown. From within DeskTop, launch another app e.g. Basic.system. Eject the DeskTop volume. Exit the app back to DeskTop. Verify that the remaining volumes appear in default order.
* Configure a system with a RAMCard, and set DeskTop to not copy itself to the RAMCard on startup. Launch DeskTop. Verify that the non-RAMCard volume containing DeskTop appears in the top right corner of the desktop. File > Copy To.... Verify that the non-RAMCard volume containing DeskTop is the first disk shown.

* Launch DeskTop. Apple > About Apple II DeskTop. Click anywhere on the screen. Verify that the dialog closes.
* Launch DeskTop. Apple > About Apple II DeskTop. Press any non-modifier key screen. Verify that the dialog closes.

* Launch DeskTop. Open a window containing a folder. Open the folder window. Position the folder window so that it partially covers the "in disk" and "available" entries in the lower window. Drag a large file into the folder window. Verify that the "in disk" and "available" values update in the folder window. Drag the folder window away. Verify that the parent window "in disk" and "available" values repaint with the old values, and without visual artifacts. Activate the parent window. Verify that the "in disk" and "available" values now update.

* Launch DeskTop. Create a set of nested folders with a total path length just under the 64-character limit (e.g. "/RAMA/AAAAAAAAAAAAAAA/BBBBBBBBBBBBBBB/CCCCCCCCCCCCCCC/DDDDDDDDDD"). Rename the volume so that the total path length of the innermost folder would be longer than 64 characters (e.g. "RAMAXXXXXXXXXXX"). Repeat the following operations, and verify that an error is shown and DeskTop doesn't crash or hang:
  * Select the innermost folder. File > Get Info.
  * Select the innermost folder. File > Rename...
  * Select the innermost folder. File > Duplicate...
  * Select the innermost folder. File > Copy To... (and pick a target)
  * Select the innermost folder. Special > Lock
  * Select the innermost folder. Special > Unlock
  * Select the innermost folder. Shortcuts > Add a Shortcut...
  * Drag a file onto the innermost folder.
  * Drag the innermost folder to another volume.
  * Drag the innermost folder to the Trash.
* Repeat the previous case, but with an image file as the innermost file instead of a folder. Select the file. File > Open. Verify that an alert is shown.
* Copy PREVIEW/SHOW.IMAGE.FILE to the APPLE.MENU folder. Restart. Repeat the previous case, but with an image file as the innermost file instead of a folder. Select the file. Apple > Show Image File. Verify that an alert is shown.
* Repeat the previous case, but with a Desk Accessory file as the innermost file instead of a folder. File > Open. Verify that an alert is shown.

* Launch DeskTop. Select a 5.25 disk volume. Remove the disk. File > Get Info. Verify that an alert is shown. Click OK. Verify that DeskTop doesn't hang or crash.
* Launch DeskTop. Select a file on a 5.25 disk. Remove the disk. File > Get Info. Verify that an alert is shown. Click OK. Verify that DeskTop doesn't hang or crash.
* Launch DeskTop. Select two files on a 5.25 disk. Remove the disk. File > Get Info. Verify that an alert is shown. Insert the disk again. Click OK. Verify that details are shown for the second file.

* Mount a disk with the BINSCII system utility. Launch DeskTop. Invoke the BINSCII system file. Verify that the display is not truncated.

* Repeat the following test cases for these operations: Copy, Move, Delete, Lock, Unlock:
  * Select multiple files. Start the operation. During the initial count of the files, press Escape. Verify that the count is cancelled and the progress dialog is closed.
  * Select multiple files. Start the operation. After the initial count of the files is complete and the actual operation has started, press Escape. Verify that the operation is cancelled and the progress dialog is closed.
* Select a volume or folder containing multiple files. File > Get Info. During the count of the files, press Escape. Verify that the count is cancelled.

* Using BASIC, create a directory structure: X/Y/Z and save a BASIC file B as X/Y/Z/B. Lock all three directories and the file from BASIC (not DeskTop). Launch DeskTop. Select X. File > Delete. Verify that a prompt is shown for deleting each file in deepest-first order (B, Z, Y, X). Click Yes at each prompt. Verify that all files are deleted.

* Create a folder, and a subfolder within it. Select the top-most folder. Special > Lock. Using Apple > Run Basic Here, verify that the folder and subfolder are locked. BYE to return to DeskTop. Select the containing volume. Special > Unlock. Using Apple > Run Basic Here, verify that the folder and subfolder are unlocked.
* Using BASIC, create a directory X and save a BASIC file X/B. Launch DeskTop. Select X. File > Lock. Close the window containing X. Open the window containing X. Verify that X is still a folder.

* Launch DeskTop. Find a folder containing a file where the folder and file's creation dates (File > Get Info) differ. Copy the folder. Select the file in the copied folder. File > Get Info. Verify that the file creation and modification dates match the original.

* Launch DeskTop. Create a new folder. Select the folder, and use Special > Lock. Add a file to the folder. Ensure that the file is not locked. Select the folder, and use File > Delete. Click OK to confirm the deletion. When a prompt is shown to confirm deleting a locked file, verify that the folder's path is visible in the progress dialog.
* Launch DeskTop. Create a new folder. Create a second folder inside it. Select the second folder, and use Special > Lock. Add a file to the second folder. Ensure that the file is not locked. Select the first folder, and use File > Delete. Click OK to confirm the deletion. When a prompt is shown to confirm deleting a locked file, verify that the second folder's path is visible in the progress dialog.

## Shortcuts

* Delete the LOCAL/SELECTOR.LIST file from the startup disk, if it was present. Launch DeskTop. Verify that Shortcuts > Edit a Shortcut..., Shortcuts > Delete a Shortcut..., and Shortcuts > Run a Shortcut... are disabled. Add a shortcut. Verify that Shortcuts > Edit a Shortcut..., Shortcuts > Delete a Shortcut..., and Shortcuts > Run a Shortcut... are now enabled.

* Launch DeskTop. Create a shortcut, "menu and list" / "at boot". Create a second shortcut, "menu and list", "at first use". Create a third shortcut, "menu and list", "never". Delete the first shortcut. Verify that the remaining shortcuts are "at first use" and "never".
* Launch DeskTop. Create a shortcut, "list only" / "at boot". Create a second shortcut, "list only", "at first use". Create a third shortcut, "list only", "never". Delete the first shortcut. Verify that the remaining shortcuts are "at first use" and "never".
* Launch DeskTop. Delete all shortcuts. Create a shortcut, "list only" / "never". Edit the shortcut. Verify that it is still "list only" / "never". Change it to "menu and list", and click OK. Verify that it appears in the Shortcuts menu.

* Launch DeskTop. Configure a shortcut with the target being a directory. Open a window. Select a file icon. Invoke the shortcut. Verify that the previously selected file is no longer selected.

* Launch DeskTop. Create 8 shortcuts. Shortcuts > Add a Shortcut.... Check the first radio button. Pick a file, OK. Enter a name, OK. Verify that a relevant alert is shown.

* Launch DeskTop. Shortcuts > Add a Shortcut... and create a shortcut for a volume directory that is not the first volume on the DeskTop. Shortcuts > Edit a Shortcut... and select the new shortcut. Verify that file picker shows both the correct disk name and the correct full path.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Verify that if the pathname is a volume directory (e.g. "/VOL") and either "at boot" or "at first use" is selected, then an alert is shown when trying to commit the dialog.

* Launch DeskTop. Select a file icon. Shortcuts > Add a Shortcut... Verify that the file dialog is navigated to the selected file's folder and the file is selected.
* Launch DeskTop. Select a volume icon. Shortcuts > Add a Shortcut... Verify that the file dialog is initialized to the boot volume and no file is selected.
* Launch DeskTop. Clear selection. Shortcuts > Add a Shortcut... Verify that the file dialog is initialized to the boot volume and no file is selected.

* Configure a shortcut for a program with many associated files to copy to RAMCard "at boot". Reboot, and launch DESKTOP.SYSTEM. While DeskTop is being copied to RAMCard, press Escape to cancel. Verify that none of the program's files were copied to the RAMCard. Once DeskTop starts, invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at boot". Reboot, and launch DESKTOP.SYSTEM. While the program's files are being copied to RAMCard, press Escape to cancel. Verify that not all of the files were copied to the RAMCard. Once DeskTop starts, invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at boot". Reboot, and launch DESKTOP.SYSTEM. Verify that all of the files were copied to the RAMCard. Once DeskTop starts, eject the disk containing the program. Invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at first use". Invoke the shortcut. Verify that the files are copied to the RAMCard, and that the program starts correctly. Return to DeskTop by quitting the program. Eject the disk containing the program. Invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at first use". Invoke the shortcut. While the program's files are being copied to RAMCard, press Escape to cancel. Verify that not all of the files were copied to the RAMCard. Invoke the shortcut again. Verify that the files are copied to the RAMCard and that the program starts correctly.

* Repeat the following:
  * For these permutations:
    * Shortcut in (1) menu and list, and (2) list only.
    * Shortcut set to copy to RAMCard (1) on boot, (2) on first use, (3) never.
    * DeskTop set to (1) Copy to RAMCard, (2) not copying to RAMCard.
  * Launch DeskTop. Configure the shortcut. Restart. Launch DeskTop. Run the shortcut. Verify that it executes correctly.

* Configure at least two shortcuts. Launch DeskTop. Shortcuts > Run a Shortcut.... Cancel. Verify that neither shortcut is invoked.

* Launch DeskTop. Shortcuts > Run a Shortcut. Verify the OK button is disabled. Click on an item. Verify the OK button becomes enabled. Click on a blank option. Verify the OK button becomes disabled. Use the arrow keys to move selection. Verify that the OK button becomes enabled.


## File Types

* Put image file in `APPLE.MENU`, start DeskTop. Select it from the Apple menu. Verify image is shown.
* Put text file in `APPLE.MENU`, start DeskTop. Select it from the Apple menu. Verify text is shown.
* Put font file in `APPLE.MENU`, start DeskTop. Select it from the Apple menu. Verify font is shown.

* Put BASIC program in `APPLE.MENU`, start DeskTop. Select it from the Apple menu. Verify it runs.
* Put System program in `APPLE.MENU`, start DeskTop. Select it from the Apple menu. Verify it runs.

* Launch DeskTop. Open a window. Locate an executable BIN file icon. Double-click it. Verify that an alert is shown. Click Cancel. Verify the alert closes but nothing else happens. Repeat, but click OK. Verify that it executes.
* Launch DeskTop. Open a window. Locate an executable BIN file icon. Hold Solid-Apple and double-click it. Verify that it executes.
* Launch DeskTop. Open a window. Locate an executable BIN file icon. Select File > Open. Verify that it executes.
* Launch DeskTop. Open a window. Locate an executable BIN file icon. Press Open-Apple+O. Verify that it executes.
* Launch DeskTop. Open a window. Locate an executable BIN file icon. Press Solid-Apple+O. Verify that it executes.

* Launch DeskTop. Select a SYS file. Rename it to have a .SYSTEM suffix. Verify that it has an application (diamond and hand) icon, without moving.
* Launch DeskTop. Select a SYS file. Rename it to not have a .SYSTEM suffix. Verify that it has a system (computer) icon, without moving.
* Launch DeskTop. Select a TXT file. Rename it to have a .SHK suffix. Verify that it has an archive icon, without moving.
* Launch DeskTop. Select a TXT file. Rename it to have a .BXY suffix. Verify that it has an archive icon, without moving.
* Launch DeskTop. Select a TXT file. Rename it to have a .BNY suffix. Verify that it has an archive icon, without moving.

* Launch DeskTop. Try to copy files including a GS/OS forked file in the selection. Verify that an alert is shown, with the filename visible in the progress dialog. Verify that if OK is clicked, the operation continues with other files, and if Cancel is clicked the operation is aborted.
* Launch DeskTop. Try to copy files including a GS/OS forked file contained in a selected folder. Verify that an alert is shown, with the filename visible in the progress dialog. Verify that if OK is clicked, the operation continues with other files, and if Cancel is clicked the operation is aborted.
* Launch DeskTop. Try to delete files including a GS/OS forked file in the selection. Verify that an alert is shown, with the filename visible in the progress dialog. Verify that if OK is clicked, the operation continues with other files, and if Cancel is clicked the operation is aborted.
* Launch DeskTop. Try to delete files including a GS/OS forked file contained in a selected folder. Verify that an alert is shown, with the filename visible in the progress dialog. Verify that if OK is clicked, the operation continues with other files, and if Cancel is clicked the operation is aborted. Note that non-empty directories will fail to be deleted.
* Launch DeskTop. Using drag/drop, try to copy or move a folder containing a GS/OS forked file, where the source and destination windows are visible. When an alert is shown, click OK. Verify that the source and destination windows are updated.
* Launch DeskTop. Using drag/drop, try to copy a volume containing a GS/OS forked file and other files, where the destination window is visible. When an alert is shown, click OK. Verify that the destination window are updated.
* Launch DeskTop. Using File > Copy To..., try to copy a folder containing a GS/OS forked file, where the source and destination windows are visible. When an alert is shown, click OK. Verify that the source and destination windows are updated.
* Launch DeskTop. Using drag/drop, try to delete a GS/OS forked file. When the delete confirmation dialog is shown, click Cancel. Verify that the source window is not updated.
* Launch DeskTop. Using drag/drop, try to delete a GS/OS forked file. When the delete confirmation dialog is shown, click OK. When an alert is shown, click OK. Verify that the source window is updated.
* Launch DeskTop. Using File > Delete try to delete a GS/OS forked file, where the containing window is visible. When the delete confirmation dialog is shown, click OK. When an alert is shown, click OK. Verify that the containing window is updated.


## Hardware Configurations

### RAM Expansions

The following tests all require:
* A RAM disk such as RAMWorks (and a ProDOS driver) or a "Slinky" memory expansion card.
* Configuring DeskTop to install itself to the RAMCard on boot. This is the default but can be controlled using the Options control panel.

* Run DeskTop on a system with RAMWorks and using RAM.DRV.SYSTEM. Verify that subdirectories under APPLE.MENU are copied to /RAM/DESKTOP/APPLE.MENU.
* Run DeskTop on a system with Slinky Ramdisk. Verify that subdirectories under APPLE.MENU are copied to /RAM5/DESKTOP/APPLE.MENU (or appropriate volume path).

* Launch DeskTop, ensure it copies itself to RAMCard. Delete the LOCAL/DESKTOP.CONFIG file from the startup disk, if it was present. Go into Control Panels and change a setting. Verify that LOCAL/DESKTOP.CONFIG is written to the startup disk.
* Launch DeskTop, ensure it copies itself to RAMCard. Delete the LOCAL/SELECTOR.LIST file from the startup disk, if it was present. Shortcuts > Add a Shortcut, and create a new shortcut. When prompted to save to the system disk, select OK. Verify that LOCAL/SELECTOR.LIST is written to the startup disk.

* Configure a system with a RAMCard of at least 1MB. On a physical volume, create a directory with a system file (e.g. BASIC.SYSTEM) and a subdirectory. In the subdirectory, create 256 normal files followed by a subdirectory (with some files) followed by more files. Then run the following tests:
  * Launch DeskTop. Create a shortcut for the system file, set to copy to RAMCard at boot. Ensure DeskTop is set to copy to RAMCard on startup. Restart DeskTop. Verify that the directory is successfully copied.
  * Launch DeskTop. Create a shortcut for the system file, set to copy to RAMCard at first use. Ensure DeskTop is set to copy to RAMCard on startup. Ensure DeskTop is set to launch Selector. Quit DeskTop. Launch Selector. Select the shortcut. Verify that the directory is successfully copied.

* Launch DeskTop, ensure it copies itself to RAMCard. Drag a file to a same-volume window so it is moved. Configure a shortcut to copy to RAMCard "at first use". Invoke the shortcut. Verify that the shortcut's files were indeed copied, not moved.

* Launch DeskTop, ensure it copies itself to RAMCard. Configure a shortcut with the target in the root of a volume, and to Copy to RAMCard at first use. Quit DeskTop. Launch Selector. Invoke the shortcut. Verify that the copy count goes to zero and doesn't blank out.
* Launch DeskTop, ensure it copies itself to RAMCard. Configure a shortcut with the target in a directory, not the root of a volume, and to Copy to RAMCard at first use. Quit DeskTop. Launch Selector. Invoke the shortcut. Verify that the copy count goes to zero and doesn't blank out.
* Launch DeskTop, ensure it copies itself to RAMCard. Configure a shortcut set to Copy to RAMCard at first use. Invoke the shortcut. Verify that it correctly copies to the RAMCard and runs.

* Launch DeskTop, ensure it copies itself to RAMCard. Modify a shortcut. Verify that no prompt is shown. Power cycle and launch DeskTop. Verify that the shortcut modifications are present.
* Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Modify a shortcut. Verify that a prompt is shown asking about saving the changes. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the shortcut modifications are present.
* Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Modify a shortcut. Verify that a prompt is shown asking about saving the changes. Click OK. Verify that another prompt is shown asking to insert the system disk. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the shortcut modifications are present.

* Repeat the following cases with the Options and Control Panel DAs, and the Date and Time DA (on a system without a real-time clock):
  * Launch DeskTop, ensure it copies itself to RAMCard. Launch the DA and modify a setting. Verify that no prompt is shown. Power cycle and launch DeskTop. Verify that the modifications are present.
  * Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Launch the DA and Modify a setting. Verify that a prompt is shown asking about saving the changes. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the modifications are present.
  * Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Launch the DA and modify a setting. Verify that a prompt is shown asking about saving the changes. Click OK. Verify that another prompt is shown asking to insert the system disk. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the modifications are present.

* Launch DeskTop, ensure it copies itself to RAMCard. Open the RAM Disk volume. Open the Desktop folder. Apple > Control Panels. Drag Apple.Menu from the Desktop folder to the Control.Panels window. Verify that an alert is shown that an item can't be movied or copied into itself.

* Invoke DESKTOP.SYSTEM, ensure it copies itself to RAMCard. Quit DeskTop. Restart DeskTop from the original startup disk. Eject the startup disk. Special > Format a Disk. Verify that no prompt for the startup disk is shown.
* Invoke DESKTOP.SYSTEM, and hit Escape when copying to RAMCard. Once DeskTop has started, eject the startup disk. Special > Format a Disk. Verify that a prompt to insert the system disk is shown.

* Boot to BASIC.SYSTEM (without going through DESKTOP.SYSTEM first). Run the following commands: `CREATE /RAM5/DESKTOP`, `CREATE /RAM5/DESKTOP/MODULES`, `BSAVE /RAM5/DESKTOP/MODULES/DESKTOP,A0,L0` (substituting the RAM disks's name for `RAM5`). Launch `DESKTOP.SYSTEM`. Verify the install doesn't hang silently or loop endlessly.

### SmartPort

* Configure a system with more than 2 drives on a SmartPort controller. Boot ProDOS 2.4 (any patch version). Launch DeskTop. Special > Format a Disk. Verify that correct device names are shown for the mirrored drives.
* Configure a system with more than 2 drives on a SmartPort controller. Boot into ProDOS 2.0.1, 2.0.2, or 2.0.3. Launch DeskTop. Special > Format a Disk. Verify that correct device names are shown for the mirrored drives.
* Run on a system with a single slot providing 3 or 4 drives (e.g. CFFA, BOOTI, Floppy Emu); verify that all show up.
* Configure a system with a SmartPort controller in slot 1 and one drive. Launch DeskTop. Special > Format a Disk. Select the drive in slot 1. Verify that the format succeeds. Repeat for slots 2, 4, 5, 6 and 7.

* With a Floppy Emu in SmartPort mode, ensure that the 32MB image shows up as an option.

### RGB Display

* On an RGB system (IIgs, etc), go to Control Panel, check RGB Color. Verify that the display shows in color. Preview an image, and verify that the image shows in color and the DeskTop remains in color after exiting.
* On an RGB system (IIgs, etc), go to Control Panel, uncheck RGB Color. Verify that the display shows in monochrome. Preview an image, and verify that the image shows in color and the DeskTop returns to monochrome after exiting.

### Z80 Card

* Configure a system with a Z80 card and without a No-Slot Clock. Boot a package disk including the CLOCK.SYSTEM driver. Verify that it doesn't hang.

### Apple IIgs

* On an IIgs, go to Control Panel, check RGB Color. Verify that the display shows in color. Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that DeskTop remains in color.
* On an IIgs, go to Control Panel, uncheck RGB Color. Verify that the display shows in monochrome. Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that DeskTop resets to monochrome.

* Configure a IIgs system with ejectable disks. Launch DeskTop. Select the ejectable volume. Special > Eject Disk. Verify that an alert is not shown.

* Configure a IIgs via the system control panel to have a RAM disk:
  * Launch DeskTop. Verify that the Ram5 volume is shown with a RAMDisk icon.
  * Configure DeskTop to copy to RAMCard on startup, and restart. Verify it is copied to /RAM5.

* On a IIgs, go to Apple > This Apple. Verify the memory count is not "000,000".

### Apple IIc+

* Run DeskTop on a IIc+ from a 3.5" floppy on internal drive. Verify that the disk doesn't spin constantly.

### Laser 128

* Run on Laser 128; verify that 800k image files on Floppy Emu show as 3.5" floppy icons.
* Run on Laser 128, with a Floppy Emu. Select a volume icon. Special > Eject Disk. Verify that the Floppy Emu does not crash.
* Run on Laser 128. Launch DeskTop. Open a volume. Click on icons one by one. Verify selection changes from icon to icon, and isn't extended as if a Open-Apple key/button or Shift is down.


# Preview

Text File:
* Verify that Escape key exits.
* Verify that Space toggles Proportional/Fixed mode.
* Verify that DeskTop's selection is not cleared on exit.
* Preview a text file that can be displayed entirely within the window. Verify that the scrollbar is inactive.
* Preview a text file that is longer than one screen.
  * Verify that the scrollbar is active.
  * Verify that Up/Down Arrow keys scroll by one line.
  * Verify that Open-Apple plus Up/Down Arrow keys scroll by page.
  * Verify that Solid-Apple plus Up/Down Arrow keys scroll by page.
  * Verify that Open-Apple plus Solid-Apple plus Up/Down Arrow keys scroll to start/end.
  * Click the Proportional/Fixed button on the title bar. Verify that the view is scrolled to the top.
* Preview a long text file, e.g. 2000 lines. Verify that dragging the scroll thumb to the middle shows approximately the middle of the file.
* Preview a text file with a tab character in the first line. Verify that the file displays all lines correctly.
* Preview a long text file. Verify that the first page of content appears immediately, and that the watch cursor is shown while the rest of the file is parsed. With any acceleration disabled, use Open-Apple+Solid-Apple+Down to jump to the bottom of the file. Verify that the view is displayed without undue delay.


Image File:
* Verify that Escape key exits.
* On a IIgs or with RGB card; verify that space bar toggles color/mono.
* On a IIgs or with RGB card: name a hires image file with a ".A2HR" suffix. Verify it displays as mono by default.
* On a IIgs or with RGB card: name a hires image file with a ".A2LC" suffix. Verify it displays as color by default.
* Configure a system with a realtime clock. Launch DeskTop. Preview an image file. Exit the preview. Verify that the menu bar clock reappears immediately.

* Put `SHOW.IMAGE.FILE` in `APPLE.MENU`, start DeskTop.
    * Select no icon, select DA from Apple menu. Verify nothing happens.
    * Select volume icon, select DA from Apple menu. Verify nothing happens.
    * Select image file icon, select DA from Apple menu. Verify image is shown.
* Put `SHOW.TEXT.FILE` in `APPLE.MENU`, start DeskTop.
    * Select no icon, select DA from Apple menu. Verify nothing happens.
    * Select volume icon, select DA from Apple menu. Verify nothing happens.
    * Select text file icon, select DA from Apple menu. Verify text is shown.
* Put `SHOW.FONT.FILE` in `APPLE.MENU`, start DeskTop.
    * Select no icon, select DA from Apple menu. Verify nothing happens.
    * Select volume icon, select DA from Apple menu. Verify nothing happens.
    * Select font file icon, select DA from Apple menu. Verify font is shown.
* Put `SHOW.DUET.FILE` in `APPLE.MENU`, start DeskTop.
    * Select no icon, select DA from Apple menu. Verify nothing happens.
    * Select volume icon, select DA from Apple menu. Verify nothing happens.
    * Select Electric Duet file icon, select DA from Apple menu. Verify music is played.

# Desk Accessories

Repeat for every desk accessory that runs in a movable window:
* Launch DeskTop. Open the DA. Click on the title bar but don't move the window. Verify that window doesn't repaint if the window is not moved.

Repeat for every desk accessory that runs in a window.
* Launch DeskTop. Open the DA. Hold Apple (either Open-Apple or Solid-Apple) and press W. Verify that the desk accessory exits. Repeat with caps-lock off.

## Control Panel

* Launch DeskTop. Open the Control Panel DA. Use the pattern editor to create a custom pattern, then click the desktop preview to apply it. Close the DA. Open the Control Panel DA. Click the right arrow above the desktop preview. Verify that the default checkerboard pattern is shown.

* Launch DeskTop, invoke Control Panel DA. Under Mouse Tracking, toggle Slow and Fast. Verify that the mouse cursor doesn't warp to a new position, and that the mouse cursor doesn't flash briefly on the left edge of the screen.

* Open the Control Panel DA. Eject the startup volume. Close the DA without changing any settings. Verify that you are not prompted to save.
* Open the Control Panel DA. Eject the startup volume. Modify a setting and close the DA. Verify that you are prompted to save.

## Options

* Open the Options DA. Eject the startup volume. Close the DA without changing any settings. Verify that you are not prompted to save.
* Open the Options DA. Eject the startup volume. Modify a setting and close the DA. Verify that you are prompted to save.
* Open the Options DA. Move the window to the bottom of the screen so only the title bar is visible. Press Apple-1, Apple-2, Apple-3. Verify that checkboxes don't mis-paint on the screen. Move the window back up. Verify that the state of the checkboxes has toggled.

## International

* Open the Control Panels folder. View > by Name. Open International. Change the date format from M/D/Y to D/M/Y or vice versa. CLick OK. Verify that the entire desktop repaints, and that dates in the window are shown with the new format.
* Open the Control Panels folder. View > by Name. Open International. Close without changing anything. Verify that only a minimal repaint happens.

## Calculator and Sci.Calc

* Run Apple > Calculator. Drag Calculator window over a volume icon. Then drag calculator to the bottom of the screen so that only the title bar is visible. Verify that volume icon redraws properly.

* Run Apple > Calculator. Drag Calculator window to bottom of screen so only title bar is visible. Type numbers on the keyboard. Verify no numbers are painted on screen. Drag window back up. Verify the typed numbers were input.

Repeat for Calculator and Sci.Calc:
* With an English build, run the DA. Verify that '.' appears as the decimal separator in calculation results and that '.' when typed functions as a decimal separator.
* With an Italian build, run the DA. Verify that ',' appears as the decimal separator in calculation result and that ',' when typed functions as a decimal separator. Verify that when '.' is typed, ',' appears.
* Enter '1' '/' '2' '='. Verify that the result has a 0 before the decimal (i.e. "0.5").
* Enter '0' '-' '.' '5' '='. Verify that the result has a 0 before the decimal (i.e. "-0.5").

With Sci.Calc:
* Enter '1' '+' '2' 'SIN' '='. Verify that the result is 1.034...
* Enter '1' 'SIN' '+' '2' '='. Verify that the result is 2.017...
* Enter '4' '5' 'SIN'. Verify that the result is 0.707...
* Enter '4' '5' '+/-' 'SIN'. Verify that the result is -0.707...
* Enter '1' '8' '0' 'COS'. Verify that the result is -1
* Enter '4' '5' 'SIN' 'ASIN. Verify that the result is approximately 45.
* Enter '4' '5' 'COS' 'ACOS'. Verify that the result is approximately 45.
* Enter '8' '9' 'TAN' 'ATAN'. Verify that the result is approximately 89.

## Date & Time

* Configure a system with a realtime clock. Launch DeskTop. Run the Date and Time desk accessory. Press Escape key. Verify the desk accessory exits. Repeat with the Return key.

* Run DeskTop on a system without a system clock. Run Apple > Control Panels > Date and Time. Set date. Reboot system, and re-run DeskTop. Create a new folder. Use File > Get Info. Verify that the date was saved/restored.

* On a system with a system clock, invoke Apple > Control Panels > Date and Time. Verify that the date and time are read-only.

* Configure a system with a realtime clock. Launch DeskTop. Run the Date and Time DA, and change the setting to 12 hour. Verify that the time is shown as 12-hour, and if less than 10 is displayed without a leading 0.
* Configure a system with a realtime clock. Launch DeskTop. Run the Date and Time DA, and change the setting to 24 hour. Verify that the time is shown as 24-hour, and if less than 10 is displayed with a leading 0.
* Configure a system without a realtime clock. Launch DeskTop. Run the Date and Time DA, and change the setting to 12 hour. Verify that the time is shown as 12-hour, and if less than 10 is displayed without a leading 0. Use the Right Arrow and Left Arrow keys and the mouse, and verify that the AM/PM field is selectable. Select the AM/PM field. Use the up and down arrow keys and the arrow buttons, and verify that the field toggles. Select the hours field. Use the up and down arrow keys and the arrow buttons, and verify that the field cycles from 1 through 12.
* Configure a system without a realtime clock. Launch DeskTop. Run the Date and Time DA, and change the setting to 24 hour. Verify that the time is shown as 24-hour, and if less than 10 is displayed with a leading 0. Use the Right Arrow and Left Arrow keys and the mouse, and verify that the AM/PM field is not selectable. Use the up and down arrow keys and the arrow buttons, and verify that the field cycles from 0 through 23.
* Configure a system without a realtime clock. Launch DeskTop. Run the Date and Time DA. Change the month and year, and verify that the day range is clamped to 28, 29, 30 or 31 as appropriate, including for leap years.
* Configure a system without a realtime clock. Launch DeskTop. Run the Date and Time DA. Click on the up/down arrows. Verify that they invert correctly when the button is down.

## Calendar

* Configure a system with a realtime clock. Launch DeskTop. Run the Calendar DA. Verify that it starts up showing the current month and year correctly.
* Configure a system without a realtime clock. Launch DeskTop. Run the Calendar DA. Verify that it starts up showing the build's release month and year correctly.

## Sort Directory

* Open a folder containing a folder. Open the folder by double-clicking. Apple > Sort Directory. Verify that files are sorted by type/name.

* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open a volume window. Create a folder. Open the folder window, and close the volume window. Apple > Run Basic Here. Run a program such as `10 FOR I = 1 to 127-14 : ?CHR$(4);"SAVE F";I : NEXT` to create as many files as possible while keeping the total icon count to 127. `BYE` to return to DeskTop. Apple > Sort Directory. Make sure all the files are sorted lexicographically (e.g. F1, F10, F100, F101, ...)

## Key Caps

* Launch DeskTop. Run Apple > Key Caps desk accessory. Turn Caps Lock off. Hold Apple (either one) and press the Q key. Verify the desk accessory exits.

## Screen Savers

* Launch DeskTop. Apple > Screen Savers. Select Melt. File > Open (or Apple+O). Click to exit. Press Apple+Down. Click to exit. Verify that the File menu is not highlighted.
* Configure a system with a realtime clock. Launch DeskTop. Apple > Screen Savers. Run a screen saver that uses the full graphics screen and conceals the menu (Flying Toasters or Melt). Exit it. Verify that the menu bar clock reappears immediately.

* Launch DeskTop. Apple > Screen Savers. Run Matrix. Click the mouse button. Verify that the screen saver exits. Run Matrix. Press a key. Verify that the screen saver exits.

## About This Apple

* Configure a system with a Mockingboard and a Zip Chip, with acceleration enabled (MAME works). Launch DeskTop. Run the This Apple DA. Verify that the Mockingboard is detected.

* Configure a device multiple drives connected to a Smartport controller on a higher slot, a single drive connected to a Smartport controller in a lower slot. Launch DeskTop, run the This Apple DA. Verify that the name on the lower slot doesn't have an extra character at the end.

* Run on Laser 128. Launch DeskTop. Copy a file to Ram5. Launch This Apple DA, close it. Verify that the file is still present on Ram5.

## System Speed

* Run System Speed DA. Click Normal then click OK. Verify DeskTop does not lock up.
* Run System Speed DA. Click Fast then click OK. Verify DeskTop does not lock up.
* Run DeskTop on a IIc. Launch Control Panel > System Speed. Click Normal and Fast. Verify that display does not switch from DHR to HR.
* Run System Speed DA. Position the cursor to the left of the animation, where it is not flickering, and move it up and down. Verify that stray pixels are not left behind by the animation.

## Puzzle

* Launch DeskTop. Apple > Puzzle. Verify that the puzzle does not show as scrambled until the mouse button is clicked on the puzzle or a key is pressed. Repeat and verify that the puzzle is scrambled differently each time.
* Launch DeskTop. Apple > Puzzle. Verify that you can move and close the window using the title bar before the puzzle is scrambled.
* Launch DeskTop. Apple > Puzzle. Verify that you can close the window using Esc or Apple+W before the puzzle is scrambled.
* Launch DeskTop. Apple > Puzzle. Scramble then solve the puzzle. After the victory sound plays, click on the puzzle again. Verify that the puzzle scrambles and that it can be solved again.
* Launch DeskTop. Apple > Puzzle. Scramble the puzzle. Move the window so that only the title bar of the window is visible on screen. Use the arrow keys to move puzzle pieces. Verify that the puzzle pieces don't mispaint on the desktop.

## Run Basic Here

* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Ensure BASIC.SYSTEM is present on the boot volume. Launch DeskTop. Open a window. Apple > Run Basic Here. Verify that BASIC.SYSTEM starts.

## Joystick

* Configure a system with only a single joystick (or paddles 0 and 1). Run the DA. Verify that only a single indicator is shown.
* Configure a system with only a two joysticks (or paddles 2 and 3). Run the DA. Verify that after the second joystick is moved, a second indicator is shown.

## Find Files

* Launch DeskTop. Close all windows. Apple Menu > Find Files. Type "PRODOS" and click Search. Verify that all volumes are searched recursively.
* Launch DeskTop. Open a volume window. Apple Menu > Find Files. Type "PRODOS" and click Search. Verify that only that volume's contents are searched recursively.
* Launch DeskTop. Open a volume window. Open a folder window. Apple Menu > Find Files. Type "PRODOS" and click Search. Verify that only that folder's contents are searched recursively.
* Launch DeskTop. Open a window. Apple Menu > Find Files. Type "*" and click Search. Select a file in the list. Press Open-Apple+O. Verify that the Find Files window closes, that a window containing the file opens, and that the file icon is selected.
* Launch DeskTop. Open a window. Apple Menu > Find Files. Type "*" and click Search. Select a file in the list. Press Solid-Apple+O. Verify that the Find Files window closes, that a window containing the file opens, and that the file icon is selected.
* Launch DeskTop. Open a window. Apple Menu > Find Files. Type "*" and click Search. Double-click a file in the list. Verify that the Find Files window closes, that a window containing the file opens, and that the file icon is selected.
* Launch DeskTop. Open a volume window. Open a folder window. Activate the volume window. Apple Menu > Find Files. Type "*" and click Search. Double-click a file in the list that's inside the folder. Verify that the Find Files window closes, that a folder window is brought to the foreground, and that the file icon is selected.

* Create a set of nested directories, 21 levels deep or more (e.g. `/VOL/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D`). Launch DeskTop and open the volume. Apple > Find Files. Enter a search term (e.g. `*`) and click Search. Verify that the DA doesn't crash. (Not all files will be found, though.)

* Launch DeskTop. Open a window with at least two files. Apple Menu > Find Files. Type "*" and click Search. Press Down Arrow once. Type Return. Press Down Arrow again. Verify that only one entry in the list appears highlighted.

## Screen Dump

* Configure a system with an SSC in Slot 1 and an ImageWriter II. Invoke the Screen Dump DA. Verify it prints a screenshot.
* Configure a system with a non-SSC in Slot 1. Invoke the Screen Dump DA. Verify nothing happens.

# Selector

* Load Selector. Put a disk in Slot 6, Drive 1. Startup > Slot 6. Verify that the system boots the disk. Repeat for all other slots with drives.

* Launch Selector, invoke BASIC.SYSTEM. Ensure /RAM exists.
* Launch Selector, invoke DeskTop, File > Quit, run BASIC.SYSTEM. Ensure /RAM exists.
* Launch Selector. Invoke a BIN program file. Verify that during launch the screen goes completely black before the program starts, with no text characters present.

* Launch Selector. Type Open-Apple and R. Ensure "Run a Program..." dialog appears
* Launch Selector. Type Solid-Apple and R. Ensure "Run a Program..." dialog appears
* Launch Selector. Type Open-Apple and 6. Ensure machine boots from Slot 6
* Launch Selector. Type Solid-Apple and 6. Ensure machine boots from Slot 6

* Launch Selector. Eject the disk with DeskTop on it. Type Q (don't click). Dismiss the dialog by hitting Esc. Verify that the dialog disappears, and the Apple menu is not shown.

* Configure a system without a RAMCard. Launch Selector. File > Run a Program.... Verify that the volume containing Selector is the first disk shown.
* Configure a system with a RAMCard, and set DeskTop to copy itself to the RAMCard on startup. Launch Selector. File > Run a Program.... Verify that the non-RAMCard volume containing Selector is the first disk shown.
* Configure a system with a RAMCard, and set DeskTop to not copy itself to the RAMCard on startup. Launch Selector. File > Run a Program.... Verify that the non-RAMCard volume containing Selector is the first disk shown.

* Using DeskTop, either delete LOCAL/SELECTOR.LIST or just delete all shortcuts. Configure Selector to start. Launch Selector. Ensure DeskTop is automatically invoked and starts correctly.

* Configure a shortcut for a program with many associated files to copy to RAMCard "at boot". Reboot, and launch DESKTOP.SYSTEM. While the program's files are being copied to RAMCard, press Escape to cancel. Verify that not all of the files were copied to the RAMCard. Once Selector starts, invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at boot". Reboot, and launch DESKTOP.SYSTEM. Verify that all of the files were copied to the RAMCard. Once Selector starts, eject the disk containing the program. Invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at first use". Invoke the shortcut. Verify that the files are copied to the RAMCard, and that the program starts correctly. Return to Selector by quitting the program. Eject the disk containing the program. Invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at first use". Invoke the shortcut. While the program's files are being copied to RAMCard, press Escape to cancel. Verify that not all of the files were copied to the RAMCard. Invoke the shortcut again. Verify that the files are copied to the RAMCard and that the program starts correctly.

* Configure a shortcut for the BINSCII system utility. Launch Selector. Invoke the BINSCII system file. Verify that the display is not truncated.

* Launch Selector. Verify the OK button is disabled. Click on an item. Verify the OK button becomes enabled. Click on a blank option. Verify the OK button becomes disabled. Use the arrow keys to move selection. Verify that the OK button becomes enabled.
* Launch Selector. Select an item. Verify that the OK button becomes enabled. File > Run a Program... Cancel the dialog. Verify that selection is cleared and that the OK button is disabled.


# Disk Copy

* Launch DeskTop. Special > Disk Copy.... File > Quit. Special > Disk Copy.... Ensure drive list is correct.

* Launch DeskTop. Special > Disk Copy.... Press Escape key. Verify that menu keyboard mode starts.
* Launch DeskTop. Special > Disk Copy.... Press Open-Apple Q. Verify that DeskTop launches.
* Launch DeskTop. Special > Disk Copy.... Press Solid-Apple Q. Verify that DeskTop launches.

* Launch DeskTop. Special > Disk Copy. Copy a disk with more than 999 blocks. Verify thousands separators are shown in block counts.
* Launch DeskTop. Special > Disk Copy.... Copy a 32MB disk image using Quick Copy (the default mode). Verify that the screen is not garbled, and that the copy is successful.
* Launch DeskTop. Special > Disk Copy.... Copy a 32MB disk image using Disk Copy (the other mode). Verify that the screen is not garbled, and that the copy is successful.

* Launch DeskTop. Special > Disk Copy.... Make a device selection (using mouse or keyboard) but don't click OK. Open the menu (using mouse or keyboard) but dismiss it. Verify that source device wasn't accepted.
* Launch DeskTop. Special > Disk Copy.... Select a drive using the mouse or keyboard, but don't click OK. Double-click the same drive. Verify that it was accepted, and that a prompt for an appropriate destination drive was shown.
* Launch DeskTop. Special > Disk Copy.... Select a drive using the mouse or keyboard, but don't click OK. Double-click a different drive. Verify that it was accepted, and that a prompt for an appropriate destination drive was shown.

* Rename the DISK.COPY file to something else. Launch DeskTop. Special > Disk Copy.... Verify that an alert is shown. Cancel the alert. Verify that DeskTop continues to run.
* Launch DeskTop. Eject the boot volume. Special > Disk Copy.... Verify that an alert is shown. Cancel the alert. Verify that DeskTop continues to run.
* Launch DeskTop. Eject the boot volume. Special > Disk Copy.... Verify that an alert is shown. Re-insert the boot volume. Click OK in the alert. Verify that Disk Copy starts.
* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Special > Disk Copy.... Verify that Disk Copy starts.
* Launch DeskTop. Open and position a window. Special > Disk Copy.... File > Quit. Verify that DeskTop restores the window.
* On a IIgs, go to Control Panel, check RGB Color. Verify that the display shows in color. Special > Disk Copy.... Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that the display remains in color.
* On a IIgs, go to Control Panel, uncheck RGB Color. Verify that the display shows in monochrome. Special > Disk Copy.... Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that the display resets to monochrome.

* Configure a system with a RAMDisk in Slot 3, e.g. using RAM.DRV.SYSTEM or RAMAUX.SYSTEM. Launch DeskTop. Special > Disk Copy.... Verify that the RAMDisk appears.
* Configure a system with 8 or fewer drives. Launch DeskTop. Special > Disk Copy.... Verify that the scrollbar is inactive.
* Configure a system with 9 or more drives. Launch DeskTop. Special > Disk Copy.... Verify that the scrollbar is active.

* Launch DeskTop. Special > Disk Copy.... Verify that ProDOS disk names in the device list have adjusted case (e.g. "Volume" not "VOLUME").
* Launch DeskTop. Special > Disk Copy.... Verify that Pascal disk names in the device list do not have adjusted case (e.g. "TGP:" not "Tgp:").
* Launch DeskTop. Special > Disk Copy.... Verify that DOS 3.3 disk names in the device list appear as "DOS 3.3 Sn, Dn" and do not have adjusted case.

* Launch DeskTop. Special > Disk Copy.... Select a ProDOS disk as a source disk. Verify that after the "Insert source disk" prompt is dismissed, the volume name appears on the "Source" line and the name has adjusted case (e.g. "Volume" not "VOLUME").
* Launch DeskTop. Special > Disk Copy.... Select a Pascal disk as a source disk. Verify that after the "Insert source disk" prompt is dismissed, the volume name appears on the "Source" line and the name does not have adjusted case (e.g. "TGP:" not "Tgp:").
* Launch DeskTop. Special > Disk Copy.... Select a DOS 3.3 disk as a source disk. Verify that after the "Insert source disk" prompt is dismissed, no volume name appears on the "Source" line.

* Launch DeskTop. Special > Disk Copy.... Select a ProDOS disk as a desination disk. Verify that in the "Do you want to erase ...?" dialog that the name has adjusted case (e.g. "Volume" not "VOLUME"), and the name is quoted.
* Launch DeskTop. Special > Disk Copy.... Select a Pascal disk as a desination disk. Verify that in the "Do you want to erase ...?" dialog that the name does not have adjusted case (e.g. "TGP:" not "Tgp:"), and the name is quoted.
* Launch DeskTop. Special > Disk Copy.... Select a DOS 3.3 disk as a desination disk. Verify that in the "Do you want to erase ...?" dialog that the prompt describes the disk using slot and drive, and is not quoted.

* Configure Virtual II with two Omnidisks formatted as ProDOS volumes mounted. Launch DeskTop. Special > Disk Copy.... Select the Omnidisks as Source and Destination. Verify that after being prompted to insert the source and destination disks, a "Do you want to erase ...?" confirmation prompt is shown.

# Alerts

* Launch DeskTop. Trigger an alert with only OK (e.g. running a shortcut with disk ejected). Verify that Escape key closes alert.
* Launch Selector. Trigger an alert with only OK (e.g. running an shortcut with disk ejected). Verify that Escape key closes alert.
* Launch DeskTop. Run Special > Disk Copy. Trigger an alert with only OK. Verify that Escape key closes alert.

# File Picker

This covers:

* Selector: File > Run a Program...
* DeskTop: File > Copy To...
* DeskTop: Shortcuts > Add a Shortcut...
* DeskTop: Shortcuts > Edit a Shortcut...

Test the following in all of the above, except where called out specifically:

* Browse to a directory containing multiple files. Hold an Apple key and start typing a filename. Verify that a prefix-matching file or the subsequent file is selected, or the last file. For example, if the files "Alfa", "November" and "Whiskey" are present, typing "A" selects "Alfa", typing "AB" selects "Alfa", typing "AL" selects "Alfa", typing "ALFAA" selects "November", typing "B" selects "November", typing "Z" selects "Whiskey". Repeat including filenames with numbers and periods.
* Browse to a directory containing multiple files. Hold an Apple key and start typing a filename. Move the mouse, or press a key without holding Apple. Hold an Apple key and start typing another filename. Verify that the matching is reset.
* Browse to a directory containing no files. Hold an Apple key and start typing a filename. Verify nothing happens.
* Browse to a directory containing one or more files starting with lowercase letters (AppleWorks or GS/OS). Verify the files appear with correct names. Press Apple+letter. Verify that the first file starting with that letter is selected.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Press Apple+1 through Apple+5. Verify that the radio buttons on the right are selected.

* Browse to a directory containing one or more files with starting with mixed case (AppleWorks or GS/OS). Verify the filenames appear with correct case.
* Browse to a directory containing 7 files. Verify that the scrollbar is inactive.
* Browse to a directory containing 8 files. Verify that the scrollbar is active. Press Apple+Down. Verify that the scrollbar thumb moves to the bottom of the track.

* Ensure the default drive has 10 or more files. Verify that an active scrollbar appears in the file list. Click OK. Click Cancel. Verify that the scrollbar is scrolled to the top.

* Launch DeskTop. Special > Format a Disk.... Select a drive with no disk, let the format fail and cancel. File > Copy To.... Verify that the file list is populated.

* Launch DeskTop. Shortcuts > Add a Shortcut.... Enter text in the first field. Move the IP into the middle of the text. Click in the second field. Verify that the first field is not truncated.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Enter a name in the first field. Move the IP into the middle of the text. Click OK. Verify that the first field is not truncated.

* Launch DeskTop. Shortcuts > Add a Shortcut.... Enter text in the second field. Move the IP into the middle of the text. Click in the first field. Verify that the second field is not truncated.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Enter a name in the second field. Move the IP into the middle of the text. Click Cancel. Verify that the second field is not truncated.

* Create a directory, and in the directory create a file named "A.B" then a file named "A". Browse to the directory. Verify "A" sorts before "A.B".

* Browse to a directory with more than 8 files, with at least 1 directory. Note the first directory name. Scroll down so that the first file in the list is not seen. Pick a file and click OK. Verify that the first directory is visible in the list.

* Open a directory with more than 30 files, without resizing the window. Scroll up and down by one tick, by one page, and to the top/bottom. Verify that such operations scroll by an integral number of icons, i.e. the last row of labels are always the same distance from the bottom of the window.

* In Shortcuts > Add/Edit a Shortcut... name field:
  * Type a non-path, non-control character. Verify that it is accepted.
  * Type a control character that is not an alias for an arrow/Tab/Return/Escape, e.g. Control+D. Verify that it is ignored.
  * Move the cursor over the text field. Verify that the cursor changes to an I-beam.
  * Move the cursor off the text field. Verify that the cursor changes to a pointer.

* Click the Drives button. Verify that on-line volumes are listed in alphabetical order.
* Click the Drives button. Manually eject a disk. Click the Drives button again. Verify that the ejected disk is removed from the list.

Repeat for each file picker:
* While there is no selection in the list box, verify that the Open button is dimmed.
* Select a folder in the list box. Verify that the Open button is not dimmed.
* Select a non-folder in the list box. Verify that the Open button is dimmed.
* Navigate to the root directory of a disk. Verify that the Close button is not dimmed.
* Open a folder. Verify that the Close button is not dimmed, that there is no selection, and that Open is dimmed. Hit Close until at the root. Verify that Close is dimmed.
* Click Drives. Verify that the Close button is dimmed.
* Click Drives. Verify that the OK button is dimmed. Click a volume name and click Open. Verify that the OK button is no longer dimmed.
* Verify that dimmed buttons don't respond to clicks.
* Verify that dimmed buttons don't respond to keyboard shortcuts (Return for OK, Control+O for Open, Control+C for Close).

For DeskTop's Shortcut > Edit a Shortcut... file picker:
* Create a shortcut not on the startup volume. Edit the shortcut. Verify that the file picker shows the shortcut target volume and file selected.
* Create a shortcut on a removable volume. Eject the volume. Edit the shortcut. Verify that the file picker initializes to any available volume, and does not crash or show corrupted results.

For Selector's File > Run a Program... file picker:
* Navigate to an empty volume and don't select anything. Click OK. Verify that an alert is shown.
* Move the mouse cursor over a folder in the list, and click to select it. Move the mouse cursor away from the click location but over the same item. Double-click. Verify that the folder opens with only the two clicks.
* Move the mouse cursor over a folder in the list that is not selected. Double-click. Verify that the folder opens with only the two clicks.

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
* File Pickers
* Disk Copy
* Sounds DA
* Find Files DA

Repeat for each list box:
* Verify the following keyboard shortcuts:
  * If the scrollbar is not enabled, the view should not scroll.
  * Up Arrow
    * If there is no selection, selects the last item and scrolls it into view.
    * Otherwise, selects the previous item and scrolls it into view.
  * Down Arrow
    * If there is no selection, selects the first item and scrolls it into view.
    * Otherwise, selects the next item and scrolls it into view.
  * Apple+Up Arrow
    * Scrolls one page up.
    * Selection is not changed.
  * Apple+Down Arrow
    * Scrolls one down up.
    * Selection is not changed.
  * Open-Apple+Solid-Apple+Up Arrow
    * Scrolls the view so that the first item is visible.
    * Selects the first item.
  * Open-Apple+Solid-Apple+Down Arrow
    * Scrolls the view so that the last item is visible.
    * Selects the last item.
* Hold down the mouse button on the scrollbar's up arrow or down arrow; verify that the scrolling continues as long as the button is held down.
* Click on an item. Verify it is selected. Click on white space below the items (if possible). Verify that selection is cleared.

For the Sounds DA:
* Click on an item. Verify it is selected, and plays the sound. Click on the same selected item. Verity if plays the sound again.

Repeat for each list box where the contents are dynamic:
* Populate the list so that the scrollbar is active. Scroll down by one row. Repopulate the list box so that the scrollbar is inactive. Verify that all expected items are shown, and hitting the Up Arrow key does nothing.

# Menus

* Click to open a menu. Without clicking again, move the mouse pointer up and down over the menu items, while simultaneously tapping the 'A' key. Verify that the key presses do not cause other menus to open instead.

The following steps exercise the menu as "pull down" using the mouse:

* Mouse-over a menu bar item, and press and hold the mouse button to pull down the menu. Drag to an item and release the button. Verify the menu closes and the item is invoked.
* Mouse-over a menu bar item, and press and hold the mouse button to pull down the menu. Drag to a separator and release the button. Verify the menu closes.
* Mouse-over a menu bar item, and press and hold the mouse button to pull down the menu. Drag off of the menu and release the button. Verify the menu closes.

The following steps exercise the menu as "drop down" using the mouse:

* Click (press and release the mouse button) on a menu bar item. Move the mouse over an item and click it. Verify the menu closes and that the item is invoked.
* Click (press and release the mouse button) on a menu bar item. Move the mouse over a separator and click it. Verify the menu closes.
* Click (press and release the mouse button) on a menu bar item. Move the mouse off the menu and click. Verify the menu closes.

The following steps exercise the menu as "drop down" using the keyboard:

* Press the Escape key. Verify that the first menu opens. Press the Escape key again. Verify that the menu closes.
* Press the Escape key. Verify that the first menu opens. Use the Up, Down, Left and Right Arrow keys to move among menu items. Press the Escape key again. Verify that the menu closes.
* Press the Escape key. Verify that the first menu opens. Use the Up, Down, Left and Right Arrow keys to move among menu items. Press the Return key. Verify that the menu closes, and that the item is invoked.

The following steps exercise the menu as "drop down" using the mouse to initiate and finish the action, but with the keyboard as an intermediate step:

* Click (press and release the mouse button) on a menu bar item. Use the Up, Down, Left and Right Arrow keys to move among menu items. Move the mouse over an item and click it. Verify the menu closes, and that the item is invoked.
* Click (press and release the mouse button) on a menu bar item. Use the Up, Down, Left and Right Arrow keys to move among menu items. Move the mouse over a separator and click it. Verify the menu closes.
* Click (press and release the mouse button) on a menu bar item. Use the Up, Down, Left and Right Arrow keys to move among menu items. Move the mouse off the menu and click. Verify the menu closes.

The following steps exercise the menu as "drop down" using the keyboard to initiate and finish the action, but with the mouse as an intermediate step:

* Press the Escape key. Verify that the first menu opens. Move the mouse over menu items. Press the Escape key again. Verify that the menu closes.
* Press the Escape key. Verify that the first menu opens. Move the mouse over a menu item. Press the Return key. Verify that the menu closes, and that the item is invoked.

The following steps exercise the menu as "drop down" using the mouse to initiate the action and the keyboard to finish the action:

* Click (press and release the mouse button) on a menu bar item. Use the mouse to move over an item. Use the arrow keys to select a different item. Press Escape. Verify that the menu closes.
* Click (press and release the mouse button) on a menu bar item. Use the mouse to move over an item. Use the arrow keys to select a different item. Press Return. Verify that the menu closes, and that the item is invoked.

The following steps exercise the menu as "drop down" using the keyboard to initiate the action and the mouse to finish the action:

* Press the Escape key. Verify that the first menu opens. Click an item with the mouse. Verify that the menu closes, and that the item is invoked.
* Press the Escape key. Verify that the first menu opens. Click a separator with the mouse. Verify that the menu closes.
* Press the Escape key. Verify that the first menu opens. Click outside the menu. Verify that the menu closes.

* Click on a menu to show it. While it is open, press the shortcut key for a command (e.g. Open-Apple+Q to Quit). Verify that the menu closes and that the command is invoked.
* Press Escape to activate the menu. While it is open, press the shortcut key for a command (e.g. Open-Apple+Q to Quit). Verify that the menu closes and that the command is invoked.

* Launch DeskTop. Close all windows. Press the Escape key. Use the Left and Right Arrow keys to highlight the View menu. Verify that all menu items are disabled. Press the Up and Down arrow keys. Verify that the cursor position does not change.

# Mouse Keys

* Enter MouseKeys mode (Open-Apple+Solid-Apple+Space). Using the Left, Right, Up and Down Arrow keys to move the mouse and the Solid-Apple (or Option) key as the mouse button, "pull down" a menu and select an item. Verify that after the item is selected that MouseKeys mode is still active. Press Escape to exit MouseKeys mode.
* Enter MouseKeys mode (Open-Apple+Solid-Apple+Space). Using the Left, Right, Up and Down Arrow keys to move the mouse and the Solid-Apple (or Option) key as the mouse button, "drop down" a menu and select an item. Verify that after the item is selected that MouseKeys mode is still active. Press Escape to exit MouseKeys mode.

# Keyboard Window Control

These shortcuts only apply in DeskTop.

* Open a window. Press Apple+M. Use the Left, Right, Up and Down Arrow keys to move the window outline. Press Escape. Verify that the window does not move.
* Open a window. Press Apple+M. Use the Left, Right, Up and Down Arrow keys to move the window outline. Press Return. Verify that the window moves to the new location.
* Open a window. Press Apple+G. Use the Left, Right, Up and Down Arrow keys to resize the window outline. Press Escape. Verify that the window does not resize.
* Open a window. Press Apple+G. Use the Left, Right, Up and Down Arrow keys to resize the window outline. Press Return. Verify that the window resizes.



