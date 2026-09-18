
--[[
  Launch DeskTop. Apple Menu > About Apple II DeskTop. Click anywhere
  on the screen. Verify that the dialog closes.
]]
test.Step(
  "About dialog closes on click",
  function()
    desktop.CloseAllWindows()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_APPLE_II_DESKTOP)
    a2d.InMouseKeysMode(function(m)
        m.Click()
    end)
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "dialog should have dismissed")
end)

--[[
  Launch DeskTop. Apple Menu > About Apple II DeskTop. Press any
  non-modifier key screen. Verify that the dialog closes.
]]
test.Step(
  "About dialog closes on key",
  function()
    desktop.CloseAllWindows()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_APPLE_II_DESKTOP)
    apple2.Type("A")
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "dialog should have dismissed")
end)

