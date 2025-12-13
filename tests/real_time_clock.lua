--[[
  Run on system with real-time clock; verify that time shows in
  top-right of menu.
]]
test.Step(
  "Clock appears in top right",
  function()
    test.Snap("verify clock is in top-right of screen")
end)

--[[
  Run on system with real-time clock. Click on a volume icon. Verify
  that the clock still renders correctly.
]]
test.Step(
  "Clock paints correctly after volume selected",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    emu.wait(10)
    test.Snap("verify clock is in top-right of screen")
end)

