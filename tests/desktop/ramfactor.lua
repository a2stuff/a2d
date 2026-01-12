--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

function RAMCardTest(name, func1, func2)
  test.Step(
    name,
    function()

      if func2 then
        func1()
      end

      a2d.ToggleOptionCopyToRAMCard() -- Enable
      a2d.Reboot()
      a2d.WaitForDesktopReady()

      if not func2 then
        func1()
      else
        func2()
      end

      a2d.DeletePath("/A2.DESKTOP/LOCAL")
      a2d.EraseVolume("RAM1")
      a2d.Reboot()
      a2d.WaitForDesktopReady()
  end)
end

--[[
  Run DeskTop on a system with RAMFactor/"Slinky" RAMDisk. Verify that
  sub-directories under `APPLE.MENU` are copied to
  `/RAM5/DESKTOP/APPLE.MENU` (or appropriate volume path).
]]
RAMCardTest(
  "Apple Menu subdirectories copied to Slinky RAM",
  function()
    a2d.OpenPath("/RAM1/DESKTOP/APPLE.MENU/TOYS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "TOYS", "directory should be copied to RAMCard")
end)

--[[
  Launch DeskTop, ensure it copies itself to RAMCard. Delete the
  `LOCAL/DESKTOP.CONFIG` file from the startup disk, if it was
  present. Go into Control Panels and change a setting. Verify that
  `LOCAL/DESKTOP.CONFIG` is written to the startup disk.
]]
RAMCardTest(
  "Desktop.config",
  function()
    a2d.DeletePath("/A2.DESKTOP/LOCAL/DESKTOP.CONFIG")

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.LeftArrowKey()
    apple2.ControlKey("D")
    a2d.WaitForRepaint()
    a2d.CloseWindow()

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.RightArrowKey()
    apple2.ControlKey("D")
    a2d.WaitForRepaint()
    a2d.CloseWindow()

    a2d.SelectPath("/A2.DESKTOP/LOCAL/DESKTOP.CONFIG")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "DESKTOP.CONFIG", "file should exist")
end)


--[[
  Launch DeskTop, ensure it copies itself to RAMCard. Delete the
  `LOCAL/SELECTOR.LIST` file from the startup disk, if it was present.
  Shortcuts > Add a Shortcut, and create a new shortcut. Verify that
  `LOCAL/SELECTOR.LIST` is written to the startup disk.
]]
RAMCardTest(
  "Selector.list",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
  end,
  function()
    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")

    a2d.AddShortcut("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")

    a2d.SelectPath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "SELECTOR.LIST", "file should exist")
end)

--[[
  Launch DeskTop. Create a shortcut for
  `/TESTS/RAMCARD/SHORTCUT/BASIC.SYSTEM`, set to copy to RAMCard at
  boot. Ensure DeskTop is set to copy to RAMCard on startup. Restart
  DeskTop. Verify that the directory is successfully copied.
]]
RAMCardTest(
  "Shortcut copied on boot",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
  end,
  function()
    a2d.OpenPath("/RAM1/EXTRAS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "directory should be copied to RAMCard")
end)

--[[
  Launch DeskTop. Create a shortcut for
  `/TESTS/RAMCARD/SHORTCUT/BASIC.SYSTEM`, set to copy to RAMCard at
  first use. Ensure DeskTop is set to copy to RAMCard on startup.
  Ensure DeskTop is set to launch Shortcuts. Quit DeskTop. Launch
  Shortcuts. Select the shortcut. Verify that the directory is
  successfully copied.
]]
RAMCardTest(
  "Shortcut copied on use",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.ToggleOptionShowShortcutsOnStartup() -- Enable
  end,
  function()
    -- invoke BASIC.SYSTEM
    apple2.Type("1")
    a2d.DialogOK()
    apple2.WaitForBasicSystem()

    -- back to Selector
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    -- Launch DeskTop
    apple2.Type("D")
    a2d.WaitForDesktopReady()

    -- Verify directory was copied
    a2d.OpenPath("/RAM1/EXTRAS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "directory should be copied to RAMCard")
end)

--[[
  Launch DeskTop, ensure it copies itself to RAMCard. Drag a file icon
  to a same-volume window so it is moved. Configure a shortcut to copy
  to RAMCard "at first use". Invoke the shortcut. Verify that the
  shortcut's files were indeed copied, not moved.
]]
RAMCardTest(
  "Copy to RAMCard always copies",
  function()
    a2d.OpenPath("/RAM1/DESKTOP/APPLE.MENU")

    a2d.Select("CALENDAR")
    local icon1_x, icon1_y = a2dtest.GetSelectedIconCoords()

    a2d.Select("TOYS")
    local icon2_x, icon2_y = a2dtest.GetSelectedIconCoords()

    a2d.ClearSelection()

    -- Move a file
    a2d.Drag(icon1_x, icon1_y, icon2_x, icon2_y)
    a2d.WaitForRepaint()

    -- Ensure "Copy to RAMCard" doesn't accidentally move
    a2d.AddShortcut("/RAM1/DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.OAShortcut("1") -- invoke shortcut
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    a2d.OpenPath("/RAM1/EXTRAS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "directory should be copied to RAMCard")
end)

--[[
  Launch DeskTop, ensure it copies itself to RAMCard. Open the RAM
  Disk volume. Open the Desktop folder. Apple Menu > Control Panels.
  Drag Apple.Menu from the Desktop folder to the Control.Panels
  window. Verify that an alert is shown that an item can't be moved or
  copied into itself.
]]
RAMCardTest(
  "Apple Menu > Control Panels is from the RAMCard",
  function()
    a2d.SelectPath("/RAM1/DESKTOP/APPLE.MENU")
    a2d.MoveWindowBy(0, 100)
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    local dst_window_x, dst_window_y, dst_window_w, dst_window_h
      = a2dtest.GetFrontWindowContentRect()
    local dst_x = dst_window_x + dst_window_w/2
    local dst_y = dst_window_y + dst_window_h + 5

    a2d.Drag(icon_x, icon_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    test.Snap("verify alert is about copy into itself")
    a2d.DialogOK()
end)

--[[
  Launch DeskTop, ensure it copies itself to RAMCard. Configure a
  shortcut set to Copy to RAMCard at first use. Invoke the shortcut.
  Verify that it correctly copies to the RAMCard and runs.
]]
test.Step(
  "Copy to RAMCard on use works",
  function()
    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("PREFIX")
    test.Expect(apple2.GrabTextScreen():match("/RAM1/EXTRAS"), "should be running from RAMCard")

    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
