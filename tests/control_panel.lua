--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "custom and default pattern",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(130,60)
        m.ButtonDown()
        m.MoveByApproximately(-20,0)
        m.MoveByApproximately(0,-10)
        m.MoveByApproximately(20,0)
        m.MoveByApproximately(0,10)
        m.ButtonUp()
    end)
    apple2.ControlKey("D")
    a2d.WaitForRepaint()
    a2d.CloseWindow()

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.RightArrowKey()
    test.Snap("verify default checkerboard is shown in preview")
    apple2.ControlKey("D")
    a2d.WaitForRepaint()
    a2d.CloseWindow()
end)


test.Step(
  "No prompt if no change",
  function()
    local drive = apple2.Get35Drive1()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")

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
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    a2d.OAShortcut("9") -- caret blink speed

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
  "Mouse tracking",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.MoveMouse(apple2.SCREEN_WIDTH/2,apple2.SCREEN_HEIGHT/2)
    a2d.OAShortcut("2")
    -- NOTE: Mouse shouldn't move at all, but POSMOUSE in emulators is sketch
    test.MultiSnap(3, "verify mouse cursor doesn't move significantly")
    a2d.OAShortcut("3")
    test.MultiSnap(3, "verify mouse cursor doesn't move significantly")
    a2d.OAShortcut("2")
    test.MultiSnap(3, "verify mouse cursor doesn't move significantly")
end)
