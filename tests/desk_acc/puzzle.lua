
--[[
  Launch DeskTop. Apple Menu > Puzzle. Verify that the puzzle does not
  show as scrambled until the mouse button is clicked on the puzzle or
  a key is pressed. Repeat and verify that the puzzle is scrambled
  differently each time.
]]
test.Step(
  "Puzzle not initially scrambled, and scrambles differently",
  function()
    desktop.SelectPath("/A2.DESKTOP/APPLE.MENU/TOYS/PUZZLE", {no_validate=true})
    desktop.OpenSelection()
    a2dtest.ExpectNothingChanged(function()
        -- close without scrambling
        apple2.EscapeKey()
        a2dtest.WaitForSystemTask()
        -- re-launches not scrambled
        desktop.OpenSelection()
    end)

    a2dtest.ExpectRepaintFraction(
      0.04, 0.09,
      function()
        apple2.SpaceKey()
        a2dtest.WaitForSystemTask()
      end,
      "should scramble on key")

    desktop.CloseWindow()
    desktop.OpenSelection()

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + h / 2)
    end)

    a2dtest.ExpectRepaintFraction(
      0.04, 0.09,
      function()
        a2d.InMouseKeysMode(function(m) m.Click() end)
        a2dtest.WaitForSystemTask()
      end,
      "should scramble on click")

    desktop.CloseWindow()
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Apple Menu > Puzzle. Verify that you can move and
  close the window using the title bar before the puzzle is scrambled.
]]
test.Step(
  "Puzzle can be moved and closed with mouse without having to scramble first",
  function()
    desktop.InvokePath("/A2.DESKTOP/APPLE.MENU/TOYS/PUZZLE")

    local id = mgtk.FrontWindow()
    local x1, y1 = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x1, y1)
        m.ButtonDown()
        m.MoveByApproximately(50, 50)
        m.ButtonUp()
        a2dtest.WaitForSystemTask()
    end)
    local x2, y2 = a2dtest.GetFrontWindowDragCoords()
    test.ExpectNotEquals(x1, x2, "window should have moved")
    test.ExpectNotEquals(y1, y2, "window should have moved")
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
        a2dtest.WaitForSystemTask()
    end)
    test.ExpectNotEquals(mgtk.FrontWindow(), id, "window should have closed")
end)

--[[
  Launch DeskTop. Apple Menu > Puzzle. Verify that you can close the
  window using Esc or Apple+W before the puzzle is scrambled.
]]
test.Step(
  "Puzzle can be closed with keyboard without having to scramble first",
  function()
    desktop.InvokePath("/A2.DESKTOP/APPLE.MENU/TOYS/PUZZLE")
    local id = mgtk.FrontWindow()
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
    test.ExpectNotEquals(mgtk.FrontWindow(), id, "window should have closed")

    desktop.InvokePath("/A2.DESKTOP/APPLE.MENU/TOYS/PUZZLE")
    local id = mgtk.FrontWindow()
    a2d.OAShortcut("W")
    a2dtest.WaitForSystemTask()
    test.ExpectNotEquals(mgtk.FrontWindow(), id, "window should have closed")
end)

--[[
  Launch DeskTop. Apple Menu > Puzzle. Scramble the puzzle. Move the
  window so that only the title bar of the window is visible on
  screen. Use the arrow keys to move puzzle pieces. Verify that the
  puzzle pieces don't mispaint on the desktop.
]]
test.Step(
  "Obscured window does not mispaint",
  function()
    desktop.InvokePath("/A2.DESKTOP/APPLE.MENU/TOYS/PUZZLE")

    -- scramble
    apple2.SpaceKey()
    a2dtest.WaitForSystemTask()

    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT)
        m.ButtonUp()
        a2dtest.WaitForSystemTask()
    end)

    a2dtest.ExpectNothingChanged(function()
        for i = 1, 10 do
          apple2.DownArrowKey()
          a2dtest.WaitForSystemTask()
          apple2.LeftArrowKey()
          a2dtest.WaitForSystemTask()
          apple2.UpArrowKey()
          a2dtest.WaitForSystemTask()
          apple2.RightArrowKey()
          a2dtest.WaitForSystemTask()
        end
    end)
end)
