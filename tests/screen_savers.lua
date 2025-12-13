--[[============================================================

  "Screen Savers" tests

  ============================================================]]

--[[
  Launch DeskTop. Apple Menu > Screen Savers. Select Melt. File > Open
  (or Apple+O). Click to exit. Press Apple+Down. Click to exit. Verify
  that the File menu is not highlighted.
]]
test.Variants(
  {
    "Melt - File > Open does not leave File menu highlighted",
    "Melt - Apple-Down does not leave File menu highlighted",
  },
  function(idx)
    a2d.SelectPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MELT")

    if idx == 1 then
      a2d.OAShortcut("O")
    else
      a2d.OADown()
    end

    emu.wait(1)

    a2d.InMouseKeysMode(function(m)
        -- Move cursor away from origin so menu bar is not obscured
        local coords_x, coords_y = 20, 20
        m.MoveToApproximately(coords_x, coords_y)
        m.Click()
    end)

    a2d.WaitForRepaint()

    a2dtest.ExpectMenuNotHighlighted()
    a2d.CloseAllWindows()
end)

--[[
  Configure a system with a real-time clock. Launch DeskTop. Apple
  Menu > Screen Savers. Run a screen saver that uses the full graphics
  screen and conceals the menu (Flying Toasters or Melt). Exit it.
  Verify that the menu bar clock reappears immediately.
]]
test.Step(
  "Clock redraws immediately",
  function()
    a2d.SelectPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MELT")
    a2d.OAShortcut("O")
    emu.wait(1)

    apple2.EscapeKey()
    apple2.Type('@') -- no-op, wait for key to be consumed

    a2dtest.ExpectClockVisible()

    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Apple Menu > Screen Savers. Run Matrix. Click the
  mouse button. Verify that the screen saver exits. Run Matrix. Press
  a key. Verify that the screen saver exits.
]]
test.Variants(
  {
    "Matrix exits on click",
    "Matrix exits on key",
  },
  function(idx)
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MATRIX")
    emu.wait(1)

    if idx == 1 then
      a2d.InMouseKeysMode(function(m) m.Click() end)
    else
      apple2.ReturnKey()
    end

    a2d.WaitForRepaint()
    a2d.CloseAllWindows()
end)


a2d.RemoveClockDriverAndReboot()

--[[
  Configure a system with no real-time clock. Launch DeskTop. Apple
  Menu > Screen Savers. Run Analog Clock. Verify that an alert is
  shown.
]]
test.Step(
  "Analog Clock shows alert if there is no system clock",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/ANALOG.CLOCK")
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()
    a2d.CloseAllWindows()
end)

--[[
  Configure a system with no real-time clock. Launch DeskTop. Apple
  Menu > Screen Savers. Run Digital Clock. Verify that an alert is
  shown.
]]
test.Step(
  "Digital Clock shows alert if there is no system clock",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/DIGITAL.CLOCK")
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()
    a2d.CloseAllWindows()
end)
