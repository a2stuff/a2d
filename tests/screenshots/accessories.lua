--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 scsi -aux rw3"
DISKARGS="-hard1 out/A2DeskTop-1.6-alpha0-en_800k.2mg -flop1 res/dos33_floppy.dsk"

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

      Dump all the Desk Accessories

    ============================================================]]--

    -- Wait for DeskTop to start
    a2d.WaitForRestart()

    --------------------------------------------------
    -- Apple Menu
    --------------------------------------------------

    function OpenFileTest(name, path)
      test.Step(
        name,
        function()
          a2d.OpenPath(path)
          test.Snap()
          a2d.CloseWindow()
          return test.PASS
      end)
    end

    OpenFileTest("Calendar", "/A2.DESKTOP/APPLE.MENU/CALENDAR")
    OpenFileTest("Calculator", "/A2.DESKTOP/APPLE.MENU/CALCULATOR")
    OpenFileTest("Change Type", "/A2.DESKTOP/APPLE.MENU/CHANGE.TYPE")

    test.Step(
      "Find Files",
      function()
        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/FIND.FILES")
        apple2.Type("C*")
        a2d.DialogOK()
        emu.wait(10)
        test.Snap()
        a2d.CloseWindow()
        return test.PASS
    end)

    OpenFileTest("Key Caps", "/A2.DESKTOP/APPLE.MENU/KEY.CAPS")

    test.Step(
      "Run Basic Here",
      function()
        a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/RUN.BASIC.HERE")
        a2d.WaitForRestart()
        test.Snap()
        apple2.TypeLine("BYE")
        a2d.WaitForRestart()
        return test.PASS
    end)

    --------------------------------------------------
    -- Control Panels
    --------------------------------------------------

    OpenFileTest("Control Panel", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    OpenFileTest("Date & Time", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/DATE.AND.TIME")
    OpenFileTest("International", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/INTERNATIONAL")
    OpenFileTest("Joystick", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/JOYSTICK")
    OpenFileTest("Map", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP")
    OpenFileTest("Options", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    OpenFileTest("Sounds", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SOUNDS")
    OpenFileTest("System Speed", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    OpenFileTest("Views", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/VIEWS")

    --------------------------------------------------
    -- Toys
    --------------------------------------------------

    OpenFileTest("Bounce", "/A2.DESKTOP/APPLE.MENU/TOYS/BOUNCE")
    OpenFileTest("Eyes", "/A2.DESKTOP/APPLE.MENU/TOYS/EYES")
    OpenFileTest("Lights Out", "/A2.DESKTOP/APPLE.MENU/TOYS/LIGHTS.OUT")
    OpenFileTest("Neko", "/A2.DESKTOP/APPLE.MENU/TOYS/NEKO")
    OpenFileTest("Puzzle", "/A2.DESKTOP/APPLE.MENU/TOYS/PUZZLE")

    --------------------------------------------------
    -- Extras
    --------------------------------------------------

    OpenFileTest("Benchmark", "/A2.DESKTOP/EXTRAS/BENCHMARK")
    OpenFileTest("CD Remote", "/A2.DESKTOP/EXTRAS/CD.REMOTE")

    test.Step(
      "DOS 3.3 Import",
      function()
        a2d.OpenPath("/A2.DESKTOP/EXTRAS/DOS33.IMPORT")
        test.Snap("Drive selection")
        apple2.DownArrowKey()
        a2d.DialogOK()
        emu.wait(10) -- DOS 3.3 CATALOG can be slow
        test.Snap("File selection")
        a2d.CloseWindow()
        return test.PASS
    end)

    OpenFileTest("Scientific Calculator", "/A2.DESKTOP/EXTRAS/SCI.CALC")

    os.exit(0)
end)
coroutine.resume(c)
