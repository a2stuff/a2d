--[[ BEGINCONFIG ========================================

MODEL="apple2gsr1"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 $HARDIMG"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Use the Options control panel (in DeskTop) to show Shortcuts on
  startup. Launch Shortcuts. File > Run a Program.... Select
  `BASIC.SYSTEM` and click OK. Verify that super-hires mode is not
  erroneously activated.
]]
test.Step(
  "Selector and IIgs",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.OAShortcut("R") -- Run a Program...
    apple2.ControlKey("D") -- Drives
    apple2.Type("A2.DESKTOP")
    apple2.ControlKey("O") -- Open
    apple2.Type("EXTRAS")
    apple2.ControlKey("O") -- Open
    apple2.Type("BASIC.SYSTEM")
    a2d.DialogOK()

    apple2.WaitForBasicSystem()

    local newvideo = apple2.ReadSSW("NEWVIDEO")
    test.ExpectEquals(newvideo & 0x80, 0, "SHR should be off")

    --[[
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    ]]
end)
