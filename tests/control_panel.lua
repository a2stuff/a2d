--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]--

--[[
  Launch DeskTop. Open the Control Panel DA. Use the pattern editor to
  create a custom pattern, then click the desktop preview to apply it.
  Close the DA. Open the Control Panel DA. Click the right arrow above
  the desktop preview. Verify that the default checkerboard pattern is
  shown.
]]--
test.Step(
  "custom and default pattern",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x+66, dialog_y+24)
        m.ButtonDown()
        m.MoveByApproximately(-20, 0)
        m.MoveByApproximately(0, -10)
        m.MoveByApproximately(20, 0)
        m.MoveByApproximately(0, 10)
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

--[[
  Open the Control Panel DA. Eject the startup disk. Close the DA
  without changing any settings. Verify that you are not prompted to
  save.
]]--
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

--[[
  Open the Control Panel DA. Eject the startup disk. Modify a setting
  and close the DA. Verify that you are prompted to save.
]]--
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

--[[
  Launch DeskTop, invoke Control Panel DA. Under Mouse Tracking,
  toggle Slow and Fast. Verify that the mouse cursor doesn't warp to a
  new position, and that the mouse cursor doesn't flash briefly on the
  left edge of the screen.
]]--
test.Step(
  "Mouse tracking",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.MoveMouse(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
    a2d.OAShortcut("2", {no_wait=true})
    -- NOTE: Mouse shouldn't move at all, but POSMOUSE in emulators is sketch
    a2dtest.MultiSnap(30, "verify mouse cursor doesn't move significantly")
    a2d.OAShortcut("3", {no_wait=true})
    a2dtest.MultiSnap(30, "verify mouse cursor doesn't move significantly")
    a2d.OAShortcut("2", {no_wait=true})
    a2dtest.MultiSnap(30, "verify mouse cursor doesn't move significantly")
end)
