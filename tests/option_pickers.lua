test.Step(
  "Shortcuts picker (in DeskTop)",
  function()
    -- Create a shortcut
    a2d.SelectPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2d.DialogOK()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    a2d.InMouseKeysMode(function(m)
        m.GoToApproximately(180,60) -- over shortcut
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
        m.GoToApproximately(150,80) -- over volume
        m.DoubleClick()
        test.Snap("verify OK button flashes")
        a2d.WaitForRepaint()
        a2d.DialogCancel()
    end)
end)

test.Step(
  "Selector (module)",
  function()
    -- Create a shortcut
    a2d.SelectPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2d.DialogOK()

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    a2d.OAShortcut("2") -- Enable "Show shortcuts on startup"
    a2d.CloseWindow()
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1) -- reboot (slot 7)
    a2d.WaitForRestart()

    a2d.InMouseKeysMode(function(m)
        m.GoToApproximately(150,60) -- over shortcut
        m.DoubleClick()
        test.Snap("verify OK button flashes")
        a2d.WaitForRepaint()
    end)
end)
