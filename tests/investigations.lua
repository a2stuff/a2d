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

      Miscellaneous investigations

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()

    test.Step(
      "Verify keyboard shortcuts option doesn't get enabled by reset (in MAME)",
      function()
        --[[
        If MGTK can't find the mouse, DeskTop turns on keyboard
        shortcuts (to be helpful) So this is a signal that after a
        hard reset (Control-OA-Reset), MAME sometimes is in a state
        where MGKT can't find the mouse. Is this an emulator issue or
        real bug? Is there some firmware banking that needs fixing?
        ]]--

        apple2.ControlOAReset()
        a2d.WaitForRestart()
        a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
        test.Snap("keyboard shortcuts should not be enabled")
        return test.PASS
    end)

    --------------------------------------------------

    os.exit(0)
end)
coroutine.resume(c)
