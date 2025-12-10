--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Alert shown during File > Get Info if disk ejected, Try Again works",
  function()
    local drive = apple2.Get35Drive1()
    local current = drive.filename

    a2d.SelectPath("/A2.DESKTOP")
    a2d.OAShortcut("I", {no_wait=true})
    emu.wait(1)
    drive:unload()

    a2dtest.WaitForAlert()
    drive:load(current)
    apple2.Type("A") -- try again
    emu.wait(20) -- floppies are slow
    test.Snap("verify enumeration completed and no mispaints")
    a2d.DialogOK()
end)

