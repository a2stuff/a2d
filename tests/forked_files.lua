--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/gsos_floppy.dsk"

======================================== ENDCONFIG ]]--

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
    test.Snap("verify 3 files copied")
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2d.CloseAllWindows()
end)

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
    test.Snap("verify 1 file copied")
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2d.CloseAllWindows()
end)

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
    test.Snap("verify 2 files copied")
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2d.CloseAllWindows()
end)

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

local kVolIconDeltaY = 29
local vol_icon1_x, vol_icon1_y = 520, 25 -- A2.DESKTOP
local vol_icon2_x, vol_icon2_y = vol_icon1_x, vol_icon1_y + kVolIconDeltaY*1 -- TESTS
local vol_icon3_x, vol_icon3_y = vol_icon1_x, vol_icon1_y + kVolIconDeltaY*2 -- RAM1
local vol_icon4_x, vol_icon4_y = vol_icon1_x, vol_icon1_y + kVolIconDeltaY*3 -- GS.OS.MIXED
local trash_icon_x, trash_icon_y = 520, 170

test.Step(
  "drag/drop directory with GS/OS forked files - destination window updates",
  function()
    a2d.SelectPath("/GS.OS.MIXED/GS.OS.FILES")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon3_x, vol_icon3_y) -- RAM1
        m.DoubleClick()
    end)
    a2d.MoveWindowBy(0, 100)
    local dst_window_x, dst_window_y, dst_window_w, dst_window_h
      = a2dtest.GetFrontWindowContentRect()

    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "GS.OS.MIXED", "on top")

    -- Drag GS.OS.FILES folder from GS.OS.MIXED to RAM1
    local icon_x, icon_y = 30, 30
    local src_window_x, src_window_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_window_x+icon_x, src_window_y+icon_y) -- GS.OS.MIXED
        m.ButtonDown()
        m.MoveToApproximately(dst_window_x + dst_window_w/2,
                              dst_window_y + dst_window_h/2) -- RAM1
        m.ButtonUp()
    end)
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    test.Snap("verify destination window updated")

    a2d.EraseVolume("RAM1")
end)

test.Step(
  "drag/drop volume with GS/OS forked files - destination window updates",
  function()
    a2d.OpenPath("/RAM1")
    local dst_window_x, dst_window_y, dst_window_w, dst_window_h
      = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon4_x, vol_icon4_y) -- GS.OS.MIXED
        m.ButtonDown()
        m.MoveToApproximately(dst_window_x + dst_window_w/2,
                              dst_window_y + dst_window_h/2) -- RAM1
        m.ButtonUp()
    end)

    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    test.Snap("verify destination window updated")

    a2d.EraseVolume("RAM1")
end)

test.Step(
  "copy directory with GS/OS forked files - destination window updates",
  function()
    a2d.CloseAllWindows()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon3_x, vol_icon3_y) -- RAM1
        m.Click()

        m.MoveToApproximately(vol_icon4_x, vol_icon4_y) -- GS.OS.MIXED
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

    a2d.EraseVolume("RAM1")
end)

test.Step(
  "drag GS/OS forked file to trash - Cancel does not update window",
  function()
    a2d.SelectPath("/GS.OS.MIXED/GS.OS.FILES/INSTALLER")
    a2d.MoveWindowBy(0,100)

    local icon_x, icon_y = 120, 30
    local window_x, window_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+icon_x, window_y+icon_y)
        m.ButtonDown()

        m.MoveToApproximately(trash_icon_x, trash_icon_y)
        m.ButtonUp()
    end)

    -- confirm deletion
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- error
    a2dtest.WaitForAlert()
    a2dtest.DHRDarkness()
    a2d.DialogCancel()
    test.Snap("verify window does not fully repaint")
    -- BUG: This is failing - the window does fully repaint

    a2d.Reboot()
end)

test.Step(
  "drag GS/OS forked file to trash - OK does update window",
  function()
    a2d.SelectPath("/GS.OS.MIXED/GS.OS.FILES/INSTALLER")
    a2d.MoveWindowBy(0,100)
    local icon_x, icon_y = 120, 30
    local window_x, window_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+icon_x, window_y+icon_y)
        m.ButtonDown()

        m.MoveToApproximately(trash_icon_x, trash_icon_y)
        m.ButtonUp()
    end)

    -- confirm deletion
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- error
    a2dtest.WaitForAlert()
    a2dtest.DHRDarkness()
    a2d.DialogOK()
    test.Snap("verify window does fully repaint")

    a2d.Reboot()
end)

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
    test.Snap("verify window does fully repaint")

    a2d.Reboot()
end)

