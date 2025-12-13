
-- Remove clock driver (to avoid build-relative dates)
a2d.RemoveClockDriverAndReboot()

--[[
  Open the Control Panels folder. View > by Name. Open International.
  Change the date format from M/D/Y to D/M/Y or vice versa. Click OK.
  Verify that the entire desktop repaints, and that dates in the
  window are shown with the new format.
]]
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

--[[
  Open the Control Panels folder. View > by Name. Open International.
  Close without changing anything. Verify that only a minimal repaint
  happens.
]]
test.Step(
  "International - minimal repaint",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.SelectAndOpen("INTERNATIONAL")
    -- don't change anything
    a2dtest.ExpectMinimalRepaint(a2d.DialogOK)
end)
