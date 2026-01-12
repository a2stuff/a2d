--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl7 scsi"
DISKARGS="-hard1 $HARDIMG -flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local s7d1 = manager.machine.images[":sl7:scsi:scsibus:6:harddisk:image"]

a2d.ConfigureRepaintTime(0.25)

test.Step(
  "swap images",
  function()

    s7d1:load("/Users/josh/dev/a2d/res/tests.hdv")
    a2d.CheckAllDrives()
    test.Snap("swapped hard1")

    s6d1:unload()
    a2d.CheckAllDrives()
    test.Snap("flop1 ejected")

    s6d2:unload() -- harmless if already empty
    a2d.CheckAllDrives()
    test.Snap("flop2 ejected")
end)
