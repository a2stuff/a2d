--[[ BEGINCONFIG ========================================

MODEL="apple2ep"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

function ShiftRight()
  apple2.PressShift()
  apple2.RightArrowKey()
  apple2.ReleaseShift()
  emu.wait(0.5)
end
function ShiftLeft()
  apple2.PressShift()
  apple2.LeftArrowKey()
  apple2.ReleaseShift()
  emu.wait(0.5)
end
function ShiftUp()
  apple2.PressShift()
  apple2.UpArrowKey()
  apple2.ReleaseShift()
  emu.wait(0.5)
end
function ShiftDown()
  apple2.PressShift()
  apple2.DownArrowKey()
  apple2.ReleaseShift()
  emu.wait(0.5)
end

test.Step(
  "Icon view - Shift+Arrow selection - starting with no selection",
  function()
    a2d.OpenPath("/TESTS/SELECTION/SHIFT.ARROWS")
    emu.wait(5) -- full windows can take a bit

    a2d.ClearSelection()
    ShiftDown()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "A", "first should be selected")

    a2d.ClearSelection()
    ShiftRight()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "A", "first should be selected")

    a2d.ClearSelection()
    ShiftUp()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "Z", "first should be selected")

    a2d.ClearSelection()
    ShiftLeft()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "Z", "first should be selected")
end)

test.Step(
  "List view - Shift+Arrow selection - starting with no selection",
  function()
    a2d.OpenPath("/TESTS/SELECTION/SHIFT.ARROWS")
    emu.wait(5) -- full windows can take a bit
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)

    a2d.ClearSelection()
    ShiftDown()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "A", "first should be selected")

    a2d.ClearSelection()
    ShiftUp()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "Z", "first should be selected")

    a2d.ClearSelection()
    ShiftRight()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "no icons should be selected")

    a2d.ClearSelection()
    ShiftLeft()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "no icons should be selected")
end)

test.Step(
  "Icon view - Shift+Arrow selection - starting with everything selected",
  function()
    a2d.OpenPath("/TESTS/SELECTION/SHIFT.ARROWS")
    emu.wait(5) -- full windows can take a bit

    a2d.SelectAll()
    local count = #a2d.GetSelectedIcons()

    ShiftDown()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not change")

    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not change")

    ShiftUp()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not change")

    ShiftLeft()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not change")
end)

test.Step(
  "List view - Shift+Arrow selection - starting with everything selected",
  function()
    a2d.OpenPath("/TESTS/SELECTION/SHIFT.ARROWS")
    emu.wait(5) -- full windows can take a bit
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)

    a2d.SelectAll()
    local count = #a2d.GetSelectedIcons()

    ShiftDown()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not change")

    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not change")

    ShiftUp()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not change")

    ShiftLeft()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not change")
end)

test.Step(
  "Icon view - Shift+Arrow selection - incremental selection",
  function()
    a2d.OpenPath("/TESTS/SELECTION/SHIFT.ARROWS")
    emu.wait(5) -- full windows can take a bit

    --  A  B  C  D  E
    --  F  G  H  I  J
    --  K  L  M  N  O
    --  P  Q  R  S  T
    --  U  V  W  X  Y
    --  Z

    a2d.ClearSelection()

    local count = 0

    -- A...E
    for i = 1, 5 do
      ShiftRight()
      count = count + 1
      test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")
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
      test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")
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
      test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")
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
      test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")
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
      test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not grow")
    end

    -- Z
    ShiftDown()
    count = count + 1
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")

    -- [A][B][C][D][E]
    -- [F] G  H  I [J]
    -- [K] L  M  N [O]
    -- [P] Q  R  S [T]
    -- [U][V][W][X][Y]
    -- [Z]

    -- no-op since it doesn't have anything to right/left/down
    ShiftRight()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not grow")
    ShiftLeft()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not grow")
    ShiftDown()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not grow")

    -- U - already selected so no change
    ShiftUp()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not grow")

    -- V - already selected so no change
    ShiftRight()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not grow")

    -- Q
    ShiftUp()
    count = count + 1
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")

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
    a2d.OpenPath("/TESTS/SELECTION/SHIFT.ARROWS")
    emu.wait(5) -- full windows can take a bit
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)

    -- Top down
    a2d.ClearSelection()
    local count = 0

    for i = 1, 10 do
      ShiftDown()
      count = count + 1
      test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")
    end
    ShiftUp()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should no grow")

    -- Bottom up
    a2d.ClearSelection()
    local count = 0

    for i = 1, 10 do
      ShiftUp()
      count = count + 1
      test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")
    end
    ShiftDown()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not grow")

    -- Middle up then down
    a2d.ClearSelection()
    apple2.Type("M")
    emu.wait(0.5)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "single icon should be selected")
    count = 1

    for i = 1, 10 do
      ShiftUp()
      count = count + 1
      test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")
    end

    for i = 1, 10 do
      ShiftDown()
      count = count + 1
      test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")
    end
end)

test.Step(
  "List view - Shift+Arrow selection - with gaps",
  function()
    a2d.OpenPath("/TESTS/SELECTION/SHIFT.ARROWS")
    emu.wait(5) -- full windows can take a bit
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)

    a2d.Select("C")
    local c_x, c_y = a2dtest.GetSelectedIconCoords()

    a2d.Select("E")
    local e_x, e_y = a2dtest.GetSelectedIconCoords()

    a2d.Select("G")

    a2d.InMouseKeysMode(function(m)
        apple2.PressShift()
        m.MoveToApproximately(c_x, c_y)
        m.Click()
        m.MoveToApproximately(e_x, e_y)
        m.Click()
        apple2.ReleaseShift()
    end)

    local count = 3
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should start off with 3")

    for i = 1, 2 do
      ShiftDown()
      count = count + 1
      test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")
    end

    for i = 1, 3 do
      ShiftUp()
      count = count + 1
      test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should grow")
    end
end)
