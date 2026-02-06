--[[ BEGINCONFIG ========================================

MODELARGS="\
  -sl1 ramfactor \
  -sl2 mouse \
  -sl4 superdrive \
  -sl5 superdrive \
  -sl6 diskiing \
  -sl7 cffa2"
 DISKARGS="\
  -flop1 disk_c.2mg -flop2 disk_d.2mg \
  -flop3 disk_a.2mg -flop4 disk_b.2mg \
  -flop5 prodos_floppy1.dsk -flop6 prodos_floppy2.dsk \
  -hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

-- Config produces 9 devices + Trash, so 117 file icons should be supported

a2d.ConfigureRepaintTime(0.25)
a2d.AddShortcut("/TESTS/HUNDRED.FILES")
a2d.CloseAllWindows()

--[[
  Load DeskTop. Ensure that every ProDOS device is online and
  represented by an icon. Open `/TESTS`. Open `/TESTS/HUNDRED.FILES`.
  Try opening volumes/folders until there are less than 8 windows but
  more than 127 icons. Verify that the "A window must be closed..."
  dialog has no Cancel button.
]]
test.Step(
  "icon limit can be hit before window limit",
  function()
    a2d.OAShortcut("1") -- Open HUNDRED.FILES
    emu.wait(5)
    a2d.OpenPath("/TESTS", {keep_windows=true})
    a2dtest.WaitForAlert()
    test.Expect(not a2dtest.OCRScreen():find("Cancel"), "alert should have no Cancel button")
    a2d.DialogOK()
    a2d.CloseAllWindows()
end)


function MaxIconsTest(name, func)
  test.Step(
    name,
    function()
      local count = 0
      a2d.CloseAllWindows()
      a2d.SelectAll()
      count = count + #a2d.GetSelectedIcons()
      test.ExpectEquals(count, 10, "should have 9 volumes + Trash")

      a2d.OAShortcut("1") -- Open HUNDRED.FILES
      emu.wait(5)
      a2d.GrowWindowBy(0, -50)
      a2d.SelectAll()
      emu.wait(5)
      count = count + #a2d.GetSelectedIcons()
      test.ExpectEquals(count, 110, "should have 9 volumes + Trash + 100 files")

      a2d.OpenPath("/RAM1", {keep_windows=true})
      a2d.MoveWindowBy(0, 100)
      a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
      apple2.WaitForBasicSystem()
      apple2.TypeLine("10 FOR I = 1 TO "..(127-count))
      apple2.TypeLine("20 PRINT CHR$(4)\"CREATE FF\"I")
      apple2.TypeLine("30 NEXT")
      apple2.TypeLine("RUN")
      apple2.TypeLine("BYE")
      a2d.WaitForDesktopReady()
      --[[
      for i = 1, 127 - count do
        a2d.CreateFolder("F" .. i)
      end
      ]]

      a2d.SelectAll()
      count = count + #a2d.GetSelectedIcons()
      test.ExpectEquals(count, 127, "127 icons should be supported")

      func()

      a2d.EraseVolume("RAM1")
  end)
end

--[[
  Load DeskTop. Ensure that every ProDOS device is online and
  represented by an icon. Open `/TESTS`. Open `/TESTS/HUNDRED.FILES`.
  Close `/TESTS`. Open an empty volume and create multiple new
  folders. Verify that 127 icons can be shown.
]]
-- NOTE: "/TESTS" is now too big for this.
MaxIconsTest("127 icons supported", function() end)

--[[
  Load DeskTop. Ensure that every ProDOS device is online and
  represented by an icon. Open windows bringing the total icons to
  127. File > New Folder. Verify that a warning is shown and the
  window is closed. Repeat, with multiple windows open. Verify that
  everything repaints correctly, and that no volume or folder icon
  incorrectly displays as dimmed.
]]
MaxIconsTest(
  "error on File > New Folder",
  function()
    a2d.OAShortcut("N") -- File > CreateFolder
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify repaint is correct")
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "window should have closed")
end)

--[[
  Load DeskTop. Ensure that every ProDOS device is online and
  represented by an icon. Open windows bringing the total icons to
  127. Use File > Copy To... to copy a file into a directory
  represented by an open window. Verify that after the copy, a warning
  is shown, the window is closed, and that no volume or folder icon
  incorrectly displays as dimmed.
]]
MaxIconsTest(
  "error on File > Copy To",
  function()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be active")
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "HUNDRED.FILES", "window should be active")
    apple2.DownArrowKey() -- select first
    a2d.CopySelectionTo("/RAM1", nil, {no_wait=true})
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    test.Snap("verify repaint is correct")
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "window should have closed")
end)

--[[
  Load DeskTop. Ensure that every ProDOS device is online and
  represented by an icon. Open windows bringing the total icons to
  127. Drag a file icon from another volume (to copy it) into an open
  window. Verify that after a copy, a warning is shown and the window
  is closed, and that no volume or folder icon incorrectly displays as
  dimmed.
]]
MaxIconsTest(
  "error on drag/drop of file",
  function()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be active")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + 10, y + 5

    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "HUNDRED.FILES", "window should be active")
    apple2.DownArrowKey() -- select first
    emu.wait(10)
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    emu.wait(10)
    test.Snap("verify repaint is correct")
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "window should have closed")
end)

--[[
  Load DeskTop. Ensure that every ProDOS device is online and
  represented by an icon. Open windows bringing the total icons to
  127. Drag a volume icon into an open window. Verify that after the
  copy, a warning is shown and the window is closed, and that no
  volume or folder icon incorrectly displays as dimmed.
]]
MaxIconsTest(
  "error on drag/drop of volume",
  function()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be active")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + 10, y + 5

    a2d.SelectPath("/D", {keep_windows=true})
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    emu.wait(10)
    test.Snap("verify repaint is correct")
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "window should have closed")
end)
