--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

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
        test.Snap("verify volume highlighted")
        m.MoveByApproximately(-10, -10)
        test.Snap("verify volume not highlighted")

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

