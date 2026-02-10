--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl4 ramfactor -sl7 superdrive"
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)
a2d.RemoveClockDriverAndReboot()
local s7d1 = manager.machine.images[":sl7:superdrive:fdc:0:35hd"]

--[[
  Repeat the following cases with:
  * Options
  * International
  * Control Panel
  * Date and Time DA (on a system without a real-time clock)
  * Sounds
  * Views

  * Launch DeskTop, ensure it copies itself to RAMCard. Launch the DA
    and modify a setting. Verify that no prompt is shown. Power cycle
    and launch DeskTop. Verify that the modifications are present.

  * Launch DeskTop, ensure it copies itself to RAMCard. Eject the
    startup disk. Launch the DA and Modify a setting. Verify that a
    prompt is shown asking about saving the changes. Insert the system
    disk, and click OK. Verify that no further prompt is shown. Power
    cycle and launch DeskTop. Verify that the modifications are
    present.

  * Launch DeskTop, ensure it copies itself to RAMCard. Eject the
    startup disk. Launch the DA and modify a setting. Verify that a
    prompt is shown asking about saving the changes. Click OK. Verify
    that another prompt is shown asking to insert the system disk.
    Insert the system disk, and click OK. Verify that no further
    prompt is shown. Power cycle and launch DeskTop. Verify that the
    modifications are present.

  Repeat but without the RAMCard setting. Verify the same prompts
  appear.
]]
function SaveSettingsTest(name, filename, toggle_func)
  test.Variants(
    {
      { name .. " - RAMCard - No prompt ", filename, 0, false},
      { name .. " - RAMCard - Prompt to save", filename, 1, false},
      { name .. " - RAMCard - Prompt to insert startup disk", filename, 2, false},
      { name .. " - RAMCard - rename - No prompt", filename, 0, true},
      { name .. " - RAMCard - rename - Prompt to save", filename, 1, true},
      { name .. " - RAMCard - rename - Prompt to insert startup disk", filename, 2, true},
    },
    function(idx, name, da, prompts, rename)
      --setup
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

      a2d.OpenPath("/RAM4/DESKTOP/APPLE.MENU/CONTROL.PANELS/" .. da)
      toggle_func()
      a2d.CloseWindow()

      if prompts > 0 then
        a2dtest.WaitForAlert({match="save the changes"})

        if prompts > 1 then
          a2d.DialogOK()
          a2dtest.WaitForAlert({match="insert the system disk"})
        end

        drive:load(current)
        a2d.DialogOK()
      end
      emu.wait(5) -- time for writing

      a2dtest.ExpectAlertNotShowing()

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

  -- Now do the same w/o the RAMCard in the mix
  test.Variants(
    {
      { name .. " - No prompt", filename, 0, false},
      { name .. " - Prompt to save", filename, 1, false},
      { name .. " - Prompt to insert startup disk", filename, 2, false},
      { name .. " - No prompt - rename", filename, 0, true},
      { name .. " - Prompt to save - rename", filename, 1, true},
      { name .. " - Prompt to insert startup disk - rename", filename, 2, true},
    },
    function(idx, name, da, prompts, rename)

      if rename then
        a2d.RenamePath("/A2.DESKTOP", "A2D")
        a2d.OpenPath("/A2D/APPLE.MENU/CONTROL.PANELS/" .. da)
      else
        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/" .. da)
      end

      toggle_func()

      local drive, current
      if prompts > 0 then
        -- Ensure prompt for saving appears
        drive = s7d1
        current = drive.filename
        drive:unload()
      end

      a2d.CloseWindow()

      if prompts > 0 then
        a2dtest.WaitForAlert({match="save the changes"})

        if prompts > 1 then
          a2d.DialogOK()
          a2dtest.WaitForAlert({match="insert the system disk"})
        end

        drive:load(current)
        a2d.DialogOK()
      end
      emu.wait(5) -- time for writing

      a2dtest.ExpectAlertNotShowing()

      -- cleanup
      a2d.CheckAllDrives()
      if rename then
        a2d.RenamePath("/A2D", "A2.DESKTOP")
      end
      a2d.DeletePath("/A2.DESKTOP/LOCAL")
      a2d.Reboot()
      a2d.WaitForDesktopReady()
  end)
end

SaveSettingsTest("Options", "OPTIONS", function()
                   a2d.OAShortcut("1") -- toggle checkbox
                   a2d.OAShortcut("1")
end)

SaveSettingsTest("International", "INTERNATIONAL", function()
                   a2d.OAShortcut("1") -- toggle checkbox
                   a2d.OAShortcut("1")
end)

SaveSettingsTest("Control Panel", "CONTROL.PANEL", function()
                   a2d.OAShortcut("1") -- toggle checkbox
                   a2d.OAShortcut("1")
end)

SaveSettingsTest("Views", "VIEWS", function()
                   a2d.OAShortcut("2") -- change radio buttons
                   a2d.OAShortcut("1")
end)

SaveSettingsTest("Sounds", "SOUNDS", function()
                   apple2.DownArrowKey() -- change listbox index
                   emu.wait(2)
                   apple2.UpArrowKey()
                   emu.wait(2)
end)

SaveSettingsTest("Date & Time", "DATE.AND.TIME", function()
                   apple2.DownArrowKey() -- adjust time
                   apple2.UpArrowKey()
                   a2d.OAShortcut("2") -- change radio buttons
                   a2d.OAShortcut("1")
end)
