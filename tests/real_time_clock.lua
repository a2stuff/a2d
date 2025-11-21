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

      "Real-Time Clock" tests

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()

    test.Step(
      "Clock appears in top right",
      function()
        test.Snap("verify clock is in top-right of screen")
    end)

    test.Step(
      "Clock paints correctly after volume selected",
      function()
        apple2.Type("A2.DESKTOP")
        emu.wait(10)
        test.Snap("verify clock is in top-right of screen")
    end)

    --------------------------------------------------

    os.exit(0)
end)
coroutine.resume(c)
