
a2d.ConfigureRepaintTime(0.5)

--[[
  Repeat the following case with these modifiers: Open-Apple,
  Solid-Apple:

  Open two windows. Hold modifier and click the close box on the
  active window. Verify that all windows close.
]]
test.Variants(
  {
    "Close all using Open Apple click on close box",
    "Close all using Solid Apple click on close box",
  },
  function(idx)
    a2d.ClearSelection()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", true) -- leave parent open
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        if idx == 1 then
          apple2.PressOA()
        else
          apple2.PressSA()
        end
        m.Click()
        if idx == 1 then
          apple2.ReleaseOA()
        else
          apple2.ReleaseSA()
        end
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)

--[[
  Open two windows. Press Open-Apple+Solid-Apple+W. Verify that all
  windows close. Repeat with Caps Lock off.
]]
test.Variants(
  {
    "Close all using Open Apple + Solid Apple + W",
    "Close all using Open Apple + Solid Apple + w",
  },
  function(idx)
    a2d.ClearSelection()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", true) -- leave parent open
    if idx == 1 then
      a2d.OASAShortcut("W")
    else
      a2d.OASAShortcut("w")
    end
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)

--[[
  Open two windows. Hold Solid-Apple and select File > Close. Verify
  that all windows close.

  Open two windows. Hold Open-Apple and select File > Close. Verify
  that all windows close.
]]
test.Variants(
  {
    "Close all using menu and Solid Apple",
    "Close all using menu and Open Apple",
  },
  function(idx)
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", true) -- leave parent open

    local file_menu_x, file_menu_y = 30, 5
    a2d.InMouseKeysMode(function(m)
        if idx == 1 then
          apple2.PressSA()
        else
          apple2.PressOA()
        end

        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
        m.MoveByApproximately(0, 35) -- File > Close
        m.Click()

        if idx == 1 then
          apple2.ReleaseSA()
        else
          apple2.ReleaseOA()
        end
    end)
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)

--[[
  Open two windows. Hold Open-Apple and open the File menu, then press
  Open-Apple+Solid-Apple+W. Verify that all windows close. Repeat with
  Caps Lock off.
]]
test.Variants(
  {
    "Close all using Open Apple + Solid Apple + W, with File menu open",
    "Close all using Open Apple + Solid Apple + w, with File menu open",
  },
  function(idx)
    a2d.OpenPath("/A2.DESKTOP/EXTRAS") -- leave parent open
    a2d.OpenMenu(a2d.FILE_MENU)
    if idx == 1 then
      a2d.OASAShortcut("W")
    else
      a2d.OASAShortcut("w")
    end
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)

--[[
  Open two windows. Hold Solid-Apple and open the File menu, then
  press Open-Apple+Solid-Apple+W. Verify that all windows close.
  Repeat with Caps Lock off.
]]
test.Variants(
  {
    "Holding SA open menu, then OA+SA+W",
    "Holding SA open menu, then OA+SA+w",
  },
  function(idx)
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", true) -- leave parent open

    local file_menu_x, file_menu_y = 30, 5
    a2d.InMouseKeysMode(function(m)
        apple2.PressSA()
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
    end)

    if idx == 1 then
      a2d.OASAShortcut("W")
    else
      a2d.OASAShortcut("w")
    end
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)
