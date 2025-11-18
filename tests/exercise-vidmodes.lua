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
      "Cycle video modes",
      function()
        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS/EYES")
        apple2.SetMonitorType(apple2.MONITOR_TYPE_COLOR)
        test.Snap("Color")
        apple2.SetMonitorType(apple2.MONITOR_TYPE_AMBER)
        test.Snap("Amber")
        apple2.SetMonitorType(apple2.MONITOR_TYPE_GREEN)
        test.Snap("Green")
        apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)
        test.Snap("Video-7")
        return test.PASS
    end)

    os.exit(0)
end)
coroutine.resume(c)
