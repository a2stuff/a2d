a2d.ConfigureRepaintTime(0.25)

--[[
  Configure a system with a Mockingboard and a Zip Chip, with
  acceleration enabled (MAME works). Launch DeskTop. Apple Menu >
  About This Apple II. Verify that the Mockingboard is detected.
]]
test.Step(
  "Mockingboard and ZIP",
  function()
    apple2.SetSystemConfig(":a2_config", "CPU type", 1 << 4, 1 << 4)
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    test.Snap("verify that Mockingboard (and ZIP CHIP) is detected")
end)
