--[[ BEGINCONFIG ========================================

MODEL="apple2ep"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl5 ramfactor -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv -flop1 floppy_with_files.dsk"

======================================== ENDCONFIG ]]

--[[
  The tests in this file require precise alignment of windows and icons;
  this may not be possible with MouseKeys based movement.
]]

a2d.ConfigureRepaintTime(0.25)

function GetWinFrameRect(window_id)
  local x, y, w, h = a2dtest.GetFrontWindowContentRect()
  return { x - 1, y - 13, x + w + 21, y + h + 11 }
end

--[[
  Position two windows so that the right edges are exactly aligned,
  and the windows vertically overlap by several pixels. Activate the
  upper window. Drag a floppy disk volume icon so that it is partially
  occluded by the bottom-right of the upper window. Verify that the
  visible parts of the icon repaint correctly and that DeskTop does
  not hang.
]]
test.Step(
  "windows with aligned right edges",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(-apple2.SCREEN_WIDTH, 0)
    a2d.MoveWindowBy(300, 0)
    emu.wait(5)
    local rect1 = GetWinFrameRect(mgtk.FrontWindow())

    a2d.OpenPath("/RAM5", {keep_windows=true})
    a2d.MoveWindowBy(-apple2.SCREEN_WIDTH, 0)
    a2d.MoveWindowBy(300, 55)
    emu.wait(5)
    local rect2 = GetWinFrameRect(mgtk.FrontWindow())

    test.ExpectEquals(rect1[3], rect2[3], "right edges should align")
    test.ExpectGreaterThan(rect1[4], rect2[2], "windows should overlap vertically")
    a2d.CycleWindows()

    a2d.SelectPath("/WITH.FILES", {keep_windows=true})
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, rect1[3]+5, rect1[4]-5)
    a2d.InMouseKeysMode(function(m) m.Home() end)
    test.Snap("verify icon painted correctly")
    a2dtest.ExpectNotHanging()

    -- cleanup
    a2d.CheckAllDrives()
end)

--[[
  Position two windows so that the left edges are exactly aligned, and
  the windows vertically overlap by several pixels. Activate the upper
  window. Drag a floppy disk volume icon so that it is partially
  occluded by the bottom-left corner of the upper window. Verify that
  the visible parts of the icon repaint correctly and that DeskTop
  does not hang.
]]
test.Step(
  "windows with aligned left edges",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(-apple2.SCREEN_WIDTH, 0)
    a2d.MoveWindowBy(300, 0)
    emu.wait(5)
    local rect1 = GetWinFrameRect(mgtk.FrontWindow())

    a2d.OpenPath("/RAM5", {keep_windows=true})
    a2d.MoveWindowBy(-apple2.SCREEN_WIDTH, 0)
    a2d.MoveWindowBy(300, 55)
    emu.wait(5)
    local rect2 = GetWinFrameRect(mgtk.FrontWindow())

    test.ExpectEquals(rect1[1], rect2[1], "left edges should align")
    test.ExpectGreaterThan(rect1[4], rect2[2], "windows should overlap vertically")
    a2d.CycleWindows()

    a2d.SelectPath("/WITH.FILES", {keep_windows=true})
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, rect1[1]-5, rect1[4]-5)
    a2d.InMouseKeysMode(function(m) m.Home() end)
    test.Snap("verify icon painted correctly")
    a2dtest.ExpectNotHanging()

    -- cleanup
    a2d.CheckAllDrives()
end)

--[[
  Position two windows so that the bottom-right corner of one overlaps
  the top-left corner of the other by several pixels. Drag a
  floppy disk volume icon so that it should show on both sides of
  overlap. Verify that the visible parts of the icon repaint
  correctly.
]]
test.Step(
  "icon clipped into two parts",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(-apple2.SCREEN_WIDTH, 0)
    a2d.MoveWindowBy(200, 0)
    emu.wait(5)
    local rect1 = GetWinFrameRect(mgtk.FrontWindow())

    a2d.OpenPath("/RAM5", {keep_windows=true})
    a2d.MoveWindowBy(-apple2.SCREEN_WIDTH, 0)
    a2d.MoveWindowBy(380, 60)
    emu.wait(5)
    local rect2 = GetWinFrameRect(mgtk.FrontWindow())

    a2d.CycleWindows()

    test.ExpectGreaterThan(rect1[3] - rect2[1], 0, "windows should just overlap")
    test.ExpectLessThan(rect1[3] - rect2[1], 10, "windows should just overlap")
    test.ExpectGreaterThan(rect1[4] - rect2[2], 0, "windows should just overlap")
    test.ExpectLessThan(rect1[4] - rect2[2], 10, "windows should just overlap")

    a2d.SelectPath("/WITH.FILES", {keep_windows=true})
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x-10, y+10, rect2[1]-5, rect1[4]+5)
    a2d.InMouseKeysMode(function(m) m.Home() end)
    test.Snap("verify both parts of icon painted correctly")
    a2dtest.ExpectNotHanging()

    -- cleanup
    a2d.CheckAllDrives()
end)

--[[
  Open five volume windows containing many files so that the windows
  have large initial sizes. Drag the top-most so that the right edge
  aligns with another window's right edge and overlaps a volume icon.
  Drag another window that was previously overlapping the same icon so
  that the right edge aligns with the other windows. Verify that the
  volume icons repaint correctly and that the system does not hang.
]]
test.Step(
  "window right edges vs. volume icons",
  function()
    a2d.OpenPath("/RAM1")
    a2d.OpenPath("/RAM5", {keep_windows=true})

    a2d.OpenPath("/A2.DESKTOP", {keep_windows=true})
    a2d.MoveWindowBy(-apple2.SCREEN_WIDTH, 0)
    a2d.MoveWindowBy(510, 0)
    emu.wait(5)
    local rect1 = GetWinFrameRect(mgtk.FrontWindow())

    a2d.OpenPath("/TESTS", {keep_windows=true})
    a2d.MoveWindowBy(-apple2.SCREEN_WIDTH, 0)
    a2d.MoveWindowBy(500, 00)
    emu.wait(5)
    local rect2 = GetWinFrameRect(mgtk.FrontWindow())

    a2d.OpenPath("/WITH.FILES", {keep_windows=true})
    a2d.MoveWindowBy(-apple2.SCREEN_WIDTH, 0)
    a2d.GrowWindowBy(0, 60)
    a2d.MoveWindowBy(500, 0)
    emu.wait(5)
    local rect3 = GetWinFrameRect(mgtk.FrontWindow())

    while a2dtest.GetFrontWindowTitle():upper() ~= "A2.DESKTOP" do
      a2d.CycleWindows()
      emu.wait(1)
    end

    a2d.MoveWindowBy(-10, 0)
    emu.wait(5)
    test.Snap("verify volume icons repainted correctly")
    a2dtest.ExpectNotHanging()

    -- cleanup
    a2d.CheckAllDrives()
end)

--[[
  Launch DeskTop. Open a window. Create a folder with a short name
  (e.g. "A"). Open the folder. Drag the folder's window so it covers
  just the left edge of the icon. Drag it away. Verify that the folder
  repaints. Repeat for the right edge.

  Launch DeskTop. Open a volume. Open a folder. Drag the folder window
  so that it obscures the top-most edge of an icon in the volume
  window. Drag the folder away. Verify that the icon in the volume
  window repaints.
]]
test.Step(
  "reveal left/right/top edges of dimmed icon",
  function()
    a2d.CreateFolder("/RAM1/A")
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(100, 80)
    a2d.Select("A")
    a2d.OpenSelection()
    a2d.ClearSelection()

    a2d.MoveWindowBy(-95, 70)
    test.Snap("verify top window covers just left edge of folder")
    a2d.MoveWindowBy(210, 0)
    test.Snap("verify top window covers just right edge of folder")

    a2d.MoveWindowBy(-100, -35)
    test.Snap("verify top window covers just top edge of folder")
    a2d.MoveWindowBy(200, 0)
    test.Snap("verify folder repaints correctly")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)
