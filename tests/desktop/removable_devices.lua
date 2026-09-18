--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 '' -sl2 mouse -sl6 '' -sl7 superdrive"
DISKARGS="-flop1 $HARDIMG -flop2 disk_a.2mg"

======================================== ENDCONFIG ]]

local s7d2 = manager.machine.images[":sl7:superdrive:fdc:1:35hd"]

--[[
  After Check All Drives, removable devices shouldn't momentarily
  disappear due to obsolete state.
]]
test.Step(
  "Drive polling after Check All Drives",
  function()
    local image = s7d2.filename

    desktop.SelectPath("/A")
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_EJECT_DISK)
    emu.wait(10) -- async drive validation

    test.Expect(not s7d2.image, "image should be unloaded")
    desktop.CloseAllWindows()
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 2, "should be A2.DESKTOP and Trash")

    s7d2:load(image)
    desktop.CheckAllDrives({no_wait=true})
    a2dtest.MultiSnap(360, "verify A doesn't flicker on/off/on")
end)
