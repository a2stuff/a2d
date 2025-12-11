--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"

======================================== ENDCONFIG ]]--

test.Step(
  "Previewable types in Apple Menu",
  function()
    a2d.RenamePath("/A2.DESKTOP/APPLE.MENU", "AM")
    a2d.CreateFolder("/A2.DESKTOP/APPLE.MENU")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.FILES/MONARCH", "/A2.DESKTOP/APPLE.MENU")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.FILES/LOREM.IPSUM", "/A2.DESKTOP/APPLE.MENU")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.FILES/FONTS/ATHENS", "/A2.DESKTOP/APPLE.MENU")
    a2d.Reboot()

    a2d.InvokeMenuItem(a2d.APPLE_MENU, 3)
    test.Snap("verify image preview")
    apple2.EscapeKey()
    a2d.WaitForRepaint()

    a2d.InvokeMenuItem(a2d.APPLE_MENU, 4)
    test.Snap("verify text preview")
    a2d.CloseWindow()
    a2d.WaitForRepaint()

    a2d.InvokeMenuItem(a2d.APPLE_MENU, 5)
    test.Snap("verify font preview")
    a2d.CloseWindow()
    a2d.WaitForRepaint()

    a2d.DeletePath("/A2.DESKTOP/APPLE.MENU")
    a2d.RenamePath("/A2.DESKTOP/AM", "APPLE.MENU")
    a2d.CloseAllWindows()
end)

test.Step(
  "Launchable types in Apple Menu",
  function()
    a2d.RenamePath("/A2.DESKTOP/APPLE.MENU", "AM")
    a2d.CreateFolder("/A2.DESKTOP/APPLE.MENU")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.FILES/HELLO.WORLD", "/A2.DESKTOP/APPLE.MENU")
    a2d.CopyPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", "/A2.DESKTOP/APPLE.MENU")
    a2d.Reboot()

    a2d.InvokeMenuItem(a2d.APPLE_MENU, 3)
    a2d.WaitForRestart()
    test.Snap("verify Hello World running")
    apple2.ReturnKey()
    a2d.WaitForRestart()

    a2d.InvokeMenuItem(a2d.APPLE_MENU, 4)
    a2d.WaitForRestart()
    test.Snap("verify BASIC.SYSTEM running")
    apple2.TypeLine("BYE")
    a2d.WaitForRestart()

    a2d.DeletePath("/A2.DESKTOP/APPLE.MENU")
    a2d.RenamePath("/A2.DESKTOP/AM", "APPLE.MENU")
    a2d.CloseAllWindows()
end)

test.Step(
  "Binary files",
  function()
    local icon_x, icon_y = 360, 90
    local window_x, window_y

    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    window_x, window_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+icon_x, window_y+icon_y)
        m.DoubleClick()
    end)
    a2dtest.WaitForAlert()
    a2d.DialogCancel()

    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    window_x, window_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+icon_x, window_y+icon_y)
        m.DoubleClick()
    end)
    a2dtest.WaitForAlert()
    a2d.DialogOK({no_wait=true})
    a2dtest.MultiSnap(40, "verify launches with dialog OK")
    a2d.WaitForRestart()

    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    window_x, window_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        apple2.PressSA()
        m.MoveToApproximately(window_x+icon_x, window_y+icon_y)
        m.DoubleClick()
        apple2.ReleaseSA()
        a2dtest.MultiSnap(30, "verify launches with SA+double click")
        return false -- no explicit exit, since we're exiting desktop
    end)
    a2d.WaitForRestart()

    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN, {no_wait=true})
    a2dtest.MultiSnap(30,"verify launches from menu")
    a2d.WaitForRestart()

    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.OAShortcut("O", {no_wait=true})
    a2dtest.MultiSnap(30,"verify launches from OA shortcut")
    a2d.WaitForRestart()

    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.SAShortcut("O", {no_wait=true})
    a2dtest.MultiSnap(30,"verify launches from SA shortcut")
    a2d.WaitForRestart()
end)

test.Step(
  "renames changing icons",
  function()
    a2d.CopyPath("/A2.DESKTOP/PRODOS", "/RAM1")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM", "/RAM1")

    a2d.SelectPath("/RAM1/PRODOS")
    a2d.RenameSelection("PRODOS") -- avoid case changes
    local pd = a2dtest.SnapshotDHRWithoutClock()
    test.Snap("note selected icon location")
    a2d.RenameSelection("PRODOS.SYSTEM")
    local pds = a2dtest.SnapshotDHRWithoutClock()
    test.Snap("verify icon changes but doesn't move")

    for i = 1, 5 do
      a2d.RenameSelection("PRODOS")
      test.Expect(a2dtest.CompareDHR(pd, a2dtest.SnapshotDHRWithoutClock()), "should not move")
      a2d.RenameSelection("PRODOS.SYSTEM")
      test.Expect(a2dtest.CompareDHR(pds, a2dtest.SnapshotDHRWithoutClock()), "should not move")
    end

    a2d.SelectPath("/RAM1/LOREM.IPSUM")
    a2d.RenameSelection("LOREM.IPSUM") -- avoid case changes
    local txt = a2dtest.SnapshotDHRWithoutClock()
    a2d.RenameSelection("LOREM.SHK")
    local shk = a2dtest.SnapshotDHRWithoutClock()
    a2d.RenameSelection("LOREM.BXY")
    local bxy = a2dtest.SnapshotDHRWithoutClock()
    a2d.RenameSelection("LOREM.BNY")
    local bny = a2dtest.SnapshotDHRWithoutClock()

    for i = 1, 5 do
      a2d.RenameSelection("LOREM.IPSUM")
      test.Expect(a2dtest.CompareDHR(txt, a2dtest.SnapshotDHRWithoutClock()), "should not move")
      a2d.RenameSelection("LOREM.SHK")
      test.Expect(a2dtest.CompareDHR(shk, a2dtest.SnapshotDHRWithoutClock()), "should not move")
      a2d.RenameSelection("LOREM.BXY")
      test.Expect(a2dtest.CompareDHR(bxy, a2dtest.SnapshotDHRWithoutClock()), "should not move")
      a2d.RenameSelection("LOREM.BNY")
      test.Expect(a2dtest.CompareDHR(bny, a2dtest.SnapshotDHRWithoutClock()), "should not move")
    end

    a2d.EraseVolume("RAM1")
end)

test.Step(
  "renaming folders doesn't change them",
  function()
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.RenamePath("/RAM1/FOLDER", "FOLDER.A2FC")
    test.Snap("Verify folder with .A2FC is still a folder")

    a2d.EraseVolume("RAM1")
end)

