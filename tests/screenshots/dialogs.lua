--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 res/prodos_floppy1.dsk -flop2 res/prodos_floppy2.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[============================================================

  Dump all the dialogs

  ============================================================]]

--------------------------------------------------
-- Apple Menu
--------------------------------------------------

test.Step(
  "Apple > About Apple II DeskTop",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP)
    test.Snap("Apple > About Apple II DeskTop")
    a2d.CloseWindow()
end)

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    test.Snap("Apple > About This Apple II")
    a2d.CloseWindow()
end)

--------------------------------------------------
-- File Menu
--------------------------------------------------

test.Step(
  "File > Get Info (volume)",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    a2d.OAShortcut("I")
    emu.wait(5) -- enumerating takes a bit
    test.Snap("File > Get Info (volume)")
    a2d.DialogCancel()
end)

test.Step(
  "File > Get Info (file)",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.OAShortcut("I")
    test.Snap("File > Get Info (file)")
    a2d.DialogCancel()
    a2d.CloseAllWindows()
end)

test.Step(
  "File > Copy To...",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
    test.Snap("File > Copy To...")
    a2d.DialogCancel()
    a2d.CloseAllWindows()
end)

--------------------------------------------------
-- Special Menu
--------------------------------------------------

test.Step(
  "Special > Format Disk...",
  function()
    a2d.ClearSelection()

    -- show dialog
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK - 2)
    test.Snap("Special > Format Disk... - Prompt for drive")

    -- select RAMFactor
    apple2.DownArrowKey() -- S7D1
    apple2.DownArrowKey() -- S7D2
    apple2.DownArrowKey() -- S1D1
    test.Snap("Special > Format Disk... - Drive selected")

    -- accept selection
    a2d.DialogOK()
    test.Snap("Special > Format Disk... - Prompt for name")

    -- type new name
    apple2.Type("NEWNAME")
    test.Snap("Special > Format Disk... - Name entered")

    -- accept typed name
    a2d.DialogOK()
    test.Snap("Special > Format Disk... - Confirm erase")

    -- confirm format
    a2d.DialogOK({no_wait=true})
    emu.wait(0.2)
    test.Snap("Special > Format Disk... - Format in progress")
end)

test.Step(
  "Special > Erase Disk...",
  function()
    a2d.ClearSelection()

    -- show dialog
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_ERASE_DISK - 2)
    test.Snap("Special > Erase Disk... - Prompt for drive")

    -- select RAMFactor
    apple2.DownArrowKey() -- S7D1
    apple2.DownArrowKey() -- S7D2
    apple2.DownArrowKey() -- S1D1
    test.Snap("Special > Erase Disk... - Drive selected")

    -- accept selection
    a2d.DialogOK()
    test.Snap("Special > Erase Disk... - Prompt for name")

    -- type new name
    apple2.Type("NEWNAME")
    test.Snap("Special > Erase Disk... - Name entered")

    -- accept typed name
    a2d.DialogOK()
    test.Snap("Special > Erase Disk... - Confirm erase")

    -- confirm erase
    a2d.DialogOK({no_wait=true})
    emu.wait(0.15)
    test.Snap("Special > Erase Disk... - Erase in progress")
end)

--------------------------------------------------
-- Shortcuts Menu
--------------------------------------------------

test.Step(
  "Shortcuts > Add a Shortcut...",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    test.Snap("Shortcuts > Add a Shortcut...")
    a2d.DialogOK()
end)

test.Step(
  "Shortcuts > Edit a Shortcut...",
  function()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    test.Snap("Shortcuts > Edit a Shortcut... - Select shortcut")
    apple2.DownArrowKey()
    a2d.DialogOK()
    test.Snap("Shortcuts > Edit a Shortcut... - Editing")
    a2d.DialogCancel()
    a2d.CloseAllWindows()
end)

test.Step(
  "Shortcuts > Delete a Shortcut...",
  function()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    test.Snap("Shortcuts > Delete a Shortcut...")
    a2d.DialogCancel()
end)

test.Step(
  "Shortcuts > Run a Shortcut...",
  function()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
    test.Snap("Shortcuts > Run a Shortcut...")
    a2d.DialogCancel()
end)

--------------------------------------------------
-- Disk Copy
--------------------------------------------------

test.Step(
  "Special > Copy Disk...",
  function()
    a2d.CopyDisk()

    -- "Disk Copy"
    a2d.InvokeMenuItem(3, 2)
    test.Snap("Disk Copy - \"Disk Copy\" option")

    -- "Quick Copy" / select source
    a2d.InvokeMenuItem(3, 1)
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    test.Snap("Disk Copy - \"Quick Copy\" option")
    a2d.DialogOK()

    -- select destination
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    test.Snap("Disk Copy - Select destination")
    a2d.DialogOK()

    -- insert source
    test.Snap("Disk Copy - Prompt for source")
    a2d.DialogOK()

    -- insert destination
    test.Snap("Disk Copy - Prompt for destination")
    a2d.DialogOK()

    -- confirm erase
    test.Snap("Disk Copy - Confirm erase")
    a2d.DialogOK()

    --[[
      BUG: hit "error during formatting" consistently when using "Disk Copy" here!
      -- Confirmed it is https://github.com/mamedev/mame/issues/14474 ?
      -- Could work around by using System Speed to slow ZIP Chip

      -- formatting
      emu.wait(10)
      test.Snap("Special > Copy Disk...")
      emu.wait(10)
    --]]

    -- reading progress
    emu.wait(0.25)
    test.Snap("Disk Copy - Reading progress")

    -- writing progress
    emu.wait(2)
    test.Snap("Disk Copy - Writing progress")

    -- success
    emu.wait(3)
    test.Snap("Disk Copy - Success")

    -- back to desktop
    a2d.DialogOK()
    emu.wait(10) -- scanning drives
    a2d.OAShortcut('Q')
    a2d.WaitForDesktopReady()
    a2d.DialogOK() -- dismiss "two volumes with the same name"
end)

test.Step(
  "Selector",
  function()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.ToggleOptionCopyToRAMCard()
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.Reboot()

    -- Launcher: Copying to RAMCard...
    emu.wait(5)
    test.Snap("Selector - Copying app to RAMCard...")
    a2d.WaitForDesktopReady()

    -- Shortcuts dialog
    emu.wait(10) -- let copying finish
    test.Snap("Selector - Shortcuts dialog")

    -- File > Run a Program...
    a2d.OAShortcut('R')
    a2d.WaitForRepaint()
    test.Snap("Selector - Run a Program...")
    a2d.DialogCancel()

    -- Copy to RAMCard...
    apple2.DownArrowKey()
    apple2.ReturnKey()
    emu.wait(2)
    test.Snap("Selector - Copying shortcut to RAMCard...")
end)
