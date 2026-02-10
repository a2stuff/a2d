--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(2)

--[[
  Put image file in `APPLE.MENU`, start DeskTop. Select it from the
  Apple menu. Verify image is shown.

  Put text file in `APPLE.MENU`, start DeskTop. Select it from the
  Apple menu. Verify text is shown.

  Put font file in `APPLE.MENU`, start DeskTop. Select it from the
  Apple menu. Verify font is shown.
]]
test.Step(
  "Previewable types in Apple Menu",
  function()
    a2d.RenamePath("/A2.DESKTOP/APPLE.MENU", "AM")
    a2d.CreateFolder("/A2.DESKTOP/APPLE.MENU")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/ROOM", "/A2.DESKTOP/APPLE.MENU")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM", "/A2.DESKTOP/APPLE.MENU")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/FONTS/ATHENS", "/A2.DESKTOP/APPLE.MENU")
    a2d.Reboot()
    a2d.WaitForDesktopReady()

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

--[[
  Put BASIC program in `APPLE.MENU`, start DeskTop. Select it from the
  Apple menu. Verify it runs.

  Put System program in `APPLE.MENU`, start DeskTop. Select it from
  the Apple menu. Verify it runs.
]]
test.Step(
  "Launchable types in Apple Menu",
  function()
    a2d.RenamePath("/A2.DESKTOP/APPLE.MENU", "AM")
    a2d.CreateFolder("/A2.DESKTOP/APPLE.MENU")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/HELLO.WORLD", "/A2.DESKTOP/APPLE.MENU")
    a2d.CopyPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", "/A2.DESKTOP/APPLE.MENU")
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.InvokeMenuItem(a2d.APPLE_MENU, 3)
    util.WaitFor(
      "hello world", function()
        return apple2.GrabTextScreen():match("Hello world!")
    end)
    apple2.ReturnKey()
    a2d.WaitForDesktopReady()

    a2d.InvokeMenuItem(a2d.APPLE_MENU, 4)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.DeletePath("/A2.DESKTOP/APPLE.MENU")
    a2d.RenamePath("/A2.DESKTOP/AM", "APPLE.MENU")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open `SAMPLE.MEDIA`. Double-click `KARATEKA.YELL`.
  Verify that an alert is shown. Click Cancel. Verify the alert closes
  but nothing else happens. Repeat, but click OK. Verify that it
  executes.

  Launch DeskTop. Open `SAMPLE.MEDIA`. Hold Solid-Apple and
  double-click `KARATEKA.YELL`. Verify that it executes.

  Launch DeskTop. Open `SAMPLE.MEDIA`. Select `KARATEKA.YELL`. File >
  Open. Verify that it executes.

  Launch DeskTop. Open `SAMPLE.MEDIA`. Select `KARATEKA.YELL`. Press
  Open-Apple+O. Verify that it executes.

  Launch DeskTop. Open `SAMPLE.MEDIA`. Select `KARATEKA.YELL`. Press
  Solid-Apple+O. Verify that it executes.
]]
test.Step(
  "Binary files",
  function()
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.InMouseKeysMode(function(m)
        local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
    end)
    a2dtest.WaitForAlert({match="binary file"})
    a2d.DialogCancel()

    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.InMouseKeysMode(function(m)
        local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
    end)
    a2dtest.WaitForAlert({match="binary file"})
    a2d.DialogOK({no_wait=true})
    a2dtest.MultiSnap(40, "verify launches with dialog OK")
    emu.wait(2) -- finish launching
    a2d.WaitForDesktopReady()

    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.InMouseKeysMode(function(m)
        apple2.PressSA()
        local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
        apple2.ReleaseSA()
        a2dtest.MultiSnap(30, "verify launches with SA+double click")
        return false -- no explicit exit, since we're exiting desktop
    end)
    emu.wait(2) -- finish launching
    a2d.WaitForDesktopReady()

    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN, {no_wait=true})
    a2dtest.MultiSnap(30,"verify launches from menu")
    emu.wait(2) -- finish launching
    a2d.WaitForDesktopReady()

    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.OAShortcut("O", {no_wait=true})
    a2dtest.MultiSnap(30,"verify launches from OA shortcut")
    emu.wait(2) -- finish launching
    a2d.WaitForDesktopReady()

    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.SAShortcut("O", {no_wait=true})
    a2dtest.MultiSnap(30,"verify launches from SA shortcut")
    emu.wait(2) -- finish launching
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Select a SYS file. Rename it to have a .SYSTEM
  suffix. Verify that it has an application (diamond and hand) icon,
  without moving.

  Launch DeskTop. Select a SYS file. Rename it to not have a .SYSTEM
  suffix. Verify that it has a system (computer) icon, without moving.

  Launch DeskTop. Select a TXT file. Rename it to have a .SHK suffix.
  Verify that it has an archive icon, without moving.

  Launch DeskTop. Select a TXT file. Rename it to have a .BXY suffix.
  Verify that it has an archive icon, without moving.

  Launch DeskTop. Select a TXT file. Rename it to have a .BNY suffix.
  Verify that it has an archive icon, without moving.
]]
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

--[[
  Launch DeskTop. File > New Folder.... Name it with a .A2FC suffix.
  Verify that it still has a folder icon.
]]
test.Step(
  "renaming folders doesn't change them",
  function()
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.RenamePath("/RAM1/FOLDER", "FOLDER.A2FC")
    test.Snap("verify folder with .A2FC is still a folder")

    a2d.EraseVolume("RAM1")
end)

