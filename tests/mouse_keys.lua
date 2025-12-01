test.Step(
  "Mouse Keys - Pull down menu",
  function()
    a2d.Select("A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(40,10) -- File
        m.ButtonDown()
        m.MoveByApproximately(0,20) -- File > Open
        m.ButtonUp()
        a2d.WaitForRepaint()
        m.MoveToApproximately(560/2, 192/2)
        test.Snap("verify cursor at center of screen")
    end)
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Mouse Keys - Drop down menu",
  function()
    a2d.Select("A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(40,10) -- File
        m.Click()
        m.MoveByApproximately(0,20) -- File > Open
        m.Click()
        a2d.WaitForRepaint()
        m.MoveToApproximately(560/2, 192/2)
        test.Snap("verify cursor at center of screen")
    end)
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Mouse Keys - screen bounds",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(560/2, 192/2)
        m.MoveByApproximately(0,-192)
        test.Snap("verify cursor at top center")
        m.MoveToApproximately(560/2, 192/2)
        m.MoveByApproximately(0,192)
        test.Snap("verify cursor at bottom center")
        m.MoveToApproximately(560/2, 192/2)
        m.MoveByApproximately(-560,0)
        test.Snap("verify cursor at left center")
        m.MoveToApproximately(560/2, 192/2)
        m.MoveByApproximately(560,0)
        test.Snap("verify cursor at right center")
    end)
end)

local vol_icon_x = 520
local vol_icon_y = 25

test.Step(
  "Mouse Keys - stay in mousekeys mode",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.Click()
        test.Snap("verify icon selected")
        apple2.ReturnKey()
        m.MoveToApproximately(560/2, 192/2)
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
        m.MoveToApproximately(40,10) -- File
        m.Click()
        m.MoveByApproximately(0,192)
        test.Snap("verify menu still open")
        m.Click()
    end)
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Mouse Keys - double-click",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.DoubleClick()
        a2d.WaitForRepaint()
        test.Snap("verify window opened")
    end)
    a2d.ClearSelection()
end)
