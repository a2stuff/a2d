--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl7 cffa2 -aux rw3"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

test.Step(
  "RAM.DRV.SYSTEM",
  function()
    -- Add RAM.DRV.SYSTEM to driver list
    a2d.CopyPath("/TESTS/DRIVERS/RAM.DRV.SYSTEM", "/A2.DESKTOP")
    a2d.SelectPath("/A2.DESKTOP/RAM.DRV.SYSTEM")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.SORT_DIRECTORY)

    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.Reboot()

    a2d.WaitForCopyToRAMCard()
    emu.wait(40) -- extra slow

    a2d.OpenPath("/RAM/DESKTOP/APPLE.MENU/TOYS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "TOYS", "should be copied to RAMCard")

    a2d.DeletePath("/A2.DESKTOP/RAM.DRV.SYSTEM")
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
end)

test.Step(
  "RAMAUX.SYSTEM",
  function()
    -- Add RAM.DRV.SYSTEM to driver list
    a2d.CopyPath("/TESTS/DRIVERS/RAMAUX.SYSTEM", "/A2.DESKTOP")
    a2d.SelectPath("/A2.DESKTOP/RAMAUX.SYSTEM")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.SORT_DIRECTORY)

    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.Reboot()
    apple2.DownArrowKey() -- to PRODOS
    apple2.DownArrowKey() -- to CLOCK.SYSTEM
    apple2.ReturnKey()

    a2d.WaitForCopyToRAMCard()
    emu.wait(40) -- extra slow

    a2d.OpenPath("/RAMA/DESKTOP/APPLE.MENU/TOYS")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "TOYS", "should be copied to RAMCard")

    a2d.DeletePath("/A2.DESKTOP/RAMAUX.SYSTEM")
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
end)
