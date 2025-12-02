--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS="-ramsize 1152K -gameio joy"
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]--

emu.wait(50) -- IIc emulation is very slow

test.Step(
  "No prompt if no change",
  function()
    local drive = apple2.Get35Drive1()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")

    local current = drive.filename
    drive:unload()

    a2d.CloseWindow()
    a2d.WaitForRepaint()
    test.Snap("verify no prompt to save")

    drive:load(current)
    a2d.CloseAllWindows()
end)

test.Step(
  "Prompt if changed",
  function()
    local drive = apple2.Get35Drive1()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    a2d.OAShortcut("5") -- show invisible files

    local current = drive.filename
    drive:unload()

    a2d.CloseWindow()
    a2d.WaitForRepaint()
    test.Snap("verify prompt to save")
    a2d.DialogCancel()

    drive:load(current)
    a2d.CloseAllWindows()
end)

test.Step(
  "Repaints when obscured",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(280, 45)
        m.ButtonDown()
        m.MoveToApproximately(280,192)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    a2d.OAShortcut("1")
    a2d.OAShortcut("2")
    a2d.OAShortcut("3")
    test.Snap("verify no mispaints")
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
    test.Snap("verify no crash to monitor")
end)
