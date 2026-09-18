--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl3 uthernet2 -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"
VEDISK1=floppy_with_files.2mg
VEDISK2=disk_b.2mg

======================================== ENDCONFIG ]]

test.Step(
  "VEDRIVE",
  function()
    desktop.InvokePath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {no_wait=true})
    apple2.WaitForBasicSystem()
    apple2.TypeLine("PREFIX /TESTS/DRIVERS")
    emu.wait(10)

    --------------------------------------------------
    -- Configure VEDrive
    --------------------------------------------------

    apple2.TypeLine("-VEDRIVE.SETUP")

    util.WaitFor(
      "IP prompt", function()
        return apple2.GrabTextScreen():match("PLEASE ENTER THE ADTPRO SERVER ADDRESS:")
    end)
    apple2.TypeLine("192.168.64.1")

    util.WaitFor(
      "audible feedback prompt", function()
        return apple2.GrabTextScreen():match("AUDIO FEEDBACK IF AVAILABLE%?")
    end)
    apple2.LeftArrowKey()
    apple2.TypeLine("0")

    util.WaitFor(
      "visual feedback prompt", function()
        return apple2.GrabTextScreen():match("VISUAL FEEDBACK IF AVAILABLE%?")
    end)
    apple2.LeftArrowKey()
    apple2.TypeLine("0")

    apple2.Type("_")
    util.WaitFor(
      "prompt", function()
        return apple2.GrabTextScreen():match("]_")
    end)
    apple2.LeftArrowKey()

    --------------------------------------------------
    -- Launch VEDrive
    --------------------------------------------------

    apple2.TypeLine("-VEDRIVE")
    util.WaitFor(
      "confirmation", function()
        return apple2.GrabTextScreen():match("Add VEDrive")
    end)

    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    --------------------------------------------------
    -- Verify
    --------------------------------------------------

    desktop.CloseAllWindows()
    desktop.ClearSelection()
    a2dtest.WaitForSystemTask()
    test.Snap("verify VEDrives have File Share icons")

    desktop.OpenWindow("WITH.FILES")
    test.Snap("verify files present")
    desktop.CloseAllWindows()
    desktop.ClearSelection()

    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_FORMAT_DISK-2)
    a2dtest.WaitForSystemTask()
    test.Snap("verify VEDrives listed")
end)
