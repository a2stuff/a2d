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

function coords()
  local found_x, found_y
  a2dtest.OCRIterate(function(run, x, y)
      if run:upper():find("SEAGATE") then
        found_x, found_y = x, y
        return false
      end
  end, {invert=true})
  return found_x, found_y
end

--[[
  Launch DeskTop. Run the command. Ensure left/right arrows move
  selection correctly.
]]
FormatEraseTest(
  "Right arrow key",
  function(invoke)
    invoke(false)

    local last_x, last_y
    for i=1, #apple2.GetProDOSDeviceList() do
      apple2.RightArrowKey()
      local x, y = coords()
      if i >= 2 then
        test.Expect(x > last_x or y > last_y, "selection should move right then down")
      end
      last_x, last_y = x, y
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

    local last_x, last_y
    for i=1,#apple2.GetProDOSDeviceList() do
      apple2.LeftArrowKey()
      local x, y = coords()
      if i >= 2 then
        test.Expect(x < last_x or y < last_y, "selection should move left then up")
      end
      last_x, last_y = x, y
    end
    a2d.DialogCancel()
end)

FormatEraseTest(
  "Down arrow key",
  function(invoke)
    invoke(false)
    local last_x, last_y
    for i=1,#apple2.GetProDOSDeviceList() do
      apple2.DownArrowKey()
      local x, y = coords()
      if i >= 2 then
        test.Expect(y > last_y or x > last_x, "selection should move down then right")
      end
      last_x, last_y = x, y
    end
    a2d.DialogCancel()
end)

FormatEraseTest(
  "Up arrow key",
  function(invoke)
    invoke(false)
    local last_x, last_y
    for i=1,#apple2.GetProDOSDeviceList() do
      apple2.UpArrowKey()
      local x, y = coords()
      if i >= 2 then
        test.Expect(y < last_y or x < last_x, "selection should move up then left")
      end
      last_x, last_y = x, y
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

    local ocr = a2dtest.OCRScreen()
    local count = 0
    for _ in ocr:upper():gmatch("SEAGATE") do
      count = count + 1
    end
    test.ExpectEquals(count, 13, "all 13 devices should be shown")
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
