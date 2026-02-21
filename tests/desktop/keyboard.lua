--[[ BEGINCONFIG ========================================

MODEL="apple2ep"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Close all windows. Start typing a volume name. Verify that a
  prefix-matching volume, or the subsequent volume (in lexicographic
  order) is selected, or the last volume (in lexicographic order).
]]
test.Step(
  "type down",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
    apple2.Type("A")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "type down order")
    apple2.Type("2")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "type down order")
    apple2.Type("Q")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "type down order")
    a2d.ClearSelection()
    apple2.Type("T")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "TESTS", "type down order")
    apple2.Type("Z")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "TRASH", "type down order")
end)

--[[
  Close all windows. Start typing a volume name. Move the mouse. Start
  typing another filename. Verify that the matching is reset.
]]
test.Step(
  "type down reset on mouse move",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
    apple2.Type("T")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "TESTS", "type down order")
    apple2.Type("R")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "TRASH", "type down order")
    a2d.InMouseKeysMode(function(m)
        m.MoveByApproximately(20, 20)
    end)
    apple2.Type("A")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "type down order")
end)

--[[
  Open `/TESTS/TYPING.SELECT/ORDER`. Start typing a filename. Verify
  that a prefix-matching file in the window, or the subsequent file
  (in lexicographic order), or the last file (in lexicographic order)
  is selected. For example, if the files "Alfa" and "Whiskey" and the
  volume "Tests" are present, typing "A" selects "Alfa", typing "AB"
  selects "Alfa", typing "AL" selects "Alfa", typing "ALFAA" selects
  "Whiskey", typing "B" selects "Whiskey", typing "Z" selects
  "Whiskey". Repeat including file names with numbers and periods.
]]
test.Step(
  "type down order",
  function()
    a2d.OpenPath("/TESTS/TYPING.SELECT/ORDER")
    emu.wait(1)

    apple2.Type("A")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "ALFA", "type down order")
    a2d.ClearSelection()

    apple2.Type("AB")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "ALFA", "type down order")
    a2d.ClearSelection()

    apple2.Type("AL")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "ALFA", "type down order")
    a2d.ClearSelection()

    apple2.Type("ALFAA")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "WHISKEY", "type down order")
    a2d.ClearSelection()

    apple2.Type("B")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "WHISKEY", "type down order")
    a2d.ClearSelection()

    apple2.Type("Z")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "WHISKEY", "type down order")
    a2d.ClearSelection()
end)

--[[
  Open `/TESTS/TYPING.SELECT`. Start typing a filename. Move the
  mouse. Start typing another filename. Verify that the matching is
  reset.
]]
test.Step(
  "type down order, reset if mouse moves",
  function()
    a2d.OpenPath("/TESTS/TYPING.SELECT/ORDER")
    emu.wait(1)

    apple2.Type("WHIS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "WHISKEY", "type down order")

    a2d.InMouseKeysMode(function(m)
        m.MoveByApproximately(20, 20)
    end)

    apple2.Type("ALFA")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "ALFA", "type down order")
end)

--[[
  Open `/TESTS/TYPING.SELECT`. Start typing a filename. Press an arrow
  key. Start typing another filename. Verify that the matching is
  reset.
]]
test.Step(
  "type down order, reset on non-name key",
  function()
    a2d.OpenPath("/TESTS/TYPING.SELECT/ORDER")
    emu.wait(1)

    apple2.Type("WHIS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "WHISKEY", "type down order")

    apple2.RightArrowKey()
    a2d.WaitForRepaint()

    apple2.Type("ALFA")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "ALFA", "type down order")
end)

--[[
  Open a window containing no files. Verify selection doesn't change.
]]
test.Step(
  "type down in empty windows does not change selection",
  function()
    -- Volume selection
    a2d.OpenPath("/RAM1")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "volume should be selected")
    apple2.Type("ANYTHING")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "volume should still be selected")

    -- Selection in another window
    a2d.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should be selected")
    apple2.Type("ANYTHING")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should still be selected")

    -- No selection in another window
    a2d.ClearSelection()
    apple2.Type("ANYTHING")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "nothing should be selected")
end)

--[[
  Use tab in a window containing no files. Verify selection doesn't change.
]]
test.Step(
  "tab in empty windows does not change selection",
  function()
    -- Volume selection
    a2d.OpenPath("/RAM1")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "volume should be selected")
    apple2.TabKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "volume should still be selected")

    -- Selection in another window
    a2d.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should be selected")
    apple2.TabKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should still be selected")

    -- No selection in another window
    a2d.ClearSelection()
    apple2.TabKey()
    a2d.WaitForRepaint()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "nothing should be selected")
end)

--[[
  Use arrow keys in a window containing no files. Verify selection doesn't change.

  (somewhat redundant with a test below)
]]
test.Step(
  "arrow keys in empty windows does not change selection",
  function()
    -- Volume selection
    a2d.OpenPath("/RAM1")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "volume should be selected")
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "volume should still be selected")

    -- Selection in another window
    a2d.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should be selected")
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should still be selected")

    -- No selection in another window
    a2d.ClearSelection()
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "nothing should be selected")
end)

--[[
  Open `/TESTS/TYPING.SELECT/CASE`. Verify the files appear with
  correct names. Press a letter. Verify that the first file starting
  with that letter is selected.
]]
test.Step(
  "type down is case insensitive",
  function()
    a2d.OpenPath("/TESTS/TYPING.SELECT/CASE")
    emu.wait(1)

    a2d.SelectAll()
    local icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 3, "should be 3 icons")
    test.ExpectEquals(icons[1].name, "UPPER", "case should match")
    test.ExpectEquals(icons[2].name, "lower", "case should match")
    test.ExpectEquals(icons[3].name, "mIxEdCaSe", "case should match")
    a2d.ClearSelection()

    apple2.Type("u")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "UPPER", "case insensitive")
    a2d.ClearSelection()

    apple2.Type("L")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "LOWER", "case insensitive")
    a2d.ClearSelection()

    apple2.Type("MiXeD")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "MIXEDCASE", "case insensitive")
end)

--[[
  Disable any acceleration. Close all windows. Restart DeskTop. Type
  the first letter of a volume name to select it. Quickly press
  Open-Apple+O. Verify the volume opens.
]]
test.Step(
  "fast typing",
  function()
    -- Note: acceleration isn't disabled as the "bot" can move fast enough

    a2d.CloseAllWindows()
    a2d.ClearSelection()

    apple2.Type("A")
    a2d.OAShortcut("O")
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    a2d.CloseAllWindows()
end)

--[[
  Disable any acceleration. Close all windows. Restart DeskTop. Type
  the first letter of a volume name to select it. Quickly click on the
  File menu. Verify that Open is enabled.
]]
test.Step(
  "fast clicking",
  function()
    -- Note: acceleration isn't disabled as the "bot" can move fast enough

    a2d.CloseAllWindows()
    a2d.ClearSelection()

    local file_menu_x, file_menu_y
    a2dtest.OCRIterate(function(run, x, y)
        if run == "File" then
          file_menu_x, file_menu_y = x, y
          return false
        end
    end)

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
    end)

    apple2.Type("A")
    apple2.ClickMouseButton()
    a2dtest.MultiSnap(10, "verify that Open is enabled")
end)

--[[
  Repeat the following for these permutations:

  * Close all windows.

  * Open a window containing no file icons.

  * Open a window containing file icons.

  Run these steps:

  * Clear selection. Press Tab repeatedly. Verify that icons in the
    active window (or desktop if no window is open) are selected in
    lexicographic order, starting with first in lexicographic order.

  * Select an icon. Press Tab. Verify that the next icon in the active
    window (or desktop if no window is open) in lexicographic order is
    selected.

  * Clear selection. Press ` repeatedly. Verify that icons in the
    active window (or desktop if no window is open) are selected in
    lexicographic order, starting with first in lexicographic order.

  * Select an icon. Press `. Verify that the next icon in the active
    window (or desktop if no window is open) in lexicographic order is
    selected.

  * Clear selection. Press Shift+` repeatedly. Verify that icons in
    the active window (or desktop if no window is open) are selected
    in reverse lexicographic order, starting with last in
    lexicographic order.

  * Select an icon. Press Shift+`. Verify that the previous icon in
    the active window (or desktop if no window is open) in
    lexicographic order is selected.

  * On a IIgs and a Platinum IIe:

    * Clear selection. Press Shift+Tab repeatedly. Verify that icons
      in the active window (or desktop if no window is open) are
      selected in reverse lexicographic order, starting with last in
      lexicographic order.

    * Select an icon. Press Shift+Tab. Verify that the previous icon
      in the active window (or desktop if no window is open) in
      lexicographic order is selected.
]]

--[[
  Open a volume window containing no file icons. Clear selection by
  clicking on the desktop. Press Tab repeatedly. Verify selection does
  not change, scrollbars do not appear in the window, and DeskTop does
  not crash. Close the window. Verify that the volume icon is no
  longer dimmed.
]]
test.Step(
  "empty window, tab key",
  function()
    a2d.OpenPath("/RAM1")
    a2d.ClearSelection()

    for i = 1, 5 do
      apple2.TabKey()
      a2d.WaitForRepaint()
    end

    test.Snap("verify no scrollbars")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "nothing should be selected")
    a2dtest.ExpectNotHanging()
    a2d.CloseWindow()

    local icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 1, "volume should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "RAM1", "volume should be selected")
    test.Expect(not icons[1].dimmed, "volume should not be dimmed selected")
end)

--[[
  Open a volume window containing no file icons. Clear selection by
  clicking on the desktop. Type 'Z' repeatedly. Verify selection does
  not change, scrollbars do not appear in the window, and DeskTop does
  not crash. Close the window. Verify that the volume icon is no
  longer dimmed.
]]
test.Step(
  "empty window, alpha key",
  function()
    a2d.OpenPath("/RAM1")
    a2d.ClearSelection()

    for i = 1, 5 do
      apple2.Type("Z")
    end

    test.Snap("verify no scrollbars")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "nothing should be selected")
    a2dtest.ExpectNotHanging()
    a2d.CloseWindow()

    local icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 1, "volume should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "RAM1", "volume should be selected")
    test.Expect(not icons[1].dimmed, "volume should not be dimmed")
end)

--[[
  Launch DeskTop. Close all windows. Clear selection by clicking on
  the desktop. Press Right Arrow key. Verify that the first
  (non-Trash) volume icon is selected. Repeat with Down Arrow key.
]]
test.Variants(
  {
    {"no windows, right arrow key", apple2.RightArrowKey},
    {"no windows, down arrow key", apple2.DownArrowKey}
  },
  function(idx, name, keyfunc)
    a2d.CloseAllWindows()
    a2d.ClearSelection()

    keyfunc()
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 1, "volume should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "A2.DESKTOP", "first volume should be selected")
end)

--[[
  Launch DeskTop. Close all windows. Clear selection by clicking on
  the desktop. Press Left Arrow key. Verify that Trash icon is
  selected. Repeat with Up Arrow key.
]]
test.Variants(
  {
    {"no windows, left arrow key", apple2.LeftArrowKey},
    {"no windows, up arrow key", apple2.UpArrowKey},
  },
  function(idx, name, keyfunc)
    a2d.CloseAllWindows()
    a2d.ClearSelection()

    keyfunc()
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 1, "volume should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "Trash", "last volume should be selected")
end)

--[[
  Launch DeskTop. Close all windows. Select a volume icon. Press an
  arrow key. Verify that the next icon in the specified direction is
  selected, if any. If none, verify that selection remains unchanged.
]]
test.Step(
  "desktop, arrow navigation",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()

    a2d.Select("A2.DESKTOP")
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "TESTS", "selection should move down")
    apple2.LeftArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "TESTS", "selection should remain unchanged")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "TESTS", "selection should remain unchanged")
    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "selection should move up")
end)

--[[
  Launch DeskTop. Open a window. Press Right Arrow key. Verify that
  the first icon in the window is selected. Repeat with Down Arrow
  key.
]]
test.Variants(
  {
    {"window, no selection, right arrow", apple2.RightArrowKey},
    {"window, no selection, down arrow", apple2.DownArrowKey},
  },
  function(idx, name, keyfunc)
    a2d.OpenPath("/A2.DESKTOP")
    emu.wait(1)
    keyfunc()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS", "first icon should be selected")
end)

--[[
  Launch DeskTop. Open a window. Press Left Arrow key. Verify that the
  last icon in the window is selected. Repeat with Up Arrow key.
]]
test.Variants(
  {
    {"window, no selection, left arrow", apple2.LeftArrowKey},
    {"window, no selection, up arrow", apple2.UpArrowKey},
  },
  function(idx, name, keyfunc)
    a2d.OpenPath("/A2.DESKTOP")
    emu.wait(1)
    keyfunc()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "LOCAL", "last icon should be selected")
end)

--[[
  Launch DeskTop. Open two windows, both containing icons. Select an
  icon in one window. Activate the other window without changing
  selection. Press Right Arrow key. Verify that the first icon in the
  active window is selected. Repeat with Down Arrow key.

  Launch DeskTop. Open two windows, both containing icons. Select an
  icon in one window. Activate the other window without changing
  selection. Press Left Arrow key. Verify that the last icon in the
  active window is selected. Repeat with Up Arrow key.
]]
test.Variants(
  {
    {"window, selection in inactive window, right arrow", apple2.RightArrowKey, "first"},
    {"window, selection in inactive window, down arrow", apple2.DownArrowKey, "first"},
    {"window, selection in inactive window, left arrow", apple2.LeftArrowKey, "last"},
    {"window, selection in inactive window, up arrow", apple2.UpArrowKey, "last"},
  },
  function(idx, name, keyfunc, which)
    a2d.CloseAllWindows()

    -- Open two windows, both containing icons
    a2d.SelectPath("/A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.OpenPath("/TESTS/PROPERTIES")
    emu.wait(1)
    a2d.MoveWindowBy(0, 100)
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
    end)
    a2d.CycleWindows()
    emu.wait(1)

    -- Select an icon in one window
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "PROPERTIES", "folder window should be on top")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()

    -- Activate the other window wihtout changing selection
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")

    -- Press key
    keyfunc()
    a2d.WaitForRepaint()

    if which == "first" then
      test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS", "first icon should be selected")
    else
      test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "LOCAL", "last icon should be selected")
    end
end)

--[[
  Launch DeskTop. Open a window containing multiple icons. Select an
  icon in the window. Press an arrow key. Verify that the next icon in
  the specified direction is selected, if any. If none, verify that
  selection remains unchanged.
]]
test.Step(
  "window, arrow navigation",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA")
    emu.wait(2)
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "ROOM", "selection should move down")
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "BBROS.MINI", "selection should move down")
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "JESU.JOY", "selection should move down")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "HELLO.WORLD", "selection should move right")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "WOZ.BREAKOUT", "selection should move right")
    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "DLR.JESTER", "selection should move up")
    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "HR.COLOR.CHART", "selection should move up")
    apple2.LeftArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "MONARCH", "selection should move left")
    apple2.LeftArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "ROOM", "selection should move left")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Press an arrow
  key. Verify that the next volume icon in visual order is selected
]]
test.Step(
  "window open, volume navigation",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.OpenSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "confirm click")

    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "TESTS", "selection should move down")

    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "selection should move down")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Click on the
  open window's title bar. Press an arrow key. Verify that an icon
  within the window is selected. Repeat for the window's header and
  scroll bars.
]]
test.Variants(
  {
    {"window open, click volume, click title bar", "titlebar"},
    {"window open, click volume, click header", "header"},
    {"window open, click volume, click h scroll bar", "hscroll"},
    {"window open, click volume, click v scroll bar", "vscroll"},
  },
  function(idx, name, where)
    a2d.SelectPath("/A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.OpenSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "confirm click")

    local win_x, win_y, win_w, win_h = a2dtest.GetFrontWindowContentRect()
    if where == "titlebar" then
      -- title bar
      x = win_x + win_w/2
      y = win_y - 5
    elseif where == "header" then
      -- header
      x = win_x + win_w/2
      y = win_y + 5
    elseif where == "hscroll" then
      -- h scroll bar
      x = win_x + win_w / 2
      y = win_y + win_h + 5
    elseif where == "vscroll" then
      -- v scroll bar
      x = win_x + win_w + 5
      y = win_y + win_h / 2
    end
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)

    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS", "selection should be in window")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Click an empty
  area within the window. Press an arrow key. Verify that an icon
  within the window is selected.
]]
test.Step(
  "window open, click volume, click empty area within window",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.OpenSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "confirm click")

    local win_x, win_y, win_w, win_h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(win_x + win_w - 5, win_y + win_h - 5)
        m.Click()
    end)

    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS", "selection should be in window")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Click an icon
  within the window. Press an arrow key. Verify that the next file
  icon in visual order within the window is selected.
]]
test.Step(
  "window open, click volume, click file",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()
    a2d.OpenSelection()
    a2d.Select("PRODOS")
    local file_x, file_y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_x, vol_y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "confirm click")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_x, file_y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS", "confirm click")

    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "CLOCK.SYSTEM", "selection should be in window")
end)


--[[
  Launch DeskTop. Open a window. Click a volume icon. Click an empty
  space on the desktop. Press the Down Arrow key. Verify that the
  first volume icon in visual order on the desktop is selected.
]]
test.Step(
  "window open, click volume, click empty area on desktop",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.OpenSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "confirm click")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH, apple2.SCREEN_HEIGHT)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "selection should be cleared")

    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "first volume should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a file icon. Click an empty
  space on the desktop. Press the Down Arrow key. Verify that the
  first file icon in visual order within the window is selected.
]]
test.Step(
  "window open, click file, click empty space on desktop",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()
    a2d.OpenSelection()
    a2d.Select("PRODOS")
    local file_x, file_y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_x, file_y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS", "confirm click")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH, apple2.SCREEN_HEIGHT)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "selection should be cleared")

    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS", "selection should be in window")
end)

--[[
  Launch DeskTop. Open one window containing icons, the other
  containing no icons. Select an icon in the first window. Activate
  the other window without changing selection. Press an arrow key.
  Verify that selection remains unchanged.

  (somewhat redundant with a test above)
]]
test.Step(
  "Arrow keys in empty windows don't change selection",
  function()
    a2d.CloseAllWindows()

    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()

    -- Open window with icons
    a2d.OpenPath("/A2.DESKTOP")

    -- Open window without icons
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
    end)
    a2d.MoveWindowBy(0, 100)

    -- Select an icon in the first window
    a2d.CycleWindows()
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS", "first icon should be selected")

    -- Activate the other window
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "empty window should be on top")

    -- Press an arrow key
    apple2.RightArrowKey()
    a2d.WaitForRepaint()

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS", "first icon should be selected")
end)

--[[
  Launch DeskTop. Open a window containing icons. View > by Date.
  Press the Right Arrow key. Verify that selection remains unchanged.
  Repeat with the Left Arrow key.
]]
test.Variants(
  {
    {"right arrow in list view", apple2.RightArrowKey},
    {"left arrow in list view", apple2.LeftArrowKey},
  },
  function(idx, name, keyfunc)
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.WaitForRepaint()

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "single volume should be selected")

    a2dtest.ExpectNothingChanged(function()
        keyfunc()
        a2d.WaitForRepaint()
    end)

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "single volume should be selected")
end)

--[[
  Launch DeskTop. Open a window containing icons. View > by Date.
  Clear selection by clicking on the desktop. Press the Down Arrow
  key. Verify that the first icon in visual order is selected. Press
  the Down Arrow key again. Verify that the next icon in visual order
  is selected. Repeat, and verify that selection does not wrap around.

  Launch DeskTop. Open a window containing icons. View > by Date.
  Clear selection by clicking on the desktop. Press the Up Arrow key.
  Verify that the last icon in visual order is selected. Press the Up
  Arrow key again. Verify that the previous icon in visual order is
  selected. Repeat, and verify that selection does not wrap around.
]]
test.Variants(
  {
    {"list view, down arrow does not wrap", "down"},
    {"list view, up arrow does not wrap", "up"},
  },
  function(idx, name, which)
    a2d.OpenPath("/A2.DESKTOP")

    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_DATE)
    a2d.WaitForRepaint()
    a2d.SelectAll()
    local icons = a2d.GetSelectedIcons()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH, apple2.SCREEN_HEIGHT)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "selection should be cleared")

    if which == "down" then
      apple2.DownArrowKey()
      a2d.WaitForRepaint()
      test.ExpectEquals(a2dtest.GetSelectedIconName(), icons[1].name, "first icon should be selected")
      apple2.DownArrowKey()
      a2d.WaitForRepaint()
      test.ExpectEquals(a2dtest.GetSelectedIconName(), icons[2].name, "next icon should be selected")
      for i = 1, 30 do
        apple2.DownArrowKey()
        a2d.WaitForRepaint()
      end
      test.ExpectEquals(a2dtest.GetSelectedIconName(), icons[#icons].name, "last icon should be selected")
    else
      apple2.UpArrowKey()
      a2d.WaitForRepaint()
      test.ExpectEquals(a2dtest.GetSelectedIconName(), icons[#icons].name, "last icon should be selected")
      apple2.UpArrowKey()
      a2d.WaitForRepaint()
      test.ExpectEquals(a2dtest.GetSelectedIconName(), icons[#icons-1].name, "previous icon should be selected")
      for i = 1, 30 do
        apple2.UpArrowKey()
        a2d.WaitForRepaint()
      end
      test.ExpectEquals(a2dtest.GetSelectedIconName(), icons[1].name, "first icon should be selected")
    end
end)

--[[
  Repeat the following cases with these modifiers: Open-Apple, Solid-Apple:

  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press
    Tab repeatedly. Verify that windows are activated and cycle in
    forward order (A, B, C, A, B, C, ...).

  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press
    ` repeatedly. Verify that windows are activated cycle in forward
    order (A, B, C, A, B, C, ...).

  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press
    Shift+` repeatedly. Verify that windows are activated cycle in
    reverse order (B, A, C, B, A, C, ...).

  * On a IIgs: Launch DeskTop. Open 3 windows (A, B, C). Hold modifier
    and press Shift+Tab repeatedly. Verify that windows are activated
    cycle in reverse order (B, A, C, B, A, C, ...).

  * On a Platinum IIe: Launch DeskTop. Open 3 windows (A, B, C). Hold
    modifier and press Shift+Tab repeatedly. Verify that windows are
    activated cycle in reverse order (B, A, C, B, A, C, ...).
]]
test.Variants(
  {
    {"cycle - OA + tab", apple2.PressOA, apple2.ReleaseOA,
     apple2.TabKey, "forwards"},
    {"cycle - OA + backtick", apple2.PressOA, apple2.ReleaseOA,
     function() apple2.Type("`") end, "forwards"},
    {"cycle - OA + tilde", apple2.PressOA, apple2.ReleaseOA,
     function() apple2.Type("~") end, "backwards"},
    {"cycle - OA + shift-tab", apple2.PressOA, apple2.ReleaseOA,
     function() apple2.PressShift() apple2.TabKey() apple2.ReleaseShift() end, "backwards"},
    {"cycle - SA + tab", apple2.PressSA, apple2.ReleaseSA,
     apple2.TabKey, "forwards"},
    {"cycle - SA + backtick", apple2.PressSA, apple2.ReleaseSA,
     function() apple2.Type("`") end, "forwards"},
    {"cycle - SA + tilde", apple2.PressSA, apple2.ReleaseSA,
     function() apple2.Type("~") end, "backwards"},
    {"cycle - SA + shift-tab", apple2.PressSA, apple2.ReleaseSA,
     function() apple2.PressShift() apple2.TabKey() apple2.ReleaseShift() end, "backwards"},
  },
  function(idx, name, press, release, keyfunc, dir)
    a2d.OpenPath("/RAM1")
    a2d.CreateFolder("A")
    a2d.CreateFolder("B")
    a2d.CreateFolder("C")
    a2d.SelectAll()
    a2d.OpenSelectionAndCloseCurrent()
    emu.wait(5)
    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "A, B, C should be open")

    local sequence = ""
    for i = 1, 6 do
      press()

      keyfunc()

      a2d.WaitForRepaint()

      release()

      sequence = sequence .. a2dtest.GetFrontWindowTitle()
    end

    if dir == "forwards" then
      test.ExpectEquals(sequence, "ABCABC", "should cycle forwards")
    else
      test.ExpectEquals(sequence, "BACBAC", "should cycle backwards")
    end

    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    a2d.DeleteSelection()
end)


--[[
  Launch DeskTop. Clear selection by closing all windows and clicking
  on the desktop. Press Apple+Down. Verify that nothing happens.
]]
test.Step(
  "OA+Down with no windows, no selection",
  function()
    a2d.CloseAllWindows()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH, apple2.SCREEN_HEIGHT)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "selection should be cleared")

    a2dtest.ExpectNothingChanged(a2d.OADown)
end)

--[[
  Launch DeskTop. Close all windows. Edit > Select All. Press the
  Right Arrow key. Verify that a single volume icon becomes selected.
]]
test.Step(
  "no windows, arrow after Select All",
  function()
    a2d.CloseAllWindows()
    a2d.SelectAll()
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "single volume should be selected")
end)

--[[
  Launch DeskTop. Open a window containing icons. Edit > Select All.
  Press the Right Arrow key. Verify that a single file icon becomes
  selected.
]]
test.Step(
  "window open, arrow after Select All",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAll()
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS", "single file should be selected")
end)

--[[
  Icon view. OA+Click select several icons. Right Arrow key. Verify
  new selection is based on last selected icon.
]]
test.Step(
  "Icon view - select from last selected",
  function()
    a2d.OpenPath("/TESTS/SELECTION/SHIFT.ARROWS")
    emu.wait(5) -- full windows can take a bit

    --  A  B  C  D  E
    --  F  G  H  I  J
    --  K  L  M  N  O
    --  P  Q  R  S  T
    --  U  V  W  X  Y
    --  Z

    a2d.Select("B")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    a2d.Select("D")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    a2d.Select("E")
    local x3, y3 = a2dtest.GetSelectedIconCoords()
    a2d.Select("C")
    local x4, y4 = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x1, y1)
        m.Click()
        apple2.PressOA()
        m.MoveToApproximately(x2, y2)
        m.Click()
        m.MoveToApproximately(x3, y3)
        m.Click()
        m.MoveToApproximately(x4, y4)
        m.Click()
        apple2.ReleaseOA()
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 4, "should start with 3 selected")

    apple2.DownArrowKey()
    emu.wait(1)

    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "should collapse to 1 selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "H", "icon next to last should be selected")
end)

--[[
  List view. OA+Click select several icons. Right Arrow key. Verify
  new selection is based on last selected icon.
]]
test.Step(
  "List view - select from last selected",
  function()
    a2d.OpenPath("/TESTS/SELECTION/SHIFT.ARROWS")
    emu.wait(5) -- full windows can take a bit
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)

    a2d.Select("C")
    local x1, y1 = a2dtest.GetSelectedIconCoords()

    a2d.Select("G")
    local x2, y2 = a2dtest.GetSelectedIconCoords()

    a2d.Select("E")
    local x3, y3 = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x1, y1)
        m.Click()
        apple2.PressOA()
        m.MoveToApproximately(x2, y2)
        m.Click()
        m.MoveToApproximately(x3, y3)
        m.Click()
        apple2.ReleaseOA()
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 3, "should start with 3 selected")

    apple2.UpArrowKey()
    emu.wait(1)

    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "should collapse to 1 selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "D", "icon next to last should be selected")
end)
