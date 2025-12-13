--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]

--[[============================================================

  "Sort Directory" tests

  ============================================================]]

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
    "Files sorted - open with keyboard",
    "Files sorted - open with click"
  },
  function(idx)
    a2d.OpenPath("/TESTS/SORT.DIRECTORY")

    if idx == 1 then
      -- keyboard
      a2d.SelectAndOpen("ORDER")
    else
      -- click
      a2d.Select("ORDER")
      local x, y = a2dtest.GetSelectedIconCoords()
      a2d.ClearSelection()

      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(x, y)
          m.DoubleClick()
      end)
      a2d.WaitForRepaint()
    end

    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.SORT_DIRECTORY)
    a2d.WaitForRepaint()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()

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
    emu.wait(5)
    ValidateOrder(ParseCat())

    apple2.TypeLine("HOME")
    apple2.TypeLine("CAT")
    emu.wait(5)
    ValidateOrder(ParseCat())

    apple2.TypeLine("BYE")
    a2d.WaitForRestart()

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
    a2d.OpenPath("/TESTS/HUNDRED.FILES")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.SORT_DIRECTORY)
    a2d.WaitForRepaint()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()

    apple2.TypeLine("HOME")
    apple2.TypeLine("CAT")
    -- snapshot repeatedly so we catch (most) files
    for n=1,50 do
      emu.wait(0.1)
      local filenames = ParseCat()
      for i = 1,#filenames-1 do
        test.ExpectLessThan(filenames[i], filenames[i+1], "filename order")
      end
    end

    apple2.TypeLine("BYE")
    a2d.WaitForRestart()

end)

--[[
  Open `/TESTS/SORT.DIRECTORY/TWO.SYS.FILES`. Apple Menu > Sort
  Directory. Verify that the files are sorted as `A.SYSTEM` then
  `B.SYSTEM`.
]]
test.Step(
  "System files sorted",
  function()
    a2d.OpenPath("/TESTS/SORT.DIRECTORY/TWO.SYS.FILES")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.SORT_DIRECTORY)
    a2d.WaitForRepaint()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()

    apple2.TypeLine("HOME")
    apple2.TypeLine("CAT")
    emu.wait(5)
    local filenames = ParseCat()
    for i = 1,#filenames-1 do
      test.ExpectLessThan(filenames[i], filenames[i+1], "filename order")
    end

    apple2.TypeLine("BYE")
    a2d.WaitForRestart()

end)
