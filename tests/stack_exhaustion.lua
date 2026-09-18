--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl6 '' -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

-- A CFFA2 is specified the repro tickles a firmware issue where low
-- stack causes improper address calculation and we crash to the
-- monitor. Low stack being a problem is not specific to the CFFA,
-- however.

test.Step(
  "Restarting launcher (about 36s)",
  function()
    desktop.OpenWindow("/A2.DESKTOP")

    -- Prior to fix, crashes around iteration 40
    local cpu = manager.machine.devices[":maincpu"]
    for i = 1, 50 do
      desktop.SelectAndOpen("DESKTOP.SYSTEM")
      a2d.WaitForDesktopReady()
      --print(string.format("i=%d SP=%02X", i, cpu.state.SP.value))
      test.Expect(not apple2.IsCrashedToMonitor(), "should not have crashed to monitor")
      test.ExpectGreaterThan(cpu.state.SP.value, 0x120, "stack should not be exausted")
    end

    desktop.CloseAllWindows()
end)

test.Step(
  "Running external programs - DeskTop (about 50s)",
  function()
    desktop.OpenWindow("/A2.DESKTOP/SAMPLE.MEDIA")

    -- Prior to fix, hangs around iteration 60 (but doesn't crash to monitor)
    local cpu = manager.machine.devices[":maincpu"]
    for i = 1, 70 do
      desktop.SelectAndOpen("KARATEKA.YELL", {no_wait=true})
      a2d.WaitForDesktopReady()
      --print(string.format("i=%d SP=%02X", i, cpu.state.SP.value))
      test.Expect(not apple2.IsCrashedToMonitor(), "should not have crashed to monitor")
      test.ExpectGreaterThan(cpu.state.SP.value, 0x120, "stack should not be exausted")
    end

    desktop.CloseAllWindows()
end)

test.Step(
  "Running external programs - Selector (about 25s)",
  function()
    desktop.AddShortcut("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    desktop.ToggleOptionShowShortcutsOnStartup()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    -- Prior to fix, runs out of stack around iteration 30 (but doesn't crash!)
    local cpu = manager.machine.devices[":maincpu"]
    for i = 1, 40 do
      apple2.Type("1")
      a2d.DialogOK()
      a2d.WaitForDesktopReady()
      --print(string.format("i=%d SP=%02X", i, cpu.state.SP.value))
      test.Expect(not apple2.IsCrashedToMonitor(), "should not have crashed to monitor")
      test.ExpectGreaterThan(cpu.state.SP.value, 0x120, "stack should not be exausted")
    end

    apple2.Type("D") -- Desktop
    a2d.WaitForDesktopReady()
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)
