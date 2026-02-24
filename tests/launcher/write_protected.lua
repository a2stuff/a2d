--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 superdrive"
DISKARGS="-flop1 $ROHARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[
  Boot with an 800K image that is write protected. Make sure DeskTop
  starts.
]]
test.Step(
  "Launcher - write protected",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    a2d.OAShortcut("I") -- File > Get Info
    emu.wait(5)
    test.ExpectMatch(a2dtest.OCRScreen(), "Write protected: +Yes", "should be write protected")
    apple2.EscapeKey() -- cancel enumeration (if it's still happening)
    a2d.CloseWindow()
end)

--[[
  Boot with an 800K image that is write protected. File > Quit. Verify
  that DeskTop restarts (since ProDOS QUIT code couldn't be saved).
]]
test.Step(
  "File > Quit just relaunches",
  function()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
    a2dtest.ExpectNotHanging()
end)
