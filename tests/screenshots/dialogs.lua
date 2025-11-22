--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 res/prodos_floppy1.dsk -flop2 res/prodos_floppy2.dsk"

======================================== ENDCONFIG ]]--

--[[============================================================

  Dump all the dialogs

  ============================================================]]--

--------------------------------------------------
-- Apple Menu
--------------------------------------------------

test.Step(
  "Apple > About Apple II DeskTop",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP)
    test.Snap("Apple > About Apple II DeskTop")
    a2d.CloseWindow()
    return test.PASS
end)

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    test.Snap("Apple > About This Apple II")
    a2d.CloseWindow()
    return test.PASS
end)

--------------------------------------------------
-- File Menu
--------------------------------------------------

test.Step(
  "File > Get Info (volume)",
  function()
    apple2.Type("A2.DESKTOP")
    a2d.OAShortcut("I")
    emu.wait(5) -- enumerating takes a bit
    test.Snap("File > Get Info (volume)")
    a2d.DialogCancel()
    return test.PASS
end)

test.Step(
  "File > Get Info (file)",
  function()
    a2d.SelectAndOpen("A2.DESKTOP")
    apple2.Type("READ.ME")
    a2d.OAShortcut("I")
    test.Snap("File > Get Info (file)")
    a2d.DialogCancel()
    a2d.CloseAllWindows()
    return test.PASS
end)

test.Step(
  "File > Copy To...",
  function()
    a2d.SelectAndOpen("A2.DESKTOP")
    apple2.Type("READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
    test.Snap("File > Copy To...")
    a2d.DialogCancel()
    a2d.CloseAllWindows()
    return test.PASS
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
    apple2.ReturnKey() -- not a2d.DialogOK() because usual wait is too ong
    test.Snap("Special > Format Disk... - Format in progress")

    return test.PASS
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
    apple2.ReturnKey() -- not a2d.DialogOK() because usual wait is too ong
    test.Snap("Special > Erase Disk... - Erase in progress")

    return test.PASS
end)

--------------------------------------------------
-- Shortcuts Menu
--------------------------------------------------

test.Step(
  "Shortcuts > Add a Shortcut...",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS")
    apple2.Type("BASIC.SYSTEM")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    test.Snap("Shortcuts > Add a Shortcut...")
    a2d.OAShortcut('4') -- copy to RAMCard / on first use
    a2d.DialogOK()
    return test.PASS
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
    return test.PASS
end)

test.Step(
  "Shortcuts > Delete a Shortcut...",
  function()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    test.Snap("Shortcuts > Delete a Shortcut...")
    a2d.DialogCancel()
    return test.PASS
end)

test.Step(
  "Shortcuts > Run a Shortcut...",
  function()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
    test.Snap("Shortcuts > Run a Shortcut...")
    a2d.DialogCancel()
    return test.PASS
end)

--------------------------------------------------
-- Disk Copy
--------------------------------------------------

-- BUG: This managed to make a "No device connected" error????
-- with nothing in floppy drives
--[[
  test.Step(
  "Special > Check All Drives...",
  function()
  a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)
  a2d.WaitForRestart()
  test.Snap("Special > Check All Drives...")
  return test.PASS
  end)
]]--

test.Step(
  "Special > Copy Disk...",
  function()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK - 2)
    a2d.WaitForRestart()

    -- "Disk Copy"
    a2d.InvokeMenuItem(3, 2)
    test.Snap("Disk Copy - \"Disk Copy\" option")

    -- "Quick Copy" / select source
    a2d.InvokeMenuItem(3, 1)
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    test.Snap("Special > Copy Disk...")
    a2d.DialogOK("Disk Copy - \"Quick Copy\" option")

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
    a2d.WaitForRestart() -- scanning drives
    a2d.OAShortcut('Q')
    a2d.WaitForRestart()
    a2d.DialogOK() -- dismiss "two volumes with the same name"

    return test.PASS
end)

test.Step(
  "Selector",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    a2d.OAShortcut("1") -- Enable "Copy to RAMCard"
    a2d.OAShortcut("2") -- Enable "Show shortcuts on startup"
    a2d.CloseWindow()
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1) -- reboot (slot 7)

    -- Launcher: Copying to RAMCard...
    emu.wait(10) -- copying is slow
    test.Snap("Selector - Copying app to RAMCard...")

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

    return test.PASS
end)
