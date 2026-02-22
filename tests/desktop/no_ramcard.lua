--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv -flop1 $FLOP1IMG -flop2 $FLOP2IMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[
  Configure a system without a RAMCard. Launch DeskTop. Verify that
  the volume containing DeskTop appears in the top right corner of the
  desktop. File > Copy To.... Verify that the volume containing
  DeskTop is the first disk shown.
]]
test.Step(
  "no ramcard, boot volume appears first",
  function()
    test.Snap("verify boot volume is in top right")
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
    emu.wait(5)
    apple2.ControlKey("D") -- Drives
    emu.wait(5)
    test.Snap("verify boot volume is first disk")
end)
