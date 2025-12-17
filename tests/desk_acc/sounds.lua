a2d.ConfigureRepaintTime(0.25)

--[[
  Open the Sounds DA. Select one of the "Obnoxious" sounds. Exit the
  DA. Run `BASIC.SYSTEM` from the EXTRAS/ folder. Verify that the
  system does not crash to the monitor.
]]
test.Step(
  "Sounds do not crash",
  function()
    local NUM_SOUNDS = 21
    a2d.AddShortcut("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SOUNDS")
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.CloseAllWindows()

    for i = 1, NUM_SOUNDS do
      a2d.OAShortcut("1")
      apple2.DownArrowKey()
      emu.wait(1)
      a2d.DialogOK()

      a2d.OAShortcut("2")
      apple2.WaitForBasicSystem()
      apple2.TypeLine("BYE")
      a2d.WaitForDesktopReady()
    end
end)

