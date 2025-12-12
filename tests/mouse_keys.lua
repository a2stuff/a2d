local file_menu_x, file_menu_y = 30, 5

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
