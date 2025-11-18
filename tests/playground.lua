--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl7 cffa2 -aux ext80"
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
      "Sample Media",
      function()
        a2d.SelectAndOpen("A2.DESKTOP")
        a2d.SelectAndOpen("SAMPLE.MEDIA")
        test.Snap("Sample Media")

        -- Change window size
        a2d.OAShortcut("G")
        apple2.RightArrowKey()
        apple2.RightArrowKey()
        apple2.RightArrowKey()
        apple2.RightArrowKey()
        apple2.ReturnKey()
        a2d.WaitForRepaint()
        test.Snap("Changed window size")

        -- Open MONARCH (image preview)
        a2d.SelectAndOpen("MONARCH")
        emu.wait(5) -- load big file
        test.Snap("Image preview")
        apple2.EscapeKey()
        a2d.WaitForRepaint()
        test.Snap("Back to desktop")
        return test.PASS
    end)

    test.Step(
      "Move Mouse",
      function()
        -- Move the mouse
        apple2.MoveMouse(480, 170)
        test.Snap("Mouse to 480,170")

        -- Move the mouse
        apple2.MoveMouse(0, 0)
        test.Snap("Mouse to 0,0")
        return test.PASS
    end)

    apple2.DumpReadableStates()

    os.exit(0)
end)
coroutine.resume(c)
