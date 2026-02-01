--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse \
  -sl7 scsi \
  -sl7:scsi:scsibus:6 harddisk              \
  -sl7:scsi:scsibus:5 harddisk              \
  -sl7:scsi:scsibus:4 harddisk              \
  -sl7:scsi:scsibus:3 harddisk              \
  -sl7:scsi:scsibus:2 harddisk              \
  -sl7:scsi:scsibus:1 harddisk              \
  -sl7:scsi:scsibus:0 harddisk              \
  -sl6 scsi \
  -sl6:scsi:scsibus:6 harddisk              \
  -sl6:scsi:scsibus:5 harddisk              \
  -sl6:scsi:scsibus:4 harddisk              \
  -sl6:scsi:scsibus:3 harddisk              \
  -sl6:scsi:scsibus:2 harddisk              \
  -sl6:scsi:scsibus:1 harddisk              \
  "
DISKARGS="\
  -hard13 $HARDIMG  \
  -hard12 disk_a.2mg  \
  -hard11 disk_j.2mg  \
  -hard10 disk_k.2mg  \
  -hard9  disk_l.2mg  \
  -hard8  disk_b.2mg  \
  -hard7  disk_c.2mg  \
  \
  -hard6  disk_d.2mg  \
  -hard5  disk_e.2mg  \
  -hard4  disk_f.2mg  \
  -hard3  disk_g.2mg  \
  -hard2  disk_h.2mg  \
  -hard1  disk_i.2mg  \
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
    a2d.CopyDisk()

    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be active")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
