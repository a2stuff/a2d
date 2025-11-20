--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ssc -sl2 mouse -sl5 ramfactor -sl7 cffa2 -aux rw3"
DISKARGS="-hard1 out/A2DeskTop-1.6-alpha0-en_800k.2mg"

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

      Test Script

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()

    test.Step(
      "Apple > About This Apple II",
      function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
        test.Snap()
        a2d.CloseWindow()
        return test.PASS
    end)

    os.exit(0)
end)
coroutine.resume(c)
