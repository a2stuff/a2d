--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 prodos_floppy1.dsk -flop2 prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

--[[
  Configure a system with two volumes of the same name. Launch
  DeskTop. Verify that an error is shown, and only one volume appears.
]]
test.Step(
  "Duplicate volume names",
  function()
    a2dtest.WaitForAlert({match="2 volumes with the same name"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 3, "Expect 2 volumes plus trash")
end)
