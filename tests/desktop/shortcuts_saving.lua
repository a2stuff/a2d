--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl4 ramfactor -sl7 superdrive"
DISKARGS="-flop3 $HARDIMG -flop4 floppy_with_files.2mg"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)
local s7d1 = manager.machine.images[":sl7:superdrive:fdc:0:35hd"]

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
    {"Shortcuts - No prompt", 0, false},
    {"Shortcuts - Prompt to save", 1, false},
    {"Shortcuts - Prompt to insert startup disk", 2, false},
    {"Shortcuts - rename - No prompt", 0, true},
    {"Shortcuts - rename - Prompt to save", 1, true},
    {"Shortcuts - rename - Prompt to insert startup disk", 2, true},
  },
  function(idx, name, prompts, rename)
    --setup
    a2d.AddShortcut("/WITH.FILES/LOREM.IPSUM") -- not on startup disk
    emu.wait(2)

    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.Reboot()
    a2d.WaitForDesktopReady({timeout=240})

    if rename then
      a2d.RenamePath("/A2.DESKTOP", "A2D")
    end

    local drive, current
    if prompts > 0 then
      -- Ensure prompt for saving appears
      drive = s7d1
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

    if prompts > 0 then
      a2dtest.WaitForAlert({match="save the changes"})

      if prompts > 1 then
        a2d.DialogOK()
        a2dtest.WaitForAlert({match="insert the system disk"})
      end

      drive:load(current)
      a2d.DialogOK()
    end

    a2dtest.ExpectAlertNotShowing()

    -- TODO: Verify that changes were saved

    -- cleanup
    a2d.CheckAllDrives()
    if rename then
      a2d.RenamePath("/A2D", "A2.DESKTOP")
    end
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
