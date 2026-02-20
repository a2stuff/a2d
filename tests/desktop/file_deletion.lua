--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv -flop1 floppy_with_files.dsk"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]

a2d.ConfigureRepaintTime(0.5)

--[[
  Launch DeskTop. Open two windows. Select a file in one window.
  Activate the other window by clicking its title bar. File > Delete.
  Click OK. Verify that the window with the deleted file refreshes.
]]
test.Step(
  "Window with deleted file refreshes",
  function()
    -- Create file to delete, and remember icon position
    a2d.SelectPath("/RAM1")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    a2d.CreateFolder("/RAM1/FILE")

    -- Open other window, remember coords
    a2d.OpenPath("/A2.DESKTOP")
    local click_x, click_y = a2dtest.GetFrontWindowDragCoords()

    -- Get second window open and visible
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
    end)
    a2d.MoveWindowBy(0,100)
    a2d.SelectAll()

    -- Activate other window by clicking on title bar
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
        a2d.WaitForRepaint()
    end)

    a2dtest.DHRDarkness()
    a2d.DeleteSelection()
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
    a2d.SelectPath("/A2.DESKTOP")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/RAM1")
    a2d.GrowWindowBy(200, 0)
    a2d.CreateFolder("A")
    a2d.CreateFolder("B")
    a2d.CreateFolder("C")

    a2d.Select("A")
    local a_x, a_y = a2dtest.GetSelectedIconCoords()
    a2d.Select("B")
    local b_x, b_y = a2dtest.GetSelectedIconCoords()
    a2d.Select("C")
    local c_x, c_y = a2dtest.GetSelectedIconCoords()

    a2d.ClearSelection()

    a2d.Drag(b_x, b_y, c_x, c_y)
    a2d.WaitForRepaint()

    a2d.Drag(a_x, a_y, trash_x, trash_y)
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()
    a2dtest.ExpectAlertNotShowing()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_x, vol_y)
        m.Click()
    end)
    local x, y = a2dtest.GetSelectedIconCoords()
    test.ExpectEquals(x, vol_x, "vol icon should be selected")
    test.ExpectEquals(y, vol_y, "vol icon should be selected")

    a2d.EraseVolume("RAM1")
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
    a2d.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/RAM1")
    a2d.GrowWindowBy(200, 0)
    a2d.CreateFolder("A")
    a2d.CreateFolder("B")

    a2d.Select("A")
    local a_x, a_y = a2dtest.GetSelectedIconCoords()
    a2d.Select("B")
    local b_x, b_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(b_x, b_y, a_x, a_y)

    a2d.Drag(a_x, a_y, trash_x, trash_y)
    a2dtest.WaitForAlert({match="delete 2 files%?"})
    a2d.DialogOK({no_wait=true})
    a2dtest.VerifyFilesRemainingCountdown(30, "deletion")

    a2d.EraseVolume("RAM1")
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
    a2d.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/RAM1")
    a2d.CreateFolder("F")
    a2d.SelectAndOpen("F")

    a2d.CycleWindows()

    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, trash_x, trash_y)
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()
    emu.wait(5)

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
    a2d.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/RAM1")
    a2d.CreateFolder("F")
    a2d.SelectAndOpen("F")

    a2d.CycleWindows()

    a2d.OADelete()
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()
    emu.wait(5)

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
    a2d.SelectPath("/TESTS/DELETION/X")
    a2d.OADelete()
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()

    a2dtest.WaitForAlert({match="file is locked"})
    test.ExpectMatch(a2dtest.OCRScreen(), "File: .*/DELETION/X/Y/Z/B", "prompt should be for B")
    apple2.Type("Y")
    a2d.WaitForRepaint()

    a2dtest.WaitForAlert({match="file is locked"})
    test.ExpectMatch(a2dtest.OCRScreen(), "File: .*/DELETION/X/Y/Z", "prompt should be for Z")
    apple2.Type("Y")
    a2d.WaitForRepaint()

    a2dtest.WaitForAlert({match="file is locked"})
    test.ExpectMatch(a2dtest.OCRScreen(), "File: .*/DELETION/X/Y", "prompt should be for Y")
    apple2.Type("Y")
    a2d.WaitForRepaint()

    a2dtest.WaitForAlert({match="file is locked"})
    test.ExpectMatch(a2dtest.OCRScreen(), "File: .*/DELETION/X", "prompt should be for X")
    apple2.Type("Y")
    a2d.WaitForRepaint()

    emu.wait(5)
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "all files should be deleted")
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
    a2d.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    -- Open window
    a2d.SelectPath("/WITH.FILES/LOREM.IPSUM")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    -- Eject disk
    local current = s6d1.filename
    s6d1:unload()

    -- Drag to trash
    a2d.Drag(icon_x, icon_y, trash_x, trash_y)
    a2dtest.WaitForAlert({match="Insert the disk"})
    a2d.DialogCancel() -- insert disk
    a2d.WaitForRepaint()

    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "LOREM.IPSUM", "clicked icon should be selected")

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
    a2d.SelectPath("/Trash")
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()

    -- Open window
    a2d.SelectPath("/WITH.FILES/LOREM.IPSUM")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    -- Drag to trash
    a2d.Drag(icon_x, icon_y, trash_x, trash_y)
    a2dtest.WaitForAlert({match="Are you sure"})

    -- Eject disk
    local current = s6d1.filename
    s6d1:unload()

    a2d.DialogOK() -- confirm
    a2d.WaitForRepaint()

    a2dtest.WaitForAlert({match="Insert the disk"})
    a2d.DialogCancel()
    a2d.WaitForRepaint()

    a2dtest.WaitForAlert({match="volume cannot be found"})
    a2d.DialogOK() -- OK
    emu.wait(5) -- slow I/O

    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "WITH.FILES", "clicked icon should be selected")
    test.Expect(not a2d.GetSelectedIcons()[1].dimmed, "selected icon should not be dimmed")

    s6d1:load(current)
end)
