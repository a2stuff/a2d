--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(5)

--[[
  Launch DeskTop. Close all windows. Eject all disks, and verify that
  only the Trash icon remains. Clear selection by clicking on the
  desktop. Press an arrow key. Verify that the Trash icon is selected.
]]
test.Step(
  "Arrows with no volumes",
  function()
    apple2.Get35Drive1():unload()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)


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


