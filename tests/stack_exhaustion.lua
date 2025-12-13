--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl6 '' -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

-- A CFFA2 is specified the repro tickles a firmware issue where low
-- stack causes improper address calculation and we crash to the
-- monitor. Low stack being a problem is not specific to the CFFA,
-- however.

test.Step(
  "Restarting launcher (takes about 122 seconds to run)",
  function()
    a2d.OpenPath("/A2.DESKTOP")

    -- Prior to fix, crashes around iteration 40
    local cpu = manager.machine.devices[":maincpu"]
    for i = 1, 50 do
      a2d.SelectAndOpen("DESKTOP.SYSTEM")
      a2d.WaitForRestart()
      --print(string.format("i=%d SP=%02X", i, cpu.state.SP.value))
      test.Expect(not apple2.IsCrashedToMonitor(), "should not have crashed to monitor")
      test.ExpectGreaterThan(cpu.state.SP.value, 0x120, "stack should not be exausted")
    end

    a2d.CloseAllWindows()
end)

test.Step(
  "Running external programs - DeskTop",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA")

    -- Prior to fix, hangs around iteration 60 (but doesn't crash to monitor)
    local cpu = manager.machine.devices[":maincpu"]
    for i = 1, 70 do
      a2d.SelectAndOpen("KARATEKA.YELL")
      a2d.WaitForRestart()
      --print(string.format("i=%d SP=%02X", i, cpu.state.SP.value))
      test.Expect(not apple2.IsCrashedToMonitor(), "should not have crashed to monitor")
      test.ExpectGreaterThan(cpu.state.SP.value, 0x120, "stack should not be exausted")
    end

    a2d.CloseAllWindows()
end)

test.Step(
  "Running external programs - Selector",
  function()
    a2d.AddShortcut("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()

    -- Prior to fix, runs out of stack around iteration 30 (but doesn't crash!)
    local cpu = manager.machine.devices[":maincpu"]
    for i = 1, 40 do
      apple2.Type("1")
      a2d.DialogOK()
      a2d.WaitForRestart()
      --print(string.format("i=%d SP=%02X", i, cpu.state.SP.value))
      test.Expect(not apple2.IsCrashedToMonitor(), "should not have crashed to monitor")
      test.ExpectGreaterThan(cpu.state.SP.value, 0x120, "stack should not be exausted")
    end

    apple2.Type("D") -- Desktop
    a2d.WaitForRestart()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
end)
