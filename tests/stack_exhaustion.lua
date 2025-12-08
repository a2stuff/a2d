--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl6 '' -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

-- A CFFA2 is specified the repro tickles a firmware issue where low
-- stack causes improper address calculation and we crash to the
-- monitor. Low stack being a problem is not specific to the CFFA,
-- however.

test.Step(
  "Stack exhaustion (takes about 122 seconds to run)",
  function()
    local cpu = manager.machine.devices[":maincpu"]

    -- Prior to fix, crashes around iteration 40
    for i = 1,50 do
      --print(string.format("i=%d SP=%04X", i, cpu.state.SP.value))
      a2d.CloseAllWindows()
      a2d.OpenPath("/A2.DESKTOP/DESKTOP.SYSTEM")
      a2d.WaitForRestart()
      test.Expect(not apple2.IsCrashedToMonitor(), "should not have crashed to monitor")
    end
end)
