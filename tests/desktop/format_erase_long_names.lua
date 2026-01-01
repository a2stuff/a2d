--[[ BEGINCONFIG ========================================

MODELARGS="-aux ext80 -sl2 mouse \
  -sl7 scsi \
  -sl7:scsi:scsibus:6 harddisk           \
  -sl7:scsi:scsibus:5 aplcdsc            \
  -sl7:scsi:scsibus:4 aplcdsc            \
  -sl7:scsi:scsibus:3 aplcdsc            \
  -sl7:scsi:scsibus:2 aplcdsc            \
  -sl7:scsi:scsibus:0 aplcdsc            \
  -sl6 scsi \
  -sl6:scsi:scsibus:6 aplcdsc            \
  -sl6:scsi:scsibus:5 aplcdsc            \
  -sl6:scsi:scsibus:4 aplcdsc            \
  -sl6:scsi:scsibus:3 aplcdsc            \
  -sl6:scsi:scsibus:2 aplcdsc            \
  "
DISKARGS="\
  -hard1 $HARDIMG  \
  "
======================================== ENDCONFIG ]]

--[[
  * harddisk is: "SEAGATEST225N1" (Seagate ST-225N)
  * aplcdsc is: "SONYCD-ROMCDU-80" (Sony CD-ROM CDU-8002)
  * cdrom (id 1) is: "SONYCDU-76S1" (Sony CDU-765S)
]]

a2d.ConfigureRepaintTime(5)

-- Callback called with func to invoke menu item; pass false if
-- no volumes selected, true if volumes selected (affects menu item)
function FormatEraseTest(name, func)
  test.Variants(
    {
      name .. " - Format",
      name .. " - Erase",
    },
    function(idx)
      a2d.CloseAllWindows()
      a2d.ClearSelection()
      func(
        function(vol_selected)
          if vol_selected then
            a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK+idx-1)
          else
            a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2+idx-1)
          end
      end)
  end)
end

--[[
  Show the dialog. Snapshots verifying long device names don't mispaint.
]]
FormatEraseTest(
  "Long names",
  function(invoke)
    invoke(false)
    test.Snap("long names on device selection")
    for i = 1, 13 do
      apple2.DownArrowKey()
    end
    test.Snap("long names with selection device selection")
    a2d.DialogOK()
    test.Snap("long names erased after device selection")
    a2d.DialogCancel()
end)
