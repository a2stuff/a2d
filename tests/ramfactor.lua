--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

function RAMCardTest(name, func1, func2)
  test.Step(
    name,
    function()

      if func2 then
        func1()
      end

      a2d.ToggleOptionCopyToRAMCard() -- Enable
      a2d.Reboot()
      a2d.WaitForCopyToRAMCard()

      if not func2 then
        func1()
      else
        func2()
      end

      a2d.DeletePath("/A2.DESKTOP/LOCAL")
      a2d.Reboot()
      a2d.EraseVolume("RAM1")
  end)
end

RAMCardTest(
  "Apple Menu subdirectories copied to Slinky RAM",
  function()
    a2d.OpenPath("/RAM1/DESKTOP/APPLE.MENU/TOYS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "TOYS", "directory should be copied to RAMCard")
end)

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
    test.Snap("verify DESKTOP.CONFIG selected")
end)


RAMCardTest(
  "Selector.list",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
  end,
  function()
    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")

    a2d.AddShortcut("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")

    a2d.SelectPath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    test.Snap("verify SELECTOR.LIST selected")
end)

RAMCardTest(
  "Shortcut copied on boot",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
  end,
  function()
    a2d.OpenPath("/RAM1/EXTRAS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "directory should be copied to RAMCard")
end)

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
    a2d.WaitForRestart()

    -- back to Selector
    apple2.TypeLine("BYE")
    a2d.WaitForRestart()

    -- Launch DeskTop
    apple2.Type("D")
    a2d.WaitForRestart()

    -- Verify directory was copied
    a2d.OpenPath("/RAM1/EXTRAS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "directory should be copied to RAMCard")
end)

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
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon1_x, icon1_y)
        m.ButtonDown()

        m.MoveToApproximately(icon2_x, icon2_y)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()

    -- Ensure "Copy to RAMCard" doesn't accidentally move
    a2d.AddShortcut("/RAM1/DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.OAShortcut("1") -- invoke shortcut
    a2d.WaitForRestart()
    apple2.TypeLine("BYE")
    a2d.WaitForRestart()
    a2d.OpenPath("/RAM1/EXTRAS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "directory should be copied to RAMCard")
end)

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

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon_x, icon_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y
        m.ButtonUp()
    end)
    a2dtest.WaitForAlert()
    test.Snap("verify alert is about copy into itself")
end)

test.Step(
  "Copy to RAMCard fails gracefully",
  function()
    a2d.CopyPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", "/A2.DESKTOP")
    a2d.SelectPath("/A2.DESKTOP/BASIC.SYSTEM")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.SORT_DIRECTORY)
    a2d.Reboot()

    apple2.TypeLine("CREATE /RAM1/DESKTOP")
    apple2.TypeLine("CREATE /RAM1/DESKTOP/MODULES")
    apple2.TypeLine("BSAVE /RAM1/DESKTOP/MODULES/DESKTOP,A0,L0")
    apple2.TypeLine("-/A2.DESKTOP/DESKTOP.SYSTEM")
    a2d.WaitForRestart()

    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.DeletePath("/A2.DESKTOP/BASIC.SYSTEM")
    a2d.Reboot()
    a2d.WaitForCopyToRAMCard()

    a2dtest.ExpectNotHanging()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
end)

test.Step(
  "Copy to RAMCard on use works",
  function()
    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.DeletePath("/A2.DESKTOP/BASIC.SYSTEM")
    a2d.Reboot()
    a2d.WaitForCopyToRAMCard()

    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.OAShortcut("1")
    a2d.WaitForCopyToRAMCard()

    apple2.TypeLine("PREFIX")
    test.Expect(apple2.GrabTextScreen():match("/RAM1/EXTRAS"), "should be running from RAMCard")

    apple2.TypeLine("BYE")
    a2d.WaitForRestart()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
end)
