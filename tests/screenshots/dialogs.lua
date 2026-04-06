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
    },
    function(idx, name, suffix, flags)
      if flags.shortcuts then
        a2d.ToggleOptionShowKeyboardShortcuts()
      end

      func(suffix)

      if flags.shortcuts then
        a2d.ToggleOptionShowKeyboardShortcuts()
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
-- File Operations
--------------------------------------------------

DialogTest(
  "Copy Progress",
  function(suffix)
    a2d.CopyPath("/A2.DESKTOP/APPLE.MENU", "/RAM1", {no_wait=true})
    emu.wait(5)
    test.Snap("Copy Progress" .. suffix)
    a2d.DialogCancel()
    a2d.CloseAllWindows()
    a2d.EraseVolume("RAM1")
end)

DialogTest(
  "Move Progress",
  function(suffix)
    a2d.CopyPath("/A2.DESKTOP/APPLE.MENU", "/RAM1")
    emu.wait(5)
    a2d.CreateFolder("/RAM1/DESTINATION")
    a2d.OpenPath("/RAM1/DESTINATION")
    a2d.MoveWindowBy(300, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w/2, y + h/2

    a2d.OpenPath("/RAM1/APPLE.MENU", {keep_windows=true})
    a2d.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(1)
    test.Snap("Move Progress" .. suffix)
    a2d.DialogCancel()
    a2d.CloseAllWindows()
    a2d.EraseVolume("RAM1")
end)

DialogTest(
  "Copy Overwrite Prompt",
  function(suffix)
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2dtest.WaitForAlert({match="already exists"})
    test.Snap("Copy Overwrite Prompt" .. suffix)
    a2d.DialogCancel()
    a2d.CloseAllWindows()
    a2d.EraseVolume("RAM1")
end)

DialogTest(
  "Delete",
  function(suffix)
    -- Copy files, so we get a good progress bar
    a2d.CopyPath("/A2.DESKTOP/APPLE.MENU", "/RAM1")
    emu.wait(5)

    -- Copy a file and lock it
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    emu.wait(1)
    a2d.SelectPath("/RAM1/READ.ME")
    a2d.OAShortcut("I") -- File > Get Info
    a2d.WaitForRepaint()
    apple2.ControlKey("L")
    a2d.DialogOK()

    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    a2d.OADelete() -- File > Delete
    a2dtest.WaitForAlert({match="Are you sure"})
    test.Snap("Delete Confirm" .. suffix)
    a2d.DialogOK()

    emu.wait(1)
    test.Snap("Delete Progress" .. suffix)
    a2dtest.WaitForAlert({match="file is locked"})
    test.Snap("Delete Confirm Locked" .. suffix)

    a2d.DialogCancel()
    a2d.CloseAllWindows()
    a2d.EraseVolume("RAM1")
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

    -- cleanup
    emu.wait(5)
    a2d.RenamePath("/NEWNAME", "RAM1")

    -- Formatting error
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK - 2)
    local disk = s6d1.filename
    s6d1:unload()
    a2d.FormatEraseSelectSlotDrive(6, 1, {no_ok=true})
    a2d.DialogOK() -- accept device selection
    apple2.Type("NEWNAME")
    a2d.DialogOK() -- accept name
    a2d.DialogOK() -- confirm erase
    a2dtest.WaitForAlert({match="error"})
    test.Snap("Special > Format Disk... - Format Error" .. suffix)
    s6d1:load(disk)
    a2d.DialogCancel()
    emu.wait(5)

    -- cleanup
    a2d.CheckAllDrives()
    emu.wait(5)
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

    -- cleanup
    emu.wait(5)
    a2d.RenamePath("/NEWNAME", "RAM1")

    -- Erasing error
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_ERASE_DISK - 2)
    local disk = s6d1.filename
    s6d1:unload()
    a2d.FormatEraseSelectSlotDrive(6, 1, {no_ok=true})
    a2d.DialogOK() -- accept device selection
    apple2.Type("NEWNAME")
    a2d.DialogOK() -- accept name
    a2d.DialogOK() -- confirm erase
    a2dtest.WaitForAlert({match="error"})
    test.Snap("Special > Erase Disk... - Erase Error" .. suffix)
    s6d1:load(disk)
    a2d.DialogCancel()
    emu.wait(5)

    -- cleanup
    a2d.CheckAllDrives()
    emu.wait(5)
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
    test.Snap("Disk Copy - \"Quick Copy\" option" .. suffix)

    -- Use "Disk Copy" so we get Formatting in there
    a2d.InvokeMenuItem(3, 2)

    apple2.DownArrowKey() -- S7,D1
    apple2.DownArrowKey() -- S1,D1
    apple2.DownArrowKey() -- S6,D1
    a2d.DialogOK()

    -- select destination
    apple2.DownArrowKey() -- S6,D1
    apple2.DownArrowKey() -- S6,D2
    test.Snap("Disk Copy - Select destination" .. suffix)
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert({match="Insert the source"})
    test.Snap("Disk Copy - Prompt for source" .. suffix)
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert({match="Insert the destination"})
    test.Snap("Disk Copy - Prompt for destination" .. suffix)
    a2d.DialogOK()

    -- confirm erase
    a2dtest.WaitForAlert({match="Are you sure"})
    test.Snap("Disk Copy - Confirm erase" .. suffix)
    a2d.DialogOK()

    local bounds = {x1=130, y1=75, x2=470, y2=100}

    -- formatting
    util.WaitFor(
      "formatting", function()
        return a2dtest.OCRScreen(bounds):match("Formatting")
    end)
    test.Snap("Disk Copy - Formatting" .. suffix)

    -- reading progress
    util.WaitFor(
      "reading", function()
        return a2dtest.OCRScreen(bounds):match("Reading")
    end)
    emu.wait(10)
    test.Snap("Disk Copy - Reading progress" .. suffix)

    -- writing progress
    util.WaitFor(
      "writing", function()
        return a2dtest.OCRScreen(bounds):match("Writing")
    end)
    emu.wait(10)
    test.Snap("Disk Copy - Writing progress" .. suffix)

    -- success
    a2dtest.WaitForAlert({match="successful", timeout=3600})
    test.Snap("Disk Copy - Success" .. suffix)
    a2d.DialogOK()
    emu.wait(5)

    -- "Quick Copy"
    a2d.InvokeMenuItem(3, 1) -- Options > Quick Copy
    apple2.DownArrowKey() -- S7,D1
    apple2.DownArrowKey() -- S1,D1
    apple2.DownArrowKey() -- S6,D1
    a2d.DialogOK()
    apple2.DownArrowKey() -- S6,D1
    apple2.DownArrowKey() -- S6,D2
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="Insert the source"})
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="Insert the destination"})
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()
    emu.wait(1)
    apple2.EscapeKey()
    a2dtest.WaitForAlert({match="not completed"})
    test.Snap("Disk Copy - Failure" .. suffix)
    a2d.DialogOK()

    -- cleanup
    emu.wait(10) -- scanning drives
    a2d.OAShortcut('Q') -- back to DeskTop
    a2d.WaitForDesktopReady()
    a2dtest.WaitForAlert() -- 2 volumes with the same name (not 'match' for running localized)
    a2d.DialogOK()
    local image1 = s6d1.filename
    s6d1:unload()
    a2d.CheckAllDrives()
    emu.wait(15)
    a2d.RenamePath("/FLOPPY1", "FLOPPY2")
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
    apple2.WaitForBasicSystem({timeout=120})
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
