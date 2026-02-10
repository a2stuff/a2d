--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl5 cffa2 -sl6 superdrive"
DISKARGS="-flop1 $HARDIMG -hard1 sizes/image_65534_blocks.hdv -hard2 sizes/image_65534_blocks.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

local s6d1 = manager.machine.images[":sl6:cffa2:cffa2_ata:0:hdd:image"]
local s6d2 = manager.machine.images[":sl6:cffa2:cffa2_ata:1:hdd:image"]

--[[
  Disk Copy with 65534 blocks. Verify block count is correct.
]]
test.Variants(
  {
    {"Quick Copy 65534 blocks", "quick"},
    {"Disk Copy 65534 blocks", "disk"},
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
    a2dtest.WaitForAlert({match="Insert the source disk"})
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert({match="Insert the destination disk"})
    a2d.DialogOK()

    -- confirmation
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()

    -- complete
    a2dtest.WaitForAlert({timeout=10800})
    test.Expect(a2dtest.OCRScreen():find("The copy was successful"), "copy should succeed")
    local transfer, read, written = a2dtest.DiskCopyGetBlockCounts()
    local total = 65534
    test.ExpectEquals(read, transfer, "blocks read should match transfer count")
    test.ExpectEquals(written, transfer, "blocks written should match transfer count")
    if what == "quick" then
      test.ExpectLessThan(transfer, total, "block counts should be less than total blocks")
    else
      test.ExpectEquals(transfer, total, "block counts should be total blocks")
    end
    a2d.DialogOK()

    if what == "full" then
      local src = util.SlurpFile(s6d1.filename)
      local dst = util.SlurpFile(s6d2.filename)
      test.ExpectBinaryEquals(src, dst, "disk images should be identical after disk copy")
    end

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
    a2dtest.WaitForAlert({match="2 volumes with the same name"})
    a2d.DialogOK()
end)
