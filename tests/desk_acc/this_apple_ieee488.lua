--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl4 ieee488 -sl7 cffa202"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Configure a system with an IEEE-488 card. Launch DeskTop. Apple Menu >
  About This Apple II. Verify that the card is detected.
]]
test.Step(
  "IEEE-488 detection",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRFrontWindowContent()
    test.ExpectMatch(ocr, "IEEE%-488", "IEEE-488 card should be detected")
end)
