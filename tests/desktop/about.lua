a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Apple Menu > About Apple II DeskTop. Click anywhere
  on the screen. Verify that the dialog closes.
]]
test.Step(
  "About dialog closes on click",
  function()
    a2d.CloseAllWindows()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP)
    a2d.InMouseKeysMode(function(m)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "dialog should have dismissed")
end)

--[[
  Launch DeskTop. Apple Menu > About Apple II DeskTop. Press any
  non-modifier key screen. Verify that the dialog closes.
]]
test.Step(
  "About dialog closes on key",
  function()
    a2d.CloseAllWindows()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP)
    apple2.Type("A")
    emu.wait(1)
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "dialog should have dismissed")
end)

