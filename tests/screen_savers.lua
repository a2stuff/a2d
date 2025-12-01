--[[============================================================

  "Screen Savers" tests

  ============================================================]]--

test.Variants(
  {
    "Melt - File > Open does not leave File menu highlighted",
    "Melt - Apple-Down does not leave File menu highlighted",
  },
  function(idx)
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS")
    apple2.Type("MELT")

    if idx == 1 then
      a2d.OAShortcut("O")
    else
      a2d.OADown()
    end

    emu.wait(1)

    a2d.InMouseKeysMode(function(m) m.Click() end)
    a2d.WaitForRepaint()

    -- cursor is in leftmost byte
    for col = 1,79 do
      test.ExpectEquals(apple2.GetDoubleHiresByte(0, col), 0x7F, "Menu should not be highlighted")
    end
    a2d.CloseAllWindows()
end)

test.Step(
  "Clock redraws immediately",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS")
    apple2.Type("MELT")
    a2d.OAShortcut("O")
    emu.wait(1)

    apple2.EscapeKey()
    apple2.ControlKey('@') -- no-op, wait for key to be consumed

    test.ExpectNotEquals(apple2.GetDoubleHiresByte(4, 78), 0x7F, "Clock should be visible already")

    a2d.CloseAllWindows()
end)

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

-- Remove clock driver
a2d.OpenPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
a2d.WaitForRestart()
apple2.TypeLine("DELETE /A2.DESKTOP/CLOCK.SYSTEM")
apple2.TypeLine("PR#7")
a2d.WaitForRestart()

test.Step(
  "Analog Clock shows alert if there is no system clock",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/ANALOG.CLOCK")
    test.Snap("verify alert shown")
    a2d.DialogOK()
    a2d.CloseAllWindows()
end)

test.Step(
  "Digital Clock shows alert if there is no system clock",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/DIGITAL.CLOCK")
    test.Snap("verify alert shown")
    a2d.DialogOK()
    a2d.CloseAllWindows()
end)
