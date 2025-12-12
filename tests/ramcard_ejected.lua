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
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
end)

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
    a2d.WaitForDesktopShowing()
    emu.wait(10)

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
end)

test.Variants(
  {
    "No prompt - Options",
    "No prompt - International",
    "No prompt - Control Panel",
    "Prompt to save - Options",
    "Prompt to save - International",
    "Prompt to save - Control Panel",
    "Prompt to insert startup disk - Options",
    "Prompt to insert startup disk - International",
    "Prompt to insert startup disk - Control Panel",
  },
  function(idx)
    --setup
    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.Reboot()
    a2d.WaitForDesktopShowing()
    emu.wait(10)

    local drive, current
    if idx > 3 then
      -- Ensure prompt for saving appears
      drive = apple2.Get35Drive1()
      current = drive.filename
      drive:unload()
    end

    if idx == 1 or idx == 4 or idx == 7 then
      a2d.OpenPath("/RAM4/DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    elseif idx == 2 or idx == 5 or idx == 8 then
      a2d.OpenPath("/RAM4/DESKTOP/APPLE.MENU/CONTROL.PANELS/INTERNATIONAL")
    elseif idx == 3 or idx == 6 or idx == 9 then
      a2d.OpenPath("/RAM4/DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    end
    a2d.OAShortcut("1")
    a2d.OAShortcut("1")
    a2d.CloseWindow()

    if idx > 3 then
      a2dtest.WaitForAlert() -- prompt to save

      if idx > 6 then
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
end)

test.Step(
  "No prompt for selector entry if startup disk ejected when running from RAMCard",
  function()
    --setup
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.Reboot()
    a2d.WaitForDesktopShowing()
    emu.wait(10)

    a2d.Quit()

    -- Restart DESKTOP.SYSTEM

    -- TODO: Utility for driving Bitsy Bye
    -- NOTE: Will need to handle inverted characters

    apple2.TabKey() -- to S3,D2
    apple2.TabKey() emu.wait(5) -- to S6,D1
    apple2.TabKey() emu.wait(5) -- to S5,D1
    apple2.DownArrowKey() -- CLOCK.SYSTEM
    apple2.DownArrowKey() -- README
    apple2.DownArrowKey() -- DESKTOP.SYSTEM
    apple2.ReturnKey()
    a2d.WaitForRestart()

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
end)

test.Step(
  "No prompt for overlay if startup disk ejected when running from RAMCard",
  function()
    --setup
    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.Reboot()
    a2d.WaitForDesktopShowing()
    emu.wait(10)

    a2d.Quit()

    -- Restart DESKTOP.SYSTEM

    -- TODO: Utility for driving Bitsy Bye
    -- NOTE: Will need to handle inverted characters

    apple2.TabKey() -- to S3,D2
    apple2.TabKey() emu.wait(5) -- to S6,D1
    apple2.TabKey() emu.wait(5) -- to S5,D1
    apple2.DownArrowKey() -- CLOCK.SYSTEM
    apple2.DownArrowKey() -- README
    apple2.DownArrowKey() -- DESKTOP.SYSTEM
    apple2.ReturnKey()
    a2d.WaitForRestart()

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
end)

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
    a2d.WaitForRestart()

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
end)


