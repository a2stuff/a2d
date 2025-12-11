--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop3 $HARDIMG -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]--

test.Step(
  "Volume order",
  function()
    test.Snap("verify A2.DESKTOP volume in top right")

    a2d.SelectPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO-4)
    apple2.ControlKey("D") -- Drives
    a2d.WaitForRepaint()

    test.Snap("verify A2.DESKTOP volume is first")

    a2d.DialogCancel()
end)


test.Step(
  "Volume order when copied to RAMCard, ejected",
  function()
    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.CloseAllWindows()
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 2) -- Slot 5
    emu.wait(240) -- copying from floppy is very slow

    test.Snap("verify A2.DESKTOP volume in top right")

    a2d.SelectPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO-4)
    apple2.ControlKey("D") -- Drives
    a2d.WaitForRepaint()

    test.Snap("verify A2.DESKTOP volume is first")

    a2d.DialogCancel()

    a2d.OpenPath("/RAM4/DESKTOP/EXTRAS/BASIC.SYSTEM")
    local drive = apple2.Get35Drive1()
    local current = drive.filename
    drive:unload()
    apple2.TypeLine("BYE")
    a2d.WaitForRestart()

    test.Snap("verify volumes appear in order")

    drive:load(current)
end)

