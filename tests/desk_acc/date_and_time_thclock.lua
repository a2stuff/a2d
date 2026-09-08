--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 thclock -sl2 mouse -sl4 softcard -sl7 cffa2"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

function SetDateTime(y,m,d,hh,mm)

  local months = {
    'jan', 'feb', 'mar',
    'apr', 'may', 'jun',
    'jul', 'aug', 'sep',
    'oct', 'nov', 'dec'
  }

  function GetValue()
    local ocr = a2dtest.OCRFrontWindowContent({invert=true})
    local found, _, val = ocr:find('^(%d+)\n')
    if found then
      return tonumber(val)
    end
    local found, _, val = ocr:find('^(%a%a%a)\n')
    if found then
      return val:lower()
    end
    return nil
  end

  function NextValue()
    apple2.UpArrowKey()
    a2d.WaitForRepaint()
  end

  while GetValue() ~= d do
    NextValue()
  end
  apple2.TabKey()

  while GetValue() ~= months[m] do
    NextValue()
  end
  apple2.TabKey()

  while GetValue() ~= y do
    NextValue()
  end
  apple2.TabKey()

  while GetValue() ~= hh do
    NextValue()
  end
  apple2.TabKey()

  while GetValue() ~= mm do
    NextValue()
  end
end

test.Step(
  "Set ThunderClock",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/DATE.AND.TIME", {no_validate=true})
    a2d.OAShortcut('2') -- 24-hour
    a2d.WaitForRepaint()

    local set_y, set_m, set_d = 27, 4, 13
    local set_hh, set_mm = 12, 34

    SetDateTime(set_y, set_m, set_d, set_hh, set_mm)

    a2d.DialogOK()
    emu.wait(10)

    local y,m,d = apple2.GetProDOSDate()
    local hh,mm = apple2.GetProDOSTime()

    test.ExpectEquals(y % 100, set_y, "year")
    test.ExpectEquals(m, set_m, "month")
    test.ExpectEquals(d, set_d, "day")
    test.ExpectEquals(hh, set_hh, "hour")
    test.ExpectEquals(mm, set_mm, "minute")

    a2d.CloseAllWindows()
end)

test.Step(
  "Clock only set if dirty",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/DATE.AND.TIME", {no_validate=true})

    local hh, mm = apple2.GetProDOSTime()
    local initial_time = string.format("%02d:%02d", hh, mm)

    -- Let time advance
    emu.wait(120)

    local hh, mm = apple2.GetProDOSTime()
    local current_time = string.format("%02d:%02d", hh, mm)

    test.ExpectNotEquals(current_time, initial_time, "time should have advanced")

    a2d.DialogCancel()
    emu.wait(10)

    local hh, mm = apple2.GetProDOSTime()
    local new_time = string.format("%02d:%02d", hh, mm)

    test.ExpectNotEquals(new_time, initial_time, "time should not have been reset")

    a2d.CloseAllWindows()
end)
