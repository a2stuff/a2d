--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

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

      "RAMCard" tests (poor naming)

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()


    function RenameTest(name, proc)
      test.Variants(
      {
        name .. " - Not copied to RAMCard, rename load volume",
        name .. " - Copied to RAMCard, rename load volume",
        name .. " - Copied to RAMCard, rename load folder",

        -- Not ready yet:
        --name .. " - Not copied to RAMCard, rename load folder",
      },
      function(idx)

        -- configure
        if idx == 2 or idx == 3 then
          a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
          a2d.OAShortcut("1") -- Enable "Copy to RAMCard"
          a2d.CloseWindow()
          a2d.CloseAllWindows()
          a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1) -- slot 7
          a2d.WaitForCopyToRAMCard()
        end

        -- setup
        local dtpath
        if idx == 1 then
          a2d.RenamePath("/A2.DESKTOP", "NEWNAME")
          dtpath = "/NEWNAME"
        elseif idx == 2 then
          a2d.RenamePath("/RAM1", "NEWNAME")
          dtpath = "/NEWNAME/DESKTOP"
        elseif idx == 3 then
          a2d.RenamePath("/RAM1/DESKTOP", "NEWNAME")
          dtpath = "/RAM1/NEWNAME"
        elseif idx == 4 then
          -- TODO: Revise me!
          a2d.RenamePath("/EMPTY/A2.DESKTOP", "NEWNAME")
          dtpath = "/EMPTY/NEWNAME"
        else
          error("NYI")
        end

        a2d.CloseAllWindows()
        a2d.ClearSelection()

        proc(dtpath)

        a2d.CloseAllWindows()
        a2d.ClearSelection()

        -- cleanup

        if idx == 1 then
          a2d.RenamePath("/NEWNAME", "A2.DESKTOP")
        elseif idx == 2 then
          a2d.RenamePath("/NEWNAME", "/RAM1")
          a2d.EraseVolume("RAM1")
        elseif idx == 3 then
          a2d.EraseVolume("RAM1")
        elseif idx == 4 then
          -- TODO: Anything?
        else
          error("NYI")
        end
        a2d.DeletePath("/A2.DESKTOP/LOCAL")
        a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1) -- slot 7
        a2d.WaitForRestart()
        return test.PASS
      end)
    end



    --[[
        elseif idx == 4 then
          -- Copy to /RAM1 temporarily
          a2d.SelectPath("/A2.DESKTOP")
          a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO - 4)
          apple2.ControlKey("D") -- Drives
          emu.wait(10) -- empty floppies
          apple2.Type("RAM1")
          a2d.DialogOK() -- confirm copy
          emu.wait(80) -- copy is slow

          -- Switch to temporary copy
          a2d.OpenPath("/RAM1/A2.DESKTOP/DESKTOP.SYSTEM")
          a2d.WaitForRestart()

          -- Delete original
          a2d.OpenPath("/A2.DESKTOP")
          a2d.OAShortcut("A") -- Select All
          a2d.OADelete()
          emu.wait(20) -- wait for enumeration
          a2d.DialogOK() -- confirm delete
          emu.wait(80) -- delete is slow

          -- Copy to folder on original disk
          a2d.SelectPath("/RAM1/A2.DESKTOP")
          a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
          apple2.ControlKey("D") -- Drives
          emu.wait(10) -- empty floppies
          apple2.Type("A2.DESKTOP")
          a2d.DialogOK() -- confirm delete
          emu.wait(80) -- copy is slow

          -- Make disk bootable
          a2d.SelectPath("/RAM1/A2.DESKTOP/PRODOS")
          a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
          apple2.ControlKey("D") -- Drives
          emu.wait(10) -- empty floppies
          apple2.Type("A2.DESKTOP")
          a2d.DialogOK() -- confirm delete

          -- Now how do we actually restart each time?
    ]]--

    RenameTest(
      "overlays",
      function(dtpath)
        -- File > Copy To...
        a2d.SelectPath(dtpath.."/READ.ME")
        a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
        test.Snap("verify copy dialog displayed")
        a2d.DialogCancel()
    end)

    RenameTest(
      "overlay + quit handler",
      function(dtpath)
        -- Special > Copy Disk
        a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
        a2d.WaitForRestart()
        test.Snap("verify disk copy dialog displayed")
        -- File > Quit returns to DeskTop
        a2d.OAShortcut("Q")
        a2d.WaitForRestart()
    end)

    RenameTest(
      "desk accessories",
      function(dtpath)
        -- Apple Menu > Calculator
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CALCULATOR)
        test.Snap("verify Calculator displayed")
        a2d.CloseWindow()
    end)

    RenameTest(
      "relative folders",
      function(dtpath)
        -- Apple Menu > Control Panels
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
        test.Snap("verify Control Panels folder displayed")
    end)

    RenameTest(
      "settings",
      function(dtpath)
        -- Control Panel, change desktop pattern, close, quit, restart
        a2d.OpenPath(dtpath.."/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
        apple2.LeftArrowKey()
        apple2.ControlKey("D")
        a2d.WaitForRepaint()
        a2d.CloseWindow()

        a2d.OpenPath(dtpath.."/DESKTOP.SYSTEM")
        a2d.WaitForCopyToRAMCard()

        test.Snap("verify desktop pattern changed")
    end)

    RenameTest(
      "configuration",
      function(dtpath)
        -- Windows are saved on exit/restored on restart
        a2d.OpenPath(dtpath.."/DESKTOP.SYSTEM")
        a2d.WaitForCopyToRAMCard()
        test.Snap("verify windows restored")
    end)

    RenameTest(
      "quit handler",
      function(dtpath)
        -- Invoking another application (e.g. `BASIC.SYSTEM`)
        -- then quitting back to DeskTop (quit handler)
        a2d.OpenPath(dtpath.."/EXTRAS/BASIC.SYSTEM")
        a2d.WaitForRestart()
        apple2.TypeLine("BYE")
        a2d.WaitForRestart()
        test.Snap("verify desktop restarted")
    end)

    RenameTest(
      "selector file",
      function(dtpath)
        -- Modifying shortcuts (selector)
        a2d.OpenPath(dtpath.."/EXTRAS")
        apple2.Type("BASIC.SYSTEM")
        a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
        a2d.WaitForRepaint()
        a2d.DialogOK()
        a2d.WaitForRepaint()

        a2d.OpenPath(dtpath.."/DESKTOP.SYSTEM")
        a2d.WaitForCopyToRAMCard()

        a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
        a2d.WaitForRepaint()
        test.Snap("verify shortcut persisted")
        a2d.DialogCancel()
        a2d.WaitForRepaint()
    end)

    --------------------------------------------------

    os.exit(0)
end)
coroutine.resume(c)
