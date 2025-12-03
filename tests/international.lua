
--[[============================================================

  "International" tests

  ============================================================]]--

-- Remove clock driver (to avoid build-relative dates)
RemoveClockDriverAndRestart()

test.Step(
  "International - full repaint",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.SelectAndOpen("INTERNATIONAL")
    a2d.OAShortcut("2") -- D/M/Y
    apple2.DHRDarkness()
    a2d.DialogOK()

    test.Snap("Verify full repaint and D/M/Y format")
end)

test.Step(
  "International - minimal repaint",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.SelectAndOpen("INTERNATIONAL")
    -- don't change anything
    apple2.DHRDarkness()
    a2d.DialogOK()

    test.Snap("Verify minimal repaint")
end)
