--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl7 cffa2 -aux rw3"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

--[[
  Run DeskTop on a system with RAMWorks and using `RAM.DRV.SYSTEM`.
  Verify that sub-directories under `APPLE.MENU` are copied to
  `/RAM/DESKTOP/APPLE.MENU`.
]]
test.Step(
  "RAM.DRV.SYSTEM",
  function()
    -- Add RAM.DRV.SYSTEM to driver list
    desktop.CopyPath("/TESTS/DRIVERS/RAM.DRV.SYSTEM", "/A2.DESKTOP")
    desktop.SelectPath("/A2.DESKTOP/RAM.DRV.SYSTEM")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.SORT_DIRECTORY)
    a2dtest.WaitForSystemTask()

    desktop.ToggleOptionCopyToRAMCard() -- Enable
    desktop.Reboot()
    a2d.WaitForDesktopReady({timeout=120})

    desktop.OpenWindow("/RAM/DESKTOP/APPLE.MENU/TOYS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "TOYS", "should be copied to RAMCard")

    desktop.DeletePath("/A2.DESKTOP/RAM.DRV.SYSTEM")
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
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
    a2dtest.WaitForSystemTask()

    desktop.ToggleOptionCopyToRAMCard() -- Enable

    -- In Bitsy Bye (since RAMAUX doesn't chain, it QUITs)
    desktop.Reboot()
    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP/CLOCK.SYSTEM")

    a2d.WaitForCopyToRAMCard()

    desktop.OpenWindow("/RAMA/DESKTOP/APPLE.MENU/TOYS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "TOYS", "should be copied to RAMCard")

    desktop.DeletePath("/A2.DESKTOP/RAMAUX.SYSTEM")
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)
