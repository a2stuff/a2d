--[[
  On an RGB system (IIgs, etc), go to Control Panel, check RGB Color.
  Verify that the display shows in color. Preview an image, and verify
  that the image shows in color and the DeskTop remains in color after
  exiting.

  On an RGB system (IIgs, etc), go to Control Panel, uncheck RGB
  Color. Verify that the display shows in monochrome. Preview an
  image, and verify that the image shows in color and the DeskTop
  returns to monochrome after exiting.
]]
test.Step(
  "RGB Color desktop",
  function()
    apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)

    desktop.InvokePath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.LeftArrowKey() -- change pattern
    apple2.ControlKey("D") -- Set Desktop Pattern
    a2d.OAShortcut("1") -- check RGB Color
    desktop.CloseWindow()
    test.Expect(apple2.IsColor(), "desktop should be in color")
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/ROOM", {no_wait=true})
    emu.wait(5) -- loading time for fullscreen DA
    test.Expect(apple2.IsColor(), "image should be in in color")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
    test.Expect(apple2.IsColor(), "desktop should still be in color")

    desktop.InvokePath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    a2d.OAShortcut("1") -- uncheck RGB Color
    desktop.CloseWindow()
    test.Expect(apple2.IsMono(), "image should be in in monochrome")
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/ROOM", {no_wait=true})
    emu.wait(5) -- loading time for fullscreen DA
    test.Expect(apple2.IsColor(), "image should be in in color")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
    test.Expect(apple2.IsMono(), "desktop should be in monochrome")
end)

--[[
  Using MAME (e.g. via Ample), configure a system with Machine
  Configuration > Monitor Type > Video-7 RGB. Start DeskTop. Open a
  window. Apple Menu > Run Basic Here. Type `HGR : HCOLOR=3 : HPLOT
  0,0 TO 100,100`. Verify a diagonal line appears.
]]
test.Step(
  "Mode on exit",
  function()
    apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)
    desktop.OpenWindow("/A2.DESKTOP")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("HGR : HCOLOR=3 : HPLOT 0,0 TO 100,100")
    emu.wait(5) -- automating BASIC prompt
    test.Snap("verify a diagonal line is drawn")
end)
