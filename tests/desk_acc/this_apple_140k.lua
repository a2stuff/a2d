--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS=""
DISKARGS="-flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]

--[[
  Boot a system with only the 140k_disk1 image. Verify that About This
  Apple II is present in the Apple Menu.
]]
test.Step(
  "About This Apple II is present on floppy",
  function()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "About This Apple II",
                      "accessory should be present in image")
end)
