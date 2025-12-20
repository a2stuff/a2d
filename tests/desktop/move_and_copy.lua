--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Move a file by dragging - same volume - target is window.
]]
test.Step(
  "Move a file by dragging - same volume - target is window",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    test.Expect(#a2d.GetSelectedIcons(), 2, "should start with 2 files")

    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Select("FOLDER")
    a2d.OpenSelection()
    a2d.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2


    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        m.ButtonUp()
    end)
    emu.wait(1)

    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    test.Expect(#a2d.GetSelectedIcons(), 1, "file should have moved")
    a2d.SelectPath("/RAM1/FOLDER/READ.ME")

    a2d.EraseVolume("RAM1")
end)

--[[
  Move a file by dragging - same volume - target is volume icon.
]]
test.Step(
  "Move a file by dragging - same volume - target is volume icon",
  function()
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1/FOLDER")

    a2d.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/RAM1/FOLDER")
    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        m.ButtonUp()
    end)
    emu.wait(1)

    a2d.OpenPath("/RAM1/FOLDER")
    emu.wait(1)
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "file should have moved")
    a2d.SelectPath("/RAM1/READ.ME")

    a2d.EraseVolume("RAM1")
end)

--[[
  Move a file by dragging - same volume - target is folder icon.
]]
test.Step(
  "Move a file by dragging - same volume - target is folder icon",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.OpenPath("/RAM1")

    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Select("FOLDER")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        m.ButtonUp()
    end)
    emu.wait(1)

    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "file should have moved")
    a2d.SelectPath("/RAM1/FOLDER/READ.ME")

    a2d.EraseVolume("RAM1")
end)

--[[
  Copy a file by dragging - same volume - target is window, holding
  Solid-Apple.
]]
test.Step(
  "Copy a file by dragging - same volume - target is window",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    test.Expect(#a2d.GetSelectedIcons(), 2, "should start with 2 files")

    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Select("FOLDER")
    a2d.OpenSelection()
    a2d.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        apple2.PressSA()
        m.ButtonUp()
        apple2.ReleaseSA()
    end)
    emu.wait(1)

    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "file should have copied")
    a2d.SelectPath("/RAM1/FOLDER/READ.ME")

    a2d.EraseVolume("RAM1")
end)

--[[
  Copy a file by dragging - same volume - target is volume icon,
  holding Solid-Apple.
]]
test.Step(
  "Copy a file by dragging - same volume - target is volume icon",
  function()
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1/FOLDER")

    a2d.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/RAM1/FOLDER")
    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        apple2.PressSA()
        m.ButtonUp()
        apple2.ReleaseSA()
    end)
    emu.wait(1)

    a2d.OpenPath("/RAM1/FOLDER")
    emu.wait(1)
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "file should have copied")
    a2d.SelectPath("/RAM1/READ.ME")

    a2d.EraseVolume("RAM1")
end)

--[[
  Copy a file by dragging - same volume - target is folder icon,
  holding Solid-Apple.
]]
test.Step(
  "Copy a file by dragging - same volume - target is folder icon",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.OpenPath("/RAM1")
    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.Select("FOLDER")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        apple2.PressSA()
        m.ButtonUp()
        apple2.ReleaseSA()
    end)
    emu.wait(1)

    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "file should have copied")
    a2d.SelectPath("/RAM1/FOLDER/READ.ME")

    a2d.EraseVolume("RAM1")
end)

--[[
  Copy a file by dragging - different volume - target is window.
]]
test.Step(
  "Copy a file by dragging - different volume - target is window",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        m.ButtonUp()
    end)
    emu.wait(1)
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.SelectPath("/RAM1/READ.ME")

    a2d.EraseVolume("RAM1")
end)

--[[
  Copy a file by dragging - different volume - target is volume icon.
]]
test.Step(
  "Copy a file by dragging - different volume - target is volume icon",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM1", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        m.ButtonUp()
    end)
    emu.wait(1)

    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.SelectPath("/RAM1/READ.ME")

    a2d.EraseVolume("RAM1")
end)

--[[
  Select multiple files, including a folder containing files. Drag the
  files to a folder on the same volume. Verify that the progress
  dialog shows "Moving" and that the number of files listed matches
  the number of selected files.

  Select multiple files, including a folder containing files. Hold
  Solid-Apple and drag the files to a folder on the same volume.
  Verify that the progress dialog shows "Copying" and that the number
  of files listed matches the number of selected files plus the number
  of files in the folder.
]]
test.Variants(
  {
    "Moving count is accurate",
    "Copying count is accurate",
  },
  function(idx)
    a2d.CreateFolder("/RAM1/SRC")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.CopyPath("/A2.DESKTOP/PRODOS", "/RAM1/SRC")
    a2d.CopyPath("/A2.DESKTOP/DESKTOP.SYSTEM", "/RAM1/SRC")
    a2d.CreateFolder("/RAM1/DST")

    a2d.OpenPath("/RAM1")
    a2d.Select("READ.ME")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    a2d.Select("SRC")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    a2d.Select("DST")
    local x3, y3 = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x1, y1)
        m.Click()
        m.MoveToApproximately(x2, y2)
        apple2.PressOA()
        m.Click()
        apple2.ReleaseOA()
        emu.wait(1)
        m.ButtonDown()
        m.MoveToApproximately(x3, y3)

        if idx == 1 then
          m.ButtonUp()
        else
          apple2.PressSA()
          m.ButtonUp()
          apple2.ReleaseSA()
        end

    end)
    emu.wait(0.25)

    if idx == 1 then
      test.Snap("verify dialog shows 'Moving: 2 files'")
    else
      test.Snap("verify dialog shows 'Copying: 4 files'")
    end

    emu.wait(2)
    a2d.EraseVolume("RAM1")
end)


--[[
  Select multiple files, including a folder containing files. Hold
  Solid-Apple and drag the files to another volume. Verify that the
  progress dialog shows "Moving" and that the number of files listed
  matches the number of selected files plus the number of files in the
  folder.
]]

--[[
  Select a volume icon. Hold Solid-Apple and drag the volume icon to
  another volume icon or window from another volume. Verify that the
  progress dialog shows "Copying" and that the number of files listed
  matches the number of files in the volume.
]]

--[[
  Launch DeskTop. Try to move a file (drag on same volume) where there
  is not enough space to make a temporary copy, e.g. a 100K file on a
  140K disk. Verify that the file is moved successfully and no error
  is shown.
]]
--[[
  Launch DeskTop. Try to copy a file (drag to different volume) where
  there is not enough space to make the copy. Verify that the error
  message says that the file is too large to copy.
]]
--[[
  Launch DeskTop. Drag multiple selected files to a different volume,
  where one of the middle files will be too large to fit on the target
  volume but that subsequently selected files will fit. Verify that an
  error message says that the file is too large to copy, and that
  clicking OK continues to copy the remaining files.
]]
--[[
  Launch DeskTop. Drag a single folder or volume containing multiple
  files to a different volume, where one of the files will be too
  large to fit on the target volume but all other files will fit.
  Verify that an error message says that the file is too large to
  copy, and that clicking OK continues to copy the remaining files.
]]

--[[
  Launch DeskTop. Open a window. File > New Folder, enter name. Copy
  the file to another folder or volume. Verify that the "Files
  remaining" count bottoms out at 0.
]]
--[[
  Launch DeskTop. Open a window. File > New Folder, enter name. Move
  the file to another folder or volume. Verify that the "Files
  remaining" count bottoms out at 0.
]]
--[[
  Launch DeskTop. Copy multiple selected files to another volume.
  Repeat the copy. When prompted to overwrite, alternate clicking Yes
  and No. Verify that the "Files remaining" count decreases to zero.
]]

--[[
  Load DeskTop. Create a folder e.g. `/RAM/F`. Try to copy the folder
  into itself using File > Copy To.... Verify that an error is shown.
]]
--[[
  Load DeskTop. Create a folder e.g. `/RAM/F`. Open the containing
  window, and the folder itself. Try to move it into itself by
  dragging. Verify that an error is shown.
]]
--[[
  Load DeskTop. Create a folder e.g. `/RAM/F`, and a sibling folder
  e.g. `/RAM/B`. Open the containing window, and the first folder
  itself. Select both folders, and try to move both into the first
  folder's window by dragging. Verify that an error is shown before
  any moves occur.
]]
--[[
  Load DeskTop. Create a folder e.g. `/RAM/F`. Open the containing
  window, and the folder itself. Try to copy it into itself by
  dragging with an Apple key depressed. Verify that an error is shown.
]]
--[[
  Load DeskTop. Open a volume window. Drag a file icon from the volume
  window to the volume icon. Verify that an error is shown.
]]
--[[
  Load DeskTop. Create a folder, and a file within the folder with the
  same name as the folder (e.g. `/RAM/F` and `/RAM/F/F`). Try to copy
  the file over the folder using File > Copy To.... Verify that an
  error is shown.
]]
--[[
  Load DeskTop. Create a folder, and a file within the folder with the
  same name as the folder (e.g. `/RAM/F` and `/RAM/F/F`). Try to move
  the file over the folder using drag and drop. Verify that an error
  is shown.
]]
--[[
  Load DeskTop. Create a folder, and a file within the folder with the
  same name as the folder, and another file (e.g. `/RAM/F` and
  `/RAM/F/F` and `/RAM/F/B`). Select both files and try to move them
  into the parent folder using drag and drop. Verify that an error is
  shown before any files are moved.
]]

--[[
  Load DeskTop. Create a folder on a volume. Create a non-folder file
  with the same name as the folder on a second volume. Drag the folder
  to the second volume. When prompted to overwrite, click Yes. Verify
  that the volume contains a folder of the appropriate name.
]]
--[[
  Load DeskTop. Create a folder on a volume, containing a non-folder
  file. Create a non-folder file with the same name as the folder on a
  second volume. Drag the folder to the second volume. When prompted
  to overwrite, click Yes. Verify that the volume contains a folder of
  the appropriate name, containing a non-folder file.
]]
--[[
  Load DeskTop. Create a non-folder file on a volume. Create a folder
  with the same name as the file on a second volume. Drag the file
  onto the second volume. Verify that an alert is shown about
  overwriting a directory.
]]

--[[
  Ensure the startup disk has a name that would be case-adjusted by
  DeskTop, e.g. `/HD` but that shows as "Hd". Launch DeskTop. Open the
  startup disk. Apple Menu > Control Panels. Drag a DA file to the
  startup disk window. Verify that the file is moved, not copied.
]]

--[[
  Launch DeskTop. Use File > Copy To... to copy a file. Verify that
  the file is indeed copied, not moved.
]]
--[[
  Launch DeskTop. Drag a file icon to a same-volume window so it is
  moved, not copied. Use File > Copy To... to copy a file. Verify that
  the file is indeed copied, not moved.
]]

--[[For the following cases, open `/TESTS` and `/TESTS/FOLDER`:]]

--[[
  Drag a file icon from another volume onto the `TESTS` icon. Verify
  that the `TESTS` window activates and refreshes, and that the
  `TESTS` window's used/free numbers update. Click on the `FOLDER`
  window. Verify that the `FOLDER` window's used/free numbers update.
]]
--[[
  Drag a file icon from another volume onto the `TESTS` window. Verify
  that the `TESTS` window activates and refreshes, and that the
  `TESTS` window's item count/used/free numbers update. Click on the
  `FOLDER` window. Verify that the `FOLDER` window's used/free numbers
  update.
]]
--[[
  Copy a file from another volume to the `TESTS` icon using File >
  Copy To.... Verify that the `TESTS` window activates and refreshes,
  and that the `TESTS` window's item count/used/free numbers update.
  Click on the `FOLDER` window. Verify that the `FOLDER` window's
  used/free numbers update.
]]
--[[
  Drag a file icon from another volume onto the `FOLDER` window.
  Verify that the `FOLDER` window activates and refreshes, and that
  the `FOLDER` window's item count/used/free numbers update. Click on
  the `TESTS` window. Verify that the `TESTS` window's used/free
  numbers update.
]]
--[[
  Copy file from another volume to `/TESTS/FOLDER` using File > Copy
  File.... Verify that the `FOLDER` window activates and refreshes,
  and that the `FOLDER` window's item count/used/free numbers update.
  Click on the `TESTS` window. Verify that the `TESTS` window's
  used/free numbers update.
]]
--[[
  Drag a file icon from the `TESTS` window to the trash. Verify that
  the `TESTS` window refreshes, and that the `TESTS` window's item
  count/used/free numbers update. Click on the `FOLDER` window. Verify
  that the `FOLDER` window's used/free numbers update.
]]
--[[
  Delete a file from the `TESTS` window using File > Delete. Verify
  that the `TESTS` window refreshes, and that the `TESTS` window's
  item count/used/free numbers update. Click on the `FOLDER` window.
  Verify that the `FOLDER` window's used/free numbers update.
]]
--[[
  Drag a file icon from the `FOLDER` window to the trash. Verify that
  the `FOLDER` window refreshes, and that the `FOLDER` window's item
  count/used/free numbers update. Click on the `TESTS` window. Verify
  that the `TESTS` window's used/free numbers update.
]]
--[[
  Delete a file from the `FOLDER` window using File > Delete. Verify
  that the `FOLDER` window refreshes, and that the `FOLDER` window's
  item count/used/free numbers update. Click on the `TESTS` window.
  Verify that the `TESTS` window's used/free numbers update.
]]
--[[
  Duplicate a file in the `FOLDER` window using File > Duplicate.
  Verify that the `FOLDER` window refreshes, and that the `FOLDER`
  window's item count/used/free numbers update. Click on the `TESTS`
  window. Verify that the `TESTS` window's used/free numbers update.
]]
--[[
  Drag a file icon in the `TESTS` window onto the `FOLDER` icon while
  holding Apple to copy it. Verify that the `FOLDER` window activates
  and refreshes, and that the `FOLDER` window's item count/used/free
  numbers update. Click on the `TESTS` window. Verify that the `TESTS`
  window's used/free numbers update.
]]
--[[
  Drag a file icon in the `TESTS` window onto the `FOLDER` window
  while holding Apple to copy it. Verify that the `FOLDER` window
  activates and refreshes, and that the `FOLDER` window's item
  count/used/free numbers update. Click on the `TESTS` window. Verify
  that the `TESTS` window's used/free numbers update.
]]

--[[
  Repeat the following in an active and inactive window. In the
  inactive window case, verify that at the end of the test that the
  window is activated.

  * Drag a single file icon and drop it within the same window. Verify the icon is moved.
  * Drag multiple file icons and drop them within the same window. Verify the icons are moved.
  * Drag a single file icon and drop it within the same window while holding either Open-Apple or Solid-Apple. Verify the icon is duplicated.
  * Drag multiple file icons and drop them within the same window while holding either Open-Apple or Solid-Apple. Verify nothing happens.
  * Drag a single file icon and drop it within the same window while holding both Open-Apple and Solid-Apple. Verify that an alias is created.
  * Drag multiple file icons and drop them within the same window while holding both Open-Apple and Solid-Apple. Verify nothing happens.
]]
--[[
  Launch DeskTop. Find a folder containing a file where the folder and
  file's creation dates (File > Get Info) differ. Copy the folder.
  Select the file in the copied folder. File > Get Info. Verify that
  the file creation and modification dates match the original.
]]
--[[
  Launch DeskTop. Find a folder containing files and folders. Copy the
  folder to another volume. Using File > Get Info, compare the source
  and destination folders and files (both the top level folder and
  nested folders). Verify that the creation and modification dates
  match the original.
]]
--[[
  Launch DeskTop. Drag a volume icon onto another volume icon (with
  sufficient capacity). Verify that no alert is shown. Repeat, but
  drag onto a volume window instead.
]]
--[[
  Launch DeskTop. Drag a volume icon onto a folder icon (with
  sufficient capacity). Verify that no alert is shown, and that the
  folder's creation date is unchanged and its modification date is
  updated. Repeat, but drag onto a folder window instead.
]]
--[[
  Launch DeskTop. Drag a volume icon onto another volume icon where
  there is not enough capacity for all of the files but there is
  capacity for some files. Verify that the copy starts and that when
  an alert is shown the progress dialog references a specific file,
  not the source volume itself.
]]

--[[
  Launch DeskTop. Open two windows containing multiple files. Select
  multiples files in the first window. File > Copy To.... Select the
  second window's location as a destination and click OK. During the
  initial count of the files, press Escape. Verify that the count is
  canceled and the progress dialog is closed, and that the second
  window's contents do not refresh.
]]
--[[
  Launch DeskTop. Open two windows containing multiple files. Select
  multiples files in the first window. File > Copy To.... Select the
  second window's location as a destination and click OK. After the
  initial count of the files is complete and the actual operation has
  started, press Escape. Verify that the second window's contents do
  refresh.
]]

--[[
  Launch DeskTop. Drag `/TESTS/EMPTY.FOLDER` to another volume. Verify
  that it is copied.
]]

--[[
  Configure a system with removable disks, e.g. Disk II in S6D1, and
  prepare two ProDOS disks with volume names `SRC` and `DST`, and a
  small file (2K or less is ideal) on `SRC`. Mount `SRC`. Launch
  DeskTop. Open `SRC` and select the file. File > Copy To.... Eject
  the disk and insert `DST`. Click Drives. Select `DST` and click OK.
  When prompted, insert the appropriate source and destination disks
  until the copy is complete. Inspect the contents of the file and
  verify that it was copied byte-for-byte correctly.
]]

--[[
  Launch DeskTop. Drag a file to another volume to copy it. Open the
  volume and select the newly copied file. File > Get Info. Check
  Locked and click OK. Drag a file with a different type but the same
  name to the volume. When prompted to overwrite, click Yes. Verify
  that the file was replaced.
]]

--[[
  Load DeskTop. Open a window for a volume in a Disk II drive. Remove
  the disk from the Disk II drive. Hold Solid-Apple and drag a file to
  another volume to move it. When prompted to insert the disk, click
  Cancel. Verify that when the window closes the disk icon is no
  longer dimmed.
]]
