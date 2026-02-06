--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl5 cffa2 -sl6 superdrive"
DISKARGS="-flop1 $HARDIMG -hard1 tests.hdv -hard2 empty_32mb.hdv"

======================================== ENDCONFIG ]]

--[[
  NOTE: Disk images should be exactly 33,554,432 bytes (32MiB); this
  causes MAME/CFFA2 driver to return $0000 as the block count.
]]

a2d.ConfigureRepaintTime(0.25)

local s5d1 = manager.machine.images[":sl5:cffa2:cffa2_ata:0:hdd:image"]
local s5d2 = manager.machine.images[":sl5:cffa2:cffa2_ata:1:hdd:image"]

--[[
  Launch DeskTop. Special > Copy Disk.... Copy a 32MB disk image using
  Quick Copy (the default mode). Verify that the screen is not
  garbled, the progress bar updates correctly, and that the copy is
  successful.

  Launch DeskTop. Special > Copy Disk.... Copy a 32MB disk image using
  Disk Copy (the other mode). Verify that the screen is not garbled,
  the progress bar updates correctly, and that the copy is successful.
]]

test.Variants(
  {
    {"Quick Copy 32MB", "quick"},
    {"Disk Copy 32MB", "disk"},
  },
  function(idx, name, what)
    if a2dtest.IsAlertShowing() then  -- duplicate volume
      a2d.DialogOK()
    end

    a2d.CopyDisk()

    a2d.InvokeMenuItem(3, idx) -- Options > Quick Copy or Disk Copy

    -- select source
    apple2.UpArrowKey() -- S5D2
    apple2.UpArrowKey() -- S5D1
    a2d.WaitForRepaint()
    a2d.DialogOK()

    -- select destination
    apple2.UpArrowKey() -- S5D2
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
    a2dtest.WaitForAlert({timeout=10800})
    test.Expect(a2dtest.OCRScreen():find("The copy was successful"), "copy should succeed")
    local transfer, read, written = a2dtest.DiskCopyGetBlockCounts()
    local total = 65535
    test.ExpectEquals(read, transfer, "blocks read should match transfer count")
    test.ExpectEquals(written, transfer, "blocks written should match transfer count")
    if what == "quick" then
      test.ExpectLessThan(transfer, total, "block counts should be less than total blocks")
    else
      test.ExpectEquals(transfer, total, "block counts should be total blocks")
    end
    a2d.DialogOK()

    if what == "full" then
      local src = util.SlurpFile(s5d1.filename)
      local dst = util.SlurpFile(s5d2.filename)
      test.ExpectBinaryEquals(src, dst, "disk images should be identical after disk copy")
    end

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
    a2dtest.WaitForAlert() -- duplicate volume
    a2d.DialogOK()
end)
