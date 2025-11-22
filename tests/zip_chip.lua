--[[============================================================

  ZIP Chip

  ============================================================]]--

test.Step(
  "ZIP Chip",
  function()
    apple2.SetSystemConfig(":a2_config", "CPU type", 1 << 4, 1 << 4)
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    test.Snap("verify that ZIP CHIP is detected")
end)
