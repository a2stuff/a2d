--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 mouse -sl2 diskiing -sl7 cffa2"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Configure a system with a drive controller (Disk II or SmartPort) in
  slot 2. Launch DeskTop. Verify that Slot 2 appears in the Startup
  menu.
]]
test.Step(
  "Slot 2 can have drive controller",
  function()
    a2d.OpenMenu(a2d.STARTUP_MENU)
    test.Snap("verify Slot 2 is listed")
end)
