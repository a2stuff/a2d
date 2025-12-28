--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 superdrive -aux ext80"
DISKARGS="-flop1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)
local s6d1 = manager.machine.images[":sl6:superdrive:fdc:0:35hd"]

--[[
  Launch DeskTop. Close all windows. Eject all disks, and verify that
  only the Trash icon remains. Clear selection by clicking on the
  desktop. Press an arrow key. Verify that the Trash icon is selected.
]]
test.Step(
  "Arrows with no volumes",
  function()
    s6d1:unload()
    a2d.CheckAllDrives()

    a2d.ClearSelection()
    apple2.RightArrowKey()
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "Trash", "trash should be selected")

    a2d.ClearSelection()
    apple2.LeftArrowKey()
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "Trash", "trash should be selected")

    a2d.ClearSelection()
    apple2.UpArrowKey()
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "Trash", "trash should be selected")

    a2d.ClearSelection()
    apple2.DownArrowKey()
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "Trash", "trash should be selected")
end)


