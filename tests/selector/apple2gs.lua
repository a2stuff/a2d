--[[ BEGINCONFIG ========================================

MODEL="apple2gsr1"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 $HARDIMG"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]

--[[
  Use the Options control panel (in DeskTop) to show Shortcuts on
  startup. Launch Shortcuts. File > Run a Program.... Select
  `BASIC.SYSTEM` and click OK. Verify that super-hires mode is not
  erroneously activated.
]]
test.Step(
  "Selector and IIgs",
  function()
    desktop.AddShortcut("/A2.DESKTOP/READ.ME")
    desktop.ToggleOptionShowShortcutsOnStartup()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    a2d.OAShortcut("R") -- Run a Program...
    a2d.NavigateFilePickerTo("/A2.DESKTOP/EXTRAS", "BASIC.SYSTEM")
    a2d.DialogOK()

    apple2.WaitForBasicSystem()

    local newvideo = apple2.ReadSSW("NEWVIDEO")
    test.ExpectEquals(newvideo & 0x80, 0, "SHR should be off")

    --[[
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
    ]]
end)
