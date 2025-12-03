--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

test.Step(
  "Time format repaint",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("2") -- 24-hour
    apple2.DHRDarkness()
    a2d.DialogOK()
    test.ExpectEquals(a2d.RepaintType(), "full", "repaint", {snap=true})
    test.Snap("verify 24-hour format shown")
    a2d.CloseAllWindows()
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1) -- slot 7
    a2d.WaitForRestart()
end)

test.Step(
  "Escape and Return",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    test.Snap("verify dialog closed")
    a2d.SelectAndOpen("DATE.AND.TIME")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.Snap("verify dialog closed")
    a2d.CloseAllWindows()
end)

test.Step(
  "Read only",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    for i=1,5 do
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

a2d.RemoveClockDriverAndRestart()

test.Step(
  "Fresh disk image",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.SelectAndOpen("DATE.AND.TIME")
    test.Snap("verify dialog date matches packaged file dates")
    apple2.DHRDarkness()
    a2d.DialogOK()
    test.ExpectEquals(a2d.RepaintType(), "full", "repaint", {snap=true})
    test.Snap("verify dates now Today")
    a2d.SelectAndOpen("DATE.AND.TIME")
    apple2.DHRDarkness()
    a2d.DialogOK()
    test.ExpectEquals(a2d.RepaintType(), "minimal", "repaint", {snap=true})
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1) -- slot 7
    a2d.WaitForRestart()
end)

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
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1) -- slot 7
    a2d.WaitForRestart()

    -- Create new folder
    a2d.OpenPath("/RAM1")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_NEW_FOLDER)
    apple2.ReturnKey()

    -- Change date again to avoid "Today"
    a2d.SetProDOSDate(1999,9,13)

    -- Inspect file
    a2d.SelectPath("/RAM1/NEW.FOLDER")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    test.Snap("verify date matches set previously set date")
    a2d.DialogOK()
    a2d.CloseAllWindows()
end)

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
    for i = 1,24 do
      apple2.UpArrowKey()
      test.Snap("verify 12 hour cycle")
    end
    a2d.DialogOK()
end)

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
    for i = 1,24 do
      apple2.UpArrowKey()
      test.Snap("verify 24 hour cycle")
    end
    a2d.DialogOK()
end)


test.Step(
  "Day ranges",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)

    -- 31 day month
    a2d.SetProDOSDate(2023,1,28)
    a2d.SelectAndOpen("DATE.AND.TIME")
    apple2.UpArrowKey()
    test.Snap("verify 28/Jan/23 wraps to 29/Jan/23")
    apple2.UpArrowKey()
    test.Snap("verify 29/Jan/23 wraps to 30/Jan/23")
    apple2.UpArrowKey()
    test.Snap("verify 30/Jan/23 wraps to 31/Jan/23")
    apple2.UpArrowKey()
    test.Snap("verify 31/Jan/23 wraps to 01/Jan/23")
    a2d.DialogOK()

    -- 30 day month
    a2d.SetProDOSDate(2023,4,28)
    a2d.SelectAndOpen("DATE.AND.TIME")
    apple2.UpArrowKey()
    test.Snap("verify 28/Apr/23 wraps to 29/Apr/23")
    apple2.UpArrowKey()
    test.Snap("verify 29/Apr/23 wraps to 30/Apr/23")
    apple2.UpArrowKey()
    test.Snap("verify 30/Apr/23 wraps to 01/Apr/23")
    a2d.DialogOK()

    -- 28 day month
    a2d.SetProDOSDate(2023,2,28)
    a2d.SelectAndOpen("DATE.AND.TIME")
    apple2.UpArrowKey()
    test.Snap("verify 28/Feb/23 wraps to 01/Feb/23")
    a2d.DialogOK()

    -- 29 day month
    a2d.SetProDOSDate(2024,2,28)
    a2d.SelectAndOpen("DATE.AND.TIME")
    apple2.UpArrowKey()
    test.Snap("verify 28/Feb/24 wraps to 01/Feb/24")
    apple2.UpArrowKey()
    test.Snap("verify 29/Feb/24 wraps to 01/Feb/24")
    a2d.DialogOK()
end)

test.Step(
  "Clicking fields",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("1") -- 12-hour

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(400, 70)
        m.ButtonDown()
        emu.wait(10/60)
        test.Snap("verify up button inverted")
        m.ButtonUp()
        m.MoveByApproximately(0, 10)
        m.ButtonDown()
        emu.wait(10/60)
        test.Snap("verify down button inverted")
        m.ButtonUp()

        m.MoveToApproximately(165,75)
        m.Click()
        test.Snap("verify day focused")
        m.MoveByApproximately(45,0)
        m.Click()
        test.Snap("verify month focused")
        m.MoveByApproximately(40,0)
        m.Click()
        test.Snap("verify year focused")
        m.MoveByApproximately(50,0)
        m.Click()
        test.Snap("verify hour focused")
        m.MoveByApproximately(40,0)
        m.Click()
        test.Snap("verify minute focused")
        m.MoveByApproximately(30,0)
        m.Click()
        test.Snap("verify period focused")
    end)
    a2d.DialogOK()
end)

test.Step(
  "Clicking 24-hour",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("2") -- 24-hour

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(370,75)
        m.Click()
        test.Snap("verify period not focused")
    end)
    a2d.DialogOK()
end)

test.Step(
  "Arrows",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.OAShortcut("1") -- 12-hour

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(250,75) -- year
        m.Click()
        test.Snap("verify year focused")

        m.MoveToApproximately(400, 70) -- up arrow
        m.ButtonDown()
        emu.wait(2/60)
        test.Snap("verify up button inverted")
        m.ButtonUp()
        emu.wait(2/60)
        test.Snap("verify year increments")

        m.MoveByApproximately(0, 10) -- down arrow
        m.ButtonDown()
        emu.wait(2/60)
        test.Snap("verify up button inverted")
        m.ButtonUp()
        emu.wait(2/60)
        test.Snap("verify year decrements")
    end)
    a2d.DialogOK()
end)

test.Step(
  "Today",
  function()
    -- Create file with known date
    a2d.OpenPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.WaitForRestart()
    a2d.SetProDOSDate(1999, 9, 13)
    apple2.TypeLine("CREATE /RAM1/WILL.BE.TODAY")
    apple2.TypeLine("PR#7")
    a2d.WaitForRestart()

    -- Show window and resize/move it
    a2d.OpenPath("/RAM1")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.GrowWindowBy(250,0)
    a2d.MoveWindowBy(0,100)
    test.Snap("verify date is shown in full")

    -- Use Date & Time to set date
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.SetProDOSDate(1998, 9, 13) -- so we know the delta
    a2d.SelectAndOpen("DATE.AND.TIME")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(250,75) -- year
        m.Click()
    end)
    apple2.UpArrowKey()
    apple2.DHRDarkness()
    a2d.DialogOK()
    test.ExpectEquals(a2d.RepaintType(), "full", "repaint", {snap=true})
    test.Snap("verify bottom date shows Today")
end)
