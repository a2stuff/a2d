--[[ BEGINCONFIG ========================================

MODEL="apple2gs"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 $HARDIMG -hard2 'NoiseTracker 3.2mg'"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)


--[[
  On a IIgs, launch DeskTop. Launch a IIgs-native program e.g.
  NoiseTracker. Exit and return to DeskTop. Verify that the display is
  not garbled.
]]
test.Step(
  "IIgs native program",
  function()

    -- Enter then exit Control Panel - otherwise NoiseTracker gives
    -- RESTART SYSTEM error on exit.
    -- TODO: Why???
    apple2.PressOA()
    apple2.PressControl()
    apple2.PressShift()
    apple2.EscapeKey()
    apple2.ReleaseShift()
    apple2.ReleaseControl()
    apple2.ReleaseOA()
    emu.wait(5)
    apple2.EscapeKey() -- to Quit
    apple2.ReturnKey()
    emu.wait(5)

    -- NOTE: NoiseTracker requires ROM3, otherwise on quit it gives a
    -- RESTART SYSTEM error
    a2d.OpenPath("/NOISETRACKER/NOISE.SYSTEM")
    emu.wait(10)
    apple2.SpaceKey()
    emu.wait(2)
    a2d.OAShortcut("Q")
    emu.wait(2)
    apple2.Type("Y")
    a2d.WaitForDesktopReady()
end)
