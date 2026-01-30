--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse  -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv -flop1 floppy_with_files.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.5)

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]

--[[
  Move files with failure during enumeration. Verify window does not
  repaint.
]]
test.Step(
  "move - failure during enumeration does not repaint window",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(280, 80)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.OpenPath("/WITH.FILES", {keep_windows=true})
    a2d.MoveWindowBy(0, 80)
    a2d.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2dtest.DHRDarkness()

    local current = s6d1.filename
    s6d1:unload()
    a2d.Drag(src_x, src_y, dst_x, dst_y, {oa_drop=true})
    a2dtest.WaitForAlert()
    s6d1:load(current)
    a2d.DialogCancel()

    emu.wait(5)
    test.Snap("verify WITH.FILES window did not repaint")

    -- cleanup
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Delete files with failure during enumeration. Verify window does not
  repaint.
]]
test.Step(
  "delete - failure during enumeration does not repaint window",
  function()
    a2d.OpenPath("/WITH.FILES")
    a2d.MoveWindowBy(0, 80)
    a2d.SelectAll()

    a2dtest.DHRDarkness()

    local current = s6d1.filename
    s6d1:unload()
    a2d.OADelete()
    a2dtest.WaitForAlert()
    s6d1:load(current)
    a2d.DialogCancel()

    emu.wait(5)
    test.Snap("verify WITH.FILES window did not repaint")

    -- cleanup
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
