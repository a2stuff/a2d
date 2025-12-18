--[[ BEGINCONFIG ========================================

MODEL="apple2ep"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

a2d.AddShortcut("/A2.DESKTOP")
function OpenVolumeWindow() a2d.OAShortcut("1") end

a2d.AddShortcut("/A2.DESKTOP/EXTRAS")
function OpenFolderWindow() a2d.OAShortcut("2") end

--[[
  Launch DeskTop. Open a window. Select a file icon. Drag a selection
  rectangle around another file icon in the same window. Verify that
  the initial selection is cleared and only the second icon is
  selected.
]]
test.Step(
  "selection rectangle around file icons",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("READ.ME")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Select("PRODOS")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x-30, y-5)
        m.ButtonDown()
        m.MoveByApproximately(60, 25)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "only new icon should be selected")
end)

--[[
  Launch DeskTop. Select a volume icon. Drag a selection rectangle
  around another volume icon. Verify that the initial selection is
  cleared and only the second icon is selected.
]]
test.Step(
  "selection rectangle around volume icons",
  function()
    a2d.CloseAllWindows()

    a2d.Select("RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Select("A2.DESKTOP")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x-30, y-5)
        m.ButtonDown()
        m.MoveByApproximately(60, 25)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "only new icon should be selected")
end)

--[[
  Repeat the following cases with these modifiers: Open-Apple, Shift
  (on a IIgs), Shift (on a Platinum IIe):

  * Launch DeskTop. Click on a volume icon. Hold modifier and click a different volume icon. Verify that selection is extended.
  * Launch DeskTop. Select two volume icons. Hold modifier and click on the desktop, not on an icon. Verify that selection is not cleared.
  * Launch DeskTop. Select one or more volume icons. Hold modifier and click a selected volume icon. Verify that it is deselected.
  * Launch DeskTop. Hold modifier and double-click on a non-selected volume icon. Verify that it highlights then unhighlights, and does not open.
  * Launch DeskTop. Select a volume icon. Wait a few seconds for the double-click timer to expire. Hold modifier and double-click the selected volume icon. Verify that it unhighlights then highlights, and does not open.
  * Launch DeskTop. Select a volume icon. Hold modifier down and drag a selection rectangle around another volume icon. Verify that both are selected.
  * Launch DeskTop. Open a volume containing files. Click on a file icon. Hold modifier and click a different file icon. Verify that selection is extended.
  * Launch DeskTop. Open a volume containing files. Select two file icons. Hold modifier and click on the window, not on an icon. Verify that selection is not cleared.
  * Launch DeskTop. Open a window. Select an icon. Hold modifier and double-click an empty spot in the window (not on an icon). Verify that the selection is not cleared.
  * Launch DeskTop. Open a window. Select an icon. Hold modifier down and drag a selection rectangle around another icon. Verify that both are selected.
  * Launch DeskTop. Open a volume window. Select two file icons. Hold modifier and click a selected file icon. Verify that it is deselected.
  * Launch DeskTop. Open a volume window. Select one file icon. Hold modifier and click the selected file icon. Verify that it is deselected, and that the volume icon does not become selected.
  * Launch DeskTop. Open a window. Hold modifier and double-click on a non-selected file icon. Verify that it highlights then unhighlights, and does not open.
  * Launch DeskTop. Open a window. Select a file icon. Wait a few seconds for the double-click timer to expire. Hold modifier and double-click the selected file icon. Verify that it unhighlights then highlights, and does not open.
  * Launch DeskTop. Open a volume window. Hold modifier, and drag-select icons in the window. Release the modifier. Verify that the volume icon is no longer selected. Click an empty area in the window to clear selection. Verify that the selection in the window clears, and that the volume icon becomes selected.
  * Launch DeskTop. Open a volume window. Select a folder icon. Hold modifier, and double-click another folder icon. Verify that selection toggles on the second folder, and no folders are opened.
]]

--[[
  Launch DeskTop. Open two windows containing file icons. Clear
  selection by clicking on the desktop. Run these cases:

  * Click on an icon in the inactive window. Verify that the icon
    highlights on mouse down, and the window activates on mouse up.

  * Drag an icon within in the inactive window. Verify that the icon
    moves and the window does not activate until mouse-up.

  * Drag an icon from the inactive window to a volume icon that does
    not have an open window. Verify that the active window remains
    active.

  * Open a volume icon so a third window appears. Click the first
    window to activate it. Drag an icon from the second window to the
    volume icon. Verify that the third window activates.
]]

--[[
  Launch DeskTop. Open two windows containing file icons. Clear
  selection by clicking on the desktop. Repeat the following cases
  with these modifiers: Open-Apple, Shift (on a IIgs), Shift (on a
  Platinum IIe):

  * Select an icon. Activate the other window by clicking on the title
    bar. Hold modifier and click another icon in the inactive window.
    Verify that the icon highlights on mouse down, and the window
    activates on mouse up, and both icons are selected.

  * Select an icon. Activate the other window by clicking on the title
    bar. Hold modifier and click the selected icon in the inactive
    window. Verify that the icon unhighlights and the window activates
    on mouse down.

  * Select an icon. Activate the other window by clicking on the title
    bar. Hold modifier and drag another icon within the inactive
    window. Verify that the icon highlights and both icons are
    dragged, and that the window activates on mouse down.
]]

--[[
  Launch DeskTop. Click on a volume icon. Hold Solid-Apple and click
  on a different volume icon. Verify that selection changes to the
  second icon.
]]
--[[
  Launch DeskTop. Open a volume containing files. Click on a file
  icon. Hold Solid-Apple and click on a different file icon. Verify
  that selection changes to the second icon.
]]

--[[
  Launch DeskTop. Open a volume window. Select an icon. Click in the
  header area (items/use/etc). Verify that selection is not cleared.
]]

--[[
  Launch DeskTop. Open a volume window. Adjust the window so it is
  small and roughly centered on the screen. In the middle of the
  window, start a drag-selection. Move the mouse cursor in circles
  around the outside of the window and within the window. Verify that
  one corner of the selection rectangle remains fixed where the
  drag-selection was started.
]]

--[[
  Launch DeskTop. Open two windows for two different volumes. Select
  an icon in one window. Click on the title bar, scroll bars, or
  header of the other window to activate it. Verify that the icon in
  the first window is still selected. Click on the title bar, scroll
  bar or header of the active window. Verify that the icon in the
  first window is still selected. Click on the content area of the
  active window. Verify that the icon is no longer selected, and the
  window's corresponding volume icon becomes selected when the mouse
  button is released.
]]
test.Step(
  "clicking non-content area doesn't change selection",
  function()
    a2d.OpenPath("/RAM1")
    local ram_id = a2dtest.GetFrontWindowID()
    a2d.MoveWindowBy(0, 100)

    OpenVolumeWindow()
    a2d.GrowWindowBy(0, -20)

    a2d.Select("READ.ME")

    local x,y,w,h = a2dtest.GetWindowContentRect(ram_id)
    -- click title bar
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y - 5)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "selection should not change")

    -- click scroll bar
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + h + 5)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "selection should not change")

    -- click header
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + 5)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "selection should not change")

    -- click content area
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "volume should be selected")
end)

--[[
  Launch DeskTop. Open a window for a volume icon and a window for a
  folder icon. Click in the content area of the volume icon's window.
  Verify that the volume icon is selected. Click in the content area
  of the folder icon's window. Verify that the folder icon is
  selected.
]]
test.Step(
  "clicking content area",
  function()
    a2d.CloseAllWindows()
    OpenVolumeWindow()
    local volume_id = a2dtest.GetFrontWindowID()

    OpenFolderWindow()
    local folder_id = a2dtest.GetFrontWindowID()
    a2d.GrowWindowBy(0, -40)
    a2d.MoveWindowBy(0, 80)

    local x,y,w,h = a2dtest.GetWindowContentRect(volume_id)
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        m.Click()
    end)
    a2d.WaitForRepaint()

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")

    x,y,w,h = a2dtest.GetWindowContentRect(folder_id)
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        m.Click()
    end)
    a2d.WaitForRepaint()

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "EXTRAS", "folder icon should be selected")
end)


--[[
  Launch DeskTop. Open a window for a volume icon and a window for a
  folder icon within that volume. Close the window for the volume
  icon. Click in the content area of the folder icon's window. Verify
  that the volume icon is selected.
]]
test.Step(
  "volume icon selected when window clicked",
  function()
    a2d.CloseAllWindows()
    OpenVolumeWindow()
    OpenFolderWindow()
    a2d.CycleWindows()
    a2d.CloseWindow()

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")
end)

--[[
  Launch DeskTop. Open a window. Select a file icon. Apple Menu >
  Control Panels. Verify that the previously selected file is no
  longer selected.
]]
test.Step(
  "selection after window opened from Apple Menu item",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.WaitForRepaint()
    test.Expect(#a2d.GetSelectedIcons(), 0, "no icons should be selected")
end)

--[[
  Launch DeskTop, ensuring no windows are open. Edit > Select All.
  Verify that the volume icons are selected.
]]
test.Step(
  "focus with no windows",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "Trash", "volume icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Edit > Select
  All. Verify that volume icons are selected.
]]
test.Step(
  "focus after click volume icon",
  function()
    a2d.CloseAllWindows()

    a2d.Select("A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.ClearSelection()

    -- click volume icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + 5, y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be clicked")

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "Trash", "volume icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Click on the
  open window's title bar. Edit > Select All. Verify that icons within
  the window are selected. Repeat for the window's header and scroll
  bars.
]]
test.Variants(
  {
    "focus after clicking title bar of window",
    "focus after clicking header of window",
    "focus after clicking scroll bar of window",
  },
  function(idx)
    a2d.CloseAllWindows()

    a2d.Select("A2.DESKTOP")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.ClearSelection()

    -- click volume icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_x + 5, vol_y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be clicked")

    -- click target
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        if idx == 1 then
          m.MoveToApproximately(x + w / 2, y - 5)
        elseif idx == 2 then
          m.MoveToApproximately(x + w / 2, y + 5)
        elseif idx == 3 then
          m.MoveToApproximately(x + w / 2, y + h + 5)
        end
        m.Click()
    end)
    a2d.WaitForRepaint()

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "PRODOS", "file icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Click an empty
  area within the window. Edit > Select All. Verify that icons within
  the window are selected.
]]
test.Step(
  "focus after click volume icon, click window",
  function()
    a2d.CloseAllWindows()

    a2d.Select("A2.DESKTOP")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("READ.ME")
    a2d.ClearSelection()

    -- click volume icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_x + 5, vol_y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be clicked")

    -- click window
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        m.Click()
    end)
    a2d.WaitForRepaint()

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "PRODOS", "file icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Click an icon
  within the window. Edit > Select All. Verify that icons within the
  window are selected.
]]
test.Step(
  "focus after click volume icon, click file icon",
  function()
    a2d.CloseAllWindows()

    a2d.Select("A2.DESKTOP")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("READ.ME")
    local file_x, file_y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    -- click volume icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_x + 5, vol_y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be clicked")

    -- click file icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_x + 5, file_y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file icon should be clicked")

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "PRODOS", "file icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Click an empty
  space on the desktop. Edit > Select All. Verify that volume icons
  are selected.
]]
test.Step(
  "focus after click volume icon, click desktop",
  function()
    a2d.CloseAllWindows()

    a2d.Select("A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.ClearSelection()

    -- click volume icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + 5, y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be clicked")

    -- click empty space
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
    end)

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "Trash", "volume icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a file icon. Click an empty
  space on the desktop. Edit > Select All. Verify that file icons
  are selected.
]]
test.Step(
  "focus after click file icon, click desktop",
  function()
    a2d.CloseAllWindows()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("READ.ME")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    -- click file icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + 5, y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file icon should be clicked")

    -- click empty space
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
    end)

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "PRODOS", "file icons should be selected")
end)


--[[
  Launch DeskTop. Open a volume window. Drag a selection rectangle so
  that it covers only the top row of pixels of an icon. Verify that
  the icon is selected.
]]
