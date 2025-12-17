--[[ BEGINCONFIG ==================================================

MODEL="apple2ee"
MODELARGS="-sl1 cffa2 -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 res/disk_b.2mg -hard3 $HARDIMG -hard4 res/disk_a.2mg"

================================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Configure multiple drives connected to a SmartPort controller on a
  higher numbered slot, a single drive connected to a SmartPort
  controller in a lower numbered slot. Launch DeskTop. Apple Menu >
  About This Apple II. Verify that the name on the lower numbered slot
  doesn't have an extra character at the end.
]]
test.Step(
  "SmartPort labeling",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    test.Snap("verify slot 1 reports cleanly")
end)
