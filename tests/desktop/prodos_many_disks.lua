--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse \
  -sl7 scsi \
  -sl7:scsi:scsibus:2 harddisk              \
  -sl7:scsi:scsibus:3 harddisk              \
  -sl7:scsi:scsibus:4 harddisk              \
  -sl7:scsi:scsibus:5 harddisk              \
  -sl7:scsi:scsibus:6 harddisk              \
  -sl6 scsi \
  -sl6:scsi:scsibus:2 harddisk              \
  -sl6:scsi:scsibus:3 harddisk              \
  -sl6:scsi:scsibus:4 harddisk              \
  -sl6:scsi:scsibus:5 harddisk              \
  -sl6:scsi:scsibus:6 harddisk              \
  -sl5 scsi \
  -sl5:scsi:scsibus:2 harddisk              \
  -sl5:scsi:scsibus:3 harddisk              \
  -sl5:scsi:scsibus:4 harddisk              \
  -sl5:scsi:scsibus:5 harddisk              \
  -sl5:scsi:scsibus:6 harddisk              \
  -sl4 scsi \
  -sl4:scsi:scsibus:2 harddisk              \
  -sl4:scsi:scsibus:3 harddisk              \
  -sl4:scsi:scsibus:4 harddisk              \
  -sl4:scsi:scsibus:5 harddisk              \
  -sl4:scsi:scsibus:6 harddisk              \
  "
DISKARGS="\
  -hard20 $HARDIMG  \
  -hard19 disk_a.2mg  \
  -hard18 disk_j.2mg  \
  -hard17 disk_k.2mg  \
  -hard16 disk_l.2mg  \
  -hard15 disk_b.2mg  \
  -hard14 disk_c.2mg  \
  -hard10 disk_d.2mg  \
  -hard9  disk_e.2mg  \
  -hard8  disk_f.2mg  \
  -hard7  disk_g.2mg  \
  -hard5  disk_h.2mg  \
  -hard4  disk_i.2mg  \
  "
======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Configure a system with 14 devices. Launch and then exit DeskTop.
  Load another ProDOS app that enumerates devices. Verify that all
  expected devices are present, and that there's no "Slot 0, Drive 1"
  entry.
]]
test.Step(
  "No S0,D1 device gets created",
  function()
    a2d.Quit()
    apple2.WaitForBitsy()

    local list = apple2.GetProDOSDeviceList()
    test.ExpectEquals(#list, 14, "should have 14 devices")

    for i,device in ipairs(list) do
      test.ExpectNotEquals(device.slot, 0, "should not have slot 0 device")
    end
end)
