--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 mouse -sl2 diskiing -sl7 cffa2 -aux ext80"

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

      "Slot 2" tests

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()

    test.Step(
      "Slot 2 can have drive controller",
      function()
        a2d.OpenMenu(a2d.STARTUP_MENU)
        test.Snap("verify Slot 2 is listed")
        return test.PASS
    end)

    --------------------------------------------------

    os.exit(0)
end)
coroutine.resume(c)
