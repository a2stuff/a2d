--[[ BEGINCONFIG ========================================

MODELARGS="-ramsize 1152K -gameio joy"
DISKARGS="-flop1 $FLOP1IMG -flop2 $FLOP2IMG"

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

      "System Speed" tests

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()
    emu.wait(50) -- floppy drives are slow

    test.Step(
      "Normal + OK doesn't crash",
      function()
        a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
        emu.wait(5) -- floppy drives are slow
        apple2.Type("N")
        a2d.DialogOK()
        a2d.CloseAllWindows()
        -- TODO: Expect still running
        return test.PASS
    end)

    test.Step(
      "Fast + OK doesn't crash",
      function()
        a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
        emu.wait(5) -- floppy drives are slow
        apple2.Type("F")
        a2d.DialogOK()
        a2d.CloseAllWindows()
        -- TODO: Expect still running
        return test.PASS
    end)

    test.Step(
      "IIc - speed doesn't affect DHR display",
      function()
        a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
        emu.wait(5) -- floppy drives are slow
        apple2.Type("N")
        apple2.Type("F")
        test.Expect(apple2.ReadSSW("RDDHIRES") < 128, "Should still be in DHR mode")
        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "Animation shields cursor correctly",
      function()
        a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
        emu.wait(5) -- floppy drives are slow
        a2d.InMouseKeysMode(function(m)
            m.GoToApproximately(115,124)
            for i=1,15 do
              m.Up(2)
              emu.wait(0.15)
              test.Snap("visually confirm no garbage")
              m.Down(2)
              emu.wait(0.15)
              test.Snap("visually confirm no garbage")
            end
            a2d.CloseAllWindows()
        end)
        return test.PASS
    end)


    --------------------------------------------------

    os.exit(0)
end)
coroutine.resume(c)
