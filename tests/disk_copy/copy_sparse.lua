--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 superdrive -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/sparse_800k.2mg -flop2 res/empty_800k.2mg"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

local s6d1 = manager.machine.images[":sl6:superdrive:fdc:0:35hd"]
local s6d2 = manager.machine.images[":sl6:superdrive:fdc:1:35hd"]

--[[
  Populate a ProDOS disk with several large files, then delete all but
  the last. Launch DeskTop. Special > Copy Disk.... Select the
  prepared disk. Ensure Options > Quick Copy is checked. Select an
  appropriate destination disk. Proceed with the copy. Verify that the
  "Blocks to transfer" count is accurate (i.e. less than the total
  block count), and the blocks read/written count up to the transfer
  count accurately.

  Populate a ProDOS disk with several large files, then delete all but
  the last. Launch DeskTop. Special > Copy Disk.... Select the
  prepared disk. Select Options > Disk Copy. Select an appropriate
  destination disk. Proceed with the copy. Verify that the "Blocks to
  transfer" count is equal to the total block count of the device, and
  the blocks read/written count up to the transfer count accurately.
]]
test.Variants(
  {
    {"copying disk with early unused blocks - Quick Copy", "quick"},
    {"copying disk with early unused blocks - Disk Copy", "disk"},
  },
  function(idx, name, what)
    local image1 = s6d1.filename
    local image2 = s6d2.filename

    a2d.CopyDisk()

    a2d.InvokeMenuItem(3, idx) -- Quick Copy or Disk Copy

    -- select source
    apple2.UpArrowKey() -- S6D2
    apple2.UpArrowKey() -- S6D1
    a2d.DialogOK()

    -- select destination
    apple2.UpArrowKey() -- S6D2
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- confirm overwrite
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- copying...
    a2dtest.WaitForAlert({timeout=600})
    if what == "quick" then
      test.Snap("verify transfer blocks is less than 1600")
    else
      test.Snap("verify transfer blocks is 1600")
    end
    test.Snap("verify blocks read/written match transfer count")
    a2d.DialogOK()

    -- re-insert the disks, since we eject them after the copy
    s6d1:load(image1)
    s6d2:load(image2)

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
