--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

desktop.AddShortcut("/TESTS/HUNDRED.FILES")
desktop.CloseAllWindows()

-- Parse on-screen output of CAT; returns filenames in array
function ParseCat()
  local cat = apple2.GrabTextScreen()
  -- parse the catalog (whatever lines are visible)
  local names = {}
  for line in cat:gmatch('([^\n]+)') do
    name = line:match("^ ([A-Z0-9.]+)%s+%S%S%S%s+%d+%s+%d+-%a+-%d+%s+$")
    if name then
      -- elide duplicates (in case we're called during scroll)
      if #names == 0 or name ~= names[#names] then
        table.insert(names, name)
      end
    end
  end
  return names
end

--[[
  Open `/TESTS/SORT.DIRECTORY/ORDER`. File > Quit. Re-launch DeskTop.
  Apple Menu > Sort Directory. Verify that the files in the window are
  sorted.

  Open `/TESTS/SORT.DIRECTORY`. Open the `ORDER` folder by
  double-clicking. Apple Menu > Sort Directory. Verify that files are
  sorted by type/name.
]]
test.Variants(
  {
    {"Files sorted - open with keyboard", "keyboard"},
    {"Files sorted - open with click", "click"},
  },
  function(idx, name, which)
    desktop.OpenWindow("/TESTS/SORT.DIRECTORY")

    if which == "keyboard" then
      -- keyboard
      desktop.SelectAndOpen("ORDER")
    else
      -- click
      desktop.Select("ORDER")
      local x, y = a2dtest.GetSelectedIconCoords()
      desktop.ClearSelection()

      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(x, y)
          m.DoubleClick()
      end)
      a2dtest.WaitForSystemTask()
    end

    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.SORT_DIRECTORY)
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()

    function ValidateOrder(filenames)
      local nums = {}
      for idx,name in pairs(filenames) do
        ab, typ, num = name:match("^(.*)%.(.*)%.(%d+)$")
        table.insert(nums, tonumber(num))
      end
      for i = 1,#nums-1 do
        test.ExpectLessThan(nums[i], nums[i+1], "filename order")
      end
    end

    apple2.TypeLine("HOME")
    apple2.TypeLine("CAT, TSYS")
    emu.wait(5) -- automating BASIC prompt
    ValidateOrder(ParseCat())

    apple2.TypeLine("HOME")
    apple2.TypeLine("CAT")
    emu.wait(5) -- automating BASIC prompt
    ValidateOrder(ParseCat())

    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
end)

--[[
  Load DeskTop. Ensure that every ProDOS device is online and
  represented by an icon. Open `/TESTS/HUNDRED.FILES`. Apple Menu >
  Sort Directory. Make sure all the files are sorted lexicographically
  (e.g. F1, F10, F100, F101, ...)
]]
test.Step(
  "Lexicographical sorting",
  function()
    desktop.CloseAllWindows()
    a2d.OAShortcut("1") -- Open HUNDRED.FILES
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.SORT_DIRECTORY)
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()

    apple2.TypeLine("HOME")
    apple2.TypeLine("CAT")
    -- snapshot repeatedly so we catch (most) files
    for n=1,50 do
      emu.wait(0.1) -- automating BASIC prompt
      local filenames = ParseCat()
      for i = 1,#filenames-1 do
        test.ExpectLessThan(filenames[i], filenames[i+1], "filename order")
      end
    end

    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
end)

--[[
  Open `/TESTS/SORT.DIRECTORY/TWO.SYS.FILES`. Apple Menu > Sort
  Directory. Verify that the files are sorted as `A.SYSTEM` then
  `B.SYSTEM`.
]]
test.Step(
  "System files sorted",
  function()
    desktop.OpenWindow("/TESTS/SORT.DIRECTORY/TWO.SYS.FILES")
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.SORT_DIRECTORY)
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()

    apple2.TypeLine("HOME")
    apple2.TypeLine("CAT")
    emu.wait(5) -- automating BASIC prompt
    local filenames = ParseCat()
    for i = 1,#filenames-1 do
      test.ExpectLessThan(filenames[i], filenames[i+1], "filename order")
    end

    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
end)
