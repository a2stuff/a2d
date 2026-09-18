--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS=""
DISKARGS="-flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]

--[[
  Configure a IIc or IIc+ in MAME. Launch DeskTop. Apple > About This
  Apple II. Verify that the system doesn't hang probing Slot 2.
]]
test.Step(
  "Does not hang probing slot 2",
  function()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    desktop.CloseWindow()
    a2dtest.ExpectNotHanging()
end)
