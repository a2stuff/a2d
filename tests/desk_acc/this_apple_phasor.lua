--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl4 phasor -sl7 cffa202"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Configure a system with a Phasor. Launch DeskTop. Apple Menu >
  About This Apple II. Verify that the Phasor is detected.
]]
test.Step(
  "Phasor detection",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    local ocr = a2dtest.OCRFrontWindowContent()
    test.ExpectMatch(ocr, "Phasor", "a Phasor should be detected")
end)
