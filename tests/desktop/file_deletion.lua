--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv -flop1 floppy_with_files.dsk"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]

--[[
  Launch DeskTop. Open two windows. Select a file in one window.
  Activate the other window by clicking its title bar. File > Delete.
  Click OK. Verify that the window with the deleted file refreshes.
]]
test.Step(
  "Window with deleted file refreshes",
  function()
    -- Create file to delete, and remember icon position
    desktop.SelectPath("/RAM1")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    desktop.CreateFolder("/RAM1/FILE")

    -- Open other window, remember coords
    desktop.OpenWindow("/A2.DESKTOP")
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    -- Get second window open and visible
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
    end)
    desktop.MoveWindowBy(0,100)
    desktop.SelectAll()

    -- Activate other window by clicking on title bar
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
        a2dtest.WaitForSystemTask()
    end)

    a2dtest.DHRDarkness()
    desktop.DeleteSelection()
    test.Snap("verify RAM1 window refreshes")
end)

--[[
  Launch DeskTop. Open a window. Create folders A, B and C. Drag B
  onto C. Drag A to the trash. Click OK in the delete confirmation
  dialog. Verify that after the deletion, no alerts appear and volume
  icons can still be selected.
]]
test.Step(
  "Volume selection after deletion",
  function()
    desktop.SelectPath("/A2.DESKTOP")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1")
    desktop.GrowWindowBy(200, 0)
    desktop.CreateFolder("A")
    desktop.CreateFolder("B")
    desktop.CreateFolder("C")

    desktop.Select("A")
    local a_x, a_y = a2dtest.GetSelectedIconCoords()
    desktop.Select("B")
    local b_x, b_y = a2dtest.GetSelectedIconCoords()
    desktop.Select("C")
    local c_x, c_y = a2dtest.GetSelectedIconCoords()

    desktop.ClearSelection()

    a2d.Drag(b_x, b_y, c_x, c_y)
    a2dtest.WaitForSystemTask()

    a2d.Drag(a_x, a_y, trash_x, trash_y)
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectAlertNotShowing()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_x, vol_y)
        m.Click()
    end)
    local x, y = a2dtest.GetSelectedIconCoords()
    test.ExpectEquals(x, vol_x, "vol icon should be selected")
    test.ExpectEquals(y, vol_y, "vol icon should be selected")

    desktop.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a window. Create folders A and B. Drag B onto
  A. Drag A to the trash. Verify that the confirmation dialog counts 2
  files. Click OK. Verify that the count stops at 0, and does not wrap
  to 65,535.
]]
test.Step(
  "Deletion count",
  function()
    desktop.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1")
    desktop.GrowWindowBy(200, 0)
    desktop.CreateFolder("A")
    desktop.CreateFolder("B")

    desktop.Select("A")
    local a_x, a_y = a2dtest.GetSelectedIconCoords()
    desktop.Select("B")
    local b_x, b_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(b_x, b_y, a_x, a_y)

    a2d.Drag(a_x, a_y, trash_x, trash_y)
    a2dtest.WaitForAlert({match="delete 2 files%?"})
    a2d.DialogOK({no_wait=true})
    a2dtest.VerifyFilesRemainingCountdown(30, "deletion")

    desktop.EraseVolume("RAM1")
end)


--[[
  Launch DeskTop. Open a volume window. Create a folder. Open the
  folder's window. Go back to the volume window, and drag the folder
  icon to the trash. Click OK in the delete confirmation dialog.
  Verify that the folder's window closes.
]]
test.Step(
  "Window closed if folder deleted via trash",
  function()
    desktop.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1")
    desktop.CreateFolder("F")
    desktop.SelectAndOpen("F")

    desktop.CycleWindows()

    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, trash_x, trash_y)
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "folder window should have closed")
end)

--[[
  Launch DeskTop. Open a volume window. Create a folder. Open the
  folder's window. Activate the folder's parent window and select the
  folder icon. File > Delete. Click OK in the delete confirmation
  dialog. Verify that the folder's window closes.
]]
test.Step(
  "Window closed if folder deleted via menu",
  function()
    desktop.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1")
    desktop.CreateFolder("F")
    desktop.SelectAndOpen("F")

    desktop.CycleWindows()

    a2d.OADelete()
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "folder window should have closed")
end)

--[[
   Open `/TESTS/DELETION`. Select `X`. File > Delete. Verify that a
   prompt is shown for deleting each file in deepest-first order (B,
   Z, Y, X). Click Yes at each prompt. Verify that all files are
   deleted.
]]
test.Step(
  "Nested file prompts",
  function()
    desktop.SelectPath("/TESTS/DELETION/X")
    a2d.OADelete()
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()

    a2dtest.WaitForAlert({match="file is locked"})
    test.ExpectMatch(a2dtest.OCRScreen(), "File: .*/DELETION/X/Y/Z/B", "prompt should be for B")
    apple2.Type("Y")
    a2dtest.WaitForSystemTask()

    a2dtest.WaitForAlert({match="file is locked"})
    test.ExpectMatch(a2dtest.OCRScreen(), "File: .*/DELETION/X/Y/Z", "prompt should be for Z")
    apple2.Type("Y")
    a2dtest.WaitForSystemTask()

    a2dtest.WaitForAlert({match="file is locked"})
    test.ExpectMatch(a2dtest.OCRScreen(), "File: .*/DELETION/X/Y", "prompt should be for Y")
    apple2.Type("Y")
    a2dtest.WaitForSystemTask()

    a2dtest.WaitForAlert({match="file is locked"})
    test.ExpectMatch(a2dtest.OCRScreen(), "File: .*/DELETION/X", "prompt should be for X")
    apple2.Type("Y")
    a2dtest.WaitForSystemTask()

    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 0, "all files should be deleted")
end)

--[[
  Load DeskTop. Open a window for a volume in a Disk II drive. Remove
  the disk from the Disk II drive. Drag a file to the trash. When
  prompted to insert the disk, click Cancel. Verify that selection
  is unchanged.
]]
test.Step(
  "Ejected disk - before enumeration",
  function()
    desktop.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    -- Open window
    desktop.SelectPath("/WITH.FILES/LOREM.IPSUM")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    -- Eject disk
    local current = s6d1.filename
    s6d1:unload()

    -- Drag to trash
    a2d.Drag(icon_x, icon_y, trash_x, trash_y)
    a2dtest.WaitForAlert({match="Insert the disk"})
    a2d.DialogCancel() -- insert disk
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "LOREM.IPSUM", "clicked icon should be selected")

    s6d1:load(current)
end)
--[[
  Load DeskTop. Open a window for a volume in a Disk II drive. Drag a
  file to the trash. Remove the disk from the Disk II drive. Click OK
  to confirm the deletion. When prompted to insert the disk, click
  Cancel. Verify that when the window closes the disk icon is no
  longer dimmed.
]]
test.Step(
  "Ejected disk - after enumeration",
  function()
    desktop.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    -- Open window
    desktop.SelectPath("/WITH.FILES/LOREM.IPSUM")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    -- Drag to trash
    a2d.Drag(icon_x, icon_y, trash_x, trash_y)
    a2dtest.WaitForAlert({match="Are you sure"})

    -- Eject disk
    local current = s6d1.filename
    s6d1:unload()

    a2d.DialogOK() -- confirm
    a2dtest.WaitForSystemTask()

    a2dtest.WaitForAlert({match="Insert the disk"})
    a2d.DialogCancel()
    a2dtest.WaitForSystemTask()

    a2dtest.WaitForAlert({match="volume cannot be found"})
    a2d.DialogOK() -- OK
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "WITH.FILES", "clicked icon should be selected")
    test.Expect(not desktop.GetSelectedIcons()[1].dimmed, "selected icon should not be dimmed")

    s6d1:load(current)
end)
