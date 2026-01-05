a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Apple > About Apple II DeskTop animates open/closed",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP, {no_wait=true})
    a2dtest.MultiSnap(15, "window animates open")
    emu.wait(5)
    a2d.CloseWindow({no_wait=true})
    a2dtest.MultiSnap(15, "window animates closed")
    emu.wait(5)
end)

test.Step(
  "Ensure About > Apple II DeskTop doesn't trash memory",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP)
    emu.wait(1)
    apple2.EscapeKey()
    emu.wait(1)
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "dialog should have dismissed")
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS")
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "previous windows should have closed")
end)

test.Step(
  "Apple > About This Apple II animates open/closed",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II, {no_wait=true})
    a2dtest.MultiSnap(15, "window animates open")
    emu.wait(5)
    a2d.CloseWindow({no_wait=true})
    a2dtest.MultiSnap(15, "window animates closed")
    emu.wait(5)
end)

test.Step(
  "Date & Time from menu clock click animates open/closed",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH, 0)
        m.Click()
        a2dtest.MultiSnap(15, "window animates open")
    end)

    emu.wait(5)
    a2d.CloseWindow({no_wait=true})
    a2dtest.MultiSnap(15, "window animates closed")
    emu.wait(5)
end)
