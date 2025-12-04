
--[[============================================================

  "Calendar" tests

  ============================================================]]--

test.Step(
  "Calendar - with real-time clock",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALENDAR")
    a2d.WaitForRepaint()
    test.Snap("verify current month and year")
    a2d.CloseWindow()
end)

test.Step(
  "Calendar - without real-time clock",
  function()
    a2d.RemoveClockDriverAndReboot()

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALENDAR")
    a2d.WaitForRepaint()
    test.Snap("verify month and year match build")
    a2d.CloseWindow()
end)
