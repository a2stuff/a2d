--[[ BEGINCONFIG ========================================

MODEL="apple2gs"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 $HARDIMG"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  On a IIgs, go to Control Panel, check RGB Color. Verify that the
  display shows in color. Special > Copy Disk.... Enter the IIgs
  control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that
  the display remains in color.
]]
test.Step(
  "RGB Color vs. IIgs Control Panel",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    a2d.OAShortcut("1") -- check RGB Color
    a2d.CloseWindow()

    a2d.CopyDisk()
    test.Expect(apple2.IsColor(), "desktop should be in color")

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

    test.Expect(apple2.IsColor(), "desktop should be in color")

    -- cleanup
    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    a2d.OAShortcut("1") -- uncheck RGB Color
    a2d.CloseWindow()
end)

--[[
  On a IIgs, go to Control Panel, uncheck RGB Color. Verify that the
  display shows in monochrome. Special > Copy Disk.... Enter the IIgs
  control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that
  the display resets to monochrome.
]]
test.Step(
  "RGB Monochrome vs. IIgs Control Panel",
  function()
    a2d.CopyDisk()
    test.Expect(apple2.IsMono(), "desktop should be in monochrome")

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

    test.Expect(apple2.IsMono(), "desktop should be in monochrome")

    -- cleanup
    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
end)
