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

      "Screen Savers" tests

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()

    test.Step(
      "Melt - File > Open does not leave File menu highlighted",
      function()
        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS")
        apple2.Type("MELT")
        a2d.OAShortcut("O")
        emu.wait(1)

        a2d.EnterMouseKeysMode()
        a2d.MouseKeysClick()
        a2d.ExitMouseKeysMode()
        a2d.WaitForRepaint()

        for i = 1,39 do
          test.ExpectEquals(apple2.ReadRAMDevice(0x2000+i), 0x7F, "Menu should not be highlighted")
        end
        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "Melt - Apple-Down does not leave File menu highlighted",
      function()
        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS")
        apple2.Type("MELT")

        a2d.OADown()
        emu.wait(1)

        a2d.EnterMouseKeysMode()
        a2d.MouseKeysClick()
        a2d.ExitMouseKeysMode()
        a2d.WaitForRepaint()

        for i = 1,39 do
          test.ExpectEquals(apple2.ReadRAMDevice(0x2000+i), 0x7F, "Menu should not be highlighted")
        end
        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "Clock redraws immediately",
      function()
        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS")
        apple2.Type("MELT")
        a2d.OAShortcut("O")
        emu.wait(1)

        apple2.EscapeKey()
        apple2.ControlKey('@') -- no-op, wait for key to be consumed

        test.ExpectNotEquals(apple2.GetHiresByte(4, 38), 0x7F, "Clock should be visible already")

        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "Matrix exits on click",
      function()
        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MATRIX")
        emu.wait(1)

        a2d.EnterMouseKeysMode()
        a2d.MouseKeysClick()
        a2d.ExitMouseKeysMode()
        a2d.WaitForRepaint()

        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "Matrix exits on key",
      function()
        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MATRIX")
        emu.wait(1)

        apple2.ReturnKey()

        a2d.CloseAllWindows()
        return test.PASS
    end)

    function RemoveClockDriver()
      a2d.OpenPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
      a2d.WaitForRestart()
      apple2.TypeLine("DELETE /A2.DESKTOP/CLOCK.SYSTEM")
      apple2.TypeLine("PR#7")
      a2d.WaitForRestart()
    end


    test.Step(
      "Analog Clock shows alert if there is no system clock",
      function()
        RemoveClockDriver()

        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/ANALOG.CLOCK")
        test.Snap()
        a2d.DialogOK()
        a2d.CloseAllWindows()
        return test.PASS
    end)

    test.Step(
      "Digital Clock shows alert if there is no system clock",
      function()
        RemoveClockDriver()

        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/DIGITAL.CLOCK")
        test.Snap()
        a2d.DialogOK()
        a2d.CloseAllWindows()
        return test.PASS
    end)

    --------------------------------------------------

    os.exit(0)
end)
coroutine.resume(c)
