a2d.ConfigureRepaintTime(0.25)

-- Does an OCR pass on the calculator display; works for both versions.
function OCRDisplay()
  local dw, dh = 124, 20
  local x, y, w, h = a2dtest.GetFrontWindowContentRect()
  local ocr = a2dtest.OCRScreen({
      x1 = x + w - dw, -- Assumes display is top-right
      x2 = x + w,
      y1 = y + 0,
      y2 = y + dh
  })
  return ocr:gsub("%s", "")
end

function ExpectExpression(expr, result)
  apple2.Type(expr)
  a2d.WaitForRepaint()
  local ocr = OCRDisplay()
  test.ExpectEquals(ocr, result, string.format("result of %q", expr), {}, 1)
  apple2.EscapeKey()
end


--[[
  Run Apple Menu > Calculator. Move the Calculator window. Verify that
  the mouse cursor is drawn correctly.
]]
test.Step(
  "Cursor doesn't home",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH*3/4, apple2.SCREEN_HEIGHT/2)
    end)
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR", {no_validate=true})
    test.Snap("verify cursor not at 0,0")
    a2d.CloseWindow()
end)

--[[
  Run Apple Menu > Calculator. Verify that the mouse cursor does not
  jump to the top-left of the screen.
]]
test.Step(
  "Move window and mouse cursor",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR", {no_validate=true})
    local x, y = a2dtest.GetFrontWindowDragCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(400, 100)
        m.ButtonUp()
    end)
    emu.wait(5) -- slow repaint

    test.Snap("verify mouse cursor painted correctly")
    a2d.CloseWindow()
end)

--[[
  Run Apple Menu > Calculator. Drag the Calculator window over a
  volume icon. Then drag the Calculator window to the bottom of the
  screen so that only the title bar is visible. Verify that volume
  icon redraws properly.
]]
test.Step(
  "Window and volume icons",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR", {no_validate=true})
    local x, y = a2dtest.GetFrontWindowDragCoords()

    local drop_x, drop_y = 500, 20

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(drop_x, drop_y)
        m.ButtonUp()
    end)
    emu.wait(5) -- slow repaint

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(drop_x, drop_y)
        m.ButtonDown()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT)
        m.ButtonUp()
    end)
    emu.wait(5) -- slow repaint

    test.Snap("verify volume icons repaint correctly")
    a2d.CloseWindow()
end)

--[[
  Run Apple Menu > Calculator. Drag the Calculator window to bottom of
  screen so only title bar is visible. Type numbers on the keyboard.
  Verify no numbers are painted on screen. Move window back up. Verify
  the typed numbers were input.
]]
test.Step(
  "Obscured window",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR", {no_validate=true})
    local x, y = a2dtest.GetFrontWindowDragCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT)
        m.ButtonUp()
    end)
    emu.wait(5) -- slow repaint

    a2dtest.ExpectNothingChanged(function()
        apple2.Type("123.456")
    end)

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT)
        m.ButtonDown()
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, 30)
        m.ButtonUp()
    end)
    emu.wait(5) -- slow repaint

    test.ExpectMatch(OCRDisplay(), "123%.456", "result should be 123.456")
    a2d.CloseWindow()
end)

--[[
  Repeat for Calculator and Sci.Calc:

  * Enter '1' '-' '2' '='. Verify that the system does not hang.

  * Enter '1' '/' '2' '='. Verify that the result has a 0 before the
    decimal (i.e. "0.5").

  * Enter '0' '-' '.' '5' '='. Verify that the result has a 0 before
    the decimal (i.e. "-0.5").
]]
test.Variants(
  {
    {"Calculator - misc", "/A2.DESKTOP/APPLE.MENU/CALCULATOR"},
    {"Sci.Calc - misc", "/A2.DESKTOP/EXTRAS/SCI.CALC"},
  },
  function(idx, name, path)
    a2d.OpenPath(path, {no_validate=true})
    a2d.WaitForRepaint()

    ExpectExpression("1-2=", "-1")
    -- should not hang

    ExpectExpression("1/2=", "0.5")
    ExpectExpression("0-.5=", "-0.5")

    ExpectExpression("6", "6")
    ExpectExpression("6/", "6")
    ExpectExpression("6/2", "2")
    ExpectExpression("6/2=", "3")

    a2d.CloseWindow()
end)

--[[
  Repeat for Calculator and Sci.Calc:

  * With an English build, run the DA. Verify that '.' appears as the
    decimal separator in calculation results and that '.' when typed
    functions as a decimal separator.

  * With an Italian build, run the DA. Verify that ',' appears as the
    decimal separator in calculation result and that ',' when typed
    functions as a decimal separator. Verify that when '.' is typed,
    ',' appears.
]]
test.Variants(
  {
    { "Calculator - decimal separator", "/A2.DESKTOP/APPLE.MENU/CALCULATOR"},
    { "Sci.Calc - decimal separator", "/A2.DESKTOP/EXTRAS/SCI.CALC"},
  },
  function(idx, name, path)
    a2d.OpenPath(path, {no_validate=true})
    a2d.WaitForRepaint()

    ExpectExpression("12.34", "12.34")
    apple2.EscapeKey()

    a2d.CloseWindow()

    function SetNumberFormat(decimal_separator, thousands_separator)
      a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/INTERNATIONAL", {no_validate=true})
      apple2.TabKey() -- focus date > time
      apple2.TabKey() -- focus time > decimal
      apple2.Type(decimal_separator)
      apple2.TabKey() -- focus decimal > thousands
      apple2.Type(thousands_separator)
      a2d.DialogOK()
    end

    -- Change decimal separator
    SetNumberFormat(",", ".")

    a2d.OpenPath(path, {no_validate=true})
    a2d.WaitForRepaint()

    ExpectExpression("12,34", "12,34")
    ExpectExpression("12.34", "12,34")

    a2d.CloseWindow()

    -- Restore decimal separator
    SetNumberFormat(".", ",")
end)

--[[
  With Sci.Calc:

  * Enter '1' '+' '2' 'SIN' '='. Verify that the result is 1.034...

  * Enter '1' 'SIN' '+' '2' '='. Verify that the result is 2.017...

  * Enter '4' '5' 'SIN'. Verify that the result is 0.707...

  * Enter '4' '5' '+/-' 'SIN'. Verify that the result is -0.707...

  * Enter '1' '8' '0' 'COS'. Verify that the result is -1

  * Enter '4' '5' 'SIN' 'ASIN. Verify that the result is approximately
    45.

  * Enter '4' '5' 'COS' 'ACOS'. Verify that the result is
    approximately 45.

  * Enter '8' '9' 'TAN' 'ATAN'. Verify that the result is
    approximately 89.

  * Verify asin(1) = 90
  * Verify asin(-1) = -90
  * Verify acos(1) is 0
  * Verify acos(-1) is 180

]]
test.Step(
  "Sci.Calc - functions",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS/SCI.CALC", {no_validate=true})
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    -- Pattern - '.' and '-' do not need escaping
    function ExpectMatch(pattern)
      local p2 = "^" .. pattern:gsub("%.", "%%."):gsub("%-", "%%-") .. "$"
      a2d.WaitForRepaint()
      local ocr = OCRDisplay()
      test.ExpectMatch(ocr, p2, "result", {}, 1)
      apple2.EscapeKey()
    end

    function Click(cx, cy)
      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(x + cx, y + cy)
          m.Click()
      end)
    end

    local col1, col2 = 30, 65
    local row1, row2, row3, row4, row5, row6 = 10, 26, 42, 58, 74, 90

    function Sin()  Click(col1, row1) end
    function ASin() Click(col2, row1) end
    function Cos()  Click(col1, row2) end
    function ACos() Click(col2, row2) end
    function Tan()  Click(col1, row3) end
    function ATan() Click(col2, row3) end
    function Pow()  Click(col1, row4) end
    function Log()  Click(col2, row4) end
    function SqRt() Click(col1, row5) end
    function Exp()  Click(col2, row5) end
    function Neg()  Click(col1, row6) end
    function Inv()  Click(col1, row6) end

    -- Functions and infix operators

    apple2.Type("1+2") Sin() apple2.Type("=")
    ExpectMatch("1.034%d+")

    apple2.Type("1") Sin() apple2.Type("+2=")
    ExpectMatch("2.017%d+")

    apple2.Type("1+1=") SqRt()
    ExpectMatch("1.41%d+")

    -- Trig basics

    apple2.Type("45") Sin()
    ExpectMatch("0.707%d+")

    apple2.Type("45") Neg() Sin()
    ExpectMatch("-0.707%d+")

    apple2.Type("180") Cos()
    ExpectMatch("-1")

    apple2.Type("45") Sin() ASin()
    ExpectMatch("45.?%d*")

    apple2.Type("45") Cos() ACos()
    ExpectMatch("45.?%d*")

    apple2.Type("89") Tan() ATan()
    ExpectMatch("89.?%d*")

    -- Trig Discontinuities

    apple2.Type("1") ASin()
    ExpectMatch("90")

    apple2.Type("1") Neg() ASin()
    ExpectMatch("-90")

    apple2.Type("1") ACos()
    ExpectMatch("0")

    apple2.Type("1") Neg() ACos()
    ExpectMatch("180")

    a2d.CloseWindow()
end)

--[[
  Exercise repeated ops, e.g. "1 + 2 = = ="
]]
test.Variants(
  {
    {"Calculator - repeated operations", "/A2.DESKTOP/APPLE.MENU/CALCULATOR"},
    {"Sci.Calc - repeated operations", "/A2.DESKTOP/EXTRAS/SCI.CALC"},
  },
  function(idx, name, path)
    a2d.OpenPath(path, {no_validate=true})
    a2d.WaitForRepaint()

    ExpectExpression("2+3=", "5")
    ExpectExpression("2+3==", "8")
    ExpectExpression("2+3===", "11")

    ExpectExpression("2*3=", "6")
    ExpectExpression("2*3==", "18")
    ExpectExpression("2*3===", "54")

    ExpectExpression("64", "64")
    ExpectExpression("64/", "64")
    ExpectExpression("64/2", "2")
    ExpectExpression("64/2=", "32")
    ExpectExpression("64/2==", "16")
    ExpectExpression("64/2==+", "16")
    ExpectExpression("64/2==+1", "1")
    ExpectExpression("64/2==+1=", "17")
    ExpectExpression("64/2==+1==", "18")

    ExpectExpression("1+2", "2")
    ExpectExpression("1+2+", "3")
    ExpectExpression("1+2++", "5")
    ExpectExpression("1+2+++", "7")

    ExpectExpression("1+2=", "3")
    ExpectExpression("1+2==", "5") -- repeats with last input as const
    ExpectExpression("1+2+", "3")
    ExpectExpression("1+2++", "5") -- repeats with last input as const
    ExpectExpression("1+2=+", "3") -- does not repeat
    ExpectExpression("1+2=+1", "1") -- start of next input, does not repeat
    ExpectExpression("1+2=+1=", "4")
    ExpectExpression("1+2-", "3")
    ExpectExpression("1+2-1", "1") -- start of next input
    ExpectExpression("1+2-1=", "2") -- start of next input, does not repeat

    -- Current Calculator behavior, not sure if these are by design:
    ExpectExpression("1+-", "2")
    ExpectExpression("1+-2=", "0")

    -- And this deviates, but the behavior is nonsensical
    if idx == 1 then
      ExpectExpression("1+2=++", "5")
    else
      ExpectExpression("1+2=++", "6")
    end

    a2d.CloseWindow()
end)
