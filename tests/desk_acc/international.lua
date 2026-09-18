
-- Remove clock driver (to avoid build-relative dates)
desktop.RemoveClockDriverAndReboot()

--[[
  Open the Control Panels folder. View > by Name. Open International.
  Change the date format from M/D/Y to D/M/Y or vice versa. Click OK.
  Verify that the entire desktop repaints, and that dates in the
  window are shown with the new format.
]]
test.Step(
  "International - full repaint",
  function()
    desktop.OpenWindow("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    desktop.SelectAndOpen("INTERNATIONAL")
    a2d.OAShortcut("2") -- D/M/Y
    a2dtest.ExpectFullRepaint(function()
        a2d.DialogOK()
        a2dtest.WaitForSystemTask()
    end)
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
    desktop.OpenWindow("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    desktop.SelectAndOpen("INTERNATIONAL")
    -- don't change anything
    a2dtest.ExpectMinimalRepaint(function()
        a2d.DialogOK()
        a2dtest.WaitForSystemTask()
    end)
end)
