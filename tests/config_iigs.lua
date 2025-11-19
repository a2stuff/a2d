--[[ BEGINCONFIG ========================================

MODEL="apple2gsr0"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 out/A2DeskTop-1.6-alpha0-en_800k.2mg"
RESOLUTION="704x462"

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
    a2d.InitSystem()

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
        test.ExpectEquals(apple2.ReadRAMDevice(0x2000+40), 0x55, "DHR access")
        test.ExpectEquals(apple2.ReadRAMDevice(0x12000+40), 0x2A, "DHR access")
        return test.PASS
    end)

    os.exit(0)
end)
coroutine.resume(c)
