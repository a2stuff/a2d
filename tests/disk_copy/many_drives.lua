--[[ BEGINCONFIG ========================================

MODELARGS="-aux ext80 -sl2 mouse \
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
  -hard19 res/disk_a.2mg  \
  -hard18 res/disk_j.2mg  \
  -hard17 res/disk_k.2mg  \
  -hard16 res/disk_l.2mg  \
  -hard15 res/disk_b.2mg  \
  -hard14 res/disk_c.2mg  \
  -hard10 res/disk_d.2mg  \
  -hard9  res/disk_e.2mg  \
  -hard8  res/disk_f.2mg  \
  -hard7  res/disk_g.2mg  \
  -hard5  res/disk_h.2mg  \
  -hard4  res/disk_i.2mg  \
  "
======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Configure a system with 9 or more drives. Launch DeskTop. Special >
  Copy Disk.... Verify that the scrollbar is active.
]]
test.Step(
  "scrollbar enabled with 9 or more drives",
  function()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2d.WaitForDesktopReady()

    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be active")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
