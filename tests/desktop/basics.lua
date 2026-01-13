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
  Launch DeskTop. Open a volume window with many items. Adjust the
  window so that the scrollbars are active. Drag a file icon slightly
  within the middle of the view, so that the scrollbars don't change.
  Verify that the scrollbars don't repaint/flicker.
]]
test.Step(
  "moving an icon doesn't always cause scrollbars to repaint",
  function()
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    a2d.GrowWindowBy(-100, -50)
    emu.wait(1)
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveByApproximately(10, 10)
        a2dtest.ExpectRepaintFraction(
          0, 0.1,
          function()
            m.ButtonUp()
            emu.wait(1)
          end,
          "scrollbars do not repaint")
    end)
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
  Launch DeskTop. Open a volume window with icons. Resize the window
  so that the horizontal scrollbar is active. Move the window so the
  left edge of the scrollbar thumb is off-screen to the left. Click on
  the right arrow, and verify that the window scrolls correctly.
  Repeat for the page right region.
]]
test.Variants(
  {
    {"scrollbar with clipped thumb still works - right arrow", "arrow"},
    {"scrollbar with clipped thumb still works - right pager", "page"},
  },
  function(idx, name, where)
    a2d.OpenPath("/A2.DESKTOP")
    a2d.GrowWindowBy(-50, 0)
    a2d.MoveWindowBy(-40, 0)
    emu.wait(1)
    test.Snap("verify thumb cut off on left")

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        if where == "arrow" then
          m.MoveToApproximately(x + w - 5, y + h + 5)
        else
          m.MoveToApproximately(x + w - 50, y + h + 5)
        end
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify window scrolled right")
end)

--[[
  Launch DeskTop. Open a window with a single icon. Move the icon so
  it overlaps the left edge of the window. Verify scrollbar appears.
  Hold scroll arrow. Verify icon scrolls into view, and eventually the
  scrollbar deactivates. Repeat with right edge.
]]
test.Step(
  "scrollbar deactivates when not needed",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.SelectPath("/RAM1/READ.ME")

    -- Left
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.Drag(icon_x, icon_y, x+5, icon_y)
    a2d.WaitForRepaint()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + 5, y + h + 5)
        m.ButtonDown()
        emu.wait(1)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")

    -- Right
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.Drag(icon_x, icon_y, x+w-5, icon_y)
    a2d.WaitForRepaint()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h + 5)
        m.ButtonDown()
        emu.wait(1)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a window with 11-15 icons. Verify scrollbars
  are not active.
]]
test.Step(
  "No scrollbars for 11-15 icons",
  function()
    a2d.OpenPath("/RAM1")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("10 FOR I = 1 TO 15 : ?CHR$(4)\"CREATE F\"I : NEXT")
    apple2.TypeLine("RUN")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    a2d.OpenPath("/RAM1")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Open a window that will require vertical scrollbars. Verify that the
  scrollbars do not repaint after the contents.
]]
test.Step(
  "Scrollbars in new window paint before items",
  function()
    a2d.OpenPath("/TESTS", {no_wait=true})
    a2dtest.MultiSnap(60, "verify scrollbars paint before items")
end)

--[[
  Open an empty window. Exit desktop, add a file to the directory, and
  restart. Verify scrollbars don't appear.
]]
test.Step(
  "No scrollbars when file added to empty directory outside DeskTop",
  function()
    a2d.OpenPath("/RAM1")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("10 NEW")
    apple2.TypeLine("SAVE MMMMMMMMMMMMMMM")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a volume window with multiple icons but that do
  not require the scrollbars to be active. Drag the first icon over to
  the right so that it is partially clipped by the window's right or
  bottom edge. Verify that the appropriate scrollbars activate.
]]
test.Step(
  "scrollbar activates even for first icon if on right",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS")
    emu.wait(1)
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")

    apple2.DownArrowKey() -- select first
    emu.wait(1)

    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.Drag(icon_x, icon_y, x + w - 10, icon_y)
    a2d.WaitForRepaint()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")
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
  Launch DeskTop. Open a window containing folders and files. Scroll
  the window so a folder is partially or fully outside the visual area
  (e.g. behind title bar, header, or scrollbars). Drag a file icon
  over the obscured part of the folder. Verify the folder doesn't
  highlight.
]]
test.Step(
  "dragging over obscured part of folder doesn't highlight",
  function()
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.OpenPath("/RAM1")

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.Select("FOLDER")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x1, y1+5, x1, y1-5)

    a2d.Select("READ.ME")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x2, y2)
        m.ButtonDown()
        m.MoveToApproximately(x2, y+5) -- Y only first
        m.MoveToApproximately(x1, y+5)
        emu.wait(5)
        test.Snap("verify folder not highlighted")
        m.ButtonUp()
    end)
    emu.wait(1)

    a2d.Select("READ.ME") -- verify not moved

    -- cleanup
    a2d.EraseVolume("/RAM1")
end)

--[[
  Launch DeskTop. Open a window containing folders and files. Scroll
  the window so a folder is partially or fully outside the visual area
  (e.g. behind title bar, header, or scrollbars). Drag a file icon
  over the visible part of the folder. Verify the folder highlights
  but doesn't render past window bounds. Continue dragging over the
  obscured part of the folder. Verify that the folder unhighlights.
]]
test.Step(
  "dragging over visible part of folder highlights, but highlights if needed",
  function()
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.OpenPath("/RAM1")

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.Select("FOLDER")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x1, y1+5, x1, y1-5)

    a2d.Select("READ.ME")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x2, y2)
        m.ButtonDown()
        m.MoveToApproximately(x1, y+15)
        emu.wait(5)
        test.Snap("verify folder highlighted")
        m.MoveToApproximately(x1, y+5)
        emu.wait(5)
        test.Snap("verify folder not highlighted")
        m.ButtonUp()
    end)
    emu.wait(1)

    a2d.Select("READ.ME") -- verify not moved

    -- cleanup
    a2d.EraseVolume("/RAM1")
end)

--[[
  Launch DeskTop. Open two windows containing folders and files. Drag
  a file icon from one window over a folder in the other window.
  Verify that the folder highlights. Drop the file. Verify that the
  file is copied or moved to the correct target folder.
]]
test.Step(
  "drop targets correct folder",
  function()
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.SelectPath("/RAM1/FOLDER")
    a2d.MoveWindowBy(0, 100)
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        test.Snap("verify folder highlighted")
        m.ButtonUp()
    end)
    emu.wait(5)

    a2d.SelectPath("/RAM1/FOLDER/READ.ME")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open two windows containing folders and files.
  Scroll one window so a folder is partially or fully outside the
  visual area (e.g. behind title bar, header, or scrollbars). Drag a
  file icon from the other window over the obscured part of the
  folder. Verify the folder doesn't highlight.
]]
test.Step(
  "obscured folder doesn't highlight",
  function()
    a2d.OpenPath("/RAM1")
    -- Create two rows of icons
    for i = 1, 6 do
      a2d.CreateFolder("F" .. i)
    end
    -- Determine deltas
    a2d.OpenPath("/RAM1")
    apple2.DownArrowKey() -- F1
    local f1_x, f1_y = a2dtest.GetSelectedIconCoords()
    apple2.DownArrowKey() -- F6
    local f6_x, f6_y = a2dtest.GetSelectedIconCoords()
    local delta_x, delta_y = f1_x - f6_x, f1_y - f6_y

    -- Obscure first row
    a2d.OpenPath("/RAM1")
    a2d.GrowWindowBy(0, -100)
    apple2.DownArrowKey() -- F1
    apple2.DownArrowKey() -- F6
    emu.wait(1)
    local f6_x, f6_y = a2dtest.GetSelectedIconCoords()
    local dst_x, dst_y = f6_x + delta_x, f6_y + delta_y

    a2d.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    a2d.MoveWindowBy(0, 80)
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        emu.wait(1)
        test.Snap("verify obscured folder does not highlight")
        m.MoveToApproximately(src_x, src_y)
        m.ButtonUp()
    end)

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open two windows containing folders and files.
  Scroll one window so a folder is partially or fully outside the
  visual area (e.g. behind title bar, header, or scrollbars). Drag a
  file icon from the other window over the visible part of the folder.
  Verify the folder highlights but doesn't render past window bounds.
  Continue dragging over the obscured part of the folder. Verify that
  the folder unhighlights.
]]
test.Step(
  "partially obscured folder highlights only visible part",
  function()
    a2d.OpenPath("/RAM1")
    -- Create two rows of icons
    for i = 1, 6 do
      a2d.CreateFolder("F" .. i)
    end
    -- Determine deltas
    a2d.OpenPath("/RAM1")
    apple2.DownArrowKey() -- F1
    local f1_x, f1_y = a2dtest.GetSelectedIconCoords()
    apple2.DownArrowKey() -- F6
    local f6_x, f6_y = a2dtest.GetSelectedIconCoords()
    local delta_x, delta_y = f1_x - f6_x, f1_y - f6_y

    -- Partially obscure first row
    a2d.OpenPath("/RAM1")
    a2d.GrowWindowBy(0, -10)
    apple2.DownArrowKey() -- F1
    apple2.DownArrowKey() -- F6
    emu.wait(1)
    local f6_x, f6_y = a2dtest.GetSelectedIconCoords()
    local dst_x, dst_y = f6_x + delta_x, f6_y + delta_y

    a2d.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    a2d.MoveWindowBy(0, 80)
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y+5)
        emu.wait(1)
        test.Snap("verify partially obscured folder highlights correctly")
        m.MoveToApproximately(dst_x, dst_y-5)
        emu.wait(1)
        test.Snap("verify partially obscured folder does not highlight if cursor outside bounds")
        m.MoveToApproximately(src_x, src_y)
        m.ButtonUp()
    end)

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a window containing folders and files. Open
  another window, for an empty volume. Drag an icon from the first to
  the second. Ensure no scrollbars activate in the target window.
]]
test.Step(
  "Dragging file to empty window doesn't activate scrollbars",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0, 90)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.OpenPath("/A2.DESKTOP", {keep_windows=true})
    a2d.GrowWindowBy(0, -40)
    a2d.Select("READ.ME")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(icon_x, icon_y, dst_x, dst_y)
    emu.wait(1)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be activated")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a window containing folders and files, with no
  scrollbars active. Open another window. Drag an icon from the first
  to the second. Ensure no scrollbars activate in the source window.
]]
test.Step(
  "Moving file doesn't activate source window scrollbars",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.CreateFolder("/RAM1/FOLDER")

    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0, 90)

    a2d.SelectAndOpen("FOLDER", {leave_parent=true})
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.CycleWindows()

    a2d.Select("READ.ME")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(icon_x, icon_y, dst_x, dst_y)
    emu.wait(1)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "window should be activated")
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be activated")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    a2d.EraseVolume("RAM1")
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
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
    end)
    a2dtest.WaitForAlert()
    test.Snap("verify alert renders with opaque background")
    a2d.DialogOK()

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open
  `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789/ABCDEF123`.
  Try to copy a file into the folder. Verify that stray pixels do not
  appear in the top line of the screen.
]]
test.Step(
  "Copy file into folder with overlong path",
  function()
    a2d.OpenPath("/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789/ABCDEF123")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    a2d.MoveWindowBy(0, 80)
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, x+w/2, y+h/2)
    emu.wait(1)
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    local dhr = apple2.SnapshotDHR()
    for i = 0, apple2.SCREEN_COLUMNS-1 do
      test.ExpectEquals(dhr[i], 0x7F, "top pixels of screen should not be dirty")
    end
end)

--[[
  Launch DeskTop. Select multiple volume icons (at least 4). Drag the
  bottom icon up so that the top two icons are completely off the
  screen. Release the mouse button. Drag the icons back down. Verify
  that while dragging, all icons have outlines, and when done dragging
  all icons reposition correctly.
]]
test.Step(
  "Volume icons offscreen",
  function()
    a2d.CloseAllWindows()
    emu.wait(1)
    a2d.SelectAll()
    test.Snap("selection?")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "Trash", "trash should be first")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(x, 20)
        m.ButtonUp()
        emu.wait(1)
        test.Snap("verify icons mostly offscreen")
        m.ButtonDown()
        m.MoveToApproximately(x, y)
        emu.wait(1)
        test.Snap("verify icons have drag outlines")
        m.ButtonUp()
        emu.wait(1)
        test.Snap("verify icons reposition correctly")
    end)
end)

--[[
  Launch DeskTop. Open a window with at least 3 rows of icons.
  Position the window at the top of the screen. Edit > Select All.
  Drag an icon from the bottom row so that the top icons end up
  completely off-screen. Release the mouse button. Drag the icons back
  down. Verify that all icons reposition correctly.
]]
test.Step(
  "Dragging windowed icons offscreen",
  function()
    a2d.OpenPath("/TESTS")
    a2d.SelectAll()
    local icons = a2d.GetSelectedIcons()
    local icon1 = icons[1] -- top row
    local icon11 = icons[11] -- bottom row
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon11.x+5, icon11.y+5)
    end)
    local dx, dy = 0, icon11.y - icon1.y
    a2dtest.ExpectNothingChanged(function()
        a2d.InMouseKeysMode(function(m)
            m.ButtonDown()
            m.MoveByApproximately(dx, -dy)
            m.ButtonUp()
            emu.wait(5)

            m.ButtonDown()
            m.MoveByApproximately(dx, dy)
            m.ButtonUp()
            emu.wait(5)
        end)
    end)
end)

--[[
  Launch DeskTop. Open a window with multiple icons. Select multiple
  icons (e.g. 3). Start dragging the icons. Note the shape of the drag
  outlines. Drag over a volume icon. Verify that the drag outline does
  not become permanently clipped.
]]
test.Step(
  "drag outlines don't become clipped",
  function()
    a2d.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS")
    a2d.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        m.MoveToApproximately(src_x+5, src_y+5)
        test.Snap("verify drag outlines still correct")
        m.MoveToApproximately(src_x, src_y)
        m.ButtonUp()
    end)
end)

--[[
  Launch DeskTop. Open a window with multiple icons. Resize the window
  so some of the icons aren't visible without scrolling. Edit > Select
  All. Drag the icons. Verify that drag outlines are shown even for
  hidden icons.
]]
test.Step(
  "Drag outlines shown for obscured icons",
  function()
    a2d.OpenPath("/TESTS")
    a2d.GrowWindowBy(-200, -200)
    a2d.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(src_x+5, src_y+5)
        test.Snap("verify drag outlines for obscured icons")
        m.MoveToApproximately(src_x, src_y)
        m.ButtonUp()
    end)
end)

--[[
  Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Edit > Select All.
  Start dragging the icons. Verify that the drag is not prevented.
]]
test.Step(
  "Can drag unlimited icons",
  function()
    a2d.OpenPath("/TESTS/HUNDRED.FILES")
    emu.wait(5)
    a2d.SelectAll()
    emu.wait(5)
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveByApproximately(10, 10)
        test.Snap("verify drag is active")
        m.ButtonUp()
        m.MoveByApproximately(-10, -10)
    end)
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
  Launch DeskTop. Select a volume icon. Drag it over an empty space on
  the desktop. Release the mouse button. Verify that the icon is
  moved.
]]
test.Step(
  "Move volume icon",
  function()
    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()

        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
        m.ButtonUp()
    end)

    local new_x, new_y = a2dtest.GetSelectedIconCoords()
    test.ExpectNotEquals(x, new_x, "icon should have moved")
    test.ExpectNotEquals(y, new_y, "icon should have moved")

    -- cleanup
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Select a volume icon. Drag it over an empty space on
  the desktop. Without releasing the mouse button, press the Escape
  key. Verify that the drag is canceled and the icon does not move.
]]
-- TODO: Since Esc exits MouseKeys mode, can't test this yet.

--[[
  Launch DeskTop. Select a volume icon. Drag it over an empty space on
  the desktop. Hold either Apple key or both Apple keys and release
  the mouse button. Verify that the drag is canceled and the icon does
  not move.
]]
test.Variants(
  {
    {"Drop volume icon - with OA", apple2.PressOA, apple2.ReleaseOA},
    {"Drop volume icon - with SA", apple2.PressSA, apple2.ReleaseSA},
    {"Drop volume icon - with OA+SA",
     function() apple2.PressOA() apple2.PressSA() end,
     function() apple2.ReleaseOA() apple2.ReleaseSA() end
    },
  },
  function(idx, name, press, release)
    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()

        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)

        press()
        m.ButtonUp()
        release()
    end)

    local new_x, new_y = a2dtest.GetSelectedIconCoords()
    test.ExpectEquals(x, new_x, "icon should not have moved")
    test.ExpectEquals(y, new_y, "icon should not have moved")
end)

--[[
  Launch DeskTop. Select a volume icon. Drag it over another icon on
  the desktop, which should highlight. Without releasing the mouse
  button, press the Escape key. Verify that the drag is canceled, the
  target icon is unhighlighted, and the dragged icon does not move.
]]
-- TODO: Since Esc exits MouseKeys mode, can't test this yet.

--[[
  Launch DeskTop. Select a file icon. Drag it over an empty space in
  the window. Without releasing the mouse button, press the Escape
  key. Verify that the drag is canceled and the icon does not move.
]]
-- TODO: Since Esc exits MouseKeys mode, can't test this yet.

--[[
  Launch DeskTop. Select a file icon. Drag it over a folder icon,
  which should highlight. Without releasing the mouse button, press
  the Escape key. Verify that the drag is canceled, the target icon is
  unhighlighted, and the dragged icon does not move.
]]
-- TODO: Since Esc exits MouseKeys mode, can't test this yet.

--[[
  Launch DeskTop. Clear selection. Hold both Open-Apple and
  Solid-Apple and start to drag a volume icon. Verify that the drag
  outline of the volume is shown.
]]
test.Step(
  "can OA+SA drag a volume icon",
  function()
    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        apple2.PressOA()
        apple2.PressSA()
        m.ButtonDown()
        m.MoveByApproximately(-100, 0)
        test.Snap("verify drag outline visible")
        m.ButtonUp()
        apple2.ReleaseSA()
        apple2.ReleaseOA()
    end)
end)

--[[
  Launch DeskTop. Open `/TESTS/FOLDER`. Start dragging `FLE` and do
  not release the button. Drag it over then off `SUBFOLDER`. Verify
  the folder highlights/unhighlights. Drag it over then off a volume
  icon. Verify that the volume icon highlights/unhighlights. Drag it
  over the folder icon again. Verify that the folder highlights.
]]
test.Step(
  "Multiple drop target highlighting during drags",
  function()
    a2d.SelectPath("/RAM1")
    local volume_x, volume_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/TESTS/FOLDER")
    a2d.Select("SUBFOLDER")
    local folder_x, folder_y = a2dtest.GetSelectedIconCoords()

    a2d.Select("FILE")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()

        m.MoveToApproximately(folder_x, folder_y)
        test.Snap("verify folder highlighted")
        m.MoveByApproximately(-10, -10)
        test.Snap("verify folder not highlighted")

        m.MoveToApproximately(volume_x, volume_y)
        test.Snap("verify folder highlighted")
        m.MoveByApproximately(-10, -10)
        test.Snap("verify folder not highlighted")

        m.MoveToApproximately(folder_x, folder_y)
        test.Snap("verify folder highlighted")
        m.MoveByApproximately(-10, -10)
        test.Snap("verify folder not highlighted")

        m.MoveToApproximately(x, y)
        m.ButtonUp()
    end)
end)

--[[
* Repeat the following:
  * For these permutations, as the specified window area:
    * Title bar
    * Scroll bars
    * Resize box
    * Header (items/in disk/available)
  * Verify:
    * Launch DeskTop. Open a window with a file icon. Drag the icon so that the mouse pointer is over the same window's specified area. Release the mouse button. Verify that the icon does not move.
    * Launch DeskTop. Open two windows for different volumes. Drag an icon from one window over the specified area of the other window. Release the mouse button. Verify that the file is copied to the target volume.
]]
test.Variants(
  {
    {"Drop icon on title bar", "titlebar"},
    {"Drop icon on scroll bar", "scrollbar"},
    {"Drop icon on resize box", "resizebox"},
    {"Drop icon on header", "header"},
  },
  function(idx, name, where)
    function GetDropCoords()
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()
      if where == "titlebar" then
        return x + w / 2, y - 5 -- title bar
      elseif where == "scrollbar" then
        return x + w / 2, y + h + 5 -- scroll bar
      elseif where == "resizebox" then
        return x + w + 5, y + h + 5 -- resize box
      elseif where == "header" then
        return x + w / 2, y + 5 -- header
      end
    end

    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    -- Same window
    local dst_x, dst_y = GetDropCoords()
    a2d.InMouseKeysMode(function(m)
        m.Home()
    end)
    a2dtest.ExpectNothingChanged(function()
        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(src_x, src_y)
            m.ButtonDown()
            m.MoveToApproximately(dst_x, dst_y)
            m.ButtonUp()
            m.Home()
        end)
    end)

    -- Other window
    a2d.OpenPath("/RAM1", {keep_windows=true})
    a2d.MoveWindowBy(0, 80)
    dst_x, dst_y = GetDropCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(5)
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "file should have copied")

    -- cleanup
    a2d.EraseVolume("RAM1")
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

--[[
* Launch DeskTop. Open `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789`. Rename the `/TESTS` volume to `/TESTSXXXXXXXXXX` so that the total path length of the innermost files would be longer than 64 characters. Repeat the following operations, and verify that an error is shown and DeskTop doesn't crash or hang:
  * Select the `ABCDEF123` folder. File > Open.
  * Select the `ABCDEF123` folder. File > Get Info.
  * Select the `ABCDEF123` folder. File > Rename
  * Select the `ABCDEF123` folder. File > Duplicate
  * Select the `ABCDEF123` folder. File > Copy To... (and pick a target)
  * Select the `ABCDEF123` folder. Shortcuts > Add a Shortcut...
  * Drag a file icon onto the `ABCDEF123` folder.
  * Drag the `ABCDEF123` folder to another volume.
  * Drag the `ABCDEF123` folder to the Trash.
  * Repeat the previous cases, but with `LONGIMAGE` file.
]]
test.Variants(
  {
    {"overlong paths - folder", "folder"},
    {"overlong paths - file", "file"},
  },
  function(idx, name, which)
    a2d.OpenPath("/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789")
    emu.wait(1)
    a2d.SelectPath("/TESTS", {keep_windows=true})
    a2d.RenameSelection("TESTSXXXXXXXXXX")
    a2d.FocusActiveWindow()
    if which == "folder" then
      a2d.Select("ABCDEF123")
    else
      a2d.Select("LONGIMAGE")
    end
    local target_x, target_y = a2dtest.GetSelectedIconCoords()

    a2d.OAShortcut("O") -- File > Open
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.OAShortcut("I") -- File > Get Info
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    apple2.ReturnKey() -- File > Rename
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.CopySelectionTo("/RAM1") -- File > Copy To...
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- Drag file to folder
    if which == "folder" then
      a2d.Select("LONGIMAGE")
      local src_x, src_y = a2dtest.GetSelectedIconCoords()
      a2d.Drag(src_x, src_y, target_x, target_y)
      a2dtest.WaitForAlert()
      a2d.DialogOK()
    end

    -- Drag to volume
    a2d.SelectPath("/RAM1", {keep_windows=true})
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(target_x, target_y, vol_x, vol_y)
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- Drag folder to Trash
    a2d.SelectPath("/Trash", {keep_windows=true})
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(target_x, target_y, trash_x, trash_y)
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.RenamePath("/TESTSXXXXXXXXXX", "TESTS")
end)

--[[
  Copy `MODULES/SHOW.IMAGE.FILE` to the `APPLE.MENU` folder. Restart.
  Open `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789`.
  Rename the `/TESTS` volume to `/TESTSXXXXXXXXXX`. Select the
  `LONGIMAGE` file. Apple Menu > Show Image File. Verify that an alert
  is shown.
]]
test.Step(
  "overlong paths - launching DAs with selection",
  function()
    a2d.CopyPath("/A2.DESKTOP/MODULES/SHOW.IMAGE.FILE", "/A2.DESKTOP/APPLE.MENU")
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.SelectPath("/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789/LONGIMAGE")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.SelectPath("/TESTS", {keep_windows=true})
    a2d.RenameSelection("TESTSXXXXXXXXXX")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)

    a2d.InvokeMenuItem(a2d.APPLE_MENU, -1)
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.RenamePath("/TESTSXXXXXXXXXX", "TESTS")
    a2d.DeletePath("/A2.DESKTOP/APPLE.MENU/SHOW.IMAGE.FILE")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Open `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789`. Copy
  `APPLE.MENU/KEY.CAPS` to the folder. Rename the `/TESTS` volume to
  `/TESTSXXXXXXXXXX`. Select the copy of `KEY.CAPS`. File > Open.
  Verify that an alert is shown.
]]
test.Step(
  "overlong paths - launching DAs",
  function()
    a2d.CopyPath("/A2.DESKTOP/APPLE.MENU/KEY.CAPS",
                 "/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789")
    a2d.SelectPath("/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789/KEY.CAPS")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/TESTS", {keep_windows=true})
    a2d.RenameSelection("TESTSXXXXXXXXXX")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
    end)
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2d.RenamePath("/TESTSXXXXXXXXXX", "TESTS")
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
* Repeat the following test cases for these operations: Copy, Move, Delete:
  * Select multiple files. Start the operation. During the initial count of the files, press Escape. Verify that the count is canceled and the progress dialog is closed, and that the window contents do not refresh.
  * Select multiple files. Start the operation. After the initial count of the files is complete and the actual operation has started, press Escape. Verify that the operation is canceled and the progress dialog is closed, and that (apart from the source window for Copy) the window contents do refresh.
]]
test.Variants(
  {
    {"copy aborted during enumeration", "copy", "during"},
    {"move aborted during enumeration", "move", "during"},
    {"delete aborted during enumeration", "delete", "during"},
    {"copy aborted after enumeration", "copy", "after"},
    {"move aborted after enumeration", "move", "after"},
    {"delete aborted after enumeration", "delete", "after"},
  },
  function(idx, name, what, when)
    local dst_x, dst_y

    if what == "delete" then
      a2d.SelectPath("/Trash")
      dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    end

    a2d.CopyPath("/A2.DESKTOP/EXTRAS", "/RAM1")
    a2d.CloseAllWindows()

    if what == "copy" or what == "move" then
      a2d.CreateFolder("/RAM1/FOLDER")
      a2d.OpenPath("/RAM1/FOLDER")
      a2d.MoveWindowBy(300, 60)
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()
      dst_x, dst_y = x + w / 2, y + h / 2
    end

    a2d.OpenPath("/RAM1/EXTRAS", {keep_windows=true})
    emu.wait(5)
    a2d.GrowWindowBy(-200, -200)
    a2d.MoveWindowBy(0, 60)
    emu.wait(5)
    a2d.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)

        a2dtest.DHRDarkness()

        if what == "copy" then
          apple2.PressSA() -- copy
          m.ButtonUp()
          apple2.ReleaseSA()
        else
          m.ButtonUp() -- move or delete
        end

        -- Bypass normal exiting delays
        -- TODO: Figure out why this is necessary
        a2d.ExitMouseKeysMode()
        return false
    end)

    if what == "delete" and when == "after" then
      a2dtest.WaitForAlert()
      a2d.DialogOK({no_wait=true})
    end

    if when == "during" then
      -- abort during enumeration
      emu.wait(0.25)
      test.Snap("verify enumerating")
      apple2.EscapeKey()
    else
      -- abort after enumeration
      if what == "delete" then
        emu.wait(0.5) -- already enumerated, so shorter wait
      else
        emu.wait(2)
      end
      test.Snap("verify performing action")
      apple2.EscapeKey()
    end

    emu.wait(10)
    if when == "during" then
      if what == "copy" or what == "move" then
        test.Snap("verify EXTRAS and FOLDER windows did not repaint")
      elseif what == "delete" then
        test.Snap("verify EXTRAS windows did not repaint")
      end
    else
      if what == "copy" then
        test.Snap("verify EXTRAS folder did not repaint but FOLDER window did repaint")
      elseif what == "move" then
        test.Snap("verify EXTRAS and FOLDER windows did repaint")
      elseif what == "delete" then
        test.Snap("verify EXTRAS folder did repaint")
      end
    end

    -- cleanup (and repaint screen)
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Open `/TESTS/HUNDRED.FILES`, without resizing the window. Scroll up
  and down by one tick, by one page, and to the top/bottom. Verify
  that such operations scroll by an integral number of icons, i.e. the
  last row of labels are always the same distance from the bottom of
  the window.
]]
test.Step(
  "Default scrolling is by integral number of icons",
  function()
    a2d.OpenPath("/TESTS/HUNDRED.FILES")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    emu.wait(5)
    a2d.InMouseKeysMode(function(m)
        test.Snap("note icon positions")
        for i = 1, 2 do
          -- Down by one tick
          m.MoveToApproximately(x + w + 10, y + h - 5)
          m.Click()
          emu.wait(2)
          test.Snap("icons should still be aligned")
        end
        for i = 1, 2 do
          -- Up by one tick
          m.MoveToApproximately(x + w + 10, y + 5)
          m.Click()
          emu.wait(2)
          test.Snap("icons should still be aligned")
        end
        for i = 1, 2 do
          -- Down by one page
          m.MoveToApproximately(x + w + 10, y + h - 20)
          m.Click()
          emu.wait(2)
          test.Snap("icons should still be aligned")
        end
        for i = 1, 2 do
          -- Up by one page
          m.MoveToApproximately(x + w + 10, y + 20)
          m.Click()
          emu.wait(2)
          test.Snap("icons should still be aligned")
        end
        m.Home()
        -- to bottom
        m.MoveToApproximately(x + w + 10, y + h - 5)
        for i = 1, 20 do
          m.Click()
          emu.wait(2)
        end
        test.Snap("icons should still be aligned")
        -- to top
        m.MoveToApproximately(x + w + 10, y + 5)
        for i = 1, 20 do
          m.Click()
          emu.wait(2)
        end
        test.Snap("icons should still be aligned")
    end)
end)

--[[
  Launch DeskTop. Open a volume window with enough icons that a
  scrollbar appears. Click on an active part of the scrollbar. Verify
  that the scrollbar responds immediately, not after the double-click
  detection delay expires.
]]
test.Step(
  "Active scrollbars respond immediately",
  function()
    a2d.OpenPath("/TESTS")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w + 5, y + h / 2)
        m.Click()
        a2dtest.MultiSnap(60, "should repaint quickly")
    end)
end)

--[[
  Launch DeskTop. Open a volume window where the vertical and
  horizontal scrollbars are inactive. Click on each inactive
  scrollbar. Verify nothing happens.
]]
test.Step(
  "Inactive scrollbar are inactive",
  function()
    a2d.OpenPath("/RAM1")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m) m.Home() end)
    a2dtest.ExpectNothingChanged(function()
        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(x + w + 5, y + h / 2)
            m.Click()
            m.MoveToApproximately(x + w / 2, y + h + 5)
            m.Click()
            m.Home()
        end)
    end)
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
