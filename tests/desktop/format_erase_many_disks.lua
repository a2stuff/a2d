--[[ BEGINCONFIG ========================================

MODELARGS="-aux ext80 -sl2 mouse -sl6 '' \
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

------------------------------------------------------------
-- Arrow Keys
------------------------------------------------------------

--[[
  Launch DeskTop. Run the command. Ensure left/right arrows move
  selection correctly.
]]
FormatEraseTest(
  "Right arrow key",
  function(invoke)
    invoke(false)
    for i=1,14 do
      apple2.RightArrowKey()
      test.Snap("verify selection moves right then down")
    end
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Run the command. Ensure left/right arrows move
  selection correctly.
]]
FormatEraseTest(
  "Left arrow key",
  function(invoke)
    invoke(false)
    for i=1,14 do
      apple2.LeftArrowKey()
      test.Snap("verify selection moves left then up")
    end
    a2d.DialogCancel()
end)

FormatEraseTest(
  "Down arrow key",
  function(invoke)
    invoke(false)
    for i=1,14 do
      apple2.DownArrowKey()
      test.Snap("verify selection moves down then right")
    end
    a2d.DialogCancel()
end)

FormatEraseTest(
  "Up arrow key",
  function(invoke)
    invoke(false)
    for i=1,14 do
      apple2.UpArrowKey()
      test.Snap("verify selection moves up then left")
    end
    a2d.DialogCancel()
end)

------------------------------------------------------------
-- Picker
------------------------------------------------------------

--[[
  Configure a system with 13 volumes, not counting `/RAM`. Launch
  DeskTop. Run the command. Verify that all 13 volumes are shown.
]]
FormatEraseTest(
  "All 13 devices show",
  function(invoke)
    invoke(false)
    test.Snap("verify all 13 devices shown")
    a2d.DialogCancel()
end)

--[[
  Configure a system with at least 9 volumes. Launch DeskTop. Run the
  command. Select a volume in the third column. Click OK. Verify that
  the selection rectangle is fully erased.
]]
FormatEraseTest(
  "Selection erased",
  function(invoke)
    invoke(false)
    apple2.RightArrowKey()
    apple2.RightArrowKey()
    apple2.RightArrowKey()
    test.Snap("verify selection in third column")
    a2d.DialogOK()
    test.Snap("verify selection erased completely")
    a2d.DialogCancel()
end)
