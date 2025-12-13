--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]--

--[[
  Launch DeskTop. Open a window. Hold Solid-Apple and double-click a
  folder icon. Verify that the folder opens, and that the original
  window closes.
]]--
test.Step(
  "Solid Apple Double-Click",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    -- Over "Extras"
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        apple2.PressSA()
        m.DoubleClick()
        apple2.ReleaseSA()
    end)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Open a window. Select a folder icon. Hold
  Solid-Apple and select File > Open. Verify that the folder opens,
  and that the original window closes.
]]--
test.Step(
  "Solid Apple File > Open",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(30, 5)
        apple2.PressSA()
        m.Click()
        m.MoveByApproximately(0, 25)
        m.Click()
        apple2.ReleaseSA()
    end)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Open a window. Select a folder icon. Hold Open-Apple
  and select File > Open. Verify that the folder opens, and that the
  original window closes.
]]--
test.Step(
  "Open Apple File > Open",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(30, 5)
        apple2.PressOA()
        m.Click()
        m.MoveByApproximately(0, 25)
        m.Click()
        apple2.ReleaseOA()
    end)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Open a window. Select a folder icon. Press
  Open-Apple+Solid-Apple+O. Verify that the folder opens, and that the
  original window closes. Repeat with Caps Lock off.
]]--
test.Variants(
  {
    "Open Apple + Solid Apple + O",
    "Open Apple + Solid Apple + o",
  },
  function(idx)
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")

    if idx == 1 then
      a2d.OASAShortcut("O")
    else
      a2d.OASAShortcut("o")
    end

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Open a window. Select a folder icon. Press
  Open-Apple+Solid-Apple+Down. Verify that the folder opens, and that
  the original window closes.
]]--
test.Step(
  "Open Apple + Solid Apple + Down",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.OASADown()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Open a window. Select a folder icon. Open the File
  menu, then press Open-Apple+Solid-Apple+O. Verify that the folder
  opens, and the original window closes. Repeat with Caps Lock off.
]]--
test.Variants(
  {
    "With menu showing, Open Apple + Solid Apple + O",
    "With menu showing, Open Apple + Solid Apple + o",
  },
  function(idx)
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(30, 5)
        m.Click()
    end)

    if idx == 1 then
      a2d.OASAShortcut("O")
    else
      a2d.OASAShortcut("o")
    end
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")
end)

--[[
  Launch DeskTop. Ensure nothing is selected. Press
  Open-Apple+Solid-Apple+O. Verify that nothing happens. Repeat with
  Caps Lock off.
q]]--
test.Variants(
  {
    "No selection, OA+SA+O",
    "No selection, OA+SA+o",
  },
  function(idx)
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        if idx == 1 then
          a2d.OASAShortcut("O")
        else
          a2d.OASAShortcut("o")
        end
    end)
end)

--[[
  Launch DeskTop. Ensure nothing is selected. Press
  Open-Apple+Solid-Apple+Down. Verify that nothing happens.
]]--
test.Step(
  "No selection, OA+SA+Down",
  function()
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.OASADown()
        a2d.WaitForRepaint()
    end)
end)

--[[
  Ensure failure to open recovers properly, when invoked
  from a non-menu shortcut like OA+SA+Down.
]]--
test.Step(
  "OA+SA+Down should not hang if disk was ejected",
  function()
    local drive = apple2.GetDiskIIS6D1()
    local current = drive.filename
    drive:unload()

    a2d.SelectPath("/FLOPPY1")
    a2d.OASADown()
    a2d.WaitForRepaint()
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()
    a2dtest.ExpectNotHanging()

    drive:load(current)
end)
