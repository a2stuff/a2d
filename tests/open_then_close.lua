test.Step(
  "Solid Apple Double-Click",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    -- Over "Extras"
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        apple2.PressSA()
        m.DoubleClick()
        apple2.ReleaseSA()
    end)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

test.Step(
  "Solid Apple File > Open",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        apple2.PressSA()
        m.Click()
        m.MoveByApproximately(0, 25)
        m.Click()
        apple2.ReleaseSA()
    end)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

test.Step(
  "Open Apple File > Open",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(30, 5)
        apple2.PressOA()
        m.Click()
        m.MoveByApproximately(0, 25)
        m.Click()
        apple2.ReleaseOA()
    end)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
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
end)

test.Step(
  "Open Apple + Solid Apple + Down",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.OASADown()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
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
        m.Click()
    end)

    if idx == 1 then
      a2d.OASAShortcut("O")
    else
      a2d.OASAShortcut("o")
    end
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
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
        a2d.OASADown()
        a2d.WaitForRepaint()
    end)
end)

