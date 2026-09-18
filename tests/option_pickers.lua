--[[
  Double-click an item. Verify that the appropriate action button
  flashes.
]]
test.Step(
  "Shortcuts picker (in DeskTop)",
  function()
    -- Create a shortcut
    desktop.SelectPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.InvokeMenuItem(desktop.SHORTCUTS_MENU, desktop.SHORTCUTS_ADD_A_SHORTCUT)
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    a2d.InvokeMenuItem(desktop.SHORTCUTS_MENU, desktop.SHORTCUTS_DELETE_A_SHORTCUT)
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x+75, dialog_y+30) -- over shortcut
        m.DoubleClick({no_wait=true})
        util.WaitFor(
          "button flash", function()
            return a2dtest.OCRScreen({invert=true}):match("OK")
        end)
        a2dtest.WaitForSystemTask()
    end)
    desktop.CloseAllWindows()
end)

--[[
  Double-click an item. Verify that the appropriate action button
  flashes.
]]
test.Step(
  "Format/Erase dialog (in DeskTop)",
  function()
    desktop.ClearSelection()
    a2dtest.WaitForSystemTask()

    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_ERASE_DISK-2)
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x+70, dialog_y+40) -- over volume
        m.DoubleClick({no_wait=true})
        util.WaitFor(
          "button flash", function()
            return a2dtest.OCRScreen({invert=true}):match("OK")
        end)
        a2dtest.WaitForSystemTask()
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
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    desktop.ToggleOptionShowShortcutsOnStartup() -- enable
    desktop.Reboot()
    a2d.WaitForDesktopReady()
    a2dtest.ConfigureForSelector()
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x + 100, dialog_y + 25) -- over shortcut
        m.DoubleClick({no_wait=true})
        util.WaitFor(
          "button flash", function()
            return a2dtest.OCRScreen({invert=true}):match("OK")
        end)
        a2dtest.WaitForSystemTask()
    end)
end)
