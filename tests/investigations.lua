--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]--


--[[============================================================

  Miscellaneous investigations

  ============================================================]]--

test.Step(
  "Verify keyboard shortcuts option doesn't get enabled by reset (in MAME)",
  function()
    --[[
      If MGTK can't find the mouse, DeskTop turns on keyboard
      shortcuts (to be helpful) So this is a signal that after a
      hard reset (Control-OA-Reset), MAME sometimes is in a state
      where MGKT can't find the mouse. Is this an emulator issue or
      real bug? Is there some firmware banking that needs fixing?
    ]]--

    apple2.ControlOAReset()
    a2d.WaitForRestart()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    test.Snap("keyboard shortcuts should not be enabled")
end)


test.Step(
  "Ejecting floppy goes sideways",
  function()
    emu.wait(20)
    local drive = apple2.GetDiskIIS6D1()
    local current = drive.filename
    drive:unload()

    a2d.OpenPath("/FLOPPY1")
    a2dtest.ExpectAlertShown()
    apple2.EscapeKey()

    --[[
      we seem to hang here somehow?

      can't reproduce it on the console though!

      maybe we're accessing the disk when it is yanked? Do something
      modal perhaps?

      CPU seems to still be chugging along, albeit in $C8xx space
    ]]--

    a2dtest.ExpectAlertNotShown()
    emu.wait(60)
    test.Snap("Waited a long time")
    apple2.Type("TRASH")
    test.Snap("typed some shit")
    a2d.InMouseKeysMode(function(m)
        m.MoveByApproximately(560,192)
        m.MoveByApproximately(-560,-192)
        m.MoveByApproximately(560,192)
        m.MoveByApproximately(-560,-192)
        m.MoveByApproximately(560,192)
        m.MoveByApproximately(-560,-192)
        m.MoveByApproximately(560,192)
        m.MoveByApproximately(-560,-192)
    end)
    -- This seems to make us hang or crash?
    drive:load(current)

    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)
    a2d.WaitForRestart()
end)

test.Step(
  "Automation hook",
  function()
    local bank_offset = 0x10000


    -- Addr must include bank offset
    function PrintWinfo(addr)
      local bank = addr & 0xFF0000
      function u8(offset)
        return apple2.ReadRAMDevice(addr + offset)
      end
      function u16(offset)
        return u8(offset) | (u8(offset+1) << 8)
      end
      function s16(offset)
        local v = u16(offset)
        if v & 0x8000 == 0 then
          return v
        else
          return 0x10000 - v
        end
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
      local win, area = mgtk.FindWindow(280,96)
      print("window at center? " .. win .. "  area: " .. NameFromEnum(mgtk.area, area))
      if win ~= 0 then
        local ctl, part = mgtk.FindControlEx(280,96,win)
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

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS", true)

    DumpWindows()
    ProbeCenter()

end)
