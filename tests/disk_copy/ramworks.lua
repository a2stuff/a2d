--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl7 cffa2 -aux rw3"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[
  Configure a system with a RAMDisk in Slot 3, e.g. using
  `RAM.DRV.SYSTEM` or `RAMAUX.SYSTEM`. Launch DeskTop. Special > Copy
  Disk.... Verify that the RAMDisk appears.
]]
test.Step(
  "RAM.DRV.SYSTEM",
  function()
    -- Add RAM.DRV.SYSTEM to driver list
    a2d.CopyPath("/TESTS/DRIVERS/RAM.DRV.SYSTEM", "/A2.DESKTOP")
    a2d.SelectPath("/A2.DESKTOP/RAM.DRV.SYSTEM")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.SORT_DIRECTORY)

    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.CopyDisk()

    test.Snap("verify S3,D1 RAM disk is in list")

    -- cleanup
    a2d.OAShortcut("Q") -- quit
    a2d.WaitForDesktopReady()

    a2d.DeletePath("/A2.DESKTOP/RAM.DRV.SYSTEM")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

test.Step(
  "RAMAUX.SYSTEM",
  function()
    -- Add RAM.DRV.SYSTEM to driver list
    a2d.CopyPath("/TESTS/DRIVERS/RAMAUX.SYSTEM", "/A2.DESKTOP")
    a2d.SelectPath("/A2.DESKTOP/RAMAUX.SYSTEM")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.SORT_DIRECTORY)
    a2d.Reboot()

    -- In Bitsy Bye (since RAMAUX doesn't chain, it QUITs)
    a2d.Reboot()
    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP/CLOCK.SYSTEM")
    a2d.WaitForDesktopReady()

    a2d.CopyDisk()

    test.Snap("verify S3,D1 RAM disk is in list")

    -- cleanup
    a2d.OAShortcut("Q") -- quit
    a2d.WaitForDesktopReady()

    a2d.DeletePath("/A2.DESKTOP/RAMAUX.SYSTEM")
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
