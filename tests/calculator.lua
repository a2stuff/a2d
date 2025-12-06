
--[[============================================================

  "Calculator" tests

  ============================================================]]--

test.Step(
  "Cursor doesn't home",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH*3/4, apple2.SCREEN_HEIGHT/2)
    end)
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR")
    test.Snap("verify cursor not at 0,0")
    a2d.CloseWindow()
end)

test.Step(
  "Move window and mouse cursor",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR")
    local x,y = a2dtest.GetFrontWindowDragCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x,y)
        m.ButtonDown()
        m.MoveToApproximately(400,100)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify mouse cursor painted correctly")
    a2d.CloseWindow()
end)

test.Step(
  "Window and volume icons",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR")
    local x,y = a2dtest.GetFrontWindowDragCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x,y)
        m.ButtonDown()
        m.MoveToApproximately(500,20)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(500,20)
        m.ButtonDown()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2,apple2.SCREEN_HEIGHT)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify volume icons repaint correctly")
    a2d.CloseWindow()
end)

test.Step(
  "Obscured window",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR")
    local x,y = a2dtest.GetFrontWindowDragCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x,y)
        m.ButtonDown()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2,apple2.SCREEN_HEIGHT)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    apple2.Type("123.456")
    test.Snap("verify no bad repaint while obscured")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2,apple2.SCREEN_HEIGHT)
        m.ButtonDown()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2,30)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify display is 123.456")
    a2d.CloseWindow()
end)

test.Variants(
  {
    "Calculator - misc",
    "Sci.Calc - misc",
  },
  function(idx)
    if idx == 1 then
      a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR")
    else
      a2d.OpenPath("/A2.DESKTOP/EXTRAS/SCI.CALC")
    end
    a2d.WaitForRepaint()

    apple2.Type("1-2=")
    a2d.WaitForRepaint()
    apple2.EscapeKey()
    -- should not hang

    apple2.Type("1/2=")
    a2d.WaitForRepaint()
    test.Snap("verify display is 0.5")
    apple2.EscapeKey()

    apple2.Type("0-.5=")
    a2d.WaitForRepaint()
    test.Snap("verify display is -0.5")
    apple2.EscapeKey()

    a2d.CloseWindow()
end)

test.Variants(
  {
    "Calculator - decimal separator",
    "Sci.Calc - decimal separator",
  },
  function(idx)
    if idx == 1 then
      a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR")
    else
      a2d.OpenPath("/A2.DESKTOP/EXTRAS/SCI.CALC")
    end
    a2d.WaitForRepaint()

    apple2.Type("12.34")
    a2d.WaitForRepaint()
    test.Snap("verify display is 12.34 (period)")
    apple2.EscapeKey()

    a2d.CloseWindow()

    function SetNumberFormat(decimal_separator, thousands_separator)
      a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/INTERNATIONAL")
      apple2.TabKey() -- focus date > time
      apple2.TabKey() -- focus time > decimal
      apple2.Type(decimal_separator)
      apple2.TabKey() -- focus decimal > thousands
      apple2.Type(thousands_separator)
      a2d.DialogOK()
    end

    -- Change decimal separator
    SetNumberFormat(",", ".")

    if idx == 1 then
      a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR")
    else
      a2d.OpenPath("/A2.DESKTOP/EXTRAS/SCI.CALC")
    end
    a2d.WaitForRepaint()

    apple2.Type("12,34")
    a2d.WaitForRepaint()
    test.Snap("verify display is 12,34 (comma)")
    apple2.EscapeKey()

    apple2.Type("12.34")
    a2d.WaitForRepaint()
    test.Snap("verify display is 12,34 (comma)")
    apple2.EscapeKey()

    a2d.CloseWindow()

    -- Restore decimal separator
    SetNumberFormat(".", ",")
end)

