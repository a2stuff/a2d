--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -flop1 prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]

--[[
  Launch DeskTop. Open a window. Hold Solid-Apple and double-click a
  folder icon. Verify that the folder opens, and that the original
  window closes.
]]
test.Step(
  "Solid Apple Double-Click",
  function()
    desktop.SelectPath("/A2.DESKTOP/EXTRAS")
    local x, y = a2dtest.GetSelectedIconCoords()
    desktop.ClearSelection()

    -- Over "Extras"
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        apple2.PressSA()
        m.DoubleClick()
        apple2.ReleaseSA()
    end)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Open a window. Select a folder icon. Hold
  Solid-Apple and select File > Open. Verify that the folder opens,
  and that the original window closes.
]]
test.Step(
  "Solid Apple File > Open",
  function()
    desktop.SelectPath("/A2.DESKTOP/EXTRAS")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(30, 5)
        apple2.PressSA()
        m.Click()
        m.MoveByApproximately(0, 25)
        m.Click()
        apple2.ReleaseSA()
    end)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Open a window. Select a folder icon. Hold Open-Apple
  and select File > Open. Verify that the folder opens, and that the
  original window closes.
]]
test.Step(
  "Open Apple File > Open",
  function()
    desktop.SelectPath("/A2.DESKTOP/EXTRAS")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(30, 5)
        apple2.PressOA()
        m.Click()
        m.MoveByApproximately(0, 25)
        m.Click()
        apple2.ReleaseOA()
    end)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Open a window. Select a folder icon. Press
  Open-Apple+Solid-Apple+O. Verify that the folder opens, and that the
  original window closes. Repeat with Caps Lock off.
]]
test.Variants(
  {
    {"Open Apple + Solid Apple + O", "O"},
    {"Open Apple + Solid Apple + o", "o"},
  },
  function(idx, name, key)
    desktop.SelectPath("/A2.DESKTOP/EXTRAS")

    a2d.OASAShortcut(key)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Open a window. Select a folder icon. Press
  Open-Apple+Solid-Apple+Down. Verify that the folder opens, and that
  the original window closes.
]]
test.Step(
  "Open Apple + Solid Apple + Down",
  function()
    desktop.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.OASADown()
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Open a window. Select a folder icon. Open the File
  menu, then press Open-Apple+Solid-Apple+O. Verify that the folder
  opens, and the original window closes. Repeat with Caps Lock off.
]]
test.Variants(
  {
    {"With menu showing, Open Apple + Solid Apple + O", "O"},
    {"With menu showing, Open Apple + Solid Apple + o", "o"},
  },
  function(idx, name, key)
    desktop.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(30, 5)
        m.Click()
    end)

    a2d.OASAShortcut(key)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Ensure nothing is selected. Press
  Open-Apple+Solid-Apple+O. Verify that nothing happens. Repeat with
  Caps Lock off.
q]]
test.Variants(
  {
    {"No selection, OA+SA+O", "O"},
    {"No selection, OA+SA+o", "o"},
  },
  function(idx, name, key)
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.OASAShortcut(key)
        a2dtest.WaitForSystemTask()
    end)
end)

--[[
  Launch DeskTop. Ensure nothing is selected. Press
  Open-Apple+Solid-Apple+Down. Verify that nothing happens.
]]
test.Step(
  "No selection, OA+SA+Down",
  function()
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.OASADown()
        a2dtest.WaitForSystemTask()
    end)
end)

--[[
  Ensure failure to open recovers properly, when invoked
  from a non-menu shortcut like OA+SA+Down.
]]
test.Step(
  "OA+SA+Down should not hang if disk was ejected",
  function()
    local drive = s6d1
    local current = drive.filename
    drive:unload()

    desktop.SelectPath("/FLOPPY1")
    a2d.OASADown()
    a2dtest.WaitForAlert({match="volume cannot be found"})
    a2d.DialogOK() -- OK
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectNotHanging()

    drive:load(current)
end)
