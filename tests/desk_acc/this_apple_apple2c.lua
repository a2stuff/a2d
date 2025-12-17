--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS=""
DISKARGS="-flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(5)

--[[
  Configure a IIc or IIc+ in MAME. Launch DeskTop. Apple > About This
  Apple II. Verify that the system doesn't hang probing Slot 2.
]]
test.Step(
  "Does not hang probing slot 2",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    a2d.CloseWindow()
    a2dtest.ExpectNotHanging()
end)
