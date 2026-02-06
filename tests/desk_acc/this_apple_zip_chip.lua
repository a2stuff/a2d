a2d.ConfigureRepaintTime(0.25)

--[[
  Run DeskTop on a IIe with a ZIP CHIP installed.. Apple Menu > About
  This Apple II. Verify that a ZIP CHIP is reported.
]]
test.Step(
  "ZIP Chip",
  function()
    apple2.SetSystemConfig(":a2_config", "CPU type", 1 << 4, 1 << 4)
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    test.Expect(a2dtest.OCRScreen():upper():find("ZIP CHIP"),
                "a ZIP CHIP should be detected")
end)
