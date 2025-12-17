--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop3 $HARDIMG -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(5) -- slow with floppies
--[[
  Configure a system with a RAMCard, and ensure DeskTop is configured
  to copy to RAMCard on startup. Configure a shortcut to copy to
  RAMCard "at boot". Launch DeskTop. Verify the shortcut's files were
  copied to RAMCard. Quit DeskTop. Re-launch DeskTop from the original
  startup disk. Eject the disk containing the shortcut. Run the
  shortcut. Verify that it launches correctly.
]]
test.Step(
  "Running with a prefix and relative path works",
  function()
    a2d.ToggleOptionCopyToRAMCard()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
    a2d.Reboot()
    a2d.WaitForDesktopReady({timeout=360})

    -- Verify copied to RAMCard
    a2d.OpenPath("/RAM4/EXTRAS")

    -- Quit
    a2d.CloseAllWindows()
    a2d.Quit()

    -- Re-launch from original startup disk
    apple2.WaitForBitsy()
    apple2.BitsySelectSlotDrive("S5,D1")
    apple2.BitsyInvokeFile("DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()

    -- Eject the disk
    local drive = apple2.Get35Drive1()
    local current = drive.filename
    drive:unload()

    -- Run the shortcut
    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()
    drive:load(current)
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a system with a RAMCard, and ensure DeskTop is configured
  to copy to RAMCard on startup. Invoke `DESKTOP.SYSTEM`. After the
  progress bar advances a few ticks but before it gets more than
  halfway, press Escape. Wait for DeskTop to start. File > Quit.
  Invoke `DESKTOP.SYSTEM` again. Open the `SAMPLE.MEDIA` folder and
  select `APPLEVISION`. File > Open. Verify that it starts.
]]
test.Step(
  "Aborted copy still runs interpreters",
  function()
    a2d.ToggleOptionCopyToRAMCard()
    a2d.Reboot()
    util.WaitFor(
      "progress bar", function()
        return apple2.GrabTextScreen():match("Esc to cancel")
    end)
    emu.wait(20)
    test.Snap("verify progress bar not more than halfway")
    apple2.EscapeKey()

    a2d.WaitForDesktopReady({timeout=240})
    a2d.Quit()

    -- Re-launch from original startup disk
    apple2.WaitForBitsy()
    apple2.BitsySelectSlotDrive("S5,D1")
    apple2.BitsyInvokeFile("DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady({timeout=360})
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/APPLEVISION")
    util.WaitFor(
      "APPLE-VISION", function()
        return apple2.GrabTextScreen():match("APPLE%-VISION")
    end)
    apple2.EscapeKey()
    a2d.WaitForDesktopReady({timeout=360})

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

