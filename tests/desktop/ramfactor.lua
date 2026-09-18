--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

function RAMCardTest(name, func1, func2)
  test.Step(
    name,
    function()

      if func2 then
        func1()
      end

      desktop.ToggleOptionCopyToRAMCard() -- Enable
      desktop.Reboot()
      a2d.WaitForDesktopReady()

      if not func2 then
        func1()
      else
        func2()
      end

      desktop.DeletePath("/A2.DESKTOP/LOCAL")
      desktop.EraseVolume("RAM1")
      desktop.Reboot()
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
    desktop.OpenWindow("/RAM1/DESKTOP/APPLE.MENU/TOYS")
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
    desktop.DeletePath("/A2.DESKTOP/LOCAL/DESKTOP.CONFIG")

    desktop.InvokePath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.LeftArrowKey()
    apple2.ControlKey("D") -- Set Desktop Pattern
    a2dtest.WaitForSystemTask()
    desktop.CloseWindow()

    desktop.InvokePath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.RightArrowKey()
    apple2.ControlKey("D") -- Set Desktop Pattern
    a2dtest.WaitForSystemTask()
    desktop.CloseWindow()

    desktop.SelectPath("/A2.DESKTOP/LOCAL/DESKTOP.CONFIG")
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
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
  end,
  function()
    desktop.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")

    desktop.AddShortcut("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")

    desktop.SelectPath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
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
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
  end,
  function()
    desktop.OpenWindow("/RAM1/EXTRAS")
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
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    desktop.ToggleOptionShowShortcutsOnStartup() -- Enable
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
    desktop.OpenWindow("/RAM1/EXTRAS")
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
    desktop.OpenWindow("/RAM1/DESKTOP/APPLE.MENU")

    desktop.Select("CALENDAR")
    local icon1_x, icon1_y = a2dtest.GetSelectedIconCoords()

    desktop.Select("TOYS")
    local icon2_x, icon2_y = a2dtest.GetSelectedIconCoords()

    desktop.ClearSelection()

    -- Move a file
    a2d.Drag(icon1_x, icon1_y, icon2_x, icon2_y)
    a2dtest.WaitForSystemTask()

    -- Ensure "Copy to RAMCard" doesn't accidentally move
    desktop.AddShortcut("/RAM1/DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.OAShortcut("1") -- invoke shortcut
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    desktop.OpenWindow("/RAM1/EXTRAS")
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
    desktop.SelectPath("/RAM1/DESKTOP/APPLE.MENU")
    desktop.MoveWindowBy(0, 100)
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.CONTROL_PANELS)
    a2dtest.WaitForSystemTask()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "CONTROL.PANELS", "control panels should be activated")

    local dst_window_x, dst_window_y, dst_window_w, dst_window_h
      = a2dtest.GetFrontWindowContentRect()
    local dst_x = dst_window_x + dst_window_w/2
    local dst_y = dst_window_y + dst_window_h + 5

    a2d.Drag(icon_x, icon_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="item cannot be moved or copied into itself"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  Launch DeskTop, ensure it copies itself to RAMCard. Configure a
  shortcut set to Copy to RAMCard at first use. Invoke the shortcut.
  Verify that it correctly copies to the RAMCard and runs.
]]
test.Step(
  "Copy to RAMCard on use works",
  function()
    desktop.ToggleOptionCopyToRAMCard() -- Enable
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("PREFIX")
    test.ExpectMatch(apple2.GrabTextScreen(), "/RAM1/EXTRAS", "should be running from RAMCard")

    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    desktop.EraseVolume("RAM1")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)
