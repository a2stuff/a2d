--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa202 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

function OASA(func)
  apple2.PressOA()
  apple2.PressSA()
  func()
  apple2.ReleaseOA()
  apple2.ReleaseSA()
  a2d.WaitForRepaint()
end

test.Step(
  "Escape exits text preview",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.Snap("verify preview exited")
end)

test.Step(
  "Space toggles modes",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")

    apple2.SpaceKey() -- toggle modes
    a2d.WaitForRepaint()
    test.Snap("verify fixed mode")

    apple2.SpaceKey() -- toggle modes
    a2d.WaitForRepaint()
    test.Snap("verify proportional mode")

    a2d.CloseWindow()
end)

test.Step(
  "Click toggles modes",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(500, 20)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify fixed mode")
    test.Snap("verify label baseline aligns with window title")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(500, 20)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify proportional mode")
    test.Snap("verify label baseline aligns with window title")

    a2d.CloseWindow()
end)

test.Step(
  "Selection retained",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")
    a2d.CloseWindow()
    test.Snap("verify selection not cleared on exit")
end)

test.Step(
  "Short file keeps scrollbar inactive",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/SHORT.TEXT")
    test.Snap("verify scrollbar inactive")
    apple2.SpaceKey() -- toggle modes
    a2d.WaitForRepaint()
    test.Snap("verify scrollbar inactive")
    a2d.CloseWindow()
end)

test.Step(
  "Long file and scrolling",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/LONG.TEXT")
    test.Snap("verify scrollbar active")

    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled down by one line")

    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled up by one line")

    apple2.PressOA()
    apple2.DownArrowKey()
    apple2.ReleaseOA()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled down by one page")

    apple2.PressOA()
    apple2.UpArrowKey()
    apple2.ReleaseOA()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled up by one page")

    apple2.PressSA()
    apple2.DownArrowKey()
    apple2.ReleaseSA()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled down by one page")

    apple2.PressSA()
    apple2.UpArrowKey()
    apple2.ReleaseSA()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled up by one page")

    OASA(apple2.DownArrowKey)
    test.Snap("verify scrolled to end")

    OASA(apple2.UpArrowKey)
    test.Snap("verify scrolled to start")

    OASA(apple2.DownArrowKey)
    apple2.SpaceKey() -- toggle mode
    a2d.WaitForRepaint()
    test.Snap("verify scrolled to top")

    a2d.CloseWindow()
end)

test.Step(
  "Touching thumb doesn't cause repaint",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/LONG.TEXT")

    apple2.PressSA()
    for i = 1,70 do
      apple2.DownArrowKey()
    end
    apple2.ReleaseSA()
    a2d.WaitForRepaint()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(530,100)
        a2dtest.ExpectNoRepaint(function()
            m.ButtonDown()
            emu.wait(10/60)
            test.Snap("verify thumb highlighted")
            m.ButtonUp()
            a2d.WaitForRepaint()
        end)
    end)
    a2d.CloseWindow()
    a2d.Restart()
end)

test.Step(
  "Scroll is proportional",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/LONG.TEXT")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(530,40)
        m.ButtonDown()
        m.MoveByApproximately(0,60)
        m.ButtonUp()
    end)
    test.Snap("verify scrolled to about halfway through file")

    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled up one line")

    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled down one line")

    a2d.CloseWindow()
end)

test.Step(
  "Performance: First page displays immediately",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(280,96)
    end)

    -- Disable ZIP Chip
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    apple2.Type("N")
    a2d.CloseWindow()

    a2d.SelectPath("/TESTS/FILE.TYPES/LONG.TEXT")
    a2d.OADown()
    emu.wait(3)
    test.Snap("verify text is displayed within 3s")
    emu.wait(15) -- let loading finish
    a2d.CloseWindow()

    -- Enable ZIP Chip
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    apple2.Type("F")
    a2d.CloseWindow()
end)

test.Step(
  "Tabs",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TABS")
    test.Snap("verify all lines displayed correctly")
    a2d.CloseWindow()
end)

test.Step(
  "Scroll edge case",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/SUDOKU.STORY")
    apple2.SpaceKey() -- toggle to Fixed
    a2d.WaitForRepaint()
    for i = 1,16 do
      apple2.DownArrowKey()
    end
    test.Snap("verify 'with' on last line")
    apple2.DownArrowKey()
    test.Snap("verify scrolled down one line")
    OASA(apple2.DownArrowKey)
    test.Snap("verify scrolled to bottom of file")
    a2d.CloseWindow()
end)

test.Step(
  "Toggling and scrollbar",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")
    apple2.SpaceKey() -- toggle to Fixed
    a2d.WaitForRepaint()
    test.Snap("verify scrollbar active and at top")

    OASA(apple2.DownArrowKey)
    apple2.SpaceKey() -- toggle to Proportional
    a2d.WaitForRepaint()
    test.Snap("verify scrollbar inactive")
end)
