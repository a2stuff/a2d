--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

--[[
  Boot to `BASIC.SYSTEM` (without going through `DESKTOP.SYSTEM`
  first). Run the following commands: `CREATE /RAM5/DESKTOP`, `CREATE
  /RAM5/DESKTOP/MODULES`, `BSAVE /RAM5/DESKTOP/MODULES/DESKTOP,A0,L0`
  (substituting the RAM disk's name for `RAM5`). Launch
  `DESKTOP.SYSTEM`. Verify the install doesn't hang silently or loop
  endlessly.
]]
test.Step(
  "Copy to RAMCard fails gracefully",
  function()
    desktop.CopyPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", "/A2.DESKTOP")
    desktop.SelectPath("/A2.DESKTOP/BASIC.SYSTEM")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.SORT_DIRECTORY)
    emu.wait(5) -- sort operation
    desktop.CloseAllWindows()
    desktop.Reboot()
    apple2.WaitForBasicSystem()

    apple2.TypeLine("CREATE /RAM1/DESKTOP")
    apple2.TypeLine("CREATE /RAM1/DESKTOP/MODULES")
    apple2.TypeLine("BSAVE /RAM1/DESKTOP/MODULES/DESKTOP,A0,L0")
    apple2.TypeLine("-/A2.DESKTOP/DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()

    desktop.ToggleOptionCopyToRAMCard() -- Enable
    desktop.DeletePath("/A2.DESKTOP/BASIC.SYSTEM")
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    a2dtest.ExpectNotHanging()
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    desktop.EraseVolume("RAM1")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)
