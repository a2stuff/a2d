--[[
  Resize window. Verify scrollbars don't repaint before the rest of
  the window if their activation state changes.
]]
test.Step(
  "Scrollbars don't repaint early on resize",
  function()
    desktop.OpenWindow("/A2.DESKTOP")

    desktop.GrowWindowBy(-apple2.SCREEN_WIDTH, -apple2.SCREEN_HEIGHT, {no_wait=true})
    a2dtest.MultiSnap(30, "verify scrollbars don't paint before window")

    desktop.GrowWindowBy(apple2.SCREEN_WIDTH, apple2.SCREEN_HEIGHT, {no_wait=true})
    a2dtest.MultiSnap(30, "verify scrollbars don't paint before window")
end)
