a2d.ConfigureRepaintTime(1)

--[[
  Double-click an item. Verify that the appropriate action button
  flashes.
]]
test.Step(
  "Shortcuts picker (in DeskTop)",
  function()
    -- Create a shortcut
    a2d.SelectPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2d.DialogOK()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x+75, dialog_y+30) -- over shortcut
        m.DoubleClick()
        test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "OK", "OK button should flash")
        a2d.WaitForRepaint()
    end)
    a2d.CloseAllWindows()
end)

--[[
  Double-click an item. Verify that the appropriate action button
  flashes.
]]
test.Step(
  "Format/Erase dialog (in DeskTop)",
  function()
    a2d.ClearSelection()

    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_ERASE_DISK-2)
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x+70, dialog_y+40) -- over volume
        m.DoubleClick()
        test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "OK", "OK button should flash")
        a2d.WaitForRepaint()
        a2d.DialogCancel()
    end)
end)

--[[
  Double-click an item. Verify that the appropriate action button
  flashes.
]]
test.Step(
  "Selector (module)",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.ToggleOptionShowShortcutsOnStartup() -- enable
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    a2dtest.ConfigureForSelector()
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x + 100, dialog_y + 30) -- over shortcut
        m.DoubleClick()
        test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "OK", "OK button should flash")
        a2d.WaitForRepaint()
    end)
end)
