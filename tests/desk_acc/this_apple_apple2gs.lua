--[[ BEGINCONFIG ========================================

MODEL="apple2gsr1"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 $HARDIMG"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  On a IIgs, go to Apple Menu > About This Apple II. Verify the memory
  count is not "000,000".
]]
test.Step(
  "Memory measurement",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    test.ExpectNotIMatch(a2dtest.OCRFrontWindowContent(), "000,000",
                "memory count should not be '000,000'")
end)
