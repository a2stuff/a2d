--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "No prompt if no change",
  function()
    local drive = apple2.Get35Drive1()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")

    local current = drive.filename
    drive:unload()

    a2d.CloseWindow()
    a2d.WaitForRepaint()
    a2dtest.ExpectAlertNotShowing()

    drive:load(current)
    a2d.CloseAllWindows()
end)

test.Step(
  "Prompt if changed",
  function()
    local drive = apple2.Get35Drive1()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    a2d.OAShortcut("5") -- show invisible files (something harmless)

    local current = drive.filename
    drive:unload()

    a2d.CloseWindow()
    a2d.WaitForRepaint()
    a2dtest.ExpectAlertShowing()
    a2d.DialogCancel()

    drive:load(current)
    a2d.CloseAllWindows()
end)

test.Step(
  "Repaints when obscured",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    local x,y = a2dtest.GetFrontWindowDragCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x,y)
        m.ButtonDown()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2,apple2.SCREEN_HEIGHT)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    a2dtest.ExpectNothingChanged(function()
        a2d.OAShortcut("1")
        a2d.OAShortcut("2")
        a2d.OAShortcut("3")
    end)
    a2d.CloseWindow()
    a2d.CloseAllWindows()
end)

test.Step(
  "No crash after running",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    a2d.CloseWindow()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()
    apple2.TypeLine("REM *** Did not crash ***")
    test.Snap("verify no crash to monitor")
end)
