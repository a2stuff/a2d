--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 prodos_floppy1.dsk -flop2 prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Configure a system with two volumes of the same name. Launch
  DeskTop. Verify that an error is shown, and only one volume appears.
]]
test.Step(
  "Duplicate volume names",
  function()
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    emu.wait(5)
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 3, "Expect 2 volumes plus trash")
end)
