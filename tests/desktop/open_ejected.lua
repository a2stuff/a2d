--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":fdc:2:35dd"]

--[[
  Launch DeskTop. Manually (not via DeskTop) eject the startup disk.
  Select the startup disk icon. File > Open. Verify that the alert
  displays correctly.
]]
test.Step(
  "Alert shown on File > Open if disk ejected",
  function()
    local drive = s5d1
    drive:unload()

    desktop.SelectPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_OPEN-1)
    a2dtest.WaitForAlert({match="volume cannot be found"})
end)

