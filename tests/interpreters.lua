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
      "Applesoft BASIC",
      function()
        a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/HELLO.WORLD")
        emu.wait(2)
        test.Snap()
        apple2.ControlOAReset()
        a2d.WaitForRestart()
        return test.PASS
    end)

    test.Step(
      "Integer BASIC",
      function()
        a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/APPLEVISION")
        emu.wait(5)
        apple2.ReturnKey()
        emu.wait(15)
        test.Snap()
        apple2.ControlOAReset()
        a2d.WaitForRestart()
        return test.PASS
    end)

    test.Step(
      "S.A.M.",
      function()
        a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/EMERGENCY")
        emu.wait(5)
        test.Snap()
        apple2.ControlOAReset()
        a2d.WaitForRestart()
        return test.PASS
    end)

    test.Step(
      "PT3",
      function()
        a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/AUTUMN.PT3")
        emu.wait(5)
        test.Snap()
        apple2.ControlOAReset()
        a2d.WaitForRestart()
        return test.PASS
    end)

    -- TODO: AW
    -- TODO: Unshrink
    -- TODO: BinSCII

    os.exit(0)
end)
coroutine.resume(c)
