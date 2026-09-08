--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(2)

--[[
  NOTE: Currently MAME does not allow configuring a system without
  a No-Slot Clock so testing is limited:

  (a) ProDOS has clock driver, and clock is writable - YES
  (b) ProDOS has no clock driver - YES
  (c) ProDOS has clock driver, but clock not writable - NO

  https://github.com/mamedev/mame/issues/14778
]]

--[[
  Open `/TESTS/FILE.TYPES`. View > by Name. Apple Menu > Control
  Panels > Date and Time. Change the time format from 12- to 24-hour
  or vice versa. Click OK. Verify that the entire desktop repaints,
  and that dates in the windows are shown with the new format
]]
test.Step(
  "Time format repaint",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("2") -- 24-hour
    a2dtest.ExpectFullRepaint(a2d.DialogOK)
    test.Snap("verify 24-hour format shown")
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Apple Menu > Control Panels > Date and Time. Press Escape key.
  Verify the desk accessory exits. Repeat with the Return key.
]]
test.Step(
  "Escape and Return",
  function()
    a2d.SelectPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/DATE.AND.TIME")
    local count = a2dtest.GetWindowCount()
    a2d.OpenSelection()
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), count, "expect window closed")

    a2d.OpenSelection()
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), count, "expect window closed")

    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Apple Menu > Control Panels > Date and Time. Verify
  that the date and time are readable.
]]
test.DISABLED_Step(
  "Read only",
  "no configuration w/ driver but no writing logic",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    for i=1, 5 do
      apple2.UpArrowKey()
      apple2.UpArrowKey()
      apple2.UpArrowKey()
      apple2.UpArrowKey()
      apple2.DownArrowKey()
      apple2.DownArrowKey()
      apple2.TabKey()
    end
    a2d.WaitForRepaint()
    test.Snap("verify fields are read-only")
    a2d.DialogCancel()
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Run the Date and Time DA, and change the setting to
  12 hour. Verify that the time is shown as 12-hour, and if less than
  10 is displayed without a leading 0.
]]
test.Step(
  "12-hour",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("1") -- 12-hour
    test.Snap("verify 12-hour, no leading 0 on hours")
    a2d.DialogOK()
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Run the Date and Time DA, and change the setting to
  24 hour. Verify that the time is shown as 24-hour, and if less than
  10 is displayed with a leading 0.
]]
test.Step(
  "24-hour",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("2") -- 24-hour
    test.Snap("verify 24-hour, leading 0 on hours")
    a2d.DialogOK()
    a2d.CloseAllWindows()
end)

