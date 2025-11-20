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

      Preview Accessories

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()

    test.Step(
      "Image Preview",
      function()
        a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
        emu.wait(5) -- file load
        test.Snap()
        apple2.EscapeKey()
        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "Electric Duet Preview",
      function()
        a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/JESU.JOY")
        test.Snap()
        apple2.EscapeKey()
        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "Font Preview",
      function()
        a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/FONTS/MONACO.EN")
        test.Snap()
        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "Text Preview",
      function()
        a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM")
        test.Snap()
        apple2.Type(" ")
        a2d.WaitForRepaint()
        test.Snap()
        apple2.EscapeKey()
        a2d.CloseAllWindows()
        return test.PASS
    end)

    os.exit(0)
end)
coroutine.resume(c)
