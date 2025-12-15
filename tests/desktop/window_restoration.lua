--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(2)

-- Need to ensure DESKTOP.FILE gets written out or window headers
-- will change

a2d.QuitAndRestart()

--[[
  Launch DeskTop. Open a subdirectory folder. Quit and relaunch
  DeskTop. Verify that the used/free numbers in the restored windows
  are non-zero.
]]
test.Step(
  "Subdirectory header values",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS")
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(a2d.QuitAndRestart)
    a2d.CloseAllWindows()
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
    a2d.SelectAll()
    a2d.OAShortcut("O") -- File > Open
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
        a2d.WaitForDesktopReady()
        a2d.OAShortcut("Q") -- File > Quit
        a2d.WaitForDesktopReady()
    end)

    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
        a2d.WaitForDesktopReady()
        a2d.OAShortcut("Q") -- File > Quit
        a2d.WaitForDesktopReady()
    end)
    a2d.CloseAllWindows()
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
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.GrowWindowBy(-40, -20)
    for i = 1,10 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(a2d.QuitAndRestart)
    a2d.CloseAllWindows()
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
    a2d.OpenPath("/A2.DESKTOP")
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(a2d.QuitAndRestart)
    a2d.CloseAllWindows()

    a2d.SelectPath("/A2.DESKTOP")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.Expect(not a2d.GetSelectedIcons()[1].dimmed, "selected icon should not be dimmed")
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
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, idx)
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(a2d.QuitAndRestart)
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify "..name.." is checked")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
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
    a2d.OpenPath("/FLOPPY1")
    a2d.Quit() -- to Bitsy Bye

    apple2.GetDiskIIS6D1():unload()

    apple2.BitsyInvokeFile("PRODOS")

    -- TODO: Verify only polled once - watch drive access?

    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Open a window. File > Quit. Launch DeskTop again.
  Ensure the window is restored. Try to drag-select volume icons.
  Verify that they are selected.
]]
test.Step(
  "Drag selection still functions",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(a2d.QuitAndRestart)
    a2d.DragSelectMultipleVolumes()

    test.ExpectEquals(#a2d.GetSelectedIcons(), 3, "volume icons should be selected")
end)

--[[
  Launch DeskTop. Open a volume window. Rename the volume to "TRASH"
  (all uppercase). File > Quit. Load DeskTop. Verify that the restored
  window is named "TRASH" not "Trash".
]]
test.Step(
  "Trash name",
  function()
    a2d.OpenPath("/TESTS")
    a2d.RenameSelection("TRASH")
    a2d.QuitAndRestart()
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "TRASH", "Case is retained")
end)

