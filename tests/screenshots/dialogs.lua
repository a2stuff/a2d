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

local function DialogTest(name, func)
  test.Variants(
    {
      {name .. " - defaults", "", {}},
      {name .. " - keyboard shortcuts", " - with shortcuts", {shortcuts=true}},
      {name .. " - default button", " - with default button highlighted", {ring=true}},
    },
    function(idx, name, suffix, flags)
      if flags.shortcuts then
        a2d.ToggleOptionShowKeyboardShortcuts()
      end
      if flags.ring then
        a2d.ToggleOptionDefaultButtons()
      end

      func(suffix)

      if flags.shortcuts then
        a2d.ToggleOptionShowKeyboardShortcuts()
      end
      if flags.ring then
        a2d.ToggleOptionDefaultButtons()
      end
  end)
end

--------------------------------------------------
-- Apple Menu
--------------------------------------------------

DialogTest(
  "Apple > About Apple II DeskTop",
  function(suffix)
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP)
    test.Snap("Apple > About Apple II DeskTop" .. suffix)
    a2d.CloseWindow()
end)

DialogTest(
  "Apple > About This Apple II",
  function(suffix)
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    test.Snap("Apple > About This Apple II" .. suffix)
    a2d.CloseWindow()
end)

--------------------------------------------------
-- File Menu
--------------------------------------------------

DialogTest(
  "File > Get Info (volume)",
  function(suffix)
    a2d.SelectPath("/A2.DESKTOP")
    a2d.OAShortcut("I")
    emu.wait(5) -- enumerating takes a bit
    test.Snap("File > Get Info (volume)" .. suffix)
    a2d.DialogCancel()
end)

DialogTest(
  "File > Get Info (file)",
  function(suffix)
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.OAShortcut("I")
    test.Snap("File > Get Info (file)" .. suffix)
    a2d.DialogCancel()
    a2d.CloseAllWindows()
end)

DialogTest(
  "File > Copy To...",
  function(suffix)
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
    test.Snap("File > Copy To..." .. suffix)
    a2d.DialogCancel()
    a2d.CloseAllWindows()
end)

--------------------------------------------------
-- Special Menu
--------------------------------------------------

DialogTest(
  "Special > Format Disk...",
  function(suffix)
    a2d.ClearSelection()

    -- show dialog
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK - 2)
    test.Snap("Special > Format Disk... - Prompt for drive" .. suffix)

    -- select RAMFactor
    a2d.FormatEraseSelectSlotDrive(1, 1, {no_ok=true})
    test.Snap("Special > Format Disk... - Drive selected" .. suffix)

    -- accept selection
    a2d.DialogOK()
    test.Snap("Special > Format Disk... - Prompt for name" .. suffix)

    -- type new name
    apple2.Type("NEWNAME")
    test.Snap("Special > Format Disk... - Name entered" .. suffix)

    -- accept typed name
    a2d.DialogOK()
    test.Snap("Special > Format Disk... - Confirm erase" .. suffix)

    -- confirm format
    a2d.DialogOK({no_wait=true})
    emu.wait(0.2)
    test.Snap("Special > Format Disk... - Format in progress" .. suffix)
end)

DialogTest(
  "Special > Erase Disk...",
  function(suffix)
    a2d.ClearSelection()

    -- show dialog
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_ERASE_DISK - 2)
    test.Snap("Special > Erase Disk... - Prompt for drive" .. suffix)

    -- select RAMFactor
    a2d.FormatEraseSelectSlotDrive(1, 1, {no_ok=true})
    test.Snap("Special > Erase Disk... - Drive selected" .. suffix)

    -- accept selection
    a2d.DialogOK()
    test.Snap("Special > Erase Disk... - Prompt for name" .. suffix)

    -- type new name
    apple2.Type("NEWNAME")
    test.Snap("Special > Erase Disk... - Name entered" .. suffix)

    -- accept typed name
    a2d.DialogOK()
    test.Snap("Special > Erase Disk... - Confirm erase" .. suffix)

    -- confirm erase
    a2d.DialogOK({no_wait=true})
    emu.wait(0.15)
    test.Snap("Special > Erase Disk... - Erase in progress" .. suffix)
end)

--------------------------------------------------
-- Shortcuts Menu
--------------------------------------------------

local shortcut_added = false

DialogTest(
  "Shortcuts > Add a Shortcut...",
  function(suffix)
    a2d.SelectPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    test.Snap("Shortcuts > Add a Shortcut..." .. suffix)
    a2d.DialogOK()
    shortcut_added = true
end)

DialogTest(
  "Shortcuts > Edit a Shortcut...",
  function(suffix)
    if not shortcut_added then
      a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
      shortcut_added = true
    end

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    test.Snap("Shortcuts > Edit a Shortcut... - Select shortcut" .. suffix)
    apple2.DownArrowKey()
    a2d.DialogOK()
    test.Snap("Shortcuts > Edit a Shortcut... - Editing" .. suffix)
    a2d.DialogCancel()
    a2d.CloseAllWindows()
end)

DialogTest(
  "Shortcuts > Delete a Shortcut...",
  function(suffix)
    if not shortcut_added then
      a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
      shortcut_added = true
    end

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    test.Snap("Shortcuts > Delete a Shortcut..." .. suffix)
    a2d.DialogCancel()
end)

DialogTest(
  "Shortcuts > Run a Shortcut...",
  function(suffix)
    if not shortcut_added then
      a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
      shortcut_added = true
    end

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
    test.Snap("Shortcuts > Run a Shortcut..." .. suffix)
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
  function(suffix)
    a2d.CopyDisk()

    -- "Disk Copy"
    a2d.InvokeMenuItem(3, 2)
    test.Snap("Disk Copy - \"Disk Copy\" option" .. suffix)

    -- "Quick Copy" / select source
    a2d.InvokeMenuItem(3, 1)
    apple2.DownArrowKey() -- S7,D1
    apple2.DownArrowKey() -- S1,D1
    apple2.DownArrowKey() -- S6,D1
    test.Snap("Disk Copy - \"Quick Copy\" option" .. suffix)
    a2d.DialogOK()

    -- select destination
    apple2.DownArrowKey() -- S6,D1
    apple2.DownArrowKey() -- S6,D2
    test.Snap("Disk Copy - Select destination" .. suffix)
    a2d.DialogOK()

    -- insert source
    test.Snap("Disk Copy - Prompt for source" .. suffix)
    a2d.DialogOK()

    -- insert destination
    test.Snap("Disk Copy - Prompt for destination" .. suffix)
    a2d.DialogOK()

    -- confirm erase
    test.Snap("Disk Copy - Confirm erase" .. suffix)
    a2d.DialogOK()

    --[[
      BUG: hit "error during formatting" consistently when using "Disk Copy" here!
      -- Confirmed it is https://github.com/mamedev/mame/issues/14474 ?
      -- Could work around by using System Speed to slow ZIP Chip

      -- formatting
      emu.wait(10)
      test.Snap("Special > Copy Disk..." .. suffix)
      emu.wait(10)
    --]]

    -- reading progress
    emu.wait(0.25)
    test.Snap("Disk Copy - Reading progress" .. suffix)

    -- writing progress
    emu.wait(2)
    test.Snap("Disk Copy - Writing progress" .. suffix)

    -- success
    emu.wait(3)
    test.Snap("Disk Copy - Success" .. suffix)

    -- cleanup
    a2d.DialogOK()
    emu.wait(10) -- scanning drives
    a2d.OAShortcut('Q') -- back to DeskTop
    a2d.WaitForDesktopReady()
    a2dtest.WaitForAlert({match="2 volumes with the same name"})
    a2d.DialogOK()
    local image1 = s6d1.filename
    s6d1:unload()
    a2d.CheckAllDrives()
    emu.wait(15)
    a2d.RenamePath("/FLOPPY1", "Floppy2")
    s6d1:load(image1)
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

DialogTest(
  "Selector",
  function(suffix)
    a2d.ToggleOptionCopyToRAMCard()
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.Reboot()

    -- Launcher: Copying to RAMCard...
    emu.wait(5)
    test.Snap("Selector - Copying app to RAMCard..." .. suffix)
    a2d.WaitForDesktopReady()

    -- Shortcuts dialog
    emu.wait(10) -- let copying finish
    test.Snap("Selector - Shortcuts dialog" .. suffix)

    -- File > Run a Program...
    a2d.OAShortcut('R')
    a2d.WaitForRepaint()
    test.Snap("Selector - Run a Program..." .. suffix)
    a2d.DialogCancel()

    -- Copy to RAMCard...
    apple2.DownArrowKey()
    apple2.ReturnKey()
    emu.wait(2)
    test.Snap("Selector - Copying shortcut to RAMCard..." .. suffix)

    -- cleanup
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady() -- back to Shortcuts
    apple2.Type("D")
    a2d.WaitForDesktopReady() -- back to DeskTop
    a2d.ToggleOptionCopyToRAMCard()
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
