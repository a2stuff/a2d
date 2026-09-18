--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl4 diskiing13 -sl7 cffa202"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Configure a system with a 13-Sector Disk II card. Launch DeskTop. Apple Menu >
  About This Apple II. Verify that the card is detected.
q]]
test.Step(
  "Disk II 13-sector detection",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRFrontWindowContent()
    test.ExpectMatch(ocr, "Disk II.*13%-sector", "a 13-sector Disk II should be detected")
end)
