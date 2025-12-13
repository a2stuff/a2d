--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

--[[
  Open `/TESTS/FILE.TYPES`. View > by Name. Apple Menu > Control
  Panels > Date and Time. Change the time format from 12- to 24-hour
  or vice versa. Click OK. Verify that the entire desktop repaints,
  and that dates in the windows are shown with the new format
]]--
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
end)

--[[
  Run these tests on a system with a real-time clock
]]--

--[[
  Apple Menu > Control Panels > Date and Time. Press Escape key.
  Verify the desk accessory exits. Repeat with the Return key.
]]--
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
  that the date and time are read-only.
]]--
test.Step(
  "Read only",
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
    test.Snap("verify fields are read-only")
    a2d.DialogCancel()
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Run the Date and Time DA, and change the setting to
  12 hour. Verify that the time is shown as 12-hour, and if less than
  10 is displayed without a leading 0.
]]--
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
]]--
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

--[[
  Run these tests on a system without a real-time clock:
]]--

a2d.RemoveClockDriverAndReboot()

--[[
  Start with a fresh disk image. Run DeskTop. Apple Menu > Control
  Panels. View > by Name. Open Date and Time. Verify that the date
  shown in the dialog matches the file dates. Click OK without
  changing anything. Verify that the entire desktop repaints, and that
  dates in the window are shown with "Today". Open Date and Time.
  Click OK without changing anything. Verify that the entire desktop
  does not repaint
]]--
test.Step(
  "Fresh disk image",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.SelectAndOpen("DATE.AND.TIME")
    test.Snap("verify dialog date matches packaged file dates")
    a2dtest.ExpectFullRepaint(a2d.DialogOK)
    test.Snap("verify dates now Today")
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2dtest.ExpectMinimalRepaint(a2d.DialogOK)
    a2d.Reboot()
end)

--[[
  Run Apple Menu > Control Panels > Date and Time. Set date. Reboot
  system, and re-run DeskTop. Create a new folder. Use File > Get
  Info. Verify that the date was saved/restored.
]]--
test.Step(
  "Change date - persisted",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    apple2.UpArrowKey() -- change day
    apple2.TabKey()
    apple2.UpArrowKey() -- change month
    apple2.TabKey()
    apple2.UpArrowKey() -- change year
    test.Snap("verify date is modified")
    a2d.DialogOK()
    -- Should write timestamp to DESKTOP.SYSTEM. Restart to verify.
    a2d.Reboot()

    -- Create new folder
    a2d.CreateFolder("/RAM1/NOT.TODAY")

    -- Change date again to avoid "Today"
    a2d.SetProDOSDate(1999, 9, 13)

    -- Inspect file
    a2d.SelectPath("/RAM1/NOT.TODAY")
    a2d.OAShortcut("I") -- File > Get Info
    test.Snap("verify date matches set previously set date")
    a2d.DialogOK()
    a2d.DeletePath("/RAM1/NOT.TODAY")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Run the Date and Time DA, and change the setting to
  12 hour. Verify that the time is shown as 12-hour, and if less than
  10 is displayed without a leading 0. Use the Right Arrow and Left
  Arrow keys and the mouse, and verify that the AM/PM field is
  selectable. Select the AM/PM field. Use the up and down arrow keys
  and the arrow buttons, and verify that the field toggles. Select the
  hours field. Use the up and down arrow keys and the arrow buttons,
  and verify that the field cycles from 1 through 12.
]]--
test.Step(
  "12-hour field behavior",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("1") -- 12-hour
    apple2.TabKey() -- to month
    apple2.TabKey() -- to year
    apple2.TabKey() -- to hour
    apple2.TabKey() -- to min
    apple2.TabKey() -- to period
    test.Snap("verify period field enabled")
    apple2.UpArrowKey()
    test.Snap("verify period field modifiable")
    apple2.LeftArrowKey() -- to min
    apple2.LeftArrowKey() -- to hour
    for i = 1, 24 do
      apple2.UpArrowKey()
      test.Snap("verify 12 hour cycle")
    end
    a2d.DialogOK()
end)

--[[
  Launch DeskTop. Run the Date and Time DA, and change the setting to
  24 hour. Verify that the time is shown as 24-hour, and if less than
  10 is displayed with a leading 0. Use the Right Arrow and Left Arrow
  keys and the mouse, and verify that the AM/PM field is not
  selectable. Use the up and down arrow keys and the arrow buttons,
  and verify that the field cycles from 0 through 23.
]]--
test.Step(
  "24-hour field behavior",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("2") -- 12-hour
    apple2.TabKey() -- to month
    apple2.TabKey() -- to year
    apple2.TabKey() -- to hour
    apple2.TabKey() -- to min
    apple2.TabKey() -- to back to day
    test.Snap("verify period field disabled")
    apple2.TabKey() -- to month
    apple2.TabKey() -- to year
    apple2.TabKey() -- to hour
    for i = 1, 24 do
      apple2.UpArrowKey()
      test.Snap("verify 24 hour cycle")
    end
    a2d.DialogOK()
end)

--[[
  Launch DeskTop. Run the Date and Time DA. Change the month and year,
  and verify that the day range is clamped to 28, 29, 30 or 31 as
  appropriate, including for leap years.
]]--
test.Step(
  "Day ranges",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)

    function IncDate(y1, m1, d1, y2, m2, d2)
      a2d.SetProDOSDate(y1, m1, d1)
      local yy,mm,dd = a2d.GetProDOSDate()
      a2d.SelectAndOpen("DATE.AND.TIME")
      apple2.UpArrowKey()
      a2d.DialogOK()
      local y,m,d = a2d.GetProDOSDate()
      test.ExpectEquals(
        y, y2,
        string.format("year: %d/%d/%d should increment to %d/%d/%d", y1, m1, d1, y2, m2, d2))
      test.ExpectEquals(
        m, m2,
        string.format("month: %d/%d/%d should increment to %d/%d/%d", y1, m1, d1, y2, m2, d2))
      test.ExpectEquals(
        d, d2,
        string.format("day: %d/%d/%d should increment to %d/%d/%d", y1, m1, d1, y2, m2, d2))
    end

    function DecDate(y1, m1, d1, y2, m2, d2)
      a2d.SetProDOSDate(y1, m1, d1)
      local yy,mm,dd = a2d.GetProDOSDate()
      a2d.SelectAndOpen("DATE.AND.TIME")
      apple2.DownArrowKey()
      a2d.DialogOK()
      local y,m,d = a2d.GetProDOSDate()
      test.ExpectEquals(
        y, y2,
        string.format("year: %d/%d/%d should decrement to %d/%d/%d", y1, m1, d1, y2, m2, d2))
      test.ExpectEquals(
        m, m2,
        string.format("month: %d/%d/%d should decrement to %d/%d/%d", y1, m1, d1, y2, m2, d2))
      test.ExpectEquals(
        d, d2,
        string.format("day: %d/%d/%d should decrement to %d/%d/%d", y1, m1, d1, y2, m2, d2))
    end


    -- 31 day month
    IncDate(2023, 1, 28, 2023, 1, 29)
    IncDate(2023, 1, 29, 2023, 1, 30)
    IncDate(2023, 1, 30, 2023, 1, 31)
    IncDate(2023, 1, 31, 2023, 1, 1)
    DecDate(2023, 1, 1, 2023, 1, 31)

    -- 30 day month
    IncDate(2023, 4, 28, 2023, 4, 29)
    IncDate(2023, 4, 29, 2023, 4, 30)
    IncDate(2023, 4, 30, 2023, 4, 1)
    DecDate(2023, 4, 1, 2023, 4, 30)

    -- 28 day month
    IncDate(2023, 2, 28, 2023, 2, 1)
    DecDate(2023, 2, 1, 2023, 2, 28)

    -- 29 day month
    IncDate(2024, 2, 28, 2024, 2, 29)
    IncDate(2024, 2, 29, 2024, 2, 1)
    DecDate(2024, 2, 1, 2024, 2, 29)
end)

-- Dialog control metrics
local incr_x, incr_y = 264, 12
local decr_x, decr_y = 264, 25
local field_y = 21
local day_x = 29
local month_x = day_x + 45
local year_x = month_x + 45
local hour_x = year_x + 45
local minute_x = hour_x + 40
local period_x = minute_x + 30

--[[
  Launch DeskTop. Run the Date and Time DA. Click on the up/down
  arrows. Verify that they invert correctly when the button is down.

  Launch DeskTop. Run the Date and Time DA. Click in the various
  fields (day/month/year/hour/minutes/period). Verify that the
  appropriate field highlights.

  Launch DeskTop. Run the Date and Time DA. Change the setting to 12
  hour. Click on the AM/PM field. Verify that the field highlights.
]]--
test.Step(
  "Clicking fields",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("1") -- 12-hour

    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x + incr_x, dialog_y + incr_y)
        m.ButtonDown()
        emu.wait(10/60)
        test.Snap("verify up button inverted")
        m.ButtonUp()

        m.MoveToApproximately(dialog_x + decr_x, dialog_y + decr_y)
        m.ButtonDown()
        emu.wait(10/60)
        test.Snap("verify down button inverted")
        m.ButtonUp()

        m.MoveToApproximately(dialog_x + day_x, dialog_y + field_y)
        m.Click()
        test.Snap("verify day focused")
        m.MoveToApproximately(dialog_x + month_x, dialog_y + field_y)
        m.Click()
        test.Snap("verify month focused")
        m.MoveToApproximately(dialog_x + year_x, dialog_y + field_y)
        m.Click()
        test.Snap("verify year focused")
        m.MoveToApproximately(dialog_x + hour_x, dialog_y + field_y)
        m.Click()
        test.Snap("verify hour focused")
        m.MoveToApproximately(dialog_x + minute_x, dialog_y + field_y)
        m.Click()
        test.Snap("verify minute focused")
        m.MoveToApproximately(dialog_x + period_x, dialog_y + field_y)
        m.Click()
        test.Snap("verify period focused")
    end)
    a2d.DialogOK()
end)

--[[
  Launch DeskTop. Run the Date and Time DA. Change the setting to 24
  hour. Click where the AM/PM field would be, to the right of the
  minutes field. Verify that nothing happens.
]]--
test.Step(
  "Clicking 24-hour",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("2") -- 24-hour

    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x + period_x, dialog_y + field_y)
        m.Click()
        test.Snap("verify period not focused")
    end)
    a2d.DialogOK()
end)

--[[
  Launch DeskTop. Run the Date and Time DA. Click the year field.
  Click the up arrow. Verify that the year increments. Click the down
  arrow. Verify that the year decrements. Verify that only the clicked
  buttons highlight, and that they un-highlight correctly when the
  button is released.
]]--
test.Step(
  "Arrows",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("1") -- 12-hour

    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x + year_x, dialog_y + field_y) -- year
        m.Click()
        test.Snap("verify year focused")

        m.MoveToApproximately(dialog_x+incr_x, dialog_y+incr_y) -- up arrow
        m.ButtonDown()
        emu.wait(2/60)
        test.Snap("verify up button inverted")
        m.ButtonUp()
        emu.wait(2/60)
        test.Snap("verify year increments")

        m.MoveToApproximately(dialog_x+decr_x, dialog_y+decr_y) -- down arrow
        m.ButtonDown()
        emu.wait(2/60)
        test.Snap("verify down button inverted")
        m.ButtonUp()
        emu.wait(2/60)
        test.Snap("verify year decrements")
    end)
    a2d.DialogOK()
end)

--[[
  Apple Menu > Control Panels. View > by Name. Run Date and Time.
  Change the date to the same date as one of the files in the folder.
  Click OK. Verify that the entire desktop repaints, and that dates in
  the window are shown with "Today".
]]--
test.Step(
  "Today",
  function()
    -- Create file with known date
    local y, m, d = a2d.GetProDOSDate()
    a2d.SetProDOSDate(1999, 9, 13)
    a2d.CreateFolder("/RAM1/WILL.BE.TODAY")
    -- Change the date so it's not current
    a2d.SetProDOSDate(y, m, d)

    -- Show window and resize/move it
    a2d.OpenPath("/RAM1")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.GrowWindowBy(250, 0)
    a2d.MoveWindowBy(0, 100)
    test.Snap("verify date is shown in full")

    -- Use Date & Time to set date
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SetProDOSDate(1998, 9, 13) -- so we know the delta
    a2d.SelectAndOpen("DATE.AND.TIME")
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x + year_x, dialog_y+field_y) -- year
        m.Click()
    end)
    apple2.UpArrowKey()
    a2dtest.ExpectFullRepaint(a2d.DialogOK)
    test.Snap("verify bottom date shows Today")
end)
