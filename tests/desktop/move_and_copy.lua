--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl5 ramfactor -sl6 superdrive -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv -flop1 floppy_with_files.2mg"

======================================== ENDCONFIG ]]

--[[
  Move a file by dragging - same volume - target is window.
]]
test.Step(
  "Move a file by dragging - same volume - target is window",
  function()
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    test.Expect(#desktop.GetSelectedIcons(), 2, "should start with 2 files")

    desktop.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.Select("FOLDER")
    desktop.OpenSelection()
    desktop.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()

    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    test.Expect(#desktop.GetSelectedIcons(), 1, "file should have moved")
    desktop.SelectPath("/RAM1/FOLDER/READ.ME")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Move a file by dragging - same volume - target is volume icon.
]]
test.Step(
  "Move a file by dragging - same volume - target is volume icon",
  function()
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1/FOLDER")

    desktop.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1/FOLDER")
    desktop.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()

    desktop.OpenWindow("/RAM1/FOLDER")
    a2dtest.WaitForSystemTask()
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 0, "file should have moved")
    desktop.SelectPath("/RAM1/READ.ME")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Move a file by dragging - same volume - target is folder icon.
]]
test.Step(
  "Move a file by dragging - same volume - target is folder icon",
  function()
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.OpenWindow("/RAM1")

    desktop.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.Select("FOLDER")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()

    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "file should have moved")
    desktop.SelectPath("/RAM1/FOLDER/READ.ME")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Copy a file by dragging - same volume - target is window, holding
  Solid-Apple.
]]
test.Step(
  "Copy a file by dragging - same volume - target is window",
  function()
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    test.Expect(#desktop.GetSelectedIcons(), 2, "should start with 2 files")

    desktop.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.Select("FOLDER")
    desktop.OpenSelection()
    desktop.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
    a2dtest.WaitForSystemTask()

    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 2, "file should have copied")
    desktop.SelectPath("/RAM1/FOLDER/READ.ME")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Copy a file by dragging - same volume - target is volume icon,
  holding Solid-Apple.
]]
test.Step(
  "Copy a file by dragging - same volume - target is volume icon",
  function()
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1/FOLDER")

    desktop.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1/FOLDER")
    desktop.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
    a2dtest.WaitForSystemTask()

    desktop.OpenWindow("/RAM1/FOLDER")
    a2dtest.WaitForSystemTask()
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "file should have copied")
    desktop.SelectPath("/RAM1/READ.ME")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Copy a file by dragging - same volume - target is folder icon,
  holding Solid-Apple.
]]
test.Step(
  "Copy a file by dragging - same volume - target is folder icon",
  function()
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.OpenWindow("/RAM1")
    desktop.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    desktop.Select("FOLDER")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
    a2dtest.WaitForSystemTask()

    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 2, "file should have copied")
    desktop.SelectPath("/RAM1/FOLDER/READ.ME")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Copy a file by dragging - different volume - target is window.
]]
test.Step(
  "Copy a file by dragging - different volume - target is window",
  function()
    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()
    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    desktop.SelectPath("/RAM1/READ.ME")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Copy a file by dragging - different volume - target is volume icon.
]]
test.Step(
  "Copy a file by dragging - different volume - target is volume icon",
  function()
    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM1", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()

    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    desktop.SelectPath("/RAM1/READ.ME")

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.CreateFolder("/RAM1/SRC")
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.CopyPath("/A2.DESKTOP/PRODOS", "/RAM1/SRC")
    desktop.CopyPath("/A2.DESKTOP/DESKTOP.SYSTEM", "/RAM1/SRC")
    desktop.CreateFolder("/RAM1/DST")

    desktop.OpenWindow("/RAM1")
    desktop.Select("READ.ME")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    desktop.Select("SRC")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    desktop.Select("DST")
    local x3, y3 = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x1, y1)
        m.Click()
        m.MoveToApproximately(x2, y2)
        apple2.PressOA()
        m.Click()
        apple2.ReleaseOA()
        a2dtest.WaitForSystemTask()

        m.ButtonDown()
        m.MoveToApproximately(x3, y3)

        if action == "move" then
          m.ButtonUp()
        else
          apple2.PressSA()
          emu.wait(1) -- during keyboard/mouse operation
          m.ButtonUp()
          emu.wait(1) -- during keyboard/mouse operation
          apple2.ReleaseSA()
        end

    end)

    util.WaitFor(
      "done enumeration", function()
        return a2dtest.OCRFrontWindowContent():match("Files remaining")
    end)

    if action == "move" then
      test.ExpectMatch(a2dtest.OCRFrontWindowContent(), "Moving: 2 files", "correct count should be shown")
    else
      test.ExpectMatch(a2dtest.OCRFrontWindowContent(), "Copying: 4 files", "correct count should be shown")
    end

    a2dtest.WaitForSystemTask()

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.CopyPath("/A2.DESKTOP/DESKTOP.SYSTEM", "/RAM1/FOLDER")

    desktop.SelectPath("/RAM5")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1")
    desktop.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    desktop.SelectAll()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(0.25) -- during copy
    test.ExpectMatch(a2dtest.OCRScreen(), "Copying: 3 files", "correct count should be shown")
    a2dtest.WaitForSystemTask()

    desktop.SelectPath("/RAM1/READ.ME")
    desktop.SelectPath("/RAM1/FOLDER")
    desktop.SelectPath("/RAM1/FOLDER/DESKTOP.SYSTEM")
    desktop.SelectPath("/RAM5/READ.ME")
    desktop.SelectPath("/RAM5/FOLDER")
    desktop.SelectPath("/RAM5/FOLDER/DESKTOP.SYSTEM")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.EraseVolume("RAM5")
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
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.CopyPath("/A2.DESKTOP/DESKTOP.SYSTEM", "/RAM1/FOLDER")

    desktop.SelectPath("/RAM1")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM5")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
    emu.wait(0.25) -- during copy
    test.ExpectMatch(a2dtest.OCRScreen(), "Copying: 4 files", "correct count should be shown")
    -- vol becomes folder, makes it +1
    a2dtest.WaitForSystemTask()

    desktop.SelectPath("/RAM1/READ.ME")
    desktop.SelectPath("/RAM1/FOLDER")
    desktop.SelectPath("/RAM1/FOLDER/DESKTOP.SYSTEM")

    desktop.OpenWindow("/RAM5")
    desktop.OpenWindow("/RAM5/RAM1")
    a2dtest.WaitForSystemTask()
    desktop.SelectPath("/RAM5/RAM1/READ.ME")
    desktop.SelectPath("/RAM5/RAM1/FOLDER")
    desktop.SelectPath("/RAM5/RAM1/FOLDER/DESKTOP.SYSTEM")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.EraseVolume("RAM5")
end)

--[[
  Launch DeskTop. Open a window. File > New Folder, enter name. Copy
  the file to another folder or volume. Verify that the "Files
  remaining" count bottoms out at 0.
]]
test.Step(
  "copy new folder progress bottoms out at 0",
  function()
    desktop.OpenWindow("/RAM1")
    desktop.CreateFolder("FOLDER")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM5", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.VerifyFilesRemainingCountdown(60, "copy")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.EraseVolume("RAM5")
end)


--[[
  Launch DeskTop. Open a window. File > New Folder, enter name. Move
  the file to another folder or volume. Verify that the "Files
  remaining" count bottoms out at 0.
]]
test.Step(
  "move new folder progress bottoms out at 0",
  function()
    desktop.OpenWindow("/RAM1")
    desktop.CreateFolder("FOLDER")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM5", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y,dst_x, dst_y, {sa_drop=true})
    a2dtest.VerifyFilesRemainingCountdown(60, "move")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.EraseVolume("RAM5")
end)

--[[
  Launch DeskTop. Copy multiple selected files to another volume.
  Repeat the copy. When prompted to overwrite, alternate clicking Yes
  and No. Verify that the "Files remaining" count decreases to zero.
]]
test.Step(
  "copy progress ends at 0 even if files skipped",
  function()
    desktop.CopyPath("/A2.DESKTOP/APPLE.MENU/TOYS/BOUNCE", "/RAM1")
    desktop.CopyPath("/A2.DESKTOP/APPLE.MENU/TOYS/EYES", "/RAM1")
    desktop.CopyPath("/A2.DESKTOP/APPLE.MENU/TOYS/LIGHTS.OUT", "/RAM1")
    desktop.CopyPath("/A2.DESKTOP/APPLE.MENU/TOYS/NEKO", "/RAM1")
    desktop.CopyPath("/A2.DESKTOP/APPLE.MENU/TOYS/PUZZLE", "/RAM1")

    desktop.SelectPath("/RAM5")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()

    -- Now copy again
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match='already exists.*replace it%?'})
    apple2.Type("Y")
    a2dtest.WaitForSystemTask()
    a2dtest.WaitForAlert({match='already exists.*replace it%?'})
    apple2.Type("N")
    a2dtest.WaitForSystemTask()
    a2dtest.WaitForAlert({match='already exists.*replace it%?'})
    apple2.Type("Y")
    a2dtest.WaitForSystemTask()
    a2dtest.WaitForAlert({match='already exists.*replace it%?'})
    apple2.Type("N")
    a2dtest.WaitForSystemTask()
    a2dtest.WaitForAlert({match='already exists.*replace it%?'})
    apple2.Type("Y")
    a2dtest.VerifyFilesRemainingCountdown(60, "copy")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.EraseVolume("RAM5")
end)

--[[
  Load DeskTop. Create a folder e.g. `/RAM/F`. Try to copy the folder
  into itself using File > Copy To.... Verify that an error is shown.
]]
test.Step(
  "Error copying folder into itself using File > Copy To",
  function()
    desktop.CreateFolder("/RAM1/F")
    desktop.CopyPath("/RAM1/F", "/RAM1/F")
    a2dtest.WaitForAlert({match="into itself"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Load DeskTop. Create a folder e.g. `/RAM/F`. Open the containing
  window, and the folder itself. Try to move it into itself by
  dragging. Verify that an error is shown.
]]
test.Step(
  "Error moving folder into itself using drag/drop",
  function()
    desktop.CreateFolder("/RAM1/F")

    desktop.OpenWindow("/RAM1/F")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    desktop.SelectPath("/RAM1/F", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="into itself"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.CreateFolder("/RAM1/F")
    desktop.CreateFolder("/RAM1/B")

    desktop.OpenWindow("/RAM1/F")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    desktop.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)

    a2dtest.WaitForAlert({match="into itself"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    desktop.SelectPath("/RAM1/F")
    desktop.SelectPath("/RAM1/B")
    desktop.OpenWindow("/RAM1/F")
    test.Expect(#desktop.GetSelectedIcons(), 0, "no files should be moved")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Load DeskTop. Create a folder e.g. `/RAM/F`. Open the containing
  window, and the folder itself. Try to copy it into itself by
  dragging with an Apple key depressed. Verify that an error is shown.
]]
test.Step(
  "Error copying folder into itself using drag/drop",
  function()
    desktop.CreateFolder("/RAM1/F")

    desktop.OpenWindow("/RAM1/F")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    desktop.SelectPath("/RAM1/F", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
    a2dtest.WaitForAlert({match="into itself"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Load DeskTop. Open a volume window. Drag a file icon from the volume
  window to the volume icon. Verify that an error is shown.
]]
test.Step(
  "Error dragging file onto its own volume",
  function()
    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/A2.DESKTOP", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="by itself"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
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
    desktop.CreateFolder("/RAM1/F")
    desktop.CreateFolder("/RAM1/F/F")
    desktop.CopyPath("/RAM1/F/F", "/RAM1")
    a2dtest.WaitForAlert({match="by itself"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.CreateFolder("/RAM1/F")
    desktop.CreateFolder("/RAM1/F/F")

    desktop.SelectPath("/RAM1/F/F")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM1", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="by itself"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.CreateFolder("/RAM1/F")
    desktop.CreateFolder("/RAM1/F/F")
    desktop.CreateFolder("/RAM1/F/B")

    desktop.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1/F")
    desktop.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="by itself"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    desktop.SelectPath("/RAM1/F/F")
    desktop.SelectPath("/RAM1/F/B")
    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    test.Expect(#desktop.GetSelectedIcons(), 1, "no files should be moved")

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.CreateFolder("/RAM1/NAME")
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM5")
    desktop.RenamePath("/RAM5/READ.ME", "NAME")

    desktop.SelectPath("/RAM1/NAME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM5", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="already exists"})
    apple2.Type("Y")
    a2dtest.WaitForSystemTask()

    desktop.OpenWindow("/RAM5/NAME") -- copy exists
    desktop.SelectPath("/RAM1/NAME") -- original exists

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.EraseVolume("RAM5")
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
    desktop.CreateFolder("/RAM1/NAME")
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1/NAME")
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM5")
    desktop.RenamePath("/RAM5/READ.ME", "NAME")

    desktop.SelectPath("/RAM1/NAME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM5", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="already exists"})
    apple2.Type("Y")
    a2dtest.WaitForSystemTask()

    desktop.SelectPath("/RAM5/NAME/READ.ME") -- copy exists
    desktop.SelectPath("/RAM1/NAME/READ.ME") -- original exists

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.EraseVolume("RAM5")
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
    desktop.CreateFolder("/RAM1/READ.ME")

    desktop.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="folder cannot be replaced"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Use File > Copy To... to copy a file. Verify that
  the file is indeed copied, not moved.
]]
test.Step(
  "Copy actually copies",
  function()
    desktop.CopyPath("/A2.DESKTOP/PRODOS", "/A2.DESKTOP/EXTRAS")
    desktop.SelectPath("/A2.DESKTOP/PRODOS")
    desktop.SelectPath("/A2.DESKTOP/EXTRAS/PRODOS")
    desktop.DeletePath("/A2.DESKTOP/EXTRAS/PRODOS")
end)

--[[
  Launch DeskTop. Drag a file icon to a same-volume window so it is
  moved, not copied. Use File > Copy To... to copy a file. Verify that
  the file is indeed copied, not moved.
]]
test.Step(
  "Copy actually copies, even after a move",
  function()
    desktop.CreateFolder("/RAM1/A")
    desktop.CreateFolder("/RAM1/B")
    desktop.OpenWindow("/RAM1")
    desktop.Select("B")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    desktop.Select("A")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "file should have moved")

    desktop.CopyPath("/A2.DESKTOP/PRODOS", "/A2.DESKTOP/EXTRAS")
    desktop.SelectPath("/A2.DESKTOP/PRODOS")
    desktop.SelectPath("/A2.DESKTOP/EXTRAS/PRODOS")
    desktop.DeletePath("/A2.DESKTOP/EXTRAS/PRODOS")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[For the following cases, open `/TESTS` and `/TESTS/FOLDER`:]]

-- NOTE: Using RAM1 instead of TESTS for easier reset

function GetNumbers(ocr, index)
  for items, used, free in ocr:gmatch(
    "(%d+,?%d*) Items? +(%d+[.,]?%d*)K in disk +(%d+[.,]?%d*)K") do
    if index == 1 then
      return assert(items), assert(used), assert(free)
    end
    index = index - 1
  end
end

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
    desktop.CreateFolder("/RAM1/FOLDER")
    local dst_x, dst_y
    if target == "icon" then
      desktop.SelectPath("/RAM1")
      dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    end

    desktop.OpenWindow("/RAM1/FOLDER")
    desktop.MoveWindowBy(200, 120)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    if target == "window" then
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()
      dst_x, dst_y = x + w / 2, y + h / 2
    end

    desktop.OpenWindow("/A2.DESKTOP", {keep_windows=true})
    desktop.GrowWindowBy(-100, -100)
    desktop.Select("READ.ME")

    local ocr = a2dtest.OCRScreen()
    local ram1_items, ram1_used, ram1_free = GetNumbers(ocr, 2)
    local folder_items, folder_used, folder_free = GetNumbers(ocr, 3)

    if target ~= nil then
      local src_x, src_y = a2dtest.GetSelectedIconCoords()
      a2d.Drag(src_x, src_y, dst_x, dst_y)
    else
      desktop.CopySelectionTo("/RAM1")
    end
    a2dtest.WaitForSystemTask()

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 2)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 3)
    test.Expect(new_ram1_used ~= ram1_used and
                new_ram1_free ~= ram1_free, "RAM1 numbers should have updated")
    test.Expect(new_folder_used == folder_used and
                new_folder_free == folder_free, "FOLDER numbers should be the same")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
        m.MoveByApproximately(0, -20)
    end)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 2)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 3)
    test.Expect(new_folder_used ~= folder_used and
                new_folder_free ~= folder_free, "FOLDER numbers should have updated")

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.CreateFolder("/RAM1/FOLDER")

    desktop.OpenWindow("/RAM1/FOLDER")
    desktop.MoveWindowBy(200, 120)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    desktop.OpenWindow("/A2.DESKTOP", {keep_windows=true})
    desktop.GrowWindowBy(-100, -100)
    desktop.Select("READ.ME")

    local ocr = a2dtest.OCRScreen()
    local ram1_items, ram1_used, ram1_free = GetNumbers(ocr, 2)
    local folder_items, folder_used, folder_free = GetNumbers(ocr, 3)

    if drag then
      local src_x, src_y = a2dtest.GetSelectedIconCoords()
      a2d.Drag(src_x, src_y, dst_x, dst_y)
    else
      desktop.CopySelectionTo("/RAM1/FOLDER")
    end
    a2dtest.WaitForSystemTask()

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 2)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 3)
    test.Expect(new_ram1_used == ram1_used and
                new_ram1_free == ram1_free, "RAM1 numbers should be the same")
    test.Expect(new_folder_used ~= folder_used and
                new_folder_free ~= folder_free, "FOLDER numbers should have updated")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
        m.MoveByApproximately(0, -20)
    end)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 2)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 3)
    test.Expect(new_ram1_used ~= ram1_used and
                new_ram1_free ~= ram1_free, "RAM1 numbers should have updated")

    desktop.EraseVolume("RAM1")
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
    desktop.SelectPath("/Trash")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")

    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.OpenWindow("/RAM1/FOLDER")
    desktop.MoveWindowBy(200, 120)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)

    desktop.Select("READ.ME")

    local ocr = a2dtest.OCRScreen()
    local ram1_items, ram1_used, ram1_free = GetNumbers(ocr, 1)
    local folder_items, folder_used, folder_free = GetNumbers(ocr, 2)

    if drag then
      local src_x, src_y = a2dtest.GetSelectedIconCoords()
      a2d.Drag(src_x, src_y, dst_x, dst_y)
      a2dtest.WaitForAlert({match="Are you sure"})
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()
    else
      desktop.DeleteSelection()
    end

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 1)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 2)
    test.Expect(new_ram1_used ~= ram1_used and
                new_ram1_free ~= ram1_free, "RAM1 numbers should have updated")
    test.Expect(new_folder_used == folder_used and
                new_folder_free == folder_free, "FOLDER numbers should be the same")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
        m.MoveByApproximately(0, -20)
    end)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 1)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 2)
    test.Expect(new_folder_used ~= folder_used and
                new_folder_free ~= folder_free, "FOLDER numbers should have updated")

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.SelectPath("/Trash")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1/FOLDER")

    desktop.OpenWindow("/RAM1/FOLDER")
    desktop.MoveWindowBy(200, 120)

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    desktop.CycleWindows()
    desktop.Select("READ.ME")

    local ocr = a2dtest.OCRScreen()
    local ram1_items, ram1_used, ram1_free = GetNumbers(ocr, 1)
    local folder_items, folder_used, folder_free = GetNumbers(ocr, 2)

    if drag then
      local src_x, src_y = a2dtest.GetSelectedIconCoords()
      a2d.Drag(src_x, src_y, dst_x, dst_y)
      a2dtest.WaitForAlert({match="Are you sure"})
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()
    else
      desktop.DeleteSelection()
    end

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 1)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 2)
    test.Expect(new_folder_used ~= folder_used and
                new_folder_free ~= folder_free, "FOLDER numbers should have updated")
    test.Expect(new_ram1_used == ram1_used and
                new_ram1_free == ram1_free, "RAM1 numbers should be the same")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
        m.MoveByApproximately(0, -20)
    end)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 1)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 2)
    test.Expect(new_ram1_used ~= ram1_used and
                new_ram1_free ~= ram1_free, "RAM1 numbers should have updated")

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1/FOLDER")

    desktop.OpenWindow("/RAM1/FOLDER")
    desktop.MoveWindowBy(200, 120)

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    desktop.CycleWindows()
    desktop.Select("READ.ME")

    local ocr = a2dtest.OCRScreen()
    local ram1_items, ram1_used, ram1_free = GetNumbers(ocr, 1)
    local folder_items, folder_used, folder_free = GetNumbers(ocr, 2)

    desktop.DuplicateSelection("DUPE")
    a2dtest.WaitForSystemTask()

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 1)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 2)
    test.Expect(new_folder_used ~= folder_used and
                new_folder_free ~= folder_free, "FOLDER numbers should have updated")
    test.Expect(new_ram1_used == ram1_used and
                new_ram1_free == ram1_free, "RAM1 numbers should be the same")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
        m.MoveByApproximately(0, -20)
    end)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 1)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 2)
    test.Expect(new_ram1_used ~= ram1_used and
                new_ram1_free ~= ram1_free, "RAM1 numbers should have updated")

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")

    local dst_x, dst_y
    desktop.OpenWindow("/RAM1/FOLDER")
    desktop.MoveWindowBy(200, 120)
    if target == "window" then
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()
      dst_x, dst_y = x + w / 2, y + h / 2
    end

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    desktop.Select("FOLDER")
    if target == "icon" then
      dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    end

    desktop.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    local ocr = a2dtest.OCRScreen()
    local ram1_items, ram1_used, ram1_free = GetNumbers(ocr, 2)
    local folder_items, folder_used, folder_free = GetNumbers(ocr, 3)

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
    a2dtest.WaitForSystemTask()

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 1)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 2)
    test.Expect(new_folder_used ~= folder_used and
                new_folder_free ~= folder_free, "FOLDER numbers should have updated")
    test.Expect(new_ram1_used == ram1_used and
                new_ram1_free == ram1_free, "RAM1 numbers should be the same")

    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "file should be copied")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
        m.MoveByApproximately(0, -20)
    end)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
    local ocr = a2dtest.OCRScreen()
    local new_ram1_items, new_ram1_used, new_ram1_free = GetNumbers(ocr, 1)
    local new_folder_items, new_folder_used, new_folder_free = GetNumbers(ocr, 2)
    test.Expect(new_ram1_used ~= ram1_used and
                new_ram1_free ~= ram1_free, "RAM1 numbers should have updated")

    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 2, "file should be copied")

    -- cleanup
    desktop.EraseVolume("RAM1")
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
      desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
      desktop.CopyPath("/A2.DESKTOP/PRODOS", "/RAM1")
      desktop.CloseAllWindows()

      if not active then
        desktop.OpenWindow("/RAM5")
        desktop.MoveWindowBy(0, 100)
      end

      local x, y = func1()

      if not active then
        desktop.CycleWindows()
      end

      func2(x, y)

      if not active then
        test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "target should be activated")
      end

      -- cleanup
      desktop.EraseVolume("RAM1")
  end)
end

--[[
  * Drag a single file icon and drop it within the same window. Verify the icon is moved.
]]
ActiveInactiveTest(
  "Drag a single file icon and drop it within the same window",
  function()
    desktop.SelectPath("/RAM1/READ.ME", {keep_windows=true})
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    local before = desktop.GetSelectedIcons()
    test.ExpectEquals(#before, 1, "one icon should be selected")

    a2d.Drag(x, y, x + 20, y + 10)
    a2dtest.WaitForSystemTask()

    local after = desktop.GetSelectedIcons()
    test.ExpectEquals(#before, #after, "same icons should be selected")
    test.ExpectEquals(before[1].name, after[1].name, "same icon should be selected")
    test.ExpectNotEquals(before[1].x, after[1].x, "icon should have moved")
end)

--[[
  * Drag multiple file icons and drop them within the same window. Verify the icons are moved.
]]
ActiveInactiveTest(
  "Drag multiple file icons and drop them within the same window",
  function()
    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.SelectAll()
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    local before = desktop.GetSelectedIcons()
    test.ExpectEquals(#before, 2, "two icons should be selected")

    a2d.Drag(x, y, x + 20, y + 10)
    a2dtest.WaitForSystemTask()
    local after = desktop.GetSelectedIcons()
    test.ExpectEquals(#before, #after, "same icons should be selected")
    test.ExpectEquals(before[1].name, after[1].name, "same icon should be selected")
    test.ExpectEquals(before[2].name, after[2].name, "same icon should be selected")
    test.ExpectNotEquals(before[1].x, after[1].x, "icon should have moved")
    test.ExpectNotEquals(before[2].x, after[2].x, "icon should have moved")
end)

--[[
  * Drag a single file icon and drop it within the same window while holding either Open-Apple or Solid-Apple. Verify the icon is duplicated.
]]
ActiveInactiveTest(
  "Drag a single file icon and drop it within the same window w/ OA or SA",
  function()
    desktop.SelectPath("/RAM1/READ.ME", {keep_windows=true})
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    local before = desktop.GetSelectedIcons()
    test.ExpectEquals(#before, 1, "one icon should be selected")

    a2d.Drag(x, y, x + 20, y + 10, {sa_drop=true})
    a2dtest.WaitForSystemTask()

    local after = desktop.GetSelectedIcons()
    test.ExpectEquals(#after, 1, "one icon should be selected")
    test.ExpectNotEquals(before[1].name, after[1].name, "different icon should be selected")

    apple2.ReturnKey()
    a2dtest.WaitForSystemTask()
end)

--[[
  * Drag multiple file icons and drop them within the same window while holding either Open-Apple or Solid-Apple. Verify nothing happens.
]]
ActiveInactiveTest(
  "Drag multiple file icons and drop them within the same window w/ OA or SA",
  function()
    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.SelectAll()
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    local before = desktop.GetSelectedIcons()
    test.ExpectEquals(#before, 2, "two icons should be selected")

    a2d.Drag(x, y, x + 20, y + 10, {sa_drop=true})
    a2dtest.WaitForSystemTask()

    local after = desktop.GetSelectedIcons()
    test.ExpectEquals(#before, #after, "same icons should be selected")
    test.ExpectEquals(before[1].name, after[1].name, "same icon should be selected")
    test.ExpectEquals(before[2].name, after[2].name, "same icon should be selected")
    test.ExpectEquals(before[1].x, after[1].x, "icon should not have moved")
    test.ExpectEquals(before[2].x, after[2].x, "icon should not have moved")
end)

--[[
  * Drag a single file icon and drop it within the same window while holding both Open-Apple and Solid-Apple. Verify that an alias is created.
]]
ActiveInactiveTest(
  "Drag a single file icon and drop it within the same window w/ OA + SA",
  function()
    desktop.SelectPath("/RAM1/READ.ME", {keep_windows=true})
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    local before = desktop.GetSelectedIcons()
    test.ExpectEquals(#before, 1, "one icon should be selected")

    a2d.Drag(x, y, x + 20, y + 10, {oa_drop=true, sa_drop=true})
    a2dtest.WaitForSystemTask()

    local after = desktop.GetSelectedIcons()
    test.ExpectEquals(#after, 1, "one icon should be selected")
    test.ExpectNotEquals(before[1].name, after[1].name, "different icon should be selected")
    test.ExpectEquals(after[1].type, desktop.IconTypes.link, "new icon should be alias")

    apple2.ReturnKey()
    a2dtest.WaitForSystemTask()
end)

--[[
  * Drag multiple file icons and drop them within the same window while holding both Open-Apple and Solid-Apple. Verify nothing happens.
]]
ActiveInactiveTest(
  "Drag multiple file icons and drop them within the same window w/ OA + SA",
  function()
    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.SelectAll()
    return a2dtest.GetSelectedIconCoords()
  end,
  function(x, y)
    local before = desktop.GetSelectedIcons()
    test.ExpectEquals(#before, 2, "two icons should be selected")

    a2d.Drag(x, y, x + 20, y + 10, {oa_drop=true, sa_drop=true})
    a2dtest.WaitForSystemTask()

    local after = desktop.GetSelectedIcons()
    test.ExpectEquals(#before, #after, "same icons should be selected")
    test.ExpectEquals(before[1].name, after[1].name, "same icon should be selected")
    test.ExpectEquals(before[2].name, after[2].name, "same icon should be selected")
    test.ExpectEquals(before[1].x, after[1].x, "icon should not have moved")
    test.ExpectEquals(before[2].x, after[2].x, "icon should not have moved")
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
      desktop.SelectPath("/RAM1")
      dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    else
      desktop.OpenWindow("/RAM1")
      desktop.MoveWindowBy(0, 100)
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()
      dst_x, dst_y = x + w / 2, y + h / 2
    end

    desktop.SelectPath("/WITH.FILES", {keep_windows=true})
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectAlertNotShowing()

    -- cleanup
    desktop.EraseVolume("RAM1")
end)


--[[
  Launch DeskTop. Drag `/TESTS/EMPTY.FOLDER` to another volume. Verify
  that it is copied.
]]
test.Step(
  "Empty folders get copied too",
  function()
    desktop.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/TESTS/EMPTY.FOLDER")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()

    desktop.SelectPath("/RAM1/EMPTY.FOLDER")

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.RenamePath("/RAM1/READ.ME", "PRODOS")

    desktop.SelectPath("/RAM1/PRODOS")
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_GET_INFO)
    apple2.ControlKey("L")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    desktop.SelectPath("/A2.DESKTOP/PRODOS")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM1", {keep_windows=true})
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="already exists"})
    apple2.Type("Y")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    desktop.SelectPath("/RAM1/PRODOS")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

