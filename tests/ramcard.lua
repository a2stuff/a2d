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


    test.Variants(
      {
        "Rename load volume",
        "Rename load volume, copied to RAMCard",
      },
      function(idx)
        if idx == 2 then
          a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
          a2d.OAShortcut("1") -- Enable "Copy to RAMCard"
          a2d.CloseWindow()
          a2d.CloseAllWindows()
          apple2.ControlOAReset()
          a2d.WaitForCopyToRAMCard()
        end

        local folder
        if idx == 1 then
          apple2.Type("A2.DESKTOP")
          folder = ""
        else
          apple2.Type("RAM1")
          folder = "/DESKTOP"
        end

        apple2.ReturnKey()
        apple2.ControlKey("X") -- clear
        apple2.Type("NEWNAME")
        apple2.ReturnKey()



        -- File > Copy To... (overlay)
        a2d.OpenPath("/NEWNAME"..folder)
        apple2.Type("READ.ME")
        a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
        test.Snap("verify copy dialog displayed")
        a2d.DialogCancel()
        a2d.CloseAllWindows()
        a2d.ClearSelection()

        -- Special > Copy Disk (and that File > Quit returns to DeskTop) (overlay + quit handler)
        a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
        a2d.WaitForRestart()
        test.Snap("verify disk copy dialog displayed")
        a2d.OAShortcut("Q")
        a2d.WaitForRestart()

        -- Apple Menu > Calculator (desk accessories)
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CALCULATOR)
        test.Snap("verify Calculator displayed")
        a2d.CloseWindow()

        -- Apple Menu > Control Panels (relative folders)
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
        test.Snap("verify Control Panels folder displayed")
        a2d.CloseWindow()

        -- Control Panel, change desktop pattern, close, quit, restart (settings)
        a2d.OpenPath("/NEWNAME"..folder.."/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
        apple2.LeftArrowKey()
        apple2.ControlKey("D")
        a2d.WaitForRepaint()
        a2d.CloseWindow()
        a2d.CloseAllWindows()
        a2d.OAShortcut("Q")
        apple2.ControlOAReset()
        a2d.WaitForCopyToRAMCard()
        test.Snap("verify desktop pattern changed")

        -- Windows are saved on exit/restored on restart (configuration)
        apple2.Type("NEWNAME")
        apple2.ReturnKey()
        apple2.ControlKey("X") -- clear
        apple2.Type("NEWNAME2")
        apple2.ReturnKey()

        a2d.OpenPath("/NEWNAME2"..folder)
        a2d.SelectAndOpen("SAMPLE.MEDIA")
        a2d.OAShortcut("Q")
        apple2.ControlOAReset()
        a2d.WaitForCopyToRAMCard()
        test.Snap("verify windows restored")
        a2d.CloseAllWindows()

        -- Invoking another application (e.g. `BASIC.SYSTEM`), then quitting back to DeskTop (quit handler)
        apple2.Type("NEWNAME2")
        apple2.ReturnKey()
        apple2.ControlKey("X") -- clear
        apple2.Type("NEWNAME3")
        apple2.ReturnKey()

        a2d.OpenPath("/NEWNAME3"..folder.."/EXTRAS/BASIC.SYSTEM")
        a2d.WaitForRestart()
        apple2.TypeLine("BYE")
        a2d.WaitForRestart()
        test.Snap("verify desktop restarted")

        -- Modifying shortcuts (selector)
        a2d.OpenPath("/NEWNAME3"..folder.."/EXTRAS")
        apple2.Type("BASIC.SYSTEM")
        a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
        a2d.WaitForRepaint()
        a2d.DialogOK()
        a2d.WaitForRepaint()
        apple2.ControlOAReset()
        a2d.WaitForCopyToRAMCard()
        a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
        a2d.WaitForRepaint()
        test.Snap("verify shortcut persisted")
        a2d.DialogCancel()
        a2d.WaitForRepaint()

        -- clean up after test
        a2d.OpenPath("/NEWNAME3"..folder.."/EXTRA/BASIC.SYSTEM")
        a2d.WaitForRestart()
        if idx == 1 then
          apple2.TypeLine("RENAME /NEWNAME3,/A2.DESKTOP")
        else
          apple2.TypeLine("RENAME /NEWNAME3,/RAM1")
        end
        apple2.TypeLine("DELETE /A2.DESKTOP/LOCAL/DESKTOP.CONFIG")
        apple2.TypeLine("DELETE /A2.DESKTOP/LOCAL/DESKTOP.FILE")
        apple2.TypeLine("DELETE /A2.DESKTOP/LOCAL/QUIT.TMP")
        apple2.TypeLine("DELETE /A2.DESKTOP/LOCAL/SELECTOR.LIST")
        apple2.ControlOAReset()
        a2d.WaitForRestart()
    end)


    --------------------------------------------------

    os.exit(0)
end)
coroutine.resume(c)
