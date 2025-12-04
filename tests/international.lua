
--[[============================================================

  "International" tests

  ============================================================]]--

-- Remove clock driver (to avoid build-relative dates)
a2d.RemoveClockDriverAndReboot()

test.Step(
  "International - full repaint",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.SelectAndOpen("INTERNATIONAL")
    a2d.OAShortcut("2") -- D/M/Y
    a2dtest.ExpectFullRepaint(a2d.DialogOK)
    test.Snap("verify D/M/Y format")
end)

test.Step(
  "International - minimal repaint",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.SelectAndOpen("INTERNATIONAL")
    -- don't change anything
    a2dtest.ExpectMinimalRepaint(a2d.DialogOK)
end)
