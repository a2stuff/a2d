test.Step(
  "Move Mouse",
  function()
    -- Move the mouse
    apple2.MoveMouse(480, 170)
    test.Snap("Mouse to 480,170")

    -- Move the mouse
    apple2.MoveMouse(0, 0)
    test.Snap("Mouse to 0,0")
end)
