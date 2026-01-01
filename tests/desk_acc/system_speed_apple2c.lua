--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS=""
DISKARGS="-flop1 $FLOP1IMG -flop2 $FLOP2IMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(2)

--[[
  Run DeskTop on a IIc. Launch Control Panel > System Speed. Click
  Normal and Fast. Verify that the display does not switch from DHR to
  HR.
]]
test.Step(
  "IIc - speed doesn't affect DHR display",
  function()
    a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    emu.wait(5) -- floppy drives are slow
    apple2.Type("N") -- Normal Speed
    apple2.Type("F") -- Fast Speed
    test.Expect(apple2.ReadSSW("RDDHIRES") < 128, "Should still be in DHR mode")
    a2d.DialogOK()
    a2d.CloseAllWindows()
end)

