--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 cffa2 -sl7 cffa2"
DISKARGS="-hard3 $HARDIMG -hard1 sizes/image_511_blocks_random.hdv -hard2 sizes/image_511_blocks_random.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Format then Disk Copy Disk Copy with 511 blocks.
]]
test.Variants(
  {
    {"Format then Quick Copy 511 blocks", "quick"},
    {"Format then Disk Copy 511 blocks", "disk"},
  },
  function(idx, name, what)
    if a2dtest.IsAlertShowing() then  -- duplicate volume
      a2d.DialogOK()
    end

    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)

    a2d.FormatEraseSelectSlotDrive(6, 1)
    a2d.ClearTextField()
    apple2.Type("NEW.NAME" .. idx)
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    --[[
      BUG: MAME/CFFA2 reports device as 512 blocks so it gets
      formatted as 512 blocks
    ]]

    emu.wait(10)

    a2d.ClearSelection()
    a2d.CopyDisk()

    a2d.InvokeMenuItem(3, idx) -- Options > Quick Copy or Disk Copy

    -- select source
    apple2.UpArrowKey() -- S6D2
    apple2.UpArrowKey() -- S6D1
    a2d.WaitForRepaint()
    a2d.DialogOK()

    -- select destination
    apple2.UpArrowKey() -- S6D2
    a2d.WaitForRepaint()
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- confirmation
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- complete
    a2dtest.WaitForAlert({timeout=7200})
    if what == "quick" then
      test.Snap("verify block counts are equal")
    else
      --[[
        BUG: MAME/CFFA2 will fail the read of the 512th block but
        successfully write it, expanding the size of the image and
        writing an arbitrary previously read block to it.
      ]]
      test.Snap("verify total block counts are 511")
    end
    a2d.DialogOK()

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
    a2dtest.WaitForAlert() -- duplicate volume
    a2d.DialogOK()
end)
