--[[ BEGINCONFIG ========================================

MODEL="apple2gsr1"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 $HARDIMG"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]

--[[
  On a IIgs, go to Apple Menu > About This Apple II. Verify the memory
  count is not "000,000".
]]
test.Step(
  "Memory measurement",
  function()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    test.ExpectNotIMatch(a2dtest.OCRFrontWindowContent(), "000,000",
                "memory count should not be '000,000'")
end)
