--[[ BEGINCONFIG ========================================

MODEL="ace2200"
MODELARGS="-sl2 mouse -sl7 cffa2"
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

      Test Script

    ============================================================]]--

    -- ACE 2200 does not auto-start with anythng but floppies
    emu.wait(1)
    apple2.ControlReset()
    apple2.TypeLine("PR#7")

    -- Wait for DeskTop to start
    a2d.WaitForRestart()
    emu.wait(5) -- slow floppy drives

    test.Step(
      "Apple > About This Apple II",
      function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
        emu.wait(5) -- slow floppy drives
        test.Snap()
        a2d.CloseWindow()
        test.ExpectEquals(apple2.ReadRAMDevice(0x2000+40), 0x55, "DHR access")
        test.ExpectEquals(apple2.ReadRAMDevice(0x12000+40), 0x2A, "DHR access")
        return test.PASS
    end)

    os.exit(0)
end)
coroutine.resume(c)
