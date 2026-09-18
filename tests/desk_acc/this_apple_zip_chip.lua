
--[[
  Run DeskTop on a IIe with a ZIP CHIP installed.. Apple Menu > About
  This Apple II. Verify that a ZIP CHIP is reported.
]]
test.Step(
  "ZIP Chip",
  function()
    apple2.SetSystemConfig(":a2_config", "CPU type", 1 << 4, 1 << 4)
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    test.ExpectIMatch(a2dtest.OCRFrontWindowContent(), "ZIP CHIP",
                "a ZIP CHIP should be detected")
end)
