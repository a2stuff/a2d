--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl7 cffa2 -aux rw3"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

--[[
  Configure a system with a RAMDisk in Slot 3, e.g. using
  `RAM.DRV.SYSTEM` or `RAMAUX.SYSTEM`. Launch DeskTop. Special > Copy
  Disk.... Verify that the RAMDisk appears.
]]
test.Step(
  "RAM.DRV.SYSTEM",
  function()
    -- Add RAM.DRV.SYSTEM to driver list
    desktop.CopyPath("/TESTS/DRIVERS/RAM.DRV.SYSTEM", "/A2.DESKTOP")
    desktop.SelectPath("/A2.DESKTOP/RAM.DRV.SYSTEM")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.SORT_DIRECTORY)

    desktop.Reboot()
    a2d.WaitForDesktopReady()

    desktop.CopyDisk()

    test.ExpectMatch(a2dtest.OCRScreen(), "3 +1 +Ram",
                "S3,D1 RAM disk should be in list")

    -- cleanup
    a2d.OAShortcut("Q") -- quit
    a2d.WaitForDesktopReady()

    desktop.DeletePath("/A2.DESKTOP/RAM.DRV.SYSTEM")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

test.Step(
  "RAMAUX.SYSTEM",
  function()
    -- Add RAM.DRV.SYSTEM to driver list
    desktop.CopyPath("/TESTS/DRIVERS/RAMAUX.SYSTEM", "/A2.DESKTOP")
    desktop.SelectPath("/A2.DESKTOP/RAMAUX.SYSTEM")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.SORT_DIRECTORY)
    desktop.Reboot()

    -- In Bitsy Bye (since RAMAUX doesn't chain, it QUITs)
    desktop.Reboot()
    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP/CLOCK.SYSTEM")
    a2d.WaitForDesktopReady()

    desktop.CopyDisk()

    test.ExpectMatch(a2dtest.OCRScreen(), "3 +1 +Ram",
                "S3,D1 RAM disk should be in list")

    -- cleanup
    a2d.OAShortcut("Q") -- quit
    a2d.WaitForDesktopReady()

    desktop.DeletePath("/A2.DESKTOP/RAMAUX.SYSTEM")
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)
