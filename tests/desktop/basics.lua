--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Open a volume, open a folder, close just the volume window; re-open
  the volume, re-open the folder, ensure the previous window is
  activated.
]]
test.Step(
  "child windows should be re-activated not duplicated",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    local window_id = mgtk.FrontWindow()
    a2d.CycleWindows()
    a2d.CloseWindow()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    test.ExpectEquals(mgtk.FrontWindow(), window_id, "window should be re-activated")
end)

--[[
  Open a window for a volume; open a window for a folder; close volume
  window; close folder window. Repeat 10 times to verify that the
  volume table doesn't have leaks.
]]
test.Step(
  "volume table shouldn't leak",
  function()
    for i = 1, 10 do
      a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})
      a2d.CycleWindows()
      a2d.CloseWindow()
      a2d.CloseWindow()
    end
end)


--[[
  Launch DeskTop. Open a window with only one icon. Drag icon so name
  is to left of window bounds. Ensure icon name renders.
]]
test.Step(
  "icon name should still render even if left is clipped",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.RenamePath("/RAM1/READ.ME","MMMMMMMMMMMMMMM")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(icon_x, icon_y, x+5, icon_y)
    a2d.WaitForRepaint()
    test.Snap("verify icon name is clipped on left but renders")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a volume window with icons. Drag leftmost icon
  to the left to make horizontal scrollbar activate. Click horizontal
  scrollbar so viewport shifts left. Verify dragged icon still
  renders.
]]
test.Step(
  "icon with negative X renders after viewport shifts left",
  function()
    a2d.SelectPath("/A2.DESKTOP/PRODOS")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    for i = 1, 5 do
      local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(icon_x, icon_y)
          m.ButtonDown()
          m.MoveToApproximately(x+5, icon_y)
          m.ButtonUp()
          m.MoveToApproximately(x + 5, y + h + 5)
          m.Click()
          m.Click()
          m.Click()
      end)
      a2d.WaitForRepaint()
    end
    test.Snap("verify icon renders")
end)

--[[
  Launch DeskTop. Open a volume window with icons. Drag leftmost icon
  to the left to make horizontal scrollbar activate. Click horizontal
  scrollbar so viewport shifts left. Move window to the right so it
  overlaps desktop icons. Verify DeskTop doesn't lock up.
]]
test.Step(
  "icon with negative X doesn't mess up volume rendering",
  function()
    a2d.SelectPath("/A2.DESKTOP/PRODOS")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon_x, icon_y)
        m.ButtonDown()
        m.MoveToApproximately(x+5, icon_y)
        m.ButtonUp()
        m.MoveToApproximately(x + 5, y + h + 5)
        m.Click()
        m.Click()
        m.Click()
    end)

    a2d.MoveWindowBy(300, 0)
    a2dtest.ExpectNotHanging()
end)

--[[
  Launch DeskTop. Open a folder using Apple menu (e.g. Control Panels)
  or a shortcut. Verify that the used/free numbers are non-zero.
]]
test.Step(
  "Windows opened from Apple Menu have used/free numbers",
  function()
    a2d.CloseAllWindows()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    emu.wait(1)
    test.Snap("verify the window has non-zero used/free numbers")
end)

--[[
  Launch DeskTop. Open a folder containing subfolders. Select all the
  icons in the folder. Double-click one of the subfolders. Verify that
  the selection is retained in the parent window, with the subfolder
  icons dimmed. Position a child window over top of the parent so it
  overlaps some of the icons. Close the child window. Verify that the
  parent window correctly shows only the previously opened folder as
  selected.
]]
test.Step(
  "Correct selection when child window is closed",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU")
    a2d.Select("CONTROL.PANELS")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.SelectAll()
    local count = #a2d.GetSelectedIcons()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
    end)
    emu.wait(5)
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not have changed")
    while a2dtest.GetFrontWindowTitle():upper() ~= "APPLE.MENU" do
      a2d.CycleWindows()
      emu.wait(1)
    end
    test.Snap("verify selected folder icons are dimmed")
    a2d.CycleWindows()
    local name = a2dtest.GetFrontWindowTitle()
    a2d.CloseWindow()
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), name, "only closed window should be selected")
end)

--[[
  Launch DeskTop. Open two windows. Select a file in one window.
  Activate the other window by clicking its title bar. File >
  Duplicate. Enter a new name. Verify that the window with the
  selected file refreshes.
]]
test.Step(
  "Duplicate activates window",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectPath("/RAM1/READ.ME", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "window should be activated")
    a2d.DuplicateSelection("DUPE")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be activated")
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open two windows. Select a file in one window.
  Activate the other window by clicking its title bar. File > Rename.
  Enter a new name. Verify that the icon is renamed.
]]
test.Step(
  "Rename activates window",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectPath("/RAM1/READ.ME", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "window should be activated")
    a2d.RenameSelection("NEW.NAME")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be activated")
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Double-click on a file that DeskTop can't open (and
  where no `BASIS.SYSTEM` is present). Click OK in the "This file
  cannot be opened." alert. Double-click on the file again. Verify
  that the alert renders with an opaque background.
]]
test.Step(
  "Alerts repaint correctly after file fails to open",
  function()
    a2d.CopyPath("/TESTS/FILE.TYPES/TEST01", "/RAM1")
    a2d.OpenPath("/RAM1")
    a2d.Select("TEST01")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
    end)
    a2dtest.WaitForAlert({match="file cannot be opened"})
    a2d.DialogOK()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
    end)
    a2dtest.WaitForAlert({match="file cannot be opened"})
    test.Snap("verify alert renders with opaque background")
    a2d.DialogOK()

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a window. Create folders A, B and C. Open A,
  and create a folder X. Open B, and create a folder Y. Drag A and B
  into C. Double-click on X. Verify it opens. Double-click on Y.
  Verify it opens. Open C. Double-click on A. Verify that the existing
  A window activates. Double-click on B. Verify that the existing B
  window activates.
]]
test.Step(
  "Re-using reparented windows",
  function()
    a2d.OpenPath("/RAM1")

    -- Create folders A, B, C
    a2d.CreateFolder("A")
    a2d.CreateFolder("B")
    a2d.CreateFolder("C")
    a2d.GrowWindowBy(100, 0)

    -- Open A, created folder X
    a2d.Select("A")
    a2d.OpenSelection({leave_parent=true})
    local a_id = mgtk.FrontWindow()
    a2d.MoveWindowBy(0, 60)
    a2d.CreateFolder("X")
    local x_x, x_y = a2dtest.GetSelectedIconCoords()

    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be active")

    -- Open B, create folder Y
    a2d.Select("B")

    a2d.OpenSelection({leave_parent=true})
    local b_id = mgtk.FrontWindow()
    a2d.MoveWindowBy(200, 60)
    a2d.CreateFolder("Y")
    local y_x, y_y = a2dtest.GetSelectedIconCoords()

    -- Drag A and B onto C
    while a2dtest.GetFrontWindowTitle():upper() ~= "RAM1" do
      a2d.CycleWindows()
      emu.wait(1)
    end
    a2d.Select("A")
    local a_x, a_y = a2dtest.GetSelectedIconCoords()
    a2d.Select("B")
    local b_x, b_y = a2dtest.GetSelectedIconCoords()
    a2d.Select("C")
    local c_x, c_y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(a_x, a_y)
        m.Click()
        m.MoveToApproximately(b_x, b_y)
        apple2.PressOA()
        m.Click()
        apple2.ReleaseOA()
        m.ButtonDown()
        m.MoveToApproximately(c_x, c_y)
        m.ButtonUp()
    end)
    emu.wait(5)

    -- Double-click on X
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x_x, x_y)
        m.DoubleClick()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "X", "X should open")

    -- Double-click on Y
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(y_x, y_y)
        m.DoubleClick()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "Y", "Y should open")

    -- Open C
    while a2dtest.GetFrontWindowTitle():upper() ~= "RAM1" do
      a2d.CycleWindows()
      emu.wait(1)
    end
    a2d.Select("C")
    a2d.OpenSelection()

    -- Double-click on A
    a2d.Select("A")
    local a_x, a_y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(a_x, a_y)
        m.DoubleClick()
    end)
    test.ExpectEquals(mgtk.FrontWindow(), a_id, "existing window should be activated")

    while a2dtest.GetFrontWindowTitle():upper() ~= "C" do
      a2d.CycleWindows()
      emu.wait(1)
    end

    -- Double-click on B
    a2d.Select("B")
    local b_x, b_y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(b_x, b_y)
        m.DoubleClick()
    end)
    test.ExpectEquals(mgtk.FrontWindow(), b_id, "existing window should be activated")
    a2d.CloseAllWindows()

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a volume window containing a folder. Open the
  folder window. Note that the folder icon is dimmed. Close the volume
  window. Open the volume window again. Verify that the folder icon is
  dimmed.
]]
test.Step(
  "folder icon in new window dimmed on creation if it's window is already open",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    a2d.MoveWindowBy(0, 100)
    emu.wait(1)
    test.Snap("note EXTRAS is dimmed")
    a2d.CycleWindows()
    a2d.CloseWindow()
    a2d.OpenPath("/A2.DESKTOP", {keep_windows=true})
    test.Snap("verify EXTRAS is still dimmed")
end)

--[[
  Launch DeskTop. Open a volume window. In the volume window, create a
  new folder F1 and open it. Note that the F1 icon is dimmed. In the
  volume window, create a new folder F2. Verify that the F1 icon is
  still dimmed.
]]
test.Step(
  "folder icon stays dimmed when window is refreshed",
  function()
    a2d.OpenPath("/RAM1")
    a2d.CreateFolder("F1")
    a2d.OpenSelection()
    a2d.MoveWindowBy(0, 100)
    emu.wait(1)
    test.Snap("note F1 is dimmed")
    a2d.CycleWindows()
    a2d.CreateFolder("F2")
    test.Snap("verify F1 is still dimmed")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a volume window containing a file and a folder.
  Open the folder window. Drag the file to the folder icon (not the
  window). Verify that the folder window activates and updates to show
  the file.
]]
test.Step(
  "window updates when file dragged to its folder icon",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.OpenPath("/RAM1/FOLDER", {leave_parent=true})
    a2d.MoveWindowBy(0, 100)
    a2d.CycleWindows()
    a2d.Select("FOLDER")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(5)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "window should be activated")
    a2d.Select("READ.ME")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a volume containing no files. Verify that the
  default minimum window size is used - about 170px by 50px not
  counting title/scrollbars.
]]
test.Step(
  "empty window default size",
  function()
    a2d.OpenPath("/RAM1")
    local x, w, w, h = a2dtest.GetFrontWindowContentRect()
    test.ExpectGreaterThan(w, 150, "window should be ~170px wide")
    test.ExpectLessThan(w, 200, "window should be ~170px wide")

    test.ExpectGreaterThan(h, 40, "window should be ~50px tall")
    test.ExpectLessThan(h, 60, "window should be ~50px tall")
end)

--[[
  Launch DeskTop. Open two windows. Attempt to drag the inactive
  window by dragging its title bar. Verify that the window activates
  and the drag works.
]]
test.Step(
  "drag inactive window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    local x, y = a2dtest.GetFrontWindowDragCoords()

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)

    a2d.Drag(x, y, x + 20, y + 20)
    emu.wait(2)
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "window should be activated")
    local new_x, new_y = a2dtest.GetFrontWindowDragCoords()
    test.ExpectNotEquals(x, new_x, "window should have moved")
end)

--[[
  Launch DeskTop. Open two windows. Click on an icon in the inactive
  window. Verify that the window activates and that the icon is
  selected.
]]
test.Step(
  "icon click in inactive window",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    emu.wait(2)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file icon should be selected")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "window should be activated")
end)

--[[
  Launch DeskTop. Open two volume windows. Click and drag in the
  inactive window without selecting any icons. Verify that the window
  activates and that the drag rectangle appears, and that when the
  button is released the volume icon is selected.
]]
test.Step(
  "volume icon selected after drag in inactive window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local click_x, click_y = x + w - 5, y + h - 5

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.ButtonDown()
        m.MoveByApproximately(20, -20)
        test.Snap("verify window activates and drag rectangle appears")
        m.ButtonUp()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "window should be activated")
end)

--[[
  Launch DeskTop. Open two volume windows. Click in the inactive
  window without selecting any icons. Verify that the window activates
  and the volume icon is selected.
]]
test.Step(
  "volume icon selected after window click - inactive window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local click_x, click_y = x + w - 5, y + h - 5

    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "window should be activated")
end)

--[[
  Launch DeskTop. Open a volume window. Click on the desktop to clear
  selection. Click in an empty area within the window. Verify that the
  volume icon is selected.
]]
test.Step(
  "volume icon selected after window click - no selection",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local click_x, click_y = x + w - 5, y + h - 5

    a2d.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")
end)

--[[
  Launch DeskTop. Open a volume window. Select a file icon. Click in
  an empty area within the window. Verify that the volume icon is
  selected.
]]
test.Step(
  "volume icon selected after window click - file selection",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local click_x, click_y = x + w - 5, y + h - 5

    a2d.Select("READ.ME")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(click_x, click_y)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")
end)

--[[
  Launch DeskTop. Open `/TESTS/FILE.TYPES`. Select `ROOM.A2FC`. File >
  Open. Press Escape. Apple Menu > Calculator (or any other DA).
  Verify that the DA launches correctly.
]]
test.Step(
  "DA launches after image preview",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/ROOM.A2FC")
    emu.wait(5)
    apple2.EscapeKey()

    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CALCULATOR)
    emu.wait(5)
    a2dtest.ExpectAlertNotShowing()
    a2d.CloseWindow()
    a2d.CloseAllWindows()
    a2dtest.ExpectNotHanging()
end)

--[[
  From `BASIC.SYSTEM`, create `/VOL/A/B` on an otherwise empty volume.
  Launch DeskTop. Open `/VOL/A`. Close `/VOL`. Open another volume
  with multiple icons. Verify that the window for `A` still renders
  the icon for `B` correctly.
]]
test.Step(
  "child icon rendering",
  function()
    a2d.CreateFolder("/RAM1/A")
    a2d.CreateFolder("/RAM1/A/B")
    a2d.OpenPath("/RAM1")
    a2d.SelectAndOpen("A", {close_current=false})
    a2d.MoveWindowBy(0, 100)
    a2d.CycleWindows()
    a2d.CloseWindow()
    a2d.OpenPath("/A2.DESKTOP", {keep_windows=true})
    a2d.CycleWindows()
    a2d.MoveWindowBy(20, 0)
    test.Snap("verify icon B rendered correctly")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)


--[[
  Open `TESTS/FILE.TYPES`. Verify that an icon appears for the
  `TEST08` file.
]]
test.Step(
  "File type $08 works",
  function()
    a2d.SelectPath("/TESTS/FILE.TYPES/TEST08")
end)

--[[
  Open `TESTS/FILE.TYPES`. Verify that an icon appears for the
  `TEST01` file.
]]
test.Step(
  "File type $01 works",
  function()
    a2d.SelectPath("/TESTS/FILE.TYPES/TEST01")
end)

--[[
  Configure a system with a SmartPort hard drive, RAMFactor card, and
  Disk II controller card with drives but no floppies. (MAME works)
  Launch DeskTop. Verify that the RAMCard volume icon doesn't flicker
  when the desktop is initially painted. (This will be easier to
  observe in emulators with acceleration disabled.)
]]
test.Step(
  "Drives don't flicker if Disk II devices are empty",
  function()
    a2d.CloseAllWindows()
    a2d.Reboot()
    emu.wait(1)
    a2dtest.MultiSnap(240, "verify RAMCard icon doesn't flicker")
end)
