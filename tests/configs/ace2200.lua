--[[ BEGINCONFIG ========================================

MODEL="ace2200"
MODELARGS="-sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5) -- slow floppy drives
    test.Snap()
    return test.PASS
end)
