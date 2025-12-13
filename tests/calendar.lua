
--[[============================================================

  "Calendar" tests

  ============================================================]]--

--[[
  Configure a system with a real-time clock. Launch DeskTop. Run the
  Calendar DA. Verify that it starts up showing the current month and
  year correctly.
]]--
test.Step(
  "Calendar - with real-time clock",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALENDAR")
    a2d.WaitForRepaint()
    test.Snap("verify current month and year")
    a2d.CloseWindow()
end)

--[[
  Configure a system without a real-time clock. Launch DeskTop. Run
  the Calendar DA. Verify that it starts up showing the build's
  release month and year correctly.
]]--
test.Step(
  "Calendar - without real-time clock",
  function()
    a2d.RemoveClockDriverAndReboot()

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALENDAR")
    a2d.WaitForRepaint()
    test.Snap("verify month and year match build")
    a2d.CloseWindow()
end)
