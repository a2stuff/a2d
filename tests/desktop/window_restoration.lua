--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv -flop1 prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]

-- Need to ensure DESKTOP.FILE gets written out or window headers
-- will change

desktop.QuitAndRestart()

--[[
  Launch DeskTop. Open a subdirectory folder. Quit and relaunch
  DeskTop. Verify that the used/free numbers in the restored windows
  are non-zero.
]]
test.Step(
  "Subdirectory header values",
  function()
    desktop.OpenWindow("/A2.DESKTOP/EXTRAS")
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(desktop.QuitAndRestart)
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open some windows. Special > Copy Disk. Quit back to
  DeskTop. Verify that the windows are restored.

  Launch DeskTop. Close all windows. Special > Copy Disk. Quit back to
  DeskTop. Verify that no windows are restored.
]]
test.Step(
  "Launching Disk Copy",
  function()
    desktop.SelectAll()
    a2d.OAShortcut("O") -- File > Open
    a2dtest.WaitForSystemTask()
    desktop.ClearSelection()
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectNothingChanged(function()
        desktop.CopyDisk()
        a2d.WaitForDesktopReady()

        a2d.OAShortcut("Q") -- File > Quit
        a2d.WaitForDesktopReady()
    end)

    desktop.CloseAllWindows()
    a2dtest.WaitForSystemTask()
    a2dtest.WaitForSystemTask()
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        desktop.CopyDisk()
        a2d.WaitForDesktopReady()

        a2d.OAShortcut("Q") -- File > Quit
        a2d.WaitForDesktopReady()
    end)
    desktop.CloseAllWindows()
end)

--[[
  Load DeskTop. Open a volume. Adjust the window size so that
  horizontal and vertical scrolling is required. Scroll to the
  bottom-right. Quit DeskTop, reload. Verify that the window size and
  scroll position was restored correctly.
]]
test.Step(
  "Window geometry and scroll position",
  function()
    desktop.OpenWindow("/TESTS/FILE.TYPES")
    desktop.GrowWindowBy(-40, -20)
    for i = 1,10 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
      a2dtest.WaitForSystemTask()
    end
    desktop.ClearSelection()
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectNothingChanged(desktop.QuitAndRestart)
    desktop.CloseAllWindows()
end)

--[[
  Load DeskTop. Open a volume. Quit DeskTop, reload. Verify that the
  volume window was restored, and that the volume icon is dimmed.
  Close the volume window. Verify that the volume icon is no longer
  dimmed.
]]
test.Step(
  "Parent icon of restored window undims",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(desktop.QuitAndRestart)
    desktop.CloseAllWindows()

    desktop.SelectPath("/A2.DESKTOP")
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.Expect(not desktop.GetSelectedIcons()[1].dimmed, "selected icon should not be dimmed")
end)

--[[
  Load DeskTop. Open a window containing icons. View > by Name. Quit
  DeskTop, reload. Verify that the window is restored, and that it
  shows the icons in a list sorted by name, and that View > by Name is
  checked. Repeat for other View menu options.
]]
test.Variants(
  {
    "As Icons",
    "As Small Icons",
    "By Name",
    "By Date",
    "By Size",
    "By Type",
  },
  function(idx, name)
    desktop.OpenWindow("/TESTS/FILE.TYPES")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, idx)
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(desktop.QuitAndRestart)
    a2d.OpenMenu(desktop.VIEW_MENU)
    test.Snap("verify "..name.." is checked")
    apple2.EscapeKey()
    desktop.CloseAllWindows()
end)

--[[
  Load DeskTop. Open a window for a volume in a Disk II drive. Quit
  DeskTop. Remove the disk from the Disk II drive. Load DeskTop.
  Verify that the Disk II drive is only polled once on startup, not
  twice.
]]
test.Step(
  "Disk II Drive polling",
  function()
    desktop.OpenWindow("/FLOPPY1")
    desktop.Quit() -- to Bitsy Bye

    local drive = s6d1
    local image = drive.filename
    drive:unload()

    apple2.BitsyInvokePath("/A2.DESKTOP/PRODOS")

    -- TODO: Verify only polled once - watch drive access?

    a2d.WaitForDesktopReady()

    -- cleanup
    drive:load(image)
    desktop.CheckAllDrives()
end)

--[[
  Launch DeskTop. Open a window. File > Quit. Launch DeskTop again.
  Ensure the window is restored. Try to drag-select volume icons.
  Verify that they are selected.
]]
test.Step(
  "Drag selection still functions",
  function()
    desktop.OpenWindow("/TESTS/FILE.TYPES")
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(desktop.QuitAndRestart)
    desktop.DragSelectMultipleVolumes()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 3, "volume icons should be selected")
end)

--[[
  Launch DeskTop. Open a volume window. Rename the volume to "TRASH"
  (all uppercase). File > Quit. Load DeskTop. Verify that the restored
  window is named "TRASH" not "Trash".
]]
test.Step(
  "Trash name",
  function()
    desktop.OpenWindow("/TESTS")
    desktop.RenameSelection("TRASH")
    desktop.QuitAndRestart()
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "TRASH", "Case is retained")
end)

--[[
  Launch DeskTop. Several windows. Quit and relaunch
  DeskTop while holding OA+SA. Verify that the window is not restored.
  are non-zero.
]]
test.Step(
  "Holding OA+SA skips restoration",
  function()
    desktop.OpenWindow("/A2.DESKTOP/EXTRAS", {leave_parent=true})

    desktop.Quit()
    apple2.BitsyInvokeFile("PRODOS")

    a2d.WaitForDesktopReady()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "windows should have restored")

    desktop.Quit()
    apple2.BitsyInvokeFile("PRODOS")

    apple2.PressOA()
    apple2.PressSA()
    a2d.WaitForDesktopReady()
    apple2.ReleaseSA()
    apple2.ReleaseOA()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "windows should not have restored")
end)
