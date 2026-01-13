a2d.ConfigureRepaintTime(1)

test.Step(
  "Automation hook",
  function()
    local bank_offset = 0x10000


    -- Addr must include bank offset
    function PrintWinfo(addr)
      local bank = addr & 0xFF0000
      local ram = apple2.GetRAMDeviceProxy()

      function u8(offset)
        return ram.read_u8(addr + offset)
      end
      function u16(offset)
        return ram.read_u16(addr + offset)
      end
      function s16(offset)
        return ram.read_s16(addr + offset)
      end

      local id = u8(0)
      print(string.format("id: %d", id))
      print(string.format("title: %q", mgtk.GetWindowName(id, bank_offset)))

      local crect = mgtk.GetWindowContentRect(id, bank_offset)
      print(string.format("geometry: %d,%d - %dx%d", crect[1], crect[2], crect[3], crect[4]))

      local nextptr = u16(56)

      local rect = mgtk.GetWinFrameRect(id)
      print(string.format("frame: %d,%d - %dx%d",
                          rect[1], rect[2], rect[3], rect[4]))

      if nextptr ~= 0 then
        print("")
        PrintWinfo(bank + nextptr)
      end
    end

    function DumpWindows()
      local num_windows = a2dtest.GetWindowCount()
      if num_windows == 0 then
        print("(no windows)")
      else
        print("" .. num_windows .. " open windows")
        PrintWinfo(0x10000 + mgtk.GetWinPtr(mgtk.FrontWindow()))
      end
    end

    function NameFromEnum(enum, value)
      for k,v in pairs(enum) do
        if v == value then
          return k
        end
      end
      return string.format("(not found: %d)", value)
    end

    function ProbeCenter()
      local win, area = mgtk.FindWindow(apple2.SCREEN_WIDTH/2,apple2.SCREEN_HEIGHT/2)
      print("window at center? " .. win .. "  area: " .. NameFromEnum(mgtk.area, area))
      if win ~= 0 then
        local ctl, part = mgtk.FindControlEx(apple2.SCREEN_WIDTH/2,apple2.SCREEN_HEIGHT/2,win)
        print("ctl: " .. NameFromEnum(mgtk.ctl,ctl) .. "  part: " .. NameFromEnum(mgtk.part,part))
      end
    end

    DumpWindows()
    ProbeCenter()

    print("-----------------------")

    a2d.OpenPath("/A2.DESKTOP")

    DumpWindows()
    ProbeCenter()


    print("-----------------------")

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS", {leave_parent=true})

    DumpWindows()
    ProbeCenter()

end)

test.Step(
  "IconTK",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    test.Snap("BS?")
    for i,icon in ipairs(a2d.GetSelectedIcons()) do
      print("sel# " .. i .. "  icon# " .. icon.id .. " = " .. icon.name)
    end

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU")
    a2d.SelectAll()
    for i,icon in ipairs(a2d.GetSelectedIcons()) do
      print("sel# " .. i .. "  icon# " .. icon.id .. " = " .. icon.name)
    end
end)


