--[[ BEGINCONFIG ==================================================

MODEL="apple2ee"
  MODELARGS="-sl2 mouse -sl4 scsi -sl5 scsi -sl6 '' -sl7 superdrive \
  \
  -sl5:scsi:scsibus:6 harddisk              \
  -sl5:scsi:scsibus:5 harddisk              \
  -sl5:scsi:scsibus:4 harddisk              \
  -sl5:scsi:scsibus:3 harddisk              \
  -sl5:scsi:scsibus:2 harddisk              \
  -sl5:scsi:scsibus:0 harddisk              \
  \
  -sl4:scsi:scsibus:6 harddisk              \
  -sl4:scsi:scsibus:5 harddisk              \
  -sl4:scsi:scsibus:4 harddisk              \
  -sl4:scsi:scsibus:3 harddisk              \
  "
DISKARGS="\
  -hard10 res/disk_a.2mg \
  -hard9  res/disk_b.2mg \
  -hard8  res/disk_c.2mg \
  -hard7  res/disk_d.2mg \
  -hard6  res/disk_e.2mg \
  -hard5  res/disk_f.2mg \
  \
  -hard4  res/disk_g.2mg \
  -hard3  res/disk_h.2mg \
  -hard2  res/disk_i.2mg \
  -hard1  res/disk_j.2mg \
  \
  -flop1 $HARDIMG \
  -flop2 res/empty_800k.2mg \
  "

================================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  This is very dependent on ProDOS 2.0.x and 2.4.x mirroring logic.
]]

-- DEVLST mapping after ProDOS has done its magic:

local s7d1 = manager.machine.images[":sl7:superdrive:fdc:0:35hd"] -- non-mirrored
local s7d2 = manager.machine.images[":sl7:superdrive:fdc:1:35hd"] -- non-mirrored

local s5d1 = manager.machine.images[":sl5:scsi:scsibus:6:harddisk:image"] -- non-mirrored
local s5d2 = manager.machine.images[":sl5:scsi:scsibus:5:harddisk:image"] -- non-mirrored

local s2d1 = manager.machine.images[":sl5:scsi:scsibus:4:harddisk:image"] -- mirrored
local s2d2 = manager.machine.images[":sl5:scsi:scsibus:3:harddisk:image"] -- mirrored

local s4d1 = manager.machine.images[":sl4:scsi:scsibus:6:harddisk:image"] -- non-mirrored
local s4d2 = manager.machine.images[":sl4:scsi:scsibus:5:harddisk:image"] -- non-mirrored

local s1d1 = manager.machine.images[":sl5:scsi:scsibus:2:harddisk:image"] -- mirrored
local s1d2 = manager.machine.images[":sl5:scsi:scsibus:1:cdrom:image"] -- mirrored

local s6d1 = manager.machine.images[":sl5:scsi:scsibus:0:harddisk:image"] -- mirrored
local s6d2 = manager.machine.images[":sl4:scsi:scsibus:4:harddisk:image"] -- mirrored

local s3d1 = manager.machine.images[":sl4:scsi:scsibus:3:harddisk:image"] -- mirrored

local devlst_order = {
  s7d1, s7d2, s5d1, s5d2, s2d1, s2d2,
  s4d1, s4d2, s1d1, s1d2, s6d1, s6d2, s3d1,
}

local alpha_order = {
  s5d1, s5d2, s2d1, s2d2, s1d1, s6d1,
  s4d1, s4d2, s6d2, s3d1
}

local empty = s7d2.filename
s7d2:unload()

--[[
  TODO: Test in ProDOS 1.x and 2.0.x as well
]]
test.Step(
  "DEVLST order",
  function()

    a2d.CheckAllDrives()
    a2d.ClearSelection()

    for index = 3, #devlst_order do
      local drive = devlst_order[index]
      if drive == s1d2 then
        goto continue
      end
      local image = drive.filename
      drive:load(empty)

      a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)
      emu.wait(1)

      -- Device prompt
      for i = 1, index do
        apple2.DownArrowKey()
      end
      apple2.ReturnKey()

      -- Name prompt
      emu.wait(2)
      a2d.ClearTextField()
      apple2.Type("X")
      a2d.DialogOK()

      -- Confirmation
      a2dtest.WaitForAlert()
      emu.wait(1)
      test.Snap("verify name is \"EMPTY\"")
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

    for index = 1, #alpha_order do
      a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)
      emu.wait(1)

      -- Device prompt
      for i = 1, #devlst_order do
        apple2.DownArrowKey()
        if devlst_order[i] == alpha_order[index] then
          break
        end
      end
      apple2.ReturnKey()

      -- Name prompt
      emu.wait(2)
      a2d.ClearTextField()
      apple2.Type("X")
      a2d.DialogOK()

      -- Confirmation
      a2dtest.WaitForAlert()
      emu.wait(1)
      test.Snap(string.format("verify name is \"%c\"", string.byte("A")+index-1))
      a2d.DialogCancel()
      emu.wait(1)
    end
end)
