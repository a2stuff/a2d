--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -flop1 prodos_floppy1.dsk -flop2 prodos_floppy2.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]

--[[============================================================

  Dump all the dialogs

  ============================================================]]

local DialogTest = test.Step

--------------------------------------------------
-- Apple Menu
--------------------------------------------------

DialogTest(
  "Apple > About Apple II DeskTop",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP)
    test.Snap("Apple > About Apple II DeskTop")
    a2d.CloseWindow()
end)

DialogTest(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    test.Snap("Apple > About This Apple II")
    a2d.CloseWindow()
end)

--------------------------------------------------
-- File Menu
--------------------------------------------------

DialogTest(
  "File > Get Info (volume)",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    a2d.OAShortcut("I")
    emu.wait(5) -- enumerating takes a bit
    test.Snap("File > Get Info (volume)")
    a2d.DialogCancel()
end)

DialogTest(
  "File > Get Info (file)",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.OAShortcut("I")
    test.Snap("File > Get Info (file)")
    a2d.DialogCancel()
    a2d.CloseAllWindows()
end)

DialogTest(
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

DialogTest(
  "Special > Format Disk...",
  function()
    a2d.ClearSelection()

    -- show dialog
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK - 2)
    test.Snap("Special > Format Disk... - Prompt for drive")

    -- select RAMFactor
    a2d.FormatEraseSelectSlotDrive(1, 1, {no_ok=true})
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

DialogTest(
  "Special > Erase Disk...",
  function()
    a2d.ClearSelection()

    -- show dialog
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_ERASE_DISK - 2)
    test.Snap("Special > Erase Disk... - Prompt for drive")

    -- select RAMFactor
    a2d.FormatEraseSelectSlotDrive(1, 1, {no_ok=true})
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

local shortcut_added = false

DialogTest(
  "Shortcuts > Add a Shortcut...",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    test.Snap("Shortcuts > Add a Shortcut...")
    a2d.DialogOK()
    shortcut_added = true
end)

DialogTest(
  "Shortcuts > Edit a Shortcut...",
  function()
    if not shortcut_added then
      a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
      shortcut_added = true
    end

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    test.Snap("Shortcuts > Edit a Shortcut... - Select shortcut")
    apple2.DownArrowKey()
    a2d.DialogOK()
    test.Snap("Shortcuts > Edit a Shortcut... - Editing")
    a2d.DialogCancel()
    a2d.CloseAllWindows()
end)

DialogTest(
  "Shortcuts > Delete a Shortcut...",
  function()
    if not shortcut_added then
      a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
      shortcut_added = true
    end

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    test.Snap("Shortcuts > Delete a Shortcut...")
    a2d.DialogCancel()
end)

DialogTest(
  "Shortcuts > Run a Shortcut...",
  function()
    if not shortcut_added then
      a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
      shortcut_added = true
    end

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
    test.Snap("Shortcuts > Run a Shortcut...")
    a2d.DialogCancel()
end)

if shortcut_added then
  a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
  a2d.Reboot()
  a2d.WaitForDesktopReady()
end

--------------------------------------------------
-- Disk Copy
--------------------------------------------------

DialogTest(
  "Special > Copy Disk...",
  function()
    a2d.CopyDisk()

    -- "Disk Copy"
    a2d.InvokeMenuItem(3, 2)
    test.Snap("Disk Copy - \"Disk Copy\" option")

    -- "Quick Copy" / select source
    a2d.InvokeMenuItem(3, 1)
    apple2.DownArrowKey() -- S7,D1
    apple2.DownArrowKey() -- S1,D1
    apple2.DownArrowKey() -- S6,D1
    test.Snap("Disk Copy - \"Quick Copy\" option")
    a2d.DialogOK()

    -- select destination
    apple2.DownArrowKey() -- S6,D1
    apple2.DownArrowKey() -- S6,D2
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

    -- cleanup
    a2d.DialogOK()
    emu.wait(10) -- scanning drives
    a2d.OAShortcut('Q') -- back to DeskTop
    a2d.WaitForDesktopReady()
    a2d.DialogOK() -- dismiss "two volumes with the same name"
    local image1 = s6d1.filename
    s6d1:unload()
    a2d.CheckAllDrives()
    emu.wait(5)
    a2d.RenamePath("/FLOPPY1", "Floppy2")
    s6d1:load(image1)
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

DialogTest(
  "Selector",
  function()
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

    -- cleanup
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady() -- back to Shortcuts
    apple2.Type("D")
    a2d.WaitForDesktopReady() -- back to DeskTop
    a2d.ToggleOptionCopyToRAMCard()
    a2d.ToggleOptionShowShortcutsOnStartup()
end)
