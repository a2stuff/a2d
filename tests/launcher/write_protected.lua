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
    util.WaitFor(
      "write protected label",
      function()
        return a2dtest.OCRScreen():match("Write protected: +Yes")
    end)
    apple2.EscapeKey() -- cancel enumeration
    emu.wait(5)
    a2d.DialogCancel()
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
