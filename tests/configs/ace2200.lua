--[[ BEGINCONFIG ========================================

MODEL="ace2200"
MODELARGS="-sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

-- ACE 2200 does not auto-start with anythng but floppies
apple2.ControlReset()
apple2.TypeLine("PR#7")

-- Wait for DeskTop to start
a2d.WaitForRestart()
emu.wait(5) -- slow floppy drives

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5) -- slow floppy drives
    test.Snap()
    a2d.CloseWindow()
    test.ExpectEquals(apple2.ReadRAMDevice(0x2000+40), 0x55, "DHR access")
    test.ExpectEquals(apple2.ReadRAMDevice(0x12000+40), 0x2A, "DHR access")
    return test.PASS
end)
