--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

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

      "Run Basic Here" tests

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()

    test.Step(
      "/RAM exists",
      function()
        a2d.OpenPath("/A2.DESKTOP")
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
        a2d.WaitForRestart()
        apple2.TypeLine("CAT /RAM")
        emu.wait(1)
        test.Expect(apple2.GrabTextScreen():match("BLOCKS FREE"), "/RAM should exist")
        apple2.TypeLine("BYE")
        a2d.WaitForRestart()
        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "PREFIX set correctly",
      function()
        a2d.OpenPath("/TESTS")
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
        a2d.WaitForRestart()
        apple2.TypeLine("PREFIX")
        emu.wait(1)
        test.Expect(apple2.GrabTextScreen():match("/TESTS/"), "Prefix should be /TESTS/")
        apple2.TypeLine("BYE")
        a2d.WaitForRestart()
        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "Copied to RAMCard",
      function()
        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
        a2d.OAShortcut("1") -- Enable "Copy to RAMCard"
        a2d.CloseWindow()
        a2d.CloseAllWindows()
        a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1) -- reboot (slot 7)
        a2d.WaitForCopyToRAMCard()

        a2d.OpenPath("/TESTS")
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
        a2d.WaitForRestart()
        test.Expect(apple2.GrabTextScreen():match("PRODOS BASIC"), "BASIC should start")
        return test.PASS
    end)

    --------------------------------------------------

    os.exit(0)
end)
coroutine.resume(c)
