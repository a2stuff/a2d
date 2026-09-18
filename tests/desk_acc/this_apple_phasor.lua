--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl4 phasor -sl7 cffa202"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Configure a system with a Phasor. Launch DeskTop. Apple Menu >
  About This Apple II. Verify that the Phasor is detected.
]]
test.Step(
  "Phasor detection",
  function()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRFrontWindowContent()
    test.ExpectMatch(ocr, "Phasor", "a Phasor should be detected")
end)
