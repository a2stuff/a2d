--[[============================================================

  RGB Display

  ============================================================]]--

test.Step(
  "RGB Color desktop",
  function()
    apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.LeftArrowKey() -- change pattern
    apple2.ControlKey("D") -- set pattern
    a2d.OAShortcut("1") -- check RGB Color
    a2d.CloseWindow()
    test.Snap("verify desktop is in color")
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    emu.wait(5) -- loading time
    test.Snap("verify image is in color")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.Snap("verify desktop is still in color")

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    a2d.OAShortcut("1") -- uncheck RGB Color
    a2d.CloseWindow()
    test.Snap("verify desktop is in monochrome")
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    emu.wait(5) -- loading time
    test.Snap("verify image is in color again")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.Snap("verify desktop is still in monochrome")
end)

test.Step(
  "Mode on exit",
  function()
    apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()
    apple2.TypeLine("HGR : HCOLOR=3 : HPLOT 0,0 TO 100,100")
    emu.wait(5)
    test.Snap("verify a diagonal line is drawn")
end)
