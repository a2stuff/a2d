--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Configure a system with DeskTop booting from slot 7 and a floppy
  drive in slot 6. Place a ProDOS formatted disk without `PRODOS` in
  the floppy drive. Invoke `DESKTOP.SYSTEM`. While the "Starting
  Shortcuts..." progress bar is displayed, hold down Apple and 6.
  Verify that when the progress bar disappears the screen clears
  completely to black and that the message "UNABLE TO LOAD PRODOS" is
  displayed properly in 40-column mode.
]]
test.Step(
  "exits 80 column mode",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()

    util.WaitFor(
      "Starting Shortcuts", function()
        return apple2.GrabTextScreen():match("Starting Shortcuts")
    end)
    a2d.OAShortcut("6")

    util.WaitFor(
      "Unable to load ProDOS", function()
        return apple2.GrabTextScreen():match("^%s*%*%*%* UNABLE TO LOAD PRODOS %*%*%*%s*$")
    end)

    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)


