function WaitForIdle()
  apple2.WaitForMemoryRead(0x4054) -- DeskTop MainLoop
end

test.Step(
  "About dialog closes on click",
  function()
    a2d.CloseAllWindows()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP)

    a2dtest.WaitForSystemTask()

    a2d.InMouseKeysMode(function(m)
        m.Click()
    end)

    WaitForIdle()

    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "dialog should have dismissed")
end)
