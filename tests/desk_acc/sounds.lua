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

--[[
  Click on an item. Verify it is selected, and plays the sound. Click
  on the same selected item. Verify it plays the sound again.
]]
test.Step(
  "Clicking on an item again plays the sound again",
  function()
    io.stderr:write(
      "NOTE: Run this test with --slow --audible\n" ..
      " * MouseKeys entry sound (lo-hi)\n" ..
      " * IIgs Bonk\n" ..
      " * IIgs Bonk\n" ..
      " * IIgs Bonk\n" ..
      " * MouseKeys exit sound (hi-lo)\n")

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SOUNDS")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + 15)
        m.Click()
        emu.wait(1)
        m.Click()
        emu.wait(1)
        m.Click()
        emu.wait(1)
    end)

    a2d.DialogCancel()
end)
