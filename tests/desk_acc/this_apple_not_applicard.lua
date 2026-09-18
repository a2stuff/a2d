--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl4 wicotrackball -sl7 cffa202"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Configure a system with a Wico Trackball card. Launch DeskTop. Apple Menu >
  About This Apple II. Verify that the Appli-Card is not mis-detected.
]]
test.Step(
  "No false-positive Appli-Card detection",
  function()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRFrontWindowContent()
    test.ExpectNotMatch(ocr, "Appli%-Card", "an Appli-Card should not be detected")
end)
