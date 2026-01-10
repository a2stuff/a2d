a2d.ConfigureRepaintTime(0.25)

--[[
  Resize window. Verify scrollbars don't repaint before the rest of
  the window if their activation state changes.
]]
test.Step(
  "Scrollbars don't repaint early on resize",
  function()
    a2d.OpenPath("/A2.DESKTOP")

    a2d.GrowWindowBy(-apple2.SCREEN_WIDTH, -apple2.SCREEN_HEIGHT, {no_wait=true})
    a2dtest.MultiSnap(30, "verify scrollbars don't paint before window")

    a2d.GrowWindowBy(apple2.SCREEN_WIDTH, apple2.SCREEN_HEIGHT, {no_wait=true})
    a2dtest.MultiSnap(30, "verify scrollbars don't paint before window")
end)
