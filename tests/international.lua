
--[[============================================================

  "International" tests

  ============================================================]]--

-- Remove clock driver (to avoid build-relative dates)
a2d.OpenPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
a2d.WaitForRestart()
apple2.TypeLine("DELETE /A2.DESKTOP/CLOCK.SYSTEM")
apple2.TypeLine("PR#7")
a2d.WaitForRestart()

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
