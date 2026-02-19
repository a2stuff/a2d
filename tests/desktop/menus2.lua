local apple_menu_x, apple_menu_y = 10, 5
local file_menu_x, file_menu_y = 30, 5
local file_open_y = 30
local file_separator_y = 60
local file_get_info_y = 75
a2d.ConfigureRepaintTime(0.25)

--[[
  Click to open a menu. Without clicking again, move the mouse pointer
  up and down over the menu items, while simultaneously tapping the
  'A' key. Verify that the key presses do not cause other menus to
  open instead.
]]
test.Step(
  "keystrokes while menu showing",
  function()
    apple2.MoveMouse(apple_menu_x, apple_menu_y)
    apple2.ClickMouseButton()
    apple2.MoveMouse(apple_menu_x, 85)
    apple2.Type("A")
    apple2.MoveMouse(apple_menu_x, 15)
    apple2.Type("A")
    apple2.MoveMouse(apple_menu_x, 85)
    apple2.Type("A")
    apple2.MoveMouse(apple_menu_x, 15)
    apple2.Type("A")
    apple2.MoveMouse(apple_menu_x, 85)
    test.ExpectMatch(a2dtest.OCRScreen(), "About Apple II DeskTop", "Apple menu should be showing")
    apple2.EscapeKey()
    apple2.MoveMouse(0,0)
end)

--[[
  Click to open a menu. Move the mouse over menu bar items and menu
  items. Verify that the highlight changes immediately when the mouse
  pointer hot spot is over the next item, not delayed by one movement.
  For example, if the mouse moves down and the next item doesn't
  highlight, moving the mouse right also shouldn't cause it to
  highlight.
]]
test.Step(
  "menu highlighting",
  function()
    apple2.MoveMouse(apple_menu_x, apple_menu_y)
    apple2.ClickMouseButton()
    apple2.MoveMouse(apple_menu_x+1, 25)
    for i = 16, 40 do
      apple2.MoveMouse(apple_menu_x, i)
      test.Snap("verify item highlights when it should")
    end
    apple2.EscapeKey()
    apple2.MoveMouse(0,0)
end)

--[[
  The following steps exercise the menu as "pull down" using the
  mouse:

  * Mouse-over a menu bar item, and press and hold the mouse button to
    pull down the menu. Drag to an item and release the button. Verify
    the menu closes and the item is invoked.

  * Mouse-over a menu bar item, and press and hold the mouse button to
    pull down the menu. Drag to a separator and release the button.
    Verify the menu closes.

  * Mouse-over a menu bar item, and press and hold the mouse button to
    pull down the menu. Drag off of the menu and release the button.
    Verify the menu closes.
]]
test.Step(
  "mouse, pull down",
  function()
    a2d.CloseAllWindows()

    -- Pull down, release on item
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.ButtonDown()
        m.MoveToApproximately(file_menu_x, file_open_y)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    a2d.CloseAllWindows()

    -- Pull down, release on separator
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.ButtonDown()
        m.MoveByApproximately(0, file_separator_y - file_menu_y)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "no windows should be open")
    a2d.CloseAllWindows()

    -- Pull down, release outside menu
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.ButtonDown()
        m.MoveByApproximately(0, apple2.SCREEN_HEIGHT)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "no windows should be open")
    a2d.CloseAllWindows()
end)

--[[
  The following steps exercise the menu as "drop down" using the
  mouse:

  * Click (press and release the mouse button) on a menu bar item.
    Move the mouse over an item and click it. Verify the menu closes
    and that the item is invoked.

  * Click (press and release the mouse button) on a menu bar item.
    Move the mouse over a separator and click it. Verify the menu
    closes.

  * Click (press and release the mouse button) on a menu bar item.
    Move the mouse off the menu and click. Verify the menu closes.
]]
test.Step(
  "mouse, drop down",
  function()
    a2d.CloseAllWindows()

    -- Drop down, click on item
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
        m.MoveToApproximately(file_menu_x, file_open_y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    a2d.CloseAllWindows()

    -- Drop down, click on separator
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
        m.MoveByApproximately(0, file_separator_y - file_menu_y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "no windows should be open")
    a2d.CloseAllWindows()

    -- Drop down, click outside menu
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
        m.MoveByApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "no windows should be open")
    a2d.CloseAllWindows()
end)

--[[
The following steps exercise the menu as "drop down" using the
keyboard:

  * Press the Escape key. Verify that the first menu opens. Press the
    Escape key again. Verify that the menu closes.

  * Press the Escape key. Verify that the first menu opens. Use the
    Up, Down, Left and Right Arrow keys to move among menu items.
    Press the Escape key again. Verify that the menu closes.

  * Press the Escape key. Verify that the first menu opens. Use the
    Up, Down, Left and Right Arrow keys to move among menu items.
    Press the Return key. Verify that the menu closes, and that the
    item is invoked.
]]
test.Step(
  "keyboard",
  function()
    a2d.CloseAllWindows()
    a2d.SelectPath("/A2.DESKTOP")

    -- Show but do nothing
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen(), "About Apple II DeskTop", "Apple menu should be showing")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.ExpectNotMatch(a2dtest.OCRScreen(), "About Apple II DeskTop", "Apple menu should be closed")

    -- Navigate but don't invoke anything
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "About Apple II DeskTop", "should have moved down into menu")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "File", "should have moved right")
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "Open", "should have moved down")
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "Get Info", "should have moved down")
    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "Open", "should have moved up")
    apple2.LeftArrowKey()
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen(), "About Apple II DeskTop", "should have moved left")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.ExpectNotMatch(a2dtest.OCRScreen(), "About Apple II DeskTop", "should have moved left")

    -- Pick something
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    apple2.ReturnKey()
    emu.wait(5)
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    a2d.CloseAllWindows()
end)

--[[
  The following steps exercise the menu as "drop down" using the mouse
  to initiate the action and the keyboard to finish the action:

  * Click (press and release the mouse button) on a menu bar item. Use
    the mouse to move over an item. Use the arrow keys to select a
    different item. Press Escape. Verify that the menu closes.

  * Click (press and release the mouse button) on a menu bar item. Use
    the mouse to move over an item. Use the arrow keys to select a
    different item. Press Return. Verify that the menu closes, and
    that the item is invoked.
]]
test.Step(
  "mouse, then keyboard",
  function()
    a2d.CloseAllWindows()

    -- Drop down, release on item
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
        m.MoveToApproximately(file_menu_x, file_get_info_y)
    end)
    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "no windows should be open")
    a2d.CloseAllWindows()

    -- Drop down, release on item
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
        m.MoveToApproximately(file_menu_x, file_get_info_y)
    end)
    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    apple2.ReturnKey()
    emu.wait(5)
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    a2d.CloseAllWindows()
end)

--[[
  The following steps exercise the menu as "drop down" using the
  keyboard to initiate the action and the mouse to finish the action:

  * Press the Escape key. Verify that the first menu opens. Click an
    item with the mouse. Verify that the menu closes, and that the
    item is invoked.

  * Press the Escape key. Verify that the first menu opens. Click a
    separator with the mouse. Verify that the menu closes.

  * Press the Escape key. Verify that the first menu opens. Click
    outside the menu. Verify that the menu closes.
]]
test.Step(
  "keyboard, then mouse",
  function()
    a2d.CloseAllWindows()

    -- Show using keyboard, then click on item
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
    end)
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    a2d.InMouseKeysMode(function(m)
        m.MoveByApproximately(0, file_open_y - file_menu_y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    a2d.CloseAllWindows()

    -- Show using keyboard, then click on separator
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
    end)
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    a2d.InMouseKeysMode(function(m)
        m.MoveByApproximately(0, file_separator_y - file_menu_y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "no windows should be open")

    -- Show using keyboard, then click outside menu
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
    end)
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    a2d.InMouseKeysMode(function(m)
        m.MoveByApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "no windows should be open")
end)

--[[
  Click on a menu to show it. While it is open, press the shortcut key
  for a command (e.g. Open-Apple+Q to Quit). Verify that the menu
  closes and that the command is invoked.
]]
test.Step(
  "Menu shortcut while menu is open",
  function()
    a2d.CloseAllWindows()
    a2d.SelectPath("/A2.DESKTOP")

    -- Open menu with click
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple_menu_x, apple_menu_y) -- Apple Menu
        m.Click()
    end)

    a2d.OAShortcut("O") -- File > Open
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    a2d.CloseAllWindows()
end)

--[[
  Press Escape to activate the menu. While it is open, press the
  shortcut key for a command (e.g. Open-Apple+Q to Quit). Verify that
  the menu closes and that the command is invoked.
]]
test.Step(
  "Menu shortcut while menu is open",
  function()
    a2d.CloseAllWindows()
    a2d.SelectPath("/A2.DESKTOP")

    -- Open menu with keyboard
    a2d.OpenMenu(a2d.APPLE_MENU)

    a2d.OAShortcut("O") -- File > Open
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    a2d.CloseAllWindows()
end)

--[[
  Press Escape to activate the menu. Arrow down to an item. Press a
  non-arrow, non-shortcut key (e.g. a punctuation key). Press Return.
  Verify that the menu item is activated.
]]
test.Step(
  "Non-arrow, non-shortcut keys are ignored",
  function()
    a2d.CloseAllWindows()
    a2d.SelectPath("/A2.DESKTOP")
    a2d.OpenMenu(a2d.FILE_MENU)

    apple2.DownArrowKey() -- to File > Open

    apple2.Type("_") -- no-op

    apple2.ReturnKey() -- invoke
    emu.wait(5)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Close all windows. Press the Escape key. Use the
  Left and Right Arrow keys to highlight the View menu. Verify that
  all menu items are disabled. Press the Up and Down arrow keys.
  Verify that the cursor position does not change.
]]
test.Step(
  "View menu items disabled",
  function()
    a2d.CloseAllWindows()
    a2d.OpenMenu(a2d.VIEW_MENU)

    test.Snap("note cursor position")

    apple2.DownArrowKey()
    apple2.DownArrowKey()
    apple2.UpArrowKey()
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    apple2.UpArrowKey()
    apple2.DownArrowKey()
    apple2.DownArrowKey()

    test.Snap("verify cursor position does not change")

    apple2.EscapeKey()
end)
