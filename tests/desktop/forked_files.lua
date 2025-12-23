--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl6 superdrive -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/gsos_800k.2mg"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.5)

--[[
  Launch DeskTop. Try to copy files including a GS/OS forked file in
  the selection. Verify that an alert is shown, with the filename
  visible in the progress dialog. Verify that if OK is clicked, the
  operation continues with other files, and the watch cursor is shown.
]]
test.Step(
  "copy selected GS/OS forked files - continue",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
    end)

    a2d.OpenPath("/TESTS/PROPERTIES/GS.OS.FILES")
    a2d.SelectAll()
    a2d.CopySelectionTo("/RAM1")
    a2dtest.WaitForAlert()
    test.Snap("verify 'Installer' filename is visible")
    a2d.DialogOK({no_wait=true})
    a2dtest.MultiSnap(10, "verify watch cursor during remaining copy")
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 3, "3 files should be copied")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Try to copy files including a GS/OS forked file in
  the selection. Verify that an alert is shown, with the filename
  visible in the progress dialog. Verify that if Cancel is clicked the
  operation is aborted.
]]
test.Step(
  "copy selected GS/OS forked files - cancel",
  function()
    a2d.OpenPath("/TESTS/PROPERTIES/GS.OS.FILES")
    a2d.SelectAll()
    a2d.CopySelectionTo("/RAM1")
    a2dtest.WaitForAlert()
    test.Snap("verify 'Installer' filename is visible")
    a2d.DialogCancel()

    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "1 file should be copied")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Try to copy files including a GS/OS forked file
  contained in a selected folder. Verify that an alert is shown, with
  the filename visible in the progress dialog. Verify that if OK is
  clicked, the operation continues with other files, and if Cancel is
  clicked the operation is aborted.
]]
test.Step(
  "copy directory with GS/OS forked files - cancel second",
  function()
    a2d.CopyPath("/TESTS/PROPERTIES/GS.OS.FILES", "/RAM1")
    a2dtest.WaitForAlert()
    test.Snap("verify 'Installer' filename is visible")
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    test.Snap("verify 'Read.Me' filename is visible")
    a2d.DialogCancel()

    a2d.OpenPath("/RAM1/GS.OS.FILES")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "2 files should be copied")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Try to delete files including a GS/OS forked file in
  the selection. Verify that an alert is shown, with the filename
  visible in the progress dialog. Verify that if OK is clicked, the
  operation continues with other files, and if Cancel is clicked the
  operation is aborted.
]]
test.Step(
  "delete selected GS/OS forked files - continue",
  function()
    a2d.OpenPath("/TESTS/PROPERTIES/GS.OS.FILES")

    -- initially cancel
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2dtest.WaitForAlert()
    test.Snap("verify 'Installer' filename is visible")
    a2d.DialogCancel()

    -- try again and continue this time
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2dtest.WaitForAlert()
    test.Snap("verify 'Installer' filename is visible")
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    test.Snap("verify 'Read.Me' filename is visible")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Try to delete files including a GS/OS forked file
  contained in a selected folder. Verify that an alert is shown, with
  the filename visible in the progress dialog. Verify that if OK is
  clicked, the operation continues with other files, and if Cancel is
  clicked the operation is aborted. Note that non-empty directories
  will fail to be deleted.
]]
test.Step(
  "delete directory with GS/OS forked files - continue",
  function()
    a2d.DeletePath("/TESTS/PROPERTIES/GS.OS.FILES")
    a2dtest.WaitForAlert()
    test.Snap("verify 'Installer' filename is visible")
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    test.Snap("verify 'Read.Me' filename is visible")
    a2d.DialogOK()

    a2dtest.WaitForAlert() -- error since directory not empty
    a2d.DialogOK()

    a2d.OpenPath("/TESTS/PROPERTIES/GS.OS.FILES")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "GS.OS.FILES", "directory should still exist")
end)

function GetFrontWindowCenter()
  local x, y, w, h = a2dtest.GetFrontWindowContentRect()
  return x + w/2, y + h/2
end

--[[
  Launch DeskTop. Using drag/drop, try to copy or move a folder
  containing a GS/OS forked file, where the source and destination
  windows are visible. When an alert is shown, click OK. Verify that
  the source and destination windows are updated.
]]
test.Step(
  "drag/drop directory with GS/OS forked files - destination window updates",
  function()
    -- Need coords for opening a second window
    a2d.SelectPath("/RAM1")
    local open_x, open_y = a2dtest.GetSelectedIconCoords()

    -- Open first window
    a2d.SelectPath("/GS.OS.MIXED/GS.OS.FILES")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    -- Open second window
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(open_x, open_y) -- RAM1
        m.DoubleClick()
    end)
    a2d.MoveWindowBy(0, 100)
    local dst_x, dst_y = GetFrontWindowCenter()

    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "GS.OS.MIXED", "on top")

    -- Drag GS.OS.FILES folder from GS.OS.MIXED to RAM1
    a2d.Drag(
      src_x, src_y, -- GS.OS.FILES
      dst_x, dst_y) -- RAM1
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    test.Snap("verify destination window updated")
    emu.wait(5)

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Using drag/drop, try to copy a volume containing a
  GS/OS forked file and other files, where the destination window is
  visible. When an alert is shown, click OK. Verify that the
  destination window is updated.
]]
test.Step(
  "drag/drop volume with GS/OS forked files - destination window updates",
  function()
    a2d.SelectPath("/GS.OS.MIXED")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/RAM1")
    local dst_x, dst_y = GetFrontWindowCenter()

    a2d.Drag(
      src_x, src_y, -- GS.OS.MIXED
      dst_x, dst_y) -- RAM1

    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    test.Snap("verify destination window updated")
    emu.wait(5)

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Using File > Copy To..., try to copy a folder
  containing a GS/OS forked file, where the source and destination
  windows are visible. When an alert is shown, click OK. Verify that
  the source and destination windows are updated.
]]
test.Step(
  "copy directory with GS/OS forked files - destination window updates",
  function()
    -- Need coordinates of two volume icons for multi-select
    a2d.SelectPath("/RAM1")
    local vol_icon1_x, vol_icon1_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/GS.OS.MIXED")
    local vol_icon2_x, vol_icon2_y = a2dtest.GetSelectedIconCoords()

    -- Multi-select / Open, just to get everything visible
    a2d.CloseAllWindows()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon1_x, vol_icon1_y) -- RAM1
        m.Click()

        m.MoveToApproximately(vol_icon2_x, vol_icon2_y) -- GS.OS.MIXED
        apple2.PressOA()
        m.Click()
        apple2.ReleaseOA()
    end)

    a2d.OAShortcut("O") -- File > Open
    a2d.MoveWindowBy(0, 100)

    a2d.Select("GS.OS.FILES")
    a2d.CopySelectionTo("/RAM1")
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    test.Snap("verify destination window activated and updated")
    emu.wait(5)

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Using drag/drop, try to delete a GS/OS forked file.
  When the delete confirmation dialog is shown, click Cancel. Verify
  that the source window is not updated.
]]
test.Step(
  "drag GS/OS forked file to trash - Cancel does not update window",
  function()
    a2d.SelectPath("/Trash")
    local trash_icon_x, trash_icon_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/GS.OS.MIXED/GS.OS.FILES/INSTALLER")
    a2d.MoveWindowBy(0,100)
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(icon_x, icon_y, trash_icon_x, trash_icon_y)

    -- confirm deletion
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- error
    a2dtest.WaitForAlert()
    a2dtest.DHRDarkness()
    a2d.DialogCancel()
    emu.wait(5)
    test.Snap("verify window does not fully repaint")
    -- BUG: This is failing - the window does fully repaint

    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Using drag/drop, try to delete a GS/OS forked file.
  When the delete confirmation dialog is shown, click OK. When an
  alert is shown, click OK. Verify that the source window is updated.
]]
test.Step(
  "drag GS/OS forked file to trash - OK does update window",
  function()
    a2d.SelectPath("/Trash")
    local trash_icon_x, trash_icon_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/GS.OS.MIXED/GS.OS.FILES/INSTALLER")
    a2d.MoveWindowBy(0,100)
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(icon_x, icon_y, trash_icon_x, trash_icon_y)

    -- confirm deletion
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- error
    a2dtest.WaitForAlert()
    a2dtest.DHRDarkness()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify window does fully repaint")

    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Using File > Delete try to delete a GS/OS forked
  file, where the containing window is visible. When the delete
  confirmation dialog is shown, click OK. When an alert is shown,
  click OK. Verify that the containing window is updated.
]]
test.Step(
  "delete GS/OS forked file - OK does update window",
  function()
    a2d.SelectPath("/GS.OS.MIXED/GS.OS.FILES/INSTALLER")
    a2d.MoveWindowBy(0,100)
    a2d.DeleteSelection()

    -- error
    a2dtest.WaitForAlert()
    a2dtest.DHRDarkness()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify window does fully repaint")

    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

