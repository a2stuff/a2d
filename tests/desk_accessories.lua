test.Step(
  "File > Open works",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU")
    a2d.Select("CALCULATOR")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN)
    test.Snap("DA opened")
    a2d.CloseWindow()
end)

function MoveDoesntRepaintTest(name, path, x, y, opt_threshold)
  test.Step(
    name .. " doesn't repaint on non-move",
    function()

      local expectfunc = a2dtest.ExpectNoRepaint

      -- Needed for Joystick, as MouseKeys tickles the buttons
      -- Needed for Bounce as the animation continues
      if opt_threshold then
        expectfunc = function(func)
          a2dtest.ExpectRepaintFraction(0, opt_threshold, func)
        end
      end

      a2d.SelectPath(path)
      a2d.OpenSelection()
      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(x,y)
          emu.wait(2/60)
      end)

      expectfunc(function()
          a2d.InMouseKeysMode(function(m)
              emu.wait(2/60)
              m.ButtonDown()
              emu.wait(10/60)
              m.ButtonUp()
          end)
      end)

      a2d.CloseWindow()
      a2d.CloseAllWindows()
      a2d.Reboot()
  end)
end

MoveDoesntRepaintTest("Calculator", "/A2.DESKTOP/APPLE.MENU/CALCULATOR", 280, 55)
MoveDoesntRepaintTest("Calendar", "/A2.DESKTOP/APPLE.MENU/CALENDAR", 280, 40)
MoveDoesntRepaintTest("Key Caps", "/A2.DESKTOP/APPLE.MENU/KEY.CAPS", 280, 50)
MoveDoesntRepaintTest("Control Panel", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL", 280, 30)
MoveDoesntRepaintTest("Joystick", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/JOYSTICK", 280, 50, 0.02)
MoveDoesntRepaintTest("Map", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP", 280, 40)
MoveDoesntRepaintTest("Options", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS", 280, 45)
MoveDoesntRepaintTest("Views", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/VIEWS", 280, 50)
MoveDoesntRepaintTest("Bounce", "/A2.DESKTOP/APPLE.MENU/TOYS/BOUNCE", 280, 45, 0.05)
MoveDoesntRepaintTest("Eyes", "/A2.DESKTOP/APPLE.MENU/TOYS/EYES", 280, 60)
MoveDoesntRepaintTest("Lights Out", "/A2.DESKTOP/APPLE.MENU/TOYS/LIGHTS.OUT", 280, 60)
MoveDoesntRepaintTest("Neko", "/A2.DESKTOP/APPLE.MENU/TOYS/NEKO", 280, 50)
MoveDoesntRepaintTest("Puzzle", "/A2.DESKTOP/APPLE.MENU/TOYS/PUZZLE", 280, 70)
MoveDoesntRepaintTest("CD Remote", "/A2.DESKTOP/EXTRAS/CD.REMOTE", 280, 70)
MoveDoesntRepaintTest("Scientific Calculator", "/A2.DESKTOP/EXTRAS/SCI.CALC", 280, 50)

-- ============================================================

function CloseWindowTest(name, path, x, y)
  test.Step(
    name .. " closes on OA+W",
    function()
      a2d.SelectPath(path)
      a2dtest.ExpectNothingHappened(function()
          a2d.OpenSelection()
          a2d.OAShortcut("W")
          a2d.WaitForRepaint()
      end)

      a2d.SelectPath(path)
      a2dtest.ExpectNothingHappened(function()
          a2d.OpenSelection()
          a2d.WaitForRepaint()
          a2d.OAShortcut("w")
      end)
  end)
end

--------------------------------------------------
-- Apple Menu
--------------------------------------------------

CloseWindowTest("Calculator", "/A2.DESKTOP/APPLE.MENU/CALCULATOR")
CloseWindowTest("Change Type", "/A2.DESKTOP/APPLE.MENU/CHANGE.TYPE")
CloseWindowTest("Find Files", "/A2.DESKTOP/APPLE.MENU/FIND.FILES")
CloseWindowTest("Key Caps", "/A2.DESKTOP/APPLE.MENU/KEY.CAPS")

--------------------------------------------------
-- Control Panels
--------------------------------------------------

CloseWindowTest("Control Panel", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
CloseWindowTest("Date & Time", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/DATE.AND.TIME")
CloseWindowTest("International", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/INTERNATIONAL")
CloseWindowTest("Joystick", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/JOYSTICK")
CloseWindowTest("Map", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP")
CloseWindowTest("Options", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
CloseWindowTest("Sounds", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SOUNDS")
CloseWindowTest("System Speed", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
CloseWindowTest("Views", "/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/VIEWS")

--------------------------------------------------
-- Toys
--------------------------------------------------

CloseWindowTest("Bounce", "/A2.DESKTOP/APPLE.MENU/TOYS/BOUNCE")
CloseWindowTest("Eyes", "/A2.DESKTOP/APPLE.MENU/TOYS/EYES")
CloseWindowTest("Lights Out", "/A2.DESKTOP/APPLE.MENU/TOYS/LIGHTS.OUT")
CloseWindowTest("Neko", "/A2.DESKTOP/APPLE.MENU/TOYS/NEKO")
CloseWindowTest("Puzzle", "/A2.DESKTOP/APPLE.MENU/TOYS/PUZZLE")

--------------------------------------------------
-- Extras
--------------------------------------------------

CloseWindowTest("Benchmark", "/A2.DESKTOP/EXTRAS/BENCHMARK")
CloseWindowTest("CD Remote", "/A2.DESKTOP/EXTRAS/CD.REMOTE")
CloseWindowTest("DOS 3.3 Import", "/A2.DESKTOP/EXTRAS/DOS33.IMPORT")
CloseWindowTest("Scientific Calculator", "/A2.DESKTOP/EXTRAS/SCI.CALC")

