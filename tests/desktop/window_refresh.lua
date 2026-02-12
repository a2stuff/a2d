--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse  -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv -flop1 floppy_with_files.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.5)

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]

--[[
  Move files with failure during enumeration. Verify window does not
  repaint.
]]
test.Step(
  "move - failure during enumeration does not repaint window",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(280, 80)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.OpenPath("/WITH.FILES", {keep_windows=true})
    a2d.MoveWindowBy(0, 80)
    a2d.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2dtest.DHRDarkness()

    local current = s6d1.filename
    s6d1:unload()
    a2d.Drag(src_x, src_y, dst_x, dst_y, {oa_drop=true})
    a2dtest.WaitForAlert({match="Insert the disk: WITH%.FILES"})
    s6d1:load(current)
    a2d.DialogCancel()

    emu.wait(5)
    test.Snap("verify WITH.FILES window did not repaint")

    -- cleanup
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Delete files with failure during enumeration. Verify window does not
  repaint.
]]
test.Step(
  "delete - failure during enumeration does not repaint window",
  function()
    a2d.OpenPath("/WITH.FILES")
    a2d.MoveWindowBy(0, 80)
    a2d.SelectAll()

    a2dtest.DHRDarkness()

    local current = s6d1.filename
    s6d1:unload()
    a2d.OADelete()
    a2dtest.WaitForAlert({match="Insert the disk: WITH%.FILES"})
    s6d1:load(current)
    a2d.DialogCancel()

    emu.wait(5)
    test.Snap("verify WITH.FILES window did not repaint")

    -- cleanup
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

a2d.ConfigureRepaintTime(0.5)

--[[
* Repeat the following test cases for these operations: Copy, Move, Delete:
  * Select multiple files. Start the operation. During the initial count of the files, press Escape. Verify that the count is canceled and the progress dialog is closed, and that the window contents do not refresh.
  * Select multiple files. Start the operation. After the initial count of the files is complete and the actual operation has started, press Escape. Verify that the operation is canceled and the progress dialog is closed, and that (apart from the source window for Copy) the window contents do refresh.
]]
test.Variants(
  {
    {"copy aborted during enumeration", "copy", "during"},
    {"move aborted during enumeration", "move", "during"},
    {"delete aborted during enumeration", "delete", "during"},
    {"copy aborted after enumeration", "copy", "after"},
    {"move aborted after enumeration", "move", "after"},
    {"delete aborted after enumeration", "delete", "after"},
  },
  function(idx, name, what, when)
    local dst_x, dst_y

    if what == "delete" then
      a2d.SelectPath("/Trash")
      dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    end

    a2d.CopyPath("/A2.DESKTOP/EXTRAS", "/RAM1")
    a2d.CloseAllWindows()

    if what == "copy" or what == "move" then
      a2d.CreateFolder("/RAM1/FOLDER")
      a2d.OpenPath("/RAM1/FOLDER")
      a2d.MoveWindowBy(300, 60)
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()
      dst_x, dst_y = x + w / 2, y + h / 2
    end

    a2d.OpenPath("/RAM1/EXTRAS", {keep_windows=true})
    emu.wait(5)
    a2d.GrowWindowBy(-200, -200)
    a2d.MoveWindowBy(0, 60)
    emu.wait(5)
    a2d.SelectAll()
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)

        a2dtest.DHRDarkness()

        if what == "copy" then
          apple2.PressSA() -- copy
          m.ButtonUp()
          apple2.ReleaseSA()
        else
          m.ButtonUp() -- move or delete
        end

        -- Bypass normal exiting delays
        -- TODO: Figure out why this is necessary
        a2d.ExitMouseKeysMode()
        return false
    end)

    if what == "delete" and when == "after" then
      a2dtest.WaitForAlert({match="Are you sure"})
      a2d.DialogOK({no_wait=true})
    end

    if when == "during" then
      -- abort during enumeration
      emu.wait(0.25)
      test.Snap("verify enumerating")
      apple2.EscapeKey()
    else
      -- abort after enumeration
      if what == "delete" then
        emu.wait(0.5) -- already enumerated, so shorter wait
      else
        emu.wait(2)
      end
      test.Snap("verify performing action")
      apple2.EscapeKey()
    end

    emu.wait(10)
    if when == "during" then
      if what == "copy" or what == "move" then
        test.Snap("verify EXTRAS and FOLDER windows did not repaint")
      elseif what == "delete" then
        test.Snap("verify EXTRAS windows did not repaint")
      end
    else
      if what == "copy" then
        test.Snap("verify EXTRAS folder did not repaint but FOLDER window did repaint")
      elseif what == "move" then
        test.Snap("verify EXTRAS and FOLDER windows did repaint")
      elseif what == "delete" then
        test.Snap("verify EXTRAS folder did repaint")
      end
    end

    -- cleanup (and repaint screen)
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Open two windows containing multiple files. Select
  multiples files in the first window. File > Copy To.... Select the
  second window's location as a destination and click OK. During the
  initial count of the files, press Escape. Verify that the count is
  canceled and the progress dialog is closed, and that the second
  window's contents do not refresh.
]]
test.Step(
  "copy aborted during enumeration doesn't refresh target window",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0, 100)

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS", {keep_windows=true})
    a2d.SelectAll()
    a2dtest.DHRDarkness()
    a2d.CopySelectionTo("/RAM1", false, {no_wait=true})
    emu.wait(0.25)
    apple2.EscapeKey()
    emu.wait(5)
    test.Snap("verify RAM1 window did not refresh")

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Open two windows containing multiple files. Select
  multiples files in the first window. File > Copy To.... Select the
  second window's location as a destination and click OK. After the
  initial count of the files is complete and the actual operation has
  started, press Escape. Verify that the second window's contents do
  refresh.
]]
test.Step(
  "copy aborted after enumeration does refresh target window",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0, 100)

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS", {keep_windows=true})
    a2d.SelectAll()
    a2dtest.DHRDarkness()
    a2d.CopySelectionTo("/RAM1", false, {no_wait=true})
    emu.wait(2)
    apple2.EscapeKey()
    emu.wait(5)

    test.Snap("verify RAM1 window did refresh")

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
