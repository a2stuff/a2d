--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 superdrive"
DISKARGS="-flop1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)
local s6d1 = manager.machine.images[":sl6:superdrive:fdc:0:35hd"]

--[[
  Open the Options DA. Eject the startup disk. Close the DA without
  changing any settings. Verify that you are not prompted to save.
]]
test.Step(
  "No prompt if no change",
  function()
    local drive = s6d1
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")

    local current = drive.filename
    drive:unload()

    a2d.CloseWindow()
    a2d.WaitForRepaint()
    a2dtest.ExpectAlertNotShowing()

    drive:load(current)
    a2d.CloseAllWindows()
end)

--[[
  Open the Options DA. Eject the startup disk. Modify a setting and
  close the DA. Verify that you are prompted to save.
]]
test.Step(
  "Prompt if changed",
  function()
    local drive = s6d1
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    a2d.OAShortcut("5") -- show invisible files (something harmless)

    local current = drive.filename
    drive:unload()

    a2d.CloseWindow()
    a2dtest.WaitForAlert()
    a2d.DialogCancel()

    drive:load(current)
    a2d.CloseAllWindows()
end)

--[[
  Open the Options DA. Move the window to the bottom of the screen so
  only the title bar is visible. Press Apple-1, Apple-2, Apple-3.
  Verify that checkboxes don't mis-paint on the screen. Move the
  window back up. Verify that the state of the checkboxes has toggled.
]]
test.Step(
  "Repaints when obscured",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    local x, y = a2dtest.GetFrontWindowDragCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT)
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

--[[
  Open the Options DA. Close the DA. Apple Menu > Run Basic Here.
  Verify that the system does not crash to the monitor.
]]
test.Step(
  "No crash after running",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    a2d.CloseWindow()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("REM *** Did not crash ***")
    test.Expect(apple2.GrabTextScreen():match("Did not crash"), "should not crash")
end)
