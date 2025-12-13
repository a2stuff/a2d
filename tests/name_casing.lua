--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/gsos_floppy.dsk"

======================================== ENDCONFIG ]]

-- Helpers, since we can only toggle the flag
local preserve_flag = true -- default state in config
function EnablePreserve()
  if not preserve_flag then
    a2d.ToggleOptionPreserveCase()
    preserve_flag = not preserve_flag
  end
end
function DisablePreserve()
  if preserve_flag then
    a2d.ToggleOptionPreserveCase()
    preserve_flag = not preserve_flag
  end
end

--[[
  Verify that GS/OS volume name cases show correctly.
]]
test.Step(
  "GS/OS volume name cases show correctly",
  function()
    a2d.OpenPath("/GS.OS.MIXED")
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "GS.OS.mixed", "case should be shown")
end)

--[[
  Verify that GS/OS file name cases show correctly in
  `/TESTS/PROPERTIES/GS.OS.NAMES`
]]
test.Step(
  "GS/OS file name cases show correctly",
  function()
    a2d.OpenPath("/TESTS/PROPERTIES/GS.OS.NAMES")
    test.Snap("verify name cases are correct")
end)

--[[
  Verify that AppleWorks file name cases show correctly in
  `/TESTS/PROPERTIES/AW.NAMES`
]]
test.Step(
  "AppleWorks file name cases show correctly",
  function()
    a2d.OpenPath("/TESTS/PROPERTIES/AW.NAMES")
    test.Snap("verify name cases are correct")
end)

--[[
  Launch DeskTop. Select an AppleWorks file icon. File > Rename.
  Specify a name using a mix of uppercase and lowercase. Close the
  containing window and re-open it. Verify that the filename case is
  retained.
]]
test.Variants(
  {
    "AppleWorks files rename with case preservation - preserve off",
    "AppleWorks files rename with case preservation - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end

    a2d.CopyPath("/TESTS/PROPERTIES/AW.NAMES/LOWER.UPPER.SS", "/RAM1")
    a2d.RenamePath("/RAM1/LOWER.UPPER.SS", "UP.lo.MiXeD")
    a2d.CloseAllWindows()
    a2d.SelectPath("/RAM1/UP.LO.MIXED")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "UP.lo.MiXeD", "name should be cased")

    -- Note that behavior is the same regardless of flag state; this
    -- is because AppleWorks files have case bits stored in auxtype
    -- which is not optional, unlike GS/OS case bits.

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Select an AppleWorks file icon. File > Duplicate.
  Specify a name using a mix of uppercase and lowercase. Close the
  containing window and re-open it. Verify that the filename case is
  retained.
]]
test.Variants(
  {
    "AppleWorks files duplicate with case preservation - preserve off",
    "AppleWorks files duplicate with case preservation - preserve on",
  },
  function()
    if idx == 1 then DisablePreserve() else EnablePreserve() end

    a2d.CopyPath("/TESTS/PROPERTIES/AW.NAMES/LOWER.UPPER.SS", "/RAM1")
    a2d.DuplicatePath("/RAM1/LOWER.UPPER.SS", "UP.lo.MiXeD")
    a2d.CloseAllWindows()
    a2d.SelectPath("/RAM1/UP.LO.MIXED")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "UP.lo.MiXeD", "name should be cased")

    -- Note that behavior is the same regardless of flag state; this
    -- is because AppleWorks files have case bits stored in auxtype
    -- which is not optional, unlike GS/OS case bits.

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. In the Options control panel, uncheck "Preserve
  uppercase and lowercase in names". Then run these test cases:

  Launch DeskTop. In the Options control panel, check "Preserve
  uppercase and lowercase in names". Then run these test cases:
]]

--[[
  File > New Folder. Enter a name with mixed case (e.g.
  "lower.UPPER.MiX"). Verify that the name appears with heuristic word
  casing (e.g. "Lower.Upper.Mix"). Close the window and re-open it.
  Verify that the name remains unchanged.

  File > New Folder. Enter a name with mixed case (e.g.
  "lower.UPPER.MiX"). Verify that the name appears with the specified
  case (e.g. "Lower.Upper.Mix"). Close the window and re-open it.
  Verify that the name remains unchanged.
]]
test.Variants(
  {
    "File > New Folder - preserve off",
    "File > New Folder - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end
    local expected
    if idx == 1 then
      expected = "Lower.Upper.Mix"
    else
      expected = "lower.UPPER.MiX"
    end

    a2d.CreateFolder("/RAM1/lower.UPPER.MiX")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), expected, "case should match")
    a2d.CloseAllWindows()
    a2d.SelectPath("/RAM1/LOWER.UPPER.MIX")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), expected, "case should match")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Select a non-AppleWorks file. File > Rename. Enter a name with mixed
  case (e.g. "lower.UPPER.MiX"). Verify that the name appears with
  heuristic word casing (e.g. "Lower.Upper.Mix"). Close the window and
  re-open it. Verify that the name remains unchanged.

  Select a non-AppleWorks file. File > Rename. Enter a name with mixed
  case (e.g. "lower.UPPER.MiX"). Verify that the name appears with the
  specified case (e.g. "Lower.Upper.Mix"). Close the window and
  re-open it. Verify that the name remains unchanged.
]]
test.Variants(
  {
    "File > Rename - preserve off",
    "File > Rename - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end
    local expected
    if idx == 1 then
      expected = "Lower.Upper.Mix"
    else
      expected = "lower.UPPER.MiX"
    end

    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.RenamePath("/RAM1/READ.ME", "lower.UPPER.MiX")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), expected, "case should match")
    a2d.CloseAllWindows()
    a2d.SelectPath("/RAM1/LOWER.UPPER.MIX")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), expected, "case should match")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Select a non-AppleWorks file. File > Duplicate. Enter a name with
  mixed case (e.g. "lower.UPPER.MiX"). Verify that the name appears
  with heuristic word casing (e.g. "Lower.Upper.Mix"). Close the
  window and re-open it. Verify that the name remains unchanged

  Select a non-AppleWorks file. File > Duplicate. Enter a name with
  mixed case (e.g. "lower.UPPER.MiX"). Verify that the name appears
  with the specified (e.g. "Lower.Upper.Mix"). Close the window and
  re-open it. Verify that the name remains unchanged.
]]
test.Variants(
  {
    "File > Duplicate - preserve off",
    "File > Duplicate - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end
    local expected
    if idx == 1 then
      expected = "Lower.Upper.Mix"
    else
      expected = "lower.UPPER.MiX"
    end

    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.DuplicatePath("/RAM1/READ.ME", "lower.UPPER.MiX")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), expected, "case should match")
    a2d.CloseAllWindows()
    a2d.SelectPath("/RAM1/LOWER.UPPER.MIX")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), expected, "case should match")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Select a disk. Special > Format Disk. Enter a name with mixed case
  (e.g. "lower.UPPER.MiX"). Let the operation complete. Verify that
  the name appears with heuristic word casing (e.g.
  "Lower.Upper.Mix"). Restart DeskTop. Verify that the name remains
  unchanged.

  Select a disk. Special > Format Disk. Enter a name with mixed case
  (e.g. "lower.UPPER.MiX"). Let the operation complete. Verify that
  the name appears with the specified case (e.g. "lower.UPPER.MiX").
  Restart DeskTop. Verify that the name remains unchanged.
]]
test.Variants(
  {
    "Format - preserve off",
    "Format - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end
    local expected
    if idx == 1 then
      expected = "Lower.Upper.Mix"
    else
      expected = "lower.UPPER.MiX"
    end

    a2d.FormatVolume("RAM1", "lower.UPPER.MiX")
    a2d.OpenPath("/LOWER.UPPER.MIX")
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), expected, "volume name should be " .. expected)

    -- cleanup
    a2d.EraseVolume("LOWER.UPPER.MIX", "RAM1")
end)

--[[
  Select a disk. Special > Erase Disk. Enter a name with mixed case
  (e.g. "lower.UPPER.MiX"). Let the operation complete. Verify that
  the name appears with heuristic word casing (e.g.
  "Lower.Upper.Mix"). Restart DeskTop. Verify that the name remains
  unchanged.

  Select a disk. Special > Erase Disk. Enter a name with mixed case
  (e.g. "lower.UPPER.MiX"). Let the operation complete. Verify that
  the name appears with the specified case (e.g. "lower.UPPER.MiX").
  Restart DeskTop. Verify that the name remains unchanged.
]]
test.Variants(
  {
    "Erase - preserve off",
    "Erase - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end
    local expected
    if idx == 1 then
      expected = "Lower.Upper.Mix"
    else
      expected = "lower.UPPER.MiX"
    end

    a2d.EraseVolume("RAM1", "lower.UPPER.MiX")
    a2d.OpenPath("/LOWER.UPPER.MIX")
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), expected, "volume name should be " .. expected)

    -- cleanup
    a2d.EraseVolume("LOWER.UPPER.MIX", "RAM1")
end)

--[[
  Launch DeskTop. In the Options control panel, check "Preserve
  uppercase and lowercase in names". File > New Folder. Enter a name
  with mixed case (e.g. "lower.UPPER.MiX"). In the Options control
  panel, uncheck "Preserve uppercase and lowercase in names". Select
  the folder. File > Rename. Click away without changing the name.
  Verify that the name appears with heuristic word casing (e.g.
  "Lower.Upper.Mix"). Close the window and re-open it. Verify that the
  name remains unchanged.
]]
test.Step(
  "Canceled rename",
  function()
    EnablePreserve()
    a2d.CreateFolder("/RAM1/lower.UPPER.MiX")
    DisablePreserve()
    a2d.SelectPath("/RAM1/LOWER.UPPER.MIX")
    apple2.ReturnKey() -- File > Rename
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0,0)
        m.Click()
    end)
    a2d.WaitForRepaint()

    a2d.OpenPath("/RAM1/LOWER.UPPER.MIX")
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "Lower.Upper.Mix", "rename should use heuristic case")

    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. In the Options control panel, check "Preserve
  uppercase and lowercase in names". File > New Folder. Enter a name
  with mixed case (e.g. "lower.UPPER.MiX"). Select the folder. Then
  run these test cases:

  * Drag it to another volume to copy it. Verify that the copied file
    retains the same mixed case name.

  * Drag it to another folder on the same volume to move it. Verify
    that the moved file retains the same mixed case name.

  * Hold Solid-Apple and drag it to another volume to move it. Verify
    that the moved file retains the same mixed case name.

  * Hold Solid-Apple and drag it to another folder on the same volume
    to copy it. Verify that the copied file retains the same mixed
    case name.
]]
test.Variants(
  {
    "drag - copy to another volume",
    "drag - move on same volume",
    "drag - move to another volume", -- Uses "real" mouse, too imprecise
    "drag - copy to same volume", -- Uses "real" mouse, too imprecise
  },
  function(idx)
    EnablePreserve()

    a2d.SelectPath("/GS.OS.MIXED")
    local other_vol_4_x, other_vol_4_y = a2dtest.GetSelectedIconCoords()

    a2d.CreateFolder("/RAM1/lower.UPPER.MiX")

    local path
    if idx == 1 then
      -- Copy to another volume
      a2d.Select("LOWER.UPPER.MIX")
      local x,y = a2dtest.GetSelectedIconCoords()

      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(x, y)
          m.ButtonDown()
          m.MoveToApproximately(other_vol_4_x, other_vol_4_y)
          m.ButtonUp()
      end)
      a2d.WaitForRepaint()

      path = "/GS.OS.MIXED/LOWER.UPPER.MIX"
    elseif idx == 2  then
      -- Move on same volume
      a2d.CreateFolder("ANOTHER.FOLDER")
      a2d.OpenPath("/RAM1")

      a2d.Select("LOWER.UPPER.MIX")
      local x1, y1 = a2dtest.GetSelectedIconCoords()

      a2d.Select("ANOTHER.FOLDER")
      local x2, y2 = a2dtest.GetSelectedIconCoords()

      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(x1, y1)
          m.ButtonDown()
          m.MoveToApproximately(x2, y2)
          m.ButtonUp()
      end)
      a2d.WaitForRepaint()

      path = "/RAM1/ANOTHER.FOLDER/LOWER.UPPER.MIX"
    elseif idx == 3 then
      -- Move to another volume
      a2d.Select("LOWER.UPPER.MIX")
      local x,y = a2dtest.GetSelectedIconCoords()

      a2d.InMouseKeysMode(function(m)
          apple2.PressSA()
          m.MoveToApproximately(x, y)
          m.ButtonDown()
          m.MoveToApproximately(other_vol_4_x, other_vol_4_y)
          m.ButtonUp()
          apple2.ReleaseSA()
      end)
      a2d.WaitForRepaint()

      path = "/GS.OS.MIXED/LOWER.UPPER.MIX"
    elseif idx == 4 then
      -- Copy on same volume
      a2d.CreateFolder("ANOTHER.FOLDER")
      a2d.OpenPath("/RAM1")

      a2d.Select("LOWER.UPPER.MIX")
      local x1,y1 = a2dtest.GetSelectedIconCoords()

      a2d.Select("ANOTHER.FOLDER")
      local x2, y2 = a2dtest.GetSelectedIconCoords()

      a2d.InMouseKeysMode(function(m)
          apple2.PressSA()
          m.MoveToApproximately(x1, y1)
          m.ButtonDown()
          m.MoveToApproximately(x2, y2)
          m.ButtonUp()
          apple2.ReleaseSA()
      end)
      a2d.WaitForRepaint()

      path = "/RAM1/ANOTHER.FOLDER/LOWER.UPPER.MIX"
    end

    a2d.OpenPath(path)
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "lower.UPPER.MiX", "move should retain case")
    a2d.DeletePath(path)
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. In the Options control panel, check "Preserve
  uppercase and lowercase in names". Rename one volume with mixed case
  e.g. "vol1.MIXED". Rename a second volume with differently mixed
  case, e.g. "VOL2.mixed". Drag the first volume to the second. Verify
  that the newly created folder is named with the same case as the
  dragged volume
]]
test.Step(
  "Copy one volume to another",
  function()
    EnablePreserve()
    a2d.RenamePath("/GS.OS.MIXED", "vol1.MIXED")
    a2d.RenamePath("/RAM1", "VOL2.mixed")

    a2d.SelectPath("/VOL1.MIXED")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()
    a2d.SelectPath("/VOL2.MIXED")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        m.ButtonUp()
    end)
    a2d.WaitForRestart() -- let copy from floppy complete

    a2d.OpenPath("/VOL2.MIXED/VOL1.MIXED")
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "vol1.MIXED", "vol copy should retain case")
end)

