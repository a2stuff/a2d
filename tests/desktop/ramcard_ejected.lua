--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop3 $HARDIMG -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(5) -- slow with floppies

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
    apple2.ControlKey("D") -- Drives
    a2d.WaitForRepaint()
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
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 2) -- Slot 5
    a2d.WaitForDesktopReady({timeout=240})

    a2d.SelectAll()
    local icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 4, "should have trash + 3 volumes")
    test.ExpectEqualsIgnoreCase(icons[2].name, "A2.DESKTOP", "boot disk should be first")
    test.ExpectEqualsIgnoreCase(icons[3].name, "RAM4", "ramdisk should be next")

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
    a2d.WaitForDesktopReady()

    a2d.CloseAllWindows()
    a2d.SelectAll()
    icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 3, "should have trash + 2 volumes")
    test.ExpectEqualsIgnoreCase(icons[2].name, "RAM4", "ramdisk should be first")

    drive:load(current)
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)
    a2d.SelectAll()
    icons = a2d.GetSelectedIcons()
    test.ExpectEquals(#icons, 4, "should have trash + 3 volumes")

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop, ensure it copies itself to RAMCard. Modify a
  shortcut. Verify that no prompt is shown. Power cycle and launch
  DeskTop. Verify that the shortcut modifications are present.

  Launch DeskTop, ensure it copies itself to RAMCard. Eject the
  startup disk. Modify a shortcut. Verify that a prompt is shown
  asking about saving the changes. Insert the system disk, and click
  OK. Verify that no further prompt is shown. Power cycle and launch
  DeskTop. Verify that the shortcut modifications are present.

  Launch DeskTop, ensure it copies itself to RAMCard. Eject the
  startup disk. Modify a shortcut. Verify that a prompt is shown
  asking about saving the changes. Click OK. Verify that another
  prompt is shown asking to insert the system disk. Insert the system
  disk, and click OK. Verify that no further prompt is shown. Power
  cycle and launch DeskTop. Verify that the shortcut modifications are
  present.
]]
test.Variants(
  {
    "No prompt - Shortcuts",
    "Prompt to save - Shortcuts",
    "Prompt to insert startup disk - Shortcuts",
  },
  function(idx)
    --setup
    a2d.AddShortcut("/FLOPPY1")
    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.Reboot()
    a2d.WaitForDesktopReady({timeout=240})

    local drive, current
    if idx > 1 then
      -- Ensure prompt for saving appears
      drive = apple2.Get35Drive1()
      current = drive.filename
      drive:unload()
    end

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    -- Pick a shortcut
    apple2.DownArrowKey()
    a2d.DialogOK()
    -- Twiddle a setting
    a2d.OAShortcut("4")
    a2d.OAShortcut("5")
    a2d.DialogOK()

    if idx > 1 then
      a2dtest.WaitForAlert() -- prompt to save

      if idx > 2 then
        a2d.DialogOK()
        a2dtest.WaitForAlert() -- prompt to insert system disk
      end

      drive:load(current)
      a2d.DialogOK()
    end

    a2dtest.ExpectAlertNotShowing()

    -- TODO: Verify that changes were saved

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

    apple2.BitsySelectSlotDrive("S5,D1")
    apple2.BitsyInvokeFile("DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()

    -- Ensure no prompt for saving appears
    local drive = apple2.Get35Drive1()
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

    apple2.BitsySelectSlotDrive("S5,D1")
    apple2.BitsyInvokeFile("DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()

    -- Ensure no prompt for disk appears
    local drive = apple2.Get35Drive1()
    local current = drive.filename
    drive:unload()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)
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
    while not apple2.GrabTextScreen():match("Press Esc to cancel") do
      emu.wait(1)
    end
    apple2.EscapeKey()
    a2d.WaitForDesktopReady({timeout=240})

    -- Ensure prompt for disk appears
    local drive = apple2.Get35Drive1()
    local current = drive.filename
    drive:unload()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)
    a2dtest.WaitForAlert()
    drive:load(current)
    a2d.DialogCancel()

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)


