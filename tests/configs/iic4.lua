--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS="-ramsize 1152K -gameio joy"
DISKARGS="-flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]--

emu.wait(50) -- IIc emulation is very slow

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5) -- IIc emulation is very slow
    test.Snap()
    a2d.CloseWindow()
    test.ExpectEquals(apple2.ReadRAMDevice(0x2000+40), 0x55, "DHR access")
    test.ExpectEquals(apple2.ReadRAMDevice(0x12000+40), 0x2A, "DHR access")
    return test.PASS
end)
