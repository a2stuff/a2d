test.Step(
  "Solid Apple Double-Click",
  function()
    a2d.OpenPath("/A2.DESKTOP")

    -- Over "Extras"
    local window_x,window_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+30,window_x+85)
    end)

    apple2.PressSA()
    apple2.DoubleClickMouseButton()
    a2d.WaitForRepaint()
    apple2.ReleaseSA()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")

    a2d.Reboot()
end)

test.Step(
  "Solid Apple File > Open",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")

    apple2.MoveMouse(30, 5)
    apple2.PressSA()
    apple2.ClickMouseButton()
    apple2.MoveMouse(30, 40)
    apple2.ClickMouseButton()
    apple2.ReleaseSA()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")

    apple2.MoveMouse(0,0)
    a2d.Reboot()
end)

test.Step(
  "Open Apple File > Open",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")

    apple2.MoveMouse(30, 5)
    apple2.PressOA()
    apple2.ClickMouseButton()
    apple2.MoveMouse(30, 40)
    apple2.ClickMouseButton()
    apple2.ReleaseOA()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")

    apple2.MoveMouse(0,0)
    a2d.Reboot()
end)

test.Variants(
  {
    "Open Apple + Solid Apple + O",
    "Open Apple + Solid Apple + o",
  },
  function(idx)
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")

    if idx == 1 then
      a2d.OASAShortcut("O")
    else
      a2d.OASAShortcut("o")
    end

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")

    a2d.Reboot()
end)

test.Step(
  "Open Apple + Solid Apple + Down",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")

    apple2.PressOA()
    apple2.PressSA()
    apple2.DownArrowKey()
    emu.wait(1/60)
    apple2.ReleaseOA()
    apple2.ReleaseSA()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")

    a2d.Reboot()
end)

test.Variants(
  {
    "With menu showing, Open Apple + Solid Apple + O",
    "With menu showing, Open Apple + Solid Apple + o",
  },
  function(idx)
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(30, 5)
    end)
    apple2.ClickMouseButton() -- if MK is used, menus remember modifier

    if idx == 1 then
      a2d.OASAShortcut("O")
    else
      a2d.OASAShortcut("o")
    end
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")

    a2d.Reboot()
end)

test.Step(
  "No selection, OA+SA+O",
  function()
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.OASAShortcut("O")
    end)
end)

test.Step(
  "No selection, OA+SA+Down",
  function()
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        apple2.PressOA()
        apple2.PressSA()
        apple2.DownArrowKey()
        emu.wait(1/60)
        apple2.ReleaseOA()
        apple2.ReleaseSA()

        a2d.WaitForRepaint()
    end)
end)

