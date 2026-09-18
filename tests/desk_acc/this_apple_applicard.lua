--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl4 applicard -sl7 cffa202"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Configure a system with an Appli-Card. Launch DeskTop. Apple Menu >
  About This Apple II. Verify that the Appli-Card is detected.
]]
test.Step(
  "Appli-Card detection",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRFrontWindowContent()
    test.ExpectMatch(ocr, "Appli%-Card", "an Appli-Card should be detected")
end)
