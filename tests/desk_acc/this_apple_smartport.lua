--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 cffa2 -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 disk_b.2mg -hard3 $HARDIMG -hard4 disk_a.2mg"

======================================== ENDCONFIG ]]

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
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    test.Snap("verify slot 1 reports cleanly")
end)
