--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -flop1 directory_eof.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Copy a disk where the volume directory has EOF at a block boundary.
  Unexpected but valid.
]]
test.Step(
  "Copy a disk with a volume dir EOF",
  function()
    a2d.CopyPath("/FROGGO", "/RAM1")
    emu.wait(60) -- slow copy from floppy
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "copy should be complete")
    a2dtest.ExpectAlertNotShowing()
end)
