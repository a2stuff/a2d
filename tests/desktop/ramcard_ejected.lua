--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 '' -sl2 mouse -sl4 ramfactor -sl7 superdrive"
DISKARGS="-flop1 prodos_floppy1.dsk -flop3 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)
local s7d1 = manager.machine.images[":sl7:superdrive:fdc:0:35hd"]

--[[
  Configure a system with a RAMCard, and set DeskTop to not copy
  itself to the RAMCard on startup. Launch DeskTop. Verify that the
  non-RAMCard volume containing DeskTop appears in the top right
  corner of the desktop. File > Copy To.... Verify that the
  non-RAMCard volume containing DeskTop is the first disk shown.
]]
test.Step(
  "Volume order",
  function()
    a2d.SelectAll()
    local icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 4, "should have trash + 3 volumes")
    test.ExpectEqualsIgnoreCase(icons[2].name, "A2.DESKTOP", "boot disk should be first")
    test.ExpectEqualsIgnoreCase(icons[3].name, "RAM4", "ramdisk should be next")

    a2d.SelectPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO-4)
    emu.wait(5)
    apple2.ControlKey("D") -- Drives
    emu.wait(5)
    test.Snap("verify A2.DESKTOP volume is first")
    a2d.DialogCancel()
end)

--[[
  Configure a system with a RAMCard, and set DeskTop to copy itself to
  the RAMCard on startup. Launch DeskTop. Verify that the non-RAMCard
  volume containing DeskTop appears in the top right corner of the
  desktop. File > Copy To.... Verify that the non-RAMCard volume
  containing DeskTop is the first disk shown. From within DeskTop,
  launch another app e.g. Basic.system. Eject the DeskTop volume. Exit
  the app back to DeskTop. Verify that the remaining volumes appear in
  default order.
]]
test.Step(
  "Volume order when copied to RAMCard, ejected",
  function()
    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.CloseAllWindows()
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1)
    a2d.WaitForDesktopReady({timeout=240})

    a2d.SelectAll()
    local icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 4, "should have trash + 3 volumes")
    test.ExpectEqualsIgnoreCase(icons[2].name, "A2.DESKTOP", "boot disk should be first")
    test.ExpectEqualsIgnoreCase(icons[3].name, "RAM4", "ramdisk should be next")

    a2d.SelectPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO-4)
    emu.wait(5)
    apple2.ControlKey("D") -- Drives
    emu.wait(5)
    test.Snap("verify A2.DESKTOP volume is first")
    a2d.DialogCancel()

    a2d.OpenPath("/RAM4/DESKTOP/EXTRAS/BASIC.SYSTEM")
    local drive = s7d1
    local current = drive.filename
    drive:unload()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.CloseAllWindows()
    a2d.SelectAll()
    icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 3, "should have trash + 2 volumes")
    test.ExpectEqualsIgnoreCase(icons[2].name, "RAM4", "ramdisk should be first")

    drive:load(current)
    a2d.CheckAllDrives()
    a2d.SelectAll()
    icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 4, "should have trash + 3 volumes")

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Invoke `DESKTOP.SYSTEM`, ensure it copies itself to RAMCard. Quit
  DeskTop. Restart DeskTop from the original startup disk. Shortcuts >
  Edit a Shortcut. Select a shortcut, modify it (e.g. change its name)
  and click OK. Verify that no prompt is shown for saving changes to
  the startup disk.
]]
test.Step(
  "No prompt for selector entry if startup disk ejected when running from RAMCard",
  function()
    --setup
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.Reboot()
    a2d.WaitForDesktopReady({timeout=240})

    a2d.Quit()

    -- Restart DESKTOP.SYSTEM

    apple2.BitsyInvokePath("/A2.DESKTOP/DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()

    -- Ensure no prompt for saving appears
    local drive = s7d1
    local current = drive.filename
    drive:unload()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()
    a2d.ClearTextField()
    apple2.Type("New Name")
    a2d.DialogOK()
    emu.wait(5)
    a2dtest.ExpectAlertNotShowing()
    a2d.DialogCancel()
    drive:load(current)

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Invoke `DESKTOP.SYSTEM`, ensure it copies itself to RAMCard. Quit
  DeskTop. Restart DeskTop from the original startup disk. Eject the
  startup disk. Special > Format Disk. Verify that no prompt for the
  startup disk is shown.
]]
test.Step(
  "No prompt for overlay if startup disk ejected when running from RAMCard",
  function()
    --setup
    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.Reboot()
    a2d.WaitForDesktopReady({timeout=240})

    a2d.Quit()
    apple2.BitsyInvokePath("/A2.DESKTOP/DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()

    -- Ensure no prompt for disk appears
    local drive = s7d1
    local current = drive.filename
    drive:unload()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)
    emu.wait(5)
    a2dtest.ExpectAlertNotShowing()
    a2d.DialogCancel()
    drive:load(current)
    emu.wait(5)

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Invoke `DESKTOP.SYSTEM`, and hit Escape when copying to RAMCard.
  Once DeskTop has started, eject the startup disk. Special > Format
  Disk. Verify that a prompt to insert the system disk is shown.
]]
test.Step(
  "Aborted copy to RAMCard correctly prompts for overlays",
  function()
    --setup
    a2d.ToggleOptionCopyToRAMCard() -- Enable

    -- Cancel copy
    a2d.Reboot({no_wait=true})
    util.WaitFor(
      "cancel message", function()
        return apple2.GrabTextScreen():match("Press Esc to cancel")
    end)
    apple2.EscapeKey()
    a2d.WaitForDesktopReady({timeout=240})

    -- Ensure prompt for disk appears
    local drive = s7d1
    local current = drive.filename
    drive:unload()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)
    a2dtest.WaitForAlert({match="insert the system disk"})
    drive:load(current)
    a2d.DialogCancel()

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)


