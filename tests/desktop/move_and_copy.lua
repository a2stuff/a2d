--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl5 ramfactor -sl6 superdrive -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/floppy_with_files.2mg"

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

    a2d.Drag(src_x, src_y, dst_x, dst_y)
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

    a2d.Drag(src_x, src_y, dst_x, dst_y)
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

    a2d.Drag(src_x, src_y, dst_x, dst_y)
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

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
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

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
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

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
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

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.Drag(src_x, src_y, dst_x, dst_y)
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

    a2d.Drag(src_x, src_y, dst_x, dst_y)
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
    {"Moving count is accurate", "move"},
    {"Copying count is accurate", "copy"},
  },
  function(idx, name, action)
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

        if action == "move" then
          m.ButtonUp()
        else
          apple2.PressSA()
          m.ButtonUp()
          apple2.ReleaseSA()
        end

    end)
    emu.wait(0.25)

    if action == "move" then
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
test.Step(
  "copy multiple files and folder to another volume",
  function()
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.CopyPath("/A2.DESKTOP/DESKTOP.SYSTEM", "/RAM1/FOLDER")

    a2d.SelectPath("/RAM5")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/RAM1")
    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.SelectAll()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(0.25)
    test.Snap("verify Copying 3 files")
    emu.wait(5)

    a2d.SelectPath("/RAM1/READ.ME")
    a2d.SelectPath("/RAM1/FOLDER")
    a2d.SelectPath("/RAM1/FOLDER/DESKTOP.SYSTEM")
    a2d.SelectPath("/RAM5/READ.ME")
    a2d.SelectPath("/RAM5/FOLDER")
    a2d.SelectPath("/RAM5/FOLDER/DESKTOP.SYSTEM")

    a2d.EraseVolume("/RAM1")
    a2d.EraseVolume("/RAM5")
end)

--[[
  Select a volume icon. Hold Solid-Apple and drag the volume icon to
  another volume icon or window from another volume. Verify that the
  progress dialog shows "Copying" and that the number of files listed
  matches the number of files in the volume plus one.
]]
test.Step(
  "dragging volume icon with Solid-Apple",
  function()
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.CopyPath("/A2.DESKTOP/DESKTOP.SYSTEM", "/RAM1/FOLDER")

    a2d.SelectPath("/RAM1")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM5")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
    emu.wait(0.25)
    test.Snap("verify Copying 4 files") -- vol becomes folder, makes it +1
    emu.wait(5)

    a2d.SelectPath("/RAM1/READ.ME")
    a2d.SelectPath("/RAM1/FOLDER")
    a2d.SelectPath("/RAM1/FOLDER/DESKTOP.SYSTEM")

    a2d.OpenPath("/RAM5")
    a2d.OpenPath("/RAM5/RAM1")
    emu.wait(1)
    a2d.SelectPath("/RAM5/RAM1/READ.ME")
    a2d.SelectPath("/RAM5/RAM1/FOLDER")
    a2d.SelectPath("/RAM5/RAM1/FOLDER/DESKTOP.SYSTEM")

    a2d.EraseVolume("/RAM1")
    a2d.EraseVolume("/RAM5")
end)

--[[
  Launch DeskTop. Open a window. File > New Folder, enter name. Copy
  the file to another folder or volume. Verify that the "Files
  remaining" count bottoms out at 0.
]]
test.Step(
  "copy new folder progress bottoms out at 0",
  function()
    a2d.OpenPath("/RAM1")
    a2d.CreateFolder("FOLDER")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM5", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.MultiSnap(60, "verify copy count ends at 0")

    a2d.EraseVolume("/RAM1")
    a2d.EraseVolume("/RAM5")
end)


--[[
  Launch DeskTop. Open a window. File > New Folder, enter name. Move
  the file to another folder or volume. Verify that the "Files
  remaining" count bottoms out at 0.
]]
test.Step(
  "move new folder progress bottoms out at 0",
  function()
    a2d.OpenPath("/RAM1")
    a2d.CreateFolder("FOLDER")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM5", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y,dst_x, dst_y, {sa_drop=true})
    a2dtest.MultiSnap(60, "verify move count ends at 0")

    a2d.EraseVolume("/RAM1")
    a2d.EraseVolume("/RAM5")
end)

--[[
  Launch DeskTop. Copy multiple selected files to another volume.
  Repeat the copy. When prompted to overwrite, alternate clicking Yes
  and No. Verify that the "Files remaining" count decreases to zero.
]]
test.Step(
  "copy progress ends at 0 even if files skipped",
  function()
    a2d.CopyPath("/A2.DESKTOP/APPLE.MENU/TOYS/BOUNCE", "/RAM1")
    a2d.CopyPath("/A2.DESKTOP/APPLE.MENU/TOYS/EYES", "/RAM1")
    a2d.CopyPath("/A2.DESKTOP/APPLE.MENU/TOYS/LIGHTS.OUT", "/RAM1")
    a2d.CopyPath("/A2.DESKTOP/APPLE.MENU/TOYS/NEKO", "/RAM1")
    a2d.CopyPath("/A2.DESKTOP/APPLE.MENU/TOYS/PUZZLE", "/RAM1")

    a2d.SelectPath("/RAM5")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(5)

    -- Now copy again
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    apple2.Type("Y")
    a2d.WaitForRepaint()
    a2dtest.WaitForAlert()
    apple2.Type("N")
    a2d.WaitForRepaint()
    a2dtest.WaitForAlert()
    apple2.Type("Y")
    a2d.WaitForRepaint()
    a2dtest.WaitForAlert()
    apple2.Type("N")
    a2d.WaitForRepaint()
    a2dtest.WaitForAlert()
    apple2.Type("Y")
    a2dtest.MultiSnap(60, "verify count ends at 0")

    a2d.EraseVolume("/RAM1")
    a2d.EraseVolume("/RAM5")
end)

--[[
  Load DeskTop. Create a folder e.g. `/RAM/F`. Try to copy the folder
  into itself using File > Copy To.... Verify that an error is shown.
]]
test.Step(
  "Error copying folder into itself using File > Copy To",
  function()
    a2d.CreateFolder("/RAM1/F")
    a2d.CopyPath("/RAM1/F", "/RAM1/F")
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.EraseVolume("/RAM1")
end)

--[[
  Load DeskTop. Create a folder e.g. `/RAM/F`. Open the containing
  window, and the folder itself. Try to move it into itself by
  dragging. Verify that an error is shown.
]]
test.Step(
  "Error moving folder into itself using drag/drop",
  function()
    a2d.CreateFolder("/RAM1/F")

    a2d.OpenPath("/RAM1/F")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.SelectPath("/RAM1/F", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.EraseVolume("/RAM1")
end)

--[[
  Load DeskTop. Create a folder e.g. `/RAM/F`, and a sibling folder
  e.g. `/RAM/B`. Open the containing window, and the first folder
  itself. Select both folders, and try to move both into the first
  folder's window by dragging. Verify that an error is shown before
  any moves occur.
]]
test.Step(
  "Invalid move into self stopped before anything actually happens",
  function()
    a2d.CreateFolder("/RAM1/F")
    a2d.CreateFolder("/RAM1/B")

    a2d.OpenPath("/RAM1/F")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    a2d.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)

    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.SelectPath("/RAM1/F")
    a2d.SelectPath("/RAM1/B")
    a2d.OpenPath("/RAM1/F")
    test.Expect(#a2d.GetSelectedIcons(), 0, "no files should be moved")

    a2d.EraseVolume("/RAM1")
end)

--[[
  Load DeskTop. Create a folder e.g. `/RAM/F`. Open the containing
  window, and the folder itself. Try to copy it into itself by
  dragging with an Apple key depressed. Verify that an error is shown.
]]
test.Step(
  "Error copying folder into itself using drag/drop",
  function()
    a2d.CreateFolder("/RAM1/F")

    a2d.OpenPath("/RAM1/F")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.SelectPath("/RAM1/F", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.EraseVolume("/RAM1")
end)

--[[
  Load DeskTop. Open a volume window. Drag a file icon from the volume
  window to the volume icon. Verify that an error is shown.
]]
test.Step(
  "Error dragging file onto its own volume",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/A2.DESKTOP", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    a2d.DialogOK()
end)

--[[
  Load DeskTop. Create a folder, and a file within the folder with the
  same name as the folder (e.g. `/RAM/F` and `/RAM/F/F`). Try to copy
  the file over the folder using File > Copy To.... Verify that an
  error is shown.
]]
test.Step(
  "Error copying file over ancestor using File > Copy To",
  function()
    a2d.CreateFolder("/RAM1/F")
    a2d.CreateFolder("/RAM1/F/F")
    a2d.CopyPath("/RAM1/F/F", "/RAM1")
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.EraseVolume("/RAM1")
end)

--[[
  Load DeskTop. Create a folder, and a file within the folder with the
  same name as the folder (e.g. `/RAM/F` and `/RAM/F/F`). Try to move
  the file over the folder using drag and drop. Verify that an error
  is shown.
]]
test.Step(
  "Error copying file over ancestor using drag/drop",
  function()
    a2d.CreateFolder("/RAM1/F")
    a2d.CreateFolder("/RAM1/F/F")

    a2d.SelectPath("/RAM1/F/F")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM1", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.EraseVolume("/RAM1")
end)

--[[
  Load DeskTop. Create a folder, and a file within the folder with the
  same name as the folder, and another file (e.g. `/RAM/F` and
  `/RAM/F/F` and `/RAM/F/B`). Select both files and try to move them
  into the parent folder using drag and drop. Verify that an error is
  shown before any files are moved.
]]
test.Step(
  "Invalid move over ancestor stopped  before anything actually happens",
  function()
    a2d.CreateFolder("/RAM1/F")
    a2d.CreateFolder("/RAM1/F/F")
    a2d.CreateFolder("/RAM1/F/B")

    a2d.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/RAM1/F")
    a2d.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.SelectPath("/RAM1/F/F")
    a2d.SelectPath("/RAM1/F/B")
    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    test.Expect(#a2d.GetSelectedIcons(), 1, "no files should be moved")

    a2d.EraseVolume("/RAM1")
end)

--[[
  Load DeskTop. Create a folder on a volume. Create a non-folder file
  with the same name as the folder on a second volume. Drag the folder
  to the second volume. When prompted to overwrite, click Yes. Verify
  that the volume contains a folder of the appropriate name.
]]
test.Step(
  "Overwrite file with empty folder",
  function()
    a2d.CreateFolder("/RAM1/NAME")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM5")
    a2d.RenamePath("/RAM5/READ.ME", "NAME")

    a2d.SelectPath("/RAM1/NAME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM5", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert() -- overwrite?
    apple2.Type("Y")
    emu.wait(5)

    a2d.OpenPath("/RAM5/NAME") -- copy exists
    a2d.SelectPath("/RAM1/NAME") -- original exists

    a2d.EraseVolume("/RAM1")
    a2d.EraseVolume("/RAM5")
end)

--[[
  Load DeskTop. Create a folder on a volume, containing a non-folder
  file. Create a non-folder file with the same name as the folder on a
  second volume. Drag the folder to the second volume. When prompted
  to overwrite, click Yes. Verify that the volume contains a folder of
  the appropriate name, containing a non-folder file.
]]
test.Step(
  "Error overwriting file with non-empty folder",
  function()
    a2d.CreateFolder("/RAM1/NAME")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1/NAME")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM5")
    a2d.RenamePath("/RAM5/READ.ME", "NAME")

    a2d.SelectPath("/RAM1/NAME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM5", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert() -- overwrite?
    apple2.Type("Y")
    emu.wait(5)

    a2d.SelectPath("/RAM5/NAME/READ.ME") -- copy exists
    a2d.SelectPath("/RAM1/NAME/READ.ME") -- original exists

    a2d.EraseVolume("/RAM1")
    a2d.EraseVolume("/RAM5")
end)

--[[
  Load DeskTop. Create a non-folder file on a volume. Create a folder
  with the same name as the file on a second volume. Drag the file
  onto the second volume. Verify that an alert is shown about
  overwriting a directory.
]]
test.Step(
  "Error overwriting folder with file",
  function()
    a2d.CreateFolder("/RAM1/READ.ME")

    a2d.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Use File > Copy To... to copy a file. Verify that
  the file is indeed copied, not moved.
]]
test.Step(
  "Copy actually copies",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/A2.DESKTOP/EXTRAS")
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.SelectPath("/A2.DESKTOP/EXTRAS/READ.ME")
    a2d.DeletePath("/A2.DESKTOP/EXTRAS/READ.ME")
end)

--[[
  Launch DeskTop. Drag a file icon to a same-volume window so it is
  moved, not copied. Use File > Copy To... to copy a file. Verify that
  the file is indeed copied, not moved.
]]
test.Step(
  "Copy actually copies, even after a move",
  function()
    a2d.CreateFolder("/RAM1/A")
    a2d.CreateFolder("/RAM1/B")
    a2d.OpenPath("/RAM1")
    a2d.Select("B")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.Select("A")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(1)
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "file should have moved")

    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/A2.DESKTOP/EXTRAS")
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.SelectPath("/A2.DESKTOP/EXTRAS/READ.ME")
    a2d.DeletePath("/A2.DESKTOP/EXTRAS/READ.ME")

    a2d.EraseVolume("RAM1")
end)

--[[For the following cases, open `/TESTS` and `/TESTS/FOLDER`:]]

-- NOTE: Using RAM1 instead of TESTS for easier reset

--[[
  Drag a file icon from another volume onto the `TESTS` icon. Verify
  that the `TESTS` window activates and refreshes, and that the
  `TESTS` window's used/free numbers update. Click on the `FOLDER`
  window. Verify that the `FOLDER` window's used/free numbers update.

  Drag a file icon from another volume onto the `TESTS` window. Verify
  that the `TESTS` window activates and refreshes, and that the
  `TESTS` window's item count/used/free numbers update. Click on the
  `FOLDER` window. Verify that the `FOLDER` window's used/free numbers
  update.

  Copy a file from another volume to the `TESTS` icon using File >
  Copy To.... Verify that the `TESTS` window activates and refreshes,
  and that the `TESTS` window's item count/used/free numbers update.
  Click on the `FOLDER` window. Verify that the `FOLDER` window's
  used/free numbers update.
]]
test.Variants(
  {
    {"Same-volume child window updates when activated - drag to icon", "icon"},
    {"Same-volume child window updates when activated - drag to window", "window"},
    {"Same-volume child window updates when activated - File > Copy To", nil},
  },
  function(idx, name, target)
    a2d.CreateFolder("/RAM1/FOLDER")
    local dst_x, dst_y
    if target == "icon" then
      a2d.SelectPath("/RAM1")
      dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    end

    a2d.OpenPath("/RAM1/FOLDER")
    a2d.MoveWindowBy(200, 100)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    if target == "window" then
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()
      dst_x, dst_y = x + w / 2, y + h / 2
    end

    a2d.OpenPath("/A2.DESKTOP", {keep_windows=true})
    a2d.GrowWindowBy(-100, -100)
    a2d.Select("READ.ME")
    test.Snap("note RAM1 and FOLDER used/free numbers")

    if target ~= nil then
      local src_x, src_y = a2dtest.GetSelectedIconCoords()
      a2d.Drag(src_x, src_y, dst_x, dst_y)
    else
      a2d.CopySelectionTo("/RAM1")
    end
    emu.wait(1)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
    test.Snap("verify RAM1 used/free numbers updated")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
    end)
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")
    test.Snap("verify FOLDER used/free numbers updated")

    a2d.EraseVolume("RAM1")
end)


--[[
  Drag a file icon from another volume onto the `FOLDER` window.
  Verify that the `FOLDER` window activates and refreshes, and that
  the `FOLDER` window's item count/used/free numbers update. Click on
  the `TESTS` window. Verify that the `TESTS` window's used/free
  numbers update.

  Copy file from another volume to `/TESTS/FOLDER` using File > Copy
  File.... Verify that the `FOLDER` window activates and refreshes,
  and that the `FOLDER` window's item count/used/free numbers update.
  Click on the `TESTS` window. Verify that the `TESTS` window's
  used/free numbers update.
]]
test.Variants(
  {
    {"Same-volume parent window updates when activated - drag to window", true},
    {"Same-volume parent window updates when activated - File > Copy To", false},
  },
  function(idx, name, drag)
    a2d.CreateFolder("/RAM1/FOLDER")

    a2d.OpenPath("/RAM1/FOLDER")
    a2d.MoveWindowBy(200, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    a2d.OpenPath("/A2.DESKTOP", {keep_windows=true})
    a2d.GrowWindowBy(-100, -100)
    a2d.Select("READ.ME")
    test.Snap("note RAM1 and FOLDER used/free numbers")

    if drag then
      local src_x, src_y = a2dtest.GetSelectedIconCoords()
      a2d.Drag(src_x, src_y, dst_x, dst_y)
    else
      a2d.CopySelectionTo("/RAM1/FOLDER")
    end
    emu.wait(1)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")
    test.Snap("verify FOLDER used/free numbers updated")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
    end)
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
    test.Snap("verify RAM1 used/free numbers updated")

    a2d.EraseVolume("RAM1")
end)

--[[
  Drag a file icon from the `TESTS` window to the trash. Verify that
  the `TESTS` window refreshes, and that the `TESTS` window's item
  count/used/free numbers update. Click on the `FOLDER` window. Verify
  that the `FOLDER` window's used/free numbers update.

  Delete a file from the `TESTS` window using File > Delete. Verify
  that the `TESTS` window refreshes, and that the `TESTS` window's
  item count/used/free numbers update. Click on the `FOLDER` window.
  Verify that the `FOLDER` window's used/free numbers update.
]]
test.Variants(
  {
    {"Same-volume child window updates when activated - drag to trash", true},
    {"Same-volume child window updates when activated - File > Delete", false},
  },
  function(idx, name, drag)
    a2d.SelectPath("/Trash")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")

    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.OpenPath("/RAM1/FOLDER")
    a2d.MoveWindowBy(200, 100)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)

    a2d.Select("READ.ME")
    test.Snap("note RAM1 and FOLDER used/free numbers")

    if drag then
      local src_x, src_y = a2dtest.GetSelectedIconCoords()
      a2d.Drag(src_x, src_y, dst_x, dst_y)
      a2dtest.WaitForAlert()
      a2d.DialogOK()
    else
      a2d.DeleteSelection()
    end
    emu.wait(1)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
    test.Snap("verify RAM1 used/free numbers updated")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
    end)
    test.Snap("verify FOLDER used/free numbers updated")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")

    a2d.EraseVolume("RAM1")
end)

--[[
  Drag a file icon from the `FOLDER` window to the trash. Verify that
  the `FOLDER` window refreshes, and that the `FOLDER` window's item
  count/used/free numbers update. Click on the `TESTS` window. Verify
  that the `TESTS` window's used/free numbers update.

  Delete a file from the `FOLDER` window using File > Delete. Verify
  that the `FOLDER` window refreshes, and that the `FOLDER` window's
  item count/used/free numbers update. Click on the `TESTS` window.
  Verify that the `TESTS` window's used/free numbers update.
]]
test.Variants(
  {
    {"Same-volume parent window updates when activated - drag to trash", true},
    {"Same-volume parent window updates when activated - File > Delete", false},
  },
  function(idx, name, drag)
    a2d.SelectPath("/Trash")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1/FOLDER")

    a2d.OpenPath("/RAM1/FOLDER")
    a2d.MoveWindowBy(200, 100)

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    a2d.CycleWindows()
    a2d.Select("READ.ME")
    test.Snap("note RAM1 used/free numbers")

    if drag then
      local src_x, src_y = a2dtest.GetSelectedIconCoords()
      a2d.Drag(src_x, src_y, dst_x, dst_y)
      a2dtest.WaitForAlert()
      a2d.DialogOK()
    else
      a2d.DeleteSelection()
    end
    emu.wait(1)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")
    test.Snap("verify FOLDER used/free numbers updated")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
    end)
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
    test.Snap("verify RAM1 used/free numbers updated")

    a2d.EraseVolume("RAM1")
end)

--[[
  Duplicate a file in the `FOLDER` window using File > Duplicate.
  Verify that the `FOLDER` window refreshes, and that the `FOLDER`
  window's item count/used/free numbers update. Click on the `TESTS`
  window. Verify that the `TESTS` window's used/free numbers update.
]]
test.Step(
  "Same-volume child window updates when activated - Duplicate",
  function()
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1/FOLDER")

    a2d.OpenPath("/RAM1/FOLDER")
    a2d.MoveWindowBy(200, 100)

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    a2d.CycleWindows()
    a2d.Select("READ.ME")
    test.Snap("note RAM1 and FOLDER used/free numbers")

    a2d.DuplicateSelection("DUPE")
    emu.wait(1)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")
    test.Snap("verify FOLDER used/free numbers updated")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
    end)
    test.Snap("verify RAM1 used/free numbers updated")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")

    a2d.EraseVolume("RAM1")
end)

--[[
  Drag a file icon in the `TESTS` window onto the `FOLDER` icon while
  holding Apple to copy it. Verify that the `FOLDER` window activates
  and refreshes, and that the `FOLDER` window's item count/used/free
  numbers update. Click on the `TESTS` window. Verify that the `TESTS`
  window's used/free numbers update.

  Drag a file icon in the `TESTS` window onto the `FOLDER` window
  while holding Apple to copy it. Verify that the `FOLDER` window
  activates and refreshes, and that the `FOLDER` window's item
  count/used/free numbers update. Click on the `TESTS` window. Verify
  that the `TESTS` window's used/free numbers update.
]]
test.Variants(
  {
    {"Same-volume child window updates when activated - copy - drag to icon", "icon"},
    {"Same-volume child window updates when activated - copy - drag to window", "window"},
  },
  function(idx, name, target)
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")

    local dst_x, dst_y
    a2d.OpenPath("/RAM1/FOLDER")
    a2d.MoveWindowBy(200, 100)
    if target == "window" then
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()
      dst_x, dst_y = x + w / 2, y + h / 2
    end

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    a2d.Select("FOLDER")
    if target == "icon" then
      dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    end

    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    test.Snap("note RAM1 and FOLDER used/free numbers")

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
    emu.wait(1)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")
    test.Snap("verify FOLDER used/free numbers updated")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "file should be copied")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
    end)
    test.Snap("verify RAM1 used/free numbers updated")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "file should be copied")

    a2d.EraseVolume("RAM1")
end)


--[[
  Repeat the following in an active and inactive window. In the
  inactive window case, verify that at the end of the test that the
  window is activated.
]]
function ActiveInactiveTest(name, func1, func2)
  test.Variants(
    {
      {name .. " - active", true},
      {name .. " - inactive", false},
    },
    function(idx, name, active)
      a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
      a2d.CopyPath("/A2.DESKTOP/PRODOS", "/RAM1")
      a2d.CloseAllWindows()

      if not active then
        a2d.OpenPath("/RAM5")
        a2d.MoveWindowBy(0, 100)
      end

      local x, y = func1()

      if not active then
        a2d.CycleWindows()
      end

      func2(x, y)

      if not active then
        test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
      end

      a2d.EraseVolume("RAM1")
  end)
end

--[[
  * Drag a single file icon and drop it within the same window. Verify the icon is moved.
]]
ActiveInactiveTest(
  "Drag a single file icon and drop it within the same window",
  function()
    a2d.SelectPath("/RAM1/READ.ME", {keep_windows=true})
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    test.Snap("note icon position")
    a2d.Drag(x, y, x + 20, y + 10)
    emu.wait(1)
    test.Snap("verify icon was moved")
end)

--[[
  * Drag multiple file icons and drop them within the same window. Verify the icons are moved.
]]
ActiveInactiveTest(
  "Drag multiple file icons and drop them within the same window",
  function()
    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.SelectAll()
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    test.Snap("note icon positions")
    a2d.Drag(x, y, x + 20, y + 10)
    emu.wait(1)
    test.Snap("verify icons were moved")
end)

--[[
  * Drag a single file icon and drop it within the same window while holding either Open-Apple or Solid-Apple. Verify the icon is duplicated.
]]
ActiveInactiveTest(
  "Drag a single file icon and drop it within the same window w/ OA or SA",
  function()
    a2d.SelectPath("/RAM1/READ.ME", {keep_windows=true})
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    test.Snap("note icon position")
    a2d.Drag(x, y, x + 20, y + 10, {sa_drop=true})
    emu.wait(5)
    test.Snap("verify icon was duplicated")
    apple2.ReturnKey()
    emu.wait(1)
end)

--[[
  * Drag multiple file icons and drop them within the same window while holding either Open-Apple or Solid-Apple. Verify nothing happens.
]]
ActiveInactiveTest(
  "Drag multiple file icons and drop them within the same window w/ OA or SA",
  function()
    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.SelectAll()
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    test.Snap("note icon positions")
    a2d.Drag(x, y, x + 20, y + 10, {sa_drop=true})
    emu.wait(1)
    test.Snap("verify nothing changed (except activation)")
end)

--[[
  * Drag a single file icon and drop it within the same window while holding both Open-Apple and Solid-Apple. Verify that an alias is created.
]]
ActiveInactiveTest(
  "Drag a single file icon and drop it within the same window w/ OA + SA",
  function()
    a2d.SelectPath("/RAM1/READ.ME", {keep_windows=true})
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    test.Snap("note icon position")
    a2d.Drag(x, y, x + 20, y + 10, {oa_drop=true, sa_drop=true})
    emu.wait(5)

    test.Snap("verify an alias was created")
    -- BUG: Failing in inactive window - a duplicate is created

    apple2.ReturnKey()
    emu.wait(1)
end)

--[[
  * Drag multiple file icons and drop them within the same window while holding both Open-Apple and Solid-Apple. Verify nothing happens.
]]
ActiveInactiveTest(
  "Drag multiple file icons and drop them within the same window w/ OA + SA",
  function()
    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.SelectAll()
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    test.Snap("note icon positions")
    a2d.Drag(x, y, x + 20, y + 10, {oa_drop=true, sa_drop=true})
    emu.wait(1)
    test.Snap("verify nothing changed (except activation)")
end)

--[[
  Launch DeskTop. Drag a volume icon onto another volume icon (with
  sufficient capacity). Verify that no alert is shown. Repeat, but
  drag onto a volume window instead.
]]
test.Variants(
  {
    {"Drag volume to volume icon", "icon"},
    {"Drag volume to volume window", "window"},
  },
  function(idx, name, target)
    local dst_x, dst_y
    if target == "icon" then
      a2d.SelectPath("/RAM1")
      dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    else
      a2d.OpenPath("/RAM1")
      a2d.MoveWindowBy(0, 100)
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()
      dst_x, dst_y = x + w / 2, y + h / 2
    end

    a2d.SelectPath("/WITH.FILES", {keep_windows=true})
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(30)
    a2dtest.ExpectAlertNotShowing()

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open two windows containing multiple files. Select
  multiples files in the first window. File > Copy To.... Select the
  second window's location as a destination and click OK. During the
  initial count of the files, press Escape. Verify that the count is
  canceled and the progress dialog is closed, and that the second
  window's contents do not refresh.
]]
test.Step(
  "copy aborted during enumeration doesn't refresh target window",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0, 100)

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS", {keep_windows=true})
    a2d.SelectAll()
    a2dtest.DHRDarkness()
    a2d.CopySelectionTo("/RAM1", false, {no_wait=true})
    emu.wait(0.25)
    apple2.EscapeKey()
    emu.wait(5)
    test.Snap("verify RAM1 window did not refresh")

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Open two windows containing multiple files. Select
  multiples files in the first window. File > Copy To.... Select the
  second window's location as a destination and click OK. After the
  initial count of the files is complete and the actual operation has
  started, press Escape. Verify that the second window's contents do
  refresh.
]]
test.Step(
  "copy aborted after enumeration does refresh target window",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0, 100)

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS", {keep_windows=true})
    a2d.SelectAll()
    a2dtest.DHRDarkness()
    a2d.CopySelectionTo("/RAM1", false, {no_wait=true})
    emu.wait(2)
    apple2.EscapeKey()
    emu.wait(5)

    test.Snap("verify RAM1 window did refresh")

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Drag `/TESTS/EMPTY.FOLDER` to another volume. Verify
  that it is copied.
]]
test.Step(
  "Empty folders get copied too",
  function()
    a2d.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/TESTS/EMPTY.FOLDER")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(1)

    a2d.SelectPath("/RAM1/EMPTY.FOLDER")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)


--[[
  Launch DeskTop. Drag a file to another volume to copy it. Open the
  volume and select the newly copied file. File > Get Info. Check
  Locked and click OK. Drag a file with a different type but the same
  name to the volume. When prompted to overwrite, click Yes. Verify
  that the file was replaced.
]]
test.Step(
  "Overwriting locked files works",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.RenamePath("/RAM1/READ.ME", "PRODOS")

    a2d.SelectPath("/RAM1/PRODOS")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    apple2.ControlKey("L")
    a2d.DialogOK()

    a2d.SelectPath("/A2.DESKTOP/PRODOS")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM1", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    apple2.Type("Y")
    a2d.DialogOK()
    emu.wait(1)

    a2d.SelectPath("/RAM1/PRODOS")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

