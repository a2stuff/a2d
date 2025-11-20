--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 scsi -aux rw3"
DISKARGS="-hard1 $HARDIMG -flop1 res/prodos_floppy1.dsk -flop2 res/prodos_floppy2.dsk"
RESOLUTION="560x384"

======================================== ENDCONFIG ]]--

package.path = emu.subst_env("$LUA_PATH") .. ";" .. package.path

-- Run in an async context
local c = coroutine.create(function()
    emu.wait(1/60) -- allow logging to get ready

    -- "Globals"
    local machine = manager.machine

    -- Dependencies
    local test = require("test")
    local apple2 = require("apple2")
    local a2d = require("a2d")
    a2d.InitSystem() -- async; outside require

    --[[============================================================

      Dump all the dialogs

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()

    --------------------------------------------------
    -- Apple Menu
    --------------------------------------------------

    test.Step(
      "Apple > About Apple II DeskTop",
      function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_APPLE_II_DESKTOP)
        test.Snap()
        a2d.CloseWindow()
        return test.PASS
    end)

    test.Step(
      "Apple > About This Apple II",
      function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
        test.Snap()
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
        test.Snap()
        a2d.DialogCancel()
        return test.PASS
    end)

    test.Step(
      "File > Get Info (file)",
      function()
        a2d.SelectAndOpen("A2.DESKTOP")
        apple2.Type("READ.ME")
        a2d.OAShortcut("I")
        test.Snap()
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
        test.Snap()
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
        test.Snap("Prompt for drive")

        -- select RAMFactor
        apple2.DownArrowKey() -- S7D1
        apple2.DownArrowKey() -- S7D2
        apple2.DownArrowKey() -- S1D1
        test.Snap("Drive selected")

        -- accept selection
        a2d.DialogOK()
        test.Snap("Prompt for name")

        -- type new name
        apple2.Type("NEWNAME")
        test.Snap("Name entered")

        -- accept typed name
        a2d.DialogOK()
        test.Snap("Confirm erase")

        -- confirm format
        apple2.ReturnKey() -- not a2d.DialogOK() because usual wait is too ong
        test.Snap("Format in progress")

        return test.PASS
    end)

    test.Step(
      "Special > Erase Disk...",
      function()
        a2d.ClearSelection()

        -- show dialog
        a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_ERASE_DISK - 2)
        test.Snap("Prompt for drive")

        -- select RAMFactor
        apple2.DownArrowKey() -- S7D1
        apple2.DownArrowKey() -- S7D2
        apple2.DownArrowKey() -- S1D1
        test.Snap("Drive selected")

        -- accept selection
        a2d.DialogOK()
        test.Snap("Prompt for name")

        -- type new name
        apple2.Type("NEWNAME")
        test.Snap("Name entered")

        -- accept typed name
        a2d.DialogOK()
        test.Snap("Confirm erase")

        -- confirm erase
        apple2.ReturnKey() -- not a2d.DialogOK() because usual wait is too ong
        test.Snap("Erase in progress")

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
        test.Snap()
        a2d.OAShortcut('4') -- copy to RAMCard / on first use
        a2d.DialogOK()
        return test.PASS
    end)

    test.Step(
      "Shortcuts > Edit a Shortcut...",
      function()
        a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
        test.Snap("Select shortcut")
        apple2.DownArrowKey()
        a2d.DialogOK()
        test.Snap("Editing")
        a2d.DialogCancel()
        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "Shortcuts > Delete a Shortcut...",
      function()
        a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
        test.Snap()
        a2d.DialogCancel()
        return test.PASS
    end)

    test.Step(
      "Shortcuts > Run a Shortcut...",
      function()
        a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
        test.Snap()
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
        test.Snap()
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
        test.Snap("\"Disk Copy\" option")

        -- "Quick Copy" / select source
        a2d.InvokeMenuItem(3, 1)
        apple2.DownArrowKey()
        apple2.DownArrowKey()
        apple2.DownArrowKey()
        apple2.DownArrowKey()
        test.Snap()
        a2d.DialogOK("\"Quick Copy\" option")

        -- select destination
        apple2.DownArrowKey()
        apple2.DownArrowKey()
        test.Snap("Select destination")
        a2d.DialogOK()

        -- insert source
        test.Snap("Prompt for source")
        a2d.DialogOK()

        -- insert destination
        test.Snap("Prompt for destination")
        a2d.DialogOK()

        -- confirm erase
        test.Snap("Confirm erase")
        a2d.DialogOK()

        --[[
          BUG: hit "error during formatting" consistently when using "Disk Copy" here!
          -- Even in "Quick Copy" the result is success by drive name is "Unknown" on return
          -- does not repro normally; timing issue? https://github.com/mamedev/mame/issues/14474 ?

        -- formatting
        emu.wait(10)
        test.Snap()
        emu.wait(10)
        --]]

        -- reading progress
        emu.wait(0.25)
        test.Snap("Reading progress")

        -- writing progress
        emu.wait(2)
        test.Snap("Writing progress")

        -- success
        emu.wait(3)
        test.Snap("Success")

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
        test.Snap("Copying app to RAMCard...")

        -- Shortcuts dialog
        emu.wait(10) -- let copying finish
        test.Snap("Shortcuts dialog")

        -- File > Run a Program...
        a2d.OAShortcut('R')
        a2d.WaitForRepaint()
        test.Snap("Run a Program...")
        a2d.DialogCancel()

        -- Copy to RAMCard...
        apple2.DownArrowKey()
        apple2.ReturnKey()
        emu.wait(2)
        test.Snap("Copying shortcut to RAMCard...")

        return test.PASS
    end)

    --------------------------------------------------

    os.exit(0)
end)
coroutine.resume(c)
