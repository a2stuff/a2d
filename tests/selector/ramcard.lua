--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Configure a system with a RAMCard, and set DeskTop to copy itself to
  the RAMCard on startup. Launch Shortcuts. File > Run a Program....
  Click Drives. Verify that the non-RAMCard volume containing
  Shortcuts is the first disk shown.
]]
test.Step(
  "Drive order when copied to RAMCard",
  function()
    -- configure
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup() -- enable
    a2d.ToggleOptionCopyToRAMCard() -- enable
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    -- test
    a2d.OAShortcut("R")
    apple2.ControlKey("D") -- Drives
    emu.wait(5)
    test.ExpectMatch(a2dtest.OCRScreen(), "A2%.DeskTop%s.*\n.*%sRam1",
                "A2.DESKTOP should be first")
    a2d.DialogCancel()

    -- cleanup
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a system with a RAMCard, and set DeskTop to not copy
  itself to the RAMCard on startup. Launch Shortcuts. File > Run a
  Program.... Click Drives. Verify that the non-RAMCard volume
  containing Shortcuts is the first disk shown.
]]
test.Step(
  "Drive order when not copied to RAMCard",
  function()
    -- configure
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup() -- enable
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    -- test
    a2d.OAShortcut("R")
    apple2.ControlKey("D") -- Drives
    emu.wait(5)
    test.ExpectMatch(a2dtest.OCRScreen(), "A2%.DeskTop%s.*\n.*%sRam1",
                "A2.DESKTOP should be first")
    a2d.DialogCancel()

    -- cleanup
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a program with many associated files to
  copy to RAMCard "at boot". Reboot, and launch `DESKTOP.SYSTEM`.
  While the program's files are being copied to RAMCard, press Escape
  to cancel. Verify that not all of the files were copied to the
  RAMCard. Once Shortcuts starts, invoke the shortcut. Verify that the
  program starts correctly.
]]
test.Step(
  "Aborted copy on boot",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
    a2d.ToggleOptionShowShortcutsOnStartup() -- enable
    a2d.ToggleOptionCopyToRAMCard() -- enable
    a2d.CloseAllWindows()
    a2d.Reboot()

    util.WaitFor(
      "shortcut copying", function()
        return apple2.GrabTextScreen():upper():match("/EXTRAS/")
    end)
    apple2.EscapeKey()
    a2d.WaitForDesktopReady()

    apple2.Type("1")
    a2d.DialogOK()
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    -- cleanup
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a folder (or another target type that can't
  be run outside of DeskTop, e.g. an image or desk accessory) to copy
  to RAMCard "at first use". Invoke the shortcut. When the "Unable to
  run the program." alert is shown, verify that the list of shortcuts
  renders correctly. Click OK. Verify that the list of shortcuts
  renders correctly.
]]
test.Step(
  "Copy on use for unsupported type",
  function()
    a2d.AddShortcut("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH", {copy="use"})
    a2d.ToggleOptionShowShortcutsOnStartup() -- enable
    a2d.ToggleOptionCopyToRAMCard() -- enable
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    apple2.Type("1")
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="Unable to run the program"})
    test.ExpectMatch(a2dtest.OCRScreen(), "Shortcuts%s.*1%s.*Monarch",
                "shortcuts list should render correctly")
    a2d.DialogOK()
    test.ExpectMatch(a2dtest.OCRScreen(), "Shortcuts%s.*1%s.*Monarch",
                "shortcuts list should render correctly")

    -- cleanup
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a program with many associated files to
  copy to RAMCard "at first use". Invoke the shortcut. While the
  program's files are being copied to RAMCard, press Escape to cancel.
  Verify that not all of the files were copied to the RAMCard. Invoke
  the shortcut again. Verify that the files are copied to the RAMCard
  and that the program starts correctly.
]]
test.Step(
  "Aborted copy on use, retried",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.ToggleOptionShowShortcutsOnStartup() -- enable
    a2d.ToggleOptionCopyToRAMCard() -- enable
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    apple2.Type("1")
    a2d.DialogOK({no_wait=true})
    emu.wait(1)
    apple2.EscapeKey()
    emu.wait(1)

    apple2.Type("1")
    a2d.DialogOK()
    apple2.WaitForBasicSystem()
    apple2.TypeLine("PREFIX")
    emu.wait(1)
    test.ExpectMatch(apple2.GrabTextScreen(), "/RAM1/EXTRAS/", "prefix should be set")

    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    -- cleanup
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a program with a long path to copy to
  RAMCard "at first use". Invoke the shortcut. Verify that long paths
  do not render over the dialog's frame.
]]
test.Step(
  "Long path in progress dialog",
  function()
    a2d.CreateFolder("/RAM1/ABCDEF123456789")
    a2d.CreateFolder("/RAM1/ABCDEF123456789/ABCDEF123456789")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL", "/RAM1/ABCDEF123456789/ABCDEF123456789")
    a2d.AddShortcut("/RAM1/ABCDEF123456789/ABCDEF123456789/KARATEKA.YELL", {copy="use"})
    a2d.ToggleOptionShowShortcutsOnStartup() -- enable
    a2d.ToggleOptionCopyToRAMCard() -- enable
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    apple2.Type("1")
    a2d.DialogOK()
    a2dtest.MultiSnap(20, "long path does not render over frame")
    emu.wait(5)
    a2d.WaitForDesktopReady()

    -- cleanup
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
