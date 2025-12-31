--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 '' -sl2 mouse -sl6 '' -sl7 superdrive -aux ext80"
DISKARGS="-flop1 $HARDIMG -flop2 res/disk_a.2mg"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)
local s7d2 = manager.machine.images[":sl7:superdrive:fdc:1:35hd"]

--[[
  After Check All Drives, removable devices shouldn't momentarily
  disappear due to obsolete state.
]]
test.Step(
  "Drive polling after Check All Drives",
  function()
    local image = s7d2.filename

    a2d.SelectPath("/A")
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_EJECT_DISK)
    emu.wait(10)

    test.Expect(not s7d2.image, "image should be unloaded")
    a2d.CloseAllWindows()
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "should be A2.DESKTOP and Trash")

    s7d2:load(image)
    a2d.CheckAllDrives({no_wait=true})
    a2dtest.MultiSnap(360, "verify A doesn't flicker on/off/on")
end)
