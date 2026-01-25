a2d.ConfigureRepaintTime(0.25)

--[[
This covers:
 * DeskTop's modal name dialog, used in:
   * Special > Format Disk...
   * Special > Erase Disk...
 * DeskTop's modeless rename prompt, used in:
   * File > New Folder
   * File > Duplicate
   * File > Rename
   * Note that this uniquely shows text centered, so pay close attention!
 * DeskTop's Add/Edit a Shortcut dialog (an extended File Picker)
 * Find Files DA.
 * Map DA:
   * With input field fully on screen.
   * With input field partially off screen.
   * With input field completely off screen.
   * With window moved to bottom of screen so that only the title bar is visible.
]]

local filename_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789."

local printable_chars = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"

function LineEditTest(name, limits, activation_func, rect_func, cleanup_func)

  --------------------------------------------------
  -- Keyboard Input
  --------------------------------------------------

--[[
 * Type a printable character.
   * Should insert a character at caret, unless invalid in context or length limit reached. Limits are:
     * File name: 15 characters; only alpha, numeric, and period accepted; only alpha at start
     * Find Files: 15 characters; only alpha, numeric, period, and * and ? accepted
     * Shortcut name: 14 characters
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Delete key
   * Should delete character to left of caret, unless at start of string.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Control+F (Forward delete)
   * Should delete character to right of caret, unless at end of string.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Control+X (or Clear key on IIgs)
   * Should clear all text.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Left Arrow
   * Should move caret one character to the left, unless at start of string.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Right Arrow
   * Should move caret one character to the right, unless at end of string.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Apple+Left Arrow
   * Should move caret to start of string.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Apple+Right Arrow
   * Should move caret to end of string.
   * Mouse cursor should be hidden until moved.
   * Test at start, in middle, and at end of the string.
]]
  function Reset()
    apple2.ControlKey("X") -- clear
  end

  test.Step(
    name .. " - keyboard input",
    function()

      activation_func()

      -- Insert - caret at start/end
      Reset()
      apple2.Type("GOOD")
      test.Snap("verify GOOD (Insert - caret at start/end)")

      -- Insert - caret in middle
      Reset()
      apple2.Type("GD")
      apple2.LeftArrowKey()
      apple2.Type("OO")
      test.Snap("verify GOOD (Insert - caret in middle)")

      -- Delete - caret at end
      Reset()
      apple2.Type("GOODbad")
      apple2.DeleteKey()
      apple2.DeleteKey()
      apple2.DeleteKey()
      test.Snap("verify GOOD (Delete - caret at end)")

      -- Delete - caret in middle
      Reset()
      apple2.Type("GObadOD")
      apple2.LeftArrowKey()
      apple2.LeftArrowKey()
      apple2.DeleteKey()
      apple2.DeleteKey()
      apple2.DeleteKey()
      test.Snap("verify GOOD (Delete - caret in middle)")

      -- Delete - caret at start
      Reset()
      apple2.Type("GOOD")
      a2d.OALeft()
      apple2.DeleteKey()
      test.Snap("verify GOOD (Delete - caret at start)")

      Reset()
      apple2.Type("badGOOD")
      for i = 1, 4 do apple2.LeftArrowKey() end
      for i = 1, 4 do apple2.DeleteKey() end
      test.Snap("verify GOOD (Delete - caret at start)")

      -- Control+F - caret at start
      Reset()
      apple2.Type("badGOOD")
      a2d.OALeft()
      apple2.ControlKey("F")
      apple2.ControlKey("F")
      apple2.ControlKey("F")
      test.Snap("verify GOOD (Control+F - caret at start)")

      -- Control+F - caret in middle
      Reset()
      apple2.Type("GObadOD")
      for i = 1, 5 do apple2.LeftArrowKey() end
      for i = 1, 3 do apple2.ControlKey("F") end
      test.Snap("verify GOOD (Control+F - caret in middle)")

      -- Control+F - caret at end
      Reset()
      apple2.Type("GOOD")
      apple2.ControlKey("F")
      apple2.ControlKey("F")
      apple2.ControlKey("F")
      test.Snap("verify GOOD (Control+F - caret at end)")

      Reset()
      apple2.Type("GOODbad")
      for i = 1, 3 do apple2.LeftArrowKey() end
      for i = 1, 4 do apple2.ControlKey("F") end
      test.Snap("verify GOOD (Control+F - caret at end)")

      -- Control+X - caret at start
      Reset()
      apple2.Type("bad")
      a2d.OALeft()
      apple2.ControlKey("X")
      apple2.Type("GOOD")
      test.Snap("verify GOOD (Control+X - caret at start)")

      -- Control+X - caret at in middle
      Reset()
      apple2.Type("bad")
      apple2.LeftArrowKey()
      apple2.ControlKey("X")
      apple2.Type("GOOD")
      test.Snap("verify GOOD (Control+X - caret at in middle)")

      -- Control+X - caret at end
      Reset()
      apple2.Type("bad")
      apple2.ControlKey("X")
      apple2.Type("GOOD")
      test.Snap("verify GOOD (Control+X - caret at end)")

      -- Left Arrow - caret at start
      Reset()
      apple2.LeftArrowKey()
      apple2.Type("OD")
      for i = 1, 3 do apple2.LeftArrowKey() end
      apple2.Type("GO")
      test.Snap("verify GOOD (Left Arrow - caret at start)")

      -- Left Arrow - caret in middle
      Reset()
      apple2.Type("GD")
      apple2.LeftArrowKey()
      apple2.Type("O")
      apple2.LeftArrowKey()
      apple2.Type("O")
      test.Snap("verify GOOD (Left Arrow - caret in middle)")

      -- Left Arrow - caret at end
      Reset()
      apple2.Type("GOD")
      apple2.LeftArrowKey()
      apple2.Type("O")
      test.Snap("verify GOOD (Left Arrow - caret at end)")

      -- Right Arrow - caret at start
      Reset()
      apple2.RightArrowKey()
      apple2.Type("GOD")
      a2d.OALeft()
      apple2.RightArrowKey()
      apple2.Type("O")
      test.Snap("verify GOOD (Right Arrow - caret at start)")

      -- Right Arrow - caret in middle
      Reset()
      apple2.Type("GOO")
      apple2.LeftArrowKey()
      apple2.LeftArrowKey()
      apple2.RightArrowKey()
      apple2.RightArrowKey()
      apple2.Type("D")
      test.Snap("verify GOOD (Right Arrow - caret in middle)")

      -- Right Arrow - caret at end
      Reset()
      apple2.Type("GOOD")
      apple2.RightArrowKey()
      test.Snap("verify GOOD (Right Arrow - caret at end)")

      -- Apple+Left - caret at start
      Reset()
      apple2.Type("badGOOD")
      a2d.OALeft()
      apple2.ControlKey("F")
      apple2.ControlKey("F")
      apple2.ControlKey("F")
      a2d.OALeft()
      test.Snap("verify GOOD (Apple+Left - caret at start)")

      -- Apple+Left - caret in middke
      Reset()
      apple2.Type("badGOOD")
      apple2.LeftArrowKey()
      apple2.LeftArrowKey()
      a2d.OALeft()
      apple2.ControlKey("F")
      apple2.ControlKey("F")
      apple2.ControlKey("F")
      test.Snap("verify GOOD (Apple+Left - caret in middke)")

      -- Apple+Left - caret at end
      Reset()
      apple2.Type("badGOOD")
      a2d.OALeft()
      apple2.ControlKey("F")
      apple2.ControlKey("F")
      apple2.ControlKey("F")
      test.Snap("verify GOOD (Apple+Left - caret at end)")

      -- Apple+Right - caret at start
      Reset()
      apple2.Type("GOODbad")
      a2d.OALeft()
      a2d.OARight()
      for i = 1, 3 do apple2.DeleteKey() end
      test.Snap("verify GOOD (Apple+Right - caret at start)")

      -- Apple+Right - caret in middle
      Reset()
      apple2.Type("GOODbad")
      for i = 1, 3 do apple2.LeftArrowKey() end
      a2d.OARight()
      for i = 1, 3 do apple2.DeleteKey() end
      test.Snap("verify GOOD (Apple+Right - caret in middle)")

      -- Apple+Right - caret at end
      Reset()
      apple2.Type("GOODbad")
      a2d.OARight()
      for i = 1, 3 do apple2.DeleteKey() end
      test.Snap("verify GOOD (Apple+Right - caret at end)")

      cleanup_func()
  end)

  --------------------------------------------------
  -- Input Limits
  --------------------------------------------------

  test.Step(
    name .. " - input limits",
    function()
      activation_func()

      -- Allowed characters - start of range
      Reset()
      apple2.Type("X")
      local n = limits.max - 5 -- "X' ... "GOOD"
      -- inserted
      for i = 1,n do
        apple2.Type(limits.chars:sub(i, i))
      end
      apple2.Type("GOOD")
      -- ignored
      for i = 1,n do
        apple2.Type(limits.chars:sub(i, i))
      end
      -- trim back down
      a2d.OALeft()
      for i = 1,n+1 do
        apple2.ControlKey("F")
      end
      test.Snap("verify GOOD (accepted characters/limits)")

      -- Allowed characters - end of range
      Reset()
      apple2.Type("X")
      local n = limits.max - 5 -- "X' ... "GOOD"
      -- inserted
      for i = 1,n do
        local idx = #limits.chars - i + 1
        apple2.Type(limits.chars:sub(idx, idx))
      end
      apple2.Type("GOOD")
      -- ignored
      for i = 1,n do
        local idx = #limits.chars - i + 1
        apple2.Type(limits.chars:sub(idx, idx))
      end
      -- trim back down
      a2d.OALeft()
      for i = 1,n+1 do
        apple2.ControlKey("F")
      end
      test.Snap("verify GOOD (more accepted characters/limits)")

      -- Disallowed characters - end of range
      Reset()
      apple2.Type("GO")
      -- control characters
      -- TODO
      apple2.ControlKey("@")
      apple2.ControlKey("A")
      apple2.ControlKey("B")
      -- apple2.ControlKey("C") "Close" in File Picker
      -- apple2.ControlKey("D") "Drives" in File Picker
      apple2.ControlKey("E")
      -- Control+F = Forward Delete
      apple2.ControlKey("G")
      -- Control+I = Tab
      -- Control+J = Down Arrow
      -- Control+K = Up Arrow
      apple2.ControlKey("L")
      -- Control+M = Return
      apple2.ControlKey("N")
      -- apple2.ControlKey("O") "Open" in File Picker
      apple2.ControlKey("P")
      apple2.ControlKey("Q")
      apple2.ControlKey("R")
      apple2.ControlKey("S")
      apple2.ControlKey("T")
      -- Control+U = Right Arrow
      apple2.ControlKey("V")
      apple2.ControlKey("W")
      -- Control+X = Clear
      apple2.ControlKey("Y")
      apple2.ControlKey("Z")
      -- Control+[ = Escape
      apple2.ControlKey("\\")
      apple2.ControlKey("]")
      apple2.ControlKey("^")
      apple2.ControlKey("_")

      -- characters outside range
      for i = 1, #printable_chars do
        local c = printable_chars:sub(i, i)
        if not limits.chars:find(c, 1, true) then
          apple2.Type(c)
        end
      end

      apple2.Type("OD")
      test.Snap("verify GOOD (disallowed characters)")


      cleanup_func()
  end)

  --------------------------------------------------
  -- Mouse cursor hidden
  --------------------------------------------------

  test.Step(
    name .. " - keyboard input and mouse cursor",
    function()

      function MoveMouse()
        a2d.InMouseKeysMode(function(m)
            m.MoveByApproximately(10, 10)
            m.MoveByApproximately(-10, -10)
        end)
      end

      activation_func()
      Reset()
      apple2.Type("GOO")
      MoveMouse()
      apple2.Type("D")
      test.Snap("verify mouse cursor hidden (Insert)")

      apple2.Type("x")
      MoveMouse()
      apple2.DeleteKey()
      test.Snap("verify mouse cursor hidden (Delete)")

      a2d.OALeft()
      apple2.Type("x")
      apple2.LeftArrowKey()
      MoveMouse()
      apple2.ControlKey("F")
      test.Snap("verify mouse cursor hidden (Control+F)")

      apple2.Type("x")
      MoveMouse()
      apple2.ControlKey("X")
      test.Snap("verify mouse cursor hidden (Control+X)")

      apple2.Type("GOOD")
      MoveMouse()
      apple2.LeftArrowKey()
      test.Snap("verify mouse cursor hidden (Left Arrow)")

      MoveMouse()
      apple2.RightArrowKey()
      test.Snap("verify mouse cursor hidden (Right Arrow)")

      MoveMouse()
      a2d.OALeft()
      test.Snap("verify mouse cursor hidden (Apple+Left Arrow)")

      MoveMouse()
      a2d.OARight()
      test.Snap("verify mouse cursor hidden (Apple+Right Arrow)")

      cleanup_func()
  end)


  --------------------------------------------------
  -- Mouse input
  --------------------------------------------------

  test.Step(
    name .. " - mouse input",
    function()

      activation_func()

      local x, y, w, h = rect_func()

      if x ~= nil then

        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(x + w / 2, y + h / 2)
            test.Snap("verify cursor is I-beam")
            m.MoveToApproximately(x + w / 2, y + h / 2 - 20)
            test.Snap("verify cursor is arrow")
        end)

        --[[
          * Click to left of string. Verify the mouse cursor is not
            obscured.

          * Click to left of caret, within the string. Verify the
            mouse cursor is not obscured.

          * Click to right string. Verify the mouse cursor is not
            obscured.

          * Click to right of caret, within the string. Verify the
            mouse cursor is not obscured.

        ]]

        function MoveToAndClick(x, y, message)
          a2d.InMouseKeysMode(function(m)
              m.MoveToApproximately(x, y)
              a2dtest.MultiSnap(60, message)
              m.Click()
              emu.wait(1)
              a2dtest.MultiSnap(60, "verify cursor not obscured")
          end)
        end


        apple2.ControlKey("X")
        apple2.Type("TEST.STRING")

        -- Click to left of string
        MoveToAndClick(
          x + 3, y + h/2,
          "verify cursor left of string")

        -- Click to left of caret, within string
        a2d.OARight()
        MoveToAndClick(
          x + 20, y + h/2,
          "verify cursor left of caret")

        -- Click to right of string
        MoveToAndClick(
          x + w - 10, y + h/2,
          "verify cursor right of string")

        -- Click to right of caret, within string
        a2d.OALeft()
        MoveToAndClick(
          x + 70, y + h/2,
          "verify cursor right of caret")
      end

      cleanup_func()
  end)



end

LineEditTest(
  "format/erase name prompt",
  {
    max = 15,
    chars = filename_chars,
  },
  function()
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_ERASE_DISK)
    a2d.ClearTextField()
  end,
  function()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    return x + 40, y + 67, 320, 11
  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
end)

LineEditTest(
  "modeless rename",
  {
    max = 15,
    chars = filename_chars,
  },
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_RENAME)
  end,
  function()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    return x, y, w, h
  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
end)

LineEditTest(
  "extended file picker",
  {
    max = 14,
    chars = printable_chars,
  },
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(5)
  end,
  function()
    local id = a2dtest.GetNextWindowID(mgtk.FrontWindow())
    local x, y, w, h = a2dtest.GetWindowContentRect(id)
    return x + 28, y + 114, 435, 11
  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
end)

LineEditTest(
  "Find Files DA",
  {
    max = 15,
    chars = filename_chars .. "?*",
  },
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    emu.wait(5)
  end,
  function()
    local id = a2dtest.GetNextWindowID(mgtk.FrontWindow())
    local x, y, w, h = a2dtest.GetWindowContentRect(id)
    return x + 20 + 3 + 25, y + 10, w - 250 - (20 + 3 + 25), 11
  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
end)

LineEditTest(
  "Map DA - on screen",
  {
    max = 15,
    chars = printable_chars,
  },
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP")
  end,
  function()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    return x + 6, y + 5 + 52 + 6, w - 6 - 100 - 12, 11
  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
    a2d.CloseAllWindows()
end)

LineEditTest(
  "Map DA - line edit partially obscured",
  {
    max = 15,
    chars = printable_chars,
  },
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.Drag(x, y, x, apple2.SCREEN_HEIGHT - 80)
  end,
  function()
    return nil

  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
    a2d.CloseAllWindows()
end)

LineEditTest(
  "Map DA - line edit fully obscured",
  {
    max = 15,
    chars = printable_chars,
  },
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.Drag(x, y, x, apple2.SCREEN_HEIGHT - 50)
  end,
  function()
    return nil

  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
    a2d.CloseAllWindows()
end)

LineEditTest(
  "Map DA - window obscured",
  {
    max = 15,
    chars = printable_chars,
  },
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.Drag(x, y, x, apple2.SCREEN_HEIGHT)
  end,
  function()
    return nil
  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
    a2d.CloseAllWindows()
end)
