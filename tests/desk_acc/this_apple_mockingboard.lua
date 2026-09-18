
--[[
  Configure a system with a Mockingboard and a Zip Chip, with
  acceleration enabled (MAME works). Launch DeskTop. Apple Menu >
  About This Apple II. Verify that the Mockingboard is detected.
]]
test.Step(
  "Mockingboard and ZIP",
  function()
    apple2.SetSystemConfig(":a2_config", "CPU type", 1 << 4, 1 << 4)
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRFrontWindowContent()
    test.ExpectMatch(ocr, "Mockingboard", "a Mockingboard should be detected")
    test.ExpectIMatch(ocr, "ZIP CHIP", "a ZIP CHIP should be detected")
end)
