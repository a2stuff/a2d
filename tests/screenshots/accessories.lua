--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 scsi"
DISKARGS="-hard1 $HARDIMG -flop1 dos33_floppy.dsk"

======================================== ENDCONFIG ]]

--[[============================================================

  Dump all the Desk Accessories

  ============================================================]]

a2d.ConfigureRepaintTime(1)

--------------------------------------------------
-- Apple Menu
--------------------------------------------------

function OpenFileTest(name, path)
  test.Step(
    name,
    function()
      a2d.OpenPath(path)
      test.Snap(name)
      a2d.CloseWindow()
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
    test.Snap("Find Files")
    a2d.CloseWindow()
end)

OpenFileTest("Key Caps", "/A2.DESKTOP/APPLE.MENU/KEY.CAPS")

test.Step(
  "Run Basic Here",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/RUN.BASIC.HERE")
    apple2.WaitForBasicSystem()
    test.Snap("Run Basic Here")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
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
    emu.wait(5)
    test.Snap("Drive selection")
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(10) -- DOS 3.3 CATALOG can be slow
    test.Snap("File selection")
    a2d.CloseWindow()
end)

OpenFileTest("Scientific Calculator", "/A2.DESKTOP/EXTRAS/SCI.CALC")

