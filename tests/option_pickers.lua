test.Step(
  "Shortcuts picker (in DeskTop)",
  function()
    -- Create a shortcut
    a2d.SelectPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2d.DialogOK()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(180,60) -- over shortcut
        m.DoubleClick()
        test.Snap("verify OK button flashes")
        a2d.WaitForRepaint()
    end)
    a2d.CloseAllWindows()
end)

test.Step(
  "Format/Erase dialog (in DeskTop)",
  function()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_ERASE_DISK-2)
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(150,80) -- over volume
        m.DoubleClick()
        test.Snap("verify OK button flashes")
        a2d.WaitForRepaint()
        a2d.DialogCancel()
    end)
end)

test.Step(
  "Selector (module)",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.ToggleOptionShowShortcutsOnStartup() -- enable
    a2d.Restart()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(150,60) -- over shortcut
        m.DoubleClick()
        test.Snap("verify OK button flashes")
        a2d.WaitForRepaint()
    end)
end)
