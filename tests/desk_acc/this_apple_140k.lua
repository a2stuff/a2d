--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS=""
DISKARGS="-flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(5)

--[[
  Boot a system with only the 140k_disk1 image. Verify that About This
  Apple II is present in the Apple Menu.
]]
test.Step(
  "About This Apple II is present on floppy",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    test.Snap("accessory should be present in image")
end)
