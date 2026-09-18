
test.Step(
  "Apple > About Apple II DeskTop animates open/closed",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP, {no_wait=true})
    a2dtest.MultiSnap(30, "window animates open")
    a2dtest.WaitForSystemTask()
    a2d.CloseWindow({no_wait=true})
    a2dtest.MultiSnap(30, "window animates closed")
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Ensure About > Apple II DeskTop doesn't trash memory",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP)
    a2dtest.WaitForSystemTask()
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "dialog should have dismissed")
    a2d.OpenWindow("/A2.DESKTOP/APPLE.MENU/TOYS")
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "previous windows should have closed")
end)

test.Step(
  "Apple > About This Apple II animates open/closed",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II, {no_wait=true})
    a2dtest.MultiSnap(30, "window animates open")
    a2dtest.WaitForSystemTask()
    a2d.CloseWindow({no_wait=true})
    a2dtest.MultiSnap(30, "window animates closed")
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Date & Time from menu clock click animates open/closed",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH, 0)
        m.Click()
        a2dtest.MultiSnap(30, "window animates open")
    end)

    a2dtest.WaitForSystemTask()
    a2d.CloseWindow({no_wait=true})
    a2dtest.MultiSnap(30, "window animates closed")
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Ensure animation ends on correct icon after preview",
  function()
    a2d.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/JESU.JOY")

    util.WaitFor(
      "player showing", function()
        return a2dtest.OCRFrontWindowContent():match("Electric Duet")
      end, {wait=1})

    apple2.EscapeKey()
    a2dtest.MultiSnap(120, "should animate back to JESU.JOY icon")
    a2dtest.WaitForSystemTask()
end)
