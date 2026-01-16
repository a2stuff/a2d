--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 superdrive"
DISKARGS="-flop1 $HARDIMG"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:superdrive:fdc:0:35hd"]

a2d.ConfigureRepaintTime(0.25)

--[[
  Select a volume or folder containing multiple files. File > Get
  Info. During the count of the files, eject the disk. Verify that an
  alert appears. Reinsert the disk. Click Try Again. Verify that the
  count of files continues and paints in the correct location.

  NOTE: Fails if unloaded while reading; very timing sensitive
]]
test.Step(
  "Alert shown during File > Get Info if disk ejected, Try Again works",
  function()
    local drive = s6d1
    local current = drive.filename

    a2d.SelectPath("/A2.DESKTOP")
    a2d.OAShortcut("I", {no_wait=true})
    emu.wait(0.5)
    drive:unload()

    a2dtest.WaitForAlert()
    drive:load(current)
    apple2.Type("A") -- try again
    emu.wait(20) -- floppies are slow
    test.Snap("verify enumeration completed and no mispaints")
    a2d.DialogOK()
end)

