--[[ BEGINCONFIG ========================================

MODEL="apple2gsr0"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 $HARDIMG"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]--

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    test.Snap()
    a2d.CloseWindow()
    test.ExpectEquals(apple2.ReadRAMDevice(0x2000+40), 0x55, "DHR access")
    test.ExpectEquals(apple2.ReadRAMDevice(0x12000+40), 0x2A, "DHR access")
    return test.PASS
end)

