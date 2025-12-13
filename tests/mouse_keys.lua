local file_menu_x, file_menu_y = 30, 5

--[[
  Enter MouseKeys mode. "Pull down" a menu (using Comma) and select an
  item (using Period). Verify that after the item is selected that
  MouseKeys mode is still active. Press Escape to exit MouseKeys mode.
]]
test.Step(
  "Mouse Keys - Pull down menu",
  function()
    a2d.Select("A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.ButtonDown()
        m.MoveByApproximately(0, 25) -- File > Open
        m.ButtonUp()
        a2d.WaitForRepaint()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
        test.Snap("verify cursor at center of screen")
    end)
    test.Expect(a2dtest.GetWindowCount(), 1, "window should have opened")
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Enter MouseKeys mode. "Drop down" a menu (using Space) and select an
  item (using Space). Verify that after the item is selected that
  MouseKeys mode is still active. Press Escape to exit MouseKeys mode.
]]
test.Step(
  "Mouse Keys - Drop down menu",
  function()
    a2d.Select("A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
        m.MoveByApproximately(0, 25) -- File > Open
        m.Click()
        a2d.WaitForRepaint()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
        test.Snap("verify cursor at center of screen")
    end)
    test.Expect(a2dtest.GetWindowCount(), 1, "window should have opened")
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Use the arrow keys to move the mouse to the top, bottom, left, and
  right edges of the screen. Verify that the mouse is clamped to the
  edges and does not wrap.
]]
test.Step(
  "Mouse Keys - screen bounds",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
        m.MoveByApproximately(0, -apple2.SCREEN_HEIGHT)
        test.Snap("verify cursor at top center")
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
        m.MoveByApproximately(0, apple2.SCREEN_HEIGHT)
        test.Snap("verify cursor at bottom center")
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
        m.MoveByApproximately(-apple2.SCREEN_WIDTH, 0)
        test.Snap("verify cursor at left center")
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
        m.MoveByApproximately(apple2.SCREEN_WIDTH, 0)
        test.Snap("verify cursor at right center")
    end)
end)

--[[
  Select an icon. Press the Return key. Verify that Mouse Keys mode is
  not silently exited, and the cursor is not distorted.
]]
test.Step(
  "Mouse Keys - stay in mousekeys mode",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon_x, icon_y)
        m.Click()
        test.Snap("verify icon selected")
        apple2.ReturnKey()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
        test.Snap("verify cursor at screen center")
        m.Click()
    end)
    a2d.ClearSelection()
end)

--[[
  Use keys to click on a menu. Without holding the button down, move
  over the menu items. Verify that the menu does not spontaneously
  close.
]]
test.Step(
  "Mouse Keys - Menu items",
  function()
    a2d.Select("A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
        m.MoveByApproximately(0, apple2.SCREEN_HEIGHT)
        test.Snap("verify menu still open")
        m.Click()
    end)
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Use keys to double-click on an icon. Verify it opens.
]]
test.Step(
  "Mouse Keys - double-click",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    local count = a2dtest.GetWindowCount()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
        a2d.WaitForRepaint()
    end)
    test.ExpectEquals(a2dtest.GetWindowCount(), count+1, "window should have opened")
    a2d.ClearSelection()
end)
