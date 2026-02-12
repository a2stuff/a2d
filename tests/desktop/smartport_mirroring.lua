--[[ BEGINCONFIG ==================================================

MODELARGS="-sl2 mouse -sl6 '' -sl7 superdrive \
  -sl5 scsi \
  -sl5:scsi:scsibus:6 harddisk              \
  -sl5:scsi:scsibus:5 harddisk              \
  -sl5:scsi:scsibus:4 harddisk              \
  -sl5:scsi:scsibus:3 harddisk              \
  -sl5:scsi:scsibus:2 harddisk              \
  -sl5:scsi:scsibus:1 harddisk              \
  -sl5:scsi:scsibus:0 harddisk              \
  -sl4 scsi \
  -sl4:scsi:scsibus:6 harddisk              \
  -sl4:scsi:scsibus:5 harddisk              \
  -sl4:scsi:scsibus:4 harddisk              \
  -sl4:scsi:scsibus:3 harddisk              \
  "
DISKARGS="\
  -hard11 disk_a.2mg \
  -hard10 disk_b.2mg \
  -hard9  disk_c.2mg \
  -hard8  disk_d.2mg \
  -hard7  disk_e.2mg \
  -hard6  disk_f.2mg \
  -hard5  disk_g.2mg \
  \
  -hard4  disk_h.2mg \
  -hard3  disk_i.2mg \
  -hard2  disk_j.2mg \
  -hard1  disk_k.2mg \
  \
  -flop1 $HARDIMG \
  -flop2 empty_800k.2mg \
  "

================================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  This is very dependent on ProDOS 2.0.x and 2.4.x mirroring logic.
]]

-- DEVLST mapping after ProDOS has done its magic:

local devices = {
  s7d1 = manager.machine.images[":sl7:superdrive:fdc:0:35hd"], -- non-mirrored
  s7d2 = manager.machine.images[":sl7:superdrive:fdc:1:35hd"], -- non-mirrored

  s5d1 = manager.machine.images[":sl5:scsi:scsibus:6:harddisk:image"], -- non-mirrored
  s5d2 = manager.machine.images[":sl5:scsi:scsibus:5:harddisk:image"], -- non-mirrored

  s2d1 = manager.machine.images[":sl5:scsi:scsibus:4:harddisk:image"], -- mirrored
  s2d2 = manager.machine.images[":sl5:scsi:scsibus:3:harddisk:image"], -- mirrored

  s4d1 = manager.machine.images[":sl4:scsi:scsibus:6:harddisk:image"], -- non-mirrored
  s4d2 = manager.machine.images[":sl4:scsi:scsibus:5:harddisk:image"], -- non-mirrored

  s1d1 = manager.machine.images[":sl5:scsi:scsibus:2:harddisk:image"], -- mirrored
  s1d2 = manager.machine.images[":sl5:scsi:scsibus:1:harddisk:image"], -- mirrored

  s6d1 = manager.machine.images[":sl5:scsi:scsibus:0:harddisk:image"], -- mirrored
  s6d2 = manager.machine.images[":sl4:scsi:scsibus:4:harddisk:image"], -- mirrored

  s3d1 = manager.machine.images[":sl4:scsi:scsibus:3:harddisk:image"], -- mirrored
}

local alpha_order = {
  {slot=5, drive=1}, {slot=5, drive=2}, -- S5 non-mirrored
  {slot=2, drive=1}, {slot=2, drive=2}, -- S5 mirrored
  {slot=1, drive=1}, {slot=1, drive=2}, -- S5 mirrored
  {slot=6, drive=1},                    -- S5 mirrored
  {slot=4, drive=1}, {slot=4, drive=2}, -- S4 non-mirrored
  {slot=6, drive=2}, {slot=3, drive=1}, -- S4 mirrored
}

local empty = devices.s7d2.filename
devices.s7d2:unload()

--[[
  TODO: Test in ProDOS 1.x and 2.0.x as well
]]
test.Step(
  "DEVLST order",
  function()

    a2d.CheckAllDrives()
    a2d.ClearSelection()

    local devlst = apple2.GetProDOSDeviceList()

    for _, entry in ipairs(devlst) do
      if entry.slot == 7 then
        -- Skip A2.DESKTOP (S7D1) and empty (S7D2)
        goto continue
      end
      local drive = devices[string.format("s%dd%d", entry.slot, entry.drive)]
      local image = drive.filename
      drive:load(empty)

      a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)
      emu.wait(1)

      -- Device prompt
      a2d.FormatEraseSelectSlotDrive(entry.slot, entry.drive)

      -- Name prompt
      emu.wait(2)
      a2d.ClearTextField()
      apple2.Type("X")
      a2d.DialogOK()

      -- Confirmation
      a2dtest.WaitForAlert({match="Are you sure.*\"EMPTY\""})
      a2d.DialogCancel()
      emu.wait(1)

      drive:load(image)

      ::continue::
    end
end)

test.Step(
  "Alpha order",
  function()
    a2d.CheckAllDrives()
    a2d.ClearSelection()

    for index, device in ipairs(alpha_order) do
      a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)
      emu.wait(1)

      -- Device prompt
      a2d.FormatEraseSelectSlotDrive(device.slot, device.drive)

      -- Name prompt
      emu.wait(2)
      a2d.ClearTextField()
      apple2.Type("X")
      a2d.DialogOK()

      -- Confirmation
      local disk = string.format("%c", string.byte("A")+index-1)
      a2dtest.WaitForAlert({match="Are you sure.*\""..disk.."\""})
      a2d.DialogCancel()
      emu.wait(1)
    end
end)
