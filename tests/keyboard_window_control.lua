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
      "Move window with keyboard - cancelled",
      function()
        a2d.OpenPath("A2.DESKTOP")
        a2d.WaitForRepaint()

        a2d.OAShortcut("M")
        for i=1,3 do
          apple2.RightArrowKey()
          apple2.DownArrowKey()
        end
        apple2.EscapeKey()
        test.Snap("should not have moved")
        return test.PASS
    end)

    test.Step(
      "Move window with keyboard",
      function()
        a2d.OpenPath("A2.DESKTOP")
        a2d.WaitForRepaint()

        a2d.OAShortcut("M")
        for i=1,3 do
          apple2.RightArrowKey()
          apple2.DownArrowKey()
        end
        apple2.ReturnKey()
        a2d.WaitForRepaint()
        test.Snap("should have moved right and down")
        return test.PASS
    end)

    test.Step(
      "Resize window with keyboard - cancelled",
      function()
        a2d.OpenPath("A2.DESKTOP")
        a2d.WaitForRepaint()

        a2d.OAShortcut("G")
        for i=1,3 do
          apple2.RightArrowKey()
          apple2.DownArrowKey()
        end
        apple2.EscapeKey()
        test.Snap("should not have resized")
        return test.PASS
    end)

    test.Step(
      "Resize window with keyboard",
      function()
        a2d.OpenPath("A2.DESKTOP")
        a2d.WaitForRepaint()

        a2d.OAShortcut("G")
        for i=1,3 do
          apple2.RightArrowKey()
          apple2.DownArrowKey()
        end
        apple2.ReturnKey()
        a2d.WaitForRepaint()
        test.Snap("should have resized")
        return test.PASS
    end)

    os.exit(0)
end)
coroutine.resume(c)
