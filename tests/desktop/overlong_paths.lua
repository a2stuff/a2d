--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Open
  `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789/ABCDEF123`.
  Try to copy a file into the folder. Verify that stray pixels do not
  appear in the top line of the screen.
]]
test.Step(
  "Copy file into folder with overlong path",
  function()
    a2d.OpenPath("/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789/ABCDEF123")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    a2d.MoveWindowBy(0, 80)
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, x+w/2, y+h/2)
    emu.wait(1)
    a2dtest.WaitForAlert({match="pathname is too long"})
    a2d.DialogOK()

    local dhr = apple2.SnapshotDHR()
    for i = 0, apple2.SCREEN_COLUMNS-1 do
      test.ExpectEquals(dhr[i], 0x7F, "top pixels of screen should not be dirty")
    end
end)

--[[
* Launch DeskTop. Open `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789`. Rename the `/TESTS` volume to `/TESTSXXXXXXXXXX` so that the total path length of the innermost files would be longer than 64 characters. Repeat the following operations, and verify that an error is shown and DeskTop doesn't crash or hang:
  * Select the `ABCDEF123` folder. File > Open.
  * Select the `ABCDEF123` folder. File > Get Info.
  * Select the `ABCDEF123` folder. File > Rename
  * Select the `ABCDEF123` folder. File > Duplicate
  * Select the `ABCDEF123` folder. File > Copy To... (and pick a target)
  * Select the `ABCDEF123` folder. Shortcuts > Add a Shortcut...
  * Drag a file icon onto the `ABCDEF123` folder.
  * Drag the `ABCDEF123` folder to another volume.
  * Drag the `ABCDEF123` folder to the Trash.
  * Repeat the previous cases, but with `LONGIMAGE` file.
]]
test.Variants(
  {
    {"overlong paths - folder", "folder"},
    {"overlong paths - file", "file"},
  },
  function(idx, name, which)
    a2d.OpenPath("/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789")
    emu.wait(1)
    a2d.SelectPath("/TESTS", {keep_windows=true})
    a2d.RenameSelection("TESTSXXXXXXXXXX")
    if which == "folder" then
      a2d.Select("ABCDEF123")
    else
      a2d.Select("LONGIMAGE")
    end
    local target_x, target_y = a2dtest.GetSelectedIconCoords()

    a2d.OAShortcut("O") -- File > Open
    a2dtest.WaitForAlert({match="pathname is too long"})
    a2d.DialogOK()

    a2d.OAShortcut("I") -- File > Get Info
    a2dtest.WaitForAlert({match="pathname is too long"})
    a2d.DialogOK()

    apple2.ReturnKey() -- File > Rename
    a2dtest.WaitForAlert({match="pathname is too long"})
    a2d.DialogOK()

    a2d.CopySelectionTo("/RAM1") -- File > Copy To...
    a2dtest.WaitForAlert({match="pathname is too long"})
    a2d.DialogOK()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2dtest.WaitForAlert({match="pathname is too long"})
    a2d.DialogOK()

    -- Drag file to folder
    if which == "folder" then
      a2d.Select("LONGIMAGE")
      local src_x, src_y = a2dtest.GetSelectedIconCoords()
      a2d.Drag(src_x, src_y, target_x, target_y)
      a2dtest.WaitForAlert({match="pathname is too long"})
      a2d.DialogOK()
    end

    -- Drag to volume
    a2d.SelectPath("/RAM1", {keep_windows=true})
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(target_x, target_y, vol_x, vol_y)
    a2dtest.WaitForAlert({match="pathname is too long"})
    a2d.DialogOK()

    -- Drag folder to Trash
    a2d.SelectPath("/Trash", {keep_windows=true})
    local trash_x, trash_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(target_x, target_y, trash_x, trash_y)
    a2dtest.WaitForAlert({match="pathname is too long"})
    a2d.DialogOK()

    a2d.RenamePath("/TESTSXXXXXXXXXX", "TESTS")
end)

--[[
  Copy `MODULES/SHOW.IMAGE.FILE` to the `APPLE.MENU` folder. Restart.
  Open `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789`.
  Rename the `/TESTS` volume to `/TESTSXXXXXXXXXX`. Select the
  `LONGIMAGE` file. Apple Menu > Show Image File. Verify that an alert
  is shown.
]]
test.Step(
  "overlong paths - launching DAs with selection",
  function()
    a2d.CopyPath("/A2.DESKTOP/MODULES/SHOW.IMAGE.FILE", "/A2.DESKTOP/APPLE.MENU")
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.SelectPath("/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789/LONGIMAGE")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.SelectPath("/TESTS", {keep_windows=true})
    a2d.RenameSelection("TESTSXXXXXXXXXX")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)

    a2d.InvokeMenuItem(a2d.APPLE_MENU, -1)
    a2dtest.WaitForAlert({match="pathname is too long"})
    a2d.DialogOK()

    a2d.RenamePath("/TESTSXXXXXXXXXX", "TESTS")
    a2d.DeletePath("/A2.DESKTOP/APPLE.MENU/SHOW.IMAGE.FILE")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Open `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789`. Copy
  `APPLE.MENU/KEY.CAPS` to the folder. Rename the `/TESTS` volume to
  `/TESTSXXXXXXXXXX`. Select the copy of `KEY.CAPS`. File > Open.
  Verify that an alert is shown.
]]
test.Step(
  "overlong paths - launching DAs",
  function()
    a2d.CopyPath("/A2.DESKTOP/APPLE.MENU/KEY.CAPS",
                 "/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789")
    a2d.SelectPath("/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789/KEY.CAPS")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/TESTS", {keep_windows=true})
    a2d.RenameSelection("TESTSXXXXXXXXXX")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
    end)
    a2dtest.WaitForAlert({match="pathname is too long"})
    a2d.DialogOK()
    a2d.RenamePath("/TESTSXXXXXXXXXX", "TESTS")
end)
