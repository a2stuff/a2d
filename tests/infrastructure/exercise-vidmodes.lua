
--[[============================================================

  Test Script

  ============================================================]]

test.Step(
  "Cycle video modes",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS/EYES")
    apple2.SetMonitorType(apple2.MONITOR_TYPE_COLOR)
    test.Snap("Color")
    apple2.SetMonitorType(apple2.MONITOR_TYPE_AMBER)
    test.Snap("Amber")
    apple2.SetMonitorType(apple2.MONITOR_TYPE_GREEN)
    test.Snap("Green")
    apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)
    test.Snap("Video-7")
end)
