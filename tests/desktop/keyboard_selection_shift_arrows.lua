--[[ BEGINCONFIG ========================================

MODEL="apple2ep"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

function ShiftRight()
  apple2.PressShift()
  emu.wait(0.25) -- during keyboard sequence
  apple2.RightArrowKey()
  emu.wait(0.25) -- during keyboard sequence
  apple2.ReleaseShift()
  a2dtest.WaitForSystemTask()
end
function ShiftLeft()
  apple2.PressShift()
  emu.wait(0.25) -- during keyboard sequence
  apple2.LeftArrowKey()
  emu.wait(0.25) -- during keyboard sequence
  apple2.ReleaseShift()
  a2dtest.WaitForSystemTask()
end
function ShiftUp()
  apple2.PressShift()
  emu.wait(0.25) -- during keyboard sequence
  apple2.UpArrowKey()
  emu.wait(0.5) -- during keyboard sequence
  apple2.ReleaseShift()
  a2dtest.WaitForSystemTask()
end
function ShiftDown()
  apple2.PressShift()
  emu.wait(0.25) -- during keyboard sequence
  apple2.DownArrowKey()
  emu.wait(0.5) -- during keyboard sequence
  apple2.ReleaseShift()
  a2dtest.WaitForSystemTask()
end

test.Step(
  "Icon view - Shift+Arrow selection - starting with no selection",
  function()
    desktop.OpenWindow("/TESTS/SELECTION/SHIFT.ARROWS")
    a2dtest.WaitForSystemTask()

    desktop.ClearSelection()
    ShiftDown()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "A", "first should be selected")

    desktop.ClearSelection()
    ShiftRight()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "A", "first should be selected")

    desktop.ClearSelection()
    ShiftUp()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "Z", "first should be selected")

    desktop.ClearSelection()
    ShiftLeft()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "Z", "first should be selected")
end)

test.Step(
  "List view - Shift+Arrow selection - starting with no selection",
  function()
    desktop.OpenWindow("/TESTS/SELECTION/SHIFT.ARROWS")
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)

    desktop.ClearSelection()
    ShiftDown()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "A", "first should be selected")

    desktop.ClearSelection()
    ShiftUp()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "Z", "first should be selected")

    desktop.ClearSelection()
    ShiftRight()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 0, "no icons should be selected")

    desktop.ClearSelection()
    ShiftLeft()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 0, "no icons should be selected")
end)

test.Step(
  "Icon view - Shift+Arrow selection - starting with everything selected",
  function()
    desktop.OpenWindow("/TESTS/SELECTION/SHIFT.ARROWS")
    a2dtest.WaitForSystemTask()

    desktop.SelectAll()
    local count = #desktop.GetSelectedIcons()

    ShiftDown()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not change")

    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not change")

    ShiftUp()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not change")

    ShiftLeft()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not change")
end)

test.Step(
  "List view - Shift+Arrow selection - starting with everything selected",
  function()
    desktop.OpenWindow("/TESTS/SELECTION/SHIFT.ARROWS")
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)

    desktop.SelectAll()
    local count = #desktop.GetSelectedIcons()

    ShiftDown()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not change")

    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not change")

    ShiftUp()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not change")

    ShiftLeft()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not change")
end)

test.Step(
  "Icon view - Shift+Arrow selection - incremental selection",
  function()
    desktop.OpenWindow("/TESTS/SELECTION/SHIFT.ARROWS")
    a2dtest.WaitForSystemTask()

    --  A  B  C  D  E
    --  F  G  H  I  J
    --  K  L  M  N  O
    --  P  Q  R  S  T
    --  U  V  W  X  Y
    --  Z

    desktop.ClearSelection()

    local count = 0

    -- A...E
    for i = 1, 5 do
      ShiftRight()
      count = count + 1
      test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")
    end

    -- [A][B][C][D][E]
    --  F  G  H  I  J
    --  K  L  M  N  O
    --  P  Q  R  S  T
    --  U  V  W  X  Y
    --  Z

    -- J...Y
    for i = 1, 4 do
      ShiftDown()
      count = count + 1
      test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")
    end

    -- [A][B][C][D][E]
    --  F  G  H  I [J]
    --  K  L  M  N [O]
    --  P  Q  R  S [T]
    --  U  V  W  X [Y]
    --  Z

    -- X...U
    for i = 1, 4 do
      ShiftLeft()
      count = count + 1
      test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")
    end

    -- [A][B][C][D][E]
    --  F  G  H  I [J]
    --  K  L  M  N [O]
    --  P  Q  R  S [T]
    -- [U][V][W][X][Y]
    --  Z

    -- P...F
    for i = 1, 3 do
      ShiftUp()
      count = count + 1
      test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")
    end

    -- [A][B][C][D][E]
    -- [F] G  H  I [J]
    -- [K] L  M  N [O]
    -- [P] Q  R  S [T]
    -- [U][V][W][X][Y]
    --  Z

    -- F...U - already selected, so no change
    for i = 1, 3 do
      ShiftDown()
      test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not grow")
    end

    -- Z
    ShiftDown()
    count = count + 1
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")

    -- [A][B][C][D][E]
    -- [F] G  H  I [J]
    -- [K] L  M  N [O]
    -- [P] Q  R  S [T]
    -- [U][V][W][X][Y]
    -- [Z]

    -- no-op since it doesn't have anything to right/left/down
    ShiftRight()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not grow")
    ShiftLeft()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not grow")
    ShiftDown()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not grow")

    -- U - already selected so no change
    ShiftUp()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not grow")

    -- V - already selected so no change
    ShiftRight()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not grow")

    -- Q
    ShiftUp()
    count = count + 1
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")

    -- [A][B][C][D][E]
    -- [F] G  H  I [J]
    -- [K] L  M  N [O]
    -- [P][Q] R  S [T]
    -- [U][V][W][X][Y]
    --  Z
end)

test.Step(
  "List view - Shift+Arrow selection - incremental selection",
  function()
    desktop.OpenWindow("/TESTS/SELECTION/SHIFT.ARROWS")
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)

    -- Top down
    desktop.ClearSelection()
    local count = 0

    for i = 1, 10 do
      ShiftDown()
      count = count + 1
      test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")
    end
    ShiftUp()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should no grow")

    -- Bottom up
    desktop.ClearSelection()
    local count = 0

    for i = 1, 10 do
      ShiftUp()
      count = count + 1
      test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")
    end
    ShiftDown()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should not grow")

    -- Middle up then down
    desktop.ClearSelection()
    apple2.Type("M")
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "single icon should be selected")
    count = 1

    for i = 1, 10 do
      ShiftUp()
      count = count + 1
      test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")
    end

    for i = 1, 10 do
      ShiftDown()
      count = count + 1
      test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")
    end
end)

test.Step(
  "List view - Shift+Arrow selection - with gaps",
  function()
    desktop.OpenWindow("/TESTS/SELECTION/SHIFT.ARROWS")
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)

    desktop.Select("C")
    local c_x, c_y = a2dtest.GetSelectedIconCoords()

    desktop.Select("E")
    local e_x, e_y = a2dtest.GetSelectedIconCoords()

    desktop.Select("G")

    a2d.InMouseKeysMode(function(m)
        apple2.PressShift()
        m.MoveToApproximately(c_x, c_y)
        m.Click()
        m.MoveToApproximately(e_x, e_y)
        m.Click()
        apple2.ReleaseShift()
    end)

    local count = 3
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should start off with 3")

    for i = 1, 2 do
      ShiftDown()
      count = count + 1
      test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")
    end

    for i = 1, 3 do
      ShiftUp()
      count = count + 1
      test.ExpectEquals(#desktop.GetSelectedIcons(), count, "selection should grow")
    end
end)
