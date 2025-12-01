--[[============================================================

  "Real-Time Clock" tests

  ============================================================]]--

test.Step(
  "Clock appears in top right",
  function()
    test.Snap("verify clock is in top-right of screen")
end)

test.Step(
  "Clock paints correctly after volume selected",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    emu.wait(10)
    test.Snap("verify clock is in top-right of screen")
end)

