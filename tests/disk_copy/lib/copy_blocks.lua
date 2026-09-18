
apple2 = require("apple2")
a2d = require("a2d")
test = require("test")
a2dtest = require("a2dtest")
util = require("util")

function CopyBlocksTests(blocks, src_img, dst_img)
  --[[
    Disk Copy with N blocks. Verify block count is correct.
  ]]
  test.Variants(
    {
      {string.format("Smart Block Copy %d blocks", blocks), "quick"},
      {string.format("Full Disk Copy %d blocks", blocks), "disk"},
    },
    function(idx, name, what)
      if a2dtest.IsAlertShowing() then  -- duplicate volume
        a2d.DialogOK()
        a2dtest.WaitForSystemTask()
      end

      a2d.CopyDisk()
      a2dtest.ConfigureForDiskCopy()

      a2d.InvokeMenuItem(3, idx) -- Options > Smart Block Copy or Full Disk Copy

      -- select source
      apple2.UpArrowKey() -- S5D2
      apple2.UpArrowKey() -- S5D1
      a2dtest.WaitForSystemTask()
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()

      -- select destination
      apple2.UpArrowKey() -- S5D2
      a2dtest.WaitForSystemTask()
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
      a2dtest.WaitForAlert({timeout=2*10800, match="The copy was successful"})
      local transfer, read, written = a2dtest.DiskCopyGetBlockCounts()
      test.ExpectEquals(read, transfer, "blocks read should match transfer count")
      test.ExpectEquals(written, transfer, "blocks written should match transfer count")
      if what == "quick" then
        test.ExpectLessThan(transfer, blocks, "block counts should be less than total blocks")
      else
        test.ExpectEquals(transfer, blocks, "block counts should be total blocks")
      end
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()

      if what == "full" then
        local src = util.SlurpFile(src_img.filename)
        local dst = util.SlurpFile(dst_img.filename)
        test.ExpectBinaryEquals(src, dst, "disk images should be identical after disk copy")
      end

      -- cleanup
      a2d.OAShortcut("Q") -- File > Quit
      a2dtest.ConfigureForDeskTop()
      a2d.WaitForDesktopReady()
      a2dtest.WaitForAlert({match="2 volumes with the same name"})
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()
  end)
end
