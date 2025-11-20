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

      "Calendar" tests

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()

    test.Step(
      "Calendar - with real-time clock",
      function()
        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALENDAR")
        a2d.WaitForRepaint()
        test.Snap("verify current month and year")
        a2d.CloseWindow()
        return test.PASS
    end)

    test.Step(
      "Calendar - without real-time clock",
      function()
        -- Remove clock driver
        a2d.OpenPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
        a2d.WaitForRestart()
        apple2.TypeLine("DELETE /A2.DESKTOP/CLOCK.SYSTEM")
        apple2.TypeLine("PR#7")
        a2d.WaitForRestart()

        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CALENDAR")
        a2d.WaitForRepaint()
        test.Snap("verify month and year match build")
        a2d.CloseWindow()
        return test.PASS
    end)

    --------------------------------------------------

    os.exit(0)
end)
coroutine.resume(c)
